#!/usr/bin/env python3
"""Convert the canon issue ledger into Code Review Bench (offline) data formats.

Produces, under --out (default runs/review-arms/crb/offline-work/):

  golden_comments/meta_formalism_copilot.json   benchmark golden-comments format:
      one entry per canon instance (pseudo-URL key), one golden comment per
      ledger issue findable at that instance's reviewed state.
  results/benchmark_data.json                   benchmark pipeline input with the
      goldens plus locally-collected tool reviews injected (no GitHub involved):
      currently tool "e2" from runs/review-arms/e2/*/base/findings.jsonl and
      "e4-union" from runs/review-arms/e4-opus-k3/*/k3/findings.jsonl if present.

Severity/category per issue are PROVISIONAL auto-mappings (hand table below,
category taxonomy from the benchmark: bug, security, concurrency, data, api,
perf, test_gap, doc_defect, style, speculative). Adjudicate before publishing
numbers; the mapping is embedded here so re-runs are reproducible.

Issues excluded: strata-D rows whose commit is a fix commit outside the 8 canon
dirty states (D1 @4f018ab, D2-D5 @4de2b00) — they are not findable in any
instance input the arms review. D6 (@b64c1ca) is included under mfc-fscompat.
"""

import argparse
import csv
import json
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
LEDGER_CSV = WORKSPACE / "docs/working/canon-issue-ledger.csv"

# commit -> (instance id, pseudo golden URL)
INSTANCES = {
    "d90d6bb": "mfc-csp",
    "c95c9cb": "mfc-lean",
    "f2f149b": "mfc-hygiene",
    "8bde50c": "mfc-secdeps",
    "4329d6e": "mfc-deploy",
    "b64c1ca": "mfc-fscompat",
    "2dc403e": "mfc-corpus",
    "7f30210": "mfc-postfix",
}
PSEUDO_URL = "https://local.invalid/meta-formalism-copilot/{inst}"

# instance id -> list of (tool name, findings.jsonl path relative to workspace)
REVIEW_SOURCES = {
    inst: [
        ("e2", f"runs/review-arms/e2/{inst}/base/findings.jsonl"),
        ("e4-union", f"runs/review-arms/e4-opus-k3/{inst}/opus-k3/findings.jsonl"),
    ]
    for inst in INSTANCES.values()
}
# postfix E2 results live under the 2026-08-06 sweep dir
REVIEW_SOURCES["mfc-postfix"][0] = ("e2", "runs/review-arms/mfc-2026-08-06/base/findings.jsonl")
# cubic CLI arm (runs/review-arms/crb/run-cubic.sh); .json files are parsed by
# cubic_to_comments, .jsonl by findings_to_comments
for _inst in INSTANCES.values():
    REVIEW_SOURCES[_inst].append(("cubic-cli", f"runs/review-arms/crb/cubic-cli/{_inst}/review.json"))

# PROVISIONAL severity/category mapping (author adjudication pending).
SEV_CAT = {
    "csp-R1": ("High", "bug"), "csp-R2": ("Low", "doc_defect"),
    "csp-A1": ("High", "bug"), "csp-A2": ("Low", "doc_defect"),
    "csp-A3": ("Low", "doc_defect"), "csp-A4": ("Medium", "test_gap"),
    "lean-R1": ("Medium", "doc_defect"), "lean-R2": ("Medium", "bug"),
    "lean-A1": ("Medium", "api"),
    "hyg-R1": ("Low", "doc_defect"), "hyg-A1": ("Low", "bug"),
    "sec-R1": ("Medium", "bug"), "sec-A1": ("Medium", "security"),
    "dep-R1": ("Medium", "doc_defect"), "dep-R2": ("Low", "doc_defect"),
    "fsc-R1": ("Low", "doc_defect"), "fsc-A1": ("Medium", "doc_defect"),
    "fsc-A2": ("Low", "style"), "fsc-A3": ("Medium", "perf"),
    "fsc-A4": ("Medium", "test_gap"),
    "cor-A1": ("Low", "style"), "cor-A2": ("Medium", "api"),
    "cor-A3": ("Low", "doc_defect"), "cor-A4": ("Medium", "doc_defect"),
    "pf-R1": ("High", "bug"), "pf-A1": ("High", "security"),
    "pf-A2": ("Medium", "test_gap"), "pf-A3": ("Medium", "api"),
    "pf-A4": ("Low", "bug"), "pf-A5": ("Medium", "bug"),
    "pf-A6": ("Medium", "bug"), "pf-A7": ("Low", "doc_defect"),
    "pf-A8": ("Low", "doc_defect"),
    "C1": ("High", "bug"), "C2": ("Medium", "security"),
    "C3": ("High", "bug"), "C4": ("Medium", "bug"),
    "D6": ("Low", "bug"),
    "N1": ("Critical", "security"), "N2": ("High", "bug"),
    "N3": ("Medium", "bug"), "N4": ("Medium", "bug"),
    "N5": ("High", "bug"), "N6": ("Medium", "bug"), "N7": ("Medium", "bug"),
}


def load_ledger() -> dict[str, list[dict]]:
    """Ledger issues grouped by instance id. Skips rows on fix commits."""
    by_inst: dict[str, list[dict]] = {inst: [] for inst in INSTANCES.values()}
    skipped = []
    with open(LEDGER_CSV, newline="") as f:
        for row in csv.DictReader(f):
            iid = (row.get("issue ID") or "").strip()
            if not iid:
                continue
            commit = (row.get("commit ID") or "").strip()
            inst = INSTANCES.get(commit)
            if inst is None:
                skipped.append((iid, commit))
                continue
            sev, cat = SEV_CAT.get(iid, ("Medium", "bug"))
            by_inst[inst].append({
                "comment": f"{row['issue summary'].strip()}",
                "severity": sev,
                "category": cat,
                "canon_issue_id": iid,
                "mapping_provenance": "auto-mapped 2026-08-14, pending adjudication",
            })
    if skipped:
        print(f"skipped (fix-commit / out-of-instance): {skipped}")
    return by_inst


def findings_to_comments(path: Path) -> list[dict]:
    """Flatten a findings.jsonl (all replicates) into benchmark review_comments."""
    comments = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            rec = json.loads(line)
            for fnd in rec.get("findings", []):
                body = f"**{fnd.get('title', '').strip()}**\n\n{fnd.get('desc', '').strip()}"
                comments.append({
                    "path": fnd.get("path"),
                    "line": fnd.get("line_start"),
                    "body": body,
                    "created_at": None,
                })
    return comments


def cubic_to_comments(path: Path) -> list[dict]:
    """Best-effort conversion of `cubic review --json` output to review_comments.

    The exact schema is unadjudicated until the first real run; this tries the
    obvious issue-list shapes and falls back to shipping the whole JSON as one
    general comment — the benchmark's extract step LLM-splits freeform text
    anyway, so the fallback still scores.
    """
    raw = path.read_text()
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return [{"path": None, "line": None, "body": raw, "created_at": None}]

    items = None
    if isinstance(data, list):
        items = data
    elif isinstance(data, dict):
        for key in ("issues", "findings", "comments", "results", "reviews"):
            if isinstance(data.get(key), list):
                items = data[key]
                break
    if not items or not all(isinstance(i, dict) for i in items):
        return [{"path": None, "line": None,
                 "body": json.dumps(data, indent=2), "created_at": None}]

    comments = []
    for it in items:
        fpath = it.get("path") or it.get("file") or it.get("filePath") or it.get("file_path")
        line = it.get("line") or it.get("startLine") or it.get("line_start") or it.get("start_line")
        prio = it.get("priority") or it.get("severity") or ""
        title = it.get("title") or it.get("summary") or ""
        if prio:
            title = f"[{prio}] {title}".strip()
        desc = it.get("description") or it.get("body") or it.get("message") or it.get("text") or ""
        body = f"**{title}**\n\n{desc}".strip("* \n") if (title or desc) else json.dumps(it, indent=2)
        comments.append({"path": fpath, "line": line, "body": body, "created_at": None})
    return comments


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="runs/review-arms/crb/offline-work")
    args = ap.parse_args()

    out = WORKSPACE / args.out
    (out / "golden_comments").mkdir(parents=True, exist_ok=True)
    (out / "results").mkdir(parents=True, exist_ok=True)

    by_inst = load_ledger()

    golden_entries = []
    benchmark_data = {}
    for commit, inst in INSTANCES.items():
        url = PSEUDO_URL.format(inst=inst)
        issues = by_inst[inst]
        golden_entries.append({
            "pr_title": f"canon instance {inst} ({commit})",
            "url": url,
            "az_comment": "local canon instance of meta-formalism-copilot; not a GitHub PR",
            "comments": issues,
        })

        reviews = []
        for tool, rel in REVIEW_SOURCES[inst]:
            p = WORKSPACE / rel
            if not p.exists():
                print(f"  [{inst}] no findings for tool {tool} ({rel}) — skipped")
                continue
            comments = cubic_to_comments(p) if p.suffix == ".json" else findings_to_comments(p)
            reviews.append({
                "tool": tool,
                "repo_name": f"meta-formalism-copilot@{commit}",
                "pr_url": url,
                "review_comments": comments,
            })
            print(f"  [{inst}] {tool}: {len(comments)} review comments")

        benchmark_data[url] = {
            "pr_title": f"canon instance {inst} ({commit})",
            "original_url": None,
            "source_repo": "meta-formalism-copilot",
            "golden_comments": issues,
            "golden_source_file": "meta_formalism_copilot.json",
            "az_comment": None,
            "reviews": reviews,
        }
        print(f"[{inst}] {len(issues)} golden comments")

    gpath = out / "golden_comments/meta_formalism_copilot.json"
    with open(gpath, "w") as f:
        json.dump(golden_entries, f, indent=2)
    bpath = out / "results/benchmark_data.json"
    with open(bpath, "w") as f:
        json.dump(benchmark_data, f, indent=2)
    total = sum(len(v) for v in by_inst.values())
    print(f"\nWrote {gpath} ({len(golden_entries)} instances, {total} goldens)")
    print(f"Wrote {bpath}")


if __name__ == "__main__":
    main()
