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

usage() {
  cat <<'EOF'
Usage: devcontainer-config/install.sh [--yes]

Installs the devcontainer config into ~/.config/claude-devcontainer (or
$CLAUDE_DEVC_CONFIG_DIR) after showing a review diff and asking y/N, then
blesses it.

  --yes       answer y without asking
  -h, --help  show this help

Exit status: 0 installed; 1 declined, or an error; 2 bad arguments.
EOF
}

ASSUME_YES=""
while [ $# -gt 0 ]; do
  case "$1" in
    --yes) ASSUME_YES="--yes" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install.sh: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"
BIN_DIR="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"

# install.sh itself is not installed — it runs from the repo.
# `claude-home` is assembled below from the repo root before the diff is shown.
PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh link-claude-home.sh egress claude-home)

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
#
# `scripts` is staged for two reasons: hooks/log-usage.sh sources
# ../scripts/lib/skill-paths.sh relative to its own path, so a payload with
# hooks but no scripts leaves that hook dead on arrival (decision 023); and
# workflows call ~/.claude/scripts/lite-review.py and questions.sh by their
# installed path (Q-025).
# The global instructions file is sourced from global-instructions/ rather than
# the repo root: at the root, a session working in THIS repo loads it twice —
# once as the linked ~/.claude copy and once as the project's own instructions
# (prompt audit 2026-09-11, F1). Entries are staged under their basename, so
# the payload layout (and link-claude-home.sh) is unchanged.
CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)

# assemble <stage-dir>: stage every CLAUDE_HOME_SRC entry under its basename and
# write the .manifest provenance stamp. Exits the script on a missing source.
assemble() {
  local stage="$1" item
  rm -rf "$stage"
  mkdir -p "$stage"
  # None of the seven entries is optional, and a missing one is silent-and-total:
  # the image ships without that part of the process and no session notices. So
  # this is fatal, not a warning — a warning here scrolls off above the payload
  # diff and the [y/N] prompt, which is where the human is actually looking.
  # All misses are collected before exiting so a reorganization is reported once
  # rather than one rerun per renamed path.
  local missing=()
  for item in "${CLAUDE_HOME_SRC[@]}"; do
    if [ -e "$REPO_ROOT/$item" ]; then
      cp -r "$REPO_ROOT/$item" "$stage/$(basename "$item")"
    else
      missing+=("$item")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "ERROR: payload source(s) not found under $REPO_ROOT: ${missing[*]}" >&2
    echo "       The image payload would be incomplete. Fix the path, or edit" >&2
    echo "       CLAUDE_HOME_SRC in this script. Nothing was installed." >&2
    exit 1
  fi
  # Provenance stamp: lets a session (and health-check) tell which commit's process
  # it is running, and detect that the image predates the repo it is editing.
  {
    echo "commit=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "dirty=$(test -n "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)" && echo yes || echo no)"
    echo "assembled_from=$REPO_ROOT"
  } > "$stage/.manifest"
}

# review_diff <dest> <src> <item...>: print `diff -ruN` of each item. Returns 0
# when nothing differs and 1 when something does; exits the script when a diff
# could not be produced.
review_diff() {
  local dest="$1" src="$2" item rc changed=0
  shift 2
  for item in "$@"; do
    # -N (treat an absent file as empty) is what makes NEW content visible: without
    # it, a new file inside a payload dir showed only as "Only in src/egress: x.txt"
    # and a new top-level item printed nothing at all (the error went to the
    # swallowed stderr), so the human approved content they never saw. stderr is
    # not discarded, and exit status >1 ("trouble") aborts rather than counting as
    # a change: this diff is the review gate, so a diff that could not be shown
    # must never reach the [y/N] prompt.
    rc=0
    diff -ruN "$dest/$item" "$src/$item" || rc=$?
    case "$rc" in
      0) ;;
      1) changed=1 ;;
      *) echo "ERROR: could not diff payload item '$item' (diff exit $rc)." >&2
         echo "       The review diff is incomplete, so nothing was installed." >&2
         exit 1 ;;
    esac
  done
  return "$changed"
}

# confirm <question>: true on y/yes. `|| reply=""` so a closed/EOF stdin (piped
# or non-tty run) reads as "no" instead of dying on `read`'s non-zero exit under
# `set -e`, which killed the script before it could say why.
confirm() {
  local reply
  printf '%s [y/N] ' "$1"
  read -r reply || reply=""
  case "$reply" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

# --- Target: the devcontainer config (decision 016) ---------------------------
install_devcontainer() {
  assemble "$SRC/claude-home"

  echo "Canonical (repo):  $SRC"
  echo "Installed (host):  $DEST"
  echo

  if [ -d "$DEST" ]; then
    echo "=== Changes this install would make ==========================================="
    if review_diff "$DEST" "$SRC" "${PAYLOAD[@]}"; then
      echo "(none — installed config already matches the repo)"
    fi
    echo "==============================================================================="
    echo
  else
    echo "First install — $DEST does not exist yet."
    echo
  fi

  if [ "$ASSUME_YES" != "--yes" ]; then
    if ! confirm 'Install this config and bless it?'; then
      echo "Aborted. Nothing was changed."
      exit 1
    fi
  fi

  mkdir -p "$DEST" "$BIN_DIR"

  # projects/ holds per-project egress registrations and is host-owned state — it is
  # NOT part of the canonical repo payload, so never clobber it.
  mkdir -p "$DEST/projects"

  local item
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
  echo "Done. Blessed, NOT verified: a bless is a review of files, not a test of a container."
  echo "Next steps:"
  echo "  touch ~/.ssh/canary                    # once, if you haven't — strengthens the H1 probe"
  echo "  cc-isolated --probe-only <repo>        # REQUIRED after any boundary change: rebuilds from"
  echo "                                         # this config and records it verified live on a pass"
  echo "  cc-isolated                            # session for the repo containing \$PWD"
  echo "  cc-isolated --register <repo> --profile python   # widen a project's egress"
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo; echo "WARNING: $BIN_DIR is not on your PATH — add it, or call $DEST/cc-isolated.sh directly." ;;
  esac
}

install_devcontainer
