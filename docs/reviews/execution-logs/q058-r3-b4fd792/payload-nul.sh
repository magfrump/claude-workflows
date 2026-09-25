#!/usr/bin/env bash
# Extract the b4fd792 payload paths (CLAUDE_HOME_SRC + the devcontainer PAYLOAD
# items, as install.sh stages them) and count files, NUL-holding files and links.
set -u
D="$(mktemp -d "${TMPDIR:-/tmp}/nulscan.XXXXXX")"
GI="global-instructions/"'CLAUDE.md'
git -C /workspace archive b4fd792 -- "$GI" skills workflows guides patterns hooks scripts \
  devcontainer-config/devcontainer.json devcontainer-config/Dockerfile \
  devcontainer-config/init-firewall.sh devcontainer-config/cc-sni-proxy.py \
  devcontainer-config/cc-isolated.sh devcontainer-config/link-claude-home.sh \
  devcontainer-config/egress | tar -xf - -C "$D"
echo "archive_exit=${PIPESTATUS[0]}"
echo "files: $(find "$D" -type f | wc -l)"
echo "NUL files:"
find "$D" -type f -print0 | LC_ALL=C perl -0ne 'chomp; open(my $f,"<:raw",$_) or die; my $c=do{local $/;<$f>}; print "$_\n" if index($c,"\0")>=0'
echo "scan_exit=$?"
echo "symlinks: $(find "$D" -type l | wc -l)"
rm -rf "$D"
