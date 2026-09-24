#!/usr/bin/env python3
"""Second probe batch: relative steps out of an exempt worktree; worktree under HOME;
installed layout (hooks dir itself a symlink). Temp HOME only."""
import json, os, subprocess, tempfile, datetime

P = "/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/gfc-rr-r1"
W = "/workspace/.claude/wt-guard"
HOOK_HEAD = f"{W}/hooks/guard-trusted-writes.py"
HOOK_BASE = f"{P}/hook-970e525.py"
T = tempfile.mkdtemp(prefix="probe2-", dir=P)

def sh(*a): subprocess.check_call(list(a), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
def mkrepo(repo, wts):
    os.makedirs(repo, exist_ok=True)
    sh("git", "-C", repo, "init", "-q")
    sh("git", "-C", repo, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "i")
    for i, w in enumerate(wts):
        sh("git", "-C", repo, "worktree", "add", "-q", w, "-b", f"b{i}")

def run(hook, payload, home, taint=False):
    td = f"{T}/taint"; os.makedirs(td, exist_ok=True)
    if taint: open(f"{td}/s", "w").close()
    elif os.path.exists(f"{td}/s"): os.remove(f"{td}/s")
    env = {"HOME": home, "PATH": os.environ["PATH"], "CC_WEB_TAINT_DIR": td}
    r = subprocess.run(["python3", hook], input=json.dumps(payload), capture_output=True, text=True, env=env)
    if r.returncode: return f"rc={r.returncode}"
    return json.loads(r.stdout)["hookSpecificOutput"]["permissionDecision"] if r.stdout.strip() else "defer"

def bash(c): return {"tool_name": "Bash", "tool_input": {"command": c}, "session_id": "s"}
def edit(p): return {"tool_name": "Edit", "tool_input": {"file_path": p}, "session_id": "s"}

out = [f"# probe2 {datetime.datetime.utcnow().isoformat()}Z cwd={os.getcwd()} T={T}"]
def rep(name, pl, home):
    for taint in (False, True):
        out.append(f"HEAD={run(HOOK_HEAD, pl, home, taint):6} BASE={run(HOOK_BASE, pl, home, taint):6} taint={taint!s:5} | {name} | {pl['tool_input'].get('command') or pl['tool_input'].get('file_path')}")

# Layout A: repo outside HOME
HOME = f"{T}/home"; os.makedirs(f"{HOME}/.claude")
R = f"{T}/repo"; mkrepo(R, [f"{R}/.claude/wt-foo"])
os.makedirs(f"{R}/.claude/hooks", exist_ok=True)
rep("cd wt; cd ..; write project settings.json", bash(f"cd {R}/.claude/wt-foo && cd .. && echo '{{}}' > settings.json"), HOME)
rep("cd wt; cd ..; write project hooks/x.sh", bash(f"cd {R}/.claude/wt-foo && cd .. && echo x > hooks/x.sh"), HOME)
rep("cd wt/..-free: cd wt; cd ../; cp into settings.local.json", bash(f"cd {R}/.claude/wt-foo; cd ../; cp /tmp/a settings.local.json"), HOME)
rep("control: cd project .claude directly; write settings.json", bash(f"cd {R}/.claude && echo '{{}}' > settings.json"), HOME)
rep("control: Edit tool on project .claude/settings.json", edit(f"{R}/.claude/settings.json"), HOME)

# Layout B: repo under HOME (~/code/repo), per 835f99d Notes "stays exempt"
HOME2 = f"{T}/home2"; os.makedirs(f"{HOME2}/.claude")
R2 = f"{HOME2}/code/repo"; mkrepo(R2, [f"{R2}/.claude/wt-x"])
rep("worktree under HOME: hooks write", bash(f"echo x > {R2}/.claude/wt-x/hooks/x.sh"), HOME2)
rep("worktree under HOME: settings.json write", bash(f"echo x > {R2}/.claude/wt-x/settings.json"), HOME2)
rep("worktree under HOME: CLAUDE.md write", bash(f"echo x >> {R2}/.claude/wt-x/CLAUDE.md"), HOME2)

# Layout C: HOME is the repo (HOME=/workspace style)
R3 = f"{T}/ws"; mkrepo(R3, [f"{R3}/.claude/wt-g"])
rep("HOME == repo: wt hooks write", bash(f"echo x > {R3}/.claude/wt-g/hooks/x.sh"), R3)

# Layout D: installed layout, CONFIG_DIR/hooks is a symlink into /opt-like payload with a subdir
HOME4 = f"{T}/home4"; OPT = f"{T}/opt/cw"
os.makedirs(f"{HOME4}/.claude"); os.makedirs(f"{OPT}/hooks/lib")
open(f"{OPT}/hooks/a.py", "w").write("x"); open(f"{OPT}/hooks/lib/u.sh", "w").write("x")
os.symlink(f"{OPT}/hooks", f"{HOME4}/.claude/hooks")
rep("installed: Edit payload hooks/a.py by real path", edit(f"{OPT}/hooks/a.py"), HOME4)
rep("installed: Edit payload hooks/lib/u.sh", edit(f"{OPT}/hooks/lib/u.sh"), HOME4)
rep("installed: Edit payload sibling (not hooks)", edit(f"{OPT}/README.md"), HOME4)

# Layout E: a hooks/ entry that links to a whole checkout dir (e.g. repo root)
HOME5 = f"{T}/home5"; CK = f"{T}/ck"
os.makedirs(f"{HOME5}/.claude/hooks"); os.makedirs(f"{CK}/src")
os.symlink(CK, f"{HOME5}/.claude/hooks/ck")
rep("hooks/ entry -> whole checkout dir: Edit ck/src/x.py", edit(f"{CK}/src/x.py"), HOME5)
print("\n".join(out))
