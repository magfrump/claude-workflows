#!/usr/bin/env python3
"""lite-review: subscription-backed, no-skill, diff-only code review.

The named lightweight review path (decision 030) rebased onto the Claude
subscription via headless `claude -p` (no OpenRouter account required).
Two modes:

  --mode full       one-shot review of the diff for correctness / security /
                    performance / API drift / misleading docs (decision 030's
                    Stage-1 grammar, diff-only)
  --mode fix-drift  decision 031's L=fix-drift check: run over a fix commit
                    during the review-fix loop, gated to comment/doc drift
                    only - the "fix introduces stale docs" class that E1/E3
                    showed costs a full pass to rediscover

Backend notes (why the flags are what they are):
- NOT --bare: --bare restricts auth to ANTHROPIC_API_KEY and never reads
  OAuth, which defeats the whole point (subscription auth). Instead the call
  minimizes context with --system-prompt (replaces the default harness
  prompt), --tools "" (no tool schemas), and an empty non-repo cwd (no
  CLAUDE.md auto-discovery). Measured overhead ~7.5k tokens vs ~33k default.
- Success is judged from the JSON envelope (is_error, num_turns), not the
  exit code - headless exit codes are unreliable for this.
- This file OWNS the FINDINGS *accept spec* - FINDING_RE (decision log 48).
  It originated in cross-model-review.py and the two were byte-identical when
  ownership moved here; cross-model-review.py is now the copy, and it is the
  OpenRouter benchmark harness, out of scope for this repo.
  test/lite-review-grammar.bats pins the accept spec, and any change to it
  needs a matching note in the decision log.
  Be precise about what that ownership does NOT cover (2026-09-12 review):
    * The *emit spec* - the format block the model actually reads - is
      duplicated verbatim in PROMPT_FULL and PROMPT_FIX_DRIFT below and in
      two harness templates. Nothing ties those copies to FINDING_RE, so
      editing one desyncs silently with no test failure.
    * The *record schema* was never shared. We emit severity/title/description;
      the harness and every on-disk E2/E3 lite-arm artifact carry sev/desc/
      line_start, and archive/benchmark/scripts/canon-to-crb.py binds to those.
      Comparability with those artifacts therefore holds at the line grammar,
      not at the record.
    * parse_findings itself has already diverged from the harness copy in four
      ways (FINDINGS: NONE case-sensitivity, block detection, parse_ok
      derivation, row keys). A fork that diffs only the regex will find it
      identical and be wrong about all four.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

DEFAULT_MODEL = "claude-haiku-4-5-20251001"

SYSTEM_PROMPT = (
    "You are a code reviewer. You cannot run commands or read files; judge "
    "only from the material in the user message. Follow the requested output "
    "format exactly."
)

PROMPT_FULL = """You are reviewing a code diff. Review for: correctness bugs, security issues, performance problems, API/consistency drift, misleading docs/comments. Report only findings that matter - do not pad. Output format, exactly:

FINDINGS:
1. <path>:<lines> | <Critical/High/Medium/Low/Informational> | <domain> | <short title> | <1-2 sentence description>

(or the single line "FINDINGS: NONE"). Nothing after the list.

=== DIFF ({label}) ===
{diff}"""

PROMPT_FIX_DRIFT = """The diff below is a FIX COMMIT made during a code-review loop. Your only job is to catch drift the fix introduced between code and prose. Report ONLY:
- comments, docstrings, or docs that the fix made stale or incorrect relative to the changed code
- new or edited comments/docs in this diff that make claims the code does not satisfy

Do NOT report pre-existing issues, style, or anything about code behavior itself - a separate full review owns those. Report only findings that matter - do not pad. Output format, exactly:

FINDINGS:
1. <path>:<lines> | <Critical/High/Medium/Low/Informational> | <domain> | <short title> | <1-2 sentence description>

(or the single line "FINDINGS: NONE"). Nothing after the list.

=== FIX COMMIT DIFF ({label}) ===
{diff}"""

FINDING_RE = re.compile(
    r"^\s*\d+\.\s*(?P<path>[^|:]+?)(?::(?P<lines>[\d\-, ]+))?\s*\|"
    r"\s*(?P<sev>Critical|High|Medium|Low|Informational)\s*\|"
    r"\s*(?P<domain>[^|]+)\|\s*(?P<title>[^|]+)\|\s*(?P<desc>.+)$",
    re.IGNORECASE,
)


def sh(args, cwd=None):
    # argv-exec, never shell strings (decision 018)
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=True).stdout


def parse_findings(text):
    """Parse the FINDINGS block; returns (findings, parse_ok)."""
    if re.search(r"FINDINGS:\s*NONE", text):
        return [], True
    rows = []
    in_block = False
    for line in text.splitlines():
        if line.strip().startswith("FINDINGS:"):
            in_block = True
            continue
        if not in_block:
            continue
        # Every well-formed row carries four pipes, so a line without one cannot
        # match — and must not be handed to the regex. FINDING_RE backtracks
        # catastrophically on a numbered line followed by a long whitespace run
        # (`\s*` and `[^|:]+?` overlap on spaces): measured 0.32 s at 1 kB,
        # 2.3 s at 2 kB, ~7.3x per doubling, so prose of a few kB is a hang
        # rather than a slow parse (review finding A6, 2026-09-12).
        #
        # Q-022 chose this over rejecting the whole block. A clean lite review
        # only ever means "proceed to the full review", so a model refusal that
        # parses as 0 rows costs nothing downstream; a new parse-failure
        # condition would cost the review-fix loop the tokens lite review exists
        # to save.
        if "|" not in line:
            continue
        m = FINDING_RE.match(line)
        if m:
            rows.append({
                "path": m.group("path").strip(),
                "lines": (m.group("lines") or "").strip(),
                "severity": m.group("sev").capitalize(),
                "domain": m.group("domain").strip(),
                "title": m.group("title").strip(),
                "description": m.group("desc").strip(),
            })
    return rows, bool(rows) or "FINDINGS" in text


def run_claude(prompt, model, timeout_s):
    """One headless subscription call; returns the decoded JSON envelope."""
    with tempfile.TemporaryDirectory(prefix="lite-review-") as empty_cwd:
        proc = subprocess.run(
            [
                "claude", "-p",
                "--model", model,
                "--output-format", "json",
                "--system-prompt", SYSTEM_PROMPT,
                "--tools", "",
                "--no-session-persistence",
            ],
            input=prompt,
            cwd=empty_cwd,  # empty non-repo dir: no CLAUDE.md auto-discovery
            capture_output=True, text=True, timeout=timeout_s,
        )
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        sys.exit(f"lite-review: claude output was not JSON (exit {proc.returncode}):\n"
                 f"{proc.stdout[:2000]}\n{proc.stderr[:2000]}")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--repo", default=".", help="path to the git repo (read-only use)")
    ap.add_argument("--range", dest="rev_range", required=True,
                    help="git diff range, e.g. 'HEAD~1..HEAD'")
    ap.add_argument("--mode", choices=["full", "fix-drift"], default="full")
    ap.add_argument("--model", default=DEFAULT_MODEL)
    ap.add_argument("--out", help="directory for findings.json + raw envelope (optional)")
    ap.add_argument("--max-diff-kb", type=int, default=192,
                    help="abort if the diff exceeds this (a diff this large "
                         "needs the full review path, not a lite pass)")
    ap.add_argument("--timeout", type=int, default=600, help="seconds per call")
    args = ap.parse_args()

    diff = sh(["git", "diff", args.rev_range], cwd=args.repo)
    if not diff.strip():
        print("lite-review: empty diff, nothing to review")
        return 0
    if len(diff) > args.max_diff_kb * 1024:
        sys.exit(f"lite-review: diff is {len(diff)//1024}KB > --max-diff-kb "
                 f"{args.max_diff_kb}; use the full review path")

    template = PROMPT_FIX_DRIFT if args.mode == "fix-drift" else PROMPT_FULL
    prompt = template.format(label=args.rev_range, diff=diff)

    env = run_claude(prompt, args.model, args.timeout)
    # judge by the envelope, not the exit code
    if env.get("is_error") or env.get("subtype") != "success":
        sys.exit(f"lite-review: call failed: is_error={env.get('is_error')} "
                 f"subtype={env.get('subtype')} result={str(env.get('result'))[:500]}")

    text = env.get("result", "")
    findings, parse_ok = parse_findings(text)

    usage = env.get("usage", {})
    record = {
        "mode": args.mode,
        "model": args.model,
        "range": args.rev_range,
        "parse_ok": parse_ok,
        "n_findings": len(findings),
        "findings": findings,
        "tokens": {
            "input": usage.get("input_tokens"),
            "output": usage.get("output_tokens"),
            "cache_creation": usage.get("cache_creation_input_tokens"),
            "cache_read": usage.get("cache_read_input_tokens"),
        },
        "num_turns": env.get("num_turns"),
    }

    if args.out:
        os.makedirs(args.out, exist_ok=True)
        with open(os.path.join(args.out, "findings.json"), "w") as fh:
            json.dump(record, fh, indent=2)
        with open(os.path.join(args.out, "raw-envelope.json"), "w") as fh:
            json.dump(env, fh, indent=2)

    if not parse_ok:
        print(f"lite-review: PARSE FAILURE - raw output:\n{text}")
        return 2
    if not findings:
        print(f"lite-review [{args.mode}]: FINDINGS: NONE "
              f"({record['tokens']['output']} out-tokens)")
        return 0
    print(f"lite-review [{args.mode}]: {len(findings)} finding(s):")
    for i, f in enumerate(findings, 1):
        loc = f"{f['path']}:{f['lines']}" if f["lines"] else f["path"]
        print(f"  {i}. {loc} | {f['severity']} | {f['domain']} | {f['title']}")
        print(f"     {f['description']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
