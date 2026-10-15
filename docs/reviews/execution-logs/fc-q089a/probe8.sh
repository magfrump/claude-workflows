#!/usr/bin/env bash
set -u; export LC_ALL=C
E=/home/node/.claude/jobs/00bcf178/tmp/fc-q089A.jPV8xH
W="$E/w8"; rm -rf "$W"; mkdir -p "$W" || exit 1; cd "$W" || exit 1
export HOME="$W/home"; mkdir -p "$HOME"; unset CLAUDE_DEVC_CONFIG_DIR
d="$W/inst"; mkdir -p "$d"; cp "$E/A/devcontainer-config/cc-push.sh" "$E/A/devcontainer-config/cc-gitdir.sh" "$d/"
(cd "$d" && sha256sum cc-gitdir.sh cc-push.sh > host-tools.sha256)
bash "$d/cc-push.sh" --help >/dev/null 2>&1; echo "P8a clean installed cc-push --help rc=$?"
printf '\n# appended\n' >> "$d/cc-push.sh"
bash "$d/cc-push.sh" --help 2>&1 | head -1; echo "P8b self-edited cc-push --help rc=${PIPESTATUS[0]}"
