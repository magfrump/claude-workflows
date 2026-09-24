#!/usr/bin/env bash
# Hermetic experiments against the branch's install.sh (and the 712c626 one).
# Everything lives under $B; HOME and every destination env var point inside it.
set -u
FC=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/fc
W=/workspace/.claude/wt-copyinstall
B="$FC/exp"
unset CLAUDECODE CLAUDE_CONFIG_DIR USAGE_LOG_FILE
export SHELL=/bin/bash

setup_env() {   # $1 = scenario name
  S="$B/$1"; rm -rf "$S"; mkdir -p "$S"
  export HOME="$S/home" CLAUDE_HOME_DIR="$S/home/.claude"
  export CLAUDE_DEVC_CONFIG_DIR="$S/home/.config/claude-devcontainer" CLAUDE_DEVC_BIN_DIR="$S/home/.local/bin"
  export TMPDIR="$S/tmp"
  mkdir -p "$HOME" "$TMPDIR"
  ROOT="$S/repo"; INSTALL="$ROOT/devcontainer-config/install.sh"
}

fake_repo() {   # $1 = install.sh source file
  local cfg="$ROOT/devcontainer-config" f
  mkdir -p "$cfg/egress" "$ROOT/global-instructions" "$ROOT/skills/a" "$ROOT/workflows" \
           "$ROOT/guides" "$ROOT/patterns" "$ROOT/hooks/lib" "$ROOT/scripts"
  cp "$1" "$cfg/install.sh"
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
  git -C "$ROOT" init -q; git -C "$ROOT" add -A
  git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m init
}

run_pty() {   # $1 answers, rest command
  local input="$1"; shift
  printf "%b" "$input" | env -u CLAUDECODE script -qec "$*" /dev/null | tr -d '\r'
  echo "[pipeline exit=${PIPESTATUS[2]}]"
}

NEW="$W/devcontainer-config/install.sh"
OLD="$FC/install-712c626.sh"
git -C "$W" show 712c626:devcontainer-config/install.sh > "$OLD"

case "$1" in
E1) # non-interactive devcontainer output, old vs new
  for v in OLD NEW; do
    for mode in closed yes; do
      setup_env "E1-$v-$mode"; fake_repo "${!v}"
      echo "##### $v $mode"
      if [ $mode = closed ]; then bash "$INSTALL" </dev/null; else bash "$INSTALL" --yes </dev/null; fi
      echo "[exit=$?]"
    done
  done ;;
E2) # dest is a symlink to a non-checkout dir
  setup_env E2; fake_repo "$NEW"
  mkdir -p "$S/elsewhere"; ln -s "$S/elsewhere" "$CLAUDE_HOME_DIR"
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "--- dest is link? $( [ -L "$CLAUDE_HOME_DIR" ] && echo yes)"; ls -la "$S/elsewhere" ;;
E3) # per-file hook symlink to a NON-checkout file with different content; also foreign skill dir
  setup_env E3; fake_repo "$NEW"
  mkdir -p "$CLAUDE_HOME_DIR/hooks" "$S/other"
  cp -R "$ROOT/skills" "$ROOT/workflows" "$ROOT/guides" "$ROOT/patterns" "$ROOT/scripts" "$CLAUDE_HOME_DIR/"
  cp "$ROOT/global-instructions/CLAUDE.md" "$CLAUDE_HOME_DIR/CLAUDE.md"
  cp -R "$ROOT/hooks/lib" "$ROOT/hooks/wiring.json" "$CLAUDE_HOME_DIR/hooks/"
  printf '#!/bin/bash\necho DIFFERENT\n' > "$S/other/h.sh"
  ln -s "$S/other/h.sh" "$CLAUDE_HOME_DIR/hooks/h.sh"
  mkdir -p "$CLAUDE_HOME_DIR/skills/mine"; printf 'mine\n' > "$CLAUDE_HOME_DIR/skills/mine/SKILL.md"
  run_pty 'n\nn\n' bash "$INSTALL" ;;
E3b) # per-file hook symlink to checkout file (content same)
  setup_env E3b; fake_repo "$NEW"
  mkdir -p "$CLAUDE_HOME_DIR/hooks"
  ln -s "$ROOT/hooks/h.sh" "$CLAUDE_HOME_DIR/hooks/h.sh"
  run_pty 'n\nn\n' bash "$INSTALL" ;;
E3c) # checkout moved: every top-level link dangles
  setup_env E3c; fake_repo "$NEW"
  mkdir -p "$CLAUDE_HOME_DIR"
  for n in workflows skills patterns guides scripts hooks; do ln -s "$S/gone/$n" "$CLAUDE_HOME_DIR/$n"; done
  ln -s "$S/gone/CLAUDE.md" "$CLAUDE_HOME_DIR/CLAUDE.md"
  run_pty 'n\nn\n' bash "$INSTALL" ;;
E4) # failure in the move-aside window: a read-only real 'hooks' dir cannot be renamed
  setup_env E4; fake_repo "$NEW"
  mkdir -p "$CLAUDE_HOME_DIR"
  for n in skills workflows guides patterns hooks scripts; do cp -R "$ROOT/$n" "$CLAUDE_HOME_DIR/$n"; done
  cp "$ROOT/global-instructions/CLAUDE.md" "$CLAUDE_HOME_DIR/CLAUDE.md"
  printf 'old\n' >> "$CLAUDE_HOME_DIR/skills/a/SKILL.md"
  chmod a-w "$CLAUDE_HOME_DIR/hooks"
  run_pty 'n\ny\n' bash "$INSTALL"
  chmod u+w "$CLAUDE_HOME_DIR/hooks"
  echo "--- dest after:"; ls -A "$CLAUDE_HOME_DIR"
  echo "--- backup:"; ls -A "$CLAUDE_HOME_DIR"/.claude-workflows-backup/* ;;
E5) # does script + env -u give a pty and drop CLAUDECODE?
  CLAUDECODE=1 script -qec 'env -u CLAUDECODE bash -c "[ -t 0 ] && echo stdin-is-tty || echo stdin-not-tty; echo CLAUDECODE=\${CLAUDECODE:-unset}"' /dev/null </dev/null | tr -d '\r'
  echo "[outside: $( [ -t 0 ] && echo tty || echo not-tty )]" ;;
E6) # manifest installed_parent under a pty wrapper
  setup_env E6; fake_repo "$NEW"
  run_pty 'n\ny\n' bash "$INSTALL" >/dev/null
  cat "$CLAUDE_HOME_DIR/.claude-workflows-manifest" ;;
E7) # two back-to-back runs: backup stamp collision handling
  setup_env E7; fake_repo "$NEW"
  run_pty 'n\ny\n' bash "$INSTALL" >/dev/null
  printf 'x\n' >> "$ROOT/skills/a/SKILL.md"
  run_pty 'n\ny\n' bash "$INSTALL" | grep -E 'moved to|exit='
  printf 'y\n' >> "$ROOT/skills/a/SKILL.md"
  run_pty 'n\ny\n' bash "$INSTALL" | grep -E 'moved to|exit='
  ls -A "$CLAUDE_HOME_DIR/.claude-workflows-backup" ;;
E8) for v in OLD NEW; do setup_env "E8-$v"; fake_repo "${!v}"; echo "##### $v -h"; bash "$INSTALL" -h </dev/null | head -3; echo "[exit=${PIPESTATUS[0]}]"; echo "##### $v --yes extra"; bash "$INSTALL" --yes extra </dev/null >/dev/null 2>&1; echo "[exit=$?] devc installed? $( [ -f "$CLAUDE_DEVC_CONFIG_DIR/devcontainer.json" ] && echo yes || echo no)"; done ;;
E9) setup_env E9; fake_repo "$NEW"; mkdir -p "$CLAUDE_HOME_DIR"
  for n in skills workflows guides patterns hooks scripts; do cp -R "$ROOT/$n" "$CLAUDE_HOME_DIR/$n"; done
  cp "$ROOT/global-instructions/CLAUDE.md" "$CLAUDE_HOME_DIR/"
  chmod a-w "$CLAUDE_HOME_DIR/hooks"
  printf 'n\ny\n' | env -u CLAUDECODE script -qec "bash $INSTALL; echo INSTALL_EXIT=\$?" /dev/null | tr -d '\r' | tail -2
  chmod u+w "$CLAUDE_HOME_DIR/hooks" ;;
esac
