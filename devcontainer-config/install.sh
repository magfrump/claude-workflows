#!/usr/bin/env bash
# install.sh — copy this repo's blessed-by-review files to the two places on the
# HOST that read them, each after its own review and its own y/N (a diff; a new
# ~/.claude entry is listed file by file, with its content if <= 200 lines):
#   1. the devcontainer config the cc-isolated launcher reads, then bless it
#      (decision 016);
#   2. the global Claude Code files in ~/.claude for bare-host sessions
#      (decision 037): CLAUDE.md, skills, workflows, guides, patterns, hooks,
#      scripts.
#
# Run from the HOST:  ./devcontainer-config/install.sh
#
# WHY COPIES RATHER THAN SYMLINKS INTO THE REPO. This repo is bind-mounted
# read-write into agent sessions, and on a bare host the agent works in it
# directly, so an agent CAN edit these files. Those edits are inert until a human
# runs this script and approves the diff: only the INSTALLED copies are ever read.
# Symlinking would hand the agent the boundary.
#
# The exception is this script itself, which is NOT inert: it runs on the host
# from the repo and decides which diff the human reads and what gets written, now
# including ~/.claude. An edit to it is covered by nothing but the commit-time
# Live-verified gate (decision 035). Review changes to it as boundary changes.
#
# So: read the diff. It is the rebuild gate.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: devcontainer-config/install.sh [--yes]

Offers two install targets in turn. Each one shows a review diff and asks y/N:
  1. devcontainer config -> $CLAUDE_DEVC_CONFIG_DIR
     (default ~/.config/claude-devcontainer); then blessed, and
     cc-isolated linked into $CLAUDE_DEVC_BIN_DIR (default ~/.local/bin).
  2. host Claude Code files -> $CLAUDE_HOME_DIR, else $CLAUDE_CONFIG_DIR,
     else ~/.claude. CLAUDE_HOME_DIR is read by install.sh only and outranks
     CLAUDE_CONFIG_DIR (which Claude Code, link-claude-home and health-check
     read); set it only to install somewhere else. Replaced entries, including
     old symlinks and files the repo lacks, are moved to
     <dest>/.claude-workflows-backup/<UTC stamp>/. The backups of the last 3
     installs are kept; the current run's is never removed.
     settings.json is never written; hook wiring stays a manual merge.

Both targets install COMMITTED content (HEAD, via git archive): every
devcontainer-config/ PAYLOAD item and the seven ~/.claude sources. Uncommitted
changes under those paths are listed as NOT included; commit and rerun.
A destination path holding a newline or other control character is refused,
and so is a payload file holding a NUL byte (a binary the diff cannot show).

NO AGENT MAY RUN DURING THE INSTALL (Q-058). install.sh checks at startup,
before the host target stages, and after each y, and refuses while it finds:
  - a Claude Code process of your uid (pgrep on the command line),
  - any other process of your uid whose working directory is inside the
    checkout (/proc; Q-062), such as a helper or loop driver an agent left
    running, or an editor or shell sitting in the repo, or
  - a running cc-isolated container (docker ps, label cc-project; docker's
    own DOCKER_HOST/DOCKER_CONTEXT choose which daemon is asked).
It names each one and how to stop it. The checks are samples, not a lock;
decision 037, "Trust model", lists what they miss (e.g. a leftover helper
working outside the checkout, or one that hides its cwd: stop those yourself).
Without pgrep or a mounted /proc it refuses; without a reachable docker it prints a NOTE line
at each check and treats no container as running. Close every Claude Code
session and stop every cc-isolated container first. Run from inside a
Claude Code session, install.sh finds that session and exits 1 at startup,
before either target.

Target 2 is SKIPPED, with a message and no effect on the exit status, when
--yes is given or stdin is not a terminal, and inside a Claude Code session
(CLAUDECODE set) that the check above missed. That stops accidental runs,
not a determined agent: a pty wrapper and `env -u CLAUDECODE` get past it.
The hard barrier is a sandbox that denies agents write access to ~/.claude.

Needs git, perl (the review's control-byte filter), pgrep and a mounted /proc (Linux);
refuses without them.

Both targets are refused, before anything is staged, when the checkout's own
.git holds a filter.*, core.fsmonitor, include* or hook.* key (in config or
config.worktree) or a non-empty info/attributes: git would run a command from
it as you, and an agent or a cc-isolated container can write .git. The refusal
names each entry and how to remove it. Hooks (.git/hooks, core.hooksPath) and
submodules are not refused; install.sh's git calls never run them.

The host target stages and reviews inside its destination, so a destination
that is not writable is refused before the review, with exit 1, even when
nothing would change.

  --yes       answer y for target 1 without asking (target 2 is skipped)
  -h, --help  show this help

Exit status: 0 no target declined; 1 a target was declined, or an error;
2 bad arguments.
EOF
}

# Top level holds only constants and function definitions; everything that runs
# is in main(), called from the last line (review R3). See main() for why.
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# install.sh itself is not installed — it runs from the repo.
# Every item is staged from the HEAD commit, not the tree (see install_devcontainer);
# `claude-home` is assembled below from the repo root before the diff is shown.
PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh link-claude-home.sh egress claude-home)

REPO_ROOT="$(cd "$SRC/.." && pwd)"

# --- Assemble the claude-home payload (decision 022) -------------------------
# The skills/workflows/guides/patterns/hooks and the global CLAUDE.md are baked
# into the image so that EVERY cc-isolated session gets this repo's process, not
# just sessions that happen to be editing this repo. They are staged here, into
# the build context, because the Dockerfile's context is the config dir.
#
# Assembled fresh from the commit on every install, into a private stage with
# the rest of the payload, so it shows up in the diff below, which is the
# human's review gate. devcontainer-config/claude-home is only a mirror of that
# stage; do not hand-edit it (nothing installs from it).
#
# `scripts` is staged for two reasons: hooks/log-usage.sh sources
# ../scripts/lib/skill-paths.sh relative to its own path, so a payload with
# hooks but no scripts leaves that hook dead on arrival (decision 023); and
# workflows call ~/.claude/scripts/lite-review.py and questions.sh by their
# installed path (Q-025).
# The global instructions file is sourced from global-instructions/ rather than
# the repo root: at the root, a session working in THIS repo loads it twice —
# once as the linked ~/.claude copy and once as the project's own instructions
# (prompt audit 2026-09-11, F1). Entries are staged under their basename, so
# the payload layout (and link-claude-home.sh) is unchanged.
CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)

# vis: filter that makes control bytes visible (all but newline and tab; NUL
# included), so a
# crafted file name or file line cannot rewrite the review on the terminal (A4).
#
# Raw 8-bit C1 bytes (0x80-0x9f; 0x9b is CSI on an 8-bit terminal) are made
# visible too, but only outside a well-formed UTF-8 sequence: every em dash is
# e2 80 94, so escaping those bytes everywhere would garble the review (fact-check
# claim 6). That needs "keep a match or replace it", which sed cannot express;
# perl can. LC_ALL=C: byte semantics, and no locale warning from perl.
vis() {
  LC_ALL=C perl -pe '
    s/\x1b/^[/g; s/\r/^M/g;
    s/[\x00-\x08\x0b\x0c\x0e-\x1a\x1c-\x1f\x7f]/?/g;
    s/\xc2[\x80-\x9f]/?/g;
    s/([\xc2-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf]{2}|[\xf0-\xf4][\x80-\xbf]{3})|[\x80-\x9f]/defined $1 ? $1 : "?"/ge;
  '
}

# vis_or_die: vis for every line shown outside review_diff (which checks vis
# itself) and mode_diff. mode_diff runs where errexit is off, so a vis failure
# there drops that MODE line silently; review_diff then shows the same items'
# content (not their MODE lines) and aborts on a vis that keeps failing.
# Elsewhere a vis failure used to end the script through set -e with no
# message at all (review C3).
# In a pipeline this runs in a subshell: it prints the error, its exit fails
# the pipeline, and set -e/pipefail then stops the script with exit 1.
vis_or_die() {
  local rc=0
  vis || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "ERROR: could not show output safely (vis exit $rc), so install.sh stopped. Nothing was installed." >&2
    exit 1
  fi
}

# repo_git <args...>: git on the checkout with the state that can make git run
# a command switched off (review R1, P2-R1). --no-optional-locks: status does
# not rewrite the index, so the post-index-change hook has nothing to fire on.
# core.hooksPath=/dev/null: no hook runs from .git/hooks or a planted hooks
# directory. core.fsmonitor=false: no fsmonitor command, from any config.
# (Submodules are kept out by --ignore-submodules=all on the status calls.)
# git_state_gate refuses the local keys these flags cannot switch off: filter
# drivers and includes.
repo_git() {
  git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"
}

# head_commit: print HEAD's commit id; exit the script if there is none.
head_commit() {
  if ! repo_git rev-parse --verify -q 'HEAD^{commit}'; then
    echo "ERROR: no readable HEAD commit in $REPO_ROOT (run \`git -C $REPO_ROOT rev-parse HEAD\`" >&2
    echo "       to see why). install.sh stages committed content only. Nothing was installed." >&2
    exit 1
  fi
}

# git_state_gate: exit the script, naming each entry, when the checkout's own git
# state names a command that git would run as the user during this install
# (review R1, security review F4). `git archive` runs a `filter.<x>.smudge` that
# an attributes file assigns, and `git status` runs `core.fsmonitor` and clean
# filters. An agent can write .git, and so can a cc-isolated container through
# its bind mount, so this is a container-to-host path the no-agent gate cannot
# see: the state persists after the writer has stopped. Called before any other
# git command on the checkout (see assemble).
#
# The reads here run nothing: `git config --file`/`--local` does not follow
# include.path unless asked (--no-includes makes that explicit), and neither
# it nor `rev-parse --git-path` reads the index or starts a filter or fsmonitor.
# --git-path resolves a linked worktree (whose .git is a file) to the common
# dir for info/attributes and config, and to the worktree's own dir for
# config.worktree. Its output may be relative to the checkout.
GIT_EXEC_KEYS_RE='^(filter\.|core\.fsmonitor|include|hook\.)'
git_state_gate() {
  local found="" out rc f attrs line
  for f in config config.worktree; do
    f="$(repo_git rev-parse --git-path "$f")" || f=""
    case "$f" in ''|/*) ;; *) f="$REPO_ROOT/$f" ;; esac
    if [ -z "$f" ] || { [ "${f##*/}" = config ] && [ ! -f "$f" ]; }; then
      echo "ERROR: could not find the git config of $REPO_ROOT. Nothing was installed." >&2
      exit 1
    fi
    [ -f "$f" ] || continue   # config.worktree is optional
    rc=0
    out="$(git --no-pager -c core.hooksPath=/dev/null config --file "$f" --no-includes --get-regexp "$GIT_EXEC_KEYS_RE")" || rc=$?
    if [ "$rc" -gt 1 ]; then
      echo "ERROR: could not read $f (git config exit $rc). Nothing was installed." >&2
      exit 1
    fi
    if [ -n "$out" ]; then
      while IFS= read -r line; do found+="         $f: $line"$'\n'; done <<< "$out"
    fi
  done
  attrs="$(repo_git rev-parse --git-path info/attributes)" || attrs=""
  case "$attrs" in ''|/*) ;; *) attrs="$REPO_ROOT/$attrs" ;; esac
  if [ -z "$attrs" ]; then
    echo "ERROR: could not find the git info/attributes path of $REPO_ROOT. Nothing was installed." >&2
    exit 1
  fi
  if [ -s "$attrs" ]; then
    found+="         $attrs is not empty:"$'\n'"$(head -n 20 "$attrs" | sed 's/^/           /')"$'\n'
  fi
  [ -n "$found" ] || return 0
  {
    echo "ERROR: the checkout's git state can make git run a command as you during this"
    echo "       install (a filter, core.fsmonitor, an include, a config-based hook, or an"
    echo "       attributes file):"
    printf '%s' "$found"
    echo "       An agent, or a cc-isolated container through its bind mount, can write"
    echo "       these. Check each one and remove it, with"
    echo "         git config --file <the file named above> --unset-all <key>"
    echo "       or by emptying the attributes file, then rerun. Removing filter.lfs.*"
    echo "       disables Git LFS in this clone; set LFS up in your global config instead"
    echo "       (\`git lfs install\`, without --local). Nothing was installed."
  } | vis_or_die >&2
  exit 1
}

# extract_commit <commit> <dir> <path...>: write each repo-relative <path>, as
# committed in <commit>, to <dir>/<basename>. Exits the script when a path is
# not in the commit or the result holds a symlink.
extract_commit() {
  local commit="$1" dir="$2" item links missing=()
  shift 2
  # No payload item is optional, and a missing one is silent-and-total: the
  # image or ~/.claude ships without that part and no session notices. So this
  # is fatal, not a warning — a warning here scrolls off above the payload diff
  # and the [y/N] prompt, which is where the human is actually looking. All
  # misses are collected before exiting so a reorganization is reported once
  # rather than one rerun per renamed path.
  for item in "$@"; do
    repo_git cat-file -e "$commit:$item" 2>/dev/null || missing+=("$item")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "ERROR: payload source(s) not found in commit ${commit:0:12} of $REPO_ROOT: ${missing[*]}" >&2
    echo "       The payload would be incomplete. Fix (and commit) the path, or edit" >&2
    echo "       CLAUDE_HOME_SRC or PAYLOAD in this script. Nothing was installed." >&2
    exit 1
  fi
  mkdir "$dir/.extract"
  # Modes are the commit's (fact-check claim 17): tar.umask=022 makes git
  # archive write 644/755 rather than its default 664/775, and tar -p keeps
  # them rather than applying this shell's umask.
  if ! repo_git -c tar.umask=022 archive --format=tar "$commit" -- "$@" \
       | tar -xpf - -C "$dir/.extract"; then
    echo "ERROR: could not extract commit ${commit:0:12} from $REPO_ROOT. Nothing was installed." >&2
    exit 1
  fi
  for item in "$@"; do
    mv "$dir/.extract/$item" "$dir/$(basename "$item")"
  done
  rm -rf "$dir/.extract"
  # No symlinks (review R1). git archive keeps committed links, and diff and
  # cp -R follow or keep them, so a link to an agent-writable file would review
  # as "(none)" and install as a live link. Today's payload has none.
  links="$(cd "$dir" && find . -type l | sed 's|^\./||' | LC_ALL=C sort)"
  if [ -n "$links" ]; then
    echo "ERROR: the committed payload contains symlinks, which install.sh never installs:" >&2
    printf '%s\n' "$links" | sed 's/^/         /' | vis_or_die >&2
    echo "       Replace them with real files and commit. Nothing was installed." >&2
    exit 1
  fi
  # No NUL bytes. diff reports such a file as "Binary files ... differ" and
  # shows none of its content, so it would install unreviewed. The payload is
  # text today (checked 2026-09-23: no committed payload file holds a NUL), so
  # there is no allowlist; add one here, documented, if a binary is ever needed.
  local nul
  if ! nul="$(cd "$dir" && find . -type f -print0 | LC_ALL=C sort -z | LC_ALL=C perl -0ne '
        chomp; open(my $f, "<:raw", $_) or die "$_: $!\n";
        my $c = do { local $/; <$f> };
        print substr($_, 2), "\n" if defined $c && index($c, "\0") >= 0;')"; then
    echo "ERROR: could not scan the staged payload for NUL bytes. Nothing was installed." >&2
    exit 1
  fi
  if [ -n "$nul" ]; then
    echo "ERROR: the committed payload holds files with NUL bytes (binary), which the review" >&2
    echo "       diff cannot show and install.sh therefore never installs:" >&2
    printf '%s\n' "$nul" | sed 's/^/         /' | vis_or_die >&2
    echo "       Remove them from the payload paths and commit. Nothing was installed." >&2
    exit 1
  fi
}

# assemble <stage-dir> [path...]: stage every CLAUDE_HOME_SRC entry, as
# committed at HEAD, under its basename and write the .manifest provenance
# stamp. Sets STAGED_COMMIT. Uncommitted changes are listed under the
# CLAUDE_HOME_SRC paths and the extra repo-relative <path>s, so a target that
# also stages other paths from STAGED_COMMIT gets one warning for all of them.
#
# COMMITTED CONTENT ONLY (code review 2026-09-23, C1). The working tree is
# agent-writable and holds git-ignored junk (__pycache__), so the payload is
# `git archive HEAD`, never `cp -r` of the tree. Uncommitted changes under the
# payload paths are listed as NOT included; the human commits and reruns.
assemble() {
  local stage="$1" commit dirty home_dirty
  shift
  git_state_gate   # before any other git call on the checkout (review R1)
  rm -rf "$stage"
  mkdir -p "$stage"
  commit="$(head_commit)" || exit 1
  STAGED_COMMIT="$commit"
  extract_commit "$commit" "$stage" "${CLAUDE_HOME_SRC[@]}"
  # Porcelain paths are repo-relative. core.quotePath=true makes git C-quote
  # every control or non-ASCII byte in them whatever the user's config (with
  # quotePath=false it printed U+009B raw: fact-check claim 9), so each entry
  # is one line; the listing also goes through vis. Ignored files are not
  # listed: never staged. repo_git keeps status from running hooks or an
  # fsmonitor, and --ignore-submodules=all keeps it out of submodules, whose
  # own git dirs carry their own config, filters and hooks (review P2-R1).
  dirty="$(repo_git -c core.quotePath=true status --porcelain --untracked-files=all --ignore-submodules=all -- "${CLAUDE_HOME_SRC[@]}" "$@")"
  home_dirty="$(repo_git -c core.quotePath=true status --porcelain --untracked-files=all --ignore-submodules=all -- "${CLAUDE_HOME_SRC[@]}")"
  if [ -n "$dirty" ]; then
    echo "WARNING: the checkout has uncommitted changes under the payload paths. They are"
    echo "         NOT included: this install stages commit ${commit:0:12} only. Commit them"
    echo "         and rerun to include them."
    printf '%s\n' "$dirty" | sed 's/^/           /' | vis_or_die
  fi
  # Provenance stamp: lets a session (and health-check) tell which commit's process
  # it is running, and detect that the image predates the repo it is editing.
  # dirty=no always: the payload is exactly the commit's content.
  {
    echo "commit=$commit"
    echo "dirty=no"
    echo "uncommitted_excluded=$(printf '%s' "$home_dirty" | grep -c '' || true)"
    echo "assembled_from=$REPO_ROOT"
  } > "$stage/.manifest"
}

# review_diff <dest> <src-prefix> <item...>: print `diff -ruN` of
# <dest>/<item> against <src-prefix><item> for each item (<src-prefix> is
# "<stage>/" or, on the host target, "<dest>/.cw-new."). Returns 0 when nothing
# differs and 1 when something does; exits the script when a diff could not be
# produced.
review_diff() {
  local dest="$1" src="$2" item rc changed=0
  shift 2
  for item in "$@"; do
    # -N (treat an absent file as empty) is what makes NEW content visible: without
    # it, a new file inside a payload dir showed only as "Only in src/egress: x.txt"
    # and a new top-level item printed nothing at all (the error went to the
    # swallowed stderr), so the human approved content they never saw. stderr is
    # not discarded, and exit status >1 ("trouble") aborts rather than counting as
    # a change: this diff is the review gate, so a diff that could not be shown
    # must never reach the [y/N] prompt.
    # vis (A4): a raw \r or CSI sequence in a file could hide `+` lines.
    # A vis failure is trouble too: its output is the review, so a failed vis
    # over a differing item read as an empty diff that still reached [y/N].
    local st
    # -a: a file with a NUL byte (only ever on the destination side; the stage
    # has none, see extract_commit) is diffed as text, with vis showing each
    # NUL as "?", rather than as "Binary files differ" with no content.
    diff -ruNa "$dest/$item" "$src$item" 2>&1 | vis && st=(0 0) || st=("${PIPESTATUS[@]}")
    rc="${st[0]}"
    if [ "${st[1]}" -ne 0 ]; then
      echo "ERROR: could not show the review of payload item '$item' (vis exit ${st[1]})." >&2
      echo "       The review diff is incomplete, so nothing was installed." >&2
      exit 1
    fi
    case "$rc" in
      0) ;;
      1) changed=1 ;;
      *) echo "ERROR: could not diff payload item '$item' (diff exit $rc)." >&2
         echo "       The review diff is incomplete, so nothing was installed." >&2
         exit 1 ;;
    esac
  done
  return "$changed"
}

# mode_diff <dest> <src-prefix> <item...>: print a MODE line for each regular file
# present in both trees whose permission bits differ. diff compares content
# only, so a committed `chmod +x` alone reviewed as "(none)" and never
# installed (fact-check claim 17). Returns 1 when any mode differs.
mode_diff() {
  local dest="$1" src="$2" item rec p rc=0
  shift 2
  for item in "$@"; do
    # Keys carry a leading "/" because a top-level file's relative path is ""
    # and bash rejects an empty associative-array key.
    local -A dm=()
    while IFS= read -r -d '' rec; do dm["/${rec#* }"]="${rec%% *}"; done \
      < <(find -H "$dest/$item" -type f -printf '%m %P\0' 2>/dev/null)
    while IFS= read -r -d '' rec; do
      p="/${rec#* }"
      if [ -n "${dm[$p]+x}" ] && [ "${dm[$p]}" != "${rec%% *}" ]; then
        echo "MODE $dest/$item${p%/}: ${dm[$p]} -> ${rec%% *}" | vis
        rc=1
      fi
    done < <(find "$src$item" -type f -printf '%m %P\0')
  done
  return "$rc"
}

# confirm <question>: true on y/yes. `|| reply=""` so a closed/EOF stdin (piped
# or non-tty run) reads as "no" instead of dying on `read`'s non-zero exit under
# `set -e`, which killed the script before it could say why.
confirm() {
  local reply
  printf '%s [y/N] ' "$1"
  read -r reply || reply=""
  case "$reply" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

# dc_unwind <reason> [<list>]: the devcontainer copy failed a check (review A1,
# P2-A2). Remove every PAYLOAD item from $DEST, say why, and exit 1 before
# chmod, the cc-isolated link and the bless. The previous config is gone too,
# so cc-isolated refuses to run until an install completes.
# Best-effort, never set -e: cc-isolated.sh goes first, and one item that
# cannot be removed (a copied tree with a read-only subdir) must not stop the
# rest or the message (review pass 4, F1: an early exit left an altered
# launcher live). A link is removed, never chmod-ed through.
dc_unwind() {
  local item left=""
  for item in cc-isolated.sh "${PAYLOAD[@]}"; do
    [ -e "$DEST/$item" ] || [ -L "$DEST/$item" ] || continue
    if [ ! -L "$DEST/$item" ]; then chmod -R u+w "$DEST/$item" 2>/dev/null || true; fi
    rm -rf "${DEST:?}/$item" 2>/dev/null || left+=" $item"
  done
  {
    echo "ERROR: $1"
    if [ -n "${2:-}" ]; then printf '%s\n' "$2" | sed 's/^/         /'; fi
    if [ -n "$left" ]; then
      echo "       Could not remove from $DEST:$left. Remove them by hand."
    fi
    echo "       The copied items were removed again (the previous config with them) and"
    echo "       nothing was blessed, so cc-isolated will not run until install.sh completes."
    echo "       Rerun install.sh."
  } | vis_or_die >&2
  exit 1
}

# --- Target: the devcontainer config (decision 016) ---------------------------
install_devcontainer() {
  # Every PAYLOAD item comes from the commit too (fact-check claim 4; user
  # decision C1): the firewall, launcher and egress lists are the boundary, and
  # the tree they sit in is agent-writable. The whole payload is staged in a
  # private temp dir and installed from there. $SRC/claude-home is refreshed as
  # a mirror of the staged claude-home for inspection; nothing installs from it.
  local dc_paths=() item
  for item in "${PAYLOAD[@]}"; do
    [ "$item" = claude-home ] || dc_paths+=("$(basename "$SRC")/$item")
  done
  # The mirror is rebuilt in the agent-writable checkout. A symlink at
  # claude-home, or at any directory between the repo root and it, would send
  # the rebuild's writes wherever it points (~/.claude, say), so refuse one.
  local p="$REPO_ROOT" comp
  local -a comps
  IFS=/ read -ra comps <<< "${SRC#"$REPO_ROOT"/}/claude-home"
  for comp in "${comps[@]}"; do
    p="$p/$comp"
    if [ -L "$p" ]; then
      echo "ERROR: $p is a symlink ($(readlink "$p")). install.sh rebuilds" | vis_or_die >&2
      echo "       devcontainer-config/claude-home in the checkout and never writes through a" >&2
      echo "       link there. Remove the link (rm, no trailing slash) and rerun. Nothing was installed." >&2
      exit 1
    fi
  done
  DC_TMP="$(mktemp -d "${TMPDIR:-/tmp}/cw-devc-stage.XXXXXX")"
  local stage="$DC_TMP/config"
  assemble "$stage/claude-home" "${dc_paths[@]}"
  extract_commit "$STAGED_COMMIT" "$stage" "${dc_paths[@]}"
  # No-follow rebuild: rm of a path without a trailing slash removes a link
  # itself, never its target; mkdir fails rather than follow anything that
  # appeared since, so the copy lands in a directory this run just created.
  rm -rf "$SRC/claude-home"
  if ! mkdir "$SRC/claude-home"; then
    echo "ERROR: could not recreate $SRC/claude-home (something reappeared there). Nothing was installed." >&2
    exit 1
  fi
  cp -Rp "$stage/claude-home/." "$SRC/claude-home/"

  # A1: the stage sits in a same-uid temp dir while the review and [y/N] wait.
  # Hash it before the review; after the y the stage, and then what landed in
  # $DEST, must hash the same, or nothing is blessed. This catches an edit that
  # persists until the copy. It does not catch a stage swapped for the review
  # and swapped back before the y: for that this target relies on the gate
  # (decision 037, "Trust model").
  local reviewed_hash links
  links="$(links_in "$stage" "" "${PAYLOAD[@]}")" \
    || links="(the symlink check could not read every item)"
  if [ -n "$links" ]; then
    {
      echo "ERROR: symlinks appeared in the staged devcontainer config after its link check:"
      printf '%s\n' "$links" | sed 's/^/         /'
      echo "       install.sh never installs a link. Nothing was installed."
    } | vis_or_die >&2
    exit 1
  fi
  reviewed_hash="$(tree_hash "$stage" "" "${PAYLOAD[@]}")"

  echo "Canonical (repo):  $SRC at commit ${STAGED_COMMIT:0:12} (staged in $stage)"
  echo "Installed (host):  $DEST"
  echo

  if [ -d "$DEST" ]; then
    echo "=== Changes this install would make ==========================================="
    local same=1
    mode_diff "$DEST" "$stage/" "${PAYLOAD[@]}" || same=0
    review_diff "$DEST" "$stage/" "${PAYLOAD[@]}" || same=0
    if [ "$same" -eq 1 ]; then
      echo "(none — installed config already matches the repo)"
    fi
    echo "==============================================================================="
    echo
  else
    echo "First install — $DEST does not exist yet."
    echo
  fi

  if [ "$ASSUME_YES" != "--yes" ]; then
    if ! confirm 'Install this config and bless it?'; then
      # Decision 037: a decline ends this target, not the run; the host target
      # is still offered. The line gained " (devcontainer config)", and the run
      # still exits 1 because something was declined.
      echo "Aborted. Nothing was changed. (devcontainer config)"
      DECLINED=1
      return 0
    fi
  fi

  # Q-058: an agent may have started while the prompt waited.
  agent_gate "Nothing was installed. (devcontainer config)"

  if [ "$(tree_hash "$stage" "" "${PAYLOAD[@]}")" != "$reviewed_hash" ]; then
    echo "ERROR: the staged devcontainer config changed after review: $stage no longer" >&2
    echo "       holds what the review showed. Nothing was installed. Rerun install.sh." >&2
    exit 1
  fi

  mkdir -p "$DEST" "$BIN_DIR"

  # projects/ holds per-project egress registrations and is host-owned state — it is
  # NOT part of the canonical repo payload, so never clobber it.
  mkdir -p "$DEST/projects"

  # A1, P2-A2: what landed must be what was reviewed, before chmod and the
  # bless. On a failed copy, a symlink or a mismatch, every PAYLOAD item is
  # removed again, so no unreviewed file stays live (cc-isolated.sh runs on
  # the host from here), and nothing is blessed.
  local copy_failed=""
  for item in "${PAYLOAD[@]}"; do
    if ! rm -rf "${DEST:?}/$item" || ! cp -Rp "$stage/$item" "$DEST/$item"; then
      copy_failed="$item"; break
    fi
  done
  if [ -n "$copy_failed" ]; then
    dc_unwind "could not copy '$copy_failed' into $DEST."
  fi
  links="$(links_in "$DEST" "" "${PAYLOAD[@]}")" \
    || links="(the symlink check could not read every item)"
  if [ -n "$links" ]; then
    dc_unwind "symlinks landed in $DEST, which install.sh never installs:" "$links"
  fi
  if [ "$(tree_hash "$DEST" "" "${PAYLOAD[@]}")" != "$reviewed_hash" ]; then
    dc_unwind "the devcontainer config copied into $DEST differs from what the review showed (the stage changed after review, during the copy)."
  fi

  chmod +x "$DEST/cc-isolated.sh" "$DEST/init-firewall.sh"

  ln -sf "$DEST/cc-isolated.sh" "$BIN_DIR/cc-isolated"
  echo "Linked $BIN_DIR/cc-isolated -> $DEST/cc-isolated.sh"
  echo

  CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless

  echo
  echo "Done. Blessed, NOT verified: a bless is a review of files, not a test of a container."
  echo "Next steps:"
  echo "  touch ~/.ssh/canary                    # once, if you haven't — strengthens the H1 probe"
  echo "  cc-isolated --probe-only <repo>        # REQUIRED after any boundary change: rebuilds from"
  echo "                                         # this config and records it verified live on a pass"
  echo "  cc-isolated                            # session for the repo containing \$PWD"
  echo "  cc-isolated --register <repo> --profile python   # widen a project's egress"
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo; echo "WARNING: $BIN_DIR is not on your PATH — add it, or call $DEST/cc-isolated.sh directly." ;;
  esac
}

# --- Target: host ~/.claude (decision 037) ------------------------------------
# Bless here means: a human at a terminal read this review and typed y. No hash
# receipt is checked afterwards (Claude Code reads ~/.claude directly), so the
# skip rules below are the whole of the "human" requirement.
#
# The replace is done move-aside, never `rm -rf` + `cp -r` in place: with the
# README's old symlink install, `cp -r stage/skills ~/.claude/skills` writes INTO
# the checkout through the link, and `rm -rf ~/.claude/skills/` (trailing slash)
# empties the checkout. And `diff` follows symlinks, so a migration from links
# to copies would review as "(none)". Hence the explicit REPLACE lines below.

# resolve_phys <path>: where <path> lands once mkdir -p creates it. Walks the
# components: an existing dir is resolved physically (links followed), a
# missing one is appended as text, and `..` drops the last component. So
# <outside>/nx/../<repo> with nx missing resolves to <repo> (review A3).
# `read` splits only the first line; main refuses any destination holding a
# newline or other control character before this runs (claim 11b).
resolve_phys() {
  local p="$1" cur="/" comp parts
  case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
  IFS=/ read -ra parts <<< "$p"
  for comp in "${parts[@]}"; do
    case "$comp" in
      ''|.) ;;
      ..) cur="$(dirname "$cur")" ;;
      *) if [ -d "${cur%/}/$comp" ]; then cur="$(cd "${cur%/}/$comp" && pwd -P)"
         else cur="${cur%/}/$comp"; fi ;;
    esac
  done
  echo "$cur"
}

inside_repo() {
  local root
  root="$(cd "$REPO_ROOT" && pwd -P)"
  case "$1/" in "$root/"*) return 0 ;; esac
  return 1
}

# tree_hash <dir> <prefix> <name...>: one hash over the listing (path, type,
# mode, link target) and the file contents of <dir>/<prefix><name> for each
# <name>. The same tree hashes the same wherever it sits, so the stage (prefix
# "") and a copy of it (prefix ".cw-new.", or another <dir>) can be compared.
tree_hash() {
  local dir="$1" pfx="$2" name
  shift 2
  for name in "$@"; do
    echo "== $name"
    find "$dir/$pfx$name" -printf '%P\t%y\t%m\t%l\n' | LC_ALL=C sort
    find "$dir/$pfx$name" -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum | cut -d' ' -f1
  done | sha256sum | cut -d' ' -f1
}

# links_in <dir> <prefix> <name...>: print every symlink at or under
# <dir>/<prefix><name>, one per line. extract_commit refuses links once, right
# after extraction; a link that appears later passed that check and tree_hash
# only records it, so every hash site calls this too (review P2-R2).
# A missing item holds no link and is skipped: at $DEST the hash check that
# follows catches it; at the stage and host sites the hash is taken of the
# missing state, and the copy (could not copy) or the swap (rolled back)
# refuses it instead (review pass 4, F2);
# a find that cannot read a tree fails the call, and every caller turns that
# into a refusal (review pass 3: a bare failure here skipped dc_unwind).
links_in() {
  local dir="$1" pfx="$2" name
  shift 2
  for name in "$@"; do
    [ -e "$dir/$pfx$name" ] || [ -L "$dir/$pfx$name" ] || continue
    find "$dir/$pfx$name" -type l || return 1
  done
}

# payload_hash <dir> <prefix> <manifest>: tree_hash of every host entry name,
# plus the provenance manifest's bytes, for R2's check. The manifest is
# covered so its commit= stamp cannot be forged at the prompt either
# (fact-check claim 14).
payload_hash() {
  local dir="$1" pfx="$2" manifest="$3"
  {
    tree_hash "$dir" "$pfx" "${CLAUDE_HOME_NAMES[@]}"
    echo "== manifest"
    sha256sum < "$manifest" | cut -d' ' -f1
  } | sha256sum | cut -d' ' -f1
}

# rm_new_copies <dest>: remove every .cw-new.* copy this install makes.
rm_new_copies() {
  local n
  for n in "${CLAUDE_HOME_NAMES[@]}" manifest; do
    # A copied tree with a read-only subdir must not survive to block every
    # later run (review pass 4); a link is removed, never chmod-ed through.
    if [ -e "${1:?}/.cw-new.$n" ] && [ ! -L "$1/.cw-new.$n" ]; then chmod -R u+w "$1/.cw-new.$n" 2>/dev/null || true; fi
    rm -rf "${1:?}/.cw-new.$n" 2>/dev/null || true
  done
}

host_refuse() {
  echo "ERROR: $1" >&2
  echo "       Nothing was installed into the host target." >&2
  exit 1
}

lock_msg() {
  echo "another install holds $1/.claude-workflows-lock, or one was killed. If no install.sh is running, remove that directory and rerun."
}

# host_cleanup: main's EXIT trap. Removes both stages (the host one sits in
# $dest/.cw-stage.*) and any unswapped host copies, and releases the lock, if
# this run took it.
host_cleanup() {
  if [ -n "$HOST_TMP" ]; then rm -rf "$HOST_TMP" || true; fi
  if [ -n "$DC_TMP" ]; then rm -rf "$DC_TMP" || true; fi
  # The host copies (review R2) this run made and did not swap in; set only
  # while this run holds the lock, so another run's copies are never touched.
  if [ -n "$HOST_NEW_IN" ]; then rm_new_copies "$HOST_NEW_IN"; fi
  if [ -n "$HOST_LOCK" ]; then rmdir "$HOST_LOCK" 2>/dev/null || true; fi
  # A destination this run created only to hold the lock and copies.
  if [ -n "$HOST_MADE_DEST" ]; then rmdir "$HOST_MADE_DEST" 2>/dev/null || true; fi
}

# host_rollback: undo a partial swap in install_claude_home (R4), using its
# locals dest, backup, bkroot, moved and swapped. Then report and exit 1.
host_rollback() {
  local n left=()
  for n in "${swapped[@]}"; do rm -rf "${dest:?}/$n"; done
  for n in "${moved[@]}"; do
    if [ -e "$dest/$n" ] || [ -L "$dest/$n" ] || ! mv "$backup/$n" "$dest/$n"; then left+=("$n"); fi
  done
  rm_new_copies "$dest"
  if [ "${#left[@]}" -eq 0 ]; then
    echo "ERROR: the install failed part-way and was rolled back: every entry was moved back" >&2
    echo "       from ${backup:-(no backup was needed)}. $dest is as it was before this run." >&2
    if [ -n "$backup" ]; then rmdir "$backup" "$bkroot" 2>/dev/null || true; fi
  else
    echo "ERROR: the install failed part-way and the rollback is INCOMPLETE." >&2
    echo "       $dest is missing: ${left[*]}. They are in $backup." >&2
    echo "       Move each back by hand: mv \"$backup/<name>\" \"$dest/<name>\"" >&2
  fi
  exit 1
}

install_claude_home() {
  local dest="$HOST_DEST" label="$HOST_LABEL"

  echo
  # Skip rules come first: before this target reads or stages anything, so
  # every non-interactive run (scripts, tests, --yes) is unchanged apart from
  # a blank line and the skip line. A skip is not a decline and does not change the exit status.
  # Neither check stops an agent that sets out to fake a terminal (`script`
  # gives it a pty; `env -u` drops CLAUDECODE). They stop the accidental run and
  # make the deliberate one conspicuous. See decision 037.
  if [ "$ASSUME_YES" = "--yes" ]; then
    echo "Skipped host target (~/.claude): it never installs with --yes. Run install.sh without --yes at a terminal to review and install it."
    return 0
  fi
  if [ -n "${CLAUDECODE:-}" ]; then
    echo "Skipped host target (~/.claude): running inside a Claude Code session (CLAUDECODE is set). Run install.sh from your own terminal."
    return 0
  fi
  if [ ! -t 0 ]; then
    echo "Skipped host target (~/.claude): it needs an interactive terminal (stdin is not a TTY). Run install.sh from your own terminal."
    return 0
  fi

  echo "=== Host target: global Claude Code files ======================================"
  echo "Destination: $dest  (chosen by $label)"

  # Q-058, review A2: the startup check ran before target 1's review and
  # prompt, which can wait for minutes. Check again before this target stages.
  agent_gate "Nothing was installed into the host target."

  # Guards: nothing below may write through a link into the checkout.
  if [ -L "$dest" ] && [ ! -d "$dest" ]; then
    host_refuse "$dest is a dangling symlink ($(readlink "$dest")). Remove it or point it at a real directory."
  fi
  if [ -e "$dest" ] && [ ! -d "$dest" ]; then
    host_refuse "$dest exists and is not a directory."
  fi
  if inside_repo "$(resolve_phys "$dest")"; then
    host_refuse "$dest resolves inside the repo checkout ($REPO_ROOT). Installing there would edit the repo, not install a copy."
  fi
  local bkroot="$dest/.claude-workflows-backup"
  if [ -L "$bkroot" ]; then
    host_refuse "$bkroot is a symlink ($(readlink "$bkroot")); the backup must be a real directory. Remove the link."
  fi
  if [ -d "$bkroot" ] && inside_repo "$(resolve_phys "$bkroot")"; then
    host_refuse "$bkroot resolves inside the repo checkout."
  fi
  local name
  for name in "${CLAUDE_HOME_NAMES[@]}" manifest; do
    if [ -L "$dest/.cw-new.$name" ]; then
      host_refuse "$dest/.cw-new.$name is a symlink left from elsewhere; remove it and rerun."
    fi
  done
  if [ -e "$dest/.claude-workflows-lock" ] || [ -L "$dest/.claude-workflows-lock" ]; then
    host_refuse "$(lock_msg "$dest")"
  fi

  # R2 and P2-R3 (Q-061 interim [1], provisional pending the user's answer):
  # everything the review reads and everything that is installed lives under
  # $dest, which the sandbox's denyWrite covers for the default ~/.claude.
  # Nothing the review reads or the install copies sits in $TMPDIR (only the
  # gate's docker stderr file does), where any same-uid writer could swap the stage, the copies' source or the old side of the diff while the
  # review ran (SP1, SP1b, SP1c). So: take the lock; extract the stage into
  # $dest/.cw-stage.*; copy it into $dest/.cw-new.*; hash those copies and
  # review them against a view of the current destination, also built in
  # $dest/.cw-stage.*; after the y, check the hash and swap exactly those
  # copies in. A decline, "nothing to install" or any error removes the stage
  # and the copies (rm_new_copies here, or main's EXIT trap).
  #
  # One install at a time (R4): two concurrent swaps left none of the seven
  # entries. The lock is released by main's EXIT trap on every path. It is
  # taken before anything is staged, so an unwritable destination is refused
  # here, before the review (exit 1), even when nothing would change.
  [ -d "$dest" ] || HOST_MADE_DEST="$dest"   # removed again if left empty
  if mkdir -p "$dest" 2>/dev/null && mkdir "$dest/.claude-workflows-lock" 2>/dev/null; then
    HOST_LOCK="$dest/.claude-workflows-lock"
    HOST_NEW_IN="$dest"   # this run owns $dest/.cw-new.* from here on
  elif [ -e "$dest/.claude-workflows-lock" ]; then
    host_refuse "$(lock_msg "$dest")"
  else
    echo "ERROR: could not create $dest/.claude-workflows-lock (is $dest writable?)." >&2
    echo "       install.sh stages and reviews under the destination, so it needs write" >&2
    echo "       access there even when nothing would change; nothing was replaced." >&2
    exit 1
  fi
  # A killed run leaves its stage behind; under the lock no other run uses one.
  # (rm of a name without a trailing slash removes a planted link, not its target.)
  rm -rf "$dest"/.cw-stage.*
  if ! HOST_TMP="$(mktemp -d "$dest/.cw-stage.XXXXXX")"; then
    HOST_TMP=""
    host_refuse "could not create a staging directory in $dest."
  fi
  local stage="$HOST_TMP/payload" ok=1
  assemble "$stage"

  # 1. Copy every entry beside its target. Any failure: undo and stop before a
  #    single live entry is touched.
  rm_new_copies "$dest"
  for name in "${CLAUDE_HOME_NAMES[@]}" manifest; do
    # cp -R into a leftover directory would nest the copy inside it.
    if [ -e "$dest/.cw-new.$name" ] || [ -L "$dest/.cw-new.$name" ]; then
      host_refuse "could not remove the leftover $dest/.cw-new.$name from an earlier run; remove it by hand."
    fi
  done
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    # -p keeps the committed modes (claim 17); R2's hash compares them too.
    if ! cp -Rp "$stage/$name" "$dest/.cw-new.$name"; then ok=0; break; fi
  done
  if [ "$ok" -eq 1 ]; then
    rm -f "$dest/.cw-new.manifest"
    cp -p "$stage/.manifest" "$dest/.cw-new.manifest" || ok=0
  fi
  if [ "$ok" -eq 0 ]; then
    rm_new_copies "$dest"
    echo "ERROR: could not copy the new files into $dest; nothing was replaced." >&2
    exit 1
  fi
  # The review below reads $new<name>; after the y they must still hash the same.
  local new="$dest/.cw-new." reviewed_hash links
  links="$(links_in "$dest" .cw-new. "${CLAUDE_HOME_NAMES[@]}" manifest)" \
    || links="(the symlink check could not read every item)"
  if [ -n "$links" ]; then
    rm_new_copies "$dest"
    {
      echo "ERROR: symlinks appeared in the copies to install after the payload's link check:"
      printf '%s\n' "$links" | sed 's/^/         /'
      echo "       install.sh never installs a link. Nothing was installed into the host target."
    } | vis_or_die >&2
    exit 1
  fi
  reviewed_hash="$(payload_hash "$dest" .cw-new. "$dest/.cw-new.manifest")"
  echo "Canonical (repo):  $REPO_ROOT (commit $(sed -n 's/^commit=//p' "$dest/.cw-new.manifest"))"
  echo

  # Pre-pass: what the content diff cannot show.
  local changed=0 link f rel line warned=0
  echo "=== Changes this install would make ==========================================="
  # A link the repo also has is REPLACEd by a copy; anything the repo lacks,
  # link or file, is only MOVEd (review R5), and says which it is.
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -L "$dest/$name" ]; then
      echo "REPLACE symlink $dest/$name -> $(readlink "$dest/$name") with a copy" | vis_or_die
      changed=1
    elif [ -d "$dest/$name" ]; then
      while IFS= read -r -d '' link; do
        rel="${link#"$dest/$name"/}"
        [ -e "$new$name/$rel" ] || continue
        echo "REPLACE symlink $link -> $(readlink "$link") with a copy" | vis_or_die
        changed=1
      done < <(find "$dest/$name" -type l -print0 | LC_ALL=C sort -z)
      while IFS= read -r -d '' f; do
        rel="${f#"$dest/$name"/}"
        if [ -e "$new$name/$rel" ]; then continue; fi
        if [ "$warned" -eq 0 ]; then
          echo "WARNING: not in the repo; these will be MOVED to the backup (Q-057):"
          warned=1
        fi
        if [ -L "$f" ]; then
          line="MOVE link $f -> $(readlink "$f") to backup (not in the repo)"
        else
          line="MOVE to backup (not in the repo): $f"
        fi
        # Match the full hooks/<path>, so hooks/sub/x.sh is not "wired" by hooks/x.sh.
        if [ "$name" = hooks ] && grep -qsF "hooks/$rel" "$dest/settings.json" "$dest/settings.local.json"; then
          line="$line  <-- WIRED in settings: moving it breaks that hook"
        fi
        echo "$line" | vis_or_die
        changed=1
      done < <(find "$dest/$name" \( -type f -o -type l \) -print0 | LC_ALL=C sort -z)
    fi
  done
  # Content diff. An entry the destination lacks is listed file by file (A7: a
  # first install diffed in full printed ~32k lines, scrolling the lines above
  # away), and its content is shown too when it is at most ADD_MAX_LINES lines;
  # past that the review says the content was left out and where to read it
  # (fact-check claim 3). The limit shows a new CLAUDE.md or a small hooks dir
  # whole and keeps a first install's skills tree to a file list.
  # An existing entry is diffed as a link-free copy under $HOST_TMP/installed
  # (inside $dest, P2-R3: in $TMPDIR a writer could rewrite this old side to
  # match the new copy and hide a change, SP1b): a
  # top-level link is followed (cp -H), so the link's target is compared;
  # links inside are dropped, since the lines above already name each one, so
  # a dangling link cannot abort the review (A8).
  local view="$HOST_TMP/installed" diffnames=() n lines src
  local ADD_MAX_LINES=200
  mkdir -p "$view"
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ ! -e "$dest/$name" ]; then
      n="$(find "$new$name" -type f | grep -c '' || true)"
      echo "ADD $dest/$name (new, $n file(s)):" | vis_or_die
      (cd "$dest" && find ".cw-new.$name" -type f | LC_ALL=C sort) | sed 's/^\.cw-new\./    /' | vis_or_die
      lines="$(find "$new$name" -type f -exec cat {} + | wc -l)"
      if [ "$lines" -le "$ADD_MAX_LINES" ]; then
        review_diff "$view" "$new" "$name" || true   # $view/$name is absent: all "+" lines
      else
        for src in "${CLAUDE_HOME_SRC[@]}"; do [ "$(basename "$src")" = "$name" ] && break; done
        echo "    (content not shown: $lines lines, over the $ADD_MAX_LINES-line limit for a new entry;" \
             "it is $src at commit ${STAGED_COMMIT:0:12})" | vis_or_die
      fi
      changed=1
      continue
    fi
    if ! cp -RH "$dest/$name" "$view/$name"; then
      echo "ERROR: could not read $dest/$name for the review. Nothing was installed." >&2
      exit 1
    fi
    find "$view/$name" -type l -delete
    chmod -R u+w "$view/$name"   # cp keeps a read-only dir's mode; cleanup must remove it
    diffnames+=("$name")
  done
  if [ "${#diffnames[@]}" -gt 0 ]; then
    if ! mode_diff "$dest" "$new" "${diffnames[@]}"; then changed=1; fi
    echo "(diff: $view is the destination as it is now, links left out; ${new}* are the copies to install)"
    if ! review_diff "$view" "$new" "${diffnames[@]}"; then changed=1; fi
  fi
  if [ "$changed" -eq 0 ]; then
    echo "(none — the destination already matches the repo)"
  fi
  echo "==============================================================================="
  echo
  # A6: nothing to do means no prompt, no swap and no 2.4 MB backup.
  if [ "$changed" -eq 0 ]; then
    rm_new_copies "$dest"
    echo "Nothing to install into $dest."
    return 0
  fi

  local wiring_changed=0
  if ! cmp -s "$dest/hooks/wiring.json" "${new}hooks/wiring.json"; then
    wiring_changed=1
  fi

  if ! confirm "Install these files into $dest?"; then
    rm_new_copies "$dest"
    echo "Aborted. Nothing was changed. (host ~/.claude)"
    DECLINED=1
    return 0
  fi

  # Q-058: an agent may have started while the review and prompt waited.
  agent_gate "Nothing was installed into the host target."

  if [ "$(payload_hash "$dest" .cw-new. "$dest/.cw-new.manifest")" != "$reviewed_hash" ]; then
    rm_new_copies "$dest"
    echo "ERROR: the copies to install changed after review: ${new}* differ from the" >&2
    echo "       files the review showed. Nothing was replaced. Rerun install.sh." >&2
    exit 1
  fi

  # 2. Move whatever is there now (link or real, never with a trailing slash)
  #    into a fresh backup dir. 3. Swap the new copies in. Steps 2-3 are one
  #    transaction (R4): any failure runs host_rollback, which reads the
  #    moved/swapped lists below (bash locals are visible to called functions).
  local stamp backup="" any=0 moved=() swapped=()
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then any=1; fi
  done
  if [ "$any" -eq 1 ]; then
    backup="$bkroot/$stamp"
    if [ -e "$backup" ]; then backup="$backup.$$"; fi
    if ! mkdir -p "$backup"; then
      rm_new_copies "$dest"
      echo "ERROR: could not create $backup; nothing was replaced." >&2
      exit 1
    fi
  fi
  trap '' INT TERM HUP   # a Ctrl-C mid-swap would skip the rollback
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
      mv "$dest/$name" "$backup/$name" || host_rollback
      moved+=("$name")
    fi
  done
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
      echo "ERROR: $dest/$name reappeared during the install." >&2
      host_rollback
    fi
    mv "$dest/.cw-new.$name" "$dest/$name" || host_rollback
    swapped+=("$name")
  done
  trap - INT TERM HUP

  # Provenance, in link-claude-home's format plus additive keys, from the
  # hash-checked copy (claim 14). `rm -f` first, and mv renames rather than
  # writing through, so a planted symlink cannot redirect the write.
  # installed_parent is best-effort: under a pty wrapper it names whatever shell
  # the wrapper ran (bash, sh), so it is a hint, not evidence of a human (A2).
  {
    echo "installed_parent=$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d ' ' || echo unknown)"
    echo "installed_at=$stamp"
  } >> "$dest/.cw-new.manifest"
  rm -f "$dest/.claude-workflows-manifest"
  mv "$dest/.cw-new.manifest" "$dest/.claude-workflows-manifest"

  echo "Installed into $dest."
  if [ -n "$backup" ]; then
    echo "Previous entries moved to $backup (delete it when satisfied)."
    # A6: keep this run's backup plus the 2 most recent earlier ones. Reached
    # only after a complete swap, so a failed or rolled-back run prunes nothing.
    # Fact-check claim 22: ordering by NAME once deleted this run's backup, the
    # only copy of what it replaced, when earlier names sorted later (a clock
    # that ran ahead). So: this run's backup is never a candidate; the others
    # are ordered by the epoch each completed install wrote into its own backup
    # (.install-stamp); a directory without that stamp was not made by a
    # completed install and is never removed.
    printf 'installed_epoch=%s\n' "$(date -u +%s)" > "$backup/.install-stamp"
    local old d e pruned=0
    while IFS= read -r old; do
      rm -rf "${bkroot:?}/$old"; pruned=$((pruned + 1))
    done < <(
      for d in "$bkroot"/*/; do
        d="${d%/}"
        # The list below is line- and TAB-separated (cut -f2), so a name holding
        # either would be split and mis-pruned (review A3): never a candidate.
        case "$d" in *$'\n'*|*$'\t'*) continue ;; esac
        if [ "$d" = "$backup" ] || [ -L "$d" ] || [ -L "$d/.install-stamp" ]; then continue; fi
        [ -f "$d/.install-stamp" ] || continue
        e="$(sed -n 's/^installed_epoch=\([0-9][0-9]*\)$/\1/p' "$d/.install-stamp")"
        [ -n "$e" ] || continue
        printf '%s\t%s\n' "$e" "${d##*/}"
      done | LC_ALL=C sort -t "$(printf '\t')" -k1,1nr -k2,2r | tail -n +3 | cut -f2)
    echo "Backups: this one plus the 2 most recent earlier installs' are kept in $bkroot ($pruned older removed)."
  fi
  if [ "$wiring_changed" -eq 1 ]; then
    echo
    echo "REMINDER: hooks/wiring.json changed (or was not installed before). Copying the"
    echo "hooks does not wire them. Redo guides/bare-host-hook-wiring.md §2 to merge it"
    echo "into $dest/settings.json."
  fi
}

# --- No-agent gate (Q-058) ------------------------------------------------------
# install.sh runs as the user's uid, so its guarantee, "what you reviewed is what
# is installed", holds only while no agent can run: an agent with the user's uid
# can rewrite the stage, the checkout or its .git during the review, and a
# cc-isolated container can write the checkout through its bind mount. So the
# install is refused while either runs: at startup, before anything is staged,
# again before the host target stages, and after each y, right before that
# target writes. See decision 037, "Trust model (Q-058)", for what this does
# not catch.
#
# A Claude Code process is one of this uid's processes whose command line holds
# a token that is `claude` (or `claude.exe`) or ends in `/claude`, followed by a
# space or the end of the line, anywhere in the command line: the native
# binary, argv0 "claude" or ".../claude", or `node .../bin/claude`. Or one whose
# command line contains `/@anthropic-ai/claude-code/` (the npm package),
# `/claude/versions/` (the versioned native binary, ~/.local/share/claude/
# versions/<ver>) or `/claude-agent-sdk/` (the Agent SDK CLI; review A2).
# pgrep never lists itself and this script's own command line does not match;
# $$ is dropped only as a belt-and-braces guard. A command line with such an
# argument (`vim ./claude`, `tail -f /var/log/claude`) also matches: the install
# is refused, and the message names the process.
CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/|/claude/versions/|/claude-agent-sdk/'

# Q-062 [2]: a process an agent left behind (a detached helper, a loop driver
# between its `claude` iterations) counts as an agent, and it has no Claude
# command line. So any other process of this uid whose working directory is in
# the checkout is refused too. Read from /proc (Linux; the install already needs
# GNU tools). install.sh itself, its ancestors (the shell that ran it) and its
# descendants (its own subshells and git calls) are not "other".

# ppid_of <pid>: print its parent PID, or nothing once it has exited.
ppid_of() {
  local k v _
  while read -r k v _; do
    [ "$k" = "PPid:" ] && { printf '%s\n' "$v"; return 0; }
  done 2>/dev/null < "/proc/$1/status"
}

# in_lineage <pid>: true if <pid> is this script, an ancestor of it, or a
# descendant of it.
in_lineage() {
  local p="$1" q="$$"
  while [ -n "$p" ] && [ "$p" -gt 1 ]; do
    [ "$p" = "$$" ] && return 0
    p="$(ppid_of "$p")"
  done
  while [ -n "$q" ] && [ "$q" -gt 1 ]; do
    [ "$q" = "$1" ] && return 0
    q="$(ppid_of "$q")"
  done
  return 1
}

# procs_in_checkout: print "PID command line" for each other process of this
# uid whose working directory is $REPO_ROOT or below it. Returns 2 when /proc
# is not mounted, 3 when the checkout's own path cannot be resolved. When no
# process's cwd can be read at all (an LSM hiding /proc, a PID-namespaced
# sandbox), it says so on stderr: the scan is then blind, not clean (review
# iteration 2, A14).
#
# A process whose cwd link cannot be read is skipped, not refused: that
# includes ssh-agent and any process that makes itself non-dumpable
# (prctl PR_SET_DUMPABLE), so refusing would block every install while
# ssh-agent runs. A leftover helper does not do that by accident; one that
# does is deliberately evading, which decision 037 lists as not seen (review
# A1; Q-064 asks whether to refuse instead).
procs_in_checkout() {
  local root d pid cwd cmd readable=0
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 3
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
    cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue   # unreadable: see above
    readable=$((readable + 1))
    case "$cwd" in "$root"|"$root"/*) ;; *) continue ;; esac
    pid="${d#/proc/}"
    in_lineage "$pid" && continue
    cmd="$(tr '\0' ' ' 2>/dev/null < "$d/cmdline")"
    [ -n "$cmd" ] || continue                   # exited, or a kernel thread
    printf '%s %s\n' "$pid" "${cmd% }"
  done
  if [ "$readable" -eq 0 ]; then
    echo "NOTE: no process's working directory could be read under /proc, not even this" >&2
    echo "      script's own: the check for processes inside the checkout saw nothing (Q-062)." >&2
  fi
}

# agent_gate <what is refused>: exit 1, naming each agent found and how to
# stop it, when a Claude Code process, another process of this uid working
# inside the checkout (Q-062), or a cc-isolated container runs.
agent_gate() {
  local what="$1" procs rc=0 ctrs err errf
  if ! command -v pgrep >/dev/null 2>&1; then
    echo "ERROR: pgrep is not installed, so install.sh cannot check that no Claude Code" >&2
    echo "       session is running (Q-058). Install procps and rerun. $what" >&2
    exit 1
  fi
  procs="$(pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE")" || rc=$?
  if [ "$rc" -gt 1 ]; then
    echo "ERROR: pgrep failed (exit $rc) while checking for Claude Code sessions (Q-058). $what" >&2
    exit 1
  fi
  procs="$(printf '%s\n' "$procs" | awk -v self="$$" 'NF && $1 != self')"
  rc=0
  local inrepo
  inrepo="$(procs_in_checkout)" || rc=$?
  if [ "$rc" -eq 3 ]; then
    echo "ERROR: could not resolve the checkout's path ($REPO_ROOT), so install.sh cannot" >&2
    echo "       check for processes working inside it (Q-062). $what" >&2
    exit 1
  elif [ "$rc" -ne 0 ]; then
    echo "ERROR: /proc is not mounted, so install.sh cannot check for processes working" >&2
    echo "       inside the checkout (Q-062). It needs Linux /proc. $what" >&2
    exit 1
  fi
  # A Claude Code process already listed above is not named twice. The list is
  # passed through the environment, not awk -v, which would expand escapes
  # such as a literal \n inside a command line (review C11).
  inrepo="$(printf '%s\n' "$inrepo" | CW_SEEN="$procs" awk '
    BEGIN { n = split(ENVIRON["CW_SEEN"], l, "\n"); for (i = 1; i <= n; i++) { split(l[i], f, " "); skip[f[1]] = 1 } }
    NF && !($1 in skip)')"
  # cc-isolated's containers carry the label cc-project=<id> (its --id-label).
  ctrs=""
  if ! command -v docker >/dev/null 2>&1; then
    echo "NOTE: docker not found: cc-isolated containers not checked, treated as none running."
  else
    # Only stdout is the container list. stderr carries warnings (a locale
    # warning, a docker CLI deprecation notice) that must not read as a running
    # container, so it is kept apart and shown only when the call fails.
    # Review C1: a hung docker is otherwise up to 20 s of silence per check.
    echo "Checking for running cc-isolated containers (docker ps; up to 20 s)..."
    errf="$(mktemp "${TMPDIR:-/tmp}/cw-docker-err.XXXXXX")"
    if ! ctrs="$(timeout 20 docker ps --filter label=cc-project \
                   --format '{{.Names}} cc-project={{.Label "cc-project"}}' 2>"$errf")"; then
      err="$(head -n 1 "$errf" 2>/dev/null)"
      echo "NOTE: docker is unreachable ($err): cc-isolated containers not checked, treated as none running." | vis_or_die
      ctrs=""
    fi
    rm -f "$errf"
    ctrs="$(printf '%s\n' "$ctrs" | awk 'NF')"
  fi
  if [ -z "$procs" ] && [ -z "$inrepo" ] && [ -z "$ctrs" ]; then return 0; fi
  {
    if [ -n "$procs" ] || [ -n "$ctrs" ]; then
      echo "ERROR: an agent is running. install.sh installs only while no agent can run, because"
    else
      echo "ERROR: a process may be acting for an agent. install.sh installs only while no agent can run, because"
    fi
    echo "       one could change what you review before it is installed (Q-058)."
    if [ -n "$procs" ]; then
      echo "       Claude Code processes of uid $(id -u) (PID and command line):"
      printf '%s\n' "$procs" | sed 's/^/           /'
      echo "       Stop them: end each Claude Code session (/exit), or kill <PID>."
    fi
    if [ -n "$inrepo" ]; then
      echo "       Other processes of uid $(id -u) working inside $REPO_ROOT (PID and command"
      echo "       line; Q-062: an agent may have left them running):"
      printf '%s\n' "$inrepo" | sed 's/^/           /'
      echo "       Stop them: kill <PID>, or cd each one out of the checkout (an editor or"
      echo "       shell sitting in the repo counts)."
    fi
    if [ -n "$ctrs" ]; then
      echo "       Running cc-isolated containers (name and project id):"
      printf '%s\n' "$ctrs" | sed 's/^/           /'
      echo "       Stop them: docker stop <name>"
    fi
    echo "       Then rerun install.sh. $what"
  } | vis_or_die >&2
  exit 1
}

# has_ctrl <string>: true if it holds a control character: C0 (newline and
# tab included), DEL, or a UTF-8-encoded C1.
has_ctrl() {
  # $(...) drops trailing newlines, but tr removes those too, so any control
  # byte makes the two strings differ.
  [ "$(printf '%s' "$1" | LC_ALL=C tr -d '\001-\037\177')" != "$1" ] && return 0
  printf '%s' "$1" | LC_ALL=C grep -q $'\xc2[\x80-\x9f]'
}

# main: everything that runs. WHY A FUNCTION: bash reads a script file as it
# goes, so a top-level line after a prompt is read only once the prompt returns,
# and an in-place rewrite of this file while [y/N] waits would run new code
# (review R3). A function body is parsed whole before it runs, and the last line
# `main "$@"; exit $?` is one line, so nothing after it is ever read.
main() {
  ASSUME_YES=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --yes) ASSUME_YES="--yes" ;;
      -h|--help) usage; exit 0 ;;
      *) echo "install.sh: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done

  DEST="${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"
  BIN_DIR="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"
  if [ -n "${CLAUDE_HOME_DIR:-}" ]; then HOST_DEST="$CLAUDE_HOME_DIR"; HOST_LABEL='$CLAUDE_HOME_DIR'
  elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then HOST_DEST="$CLAUDE_CONFIG_DIR"; HOST_LABEL='$CLAUDE_CONFIG_DIR'
  else HOST_DEST="$HOME/.claude"; HOST_LABEL='the default, ~/.claude'
  fi

  # Fact-check claim 11b: a newline in a destination defeated the in-repo guard
  # (resolve_phys splits on the first line only), and every listing below is
  # line-based. No real destination needs a control character, so refuse any
  # before either target runs.
  local d
  for d in "$DEST" "$BIN_DIR" "$HOST_DEST"; do
    if has_ctrl "$d"; then
      echo "ERROR: a destination contains a newline or other control character: $(printf '%q' "$d")" >&2
      echo "       (from CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR, CLAUDE_HOME_DIR, CLAUDE_CONFIG_DIR" >&2
      echo "       or HOME). install.sh refuses it. Nothing was installed." >&2
      exit 1
    fi
  done

  # The seven entry names, derived from CLAUDE_HOME_SRC so the host can never
  # install a subset of the payload (FP-066).
  CLAUDE_HOME_NAMES=()
  local item
  for item in "${CLAUDE_HOME_SRC[@]}"; do CLAUDE_HOME_NAMES+=("$(basename "$item")"); done

  # vis (perl) filters every review line; without it the review cannot be shown.
  if ! command -v perl >/dev/null 2>&1; then
    echo "ERROR: perl is not installed. install.sh needs it to show the review safely" >&2
    echo "       (vis). Install perl and rerun. Nothing was staged or installed." >&2
    exit 1
  fi

  agent_gate "Nothing was staged or installed."

  HOST_TMP="" HOST_LOCK="" DC_TMP="" STAGED_COMMIT="" HOST_NEW_IN="" HOST_MADE_DEST=""
  trap host_cleanup EXIT

  DECLINED=0
  install_devcontainer
  install_claude_home
  return "$DECLINED"
}

main "$@"; exit $?
