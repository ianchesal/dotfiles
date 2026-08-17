# Review A Spec

Review the spec document at: $ARGUMENTS

If no path is given above, review the most recently modified file in
`docs/superpowers/specs/` and say which file you picked. If a bare filename is
given, look for it in `docs/superpowers/specs/`.

Follow these steps:

1. Read the whole spec before commenting on any part of it
2. Read enough of the surrounding project to judge the spec against reality: the repo's `CLAUDE.md`, and the files or subsystems the spec says it will touch. A spec that contradicts the codebase is the most valuable kind of finding
3. Review it against the checks below
4. Write the review to `SPEC_REVIEW.md` at the repo root, replacing any existing file

Checks:

- **Placeholders** — TBDs, TODOs, empty sections, "we'll work this out later"
- **Contradictions** — sections that disagree with each other, or an architecture that doesn't match the described features
- **Ambiguity** — requirements two competent implementers would build differently. Name both readings
- **Reality mismatch** — claims about existing code, file layout, APIs, or tooling that aren't true in this repo
- **Scope** — is this one implementable unit of work, or does it need decomposing? Call out anything smuggling in a second project
- **Gaps** — unhandled errors, edge cases, migration and rollback, concurrent access, empty or oversized inputs
- **Testability** — can each requirement be verified? Which ones have no observable outcome?
- **Unstated assumptions** — what the spec takes for granted about environment, data, or user behaviour
- **YAGNI** — anything that could be cut without hurting the stated goal

Structure `SPEC_REVIEW.md` as:

- A one-paragraph verdict: ready to implement, ready with fixes, or needs rework
- The findings, ordered by severity, blockers first. Each one gets a severity (blocker / should-fix / nit), the spec section it lives in, what's wrong, and a concrete suggested fix
- A short "what's good" section naming what is already solid and shouldn't be churned

Quote the spec where quoting makes the finding concrete. Don't pad the review to
look thorough — if the spec is good, say so and keep it short.

This is a review only: do not edit the spec, and do not implement anything.
`SPEC_REVIEW.md` is gitignored, so leave it uncommitted.
