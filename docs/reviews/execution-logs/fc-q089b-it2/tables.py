import re
import sys

# For each GFM table: count cells per row. GFM splits on every unescaped `|`,
# including inside backtick code spans, so count raw unescaped pipes.
for p in sys.argv[1:]:
    lines = open(p).read().split("\n")
    i = 0
    while i < len(lines):
        if lines[i].startswith("|") and i + 1 < len(lines) and re.match(r"^\|[\s:|-]+\|\s*$", lines[i + 1]):
            rows = []
            j = i
            while j < len(lines) and lines[j].startswith("|"):
                rows.append((j + 1, lines[j]))
                j += 1

            def cells(s):
                s2 = s.replace("\\|", "")
                return s2.strip().strip("|").count("|") + 1

            n0 = cells(rows[0][1])
            bad = [(ln, cells(r)) for ln, r in rows if cells(r) != n0]
            print(f"{p}:{i + 1} rows={len(rows)} cols={n0} mismatched={bad}")
            i = j
        else:
            i += 1
