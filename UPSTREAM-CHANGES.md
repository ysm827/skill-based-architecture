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

## Archive Policy

Downstream refresh agents almost always only read the most recent 3–5 entries. Old entries cost them context without changing decisions. When this file passes ~300 lines (or roughly 8 entries), move the oldest entries to `UPSTREAM-CHANGES-archive.md` and keep only the most recent 3–5 here.

The archive file has the same format and is read on demand if a downstream agent is investigating a specific historical change. `scripts/check-upstream-changes.sh` only enforces a same-diff entry in `UPSTREAM-CHANGES.md`; archived entries are out of its scope.

## 2026-05-11 - Tiered maintenance triggers (bash gate / AAR scan / full pass)

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/workflows/update-rules.md`,
  `templates/skill/workflows/maintain-docs.md`, `UPSTREAM-CHANGES.md`
- Why it matters: agent-led file cleanup costs tokens. Running the full
  reorganization scan on every commit, or every time anyone touches a
  gotchas file, would burn tokens without proportional benefit. The
  workflow now articulates a three-tier trigger discipline so the
  expensive scan runs only when cheap signals have already flagged
  something:
    - Tier 0 (bash, free, every commit): smoke-test `grep | uniq -d` on
      `gotchas.md` / `*pitfall*.md` `##` headings — catches verbatim
      copy-paste duplicates deterministically.
    - Tier 1 (agent, cheap, on every AAR closure that records a new
      entry): `update-rules.md § Search Before Record` upgraded to
      include a gotchas-specific scan recipe — list existing tags + ##
      headings via grep, then have the agent read 3–5 candidate entries
      and decide append / merge / skip. Cheap because the agent is
      already in context and only reads the candidate set, not the whole
      file.
    - Tier 2 (agent, expensive, threshold-triggered): full
      reorganization (dedup + categorize + split if needed). Only fires
      when entry count > 25, line count > 80% of cap, a recurring Tier-0
      dup signals drift, or the user explicitly asks. Expected cadence is
      "once or twice per file per year", not "every commit".
  `maintain-docs.md § Step 1b` was rewritten to make these triggers
  explicit (table + trigger list + token-cost intuition).
- Downstream refresh guidance: pull the updated `workflows/update-rules.md`
  and `workflows/maintain-docs.md` as mechanism-owned files. The Search
  Before Record block in `update-rules.md` now mandates the gotchas
  similarity scan at append time — agents already in AAR context should
  run the cheap grep recipe before appending to any pitfall file.

## 2026-05-11 - Gotchas dedup check + classification upgrade path

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/scripts/smoke-test.sh`,
  `templates/skill/references/gotchas.md`,
  `templates/skill/workflows/maintain-docs.md`,
  `UPSTREAM-CHANGES.md`
- Why it matters: real-data audit of a downstream chaos_web pitfall log
  surfaced two problems the existing architecture did not catch:
  1. **Copy-paste duplicate entries**. The file had 4 entries whose `##`
     heading text matched another entry verbatim — same pitfall recorded
     twice because the author had no quick way to see "did I write this
     already?". The previous gotchas check only enforced line count,
     not duplicates. `smoke-test.sh § 2a` now grep-dedups `## ` headings
     in `gotchas.md` / `*pitfall*.md` and fails when any heading appears
     more than once. Deterministic check, very low false-positive rate.
  2. **No classification upgrade path**. The template `gotchas.md` told
     authors how to write one entry but said nothing about how to keep
     50 entries scannable. By the time a real file hits 25+ entries
     with no organization, finding "is this already recorded?" is O(file)
     and duplicates appear (see point 1). The template comment now
     teaches a three-stage upgrade: stage 1 flat with `**[topic]**` tags
     (≤ 10 entries), stage 2 H2 categories with `###` entries (10–25),
     stage 3 split files (> 25 or > 400 lines). `maintain-docs.md
     Step 1b` was reordered to enforce the same pipeline: dedup →
     staleness → **categorize before splitting** → structural → tag →
     split as last resort. Result: existing files reorganize before
     splitting prematurely, and new files start with the right structural
     instinct.
- Downstream refresh guidance: pull the updated `scripts/smoke-test.sh`,
  `references/gotchas.md` (template-side; **do not overwrite a downstream
  copy that already has real entries**, just port the new comment block
  to it), and `workflows/maintain-docs.md` as mechanism-owned files.
  After the refresh, run `smoke-test.sh <name>` — if you have copy-paste
  duplicates in your gotchas/pitfall files, the new check will list them
  and you can dedup in one pass. If your gotchas file is > 10 entries,
  follow `maintain-docs.md § Step 1b` to categorize before any split.

## 2026-05-09 - SKILL.md dual budget + test-trigger per-source rates

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/scripts/smoke-test.sh`,
  `templates/skill/scripts/check-growth-health.sh`,
  `templates/skill/scripts/test-trigger.sh`,
  `templates/skill/workflows/maintain-docs.md`,
  `templates/skill/conformance.yaml`,
  `templates/README.md`, `references/progressive-rigor.md`,
  `references/conventions.md`, `SKILL.md`, `AGENTS.md`, `CLAUDE.md`,
  `CODEX.md`, `GEMINI.md`, `README.md`, `README.zh-CN.md`, `EXAMPLES.md`,
  `UPSTREAM-CHANGES.md`
- Why it matters: closes two diagnostic gaps surfaced when auditing real
  downstream skills.
  1. **SKILL.md dual budget.** A single 100-line cap forced description
     quality to cannibalize body clarity (or vice versa) — when a skill
     wrote a proper 15-line description with quoted trigger phrases, body
     budget shrank to 85 lines and forced cramped routing tables. The
     budget now splits into description ≤ 25 lines (activation gate) +
     body ≤ 90 lines (navigation hub), enforced separately by
     `smoke-test.sh` and reported separately by `check-growth-health.sh`.
     Total cap effectively rises from 100 to 115, but each half has its
     own discipline — description can't bloat past 25 by stuffing
     workflow keywords, body can't bloat past 90 by inlining rule content.
  2. **test-trigger.sh per-source rates.** The script now reports
     trigger rate broken down by source (description quoted phrases vs.
     routing.yaml trigger_examples vs. Common Tasks vs. body candidates),
     not just one combined number. A large description-vs-routing gap
     (≥ 30 points) flags that the description is missing whole task
     categories the routing.yaml introduces — the most common cause of
     low real-world activation rates. Real-data example: chaos showed
     overall 69% but split into description 100% / routing 50% — the
     gap pointed straight at six trigger categories (plan / model / docs
     / upstream / rule-maintenance / fallback) that lived in routing.yaml
     but never made it into the description.
- Downstream refresh guidance: pull the updated `scripts/smoke-test.sh`,
  `scripts/check-growth-health.sh`, `scripts/test-trigger.sh`, and
  `workflows/maintain-docs.md` as mechanism-owned files. After the
  refresh:
  - Re-run `smoke-test.sh <name>` — your SKILL.md may previously have been
    a single-budget pass; if description was already ≤ 25 lines, the
    dual budget will still pass.
  - Re-run `test-trigger.sh <name>` — the per-source rates surface
    coverage gaps that the single number used to hide. A description ≤
    20% trigger rate against routing.yaml entries is the smoking-gun
    signal for the chaos-shaped gap.

## 2026-05-09 - test-trigger.sh body-candidate scan

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/scripts/test-trigger.sh`,
  `UPSTREAM-CHANGES.md`
- Why it matters: when a skill keeps trigger phrases inside SKILL.md body
  (e.g. executable-style Tier-2 routes with `positive_signals:` lists)
  instead of in the frontmatter description / routing.yaml / Common Tasks,
  the previous `test-trigger.sh` couldn't extract anything and silently
  bailed with "No test prompts could be generated". Activation analysis
  effectively gave up. The script now:
  1. Always scans the body for quoted candidate trigger phrases, labeled
     with their nearest preceding heading.
  2. In static-analysis mode reports those candidates and flags the
     promotion gap (description has 0 phrases but body has N → promote).
  3. In live `claude -p` mode, when description / routing.yaml / Common
     Tasks together yield zero prompts, prints the body candidates as
     promotion advice instead of failing silently.
  4. Accepts `--include-body` to feed those body candidates into the
     trigger test as-if-promoted, measuring potential trigger rate after
     promotion (vs. current rate).
  Standard skill layouts (description + routing.yaml + Common Tasks) are
  unchanged — body extraction runs in addition, not instead.
- Downstream refresh guidance: pull the updated
  `skills/<name>/scripts/test-trigger.sh` as a mechanism-owned file. No
  workflow text changes; no breaking changes for existing skills.

## 2026-05-09 - Backward-compatible refresh guards

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/scripts/sync-routing.sh`,
  `templates/skill/workflows/update-upstream.md`, `UPSTREAM-CHANGES.md`
- Why it matters: closes two refresh gaps that affect downstream projects
  scaffolded before the recent template trims:
  1. `sync-routing.sh` was changed to stop generating `.codex/instructions.md`
     when the recent commits made `.codex/` optional. That left existing
     downstream copies with stale routing blocks that would never auto-update.
     The script now keeps `.codex/instructions.md` in its target list **only
     when the file already exists** — old downstream skills keep getting
     synced; new scaffolds don't introduce the file.
  2. `update-upstream.md` had no explicit step for "scan upstream for new
     mechanism files that don't exist locally". When upstream introduced
     `conformance.yaml`, `check-version-conformance.sh`, and
     `_parse_conformance.py`, downstream agents could miss them entirely
     unless they happened to compare directory listings. A new step 5 now
     requires that scan before the per-file compare loop, with whole-file
     copy permitted under the existing Hard Rule #4 for missing files.
- Downstream refresh guidance: pull the updated `sync-routing.sh` and
  `update-upstream.md` as mechanism-owned files. Re-run
  `update-upstream.md` step 5 against your skill — it will surface any
  upstream mechanism files you don't yet have (most projects will need
  to copy `conformance.yaml`, `check-version-conformance.sh`, and
  `_parse_conformance.py` if they haven't yet).

## 2026-05-09 - Bloat reduction across templates, references, examples, READMEs

- Upstream commit: pending in this working tree
- Changed areas: 33 files. Deletions:
  `templates/migration/` (entire dir — `migrate.sh`, `resume.sh`, README),
  `templates/checklists/post-migration.md`,
  `templates/protocol-blocks/iron-law-header.md`,
  `templates/shells/.codex/instructions.md`, `.codex/instructions.md` (root),
  `examples/{migration,project-types,self-evolution,README}.md`.
  Major slims: `WORKFLOW.md` (-160 lines, removed migration FSM),
  `README.md` + `README.zh-CN.md` (-296 lines combined),
  `references/layout.md` (-167 lines, split out three new files),
  `references/thin-shells.md` (-141 lines, per-tool moved out).
  New references: `references/{progressive-rigor,positioning,per-tool-shells}.md`.
  Major rewrite: `EXAMPLES.md` (now consolidated body, was a stub).
  Mechanism updates: `scripts/sync-self-routing.sh` and
  `templates/skill/scripts/sync-routing.sh` no longer generate
  `.codex/instructions.md`; `smoke-test.sh` makes `.codex/instructions.md`
  optional instead of required; `examples/README.md` route in
  `references/self-hosting-routing.yaml` repointed to `EXAMPLES.md` +
  `examples/behavior-failures.md`.
  Net: +476 / −2117 lines.
- Why it matters: removed mechanisms that solved problems that don't
  recur — the migration state machine for crashes that don't happen, the
  duplicate Codex shell for harnesses that all read `AGENTS.md`, four
  long examples files that no route ever activated, the reusable
  `iron-law-header` block that was referenced once. Split two oversized
  references (`layout.md`, `thin-shells.md`) so routing pulls only the
  relevant subsection. The architecture's own "small focused files"
  principle now applies to itself.
- Downstream refresh guidance: when running `update-upstream`, expect to
  delete several files in your downstream skill if you scaffolded from a
  prior upstream:
  - Delete `skills/$NAME/.codex/instructions.md` if your harness does not
    explicitly read it (most don't — `AGENTS.md` is canonical).
    `smoke-test.sh` no longer requires it.
  - If your downstream copied `templates/migration/`, `templates/checklists/`,
    or `templates/protocol-blocks/iron-law-header.md`, remove them — they
    are no longer maintained upstream.
  - Old long-form example files were consolidated into root `EXAMPLES.md`.
    `examples/behavior-failures.md` is the only example file kept.
  - For inbound links to former `references/layout.md` sections,
    repoint: `#progressive-rigor` → `progressive-rigor.md`,
    `#multi-skill-projects` → `multi-skill-routing.md` (Coexistence rules),
    Positioning section → `positioning.md`.
  - For inbound links to former `references/thin-shells.md § Per-Tool …`,
    repoint to `references/per-tool-shells.md`.

## 2026-05-09 - Wire conformance into the check suite + self-hosting parity

- Upstream commit: pending in this working tree
- Changed areas: `scripts/check-all.sh`,
  `templates/skill/workflows/update-upstream.md`,
  `references/self-hosting-conformance.yaml` (new),
  `references/README.md`, `scripts/README.md`, `UPSTREAM-CHANGES.md`
- Why it matters: closes three follow-on gaps that were left by the previous
  conformance commit:
  1. The conformance check shipped without being wired into `check-all.sh` —
     it was a "stored but not activated" tool (Pitfall #4 in `SKILL.md`).
     Now `check-all.sh` runs both the template manifest and the new
     self-hosting manifest before commit/push.
  2. The downstream `update-upstream` workflow ran the local
     `conformance.yaml` (a snapshot from initial scaffold), which silently
     re-validates against an old contract whenever upstream bumps required
     sections. The workflow now mandates running the check against
     `$tmp/upstream/templates/skill/conformance.yaml` (the live upstream
     contract) and only after passing may the local manifest be overwritten
     as a mechanism-owned file.
  3. The upstream repo itself was outside the conformance net — it is
     self-hosting and has no `workflows/` folder, so the template manifest
     could not validate it. The new
     `references/self-hosting-conformance.yaml` asserts the upstream's
     canonical files (`SKILL.md`, `WORKFLOW.md`, `TEMPLATES-GUIDE.md`,
     `references/protocols.md`) still teach the protocols its templates
     promise downstream — Task Closure Protocol, AAR, Recording Threshold,
     Activation Check, Generalization Rule, Progressive Rigor, etc.
  Additionally `scripts/README.md` now carries a Check Suite Matrix so
  maintainers can answer "which check covers which gap" without reading
  every script header.
- Downstream refresh guidance: when running `update-upstream`, follow the
  updated step 9 (run conformance against the upstream clone's manifest, not
  the local one). Treat `conformance.yaml` and `_parse_conformance.py` as
  mechanism-owned — overwrite them from upstream after a successful refresh.
  Do NOT copy `references/self-hosting-conformance.yaml` or `check-all.sh`
  into downstream projects; they are upstream-only maintenance assets.

## 2026-05-09 - Content conformance manifest + check script

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/conformance.yaml` (new),
  `templates/skill/scripts/check-version-conformance.sh` (new),
  `templates/skill/scripts/_parse_conformance.py` (new),
  `UPSTREAM-CHANGES.md`
- Why it matters: adds a content-presence check that complements the existing
  guardrails. `check-upstream-changes.sh` enforces a downstream-impact note,
  `sync-routing.sh --check` keeps routing tables in sync, `smoke-test.sh`
  enforces structural budgets, `check-self-scenarios.sh` proves trigger
  routing, and `check-growth-health.sh` reports growth pressure. None of
  those validate that a downstream skill actually carries the workflow
  sections an upstream upgrade just shipped (Task Closure Protocol,
  Generalization Rule, Question Gate A/B/C, the dossier-folder block, and so
  on). The new manifest closes that gap: each commit IS the version, and
  `check-version-conformance.sh <skill-root>` asserts the listed sections /
  phrases / files all exist. Default manifest path is
  `<skill-root>/conformance.yaml`; downstream skills get a copy when they
  scaffold from `templates/skill/`. Upstream self-check:
  `bash templates/skill/scripts/check-version-conformance.sh templates/skill`.
- Downstream refresh guidance: when running `update-upstream`, after the
  existing routing sync and smoke test, run the conformance check on your
  skill root. If it reports missing sections, the upstream upgrade is
  incomplete — re-apply the missing template content before declaring the
  refresh done. Do NOT add `version:` fields to `conformance.yaml`; each
  upstream commit is the version, and downstream pulls the latest manifest
  from the upstream clone.

## 2026-05-08 - Architecture governance follow-through

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/workflows/profile-project.md`,
  `references/layout.md`, `references/executable-skill-architecture.md`,
  `references/scenario-testing.md`, `TEMPLATES-GUIDE.md`,
  `references/protocols.md`, `templates/skill/workflows/update-rules.md`,
  `templates/README.md`, `templates/skill/scripts/check-growth-health.sh`,
  `templates/skill/scripts/audit-route-paths.sh`,
  `scripts/check-self-scenarios.sh`, `scripts/check-all.sh`, `README.md`,
  `README.zh-CN.md`, `skill.yaml`, and `UPSTREAM-CHANGES.md`
- Why it matters: turns the architecture review into concrete governance:
  project profiling now uses separate structure / execution / topology axes,
  growth pressure is reported without failing by default, Task Closure has one
  canonical source, references can be audited by route path, and the
  self-hosting repo has minimal scenario checks for high-risk routing.
- Downstream refresh guidance: port the three-axis `profile-project` changes
  and the new report scripts if the downstream skill is starting to grow. Keep
  `check-growth-health.sh` and `audit-route-paths.sh` report-first unless the
  downstream project has stable thresholds. Do not copy
  `scripts/check-self-scenarios.sh`; it is upstream self-hosting validation.

---

Older entries (2026-05-08 through 2026-04-30) archived to [`UPSTREAM-CHANGES-archive.md`](UPSTREAM-CHANGES-archive.md).
