#!/bin/bash
# The D6 snippet (plan D6, F38-F40; U3b3): the one way the orchestrator runs
# build-loop.sh (the gate) and dev-cycle.sh (the digest). U4 puts this file,
# byte for byte, in skills/dev-cycle/SKILL.md, the root-owned image copy, as
# the body of a quoted heredoc that bash reads, so it runs the same from any
# login shell:
#   bash -s -- build-loop.sh ARG... <<'D6'
#   (this file)
#   D6
# T33 asserts the two match. Run it from the repository's checkout (the
# orchestrator's own worktree). It trusts no file the uid can write: in
# claude-workflows (main's first-parent root commit is D6_ROOT) it runs main's
# own scripts, extracted from main's commit into a fresh temp dir and
# hash-checked just before the run; in any other repository it runs the image
# copy under D6_OPT, by absolute path, once those files and every directory
# above them are root-owned, no symlink and not writable here. It never reads
# the working tree, ~/.claude/scripts or a replaced object.
# Arguments: build-loop.sh or dev-cycle.sh, then that script's own.
# Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout,
# with nothing run, for a replace ref, info/grafts, a default branch that is
# not exactly one plain main or master, a script on main that is not a
# regular file or whose extracted bytes do not hash to main's id, or an image
# copy that fails the ownership checks; 1 for another first argument.
# Its own git calls carry the lib's HARDEN pairs and git_harden's environment
# (a test pins the two lists equal).
d6() {
  set -u
  D6_ROOT=640cf00735754d4253819a0354fb8ca9b71a8ea7; D6_OPT=/opt/claude-workflows
  no() { echo "refuse d6: $*"; exit 2; }
  g() { GIT_NO_REPLACE_OBJECTS=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none GIT_LITERAL_PATHSPECS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 git -c core.useReplaceRefs=false -c core.hooksPath=/dev/null -c core.fsmonitor=false -c core.attributesFile=/dev/null -c core.commitGraph=false -c core.multiPackIndex=false -c log.date=default -c log.showSignature=false "$@"; }
  own() { [[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no "$1 is not root-owned, a plain path and unwritable here"; }
  local s="${1:-}" F x m n sha ids f i  # d stays global: the EXIT trap reads it
  [[ "$s" == build-loop.sh || "$s" == dev-cycle.sh ]] || { echo "d6: the first argument is build-loop.sh or dev-cycle.sh" >&2; exit 1; }
  shift
  F=(build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh)
  x="$(g for-each-ref --format='%(refname)' refs/replace/)" || no "refs/replace could not be listed"
  [[ -z "$x" ]] || no "a replace ref exists (F38)"
  x="$(g rev-parse --path-format=absolute --git-path info/grafts)" || no "the grafts path could not be read"
  [[ ! -e "$x" && ! -L "$x" ]] || no "info/grafts exists (F38)"
  m=""; for n in main master; do g show-ref --verify -q "refs/heads/$n" && m+="$n "; done
  m="${m% }"; [[ "$m" == main || "$m" == master ]] || no "the default branch is not exactly one of main and master"
  ! g symbolic-ref -q "refs/heads/$m" >/dev/null || no "refs/heads/$m is a symbolic ref"
  sha="$(g rev-parse --verify -q "refs/heads/$m^{commit}")" || no "refs/heads/$m names no commit"
  if [[ "$(g rev-list --first-parent --max-parents=0 "$sha")" == "$D6_ROOT" ]]; then
    d="$(mktemp -d)" || no "mktemp failed"
    trap 'rm -rf "$d"' EXIT
    mkdir "$d/scripts" "$d/scripts/lib" || no "the temp dir could not be laid out"
    ids=()
    for f in "${F[@]}"; do
      x="$(g ls-tree --format='%(objectmode) %(objecttype) %(objectname)' "$sha" -- "scripts/$f")" || no "scripts/$f could not be listed"
      [[ "$x" =~ ^100(644|755)\ blob\ ([0-9a-f]+)$ ]] || no "scripts/$f is not a regular file on $m"
      ids+=("${BASH_REMATCH[2]}")
      g cat-file blob "${BASH_REMATCH[2]}" > "$d/scripts/$f" || no "scripts/$f could not be read from $m"
    done
    for i in "${!F[@]}"; do
      [[ "$(g hash-object --no-filters "$d/scripts/${F[i]}")" == "${ids[i]}" ]] || no "the extracted scripts/${F[i]} does not hash to $m's copy"
    done
  else
    d="$D6_OPT"
    for f in "${F[@]}"; do own "$d/scripts/$f"; [[ -f "$d/scripts/$f" ]] || no "$d/scripts/$f is not a regular file"; done
    x="$d/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done
  fi
  env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"
  exit "$?"
}
# Under bash -s the script is the heredoc on stdin: bash has read this whole
# line before it runs, and no child reads the rest of it.
d6 "$@" </dev/null
