# Workflow: Optional Auxiliary Delegation

Read this only when an ordinary task has one possible auxiliary workstream. Planned multi-workstream runs use [`subagent-driven.md`](subagent-driven.md). Inline remains the default.

## Admission Test

Delegate only when all five are true:

1. **Independent** — inputs, output, and acceptance are fixed without another decision.
2. **Result-only** — the main agent needs a compact verdict/artifact, not the traversal as reasoning substrate.
3. **Real overlap** — useful non-overlapping main-thread work starts immediately.
4. **Positive Net Benefit** — saved time/context exceeds startup, handoff, review, merge, and likely rework.
5. **Bounded fan-out** — workers match independent workstreams, not files, tests, commands, or free slots.

Any no/unknown means stay inline. One foreground worker followed by waiting is not admitted. Ordinary searches, one command/test, one-file edits, user discussion, and the next critical-path result stay inline.

## Dispatch

1. Name the main-thread work that will continue.
2. Provide Task Ref, Role, Goal, exact Inputs, expected Outputs, Forbidden Zones, and literal Acceptance Criteria.
3. Dispatch the minimum admitted workers; workers do not spawn workers.
4. Continue the named work. Wait only when every remaining critical path depends on running workers, using one bounded/event-driven wait rather than polling.
5. Verify returned Evidence and the verdict/artifact against the contract before using them; self-reported provenance does not complete the owning Native Plan step.

## Main-Agent Boundary

Never delegate user clarification, business meaning, architecture/schema/protocol/security/permission decisions, root-cause synthesis, or tightly coupled edits. A bounded implementation batch may delegate only after the main agent fixes design, ownership, forbidden zones, and acceptance.

## Interception Transparency

Optional dispatch unavailable while the task remains possible → continue inline. A required permission/tool/file/network path blocked → report the real blocker and choices. Never turn an unavailable optimization into a blocker or hide an actual one.

## Completion Check

- Admission passed before dispatch.
- Main-thread work overlapped; worker count matched workstreams.
- Main-agent judgment stayed inline.
- Contract and returned evidence were verified.
