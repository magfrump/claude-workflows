#!/usr/bin/env python3
"""Probe the guard hook (HEAD and 970e525) against a real git-worktree fixture.
Temp HOME only; never touches the real ~/.claude."""
import json, os, subprocess, sys, tempfile, datetime, shutil

P = "/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/gfc-rr-r1"
W = "/workspace/.claude/wt-guard"
HOOK_HEAD = f"{W}/hooks/guard-trusted-writes.py"
HOOK_BASE = f"{P}/hook-970e525.py"
with open(HOOK_BASE, "w") as f:
    f.write(subprocess.check_output(["git", "-C", W, "show", "970e525:hooks/guard-trusted-writes.py"], text=True))

T = tempfile.mkdtemp(prefix="probe-", dir=P)
HOME = f"{T}/home"; REPO = f"{T}/repo"; CHECKOUT = f"{T}/checkout"
os.makedirs(f"{HOME}/.claude/hooks"); os.makedirs(REPO)
def sh(*a): subprocess.check_call(list(a), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
sh("git", "-C", REPO, "init", "-q")
sh("git", "-C", REPO, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "i")
sh("git", "-C", REPO, "worktree", "add", "-q", f"{REPO}/.claude/wt-foo", "-b", "a")
sh("git", "-C", REPO, "worktree", "add", "-q", f"{REPO}/.claude/worktrees/foo", "-b", "b")
# bare-host checkout with a per-file linked hook, a linked dir, a dangling link
os.makedirs(f"{CHECKOUT}/hooks/lib"); os.makedirs(f"{CHECKOUT}/global-instructions")
open(f"{CHECKOUT}/hooks/linked.sh", "w").write("x")
open(f"{CHECKOUT}/hooks/lib/util.sh", "w").write("x")
open(f"{CHECKOUT}/global-instructions/CLAUDE.md", "w").write("x")
os.symlink(f"{CHECKOUT}/hooks/linked.sh", f"{HOME}/.claude/hooks/linked.sh")
os.symlink(f"{CHECKOUT}/hooks/lib", f"{HOME}/.claude/hooks/lib")
os.symlink(f"{CHECKOUT}/hooks/gone.sh", f"{HOME}/.claude/hooks/dangling.sh")
os.symlink(f"{CHECKOUT}/global-instructions/CLAUDE.md", f"{HOME}/.claude/CLAUDE.md")

def run(hook, payload, env_extra=None):
    env = {"HOME": HOME, "PATH": os.environ["PATH"], "CC_WEB_TAINT_DIR": f"{T}/taint"}
    if env_extra: env.update(env_extra)
    r = subprocess.run(["python3", hook], input=json.dumps(payload), capture_output=True, text=True, env=env)
    if r.returncode != 0: return f"rc={r.returncode}"
    if not r.stdout.strip(): return "defer"
    return json.loads(r.stdout)["hookSpecificOutput"]["permissionDecision"]

def bash(c): return {"tool_name": "Bash", "tool_input": {"command": c}, "session_id": "s"}
def edit(p): return {"tool_name": "Edit", "tool_input": {"file_path": p}, "session_id": "s"}

R = REPO; H = HOME
cases = [
 ("abs wt hooks write (should exempt)", bash(f"echo x > {R}/.claude/wt-foo/hooks/x.sh")),
 ("abs wt // doubled", bash(f"echo x > {R}//.claude/wt-foo/hooks/x.sh")),
 ("abs wt trailing /. ", bash(f"cp /tmp/a {R}/.claude/wt-foo/.")),
 ("abs wt /./ inside", bash(f"echo x > {R}/.claude/wt-foo/./hooks/x.sh")),
 ("leading // root", bash(f"echo x > /{R}/.claude/wt-foo/hooks/x.sh")),
 ("dd of= wt", bash(f"dd if=/dev/zero of={R}/.claude/wt-foo/settings.json")),
 ("--opt= wt", bash(f"cp --target-directory={R}/.claude/wt-foo/hooks /tmp/a")),
 ("glob in wt word", bash(f"echo x > {R}/.claude/wt-foo/hooks/*.sh")),
 ("basename-derived .claude (N2 class)", bash(f"D=$(basename $(dirname {R}/.claude/wt-foo)); echo x > $(cd;pwd)/$D/settings.json")),
 ("TOCTOU replace root with symlink to home (CLAUDE.md)", bash(f"rm -rf {R}/.claude/wt-foo && ln -s \"$(cd;pwd)\" {R}/.claude/wt-foo && echo x > {R}/.claude/wt-foo/CLAUDE.md")),
 ("TOCTOU replace root, ~ named", bash(f"rm -rf {R}/.claude/wt-foo && ln -s ~ {R}/.claude/wt-foo && echo x > {R}/.claude/wt-foo/CLAUDE.md")),
 ("same-cmd symlink inside wt via $(cd;pwd) to home CLAUDE.md", bash(f"ln -s \"$(cd;pwd)\" {R}/.claude/wt-foo/h && echo x > {R}/.claude/wt-foo/h/CLAUDE.md")),
 ("same-cmd symlink inside wt to home, then .claude/settings", bash(f"ln -s ~ {R}/.claude/wt-foo/h && echo x > {R}/.claude/wt-foo/h/.claude/settings.json")),
 ("cd wt then cd .. relative settings", bash(f"cd {R}/.claude/wt-foo && cd .. && echo x > settings.json")),
 ("cd wt; bare cd; CLAUDE.md (N2 class)", bash(f"cd {R}/.claude/wt-foo; cd; echo x > CLAUDE.md")),
 ("wt path + ~/.claude elsewhere", bash(f"cp {R}/.claude/wt-foo/settings.json ~/.claude/")),
 ("0b: bash write to linked hook's checkout path", bash(f"echo x > {CHECKOUT}/hooks/linked.sh")),
 ("0b: bash write to linked lib dir file", bash(f"cp /tmp/a {CHECKOUT}/hooks/lib/util.sh")),
 ("0b: bash write to checkout global CLAUDE.md", bash(f"echo x > {CHECKOUT}/global-instructions/CLAUDE.md")),
 ("N12 edit linked hook", edit(f"{CHECKOUT}/hooks/linked.sh")),
 ("N12 edit file in linked dir hooks/lib", edit(f"{CHECKOUT}/hooks/lib/util.sh")),
 ("N12 edit dangling target", edit(f"{CHECKOUT}/hooks/gone.sh")),
 ("N12 edit other checkout hook (unlinked)", edit(f"{CHECKOUT}/hooks/other.sh")),
 ("Write tool to a temp prose file (N15 advice)", {"tool_name": "Write", "tool_input": {"file_path": f"{T}/msg.txt"}, "session_id": "s"}),
 ("Bash using the prose file (N15 advice)", bash(f"git commit -F {T}/msg.txt")),
]
out = [f"# probe run {datetime.datetime.utcnow().isoformat()}Z  cwd={os.getcwd()}  T={T}"]
for name, pl in cases:
    h = run(HOOK_HEAD, pl); b = run(HOOK_BASE, pl)
    cmd = pl["tool_input"].get("command") or pl["tool_input"].get("file_path")
    out.append(f"HEAD={h:6} BASE={b:6} | {name} | {cmd}")
# tainted edit of copied-CLAUDE.md scenario is covered by bats; also check hooks-dir-as-symlink layout
os.makedirs(f"{T}/taint"); open(f"{T}/taint/s", "w").write("")
out.append("-- tainted --")
for name, pl in cases[16:23]:
    out.append(f"HEAD={run(HOOK_HEAD, pl):6} | tainted {name}")
print("\n".join(out))
