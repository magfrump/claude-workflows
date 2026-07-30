#!/usr/bin/env bash
# link-claude-home.sh — expose the baked claude-workflows payload inside the
# per-project ~/.claude volume (decision 022).
#
# THE PROBLEM THIS SOLVES. /home/node/.claude is a per-project Docker *volume*
# (decision 016 H6: one volume per project so a compromised session can't read
# another project's credentials). A fresh volume is empty, and nothing ever put
# the repo's skills, workflows, guides, patterns, or global CLAUDE.md into it.
# So every cc-isolated session ran with NONE of this repo's process available:
# no decision tree, no code-review orchestrator, no critic skills. The skills
# only ever worked in sessions that happened to be editing claude-workflows
# itself, and even there only because `code-review` reads skill files by path
# from $PWD rather than through skill registration.
#
# THE FIX. The payload is baked into the image at /opt/claude-workflows (root
# owned, mode 0555) and symlinked into the volume here, at every container
# start. Symlinks rather than copies so a rebuilt image is picked up without
# stale-volume surgery.
#
# WHY THE PAYLOAD IS ROOT-OWNED AND READ-ONLY. `node` (the agent) cannot edit
# /opt/claude-workflows. Getting a change from the claude-workflows repo into
# a running session therefore requires a human on the host: edit the repo, run
# install.sh, read the diff, bless, rebuild. This is the same boundary the
# devcontainer config itself uses, and it is deliberately stronger than the old
# (nonexistent) behavior: a writable ~/.claude/skills would let a session
# rewrite the critics that review it — the same class of problem as Gate 1h
# loading its review skill from the branch under review.
#
# IDEMPOTENT, and never clobbers real files: if a volume already has a genuine
# (non-symlink) entry at one of these names, we leave it alone and warn. Only
# our own symlinks are refreshed.

set -euo pipefail

SRC="${CC_WORKFLOWS_DIR:-/opt/claude-workflows}"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

[ -d "$SRC" ] || { echo "link-claude-home: no payload at $SRC — skipping." >&2; exit 0; }
mkdir -p "$DEST"

# Directories are linked wholesale; CLAUDE.md is a single file. `hooks` is
# linked so the scripts are present and referenceable, but is deliberately NOT
# wired into settings.json — hook wiring changes session behavior (including
# PreToolUse guards that can block calls) and is a human opt-in, not something
# an image rebuild should switch on silently. See decision 022.
ENTRIES=(skills workflows guides patterns hooks CLAUDE.md)

linked=0 skipped=0
for name in "${ENTRIES[@]}"; do
  [ -e "$SRC/$name" ] || continue
  target="$DEST/$name"
  if [ -L "$target" ]; then
    ln -sfn "$SRC/$name" "$target"        # refresh (image may have moved)
    linked=$((linked + 1))
  elif [ -e "$target" ]; then
    echo "link-claude-home: $target exists and is not a symlink — leaving it alone." >&2
    skipped=$((skipped + 1))
  else
    ln -sfn "$SRC/$name" "$target"
    linked=$((linked + 1))
  fi
done

# Stamp what the image shipped so a session can tell whether its process is
# current, and so `--probe`/health-check can surface staleness.
if [ -f "$SRC/.manifest" ]; then
  cp -f "$SRC/.manifest" "$DEST/.claude-workflows-manifest" 2>/dev/null || true
fi

echo "link-claude-home: linked $linked entr$([ "$linked" -eq 1 ] && echo y || echo ies) from $SRC${skipped:+, skipped $skipped}"
