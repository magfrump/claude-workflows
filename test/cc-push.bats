#!/usr/bin/env bats
# @category fast
# cc-push (devcontainer-config/cc-push.sh, Q-076): push a cc-isolated session's
# commits from a host-only bare clone that fetches from the checkout, so nothing
# the session planted in the checkout runs on the host.
#
# Every planted command touches a marker under $M; the suite asserts cc-push leaves
# none. The "real remote" is a local bare repo (no network).
#
# Usage: bats test/cc-push.bats

bats_require_minimum_version 1.5.0

setup() {
  CC_PUSH="$BATS_TEST_DIRNAME/../devcontainer-config/cc-push.sh"
  T="$(mktemp -d)"
  M="$T/ran"
  mkdir -p "$M" "$T/home"
  # Hermetic git: no user or system config leaks in, and none is written.
  export HOME="$T/home"
  export GIT_CONFIG_GLOBAL="$T/home/.gitconfig"
  export GIT_CONFIG_NOSYSTEM=1
  export CC_PUSH_CLONES_DIR="$T/clones"
  git config --global user.name t
  git config --global user.email t@example.com
  git config --global commit.gpgsign false
  git config --global init.defaultBranch main
  # The real remote, and a checkout of it with one session commit.
  git init -q --bare "$T/upstream.git"
  git init -q "$T/co"
  echo base > "$T/co/f"
  git -C "$T/co" add f
  git -C "$T/co" commit -qm base
  git -C "$T/co" push -q "$T/upstream.git" main
  echo session > "$T/co/f"
  git -C "$T/co" commit -qam "session work"
  SESSION_HEAD="$(git -C "$T/co" rev-parse HEAD)"
}

teardown() {
  rm -rf "$T"
}

# plant_all: everything the fact-checks planted that host git in the checkout
# would run, done after the checkout's last commit (the plants would fire in it).
plant_all() {
  local g="$T/co/.git" h
  for h in pre-push pre-commit post-checkout post-merge post-commit reference-transaction \
           post-update pre-receive update post-receive push-to-checkout pre-auto-gc \
           post-rewrite post-index-change fsmonitor-watchman pre-upload upload-pack; do
    printf '#!/bin/sh\ntouch %s/hook-%s\n' "$M" "$h" > "$g/hooks/$h"
    chmod +x "$g/hooks/$h"
  done
  mkdir -p "$T/co/.husky/_"
  printf '#!/bin/sh\ntouch %s/husky\n' "$M" > "$T/co/.husky/_/pre-push"
  chmod +x "$T/co/.husky/_/pre-push"
  git config --file "$g/config" core.hooksPath .husky/_
  git config --file "$g/config" core.fsmonitor "touch $M/fsmonitor; true"
  git config --file "$g/config" filter.x.clean "touch $M/clean; cat"
  git config --file "$g/config" filter.x.smudge "touch $M/smudge; cat"
  git config --file "$g/config" filter.x.process "touch $M/process"
  echo '* filter=x' > "$g/info/attributes"
  git config --file "$g/config" core.sshCommand "touch $M/ssh"
  git config --file "$g/config" core.gitProxy "touch $M/gitproxy"
  git config --file "$g/config" core.askPass "touch $M/askpass"
  git config --file "$g/config" core.pager "touch $M/pager"
  git config --file "$g/config" core.alternateRefsCommand "touch $M/altrefs"
  git config --file "$g/config" uploadpack.packObjectsHook "touch $M/packobjectshook"
  git config --file "$g/config" uploadpack.allowFilter true
  git config --file "$g/config" credential.helper "!touch $M/credhelper"
  git config --file "$g/config" diff.external "touch $M/diffext"
  git config --file "$g/config" gc.auto 1
  git config --file "$g/config" remote.origin.url "$T/evil.git"
  git config --file "$g/config" remote.origin.receivepack "touch $M/receivepack; git-receive-pack"
  git config --file "$g/config" remote.origin.uploadpack "touch $M/uploadpack; git-upload-pack"
  git config --file "$g/config" remote.pushDefault ./evil.git
  printf '[core]\n\tfsmonitor = touch %s/included\n' "$M" > "$T/co/inc.cfg"
  git config --file "$g/config" include.path ../inc.cfg
  git config --file "$g/config" "includeIf.gitdir:/.path" ../inc.cfg
  mkdir -p "$g/remotes"; printf 'URL: ./evil.git\n' > "$g/remotes/upstream"
  git init -q --bare "$T/evil.git"
  printf '#!/bin/sh\ntouch %s/evil-receive\n' "$M" > "$T/evil.git/hooks/post-receive"
  chmod +x "$T/evil.git/hooks/post-receive"
  # A tracked-file shape: the attributes the fetched tree carries.
  printf '* filter=x diff=x\n' > "$T/co/.gitattributes"
}

markers() {
  ls -A "$M"
}

@test "cc-push pushes the checkout's branch from a host-only bare clone" {
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" = "$SESSION_HEAD" ]
  [[ "$output" == *"session work"* ]]
  local clone; clone="$(echo "$T"/clones/co-*)"
  [ "$(git -C "$clone" rev-parse --is-bare-repository)" = true ]
  [ "$(git -C "$clone" config core.hooksPath)" = /dev/null ]
  [ "$(cat "$clone/cc-push-checkout")" = "$(cd "$T/co" && pwd -P)" ]
}

@test "cc-push runs nothing planted in the checkout (full plant set)" {
  plant_all
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" = "$SESSION_HEAD" ]
  [ -z "$(markers)" ] || { echo "ran: $(markers)"; return 1; }
  # The remote came from --remote, never from the checkout's (planted) config.
  [ "$(git -C "$T/evil.git" for-each-ref | wc -l)" -eq 0 ]
  # The plants are live: host git in the checkout would have run them.
  git -C "$T/co" status >/dev/null 2>&1 || true
  [ -n "$(markers)" ]
}

@test "cc-push, second run: reuses the clone and its remote; a later session commit is pushed" {
  bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo more >> "$T/co/f"; git -C "$T/co" commit -qam "second"
  plant_all
  cd "$T/co"   # default checkout: the one containing $PWD
  run bash "$CC_PUSH" --yes
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" = "$(git -C "$T/co" rev-parse HEAD)" ]
  [[ "$output" == *"second"* ]]
  [ -z "$(markers)" ]
}

@test "cc-push without --remote on first use refuses and creates nothing" {
  run bash "$CC_PUSH" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *"--remote"* ]]
  [ ! -e "$T/clones" ]
}

@test "cc-push declined at the prompt pushes nothing" {
  run bash "$CC_PUSH" --remote "$T/upstream.git" "$T/co" <<< n
  [ "$status" -eq 2 ]
  [[ "$output" == *"Not pushed."* ]]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" != "$SESSION_HEAD" ]
}

@test "cc-push refuses a clone inside the checkout, or a directory it did not create" {
  run bash "$CC_PUSH" --remote "$T/upstream.git" --clone "$T/co/sub/clone" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *"inside the checkout"* ]]
  [ ! -e "$T/co/sub" ]
  git init -q "$T/mine"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --clone "$T/mine" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not made by cc-push"* ]]
}

@test "cc-push shows container-written commit text with control bytes as '?'" {
  echo x >> "$T/co/f"
  git -C "$T/co" commit -qam "$(printf 'evil\033[2J subject')"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 0 ]
  [[ "$output" == *"evil?[2J subject"* ]]
  [[ "$output" != *$'\033'* ]]
}

@test "cc-push --branch pushes a branch other than HEAD's; an unknown one is refused" {
  git -C "$T/co" branch feat/x
  echo y >> "$T/co/f"; git -C "$T/co" commit -qam "on main only"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --branch feat/x --yes "$T/co"
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/feat/x)" = "$SESSION_HEAD" ]
  run bash "$CC_PUSH" --branch nope --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no branch nope"* ]]
}

@test "cc-push never forces: a rewritten branch is refused by the remote" {
  bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  git -C "$T/co" reset -q --hard HEAD~1
  echo other > "$T/co/f"; git -C "$T/co" commit -qam "rewritten"
  run bash "$CC_PUSH" --yes "$T/co"
  [ "$status" -ne 0 ]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" = "$SESSION_HEAD" ]
}
