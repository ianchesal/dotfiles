#!/usr/bin/env bash
#
# Claude Code SessionStart hook: when claude runs inside a herdr pane, tell it
# so. Prints where it is (workspace, tab, pane) followed by herdr-context.md,
# the policy for how to use herdr. SessionStart stdout becomes session context.
#
# Outside herdr it prints nothing, so it costs nothing anywhere else. It must
# never fail the session: every error path exits 0.
#
# Wired up in ~/.claude/settings.json (seeded from create_private_settings.json)
# with matcher startup|resume|clear|compact, so the context survives /clear and
# compaction.
#
# Seams for script/tests/herdr-claude-hooks.test.sh:
#   HERDR_BIN -- herdr executable (default: $HERDR_BIN_PATH, else herdr on PATH)

set -uo pipefail

# Claude hands the hook a JSON payload on stdin; this hook doesn't need it.
cat >/dev/null 2>&1 || true

[ "${HERDR_ENV:-}" = 1 ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0

# herdr injects its binary path, but a brew upgrade under a running server
# leaves it pointing at a deleted Cellar path -- fall back to PATH.
herdr=${HERDR_BIN:-${HERDR_BIN_PATH:-herdr}}
[ -x "$herdr" ] || herdr=herdr

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

ws=${HERDR_WORKSPACE_ID:-}
label=
if [ -n "$ws" ] && command -v jq >/dev/null 2>&1; then
  label=$("$herdr" workspace get "$ws" 2>/dev/null | jq -r '.result.workspace.label // empty' 2>/dev/null) || label=
fi

printf 'herdr session context: workspace %s%s, tab %s, pane %s (this pane).\n\n' \
  "${ws:-unknown}" "${label:+ (\"$label\")}" "${HERDR_TAB_ID:-unknown}" "$HERDR_PANE_ID"
cat "$here/herdr-context.md" 2>/dev/null || true
exit 0
