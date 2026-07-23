#!/usr/bin/env bash
# sync-vendor.sh — Mechanically sync vendor-class files (sync-manifest.yaml)
# from an upstream clone. Replaces the per-file hand-archaeology of
# update-upstream.md steps 5–7 for files downstream must not edit.
#
# Safety model (no recorded checksums — upstream git history IS the base):
#   base = upstream@synced_sha version of the file (.upstream-sync pointer)
#   local == base        → provably unedited → safe to take upstream HEAD
#   local != base        → LOCAL-EDIT: report, never overwrite
#   no local file        → NEW: copy
#   gone at upstream HEAD→ DROPPED: report; deletion stays a human decision
#
# Usage:
#   bash scripts/sync-vendor.sh [skill-name|skill-root] --upstream <path-to-clone> [--apply]
#
# Default is dry-run (report only); --apply writes NEW/UPDATE files.
# Exit: 0 = clean · 1 = LOCAL-EDIT/DROPPED need human attention · 2 = usage/prereqs
set -uo pipefail

TARGET=""; UP=""; APPLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --upstream) UP="${2:-}"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    -h|--help)
      echo "Usage: bash sync-vendor.sh [skill-name|skill-root] --upstream <path-to-clone> [--apply]"
      echo "Mechanically syncs sync-manifest.yaml vendor files; dry-run unless --apply."
      exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

# Resolve the skill root (where SKILL.md + .upstream-sync live).
if [[ -n "$TARGET" && -f "$TARGET/SKILL.md" ]]; then SKILL_ROOT="$TARGET"
elif [[ -n "$TARGET" && -f "skills/$TARGET/SKILL.md" ]]; then SKILL_ROOT="skills/$TARGET"
elif [[ -f "SKILL.md" ]]; then SKILL_ROOT="."
else echo "Usage: bash sync-vendor.sh [skill-name|skill-root] --upstream <path-to-clone> [--apply]" >&2; exit 2; fi

if [[ -z "$UP" || ! -d "$UP/.git" ]]; then
  echo "FAIL: --upstream <path-to-clone> is required and must be a git clone (need history for the base check)." >&2
  exit 2
fi

MANIFEST="$UP/templates/skill/sync-manifest.yaml"
if [[ ! -f "$MANIFEST" ]]; then
  echo "FAIL: upstream clone has no templates/skill/sync-manifest.yaml (pre-manifest upstream? fall back to manual steps)." >&2
  exit 2
fi

TMP_DIR="$(mktemp -d)"; trap 'rm -rf "$TMP_DIR"' EXIT
VENDOR_LIST="$TMP_DIR/vendor-list"; BASE_TMP="$TMP_DIR/base"
if ! awk '
  BEGIN { inside=0; found=0; count=0; bad=0 }
  function fail(msg) { print "FAIL: " msg > "/dev/stderr"; bad=1 }
  {
    line=$0
    if (!inside) {
      if (line ~ /^vendor:[[:space:]]*(#.*)?$/) { inside=1; found=1 }
      next
    }
    if (line ~ /^[^[:space:]#]/) exit
    if (line ~ /^[[:space:]]*($|#)/) next
    if (line ~ /^  -[[:space:]]+/) {
      sub(/^  -[[:space:]]+/, "", line); sub(/[[:space:]]+$/, "", line)
      if (line == "") fail("empty vendor path")
      else { print line; count++ }
      next
    }
    fail("invalid vendor manifest line: " line)
  }
  END {
    if (!found) fail("sync-manifest.yaml has no vendor block")
    else if (count == 0) fail("sync-manifest.yaml vendor block is empty")
    if (bad) exit 1
  }
' "$MANIFEST" >"$VENDOR_LIST"; then
  exit 2
fi

validate_vendor_path() {
  local f="$1" probe part
  local -a parts
  case "$f" in
    ""|/*|.|..|./*|../*|*/.|*/..|*/./*|*/../*|*//*|*/)
      echo "FAIL: unsafe vendor path: $f" >&2; return 1 ;;
  esac
  case "$f" in
    sync-manifest.yaml|protocol-blocks/*|scripts/*) ;;
    *) echo "FAIL: vendor path is outside allowed owners: $f" >&2; return 1 ;;
  esac
  IFS='/' read -r -a parts <<< "$f"
  probe="$SKILL_ROOT"
  for part in "${parts[@]}"; do
    probe="$probe/$part"
    if [[ -L "$probe" ]]; then
      echo "FAIL: vendor target contains a symlink component: $f" >&2
      return 1
    fi
  done
}

SYNC_FILE="$SKILL_ROOT/.upstream-sync"
SYNCED_SHA="$(grep -E '^synced_sha:' "$SYNC_FILE" 2>/dev/null | head -1 | sed -E 's/^synced_sha:[[:space:]]*//')"
BASE_OK=1
if [[ -z "$SYNCED_SHA" || "$SYNCED_SHA" == *"<"* ]] \
   || ! git -C "$UP" cat-file -e "${SYNCED_SHA}^{commit}" 2>/dev/null; then
  BASE_OK=0
  echo "⚠ No usable synced_sha (missing/placeholder pointer, or sha not in upstream history)."
  echo "  Without a base, a differing local file cannot be proven unedited — all such files"
  echo "  report as LOCAL-EDIT. Do one manual pass (update-upstream.md) and set the pointer."
  echo ""
fi

new=0; upd=0; ok=0; conflict=0; dropped=0

while IFS= read -r F; do
  [[ -z "$F" ]] && continue
  validate_vendor_path "$F" || exit 2
  upnew="$UP/templates/skill/$F"; loc="$SKILL_ROOT/$F"
  if [[ ! -f "$upnew" ]]; then
    if [[ -f "$loc" ]]; then
      echo "DROPPED    $F  (gone at upstream HEAD — read the UPSTREAM-CHANGES entry, delete manually if agreed)"
      dropped=$((dropped+1))
    fi
    continue
  fi
  if [[ ! -f "$loc" ]]; then
    echo "NEW        $F"
    if [[ $APPLY -eq 1 ]]; then mkdir -p "$(dirname "$loc")"; cp -p "$upnew" "$loc"; fi
    new=$((new+1)); continue
  fi
  if cmp -s "$loc" "$upnew"; then ok=$((ok+1)); continue; fi
  if [[ $BASE_OK -eq 1 ]] \
     && git -C "$UP" show "$SYNCED_SHA:templates/skill/$F" >"$BASE_TMP" 2>/dev/null \
     && cmp -s "$loc" "$BASE_TMP"; then
    echo "UPDATE     $F  (local == base @ ${SYNCED_SHA:0:7} → taking upstream HEAD)"
    [[ $APPLY -eq 1 ]] && cp -p "$upnew" "$loc"
    upd=$((upd+1))
  else
    echo "LOCAL-EDIT $F  (differs from base — reconcile by hand: port your edit upstream, or keep the fork and record why)"
    conflict=$((conflict+1))
  fi
done < "$VENDOR_LIST"

echo ""
mode="dry-run"; [[ $APPLY -eq 1 ]] && mode="applied"
echo "vendor sync ($mode): $ok current · $new new · $upd updated · $conflict local-edit · $dropped dropped"
if [[ $APPLY -eq 0 && $((new + upd)) -gt 0 ]]; then
  echo "→ re-run with --apply to write the NEW/UPDATE files."
fi
[[ $((conflict + dropped)) -gt 0 ]] && exit 1
exit 0
