#!/bin/bash
# board.sh: the cross-project board. Host only, no LLM.
# Reads a registry of repos and prints each one's open `you:` questions as its
# default branch's commit holds them (plan D8: an answer counts once it reaches
# main, so the board shows what the dev cycle reads, never a working tree), and
# writes one owner answer back to a repo's main as an answers-class commit.
# Design: docs/working/research-2026-11-12-host-board-answer-route.md sections
# 3 to 6, docs/working/research-2026-11-12-host-board-listing.md (unit 1) and
# docs/working/research-2026-11-12-host-board-answer-commit.md (unit 2) and
# docs/working/research-2026-11-12-host-board-answer-in-place.md (unit 3);
# owner guide: guides/cross-project-board.md.
#
# Usage: ~/.claude/scripts/board.sh                          (the listing)
#        ~/.claude/scripts/board.sh answer PROJECT Q-NNN TEXT (one answer)
# PROJECT is a registry line, or the last part of exactly one.
# Registry: BOARD_REGISTRY, else ~/.config/claude-board/repos: one absolute
# repo path per line; blank lines and lines starting # are skipped.
# Run log: one line per run appended to ~/.local/state/claude-board/runs.log.
# Exit: 0 every project read (answer: written, even if the run log then
# fails); 1 a bad registry line, an unreadable project, no project listed or
# the run log not written (answer: not written, and the line to paste printed
# with the reason); 3 (answer only) written to main, but the checkout with
# main checked out is behind it, and the repair is printed; 2 the run refused
# before reading any repo (a missing file beside this script, no perl or
# python3, no registry, bad arguments).
#
# Trust (H1): the repos are container-writable, so nothing from them runs here.
# questions.sh and the lib are the copies beside this script (the installed,
# install-reviewed ones on the host), every git call runs under the lib's
# git_harden, only git objects are read (no working tree, so no filter runs;
# the in-place write's one index update runs against an empty work tree, so
# git's racy-entry re-hash of other files cannot run a clean filter either),
# and everything printed passes through the lib's scrub. It assumes the
# owner's PATH holds no `.` or empty entry, since commands run with a repo as
# the current directory.
# shellcheck disable=SC2015  # A && B || C: C is the refusal when either fails
set -euo pipefail
export LC_ALL=C
HERE="$(cd -- "$(dirname -- "$0")" && pwd -P)"
SELF="$HERE/${0##*/}"
QS="$HERE/questions.sh"
LIB="$HERE/lib/dev-cycle-read.sh"
die() { echo "board: $*" >&2; exit 2; }
for f in "$QS" "$LIB"; do
  [[ -f "$f" ]] || die "refusing to run: $f is missing (questions.sh and lib/dev-cycle-read.sh must sit beside board.sh)"
done
[[ $# -eq 0 || ( $# -eq 4 && "$1" == answer ) ]] || die "usage: board.sh, or board.sh answer PROJECT Q-NNN TEXT"
[[ $# -eq 0 || "$3" =~ ^Q-[0123456789]+$ ]] || die "not a question ID (Q- and digits): $3"
command -v perl >/dev/null 2>&1 || die "refusing to run: perl is missing, and the output scrub needs it"
command -v python3 >/dev/null 2>&1 || die "refusing to run: python3 is missing, and questions.sh check needs it"
# shellcheck source=lib/dev-cycle-read.sh
source "$LIB"
scrub_reexec "$SELF" "$@"
# Away from every repo before the first git call, so no repo's config is read
# unhardened; then drop an inherited GIT_DIR and the like, and harden.
cd /
# shellcheck disable=SC2046  # one variable name per line
unset $(git rev-parse --local-env-vars)
# The answer's identity is the owner's (the environment, then the global and
# system config), read here, outside any repo and before git_harden hides that
# config, so commit-tree never falls back to a repo-local identity a container
# can write (FP-177: an identity held in the environment counts too).
IDENT=""
if [[ $# -eq 4 ]]; then
  IDENT=1
  for w in AUTHOR COMMITTER; do
    x="$(git -c user.useConfigOnly=true var "GIT_${w}_IDENT" 2>/dev/null)" \
      && [[ "$x" =~ ^([^\<\>]+)\ \<([^\<\>]+)\>\ [0123456789]+\ [-+][0123456789]{4}$ ]] || { IDENT=""; break; }
    export "GIT_${w}_NAME=${BASH_REMATCH[1]}" "GIT_${w}_EMAIL=${BASH_REMATCH[2]}"
  done
fi
git_harden
REG="${BOARD_REGISTRY:-$HOME/.config/claude-board/repos}"
[[ -f "$REG" ]] || die "no registry at $REG: write one absolute repo path per line (guides/cross-project-board.md)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/claude-board.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

# First line of $1 holding a refusal (✗), else its first line; temp paths read
# as the repo's own.
first_refusal() {
  local l
  l="$(printf '%s\n' "$1" | grep -a -m1 '✗' || printf '%s\n' "$1" | head -n1)"
  l="${l#"${l%%[! ]*}"}"
  printf '%s' "${l//"$2/"/docs/working/}"
}

# Main's three questions files into $1, then questions.sh check and open over
# them: sets QOPEN (open's output), or WHY and returns 3. Runs in the repo,
# after resolve_main.
QOPEN=""; WHY=""
read_main() {
  local d="$1" f e out
  for f in questions questions-archive watching; do
    e="$(main_entry "docs/working/$f.md")"
    case "$e" in
      blob) git cat-file blob "$MAIN_SHA:docs/working/$f.md" > "$d/$f.md" \
              || { WHY="UNREADABLE: docs/working/$f.md could not be read from $MAIN"; return 3; } ;;
      absent) [[ "$f" == watching ]] || { WHY="no questions doc on main: $MAIN has no docs/working/$f.md"; return 3; } ;;
      *) WHY="UNREADABLE: $(entry_why "$e" "docs/working/$f.md")"; return 3 ;;
    esac
  done
  qs() { ( cd -- "$d" && QUESTIONS_LIVE="$d/questions.md" QUESTIONS_ARCHIVE="$d/questions-archive.md" \
           QUESTIONS_WATCHING="$d/watching.md" bash "$QS" "$@" ); }
  if ! out="$(qs check 2>&1)"; then
    WHY="UNREADABLE (questions.sh check: $(first_refusal "$out" "$d"))"; return 3
  fi
  if ! QOPEN="$(qs open 2>"$d/err")"; then
    WHY="UNREADABLE (questions.sh open: $(first_refusal "$(cat -- "$d/err")" "$d"))"; return 3
  fi
}

# open's lines as ID, route and slug, tab-separated.
open_rows() { printf '%s\n' "$QOPEN" | awk -F'  +' 'NF { print $1 "\t" $2 "\t" $3 }'; }

# One project's block. Runs in its own subshell (it cds and sets MAIN_*);
# returns 3 after printing why the project is unreadable.
repo() {
  local n="$1" p="$2" d="$TMP/$1" id route slug r day watches=0 shown=0 lines=""
  mkdir "$d"
  printf '\n== %s\n' "$p"
  cd -- "$p"
  if ! resolve_main || ! main_by_name; then
    echo "   UNREADABLE: no branch named main or master (nor origin/HEAD's), so no default branch to read"; return 3
  fi
  read_main "$d" || { echo "   $WHY"; return 3; }
  while IFS=$'\t' read -r id route slug; do
    [[ -n "$slug" ]] || { echo "   UNREADABLE (questions.sh open: a line that is not ID, route and slug: $id)"; return 3; }
    case "$route" in
      deferred|trigger) watches=$((watches + 1)); continue ;;
      you:*)
        # open lists an ANSWERED live entry until its repo archives it: drop
        # those, but never drop one silently on a skip (an unread file).
        r="$(check_answer "$id")"
        case "$r" in
          "open $id") ;;
          keep\ *|drop\ *|done\ *|unrecognized\ *) continue ;;
          *) echo "   UNREADABLE $id (check_answer: $r)"; return 3 ;;
        esac ;;
    esac
    # Any other route (agent, say) is shown as printed rather than hidden.
    lines+="$(printf '   %s  %-16s  %s' "$id" "$route" "$slug")"$'\n'
    shown=$((shown + 1))
  done < <(open_rows)
  if ! day="$(git log -1 --format=%cd --date=short "$MAIN_SHA")" || [[ -z "$day" ]]; then
    echo "   UNREADABLE: the date of $MAIN's last commit could not be read"; return 3
  fi
  printf '   main %s · %d open watch%s\n' "$day" "$watches" "$([[ $watches -eq 1 ]] || echo es)"
  if [[ $shown -eq 0 ]]; then echo "   nothing open for you"; else printf '%s' "$lines"; fi
  echo "$shown" > "$TMP/$n.count"
}

# A registry line with a trailing CR and surrounding blanks dropped.
trim() { local l="${1%$'\r'}"; l="${l#"${l%%[! $'\t']*}"}"; printf '%s' "${l%"${l##*[! $'\t']}"}"; }
log_run() {
  local d="$HOME/.local/state/claude-board"
  mkdir -p -- "$d" && printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >> "$d/runs.log"
}

# ---- board.sh answer PROJECT Q-NNN TEXT (unit 2: main not checked out, c1;
# unit 3: main checked out in one worktree W with questions.md unmodified, c2) ----
# The awk programs read the line as ENVIRON["LINE"] (LINE is exported): -v
# would expand its backslashes.
# Not written: the reason and the line to paste, exit 1, nothing changed.
nope() {
  printf 'NOT WRITTEN to %s: %s\nPaste this into that repo'"'"'s session instead:\n%s\n' "$PROJ" "$1" "$LINE"
  log_run "answer $QID printed" || echo "board: could not append to the run log" >&2
  exit 1
}
# Main's ref, reflog and object store, and the git dirs, are each absent or a
# real file or directory reached with no symlink (pre-mortem item 6): git
# follows a link planted in .git, so a write (a reflog line, an object) could
# land outside the repository. Prints the first one that is not.
gitdir_link() {
  local c u q r g e x
  local -a qs=() wg=()
  g="$(git rev-parse --absolute-git-dir)" && u="$(git rev-parse --path-format=absolute --git-common-dir)" || { echo "the git directory"; return; }
  [[ ! -L "$g" && ! -L "$u" ]] && c="$(realpath -e -- "$u")" || { echo "the git directory"; return; }
  # With main checked out (c2), also W's own git dir with its index and HEAD's
  # reflog, by their paths under the resolved common dir, so a link in
  # worktrees/ or below shows. git appends to HEAD's reflog only when it runs
  # in W (the registry line is W), but the check costs nothing either way.
  if [[ -n "$W" ]]; then
    x="${WGD#"$u/worktrees/"}"
    [[ "$WGD" == "$u" || ( "$WGD" == "$u/worktrees/$x" && "$x" != */* ) ]] || { echo "the checkout's git directory"; return; }
    if [[ "$WGD" == "$u" ]]; then wg=(index logs/HEAD); else wg=(worktrees "worktrees/$x" "worktrees/$x/index" "worktrees/$x/logs" "worktrees/$x/logs/HEAD"); fi
  fi
  for e in objects refs refs/heads "refs/heads/$MAIN" packed-refs logs logs/refs logs/refs/heads "logs/refs/heads/$MAIN" 'objects/??'; do
    # shellcheck disable=SC2206  # the glob in objects/?? is meant; no name here holds a blank
    qs+=("$c"/$e)
  done
  for e in "${wg[@]}"; do qs+=("$c/$e"); done
  for q in "${qs[@]}"; do
    [[ -e "$q" || -L "$q" ]] || continue
    r="$(realpath -e -- "$q" 2>/dev/null)" && [[ ! -L "$q" && "$r" == "$q" ]] || { echo "${q#"$c"/}"; return; }
  done
}
# Whether main is checked out or being moved in any worktree: a stated copy of
# the worktree scan in land (scripts/build-loop.sh), which this unit may not
# edit or extract (brief 2026-11-12-host-board-answer-commit); keep the two
# alike. Sets WHY and returns 1 for a refusal; when main is checked out, sets
# W to that worktree and WGD to its git directory (unit 3's case, case c2).
wt_scan() {
  local x w="" p q d common n=0 bare="" hd=""
  W=""; WGD=""
  git worktree list --porcelain -z > "$TMP/wts" || { WHY="the worktrees could not be listed"; return 1; }
  while IFS= read -r -d '' x; do
    case "$x" in
      "worktree "*) p="${x#worktree }" ;;
      bare) bare=1 ;;
      "branch refs/heads/$MAIN") [[ -z "$w" ]] || { WHY="$MAIN is checked out in two worktrees"; return 1; }; w="$p" ;;
    esac
  done < "$TMP/wts"
  common="$(git rev-parse --path-format=absolute --git-common-dir)" || { WHY="the git directory could not be found"; return 1; }
  [[ -z "$bare" || ( ! -e "$common/index" && ! -L "$common/index" ) ]] || { WHY="the repository lists as bare but has an index"; return 1; }
  for d in "$common" "$common"/worktrees "$common"/worktrees/* "$common"/worktrees/.[!.]* "$common"/worktrees/..?*; do
    for q in "" /rebase-merge /rebase-apply; do
      [[ ! -e "$d$q" && ! -L "$d$q" ]] || [[ -d "$d$q" && ! -L "$d$q" && -r "$d$q" && -x "$d$q" ]] || { WHY="a worktree's git directory or rebase state cannot be read"; return 1; }
    done
    [[ -d "$d" && "$d" != "$common/worktrees" ]] || continue
    for q in HEAD rebase-merge/head-name rebase-apply/head-name rebase-merge/update-refs BISECT_START; do
      [[ "$q" != HEAD && ! -e "$d/$q" && ! -L "$d/$q" ]] && continue
      [[ -f "$d/$q" && ! -L "$d/$q" && -r "$d/$q" ]] || { WHY="a worktree's git state ($q) cannot be read"; return 1; }
    done
    x=0; q="$(git --git-dir="$d" symbolic-ref -q HEAD 2>/dev/null)" || x=$?
    [[ "$x" -le 1 ]] || { WHY="a worktree's git state (HEAD) cannot be read"; return 1; }
    # land passes a bare HEAD naming main; here its reflog would be written too.
    [[ "$q" != "refs/heads/$MAIN" || -z "$bare" || "$d" != "$common" ]] \
      || { WHY="the bare repository's HEAD names $MAIN, so the write would also touch HEAD's reflog (not built)"; return 1; }
    [[ "$q" != "refs/heads/$MAIN" ]] || { n=$((n + 1)); hd="$d"; }
    for q in rebase-merge/head-name rebase-apply/head-name rebase-merge/update-refs; do
      [[ ! -f "$d/$q" ]] || ! state_is "$d/$q" "refs/heads/$MAIN" || { WHY="a worktree is rebasing $MAIN"; return 1; }
    done
    [[ ! -f "$d/BISECT_START" ]] || ! state_is "$d/BISECT_START" "$MAIN" || { WHY="a worktree is bisecting from $MAIN"; return 1; }
  done
  [[ "$n" -eq "$([[ -n "$w" ]] && echo 1 || echo 0)" ]] || { WHY="a worktree has $MAIN checked out that git worktree list does not show"; return 1; }
  W="$w"; WGD="$hd"
}
# Case c2, main checked out in W: W is what land requires of it (its own top
# level, the worktree whose git dir names main, on main at MAIN_SHA, no merge or
# other operation under way); no symlink from W's resolved top level down to
# the file, nor at W's .git (pre-mortem item 2; W's git dir is gitdir_link's);
# and the file is byte for byte main's blob ($1) and W's index entry (item 3),
# read from objects and raw bytes, never with git status, so no filter runs.
# Sets R (W resolved), or WHY and returns 1.
w_check() {
  local q x f=docs/working/questions.md
  R="$(realpath -e -- "$W" 2>/dev/null)" && [[ -d "$R" ]] || { WHY="$MAIN's checkout at $W is missing"; return 1; }
  for q in .git docs docs/working "$f"; do
    [[ ! -L "$R/$q" ]] || { WHY="$q in $MAIN's checkout $R is a symlink, so the write could land outside it"; return 1; }
  done
  [[ "$(git -C "$R" rev-parse --show-toplevel)" -ef "$R" && "$(git -C "$R" rev-parse --absolute-git-dir)" -ef "$WGD" \
    && "$(git -C "$R" symbolic-ref -q HEAD)" == "refs/heads/$MAIN" && "$(git -C "$R" rev-parse --verify -q 'HEAD^{commit}')" == "$MAIN_SHA" ]] \
    || { WHY="$MAIN's checkout $R is not its own top level, not the one whose git directory names $MAIN, or not on it at $MAIN_SHA"; return 1; }
  for q in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_START rebase-merge rebase-apply sequencer; do
    x="$(git -C "$R" rev-parse --path-format=absolute --git-path "$q")" && [[ ! -e "$x" && ! -L "$x" ]] \
      || { WHY="$MAIN's checkout $R is in the middle of a merge, cherry-pick, revert, rebase or bisect ($q)"; return 1; }
  done
  [[ "$(git -C "$R" ls-files -s -v -- "$f")" == "H 100644 $(git rev-parse "$MAIN_SHA:$f") 0"$'\t'"$f" ]] \
    || { WHY="$f in $MAIN's checkout $R has a staged change or an index flag (its index entry is not $MAIN's blob)"; return 1; }
  [[ -f "$R/$f" ]] && cmp -s -- "$R/$f" "$1" || { WHY="$f in $MAIN's checkout $R is modified (its bytes are not $MAIN's)"; return 1; }
  [[ -w "$R/docs/working" ]] || { WHY="$R/docs/working is not writable"; return 1; }
}
# After the ref moved (c2): main has the answer, W's index entry or file does
# not. Says so, and names the repair; exit 3, never "not written".
behind() {
  printf 'WRITTEN to %s on %s, but its checkout %s is behind: %s.
%s
If %s there holds no edit of yours, bring it level with main:
  git -C %q checkout HEAD -- %s
' \
    "$p" "$MAIN" "$R" "$1" "$LINE" "$f" "$R" "$f"
  log_run "answer $QID written, checkout behind" || echo "board: the run log could not be appended to" >&2
  exit 3
}
state_is() { awk -v w="$2" '{ sub(/^[ \t\r]+/, ""); sub(/[ \t\r]+$/, "") } $0 == w { f = 1 } END { exit !f }' "$1"; }
# The entry's Needs line with Status OPEN made ANSWERED and LINE after it; the
# heading rule is ANSWER_AWK's (the lib), and check_answer re-reads the result.
# shellcheck disable=SC2016  # awk code, not shell
EDIT_AWK='
function heading(l,   h) { if (substr(l, 1, 4) != "### ") return 0; h = substr(l, 5); return h == id || index(h, id " ") == 1 || index(h, id "\t") == 1 }
fence($0) { print; next }
!st && heading($0) { st = 1; print; next }
st == 1 && /^(#|##|###) / { exit 3 }
st == 1 && /^\*\*Needs:\*\*/ { if (!sub(/ · \*\*Status:\*\* OPEN$/, " · **Status:** ANSWERED")) exit 3; print; print ENVIRON["LINE"]; st = 2; next }
{ print }
END { if (st != 2) exit 3 }'
# The allow-list: NEW differs from OLD in exactly those two lines, byte for byte.
# shellcheck disable=SC2016
ALLOW_AWK='
NR == FNR { o[++no] = $0; next } { n[++nn] = $0 }
END { if (nn != no + 1) exit 1; k = 1; while (k <= no && o[k] == n[k]) k++
  e = o[k]; if (k > no || substr(e, 1, 10) != "**Needs:**" || !sub(/ · \*\*Status:\*\* OPEN$/, " · **Status:** ANSWERED", e)) exit 1
  if (n[k] != e || n[k + 1] != ENVIRON["LINE"]) exit 1
  for (i = k + 1; i <= no; i++) if (o[i] != n[i + 1]) exit 1 }'

answer() {
  local p="" l m=0 x route="" r slug blob tree new f=docs/working/questions.md d="$TMP/a"
  [[ "$TEXT" != *[$'\n\r']* ]] || nope "the answer is more than one line; a session records multi-line answers"
  [[ "$TEXT" =~ [^[:space:]] ]] || nope "the answer is empty"
  # shellcheck disable=SC2016  # perl code, not shell
  printf '%s' "$TEXT" | env -u PERL_UNICODE -u PERL5OPT -u PERLIO perl -MEncode -e 'local $/; my $s = <STDIN>;
    my $t = eval { Encode::decode("UTF-8", $s, Encode::FB_CROAK) };
    exit(defined $t && $t !~ /[\x00-\x1f\x7f-\x9f\x{200e}\x{200f}\x{2028}-\x{202e}\x{2066}-\x{2069}]/ ? 0 : 1)' \
    || nope "the answer is not plain UTF-8 text (it holds a control character or invalid bytes)"
  [[ -n "$IDENT" ]] || nope "git knows no identity for you (user.name and user.email in your global git config, or GIT_AUTHOR_NAME and the like)"
  while IFS= read -r l || [[ -n "$l" ]]; do
    l="$(trim "$l")"; [[ -z "$l" || "$l" == \#* ]] && continue
    x="${l%/}"; [[ "$l" == "$PROJ" || "${x##*/}" == "$PROJ" ]] && { p="$l"; m=$((m + 1)); }
  done < "$REG"
  [[ $m -eq 1 ]] || nope "$([[ $m -eq 0 ]] && echo "no registry line is" || echo "$m registry lines are") $PROJ or ends in it"
  [[ "$p" == /* && -d "$p" ]] || nope "the registry line $p is not an absolute path to a directory"
  cd -- "$p"
  x="$(git rev-parse --git-dir 2>&1)" || nope "not a git repository here (git: ${x%%$'\n'*})"
  resolve_main && main_by_name || nope "no branch named main or master (nor origin/HEAD's)"
  mkdir "$d"; read_main "$d" || nope "$WHY"
  while IFS=$'\t' read -r x route slug; do [[ "$x" == "$QID" ]] && break; route=""; done < <(open_rows)
  case "$route" in deferred|trigger) nope "$QID is a watch in watching.md, not an owner question" ;; esac
  check_answer "$QID" > "$TMP/r"; r="$(cat -- "$TMP/r")"; slug="$ANSWER_HEADING"
  case "$r" in
    "open $QID") ;;
    keep\ *|drop\ *|done\ *|unrecognized\ *) nope "$QID is already ANSWERED on $MAIN" ;;
    *) nope "${r#skip }" ;;
  esac
  [[ -n "$route" ]] || nope "$QID is not an open entry of $f (questions-archive.md holds it)"
  [[ "$route" == you:* ]] || nope "$QID's route is $route, not an owner (you:) route"
  [[ "$(git ls-tree "$MAIN_SHA" -- "$f")" == "100644 blob "* ]] || nope "$f is not a plain 100644 file on $MAIN"
  ! grep -q $'\r' -- "$d/questions.md" || nope "$f holds a carriage return, which the board does not rewrite"
  wt_scan || nope "$WHY"
  # gitdir_link's list holds every part of the ref's two paths only for a name with no slash.
  [[ "$MAIN" != */* ]] || nope "the branch name $MAIN holds a slash, and the board checks only a ref path without one"
  # Refs in a reftable, or hooks defined in config, are writes and commands the
  # checks here do not model (H2): refuse rather than trust core.hooksPath for them.
  x="$(git config --get extensions.refStorage || true)"
  [[ -z "$x" || "$x" == files ]] && [[ ! -e "$(git rev-parse --path-format=absolute --git-common-dir)/reftable" ]] \
    || nope "the repository keeps its refs in a reftable, which the board does not write"
  [[ -z "$(git config --get-regexp '^hook\.' || true)" ]] || nope "the repository's git config defines hooks (hook.*), which the board does not write beside"
  x="$(gitdir_link)"; [[ -z "$x" ]] || nope "$x in the git directory is a symlink or leaves it, so a write could land outside the repository"
  [[ -z "$W" ]] || w_check "$d/questions.md" || nope "$WHY"
  awk -v id="$QID" "$FENCE_AWK$EDIT_AWK" "$d/questions.md" > "$d/new" \
    || nope "the entry's header line does not end in **Status:** OPEN"
  [[ $(wc -c < "$d/new") -eq $(($(wc -c < "$d/questions.md") + ${#LINE} + 5)) ]] \
    && awk "$ALLOW_AWK" "$d/questions.md" "$d/new" || nope "the rewritten file changes more than the answer line and Status"
  # Plumbing only: no checkout, status or filter; a temporary index outside the repo.
  blob="$(git hash-object -w --no-filters --stdin < "$d/new")"
  tree="$(GIT_INDEX_FILE="$TMP/index" git read-tree "$MAIN_SHA" && GIT_INDEX_FILE="$TMP/index" git update-index --cacheinfo "100644,$blob,$f" \
    && GIT_INDEX_FILE="$TMP/index" git write-tree)"
  printf 'docs(questions): answer %s from the board\n\nThe answer line and Status only, written on the host by board.sh answer.\n' "$QID" > "$TMP/msg"
  new="$(git commit-tree --no-gpg-sign -p "$MAIN_SHA" -F "$TMP/msg" "$tree")"
  # Post-conditions on NEW before the ref moves: one file changed, and the
  # cycle's own reader reads the entry as answered under the same heading.
  [[ "$(git diff-tree -r --no-renames --raw "$MAIN_SHA" "$new")" == ":100644 100644 $(git rev-parse "$MAIN_SHA:$f") $blob M"$'\t'"$f" ]] \
    || nope "the new commit changes more than $f"
  x="$MAIN_SHA"; MAIN_SHA="$new"; check_answer "$QID" > "$TMP/r"; MAIN_SHA="$x"; r="$(cat -- "$TMP/r")"
  [[ "$r" =~ ^(keep|drop|done|unrecognized)\ $QID$ && "$ANSWER_HEADING" == "$slug" ]] \
    || nope "the cycle's reader does not read the new commit as this answer ($r)"
  git update-ref -m "board: answer $QID" "refs/heads/$MAIN" "$new" "$MAIN_SHA" 2>/dev/null \
    || nope "$MAIN moved while the board wrote (compare-and-swap lost); $MAIN is unchanged"
  : > "$TMP/moved"  # from here on the answer is written, whatever fails next
  # c2: W's index entry, then its file (a temp file beside it, renamed over it
  # once the bytes are still main's old ones), so W never runs ahead of main.
  if [[ -n "$W" ]]; then
    # From an empty work tree, as cwd too: writing an index re-hashes its racily
    # clean entries through their clean filter (git's ce_compare_data), by
    # paths lstat reads relative to cwd; with no files there, nothing is read.
    mkdir -- "$TMP/empty" && ( cd -- "$TMP/empty" && git --git-dir="$WGD" --work-tree=. update-index --cacheinfo "100644,$blob,$f" ) \
      || behind "its index entry could not be updated"
    x=""
    [[ ! -L "$R/docs" && ! -L "$R/docs/working" && ! -L "$R/$f" ]] && x="$(mktemp -- "$R/docs/working/.questions.XXXXXX")" \
      && cat -- "$d/new" > "$x" && chmod --reference="$R/$f" -- "$x" && cmp -s -- "$R/$f" "$d/questions.md" && mv -fT -- "$x" "$R/$f" \
      || { [[ -z "$x" ]] || rm -f -- "$x" 2>/dev/null; behind "its file could not be replaced, or changed while the board wrote"; }
  fi
  printf 'WRITTEN to %s: %s on %s at %s\n%s\n' "$p" "$slug" "$MAIN" "${new:0:12}" "$LINE"
  printf "The cycle's reader reads it as %s%s. The repo's dev cycle reads it at its next iteration.\n" "${r%% *}" \
    "$([[ "${r%% *}" != unrecognized ]] || echo ' (no leading option: an entry that takes [1], [2] or [3] does not act on it)')"
  [[ -z "$W" ]] || printf 'Its checkout %s has it too: that one index entry and file were replaced, nothing else there.\n' "$R"
  log_run "answer $QID written${W:+ in place}" || echo "board: the answer is written, but the run log could not be appended to" >&2
  exit 0
}
if [[ $# -eq 4 ]]; then
  PROJ="$2"; QID="$3"; TEXT="$4"; LINE="$QID: $TEXT (owner, board $(date +%Y-%m-%d))"; export LINE
  # Not under if or ||, which would switch errexit off inside the subshell.
  set +e; ( set -e; answer ); rc=$?; set -e
  [[ ! -e "$TMP/moved" || $rc -eq 0 || $rc -eq 3 ]] || { echo "board: $PROJ's main has the answer, but the board stopped after writing it (exit $rc)" >&2; exit 0; }
  [[ $rc -le 1 || ( $rc -eq 3 && -e "$TMP/moved" ) ]] || nope "the board stopped (exit $rc) before moving $PROJ's main"
  exit "$rc"
fi

n=0; projects=0; bad=0; total=0
while IFS= read -r line || [[ -n "$line" ]]; do
  n=$((n + 1))
  line="$(trim "$line")"
  [[ -z "$line" || "$line" == \#* ]] && continue
  why=""
  if [[ "$line" != /* ]]; then why="not an absolute path"
  elif [[ ! -d "$line" ]]; then why="not a directory"
  elif ! err="$(git -C "$line" rev-parse --git-dir 2>&1 >/dev/null)"; then why="not a git repository (git: ${err%%$'\n'*})"
  fi
  if [[ -n "$why" ]]; then printf 'REGISTRY LINE %d: %s: %s\n' "$n" "$why" "$line"; bad=$((bad + 1)); continue; fi
  projects=$((projects + 1))
  # Not under if or ||, which would switch errexit off inside the subshell.
  set +e; ( set -e; repo "$n" "$line" ); rc=$?; set -e
  if [[ $rc -ne 0 ]]; then
    [[ $rc -eq 3 ]] || echo "   UNREADABLE: the board stopped reading this repo (exit $rc)"
    bad=$((bad + 1))
  else
    total=$((total + $(cat -- "$TMP/$n.count")))
  fi
done < "$REG"

status=0
[[ $bad -eq 0 && $projects -gt 0 ]] || status=1
[[ $projects -gt 0 ]] || echo "board: the registry $REG lists no project"
LOG_DIR="$HOME/.local/state/claude-board"
if ! { mkdir -p -- "$LOG_DIR" && printf '%s projects=%d open=%d unreadable=%d exit=%d\n' \
         "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$projects" "$total" "$bad" "$status" >> "$LOG_DIR/runs.log"; }; then
  echo "board: could not append to $LOG_DIR/runs.log" >&2; status=1
fi
printf '\n%d project%s, %d open for you, %d unreadable or refused; exit %d\n' "$projects" \
  "$([[ $projects -eq 1 ]] || echo s)" "$total" "$bad" "$status"
echo "To answer: board.sh answer PROJECT Q-NNN TEXT (PROJECT: the path above, or its last part)."
exit "$status"
