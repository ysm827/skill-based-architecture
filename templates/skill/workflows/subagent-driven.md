# Workflow: Subagent-Driven Development

> Delegation is an optional optimization, never a compliance target. **Inline is the default.** Use a subagent only when the Delegation Admission Gate proves a positive net benefit.

Two modes:

- **Mode 1: Optional Auxiliary Delegation** — one independently executable auxiliary workstream overlaps with useful main-thread work.
- **Mode 2: Planned Orchestration** — a complex task already contains several independent workstreams that can run concurrently under explicit contracts.

Neither mode is justified by free worker slots, file count, test count, or the fact that a step is mechanical. The point is faster or safer completion of the user's task after coordination cost, not maximum worker utilization.

## Harness Compatibility

| Harness | Support |
|---|---|
| Claude Code / Codex with a subagent primitive | Modes 1 and 2 when the admission gate passes |
| Cursor / Gemini / Copilot without a subagent primitive | Execute inline; contract discipline may still be reused |

If delegation is unavailable, continue inline when the task itself remains possible. An optional optimization being unavailable is not a blocker and does not warrant stopping the user. Surface the issue only when the requested outcome itself cannot proceed.

## Mode 1: Optional Auxiliary Delegation

### Delegation Admission Gate

Spawn only when **all** answers are yes:

1. **Independent workstream** — it has a clear input/output contract and can finish without decisions from the main agent or another worker.
2. **Result-only consumption** — the main agent needs a compact result, not the traversal as substrate for root-cause analysis, design, or user explanation.
3. **Real overlap** — the main agent can name useful, non-overlapping work it will continue immediately while the worker runs.
4. **Positive Net Benefit** — expected time/context saved exceeds startup, prompt/context handoff, coordination, review, merge, and likely rework cost.
5. **Bounded fan-out** — worker count must not exceed the number of independent workstreams. A file, test class, command, or available concurrency slot is not automatically a workstream.

If any answer is no or unknown, do the step inline. “Can be delegated” is not “should be delegated.”

### Small Actions Stay Inline

Do not delegate these merely for context isolation or because they are mechanical:

- reading one file or a narrow anchored excerpt
- an ordinary `rg` / symbol lookup whose hits the main agent must inspect
- one command or one narrow validation check
- a single-file edit or a short same-context patch
- one targeted test whose result is the next required decision
- a follow-up check that depends on the immediately preceding result

A long test/build or wide read may qualify only if every Admission Gate item passes. Prefer bounded command output and minimal sufficient reads before adding a worker.

### Main-Thread Non-Blocking Rule

Before spawning, write down the exact main-thread work that will run concurrently. Then continue it immediately.

- **Do not spawn a worker if the next main-thread action would be waiting.** Inline is cheaper.
- Do not wait while any useful independent main-thread work remains.
- Only when **all remaining critical paths** depend on already-running workers may the main agent perform one bounded, event-driven wait for the next result.
- Do not repeatedly poll or enter a blocking wait loop. After a result or timeout, integrate new evidence, reassess the plan, and either continue useful work or report progress.
- Do not start extra workers to manufacture something to wait for.

Batch dispatch is useful only for genuinely independent workstreams. Dispatch them together, then keep the main agent on integration, constraints, review preparation, or another non-overlapping workstream.

### Count and Scope Discipline

- Start with the fewest workers that produce real overlap; add another only when its incremental Net Benefit is positive.
- Never split one acceptance contract by file, test class, log slice, or command solely to fill concurrency slots.
- Tests for one behavior remain one verification workstream unless they can be specified, executed, and reviewed independently.
- Workers do not spawn their own workers. Flatten only the workstreams that already exist in the task.
- User-requested core implementation stays with the main agent unless the user explicitly delegates ownership differently.

### Job vs Auxiliary

| Scenario | Main agent needs | Verdict |
|---|---|---|
| Read 3 files to locate and explain an NPE | traversal and reasoning | inline |
| Run one targeted test, then decide the next patch | immediate result on the critical path | inline |
| Inventory many callsites while main agent designs the migration contract | compact list; real concurrent design work exists | may delegate |
| Run a long independent regression while main agent reviews the diff | final result; real concurrent review exists | may delegate |
| Run a build and then do nothing until it ends | result only, but no overlap | inline |

### Decision Flow

```text
next sub-step
    ↓
main-agent judgment / user discussion / critical-path result? ── yes → inline
    │ no
    ↓
all five Admission Gate checks pass? ── no or unknown → inline
    │ yes
    ↓
spawn the minimum workers → continue named main-thread work immediately
    ↓
all remaining critical paths now depend on workers? ── no → keep working
    │ yes
    ↓
one bounded/event-driven wait → integrate result; never poll-loop
```

### Never Delegate

- architecture, schema, security, destructive-operation, or permission decisions
- root-cause conclusions and tradeoffs that the main agent must defend to the user
- requirement clarification or user communication
- tightly coupled edits whose contracts overlap
- work where reviewing the worker costs about as much as doing it inline

### Common Failure Modes

- **Mechanical means delegate** — ignores coordination cost and creates workers for ordinary grep, edits, commands, and tests.
- **Spawn then wait** — proves the Real Overlap gate was false; the worker should not have been started.
- **Fan out by file/test class** — counts artifacts instead of independent workstreams.
- **Fill all slots** — treats concurrency capacity as demand.
- **Repeated wait polling** — blocks the main agent without producing new evidence.
- **Delegate core judgment** — returns an answer the main agent must re-derive before it can trust or explain it.

## Mode 2: Planned Orchestration

Use Mode 2 only when all are true:

- the task contains **at least 3 independent workstreams** with non-overlapping ownership
- each workstream has a mechanically reviewable contract
- concurrent execution has positive Net Benefit after coordination and integration cost
- the main agent owns synthesis, cross-workstream decisions, and final verification

A multi-hour task, a large file set, or an explore + implement + review sequence does not qualify by itself. If the task is mostly serial or shares one decision chain, stay inline.

The Plan → Dispatch → Two-Stage Review → Merge/Reject procedure lives in [`subagent-orchestration.md`](subagent-orchestration.md). A [`plan-feature.md` § Task Breakdown](plan-feature.md) may map to contracts, but only the truly independent tasks are dispatched; the plan's task count is not the worker count.

## Interception Transparency

Distinguish an optional dispatch optimization from an actual task blocker:

- **Optional dispatch unavailable/denied, task still possible inline** → continue inline; do not pause merely to satisfy a delegation rule.
- **Requested outcome cannot proceed because a required tool, permission, file, or network path is blocked** → stop, report the concrete blocker and available choices.

Never hide an actual blocker. Never manufacture one from an unavailable optional worker.

## Rationalizations to Reject

| Rationalization | Rebuttal |
|---|---|
| “The step is mechanical, so it belongs to a worker.” | Mechanical work still needs positive Net Benefit and real overlap. |
| “There are three files/tests, so I need three workers.” | Artifacts are not independent workstreams. Keep one contract or work inline. |
| “Context isolation is always worth a foreground worker.” | Not when the main agent then idles; use bounded reads/output or stay inline. |
| “The worker is already running, so I should wait now.” | Continue any independent work first. Wait only when every remaining critical path depends on it. |
| “Slots are available, so parallelize.” | Capacity is not demand; each worker must earn its coordination cost. |
| “The worker almost got it right; always re-dispatch.” | Re-run the Net Benefit gate. A small reviewed correction may now be cheaper inline. |
| “Sequential dispatch is safer.” | If workstreams are independent and admitted, dispatch together; if they are dependent, keep the dependency chain inline. |

## Red Flags — Stop and Reassess

- the main agent cannot name what it will do while a new worker runs
- worker count exceeds independent workstream count
- two workers need the same writable file or decision
- a single test/grep/edit was split out solely to keep context clean
- the main agent is about to call wait while useful work remains
- wait has already returned no new result and another blocking poll is being considered
- reviewing a worker requires re-reading essentially all of its work
- a worker asks for missing core context or a user decision
