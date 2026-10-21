#!/usr/bin/env bats
# @category fast
# devcontainer-config/cc-verify.sh, one or more cases per pre-mortem mitigation
# (docs/working/research-2026-10-20-cc-verify-host-tool.md §5). docker, devcontainer,
# claude, curl, gh and wget are strict PATH stubs; git is real, on local fixture repos.
bats_require_minimum_version 1.5.0

setup() {
  SRC="$BATS_TEST_DIRNAME/../devcontainer-config"
  T="$(mktemp -d)"; export STUB="$T/stub" HOME="$T/home" CC_VERIFY_ROOT="$T/root"
  unset CLAUDECODE
  mkdir -p "$STUB" "$HOME" "$T/bin" "$T/cfg"
  for t in claude curl gh wget; do printf '#!/bin/sh\necho "no network: %s" >&2; exit 99\n' "$t" > "$T/bin/$t"; done
  # docker: only the calls cc-verify makes; anything else fails loudly.
  cat > "$T/bin/docker" <<'EOF'
#!/usr/bin/env bash
echo "docker $*" >> "$STUB/docker.log"
c="$(cat "$STUB/container" 2>/dev/null)"
case "$*" in
  "ps -aq --no-trunc --filter label=cc-project=$c") [ -z "$c" ] || echo cid1 ;;
  "ps -aq --no-trunc --filter "*) ;;
  "inspect -f {{.Image}} cid1") echo sha256:new ;;
  "rm -f cid1") rm -f "$STUB/container" ;;
  "volume inspect "*) [ -f "$STUB/vol-$3" ] ;;
  "volume rm "*) rm "$STUB/vol-$3" ;;
  "image ls -q --no-trunc") echo sha256:old ;;
  "image rm sha256:new") ;;
  *) echo "unexpected: docker $*" >&2; exit 99 ;;
esac
EOF
  # devcontainer: only `exec ... bash -c BLOCK`, which runs BLOCK here.
  cat > "$T/bin/devcontainer" <<'EOF'
#!/usr/bin/env bash
[ "$1 $2 $4 $6 $8 $9" = "exec --workspace-folder --override-config --id-label bash -c" ] || { echo "unexpected: devcontainer $*" >&2; exit 99; }
exec bash -c "${10}"
EOF
  # Main's "installed launcher": --register blesses the stage, --probe-only starts a
  # container and writes the receipt.
  cat > "$T/cfg/cc-isolated.sh" <<'EOF'
#!/usr/bin/env bash
set -eu
c="$CLAUDE_DEVC_CONFIG_DIR"; pid="$(printf %s "$2" | sha256sum | cut -c1-12)"
case "$1" in
  --register) mkdir -p "$c/projects"; echo "$4" > "$c/projects/$pid.profile"
    (cd "$c" && sha256sum devcontainer.json Dockerfile > manifest.sha256 && sha256sum cc-push.sh cc-verify.sh > host-tools.sha256) ;;
  --probe-only) echo "$pid" > "$STUB/container"; touch "$STUB/vol-cc-$pid-bashhistory" "$STUB/vol-cc-$pid-claude-config"
    sha256sum < "$c/manifest.sha256" | cut -c1-16 > "$c/verified-live.sha256" ;;
  *) exit 99 ;;
esac
EOF
  chmod +x "$T/bin/"* "$T/cfg/cc-isolated.sh"
  PATH="$T/bin:$PATH"
  # The fixture repo: main, and branch feat/x changing the Dockerfile.
  R="$T/repo"; mkdir -p "$R/devcontainer-config/egress" "$R/global-instructions" "$R/skills"
  printf 'PAYLOAD=(devcontainer.json Dockerfile cc-isolated.sh cc-push.sh cc-verify.sh egress claude-home)\nCLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills)\n' > "$R/devcontainer-config/install.sh"
  cat > "$R/devcontainer-config/devcontainer.json" <<'EOF'
{
  // main's config
  "name": "cc (${localEnv:CC_PROJECT_NAME})",
  "build": { "dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile" },
  "runArgs": ["--cap-add=NET_ADMIN", "--cap-add=NET_RAW"],
  "mounts": ["source=cc-${localEnv:CC_PROJECT_ID}-bashhistory,target=/commandhistory,type=volume"],
  "containerEnv": { "A": "1" },
}
EOF
  echo 'FROM x' > "$R/devcontainer-config/Dockerfile"
  cp "$T/cfg/cc-isolated.sh" "$SRC/cc-verify.sh" "$R/devcontainer-config/"
  echo push > "$R/devcontainer-config/cc-push.sh"; echo base > "$R/devcontainer-config/egress/base.txt"
  echo hi > "$R/global-instructions/CLAUDE.md"; echo s > "$R/skills/s.md"
  git -C "$R" init -q -b main && commit "$R" init
  git -C "$R" checkout -q -b feat/x && echo 'FROM y' > "$R/devcontainer-config/Dockerfile" && commit "$R" branch
  git -C "$R" checkout -q main
  # Main's install: main's files, cc-verify itself, and both manifests.
  cp "$R/devcontainer-config/"{devcontainer.json,Dockerfile,cc-push.sh,cc-verify.sh} "$T/cfg/"
  bless_main
  printf 'echo "name=$CC_PROJECT_NAME"\n' > "$T/check"
}
teardown() { chmod -R u+rwx "$T" 2>/dev/null; rm -rf "$T"; }
commit() { git -C "$1" add -A && git -C "$1" -c user.name=t -c user.email=t@e -c commit.gpgsign=false commit -qm "$2"; }
bless_main() { (cd "$T/cfg" && sha256sum cc-isolated.sh devcontainer.json Dockerfile > manifest.sha256 && sha256sum cc-push.sh cc-verify.sh > host-tools.sha256); }
verify() { run "$T/cfg/cc-verify.sh" --check "$T/check" "$R" "${1:-feat/x}" <<< "${2:-y}"; }

@test "pass: VERIFY-<tree8> naming and banner, tree id in RESULT and trailer, host tools gone, all torn down (1, 6)" {
  tree="$(git -C "$R" merge-tree --write-tree main feat/x)"
  verify
  [ "$status" -eq 0 ]
  [[ "$output" == *"  | name=VERIFY-${tree:0:8}"* ]]
  [ "$(grep -c "VERIFY-${tree:0:8} is a THROWAWAY verify of tree $tree" <<< "$output")" = 2 ]
  [[ "$output" == *"RESULT cc-verify pass tree=$tree config="* ]]
  [[ "$output" == *"Live-verified: "*" — cc-verify of tree $tree"* ]]
  [[ "$output" == *"+FROM y"* ]]   # the Dockerfile diff was shown before the y
  [[ "$output" == *"CHECK host tools removed from the stage (cc-push.sh cc-verify.sh): ok"* ]]
  [[ "$output" == *"CHECK verify container, volumes, image and run dir removed: ok"* ]]
  grep -qx 'docker image rm sha256:new' "$STUB/docker.log"
  [ -z "$(ls -A "$CC_VERIFY_ROOT")" ] && [ -z "$(ls "$STUB" | grep '^vol-')" ]
}

@test "a failing check exits 3 and still tears down" {
  echo 'exit 5' > "$T/check"
  verify
  [ "$status" -eq 3 ]
  [[ "$output" == *"RESULT cc-verify fail tree="*"(check exit 5)"* ]]
  [ -z "$(ls -A "$CC_VERIFY_ROOT")" ]
}

@test "a run file refuses a new run until --clean removes the old run's container, volumes and dir (2)" {
  verify; [ "$status" -eq 0 ]
  d="$CC_VERIFY_ROOT/run-1-1"; mkdir -p "$d"; printf 'PID=1\nT8=abcdef12\n' > "$d/record"
  pid="$(printf '%s' "$d/VERIFY-abcdef12" | sha256sum | cut -c1-12)"
  echo "$pid" > "$STUB/container"; touch "$STUB/vol-cc-$pid-claude-config"
  verify
  [ "$status" -eq 1 ] && [[ "$output" == *"an earlier run left $d; run: cc-verify --clean"* ]]
  run "$T/cfg/cc-verify.sh" --clean
  [ "$status" -eq 0 ] && [ ! -e "$d" ] && [ ! -e "$STUB/container" ] && [ ! -e "$STUB/vol-cc-$pid-claude-config" ]
}

@test "n at the prompt declines: nothing is built and the run dir is gone (3)" {
  verify feat/x n
  [ "$status" -eq 1 ] && [[ "$output" == *"declined: nothing was built."* ]]
  ! grep -q 'cid1\|volume' "$STUB/docker.log"
  [ -z "$(ls -A "$CC_VERIFY_ROOT")" ]
}

@test "a branch that conflicts with main is refused (6)" {
  echo 'FROM z' > "$R/devcontainer-config/Dockerfile"; commit "$R" main-moves
  verify
  [ "$status" -eq 1 ] && [[ "$output" == *"feat/x does not merge cleanly with main"* ]]
}

@test "refusals before anything is created: CLAUDECODE, a changed cc-verify, a repo checkout copy, bad usage (7, 8)" {
  CLAUDECODE=1 verify
  [ "$status" -eq 1 ] && [[ "$output" == *"not from a Claude Code session"* ]]
  echo '# edited' >> "$T/cfg/cc-verify.sh"; verify
  [ "$status" -eq 1 ] && [[ "$output" == *"does not match $T/cfg/host-tools.sha256"* ]]
  run "$SRC/cc-verify.sh" --clean
  [ "$status" -eq 1 ] && [[ "$output" == *"runs from its installed copy"* ]]
  run "$T/cfg/cc-verify.sh" "$R"
  [ "$status" -eq 2 ]
  [ ! -e "$CC_VERIFY_ROOT" ] && [ ! -e "$STUB/docker.log" ]
}
