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

DISPOSABLE CLONES. Each verified clone is frozen into a hash-pinned baseline
tar under external/crb-eval/.baselines/, and a review cell is a wipe-and-extract
of that tar rather than a repair of the previous cell's tree. The reason is not
tidiness: the work clone is mounted read-write into a
`--dangerously-skip-permissions` container, and the 2026-08-19 review executed
five host-side code-execution paths out of the host then running `git` against
that container-written `.git` (hooks, core.hooksPath, core.fsmonitor, a smudge
filter reachable from tracked `.gitattributes` alone), plus `core.worktree`
redirecting `git clean -qffdx` at an unrelated host directory. So the host does
not read a used `.git` at all. Post-run detection moved to
scripts/crb-audit-clone.sh, which runs inside a throwaway container.

Usage:
  scripts/crb-materialize.py --list                     # what's available
  scripts/crb-materialize.py --per-repo 1               # 5-PR pilot (1/repo)
  scripts/crb-materialize.py --slug discourse-graphite-PR1 keycloak-PR37429
  scripts/crb-materialize.py --all                      # all 50 (~13 GB w/ baselines)
  scripts/crb-materialize.py --per-repo 1 --dry-run     # print, clone nothing
  scripts/crb-materialize.py --verify   grafana-PR79265 # re-check the baseline
  scripts/crb-materialize.py --restore  grafana-PR79265 # wipe + re-extract (per cell)
  scripts/crb-materialize.py --slug grafana-PR79265 --force  # rebuild + baseline

Writes/updates runs/review-arms/crb/instances.json. Each record carries: url,
source_repo, pr_title, fork, fork_url, head, base, commits, n_goldens,
files_changed, insertions, deletions, clone_mb, depth, baseline_tar,
baseline_sha256, baseline_mb, baseline_files_indexed. The runner
(runs/review-arms/crb-pipeline/run-host.sh) and the injector
(scripts/crb-pipeline-to-benchmark.py) both read that manifest, so the PR
identity travels with the artifacts instead of being re-derived.
"""

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
BENCH = WORKSPACE / "external/code-review-benchmark/offline"
BENCH_DATA = BENCH / "results/benchmark_data.json"
DST_ROOT = WORKSPACE / "external/crb-eval"
# Pristine per-slug snapshots. A cell is a wipe-and-extract of one of these, so
# nothing the review container writes can survive into the next cell and no host
# process ever runs `git` against container-written state (2026-08-19 rubric
# R1/R2). Built from a clone no container has touched, and pinned by sha256 in
# the manifest so a tampered baseline refuses to restore.
BASELINE_ROOT = DST_ROOT / ".baselines"
# Harvest looks at these only; see scripts/crb-harvest-artifacts.py.
ARTIFACT_SUFFIXES = (".md", ".json")
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

    Runs ONLY on trees no container has touched: the freshly cloned tree inside
    materialize(), and a temp extract of the baseline under --verify. It used to run per cell, against the clone the
    review container had just written — that is the arrangement the 2026-08-19
    review broke out of (R1/R2), and it is why the per-cell check is now a wipe
    plus an audit inside a container instead.

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


def scrub_object_store(dst: Path):
    """Restore the post-materialize baseline: no reflogs, no unreachable
    objects, no FETCH_HEAD.

    Load-bearing for the AUDIT, not for the reset (there is no reset any more).
    scripts/crb-audit-clone.sh voids a cell on a leftover `.git/FETCH_HEAD` and
    on unreachable commits under `git fsck --no-reflogs`. materialize()'s own
    fetches write both, so unless they are cleared here EVERY baseline would
    carry them and EVERY cell would void — and the checks would mean nothing.
    Clearing them is what makes their later presence evidence.

    Runs on a clone this script just built from the fork, before any container
    has seen it, which is the only reason it is safe to run host `git` here.
    """
    # Heals a clone materialized before the remote-removal ordering fix, whose
    # refs/remotes/origin/HEAD symref was left dangling. for-each-ref does not
    # list a broken ref, so the ref-pruning loop cannot reach it.
    subprocess.run(["git", "symbolic-ref", "-d", "refs/remotes/origin/HEAD"],
                   cwd=dst, capture_output=True, text=True)
    sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
    sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)
    (dst / ".git" / "FETCH_HEAD").unlink(missing_ok=True)


def sha256_file(path: Path, _bufsize: int = 1 << 20) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(_bufsize), b""):
            h.update(chunk)
    return h.hexdigest()


def artifact_index(dst: Path) -> dict:
    """{relpath: sha256} for every .md/.json file in the clone, .git excluded.

    The baseline the harvest diffs against (scripts/crb-harvest-artifacts.py).
    It replaces `git status --porcelain --untracked-files=all`, which had to run
    on the host against a container-written `.git` (2026-08-19 rubric R1: the
    harvest's `git status` was the FIRST host command after the container
    exited, and `core.fsmonitor` fires on exactly that). It is also strictly
    more complete: `--untracked-files=all` still honours `.gitignore`, so a
    rubric written under a path the upstream repo ignores was invisible to it.

    Symlinks are never followed and never indexed, in either direction: a
    symlinked directory is the one way an os.walk could leave the clone.
    """
    index = {}
    for root, dirs, files in os.walk(dst, followlinks=False):
        # Repository internals are not artifacts, at any depth — a nested repo's
        # object store is megabytes of content nobody reviews.
        dirs[:] = [d for d in dirs
                   if d != ".git" and not (Path(root) / d).is_symlink()]
        for name in files:
            if not name.endswith(ARTIFACT_SUFFIXES):
                continue
            fp = Path(root) / name
            if fp.is_symlink() or not fp.is_file():
                continue
            index[str(fp.relative_to(dst))] = sha256_file(fp)
    return index


def snapshot_baseline(dst: Path, slug: str) -> dict:
    """Freeze a PRISTINE clone as the per-cell restore point. Manifest fields.

    ONLY EVER CALL THIS ON A CLONE NO CONTAINER HAS TOUCHED. The baseline is the
    definition of "clean" for every later cell, so snapshotting a used clone
    would launder whatever that cell left behind into the baseline itself.

    That precondition is now established by CONSTRUCTION, not by this paragraph:
    materialize() is the only caller, and it calls this on a tree it has just
    cloned from the fork, immediately after verify_containment() passed. The CLI
    mode that let an operator point this at an arbitrary existing clone
    (--snapshot) was deleted on the 2026-08-19 security review — see the note in
    main() for why a documented precondition was not good enough.
    """
    BASELINE_ROOT.mkdir(parents=True, exist_ok=True)
    tar, idx_path = baseline_paths(slug)
    # Derived from the published names, not respelled: `.part` siblings were the
    # last two places the layout was written out by hand.
    part = tar.with_name(tar.name + ".part")
    # `-C dst .` so the archive holds clone-relative paths: extraction then does
    # not depend on where the clone lived when it was made.
    sh(["tar", "--create", "--file", str(part), "-C", str(dst), "."])
    # Atomic publish. A half-written baseline that is restorable is worse than
    # none: it would restore a truncated repo and the cell would review nothing.
    part.replace(tar)
    index = artifact_index(dst)
    idx_part = idx_path.with_name(idx_path.name + ".part")
    idx_part.write_text(json.dumps(index, indent=0, sort_keys=True) + "\n")
    idx_part.replace(idx_path)
    digest = sha256_file(tar)
    idx_digest = sha256_file(idx_path)
    print(f"  baseline: {tar.name} ({round(tar.stat().st_size / (1024 * 1024))} MB, "
          f"sha256 {digest[:12]}…), {len(index)} artifact path(s) indexed")
    return {
        # Informational provenance only — restore_clone() derives the path from
        # the slug rather than trusting this string, so a hand-edited manifest
        # cannot redirect an extraction. Recorded workspace-relative when it can
        # be (the normal case, and what a results doc should quote) and absolute
        # otherwise, rather than raising: a provenance field must not be able to
        # fail a snapshot.
        "baseline_tar": str(tar.relative_to(WORKSPACE)
                            if tar.is_relative_to(WORKSPACE) else tar),
        "baseline_sha256": digest,
        # The index is the OTHER half of this contract and gets the same
        # treatment: atomic publish and a hash in the manifest. It was previously
        # written non-atomically, hashed by nothing, and first required ~110 lines
        # into the cell — i.e. AFTER the $10-40 review was paid — so a stale or
        # truncated index silently changed what "the pipeline wrote this" means
        # and no check could see it. `baseline_files_indexed` was recorded and
        # never compared, which is the same defect wearing a number.
        "baseline_index_sha256": idx_digest,
        "baseline_mb": round(tar.stat().st_size / (1024 * 1024)),
        "baseline_files_indexed": len(index),
    }


def baseline_paths(slug: str):
    """(tar, index) for a slug. The ONE place this layout is defined.

    `run-host.sh` used to spell `.baselines/$id.tar` and `.baselines/$id.index.json`
    itself, in two places — the hand-copy failure `scripts/crb_common.py`'s
    docstring exists to prevent, reproduced in new code. The runner now asks for
    them via `--baseline-paths <slug>` instead of restating the layout.
    """
    return BASELINE_ROOT / f"{slug}.tar", BASELINE_ROOT / f"{slug}.index.json"


def restore_clone(slug: str, rec: dict) -> str:
    """Wipe the work clone and re-extract it from the hash-pinned baseline.

    This replaced reset_clone(), which repaired the clone in place with
    `checkout --force` / `reset --hard` / `clean -qffdx` / `gc` / `fsck` — all
    of them HOST git commands run against a `.git` that a
    `--dangerously-skip-permissions` container had just had write access to. The
    2026-08-19 review executed five host-side code-execution paths out of that
    arrangement (hooks, `core.hooksPath`, `core.fsmonitor`, a smudge filter
    reachable from tracked `.gitattributes` alone) plus `core.worktree`
    redirecting `git clean -qffdx` at an unrelated host directory. No
    enumeration of dangerous config keys closes that; not reading the foreign
    `.git` at all does.

    Everything the old reset had to reason about therefore stops being a
    question: an agent commit, a staged edit, a created branch, a deleted
    `main`, a nested clone of the answer key — all are simply gone, and none of
    them can be confused with contamination. Detection moved to
    scripts/crb-audit-clone.sh, which runs on the outgoing clone inside a
    throwaway container and only has to record evidence, never repair.
    """
    tar, idx_unused = baseline_paths(slug)
    if not tar.is_file():
        raise RuntimeError(f"no baseline at {tar} — rebuild with "
                           f"`--slug {slug} --force`")
    want = rec.get("baseline_sha256")
    if not want:
        raise RuntimeError(f"manifest has no baseline_sha256 — rebuild with "
                           f"`--slug {slug} --force`")
    got = sha256_file(tar)
    if got != want:
        raise RuntimeError(
            f"baseline sha256 mismatch (manifest {want[:12]}…, file {got[:12]}…) — "
            f"refusing to restore. Re-materialize this slug.")
    # Both halves, before the cell rather than after it. The index is what the
    # harvest diffs against, so an index that does not match this tar makes every
    # artifact decision wrong in a way nothing downstream can detect — and the
    # cell is paid for by then.
    idx_path = idx_unused
    idx_want = rec.get("baseline_index_sha256")
    if not idx_path.is_file():
        raise RuntimeError(f"no baseline index at {idx_path} — rebuild with "
                           f"`--slug {slug} --force`")
    if not idx_want:
        raise RuntimeError(
            f"manifest has no baseline_index_sha256 (baseline predates the index "
            f"pin) — rebuild with `--slug {slug} --force`")
    idx_got = sha256_file(idx_path)
    if idx_got != idx_want:
        raise RuntimeError(
            f"baseline INDEX sha256 mismatch (manifest {idx_want[:12]}…, file "
            f"{idx_got[:12]}…) — refusing to restore. Re-materialize this slug.")
    dst = DST_ROOT / slug
    if dst.exists():
        shutil.rmtree(dst)
    dst.mkdir(parents=True)
    sh(["tar", "--extract", "--file", str(tar), "-C", str(dst)])
    if not (dst / ".git").is_dir():
        raise RuntimeError(f"restored tree has no .git — baseline {tar.name} is corrupt")
    return f"restored from {tar.name} ({want[:12]}…)"


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
    # while the fsck check ignored fsck's exit status; the audit no longer does.
    subprocess.run(["git", "remote", "remove", "origin"], cwd=dst,
                   capture_output=True, text=True)
    refs = sh(["git", "for-each-ref", "--format=%(refname)",
               "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines()
    for ref in refs:
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
    # Also deletes .git/FETCH_HEAD, which THIS function's own fetches wrote.
    # Deleting it here is what makes its later presence meaningful evidence to
    # scripts/crb-audit-clone.sh rather than a leftover of materialization.
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
    rec = {
        "url": url, "source_repo": entry["source_repo"], "pr_title": entry["pr_title"],
        "fork": fork, "fork_url": remote, "head": head, "base": base,
        "commits": n_commits, "n_goldens": len(entry["golden_comments"]),
        "files_changed": files, "insertions": ins, "deletions": dels,
        "clone_mb": mb, "depth": depth,
    }
    # Snapshot LAST, and only after verify_containment has passed: the baseline
    # is the definition of "clean" every later cell restores to, so it must be
    # taken from a tree that has just been proven contained. Doubles the disk
    # cost of the arm (pilot ~670 MB -> ~1.3 GB; --all ~6.5 -> ~13 GB), which is
    # the price of never running host git against a container-written .git.
    rec.update(snapshot_baseline(dst, slug))
    return rec


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
                   help="re-assert answer-key containment on the BASELINE of clone(s) "
                        "and exit (read-only; extracts to a temp dir, never touches the "
                        "work clone)")
    g.add_argument("--baseline-paths", metavar="SLUG",
                   help="print this slug's baseline tar and index paths, one per "
                        "line, and exit. The runner's precondition check uses this "
                        "instead of restating the .baselines/ layout in bash.")
    g.add_argument("--restore", nargs="+", metavar="SLUG",
                   help="DESTRUCTIVE. Wipe the work clone(s) and re-extract from the "
                        "hash-pinned baseline — the per-cell reset run-host.sh performs "
                        "before every review cell. No git runs against the old tree.")
    # There is deliberately NO mode that baselines an EXISTING clone. The one
    # that existed (--snapshot) was the last place host `git` ran against a
    # directory this script had not just created, and the 2026-08-19 security
    # review found it reopened R1: `git symbolic-ref -d` performs a ref
    # transaction, so a container-written `reference-transaction` hook or
    # `core.hooksPath` fires, and `verify_containment`'s `git diff` adds the
    # `.gitattributes` smudge-filter path. Its "pristine clone" precondition was
    # prose only, and the runner printed it as the remedy on the path EVERY
    # pre-baseline clone takes — so the unsafe path was the expected first run.
    #
    # A clone without a baseline is therefore re-materialized (`--slug <id>
    # --force`), which throws the directory away and clones afresh from the
    # fork. That costs a re-download and is the only form of the operation whose
    # safety is established by construction rather than by a comment.
    ap.add_argument("--depth", type=int, default=50, help="shallow clone depth (default 50)")
    ap.add_argument("--force", action="store_true", help="rebuild existing clones")
    ap.add_argument("--dry-run", action="store_true", help="print the selection, clone nothing")
    args = ap.parse_args()

    if args.baseline_paths:
        tar, idx = baseline_paths(args.baseline_paths)
        print(tar)
        print(idx)
        return

    if args.verify or args.restore:
        slugs = args.verify or args.restore
        mode = "--verify" if args.verify else "--restore"
        # --dry-run applies to these modes too. It used to be read only further
        # down, so `--reset SLUG --dry-run` (the mode --restore replaced) ran the
        # full destructive reset while its help text advertised "clone nothing".
        if args.dry_run:
            print(f"--dry-run: would run {mode} on {len(slugs)} clone(s): "
                  f"{', '.join(slugs)}. Nothing touched.")
            return
        manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
        bad = []
        for slug in slugs:
            rec = manifest.get(slug) or {}
            head = rec.get("head")
            # --verify runs verify_containment, whose stray-commit
            # check is self-referential without a pinned head: compared against
            # the clone's OWN current `review` tip, a moved ref passes trivially.
            # A slug absent from the manifest therefore cannot be verified, and
            # saying so is the only honest outcome — run-host.sh accepts slugs
            # from argv, so this is reachable.
            #
            # --restore is deliberately NOT in that list: it asserts nothing
            # about the clone, it deletes it and unpacks a hash-pinned archive.
            # Its precondition is baseline_sha256, which restore_clone() checks
            # and names. Requiring a head here would have made every restore
            # depend on a field it does not use.
            if not head and not args.restore:
                print(f"  !! {slug}: no manifest entry — cannot pin the reviewed head, "
                      f"so containment is unverifiable. Re-materialize this slug.",
                      file=sys.stderr)
                bad.append(slug)
                continue
            try:
                if args.restore:
                    print(f"  {slug}: {restore_clone(slug, rec)}")
                else:
                    # Verify the BASELINE, not the work clone: the work clone may
                    # have been mounted read-write into an agent container, and
                    # host git must never read a `.git` from one (2026-08-19
                    # R1/R2). The baseline is hash-pinned and was built before any
                    # container existed, so a temp extract of it is safe to inspect
                    # — and it is also the thing every cell actually starts from.
                    tar, _idx = baseline_paths(slug)
                    if not tar.is_file():
                        raise RuntimeError(f"no baseline at {tar} — rebuild with "
                                           f"`--slug {slug} --force`")
                    want = rec.get("baseline_sha256")
                    got = sha256_file(tar)
                    if not want:
                        raise RuntimeError("manifest has no baseline_sha256")
                    if got != want:
                        raise RuntimeError(f"baseline sha256 mismatch "
                                           f"(manifest {want[:12]}…, file {got[:12]}…)")
                    with tempfile.TemporaryDirectory(prefix=f"crb-verify-{slug}-") as tmp:
                        sh(["tar", "--extract", "--file", str(tar), "-C", tmp])
                        n_commits, stat = verify_containment(Path(tmp), slug, head)
                    print(f"  {slug}: baseline ok — sha256 {got[:12]}…, "
                          f"{n_commits} commit(s), {stat}")
            except Exception as e:
                print(f"  !! {slug}: {mode.lstrip('-').upper()} FAILED — {e}", file=sys.stderr)
                bad.append(slug)
                continue
        if bad:
            sys.exit(f"{mode} failed for: {', '.join(bad)}")
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
        # DESTRUCTIVE modes are marked: --restore deletes the work clone outright;
        # --force rebuilds a clone from scratch. --verify and --list are read-only.
        ap.error("pick one of --list / --per-repo N / --slug ... / --all / "
                 "--verify SLUG ... (read-only) / --restore SLUG ... (DESTRUCTIVE: "
                 "wipes the work clone). A clone with no baseline is rebuilt with "
                 "--slug SLUG --force, not baselined in place.")

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
