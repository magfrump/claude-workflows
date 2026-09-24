#!/usr/bin/env python3
"""Probe the branch guard (and the 970e525 guard) with a temp HOME. Never touches the real ~/.claude."""
import json, os, subprocess, tempfile, datetime, sys
S = "/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/review"
NEW = "/workspace/.claude/wt-guard/hooks/guard-trusted-writes.py"
OLD = S + "/oldtree/hooks/guard-trusted-writes.py"
print("timestamp:", datetime.datetime.utcnow().isoformat() + "Z")

def run(hook, payload, home, extra_env=None):
    env = {k: v for k, v in os.environ.items() if k != "CLAUDE_CONFIG_DIR"}
    env.update(HOME=home, CC_WEB_TAINT_DIR=home + "/../taint")
    if extra_env: env.update(extra_env)
    r = subprocess.run(["python3", hook], input=json.dumps(payload), capture_output=True, text=True, env=env)
    if r.returncode != 0 or r.stderr:
        return f"rc={r.returncode} err={r.stderr.strip()[:200]}"
    if not r.stdout.strip(): return "defer"
    return json.loads(r.stdout)["hookSpecificOutput"]["permissionDecision"]

def bash(c): return {"session_id": "clean", "tool_name": "Bash", "tool_input": {"command": c}}
def edit(p): return {"session_id": "clean", "tool_name": "Edit", "tool_input": {"file_path": p}}

T = tempfile.mkdtemp(dir=S)
H = T + "/home"; os.makedirs(H + "/.claude/hooks")
print("HOME =", H)

section = lambda s: print("\n###", s)
section("Claim 1: word/quote/= edge cases (Bash)")
cmds = [
    "cd ~ && echo x > .claude/wt-a/f",
    "cd ~ && echo x > .claude/wt-a/hooks/x",
    "cd ~ && echo x > .claude/wt-a/settings.json",
    "cd ~ && echo x > .claude/worktrees/x/settings.json",
    "cd ~ && echo '{}' > .claude/wt-x'/..'/settings.json",
    "cd ~ && echo '{}' > .claude/wt-x/.\"\"./settings.json",
    'echo \'{}\' > "$HOME"/.claude/wt-x"/../"settings.json',
    'echo x > "$HOME"/.claude/wt-x/settings.json',
    f'echo x > "{H}"/.claude/wt-x/settings.json',
    f"echo x > a=b={H}/.claude/wt-x/settings.json",
    f"dd of={H}/.claude/wt-x/settings.json",
    "echo x > a=/../.claude/wt-x/hooks/x",
    "echo x > /srv/repo/.claude/wt-foo/global-instructions/CLAUDE.md",
    "echo x > /srv/repo/.claude/wt-foo/hooks/x.sh",
    "echo x > /srv/foo.claude/wt-x/hooks/x",
]
for c in cmds:
    print(f"new={run(NEW, bash(c), H):8s} old={run(OLD, bash(c), H):8s}  {c}")

section("Claim 1: live shell effect of the quoted-'..' spelling (temp HOME only)")
os.makedirs(H + "/.claude/wt-x", exist_ok=True)
for c in ["cd ~ && echo '{\"bypass\":1}' > .claude/wt-x'/..'/settings.json",
          'mkdir -p "$HOME"/.claude/wt-y && echo \'{"bypass":2}\' > "$HOME"/.claude/wt-y"/../"settings.local.json']:
    d = run(NEW, bash(c), H)
    print(f"guard(new)={d}  cmd: {c}")
    if d == "defer":
        r = subprocess.run(["bash", "-c", c], env={**os.environ, "HOME": H}, capture_output=True, text=True)
        print("  bash rc =", r.returncode, r.stderr.strip())
for f in ("settings.json", "settings.local.json"):
    p = H + "/.claude/" + f
    print(" ", p, "->", open(p).read().strip() if os.path.exists(p) else "(absent)")

section("HOME == worktree parent layout (HOME=/workspace-like)")
H2 = T + "/ws"; os.makedirs(H2 + "/.claude/hooks"); os.makedirs(H2 + "/.claude/wt-guard/hooks")
for c in [f"echo x > {H2}/.claude/wt-guard/hooks/x.sh", "echo x > .claude/wt-guard/hooks/x.sh",
          f"cd {H2} && echo x > .claude/wt-guard/settings.json"]:
    print(f"new={run(NEW, bash(c), H2):8s} old={run(OLD, bash(c), H2):8s}  {c}")

section("Claim 3: N12 loop edge cases (Edit)")
H3 = T + "/h3"; CO = T + "/co"
os.makedirs(CO + "/hooks/lib"); os.makedirs(H3 + "/.claude/hooks")
open(CO + "/hooks/lib/util.py", "w").write("x"); open(CO + "/hooks/a.sh", "w").write("x")
open(CO + "/README.md", "w").write("x")
os.symlink(CO + "/hooks/lib", H3 + "/.claude/hooks/lib")          # link to a directory
os.symlink(CO + "/hooks/gone.sh", H3 + "/.claude/hooks/gone.sh")  # dangling link
os.symlink(CO + "/hooks/a.sh", H3 + "/.claude/hooks/a.sh")
for p in [CO + "/hooks/lib/util.py", CO + "/hooks/lib/new.py", CO + "/hooks/gone.sh", CO + "/hooks/a.sh", CO + "/README.md"]:
    print(f"new={run(NEW, edit(p), H3):8s} old={run(OLD, edit(p), H3):8s}  Edit {p}")
# hooks itself a symlink into an /opt-like payload
H4 = T + "/h4"; OPT = T + "/opt/cw"; os.makedirs(OPT + "/hooks"); os.makedirs(H4 + "/.claude")
open(OPT + "/hooks/g.py", "w").write("x")
os.symlink(OPT + "/hooks", H4 + "/.claude/hooks")
for p in [OPT + "/hooks/g.py", OPT + "/hooks/new.py"]:
    print(f"new={run(NEW, edit(p), H4):8s} old={run(OLD, edit(p), H4):8s}  Edit {p} (hooks is a dir symlink)")
# a hooks entry that links to the checkout ROOT
H5 = T + "/h5"; os.makedirs(H5 + "/.claude/hooks"); os.symlink(CO, H5 + "/.claude/hooks/root")
print(f"new={run(NEW, edit(CO + '/README.md'), H5):8s} old={run(OLD, edit(CO + '/README.md'), H5):8s}  Edit README with hooks/root -> checkout root")

section("Claim 6: the Bash deny's advice (Write a file, pass it)")
print("Write tmp msg:", run(NEW, {"session_id": "clean", "tool_name": "Write", "tool_input": {"file_path": T + "/msg.txt"}}, H))
print("git commit -F:", run(NEW, bash(f"git commit -F {T}/msg.txt"), H))
print("gh pr create --body-file:", run(NEW, bash(f"gh pr create --body-file {T}/msg.txt"), H))
print("heredoc form denied:", run(NEW, bash("cat > /tmp/m <<'E'\nsee ~/.claude/CLAUDE.md\nE"), H))
