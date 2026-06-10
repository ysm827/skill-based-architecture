# Fix Bug Workflow

> **Pervasive reverse-question — default habit**: Before each sub-step, ask "Is watching the whole process redundant for the main agent?" If yes (mechanical + time-consuming + only-need-result) → **directly** `spawn_agent` (global authorization assumed), main conversation only sees the result. See [`subagent-driven.md` § Mode 1: Direct Auxiliary Delegation](subagent-driven.md#mode-1-direct-auxiliary-delegation). **Not limited to specific list**, any sub-step may trigger (running tests / wide grep / batch edit / scanning logs…).

## Mandatory Pre-Step (cannot skip)

**Re-run `SKILL.md` § Session Discipline before starting.** Re-match this bug against Common Tasks; re-read the route's files only if the route changed or context was compacted (see § Session Discipline).

## Read First

1. Re-open `SKILL.md` → match this bug to a Common Tasks route
2. Read **all** files listed for that route (not just the ones you remember)
3. Read task-relevant `references/*.md` (especially `references/gotchas.md`)

## Steps

1. Restate the bug scope and affected behavior
2. Read the minimum necessary files — do not read files unrelated to the symptom
3. Identify the root cause — not the first plausible cause, the actual one. **If 2+ plausible hypotheses survive a 30-second think**, see § Hypothesis Fan-out below before reading more code.
4. Implement the smallest correct fix — no "while we're here" cleanups
5. Run Fix Impact Analysis — confirm the change did not silently break callers, data flow, or compatibility
6. Validate behavior (tests pass, manual reproduction no longer triggers the bug). **Before running tests / build,** ask the reverse-question "主 agent 看这一步的全过程是多余的吗?" — if yes, see [`subagent-driven.md` § Mode 1: Direct Auxiliary Delegation](subagent-driven.md#mode-1-direct-auxiliary-delegation) signals #1 / #2 to optionally dispatch a verify / build subagent (Codex falls back to display isolation).
7. **Run Task Closure Protocol** from `workflows/task-closure.md` — mandatory, not optional
8. If the recording threshold passes, update the appropriate `rules/`, `references/`, or `workflows/` file before ending the task
9. Records must pass the generalization check — write as reusable knowledge, not project-specific narratives
10. If the lesson is costly and task-relevant, also activate it in workflow/routing, not only store in `references/`

## Hypothesis Fan-out (optional, for ambiguous bugs)

When the first read leaves 2+ plausible root causes still alive, serial elimination is the wrong strategy — by the time hypothesis #4 hits, the main context is polluted with three rabbit holes.

**Trigger** — fan out only when **all** of:

- ≥ 2 hypotheses are concrete enough to be a single-sentence claim
- Each one can be **independently verified** by reading a different region of the codebase / a different log slice / a different external check
- Inspecting them all in one context would consume > 30% of remaining budget

If any condition fails, just inline the most likely one. Fan-out has dispatch overhead.

**How to fan out** — for each hypothesis, dispatch one subagent (per `workflows/subagent-orchestration.md` Phase 1 contract format):

- **Goal**: confirm or refute the claim "*<single-sentence hypothesis>*"
- **Inputs**: the specific files / logs / endpoints that would prove or disprove it (do not pass the bug description as a whole — pass only the slice that matters for this hypothesis)
- **Outputs**: a short verdict — "confirmed (evidence: …)" / "refuted (evidence: …)" / "inconclusive (need: …)"
- **Forbidden Zones**: any file edit; this is read-only investigation
- **Acceptance Criteria**: the verdict cites at least one specific file:line or log line as evidence

Dispatch in parallel. The main agent reads only the verdicts (not the supporting code traversal each subagent did) and chooses which hypothesis to act on at Step 4.

**Degraded harness (Cursor / Codex / Gemini)**: skip the literal dispatch, but still write down the list of hypotheses + the verification region for each before reading code. The discipline of "decide what would refute each, before reading" survives even without subagents.

## Fix Impact Analysis

Before final validation, inspect the actual diff and answer:

1. **Direct impact** — Which callers use the changed function/method/component? Did any parameter signature, return type, response shape, or error behavior change?
2. **Indirect impact** — Does the fix alter upstream/downstream data flow, shared state, global config, cache behavior, event timing, listeners, callbacks, or async ordering?
3. **Data compatibility** — If fields were added, removed, renamed, or changed type, do old data, persisted data, API consumers, and fallback/default paths still work?
4. **Blast-radius validation** — Which targeted tests, compile checks, type checks, or manual smoke paths cover the affected callers and compatibility assumptions?

If any answer is unknown, inspect the relevant callers or data contracts before declaring the fix safe.

## Completion Checklist

- [ ] Root cause identified (not just a plausible-looking fix)
- [ ] Fix Impact Analysis completed against the actual diff
- [ ] Direct callers and changed signatures/return shapes checked
- [ ] Indirect data flow, shared state, events, callbacks, and async timing considered
- [ ] Data compatibility checked for added/removed/renamed/type-changed fields
- [ ] Code fix verified (tests pass, manual repro clean)
- [ ] Task Closure Protocol was run (AAR scan completed before declaring task done)
- [ ] Recording threshold checked
- [ ] If threshold passed, record passes generalization check and docs updated
- [ ] If the lesson was costly and task-relevant, it was activated in workflow/routing, not only stored in `references/`

<!-- FILL: add project-specific validation steps here — e.g. specific test suites to run, linters, smoke tests. -->
