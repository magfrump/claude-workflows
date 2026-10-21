#!/usr/bin/env bash
# cc-verify — live-verify a branch's devcontainer config WITHOUT installing it
# (docs/working/dd-branch-verify-without-install.md [5], Q-165 [1]). Run it on the
# HOST from your own terminal, never from a Claude Code session:
#   cc-verify [--profile NAME[,NAME...]] --check FILE REPO BRANCH
#       stage `git merge-tree --write-tree main BRANCH` from REPO's objects, run
#       MAIN's installed cc-isolated on that stage and a scratch clone named
#       VERIFY-<tree8>, run FILE in its container, then tear it all down
#   cc-verify --clean      remove what an interrupted run left (a new run refuses until then)
#   cc-verify --help       this text
# The config verified is the merge tree's devcontainer-config/, never REPO's
# working tree; nothing is installed and main's config dir is never written.
# --profile: the verify workspace's egress grant (default base). FILE runs as
# `bash -c` in the container, stdin closed; its exit status is the verdict.
# Runs live in $CC_VERIFY_ROOT (default ~/cc-verify): add it to your agents'
# sandbox denyWrite, since a same-uid writer there can edit the stage mid-build.
# EXIT STATUS (decision log row 58): 0 the check passed and teardown was clean;
# 1 an error, a refusal, a declined prompt or an incomplete teardown; 2 bad
# usage; 3 the check failed.
set -euo pipefail

SELF="$(readlink -f -- "${BASH_SOURCE[0]}")"
CFG="$(dirname -- "$SELF")"
LAUNCHER="$CFG/cc-isolated.sh"
ROOT="${CC_VERIFY_ROOT:-$HOME/cc-verify}"
RUN="" STEP=preflight DIED=0 DONE=0 T8="" TREE="" SOURCED=()
usage() { awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$SELF"; }
usage_error() { printf 'ERROR: %s\n' "$1" >&2; usage >&2; exit 2; }
die() { DIED=1; printf 'ERROR: %s\n' "$*" >&2; exit 1; }
say() { STEP="$*"; printf '== %s\n' "$*"; }
# Text from branch code or the container: no control bytes, every line indented,
# so it can neither rewrite the terminal nor forge a RESULT or CHECK line.
relay() { LC_ALL=C tr -d '\000-\010\013-\037\177' | sed 's/^/  | /'; }
banner() { echo "=== cc-verify: VERIFY-$T8 is a THROWAWAY verify of tree $TREE, not your checkout. $1 ==="; }
hash_ok() {  # hash_ok MANIFEST NAME: $CFG/NAME matches its one entry in $CFG/MANIFEST
  local want
  want="$(awk -v f="$2" '$2 == f { n++; h = $1 } END { if (n == 1) print h }' "$CFG/$1" 2>/dev/null)"
  [ -n "$want" ] && [ -f "$CFG/$2" ] && [ ! -L "$CFG/$2" ] && [ "$(sha256sum < "$CFG/$2" | cut -d' ' -f1)" = "$want" ]
}

# source_lines_ok DIR FILE: every `source`/`.` line in FILE, and in the files it
# sources, loads a plain name from its own directory, never the config dir, and
# CC_ISOLATED_DIR is only ever that directory (pre-mortem 5: then a stage is inert
# on the host). Prints the first offending line; the names loaded go to SOURCED.
source_lines_ok() {
  local f line i=0 own='"\$\(dirname -- "\$\(readlink -f -- "\$\{BASH_SOURCE\[0\]\}"\)"\)"'
  local src='^[[:space:]]*source "(\$CC_ISOLATED_DIR|\$\(dirname -- "\$\(readlink -f -- "\$\{BASH_SOURCE\[0\]\}"\)"\))/([A-Za-z0-9._-]+)"[[:space:]]*$'
  local -a q=("$2")
  while [ "$i" -lt "${#q[@]}" ]; do
    f="$1/${q[$i]}"; i=$((i + 1))
    [ -f "$f" ] || { echo "$f is missing"; return 1; }
    while IFS= read -r line; do
      if [[ "$line" =~ ^[[:space:]]*(source|\.)[[:space:]] ]]; then
        [[ "$line" =~ $src ]] || { echo "$f: $line"; return 1; }
        [[ " ${q[*]} " == *" ${BASH_REMATCH[2]} "* ]] || q+=("${BASH_REMATCH[2]}")
      elif [[ "$line" == *CC_ISOLATED_DIR=* && ! "$line" =~ ^[[:space:]]*CC_ISOLATED_DIR=${own}[[:space:]]*$ ]]; then
        echo "$f: $line"; return 1
      fi
    done < "$f"
  done
  SOURCED=("${q[@]:1}")
}

# devcontainer_ok MAIN STAGED: pre-mortem 3's rules on the parsed JSONC (comments
# and trailing commas stripped outside strings, duplicate keys refused).
devcontainer_ok() {
  python3 -I - "$1" "$2" <<'PY'
import json, re, sys
def load(path):
    s = open(path, encoding="utf-8").read(); out, i, n = [], 0, len(s)
    while i < n:
        if s[i] == '"':
            j = i + 1
            while j < n and s[j] != '"': j += 2 if s[j] == "\\" else 1
            out.append(s[i:j + 1]); i = j + 1; continue
        if s.startswith("//", i): j = s.find("\n", i); i = n if j < 0 else j; continue
        if s.startswith("/*", i):
            j = s.find("*/", i + 2)
            if j < 0: raise ValueError("unterminated comment")
            i = j + 2; continue
        if s[i] in "}]":
            while out and out[-1].isspace(): out.pop()
            if out and out[-1] == ",": out.pop()
        out.append(s[i]); i += 1
    def pairs(p):
        if len({k for k, _ in p}) != len(p): raise ValueError("duplicate key")
        return dict(p)
    return json.loads("".join(out), object_pairs_hook=pairs), s
try:
    (m, mraw), (s, sraw) = load(sys.argv[1]), load(sys.argv[2])
    assert isinstance(m, dict) and isinstance(s, dict)
except Exception as e:
    print(f"it does not parse as JSONC ({e!r})"); sys.exit(1)
bad = []
# These keys act inside the container. Any other key can reach the host
# (initializeCommand, build, features, workspaceMount, ports...) and must equal main's.
free = {"name", "containerEnv", "remoteEnv", "remoteUser", "containerUser", "waitFor", "onCreateCommand",
        "updateContentCommand", "postCreateCommand", "postStartCommand", "postAttachCommand",
        "customizations", "runArgs", "mounts"}
for k in sorted(set(m) | set(s)):
    if k not in m: bad.append(f"top-level key {k!r} is not in main's devcontainer.json")
    elif k not in free and m.get(k) != s.get(k): bad.append(f"{k!r} differs from main's (it reaches the host)")
ra, i = s.get("runArgs", []), 0
sec = re.compile(r"seccomp=\$\{localEnv:CC_CONFIG_DIR\}/[A-Za-z0-9._-]+\.json")
if not isinstance(ra, list): bad.append("runArgs is not a list"); ra = []
while i < len(ra):
    a, nxt = ra[i], (ra[i + 1] if i + 1 < len(ra) else None)
    if a in ("--cap-add=NET_ADMIN", "--cap-add=NET_RAW"): i += 1
    elif a == "--security-opt" and isinstance(nxt, str) and sec.fullmatch(nxt): i += 2
    elif isinstance(a, str) and a.startswith("--security-opt=") and sec.fullmatch(a[15:]): i += 1
    else: bad.append(f"runArgs entry {a!r} is not allowed"); i += 1
mounts = s.get("mounts", [])
for x in (mounts if isinstance(mounts, list) else [mounts]):
    if x not in m.get("mounts", []): bad.append(f"mount {x!r} is not one of main's")
env = re.compile(r"\$\{\s*(?:localEnv|env)\s*:\s*([^}:\s]+)")
for v in sorted(set(env.findall(sraw)) - set(env.findall(mraw))):
    bad.append(f"it reads the host variable {v!r}, which main's does not")
print("\n".join(bad)); sys.exit(1 if bad else 0)
PY
}

stage_hash() {  # one hash over the stage's build inputs (pre-mortem 4)
  (cd stage && find "${BUILD[@]}" -printf '%p\t%y\t%m\t%l\n' | LC_ALL=C sort \
     && find "${BUILD[@]}" -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum) | sha256sum | cut -d' ' -f1
}

# teardown DIR: remove what the run in DIR created. The project id comes from DIR's
# own path, so a planted record can only name a VERIFY- project inside DIR. An image
# goes only if absent from the run's before-snapshot and unused, never with -f.
teardown() {
  local d="$1" t8 pid cs c img fail=0 imgs=()
  t8="$(sed -n 's/^T8=\([0-9a-f]\{8\}\)$/\1/p' "$d/record" 2>/dev/null | head -1)"
  if [ -n "$t8" ]; then
    pid="$(printf '%s' "$d/VERIFY-$t8" | sha256sum | cut -c1-12)"
    cs="$(docker ps -aq --no-trunc --filter "label=cc-project=$pid")" || { echo "TEARDOWN: docker ps failed"; return 1; }
    for c in $cs; do
      img="$(docker inspect -f '{{.Image}}' "$c")" && imgs+=("$img")
      docker rm -f "$c" >/dev/null || { echo "TEARDOWN: could not remove container $c"; fail=1; }
    done
    for c in "cc-$pid-bashhistory" "cc-$pid-claude-config"; do
      ! docker volume inspect "$c" >/dev/null 2>&1 || docker volume rm "$c" >/dev/null || { echo "TEARDOWN: kept volume $c"; fail=1; }
    done
    for img in "${imgs[@]}"; do
      if [ -f "$d/images-before" ] && ! grep -qxF "$img" "$d/images-before" \
         && [ -z "$(docker ps -aq --no-trunc --filter "ancestor=$img")" ]; then
        docker image rm "$img" >/dev/null || { echo "TEARDOWN: could not remove image $img"; fail=1; }
      else echo "NOTE: kept image $img: it existed before the run, or another container uses it."; fi
    done
  fi
  [ "$fail" = 0 ] && rm -rf --one-file-system -- "$d" \
    || { echo "TEARDOWN: left $d (files the container wrote as root? then: sudo rm -rf -- $(printf %q "$d"))"; return 1; }
}

on_exit() {
  local rc=$?
  trap - EXIT INT TERM HUP
  set +e
  if [ "$DONE" != 1 ]; then   # only the verdict exits 0 or 3
    if [ "$rc" = 130 ]; then echo "ERROR: interrupted." >&2
    elif [ "$rc" != 1 ] || [ "$DIED" != 1 ]; then echo "ERROR: unexpected failure during step \"$STEP\" (status $rc)." >&2; fi
    rc=1
  fi
  cd / && say "teardown"
  if teardown "$RUN"; then echo "CHECK verify container, volumes, image and run dir removed: ok"
  else echo "CHECK teardown complete: FAIL (run: cc-verify --clean)"; rc=1; fi
  [ -z "$T8" ] || banner "It is gone."
  exit "$rc"
}

# --- arguments and preflight: refuse before creating anything ------------------
MODE=run PROFILE=base CHECK="" POS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --clean) MODE=clean; shift ;;
    --profile|--check)
      [ $# -ge 2 ] && [[ "$2" != [-#]* ]] || usage_error "$1 needs a value."
      if [ "$1" = --profile ]; then PROFILE="$2"; else CHECK="$2"; fi
      shift 2 ;;
    --) shift; POS+=("$@"); break ;;
    -*|\#*) usage_error "$(printf 'unknown flag, or a pasted comment: %q' "$1")" ;;
    *) POS+=("$1"); shift ;;
  esac
done
if [ "$MODE" = clean ]; then [ "${#POS[@]}" -eq 0 ] && [ -z "$CHECK" ] || usage_error "--clean takes no other arguments."
else [ "${#POS[@]}" -eq 2 ] && [ -n "$CHECK" ] || usage_error "give --check FILE, REPO and BRANCH."; fi

[ -z "${CLAUDECODE:-}" ] || die "run cc-verify from your own terminal, not from a Claude Code session."
for c in git docker devcontainer python3 sha256sum tar find; do command -v "$c" >/dev/null || die "'$c' not found on PATH."; done
[ -f "$CFG/manifest.sha256" ] || die "cc-verify runs from its installed copy (install.sh links it); $CFG has no manifest."
hash_ok host-tools.sha256 cc-verify.sh || die "$SELF does not match $CFG/host-tools.sha256: review it, then re-bless."
hash_ok manifest.sha256 cc-isolated.sh || die "$LAUNCHER does not match $CFG/manifest.sha256: review it, then re-bless."
why="$(source_lines_ok "$CFG" cc-isolated.sh)" || die "main's launcher may load code from its config dir, so a stage would run on the host: $why"
source_lines_ok "$CFG" cc-isolated.sh

if [ "$MODE" = clean ]; then
  shopt -s nullglob
  rc=0
  for d in "$ROOT"/run-*; do
    p="$(sed -n 's/^PID=\([0-9]*\)$/\1/p' "$d/record" 2>/dev/null | head -1)"
    if [ -L "$d" ] || [ ! -d "$d" ]; then echo "NOTE: skipped $d: not a directory."; rc=1
    elif [ -n "$p" ] && grep -qa cc-verify "/proc/$p/cmdline" 2>/dev/null; then echo "NOTE: skipped $d: run $p is still going."; rc=1
    else d="$(cd -P -- "$d" && pwd)" && echo "cleaning $d" && teardown "$d" || rc=1; fi
  done
  exit "$rc"
fi

REPO="${POS[0]}" BRANCH="${POS[1]}"
[ -f "$CHECK" ] && [ -r "$CHECK" ] || die "cannot read the check file $CHECK."
BLOCK="$(cat -- "$CHECK")"   # read once: a later edit of FILE changes nothing
mkdir -p -- "$ROOT"
shopt -s nullglob; left=("$ROOT"/run-*); shopt -u nullglob
[ "${#left[@]}" -eq 0 ] || die "an earlier run left ${left[*]}; run: cc-verify --clean"
RUN="$ROOT/run-$(date +%s)-$$"
mkdir -m 700 -- "$RUN" && RUN="$(cd -P -- "$RUN" && pwd)" && cd -- "$RUN" || die "could not create $RUN."
trap on_exit EXIT
trap 'exit 130' INT TERM HUP
printf 'PID=%s\n' "$$" > record   # the run file: --clean reads it, and a new run refuses while it exists

say "1. merge main + $BRANCH"
G=(git --no-optional-locks -C src.git -c core.hooksPath=/dev/null -c core.fsmonitor=false)
git -c core.hooksPath=/dev/null -c core.fsmonitor=false clone -q --bare --no-local --template= -- "$REPO" src.git </dev/null \
  || die "could not clone $REPO."
MAIN="$("${G[@]}" rev-parse --verify -q 'refs/heads/main^{commit}')" || die "no branch main in $REPO."
BR="$("${G[@]}" rev-parse --verify -q --end-of-options "$BRANCH^{commit}")" || die "no commit $BRANCH in $REPO."
mrc=0
mt="$("${G[@]}" merge-tree --write-tree --name-only "$MAIN" "$BR" 2>merge-err)" || mrc=$?
[ "$mrc" = 0 ] || { printf '%s\n' "$mt" | cat - merge-err | relay; [ "$mrc" != 1 ] || die "$BRANCH does not merge cleanly with main (above)."
  die "git merge-tree --write-tree failed (it needs git >= 2.38)."; }
TREE="$(head -1 <<< "$mt")"
[[ "$TREE" =~ ^[0-9a-f]{40}([0-9a-f]{24})?$ ]] || die "merge-tree printed no tree id."
T8="${TREE:0:8}"
printf 'PID=%s\nT8=%s\n' "$$" "$T8" > record
banner "Everything it creates is removed at exit."

say "2. stage the merge tree's devcontainer-config/ as install.sh lays it out"
inst="$("${G[@]}" show "$TREE:devcontainer-config/install.sh")" || die "no devcontainer-config/install.sh in the merge tree."
list() {  # list NAME PATTERN: the items of install.sh's one-line NAME=(...), each matching PATTERN
  local l item items
  l="$(grep -m1 "^$1=(.*)\$" <<< "$inst")" || die "no one-line $1=(...) in the merge tree's install.sh."
  l="${l#"$1=("}"
  read -ra items <<< "${l%)}"   # split without globbing
  for item in "${items[@]}"; do [[ "$item" =~ $2 && "$item" != *..* ]] || die "$(printf '%s item %q is not a plain name.' "$1" "$item")"; echo "$item"; done
}
l="$(list PAYLOAD '^[A-Za-z0-9._-]+$')" && mapfile -t PAYLOAD <<< "$l" || { DIED=1; exit 1; }
l="$(list CLAUDE_HOME_SRC '^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)?$')" && mapfile -t HOME_SRC <<< "$l" || { DIED=1; exit 1; }
mapfile -t HOST_TOOLS < <(awk '$2 ~ /^[A-Za-z0-9._-]+$/ { print $2 }' "$CFG/host-tools.sha256")
DC=() BUILD=()
for i in "${PAYLOAD[@]}"; do
  [ "$i" = claude-home ] || DC+=("$i")
  [[ " ${HOST_TOOLS[*]} " == *" $i "* ]] || BUILD+=("$i")
done
mkdir -m 700 stage stage/claude-home
"${G[@]}" archive --format=tar "$TREE:devcontainer-config" -- "${DC[@]}" | tar -x --no-same-owner -C stage -f - \
  || die "could not stage devcontainer-config/ (an item missing from the merge tree?)."
for e in "${HOME_SRC[@]}"; do
  if [[ "$e" == */* ]]; then "${G[@]}" archive --format=tar "$TREE:${e%/*}" -- "${e##*/}"
  else "${G[@]}" archive --format=tar "$TREE" -- "$e"; fi | tar -x --no-same-owner -C stage/claude-home -f - || die "could not stage $e."
done
printf 'commit=%s\ndirty=no\nuncommitted_excluded=0\nassembled_from=cc-verify, merge tree %s of %s and %s\n' \
  "$TREE" "$TREE" "$MAIN" "$BR" > stage/claude-home/.manifest
[ -z "$(find stage -type l -print -quit)" ] || die "the merge tree puts a symlink in the stage."

say "3. review the staged config against main's installed copy"
H="$(stage_hash)"
why="$(devcontainer_ok "$CFG/devcontainer.json" stage/devcontainer.json)" \
  || { printf '%s\n' "$why" | relay; die "the staged devcontainer.json reaches the host in a way main's does not (above)."; }
echo "CHECK devcontainer.json keys, runArgs, mounts and host variables: ok"
for f in devcontainer.json Dockerfile; do diff -u "$CFG/$f" "stage/$f" | relay || true; done
echo "Staged items that differ from main's install:"
for i in "${PAYLOAD[@]}"; do diff -rq "$CFG/$i" "stage/$i" >/dev/null 2>&1 || echo "  $i"; done
printf 'Build and run this config as VERIFY-%s? [y/N] ' "$T8"
read -r reply || reply=""
[[ "$reply" =~ ^[yY]$ ]] || die "declined: nothing was built."

say "4. scratch workspace VERIFY-$T8 at a merge commit of that tree"
MC="$(GIT_AUTHOR_NAME=cc-verify GIT_AUTHOR_EMAIL=cc-verify@localhost GIT_COMMITTER_NAME=cc-verify \
  GIT_COMMITTER_EMAIL=cc-verify@localhost "${G[@]}" commit-tree "$TREE" -p "$MAIN" -p "$BR" -m "cc-verify: main + $BRANCH")"
"${G[@]}" update-ref refs/heads/cc-verify-merge "$MC"
git -c core.hooksPath=/dev/null clone -q --no-local --no-checkout --template= -- src.git "VERIFY-$T8" </dev/null
git -C "VERIFY-$T8" -c core.hooksPath=/dev/null checkout -q --detach "$MC"
WS="$RUN/VERIFY-$T8"
PID="$(printf '%s' "$WS" | sha256sum | cut -c1-12)"
[ -z "$(docker ps -aq --no-trunc --filter "label=cc-project=$PID")" ] || die "a container already carries label cc-project=$PID."
docker image ls -q --no-trunc | LC_ALL=C sort -u > images-before

say "5. register and bless the stage with main's launcher"
unset GH_TOKEN OPENROUTER_API_KEY   # opt-in credentials never reach a container running branch code
CLAUDE_DEVC_CONFIG_DIR="$RUN/stage" "$LAUNCHER" --register "$WS" --profile "$PROFILE" </dev/null 2>&1 | relay || die "--register failed (above)."
[ -f "stage/projects/$PID.profile" ] || die "the launcher wrote no stage/projects/$PID.profile: its project id differs."
[ "$(stage_hash)" = "$H" ] || die "the stage changed between the review and the bless."
for t in "${HOST_TOOLS[@]}"; do rm -f -- "stage/$t"; done
for t in "${SOURCED[@]}"; do [ ! -e "stage/$t" ] || die "stage/$t is still present after the bless."; done
echo "CHECK host tools removed from the stage (${HOST_TOOLS[*]}): ok"

say "6. --probe-only: build, boot and self-probe the staged config"
CLAUDE_DEVC_CONFIG_DIR="$RUN/stage" "$LAUNCHER" --probe-only "$WS" </dev/null 2>&1 | relay || die "--probe-only failed (above)."
HASH="$(sha256sum < stage/manifest.sha256 | cut -c1-16)"
[ "$(tr -d '[:space:]' < stage/verified-live.sha256 2>/dev/null)" = "$HASH" ] || die "no verified-live receipt for $HASH in the stage."
[ "$(stage_hash)" = "$H" ] || die "the stage's build inputs changed after the review: the verdict would be about another config."
echo "CHECK verified-live receipt for config $HASH, stage unchanged since the review: ok"
cid="$(docker ps -aq --no-trunc --filter "label=cc-project=$PID")"
[ "$(grep -c . <<< "$cid")" = 1 ] || die "expected one container labelled cc-project=$PID, found: ${cid:-none}."
read -r priv caps img < <(docker inspect -f '{{.HostConfig.Privileged}} {{json .HostConfig.CapAdd}} {{.Image}}' "$cid") || true
[ "${priv:-}" = false ] || die "the verify container is privileged, or could not be inspected."
for c in ${caps//[\[\]\",]/ }; do
  case "$c" in null|NET_ADMIN|NET_RAW|CAP_NET_ADMIN|CAP_NET_RAW) ;; *) die "the verify container has capability $c." ;; esac
done
grep -qxF "$img" images-before && echo "NOTE: the verify image $img existed before the run; teardown keeps it." \
  || echo "CHECK container unprivileged, capabilities within NET_ADMIN and NET_RAW, image new: ok"

say "7. run $CHECK in VERIFY-$T8"
CC_EGRESS_PROFILE="$(tr -d '[:space:]' < "stage/projects/$PID.profile")"
export CC_PROJECT_ID="$PID" CC_PROJECT_NAME="VERIFY-$T8" CC_CONFIG_DIR="$RUN/stage" CC_CONFIG_HASH="$HASH" CC_EGRESS_PROFILE
rc=0
devcontainer exec --workspace-folder "$WS" --override-config "$RUN/stage/devcontainer.json" \
  --id-label "cc-project=$PID" bash -c "$BLOCK" </dev/null 2>&1 | relay || rc=$?
DONE=1
[ "$rc" = 0 ] || { echo "RESULT cc-verify fail tree=$TREE config=$HASH (check exit $rc)"; exit 3; }
echo "RESULT cc-verify pass tree=$TREE config=$HASH"
echo "Trailer for the merge: Live-verified: $HASH — cc-verify of tree $TREE"
exit 0
