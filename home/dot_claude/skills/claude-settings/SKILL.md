---
name: claude-settings
description: Promote useful local ~/.claude/settings.json changes into the tracked skeleton, or apply the skeleton's defaults onto a local settings.json.
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep, Edit
---

<!-- Customize the machine-local key list below to match what you don't want propagated. -->

**Arguments:** `$ARGUMENTS`

`claude/settings.json` is gitignored (real per-machine Claude Code state,
symlinked in as `~/.claude/settings.json`). `claude/settings.skeleton.json` is
the tracked, curated set of portable defaults. This skill moves things between
them. Requires exactly one argument: `promote` or `apply`.

## Machine-local keys (never touch these)

These keys are account/machine bookkeeping, not portable preference. Never
read them into the skeleton and never overwrite them when applying:
`enabledPlugins`, `extraKnownMarketplaces`, `feedbackSurveyState`, `autoMode`,
`env`, `effortLevel`, `allowedTools`.

If you find a genuinely new machine-local key not in this list while doing
either operation below, treat it as machine-local (skip it) and mention it in
your summary so the user can decide whether to add it to this list.

## `promote`: fold local improvements into the tracked skeleton

1. Read `~/.claude/settings.json` (local) and `claude/settings.skeleton.json`
   (tracked).
2. For every key in local that isn't a machine-local key (above), compare
   against the skeleton:
   - Key missing from skeleton entirely, or a value that looks like a durable
     preference rather than one-off state → candidate to add.
   - Key present in both but changed (e.g. a hook gained a new matcher entry,
     a new hook event was added) → candidate to update. For object/array
     values, merge additively where it makes sense (e.g. append a new entry
     to a `hooks.<Event>` array) rather than blindly overwriting the whole
     skeleton value, so you don't silently drop something else already in
     the skeleton.
   - Trivial/noisy differences (e.g. `tui`, timestamps, anything that looks
     like transient state rather than a preference) → not a candidate.
3. Present the candidates and your proposed skeleton diff to the user. Get
   confirmation before writing.
4. Write the updated `claude/settings.skeleton.json`.
5. Ask whether to commit (this repo's convention: commit directly on `main`,
   no PR).

## `apply`: merge the skeleton's defaults onto the local file

1. Read `claude/settings.skeleton.json` (tracked) and `~/.claude/settings.json`
   (local).
2. For each top-level key in the skeleton, merge it into local:
   - Key absent locally → add it.
   - Key present locally and identical → leave alone.
   - Key present locally and different → for object/array values, merge
     additively (e.g. add missing entries to a `hooks.<Event>` array rather
     than replacing the array, so any local-only hook entries survive); for
     scalar values, the skeleton wins.
3. Never touch machine-local keys (above) or any key not present in the
   skeleton.
4. Show a summary of what changed before writing `~/.claude/settings.json`.
