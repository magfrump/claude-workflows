#!/usr/bin/env python3
"""code-fact-check: resolve every relative markdown link (+ #anchor) in the given files."""
import re, sys, os, unicodedata

def slug(h):
    h = h.strip().lower()
    h = re.sub(r"[`*_]", "", h)
    # GitHub: drop punctuation except hyphens and spaces; keep unicode letters/digits
    out = []
    for ch in h:
        cat = unicodedata.category(ch)
        if ch in " -":
            out.append(ch)
        elif cat[0] in "LN":
            out.append(ch)
    return "".join(out).replace(" ", "-")

def anchors(path):
    res, seen = set(), {}
    in_code = False
    for line in open(path, encoding="utf-8"):
        if line.lstrip().startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        m = re.match(r"^(#{1,6})\s+(.*?)\s*#*\s*$", line)
        if m:
            s = slug(m.group(2))
            n = seen.get(s, 0)
            res.add(s if n == 0 else f"{s}-{n}")
            seen[s] = n + 1
    return res

bad = 0
for f in sys.argv[1:]:
    txt = open(f, encoding="utf-8").read()
    for m in re.finditer(r"\]\(([^)\s]+)\)", txt):
        link = m.group(1)
        if re.match(r"^[a-z]+:", link):
            continue
        target, _, anc = link.partition("#")
        tpath = os.path.normpath(os.path.join(os.path.dirname(f), target)) if target else f
        if not os.path.exists(tpath):
            print(f"MISSING FILE  {f}: ({link})"); bad += 1; continue
        if anc and tpath.endswith(".md"):
            if anc not in anchors(tpath):
                print(f"MISSING ANCHOR {f}: ({link})"); bad += 1
print(f"broken={bad}")
