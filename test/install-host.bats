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
# host stage, give the review time to finish, run $TAMPER, then answer y.
FEED_TAMPER='printf "n\n"
  for _i in $(seq 200); do compgen -G "$TMPDIR/cw-host-stage.*/payload/.manifest" >/dev/null && break; sleep 0.1; done
  sleep 2; eval "$TAMPER"; printf "y\n"'

no_host_stage_left() {
  ! compgen -G "$TMPDIR/cw-host-stage.*" >/dev/null
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
  cp -R "$CONFIG_SRC/../hooks" "$ROOT/hooks"
  cp -R "$CONFIG_SRC/../scripts" "$ROOT/scripts"
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
  grep -q '^installed_by=host-tty$' "$m"
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
  [[ "$output" == *'nothing was replaced'* ]]   # it got past the prompt and failed safely
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

@test "T28 a stage edited while the prompt waits is not installed (review R2)" {
  need_script; fake_repo; symlink_install
  before=$(snap "$CLAUDE_HOME_DIR")
  export TAMPER='for f in "$TMPDIR"/cw-host-stage.*/payload/hooks/h.sh; do printf "echo TAMPERED\n" >> "$f"; done'
  run_pty_feed "$FEED_TAMPER" bash "$INSTALL"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'stage changed after review'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
  ! grep -rqs TAMPERED "$CLAUDE_HOME_DIR"
  ! compgen -G "$CLAUDE_HOME_DIR/.cw-new.*" >/dev/null
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
  ! compgen -G "$CLAUDE_HOME_DIR/.cw-new.*" >/dev/null
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
  ! grep -F "$d/hooks/sub/x.sh" <<<"$output" | grep -q 'WIRED'
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

@test "T36 an entry the destination lacks is listed with a file count, not diffed (review A7)" {
  need_script; fake_repo
  run_pty 'n\nn\n' bash "$INSTALL"
  echo "$output"
  d="$CLAUDE_HOME_DIR"
  [[ "$output" == *"ADD $d/hooks (new, 3 file(s)):"* ]]
  [[ "$output" == *'    hooks/lib/x.sh'* ]]
  [[ "$output" == *"ADD $d/CLAUDE.md (new, 1 file(s)):"* ]]
  [[ "$output" != *'+skill a'* ]]
  [[ "$output" != *'+global instructions'* ]]
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

@test "T38 backups are capped at the newest 3, and the install says so (review A6)" {
  need_script; fake_repo; symlink_install
  for i in 1 2 3 4; do
    printf 'change %s\n' "$i" >> "$ROOT/workflows/w.md"; commit_all "c$i"
    run_pty 'n\ny\n' bash "$INSTALL"
    grep -q "change $i" "$CLAUDE_HOME_DIR/workflows/w.md"
    sleep 1   # distinct second-resolution stamps
  done
  echo "$output"
  [ "$(find "$CLAUDE_HOME_DIR/.claude-workflows-backup" -mindepth 1 -maxdepth 1 | wc -l)" -eq 3 ]
  [[ "$output" == *'newest 3'* ]]
  # The oldest (the symlink-install backup) is the one pruned.
  [ -z "$(find "$CLAUDE_HOME_DIR/.claude-workflows-backup" -type l)" ]
}

@test "T24 with CLAUDE_HOME_DIR unset, CLAUDE_CONFIG_DIR chooses the destination" {
  need_script; fake_repo
  run_pty 'n\ny\n' env -u CLAUDE_HOME_DIR CLAUDE_CONFIG_DIR="$S/cfgdir" bash "$INSTALL"
  echo "$output"
  [ -d "$S/cfgdir/skills" ] && [ ! -L "$S/cfgdir/skills" ]
  [ ! -e "$HOME/.claude" ]
  [[ "$output" == *'CLAUDE_CONFIG_DIR'* ]]
}
