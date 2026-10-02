Commit: f4d27d2 (A) / a7dfc0c (B)

# Security Review — dev-cycle pass 30 (the pass-29 fix round)

**Scope:** Partial. A: `git diff 38578a9..f4d27d2 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`, commits e2f2d54 and f4d27d2). B: `git diff c345865..a7dfc0c -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`). Merge 35987c1 (parents a7dfc0c and 0a56e33) carries f4d27d2's `scripts/dev-cycle.sh` (`a66b614`), `test/scripts/dev-cycle.bats` (`7d54297`) and `scripts/questions.sh` (`df58181`, unchanged since 38578a9), and a7dfc0c's SKILL.md (`6b6010d`), checked with `git rev-parse`. Everything else is context only.
**Date:** 2026-10-02
**Based on:** shared brief `digest-pass30-brief-dc1aa358.md`; Stage-1 context `docs/reviews/code-fact-check-report-digest-pass29.md` (it covers 38578a9, so every unit cited below was re-read whole at f4d27d2: FENCE_AWK `:255-281`, check_brief `:282-314`, ANSWER_AWK and check_answer `:356-449`, help `:2-67` and `:131`); the pass-29 security, api-consistency and fact-check reports, whose probes were rerun.
**Replication:** k=1 (loop pass)

**Probe discipline.** Each probe was one script that started with `set -eu`, made its own `mktemp -d -p sec30/` directory in that same script, and checked `case "$PWD"` before any `git init`, commit, write or `rm`. Each sub-case got its own `mktemp -d` under that directory. Code came from `git show <commit>:<path>` or `git archive <commit> | tar -x`. Every process ran in the foreground under `timeout`, and all of them exited. `GIT_CONFIG_GLOBAL=/dev/null`. Apart from this report, nothing was written to `/workspace` or either worktree. Afterwards `/workspace` was on `main` and `wt-devcycle` was clean. At 17:33:46Z, after the last probe, `wt-digest` was also clean. By 17:36Z it showed uncommitted edits to `scripts/dev-cycle.sh` and `test/scripts/dev-cycle.bats` (mtimes 17:35:10Z and 17:35:57Z) from another actor, and I did not touch them. Every result here comes from the committed f4d27d2 blobs. The bats processes in `pgrep` belong to another session's suite in `wt-devcycle/test/`. I did not start or stop them. The system awk is mawk 1.3.4 20200120.

Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec30/` (`sec30/` below):
- `probe1.sh`/`.log`: bats (`bats.log`), lint (`lint.log`), shellcheck, `--help`, blob identity, every real ID at 38578a9 vs f4d27d2, and fence balance in the real files.
- `probe2.sh`/`.log`: every pass-28/29 shape (security, fact-check Q-031–Q-045 and Q-101–Q-114, api P1–P13), plus new candidates C1–C17. Each case ran isolated, as `--check-answer` and `--check-brief`.
- `probe3.sh`/`.log`: questions.sh archive splits (security P3, fact-check probe 6, D1), plus C18/C1c/C1d/C2b.
- `probe4.sh`/`.log`: D2 (a double archive split), C2c, `opens()` under mawk (match/RLENGTH, fcol), interval-expression support, and timing.
- `probe5.sh`/`.log`: C2d and C1e (pure-fence shapes with both readers balanced).

Legibility-target values: **agent** (the model running the dev-cycle skill acts on the output); **user** (the human who answers questions and reads the roadmap or record); **maintainer** (someone editing the script, tests or skill).

---

## Trust Boundary Map

```
B1 (changed): questions files (recorded answers + any session's text; questions.sh rewrites them) → --check-answer awk (FENCE_AWK opens()/closes() with fcol; whole-file parity; END "unbalanced" skip; only a fenced "### Q-NNN " ends the entry) → keep/drop/done/open/unrecognized/skip → brief Kept:/Applied:/close (SKILL:285-299)
B2 (changed): brief blob on the default branch → --check-brief awk (same FENCE_AWK; first Status: line; no END check) → open/done/dropped + commit → Done / Ideas / git mv (SKILL:273-284)
B3: brief branch tip → --check-branch → idle (unchanged)
B4 (changed): roadmap In flight lines + briefs glob ("prints ok") → orphan rule (any glob-ok or cycle-written brief, any state, gets a line) → checks 1-3; closed/ open|new → record + final-message list (SKILL:84-95, :269-272, :369-375)
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | questions-file content (working tree), including what `questions.sh archive` moves between the two files | runtime-mutable (user, any session, the cycle, questions.sh) | UNTRUSTED toward the keep/drop/done decision. Only the target entry's own recorded answer, once its header is ANSWERED, should decide |
| S2 | brief blob and its history on the default branch | runtime-mutable (any merge) | UNTRUSTED toward Done/dropped. Accepted by design as a self-report reviewed at merge |
| S3 | brief branch tip commit date | runtime-mutable (any committer) | UNTRUSTED toward the idle decision. Its only effect is to ask the user |
| S4 | path printed by the briefs glob or named in an In flight line | per cycle | UNTRUSTED toward write sinks (`--check-write`, `git mv`, roadmap line text) |
| S5 | `FENCE_AWK`/`ANSWER_AWK` program text, ID regex | code-constant | trusted |

Untrusted text still reaches decision sinks only through S1 and S2. This round makes three changes:
- It bounds openers (at most 3 spaces, or a list marker after at most 3 spaces) and closers (no marker, indentation at most `fcol + 3`). That closes pass-29 F1 for every shape that pass reported.
- It turns a file that ends inside a fence into a whole-file skip. That closes pass-29 F2 and the single-split case of F3.
- It ends an entry only on a fenced `### Q-NNN ` line, which closes pass-29 F4.

Two residual divergences remain in the closer rule (F1 below). One of them is a new regression against 38578a9. The never-closed skip catches only an odd number of flips (F3).

## Findings

#### F1. `closes()` diverges from CommonMark in two ways: `fcol + 3` is too generous for an opener with no list marker, and a tab never counts as indentation. Both readers stay balanced and still read a quoted line: wrong `drop`, wrong `keep`, and a brief wrongly `done`. The tab half regresses against 38578a9

**Severity:** Low. This is the same class as pass-29 F1. A quoted line decides, but whoever wrote the quote could have written the decisive line directly. That is also why the floor rule does not lift it: no party gains a capability it lacks.
**Location:** `scripts/dev-cycle.sh:276-280` (`closes()`), `:274` (`fcol = i`), comment `:259-261`. Used at `:302` (briefs) and `:402` (answers).
**Boundary:** B1, B2
**Move:** 11 (bypass enumeration)
**Confidence:** High for the code's readings, which were executed. Medium-High for the CommonMark column, which comes from the spec. No reference parser is installed. Two spec rules apply: a closing fence "may be preceded by up to three spaces of indentation", relative to its container, not to the opener; and a tab advances to the next multiple of 4. Preconditions: a hand-written fence example in the target entry or brief, shaped as below. None occurs in the real files (`probe1.log`: 0 indented or list-marker fence-shaped lines in the 6 files read).
**Legibility-target:** maintainer

**Evidence (verbatim):**
```awk
# scripts/dev-cycle.sh:264, :274, :276-280 (FENCE_AWK :263-281, read whole)
function spaces(l,   n) { n = 0; while (substr(l, n + 1, 1) == " ") n++; return n }
...
  fch = ch; flen = n; fcol = i; return 1
}
function closes(l,   i, s, n) {
  i = spaces(l); if (i > fcol + 3) return 0
  s = substr(l, i + 1); n = run(s, fch)
  return n >= flen && substr(s, n + 1) ~ /^[ \t]*$/
}
```
The comment states exactly this rule: "indented at most 3 columns past the opener's fence". So the comment is accurate about the code. The divergence is between the code and CommonMark.

- **(a) Opener with no marker.** For an opener with no list marker, `fcol` is the fence's own indentation, not its container's column. A top-level ```` ``` ```` opened with 2 spaces therefore accepts a 5-space closer. In CommonMark a top-level closer takes at most 3 spaces.
- **(b) Tabs.** `spaces()` counts only spaces, so a tab-led line never closes. In CommonMark, a tab after `- ```` reaches column 4, which is relative indent 2 inside the item, so the line closes the fence.

| Case (isolated; both readers balanced at EOF unless noted) | 38578a9 | f4d27d2 | CommonMark |
|---|---|---|---|
| C2d answer: `- ```` / `<tab>```` / `**Answer:** [2] drop` / blank / 4 spaces + ```` ``` ```` / `**Answer:** [1] keep` (`probe5.log`) | drop | **keep** | drop (the tab line closes; the 4-space line is indented code) |
| C2d brief: `- ```` / `<tab>```` / `Status: open` / blank / 4 spaces + ```` ``` ```` / `Status: done` | open | **done** | open |
| C18 answer: `  ```` / 5 spaces + ```` ``` ```` / `[2] drop` / `-     ```` / ```` ``` ```` / `[1] keep` (`probe3.log`) | drop | **drop** | keep |
| C1e brief: `  ```` / 5 spaces + ```` ``` ```` / `Status: done` / ```` ``` ```` / `Status: open` (`probe5.log`) | done | **done** | open |
| C1c answer: C1 plus a trailing ```` ``` ```` (CommonMark leaves that one open) | drop | **drop** | keep |
| C1 / C1d / C2b answer, where the flip persists to EOF | drop | skip (never closed) | keep / keep / drop |

Notes on the table:
- C2d needs nothing but fence lines, and the code reads both files as balanced. Its answer and brief rows are new wrong readings at f4d27d2. Under 38578a9, `lead()` stripped the tab, so the tab line closed the fence there.
- The brief reader has no END check and stops at the first `Status:` line. So a brief takes F1's wrong `done` even when only one line diverges (C1e).
- The never-closed skip catches the single-flip answer rows (C1, C2b), and that is where it pays off.
- The brief asked that every result be the CommonMark reading or a skip/open/unrecognized, "never a wrong keep/drop/done". These rows break that criterion.

**Recommendation:**
- **Closer rule.** Make the closer bound depend on the container, not the fence. For an opener with no marker, cap the closer at 3 spaces (record the container column as 0, separately from the fence's own indentation). Keep `fcol + 3` only for list-marker openers.
- **Tabs.** In `spaces()`, count a tab as advancing to the next multiple of 4. The fail-closed alternative: in `closes()`, treat a fence-shaped line whose prefix holds a tab, or whose indentation lies in `(3, fcol + 3]` for a no-marker opener, as "ambiguous". Have it set a flag that END turns into the never-closed skip. Do the same in `check_brief`.
- **Tests and comment.** Add C2d (both halves), C18 and C1e as bats cases. Reword `:259-261` so it no longer reads as CommonMark's rule.

#### F2. `opens()` still accepts three shapes that CommonMark does not treat as fences: a marker followed by 5 or more spaces, an ordinal of 10 or more digits, and a fence line inside an HTML `<pre>` block. Each one reads a quoted line, and the code stays balanced while CommonMark leaves a fence open

**Severity:** Low (same class as F1; not a regression, since 38578a9 reads these the same way)
**Location:** `scripts/dev-cycle.sh:266-275` (`opens()`, the `match()` at `:269`)
**Boundary:** B1, B2
**Move:** 11
**Confidence:** High for the code (executed). Medium-High for CommonMark:
- A list item whose content starts after 5 or more spaces begins with indented code.
- An ordered-list start number has at most 9 digits.
- HTML blocks are outside the model, and the "close to CommonMark" hedge covers them.
Precondition: a hand-written line of that shape in the target entry or brief, ahead of a plain fence line.
**Legibility-target:** maintainer

**Evidence (verbatim):** `if (match(s, /^([-*+]|[0123456789]+[.)])[ \t]+/)) { i += RLENGTH; s = substr(s, RLENGTH + 1) }` (`:269`). `probe4.log` (opens() on its own): `[-     ```] opens=1 fcol=6`, `[1234567890. ```] opens=1 fcol=12`. `probe2.log`:

| Case | 38578a9 | f4d27d2 | CommonMark |
|---|---|---|---|
| C3 `-     ```` / `[2] drop` / ```` ``` ```` / `[1] keep` | keep | keep | drop |
| C4 `1234567890. ```` / `[2] drop` / ```` ``` ```` / `[1] keep` | keep | keep | drop |
| C6 `<pre>` / ```` ``` ```` / `</pre>` / `[2] drop` / ```` ``` ```` / `[1] keep` | keep | keep | drop |
| C5 `- ```` / `  x` / ```` ``` ```` (col 0) / `[1] keep` | keep | keep | unrecognized (the col-0 line opens a new fence) |
| briefs C3 / C4 / C6 (`Status: done` in the CommonMark-unfenced spot) | open ×3 | open ×3 | done ×3 (wrong open: fails toward keeping the slot) |

In each answer row CommonMark ends the file inside a fence, but the code's reader does not, so the END skip does not fire. Combined with F1(a), C3's shape rebalances a CommonMark-balanced file into a wrong `drop` (C18 above). C5 is what an author usually means, so it is listed but not counted.

**Recommendation:**
- Accept 1–4 columns of whitespace after a marker. For 5 or more, the opener is the marker's column + 2, and the rest is indented code, not a fence.
- Accept at most 9 digits. Check `RLENGTH` of a `[0123456789]+` match. Do not use `{1,9}`: under mawk 1.3.4 20200120, `match("123456789. ", /^[0-9]{1,9}[.)]/)` returns 0 (`probe4.log`), so intervals are unsupported there.
- Leave `<pre>` to the comment's hedge.

#### F3. The never-closed skip catches only an odd number of parity flips. Two `questions.sh archive` splits of plain ```` ``` ```` quotes rebalance both files, and the forged `done Q-018` read returns. The comment at `:362-365` promises more than the check gives

**Severity:** Low. The decisive read needs a quoted heading whose ID has no real entry (a lost or never-written `Asked:` ID). Otherwise the archive holds two copies and the read is a `dup` skip.
**Location:** `scripts/dev-cycle.sh:427-432` (END), comment `:362-365`. Cause: `scripts/questions.sh:161`, `:223-227`, `:364-368` (context, unchanged; their entry patterns do not track fences)
**Boundary:** B1 (S1 rewritten by the repo's own tool)
**Move:** 3, 4
**Confidence:** High (executed). Preconditions:
- two live entries each quote an ANSWERED entry's heading in a plain fence with no info string;
- `questions.sh archive` then runs;
- the quoted ID is asked but has no real entry.
**Legibility-target:** maintainer

**Evidence (verbatim):** the comment says "A file that ends with a fence still open is a skip for every ID: one stray fence line (questions.sh archive can split an entry at a fenced heading) flips what follows, so nothing in that file is trusted." The check is `if (infence) print "unbalanced"` (`:428`).

The single-split shapes now skip every ID:
- security P3 after the archive: `skip Q-009 … Q-018 … Q-011 … Q-012: a code fence in docs/working/questions.md is never closed`;
- fact-check probe 6: Q-001, Q-002 and Q-000 all skip;
- D1 (two splits whose quotes carry ```` ```markdown ````, which cannot close each other): every ID skips.

D2 (`probe4.log`) is the D1 layout with plain ```` ``` ```` quotes:
- **Before the archive** (38578a9 and f4d27d2 agree): `open Q-009; open Q-010; open Q-011; drop Q-013; skip Q-018 …; skip Q-019 …`.
- **After the archive**, f4d27d2 reads `open Q-009; skip Q-010: its heading appears only inside a code fence …; skip Q-011: …; drop Q-013; done Q-018; skip Q-019: … questions-archive.md`. 38578a9 gives the same reading.

Both files end balanced. The live file's two leftover openers pair up and fence Q-011 and Q-010. The archive's two leftover closers pair up and turn the first quote into a real entry. F1's C2d and C18 are the same "even flips" bypass, built from hand-written lines instead.

**Recommendation:**
- Narrow the comment to what END can see: "a file that ends inside a fence".
- The durable fix is still pass-29 F3's: make questions.sh's entry parsing fence-aware, or have `questions.sh check` fail on a fenced `### Q-` line before `archive` runs. That change is outside this diff, so file it.
- A cheap in-diff mitigation: have END also report `unbalanced` when the file holds a fenced line matching `^### Q-[0-9]+ ` whose following ANSWERED header would be archived. Simpler: treat any fenced `### Q-NNN ` line in either file as a skip for every ID. `probe1.log` shows 0 such lines in the real files, so this costs nothing today.

#### F4. `spaces()` walks every leading space on every unfenced line before testing `> 3`. A file of long blank-space lines costs about 5× more

**Severity:** Informational (availability, only at sizes far beyond the real 186 KB archive; this belongs to the performance critic)
**Location:** `scripts/dev-cycle.sh:264`, `:267`, `:277`
**Boundary:** B1
**Move:** 8
**Confidence:** High (measured, `probe4.log`, one run each)
**Legibility-target:** maintainer

**Evidence (verbatim):** `function spaces(l,   n) { n = 0; while (substr(l, n + 1, 1) == " ") n++; return n }`, then `i = spaces(l); if (i > 3) return 0` (`:267`). Measured with two IDs:

| Input | 38578a9 | f4d27d2 |
|---|---|---|
| 4096 lines of 4096 spaces (16 MiB) | 206 ms | 1104 ms |
| one 16 MiB space line before a fence | 4019 ms | 4669 ms |
| the same line inside a fence | 2780 ms | 3221 ms |

Results are unchanged (keep / skip).

**Recommendation:** Optional. Stop counting at `limit + 1` (`spaces(l, 4)` in `opens()`, `spaces(l, fcol + 4)` in `closes()`).

#### F5. B: the orphan rule and the final-message list are fixed. One untested edge remains: the same file name under `briefs/` and `closed/`

**Severity:** Informational (bookkeeping. Read-static. The edge needs a copy of a closed brief put back under `briefs/`)
**Location:** `skills/dev-cycle/SKILL.md:93-95`, `:269-272`, `:280-282` (a7dfc0c)
**Boundary:** B4
**Move:** 5
**Confidence:** Medium (read-static)
**Legibility-target:** agent

**Evidence (verbatim):**
- Rules: "A brief the glob prints `ok` for, or this cycle wrote, whose path no In flight line names (compared as text) gets one, whatever its state, so In flight's checks reach it."
- In flight: "items whose brief the Rules' glob prints `ok` for or this cycle wrote (whatever state `--check-brief` prints, so check 1 can close it)".
- Final message: "each `closed/` brief that reads `open` or `new` (for the user to set its status)".

The two membership sentences now name the same set. That set matches the slot definition's "the glob prints `ok` for it … or this cycle wrote it" (`:84-86`), so pass-29 F7 (done briefs with no line) and F6 (closed/ open/new missing from the final message) are fixed.

The orphan rule is correct and complete for every state `--check-brief` prints:
- `open` and `new` hold a slot and reach check 3;
- `done` and `dropped` reach check 1;
- a skip keeps its slot and is recorded.

The remaining edge: a line already points at `closed/<name>` while a file of the same `<name>` sits under `briefs/`. The text compare adds a second line. If that brief reads `done`, check 1's `git mv` targets an existing `closed/<name>`. The skill does not say what happens then.

**Recommendation:** Optional. Add to check 1: "if `closed/<same name>` already exists, record it and leave both for the user".

## Pass-29 probe reruns (executed; not endorsements, because the fence reader has F1–F3 and untested candidates)

| Shape (`probe2.log`/`probe3.log`, isolated) | 38578a9 | f4d27d2 | CommonMark |
|---|---|---|---|
| sec29 N1, N1b, N2 (marker or 8-space line inside a fence) | drop ×3 | keep ×3 | keep |
| sec29 N3 nested `- - ```` (CommonMark also ends inside a fence) | drop | skip (never closed) | keep |
| sec29 N4, s28 Q-013/Q-014/Q-017 (indented or tab code) | keep / unrecognized ×3 | keep ×4 | keep |
| fc Q-031 / Q-032 (4-space or tab lines around `[2]`) | keep / keep | drop / drop | drop |
| fc29 Q-101 / Q-102 / Q-103 | drop / drop / unrecognized | keep ×3 | keep |
| fc29 Q-105 (4-space line never closes) | keep | skip (never closed) | no answer |
| fc29 Q-111, s28 Q-016, fc Q-045 (fence open at EOF) | unrecognized / unrecognized / keep | skip ×3 | unrec / unrec / keep (skip by design) |
| fc29 Q-112, api P11, C7 (fenced `### other`, `### example`, bare `### Q-019`) | unrecognized ×3 | drop / keep / keep | drop / keep / keep |
| C8 fenced `### Q-019 · quoted`, then `[1]` | unrecognized | unrecognized | keep (fail-closed loss, by design: questions.sh splits there) |
| api P1 / P1b / P2 / P3 | drop / drop / drop / unrecognized | keep ×4 | keep |
| brief N1 / N2 / N3 | done ×3 | open ×3 | open |
| brief N4 (4-space lines around `Status: done`) | open | done | done |
| sec29 P3, fact-check probe 6 (archive split, one) | `done Q-018` / skips | skip for every ID | skip |
| s28 F1 forged Q-018 / Q-023, fc Q-037, api P8 | skip (fenced) | skip (fenced) | skip |
| H1–H7, Q-005–Q-007, Q-039–Q-041 (header gate) | unchanged | unchanged | as pass 29 F5 (Informational) |
| Q-001–Q-004, Q-010–Q-012, Q-019/020/024, Q-033, Q-044, Q-104, Q-113/114, C11–C14 | keep/drop as CommonMark | same | same |

Every shape pass 29 reported now reads as CommonMark does or skips. The new wrong readings are F1's and F2's shapes, plus F3's even-split case.

## Untested bypass candidates

- A nested-list opener indented 4 or more spaces under an earlier item (`- a` / `    - ```` `). `opens()` rejects it at `i > 3`, while CommonMark opens a fence. Not run.
- `- <tab>````: the code gives fcol 3, while CommonMark's content column is 4. Only the closer bound would differ by one. Not run as a decision case.
- Blockquote fences with lazy unprefixed lines (C12 ran, and CommonMark and the code agree), and setext or HTML blocks other than `<pre>`: not run.
- `questions.sh archive` where an OPEN quoted copy of an ANSWERED real entry's heading sits in the live file: carried over from pass 29, not run.
- gawk and busybox awk are not installed. Every result is mawk 1.3.4's.
- Entries written after 35987c1 are not covered by the real-ID run.

Because of F1–F3 and these candidates, neither fence reader nor the never-closed skip appears in the Endorsement Claims.

## Endorsement Claims

- **Claim:** `--check-answer` output on every real ID is identical at 38578a9 and f4d27d2:
  - 102 IDs at 35987c1 (3 done, 19 drop, 26 keep, 13 open, 41 unrecognized);
  - 98 at f4d27d2;
  - 99 on `/workspace` main.

  Every real questions file ends outside a fence (1/1 and 9/9 opens/closes). None holds an indented or list-marker fence-shaped line, and none holds a fenced `### Q-` line.
  **Location:** `scripts/dev-cycle.sh:356-449`
  **Evidence:** executed
  **Verified:** `probe1.log`; `diff ans-old-*.log ans-new-*.log` was empty for all three sources.
  **Not verified:** entries written after 35987c1, and any future archive of a fenced heading (F3).
  **route: code-fact-check**
- **Claim:** The A gates hold at f4d27d2:
  - bats 48/48;
  - `hermeticity-lint --root .` exits 0;
  - shellcheck on `scripts/dev-cycle.sh` is clean;
  - `--help` (`sed -n '2,67p'`) prints 66 lines ending at the Exit paragraph. Line 67 is its last comment line, and line 68 is blank.

  **Location:** `scripts/dev-cycle.sh:2-67`, `:131`
  **Evidence:** executed
  **Verified:** `bats.log`, `lint.log`, `probe1.log`.
  **Not verified:** shellcheck on the bats file, and the full repo suite.
  **route: code-fact-check**
- **Claim:** Under mawk 1.3.4 20200120, `match()` with the marker regex sets `RLENGTH` to the marker plus its following blanks. The resulting `fcol` values:
  - 0, 3, 2 and 3 for ```` ``` ````, `   ````, `- ```` and `1. ````;
  - 4 for `10) ```` and for `-   ````;
  - 5 for `   - ````;
  - 2 for `-<tab>````.

  A 4-space line, `+````, `- - ```` and ```` ```a`b ```` do not open.
  **Location:** `scripts/dev-cycle.sh:266-275`
  **Evidence:** executed
  **Verified:** `probe4.log` (opens() cut from f4d27d2 and run alone).
  **Not verified:** gawk and busybox awk, and `RSTART`/`RLENGTH` interplay with `option()`'s own `match()` (by reading, they never interleave within one record).
- **Claim:** Merge 35987c1's `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats` and `scripts/questions.sh` blobs equal f4d27d2's, and its `skills/dev-cycle/SKILL.md` equals a7dfc0c's.
  **Location:** merge 35987c1
  **Evidence:** executed
  **Verified:** `git rev-parse <commit>:<path>` for each (`probe1.log`).
  **Not verified:** other paths in the merge.
  **route: code-fact-check**
- **Claim:** B's orphan rule, In flight membership and slot definition name the same set ("the glob prints `ok` for … or this cycle wrote"). The final-message paragraph lists `closed/` briefs that read `open` or `new`.
  **Location:** `skills/dev-cycle/SKILL.md:84-95`, `:269-272`, `:369-375`
  **Evidence:** read-static
  **Verified:** the three sentences at a7dfc0c, read whole with check 1–3 (`:273-312`).
  **Not verified:** how an agent orders the orphan rule against check 1 within one cycle, and the duplicate-name edge (F5).

## Primitive sweep

Primitive: process exec (`git`/`awk` argv) on values from repo text, in the changed units. This round changes no exec site. Only the awk program text and messages change.

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:295` `git cat-file -t "$MAIN_SHA:$a"` | S2/S4 path | `pathform` + brief regex + `blocker`, hash prefix | cleared: argv only |
| `scripts/dev-cycle.sh:299` `git cat-file blob … \| awk "$FENCE_AWK"'…'` | S2 blob | same; S5 program | cleared as exec; F1/F2 are reader logic |
| `scripts/dev-cycle.sh:311-312` `git log -1 … -G'^Status: ' "$MAIN_SHA" -- "$a"` | S2 path | same, after `--` | cleared (unchanged) |
| `scripts/dev-cycle.sh:439` `awk -v id="$a" "$FENCE_AWK$ANSWER_AWK" "$f"` | S1 file, ID | ID `^Q-[0123456789]+$`; S5 programs; fixed file names | cleared as exec; F1–F4 are logic |
| SKILL `:280-282` `git mv` of a brief to `closed/` | S4 path | `--check-path` ok + `--check-write` on the destination | cleared (unchanged); F5 is the duplicate-name edge |

No eval, deserialization, SQL or HTML sinks are in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | `closes()`: `fcol + 3` for a no-marker opener and tab-blind indentation. C2d gives a wrong keep and a brief wrongly done, both regressions vs 38578a9. C18 gives a wrong drop and C1e a brief wrongly done | Low | B1, B2 | `scripts/dev-cycle.sh:274-280`, comment `:259-261` | High (code) / Med-High (CommonMark) |
| F2 | `opens()` accepts marker + 5 spaces, 10-digit ordinals and `<pre>` contents; wrong keep (C3/C4/C6) | Low | B1, B2 | `:266-275` | High / Med-High |
| F3 | Never-closed skip misses even flips; a double archive split brings back `done Q-018`; comment `:362-365` overstates | Low | B1 | `:427-432`, `:362-365`; questions.sh `:161-368` | High |
| F4 | `spaces()` walks every leading space; about 5× on all-space files | Informational | B1 | `:264`, `:267`, `:277` | High |
| F5 | B fixed; the duplicate name in `briefs/` and `closed/` is unaddressed | Informational | B4 | SKILL `:93-95`, `:280-282` | Medium |

## Overall Assessment

The pass-29 targets are fixed as executed:
- every pass-29 fence shape (security N1–N4, Q-031/Q-032; fact-check Q-101–Q-105; api P1–P3) now reads as CommonMark does or skips;
- the single archive split (security P3, fact-check probe 6) is a whole-file skip;
- a fenced non-Q heading no longer ends the entry;
- the help range is right, bats is 48/48, lint and shellcheck are clean, and every real ID reads unchanged;
- on B, the orphan rule covers every listed brief in any state, and the final message names the `closed/` open/new briefs.

What remains is three Low findings in the same fence class:
- **F1** is the one that matters. The new closer bound is measured from the fence, not its container, and it ignores tabs. C2d is built from plain fence lines and leaves both readers balanced, yet it reads a quoted `keep` and a quoted brief `done` that 38578a9 read correctly.
- **F2** lists opener shapes that were never handled.
- **F3** shows that the END skip catches only odd flips. An even number, from two archive splits or two hand-written divergences, slips through.

None gives a party a capability it lacks: every decisive case needs quoted text that its author could have written as a real line. So nothing is Medium or above. Still, F1 and F2 break the brief's own criterion: never a wrong keep/drop/done. The issues are fixable in place and none is architectural.

The single most useful change has two parts. First, fix F1's closer bound: indentation at most 3 for a no-marker opener, and tabs counted to the next multiple of 4. Second, extend the skip: any closer-shaped line the two rules disagree on, and any fenced `### Q-` line, makes the file a skip. That second part also contains F3 at no cost to the real files.

No further findings within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

Saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass30.md`, first line `Commit: f4d27d2 (A) / a7dfc0c (B)`. It follows the security-reviewer structure:
- header;
- Trust Boundary Map and S-table;
- Findings, each with Severity, Location, Evidence (verbatim), Confidence and Legibility-target;
- Untested bypass candidates;
- Endorsement Claims, with `route: code-fact-check` on claims that could anchor a rubric row;
- Primitive sweep, Summary Table and Overall Assessment.

As in pass 29, a probe-rerun table is added. The brief's attack list was covered:
- pass 29's fence probes rerun against the bounded opener and closer (rerun table, F1, F2);
- the never-closed whole-file skip against questions.sh archive's split, single and double (F3);
- the Q-heading-only entry end (rerun rows Q-112, P11, C7, C8);
- `match()`/`RLENGTH` under mawk (endorsement 3);
- all real IDs (endorsement 1);
- the help range `2,67p` (endorsement 2);
- commits e2f2d54/f4d27d2 and merge 35987c1 (endorsement 4);
- the orphan rule, the In flight wording and the final-message list at a7dfc0c (F5, endorsement 5).

Nothing was committed.
