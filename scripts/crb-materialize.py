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
blame-ish reading, not enough to reach unrelated later work. Measured on the
5-PR pilot: 33-195 MB each (see clone_mb in the manifest).

Usage:
  scripts/crb-materialize.py --list                     # what's available
  scripts/crb-materialize.py --per-repo 1               # 5-PR pilot (1/repo)
  scripts/crb-materialize.py --slug discourse-graphite-PR1 keycloak-PR37429
  scripts/crb-materialize.py --all                      # all 50 (~6-7 GB)
  scripts/crb-materialize.py --per-repo 1 --dry-run     # print, clone nothing
  scripts/crb-materialize.py --verify grafana-PR79265   # re-check containment
  scripts/crb-materialize.py --reset  grafana-PR79265   # restore, then re-check

Writes/updates runs/review-arms/crb/instances.json. Each record carries: url,
source_repo, pr_title, fork, fork_url, head, base, commits, n_goldens,
files_changed, insertions, deletions, clone_mb, depth. The runner
(runs/review-arms/crb-pipeline/run-host.sh) and the injector
(scripts/crb-pipeline-to-benchmark.py) both read that manifest, so the PR
identity travels with the artifacts instead of being re-derived.
"""

import argparse
import json
import os
import re
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
    """keycloak__keycloak__claude-code__PR37429__20260310 -> keycloak-PR37429.

    The result becomes a directory name under DST_ROOT, so it is constrained to
    a safe charset rather than trusted: repo_name comes from the vendored
    dataset, and `Path(DST_ROOT) / "/abs"` would silently discard DST_ROOT while
    a `/` or `..` component would escape it — into a tree that --force then
    shutil.rmtree()s.
    """
    parts = repo_name.split("__")
    if len(parts) < 4:
        raise ValueError(f"unexpected fork repo name: {repo_name}")
    slug = f"{parts[1]}-{parts[3]}".replace(".", "_")
    if not re.fullmatch(r"[A-Za-z0-9_-]+", slug):
        raise ValueError(f"unsafe slug {slug!r} derived from fork repo name {repo_name!r}")
    return slug


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
    """Upstream project a dataset entry belongs to. The dataset splits two
    projects across mirror repos (sentry / sentry-greptile, keycloak /
    keycloak-greptile); for stratification those are the same codebase, so
    --per-repo 1 yields 5 PRs (one per project), not 7. Note discourse-graphite
    is NOT such a split — it is the only name discourse appears under."""
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
    # --per-repo N: the N PRs with the most golden comments in each source
    # PROJECT — the grouping key is family(source_repo), not source_repo, and
    # that difference is exactly what makes this 5 PRs rather than 7.
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


def verify_containment(dst: Path, slug: str, head: str = None):
    """Assert the no-answer-key invariant on a clone. Returns (n_commits, stat).

    Callable on purpose: materialize() establishes this invariant once, but the
    clone is later mounted READ-WRITE into a review container, so the property
    has to be re-checkable before and after every cell rather than proven once
    at creation. run-host.sh calls this via --reset, which resets first and
    then asserts this; --verify is the read-only form for a human.

    Guard (a) nothing reachable outside the reviewed head's ancestry;
    (b) no remote survives (a re-added remote is the route by which a reviewing
        agent could fetch the merged upstream fix — the answer key);
    (c) the review range is non-empty and the blobs its diff touches are present
        locally, so a partial/broken clone fails here rather than mid-review.
    """
    if head is None:
        head = sh(["git", "rev-parse", "review"], cwd=dst)
    stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
    stray_n = len([l for l in stray.splitlines() if l])
    if stray_n:
        raise RuntimeError(f"{slug}: {stray_n} stray commit(s) reachable outside the reviewed head")
    remotes = sh(["git", "remote"], cwd=dst)
    if remotes:
        raise RuntimeError(f"{slug}: remote(s) present ({remotes.split()!r}) — "
                           "answer-key containment is broken")
    n_commits = int(sh(["git", "rev-list", "--count", "main..review"], cwd=dst))
    stat = sh(["git", "diff", "--shortstat", "main", "review"], cwd=dst)
    if n_commits == 0 or not stat:
        raise RuntimeError(f"{slug}: empty review range (commits={n_commits}, stat={stat!r})")
    return n_commits, stat


def fetch_traces(dst: Path):
    """Evidence that something fetched into this clone since it was scrubbed.

    WHY THIS EXISTS — and what it does NOT do. The 2026-08-18 k=3 fact-check
    refuted, by execution in all three replicates, the claim this module used to
    rest on ("with no remote there is no route to fetch it"). `git fetch <URL>
    <refspec>` needs no configured remote. It leaves no remote, and the objects
    it writes are reachable via `.git/FETCH_HEAD`, which `git rev-list --all`
    does NOT walk. So neither the remote check nor the stray check sees it: a
    replicate built a clone the way materialize() does, fetched an answer key
    with zero remotes, deleted the fetched ref, committed the content on top of
    `review`, and the guard passed it as benign agent work.

    These two checks are therefore DETECTION OF TRACES, not prevention:

      (a) `.git/FETCH_HEAD` — written by every fetch, including a by-URL fetch.
          materialize() deletes it after its own fetches so its later presence
          is meaningful.
      (b) unreachable commits — what a fetch-then-delete-the-ref leaves behind,
          under `--no-reflogs`.

    `--no-reflogs` is load-bearing and was added on the iteration-2 fact-check.
    Without it `git fsck` treats reflog entries as reachability roots, so a
    fetched commit whose ref was deleted stays "reachable" through that ref's
    reflog and check (b) never fires — the check was inert for its stated
    purpose. It is what makes scrub_object_store() load-bearing in turn: with
    reflogs no longer masking anything, the commits reset_clone() discards WOULD
    read as unreachable on the next cell unless the reflogs are expired.

    Defeating both checks requires removing FETCH_HEAD *and* expiring the
    reflogs *and* running `gc --prune=now` — deleting FETCH_HEAD alone still
    voids. That is a higher bar than the earlier comment here claimed, but it is
    still only a bar, not a wall: an agent that clones somewhere else in the
    container filesystem is untouched by any of this. Nothing git-local can
    prevent that while the container has unrestricted egress — the actual
    control is the egress allowlist tracked as R3 in
    docs/reviews/code-review-rubric-2026-08-18-feat-crb-direction1-harness.md.
    Treat a fired check as proof of contamination, never a quiet pass as proof
    of cleanliness.
    """
    traces = []
    if (dst / ".git" / "FETCH_HEAD").exists():
        traces.append("FETCH_HEAD present — something fetched into this clone")
    # --connectivity-only skips object content validation; on a 33-195 MB clone
    # that is the expensive half. (It is NOT what keeps fsck quiet on a shallow
    # clone — measured: fsck is equally quiet on a --depth=1 clone without it.)
    r = subprocess.run(["git", "fsck", "--unreachable", "--no-reflogs",
                        "--connectivity-only", "--no-progress"],
                       cwd=dst, capture_output=True, text=True)
    out = (r.stdout or "") + (r.stderr or "")
    unreachable = [l for l in out.splitlines()
                   if l.startswith("unreachable commit")]
    if unreachable:
        traces.append(f"{len(unreachable)} unreachable commit(s) — "
                      f"a fetched ref that was deleted leaves exactly this")
    # fsck's own errors must not be swallowed. A clean clone exits 0; anything
    # else means the check could not do its job, and a containment check that
    # silently could-not-run is the failure mode this whole module exists to
    # avoid. (materialize() leaves no dangling symref for this to trip on —
    # see the remote-removal ordering there.)
    errors = [l for l in out.splitlines() if l.startswith("error:")]
    if errors:
        traces.append(f"git fsck reported {len(errors)} error(s), first: "
                      f"{errors[0][:160]} — cannot certify containment")
    return traces


def classify_strays(dst: Path, head: str):
    """(strays, foreign) for commits reachable from a ref but not from `head`.

    `foreign` = does not descend from the reviewed head. Descent is NECESSARY
    for a stray to be treated as benign agent work, and it is NOT SUFFICIENT —
    see fetch_traces() above, and note the second refutation the fact-check
    raised: the upstream MERGE commit of this PR descends from the PR head, so
    descent is not evidence of agent authorship. Benign classification requires
    descent AND a clean fetch_traces(); the caller enforces both.

    The expected benign case is real and common: the payload's own CLAUDE.md
    instructs the reviewing agent to commit its work, so voiding on any stray
    (the pre-cf6e7c9 behaviour) would void most cells of the sweep.
    """
    strays = [l for l in sh(["git", "rev-list", "--all", "--not", head],
                            cwd=dst).splitlines() if l]
    foreign = [c for c in strays
               if subprocess.run(["git", "merge-base", "--is-ancestor", head, c],
                                 cwd=dst, capture_output=True).returncode != 0]
    return strays, foreign


def scrub_object_store(dst: Path):
    """Restore the post-materialize baseline: no reflogs, no unreachable objects,
    no FETCH_HEAD.

    Load-bearing, and pinned by test/crb-containment-reset.bats. Because
    fetch_traces() runs `git fsck --no-reflogs`, the commits reset_clone() has
    just discarded are genuinely unreachable, and WOULD fire check (b) on the
    next cell's pre-run check — voiding a clean cell — if the reflogs were not
    expired here.

    (This rationale was wrong when first written: without `--no-reflogs`, fsck
    treated the reflog as a root, nothing ever read as unreachable, and removing
    this call left the suite green. The iteration-2 fact-check caught it. The
    fix was to make the check strict rather than to delete the call, since a
    check that cannot fire is worse than no check.)
    """
    # Heals a clone materialized before the remote-removal ordering fix, whose
    # refs/remotes/origin/HEAD symref was left dangling. for-each-ref does not
    # list a broken ref, so the ref-pruning loop cannot reach it.
    subprocess.run(["git", "symbolic-ref", "-d", "refs/remotes/origin/HEAD"],
                   cwd=dst, capture_output=True, text=True)
    sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
    sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)
    (dst / ".git" / "FETCH_HEAD").unlink(missing_ok=True)


def reset_clone(dst: Path, slug: str, head: str, base: str):
    """Restore a clone to its materialized ref/index/worktree state. Returns a
    note describing what had to be undone (empty when nothing had).

    Raises RuntimeError — i.e. VOIDS the cell — for contamination: a surviving
    remote, a trace of a fetch (see fetch_traces), or a commit that does not
    descend from the reviewed head. Agent-authored commits ON TOP of the head,
    in a clone with no fetch traces, are reset rather than voided.

    This is the between-cells reset, and it replaced `git checkout -- .` +
    `git clean -qfdx`, which restored *tracked files from the index* and so
    undid neither a commit nor a `git add`. Both survivals were silent: the
    containment check inspects refs and remotes, not the index.
    """
    remotes = sh(["git", "remote"], cwd=dst)
    if remotes:
        raise RuntimeError(f"{slug}: remote(s) present ({remotes.split()!r}) — "
                           "answer-key containment is broken")
    # Checked before the descent test so the VOID message names the fetch rather
    # than the commit — on a fetch-and-copy both checks fire, so the order
    # changes which reason is reported, not the verdict.
    traces = fetch_traces(dst)
    if traces:
        raise RuntimeError(f"{slug}: {'; '.join(traces)} — containment is broken")
    strays, foreign = classify_strays(dst, head)
    if foreign:
        raise RuntimeError(
            f"{slug}: {len(foreign)} commit(s) reachable outside the reviewed head "
            f"and NOT descended from it ({foreign[0][:12]}…) — containment is broken")
    dirty = sh(["git", "status", "--porcelain"], cwd=dst)
    # -B moves `review` back onto the pinned head from wherever HEAD now is;
    # --force discards worktree state; the explicit reset --hard then guarantees
    # the index matches too (a staged edit is what `checkout -- .` used to keep).
    sh(["git", "checkout", "--force", "--quiet", "-B", "review", head], cwd=dst)
    sh(["git", "reset", "--hard", "--quiet", head], cwd=dst)
    sh(["git", "branch", "--quiet", "-f", "main", base], cwd=dst)
    # Same scrub materialize() performs, so a branch or tag the agent created
    # cannot linger into the next cell and read as a stray commit there.
    for ref in sh(["git", "for-each-ref", "--format=%(refname)",
                   "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines():
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
    sh(["git", "clean", "-qfdx"], cwd=dst)
    # Restore the object-store baseline LAST: the commits just discarded are
    # unreachable now, and the next cell's fetch_traces() would read them as a
    # deleted fetched ref and void a clean cell.
    scrub_object_store(dst)
    notes = []
    if strays:
        notes.append(f"{len(strays)} agent commit(s) on top of the head, reset")
    if dirty:
        notes.append(f"{len(dirty.splitlines())} dirty path(s) cleaned")
    return "; ".join(notes)


def materialize(slug, url, entry, fork, depth, force):
    dst = DST_ROOT / slug
    if dst.exists():
        if not force:
            print(f"{slug}: exists, skipping (use --force to rebuild)")
            return None
        shutil.rmtree(dst)
    print(f"=== {slug}  ({entry['source_repo']}, {len(entry['golden_comments'])} goldens)")
    # `fork` is interpolated into the clone URL and comes from the vendored
    # dataset. slug_for() only constrains the two components it uses for the
    # directory name, so validate the whole thing here: a `../` component would
    # resolve to a different GitHub owner than FORK_ORG.
    if not re.fullmatch(r"[A-Za-z0-9._-]+", fork):
        raise ValueError(f"unsafe fork repo name {fork!r}")
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
    # Remove the remote FIRST: it takes refs/remotes/origin/* with it, including
    # the symbolic refs/remotes/origin/HEAD. Deleting that symref via
    # `update-ref -d` instead DEREFERENCES it — git removes the branch it points
    # at and leaves the symref dangling, after which `git fsck` exits non-zero
    # with "invalid sha1 pointer" on every later call. That was harmless only
    # while fetch_traces() ignored fsck's exit status; it no longer does.
    subprocess.run(["git", "remote", "remove", "origin"], cwd=dst,
                   capture_output=True, text=True)
    refs = sh(["git", "for-each-ref", "--format=%(refname)",
               "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines()
    for ref in refs:
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
    # Also deletes .git/FETCH_HEAD, which THIS function's own fetches wrote.
    # Deleting it here is what makes its later presence meaningful evidence to
    # fetch_traces() rather than a leftover of materialization.
    scrub_object_store(dst)

    n_commits, stat = verify_containment(dst, slug, head)
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
    g.add_argument("--verify", nargs="+", metavar="SLUG",
                   help="re-assert answer-key containment on existing clone(s) and exit "
                        "(read-only)")
    g.add_argument("--reset", nargs="+", metavar="SLUG",
                   help="restore clone(s) to the materialized state, then verify — "
                        "undoes agent commits/edits, voids only on contamination "
                        "(used by run-host.sh before and after each review cell)")
    ap.add_argument("--depth", type=int, default=50, help="shallow clone depth (default 50)")
    ap.add_argument("--force", action="store_true", help="rebuild existing clones")
    ap.add_argument("--dry-run", action="store_true", help="print the selection, clone nothing")
    args = ap.parse_args()

    if args.verify or args.reset:
        slugs = args.verify or args.reset
        resetting = bool(args.reset)
        manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
        bad = []
        for slug in slugs:
            dst = DST_ROOT / slug
            if not (dst / ".git").is_dir():
                print(f"  !! {slug}: no clone at {dst}", file=sys.stderr)
                bad.append(slug)
                continue
            # Pin to the manifest's recorded head. Without it the stray-commit
            # check is self-referential — it would compare the clone against its
            # OWN current `review` tip, so a moved ref passes trivially. A slug
            # absent from the manifest therefore cannot be verified, and saying
            # so is the only honest outcome: run-host.sh accepts slugs from argv,
            # so this is reachable, and a silent weak pass is what R2 is about.
            rec = manifest.get(slug) or {}
            head, base = rec.get("head"), rec.get("base")
            if not head or (resetting and not base):
                print(f"  !! {slug}: no manifest entry — cannot pin the reviewed head, "
                      f"so containment is unverifiable. Re-materialize this slug.",
                      file=sys.stderr)
                bad.append(slug)
                continue
            try:
                note = reset_clone(dst, slug, head, base) if resetting else ""
                n_commits, stat = verify_containment(dst, slug, head)
            except Exception as e:
                print(f"  !! {slug}: CONTAINMENT CHECK FAILED — {e}", file=sys.stderr)
                bad.append(slug)
                continue
            print(f"  {slug}: containment ok — {n_commits} commit(s), {stat}"
                  + (f" [{note}]" if note else ""))
        if bad:
            sys.exit(f"containment check failed for: {', '.join(bad)}")
        return

    prs = load_prs()
    if args.list:
        print(f"{'slug':32} {'repo':20} {'goldens':>7}  url")
        for slug, url, entry, _fork in prs:
            print(f"{slug:32} {entry['source_repo']:20} "
                  f"{len(entry['golden_comments']):7}  {url}")
        print(f"\n{len(prs)} PRs, {sum(len(e['golden_comments']) for _, _, e, _ in prs)} goldens")
        return
    if not (args.all or args.per_repo or args.slug):
        ap.error("pick one of --list / --per-repo N / --slug ... / --all / "
                 "--verify SLUG ... / --reset SLUG ...")

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
            # Remove the partial clone. Leaving it costs up to ~200 MB AND makes
            # the next run print "exists, skipping" for a repo that never passed
            # its guards — the failure would then hide itself.
            partial = DST_ROOT / slug
            if partial.is_dir():
                shutil.rmtree(partial, ignore_errors=True)
                print(f"{slug}: removed partial clone at {partial}", file=sys.stderr)
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
