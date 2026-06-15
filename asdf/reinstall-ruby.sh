#!/usr/bin/env bash
#
# reinstall-ruby.sh
#
# Rebuilds asdf Ruby so it links against the correct dependencies.
#
# WARNING: `asdf uninstall ruby 3.3.9` deletes every gem installed under that
# version. This script snapshots the gem list first and offers to reinstall
# them at the end.
#
# Usage:
#   ./reinstall-ruby.sh           # interactive (prompts before destructive steps)
#   ./reinstall-ruby.sh --yes     # no prompts (assume yes)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_VERSIONS="${SCRIPT_DIR}/tool-versions"

[ -f "${TOOL_VERSIONS}" ] || {
  printf '\033[1;31mERROR:\033[0m %s\n' "tool-versions not found at ${TOOL_VERSIONS}" >&2
  exit 1
}

RUBY_VERSION="$(awk '$1 == "ruby" { print $2; exit }' "${TOOL_VERSIONS}")"
[ -n "${RUBY_VERSION}" ] || {
  printf '\033[1;31mERROR:\033[0m %s\n' "no ruby version found in ${TOOL_VERSIONS}" >&2
  exit 1
}

RUBY_BIN="${HOME}/.asdf/installs/ruby/${RUBY_VERSION}/bin"

STAMP="$(date +%Y%m%d-%H%M%S)"
GEM_SNAPSHOT="${HOME}/ruby-${RUBY_VERSION}-gems-${STAMP}.txt"   # full `gem list` (for reference)
GEM_PAIRS="${HOME}/ruby-${RUBY_VERSION}-gem-pairs-${STAMP}.txt" # name<space>version, restorable
GEM_FAILED="${HOME}/ruby-${RUBY_VERSION}-gem-restore-failures-${STAMP}.txt"

ASSUME_YES=0
[ "${1:-}" = "--yes" ] && ASSUME_YES=1

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2
  exit 1
}

confirm() {
  # confirm "prompt"  -> returns 0 for yes, 1 for no
  [ "${ASSUME_YES}" -eq 1 ] && return 0
  local reply
  read -r -p "$1 [y/N] " reply </dev/tty
  case "${reply}" in [yY] | [yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

# --- Pre-flight -------------------------------------------------------------
command -v asdf >/dev/null 2>&1 || die "asdf not found on PATH"

LIBYAML_PREFIX="$(brew --prefix libyaml 2>/dev/null || true)"
[ -n "${LIBYAML_PREFIX}" ] || LIBYAML_PREFIX="/home/linuxbrew/.linuxbrew/opt/libyaml"
[ -e "${LIBYAML_PREFIX}/lib/libyaml-0.so.2" ] ||
  die "libyaml not found at ${LIBYAML_PREFIX}/lib -- install it first:  brew install libyaml"
log "Using libyaml prefix: ${LIBYAML_PREFIX}"

# --- Snapshot installed gems (current gem is broken, so use the workaround) -
if [ -x "${RUBY_BIN}/gem" ]; then
  log "Snapshotting installed gems -> ${GEM_SNAPSHOT}"
  LD_LIBRARY_PATH="${LIBYAML_PREFIX}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "${RUBY_BIN}/gem" list --local >"${GEM_SNAPSHOT}"

  # Turn `gem list` into restorable "name version" pairs. Skips Ruby's bundled
  # default gems (they come back with Ruby) and strips platform suffixes.
  awk '
    {
      idx = index($0, " (")
      if (idx == 0) next
      name = substr($0, 1, idx - 1)
      rest = substr($0, idx + 2)
      sub(/\)[[:space:]]*$/, "", rest)
      n = split(rest, parts, ",")
      for (i = 1; i <= n; i++) {
        v = parts[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
        if (v ~ /^default:/) continue          # bundled with Ruby; skip
        split(v, vt, " ")                       # drop platform suffix, keep version
        print name " " vt[1]
      }
    }
  ' "${GEM_SNAPSHOT}" >"${GEM_PAIRS}"
  log "Restorable gem versions: $(wc -l <"${GEM_PAIRS}")  (list: ${GEM_PAIRS})"
else
  warn "No existing ${RUBY_VERSION} gem binary found; nothing to snapshot."
  : >"${GEM_PAIRS}"
fi

# --- Rebuild Ruby -----------------------------------------------------------
echo
warn "About to UNINSTALL and REBUILD Ruby ${RUBY_VERSION} (this deletes its gems and recompiles)."
confirm "Proceed?" || die "Aborted by user. Nothing changed. Snapshot kept at ${GEM_SNAPSHOT}"

log "Uninstalling Ruby ${RUBY_VERSION}..."
asdf uninstall ruby "${RUBY_VERSION}"

log "Reinstalling Ruby ${RUBY_VERSION} with libyaml rpath baked in..."
LDFLAGS="-Wl,-rpath,${LIBYAML_PREFIX}/lib" \
  RUBY_CONFIGURE_OPTS="--with-libyaml-dir=${LIBYAML_PREFIX}" \
  asdf install ruby "${RUBY_VERSION}"

asdf reshim ruby "${RUBY_VERSION}" || true

# --- Verify the fix (no LD_LIBRARY_PATH -- proves the rpath is baked in) -----
log "Verifying psych loads natively..."
"${RUBY_BIN}/ruby" -e 'require "psych"; puts "psych OK, libyaml " + Psych::LIBYAML_VERSION' ||
  die "psych STILL failing after rebuild -- the rpath was not baked. Do not delete the gem snapshot."

log "Confirming psych.so RUNPATH now references libyaml..."
PSYCH_SO="$(find "${HOME}/.asdf/installs/ruby/${RUBY_VERSION}" -name 'psych.so' -print -quit 2>/dev/null || true)"
if [ -n "${PSYCH_SO}" ]; then
  (objdump -x "${PSYCH_SO}" 2>/dev/null | grep -iE 'rpath|runpath') || true
fi

# --- Restore gems -----------------------------------------------------------
GEM_COUNT="$(wc -l <"${GEM_PAIRS}" | tr -d ' ')"
if [ "${GEM_COUNT}" -gt 0 ]; then
  echo
  log "Ready to reinstall ${GEM_COUNT} gem versions from the snapshot."
  log "(Mason re-installs rubocop itself, and bundler restores per-project gems, so this is optional.)"
  if confirm "Reinstall all snapshotted gems now?"; then
    : >"${GEM_FAILED}"
    while read -r name version; do
      [ -n "${name:-}" ] || continue
      log "gem install ${name} -v ${version}"
      if ! "${RUBY_BIN}/gem" install "${name}" -v "${version}" --no-document; then
        warn "failed: ${name} ${version}"
        echo "${name} ${version}" >>"${GEM_FAILED}"
      fi
    done <"${GEM_PAIRS}"

    if [ -s "${GEM_FAILED}" ]; then
      warn "Some gems failed to reinstall; see ${GEM_FAILED}"
    else
      log "All gems reinstalled."
      rm -f "${GEM_FAILED}"
    fi
  else
    log "Skipped gem restore. Reinstall later with:"
    log "  while read -r n v; do gem install \"\$n\" -v \"\$v\" --no-document; done < ${GEM_PAIRS}"
  fi
fi

echo
log "Done. Ruby ${RUBY_VERSION} rebuilt; psych/libyaml fixed."
log "Snapshot kept at: ${GEM_SNAPSHOT}"
