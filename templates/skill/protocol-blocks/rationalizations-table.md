# Rationalizations to Reject

Drop this block into any project workflow that enforces Task Closure Protocol, AAR, or other discipline the agent is tempted to skip under pressure. Every row is a captured-verbatim excuse from a real pressure-test failure — do not argue with them, just refuse.

| Rationalization | Reality |
|---|---|
| "This task was small — AAR is overkill" | Small tasks are where lessons hide. The AAR scan takes 30 seconds; skipping is slower than doing |
| "I'll run AAR at the end of the session" | You will forget. The scan must happen at task closure, not batched |
| "Nothing new happened, just a routine fix" | If nothing new happened, the scan returns "no" on all four questions in 30 seconds. Do it anyway |
| "The user is in a hurry" | The protocol exists *because* hurry produces the worst pitfalls. Pressure is a reason to run AAR, not skip it |
| "I already know this lesson, don't need to record" | Recording is for future agents, not past you. Current knowledge is not durable across context boundaries |
| "This is covered by the existing rules" | Then the scan returns "no" in 10 seconds. Faster to run it than argue about it |
| "There are 3 subtasks, so I should dispatch 3 subagents" | Task count is not worker count. Dispatch only independent workstreams with positive Net Benefit and real overlap; otherwise stay inline |
| "The worker almost got it right, so I must re-dispatch" | Re-run the Admission Gate on the remaining delta. A small reviewed correction may now be cheaper inline |
| "I already read SKILL.md for the previous task" | The new task may match a different route. Context compresses silently. Re-read costs seconds; skipping costs hours of wrong-direction work |
| "User said 'record this' — I'll also archive the full session as YYYY-MM-DD-session-notes.md in `references/`" | "Record" means extract a **generalized, reusable lesson** into `rules/` or `references/<topic>.md`. Dated session narratives belong in `git log` / `CHANGELOG`, never in `references/`. `references/` rejects date-named narrative files — they violate the generalization rule (project-specific story, not reusable knowledge) and the activation rule (no routing path will ever read them) |
| "This agent is unstable — the model must not be smart enough" | Before blaming the model, run the **four-primitive audit**: does the system have (1) **state** tracking, (2) node-level **validation**, (3) **orchestration** with checkpoints, (4) **recovery** paths? Three "no"s means it is a harness problem, not a model problem — prompt re-tuning cannot patch a missing harness |
| "It crashed — I'll just rerun the migration from the start" | Re-running amplifies pollution. A half-completed Phase 5 leaves `{{NAME}}` stubs that a Phase 3 rerun cannot see; Phase 8 then passes on a broken tree. Either **detect-and-resume** via `.migration-state`, or `rm -rf` the skill tree first. No in-between |

<!-- OPTIONAL: add project-specific rows captured from Phase 9 pressure tests. Every row must be a verbatim rationalization the agent produced, not a hypothetical. -->

**How to use this table:** When the agent catches itself thinking any phrase in the left column, it must stop and re-read the right column. Do not negotiate. The table grows by pressure-testing, not by imagination.
