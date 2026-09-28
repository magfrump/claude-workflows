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
#                  CC_PUSH_CLONES_DIR defaulting to $XDG_DATA_HOME/cc-isolated/clones,
#                  or ~/.local/share/cc-isolated/clones when XDG_DATA_HOME is unset).
#   --yes          push without asking (the preview is still printed).
#
# Exit codes: 0 pushed (or nothing to push); 1 error: bad usage, a checkout cc-push
# refuses (below), a failed fetch, or a push the remote rejected (git's own exit
# status is never passed through); 2 declined at the prompt.
#
# WHY. The container writes the checkout's .git through the bind mount, so host git
# run IN the checkout can run what the session planted: hooks, core.fsmonitor,
# filter drivers, remote.*.receivepack, a remote repointed at a repo with hooks, an
# `exec` line in a rebase todo list — and, with no .git change at all, a hook that
# was already there and runs a tracked file the session edited (husky, the
# pre-commit framework). cc-isolated's exit scan is a tripwire for some of that,
# not a guarantee. cc-push runs no git command in the checkout: it keeps a BARE
# clone that only the host writes, and in it:
#   1. `git fetch <checkout>` — for a local path git starts upload-pack in the
#      checkout's .git. upload-pack READS there: refs, objects and config (the
#      checkout's config, and your global config). It runs no hook, no fsmonitor,
#      no filter, and ignores uploadpack.packObjectsHook from repo config. Nothing
#      is checked out.
#   2. `git fetch origin` — the real remote, as configured in the clone.
#   3. a preview of what the push adds (log, and a diff stat when origin already
#      has the branch), printed as plain text;
#   4. `git push origin refs/cc/heads/<branch>:refs/heads/<branch>` from the clone.
# Every git command cc-push runs passes core.hooksPath=/dev/null and
# core.fsmonitor=false, so your own global config cannot point hooks at anything
# either.
#
# WHAT UPLOAD-PACK WOULD READ BEYOND THE CHECKOUT, AND SO IS REFUSED. Before the
# fetch, with plain file tests (no git), cc-push refuses a checkout whose .git is
# not a real directory (a `gitdir:` file or a symlink: a linked worktree or
# submodule, or a redirect to any repository on this machine), or holds a
# commondir, objects/info/alternates or objects/info/http-alternates file (each
# names another object store), a symlink outside hooks/, a FIFO, socket or device
# (a read of one never ends), or a config / config.worktree with an [include] or
# [includeIf] section (git would read whatever path it names, a FIFO included).
# Otherwise upload-pack could fetch history from another repository you can read
# and cc-push would offer it for push. Run cc-push on the main checkout.
#
# EVERY STRING FROM THE CHECKOUT (branch names, commit text, git's messages) is
# printed through vis: anything but printable ASCII shows as '?'.
#
# KEEP THE CLONE HOOK-FREE. It holds container-authored content. It is bare, so
# nothing is checked out and no tool installs hooks into it; if you ever check out
# a working tree from it and run husky/pre-commit/lefthook there, the fetched
# content runs on your next commit. Do your host-side work in a normal clone of the
# real remote, after the push, like any other collaborator's commits.

set -euo pipefail

# Whatever the caller's environment points git at, cc-push chooses the repos.
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_CEILING_DIRECTORIES

# usage: the comment block above, from line 2 to the first line that is not a
# comment, so it cannot end mid-sentence when the block grows.
usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"
}

# vis: every byte outside printable ASCII (newline aside) as '?'. Byte-wise under
# LC_ALL=C, so C0 and C1 controls (0x80-0x9f, and their UTF-8 forms U+0080-U+009F),
# bidi overrides (U+202A-U+202E, U+2066-U+2069) and any other non-ASCII text are
# all neutralised: a commit message or branch name the session wrote cannot
# rewrite the terminal or reorder what it shows.
vis() {
  LC_ALL=C tr -c '[:print:]\n' '?'
}

# say <text...>: one line, through vis.
say() {
  printf '%s\n' "$*" | vis
}

die() {
  printf 'ERROR: %s\n' "$*" | vis >&2
  exit 1
}

# ngit <args...>: git with hooks and fsmonitor off whatever any config says.
ngit() {
  git -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"
}

# hgit <clone> <args...>: ngit in the host-only clone.
hgit() {
  local c="$1"; shift
  ngit -C "$c" "$@"
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

# check_checkout <checkout>: refuse (die) a .git that would make upload-pack read
# outside the checkout or block forever (see the header). Plain file tests, find
# -P (never follows a link) and grep on the config as text: no git runs here.
check_checkout() {
  local co="$1" g="$1/.git" f odd
  local run_main="cc-push reads only a checkout whose .git is a real directory. Run it on the main checkout (the one the session was launched on)."
  if [ -L "$g" ]; then
    die "$g is a symlink: it can point git at any repository on this machine. $run_main"
  fi
  if [ ! -d "$g" ]; then
    die "$g is not a directory (a linked worktree's or submodule's gitdir: file): its gitdir: line can point git at any repository on this machine. $run_main"
  fi
  if [ -e "$g/commondir" ] || [ -L "$g/commondir" ]; then
    die "$g/commondir exists (a linked worktree's layout): it names another repository, which git would read. $run_main"
  fi
  for f in objects/info/alternates objects/info/http-alternates; do
    if [ -e "$g/$f" ] || [ -L "$g/$f" ]; then
      die "$g/$f exists: git would read objects from the repositories it names, anywhere on this machine, and cc-push could push them. Push this work from a checkout that does not borrow objects (no clone --shared or --reference)."
    fi
  done
  # A symlink (outside hooks/, which upload-pack never reads) can alias another
  # repository's objects or refs; a FIFO, socket or device blocks the read.
  # Its name is the container's: line breaks in it are shown as '?' too.
  if ! odd="$(find -P "$g" -path "$g/hooks" -prune -o \( -type l -o ! -type f ! -type d \) -printf '%p' -quit 2>&1)"; then
    die "cannot list everything under $g: ${odd//$'\n'/?}"
  fi
  odd="${odd//$'\n'/?}"
  if [ -n "$odd" ]; then
    die "$odd is a symlink, FIFO, socket or device inside the checkout's .git: git could read another repository through it, or block forever reading it. Remove it (it is not something git creates), then rerun."
  fi
  # [include] / [includeIf "..."] (any case, and a header may follow another on
  # one line): git would read the named path, which can be a FIFO or another
  # repository's config. Read as text; an include that is only mentioned inside a
  # value is refused too.
  for f in config config.worktree; do
    [ -e "$g/$f" ] || continue
    if LC_ALL=C grep -Eiq '\[[[:space:]]*include' "$g/$f"; then
      die "$g/$f has an [include] or [includeIf] section: git would read whatever path it names (another repository's config, or a FIFO that never ends). Check what it points at, delete the section with a text editor (not git config), then rerun."
    fi
  done
}

# run_vis <command...>: run it with stdout and stderr through vis; its status.
run_vis() {
  local rc=0
  "$@" 2>&1 | vis || rc=$?
  return "$rc"
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
  check_checkout "$co"

  local id name
  id="$(printf '%s' "$co" | sha256sum | cut -c1-12)"
  name="$(basename -- "$co")"
  if [ -z "$clone" ]; then
    clone="${CC_PUSH_CLONES_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/cc-isolated/clones}/$name-$id"
  fi
  local clone_real
  clone_real="$(realpath -m -- "$clone")" || die "cannot resolve the clone path $clone"
  case "$clone_real/" in
    "$co"/*) die "the clone $clone is inside the checkout $co, which the container can write" ;;
  esac

  # The clone: created here, bare, marked with the checkout it serves. A directory
  # without cc-push's marker file for this checkout is never used (it could be a
  # working tree with hooks).
  if [ ! -e "$clone" ]; then
    [ -n "$remote" ] || die "no host-only clone for $co yet. Name the real remote once:
  cc-push --remote <url> $co
(cc-push never reads remotes from the checkout: the session could have changed them.)"
    mkdir -p "$(dirname -- "$clone")" 2>/dev/null || die "cannot create the directory for the clone $clone"
    run_vis ngit init -q --bare "$clone" >&2 || die "could not create the host-only clone $clone"
    { hgit "$clone" config core.hooksPath /dev/null &&
      hgit "$clone" config remote.origin.url "$remote" &&
      hgit "$clone" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' &&
      printf '%s\n' "$co" > "$clone/cc-push-checkout"; } \
      || die "could not set up the host-only clone $clone"
    say "Created the host-only clone $clone (bare, hooks off) for $co."
  else
    [ -f "$clone/cc-push-checkout" ] || die "$clone exists but has no cc-push marker; pick another --clone"
    [ "$(cat "$clone/cc-push-checkout")" = "$co" ] \
      || die "$clone serves $(cat "$clone/cc-push-checkout"), not $co; pick another --clone"
    if [ -n "$remote" ]; then
      hgit "$clone" config remote.origin.url "$remote" || die "could not set the remote in $clone"
      say "Remote for $co set to: $remote"
    fi
  fi
  remote="$(hgit "$clone" config --get remote.origin.url)" || die "no remote.origin.url in $clone; rerun with --remote <url>"

  # 1. The session's branches, from the checkout. A local-path fetch: git runs
  # upload-pack there and copies refs and objects; no submodules, no tags, no
  # checkout. refs/cc/heads/* mirrors the checkout's branches (pruned).
  # protocol.file.allow=always: a global protocol.file.allow=never would refuse
  # this one fetch that has to be local.
  if ! run_vis hgit "$clone" -c protocol.file.allow=always fetch -q --no-tags --no-recurse-submodules \
         --no-write-fetch-head --prune "$co" '+refs/heads/*:refs/cc/heads/*' >&2; then
    die "could not fetch from $co"
  fi

  if [ -z "$branch" ]; then
    local sym
    # LC_ALL=C: a branch name need not be valid UTF-8, and `.` must match any byte.
    sym="$(hgit "$clone" -c protocol.file.allow=always ls-remote --symref "$co" HEAD 2>/dev/null | LC_ALL=C sed -n 's/^ref: refs\/heads\/\(.*\)\tHEAD$/\1/p')" || true
    [ -n "$sym" ] || die "the checkout's HEAD names no branch (detached?); pass --branch <name>"
    branch="$sym"
  fi
  ngit check-ref-format "refs/heads/$branch" || die "not a valid branch name: $branch"
  local src="refs/cc/heads/$branch"
  hgit "$clone" rev-parse -q --verify "$src^{commit}" >/dev/null \
    || die "the checkout has no branch $branch"

  # 2. The real remote's current state, so the preview is against what is there.
  run_vis hgit "$clone" fetch -q --no-tags --no-recurse-submodules origin >&2 \
    || die "could not fetch from origin ($remote)"

  # 3. Preview. --no-ext-diff/--no-textconv: no diff program runs on the session's
  # files; --no-show-signature: no gpg on its signatures; output is plain text.
  local base="refs/remotes/origin/$branch" range commits
  say "Push $src ($co)"
  say "  to origin ($remote) as $branch."
  if hgit "$clone" rev-parse -q --verify "$base^{commit}" >/dev/null; then
    range="$base..$src"
    commits="$(hgit "$clone" rev-list "$range")" || die "could not list the commits in $range"
    if [ -z "$commits" ]; then
      say "Nothing to push: origin/$branch already has every commit."
      exit 0
    fi
    say "Commits origin/$branch does not have:"
    run_vis hgit "$clone" --no-pager log --no-show-signature --format='  %h %an: %s' "$range" \
      || die "could not show the commits in $range"
    # No merge base (unrelated history): no stat; the remote will refuse the push.
    hgit "$clone" --no-pager diff --no-ext-diff --no-textconv --stat "$base...$src" 2>/dev/null | vis \
      || say "  (no diff stat: $branch shares no history with origin/$branch)"
  else
    say "origin has no branch $branch; commits not on any origin branch:"
    run_vis hgit "$clone" --no-pager log --no-show-signature --format='  %h %an: %s' "$src" --not --remotes=origin \
      || die "could not show the commits on $branch"
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
  # refused by the remote as usual: cc-push never forces. git's report (and the
  # remote's messages) name the branch, so they go through vis too.
  run_vis hgit "$clone" push origin "$src:refs/heads/$branch" \
    || die "the push of $branch to origin failed (see above); nothing was forced"
  say "Pushed $branch to origin."
}

# Main-execution guard: allow sourcing for tests. main runs in a subshell with
# errexit on, so an unexpected failure still exits 1 rather than git's own status
# (128 and so on): the exit codes stay 0, 1 and 2.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set +e
  ( set -e; main "$@" )
  rc=$?
  case "$rc" in
    0|1|2) exit "$rc" ;;
    *) echo "ERROR: cc-push stopped on an unexpected failure (status $rc)." >&2; exit 1 ;;
  esac
fi
