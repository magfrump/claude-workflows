Commit: c143b929

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1c (claude-workflows, branch feat/build-loop-u1c)
**Scope:** unit diff `feat/build-loop-u1b...feat/build-loop-u1c` at HEAD c143b929 (u1b tip 2e711a7b): comments, help text, test names and comments in scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats; commit messages of 859e29e8, aaae80c6, 553a50d5, c143b929. docs/reviews/ artifacts out of scope.
**Checked:** 2026-10-05
**Total claims checked:** 38 (Claims 1-36, with 16 and 36 split into a/b)
**Summary:** 32 verified, 5 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Execution provenance (shared by every `executed` claim below unless the claim names another log). All probes ran with `timeout`, no background processes, scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/fc-r2/` (abbreviated `$FC` below). Probe repos are built by `$FC/h.bash`, which sources `test/lib/build-loop-fixtures.bash` and calls `bl_setup` (so `LC_ALL=C`, hermetic git env), with `BATS_TEST_TMPDIR=$FC/p-<probe>`.

| Log | Command (cwd) | Exit | Time (UTC) |
|---|---|---|---|
| `$FC/logs/bats-read.log` | `LC_ALL=C.UTF-8 timeout 600 bats test/scripts/build-loop-read.bats` (worktree) | 0, 16/16 ok | 2026-10-05T16:46Z |
| `$FC/logs/c1.log` | `bash $FC/c1.sh` (`$FC`): 34 near-miss constraint shapes | 0 | 2026-10-05T16:47Z |
| `$FC/logs/c2.log` | `bash $FC/c2.sh` (`$FC`): fences, headings, success forms, dup, CRLF, BOM, NUL, H0 | 0 | 2026-10-05T16:48Z |
| `$FC/logs/m1.log` | `bash $FC/m1.sh` (`$FC`): 21 crafted tip objects via `git hash-object -t commit --literally -w` | 0 | 2026-10-05T16:48Z |
| `$FC/logs/m2.log` | `bash $FC/m2.sh` (`$FC`): `%s` vs `%B`, LC_ALL in {C, en_US.UTF-8, xx_YY.UTF-8, C.UTF-8} | 0 | 2026-10-05T16:49Z |
| `$FC/logs/m3.log` | `bash $FC/m3.sh` (`$FC`): old (553a50d5, `git archive`) vs new setlocale warnings; commit-tree verbatim; two-tree object; commit_all empty | 0 | 2026-10-05T16:50Z |
| `$FC/logs/s1.log` | `bash $FC/s1.sh` (`$FC`): working-tree plainness, shared-branch, Branch/Dispatched forms, exit codes, help | 0 | 2026-10-05T16:49Z |
| `$FC/logs/s2.log` | `bash $FC/s2.sh` (`$FC`): sha256 of every repo file + `for-each-ref` before/after `--status` and `--settings` | 0 | 2026-10-05T16:50Z |
| `$FC/logs/real-briefs.log` | `timeout 60 bash scripts/build-loop.sh --status docs/working/briefs/*.md` (worktree) | 0 | 2026-10-05T16:50Z |
| `$FC/logs/glog-timing.log` | per-brief `git log -1 ... -G'^Status: '` wall time (worktree) | 0 | 2026-10-05T16:51Z |

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern (the closest family, commit-message counts, was re-computed for 553a50d5 and c143b929 and holds).

---

## Claim 1: "Usage: scripts/build-loop.sh --status BRIEF..." / "--status needs at least one brief path"

**Location:** `scripts/build-loop.sh:7`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the --status mode's argument parsing (no arguments is a usage error, exit 1, stderr only); does not establish behaviour for an argument that itself looks like an option (it is treated as a path, per aaae80c6's note).

`scripts/build-loop.sh:95`: `--status) MODE=status; shift; ARGS=("$@"); [[ $# -gt 0 ]] || usage "--status needs at least one brief path" ;;` and `usage()` at `:91` exits 1. Probe: `--status` alone exited 1; `--status bogus/path <brief>` exited 0 with a skip line for the bogus path (`$FC/logs/s1.log`, "no-args 1", "skip-args 0"). The bats test at `test/scripts/build-loop-read.bats:195-199` asserts status 1, empty stdout, non-empty stderr for `--status`.

**Evidence:** `scripts/build-loop.sh:91-99`, `test/scripts/build-loop-read.bats:195-199`, `$FC/logs/s1.log`, `$FC/logs/bats-read.log`

---

## Claim 2: "--settings  four lines from the default branch's commit, never the working tree ... Lines 1-3 from one line of docs/dev-cycle.md"

**Location:** `scripts/build-loop.sh:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line count and order (policy, slots, never, constraints) and that the fourth line ignores a working-tree-only docs/constraints.md; does not re-verify lines 1-3's own grammar (U1b's text, outside this diff).

`scripts/build-loop.sh:355`: `printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE"`. The bats test "--settings prints its four lines in order..." (`test/scripts/build-loop-read.bats:190-194`) asserts 4 lines with prefixes policy/slots/never/constraints, and T44 (`:363-366`) writes `docs/constraints.md` only to the working tree and asserts `constraints missing: no docs/constraints.md on the default branch`. Both pass (`$FC/logs/bats-read.log`).

**Evidence:** `scripts/build-loop.sh:254-267`, `scripts/build-loop.sh:353-356`, `test/scripts/build-loop-read.bats:159-198`, `$FC/logs/bats-read.log`

---

## Claim 3: "constraints ok N-hard M-soft|missing|none-hard|unreadable: WHY ... docs/constraints.md"

**Location:** `scripts/build-loop.sh:29-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four line forms and which file inputs produce each (absent → missing; no hard → none-hard, including an empty file; a refused or non-regular file → unreadable); does not establish what any consumer does with them.

`scripts/build-loop.sh:256-265` produces exactly the four forms: `constraints missing: no $f on the default branch`, `constraints ok $c-hard $l1-soft: ...`, `constraints none-hard: ...`, and `constraints unreadable: ...` for every other path. Probes: an empty file gives `none-hard ... has 0 soft constraints`, a directory at the path gives `unreadable: docs/constraints.md is not a regular file on the default branch`, a BOM or NUL gives FENCE_AWK's unreadable reason (`$FC/logs/c2.log`).

**Evidence:** `scripts/build-loop.sh:254-267`, `$FC/logs/c2.log`, `$FC/logs/bats-read.log`

---

## Claim 4: "docs/constraints.md, which every loop prompt carries" / "Only "ok" lets the orchestrator dispatch."

**Location:** `scripts/build-loop.sh:30`, `scripts/build-loop.sh:37`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers only that both statements match the plan (`docs/working/plan-build-loop-handoff.md:44`, `:227`, `:260`); does not establish behaviour, since neither the loop prompt (U3) nor the dispatch step (U4) exists in this unit.

The plan says "Every loop prompt carries `docs/constraints.md` from main's commit" (`docs/working/plan-build-loop-handoff.md:44`) and "**Step 10, dispatch**: only when `--settings` prints `constraints ok`" (`docs/working/plan-build-loop-handoff.md:260`). No code in the worktree reads the constraints line yet (paraphrased — no quote available because the claim covers absence of code: a grep of scripts/ for `CONSTRAINTS_LINE` finds only build-loop.sh's own producer and printf). Needed to verify: U3's `--prompt` and U4's dispatch step. Override row 275 treats U3/U4 claims as checked in those units.

**Evidence:** `docs/working/plan-build-loop-handoff.md:44`, `docs/working/plan-build-loop-handoff.md:260`, `scripts/build-loop.sh:198`, `scripts/build-loop.sh:355`

---

## Claim 5: "A constraint is a line "H<n>: text" (hard) or "S<n>: text" (soft) at column 0, optionally after "- ", n without a leading 0"

**Location:** `scripts/build-loop.sh:30-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exact-line regex (column 0, one optional "- ", uppercase H/S, n from 1 with no leading 0, ": " then a non-blank) and CRLF tolerance; does not establish handling of lines inside a fence (see Claim 8) and n=0 ("H0:" is refused as a near miss, which "without a leading 0" does not literally state).

`scripts/build-loop.sh:164`: `/^(- )?[HS][123456789][0123456789]*: [^ \t]/ {`. Probes: `H1: a`/`S1: c` with CRLF endings count as `ok 1-hard 1-soft`; `H01: x`, `H0: z`, `H2:  x`, `H2:<TAB>x`, `  H2: x`, `h2: x`, `H2:` and `H2: ` all give the near-miss unreadable line (`$FC/logs/c1.log`, `$FC/logs/c2.log`).

**Evidence:** `scripts/build-loop.sh:161-171`, `$FC/logs/c1.log`, `$FC/logs/c2.log`

---

## Claim 6: "a hard one needs a "success: <observable>" line (any indent, optionally after "- ") before the next constraint or heading" (also `:174` "a heading ends a pending one")

**Location:** `scripts/build-loop.sh:33-35`, `scripts/build-loop.sh:174`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the success-line regex and the next-constraint and `#`-line terminators; does not establish that every Markdown heading ends a pending constraint — it does not (setext and indented ATX headings do not), and a non-heading line starting `#` does.

`scripts/build-loop.sh:174-175`: `/^#/ { if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl; pend = ""; next }` and `/^[ \t]*(- )?success: [^ \t]/ { pend = "" }`. "Heading" is any line whose first byte is `#`. Probes (`$FC/logs/c2.log`): `- H1: a` / `Other` / `=====` / `success: b` (setext heading) → `constraints ok 1-hard 0-soft`; the same with `-----` → ok; `- H1: a` / `  ## Other` / `success: b` (ATX heading indented 2 spaces, still a heading in CommonMark) → ok; while `- H1: a` / `#tag` / `success: b` (not a heading) → `unreadable: hard constraint H1 (line 1) has no success: line`. "Any indent" holds for spaces and tabs (`<TAB>success: b` and `    - success: b` → ok); `* success: b` is not accepted (→ nosuccess). Precise version: "before the next constraint or the next line starting #".

**Evidence:** `scripts/build-loop.sh:172-175`, `$FC/logs/c2.log`

---

## Claim 7: "and no ID may repeat"

**Location:** `scripts/build-loop.sh:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers repeats of the same ID with and without the "- " prefix; does not establish anything about H<n>/S<n> sharing a number (they are distinct IDs and both count).

`scripts/build-loop.sh:165-167`: `id = $0; sub(/^- /, "", id); sub(/:.*/, "", id)` then `if (bad == "" && (id in seen)) bad = "dup " id " " seen[id] " " NR`. Probe `H1: a` ... `- H1: c` → `constraint H1 is listed twice (lines 1 and 3)`; `H1` with `S1` → `ok 1-hard 1-soft` (`$FC/logs/c2.log`).

**Evidence:** `scripts/build-loop.sh:164-171`, `$FC/logs/c2.log`

---

## Claim 8: "Any other line whose letters and digits, from its first letter, start like "h1" or "s1" makes the file unreadable." (also `:173` "looks like an ID but is not exact")

**Location:** `scripts/build-loop.sh:35-37`, `scripts/build-loop.sh:173`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every ASCII near-miss shape from iteration 1 and 20 more (all refused); does not hold for lines inside a code fence (skipped by FENCE_AWK before this rule) or for non-ASCII look-alike letters (not "letters" under LC_ALL=C), and in both cases a line a reader would take for a hard constraint vanishes while the line reads `constraints ok`.

`scripts/build-loop.sh:163`: `fence($0) { next }` runs before `:172-173`: `{ s = $0; sub(/^[^a-zA-Z]*/, "", s); s = tolower(s); gsub(/[^a-z0123456789]/, "", s) }` / `s ~ /^[hs][0123456789]/ { if (bad == "") bad = "near " NR; next }`, and `main_file` runs awk under `env LC_ALL=C` (`:128`), so "letter" means ASCII a-z/A-Z.

Refused, as stated (`$FC/logs/c1.log`): `* H2: x`, `1. H2: x`, `H2:  x`, `H2:<TAB>x`, `  H2: x`, `h2: x`, `**H2:** x`, `### H2: x`, `> H2: x`, `H10 : x`, `| H2: x |`, `H01: x`, `+ H2: x`, `-H2: x`, `- - H2: x`, `-  H2: x`, `H2 x`, `H-2: x`, `_H2_: x`, `H 2: x`, `H2. x`, `H2) x`, `<!-- H2: x -->`, `` `H2`: x ``, `\H2: x`, `S2:  x`. Line-order point from the brief: because `:173` runs before `:174`, `### H2: x` is a near miss (unreadable), not a heading.

Not refused, each with `- H1: a` / `  success: b` before it, output `constraints ok 1-hard 0-soft`:
- a fenced line: `` ``` `` / `H2: never drop prod` / `` ``` `` (also `~~~` fences) (`$FC/logs/c2.log`);
- Cyrillic `Н2: x` (U+041D) and fullwidth `Ｈ2: x` (U+FF28) (`$FC/logs/c1.log`).
(`Hard2: x`, `2H: x`, `H２: x` also read ok, and match the stated rule.) The help states FENCE_AWK only for lines 1-3 (`:12-13`); the plan reads the file "under FENCE_AWK" (`docs/working/plan-build-loop-handoff.md:204`). Under Q-112 [1] this is reportable only if a hard constraint can be silently dropped while the line reads ok: the fenced case does that for a fenced line, and the homoglyph case for a look-alike ID. Precise version: "Any other line outside a fence whose ASCII letters and digits ...".

**Evidence:** `scripts/build-loop.sh:128`, `scripts/build-loop.sh:161-183`, `$FC/logs/c1.log`, `$FC/logs/c2.log`

---

## Claim 9: "--status  one line per brief path, in argument order, from the default branch's commit (the path must also be plain in the working tree, as --check-brief)"

**Location:** `scripts/build-loop.sh:42-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the argument's own path (symlinked file or symlinked directory in the working tree → skip, via check_brief's `blocker`) and ordering; does not establish a working-tree check on the *other* briefs shared_branches reads (there is none, and the help does not claim one), and "plain" admits a path missing from the working tree.

`scripts/build-loop.sh:312`: `out="$(check_brief "$a")"`, and `scripts/lib/dev-cycle-read.sh:329`: `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi`. Probes (`$FC/logs/s1.log`): the brief replaced in the working tree by a symlink to an identical file → `skip ...: reached through a symlink, or not a regular file`; `docs/working/briefs` a symlinked directory → same skip; the brief deleted from the working tree → `ok ... open review feat/a absent - - 0`; a *sharing* brief that is a working-tree symlink still counts (`skip ...: another open brief ...`). So the lite drift claim that this is unenforced is refuted for the argument path. T28 asserts argument order over six mixed paths.

**Evidence:** `scripts/build-loop.sh:310-316`, `scripts/lib/dev-cycle-read.sh:321-347`, `$FC/logs/s1.log`, `$FC/logs/bats-read.log`

---

## Claim 10: "ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON] / STATE: open, done or dropped (dev-cycle.sh --check-brief), or new when main has no file there (then "new review - absent - - 0")"

**Location:** `scripts/build-loop.sh:45-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the field order and the new-brief line; does not establish STATE for a brief moved to closed/ (it prints new, settled by override row 272).

`scripts/build-loop.sh:315`: `if [[ "$st" == new ]]; then echo "ok $a new review - absent - - 0"; return; fi` and `:345`: `echo "ok $a $st $pol $br $loop $sha $date $disp$reason"`. T8 asserts `ok docs/working/briefs/2026-10-01-none.md new review - absent - - 0`; T28 asserts open/done/dropped lines; probe printed `ok ...-zz.md new review - absent - - 0` (`$FC/logs/s2.log`).

**Evidence:** `scripts/build-loop.sh:310-346`, `test/scripts/build-loop-read.bats:517-519`, `$FC/logs/s2.log`

---

## Claim 11: "POLICY: self-merge only when --settings' policy is self-merge and the brief's first "Policy:" line is exactly "Policy: self-merge"; else review."

**Location:** `scripts/build-loop.sh:48-50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the 2x5 matrix in T5 and the malformed-never case; does not establish the gate's (U2) use of the same value.

`scripts/build-loop.sh:325`: `[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge`, with `pol=review` initialised at `:311`. `BRIEF[policy]` is the first `Policy:` line outside a fence (`scripts/lib/dev-cycle-read.sh:300-301`). T5 passes (`$FC/logs/bats-read.log`).

**Evidence:** `scripts/build-loop.sh:311`, `scripts/build-loop.sh:325`, `scripts/lib/dev-cycle-read.sh:289-312`, `test/scripts/build-loop-read.bats:522-537`

---

## Claim 12: "BRANCH: from the brief's first "Branch: NAME" line."

**Location:** `scripts/build-loop.sh:50-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers first-line selection (a malformed first line is a skip even when a later one is valid; a later different line is ignored); does not establish anything about Branch: lines inside fences beyond brief_fields' documented skip.

`scripts/build-loop.sh:318`: `if [[ ! "${BRIEF[branch]}" =~ ^Branch:\ ([^\ ]+)$ ]]; then echo "skip $a: its first Branch: line is not exactly \"Branch: NAME\""; return; fi`. Probes: `Branch:  feat/e` then `Branch: feat/e` → that skip; `Branch: feat/f` then `Branch: feat/zzz` → `ok ... feat/f ...` (`$FC/logs/s1.log`).

**Evidence:** `scripts/build-loop.sh:317-319`, `$FC/logs/s1.log`

---

## Claim 13: "LOOP: absent (no such branch), working, ready, blocked or stopped, from the branch tip (SHA, with DATE its commit date as YYYY-MM-DD; "-" when absent)."

**Location:** `scripts/build-loop.sh:51-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the five LOOP values and DATE as `%cs` for ordinary commits; does not establish DATE's shape for a crafted committer line (settled, override row 274).

`scripts/build-loop.sh:332`: `"absent "*) echo "ok $a $st $pol $br absent - - $disp"; return ;;`; DATE comes from `check_branch`'s `$(git log -1 --format=%cs "$sha")` (`scripts/lib/dev-cycle-read.sh:380`). T6 asserts absent, working (0 ahead and 1 ahead), ready, blocked, stopped with SHA and `%cs` date; it passes.

**Evidence:** `scripts/build-loop.sh:330-345`, `scripts/lib/dev-cycle-read.sh:370-383`, `test/scripts/build-loop-read.bats:412-443`

---

## Claim 14: "A tip is a marker only when the branch is at least one commit ahead of main and the tip is an empty commit with one parent whose subject is exactly "handoff: ready", "handoff: blocked" or "handoff: stopped: REASON" (1-120 printable ASCII characters, no blank at either end), alone on its first line"

**Location:** `scripts/build-loop.sh:54-59`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 21 crafted tips (two trees, parent after author, parent after committer, duplicate parent, merge, root, NUL, CR, trailing blanks, whitespace-only second line, encoding header, Latin-1 reason, no trailing newline, leading blank line) plus T6/T7; does not establish that "subject" means git's subject — it means the raw first message line, so a message with a leading blank line reads working while `git log --format=%s` shows "handoff: ready".

`scripts/build-loop.sh:276-284` (quoted in Claim 24) plus `:291`: `LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'`. Results (`$FC/logs/m1.log`): normal crafted marker → ready; two tree lines → `it has no parent`; `parent` after `author` → `it has no parent`; `parent` after `committer` → ready (git ignores the late header and sees one parent); `parent X` twice → `it has 2 parents`; merge → 2 parents; root → no parent; NUL → `it holds a NUL byte`; `handoff: ready\r` → not exactly; `handoff: ready` + `   ` line → `runs onto a second line`; trailing blank lines → ready; no trailing newline → ready; `stopped: x  ` → not exactly; Latin-1 reason (with or without an encoding header) → not exactly. Leading blank line: `%B` keeps it (od shows `\n handoff: ready`), `subj` is empty → working, while `git log -1 --format=%s` prints `handoff: ready` (`$FC/logs/m2.log`). This matches the help's own definition at `:67-68` ("its message's first line") and is fail-safe (working, never ready). The 0-ahead rule is asserted by T7 (`test/scripts/build-loop-read.bats:478-481`).

**Evidence:** `scripts/build-loop.sh:273-293`, `scripts/build-loop.sh:336-344`, `$FC/logs/m1.log`, `$FC/logs/m2.log`, `$FC/logs/bats-read.log`

---

## Claim 15: "REASON is printed last. Any other tip is working. DISPATCHED: the brief's "Dispatched: N" (0-99), or 0 without one."

**Location:** `scripts/build-loop.sh:59-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers REASON placement, the working default, Dispatched 0/7/99, missing → 0, first line wins, and a fenced Dispatched line ignored; does not establish ordering when REASON itself holds spaces beyond being the line's tail.

`scripts/build-loop.sh:311` sets `disp=0`; `:320-323`: `[[ "${BRIEF[dispatched]}" =~ ^Dispatched:\ (0|[123456789][0123456789]?)$ ]] || { echo "skip ..."; return; }` / `disp="${BASH_REMATCH[1]}"`. Probes (`$FC/logs/s1.log`): `Dispatched: 0` → 0, `99` → 99, `7` → 7, none → 0, `Dispatched: 3` then `Dispatched: x` → 3, a fenced `Dispatched: x` → 0. T6 asserts `... 2 new dependency (left-pad)` with REASON last.

**Evidence:** `scripts/build-loop.sh:311`, `scripts/build-loop.sh:320-324`, `scripts/build-loop.sh:341`, `scripts/build-loop.sh:345`, `$FC/logs/s1.log`

---

## Claim 16a: "skip BRIEF: WHY — The brief cannot be read (as --check-brief), its Branch: line is missing or malformed or its Dispatched: line malformed, its branch name is refused (as --check-branch), ... or the tip's subject (its message's first line) starts "handoff:" but it is not a marker."

**Location:** `scripts/build-loop.sh:62-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every skip source except the shared-branch one (Claim 16b); does not establish the content of check_brief's and check_branch's own reasons (lib, U1a).

`scripts/build-loop.sh:313` passes check_brief's skip through, `:317`, `:318`, `:322` are the Branch/Dispatched skips, `:334`: `*) echo "skip $a: Branch: ${out#*: }"; return ;;` passes check_branch's refusal, `:340` is the not-a-marker skip. T8 and T7 assert each (`$FC/logs/bats-read.log`).

**Evidence:** `scripts/build-loop.sh:312-344`, `test/scripts/build-loop-read.bats:445-520`

---

## Claim 16b: "another open brief on main, in briefs/ or closed/, names the same branch (ignoring case)"

**Location:** `scripts/build-loop.sh:66-67`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the skip for open briefs (case-folded, briefs/ and closed/, main only); does not hold for a done or dropped brief, which is never skipped for this reason even when an open brief names its branch.

`scripts/build-loop.sh:327`: `if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then`. The condition requires the brief itself to be open; the help's list of skip reasons does not say so. Probe: an open brief b and a done brief d both naming `feat/b` → `ok ...-d.md done review feat/b absent - - 0` and `ok ...-b.md open ...` (`$FC/logs/s1.log`); T28 likewise asserts `ok $c done review feat/x ...` while two open briefs name feat/x. Precise version: "the brief is open and another open brief ...".

**Evidence:** `scripts/build-loop.sh:294-309`, `scripts/build-loop.sh:326-329`, `$FC/logs/s1.log`, `test/scripts/build-loop-read.bats:549-563`

---

## Claim 17: "Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:72`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers --status (ready marker, new brief) and --settings in a probe repo: every file under the repo (including .git) and every ref byte-identical before and after; does not establish anything about writes outside the repo (none observed; not swept).

Probe `$FC/s2.sh` hashed every file under the repo with sha256sum plus `git for-each-ref` before and after the runs: "all repo files and refs byte-identical", no file newer than a stamp (`$FC/logs/s2.log`).

**Evidence:** `scripts/build-loop.sh:348-357`, `$FC/logs/s2.log`

---

## Claim 18: "Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:75-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers --status with ok and skip lines (0), no arguments (1), not a git repo (1), no default branch (1); the perl and lib cases were not re-run for --status (the lib case is asserted for --settings by bats).

Probes (`$FC/logs/s1.log`): `ok 0`, `skip-args 0`, `no-args 1`, `not-git 1` ("Not inside a git repository"), `no-default 1` ("build-loop.sh needs a default branch found by name ..."). The bats test at `test/scripts/build-loop-read.bats:200-205` and `:207-213` asserts the --settings exits.

**Evidence:** `scripts/build-loop.sh:80-111`, `$FC/logs/s1.log`, `test/scripts/build-loop-read.bats:190-213`

---

## Claim 19: "docs/constraints.md: "ok HARD SOFT", "nosuccess ID LINE", "dup ID FIRST SECOND" or "near LINE" (the first problem found)."

**Location:** `scripts/build-loop.sh:158-159`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers CONSTRAINTS_AWK's own outputs and their rendering by the case arms at `:260-265`, including the `*)` arm that only "near" reaches; does not separately list FENCE_AWK's "odd"/"unbalanced" outputs, which main_file consumes before the case (`:130-133`).

`scripts/build-loop.sh:181`: `print (bad != "" ? bad : "ok " hard + 0 " " soft + 0)`; every `bad =` assignment is guarded by `bad == ""` (`:166`, `:167`, `:173`, `:174`, `:180`), so the first problem wins. The arms render `nosuccess` (`:263`), `dup` (`:264`) and the catch-all near-miss message (`:265`); each rendering is asserted in T44 and observed in `$FC/logs/c1.log`/`c2.log`.

**Evidence:** `scripts/build-loop.sh:158-183`, `scripts/build-loop.sh:254-267`, `$FC/logs/c1.log`, `$FC/logs/c2.log`

---

## Claim 20: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER ..., NEVER_LINE and CONSTRAINTS_LINE from main's commit. POLICY is for --status and the gate, NEVER for the gate."

**Location:** `scripts/build-loop.sh:194-197`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that read_settings sets these variables and that POLICY's only current reader is status_line; does not establish the gate's use (U2, not built), and NEVER currently has no reader.

`scripts/build-loop.sh:325`: `[[ "$POLICY" == self-merge && ...` is the only read of POLICY; NEVER is only assigned (`:203`, `:239`) — paraphrased — no quote available because the claim covers absence of code (grep of build-loop.sh for `NEVER` outside `NEVER_LINE` finds only comments and assignments). `:199`'s `SC2034` disable agrees.

**Evidence:** `scripts/build-loop.sh:194-268`, `scripts/build-loop.sh:325`

---

## Claim 21: "The tip SHA of a brief's branch, read as a handoff marker: prints ready, blocked, "stopped REASON", working (no "handoff:" subject), or "bad WHY". The caller has checked that the branch is at least one commit ahead of main."

**Location:** `scripts/build-loop.sh:270-272`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the five output forms and the single caller's ahead guard; does not establish the guard for any future caller.

`scripts/build-loop.sh:337-338`: `if [[ "$ahead" -gt 0 ]]; then` / `kind="$(marker_kind "$sha")"` is the only call. Outputs observed in `$FC/logs/m1.log` and T6/T7.

**Evidence:** `scripts/build-loop.sh:273-293`, `scripts/build-loop.sh:336-344`, `$FC/logs/m1.log`

---

## Claim 22: "git parses the object: its tree, its parents and where the message starts."

**Location:** `scripts/build-loop.sh:275`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers parents (`rev-list --parents`), tree (`rev-parse ^{tree}`) and message (`log %B`) all coming from git's parser, including on objects with two tree lines and misplaced parent lines; does not cover the NUL check at `:279`, which reads the raw object (`cat-file commit`) on purpose.

`scripts/build-loop.sh:276-277`: `read -ra p <<<"$(git rev-list --parents -n 1 "$1")"` / `msg="$(git log -1 --format=%B "$1")"`, and `:282` compares `git rev-parse --verify "$1^{tree}"` with the parent's. For the two-tree object, `rev-parse ^{tree}` returns the first (main's) tree and `rev-list --parents` prints 1 word (no parent) (`$FC/logs/m3.log`).

**Evidence:** `scripts/build-loop.sh:273-284`, `$FC/logs/m3.log`, `$FC/logs/m1.log`

---

## Claim 23: NUL-byte refusal ("bad it holds a NUL byte")

**Location:** `scripts/build-loop.sh:279`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a NUL in the message of a tip whose `%B` subject starts "handoff:"; does not establish the check for tips whose subject does not start "handoff:" (they return working at `:278` first, by design).

`scripts/build-loop.sh:279`: `if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi`. Probe `handoff: ready\0x` → `... is not a marker: it holds a NUL byte` (`$FC/logs/m1.log`).

**Evidence:** `scripts/build-loop.sh:278-279`, `$FC/logs/m1.log`

---

## Claim 24: "grep in the C locale: the ranges are ASCII bytes, and no locale is switched here."

**Location:** `scripts/build-loop.sh:290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reason check's byte semantics and the absence of an extra setlocale warning under an uninstalled caller locale; does not cover the two warnings bash itself prints at start-up and on scrub_reexec (present for every mode).

`scripts/build-loop.sh:291`: `printf '%s\n' "$r" | LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'` — the variable is set only for grep's environment. Under `LC_ALL=en_US.UTF-8` and `xx_YY.UTF-8` (both uninstalled; `locale -a` lists C, C.utf8, POSIX) a ready and a stopped tip each produce exactly 2 stderr lines, both bash start-up `setlocale` warnings (`$FC/logs/m2.log`); the 553a50d5 script, which used `local LC_ALL=C`, produces 3 for the stopped tip (`$FC/logs/m3.log`). UTF-8 reasons (`caf\xc3\xa9`, bidi) are refused (T7).

**Evidence:** `scripts/build-loop.sh:289-292`, `$FC/logs/m2.log`, `$FC/logs/m3.log`

---

## Claim 25: "Lower-cased branch names that more than one open brief on main (in briefs/ or closed/) names, each between newlines: such briefs are skipped (F31). status_line computes it on first use, so no caller can skip it."

**Location:** `scripts/build-loop.sh:294-296`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the set's contents (case-folded, briefs/ and closed/, main's tree only, working-tree-only briefs excluded) and its lazy computation inside status_line; does not establish computation for a run whose every brief exits status_line before `:326` (none is needed then).

`scripts/build-loop.sh:301`: `list="$(git ls-tree --full-tree --name-only "$MAIN_SHA" -- docs/working/briefs/ docs/working/briefs/closed/)"`, `:303`: `if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi`, `:305`: `b="$(lower "${BASH_REMATCH[1]}")"`, `:307-308` builds the newline-delimited set; `:326`: `[[ -n "$SHARED_BRANCHES" ]] || shared_branches` (after the first call the value is at least `$'\n'`, so it is computed once). T28 asserts Feat/X vs feat/x, an open closed/ brief counting, and a working-tree-only brief not counting; all pass.

**Evidence:** `scripts/build-loop.sh:294-309`, `scripts/build-loop.sh:326-329`, `test/scripts/build-loop-read.bats:549-573`

---

## Claim 26: "kept in a lib so scripts/build-loop.sh can share it" ("planned" dropped)

**Location:** `scripts/dev-cycle.sh:278` (diff hunk at `:87`), `scripts/lib/dev-cycle-read.sh:2-3`
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that build-loop.sh sources the lib from its own directory; does not establish which lib functions each script uses.

`scripts/build-loop.sh:85-88`: `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` ... `source "$READ_LIB"`. No "planned" remains in the three files (paraphrased — no quote available because the claim covers absence of text: grep for `planned` in scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh returns nothing).

**Evidence:** `scripts/build-loop.sh:82-88`, `scripts/dev-cycle.sh:91-94`, `scripts/lib/dev-cycle-read.sh:1-5`

---

## Claim 27: "commit_all [MSG]: stage everything and commit it on the current branch (an empty commit when nothing changed, so rewriting a file as it was still works)."

**Location:** `test/lib/build-loop-fixtures.bash:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the no-change case; does not establish behaviour with a pre-commit hook (the hermetic env has none).

`test/lib/build-loop-fixtures.bash:23`: `commit_all() { git add -A && git commit -q --allow-empty -m "${1:-fixture}"; }`. Probe: commit count 3 → 4, `diff-tree` empty (`$FC/logs/m3.log`).

**Evidence:** `test/lib/build-loop-fixtures.bash:23`, `$FC/logs/m3.log`

---

## Claim 28: "constraints LINE...: docs/constraints.md holding these lines, committed." / "brief SLUG LINE...: docs/working/briefs/2026-10-01-SLUG.md holding a title and these lines, committed on the current branch; sets B to its path."

**Location:** `test/lib/build-loop-fixtures.bash:29-30`, `test/lib/build-loop-fixtures.bash:42-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both helpers' file contents and commits; "a title" is `# Brief: SLUG` followed by a blank line, which the comment does not mention.

`:30`: `constraints() { mkdir -p docs && printf '%s\n' "$@" > docs/constraints.md && commit_all constraints; }`; `:46-48`: `B="docs/working/briefs/2026-10-01-$s.md"` / `printf '# Brief: %s\n\n' "$s" > "$B" && printf '%s\n' "$@" >> "$B"` / `commit_all "brief $s"`.

**Evidence:** `test/lib/build-loop-fixtures.bash:29-49`

---

## Claim 29: "work BRANCH: BRANCH from main with one commit that changes a file."

**Location:** `test/lib/build-loop-fixtures.bash:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the branch point and the one changing commit; does not establish the checkout state if a step fails midway.

`:53-54`: `git branch -q "$1" main` / `git checkout -q "$1" && echo "$1" > "work-${1//\//-}.txt" && commit_all "work on $1" && git checkout -q main`. T6 asserts working with the branch one commit ahead.

**Evidence:** `test/lib/build-loop-fixtures.bash:52-55`, `$FC/logs/bats-read.log`

---

## Claim 30: "tip BRANCH MESSAGE [TREE [PARENT...]]: a commit with MESSAGE and a newline (no cleanup: commit-tree takes it as given) on BRANCH's tip. By default it is empty (BRANCH's own tree) with BRANCH's tip as its one parent; pass TREE and the parents ("" for none) to build anything else."

**Location:** `test/lib/build-loop-fixtures.bash:57-60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers verbatim message storage (leading blank line, surrounding spaces, `#` lines and trailing blank lines kept) and the default/explicit tree and parents; does not establish behaviour for a MESSAGE holding NUL (bash cannot pass one).

`:65`: `git update-ref "refs/heads/$b" "$(printf '%s\n' "$m" | git commit-tree "$t" "${p[@]}")"`; `:63` skips empty parent arguments. Probe: message `\n  x  \n\n# c\n\n` is stored byte for byte after the header (`$FC/logs/m3.log`).

**Evidence:** `test/lib/build-loop-fixtures.bash:61-66`, `$FC/logs/m3.log`

---

## Claim 31: The new and renamed bats test names (T44; "--settings prints its four lines in order and exits 0; usage errors and a missing default branch exit 1"; T6; T7 "spoofed markers are skips or read as working, and a bad reason is not echoed"; T8; T5; T21; T28)

**Location:** `test/scripts/build-loop-read.bats:159`, `:190`, `:412`, `:445`, `:488`, `:522`, `:539`, `:549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each name against its assertions; T7's "not echoed" is asserted for the non-ASCII and ESC reasons only, the bidi case relying on the skip text being a constant (`scripts/build-loop.sh:292`) — the same premise override row 265 settled for 859e29e8.

Each name's claims are asserted in its body (read in full; e.g. `:200-205` asserts the missing-default-branch exit 1 the renamed test names; `:465` asserts `[[ "$output" != *$'\xc3'* && "$output" != *'[31m'* ]]`). All 16 tests pass (`$FC/logs/bats-read.log`).

**Evidence:** `test/scripts/build-loop-read.bats:159-573`, `$FC/logs/bats-read.log`

---

## Claim 32: Test comments — "A hand-made object with two tree lines, the parent's last: git stops at the second and sees no parent; a reader taking the last tree would say ready." and "A ready marker's body is not read here (--marker reads blocked and stopped bodies)."

**Location:** `test/scripts/build-loop-read.bats:467-468`, `test/scripts/build-loop-read.bats:439`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git's parse of the two-tree object and the ready-with-body case; `--marker` is a plan reference (`docs/working/plan-build-loop-handoff.md:206`, U3b), not code in this unit.

Two-tree object: git takes the first tree and reports no parent (`$FC/logs/m3.log`); the last tree equals the parent's, so a last-tree reader would see an empty one-parent commit. Plan: "`--marker BRIEF` → `ok BRIEF SHA`, then the `blocked` or `stopped` body" (`docs/working/plan-build-loop-handoff.md:206`). T6's ready-with-body case prints `ready`.

**Evidence:** `test/scripts/build-loop-read.bats:439-442`, `test/scripts/build-loop-read.bats:467-472`, `docs/working/plan-build-loop-handoff.md:206`, `$FC/logs/m3.log`

---

## Claim 33: Other new test comments ("Only in the working tree: still missing."; "A line that looks like a constraint ID but is not exact: unreadable, never skipped (Q-112 [1])."; "A marker at main's tip with the branch 0 commits ahead is main's, not the loop's."; "So is a branch that is a symbolic ref to main."; "Not landed on main: new, with nothing else to read."; "An open brief left in closed/ counts too."; "An open brief only in the working tree does not count.")

**Location:** `test/scripts/build-loop-read.bats:363`, `:387`, `:478`, `:482`, `:516`, `:564`, `:569`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each comment against the assertion beneath it, all passing; "never skipped" holds for the ten listed shapes, not for fenced or non-ASCII look-alikes (Claim 8).

Each comment is followed by the assertion it names (read in full) and the suite passes (`$FC/logs/bats-read.log`).

**Evidence:** `test/scripts/build-loop-read.bats:359-573`, `$FC/logs/bats-read.log`

---

## Claim 34: Commit messages 859e29e8 and aaae80c6 (test list; "a hard one needs a success: ... line before the next constraint"; "The lib is called in-process (no dev-cycle.sh subprocess)"; "check_brief's git log -1 -G'^Status: ' costs about 1 ms per brief"; "The '--status --settings' usage case is dropped"; "The real briefs have no Branch: line yet, so --status skips them")

**Location:** `859e29e8`, `aaae80c6` (commit messages)
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the listed behavioural claims (all hold at HEAD) and re-times the `-G` walk; does not re-check the two claims settled by override row 265 or the 79 ms figure (row 275).

Holds: the bats bodies match 859e29e8's list; build-loop.sh never runs dev-cycle.sh (paraphrased — no quote available because the claim covers absence of code: its only `dev-cycle.sh` mentions are comments at `scripts/build-loop.sh:46`, `:71`, `:82`); the usage loop at `test/scripts/build-loop-read.bats:195` is `"" "--bogus" "--settings extra" "--status"`; `--status` on the three real briefs prints `skip ...: no Branch: line on the default branch` for each (`$FC/logs/real-briefs.log`). Imprecise: the per-brief `git log -1 --first-parent ... -G'^Status: '` measured 2-3 ms wall time per brief including process start (`$FC/logs/glog-timing.log`, main at 2143 commits, 1023 first-parent), not "about 1 ms". History-only and load-dependent; row 275's rationale ("timing varies with load") likely applies.

**Evidence:** `$FC/logs/real-briefs.log`, `$FC/logs/glog-timing.log`, `test/scripts/build-loop-read.bats:195`, `scripts/build-loop.sh:46`

---

## Claim 35: Commit message 553a50d5: "this says four lines, three of them from docs/dev-cycle.md. U1c stays at 399 changed code lines against U1b."

**Location:** `553a50d5` (commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count as added+deleted lines under scripts/ and test/ of `git diff feat/build-loop-u1b...553a50d5`; does not establish the count against the u1b tip of that day (the three-dot diff uses the merge base, which gives the same 399 against `83b9fd49^2`).

`git diff --numstat feat/build-loop-u1b...553a50d5 -- scripts test | awk '{a+=$1+$2} END{print a}'` → 399; against `83b9fd49^2` → 399 (cwd worktree, exit 0, 2026-10-05T16:45Z; output inline in this session, re-runnable).

**Evidence:** `scripts/build-loop.sh:10-11`

---

## Claim 36a: Commit c143b929, bullets R1 (main clause and "IDs have no leading 0, so H1 and H01 cannot both count"), A1, A4/A5, A8, the wording bullet ("the unused status_of helper removed"), "T5 sets "Self-merge never: none"", and "426 changed code lines against U1b"

**Location:** `c143b929` (commit message)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed bullet against HEAD; R1's main clause is verified for ASCII lines outside fences only (Claim 8's residue applies).

R1: `H01: x` → near-miss unreadable (`$FC/logs/c1.log`). A1: rev-list/rev-parse/log as quoted in Claim 22; the two-tree object is a skip (`it has no parent`, `$FC/logs/m1.log`). A4/A5: Claim 25. A8: Claim 24 (3 warnings at 553a50d5 vs 2 now). `status_of` absent from scripts (grep empty). T5: `settings "Build-loop policy: $s" "" "Self-merge never: none"` (`test/scripts/build-loop-read.bats:525`). Count: `git diff --numstat feat/build-loop-u1b...c143b929 -- scripts test` gives 170+8, 1+1, 2+2, 32+2, 205+3 = 426.

**Evidence:** `test/scripts/build-loop-read.bats:525`, `scripts/build-loop.sh:273-309`, `$FC/logs/c1.log`, `$FC/logs/m1.log`, `$FC/logs/m3.log`

---

## Claim 36b: Commit c143b929, R1: "a heading ends a pending hard constraint, so a success: line under another section does not satisfy it."

**Location:** `c143b929` (commit message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers ATX headings at column 0; does not hold for setext headings or ATX headings indented 1-3 spaces, under which a success: line still satisfies the pending constraint.

Same mechanism and probes as Claim 6: `scripts/build-loop.sh:174` matches only `/^#/`; `- H1: a` / `Other` / `=====` / `success: b` → `constraints ok 1-hard 0-soft` (`$FC/logs/c2.log`).

**Evidence:** `scripts/build-loop.sh:174`, `$FC/logs/c2.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 6** (`scripts/build-loop.sh:33-35`, `:174`): "heading" means any line starting `#`; setext and indented ATX headings do not end a pending hard constraint, `#tag` does. Say "the next line starting #".
- **Claim 8** (`scripts/build-loop.sh:35-37`): the near-miss rule skips fenced lines and treats only ASCII as letters. A fenced `H2: never drop prod`, or a Cyrillic or fullwidth `Н2:`/`Ｈ2:`, leaves `constraints ok` (the Q-112 [1] reportable case). Add "outside a fence" and "ASCII", or refuse these lines too.
- **Claim 16b** (`scripts/build-loop.sh:66-67`): the shared-branch skip applies only when the brief itself is open; done or dropped briefs print ok.
- **Claim 34** (commits 859e29e8/aaae80c6): "about 1 ms per brief" measured 2-3 ms wall time; history-only (row 275's rationale likely applies).
- **Claim 36b** (commit c143b929): "a heading ends a pending hard constraint" holds for column-0 `#` headings only (same as Claim 6).

### Unverifiable
- **Claim 4** (`scripts/build-loop.sh:30`, `:37`): "every loop prompt carries" and "Only ok lets the orchestrator dispatch" describe U3/U4, which are not built yet; they match plan `:44`/`:260`.

---

## Goal-Alignment Note

**Goal (from preamble):** Final confirming review of U1c (HEAD c143b929) before it merges into feat/build-loop-u1b.
**Alignment:** Aligned. The fix commit's claims hold under execution (R1's ASCII near-miss refusal, the git-parsed marker, closed/ briefs counting, the C-locale grep, the 426-line count). The one item that bears on the merge decision is Claim 8. Q-112 [1] asks for a report when a hard constraint can be silently dropped while the line reads `constraints ok`, and a fenced constraint line or a homoglyph ID does exactly that. The orchestrator should decide whether fence-skipping is intended (plan `:204` reads the file "under FENCE_AWK") and say so in the help, or refuse those lines.
**Out of scope here:** code quality, and whether the fence and homoglyph cases should fail closed (that is a design call for the critics or the user).
