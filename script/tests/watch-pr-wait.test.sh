#!/usr/bin/env bash
#
# Tests for home/dot_claude/skills/watch-pr/executable_wait.sh. Drives the
# waiter against a fake gh that serves canned PR snapshots from a scratch dir,
# so nothing talks to GitHub.
#
# Run: script/tests/watch-pr-wait.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_claude/skills/watch-pr/executable_wait.sh

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

failures=0
check() {
  local label=$1 expected=$2 actual=$3
  if [ "$expected" = "$actual" ]; then
    printf '  ok   %s\n' "$label"
  else
    printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$label" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

# A fake gh. Each `pr view` is one poll and bumps $FIX/polls. Every call
# answers from $FIX/<name>.<poll>.json, falling back to the nearest earlier
# poll's file and then to $FIX/<name>.json, and applies --jq to it the way gh
# does (strings raw, objects compact).
mkdir -p "$work/bin"
cat >"$work/bin/gh" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
[ "$1 $2" != 'api user' ] || { echo me; exit 0; }
[ ! -e "$FIX/fail" ] || { echo 'HTTP 502: Bad Gateway' >&2; exit 1; }
echo 'hint: use gh event listen' >&2
expr=.
prev=
for arg in "$@"; do
  [ "$prev" != --jq ] || expr=$arg
  prev=$arg
done
case "$*" in
  'pr view '*) echo $(($(cat "$FIX/polls" 2>/dev/null || echo 0) + 1)) >"$FIX/polls"; name=view ;;
  *'/issues/'*'/comments '*) name=issues ;;
  *'/reviews '*) name=reviews ;;
  *'/pulls/'*'/comments '*) name=inline ;;
  *) echo "fake gh: unexpected call: $*" >&2; exit 64 ;;
esac
poll=$(cat "$FIX/polls")
file=$FIX/$name.json
for ((k = poll; k >= 1; k--)); do
  if [ -e "$FIX/$name.$k.json" ]; then file=$FIX/$name.$k.json; break; fi
done
[ -e "$file" ] || { echo '[]' | jq -rc "$expr"; exit 0; }
jq -rc "$expr" "$file"
FAKE
chmod +x "$work/bin/gh"

pr=https://github.com/acme/app/pull/7
since=2026-11-24T12:00:00Z
before=2026-11-24T11:59:00Z
after=2026-11-24T12:01:00Z

# view <file> <state> <head> <mergeable> <check>... -- write a `pr view` answer.
view() {
  local file=$1 state=$2 head=$3 mergeable=$4
  shift 4
  local checks
  checks=$(printf '%s\n' "$@" | jq -s -c .)
  printf '{"state":"%s","headRefOid":"%s","mergeable":"%s","statusCheckRollup":%s}\n' \
    "$state" "$head" "$mergeable" "$checks" >"$fix/$file"
}
# run <status> <conclusion> <completedAt> <name> -- a GitHub Actions check run.
run_check() {
  printf '{"__typename":"CheckRun","name":"%s","status":"%s","conclusion":"%s","completedAt":"%s","detailsUrl":"https://ci/%s"}' \
    "$4" "$1" "$2" "$3" "$4"
}
# status <state> <startedAt> <context> -- a commit status, as Buildkite sends.
status_check() {
  printf '{"__typename":"StatusContext","context":"%s","state":"%s","startedAt":"%s","targetUrl":"https://bk/%s"}' \
    "$3" "$1" "$2" "$3"
}
# comment <file> <author> <at> <url> [review state] -- one activity item.
comment() {
  if [ -n "${5:-}" ]; then
    printf '[{"user":{"login":"%s"},"submitted_at":"%s","html_url":"%s","state":"%s"}]\n' "$2" "$3" "$4" "$5" >"$fix/$1"
  else
    printf '[{"user":{"login":"%s"},"updated_at":"%s","html_url":"%s"}]\n' "$2" "$3" "$4" >"$fix/$1"
  fi
}

fresh() {
  fix=$work/fix.$1
  mkdir -p "$fix"
}

# wait_for <max seconds> [args...] -- run the waiter; sets $out and $rc.
wait_for() {
  local max=$1
  shift
  rc=0
  FIX=$fix GH_BIN=$work/bin/gh PR_WAIT_INTERVAL=0 PR_WAIT_MAX=$max \
    "$subject" "$@" >"$work/out" 2>"$work/err" || rc=$?
  out=$(cat "$work/out")
}

echo "watch-pr-wait"

# --- arguments ------------------------------------------------------------
fresh args
wait_for 0 https://github.com/acme/app
check "rejects a URL that isn't a PR" "2" "$rc"
wait_for 0 "$pr" yesterday
check "rejects a since that isn't ISO-8601 UTC" "2" "$rc"

# --- quiet PR: timeout ----------------------------------------------------
fresh quiet
view view.json OPEN aaa MERGEABLE "$(run_check COMPLETED SUCCESS "$before" build)"
comment issues.json alice "$before" https://c/1
wait_for 0 "$pr" "$since"
check "nothing newer than since times out with exit 8" "8:timeout" "$rc:$out"
check "gh's stderr hint stays out of the output" "" "$(cat "$work/err")"

# --- merged or closed -----------------------------------------------------
fresh merged
view view.json MERGED aaa UNKNOWN
wait_for 0 "$pr" "$since"
check "a merged PR reports its state" "0:state MERGED" "$rc:$out"

# --- activity by others, not by me ----------------------------------------
fresh activity
view view.json OPEN aaa MERGEABLE
comment issues.json me "$after" https://c/mine
comment inline.json alice "$after" https://c/line
comment reviews.json bob "$after" https://r/1 CHANGES_REQUESTED
wait_for 0 "$pr" "$since"
check "reports reviews and line comments by others, skips my own" \
  "review bob CHANGES_REQUESTED https://r/1|inline alice https://c/line" "$(printf '%s' "$out" | tr '\n' '|')"

fresh edited
view view.json OPEN aaa MERGEABLE
comment issues.json 'claude[bot]' "$after" https://c/sticky
wait_for 0 "$pr" "$since"
check "a comment edited after since counts (bots update sticky comments)" \
  "comment claude[bot] https://c/sticky" "$out"

# --- checks -----------------------------------------------------------------
fresh failed
view view.json OPEN aaa MERGEABLE \
  "$(run_check COMPLETED FAILURE "$before" old-fail)" \
  "$(run_check COMPLETED TIMED_OUT "$after" unit)" \
  "$(run_check IN_PROGRESS '' '' lint)"
wait_for 0 "$pr" "$since"
check "a check that failed after since wakes at once; an older failure doesn't" \
  "failed unit https://ci/unit" "$out"

fresh buildkite
view view.json OPEN aaa MERGEABLE "$(status_check FAILURE "$after" buildkite/app)"
wait_for 0 "$pr" "$since"
check "a failing commit status (Buildkite) counts as a failed check" \
  "failed buildkite/app https://bk/buildkite/app|checks-done pass=0 fail=1" "$(printf '%s' "$out" | tr '\n' '|')"

fresh all-done
view view.1.json OPEN aaa MERGEABLE \
  "$(run_check COMPLETED SUCCESS "$before" build)" "$(status_check PENDING "$before" buildkite/app)"
view view.2.json OPEN aaa MERGEABLE \
  "$(run_check COMPLETED SUCCESS "$before" build)" "$(status_check SUCCESS "$after" buildkite/app)"
wait_for 5 "$pr" "$since"
check "the last pending check finishing reports checks-done" "0:checks-done pass=2 fail=0" "$rc:$out"
check "it took a second poll to see it" "2" "$(cat "$fix/polls")"

fresh skipped
view view.json OPEN aaa MERGEABLE \
  "$(run_check COMPLETED SUCCESS "$before" build)" "$(run_check COMPLETED SKIPPED "$after" claude)"
wait_for 0 "$pr" "$since"
check "a skipped check finishing (comment-triggered workflows) doesn't wake" "8:timeout" "$rc:$out"

# --- head and mergeability compare with the first poll -----------------------
fresh head
view view.1.json OPEN aaa MERGEABLE
view view.2.json OPEN bbb MERGEABLE
wait_for 5 "$pr" "$since"
check "a push while waiting reports the new head" "head bbb" "$out"

fresh conflict
view view.1.json OPEN aaa MERGEABLE
view view.2.json OPEN aaa CONFLICTING
wait_for 5 "$pr" "$since"
check "becoming unmergeable while waiting reports conflict" "conflict" "$out"

fresh known-conflict
view view.json OPEN aaa CONFLICTING
wait_for 0 "$pr" "$since"
check "a conflict that was already there doesn't wake" "8:timeout" "$rc:$out"

# --- gh failing ---------------------------------------------------------------
fresh gh-down
view view.json OPEN aaa MERGEABLE
touch "$fix/fail"
wait_for 60 "$pr" "$since"
check "gh failing every poll gives up with exit 1" "1" "$rc"
check "and shows gh's error" "1" "$(grep -c 'HTTP 502' "$work/err")"

if [ "$failures" -gt 0 ]; then
  echo "$failures failure(s)"
  exit 1
fi
echo "all passed"
