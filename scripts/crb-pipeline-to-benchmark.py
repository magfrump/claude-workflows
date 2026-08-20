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
      Untouched PRs and every other tool's reviews are preserved verbatim.
      NOTE this does NOT make step 3's own aggregate table a leaderboard when
      our arm covers fewer PRs than the other tools: that table sums each tool
      over every PR it has results for, so a 5-PR pilot row is compared against
      50-PR rows. Use scripts/crb-subset-leaderboard.py, which re-aggregates
      every tool over exactly the PRs our arm was judged on.
  results/<judge>/candidates.json, evaluations.json
      copied from the benchmark's checked-in results for that judge (unless
      --no-seed). Steps 2 and 3 skip any (PR, tool) pair already present, so
      seeding means the paid judge work is OUR TOOL ONLY — the other 49 tools
      keep their published scores instead of being re-judged at ~50x the cost.

Review comments come from the pipeline's rubric — one comment per 🔴 Must Fix or
🟡 Must Address row, the unit a human reviewer would post inline — falling back
to the headless result text when no rubric artifact was captured.

Three rubric sections are never emitted, for two different reasons:
  * "✅ Confirmed Good" and "Considered Overrides" assert the code is FINE or
    that a finding was already waived, so counting them as findings would
    inflate the false-positive denominator with non-claims;
  * "🟢 Consider" is advisory by the SKILL's own tier definition and rarely
    corresponds to a human PR comment (this benchmark's ground truth), so it is
    excluded as a scoring decision — log #36, taken before any judge run.

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
import shlex
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
# Shared with crb-subset-leaderboard.py — see crb_common's docstring for why
# these four in particular are not hand-copied into both files.
from crb_common import (  # noqa: E402
    BENCH, BENCH_DATA, DEFAULT_JUDGE, DEFAULT_OUT, DEFAULT_TOOL, MANIFEST,
    WORKSPACE, sanitize_model,
)

DEFAULT_RUNS = WORKSPACE / "runs/review-arms/crb-pipeline"

# Rubric section headers we treat as findings. "Confirmed Good" and "Considered
# Overrides" are deliberately absent.
#
# Matching is on the NORMALIZED HEADING, not a substring: "consider" is a
# substring of "considered overrides", so a substring test lets that section
# through, and it emitted nothing only by the accident that its column is named
# "Prior finding" rather than "Finding". A rename in skills/code-review/SKILL.md
# would have started injecting already-waived findings as guaranteed false
# positives. Anchor here so the exclusion is a property of this file.
#
# 🟢 CONSIDER IS EXCLUDED — decision log #36 (2026-08-19), taken BEFORE any judge
# run, so no score existed to select on. 🟢 rows are advisory by the SKILL's own
# tier definition ("Not required to pass review") and rarely correspond to a
# human PR comment, which is this benchmark's ground truth. Since the benchmark
# scores precision as TP / total_candidates, every unmatched green would be a
# false positive: the 49 comparison tools post a median of 4 findings per PR
# while an E8 rubric carries ~16 (1 red + 8 amber + 7 green on mfc-csp).
# Red+amber is therefore the arm's single scored form; the earlier plan to score
# both variants and report them together is retired.
FINDING_SECTIONS = ("Must Fix", "Must Address")


def normalize_section(title: str) -> str:
    """Rubric heading -> comparable key. Strips the emoji and punctuation the
    template decorates headings with ("## 🔴 Must Fix" -> "must fix")."""
    return re.sub(r"[^a-z ]", "", title.lower()).strip()


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

# No "consider" alias: excluding 🟢 is the decision (log #36), not a default a
# flag can undo. Leaving the alias in place would have made the exclusion look
# like a preference and let a later invocation quietly re-inject advisory rows.
SECTION_ALIASES = {"fix": "Must Fix", "address": "Must Address"}


def comments_from_rubric(md: str, sections=FINDING_SECTIONS):
    """One review comment per finding row. Body = the finding text plus the
    severity/domain metadata the row carries, which is what the benchmark's
    extraction step reads."""
    out = []
    wanted = {normalize_section(s) for s in sections}
    for section, header, rows in md_tables(md):
        if normalize_section(section) not in wanted:
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


# The judge files the purge must cover. dedup_groups.json is included even
# though seeding never copies it: step 2.5 writes it into the work dir, and a
# stale group there maps the OLD candidate indices onto the NEW candidates.
JUDGE_STATE_FILES = ("candidates.json", "dedup_groups.json", "evaluations.json")


def purge_stale_judge_entries(jdir: Path, urls, tool: str):
    """Drop (PR, tool) entries from any existing judge-state file in jdir.

    Steps 2/2.5/3 are all skip-if-present, keyed on (PR url, tool). So when a
    cell is re-run and its review re-injected, judge state from the PREVIOUS
    review survives every re-run of judge.sh and is reported as the new
    review's score. Observed 2026-08-20: the voided keycloak-PR36880 cell's
    wrong-ref review (a Dependabot CI diff) stayed in evaluations.json as five
    false positives after the cell was cleared and re-run against the real PR.
    benchmark_data.json already gets this right (the old review entry is
    replaced on inject); this extends the same invalidation to the judge dir.

    Only the injected PRs' entries for OUR tool are touched — the other tools'
    seeded results, which the seeding exists to preserve, are never modified.
    Returns {filename: n_dropped} for files that were rewritten.
    """
    purged = {}
    for name in JUDGE_STATE_FILES:
        p = jdir / name
        if not p.exists():
            continue
        d = json.loads(p.read_text())
        dropped = 0
        for url in urls:
            entry = d.get(url)
            if isinstance(entry, dict) and tool in entry:
                del entry[tool]
                dropped += 1
        if dropped:
            p.write_text(json.dumps(d, indent=2) + "\n")
            purged[name] = dropped
    return purged


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--runs", default=str(DEFAULT_RUNS), help="arm output dir")
    ap.add_argument("--out", default=str(DEFAULT_OUT), help="benchmark work dir to write")
    # --tool is the spelling used by crb-subset-leaderboard.py AND by all three
    # vendored benchmark steps; --tool-name is kept as the original spelling so
    # existing invocations keep working.
    ap.add_argument("--tool-name", "--tool", dest="tool_name", default=DEFAULT_TOOL,
                    help="tool name in benchmark_data.json (default mfc-pipeline-e8)")
    ap.add_argument("--judge", default=DEFAULT_JUDGE,
                    help=f"judge model id whose results dir to seed (default {DEFAULT_JUDGE})")
    ap.add_argument("--slug", nargs="+", help="only these instances")
    ap.add_argument("--source", choices=("auto", "rubric", "result"), default="auto",
                    help="where review comments come from (default auto: rubric, else result)")
    # Narrowing further (e.g. red only) stays possible for a probe; widening to
    # 🟢 does not, by design — see FINDING_SECTIONS and decision log #36.
    ap.add_argument("--sections", nargs="+", choices=sorted(SECTION_ALIASES),
                    default=sorted(SECTION_ALIASES),
                    help="rubric sections to emit as findings (default: both — "
                         "Must Fix + Must Address; 🟢 Consider is never emitted)")
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
    injected_urls = []
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
        if (cell / "CONTAINMENT_FAILED").exists():
            print(f"  !! {slug}: cell voided by a post-run containment failure — skipped",
                  file=sys.stderr)
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
        injected_urls.append(url)
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
        # Seeding is what keeps the judge pass at ~$17 instead of ~$850, so a
        # partial or failed seed is an error, not a warning. Exiting here beats
        # discovering it from the bill.
        for name in ("candidates.json", "evaluations.json"):
            s = src / name
            if s.exists() and not (jdir / name).exists():
                shutil.copy2(s, jdir / name)
                print(f"Seeded {jdir/name} from {s.relative_to(BENCH)}")
            elif (jdir / name).exists():
                print(f"Kept existing {jdir/name} (delete to re-seed)")
            elif not s.exists():
                sys.exit(f"seed source {s} is missing — refusing to continue: an unseeded "
                         f"judge dir re-judges every tool (~50x cost). Pass --no-seed to "
                         f"do that deliberately.")
    else:
        sys.exit(f"no checked-in results for judge {args.judge} at {src} — refusing to "
                 f"continue: the judge run would score every tool (~50x cost). Pass "
                 f"--no-seed to do that deliberately.")

    # Invalidate stale judge state for the pairs we just (re-)injected — after
    # seeding, so a freshly-seeded file is also covered, and regardless of
    # --no-seed, which leaves pre-existing files in place.
    purged = purge_stale_judge_entries(jdir, injected_urls, args.tool_name)
    for name, n in purged.items():
        print(f"Purged {n} stale {args.tool_name} entr{'y' if n == 1 else 'ies'} "
              f"from {jdir/name} (will be re-extracted/re-judged)")

    # The work dir carries its own runbook: the --tool flag is not optional
    # decoration. Without it step 2 re-extracts the 50 (PR, tool) pairs the
    # checked-in candidates file is missing (all greptile-v5; 216 pairs are
    # absent, 166 of them below step 2's >=20-char extraction gate). Step 3
    # itself would not re-judge them — the seeded evaluations.json is complete
    # at 2449 pairs — but those new extractions flow into step 2.5, for which
    # NO dedup_groups.json is checked in, so an unscoped run there is roughly
    # 2233 paid LLM calls. That is the real unguarded cost.
    runbook = f"""# Judging run for `{args.tool_name}`

Judge: `{args.judge}` · work dir written by `scripts/crb-pipeline-to-benchmark.py`.
Full context: `docs/working/crb-direction1-setup.md`.

## Preferred: run `./judge.sh`

```bash
ANTHROPIC_API_KEY=sk-ant-... ./judge.sh
```

`judge.sh` (written alongside this file) sets every variable, passes `--tool` to
all three steps, and **refuses to start** unless `MARTIAN_BASE_URL` is an
`api.anthropic.com` endpoint — the benchmark otherwise defaults it to
`https://api.withmartian.com/v1`, which would send your Anthropic key to a third
party. Set `CRB_ALLOW_FOREIGN_ENDPOINT=1` only if judging via another provider is
genuinely what you want.

## By hand (both footguns are yours to avoid)

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

    # An executable runbook, so the two things a human can get wrong are not
    # left to a human. (1) MARTIAN_BASE_URL is coupled to MARTIAN_API_KEY: the
    # benchmark defaults the base URL to api.withmartian.com, so exporting the
    # key WITHOUT the URL sends an Anthropic credential to a third party.
    # (2) --tool must be on all three steps; see the note above for the cost.
    # Every interpolated value is shell-quoted, and the two identifiers are
    # charset-checked first: this file is written executable, so a --judge or
    # --tool-name containing $(...) would otherwise execute on the operator's
    # machine when they run it.
    for label, value in (("--tool-name", args.tool_name), ("--judge", args.judge)):
        if not re.fullmatch(r"[A-Za-z0-9._/-]+", value):
            sys.exit(f"refusing to generate judge.sh: {label} {value!r} contains characters "
                     f"outside [A-Za-z0-9._/-]")
    q_tool = shlex.quote(args.tool_name)
    q_judge = shlex.quote(args.judge)
    q_evals = shlex.quote(str(out / "results" / sanitize_model(args.judge) / "evaluations.json"))
    q_bench = shlex.quote(str(BENCH))
    q_leaderboard = shlex.quote(str(WORKSPACE / "scripts/crb-subset-leaderboard.py"))
    judge_sh = f"""#!/usr/bin/env bash
# Generated by scripts/crb-pipeline-to-benchmark.py — do not hand-edit.
# Runs the benchmark's judging steps for {q_tool} only.
set -euo pipefail
cd "$(dirname "$0")"

MARTIAN_API_KEY="${{MARTIAN_API_KEY:-${{ANTHROPIC_API_KEY:-}}}}"
MARTIAN_BASE_URL="${{MARTIAN_BASE_URL:-https://api.anthropic.com/v1/}}"
MARTIAN_MODEL="${{MARTIAN_MODEL:-{q_judge}}}"
export MARTIAN_API_KEY MARTIAN_BASE_URL MARTIAN_MODEL
export PYTHONPATH="${{PYTHONPATH:-{q_bench}}}"

[ -n "$MARTIAN_API_KEY" ] || {{ echo "MARTIAN_API_KEY (or ANTHROPIC_API_KEY) not set" >&2; exit 1; }}

# Fail closed rather than shipping the key to whatever host happens to be the
# default (the benchmark defaults MARTIAN_BASE_URL to api.withmartian.com).
# Anchored on the scheme+host prefix: a substring test would accept
# https://api.anthropic.com.evil.example/v1/.
case "$MARTIAN_BASE_URL" in
  https://api.anthropic.com|https://api.anthropic.com/*) ;;
  *)
    if [ "${{CRB_ALLOW_FOREIGN_ENDPOINT:-}}" = "1" ]; then
      echo "WARNING: sending MARTIAN_API_KEY to non-Anthropic endpoint '$MARTIAN_BASE_URL'" >&2
      echo "         (CRB_ALLOW_FOREIGN_ENDPOINT=1 was set deliberately)" >&2
    else
      echo "MARTIAN_BASE_URL is '$MARTIAN_BASE_URL', not an api.anthropic.com endpoint." >&2
      echo "Refusing to send MARTIAN_API_KEY there." >&2
      echo "Set CRB_ALLOW_FOREIGN_ENDPOINT=1 if that is genuinely intended." >&2
      exit 1
    fi
    ;;
esac

for step in step2_extract_comments step2_5_dedup_candidates step3_judge_comments; do
  echo "=== $step --tool {q_tool}"
  python -m "code_review_benchmark.$step" --tool {q_tool}
done

python3 {q_leaderboard} --evaluations {q_evals} --tool {q_tool}
"""
    judge_path = out / "judge.sh"
    judge_path.write_text(judge_sh)
    judge_path.chmod(0o755)
    print(f"Wrote {judge_path} (executable — prefer it over hand-running the steps)")
    print(f"\nNext (from {out}, with MARTIAN_* env set — see "
          f"docs/working/crb-direction1-setup.md):")
    for step in ("step2_extract_comments", "step2_5_dedup_candidates", "step3_judge_comments"):
        print(f"  python -m code_review_benchmark.{step} --tool {args.tool_name}")


if __name__ == "__main__":
    main()
