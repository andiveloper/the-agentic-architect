#!/usr/bin/env bash
#
# install.sh - install The Last Architect (arc42 ACC) skills + subagents into a
# coding-agent setup.
#
# Installs the build-architecture-communication-canvas toolkit (skills +
# subagents) into one or more coding agents:
#   --cursor   Cursor:      <base>/.cursor/{skills,agents}
#   --claude   Claude Code: <base>/.claude/{skills,agents}
#
# Scope (pick exactly one):
#   --target <dir>   project-scoped: into <dir>
#   --user           user-scoped:    into $HOME
#
# Runs from a local checkout, or directly from GitHub without a checkout:
#   curl -fsSL https://raw.githubusercontent.com/andiveloper/the-last-architect/main/install.sh | bash -s -- --cursor --user
#
# Usage:
#   ./install.sh --cursor --user
#   ./install.sh --claude --target /path/to/your/project
#   ./install.sh --cursor --claude --target /path/to/your/project
#   ./install.sh --help

set -euo pipefail

REPO_SLUG="andiveloper/the-last-architect"
REPO_BRANCH="main"
TOOLKIT="build-architecture-communication-canvas"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

usage() {
  cat <<'EOF'
install.sh - install The Last Architect (arc42 ACC) skills + subagents.

Installs the build-architecture-communication-canvas toolkit into one or more
coding agents. Choose at least one agent and exactly one scope.

Agents (one or more):
  --cursor                        Cursor:      <base>/.cursor/{skills,agents}
  --claude                        Claude Code: <base>/.claude/{skills,agents}

Scope (exactly one):
  --target <dir>                  project-scoped: into <dir>
  --user                          user-scoped:    into $HOME

Usage:
  ./install.sh --cursor --user
  ./install.sh --claude --target /path/to/your/project
  ./install.sh --cursor --claude --target /path/to/your/project
  ./install.sh --help

Run directly from GitHub without a checkout:
  curl -fsSL https://raw.githubusercontent.com/andiveloper/the-last-architect/main/install.sh | bash -s -- --cursor --user
EOF
  exit "${1:-0}"
}

DEST_BASE=""
MODE=""
WANT_CURSOR=0
WANT_CLAUDE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cursor)
      WANT_CURSOR=1
      shift
      ;;
    --claude)
      WANT_CLAUDE=1
      shift
      ;;
    --target)
      MODE="target"
      DEST_BASE="${2:-}"
      [[ -z "$DEST_BASE" ]] && { echo "error: --target requires a directory" >&2; usage 1; }
      shift 2
      ;;
    --user)
      MODE="user"
      DEST_BASE="$HOME"
      shift
      ;;
    -h|--help)
      usage 0
      ;;
    *)
      echo "error: unknown argument '$1'" >&2
      usage 1
      ;;
  esac
done

if [[ "$WANT_CURSOR" -eq 0 && "$WANT_CLAUDE" -eq 0 ]]; then
  echo "error: choose at least one agent: --cursor and/or --claude" >&2
  usage 1
fi

if [[ -z "$MODE" ]]; then
  echo "error: choose a scope: --target <dir> or --user" >&2
  usage 1
fi

if [[ "$MODE" == "target" && ! -d "$DEST_BASE" ]]; then
  echo "error: target directory does not exist: $DEST_BASE" >&2
  exit 1
fi

# Locate the toolkit source: prefer a local checkout next to this script,
# otherwise download the repo tarball from GitHub.
SRC=""
CLEANUP_DIR=""

cleanup() {
  if [[ -n "$CLEANUP_DIR" && -d "$CLEANUP_DIR" ]]; then
    rm -rf "$CLEANUP_DIR"
  fi
}
trap cleanup EXIT

if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/$TOOLKIT/skills" && -d "$SCRIPT_DIR/$TOOLKIT/agents" ]]; then
  SRC="$SCRIPT_DIR/$TOOLKIT"
else
  echo "Local toolkit not found next to script; downloading from GitHub ($REPO_SLUG@$REPO_BRANCH)..."
  CLEANUP_DIR="$(mktemp -d)"
  TARBALL_URL="https://github.com/$REPO_SLUG/archive/refs/heads/$REPO_BRANCH.tar.gz"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$TARBALL_URL" -o "$CLEANUP_DIR/repo.tar.gz"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$CLEANUP_DIR/repo.tar.gz" "$TARBALL_URL"
  else
    echo "error: need curl or wget to download from GitHub" >&2
    exit 1
  fi
  tar -xzf "$CLEANUP_DIR/repo.tar.gz" -C "$CLEANUP_DIR"
  SRC="$CLEANUP_DIR/the-last-architect-$REPO_BRANCH/$TOOLKIT"
fi

if [[ ! -d "$SRC/skills" || ! -d "$SRC/agents" ]]; then
  echo "error: cannot find toolkit skills/agents at $SRC" >&2
  exit 1
fi

copy_tree() {
  # copy_tree <src_dir> <dest_dir>
  local src="$1" dest="$2"
  mkdir -p "$dest"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$src/" "$dest/"
  else
    cp -R "$src/." "$dest/"
  fi
}

install_into() {
  # install_into <label> <config_dir>
  local label="$1" cfg="$2"
  local dest="$DEST_BASE/$cfg"
  echo "Installing The Last Architect ($label) into: $dest"
  copy_tree "$SRC/skills" "$dest/skills"
  copy_tree "$SRC/agents" "$dest/agents"
  echo "  Skills:    $dest/skills/ (build-architecture-communication-canvas, arc42-acc-canvas, repo-discovery, acc-gap-analysis)"
  echo "  Subagents: $dest/agents/ (9 acc-* category agents)"
}

[[ "$WANT_CURSOR" -eq 1 ]] && install_into "Cursor" ".cursor"
[[ "$WANT_CLAUDE" -eq 1 ]] && install_into "Claude Code" ".claude"

echo
echo "Done."
echo "Open a repository in your coding agent and run: /build-architecture-communication-canvas"
