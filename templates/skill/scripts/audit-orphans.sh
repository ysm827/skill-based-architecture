#!/usr/bin/env bash
# Surface content-tier + workflow files with zero inbound links.
# Single-root compatibility:
#   bash scripts/audit-orphans.sh
# Two-root usage (run once from each local root):
#   bash scripts/audit-orphans.sh --namespace skill --routing /path/to/routing.yaml
#   bash /path/to/scripts/audit-orphans.sh --namespace code --routing /path/to/routing.yaml
# `--namespace` prevents `code:gotchas/x.md` from making a same-path
# `skill:gotchas/x.md` look reachable (and vice versa). Local unprefixed links
# still count inside the root being audited.
set -euo pipefail
ROOT="$PWD"
ROUTING="$ROOT/routing.yaml"
NAMESPACE=""

usage() {
  echo "Usage: bash audit-orphans.sh [--namespace skill|code] [--routing <path>]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      NAMESPACE="$2"; shift 2 ;;
    --routing)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      ROUTING="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

if [[ -z "$NAMESPACE" ]]; then
  if [[ -f "$ROUTING" ]] && grep -q '^path_resolution:' "$ROUTING"; then
    NAMESPACE="skill"
  else
    NAMESPACE="single"
  fi
fi
case "$NAMESPACE" in single|skill|code) ;; *) usage; exit 2 ;; esac
if [[ "$NAMESPACE" != "single" && ! -f "$ROUTING" ]]; then
  echo "audit-orphans: two-root audit requires --routing <path>" >&2
  exit 2
fi

TIER_DIRS=(rules references architecture gotchas conventions)
AUDIT_DIRS=("${TIER_DIRS[@]}" workflows)
LOCAL_SOURCES=()
for dir in workflows "${TIER_DIRS[@]}"; do
  while IFS= read -r file; do LOCAL_SOURCES+=("$file"); done < <(find "$ROOT/$dir" -type f -name '*.md' 2>/dev/null | sort)
done
for file in "$ROOT"/*.md; do [[ -f "$file" ]] && LOCAL_SOURCES+=("$file"); done
if [[ -f "$ROOT/../../AGENTS.md" || -f "$ROOT/../../CLAUDE.md" ]]; then
  for shell in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
    [[ -f "$ROOT/../../$shell" ]] && LOCAL_SOURCES+=("$ROOT/../../$shell")
  done
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
NORMALIZED_SOURCES=()
SOURCE_ORIGINS=()

normalize_local() {
  awk 'BEGIN{f=0} /^```/ {f=1-f; next} !f' "$1" |
    case "$NAMESPACE" in
      skill) sed -E 's#code:(rules|references|architecture|gotchas|conventions|workflows)/[A-Za-z0-9._/-]+\.md##g' ;;
      code) sed -E 's#skill:(rules|references|architecture|gotchas|conventions|workflows)/[A-Za-z0-9._/-]+\.md##g' ;;
      single) sed -E 's#(skill|code):(rules|references|architecture|gotchas|conventions|workflows)/[A-Za-z0-9._/-]+\.md##g' ;;
    esac
}

i=0
for file in "${LOCAL_SOURCES[@]:-}"; do
  [[ -n "$file" && -f "$file" ]] || continue
  normalized="$TMP_DIR/$i"
  normalize_local "$file" > "$normalized"
  SOURCE_ORIGINS+=("$file")
  NORMALIZED_SOURCES+=("$normalized")
  i=$((i+1))
done

routing_mentions() {
  local rel="$1" token
  [[ -f "$ROUTING" ]] || return 1
  if [[ "$NAMESPACE" == "single" ]]; then token="$rel"; else token="$NAMESPACE:$rel"; fi
  grep -vE '^[[:space:]]*#' "$ROUTING" | grep -qF "$token"
}

has_inbound() {
  local rel="$1" match="$2" absolute="$ROOT/$1" idx
  routing_mentions "$rel" && return 0
  for ((idx=0; idx<${#NORMALIZED_SOURCES[@]}; idx++)); do
    [[ "${SOURCE_ORIGINS[$idx]}" == "$absolute" ]] && continue
    grep -qF "$match" "${NORMALIZED_SOURCES[$idx]}" && return 0
  done
  return 1
}

ORPHANS=0
TOTAL=0
echo "Orphan scan — namespace=$NAMESPACE, root=$ROOT"
echo "============================================================"
for dir in "${AUDIT_DIRS[@]}"; do
  while IFS= read -r file; do
    case "$(basename "$file")" in README.md|index.md) continue ;; esac
    TOTAL=$((TOTAL+1))
    rel="${file#$ROOT/}"
    if [[ "$dir" == workflows ]]; then match="$(basename "$file")"; else match="$rel"; fi
    if ! has_inbound "$rel" "$match"; then
      echo "ORPHAN  $rel"
      ORPHANS=$((ORPHANS+1))
    fi
  done < <(find "$ROOT/$dir" -type f -name '*.md' 2>/dev/null | sort)
done

echo ""
echo "Summary: $ORPHANS orphan(s) / $TOTAL file(s)"
[[ "$ORPHANS" -eq 0 ]] || exit 1
