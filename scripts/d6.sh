#!/bin/bash
# d6.sh (plan D6; Q-140 [1]): the one way the orchestrator runs build-loop.sh
# (the gate), dev-cycle.sh (the digest) and questions.sh. The dev-cycle skill
# calls the root-owned image copy by absolute path:
#   cd CHECKOUT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG...
# It always runs the root-owned image copy under D6_OPT by absolute path, never
# main's copy, a working-tree copy or ~/.claude/scripts, so no repository data
# chooses which script runs (Q-140: a choice read from the repository let a
# loop that moved main, or rewrote the checkout's .git entry, pick its own
# scripts). D6_OPT is a literal, never read from the environment or from this
# file's own path: a working-tree copy of this file still runs the image's
# scripts. It still trusts that entry and the default branch's ref for which
# repository and branch the script reads (a moved main is --main-log's to
# report), and it cannot guard against this uid's own shell (PATH, exported
# functions): the plan's same-uid residual (Q-103). In claude-workflows a gate
# change runs from the next image release. Run it from the checkout the script
# is to read (each step names MAIN_WT, WT or GT). Arguments: build-loop.sh,
# dev-cycle.sh or questions.sh, then that script's own.
# Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout, with
# nothing run, for an image-copy file that is missing or not a regular file (a
# partial image), an image lib that does not load or whose git_harden refuses
# the caller's environment, a default branch that is not exactly one of main and
# master, or a git read that exits above 1 (git may add a line on stderr); 1 for
# another first argument. An image with no d6.sh at all prints nothing of this:
# bash exits 127 naming the path, which the skill's Rules read as this refusal.
# Its git is the image lib's git_harden, in a subshell, so the script starts
# from the caller's environment, not with d6.sh's pairs. These checks come
# before, not instead of, build-loop.sh's own state and default-branch gates in
# its gated modes, which also refuse a symbolic or non-commit default branch
# (dev-cycle.sh, questions.sh and the read modes have none; row 548 for
# dev-cycle.sh). What it no longer checks, and why, is rows R6c to R6e of the
# restriction audit, in docs/working/research-2026-11-05-d6-block-into-image.md.
set -u -o pipefail
D6_OPT=/opt/claude-workflows
no() { echo "refuse d6: $*"; exit 2; }
# shellcheck source=lib/dev-cycle-read.sh
harden() { source "$D6_OPT/scripts/lib/dev-cycle-read.sh" && git_harden; }
g() { ( harden && git "$@" ); }
s="${1:-}"
[[ "$s" == build-loop.sh || "$s" == dev-cycle.sh || "$s" == questions.sh ]] || { echo "d6: the first argument is build-loop.sh, dev-cycle.sh or questions.sh" >&2; exit 1; }
shift
# The four files the scripts run (build-loop.sh and dev-cycle.sh source the
# lib from their own directory; dev-cycle.sh runs questions.sh beside it).
# lib/migrations.sh is left out: both scripts check it themselves before use.
for f in build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh; do
  x="$D6_OPT/scripts/$f"
  [[ -e "$x" || -L "$x" ]] || no "$x is missing"
  [[ -f "$x" && ! -L "$x" ]] || no "$x is not a regular file"
done
# Tried alone first, so that exit 1 below comes from show-ref, which counts as
# absent a ref it cannot use (a junk file, a dangling symbolic ref), as the block did.
( harden ) || no "$D6_OPT/scripts/lib/dev-cycle-read.sh did not load, or its git_harden refused this environment"
have=""
for n in main master; do
  rc=0; g show-ref --verify -q "refs/heads/$n" || rc=$?
  [[ "$rc" -le 1 ]] || no "refs/heads/$n could not be read"
  [[ "$rc" -ne 0 ]] || have+="$n "
done
have="${have% }"; [[ "$have" == main || "$have" == master ]] || no "the default branch is not exactly one of main and master"
exec env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED -u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE -u QUESTIONS_WATCHING bash "$D6_OPT/scripts/$s" "$@" </dev/null
