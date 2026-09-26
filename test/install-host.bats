#!/usr/bin/env bats
# @category slow
# Hermetic tests for install.sh's host ~/.claude target (decision 037,
# plan docs/working/plan-copy-install-bare-host.md, T1-T24).
#
# HERMETICITY. install.sh writes real host paths by default. Every test pins
# HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR and TMPDIR
# into BATS_TEST_TMPDIR, and unsets CLAUDE_CONFIG_DIR (set in Claude Code
# sessions; install.sh honours it as a destination). The installer under test is
# a COPY inside a throwaway fake repo, never this checkout's live paths.
#
# The y path needs a TTY, which is the point of the host target's skip rule. The
# pty tests get one from util-linux `script -qec CMD /dev/null`, fed the answers
# on stdin ("n\ny\n" = decline the devcontainer target, accept the host one).
# They also unset CLAUDECODE, which the installer treats as "running inside a
# Claude Code session" (T22).
#
# Usage: bats test/install-host.bats

bats_require_minimum_version 1.5.0

setup() {
  CONFIG_SRC="$BATS_TEST_DIRNAME/../devcontainer-config"
  S="$BATS_TEST_TMPDIR"
  export HOME="$S/home"
  export CLAUDE_HOME_DIR="$HOME/.claude"
  export CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/claude-devcontainer"
  export CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
  export TMPDIR="$S/tmp"
  export SHELL=/bin/bash   # `script -c` runs the command under $SHELL
  unset CLAUDE_CONFIG_DIR USAGE_LOG_FILE
  mkdir -p "$HOME" "$TMPDIR"
  ROOT="$S/repo"
  INSTALL="$ROOT/devcontainer-config/install.sh"
  # The no-agent gate (Q-058) asks pgrep and docker what is running. The session
  # running these tests is itself a Claude Code process, so both are stubbed to
  # "nothing running" by default; a test that wants an agent rewrites a stub.
  # Every stub call is logged to $S/probe.log.
  STUB="$S/stub"
  mkdir -p "$STUB"
  stub_pgrep 'exit 1'
  stub_docker 'exit 0'
  export PATH="$STUB:$PATH"
}

# stub_pgrep / stub_docker <body>: replace the stub's body (after logging argv).
stub_pgrep() {
  printf '#!/bin/bash\necho "pgrep $*" >> "%s/probe.log"\n%s\n' "$S" "$1" > "$STUB/pgrep"
  chmod +x "$STUB/pgrep"
}
stub_docker() {
  printf '#!/bin/bash\necho "docker $*" >> "%s/probe.log"\n%s\n' "$S" "$1" > "$STUB/docker"
  chmod +x "$STUB/docker"
}

# path_without <cmd...>: print a PATH (stubs first) under which each named
# command is absent: every other executable on the current PATH is linked
# into one directory, then the named ones are removed from it. One `ln` per
# PATH directory and no per-entry test (review C2, P2-C2): non-executable
# entries get linked too, which is harmless in a PATH directory, since command
# lookup skips them. A name an earlier directory already linked makes ln
# report "File exists" and go on, so the first on PATH wins, as on PATH itself.
path_without() {
  local farm="$S/farm" dir skip
  mkdir -p "$farm"
  local IFS=:
  for dir in $PATH; do
    [ "$dir" = "$STUB" ] || [ ! -d "$dir" ] && continue
    ln -s "$dir"/* "$farm/" 2>/dev/null || true
  done
  for skip in "$@"; do rm -f "$farm/$skip" "$STUB/$skip"; done
  printf '%s:%s\n' "$STUB" "$farm"
}

teardown() {
  # T16 makes the destination read-only; let bats clean it up.
  [ -d "$S/home/.claude" ] && chmod -R u+w "$S/home/.claude" 2>/dev/null || true
}

need_script() {
  command -v script >/dev/null || skip "util-linux script not installed (needed for a pty)"
}

# A throwaway git repo holding a copy of install.sh, the seven claude-home
# sources and a stub devcontainer payload. cc-isolated.sh is an executable stub,
# so a devcontainer "y" runs a fake --bless instead of anything real.
fake_repo() {
  local cfg="$ROOT/devcontainer-config" f
  rm -rf "$ROOT"
  mkdir -p "$cfg/egress" "$ROOT/global-instructions" "$ROOT/skills/a" "$ROOT/workflows" \
           "$ROOT/guides" "$ROOT/patterns" "$ROOT/hooks/lib" "$ROOT/scripts"
  cp "$CONFIG_SRC/install.sh" "$cfg/install.sh"
  printf 'global instructions\n' > "$ROOT/global-instructions/CLAUDE.md"
  printf 'skill a\n'  > "$ROOT/skills/a/SKILL.md"
  printf 'workflow\n' > "$ROOT/workflows/w.md"
  printf 'guide\n'    > "$ROOT/guides/g.md"
  printf 'pattern\n'  > "$ROOT/patterns/p.md"
  printf '#!/bin/bash\nexit 0\n' > "$ROOT/hooks/h.sh"
  printf '#!/bin/bash\n' > "$ROOT/hooks/lib/x.sh"
  printf '{"hooks":{}}\n' > "$ROOT/hooks/wiring.json"
  printf '#!/bin/bash\n' > "$ROOT/scripts/s.sh"
  for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py link-claude-home.sh; do
    printf 'stub %s\n' "$f" > "$cfg/$f"
  done
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$cfg/cc-isolated.sh"
  chmod +x "$cfg/cc-isolated.sh"
  printf 'api.anthropic.com\n' > "$cfg/egress/base.txt"
  printf 'devcontainer-config/claude-home/\n' > "$ROOT/.gitignore"
  git -C "$ROOT" init -q
  commit_all init
}

# install.sh stages COMMITTED content only, so a fixture edit that should be
# installed has to be committed.
commit_all() {
  git -C "$ROOT" add -A
  git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m "${1:-edit}"
}

# The README's symlink install, plus host-owned user state that must survive.
symlink_install() {
  local d="$CLAUDE_HOME_DIR" n
  mkdir -p "$d/hooks" "$d/projects/x" "$d/memory" "$d/logs"
  ln -s "$ROOT/global-instructions/CLAUDE.md" "$d/CLAUDE.md"
  for n in workflows skills patterns guides scripts; do ln -s "$ROOT/$n" "$d/$n"; done
  ln -s "$ROOT/hooks/h.sh" "$d/hooks/h.sh"           # per-file hook link
  printf 'copied security hook\n' > "$d/hooks/guard.py"  # README's copied hooks
  printf '{"user":"settings"}\n' > "$d/settings.json"
  printf '{"local":1}\n'        > "$d/settings.local.json"
  printf 'p\n'                  > "$d/projects/x/p.json"
  printf 'm\n'                  > "$d/memory/m.md"
  printf '{"l":1}\n'            > "$d/logs/usage.jsonl"
  printf 'secret\n'             > "$d/.credentials.json"
}

# Listing + content hashes of a tree, not following links. Excludes the
# devcontainer staging dir (every run reassembles it) and .git.
snap() {
  local dir="$1"
  [ -e "$dir" ] || { echo "ABSENT"; return; }
  (cd "$dir" && find . -path ./.git -prune -o -path ./devcontainer-config/claude-home -prune \
     -o -printf '%p %y %l\n' | sort
   cd "$dir" && find . -path ./.git -prune -o -path ./devcontainer-config/claude-home -prune \
     -o -type f -print0 | sort -z | xargs -0 -r sha256sum)
}

# Run install.sh inside a pty. $1 = answers (printf %b), rest = command words.
run_pty() {
  local input="$1"; shift
  run bash -c 'set -o pipefail; printf "%b" "$1" | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d "\r"' \
      _ "$input" "$*"
}

# Like run_pty, but stdin comes from the shell snippet $1, so a test can act
# while install.sh waits at a prompt (e.g. tamper with the stage, then answer).
run_pty_feed() {
  local feed="$1"; shift
  run bash -c 'set -o pipefail; { eval "$1"; } | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d "\r"' \
      _ "$feed" "$*"
}

# Feed snippet: answer n to the devcontainer target, wait (max ~20 s) for the
# review's view of the destination (made after the copies are hashed, right
# before the review; it sits in $dest/.cw-stage.*), give the review time to
# finish, run $TAMPER, then answer y.
FEED_TAMPER='printf "n\n"
  for _i in $(seq 200); do compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*/installed" >/dev/null && break; sleep 0.1; done
  sleep 2; eval "$TAMPER"; printf "y\n"'

no_host_stage_left() {
  ! compgen -G "$TMPDIR/cw-host-stage.*" >/dev/null &&
    ! compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*" >/dev/null
}

@test "T1 plain run with closed stdin: devcontainer declines as today, host skipped, dest untouched" {
  fake_repo; symlink_install
  before=$(snap "$CLAUDE_HOME_DIR")
  run env -u CLAUDECODE bash "$INSTALL" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *'Aborted. Nothing was changed.'* ]]
  [[ "$output" == *'Skipped host target'*'interactive terminal'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  no_host_stage_left
}

@test "T2 piped answers without a TTY never reach the host target" {
  fake_repo; symlink_install
  before=$(snap "$CLAUDE_HOME_DIR")
  run bash -c 'printf "n\ny\n" | env -u CLAUDECODE bash "$1"' _ "$INSTALL"
  [[ "$output" == *'Skipped host target'*'interactive terminal'* ]]
  [[ "$output" != *'Install these files'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
}

@test "T3 --yes without a TTY installs the devcontainer target and skips the host" {
  fake_repo; symlink_install
  before=$(snap "$CLAUDE_HOME_DIR")
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *'BLESS-STUB --bless'* ]]
  [ -L "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ]
  [[ "$output" == *'Skipped host target'*'--yes'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
}

@test "T4 --yes inside a pty still skips the host target" {
  need_script; fake_repo; symlink_install
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty "" bash "$INSTALL" --yes
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *'Skipped host target'*'--yes'* ]]
  [[ "$output" != *'Install these files'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
}

@test "T5 migration review names every symlink it will replace, before the prompt" {
  need_script; fake_repo; symlink_install
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\nn\n' bash "$INSTALL"
  echo "$output"
  for n in CLAUDE.md workflows skills patterns guides scripts hooks/h.sh; do
    [[ "$output" == *"REPLACE symlink $CLAUDE_HOME_DIR/$n -> "* ]]
  done
  review="${output%%Install these files*}"
  [ "$review" != "$output" ]                 # the host prompt was reached
  [[ "$review" == *'REPLACE symlink'* ]]     # ...and every REPLACE line precedes it
  [[ "${output#*Install these files}" != *'REPLACE symlink'* ]]
  # The devcontainer dest does not exist (first install), so any "(none" would
  # be the host review wrongly reporting an invisible migration.
  [[ "$output" != *'(none'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
}

@test "T6 migration y path: real copies in place, checkout untouched, links backed up as links" {
  need_script; fake_repo; symlink_install
  ln -s "$ROOT/global-instructions/CLAUDE.md" "$CLAUDE_HOME_DIR/.claude-workflows-manifest"
  repo_before=$(snap "$ROOT")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  for n in CLAUDE.md skills workflows guides patterns hooks scripts; do
    [ -e "$CLAUDE_HOME_DIR/$n" ]
    [ ! -L "$CLAUDE_HOME_DIR/$n" ]
  done
  [ -z "$(find "$CLAUDE_HOME_DIR/hooks" -type l)" ]
  diff -r "$ROOT/skills" "$CLAUDE_HOME_DIR/skills"
  diff -r "$ROOT/hooks" "$CLAUDE_HOME_DIR/hooks"
  diff "$ROOT/global-instructions/CLAUDE.md" "$CLAUDE_HOME_DIR/CLAUDE.md"
  [ ! -e "$ROOT/skills/skills" ]
  [ "$(snap "$ROOT")" = "$repo_before" ]
  [ ! -L "$CLAUDE_HOME_DIR/.claude-workflows-manifest" ]
  bk=$(echo "$CLAUDE_HOME_DIR"/.claude-workflows-backup/*)
  [ -L "$bk/skills" ]
  [ "$(readlink "$bk/skills")" = "$ROOT/skills" ]
  [ -L "$bk/CLAUDE.md" ]
  [ -L "$bk/hooks/h.sh" ]
  [[ "$output" == *"$bk"* ]]
}

@test "T7 user state in the destination is byte-identical after an install" {
  need_script; fake_repo; symlink_install
  sums() { (cd "$CLAUDE_HOME_DIR" && sha256sum settings.json settings.local.json projects/x/p.json memory/m.md logs/usage.jsonl .credentials.json); }
  before=$(sums)
  run_pty 'n\ny\n' bash "$INSTALL"
  [ -d "$CLAUDE_HOME_DIR/skills" ] && [ ! -L "$CLAUDE_HOME_DIR/skills" ]   # the install ran
  [ "$(sums)" = "$before" ]
}

@test "T8 hermeticity: a host install writes nothing outside the host destination" {
  need_script; fake_repo; symlink_install
  touch "$S/stamp"; sleep 1
  run_pty 'n\ny\n' bash "$INSTALL"
  [ -d "$CLAUDE_HOME_DIR/skills" ] && [ ! -L "$CLAUDE_HOME_DIR/skills" ]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR" ]
  [ ! -e "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ]
  [ -z "$(find "$HOME" -path "$CLAUDE_HOME_DIR" -prune -o -newer "$S/stamp" -print)" ]
  no_host_stage_left
}

@test "T9 installed hooks still find lib/ and ../scripts (log-usage smoke test)" {
  need_script; fake_repo
  rm -rf "$ROOT/hooks" "$ROOT/scripts"
  # The committed hooks and scripts: a `cp -R` of the tree also took ignored
  # __pycache__/*.pyc, which the NUL-byte check (T61) rightly refuses.
  git -C "$CONFIG_SRC/.." archive HEAD hooks scripts | tar -xf - -C "$ROOT"
  commit_all real-hooks
  run_pty 'n\ny\n' bash "$INSTALL"
  [ -f "$CLAUDE_HOME_DIR/hooks/lib/usage-common.sh" ]
  [ -f "$CLAUDE_HOME_DIR/scripts/lib/skill-paths.sh" ]
  cd "$S"
  run bash "$CLAUDE_HOME_DIR/hooks/log-usage.sh" <<<'{"tool_name":"Skill","tool_input":{"skill":"smoke"}}'
  echo "$output"
  [ "$status" -eq 0 ]
  grep -q '"smoke"' "$HOME/.claude/logs/usage.jsonl"
}

@test "T10 the provenance manifest names the commit, the source and the installer" {
  need_script; fake_repo
  run_pty 'n\ny\n' bash "$INSTALL"
  m="$CLAUDE_HOME_DIR/.claude-workflows-manifest"
  grep -q "^commit=$(git -C "$ROOT" rev-parse HEAD)$" "$m"
  grep -q "^assembled_from=$ROOT$" "$m"
  # installed_by=host-tty claimed a property the code does not establish (A2).
  [ -z "$(grep '^installed_by=' "$m")" ]
  grep -q '^installed_parent=' "$m"
}

@test "T40 --help and README state the skip rule's limits and CLAUDE_HOME_DIR (review A1, A5)" {
  fake_repo
  run bash "$INSTALL" --help
  [ "$status" -eq 0 ]
  [[ "$output" != *'only installs for a human'* ]]
  [[ "$output" == *'not a determined agent'* ]]
  [[ "$output" == *'CLAUDE_HOME_DIR'*'install.sh only'*'CLAUDE_CONFIG_DIR'* ]]
  readme="$BATS_TEST_DIRNAME/../README.md"
  [ -z "$(grep 'only installs for a human' "$readme")" ]
  grep -q 'not a determined agent' "$readme"
  grep -q 'CLAUDE_HOME_DIR' "$readme"
}

@test "T11 wiring reminder: on first install, not when unchanged, again when wiring.json changes" {
  need_script; fake_repo; symlink_install
  run_pty 'n\ny\n' bash "$INSTALL"
  [[ "$output" == *'bare-host-hook-wiring.md'* ]]
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" == *'(none'* ]]
  [[ "$output" != *'bare-host-hook-wiring.md'* ]]
  printf '{"hooks":{"x":1}}\n' > "$ROOT/hooks/wiring.json"; commit_all
  run_pty 'n\ny\n' bash "$INSTALL"
  [[ "$output" == *'bare-host-hook-wiring.md'* ]]
}

@test "T12 a review diff that fails aborts before the host prompt" {
  need_script; fake_repo
  mkdir -p "$CLAUDE_HOME_DIR"; printf 'not a dir\n' > "$CLAUDE_HOME_DIR/skills"
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'could not diff'* ]]
  [[ "$output" != *'Install these files'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
}

@test "T13 a foreign file in an owned dir is listed, then moved to the backup" {
  need_script; fake_repo
  mkdir -p "$CLAUDE_HOME_DIR"; cp -R "$ROOT/skills" "$CLAUDE_HOME_DIR/skills"
  mkdir -p "$CLAUDE_HOME_DIR/skills/mine"; printf 'mine\n' > "$CLAUDE_HOME_DIR/skills/mine/SKILL.md"
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" == *"MOVE to backup (not in the repo): $CLAUDE_HOME_DIR/skills/mine/SKILL.md"* ]]
  [ ! -e "$CLAUDE_HOME_DIR/skills/mine" ]
  [ "$(cat "$CLAUDE_HOME_DIR"/.claude-workflows-backup/*/skills/mine/SKILL.md)" = mine ]
}

@test "T14 a destination that resolves inside the checkout is refused" {
  need_script; fake_repo
  mkdir -p "$ROOT/inrepo"; mkdir -p "$(dirname "$CLAUDE_HOME_DIR")"
  ln -s "$ROOT/inrepo" "$CLAUDE_HOME_DIR"
  repo_before=$(snap "$ROOT")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'inside the repo checkout'* ]]
  [ "$(snap "$ROOT")" = "$repo_before" ]
}

@test "T15 an unknown flag prints usage and exits 2 before assembling anything" {
  fake_repo
  run bash "$INSTALL" --bogus </dev/null
  [ "$status" -eq 2 ]
  [[ "$output" == *'Usage:'* ]]
  [ ! -e "$ROOT/devcontainer-config/claude-home" ]
}

@test "T16 a copy failure swaps nothing and leaves no backup" {
  need_script; fake_repo; symlink_install
  chmod a-w "$CLAUDE_HOME_DIR"
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  chmod u+w "$CLAUDE_HOME_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *'nothing was replaced'* ]]   # the copy step failed safely (before the review, since R2)
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  [ ! -e "$CLAUDE_HOME_DIR/.claude-workflows-backup" ]
  ! compgen -G "$CLAUDE_HOME_DIR/.cw-new.*" >/dev/null
}

@test "T17 declining the host prompt changes nothing and cleans the stage" {
  need_script; fake_repo; symlink_install
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\nn\n' bash "$INSTALL"
  [ "$status" -eq 1 ]
  [[ "$output" == *'Aborted. Nothing was changed. (host'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  no_host_stage_left
}

@test "T18 first install creates the destination with all seven entries" {
  need_script; fake_repo
  run_pty 'n\ny\n' bash "$INSTALL"
  for n in CLAUDE.md skills workflows guides patterns hooks scripts; do
    [ -e "$CLAUDE_HOME_DIR/$n" ]
  done
  [ -f "$CLAUDE_HOME_DIR/.claude-workflows-manifest" ]
  [ ! -e "$CLAUDE_HOME_DIR/.claude-workflows-backup" ]
}

@test "T19 accepting the devcontainer target still installs it, then offers the host" {
  need_script; fake_repo
  run_pty 'y\nn\n' bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'BLESS-STUB --bless'* ]]
  [ -f "$CLAUDE_DEVC_CONFIG_DIR/devcontainer.json" ]
  [[ "$output" == *'Install these files'* ]]
  [ ! -e "$CLAUDE_HOME_DIR/skills" ]
}

@test "T20 a foreign hook wired in settings is flagged before it is moved" {
  need_script; fake_repo; symlink_install
  printf '#!/bin/bash\n' > "$CLAUDE_HOME_DIR/hooks/mine.sh"
  printf '{"hooks":{"Stop":[{"command":"bash ~/.claude/hooks/mine.sh"}]}}\n' > "$CLAUDE_HOME_DIR/settings.json"
  run_pty 'n\nn\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" == *"MOVE to backup (not in the repo): $CLAUDE_HOME_DIR/hooks/mine.sh"*'WIRED in settings'* ]]
}

@test "T21 a planted backup-dir symlink is refused and the checkout is untouched" {
  need_script; fake_repo; symlink_install
  mkdir -p "$ROOT/bk"; ln -s "$ROOT/bk" "$CLAUDE_HOME_DIR/.claude-workflows-backup"
  repo_before=$(snap "$ROOT"); before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'.claude-workflows-backup'* ]]
  [ "$(snap "$ROOT")" = "$repo_before" ]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
}

@test "T22 inside a Claude Code session (CLAUDECODE set) the host target is skipped even with a pty" {
  need_script; fake_repo; symlink_install
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' env CLAUDECODE=1 bash "$INSTALL"
  echo "$output"
  [[ "$output" == *'Skipped host target'*'Claude Code session'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
}

@test "T23 a dirty checkout is called out in the host review" {
  need_script; fake_repo
  printf 'edited\n' >> "$ROOT/skills/a/SKILL.md"
  run_pty 'n\nn\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" == *'uncommitted changes'*'NOT included'* ]]
  [[ "$output" == *'skills/a/SKILL.md'* ]]
}

@test "T25 uncommitted edits (unstaged, staged, untracked) are listed and NOT installed" {
  need_script; fake_repo
  printf 'edited\n' >> "$ROOT/global-instructions/CLAUDE.md"
  printf 'staged\n' > "$ROOT/workflows/w.md"; git -C "$ROOT" add workflows/w.md
  printf 'new\n' > "$ROOT/skills/a/untracked.md"
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  review="${output%%Install these files*}"
  [[ "$review" == *'NOT included'* ]]
  for p in global-instructions/CLAUDE.md workflows/w.md skills/a/untracked.md; do
    [[ "$review" == *"$p"* ]]
  done
  [ "$(cat "$CLAUDE_HOME_DIR/CLAUDE.md")" = 'global instructions' ]
  [ "$(cat "$CLAUDE_HOME_DIR/workflows/w.md")" = workflow ]
  [ ! -e "$CLAUDE_HOME_DIR/skills/a/untracked.md" ]
  m="$CLAUDE_HOME_DIR/.claude-workflows-manifest"
  grep -q "^commit=$(git -C "$ROOT" rev-parse HEAD)$" "$m"
  grep -q '^dirty=no$' "$m"
}

@test "T26 git-ignored files in the checkout (e.g. __pycache__) are never installed" {
  need_script; fake_repo
  printf '__pycache__/\n' >> "$ROOT/.gitignore"; commit_all ignore
  mkdir -p "$ROOT/scripts/__pycache__"; printf 'bytecode\n' > "$ROOT/scripts/__pycache__/x.pyc"
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [ -f "$CLAUDE_HOME_DIR/scripts/s.sh" ]
  [ ! -e "$CLAUDE_HOME_DIR/scripts/__pycache__" ]
  [[ "$output" != *'NOT included'* ]]   # ignored files are not "uncommitted changes"
}

@test "T27 a symlink in the committed payload is refused before any prompt (review R1)" {
  need_script; fake_repo; symlink_install
  printf '#!/bin/bash\nexit 0\n' > "$S/agent-writable.sh"
  ln -s "$S/agent-writable.sh" "$ROOT/hooks/guard.sh"; commit_all link
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *'symlink'*'hooks/guard.sh'* ]]
  [[ "$output" != *'[y/N]'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  [ ! -L "$CLAUDE_HOME_DIR/hooks/guard.sh" ]
}

@test "T28 a stage edited while the prompt waits is not installed: the reviewed copies are (review R2, Q-061)" {
  need_script; fake_repo; symlink_install
  export TAMPER='for f in "$CLAUDE_HOME_DIR"/.cw-stage.*/payload/hooks/h.sh; do printf "echo TAMPERED\n" >> "$f"; done'
  run_pty_feed "$FEED_TAMPER" bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]                           # the devcontainer target was declined
  [[ "$output" == *'Installed into'* ]]
  [ -z "$(grep -rls TAMPERED "$CLAUDE_HOME_DIR")" ]
  [ "$(cat "$CLAUDE_HOME_DIR/hooks/h.sh")" = "$(printf '#!/bin/bash\nexit 0')" ]
  ! compgen -G "$CLAUDE_HOME_DIR/.cw-new.*" >/dev/null
}

@test "T67 a stage swapped for the review and swapped back before y installs only what the review showed (review R2, SP1)" {
  need_script; fake_repo
  run_pty 'n\ny\n' bash "$INSTALL"
  [ "$(cat "$CLAUDE_HOME_DIR/hooks/h.sh")" = "$(printf '#!/bin/bash\nexit 0')" ]
  printf '#!/bin/bash\necho MALICIOUS-PAYLOAD\n' > "$ROOT/hooks/h.sh"
  printf 'guide v2 benign\n' > "$ROOT/guides/g.md"
  commit_all mal
  # A same-uid helper the gate does not see (the pgrep stub reports none): it
  # swaps the stage's h.sh for the installed one while the review is produced,
  # and restores it 1.5 s later, before the y.
  (
    d=""; end=$((SECONDS + 30))
    while [ -z "$d" ] && [ "$SECONDS" -lt "$end" ]; do
      d=$(compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*/installed" | head -1) || true; sleep 0.005
    done
    [ -n "$d" ] || exit 0   # never saw the review start: helper.done stays absent
    st="${d%/installed}/payload"
    cp "$st/hooks/h.sh" "$S/mal.keep"
    printf '#!/bin/bash\nexit 0\n' > "$st/hooks/h.sh"; touch -r "$S/mal.keep" "$st/hooks/h.sh"
    sleep 1.5
    cp "$S/mal.keep" "$st/hooks/h.sh"
    echo swapped-back > "$S/helper.done"
  ) &
  export TAMPER="sleep 1.5"
  run_pty_feed "$FEED_TAMPER" bash "$INSTALL"
  wait
  echo "$output"
  [ -f "$S/helper.done" ]
  [[ "$output" == *'Installed into'* ]]
  # What was installed is what the review displayed: the review showed the
  # committed h.sh, which is what landed, whatever the stage held meanwhile.
  [[ "$output" == *'+echo MALICIOUS-PAYLOAD'* ]]
  [ "$(cat "$CLAUDE_HOME_DIR/hooks/h.sh")" = "$(printf '#!/bin/bash\necho MALICIOUS-PAYLOAD')" ]
  [ "$(cat "$CLAUDE_HOME_DIR/guides/g.md")" = 'guide v2 benign' ]
}

# tmpdir_writer <file-name> <content>: a same-uid writer the gate does not see.
# Until $S/stop exists (at most 20 s), it rewrites every file of that name
# under $TMPDIR that does not already hold <content>, and records each hit and
# each cw-host-stage.* directory it sees. The devcontainer target's stage
# (cw-devc-stage.*, declined in these tests) is left alone: that target still
# stages in $TMPDIR (decision 037).
tmpdir_writer() {
  (
    end=$((SECONDS + 20))
    while [ ! -e "$S/stop" ] && [ "$SECONDS" -lt "$end" ]; do
      compgen -G "$TMPDIR/cw-host-stage.*" >> "$S/helper.saw" || true
      while IFS= read -r -d '' v; do
        grep -qF "$2" "$v" && continue
        printf '%s\n' "$2" > "$v.t" && mv -f "$v.t" "$v" && echo "$v" >> "$S/helper.hits"
      done < <(find "$TMPDIR" -path "$TMPDIR/cw-devc-stage.*" -prune -o -name "$1" -type f -print0 2>/dev/null)
      sleep 0.01
    done
  ) &
}

@test "T80 the old side of the host review is not in \$TMPDIR: rewriting it there cannot hide a change (review P2-R3, SP1b)" {
  need_script; fake_repo
  run_pty 'n\ny\n' bash "$INSTALL"
  printf '#!/bin/bash\necho MALICIOUS-PAYLOAD\n' > "$ROOT/hooks/h.sh"
  printf 'guide v2 benign\n' > "$ROOT/guides/g.md"
  commit_all mal
  # SP1b rewrote $TMPDIR/cw-host-stage.*/installed/hooks/h.sh to the new
  # content, so the review showed no change to it.
  tmpdir_writer h.sh 'echo MALICIOUS-PAYLOAD'
  export TAMPER="touch '$S/stop'"
  run_pty_feed "$FEED_TAMPER" bash "$INSTALL"
  wait
  echo "$output"
  [ ! -s "$S/helper.saw" ]                            # no host stage in $TMPDIR
  [ ! -s "$S/helper.hits" ]
  [[ "$output" == *'+echo MALICIOUS-PAYLOAD'* ]]      # the change is shown
  [[ "$output" == *'Installed into'* ]]
  [ "$(cat "$CLAUDE_HOME_DIR/hooks/h.sh")" = "$(printf '#!/bin/bash\necho MALICIOUS-PAYLOAD')" ]
}

@test "T81 the host stage is not in \$TMPDIR: editing it there between archive and copy cannot alter what is installed (review P2-A1, SP1c)" {
  need_script; fake_repo
  seq 300 > "$ROOT/skills/a/big.md"; commit_all big   # a first-install entry over 200 lines
  tmpdir_writer SKILL.md 'MALICIOUS-SKILL'
  export TAMPER="touch '$S/stop'"
  run_pty_feed "$FEED_TAMPER" bash "$INSTALL"
  wait
  echo "$output"
  [ ! -s "$S/helper.saw" ]
  [ ! -s "$S/helper.hits" ]
  [[ "$output" == *'content not shown'*'it is skills at commit'* ]]
  [[ "$output" == *'Installed into'* ]]
  [ "$(cat "$CLAUDE_HOME_DIR/skills/a/SKILL.md")" = 'skill a' ]
}

@test "T82 a stale stage left under the destination is cleared; a planted .cw-stage link's target is untouched (review P2-R3)" {
  need_script; fake_repo
  mkdir -p "$CLAUDE_HOME_DIR/.cw-stage.OLD1/payload"; printf 'x\n' > "$CLAUDE_HOME_DIR/.cw-stage.OLD1/payload/f"
  mkdir -p "$S/elsewhere"; printf 'keep\n' > "$S/elsewhere/sentinel"
  ln -s "$S/elsewhere" "$CLAUDE_HOME_DIR/.cw-stage.LINK"
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" == *'Installed into'* ]]
  run ! compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*"
  [ "$(cat "$S/elsewhere/sentinel")" = keep ]
}

@test "T68 a reviewed copy under the destination edited while the prompt waits is refused (review R2)" {
  need_script; fake_repo; symlink_install
  before=$(snap "$CLAUDE_HOME_DIR")
  export TAMPER='printf "echo TAMPERED\n" >> "$CLAUDE_HOME_DIR/.cw-new.hooks/h.sh"'
  run_pty_feed "$FEED_TAMPER" bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'changed after review'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  [ -z "$(grep -rls TAMPERED "$CLAUDE_HOME_DIR")" ]
  run ! compgen -G "$CLAUDE_HOME_DIR/.cw-new.*"
  [ ! -e "$CLAUDE_HOME_DIR/.claude-workflows-lock" ]
}

@test "T29 rewriting install.sh while it waits at a prompt runs no new code (review R3)" {
  need_script; fake_repo
  # Insert a command right after the top-level line that calls into the first
  # prompt: bash resumes reading the file there once that call returns.
  L=$(grep -n -m1 -E '^(install_devcontainer$|main "\$@")' "$INSTALL" | cut -d: -f1)
  [ -n "$L" ]
  export INJECT_L="$L" INJECT_F="$INSTALL" PWN="$S/pwned"
  feed='for _i in $(seq 200); do [ -e "$(dirname "$INJECT_F")/claude-home/.manifest" ] && break; sleep 0.1; done
    sleep 2
    { head -n "$INJECT_L" "$INJECT_F"; echo "touch \"$PWN\""; tail -n +"$((INJECT_L + 1))" "$INJECT_F"; } > "$INJECT_F.new"
    cat "$INJECT_F.new" > "$INJECT_F"
    printf "n\nn\n"'
  run_pty_feed "$feed" bash "$INSTALL"
  echo "$output"
  [[ "$output" == *'Aborted. Nothing was changed. (devcontainer'* ]]
  [ ! -e "$S/pwned" ]
}

# A destination that already holds a copy install, and a committed repo change
# so the next y has something to replace.
installed_then_changed() {
  run_pty 'n\ny\n' bash "$INSTALL"
  [ -d "$CLAUDE_HOME_DIR/scripts" ] && [ ! -L "$CLAUDE_HOME_DIR/scripts" ]
  printf 'changed\n' >> "$ROOT/workflows/w.md"; commit_all change
}

@test "T30 a move-aside failure rolls every entry back and says so (review R4)" {
  need_script; [ "$(id -u)" -ne 0 ] || skip "root ignores the directory permission this relies on"
  fake_repo; installed_then_changed
  # Moving a directory to a new parent needs write permission on it ('..').
  # scripts is the last entry, so six have already moved when it fails.
  chmod a-w "$CLAUDE_HOME_DIR/scripts"
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  chmod u+w "$CLAUDE_HOME_DIR/scripts"
  [ "$status" -eq 1 ]
  [[ "$output" == *'rolled back'* ]]
  [[ "$output" == *'.claude-workflows-backup'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  [ -z "$(compgen -G "$CLAUDE_HOME_DIR/.cw-new.*")" ]
  [ ! -e "$CLAUDE_HOME_DIR/.claude-workflows-lock" ]
}

@test "T31 a held install lock is refused, named, and left alone (review R4)" {
  need_script; fake_repo; installed_then_changed
  mkdir "$CLAUDE_HOME_DIR/.claude-workflows-lock"
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"$CLAUDE_HOME_DIR/.claude-workflows-lock"* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
}

@test "T32 a successful install releases its lock" {
  need_script; fake_repo; installed_then_changed
  run_pty 'n\ny\n' bash "$INSTALL"
  [ "$status" -eq 1 ]   # the devcontainer target was declined
  grep -q changed "$CLAUDE_HOME_DIR/workflows/w.md"
  [ ! -e "$CLAUDE_HOME_DIR/.claude-workflows-lock" ]
}

@test "T33 a foreign hook link is labelled MOVE (not REPLACE), WIRED on its own line (review R5)" {
  need_script; fake_repo; symlink_install
  d="$CLAUDE_HOME_DIR"
  printf '#!/bin/bash\n' > "$S/theirs-target.sh"
  ln -s "$S/theirs-target.sh" "$d/hooks/theirs.sh"
  mkdir -p "$d/hooks/sub"; printf 'x\n' > "$d/hooks/sub/x.sh"; printf 'y\n' > "$d/hooks/sub/y.sh"
  printf '{"a":"bash ~/.claude/hooks/theirs.sh","b":"hooks/x.sh","c":"hooks/sub/y.sh"}\n' > "$d/settings.json"
  run_pty 'n\nn\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" != *"REPLACE symlink $d/hooks/theirs.sh"* ]]
  line=$(grep -F "$d/hooks/theirs.sh" <<<"$output" | head -1)
  [[ "$line" == "MOVE link $d/hooks/theirs.sh -> $S/theirs-target.sh to backup (not in the repo)"*'WIRED in settings'* ]]
  grep -F "$d/hooks/sub/y.sh" <<<"$output" | grep -q 'WIRED'
  [ -z "$(grep -F "$d/hooks/sub/x.sh" <<<"$output" | grep 'WIRED')" ]
  # A repo-backed link is still a REPLACE.
  [[ "$output" == *"REPLACE symlink $d/hooks/h.sh -> "* ]]
}

@test "T34 control bytes in the review diff are made visible, not sent raw (review A4)" {
  need_script; fake_repo; symlink_install
  printf 'visible\n\033[1A\033[2Khidden-line\n' > "$ROOT/hooks/evil.sh"; commit_all evil
  run_pty 'n\nn\n' bash "$INSTALL"
  echo "$output" | cat -v
  [[ "$output" != *$'\e'* ]]
  [[ "$output" == *'+^[[1A^[[2Khidden-line'* ]]
}

@test "T35 a dangling link in an owned dir is named as a MOVE, not a failed review (review A8)" {
  need_script; fake_repo; symlink_install
  d="$CLAUDE_HOME_DIR"
  ln -s "$S/no-such-target" "$d/hooks/dead.sh"
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" != *'could not diff'* ]]
  [[ "$output" == *"MOVE link $d/hooks/dead.sh -> $S/no-such-target to backup (not in the repo)"* ]]
  [ -f "$d/hooks/h.sh" ] && [ ! -L "$d/hooks/h.sh" ]        # the install went ahead
  bk=$(echo "$d"/.claude-workflows-backup/*)
  [ -L "$bk/hooks/dead.sh" ]
}

@test "T36 an entry the destination lacks is listed with a file count (review A7)" {
  need_script; fake_repo
  run_pty 'n\nn\n' bash "$INSTALL"
  echo "$output"
  d="$CLAUDE_HOME_DIR"
  [[ "$output" == *"ADD $d/hooks (new, 3 file(s)):"* ]]
  [[ "$output" == *'    hooks/lib/x.sh'* ]]
  [[ "$output" == *"ADD $d/CLAUDE.md (new, 1 file(s)):"* ]]
}

@test "T37 when nothing changed: (none), no prompt, no swap, no backup (review A6)" {
  need_script; fake_repo
  run_pty 'n\ny\n' bash "$INSTALL"
  [ -d "$CLAUDE_HOME_DIR/skills" ]
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" == *'(none'* ]]
  [[ "$output" != *'Install these files'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  [ ! -e "$CLAUDE_HOME_DIR/.claude-workflows-backup" ]
}

@test "T38 backups are capped at the last 3 installs, and the install says so (review A6)" {
  need_script; fake_repo; symlink_install
  for i in 1 2 3 4; do
    printf 'change %s\n' "$i" >> "$ROOT/workflows/w.md"; commit_all "c$i"
    run_pty 'n\ny\n' bash "$INSTALL"
    grep -q "change $i" "$CLAUDE_HOME_DIR/workflows/w.md"
    sleep 1   # distinct second-resolution stamps
  done
  echo "$output"
  [ "$(find "$CLAUDE_HOME_DIR/.claude-workflows-backup" -mindepth 1 -maxdepth 1 | wc -l)" -eq 3 ]
  [[ "$output" == *'2 most recent earlier'*'kept'* ]]
  # The oldest (the symlink-install backup) is the one pruned.
  [ -z "$(find "$CLAUDE_HOME_DIR/.claude-workflows-backup" -type l)" ]
}

@test "T39 a destination whose unresolved tail climbs back into the checkout is refused (review A3)" {
  need_script; fake_repo
  repo_before=$(snap "$ROOT")
  run_pty 'n\ny\n' env CLAUDE_HOME_DIR="$S/nx/../repo" bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'inside the repo checkout'* ]]
  [ "$(snap "$ROOT")" = "$repo_before" ]
  [ ! -e "$S/nx" ]
}

@test "T41 pruning keeps this run's backup and unstamped dirs, and orders by install stamp, not name (fact-check claim 22)" {
  need_script; fake_repo
  mkdir -p "$CLAUDE_HOME_DIR"; printf 'my own instructions\n' > "$CLAUDE_HOME_DIR/CLAUDE.md"
  bk="$CLAUDE_HOME_DIR/.claude-workflows-backup"
  # Three earlier installs whose names sort after today's stamp (a clock that
  # once ran ahead), stamped out of name order, plus a dir no install made.
  mkdir -p "$bk/20990101T000000Z" "$bk/20990102T000000Z" "$bk/20990103T000000Z" "$bk/20000101T000000Z"
  printf 'installed_epoch=4102444900\n' > "$bk/20990101T000000Z/.install-stamp"
  printf 'installed_epoch=4102444700\n' > "$bk/20990102T000000Z/.install-stamp"
  printf 'installed_epoch=4102444800\n' > "$bk/20990103T000000Z/.install-stamp"
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  cur=$(sed -n 's/^Previous entries moved to \(.*\) (delete it when satisfied)\.$/\1/p' <<<"$output")
  [ -n "$cur" ]
  [ "$(cat "$cur/CLAUDE.md")" = 'my own instructions' ]
  [ -d "$bk/20990101T000000Z" ] && [ -d "$bk/20990103T000000Z" ]
  [ ! -e "$bk/20990102T000000Z" ]          # the oldest by stamp, not by name
  [ -d "$bk/20000101T000000Z" ]            # no stamp: not made by an install
}

@test "T42 a committed mode change is reviewed and installed, not reported as (none) (fact-check claim 17)" {
  need_script; fake_repo
  run_pty 'n\ny\n' bash "$INSTALL"
  [ -f "$CLAUDE_HOME_DIR/hooks/h.sh" ] && [ ! -x "$CLAUDE_HOME_DIR/hooks/h.sh" ]
  chmod +x "$ROOT/hooks/h.sh"; commit_all chmod
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" == *"MODE $CLAUDE_HOME_DIR/hooks/h.sh: 644 -> 755"* ]]
  [[ "$output" != *'(none'* ]]
  [ -x "$CLAUDE_HOME_DIR/hooks/h.sh" ]
  [ "$(stat -c %a "$CLAUDE_HOME_DIR/hooks/h.sh")" = 755 ]
}

@test "T43 a provenance manifest edited while the prompt waits is not installed (fact-check claim 14)" {
  need_script; fake_repo; symlink_install
  before=$(snap "$CLAUDE_HOME_DIR")
  # The reviewed copy of the manifest (review R2: the stage is no longer
  # installed, so the copy under the destination is what could be forged).
  export TAMPER='printf "commit=FORGED\n" > "$CLAUDE_HOME_DIR/.cw-new.manifest"'
  run_pty_feed "$FEED_TAMPER" bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'changed after review'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  [ -z "$(grep -rls FORGED "$CLAUDE_HOME_DIR")" ]
  ! compgen -G "$CLAUDE_HOME_DIR/.cw-new.*" >/dev/null
}

@test "T44 the devcontainer target installs committed config only and lists what it leaves out (fact-check claim 4)" {
  fake_repo
  cfg="$ROOT/devcontainer-config"
  printf 'UNCOMMITTED-EDIT\n' >> "$cfg/devcontainer.json"
  printf 'evil.example.com\n' > "$cfg/egress/new.txt"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *'NOT included'* ]]
  [[ "$output" == *'devcontainer-config/devcontainer.json'* ]]
  [[ "$output" == *'devcontainer-config/egress/new.txt'* ]]
  [ "$(cat "$CLAUDE_DEVC_CONFIG_DIR/devcontainer.json")" = 'stub devcontainer.json' ]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/egress/new.txt" ]
  [ -f "$CLAUDE_DEVC_CONFIG_DIR/egress/base.txt" ]
  [ -x "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ]
}

@test "T45 a devcontainer payload item missing from the commit is fatal before the prompt (fact-check claim 4)" {
  fake_repo
  rm "$ROOT/devcontainer-config/Dockerfile"; commit_all drop
  printf 'stub Dockerfile\n' > "$ROOT/devcontainer-config/Dockerfile"   # in the tree, not the commit
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'not found in commit'*'devcontainer-config/Dockerfile'* ]]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR" ]
}

@test "T46 a destination containing a newline is refused before anything runs (fact-check claim 11b)" {
  need_script; fake_repo
  repo_before=$(snap "$ROOT")
  # Once mkdir -p makes "nl<LF>", this path lands in the checkout; the first-line
  # split in resolve_phys saw only ".../out/nl" and let it through.
  export CLAUDE_HOME_DIR="$S/out/nl"$'\n'"/../../repo"
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'control character'* ]]
  [[ "$output" != *'[y/N]'* ]]
  [ ! -e "$S/out" ]
  [ ! -e "$ROOT/devcontainer-config/claude-home" ]
  [ "$(snap "$ROOT")" = "$repo_before" ]
}

@test "T47 a raw 8-bit C1 byte is made visible; valid UTF-8 is left alone (fact-check claim 6)" {
  need_script; fake_repo; symlink_install
  printf 'a\23331mX\nem \342\200\224 dash\n' > "$ROOT/hooks/c1.sh"; commit_all c1
  run_pty 'n\nn\n' bash "$INSTALL"
  echo "$output" | cat -v
  [ "$(printf '%s' "$output" | LC_ALL=C grep -c $'\x9b')" -eq 0 ]
  [[ "$output" == *'+a?31mX'* ]]
  [[ "$output" == *$'+em \342\200\224 dash'* ]]
}

@test "T48 the uncommitted-changes listing never prints a control byte raw, even with core.quotePath=false (fact-check claim 9)" {
  fake_repo
  git -C "$ROOT" config core.quotePath false
  printf 'x\n' > "$ROOT/skills/a/evil"$'\xc2\x9b'"31mred.md"
  run env -u CLAUDECODE bash "$INSTALL" </dev/null
  echo "$output" | cat -v
  [[ "$output" == *'NOT included'*'31mred.md'* ]]
  [ "$(printf '%s' "$output" | LC_ALL=C grep -c $'\xc2\x9b')" -eq 0 ]
}

@test "T49 a small new entry's content is shown; a large one says it is omitted (fact-check claim 3)" {
  need_script; fake_repo
  seq 1 300 | sed 's/^/line /' > "$ROOT/workflows/big.md"; commit_all big
  run_pty 'n\nn\n' bash "$INSTALL"
  echo "$output"
  d="$CLAUDE_HOME_DIR"
  [[ "$output" == *"ADD $d/CLAUDE.md (new, 1 file(s)):"*'+global instructions'* ]]
  [[ "$output" == *"ADD $d/hooks (new, 3 file(s)):"*'+exit 0'* ]]
  [[ "$output" == *"ADD $d/workflows (new, 2 file(s)):"*'content not shown: 301 lines'* ]]
  [[ "$output" != *'+line 150'* ]]
}

@test "T50 a Claude Code process for this user stops the install before either target stages (Q-058)" {
  need_script; fake_repo; symlink_install
  stub_pgrep 'echo "4242 node /usr/local/bin/claude --resume"; exit 0'
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'y\ny\n' bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'4242 node /usr/local/bin/claude --resume'* ]]
  [[ "$output" == *'Claude Code'* ]]
  [[ "$output" != *'[y/N]'* ]]
  [[ "$output" != *'Canonical'* ]]
  [ ! -e "$ROOT/devcontainer-config/claude-home" ]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR" ]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  # It asked about this user's processes, by full command line.
  grep -q -- "pgrep -u $(id -u) -af" "$S/probe.log"
}

@test "T51 a running cc-isolated container stops the install and is named with how to stop it (Q-058)" {
  fake_repo
  stub_docker 'case "$*" in *label=cc-project*) echo "brave_turing cc-project=0123456789ab";; esac; exit 0'
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'brave_turing cc-project=0123456789ab'* ]]
  [[ "$output" == *'docker stop'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$ROOT/devcontainer-config/claude-home" ]
  grep -q 'docker ps --filter label=cc-project' "$S/probe.log"
}

@test "T52 docker absent or unreachable: a NOTE line says so at each check, and the install goes ahead (Q-058)" {
  fake_repo
  stub_docker 'echo "Cannot connect to the Docker daemon" >&2; exit 1'
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *'Checking for running cc-isolated containers'*'docker is unreachable'*'treated as none running'* ]]
  [[ "$output" == *'BLESS-STUB --bless'* ]]
  p=$(path_without docker)
  run env -u CLAUDECODE PATH="$p" bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *'docker not found'*'treated as none running'* ]]
}

@test "T64 a docker warning on stderr with no containers listed is not a running container (Q-058)" {
  # Regression: the container list was read with 2>&1, so any stderr noise (a
  # locale warning from the shell, a CLI deprecation notice) refused every install.
  fake_repo
  stub_docker 'echo "WARNING: some docker CLI notice" >&2; exit 0'
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" != *'an agent is running'* ]]
  [[ "$output" == *'BLESS-STUB --bless'* ]]
}

@test "T53 without pgrep the install is refused, not waved through (Q-058)" {
  fake_repo
  p=$(path_without pgrep)
  run env -u CLAUDECODE PATH="$p" bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'pgrep'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$ROOT/devcontainer-config/claude-home" ]
}

@test "T54 an agent that starts while the host prompt waits stops the swap (Q-058)" {
  need_script; fake_repo; symlink_install
  stub_pgrep "[ -e '$S/agent-up' ] || exit 1; echo '777 claude'; exit 0"
  before=$(snap "$CLAUDE_HOME_DIR")
  export TAMPER="touch '$S/agent-up'"
  run_pty_feed "$FEED_TAMPER" bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'Install these files'* ]]      # the review and prompt ran
  [[ "$output" == *'777 claude'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  run ! compgen -G "$CLAUDE_HOME_DIR/.cw-new.*"
  [ ! -e "$CLAUDE_HOME_DIR/.claude-workflows-lock" ]
}

@test "T55 an agent that starts while the devcontainer prompt waits stops that install (Q-058)" {
  need_script; fake_repo
  stub_pgrep "[ -e '$S/agent-up' ] || exit 1; echo '778 claude'; exit 0"
  feed="for _i in \$(seq 200); do [ -e '$ROOT/devcontainer-config/claude-home/.manifest' ] && break; sleep 0.1; done
    sleep 1; touch '$S/agent-up'; printf 'y\ny\n'"
  run_pty_feed "$feed" bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'778 claude'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR" ]
}

@test "T56 --help, README and the hook-wiring guide document the no-agent check (Q-058)" {
  fake_repo
  run bash "$INSTALL" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *'Claude Code process'* ]]
  [[ "$output" == *'cc-isolated container'* ]]
  # Review A4: an in-session run is refused at startup, not "target 1 installs".
  [[ "$output" == *'Claude Code session, install.sh finds that session and exits 1 at startup'* ]]
  grep -q 'exits 1 at startup' "$BATS_TEST_DIRNAME/../README.md"
  # Review P2-A4, P2-A5: the git-state refusal and the unwritable destination.
  [[ "$output" == *'filter.*, core.fsmonitor, include* or hook.*'* ]]
  [[ "$output" == *'not writable is refused before the review, with exit 1'* ]]
  grep -q -- '--unset-all' "$BATS_TEST_DIRNAME/../README.md"
  grep -q 'unwritable destination is refused before the review' "$BATS_TEST_DIRNAME/../README.md"
  for doc in README.md guides/bare-host-hook-wiring.md; do
    grep -q 'Q-058' "$BATS_TEST_DIRNAME/../$doc"
    grep -q 'cc-isolated container' "$BATS_TEST_DIRNAME/../$doc"
  done
}

@test "T57 without perl the install is refused at startup (vis needs it)" {
  fake_repo
  p=$(path_without perl)
  run env -u CLAUDECODE PATH="$p" bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'perl'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$ROOT/devcontainer-config/claude-home" ]
}

@test "T58 a vis failure is diff trouble: it aborts before the prompt, never reads as an empty diff" {
  fake_repo
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  [ "$status" -eq 0 ]
  printf '{"changed":1}\n' > "$ROOT/devcontainer-config/devcontainer.json"; commit_all dc
  # Only vis (`perl -pe`) fails; the payload's NUL scan still runs real perl.
  printf '#!/bin/bash\ncase "$1" in -pe) cat >/dev/null; exit 1 ;; esac\nexec %s "$@"\n' \
    "$(command -v perl)" > "$STUB/perl"
  chmod +x "$STUB/perl"
  run env -u CLAUDECODE bash "$INSTALL" </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'could not show the review'* ]]
  [[ "$output" != *'bless it?'* ]]
  [ "$(cat "$CLAUDE_DEVC_CONFIG_DIR/devcontainer.json")" = 'stub devcontainer.json' ]
}

@test "T59 a symlink planted at devcontainer-config/claude-home is refused, its target untouched" {
  fake_repo
  mkdir -p "$S/elsewhere"; printf 'keep\n' > "$S/elsewhere/sentinel"
  ln -s "$S/elsewhere" "$ROOT/devcontainer-config/claude-home"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'claude-home'*'symlink'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ -L "$ROOT/devcontainer-config/claude-home" ]
  [ "$(ls -A "$S/elsewhere")" = sentinel ]
  [ "$(cat "$S/elsewhere/sentinel")" = keep ]
}

@test "T60 a symlinked directory above claude-home inside the repo is refused" {
  fake_repo
  mv "$ROOT/devcontainer-config" "$S/realdc"
  ln -s "$S/realdc" "$ROOT/devcontainer-config"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'symlink'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$S/realdc/claude-home" ]
}

@test "T61 a committed payload file holding a NUL byte is refused and listed before any prompt" {
  need_script; fake_repo; symlink_install
  printf 'looks\0binary\n' > "$ROOT/hooks/blob.bin"
  printf 'dc\0bin\n' > "$ROOT/devcontainer-config/egress/x.bin"; commit_all bin
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'y\ny\n' bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'NUL'*'hooks/blob.bin'* ]]
  [[ "$output" != *'Binary files'* ]]
  [[ "$output" != *'[y/N]'* ]]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR" ]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  # The devcontainer payload is checked the same way.
  git -C "$ROOT" rm -q hooks/blob.bin; commit_all rm
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'NUL'*'egress/x.bin'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
}

@test "T62 an installed file holding a NUL byte is reviewed as text, not 'Binary files differ'" {
  need_script; fake_repo
  run_pty 'n\ny\n' bash "$INSTALL"
  [ -f "$CLAUDE_HOME_DIR/hooks/h.sh" ]
  printf 'bad\0byte\n' > "$CLAUDE_HOME_DIR/hooks/h.sh"
  run_pty 'n\nn\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" != *'Binary files'* ]]
  [[ "$output" == *'-bad?byte'* ]]
  [[ "$output" == *'+exit 0'* ]]
}

@test "T63 decision 037 records the Q-058 trust model and its accepted residuals; the plan's Risks cite it" {
  d="$BATS_TEST_DIRNAME/../docs/decisions/037-bare-host-copy-install.md"
  plan="$BATS_TEST_DIRNAME/../docs/working/plan-copy-install-bare-host.md"
  grep -q '^## Trust model (Q-058)' "$d"
  sec=$(sed -n '/^## Trust model (Q-058)/,/^## /p' "$d")
  [[ "$sec" == *"user's uid"* ]]
  [[ "$sec" == *'code-review-rubric-2026-09-23-ans-copy-install-final.md'* ]]
  for residual in 'TAB' '.git/config' 'another host' 'renamed'; do
    [[ "$sec" == *"$residual"* ]]
  done
  sed -n '/^## Risks/,/^## /p' "$plan" | grep -q 'Q-058'
}

@test "T69 a devcontainer stage edited while its prompt waits is neither installed nor blessed (review A1, P3)" {
  need_script; fake_repo
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  [ "$status" -eq 0 ]
  printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"; commit_all v2
  feed="for _i in \$(seq 200); do [ -e '$ROOT/devcontainer-config/claude-home/.manifest' ] && break; sleep 0.1; done
    sleep 1; for f in \"\$TMPDIR\"/cw-devc-stage.*/config/devcontainer.json; do printf 'TAMPERED\n' > \"\$f\"; done; printf 'y\nn\n'"
  run_pty_feed "$feed" bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'+{"v":2}'* ]]                  # the review showed the commit
  [[ "$output" == *'changed after review'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ "$(cat "$CLAUDE_DEVC_CONFIG_DIR/devcontainer.json")" = 'stub devcontainer.json' ]
  [ -z "$(grep -rls TAMPERED "$CLAUDE_DEVC_CONFIG_DIR")" ]
}

@test "T70 a devcontainer file that differs once copied into place is removed, not blessed (review A1)" {
  fake_repo
  # A cp that alters devcontainer.json as it lands in the destination: the
  # stage changing during the copy loop, after the pre-copy check.
  printf '#!/bin/bash\n%s "$@" || exit\ncase "${@: -1}" in */claude-devcontainer/devcontainer.json) echo TAMPERED >> "${@: -1}";; esac\n' \
    "$(command -v cp)" > "$STUB/cp"
  chmod +x "$STUB/cp"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'differs from what the review'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/devcontainer.json" ]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ]
}

# stub_pgrep_table: a pgrep that applies the pattern install.sh passes (its last
# argument) to the command lines in $S/ps.txt ("PID command line" per line), as
# `pgrep -af` does, and prints the matching lines.
stub_pgrep_table() {
  stub_pgrep "pat=\"\${*: -1}\"; rc=1
while IFS= read -r l; do printf '%s\\n' \"\${l#* }\" | grep -qE -- \"\$pat\" && { echo \"\$l\"; rc=0; }; done < '$S/ps.txt'
exit \$rc"
}

@test "T71 the gate recognises the versioned native binary and the Agent SDK CLI; other processes pass (review A2)" {
  fake_repo
  stub_pgrep_table
  others=$'5001 bash ralph-loop.sh\n5002 vim notes.md\n5003 node cli.js'
  for agent in '4243 /home/u/.local/share/claude/versions/2.1.3 --resume' \
               '4244 node /x/node_modules/@anthropic-ai/claude-agent-sdk/cli.js' \
               '4245 claude --resume' \
               '4246 node /usr/lib/node_modules/@anthropic-ai/claude-code/cli.js'; do
    printf '%s\n%s\n' "$others" "$agent" > "$S/ps.txt"
    run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
    echo "$output"
    [ "$status" -eq 1 ]
    [[ "$output" == *"$agent"* ]]
    [[ "$output" != *'5001'* ]]
    [[ "$output" != *'BLESS-STUB'* ]]
  done
  # Documented residuals (decision 037): not Claude-shaped, so not refused.
  printf '%s\n' "$others" > "$S/ps.txt"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *'BLESS-STUB --bless'* ]]
}

@test "T72 an agent seen only while the devcontainer prompt waits stops the host target before it stages (review A2, P4)" {
  need_script; fake_repo
  stub_pgrep "[ -e '$S/agent-up' ] && [ ! -e '$S/agent-down' ] || exit 1; echo '779 claude'; exit 0"
  # No fixed sleeps (review P2-C3). The mirror exists only after the startup
  # check (pgrep call 1) passed; the agent is visible until the host target's
  # pre-stage check (pgrep call 2) has run.
  feed="for _i in \$(seq 200); do [ -e '$ROOT/devcontainer-config/claude-home/.manifest' ] && break; sleep 0.1; done
    touch '$S/agent-up'; printf 'n\n'
    for _i in \$(seq 200); do [ \"\$(grep -c '^pgrep' '$S/probe.log')\" -ge 2 ] && break; sleep 0.05; done
    touch '$S/agent-down'; printf 'y\n'"
  run_pty_feed "$feed" bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'779 claude'* ]]
  [[ "$output" == *'Nothing was installed into the host target.'* ]]
  [[ "$output" != *'Install these files'* ]]
  [ ! -e "$CLAUDE_HOME_DIR" ]
  no_host_stage_left
}

@test "T73 a TAB-named backup dir planted before the run is skipped by the prune; kept backups stay (review A3, P5)" {
  need_script; fake_repo; symlink_install
  bk="$CLAUDE_HOME_DIR/.claude-workflows-backup"
  tabbed="$bk/20200101T000000Z"$'\t'junk
  mkdir -p "$bk/20200101T000000Z" "$bk/20200102T000000Z" "$tabbed"
  printf 'installed_epoch=200\n' > "$bk/20200101T000000Z/.install-stamp"
  printf 'installed_epoch=300\n' > "$bk/20200102T000000Z/.install-stamp"
  printf 'installed_epoch=100\n' > "$tabbed/.install-stamp"
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" == *'Installed into'* ]]
  # This run's backup plus the two most recent earlier ones are kept; the
  # TAB-named dir is never a prune candidate (nor a split one).
  [ -d "$bk/20200101T000000Z" ]
  [ -d "$bk/20200102T000000Z" ]
  [ -d "$tabbed" ]
}

@test "T74 a vis failure outside the review diff says so and installs nothing (review C3)" {
  need_script; fake_repo; symlink_install
  before=$(snap "$CLAUDE_HOME_DIR")
  # Only vis (`perl -pe`) fails; the first host line through it is a REPLACE.
  printf '#!/bin/bash\ncase "$1" in -pe) cat >/dev/null; exit 1 ;; esac\nexec %s "$@"\n' \
    "$(command -v perl)" > "$STUB/perl"
  chmod +x "$STUB/perl"
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'could not show output safely'*'Nothing was installed.'* ]]
  [[ "$output" != *'Install these files'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  run ! compgen -G "$CLAUDE_HOME_DIR/.cw-new.*"
  [ ! -e "$CLAUDE_HOME_DIR/.claude-workflows-lock" ]
}

@test "T83 a cp failure in the devcontainer copy loop removes what was copied; no altered launcher stays live (review P2-A2, A1b)" {
  fake_repo
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  [ "$status" -eq 0 ]
  printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"; commit_all v2
  # cc-isolated.sh changes as it lands, then the later egress copy fails.
  printf '#!/bin/bash\ncase "${@: -1}" in */claude-devcontainer/egress) exit 1;; esac\n%s "$@" || exit\ncase "${@: -1}" in */claude-devcontainer/cc-isolated.sh) echo "echo TAMPERED-LAUNCHER" >> "${@: -1}";; esac\n' \
    "$(command -v cp)" > "$STUB/cp"
  chmod +x "$STUB/cp"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'could not copy'*'removed again'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ]
  [ -z "$(grep -rls TAMPERED-LAUNCHER "$CLAUDE_DEVC_CONFIG_DIR" 2>/dev/null)" ]
}

# Marker command: git runs it only if it obeys the planted config.
plant_marker_cmd() {
  printf '#!/bin/bash\ntouch "%s/%s"\ncat\n' "$S" "$1" > "$S/$1.sh"
  chmod +x "$S/$1.sh"
}

@test "T65 a smudge filter planted in .git/config and .git/info/attributes is refused and never run (review R1)" {
  fake_repo
  plant_marker_cmd smudge-ran
  git -C "$ROOT" config filter.pwn.smudge "$S/smudge-ran.sh"
  printf '*.md filter=pwn\n' > "$ROOT/.git/info/attributes"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'filter.pwn.smudge'* ]]
  [[ "$output" == *'info/attributes'*'*.md filter=pwn'* ]]
  [[ "$output" == *'--unset-all <key>'*'filter.lfs'* ]]      # review P2-A4
  [[ "$output" == *'Nothing was installed.'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$S/smudge-ran" ]
  [ ! -e "$ROOT/devcontainer-config/claude-home" ]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR" ]
  # A non-empty attributes file alone is refused too.
  git -C "$ROOT" config --unset filter.pwn.smudge
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *'info/attributes'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
}

@test "T66 core.fsmonitor or an include in .git/config is refused and never run, also from a linked worktree (review R1)" {
  fake_repo
  git -C "$ROOT" worktree add -q "$S/wt" 2>/dev/null
  plant_marker_cmd fsmonitor-ran
  git -C "$ROOT" config core.fsmonitor "$S/fsmonitor-ran.sh"
  for inst in "$INSTALL" "$S/wt/devcontainer-config/install.sh"; do
    run env -u CLAUDECODE bash "$inst" --yes </dev/null
    echo "$output"
    [ "$status" -eq 1 ]
    [[ "$output" == *'core.fsmonitor'* ]]
    [[ "$output" != *'BLESS-STUB'* ]]
  done
  [ ! -e "$S/fsmonitor-ran" ]
  git -C "$ROOT" config --unset core.fsmonitor
  printf '[core]\n\tfsmonitor = %s\n' "$S/fsmonitor-ran.sh" > "$S/inc.cfg"
  git -C "$ROOT" config include.path "$S/inc.cfg"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'include.path'* ]]
  [ ! -e "$S/fsmonitor-ran" ]
  # The worktree's attributes are the common dir's, though its .git is a file.
  git -C "$ROOT" config --unset include.path
  printf '* filter=x\n' > "$ROOT/.git/info/attributes"
  run env -u CLAUDECODE bash "$S/wt/devcontainer-config/install.sh" --yes </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *'info/attributes'* ]]
}

@test "T75 a planted .git/hooks hook and a core.hooksPath hook never run; the install proceeds (review P2-R1, SP3b/SP3c)" {
  fake_repo
  printf '#!/bin/sh\ntouch "%s/hook-ran"\n' "$S" > "$ROOT/.git/hooks/post-index-change"
  chmod +x "$ROOT/.git/hooks/post-index-change"
  mkdir -p "$S/hk"
  printf '#!/bin/sh\ntouch "%s/hookspath-ran"\n' "$S" > "$S/hk/post-index-change"
  chmod +x "$S/hk/post-index-change"
  for how in default hookspath; do
    [ "$how" = hookspath ] && git -C "$ROOT" config core.hooksPath "$S/hk"
    # Stat-dirty but content-clean: a status that refreshes the index rewrites
    # it, and writing the index runs post-index-change.
    touch -d '2001-01-01' "$ROOT/skills/a/SKILL.md"
    run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *'BLESS-STUB --bless'* ]]
  done
  [ ! -e "$S/hook-ran" ]
  [ ! -e "$S/hookspath-ran" ]
  # The same hook does run under a plain git status (the test can see it).
  git -C "$ROOT" config --unset core.hooksPath
  touch -d '2002-01-01' "$ROOT/skills/a/SKILL.md"
  git -C "$ROOT" status --porcelain >/dev/null
  [ -e "$S/hook-ran" ]
}

@test "T76 a submodule's own filter and hook never run; the install proceeds (review P2-R1, SP3d)" {
  fake_repo
  git init -q "$S/sub"; printf 's\n' > "$S/sub/s.txt"
  git -C "$S/sub" add .; git -C "$S/sub" -c user.email=t@t -c user.name=t commit -qm s
  git -C "$ROOT" -c protocol.file.allow=always submodule add -q "$S/sub" skills/sub 2>/dev/null
  commit_all sub
  plant_marker_cmd sub-clean-ran
  md="$ROOT/.git/modules/skills/sub"
  git -C "$ROOT/skills/sub" config filter.pwn.clean "$S/sub-clean-ran.sh"
  printf '* filter=pwn\n' > "$md/info/attributes"
  printf '#!/bin/sh\ntouch "%s/sub-hook-ran"\n' "$S" > "$md/hooks/post-index-change"
  chmod +x "$md/hooks/post-index-change"
  touch -d '2001-01-01' "$ROOT/skills/sub/s.txt"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *'BLESS-STUB --bless'* ]]
  [ ! -e "$S/sub-clean-ran" ]
  [ ! -e "$S/sub-hook-ran" ]
}

# stub_cp_then <case-pattern> <shell>: a cp that runs the real cp, then, when
# its last argument matches the pattern, runs the shell snippet ($dst is that
# argument, $srcarg the one before it). Stands in for a writer acting at that
# exact moment, which the review probes had to race for.
stub_cp_then() {
  printf '#!/bin/bash\n%s "$@" || exit\ndst="${@: -1}"; srcarg="${@: -2:1}"\ncase "$dst" in %s) %s ;; esac\nexit 0\n' \
    "$(command -v cp)" "$1" "$2" > "$STUB/cp"
  chmod +x "$STUB/cp"
}

@test "T77 a symlink that appears in the host copies after the payload link check is refused, not installed (review P2-R2, SP1d)" {
  need_script; fake_repo; symlink_install
  printf '#!/bin/bash\nexit 0\n' > "$S/agent-writable.sh"
  stub_cp_then '*/.cw-new.hooks' "ln -sfn '$S/agent-writable.sh' \"\$dst/h.sh\""
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'symlink'*'.cw-new.hooks/h.sh'* ]]
  [[ "$output" != *'Install these files'* ]]
  [[ "$output" != *'Installed into'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  run ! compgen -G "$CLAUDE_HOME_DIR/.cw-new.*"
}

@test "T78 a cc-isolated.sh symlink planted in the devcontainer stage after the link check is refused before the review (review P2-R2, SP1e)" {
  fake_repo
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$S/agent-writable-cc.sh"
  chmod +x "$S/agent-writable-cc.sh"
  # The checkout mirror rebuild runs after extract_commit's check and before
  # the pre-review hash: plant the link in the stage then.
  stub_cp_then '*/claude-home/' "ln -sfn '$S/agent-writable-cc.sh' \"\${srcarg%/claude-home/.}/cc-isolated.sh\""
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'symlink'*'cc-isolated.sh'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ]
}

@test "T79 a symlink that lands in the devcontainer destination is removed and named, not blessed (review P2-R2)" {
  fake_repo
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$S/agent-writable-cc.sh"
  stub_cp_then '*/claude-devcontainer/cc-isolated.sh' "ln -sfn '$S/agent-writable-cc.sh' \"\$dst\""
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'symlink'*'cc-isolated.sh'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ] && [ ! -L "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ]
}

@test "T24 with CLAUDE_HOME_DIR unset, CLAUDE_CONFIG_DIR chooses the destination" {
  need_script; fake_repo
  run_pty 'n\ny\n' env -u CLAUDE_HOME_DIR CLAUDE_CONFIG_DIR="$S/cfgdir" bash "$INSTALL"
  echo "$output"
  [ -d "$S/cfgdir/skills" ] && [ ! -L "$S/cfgdir/skills" ]
  [ ! -e "$HOME/.claude" ]
  [[ "$output" == *'CLAUDE_CONFIG_DIR'* ]]
}

@test "T84 a config-based hook (hook.*) in .git/config is refused and never run (review pass 3)" {
  fake_repo
  plant_marker_cmd hook-ran
  git -C "$ROOT" config hook.pwn.command "$S/hook-ran.sh"
  git -C "$ROOT" config hook.pwn.event post-index-change
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'hook.pwn.command'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$S/hook-ran" ]
}

@test "T85 a PAYLOAD item missing from DEST after the copy unwinds with a message; no altered launcher stays live (review pass 3, links_in)" {
  fake_repo
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  [ "$status" -eq 0 ]
  printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"; commit_all v2
  # cc-isolated.sh changes as it lands; claude-home, the last item, is removed
  # right after its copy, so the post-copy symlink check meets a missing item.
  printf '#!/bin/bash\n%s "$@" || exit\ncase "${@: -1}" in */claude-devcontainer/cc-isolated.sh) echo "echo TAMPERED-LAUNCHER" >> "${@: -1}";; */claude-devcontainer/claude-home) rm -rf "${@: -1}";; esac\n' \
    "$(command -v cp)" > "$STUB/cp"
  chmod +x "$STUB/cp"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'ERROR:'*'removed again'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ]
  [ -z "$(grep -rls TAMPERED-LAUNCHER "$CLAUDE_DEVC_CONFIG_DIR" 2>/dev/null)" ]
}

@test "T86 dc_unwind removes the launcher even when another copied item cannot be removed (review pass 4, F1)" {
  fake_repo
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  [ "$status" -eq 0 ]
  printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"; commit_all v2
  # Dockerfile lands as a tree with a read-only subdir (so a plain rm -rf
  # fails), and cc-isolated.sh changes as it lands: the hash then mismatches.
  printf '#!/bin/bash\n%s "$@" || exit\nd="${@: -1}"\ncase "$d" in */claude-devcontainer/Dockerfile) rm -f "$d"; mkdir -p "$d/sub"; touch "$d/sub/f"; chmod 555 "$d/sub";; */claude-devcontainer/cc-isolated.sh) echo "echo TAMPERED-LAUNCHER" >> "$d";; esac\n' \
    "$(command -v cp)" > "$STUB/cp"
  chmod +x "$STUB/cp"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  chmod -R u+w "$CLAUDE_DEVC_CONFIG_DIR" 2>/dev/null || true
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'ERROR:'*'removed again'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/Dockerfile" ]
  [ -z "$(grep -rls TAMPERED-LAUNCHER "$CLAUDE_DEVC_CONFIG_DIR" 2>/dev/null)" ]
}

@test "T87 a leftover copy with a read-only subdir from a killed run is cleared, and the install proceeds (review pass 4)" {
  need_script; fake_repo
  mkdir -p "$CLAUDE_HOME_DIR/.cw-new.skills/sub"; printf 'x\n' > "$CLAUDE_HOME_DIR/.cw-new.skills/sub/f"
  chmod 555 "$CLAUDE_HOME_DIR/.cw-new.skills/sub"
  run_pty 'n\ny\n' bash "$INSTALL"
  chmod -R u+w "$CLAUDE_HOME_DIR" 2>/dev/null || true
  echo "$output"
  [[ "$output" == *'Installed into'* ]]
  run ! compgen -G "$CLAUDE_HOME_DIR/.cw-new.*"
  [ ! -e "$CLAUDE_HOME_DIR/skills/skills" ]
}

# --- Q-062 [2]: a non-Claude process working inside the checkout is an agent ---

@test "T88 a leftover non-Claude process working inside the checkout stops the install and is named (Q-062)" {
  fake_repo
  # A helper an agent left behind: no Claude command line, cwd in the repo.
  # fd 3 is closed so bats does not wait on it.
  (cd "$ROOT/skills" && exec sleep 300) >/dev/null 2>&1 3>&- &
  helper=$!
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  kill "$helper" 2>/dev/null || true
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"$helper sleep 300"* ]]
  [[ "$output" == *'working inside'*'Q-062'* ]]
  # Only an in-checkout process was found, so the lead line does not claim an agent.
  [[ "$output" == *'a process may be acting for an agent'* ]]
  [[ "$output" != *'an agent is running'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$ROOT/devcontainer-config/claude-home" ]
  # Once it has gone, the same run installs.
  wait "$helper" 2>/dev/null || true
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *'BLESS-STUB --bless'* ]]
}

@test "T89 the shell that runs install.sh from inside the checkout, and install.sh's own children, are not refused (Q-062)" {
  fake_repo
  run env -u CLAUDECODE bash -c 'cd "$1" && bash devcontainer-config/install.sh --yes </dev/null' _ "$ROOT"
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" != *'working inside'* ]]
  [[ "$output" == *'BLESS-STUB --bless'* ]]
}

@test "T90 without a mounted /proc the install is refused, not waved through (Q-062)" {
  fake_repo
  # Run the gate's /proc probe against a path that does not exist: the copy
  # under test is edited so /proc/self reads as absent.
  sed -i 's|\[ -d /proc/self \] \|\| return 2|[ -d /nonexistent/self ] \|\| return 2|' "$INSTALL"
  grep -q '/nonexistent/self' "$INSTALL"
  commit_all noproc
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'/proc is not mounted'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
}

@test "T91 a blind /proc scan (no cwd readable) refuses, naming the processes it could not place (Q-064 [2])" {
  fake_repo
  # Point every cwd read at a link that does not exist, as an LSM hiding /proc would.
  sed -i 's|readlink "\$d/cwd"|readlink "\$d/cwd-hidden"|' "$INSTALL"
  grep -q 'cwd-hidden' "$INSTALL"
  commit_all blind
  (exec sleep 300) >/dev/null 2>&1 3>&- &
  local other=$!
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  kill "$other" 2>/dev/null || true
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'working directory cannot be read'*'Q-064'* ]]
  [[ "$output" == *"$other sleep 300"* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
}

@test "T92 a same-uid process that hides its cwd (non-dumpable) is refused and named, wherever it works (Q-064 [2])" {
  fake_repo
  python3 -c 'import ctypes' 2>/dev/null || skip "python3 ctypes unavailable"
  # prctl(PR_SET_DUMPABLE=4, 0) makes /proc/<pid>/cwd unreadable to the same uid.
  (cd "$S" && exec python3 -c 'import ctypes, time; ctypes.CDLL(None).prctl(4, 0, 0, 0, 0); time.sleep(300)') \
    >/dev/null 2>&1 3>&- &
  local hidden=$!
  for _i in $(seq 50); do readlink "/proc/$hidden/cwd" >/dev/null 2>&1 || break; sleep 0.1; done
  ! readlink "/proc/$hidden/cwd" >/dev/null 2>&1 || { kill "$hidden"; skip "prctl did not hide the cwd here"; }
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  kill "$hidden" 2>/dev/null || true
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"$hidden python3 -c"* ]]
  [[ "$output" == *'working directory cannot be read'* ]]
  [[ "$output" != *'BLESS-STUB'* ]]
}
