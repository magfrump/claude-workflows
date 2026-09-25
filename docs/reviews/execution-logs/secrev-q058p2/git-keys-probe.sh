#!/usr/bin/env bash
# Which command-running git config keys do install.sh's own git invocations
# (rev-parse, cat-file, archive --format=tar to a pipe, status --porcelain into
# $(...)) honour? Hermetic: temp HOME, empty global config, no system config.
# Writes git-keys-probe.log next to this script.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$(mktemp -d "${TMPDIR:-/tmp}/gitkeys.XXXXXX")"
export HOME="$P/home" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$P/empty"
mkdir -p "$HOME"; : > "$GIT_CONFIG_GLOBAL"
G() { git -c user.email=t@t -c user.name=t "$@"; }
mark() {
  printf '#!/bin/sh\necho %s >> "%s/marks"\ncat >/dev/null 2>&1\nexit 0\n' "$1" "$P" > "$P/$1.sh"
  chmod +x "$P/$1.sh"
}
{
  git --version
  git init -q "$P/r"; cd "$P/r"
  echo a > a.txt; G add .; G commit -qm i
  for k in ext pager pst par tconv; do mark "$k"; done
  git config diff.external "$P/ext.sh"
  git config core.pager "$P/pager.sh"
  git config pager.status "$P/pst.sh"
  git config pager.archive "$P/par.sh"
  git config diff.x.textconv "$P/tconv.sh"
  git config gc.auto 1
  git config alias.status "!echo alias-ran >> $P/marks"
  echo 'a.txt diff=x' > .gitattributes; G add .gitattributes; G commit -qm attrs
  sleep 1; echo b >> a.txt
  out="$(git -c core.quotePath=true -c core.fsmonitor=false status --porcelain --untracked-files=all -- a.txt)"
  echo "status: $out"
  git -c tar.umask=022 archive --format=tar HEAD -- a.txt | tar -tf - >/dev/null
  git rev-parse --verify -q 'HEAD^{commit}' >/dev/null
  git cat-file -e HEAD:a.txt
  echo "keys set: diff.external core.pager pager.status pager.archive diff.x.textconv gc.auto alias.status"
  echo "marks after the installer's invocations: $(cat "$P/marks" 2>/dev/null || echo none)"
  # Now the hook routes the gate does not check.
  git config --unset diff.external
  printf '#!/bin/sh\necho post-index-change-default >> "%s/marks"\n' "$P" > .git/hooks/post-index-change
  chmod +x .git/hooks/post-index-change
  # A stat-only change (content equal to the index): status refreshes the
  # entry and rewrites the index, which fires post-index-change.
  git checkout -q -- a.txt
  sleep 1; touch a.txt
  git -c core.quotePath=true -c core.fsmonitor=false status --porcelain --untracked-files=all -- a.txt >/dev/null
  echo "marks after status with .git/hooks/post-index-change: $(tr '\n' ' ' < "$P/marks")"
  gate="$(git config --file .git/config --no-includes --get-regexp '^(filter\.|core\.fsmonitor|include)' || true)"
  echo "install.sh's GIT_EXEC_KEYS_RE over .git/config finds: '${gate}'"
} > "$here/git-keys-probe.log" 2>&1
rm -rf "$P"
cat "$here/git-keys-probe.log"
