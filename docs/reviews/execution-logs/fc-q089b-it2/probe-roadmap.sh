#!/usr/bin/env bash
# Roadmap Ideas row (security F3-F5): path-limited / -o / -i commits, git -C from
# another cwd, and a shebang edit, against the gate at 79f22357. $1 = probe root.
D="$1"
case "$D" in /home/node/.claude/jobs/00bcf178/tmp/fc-it2.*) ;; *) echo "bad D"; exit 1 ;; esac
export HOME="$D/home" LC_ALL=C GIT_CONFIG_NOSYSTEM=1
G="$D/src/hooks/live-verify-gate.sh"
pl() { jq -n -c --arg c "$1" '{"tool_name":"Bash","tool_input":{"command":$c}}'; }
gate() { echo "\$ [cwd $(basename "$PWD")] gate <<< $1"; timeout 20 bash "$G" <<< "$(pl "$1")" 2>&1 | grep '^BLOCKED'; echo "exit=${PIPESTATUS[0]}"; }
R="$D/p3"; rm -rf "$R" "$D/elsewhere"; mkdir -p "$R/devcontainer-config/egress" "$D/elsewhere"; cd "$R" || exit 1
git init -q; git config user.email t@e; git config user.name t
echo base > devcontainer-config/egress/base.txt
printf '#!/usr/bin/env bash\necho p\n' > devcontainer-config/cc-push.sh
git add -A; git -c commit.gpgsign=false commit -qm i
echo "start: $(date -u +%FT%TZ) cwd: $PWD"
echo widened >> devcontainer-config/egress/base.txt     # unstaged
echo "## F3 unstaged gated change, path-limited / -o / -i"
gate 'git commit devcontainer-config/egress/base.txt -m x'
gate 'git commit -o devcontainer-config/egress/base.txt -m x'
gate 'git commit -i devcontainer-config/egress/base.txt -m x'
echo "## F4 staged gated change, git -C from another cwd"
git add devcontainer-config/egress/base.txt
gate 'git commit -m x'
cd "$D/elsewhere" || exit 1
gate "git -C $R commit -m x"
cd "$R" || exit 1; git reset -q
git checkout -q -- devcontainer-config/egress/base.txt
echo "## F5 shebang edit"
sed -i '1s|.*|#!/tmp/evil|' devcontainer-config/cc-push.sh; git add devcontainer-config/cc-push.sh
git diff --cached -U0 | grep '^[-+]#!'
gate 'git commit -m x'
