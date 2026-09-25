#!/usr/bin/env bash
# T85's shape (claude-home removed right after its copy into DEST; cc-isolated.sh
# tampered as it lands) against 516124d's and f5e3029's install.sh: is an
# ERROR line printed, and does the tampered launcher stay live?
# Hermetic: temp HOME/TMPDIR, empty global git config, stubbed pgrep/docker/cp.
# Usage: t85-shape-old.sh <repo>
set -uo pipefail
repo="$1"
for rev in 516124d f5e3029; do
  S="$(mktemp -d "${TMPDIR:-/tmp}/t85old.XXXXXX")"
  (
    export HOME="$S/home" TMPDIR="$S/tmp" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$S/g"
    export CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/claude-devcontainer" CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
    unset CLAUDECODE CLAUDE_CONFIG_DIR
    : > "$S/g"; mkdir -p "$HOME" "$TMPDIR" "$S/stub" "$S/repo"
    git -C "$repo" archive "$rev" devcontainer-config global-instructions skills workflows guides patterns hooks scripts .gitignore | tar -x -C "$S/repo"
    git -C "$S/repo" init -q; git -C "$S/repo" -c user.email=t@t -c user.name=t add -A
    git -C "$S/repo" -c user.email=t@t -c user.name=t commit -qm init
    printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$S/repo/devcontainer-config/cc-isolated.sh"
    git -C "$S/repo" -c user.email=t@t -c user.name=t commit -qam stub
    printf '#!/bin/bash\nexit 1\n' > "$S/stub/pgrep"; printf '#!/bin/bash\nexit 0\n' > "$S/stub/docker"
    chmod +x "$S/stub/pgrep" "$S/stub/docker"
    export PATH="$S/stub:$PATH"
    bash "$S/repo/devcontainer-config/install.sh" --yes </dev/null > /dev/null 2>&1
    printf '{"v":2}\n' > "$S/repo/devcontainer-config/devcontainer.json"
    git -C "$S/repo" -c user.email=t@t -c user.name=t commit -qam v2
    # shellcheck disable=SC2016  # expanded by the stub
    printf '#!/bin/bash\n%s "$@" || exit\ncase "${@: -1}" in */claude-devcontainer/cc-isolated.sh) echo "echo TAMPERED-LAUNCHER" >> "${@: -1}";; */claude-devcontainer/claude-home) rm -rf "${@: -1}";; esac\n' \
      "$(command -v cp)" > "$S/stub/cp"; chmod +x "$S/stub/cp"
    rc=0; bash "$S/repo/devcontainer-config/install.sh" --yes </dev/null > "$S/out" 2>&1 || rc=$?
    echo "== $rev: rc=$rc ERROR-lines=$(grep -c '^ERROR' "$S/out") blessed=$(grep -c BLESS-STUB "$S/out")" \
         "launcher-tampered-live=$(grep -ls TAMPERED-LAUNCHER "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" 2>/dev/null | wc -l)" \
         "bin-link-resolves=$([ -e "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ] && echo yes || echo no)"
    grep -vE 'setlocale' "$S/out" | tail -n 3 | sed "s|$S|\$S|g; s/^/    /"
  )
  chmod -R u+rwx "$S"; rm -rf "$S"
done
