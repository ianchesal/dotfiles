#!/usr/bin/env bash
#
# Block until a pull request needs attention, print what changed, then exit.
#
# Usage: wait.sh <https://github.com/OWNER/REPO/pull/N> [since]
#
#   since  ISO-8601 UTC time (2026-11-24T16:45:00Z) you started your last read
#          of the PR; default now. Checks that finished, and comments or
#          reviews written or edited, after it count as new.
#
# Prints one line per event and exits 0:
#   state MERGED|CLOSED
#   head <sha>                       the head moved while waiting (a push)
#   conflict                         the PR became unmergeable while waiting
#   failed <check> <url>             a check failed after `since`
#   checks-done pass=N fail=M        nothing pending, and a check finished after `since`
#   comment <author> <url>           a PR comment, by anyone but you
#   review <author> <STATE> <url>    a review
#   inline <author> <url>            a line comment or thread reply
# Exits 8 printing `timeout` after PR_WAIT_MAX seconds with nothing new, 1 when
# gh keeps failing, 2 on bad arguments.
#
# The watch-pr skill runs this as a background job, so the harness wakes the
# agent when it exits. It polls because `gh event listen` has no event for
# top-level PR comments or for commit statuses (how Buildkite reports).
#
# Env: PR_WAIT_INTERVAL seconds between polls (60), PR_WAIT_MAX seconds before
# giving up (43200 = 12h), GH_BIN the gh to call (tests point it at a fake).

set -euo pipefail

gh_bin=${GH_BIN:-gh}
interval=${PR_WAIT_INTERVAL:-60}
max_wait=${PR_WAIT_MAX:-43200}

usage() {
  echo "usage: ${0##*/} <https://github.com/OWNER/REPO/pull/N> [since, e.g. 2026-11-24T16:45:00Z]" >&2
  exit 2
}

pr=${1:-}
[[ $pr =~ ^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)/?$ ]] || usage
repo=${BASH_REMATCH[1]}/${BASH_REMATCH[2]}
num=${BASH_REMATCH[3]}
since=${2:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}
[[ $since =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || usage

# Snapshots go through files: a long thread passed as one argument would hit
# Linux's 128 KiB single-argument limit.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# gh prints a `gh event listen` hint on stderr for PR URLs. Keep stderr aside
# and show it only when a call fails for good.
err=$work/stderr
gh_quiet() { "$gh_bin" "$@" 2>"$err"; }

me=$(gh_quiet api user --jq .login) || {
  cat "$err" >&2
  exit 1
}

# Writes $work/snap.json: state, head, mergeable, checks[{name,url,at,bucket}]
# and activity[{kind,author,at,url,state?}]. A check's `at` is when it
# finished; a commit status has only the time of its latest update.
snapshot() {
  gh_quiet pr view "$pr" --json state,headRefOid,mergeable,statusCheckRollup --jq '{
    state, head: .headRefOid, mergeable,
    checks: [.statusCheckRollup[] | {
      name: (.name // .context),
      url: (.detailsUrl // .targetUrl // ""),
      at: (.completedAt // .startedAt // ""),
      bucket: (
        if .__typename == "StatusContext" then
          (if .state == "PENDING" or .state == "EXPECTED" then "pending"
           elif .state == "FAILURE" or .state == "ERROR" then "fail"
           else "pass" end)
        elif .status != "COMPLETED" then "pending"
        elif .conclusion == "SKIPPED" or .conclusion == "NEUTRAL" then "skip"
        elif .conclusion == "SUCCESS" then "pass"
        else "fail" end)
    }]
  }' >"$work/view.json" || return 1
  {
    gh_quiet api --paginate "repos/$repo/issues/$num/comments" \
      --jq '.[] | {kind: "comment", author: .user.login, at: .updated_at, url: .html_url}' &&
      gh_quiet api --paginate "repos/$repo/pulls/$num/reviews" \
        --jq '.[] | {kind: "review", author: .user.login, at: .submitted_at, url: .html_url, state}' &&
      gh_quiet api --paginate "repos/$repo/pulls/$num/comments" \
        --jq '.[] | {kind: "inline", author: .user.login, at: .updated_at, url: .html_url}'
  } >"$work/activity.json" || return 1
  jq -s '.[0] + {activity: .[1:]}' "$work/view.json" "$work/activity.json" >"$work/snap.json"
}

# The event lines for $work/snap.json. Head and mergeable compare with the
# first snapshot; everything else with `since`. Timestamps are all GitHub's
# fixed-width UTC form, so they compare as strings.
events() {
  jq -r --arg bhead "$base_head" --arg bmerge "$base_mergeable" --arg since "$since" --arg me "$me" '
    (.checks | map(select(.bucket != "skip"))) as $real
    | (if .state != "OPEN" then "state \(.state)" else empty end),
      (if .head != $bhead then "head \(.head)" else empty end),
      (if .mergeable == "CONFLICTING" and $bmerge != "CONFLICTING" then "conflict" else empty end),
      ($real[] | select(.bucket == "fail" and .at > $since) | "failed \(.name) \(.url)"),
      (if ($real | length) > 0 and ($real | all(.bucket != "pending")) and ([$real[].at] | max) > $since
       then "checks-done pass=\($real | map(select(.bucket == "pass")) | length) fail=\($real | map(select(.bucket == "fail")) | length)"
       else empty end),
      (.activity[] | select(.author != $me and (.at // "") > $since)
        | "\(.kind) \(.author) \(if .state then .state + " " else "" end)\(.url)")' "$work/snap.json"
}

start=$(date +%s)
failures=0
base_head=
base_mergeable=
while :; do
  if snapshot; then
    failures=0
    if [ -z "$base_head" ]; then
      base_head=$(jq -r .head "$work/snap.json")
      base_mergeable=$(jq -r .mergeable "$work/snap.json")
    fi
    out=$(events)
    if [ -n "$out" ]; then
      printf '%s\n' "$out"
      exit 0
    fi
  else
    failures=$((failures + 1))
    if [ "$failures" -ge 5 ]; then
      echo "gh failed $failures polls in a row:" >&2
      cat "$err" >&2
      exit 1
    fi
  fi
  if [ $(($(date +%s) - start + interval)) -ge "$max_wait" ]; then
    echo timeout
    exit 8
  fi
  sleep "$interval"
done
