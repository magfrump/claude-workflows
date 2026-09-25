#!/usr/bin/env bash
# Pass-4 fact-check probes against install.sh at f5e3029 (or any version given).
# Hermetic: temp HOME/TMPDIR, GIT_CONFIG_NOSYSTEM=1, a temp GIT_CONFIG_GLOBAL,
# stubbed pgrep/docker, a throwaway fake repo holding a COPY of install.sh.
# Never touches the real ~/.claude or ~/.config.
# Usage: probe-p4.sh <path to install.sh under test>
set -uo pipefail

INSTALL_SRC="$1"
S="$(mktemp -d "${TMPDIR:-/tmp}/q058p4.XXXXXX")"
export HOME="$S/home" TMPDIR="$S/tmp" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$S/global.gitconfig"
export CLAUDE_HOME_DIR="$HOME/.claude" CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/claude-devcontainer" CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
export SHELL=/bin/bash
unset CLAUDE_CONFIG_DIR CLAUDECODE GIT_DIR GIT_WORK_TREE
mkdir -p "$HOME" "$TMPDIR" "$S/stub"
: > "$GIT_CONFIG_GLOBAL"
REALCP="$(command -v cp)"
STUB="$S/stub"
export S REALCP
stub_default() {
  rm -f "$STUB"/*
  printf '#!/bin/bash\nexit 1\n' > "$STUB/pgrep"
  printf '#!/bin/bash\nexit 0\n' > "$STUB/docker"
  chmod +x "$STUB/pgrep" "$STUB/docker"
}
stub_default
export PATH="$STUB:$PATH"

ROOT="$S/repo"
INSTALL="$ROOT/devcontainer-config/install.sh"
G() { git -c user.email=t@t -c user.name=t "$@"; }
fake_repo() {
  local cfg="$ROOT/devcontainer-config" f
  chmod -R u+rwx "$S" 2>/dev/null
  rm -rf "$ROOT" "$HOME/.claude" "$HOME/.config" "$HOME/.local" "${TMPDIR:?}"/*
  : > "$GIT_CONFIG_GLOBAL"
  mkdir -p "$cfg/egress" "$ROOT/global-instructions" "$ROOT/skills/a" "$ROOT/workflows" \
           "$ROOT/guides" "$ROOT/patterns" "$ROOT/hooks/lib" "$ROOT/scripts"
  "$REALCP" "$INSTALL_SRC" "$cfg/install.sh"
  printf 'g\n' > "$ROOT/global-instructions/CLAUDE.md"
  printf 'skill a\n' > "$ROOT/skills/a/SKILL.md"
  for f in workflows/w.md guides/g.md patterns/p.md hooks/lib/x.sh hooks/wiring.json scripts/s.sh; do
    printf 'x\n' > "$ROOT/$f"
  done
  printf '#!/bin/bash\nexit 0\n' > "$ROOT/hooks/h.sh"
  for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py link-claude-home.sh; do
    printf 'stub %s\n' "$f" > "$cfg/$f"
  done
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$cfg/cc-isolated.sh"
  chmod +x "$cfg/cc-isolated.sh"
  printf 'api.anthropic.com\n' > "$cfg/egress/base.txt"
  printf 'devcontainer-config/claude-home/\n' > "$ROOT/.gitignore"
  git -C "$ROOT" init -q
  G -C "$ROOT" add -A
  G -C "$ROOT" commit -q -m init
}
# stub_cp <case-pattern> <shell>: real cp, then the snippet when the last
# argument matches (dst = last argument, srcarg = the one before it).
stub_cp() {
  printf '#!/bin/bash\n"%s" "$@" || exit\ndst="${@: -1}"; srcarg="${@: -2:1}"\ncase "$dst" in %s) %s ;; esac\nexit 0\n' \
    "$REALCP" "$1" "$2" > "$STUB/cp"
  chmod +x "$STUB/cp"
}
# pty <answers> <cmd...>: run under a pty, answers fed on stdin.
pty() {
  local input="$1"; shift
  # shellcheck disable=SC2016  # expanded by the inner bash
  bash -c 'set -o pipefail; printf "%b" "$1" | script -qec "$2" /dev/null | tr -d "\r"' _ "$input" "$*"
}
hdr() { echo; echo "######## $*"; }
show() { sed "s|$S|\$S|g" "$S/out" | grep -vE '^[-+@ ]|^diff |^=+$|^$' | tail -n "${1:-12}"; }
launcher_state() {
  echo "  DEST cc-isolated.sh: $([ -e "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ] && echo present || echo absent);" \
       "DEST items left: $(ls -A "$CLAUDE_DEVC_CONFIG_DIR" 2>/dev/null | tr '\n' ' ');" \
       "TAMPERED live: $(grep -rls TAMPERED "$CLAUDE_DEVC_CONFIG_DIR" 2>/dev/null | wc -l);" \
       "blessed: $(grep -c BLESS-STUB "$S/out")"
}

echo "== $(date -u +%Y-%m-%dT%H:%M:%SZ) git: $(git --version); find: $(find --version | head -1); install.sh: $INSTALL_SRC ($(wc -l < "$INSTALL_SRC") lines)"

# --- A: case of git config keys vs GIT_EXEC_KEYS_RE ------------------------------
hdr "A1 mixed-case hook/filter/fsmonitor/include keys written raw into .git/config"
fake_repo
cat >> "$ROOT/.git/config" <<'EOF'
[Hook "MixedSub"]
	Command = /bin/true
	EVENT = post-index-change
[HOOK "x"]
	command = /bin/true
[Filter "Y"]
	Smudge = cat
[Core]
	FsMonitor = /bin/false
[IncludeIf "gitdir:/nowhere/"]
	Path = /nonexistent
EOF
echo "raw get-regexp output (the gate's own read):"
git --no-pager -c core.hooksPath=/dev/null config --file "$ROOT/.git/config" --no-includes \
  --get-regexp '^(filter\.|core\.fsmonitor|include|hook\.)' | sed 's/^/  /'
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "install --yes rc=$rc; refusal lists:"; grep -E '^ +/.*: ' "$S/out" | sed "s|$S|\$S|g"
grep -A1 'install (a filter' "$S/out" | sed 's/^/  msg| /'
hdr "A2 hook.* only (lowercase, as T84) + a harmless hooks.* key, which must not match"
fake_repo
G -C "$ROOT" config hooks.allowunannotated true
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "hooks.allowunannotated alone: rc=$rc blessed=$(grep -c BLESS-STUB "$S/out")"

# --- B: find failure (unreadable dir) at each links_in site -----------------------
hdr "B1 stage site: stage/egress made unreadable during the mirror cp (first install, --yes)"
fake_repo
# shellcheck disable=SC2016  # expanded inside the stub
stub_cp '*/devcontainer-config/claude-home/' 'chmod 000 "${srcarg%/claude-home/.}/egress"'
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "rc=$rc"; show 8; launcher_state
stub_default

hdr "B2a DEST site: DEST/egress (non-empty) made unreadable right after its copy; cc-isolated.sh tampered as it lands (reinstall, --yes)"
fake_repo
bash "$INSTALL" --yes </dev/null > /dev/null 2>&1
printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"; G -C "$ROOT" commit -qam v2
# shellcheck disable=SC2016
stub_cp '*/claude-devcontainer/cc-isolated.sh) echo "echo TAMPERED" >> "$dst";; */claude-devcontainer/egress' 'chmod 000 "$dst"'
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "rc=$rc"; show 8; launcher_state
echo "  ERROR line printed: $(grep -c '^ERROR' "$S/out"); 'removed again' printed: $(grep -c 'removed again' "$S/out")"
echo "  ~/.local/bin/cc-isolated resolves: $([ -e "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ] && echo yes || echo no)"
stub_default

hdr "B2b DEST site: an EMPTY unreadable dir added under DEST/claude-home after its copy (reinstall, --yes)"
fake_repo
bash "$INSTALL" --yes </dev/null > /dev/null 2>&1
printf '{"v":3}\n' > "$ROOT/devcontainer-config/devcontainer.json"; G -C "$ROOT" commit -qam v3
# shellcheck disable=SC2016
stub_cp '*/claude-devcontainer/claude-home' 'mkdir "$dst/zz"; chmod 000 "$dst/zz"'
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "rc=$rc"; show 8; launcher_state
stub_default

hdr "B3 host site: .cw-new.guides (non-empty) made unreadable right after its copy (pty, n then y)"
fake_repo
# shellcheck disable=SC2016
stub_cp '*/.claude/.cw-new.guides' 'chmod 000 "$dst"'
pty 'n\ny\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; show 8
echo "  installed: $(grep -c 'Installed into' "$S/out"); .cw-new left: $(compgen -G "$CLAUDE_HOME_DIR/.cw-new.*" | wc -l); lock left: $([ -e "$CLAUDE_HOME_DIR/.claude-workflows-lock" ] && echo yes || echo no)"
stub_default
hdr "B3b the next run after B3 (the unreadable .cw-new.guides is still there)"
pty 'n\ny\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; show 6
stub_default

# --- C: a MISSING item at each site: what catches it -----------------------------
hdr "C1a host site, reinstall: .cw-new.guides removed right after its copy (pty, n then y)"
fake_repo
pty 'n\ny\n' bash "$INSTALL" > /dev/null 2>&1
printf 'guide v2\n' > "$ROOT/guides/g.md"; G -C "$ROOT" commit -qam v2
# shellcheck disable=SC2016
stub_cp '*/.claude/.cw-new.guides' 'rm -rf "$dst"'
pty 'n\ny\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; show 8
echo "  reached prompt: $(grep -c 'Install these files' "$S/out"); installed: $(grep -c 'Installed into' "$S/out"); guides still installed: $([ -e "$CLAUDE_HOME_DIR/guides/g.md" ] && echo yes || echo no)"
stub_default

hdr "C1b host site, first install: .cw-new.guides removed right after its copy"
fake_repo
# shellcheck disable=SC2016
stub_cp '*/.claude/.cw-new.guides' 'rm -rf "$dst"'
pty 'n\ny\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; show 8
echo "  reached prompt: $(grep -c 'Install these files' "$S/out"); installed: $(grep -c 'Installed into' "$S/out")"
stub_default

hdr "C1c host site, reinstall: .cw-new.guides removed after the prompt (writer acts at the y) -> hash check?"
fake_repo
pty 'n\ny\n' bash "$INSTALL" > /dev/null 2>&1
printf 'guide v3\n' > "$ROOT/guides/g.md"; G -C "$ROOT" commit -qam v3
export CLAUDE_HOME_DIR
# shellcheck disable=SC2016
feed='printf "n\n"; for _i in $(seq 200); do compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*/installed" >/dev/null && break; sleep 0.1; done; sleep 2
  rm -rf "$CLAUDE_HOME_DIR/.cw-new.guides"; printf "y\n"'
bash -c 'set -o pipefail; { eval "$1"; } | script -qec "$2" /dev/null | tr -d "\r"' _ "$feed" "bash $INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; show 6

hdr "C2a stage site, first install: stage/egress removed during the mirror cp (--yes)"
fake_repo
# shellcheck disable=SC2016
stub_cp '*/devcontainer-config/claude-home/' 'rm -rf "${srcarg%/claude-home/.}/egress"'
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "rc=$rc"; show 6; launcher_state
stub_default

hdr "C2b stage site, reinstall: stage/egress removed during the mirror cp (--yes)"
fake_repo
bash "$INSTALL" --yes </dev/null > /dev/null 2>&1
printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"; G -C "$ROOT" commit -qam v2
# shellcheck disable=SC2016
stub_cp '*/devcontainer-config/claude-home/' 'rm -rf "${srcarg%/claude-home/.}/egress"'
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "rc=$rc"; show 6; launcher_state
stub_default

# --- D: the NOTE / progress lines (037:33, plan:253) ------------------------------
hdr "D docker absent / unreachable / reachable: lines per check (--yes, one check at startup, one after y)"
fake_repo
for mode in reachable unreachable absent; do
  case "$mode" in
    reachable) stub_default ;;
    unreachable) printf '#!/bin/bash\necho "cannot connect" >&2\nexit 1\n' > "$STUB/docker"; chmod +x "$STUB/docker" ;;
    absent) rm -f "$STUB/docker" ;;
  esac
  rm -rf "$HOME/.config" "$HOME/.local"
  if [ "$mode" = absent ]; then
    # hide any real docker on PATH
    mkdir -p "$S/nodocker"; for d in ${PATH//:/ }; do for e in "$d"/*; do
      b="${e##*/}"; [ "$b" = docker ] || [ -e "$S/nodocker/$b" ] || ln -s "$e" "$S/nodocker/$b" 2>/dev/null; done; done
    rc=0; PATH="$S/nodocker" bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
  else
    rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
  fi
  echo "$mode: rc=$rc progress=$(grep -c '^Checking for running cc-isolated' "$S/out") NOTE=$(grep -c '^NOTE: docker' "$S/out")"
  grep -nE '^(Checking for running|NOTE: docker)' "$S/out" | sed 's/^/    /'
done
stub_default

# --- E: 037's P3-1 residual: a global filter driver + a committed .gitattributes --
hdr "E global filter.g.smudge in GIT_CONFIG_GLOBAL + committed .gitattributes: does the install run it?"
fake_repo
printf '#!/bin/bash\ntouch "%s/global-smudge-ran"\ncat\n' "$S" > "$S/gsmudge.sh"; chmod +x "$S/gsmudge.sh"
printf '*.md filter=g\n' > "$ROOT/.gitattributes"; G -C "$ROOT" add .gitattributes; G -C "$ROOT" commit -qm attrs
rm -f "$S/global-smudge-ran"
git config --file "$GIT_CONFIG_GLOBAL" filter.g.smudge "$S/gsmudge.sh"
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "rc=$rc blessed=$(grep -c BLESS-STUB "$S/out") global-smudge-ran=$([ -e "$S/global-smudge-ran" ] && echo yes || echo no)"

chmod -R u+rwx "$S" 2>/dev/null
rm -rf "$S"
echo; echo "== done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
