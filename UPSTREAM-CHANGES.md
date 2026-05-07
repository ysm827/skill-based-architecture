# Upstream Changes

This file is a human- and agent-readable map for downstream refreshes.
When a downstream project asks to update from this upstream repo, read the
latest relevant entries first, then verify every candidate change against the
actual upstream/downstream file diff.

This is not a lockfile, upgrade manifest, changelog contract, or source of
truth. It is intentionally upstream-owned only. Downstream projects should not
copy, create, or maintain a local version of this file.

## How To Use

1. Clone the upstream repo named in `workflows/update-upstream.md`.
2. Read the newest entries below to identify likely files and intent.
3. Compare actual upstream and downstream files before editing.
4. Preserve downstream project-owned rules, gotchas, routing examples, and
   local workflows.
5. Patch useful upstream mechanism changes, then run the downstream validation
   commands from `workflows/update-upstream.md`.

## Entry Format

```text
## YYYY-MM-DD - short title

- Upstream commit: <hash> <subject>
- Changed areas: <files or directories>
- Why it matters: <intent>
- Downstream refresh guidance: <what to compare/port/preserve>
```

## 2026-05-07 - Guard upstream change notes

- Upstream commit: see `git log -- scripts/check-upstream-changes.sh` for the
  introducing commit; this entry documents the check added by that same change
- Changed areas: `scripts/check-upstream-changes.sh`, `UPSTREAM-CHANGES.md`,
  `WORKFLOW.md`, `README.md`, `README.zh-CN.md`, `skill.yaml`, and
  `templates/README.md`
- Why it matters: prevents downstream-facing upstream changes from landing
  without an update note for future downstream refresh agents.
- Downstream refresh guidance: do not copy this root script into downstream
  projects. It is an upstream maintenance guard; downstream agents only read
  the resulting `UPSTREAM-CHANGES.md` from a cloned upstream repo.

## 2026-05-07 - Upstream change notes for downstream refreshes

- Upstream commit: see `git log -- UPSTREAM-CHANGES.md` for the introducing
  commit; this entry documents the mechanism added by that same change
- Changed areas: `UPSTREAM-CHANGES.md`, `WORKFLOW.md`, `README.md`,
  `README.zh-CN.md`, `skill.yaml`, and
  `templates/skill/workflows/update-upstream.md`
- Why it matters: gives downstream refresh agents an upstream-owned update map
  to read before they inspect actual file diffs.
- Downstream refresh guidance: port the updated `update-upstream` workflow if a
  downstream project should read upstream notes first. Do not copy, create, or
  update `UPSTREAM-CHANGES.md` in downstream projects; read it from the cloned
  upstream repo during refresh.

## 2026-05-07 - README branding and planning workflow hooks

- Upstream commit: `12db598 Add README branding and planning workflow hooks`
- Changed areas: `README.md`, `README.zh-CN.md`, `WORKFLOW.md`,
  `references/thin-shells.md`, `templates/README.md`,
  `templates/checklists/post-migration.md`, `templates/hooks/*`,
  `templates/skill/SKILL.md.template`, `templates/skill/routing.yaml`,
  `templates/skill/workflows/plan-feature.md`, and
  `assets/skill-based-architecture-title.png`
- Why it matters: adds the README title asset and project badges, introduces
  the reusable `plan-feature` workflow/route, and adds the `workflow-state`
  hook so long-running work can surface the active workflow state.
- Downstream refresh guidance: compare hook files, routing, SKILL summary, and
  workflow scaffolding as mechanism-owned changes. Preserve downstream
  project-specific routes, examples, rules, gotchas, and workflow text unless
  the upstream change fixes a reusable mechanism.

## 2026-04-30 - Routing manifests and upstream refresh workflow

- Upstream commit: `9cc9e56 Add routing manifests and upstream refresh workflow`
- Changed areas: `templates/skill/routing.yaml`,
  `templates/skill/workflows/update-upstream.md`,
  `templates/skill/scripts/sync-routing.sh`,
  root/self-hosting routing references, and generated shell bootstraps
- Why it matters: makes `routing.yaml` the source of truth for generated Always
  Read lists, Common Tasks, trigger examples, required reads, workflows, and
  thin-shell bootstraps; introduces the agent-led upstream refresh workflow.
- Downstream refresh guidance: port the routing source-of-truth mechanism and
  `update-upstream` workflow when missing. Regenerate generated sections from
  local `routing.yaml`; do not hand-edit shell bootstraps or overwrite
  downstream task examples.
