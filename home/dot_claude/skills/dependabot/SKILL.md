---
name: dependabot
description: Triage, approve, and merge open Dependabot PRs on the current repo.
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
---

<!-- Customize the merge method and Node-major detection heuristics to match your workflow. -->

**Arguments:** `$ARGUMENTS`

Triage every open Dependabot PR on the current repo: approve and merge the
green ones, ask Dependabot to rebase the conflicted ones, and close the ones
that need a Node.js major bump we don't have. Uses `gh` only — no local git
checkouts, rebases, or force-pushes.

## Step 1: List PRs

```
gh pr list --author "app/dependabot" --state open --json number,title,headRefName,mergeable,mergeStateStatus,statusCheckRollup --jq 'sort_by(.number)'
```

If there are none, report that and stop.

`mergeable` is `MERGEABLE` / `CONFLICTING` / `UNKNOWN` (not a boolean).
`mergeStateStatus` is what tells you whether branch protection will actually
let it merge: `CLEAN`, `BEHIND` (base moved, protection requires up-to-date),
`DIRTY` (conflicts), `BLOCKED`, `UNSTABLE`, `UNKNOWN`. `UNKNOWN` in either
field just means GitHub hasn't computed it yet — wait a few seconds and
re-fetch (up to ~1 minute) before classifying.

If a PR from an earlier run has disappeared and a new one covers the same
dependency group, Dependabot closed and recreated it (common after a rebase
when one of a group's updates already landed on main). Mention it in the
summary; treat the new PR normally.

## Step 2: Process PRs one at a time, oldest first

For each PR, re-fetch its current state with the same `gh pr list` query
before acting on it — merging one PR can change another's mergeable state or
checks, so don't trust state gathered before earlier PRs in this run
finished.

Classify it:

- **Checks still pending** → skip, note as "pending" for the summary. Move on.
- **`mergeable: CONFLICTING` (`mergeStateStatus: DIRTY`)** → comment
  `@dependabot rebase` on the PR (`gh pr comment <number> --body "@dependabot rebase"`)
  and move on. Don't wait for it — it'll be clean on a future run of this skill.
- **Green but `mergeStateStatus: BEHIND`** → branch protection requires the
  branch to be up to date, so auto-merge will sit forever. Approve it, arm
  auto-merge, and ask Dependabot to rebase — once the rebase's CI passes,
  GitHub merges it with no further runs needed:
  1. `gh pr review <number> --approve`
  2. `gh pr merge <number> --auto --squash`
  3. `gh pr comment <number> --body "@dependabot rebase"`
  Don't poll; note it as "rebase-requested (auto-merge armed)" and move on.

  **Fallback if Dependabot refuses:** Dependabot sometimes replies "The base
  commit for this pull request has not changed" while GitHub still reports
  `BEHIND` (confirm with `gh api repos/{owner}/{repo}/compare/main...<headRefName> --jq .behind_by`).
  Re-asking for a rebase won't help. Comment `@dependabot recreate` instead —
  it rebuilds the branch from current main, and auto-merge stays armed
  through the force-push, so the PR merges once CI passes. Prefer this over
  `gh pr update-branch`, which pushes a non-Dependabot commit and makes
  Dependabot stop maintaining the PR.
- **Checks failing** → inspect the failure before giving up on the PR:
  ```
  gh pr checks <number>
  gh run view <run-id> --log-failed
  ```
  Look for Node-version signatures: `EBADENGINE`, `engine "node" is incompatible`,
  `Unsupported engine`, `requires Node`, `The engine "node" is incompatible
  with this module`, etc.
  - **Node-major-bump signature found**: find the repo's currently pinned
    Node major version (`.tool-versions`, `.nvmrc`, `engines.node` in
    `package.json`, or CI workflow files — whichever the repo uses), then:
    1. Comment on the PR explaining specifically why it can't be taken yet
       (e.g. "This needs Node >= 20; this repo is pinned to Node 18 via
       .tool-versions. Closing until we bump Node."). A real explanation is
       required — closing without one is what lets Dependabot recreate the PR.
    2. `gh pr close <number>`
  - **Any other failure reason**: skip, note as "failing (non-Node)" with a
    one-line reason for the summary. Don't close or comment.
- **Green and `mergeStateStatus: CLEAN`** →
  1. `gh pr review <number> --approve`
  2. `gh pr merge <number> --auto --squash` (match the repo's normal merge
     method if it's not squash)
  3. Poll until it actually merges (`gh pr view <number> --json state,mergeStateStatus`)
     before moving to the next PR — a merge can be what unblocks or conflicts
     the remaining ones. Keep the poll bounded (~5 minutes, well under the
     Bash tool timeout) and check `mergeStateStatus` each iteration: if it
     goes `BEHIND` or `DIRTY`, stop polling and handle it per the rules
     above. If it's still open when the bound runs out, note it as pending
     with its `mergeStateStatus` and move on.
- **Anything else** (`BLOCKED`, `UNSTABLE`, etc.) → skip, note it in the
  summary with the `mergeStateStatus` so a human can look.

Run polling in the foreground with a bound rather than as a background job.
If you ever need to kill a stuck command, kill it by PID or task ID — never
`pkill -f` a pattern, since it can match the shell running the kill.

## Step 3: Summarize

Report counts and PR numbers for each bucket: merged, rebase-requested
(flag which have auto-merge armed), closed-for-node, pending, failing-non-node,
and other-blocked (with `mergeStateStatus`).

## Step 4: Offer to dig into the leftovers

If anything landed in "failing (non-Node)", ask whether to investigate those
PRs and try to get them fixed and merged (e.g. bumping a lockfile, fixing a
config the dependency update broke). Only proceed into that work if asked —
this skill's default scope stops at the green/conflicted/Node-bump triage
above.
