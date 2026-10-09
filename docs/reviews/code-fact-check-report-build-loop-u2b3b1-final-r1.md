Commit: f56ba3f5

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b3b1 (branch feat/build-loop-u2b3b1)
**Scope:** `git diff main...HEAD` at f56ba3f5 (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md, docs/working/plan-build-loop-handoff.md line 204, the three test files, commit messages of 8ed86432, 1ece139d, f56ba3f5), plus one unchanged plan line (301) that describes the scoped code
**Checked:** 2026-10-09
**Total claims checked:** 32
**Summary:** 26 verified, 2 mostly accurate, 1 stale, 1 incorrect, 2 unverifiable

Replicate fc-r1 (k=3, final confirming pass). Hallucination log `docs/reviews/hallucination-patterns.md` consulted: no claim below matches a logged pattern (every symbol named in the diff greps to a definition).

Execution logs (all under `/tmp/claude-1000/-workspace/f2c3719b-892d-4844-84dc-9c1b5883d0c4/scratchpad/u2b3b1-final/fc-r1/`, abbreviated `$S/` below). All exit 0.

- **E1** suites: `LC_ALL=C.UTF-8 TMPDIR=$(mktemp -d /tmp/fc-r1-XXXX) bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/scripts/utility-smoke.bats`; cwd the worktree; 2026-10-09T08:09:40Z; `1..220`, 220 `ok`, no `not ok`. Output `$S/suites.log`.
- **E2** `bash $S/probe-rs.sh`: 32 temp repos (cwd `/tmp/fc-r1-rs-*`), one `docs/dev-cycle.md` each, then `resolve_main; reader_settings`, then (when refused) `import_readers` twice and `import_targets`; 2026-10-09T08:12:19Z. Output `$S/probe-rs.log`.
- **E3** `bash $S/probe-doc.sh`: SETTINGS_AWK and reader_settings over the branch tip's `docs/dev-cycle.md` (MAIN_SHA=HEAD), cwd the worktree; 08:12:45Z. Output `$S/probe-doc.log`. Plus `bash scripts/build-loop.sh --settings` in the worktree, 08:14:58Z, `$S/settings.log`.
- **E4** walk measurements over /workspace from /workspace (ROOT_REAL=/workspace; only git listing and reading commands; main == merge-base f8d003c7): `$S/measure.sh` (08:10:50Z), `$S/measure2.sh` (08:11:26Z, timings, load average 2.50), `$S/measure3.sh` (08:11:54Z, `git worktree list` shimmed to the main record for one root), `$S/measure4.sh` (08:14:19Z, 5/10/20 aliases). Outputs `$S/measure.log`, `$S/measure2.log`, `$S/measure3.log`, `$S/measure4.log`.
- **E5** `bash $S/probe-memo.sh`: import_targets after a memoized non-settings refusal; 08:13:12Z. Output `$S/probe-memo.log`.

Measured (E4): no alias: 25 roots, work 347,710 per walk, 128 names, main walk 1.46/1.49 s; one alias (`/home/magfrump/claude-workflows`): 49 roots, work 899,730, 128 names, main walk 1.53/1.46 s, tree walk 2.07/1.30 s; one root: 8,240; 20 aliases: 505 roots, 38,441,630 (77% of 50,000,000).

---

## Claim 1: "The two lines above name the readers the self-merge floor and `--check-fix` model besides this checkout, its registered worktrees and the running session's HOME ... Each is one line of absolute paths separated by single spaces (or `none`), followed by a blank line (outside a code block) or the end of the file. A second copy, a line in any other form, or a file the readers refuse (an unclosed code block, say) fails the import walks, so the floor refuses every path."

**Location:** `docs/dev-cycle.md:28-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the base reader set, the line grammar, the next-line rule (a fenced block between the line and the blank is skipped), and refusal for a second copy, bad form and an unclosed fence; does not establish that every absolute path is accepted (readerform also refuses non-NAMECHARS bytes, `/`, and empty, `.` or `..` parts, which the paragraph does not list).

The base set is ROOT_REAL plus the registry and import_home's home: `rs_r=("$ROOT_REAL" "${rs_w[@]}")` (`scripts/lib/dev-cycle-read.sh:1028`) and `rs_h=(); for p in "$IMPORT_HOME" "$IMPORT_HOME_REAL"` (`:1053`). E2 cases: `next-fence-then-blank` gives `readers 1-roots 0-homes set`, `next-nonblank` and `next-fence-then-text` give `line 1 is followed by a non-blank line outside a fence`, `eof` sets, `double-space`/`trailing-space`/`empty-value` give `is not exactly "Reader roots: PATH ..." with single spaces`, `second-copy-bold` gives `more than one line starts "Reader roots:" (lines 1 and 3)`, `unclosed-fence` gives `the code fence opened at line 3 ... is never closed`. Each refused case printed `import_readers rc=1`, `again rc=1`, `import_targets rc=1`. Floor refusal of every path: each branch of floor returns 0 and the walk branch words `TRUTH_WHY == walk` (`scripts/lib/dev-cycle-read.sh:1415-1418`); E1's floor assertion `want docs/other.md "the reader settings of docs/dev-cycle.md cannot be used (more than one line starts ...` passed.

**Evidence:** `docs/dev-cycle.md:28-34`, `scripts/lib/dev-cycle-read.sh:593-635`, `scripts/lib/dev-cycle-read.sh:1010-1058`, `scripts/lib/dev-cycle-read.sh:1405-1420`, `$S/probe-rs.log`, `$S/suites.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "Only the default branch's copy is read (`scripts/build-loop.sh --settings` prints its `readers` line)."

**Location:** `docs/dev-cycle.md:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reader_settings reading `$MAIN_SHA:docs/dev-cycle.md` and --settings printing the fifth line; does not establish which commit a redirected origin/HEAD makes "the default branch" in dev-cycle.sh (override-log row, Q-103 residual).

main_file reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:544`). In the worktree, whose tip has the two lines while main does not, `--settings` printed `readers none: no line starts "Reader roots:" or "Reader homes:"` (E3, `$S/settings.log`); the E1 test "Only main's commit decides: a loop's branch and the working tree are ignored" passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:535-550`, `scripts/build-loop.sh:741`, `$S/settings.log`, `$S/suites.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: No prose line of docs/dev-cycle.md is counted as a copy by SETTINGS_AWK's letters-only prefix rule (brief item 7; test comment "no prose line read as a copy")

**Location:** `docs/dev-cycle.md:24-35`, `test/scripts/build-loop-read.bats:77`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch tip's docs/dev-cycle.md for all five keys; does not establish it for later edits of the file.

E3 printed one record per key with count 1: `roots 1 24 0 1	Reader roots: /home/magfrump/claude-workflows`, `homes 1 26 0 1	Reader homes: /home/magfrump`, `policy 1 7 0 1	Build-loop policy: review (interim; Q-103)`, and reader_settings gave `readers 1-roots 1-homes set`. The paragraph's first words (`The two lines above`) fold to letters that start neither `readerroots` nor `readerhomes`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:556-573`, `$S/probe-doc.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "(U2b3b1) `readers N-roots M-homes set|none|malformed: WHY` (the `Reader roots:` and `Reader homes:` lines of `docs/dev-cycle.md`)"

**Location:** `docs/working/plan-build-loop-handoff.md:204`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three line shapes reader_settings assigns; does not establish the WHY texts.

`READERS_LINE="readers malformed: $why; both import walks fail"` (`scripts/lib/dev-cycle-read.sh:630`), `READERS_LINE='readers none: no line starts ...'` (`:633`), `READERS_LINE="readers $nr-roots $nh-homes set: $f on the default branch"` (`:634`), and `readers none: no $f on the default branch` (`:602`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:597-635`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5a: "build-loop.sh and dev-cycle.sh both call it once main is found by name (H4; without main by name there is no settings source, so the lists stay empty)."

**Location:** `docs/working/plan-build-loop-handoff.md:301` (unchanged on the branch; it describes the scoped function)
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-main-by-name behaviour of reader_settings at f56ba3f5; does not establish anything about the rest of the plan bullet beyond Claim 5b.

Since 1ece139d, no main by name fails closed rather than leaving the lists empty and silent:

```bash
# scripts/lib/dev-cycle-read.sh:597-600
  if ! main_by_name; then
    IMPORT_READER_WHY="no default branch was found by name, so its reader settings cannot be read"
    READERS_LINE="readers malformed: $IMPORT_READER_WHY; both import walks fail"; return 0
  fi
```
(excerpt ends :600; enclosing reader_settings() continues to :635 — read)

E2 `no-main-by-name` printed that WHY and `import_readers rc=1`. Also, dev-cycle.sh calls it whether or not main was found by name (`resolve_main || [[ -n "$CHECK" ]] || {...}` then `reader_settings`, `scripts/dev-cycle.sh:192-194`). The plan line should say the lists stay empty and IMPORT_READER_WHY is set, so both walks fail.

**Evidence:** `docs/working/plan-build-loop-handoff.md:301`, `scripts/lib/dev-cycle-read.sh:593-600`, `scripts/dev-cycle.sh:192-194`, `$S/probe-rs.log`
**Legibility-target:** for-author

---

## Claim 5b: "import_readers caches a refusal (D7), refuses a control byte in a caller path, and re-spells every registered worktree ..."

**Location:** `docs/working/plan-build-loop-handoff.md:301` (unchanged on the branch)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which function refuses control bytes in caller paths; does not dispute the D7 caching or G8 re-spelling parts (both verified in Claims 21-23), nor that reader_settings' paths can never carry one.

import_readers refuses only a newline (plus relative and `/`): `[[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1` (`scripts/lib/dev-cycle-read.sh:1038`). The control-byte refusal is readerform's, in reader_settings: `[[ "$1" == /?* && "$1" =~ ^[$NAMECHARS]+$ ]] || return 1` (`:579`). A caller that sets IMPORT_READER_ROOTS directly (as the tests' `T_READER_ROOTS` does) with a CR passes import_readers. The precise text is "reader_settings refuses a control byte in a caller path (readerform)". Out-of-diff, low impact, because contract item 9 routes callers through reader_settings.

**Evidence:** `scripts/lib/dev-cycle-read.sh:574-580`, `scripts/lib/dev-cycle-read.sh:1034-1040`
**Legibility-target:** for-author

---

## Claim 6: "--settings  five lines from the default branch's commit"

**Location:** `scripts/build-loop.sh:11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count and order; does not establish each line's content beyond Claim 7.

`printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE" "$READERS_LINE"` (`scripts/build-loop.sh:741`); E3's run printed five lines; E1's renamed test "--settings prints its five lines in order" passed.

**Evidence:** `scripts/build-loop.sh:739-742`, `$S/settings.log`, `$S/suites.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "readers N-roots M-homes set|none|malformed: WHY ... Each is one line, single spaces, the next line outside a fence blank or the end; a PATH is absolute, not / alone, of letters, digits and . _ - / with no empty, . or .. part, listed once. none: no file or no such line. malformed (a second copy, a bad line, or a file not read) fails both walks, so the floor refuses every path; its WHY ends "; both import walks fail"."

**Location:** `scripts/build-loop.sh:43-53`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every rule listed (E2: 32 cases incl. CRLF, fenced copy, case-differs, indented, tab, `~`, glob, `//a`, `/a/`, duplicates, master as main); does not establish that "none" is printed for an explicit `...: none` line (it prints `0-roots 0-homes set`, which the header does not claim otherwise; override-log Won't-Fix row).

E2 outputs match each rule (e.g. `dup` → `line 1 lists entry 3 twice; both import walks fail`; `absent-file` → `readers none: no docs/dev-cycle.md on the default branch`; `no-lines` → `readers none: no line starts ...`; `roots-bad-homes-good` → malformed with both lists empty). "its WHY ends" refers to the printed line: IMPORT_READER_WHY itself does not carry the suffix, only `READERS_LINE="readers malformed: $why; both import walks fail"` (`scripts/lib/dev-cycle-read.sh:630`).

**Evidence:** `scripts/build-loop.sh:43-53`, `scripts/lib/dev-cycle-read.sh:574-635`, `$S/probe-rs.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "The reader lists both import walks take, from main's settings (the lib's caller contract item 9), before any walk; --settings prints its line. Not read_settings below: without this call the walks model no host reader."

**Location:** `scripts/build-loop.sh:304-307`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call's position (after `main_by_name || exit 1`, before any mode runs) and the fail-open consequence of omitting it; does not establish a guard against omission (override-log row, architecture F2).

Sourcing clears the lists: `IMPORT_ROOTS=""; ... IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""` (`scripts/lib/dev-cycle-read.sh:1002`) and `READERS_LINE=""; IMPORT_READER_WHY=""` (`:591`), so with no call the walks see empty lists and no WHY. The call follows `main_by_name || { echo ...; exit 1; }` (`scripts/build-loop.sh:302`), so no-main cannot reach it here.

**Evidence:** `scripts/build-loop.sh:295-307`, `scripts/lib/dev-cycle-read.sh:591`, `scripts/lib/dev-cycle-read.sh:1002`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "The walk also models the host readers the default branch's docs/dev-cycle.md names ("Reader roots:", "Reader homes:"; see build-loop.sh --settings), and fails when those lines are malformed or no default branch is found by name."

**Location:** `scripts/dev-cycle.sh:56-60`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the modelled readers and the two named failure causes; does not establish anything beyond the omitted third cause below.

Both named causes hold (E1 dev-cycle.bats test "refuses every path on a malformed line or with no main by name" passed). The text omits the third cause the code has: a docs/dev-cycle.md that main_file refuses (an unclosed fence anywhere in the file, a symlink, a NUL line) also sets IMPORT_READER_WHY (`why="$FILE_WHY"`, `scripts/lib/dev-cycle-read.sh:603`; E2 `unclosed-fence`). That is not "those lines are malformed" on a plain reading; build-loop.sh's header words it "malformed (a second copy, a bad line, or a file not read)". Tighten to "malformed (or the file is not read)".

**Evidence:** `scripts/dev-cycle.sh:56-60`, `scripts/lib/dev-cycle-read.sh:601-603`, `$S/probe-rs.log`, `$S/suites.log`
**Legibility-target:** for-author

---

## Claim 10: check_fix's new walk-failure message and the comment at its reader_settings call ("without main found by name the walk fails closed")

**Location:** `scripts/dev-cycle.sh:186`, `scripts/dev-cycle.sh:192-194`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message on a refused-settings walk failure and the no-main fail-closed path for --check-fix; does not establish dev-cycle.sh's behaviour under a redirected origin/HEAD (override-log row).

`if [[ "$TRUTH_WHY" == walk && -n "$IMPORT_READER_WHY" ]]; then echo "skip $a: the reader settings of docs/dev-cycle.md cannot be used ($IMPORT_READER_WHY), ...` (`scripts/dev-cycle.sh:186`). E1's assertion `"skip docs/notes.md: the reader settings of docs/dev-cycle.md cannot be used (no default branch was found by name"*` (after `git branch -m main trunk`) passed.

**Evidence:** `scripts/dev-cycle.sh:176-194`, `test/scripts/dev-cycle.bats:1407-1424`, `$S/suites.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "Both walks also read the repository's worktree registry (import_readers), and reader_settings reads docs/dev-cycle.md from the default branch's commit."

**Location:** `scripts/lib/dev-cycle-read.sh:42-43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the read source; does not establish which branch counts as default (resolve_main).

`main_file "$f" "$SETTINGS_AWK"` with `f=docs/dev-cycle.md` (`scripts/lib/dev-cycle-read.sh:594,601`) reads `git cat-file blob "$MAIN_SHA:$f"` (`:544`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:535-550`, `scripts/lib/dev-cycle-read.sh:593-601`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: Contract item 9: "Call reader_settings after sourcing the lib (which clears the reader lists) and resolve_main, before a decision's first walk: it sets IMPORT_READER_ROOTS and IMPORT_READER_HOMES from main's docs/dev-cycle.md (host spellings of the main worktree and host HOMEs), or IMPORT_READER_WHY, which fails both walks; both scripts call it."

**Location:** `scripts/lib/dev-cycle-read.sh:86-91`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the clearing on source, what reader_settings sets, WHY failing both walks, and the two call sites; does not establish enforcement for a third caller (none exists: grep shows only `scripts/build-loop.sh:307` and `scripts/dev-cycle.sh:194` outside tests).

Clearing: `:591`, `:1002`. Walks fail on WHY: `[[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1` (`:1020`), and both walks call `import_readers || { ...=error; return 1; }` (`:1181`, `:1231`). E2 refused cases: `import_readers rc=1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:86-91`, `scripts/lib/dev-cycle-read.sh:1020`, `scripts/lib/dev-cycle-read.sh:1181`, `scripts/lib/dev-cycle-read.sh:1231`, `$S/probe-rs.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: SETTINGS_AWK comment: "One pass over docs/dev-cycle.md (read_settings, reader_settings): per key, how many lines start with it once all but letters is dropped and case folded (best effort), the first two line numbers, whether the next unfenced line after the first is blank or the end (NEXT 1), and the first line"

**Location:** `scripts/lib/dev-cycle-read.sh:551-554`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record shape and the five keys; does not establish that markup adding letters cannot hide a copy (the comment says best effort).

`s = tolower($0); gsub(/[^a-z]/, "", s)` and `index(s, "readerroots") == 1` (`:561-565`); `print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) " " nx[k] "\t" t[k]` (`:572`). E3 printed records in that shape; both callers use it (`scripts/build-loop.sh:356`, `scripts/lib/dev-cycle-read.sh:601`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:551-573`, `$S/probe-doc.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "readerform PATH: a path the reader settings may name: absolute, of NAMECHARS alone (so no blank or control byte ...), not / alone, with no empty, . or .. part."

**Location:** `scripts/lib/dev-cycle-read.sh:574-576`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers readerform's accepted set; does not establish refusal of control bytes for lists set without reader_settings (see Claim 5b).

`[[ "$1" == /?* && "$1" =~ ^[$NAMECHARS]+$ ]]` and the per-part loop `[[ -n "$c" && "$c" != . && "$c" != .. ]]` (`:579-580`), NAMECHARS `'abc...XYZ0123456789._/-'` (`:201`). E2: `relative`, `slash-alone`, `dotdot`, `dot`, `dslash`, `trailing-slash`, `tilde`, `tab`, `glob` all refused.

**Evidence:** `scripts/lib/dev-cycle-read.sh:201`, `scripts/lib/dev-cycle-read.sh:574-580`, `$S/probe-rs.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: reader_settings comment: "(host spellings of the main worktree, the first git worktree list entry) ... each one line as "Self-merge never:" is, each PATH in readerform, listed once. ... no file or line adds no reader. A file main_file refuses, a second copy, a bad line or no main found by name (i1 security F1) sets IMPORT_READER_WHY, which fails both walks. Call it in the caller's shell once main is resolved; a caller that never calls it models no host reader (override row)."

**Location:** `scripts/lib/dev-cycle-read.sh:582-590`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed refusal cause and the no-reader cases; does not establish that "as Self-merge never: is" extends to the entry form (never's entries are globs, these are readerform paths, which the same sentence states).

Per-cause E2 results as in Claims 1 and 7; no-main: `no-main-by-name` → WHY set; absent file and no line → both lists empty, WHY empty. "Never calls it" → lists cleared on source (`:591`, `:1002`). The override row exists (override-log, 2026-10-09 row "A caller that walks without calling reader_settings ...").

**Evidence:** `scripts/lib/dev-cycle-read.sh:582-635`, `docs/reviews/override-log.md` (last 8 rows), `$S/probe-rs.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: References retargeted from U2b3b to U2b3b2 ("U2b3b2's outside starts", "a start file only another registered checkout holds (U2b3b2)", "the walks read the gate's own checkout only; U2b3b2") and "(reader_settings names the host's)"

**Location:** `scripts/lib/dev-cycle-read.sh:721-722`, `scripts/lib/dev-cycle-read.sh:805-808`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the plan names U2b3b2 with those items and that reader_settings supplies host readers; does not establish U2b3b2's eventual design.

The plan's `**U2b3b2, the outside starts** (part a, C1, G9, H2, H5)` bullet names "each reader home's ... instruction file" and "Other roots' checkout-only starts are the C1 seeds" (`docs/working/plan-build-loop-handoff.md:302`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:302`, `scripts/lib/dev-cycle-read.sh:721-722`, `scripts/lib/dev-cycle-read.sh:805-808`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "/workspace's walks spend about 350,000 each over its 25 reader roots and 870,000 over 49 (one host alias), 8,200 with one (2026-10-09)."

**Location:** `scripts/lib/dev-cycle-read.sh:740`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three work figures over /workspace at main f8d003c7 with today's checkout and registry; does not establish the figures' stability as the registry or checkout changes.

Measured (E4): 347,710 at 25 roots (-0.7%), 8,240 with one root (+0.5%), but 899,730 at 49 roots, 3.4% above "about 870,000" (both walks agree; repeated twice). Root counts match. Precise version: "about 900,000 over 49".

**Evidence:** `scripts/lib/dev-cycle-read.sh:740`, `$S/measure.log`, `$S/measure2.log`, `$S/measure3.log`
**Legibility-target:** for-author

---

## Claim 18: "Roots are about (1 + C) times the worktrees for C host aliases (G8): with one, near 285 worktrees (49 roots here: 1.5 s per walk; U2b3b1 i1 performance F1)."

**Location:** `scripts/lib/dev-cycle-read.sh:745-746`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the (1 + C) multiplier, 49 roots, the 1.5 s main walk and the 285-worktree limit by extrapolation; does not establish wall time on other hosts or under other load (the tree walk took 1.30-2.07 s here).

Multiplier: 25 registered entries become 49 roots with one alias (24 beneath /workspace re-spelled plus the alias), 145/265/505 roots with 5/10/20 aliases (E4). The 20-alias run spent 38,441,630, 77% of IMPORT_WORK_MAX; quadratic extrapolation gives 505 x sqrt(50,000,000 / 38,441,630) ≈ 576 roots, about 288 worktrees with one alias, consistent with "near 285". Main walk with the alias: 1.53 s and 1.46 s (load average 2.50).

**Evidence:** `scripts/lib/dev-cycle-read.sh:740-746`, `scripts/lib/dev-cycle-read.sh:1023-1032`, `$S/measure2.log`, `$S/measure4.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: import_targets: "import_readers' IMPORT_ROOTS and IMPORT_HOMES when its memo key is current (else ROOT_REAL alone and import_home's home: a call outside a walk; either fails on refused settings)"

**Location:** `scripts/lib/dev-cycle-read.sh:765-767`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both branches with IMPORT_READER_WHY set; does not establish the memo-current non-settings refusal case beyond E5 (which also fails: empty roots give rc=1).

`[[ -z "$IMPORT_READER_WHY" ]] || return 1` (`:1065`) runs after either root choice (`:1064`). E1's `IMPORT_READER_WHY=x; ... import_targets ""` → `rc=1` passed (fallback branch); E2's refused cases ran import_targets after a memoized refusal → `rc=1`. E5: after a memoized refusal from a relative caller root (WHY empty) import_targets still returned `rc=1`, while a call before any walk printed names `rc=0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1059-1086`, `test/scripts/build-loop-check.bats:1880-1882`, `$S/probe-rs.log`, `$S/probe-memo.log`, `$S/suites.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: import_readers: "IMPORT_ROOTS holds ROOT_REAL, every path git worktree list registers ..., each IMPORT_READER_ROOTS entry and, beneath each such entry, every registered worktree that lies beneath the main worktree (the first record), re-spelled there"

**Location:** `scripts/lib/dev-cycle-read.sh:973-978`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the root list's composition; does not establish behaviour for a bare main repository (where git's first record is the bare dir), which neither caller supports.

```bash
# scripts/lib/dev-cycle-read.sh:1026-1032
  [[ ${#rs_w[@]} -eq 0 ]] || rs_m="${rs_w[0]}"
  [[ -z "$IMPORT_READER_ROOTS" ]] || mapfile -t rs_c <<<"$IMPORT_READER_ROOTS"
  rs_r=("$ROOT_REAL" "${rs_w[@]}")
  for rs_cr in "${rs_c[@]}"; do
    [[ -n "$rs_cr" ]] || continue
    rs_r+=("$rs_cr"); for p in "${rs_w[@]}"; do [[ -z "$rs_m" || "$p" != "$rs_m"/* ]] || rs_r+=("$rs_cr${p#"$rs_m"}"); done
  done
```
(excerpt ends :1032; enclosing import_readers() continues to :1058 — read)

E1's "a caller root re-spells the worktrees registered beneath the main worktree" passed (walk from ../gate, a worktree outside main). E4: 49 roots for 25 entries plus one alias.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1010-1058`, `test/scripts/build-loop-check.bats:1885-1896`, `$S/measure.log`, `$S/suites.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: "It returns 1 when IMPORT_READER_WHY is set (reader_settings refused the settings), import_home or the listing fails, ..." and the inline "reader_settings' refusal fails the walks."

**Location:** `scripts/lib/dev-cycle-read.sh:987-989`, `scripts/lib/dev-cycle-read.sh:1018-1020`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the WHY refusal; does not establish the pre-existing refusal causes (unchanged on the branch).

`[[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1` (`:1020`); E2 refused cases `import_readers rc=1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1020`, `$S/probe-rs.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: "The result, a refusal included (but not an import_home failure, which returns first), is memoized in IMPORT_READERS_DONE, keyed on ROOT_REAL, HOME, the caller's two lists and IMPORT_READER_WHY" and the inline "A refusal is memoized too, as an empty IMPORT_ROOTS (a result never is: ROOT_REAL leads it), so a refusing decision lists the registry once"

**Location:** `scripts/lib/dev-cycle-read.sh:994-997`, `scripts/lib/dev-cycle-read.sh:1014-1016`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the memo key parts, refusal memoization (WHY, relative root) and the import_home exception; does not establish memo behaviour across import_reset (contract item 4, unchanged).

`import_home || return 1` precedes `import_readers_key` (`:1012-1013`); the key holds `e="$IMPORT_READER_WHY"` (`:1007`); `if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi` then `IMPORT_READERS_DONE="$IMPORT_READERS_KEY"; IMPORT_ROOTS=""` before any refusal (`:1016-1017`). E1's "a refused reader set is memoized, so a decision lists the worktree registry once" (one `worktree` call logged for three walk calls) passed; E2 `again rc=1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1004-1020`, `test/scripts/build-loop-check.bats:1898-1909`, `$S/suites.log`, `$S/probe-rs.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: "The first record is the main worktree, which each caller root spells on a host, so the worktrees registered beneath it are spelled beneath each caller root there too"

**Location:** `scripts/lib/dev-cycle-read.sh:1023-1025`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's porcelain order (main worktree first) as observed and the re-spelling; does not establish that the host actually has those paths.

`rs_m="${rs_w[0]}"` (`:1026`). In /workspace the first porcelain record is `/workspace` (25 entries); in the E1 test run from `../gate`, ROOT_REAL is the gate but `rs_m` is the main checkout, and the re-spelled `/host/cw/.claude/wt-b/docs/n.md` import was found.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1023-1032`, `test/scripts/build-loop-check.bats:1885-1896`, `$S/measure.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: floor's new walk-failure message names the reader settings

**Location:** `scripts/lib/dev-cycle-read.sh:1416`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message when WHY is set; does not establish U2c's caller printing it (not built).

`if [[ "$TRUTH_WHY" == walk && -n "$IMPORT_READER_WHY" ]]; then FLOOR_WHY="the reader settings of docs/dev-cycle.md cannot be used ($IMPORT_READER_WHY), so the instruction files could not be walked for @ imports"` (`:1416`); the E1 assertion on that exact text passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1397-1420`, `test/scripts/build-loop-check.bats:1877-1879`, `$S/suites.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: Test helper comment: "T_SETTINGS=1 sets them as the scripts do, with reader_settings."

**Location:** `test/scripts/build-loop-check.bats:17-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers imps and floors calling reader_settings after resolve_main; does not establish identical ordering with the scripts' ROOT_REAL assignment (the helpers set ROOT_REAL after reader_settings, which reader_settings does not read).

`resolve_main || true; [[ -z "${T_SETTINGS:-}" ]] || reader_settings; ROOT_REAL="$(pwd -P)"` (`:24`, `:34`). paraphrased — no quote available because the claim covers absence of a dependency: reader_settings' body (`scripts/lib/dev-cycle-read.sh:593-635`) has no ROOT_REAL reference (grep).

**Evidence:** `test/scripts/build-loop-check.bats:17-35`, `scripts/lib/dev-cycle-read.sh:593-635`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: New and renamed test names and their in-test comments (build-loop-check.bats 3 tests, build-loop-read.bats 1 new + 1 renamed, dev-cycle.bats 1), incl. "The walk, then isimported for each path: three calls of the walk in one decision."

**Location:** `test/scripts/build-loop-check.bats:1851-1909`, `test/scripts/build-loop-read.bats:198`, `test/scripts/build-loop-read.bats:493-532`, `test/scripts/dev-cycle.bats:1407-1424`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each test's body checks what its name states and that all pass; does not establish coverage of build-loop.sh's own reader_settings call in a walk (only its --settings line is tested; the walk path is covered via the lib helpers).

Each name matches its body (read in full): e.g. the working-tree-only `/wt` root leaves `docs/w.md -`; the memo test counts one `worktree` call for walk + two isimported; the dev-cycle test checks two paths, a malformed line and `git branch -m main trunk`. E1: 220/220.

**Evidence:** `test/scripts/build-loop-check.bats:1851-1909`, `test/scripts/build-loop-read.bats:493-532`, `test/scripts/dev-cycle.bats:1407-1424`, `$S/suites.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: 8ed86432: "Suites 220/220 ... 375 code lines against main (the move counted twice)" and "Over /workspace both walks still give 128 names, at 49 roots (was 25)"

**Location:** commit 8ed86432 message
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count at 8ed86432, the 220-test count and names/roots measured today; does not establish that the suites passed at 8ed86432 itself (run here at f56ba3f5 only).

`git diff --numstat main...8ed86432 -- ':(top)' ':(top,exclude)docs/'` sums 295 added + 80 deleted = 375. Test counts at 8ed86432: 117 + 20 + 79 in the three suites, plus fixture-git-env 2 and utility-smoke 2 = 220 (same at f56ba3f5, where E1 ran 220/220). E4: 128 names in both walks at 25 and 49 roots.

**Evidence:** commit 8ed86432, `$S/suites.log`, `$S/measure.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28: 8ed86432: "the main walk takes 1.5 s (was 1.3 s)"

**Location:** commit 8ed86432 message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 1.5 s with-alias figure (reproduced: 1.53 s, 1.46 s); does not establish the 1.3 s baseline, which was not reproduced (1.46 s, 1.49 s at 25 roots here) under this run's load (average 2.50).

The implied cost of the alias (0.2 s) was not observed: with and without the alias the main walk took 1.46-1.53 s. Wall time depends on host load, so the historical baseline cannot be re-checked; a same-run A/B under idle load would be needed.

**Evidence:** `$S/measure2.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29: 8ed86432 Notes: "two keys rather than the plan's one "Reader roots:" line ...; without main found by name the lists stay empty, as there is no settings source."

**Location:** commit 8ed86432 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the note as true of 8ed86432 (plan line 297's single `Reader roots:` line; `if ! main_by_name; then READERS_LINE="readers none: no default branch found by name"; return 0; fi` at 8ed86432's lib :606); does not establish it of f56ba3f5, where 1ece139d replaced the no-main behaviour (Claim 5a).

**Evidence:** `docs/working/plan-build-loop-handoff.md:297`, `git show 8ed86432:scripts/lib/dev-cycle-read.sh` line 606
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: 1ece139d: "with no default branch found by name, reader_settings now sets IMPORT_READER_WHY ...; import_targets refuses while IMPORT_READER_WHY is set, memo or not; the floor and --check-fix name the reader settings ...; the H4 test now checks two paths ... Suites 220/220 ... (397 lines)"

**Location:** commit 1ece139d message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fix as present at f56ba3f5 (f56ba3f5 touches docs/reviews only), the test count and the line count; does not establish the declined findings' override rows beyond their presence in the log's last 8 rows.

`git diff --numstat main...1ece139d -- ':(top)' ':(top,exclude)docs/'` sums 312 + 85 = 397. Fixes: Claims 5a/10 (no main), 19 (import_targets), 10/24 (messages); dev-cycle.bats test checks `docs/notes.md` and `docs/h.md`. E1: 220/220.

**Evidence:** commit 1ece139d, `scripts/lib/dev-cycle-read.sh:597-600`, `scripts/lib/dev-cycle-read.sh:1065`, `test/scripts/dev-cycle.bats:1407-1424`, `$S/suites.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 31: f56ba3f5: "k=1, full panel, at 8ed86432: no red; two ambers acknowledged with revisit triggers; fixes in 1ece139d (lite fix-drift: no findings)."

**Location:** commit f56ba3f5 message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the "no red" and "two ambers" parts against the rubric's status line (they match); does not establish the lite fix-drift result, which has no report file on the branch.

The rubric reads `**Status: 🟡 ITERATION 1 — no red; two ambers (architecture F1, ...; security F1, ...) acknowledged with revisit triggers` (`docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b1.md:5`). paraphrased — no quote available because the claim covers absence of a file: no fix-drift report is among the branch's added `docs/reviews/` files (`git diff --stat main...HEAD`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b1.md:5`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`docs/working/plan-build-loop-handoff.md:301`, unchanged line): attributes the control-byte refusal to import_readers, which refuses only a newline; readerform in reader_settings does it. Say "reader_settings refuses a control byte".

### Stale
- **Claim 5a** (`docs/working/plan-build-loop-handoff.md:301`, unchanged line): "without main by name ... the lists stay empty" predates 1ece139d; now IMPORT_READER_WHY is set and both walks fail.

### Mostly Accurate
- **Claim 9** (`scripts/dev-cycle.sh:56-60`): failure causes omit "the file is not read" (an unclosed fence etc.), which also fails the walk.
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:740`): 49-root figure measures 899,730, not about 870,000 (25-root and one-root figures reproduce).

### Unverifiable
- **Claim 28** (commit 8ed86432): "was 1.3 s" baseline not reproduced under load; needs an idle same-run A/B.
- **Claim 31** (commit f56ba3f5): "lite fix-drift: no findings" has no report on the branch.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report at the output path your role names, structured per your skill, every finding with a verbatim Evidence quote and path:line.
- Answered: yes — all eight brief items checked, each with at least one executed probe or suite run; no claim in the diff is Incorrect or Stale; the two non-verified diff claims are text tightenings.
- Out of scope: the hallucination-pattern log was not updated (the shared brief allows writing only this report; Claim 5b is a misattribution, not a fabricated symbol, so it would not qualify anyway).
- Escalate: plan line 301 (outside the diff) carries the stale no-main sentence and the import_readers control-byte misattribution; a one-line plan edit fixes both and adds no code lines.
- Decisions I made: counted 220 as the three suites plus fixture-git-env and utility-smoke (the only combination matching the checkpoint's suite list); measured the one-root figure over /workspace by shimming `git worktree list` (a fresh clone gives 4,165 and 64 names, a different tree).
