#!/usr/bin/env bash
# Pass-3 extra probes. Run: rt3.sh <probe-root>
set -u
P="$1"; [ -d "$P/head/devcontainer-config" ] || exit 2
R="$P/rt3"; rm -rf "$R"; mkdir -p "$R/bin" "$R/home" "$R/tmp" || exit 2
export HOME="$R/home" TMPDIR="$R/tmp"
printf '#!/usr/bin/env bash\nexit 0\n' > "$R/bin/devcontainer"; chmod +x "$R/bin/devcontainer"
PATH="$R/bin:$PATH"; SRC="$P/head/devcontainer-config"
mk() { local d="$1"; rm -rf "$d"; mkdir -p "$d/egress"
  echo '{"name":"x"}' > "$d/devcontainer.json"; echo 'FROM node:22' > "$d/Dockerfile"
  echo '#!/bin/bash' > "$d/init-firewall.sh"; echo '#!/usr/bin/python3' > "$d/cc-sni-proxy.py"
  echo '#!/usr/bin/env bash' > "$d/link-claude-home.sh"; echo 'api.anthropic.com' > "$d/egress/base.txt"
  cp "$SRC/cc-isolated.sh" "$SRC/cc-exit-scan.sh" "$SRC/cc-gitdir.sh" "$SRC/cc-push.sh" "$d/"
  CLAUDE_DEVC_CONFIG_DIR="$d" bash "$d/cc-isolated.sh" --bless >/dev/null; }
echo "### Q1: config dir with a colon in its path: re-bless shows the diff"
C="$R/a:b"; mk "$C"; echo '# q1' >> "$C/cc-push.sh"
CLAUDE_DEVC_CONFIG_DIR="$C" bash "$C/cc-isolated.sh" --bless 2>&1 | grep -E '^(Changed|No previous|[<>])'
echo "### Q2: cc-push with host-tools.sha256 missing / a symlink (installed dir)"
D="$R/cfg"; mk "$D"; export CLAUDE_DEVC_CONFIG_DIR="$D"
mv "$D/host-tools.sha256" "$R/ht"; bash "$D/cc-push.sh" --help >/dev/null 2>"$R/q2a"; echo "missing: exit=$?"
ln -s "$R/ht" "$D/host-tools.sha256"; bash "$D/cc-push.sh" --help >/dev/null 2>"$R/q2b"; echo "symlink: exit=$?"
rm "$D/host-tools.sha256"; mv "$R/ht" "$D/host-tools.sha256"
echo "### Q3: cc-push from a repo checkout (install.sh beside it, no manifests)"
bash "$SRC/cc-push.sh" --help >/dev/null 2>&1; echo "repo checkout: exit=$?"
echo "### Q4: the refusal's check_manifest hint '\$0 --bless' with CLAUDE_DEVC_CONFIG_DIR unset (custom dir)"
L="$R/custom"; mk "$L"; echo '# q4' >> "$L/cc-exit-scan.sh"; echo 'x' >> "$L/Dockerfile"
( unset CLAUDE_DEVC_CONFIG_DIR; bash "$L/cc-isolated.sh" "$R" 2>&1 | grep -E -- '--bless' )
echo "--- running the first hint verbatim (env unset):"
( unset CLAUDE_DEVC_CONFIG_DIR; bash "$L/cc-isolated.sh" --bless > "$R/q4.out" 2>&1; echo "exit=$?"; grep -v setlocale "$R/q4.out" | head -3 )
echo "custom manifest unchanged after it: $(CLAUDE_DEVC_CONFIG_DIR="$L" bash -c 'source "$0"; check_manifest >/dev/null 2>&1 && echo no-it-matches || echo yes-still-differs' "$L/cc-isolated.sh" 2>/dev/null)"
echo "### done"
