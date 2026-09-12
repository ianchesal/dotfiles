# Morning Startup — Config

Copy this file to `config.md` in this same directory and fill in your values.
`config.md` is git-ignored and never committed.

---

## Identity

- **Slack User ID**: `{{YOUR_SLACK_USER_ID}}`
  - Find yours: open Slack → click your profile → "Copy member ID"
- **Slack Team ID**: `{{YOUR_SLACK_TEAM_ID}}`
  - Find yours: open Slack in a browser, it appears in the URL (e.g. `app.slack.com/client/TXXXXXXXX`)
- **Work email**: `{{YOUR_WORK_EMAIL}}`
- **User shortname**: `{{USER_SHORTNAME}}`
  - Your short identifier used in signal-cache filenames (e.g. `alex`, `sam`).
    Must match the shortname used when running the `signal-person` skill for yourself.

## Daily Notes

- **Path**: `{{PATH_TO_DAILY_NOTES}}`
  - Example: `~/Documents/Personal/Daily/`
- **Structure**: `YYYY/MM-MonthName/YYYY-MM-DD.md`
  - Example: `2026/03-March/2026-03-04.md`
- **Anchor section**: The skill inserts `## Daily Plan` above this section heading in your note:
  `## {{SECTION_HEADING_TO_INSERT_ABOVE}}`
  - Example: `## One thing I'm excited about right now`
- **Obsidian vault name**: `{{OBSIDIAN_VAULT}}`
  - The vault name as Obsidian knows it — used to build the `obsidian://` link stored
    on each Notion entry so you can jump from the briefing back to that day's journal.
  - Example: `Personal`
  - Leave blank to skip the link.
- **Obsidian vault root**: `{{OBSIDIAN_VAULT_ROOT}}`
  - The vault's folder on disk. `obsidian://` links are relative to this, not to the
    daily notes path, so both values are needed to build one.
  - Example: `~/Documents/Personal/`

These notes are **read-only** to this skill, with one exception: it writes a slim
`## Work Day` stub into today's note pointing at the Notion briefing.

## Auth

- **Auth command**: `{{YOUR_AUTH_COMMAND}}`
  - This is an interactive shell command/function that handles your work auth
    (SSO, password manager, CLI tools, etc.). The skill will prompt you to run
    it manually in your terminal.
  - Example: `ian-auth` (a zsh function that handles Okta, 1Password, GitHub, and Persona CLI)
  - Leave blank if you don't need a morning auth step.

## Jira

- **Cloud ID**: `{{YOUR_JIRA_CLOUD_ID}}`
  - Find yours: visit `https://yourcompany.atlassian.net` → the cloud ID appears
    in API responses, or ask your Jira admin.
- **Base URL**: `https://{{YOUR_COMPANY}}.atlassian.net/browse/`
- **Languishing threshold**: 7 days
  - Issues not updated in this many days are flagged as stale.

## Slack: VIP DMs

People whose DMs you should always prioritize reviewing:

- `{{VIP_1_NAME}}` — `{{VIP_1_SLACK_USERNAME}}`
- `{{VIP_2_NAME}}` — `{{VIP_2_SLACK_USERNAME}}`
- _(add more as needed)_

Common VIPs: your manager, your skip-level, your CEO/CTO, key cross-functional partners.

## 1:1 People — Signal Registry

People you have recurring 1:1s with. The morning-startup skill resolves each 1:1 on
your calendar against this table to find the person's **shortname**, which keys their
signal-cache file at `~/.claude/signal-cache/{shortname}.json`. The cache is built and
refreshed automatically during 1:1 prep, and can be enriched out-of-band by the
`signal-person` skill. People not listed here still get live 1:1 prep, but no cache is
kept for them.

| Display Name | Shortname | Slack Username | GitHub Handle |
|--------------|-----------|----------------|---------------|
| `{{REPORT_1_NAME}}` | `{{REPORT_1_SHORTNAME}}` | `{{REPORT_1_SLACK}}` | `{{REPORT_1_GITHUB}}` |
| `{{REPORT_2_NAME}}` | `{{REPORT_2_SHORTNAME}}` | `{{REPORT_2_SLACK}}` | `{{REPORT_2_GITHUB}}` |

- **Shortname**: lowercase, no spaces (e.g. `jordan`, `sam`). Used in the cache filename.
- **GitHub Handle**: optional — enables PR-volume signal when the `gh` CLI is available.

## Slack: Channels to Monitor

Channels your team owns or that you should read daily:

| Channel | ID | Notes |
|---------|----|-------|
| `#{{CHANNEL_1}}` | `{{CHANNEL_1_ID}}` | {{what to look for}} |
| `#{{CHANNEL_2}}` | `{{CHANNEL_2_ID}}` | {{what to look for}} |

To find a channel ID: right-click a channel in Slack → "Copy link" → the ID is
the `C...` part at the end of the URL.

Include your incidents/on-call channel here if you have one.

## Calendar: People to Flag

People whose presence on your calendar warrants a prep note:

- **Vendor/customer signals**: List domains or names that indicate an external meeting
  (e.g. `@google.com`, `@salesforce.com`, known customer names)
- **VIPs**: Names of executives or senior leaders whose calendar presence is notable
  - `{{EXEC_1_NAME}}`
  - `{{EXEC_2_NAME}}`
- **Scheduling tool**: `{{SCHEDULING_TOOL}}` (e.g. Clockwise, Calendly)
  - The skill will flag meetings that originated from this tool's scheduling links.

## Timezone

- **Your timezone**: `{{YOUR_TIMEZONE}}`
  - Example: `America/New_York`
- **Company HQ timezone**: `{{COMPANY_HQ_TIMEZONE}}`
  - Example: `America/Los_Angeles`
  - Used for lunch window suggestions when your timezone differs from company HQ.

## Notion: Daily Startup Database

The full briefing is written here — one page per workday.

- **Data source**: `{{NOTION_STARTUP_DATA_SOURCE}}`
  - A `collection://<uuid>` URL, not a page URL.
  - Find yours: run `notion-fetch` on the database's page URL. The response carries a
    `<database ... data-source-url="collection://...">` tag — that value is what goes
    here.
  - Example: `collection://3d8ef6bc-b0fd-80c5-97d3-000b7ca353c9`

The database needs these properties. The skill reads the live schema at preflight, so
the live schema wins if it drifts from this list:

| Property | Type | Purpose |
|----------|------|---------|
| `Day` | title | `YYYY-MM-DD Ddd` — e.g. `2026-09-10 Thu` |
| `Entry Date` | date | Canonical date. Used to find today's entry instead of creating duplicates |
| `Day Shape` | select | `Focus-heavy`, `Balanced`, `Meeting-heavy`, `Back-to-back`, `Light` |
| `Energy` | select | `High`, `Steady`, `Guarded`, `Low` — read from the personal journal only |
| `The One Thing` | text | Coaching line, verbatim |
| `Today Needs` | text | Coaching line, verbatim |
| `One Question` | text | Coaching line, verbatim |
| `Flags` | multi-select | `Incident`, `Blocked Jira`, `RSVP Needed`, `Vendor`, `Org Change`, `Travel/PTO`, `Interview`, `Week Ahead` |
| `1:1s With` | multi-select | People with a 1:1 that day |
| `Meetings` | number | Real meetings, excluding focus/Clockwise/solo blocks |
| `Focus Hours` | number | Uninterrupted hours available |
| `Phase 2 Prep` | checkbox | Set when deep 1:1 and meeting prep lands on the page |
| `Journal` | url | `obsidian://` link back to that day's personal note |
| `Notes` | text | Yours. The skill never writes to it |
