#!/usr/bin/env python3
"""Turn one reviewed commit range into a review-canon instance, as text.

Spec: section 10 of docs/working/research-2026-11-05-canon-proposal-filter.md
(section 8 is the rule that picks the range). It does not classify, rank or
propose, and runs no review arm. It refuses with a named reason (exit 1)
unless both commits resolve and neither is spelled like an option, base is a
strict ancestor of head, the diff changes a file outside docs/, that part is
at most 10 files and 500 changed lines (a binary file counts 0 lines), and the
rubric has a table with a Finding column (found by header name) whose every
row has a severity (a 🔴/🟡/🟢 heading or cell, or an R/A/C ID). Then it prints one
review-canon.md section 1 row and a skeleton ledger CSV row per red or amber
finding. It writes neither canon file. Usage errors exit 2.

--rubric-commit reads the rubric at that commit, not the working tree, which
pins the labels (FP-064). --ledger-csv takes the ledger's header, columns found
by name. --clone DEST (DEST must not exist) builds a scrubbed clone: branch
review at head, main at base, no other refs or remote, hooks off, unreachable
objects pruned; guard (a) refuses if a commit outside head's ancestry
survives, guard (b) if a docs/reviews/ file names head, and files naming other
commits of the range are noted. A refused clone is removed.
"""

import argparse
import csv
import io
import os
import re
import shutil
import subprocess
import sys

MAX_FILES, MAX_LINES = 10, 500
SEVERITY = {"🔴": "R", "🟡": "A", "🟢": "C"}
# Inherited, these would beat -C and point git at another repository.
GIT_LOCAL = ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_OBJECT_DIRECTORY",
             "GIT_ALTERNATE_OBJECT_DIRECTORIES", "GIT_COMMON_DIR", "GIT_NAMESPACE",
             "GIT_PREFIX", "GIT_CEILING_DIRECTORIES")


class Refusal(Exception):
    pass


def git(repo, *args, check=True):
    env = {k: v for k, v in os.environ.items() if k not in GIT_LOCAL}
    proc = subprocess.run(["git", "-c", "core.hooksPath=/dev/null", "-C", repo, *args],
                          capture_output=True, env=env)
    proc.stdout = proc.stdout.decode("utf-8", "surrogateescape")
    if check and proc.returncode != 0:
        raise Refusal("git %s failed: %s" % (args[0], proc.stderr.decode("utf-8", "replace")
                                             .strip() or proc.returncode))
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
    span = "%s..%s" % (base[:12], head[:12])
    if base == head:
        raise Refusal("empty range: base and head are the same commit %s" % base[:12])
    if git(repo, "merge-base", "--is-ancestor", base, head, check=False).returncode != 0:
        raise Refusal("base %s is not an ancestor of head %s" % (base[:12], head[:12]))
    total = files = added = deleted = 0
    for rec in git(repo, "diff", "--numstat", "--no-renames", "-z", base, head,
                   "--").stdout.split("\0"):
        if not rec:
            continue
        a, d, path = rec.split("\t", 2)
        total += 1
        if not path.startswith("docs/"):
            files += 1
            added += int(a) if a.isdigit() else 0  # "-" marks a binary file
            deleted += int(d) if d.isdigit() else 0
    if total == 0:
        raise Refusal("empty range: %s changes no file" % span)
    if files == 0:
        raise Refusal("empty range: %s changes only docs/" % span)
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
    """(severity, id, finding) for each row of every table with a Finding column."""
    rows, heading, found, fence = [], "", False, False
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.lstrip().startswith(("```", "~~~")):
            fence = not fence
        if line.startswith("#") and not fence:
            heading = line
        head, sep = cells(line), cells(lines[i + 1]) if i + 1 < len(lines) else None
        if fence or not (head and sep and all(re.fullmatch(r":?-+:?", c) for c in sep if c)):
            i += 1
            continue
        names = [h.lower() for h in head]
        i += 2
        body = []
        while i < len(lines) and cells(lines[i]) is not None:
            body.append(cells(lines[i]))
            i += 1
        if "finding" not in names:
            continue
        found = True
        fcol = names.index("finding")
        icol = next((names.index(n) for n in ("#", "id") if n in names), None)
        hsev = next((v for k, v in SEVERITY.items() if k in heading), None)
        for r in body:
            rid = r[icol] if icol is not None and icol < len(r) else ""
            # Later-iteration tables often carry the marker in a cell of their own.
            cell = next((v for c in r for k, v in SEVERITY.items() if k in c), None)
            sev = hsev or cell or (rid[:1].upper() if rid[:1].upper() in ("R", "A", "C") else None)
            if not sev:
                raise Refusal("rubric row %r has no severity (no 🔴/🟡/🟢 heading or cell, no R/A/C ID)"
                              % (rid or r[0]))
            rows.append((sev, rid or "%s%d" % (sev, len(rows) + 1),
                         r[fcol] if fcol < len(r) else ""))
    if not found:
        raise Refusal("rubric has no table with a Finding column")
    return rows


def read_rubric(repo, path, commit):
    if not commit:
        with open(path, encoding="utf-8") as fh:
            return fh.read(), path
    sha = resolve(repo, "rubric commit", commit)
    proc = git(repo, "show", "%s:%s" % (sha, path), check=False)
    if proc.returncode != 0:
        raise Refusal("rubric %s is not in commit %s" % (path, sha[:12]))
    proc.stdout.encode("utf-8")  # a surrogate here means the file is not UTF-8
    return proc.stdout, "%s@%s" % (path, sha[:8])


def ledger_rows(header, iid, repo_name, head, labels):
    names = [h.strip().lower() for h in header]

    def col(prefix):
        hit = [k for k, n in enumerate(names) if n.startswith(prefix)]
        if not hit:
            raise Refusal("ledger header has no column starting %r" % prefix)
        return hit[0]
    cols = [col(p) for p in ("issue id", "issue summary", "repo", "commit id", "fix status")]
    buf = io.StringIO()
    out = csv.writer(buf, lineterminator="\n")
    for _sev, rid, finding in labels:
        row = ["not run"] * len(names)
        summary = re.sub(r"\s+", " ", re.sub(r"[*`]", "", finding).replace("\\|", "|")).strip()
        for k, v in zip(cols, ("%s-%s" % (iid, rid), summary, repo_name, head[:8],
                               "TODO: fix commit")):
            row[k] = v
        out.writerow(row)
    return buf.getvalue()


def reviews_naming(dest, prefixes):
    """docs/reviews/ files in the clone's HEAD tree that name any of the prefixes."""
    if not prefixes:
        return []
    args = ["grep", "-l", "-z", "-F"] + [x for p in prefixes for x in ("-e", p)]
    proc = git(dest, *args, "HEAD", "--", "docs/reviews/", check=False)
    if proc.returncode not in (0, 1):
        raise Refusal("git grep failed in the clone")
    return [p.split(":", 1)[-1] for p in proc.stdout.split("\0") if p]


def build_clone(repo, dest, base, head):
    if os.path.lexists(dest):
        raise Refusal("clone destination %s already exists" % dest)
    # An absolute path keeps a name like h:x from being read as an ssh URL.
    git(".", "clone", "--quiet", "--no-hardlinks", "--no-checkout", "--origin", "origin",
        "--", os.path.abspath(repo), dest)
    try:
        git(dest, "checkout", "--quiet", "-B", "review", head)
        git(dest, "branch", "-f", "main", base)
        for ref in git(dest, "for-each-ref", "--format=%(refname)").stdout.split():
            if ref not in ("refs/heads/review", "refs/heads/main"):
                git(dest, "update-ref", "-d", ref)
        git(dest, "remote", "remove", "origin")
        git(dest, "reflog", "expire", "--expire=now", "--all")
        git(dest, "gc", "--quiet", "--prune=now")
        stray = git(dest, "rev-list", "--all", "--not", head).stdout.split()
        if stray:
            raise Refusal("guard (a): %d commit(s) outside head's ancestry survived" % len(stray))
        own = reviews_naming(dest, [head[:7]])
        if own:
            raise Refusal("guard (b): the tree has its own review (names head %s): %s"
                          % (head[:7], ", ".join(own)))
        older = sum(1 for p in git(dest, "ls-tree", "-r", "-z", "--name-only", "HEAD")
                    .stdout.split("\0") if p.startswith("docs/reviews/"))
        inner = [c[:7] for c in git(dest, "rev-list", "%s..%s" % (base, head)).stdout.split()
                 if c != head]
        under = len(inner) + 1
        return under, older, reviews_naming(dest, inner)
    except BaseException:
        shutil.rmtree(dest, ignore_errors=True)
        raise


def repo_name_of(repo):
    # The common dir names the repository even from a linked worktree.
    common = git(repo, "rev-parse", "--path-format=absolute", "--git-common-dir").stdout.strip()
    return os.path.basename(os.path.dirname(common) if common.endswith("/.git") else common)


def main(argv):
    ap = argparse.ArgumentParser(prog="canon-instance.py", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    for name in ("--repo", "--base", "--head", "--id", "--rubric"):
        ap.add_argument(name, required=True)
    for name in ("--rubric-commit", "--ledger-csv", "--clone", "--repo-name"):
        ap.add_argument(name)
    a = ap.parse_args(argv)
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,39}", a.id):
        print("canon-instance: refused: id %r must be lower-case letters, digits and -" % a.id,
              file=sys.stderr)
        return 2
    try:
        if not os.path.isdir(a.repo) or git(a.repo, "rev-parse", "--git-dir",
                                             check=False).returncode != 0:
            raise Refusal("repo %s is not a git repository" % a.repo)
        base, head = resolve(a.repo, "base", a.base), resolve(a.repo, "head", a.head)
        files, added, deleted = check_range(a.repo, base, head)
        text, rubric_ref = read_rubric(a.repo, a.rubric, a.rubric_commit)
        labels = parse_rubric(text)
        header = ["issue ID", "issue summary", "repo", "commit ID",
                  "fix status (including commit ID if fixed)"]
        if a.ledger_csv:
            with open(a.ledger_csv, encoding="utf-8", newline="") as fh:
                header = next(csv.reader(fh), None)
            if not header:
                raise Refusal("ledger %s has no header row" % a.ledger_csv)
        rows = ledger_rows(header, a.id, a.repo_name or repo_name_of(a.repo), head,
                           [x for x in labels if x[0] in ("R", "A")])
        clone = build_clone(a.repo, a.clone, base, head) if a.clone else None
    except UnicodeError as exc:
        print("canon-instance: refused: input is not UTF-8 (%s)" % exc.reason, file=sys.stderr)
        return 1
    except (Refusal, OSError, csv.Error) as exc:
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
        print(",".join(header))
    sys.stdout.write(rows)
    if clone:
        under, older, inner = clone
        print("\nclone %s: ok, %d commit(s) under review, %d older docs/reviews/ file(s)"
              % (a.clone, under, older))
        for path in inner:
            print("clone note: %s names a commit inside the range" % path)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
