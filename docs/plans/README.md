# Plan Archive

Frozen snapshots of plans that were drafted, executed, or abandoned. **Plans here are never updated after they leave `draft`** — they are historical artifacts, not active knowledge.

## Why archive plans at all

Plans contain things that don't naturally fit into `rules/` or `references/`: the full context as it stood at the time, dead-end branches, calendar pressure, prior assumptions, who-said-what. Most of that has no ongoing value — but occasionally someone needs to ask "wait, why did we even consider doing it that way back then?", and the surviving rule alone is not enough.

The deal: archive is cheap (one file, no maintenance burden), so we keep it. But it is **not active knowledge**:
- It is **not** linked from `SKILL.md` routing.
- It is **not** required reading on any task path.
- It is **not** maintained once frozen.

If something in here turns out to be load-bearing — i.e. an agent making a future change would do the wrong thing without it — that fragment must be **lifted into the live structure** (see "When a plan closes" below). Keeping it alive only in a plan archive is the same as losing it.

## File format

Plans take **either** of two shapes — pick by complexity, per `templates/skill/workflows/plan-feature.md`:

### Simple plan — one file `YYYY-MM-DD-slug.md`

Use when the work is a focused refactor or small feature: one or two files touched, no separate research / evidence material, no separate checklist needed.

```yaml
---
date: 2026-05-12
status: done             # draft | executing | done | abandoned
distilled_to:            # required when done; list the live-structure files that received the load-bearing content
  - SKILL.md § Common Pitfalls #N
  - rules/<topic>.md
  - references/gotchas.md
# omit distilled_to entirely if abandoned, or if you genuinely judged no content was load-bearing
---
```

Body: free form. Common sections — context / problem / options considered / chosen approach / steps / open questions.

### Complex plan — directory `YYYY-MM-DD-slug/`

Use when the work needs separate PRD / research / evidence material (see `templates/skill/workflows/plan-feature.md § Complex Task Dossier`). Frontmatter lives in the directory's `prd.md`:

```text
docs/plans/YYYY-MM-DD-slug/
├── prd.md          ← frontmatter goes here
├── decisions.md    ← intra-plan ADR-lite, mutable during planning; load-bearing entries promoted into rules/ or references/ on close
├── checklist.md
├── research/
├── evidence/
├── implement.jsonl
└── check.jsonl
```

`decisions.md` inside a plan dossier is **intra-plan and mutable** during planning — it records local trade-offs as you make them. When the plan reaches `status: done`, any entry that **binds future work** gets lifted into the right live location (see next section). Local-only decisions stay in the dossier and freeze with it.

## Lifecycle

```
draft  →  executing  →  done       →  lift load-bearing content into live structure  →  archive frozen
                    ↘
                      abandoned    →  archive frozen, no distillation
```

- **draft** — being written; can change freely.
- **executing** — work in progress; can still be revised.
- **done** — work landed. **Before flipping to done, distill any load-bearing content into the live structure** (see below). Distillation is the closure step, not a follow-up.
- **abandoned** — explicitly decided not to do this. Archive with a one-line `## Why Abandoned` section at the top of the body. Do **not** distill — the absence of a decision is itself the record.

Once a file moves out of `draft` / `executing`, treat it as read-only.

## When a plan closes — where load-bearing content goes

Sort each surviving conclusion from `decisions.md` (or the simple plan's body) into one of three buckets. There is no fourth bucket called "decisions" — that was tried and removed; see [REFERENCE.md](../../REFERENCE.md) by-task entry for context.

| Conclusion shape | Lives in | Why this location |
|---|---|---|
| "Future work must / must not do X" (a constraint on future tasks) | `rules/<topic>.md` (downstream skills) | SKILL.md routing pulls `rules/` onto every relevant task path; the constraint is read automatically when it matters |
| "We tried Y; here is why Y is wrong" (anti-pattern, footgun, rejected alternative) | `references/gotchas.md` or SKILL.md § Common Pitfalls | Already on task paths; covered by `templates/skill/workflows/maintain-docs.md` Tier-0/1/2 stale-check; the "why rejected" framing is exactly what gotchas.md exists for |
| Neither — purely "what happened, why we did it then" | Stays in the plan archive only; `distilled_to:` is omitted | Pure provenance with no future binding — archiving alone is correct |

If a conclusion fits multiple buckets (e.g. both a rule and a pitfall), it goes in both places — these are different audiences, not duplicates.

## Discoverability

Plans are **not** linked from `SKILL.md` or `REFERENCE.md` routing. They are reachable from:

1. `git log docs/plans/` if you want to scan history directly.
2. `ls docs/plans/` — filename includes date, so chronological order is free.
3. Soft references in `rules/` / `references/gotchas.md` entries (e.g. "see `docs/plans/2026-05-12-thin-shells-generator.md` for rejected alternatives") when the maintainer wanted to leave breadcrumbs.

That is intentional: routing should pull active knowledge, not archaeology.
