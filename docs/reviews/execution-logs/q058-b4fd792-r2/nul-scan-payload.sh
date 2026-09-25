#!/usr/bin/env bash
# Extract every payload path of both targets as committed at b4fd792 (the same
# git archive call install.sh makes) into a scratch dir, and list files holding a NUL.
# Usage: nul-scan-payload.sh <worktree> <scratch-dir>
set -euo pipefail
W="$1"; OUT="$2"
rm -rf "$OUT"; mkdir -p "$OUT"
date -u +%FT%TZ
git -C "$W" -c tar.umask=022 archive --format=tar b4fd792 -- \
  global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts \
  devcontainer-config/devcontainer.json devcontainer-config/Dockerfile \
  devcontainer-config/init-firewall.sh devcontainer-config/cc-sni-proxy.py \
  devcontainer-config/cc-isolated.sh devcontainer-config/link-claude-home.sh \
  devcontainer-config/egress | tar -xf - -C "$OUT"
echo "files=$(find "$OUT" -type f | wc -l)"
echo "nul_files:"
(cd "$OUT" && find . -type f -print0 | LC_ALL=C perl -0ne '
  chomp; open(my $f, "<:raw", $_) or die "$_: $!\n";
  my $c = do { local $/; <$f> };
  print "$_\n" if defined $c && index($c, "\0") >= 0;')
echo "scan_exit=$?"
