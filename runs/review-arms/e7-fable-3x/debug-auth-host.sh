#!/usr/bin/env bash
# E7 auth debugging — run from the HOST. One container per probe, prints a
# compact report to paste back into the workspace session.
#
# Usage: CLAUDE_CREDENTIALS=~/.claude/.credentials.json bash runs/review-arms/e7-fable-3x/debug-auth-host.sh
set -euo pipefail
CC_VERSION="2.1.232"

[ -n "${CLAUDE_CREDENTIALS:-}" ] && [ -f "$CLAUDE_CREDENTIALS" ] || {
  echo "Set CLAUDE_CREDENTIALS to your .credentials.json" >&2; exit 1; }

AUTH_DIR=$(mktemp -d)
trap 'rm -rf "$AUTH_DIR"' EXIT
cp "$CLAUDE_CREDENTIALS" "$AUTH_DIR/.credentials.json"
chmod 700 "$AUTH_DIR"; chmod 600 "$AUTH_DIR/.credentials.json"

echo "== host-side credential shape (no secrets printed)"
python3 - "$CLAUDE_CREDENTIALS" <<'EOF'
import json, sys, time
d = json.load(open(sys.argv[1]))
o = d.get("claudeAiOauth") or d
print("  top-level keys:", sorted(d.keys()))
print("  scopes:", o.get("scopes"))
exp = o.get("expiresAt")
if exp:
    ms = exp > 1e12
    print(f"  expiresAt: {exp} ({'EXPIRED' if (exp/1000 if ms else exp) < time.time() else 'valid'})")
print("  has accessToken:", bool(o.get("accessToken")), " has refreshToken:", bool(o.get("refreshToken")))
EOF

run_probe() {  # $1 = label, remaining args = claude flags before -p
  local label="$1"; shift
  echo "== probe: $label"
  docker run --rm -u node "$@" \
    -v "$AUTH_DIR":/home/node/.claude \
    -v cc-review-npm-cache:/home/node/.npm \
    node:22 sh -c '
      echo "  HOME=$HOME  homedir=$(node -e "process.stdout.write(require(\"os\").homedir())")"
      ls -la /home/node/.claude/ | sed "s/^/  /"
      npx -y @anthropic-ai/claude-code@'"$CC_VERSION"' '"$CLAUDE_FLAGS"' --debug -p "Reply with exactly: OK" --model claude-fable-5 --output-format json \
        >/tmp/out.json 2>/tmp/err.log || true
      echo "  --- result:"
      head -c 600 /tmp/out.json; echo
      echo "  --- stderr (auth/login/credential lines):"
      grep -iE "auth|login|credential|oauth|token|401|403" /tmp/err.log | tail -25 | sed "s/^/  /" || echo "  (none)"
    '
  echo
}

CLAUDE_FLAGS="--bare"        run_probe "WITH --bare (current E7 config)"
CLAUDE_FLAGS=""              run_probe "WITHOUT --bare"
CLAUDE_FLAGS="--bare"        run_probe "WITH --bare + CLAUDE_CONFIG_DIR pinned" -e CLAUDE_CONFIG_DIR=/home/node/.claude

# Probe 4: interactive login also writes oauthAccount/hasCompletedOnboarding to
# ~/.claude.json (homedir, NOT inside ~/.claude). Mount a minimal one.
printf '{"hasCompletedOnboarding": true}\n' > "$AUTH_DIR/global.claude.json"
CLAUDE_FLAGS="--bare"        run_probe "WITH --bare + minimal ~/.claude.json" \
  -v "$AUTH_DIR/global.claude.json":/home/node/.claude.json
echo "Done — paste the whole output back into the workspace session."
