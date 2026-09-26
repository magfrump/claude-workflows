#!/usr/bin/env python3
"""Claim 26 probe: run test/skills/arithmetic-eval/mode1-equiv.py on transcripts that
hold each Claim 13 shape, (a) alone and (b) next to a correct, DENIED Mode 1 call that
computes the expected value (so any exit 0 is attributable to the transcript as a whole).
Also: the shape carrying an UNDENIED Bash call (the would-be wrong exit 0)."""
import json, os, re, subprocess, sys, tempfile, datetime
M = "/workspace/test/skills/arithmetic-eval/mode1-equiv.py"
SK = "/workspace/skills/arithmetic-eval/SKILL.md"
text = open(SK).read()
block = re.search(r"^## Mode 1\b.*?^```bash\n(.*?)^```", text, re.S | re.M).group(1).strip("\n")
head = block[: block.index("<<'EXPREOF'\n") + len("<<'EXPREOF'\n")]
CMD = head + "2+3\nEXPREOF"          # expected 5
EXP = "5"
INIT = {"type": "system", "subtype": "init", "tools": ["Bash"]}
def call(i, cmd=CMD, name="Bash"):
    return {"type": "assistant", "message": {"content": [{"type": "tool_use", "id": i, "name": name, "input": {"command": cmd}}]}}
def res(den):
    return {"type": "result", "result": "r", "permission_denials": den}
D = lambda i: {"tool_name": "Bash", "tool_use_id": i}
GOOD = [INIT, call("t1"), res([D("t1")])]
def run(label, lines):
    fd, p = tempfile.mkstemp(suffix=".jsonl"); os.close(fd)
    with open(p, "w") as f:
        for l in lines:
            f.write((l if isinstance(l, str) else json.dumps(l)) + "\n")
    r = subprocess.run([sys.executable, M, SK, p, EXP], capture_output=True, text=True)
    os.unlink(p)
    tail = (r.stdout + r.stderr).strip().splitlines()
    print(f"{label:<74} rc={r.returncode}  {tail[-1][:110] if tail else ''}")
print("date:", datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"), "python:", sys.version.split()[0])
run("B00 baseline: good denied Mode 1 call (2+3 -> 5)", GOOD)
run("B01 baseline: same call UNDENIED", [INIT, call("t1"), res([])])
deep = "[" * 1200 + "]" * 1200
shapes = {
  "S1 permission_denials = 5 (number)":        [res(5)],
  "S1z permission_denials = 0 (falsy number)": [res(0)],
  "S2 denial tool_use_id is a list":            [res([{"tool_name": "Bash", "tool_use_id": [1]}])],
  "S3 Bash tool_use id is an object":           [call({"a": 1})],
  "S4 non-object event (array)":                ['[1,2]'],
  "S4s non-object event (string)":              ['"hello"'],
  "S4n non-object event (number)":              ['42'],
  "S5 assistant message is a string":           [{"type": "assistant", "message": "oops"}],
  "S6 assistant content is a string":           [{"type": "assistant", "message": {"content": "oops"}}],
  "S7 1200-deep line":                          [deep],
}
for k, extra in shapes.items():
    run(f"{k} | alone (+init)", [INIT] + extra)
    run(f"{k} | + good denied call", GOOD + extra)
# The shape as a *carrier* of an undenied Bash call next to a good denied call.
undenied = call("t2")
run("C1 non-object event: [undenied call event] (array-wrapped) + good", GOOD + [json.dumps([undenied])])
run("C2 string message holding JSON of an undenied call + good", GOOD + [{"type": "assistant", "message": json.dumps(undenied["message"])}])
run("C3 string content holding JSON of an undenied call + good", GOOD + [{"type": "assistant", "message": {"content": json.dumps(undenied["message"]["content"])}}])
run("C4 undenied call, denial list in 2nd result has permission_denials=0", [INIT, call("t1"), res(0)])
run("C5 good + second result with permission_denials=0", GOOD + [res(0)])
