#!/usr/bin/env bash
# Verify that active-tier and workflow files are reachable from a task route.
#
# Single-root compatibility:
#   bash scripts/route-reachability.sh
# Two-root usage (run once from each local root):
#   bash scripts/route-reachability.sh --namespace skill --routing /path/to/routing.yaml
#   bash /path/to/scripts/route-reachability.sh --namespace code --routing /path/to/routing.yaml

set -uo pipefail

ROOT="$PWD"
ROUTING="$ROOT/routing.yaml"
NAMESPACE=""

usage() {
  echo "Usage: bash route-reachability.sh [--namespace skill|code] [--routing <path>]" >&2
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

if [[ ! -f "$ROUTING" ]]; then
  if [[ "$NAMESPACE" == "single" ]]; then
    echo "route-reachability: no routing.yaml at $ROOT — nothing to check"
    exit 0
  fi
  echo "route-reachability: two-root audit requires --routing <path>" >&2
  exit 2
fi

# Workflows are active procedures, not lookup material: a workflow referenced
# only by another dead workflow is not route-reachable and must fail here.
ACTIVE_DIRS=(architecture conventions gotchas rules workflows references/business)
TOKEN_RE='(skill:|code:)?(architecture|conventions|gotchas|rules|references|workflows)/[A-Za-z0-9._/-]+\.md'

strip_fences() { awk 'BEGIN{f=0} /^```/ {f=1-f; next} !f' "$1"; }

normalize_tokens() {
  local mode="$1" token prefix rel
  grep -oE "$TOKEN_RE" 2>/dev/null | sort -u | while IFS= read -r token; do
    [[ -n "$token" ]] || continue
    prefix=""
    rel="$token"
    case "$token" in
      skill:*) prefix="skill"; rel="${token#skill:}" ;;
      code:*) prefix="code"; rel="${token#code:}" ;;
    esac
    if [[ "$NAMESPACE" == "single" ]]; then
      [[ -z "$prefix" ]] && printf '%s\n' "$rel"
    elif [[ "$mode" == "routing" ]]; then
      [[ "$prefix" == "$NAMESPACE" ]] && printf '%s\n' "$rel"
    elif [[ -z "$prefix" || "$prefix" == "$NAMESPACE" ]]; then
      printf '%s\n' "$rel"
    fi
  done
}

# A two-root route must use an explicit prefix; local hub edges may remain
# unprefixed because they resolve inside the root currently being checked.
reachable="$(grep -vE '^[[:space:]]*#' "$ROUTING" | normalize_tokens routing)"

while :; do
  add=""
  while IFS= read -r rel; do
    [[ -n "$rel" && -f "$ROOT/$rel" ]] || continue
    add+="$(strip_fences "$ROOT/$rel" | normalize_tokens local)"$'\n'
    # Same-directory workflow links are commonly written as `(task-closure.md)`.
    # Resolve those only while traversing an already-reachable workflow.
    if [[ "$rel" == workflows/* ]]; then
      while IFS= read -r base; do
        [[ -n "$base" && -f "$ROOT/workflows/$base" ]] || continue
        add+="workflows/$base"$'\n'
      done < <(strip_fences "$ROOT/$rel" | grep -oE '[A-Za-z0-9._-]+\.md' | sort -u || true)
    fi
  done <<< "$reachable"
  next="$(printf '%s\n%s\n' "$reachable" "$add" | grep -vE '^[[:space:]]*$' | sort -u)"
  [[ "$next" == "$reachable" ]] && break
  reachable="$next"
done

UNREACHED=0
TOTAL=0
echo "Route-reachability — namespace=$NAMESPACE, root=$ROOT"
echo "============================================================"
for dir in "${ACTIVE_DIRS[@]}"; do
  while IFS= read -r file; do
    case "$(basename "$file")" in README.md) continue ;; esac
    TOTAL=$((TOTAL+1))
    rel="${file#$ROOT/}"
    if ! grep -qxF "$rel" <<< "$reachable"; then
      echo "UNREACHED  $rel"
      UNREACHED=$((UNREACHED+1))
    fi
  done < <(find "$ROOT/$dir" -type f -name '*.md' 2>/dev/null | sort)
done

echo ""
echo "Summary: $UNREACHED unreachable / $TOTAL active file(s)"
[[ "$UNREACHED" -eq 0 ]] || exit 1
