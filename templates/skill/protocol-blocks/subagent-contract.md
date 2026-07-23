# Subagent Contract
Every subagent dispatched through [`subagent-auxiliary.md`](../workflows/subagent-auxiliary.md) or [`subagent-driven.md`](../workflows/subagent-driven.md) gets this dispatch/return envelope. Paste only the contract, not the main conversation history.
From a plan? Task heading → Task Ref; Files+Produces → Outputs; Files+Consumes → Inputs; other tasks' files → Forbidden Zones; Acceptance → Acceptance Criteria.

```markdown
## Task Ref
<!-- FIELD: Native Plan step, issue, or stable current-task identifier. -->
## Role
<!-- FIELD: explore | implement | review | verify. Task role, not a harness agent type. -->
## Goal
<!-- FIELD: one sentence, outcome-focused. E.g., "Extract the retry logic in api/client.ts into a reusable helper with identical behavior." -->
## Inputs
<!-- FIELD: exact file paths/artifacts the worker may read. Nothing implicit. -->
## Outputs
<!-- FIELD: exact file paths the worker must create or modify. -->
## Forbidden Zones
<!-- FIELD: files, directories, or side effects the worker must NOT touch. -->
## Acceptance Criteria
<!-- FIELD: literal checks the main agent will run in Phase 3 Stage A. -->
## Evidence
- Context Read: <!-- exact paths/artifacts actually read -->
- Files Changed: <!-- exact paths, or none -->
- Checks Run: <!-- command/check plus observed result -->
- Remaining Risks: <!-- scoped concerns, or none -->
## Return Status
<!-- Worker ends with exactly ONE word: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED -->
```

Dispatch rules: no field may be empty; Forbidden Zones default to deny; Acceptance Criteria must be rerunnable commands or `git` checks; if the contract is wrong, the main agent rewrites and re-dispatches.
Return rules: Evidence is a provenance index, not proof; the main agent checks the diff/paths and reruns Acceptance Criteria. Missing Evidence or a bare "done" is invalid.

| Status | Meaning | Controller response |
|---|---|---|
| `DONE` | All Acceptance Criteria pass, no reservations | Run Phase 3 Stage A + B, then merge |
| `DONE_WITH_CONCERNS` | Criteria pass, but a scoped risk remains | Read concern before merging; queue follow-up if non-trivial |
| `NEEDS_CONTEXT` | Inputs were insufficient to finish; worker names exactly what is missing | Do **not** patch inline — widen `Inputs`, re-dispatch |
| `BLOCKED` | An obstruction the worker cannot resolve (permission denied, tool unavailable, contract self-contradictory) | Resolve the blocker — surface to the user per the Interception Transparency Rule when you cannot — then re-dispatch |
