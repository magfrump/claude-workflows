#!/usr/bin/env bash
# P1: a stray cc-push.sh.orig is gated as a host tool. P2: an unstaged rename via
# intent-to-add under commit -a, with and without --no-renames. $1 = probe root.
D="$1"
case "$D" in /home/node/.claude/jobs/00bcf178/tmp/fc-it2.*) ;; *) echo "bad D"; exit 1 ;; esac
export HOME="$D/home" LC_ALL=C
G="$D/src/hooks/live-verify-gate.sh"
pl() { jq -n -c --arg c "$1" '{"tool_name":"Bash","tool_input":{"command":$c}}'; }
rm -rf "$D/p2"; mkdir -p "$D/p2/devcontainer-config/egress"; cd "$D/p2" || exit 1
git init -q; git config user.email t@e; git config user.name t
echo base > devcontainer-config/egress/base.txt
echo 'echo p' > devcontainer-config/cc-push.sh
git add -A; git -c commit.gpgsign=false commit -qm i
echo "start: $(date -u +%FT%TZ) cwd: $PWD $(git --version)"
echo '## P1 stray cc-push.sh.orig staged, no trailer then Host-tool-tested'
echo x > devcontainer-config/cc-push.sh.orig; git add devcontainer-config/cc-push.sh.orig
timeout 20 bash "$G" <<< "$(pl 'git commit -m x')"; echo "exit=$?"
timeout 20 bash "$G" <<< "$(pl 'git commit -m x -m "Host-tool-tested: no - t"')"; echo "exit=$?"
git reset -q devcontainer-config/cc-push.sh.orig; rm devcontainer-config/cc-push.sh.orig
echo '## P2 unstaged rename (intent-to-add), commit -a'
mv devcontainer-config/egress/base.txt devcontainer-config/moved.txt
git add -N devcontainer-config/moved.txt
echo '$ git diff --name-only'; git diff --name-only
echo '$ git diff --name-only --no-renames'; git diff --name-only --no-renames
timeout 20 bash "$G" <<< "$(pl 'git commit -am x')"; echo "exit=$?"
