# Reference

Look up what you need, not everything. Reference topics live under [`references/`](references/) split by subject.

## By task

- **Deciding SBA product direction or whether to absorb a major capability** → read [`docs/sba-bible.md`](docs/sba-bible.md), then use [`templates/skill/workflows/plan-feature.md`](templates/skill/workflows/plan-feature.md); the Bible defines desired direction, while code/tests define current reality
- **Laying out a new skill** → [`references/layout.md`](references/layout.md)
- **Deciding when to grow / shrink / split a skill** → [`references/progressive-rigor.md`](references/progressive-rigor.md)
- **Capturing stable macro business meaning without a heavy product-doc taxonomy** → [`references/business-global-model.md`](references/business-global-model.md)
- **Combining a task workflow with routed domain context, validating cross-owner reads, or retiring legacy knowledge** → [`references/business-global-model.md`](references/business-global-model.md#orthogonal-task-and-domain-routing)
- **Diagnosing instability — is it prompt, context, or harness?** → [`references/layout.md § Positioning in the Agent Stack`](references/layout.md#positioning-in-the-agent-stack)
- **Writing or debugging thin shells** → [`references/thin-shells.md`](references/thin-shells.md) (common body, hooks, hygiene); [`references/per-tool-shells.md`](references/per-tool-shells.md) (per-tool templates + compatibility matrix)
- **Updating downstream task routing** → edit `skills/<name>/routing.yaml`, then `bash skills/<name>/scripts/sync-routing.sh <name> --check`
- **Updating this repo's self-hosting shells** → for route changes edit [`references/self-hosting-routing.yaml`](references/self-hosting-routing.yaml); for shell content (Auto-Triggers, Red Flags, per-harness opening) edit [`references/self-hosting-shell-base.md`](references/self-hosting-shell-base.md) and/or [`references/self-hosting-shells.yaml`](references/self-hosting-shells.yaml). Then `bash scripts/sync-self-shells.sh` + `bash scripts/check-self-shells.sh`. Never hand-edit `AGENTS.md` / `CLAUDE.md` / `CODEX.md` / `GEMINI.md` / `.cursor/rules/workflow.mdc` directly — they are generated.
- **Task Anchor / Native Plan, Task Closure, recording lessons, or activation verification** → [`references/protocols.md`](references/protocols.md)
- **Closing a plan — where its conclusions go** → [`templates/skill/workflows/plan-feature.md`](templates/skill/workflows/plan-feature.md) § Complex Steps step 8 + [`docs/plans/README.md`](docs/plans/README.md) "When a plan closes". Load-bearing conclusions go into `rules/` (must / must not), `references/gotchas.md` or SKILL.md § Common Pitfalls (anti-patterns); the plan itself archives in [`docs/plans/`](docs/plans/) as audit trail. A separate `references/decisions/` directory was tried and removed — it became a silo no routing pulled from
- **Operating a multi-skill repo (routing, fission signals, coexistence rules)** → [`references/multi-skill-routing.md`](references/multi-skill-routing.md)
- **Composing other skills from your workflows** → [`references/skill-composition.md`](references/skill-composition.md)
- **Picking rule file sets, anti-patterns, file size budgets, troubleshooting** → [`references/conventions.md`](references/conventions.md)

## By topic

| File | Covers |
|---|---|
| [layout.md](references/layout.md) | Recommended directory layout, `SKILL.md` template, description-as-trigger discipline, positioning in the agent stack, relation to the official Anthropic skill spec |
| [progressive-rigor.md](references/progressive-rigor.md) | Three structural tiers (Single-file / Folder-light / Full), upgrade triggers, three-axis profile (structure / execution / topology), Simple vs Advanced route schema |
| [business-global-model.md](references/business-global-model.md) | Optional project-specific macro business layer: admission, modeling/calibration, current-baseline semantics, Plan/Fix Bug consumption, progressive split, and route activation |
| [thin-shells.md](references/thin-shells.md) | Cursor registration entry, common thin-shell body, Auto-Triggers, XML-Tag Injection, SessionStart hook, Context Hygiene Playbook |
| [per-tool-shells.md](references/per-tool-shells.md) | Per-tool shell templates (AGENTS / CLAUDE / CODEX / GEMINI / Cursor / Windsurf / Claude native) + tool compatibility matrix |
| [protocols.md](references/protocols.md) | Task Execution Protocol (Task Anchor + Native Plan), Task Closure, recording threshold, destination/generalization rules, and activation verification |
| [multi-skill-routing.md](references/multi-skill-routing.md) | Multi-skill repo operating guide: routing, description discipline, shared resources, cross-skill refs, fission signals, coexistence rules |
| [skill-composition.md](references/skill-composition.md) | Composing other skills from your workflows (embedded / serial chain / subagent delegation) |
| [executable-skill-architecture.md](references/executable-skill-architecture.md) | Optional advanced shape for API/CLI/platform-operation skills with scripts, tools, capabilities, workflows, and local config |
| [scenario-testing.md](references/scenario-testing.md) | Unit/contract/golden/scenario testing layers for skill behavior, especially executable or high-risk routes |
| [conventions.md](references/conventions.md) | Common rule file sets by project type, decision guide, what to preserve vs remove, anti-patterns, troubleshooting, file size guidelines, naming conventions, optional CI validation |
| [self-hosting-routing.yaml](references/self-hosting-routing.yaml) | Canonical YAML route manifest for this repo's root thin-shell bootstraps, plus sync/check protocol |
| [self-hosting-shell-base.md](references/self-hosting-shell-base.md) | Common body (Auto-Triggers + Red Flags) injected into every generated root shell |
| [self-hosting-shells.yaml](references/self-hosting-shells.yaml) | Per-harness frontmatter / title / opening / optional appended section for AGENTS / CLAUDE / CODEX / GEMINI / Cursor workflow.mdc |
| [self-hosting-conformance.yaml](references/self-hosting-conformance.yaml) | Content-presence guard for this repo's own canon — asserts canonical files still teach the protocols `templates/skill/conformance.yaml` promises downstream |

New references should link to the topic file directly (e.g. `references/per-tool-shells.md#tool-compatibility-summary`), not through this stub.
