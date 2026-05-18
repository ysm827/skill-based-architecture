## Auto-Triggers

- **New task in same session** → re-read `SKILL.md`, re-match the route above, re-read all required files. "I already read it" is not valid — context compresses, routes differ.
- Closure checks fire by task type — see `templates/skill/workflows/update-rules.md` § Task Closure Trigger Policy:
  - Pure Q&A / code explanation / read-only investigation / advice with no file changes → no AAR, no smoke-test
  - Code / behavior changes → lightweight AAR scan; stop if all four answers are "no"
  - Skill docs / routing / scripts / entry shells / structure changed → run only the route/structure checks matched by the change; **`smoke-test.sh` is not a default closure action for ordinary code changes**
- When adding to `templates/` → apply the "would two real projects disagree?" admission test (`templates/ANTI-TEMPLATES.md`)

## Red Flags — STOP

- "Just this once I'll skip the AAR" → stop. See `templates/skill/workflows/update-rules.md` § Rationalizations to Reject.
- "I'll inline this in SKILL.md instead of linking a reference" → stop. SKILL.md stays within dual budget (description ≤ 25 + body ≤ 90 lines); content goes to `references/` or `templates/`.
- "Let me pre-fill a gotchas example so the template feels complete" → stop. `templates/ANTI-TEMPLATES.md` forbids project-specific content in templates.
