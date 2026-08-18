#!/usr/bin/env python3
"""Rank tools on the SUBSET of benchmark PRs our arm actually reviewed.

Step 3's own aggregate table sums each tool over every PR it has results for.
When our arm covers a 5-PR pilot and the other 49 tools cover all 50, that table
compares our row on 5 PRs against theirs on 50 — different denominators, not a
ranking. This script recomputes every tool's precision/recall/F1 over exactly
the PRs our tool was judged on, which is the comparison a pilot can defend.

Metrics are MICRO-averaged (sum tp/fp/fn across the subset, then divide), the
same convention step 3 uses for its aggregate table.

Usage:
  scripts/crb-subset-leaderboard.py                       # subset = our tool's PRs
  scripts/crb-subset-leaderboard.py --tool mfc-pipeline-main
  scripts/crb-subset-leaderboard.py --all-prs             # full 50-PR leaderboard
  scripts/crb-subset-leaderboard.py --markdown > table.md
"""

import argparse
import json
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
DEFAULT_EVALS = (WORKSPACE / "runs/review-arms/crb/offline-work-50/results"
                 / "claude-opus-4-5-20251101/evaluations.json")


def f1(p, r):
    return 2 * p * r / (p + r) if (p + r) else 0.0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--evaluations", default=str(DEFAULT_EVALS))
    ap.add_argument("--tool", default="mfc-pipeline-e8", help="our arm's tool name")
    ap.add_argument("--all-prs", action="store_true",
                    help="rank over every PR in the file instead of our tool's subset")
    ap.add_argument("--markdown", action="store_true", help="emit a markdown table")
    args = ap.parse_args()

    path = Path(args.evaluations)
    if not path.exists():
        sys.exit(f"no evaluations at {path} — run step 3 first")
    evals = json.loads(path.read_text())

    urls = sorted(evals) if args.all_prs else sorted(
        u for u, tools in evals.items() if args.tool in tools)
    if not urls:
        sys.exit(f"tool {args.tool!r} has no judged PRs in {path}")

    agg = {}
    for url in urls:
        for tool, res in evals[url].items():
            if res.get("skipped"):
                continue
            a = agg.setdefault(tool, {"tp": 0, "fp": 0, "fn": 0, "n": 0, "cand": 0, "gold": 0})
            a["tp"] += res.get("tp", 0)
            a["fp"] += res.get("fp", 0)
            a["fn"] += res.get("fn", 0)
            a["cand"] += res.get("total_candidates", 0)
            a["gold"] += res.get("total_golden", 0)
            a["n"] += 1

    rows = []
    for tool, a in agg.items():
        p = a["tp"] / (a["tp"] + a["fp"]) if (a["tp"] + a["fp"]) else 0.0
        r = a["tp"] / (a["tp"] + a["fn"]) if (a["tp"] + a["fn"]) else 0.0
        rows.append((tool, p, r, f1(p, r), a))
    rows.sort(key=lambda x: -x[3])

    n_gold = sum(evals[u][t].get("total_golden", 0)
                 for u in urls for t in [args.tool] if t in evals[u])
    header = (f"{len(urls)} PR(s), {n_gold} goldens on the {args.tool} rows"
              if not args.all_prs else f"all {len(urls)} PRs")
    if args.markdown:
        print(f"Subset: {header} · micro-averaged · judge: {path.parent.name}\n")
        print("| # | Tool | Precision | Recall | F1 | PRs | Cands | Goldens |")
        print("|---|---|---|---|---|---|---|---|")
        for i, (tool, p, r, f, a) in enumerate(rows, 1):
            mark = "**" if tool == args.tool else ""
            print(f"| {i} | {mark}{tool}{mark} | {p:.1%} | {r:.1%} | {f:.1%} | "
                  f"{a['n']} | {a['cand']} | {a['gold']} |")
        return

    print(f"Subset: {header} · micro-averaged · judge: {path.parent.name}")
    print(f"{'#':>3}  {'tool':28} {'prec':>7} {'recall':>7} {'F1':>7} {'PRs':>4} "
          f"{'cand':>5} {'gold':>5}")
    for i, (tool, p, r, f, a) in enumerate(rows, 1):
        star = " <-- ours" if tool == args.tool else ""
        print(f"{i:>3}  {tool:28} {p:>6.1%} {r:>6.1%} {f:>6.1%} {a['n']:>4} "
              f"{a['cand']:>5} {a['gold']:>5}{star}")


if __name__ == "__main__":
    main()
