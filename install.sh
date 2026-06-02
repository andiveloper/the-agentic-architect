#!/usr/bin/env bash
#
# install.sh - install The Last Architect (arc42 ACC) skills + subagents into a Cursor setup.
#
# Copies .cursor/skills/ and .cursor/agents/ from this repo into a destination:
#   --target <dir>   project-scoped: <dir>/.cursor/{skills,agents}
#   --user           user-scoped:    ~/.cursor/{skills,agents}
#
# Usage:
#   ./install.sh --target /path/to/your/project
#   ./install.sh --user
#   ./install.sh --help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/.cursor"

usage() {
  cat <<'EOF'
install.sh - install The Last Architect (arc42 ACC) skills + subagents into a Cursor setup.

Copies .cursor/skills/ and .cursor/agents/ from this repo into a destination.

Usage:
  ./install.sh --target /path/to/your/project   # project-scoped: <dir>/.cursor/{skills,agents}
  ./install.sh --user                           # user-scoped:    ~/.cursor/{skills,agents}
  ./install.sh --help
EOF
  exit "${1:-0}"
}

DEST_BASE=""
MODE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
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

if [[ -z "$MODE" ]]; then
  echo "error: choose --target <dir> or --user" >&2
  usage 1
fi

if [[ ! -d "$SRC/skills" || ! -d "$SRC/agents" ]]; then
  echo "error: cannot find .cursor/skills or .cursor/agents next to this script ($SRC)" >&2
  exit 1
fi

if [[ "$MODE" == "target" && ! -d "$DEST_BASE" ]]; then
  echo "error: target directory does not exist: $DEST_BASE" >&2
  exit 1
fi

DEST="$DEST_BASE/.cursor"
mkdir -p "$DEST/skills" "$DEST/agents"

copy_tree() {
  # copy_tree <src_subdir> <dest_subdir>
  local src="$SRC/$1" dest="$DEST/$2"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$src/" "$dest/"
  else
    cp -R "$src/." "$dest/"
  fi
}

echo "Installing The Last Architect (arc42 ACC) into: $DEST"
copy_tree skills skills
copy_tree agents agents

echo "Done."
echo "  Skills:   $DEST/skills/ (build-architecture-communication-canvas, arc42-acc-canvas, repo-discovery, acc-gap-analysis)"
echo "  Subagents:$DEST/agents/ (9 acc-* category agents)"
echo
echo "Open a repository in Cursor and run: /build-architecture-communication-canvas"
