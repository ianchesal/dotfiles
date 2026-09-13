#!/usr/bin/env bash
# gh CLI extensions, ported from the git:setup_gh rake task that the chezmoi
# migration retired. `gh extension install` is not idempotent -- it errors if
# the extension is already there -- so check first.
set -euo pipefail
command -v gh >/dev/null 2>&1 || { echo "gh not installed; skipping extensions"; exit 0; }
gh auth status >/dev/null 2>&1 || { echo "gh not authenticated; skipping extensions"; exit 0; }

installed="$(gh extension list 2>/dev/null || true)"
for ext in gennaro-tedesco/gh-f dlvhdr/gh-dash github/gh-stack; do
  if printf '%s' "$installed" | grep -q "${ext#*/}"; then
    echo "gh extension ${ext} already installed"
  else
    echo "Installing gh extension ${ext}"
    gh extension install "$ext" || echo "  (failed; continuing)"
  fi
done
