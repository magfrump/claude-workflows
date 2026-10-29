#!/usr/bin/env python3
"""Check, start and ingest a project's harness-feedback file.

A project using these workflows keeps docs/harness-feedback.md, where its
sessions record how a harness feature worked or failed there. The entry
grammar is written once, in guides/harness-feedback.md; this script enforces
it and does not restate it beyond the code below.

Usage:
  harness-feedback.py check [FILE]    validate (exit 1, one line per problem)
  harness-feedback.py next-id [FILE]  print the next free F-NNN
  harness-feedback.py init [FILE]     create the file with its preamble if absent
  harness-feedback.py ingest FILE     claude-workflows only: copy FILE to
                                      docs/working/feedback/PROJECT.md and append
                                      one idea-log seed per entry not yet seeded

FILE defaults to docs/harness-feedback.md in the git toplevel of the current
directory ($PWD outside a repository). ingest writes into the toplevel of the
current directory, never through a symbolic link or outside that toplevel.
Exit: 0 ok, 1 refused (problems listed), 2 usage or an unreadable file.
"""

import datetime
import os
import re
import subprocess
import sys

MAX_BYTES = 1_000_000
VERDICTS = ("fails", "friction", "works")
BULLETS = ("Context", "Expected", "Observed", "Evidence")
DEFAULT_REL = os.path.join("docs", "harness-feedback.md")
FEEDBACK_DIR = os.path.join("docs", "working", "feedback")
IDEA_LOG = os.path.join("docs", "working", "idea-log.md")

PROJECT_RE = re.compile(r"^Project: ([A-Za-z0-9_][A-Za-z0-9._-]{0,63})$")
HEADING_RE = re.compile(r"^### F-([0-9]{3,}) · ([a-z0-9][a-z0-9-]*)$")
META_RE = re.compile(
    r"^\*\*Feature:\*\* ([^·]*\S[^·]*) · \*\*Date:\*\* ([0-9]{4}-[0-9]{2}-[0-9]{2})"
    r" · \*\*Verdict:\*\* (\S+)$")
BULLET_RE = re.compile(r"^- \*\*(" + "|".join(BULLETS) + r"):\*\*(.*)$")
CONTROL_RE = re.compile(r"[\x00-\x08\x0b-\x1f\x7f]")


class Usage(Exception):
    """A usage error or a file that cannot be read: exit 2."""


def toplevel():
    """The git toplevel of $PWD, or $PWD outside a repository."""
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, check=False)
    except OSError:
        out = None
    if out is not None and out.returncode == 0 and out.stdout.strip():
        return os.path.realpath(out.stdout.strip())
    return os.path.realpath(os.getcwd())


def read_text(path):
    """Read a regular file as UTF-8 text, or raise Usage naming why not."""
    if not os.path.lexists(path):
        raise Usage(f"{path}: no such file (init creates it)")
    if os.path.islink(path) or not os.path.isfile(path):
        raise Usage(f"{path}: not a regular file (a symbolic link is refused)")
    with open(path, "rb") as fh:
        data = fh.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise Usage(f"{path}: larger than {MAX_BYTES} bytes")
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise Usage(f"{path}: not UTF-8 (byte {exc.start})") from None


def parse(text):
    """Return (project, entries, problems). Each entry is a dict."""
    problems = []
    lines = text.split("\n")
    if text.endswith("\n"):
        lines.pop()
    projects = []
    entries = []
    cur = None
    seen = {}
    for no, line in enumerate(lines, 1):
        where = f"line {no}"
        if "\r" in line:
            problems.append(f"{where}: CR byte (use LF line endings)")
        elif CONTROL_RE.search(line):
            problems.append(f"{where}: control character")
        if "<!--" in line:
            problems.append(f"{where}: '<!--' is not allowed")
        if cur is None and not line.startswith("### F-") and not line.startswith("### f-"):
            if line.startswith("Project:"):
                m = PROJECT_RE.match(line)
                if m:
                    projects.append((no, m.group(1)))
                else:
                    problems.append(f"{where}: Project line must be 'Project: NAME' "
                                    "(1-64 of A-Z a-z 0-9 . _ -, not starting with . or -)")
            continue
        if line.startswith("#"):
            m = HEADING_RE.match(line)
            if not m:
                problems.append(f"{where}: heading after the first entry must be "
                                "'### F-NNN · slug' (NNN 3+ digits, slug a-z 0-9 -)")
                continue
            num = int(m.group(1))
            if num in seen:
                problems.append(f"{where}: F-{m.group(1)} repeats the ID on line {seen[num]}")
            seen[num] = no
            cur = {"line": no, "id": "F-" + m.group(1), "num": num,
                   "slug": m.group(2), "meta": None, "bullets": {}}
            entries.append(cur)
            continue
        if no == cur["line"] + 1:
            cur["meta_line"] = True
            m = META_RE.match(line)
            if not m:
                problems.append(f"{where}: {cur['id']} needs the meta line "
                                "'**Feature:** NAME · **Date:** YYYY-MM-DD · "
                                "**Verdict:** fails|friction|works' right after its heading")
                continue
            feature, date, verdict = m.group(1).strip(), m.group(2), m.group(3)
            try:
                datetime.date.fromisoformat(date)
            except ValueError:
                problems.append(f"{where}: {cur['id']} date {date} is not a calendar date")
            if verdict not in VERDICTS:
                problems.append(f"{where}: {cur['id']} verdict '{verdict}' is not one of "
                                + ", ".join(VERDICTS))
            cur["meta"] = (feature, date, verdict)
            continue
        m = BULLET_RE.match(line)
        if m:
            key, value = m.group(1), m.group(2)
            if key in cur["bullets"]:
                problems.append(f"{where}: {cur['id']} repeats **{key}:**")
            elif not value.startswith(" ") or not value.strip():
                problems.append(f"{where}: {cur['id']} **{key}:** needs text after it")
            cur["bullets"].setdefault(key, value.strip())
    if not projects:
        problems.insert(0, "preamble: no 'Project: NAME' line before the first entry")
    elif len(projects) > 1:
        problems.insert(0, f"line {projects[1][0]}: second Project line "
                        f"(first on line {projects[0][0]})")
    for e in entries:
        if "meta_line" not in e:
            problems.append(f"line {e['line']}: {e['id']} has no meta line")
        missing = [k for k in BULLETS if k not in e["bullets"]]
        if missing:
            problems.append(f"line {e['line']}: {e['id']} is missing "
                            + ", ".join(f"**{k}:**" for k in missing))
    project = projects[0][1] if len(projects) == 1 else None
    return project, entries, problems


def load(path):
    """Parse a file; print problems and return None when it does not pass,
    else (project, entries, text)."""
    text = read_text(path)
    project, entries, problems = parse(text)
    if problems:
        for p in problems:
            print(f"{path}: {p}")
        return None
    return project, entries, text


def default_path(args):
    if len(args) > 1:
        raise Usage("too many arguments")
    return args[0] if args else os.path.join(toplevel(), DEFAULT_REL)


def cmd_check(args):
    path = default_path(args)
    got = load(path)
    if got is None:
        return 1
    print(f"ok {path}: project {got[0]}, {len(got[1])} entries")
    return 0


def cmd_next_id(args):
    got = load(default_path(args))
    if got is None:
        return 1
    print("F-%03d" % (max((e["num"] for e in got[1]), default=0) + 1))
    return 0


def assert_inside(top, path):
    """Refuse a write target that is a link, or whose real path leaves top."""
    rel = os.path.relpath(path, top)
    if rel.startswith(".."):
        raise Usage(f"{path}: outside {top}")
    cur = top
    for part in rel.split(os.sep):
        cur = os.path.join(cur, part)
        if os.path.islink(cur):
            raise Usage(f"{cur}: a symbolic link; refusing to write through it")
    real = os.path.realpath(path)
    if real != top and not real.startswith(top + os.sep):
        raise Usage(f"{path}: resolves outside {top}")


def write_file(path, text, append=False):
    """Write without following a link at the final component."""
    flags = os.O_WRONLY | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0)
    flags |= os.O_APPEND if append else os.O_TRUNC
    fd = os.open(path, flags, 0o644)
    with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)


def make_dirs(top, rel_dir):
    cur = top
    for part in rel_dir.split(os.sep):
        cur = os.path.join(cur, part)
        if os.path.islink(cur):
            raise Usage(f"{cur}: a symbolic link; refusing to write through it")
        if not os.path.isdir(cur):
            os.mkdir(cur)


def cmd_init(args):
    top = toplevel()
    path = default_path(args)
    if os.path.lexists(path):
        print(f"exists {path}")
        return 0
    if not args:
        make_dirs(top, "docs")
    path = os.path.abspath(path)
    if path == top or path.startswith(top + os.sep):
        assert_inside(top, path)
    name = re.sub(r"[^A-Za-z0-9._-]", "-", os.path.basename(top)).lstrip(".-")[:64]
    name = name or "project"
    write_file(path, "# Harness feedback\n\n"
               "Entries on how claude-workflows features work or fail in this project.\n"
               "Grammar: ~/.claude/guides/harness-feedback.md.\n\n"
               f"Project: {name}\n")
    print(f"created {path}")
    return 0


def seed_line(project, rel_copy, e):
    feature, _date, verdict = e["meta"]
    observed = e["bullets"]["Observed"]
    if len(observed) > 200:
        observed = observed[:197] + "..."
    observed = observed.replace("(signal:", "(signal -")
    feature = feature.replace("(signal:", "(signal -")
    return (f"- harness feedback, {feature} ({verdict}): {e['slug']}: {observed} "
            f"(signal: harness feedback {project} {e['id']}, {rel_copy})\n")


def cmd_ingest(args):
    if len(args) != 1:
        raise Usage("ingest takes exactly one FILE")
    src = args[0]
    got = load(src)
    if got is None:
        print("refused: nothing written", file=sys.stderr)
        return 1
    project, entries, text = got
    top = toplevel()
    feedback_dir = os.path.join(top, FEEDBACK_DIR)
    src_real = os.path.realpath(src)
    if os.path.dirname(src_real) == os.path.realpath(feedback_dir) \
            and not os.path.islink(feedback_dir):
        dest = src_real
    else:
        dest = os.path.join(feedback_dir, project + ".md")
    log = os.path.join(top, IDEA_LOG)
    # Check every target before the first write, so a refusal writes nothing.
    for target in (dest, log):
        assert_inside(top, target)
    rel_copy = os.path.relpath(dest, top)
    log_text = read_text(log) if os.path.lexists(log) else None
    make_dirs(top, FEEDBACK_DIR)
    if dest != src_real:
        write_file(dest, text)
    new = [seed_line(project, rel_copy, e) for e in entries
           if log_text is None
           or f"(signal: harness feedback {project} {e['id']}," not in log_text]
    if new:
        prefix = ""
        if log_text is None:
            prefix = "# Idea log\n\n"
        elif not log_text.endswith("\n"):
            prefix = "\n"
        write_file(log, prefix + "".join(new), append=log_text is not None)
    print(f"ingested {project}: {len(new)} new seeds, "
          f"{len(entries) - len(new)} already seeded; copy at {rel_copy}")
    return 0


COMMANDS = {"check": cmd_check, "next-id": cmd_next_id,
            "init": cmd_init, "ingest": cmd_ingest}


def main(argv):
    if len(argv) < 2 or argv[1] not in COMMANDS:
        usage = __doc__[__doc__.index("Usage:"):]
        print(usage.split("\n\n")[0], file=sys.stderr)
        return 2
    try:
        return COMMANDS[argv[1]](argv[2:])
    except Usage as exc:
        print(f"harness-feedback: {exc}", file=sys.stderr)
        return 2
    except OSError as exc:
        print(f"harness-feedback: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
