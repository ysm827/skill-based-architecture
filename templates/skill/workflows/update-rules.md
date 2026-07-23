# Rule Update Workflow

Use this workflow after Task Closure decides knowledge is worth recording, when the user explicitly asks to record it, or when an existing rule is inaccurate. Closure decides **whether**; this file decides **what, where, and how**.

## Classification Guide

- Long-lived must/must-not constraint → `rules/`
- Ordered task procedure or completion check → `workflows/`
- Architecture, routing, code map, dependency explanation → `references/`
- Stable project-specific macro business types/flows/states/boundaries/invariants → routed `references/business/<module>.md`
- Pitfall, footgun, failed approach → `references/gotchas.md` or a routed domain pitfall file; promote a short warning to SKILL.md only when it must surface earlier
- Agent behavior miss → `references/behavior-failures.md`
- Frozen plan provenance → `docs/plans/`; load-bearing conclusions must also enter an active destination above
- Personal preference useful only to this user → the harness memory system, not project skill docs

## Task Closure Boundary

[`task-closure.md`](task-closure.md) is the only正文 source for the Trigger Policy, closure steps, Rationalizations, Red Flags, and AAR. Do not copy those sections here. This workflow owns recording threshold, fidelity, reconciliation, destination, activation, durability, and retirement.

## Recording Gates

Run these gates in order. A record that fails any gate does not ship.

### Recording Threshold

For new knowledge, at least two must pass:

1. **Repeatable** — likely to recur.
2. **Costly** — absence wastes meaningful time or causes regressions.
3. **Not obvious** — code alone would not quickly reveal it.

Outdated or false existing content is corrected directly; it need not re-earn the threshold.

### Evidence / Upgrade Gate

- For discipline rules whose only job is changing behavior under pressure, require an observed/known failure or run a baseline scenario; do not codify a hunch.
- For external absorbs, benchmark/eval lessons, major template/default-scaffold changes, Always Read/routing changes, or reusable mechanisms, require the user's approval of an exact upgrade plan before editing.
- State the evidence, net benefit over context/complexity cost, why a lighter destination is insufficient, and the cheapest meaningful validation.

### Fidelity Gate

Do not persist a lossy conversation summary. Preserve every fact that changes a future decision:

- the definition or identity being distinguished;
- applicability conditions;
- boundary, counterexample, or forbidden case;
- the reason/consequence that explains why the distinction matters.

No fixed four-section template is required. The test is semantic: can a fresh Agent, reading only the proposed record, reconstruct the same key judgment without the conversation? If not, restore the missing load-bearing meaning before writing.

Creating a business model or changing its macro types, flow direction, states, boundaries, or invariants also requires a user-facing read-back of the final durable meaning. Approved-but-unimplemented semantics stay in the Plan until code, tests, and behavior land.

### Reconciliation Gate (search before record)

Search likely destinations and read the nearest 3–5 candidate entries, not the entire library by default:

```bash
grep -ri "<concept/root cause>" skills/<name>/rules/ skills/<name>/references/ skills/<name>/workflows/
grep -E '^#{2,3} ' <candidate-file>
grep -oP '\*\*\[([^\]]+)\]' <candidate-file> | sort | uniq -c | sort -rn
```

Then choose exactly one outcome:

1. **No write** — an existing entry already covers the durable meaning.
2. **Extend in place** — same root cause or rule, new symptom/condition/counterexample.
3. **Correct in place** — existing meaning is inaccurate or over-broad.
4. **Retire** — premise no longer exists; delete or mark a scoped legacy remainder.
5. **Add independently** — genuinely different root cause/constraint with its own activation path.

For Gotchas this five-way decision is mandatory. Different symptoms of one root cause belong in one entry. Never default to appending at file end, and never preserve chronology as document structure.

### Activation Check

No new reference or business-model content ships without a declared path that is both reached and acted on:

1. Which exact route, workflow line, rule summary, or selecting index will lead the next relevant task here?
2. Is that trigger guaranteed to fire for the task the record protects?
3. What next action changes after reading it — a file opened, check run, branch rejected, or workflow selected?

If no answer exists, add the nearest pointer in the same change, promote a concise constraint into a routed rule/workflow, or skip the record. `audit-orphans`, route reachability, and smoke tests prove structural reach, not actionability.

At Single-file tier, do not escalate the architecture merely to store one lesson. At Folder-light tier, a SKILL.md route or rules bullet may activate it. A recorded + activated landmine that causes another verified costly miss may graduate to a machine gate in the triggering tool, with a scoped escape hatch.

## Placement and Shape

Choose the lightest shape that preserves meaning:

| Need | Shape |
|---|---|
| One sentence that fits an existing rule/entry | edit that entry in place |
| Several conditions/explanations on an existing topic | expand the matching section |
| Distinct procedure or independently routed topic | new section/file only if it has its own load reason |

Place content under the most relevant H2/H3 in logical order. Create a new section at the correct conceptual position only when no section fits. A file index is valid only when multiple independent files exist and task signals use the index to select the next read; a passive directory listing is not activation.

Gotcha/rule entries use a reusable `**[topic]**` tag. Reuse existing tags; repeated tags are a prompt to compare root causes, not permission to accumulate parallel entries.

### Generalization Rule

Apply the durability test that matches the destination:

- Generic rules, workflows, architecture notes, and gotchas must make sense in another project of the same type: `specific finding → reusable pattern → consequence`.
- Business global models are intentionally project-specific. They must instead be **cross-implementation stable**: after renaming modules/classes and replacing APIs, storage, or frameworks, the macro business statement remains true.

Do not force business names out of a business model merely to make it cross-project generic. Do not put code names, fields, paths, or one-off requirements into it merely because they are project-specific.

## Sync Targets

| Change | Required follow-up |
|---|---|
| New/renamed workflow or reference | update `routing.yaml`; run `scripts/sync-routing.sh` |
| Route/Always Read/entry routing changed | regenerate SKILL.md and thin-shell blocks from `routing.yaml` |
| Rule/reference meaning changed | grep workflows for repeated invariants and update stale copies |
| Plan completed | reconcile load-bearing conclusions into active destinations; set truthful `distilled_to:` |
| Business model implemented/changed | update model, code, tests, and routed activation in the same completing task |

## When NOT to Record

- one-off workaround or minor preference;
- fact immediately obvious from code or already covered by official docs;
- session transcript, chronological debug log, or date-named narrative under `references/`;
- unconfirmed inference presented as intent;
- “later” business-model candidate — keep it only in the current session, with no file/directory/index/route;
- content whose only purpose is moving an eval/benchmark score (Goodhart test: would you write it without the metric?).

## Learn, Correct, Retire

When a task exposes a documentation failure, classify it before editing:

1. missing knowledge → threshold + all recording gates;
2. outdated/inaccurate knowledge → correct in place and check consumers;
3. obsolete premise → delete, or scope a temporary legacy remainder with reason/date;
4. rule existed but was missed → improve its activation/prominence instead of duplicating it.

When deleting/renaming a file, update routing and inbound links, run sync, and inspect orphan/reachability results. For durable knowledge, deletion additionally requires a reviewable destination, owner, normal activation path, fitted validation, and an explicit account of intentionally unretained content. Put this proof in the existing Plan or migration record; do not create a fixed ledger solely to satisfy the gate. Use `maintain-docs.md` for full-file reorganization, split/merge, index, and independent-load-reason audits.

## Completion Criteria

- [ ] Destination was classified before writing
- [ ] New knowledge passed threshold/evidence gates; outdated content was corrected directly
- [ ] Fidelity preserved definitions, conditions, boundaries/counterexamples, and reasons
- [ ] Reconciliation selected no-write / extend / correct / retire / independent-add
- [ ] Gotchas were merged by root cause and placed by topic, not appended chronologically
- [ ] Generic content passed cross-project generalization; business models passed cross-implementation stability
- [ ] New/changed content has an action-changing activation path
- [ ] Routing, generated entries, consumers, and plan `distilled_to:` were synchronized where triggered
