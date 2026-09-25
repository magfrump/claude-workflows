#!/bin/bash
SP=/tmp/claude-1000/-workspace/7630264d-3947-4203-a0ec-b9ffcc3a4e06/scratchpad/x
L=/workspace/docs/reviews/execution-logs/q058-r1-nul-scan.log
rm -rf "$SP/nul"; mkdir -p "$SP/nul"
{
  date -u +%FT%TZ
  echo "cmd: git -C /workspace archive b4fd792 -- <CLAUDE_HOME_SRC + devcontainer-config PAYLOAD> | tar -x; perl NUL scan (same logic as extract_commit)"
  git -C /workspace archive b4fd792 -- global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts \
    devcontainer-config/devcontainer.json devcontainer-config/Dockerfile devcontainer-config/init-firewall.sh \
    devcontainer-config/cc-sni-proxy.py devcontainer-config/cc-isolated.sh devcontainer-config/link-claude-home.sh \
    devcontainer-config/egress | tar -xf - -C "$SP/nul"
  echo "files: $(cd "$SP/nul" && find . -type f | wc -l)"
  cd "$SP/nul" && find . -type f -print0 | LC_ALL=C perl -0ne 'chomp; open(my $f,"<:raw",$_) or die; my $c=do{local $/;<$f>}; print "NUL: $_\n" if index($c,"\0")>=0'
  echo "scan exit=$?"
} > "$L" 2>&1
grep -v setlocale "$L"
