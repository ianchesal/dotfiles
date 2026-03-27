---
name: daily-wrap
description: >
  End-of-day ritual skill that reads Ian's daily Obsidian journal note, synthesizes the day,
  fills in the Day in Review section, advises on tomorrow, and keeps Today.md current.
  Trigger when Ian says things like: "wrap up my day", "daily wrap", "end of day", "let's review today",
  "help me close out today", "day in review", "how'd my day go", or any similar end-of-day journaling prompt.
  Also trigger if Ian says "update my Today note" or "update Today.md". This skill covers work AND personal
  life — prod incidents, vendor negotiations, relationship, health, home, mental state, all of it.
---

# Daily Wrap Skill

A ritual skill for closing out Ian's day. It reads the daily note, infers what happened,
checks in with Ian to confirm/correct, writes the Day in Review, and updates Today.md.

---

## File Paths

Daily notes live at:
```
\\synology01\ian\Obsidian\Personal\Daily\YYYY\MM-MonthName\YYYY-MM-DD.md
```

Month folder names use zero-padded month number + full month name, e.g.:
- `01-January`, `02-February`, `03-March`, `04-April`, `05-May`, `06-June`
- `07-July`, `08-August`, `09-September`, `10-October`, `11-November`, `12-December`

Today.md (persistent context across days):
```
\\synology01\ian\Obsidian\Personal\Today.md
```

---

## Step 1: Read the Files

Use the Filesystem MCP tools to read:
1. **Today's daily note** — derive the path from today's actual date
2. **Today.md** — for persistent context (Current Focus, ongoing threads)
3. **Yesterday's daily note** (optional) — only if today's note is sparse; helps with continuity

If today's note doesn't exist yet, tell Ian and offer to help him create it from the template.

---

## Step 2: Synthesize the Day

Before asking Ian anything, do your own read of the note and form a picture of the day.
Look at each section:

### From "Today's Intentions"
- What did Ian plan to do?
- Cross-reference against "Day in Review > What actually got done?" — is it already filled in?

### From "Daily Plan" (if present — populated by a separate automation)
- Calendar: what meetings happened? Any notable external/customer/vendor meetings?
- Slack: any open incidents? Any VIP activity that needed a response?
- Jira: any overdue or high-priority tickets?

### From "Random Notes"
- Personal observations, home stuff, health, mood signals, side projects
- These often contain the most honest snapshot of how the day *actually* felt

### From "Tasks"
- Any todos added or checked off today?

### From "Day in Review" (bottom of note)
- May already be partially or fully filled in — if so, build on it rather than replace it
- If empty, that's what this skill is here to fill

### From "Claude:" directives (anywhere in the note)
Scan the entire note for any bullet point starting with `Claude:` — these can appear in
Today's Intentions, Random Notes, or anywhere else. They are explicit instructions Ian left
for himself (and you) earlier in the day.

Collect all `Claude:` directives before the check-in and treat them as **overrides** —
they take priority over your normal inference and question logic.

**How to handle them:**
- Surface each directive explicitly in your check-in under a "**You left me a note:**" section
- Execute the directive during the wrap — don't just acknowledge it and move on
- If a directive asks you to discuss something, discuss it; if it asks you to help draft
  something, do that; if it asks you to hold Ian accountable for something, do that
- If a directive seems stale or no longer relevant by end of day, surface it anyway and
  ask: "still want to work through this?" — don't silently drop it
- Multiple directives are fine; work through them in order

**Example directives and how to handle them:**
- `Claude: ask me how the Cloudflare call went, I need to process it` → ask directly, make space for a real answer
- `Claude: don't let me skip talking about my workout today` → bring it up even if it's not in the note
- `Claude: help me draft a response to X before we close out` → produce the draft as part of the wrap
- `Claude: I want to think through [situation] before we wrap` → treat as a discussion prompt, not a checkbox

---

## Step 3: Check In With Ian

Present your synthesis as a brief, honest read of the day. Don't just list facts back at him —
interpret them. Then ask targeted follow-up questions to fill in gaps.

**Format your check-in like this:**

---
### Here's how I read today:

[2-4 sentence honest assessment of the day — what got done, what didn't, how it seemed to go energetically, any notable wins or friction]

**A few things I'm inferring — correct me if I'm off:**
- [inference 1]
- [inference 2]
- [inference 3, etc.]

**You left me a note:** *(only include this section if there are Claude: directives in the note)*
- [directive 1 — quoted or paraphrased, with a note on how you'll handle it]
- [directive 2, etc.]

**A couple questions:**
1. [question about something genuinely unclear or missing]
2. [question about personal/emotional state if not captured in the note]
3. [only ask a 3rd if there's something genuinely important missing — don't pad]
---

**Guidelines for the check-in:**
- Be direct and honest, not flattering. If it looks like a rough day, say so.
- If the Day in Review is already filled in well, say so and ask only what's missing.
- Probe personal/home/health when there are signals in Random Notes (mini-split, Krista, exercise, etc.)
- Don't ask about things that are clearly documented — only ask about gaps.
- If the note is basically empty (sparse Intentions, no Day in Review, no Random Notes), be more curious: ask more open-ended questions about how the day went.

---

## Step 4: Write the Day in Review

After Ian responds, write the final Day in Review using his words plus your synthesis.
Keep his voice — don't polish it into something more corporate than how he writes.

The two fields to fill:

**What actually got done?**
- Bullet list, 3-7 items, concrete and specific
- Include personal wins (a good moment with family, a workout, a side project shipped) alongside work

**What carries forward?**
- Incomplete work, unresolved decisions, things explicitly punted
- Don't include everything unfinished — just the things that actually need Ian's attention

Write the updated section out clearly in your response so Ian can review it before you write it to disk.

Once Ian confirms (or adjusts), use the Filesystem MCP `edit_file` tool to update the note.

The Day in Review section looks like this in the file:
```markdown
## Day in Review
**What actually got done?**
- 

**What carries forward?**
- 
```

Replace the empty bullets with real content. Preserve everything above this section unchanged.

---

## Step 5: Tomorrow Advisory

After the Day in Review is confirmed, give Ian a brief tomorrow advisory. Keep it tight — 
this isn't a full daily plan, just a heads-up so he can go to sleep with his head clear.

Pull from:
- "What carries forward?" items you just wrote
- Tomorrow's daily note (if it exists — peek at it using tomorrow's date path)
- Today.md "Current Focus" — are any of tomorrow's items aligned with his stated priorities?

**Format:**
```
### Tomorrow
[1-2 sentences framing the day — what's the dominant theme or pressure?]

**Top 3 things to carry into tomorrow:**
1. [most important carry-forward or known meeting/deadline]
2. [second most important]
3. [third]

**One thing to let go of tonight:**
[Something Ian was carrying today that doesn't need mental energy overnight]
```

The "one thing to let go of" is important — don't skip it. It's often more useful than the to-do list.

---

## Step 5b: Carry Forward Into Tomorrow's Note

After the Tomorrow Advisory is confirmed, write the top carry-forward items into tomorrow's daily note as Today's Intentions.

**How:**
1. Derive tomorrow's note path from today's date + 1
2. Read the file — check if Today's Intentions already has content (don't clobber anything Ian wrote himself)
3. Write the top 2-3 items from "What carries forward?" as intention bullets, using concise action-oriented language
4. Leave at least one blank bullet after them so Ian has room to add his own

**Format for the bullets** — keep them tight, one line each, with enough context to be actionable:
- ✓ `Cursor negotiation — have Charles's direction, press on token unit pricing`
- ✗ `Follow up on Cursor` (too vague)

**Edge cases:**
- If tomorrow's note doesn't exist yet, skip this step and mention it to Ian
- If Today's Intentions already has content, append after existing bullets rather than replacing
- Weekend → Monday: same logic applies; carry the most important items into Monday's note

Show Ian what you're writing before committing, or just write it and confirm — use judgment based on whether the items are obvious vs. surprising.

---

## Step 6: Update Today.md (if warranted)

After the daily wrap is complete, assess whether Today.md needs updating.

The **Current Focus** section (numbered list, 1-3 items) should reflect what Ian actually needs to be
focused on right now — not aspirational goals, but the real live wires. Update it if:
- A major new stressor or priority emerged today that isn't reflected
- Something on the list has clearly resolved or shifted
- Ian explicitly says something has changed

The **A Thought to Carry** quote can be updated if the day surfaced something that calls for a
different framing tomorrow. Don't change it just to change it — only if something better fits.

Show Ian the proposed Today.md changes before writing them. Then write with `edit_file`.

---

## Tone and Style Notes

- Ian doesn't want flattery. Don't say "great job" or "sounds like a productive day" reflexively.
- He's going through a genuinely difficult period — engineering chaos, org strain, personal stress.
  Acknowledge hard days honestly. Don't minimize or silver-line unless he does first.
- Keep it grounded and practical. The goal is a clear head, not a therapy session (unless it goes there).
- His journal voice is casual, honest, occasionally dry — match that energy.
- If something in the note suggests he's running on fumes or carrying a lot, name it directly.

---

## Edge Cases

**Note doesn't exist yet:** Offer to create it from the template path at
`\\synology01\ian\Obsidian\Personal\Extras\Templates\Template, Daily Note.md`

**Note is basically empty:** Ask more open questions. Start with "How'd today actually go?"
before trying to infer anything.

**Day in Review already fully filled in:** Read it, affirm what's there, and go straight to
Tomorrow Advisory + Today.md update. Don't make him re-do work he already did.

**Weekend note:** Lighter touch. Less focus on work incidents/Jira, more on personal/home/hobby.
The "tomorrow advisory" on Sunday should acknowledge the week ahead, not just Monday's to-do list.
