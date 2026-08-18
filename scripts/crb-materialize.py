#!/usr/bin/env python3
"""Materialize Code Review Bench (offline) PRs as local review clones.

Direction (1) of docs/working/crb-arm-plan.md: run OUR processes on THEIR
dataset. The benchmark's 50 PRs live as forks under github.com/code-review-
benchmark/<upstream>__<repo>__<tool>__PR<n>__<date>, each with the reviewed
change as PR #1. Every tool's fork of the same original PR carries the same
code (they differ only in which bot reviewed it), so one fork per PR suffices.

For each selected PR this creates external/crb-eval/<slug>/ with:
  - branch `review` at the PR head  (refs/pull/1/head on the fork)
  - branch `main`   at the PR base  (merge-base of head and the fork default)
  - NO other refs and NO origin remote, so a reviewing agent cannot fetch the
    upstream future (the merged fix — the answer key) via `git log --all`.
This mirrors scripts/prep-cc-review-clones.sh, which does the same job for the
meta-formalism-copilot canon instances.

Clones are SHALLOW (--depth, default 50): enough history for context and
blame-ish reading, not enough to reach unrelated later work, and ~1 order of
magnitude smaller on disk than a full clone of grafana/keycloak.

Usage:
  scripts/crb-materialize.py --list                     # what's available
  scripts/crb-materialize.py --per-repo 1               # 5-PR pilot (1/repo)
  scripts/crb-materialize.py --slug discourse-graphite-PR1 keycloak-PR37429
  scripts/crb-materialize.py --all                      # all 50 (~15-25GB)
  scripts/crb-materialize.py --per-repo 1 --dry-run     # print, clone nothing

Writes/updates runs/review-arms/crb/instances.json: slug -> {url, fork, head, base,
n_goldens, files_changed, insertions, deletions, clone_mb}. The runner
(runs/review-arms/crb-pipeline/run-host.sh) and the injector
(scripts/crb-pipeline-to-benchmark.py) both read that manifest, so the PR
identity travels with the artifacts instead of being re-derived.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
BENCH = WORKSPACE / "external/code-review-benchmark/offline"
BENCH_DATA = BENCH / "results/benchmark_data.json"
DST_ROOT = WORKSPACE / "external/crb-eval"
# The manifest lives under runs/ (tracked) rather than beside the clones:
# external/ is gitignored, and the slug -> PR mapping is provenance the
# results depend on, so it must survive a clone wipe.
MANIFEST = WORKSPACE / "runs/review-arms/crb/instances.json"
FORK_ORG = "https://github.com/code-review-benchmark"
# Fork owner whose copy we clone. Any tool's fork works (same code); claude-code
# is present on all 50 and was cut on one date (20260310), so it is the most
# uniform choice.
DEFAULT_FORK_TOOL = "claude-code"


def sh(args, cwd=None, check=True, capture=True):
    r = subprocess.run(args, cwd=cwd, check=False,
                       stdout=subprocess.PIPE if capture else None,
                       stderr=subprocess.PIPE if capture else None, text=True)
    if check and r.returncode != 0:
        raise RuntimeError(f"{' '.join(args)} failed ({r.returncode}): "
                           f"{(r.stderr or '').strip()[:500]}")
    return (r.stdout or "").strip()


def slug_for(repo_name: str) -> str:
    """keycloak__keycloak__claude-code__PR37429__20260310 -> keycloak-PR37429."""
    parts = repo_name.split("__")
    if len(parts) < 4:
        raise ValueError(f"unexpected fork repo name: {repo_name}")
    return f"{parts[1]}-{parts[3]}".replace(".", "_")


def load_prs():
    """[(slug, url, entry, fork_repo_name)] for every PR in the dataset."""
    data = json.loads(BENCH_DATA.read_text())
    out = []
    for url, entry in data.items():
        forks = {r["tool"]: r["repo_name"] for r in entry.get("reviews", [])
                 if r.get("repo_name")}
        fork = forks.get(DEFAULT_FORK_TOOL) or (sorted(forks.values())[0] if forks else None)
        if not fork:
            print(f"  !! no fork repo recorded for {url} — skipped", file=sys.stderr)
            continue
        out.append((slug_for(fork), url, entry, fork))
    out.sort(key=lambda t: t[0])
    return out


def family(source_repo: str) -> str:
    """Upstream project a dataset entry belongs to. The dataset splits a few
    projects across mirror repos (discourse-graphite, sentry-greptile,
    keycloak-greptile); for stratification those are the same codebase, so
    --per-repo 1 should yield 5 PRs (one per project), not 7."""
    return source_repo.split("-")[0]


def select(prs, args):
    if args.slug:
        want = set(args.slug)
        sel = [p for p in prs if p[0] in want]
        missing = want - {p[0] for p in sel}
        if missing:
            sys.exit(f"unknown slug(s): {', '.join(sorted(missing))}")
        return sel
    if args.all:
        return prs
    # --per-repo N: the N PRs with the most golden comments in each source repo.
    # Rationale: goldens are the denominator of recall, so per dollar of review
    # this maximizes measurable signal. Ties break on slug for determinism.
    by_repo = {}
    for p in prs:
        by_repo.setdefault(family(p[2]["source_repo"]), []).append(p)
    sel = []
    for repo in sorted(by_repo):
        ranked = sorted(by_repo[repo],
                        key=lambda p: (-len(p[2]["golden_comments"]), p[0]))
        sel.extend(ranked[: args.per_repo])
    return sorted(sel, key=lambda p: p[0])


def resolve_base(dst: Path, depth: int) -> str:
    """merge-base(review, fork default branch), deepening if the shallow
    boundary hides the common ancestor."""
    for extra in (0, depth * 4, depth * 20):
        if extra:
            sh(["git", "fetch", "--quiet", f"--deepen={extra}", "origin"], cwd=dst)
        r = subprocess.run(["git", "merge-base", "review", "origin/HEAD"],
                           cwd=dst, capture_output=True, text=True)
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip()
    raise RuntimeError("could not find merge-base of the PR head and the fork "
                       "default branch even after deepening")


def dir_mb(path: Path) -> int:
    total = 0
    for root, _dirs, files in os.walk(path):
        for f in files:
            fp = Path(root) / f
            try:
                total += fp.stat().st_size
            except OSError:
                pass
    return round(total / (1024 * 1024))


def materialize(slug, url, entry, fork, depth, force):
    dst = DST_ROOT / slug
    if dst.exists():
        if not force:
            print(f"{slug}: exists, skipping (use --force to rebuild)")
            return None
        shutil.rmtree(dst)
    print(f"=== {slug}  ({entry['source_repo']}, {len(entry['golden_comments'])} goldens)")
    remote = f"{FORK_ORG}/{fork}"
    # --no-checkout: the working tree is populated from `review` below, not from
    # the fork's default branch (which is the BASE — checking it out first would
    # just be thrown away).
    sh(["git", "clone", "--quiet", "--no-checkout", f"--depth={depth}", remote, str(dst)])
    sh(["git", "fetch", "--quiet", f"--depth={depth}", "origin",
        "refs/pull/1/head:refs/heads/review"], cwd=dst)
    head = sh(["git", "rev-parse", "review"], cwd=dst)
    base = resolve_base(dst, depth)
    # Check out `review` FIRST: on forks whose default branch is itself named
    # `main`, HEAD still points at it after --no-checkout, and git refuses to
    # force-update the branch that is checked out.
    sh(["git", "checkout", "--quiet", "review"], cwd=dst)
    sh(["git", "branch", "-f", "main", base], cwd=dst)

    # Scrub: every ref except review/main, the remote, and the reflogs. After
    # this the clone has no route to anything outside the reviewed ancestry.
    refs = sh(["git", "for-each-ref", "--format=%(refname)",
               "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines()
    for ref in refs:
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
    subprocess.run(["git", "remote", "remove", "origin"], cwd=dst,
                   capture_output=True, text=True)
    sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
    sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)

    # Guard (a): nothing reachable outside the reviewed head's ancestry.
    stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
    stray_n = len([l for l in stray.splitlines() if l])
    if stray_n:
        raise RuntimeError(f"{slug}: {stray_n} stray commit(s) survived the scrub")
    # Guard (b): the range is non-empty and its blobs are present locally (a
    # partial/broken clone shows up here rather than mid-review).
    n_commits = int(sh(["git", "rev-list", "--count", "main..review"], cwd=dst))
    stat = sh(["git", "diff", "--shortstat", "main", "review"], cwd=dst)
    if n_commits == 0 or not stat:
        raise RuntimeError(f"{slug}: empty review range (commits={n_commits}, stat={stat!r})")
    files = ins = dels = 0
    for chunk in stat.split(","):
        c = chunk.strip()
        n = int(c.split()[0])
        if "file" in c:
            files = n
        elif "insertion" in c:
            ins = n
        elif "deletion" in c:
            dels = n
    mb = dir_mb(dst)
    print(f"{slug}: ok — {n_commits} commit(s), {files} files "
          f"(+{ins}/-{dels}), {mb} MB on disk")
    return {
        "url": url, "source_repo": entry["source_repo"], "pr_title": entry["pr_title"],
        "fork": fork, "fork_url": remote, "head": head, "base": base,
        "commits": n_commits, "n_goldens": len(entry["golden_comments"]),
        "files_changed": files, "insertions": ins, "deletions": dels,
        "clone_mb": mb, "depth": depth,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--all", action="store_true", help="materialize all 50 PRs")
    g.add_argument("--per-repo", type=int, metavar="N",
                   help="N PRs per source repo, most-goldens-first (N=1 -> 5-PR pilot)")
    g.add_argument("--slug", nargs="+", help="explicit slugs (see --list)")
    g.add_argument("--list", action="store_true", help="list available PRs and exit")
    ap.add_argument("--depth", type=int, default=50, help="shallow clone depth (default 50)")
    ap.add_argument("--force", action="store_true", help="rebuild existing clones")
    ap.add_argument("--dry-run", action="store_true", help="print the selection, clone nothing")
    args = ap.parse_args()

    prs = load_prs()
    if args.list:
        print(f"{'slug':32} {'repo':20} {'goldens':>7}  url")
        for slug, url, entry, _fork in prs:
            print(f"{slug:32} {entry['source_repo']:20} "
                  f"{len(entry['golden_comments']):7}  {url}")
        print(f"\n{len(prs)} PRs, {sum(len(e['golden_comments']) for _, _, e, _ in prs)} goldens")
        return
    if not (args.all or args.per_repo or args.slug):
        ap.error("pick one of --list / --per-repo N / --slug ... / --all")

    sel = select(prs, args)
    print(f"Selected {len(sel)} PR(s), "
          f"{sum(len(e['golden_comments']) for _, _, e, _ in sel)} goldens:")
    for slug, _url, entry, _fork in sel:
        print(f"  {slug:32} {entry['source_repo']:20} {len(entry['golden_comments'])} goldens")
    if args.dry_run:
        print("\n--dry-run: nothing cloned.")
        return

    DST_ROOT.mkdir(parents=True, exist_ok=True)
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    failures = []
    for slug, url, entry, fork in sel:
        try:
            rec = materialize(slug, url, entry, fork, args.depth, args.force)
        except Exception as e:  # keep going; one bad fork shouldn't stop a sweep
            print(f"{slug}: FAILED — {e}", file=sys.stderr)
            failures.append(slug)
            continue
        if rec:
            manifest[slug] = rec
            MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")

    print(f"\nManifest: {MANIFEST} ({len(manifest)} instance(s))")
    if failures:
        print(f"FAILED: {', '.join(failures)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
