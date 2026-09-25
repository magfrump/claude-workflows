#!/usr/bin/env bash
# Pass-3 fact-check probes against install.sh at 516124d.
# Hermetic: temp HOME/TMPDIR, GIT_CONFIG_NOSYSTEM=1, empty GIT_CONFIG_GLOBAL,
# stubbed pgrep/docker, a throwaway fake repo holding a COPY of install.sh.
# Never touches the real ~/.claude or ~/.config.
# Usage: probe-p3.sh <path to install.sh under test>
set -uo pipefail

INSTALL_SRC="$1"
S="$(mktemp -d "${TMPDIR:-/tmp}/q058p3.XXXXXX")"
export HOME="$S/home" TMPDIR="$S/tmp" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$S/empty.gitconfig"
export CLAUDE_HOME_DIR="$HOME/.claude" CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/claude-devcontainer" CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
export SHELL=/bin/bash
unset CLAUDE_CONFIG_DIR CLAUDECODE GIT_DIR GIT_WORK_TREE
mkdir -p "$HOME" "$TMPDIR" "$S/stub"
: > "$GIT_CONFIG_GLOBAL"
REALCP="$(command -v cp)"
STUB="$S/stub"
stub_default() {
  rm -f "$STUB"/*
  printf '#!/bin/bash\nexit 1\n' > "$STUB/pgrep"
  printf '#!/bin/bash\nexit 0\n' > "$STUB/docker"
  chmod +x "$STUB/pgrep" "$STUB/docker"
}
stub_default
BASEPATH="$STUB:$PATH"
export PATH="$BASEPATH"

ROOT="$S/repo"
INSTALL="$ROOT/devcontainer-config/install.sh"
G() { git -c user.email=t@t -c user.name=t "$@"; }
fake_repo() {
  local cfg="$ROOT/devcontainer-config" f
  chmod -R u+w "$S" 2>/dev/null
  rm -rf "$ROOT" "$HOME/.claude" "$HOME/.config" "$HOME/.local"
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
# pty <answers> <cmd...>: run under a pty, answers fed on stdin.
pty() {
  local input="$1"; shift
  # shellcheck disable=SC2016  # expanded by the inner bash
  bash -c 'set -o pipefail; printf "%b" "$1" | script -qec "$2" /dev/null | tr -d "\r"' _ "$input" "$*"
}
# pty_feed <shell snippet> <cmd...>
pty_feed() {
  local feed="$1"; shift
  # shellcheck disable=SC2016  # expanded by the inner bash
  bash -c 'set -o pipefail; { eval "$1"; } | script -qec "$2" /dev/null | tr -d "\r"' _ "$feed" "$*"
}
hdr() { echo; echo "######## $*"; }

echo "== $(date -u +%Y-%m-%dT%H:%M:%SZ) git: $(git --version); install.sh: $INSTALL_SRC ($(wc -l < "$INSTALL_SRC") lines)"

# --- P1: hooks and submodules, with positive controls --------------------------
hdr "P1a .git/hooks + core.hooksPath post-index-change: install vs plain git status"
fake_repo
printf '#!/bin/sh\ntouch "%s/m-default"\n' "$S" > "$ROOT/.git/hooks/post-index-change"
chmod +x "$ROOT/.git/hooks/post-index-change"
rm -f "$S"/m-*
touch -d 2001-01-01 "$ROOT/skills/a/SKILL.md"
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "install --yes rc=$rc blessed=$(grep -c BLESS-STUB "$S/out") hook-ran=$([ -e "$S/m-default" ] && echo yes || echo no)"
touch -d 2002-01-01 "$ROOT/skills/a/SKILL.md"
git -C "$ROOT" status --porcelain >/dev/null
echo "control: plain git status -> hook-ran=$([ -e "$S/m-default" ] && echo yes || echo no)"
mkdir -p "$S/hk"; printf '#!/bin/sh\ntouch "%s/m-hookspath"\n' "$S" > "$S/hk/post-index-change"; chmod +x "$S/hk/post-index-change"
git -C "$ROOT" config core.hooksPath "$S/hk"
touch -d 2003-01-01 "$ROOT/skills/a/SKILL.md"
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "core.hooksPath: install rc=$rc blessed=$(grep -c BLESS-STUB "$S/out") hookspath-ran=$([ -e "$S/m-hookspath" ] && echo yes || echo no)"
touch -d 2004-01-01 "$ROOT/skills/a/SKILL.md"
git -C "$ROOT" status --porcelain >/dev/null
echo "control: plain git status -> hookspath-ran=$([ -e "$S/m-hookspath" ] && echo yes || echo no)"

hdr "P1b the host target (pty, n then y) with the same planted hooks"
fake_repo
printf '#!/bin/sh\ntouch "%s/m-host"\n' "$S" > "$ROOT/.git/hooks/post-index-change"
chmod +x "$ROOT/.git/hooks/post-index-change"
rm -f "$S"/m-*
touch -d 2001-01-01 "$ROOT/skills/a/SKILL.md"
pty 'n\ny\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc installed=$(grep -c 'Installed into' "$S/out") hook-ran=$([ -e "$S/m-host" ] && echo yes || echo no)"

hdr "P1c git hook config support on this git (config-based hooks need git >= 2.54)"
git hook run --ignore-missing post-index-change 2>&1 | head -2; echo "git hook run rc=${PIPESTATUS[0]}"
G -C "$ROOT" config hook.x.command "touch $S/m-cfghook"; G -C "$ROOT" config hook.x.event post-index-change
touch -d 2005-01-01 "$ROOT/skills/a/SKILL.md"
git -C "$ROOT" status --porcelain >/dev/null
echo "plain status with hook.x.command/event: cfghook-ran=$([ -e "$S/m-cfghook" ] && echo yes || echo no) (no = this git ignores config-based hooks)"

# --- P2-R2: post-y link swap changes the hash (host) ---------------------------
hdr "P2 host: h.sh in .cw-new.hooks replaced by a link to identical content at the prompt"
fake_repo
pty 'n\ny\n' bash "$INSTALL" > /dev/null 2>&1
printf 'guide v2\n' > "$ROOT/guides/g.md"; G -C "$ROOT" commit -qam v2
# shellcheck disable=SC2016  # evaluated by pty_feed
feed='printf "n\n"; for _i in $(seq 200); do compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*/installed" >/dev/null && break; sleep 0.1; done; sleep 2
  "$REALCP" "$CLAUDE_HOME_DIR/.cw-new.hooks/h.sh" "$S/same.sh"; ln -sfn "$S/same.sh" "$CLAUDE_HOME_DIR/.cw-new.hooks/h.sh"; printf "y\n"'
export REALCP S
pty_feed "$feed" bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; grep -E 'changed after review|Installed into' "$S/out"
echo "installed h.sh is link: $([ -L "$CLAUDE_HOME_DIR/hooks/h.sh" ] && echo yes || echo no); .cw-new left: $(compgen -G "$CLAUDE_HOME_DIR/.cw-new.*" | wc -l); .cw-stage left: $(compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*" | wc -l)"

# --- P3: cleanup on every exit path; stale stages; planted link ------------------
hdr "P3a stale .cw-stage dir + planted .cw-stage link (to a dir and to a file)"
fake_repo
mkdir -p "$CLAUDE_HOME_DIR/.cw-stage.OLD/payload/sub"; echo x > "$CLAUDE_HOME_DIR/.cw-stage.OLD/payload/sub/f"
mkdir -p "$S/elsewhere"; echo keep > "$S/elsewhere/sentinel"; echo keepf > "$S/elsefile"
ln -s "$S/elsewhere" "$CLAUDE_HOME_DIR/.cw-stage.LD"; ln -s "$S/elsefile" "$CLAUDE_HOME_DIR/.cw-stage.LF"
pty 'n\ny\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc installed=$(grep -c 'Installed into' "$S/out") .cw-stage left: $(compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*" | wc -l) sentinel=$(cat "$S/elsewhere/sentinel") elsefile=$(cat "$S/elsefile")"

for path in decline nothing gitstate sigint sigterm; do
  hdr "P3b exit path: $path"
  fake_repo
  case "$path" in
    decline) pty 'n\nn\n' bash "$INSTALL" > "$S/out" 2>&1 ;;
    nothing) pty 'n\ny\n' bash "$INSTALL" > /dev/null 2>&1; pty 'n\n' bash "$INSTALL" > "$S/out" 2>&1 ;;
    gitstate)
      # The devcontainer target runs git_state_gate first; to reach the host
      # target's gate, plant the key while the devcontainer prompt waits.
      # shellcheck disable=SC2016
      feed='for _i in $(seq 200); do [ -e "$ROOT/devcontainer-config/claude-home/.manifest" ] && break; sleep 0.1; done; sleep 0.5
        git -C "$ROOT" config core.fsmonitor /bin/false; printf "n\n"; sleep 3; printf "y\n"'
      export ROOT
      pty_feed "$feed" bash "$INSTALL" > "$S/out" 2>&1 ;;
    sigint|sigterm)
      sig=INT; [ "$path" = sigterm ] && sig=TERM
      pty 'n\ny\n' bash "$INSTALL" > /dev/null 2>&1
      printf 'guide v3\n' > "$ROOT/guides/g.md"; G -C "$ROOT" commit -qam v3
      # shellcheck disable=SC2016
      feed='printf "n\n"; for _i in $(seq 200); do compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*/installed" >/dev/null && break; sleep 0.1; done; sleep 2
        pkill -'"$sig"' -f "^bash $INSTALL\$"; sleep 1'
      export INSTALL CLAUDE_HOME_DIR
      pty_feed "$feed" bash "$INSTALL" > "$S/out" 2>&1 ;;
  esac
  echo "rc=$? last: $(grep -E 'ERROR|Aborted|Nothing to install|Installed' "$S/out" | tail -1)"
  echo "  .cw-stage left: $(compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*" | wc -l); .cw-new left: $(compgen -G "$CLAUDE_HOME_DIR/.cw-new.*" | wc -l); lock left: $([ -e "$CLAUDE_HOME_DIR/.claude-workflows-lock" ] && echo yes || echo no); dest exists: $([ -e "$CLAUDE_HOME_DIR" ] && echo yes || echo no)"
done

# --- P4: $TMPDIR use by the host target --------------------------------------------
hdr "P4 mktemp calls during a host run (mktemp wrapper logs its args; docker stub present)"
fake_repo
printf '#!/bin/bash\necho "mktemp $*" >> "%s/mktemp.log"\nexec /usr/bin/mktemp "$@"\n' "$S" > "$STUB/mktemp"; chmod +x "$STUB/mktemp"
rm -f "$S/mktemp.log"
pty 'n\ny\n' bash "$INSTALL" > "$S/out" 2>&1; echo "rc=$? installed=$(grep -c 'Installed into' "$S/out")"
sed "s|$S|\$S|g" "$S/mktemp.log"
stub_default

# --- P5: unwritable destination -------------------------------------------------
hdr "P5 unwritable destination, nothing would change"
fake_repo
pty 'n\ny\n' bash "$INSTALL" > /dev/null 2>&1
chmod a-w "$CLAUDE_HOME_DIR"
pty 'n\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc (pty pipeline rc is install.sh's)"; grep -A2 'could not create' "$S/out"
grep -c 'Nothing to install' "$S/out" | sed 's/^/"Nothing to install" lines: /'
chmod u+w "$CLAUDE_HOME_DIR"
hdr "P5b unwritable parent, destination absent"
fake_repo
mkdir -p "$S/ro"; chmod a-w "$S/ro"
CLAUDE_HOME_DIR="$S/ro/claude" pty 'n\n' env CLAUDE_HOME_DIR="$S/ro/claude" bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; grep 'could not create' "$S/out"
chmod u+w "$S/ro"

# --- P6: the remedy command ---------------------------------------------------------
hdr "P6 git config --file <file> --unset-all <key> for each refused shape"
fake_repo
G -C "$ROOT" config extensions.worktreeConfig true
G -C "$ROOT" config --worktree filter.WT.clean cat
G -C "$ROOT" config --add include.path /nonexistent/a
G -C "$ROOT" config --add include.path /nonexistent/b
G -C "$ROOT" config 'includeIf.gitdir:/nowhere/.path' /nonexistent/c
G -C "$ROOT" config filter.lfs.smudge 'git-lfs smudge -- %f'
G -C "$ROOT" config filter.lfs.required true
G -C "$ROOT" config core.fsmonitor /bin/false
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "install rc=$rc; refusal lists:"; grep -E '^ +/.*: ' "$S/out" | sed "s|$S|\$S|g"
grep -A5 'Check each one' "$S/out"
while IFS= read -r l; do
  f="${l%%: *}"; f="${f#"${f%%[! ]*}"}"; kv="${l#*: }"; k="${kv%% *}"
  rc=0; git config --file "$f" --unset-all "$k" || rc=$?
  echo "git config --file ${f/#$S/\$S} --unset-all $k -> rc=$rc"
done < <(grep -E '^ +/.*: ' "$S/out")
echo "old remedy for comparison (git config --local --unset include.path) on a fresh multi-valued key:"
G -C "$ROOT" config --add include.path /x/1; G -C "$ROOT" config --add include.path /x/2
rc=0; git -C "$ROOT" config --local --unset include.path || rc=$?; echo "  rc=$rc"
git -C "$ROOT" config --local --unset-all include.path
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "rerun after the remedies: rc=$rc blessed=$(grep -c BLESS-STUB "$S/out")"

# --- P7: NOTE count with docker absent -----------------------------------------------
hdr "P7 NOTE lines per run with docker absent"
farm="$S/farm"; mkdir -p "$farm"
IFS=: read -ra dirs <<< "$PATH"
for d in "${dirs[@]}"; do [ "$d" = "$STUB" ] || [ ! -d "$d" ] && continue; ln -s "$d"/* "$farm/" 2>/dev/null; done
rm -f "$farm/docker"; rm -f "$STUB/docker"
export PATH="$STUB:$farm"
command -v docker >/dev/null && echo "docker still on PATH!" || echo "docker absent"
count() { grep -c '^NOTE: docker not found' "$S/out"; }
fake_repo; bash "$INSTALL" </dev/null > "$S/out" 2>&1; echo "closed stdin (decline dc, host skipped): NOTEs=$(count) progress=$(grep -c '^Checking for running' "$S/out")"
fake_repo; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1; echo "--yes: NOTEs=$(count)"
fake_repo; pty 'n\nn\n' bash "$INSTALL" > "$S/out" 2>&1; echo "pty n,n: NOTEs=$(count)"
fake_repo; pty 'n\ny\n' bash "$INSTALL" > "$S/out" 2>&1; echo "pty n,y: NOTEs=$(count)"
fake_repo; pty 'y\ny\n' bash "$INSTALL" > "$S/out" 2>&1; echo "pty y,y: NOTEs=$(count) installed=$(grep -c 'Installed into' "$S/out")"
export PATH="$BASEPATH"; stub_default
fake_repo; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1; echo "docker stub present, --yes: progress lines=$(grep -c '^Checking for running' "$S/out") NOTEs=$(grep -c '^NOTE' "$S/out")"

# --- P8: vis failure inside mode_diff ----------------------------------------------------
hdr "P8 perl (vis) fails only on a MODE line; the change is a chmod only"
fake_repo
pty 'n\ny\n' bash "$INSTALL" > /dev/null 2>&1
chmod +x "$ROOT/guides/g.md"; G -C "$ROOT" commit -qam mode
realperl="$(command -v perl)"
printf '#!/bin/bash\nin="$(cat; echo x)"; in="${in%%x}"\ncase "$in" in MODE*) exit 3;; esac\nprintf "%%s" "$in" | %s "$@"\n' "$realperl" > "$STUB/perl"; chmod +x "$STUB/perl"
pty 'n\nn\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; sed -n '/Host target/,$p' "$S/out" | sed "s|$S|\$S|g"
stub_default

# --- P9: links_in's own failure after the devcontainer copy -------------------------------
hdr "P9 devcontainer: find fails inside links_in after the copy (unreadable dir planted during cp)"
fake_repo
bash "$INSTALL" --yes </dev/null > /dev/null 2>&1
printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"; G -C "$ROOT" commit -qam v2
printf '#!/bin/bash\n%s "$@" || exit\ncase "${@: -1}" in */claude-devcontainer/cc-isolated.sh) echo "echo TAMPERED" >> "${@: -1}";; */claude-devcontainer/egress) mkdir -p "${@: -1}/locked" && chmod 000 "${@: -1}/locked";; esac\n' "$REALCP" > "$STUB/cp"
chmod +x "$STUB/cp"
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "rc=$rc"; sed "s|$S|\$S|g" "$S/out" | grep -vE '^(NOTE|Checking|Canonical|Installed|===|$)' | tail -8
echo "cc-isolated.sh left in DEST: $([ -e "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ] && echo yes || echo no); TAMPERED in it: $(grep -c TAMPERED "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" 2>/dev/null); bin link resolves: $([ -e "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ] && echo yes || echo no)"
chmod -R u+rwx "$CLAUDE_DEVC_CONFIG_DIR" 2>/dev/null
stub_default

echo; echo "== done $(date -u +%Y-%m-%dT%H:%M:%SZ); probe dir: $S"
chmod -R u+w "$S" 2>/dev/null
rm -rf "$S"
