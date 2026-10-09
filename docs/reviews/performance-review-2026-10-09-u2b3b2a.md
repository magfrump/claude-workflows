Commit: 55490d15

# Performance Review: feat/build-loop-u2b3b2a (U2b3b2a, iteration 1)

**Scope:** `git diff main...HEAD` (55490d15): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2a-i1/shared.md`. The fact-check ran in parallel, so its verdicts were not available to this review.

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

Both walks (`imported_names`, `main_imports`) run once per gate decision. That is a **cold path**: one decision, seconds of budget, not per request. A walk forks one parser (`import_targets`: sed, maybe python3, awk) per file it reads. The diff adds three things:

1. **Second channel.** `put` now prints `//`+path for every resolved candidate below no root (`dev-cycle-read.sh:889`). `names()` emits every prefix of a token, so a token of length L now prints about L²/2 bytes where main printed none. These bytes are charged to IMPORT_OUT_MAX.
2. **Outside reads.** Each `//` line in the walk costs one `[[ -f && -r ]]` stat (`:1245`, `:1353`). Each regular readable one is queued and read through `outside_targets` (`:1115-1121`). That costs one `realpath -e` and one parser run (head, sed, awk, possibly python3), plus a second parser run in IMPORT_WHOLE mode when the real path differs.
3. **Dotnest table.** It is built once per reader set in bash, O(R²) over IMPORT_ROOTS (`:1076-1078`). Before, every parser process built it in awk.

Measurements were taken on this host on 2026-10-09 under the current shared load. Each walk ran once, with `timeout`, and no load generators were used. Probes are in `u2b3b2a-i1/performance/` (time.sh, probe.sh, bin.sh, memo.sh, dn.sh).

| Fixture (one start file) | main lib | branch lib |
|---|---|---|
| /workspace, real (7 worktrees) | main walk 1.31-1.40 s, tree 1.45-1.49 s (one 2.36 s outlier), 5,607 B | main walk 1.29-1.35 s, tree 1.43-1.54 s, 5,607 B, 0 `//` lines |
| `@/q` + 1000 x + `.md` | 0.013 s, 1 B | 0.146 s, 507,523 B, 1,004 `//` lines |
| `@/q` + 2900 x + `.md` | ok, 0.026 s | **walk fails** (rc 1), 0.08 s |
| `@~/` + 1000 x + `.md` | 0.016 s, 3 B | 0.14 s, 516,560 B |
| 2,000 lines `@/nonexistent/dirN/some/longer/path/fileN.md` | 0.16 s, 1 B | 1.0-1.06 s, 1,854,151 B, 50,904 `//` lines |
| same 2,000 lines, relative (no leading /) | main 3.52 s / tree 0.93 s, 1,752,343 B | main 3.45 s / tree 0.93 s, 1,752,343 B (unchanged) |
| `@/usr/bin/python3.md @/usr/bin/bash.md @/usr/lib/.../libc.so.6.md` | ok, 0.012 s | **both walks fail**, 1.0-1.9 s |
| chain of 20 outside files | 0.17-0.18 s | 0.21-0.23 s |

On the real repo the change costs nothing measurable. On a fixture, the new cost is parity with what relative names already paid (rows 5-6). The two new failure shapes are rows 3 and 7.

## Findings

#### F1. A token whose prefix names a large outside regular file (a binary, a log, ~/.claude.json) makes the walk read up to 4 MiB of it and fail closed

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1245`, `:1353` (queueing), `:1118` (the read)
**Move:** Ask "what's the size of N?" / hidden multiplication
**Classification:** Macro (quadratic prefix output over an unbounded foreign file) / Cold path (once per gate decision, but the gate blocks on it)
**Confidence:** High (executed)
**Baseline:** measured on 2026-10-09 (bin.sh, this host). `outside_targets /usr/bin/python3` took 1.026 s and returned rc=1, with awk exiting 3 after printing 97,197 lines. `/usr/bin/bash` took 0.391 s and `libc.so.6` took 0.604 s, both rc=1. A start file holding `@/usr/bin/python3.md @/usr/bin/bash.md @/usr/lib/x86_64-linux-gnu/libc.so.6.md` fails both walks (main 1.894 s, tree 1.022 s). On main's lib the same start file is ok in 0.012 s.

Evidence (verbatim):
```
      [[ "$p" != //* ]] || { p="${p#/}"; [[ -f "$p" && -r "$p" && "$seen" != *$'\n'"$p"$'\n'* ]] && seen+="$p"$'\n' && queue+=("$p"); continue; }
```
(excerpt from imported_names' read loop, which continues to `:1248`; main_imports' twin is at `:1353`, and both were read.) Every prefix of a candidate is tested with `-f`. So `@/usr/bin/python3.md` queues `/usr/bin/python3`, and `capped_read` (`:1162`, `head -c 4194305`) feeds 4 MiB of binary to the parser. Binary data holds `@` bytes followed by long runs with no blank. Every prefix of each run is then emitted, so work and output grow quadratically, IMPORT_WORK_MAX or IMPORT_LEFT is spent, and the walk returns 1. This is fail-closed, so it is not a false negative. It is an availability cliff that main did not have: main never read files outside the repo. In the repo today it does not bite (0 `//` lines). The exposure grows with U2b3b2b, whose outside seeds are user-authored files (~/.claude/CLAUDE.md, ancestors) that are more likely to name `~/.claude.json`, a history file or a binary path. Each such read also costs up to about 1 s before it fails.

**Recommendation:** Accept it as fail-closed, but say it where readers look: the walk header at `:720-724` should state that a `//` name whose file is large or binary can spend the budgets and fail the walk. Optionally, follow a `//` name only when the whole candidate the session would import is that file. Do not follow prefixes the way the repo arm does. Whether that keeps the superset is a correctness question for the fact-check/security critics, not this review.
**Legibility-target:** the walk header comment above `IMPORTED=error` (`:720-728`) and the IMPORT_OUT_MAX / IMPORT_WORK_MAX comments (`:733-757`).

#### F2. A single absolute or ~/ token over about 2,830 characters now fails both walks (output quadratic in token length, now charged)

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:889`
**Move:** Check the asymptotic behavior / work moved to the wrong place
**Classification:** Macro (O(L²) output per token) / Cold path
**Confidence:** High (executed)
**Baseline:** measured on 2026-10-09 (probe.sh). A 1,000-character absolute token printed 507,523 B and took 0.146 s (main's lib: 1 B, 0.013 s). A 2,900-character absolute token gives rc=1 on both walks on the branch and is ok on main's lib.

Evidence (verbatim):
```
  # Below no root: the second channel, / and the absolute path (so // leads
  # it, and no repo name or work trailer can be read as one: U2b3a i1 architecture F5).
  if (nho == 0) show("/" out)
```
(excerpt ends `:889`; enclosing `put()` ends at `:890`, read.) Every prefix `names()` emits is resolved and, below no root, shown. Total bytes are Σ(prefix length) ≈ L²/2, against IMPORT_OUT_MAX = 4,000,000. That reaches the limit at L ≈ 2,830, and earlier for a `~/` token when IMPORT_READER_HOMES adds a second home spelling, since each spelling prints its own prefixes. Repo-relative names already had this shape: the 2,000-line relative fixture prints 1,752,343 B on both libs, so this is parity rather than a new complexity class. The new part is that absolute and ~/ names, which main dropped for free, now spend the walk-wide budget too. A file can therefore fail a walk with absolute paths, which before only relative ones could do.

**Recommendation:** None required for correctness. Add the second channel to the IMPORT_OUT_MAX comment's sizing note ("A fresh clone's walks print about 2 KB, /workspace's about 6 KB") so a later reader knows absolute names now count. If it ever matters, a `//` line whose path has a non-directory, non-file ancestor could stop that token's prefixes early.
**Legibility-target:** IMPORT_OUT_MAX comment (`:733-737`).

#### F3. A symlinked outside file is parsed twice (under its link path and under its real path)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1115-1121`
**Move:** Count the hidden multiplications
**Classification:** Micro (one extra parse per symlinked outside file) / Cold path
**Confidence:** Medium. The double read is traced from code. The fork counts below are measured, but the double parse itself was not isolated.
**Baseline:** measured on 2026-10-09 (memo.sh). A chain of 11 outside files plus one symlink to the last made 14 `realpath` forks and 1 `git worktree list` per walk. The 20-file chain cost about 0.04 s more than main's lib (0.21 vs 0.17 s), so about 2 ms per outside file.

Evidence (verbatim):
```
  r="$(realpath -e -- "$1")" || return 1
  a="$(capped_read < "$1" | import_targets "${d:-/}")" && import_work a w || return 1
  if [[ "$r" != "$1" ]]; then b="$(printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /)" && import_work b w || return 1; fi
```
When the real path is itself outside every root, the IMPORT_WHOLE pass prints `//$r`. The walk then queues `$r` as a new entry, because `seen` is keyed on the spelled path, and it reads and parses the same content again against the real directory. This may be intended for resolving relative names against both directories. Its cost is double for every outside symlink, for example a stow-managed `~/.claude/CLAUDE.md`. The IMPORT_WHOLE pass also forks sed (with `-e ''`) and the UTF-8 awk gate for a one-line name.

**Recommendation:** None needed now. If U2b3b2b's seeds make symlinked dotfiles common, state the double read in outside_targets' header so it is a known cost.
**Legibility-target:** `outside_targets` header (`:1109-1114`).

#### F4. An outside file is opened after a separate test; a FIFO swapped in, or a hung mount, would stall the walk without bound

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1245`, `:1353` (test), `:1118` (open)
**Move:** Find the contention point / resource lifecycle
**Classification:** Macro (unbounded wait) / Cold path that blocks the gate
**Confidence:** Low (not executed: it needs a racing process or a hung mount, and I ran no such probe)
**Baseline:** no baseline available — flagged as speculative

Evidence (verbatim):
```
  a="$(capped_read < "$1" | import_targets "${d:-/}")" && import_work a w || return 1
```
The `-f`/`-r` test runs when the name is queued, and the open runs later, when it is popped. A path replaced by a FIFO in between makes `< "$1"` block on open with no writer. A regular file on a stalled network or 9p mount (on WSL2 that includes `/mnt/c`, and `@/mnt/c/...` prefixes are plausible in a WSL user's memory file) blocks `head`. The work bound charges neither wait, so the gate hangs instead of failing closed. Inside the repo the same gap existed, but the files were under the repo's own control. Outside it, anything on the host can trigger it.

**Recommendation:** Hand the race half to the security critic. On the performance side, consider bounding the outside read in time (for example coreutils `timeout` around `head`, failing the walk when it fires), and state the gap in the walk header's "Not covered" list.
**Legibility-target:** the walk header (`:720-728`).

#### F5. The bash dotnest table is O(R²) per reader set, which is fine at today's sizes

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1076-1078`
**Move:** Check the asymptotic behavior
**Classification:** Macro (O(R²)) / Cold path (once per reader set, memoized)
**Confidence:** High (executed on synthetic arrays)
**Baseline:** measured on 2026-10-09 (dn.sh, synthetic `rs_ro`). R=50: 0.010 s. R=98: 0.038 s. R=200: 0.169 s. R=570 (where IMPORT_WORK_MAX already fails the honest walks): 1.452 s.

Evidence (verbatim):
```
  for i in "${!rs_ro[@]}"; do for n in "${!rs_ro[@]}"; do
    p="${rs_ro[i]}/"; t="${rs_ro[n]}/"; [[ ${#t} -le ${#p} || "$t" != "$p"* || "/${t#"$p"}" != *"/."* ]] || IMPORT_DOTNEST+="$((i + 1)) $((n + 1))"$'\n'
  done; done
```
This is a net win over main, where every parser process redid the R² test in awk. Before the walk fails on work anyway, it costs at most about 1.5 s. `p` could be hoisted out of the inner loop, but the gain is a small constant.

**Recommendation:** None.
**Legibility-target:** none needed (the comment at `:1074-1075` states it is built once).

## Endorsements (evidence-gated)

- Within a walk, `import_targets`' new `import_readers` call is a memo hit in the `$(...)` subshells: one `git worktree list` per walk of each kind over a 12-file outside chain (memo.sh, 2026-10-09). This is measured for this fixture, not proven for every caller. `[unverified — submitted as claim]`
- On /workspace (7 registered worktrees), the branch's walks match main's in time (main walk 1.29-1.35 s vs 1.31-1.40 s; tree 1.43-1.54 s vs 1.45-1.49 s) and in output (5,607 B, 0 `//` lines), measured under the current load. This is consistent with the commit's "about the same time". The absolute 0.7-0.8 s figure was not reproduced under today's load. `[unverified — submitted as claim]`
- Moving the dotnest test out of the per-file awk BEGIN into `import_readers` removes an O(R²) step from every parser process. `[read: scripts/lib/dev-cycle-read.sh:947-953, :1074-1078]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Prefix naming a large or binary outside file is read (4 MiB) and fails the walk | Low | `dev-cycle-read.sh:1245,1353,1118` | High |
| 2 | Absolute/~ token over about 2,830 chars now fails the walks (L²/2 output now charged) | Low | `dev-cycle-read.sh:889` | High |
| 4 | Test-then-open on outside files: a FIFO swap or hung mount stalls the walk unbounded | Low | `dev-cycle-read.sh:1118,1245,1353` | Low |
| 3 | Symlinked outside file parsed twice (link path and real path) | Informational | `dev-cycle-read.sh:1115-1121` | Medium |
| 5 | Bash dotnest table O(R²), 0.04 s at 98 roots | Informational | `dev-cycle-read.sh:1076-1078` | High |

## Overall Assessment

On the real repository this change is performance-neutral: the same time and the same 5,607 B, because nothing in /workspace names an outside path. The dotnest hoist is a small structural win. The new costs all come from content outside the repo's control. Absolute and ~/ tokens now pay the same quadratic prefix volume as relative names, and a prefix that happens to be a large regular file is read and parsed. Both end in fail-closed refusals, not false negatives, so they are availability cliffs (F1, F2) rather than defects. F4 is the one shape that could hang the gate instead of refusing. None of these blocks this unit. They matter more for U2b3b2b, whose outside seeds feed user-authored text into exactly these paths. The cheapest fix is to name F1/F2/F4 in the walk header and the budget comments now, and to decide in U2b3b2b whether `//` prefixes need to be followed at all.

## Goal-Alignment Note

The user's goal is to land U2b3b2a through its review-fix loop. This review checked the unit's stated performance posture: walks once per decision, budgets bounding both walks, the memo hitting inside the parser subshells, and the dotnest table built once. That posture holds on the real repository. The findings are all Low or Informational and fixable with comments. Nothing here argues for changing the unit's design before merge. F1 and F4 should be carried to the security critic and to U2b3b2b's brief, because the outside seeds raise how often these shapes appear.
