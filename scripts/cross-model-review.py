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
- Stage-1 matching is deterministic (same file + line ranges within +/-N).
  Stage-2 (same-underlying-issue) is a judge-model call, pinned by --judge;
  changing the judge invalidates prior numbers, so the judge id is stamped
  into every output row.
- Temperature is NOT set (provider default) because several providers reject
  or silently remap it; replicate variance is therefore "as deployed".

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
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    findings_path = os.path.join(args.out, "findings.jsonl")
    key = os.environ.get("OPENROUTER_API_KEY", "")

    if not args.analyze_only:
        if not key:
            sys.exit("OPENROUTER_API_KEY not set")
        if not (args.repo and args.rev_range and args.models):
            sys.exit("--repo, --range, and --models are required unless --analyze-only")

        diff = sh(["git", "-C", args.repo, "diff", args.rev_range])
        if not diff.strip():
            sys.exit(f"empty diff for range {args.rev_range}")
        prompt = PROMPT_TEMPLATE.format(label=f"{os.path.basename(args.repo)} {args.rev_range}", diff=diff)
        prompt_sha = hashlib.sha256(prompt.encode()).hexdigest()[:12]

        # cost guard: ~4 chars/token heuristic on input, assume 1.5k output tokens/run
        pricing = fetch_pricing(key)
        est_in_tok = len(prompt) / 4
        projected = 0.0
        for m in args.models:
            pin, pout = pricing.get(m, (0, 0))
            projected += args.replicates * (est_in_tok * pin + 1500 * pout)
        print(f"projected spend: ${projected:.2f} across {len(args.models)} models x {args.replicates}")
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
