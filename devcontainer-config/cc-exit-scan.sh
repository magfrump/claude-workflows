# cc-exit-scan.sh — cc-isolated's session-exit scan (Q-069 [3], Q-076), sourced by
# cc-isolated.sh from the directory it is installed in; not run on its own. It
# defines functions and constants only. It ships with the launcher: install.sh's
# PAYLOAD installs it, enforcement_files() hashes it into the trust manifest, and
# hooks/live-verify-gate.sh gates commits to it.
# shellcheck shell=bash

# logical_workspace <start> <ws>: the checkout <ws> (physical, as git reports it)
# by the path you reached it on — <start> (or $PWD) with symlinks unresolved, up
# to the toplevel — or nothing when that route is not recoverable. Host git
# matches your includeIf "gitdir:" patterns against this form as well as the
# physical one, so the exit scan has to (the scan's _snap_cond).
logical_workspace() {
  local start="${1:-$PWD}" ws="$2" lstart pstart rel
  lstart="$(cd "$start" 2>/dev/null && pwd -L)" || return 0
  pstart="$(cd "$start" 2>/dev/null && pwd -P)" || return 0
  case "$pstart" in
    "$ws")   rel="" ;;
    "$ws"/*) rel="${pstart#"$ws"}" ;;
    *) return 0 ;;
  esac
  case "$lstart" in *"$rel") printf '%s' "${lstart%"$rel"}" ;; esac
}

# --- Exit scan: a tripwire for .git changes the container made -------------------
#
# WHY (Q-069 [3], Q-076). The container writes the checkout's .git through the bind
# mount. A plain host `git push` or `git status` then runs whatever hooks,
# core.fsmonitor, filter drivers, remote receive-pack commands or included config
# the session planted — as you, with your keys. The way to push is cc-push
# (cc-push.sh, next to this file): it fetches into a separate host-only clone and
# pushes from there, and runs no git command in the checkout (its fetch has git
# start upload-pack there, which reads refs, objects and config and runs nothing
# from them). This scan is a TRIPWIRE:
# main() snapshots what host git reads to decide what to run, before the session,
# and compares after claude exits; anything added, removed or changed is named, and
# the launcher exits 3 instead of 0. It catches the common plants. It cannot be
# complete (see LIMITS): a clean scan is not permission to run git in the checkout.
#
# WHAT IS SNAPSHOTTED. Content hashes (and modes, and symlink targets), not a list
# of dangerous keys: git grows exec-capable settings faster than any list. Recorded,
# for every git dir reached (the checkout's git dir and common dir; every git dir
# nested in one at modules/** or worktrees/*, found by its HEAD; every embedded
# `.git` in the working tree; every common dir a `commondir` file names; every
# local-path remote), by its fixed layout, never by a file name found anywhere:
#   config, config.worktree, commondir, info/attributes, the hooks dir and every
#   entry in it except *.sample, the legacy remotes/* and branches/* files, the
#   in-progress rebase-merge/, rebase-apply/ and sequencer/ state (a todo `exec`
#   line runs on `git rebase --continue`), and every symlink.
# Plus what those configs name: every core.hooksPath dir, include.path /
# includeIf.*.path target and core.attributesFile, and every remote that is a
# local path inside the checkout (remote.*.url/pushurl, remote.pushDefault,
# branch.*.remote/pushRemote naming a path, url.<base>.insteadOf bases, legacy
# remotes files; a relative path resolved in the working tree of the repo whose
# config names it), walked as a git dir: a push to it runs its hooks. And your own
# global/system config, read with its includes evaluated for each git dir
# (includeIf gitdir:/gitdir/i: matched here against the physical git dir and the
# one under the path you launched on, symlinks kept, as git matches both;
# onbranch:/hasconfig: taken as matching): a relative core.hooksPath or
# core.attributesFile there resolves in each working tree, the top level and every
# embedded repo. Only those three kinds of entry are followed in your own config;
# its other entries are not recorded (the container cannot write it).
# Any change to one of these is a finding, even an inert one such as user.name. The
# key list below only labels report lines.
#
# FAIL CLOSED. A directory that cannot be listed, a file that cannot be read, a
# config git cannot parse, or a file too large to hash (over 64 MiB, or past 1 GiB
# in all: _snap_size_ok) makes the snapshot fail: at launch the launcher refuses
# to start, at exit it returns 4. Git needs only search permission to run a hook,
# so an unlistable hooks dir must never read as "empty". A Ctrl-C during the exit
# scan also exits 4, saying the scan did not finish.
#
# THE SCAN RUNS NOTHING FROM THE REPO. The git dir is located by plain file reads
# (a `.git` file's `gitdir:` line, a `commondir`), never `git rev-parse` in the
# checkout. Config is read with `git config --file <f> --no-includes` from cwd /,
# so no repo is discovered and git follows no include (the scan reads each target
# itself). The rest is host tools reading files: find, stat, readlink, realpath,
# sha256sum, cat, tr, sort, awk, cut, mktemp, dirname and rm; find never follows
# symlinks (-P), and a symlink's target is hashed only when it is a regular file.
# Nothing refreshes an index, which is what starts fsmonitor and clean filters.
# (The launcher's own resolve_workspace runs `git rev-parse --show-toplevel` in the
# checkout before the baseline; that runs no hook or fsmonitor.)
#
# EVERY CONTAINER-CHOSEN STRING (names, values, error text) is reduced to printable
# ASCII, newlines included, before it reaches the terminal: paths and values in
# report lines are %q-quoted or have line breaks replaced, every error reason is
# written by _snap_fail (tools' own error text is dropped: it would quote a path
# raw), and whole messages go through scan_vis.
#
# LIMITS (also in guides/cc-isolated-usage.md). No finding does not mean safe:
#   - a hook present at launch that runs a tracked file (husky's
#     core.hooksPath=.husky/_, the pre-commit framework, `exec ./scripts/check.sh`):
#     the session edits the tracked file, nothing in .git changes;
#   - anything present at launch is the baseline, including an earlier session's
#     plant or rebase left in progress, and a config value naming a program by path
#     in the checkout (core.pager = ./tools/pager.sh) is recorded as a value, not
#     followed;
#   - the container keeps running after claude exits, so a process it left behind
#     can plant after the scan; a launcher killed before the scan (closed terminal,
#     SIGTERM) scans nothing;
#   - tracked .gitattributes and .gitmodules are not scanned (they select drivers
#     and URLs that config defines, but git also acts on .gitmodules itself on
#     `submodule update`); a driver your own global config defines (filter.lfs.*)
#     runs on session-written content with no finding;
#   - includeIf gitdir: is matched for the physical path and the path you launched
#     on; running git through yet another symlinked route can match a condition
#     the scan did not evaluate;
#   - time: hashing is capped per file and in total, but a session can still plant
#     many files (and many embedded repos) to make the scan slow. A scan you stop
#     with Ctrl-C exits 4; one you kill some other way scans nothing.
GIT_EXIT_SCAN_KEYS_RE='^(filter\.|core\.fsmonitor|include|hook\.|core\.hookspath|core\.sshcommand|core\.askpass|core\.pager|core\.editor|core\.gitproxy|core\.attributesfile|core\.worktree|sequence\.editor|pager\.|credential|diff\.|difftool\.|merge\.|mergetool\.|interactive\.|gpg\.|alias\.|submodule\.|protocol\.|remote\.|branch\..*\.(remote|pushremote)$|url\.|uploadpack\.|receive\.|sendemail\.|ssh\.|http\.|gc\.|web\.|browser\.|man\.|instaweb\.)'

# scan_git_dirs <ws>: print the git dir, then the common dir, of <ws>, from plain
# file reads. Returns 1 when either cannot be found.
scan_git_dirs() {
  local ws="$1" g line common
  g="$ws/.git"
  if [ -f "$g" ]; then
    # A linked worktree or submodule: `.git` is a file holding `gitdir: <path>`.
    # Read errors are dropped: their text would name a container-chosen path raw.
    line=""
    { IFS= read -r line < "$g"; } 2>/dev/null || true
    case "$line" in
      "gitdir: "*) g="${line#gitdir: }" ;;
      *) return 1 ;;
    esac
    case "$g" in /*) ;; *) g="$ws/$g" ;; esac
  fi
  [ -d "$g" ] || return 1
  common="$g"
  if [ -f "$g/commondir" ]; then
    line=""
    { IFS= read -r line < "$g/commondir"; } 2>/dev/null || true
    case "$line" in /*) common="$line" ;; *) common="$g/$line" ;; esac
  fi
  # Normalise (a worktree's commondir is usually "../.."): a plain cd, no git.
  g="$(cd "$g" 2>/dev/null && pwd -P)" || return 1
  common="$(cd "$common" 2>/dev/null && pwd -P)" || return 1
  printf '%s\n%s\n' "$g" "$common"
}

# The _snap_* helpers below run inside git_exec_snapshot and share its locals
# (bash dynamic scoping): _snap (the records), _snap_seen (walked dirs), _snap_ws,
# _snap_gd, _snap_common, _snap_tmp, _snap_names/_snap_rnames (remote names). Each
# returns 1 after printing a reason on stderr when something cannot be read.
# Records are tab-separated:
#   F <kind> <path %q> <attrs>     a file, dir or link host git reads
#   C <config %q> <key> <value>    one config entry (labels the report only)

# _snap_fail <printf format> <args...>: the reason on stderr, every byte outside
# printable ASCII (line breaks included) shown as '?'; returns 1.
_snap_fail() {
  local m
  # shellcheck disable=SC2059  # the format is always one of ours
  m="$(printf "$@")"
  printf '%s' "$m" | LC_ALL=C tr -c '[:print:]' '?' >&2
  echo >&2
  return 1
}

# _snap_hash <file>: the first 16 hex of its sha256. Reads, never runs.
_snap_hash() {
  local h
  if [ ! -r "$1" ] || ! h="$(sha256sum < "$1" 2>/dev/null)"; then
    _snap_fail 'cannot read %s' "$1"
    return 1
  fi
  printf '%s' "${h:0:16}"
}

# _snap_size_ok <file>: refuse to hash a file above GIT_EXIT_SCAN_MAX_FILE_BYTES,
# or once GIT_EXIT_SCAN_MAX_TOTAL_BYTES have been hashed in this snapshot: a
# session can plant a huge (or sparse, apparently huge) hook to stall the scan for
# hours, and a stalled scan gets killed, which is no scan. Too large reads as
# unreadable (fail closed, exit 4): treat the checkout as unsafe. The size is
# stat's apparent size (a sparse file counts in full); -L: a link's target.
GIT_EXIT_SCAN_MAX_FILE_BYTES=$((64 * 1024 * 1024))
GIT_EXIT_SCAN_MAX_TOTAL_BYTES=$((1024 * 1024 * 1024))
_snap_size_ok() {
  local s
  s="$(stat -L -c %s -- "$1" 2>/dev/null)" || { _snap_fail 'cannot stat %s' "$1"; return 1; }
  if [ "$s" -gt "$GIT_EXIT_SCAN_MAX_FILE_BYTES" ]; then
    _snap_fail '%s is too large to hash (%s bytes, over %s): treat the checkout as unsafe' \
      "$1" "$s" "$GIT_EXIT_SCAN_MAX_FILE_BYTES"
    return 1
  fi
  _snap_bytes=$((_snap_bytes + s))
  if [ "$_snap_bytes" -gt "$GIT_EXIT_SCAN_MAX_TOTAL_BYTES" ]; then
    _snap_fail 'more than %s bytes to hash (at %s): too much to hash, treat the checkout as unsafe' \
      "$GIT_EXIT_SCAN_MAX_TOTAL_BYTES" "$1"
    return 1
  fi
}

# _snap_file <kind> <path>: record <path> without following it. A symlink is
# recorded with its target string, plus the target's hash when that is a regular
# file; when it resolves to a directory, _snap_linkdir is set to it so the caller
# can decide whether to walk it. A missing path is recorded as missing, so
# creating it later is a change.
_snap_file() {
  local kind="$1" p="$2" attrs h t m
  _snap_linkdir=""
  # Tool errors are dropped (2>/dev/null) and replaced by _snap_fail: their text
  # would name the container-chosen path with its line breaks.
  if [ -L "$p" ]; then
    t="$(readlink -- "$p" 2>/dev/null)" || { _snap_fail 'cannot read link %s' "$p"; return 1; }
    attrs="link -> $(printf '%q' "$t")"
    if [ -f "$p" ]; then
      _snap_size_ok "$p" || return 1
      h="$(_snap_hash "$p")" || return 1
      attrs+=" file $h"
    elif [ -d "$p" ]; then
      _snap_linkdir="$(cd "$p" 2>/dev/null && pwd -P)" \
        || { _snap_fail 'cannot enter %s' "$p"; return 1; }
      attrs+=" dir"
    elif [ -e "$p" ]; then
      attrs+=" other"
    else
      attrs+=" dangling"
    fi
  elif [ -f "$p" ]; then
    _snap_size_ok "$p" || return 1
    h="$(_snap_hash "$p")" || return 1
    m="$(stat -c %a -- "$p" 2>/dev/null)" || { _snap_fail 'cannot stat %s' "$p"; return 1; }
    attrs="file $m $h"
  elif [ -d "$p" ]; then
    m="$(stat -c %a -- "$p" 2>/dev/null)" || { _snap_fail 'cannot stat %s' "$p"; return 1; }
    attrs="dir $m"
  elif [ -e "$p" ]; then
    m="$(stat -c '%F %a' -- "$p" 2>/dev/null)" || { _snap_fail 'cannot stat %s' "$p"; return 1; }
    attrs="other $m"   # fifo, socket, device
  else
    attrs="missing"
  fi
  _snap+="F"$'\t'"$kind"$'\t'"$(printf '%q' "$p")"$'\t'"$attrs"$'\n'
}

# _snap_opt <kind> <path>: _snap_file, but only for a path that exists (so one
# created later reads as "+ new").
_snap_opt() {
  _snap_linkdir=""
  if [ -e "$2" ] || [ -L "$2" ]; then _snap_file "$1" "$2"; fi
}

# _snap_find <out> <find args...>: run find into <out> (NUL-separated). A find
# that cannot list a directory fails the snapshot: unlistable is not empty.
_snap_find() {
  local out="$1"; shift
  if ! find -P "$@" -print0 > "$out" 2> "$out.err"; then
    _snap_fail 'cannot list everything under %s: %s' "$1" "$(cat "$out.err")"
    return 1
  fi
}

# _snap_path <value> <base>: a config path value as git resolves it.
_snap_path() {
  # shellcheck disable=SC2088  # matching a literal "~/" in the config value
  case "$1" in
    "~/"*) printf '%s' "$HOME/${1#"~/"}" ;;
    /*)    printf '%s' "$1" ;;
    *)     printf '%s' "$2/$1" ;;
  esac
}

# _snap_inside_ws <path>: whether <path> (existing or not) resolves inside the
# checkout — the only tree the container can write.
_snap_inside_ws() {
  local r
  r="$(realpath -m -- "$1" 2>/dev/null)" || return 1
  case "$r/" in "$_snap_ws"/*) return 0 ;; esac
  return 1
}

# _snap_hooks <dir>: a hooks dir and every entry git could run from it.
_snap_hooks() {
  local d="$1" real list f
  _snap_file hooksdir "$d" || return 1
  [ -z "$_snap_linkdir" ] || d="$_snap_linkdir"
  [ -d "$d" ] || return 0   # recorded as missing: creating it is a change
  real="$(cd "$d" 2>/dev/null && pwd -P)" || { _snap_fail 'cannot enter %s' "$d"; return 1; }
  [ -z "${_snap_seen["h:$real"]:-}" ] || return 0
  _snap_seen["h:$real"]=1
  list="$_snap_tmp/h.${#_snap_seen[@]}"
  _snap_find "$list" "$real" -mindepth 1 -maxdepth 1 ! -name '*.sample' || return 1
  while IFS= read -r -d '' f; do
    _snap_file hook "$f" || return 1
  done < "$list"
}

# _snap_worktree_of <config file>: the working tree a relative core.hooksPath in
# that config is resolved against.
_snap_worktree_of() {
  local gd v
  gd="$(cd "$(dirname -- "$1")" 2>/dev/null && pwd -P)" || gd="$(dirname -- "$1")"
  if [ "$gd" = "$_snap_gd" ] || [ "$gd" = "$_snap_common" ]; then
    printf '%s' "$_snap_ws"
  elif v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree 2>/dev/null)"; then
    _snap_path "$v" "$gd"
  elif [ "${gd##*/}" = .git ]; then
    printf '%s' "${gd%/*}"
  else
    printf '%s' "$gd"
  fi
}

# _snap_remote <url> [<working tree>]: a remote that is a local path inside the
# checkout is a git dir whose hooks and receive-pack a host push runs. Git's rule
# (transport.c, url_is_local_not_ssh): "scheme://" is a URL, and a ':' before any
# '/' is host:path over ssh; anything else, including sub/a:b, is a local path,
# relative to the working tree of the repo whose config names it (git runs there):
# an embedded repo's ./x.git is <embedded repo>/x.git, not <checkout>/x.git. The
# working tree defaults to the checkout's. For <p> git tries <p>/.git, <p>,
# <p>.git/.git and <p>.git (enter_repo), so both <p> and <p>.git are walked. A
# local path outside the checkout is not writable by the container.
_snap_remote() {
  local p="$1" base="${2:-$_snap_ws}" c
  case "$p" in
    "") return 0 ;;
    file://localhost/*) p="${p#file://localhost}" ;;
    file://*) p="${p#file://}" ;;
    *://*) return 0 ;;
  esac
  if [[ "$p" == *:* ]] && [[ "${p%%:*}" != */* ]]; then return 0; fi
  case "$p" in /*) ;; *) p="$base/$p" ;; esac
  for c in "$p" "$p.git"; do
    _snap_inside_ws "$c" || continue
    _snap_file remote "$c" || return 1
    [ -z "$_snap_linkdir" ] || c="$_snap_linkdir"
    if [ -e "$c/.git" ] || [ -L "$c/.git" ]; then
      _snap_dotgit "$c/.git" || return 1
    elif [ -e "$c/HEAD" ]; then
      _snap_gitdir "$c" || return 1
    fi
  done
}

# _snap_config <file>: every entry (as C records), and what the entries point at.
_snap_config() {
  local f="$1" base="${2:-}" real out rec key val t name
  # The working tree its relative paths resolve in; an include target inherits
  # the including repo's.
  [ -n "$base" ] || base="$(_snap_worktree_of "$f")"
  real="$(realpath -m -- "$f" 2>/dev/null)" || real="$f"
  [ -z "${_snap_seen["c:$real"]:-}" ] || return 0
  _snap_seen["c:$real"]=1
  out="$_snap_tmp/c.${#_snap_seen[@]}"
  if ! (cd / && git --no-pager config --file "$f" --no-includes --null --list) > "$out" 2> "$out.err"; then
    _snap_fail 'could not read config %s: %s' "$f" "$(cat "$out.err")"
    return 1
  fi
  while IFS= read -r -d '' rec; do
    key="${rec%%$'\n'*}"
    val=""
    [[ "$rec" != *$'\n'* ]] || val="${rec#*$'\n'}"
    t="${val//$'\n'/?}"
    _snap+="C"$'\t'"$(printf '%q' "$f")"$'\t'"${key//$'\t'/?} ${t//$'\t'/?}"$'\n'
    case "$key" in
      core.hookspath)
        [ -z "$val" ] || _snap_hooks "$(_snap_path "$val" "$base")" || return 1 ;;
      include.path|includeif.*.path)
        [ -n "$val" ] || continue
        t="$(_snap_path "$val" "$(dirname -- "$f")")"
        _snap_file include "$t" || return 1
        if [ -f "$t" ]; then _snap_config "$t" "$base" || return 1; fi ;;
      core.attributesfile)
        [ -z "$val" ] || _snap_file attributes "$(_snap_path "$val" "$base")" || return 1 ;;
      remote.pushdefault|branch.*.remote|branch.*.pushremote)
        # A remote name, or a URL/path when no remote has that name: decided once
        # every config is read (git_exec_snapshot), in this config's working tree.
        _snap_names+=("$val")
        _snap_nbases+=("$base") ;;
      remote.*.*)
        name="${key#remote.}"; name="${name%.*}"
        [ -z "$name" ] || _snap_rnames["$name"]=1
        case "$key" in
          remote.*.url|remote.*.pushurl) _snap_remote "$val" "$base" || return 1 ;;
        esac ;;
      url.*.insteadof|url.*.pushinsteadof)
        # url.<base>.insteadOf rewrites matching URLs to <base>.
        t="${key#url.}"; t="${t%.*}"
        _snap_remote "$t" "$base" || return 1 ;;
    esac
  done < "$out"
}

# _snap_glob_re <pattern>: git's wildmatch (WM_PATHNAME) as an anchored ERE.
# Returns 1 for a pattern with a bracket expression: the caller then treats the
# condition as matching rather than guess.
_snap_glob_re() {
  local pat="$1" re="" c i n=${#1}
  [[ "$pat" != *'['* ]] || return 1
  for ((i = 0; i < n; i++)); do
    c="${pat:i:1}"
    case "$c" in
      '*')
        if [ "${pat:i+1:1}" = '*' ]; then
          if [ "${pat:i+2:1}" = / ]; then re+='(.*/)?'; i=$((i + 2)); else re+='.*'; i=$((i + 1)); fi
        else
          re+='[^/]*'
        fi ;;
      '?') re+='[^/]' ;;
      [a-zA-Z0-9/_~-]) re+="$c" ;;
      '^') re+='\^' ;;
      *) re+="[$c]" ;;
    esac
  done
  printf '^%s$' "$re"
}

# _snap_logical <path>: <path> (physical, inside the checkout) as seen from the
# logical checkout path _snap_lws — the path you launched on, symlinks kept —
# or nothing when there is none or it is the physical path.
_snap_logical() {
  [ -n "${_snap_lws:-}" ] && [ "$_snap_lws" != "$_snap_ws" ] || return 0
  case "$1" in
    "$_snap_ws") printf '%s' "$_snap_lws" ;;
    "$_snap_ws"/*) printf '%s' "$_snap_lws${1#"$_snap_ws"}" ;;
  esac
}

# _snap_cond <condition> <including file> <git dir> <logical git dir>: 0 when an
# includeIf condition applies to the repo whose git dir is given (config.c,
# include_by_gitdir). Git matches the pattern against the git dir as an absolute
# path WITHOUT resolving symlinks (from $PWD, so a checkout reached through a
# symlinked directory keeps that route) and then against its realpath; both are
# tried here, the first as the logical checkout path (_snap_lws) gives it.
# onbranch:, hasconfig: and anything unknown count as matching: walking a target
# git might not include costs nothing.
_snap_cond() {
  local cond="$1" from="$2" gd="$3" lgd="$4" pat icase="" re
  local lg1 lg2
  lg1="$(_snap_logical "$gd")"; lg2="$(_snap_logical "$lgd")"
  case "$cond" in
    gitdir:*)   pat="${cond#gitdir:}" ;;
    gitdir/i:*) pat="${cond#gitdir/i:}"; icase=1 ;;
    *) return 0 ;;
  esac
  # shellcheck disable=SC2088  # matching a literal "~/" in the pattern
  case "$pat" in
    "~/"*) pat="$HOME/${pat#"~/"}" ;;
    ./*)   pat="$(dirname -- "$from")/${pat#./}" ;;
    /*)    ;;
    *)     pat="**/$pat" ;;
  esac
  case "$pat" in */) pat+='**' ;; esac
  re="$(_snap_glob_re "$pat")" || return 0
  if [ -n "$icase" ]; then re="${re,,}"; gd="${gd,,}"; lgd="${lgd,,}"; lg1="${lg1,,}"; lg2="${lg2,,}"; fi
  [[ "$gd" =~ $re ]] || [[ "$lgd" =~ $re ]] \
    || { [ -n "$lg1" ] && [[ "$lg1" =~ $re ]]; } || { [ -n "$lg2" ] && [[ "$lg2" =~ $re ]]; }
}

# _snap_host_config <git dir> <logical git dir> <working tree> [<file> <depth>]:
# your own global and system config (read from /, so no repo is discovered), with
# its includes followed here and includeIf conditions evaluated for this git dir,
# as git would for a command run in <working tree>. A relative core.hooksPath or
# core.attributesFile there resolves inside the checkout; walk those. Entries are
# not recorded (the container cannot write these files, and they are yours to
# change mid-session), except in an include target that is inside the checkout.
_snap_host_config() {
  local gd="$1" lgd="$2" wt="$3" file="${4:-}" depth="${5:-0}" out origin rec key val t cond
  local -a src=()
  [ "$depth" -le 10 ] || return 0   # git's own include depth limit
  [ -z "$file" ] || src=(--file "$file")
  out="$_snap_tmp/host.$depth.${#_snap_seen[@]}.$RANDOM"
  if ! (cd / && git --no-pager config "${src[@]}" --no-includes --show-origin --null --list) > "$out" 2> "$out.err"; then
    _snap_fail 'could not read your git config%s: %s' "${file:+ $file}" "$(cat "$out.err")"
    return 1
  fi
  while IFS= read -r -d '' origin && IFS= read -r -d '' rec; do
    key="${rec%%$'\n'*}"
    val=""
    [[ "$rec" != *$'\n'* ]] || val="${rec#*$'\n'}"
    [ -n "$val" ] || continue
    origin="${origin#file:}"
    case "$key" in
      core.hookspath)
        t="$(_snap_path "$val" "$wt")"
        if _snap_inside_ws "$t"; then _snap_hooks "$t" || return 1; fi ;;
      core.attributesfile)
        t="$(_snap_path "$val" "$wt")"
        if _snap_inside_ws "$t"; then _snap_file attributes "$t" || return 1; fi ;;
      include.path|includeif.*.path)
        if [ "$key" != include.path ]; then
          cond="${key#includeif.}"; cond="${cond%.path}"
          _snap_cond "$cond" "$origin" "$gd" "$lgd" || continue
        fi
        t="$(_snap_path "$val" "$(dirname -- "$origin")")"
        if _snap_inside_ws "$t"; then
          _snap_file include "$t" || return 1
          if [ -f "$t" ]; then _snap_config "$t" "$wt" || return 1; fi
        fi
        if [ -f "$t" ]; then _snap_host_config "$gd" "$lgd" "$wt" "$t" $((depth + 1)) || return 1; fi ;;
    esac
  done < "$out"
}

# _snap_dotgit_target <path of a .git entry>: the git dir it names (a dir, a
# `gitdir:` file, or a link), or nothing.
_snap_dotgit_target() {
  local p="$1" line g
  if [ -d "$p" ]; then
    g="$p"
  elif [ -f "$p" ]; then
    line=""
    { IFS= read -r line < "$p"; } 2>/dev/null || true
    case "$line" in "gitdir: "*) g="${line#gitdir: }" ;; *) return 0 ;; esac
    case "$g" in /*) ;; *) g="${p%/*}/$g" ;; esac
  else
    return 0
  fi
  [ -d "$g" ] || return 0
  (cd "$g" 2>/dev/null && pwd -P) || true
}

# _snap_nested <dir>: the git dirs under <dir> (a modules/ or worktrees/ dir, or a
# linked dir in the checkout): each directory holding HEAD next to objects/ or a
# commondir file, at any depth (submodule names contain slashes).
_snap_nested() {
  local d="$1" real list f g
  [ -d "$d" ] && [ ! -L "$d" ] || return 0   # a link is walked by the link loop
  real="$(cd "$d" 2>/dev/null && pwd -P)" || { _snap_fail 'cannot enter %s' "$d"; return 1; }
  [ -z "${_snap_seen["n:$real"]:-}" ] || return 0
  _snap_seen["n:$real"]=1
  list="$_snap_tmp/n.${#_snap_seen[@]}"
  _snap_find "$list" "$real" -mindepth 2 -name HEAD || return 1
  while IFS= read -r -d '' f; do
    g="${f%/*}"
    if [ -d "$g/objects" ] || [ -f "$g/commondir" ]; then _snap_gitdir "$g" || return 1; fi
  done < "$list"
}

# _snap_gitdir <dir>: everything exec-relevant in one git dir, by its fixed layout
# (never by a name found anywhere under it: a branch named `config` or `hooks`, or
# a checkout under a directory named hooks, is not a git file), then the common
# dir its commondir names and the git dirs nested in it.
_snap_gitdir() {
  local real list f line c name d body
  real="$(cd "$1" 2>/dev/null && pwd -P)" || { _snap_fail 'cannot enter %s' "$1"; return 1; }
  [ -z "${_snap_seen["g:$real"]:-}" ] || return 0
  _snap_seen["g:$real"]=1
  for f in config config.worktree; do
    _snap_opt config "$real/$f" || return 1
    if [ -f "$real/$f" ]; then _snap_config "$real/$f" || return 1; fi
  done
  _snap_opt attributes "$real/info/attributes" || return 1
  _snap_hooks "$real/hooks" || return 1
  _snap_opt commondir-file "$real/commondir" || return 1
  if [ -f "$real/commondir" ]; then
    # A nested worktree's common dir can be a bare repo in the checkout not named
    # .git; walk it (the checkout's own common dir is walked by the caller).
    line=""
    { IFS= read -r line < "$real/commondir"; } 2>/dev/null || true
    case "$line" in /*) c="$line" ;; *) c="$real/$line" ;; esac
    if [ -n "$line" ] && [ -d "$c" ] && _snap_inside_ws "$c"; then _snap_gitdir "$c" || return 1; fi
  fi
  # Legacy remotes: remotes/<name> ("URL: <url>" lines), branches/<name> ("<url>#<branch>"),
  # a relative path resolved in this git dir's working tree, as git would.
  for d in remotes branches; do
    [ -d "$real/$d" ] || continue
    list="$_snap_tmp/r.${#_snap_seen[@]}.$d"
    _snap_find "$list" "$real/$d" -mindepth 1 ! -type d || return 1
    while IFS= read -r -d '' f; do
      _snap_file legacy-remote "$f" || return 1
      name="${f#"$real/$d/"}"
      _snap_rnames["$name"]=1
      [ -f "$f" ] || continue
      # Read in one go (the hash above proved it readable); a read error's text
      # would name the container-chosen path raw.
      body="$(cat -- "$f" 2>/dev/null)" || { _snap_fail 'cannot read %s' "$f"; return 1; }
      while IFS= read -r line || [ -n "$line" ]; do
        if [ "$d" = branches ]; then
          _snap_remote "${line%%#*}" "$(_snap_worktree_of "$real/config")" || return 1
          break
        fi
        case "$line" in URL:*) line="${line#URL:}"; _snap_remote "${line#"${line%%[![:space:]]*}"}" "$(_snap_worktree_of "$real/config")" || return 1 ;; esac
      done <<< "$body"
    done < "$list"
  done
  # An interrupted rebase, cherry-pick or revert: its todo list runs on --continue.
  for d in rebase-merge rebase-apply sequencer; do
    [ -d "$real/$d" ] || continue
    list="$_snap_tmp/s.${#_snap_seen[@]}.$d"
    _snap_find "$list" "$real/$d" ! -type d || return 1
    while IFS= read -r -d '' f; do
      _snap_file sequencer "$f" || return 1
    done < "$list"
  done
  # Every symlink (git follows them); a linked dir inside the checkout is searched
  # for git dirs too. Hooks were recorded above.
  list="$_snap_tmp/l.${#_snap_seen[@]}"
  _snap_find "$list" "$real" -type l || return 1
  while IFS= read -r -d '' f; do
    [ "${f%/*}" != "$real/hooks" ] || continue
    _snap_file link "$f" || return 1
    if [ -n "$_snap_linkdir" ] && _snap_inside_ws "$_snap_linkdir"; then
      c="$_snap_linkdir"
      if [ -e "$c/HEAD" ]; then _snap_gitdir "$c" || return 1; fi
      _snap_nested "$c" || return 1
    fi
  done < "$list"
  _snap_nested "$real/modules" || return 1
  _snap_nested "$real/worktrees"
}

# _snap_dotgit <path>: a `.git` entry — a git dir, a `gitdir:` file, or a link.
_snap_dotgit() {
  local p="$1" g
  _snap_file dotgit "$p" || return 1
  g="$(_snap_dotgit_target "$p")"
  [ -z "$g" ] || _snap_gitdir "$g"
}

# git_exec_snapshot <ws> [<logical ws>]: the records above for <ws>, sorted
# (LC_ALL=C) so two snapshots compare line by line. <logical ws> is the same
# checkout by the path you reach it on, symlinks unresolved (logical_workspace);
# your includeIf gitdir: conditions are matched against it too. Lines are raw
# (values may hold control bytes the container chose); show them only through
# scan_vis. Returns 1, with a reason on stderr, when any part cannot be read. Every
# reason goes through _snap_fail, so none can hold a line break.
git_exec_snapshot() {
  local ws="$1" _snap_lws="${2:-}" dirs _snap="" _snap_gd _snap_common _snap_ws _snap_tmp _snap_linkdir="" rc=0 list f g i
  local _snap_bytes=0
  local -A _snap_seen=() _snap_rnames=()
  local -a _snap_names=() _snap_nbases=()
  if ! dirs="$(scan_git_dirs "$ws")"; then
    _snap_fail 'cannot locate the git directory of %s from its .git entry' "$ws"
    return 1
  fi
  _snap_gd="${dirs%%$'\n'*}"
  _snap_common="${dirs#*$'\n'}"
  _snap_ws="$(cd "$ws" 2>/dev/null && pwd -P)" || { _snap_fail 'cannot enter %s' "$ws"; return 1; }
  if [ ! -f "$_snap_common/config" ]; then
    # The common dir is whatever `commondir` names: the container's choice.
    _snap_fail 'no git config at %s/config' "$_snap_common"
    return 1
  fi
  # The resolved dirs are records too: repointing `.git` or `commondir` shows up.
  _snap+="F"$'\t'"gitdir"$'\t'"$(printf '%q' "$ws/.git")"$'\t'"$(printf '%q' "$_snap_gd")"$'\n'
  _snap+="F"$'\t'"commondir"$'\t'"$(printf '%q' "$ws/.git")"$'\t'"$(printf '%q' "$_snap_common")"$'\n'
  _snap_tmp="$(mktemp -d)"
  {
    _snap_dotgit "$ws/.git" &&
    _snap_gitdir "$_snap_gd" &&
    _snap_gitdir "$_snap_common" &&
    _snap_host_config "$_snap_gd" "$_snap_ws/.git" "$_snap_ws" &&
    # Embedded repos anywhere in the working tree, each with your host config as
    # it applies there.
    list="$_snap_tmp/worktree" &&
    _snap_find "$list" "$_snap_ws" -mindepth 2 -name .git
  } || rc=1
  if [ "$rc" -eq 0 ]; then
    while IFS= read -r -d '' f; do
      [ "$f" != "$_snap_ws/.git" ] || continue
      _snap_dotgit "$f" || { rc=1; break; }
      g="$(_snap_dotgit_target "$f")"
      [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}" || { rc=1; break; }
    done < "$list"
  fi
  # Remote names that no remote defines are URLs or paths to git (remote.c).
  # Walking one can reach configs that name more, hence the growing index.
  i=0
  while [ "$rc" -eq 0 ] && [ "$i" -lt "${#_snap_names[@]}" ]; do
    f="${_snap_names[$i]}"
    g="${_snap_nbases[$i]}"
    i=$((i + 1))
    [ -z "$f" ] || [ -n "${_snap_rnames["$f"]:-}" ] || _snap_remote "$f" "$g" || rc=1
  done
  rm -rf "$_snap_tmp"
  [ "$rc" -eq 0 ] || return 1
  printf '%s' "$_snap" | LC_ALL=C sort -u
}

# scan_vis: make control bytes visible as '?' so a container-chosen hook name or
# config value cannot rewrite the terminal around the warning. Newlines pass, so
# only whole messages go through here; every container-chosen string in them has
# already lost its line breaks (%q, _snap_fail, or the C-record replacement).
scan_vis() {
  LC_ALL=C tr -c '[:print:]\n' '?'
}

# scan_diff <before> <after>: the report lines for everything that differs. Files
# first (+ new, - gone, ~ changed); under a changed config file, its added and
# removed entries, with keys the label list knows marked "<- can run a program".
scan_diff() {
  SCAN_KEYS_RE="$GIT_EXIT_SCAN_KEYS_RE" LC_ALL=C awk -F'\t' '
    function note(key) { return (tolower(key) ~ ENVIRON["SCAN_KEYS_RE"]) ? "   <- can run a program" : "" }
    FNR == NR { if ($1 == "F") b[$2 FS $3] = $4; else if ($1 == "C") bc[$0] = 1; next }
    { if ($1 == "F") a[$2 FS $3] = $4; else if ($1 == "C") ac[$0] = 1 }
    END {
      for (k in a) {
        split(k, p, FS)
        if (!(k in b))        { print p[2] "\t0\t    + " p[1] " " p[2] "  " a[k] }
        else if (a[k] != b[k]) { print p[2] "\t0\t    ~ " p[1] " " p[2] "  " a[k] }
      }
      for (k in b) if (!(k in a)) { split(k, p, FS); print p[2] "\t0\t    - " p[1] " " p[2] "  " b[k] }
      # Entries sort under the line of the config file they sit in (same path).
      for (e in ac) if (!(e in bc)) { split(e, p, FS); print p[2] "\t1\t        + " p[3] note(substr(p[3], 1, index(p[3] " ", " ") - 1)) }
      for (e in bc) if (!(e in ac)) { split(e, p, FS); print p[2] "\t2\t        - " p[3] }
    }' <(printf '%s\n' "$1") <(printf '%s\n' "$2") \
    | LC_ALL=C sort -t $'\t' -k1,1 -k2,2n -k3 | cut -f3-
}

# git_exit_scan <ws> <launch snapshot> [<logical ws>]: 0 when nothing the tripwire
# records changed; 1 (warning on stderr, naming each item) when something did; 2
# when the exit state could not be read. 0 is not "safe": see LIMITS above.
# <logical ws> must be what the launch snapshot was taken with.
git_exit_scan() {
  local ws="$1" before="$2" lws="${3:-}" after changes errf reason
  errf="$(mktemp)"
  if ! after="$(git_exec_snapshot "$ws" "$lws" 2>"$errf")"; then
    reason="$(cat "$errf")"
    rm -f "$errf"
    {
      echo "WARNING: the exit scan could not read everything it checks in $ws (its git"
      echo "  dirs, its working tree and what their config names):"
      printf '%s\n' "$reason" | sed 's/^/    /'
      echo "  Git may still be able to run what the scan could not list (a hook needs only"
      echo "  search permission). Treat the checkout as untrusted: do not run git in it on"
      echo "  the host. Push with cc-push, which fetches into a separate host-only clone"
      echo "  and pushes from there:  cc-push $ws"
      echo "  (guides/cc-isolated-usage.md, \"Pushing: cc-push\")."
    } | scan_vis >&2
    return 2
  fi
  rm -f "$errf"
  [ "$before" != "$after" ] || return 0
  changes="$(scan_diff "$before" "$after")"
  [ -n "$changes" ] || return 0
  {
    echo
    echo "WARNING: this session changed what HOST git reads in $ws to decide which"
    echo "  programs to run (hooks, config, attributes, submodule and nested git dirs,"
    echo "  local remotes, rebase todo lists). Any of these can make git run a program"
    echo "  as you, with your keys. Since launch (+ new, - removed, ~ changed):"
    printf '%s\n' "$changes"
    echo "  Do not run git in this checkout on the host (not even \`git status\`). Push"
    echo "  with cc-push, which fetches into a separate host-only clone and pushes from"
    echo "  there, running nothing from this checkout:  cc-push $ws"
    echo "  To use the checkout with host git again, first check each item and undo what"
    echo "  you did not make:"
    echo "    a config entry  ->  git config --file <file> --unset-all <key>"
    echo "    a hook or file  ->  rm <path> (or restore it)"
    echo "    gitdir/commondir -> .git (or its commondir) was repointed; restore it"
    echo "  \`git -c core.hooksPath=/dev/null -c core.fsmonitor=false push\` is NOT a safe"
    echo "  alternative: it still runs remote.*.receivepack, a repointed remote's hooks,"
    echo "  credential helpers and core.sshCommand, from included config files too."
    echo "  See guides/cc-isolated-usage.md, \"Pushing: cc-push\"."
  } | scan_vis >&2
  return 1
}

# scan_interrupted: the INT trap while the exit scan runs.
scan_interrupted() {
  {
    echo
    echo "WARNING: the exit scan was interrupted, so it checked nothing. Treat the"
    echo "  checkout as untrusted: do not run git in it on the host. Push with cc-push"
    echo "  (guides/cc-isolated-usage.md, \"Pushing: cc-push\")."
  } >&2
  exit 4
}
