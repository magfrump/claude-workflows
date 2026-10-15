# Spike: verify Q-117 without installing the branch (cc-verify, hand version)

- **Goal**: One host paste that live-verifies `fix/egress-dnsmasq-ipset` (Q-117) without installing it. It stages the merge of main and the branch, and runs main's installed cc-isolated against that stage on a scratch clone. The same run checks the research doc's four unverified claims (§7).
- **Project state**: roadmap Next 3, step 1 of the DD's recommendation ([4] as [5]'s first step), on `docs/branch-verify-without-install` · inputs: `research-branch-verify-without-install.md`, `dd-branch-verify-without-install.md` · blocked on a host run (the user's `you: terminal` paste)
- **Task status**: paused (paste written and reviewed in two iterations, outcome in the rubric linked below; nothing has run on the host)

Last verified: 2026-10-15 against main b279a2ba and `fix/egress-dnsmasq-ipset` b26d4b8b23aa (pinned in the paste); their merge tree is `65e65962b12e…`.
Relevant paths: `devcontainer-config/cc-isolated.sh`, `devcontainer-config/install.sh`, `devcontainer-config/devcontainer.json`, `devcontainer-config/Dockerfile`, `guides/cc-isolated-usage.md`, `docs/working/questions-archive.md` (Q-117)
Review: `docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md`

## What it does, and what it never touches

The paste writes one script, `~/cc-verify/spike-q117.sh`, and runs it. Everything the script creates is kept under `~/cc-verify/` and named from the run:

| Created | Name | Removed by |
|---|---|---|
| bare scratch clone of your checkout (objects and refs only, no template hooks) | `~/cc-verify/src-<RUN>.git` | the EXIT trap |
| the stage (main + branch, laid out like install.sh's payload) | `~/cc-verify/stage-<TREE8>` | the trap |
| scratch workspace | `~/cc-verify/VERIFY-<TREE8>` | the trap |
| one container | label `cc-project=<PID>`, where PID is the project id of `~/cc-verify/VERIFY-<TREE8>` | the trap (`docker rm -f`) |
| two volumes | `cc-<PID>-bashhistory`, `cc-<PID>-claude-config` | the trap |
| one image | the one the container ran, plus any `vsc-verify-<TREE8>-…` build tag | the trap, only with proof the image is this run's: its id is absent from the run's before-snapshot (and, for the container's image, no other container uses it). Without that proof it is reported and kept. |
| raw extract | `~/cc-verify/stage-<TREE8>.raw` (only during step 2) | step 2, or the trap |
| before/after snapshots | `~/cc-verify/snap-<RUN>-before`, `…-after` | the trap after a complete teardown; after an incomplete one, the before-snapshot stays so `--clean` can still prove which image is new |
| run record | `~/cc-verify/run-<RUN>.env`, holding only `RUN=` and `T8=` | the trap, last, and only when every removal succeeded |
| log | `~/cc-verify/log-<RUN>.txt` | kept on purpose. The script reads its tail only to show a `--register` failure; nothing else reads it. |

**What the run checks at runtime** (the `CHECK` lines). It compares, before and after:
- a hash over every file in `~/.config/claude-devcontainer`;
- the hashes of `manifest.sha256`, `host-tools.sha256` and `verified-live.sha256`;
- where `~/.local/bin/cc-isolated` and `cc-push` point;
- every container, volume and image tag that existed before the run.

Step 4 also checks the path-keyed identity, and step 6 has the launcher write `projects/<PID>.profile` under the *stage*.

**What holds by construction, not by a check.** No command in the script writes `~/.claude` or your checkout's working tree. Its only operations on the checkout are `git rev-parse` and a `git clone` *from* it. It runs no branch code on the host. It needs no session to close: there is no install, so install.sh's agent gate never runs.

## The paste (one block, for a `you: terminal` entry)

Run it from a terminal on the host. The last line is the only one to edit: replace `~/claude-workflows` if your checkout lives elsewhere. The block holds no shell comments outside the script, so it pastes the same into bash and zsh. It takes up to about an hour: the image build, then Q-117's own wait (up to 45 min) for a dl.google.com pool rotation. Do not open a shell or run git inside `~/cc-verify` while it runs, or afterwards if a teardown is reported incomplete: branch code can write the workspace's `.git`.

```bash
mkdir -p ~/cc-verify && cat > ~/cc-verify/spike-q117.sh <<'CCVERIFY'
#!/usr/bin/env bash
# spike-q117.sh: live-verify fix/egress-dnsmasq-ipset (Q-117) WITHOUT installing it.
# Candidate [4] of docs/working/dd-branch-verify-without-install.md. Run on the HOST,
# from your own terminal, while other sessions keep running:
#     bash ~/cc-verify/spike-q117.sh ~/claude-workflows     # your host checkout
#     bash ~/cc-verify/spike-q117.sh --clean                # remove a crashed run's leftovers
# It stages the merge of main and the branch into ~/cc-verify/stage-TREE8, clones a
# scratch workspace ~/cc-verify/VERIFY-TREE8, and runs MAIN's installed cc-isolated
# with CLAUDE_DEVC_CONFIG_DIR=<stage>. Main's config dir, its bin links and every
# other project's container and volumes are never written. Teardown runs on exit.
set -euo pipefail
# Opt-in credentials devcontainer.json forwards from this shell (devcontainer.json, "GH_TOKEN"
# and "OPENROUTER_API_KEY" in containerEnv) never reach a container running branch code.
unset GH_TOKEN OPENROUTER_API_KEY

V="$HOME/cc-verify"
MAIN_CFG="$HOME/.config/claude-devcontainer"
MAIN_BIN="$HOME/.local/bin"
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

die() { printf 'REFUSED: %s\n' "$*" >&2; exit 1; }
# vis: drop control bytes (all but tab and newline) from text that branch code or the
# container produced, so it cannot rewrite the terminal or forge RESULT/CHECK lines.
vis() { LC_ALL=C tr -d '\000-\010\013-\037\177'; }
# relay: vis, then show each line indented under "  | " on stderr (so nothing the container
# prints can start a line with RESULT or CHECK) and pass it unindented on stdout.
relay() { local l; vis | while IFS= read -r l || [ -n "$l" ]; do printf '  | %s\n' "$l" >&2; printf '%s\n' "$l"; done; }
say() { printf '== %s\n' "$*"; }

# --- teardown: removes only what this run created, named from its own ids ------------
# Everything is derived from RUN and T8 (format-checked); no path, project id or image id
# is read from a file. The project id is the hash of ~/cc-verify/VERIFY-<T8>, a path only
# this script creates, so no run record can name another project's container or volume.
VP="" RUN="" T8="" PID="" SNAP=0
verify_pid() {  # project_id of ~/cc-verify/VERIFY-<T8> (cc-isolated.sh:372-374)
  printf '%s' "$VP/VERIFY-$1" | sha256sum | cut -c1-12
}
teardown() {
  local fail=0 c v i tags pid img imgs=""
  if [[ "$T8" =~ ^[0-9a-f]{8}$ ]] && [ -n "$VP" ]; then
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
    # exist and not list the image id. Without that proof (a --clean after the snapshot was
    # lost) they are reported and kept.
    local before="$V/snap-$RUN-before/images"
    for img in $imgs; do
      if [ ! -f "$before" ]; then echo "TEARDOWN: kept image $img (no before-snapshot proves it new; remove it by hand if it is the verify build)" >&2; continue; fi
      if grep -q " $img\$" "$before"; then continue; fi
      if [ -n "$(docker ps -aq --filter "ancestor=$img" </dev/null)" ]; then echo "TEARDOWN: image $img still in use; not removed" >&2; continue; fi
      docker image rm -f "$img" >/dev/null </dev/null || { echo "TEARDOWN: could not remove image $img" >&2; fail=1; }
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
    rm -rf -- "$V/stage-$T8" "$V/stage-$T8.raw" "$V/VERIFY-$T8" || fail=1
  fi
  if [[ "$RUN" =~ ^[0-9]+-[0-9]+$ ]]; then
    rm -rf -- "$V/src-$RUN.git" || fail=1
    if [ "$fail" = 0 ]; then rm -f -- "$V/run-$RUN.env"; fi
  fi
  return "$fail"
}

snapshot() {   # snapshot <before|after>
  local d="$V/snap-$RUN-$1" f
  mkdir -p "$d"
  docker ps -a --no-trunc --format '{{.ID}} {{.Names}}' </dev/null | sort > "$d/containers"
  docker volume ls -q </dev/null | sort > "$d/volumes"
  docker image ls --no-trunc --format '{{.Repository}}:{{.Tag}} {{.ID}}' </dev/null | sort > "$d/images"
  : > "$d/main"
  for f in manifest.sha256 host-tools.sha256 verified-live.sha256; do
    if [ -e "$MAIN_CFG/$f" ]; then sha256sum < "$MAIN_CFG/$f" | sed "s|-\$|$f|" >> "$d/main"
    else echo "absent $f" >> "$d/main"; fi
  done
  for f in cc-isolated cc-push; do echo "$f -> $(readlink -f "$MAIN_BIN/$f" 2>/dev/null || echo absent)" >> "$d/main"; done
  echo "config tree $( (cd "$MAIN_CFG" && find . \( -type f -o -type l \) -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) | sha256sum)" >> "$d/main"
}

compare() {    # after teardown: did anything outside this run change?
  local b="$V/snap-$RUN-before" a="$V/snap-$RUN-after" bad=0 x
  snapshot after
  if cmp -s "$b/main" "$a/main"; then echo "CHECK main install untouched: ok"
  else echo "CHECK main install untouched: FAIL"; diff "$b/main" "$a/main" || true; bad=1; fi
  x="$(comm -23 "$b/containers" "$a/containers")"
  if [ -z "$x" ]; then echo "CHECK no pre-existing container removed: ok"
  else echo "CHECK no pre-existing container removed: FAIL"; printf '  %s\n' "$x"; bad=1; fi
  x="$(comm -23 "$b/volumes" "$a/volumes")"
  if [ -z "$x" ]; then echo "CHECK no pre-existing volume removed: ok"
  else echo "CHECK no pre-existing volume removed: FAIL"; printf '  %s\n' "$x"; bad=1; fi
  x="$(comm -23 "$b/images" "$a/images" | grep -v '^<none>:<none> ' || true)"
  if [ -z "$x" ]; then echo "CHECK no pre-existing image tag moved or removed: ok"
  else echo "CHECK no pre-existing image tag moved or removed: FAIL (research §7 image-naming claim)"; printf '  %s\n' "$x"; bad=1; fi
  if docker volume ls -q </dev/null | grep -q "^cc-$PID-"; then echo "CHECK verify volumes gone: FAIL"; bad=1
  else echo "CHECK verify volumes gone: ok"; fi
  if [ -n "$(docker ps -aq --filter "label=cc-project=$PID" </dev/null)" ]; then echo "CHECK verify container gone: FAIL"; bad=1
  else echo "CHECK verify container gone: ok"; fi
  x="$(comm -13 "$b/containers" "$a/containers"; comm -13 "$b/volumes" "$a/volumes"; comm -13 "$b/images" "$a/images")"
  [ -z "$x" ] || { echo "NOTE created during the run and still present (another session's, or a build leftover; not removed):"; printf '  %s\n' "$x"; }
  rm -rf -- "$a"
  return "$bad"
}

on_exit() {
  local rc=$? trc=0 crc=0
  trap - EXIT INT TERM HUP
  if [ -n "$RUN" ]; then
    say "teardown"
    teardown || trc=1
    if [ "$SNAP" = 1 ]; then compare || crc=1; fi
    if [ "$trc" = 1 ] || [ -e "$V/run-$RUN.env" ]; then
      # The before snapshot stays: it is what lets --clean prove an image is this run's.
      echo "TEARDOWN INCOMPLETE. Fallback: bash $V/spike-q117.sh --clean" >&2
      rc=1
    else
      rm -rf -- "$V/snap-$RUN-before"
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
  files=("$V"/run-*.env)
  [ "${#files[@]}" -gt 0 ] || { echo "nothing to clean in $V"; exit 0; }
  rc=0
  for f in "${files[@]}"; do
    RUN="$(sed -n 's/^RUN=\([0-9]*-[0-9]*\)$/\1/p' "$f" | head -1)"
    T8="$(sed -n 's/^T8=\([0-9a-f]\{8\}\)$/\1/p' "$f" | head -1)"
    [ "$f" = "$V/run-$RUN.env" ] || { echo "skipping malformed $f (remove it by hand)" >&2; rc=1; continue; }
    echo "cleaning run $RUN (tree ${T8:-?}${T8:+, project $(verify_pid "$T8")})"
    if teardown; then rm -rf -- "$V/snap-$RUN-before" "$V/snap-$RUN-after"; else rc=1; fi
  done
  exit "$rc"
fi

# --- preflight: refuse before creating anything --------------------------------------
[ $# -eq 1 ] || die "usage: bash $V/spike-q117.sh <your host checkout of claude-workflows> | --clean"
[ -z "${CLAUDECODE:-}" ] || die "run this from your own terminal, not from inside a Claude Code session."
[ -z "${CLAUDE_DEVC_CONFIG_DIR:-}" ] || die "CLAUDE_DEVC_CONFIG_DIR is set in this shell ($CLAUDE_DEVC_CONFIG_DIR); unset it so main's install is the known default."
for c in git docker devcontainer sha256sum tar find cmp diff comm readlink; do
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
left=("$V"/run-*.env)
shopt -u nullglob
[ "${#left[@]}" -eq 0 ] || die "a previous run left state (${left[*]}). Run: bash $V/spike-q117.sh --clean"

RUN="$(date +%s)-$$"
printf 'RUN=%s\n' "$RUN" > "$V/run-$RUN.env"
trap on_exit EXIT
trap 'exit 130' INT TERM HUP
LOG="$V/log-$RUN.txt"

# --- 1. merge check, in a bare scratch clone (objects only: no hooks, no local config) -
say "1. merge check: $BASE + $BRANCH"
SRCGIT="$V/src-$RUN.git"
git -c core.hooksPath=/dev/null clone -q --bare --no-local --template= -- "$REPO_TOP" "$SRCGIT" </dev/null || die "could not clone $REPO_TOP."
G=(git --no-optional-locks -C "$SRCGIT" -c core.hooksPath=/dev/null -c core.fsmonitor=false)
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
t8="${TREE:0:8}"
S="$V/stage-$t8"
W="$V/VERIFY-$t8"
echo "   $BASE=${MAIN_SHA:0:12}  $BRANCH=${BR_SHA:0:12}  merged tree=$TREE"
# Only once these paths are known to be fresh does teardown get to remove them.
[ ! -e "$S" ] && [ ! -e "$W" ] && [ ! -e "$S.raw" ] || die "$S or $W already exists (not this run's; remove it by hand)."
T8="$t8"
printf 'T8=%s\n' "$T8" >> "$V/run-$RUN.env"

# --- 2. stage the merged tree the way install.sh lays out its payload ------------------
say "2. stage -> $S"
# Read into a variable first: `git show | grep -q` under pipefail can fail with SIGPIPE when
# grep exits early on a file larger than the pipe buffer (review fact-check claim 6).
inst="$("${G[@]}" show "$TREE:devcontainer-config/install.sh")" || die "no devcontainer-config/install.sh in the merged tree."
grep -qxF "$EXPECT_PAYLOAD" <<< "$inst" \
  || die "install.sh's PAYLOAD in the merged tree is not the list this spike stages; update the spike."
grep -qxF "$EXPECT_HOME_SRC" <<< "$inst" \
  || die "install.sh's CLAUDE_HOME_SRC in the merged tree is not the list this spike stages; update the spike."
mkdir "$S.raw"
"${G[@]}" archive --format=tar "$TREE" -- devcontainer-config global-instructions/CLAUDE.md "${HOME_DIRS[@]}" \
  | tar -x -C "$S.raw"
[ -z "$(find "$S.raw" -type l -print -quit)" ] || die "the merged tree holds symlinks in the payload; install.sh never installs one."
mkdir "$S" "$S/claude-home"
for i in "${DC_ITEMS[@]}"; do
  [ -e "$S.raw/devcontainer-config/$i" ] || die "devcontainer-config/$i is missing from the merged tree."
  cp -Rp "$S.raw/devcontainer-config/$i" "$S/$i"
done
cp -p "$S.raw/global-instructions/CLAUDE.md" "$S/claude-home/CLAUDE.md"
for i in "${HOME_DIRS[@]}"; do cp -Rp "$S.raw/$i" "$S/claude-home/$i"; done
printf 'commit=%s\ndirty=no\nuncommitted_excluded=0\nassembled_from=cc-verify spike, merge tree %s of %s and %s\n' \
  "$TREE" "$TREE" "$MAIN_SHA" "$BR_SHA" > "$S/claude-home/.manifest"
chmod +x "$S/cc-isolated.sh" "$S/cc-push.sh" "$S/init-firewall.sh"
rm -rf -- "$S.raw"

# --- 3. devcontainer.json is host-trusted config: it must equal main's installed copy --
say "3. devcontainer.json gate"
if grep -n 'initializeCommand' "$S/devcontainer.json"; then
  die "the staged devcontainer.json names initializeCommand, which runs ON THE HOST."
fi
for i in "${PINNED[@]}"; do
  if ! cmp -s "$MAIN_CFG/$i" "$S/$i"; then
    diff -u "$MAIN_CFG/$i" "$S/$i" | vis | sed 's/^/  | /' || true
    die "the staged $i differs from main's installed copy (diff above). This spike refuses any change to what reaches the docker daemon (runArgs, mounts, lifecycle commands, base image, build steps). If main's install is behind main, reinstall main first."
  fi
done
echo "   devcontainer.json and Dockerfile identical to main's installed copies (runArgs, mounts, lifecycle commands, base image unchanged)"
echo "   staged files that differ from main's install (expect init-firewall.sh; more if main's install is behind main):"
for i in "${DC_ITEMS[@]}" claude-home; do
  [ "$i" = claude-home ] && [ ! -e "$MAIN_CFG/claude-home" ] && { echo "     claude-home (none installed)"; continue; }
  diff -rq "$MAIN_CFG/$i" "$S/$i" >/dev/null 2>&1 || echo "     $i"
done

# --- 4. scratch workspace with its own path-keyed identity -----------------------------
say "4. workspace -> $W"
git -c core.hooksPath=/dev/null -c core.fsmonitor=false clone -q --no-local --template= -- "$SRCGIT" "$W" </dev/null
WS="$(git -C "$W" -c core.hooksPath=/dev/null -c core.fsmonitor=false rev-parse --show-toplevel)"
[ "$WS" = "$VP/VERIFY-$T8" ] || die "workspace toplevel is $WS, not $VP/VERIFY-$T8."
PID="$(verify_pid "$T8")"                                        # = project_id(WS), cc-isolated.sh:372-374
HPID="$(printf '%s' "$REPO_TOP" | sha256sum | cut -c1-12)"
[ "$(basename "$WS")" = "VERIFY-$T8" ] || die "workspace basename is $(basename "$WS"), not VERIFY-$T8."
[ "$PID" != "$HPID" ] || die "verify project id equals $REPO_TOP's ($HPID)."
[ -z "$(docker ps -aq --filter "label=cc-project=$PID" </dev/null)" ] || die "a container already carries label cc-project=$PID."
! docker volume ls -q </dev/null | grep -q "^cc-$PID-" || die "volumes cc-$PID-* already exist."
echo "   project id $PID (your checkout's is $HPID); container label cc-project=$PID; volumes cc-$PID-*"

# --- 5. snapshot, register, probe -------------------------------------------------------
say "5. snapshot before"
snapshot before
SNAP=1
say "6. register $PROFILE in the stage (main's launcher, CLAUDE_DEVC_CONFIG_DIR=stage); log: $LOG"
CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" --register "$WS" --profile "$PROFILE" >"$LOG" 2>&1 </dev/null \
  || { tail -n 20 "$LOG" | vis | sed 's/^/  | /' >&2; die "--register failed (log above)."; }
[ "$(cat "$S/projects/$PID.profile" 2>/dev/null)" = "$PROFILE" ] \
  || die "the launcher did not write $S/projects/$PID.profile: its project id differs from this spike's."
# What the bless hashed must still be main's copies: a stage edit between step 3 and the bless
# would otherwise be blessed, and check_manifest would then confirm it.
for i in "${PINNED[@]}"; do
  want="$(sha256sum < "$MAIN_CFG/$i" | cut -d' ' -f1)"
  have="$(awk -v f="$i" '$2 == f { print $1 }' "$S/manifest.sha256")"
  [ "$have" = "$want" ] || die "the stage's blessed $i is not main's installed copy (changed after step 3)."
done
HASH="$(sha256sum < "$S/manifest.sha256" | cut -c1-16)"       # = blessed_hash, cc-isolated.sh:88-93
echo "   stage blessed: config $HASH"
say "7. --probe-only (builds the image, boots the branch firewall, runs the self-probe)"
CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" --probe-only "$WS" </dev/null 2>&1 | relay >> "$LOG" \
  || die "--probe-only failed (output above)."
[ "$(tr -d '[:space:]' < "$S/verified-live.sha256" 2>/dev/null)" = "$HASH" ] \
  || die "no verified-live receipt for $HASH in the stage."
cids="$(docker ps -aq --no-trunc --filter "label=cc-project=$PID" </dev/null)"
[ "$(printf '%s\n' "$cids" | grep -c .)" = 1 ] || die "expected exactly one container labelled cc-project=$PID, found: $cids"
img="$(docker inspect -f '{{.Image}}' "$cids" </dev/null)"
new=yes; if grep -q " $img\$" "$V/snap-$RUN-before/images"; then new=no; fi
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
export CC_PROJECT_ID="$PID" CC_PROJECT_NAME="VERIFY-$T8" CC_EGRESS_PROFILE="$PROFILE" CC_CONFIG_DIR="$S" CC_CONFIG_HASH="$HASH"
out="$(devcontainer exec --workspace-folder "$WS" --override-config "$S/devcontainer.json" \
         --id-label "cc-project=$PID" bash -c "$Q117" </dev/null 2>&1 | relay)" \
  || die "devcontainer exec of the Q-117 block failed."

# --- 9. verdict (Q-117's own pass rule) --------------------------------------------------
first="$(printf '%s\n' "$out" | sed -n 's/^first ALLOW address: //p')"
pool="$(printf '%s\n' "$out" | sed -n 's/^pool now: //p')"
v=pass
printf '%s\n' "$out" | grep -qx 'dnsmasq instances (expect 2): 2' || v=fail
printf '%s\n' "$out" | grep -qx 'fetch 1 (expect 200): 200' || v=fail
printf '%s\n' "$out" | grep -qx 'fetch 2 (expect 200): 200' || v=fail
printf '%s\n' "$out" | grep -qx 'FAIL lines for dl.google.com (expect 0): 0' || v=fail
if [ -z "$first" ] || [ "$first" = NONE ]; then v=fail; fi
# "Rerun later" only when nothing else failed: a FAIL line or a bad fetch stays a fail.
if [ "$v" = pass ] && printf ' %s ' "$pool" | grep -qF " $first "; then v=no-rotation; fi
echo "RESULT Q-117 $v (tree $TREE, config $HASH)"
case "$v" in
  pass) exit 0 ;;
  no-rotation) echo "The pool did not rotate within 45 min: rerun later (Q-117's rule)."; exit 2 ;;
  *) exit 1 ;;
esac
CCVERIFY
bash ~/cc-verify/spike-q117.sh ~/claude-workflows
```

If anything kills the run before its trap fires (a `kill -9`, a closed terminal, a power cut), run `bash ~/cc-verify/spike-q117.sh --clean`. The next run refuses to start until you have. Afterwards `rm -r ~/cc-verify` removes the script and the kept logs.

## Expected output on success

These are the lines that matter, in order. Long output in between is elided (`…`), and `<…>` stands for run-specific values. Every line the script did not write itself is shown indented under `  | ` with control bytes removed: the launcher's and the container's output, git's conflict listing, the step-3 diff and a `--register` failure's log tail. So only the script's own lines can start with `RESULT`, `CHECK` or `REFUSED`.

```
== 1. merge check: main + fix/egress-dnsmasq-ipset
   main=<12 hex>  fix/egress-dnsmasq-ipset=b26d4b8b23aa  merged tree=<40 hex>
== 2. stage -> <home>/cc-verify/stage-<TREE8>
== 3. devcontainer.json gate
   devcontainer.json and Dockerfile identical to main's installed copies (runArgs, mounts, lifecycle commands, base image unchanged)
   staged files that differ from main's install (expect init-firewall.sh; more if main's install is behind main):
     init-firewall.sh
     claude-home
== 4. workspace -> <home>/cc-verify/VERIFY-<TREE8>
   project id <PID> (your checkout's is <other 12 hex>); container label cc-project=<PID>; volumes cc-<PID>-*
== 5. snapshot before
== 6. register android in the stage (main's launcher, CLAUDE_DEVC_CONFIG_DIR=stage); log: <home>/cc-verify/log-<RUN>.txt
   stage blessed: config <16 hex>
== 7. --probe-only (builds the image, boots the branch firewall, runs the self-probe)
  | NOTE: blessed config <16 hex> has NOT been verified in a live container.
  | …  (devcontainer build and start output)
  | Boundary self-probe passed (canary invisible · egress default-deny · workspace identity · volume not shared · image from central Dockerfile · config <16 hex> · firewall complete).
  | Recorded config <16 hex> as verified live in <home>/cc-verify/stage-<TREE8>/verified-live.sha256.
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
CHECK no pre-existing container removed: ok
CHECK no pre-existing volume removed: ok
CHECK no pre-existing image tag moved or removed: ok
CHECK verify volumes gone: ok
CHECK verify container gone: ok
RESULT spike-q117 exit=0
```

`claude-home` always shows under "differ": the spike's `.manifest` records the merge tree and "cc-verify spike", where install.sh's records a commit and the checkout path. More entries appear when main's install is behind main. A `NOTE created during the run and still present` block lists containers, volumes or images that appeared during the run and that the trap did not recognise as its own: either another session's work, or a build leftover (the devcontainer CLI's image naming is unverified, below). It is a note, not a failure.

Exit status. Once the run has started, it is also printed as `RESULT spike-q117 exit=<n>`; preflight refusals and `--clean` exit without that line:
- `0`: Q-117 passed and every CHECK is ok.
- `2`: nothing failed, but the pool did not rotate within 45 min. Q-117's own rule says run again later.
- `130`: interrupted (Ctrl-C, TERM, HUP). The trap still tears down.
- `1`: anything else: a refusal, a Q-117 fail, a failed CHECK, or an incomplete teardown (which also prints the `--clean` fallback).

**What to paste back:** the `RESULT` lines, every `CHECK` line, and the `NOTE` block if one appeared. On a refusal, the `REFUSED:` line.

## Each step, checked against the code

| Step | Command in the script | Why it is right (source) |
|---|---|---|
| preflight | `unset GH_TOKEN OPENROUTER_API_KEY` | devcontainer.json forwards both from the launching shell into the container (`containerEnv`). A container running branch code gets neither. |
| preflight | refuses with `CLAUDECODE` set, with `CLAUDE_DEVC_CONFIG_DIR` already set, or without `git docker devcontainer …`; checks `docker info` | `CLAUDECODE` mirrors install.sh's target-2 rule (decision 037). An inherited `CLAUDE_DEVC_CONFIG_DIR` would change which config is "main's" (cc-isolated.sh:68-70). |
| preflight | `cc-isolated` on PATH must resolve to `~/.config/claude-devcontainer/cc-isolated.sh` | install.sh links it there (install.sh:598, defaults :1310-1311). |
| preflight | a leftover `run-*.env` refuses the run | so a crashed run is cleaned before a new one reuses its names |
| 1 | `git -c core.hooksPath=/dev/null clone --bare --no-local --template=` of your checkout. Later git calls go through `git --no-optional-locks -C <clone> -c core.hooksPath=/dev/null -c core.fsmonitor=false` | The clone copies objects and refs: no `.git/config` filters or merge drivers, no `info/attributes`, no hooks (`--template=` copies none). Those are what install.sh's `git_state_gate` refuses in the checkout (install.sh:209-252; decision 037 "The checkout's git state"). The flags match `repo_git` (install.sh:180-182). The run record and this clone are the only things created before the merge check, and the trap removes both. |
| 1 | the branch must resolve to the reviewed commit `b26d4b8b23aa…` (`EXPECT_BR`) | Ties the run to what this doc reviewed. A ref moved in the checkout's `.git`, which a cc-isolated container can write, refuses the run (review security F2). |
| 1 | `git merge-tree --write-tree --name-only main <branch>`: exit 1 refuses and lists the conflicts; any other non-zero refuses as "needs git ≥ 2.38" | The first-match check. Verified in the sandbox: today the merge is clean (tree `65e65962…`, the same tree a real `git merge` produces), and `feat/q125-cc-isolated-sandbox` is refused on `hooks/live-verify-gate.sh`. |
| 1 | `git diff-tree -r --name-only <main> <tree>` may list only the branch's five paths | Everything else in the stage is main's committed content. `main` itself is still resolved by name. What reaches the docker daemon from it is pinned in step 3. |
| 2 | refuses unless the merged tree's `install.sh` has exactly the `PAYLOAD=(…)` and `CLAUDE_HOME_SRC=(…)` lines the spike stages, read into a variable first (no `git show \| grep -q` under pipefail) | install.sh:110 and :135. The variable avoids SIGPIPE: install.sh is larger than a pipe buffer, and the review reproduced spurious refusals with the pipe (fact-check claim 6). |
| 2 | `git archive <tree> -- devcontainer-config global-instructions/CLAUDE.md skills … scripts \| tar -x`; refuses any symlink | The same sources and the same no-symlink rule as `extract_commit` (install.sh:257-317, the symlink refusal at :288). |
| 2 | layout: the 10 PAYLOAD files and dirs at the stage root, `claude-home/` built from `CLAUDE.md` and the six dirs, a `.manifest`, `chmod +x` on three scripts | Matches `install_devcontainer` (install.sh:471-508), `assemble`'s `.manifest` keys (:356-361) and install.sh:596. The Dockerfile copies `claude-home/` (Dockerfile:500), `egress/` (:486) and the scripts (:487-491) from the build context, which is `CC_CONFIG_DIR` (devcontainer.json:24-26). The review checked that the current launcher and the pre-Q-089 launcher both bless and check a stage built this way. |
| 3 | refuses if the staged `devcontainer.json` names `initializeCommand`, or if the staged `devcontainer.json` **or `Dockerfile`** differs at all from main's installed copy (shows `diff -u`) | These two files are what the docker daemon runs with. devcontainer.json carries runArgs (devcontainer.json:58-69), mounts (:77-80) and lifecycle commands. The Dockerfile is pinned too because its base image's `devcontainer.metadata` label can add privileged, capAdd, securityOpt and mounts to the run config, and its `# syntax=` line and `RUN` options reach BuildKit (review security F1). Whole-file identity is stricter than "refuse runArgs/mounts changes": devcontainer.json is JSONC, so a line diff cannot reliably isolate keys. The other staged files are either built into the image as the code under test (`init-firewall.sh`, `cc-sni-proxy.py`, `link-claude-home.sh`, `egress/`, `claude-home/`) or host tools this spike never executes (below). |
| 4 | `git … clone --no-local --template=` (hooks and fsmonitor off) into `~/cc-verify/VERIFY-<TREE8>`; its toplevel must equal `<physical ~/cc-verify>/VERIFY-<TREE8>`; PID = `printf %s <that path> \| sha256sum \| cut -c1-12` | `resolve_workspace` uses `git rev-parse --show-toplevel` (cc-isolated.sh:354-367), and `project_id` is that exact pipeline (cc-isolated.sh:372-374). The display name is `basename` of the workspace (cc-isolated.sh:814 → devcontainer.json:22), so it reads `VERIFY-<TREE8>`. |
| 4 | refuses if PID equals your checkout's, if any container already carries label `cc-project=<PID>`, or if any `cc-<PID>-*` volume exists | The launcher selects the container by `--id-label cc-project=$pid` (cc-isolated.sh:836) and names volumes `cc-${CC_PROJECT_ID}-…` (devcontainer.json:78-79). With a fresh PID, `--remove-existing-container` (cc-isolated.sh:883) can only hit this run's container. |
| 5 | snapshot (the list under "What the run checks") | DD constraint H2's observable, widened to the whole config dir after review (fact-check claim 3) |
| 6 | `CLAUDE_DEVC_CONFIG_DIR=<stage> ~/.config/claude-devcontainer/cc-isolated.sh --register <ws> --profile android` | Flag syntax: cc-isolated.sh:9-11 and :736; guide `cc-isolated-usage.md:23,537`. `register_project` checks `$(config_dir)/egress/android.txt`, writes `$(config_dir)/projects/<pid>.profile` and re-blesses (cc-isolated.sh:434-480). `bless_manifest` writes only under `config_dir` (cc-isolated.sh:281-319). The script then requires `stage/projects/<PID>.profile`, which proves the launcher computed the same PID. |
| 6 | after the bless, the stage manifest's `devcontainer.json` and `Dockerfile` hashes must equal main's installed copies'; stage hash = `sha256sum < stage/manifest.sha256 \| cut -c1-16` | Closes the window between step 3 and the bless (review security F3). From then on, `check_manifest` at `--probe-only` (cc-isolated.sh:332-350) holds the stage to what was blessed. The hash is `blessed_hash` (cc-isolated.sh:88-93). |
| 7 | `CLAUDE_DEVC_CONFIG_DIR=<stage> …/cc-isolated.sh --probe-only <ws>`; then requires `stage/verified-live.sha256` = that hash | The probe action always rebuilds (cc-isolated.sh:880-885) and runs `probe_boundary` (:577-705). Only a full pass calls `record_verified_live` into `config_dir` (:113-115, :702). Main's launcher loads host code only from its own directory (cc-isolated.sh:714-718), and so did the pre-Q-089 launcher (`source "$(dirname …BASH_SOURCE…)/cc-exit-scan.sh"`). So the stage's copies of `cc-isolated.sh` and the host tools are hashed but never executed. They are staged because `enforcement_files`/`host_tool_files` (cc-isolated.sh:128-151, :199-203) and the bless need them present. The review confirmed that the launcher, run against the stage, executes no staged file and writes only under it. |
| 7 | exactly one container with the label; reports whether its image is new | `docker inspect -f '{{.Image}}'` |
| 8 | exports `CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR CC_CONFIG_HASH`, then `devcontainer exec --workspace-folder <ws> --override-config <stage>/devcontainer.json --id-label cc-project=<PID> bash -c "$Q117"` | Exactly the five variables `rebuild_hint` says the by-hand CLI needs (cc-isolated.sh:561-563), and the same `dc` args the launcher uses (:834-836). `bash -c` with the block as one argument is how the probe runs in-container scripts (cc-isolated.sh:608). stdin is `/dev/null`, so nothing reads the rest of the script. |
| 8 | Q-117's container block, verbatim | questions-archive.md:2463-2475 (byte for byte). It runs as `remoteUser: node` (devcontainer.json:71). node can read the proxy log: on the branch, `/run/cc-sni-proxy` is 0755 (`init-firewall.sh:1392-1393` on the branch) and the log is opened 0644 (`cc-sni-proxy.py:260`). The `ALLOW sni=… -> <ip>:<port>` field order is the proxy's (`cc-sni-proxy.py:207`). dl.google.com is only in `egress/android.txt`. |
| 7-8 | launcher and container output goes through `relay`: control bytes (all but tab and newline) are dropped, and each line is shown under `  \| ` | Branch code builds and boots this container, so its output cannot rewrite the terminal, set the clipboard through OSC 52, or print a line that looks like the script's `RESULT`/`CHECK` (review security F8). |
| 9 | verdict = Q-117's own rule: 2 instances, both fetches 200, 0 FAIL lines, the first ALLOW address absent from "pool now". `no-rotation` (exit 2) applies only when nothing else failed | questions-archive.md:2478. The ordering was fixed in review: a real failure used to report as "rerun later" (fact-check claim 9a). |
| trap / `--clean` | Order of removal: the label's containers; the two named volumes; the containers' images; `vsc-verify-<TREE8>-…` tags; then the stage, workspace and clone. Every name is derived from `RUN` and `TREE8` (format-checked), and the project id is recomputed from `~/cc-verify/VERIFY-<TREE8>`. An image goes only if the run's before-snapshot exists and does not list its id: the container's image by id (and only if unused), a build tag by name (`docker image rm <repo:tag>`, no `-f`, so other tags on that id survive). Without the snapshot, images are reported and kept. | A planted `run-*.env` can name only a `VERIFY-<8 hex>` path under `~/cc-verify`, and only this script creates those. It has no snapshot, so it removes no image at all. It cannot point `docker rm` or `volume rm` at another project. Both points were reproduced before the fixes (iteration-1 fact-check claim 24b, security F4; iteration-2 tag-rule finding) and re-tested after: a planted record naming `deadbeef` left `acme/preverify-deadbeef:1` and `vsc-verify-deadbeef-x` in place. |

## What was tested here, without a host

The sandbox has no docker, and nothing ran for real. The script was run end to end in a scratch `HOME`, with fake `docker` and `devcontainer` commands on PATH. The fake devcontainer records `up`, creates a labelled container, two volumes and an image, and answers the probe's in-container checks. The real main launcher from `main` was installed into the fake `~/.config/claude-devcontainer` and blessed there. So steps 6-7 ran main's real `--register`, `bless_manifest`, `check_manifest` and `probe_boundary` against the stage. After the review fixes:

- **Pass path:** `RESULT Q-117 pass`, every `CHECK` ok, exit 0. A pre-existing "harness" container, volume and image survived. Main's config dir, manifests and bin link were unchanged.
- **Refusals:**
  - a branch that conflicts (`feat/q125-cc-isolated-sandbox` swapped in, with its own `EXPECT_BR`): refused at step 1 on `hooks/live-verify-gate.sh`, with no docker call besides the preflight `docker info`;
  - a moved branch (`EXPECT_BR` mismatch): refused at step 1;
  - a `devcontainer.json` difference (`--privileged` added) and a `Dockerfile` difference: each refused at step 3, with the diff shown.
- **Failures:** 3 FAIL lines gave `RESULT Q-117 fail` with teardown and CHECKs ok, exit 1. That stayed `fail`, not `no-rotation`, even when the pool also did not rotate. No rotation alone gave exit 2.
- **Forged output:** a container line `RESULT Q-117 pass`, and one carrying ESC/CR bytes, were shown indented and stripped. The real verdict line followed, unchanged.
- **Planted run record:** a `run-*.env` naming the harness's project id and image removed nothing. So did one with `T8=deadbeef` next to images tagged `acme/preverify-deadbeef:1` and `vsc-verify-deadbeef-x`.
- **Crash:** `kill -9` during step 8 left the container, volumes, image, stage, clone and run record. The next run refused, `--clean` removed exactly those, and the harness's objects survived.
- `bash -n` and `shellcheck -S warning` are clean. The paste round-trips byte for byte into `~/cc-verify/spike-q117.sh` under bash and `zsh -f`.

## Not verified (needs the host run)

1. **Image naming** (research §7). The trap removes the image the verify container ran (if new and unused), plus any image whose tag contains `verify-<TREE8>`. The second rule assumes the devcontainer CLI tags images after the lower-cased workspace folder. If that is wrong, an intermediate base image may be left behind: it shows under `NOTE … still present`, nothing deletes it, and you remove it by id. If the CLI *retags* an image that existed before, `CHECK no pre-existing image tag moved or removed` fails. That would be the claim refuted.
2. **Main's launcher on a stage dir** (research §7): steps 6-7 are the test. They were exercised against the real launcher in the sandbox, but not with the real CLI and dockerd.
3. **The devcontainer CLI's `exec`** with the five exported variables, taken from `rebuild_hint` (cc-isolated.sh:561-563) and not observed. A failure shows as `REFUSED: devcontainer exec of the Q-117 block failed.`
4. **`devcontainer exec` passes the inner exit status back.** Assumed. So is `docker ps --filter ancestor=<image id>` listing the containers that use an image.
5. **git ≥ 2.38 on the host**, for `merge-tree --write-tree`. Without it, step 1 refuses.
6. **`devcontainer read-configuration`** (research §7): not used. The whole-file pin in step 3 replaces it.
7. **The CLI merging a base image's `devcontainer.metadata` label** into the run config is taken from the dev container spec, not observed. The Dockerfile pin makes it moot here.
8. **Real docker's output formats.** The fake docker ignores `--format` for `ps`. The script assumes `docker image ls --no-trunc --format '{{.ID}} …'` prints ids in the same `sha256:…` form as `docker inspect -f '{{.Image}}'`.
9. **`devcontainer exec` runs as `remoteUser` (node) by default**, as the launcher's own probes assume.
10. **The devcontainer CLI's own writes on the host** (caches, temp files, and any image-build metadata outside docker). They are not part of the snapshot.
11. **Files the container writes into the workspace bind mount as root** could make `rm -rf ~/cc-verify/VERIFY-<TREE8>` fail, for `--clean` too. The trap would then report an incomplete teardown, and you would remove the directory with elevated rights.
12. **The build's network and time.** Base layers are probably cache-shared with main's image, because the Dockerfile is identical. Not measured.

## Residual risks (accepted for a spike)

- **The verdict is attested by the code under test.** The branch's `init-firewall.sh` runs as root in the container before the Q-117 block, so a hostile branch could fake the block's output. Main's own probe has the same trust shape. What the paste guarantees is that the branch reaches only the container, not the host. The review is what judges the branch's code (review security F5).
- **`main` is resolved by name** from the checkout's `.git`, which a cc-isolated container can write. Pinning the branch, the five-path rule and the step-3 pins mean a planted `main` can change only what is built *into* the image: it cannot change how the container is run or built. The verdict would then be about the wrong code, not a host compromise.
- **The stage after `check_manifest`.** A same-uid process could rewrite a stage file between the launcher's `check_manifest` and the docker build reading it. That is the same swap window decision 037 accepts for install target 1. cc-isolated containers cannot reach the stage. The verify container itself reaches only its own workspace, `VERIFY-<TREE8>`, through its bind mount.
- **git and global config.** A filter or merge driver defined in your global `~/.gitconfig`, and assigned by a committed `.gitattributes`, would run during `git archive`, `merge-tree` or `git clone`. That is install.sh's residual too (decision 037). `git clone --no-local` runs `upload-pack` against your checkout, which reads that repository's config; `uploadpack.packObjectsHook` is honoured only from protected (global/system) config.
- **8-bit control bytes** (C1, e.g. 0x9b CSI) are not stripped, because stripping them would mangle UTF-8 text. Only terminals in 8-bit mode act on them.
- **A leftover `VERIFY-<TREE8>`** after an incomplete teardown has a `.git` that branch code could have written. Do not run git or a git-aware prompt there; run `--clean` (review security F7).
- **An agent running the paste.** The `CLAUDECODE` refusal stops accidents only. An agent with host docker access already has more than this script gives it.
- **The verdict covers the merge tree, not the branch tip.** That is deliberate (DD H6). A clean `git merge` of this branch into an unchanged main produces exactly this tree.
