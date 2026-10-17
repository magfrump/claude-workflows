#!/bin/bash
# Commit an implementer child's work on its behalf (Q-146 [1]).
#
# The implementer children run with no Bash grant, so in a worktree or a
# dedicated clone they cannot run `git commit` (F5 in
# docs/working/si-trust-evidence-2026-10-14.md). Instead each child writes its
# commit message to $SI_COMMIT_MSG_FILE at its worktree root, and the loop
# commits for it after it exits.
#
# Sourced by scripts/self-improvement.sh — do not execute directly.
#
# Functions:
#   si_commit_child_work — stage and commit a task worktree's changes

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: this file should be sourced, not executed directly" >&2
    exit 1
fi

# The message file's name, relative to the worktree root. The implementer
# prompt names it; it is never staged.
SI_COMMIT_MSG_FILE=".si-commit-msg"

# Stage everything the child changed in its worktree (except the message file)
# and commit it with the child's message, or with the task description when the
# child wrote none.
#
# The commit runs with every hook switched off (core.hooksPath=/dev/null plus
# --no-verify). It runs as this script on a tree the child wrote, so a hooks
# directory that the repo's config points into the tree would otherwise run
# child-written code outside the child's permission mode (constraint H1).
#
# Args: $1 = worktree dir, $2 = task description (the fallback message)
# Returns: 0 committed; 3 nothing to commit (no commit made); 1 failure, with
#          a line on stderr naming why.
si_commit_child_work() {
    local wt=$1 desc=$2 msg msg_src="" tmp="" err rc=0
    # Absolute, because `git -C` resolves a relative -F path from inside $wt.
    if ! wt=$(cd -- "$wt" 2>/dev/null && pwd); then
        echo "worktree $1 does not exist" >&2
        return 1
    fi
    msg="$wt/$SI_COMMIT_MSG_FILE"
    # The script, not the child, reads this file, so a symlink would let it
    # copy a file from outside the worktree into a commit message.
    if [ -L "$msg" ] || { [ -e "$msg" ] && [ ! -f "$msg" ]; }; then
        echo "$SI_COMMIT_MSG_FILE in $wt is not a regular file; refusing to read it" >&2
        return 1
    fi
    if ! err=$(git -C "$wt" add -A -- . ":(exclude)$SI_COMMIT_MSG_FILE" 2>&1); then
        echo "git add failed in $wt: $err" >&2
        return 1
    fi
    if git -C "$wt" diff --cached --quiet; then
        return 3
    fi
    if [ -f "$msg" ] && grep -q '[^[:space:]]' "$msg"; then
        msg_src=$msg
    else
        if [ -z "${desc//[[:space:]]/}" ]; then
            echo "no $SI_COMMIT_MSG_FILE in $wt and no task description to fall back on" >&2
            return 1
        fi
        tmp=$(mktemp) || { echo "mktemp failed for the fallback commit message" >&2; return 1; }
        printf '%s\n\nConfidence: low\nNotes: committed by self-improvement.sh; the implementer wrote no %s, so this message is the task description.\n' \
            "$desc" "$SI_COMMIT_MSG_FILE" > "$tmp"
        msg_src=$tmp
    fi
    err=$(git -C "$wt" -c core.hooksPath=/dev/null commit -q --no-verify -F "$msg_src" 2>&1) || rc=$?
    [ -z "$tmp" ] || rm -f "$tmp"
    if [ "$rc" -ne 0 ]; then
        echo "git commit failed in $wt (exit $rc): $err" >&2
        return 1
    fi
    return 0
}
