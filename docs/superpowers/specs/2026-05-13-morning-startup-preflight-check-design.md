# Design: Morning Startup Preflight Check

**Date:** 2026-05-13
**Skill:** `morning-startup`
**File:** `claude/skills/morning-startup/SKILL.md`

## Problem

The morning-startup skill proceeds directly into context gathering without first
verifying that the three external MCP data sources are reachable. When a source
is unavailable, the failure surfaces mid-flow — after local notes have been read
and sometimes after partial output has been written — forcing the user to restart
from scratch.

## Goal

Fail fast: verify all three MCP data sources are available before any work
begins, and stop immediately with a clear error if any are not.

## Design

### Placement

Insert a new **Step 0: Preflight Check** between the config load block and the
current Step 1 (Read Context from Notes). Renumber existing steps 1–4 → 2–5.

### Probe Calls

Run all three probes in parallel:

| Source | Probe call | Success condition |
|--------|-----------|-------------------|
| Google Calendar | `mcp__claude_ai_Google_Calendar__list_calendars` | Returns without error |
| Slack | `mcp__claude_ai_Slack__slack_search_users` querying `{{SLACK_USER_ID}}` | Returns without error |
| Jira | `mcp__claude_ai_Atlassian__atlassianUserInfo` | Returns without error |

### On Success

Print a single confirmation line and proceed immediately to Step 1:

```
✅ All data sources available (Calendar, Slack, Jira) — starting briefing…
```

### On Failure

Print an error block naming every failed source with a one-line diagnosis
(tool not found vs. auth error vs. timeout/unexpected), then **stop**. Do not
read any notes, do not write any files.

```
❌ Preflight check failed — cannot start morning briefing.

The following data sources are not available:
- **Slack** — MCP tool did not respond. Check your MCP server status or restart Claude Code.
- **Jira** — MCP tool did not respond. Check your Atlassian MCP connection.

Fix the above and re-run your morning startup.
```

### Error Diagnosis

Map error types to user-facing messages:

- **Tool not found / schema not loaded**: "MCP server may not be running. Restart
  Claude Code or check your MCP config."
- **Authentication / authorization error**: "Auth expired or invalid. Re-authenticate
  via the MCP server settings."
- **Unexpected / unknown error**: "Unexpected error — see details above."

## Out of Scope

- Retrying failed probes automatically (fail fast is the goal)
- ToolSearch fallback to find alternate tool name variants
- Degraded-mode partial briefings when some sources are unavailable

## Implementation Notes

The probe calls are intentionally lightweight — `list_calendars` and
`atlassianUserInfo` return minimal data. The Slack probe queries for the user's
own ID which is guaranteed to return quickly.

The check adds one parallel round-trip before work begins (~1–2 seconds). This
is an acceptable trade-off to eliminate mid-flow failures.
