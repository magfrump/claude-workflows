#!/usr/bin/env bash
# cc-push — push the commits a cc-isolated session made, without running anything
# the session could have planted in the checkout (Q-076).
#
# Run from the HOST, never inside a session, and after the session's container
# has stopped (docker stop <name>; cc-push checks):
#   cc-push --remote git@github.com:me/app.git ~/code/app   # first push: sets the remote
#   cc-push ~/code/app                                      # later: same remote
#   cc-push                                                 # the checkout containing $PWD
#   cc-push --branch feat/x ~/code/app                      # a branch other than HEAD's
#
# Options:
#   --remote URL     the real remote, stored in the host-only clone (never read from
#                    the checkout). Needed the first time. It is STICKY: given
#                    again, it replaces the stored one, and every later cc-push of
#                    this checkout uses the new one.
#   --branch NAME    the branch to push (default: the one the checkout's HEAD names).
#   --clone DIR      the host-only clone (default: $CC_PUSH_CLONES_DIR/<name>-<id>,
#                    CC_PUSH_CLONES_DIR defaulting to $XDG_DATA_HOME/cc-isolated/clones,
#                    or ~/.local/share/cc-isolated/clones when XDG_DATA_HOME is unset).
#   --yes            push without asking (the preview is still printed).
#   --allow-running  go on although a cc-isolated container for this checkout is
#                    running, or docker cannot say (loud warning; see below).
#   -h, --help       this text.
# One checkout at a time: a second one, before or after `--`, is a usage error.
#
# Exit codes (the host tools' convention, as install.sh; decision log #58):
#   0 pushed, or nothing to push;
#   1 an error — a checkout, git or container state cc-push refuses (below), a
#     failed fetch, a push the remote rejected (git's own exit status is never
#     passed through), an interruption — or declined at the prompt (n, or Ctrl-C);
#   2 bad usage (an unknown flag, a flag without its value, two checkouts).
#
# WHY. The container writes the checkout's .git through the bind mount, so host git
# run IN the checkout can run what the session planted: hooks, core.fsmonitor,
# filter drivers, remote.*.receivepack, a remote repointed at a repo with hooks, an
# `exec` line in a rebase todo list — and, with no .git change at all, a hook that
# was already there and runs a tracked file the session edited (husky, the
# pre-commit framework). cc-isolated's exit scan is a tripwire for some of that,
# not a guarantee. cc-push runs no git command in the checkout: it keeps a BARE
# clone that only the host writes, and in it:
#   1. resolve the branch: --branch, or the one the checkout's HEAD names
#      (`git ls-remote --symref`, which starts upload-pack like the fetch below);
#   2. `git fetch --upload-pack='git-upload-pack --strict' <checkout>/.git`
#      refs/heads/<branch> only, into refs/cc/heads/<branch>: no other branch the
#      session made is copied to host disk. For a local path git starts
#      upload-pack in that directory, and --strict makes it use exactly that
#      directory or fail (it never tries <dir>/.git or another repository
#      instead). upload-pack READS there: refs, objects and config (the
#      checkout's config, and your global config). It runs no hook, no fsmonitor,
#      no filter, and ignores uploadpack.packObjectsHook from repo config. Nothing
#      is checked out.
#   3. `git fetch origin` — the real remote, as configured in the clone.
#   4. a preview of what the push adds (log, and a diff stat when origin already
#      has the branch), printed as plain text;
#   5. `git push origin refs/cc/heads/<branch>:refs/heads/<branch>` from the clone.
# Every git command cc-push runs passes core.hooksPath=/dev/null and
# core.fsmonitor=false, so your own global config cannot point hooks at anything
# either. So no hook runs on push, git-lfs's pre-push included: cc-push does not
# upload LFS objects (push them from a normal clone once you trust the content).
#
# WHAT IT REFUSES BEFORE THE FETCH.
#   - A git older than the fixed releases of the May 2024 git security update:
#     2.39.4, 2.40.2, 2.41.1, 2.42.2, 2.43.4, 2.44.1, 2.45.1, or any 2.46 and
#     later. That update hardened what a local clone or fetch trusts in the
#     repository it reads from; cc-push's promises rest on it. (This list is
#     from git's release notes as recalled, not checked against them offline.)
#   - A running cc-isolated container for this checkout (docker ps, label
#     cc-project=<id>, the id cc-isolated.sh's project_id gives). While one
#     runs it can change the checkout between cc-push's checks and its fetch.
#     Without docker, or when docker does not answer, cc-push cannot tell, so it
#     refuses as well. --allow-running overrides both, with a warning.
#   - What upload-pack would read beyond the checkout. With plain file tests (no
#     git; cc-gitdir.sh, next to this file), cc-push requires that
#     <checkout>/.git is a directory git accepts as a git directory (a HEAD that
#     is `ref: refs/...`, a detached commit id or a symlink into refs/, and
#     searchable objects/ and refs/ directories: git 2.39's is_git_directory),
#     and that the checkout root itself does not look like a git directory (a
#     HEAD next to objects/, or a commondir file). When .git is not valid,
#     git's discovery falls back to treating the root as a bare repository,
#     which the session can plant. It also refuses a .git that is not a real
#     directory (a `gitdir:` file or a symlink: a linked worktree or submodule,
#     or a redirect to any repository on this machine), or that holds a
#     commondir, objects/info/alternates or objects/info/http-alternates file
#     (each names another object store), a symlink outside hooks/, a FIFO,
#     socket or device (a read of one never ends), or a config /
#     config.worktree with an [include] or [includeIf] section (git would read
#     whatever path it names, a FIFO included). Otherwise upload-pack could
#     fetch history from another repository you can read and cc-push would
#     offer it for push. Run cc-push on the main checkout.
#   - A partial clone (remote.*.promisor or extensions.partialClone in .git's
#     config, read as text): upload-pack there cannot send the objects the clone
#     never downloaded, so the fetch would fail after packing everything else.
# What is left: upload-pack reading the checkout's own refs, objects and
# (include-free) config. The complete list of what cc-isolated's tools do not
# catch is in guides/cc-isolated-usage.md, "Known routes it does not see".
#
# EVERY STRING FROM THE CHECKOUT (branch names, commit text, git's messages,
# including the stderr of every git call that can name a checkout ref) is
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

# gitdir_valid, looks_like_gitdir: plain file tests, next to this file (readlink
# -f: cc-push on PATH is a symlink to the installed copy).
# shellcheck source=cc-gitdir.sh
source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"

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

# usage_die <text...>: a usage error: the reason, then the help, on stderr; exit 2.
usage_die() {
  printf 'ERROR: %s\n' "$*" | vis >&2
  usage >&2
  exit 2
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

# project_id <checkout>: the id cc-isolated gives this checkout — its container
# label is cc-project=<id>, and the clone's default name ends in it. The same
# logic as cc-isolated.sh's project_id (test/cc-push.bats pins that they agree).
project_id() {
  printf '%s' "$1" | sha256sum | cut -c1-12
}

# git_version_ok <`git --version` output>: 0 when it names a release at or above
# the May 2024 security fixes (see the header). Anything unparseable is refused.
git_version_ok() {
  local maj min pat need
  [[ "$1" =~ ^git\ version\ ([0-9]+)\.([0-9]+)\.([0-9]+) ]] || return 1
  maj=$((10#${BASH_REMATCH[1]})); min=$((10#${BASH_REMATCH[2]})); pat=$((10#${BASH_REMATCH[3]}))
  [ "$maj" -ge 2 ] || return 1
  [ "$maj" -eq 2 ] || return 0
  [ "$min" -lt 46 ] || return 0
  case "$min" in
    39) need=4 ;; 40) need=2 ;; 41) need=1 ;; 42) need=2 ;;
    43) need=4 ;; 44) need=1 ;; 45) need=1 ;;
    *)  return 1 ;;   # before 2.39: no fixed release in that series
  esac
  [ "$pat" -ge "$need" ]
}

# check_git_version: die unless the host git is a fixed release (header).
check_git_version() {
  local v
  v="$(git --version 2>/dev/null)" || die "cannot run git --version"
  git_version_ok "$v" || die "$v is older than the fixed releases of the May 2024 git security update (2.39.4, 2.40.2, 2.41.1, 2.42.2, 2.43.4, 2.44.1, 2.45.1, or 2.46 and later). cc-push relies on those fixes when git reads the checkout; upgrade git, then rerun."
}

# check_no_container <checkout> <allow>: die when a cc-isolated container for the
# checkout is running, or docker cannot say, unless <allow> is set (then warn).
# Its processes can change the checkout between check_checkout and the fetch.
check_no_container() {
  local co="$1" allow="$2" pid ctrs="" err="" errf
  pid="$(project_id "$co")"
  if ! command -v docker >/dev/null 2>&1; then
    err="docker is not installed, so cc-push cannot check"
  else
    errf="$(mktemp "${TMPDIR:-/tmp}/cc-push-docker.XXXXXX")"
    # Only stdout is the list: stderr may carry warnings. A hung docker would
    # otherwise block here with no word.
    if ! ctrs="$(timeout 20 docker ps --filter "label=cc-project=$pid" --format '{{.Names}}' 2>"$errf")"; then
      err="docker did not answer ($(head -n 1 "$errf" 2>/dev/null)), so cc-push cannot check"
      ctrs=""
    fi
    rm -f "$errf"
    ctrs="$(printf '%s\n' "$ctrs" | awk 'NF' | paste -sd ' ' -)"
  fi
  if [ -n "$ctrs" ]; then
    if [ -z "$allow" ]; then
      die "a cc-isolated container for $co is running ($ctrs). While it runs it can change the checkout between cc-push's checks and its fetch. Stop it first (docker stop $ctrs), then rerun; or pass --allow-running to go on anyway."
    fi
    say "WARNING: a cc-isolated container for $co is RUNNING ($ctrs), and --allow-running was given." >&2
    say "  It can change the checkout between cc-push's checks and its fetch, so what is fetched" >&2
    say "  may not be what was checked. Stop it (docker stop $ctrs) unless you know it is idle." >&2
  elif [ -n "$err" ]; then
    if [ -z "$allow" ]; then
      die "$err whether a cc-isolated container for $co (label cc-project=$pid) is still running; one could change the checkout between cc-push's checks and its fetch. Make sure none is (docker stop), then rerun with --allow-running."
    fi
    say "WARNING: $err whether a cc-isolated container for $co is running; going on (--allow-running)." >&2
  fi
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
    # A partial clone: remote.<name>.promisor or extensions.partialClone, as a
    # key at the start of a line or right after a section header (git reads
    # `[remote "o"] promisor = true`). partialCloneFilter is not matched.
    if LC_ALL=C grep -Eiq '(^|\])[[:space:]]*(promisor|partialclone)[[:space:]]*(=|$)' "$g/$f"; then
      die "$g/$f marks a partial clone (remote.*.promisor or extensions.partialClone): upload-pack there cannot send the objects the clone never downloaded, and cc-push will not let it fetch them, so the fetch would fail. cc-push supports only full clones: launch sessions on a full clone (git clone without --filter)."
    fi
  done
  # Git's own test (cc-gitdir.sh), after the checks above (they name the more
  # specific problem). If .git fails it, git's discovery goes on to the root.
  if ! gitdir_valid "$g"; then
    die "$g is not a valid git directory (its HEAD, objects/ or refs/ is missing or broken): git would look for a repository elsewhere, such as the checkout root. Restore it (compare with a fresh clone), then rerun."
  fi
  if looks_like_gitdir "$co"; then
    die "$co itself looks like a git directory (a HEAD next to objects/, or a commondir file): git can read the checkout root as a repository. Remove what the session planted there, then rerun."
  fi
}

# run_vis <command...>: run it with stdout and stderr through vis; its status.
run_vis() {
  local rc=0
  "$@" 2>&1 | vis || rc=$?
  return "$rc"
}

# err_vis <command...>: run it with only its stderr through vis (stdout untouched,
# for a caller capturing it); its status. For git calls whose error text can name
# a checkout ref.
err_vis() {
  local rc
  { "$@" 2>&1 1>&3 3>&- | vis >&2; rc="${PIPESTATUS[0]}"; } 3>&1
  return "$rc"
}

main() {
  local remote="" branch="" clone="" yes="" start="" allow_running=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --remote) [ $# -ge 2 ] || usage_die "--remote needs a URL"; remote="$2"; shift 2 ;;
      --branch) [ $# -ge 2 ] || usage_die "--branch needs a name"; branch="$2"; shift 2 ;;
      --clone)  [ $# -ge 2 ] || usage_die "--clone needs a directory"; clone="$2"; shift 2 ;;
      --yes)    yes=1; shift ;;
      --allow-running) allow_running=1; shift ;;
      --help|-h) usage; exit 0 ;;
      --) shift; break ;;
      -*) usage_die "unknown flag: $1" ;;
      *)  [ -z "$start" ] || usage_die "one checkout at a time"; start="$1"; shift ;;
    esac
  done
  # After `--`: at most one word, and only when no checkout was named before it.
  if [ $# -gt 0 ]; then
    [ $# -eq 1 ] && [ -z "$start" ] || usage_die "one checkout at a time"
    start="$1"
  fi

  check_git_version

  local co
  co="$(find_checkout "${start:-$PWD}")" \
    || die "no git checkout at or above ${start:-$PWD}. Name it: cc-push /path/to/checkout"
  case "$co" in *$'\n'*|*::*) die "refusing a checkout path holding a newline or '::'" ;; esac
  # The container first: while it runs, every check below could be undone.
  check_no_container "$co" "$allow_running"
  check_checkout "$co"

  local id name
  id="$(project_id "$co")"
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
    { err_vis hgit "$clone" config core.hooksPath /dev/null &&
      err_vis hgit "$clone" config remote.origin.url "$remote" &&
      err_vis hgit "$clone" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' &&
      printf '%s\n' "$co" > "$clone/cc-push-checkout"; } \
      || die "could not set up the host-only clone $clone"
    say "Created the host-only clone $clone (bare, hooks off) for $co."
  else
    [ -f "$clone/cc-push-checkout" ] || die "$clone exists but has no cc-push marker; pick another --clone"
    [ "$(cat "$clone/cc-push-checkout")" = "$co" ] \
      || die "$clone serves $(cat "$clone/cc-push-checkout"), not $co; pick another --clone"
    if [ -n "$remote" ]; then
      err_vis hgit "$clone" config remote.origin.url "$remote" || die "could not set the remote in $clone"
      say "Remote for $co set to: $remote (kept for later runs)"
    fi
  fi
  remote="$(err_vis hgit "$clone" config --get remote.origin.url)" || die "no remote.origin.url in $clone; rerun with --remote <url>"

  # 1. The branch, before anything is fetched: only it is copied to host disk.
  # Every ls-remote/fetch names the checkout's .git (checked above) directly:
  # upload-pack --strict uses that directory or fails, and never goes looking for
  # another repository. protocol.file.allow=always: a global
  # protocol.file.allow=never would refuse these local reads.
  local up=(-c protocol.file.allow=always) upl=(--upload-pack='git-upload-pack --strict')
  if [ -z "$branch" ]; then
    local sym
    # LC_ALL=C: a branch name need not be valid UTF-8, and `.` must match any byte.
    sym="$(hgit "$clone" "${up[@]}" ls-remote "${upl[@]}" --symref "$co/.git" HEAD 2>/dev/null | LC_ALL=C sed -n 's/^ref: refs\/heads\/\(.*\)\tHEAD$/\1/p')" || true
    [ -n "$sym" ] || die "the checkout's HEAD names no branch (detached?); pass --branch <name>"
    branch="$sym"
  fi
  ngit check-ref-format "refs/heads/$branch" || die "not a valid branch name: $branch"
  local src="refs/cc/heads/$branch" heads
  # check-ref-format forbids tabs and line breaks, so an exact match on the
  # tab-separated ref column is exact. The name goes through the environment,
  # not awk -v (which would expand escapes in it).
  heads="$(err_vis hgit "$clone" "${up[@]}" ls-remote "${upl[@]}" --heads "$co/.git")" \
    || die "could not list the branches of $co"
  printf '%s\n' "$heads" | CC_WANT="refs/heads/$branch" LC_ALL=C awk -F'\t' '$2 == ENVIRON["CC_WANT"] { f = 1 } END { exit !f }' \
    || die "the checkout has no branch $branch"

  # 2. That branch alone, into refs/cc/heads/<branch>. Git copies its refs and
  # objects; no submodules, no tags, no checkout.
  if ! run_vis hgit "$clone" "${up[@]}" fetch -q --no-tags --no-recurse-submodules \
         --no-write-fetch-head "${upl[@]}" \
         "$co/.git" "+refs/heads/$branch:$src" >&2; then
    die "could not fetch $branch from $co"
  fi
  hgit "$clone" rev-parse -q --verify "$src^{commit}" >/dev/null \
    || die "the checkout has no branch $branch"

  # 3. The real remote's current state, so the preview is against what is there.
  run_vis hgit "$clone" fetch -q --no-tags --no-recurse-submodules origin >&2 \
    || die "could not fetch from origin ($remote)"

  # 4. Preview. --no-ext-diff/--no-textconv: no diff program runs on the session's
  # files; --no-show-signature: no gpg on its signatures; output is plain text.
  local base="refs/remotes/origin/$branch" range commits
  say "Push $src ($co)"
  say "  to origin ($remote) as $branch."
  if hgit "$clone" rev-parse -q --verify "$base^{commit}" >/dev/null; then
    range="$base..$src"
    commits="$(err_vis hgit "$clone" rev-list "$range")" || die "could not list the commits in $range"
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
    # Ctrl-C at the prompt is a decline: exit 1 like `n`, never 130.
    trap 'echo; echo "Not pushed."; exit 1' INT
    printf 'Push these? [y/N] '
    read -r reply || reply=""
    trap - INT
    case "$reply" in
      [yY]|[yY][eE][sS]) ;;
      *) echo "Not pushed."; exit 1 ;;
    esac
  fi

  # 5. From the clone, with your credentials; hooks off. A non-fast-forward is
  # refused by the remote as usual: cc-push never forces. git's report (and the
  # remote's messages) name the branch, so they go through vis too.
  run_vis hgit "$clone" push origin "$src:refs/heads/$branch" \
    || die "the push of $branch to origin failed (see above); nothing was forced"
  say "Pushed $branch to origin."
}

# Main-execution guard: allow sourcing for tests. main runs in a subshell with
# errexit on, so an unexpected failure still exits 1 rather than git's own status
# (128 and so on): the exit codes stay 0, 1 and 2. The INT trap keeps this shell
# alive through a Ctrl-C so it can map the subshell's status; the subshell gets
# default INT handling back (bash resets trapped signals in a subshell).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set +e
  trap ':' INT
  ( set -e; main "$@" )
  rc=$?
  case "$rc" in
    0|1|2) exit "$rc" ;;
    130) echo "ERROR: cc-push was interrupted." >&2; exit 1 ;;
    *) echo "ERROR: cc-push stopped on an unexpected failure (status $rc)." >&2; exit 1 ;;
  esac
fi
