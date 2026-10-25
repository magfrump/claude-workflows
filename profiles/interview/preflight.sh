#!/usr/bin/env bash
# preflight.sh — go/no-go check for the interview environment. Run on the host
# the day before, and again ~1 hour before the call.
#
# Usage: bash profiles/interview/preflight.sh [--warm]
#   --warm  also run warm-cache.py: download small models/datasets into the
#           Hugging Face cache and run one GPU training step (~1–3 min first time)
#
# Exit status: 0 if every check passed (warnings allowed), 1 if any FAILED.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CCI_CONFIG_DIR:-$HOME/.claude-interview}"
VENV="${CCI_VENV:-$HOME/interview-env}"
PY="$VENV/bin/python"
HF_HOME_DIR="${HF_HOME:-$HOME/.cache/huggingface}"
MIN_FREE_GB=15

warm=0
[ "${1:-}" = "--warm" ] && warm=1

fails=0
pass() { printf '  PASS  %s\n' "$*"; }
warn() { printf '  WARN  %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; fails=$((fails + 1)); }

echo "== Host"
if [ -f /etc/cc-config-hash ]; then
  fail "running inside the cc-isolated container; run this on the host"
else
  pass "not in the cc-isolated container"
fi
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
  pass "nvidia-smi: $(nvidia-smi -L | head -1)"
else
  fail "nvidia-smi missing or sees no GPU (WSL needs the Windows NVIDIA driver)"
fi

echo "== Python environment ($VENV)"
if [ -x "$PY" ]; then
  pass "$("$PY" --version 2>&1)"
  # Versions must match the interviewers' pins exactly.
  if "$PY" - <<'EOF'
import sys
from importlib.metadata import version, PackageNotFoundError
want = {"datasets": "3.5.0", "torch": "2.6.0", "transformers": "4.50.3"}
bad = []
for pkg, v in want.items():
    try:
        got = version(pkg)
    except PackageNotFoundError:
        got = "missing"
    # torch wheels may carry a local tag, e.g. 2.6.0+cu124
    if got.split("+")[0] != v:
        bad.append(f"{pkg}: want {v}, got {got}")
for b in bad:
    print("        " + b)
sys.exit(1 if bad else 0)
EOF
  then pass "pinned versions match requirements.txt"
  else fail "pinned versions do not match (re-run install.sh)"
  fi
  if "$PY" -c "import accelerate, sklearn, matplotlib, tqdm" 2>/dev/null; then
    pass "extras importable (accelerate, sklearn, matplotlib, tqdm)"
  else
    warn "some extras missing (fine if you used --no-extras)"
  fi
  if gpu_out="$("$PY" - 2>&1 <<'EOF'
import time, torch
assert torch.cuda.is_available(), f"torch {torch.__version__} cannot see CUDA"
d = torch.device("cuda")
x = torch.randn(4096, 4096, device=d)
torch.cuda.synchronize(); t = time.time()
for _ in range(10):
    y = x @ x
torch.cuda.synchronize()
props = torch.cuda.get_device_properties(0)
print(f"{props.name}, {props.total_memory / 2**30:.1f} GiB, "
      f"torch {torch.__version__} (CUDA {torch.version.cuda}), "
      f"bf16={'yes' if torch.cuda.is_bf16_supported() else 'no'}, "
      f"10x 4k matmul {time.time() - t:.2f}s")
EOF
)"; then
    pass "GPU: $gpu_out"
  else
    fail "torch GPU check: $(echo "$gpu_out" | tail -1)"
  fi
else
  fail "no venv python at $PY (run install.sh)"
fi

echo "== Network"
for url in https://huggingface.co https://pypi.org/simple/; do
  if curl -sfI --max-time 10 "$url" >/dev/null; then pass "reachable: $url"; else fail "unreachable: $url"; fi
done

echo "== Disk"
mkdir -p "$HF_HOME_DIR"
free_gb=$(df -Pk "$HF_HOME_DIR" | awk 'NR==2 {print int($4 / 1048576)}')
if [ "$free_gb" -ge "$MIN_FREE_GB" ]; then
  pass "${free_gb} GB free for $HF_HOME_DIR"
else
  warn "only ${free_gb} GB free for $HF_HOME_DIR (want >= ${MIN_FREE_GB})"
fi

echo "== Claude Code profile ($CONFIG_DIR)"
if command -v claude >/dev/null 2>&1; then pass "claude $(claude --version 2>/dev/null | head -1)"; else fail "claude not on PATH"; fi
if command -v cci >/dev/null 2>&1; then pass "cci on PATH"; else warn "cci not on PATH (use ~/.local/bin/cci)"; fi
if [ ! -f "$CONFIG_DIR/CLAUDE.md" ]; then
  fail "no CLAUDE.md in profile (run install.sh)"
elif cmp -s "$HERE/CLAUDE.md" "$CONFIG_DIR/CLAUDE.md"; then
  pass "CLAUDE.md matches $HERE/CLAUDE.md"
else
  warn "profile CLAUDE.md differs from $HERE/CLAUDE.md (re-run install.sh if you edited it)"
fi
if [ -f "$CONFIG_DIR/settings.json" ]; then pass "settings.json present"; else fail "no settings.json in profile (run install.sh)"; fi
# Claude Code loads CLAUDE.md files from every ancestor of the launch directory,
# whatever CLAUDE_CONFIG_DIR says, so the main harness's ~/.claude/CLAUDE.md
# leaks in unless settings.json excludes it. Files directly under $HOME are
# covered by the /home/*/ patterns; anything above $HOME is not.
excludes_set=0
grep -q '"claudeMdExcludes"' "$CONFIG_DIR/settings.json" 2>/dev/null && excludes_set=1
leaks=0 dir="$HOME/interview"
while :; do
  dir="$(dirname "$dir")"
  for f in "$dir/CLAUDE.md" "$dir/CLAUDE.local.md" "$dir/.claude/CLAUDE.md"; do
    [ -f "$f" ] || continue
    if [ "$excludes_set" -eq 1 ] && [ "$dir" = "$HOME" ] && [[ "$HOME" == /home/* ]]; then
      pass "ancestor $f is excluded by claudeMdExcludes"
    else
      fail "ancestor $f would load into every cci session (add it to claudeMdExcludes)"
      leaks=1
    fi
  done
  [ "$dir" = / ] && break
done
[ "$leaks" -eq 0 ] && echo "        to confirm: cd ~/interview && cci -p 'List the path of every CLAUDE.md in your context.'"
if [ -f "$CONFIG_DIR/.credentials.json" ]; then
  pass "credentials present"
else
  warn "no credentials yet: run 'cci', then /login (do this in the practice run)"
fi

if [ "$warm" -eq 1 ] && [ -x "$PY" ]; then
  echo "== Warm cache"
  if "$PY" "$HERE/warm-cache.py"; then pass "warm-cache.py"; else fail "warm-cache.py (see output above)"; fi
fi

echo
if [ "$fails" -eq 0 ]; then echo "READY (0 failures)"; else echo "NOT READY: $fails failure(s)"; fi
[ "$fails" -eq 0 ]
