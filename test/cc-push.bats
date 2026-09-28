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
  # cc-push refuses while it cannot rule out a running cc-isolated container:
  # a docker stub that lists none (and logs its arguments) stands in for docker.
  mkdir -p "$T/bin"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s/docker-argv"\nprintf "%%s" "${STUB_DOCKER_PS:-}"\nexit "${STUB_DOCKER_RC:-0}"\n' "$T" > "$T/bin/docker"
  chmod +x "$T/bin/docker"
  PATH="$T/bin:$PATH"
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

@test "cc-push declined at the prompt pushes nothing and exits 1" {
  run bash "$CC_PUSH" --remote "$T/upstream.git" "$T/co" <<< n
  [ "$status" -eq 1 ]
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
  [[ "$output" == *"Exit codes"*"0 pushed, or nothing to push"*"or declined at the prompt (n, or Ctrl-C)"*"2 bad usage"* ]]
  [[ "$output" == *"--allow-running"* ]]
  [[ "$output" == *"real remote, after the push, like any other collaborator's commits."* ]]
  [[ "$output" != *"set -euo pipefail"* ]]
}

# --- Git-directory validity (cc-gitdir.sh). When <checkout>/.git is not a git
# directory git accepts, git's discovery falls back to the checkout root as a bare
# repository: a session could empty .git/HEAD and plant a repository there.

# gd <name>: a copy of the checkout's .git at $T/gd/<name>, to vary.
gd() {
  mkdir -p "$T/gd"
  cp -r "$T/co/.git" "$T/gd/$1"
  printf '%s' "$T/gd/$1"
}

# wtgd <name>: a copy of the linked worktree wt's git dir at $T/gd/<name>, its
# commondir naming the checkout's .git by absolute path.
wtgd() {
  mkdir -p "$T/gd"
  cp -r "$T/co/.git/worktrees/wt" "$T/gd/$1"
  printf '%s\n' "$T/co/.git" > "$T/gd/$1/commondir"
  printf '%s' "$T/gd/$1"
}

# git_accepts <dir>: git-upload-pack --strict's verdict (enter_repo -> git 2.39's
# is_git_directory), through ls-remote as cc-push calls it.
git_accepts() {
  git -c protocol.file.allow=always ls-remote --upload-pack='git-upload-pack --strict' "$1" >/dev/null 2>&1
}

# plant_root_repo: the other_repo history as a bare repository at the checkout
# root (HEAD, objects/, refs/, config: all working-tree files to the checkout).
plant_root_repo() {
  other_repo
  cp -r "$T/other.git/." "$T/co/"
}

@test "gitdir_valid agrees with git on valid, broken-HEAD, missing-dir and commondir-linked git dirs" {
  source "$BATS_TEST_DIRNAME/../devcontainer-config/cc-gitdir.sh"
  local d sha; sha="$(git -C "$T/co" rev-parse HEAD)"
  git -C "$T/co" worktree add -q "$T/wt" -b wt
  declare -A want=()
  d="$(gd plain)";       want[$d]=valid
  d="$(gd detached)";    echo "$sha" > "$d/HEAD"; want[$d]=valid
  d="$(gd sha256)";      printf '%s%s\n' "$sha" 0123456789abcdef0123456789ab > "$d/HEAD"; want[$d]=valid
  d="$(gd linkhead)";    rm "$d/HEAD"; ln -s refs/heads/main "$d/HEAD"; want[$d]=valid
  d="$(gd nospace)";     printf 'ref:refs/heads/main' > "$d/HEAD"; want[$d]=valid
  d="$(gd tabs)";        printf 'ref: \t refs/heads/main\n' > "$d/HEAD"; want[$d]=valid
  d="$(gd nohead)";      rm "$d/HEAD"; want[$d]=invalid
  d="$(gd garbage)";     echo 'hello world' > "$d/HEAD"; want[$d]=invalid
  d="$(gd notrefs)";     echo 'ref: heads/main' > "$d/HEAD"; want[$d]=invalid
  d="$(gd shorthex)";    printf '%s\n' "${sha:0:39}" > "$d/HEAD"; want[$d]=invalid
  d="$(gd nul)";         printf 'ref:\0 refs/heads/main\n' > "$d/HEAD"; want[$d]=invalid
  d="$(gd headdir)";     rm "$d/HEAD"; mkdir "$d/HEAD"; want[$d]=invalid
  d="$(gd linkabs)";     rm "$d/HEAD"; ln -s "$T/co/.git/HEAD" "$d/HEAD"; want[$d]=invalid
  d="$(gd noobjects)";   rm -rf "$d/objects"; want[$d]=invalid
  d="$(gd norefs)";      rm -rf "$d/refs"; want[$d]=invalid
  d="$T/co/.git/worktrees/wt";                     want[$d]=valid
  # A linked worktree's git dir, copied, its commondir made absolute: HEAD here,
  # objects/ and refs/ only in the common dir it names.
  d="$(wtgd wtlinked)";  want[$d]=valid
  d="$(wtgd wtrel)";     echo ../../co/.git > "$d/commondir"; want[$d]=valid
  d="$(wtgd wtnohead)";  rm "$d/HEAD"; want[$d]=invalid
  d="$(wtgd wtnowhere)"; echo "$T/nowhere" > "$d/commondir"; want[$d]=invalid
  d="$(wtgd wtempty)";   : > "$d/commondir"; want[$d]=invalid
  d="$(wtgd wtnotgit)";  echo "$T/co" > "$d/commondir"; want[$d]=invalid
  local got g bad=0
  for d in "${!want[@]}"; do
    if gitdir_valid "$d"; then got=valid; else got=invalid; fi
    if git_accepts "$d"; then g=valid; else g=invalid; fi
    if [ "$got" != "${want[$d]}" ] || [ "$g" != "${want[$d]}" ]; then
      echo "$d: gitdir_valid=$got git=$g want=${want[$d]}"; bad=1
    fi
  done
  [ "$bad" -eq 0 ]
}

@test "gitdir_valid and gitdir_head_kind: stricter than git only where git reads past 255 bytes; a FIFO HEAD does not block" {
  source "$BATS_TEST_DIRNAME/../devcontainer-config/cc-gitdir.sh"
  local d
  d="$(gd big)"; { printf 'ref: refs/heads/main\n'; head -c 300 /dev/zero | tr '\0' x; } > "$d/HEAD"
  run ! gitdir_valid "$d"
  d="$(gd fifo)"; rm "$d/HEAD"; mkfifo "$d/HEAD"
  run timeout 10 bash -c 'source "$1"; gitdir_head_kind "$2"' _ "$BATS_TEST_DIRNAME/../devcontainer-config/cc-gitdir.sh" "$d"
  [ "$status" -eq 0 ]
  [ "$output" = invalid ]
  [ "$(gitdir_head_kind "$T/co/.git")" = symref ]
  d="$(gd k1)"; git -C "$T/co" rev-parse HEAD > "$d/HEAD"
  [ "$(gitdir_head_kind "$d")" = detached ]
  d="$(gd k2)"; rm "$d/HEAD"; ln -s refs/heads/main "$d/HEAD"
  [ "$(gitdir_head_kind "$d")" = symlink ]
}

@test "looks_like_gitdir: HEAD next to objects/, or a commondir file; not a normal checkout root" {
  source "$BATS_TEST_DIRNAME/../devcontainer-config/cc-gitdir.sh"
  run ! looks_like_gitdir "$T/co"
  looks_like_gitdir "$T/co/.git"
  mkdir -p "$T/r1/objects"; touch "$T/r1/HEAD"
  looks_like_gitdir "$T/r1"
  mkdir -p "$T/r2"; touch "$T/r2/HEAD"
  run ! looks_like_gitdir "$T/r2"
  mkdir -p "$T/r3/objects"
  run ! looks_like_gitdir "$T/r3"
  mkdir -p "$T/r4"; echo .. > "$T/r4/commondir"
  looks_like_gitdir "$T/r4"
}

@test "cc-push refuses a .git without HEAD, and does not fall back to a repository planted at the root" {
  plant_root_repo
  rm "$T/co/.git/HEAD"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *".git is not a valid git directory"* ]]
  not_pushed "$OTHER_HEAD"
  [ ! -e "$T/clones" ]
}

@test "cc-push refuses a .git whose HEAD is garbage" {
  echo garbage > "$T/co/.git/HEAD"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *".git is not a valid git directory"* ]]
  not_pushed "$SESSION_HEAD"
}

@test "cc-push refuses a checkout root holding HEAD, objects/ and refs/ (a planted bare repository)" {
  plant_root_repo
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"itself looks like a git directory"* ]]
  not_pushed "$OTHER_HEAD"
  not_pushed "$SESSION_HEAD"
}

@test "cc-push refuses a checkout root holding a commondir file" {
  echo .git > "$T/co/commondir"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *"itself looks like a git directory"* ]]
  not_pushed "$SESSION_HEAD"
}

@test "cc-push fetches from <checkout>/.git by name, with git-upload-pack --strict" {
  local real_git co; real_git="$(command -v git)"
  co="$(cd "$T/co" && pwd -P)"
  mkdir -p "$T/bin"
  cat > "$T/bin/git" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$T/git-argv"
exec "$real_git" "\$@"
EOF
  chmod +x "$T/bin/git"
  PATH="$T/bin:$PATH" run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"; cat "$T/git-argv"
  [ "$status" -eq 0 ]
  grep -qxF -- "-c core.hooksPath=/dev/null -c core.fsmonitor=false -C $CC_PUSH_CLONES_DIR/co-$(printf '%s' "$co" | sha256sum | cut -c1-12) -c protocol.file.allow=always fetch -q --no-tags --no-recurse-submodules --no-write-fetch-head --upload-pack=git-upload-pack --strict $co/.git +refs/heads/main:refs/cc/heads/main" "$T/git-argv"
  grep -qF -- "ls-remote --upload-pack=git-upload-pack --strict --symref $co/.git HEAD" "$T/git-argv"
  # Nothing names the checkout root as a repository.
  ! grep -E -- " $co( |\$)" "$T/git-argv"
}

# --- Q-076 review round (security/performance/API reviews and fact-check r3 of
# 2026-09-27): container check, one-branch fetch, git version floor, exit codes,
# usage, partial clones.

# cc_id <path>: cc-isolated's project id for <path>, from cc-isolated.sh itself.
cc_id() {
  bash -c 'source "$1"; project_id "$2"' _ "$BATS_TEST_DIRNAME/../devcontainer-config/cc-isolated.sh" "$1"
}

@test "cc-push's project_id is cc-isolated's (the container label it asks docker for)" {
  local co; co="$(cd "$T/co" && pwd -P)"
  [ "$(bash -c 'source "$1"; project_id "$2"' _ "$CC_PUSH" "$co")" = "$(cc_id "$co")" ]
}

@test "a running cc-isolated container for the checkout: refused (exit 1), nothing fetched" {
  local co; co="$(cd "$T/co" && pwd -P)"
  STUB_DOCKER_PS=$'cc-app-1\n' run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"a cc-isolated container for $co is running (cc-app-1)"*"docker stop cc-app-1"*"--allow-running"* ]]
  grep -qxF -- "ps --filter label=cc-project=$(cc_id "$co") --format {{.Names}}" "$T/docker-argv"
  [ ! -e "$T/clones" ]
  not_pushed "$SESSION_HEAD"
}

@test "--allow-running goes on past a running container, with a warning" {
  STUB_DOCKER_PS=$'cc-app-1\n' run bash "$CC_PUSH" --allow-running --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: a cc-isolated container for "*"is RUNNING (cc-app-1)"* ]]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" = "$SESSION_HEAD" ]
}

@test "docker that does not answer: refused unless --allow-running" {
  STUB_DOCKER_RC=1 run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"docker did not answer"*"cannot check whether a cc-isolated container"*"--allow-running"* ]]
  [ ! -e "$T/clones" ]
  STUB_DOCKER_RC=1 run bash "$CC_PUSH" --allow-running --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: docker did not answer"* ]]
}

@test "no docker at all: refused unless --allow-running" {
  rm "$T/bin/docker"
  ! command -v docker >/dev/null || skip "a real docker is on PATH"
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"docker is not installed, so cc-push cannot check"* ]]
  run bash "$CC_PUSH" --allow-running --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: docker is not installed"* ]]
}

@test "only the pushed branch is fetched: an unrelated branch never reaches the host clone" {
  git -C "$T/co" checkout -q -b junk
  echo junk > "$T/co/j"; git -C "$T/co" add j; git -C "$T/co" commit -qm junk
  local junk; junk="$(git -C "$T/co" rev-parse HEAD)"
  git -C "$T/co" checkout -q main
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 0 ]
  local clone; clone="$(echo "$T"/clones/co-*)"
  run ! git -C "$clone" cat-file -e "$junk^{commit}"
  [ -z "$(git -C "$clone" for-each-ref refs/cc/heads/junk)" ]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" = "$SESSION_HEAD" ]
}

@test "git_version_ok: the May 2024 fixed releases and later pass, earlier ones do not" {
  source "$BATS_TEST_DIRNAME/../devcontainer-config/cc-push.sh"
  local v
  for v in 2.39.4 2.39.5 2.40.2 2.41.1 2.42.2 2.43.4 2.44.1 2.45.1 2.45.2 2.46.0 2.47.1 3.0.0 \
           2.39.4.windows.1 2.46.0-rc0; do
    git_version_ok "git version $v" || { echo "refused $v"; return 1; }
  done
  for v in 2.39.3 2.40.1 2.41.0 2.42.1 2.43.3 2.44.0 2.45.0 2.38.9 2.30.0 1.9.9; do
    ! git_version_ok "git version $v" || { echo "accepted $v"; return 1; }
  done
  run ! git_version_ok "git version x.y"
  run ! git_version_ok ""
}

@test "cc-push refuses to run on a git below the fixed releases, before touching the checkout" {
  local real_git; real_git="$(command -v git)"
  mkdir -p "$T/oldgit"
  cat > "$T/oldgit/git" <<STUB
#!/usr/bin/env bash
if [ "\$1" = --version ]; then echo "git version 2.39.3"; exit 0; fi
exec "$real_git" "\$@"
STUB
  chmod +x "$T/oldgit/git"
  PATH="$T/oldgit:$PATH" run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"git version 2.39.3 is older than the fixed releases"* ]]
  [ ! -e "$T/clones" ]
  [ ! -e "$T/docker-argv" ]
}

@test "usage errors exit 2: unknown flag, a flag without its value, two checkouts (with or without --)" {
  run bash "$CC_PUSH" --nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown flag: --nope"* ]]
  run bash "$CC_PUSH" --remote
  [ "$status" -eq 2 ]
  run bash "$CC_PUSH" "$T/co" "$T/co"
  [ "$status" -eq 2 ]
  [[ "$output" == *"one checkout at a time"* ]]
  run bash "$CC_PUSH" --clone "$T/x" "$T/co" -- "$T/other"
  [ "$status" -eq 2 ]
  [[ "$output" == *"one checkout at a time"* ]]
  run bash "$CC_PUSH" -- "$T/co" "$T/other"
  [ "$status" -eq 2 ]
  [ ! -e "$T/x" ] && [ ! -e "$T/clones" ]
  # One checkout after -- is fine.
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes -- "$T/co"
  [ "$status" -eq 0 ]
}

@test "Ctrl-C at the prompt is a decline: exit 1, not 130, nothing pushed" {
  mkfifo "$T/in"
  # SIGINT default (a background job starts with it ignored, which a trap cannot
  # undo) and its own process group, so the whole cc-push tree gets the signal.
  perl -e '$SIG{INT} = "DEFAULT"; setpgrp(0, 0); exec @ARGV or die' \
    bash "$CC_PUSH" --remote "$T/upstream.git" "$T/co" < "$T/in" > "$T/out" 2>&1 &
  local pid=$! rc=0
  exec 7> "$T/in"   # the writer end, so cc-push's read blocks (bats owns fd 3)
  for _ in $(seq 1 300); do
    grep -q 'Push these?' "$T/out" 2>/dev/null && break
    sleep 0.1
  done
  grep -q 'Push these?' "$T/out"
  kill -INT -- "-$pid"
  wait "$pid" || rc=$?
  exec 7>&-
  cat "$T/out"
  [ "$rc" -eq 1 ]
  grep -q 'Not pushed.' "$T/out"
  not_pushed "$SESSION_HEAD"
}

@test "a partial clone is refused up front, with the reason" {
  local cfg="$T/co/.git/config" orig
  orig="$(cat "$cfg")"
  git config --file "$cfg" remote.origin.promisor true
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"marks a partial clone"* ]]
  [ ! -e "$T/clones" ]
  printf '%s\n' "$orig" > "$cfg"
  git config --file "$cfg" extensions.partialClone origin
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  [[ "$output" == *"marks a partial clone"* ]]
  printf '%s\n[remote "o"] PROMISOR = true\n' "$orig" > "$cfg"
  [ "$(git config --file "$cfg" --get remote.o.promisor)" = true ]
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 1 ]
  # partialCloneFilter alone does not make a partial clone, and is not refused.
  printf '%s\n' "$orig" > "$cfg"
  git config --file "$cfg" remote.origin.partialCloneFilter blob:none
  run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 0 ]
}

@test "err_vis: only stderr goes through vis, stdout is captured untouched, the status is kept" {
  source "$BATS_TEST_DIRNAME/../devcontainer-config/cc-push.sh"
  local out
  out="$(err_vis bash -c 'printf "keep\n"; printf "bad\033[2J\n" >&2; exit 3' 2>"$T/err")" && return 1
  [ "$out" = keep ]
  [ "$(cat "$T/err")" = "bad?[2J" ]
  run err_vis bash -c 'exit 3'
  [ "$status" -eq 3 ]
}

@test "PATH: a program the session wrote is never run by name, from a relative or checkout PATH entry" {
  # Plant a `git` in the checkout and put it on PATH both ways: as a relative
  # entry (run from inside the checkout) and as an absolute path into it.
  mkdir -p "$T/co/bin"
  printf '#!/bin/sh\ntouch "%s/planted-ran"\nexit 1\n' "$T" > "$T/co/bin/git"
  chmod +x "$T/co/bin/git"
  cd "$T/co"
  PATH="bin:$T/co/bin:$PATH" run bash "$CC_PUSH" --remote "$T/upstream.git" --yes "$T/co"
  [ "$status" -eq 0 ]
  [ ! -e "$T/planted-ran" ]
  [ "$(git -C "$T/upstream.git" rev-parse refs/heads/main)" = "$SESSION_HEAD" ]
}
