---
date: 2026-05-12
status: done
distilled_to:
  - SKILL.md § Common Pitfalls #2 (Soft-pointer-only shell)
  - references/thin-shells.md § "Why a bootstrap instead of just 'Scan skills/'?"
---

# Plan: Self-hosting thin shells — generator vs. shared-source

> Reconstructed retroactively on 2026-05-14 from session transcript + commits `e2ffe7a` through `47f19a0`. The original planning happened informally in conversation. Kept as a plan archive (audit trail of "why we chose A over B"); the operationally-binding rule lives in SKILL.md Pitfall #2 and references/thin-shells.md — where new agents will actually read it.

## Context

The four root shells (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`) plus `.cursor/rules/workflow.mdc` had drifted multiple times. Each is ~90% identical. The previous approach was hand-editing all five whenever the common protocol changed. The trigger for this plan was the user's observation: "this is going to bite us in 6 months."

## Problem

Five near-identical files. Manual edit-all-five is unreliable (silent drift). Need a mechanism that:

1. Keeps the literal content present in each file (cannot be dropped by harness context compaction).
2. Lets humans edit one source, not five.
3. Makes "out of sync" a machine-detectable failure, not a vibe.

## Options Considered

- **Option A — Hand-edit five files.** Status-quo. Already failed once; will fail again. Rejected.

- **Option B — Write a single `_SHELL.md` and have ABCD contain only "go read `_SHELL.md`".** User's intuitive proposal: "为什么不写一个 E,统一让 ABCD 来读 E 呢?" Rejected because this is the "soft-pointer-only shell" pitfall — harnesses compact context, the pointer can be lost, and the agent then has no routing/protocol with no idea what was lost. The redundancy is intentional. Documented in `SKILL.md § Common Pitfalls #2`.

- **Option C — Generator: ABCD are build artifacts of one source.** Keeps the literal content in each file (preserves #2's guarantee) AND single-edit (no manual sync). Drift becomes a `check-self-shells.sh` failure, not a silent rot.

## Chosen Approach

Option C. Sources:

- `references/self-hosting-shell-base.md` — common body.
- `references/self-hosting-shells.yaml` — per-harness frontmatter / title / opening / appended.
- `references/self-hosting-routing.yaml` — routing manifest (existence validation only; block text hardcoded in generator).

Generator: `scripts/sync-self-shells.sh`. Drift check: `scripts/check-self-shells.sh`. Wired into `scripts/check-all.sh`.

## Steps

- [x] Extract common body to `references/self-hosting-shell-base.md`.
- [x] Extract per-harness deltas to `references/self-hosting-shells.yaml`.
- [x] Rename `sync-self-routing.sh` → `sync-self-shells.sh` (scope grew beyond just routing).
- [x] Rename `check-self-routing.sh` → `check-self-shells.sh`.
- [x] Add description-identity check across SKILL.md / Cursor registration / `skill.yaml`.
- [x] Wire into `scripts/check-all.sh`.
- [x] Verify all four root shells + Cursor workflow.mdc regenerate identically to their pre-refactor content.

## Open Questions (resolved during execution)

- ~~Should the routing block text be parametrized from `self-hosting-routing.yaml`?~~ → No. Existence-only validation is enough; the block text is for agents, written once, stable. Keeping it as a constant inside the generator avoids over-engineering the YAML.
- ~~Should `.cursor/skills/skill-based-architecture/SKILL.md` be fully generated too?~~ → No. That file has Cursor-registration-specific structure that is hand-maintained. The generator only replaces the routing block inside it, leaving the rest untouched.
