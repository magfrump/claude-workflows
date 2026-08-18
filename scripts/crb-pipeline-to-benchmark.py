#!/usr/bin/env python3
"""Inject our pipeline's reviews into Code Review Bench as a new tool.

Direction (1) of docs/working/crb-arm-plan.md, stage 3: take the per-instance
output of runs/review-arms/crb-pipeline/run-host.sh and write a benchmark work
dir the vendored offline pipeline (steps 2 / 2.5 / 3) can score, alongside the
49 tools whose results ship with the benchmark.

What it writes under --out (default runs/review-arms/crb/offline-work-50/):

  results/benchmark_data.json
      the benchmark's own file, with one extra entry in each covered PR's
      "reviews" list: {"tool": <--tool-name>, "review_comments": [...]}.
      Untouched PRs and every other tool's reviews are preserved verbatim, so
      the aggregate table at the end of step 3 is a real leaderboard.
  results/<judge>/candidates.json, evaluations.json
      copied from the benchmark's checked-in results for that judge (unless
      --no-seed). Steps 2 and 3 skip any (PR, tool) pair already present, so
      seeding means the paid judge work is OUR TOOL ONLY — the other 49 tools
      keep their published scores instead of being re-judged at ~50x the cost.

Review comments come from the pipeline's rubric (one comment per 🔴/🟡/🟢 row —
the unit a human reviewer would post inline), falling back to the headless
result text when no rubric artifact was captured. "✅ Confirmed Good" rows are
never emitted: they assert the code is fine, so counting them as findings would
inflate the false-positive denominator with non-claims.

Usage:
  scripts/crb-pipeline-to-benchmark.py                       # all run cells
  scripts/crb-pipeline-to-benchmark.py --slug grafana-PR79265
  scripts/crb-pipeline-to-benchmark.py --tool-name mfc-pipeline-main --runs <dir>
  scripts/crb-pipeline-to-benchmark.py --stats               # what would be sent

Then (real judge, from the work dir — see docs/working/crb-direction1-setup.md):
  export MARTIAN_API_KEY=$ANTHROPIC_API_KEY \
         MARTIAN_BASE_URL=https://api.anthropic.com/v1/ \
         MARTIAN_MODEL=claude-opus-4-5-20251101
  python -m code_review_benchmark.step2_extract_comments   --tool mfc-pipeline-e8
  python -m code_review_benchmark.step2_5_dedup_candidates --tool mfc-pipeline-e8
  python -m code_review_benchmark.step3_judge_comments     --tool mfc-pipeline-e8
"""

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
BENCH = WORKSPACE / "external/code-review-benchmark/offline"
BENCH_DATA = BENCH / "results/benchmark_data.json"
DEFAULT_RUNS = WORKSPACE / "runs/review-arms/crb-pipeline"
DEFAULT_OUT = WORKSPACE / "runs/review-arms/crb/offline-work-50"
MANIFEST = WORKSPACE / "runs/review-arms/crb/instances.json"
DEFAULT_JUDGE = "claude-opus-4-5-20251101"

# Rubric section headers we treat as findings. "Confirmed Good" and "Considered
# Overrides" are deliberately absent.
FINDING_SECTIONS = ("Must Fix", "Must Address", "Consider")


def sanitize_model(model: str) -> str:
    return model.strip().replace("/", "_")


def md_tables(md: str):
    """Yield (section_title, header_cells, [row_cells]) for each pipe table."""
    section = ""
    header = None
    rows = []
    for line in md.splitlines():
        if line.startswith("#"):
            if header and rows:
                yield section, header, rows
            header, rows = None, []
            section = line.lstrip("#").strip()
            continue
        if line.strip().startswith("|"):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if all(re.fullmatch(r":?-{2,}:?", c or "-") for c in cells):
                continue  # separator row
            if header is None:
                header = cells
            else:
                rows.append(cells)
        elif header and rows:
            yield section, header, rows
            header, rows = None, []
    if header and rows:
        yield section, header, rows


SECTION_ALIASES = {"fix": "Must Fix", "address": "Must Address", "consider": "Consider"}


def comments_from_rubric(md: str, sections=FINDING_SECTIONS):
    """One review comment per finding row. Body = the finding text plus the
    severity/domain metadata the row carries, which is what the benchmark's
    extraction step reads."""
    out = []
    for section, header, rows in md_tables(md):
        if not any(s.lower() in section.lower() for s in sections):
            continue
        idx = {h.lower(): i for i, h in enumerate(header)}
        f_i = idx.get("finding")
        if f_i is None:
            continue
        loc_i = idx.get("location")
        sev_i = idx.get("severity")
        num_i = idx.get("#")
        for cells in rows:
            if f_i >= len(cells):
                continue
            body = cells[f_i].strip()
            if not body:
                continue
            loc = cells[loc_i].strip() if loc_i is not None and loc_i < len(cells) else ""
            sev = cells[sev_i].strip() if sev_i is not None and sev_i < len(cells) else ""
            tag = cells[num_i].strip() if num_i is not None and num_i < len(cells) else ""
            prefix = " · ".join(x for x in (tag, sev) if x and x != "—")
            path, line = parse_location(loc)
            out.append({
                "path": path,
                "line": line,
                "body": (f"[{prefix}] " if prefix else "") + body
                        + (f"\n\nLocation: {loc}" if loc and loc != "—" else ""),
            })
    return out


LOC_RE = re.compile(r"`?([\w./\-]+\.\w+)`?(?::(\d+))?")


def parse_location(loc: str):
    """Best-effort file/line out of a rubric Location cell like
    "`proxy.ts:57` (also `:52-63`)". Benchmark judging is text-only — path/line
    are carried for human readability, not scored — so a miss is harmless."""
    if not loc:
        return None, None
    m = LOC_RE.search(loc)
    if not m:
        return None, None
    return m.group(1), int(m.group(2)) if m.group(2) else None


def load_cell(cell_dir: Path, source: str, sections=FINDING_SECTIONS):
    """(comments, provenance) for one instance's run output."""
    rubrics = sorted(cell_dir.glob("artifacts/**/*rubric*.md"))
    if source in ("auto", "rubric") and rubrics:
        md = rubrics[0].read_text(errors="replace")
        comments = comments_from_rubric(md, sections)
        if comments:
            return comments, f"rubric:{rubrics[0].relative_to(cell_dir)}"
        if source == "rubric":
            return [], f"rubric:{rubrics[0].relative_to(cell_dir)} (no finding rows)"
    review = cell_dir / "review.md"
    if review.exists() and review.read_text(errors="replace").strip():
        text = review.read_text(errors="replace")
        return ([{"path": None, "line": None, "body": text}],
                "result-text (no rubric artifact)" if source == "auto" else "result-text")
    return [], "EMPTY"


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--runs", default=str(DEFAULT_RUNS), help="arm output dir")
    ap.add_argument("--out", default=str(DEFAULT_OUT), help="benchmark work dir to write")
    ap.add_argument("--tool-name", default="mfc-pipeline-e8",
                    help="tool name in benchmark_data.json (default mfc-pipeline-e8)")
    ap.add_argument("--judge", default=DEFAULT_JUDGE,
                    help=f"judge model id whose results dir to seed (default {DEFAULT_JUDGE})")
    ap.add_argument("--slug", nargs="+", help="only these instances")
    ap.add_argument("--source", choices=("auto", "rubric", "result"), default="auto",
                    help="where review comments come from (default auto: rubric, else result)")
    # The benchmark's 49 tools post a median of 4 findings per PR; an E8 rubric
    # carries ~16 (1 red + 8 amber + 7 green on mfc-csp). Every green counts
    # against precision, so scoring red+amber as a second tool name isolates
    # "what the pipeline says you must do" from its advisory tail.
    ap.add_argument("--sections", nargs="+", choices=sorted(SECTION_ALIASES),
                    default=sorted(SECTION_ALIASES),
                    help="rubric sections to emit as findings (default: all three)")
    ap.add_argument("--no-seed", action="store_true",
                    help="do NOT copy the benchmark's checked-in candidates/evaluations "
                         "(every tool then gets re-judged — ~50x the judge cost)")
    ap.add_argument("--stats", action="store_true", help="report only, write nothing")
    args = ap.parse_args()

    sections = [SECTION_ALIASES[s] for s in args.sections]
    if set(sections) != set(FINDING_SECTIONS):
        print(f"Rubric sections: {', '.join(sections)}")
    runs = Path(args.runs)
    out = Path(args.out)
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    data = json.loads(BENCH_DATA.read_text())

    cells = sorted(p for p in runs.glob("*/") if (p / "review.md").exists()
                   or (p / "artifacts").exists())
    if args.slug:
        want = set(args.slug)
        cells = [c for c in cells if c.name in want]
        missing = want - {c.name for c in cells}
        if missing:
            print(f"  !! no run output for: {', '.join(sorted(missing))}", file=sys.stderr)
    if not cells:
        sys.exit(f"no run cells under {runs} — run runs/review-arms/crb-pipeline/run-host.sh first")

    injected = 0
    total_comments = 0
    for cell in cells:
        slug = cell.name
        rec = manifest.get(slug)
        if not rec:
            print(f"  !! {slug}: not in {MANIFEST} — skipped", file=sys.stderr)
            continue
        url = rec["url"]
        if url not in data:
            print(f"  !! {slug}: {url} not in benchmark_data.json — skipped", file=sys.stderr)
            continue
        comments, prov = load_cell(cell, args.source, sections)
        if not comments:
            print(f"  !! {slug}: no reviewable output ({prov}) — skipped", file=sys.stderr)
            continue
        entry = data[url]
        entry["reviews"] = [r for r in entry.get("reviews", []) if r["tool"] != args.tool_name]
        entry["reviews"].append({
            "tool": args.tool_name,
            "repo_name": rec["fork"],
            "pr_url": url,
            "review_comments": comments,
            "source_provenance": prov,
        })
        injected += 1
        total_comments += len(comments)
        print(f"  {slug:28} {len(comments):3} comment(s)  "
              f"[{len(entry['golden_comments'])} goldens]  {prov}")

    print(f"\n{injected}/{len(data)} benchmark PRs carry a {args.tool_name} review "
          f"({total_comments} comments).")
    if args.stats:
        print("--stats: nothing written.")
        return

    (out / "results").mkdir(parents=True, exist_ok=True)
    (out / "results/benchmark_data.json").write_text(json.dumps(data, indent=2) + "\n")
    print(f"Wrote {out/'results/benchmark_data.json'}")

    jdir = out / "results" / sanitize_model(args.judge)
    jdir.mkdir(parents=True, exist_ok=True)
    src = BENCH / "results" / sanitize_model(f"anthropic/{args.judge}")
    if not src.exists():
        src = BENCH / "results" / sanitize_model(args.judge)
    if args.no_seed:
        print("--no-seed: judge dir left empty; all 50 tools will be re-judged.")
    elif src.exists():
        for name in ("candidates.json", "evaluations.json"):
            s = src / name
            if s.exists() and not (jdir / name).exists():
                shutil.copy2(s, jdir / name)
                print(f"Seeded {jdir/name} from {s.relative_to(BENCH)}")
            elif (jdir / name).exists():
                print(f"Kept existing {jdir/name} (delete to re-seed)")
    else:
        print(f"  !! no checked-in results for judge {args.judge} — "
              f"nothing to seed; the judge run will score every tool.", file=sys.stderr)

    # The work dir carries its own runbook: the --tool flag is not optional
    # decoration. Without it step 2 re-extracts the ~52 (PR, tool) pairs the
    # checked-in candidates file happens to be missing, and step 3 would re-judge
    # them — paid work that overwrites published numbers with ours.
    runbook = f"""# Judging run for `{args.tool_name}`

Judge: `{args.judge}` · work dir written by `scripts/crb-pipeline-to-benchmark.py`.
Full context: `docs/working/crb-direction1-setup.md`.

```bash
cd {out}
export PYTHONPATH=/workspace/external/code-review-benchmark/offline   # or: uv sync in offline/
export MARTIAN_API_KEY="$ANTHROPIC_API_KEY"
export MARTIAN_BASE_URL=https://api.anthropic.com/v1/
export MARTIAN_MODEL={args.judge}

# --tool IS REQUIRED on all three: it confines paid work to our arm and leaves
# the other tools' checked-in scores untouched.
python -m code_review_benchmark.step2_extract_comments   --tool {args.tool_name}
python -m code_review_benchmark.step2_5_dedup_candidates --tool {args.tool_name}
python -m code_review_benchmark.step3_judge_comments     --tool {args.tool_name}

# Comparable ranking over exactly the PRs our arm reviewed:
python3 /workspace/scripts/crb-subset-leaderboard.py \\
  --evaluations {out}/results/{sanitize_model(args.judge)}/evaluations.json \\
  --tool {args.tool_name}
```
"""
    (out / "RUN.md").write_text(runbook)
    print(f"Wrote {out/'RUN.md'} (runbook for the judging steps)")
    print(f"\nNext (from {out}, with MARTIAN_* env set — see "
          f"docs/working/crb-direction1-setup.md):")
    for step in ("step2_extract_comments", "step2_5_dedup_candidates", "step3_judge_comments"):
        print(f"  python -m code_review_benchmark.{step} --tool {args.tool_name}")


if __name__ == "__main__":
    main()
