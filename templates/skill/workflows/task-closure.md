# Task Closure Protocol

This is the completion-time gate for behavior, rule, routing, script, and structure changes. Recording mechanics live in [`update-rules.md`](update-rules.md); file-boundary and path-integrity mechanics live in [`maintain-docs.md`](maintain-docs.md).

## Task Closure Protocol

### Entry Gate

Closure starts only after execution is complete. For a Simple task, the direct check and goal evidence must exist. For a Managed or Design-derived task, first run the final Anchor Checkpoint; the Task Anchor's Goal and Done When must be satisfied, every admitted Native Plan step must have passed its check, material Boundaries must remain intact, and no stale Plan branch may remain.

If any condition is missing, return to [`task-execution.md`](task-execution.md); do not use Closure to finish execution work. A Plan status or worker claim is not evidence by itself.

### Trigger Policy

| Task | Required closure |
|---|---|
| Pure Q&A/read-only advice with no file change | none |
| Formatting/comment/behavior-preserving rename with no reusable lesson | relevant text check only |
| Production behavior, API/schema, validation, state, transaction, async, or call-chain change | fresh verification + lightweight AAR |
| Rule/reference/workflow meaning change | AAR + triggered reconciliation/activation checks |
| Routing, SKILL/shell, script, generated block, file path, or skill structure change | full structure/path closure |
| User explicitly requests full validation | run the requested suite |

`smoke-test.sh` is for skill structure/routing/links, not ordinary code changes.

### Closure Steps

1. **Read back the contract** — restate the Task Anchor (or Simple-task outcome), matched route, Goal-level acceptance evidence, material Boundaries, and forbidden shortcuts. After a long/interrupted task, use `protocol-blocks/reboot-check.md`.
2. **Verify with fresh, fitted evidence**:
   - targeted command/test/typecheck first;
   - runtime/service/browser evidence only for wiring, config, permissions, serialization, data state, or UI behavior;
   - packaged/release/deploy evidence only when that chain changed or the user requires it.
   A fresh command against a stale artifact is not fresh evidence.
3. **Run the AAR below.** Any yes enters `update-rules.md`; all no stops recording.
4. **Run conditional integrity work**:
   - routing/shell/generated-block or structure/path changes → follow `maintain-docs.md` Step 6 and the repository's sync/smoke commands;
   - rule/reference meaning changes → search workflows for repeated invariants and reconcile them in the same change;
   - durable knowledge migrated/deleted/superseded → prove destination, owner, normal activation path, fitted validation, and intentionally unretained content before removing the legacy source; use the existing Plan/migration record rather than creating a mandatory ledger;
   - high-risk route, non-idempotent workflow, executable script contract, or external handoff → add/adjust a behavior contract only when structural checks cannot prove it.
5. **Report honestly** — name verified evidence and any unverified risk; do not self-certify beyond the checks run.

### Rationalizations to Reject

| Rationalization | Reality |
|---|---|
| “The change is small.” | Behavior/structure is the trigger; read-only work is already exempt. |
| “Tests passed earlier.” | A completion claim requires fresh evidence after the final edit. |
| “I will reconcile links/rules later.” | The decision context will be gone; do it in the same change. |
| “The file exists and smoke is green.” | Reachable structure can still be inert; state the next action it changes. |
| “I should add a safeguard just in case.” | No concrete recurring failure means no new mechanism. |

### Red Flags

- claiming “done/should pass” without reading a fresh exit code;
- recording by appending instead of reconciling the existing concept;
- creating a file/index with no independently selected task path;
- treating optional delegation or future infrastructure as a completion requirement.

## After-Action Review

Ask only after Trigger Policy admits the task:

1. Did this reveal a repeatable costly pattern not obvious from code?
2. Did a missing rule or activation path cause a wrong turn?
3. Did an existing rule become inaccurate, obsolete, duplicated, or inert?
4. Did an external fact materially affect the decision and need scoped re-verification guidance?

Any yes → apply `update-rules.md` threshold, fidelity, reconciliation, activation, and durability gates. Otherwise do not create a record.
