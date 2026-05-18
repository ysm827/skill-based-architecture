---
date: YYYY-MM-DD                       # day the plan was drafted; filename uses the same date
status: draft                          # draft | executing | done | abandoned
# distilled_to:                        # set on close — the live-structure files that received load-bearing content
#   - rules/<topic>.md                 # for "must / must not do X" conclusions
#   - references/gotchas.md            # for "we tried Y; here is why Y is wrong" anti-patterns
#   - SKILL.md § Common Pitfalls #N    # if Pitfalls is the right home
# Omit distilled_to entirely if status is abandoned, OR if you genuinely judged no
# conclusion was load-bearing. Note that judgment in the plan body.
---

# Plan: {{Title}}

> Plans are frozen snapshots. Edit freely while `status: draft` or `executing`. Once `status: done` or `abandoned`, this file is read-only — lift any still-load-bearing content into `rules/` / `references/gotchas.md` / SKILL.md Pitfalls instead.

## Context

Why are we drafting this plan? What changed?

## Problem

The thing we are trying to solve, stated concretely.

## Options Considered

- **Option A: ...** — Pros / cons.
- **Option B: ...** — Pros / cons.
- **Option C: ...** — Pros / cons.

## Chosen Approach

Which option won, and the one or two sentences of "why" that will survive into the live structure on close.

## Steps

Concrete actions, in order. Tick off as you go.

- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

## Open Questions

Things still unresolved at the time of drafting. Closed questions should be moved into the body above as decisions, not left here as resolved checkboxes.

<!-- For abandoned plans, replace the body with a single section: -->
<!-- ## Why Abandoned -->
<!-- One paragraph. Do not distill; the absence of a decision is itself the record. -->
