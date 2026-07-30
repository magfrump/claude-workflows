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

# Directories are linked wholesale; CLAUDE.md is a single file.
#
# `scripts` is here only because hooks/log-usage.sh sources
# ../scripts/lib/skill-paths.sh relative to its own resolved path — without it
# that hook aborts on every Skill/Read/Agent call. Linking the dir keeps the
# relative source working from $SRC/hooks/.
ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)

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

# --- Settings wiring: hooks + permissions (decision 023) ---------------------
# Decision 022 shipped the hooks unwired, on the reasoning that hook wiring
# changes session behavior and should be a human opt-in rather than something an
# image rebuild switches on silently. 023 keeps the opt-in but moves it: the
# human's gate is now install.sh's diff-and-bless (hooks/wiring.json is part of
# the reviewed payload) rather than a hand-edit of settings.json in every
# per-project volume, which in practice meant the hooks were never on anywhere.
#
# settings.json is MERGED, not linked. It lives in the per-project volume and
# Claude Code writes to it at runtime (theme, effortLevel, ...); a symlink to the
# root-owned payload would make those writes fail. So this is a default, not a
# boundary — `node` can still edit the merged result, and it is restored on next
# start. Anything that must be enforced belongs in the image, not here.
#
# Set CC_SKIP_HOOK_WIRING=1 to leave settings.json alone entirely.
WIRING="$SRC/hooks/wiring.json"
SETTINGS="$DEST/settings.json"

if [ "${CC_SKIP_HOOK_WIRING:-}" = "1" ]; then
  echo "link-claude-home: CC_SKIP_HOOK_WIRING=1 — leaving $SETTINGS unwired."
elif [ ! -f "$WIRING" ]; then
  echo "link-claude-home: no $WIRING — hooks linked but not wired." >&2
elif ! command -v jq >/dev/null 2>&1; then
  echo "link-claude-home: jq not found — hooks linked but not wired." >&2
else
  [ -f "$SETTINGS" ] || printf '{}\n' > "$SETTINGS"

  # A settings.json the agent (or a crash) left unparseable must not be silently
  # replaced — that would discard real user settings. Bail loudly instead.
  if ! jq -e . "$SETTINGS" >/dev/null 2>&1; then
    echo "link-claude-home: $SETTINGS is not valid JSON — refusing to touch it." >&2
  else
    # Merge semantics, per event key (hooks) and per mode (permissions):
    #   (existing - ours) + ours
    # Array subtraction is deep equality, so re-running is exactly idempotent:
    # our entries are removed and re-appended, and everything we did not author
    # is preserved in place. `_comment` is dropped so documentation never lands
    # in settings.
    #
    # permissions.deny is merged for the same reason the hooks are, and it is
    # not optional decoration: guard-trusted-writes.py deliberately DEFERS on
    # its HARD tier for Edit/Write rather than returning "ask" (a hook "ask"
    # silently overrides deny — Claude Code issue #39344), so the deny rules
    # are what actually blocks that path. Wiring the hook alone left the HARD
    # tier a no-op for the file tools (decision 023 amendment B).
    tmp="$SETTINGS.link-tmp.$$"
    if jq --arg dir "$DEST" --slurpfile w "$WIRING" '
          ($w[0]
           | with_entries(select(.key | startswith("_") | not))
           | walk(if type == "string"
                  then gsub("\\{\\{CLAUDE_DIR\\}\\}"; $dir)
                  else . end)) as $wiring
          | .hooks //= {}
          | reduce (($wiring.hooks // {}) | keys_unsorted[]) as $ev (
              .;
              .hooks[$ev] = (((.hooks[$ev] // []) - $wiring.hooks[$ev]) + $wiring.hooks[$ev])
            )
          | .permissions //= {}
          | reduce (($wiring.permissions // {}) | keys_unsorted[]) as $mode (
              .;
              .permissions[$mode] =
                (((.permissions[$mode] // []) - $wiring.permissions[$mode])
                 + $wiring.permissions[$mode])
            )
        ' "$SETTINGS" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
      mv -f "$tmp" "$SETTINGS"
      echo "link-claude-home: wired $(jq -r '[.hooks[][]?.hooks[]?] | length' "$SETTINGS") hook command(s)" \
           "and $(jq -r '[.permissions[]?[]?] | length' "$SETTINGS") permission rule(s) into $SETTINGS"
    else
      rm -f "$tmp"
      echo "link-claude-home: hook merge failed — $SETTINGS left unchanged." >&2
    fi
  fi
fi
