#!/usr/bin/env bash
# Install a skill from SkillVault into Codex or Claude Code.
#
# Usage:
#   ./scripts/install.sh diagnose            # Auto-detect agent
#   ./scripts/install.sh diagnose --codex    # Force Codex
#   ./scripts/install.sh diagnose --claude   # Force Claude
#   ./scripts/install.sh diagnose tdd brainstorm  # Multiple skills
#
# The script downloads skills from GitHub and places them in the correct
# skills directory for the detected agent.

set -euo pipefail

REPO="Tsan1024/SkillVault"
REPO_URL="https://github.com/${REPO}.git"
BRANCH="dev"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
  sed -n '2,11p' "$0"
  exit 0
}

# --- Detect which agent is installed ---
detect_agent() {
  if [ -d "$HOME/.codex" ] && [ -d "$HOME/.claude" ]; then
    echo "codex"  # Default to Codex when both exist
  elif [ -d "$HOME/.codex" ]; then
    echo "codex"
  elif [ -d "$HOME/.claude" ]; then
    echo "claude"
  else
    echo ""
  fi
}

# --- Main ---
main() {
  local agent=""
  local skills=()

  # Parse args
  for arg in "$@"; do
    case "$arg" in
      --help|-h) usage ;;
      --codex)   agent="codex" ;;
      --claude)  agent="claude" ;;
      *)         skills+=("$arg") ;;
    esac
  done

  if [ ${#skills[@]} -eq 0 ]; then
    echo -e "${RED}Error: no skill names provided.${NC}"
    usage
  fi

  # Auto-detect if not specified
  if [ -z "$agent" ]; then
    agent=$(detect_agent)
    if [ -z "$agent" ]; then
      echo -e "${RED}Error: could not detect Codex or Claude Code.${NC}"
      echo "  Use --codex or --claude to specify."
      exit 1
    fi
  fi

  # Resolve target directory
  local target_dir
  case "$agent" in
    codex)  target_dir="$HOME/.codex/skills" ;;
    claude) target_dir="$HOME/.claude/skills" ;;
    *)      echo -e "${RED}Unknown agent: $agent${NC}"; exit 1 ;;
  esac

  mkdir -p "$target_dir"

  echo -e "${GREEN}Installing to ${target_dir}...${NC}\n"

  local tmpdir
  tmpdir=$(mktemp -d)
  trap "rm -rf $tmpdir" EXIT

  for skill in "${skills[@]}"; do
    local src="$tmpdir/skills/$skill"

    if [ -d "$src" ]; then
      # Already fetched in this batch
      :
    else
      # Sparse checkout just this skill directory
      git clone --depth 1 --filter=blob:none --sparse \
        --branch "$BRANCH" "$REPO_URL" "$tmpdir" 2>/dev/null
      git -C "$tmpdir" sparse-checkout set "skills/$skill" 2>/dev/null
    fi

    if [ ! -d "$src" ]; then
      echo -e "  ${RED}x${NC} $skill (not found)"
      continue
    fi

    rm -rf "$target_dir/$skill"
    cp -r "$src" "$target_dir/$skill"
    echo -e "  ${GREEN}+${NC} $skill"
  done

  echo -e "\n${GREEN}Done.${NC} Restart your agent to pick up new skills."
}

main "$@"
