# Refactor Fan-out Workflow

> This workflow identifies possible fan-out; it does not require it. Keep the refactor inline unless several non-overlapping batches pass [`subagent-driven.md` § Delegation Admission Gate](subagent-driven.md#delegation-admission-gate) with positive Net Benefit. Never create workers by file count alone.

Use this for refactors that touch **N independent usage points** of the same construct: renaming a function across 30 files, changing an API signature with many callers, extracting an interface with multiple implementations, migrating a config key.

For single-region refactors (one file, one component), use `workflows/change-managed.md` instead — subagent dispatch only pays off when the work genuinely fans out.

## When to Use

Trigger this workflow when **all** of these are true:

- The change has **one well-defined source-of-truth edit** (the new name, signature, or interface) PLUS **≥ 5 independent application sites** that must follow
- Application sites are **independent**: changing one does not require reading the others' diff
- The same edit pattern repeats across sites (rename, swap call, adapt to new signature) — not bespoke per-site logic
- At least two batches have independent writable ownership, and parallel execution saves more than contract/review/integration cost

If any condition fails: use `change-managed.md` and do the change sequentially in the main context. Even when all pass, use the fewest batches that create real overlap; `≥ 5` sites is an inspection threshold, not a worker quota.

## Harness Compatibility

Same as [`subagent-driven.md` § Harness Compatibility](subagent-driven.md#harness-compatibility-shared-by-both-modes) — full parallel dispatch on Claude Code (and Codex with global authorization); degraded harnesses run the batches sequentially with contract discipline: you keep the safety, you lose the parallelism.

## Three Phases

### Phase 1 — Find usage + plan cut-points

Done by the main agent in the main context.

1. **Locate the source-of-truth edit** — the function, type, signature, or config key whose definition will change. Read it.
2. **Find all usage sites** — `grep -rln`, IDE references, or a language-server-driven search. Produce the **literal list** of files (and the line ranges within each, when a file has multiple sites).
3. **Decide cut-points** — group sites into N batches such that:
   - Sites in the same batch can be edited without reading sites in another batch
   - Each batch is roughly even in size (avoid one giant batch + several trivial ones)
   - Shared files (a file containing sites from multiple batches) become a **Forbidden Zone** for all but one batch, or get edited in a Phase 0 by the main agent before fan-out begins
4. **Write down the plan** — list each candidate batch with: files included, the literal transformation, acceptance check, expected parallel gain, and main-thread work. Persist this in `docs/plans/YYYY-MM-DD-<slug>/` if the work justifies a plan folder; otherwise inline in the conversation.

**Stop condition for Phase 1**: the list of batches + per-batch acceptance check is fully written before dispatching the first worker.

### Phase 2 — Fan out

Re-run the Admission Gate after cut-points are known. Dispatch only the admitted batches; execute the others inline. Use the **Subagent Contract** format from `workflows/subagent-orchestration.md` Phase 1:

| Field | What goes here |
|---|---|
| **Goal** | "Apply *<the literal transformation>* to all usage sites in *<the list of files>*; do not change behavior beyond the transformation." |
| **Inputs** | The transformation rule (one-line spec), the list of files for this batch only, and the source-of-truth definition the new shape was derived from. **Do not** pass the full usage list across batches — each worker sees only its own slice. |
| **Outputs** | The diff for the batch's files. |
| **Forbidden Zones** | All files not in this batch, plus any "drive-by" edits (no formatting fixes, no comment polish, no rename of nearby identifiers). |
| **Acceptance Criteria** | The literal check from Phase 1 (e.g., `grep -c 'oldName' <files>` returns 0; `bash <test-command>` exits 0). |

Dispatch admitted batches together. Worker count cannot exceed independent batches, and physical-region splits created solely to increase parallelism are forbidden. Continue the named main-thread work; do not dispatch and immediately wait.

### Phase 3 — Merge + verify

When workers return, the main agent runs **two stages** per batch (same as `subagent-orchestration.md` Phase 3):

**Stage A — Spec compliance**

- [ ] Worker touched only its batch's files (`git diff --stat` confirms)
- [ ] Acceptance check passes when re-run by the main agent
- [ ] No drive-by edits

If Stage A fails: reject the diff and re-run the Admission Gate; re-dispatch or fix inline according to the remaining work's current Net Benefit.

**Stage B — Cross-batch consistency**

After all batches' Stage A pass, the main agent runs the **whole-repo check**:

- [ ] `grep -c '<old-pattern>'` across the **entire repo** returns 0 (or only in expected leftovers — declared in Phase 1)
- [ ] The smallest whole-refactor regression and risk-triggered checks pass; a full suite runs only when the change's blast radius or release contract requires it
- [ ] No two batches introduced inconsistent variants of the new pattern (e.g., one batch used `newName` and another used `new_name`)

If Stage B finds inconsistencies → record which batch deviated and re-run the Admission Gate for the correction; do not preserve fan-out by inertia.

## Rationalizations to Reject

| Rationalization | Rebuttal |
|---|---|
| "There are 5 sites, so the workflow requires workers" | Five sites only triggers cut-point analysis. Dispatch still needs independent batches, real overlap, and positive Net Benefit. |
| "I'll split identical sites by physical region to fill slots" | Slots are not workstreams. Use the fewest coherent batches; stay inline if coordination erases the gain. |
| "I'll let the worker also fix the typo I noticed nearby" | Drive-by edits violate the contract. Drive-bys are how refactor PRs become unreviewable. Open a follow-up task. |
| "Phase 1 takes too long, I'll just start dispatching" | The cost of a wrong cut-point at Phase 1 is wasted dispatches. The cost of a Phase 1 thirty seconds longer is thirty seconds. |
| "The whole-repo grep in Stage B is paranoid" | The whole-repo grep is exactly how you catch the site you missed at Phase 1. Run it. |

## Red Flags — STOP

- You catch yourself rewriting the contract mid-batch → cancel, fix the contract, re-dispatch.
- Two workers' diffs overlap on the same file → Phase 1 had a bad cut-point. Revert, redo Phase 1.
- A worker asks for the "context" of the broader refactor → contract too narrow. Cancel, expand `Inputs`, re-dispatch.
- The whole-repo grep in Stage B finds matches you didn't expect → there are sites you missed; do not merge until each is decided (in a new batch, or as an intentional leftover).

## Closure

After all batches merge and Stage B passes: run the **Task Closure Protocol** from `workflows/task-closure.md` exactly once (not per batch). A multi-site refactor often produces one or two real lessons — about the old shape, the new shape, or the migration mechanic itself. Apply the recording threshold.

<!-- OPTIONAL: project-specific Stage B commands (test runner, lint, type-check) -->
<!-- OPTIONAL: project-specific Forbidden Zone defaults (e.g., migrations/, vendored deps) -->
