# Workflow: Subagent Orchestration

Read this only after [`subagent-driven.md`](subagent-driven.md) admits Mode 2. The selector's bounded fan-out, positive-Net-Benefit, non-blocking, and main-agent ownership rules remain binding.

## 1. Contract

Write the full task list before dispatch. Every worker gets:

1. **Task Ref** — the owning Native Plan step, issue, or current-task identifier.
2. **Role** — exactly `explore`, `implement`, `review`, or `verify`; this is a task role, not a harness agent type.
3. **Goal** — one outcome-focused sentence.
4. **Inputs** — exact allowed files/data/artifacts.
5. **Outputs** — exact artifacts or files to return/change.
6. **Forbidden Zones** — paths and side effects it must not touch.
7. **Acceptance Criteria** — literal checks the main agent can rerun.

Every return adds **Evidence** (`Context Read`, `Files Changed`, `Checks Run`, `Remaining Risks`) and exactly one **Return Status**: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`.

Reject contracts whose acceptance cannot be checked. Reuse an existing design Plan breakdown or Native Plan step instead of re-deriving it; worker status remains local to that contract.

## 2. Dispatch

- Send independent contracts together; do not paste the conversation or let workers spawn workers.
- Continue the named main-thread work immediately; wait only when all remaining critical paths depend on workers.
- A worker runs scoped verification and reports evidence plus candidate lessons. It does **not** run project-wide Task Closure or decide what becomes durable knowledge.

## 3. Main-Agent Review

Run both stages for every return:

**Stage A — contract compliance**

- Task Ref and Role still match the owning work;
- `Context Read` stays within Inputs; main-agent `git diff`/path inspection, not `Files Changed`, proves Outputs and Forbidden Zones;
- literal acceptance checks pass when rerun;
- no drive-by change escaped the contract; worker Evidence is a provenance index, not proof.

**Stage B — quality/integration**

- result fits project rules and neighboring interfaces;
- errors, compatibility, security, and cross-batch consistency are handled;
- discovery/judgment claims get independent challenge when uncertainty is material; use [`../references/subagent-verification.md`](../references/subagent-verification.md) for open-ended searches.

A failed stage triggers a fresh Net Benefit decision: correct inline when the remainder is small/coupled; rewrite and re-dispatch only when it remains independently worthwhile.

## 4. Route the Return

- `DONE` → Stage A + B, then merge if both pass; only the main agent may complete the owning Native Plan step.
- `DONE_WITH_CONCERNS` → inspect concern, then Stage A + B.
- `NEEDS_CONTEXT` → widen Inputs only if the work remains admitted.
- `BLOCKED` → resolve or surface the real obstruction.
- Missing Evidence or status → treat as `NEEDS_CONTEXT`.

After all accepted results are integrated and their owning Native Plan steps pass the main agent's checks, the **main agent** runs Task Closure once for the complete task and decides whether any reported candidate lesson passes recording gates.

## Degraded Mode

Without native dispatch, write one contract, execute it inline from only that scope, then return to main-agent review. This preserves boundary/review discipline but does not claim concurrency.
