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

## Work Daily Notes

- **Path**: `{{PATH_TO_WORK_NOTES}}`
  - Example: `~/Documents/Personal/Work/`
- **Structure**: `YYYY/MM-MonthName/work-YYYY-MM-DD.md`
  - Example: `2026/05-May/work-2026-05-04.md`
  - The `work-` filename prefix keeps bare date wikilinks like `[[2026-05-04]]`
    resolving unambiguously to the personal daily journal note.
- **Title format**: `Work Day - YYYY-MM-DD`
  - Used in the `# Work Day - YYYY-MM-DD` heading and wikilinks from the personal journal.
