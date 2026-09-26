#!/usr/bin/env python3
"""Check that the Bash commands a model tried in a deny-record fixture run
include a Mode 1 evaluator call that computes an expected value (Q-063 [1],
dd-arith-eval-bash-grant.md).

The fixture run offered Bash but denied every call, so nothing ran. This script
does not read the transcript: the caller (eval-helpers.bash's
assert_mode1_equiv) extracts the attempted commands through transcript.jq, the
one strict reader, which also refuses malformed transcripts and undenied calls
(review iteration 4, R2/A21). For each command, this script:
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
It passes if any command's result matches one of the expected values.

Usage: mode1-equiv.py <SKILL.md> <commands.json> <expected>
       mode1-equiv.py --check-spec <SKILL.md> <expected>
  <commands.json> is a JSON array of strings: the Bash commands, in order.
  <expected> is one or more values separated by "|", each a plain number
  (digits, an optional "." part and exponent, an optional leading "-"),
  optionally followed by "~<relative tolerance>", a plain number >= 0 (default
  1e-6; relative only, so an expected 0 needs an exact 0), e.g.
  "1900000000|1900000" or "42.16~0.002". No spaces, "_", nan, inf or leading
  "+" (an exponent may carry one: 1e+5).
  --check-spec validates <expected> and SKILL.md's Mode 1 block without any
  commands, so a broken fixture spec is caught before any paid run.
Exit 0 on a match (or a valid spec), 1 on no match (per-command diagnostics on
stdout), 2 on anything else: a usage, spec, file or SKILL.md problem, or any
unexpected error in this script (message on stderr). Exit 1 therefore always
means "the model's commands did not compute the value", never a checker fault.
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


def commands(path):
    """The commands from a JSON array of strings; anything else is a SetupError."""
    try:
        data = json.loads(read_text(path))
    except ValueError as e:
        raise SetupError(f"{path} is not JSON: {e}")
    if not isinstance(data, list) or not all(isinstance(c, str) for c in data):
        raise SetupError(f"{path} is not a JSON array of strings")
    return data


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
            raise SetupError("expects 3 arguments: <SKILL.md> <commands.json> <expected>\n" + __doc__)
        skill_path, commands_path, spec = sys.argv[1:]
        ref_program, ref_dump = reference(skill_path)
        expected = parse_expected(spec)
        cmds = commands(commands_path)
    except SetupError as e:
        print("mode1-equiv: " + str(e), file=sys.stderr)
        return 2

    print(f"Bash commands seen: {len(cmds)}")
    for i, cmd in enumerate(cmds, 1):
        w = split_mode1(cmd.strip("\n"))
        if not w:
            print(f"  command {i}: not the Mode 1 wrapper: {cmd[:120]!r}")
            continue
        program, expr = w
        try:
            same = ast.dump(ast.parse(program)) == ref_dump
        except (SyntaxError, ValueError, RecursionError, MemoryError):
            same = False
        if not same:
            print(f"  command {i}: Mode 1 wrapper, but the program differs from SKILL.md's (by AST)")
            continue
        value = evaluate(ref_program, expr)
        print(f"  command {i}: Mode 1, expression {expr!r} -> {value}")
        if value is not None and any(math.isclose(value, v, rel_tol=t, abs_tol=0.0) for v, t in expected):
            return 0
    print(f"No Mode 1 command computed any of: {spec}")
    return 1


if __name__ == "__main__":
    # Backstop for the exit contract: an error this script did not anticipate
    # is a checker fault, exit 2, never a traceback with exit 1, which the
    # harness would read as a model result (review iteration 4, A21).
    try:
        sys.exit(main())
    except Exception as e:  # noqa: BLE001 - deliberate catch-all, see above
        print(f"mode1-equiv: checker error: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(2)
