#!/usr/bin/env bash
# SkillVault sync — check and pull updates from upstream skill repos.
#
# Usage:
#   ./scripts/sync.sh              Check for upstream updates (dry-run)
#   ./scripts/sync.sh --pull       Pull updates into skills/
#
# Requires: git, python3

set -euo pipefail
cd "$(dirname "$0")/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

SOURCES="sources.yaml"
TMPDIR="${TMPDIR:-/tmp}/skillvault-sync-$$"
MODE="${1:---check}"

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Parse sources.yaml into structured data
# ---------------------------------------------------------------------------
parse_sources() {
  python3 -c "
import yaml, sys, json
with open('$SOURCES') as f:
    data = yaml.safe_load(f)
print(json.dumps(data['sources'], indent=2))
" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Check a single upstream: compare local commit vs remote HEAD
# ---------------------------------------------------------------------------
check_repo() {
  local key="$1" repo="$2" local_commit="$3"
  local remote
  remote=$(git ls-remote "$repo" HEAD 2>/dev/null | awk '{print $1}')
  if [ -z "$remote" ]; then
    echo -e "  ${key}  ${RED}UNREACHABLE${NC}"
    return
  fi
  if [ "$remote" != "$local_commit" ]; then
    echo -e "  ${key}  ${RED}outdated${NC}  ${local_commit:0:10} → ${BOLD}${remote:0:10}${NC}"
  else
    echo -e "  ${key}  ${GREEN}up to date${NC}  ${local_commit:0:10}"
  fi
}

# ---------------------------------------------------------------------------
# Pull: clone upstream, copy changed skill dirs, update sources.yaml
# ---------------------------------------------------------------------------
pull_repo() {
  local key="$1" repo="$2" local_commit="$3" skill_paths="$4"
  local remote repo_name
  remote=$(git ls-remote "$repo" HEAD 2>/dev/null | awk '{print $1}')
  repo_name=$(echo "$repo" | sed 's|.*/||;s|\.git$||')

  if [ -z "$remote" ]; then
    echo -e "${RED}  Cannot reach $repo${NC}"
    return 1
  fi

  if [ "$remote" = "$local_commit" ]; then
    echo -e "  ${key}  ${GREEN}already current${NC}"
    return 0
  fi

  echo -e "\n${YELLOW}  Pulling ${key}...${NC}"
  git clone --depth 1 --quiet "$repo" "$TMPDIR/$repo_name" 2>/dev/null

  local updated=0
  while IFS='|' read -r name path; do
    [ -z "$name" ] && continue
    if [ -d "$TMPDIR/$repo_name/$path" ]; then
      rm -rf "skills/$name"
      cp -r "$TMPDIR/$repo_name/$path" "skills/$name"
      echo "    ${GREEN}+${NC} $name"
      updated=$((updated + 1))
    else
      echo "    ${RED}?${NC} $name (path not found: $path)"
    fi
  done <<< "$skill_paths"

  echo "  Updated $updated skills, $(echo "$skill_paths" | wc -l | tr -d ' ') total"

  # Update commit hash in sources.yaml
  python3 -c "
import yaml
with open('$SOURCES') as f:
    data = yaml.safe_load(f)
data['sources']['$key']['commit'] = '$remote'
data['sources']['$key']['synced'] = '$(date +%Y-%m-%d)'
with open('$SOURCES', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
"
  echo "  Updated sources.yaml (commit: ${remote:0:10})"
}

# ---------------------------------------------------------------------------
# Build pipe-delimited name|path list from a YAML skills section
# ---------------------------------------------------------------------------
extract_skill_paths() {
  local key="$1"
  python3 -c "
import yaml, sys
with open('$SOURCES') as f:
    data = yaml.safe_load(f)
src = data['sources']['$key']
if src.get('type') == 'submodule':
    sys.exit(0)
for s in src.get('skills', []):
    print(f\"{s['name']}|{s['path']}\")
"
}

# ---------------------------------------------------------------------------
main
# ---------------------------------------------------------------------------
main() {
  mkdir -p "$TMPDIR"

  # Parse sources
  local sources_json
  sources_json=$(parse_sources)
  if [ -z "$sources_json" ]; then
    echo -e "${RED}Error: cannot parse sources.yaml (is PyYAML installed?)${NC}"
    exit 1
  fi

  # Extract values with python3
  mc=$(echo "$sources_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['mattpocock/skills']['commit'])")
  oc=$(echo "$sources_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['obra/superpowers']['commit'])")
  lc=$(echo "$sources_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['larksuite/cli']['commit'])")

  echo -e "${BOLD}SkillVault Sync${NC}\n"

  # --- Check phase (always runs) ---
  echo -e "${BOLD}Upstream status:${NC}\n"
  check_repo "mattpocock/skills " "https://github.com/mattpocock/skills" "$mc"
  check_repo "obra/superpowers  " "https://github.com/obra/superpowers"   "$oc"
  check_repo "larksuite/cli     " "https://github.com/larksuite/cli"      "$lc"

  # Submodule hint
  echo -e "\n  ${YELLOW}larksuite/cli${NC} is a submodule — update with:"
  echo "    git submodule update --remote vendors/larksuite-cli"

  # --- Pull phase ---
  if [ "$MODE" = "--pull" ]; then
    echo -e "\n${BOLD}Pulling updates...${NC}"

    pull_repo "mattpocock/skills" "https://github.com/mattpocock/skills" "$mc" \
      "$(extract_skill_paths "mattpocock/skills")"

    pull_repo "obra/superpowers" "https://github.com/obra/superpowers" "$oc" \
      "$(extract_skill_paths "obra/superpowers")"

    echo -e "\n${GREEN}Done.${NC} Review: git diff skills/"
  fi
}

main
