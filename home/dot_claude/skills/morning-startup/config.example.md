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

## Gmail: Inbox Triage

The skill reads your inbox to answer "am I missing email?" — an overnight pass, an
aging sweep for what already slipped, and a check for threads where someone is waiting
on you. Gmail is **read-only**: nothing is starred, labelled, archived, or replied to.

- **Account index**: `{{GMAIL_ACCOUNT_INDEX}}`
  - The `u/N` in your Gmail URLs, used to build clickable thread links. `0` if work
    email is the only account signed in to that browser profile; `1` or higher if you
    have a personal account signed in ahead of it.
  - Check by opening Gmail and reading the URL: `mail.google.com/mail/u/1/` → `1`.
  - Getting this wrong produces links that open the wrong account's inbox, so confirm
    it rather than assuming `0`.
  - Example: `0`
- **Aging window**: `14d`
  - How far back the aging sweep looks for unread and unanswered mail. Gmail duration
    syntax (`7d`, `14d`, `1m`). Widen it if things still slip through; narrow it if the
    Email section is too long to read.
- **VIP email addresses**: `{{VIP_EMAIL_ADDRESSES}}`
  - Anything from these senders earns a `[VIP]` badge and is always surfaced. These are
    **email addresses, not the Slack usernames** from the VIP DMs section above — the
    same person needs an entry in both places.
  - Comma-separated. Example: `boss@example.com, ceo@example.com`
- **External domains**: `{{EXTERNAL_DOMAINS}}`
  - Vendor, customer, and partner domains. Mail from these earns `[EXTERNAL]`, on the
    reasoning that outside mail is what actually costs you when it sits unanswered.
  - Reuse the same domains you listed under **Calendar: People to Flag** below.
  - Comma-separated. Example: `@google.com, @salesforce.com`
- **Noise senders**: `{{EMAIL_NOISE_SENDERS}}`
  - Gmail negative-match terms appended to every triage query, on top of the
    `-category:promotions/social/forums` exclusions the skill always applies.
  - Use this for newsletters and automated mail that survives Gmail's own
    categorisation. Do **not** list Jira, GitHub, Notion, or Slack notifications — the
    skill already suppresses those, because those systems have their own sections in
    the briefing and reporting them twice buries real mail.
  - Example: `-from:newsletter@example.com -from:noreply@example.com -subject:"weekly digest"`
  - Leave blank to apply only the category exclusions.
  - Two patterns worth knowing about, both seen in a real inbox rather than invented:
    **transactional-notification floods** (a spend or billing tool firing several
    near-identical mails in a minute) survive Gmail's categorisation and will dominate
    the overnight pass — filter the sender, not the subject. And if you are **migrating
    off Superhuman**, its `reminder@superhuman.com` follow-ups stay in your threads
    forever. Do not filter those: the skill uses them as a signal, since each one marks
    a thread you had already flagged as needing a reply.

If a genuine thread gets missed, suspect this list before widening anything else —
over-broad noise filtering is the likeliest way this step goes quiet on real mail.

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
the live schema wins if it drifts from this list.

**If you are adding Gmail triage to an existing database**, seed `Email Backlog` and
`Awaiting Reply` as `Flags` options before the first run. Notion will not create
multi-select options on the fly, and the skill omits an unseeded flag rather than
failing the page write — so without seeding you get briefings that read correctly but
never carry the email flags.

| Property | Type | Purpose |
|----------|------|---------|
| `Day` | title | `YYYY-MM-DD Ddd` — e.g. `2026-09-10 Thu` |
| `Entry Date` | date | Canonical date. Used to find today's entry instead of creating duplicates |
| `Day Shape` | select | `Focus-heavy`, `Balanced`, `Meeting-heavy`, `Back-to-back`, `Light` |
| `Energy` | select | `High`, `Steady`, `Guarded`, `Low` — read from the personal journal only |
| `The One Thing` | text | Coaching line, verbatim |
| `Today Needs` | text | Coaching line, verbatim |
| `One Question` | text | Coaching line, verbatim |
| `Flags` | multi-select | `Incident`, `Blocked Jira`, `RSVP Needed`, `Vendor`, `Org Change`, `Travel/PTO`, `Interview`, `Week Ahead`, `Email Backlog`, `Awaiting Reply` |
| `1:1s With` | multi-select | People with a 1:1 that day |
| `Meetings` | number | Real meetings, excluding focus/Clockwise/solo blocks |
| `Focus Hours` | number | Uninterrupted hours available |
| `Phase 2 Prep` | checkbox | Set when deep 1:1 and meeting prep lands on the page |
| `Journal` | url | `obsidian://` link back to that day's personal note |
| `Notes` | text | Yours. The skill never writes to it |
