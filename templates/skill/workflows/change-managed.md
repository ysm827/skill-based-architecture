# Change-Managed Workflow

> **Inline by default.** Delegate only after [`subagent-driven.md` § Delegation Admission Gate](subagent-driven.md#delegation-admission-gate) proves positive Net Benefit and real concurrent main-thread work. A mechanical batch is still inline when dispatch/review costs or dependency order erase the gain.

Use this for non-bug changes where partial edits can create drift: new features, refactors, optimizations, route changes, generated/copied files, shared configuration, or any change with multiple derived targets.

## Mandatory Pre-Step (cannot skip)

**Re-run `SKILL.md` § Session Discipline before starting.** Re-match the request against Common Tasks; re-read the route's files only if the route changed or context was compacted (see § Session Discipline); stop for clarification if the request is vague about scope or success criteria.

## Read First

1. Re-open `SKILL.md` → match this change to a Common Tasks route
2. Apply `references/minimal-sufficient-context.md`; start with the route's core files and the smallest source-of-truth slice
3. Expand to task-relevant `rules/*.md` or `references/*.md` only when scope, ownership, generated files, contracts, permissions, config, or shared runtime state require it
4. If the change touches templates, scaffolds, copied shell blocks, generated files, or reusable project structure, switch to `workflows/edit-templates.md` or run its template-specific checks as a sub-step

## Steps

1. **Define scope** — name the exact files/modules owned by this change and the observable outcome that proves it worked. **Permission check (opt-in):** if the project uses a permission model, decide up front whether this is an *Ask-first* operation (crosses a contract, hard to reverse, blast radius beyond the task) → propose and stop for the user before editing; or *Never* → refuse. This is a **pre-execution authority** check — distinct from the **post-edit** blast-radius buckets in [`task-closure.md`](task-closure.md) (which gauge closure rigor, not permission). See [`../references/permission-model.md`](../references/permission-model.md).
2. **Find the source of truth** — identify whether the changed content is canonical or derived. If derived, edit the canonical source first and use the project's sync/generation command.
3. **Map fan-out targets** — list every file that must stay in sync before editing. Include thin shells, generated configs, docs indexes, tests, and registration files when relevant. Stay inline for one dependency chain or a small same-context batch. Use [`refactor-fanout.md`](refactor-fanout.md) only when several non-overlapping batches pass the Delegation Admission Gate; do not create a worker per file.
4. **Make the smallest coherent change** — avoid opportunistic cleanup outside the declared scope.
5. **Sync derived files** — run the project-specific generator, sync script, formatter, or manual copy step required by the source-of-truth mapping.
6. **Run drift checks** — run the project-specific drift/integrity checks. If none exist, compare the fan-out targets manually and consider recording the missing check via Task Closure Protocol.
7. **Validate behavior** — run the most targeted tests, smoke checks, or manual verification for the changed behavior.
8. **Run Task Closure Protocol** from `workflows/task-closure.md` — mandatory before declaring completion.

## Completion Checklist

- [ ] Scope and success criteria are explicit
- [ ] Canonical source vs derived files identified
- [ ] All fan-out targets updated or intentionally left unchanged with a reason
- [ ] Sync/generation step run when derived files exist
- [ ] Drift/integrity check run, or manual comparison completed
- [ ] Targeted validation completed
- [ ] Task Closure Protocol was run

<!-- OPTIONAL: project-specific sync/drift commands, for example `bash scripts/sync-*.sh`, `bash scripts/check-*.sh`, codegen, formatters, or schema validators. Also declare the cheapest-sufficient validation path (e.g. hot-reload dev server instead of a full production build) and the conditions that escalate to the expensive one (release evidence, cross-module contract change, build-chain edits). -->
