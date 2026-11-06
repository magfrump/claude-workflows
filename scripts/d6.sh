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
# Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout,
# with nothing run, for a replace ref, info/grafts, a default branch that is
# not exactly one plain main or master or whose ref names no commit itself, an
# image-copy file that is missing (an image older than the skill) or not a
# regular file, or one of those files or a directory above them that is not
# root-owned, a plain path and unwritable here (the -w test makes a run as root
# refuse unless the mount is read-only), or a git read that fails (git may add
# a line on stderr); 1 for another first argument. An image with no d6.sh at
# all prints nothing of this: bash exits 127 naming the path, which the skill's
# Rules read as this refusal. Its git carries the lib's HARDEN pairs and
# git_harden's environment (G; a test pins the lists equal). These checks come
# before, not instead of, build-loop.sh's own state and default-branch gates in
# its gated modes (dev-cycle.sh, questions.sh and the read modes have none; row
# 548 for dev-cycle.sh).
set -u -o pipefail
D6_OPT=/opt/claude-workflows
no() { echo "refuse d6: $*"; exit 2; }
G=(env GIT_NO_REPLACE_OBJECTS=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none GIT_LITERAL_PATHSPECS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 git -c core.useReplaceRefs=false -c core.hooksPath=/dev/null -c core.fsmonitor=false -c core.attributesFile=/dev/null -c core.commitGraph=false -c core.multiPackIndex=false -c log.date=default -c log.showSignature=false -c commit.gpgSign=false)
g() { "${G[@]}" "$@"; }
own() { [[ -e "$1" || -L "$1" ]] || no "$1 is missing"; [[ ! -L "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no "$1 is not root-owned, a plain path and unwritable here"; }
s="${1:-}"
[[ "$s" == build-loop.sh || "$s" == dev-cycle.sh || "$s" == questions.sh ]] || { echo "d6: the first argument is build-loop.sh, dev-cycle.sh or questions.sh" >&2; exit 1; }
shift
x="$(g for-each-ref --format='%(refname)' refs/replace/)" || no "refs/replace could not be listed"
[[ -z "$x" ]] || no "a replace ref exists (F38)"
x="$(g rev-parse --path-format=absolute --git-path info/grafts)" || no "the grafts path could not be read"
[[ ! -e "$x" && ! -L "$x" ]] || no "info/grafts exists (F38)"
m=""; for n in main master; do g show-ref --verify -q "refs/heads/$n" && m+="$n "; done
m="${m% }"; [[ "$m" == main || "$m" == master ]] || no "the default branch is not exactly one of main and master"
! g symbolic-ref -q "refs/heads/$m" >/dev/null || no "refs/heads/$m is a symbolic ref"
sha="$(g rev-parse --verify -q "refs/heads/$m")" && [[ "$(g cat-file -t "$sha")" == commit ]] || no "refs/heads/$m names no commit"
# The four files the scripts run (build-loop.sh and dev-cycle.sh source the
# lib from their own directory; dev-cycle.sh runs questions.sh beside it),
# then every directory from scripts/lib up to /.
for f in build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh; do
  own "$D6_OPT/scripts/$f"; [[ -f "$D6_OPT/scripts/$f" ]] || no "$D6_OPT/scripts/$f is not a regular file"
done
x="$D6_OPT/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done
exec env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED -u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE -u QUESTIONS_WATCHING bash "$D6_OPT/scripts/$s" "$@" </dev/null
