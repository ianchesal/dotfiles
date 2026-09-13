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
gh pr list --author "app/dependabot" --state open --json number,title,headRefName,mergeable,statusCheckRollup --jq 'sort_by(.number)'
```

If there are none, report that and stop.

## Step 2: Process PRs one at a time, oldest first

For each PR, re-fetch its current state with the same `gh pr list` query
before acting on it — merging one PR can change another's mergeable state or
checks, so don't trust state gathered before earlier PRs in this run
finished.

Classify it:

- **Checks still pending** → skip, note as "pending" for the summary. Move on.
- **`mergeable: false` (conflicting)** → comment `@dependabot rebase` on the
  PR (`gh pr comment <number> --body "@dependabot rebase"`) and move on. Don't
  wait for it — it'll be clean on a future run of this skill.
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
- **Green and `mergeable: true`** →
  1. `gh pr review <number> --approve`
  2. `gh pr merge <number> --auto --squash` (match the repo's normal merge
     method if it's not squash)
  3. Poll until it actually merges (`gh pr view <number> --json state`)
     before moving to the next PR — a merge can be what unblocks or conflicts
     the remaining ones.

## Step 3: Summarize

Report counts and PR numbers for each bucket: merged, rebase-requested,
closed-for-node, pending, and failing-non-node.

## Step 4: Offer to dig into the leftovers

If anything landed in "failing (non-Node)", ask whether to investigate those
PRs and try to get them fixed and merged (e.g. bumping a lockfile, fixing a
config the dependency update broke). Only proceed into that work if asked —
this skill's default scope stops at the green/conflicted/Node-bump triage
above.
