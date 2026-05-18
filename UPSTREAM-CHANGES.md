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

- Status: superseded by YYYY-MM-DD - newer-title    # OPTIONAL — see below
- Upstream commit: <hash> <subject>
- Changed areas: <files or directories>
- Why it matters: <intent>
- Downstream refresh guidance: <what to compare/port/preserve>
```

### Status field (optional)

Default = active (omit the `Status:` line). Add it only when an entry's guidance has been **reversed** (not merely extended) by a later commit:

- `Status: superseded by YYYY-MM-DD - <title>` — newer entry replaces this guidance. Downstream refresh agents follow the newer entry, skip this one.
- `Status: deprecated — <one-line reason>` — the mechanism this entry describes was removed entirely; no replacement exists. The entry stays as history.

**Writer protocol.** When your new entry reverses an older one — active or archived — edit the older entry to add the `Status: superseded by ...` line referencing your new entry's heading. Pointers are one-way (older → newer); the new entry can mention the supersede in prose but doesn't carry machine markup. Extending or building on a prior entry does **not** count as reversal — only reach for `superseded by` when reading the old guidance would lead a future agent astray.

**Check.** `scripts/check-upstream-supersedes.sh` (wired into `check-all.sh`) validates every `Status: superseded by` reference resolves to a real `## YYYY-MM-DD - title` heading in `UPSTREAM-CHANGES.md` or `UPSTREAM-CHANGES-archive.md`. Broken references fail the suite.

## Archive Policy

Downstream refresh agents almost always only read the most recent 3–5 entries. Old entries cost them context without changing decisions. When this file passes ~300 lines (or roughly 8 entries), move the oldest entries to `UPSTREAM-CHANGES-archive.md` and keep only the most recent 3–5 here.

The archive file has the same format and is read on demand if a downstream agent is investigating a specific historical change. `scripts/check-upstream-changes.sh` only enforces a same-diff entry in `UPSTREAM-CHANGES.md`; archived entries are out of its scope.

## 2026-05-12 - Self-hosting thin-shell generator (`sync-self-shells.sh`)

- Upstream commit: pending in this working tree
- Changed areas: `references/self-hosting-shell-base.md` (new — common body),
  `references/self-hosting-shells.yaml` (new — per-harness deltas),
  `scripts/sync-self-shells.sh` (renamed from `sync-self-routing.sh`,
  rewritten for whole-shell generation),
  `scripts/check-self-shells.sh` (renamed from `check-self-routing.sh`,
  internal call updated),
  `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`,
  `.cursor/rules/workflow.mdc` (now generated, do NOT hand-edit),
  `scripts/check-all.sh` (label + script-name update),
  `scripts/README.md`, `REFERENCE.md`, `references/self-hosting-routing.yaml`
  (header comment), `templates/skill/scripts/smoke-test.sh § 7`,
  `UPSTREAM-CHANGES.md`
- Why it matters: the previous `sync-self-routing.sh` only managed the routing
  block between `<!-- SELF_ROUTING_BLOCK_START -->` markers (~12 lines per
  shell). The other ~18 lines per shell — opening, Auto-Triggers, Red Flags,
  per-harness notes — were hand-maintained. Direct diff of the four shells
  pre-generator showed **5 unintended drifts already present**:
    1. `AGENTS.md` had a unique 2-paragraph opening; the other three diverged
       on whether to link `[references/layout.md]`.
    2. CODEX/GEMINI lost the `"I already read it" is not valid — context
       compresses, routes differ` clause that AGENTS/CLAUDE carry.
    3. CODEX/GEMINI lost the `See § Rationalizations to Reject` reference
       in the first Red Flag bullet.
    4. CODEX had a short version of the ANTI-TEMPLATES Red Flag without the
       file reference.
    5. `.cursor/rules/workflow.mdc` Red Flag still said `SKILL.md stays ≤ 100
       lines` — outdated since 2026-05-09's dual-budget change (description
       ≤ 25 + body ≤ 90). Hand-maintained docs drift in proportion to file
       count × edit cadence.
  Pointer-style solutions ("CLAUDE.md says 'go read E'") fail by the same
  mechanism as the Soft-pointer-only shell pitfall (SKILL.md § Common
  Pitfalls #2): harness context-compaction can drop the pointer between
  session start and the moment the agent needs the protocol. Symlinks fail
  on Windows + force 100% identity, killing legitimate per-harness deltas
  (e.g. CODEX's `apply_patch` notes). Therefore: build-time generation,
  read-time literal content.

  Source-of-truth files:
    - `references/self-hosting-shell-base.md` — common body (Auto-Triggers +
      Red Flags). Single place to update the wording every shell shares.
    - `references/self-hosting-shells.yaml` — per-harness `file`, `title`,
      optional `frontmatter` (only `.mdc` uses), `opening`, optional
      `appended` (only CODEX uses for `## Codex-specific notes`).

  Generation:
    - `scripts/sync-self-shells.sh` composes each entry from base + yaml +
      hardcoded routing block, writes to disk. Targets: 4 root shells +
      `.cursor/rules/workflow.mdc` in full-file mode; `.cursor/skills/.../
      SKILL.md` in routing-block-only mode (the rest is Cursor-registration
      specific and stays hand-maintained; description identity is checked
      separately by `check-self-shells.sh`).
    - `--check` mode diffs generated content against on-disk and exits
      non-zero on drift — wired into `check-all.sh` ("self-hosting shells +
      activation check").

  Drift outcome after generation (verified by `diff` of resulting files):
    - CLAUDE ↔ GEMINI: differ by only the `# CLAUDE.md` / `# GEMINI.md` title.
    - CLAUDE ↔ CODEX: title + the legitimate `## Codex-specific notes`
      appended section.
    - AGENTS ↔ CLAUDE: title + AGENTS's unique 2-paragraph opening
      (intentionally preserved as per-harness delta — AGENTS is the most
      generic shell, read by tools that don't have a specific narrowing).
    - All five files: `--check` returns OK.

  No new external dependencies (custom yaml subset parser inline; pattern
  matches `_parse_conformance.py`). One Python composition bug (extra blank
  line from a stray `\n` in a join part) was caught by visual inspection of
  `head -8 CLAUDE.md` and fixed before this commit.
- Downstream refresh guidance: this generator is **upstream-only**
  maintenance. Do NOT copy `sync-self-shells.sh`, `self-hosting-shell-base.md`,
  `self-hosting-shells.yaml`, or `check-self-shells.sh` into downstream
  projects. Downstream shells follow `templates/shells/` (a separate seed
  set that each project owns after scaffold). If a downstream project finds
  its own four shells drifting and wants the same generator pattern, port
  the structure but keep the source files local — they are project knowledge,
  not template content.

## 2026-05-12 - `Status: superseded by` field + check for reversed UPSTREAM-CHANGES entries

- Upstream commit: pending in this working tree
- Changed areas: `UPSTREAM-CHANGES.md` (schema doc),
  `templates/skill/workflows/update-upstream.md` (step 3 read semantic),
  `scripts/check-upstream-supersedes.sh` (new),
  `scripts/check-all.sh` (wire new check), `UPSTREAM-CHANGES.md` (this entry)
- Why it matters: until now, UPSTREAM-CHANGES.md was a strictly append-only
  time log. The archive policy moves old entries out of context, but it does
  not address the second-order problem: **later commits can reverse the
  guidance of earlier entries, and the older entry has no signal that it has
  been overruled**. A downstream refresh agent reading an archived entry from
  3 months ago will follow its instructions verbatim — even if upstream
  removed the file it tells them to add. Probability across many downstream
  skills and a multi-quarter horizon approaches 1.

  Mechanism: entries gain an optional `Status:` line as their first bullet.
  Two values:
    - `Status: superseded by YYYY-MM-DD - <title>` — newer entry replaces this
      guidance; refresh agents follow the newer one, skip this one.
    - `Status: deprecated — <one-line reason>` — mechanism removed entirely;
      no replacement.
  Pointers are **one-way** (older entry → newer entry). The newer entry can
  mention the supersede in prose but does not carry machine markup —
  bidirectional references would double the bookkeeping cost without
  improving check coverage.

  Enforcement: `scripts/check-upstream-supersedes.sh` validates every
  `Status: superseded by` reference resolves to a real `## YYYY-MM-DD -
  title` H2 heading in `UPSTREAM-CHANGES.md` or
  `UPSTREAM-CHANGES-archive.md`. Fence-aware (schema examples inside
  ```` ```text ```` blocks are skipped, not treated as references).
  Wired into `check-all.sh` between the change-note guard and the routing
  manifest check.

  Read protocol: `templates/skill/workflows/update-upstream.md § Procedure
  step 3` now instructs downstream refresh agents to skip any entry whose
  first bullet starts with `- Status: superseded by …` or `- Status:
  deprecated …`.
- Downstream refresh guidance: pull the updated
  `workflows/update-upstream.md` as a mechanism-owned file. The
  `check-upstream-supersedes.sh` script is upstream-only maintenance —
  do NOT copy it into downstream projects. Downstream UPSTREAM-CHANGES
  consumption changes are read-only: when a refresh entry's first bullet
  is `Status: superseded by …`, follow the entry it points to instead.
  When `Status: deprecated`, skip entirely.

## 2026-05-12 - Tier-2 maintenance ledger (`.maintenance-log.yaml`)

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/workflows/maintain-docs.md`,
  `templates/skill/scripts/smoke-test.sh`, `templates/README.md`,
  `.maintenance-log.yaml` (new — upstream self-hosting bootstrap),
  `UPSTREAM-CHANGES.md`
- Why it matters: closes a dangling clock in the Tier 0/1/2 model shipped
  on 2026-05-11. The Tier-2 trigger list included "Smoke-test Tier-0
  flagged a duplicate **and** the previous Tier-2 pass was more than ~30
  days ago" but nothing in the architecture recorded when a Tier-2 pass
  actually ran. Three observable failure modes:
    1. **Never triggers** — agent reads the condition, finds no record,
       treats "no record" as "no event", skips Tier-2. The drift the tier
       was designed to catch accumulates silently (real example: chaos_web
       audit found 4 verbatim-dup entries before any agent noticed).
    2. **Always triggers** — different agent reads the same condition,
       treats "no record ≡ infinitely old", runs full reorg every time
       smoke-test reports a dup. Token cost balloons.
    3. **Inconsistent across sessions** — the two agents above are the
       same agent on different days. Tier-2 fires unpredictably and no
       decision is reproducible.
  Fix: introduce `.maintenance-log.yaml` at the skill root as the per-file
  Tier-2 timestamp. Schema is lenient (`path` required, `last_tier2`
  required once a pass has run, rest advisory) so the file stays
  hand-editable. `maintain-docs.md § Step 7` now adds the write step as a
  Tier-2 closure gate — Tier-2 is incomplete until the ledger is updated.
  `smoke-test.sh § 2a` reads the ledger on every detected dup `##` heading
  and prints one of three Tier-2 hints (no entry / > 30d / ≤ 30d). The
  duplicate itself still always fails; the ledger only governs the *reorg
  recommendation* on top.

  Side effect: `smoke-test.sh` budget raised from 800 to 850 lines in
  `templates/README.md`. The ~25 lines of helpers + advisory branch are
  the minimum that closes the dangling clock. **Next addition to
  `smoke-test.sh` forces extraction** into a `check-<concern>.sh`
  companion (same pattern as `check-description-routing.sh`); the next
  budget bump is not on the table.
- Downstream refresh guidance: pull the updated `workflows/maintain-docs.md`
  and `scripts/smoke-test.sh` as mechanism-owned files. Then, for each
  long-lived entries-style file in your skill (`references/gotchas.md`,
  any `*pitfall*.md`, plus optionally entry-style logs like a project's
  decision log or upstream-changes log), add an entry to a new
  `skills/<name>/.maintenance-log.yaml` per the schema in `Step 7`. If
  no Tier-2 has been run on that file yet, omit `last_tier2:` — smoke-test
  will treat the first dup as a baseline-trigger and recommend a Tier-2
  baseline pass. Do **not** copy the upstream `.maintenance-log.yaml`
  from this repo; it is upstream-state, not a template.

## 2026-05-12 - rules/*.md categorization guidance in maintain-docs Step 3

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/workflows/maintain-docs.md`,
  `UPSTREAM-CHANGES.md`
- Why it matters: Tier 2 § Step 3 "Categorize (before splitting)"
  previously described categorization only for entries-style files
  (gotchas / pitfalls — promote `**[topic]**` tags to H2 categories).
  For `rules/*.md`, which don't carry tags, the workflow gave no
  concrete recipe — agents crossing the Tier 2 trigger had to invent
  a grouping axis from scratch every time. Step 3 now distinguishes
  the two file types and articulates three common axes for
  `rules/*.md`: module / surface boundary, responsibility / lifecycle
  phase, and trigger scenario, with a "pick exactly one axis per file"
  constraint. Mixing axes is reframed as a split signal (Step 6), not
  a categorization signal. Single H2 growing past ~30 bullet-rules is
  the recommended sub-rule extraction threshold.
- Downstream refresh guidance: pull the updated
  `workflows/maintain-docs.md` as a mechanism-owned file. No migration
  required for existing rule files; the new guidance only fires when
  a `rules/*.md` crosses the Tier 2 bullet-rule trigger (> 25
  bullet-level rules) or when the user explicitly asks for cleanup.

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
