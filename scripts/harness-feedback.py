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
  harness-feedback.py rename STORED NAME
                                      claude-workflows only: move a stored copy
                                      to docs/working/feedback/NAME.md, set its
                                      Project line and rekey its seeds
  harness-feedback.py pending FILE CW SRC [STORED...]
                                      read-only, for board.sh: one line on what
                                      of FILE the STORED copies lack

FILE defaults to docs/harness-feedback.md in the git toplevel of the current
directory ($PWD outside a repository). ingest and rename write into the toplevel of the
current directory, never through a symbolic link or outside that toplevel.
Exit: 0 ok, 1 refused (problems listed), 2 usage or an unreadable file;
pending exits 3 when a file cannot be read or compared.
"""

import datetime
import os
import re
import shlex
import subprocess
import sys
import unicodedata

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
# A line meant as an entry heading but mistyped (## or ####, f-, extra blanks)
# must not pass as preamble text, or its entry silently disappears.
HEADING_LIKE_RE = re.compile(r"^#+[ \t]*[Ff]-[0-9]")
BULLET_RE = re.compile(r"^- \*\*(" + "|".join(BULLETS) + r"):\*\*(.*)$")
# Control (Cc), format (Cf: bidi overrides, zero-width marks) and line or
# paragraph separators (Zl, Zp): a reader that splits on more than LF, or a
# display that reorders text, would see a different file than check does.
BAD_CATEGORIES = ("Cc", "Cf", "Zl", "Zp")


def bad_char(line):
    for ch in line:
        if ch != "\t" and unicodedata.category(ch) in BAD_CATEGORIES:
            return "U+%04X" % ord(ch)
    return None


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
        elif bad_char(line):
            problems.append(f"{where}: control or format character {bad_char(line)}")
        if "<!--" in line:
            problems.append(f"{where}: '<!--' is not allowed")
        if cur is None and not HEADING_LIKE_RE.match(line):
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
                problems.append(f"{where}: an entry heading must be '### F-NNN · slug' "
                                "(NNN 3+ digits, slug a-z 0-9 -), and after the first "
                                "entry every '#' line is one")
                # Skip this entry's lines, so its bullets are not blamed on the last one.
                cur = {"bad": True, "line": no}
                continue
            num = int(m.group(1))
            if num in seen:
                problems.append(f"{where}: F-{m.group(1)} repeats the ID on line {seen[num]}")
            seen[num] = no
            cur = {"line": no, "id": "F-" + m.group(1), "num": num,
                   "slug": m.group(2), "meta": None, "bullets": {}}
            entries.append(cur)
            continue
        if cur.get("bad"):
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


def write_file(path, text, append=False, exclusive=False):
    """Write without following a link at the final component."""
    flags = os.O_WRONLY | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0)
    flags |= os.O_APPEND if append else os.O_TRUNC
    if exclusive:
        flags |= os.O_EXCL
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


def project_name(top):
    """The origin remote's repository name, else the toplevel's basename.

    The remote comes first: a devcontainer mounts every project at /workspace
    and a worktree's directory name changes per run, and claude-workflows tells
    projects apart by this name alone.
    """
    base = os.path.basename(top)
    try:
        out = subprocess.run(["git", "-C", top, "config", "--get", "remote.origin.url"],
                             capture_output=True, text=True, check=False)
        url = out.stdout.strip().rstrip("/")
        if out.returncode == 0 and url:
            parts = [p for p in re.split(r"[/:]", url) if p and p != ".git"]
            last = parts[-1] if parts else ""
            if last.endswith(".git"):
                last = last[:-4]
            if last.strip(".-"):
                base = last
    except OSError:
        pass
    name = re.sub(r"[^A-Za-z0-9._-]", "-", base).lstrip(".-")[:64]
    return name or "project"


def cmd_init(args):
    top = toplevel()
    path = os.path.abspath(default_path(args))
    if os.path.lexists(path):
        print(f"exists {path}")
        return 0
    assert_inside(top, os.path.dirname(path))
    if not args:
        make_dirs(top, "docs")
    assert_inside(top, path)
    name = project_name(top)
    write_file(path, "# Harness feedback\n\n"
               "Entries on how claude-workflows features work or fail in this project.\n"
               "Grammar: ~/.claude/guides/harness-feedback.md.\n\n"
               f"Project: {name}\n", exclusive=True)
    print(f"created {path}")
    return 0


def sig(e):
    """What identifies an entry across copies: ID, slug and meta line."""
    return (e["id"], e["slug"], e["meta"])


def stored_match(project, entries, texts, stored):
    """Find a project's stored copy. STORED is a list of (name, project,
    entries, texts). Return (match, other): match holds this Project; other,
    when none does, holds these entries under another Project (a rename): its
    signatures lead this file's and its first entry's text is this one's, so
    two projects that filed the same F-001 heading are not taken for one.
    Raise ValueError when two stored copies hold one Project."""
    by_project = {}
    for s in stored:
        if s[1] in by_project:
            raise ValueError(f"{by_project[s[1]][0]} and {s[0]} both hold Project {s[1]}")
        by_project[s[1]] = s
    match = by_project.get(project)
    other = None
    if match is None and entries:
        other = next((s for s in stored if s[2] and s[3][0] == texts[0]
                      and [sig(e) for e in s[2]] == [sig(e) for e in entries[:len(s[2])]]),
                     None)
    return match, other


def seed_re(rel_copy):
    """A seed's signal for the stored copy rel_copy: group 1 the Project name it
    was seeded under, group 2 the entry ID. seed_line neutralises "(signal:" in
    entry text, so only the signal itself matches."""
    return re.compile(r"\(signal: harness feedback ([A-Za-z0-9._-]+) (F-[0-9]+), "
                      + re.escape(rel_copy) + r"\)")


def rename_cmd(rel_copy, project):
    return f"scripts/harness-feedback.py rename {shlex.quote(rel_copy)} {shlex.quote(project)}"


def read_stored(top, skip):
    """Every docs/working/feedback/*.md but skip, as (rel, project, entries,
    texts).
    One that cannot be read raises Usage; one that fails check returns its
    first problem as a str. ingest refuses either way, as pending does."""
    feedback_dir = os.path.join(top, FEEDBACK_DIR)
    if not os.path.isdir(feedback_dir) or os.path.islink(feedback_dir):
        return []
    out = []
    for fname in sorted(os.listdir(feedback_dir)):
        path = os.path.join(feedback_dir, fname)
        # A link is never skipped: read_text refuses it, as pending does.
        if not fname.endswith(".md") or (not os.path.islink(path)
                                         and os.path.realpath(path) == skip):
            continue
        rel = os.path.join(FEEDBACK_DIR, fname)
        text = read_text(path)
        project, entries, problems = parse(text)
        if problems:
            return f"the stored copy {rel}: {problems[0]}"
        out.append((rel, project, entries, entry_texts(text, entries)))
    return out


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
    if not os.path.isfile(os.path.join(top, "guides", "harness-feedback.md")):
        raise Usage(f"{top}: not a claude-workflows checkout "
                    "(no guides/harness-feedback.md); ingest runs there only")
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
    why = ingest_refusal(top, project, entries, entry_texts(text, entries),
                         src_real, rel_copy)
    log_text = read_text(log) if os.path.lexists(log) else None
    if why is None and log_text is not None:
        # Seeds of this copy under another Project name: the Project line was
        # renamed, and the skip test below, keyed on the name, would seed again.
        olds = sorted({m.group(1) for m in seed_re(rel_copy).finditer(log_text)} - {project})
        if olds:
            why = (f"{IDEA_LOG} seeds {rel_copy} under Project {', '.join(olds)}, not "
                   f"{project}, so ingest would seed its entries twice; if the project "
                   f"was renamed, run {rename_cmd(rel_copy, project)}, else restore its "
                   "Project line")
    if why is not None:
        print(f"refused: {why}; nothing written", file=sys.stderr)
        return 1
    if log_text is not None and not log_text.strip():
        log_text = None
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


def ingest_refusal(top, project, entries, texts, src_real, rel_copy):
    """Why ingest must not copy or seed this file, or None. stored_match makes
    the same comparison for pending, so the board withholds its command here."""
    stored = read_stored(top, src_real)
    if isinstance(stored, str):
        return stored
    try:
        match, other = stored_match(project, entries, texts, stored)
    except ValueError as exc:
        return str(exc)
    if match is not None and match[0] != rel_copy:
        return (f"its stored copy is {match[0]}, not {rel_copy}, so ingest would "
                f"store it twice; run {rename_cmd(match[0], project)}")
    if other is not None:
        return (f"its entries are stored under Project {other[1]} ({other[0]}), so "
                "ingest would store and seed them twice; if the project was renamed, "
                f"run {rename_cmd(other[0], project)}")
    held = next((c for c in stored if c[0] == rel_copy), None)
    if held is not None and held[1] != project:
        # Compare the name first: an empty entry list is a prefix of any list.
        return (f"{rel_copy} holds Project {held[1]}, not {project} (another "
                "project under this file name)")
    if match is not None and [sig(e) for e in match[2]] != \
            [sig(e) for e in entries[:len(match[2])]]:
        # The project's file only grows: a copy whose entries do not extend the
        # stored one is another project under the same name, or a lost history.
        return (f"{rel_copy} holds entries this file does not start with "
                "(another project with the same Project name, or entries removed)")
    return None


def cmd_rename(args):
    """Move a stored copy to NAME.md, set its Project line, rekey its seeds."""
    if len(args) != 2:
        raise Usage("rename takes STORED NAME")
    src, name = args
    if not PROJECT_RE.match(f"Project: {name}"):
        raise Usage(f"{name}: not a Project name (1-64 of A-Z a-z 0-9 . _ -, "
                    "not starting with . or -)")
    top = toplevel()
    if not os.path.isfile(os.path.join(top, "guides", "harness-feedback.md")):
        raise Usage(f"{top}: not a claude-workflows checkout "
                    "(no guides/harness-feedback.md); rename runs there only")
    feedback_dir = os.path.join(top, FEEDBACK_DIR)
    src_abs = os.path.abspath(src)
    if os.path.realpath(os.path.dirname(src_abs)) != feedback_dir \
            or not src_abs.endswith(".md"):
        raise Usage(f"{src}: not a stored copy (a .md file in {FEEDBACK_DIR})")
    src_abs = os.path.join(feedback_dir, os.path.basename(src_abs))
    dest = os.path.join(feedback_dir, name + ".md")
    log = os.path.join(top, IDEA_LOG)
    # Check every target before the first write, so a refusal writes nothing.
    for target in (src_abs, dest, log):
        assert_inside(top, target)
    got = load(src_abs)
    if got is None:
        print("refused: nothing written", file=sys.stderr)
        return 1
    old_project, entries, text = got
    rel_old, rel_new = os.path.relpath(src_abs, top), os.path.relpath(dest, top)
    stored = read_stored(top, os.path.realpath(src_abs))
    if isinstance(stored, str):
        why = stored
    elif dest != src_abs and os.path.lexists(dest):
        why = f"{rel_new} exists"
    else:
        why = next((f"{c[0]} holds Project {name}" for c in stored if c[1] == name), None)
    if why is not None:
        print(f"refused: {why}; nothing written", file=sys.stderr)
        return 1
    lines = text.split("\n")
    first = entries[0]["line"] - 1 if entries else len(lines)
    lines[:first] = [f"Project: {name}" if PROJECT_RE.match(ln) else ln
                     for ln in lines[:first]]
    log_text = read_text(log) if os.path.lexists(log) else ""
    new_log, n = seed_re(rel_old).subn(
        lambda m: f"(signal: harness feedback {name} {m.group(2)}, {rel_new})", log_text)
    write_file(dest, "\n".join(lines), exclusive=dest != src_abs)
    if n:
        try:
            write_file(log, new_log)
        except OSError:
            # Undo the new copy, so a failed rename leaves the old state whole.
            if dest != src_abs:
                os.unlink(dest)
            else:
                write_file(dest, text)
            raise
    if dest != src_abs:
        os.unlink(src_abs)
    print(f"renamed {rel_old} (Project {old_project}) to {rel_new} (Project {name}): "
          f"{n} seeds rekeyed; commit the copy and {IDEA_LOG} together")
    return 0


def entry_texts(text, entries):
    """Each entry's lines, heading to the line before the next heading."""
    lines = text.split("\n")
    ends = [e["line"] - 1 for e in entries[1:]] + [len(lines)]
    return ["\n".join(lines[e["line"] - 1:end]).rstrip()
            for e, end in zip(entries, ends)]


def span(es):
    ids = [e["id"] for e in es]
    return ids[0] if len(ids) == 1 else f"{ids[0]} to {ids[-1]}"


def cmd_pending(args):
    """Read-only, for board.sh: one line on what of FILE the STORED copies lack.
    CW and SRC only shape the printed ingest command; runs no git. Exit 3 when a
    file cannot be read or compared (1 stays an uncaught error's)."""
    if len(args) < 3:
        raise Usage("pending takes FILE CW SRC [STORED...]")
    (src, cw, shown), stored = args[:3], args[3:]

    def parsed(path, name):
        try:
            text = read_text(path)
        except Usage as exc:
            return None, str(exc).replace(path, name, 1)
        project, entries, problems = parse(text)
        if problems:
            return None, f"{name}: {problems[0]}"
        return (project, entries, entry_texts(text, entries)), None

    got, why = parsed(src, DEFAULT_REL)
    if got is None:
        print(f"feedback UNREADABLE: {why}")
        return 3
    project, entries, texts = got
    copies = []
    for path in stored:
        name = os.path.join(FEEDBACK_DIR, os.path.basename(path))
        c, why = parsed(path, name)
        if c is None:
            print(f"feedback NOT COMPARED: the stored copy {why}")
            return 3
        copies.append((name,) + c)
    own = os.path.join(FEEDBACK_DIR, project + ".md")
    names = {c[0]: c[1] for c in copies}
    try:
        match, other = stored_match(project, entries, texts, copies)
    except ValueError as exc:
        print(f"feedback NOT COMPARED: {exc}")
        return 3
    if other is not None:
        print(f"feedback: {len(entries)} entries, stored under Project {other[1]} "
              f"({other[0]}); renamed? No command: ingest refuses until it is renamed")
        return 0
    stored_entries, stored_texts = match[2:] if match else ([], [])
    n = len(stored_entries)
    if [sig(e) for e in stored_entries] != [sig(e) for e in entries[:n]]:
        bad = next(i for i, e in enumerate(stored_entries)
                   if i >= len(entries) or sig(e) != sig(entries[i]))
        print(f"feedback: {stored_entries[bad]['id']} differs from the stored copy "
              f"{match[0]}; no command: ingest would refuse it")
        return 0
    new = entries[n:]
    changed = [e for e, t, o in zip(entries, texts, stored_texts) if t != o]
    if not new and not changed:
        print(f"feedback: {len(entries)} entr{'y' if len(entries) == 1 else 'ies'}, all copied")
        return 0
    parts = ([f"{len(new)} not copied ({span(new)})"] if new else []) \
        + ([f"{len(changed)} changed ({span(changed)})"] if changed else [])
    line = "feedback: " + ", ".join(parts)
    if match is not None and match[0] != own:
        line += (f"; no command: its stored copy is {match[0]}, not {own}, "
                 "so ingest refuses until it is renamed")
    elif match is None and own in names:
        line += f"; no command: {own} holds Project {names[own]}"
    else:
        line += (f": cd {shlex.quote(cw)} && ~/.claude/scripts/harness-feedback.py "
                 f"ingest {shlex.quote(shown)}")
    print(line)
    return 0


COMMANDS = {"check": cmd_check, "next-id": cmd_next_id,
            "init": cmd_init, "ingest": cmd_ingest, "rename": cmd_rename,
            "pending": cmd_pending}


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
