# Spike: verify Q-117 without installing the branch (cc-verify, hand version)

- **Goal**: One host paste that live-verifies `fix/egress-dnsmasq-ipset` (Q-117) without installing it. It stages the merge of main and the branch, and runs main's installed cc-isolated against that stage on a scratch clone. The same run checks the research doc's four unverified claims (§7).
- **Project state**: roadmap Next 3, step 1 of the DD's recommendation ([4] as [5]'s first step), on `docs/branch-verify-without-install` · inputs: `research-branch-verify-without-install.md`, `dd-branch-verify-without-install.md` · blocked on a host run (the user's `you: terminal` paste)
- **Task status**: paused (paste written; review stopped by instruction after the A16 check; open residuals, including two worst cases that need `denyWrite` for `~/cc-verify`, are in Residual risks and the rubric; nothing has run on the host)

Last verified: 2026-10-15 against main b279a2ba and `fix/egress-dnsmasq-ipset` b26d4b8b23aa (pinned in the paste); their merge tree is `65e65962b12e…`.
Relevant paths: `devcontainer-config/cc-isolated.sh`, `devcontainer-config/install.sh`, `devcontainer-config/devcontainer.json`, `devcontainer-config/Dockerfile`, `guides/cc-isolated-usage.md`, `docs/working/questions-archive.md` (Q-117)
Review: `docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md`

## What it does, and what it never touches

The paste hands the script to `bash -c` as text; it is never written to disk, so nothing can swap it between your paste and its run (review security final F1).

Everything a run creates lives in **one fresh run directory**, `~/cc-verify/run-<RUN>.d`. The script creates it with `mkdir -m 700`, `cd`s into it, and checks it: the physical path is what it created, it is owned by you, the mode is 700, and it is empty. It records the directory's device and inode. From then on it creates, moves and deletes only by relative path from there, never by looking up `~/cc-verify/...` again (A-cap pass 2, F2 structural fix).

| Created (all inside the run directory) | Name | Removed by |
|---|---|---|
| bare scratch clone of your checkout (objects and refs only, no template hooks) | `src.git` | the EXIT trap |
| the stage (main + branch, laid out like install.sh's payload) | `stage/` (mode 700) | the trap |
| scratch workspace | `VERIFY-<TREE8>/` | the trap |
| one container | label `cc-project=<PID>`, where PID is the project id of `<run dir>/VERIFY-<TREE8>` | the trap (`docker rm -f`) |
| two volumes | `cc-<PID>-bashhistory`, `cc-<PID>-claude-config` | the trap |
| one image | the one the container ran, plus any `vsc-verify-<TREE8>-…` build tag | the trap, only with proof that the image is this run's: its id is absent from the run's before-snapshot, and no other container uses it. Never with `-f`: only `vsc-verify-<TREE8>` names are untagged, and the id is removed only if no other tag is left on it. A pre-existing tag the build moved onto it is kept and reported (a `CHECK … FAIL`). Without that proof, the image is reported and kept. |
| before-snapshot | `snap-containers`, `snap-volumes`, `snap-images`, `snap-main` | the trap after a complete teardown. After an incomplete one they stay, so `--clean` can still prove which image is new. The after-state is compared in memory and never written. |
| run record | `record` (`RUN=`, `T8=`) | the trap, last, and only when every removal succeeded. It marks a run as unfinished. |
| log | `log.txt` | kept, with the run directory, on purpose. The script reads its tail through fd 3 only to show a `--register` failure. |

**How it writes and deletes.**
- **Every file goes through `xwrite` or `openlog`.** The data goes to a randomly named temp file in the run directory, created with O_EXCL (`set -o noclobber` with `>`). Its descriptor must be a regular file with exactly one link and the same inode as the name, so neither a symbolic nor a hard link planted there gets the data (A-cap pass 2, F3). A rename then puts the file in place; a rename replaces a planted link rather than following it. The log stays open on fd 3.
- **The stage is not assembled by moving files.** `git archive <tree>:devcontainer-config` and `git archive <tree>:global-instructions` produce paths relative to those subtrees. `tar -x -U` runs inside a subshell that has `cd`ed into `stage/` (or `stage/claude-home/`) and checked that directory's device and inode against the one this run created. `-U` unlinks anything already at a member's path, a planted link included, instead of following it (GNU tar 1.34, tested). It does **not** hold the directories tar creates on the way: a racer that swaps one of them for a link gets the rest of that subtree written through the link. That is a residual (A16 check, F1, reproduced; see Residual risks). There is no raw directory and no `mv`. Afterwards the stage must hold no symlink, and three scripts must already be executable from their committed mode, so nothing runs `chmod`.
- **Teardown deletes only inside the run directory.** `rm_inside` refuses unless the working directory is still the recorded run directory. A link is removed itself, never its target. A directory is deleted only if its realpath is under the run directory and its parent's device and inode are the run directory's; then `rm -rf --one-file-system`, which never follows a link inside the tree.
- **External tools still get absolute paths.** The launcher and the devcontainer CLI receive `<run dir>/stage` and `<run dir>/VERIFY-<TREE8>`. Before each call, `path_ok` checks that the path has no link in any component and still names the recorded directory. That only proves the path was right at that moment. The launcher keeps re-reading its config dir throughout the call, through `check_manifest` and the whole image build (`devcontainer up --override-config`), so the window is the length of the call, not a moment (A16 check, F2).

**What the run checks at runtime****What the run checks at runtime** (the `CHECK` lines). It compares, before and after:
- a hash over every file in `~/.config/claude-devcontainer`;
- the hashes of `manifest.sha256`, `host-tools.sha256` and `verified-live.sha256`;
- where `~/.local/bin/cc-isolated` and `cc-push` point;
- every container, volume and image tag that existed before the run.

Step 4 also checks the path-keyed identity, and step 6 has the launcher write `projects/<PID>.profile` under the *stage*.

**What holds by construction, not by a check.** No command in the script writes `~/.claude` or your checkout's working tree. Its only operations on the checkout are `git rev-parse` and a `git clone` *from* it. It runs no branch code on the host. It needs no session to close: there is no install, so install.sh's agent gate never runs.

## The paste (one block, for a `you: terminal` entry)

Run it from a terminal on the host. The last line is the only one to edit: replace `~/claude-workflows` if your checkout lives elsewhere. The block holds no shell comments outside the script, so it pastes the same into bash and zsh. Its first output line is `script sha256 a65f4c30ba1b8907`; any other value means the pasted block is not this reviewed one, so stop it with Ctrl-C. It takes up to about an hour: the image build, then Q-117's own wait (up to 45 min) for a dl.google.com pool rotation. Do not open a shell or run git inside `~/cc-verify` while it runs, or afterwards if a teardown is reported incomplete: branch code can write the workspace's `.git`. **Before you run it: add `~/cc-verify` to your agents' sandbox `denyWrite`, or run it only while no agent that can write `~/cc-verify` is running.** The run directory holds against the earlier directory swaps. But a same-uid writer can still race the stage extraction into writing in other directories, or edit the stage into host code execution while the image builds (see Residual risks).

```bash
bash -c "$(cat <<'CCVERIFY'
#!/usr/bin/env bash
# spike-q117: live-verify fix/egress-dnsmasq-ipset (Q-117) WITHOUT installing it.
# Candidate [4] of docs/working/dd-branch-verify-without-install.md. Run on the HOST,
# from your own terminal, while other sessions keep running, by pasting the block in
# docs/working/spike-cc-verify-q117.md: it passes this text to `bash -c` and is never
# written to disk, so nothing can swap it between your paste and its run. Its last
# argument is your host checkout, or --clean to remove a crashed run's leftovers.
# Everything a run creates lives in one fresh directory, ~/cc-verify/run-<RUN>.d (mode
# 700), which the script cd's into, checks by device and inode, and works inside by
# relative path. It stages the merge of main and the branch there, clones a scratch
# workspace VERIFY-<TREE8> there, and runs MAIN's installed cc-isolated with
# CLAUDE_DEVC_CONFIG_DIR=<run dir>/stage. Main's config dir, its bin links and every
# other project's container and volumes are never written. Teardown runs on exit.
set -euo pipefail
# Never pass this shell's options to the launcher, even if your shell exports SHELLOPTS.
export -n SHELLOPTS 2>/dev/null || true
# noclobber makes `>` an O_EXCL create of a new file; xwrite and openlog rely on it.
set -o noclobber
# Opt-in credentials devcontainer.json forwards from this shell (devcontainer.json, "GH_TOKEN"
# and "OPENROUTER_API_KEY" in containerEnv) never reach a container running branch code.
unset GH_TOKEN OPENROUTER_API_KEY

V="$HOME/cc-verify"
MAIN_CFG="$HOME/.config/claude-devcontainer"
MAIN_BIN="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"   # install.sh:1311
LAUNCHER="$MAIN_CFG/cc-isolated.sh"
BASE=main
BRANCH=fix/egress-dnsmasq-ipset
# The branch commit this paste was reviewed against. A moved branch refuses: ask for a new paste.
EXPECT_BR=b26d4b8b23aa05130bc9340c0c4c81ecba75897f
# The only paths the merge may change relative to main (the branch's own diff).
BRANCH_PATHS='devcontainer-config/init-firewall.sh
docs/decisions/038-sni-resolve-time-ipset.md
docs/reviews/security-review-2026-10-05-egress-sni-resolve-time-ipset.md
docs/working/egress-android-build.md
test/init-firewall-rules.bats'
# Staged files that reach the host's docker daemon (build and run configuration): they must
# be byte-identical to main's installed copies. Everything else in the stage is either
# built into the image (the code under test) or a host tool this spike never executes.
PINNED=(devcontainer.json Dockerfile)
PROFILE=android
EXPECT_PAYLOAD='PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress claude-home)'
EXPECT_HOME_SRC='CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)'
DC_ITEMS=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress)
HOME_DIRS=(skills workflows guides patterns hooks scripts)

DIED=0 VERDICT=0
die() { DIED=1; printf 'REFUSED: %s\n' "$*" >&2; exit 1; }
xdie() { printf 'REFUSED: %s\n' "$*" >&2; exit 97; }   # die for code that runs in a subshell
devino() { stat -c '%d:%i' -- "$1"; }

# xwrite <name>: write stdin to <name> in the current directory, never following anything
# planted there. A random temp name is created with O_EXCL (noclobber `>`); its descriptor
# must be a regular file with exactly one link and the same inode as the name (so neither
# a symlink nor a hard link planted in the gap gets the data); rename(2), which replaces a
# link instead of following it, then puts it in place.
xwrite() {
  local n="$1" t fd
  case "$n" in */*|.|..|'') xdie "xwrite takes a plain name, not '$n'." ;; esac
  t=".xw.$$.$RANDOM$RANDOM"
  exec {fd}>"$t" || xdie "could not create $t."
  if [ -L "$t" ] || [ ! -f "/proc/self/fd/$fd" ] || [ "$(stat -L -c %h "/proc/self/fd/$fd")" != 1 ] \
     || [ ! "$t" -ef "/proc/self/fd/$fd" ]; then exec {fd}>&-; xdie "$t changed under the script."; fi
  cat >&"$fd"
  exec {fd}>&-
  mv -fT -- "$t" "$n" || xdie "could not put $n in place."
}
# openlog <name>: create the log the same way and keep it open on fd 3 for every later write.
openlog() {
  local t=".xw.$$.log.$RANDOM$RANDOM"
  exec 3>"$t" || die "could not create $t."
  if [ -L "$t" ] || [ ! -f /proc/self/fd/3 ] || [ "$(stat -L -c %h /proc/self/fd/3)" != 1 ] \
     || [ ! "$t" -ef /proc/self/fd/3 ]; then die "$t changed under the script."; fi
  mv -fT -- "$t" "$1" || die "could not put the log in place."
}
# in_dir <name> <dev:ino> <cmd...>: run <cmd> in a subshell cd'd into <name> (relative to the
# run directory), only if that directory is still the one this run created.
in_dir() {
  local n="$1" id="$2"; shift 2
  ( cd -P -- "$n" 2>/dev/null || xdie "cannot enter $n."
    [ "$(devino .)" = "$id" ] || xdie "$n is no longer the directory this run created."
    "$@" )
}
# child_dir <name>: mkdir <name> in the run directory and print its dev:ino, refusing it unless
# it is a real directory whose parent is the run directory.
child_dir() {
  mkdir -m 700 -- "$1" || xdie "could not create $1 (something is already there)."
  ( cd -P -- "$1" && [ "$(devino ..)" = "$RDID" ] && devino . ) || xdie "$1 does not resolve inside the run directory."
}
# path_ok: the absolute path handed to the launcher and the devcontainer CLI still names the
# run directory, with no link in any component. They re-resolve it; this cannot hold it.
path_ok() {
  [ "$(realpath -e -- "$RDP" 2>/dev/null)" = "$RDP" ] && [ "$(devino "$RDP" 2>/dev/null)" = "$RDID" ] \
    || die "the run directory's path ($RDP) no longer names the run directory."
}
# vis: drop control bytes (all but tab and newline) from text that branch code or the
# container produced, so it cannot rewrite the terminal or forge RESULT/CHECK lines.
vis() { LC_ALL=C tr -d '\000-\010\013-\037\177'; }
# relay: vis, then show each line indented under "  | " on stderr (so nothing the container
# prints can start a line with RESULT or CHECK) and pass it unindented on stdout.
relay() { local l; vis | while IFS= read -r l || [ -n "$l" ]; do printf '  | %s\n' "$l" >&2; printf '%s\n' "$l"; done; }
STEP=preflight NOROT=0
say() { STEP="$*"; printf '== %s\n' "$*"; }
REPASTE="re-paste the block from docs/working/spike-cc-verify-q117.md with --clean as its last argument"

# --- teardown: runs inside the run directory and removes only what this run created ------
# The project id is the hash of <run dir>/VERIFY-<T8>, a path inside the run directory, so no
# record can name another project's container or volume. Files are deleted by relative path
# from the run directory, and only after checking that they resolve inside it.
RDP="" RDID="" RUN="" T8="" PID="" SNAP=0 RETAG="" IMGTAGS_CHECKED=""
verify_pid() {  # project_id of <run dir>/VERIFY-<T8> (cc-isolated.sh:372-374)
  printf '%s' "$RDP/VERIFY-$1" | sha256sum | cut -c1-12
}
# rm_inside <name>: delete <name> from the run directory (the cwd). A link is removed itself,
# never its target; a directory only if its parent is the run directory and its realpath is
# under it; rm stays on one file system and never follows a link inside the tree.
rm_inside() {
  local x="$1" here
  [ -e "$x" ] || [ -L "$x" ] || return 0
  here="$(pwd -P)"
  [ "$(devino .)" = "$RDID" ] || { echo "TEARDOWN: refused: the working directory is not the run directory" >&2; return 1; }
  # An explicit status: inside the EXIT trap a bare `return` would return the status the
  # script was exiting with, not rm's.
  if [ -L "$x" ] || [ ! -d "$x" ]; then rm -f -- "$x" && return 0; return 1; fi
  case "$(realpath -e -- "$x")" in "$here"/*) ;; *) echo "TEARDOWN: refused to delete $x: it resolves outside the run directory" >&2; return 1 ;; esac
  [ "$(cd -P -- "$x" && devino ..)" = "$RDID" ] || { echo "TEARDOWN: refused to delete $x: its parent is not the run directory" >&2; return 1; }
  rm -rf --one-file-system -- "$x"
}
teardown() {
  local fail=0 c v i tags pid img imgs="" t other f
  if [[ "$T8" =~ ^[0-9a-f]{8}$ ]] && [ -n "$RDP" ]; then
    pid="$(verify_pid "$T8")"
    for c in $(docker ps -aq --no-trunc --filter "label=cc-project=$pid" </dev/null); do
      img="$(docker inspect -f '{{.Image}}' "$c" </dev/null 2>/dev/null || true)"
      if [[ "$img" =~ ^sha256:[0-9a-f]{64}$ ]]; then imgs="$imgs $img"; fi
      docker rm -f "$c" >/dev/null </dev/null || { echo "TEARDOWN: could not remove container $c" >&2; fail=1; }
    done
    for v in "cc-$pid-bashhistory" "cc-$pid-claude-config"; do
      if docker volume inspect "$v" >/dev/null 2>&1 </dev/null; then
        docker volume rm "$v" >/dev/null </dev/null || { echo "TEARDOWN: could not remove volume $v" >&2; fail=1; }
      fi
    done
    # Images are removed only with proof they are this run's: the run's before snapshot must
    # exist and not list the image id. Without that proof they are reported and kept.
    local before=snap-images
    if [ -L "$before" ]; then before=/nonexistent; fi
    for img in $imgs; do
      if [ ! -f "$before" ]; then echo "TEARDOWN: kept image $img (no before-snapshot proves it new; remove it by hand if it is the verify build)" >&2; continue; fi
      if grep -q " $img\$" "$before"; then continue; fi
      if [ -n "$(docker ps -aq --filter "ancestor=$img" </dev/null)" ]; then echo "TEARDOWN: image $img still in use; not removed" >&2; continue; fi
      # Never -f: untag only this run's vsc-verify-<T8> names, then remove the id only if no
      # other tag is left on it (a tag the build moved onto it stays, and is reported).
      other=""
      for t in $(docker image inspect -f '{{range .RepoTags}}{{.}} {{end}}' "$img" </dev/null 2>/dev/null || true); do
        case "$t" in
          vsc-verify-"$T8"-*|vsc-verify-"$T8":*) docker image rm "$t" >/dev/null </dev/null || { echo "TEARDOWN: could not untag $t" >&2; fail=1; } ;;
          *) other="$other $t" ;;
        esac
      done
      if [ -n "$other" ]; then echo "TEARDOWN: kept image $img: it also carries$other" >&2; continue; fi
      if docker image inspect "$img" >/dev/null 2>&1 </dev/null; then
        docker image rm "$img" >/dev/null </dev/null || { echo "TEARDOWN: could not remove image $img" >&2; fail=1; }
      fi
    done
    # The devcontainer CLI is expected to name its image vsc-<lower-cased folder>-... (unverified).
    # A tag of that exact prefix whose image id is new since the snapshot is this run's build
    # leftover; it is untagged by name (no -f), so other tags on the same id survive.
    if [ -f "$before" ]; then
      while read -r i tags; do
        [ -n "$i" ] || continue
        case "$tags" in vsc-verify-"$T8"-*|vsc-verify-"$T8":*) ;; *) continue ;; esac
        if grep -q " $i\$" "$before"; then continue; fi
        docker image rm "$tags" >/dev/null </dev/null || { echo "TEARDOWN: could not untag $tags" >&2; fail=1; }
      done < <(docker image ls --no-trunc --format '{{.ID}} {{.Repository}}:{{.Tag}}' </dev/null)
    fi
    rm_inside stage || fail=1
    rm_inside "VERIFY-$T8" || fail=1
  fi
  if [ -n "$RDID" ]; then
    rm_inside src.git || fail=1
    for f in .xw.*; do [ "$f" = '.xw.*' ] || rm_inside "$f" || fail=1; done
    if [ "$fail" = 0 ]; then rm_inside record || fail=1; fi
  fi
  return "$fail"
}

main_state() {  # what "main install untouched" compares
  local f
  for f in manifest.sha256 host-tools.sha256 verified-live.sha256; do
    if [ -e "$MAIN_CFG/$f" ]; then sha256sum < "$MAIN_CFG/$f" | sed "s|-\$|$f|"
    else echo "absent $f"; fi
  done
  for f in cc-isolated cc-push; do echo "$f -> $(readlink -f "$MAIN_BIN/$f" 2>/dev/null || echo absent)"; done
  echo "config tree $( (cd "$MAIN_CFG" && find . \( -type f -o -type l \) -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) | sha256sum)"
}
snapshot_before() {   # into the run directory, by plain name
  docker ps -a --no-trunc --format '{{.ID}} {{.Names}}' </dev/null | sort | xwrite snap-containers
  docker volume ls -q </dev/null | sort | xwrite snap-volumes
  docker image ls --no-trunc --format '{{.Repository}}:{{.Tag}} {{.ID}}' </dev/null | sort | xwrite snap-images
  main_state | xwrite snap-main
}

compare() {    # after teardown: did anything outside this run change? (after-state kept in memory)
  local bad=0 x ac av ai am
  ac="$(docker ps -a --no-trunc --format '{{.ID}} {{.Names}}' </dev/null | sort)"
  av="$(docker volume ls -q </dev/null | sort)"
  ai="$(docker image ls --no-trunc --format '{{.Repository}}:{{.Tag}} {{.ID}}' </dev/null | sort)"
  am="$(main_state)"
  if [ "$(cat snap-main 2>/dev/null)" = "$am" ]; then echo "CHECK main install untouched: ok"
  else echo "CHECK main install untouched: FAIL"; diff snap-main <(printf '%s\n' "$am") || true; bad=1; fi
  x="$(comm -23 snap-volumes <(printf '%s\n' "$av" | grep -v '^$'))"
  if [ -z "$x" ]; then echo "CHECK no pre-existing volume removed: ok"
  else echo "CHECK no pre-existing volume removed: FAIL"; printf '  %s\n' "$x"; bad=1; fi
  # Containers and image tags also change when another session's launcher recreates its
  # container (cc-isolated.sh:883, :895), so a disappearance is reported, not failed. This
  # script's only `docker rm` targets label cc-project=<PID>, fresh at step 4.
  x="$(comm -23 snap-containers <(printf '%s\n' "$ac" | grep -v '^$'))"
  [ -z "$x" ] || { echo "NOTE pre-existing containers gone after the run (another session's rebuild? this script removes only label cc-project=$PID):"; printf '  %s\n' "$x"; }
  x="$(comm -23 snap-images <(printf '%s\n' "$ai" | grep -v '^$') | grep -v '^<none>:<none> ' || true)"
  [ -z "$x" ] || { echo "NOTE pre-existing image tags moved or gone (another session's rebuild; a vsc-verify-* one would refute the research §7 image-naming claim):"; printf '  %s\n' "$x"; }
  if [ -n "$IMGTAGS_CHECKED" ]; then
    if [ -z "$RETAG" ]; then echo "CHECK verify image carried no pre-existing tag: ok"
    else echo "CHECK verify image carried no pre-existing tag: FAIL (refutes the research §7 image-naming claim; tag kept, see TEARDOWN):$RETAG"; bad=1; fi
  fi
  if docker volume ls -q </dev/null | grep -q "^cc-$PID-"; then echo "CHECK verify volumes gone: FAIL"; bad=1
  else echo "CHECK verify volumes gone: ok"; fi
  if [ -n "$(docker ps -aq --filter "label=cc-project=$PID" </dev/null)" ]; then echo "CHECK verify container gone: FAIL"; bad=1
  else echo "CHECK verify container gone: ok"; fi
  x="$(comm -13 snap-containers <(printf '%s\n' "$ac" | grep -v '^$'); comm -13 snap-volumes <(printf '%s\n' "$av" | grep -v '^$'); comm -13 snap-images <(printf '%s\n' "$ai" | grep -v '^$'))"
  [ -z "$x" ] || { echo "NOTE created during the run and still present (another session's, or a build leftover; not removed):"; printf '  %s\n' "$x"; }
  return "$bad"
}

on_exit() {
  local rc=$? trc=0 crc=0 orig
  orig=$rc
  trap - EXIT INT TERM HUP
  set +e   # teardown must run even if a write (say, to a closed terminal) fails
  # Only 0, 1, 130 and the verdict's own 2 are meaningful; any other status (a command that
  # failed under set -e, e.g. tar's 2 or git's 128) becomes 1 with a named step.
  if [ "$rc" = 2 ] && [ "$NOROT" != 1 ]; then rc=99; fi
  case "$rc" in
    0|1|2|130) ;;
    97) rc=1; DIED=1 ;;   # a subshell already printed its REFUSED line
    *) printf 'REFUSED: unexpected failure during step "%s" (status %s).\n' "$STEP" "$orig" >&2; rc=1 ;;
  esac
  if [ "$rc" = 1 ] && [ "$DIED" != 1 ] && [ "$VERDICT" != 1 ]; then
    printf 'REFUSED: unexpected failure during step "%s" (status 1).\n' "$STEP" >&2
  fi
  if [ -n "$RDID" ]; then
    say "teardown"
    teardown || trc=1
    if [ "$SNAP" = 1 ]; then compare || crc=1; fi
    if [ "$trc" = 1 ] || [ -e record ]; then
      # The before snapshot stays: it is what lets --clean prove an image is this run's.
      echo "TEARDOWN INCOMPLETE. Fallback: $REPASTE." >&2
      rc=1
    else
      for f in snap-containers snap-volumes snap-images snap-main; do rm_inside "$f"; done
    fi
    [ "$crc" = 0 ] || rc=1
  fi
  echo "RESULT spike-q117 exit=$rc"
  exit "$rc"
}

# --- --clean: remove a crashed run's leftovers ---------------------------------------
if [ "${1:-}" = "--clean" ]; then
  [ -d "$V" ] || { echo "nothing to clean: no $V"; exit 0; }
  VP="$(cd "$V" && pwd -P)"
  shopt -s nullglob
  dirs=("$V"/run-*.d)
  rc=0 n=0
  for d in "${dirs[@]}"; do
    name="${d##*/}"; RUN="${name#run-}"; RUN="${RUN%.d}"
    [[ "$RUN" =~ ^[0-9]+-[0-9]+$ ]] || { echo "skipping $d: not a run directory name (remove it by hand)" >&2; rc=1; continue; }
    if [ -L "$d" ] || [ ! -d "$d" ]; then echo "skipping $d: not a real directory (remove it by hand)" >&2; rc=1; continue; fi
    [ -e "$d/record" ] || [ -L "$d/record" ] || continue   # a completed run: only its log is left
    n=$((n + 1))
    ( cd -P -- "$d" && [ "$(pwd -P)" = "$VP/$name" ] || xdie "$d does not resolve to itself."
      RDP="$(pwd -P)"; RDID="$(devino .)"
      if [ -L record ] || [ ! -f record ]; then xdie "$d/record is not a regular file (remove it by hand)."; fi
      T8="$(sed -n 's/^T8=\([0-9a-f]\{8\}\)$/\1/p' record | head -1)"
      echo "cleaning run $RUN (tree ${T8:-?}${T8:+, project $(verify_pid "$T8")})"
      if teardown; then for f in snap-containers snap-volumes snap-images snap-main; do rm_inside "$f"; done
      else exit 1; fi ) || rc=1
  done
  [ "$n" -gt 0 ] || echo "nothing to clean in $V"
  exit "$rc"
fi

# --- preflight: refuse before creating anything --------------------------------------
# Compare this with the hash the doc gives next to the block: a different hash means the
# block you pasted is not the reviewed one.
[ -n "${BASH_EXECUTION_STRING:-}" ] && echo "   script sha256 $(printf '%s' "$BASH_EXECUTION_STRING" | sha256sum | cut -c1-16)"
[ $# -eq 1 ] || die "usage: the block's last argument is your host checkout of claude-workflows, or --clean."
[ -z "${CLAUDECODE:-}" ] || die "run this from your own terminal, not from inside a Claude Code session."
[ -z "${CLAUDE_DEVC_CONFIG_DIR:-}" ] || die "CLAUDE_DEVC_CONFIG_DIR is set in this shell ($CLAUDE_DEVC_CONFIG_DIR); unset it so main's install is the known default."
for c in git docker devcontainer sha256sum tar find cmp diff comm readlink realpath stat; do
  command -v "$c" >/dev/null 2>&1 || die "'$c' not found on PATH."
done
[ -f "$LAUNCHER" ] && [ -f "$MAIN_CFG/manifest.sha256" ] && [ -f "$MAIN_CFG/devcontainer.json" ] \
  || die "no main install at $MAIN_CFG (need cc-isolated.sh, manifest.sha256, devcontainer.json)."
[ "$(readlink -f "$(command -v cc-isolated || true)" 2>/dev/null)" = "$(readlink -f "$LAUNCHER")" ] \
  || die "the cc-isolated on PATH is not $LAUNCHER; this spike drives main's installed launcher only."
docker info >/dev/null 2>&1 </dev/null || die "docker is not reachable."
REPO_TOP="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" || die "$1 is not inside a git repository."
mkdir -p "$V"
VP="$(cd "$V" && pwd -P)"
shopt -s nullglob
left=("$V"/run-*.d/record)
shopt -u nullglob
[ "${#left[@]}" -eq 0 ] || die "a previous run left state (${left[*]}). First $REPASTE."

# --- the run directory: fresh, mode 700, entered and held -------------------------------
RUN="$(date +%s)-$$"
mkdir -m 700 -- "$V/run-$RUN.d" || die "could not create $V/run-$RUN.d (something is already there)."
cd -P -- "$V/run-$RUN.d" || die "could not enter $V/run-$RUN.d."
[ "$(pwd -P)" = "$VP/run-$RUN.d" ] && [ "$(stat -c '%u %a' .)" = "$(id -u) 700" ] && [ -z "$(ls -A)" ] \
  || die "$V/run-$RUN.d is not the fresh directory this run created."
RDP="$VP/run-$RUN.d"
RDID="$(devino .)"
trap on_exit EXIT
trap 'exit 130' INT TERM HUP
printf 'RUN=%s\n' "$RUN" | xwrite record
LOG="$RDP/log.txt"
openlog log.txt

# --- 1. merge check, in a bare scratch clone (objects only: no hooks, no local config) -
say "1. merge check: $BASE + $BRANCH"
git -c core.hooksPath=/dev/null clone -q --bare --no-local --template= -- "$REPO_TOP" src.git </dev/null || die "could not clone $REPO_TOP."
G=(git --no-optional-locks -C src.git -c core.hooksPath=/dev/null -c core.fsmonitor=false)
MAIN_SHA="$("${G[@]}" rev-parse --verify -q "refs/heads/$BASE^{commit}")" || die "no local branch $BASE in $REPO_TOP."
BR_SHA="$("${G[@]}" rev-parse --verify -q "refs/heads/$BRANCH^{commit}")" || die "no local branch $BRANCH in $REPO_TOP."
[ "$BR_SHA" = "$EXPECT_BR" ] || die "$BRANCH is at $BR_SHA, not the reviewed $EXPECT_BR. Ask for a refreshed paste."
set +e
mt="$("${G[@]}" merge-tree --write-tree --name-only "$MAIN_SHA" "$BR_SHA" 2>&1 </dev/null)"
mrc=$?
set -e
case "$mrc" in
  0) ;;
  1) printf '%s\n' "$mt" | vis | sed 's/^/  | /' >&2; die "$BRANCH does not merge cleanly with $BASE (conflicts above). Merge $BASE into the branch first." ;;
  *) printf '%s\n' "$mt" | vis | sed 's/^/  | /' >&2; die "git merge-tree --write-tree failed (exit $mrc; it needs git >= 2.38)." ;;
esac
TREE="$(printf '%s\n' "$mt" | head -1)"
[[ "$TREE" =~ ^[0-9a-f]{40}([0-9a-f]{24})?$ ]] || die "merge-tree printed no tree id."
# The merge may change only the branch's own paths: everything else is main's, as committed.
changed="$("${G[@]}" diff-tree -r --name-only "$MAIN_SHA" "$TREE")" || die "could not diff $BASE against the merged tree."
while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -qxF -- "$f" <<< "$BRANCH_PATHS" || die "the merge changes $(printf %q "$f"), which is not one of the branch's reviewed paths."
done <<< "$changed"
T8="${TREE:0:8}"
printf 'RUN=%s\nT8=%s\n' "$RUN" "$T8" | xwrite record
echo "   $BASE=${MAIN_SHA:0:12}  $BRANCH=${BR_SHA:0:12}  merged tree=$TREE"

# --- 2. stage the merged tree the way install.sh lays out its payload ------------------
S="$RDP/stage"
say "2. stage -> $S"
# Read into a variable first: `git show | grep -q` under pipefail can fail with SIGPIPE when
# grep exits early on a file larger than the pipe buffer (review fact-check claim 6).
inst="$("${G[@]}" show "$TREE:devcontainer-config/install.sh")" || die "no devcontainer-config/install.sh in the merged tree."
grep -qxF "$EXPECT_PAYLOAD" <<< "$inst" \
  || die "install.sh's PAYLOAD in the merged tree is not the list this spike stages; update the spike."
grep -qxF "$EXPECT_HOME_SRC" <<< "$inst" \
  || die "install.sh's CLAUDE_HOME_SRC in the merged tree is not the list this spike stages; update the spike."
# Extract straight into the held stage directories: `git archive <tree>:<dir>` gives paths
# relative to that subtree, tar runs after cd-ing into a directory checked to be this run's,
# and -U unlinks anything already at a member's path (a planted link) instead of following it.
SID="$(child_dir stage)" || exit 97
CHID="$(cd -P -- stage && [ "$(devino .)" = "$SID" ] && mkdir -m 700 -- claude-home && cd -P -- claude-home && [ "$(devino ..)" = "$SID" ] && devino .)" \
  || die "could not create stage/claude-home inside the stage."
"${G[@]}" archive --format=tar "$TREE:devcontainer-config" -- "${DC_ITEMS[@]}" | in_dir stage "$SID" tar -x -U --no-same-owner -f -
"${G[@]}" archive --format=tar "$TREE:global-instructions" -- CLAUDE.md | in_dir stage/claude-home "$CHID" tar -x -U --no-same-owner -f -
"${G[@]}" archive --format=tar "$TREE" -- "${HOME_DIRS[@]}" | in_dir stage/claude-home "$CHID" tar -x -U --no-same-owner -f -
printf 'commit=%s\ndirty=no\nuncommitted_excluded=0\nassembled_from=cc-verify spike, merge tree %s of %s and %s\n' \
  "$TREE" "$TREE" "$MAIN_SHA" "$BR_SHA" | in_dir stage/claude-home "$CHID" xwrite .manifest
for i in "${DC_ITEMS[@]}"; do [ -e "stage/$i" ] || die "devcontainer-config/$i is missing from the merged tree."; done
for i in cc-isolated.sh cc-push.sh init-firewall.sh; do [ -x "stage/$i" ] || die "stage/$i is not executable (committed mode changed?)."; done
[ -z "$(find stage -xdev -type l -print -quit)" ] || die "a symlink is in the stage (in the merged tree, or planted)."

# --- 3. devcontainer.json is host-trusted config: it must equal main's installed copy --
say "3. devcontainer.json gate"
if grep -q 'initializeCommand' stage/devcontainer.json; then
  die "the staged devcontainer.json names initializeCommand, which runs ON THE HOST."
fi
for i in "${PINNED[@]}"; do
  if ! cmp -s "$MAIN_CFG/$i" "stage/$i"; then
    diff -u "$MAIN_CFG/$i" "stage/$i" | vis | sed 's/^/  | /' || true
    die "the staged $i differs from main's installed copy (diff above). This spike refuses any change to what reaches the docker daemon (runArgs, mounts, lifecycle commands, base image, build steps). If main's install is behind main, reinstall main first."
  fi
done
echo "   devcontainer.json and Dockerfile identical to main's installed copies (runArgs, mounts, lifecycle commands, base image unchanged)"
echo "   staged files that differ from main's install (expect init-firewall.sh; more if main's install is behind main):"
for i in "${DC_ITEMS[@]}" claude-home; do
  [ "$i" = claude-home ] && [ ! -e "$MAIN_CFG/claude-home" ] && { echo "     claude-home (none installed)"; continue; }
  diff -rq "$MAIN_CFG/$i" "stage/$i" >/dev/null 2>&1 || echo "     $i"
done

# --- 4. scratch workspace with its own path-keyed identity -----------------------------
say "4. workspace -> $RDP/VERIFY-$T8"
git -c core.hooksPath=/dev/null -c core.fsmonitor=false clone -q --no-local --template= -- src.git "VERIFY-$T8" </dev/null
WS="$(git -C "VERIFY-$T8" -c core.hooksPath=/dev/null -c core.fsmonitor=false rev-parse --show-toplevel)"
[ "$WS" = "$RDP/VERIFY-$T8" ] || die "workspace toplevel is $WS, not $RDP/VERIFY-$T8."
PID="$(verify_pid "$T8")"                                        # = project_id(WS), cc-isolated.sh:372-374
HPID="$(printf '%s' "$REPO_TOP" | sha256sum | cut -c1-12)"
[ "$PID" != "$HPID" ] || die "verify project id equals $REPO_TOP's ($HPID)."
[ -z "$(docker ps -aq --filter "label=cc-project=$PID" </dev/null)" ] || die "a container already carries label cc-project=$PID."
! docker volume ls -q </dev/null | grep -q "^cc-$PID-" || die "volumes cc-$PID-* already exist."
echo "   project id $PID (your checkout's is $HPID); container label cc-project=$PID; volumes cc-$PID-*"

# --- 5. snapshot, register, probe -------------------------------------------------------
say "5. snapshot before"
snapshot_before
SNAP=1
say "6. register $PROFILE in the stage (main's launcher, CLAUDE_DEVC_CONFIG_DIR=stage); log: $LOG"
[ -z "$(find stage -xdev -type l -print -quit)" ] || die "a symlink appeared in the stage."
path_ok
CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" --register "$WS" --profile "$PROFILE" >&3 2>&1 </dev/null \
  || { tail -n 20 /dev/fd/3 | vis | sed 's/^/  | /' >&2; die "--register failed (log above)."; }
[ "$(cat "stage/projects/$PID.profile" 2>/dev/null)" = "$PROFILE" ] \
  || die "the launcher did not write stage/projects/$PID.profile: its project id differs from this spike's."
# What the bless hashed must still be main's copies: a stage edit between step 3 and the bless
# would otherwise be blessed, and check_manifest would then confirm it.
for i in "${PINNED[@]}"; do
  want="$(sha256sum < "$MAIN_CFG/$i" | cut -d' ' -f1)"
  have="$(awk -v f="$i" '$2 == f { print $1 }' stage/manifest.sha256)"
  [ "$have" = "$want" ] || die "the stage's blessed $i is not main's installed copy (changed after step 3)."
done
HASH="$(sha256sum < stage/manifest.sha256 | cut -c1-16)"       # = blessed_hash, cc-isolated.sh:88-93
echo "   stage blessed: config $HASH"
say "7. --probe-only (builds the image, boots the branch firewall, runs the self-probe)"
path_ok
CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" --probe-only "$WS" </dev/null 2>&1 | relay >&3 \
  || die "--probe-only failed (output above)."
[ "$(tr -d '[:space:]' < stage/verified-live.sha256 2>/dev/null)" = "$HASH" ] \
  || die "no verified-live receipt for $HASH in the stage."
cids="$(docker ps -aq --no-trunc --filter "label=cc-project=$PID" </dev/null)"
[ "$(printf '%s\n' "$cids" | grep -c .)" = 1 ] || die "expected exactly one container labelled cc-project=$PID, found: $cids"
img="$(docker inspect -f '{{.Image}}' "$cids" </dev/null)"
new=yes; if grep -q " $img\$" snap-images; then new=no; fi
# A tag that named a different image before the run and now names this one means the CLI
# reused an existing image name (research §7): reported as a CHECK, and teardown keeps it.
for t in $(docker image inspect -f '{{range .RepoTags}}{{.}} {{end}}' "$img" </dev/null 2>/dev/null || true); do
  if awk -v t="$t" -v i="$img" '$1 == t && $2 != i { f = 1 } END { exit !f }' snap-images; then RETAG="$RETAG $t"; fi
done
IMGTAGS_CHECKED=1
echo "   container ${cids:0:12}, image ${img:7:12} (new: $new)"

# --- 8. Q-117's container block, verbatim (questions-archive.md, Q-117) -------------------
say "8. Q-117 container block (up to ~45 min: waits for a dl.google.com pool rotation)"
Q117="$(cat <<'Q117BLOCK'
U=https://dl.google.com/dl/android/maven2/com/android/application/com.android.application.gradle.plugin/8.7.3/com.android.application.gradle.plugin-8.7.3.pom
L=/run/cc-sni-proxy/proxy.log
echo "firewall marker: $(cat /run/cc-firewall/complete 2>&1)"
echo "dnsmasq instances (expect 2): $(pgrep -u dnsmasq dnsmasq | wc -l)"
echo "fetch 1 (expect 200): $(curl -sS -m 10 -o /dev/null -w '%{http_code}' "$U")"
first=$(grep -oE 'ALLOW sni=dl\.google\.com -> [0-9.]+' "$L" | tail -1 | awk '{print $4}')
echo "first ALLOW address: ${first:-NONE}"
echo "waiting for the pool to drop $first (polls every 30 s, gives up after 45 min)..."
for i in $(seq 1 90); do getent ahostsv4 dl.google.com | awk '{print $1}' | grep -qxF "$first" || break; sleep 30; done
echo "pool now: $(getent ahostsv4 dl.google.com | awk '{print $1}' | sort -u | tr '\n' ' ')"
echo "fetch 2 (expect 200): $(curl -sS -m 10 -o /dev/null -w '%{http_code}' "$U")"
echo "FAIL lines for dl.google.com (expect 0): $(grep -c 'FAIL sni=dl\.google\.com' "$L")"
grep -E 'sni=dl\.google\.com' "$L" | tail -5
Q117BLOCK
)"
path_ok
export CC_PROJECT_ID="$PID" CC_PROJECT_NAME="VERIFY-$T8" CC_EGRESS_PROFILE="$PROFILE" CC_CONFIG_DIR="$S" CC_CONFIG_HASH="$HASH"
# main's installed copy, which step 3 proved byte-identical, so a stage edit since the
# launcher's check_manifest cannot change what exec reads (review security final F4).
out="$(devcontainer exec --workspace-folder "$WS" --override-config "$MAIN_CFG/devcontainer.json" \
         --id-label "cc-project=$PID" bash -c "$Q117" </dev/null 2>&1 | relay)" \
  || die "devcontainer exec of the Q-117 block failed."

# --- 9. verdict (Q-117's own pass rule) --------------------------------------------------
say "9. verdict"
first="$(printf '%s\n' "$out" | sed -n 's/^first ALLOW address: //p')"
pool="$(printf '%s\n' "$out" | sed -n 's/^pool now: //p')"
v=pass
printf '%s\n' "$out" | grep -qx 'dnsmasq instances (expect 2): 2' || v=FAIL
printf '%s\n' "$out" | grep -qx 'fetch 1 (expect 200): 200' || v=FAIL
printf '%s\n' "$out" | grep -qx 'fetch 2 (expect 200): 200' || v=FAIL
printf '%s\n' "$out" | grep -qx 'FAIL lines for dl.google.com (expect 0): 0' || v=FAIL
if [ -z "$first" ] || [ "$first" = NONE ]; then v=FAIL; fi
# "Rerun later" only when nothing else failed: a FAIL line or a bad fetch stays a fail.
if [ "$v" = pass ] && printf ' %s ' "$pool" | grep -qF " $first "; then v=no-rotation; fi
echo "RESULT Q-117 $v (tree $TREE, config $HASH)"
case "$v" in
  pass) exit 0 ;;
  no-rotation) echo "The pool did not rotate within 45 min: rerun later (Q-117's rule)."; NOROT=1; exit 2 ;;
  *) VERDICT=1; exit 1 ;;
esac
CCVERIFY
)" spike-q117 ~/claude-workflows
```

If anything kills the run before its trap fires (a `kill -9`, a closed terminal, a power cut), **re-paste the same block with `--clean` in place of the checkout path** on its last line. The next run refuses to start until you have. Do not run a script file you find in `~/cc-verify` instead: the paste never writes one, and any such file is not this one. Afterwards, `rm -r ~/cc-verify` removes the kept run directories and logs.

## Expected output on success

These are the lines that matter, in order. Long output in between is elided (`…`), and `<…>` stands for run-specific values. Every line the script did not write itself is shown indented under `  | ` with control bytes removed: the launcher's and the container's output, git's conflict listing, the step-3 diff and a `--register` failure's log tail. So only the script's own lines can start with `RESULT`, `CHECK` or `REFUSED`.

```
   script sha256 a65f4c30ba1b8907
== 1. merge check: main + fix/egress-dnsmasq-ipset
   main=<12 hex>  fix/egress-dnsmasq-ipset=b26d4b8b23aa  merged tree=<40 hex>
== 2. stage -> <home>/cc-verify/run-<RUN>.d/stage
== 3. devcontainer.json gate
   devcontainer.json and Dockerfile identical to main's installed copies (runArgs, mounts, lifecycle commands, base image unchanged)
   staged files that differ from main's install (expect init-firewall.sh; more if main's install is behind main):
     init-firewall.sh
     claude-home
== 4. workspace -> <home>/cc-verify/run-<RUN>.d/VERIFY-<TREE8>
   project id <PID> (your checkout's is <other 12 hex>); container label cc-project=<PID>; volumes cc-<PID>-*
== 5. snapshot before
== 6. register android in the stage (main's launcher, CLAUDE_DEVC_CONFIG_DIR=stage); log: <home>/cc-verify/run-<RUN>.d/log.txt
   stage blessed: config <16 hex>
== 7. --probe-only (builds the image, boots the branch firewall, runs the self-probe)
  | NOTE: blessed config <16 hex> has NOT been verified in a live container.
  | …  (devcontainer build and start output)
  | Boundary self-probe passed (canary invisible · egress default-deny · workspace identity · volume not shared · image from central Dockerfile · config <16 hex> · firewall complete).
  | Recorded config <16 hex> as verified live in <home>/cc-verify/run-<RUN>.d/stage/verified-live.sha256.
   container <12 hex>, image <12 hex> (new: yes)
== 8. Q-117 container block (up to ~45 min: waits for a dl.google.com pool rotation)
  | firewall marker: <the marker's content>
  | dnsmasq instances (expect 2): 2
  | fetch 1 (expect 200): 200
  | first ALLOW address: <A>
  | waiting for the pool to drop <A> (polls every 30 s, gives up after 45 min)...
  | pool now: <addresses, not including A>
  | fetch 2 (expect 200): 200
  | FAIL lines for dl.google.com (expect 0): 0
  | <up to 5 proxy-log lines for dl.google.com>
RESULT Q-117 pass (tree <40 hex>, config <16 hex>)
== teardown
CHECK main install untouched: ok
CHECK no pre-existing volume removed: ok
CHECK verify image carried no pre-existing tag: ok
CHECK verify volumes gone: ok
CHECK verify container gone: ok
RESULT spike-q117 exit=0
```

`claude-home` always shows under "differ": the spike's `.manifest` records the merge tree and "cc-verify spike", where install.sh's records a commit and the checkout path. More entries appear when main's install is behind main. The two `NOTE pre-existing … gone` blocks list containers and image tags that disappeared during the run. Another session's launcher recreates its container when its blessed config changed and on every `--probe-only` (cc-isolated.sh:883, :895), and that gives the container a new id and moves its tag. So these are notes, not failures; this script's only `docker rm` targets its own fresh label. A `vsc-verify-*` tag among them would refute the image-naming claim. A `NOTE created during the run and still present` block lists containers, volumes or images that appeared during the run and that the trap did not recognise as its own: either another session's work, or a build leftover (the devcontainer CLI's image naming is unverified, below). It is a note, not a failure.

Exit status. Once the run has started, it is also printed as `RESULT spike-q117 exit=<n>`; preflight refusals and `--clean` exit without that line:
- `0`: Q-117 passed and every CHECK is ok.
- `2`: nothing failed, but the pool did not rotate within 45 min. Q-117's own rule says run again later.
- `130`: interrupted (Ctrl-C, TERM, HUP). The trap still tears down: it runs without errexit, so a failed write (a closed terminal) cannot skip it. Ctrl-C acts at once. A `kill` of the script itself waits for the running step to return, up to the 45-minute wait in step 8 (bash runs a trap only between commands).
- `1`: anything else: a refusal, a Q-117 `FAIL`, a failed CHECK, or an incomplete teardown, which also prints the `--clean` fallback. A command that fails on its own, with any status other than the verdict's, is reported as `REFUSED: unexpected failure during step "<step>" (status <n>).` and mapped to 1. So a `2` only ever comes from the verdict, and every 1 carries a `REFUSED:` line or a verdict line (review API final F1; A-cap security F6).

**What to paste back:** the `script sha256` line, the `RESULT` lines, every `CHECK` line, every `NOTE` block, any `TEARDOWN` lines, and on a refusal the `REFUSED:` line. After a `--clean`, paste its whole output.

## Each step, checked against the code

| Step | Command in the script | Why it is right (source) |
|---|---|---|
| preflight | `unset GH_TOKEN OPENROUTER_API_KEY` | devcontainer.json forwards both from the launching shell into the container (`containerEnv`). A container running branch code gets neither. |
| preflight | refuses with `CLAUDECODE` set, with `CLAUDE_DEVC_CONFIG_DIR` already set, or without `git docker devcontainer …`; checks `docker info` | `CLAUDECODE` mirrors install.sh's target-2 rule (decision 037). An inherited `CLAUDE_DEVC_CONFIG_DIR` would change which config is "main's" (cc-isolated.sh:68-70). |
| preflight | `cc-isolated` on PATH must resolve to `~/.config/claude-devcontainer/cc-isolated.sh`; the bin dir checked is `CLAUDE_DEVC_BIN_DIR`, default `~/.local/bin` | install.sh links it there (install.sh:598, defaults :1310-1311). Honouring `CLAUDE_DEVC_BIN_DIR` keeps the bin-link CHECK meaningful on a non-default install (review API final F4). |
| preflight | a leftover `run-*.d/record` refuses the run; then `mkdir -m 700 ~/cc-verify/run-<RUN>.d` (not `-p`), `cd -P` into it, check it (path, owner, mode 700, empty), record its device and inode; run record and log through `xwrite`/`openlog`; `export -n SHELLOPTS` before `set -o noclobber` | so a crashed run is cleaned before a new one reuses names; every later create, move and delete is relative to this held directory, and no write follows a planted link (A-cap pass 2, F2/F3); noclobber never reaches main's launcher (A-cap security F3) |
| 1 | `git -c core.hooksPath=/dev/null clone --bare --no-local --template=` of your checkout. Later git calls go through `git --no-optional-locks -C <clone> -c core.hooksPath=/dev/null -c core.fsmonitor=false` | The clone copies objects and refs: no `.git/config` filters or merge drivers, no `info/attributes`, no hooks (`--template=` copies none). Those are what install.sh's `git_state_gate` refuses in the checkout (install.sh:209-252; decision 037 "The checkout's git state"). The flags match `repo_git` (install.sh:180-182). The run record and this clone are the only things created before the merge check, and the trap removes both. |
| 1 | the branch must resolve to the reviewed commit `b26d4b8b23aa…` (`EXPECT_BR`) | Ties the run to what this doc reviewed. A ref moved in the checkout's `.git`, which a cc-isolated container can write, refuses the run (review security F2). |
| 1 | `git merge-tree --write-tree --name-only main <branch>`: exit 1 refuses and lists the conflicts; any other non-zero refuses as "needs git ≥ 2.38" | The first-match check. Verified in the sandbox: today the merge is clean (tree `65e65962…`, the same tree a real `git merge` produces), and `feat/q125-cc-isolated-sandbox` is refused on `hooks/live-verify-gate.sh`. |
| 1 | `git diff-tree -r --name-only <main> <tree>` may list only the branch's five paths | Everything else in the stage is main's committed content. `main` itself is still resolved by name. What reaches the docker daemon from it is pinned in step 3. |
| 2 | refuses unless the merged tree's `install.sh` has exactly the `PAYLOAD=(…)` and `CLAUDE_HOME_SRC=(…)` lines the spike stages, read into a variable first (no `git show \| grep -q` under pipefail) | install.sh:110 and :135. The variable avoids SIGPIPE: install.sh is larger than a pipe buffer, and the review reproduced spurious refusals with the pipe (fact-check claim 6). |
| 2 | `git archive <tree>:devcontainer-config -- <10 items>`, `git archive <tree>:global-instructions -- CLAUDE.md` and `git archive <tree> -- skills … scripts`, each piped into `tar -x -U` inside a subshell `cd`ed into `stage/` or `stage/claude-home/` whose device and inode match the ones this run created; refuses any symlink in the stage afterwards | The same sources as `extract_commit` (install.sh:257-317) and the same no-symlink rule (:288). Extracting a subtree directly replaces the old raw directory and `mv` (A-cap pass 2, F2): no file is moved from a directory a swap could redirect, and `-U` replaces a planted link at a member's path instead of writing through it. |
| 2 | layout: the 10 PAYLOAD files and dirs at the stage root, `claude-home/` holding `CLAUDE.md`, the six dirs and a `.manifest` (via `xwrite` in the held `claude-home`). The three scripts must already be executable from their committed mode (100755), so nothing runs `chmod`. | Matches `install_devcontainer` (install.sh:471-508), `assemble`'s `.manifest` keys (:356-361) and install.sh:596's modes. The Dockerfile copies `claude-home/` (Dockerfile:500), `egress/` (:486) and the scripts (:487-491) from the build context, which is `CC_CONFIG_DIR` (devcontainer.json:24-26). It also normalizes the payload's modes (:517-520), so `xwrite`'s 0600 on `.manifest` does not matter. The review checked that the current launcher and the pre-Q-089 launcher both bless and check a stage built this way. |
| 3 | refuses (with `grep -q`, so no staged line reaches the terminal) if the staged `devcontainer.json` names `initializeCommand`, or if the staged `devcontainer.json` **or `Dockerfile`** differs at all from main's installed copy (shows `diff -u`) | These two files are what the docker daemon runs with. devcontainer.json carries runArgs (devcontainer.json:58-69), mounts (:77-80) and lifecycle commands. The Dockerfile is pinned too because its base image's `devcontainer.metadata` label can add privileged, capAdd, securityOpt and mounts to the run config, and its `# syntax=` line and `RUN` options reach BuildKit (review security F1). Whole-file identity is stricter than "refuse runArgs/mounts changes": devcontainer.json is JSONC, so a line diff cannot reliably isolate keys. The other staged files are either built into the image as the code under test (`init-firewall.sh`, `cc-sni-proxy.py`, `link-claude-home.sh`, `egress/`, `claude-home/`) or host tools this spike never executes (below). |
| 4 | `git … clone --no-local --template=` (hooks and fsmonitor off) into `VERIFY-<TREE8>` in the run directory; its toplevel must equal `<run dir>/VERIFY-<TREE8>`; PID = `printf %s <that path> \| sha256sum \| cut -c1-12` | `resolve_workspace` uses `git rev-parse --show-toplevel` (cc-isolated.sh:354-367), and `project_id` is that exact pipeline (cc-isolated.sh:372-374). The display name is `basename` of the workspace (cc-isolated.sh:814 → devcontainer.json:22), so it reads `VERIFY-<TREE8>`. |
| 4 | refuses if PID equals your checkout's, if any container already carries label `cc-project=<PID>`, or if any `cc-<PID>-*` volume exists | The launcher selects the container by `--id-label cc-project=$pid` (cc-isolated.sh:836) and names volumes `cc-${CC_PROJECT_ID}-…` (devcontainer.json:78-79). With a fresh PID, `--remove-existing-container` (cc-isolated.sh:883) can only hit this run's container. |
| 5 | snapshot (the list under "What the run checks") | DD constraint H2's observable, widened to the whole config dir after review (fact-check claim 3). Pre-existing containers or image tags that disappear are reported as NOTEs, not failures, because other sessions' launchers recreate theirs (review performance final F1). |
| 6 | `CLAUDE_DEVC_CONFIG_DIR=<stage> ~/.config/claude-devcontainer/cc-isolated.sh --register <ws> --profile android` | Flag syntax: cc-isolated.sh:9-11 and :736; guide `cc-isolated-usage.md:23,537`. `register_project` checks `$(config_dir)/egress/android.txt`, writes `$(config_dir)/projects/<pid>.profile` and re-blesses (cc-isolated.sh:434-480). `bless_manifest` writes only under `config_dir` (cc-isolated.sh:281-319). The script then requires `stage/projects/<PID>.profile`, which proves the launcher computed the same PID. |
| 6 | after the bless, the stage manifest's `devcontainer.json` and `Dockerfile` hashes must equal main's installed copies'; stage hash = `sha256sum < stage/manifest.sha256 \| cut -c1-16` | Closes the window between step 3 and the bless (review security F3). From then on, `check_manifest` at `--probe-only` (cc-isolated.sh:332-350) holds the stage to what was blessed. The hash is `blessed_hash` (cc-isolated.sh:88-93). |
| 7 | `CLAUDE_DEVC_CONFIG_DIR=<stage> …/cc-isolated.sh --probe-only <ws>`; then requires `stage/verified-live.sha256` = that hash | The probe action always rebuilds (cc-isolated.sh:880-885) and runs `probe_boundary` (:577-705). Only a full pass calls `record_verified_live` into `config_dir` (:113-115, :702). Main's launcher loads host code only from its own directory (cc-isolated.sh:714-718), and so did the pre-Q-089 launcher (`source "$(dirname …BASH_SOURCE…)/cc-exit-scan.sh"`). So the stage's copies of `cc-isolated.sh` and the host tools are hashed but never executed. They are staged because `enforcement_files`/`host_tool_files` (cc-isolated.sh:128-151, :199-203) and the bless need them present. The review confirmed that the launcher, run against the stage, executes no staged file and writes only under it. |
| 7 | exactly one container with the label; reports whether its image is new | `docker inspect -f '{{.Image}}'` |
| 8 | exports `CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR CC_CONFIG_HASH`, then `devcontainer exec --workspace-folder <ws> --override-config ~/.config/claude-devcontainer/devcontainer.json --id-label cc-project=<PID> bash -c "$Q117"` | Exactly the five variables `rebuild_hint` says the by-hand CLI needs (cc-isolated.sh:561-563), and the launcher's `dc` args (:834-836), except that the config path is main's installed copy, which step 3 proved byte-identical to the stage's. So a stage edit made after the launcher's `check_manifest` cannot add `remoteEnv` or the like to what exec reads (review security final F4). `bash -c` with the block as one argument is how the probe runs in-container scripts (cc-isolated.sh:608). stdin is `/dev/null`, so nothing reads the rest of the script. |
| 8 | Q-117's container block, verbatim | questions-archive.md:2463-2475 (byte for byte). It runs as `remoteUser: node` (devcontainer.json:71). node can read the proxy log: on the branch, `/run/cc-sni-proxy` is 0755 (`init-firewall.sh:1392-1393` on the branch) and the log is opened 0644 (`cc-sni-proxy.py:260`). The `ALLOW sni=… -> <ip>:<port>` field order is the proxy's (`cc-sni-proxy.py:207`). dl.google.com is only in `egress/android.txt`. |
| 7-8 | launcher and container output goes through `relay`: control bytes (all but tab and newline) are dropped, and each line is shown under `  \| ` | Branch code builds and boots this container, so its output cannot rewrite the terminal, set the clipboard through OSC 52, or print a line that looks like the script's `RESULT`/`CHECK` (review security F8). |
| 9 | verdict = Q-117's own rule: 2 instances, both fetches 200, 0 FAIL lines, the first ALLOW address absent from "pool now". `no-rotation` (exit 2) applies only when nothing else failed | questions-archive.md:2478. The ordering was fixed in review: a real failure used to report as "rerun later" (fact-check claim 9a). |
| trap / `--clean` | Runs inside the run directory (`--clean`: `cd -P` into each real `run-*.d` with a `record`, check it resolves to itself). Order: the label's containers; the two named volumes; the containers' images (no `-f`, only with before-snapshot proof, keeping any non-verify tag); `vsc-verify-<TREE8>-…` tags; then `stage`, `VERIFY-<TREE8>`, `src.git` and any temp file through `rm_inside`; `record` last, only if all succeeded. `rm_inside` refuses unless the working directory is still the recorded one. It removes a link itself, never its target, and deletes a directory only if its realpath is under the run directory and its parent is the run directory (`rm -rf --one-file-system`). The project id is recomputed from `<run dir>/VERIFY-<TREE8>`. | A planted `record` can only name a `VERIFY-<8 hex>` path inside its own run directory, so it cannot point `docker rm` or `volume rm` at another project. Without a real before-snapshot it removes no image. Teardown cannot delete outside the run directory: F2's two swaps (reproduced on 5a745059) leave their victim directories untouched now. |

## What was tested here, without a host

The sandbox has no docker, and nothing ran for real. The script was run end to end in a scratch `HOME`, with fake `docker` and `devcontainer` commands on PATH. The fake devcontainer records `up`, creates a labelled container, two volumes and an image, and answers the probe's in-container checks. The real main launcher from `main` was installed into the fake `~/.config/claude-devcontainer` and blessed there. So steps 6-7 ran main's real `--register`, `bless_manifest`, `check_manifest` and `probe_boundary` against the stage. After the review fixes:

- **Pass path:** `RESULT Q-117 pass`, every `CHECK` ok, exit 0, run in the paste's `bash -c` form. A pre-existing "harness" container, volume and image survived. Main's config dir, manifests and bin link were unchanged.
- **Refusals:**
  - a branch that conflicts (`feat/q125-cc-isolated-sandbox` swapped in, with its own `EXPECT_BR`): refused at step 1 on `hooks/live-verify-gate.sh`, with no docker call besides the preflight `docker info`;
  - a moved branch (`EXPECT_BR` mismatch): refused at step 1;
  - a `devcontainer.json` difference (`--privileged` added) and a `Dockerfile` difference: each refused at step 3, with the diff shown.
- **Failures:** 3 FAIL lines gave `RESULT Q-117 FAIL` with teardown and CHECKs ok, exit 1. That stayed `FAIL`, not `no-rotation`, even when the pool also did not rotate. No rotation alone gave exit 2. A `tar` that exits 2 in step 2 gave `REFUSED: unexpected failure during step "2. stage -> …" (status 2)` and exit 1.
- **Forged output:** a container line `RESULT Q-117 pass`, and one carrying ESC/CR bytes, were shown indented and stripped. The real verdict line followed, unchanged.
- **Planted run record:** a `run-*.env` naming the harness's project id and image removed nothing. So did one with `T8=deadbeef` next to images tagged `acme/preverify-deadbeef:1` and `vsc-verify-deadbeef-x`.
- **Crash:** `kill -9` during step 8 left the container, volumes, image, stage, clone and run record. The next run refused, `--clean` removed exactly those, and the harness's objects survived.
- **A-cap matrix (on the final script):**
  - everything above;
  - a watcher swaps the run record and then the log for symlinks during the run: both victim files stay untouched (the same case wrote both victims on the previous version);
  - a build that moves a pre-existing tag onto the verify image: `CHECK verify image carried no pre-existing tag: FAIL`, the tag is kept, exit 1;
  - `--clean` with a dangling `run-*.env`: skipped, exit 1;
  - an exported `SHELLOPTS`: the launcher is unaffected. This case is weak evidence: bash refuses the assignment (`SHELLOPTS: readonly variable`), so it does not set the value it names. The `export -n` line was confirmed separately by the A-cap pass 2 check;
  - the `script sha256` line matches;
  - a `snap-main` link planted in the run directory: the victim file stays untouched (rename replaces the link);
  - **(A-cap pass 2, F2)** two deterministic swaps, made by PATH shims at the moment an attacker would race for:
    - the stage directory replaced by a link to a victim directory: the run refuses (`stage is no longer the directory this run created`) and the victim stays untouched;
    - the old raw source directory replaced by a link: on 5a745059's script the victim's files were moved into the stage and deleted; now there is no raw directory to swap. On this design the case is vacuous, so it shows the attack surface is gone, not that a defence works.

    Both cases fail on 5a745059's script and pass on the final one.

  That makes 27 cases, all ok.
- `bash -n` and `shellcheck -S warning` are clean. The script was run in the paste's own form (`bash -c "$(cat …)" spike-q117 <arg>`). The paste block itself was executed under bash and `zsh -f` against the fake HOME, and gave the same pass. It ran under `bash -i`, `zsh -f` and `zsh -f -i` too, and gave the same pass.

## Not verified (needs the host run)

1. **Image naming** (research §7). The trap removes the image the verify container ran, if the before-snapshot proves it new and no other container uses it. It also untags, by name and without `-f`, any `vsc-verify-<TREE8>-…` tag whose id is new since the snapshot. That second rule assumes the devcontainer CLI names its image `vsc-<lower-cased folder>-…`. If that is wrong, a base image may be left behind: it shows under `NOTE … still present`, nothing deletes it, and you remove it by id. A pre-existing `vsc-verify-*` tag listed under `NOTE pre-existing image tags moved or gone` would refute the claim.
2. **Main's launcher on a stage dir** (research §7): steps 6-7 are the test. They were exercised against the real launcher in the sandbox, but not with the real CLI and dockerd.
3. **The devcontainer CLI's `exec`** with the five exported variables, taken from `rebuild_hint` (cc-isolated.sh:561-563) and not observed. A failure shows as `REFUSED: devcontainer exec of the Q-117 block failed.`
4. **`devcontainer exec` passes the inner exit status back.** Assumed. So is `docker ps --filter ancestor=<image id>` listing the containers that use an image.
5. **git ≥ 2.38 on the host**, for `merge-tree --write-tree`. Without it, step 1 refuses.
6. **`devcontainer read-configuration`** (research §7): not used. The whole-file pin in step 3 replaces it.
7. **The CLI merging a base image's `devcontainer.metadata` label** into the run config is taken from the dev container spec, not observed. The Dockerfile pin makes it moot here.
8. **Real docker's output formats.** The fake docker ignores `--format` for `ps`. The script assumes two things, both emulated rather than observed:
   - `docker image ls --no-trunc --format '{{.ID}} …'` prints ids in the same `sha256:…` form as `docker inspect -f '{{.Image}}'`;
   - `docker image inspect -f '{{range .RepoTags}}{{.}} {{end}}'` lists an image's tags, and `docker image rm <id>` without `-f` refuses an id that still has several tags.
9. **`devcontainer exec` runs as `remoteUser` (node) by default**, as the launcher's own probes assume.
10. **The devcontainer CLI's own writes on the host** (caches, temp files, and any image-build metadata outside docker). They are not part of the snapshot.
11. **Files the container writes into the workspace bind mount as root** could make teardown's `rm -rf` of `VERIFY-<TREE8>` fail, for `--clean` too. The trap would then report an incomplete teardown, and you would remove the directory with elevated rights.
12. **The build's network, time and cache.** Base layers are probably cache-shared with main's image, because the Dockerfile is identical. The build arguments the launcher passes, including `TZ` (Dockerfile:16-17), must match main's for that to hold. Teardown removes the verify images but not BuildKit's build cache for their layers (pruning is global, so the script does not). That cache is a few MB when main's cache is hit, but multi-GB if not. Neither the snapshot nor a NOTE shows it; check `docker system df` afterwards (review performance final F2).

## Residual risks (accepted for a spike)

- **The verdict is attested by the code under test.** The branch's `init-firewall.sh` runs as root in the container before the Q-117 block, so a hostile branch could fake the block's output. Main's own probe has the same trust shape. What the paste guarantees is that the branch reaches only the container, not the host. The review is what judges the branch's code (review security F5).
- **`main` is resolved by name** from the checkout's `.git`, which a cc-isolated container can write. Pinning the branch, the five-path rule and the step-3 pins mean a planted `main` can change only what is built *into* the image: it cannot change how the container is run or built. The verdict would then be about the wrong code, not a host compromise.
- **The stage after `check_manifest`.** A same-uid process could rewrite a stage file between the launcher's `check_manifest` and the docker build reading it. That is the same swap window decision 037 accepts for install target 1. cc-isolated containers cannot reach the stage. The verify container itself reaches only its own workspace, `VERIFY-<TREE8>`, through its bind mount.
- **git and global config.** A filter or merge driver defined in your global `~/.gitconfig`, and assigned by a committed `.gitattributes`, would run during `git archive`, `merge-tree` or `git clone`. That is install.sh's residual too (decision 037). `git clone --no-local` runs `upload-pack` against your checkout, which reads that repository's config; `uploadpack.packObjectsHook` is honoured only from protected (global/system) config.
- **8-bit control bytes** (C1, e.g. 0x9b CSI) are not stripped, because stripping them would mangle UTF-8 text. Only terminals in 8-bit mode act on them.
- **A planted run record together with a planted before-snapshot** (by a same-uid writer of `~/cc-verify`, inside a `run-*.d`) can make `--clean` untag `vsc-verify-<8 hex>-…` names and remove an *untagged* image that a `VERIFY-<8 hex>`-labelled container ran (never with `-f`). It cannot reach other projects' containers or volumes, other image names, or any file outside that run directory (review security final F5; A-cap fact-check claim 14).
- **What a same-uid writer of `~/cc-verify` can still do** (after the A-cap pass 2 structural fix; reduced, not closed):
  - **Write inside the run directory.** Mode 700 does not stop the same uid. Such a writer can edit staged files after the script's checks and after the launcher's `check_manifest`, while the image builds. **Worst case: a stage `devcontainer.json` edited in that window (`initializeCommand`, privileged `runArgs`) means code execution on the host.** Decision 037 accepts the equivalent window for install target 1, but behind its agent gate, which this spike does not have. So the comparison holds only if `~/cc-verify` is no more writable by agents than `~/.config/claude-devcontainer` (A16 check, F3).
  - **Rename the run directory away and plant a link at its path** while the launcher or the devcontainer CLI is using `<run dir>/...`. `path_ok` refuses if this happened before a call, but not during one (see above).
  - **Swap a directory that `tar -x` has just created in the stage for a link.** The rest of that subtree's files, with names and contents fixed by the merged tree, are then written into any directory you can write, `~/.claude` included, despite its `denyWrite` (the script runs outside the sandbox). With a swap back, the run still ends `RESULT Q-117 pass`, because the later `find -type l` check comes too late (A16 check, F1: reproduced 4/4, with a clean pass 2/3 when the directory is swapped back). The same leading-directory class is untested for `git clone` into `src.git` and `VERIFY-<TREE8>`. The fix is an extractor that refuses links at every path component (`openat` with `O_NOFOLLOW`, e.g. Python's `tarfile` with a directory fd), listed for the `cc-verify` unit. A planted FIFO can also block a write.
  - **Deny service** by killing the run, which a same-uid process can always do.

  Adding `~/cc-verify` to the agents' sandbox `denyWrite` closes all of these. That is a settings change for you, not part of this paste. Without it, **do not run the paste while an agent that can write `~/cc-verify` is running.** The worst cases above are host code execution and writes into any directory you own.
- **A leftover `VERIFY-<TREE8>`** after an incomplete teardown has a `.git` that branch code could have written. Do not run git or a git-aware prompt there; run `--clean` (review security F7).
- **An agent running the paste.** The `CLAUDECODE` refusal stops accidents only. An agent with host docker access already has more than this script gives it.
- **The verdict covers the merge tree, not the branch tip.** That is deliberate (DD H6). A clean `git merge` of this branch into an unchanged main produces exactly this tree.

## Toward the `cc-verify` tool (not needed for this spike)

The final API review found that a reusable tool cannot adopt this paste's surface unchanged:
- exit codes should follow decision log row 58: 2 = bad usage, tool codes above 2. Row 58 maps only Ctrl-C at a prompt to 1, so whether an interrupted run exits 1 or 130 is open (API F2);
- it needs a sibling-style flag parser with `--help`;
- refusals should use the siblings' `ERROR:`/`NOTE:` prefixes;
- it should honour both `CLAUDE_DEVC_*` variables and give `~/cc-verify` an override variable;
- it needs one line grammar for results;
- it needs the DD's guard against deleting a clone that holds commits, and a branch argument in place of the pinned commit and path list.
- it should keep the spike's held run directory (fresh `mkdir -m 700`, entered, identity-checked, all work by relative path, inside-only teardown), adopted in the spike after A-cap pass 2 (F2/F3).

These are in `docs/reviews/api-consistency-review-2026-10-15-cc-verify-spike.md` (F2-F6, F9) for the next unit's plan.
