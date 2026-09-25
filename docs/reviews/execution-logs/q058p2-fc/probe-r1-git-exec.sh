#!/usr/bin/env bash
# Probe R1 (24ce814): which checkout git state still makes install.sh's git
# calls run a command? Hermetic: temp HOME, no system/global git config,
# stubbed pgrep/docker, a throwaway fake repo (same shape as
# test/install-host.bats fake_repo), all destinations under a temp dir.
# Usage: probe-r1-git-exec.sh <path to install.sh under test>
set -uo pipefail

INSTALL_SRC="$1"
S="$(mktemp -d "${TMPDIR:-/tmp}/q058p2-r1.XXXXXX")"
export HOME="$S/home" TMPDIR="$S/tmp" GIT_CONFIG_NOSYSTEM=1
export CLAUDE_HOME_DIR="$HOME/.claude" CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/cd" CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
unset CLAUDE_CONFIG_DIR CLAUDECODE GIT_DIR GIT_WORK_TREE
mkdir -p "$HOME" "$TMPDIR" "$S/stub" "$S/m"
printf '#!/bin/bash\nexit 1\n' > "$S/stub/pgrep"
printf '#!/bin/bash\nexit 0\n' > "$S/stub/docker"
chmod +x "$S/stub/pgrep" "$S/stub/docker"
export PATH="$S/stub:$PATH"

ROOT="$S/repo"
fake_repo() {
  local cfg="$ROOT/devcontainer-config" f
  rm -rf "$ROOT" "$S/wt" "$CLAUDE_DEVC_CONFIG_DIR"
  mkdir -p "$cfg/egress" "$ROOT/global-instructions" "$ROOT/skills/a" "$ROOT/workflows" \
           "$ROOT/guides" "$ROOT/patterns" "$ROOT/hooks/lib" "$ROOT/scripts"
  cp "$INSTALL_SRC" "$cfg/install.sh"
  printf 'g\n' > "$ROOT/global-instructions/CLAUDE.md"
  printf 's\n' > "$ROOT/skills/a/SKILL.md"
  for f in workflows/w.md guides/g.md patterns/p.md hooks/h.sh hooks/lib/x.sh hooks/wiring.json scripts/s.sh; do
    printf 'x\n' > "$ROOT/$f"
  done
  for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py link-claude-home.sh; do
    printf 'stub %s\n' "$f" > "$cfg/$f"
  done
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$cfg/cc-isolated.sh"
  chmod +x "$cfg/cc-isolated.sh"
  printf 'api.anthropic.com\n' > "$cfg/egress/base.txt"
  printf 'devcontainer-config/claude-home/\n' > "$ROOT/.gitignore"
  git -C "$ROOT" init -q
  git -C "$ROOT" add -A
  git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m init
}
marker() {  # marker <name>: print the path of a command that touches $S/m/<name>
  printf '#!/bin/sh\ntouch "%s/m/%s"\ncat 2>/dev/null\nexit 0\n' "$S" "$1" > "$S/$1.sh"
  chmod +x "$S/$1.sh"
  printf '%s' "$S/$1.sh"
}
run_install() {  # run_install <label> [install.sh path]
  local inst="${2:-$ROOT/devcontainer-config/install.sh}" rc=0
  rm -f "$S/m/"*
  # Make the index stale under a payload path, so status refreshes and writes it.
  sleep 1.1; touch "$ROOT/hooks/h.sh"
  bash "$inst" --yes </dev/null > "$S/out.txt" 2>&1 || rc=$?
  echo "### $1: install.sh exit $rc; refused-by-gate: $(grep -c "git state can make git run" "$S/out.txt"); blessed: $(grep -c BLESS-STUB "$S/out.txt")"
  echo "    markers fired: $(find "$S/m" -mindepth 1 -printf '%f ')"
  grep -E '^ERROR|: (core|filter|include)|attributes' "$S/out.txt" | sed 's/^/    | /'
}

echo "== git $(git --version)"

# A. The default hooks dir: post-index-change (runs when git writes the index).
fake_repo
cp "$(marker hook-post-index-change)" "$ROOT/.git/hooks/post-index-change"
run_install "A .git/hooks/post-index-change"

# B. core.hooksPath pointing at a dir with post-index-change.
fake_repo
mkdir -p "$S/hk"; cp "$(marker hookspath-pic)" "$S/hk/post-index-change"
git -C "$ROOT" config core.hooksPath "$S/hk"
run_install "B core.hooksPath=<dir with post-index-change>"

# C. Keys outside GIT_EXEC_KEYS_RE that name commands, one fresh repo each
#    (none should be reachable by rev-parse/config/cat-file/archive/status).
for kv in diff.external core.pager pager.status pager.archive core.sshCommand \
          gpg.program uploadpack.packObjectsHook credential.helper core.askPass \
          core.editor tar.tar.command diff.x.textconv core.alternateRefsCommand \
          sequence.editor core.gitProxy; do
  fake_repo
  git -C "$ROOT" config "$kv" "$(marker "key-$kv")"
  [ "$kv" = diff.x.textconv ] && { printf '*.md diff=x\n' > "$ROOT/.gitattributes"; git -C "$ROOT" add .gitattributes; git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m a; }
  run_install "C $kv"
done
fake_repo
git -C "$ROOT" config url."ext::$(marker url-ext) %s".insteadOf "$ROOT"
git -C "$ROOT" config protocol.ext.allow always
run_install "C url.<ext>.insteadOf + protocol.ext.allow"
fake_repo
git -C "$ROOT" config log.showSignature true
git -C "$ROOT" config gpg.program "$(marker gpg-with-showsig)"
run_install "C log.showSignature + gpg.program"

# D. config.worktree with extensions.worktreeConfig, main worktree.
fake_repo
git -C "$ROOT" config extensions.worktreeConfig true
git -C "$ROOT" config --worktree core.fsmonitor "$(marker wtcfg-fsmonitor-main)"
run_install "D config.worktree (main worktree) core.fsmonitor"
git -C "$ROOT" config --worktree --unset core.fsmonitor
git -C "$ROOT" config --worktree filter.pwn.smudge "$(marker wtcfg-smudge-main)"
printf '*.md filter=pwn\n' > "$ROOT/.gitattributes"; git -C "$ROOT" add .gitattributes
git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m attrs
run_install "D2 config.worktree (main) filter.pwn.smudge + committed .gitattributes"

# E. config.worktree of a linked worktree.
fake_repo
git -C "$ROOT" worktree add -q "$S/wt" 2>/dev/null
git -C "$ROOT" config extensions.worktreeConfig true
git -C "$S/wt" config --worktree core.fsmonitor "$(marker wtcfg-fsmonitor-linked)"
echo "    linked config.worktree: $(git -C "$S/wt" rev-parse --git-path config.worktree)"
run_install "E config.worktree (linked worktree) core.fsmonitor, run from the linked worktree" "$S/wt/devcontainer-config/install.sh"

# F. Committed .gitattributes + a local filter (refused?) vs. no local filter.
fake_repo
printf '*.md filter=pwn\n' > "$ROOT/.gitattributes"; git -C "$ROOT" add .gitattributes
git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m attrs
git -C "$ROOT" config filter.pwn.smudge "$(marker committed-attrs-smudge)"
run_install "F committed .gitattributes + local filter.pwn.smudge"

# G. Positive control: the refused keys still refused (T65/T66 shapes).
fake_repo
git -C "$ROOT" config core.fsmonitor "$(marker control-fsmonitor)"
run_install "G control: local core.fsmonitor"

echo "== probe dir: $S"
