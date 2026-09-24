#!/bin/bash
cd /workspace/.claude/wt-copyinstall || exit 1
grep -n 'remoteUser\|containerUser\|updateRemoteUserUID\|userns' devcontainer-config/devcontainer.json devcontainer-config/Dockerfile 2>/dev/null | head
grep -n '^PAYLOAD=' devcontainer-config/install.sh
T=$(mktemp -d)
git archive HEAD -- global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts devcontainer-config | tar -xf - -C "$T"
echo "files: $(find "$T" -type f | wc -l)"
echo "files holding NUL:"
find "$T" -type f -print0 | LC_ALL=C perl -0ne 'chomp; open(my $f,"<:raw",$_) or die; my $c=do{local $/;<$f>}; print "$_\n" if index($c,"\0")>=0'
echo "(end)"
rm -rf "$T"
