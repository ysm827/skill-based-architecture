#!/usr/bin/env bash
# Generate self-hosting thin shells from a single source.
#
# Sources (upstream-only):
#   references/self-hosting-shell-base.md   common body (Auto-Triggers + Red Flags)
#   references/self-hosting-shells.yaml     per-harness frontmatter / title / opening / appended
#   references/self-hosting-routing.yaml    routing manifest (validated; block text hardcoded below)
#
# Targets:
#   AGENTS.md, CLAUDE.md, CODEX.md, GEMINI.md, .cursor/rules/workflow.mdc
#     → whole-file generation (anything hand-edited will be overwritten)
#   .cursor/skills/skill-based-architecture/SKILL.md
#     → routing-block-only replace (the rest is Cursor-registration-specific
#       and stays hand-maintained; description identity is checked separately
#       by scripts/check-self-shells.sh)
#
# Usage: scripts/sync-self-shells.sh [--check]
#   --check : diff generated content against on-disk, non-zero exit on drift.
#
# Why a generator: see UPSTREAM-CHANGES.md 2026-05-12 "self-hosting shell generator"
# entry. The four root shells must contain literal protocol content (the
# "soft-pointer-only shell" pitfall in SKILL.md § Common Pitfalls forbids
# delegating to "go read X" since harness context-compaction can drop it).
# Maintaining 4-5 near-identical files by hand drifts; generation makes "they
# stay in sync" a machine invariant.

set -euo pipefail

MODE="sync"
for arg in "$@"; do
  case "$arg" in
    --check) MODE="check" ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROUTING="$ROOT/references/self-hosting-routing.yaml"
SHELLS_YAML="$ROOT/references/self-hosting-shells.yaml"
BASE_MD="$ROOT/references/self-hosting-shell-base.md"
CURSOR_REG="$ROOT/.cursor/skills/skill-based-architecture/SKILL.md"

for f in "$ROUTING" "$SHELLS_YAML" "$BASE_MD"; do
  [[ -f "$f" ]] || { echo "Missing source: $f" >&2; exit 1; }
done

python3 - "$ROOT" "$ROUTING" "$SHELLS_YAML" "$BASE_MD" "$CURSOR_REG" "$MODE" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
routing_yaml = Path(sys.argv[2])
shells_yaml = Path(sys.argv[3])
base_md = Path(sys.argv[4])
cursor_reg = Path(sys.argv[5])
mode = sys.argv[6]

START = '<!-- SELF_ROUTING_BLOCK_START -->'
END = '<!-- SELF_ROUTING_BLOCK_END -->'

# Routing block text is hardcoded. The manifest at routing_yaml is validated
# for existence + path health, but the literal block shown to agents stays
# stable across manifest content edits. To change the block text itself, edit
# this constant.
ROUTING_BLOCK = """## Quick Routing (survives context truncation)

Task routes live in `references/self-hosting-routing.yaml`.

For every new task:
1. Read `SKILL.md`.
2. Read `references/self-hosting-routing.yaml`.
3. Match by `labels`, `trigger_examples`, and task intent.
4. Read only that route's `required_reads`, then follow its `workflow`.
5. If no route matches, use the `other` route."""


def clean(value: str) -> str:
    value = value.strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1]
    return value


def parse_routing_manifest():
    tasks = []
    current = None
    section = None
    for raw in routing_yaml.read_text().splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        stripped = raw.strip()
        if stripped == "tasks:":
            continue
        if raw.startswith("  - id:"):
            current = {"id": clean(raw.split(":", 1)[1]), "required_reads": [], "trigger_examples": []}
            tasks.append(current)
            section = None
            continue
        if current is None:
            continue
        if raw.startswith("    required_reads:"):
            section = "required_reads"
            continue
        if raw.startswith("    trigger_examples:"):
            section = "trigger_examples"
            continue
        if section in {"required_reads", "trigger_examples"} and raw.startswith("      - "):
            current[section].append(clean(stripped[2:]))
            continue
        if raw.startswith("    ") and ":" in stripped:
            key, value = stripped.split(":", 1)
            current[key.strip()] = clean(value)
            section = None
    if not tasks:
        raise SystemExit("self-hosting-routing.yaml has no tasks")
    ids = [task.get("id", "") for task in tasks]
    if len(ids) != len(set(ids)):
        raise SystemExit("self-hosting-routing.yaml has duplicate task ids")
    if "other" not in ids:
        raise SystemExit("self-hosting-routing.yaml is missing fallback task id: other")
    errors = []
    for task in tasks:
        refs = list(task.get("required_reads", []))
        workflow = task.get("workflow", "")
        if workflow:
            refs.append(workflow)
        for ref in refs:
            if "FILL:" in ref or ref.startswith("Check "):
                continue
            path = ref.split("#", 1)[0]
            if not path or not (".md" in path or ".sh" in path or "/" in path):
                continue
            if not (root / path).exists():
                errors.append(f"{task.get('id')}: missing route target: {ref}")
    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        raise SystemExit(1)


def parse_shells():
    """Subset yaml parser. Top key: `shells:`. Each item starts with `  - key: val`
    and may have additional `    key: val` or `    key: |` continuations. Multi-line
    block scalars (`|`) collect indented lines until the indent drops."""
    text = shells_yaml.read_text()
    shells = []
    current = None
    multi_key = None
    multi_lines = []
    multi_indent = None

    def flush_multi():
        nonlocal multi_key, multi_lines, multi_indent
        if multi_key is not None and current is not None:
            value = "\n".join(multi_lines)
            if not value.endswith("\n"):
                value += "\n"
            current[multi_key] = value
        multi_key = None
        multi_lines = []
        multi_indent = None

    for raw in text.splitlines():
        if multi_key is not None:
            if raw.strip() == "":
                multi_lines.append("")
                continue
            stripped_left = raw.lstrip(" ")
            line_indent = len(raw) - len(stripped_left)
            if multi_indent is None:
                multi_indent = line_indent
            if line_indent >= multi_indent:
                multi_lines.append(raw[multi_indent:])
                continue
            flush_multi()

        if raw.lstrip().startswith("#"):
            continue
        if not raw.strip():
            continue
        if raw.rstrip() == "shells:":
            continue
        if raw.startswith("  - "):
            current = {}
            shells.append(current)
            kv = raw[4:].strip()
            if ":" in kv:
                key, _, val = kv.partition(":")
                current[key.strip()] = clean(val)
            continue
        if raw.startswith("    ") and current is not None:
            content = raw[4:]
            if ":" in content:
                key, _, val = content.partition(":")
                key = key.strip()
                val = val.strip()
                if val == "|":
                    multi_key = key
                    multi_lines = []
                    multi_indent = None
                else:
                    current[key] = clean(val)

    flush_multi()
    if not shells:
        raise SystemExit("self-hosting-shells.yaml has no shells")
    return shells


def compose_shell(entry, base_body):
    """Join parts with `\n` and trust each `""` element to produce exactly one
    blank line. Never embed `\n` inside a part — that double-spaces."""
    parts = []
    fm = entry.get("frontmatter", "").rstrip("\n")
    if fm:
        parts.append(fm)
        parts.append("")
    title = entry.get("title", "").strip()
    if not title:
        raise SystemExit(f"shell entry missing title: {entry.get('file', '?')}")
    parts.append(f"# {title}")
    parts.append("")
    opening = entry.get("opening", "").rstrip("\n")
    if opening:
        parts.append(opening)
        parts.append("")
    parts.append(START)
    parts.append(ROUTING_BLOCK)
    parts.append(END)
    parts.append("")
    parts.append(base_body.rstrip("\n"))
    appended = entry.get("appended", "").rstrip("\n")
    if appended:
        parts.append("")
        parts.append(appended)
    return "\n".join(parts) + "\n"


def update_cursor_registration():
    if not cursor_reg.exists():
        return None
    text = cursor_reg.read_text()
    replacement = f"{START}\n{ROUTING_BLOCK}\n{END}"
    if START in text and END in text:
        before = text.split(START, 1)[0]
        after = text.split(END, 1)[1]
        return before + replacement + after
    return None


parse_routing_manifest()
shells = parse_shells()
base_body = base_md.read_text()

failed = False

for entry in shells:
    rel = entry.get("file", "")
    if not rel:
        raise SystemExit("shell entry missing 'file'")
    target = root / rel
    new_text = compose_shell(entry, base_body)
    old_text = target.read_text() if target.exists() else ""
    if new_text == old_text:
        print(f"OK: {rel}")
    elif mode == "check":
        print(f"DRIFT: {rel}")
        failed = True
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(new_text)
        print(f"synced {rel}")

cursor_new = update_cursor_registration()
if cursor_new is not None:
    old_text = cursor_reg.read_text()
    if cursor_new == old_text:
        print(f"OK: {cursor_reg.relative_to(root)}")
    elif mode == "check":
        print(f"DRIFT: {cursor_reg.relative_to(root)}")
        failed = True
    else:
        cursor_reg.write_text(cursor_new)
        print(f"synced {cursor_reg.relative_to(root)} (routing block only)")

if failed:
    print("\nRun: bash scripts/sync-self-shells.sh")
    raise SystemExit(1)
if mode == "check":
    print("\nAll self-hosting shells match generated content.")
PY
