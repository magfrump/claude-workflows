#!/bin/bash
# Hermetic experiments against a copy of install.sh in a throwaway repo.
# Never touches the real HOME: everything under $S.
W=/workspace/.claude/wt-copyinstall
SP=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad
unset CLAUDECODE CLAUDE_CONFIG_DIR
export SHELL=/bin/bash

setup() {
  S=$SP/fc/exp/$1; rm -rf "$S"; mkdir -p "$S"
  export HOME="$S/home" CLAUDE_HOME_DIR="$S/home/.claude"
  export CLAUDE_DEVC_CONFIG_DIR="$S/home/.config/cd" CLAUDE_DEVC_BIN_DIR="$S/home/.local/bin"
  export TMPDIR="$S/tmp"; mkdir -p "$HOME" "$TMPDIR"
  ROOT="$S/repo"; cfg="$ROOT/devcontainer-config"
  mkdir -p "$cfg/egress" "$ROOT/global-instructions" "$ROOT/skills/a" "$ROOT/workflows" \
           "$ROOT/guides" "$ROOT/patterns" "$ROOT/hooks/lib" "$ROOT/scripts"
  cp "$W/devcontainer-config/install.sh" "$cfg/install.sh"
  printf 'gi\n' > "$ROOT/global-instructions/CLAUDE.md"
  printf 'skill a\n' > "$ROOT/skills/a/SKILL.md"
  printf 'w\n' > "$ROOT/workflows/w.md"; printf 'g\n' > "$ROOT/guides/g.md"; printf 'p\n' > "$ROOT/patterns/p.md"
  printf '#!/bin/bash\nexit 0\n' > "$ROOT/hooks/h.sh"; printf 'x\n' > "$ROOT/hooks/lib/x.sh"
  printf '{"hooks":{}}\n' > "$ROOT/hooks/wiring.json"; printf 's\n' > "$ROOT/scripts/s.sh"
  for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py link-claude-home.sh; do printf 'stub\n' > "$cfg/$f"; done
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$cfg/cc-isolated.sh"; chmod +x "$cfg/cc-isolated.sh"
  printf 'a\n' > "$cfg/egress/base.txt"
  printf 'devcontainer-config/claude-home/\n' > "$ROOT/.gitignore"
  git -C "$ROOT" init -q; git -C "$ROOT" add -A; git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m init
  INSTALL="$cfg/install.sh"
}
pty() { printf "%b" "$1" | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d '\r'; echo "PIPESTATUS=${PIPESTATUS[*]}"; }

echo "######## E1 dest is a symlink to a non-checkout dir"
setup e1; mkdir -p "$S/elsewhere"; ln -s "$S/elsewhere" "$CLAUDE_HOME_DIR"
pty 'n\ny\n' "bash $INSTALL" | tail -8
ls -la "$S/elsewhere" | head; ls -la "$HOME"

echo "######## E2 per-file symlink with DIFFERENT content + foreign symlinked skill dir + dangling per-file link"
setup e2; mkdir -p "$CLAUDE_HOME_DIR/hooks/lib" "$S/other/myskill"
cp -R "$ROOT/skills" "$CLAUDE_HOME_DIR/skills"; printf 'mine\n' > "$S/other/myskill/SKILL.md"
ln -s "$S/other/myskill" "$CLAUDE_HOME_DIR/skills/myskill"
printf '#!/bin/bash\necho OLD\n' > "$S/other/h.sh"; ln -s "$S/other/h.sh" "$CLAUDE_HOME_DIR/hooks/h.sh"
pty 'n\nn\n' "bash $INSTALL" | sed -n '/Host target/,$p'
echo "-- E2b dangling per-file symlink in hooks"
setup e2b; mkdir -p "$CLAUDE_HOME_DIR/hooks"; ln -s "$S/gone.sh" "$CLAUDE_HOME_DIR/hooks/old.sh"
pty 'n\nn\n' "bash $INSTALL" | sed -n '/Host target/,$p'

echo "######## E3 installed_parent under script with SHELL=bash, sh, and zsh"
for sh in /bin/bash /bin/sh /usr/bin/zsh; do
  [ -x "$sh" ] || continue
  setup "e3$(basename $sh)"; export SHELL=$sh
  pty 'n\ny\n' "bash $INSTALL" >/dev/null
  echo "SHELL=$sh: $(grep installed_ "$CLAUDE_HOME_DIR/.claude-workflows-manifest" | tr '\n' ' ')"
  setup "e3x$(basename $sh)"; export SHELL=$sh
  pty 'n\ny\n' "$INSTALL" >/dev/null
  echo "SHELL=$sh direct exec: $(grep installed_parent "$CLAUDE_HOME_DIR/.claude-workflows-manifest")"
done
export SHELL=/bin/bash

echo "######## E4 mv failure between backup and swap (workflows dir not writable)"
setup e4; mkdir -p "$CLAUDE_HOME_DIR"
for n in skills workflows guides; do cp -R "$ROOT/$n" "$CLAUDE_HOME_DIR/$n"; done
cp "$ROOT/global-instructions/CLAUDE.md" "$CLAUDE_HOME_DIR/CLAUDE.md"
chmod a-w "$CLAUDE_HOME_DIR/workflows"
pty 'n\ny\n' "bash $INSTALL" | sed -n '/Install these files/,$p'
chmod u+w "$CLAUDE_HOME_DIR/workflows" 2>/dev/null
echo "-- dest after:"; ls -A "$CLAUDE_HOME_DIR"; echo "-- backup:"; ls -A "$CLAUDE_HOME_DIR"/.claude-workflows-backup/*

echo "######## E5 two sequential runs in the same second"
setup e5; mkdir -p "$CLAUDE_HOME_DIR"; cp -R "$ROOT/skills" "$CLAUDE_HOME_DIR/skills"
pty 'n\ny\n' "bash $INSTALL" >/dev/null; pty 'n\ny\n' "bash $INSTALL" >/dev/null
ls -A "$CLAUDE_HOME_DIR/.claude-workflows-backup"
echo "-- E5b concurrent: pre-create stamp dir race simulation (backup/<stamp>/skills exists)"
setup e5b; mkdir -p "$CLAUDE_HOME_DIR"; cp -R "$ROOT/skills" "$CLAUDE_HOME_DIR/skills"
( pty 'n\ny\n' "bash $INSTALL" >/dev/null ) & ( pty 'n\ny\n' "bash $INSTALL" > "$S/b.out" ) & wait
ls -A "$CLAUDE_HOME_DIR/.claude-workflows-backup"; find "$CLAUDE_HOME_DIR/.claude-workflows-backup" -maxdepth 3 | sort; tail -3 "$S/b.out"

echo "######## E6 non-interactive devcontainer run output old vs new"
setup e6
env -u CLAUDECODE bash "$INSTALL" </dev/null > "$S/new.out" 2>&1; echo "new exit=$?"
git -C "$W" show 712c626:devcontainer-config/install.sh > "$S/old.sh"; cp "$S/old.sh" "$INSTALL"
env -u CLAUDECODE bash "$INSTALL" </dev/null > "$S/old.out" 2>&1; echo "old exit=$?"
diff "$S/old.out" "$S/new.out"
echo "-- --help old:"; env -u CLAUDECODE bash "$INSTALL" --help </dev/null 2>&1 | tail -2; echo "old --help exit=${PIPESTATUS[0]}"
