#!/usr/bin/env python3
"""Cross-model code-review harness (OpenRouter).

Runs the same diff-inline review prompt against N models via the OpenRouter
chat-completions API, normalizes the findings, computes pairwise overlap
(same-model replicates vs cross-model pairs), and emits a JSONL corpus plus a
summary table. This is the standalone `review_once()` entry point the
measurement-harness design calls for: explicit SHAs in, findings out, no
orchestrating agent required.

Design notes (see docs/working/experiment-results-code-review-2026-07-29.md):
- Diff is pasted inline; the model gets NO tools. This deliberately matches the
  session experiments' headless arm (opus 5 vs 4.8), not the agentic arm, so
  cross-provider numbers are comparable: agentic context-fetch would confound
  model identity with retrieval behavior (tracker Thread 2).
- Stage-1 context enrichment (decision 021, via --context-base): the
  prompt gains (a) the sibling-branch diff from --context-base to the range
  start, explicitly labelled "already committed - context only, not under
  review", and (b) the full post-range contents of every file the reviewed
  diff touches. This kills the sibling-commit / flattened-boundary
  misattribution FP class (Results 3c & 5) while staying git-only, no-tools,
  and byte-identical across models. VALIDATED 2026-07-31
  (docs/working/experiment-stage1-fp-kill-2026-07-31.md): the D3/D4 re-run
  reproduced neither FP in 0/8 replicates each, and cross-family agreement on
  real issues rose among the Sonnet/Gemini/Sol pairs on D3 (a redistribution:
  the two largest Kimi pairs fell; D4's comparable pairs fell). --context-base is
  therefore the RECOMMENDED mode for any review-quality use; run diff-only
  only as a deliberate recall probe or for comparability with pre-021
  measurements (live diff-only runs print a warning to stderr). Files larger
  than --max-inline-kb, binary/undecodable files, and files that would push
  the running inlined total over the --max-total-inline-kb aggregate budget
  are listed but not inlined (best-fit skip: later smaller files that still
  fit are inlined; function-body extraction is the designated large-file
  fallback, not yet built). Section
  delimiters carry a nonce derived from the diff, so inlined repo content
  cannot forge an "UNDER REVIEW"/"CONTEXT ONLY" boundary. Without
  --context-base the prompt is byte-identical to the pre-021 harness, so
  historical numbers stay comparable.
- WARNING: --context-base ships whole repo files and the sibling-branch diff
  to third-party model APIs, with no secret screening, and --dry-run persists
  the full prompt to <out>/prompt.txt. Use only on repos whose full contents
  you are willing to send and store. prompt.txt is a whole-repo (or, with
  --repo, a foreign-repo) snapshot: keep --out outside any tree you commit,
  or rely on the runs/**/prompt.txt gitignore rule — never `git add` it.
- --dry-run builds the prompt, writes it to <out>/prompt.txt, and prints
  per-section character counts, an aggregate token estimate, and projected
  per-model cost WITHOUT sending anything (pricing fetch is skipped if
  OPENROUTER_API_KEY is unset).
- Stage-1 matching is deterministic (same file + line ranges within +/-N).
  Stage-2 (same-underlying-issue) is a judge-model call, pinned by --judge;
  changing the judge invalidates prior numbers, so the judge id is stamped
  into every output row.
- Temperature is NOT set (provider default) because several providers reject
  or silently remap it; replicate variance is therefore "as deployed".
- DO NOT add prompt caching (`cache_control` breakpoints) here. This is the
  cross-model *sweep*: its confound control requires prompts that are
  byte-identical ACROSS models and stamped by prompt_sha, and caching is a
  per-provider cost lever that would confound cost/latency across families and
  add a non-byte-identical field to the request. Prompt caching is adopted only
  on the production review loop (the code-review SKILL's Agent-tool dispatch),
  fenced off this path on purpose — decision 032 (#3 / H4). If you want cache
  behavior for a live headless review, do it in the SKILL loop, not in this
  benchmark harness.

Usage:
  export OPENROUTER_API_KEY=sk-or-...
  scripts/cross-model-review.py \
    --repo /path/to/repo --range 'abc123~1..abc123' \
    --models anthropic/claude-opus-4.5 openai/gpt-5.2 google/gemini-3-pro \
    --replicates 2 \
    --out runs/cross-model/abc123

  # overlap-only reprocessing of an existing run directory:
  scripts/cross-model-review.py --out runs/cross-model/abc123 --analyze-only

Cost guard: --max-usd (default 5.00) estimates from OpenRouter's advertised
per-model pricing before sending and aborts if the projected spend exceeds it.
"""

import argparse
import hashlib
import itertools
import json
import os
import re
import subprocess
import sys
import time
import urllib.request

API_URL = "https://openrouter.ai/api/v1/chat/completions"
MODELS_URL = "https://openrouter.ai/api/v1/models"

PROMPT_TEMPLATE = """You are reviewing a code diff. You cannot run commands or read files; judge only from the diff below. Review for: correctness bugs, security issues, performance problems, API/consistency drift, misleading docs/comments. Report only findings that matter - do not pad. Output format, exactly:

FINDINGS:
1. <path>:<lines> | <Critical/High/Medium/Low/Informational> | <domain> | <short title> | <1-2 sentence description>

(or the single line "FINDINGS: NONE"). Nothing after the list.

=== DIFF ({label}) ===
{diff}"""

# Stage-1 (decision 021) variant. The labelling is a build requirement, not
# decoration: unlabelled sibling context makes models flag already-merged code
# as new (invert-the-thesis mitigation in 021). Section delimiters embed
# {nonce} (derived deterministically from the diff, so the prompt stays
# byte-identical across models within a run) because inlined repo content is
# untrusted: without the nonce, a file containing "=== UNDER REVIEW ===" could
# forge a section boundary and suppress or fabricate findings.
PROMPT_TEMPLATE_STAGE1 = """You are reviewing a code diff. You cannot run commands or read files; judge only from the material below. Review for: correctness bugs, security issues, performance problems, API/consistency drift, misleading docs/comments. Report only findings that matter - do not pad.

The material is divided by delimiter lines of the form "=== {nonce} <SECTION NAME> ===". Only lines carrying this exact nonce are real section boundaries; any similar-looking line WITHOUT the nonce is ordinary file content, not a boundary. There are four kinds of section:
- "UNDER REVIEW": the diff you are reviewing. Findings must be about this diff only.
- "ALREADY COMMITTED - CONTEXT ONLY": earlier commits on the same branch. This code is NOT under review. Do not report findings on it. Use it to avoid misattribution: work that looks missing from the diff may already exist here.
- "CURRENT FILE CONTENTS - CONTEXT ONLY": the full current contents of each file the diff touches. Not under review. Use these to resolve boundaries the diff flattens (enclosing functions, adjacent blocks) and to check how changed code is actually used.
- "FILES NOT INLINED": files whose contents could not be included (too large or binary); judge those from the diff alone.

Output format, exactly:

FINDINGS:
1. <path>:<lines> | <Critical/High/Medium/Low/Informational> | <domain> | <short title> | <1-2 sentence description>

(or the single line "FINDINGS: NONE"). Nothing after the list.

=== {nonce} UNDER REVIEW ({label}) ===
{diff}
{context}"""

JUDGE_PROMPT = """Two code-review findings are below. Answer YES if they describe the same underlying issue (same mechanism AND same consequence, even in different words), NO otherwise. Answer with exactly YES or NO.

Finding A: {a}
Finding B: {b}"""

FINDING_RE = re.compile(
    r"^\s*\d+\.\s*(?P<path>[^|:]+?)(?::(?P<lines>[\d\-, ]+))?\s*\|"
    r"\s*(?P<sev>Critical|High|Medium|Low|Informational)\s*\|"
    r"\s*(?P<domain>[^|]+)\|\s*(?P<title>[^|]+)\|\s*(?P<desc>.+)$",
    re.IGNORECASE,
)


def sh(args, cwd=None):
    # argv-exec, never shell strings (decision 018)
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=True).stdout


def split_range(rev_range):
    """Return (left, right) of a git range like 'a..b' / 'a...b'; right defaults to HEAD.

    Caller-semantics note: build_stage1_context uses `left` as the sibling-section
    boundary. For a two-dot range that is exactly the range start. For a THREE-dot
    range the reviewed diff (`git diff a...b`) is based at merge-base(a, b), so
    commits between the merge-base and `a` fall into the reviewed diff's baseline
    rather than the sibling section — sibling context can overlap the reviewed
    diff. All current callers use two-dot ranges; pass two-dot ranges with
    --context-base until this is normalized.
    """
    parts = re.split(r"\.{2,3}", rev_range, maxsplit=1)
    left = parts[0].strip()
    right = parts[1].strip() if len(parts) > 1 and parts[1].strip() else "HEAD"
    return left, right


def stage1_nonce(diff):
    """Deterministic delimiter nonce: same diff -> same nonce -> byte-identical
    prompts across models within a run (H3), while inlined repo content cannot
    predictably... (it CAN read the diff, so this defends against committed
    static collisions like literal '=== UNDER REVIEW ===' strings, not against
    an adversary crafting the reviewed diff itself - acceptable for an
    own-repo measurement harness)."""
    return hashlib.sha256(diff.encode()).hexdigest()[:10]


def build_stage1_context(repo, rev_range, context_base, max_inline_kb, nonce,
                         max_total_inline_kb=256):
    """Assemble decision-021 Stage-1 context sections.

    Returns (context_text, stats): stats has sibling_diff / enclosing_files as
    inlined character counts and skipped_files as a file count, consumed by the
    dry-run printout. Sections (delimiters carry the run nonce):
      1. sibling-branch diff: context_base...<range-left>, i.e. the commits of the
         logical changeset already committed before the range under review.
      2. whole enclosing files: post-range (<range-right>) contents of every file
         the reviewed diff touches. Files over max_inline_kb, and binary or
         undecodable files, are listed under FILES NOT INLINED rather than
         included (021 reserves function-body extraction as the large-file
         fallback; until that exists, an explicit omission beats a silent one).
    """
    left, right = split_range(rev_range)
    parts = []
    stats = {}

    def header(title):
        return f"\n=== {nonce} {title} ===\n"

    # -c core.quotepath=off: with the default, non-ASCII paths come back
    # escaped/quoted from --name-only and then fail `git show`, which would
    # falsely report the file as deleted.
    gitq = ["git", "-C", repo, "-c", "core.quotepath=off"]

    sibling = sh(gitq + ["diff", f"{context_base}...{left}"])
    if sibling.strip():
        parts.append(header(f"ALREADY COMMITTED - CONTEXT ONLY, NOT UNDER REVIEW "
                            f"(branch diff {context_base}...{left})") + sibling)
        stats["sibling_diff"] = len(sibling)
    else:
        parts.append(header("ALREADY COMMITTED - CONTEXT ONLY") + f"(none: no sibling "
                     f"commits between {context_base} and the range start)\n")
        stats["sibling_diff"] = 0

    touched = [p for p in sh(
        gitq + ["diff", "--name-only", rev_range]).splitlines() if p.strip()]
    inlined, skipped = 0, []
    for path in touched:
        try:
            content = sh(gitq + ["show", f"{right}:{path}"])
        except subprocess.CalledProcessError:
            # deleted by the range (or rename target missing at right): nothing to inline
            parts.append(header(f"CURRENT FILE CONTENTS - CONTEXT ONLY ({path})")
                         + f"(file does not exist at {right} - deleted or renamed by the diff)\n")
            continue
        except UnicodeDecodeError:
            # sh() decodes strictly; a genuinely binary file lands here, not at
            # the NUL sniff below. Size via cat-file since the content is unreadable.
            try:
                size = int(sh(gitq + ["cat-file", "-s", f"{right}:{path}"]).strip())
            except (subprocess.CalledProcessError, ValueError):
                size = 0
            skipped.append((path, size, "binary (undecodable)"))
            continue
        if "\x00" in content[:8192]:
            skipped.append((path, len(content), "binary"))
            continue
        if len(content) > max_inline_kb * 1024:
            skipped.append((path, len(content), "over --max-inline-kb"))
            continue
        # Aggregate budget: --max-inline-kb caps each file, but a wide diff could
        # otherwise grow the prompt linearly in touched-file count (50 files ~ 3 MB).
        # Spill overflow into the existing FILES NOT INLINED section rather than
        # relying on the dollar-denominated --max-usd abort as the only backstop.
        if inlined + len(content) > max_total_inline_kb * 1024:
            skipped.append((path, len(content), "over --max-total-inline-kb (aggregate)"))
            continue
        parts.append(header(f"CURRENT FILE CONTENTS - CONTEXT ONLY ({path} at {right})")
                     + content)
        inlined += len(content)
    if skipped:
        lines = "\n".join(f"- {p} ({n // 1024} KB, {why})" for p, n, why in skipped)
        parts.append(header("FILES NOT INLINED (too large or binary; judge these "
                            "from the diff alone)") + lines + "\n")
    stats["enclosing_files"] = inlined
    stats["skipped_files"] = len(skipped)
    return "".join(parts), stats


def api(key, payload, retries=3):
    body = json.dumps(payload).encode()
    for attempt in range(retries):
        req = urllib.request.Request(
            API_URL,
            data=body,
            headers={
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json",
                # OpenRouter attribution headers (optional but polite)
                "HTTP-Referer": "https://github.com/magfrump/claude-workflows",
                "X-Title": "cross-model-review harness",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=600) as resp:
                return json.load(resp)
        except Exception as e:  # noqa: BLE001 - retry any transport/5xx error
            if attempt == retries - 1:
                raise
            time.sleep(5 * (attempt + 1))
            last = e  # noqa: F841


def fetch_pricing(key):
    """Return {model_id: (prompt_usd_per_tok, completion_usd_per_tok)} from the live API."""
    req = urllib.request.Request(MODELS_URL, headers={"Authorization": f"Bearer {key}"})
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = json.load(resp)
        out = {}
        for m in data.get("data", []):
            p = m.get("pricing", {})
            out[m["id"]] = (float(p.get("prompt", 0)), float(p.get("completion", 0)))
        return out
    except Exception:  # offline / analyze-only paths don't need pricing
        return {}


def parse_findings(text):
    """Parse the FINDINGS block; returns (findings, parse_ok)."""
    if re.search(r"FINDINGS:\s*NONE", text, re.IGNORECASE):
        return [], True
    rows = []
    in_block = False
    for line in text.splitlines():
        if re.match(r"\s*FINDINGS\s*:", line):
            in_block = True
            continue
        if not in_block:
            continue
        m = FINDING_RE.match(line)
        if m:
            d = {k: (v.strip() if v else v) for k, v in m.groupdict().items()}
            # normalize basename-shorthand hazard: keep both raw and basename
            d["basename"] = os.path.basename(d["path"])
            lines = re.findall(r"\d+", d.get("lines") or "")
            d["line_start"] = int(lines[0]) if lines else None
            d["line_end"] = int(lines[-1]) if lines else d["line_start"]
            rows.append(d)
    return rows, in_block or bool(rows)


def stage1_candidates(a, b, slack):
    """Deterministic pre-filter: same basename AND line ranges overlap within slack."""
    if a["basename"] != b["basename"]:
        return False
    if a["line_start"] is None or b["line_start"] is None:
        return True  # can't rule out on lines; let the judge decide
    return not (
        a["line_end"] + slack < b["line_start"]
        or b["line_end"] + slack < a["line_start"]
    )


def judge_same(key, judge_model, a, b):
    fa = f"{a['path']}:{a.get('lines')} {a['title']} - {a['desc']}"
    fb = f"{b['path']}:{b.get('lines')} {b['title']} - {b['desc']}"
    resp = api(
        key,
        {
            "model": judge_model,
            "messages": [{"role": "user", "content": JUDGE_PROMPT.format(a=fa, b=fb)}],
            "max_tokens": 4,
        },
    )
    return "YES" in resp["choices"][0]["message"]["content"].upper()


def jaccard(fa, fb, key, judge_model, slack):
    """Issue-level Jaccard between two finding lists via union-find over matches."""
    if not fa and not fb:
        return 1.0, 0  # both clean: agreement
    if not fa or not fb:
        return 0.0, 0
    matches = 0
    matched_b = set()
    for x in fa:
        for j, y in enumerate(fb):
            if j in matched_b or not stage1_candidates(x, y, slack):
                continue
            if judge_same(key, judge_model, x, y):
                matches += 1
                matched_b.add(j)
                break
    union = len(fa) + len(fb) - matches
    return matches / union, matches


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--repo", help="path to the git repo (read-only use)")
    ap.add_argument("--range", dest="rev_range", help="git diff range, e.g. 'abc~1..abc'")
    ap.add_argument("--models", nargs="+", default=[], help="OpenRouter model ids")
    ap.add_argument("--replicates", type=int, default=2)
    ap.add_argument("--judge", default="anthropic/claude-sonnet-4.5", help="pinned judge model for stage-2 matching")
    ap.add_argument("--slack", type=int, default=5, help="line-overlap slack for stage-1 matching")
    ap.add_argument("--max-usd", type=float, default=5.00, help="abort if projected spend exceeds this")
    ap.add_argument("--out", required=True, help="output directory")
    ap.add_argument("--analyze-only", action="store_true", help="recompute overlap from existing findings.jsonl")
    ap.add_argument("--context-base", help="decision-021 Stage 1: enrich the prompt with the "
                    "sibling-branch diff from this ref to the range start, plus whole enclosing "
                    "files. RECOMMENDED for review-quality use (validated 2026-07-31; see module "
                    "docstring). Omit only for a deliberate diff-only recall probe or pre-021 "
                    "comparability.")
    ap.add_argument("--max-inline-kb", type=int, default=64, help="Stage 1: files larger than "
                    "this are listed but not inlined")
    ap.add_argument("--max-total-inline-kb", type=int, default=256, help="Stage 1: aggregate "
                    "budget for inlined enclosing files; a file that would push the running "
                    "total over the budget is listed but not inlined (later smaller files "
                    "that still fit are inlined — best-fit skip, not a hard stop)")
    ap.add_argument("--dry-run", action="store_true", help="build the prompt, write it to "
                    "<out>/prompt.txt, print token/cost projections, and exit without calling any model")
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    findings_path = os.path.join(args.out, "findings.jsonl")
    key = os.environ.get("OPENROUTER_API_KEY", "")

    if not args.analyze_only:
        if not key and not args.dry_run:
            sys.exit("OPENROUTER_API_KEY not set")
        if not (args.repo and args.rev_range):
            sys.exit("--repo and --range are required unless --analyze-only")
        if not args.models and not args.dry_run:
            sys.exit("--models is required unless --dry-run or --analyze-only")

        diff = sh(["git", "-C", args.repo, "diff", args.rev_range])
        if not diff.strip():
            sys.exit(f"empty diff for range {args.rev_range}")
        label = f"{os.path.basename(args.repo)} {args.rev_range}"
        if args.context_base:
            nonce = stage1_nonce(diff)
            context, ctx_stats = build_stage1_context(
                args.repo, args.rev_range, args.context_base, args.max_inline_kb, nonce,
                args.max_total_inline_kb)
            prompt = PROMPT_TEMPLATE_STAGE1.format(
                label=label, diff=diff, context=context, nonce=nonce)
        else:
            context, ctx_stats = "", {}
            prompt = PROMPT_TEMPLATE.format(label=label, diff=diff)
        prompt_sha = hashlib.sha256(prompt.encode()).hexdigest()[:12]

        # cost guard: ~4 chars/token heuristic on input, assume 1.5k output tokens/run
        pricing = fetch_pricing(key) if key else {}
        est_in_tok = len(prompt) / 4
        projected = 0.0
        for m in args.models:
            pin, pout = pricing.get(m, (0, 0))
            projected += args.replicates * (est_in_tok * pin + 1500 * pout)
        mode = f"stage1(base={args.context_base})" if args.context_base else "diff-only"
        print(f"context mode: {mode}, prompt sha {prompt_sha}")
        print(f"prompt size: {len(prompt):,} chars, ~{int(est_in_tok):,} tokens "
              f"(diff {len(diff):,} chars"
              + (f", sibling diff {ctx_stats.get('sibling_diff', 0):,}, enclosing files "
                 f"{ctx_stats.get('enclosing_files', 0):,}, "
                 f"{ctx_stats.get('skipped_files', 0)} skipped" if args.context_base else "")
              + ")")
        # Unpriced models must fail the guard closed, not project $0.00: a
        # pricing-fetch failure (or an unknown model id) would otherwise let a
        # real-priced sweep sail under any --max-usd cap.
        unpriced = [m for m in args.models if pricing.get(m, (0, 0)) == (0, 0)]
        if args.models and pricing and not unpriced:
            print(f"projected spend: ${projected:.2f} across {len(args.models)} models x {args.replicates}")
            for m in args.models:
                pin, pout = pricing.get(m, (0, 0))
                per_call = est_in_tok * pin + 1500 * pout
                print(f"  {m}: ~${per_call:.3f}/call")
        elif args.models:
            print(f"no pricing available for: {', '.join(unpriced) or 'any model'} — no $ projection")
        if args.dry_run:
            with open(os.path.join(args.out, "prompt.txt"), "w") as fh:
                fh.write(prompt)
            print(f"dry run: prompt written to {os.path.join(args.out, 'prompt.txt')}; no calls made")
            return
        if not args.context_base:
            # Decision 021 + the 2026-07-31 FP-kill validation: diff-only manufactures
            # sibling-commit/flattened-boundary FPs; Stage-1 context is the review-quality mode.
            print("WARNING: diff-only mode is a recall probe with a known misattribution "
                  "FP class (decision 021; validated fix: --context-base). Findings from "
                  "this run must not be treated as review verdicts.", file=sys.stderr)
        if unpriced:
            sys.exit(f"cost guard cannot price: {', '.join(unpriced)} — refusing to send "
                     f"(pricing fetch failed or unknown model id); re-run when pricing resolves")
        if projected > args.max_usd:
            sys.exit(f"projected ${projected:.2f} > --max-usd {args.max_usd}; raise the cap to proceed")

        with open(findings_path, "w") as fh:
            for model in args.models:
                for r in range(1, args.replicates + 1):
                    t0 = time.time()
                    # A model that is unavailable to this account (402/404 tier gating) must
                    # not abort the sweep: record the failure and keep the other models going.
                    try:
                        resp = api(key, {"model": model, "messages": [{"role": "user", "content": prompt}]})
                    except Exception as e:  # noqa: BLE001 - per-run isolation is the point
                        code = getattr(e, "code", "")
                        fh.write(json.dumps({
                            "model": model, "replicate": r, "prompt_sha": prompt_sha,
                            "range": args.rev_range, "repo": os.path.basename(args.repo),
                            "context_base": args.context_base,
                            "error": f"{type(e).__name__} {code}".strip(),
                            "parse_ok": False, "n_findings": 0, "findings": [],
                        }) + "\n")
                        fh.flush()
                        print(f"{model} r{r}: ERROR {type(e).__name__} {code}")
                        continue
                    # Reasoning models (e.g. kimi-k3) return message.content = null when the
                    # completion budget is spent inside the reasoning trace. Treat that as a
                    # failed run rather than a clean "no findings" one.
                    choice = resp["choices"][0]
                    text = choice["message"].get("content") or ""
                    finish = choice.get("finish_reason")
                    rows, ok = parse_findings(text)
                    if not text.strip():
                        fh.write(json.dumps({
                            "model": model, "replicate": r, "prompt_sha": prompt_sha,
                            "range": args.rev_range, "repo": os.path.basename(args.repo),
                            "context_base": args.context_base,
                            "error": f"empty-content finish_reason={finish}",
                            "parse_ok": False, "n_findings": 0, "findings": [],
                        }) + "\n")
                        fh.flush()
                        print(f"{model} r{r}: ERROR empty content (finish_reason={finish})")
                        continue
                    usage = resp.get("usage", {})
                    rec = {
                        "model": model,
                        "replicate": r,
                        "prompt_sha": prompt_sha,
                        "range": args.rev_range,
                        "repo": os.path.basename(args.repo),
                        "context_base": args.context_base,
                        "parse_ok": ok,
                        "n_findings": len(rows),
                        "findings": rows,
                        "raw": text,
                        "usage": usage,
                        "latency_s": round(time.time() - t0, 1),
                    }
                    fh.write(json.dumps(rec) + "\n")
                    fh.flush()
                    print(f"{model} r{r}: {len(rows)} findings ({rec['latency_s']}s, parse_ok={ok})")

    # ---- analysis ----
    runs = [json.loads(l) for l in open(findings_path)]
    # Overlap across different prompts measures prompt variance, not model
    # variance — warn when the corpus mixes context modes or prompt versions.
    variants = {(r.get("prompt_sha"), r.get("context_base")) for r in runs}
    if len(variants) > 1:
        print(f"WARNING: findings.jsonl mixes {len(variants)} (prompt_sha, context_base) "
              f"variants — overlap numbers below pool across different prompts",
              file=sys.stderr)
    # Errored runs are absent, not clean — counting them as empty finding lists would
    # score a failed call as perfect agreement with another failed call.
    errored = [r for r in runs if r.get("error")]
    if errored:
        print(f"\n({len(errored)} errored runs excluded from overlap: "
              f"{sorted({r['model'] + ' ' + r['error'] for r in errored})})")
    runs = [r for r in runs if not r.get("error")]
    by_key = {(r["model"], r["replicate"]): r["findings"] for r in runs}
    models = sorted({r["model"] for r in runs})
    reps = sorted({r["replicate"] for r in runs})

    if not key:
        print("\n(no OPENROUTER_API_KEY: stage-2 judge unavailable; reporting stage-1-only overlap)")

    def pair_j(k1, k2):
        if key:
            j, _ = jaccard(by_key[k1], by_key[k2], key, args.judge, args.slack)
            return j
        # degraded stage-1-only mode
        fa, fb = by_key[k1], by_key[k2]
        if not fa and not fb:
            return 1.0
        if not fa or not fb:
            return 0.0
        # Greedy one-to-one match: each fb finding can be claimed at most once.
        # Counting "every fa with any candidate" instead lets several fa map to one
        # fb, so matches can exceed |fb|, making union < matches and Jaccard > 1.
        matched_b = set()
        m = 0
        for x in fa:
            for j, y in enumerate(fb):
                if j in matched_b or not stage1_candidates(x, y, args.slack):
                    continue
                matched_b.add(j)
                m += 1
                break
        return m / (len(fa) + len(fb) - m)

    # Abstention rate makes the empty-vs-empty artifact visible: jaccard() scores two
    # empty finding lists as 1.0 agreement, so a model that abstains on every replicate
    # gets a perfect J_self. Report the fraction of (non-errored) replicates a model
    # returned zero findings on, so a high J_self driven by abstention is legible.
    abstain = {}
    for m in models:
        runs_m = [r for r in runs if r["model"] == m]
        if runs_m:
            abstain[m] = round(sum(1 for r in runs_m if not r["findings"]) / len(runs_m), 3)

    results = {"judge": args.judge if key else "stage1-only", "abstain": abstain, "self": {}, "cross": {}}
    for m in models:
        pairs = [pair_j((m, a), (m, b)) for a, b in itertools.combinations(reps, 2) if (m, a) in by_key and (m, b) in by_key]
        if pairs:
            results["self"][m] = round(sum(pairs) / len(pairs), 3)
    for m1, m2 in itertools.combinations(models, 2):
        pairs = [pair_j((m1, a), (m2, b)) for a in reps for b in reps if (m1, a) in by_key and (m2, b) in by_key]
        if pairs:
            results["cross"][f"{m1} vs {m2}"] = round(sum(pairs) / len(pairs), 3)

    with open(os.path.join(args.out, "overlap.json"), "w") as fh:
        json.dump(results, fh, indent=2)

    print("\n== abstention rate (fraction of replicates with zero findings) ==")
    for m, v in abstain.items():
        print(f"  {m}: {v}")
    print("== J_self (same model, replicate pairs) ==")
    for m, v in results["self"].items():
        print(f"  {m}: {v}")
    print("== J_cross (model pairs, all replicate combinations) ==")
    for p, v in results["cross"].items():
        print(f"  {p}: {v}")
    print(f"\nInterpretation: J_self ~= J_cross => model identity adds no signal beyond "
          f"resampling (tracker Thread 1). J_cross << J_self => models see genuinely "
          f"different issue populations => cross-model union buys recall.")
    print(f"outputs: {findings_path}, {os.path.join(args.out, 'overlap.json')}")


if __name__ == "__main__":
    main()
