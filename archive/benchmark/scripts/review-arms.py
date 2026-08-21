#!/usr/bin/env python3
"""Named lightweight-review arm set (decision 030) over cross-model-review.py.

Decision 030 promoted the Stage-1 context harness (decision 021,
scripts/cross-model-review.py --context-base) to be *the* lightweight review
path and queued a small portfolio of cheap variants to test against it. This
wrapper packages that portfolio as named, runnable configs so a local project
can be reviewed under several processes side by side at ~$0.03-0.35/call
instead of the ~$14.6/instance agentic orchestrator:

  base   [030 arm 0]  Stage-1 context, k=1, mid-tier model (sonnet-5).
                      The promoted default; validated 2026-07-31 (FP-kill 0/8).
  small  [030 arm 3]  Same config pinned to a Sol-class model - the cost
                      floor. Hypothesis: >=60% of base's verified-bug recall
                      at <=1/3 cost.
  k3     [030 arm 7]  Same config, k=3 replicates, keep only findings that
                      >=2 replicates agree on (consensus filter, implemented
                      here as post-processing over findings.jsonl).
                      Hypothesis: cuts FP-class findings >=30% vs k=1.

Not included: 030 arm [8] (rubric/checklist single call) - demoted to
build-only-if-base-precision-proves-deficient; see the decision record.

Each arm shells out to cross-model-review.py (the engine is unchanged; prompts
stay byte-identical to the validated config). The wrapper adds arm naming,
a shared output layout, the consensus filter, and a cross-arm summary.

Usage:
  export OPENROUTER_API_KEY=sk-or-...
  scripts/review-arms.py --repo /path/to/repo --range 'main..HEAD' \
      --context-base main --out runs/review-arms/myproj-2026-08-06
  # cost preview without sending anything:
  scripts/review-arms.py ... --dry-run
  # subset:
  scripts/review-arms.py ... --arms base small

WARNING (inherited from the engine): Stage-1 context ships whole repo files
and the branch diff to third-party model APIs with no secret screening. Only
point this at repos whose full contents you are willing to send (decisions
021/030 restate this as a hard trigger: non-operator-owned repo => add a
secret-screening pass first).
"""

import argparse
import importlib.util
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ENGINE = os.path.join(HERE, "cross-model-review.py")

# The engine's filename has a dash, so load it as a module for the matching
# helpers (stage1_candidates / judge_same) rather than duplicating them.
_spec = importlib.util.spec_from_file_location("cross_model_review", ENGINE)
cmr = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cmr)

# Model pins follow the validated 2026-07-31 sweep families: sonnet-5 is the
# incumbent mid-tier family. The small arm is pinned to gemini-3.1-flash-lite
# ($0.25/$1.50 per M vs sonnet-5's $2/$10, checked 2026-08-06) - NOT gpt-5.6-sol,
# whose current pricing ($5/$30) is ~2.7x sonnet-5 despite the 2026-07-30
# experiment notes calling Sol cheap; only <=1/3 of base cost satisfies the 030
# arm-[3] hypothesis premise. Gemini is one of the four FP-validated families
# (at pro tier - the flash-lite tier still owes a D3/D4 FP re-check, 030's
# per-model re-validation duty).
ARMS = {
    "base": {"model": "anthropic/claude-sonnet-5", "replicates": 1, "consensus": None,
             "note": "030 arm [0]: promoted Stage-1 default, k=1"},
    "small": {"model": "google/gemini-3.1-flash-lite", "replicates": 1, "consensus": None,
              "note": "030 arm [3]: cost floor (~1/8 base input price)"},
    "k3": {"model": "anthropic/claude-sonnet-5", "replicates": 3, "consensus": 2,
           "note": "030 arm [7]: keep findings >=2 of 3 replicates agree on"},
    # E4 middle-ground arm (2026-08-13): opus-tier model + k=3 replication,
    # scored primarily as the UNION of replicate findings (fact-check-style
    # most-severe-wins, per canon evidence that union buys recall while
    # consensus does not buy precision). consensus=2 is still computed as a
    # free secondary metric. Opus 5 = $5/$25 per M on OpenRouter vs sonnet-5's
    # intro $2/$10, so a k=3 sweep projects ~7.5x the E2 base sweep ($0.81).
    "opus-k3": {"model": "anthropic/claude-opus-5", "replicates": 3, "consensus": 2,
                "note": "E4 middle ground: opus 5, k=3, union-scored"},
}


def consensus_filter(findings_path, min_votes, slack, key, judge_model):
    """Cluster one model's findings across replicates; keep clusters with
    >= min_votes distinct replicates. Matching reuses the engine's stage-1
    deterministic pre-filter, escalating to the stage-2 judge call only when a
    key is available (without one, stage-1 candidacy alone counts as a match -
    looser, but deterministic and free)."""
    runs = [json.loads(l) for l in open(findings_path)]
    runs = [r for r in runs if not r.get("error")]
    clusters = []  # each: {"finding": representative, "votes": set(replicates)}
    for r in runs:
        for f in r["findings"]:
            placed = False
            for c in clusters:
                if not cmr.stage1_candidates(f, c["finding"], slack):
                    continue
                if key and not cmr.judge_same(key, judge_model, f, c["finding"]):
                    continue
                c["votes"].add(r["replicate"])
                placed = True
                break
            if not placed:
                clusters.append({"finding": f, "votes": {r["replicate"]}})
    kept = [c for c in clusters if len(c["votes"]) >= min_votes]
    return kept, clusters


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--repo", required=True, help="path to the git repo (read-only)")
    ap.add_argument("--range", dest="rev_range", required=True,
                    help="git diff range under review, e.g. 'main..HEAD' (two-dot)")
    ap.add_argument("--context-base", required=True,
                    help="decision-021 Stage-1 context base (usually the branch base); "
                         "Stage-1 context is mandatory here - diff-only is a recall "
                         "probe, not a review process (decision 030)")
    ap.add_argument("--arms", nargs="+", default=list(ARMS), choices=list(ARMS),
                    help="which arms to run (default: all)")
    ap.add_argument("--out", required=True, help="output directory; one subdir per arm")
    ap.add_argument("--judge", default="anthropic/claude-sonnet-4.5",
                    help="pinned judge for consensus stage-2 matching")
    ap.add_argument("--slack", type=int, default=5)
    ap.add_argument("--max-usd", type=float, default=2.00,
                    help="per-arm engine cost cap (030 H1: a whole sweep should sit "
                         "well under the agentic path's single-instance cost)")
    ap.add_argument("--dry-run", action="store_true",
                    help="prompt build + cost projection per arm; no API calls")
    args = ap.parse_args()

    key = os.environ.get("OPENROUTER_API_KEY", "")

    # Auth preflight: /api/v1/key is the cheapest endpoint that actually
    # verifies the key. The engine's pricing fetch does NOT - /models is
    # public and accepts any Authorization header - so an invalid/expired key
    # otherwise sails past the cost guard and then 401s on every completion
    # call (each retried 3x with backoff). Fail once, up front, instead.
    if not args.dry_run:
        if not key:
            sys.exit("OPENROUTER_API_KEY not set (export it in this shell, or "
                     "use --dry-run for a no-key cost preview)")
        import urllib.error
        import urllib.request
        req = urllib.request.Request("https://openrouter.ai/api/v1/key",
                                     headers={"Authorization": f"Bearer {key}"})
        try:
            with urllib.request.urlopen(req, timeout=30):
                pass
        except urllib.error.HTTPError as e:
            if e.code == 401:
                sys.exit("OPENROUTER_API_KEY was rejected (401). Common causes: "
                         "expired/revoked key, a typo or trailing whitespace/"
                         "newline in the export, or the key was created under a "
                         "since-disabled org. Verify with:\n"
                         "  curl -s https://openrouter.ai/api/v1/key "
                         "-H \"Authorization: Bearer $OPENROUTER_API_KEY\"\n"
                         "and regenerate at https://openrouter.ai/keys if needed.")
            print(f"warning: key preflight returned HTTP {e.code}; "
                  f"proceeding (only 401 is treated as fatal)", file=sys.stderr)
        except Exception as e:  # noqa: BLE001 - network blip: don't block the run
            print(f"warning: key preflight failed ({type(e).__name__}); "
                  f"proceeding", file=sys.stderr)

    # Preflight the refs once, here, so a bad --range/--context-base fails with
    # an actionable message instead of a git traceback from inside each arm.
    left, right = cmr.split_range(args.rev_range)
    for label, ref in [("--range start", left), ("--range end", right),
                       ("--context-base", args.context_base)]:
        r = subprocess.run(["git", "-C", args.repo, "rev-parse", "--verify",
                            "--quiet", f"{ref}^{{commit}}"], capture_output=True)
        if r.returncode != 0:
            branches = subprocess.run(["git", "-C", args.repo, "branch",
                                       "--format=%(refname:short)"],
                                      capture_output=True, text=True).stdout.split()
            sys.exit(f"{label} ref '{ref}' does not resolve in {args.repo}\n"
                     f"local branches there: {', '.join(branches) or '(none)'}\n"
                     f"hint: repos without 'main' need explicit refs, e.g. "
                     f"--range 'HEAD~5..HEAD' --context-base HEAD~10, or the "
                     f"repo's actual base branch")
    if not subprocess.run(["git", "-C", args.repo, "diff", "--quiet",
                           args.rev_range], capture_output=True).returncode:
        sys.exit(f"empty diff for range {args.rev_range} in {args.repo} - "
                 f"nothing to review")

    os.makedirs(args.out, exist_ok=True)
    summary = {}

    for arm in args.arms:
        cfg = ARMS[arm]
        arm_out = os.path.join(args.out, arm)
        cmd = [sys.executable, ENGINE,
               "--repo", args.repo, "--range", args.rev_range,
               "--context-base", args.context_base,
               "--models", cfg["model"],
               "--replicates", str(cfg["replicates"]),
               "--judge", args.judge, "--slack", str(args.slack),
               "--max-usd", str(args.max_usd),
               "--out", arm_out]
        if args.dry_run:
            cmd.append("--dry-run")
        # flush before exec'ing the engine: its output goes straight to the fd,
        # so an unflushed header would print after the engine's own output
        print(f"\n=== arm: {arm} ({cfg['note']}) ===", flush=True)
        # argv-exec, never shell strings (decision 018); engine output streams through
        proc = subprocess.run(cmd)
        if proc.returncode != 0:
            print(f"arm {arm}: engine exited {proc.returncode}; skipping summary row")
            summary[arm] = {"error": f"engine exit {proc.returncode}", **cfg}
            continue
        if args.dry_run:
            summary[arm] = {"dry_run": True, **cfg}
            continue

        findings_path = os.path.join(arm_out, "findings.jsonl")
        runs = [json.loads(l) for l in open(findings_path)]
        ok_runs = [r for r in runs if not r.get("error")]
        n_raw = sum(r["n_findings"] for r in ok_runs)
        row = {**cfg, "runs_ok": len(ok_runs), "runs_errored": len(runs) - len(ok_runs),
               "findings_raw": n_raw,
               "tokens_in": sum(r.get("usage", {}).get("prompt_tokens", 0) for r in ok_runs),
               "tokens_out": sum(r.get("usage", {}).get("completion_tokens", 0) for r in ok_runs)}
        if cfg["consensus"]:
            kept, clusters = consensus_filter(findings_path, cfg["consensus"],
                                              args.slack, key, args.judge)
            row["clusters"] = len(clusters)
            row["findings_consensus"] = len(kept)
            with open(os.path.join(arm_out, "consensus.json"), "w") as fh:
                json.dump({"min_votes": cfg["consensus"],
                           "judge": args.judge if key else "stage1-only",
                           "kept": [{"votes": sorted(c["votes"]), **c["finding"]}
                                    for c in kept]}, fh, indent=2)
        summary[arm] = row

    with open(os.path.join(args.out, "arms-summary.json"), "w") as fh:
        json.dump({"repo": os.path.basename(args.repo), "range": args.rev_range,
                   "context_base": args.context_base, "arms": summary}, fh, indent=2)

    print("\n== arm summary ==")
    for arm, row in summary.items():
        if row.get("dry_run"):
            print(f"  {arm}: dry run (see projections above)")
        elif row.get("error"):
            print(f"  {arm}: {row['error']}")
        else:
            extra = (f" -> {row['findings_consensus']} after consensus"
                     if "findings_consensus" in row else "")
            print(f"  {arm}: {row['findings_raw']} findings{extra} "
                  f"({row['runs_ok']} runs, {row['tokens_in']:,} in / "
                  f"{row['tokens_out']:,} out tokens)")
    print(f"outputs: {os.path.join(args.out, 'arms-summary.json')}")


if __name__ == "__main__":
    main()
