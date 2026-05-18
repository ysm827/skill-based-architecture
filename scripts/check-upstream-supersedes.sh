#!/usr/bin/env bash
# Validate `Status: superseded by …` references in UPSTREAM-CHANGES.md and
# UPSTREAM-CHANGES-archive.md. Every such reference must resolve to a real
# `## YYYY-MM-DD - title` H2 heading in one of the two files.
#
# Pointers are one-way (older entry → newer entry that replaced it).
# Schema + writer protocol: UPSTREAM-CHANGES.md § "Status field (optional)".
# Read semantic: templates/skill/workflows/update-upstream.md § Procedure step 3.
#
# Cheap to always run (two markdown files). Catches drift when entries are
# renamed, merged, or removed without updating their incoming supersede refs.
#
# Default state (no `Status: superseded by` lines anywhere) → 0 refs validated,
# exit 0. The check only fires once someone uses the mechanism.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILES=(UPSTREAM-CHANGES.md UPSTREAM-CHANGES-archive.md)

# Collect every "## YYYY-MM-DD - title" heading across both files, ignoring
# anything inside ```...``` fences (schema examples in docs use real-looking
# heading lines that must not count as targets).
extract_outside_fences() {
  # $1=file, $2=awk pattern, output: "<file>\t<line_no>\t<line>"
  awk -v fname="$1" -v pat="$2" '
    /^```/ { in_fence = !in_fence; next }
    !in_fence && $0 ~ pat { print fname "\t" NR "\t" $0 }
  ' "$1"
}

HEADINGS=""
for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || continue
  while IFS=$'\t' read -r _ _ line; do
    HEADINGS+="$line"$'\n'
  done < <(extract_outside_fences "$f" '^## [0-9]{4}-[0-9]{2}-[0-9]{2} ')
done

BROKEN=0
TOTAL=0
while IFS=$'\t' read -r src_file src_line body; do
  [[ -z "$body" ]] && continue
  # Strip "- Status: superseded by " prefix, trim trailing whitespace.
  target=$(printf '%s' "$body" | sed -E 's/^[[:space:]]*-[[:space:]]*Status:[[:space:]]*superseded by[[:space:]]*//' | sed 's/[[:space:]]*$//')
  [[ -z "$target" ]] && continue

  TOTAL=$((TOTAL + 1))
  if ! grep -qF "## $target" <<< "$HEADINGS"; then
    echo "BROKEN: $src_file:$src_line"
    echo "       $body"
    echo "       → no matching '## $target' in UPSTREAM-CHANGES.md or UPSTREAM-CHANGES-archive.md"
    BROKEN=$((BROKEN + 1))
  fi
done < <(
  for f in "${FILES[@]}"; do
    [[ -f "$f" ]] || continue
    extract_outside_fences "$f" '^- Status:[[:space:]]*superseded by'
  done
)

if [[ "$BROKEN" -gt 0 ]]; then
  echo "FAIL: $BROKEN broken 'Status: superseded by' reference(s) out of $TOTAL total."
  echo "      Fix the target heading text or restore the referenced entry."
  exit 1
fi

echo "OK: $TOTAL 'Status: superseded by' reference(s) all resolve"
exit 0
