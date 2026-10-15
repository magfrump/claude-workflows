# Spike: verify Q-117 without installing the branch (cc-verify, hand version)

- **Goal**: One host paste that live-verifies `fix/egress-dnsmasq-ipset` (Q-117) without installing it. It stages the merge of main and the branch, and runs main's installed cc-isolated against that stage on a scratch clone. The same run checks the research doc's four unverified claims (§7).
- **Project state**: roadmap Next 3, step 1 of the DD's recommendation ([4] as [5]'s first step), on `docs/branch-verify-without-install` · inputs: `research-branch-verify-without-install.md`, `dd-branch-verify-without-install.md` · blocked on a host run (the user's `you: terminal` paste)
- **Task status**: paused (paste written and reviewed; nothing has run on the host)

Last verified: 2026-10-15 against main b279a2ba, `fix/egress-dnsmasq-ipset` b26d4b8b (their merge tree today: `65e65962b12e…`).
Relevant paths: `devcontainer-config/cc-isolated.sh`, `devcontainer-config/install.sh`, `devcontainer-config/devcontainer.json`, `guides/cc-isolated-usage.md`, `docs/working/questions-archive.md` (Q-117)

## What it does, and what it never touches

The paste writes one script, `~/cc-verify/spike-q117.sh`, and runs it. Everything the script creates is named from the run and kept under `~/cc-verify/`:

| Created | Name | Removed by |
|---|---|---|
| bare scratch clone of your checkout (objects only) | `~/cc-verify/src-<RUN>.git` | the EXIT trap |
| the stage (main + branch, laid out like install.sh's payload) | `~/cc-verify/stage-<TREE8>` | the trap |
| scratch workspace | `~/cc-verify/VERIFY-<TREE8>` | the trap |
| one container | label `cc-project=<PID>`, PID = sha256 of the scratch path | the trap (`docker rm -f`) |
| two volumes | `cc-<PID>-bashhistory`, `cc-<PID>-claude-config` | the trap |
| one image | whatever the devcontainer CLI builds for that workspace | the trap, but only if its id was not present before the run, plus any image whose tag names `verify-<TREE8>` |
| run record | `~/cc-verify/run-<RUN>.env` (written before anything else) | the trap, last, and only when every removal succeeded |
| log | `~/cc-verify/log-<RUN>.txt` | kept on purpose; no tool reads it |

It never writes `~/.config/claude-devcontainer`, `~/.local/bin`, `~/.claude`, your checkout's working tree, or any container, volume or image it did not create. It runs no branch code on the host, and needs no session to close: there is no install, so install.sh's agent gate never runs. The run proves each of these claims by checking: the before/after snapshot (`CHECK` lines), the path-keyed identity checks in step 4, and the launcher writing `projects/<PID>.profile` under the *stage*.

## The paste (one block, for a `you: terminal` entry)

Run it from a terminal on the host. Edit only the checkout path on the last line. It takes up to about an hour: the image build, then Q-117's own wait (up to 45 min) for a dl.google.com pool rotation.

```bash
# --- HOST: your own terminal. Other sessions may keep running. EDIT the checkout path on the last line. ---
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

V="$HOME/cc-verify"
MAIN_CFG="$HOME/.config/claude-devcontainer"
MAIN_BIN="$HOME/.local/bin"
LAUNCHER="$MAIN_CFG/cc-isolated.sh"
BASE=main
BRANCH=fix/egress-dnsmasq-ipset
PROFILE=android
EXPECT_PAYLOAD='PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress claude-home)'
EXPECT_HOME_SRC='CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)'
DC_ITEMS=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress)
HOME_DIRS=(skills workflows guides patterns hooks scripts)

die() { printf 'REFUSED: %s\n' "$*" >&2; exit 1; }
say() { printf '== %s\n' "$*"; }

# --- teardown: removes only what this run created, named from its own ids ------------
# Paths are derived from RUN and T8, never read from a file; PID and IMG are format-checked.
RUN="" T8="" PID="" IMG="" IMG_NEW=0 SNAP=0
teardown() {
  local fail=0 c v i tags
  if [[ "$PID" =~ ^[0-9a-f]{12}$ ]]; then
    for c in $(docker ps -aq --no-trunc --filter "label=cc-project=$PID" </dev/null); do
      docker rm -f "$c" >/dev/null </dev/null || { echo "TEARDOWN: could not remove container $c" >&2; fail=1; }
    done
    for v in "cc-$PID-bashhistory" "cc-$PID-claude-config"; do
      if docker volume inspect "$v" >/dev/null 2>&1 </dev/null; then
        docker volume rm "$v" >/dev/null </dev/null || { echo "TEARDOWN: could not remove volume $v" >&2; fail=1; }
      fi
    done
  fi
  if [ "$IMG_NEW" = 1 ] && [[ "$IMG" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    docker image rm -f "$IMG" >/dev/null </dev/null || { echo "TEARDOWN: could not remove image $IMG" >&2; fail=1; }
  fi
  if [[ "$T8" =~ ^[0-9a-f]{8}$ ]]; then
    # The devcontainer CLI tags its images after the workspace folder (unverified); a tag
    # naming this run's folder is this run's, whoever else is building meanwhile.
    while read -r i tags; do
      [ -n "$i" ] || continue
      case "$tags" in *verify-"$T8"*) docker image rm -f "$i" >/dev/null </dev/null || fail=1 ;; esac
    done < <(docker image ls --no-trunc --format '{{.ID}} {{.Repository}}:{{.Tag}}' </dev/null | tr 'A-Z' 'a-z')
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
  rm -rf -- "$b" "$a"
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
      echo "TEARDOWN INCOMPLETE. Fallback: bash $V/spike-q117.sh --clean" >&2
      rc=1
    fi
    [ "$crc" = 0 ] || rc=1
  fi
  echo "RESULT spike-q117 exit=$rc"
  exit "$rc"
}

# --- --clean: remove a crashed run's leftovers ---------------------------------------
if [ "${1:-}" = "--clean" ]; then
  shopt -s nullglob
  files=("$V"/run-*.env)
  [ "${#files[@]}" -gt 0 ] || { echo "nothing to clean in $V"; exit 0; }
  rc=0
  for f in "${files[@]}"; do
    RUN="$(sed -n 's/^RUN=\([0-9]*-[0-9]*\)$/\1/p' "$f" | head -1)"
    T8="$(sed -n 's/^T8=\([0-9a-f]\{8\}\)$/\1/p' "$f" | head -1)"
    PID="$(sed -n 's/^PID=\([0-9a-f]\{12\}\)$/\1/p' "$f" | head -1)"
    IMG="$(sed -n 's/^IMG=\(sha256:[0-9a-f]\{64\}\)$/\1/p' "$f" | head -1)"
    IMG_NEW=0; [ -n "$IMG" ] && IMG_NEW=1
    [ "$f" = "$V/run-$RUN.env" ] || { echo "skipping malformed $f (remove it by hand)" >&2; rc=1; continue; }
    echo "cleaning run $RUN (tree ${T8:-?}, project ${PID:-?})"
    teardown || rc=1
    rm -rf -- "$V/snap-$RUN-before" "$V/snap-$RUN-after"
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
git clone -q --bare --no-local -- "$REPO_TOP" "$SRCGIT" </dev/null || die "could not clone $REPO_TOP."
G=(git -C "$SRCGIT" -c core.hooksPath=/dev/null -c core.fsmonitor=false)
MAIN_SHA="$("${G[@]}" rev-parse --verify -q "refs/heads/$BASE^{commit}")" || die "no local branch $BASE in $REPO_TOP."
BR_SHA="$("${G[@]}" rev-parse --verify -q "refs/heads/$BRANCH^{commit}")" || die "no local branch $BRANCH in $REPO_TOP."
set +e
mt="$("${G[@]}" merge-tree --write-tree --name-only "$MAIN_SHA" "$BR_SHA" 2>&1 </dev/null)"
mrc=$?
set -e
case "$mrc" in
  0) ;;
  1) printf '%s\n' "$mt" >&2; die "$BRANCH does not merge cleanly with $BASE (conflicts above). Merge $BASE into the branch first." ;;
  *) printf '%s\n' "$mt" >&2; die "git merge-tree --write-tree failed (exit $mrc; it needs git >= 2.38)." ;;
esac
TREE="$(printf '%s\n' "$mt" | head -1)"
[[ "$TREE" =~ ^[0-9a-f]{40}([0-9a-f]{24})?$ ]] || die "merge-tree printed no tree id: $TREE"
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
"${G[@]}" show "$TREE:devcontainer-config/install.sh" | grep -qxF "$EXPECT_PAYLOAD" \
  || die "install.sh's PAYLOAD in the merged tree is not the list this spike stages; update the spike."
"${G[@]}" show "$TREE:devcontainer-config/install.sh" | grep -qxF "$EXPECT_HOME_SRC" \
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
if ! cmp -s "$MAIN_CFG/devcontainer.json" "$S/devcontainer.json"; then
  diff -u "$MAIN_CFG/devcontainer.json" "$S/devcontainer.json" || true
  die "the staged devcontainer.json differs from main's installed copy (diff above). This spike refuses any change there (runArgs, mounts, lifecycle commands): reinstall main, or review it by hand."
fi
echo "   identical to $MAIN_CFG/devcontainer.json (runArgs, mounts, lifecycle commands unchanged)"
echo "   staged files that differ from main's install (expect init-firewall.sh; more if main's install is behind main):"
for i in "${DC_ITEMS[@]}" claude-home; do
  [ "$i" = claude-home ] && [ ! -e "$MAIN_CFG/claude-home" ] && { echo "     claude-home (none installed)"; continue; }
  diff -rq "$MAIN_CFG/$i" "$S/$i" >/dev/null 2>&1 || echo "     $i"
done

# --- 4. scratch workspace with its own path-keyed identity -----------------------------
say "4. workspace -> $W"
git clone -q --no-local -- "$SRCGIT" "$W" </dev/null
WS="$(git -C "$W" rev-parse --show-toplevel)"
PID="$(printf '%s' "$WS" | sha256sum | cut -c1-12)"            # = project_id, cc-isolated.sh:372-374
HPID="$(printf '%s' "$REPO_TOP" | sha256sum | cut -c1-12)"
printf 'PID=%s\n' "$PID" >> "$V/run-$RUN.env"
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
  || { tail -n 20 "$LOG" >&2; die "--register failed (log above)."; }
[ "$(cat "$S/projects/$PID.profile" 2>/dev/null)" = "$PROFILE" ] \
  || die "the launcher did not write $S/projects/$PID.profile: its project id differs from this spike's."
HASH="$(sha256sum < "$S/manifest.sha256" | cut -c1-16)"       # = blessed_hash, cc-isolated.sh:89-94
echo "   stage blessed: config $HASH"
say "7. --probe-only (builds the image, boots the branch firewall, runs the self-probe)"
CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" --probe-only "$WS" </dev/null 2>&1 | tee -a "$LOG" \
  || die "--probe-only failed (output above)."
[ "$(tr -d '[:space:]' < "$S/verified-live.sha256" 2>/dev/null)" = "$HASH" ] \
  || die "no verified-live receipt for $HASH in the stage."
cids="$(docker ps -aq --no-trunc --filter "label=cc-project=$PID" </dev/null)"
[ "$(printf '%s\n' "$cids" | grep -c .)" = 1 ] || die "expected exactly one container labelled cc-project=$PID, found: $cids"
IMG="$(docker inspect -f '{{.Image}}' "$cids" </dev/null)"
if ! grep -q " $IMG\$" "$V/snap-$RUN-before/images"; then IMG_NEW=1; printf 'IMG=%s\n' "$IMG" >> "$V/run-$RUN.env"; fi
echo "   container ${cids:0:12}, image ${IMG:7:12} (new: $IMG_NEW)"

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
         --id-label "cc-project=$PID" bash -c "$Q117" </dev/null 2>&1 | tee /dev/stderr)" \
  || die "devcontainer exec of the Q-117 block failed."

# --- 9. verdict (Q-117's own pass rule) --------------------------------------------------
first="$(printf '%s\n' "$out" | sed -n 's/^first ALLOW address: //p')"
pool="$(printf '%s\n' "$out" | sed -n 's/^pool now: //p')"
v=pass
printf '%s\n' "$out" | grep -qx 'dnsmasq instances (expect 2): 2' || v=fail
printf '%s\n' "$out" | grep -qx 'fetch 1 (expect 200): 200' || v=fail
printf '%s\n' "$out" | grep -qx 'fetch 2 (expect 200): 200' || v=fail
printf '%s\n' "$out" | grep -qx 'FAIL lines for dl.google.com (expect 0): 0' || v=fail
if [ -z "$first" ] || [ "$first" = NONE ]; then v=fail
elif printf ' %s ' "$pool" | grep -qF " $first "; then v=no-rotation; fi
echo "RESULT Q-117 $v (tree $TREE, config $HASH)"
case "$v" in
  pass) exit 0 ;;
  no-rotation) echo "The pool did not rotate within 45 min: rerun later (Q-117's rule)."; exit 2 ;;
  *) exit 1 ;;
esac
CCVERIFY
bash ~/cc-verify/spike-q117.sh ~/claude-workflows    # EDIT: your host checkout of claude-workflows
```

If anything kills the run before its trap fires (a `kill -9`, a closed terminal, a power cut), run `bash ~/cc-verify/spike-q117.sh --clean`. The next run refuses to start until you have. Afterwards `rm -r ~/cc-verify` removes the script and the kept logs.

## Expected output on success

These are the lines that matter, in order; long launcher output in between is elided (`…`). `<…>` stands for run-specific values.

```
== 1. merge check: main + fix/egress-dnsmasq-ipset
   main=<12 hex>  fix/egress-dnsmasq-ipset=<12 hex>  merged tree=<40 hex>
== 2. stage -> ~/cc-verify/stage-<TREE8>
== 3. devcontainer.json gate
   identical to ~/.config/claude-devcontainer/devcontainer.json (runArgs, mounts, lifecycle commands unchanged)
   staged files that differ from main's install (expect init-firewall.sh; more if main's install is behind main):
     init-firewall.sh
     claude-home
== 4. workspace -> ~/cc-verify/VERIFY-<TREE8>
   project id <PID> (your checkout's is <other 12 hex>); container label cc-project=<PID>; volumes cc-<PID>-*
== 5. snapshot before
== 6. register android in the stage (main's launcher, CLAUDE_DEVC_CONFIG_DIR=stage); log: ~/cc-verify/log-<RUN>.txt
   stage blessed: config <16 hex>
== 7. --probe-only (builds the image, boots the branch firewall, runs the self-probe)
NOTE: blessed config <16 hex> has NOT been verified in a live container.
…  (devcontainer build and start output)
Boundary self-probe passed (canary invisible · egress default-deny · workspace identity · volume not shared · image from central Dockerfile · config <16 hex> · firewall complete).
Recorded config <16 hex> as verified live in ~/cc-verify/stage-<TREE8>/verified-live.sha256.
   container <12 hex>, image <12 hex> (new: 1)
== 8. Q-117 container block (up to ~45 min: waits for a dl.google.com pool rotation)
firewall marker: <the marker's content>
dnsmasq instances (expect 2): 2
fetch 1 (expect 200): 200
first ALLOW address: <A>
waiting for the pool to drop <A> (polls every 30 s, gives up after 45 min)...
pool now: <addresses, not including A>
fetch 2 (expect 200): 200
FAIL lines for dl.google.com (expect 0): 0
<up to 5 proxy-log lines for dl.google.com>
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

`claude-home` shows under "differ" whenever main's installed payload predates the merged tree's (its `.manifest` alone differs). A `NOTE created during the run and still present` block lists containers, volumes or images that appeared during the run and that the trap did not recognise as its own. That is either another session's work or a leftover from the build (the devcontainer CLI's image naming is unverified, below). It is a note, not a failure.

Exit status, also printed as `RESULT spike-q117 exit=<n>`:
- `0`: Q-117 passed and every CHECK is ok.
- `2`: the pool did not rotate within 45 min. This is Q-117's own "run again later" case.
- `1`: anything else: a refusal, a Q-117 fail, a failed CHECK, or an incomplete teardown, which also prints the `--clean` fallback.

**What to paste back:** the `RESULT` lines, every `CHECK` line, and the `NOTE` block if one appeared. On a refusal, the `REFUSED:` line.

## Each step, checked against the code

| Step | Command in the script | Why it is right (source) |
|---|---|---|
| preflight | refuses with `CLAUDECODE` set, with `CLAUDE_DEVC_CONFIG_DIR` already set, or without `git docker devcontainer …` | `CLAUDECODE` mirrors install.sh's target-2 rule (decision 037). An inherited `CLAUDE_DEVC_CONFIG_DIR` would change which config is "main's" (cc-isolated.sh:68-70). |
| preflight | `cc-isolated` on PATH must resolve to `~/.config/claude-devcontainer/cc-isolated.sh` | install.sh links it there (install.sh:598, defaults :1310-1311). |
| preflight | a leftover `run-*.env` refuses the run | so a crashed run is cleaned before a new one reuses names |
| 1 | `git clone --bare --no-local` of your checkout; every later git call with `-c core.hooksPath=/dev/null -c core.fsmonitor=false` | A bare clone copies objects and refs only: no `.git/config` filters, merge drivers, attributes or hooks. Those are what install.sh's `git_state_gate` refuses in the checkout (install.sh:209-252; decision 037 "The checkout's git state"). The flags match `repo_git` (install.sh:180-182). |
| 1 | `git merge-tree --write-tree --name-only main fix/egress-dnsmasq-ipset`: exit 1 refuses with the conflict list, any other non-zero refuses as "needs git ≥ 2.38" | The first-match check. Nothing outside `~/cc-verify` exists yet, and the trap removes the clone. Verified in the sandbox: today it is clean (tree `65e65962…`), and `feat/q125-cc-isolated-sandbox` is refused on `hooks/live-verify-gate.sh`. |
| 2 | refuses unless the merged tree's `install.sh` has exactly the `PAYLOAD=(…)` and `CLAUDE_HOME_SRC=(…)` lines the spike stages | install.sh:110 and :135. The egress branch does not touch install.sh. |
| 2 | `git archive <tree> -- devcontainer-config global-instructions/CLAUDE.md skills … scripts \| tar -x`; refuses any symlink | Same sources and the same no-symlink rule as `extract_commit` (install.sh:257-317, the symlink refusal at :288). |
| 2 | layout: the 10 PAYLOAD files and dirs at the stage root, `claude-home/` built from `CLAUDE.md` and the six dirs, a `.manifest`, `chmod +x` on three scripts | Matches `install_devcontainer` (install.sh:471-508), `assemble`'s `.manifest` keys (:356-361) and install.sh:596. The Dockerfile copies `claude-home/` (Dockerfile:500), `egress/` (:486) and the scripts (:487-491) from the build context, which is `CC_CONFIG_DIR` (devcontainer.json:24-26). |
| 3 | refuses if the staged `devcontainer.json` contains `initializeCommand`, or differs **at all** from `~/.config/claude-devcontainer/devcontainer.json` (shows `diff -u`) | Stricter than "refuse runArgs/mounts/initializeCommand changes". devcontainer.json is JSONC, so a line diff cannot reliably tell those keys from others. Any difference refuses. main's copy has no `initializeCommand`, and its runArgs (devcontainer.json:58-69) and mounts (:77-80) are the reviewed ones. The egress branch does not change the file. |
| 4 | `git clone --no-local` into `~/cc-verify/VERIFY-<TREE8>`; PID = `printf %s <toplevel> \| sha256sum \| cut -c1-12` | `resolve_workspace` uses `git rev-parse --show-toplevel` (cc-isolated.sh:354-367), and `project_id` is that exact pipeline (cc-isolated.sh:372-374). The display name is `basename` of the workspace (cc-isolated.sh:814 → devcontainer.json:22), so it reads `VERIFY-<TREE8>`. |
| 4 | refuses if PID equals your checkout's, or any container already has label `cc-project=<PID>`, or any `cc-<PID>-*` volume exists | The launcher selects the container by `--id-label cc-project=$pid` (cc-isolated.sh:836) and names volumes `cc-${CC_PROJECT_ID}-…` (devcontainer.json:78-79). A fresh PID means `--remove-existing-container` (cc-isolated.sh:883) can only hit this run's container. |
| 5 | snapshot `docker ps -a`, `docker volume ls`, `docker image ls`, sha256 of main's `manifest.sha256`, `host-tools.sha256`, `verified-live.sha256`, and `readlink -f` of `~/.local/bin/cc-isolated` and `cc-push` | DD constraint H2's observable. |
| 6 | `CLAUDE_DEVC_CONFIG_DIR=<stage> ~/.config/claude-devcontainer/cc-isolated.sh --register <ws> --profile android` | Flag syntax: cc-isolated.sh:9-11 and :736, guide `cc-isolated-usage.md:23,537`. `register_project` checks `$(config_dir)/egress/android.txt`, writes `$(config_dir)/projects/<pid>.profile` and re-blesses (cc-isolated.sh:434-480). `bless_manifest` writes only under `config_dir` (cc-isolated.sh:281-319). The script then checks that `stage/projects/<PID>.profile` exists, which proves the launcher computed the same PID. |
| 6 | stage hash = `sha256sum < stage/manifest.sha256 \| cut -c1-16` | = `blessed_hash` (cc-isolated.sh:88-93). |
| 7 | `CLAUDE_DEVC_CONFIG_DIR=<stage> …/cc-isolated.sh --probe-only <ws>`, then requires `stage/verified-live.sha256` = that hash | The probe action always rebuilds (cc-isolated.sh:880-885), runs `probe_boundary` (:577-705), and only a full pass calls `record_verified_live` into `config_dir` (:113-115, :702). Main's launcher loads host code only from its own directory (cc-isolated.sh:714-718; the pre-Q-089 launcher also did, `source "$(dirname …BASH_SOURCE…)/cc-exit-scan.sh"`). So the stage's copies of `cc-isolated.sh` and the host tools are hashed but never executed. They are staged because `enforcement_files`/`host_tool_files` (cc-isolated.sh:128-151, :199-203) and the bless need them present. |
| 7 | exactly one container with the label; records its image id, and marks it removable only if that id is not in the "before" snapshot | `docker inspect -f '{{.Image}}'` |
| 8 | exports `CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR CC_CONFIG_HASH`, then `devcontainer exec --workspace-folder <ws> --override-config <stage>/devcontainer.json --id-label cc-project=<PID> bash -c "$Q117"` | Exactly the five variables `rebuild_hint` says the by-hand CLI needs (cc-isolated.sh:561-563), and the same `dc` args the launcher uses (:834-836). `bash -c` with the block as one argument is how the probe runs in-container scripts (cc-isolated.sh:608). stdin is `/dev/null`, so nothing reads the rest of the script. |
| 8 | Q-117's container block, verbatim | questions-archive.md:2463-2475 (checked byte for byte). It runs as `remoteUser: node` (devcontainer.json:71). node can read the proxy log: on the branch, `/run/cc-sni-proxy` is 0755 (`init-firewall.sh:1392-1393` on the branch) and the log is opened 0644 (`cc-sni-proxy.py:260`). The `ALLOW sni=… -> <ip>:<port>` field order is the proxy's (`cc-sni-proxy.py:207`). dl.google.com is only in `egress/android.txt`. |
| 9 | verdict = Q-117's own rule: 2 instances, both fetches 200, 0 FAIL lines, the first ALLOW address absent from "pool now"; exit 2 when it never rotated | questions-archive.md:2478 |
| trap | removes the label's containers, the two named volumes, the recorded image (only if new), images tagged `verify-<TREE8>`, then the stage, workspace and clone. Paths are rebuilt from `RUN` and `TREE8`, never read from a file. `--clean` reads only format-checked `RUN`/`T8`/`PID`/`IMG` from `run-*.env`. | So a planted `run-*.env` cannot steer `rm -rf` outside `~/cc-verify`, or `docker rm` outside one 12-hex label |

## What was tested here, without a host

The sandbox has no docker, and nothing ran for real. The script was run end to end in a scratch `HOME` with fake `docker` and `devcontainer` commands on PATH. The fake devcontainer records `up`, creates a labelled container, two volumes and an image, and answers the probe's in-container checks. The real main launcher from `main` was installed into the fake `~/.config/claude-devcontainer` and blessed there, so steps 6-7 ran main's real `--register`, `bless_manifest`, `check_manifest` and `probe_boundary` against the stage. Results:

- pass path: `RESULT Q-117 pass`, every `CHECK` ok, exit 0. A pre-existing "harness" container, volume and image survived. Main's manifests and bin link were unchanged.
- a branch that conflicts (`feat/q125-cc-isolated-sandbox` swapped in): refused at step 1 on `hooks/live-verify-gate.sh`, with no docker call made.
- a `devcontainer.json` difference (`--privileged` added on one side): diff shown, refused at step 3.
- a Q-117 failure (3 FAIL lines): `RESULT Q-117 fail`, teardown and CHECKs ok, exit 1. No rotation: exit 2.
- `kill -9` during step 8: container, volumes, image, stage, clone and run record left behind. The next run refused, `--clean` removed exactly those, and the harness's objects survived.
- `bash -n` and `shellcheck -S warning` are clean.

## Not verified (needs the host run)

1. **Image naming** (research §7). The trap removes the container's image by id when it is new, and any image whose tag contains `verify-<TREE8>`, on the assumption that the devcontainer CLI tags images after the lower-cased workspace folder. If that is wrong, the build's base image may be left behind: it shows under `NOTE … still present`, nothing deletes it, and you remove it by id. If the CLI *retags* an image that existed before, `CHECK no pre-existing image tag moved or removed` fails. That would be the claim refuted.
2. **Main's launcher on a stage dir** (research §7): steps 6-7 are the test. Exercised against the real launcher in the sandbox, but not with the real CLI and dockerd.
3. **The devcontainer CLI and the five exported variables** for `exec`: taken from `rebuild_hint` (cc-isolated.sh:561-563), not observed. A failure shows as `REFUSED: devcontainer exec of the Q-117 block failed.`
4. **`devcontainer exec` passes the inner exit status back**, and `docker image ls --format '{{.ID}} {{.Repository}}:{{.Tag}}'` behaves as in current docker. Both assumed.
5. **git ≥ 2.38 on the host**, for `merge-tree --write-tree`. Without it, step 1 refuses.
6. **`devcontainer read-configuration`** (research §7): not used. The whole-file identity rule in step 3 replaces it.
7. **The build's network and time.** Base layers are probably cache-shared with main's image, since the Dockerfile is identical apart from the `CC_EGRESS_PROFILE`/`CC_CONFIG_HASH` args in the per-project tail. Not measured.

## Residual risks (accepted for a spike)

- **Stage swapped between review and build.** A same-uid process could rewrite a stage file after step 3. Main's launcher hashes the stage's enforcement files at bless and at `--probe-only` (cc-isolated.sh:332-350), which covers `devcontainer.json`, `Dockerfile` and `init-firewall.sh`. A swap-and-revert inside that window stays open, as for install target 1 (decision 037). cc-isolated agents cannot reach `~/cc-verify`.
- **A filter driver in your global `~/.gitconfig`** assigned by a committed `.gitattributes` would run during `git archive` and `git clone`. This is the residual install.sh also carries (decision 037).
- **An agent running the paste.** The `CLAUDECODE` refusal stops accidents only. An agent with host docker access already has more than this script gives it.
- **The verdict covers the merge tree, not the branch tip.** That is deliberate (DD H6). Merging must produce the same tree for the verdict to carry over. With no main commits in between, a clean `git merge` gives exactly this tree.
