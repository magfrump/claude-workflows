#!/usr/bin/env bash
# install.sh — copy the canonical devcontainer config from this repo to the host
# config dir the launcher actually reads, then bless it (decision 016).
#
# Run from the HOST:  ./devcontainer-config/install.sh
#
# WHY A COPY RATHER THAN A SYMLINK INTO THE REPO. This directory is inside a repo
# that agent sessions bind-mount read-write — an agent CAN edit these files. That is
# fine, and deliberate: edits here are inert. Only the INSTALLED copy at
# ~/.config/claude-devcontainer/ is ever read by the launcher, it is in no bind
# mount, and getting an edit from here to there requires a human running this script
# and approving the diff below. Symlinking would hand the agent the boundary.
#
# So: read the diff. It is the rebuild gate.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"
BIN_DIR="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"
ASSUME_YES="${1:-}"

# install.sh itself is not installed — it runs from the repo.
# `claude-home` is assembled below from the repo root before the diff is shown.
PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-isolated.sh link-claude-home.sh egress claude-home)

REPO_ROOT="$(cd "$SRC/.." && pwd)"

# --- Assemble the claude-home payload (decision 022) -------------------------
# The skills/workflows/guides/patterns/hooks and the global CLAUDE.md are baked
# into the image so that EVERY cc-isolated session gets this repo's process, not
# just sessions that happen to be editing this repo. They are staged here, into
# the build context, because the Dockerfile's context is the config dir.
#
# Assembled fresh on every install so the staged copy can never silently drift
# from the repo — and, being inside $SRC, it shows up in the diff below, which
# is the human's review gate. Do not hand-edit devcontainer-config/claude-home.
CLAUDE_HOME_SRC=(CLAUDE.md skills workflows guides patterns hooks)
STAGE="$SRC/claude-home"
rm -rf "$STAGE"
mkdir -p "$STAGE"
for item in "${CLAUDE_HOME_SRC[@]}"; do
  if [ -e "$REPO_ROOT/$item" ]; then
    cp -r "$REPO_ROOT/$item" "$STAGE/$item"
  else
    echo "WARNING: $REPO_ROOT/$item not found — omitted from the image payload." >&2
  fi
done
# Provenance stamp: lets a session (and health-check) tell which commit's process
# it is running, and detect that the image predates the repo it is editing.
{
  echo "commit=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "dirty=$(test -n "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)" && echo yes || echo no)"
  echo "assembled_from=$REPO_ROOT"
} > "$STAGE/.manifest"

echo "Canonical (repo):  $SRC"
echo "Installed (host):  $DEST"
echo

if [ -d "$DEST" ]; then
  echo "=== Changes this install would make ==========================================="
  changed=0
  for item in "${PAYLOAD[@]}"; do
    if ! diff -ru "$DEST/$item" "$SRC/$item" 2>/dev/null; then
      changed=1
    fi
  done
  if [ "$changed" -eq 0 ]; then
    echo "(none — installed config already matches the repo)"
  fi
  echo "==============================================================================="
  echo
else
  echo "First install — $DEST does not exist yet."
  echo
fi

if [ "$ASSUME_YES" != "--yes" ]; then
  printf 'Install this config and bless it? [y/N] '
  read -r reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Aborted. Nothing was changed."; exit 1 ;;
  esac
fi

mkdir -p "$DEST" "$BIN_DIR"

# projects/ holds per-project egress registrations and is host-owned state — it is
# NOT part of the canonical repo payload, so never clobber it.
mkdir -p "$DEST/projects"

for item in "${PAYLOAD[@]}"; do
  rm -rf "${DEST:?}/$item"
  cp -r "$SRC/$item" "$DEST/$item"
done

chmod +x "$DEST/cc-isolated.sh" "$DEST/init-firewall.sh"

ln -sf "$DEST/cc-isolated.sh" "$BIN_DIR/cc-isolated"
echo "Linked $BIN_DIR/cc-isolated -> $DEST/cc-isolated.sh"
echo

CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless

echo
echo "Done. Next steps:"
echo "  touch ~/.ssh/canary                    # once, if you haven't — strengthens the H1 probe"
echo "  cc-isolated                            # session for the repo containing \$PWD"
echo "  cc-isolated --register <repo> --profile python   # widen a project's egress"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo; echo "WARNING: $BIN_DIR is not on your PATH — add it, or call $DEST/cc-isolated.sh directly." ;;
esac
