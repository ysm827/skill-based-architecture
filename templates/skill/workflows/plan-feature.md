# Plan Feature Workflow

Use this for planning requests. Only complex plans get a `docs/plans/.../` folder; simple plans stay inline in the conversation unless the user explicitly asks for a file.

## Complexity Gate

| Size | Signal | Action |
|---|---|---|
| Trivial | typo, comment, obvious one-line change | skip this workflow |
| Simple | clear goal, 1-2 files, no product ambiguity | ask at most one confirmation question; no folder |
| Complex | multiple files, unclear behavior, external dependency, architecture choice, or long run | create a dossier folder and continue below |

## Question Gate

Before asking any question, pass all three gates:
1. **Gate A: Derivable?** If code, docs, configs, tests, issue text, or quick primary-source research can answer it, inspect first. Do not ask.
2. **Gate B: Meta / lazy?** Never ask "should I search?", "can you paste the code?", or "what does this repo look like?" when the repo or source is available. Take the action.
3. **Gate C: Blocking / Preference / Derivable?** Ask only `Blocking` or `Preference` questions. Resolve `Derivable` questions yourself and record evidence.

Ask one question at a time. Prefer 2-3 concrete options with trade-offs for preference questions.

## Simple Plan

For Simple tasks, do not create `docs/plans/` and do not write `.skill-workflow-state`. Produce a short inline plan with scope, steps, and validation. If one confirmation is needed, ask it before writing the plan.

## Complex Task Dossier

For Complex tasks, create one directory:

```text
docs/plans/YYYY-MM-DD-<slug>/
├── prd.md
├── decisions.md
├── checklist.md
├── research/
├── evidence/
├── implement.jsonl
└── check.jsonl
```

Keep `prd.md` short: goal, scope, requirements, acceptance criteria, out of scope, and current open questions. Put supporting material elsewhere:

- `decisions.md` — ADR-lite entries with `Context`, `Decision`, and `Consequences`.
- `research/` — summarized research findings.
- `evidence/` — copied source/doc snippets with file path and line references.
- `implement.jsonl` — files the implementer must read first.
- `check.jsonl` — files the checker/reviewer must read first.

JSONL row shape: `{"file":"docs/plans/YYYY-MM-DD-<slug>/prd.md","reason":"Accepted scope"}`.

## Complex State File

For Complex tasks only, write `.skill-workflow-state` if the optional workflow-state hook is installed:

```text
workflow=skills/{{NAME}}/workflows/plan-feature.md
status=planning
task=docs/plans/YYYY-MM-DD-<slug>
```

Update `status` as the task moves. Delete the file when the plan is complete or the workflow is abandoned.

## Complex Steps

1. **Scan existing rules / gotchas / pitfalls first** — before drafting `prd.md`, glance through `rules/`, `references/gotchas.md` (or any `references/*pitfall*.md`), and SKILL.md § Common Pitfalls for entries that look related to your scope. Read the relevant ones. These are the active constraints; proposing something the existing canon already rejected wastes the plan. Skip if these locations are empty.
2. **Create / update dossier** — create the directory and seed `prd.md`, `decisions.md`, `checklist.md`, `research/`, `evidence/`, `implement.jsonl`, and `check.jsonl`.
3. **Inspect first** — gather repo evidence before questioning: similar features, entry points, config, scripts, tests, and current docs.
4. **Question gate** — classify each possible question through Gate A/B/C; ask only the highest-value next question.
5. **Define scope** — write requirements, acceptance criteria, and out-of-scope items in `prd.md`.
6. **Record decisions** — when choosing between approaches, append ADR-lite entries to `decisions.md`. **`decisions.md` is intra-plan and mutable** — local working notes that freeze with the plan archive on close. Load-bearing entries get lifted into the live structure at step 8; entries that don't make that cut stay here.
7. **Prepare execution context** — fill `implement.jsonl` and `check.jsonl` with only relevant rule, workflow, research, evidence, and PRD files.
8. **On closure: lift load-bearing content into the live structure** — when `status` flips to `done`, sort every conclusion in `decisions.md` (or the simple plan's body) into one of three buckets:

   - **"Future work must / must not do X"** (a constraint that binds tasks beyond this plan) → add to a `rules/<topic>.md` file. Routing pulls `rules/` onto every relevant task path, so the constraint is read automatically.
   - **"We tried Y; here is why Y is wrong"** (anti-pattern, footgun, rejected alternative worth remembering) → add an entry to `references/gotchas.md` (or `references/*pitfall*.md`), or — if the lesson is high-value enough to surface early — promote it to SKILL.md § Common Pitfalls. Use the "alternatives rejected" framing while the context is still fresh; six months from now you cannot reconstruct it.
   - **Neither** — pure provenance ("what happened, why we did it then") with no future binding → leave it in the plan archive and omit `distilled_to:`. Note the judgment in the plan body so future readers can see you actively chose not to lift anything.

   Then set the plan's `distilled_to:` frontmatter to list the live-structure files that received content. If the conclusion fits two buckets (e.g. both a rule and a pitfall), it goes in both — different audiences, not duplicates. **There is no fourth bucket** called `references/decisions/`; that was tried and removed (silo problem — see [docs/plans/README.md](../../../docs/plans/README.md) "When a plan closes").

9. **Final readback** — summarize requirements, acceptance criteria, chosen approach, out-of-scope items, and dossier path.

## Workflow-State Blocks

[workflow-state:planning]
You are planning a complex task. Keep `prd.md` short, inspect code/docs before asking, and run Question Gate A/B/C before every user question.
[/workflow-state:planning]

[workflow-state:research]
External or cross-repo research is active. Put summaries in `research/`, put quoted source/doc snippets with file:line references in `evidence/`, and avoid unsupported paraphrase.
[/workflow-state:research]

[workflow-state:converging]
Requirements are being locked. Move answered questions into `prd.md`, record trade-offs in `decisions.md`, and keep out-of-scope explicit.
[/workflow-state:converging]

[workflow-state:implementation-ready]
Planning is complete. Verify `implement.jsonl` and `check.jsonl` point at the PRD, rules, decisions, and any research/evidence needed before implementation starts.
[/workflow-state:implementation-ready]

## Completion Checklist

- [ ] Trivial/simple tasks were not forced into a dossier
- [ ] Simple plans stayed inline unless the user explicitly asked for a file
- [ ] Every asked question passed Gate A/B/C
- [ ] `prd.md` contains testable acceptance criteria
- [ ] `decisions.md` records approach trade-offs when choices mattered
- [ ] Research and evidence are not mixed into `prd.md`
- [ ] `implement.jsonl` and `check.jsonl` contain only relevant files
- [ ] `.skill-workflow-state` was removed or left with the correct active state
- [ ] If the plan landed (`status: done`): step 8 was actually performed — every `decisions.md` entry was sorted into `rules/` / `references/gotchas.md` / SKILL.md Pitfalls / "no, pure provenance"; `distilled_to:` frontmatter reflects what was lifted
