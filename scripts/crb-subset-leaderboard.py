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
  scripts/crb-subset-leaderboard.py --tool mfc-pipeline-e8-redamber
  scripts/crb-subset-leaderboard.py --all-prs             # every PR in the evals file
  scripts/crb-subset-leaderboard.py --judge claude-sonnet-4-5-20250929
  scripts/crb-subset-leaderboard.py --markdown > table.md
"""

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
# One definition of the work-dir identity, shared with the injector: --judge and
# --out there change where evaluations land, so this reads the same constants
# rather than hand-copying them and holding them in sync by comment.
from crb_common import (  # noqa: E402
    DEFAULT_JUDGE, DEFAULT_OUT, DEFAULT_TOOL, MANIFEST, RUN_META, WORKSPACE,
    sanitize_model,
)


def f1(p, r):
    return 2 * p * r / (p + r) if (p + r) else 0.0


def attrition(urls, run_meta_path: Path):
    """(lines, checked) — sweep cells that are NOT in the judged subset.

    The subset is defined as "PRs our tool has a judged row for", which means a
    cell that produced nothing injectable removes itself from the denominator
    without appearing anywhere in this table. That attrition is not random: the
    cells that fail are the ones where the pipeline struggled, so a subset
    selected this way is selected FOR pipeline success, and the resulting recall
    is biased in our own favour. Reporting the count is not enough — the reader
    needs to know which PRs left and why.
    """
    if not run_meta_path.exists():
        return ([f"!! subset attrition NOT checked: no run-meta.json at {run_meta_path} "
                 f"(pass --run-meta to point at one). The {len(urls)} PR(s) below are the "
                 f"ones that were judged, which is not necessarily the ones that were run."],
                False)
    meta = json.loads(run_meta_path.read_text())
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    cells = meta.get("cells") or {}
    requested = meta.get("requested_instances") or sorted(cells)
    voided = set(meta.get("voided_cells") or [])
    judged = set(urls)
    lost = []
    for slug in requested:
        url = (manifest.get(slug) or {}).get("url")
        if url and url in judged:
            continue
        if slug in voided:
            why = "voided by a post-run containment failure"
        elif slug not in cells:
            why = "no cell produced (missing clone, or pre-run containment failure)"
        elif not url:
            why = f"not in {MANIFEST.name} — cannot map the slug to a PR"
        else:
            why = "ran, but has no judged row (no reviewable output, or not injected)"
        lost.append(f"     {slug:28} {why}")
    if not lost:
        return ([], True)
    return ([f"!! SUBSET ATTRITION: {len(lost)} of {len(requested)} attempted cell(s) are NOT "
             f"in this ranking. The subset is defined by which PRs our tool was judged on, "
             f"so failed cells drop out of the denominator — which biases the numbers below "
             f"in our favour. Missing:"] + lost, True)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--evaluations", default=None,
                    help="explicit evaluations.json (overrides --out/--judge)")
    ap.add_argument("--out", default=str(DEFAULT_OUT),
                    help=f"benchmark work dir written by the injector (default {DEFAULT_OUT})")
    ap.add_argument("--judge", default=DEFAULT_JUDGE,
                    help=f"judge model id whose results to read (default {DEFAULT_JUDGE})")
    ap.add_argument("--tool", default=DEFAULT_TOOL, help="our arm's tool name")
    ap.add_argument("--all-prs", action="store_true",
                    help="rank over every PR in the evaluations file (that is all 50 only "
                         "when the file was seeded from the benchmark's checked-in results)")
    ap.add_argument("--markdown", action="store_true", help="emit a markdown table")
    ap.add_argument("--run-meta", default=str(RUN_META),
                    help=f"sweep provenance to check subset attrition against "
                         f"(default {RUN_META})")
    args = ap.parse_args()

    path = (Path(args.evaluations) if args.evaluations
            else Path(args.out) / "results" / sanitize_model(args.judge) / "evaluations.json")
    if not path.exists():
        sys.exit(f"no evaluations at {path} — run step 3 first "
                 f"(or point --out/--judge/--evaluations at the right dir)")
    evals = json.loads(path.read_text())

    # Attrition is always measured against the PRs OUR tool was judged on, even
    # under --all-prs where the displayed subset is everything: the question is
    # what happened to the cells we ran, not how the table is scoped.
    our_urls = sorted(u for u, tools in evals.items() if args.tool in tools)
    urls = sorted(evals) if args.all_prs else our_urls
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

    # Recall is only cross-tool comparable if every tool was scored against the
    # same golden set, and in the checked-in evaluations it frequently was not
    # (goldens were revised between tool runs). Surface it in the output rather
    # than in a runbook nobody re-reads at write-up time.
    warn = ""
    skew = []
    for url in urls:
        golds = {t: r.get("total_golden", 0) for t, r in evals[url].items()
                 if not r.get("skipped")}
        if len(set(golds.values())) > 1:
            ours = golds.get(args.tool)
            skew.append((url, min(golds.values()), max(golds.values()), ours))
    if skew:
        lo_than_ours = sum(1 for _u, lo, _hi, ours in skew if ours is not None and lo < ours)
        warn = (f"!! GOLDEN-DENOMINATOR SKEW: {len(skew)} of {len(urls)} PR(s) in this subset "
                f"have non-uniform total_golden across tools"
                + (f"; on {lo_than_ours} of them at least one tool was scored against FEWER "
                   f"goldens than {args.tool}, which inflates their recall relative to ours"
                   if lo_than_ours else "")
                + ". Recall is not denominator-uniform — see the gold column.")
        print(warn, file=sys.stderr)

    # Attrition goes to stderr like the skew warning AND into the markdown body:
    # the markdown is what gets pasted into a results doc, and a caveat that
    # only ever existed on a terminal is a caveat that will not survive to the
    # place the number is quoted.
    att_lines, _checked = attrition(our_urls, Path(args.run_meta))
    for line in att_lines:
        print(line, file=sys.stderr)

    if args.markdown:
        print(f"Subset: {header} · micro-averaged · judge: {path.parent.name}\n")
        # Same reasoning for the skew warning: it belongs where the table is read.
        for note in ([warn] if warn else []) + ([("\n".join(att_lines))] if att_lines else []):
            print("> " + note.replace("\n", "\n> ") + "\n")
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
