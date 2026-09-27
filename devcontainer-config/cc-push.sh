#!/usr/bin/env bash
# cc-push — push the commits a cc-isolated session made, without running anything
# the session could have planted in the checkout (Q-076).
#
# Run from the HOST, never inside a session:
#   cc-push --remote git@github.com:me/app.git ~/code/app   # first push: sets the remote
#   cc-push ~/code/app                                      # later: same remote
#   cc-push                                                 # the checkout containing $PWD
#   cc-push --branch feat/x ~/code/app                      # a branch other than HEAD's
#
# Options:
#   --remote URL   the real remote, stored in the host-only clone (never read from
#                  the checkout). Needed the first time; given again, it replaces it.
#   --branch NAME  the branch to push (default: the one the checkout's HEAD names).
#   --clone DIR    the host-only clone (default: $CC_PUSH_CLONES_DIR/<name>-<id>,
#                  CC_PUSH_CLONES_DIR defaulting to ~/.local/share/cc-isolated/clones).
#   --yes          push without asking (the preview is still printed).
#
# WHY. The container writes the checkout's .git through the bind mount, so host git
# run IN the checkout can run what the session planted: hooks, core.fsmonitor,
# filter drivers, remote.*.receivepack, a remote repointed at a repo with hooks, an
# `exec` line in a rebase todo list — and, with no .git change at all, a hook that
# was already there and runs a tracked file the session edited (husky, the
# pre-commit framework). cc-isolated's exit scan is a tripwire for some of that,
# not a guarantee. cc-push never runs git in the checkout. It keeps a BARE clone
# that only the host writes, and in it:
#   1. `git fetch <checkout>` — git runs upload-pack in the checkout, which reads
#      its refs, objects and config but runs no hook, no fsmonitor, no filter, and
#      ignores uploadpack.packObjectsHook from repo config. Nothing is checked out.
#   2. `git fetch origin` — the real remote, as configured in the clone.
#   3. a preview of what the push adds (log and diff stat, printed as plain text);
#   4. `git push origin refs/cc/heads/<branch>:refs/heads/<branch>` from the clone.
# Every git call here passes core.hooksPath=/dev/null and core.fsmonitor=false, so
# your own global config cannot point hooks at anything either.
#
# KEEP THE CLONE HOOK-FREE. It holds container-authored content. It is bare, so
# nothing is checked out and no tool installs hooks into it; if you ever check out
# a working tree from it and run husky/pre-commit/lefthook there, the fetched
# content runs on your next commit. Do your host-side work in a normal clone of the
# real remote, after the push, like any other collaborator's commits.
#
# Exit codes: 0 pushed (or nothing to push), 1 usage or setup error, 2 declined.

set -euo pipefail

# Whatever the caller's environment points git at, cc-push chooses the repos.
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_CEILING_DIRECTORIES

usage() {
  sed -n '2,38p' "${BASH_SOURCE[0]}"
}

# vis: control bytes (and anything outside printable ASCII) as '?', so a commit
# message or branch name the session wrote cannot rewrite the terminal.
vis() {
  LC_ALL=C tr -c '[:print:]\n' '?'
}

die() {
  printf 'ERROR: %s\n' "$*" | vis >&2
  exit 1
}

# hgit <clone> <args...>: git in the host-only clone, with hooks and fsmonitor off
# whatever any config says.
hgit() {
  local c="$1"; shift
  git -C "$c" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"
}

# find_checkout <start>: the nearest directory at or above <start> holding a .git
# entry. Plain file tests: no git runs in the checkout.
find_checkout() {
  local d
  d="$(cd "$1" 2>/dev/null && pwd -P)" || return 1
  while :; do
    if [ -e "$d/.git" ] || [ -L "$d/.git" ]; then printf '%s' "$d"; return 0; fi
    [ "$d" != / ] || return 1
    d="$(dirname -- "$d")"
  done
}

main() {
  local remote="" branch="" clone="" yes="" start=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --remote) [ $# -ge 2 ] || die "--remote needs a URL"; remote="$2"; shift 2 ;;
      --branch) [ $# -ge 2 ] || die "--branch needs a name"; branch="$2"; shift 2 ;;
      --clone)  [ $# -ge 2 ] || die "--clone needs a directory"; clone="$2"; shift 2 ;;
      --yes)    yes=1; shift ;;
      --help|-h) usage; exit 0 ;;
      --) shift; break ;;
      -*) usage >&2; die "unknown flag: $1" ;;
      *)  [ -z "$start" ] || die "one checkout at a time"; start="$1"; shift ;;
    esac
  done
  [ $# -eq 0 ] || { [ -z "$start" ] && start="$1"; }

  local co
  co="$(find_checkout "${start:-$PWD}")" \
    || die "no git checkout at or above ${start:-$PWD}. Name it: cc-push /path/to/checkout"
  case "$co" in *$'\n'*|*::*) die "refusing a checkout path holding a newline or '::'" ;; esac

  local id name
  id="$(printf '%s' "$co" | sha256sum | cut -c1-12)"
  name="$(basename -- "$co")"
  if [ -z "$clone" ]; then
    clone="${CC_PUSH_CLONES_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/cc-isolated/clones}/$name-$id"
  fi
  local clone_real
  clone_real="$(realpath -m -- "$clone")"
  case "$clone_real/" in
    "$co"/*) die "the clone $clone is inside the checkout $co, which the container can write" ;;
  esac

  # The clone: created here, bare, marked with the checkout it serves. A directory
  # cc-push did not create is never used (it could be a working tree with hooks).
  if [ ! -e "$clone" ]; then
    [ -n "$remote" ] || die "no host-only clone for $co yet. Name the real remote once:
  cc-push --remote <url> $co
(cc-push never reads remotes from the checkout: the session could have changed them.)"
    mkdir -p "$(dirname -- "$clone")"
    git init -q --bare "$clone"
    hgit "$clone" config core.hooksPath /dev/null
    hgit "$clone" config remote.origin.url "$remote"
    hgit "$clone" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    printf '%s\n' "$co" > "$clone/cc-push-checkout"
    echo "Created the host-only clone $clone (bare, hooks off) for $co." | vis
  else
    [ -f "$clone/cc-push-checkout" ] || die "$clone exists but was not made by cc-push; pick another --clone"
    [ "$(cat "$clone/cc-push-checkout")" = "$co" ] \
      || die "$clone serves $(cat "$clone/cc-push-checkout"), not $co; pick another --clone"
    if [ -n "$remote" ]; then
      hgit "$clone" config remote.origin.url "$remote"
      echo "Remote for $co set to: $remote" | vis
    fi
  fi
  remote="$(hgit "$clone" config --get remote.origin.url)" || die "no remote.origin.url in $clone; rerun with --remote <url>"

  # 1. The session's branches, from the checkout. A local-path fetch: git runs
  # upload-pack there and copies refs and objects; no submodules, no tags, no
  # checkout. refs/cc/heads/* mirrors the checkout's branches (pruned).
  # protocol.file.allow=always: a global "never" (which the guide suggests for
  # other pushes) would refuse this one fetch that has to be local.
  if ! hgit "$clone" -c protocol.file.allow=always fetch -q --no-tags --no-recurse-submodules \
         --no-write-fetch-head --prune "$co" '+refs/heads/*:refs/cc/heads/*'; then
    die "could not fetch from $co"
  fi

  if [ -z "$branch" ]; then
    local sym
    sym="$(hgit "$clone" -c protocol.file.allow=always ls-remote --symref "$co" HEAD 2>/dev/null | sed -n 's/^ref: refs\/heads\/\(.*\)\tHEAD$/\1/p')" || true
    [ -n "$sym" ] || die "the checkout's HEAD names no branch (detached?); pass --branch <name>"
    branch="$sym"
  fi
  git check-ref-format "refs/heads/$branch" || die "not a valid branch name: $branch"
  local src="refs/cc/heads/$branch"
  hgit "$clone" rev-parse -q --verify "$src^{commit}" >/dev/null \
    || die "the checkout has no branch $branch"

  # 2. The real remote's current state, so the preview is against what is there.
  hgit "$clone" fetch -q --no-tags --no-recurse-submodules origin \
    || die "could not fetch from origin ($remote)"

  # 3. Preview. --no-ext-diff/--no-textconv: no diff program runs on the session's
  # files; --no-show-signature: no gpg on its signatures; output is plain text.
  local base="refs/remotes/origin/$branch" range
  echo "Push $src ($co)"
  echo "  to origin ($remote) as $branch."
  if hgit "$clone" rev-parse -q --verify "$base^{commit}" >/dev/null; then
    range="$base..$src"
    if [ -z "$(hgit "$clone" rev-list "$range")" ]; then
      echo "Nothing to push: origin/$branch already has every commit." | vis
      exit 0
    fi
    echo "Commits origin/$branch does not have:"
    hgit "$clone" --no-pager log --no-show-signature --format='  %h %an: %s' "$range" | vis
    hgit "$clone" --no-pager diff --no-ext-diff --no-textconv --stat "$base...$src" | vis
  else
    echo "origin has no branch $branch; commits not on any origin branch:"
    hgit "$clone" --no-pager log --no-show-signature --format='  %h %an: %s' "$src" --not --remotes=origin | vis
  fi

  if [ -z "$yes" ]; then
    local reply=""
    printf 'Push these? [y/N] '
    read -r reply || reply=""
    case "$reply" in
      [yY]|[yY][eE][sS]) ;;
      *) echo "Not pushed."; exit 2 ;;
    esac
  fi

  # 4. From the clone, with your credentials; hooks off. A non-fast-forward is
  # refused by the remote as usual: cc-push never forces.
  hgit "$clone" push origin "$src:refs/heads/$branch"
  echo "Pushed $branch to origin." | vis
}

# Main-execution guard: allow sourcing for tests.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
