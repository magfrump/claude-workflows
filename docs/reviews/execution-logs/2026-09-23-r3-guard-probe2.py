#!/usr/bin/env python3
"""Config-dir overlap check vs a quote-split spelling, temp dirs only."""
import json, os, subprocess, tempfile, datetime
S = "/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/review"
NEW = "/workspace/.claude/wt-guard/hooks/guard-trusted-writes.py"
OLD = S + "/oldtree/hooks/guard-trusted-writes.py"
print("timestamp:", datetime.datetime.utcnow().isoformat() + "Z")
T = tempfile.mkdtemp(dir=S); H = T + "/home"; os.makedirs(H)
CFG = T + "/srv/repo/.claude/wt-cfg"; os.makedirs(CFG)
def run(hook, c):
    env = {**os.environ, "HOME": H, "CLAUDE_CONFIG_DIR": CFG, "CC_WEB_TAINT_DIR": T + "/taint"}
    r = subprocess.run(["python3", hook], input=json.dumps({"session_id": "c", "tool_name": "Bash", "tool_input": {"command": c}}),
                       capture_output=True, text=True, env=env)
    return json.loads(r.stdout)["hookSpecificOutput"]["permissionDecision"] if r.stdout.strip() else "defer"
for c in [f"echo x > {CFG}/settings.json",
          f'echo x > "{T}/srv/repo"/.claude/wt-cfg/settings.json']:
    print(f"new={run(NEW, c):6s} old={run(OLD, c):6s} {c}")
