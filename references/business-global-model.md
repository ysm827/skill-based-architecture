# Reference — Business Global Models

Use this optional pattern for product/business projects where an Agent repeatedly needs stable domain meaning before it can plan or classify a bug. Do not install it for every project and do not create empty `references/business/` placeholders.

## Contents

- [What belongs here](#what-belongs-here)
- [Lifecycle and storage shape](#lifecycle-and-storage-shape)
- [Trigger paths](#trigger-paths)
- [Current baseline, not future fiction](#current-baseline-not-future-fiction)
- [Plan and bug-fix consumption](#plan-and-bug-fix-consumption)
- [Semantic read-back](#semantic-read-back)
- [Routing recipe](#routing-recipe)
- [Orthogonal task and domain routing](#orthogonal-task-and-domain-routing)
- [Cross-owner reads](#cross-owner-reads)
- [Provenance and retirement](#provenance-and-retirement)

## What belongs here

A business global model is project-specific but implementation-independent. It records low-volatility facts such as:

- why a module exists and where its business boundary sits;
- stable concepts, actors, type systems, or decision matrices;
- macro flow progression and business lifecycle;
- business states, permitted transitions, and terminal states;
- cross-module relationships and invariants that survive ordinary feature work.

Use the implementation-independence test:

> If frameworks, classes, APIs, tables, and storage were replaced, would this statement still be true?

If no, keep it in code maps, technical references, gotchas, tests, contracts, or the current plan instead.

Do not record:

- Controller/Manager/method names, API fields, database columns, config keys, or runtime paths;
- page/component implementation details;
- one requirement's task breakdown or rejected technical design;
- one bug's repair narrative, temporary compatibility branch, or volatile edge rule;
- unverified inference presented as business intent.

The content list is a menu, not a template quota. A module without a meaningful state machine does not need a state-machine section. Never add empty headings for symmetry.

## Lifecycle and storage shape

Start absent. Create the directory only when the first real model is confirmed:

```text
references/business/
└── merge-task.md
```

Do not create an `index.md` for one file. Split only when real tasks load the parts independently:

```text
references/business/merge-task/
├── index.md
├── types.md
└── lifecycle.md
```

Before splitting, answer all four:

1. Which real request reads this candidate without all siblings?
2. Which route, workflow, or index selects it?
3. Can it be understood without loading the siblings?
4. Does the split reduce irrelevant context?

If every caller loads and changes the files together, merge them. Line count is only a review signal. Independent generation/ownership may justify separate files, but it does not justify co-loading them at runtime.

## Trigger paths

### Project initialization

During project profiling:

1. Inspect modules, entry points, stable enums/types, states, tests, and existing docs.
2. Present only modules that appear to have durable business semantics.
3. Ask the user per candidate: model now, later, or not needed.
4. Create files only for "now".

"Later" is session-only. Do not create a candidate queue, empty file, empty index, or placeholder route. If the gap recurs in another session, detect and ask again.

### Daily work

Classify the current module knowledge before acting:

| State | Action |
|---|---|
| No model, and the gap affects the decision | Explain the missing macro meaning; ask whether to model now or continue without persistence |
| Model exists but one area is unclear | Inspect code/tests; ask only the minimal business question; update the existing file in place |
| Model conflicts with code/tests/runtime | Surface the conflict; ask which side is the correct business intent; then classify bug/design/doc drift |
| Model is sufficient | Use it without asking again |

Full modeling follows: evidence scan → remove implementation/one-off details → user brainstorm → semantic read-back → write the minimum sufficient model → activate it in routing.

## Current baseline, not future fiction

The active model describes the confirmed, effective business baseline. An approved but unimplemented semantic change stays in the plan until code, tests, and behavior land. Update the active model in the same completing task as the implementation.

When code and intended business meaning differ, keep the temporary gap and repair design in the current plan or gotcha. Do not make the live model claim behavior that has not landed.

## Plan and bug-fix consumption

For a routed business module, use this order:

```text
business global model  -> what should be true
architecture/rules     -> how the design intends to realize it
code/tests/runtime     -> what is true now
comparison             -> plan, bug fix, design change, or clarification
```

Code proves current behavior, not correctness by itself.

Before a business-sensitive bug fix, classify:

- `IMPLEMENTATION_BUG` — code violates the confirmed model; continue the bugfix loop.
- `DESIGN_CHANGE` — the proposed fix changes a type definition, flow direction, state machine, or core invariant; stop the bugfix and switch to planning with explicit user approval.
- `INSUFFICIENT_BUSINESS_CONTEXT` — there is not enough stable meaning to define the expected result; run the missing/unclear path above.

Obvious technical failures such as compilation errors, crashes, or unconditional 500s do not require business modeling unless their correct behavior is itself ambiguous.

## Semantic read-back

Do not silently compress a brainstorm into a lossy sentence. Before writing or changing macro semantics:

1. List the load-bearing definition, condition, boundary/counterexample, and reason actually needed for future decisions.
2. Draft the durable text without forcing four fixed headings.
3. Ask whether a fresh Agent could reconstruct the same key decision from the draft alone.
4. Show the user the final meaning for confirmation when creating a model or changing macro semantics.

"Type 4 is a version merge" is insufficient if the confirmed meaning also depends on source/target identities, distinction from another type, or a forbidden target.

## Routing recipe

Do not add business files to `always_read`. Prefer a direct route read while one module has one file:

```yaml
required_reads:
  - references/business/merge-task.md
```

After a module genuinely splits, route directly to the smallest known leaf. Use a module `index.md` only when it actively selects the leaf from task signals; a passive file list is not activation.

For explicit modeling requests, copy and adapt `workflows/profile-business-model.md.example`, rename it to a real workflow, and add a project-specific route. Do not add that route to non-business projects.

## Orthogonal task and domain routing

When the same domain knowledge must accompany different task workflows, do not duplicate one complete route per task/domain pair. Keep one task route to select the workflow and add `domain_overlays` only after real domain leaves exist. An overlay may append `required_reads`; it must not declare or replace a workflow.

```yaml
domain_overlays:
  - id: billing
    labels: { en: Billing domain, zh: 计费领域 }
    required_reads: [references/business/billing.md]
    trigger_examples: [账单, 计费规则, invoice policy]

tasks:
  - id: fix-bug
    labels: { en: Fix bug, zh: 修复 bug }
    workflow: workflows/fix-bug.md
    trigger_examples: [接口报错, fix this bug]
```

For each task, match exactly one task route and zero or more domain overlays, then merge Always Read + task reads + overlay reads. Keep only current-Session provenance: `task_route_id`, `domain_overlay_ids`, and `merged_required_reads`. This is a review aid, not persistent task state. Do not pre-create overlays, domain files, or an index for domains that do not yet exist.

## Cross-owner reads

When a domain has one owner but another app must consume it, keep the business model at the owner and declare an owner root instead of copying the model. Cross-owner references use `owner:<owner-id>:<path>`:

```yaml
owner_roots:
  billing-service: services/billing

domain_overlays:
  - id: billing
    labels: { en: Billing domain, zh: 计费领域 }
    required_reads:
      - owner:billing-service:skills/billing/references/business/billing.md
    trigger_examples: [账单, 计费规则, invoice policy]
```

Owner ids and roots are project declarations, never SBA hard-coded app names. Roots and target paths must be workspace-relative and may not traverse parents. Validate target existence from the real workspace root:

```bash
bash scripts/sync-routing.sh <skill-root> --check --workspace-root <workspace-root>
```

Without `--workspace-root`, the validator may prove syntax, declared ownership, and path safety only; it must report target existence as unverified rather than presenting a complete green result. The project assembler should supply this root so ordinary users do not configure it manually.

## Provenance and retirement

Requirement provenance is conditional, not a permanent double-maintenance protocol. When a requirement creates or changes durable business meaning, let the requirement name the active destination and let the active leaf retain the source requirement needed to reconstruct that decision. A migration dossier, when needed for many legacy sources, is a temporary reconciliation artifact and freezes after migration; ordinary future requirements do not keep updating it.

Before deleting or superseding durable knowledge, prove destination, owner, normal activation path, fitted validation, and any intentionally unretained content. Keep that proof in the existing Plan or migration record; do not create a fixed ledger or extra file when the same contract already fits there.
