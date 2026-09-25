#!/usr/bin/env bats
# Security review pass 2 (2026-09-25) probes against install.sh at feba07d.
# Harness adapted from docs/reviews/execution-logs/secrev-q058-b4fd792/probe.bats.
#
# HERMETIC: HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR and
# TMPDIR all sit in BATS_TEST_TMPDIR; pgrep/docker are stubbed to "nothing
# running"; GIT_CONFIG_GLOBAL points at an empty file and GIT_CONFIG_NOSYSTEM=1,
# so neither the real home config dirs nor the real git config is read or
# written. The installer under test is a COPY inside a throwaway fake repo.
#
# Usage: bats docs/reviews/execution-logs/secrev-q058p2/probe.bats

# TAMPER is exported per test on purpose (bats runs each test in a subshell).
# shellcheck disable=SC2030,SC2031
bats_require_minimum_version 1.5.0

setup() {
  CONFIG_SRC="/workspace/.claude/wt-q058p2/devcontainer-config"
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
  touch "$S/stop"
  if [ -d "$S/home/.claude" ]; then chmod -R u+w "$S/home/.claude" 2>/dev/null || true; fi
}

G() { git -c user.email=t@t -c user.name=t "$@"; }

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

commit_all() { G -C "$ROOT" add -A; G -C "$ROOT" commit -q -m "${1:-edit}"; }

run_pty() {
  local input="$1"; shift
  # shellcheck disable=SC2016  # expanded by the inner bash
  run bash -c 'set -o pipefail; printf "%b" "$1" | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d "\r"' \
      _ "$input" "$*"
}
run_pty_feed() {
  local feed="$1"; shift
  # shellcheck disable=SC2016  # expanded by the inner bash
  run bash -c 'set -o pipefail; { eval "$1"; } | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d "\r"' \
      _ "$feed" "$*"
}
# shellcheck disable=SC2016  # evaluated later by run_pty_feed
FEED_TAMPER='printf "n\n"
  for _i in $(seq 200); do compgen -G "$TMPDIR/cw-host-stage.*/payload/.manifest" >/dev/null && break; sleep 0.1; done
  sleep 2; eval "$TAMPER"; printf "y\n"'

# plant_marker <name>: an executable that records it ran and passes stdin through.
plant_marker() {
  printf '#!/bin/sh\ntouch "%s/%s"\ncat\n' "$S" "$1" > "$S/$1.sh"
  chmod +x "$S/$1.sh"
}

# --- R2 (host swap-and-revert) ------------------------------------------------

@test "SP1 (re-run) stage swapped to benign during the review and restored before y" {
  fake_repo
  run_pty 'n\ny\n' bash "$INSTALL"
  printf '#!/bin/bash\necho MALICIOUS-PAYLOAD\n' > "$ROOT/hooks/h.sh"
  printf 'guide v2 benign\n' > "$ROOT/guides/g.md"
  commit_all mal
  (
    d=""
    for _i in $(seq 2000); do d=$(compgen -G "$TMPDIR/cw-host-stage.*/installed" | head -1) && [ -n "$d" ] && break; sleep 0.005; done
    st="${d%/installed}/payload"
    cp "$st/hooks/h.sh" "$S/mal.keep"
    printf '#!/bin/bash\nexit 0\n' > "$st/hooks/h.sh"
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
  # Resolved: the review now shows exactly what lands.
  [[ "$output" == *'+echo MALICIOUS-PAYLOAD'* ]]
  grep -q MALICIOUS-PAYLOAD "$CLAUDE_HOME_DIR/hooks/h.sh"
  echo "SP1 RESULT: review showed the payload that was installed"
}

@test "SP1b the OLD side of the diff (HOST_TMP/installed) is rewritten to match the new copy during the review" {
  fake_repo
  run_pty 'n\ny\n' bash "$INSTALL"
  printf '#!/bin/bash\necho MALICIOUS-PAYLOAD\n' > "$ROOT/hooks/h.sh"
  printf 'guide v2 benign\n' > "$ROOT/guides/g.md"
  commit_all mal
  # Same-uid helper, invisible to the gate: whenever the review's view copy of
  # hooks/h.sh exists and is not the new content, atomically replace it.
  (
    end=$((SECONDS + 20))
    while [ ! -e "$S/stop" ] && [ "$SECONDS" -lt "$end" ]; do
      for v in "$TMPDIR"/cw-host-stage.*/installed/hooks/h.sh; do
        [ -f "$v" ] || continue
        grep -q MALICIOUS "$v" && continue
        printf '#!/bin/bash\necho MALICIOUS-PAYLOAD\n' > "$v.t" && mv -f "$v.t" "$v" && echo hit >> "$S/helper.hits"
      done
      sleep 0.001
    done
  ) &
  export TAMPER="touch '$S/stop'"
  run_pty_feed "$FEED_TAMPER" bash "$INSTALL"
  wait
  echo "$output"
  echo "--- installed h.sh:"; cat "$CLAUDE_HOME_DIR/hooks/h.sh"
  [ -s "$S/helper.hits" ]
  [[ "$output" == *'+guide v2 benign'* ]]
  [[ "$output" != *'MALICIOUS-PAYLOAD'* ]]           # the review never showed it
  [[ "$output" == *'Installed into'* ]]
  grep -q MALICIOUS-PAYLOAD "$CLAUDE_HOME_DIR/hooks/h.sh"   # but it was installed
  echo "SP1b RESULT: unreviewed hook installed; hash check passed"
}

@test "SP1c a stage edit between git archive and the copy into dest lands under an ADD entry whose content is not shown" {
  fake_repo
  # A first-install skills tree over the 200-line ADD limit.
  seq 300 > "$ROOT/skills/a/big.md"
  commit_all big
  (
    end=$((SECONDS + 20))
    while [ ! -e "$S/stop" ] && [ "$SECONDS" -lt "$end" ]; do
      for v in "$TMPDIR"/cw-host-stage.*/payload/skills/a/SKILL.md; do
        [ -f "$v" ] || continue
        grep -q MALICIOUS "$v" && continue
        printf 'MALICIOUS-SKILL\n' > "$v.t" && mv -f "$v.t" "$v" && echo hit >> "$S/helper.hits"
      done
      sleep 0.001
    done
  ) &
  export TAMPER="touch '$S/stop'"
  run_pty_feed "$FEED_TAMPER" bash "$INSTALL"
  wait
  echo "$output"
  [ -s "$S/helper.hits" ]
  [[ "$output" == *'content not shown'*'it is skills at commit'* ]]
  [[ "$output" != *'MALICIOUS-SKILL'* ]]
  [[ "$output" == *'Installed into'* ]]
  echo "--- installed skills/a/SKILL.md:"; cat "$CLAUDE_HOME_DIR/skills/a/SKILL.md"
  grep -q MALICIOUS-SKILL "$CLAUDE_HOME_DIR/skills/a/SKILL.md"
  echo "SP1c RESULT: installed content differs from 'skills at commit X'"
}

@test "SP1d a symlink planted in the stage after extract_commit's link check installs as a live link into an agent-writable file" {
  fake_repo
  run_pty 'n\ny\n' bash "$INSTALL"
  printf 'guide v2 benign\n' > "$ROOT/guides/g.md"
  commit_all benign
  # The link target holds exactly what is installed today, so the review
  # (diff -r dereferences links) shows no change for hooks/h.sh.
  printf '#!/bin/bash\nexit 0\n' > "$S/agent-writable.sh"
  (
    end=$((SECONDS + 20))
    while [ ! -e "$S/stop" ] && [ "$SECONDS" -lt "$end" ]; do
      # .manifest is written last in assemble, after the link and NUL checks;
      # the copy into dest (hooks is 6th of 7) follows.
      for v in "$TMPDIR"/cw-host-stage.*/payload/hooks/h.sh; do
        [ -e "${v%/hooks/h.sh}/.manifest" ] || continue
        [ -L "$v" ] && continue
        ln -sf "$S/agent-writable.sh" "$v.t" && mv -Tf "$v.t" "$v" && echo hit >> "$S/helper.hits"
      done
      sleep 0.001
    done
  ) &
  export TAMPER="touch '$S/stop'"
  run_pty_feed "$FEED_TAMPER" bash "$INSTALL"
  wait
  echo "$output"
  [ -s "$S/helper.hits" ]
  [[ "$output" == *'+guide v2 benign'* ]]
  [[ "$output" == *'Installed into'* ]]
  ls -la "$CLAUDE_HOME_DIR/hooks/"
  [ -L "$CLAUDE_HOME_DIR/hooks/h.sh" ]
  printf '#!/bin/bash\necho AGENT-EDIT-AFTER-INSTALL\n' > "$S/agent-writable.sh"
  grep -q AGENT-EDIT-AFTER-INSTALL "$CLAUDE_HOME_DIR/hooks/h.sh"
  echo "SP1d RESULT: installed hook is a live link to an agent-writable file"
}

@test "SP1e devcontainer: a cc-isolated.sh symlink planted after extract_commit's check passes both A1 hashes and is blessed" {
  fake_repo
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$S/agent-writable-cc.sh"
  chmod +x "$S/agent-writable-cc.sh"
  mirror="$ROOT/devcontainer-config/claude-home"
  # Trigger: the checkout mirror is rebuilt after extract_commit's link check
  # and before the pre-review tree_hash.
  (
    end=$((SECONDS + 20))
    while [ ! -e "$S/stop" ] && [ "$SECONDS" -lt "$end" ]; do
      if [ -d "$mirror" ]; then
        for v in "$TMPDIR"/cw-devc-stage.*/config/cc-isolated.sh; do
          [ -e "$v" ] || continue
          [ -L "$v" ] && continue
          ln -sf "$S/agent-writable-cc.sh" "$v.t" && mv -Tf "$v.t" "$v" && echo hit >> "$S/helper.hits"
        done
      fi
      sleep 0.001
    done
  ) &
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  touch "$S/stop"; wait
  echo "$output"
  [ -s "$S/helper.hits" ]
  ls -la "$CLAUDE_DEVC_CONFIG_DIR/"
  [ -L "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ]
  [[ "$output" == *'BLESS-STUB --bless'* ]]
  echo "SP1e RESULT: blessed config's cc-isolated.sh is a link to an agent-writable file; status=$status"
}

# --- R1 (checkout git state runs commands) --------------------------------------

@test "SP3a (re-run) smudge filter + attributes, and core.fsmonitor, are refused and never run" {
  fake_repo
  plant_marker smudge-ran; plant_marker fsmon-ran
  git -C "$ROOT" config filter.pwn.smudge "$S/smudge-ran.sh"
  printf '*.md filter=pwn\n' > "$ROOT/.git/info/attributes"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]; [ ! -e "$S/smudge-ran" ]
  git -C "$ROOT" config --unset filter.pwn.smudge; : > "$ROOT/.git/info/attributes"
  git -C "$ROOT" config core.fsmonitor "$S/fsmon-ran.sh"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]; [ ! -e "$S/fsmon-ran" ]
  echo "SP3a RESULT: refused, no marker"
}

@test "SP3b .git/hooks/post-index-change runs during install (git status), not refused" {
  fake_repo
  printf '#!/bin/sh\ntouch "%s/hook-ran"\n' "$S" > "$ROOT/.git/hooks/post-index-change"
  chmod +x "$ROOT/.git/hooks/post-index-change"
  sleep 1; touch "$ROOT/skills/a/SKILL.md"   # stat-dirty: status refreshes and rewrites the index
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ -e "$S/hook-ran" ]
  echo "SP3b RESULT: hook ran as the user; install status=$status"
}

@test "SP3c core.hooksPath in .git/config (not in the refused key list) runs during install" {
  fake_repo
  mkdir -p "$S/hk"
  printf '#!/bin/sh\ntouch "%s/hookspath-ran"\n' "$S" > "$S/hk/post-index-change"
  chmod +x "$S/hk/post-index-change"
  git -C "$ROOT" config core.hooksPath "$S/hk"
  sleep 1; touch "$ROOT/skills/a/SKILL.md"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ -e "$S/hookspath-ran" ]
  echo "SP3c RESULT: hooksPath hook ran; install status=$status"
}

@test "SP3d a submodule's own git dir (filter + attributes + hook) runs during install; superproject gate sees nothing" {
  fake_repo
  git init -q "$S/sub"; printf 's\n' > "$S/sub/s.txt"; G -C "$S/sub" add .; G -C "$S/sub" commit -qm s
  G -C "$ROOT" -c protocol.file.allow=always submodule add -q "$S/sub" skills/sub
  G -C "$ROOT" commit -qm sub
  plant_marker sub-clean-ran
  md="$ROOT/.git/modules/skills/sub"
  git -C "$ROOT/skills/sub" config filter.pwn.clean "$S/sub-clean-ran.sh"
  printf '* filter=pwn\n' > "$md/info/attributes"
  printf '#!/bin/sh\ntouch "%s/sub-hook-ran"\n' "$S" > "$md/hooks/post-index-change"
  chmod +x "$md/hooks/post-index-change"
  sleep 1; touch "$ROOT/skills/sub/s.txt"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  echo "markers:"; for m in sub-clean-ran sub-hook-ran; do [ -e "$S/$m" ] && echo "  $m"; done
  [ -e "$S/sub-clean-ran" ] || [ -e "$S/sub-hook-ran" ]
  echo "SP3d RESULT: submodule filter/hook ran; install status=$status"
}

# --- A1 cleanup ---------------------------------------------------------------

@test "A1 after a post-copy mismatch, the cc-isolated link is left dangling (old script removed)" {
  fake_repo
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  [ "$status" -eq 0 ]
  [ -L "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ] && [ -e "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ]
  printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"; commit_all v2
  # shellcheck disable=SC2016  # the stub body is literal
  printf '#!/bin/bash\n%s "$@" || exit\ncase "${@: -1}" in */claude-devcontainer/devcontainer.json) echo TAMPERED >> "${@: -1}";; esac\n' \
    "$(command -v cp)" > "$STUB/cp"
  chmod +x "$STUB/cp"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" != *'BLESS-STUB'* ]]
  ls -la "$CLAUDE_DEVC_BIN_DIR" "$CLAUDE_DEVC_CONFIG_DIR"
  [ -L "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ]
  [ ! -e "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ]        # dangling: points at the removed script
  [ ! -e "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ]
  echo "A1 RESULT: link dangling, no old or unreviewed script reachable"
}

@test "A1b a cp failure later in the copy loop exits (set -e) before the post-copy check; an altered cc-isolated.sh stays live" {
  fake_repo
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  [ "$status" -eq 0 ]
  printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"; commit_all v2
  # Simulated with a cp stub, as T70 does: cc-isolated.sh changes as it lands
  # (the stage edited during the loop), and the later egress copy fails (e.g.
  # the same writer removed the stage's egress dir).
  # shellcheck disable=SC2016  # the stub body is literal
  printf '#!/bin/bash\ncase "${@: -1}" in */claude-devcontainer/egress) exit 1;; esac\n%s "$@" || exit\ncase "${@: -1}" in */claude-devcontainer/cc-isolated.sh) echo "echo TAMPERED-LAUNCHER" >> "${@: -1}";; esac\n' \
    "$(command -v cp)" > "$STUB/cp"
  chmod +x "$STUB/cp"
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" != *'differs from what the review'* ]]   # the post-copy check never ran
  [[ "$output" != *'BLESS-STUB'* ]]
  [ -e "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ]
  grep -q TAMPERED-LAUNCHER "$CLAUDE_DEVC_BIN_DIR/cc-isolated"
  echo "A1b RESULT: unreviewed launcher live behind the cc-isolated link; status=$status"
}

# --- R2 staging-under-dest side effects -----------------------------------------

@test "R2x first-install decline removes the created dest; a planted .cw-new.hooks dir is replaced, not reviewed" {
  fake_repo
  run_pty 'n\nn\n' bash "$INSTALL"
  echo "$output"
  [ ! -e "$CLAUDE_HOME_DIR" ]
  mkdir -p "$CLAUDE_HOME_DIR/.cw-new.hooks"; printf 'echo PLANTED\n' > "$CLAUDE_HOME_DIR/.cw-new.hooks/evil.sh"
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "$output"
  [[ "$output" == *'Installed into'* ]]
  [ ! -e "$CLAUDE_HOME_DIR/hooks/evil.sh" ]
  [[ "$output" != *'PLANTED'* ]]
  run ! compgen -G "$CLAUDE_HOME_DIR/.cw-new.*"
  echo "R2x RESULT: decline cleans up; planted copy dir discarded"
}
