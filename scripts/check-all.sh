#!/usr/bin/env bash
# Run the upstream repo's full maintenance check suite.

set -euo pipefail

MODE="worktree"
BASE="${UPSTREAM_CHANGES_BASE:-HEAD}"

usage() {
  cat <<'EOF'
Usage: scripts/check-all.sh [--base <git-ref>] [--staged]

Runs the self-hosting upstream maintenance checks used before commit/push:
  - upstream change-note guard
  - upstream supersedes refs check
  - template routing manifest check
  - template SessionStart hook runtime contract
  - temporary downstream scaffold smoke test
  - self-hosting shells + activation check
  - whitespace diff check
  - single-root + two-root integrity contracts
  - self-hosting scenario checks
  - self-hosting phase 7 smoke test
  - self-hosting orphan audit
  - template content conformance (downstream contract)
  - self-hosting content conformance (upstream-canon)

Default mode checks the working tree. Use --staged from a pre-commit hook to
check the pending commit for UPSTREAM-CHANGES.md coverage and whitespace.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      [[ $# -ge 2 ]] || { echo "Missing value for --base" >&2; exit 2; }
      BASE="$2"
      shift 2
      ;;
    --staged)
      MODE="staged"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

run() {
  local label="$1"
  shift
  printf '\n==> %s\n' "$label"
  "$@"
}

check_downstream_scaffold() {
  local tmp name summary upstream_ref upstream_sha status
  tmp="$(mktemp -d)"
  name="sample-skill"
  summary="Sample downstream scaffold for upstream regression checks"
  upstream_ref="$(git -C "$ROOT" config --get remote.origin.url 2>/dev/null || printf '%s' "$ROOT")"
  upstream_sha="$(git -C "$ROOT" rev-parse HEAD)"

  set +e
  (
    set -euo pipefail
    cd "$tmp"
    mkdir -p "skills/$name"
    cp -R "$ROOT/templates/skill/." "skills/$name/"
    mv "skills/$name/SKILL.md.template" "skills/$name/SKILL.md"
    cp -R "$ROOT/templates/shells/." .
    mv ".cursor/skills/{{NAME}}/SKILL.md.template" ".cursor/skills/{{NAME}}/SKILL.md"
    mv ".cursor/skills/{{NAME}}" ".cursor/skills/$name"

    find "skills/$name" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor \
      -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.yaml' \) \
      -exec sed -i.bak \
        -e "s/{{NAME}}/$name/g" \
        -e "s/{{SUMMARY}}/$summary/g" \
        -e "s/<trigger phrase 1>/fix sample bug/g" \
        -e "s/<trigger phrase 2>/plan sample feature/g" \
        -e "s/<trigger phrase 3 \\/ 中文触发短语>/更新示例技能/g" \
        -e "s/<condition 1>/working on the sample project/g" \
        -e "s/<condition 2>/maintaining sample project rules/g" \
        -e "s/FILL:/FILLED:/g" \
        {} +
    find . -name '*.bak' -type f -delete

    printf 'upstream: %s\nsynced_sha: %s\nsynced_date: %s\n' \
      "$upstream_ref" "$upstream_sha" "$(date +%F)" > "skills/$name/.upstream-sync"

    bash "skills/$name/scripts/sync-routing.sh" "$name" --check
    bash "skills/$name/scripts/smoke-test.sh" "$name" --phase 8
    (
      cd "skills/$name"
      bash scripts/audit-orphans.sh
      bash scripts/route-reachability.sh
    )
  )
  status=$?
  set -e
  rm -rf "$tmp"
  return "$status"
}

check_two_root_integrity() {
  local tmp skill_root code_root routing
  tmp="$(mktemp -d)"
  skill_root="$tmp/skill"
  code_root="$tmp/code"
  routing="$skill_root/routing.yaml"
  mkdir -p "$skill_root/rules" "$skill_root/workflows" "$skill_root/gotchas" "$code_root/gotchas"

  printf '# Base\n' > "$skill_root/rules/base.md"
  printf '# Run\n' > "$skill_root/workflows/run.md"
  printf '# Code shared\n' > "$code_root/gotchas/shared.md"
  printf '# Skill collision\n' > "$skill_root/gotchas/shared.md"
  cat > "$routing" <<'YAML'
path_resolution:
  skill_root: {owns: [rules/**, workflows/**, gotchas/**]}
  code_root: {owns: [gotchas/**]}
always_read:
  - skill:rules/base.md
tasks:
  - id: fixture
    required_reads:
      - code:gotchas/shared.md
    workflow: skill:workflows/run.md
YAML

  if (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh" --namespace skill --routing "$routing") >/dev/null 2>&1; then
    echo "two-root audit failed to isolate a same-path skill:/code: collision" >&2
    rm -rf "$tmp"
    return 1
  fi
  if (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh" --namespace skill --routing "$routing") >/dev/null 2>&1; then
    echo "two-root route check failed to isolate a same-path skill:/code: collision" >&2
    rm -rf "$tmp"
    return 1
  fi

  rm "$skill_root/gotchas/shared.md"
  (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh" --namespace skill --routing "$routing")
  (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh" --namespace skill --routing "$routing")
  (cd "$code_root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh" --namespace code --routing "$routing")
  (cd "$code_root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh" --namespace code --routing "$routing")
  rm -rf "$tmp"
}

check_conformance_option_like_phrases() {
  local tmp script
  tmp="$(mktemp -d)"
  script="$ROOT/templates/skill/scripts/check-version-conformance.sh"
  printf '%s\n' '# Fixture' '--present' > "$tmp/fixture.md"

  cat > "$tmp/pass.yaml" <<'YAML'
required_sections:
  - file: fixture.md
    must_contain:
      - "--present"
YAML
  bash "$script" "$tmp" --conformance "$tmp/pass.yaml" >/dev/null

  cat > "$tmp/fail.yaml" <<'YAML'
required_sections:
  - file: fixture.md
    must_not_contain:
      - "--present"
YAML
  if bash "$script" "$tmp" --conformance "$tmp/fail.yaml" >/dev/null 2>&1; then
    echo "conformance must_not_contain accepted an option-like phrase that exists" >&2
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"
}

check_vendor_sync_guards() (
  set -euo pipefail
  local tmp up skill outside script manifest sha output status
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  up="$tmp/upstream"; skill="$tmp/skill"; outside="$tmp/outside"
  script="$ROOT/templates/skill/scripts/sync-vendor.sh"
  manifest="$up/templates/skill/sync-manifest.yaml"

  mkdir -p "$up/templates/skill/scripts" "$up/templates/skill/rules" "$skill" "$outside"
  printf '# fixture\n' > "$up/templates/skill/scripts/payload.sh"
  printf '# project-owned\n' > "$up/templates/skill/rules/project.md"
  printf '# fixture skill\n' > "$skill/SKILL.md"
  printf 'vendor:\n  - scripts/payload.sh\nproject_owned:\n  - rules/project.md\n' > "$manifest"
  git -C "$up" init -q
  git -C "$up" config user.email fixture@example.invalid
  git -C "$up" config user.name Fixture
  git -C "$up" add .
  git -C "$up" commit -qm fixture
  sha="$(git -C "$up" rev-parse HEAD)"
  printf 'upstream: fixture\nsynced_sha: %s\nsynced_date: 2026-07-22\n' "$sha" > "$skill/.upstream-sync"

  bash "$script" "$skill" --upstream "$up" --apply >/dev/null
  [[ -f "$skill/scripts/payload.sh" ]] || { echo "vendor block entry was not copied" >&2; return 1; }
  [[ ! -e "$skill/rules/project.md" ]] || { echo "parser consumed a non-vendor owner block" >&2; return 1; }

  expect_vendor_reject() {
    local label="$1"
    if output="$(bash "$script" "$skill" --upstream "$up" --apply 2>&1)"; then
      echo "vendor guard accepted $label" >&2
      return 1
    else
      status=$?
    fi
    [[ $status -eq 2 && "$output" == *"FAIL:"* ]] || {
      echo "vendor guard returned unexpected result for $label: status=$status" >&2
      printf '%s\n' "$output" >&2
      return 1
    }
  }

  printf 'vendor:\n  - rules/project.md\n' > "$manifest"
  expect_vendor_reject "project-owned path"
  [[ ! -e "$skill/rules/project.md" ]] || { echo "project-owned path was written" >&2; return 1; }

  printf 'vendor:\n  - /tmp/vendor-sync-absolute-escape\n' > "$manifest"
  expect_vendor_reject "absolute path"

  printf 'vendor:\n  - scripts/../escape.sh\n' > "$manifest"
  expect_vendor_reject "traversal path"
  [[ ! -e "$skill/escape.sh" ]] || { echo "traversal path escaped the owner directory" >&2; return 1; }

  rm -rf "$skill/scripts"
  ln -s "$outside" "$skill/scripts"
  printf 'vendor:\n  - scripts/payload.sh\n' > "$manifest"
  expect_vendor_reject "symlink target"
  [[ ! -e "$outside/payload.sh" ]] || { echo "symlink target escaped the skill root" >&2; return 1; }
)

check_overlay_owner_contract() (
  set -euo pipefail
  local tmp root skill script output
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  root="$tmp/workspace"
  skill="$root/skills/sample"
  script="$ROOT/templates/skill/scripts/sync-routing.sh"
  mkdir -p "$skill/rules" "$skill/workflows" "$skill/references/business" \
    "$root/services/billing/skills/billing/references/business"
  printf '# Base\n' > "$skill/rules/base.md"
  printf '# Run\n' > "$skill/workflows/run.md"
  printf '# Local billing consumer\n' > "$skill/references/business/billing-consumer.md"
  printf '# Billing owner\n' > "$root/services/billing/skills/billing/references/business/billing.md"
  cat > "$skill/SKILL.md" <<'MARKDOWN'
---
name: sample
description: sample overlay fixture
---
# Sample
<!-- ALWAYS_READ_START -->
<!-- ALWAYS_READ_END -->
<!-- ROUTING_SUMMARY_START -->
<!-- ROUTING_SUMMARY_END -->
MARKDOWN
  cat > "$skill/routing.yaml" <<'YAML'
owner_roots:
  billing: services/billing
always_read:
  - rules/base.md
domain_overlays:
  - id: billing
    labels: { en: Billing, zh: 计费 }
    required_reads:
      - references/business/billing-consumer.md
      - owner:billing:skills/billing/references/business/billing.md
    trigger_examples: [账单, billing policy]
tasks:
  - id: run
    labels: { en: Run, zh: 执行 }
    workflow: workflows/run.md
    trigger_examples: [执行任务, run task]
  - id: other
    labels: { en: Other, zh: 其他 }
    workflow: workflows/run.md
    trigger_examples: [其他任务]
YAML

  (cd "$root" && bash "$script" "$skill" --workspace-root "$root") >/dev/null
  grep -q 'Domain overlays are active' "$skill/SKILL.md"
  grep -q 'task_route_id.*domain_overlay_ids.*merged_required_reads' "$skill/SKILL.md"
  (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null
  output="$(cd "$root" && bash "$script" "$skill" --check)"
  [[ "$output" == *"cross-owner target verification remains open"* ]] || {
    echo "owner check without workspace root did not report unverified target existence" >&2
    return 1
  }
  output="$(bash "$ROOT/templates/skill/scripts/route-health.sh" "$skill")"
  [[ "$output" == *"1 task routes + 1 domain overlays"* ]] || {
    echo "route-health did not separate task routes from domain overlays" >&2
    return 1
  }

  rm "$root/services/billing/skills/billing/references/business/billing.md"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "owner target validation accepted a missing cross-owner file" >&2
    return 1
  fi
  printf '# Billing owner\n' > "$root/services/billing/skills/billing/references/business/billing.md"

  perl -0pi -e 's#billing: services/billing#billing: ../billing#' "$skill/routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "owner root validation accepted parent traversal" >&2
    return 1
  fi
  perl -0pi -e 's#billing: ../billing#billing: services/billing#' "$skill/routing.yaml"

  perl -0pi -e 's#owner:billing:#owner:undeclared:#' "$skill/routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "owner reference validation accepted an undeclared owner" >&2
    return 1
  fi
  perl -0pi -e 's#owner:undeclared:#owner:billing:#' "$skill/routing.yaml"

  perl -0pi -e 's/(    labels: \{ en: Billing[^\n]*\n)/$1    workflow: workflows\/run.md\n/' "$skill/routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "domain overlay validation accepted a workflow override" >&2
    return 1
  fi
)

check_recursive_knowledge_integrity() (
  set -euo pipefail
  local tmp root routing
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  root="$tmp/skill"
  routing="$root/routing.yaml"
  mkdir -p "$root/rules" "$root/workflows" "$root/references/business/deep"
  printf '# Base\n' > "$root/rules/base.md"
  printf '# Run\n' > "$root/workflows/run.md"
  printf '# Known\n' > "$root/references/business/known.md"
  printf '# Nested orphan\n' > "$root/references/business/deep/orphan.md"
  cat > "$routing" <<'YAML'
always_read:
  - rules/base.md
tasks:
  - id: run
    required_reads:
      - references/business/known.md
    workflow: workflows/run.md
YAML

  if (cd "$root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh") >/dev/null 2>&1; then
    echo "recursive orphan audit missed a nested business reference" >&2
    return 1
  fi
  if (cd "$root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh") >/dev/null 2>&1; then
    echo "recursive route reachability missed an unactivated nested business reference" >&2
    return 1
  fi

  printf '\nSee references/business/deep/orphan.md.\n' >> "$root/references/business/known.md"
  (cd "$root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh") >/dev/null
  (cd "$root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh") >/dev/null
)

if [[ "$MODE" == "staged" ]]; then
  run "upstream change-note guard (staged)" bash scripts/check-upstream-changes.sh --base "$BASE" --staged
  run "whitespace diff check (staged)" git diff --cached --check
else
  run "upstream change-note guard" bash scripts/check-upstream-changes.sh --base "$BASE"
  run "whitespace diff check" git diff --check
fi

run "upstream supersedes refs check" bash scripts/check-upstream-supersedes.sh

run "template routing manifest check" bash templates/skill/scripts/sync-routing.sh templates/skill --check
run "template SessionStart hook runtime contract" bash scripts/check-template-hooks.sh
run "temporary downstream scaffold smoke test" check_downstream_scaffold
run "single-root + two-root integrity contracts" check_two_root_integrity
run "conformance option-like phrase contract" check_conformance_option_like_phrases
run "vendor owner + path guards" check_vendor_sync_guards
run "task route + domain overlay and cross-owner guards" check_overlay_owner_contract
run "recursive business-reference integrity" check_recursive_knowledge_integrity
run "self-hosting shells + activation check" bash scripts/check-self-shells.sh
run "self-hosting scenario checks" bash scripts/check-self-scenarios.sh
run "self-hosting phase 7 smoke test" bash templates/skill/scripts/smoke-test.sh skill-based-architecture --phase 7
run "self-hosting orphan audit" bash templates/skill/scripts/audit-orphans.sh
run "template content conformance" bash templates/skill/scripts/check-version-conformance.sh templates/skill
run "self-hosting content conformance" bash templates/skill/scripts/check-version-conformance.sh . --conformance references/self-hosting-conformance.yaml

printf '\nAll upstream maintenance checks passed.\n'
