#!/usr/bin/env bash
# Old remedy `git config --local --unset <key>` vs new `--file <f> --unset-all` for a config.worktree key.
set -uo pipefail
T="$(mktemp -d "${TMPDIR:-/tmp}/oldrem.XXXXXX")"
export HOME="$T/h" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$T/empty"; mkdir -p "$HOME"; : > "$GIT_CONFIG_GLOBAL"
git init -q "$T/r"
git -C "$T/r" config extensions.worktreeConfig true
git -C "$T/r" config --worktree filter.pwn.clean cat
git -C "$T/r" config --local --unset filter.pwn.clean; echo "old: --local --unset -> rc=$?"
git -C "$T/r" config --file "$T/r/.git/config.worktree" --unset-all filter.pwn.clean; echo "new: --file config.worktree --unset-all -> rc=$?"
rm -rf "$T"
