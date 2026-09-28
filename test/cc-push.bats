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
  # Every hook githooks(5) lists (git 2.39), plus two names that are not hooks
  # (pre-upload, upload-pack) in case a git ever runs them on fetch.
  for h in applypatch-msg pre-applypatch post-applypatch pre-commit pre-merge-commit \
           prepare-commit-msg commit-msg post-commit pre-rebase post-checkout post-merge \
           pre-push pre-receive update proc-receive post-receive post-update \
           reference-transaction push-to-checkout pre-auto-gc post-rewrite \
           sendemail-validate fsmonitor-watchman p4-changelist p4-prepare-changelist \
           p4-post-changelist p4-pre-submit post-index-change pre-upload upload-pack; do
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
  # (Includes are refused outright: see the include tests below.)
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
  [[ "$output" == *"has no cc-push marker"* ]]
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
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"the push of main to origin failed"* ]]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" = "$SESSION_HEAD" ]
}

# --- Iteration-3 fact-check regressions (docs/reviews/code-fact-check-report-r{1,2,3}.md
# at a42e37f; E2c/E2b/E4/E5 in r1, P2a in r3).

# other_repo: a host repository the session cannot write, holding a commit that
# must never reach origin through cc-push. Sets OTHER_HEAD.
other_repo() {
  git init -q --bare "$T/other.git"
  git -C "$T/co" push -q "$T/other.git" main:main
  git clone -q "$T/other.git" "$T/oc"
  echo secret > "$T/oc/s"; git -C "$T/oc" add s; git -C "$T/oc" commit -qm "OTHER REPO COMMIT"
  git -C "$T/oc" push -q origin main
  OTHER_HEAD="$(git -C "$T/oc" rev-parse HEAD)"
}

# not_pushed <sha>: origin does not have it.
not_pushed() {
  ! git -C "$T/upstream.git" cat-file -e "$1^{commit}" 2>/dev/null
}

@test "E2c: a .git gitdir: file (redirect to another host repo) is refused, nothing fetched or pushed" {
  other_repo
  mv "$T/co/.git" "$T/co-gitdir"
  echo "gitdir: $T/other.git" > "$T/co/.git"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *".git is not a directory"*"Run it on the main checkout"* ]]
  not_pushed "$OTHER_HEAD"
  [ ! -e "$T/clones" ]
}

@test "a .git that is a symlink to another repo is refused" {
  other_repo
  rm -rf "$T/co/.git"
  ln -s "$T/other.git" "$T/co/.git"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *".git is a symlink"* ]]
  not_pushed "$OTHER_HEAD"
}

@test "P2a: objects/info/alternates naming another host repo is refused, its commit not pushed" {
  other_repo
  echo "$T/other.git/objects" > "$T/co/.git/objects/info/alternates"
  git --git-dir="$T/co/.git" update-ref refs/heads/leak "$OTHER_HEAD"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --branch leak --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"objects/info/alternates exists"* ]]
  not_pushed "$OTHER_HEAD"
}

@test "http-alternates and a commondir file are refused too" {
  echo "http://example.invalid/x" > "$T/co/.git/objects/info/http-alternates"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *"http-alternates exists"* ]]
  rm "$T/co/.git/objects/info/http-alternates"
  echo "../../elsewhere" > "$T/co/.git/commondir"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *"commondir exists"* ]]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" != "$SESSION_HEAD" ]
}

@test "a symlinked object store (aliasing another repo's objects) is refused" {
  other_repo
  mv "$T/co/.git/objects" "$T/co-objects"
  ln -s "$T/other.git/objects" "$T/co/.git/objects"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *".git/objects is a symlink, FIFO, socket or device"* ]]
  not_pushed "$OTHER_HEAD"
}

@test "a symlinked hook is not a reason to refuse (upload-pack never reads hooks/)" {
  printf '#!/bin/sh\ntouch %s/hook\n' "$M" > "$T/hk"; chmod +x "$T/hk"
  ln -s "$T/hk" "$T/co/.git/hooks/pre-push"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 0 ]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" = "$SESSION_HEAD" ]
  [ -z "$(markers)" ]
}

@test "E2b: an include.path naming a FIFO is refused at once, not hung on" {
  mkfifo "$T/fifo"
  git config --file "$T/co/.git/config" include.path "$T/fifo"
  run timeout 30 bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"has an [include] or [includeIf] section"* ]]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" != "$SESSION_HEAD" ]
  # The r1 form (the FIFO inside .git, named relatively) is refused as well.
  git config --file "$T/co/.git/config" include.path fifo
  mkfifo "$T/co/.git/fifo"
  run timeout 30 bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
}

@test "includeIf, an upper-case [ Include ], a header after another on one line, and config.worktree are refused" {
  local cfg="$T/co/.git/config" orig
  orig="$(cat "$cfg")"
  printf '[includeIf "gitdir:/"]\n\tpath = /nowhere\n' >> "$cfg"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  printf '%s\n[ Include ]\n\tpath = /nowhere\n' "$orig" > "$cfg"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  printf '%s\n[user][include]path = /nowhere\n' "$orig" > "$cfg"
  # git itself reads that line as an include:
  [ "$(git config --file "$cfg" --get include.path)" = /nowhere ]
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *"[include] or [includeIf] section"* ]]
  printf '%s\n' "$orig" > "$cfg"
  git config --file "$T/co/.git/config.worktree" include.path /nowhere
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *"config.worktree has an [include]"* ]]
}

@test "a FIFO as packed-refs inside .git is refused without blocking" {
  mkfifo "$T/co/.git/packed-refs"
  run timeout 30 bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"packed-refs is a symlink, FIFO, socket or device"* ]]
}

@test "a newline in the name of a refused .git entry cannot forge a line" {
  mkfifo "$T/co/.git/$(printf 'x\nPushed main to origin.')"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *"x?Pushed main to origin."* ]]
  run grep -c '^Pushed main' <<< "$output"
  [ "$output" -eq 0 ]
}

@test "E4: a branch name with C1 CSI (U+009B and a raw 0x9b byte) and RLO (U+202E) never reaches the terminal raw" {
  local b; b="$(printf 'feat\xc2\x9b31mX\xe2\x80\xaeevil\x9b2J')"
  git check-ref-format "refs/heads/$b"   # git accepts it
  git -C "$T/co" checkout -q -b "$b"
  echo z >> "$T/co/f"; git -C "$T/co" commit -qam z
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 0 ]
  git -C "$T/upstream.git" rev-parse -q --verify "refs/heads/$b"
  [[ "$output" == *"as feat??31mX???evil?2J."* ]]
  [[ "$output" == *"origin has no branch feat??31mX???evil?2J"* ]]
  [[ "$output" == *"Pushed feat??31mX???evil?2J to origin."* ]]
  run env LC_ALL=C grep -c -a -e $'\x9b' -e $'\xe2\x80\xae' <<< "$output"
  [ "$output" -eq 0 ]
}

@test "E4: a remote rejection naming the branch is shown through vis too" {
  local b; b="$(printf 'r\xc2\x9bx')"
  git -C "$T/co" checkout -q -b "$b"
  printf '#!/bin/sh\necho "refused $1"; exit 1\n' > "$T/upstream.git/hooks/update"
  chmod +x "$T/upstream.git/hooks/update"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"refused refs/heads/r??x"* ]]
  run env LC_ALL=C grep -c -a -e $'\x9b' <<< "$output"
  [ "$output" -eq 0 ]
}

@test "E5: a git fatal (unwritable clone parent) exits 1, never git's 128" {
  [ "$(id -u)" -ne 0 ] || skip "root ignores directory permissions"
  mkdir "$T/ro"; chmod 555 "$T/ro"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --clone "$T/ro/clone" --yes "$T/co"
  chmod 755 "$T/ro"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"could not create the host-only clone"* ]]
}

@test "unrelated history: the preview says so and the rejected push exits 1, not 128" {
  git -C "$T/co" checkout -q --orphan fresh
  echo other > "$T/co/g"; git -C "$T/co" add g; git -C "$T/co" commit -qm unrelated
  git -C "$T/co" branch -q -D main
  git -C "$T/co" branch -q -m fresh main
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no diff stat: main shares no history with origin/main"* ]]
  [[ "$output" == *"the push of main to origin failed"* ]]
}

@test "--help prints the whole header, exit codes included" {
  run bash "$CC_PUSH" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Exit codes: 0 pushed"*"2 declined at the prompt."* ]]
  [[ "$output" == *"real remote, after the push, like any other collaborator's commits."* ]]
  [[ "$output" != *"set -euo pipefail"* ]]
}
