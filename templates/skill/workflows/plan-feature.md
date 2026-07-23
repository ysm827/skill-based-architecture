# Plan Feature Workflow

> **Inline by default.** Planning evidence and decisions belong in the main context. Read [`subagent-auxiliary.md`](subagent-auxiliary.md) only for an independent, result-only research workstream with real overlap and positive Net Benefit; planned multi-workstream execution uses [`subagent-driven.md`](subagent-driven.md).

Use this for planning requests. It resolves what should be done; it is not the runtime Native Plan. Simple plans stay inline unless the user asks for a file.

## Complexity Gate

| Size | Signal | Action |
|---|---|---|
| Trivial | typo, comment, obvious one-line change | skip this workflow |
| Simple | clear goal, 1–2 files, no product ambiguity | short inline plan; at most one confirmation |
| Complex | multiple files, unclear behavior, dependency, architecture choice, or long run | create `docs/plans/YYYY-MM-DD-<slug>/prd.md` |
| Large | multi-subsystem, irreversible/expensive, high uncertainty, or many unknowns | Complex plan + read [`plan-large.md`](plan-large.md) |

## Question Gate

- **Gate A: Derivable?** Inspect code, docs, config, tests, and primary sources first.
- **Gate B: Meta/lazy?** Never ask the user to perform discovery available to the Agent.
- **Gate C: Blocking/preference?** Ask only blocking or preference questions.

Ask one question at a time and offer concrete trade-offs for preferences.

## Business-Semantics Gate

For a business-bearing module, read its routed business global model before treating code as intended behavior. Compare in this order:

1. business model — what the business says should be true;
2. architecture / rules / contracts — how the system intends to realize it;
3. code / tests / runtime — what is currently true.

Record `business-model impact: unchanged / proposed change / unknown`. A proposed change to a type system, macro flow, state machine, boundary, or core invariant is a design decision, not an implementation detail. Keep approved-but-unimplemented semantics in the Plan; update the formal model only when code, tests, and behavior land. If the model is absent or locally unclear and the gap blocks planning, follow the project's routed business-model workflow: ask whether to model now only when completely absent; otherwise search first and ask only for the missing macro meaning.

If new evidence overturns a load-bearing conclusion, do not silently replace it: re-check the chosen approach, acceptance criteria, boundaries, and Task Anchor before continuing. The Agent may verify facts, but a normative business judgment requires confirmation from the business owner.

## Brainstorm — Diverge Before Converging

For Complex/Large work, inspect adjacent evidence, then generate at least two genuinely different solution shapes with honest trade-offs. For Large or highly ambiguous work, present the chosen design and obtain buy-in before writing Task Breakdown. Trivial/Simple work skips this.

## Complex Plan

Create only `prd.md` initially; add a sibling only when content has an independent loading reason. Use these section names, in order, only when warranted: Context; Problem; Options Considered; Chosen Approach; Requirements & Acceptance Criteria; Out of Scope; Task Breakdown; Open Questions.

Plans are active while `draft` or `executing`; on `done` or `abandoned`, freeze them as audit history. If the workflow-state hook is installed, point `.skill-workflow-state` at this workflow while planning and remove it at closure.

Only when the task migrates, deletes, or supersedes durable knowledge, record a compact knowledge-impact contract in the existing Plan: legacy source, active destination, owner, activation path, and validation. Do not create a migration dossier or fixed ledger for an ordinary requirement; when a many-file migration genuinely needs one, freeze it after reconciliation instead of maintaining it forever.

When the user approves the design and requests implementation, pass its chosen outcome, acceptance criteria, boundaries, and task breakdown to [`task-execution.md`](task-execution.md). That protocol creates the Task Anchor and harness-native execution Plan; do not use this design dossier as live step state.

## Task Breakdown

For two or more dependent tasks, declare an executable interface per task:

```markdown
### Task N — <verb-noun>
- **Files**: owned, shared-read-only, and forbidden paths
- **Consumes**: earlier/existing interfaces this task needs
- **Produces**: exact interfaces later tasks depend on
- **Acceptance**: literal command or observable behavior
```

Task heading maps to Task Ref; Role is chosen at dispatch; Files+Produces map to Outputs; shared Files+Consumes to Inputs; forbidden paths to Forbidden Zones; Acceptance to Acceptance Criteria. This is a possible Mode 2 handoff, not automatic delegation: task count is not worker count, and only independent, mechanically reviewable, net-positive workstreams dispatch. Projects that explicitly adopt the upstream Tests-as-Spec guide may add their own routed test-case contract here.

## Complex Steps

1. Scan related live rules, routed business models, gotchas/pitfalls, and SKILL.md Common Pitfalls; plans are not active truth.
2. Create `docs/plans/YYYY-MM-DD-<slug>/prd.md`; do not pre-create empty siblings.
3. Inspect similar code, entry points, config, tests, and current docs before questioning. A wide result-only inventory may use `subagent-auxiliary.md` only after its Admission Test passes; decision evidence stays inline.
4. Run the Question Gate; keep unknowns explicit instead of converting them into assumptions.
5. State scope, `business-model impact`, acceptance criteria, and out-of-scope items.
6. Record at least two real options when a choice exists, then the chosen trade-off. Load [`plan-large.md`](plan-large.md) only if the Complexity Gate classified the task Large.
7. Give implementers/reviewers the exact reading list and task interfaces. Invoke Mode 2 only for the independent subset with real overlap and positive Net Benefit; keep serial/core work with the main agent.
8. Before `done`, distill every load-bearing conclusion through `update-rules.md`: future constraints → rules; rejected alternatives/footguns → gotchas or Common Pitfalls; current implemented macro business facts → the routed business model; pure provenance stays only in the archive. Apply fidelity, reconciliation, and activation gates; set `distilled_to:` to actual live targets.
9. Read back requirements, acceptance, chosen approach, out-of-scope, unresolved decisions, and the plan path.
10. If implementation starts now, instantiate the approved result through `task-execution.md`; otherwise stop at the approved design.

## Decision Completeness

Before declaring ready, check decisions rather than section count: external dependency failure behavior and persisted state; concrete migration artifact for schema/contract changes; conflicts between repeated claims/cross-file links; and whether every blocker appears in Open Questions. For business work, ensure the Plan does not silently treat current code as the business baseline or place unimplemented target semantics into the formal model.

## Completion Checklist

- [ ] Complexity, Question, Brainstorm, and Business-Semantics gates were applied where relevant
- [ ] Complex plan uses only warranted canonical sections and testable acceptance criteria
- [ ] Multi-task entries declare Files / Consumes / Produces / Acceptance
- [ ] Large tasks loaded `plan-large.md`; non-Large tasks did not
- [ ] Required reading, trade-offs, out-of-scope, and unresolved decisions are explicit
- [ ] Multi-file claims/cross-links were checked for drift before freeze
- [ ] Approved implementation work was handed to Task Execution rather than tracked as mutable state in the design dossier
- [ ] On `done`, load-bearing conclusions were faithfully reconciled into activated live targets and `distilled_to:` matches
- [ ] `.skill-workflow-state` was removed or reflects the active state

[workflow-state:planning]
Keep `prd.md` short, inspect evidence before asking, and apply the business-semantics gate when macro business meaning affects the plan.
[/workflow-state:planning]
