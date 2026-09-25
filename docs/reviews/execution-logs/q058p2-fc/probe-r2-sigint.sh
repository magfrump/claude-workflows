#!/usr/bin/env bash
# Probe R2 (6ec64c3), SIGINT case: probe-r2-a1.sh started install.sh from a
# background job, whose SIGINT disposition is SIG_IGN (inherited, and bash
# cannot un-ignore it), so its SIGINT row proves nothing. Here python starts
# the pty with SIGINT at its default, then sends SIGINT to install.sh's bash
# at the host prompt. Same hermetic fixture as probe-r2-a1.sh.
# Usage: probe-r2-sigint.sh <path to install.sh under test>
set -uo pipefail

INSTALL_SRC="$1"
S="$(mktemp -d "${TMPDIR:-/tmp}/q058p2-int.XXXXXX")"
export HOME="$S/home" TMPDIR="$S/tmp" GIT_CONFIG_NOSYSTEM=1 SHELL=/bin/bash
export CLAUDE_HOME_DIR="$HOME/.claude" CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/cd" CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
unset CLAUDE_CONFIG_DIR CLAUDECODE
mkdir -p "$HOME" "$TMPDIR" "$S/stub"
printf '#!/bin/bash\nexit 1\n' > "$S/stub/pgrep"
printf '#!/bin/bash\nexit 0\n' > "$S/stub/docker"
chmod +x "$S/stub/pgrep" "$S/stub/docker"
export PATH="$S/stub:$PATH"
ROOT="$S/repo"
INSTALL="$ROOT/devcontainer-config/install.sh"
cfg="$ROOT/devcontainer-config"
mkdir -p "$cfg/egress" "$ROOT/global-instructions" "$ROOT/skills/a" "$ROOT/workflows" \
         "$ROOT/guides" "$ROOT/patterns" "$ROOT/hooks/lib" "$ROOT/scripts"
cp "$INSTALL_SRC" "$INSTALL"
printf 'g\n' > "$ROOT/global-instructions/CLAUDE.md"
printf 's\n' > "$ROOT/skills/a/SKILL.md"
for f in workflows/w.md guides/g.md patterns/p.md hooks/h.sh hooks/lib/x.sh hooks/wiring.json scripts/s.sh; do
  printf 'x\n' > "$ROOT/$f"
done
for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py link-claude-home.sh cc-isolated.sh; do
  printf 'stub %s\n' "$f" > "$cfg/$f"
done
printf 'api.anthropic.com\n' > "$cfg/egress/base.txt"
printf 'devcontainer-config/claude-home/\n' > "$ROOT/.gitignore"
git -C "$ROOT" init -q && git -C "$ROOT" add -A && git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m init

INSTALL="$INSTALL" python3 - <<'EOF'
import os, signal, subprocess, time
inst = os.environ["INSTALL"]
p = subprocess.Popen(["script", "-qec", f"bash '{inst}'", "/dev/null"],
                     stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                     preexec_fn=lambda: signal.signal(signal.SIGINT, signal.SIG_DFL))
p.stdin.write(b"n\n"); p.stdin.flush()
dest = os.environ["CLAUDE_HOME_DIR"]
for _ in range(150):
    if os.path.exists(dest + "/.cw-new.manifest"): break
    time.sleep(0.1)
time.sleep(2)
pid = subprocess.run(["/usr/bin/pgrep", "-f", f"^bash {inst}$"], capture_output=True, text=True).stdout.split()[0]
sigint = open(f"/proc/{pid}/status").read().split("SigIgn:")[1].split()[0]
print(f"### SIGINT: install.sh pid {pid}, SigIgn mask {sigint} (bit 2 = SIGINT ignored: {bool(int(sigint,16) & 2)})")
print("    copies before signal:", sorted(n for n in os.listdir(dest) if n.startswith(".cw-new.")))
os.kill(int(pid), signal.SIGINT)
for _ in range(50):
    if not os.path.exists(f"/proc/{pid}"): break
    time.sleep(0.1)
print("    install.sh alive 5 s after SIGINT:", os.path.exists(f"/proc/{pid}"))
p.stdin.close(); p.wait(timeout=30)
print("    dest exists:", os.path.exists(dest), "entries:", sorted(os.listdir(dest)) if os.path.exists(dest) else [])
print("    TMPDIR leftovers:", os.listdir(os.environ["TMPDIR"]))
EOF
echo "== probe dir: $S"
