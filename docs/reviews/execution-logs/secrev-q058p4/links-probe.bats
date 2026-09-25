#!/usr/bin/env bats
# Security review pass 4 (2026-09-25) probes of links_in at f5e3029: a missing
# item and a find failure, at each of its three call sites. Every test asserts
# the SAFE outcome (nothing unreviewed installed or blessed) and prints what the
# installer said, so the log shows HOW it failed closed (message or silent).
#
# HERMETIC: HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR and
# TMPDIR all sit in BATS_TEST_TMPDIR; pgrep/docker are stubbed to "nothing
# running"; GIT_CONFIG_GLOBAL is an empty file and GIT_CONFIG_NOSYSTEM=1. The
# installer under test is a COPY of /workspace/.claude/wt-q058p2's install.sh
# (f5e3029) inside a throwaway fake repo. Helpers are copied from
# test/install-host.bats at f5e3029.
#
# Usage: bats docs/reviews/execution-logs/secrev-q058p4/links-probe.bats

bats_require_minimum_version 1.5.0

setup() {
  CONFIG_SRC="${PROBE_CONFIG_SRC:-/workspace/.claude/wt-q058p2/devcontainer-config}"
  S="$BATS_TEST_TMPDIR"
  export HOME="$S/home"
  export CLAUDE_HOME_DIR="$HOME/.claude"
  export CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/claude-devcontainer"
  export CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
  export TMPDIR="$S/tmp"
  export SHELL=/bin/bash
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_CONFIG_GLOBAL="$S/empty.gitconfig"
  unset CLAUDE_CONFIG_DIR USAGE_LOG_FILE
  mkdir -p "$HOME" "$TMPDIR"
  : > "$GIT_CONFIG_GLOBAL"
  ROOT="$S/repo"
  INSTALL="$ROOT/devcontainer-config/install.sh"
  STUB="$S/stub"
  mkdir -p "$STUB"
  printf '#!/bin/bash\nexit 1\n' > "$STUB/pgrep"
  printf '#!/bin/bash\nexit 0\n' > "$STUB/docker"
  chmod +x "$STUB/pgrep" "$STUB/docker"
  export PATH="$STUB:$PATH"
}

teardown() {
  chmod -R u+rwx "$S" 2>/dev/null || true
}

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

commit_all() {
  git -C "$ROOT" add -A
  git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m "${1:-edit}"
}

# A prior install of the host target as plain files, so the host swap has
# something to replace and a snapshot to compare.
host_prior() {
  local d="$CLAUDE_HOME_DIR" n
  mkdir -p "$d"
  cp "$ROOT/global-instructions/CLAUDE.md" "$d/CLAUDE.md"
  for n in skills workflows guides patterns hooks scripts; do cp -R "$ROOT/$n" "$d/$n"; done
  printf 'old\n' > "$d/skills/a/SKILL.md"   # so there is something to install
  printf '{"user":"settings"}\n' > "$d/settings.json"
}

snap() {
  local dir="$1"
  [ -e "$dir" ] || { echo "ABSENT"; return; }
  (cd "$dir" && find . -printf '%p %y %m %l\n' | sort
   cd "$dir" && find . -type f -print0 | sort -z | xargs -0 -r sha256sum)
}

run_pty() {
  local input="$1"; shift
  run bash -c 'set -o pipefail; printf "%b" "$1" | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d "\r"' \
      _ "$input" "$*"
}

# stub_cp_then <case-pattern> <shell>: real cp, then the snippet when the last
# argument matches ($dst is that argument, $srcarg the one before it).
stub_cp_then() {
  printf '#!/bin/bash\n%s "$@" || exit\ndst="${@: -1}"; srcarg="${@: -2:1}"\ncase "$dst" in %s) %s ;; esac\nexit 0\n' \
    "$(command -v cp)" "$1" "$2" > "$STUB/cp"
  chmod +x "$STUB/cp"
}

# No PAYLOAD item of the devcontainer target may be live or blessed.
devc_nothing_live() {
  [[ "$output" != *'BLESS-STUB'* ]]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ]
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/init-firewall.sh" ]
}

# --- Site 1: the devcontainer stage, before the review ----------------------
# The checkout mirror rebuild (cp -Rp "$stage/claude-home/." ...) runs after
# extract_commit's link check and right before links_in on the stage.

@test "L1 stage: a middle PAYLOAD item (cc-isolated.sh) removed before links_in" {
  fake_repo
  stub_cp_then '*/claude-home/' "rm -f \"\${srcarg%/claude-home/.}/cc-isolated.sh\""
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "status=$status"; echo "$output"
  [ "$status" -ne 0 ]
  devc_nothing_live
}

@test "L2 stage: the LAST PAYLOAD item (claude-home) removed before links_in" {
  fake_repo
  stub_cp_then '*/claude-home/' "rm -rf \"\${srcarg%/.}\""
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "status=$status"; echo "$output"
  [ "$status" -ne 0 ]
  devc_nothing_live
}

@test "L3 stage: find cannot read an item (egress made mode 000) before links_in" {
  fake_repo
  stub_cp_then '*/claude-home/' "chmod 000 \"\${srcarg%/claude-home/.}/egress\""
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "status=$status"; echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *'could not read every item'* ]]
  devc_nothing_live
}

# --- Site 2: $DEST after the copy, before the bless -------------------------

@test "L4 DEST: a middle item (cc-isolated.sh) removed right after its copy" {
  fake_repo
  stub_cp_then '*/claude-devcontainer/cc-isolated.sh' 'rm -f "$dst"'
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "status=$status"; echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *'ERROR:'*'removed again'* ]]
  devc_nothing_live
}

@test "L5 DEST: a tampered cc-isolated.sh, then find cannot read egress (mode 000)" {
  fake_repo
  stub_cp_then '*/claude-devcontainer/cc-isolated.sh|*/claude-devcontainer/egress' \
    'case "$dst" in *.sh) echo "echo TAMPERED" >> "$dst" ;; *) chmod 000 "$dst" ;; esac'
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "status=$status"; echo "$output"
  echo "--- left in DEST:"; ls -la "$CLAUDE_DEVC_CONFIG_DIR" || true
  [ "$status" -ne 0 ]
  devc_nothing_live
  [ -z "$(grep -rls TAMPERED "$CLAUDE_DEVC_CONFIG_DIR" 2>/dev/null)" ]
}

@test "L5b DEST: as L5, but the unreadable dir is inside claude-home (the last item)" {
  fake_repo
  stub_cp_then '*/claude-devcontainer/cc-isolated.sh|*/claude-devcontainer/claude-home' \
    'case "$dst" in *.sh) echo "echo TAMPERED" >> "$dst" ;; *) chmod 000 "$dst/skills" ;; esac'
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "status=$status"; echo "$output"
  echo "--- left in DEST:"; ls -la "$CLAUDE_DEVC_CONFIG_DIR" || true
  [ "$status" -ne 0 ]
  devc_nothing_live
  [ -z "$(grep -rls TAMPERED "$CLAUDE_DEVC_CONFIG_DIR" 2>/dev/null)" ]
}

# --- Site 3: the host copies $dest/.cw-new.*, before the review -------------

@test "L6 host: a middle copy (.cw-new.hooks) missing at links_in; answered y" {
  command -v script >/dev/null || skip "no util-linux script"
  fake_repo; host_prior
  stub_cp_then '*/.cw-new.hooks' 'rm -rf "$dst"'
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "status=$status"; echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" != *'Installed into'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
}

@test "L7 host: the LAST copy (.cw-new.scripts) missing at links_in" {
  command -v script >/dev/null || skip "no util-linux script"
  fake_repo; host_prior
  stub_cp_then '*/.cw-new.scripts' 'rm -rf "$dst"'
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "status=$status"; echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" != *'Installed into'* ]]
  [ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]
}

@test "L8 host: find cannot read a copy (.cw-new.skills/a mode 000)" {
  command -v script >/dev/null || skip "no util-linux script"
  fake_repo; host_prior
  stub_cp_then '*/.cw-new.skills' 'chmod 000 "$dst/a"'
  before=$(snap "$CLAUDE_HOME_DIR")
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "status=$status"; echo "$output"
  echo "--- .cw-new.* left:"; ls -d "$CLAUDE_HOME_DIR"/.cw-new.* 2>/dev/null || echo none
  [ "$status" -ne 0 ]
  [[ "$output" == *'could not read every item'* ]]
  [[ "$output" != *'Installed into'* ]]
  chmod -R u+rwx "$CLAUDE_HOME_DIR" 2>/dev/null || true
}

# --- dc_unwind itself (reached from links_in's new failure path and from the
# hash mismatch): does it remove every item when one rm fails? ---------------

@test "L9 stage writer after the y: Dockerfile becomes a dir holding a 0555 subdir, cc-isolated.sh is altered" {
  fake_repo
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  [ "$status" -eq 0 ]
  [ -L "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ]
  printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"; commit_all v2
  # A $TMPDIR writer acting after the post-y stage hash, when the first PAYLOAD
  # item lands in DEST: every later item is copied from the altered stage.
  stub_cp_then '*/claude-devcontainer/devcontainer.json' \
    'st="${srcarg%/devcontainer.json}"; rm -f "$st/Dockerfile"; mkdir -p "$st/Dockerfile/s"; echo x > "$st/Dockerfile/s/f"; chmod 555 "$st/Dockerfile/s"; echo "echo TAMPERED-LAUNCHER" >> "$st/cc-isolated.sh"'
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "status=$status"; echo "$output"
  echo "--- left in DEST:"; ls -la "$CLAUDE_DEVC_CONFIG_DIR" || true
  echo "--- running the cc-isolated link, as the user next would:"
  run "$CLAUDE_DEVC_BIN_DIR/cc-isolated" --version
  echo "$output"
  # SAFE outcome asserted: no altered launcher behind the link.
  [ -z "$(grep -rls TAMPERED-LAUNCHER "$CLAUDE_DEVC_CONFIG_DIR" 2>/dev/null)" ]
}
