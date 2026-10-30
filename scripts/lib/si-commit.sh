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
# These git calls run as this script on a tree the child wrote (constraint
# H1), so nothing the child could write may steer them:
#   - The git dir is pinned. The worktree's `.git` is a child-writable file, so
#     the admin dir is found from the trusted repo's worktrees/*/gitdir records
#     instead, the child's `.git` must point at that same dir, and git gets it
#     with --git-dir/--work-tree, never by discovery. Otherwise a `.git`
#     pointing at a child-made dir would bring its own config (core.fsmonitor,
#     hooks) and run child code as the script, and one pointing at a sibling
#     worktree's admin dir would commit onto that sibling's branch.
#   - Every hook is off (core.hooksPath=/dev/null plus --no-verify), and so is
#     core.fsmonitor, in case the repo's config names a path inside the tree.
#
# Args: $1 = worktree dir, $2 = task description (the fallback message),
#       $3 = the repo the worktree belongs to (REPO_DIR)
# Returns: 0 committed; 3 nothing to commit (no commit made); 1 failure, with
#          a line on stderr naming why.
si_commit_child_work() {
    local wt=$1 desc=$2 repo=$3 common gd msg msg_src="" tmp="" err rc=0
    # Absolute, because a relative -F path would resolve from git's cwd.
    if ! wt=$(cd -- "$wt" 2>/dev/null && pwd -P); then
        echo "worktree $1 does not exist" >&2
        return 1
    fi
    if ! common=$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) \
        || ! common=$(cd -- "$common" && pwd -P); then
        echo "cannot find the git dir of repo $repo" >&2
        return 1
    fi
    # The admin dir comes from the repo's own records: each worktrees/<name>/
    # holds a `gitdir` file, written by git and outside the child's cwd, that
    # names its worktree's .git. A relative value is relative to that dir.
    local d p
    gd=""
    for d in "$common"/worktrees/*/; do
        [ -f "$d/gitdir" ] || continue
        p=$(head -n 1 -- "$d/gitdir")
        [ "${p#/}" != "$p" ] || p="$d/$p"
        p=$(cd -- "${p%/.git}" 2>/dev/null && pwd -P) || continue
        if [ "$p" = "$wt" ]; then gd=$(cd -- "$d" && pwd -P); break; fi
    done
    if [ -z "$gd" ]; then
        echo "$wt is not a registered worktree of $common; refusing to commit there" >&2
        return 1
    fi
    # The child's .git must agree, so a tampered one fails loudly instead of
    # sitting there for later gates' git discovery.
    if [ -L "$wt/.git" ] || [ ! -f "$wt/.git" ]; then
        echo ".git in $wt is not a worktree link file; refusing to commit there" >&2
        return 1
    fi
    p=$(sed -n '1s/^gitdir: //p' "$wt/.git")
    if [ -z "$p" ] || ! p=$(cd -- "$wt" && cd -- "$p" 2>/dev/null && pwd -P) || [ "$p" != "$gd" ]; then
        echo ".git in $wt does not point at its own admin dir $gd; refusing to commit there" >&2
        return 1
    fi
    # Operator env that could redirect the index or objects is dropped too.
    local -a g=(env -u GIT_INDEX_FILE -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES
        git --git-dir="$gd" --work-tree="$wt" -c core.hooksPath=/dev/null -c core.fsmonitor=false)
    msg="$wt/$SI_COMMIT_MSG_FILE"
    # The script, not the child, reads this file, so a symlink would let it
    # copy a file from outside the worktree into a commit message.
    if [ -L "$msg" ] || { [ -e "$msg" ] && [ ! -f "$msg" ]; }; then
        echo "$SI_COMMIT_MSG_FILE in $wt is not a regular file; refusing to read it" >&2
        return 1
    fi
    # Pathspecs are relative to git's cwd, so run from the worktree root.
    if ! err=$(cd -- "$wt" && "${g[@]}" add -A -- . ":(exclude)$SI_COMMIT_MSG_FILE" 2>&1); then
        echo "git add failed in $wt: $err" >&2
        return 1
    fi
    # Exit 1 means staged changes; an error (128) also falls through, and the
    # commit below then fails loudly.
    if "${g[@]}" diff --cached --quiet 2>/dev/null; then
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
    err=$("${g[@]}" commit -q --no-verify -F "$msg_src" 2>&1) || rc=$?
    [ -z "$tmp" ] || rm -f -- "$tmp"
    if [ "$rc" -ne 0 ]; then
        echo "git commit failed in $wt (exit $rc): $(printf '%s' "$err" | tr '\n' ' ')" >&2
        return 1
    fi
    # Committed: drop the message file so later gates see a clean worktree.
    rm -f -- "$msg"
    return 0
}
