#!/usr/bin/env python3
"""Turn one reviewed commit range into a review-canon instance, as text.

Usage:
  canon-instance.py --repo PATH --base SHA --head SHA --id NAME --rubric PATH
                    [--rubric-commit SHA] [--ledger-csv PATH] [--clone DEST]
                    [--repo-name NAME]

Spec: section 10 of docs/working/research-2026-11-05-canon-proposal-filter.md;
the rule that picks which range to convert is its section 8. This script does
not classify, rank or propose, and it runs no review arm.

It checks, refusing with a named reason (exit 1) when one fails:
  - both commits resolve, neither is spelled like an option, base is a strict
    ancestor of head, and the two-dot diff is not empty;
  - the change outside docs/ is at most MAX_FILES files and MAX_LINES changed
    lines (rule step 4; a diff's docs/ part is review records, not code);
  - the rubric has a table with a "Finding" column, found by header name,
    never by position.
Then it prints, on stdout, one review-canon.md section 1 row and one skeleton
ledger CSV row per red or amber finding. It writes neither canon file: the
append-only canon changes only by a reviewed commit that pastes these lines.

--rubric-commit reads the rubric from git at that commit instead of the
working tree, so the labels are pinned (FP-064: a rubric path is overwritten
by later runs). --ledger-csv reads the ledger's header so the skeleton rows
have its columns; without it a five-column header is printed first.
--clone builds a scrubbed clone at DEST (which must not exist): branch review
at head, branch main at base, no other refs, no remote, unreachable objects
pruned. Guard (a): no commit outside head's ancestry survives. Guard (b): no
docs/reviews/ file in the tree names head (its own review, the answer key).
On a guard failure the clone is removed and the files are named.

Usage errors exit 2. Python 3 stdlib and git only.
"""

import argparse
import csv
import io
import os
import re
import shutil
import subprocess
import sys

MAX_FILES = 10
MAX_LINES = 500
SEVERITY = {"🔴": "R", "🟡": "A", "🟢": "C"}


class Refusal(Exception):
    pass


def git_env():
    # A GIT_DIR or GIT_WORK_TREE inherited from the caller would beat -C and
    # point every command at another repository; drop git's local variables.
    env = dict(os.environ)
    for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_OBJECT_DIRECTORY",
                 "GIT_ALTERNATE_OBJECT_DIRECTORIES", "GIT_COMMON_DIR", "GIT_NAMESPACE",
                 "GIT_PREFIX", "GIT_CEILING_DIRECTORIES"):
        env.pop(name, None)
    return env


def git(repo, *args, check=True):
    proc = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True,
                          env=git_env())
    if check and proc.returncode != 0:
        raise Refusal("git %s failed: %s" % (args[0], proc.stderr.strip() or proc.returncode))
    return proc


def resolve(repo, name, rev):
    if not rev or rev.startswith("-"):
        raise Refusal("%s %r is empty or spelled like an option" % (name, rev))
    proc = git(repo, "rev-parse", "--verify", "--quiet", "--end-of-options",
               rev + "^{commit}", check=False)
    if proc.returncode != 0:
        raise Refusal("%s %s does not resolve to a commit in %s" % (name, rev, repo))
    return proc.stdout.strip()


def check_range(repo, base, head):
    if base == head:
        raise Refusal("empty range: base and head are the same commit %s" % base[:12])
    if git(repo, "merge-base", "--is-ancestor", base, head, check=False).returncode != 0:
        raise Refusal("base %s is not an ancestor of head %s" % (base[:12], head[:12]))
    files, added, deleted, total = 0, 0, 0, 0
    out = git(repo, "diff", "--numstat", "--no-renames", "-z", base, head, "--").stdout
    for rec in out.split("\0"):
        if not rec:
            continue
        a, d, path = rec.split("\t", 2)
        total += 1
        if path.startswith("docs/"):
            continue
        files += 1
        # numstat prints "-" for a binary file; it counts as a file, not lines.
        added += int(a) if a.isdigit() else 0
        deleted += int(d) if d.isdigit() else 0
    if total == 0:
        raise Refusal("empty range: %s..%s changes no file" % (base[:12], head[:12]))
    if files == 0:
        raise Refusal("empty range: %s..%s changes only docs/" % (base[:12], head[:12]))
    if files > MAX_FILES:
        raise Refusal("over the size limit: %d files outside docs/ (limit %d)" % (files, MAX_FILES))
    if added + deleted > MAX_LINES:
        raise Refusal("over the size limit: %d changed lines outside docs/ (limit %d)"
                      % (added + deleted, MAX_LINES))
    return files, added, deleted


def cells(line):
    s = line.strip()
    if not s.startswith("|"):
        return None
    s = s[1:-1] if s.endswith("|") and len(s) > 1 else s[1:]
    return [c.strip() for c in re.split(r"(?<!\\)\|", s)]


def parse_rubric(text):
    """Red, amber and green rows of every table with a Finding column.

    Severity comes from the nearest heading's marker, else the ID's letter."""
    rows, heading, found_table = [], "", False
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("#"):
            heading = line
        head = cells(line)
        sep = cells(lines[i + 1]) if i + 1 < len(lines) else None
        if head and sep and all(re.fullmatch(r":?-{3,}:?", c) for c in sep if c):
            names = [h.lower() for h in head]
            i += 2
            body = []
            while i < len(lines) and cells(lines[i]) is not None:
                body.append(cells(lines[i]))
                i += 1
            if "finding" not in names:
                continue
            found_table = True
            fcol = names.index("finding")
            icol = next((names.index(n) for n in ("#", "id") if n in names), None)
            sev_heading = next((v for k, v in SEVERITY.items() if k in heading), None)
            for r in body:
                if fcol >= len(r):
                    continue
                rid = r[icol] if icol is not None and icol < len(r) else ""
                sev = sev_heading or (rid[:1].upper() if rid[:1].upper() in "RAC" else None)
                if sev:
                    rows.append((sev, rid or "%s%d" % (sev, len(rows) + 1), r[fcol]))
            continue
        i += 1
    if not found_table:
        raise Refusal("rubric has no table with a Finding column")
    return rows


def read_rubric(repo, path, commit):
    if commit:
        sha = resolve(repo, "rubric commit", commit)
        proc = git(repo, "show", "%s:%s" % (sha, path), check=False)
        if proc.returncode != 0:
            raise Refusal("rubric %s is not in commit %s" % (path, sha[:12]))
        return proc.stdout, "%s@%s" % (path, sha[:8])
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read(), path
    except OSError as exc:
        raise Refusal("rubric %s cannot be read: %s" % (path, exc.strerror))


def plain(text):
    text = re.sub(r"[*`]", "", text).replace("\\|", "|")
    return re.sub(r"\s+", " ", text).strip()


def ledger_rows(header, iid, repo_name, head, labels):
    names = [h.strip() for h in header]
    def col(prefix):
        for k, n in enumerate(names):
            if n.lower().startswith(prefix):
                return k
        raise Refusal("ledger header has no column starting %r" % prefix)
    cid, csum, crepo, ccommit, cfix = (col("issue id"), col("issue summary"), col("repo"),
                                       col("commit id"), col("fix status"))
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    for sev, rid, finding in labels:
        row = ["not run"] * len(names)
        row[cid] = "%s-%s" % (iid, rid)
        row[csum] = plain(finding)
        row[crepo] = repo_name
        row[ccommit] = head[:8]
        row[cfix] = "TODO: fix commit"
        w.writerow(row)
    return buf.getvalue()


def build_clone(repo, dest, base, head):
    if os.path.lexists(dest):
        raise Refusal("clone destination %s already exists" % dest)
    proc = subprocess.run(["git", "clone", "--quiet", "--no-hardlinks", "--no-checkout",
                           "--", repo, dest], capture_output=True, text=True, env=git_env())
    if proc.returncode != 0:
        raise Refusal("git clone failed: %s" % proc.stderr.strip())
    try:
        git(dest, "checkout", "--quiet", "-B", "review", head)
        git(dest, "branch", "-f", "main", base)
        refs = git(dest, "for-each-ref", "--format=%(refname)", "refs/heads", "refs/tags",
                   "refs/remotes").stdout.split()
        for ref in refs:
            if ref not in ("refs/heads/review", "refs/heads/main"):
                git(dest, "update-ref", "-d", ref)
        git(dest, "remote", "remove", "origin", check=False)
        git(dest, "reflog", "expire", "--expire=now", "--all")
        git(dest, "gc", "--quiet", "--prune=now")
        stray = git(dest, "rev-list", "--all", "--not", head).stdout.split()
        if stray:
            raise Refusal("guard (a): %d commit(s) outside head's ancestry survived" % len(stray))
        own = reviews_naming(dest, [head[:7]])
        if own:
            raise Refusal("guard (b): the tree has its own review (names head %s): %s"
                          % (head[:7], ", ".join(own)))
        older = [p for p in git(dest, "ls-tree", "-r", "--name-only", "HEAD").stdout.split("\n")
                 if p.startswith("docs/reviews/")]
        inner = [c for c in git(dest, "rev-list", "%s..%s" % (base, head)).stdout.split()
                 if c != head]
        under = int(git(dest, "rev-list", "--count", "main..review").stdout)
    except Refusal:
        shutil.rmtree(dest, ignore_errors=True)
        raise
    # A review of a commit inside the range is in the tree the reviewer reads:
    # not the answer key for head, but worth saying in the provenance.
    return under, len(older), reviews_naming(dest, [c[:7] for c in inner])


def reviews_naming(dest, prefixes):
    """docs/reviews/ files in the clone's HEAD tree that name any prefix."""
    if not prefixes:
        return []
    args = ["grep", "-l", "-F"]
    for p in prefixes:
        args += ["-e", p]
    proc = git(dest, *args, "HEAD", "--", "docs/reviews/", check=False)
    if proc.returncode not in (0, 1):
        raise Refusal("git grep failed in the clone: %s" % proc.stderr.strip())
    return [p.split(":", 1)[-1] for p in proc.stdout.split("\n") if p]


def main(argv):
    ap = argparse.ArgumentParser(prog="canon-instance.py", add_help=True)
    ap.add_argument("--repo", required=True)
    ap.add_argument("--base", required=True)
    ap.add_argument("--head", required=True)
    ap.add_argument("--id", required=True)
    ap.add_argument("--rubric", required=True)
    ap.add_argument("--rubric-commit")
    ap.add_argument("--ledger-csv")
    ap.add_argument("--clone")
    ap.add_argument("--repo-name", help="the ledger's repo column (default: the top level's name)")
    a = ap.parse_args(argv)
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,39}", a.id):
        print("canon-instance: refused: id %r must be lower-case letters, digits and -" % a.id,
              file=sys.stderr)
        return 2
    try:
        if not os.path.isdir(a.repo) or git(a.repo, "rev-parse", "--git-dir",
                                             check=False).returncode != 0:
            raise Refusal("repo %s is not a git repository" % a.repo)
        base = resolve(a.repo, "base", a.base)
        head = resolve(a.repo, "head", a.head)
        files, added, deleted = check_range(a.repo, base, head)
        text, rubric_ref = read_rubric(a.repo, a.rubric, a.rubric_commit)
        labels = parse_rubric(text)
        if a.ledger_csv:
            with open(a.ledger_csv, encoding="utf-8", newline="") as fh:
                header = next(csv.reader(fh), None)
            if not header:
                raise Refusal("ledger %s has no header row" % a.ledger_csv)
        else:
            header = ["issue ID", "issue summary", "repo", "commit ID",
                      "fix status (including commit ID if fixed)"]
        repo_name = a.repo_name or os.path.basename(
            git(a.repo, "rev-parse", "--show-toplevel").stdout.strip())
        rows = ledger_rows(header, a.id, repo_name, head, [x for x in labels if x[0] in "RA"])
        clone = build_clone(a.repo, a.clone, base, head) if a.clone else None
    except (Refusal, OSError) as exc:
        print("canon-instance: refused: %s" % exc, file=sys.stderr)
        return 1
    count = {s: sum(1 for x in labels if x[0] == s) for s in "RAC"}
    status = ("🔴 DOES NOT PASS" if count["R"] else "🟡 CONDITIONAL" if count["A"]
              else "✅ PASSES")
    print("| %s | `%s..%s` | %df +%d/−%d | `%s` | %s | %d/%d/%d | TODO: provenance |"
          % (a.id, base[:8], head[:8], files, added, deleted, rubric_ref, status,
             count["R"], count["A"], count["C"]))
    print()
    if not a.ledger_csv:
        sys.stdout.write(",".join(header) + "\n")
    sys.stdout.write(rows)
    if clone is not None:
        under, older, inner = clone
        print()
        print("clone %s: ok, %d commit(s) under review, %d older docs/reviews/ file(s)"
              % (a.clone, under, older))
        for path in inner:
            print("clone note: %s names a commit inside the range" % path)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
