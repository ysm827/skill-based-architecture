# Task Execution Protocol

Use this after matching the task route when the task is not one clear action with one direct check. It controls this task's goal and progress; the matched Domain Workflow remains authoritative for task-specific procedure and mandatory gates. Simple tasks skip this protocol.

## Task Classifier

| Class | Signal | Action |
|---|---|---|
| Simple | one clear action, one direct check, little room to drift | execute directly; do not display an Anchor or Plan |
| Managed | dependent steps, meaningful boundaries, repeated verification, or material drift risk | establish a Task Anchor, use a concise Native Plan, and present only useful alignment |
| Design | unresolved product/architecture choice, materially different interpretations, or irreversible decision | use `plan-feature.md`; after approval, convert its result into a Managed task |

Do not classify by tool-call count or file count. Ask whether keeping an explicit goal changes how the task should proceed.

## Task Anchor

Before mutation on a Managed task, establish current-Session state with one observable Goal, Done When evidence, and only material Boundaries such as scope, non-goals, preservation requirements, permission, or approval limits. Derive a concise Native Plan from the matched Domain Workflow.

The Task Anchor is runtime state, not a fixed chat template.

### Presentation Gate

Evaluate **Structured Brief first**. If any Structured condition matches, it wins; Compact Alignment is allowed only when all Structured conditions are false.

- **Structured Brief**: trigger when the task is long, complex, scope-sensitive, confirmation-dependent, or lacks a visible native Plan surface. The first user-facing task-start message MUST begin with separate Goal, Done When, material Boundaries, and Steps sections in the user's language. Steps must be numbered; do not collapse the brief into prose or render empty headings:

```text
<localized Goal heading>
<observable outcome>

<localized Done When heading>
<goal-level evidence>

<localized Boundaries heading, only when material>
<scope, non-goals, preservation, or approval limits>

<localized Steps heading>
1. <task-specific step>
2. <task-specific step>
```

- **Compact Alignment**: only when no Structured condition matches, use natural-language alignment if it helps the user verify direction, usually one short sentence covering the outcome, completion proof, and any material boundary. If the native Plan/Task surface is visible, do not repeat its steps in chat.

Do not expose protocol labels merely to prove an Anchor exists. After any needed alignment, proceed without waiting unless a blocking design choice, authority boundary, shared/irreversible action, or scope expansion requires user input.

Use the harness's native Plan/Task surface to hold step state. If none exists, keep a concise checklist in the current session. This protocol does not create durable planning files or recover task state across Sessions.

## Workflow Boundary

- Workflow is the reusable procedure for a task class; Native Plan is its task-specific instance.
- The user-visible Plan may group internal Workflow steps, but cannot omit or reorder a mandatory gate in a way that changes its meaning.
- Workflow owns domain checks; Task Anchor owns this task's Goal, Done When, and material Boundaries.
- Runtime step status belongs to the Native Plan, never to the reusable Workflow document.

## Recitation Loop

Before each main Plan step, bring a compact Anchor Checkpoint into current attention:

```text
Goal: <the unchanged observable outcome>
Done When: <the remaining goal-level evidence>
Current Step: <its output and check>
Boundaries: <only those relevant now>
```

Run the checkpoint again after a later user message, a failed check or surprising premise change, a Subagent return, an interruption/compaction, and immediately before scope expansion, a shared/irreversible action, or Closure. Keep it internal unless a status update or changed Goal matters to the user; do not narrate it before every tool call.

If the Goal or Done When can no longer be stated accurately from the current Session, stop mutation and reconstruct them from the user request, matched route, and Workflow before continuing. Do not invent missing task state or create persistence as a fallback.

## Execution Loop

1. Keep exactly one main step active; pending steps remain explicit.
2. Run the Anchor Checkpoint, then name the current step's output and check before acting.
3. Mark the step complete only after its check passes. Code written, effort spent, or a worker's claim is not completion evidence.
4. Before advancing, confirm the next step directly serves the Goal and still respects Boundaries.
5. If evidence changes the premise, scope, ordering, or Done When, update the Anchor and remaining Plan before more mutation. Tell the user when the Goal itself must change.
6. Never silently overwrite a load-bearing conclusion. Re-check the chosen approach, acceptance, Boundaries, and Task Anchor; obtain the business owner's confirmation before adopting a normative business judgment.

Independent Subagents may work concurrently, but the main task keeps one integration/decision focus. Their outputs are candidate evidence until the main Agent reviews them and runs the owning step's check.

## New Message Gate

For each later user message in the same session:

- refinement/correction of the current outcome -> update the current Anchor and remaining Plan;
- new independent outcome -> re-match the route and replace the old Anchor/Plan;
- status question -> report Goal, current step, and verified results without changing state;
- pause/stop -> stop advancement and leave unverified steps incomplete.

## Exit To Closure

Enter `task-closure.md` only when every admitted Plan step is verified, the Goal's Done When evidence is present, material Boundaries were respected, and no stale Plan branch remains. Task Closure verifies and reports the integrated result; it does not finish incomplete execution work.
