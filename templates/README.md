# templates/ — Pre-Built Copy-Pasteable Content

This directory holds **ready-to-copy files** for downstream projects. WORKFLOW.md Quick Start copies this tree into the target project and runs a single `sed` pass to substitute placeholders. The goal: eliminate the "Agent generated the file inline and dropped half the sections" failure mode.

`SKILL.md` sources intentionally use the `.template` suffix. Codex-style skill loaders may recursively scan installed skills for `SKILL.md`; leaving raw template files with placeholder frontmatter under `templates/` makes them look like broken real skills. Quick Start renames `SKILL.md.template` to `SKILL.md` after copying into the downstream project.

## Layout

```
templates/
├── skill/                    → becomes skills/{{NAME}}/
│   ├── SKILL.md.template     (renamed to SKILL.md during Quick Start)
│   ├── routing.yaml            (single source for Always Read + Common Tasks + shell bootstraps)
│   ├── sync-manifest.yaml      (vendor-class file list consumed by scripts/sync-vendor.sh)
│   ├── rules/{project-rules,coding-standards,agent-behavior}.md
│   ├── workflows/{task-execution,plan,fix,change,review,refactor,rule/template maintenance,subagent modes,task-closure}.md
│   ├── workflows/invoke-skill.md.example  (copy-paste template for Pattern A composition; rename and adapt)
│   ├── workflows/profile-business-model.md.example  (opt-in product/business model workflow; rename only after real pressure)
│   ├── references/{agent-behavior-meta,behavior-failures,gotchas,subagent-verification}.md
│   ├── protocol-blocks/       → internal Task Closure / routing reinforcement blocks
│   └── scripts/              → automated verification (lives inside the skill)
│       ├── smoke-test.sh                (fully automated structural + routing checks)
│       ├── sync-routing.sh              (generate/check routing summary + shell bootstraps from routing.yaml)
│       ├── sync-vendor.sh               (mechanical vendor-file sync from an upstream clone; base = synced_sha)
│       ├── upstream-status.sh           (am-I-behind reporter + wrong-checkout guard; reads .upstream-sync)
│       ├── route-health.sh              (static routing-quality lint; advisory)
│       ├── audit-orphans.sh             (content-tier files with zero inbound links)
│       ├── route-reachability.sh        (task-route activation, including workflows)
│       └── check-version-conformance.sh (downstream contract: required/forbidden phrases + files)
├── shells/                   → becomes repo-root entry files
│   ├── AGENTS.md / CLAUDE.md / CODEX.md / GEMINI.md
│   ├── .cursor/rules/workflow.mdc
│   └── .cursor/skills/{{NAME}}/SKILL.md.template
├── hooks/                    → optional SessionStart injection + mechanism-level gates
│   ├── session-start              (bash, per-harness JSON branching — re-inject one router)
│   ├── workflow-state             (bash, UserPromptSubmit — inject one active workflow hint)
│   ├── agent-behavior-gate.sh     (bash, PreToolUse — enforce Admission Threshold deterministically)
│   ├── hooks.json                 (Claude Code settings fragment — SessionStart + UserPromptSubmit + PreToolUse)
│   ├── hooks-cursor.json          (Cursor config — same as above, per-harness wiring)
│   ├── README.md                  (rollout / tuning / false-positive mitigations, per-hook)
│   └── SECURITY.md                (trust boundary: what may vs must not be written to hook-read files)
```

## Placeholders

Two kinds — each with a different "fill" mechanism:

| Marker | Meaning | Filled by |
|---|---|---|
| `{{NAME}}`, `{{SUMMARY}}` | Mechanical substitution | Single `sed` pass in Quick Start |
| `<!-- FILL: … -->` | Requires agent judgment before the skill ships | `grep -r 'FILL:'` lists pending migration work |
| `<!-- OPTIONAL: … -->` | Advanced or organically-grown content | Leave empty unless the project has real evidence or user asks |

**Audit after Quick Start:** run `grep -r 'FILL:' skills/{{NAME}} AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor` — every match is required agent work before shipping. Users should not need to interpret these markers.

## Size Review Budgets

Line counts trigger review, not automatic splitting. The SKILL dual budget and structural checks are machine-enforced where stated; other rows require the independent-load-reason judgment in `workflows/maintain-docs.md`.

| Path | Budget | Enforcement |
|---|---|---|
| `shells/*` | ≤ 60 lines | Thin shells must stay thin; > 60 = content leaking in. Must include generated Always Read + `routing.yaml` bootstrap + route-before-routing check for vague verbs (see `protocol-blocks/ambiguous-request-gate.md`) |
| `skill/routing.yaml` | ≤ 120 lines | Single source of truth for generated Always Read, Common Tasks, trigger examples, required reads, workflows, and thin-shell bootstraps; project-specific after fill |
| `skill/rules/project-rules.md`, `skill/rules/coding-standards.md` | ≤ 20 lines, ≥ 60% must be `<!-- FILL: -->` | Rule stubs are scaffolding, not content |
| `skill/rules/agent-behavior.md` | ≤ 100 lines, fully pre-filled | Universal defaults; additions require evidence or equal-weight replacement per `ANTI-TEMPLATES.md` |
| `hooks/session-start`, `hooks/workflow-state`, `hooks/agent-behavior-gate.sh` | ≤ 150 lines each | Optional hook scripts. Keep per-harness branching in-script; see `hooks/README.md` |
| `hooks/README.md` | ≤ 150 lines | Per-hook rollout guidance; allowed larger because it documents optional installs + tuning |
| `skill/workflows/task-execution.md`, `profile-project.md`, `plan-feature.md`, `plan-large.md`, `update-upstream.md`, `fix-bug.md`, `change-managed.md`, `edit-templates.md`, `subagent-auxiliary.md`, `subagent-driven.md`, `subagent-orchestration.md` | ≤ 100 lines | Cross-cutting execution plus task-specific/conditionally selected workflows stay lean |
| `skill/workflows/profile-business-model.md.example` | ≤ 100 lines | Optional business-model workflow; stays inactive until a downstream renames it and adds a real route |
| `skill/workflows/update-rules.md`, `maintain-docs.md` | ≤ 250 lines | Protocol-heavy workflows allowed more room |
| `skill/protocol-blocks/*` | ≤ 40 lines each | One idea per block |
| `skill/SKILL.md.template` | dual budget: description ≤ 25 lines + body ≤ 90 lines | Same hard cap as downstream SKILL.md (smoke-test enforces both separately). description carries quoted trigger phrases; body navigates rules/workflows/references. Keep each shorter when possible. |
| `skill/scripts/smoke-test.sh` | ≤ 980 lines | Structural test harness; optional overlay line accounting is isolated from the task core; the next substantial concern should replace/simplify existing checks |
| `skill/scripts/sync-routing.sh` | ≤ 520 lines | Dependency-free generator/checker; optional overlay parsing and generic cross-owner path validation stay internal so default projects gain no extra files or setup |
| `skill/scripts/sync-vendor.sh` | ≤ 160 lines | Mechanical vendor sync; base check via upstream git history — no new state files |
| `skill/sync-manifest.yaml` | ≤ 40 lines | Vendor-class file list only; project-owned/generated/runtime-data paths never belong here |
| `skill/scripts/audit-orphans.sh`, `route-reachability.sh` | ≤ 120 lines each | Recursive zero-inbound and task-activation checks, including nested `references/business/`; heuristic, run before deleting flagged files |
| `skill/references/gotchas.md` | ≤ 25 lines (seed) | MUST stay near-empty — content grows post-deployment |
| `skill/references/behavior-failures.md` | ≤ 25 lines (seed) | MUST stay near-empty — agent-behavior violations logged via AAR |

Anything over budget needs either splitting or rejection. See `ANTI-TEMPLATES.md`.

## Growth Health

Review these signals during major template or skill updates. A threshold does
not force an automatic refactor; it forces an explicit decision.

| Signal | Review when | Default action |
|---|---:|---|
| `SKILL.md` description lines | > 25 | Split intent clusters or shorten activate-when clause |
| `SKILL.md` body lines | > 90 | Move detail to routed files or downgrade scope |
| Always Read files | > 3 | Demote domain-specific files to task routes |
| Concrete routes | > 10 | Group routes, merge low-frequency tasks, or evaluate multi-skill split |
| `references/` orphans | > 0 | Add an activation path or delete the reference |
| Workflow line count | > budget row above | Split only if sections are independently navigable |
| Check script line count | > budget row above | Extract checks or reject new mechanism weight |
| High-risk route scenarios | 0 covered | Add contract/scenario tests before trusting behavior |

Executable-skill pressure is a separate signal: if project evidence shows
external APIs/CLIs, remote side effects, repeated script logic, local config, or
stable output contracts, read `references/executable-skill-architecture.md`
before expanding the base template.

## The "Would Two Real Projects Disagree?" Test

Before adding anything to this directory, answer:

> "A Go backend microservice and a React animation site both pull this template. Would they both agree on this content?"

- **Yes** → it's structural protocol; may go in `templates/`.
- **No / probably not** → it's project-specific; move to `<!-- FILL: -->` comment or `examples/` instead.

No exceptions. If this test is hand-waved, `templates/` slides into opinionated defaults and downstream projects start looking identical.

New reusable mechanisms must also pass the [Mechanism Admission Gate](ANTI-TEMPLATES.md#mechanism-admission-gate): reduce repeated maintenance or prevent a verified recurring failure; otherwise keep them out of `templates/` as mechanisms.

## Anti-Drift Checks

Run these when templates change:

1. **Placeholder audit** — `grep -r '{{' templates/` lists every placeholder; it must match the Quick Start substitution set.
2. **Loader-safety audit** — `find templates -name 'SKILL.md'` returns no rows; template sources stay `SKILL.md.template` until materialized.
3. **FILL audit** — `grep -r 'FILL:' templates/` returns only required migration-work markers.
4. **Routing audit** — run `sync-routing.sh --check`, then repeat it on a minimally filled sample.
5. **Integrity audit** — run `audit-orphans.sh` for link reachability and `route-reachability.sh` for real task activation; two-root skills pass the namespace/routing arguments documented by those scripts.
6. **Homogeneity spot-check** — compare two unlike toy projects; skeleton may match, project rules/routes must not.
7. **Upstream check suite** — run `bash scripts/check-all.sh`; it instantiates a temporary downstream and enforces the upstream change-note contract.
