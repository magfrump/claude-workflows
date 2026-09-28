# cc-gitdir.sh — is this directory a git directory? Plain file tests, no git run
# (Q-076). Sourced by cc-push.sh and cc-exit-scan.sh from the directory they are
# installed in; not run on its own. It defines functions only. It ships with the
# launcher: install.sh's PAYLOAD installs it, enforcement_files() hashes it into
# the trust manifest, and hooks/live-verify-gate.sh gates commits to it.
#
# WHY. Both tools look only at <checkout>/.git. Git does not: when .git is not a
# valid git directory, discovery goes on to ask whether the checkout ROOT is one
# (a bare repository: HEAD, objects/ and refs/ right there) and uses that instead.
# A session can empty .git's HEAD and plant a repository in the working tree, and
# host git would read config, hooks and objects the tools never looked at. So
# they first confirm .git is what git itself would accept (gitdir_valid) and that
# the root does not look like a repository (looks_like_gitdir).
# shellcheck shell=bash

# gitdir_head_kind <dir>: what <dir>/HEAD is, as git 2.39's validate_headref
# (setup.c) reads it — `symlink` (a symlink whose target starts with refs/),
# `symref` (a regular file reading `ref:`, optional whitespace, then refs/...),
# `detached` (a regular file starting with 40 hex digits), or `invalid`
# (anything else: missing, a dangling or foreign symlink, a FIFO or other
# non-regular file, garbage). Never the ref it names: a branch switch keeps the
# kind. Stricter than git in one way: a regular HEAD over 255 bytes is invalid
# (git reads only the first 255; no git writes one that long).
gitdir_head_kind() {
  local h="$1/HEAD" t s buf rest
  local LC_ALL=C   # [:space:] is C isspace(); byte-wise matching
  if [ -L "$h" ]; then
    t="$(readlink -- "$h" 2>/dev/null)" || { echo invalid; return 0; }
    case "$t" in refs/*) echo symlink ;; *) echo invalid ;; esac
    return 0
  fi
  # A FIFO would block the read; a device or socket is not a HEAD either.
  [ -f "$h" ] && [ -r "$h" ] || { echo invalid; return 0; }
  s="$(stat -c %s -- "$h" 2>/dev/null)" || { echo invalid; return 0; }
  [ "$s" -le 255 ] || { echo invalid; return 0; }
  # Up to the first NUL, as git's C string ends there.
  buf=""
  IFS= read -r -d '' buf < "$h" 2>/dev/null || true
  case "$buf" in
    ref:*)
      rest="${buf#ref:}"
      rest="${rest#"${rest%%[![:space:]]*}"}"
      case "$rest" in refs/*) echo symref; return 0 ;; esac ;;
  esac
  if [[ "$buf" =~ ^[0-9a-fA-F]{40} ]]; then echo detached; return 0; fi
  echo invalid
}

# gitdir_common <dir>: the common dir git would use for <dir> (setup.c
# get_common_dir_noenv): <dir> itself, or the path its commondir file names,
# trailing CR/LF trimmed, relative to <dir>. Returns 1 when commondir exists but
# cannot be read safely (not a regular file, unreadable, empty, over 4096 bytes):
# git dies on the empty and unreadable cases.
gitdir_common() {
  local d="$1" c="$1/commondir" s line
  if [ ! -e "$c" ] && [ ! -L "$c" ]; then printf '%s' "$d"; return 0; fi
  [ -f "$c" ] && [ -r "$c" ] || return 1
  s="$(stat -c %s -- "$c" 2>/dev/null)" || return 1
  [ "$s" -gt 0 ] && [ "$s" -le 4096 ] || return 1
  line=""
  if ! IFS= read -r -d '' line < "$c" 2>/dev/null; then
    # No NUL: the whole file, trailing line breaks trimmed.
    while :; do
      case "$line" in *$'\n'|*$'\r') line="${line%?}" ;; *) break ;; esac
    done
  fi
  case "$line" in /*) printf '%s' "$line" ;; *) printf '%s/%s' "$d" "$line" ;; esac
}

# gitdir_valid <dir>: 0 when git 2.39 (setup.c is_git_directory) would accept
# <dir> as a git directory: HEAD passes validate_headref (gitdir_head_kind is not
# invalid), and objects/ and refs/ are searchable directories in the common dir.
# git only asks access(X_OK); requiring directories too is stricter, never looser.
gitdir_valid() {
  local d="$1" common
  [ -d "$d" ] || return 1
  [ "$(gitdir_head_kind "$d")" != invalid ] || return 1
  common="$(gitdir_common "$d")" || return 1
  [ -d "$common/objects" ] && [ -x "$common/objects" ] &&
    [ -d "$common/refs" ] && [ -x "$common/refs" ]
}

# looks_like_gitdir <dir>: the loose heuristic — a HEAD entry (of any type) next
# to an objects/ dir, or a commondir file. Catches a planted repository before
# anything checks it is complete: git may accept it (or the next edit may make it
# acceptable).
looks_like_gitdir() {
  local d="$1"
  { { [ -e "$d/HEAD" ] || [ -L "$d/HEAD" ]; } && [ -d "$d/objects" ]; } || [ -f "$d/commondir" ]
}
