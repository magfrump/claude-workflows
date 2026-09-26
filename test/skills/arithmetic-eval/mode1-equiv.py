#!/usr/bin/env python3
"""Check that a deny-record transcript holds a Mode 1 evaluator call that
computes an expected value (Q-063 [1], dd-arith-eval-bash-grant.md).

The fixture run offered Bash but denied every call, so nothing ran. This script
reads the Bash commands the model *tried* and, for each one:
  1. requires the shell wrapper to be SKILL.md's Mode 1 wrapper exactly
     (`( ulimit ...; timeout 5 python3 -c '` ... `' ) <<'EXPREOF'`). The
     heredoc closes at the FIRST line equal to EXPREOF, as in bash, and only
     blank or `#` comment lines may follow it, so no shell can ride along
     after the expression;
  2. requires the embedded Python program to equal SKILL.md's by ast.dump,
     which ignores comments and formatting (a probe showed Haiku drops the
     comments, so a byte match fails correct runs) but not any code change;
  3. takes the heredoc body (the expression) and runs it through the evaluator
     extracted from SKILL.md, never the model's copy.
It passes if any call's result matches one of the expected values.

It also re-checks the generator's tripwire: every Bash tool_use id must be in
the result event's permission_denials, or the run fails whatever it computed.

Usage: mode1-equiv.py <SKILL.md> <transcript.jsonl> <expected>
       mode1-equiv.py --check-spec <SKILL.md> <expected>
  <expected> is one or more values separated by "|", each a plain number
  (digits, an optional "." part and exponent, an optional leading "-"),
  optionally followed by "~<relative tolerance>", a plain number >= 0 (default
  1e-6; relative only, so an expected 0 needs an exact 0), e.g.
  "1900000000|1900000" or "42.16~0.002". No spaces, "_", "+", nan or inf.
  --check-spec validates <expected> and SKILL.md's Mode 1 block without a
  transcript, so a broken fixture spec is caught before any paid run.
Exit 0 on a match (or a valid spec), 1 on no match (per-call diagnostics on
stdout), 2 on any setup error: usage, value spec, an unreadable file, a
transcript event of the wrong shape, or a SKILL.md whose Mode 1 block does
not extract (message on stderr). Every setup error goes through SetupError in
main(), so none can escape as a traceback with exit 1, which would read as
"the model did not compute the value".
"""
import ast
import json
import math
import re
import subprocess
import sys

HEAD_RE = re.compile(
    r"\A\( ulimit -t 5 -v 1000000 2>/dev/null; timeout 5 python3 -c '\n"
    r"(?P<program>[^']*)\n"
    r"' \) <<'EXPREOF'\n",
)
TAIL_LINE_RE = re.compile(r"[ \t]*(#.*)?")
NUMBER_RE = re.compile(r"-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?")


class SetupError(Exception):
    """A problem with the check's inputs, not with what the model did."""


def split_mode1(cmd):
    """(program, expression) if <cmd> is the Mode 1 wrapper, else None.

    The heredoc body ends at the first line that is exactly EXPREOF, which is
    where bash ends it; everything after must be blank or a # comment."""
    m = HEAD_RE.match(cmd)
    if not m:
        return None
    lines = cmd[m.end():].split("\n")
    if "EXPREOF" not in lines:
        return None
    end = lines.index("EXPREOF")
    if not all(TAIL_LINE_RE.fullmatch(t) for t in lines[end + 1:]):
        return None
    return m.group("program"), "\n".join(lines[:end])


def reference(skill_path):
    """(program, ast dump) of SKILL.md's Mode 1 block."""
    text = read_text(skill_path)
    m = re.search(r"^## Mode 1\b.*?^```bash\n(.*?)^```", text, re.S | re.M)
    if not m:
        raise SetupError("no ```bash block under '## Mode 1' in " + skill_path)
    w = split_mode1(m.group(1).strip("\n"))
    if not w:
        raise SetupError("SKILL.md's own Mode 1 block does not match the wrapper pattern")
    try:
        return w[0], ast.dump(ast.parse(w[0]))
    except SyntaxError as e:
        raise SetupError(f"SKILL.md's Mode 1 program does not parse: {e}")


def read_text(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except (OSError, UnicodeDecodeError) as e:
        raise SetupError(f"cannot read {path}: {e}")


def events(transcript_path):
    out = []
    for line in read_text(transcript_path).split("\n"):
        try:
            out.append(json.loads(line))
        except ValueError:
            continue  # a stray non-JSON line, as the other transcript checks allow
    return out


def bash_calls(evs):
    """[(tool_use id, command)] for every Bash call, at any depth. A Bash
    tool_use whose fields have the wrong types is a SetupError, not a crash."""
    calls = []
    for ev in evs:
        if not isinstance(ev, dict) or ev.get("type") != "assistant":
            continue
        message = ev.get("message") or {}
        content = message.get("content") if isinstance(message, dict) else None
        for block in content if isinstance(content, list) else []:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "tool_use" and block.get("name") == "Bash":
                inp = block.get("input")
                cmd = inp.get("command") if isinstance(inp, dict) else None
                if not isinstance(cmd, str):
                    raise SetupError(f"Bash tool_use {block.get('id')!r} has no string input.command")
                calls.append((block.get("id"), cmd))
    return calls


def parse_expected(spec):
    """[(value, rel_tol)]; every value finite, every tolerance finite and >= 0."""
    alts = []
    for part in spec.split("|"):
        value, sep, tol = part.partition("~")
        if not NUMBER_RE.fullmatch(value) or (sep and not NUMBER_RE.fullmatch(tol)):
            raise SetupError(f"bad expected value {part!r} in {spec!r}")
        v, t = float(value), float(tol) if sep else 1e-6
        if not math.isfinite(v) or not math.isfinite(t) or t < 0:
            raise SetupError(f"expected value {part!r} in {spec!r}: value must be finite, tolerance finite and >= 0")
        alts.append((v, t))
    return alts


def evaluate(program, expr):
    """Run <expr> through the reference evaluator; return its value or None."""
    try:
        r = subprocess.run(["python3", "-c", program], input=expr + "\n",
                           capture_output=True, text=True, timeout=10)
    except subprocess.TimeoutExpired:
        return None
    m = re.search(r"-> (\S+)\s*\Z", r.stdout)
    if r.returncode != 0 or not m:
        return None
    try:
        return float(m.group(1))
    except ValueError:
        return None


def main():
    try:
        if len(sys.argv) > 1 and sys.argv[1] == "--check-spec":
            if len(sys.argv) != 4:
                raise SetupError("--check-spec expects 2 arguments: <SKILL.md> <expected>\n" + __doc__)
            reference(sys.argv[2])
            parse_expected(sys.argv[3])
            return 0
        if len(sys.argv) != 4:
            raise SetupError("expected 3 arguments\n" + __doc__)
        skill_path, transcript_path, spec = sys.argv[1:]
        ref_program, ref_dump = reference(skill_path)
        expected = parse_expected(spec)
        evs = events(transcript_path)
        calls = bash_calls(evs)
    except SetupError as e:
        print("mode1-equiv: " + str(e), file=sys.stderr)
        return 2

    denied = {d.get("tool_use_id") for ev in evs
              if isinstance(ev, dict) and ev.get("type") == "result"
              for d in (ev.get("permission_denials") or []) if isinstance(d, dict)}
    denied.discard(None)
    # A call with no id counts as undenied (review iteration 3, C28).
    undenied = [cid for cid, _ in calls if cid is None or cid not in denied]
    if undenied:
        print(f"Bash tripwire: {len(undenied)} Bash call(s) not in permission_denials (may have executed): {undenied}")
        return 1

    print(f"Bash calls seen: {len(calls)}")
    for i, (_, cmd) in enumerate(calls, 1):
        w = split_mode1(cmd.strip("\n"))
        if not w:
            print(f"  call {i}: not the Mode 1 wrapper: {cmd[:120]!r}")
            continue
        program, expr = w
        try:
            same = ast.dump(ast.parse(program)) == ref_dump
        except SyntaxError:
            same = False
        if not same:
            print(f"  call {i}: Mode 1 wrapper, but the program differs from SKILL.md's (by AST)")
            continue
        value = evaluate(ref_program, expr)
        print(f"  call {i}: Mode 1, expression {expr!r} -> {value}")
        if value is not None and any(math.isclose(value, v, rel_tol=t, abs_tol=0.0) for v, t in expected):
            return 0
    print(f"No Mode 1 call computed any of: {spec}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
