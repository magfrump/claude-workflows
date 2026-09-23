#!/usr/bin/env bash
# Hermetic probes of install.sh (HEAD d0fdd04 and pre-change 712c626).
# Every destination is under $B; nothing touches the real HOME.
set -u
FC=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/cfc-r3
WT=/workspace/.claude/wt-copyinstall
B="$FC/probe"
rm -rf "$B"; mkdir -p "$B"
export SHELL=/bin/bash
unset CLAUDECODE CLAUDE_CONFIG_DIR

git -C "$WT" show d0fdd04:devcontainer-config/install.sh > "$B/install-head.sh"
git -C "$WT" show 712c626:devcontainer-config/install.sh > "$B/install-old.sh"

setenv() { # $1 = case name
  C="$B/$1"; mkdir -p "$C"
  export HOME="$C/home" CLAUDE_HOME_DIR="$C/home/.claude"
  export CLAUDE_DEVC_CONFIG_DIR="$C/home/.config/claude-devcontainer" CLAUDE_DEVC_BIN_DIR="$C/home/.local/bin"
  export TMPDIR="$C/tmp"; mkdir -p "$HOME" "$TMPDIR"
  ROOT="$C/repo"; INSTALL="$ROOT/devcontainer-config/install.sh"
}
fake_repo() { # $1 = which install.sh
  local cfg="$ROOT/devcontainer-config" f
  mkdir -p "$cfg/egress" "$ROOT/global-instructions" "$ROOT/skills/a" "$ROOT/workflows" \
           "$ROOT/guides" "$ROOT/patterns" "$ROOT/hooks/lib" "$ROOT/scripts"
  cp "$1" "$cfg/install.sh"; chmod +x "$cfg/install.sh"
  printf 'global instructions\n' > "$ROOT/global-instructions/CLAUDE.md"
  printf 'skill a\n' > "$ROOT/skills/a/SKILL.md"
  printf 'workflow\n' > "$ROOT/workflows/w.md"
  printf 'guide\n' > "$ROOT/guides/g.md"
  printf 'pattern\n' > "$ROOT/patterns/p.md"
  printf '#!/bin/bash\nexit 0\n' > "$ROOT/hooks/h.sh"
  printf '#!/bin/bash\n' > "$ROOT/hooks/lib/x.sh"
  printf '{"hooks":{}}\n' > "$ROOT/hooks/wiring.json"
  printf '#!/bin/bash\n' > "$ROOT/scripts/s.sh"
  for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py link-claude-home.sh; do printf 'stub %s\n' "$f" > "$cfg/$f"; done
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$cfg/cc-isolated.sh"; chmod +x "$cfg/cc-isolated.sh"
  printf 'api.anthropic.com\n' > "$cfg/egress/base.txt"
  printf 'devcontainer-config/claude-home/\n' > "$ROOT/.gitignore"
  git -C "$ROOT" init -q; git -C "$ROOT" add -A; git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m init
}
pty() { # $1 = answers, $2 = command string
  printf '%b' "$1" | script -qec "$2" /dev/null
  echo "[exit=$?]"
}
hr() { echo; echo "######## $* ########"; }

# P1 non-interactive, no --yes: HEAD vs old
hr "P1a HEAD, stdin=/dev/null, no args"; setenv p1a; fake_repo "$B/install-head.sh"; "$INSTALL" </dev/null; echo "[exit=$?]"; ls -A "$HOME"
hr "P1b OLD, stdin=/dev/null, no args"; setenv p1b; fake_repo "$B/install-old.sh"; "$INSTALL" </dev/null; echo "[exit=$?]"
hr "P1c HEAD --yes </dev/null"; setenv p1c; fake_repo "$B/install-head.sh"; "$INSTALL" --yes </dev/null | tail -5; echo "[exit=${PIPESTATUS[0]}]"; ls -A "$HOME"
hr "P1d OLD -h </dev/null"; setenv p1d; fake_repo "$B/install-old.sh"; "$INSTALL" -h </dev/null | tail -3; echo "[exit=${PIPESTATUS[0]}]"
hr "P1e HEAD -h"; setenv p1e; fake_repo "$B/install-head.sh"; "$INSTALL" -h >/dev/null; echo "[exit=$?]"

# P2 CLAUDECODE set, under pty
hr "P2 HEAD CLAUDECODE=1 under pty, answers n,y"; setenv p2; fake_repo "$B/install-head.sh"; export CLAUDECODE=1; pty 'n\ny\n' "$INSTALL" | tail -4; unset CLAUDECODE; ls -A "$HOME"

# P3 migration scenario with per-file hook symlink, foreign skill dir, foreign per-file link, dangling link
hr "P3 migration, pty, env -u CLAUDECODE, answers n,y"; setenv p3; fake_repo "$B/install-head.sh"
d="$CLAUDE_HOME_DIR"; mkdir -p "$d/hooks" "$d/memory"
ln -s "$ROOT/global-instructions/CLAUDE.md" "$d/CLAUDE.md"
for n in skills workflows guides patterns scripts; do ln -s "$ROOT/$n" "$d/$n"; done
ln -s "$ROOT/hooks/h.sh" "$d/hooks/h.sh"
printf 'foreign hook\n' > "$d/hooks/mine.sh"
ln -s "$C/elsewhere.sh" "$d/hooks/dangling.sh"
printf 'x\n' > "$C/other.sh"; ln -s "$C/other.sh" "$d/hooks/foreignlink.sh"
printf '{"hooks":{"x":"bash ~/.claude/hooks/mine.sh"}}\n' > "$d/settings.json"
pty 'n\ny\n' "env -u CLAUDECODE $INSTALL"
ls -la "$d" "$d/hooks"; ls -R "$d/.claude-workflows-backup" | head -30; cat "$d/.claude-workflows-manifest"

# P3b per-file symlink in a real dir whose TARGET content differs from the repo
hr "P3b real skills dir with per-file link to a file whose content differs"; setenv p3b; fake_repo "$B/install-head.sh"
d="$CLAUDE_HOME_DIR"; mkdir -p "$d/skills/a"; printf 'OLD CONTENT\n' > "$C/old-skill.md"; ln -s "$C/old-skill.md" "$d/skills/a/SKILL.md"
pty 'n\nn\n' "env -u CLAUDECODE $INSTALL" | sed -n '/Host target/,$p'

# P3c top-level symlink to a NON-checkout dir with different content
hr "P3c ~/.claude/skills -> non-checkout dir with other content"; setenv p3c; fake_repo "$B/install-head.sh"
d="$CLAUDE_HOME_DIR"; mkdir -p "$d" "$C/myskills/zzz"; printf 'mine\n' > "$C/myskills/zzz/SKILL.md"; ln -s "$C/myskills" "$d/skills"
pty 'n\nn\n' "env -u CLAUDECODE $INSTALL" | sed -n '/Host target/,$p'

# P4 dest itself symlink to non-checkout dir
hr "P4 dest symlink -> real dir outside checkout"; setenv p4; fake_repo "$B/install-head.sh"
mkdir -p "$C/realclaude"; ln -s "$C/realclaude" "$HOME/.claude"
pty 'n\ny\n' "env -u CLAUDECODE $INSTALL" | tail -4; ls -la "$HOME/.claude" ; ls -A "$C/realclaude"

# P5 dest symlink into checkout
hr "P5 dest symlink -> checkout"; setenv p5; fake_repo "$B/install-head.sh"
ln -s "$ROOT" "$HOME/.claude"
pty 'n\ny\n' "env -u CLAUDECODE $INSTALL" | tail -4; git -C "$ROOT" status --porcelain

# P6 failure between move-aside and swap-in: unwritable real dir cannot be renamed to a new parent
hr "P6 mv failure mid step 2"; setenv p6; fake_repo "$B/install-head.sh"
d="$CLAUDE_HOME_DIR"; mkdir -p "$d/workflows"; printf 'workflow\n' > "$d/workflows/w.md"; mkdir -p "$d/skills/a"; printf 'skill a\n' > "$d/skills/a/SKILL.md"
printf 'global instructions\n' > "$d/CLAUDE.md"
chmod a-w "$d/workflows"
pty 'n\ny\n' "env -u CLAUDECODE $INSTALL" | tail -6
echo "--- state after failure:"; ls -la "$d"; ls -R "$d/.claude-workflows-backup"
chmod u+w "$d/workflows"

# P7 two runs in the same second
hr "P7 same-second reruns"; setenv p7; fake_repo "$B/install-head.sh"
d="$CLAUDE_HOME_DIR"
pty 'n\ny\n' "env -u CLAUDECODE $INSTALL" >/dev/null
pty 'n\ny\n' "env -u CLAUDECODE $INSTALL" >/dev/null
pty 'n\ny\n' "env -u CLAUDECODE $INSTALL" >/dev/null
ls -A "$d/.claude-workflows-backup"

# P8 installed_parent under different wrappers
hr "P8 installed_parent"; setenv p8; fake_repo "$B/install-head.sh"
pty 'n\ny\n' "env -u CLAUDECODE $INSTALL" >/dev/null; grep installed_ "$CLAUDE_HOME_DIR/.claude-workflows-manifest"
pty 'n\ny\n' "cd $ROOT && env -u CLAUDECODE ./devcontainer-config/install.sh" >/dev/null; grep installed_ "$CLAUDE_HOME_DIR/.claude-workflows-manifest"
pty 'n\ny\n' "bash -c 'env -u CLAUDECODE $INSTALL; echo done'" >/dev/null; grep installed_ "$CLAUDE_HOME_DIR/.claude-workflows-manifest"
