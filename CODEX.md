# CODEX.md

This repo is the **skill-based-architecture** meta-skill itself. Formal docs live at the repo root (self-hosting layout, see [references/layout.md](references/layout.md)). Read [SKILL.md](SKILL.md) first — it is the router.

<!-- SELF_ROUTING_BLOCK_START -->
## Quick Routing (survives context truncation)

Task routes live in `references/self-hosting-routing.yaml`.

For every new task:
1. Read `SKILL.md`.
2. Read `references/self-hosting-routing.yaml`.
3. Match by `labels`, `trigger_examples`, and task intent.
4. Read only that route's `required_reads`, then follow its `workflow`.
5. If no route matches, use the `other` route.
<!-- SELF_ROUTING_BLOCK_END -->

## Auto-Triggers

- **New task in same session** → always re-match the route above; re-read route files only after a route change or compaction. Then execute one clear action/check directly, otherwise follow `templates/skill/workflows/task-execution.md` to establish a Task Anchor, present only useful alignment, use the harness-native Plan without repeating visible steps in chat, and run its compact Anchor Checkpoint before each main step. This is Session recitation, not planning-file persistence. Can't tell if context compacted? Re-read.
- Closure checks fire by **blast-radius bucket** (path-based classification of files changed):
  - **A** (entry shells / SKILL.md / routing yaml / scripts / `*.tpl`) → full AAR + smoke-test + path-integrity gates
  - **B** (template rules/workflows non-example, references linked from SKILL.md, `workflows/full-migration.md`) → lightweight AAR only
  - **C** (README, examples, docs, UPSTREAM-CHANGES, references not linked from SKILL.md) → skip closure entirely
  - Multiple files in one task → take the max bucket. Path not in any list → default B. Trivial edit (typo / whitespace) in an A-bucket file still = full closure (bucket measures *what could break*, not *what changed*).
  - Pure Q&A / code explanation / read-only investigation / advice with no file changes → exempt; no AAR, no smoke-test.
  - Full path lists + canonical bucket rules: `references/protocols.md` § Task Closure Protocol.
- When adding to `templates/` → apply the "would two real projects disagree?" admission test (`templates/ANTI-TEMPLATES.md`)

## Red Flags — STOP

- "Just this once I'll skip the AAR" → stop. See `templates/skill/workflows/task-closure.md` § Rationalizations to Reject.
- "I'll inline this in SKILL.md instead of linking a reference" → stop. SKILL.md stays within dual budget (description ≤ 25 + body ≤ 90 lines); content goes to `references/` or `templates/`.
- "Let me pre-fill a gotchas example so the template feels complete" → stop. `templates/ANTI-TEMPLATES.md` forbids project-specific content in templates.

## Codex-specific notes

- When executing `WORKFLOW.md` phases, prefer sequential edits over bulk rewrites — Codex's `apply_patch` works best on focused diffs.
- When modifying `templates/`, run `bash templates/skill/scripts/smoke-test.sh <test-name>` against a sample target before declaring completion.
