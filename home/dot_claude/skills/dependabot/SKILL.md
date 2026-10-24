---
name: dependabot
description: Drain the current repo's Dependabot PR queue — approve and merge green PRs, drive rebases to completion, close Node-major bumps — looping until nothing actionable is left.
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
---

<!-- Customize the merge method and Node-major detection heuristics to match your workflow. -->

**Arguments:** `$ARGUMENTS`

Drain every open Dependabot PR on the current repo: approve and merge the
green ones, get Dependabot to rebase the conflicted or out-of-date ones and
**wait for those rebases to land and merge**, and close the ones that need a
Node.js major bump we don't have. Uses `gh` only — no local git checkouts,
rebases, or force-pushes.

**This skill is tenacious.** One invocation runs until the queue is empty or
every PR still open needs a human. Never stop with "it'll be clean on a future
run" — waiting for Dependabot and CI is this skill's job, not the user's.

## The loop

Work in **rounds**. Each round:

1. Fetch the queue (Step 1).
2. Classify and act on each PR (Step 2), updating a per-PR ledger.
3. Decide whether to stop (Step 3). If not, wait (Step 4) and start the next
   round.

Keep a ledger in your working notes, one line per PR: number, current
bucket, head SHA when you last acted, what you last did (approve / auto-merge
armed / `rebase` / `recreate`) and when. The ledger is how you tell "waiting"
from "stuck".

Post a one-line progress update to the user at the end of each round (e.g.
`round 4: merged #31, waiting on rebase of #33, 2 parked`), not a full
summary.

## Step 1: List PRs

```
gh pr list --author "app/dependabot" --state open --json number,title,headRefName,headRefOid,mergeable,mergeStateStatus,autoMergeRequest,statusCheckRollup --jq 'sort_by(.number)'
```

`mergeable` is `MERGEABLE` / `CONFLICTING` / `UNKNOWN` (not a boolean).
`mergeStateStatus` is what tells you whether branch protection will actually
let it merge: `CLEAN`, `BEHIND` (base moved, protection requires up-to-date),
`DIRTY` (conflicts), `BLOCKED`, `UNSTABLE`, `UNKNOWN`. `UNKNOWN` in either
field just means GitHub hasn't computed it yet — treat the PR as pending this
round and look again next round.

New PRs will appear mid-run: Dependabot opens more as merges free up its
`open-pull-requests-limit`, and it closes and recreates a group PR when one
of its updates already landed on main. Treat every new PR as part of the
queue. Mention recreated groups in the summary.

## Step 2: Classify and act, oldest first

Re-fetch with the Step 1 query before acting on each PR — a merge earlier in
the round can change another PR's state.

- **Checks still pending** (including `BLOCKED` or `UNKNOWN` while checks run)
  → bucket **waiting**. No action.
- **Green and `mergeStateStatus: CLEAN`** →
  1. `gh pr review <number> --approve`
  2. `gh pr merge <number> --auto --squash` (match the repo's normal merge
     method if it's not squash)
  It usually merges within seconds; bucket **waiting** until a later fetch
  shows it gone (then **merged**).
- **`mergeable: CONFLICTING` (`DIRTY`) or green-but-`BEHIND`** → approve and
  arm auto-merge (steps 1–2 above) if checks are green and that isn't done
  yet, then get the branch rebased. **Only one rebase in flight at a time,
  for the oldest such PR**: when branch protection requires up-to-date
  branches, every merge puts all the others `BEHIND` again, so rebasing the
  whole queue at once just burns CI. The rest sit in **waiting** until their
  turn.
  - First ask: `gh pr comment <number> --body "@dependabot rebase"`. Record
    the head SHA and time.
  - If Dependabot replies "The base commit for this pull request has not
    changed" while GitHub still reports `BEHIND` (confirm with
    `gh api repos/{owner}/{repo}/compare/main...<headRefName> --jq .behind_by`),
    or the head SHA hasn't moved ~10 minutes after the request, escalate to
    `gh pr comment <number> --body "@dependabot recreate"` — it rebuilds the
    branch from current main and auto-merge stays armed through the
    force-push. Never use `gh pr update-branch`: it pushes a non-Dependabot
    commit and Dependabot stops maintaining the PR.
  - If the head SHA still hasn't moved ~15 minutes after `recreate`, bucket
    **parked: Dependabot unresponsive**.
  - Once the head SHA moves, the PR is back to normal classification — when
    its CI passes, auto-merge merges it.
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
    2. `gh pr close <number>` → **closed-for-node**.
  - **Failure right after a rebase/recreate, or one that looks flaky**
    (network timeout, runner lost, rate limit): re-run it once with
    `gh run rerun <run-id> --failed` and bucket **waiting**.
  - **Any other failure reason** (or a second failure after a re-run): bucket
    **parked: failing (non-Node)** with a one-line reason. Don't close or
    comment.
- **Anything else** (`BLOCKED` with green checks, `UNSTABLE`, etc.) → bucket
  **parked: blocked** with the `mergeStateStatus` so a human can look.

A parked PR stays parked for the rest of the run unless its head SHA changes
(someone pushed to it), in which case reclassify it.

## Step 3: Decide whether to stop

Stop and go to Step 5 when **any** of these holds:

- The queue is empty.
- Every open PR is parked.
- No PR changed state (merged, closed, new head SHA, checks finished) for
  ~30 minutes of rounds — park whatever is still waiting as **parked:
  stalled** with what it was waiting on.
- The run has gone ~3 hours. Report that as the reason; it's a safety cap,
  not a normal exit.

Otherwise go to Step 4.

## Step 4: Wait

Wait with a single bounded foreground poll that watches the PR(s) you're
waiting on and returns as soon as something changes — e.g. a `for` loop of
`gh pr list ...` / `gh pr view ...` checks with `sleep 20` between them,
capped at ~8 minutes and run with a Bash `timeout` above that cap. Exit the
loop early when a watched PR merges, its head SHA moves, its checks finish, or
its `mergeStateStatus` changes. Then start the next round.

Never run the wait as a background job, and never end your turn to wait —
ending the turn is what forces the user to rerun the skill. If you ever need
to kill a stuck command, kill it by PID or task ID — never `pkill -f` a
pattern, since it can match the shell running the kill.

## Step 5: Summarize

Report the stop reason, the number of rounds and elapsed time, then counts and
PR numbers (as full URLs) for each bucket: merged, closed-for-node, and each
parked reason (unresponsive, failing non-Node with its one-line reason,
blocked with `mergeStateStatus`, stalled with what it was waiting on). Note any
groups Dependabot recreated mid-run.

## Step 6: Offer to dig into the leftovers

If anything is parked as "failing (non-Node)", ask whether to investigate
those PRs and try to get them fixed and merged (e.g. bumping a lockfile,
fixing a config the dependency update broke). Only proceed into that work if
asked — this skill's default scope stops at draining the queue above.
