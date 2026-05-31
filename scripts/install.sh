#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${LAMMUON_AGENT_REPO:-https://github.com/nShieldSolo/AgentTeam}"
BRANCH="${LAMMUON_AGENT_BRANCH:-main}"
MODE="project"
TARGET_DIR="$PWD"
UPDATE_REQUESTED=0
INSTALLED=0
UPDATED=0
UNCHANGED=0
BACKED_UP=0

usage() {
  cat <<'EOF'
Install lammuon Cursor agents/rules into a project.

Usage:
  scripts/install.sh [target-project-dir]
  scripts/install.sh --project [target-project-dir]
  scripts/install.sh --update [target-project-dir]
  scripts/install.sh --global cursor
  scripts/install.sh --global codex
  scripts/install.sh --global all

Examples:
  scripts/install.sh
  scripts/install.sh /path/to/project
  scripts/install.sh --update
  scripts/install.sh --global cursor
  scripts/install.sh --global codex
  scripts/install.sh --global all

From GitHub:
  curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash -s -- /path/to/project
  curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash -s -- --global cursor
  curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash -s -- --global codex
  curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash -s -- --global all

Environment:
  LAMMUON_AGENT_BRANCH=main
  LAMMUON_AGENT_REPO=https://github.com/nShieldSolo/AgentTeam
  CODEX_HOME=$HOME/.codex
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --project)
      MODE="project"
      TARGET_DIR="${2:-$PWD}"
      [[ $# -ge 2 ]] && shift
      ;;
    --update)
      UPDATE_REQUESTED=1
      if [[ "${2:-}" != "" && "${2:-}" != --* ]]; then
        TARGET_DIR="$2"
        shift
      fi
      ;;
    --global)
      MODE="${2:-}"
      if [[ "$MODE" != "cursor" && "$MODE" != "codex" && "$MODE" != "all" ]]; then
        echo "--global must be one of: cursor, codex, all" >&2
        exit 1
      fi
      shift
      ;;
    --cursor-global)
      MODE="cursor"
      ;;
    --codex-global)
      MODE="codex"
      ;;
    --all-global)
      MODE="all"
      ;;
    --*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      TARGET_DIR="$1"
      ;;
  esac
  shift
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

reset_stats() {
  INSTALLED=0
  UPDATED=0
  UNCHANGED=0
  BACKED_UP=0
}

sync_file() {
  local source="$1"
  local dest="$2"
  local stamp="$3"

  if [[ -e "$dest" ]]; then
    if cmp -s "$source" "$dest"; then
      UNCHANGED=$((UNCHANGED + 1))
      return 0
    fi
    cp "$dest" "$dest.bak.$stamp"
    BACKED_UP=$((BACKED_UP + 1))
    cp "$source" "$dest"
    UPDATED=$((UPDATED + 1))
    return 0
  fi

  cp "$source" "$dest"
  INSTALLED=$((INSTALLED + 1))
}

source_revision() {
  local source_dir="$1"
  local rev

  if command -v git >/dev/null 2>&1; then
    if git -C "$source_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      rev="$(git -C "$source_dir" rev-parse HEAD 2>/dev/null || true)"
      if [[ -n "$rev" ]]; then
        if ! git -C "$source_dir" diff --quiet -- . 2>/dev/null || ! git -C "$source_dir" diff --cached --quiet -- . 2>/dev/null; then
          rev="$rev-dirty"
        fi
        printf '%s\n' "$rev"
        return 0
      fi
    fi

    rev="$(git ls-remote "$REPO_URL" "refs/heads/$BRANCH" 2>/dev/null | awk '{print $1}' | head -n 1 || true)"
    if [[ -n "$rev" ]]; then
      printf '%s\n' "$rev"
      return 0
    fi
  fi

  printf 'unknown\n'
}

write_state() {
  local state_file="$1"
  local source_dir="$2"
  local scope="$3"
  local revision installed_at

  revision="$(source_revision "$source_dir")"
  installed_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  mkdir -p "$(dirname "$state_file")"
  {
    printf 'scope=%s\n' "$scope"
    printf 'repo_url=%s\n' "$REPO_URL"
    printf 'branch=%s\n' "$BRANCH"
    printf 'revision=%s\n' "$revision"
    printf 'installed_at=%s\n' "$installed_at"
  } > "$state_file"
}

print_summary() {
  local label="$1"
  local location="$2"
  local state_file="$3"
  local total
  total=$((INSTALLED + UPDATED + UNCHANGED))

  echo "$label: $location"
  echo "Files: $total total, $INSTALLED new, $UPDATED updated, $UNCHANGED unchanged, $BACKED_UP backed up"
  echo "State: $state_file"
}

copy_lammuon_files() {
  local source_dir="$1"
  local target_dir="$2"
  local stamp state_file
  stamp="$(date +%Y%m%d%H%M%S)"
  state_file="$target_dir/.cursor/lammuon-agent.state"
  reset_stats

  mkdir -p "$target_dir/.cursor/agents" "$target_dir/.cursor/rules"

  local file dest
  for file in "$source_dir"/.cursor/agents/lammuon-*.md; do
    [[ -e "$file" ]] || continue
    dest="$target_dir/.cursor/agents/$(basename "$file")"
    sync_file "$file" "$dest" "$stamp"
  done

  for file in "$source_dir"/.cursor/rules/lammuon-*.mdc; do
    [[ -e "$file" ]] || continue
    dest="$target_dir/.cursor/rules/$(basename "$file")"
    sync_file "$file" "$dest" "$stamp"
  done

  if [[ $((INSTALLED + UPDATED + UNCHANGED)) -eq 0 ]]; then
    echo "No lammuon agent/rule files found in source: $source_dir" >&2
    exit 1
  fi

  write_state "$state_file" "$source_dir" "project"
  print_summary "Synced lammuon project files" "$target_dir/.cursor" "$state_file"
  echo "Restart Cursor or reload the window if the agents/rules do not appear immediately."
}

copy_cursor_global_agents() {
  local source_dir="$1"
  local target_dir="${HOME}/.cursor/agents"
  local stamp state_file
  stamp="$(date +%Y%m%d%H%M%S)"
  state_file="$target_dir/.lammuon-agent.state"
  reset_stats

  mkdir -p "$target_dir"

  local file dest
  for file in "$source_dir"/.cursor/agents/lammuon-*.md; do
    [[ -e "$file" ]] || continue
    dest="$target_dir/$(basename "$file")"
    sync_file "$file" "$dest" "$stamp"
  done

  if [[ $((INSTALLED + UPDATED + UNCHANGED)) -eq 0 ]]; then
    echo "No lammuon Cursor agents found in source: $source_dir" >&2
    exit 1
  fi

  write_state "$state_file" "$source_dir" "cursor-global"
  print_summary "Synced Cursor global agents" "$target_dir" "$state_file"
  echo ""
  echo "WARNING: Cursor global install only syncs agents (~/.cursor/agents)."
  echo "         It does NOT install .cursor/rules (lammuon-preflight, lammuon-router, ...)."
  echo "         For Router / Test Case / Build gates in a repo, run project install in that repo:"
  echo "         curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash"
}

copy_codex_global_skill() {
  local source_dir="$1"
  local codex_home="${CODEX_HOME:-$HOME/.codex}"
  local skill_src="$source_dir/codex/skills/lammuon-team"
  local skill_dest="$codex_home/skills/lammuon-team"
  local stamp state_file
  stamp="$(date +%Y%m%d%H%M%S)"
  state_file="$skill_dest/.lammuon-agent.state"
  reset_stats

  if [[ ! -f "$skill_src/SKILL.md" ]]; then
    echo "Codex skill source not found: $skill_src/SKILL.md" >&2
    exit 1
  fi

  mkdir -p "$skill_dest/references/.cursor/agents" "$skill_dest/references/.cursor/rules"

  sync_file "$skill_src/SKILL.md" "$skill_dest/SKILL.md" "$stamp"

  local file dest
  for file in "$source_dir"/.cursor/agents/lammuon-*.md; do
    [[ -e "$file" ]] || continue
    dest="$skill_dest/references/.cursor/agents/$(basename "$file")"
    sync_file "$file" "$dest" "$stamp"
  done

  for file in "$source_dir"/.cursor/rules/lammuon-*.mdc; do
    [[ -e "$file" ]] || continue
    dest="$skill_dest/references/.cursor/rules/$(basename "$file")"
    sync_file "$file" "$dest" "$stamp"
  done

  write_state "$state_file" "$source_dir" "codex-global"
  print_summary "Synced Codex global skill" "$skill_dest" "$state_file"
  echo "Restart Codex if the skill is not listed immediately."
}

install_mode() {
  local source_dir="$1"
  case "$MODE" in
    project)
      copy_lammuon_files "$source_dir" "$TARGET_DIR"
      ;;
    cursor)
      copy_cursor_global_agents "$source_dir"
      ;;
    codex)
      copy_codex_global_skill "$source_dir"
      ;;
    all)
      copy_cursor_global_agents "$source_dir"
      copy_codex_global_skill "$source_dir"
      ;;
    *)
      echo "Unsupported mode: $MODE" >&2
      exit 1
      ;;
  esac
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
LOCAL_SOURCE=""

if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/../.cursor" ]]; then
  LOCAL_SOURCE="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

if [[ -n "$LOCAL_SOURCE" ]]; then
  install_mode "$LOCAL_SOURCE"
  exit 0
fi

require_cmd curl
require_cmd tar

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

ARCHIVE_URL="${REPO_URL}/archive/refs/heads/${BRANCH}.tar.gz"
echo "Downloading $ARCHIVE_URL"
curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$TMP_DIR"

SOURCE_DIR="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR/.cursor" ]]; then
  echo "Downloaded archive does not contain .cursor. Check repo/branch." >&2
  exit 1
fi

install_mode "$SOURCE_DIR"
