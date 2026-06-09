#!/usr/bin/env bash
#
# install.sh - install The Agentic Architect skills + subagents into a
# coding-agent setup.
#
# Installs all The Agentic Architect toolkits (skills + subagents) into one or
# more coding agents:
#   --cursor   Cursor:      <base>/.cursor/{skills,agents}
#   --claude   Claude Code: <base>/.claude/{skills,agents}
#
# Toolkits installed:
#   - build-architecture-communication-canvas (arc42 ACC)
#   - discover-ubiquitous-language (DDD ubiquitous language discovery)
#   - define-bounded-contexts (DDD bounded contexts + context map)
#   - analyze-commits (git-history diagnostics)
#
# Scope (pick exactly one):
#   --target <dir>   project-scoped: into <dir>
#   --user           user-scoped:    into $HOME
#
# Runs from a local checkout, or directly from GitHub without a checkout:
#   curl -fsSL https://raw.githubusercontent.com/andiveloper/the-agentic-architect/main/install.sh | bash -s -- --cursor --user
#
# Usage:
#   ./install.sh --cursor --user
#   ./install.sh --claude --target /path/to/your/project
#   ./install.sh --cursor --claude --target /path/to/your/project
#   ./install.sh --help

set -euo pipefail

REPO_SLUG="andiveloper/the-agentic-architect"
REPO_BRANCH="main"
TOOLKITS=("build-architecture-communication-canvas" "discover-ubiquitous-language" "define-bounded-contexts" "analyze-commits")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

usage() {
  cat <<'EOF'
install.sh - install The Agentic Architect skills + subagents.

Installs all The Agentic Architect toolkits (build-architecture-communication-canvas,
discover-ubiquitous-language, define-bounded-contexts and analyze-commits) into one or
more coding agents. Choose at least one agent and exactly one scope.

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

# Locate the toolkit source base (the directory containing the toolkit
# folders): prefer a local checkout next to this script, otherwise download
# the repo tarball from GitHub.
SRC_BASE=""
CLEANUP_DIR=""

cleanup() {
  if [[ -n "$CLEANUP_DIR" && -d "$CLEANUP_DIR" ]]; then
    rm -rf "$CLEANUP_DIR"
  fi
}
trap cleanup EXIT

# True only if every toolkit's skills/agents exist under the given base dir.
toolkits_present() {
  local base="$1" tk
  [[ -z "$base" ]] && return 1
  for tk in "${TOOLKITS[@]}"; do
    [[ -d "$base/$tk/skills" && -d "$base/$tk/agents" ]] || return 1
  done
  return 0
}

if toolkits_present "$SCRIPT_DIR"; then
  SRC_BASE="$SCRIPT_DIR"
else
  echo "Local toolkits not found next to script; downloading from GitHub ($REPO_SLUG@$REPO_BRANCH)..."
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
  SRC_BASE="$CLEANUP_DIR/the-agentic-architect-$REPO_BRANCH"
fi

if ! toolkits_present "$SRC_BASE"; then
  echo "error: cannot find all toolkit skills/agents under $SRC_BASE" >&2
  echo "       expected: ${TOOLKITS[*]}" >&2
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
  local label="$1" cfg="$2" tk
  local dest="$DEST_BASE/$cfg"
  echo "Installing The Agentic Architect ($label) into: $dest"
  for tk in "${TOOLKITS[@]}"; do
    copy_tree "$SRC_BASE/$tk/skills" "$dest/skills"
    copy_tree "$SRC_BASE/$tk/agents" "$dest/agents"
  done
  echo "  Skills:    $dest/skills/"
  echo "    - build-architecture-communication-canvas, arc42-acc-canvas, acc-canvas-png, repo-discovery, acc-gap-analysis"
  echo "    - discover-ubiquitous-language, ddd-ubiquitous-language"
  echo "    - define-bounded-contexts, ddd-bounded-contexts"
  echo "    - analyze-commits, git-history-diagnostics"
  echo "  Subagents: $dest/agents/"
  echo "    - 9 acc-* category agents + acc-canvas-drawio (source of truth, default) + acc-canvas-markdown + acc-canvas-html renderers"
  echo "    - ul-domain-extractor"
  echo "    - bc-context-analyzer + bc-canvas-drawio-renderer (source of truth, default) + bc-canvas-markdown-renderer + bc-canvas-html-renderer"
  echo "    - 5 commit-* diagnostic agents (churn, contributors, bug-cluster, velocity, firefighting)"
}

[[ "$WANT_CURSOR" -eq 1 ]] && install_into "Cursor" ".cursor"
[[ "$WANT_CLAUDE" -eq 1 ]] && install_into "Claude Code" ".claude"

echo
echo "Done."
echo
echo "Available tools (listed in the recommended run order):"
echo "  Command                                    What it does"
echo "  -----------------------------------------  --------------------------------------------------------------"
echo "  /analyze-commits                           Diagnose a repo from its git history (churn, bus factor, bug"
echo "                                             clusters, velocity, firefighting) (-> docs/commit-analysis.md)"
echo "  /build-architecture-communication-canvas   Fill the arc42 Architecture Communication Canvas for a repo"
echo "                                             (-> docs/architecture-communication-canvas.md)"
echo "  /discover-ubiquitous-language              Discover the domain ubiquitous language from existing code for"
echo "                                             review with domain experts (-> docs/ubiquitous-language.md)"
echo "  /define-bounded-contexts                   Identify DDD bounded contexts and render a Bounded Context Canvas"
echo "                                             draw.io per context, plus a draw.io context map (-> docs/bounded-contexts/"
echo "                                             <context>.drawio + context-map.drawio; md/html/png optional)"
echo
echo "Tools stand alone but compose; for a fresh or inherited repo, run them top-to-bottom."
echo "Open a repository in your coding agent and run one of the commands above."
