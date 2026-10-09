Commit: f56ba3f5
# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u2b3b1)
**Scope:** `git diff main...HEAD` on `feat/build-loop-u2b3b1` at f56ba3f5 (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md, docs/working/plan-build-loop-handoff.md line 204, test/scripts/build-loop-read.bats, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats) plus the messages of 8ed86432, 1ece139d and f56ba3f5
**Checked:** 2026-10-09
**Total claims checked:** 34
**Summary:** 29 verified, 5 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable
**Commit:** f56ba3f5
**Replication:** k=3 final confirming pass, replicate fc-r2

Hallucination log (`docs/reviews/hallucination-patterns.md`) read. One logged family is relevant: test counts claimed in commit messages ("All 85 tests ... but the suites hold 97", "mode1-equiv 33 ... holds 25"). Both "Suites 220/220" claims were checked against this pattern by counting and running the suites (Claims 31a and 32). They do not match it.

Execution logs are in the role scratch dir `/tmp/claude-1000/-workspace/f2c3719b-892d-4844-84dc-9c1b5883d0c4/scratchpad/u2b3b1-final/fc-r2/` (abbreviated `$S` below):
- `bats.log`: the three changed suites. Command `LC_ALL=C.UTF-8 TMPDIR=$(mktemp -d /tmp/fc-r2-XXXX) bats test/scripts/build-loop-read.bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats`, cwd the worktree, bats exit 0, finished 2026-10-09T01:10:40-07:00. Result `1..216`, 216 `ok`, no `not ok`.
- `bats2.log`: fixture-git-env and utility-smoke. Same form, exit 0, 2026-10-09T01:11-07:00, 4/4 ok.
- `probe1.sh` / `probe1.out`: reader_settings edge cases, import_readers memo, import_targets, and G8 re-spelling. Run in a fresh `mktemp -d /tmp/fc-r2-p1-XXXX` repo with `LC_ALL=C.UTF-8 timeout 120 bash probe1.sh`, cwd `$S`, exit 0, 2026-10-09T01:12:19-07:00.
- `measure.sh` with `measure.out`, `measure2.out`, `measure3.out` and `measure-one.out`: read-only walks over /workspace with ROOT_REAL=/workspace, using the worktree's lib and an `import_work` wrapper that sums the work trailer. Command `LC_ALL=C.UTF-8 timeout 300 bash measure.sh <lib> ""|/home/magfrump/claude-workflows`, cwd `$S` (the script cds to /workspace, branch main, 25 registered worktrees), exit 0, 2026-10-09T01:09:43 to 01:13:27-07:00, load average 1.5 to 2.3. For `measure-one.out`, a `git` shim in `$S/shim` cut `worktree list` down to its first record.

---

## Claim 1: "The two lines above name the readers the self-merge floor and `--check-fix` model besides this checkout, its registered worktrees and the running session's HOME: the host spelling of the main checkout ... and the host's HOME."

**Location:** `docs/dev-cycle.md:28-31`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the root and home sets that import_readers builds from ROOT_REAL, the registry, import_home and the caller lists. It does not establish that build-loop.sh runs the floor today: no script calls `floor` before U2c (see Claim 3).

import_readers builds the roots as `rs_r=("$ROOT_REAL" "${rs_w[@]}")` and appends each caller root (`rs_r+=("$rs_cr")`, `scripts/lib/dev-cycle-read.sh:1028-1031`). The homes are `for p in "$IMPORT_HOME" "$IMPORT_HOME_REAL"` followed by the caller's homes (`:1052-1054`). In probe1 "G8 respell", the roots came out as the checkout, `.claude/wt-x`, `side`, `/host/cw` and `/host/cw/.claude/wt-x`.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:1016-1057`, `$S/probe1.out`

---

## Claim 2: "Each is one line of absolute paths separated by single spaces (or `none`), followed by a blank line (outside a code block) or the end of the file."

**Location:** `docs/dev-cycle.md:31-33`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line shape and next-line rule. It does not establish the path-form rule, which this sentence leaves out.

The line shape and next-line rule match. Probe1 "EOF no newline" gave `readers 1-roots 0-homes set`, "fence then blank" gave `set`, and "next line after a fence" (a fenced block, then `/b`) gave `readers malformed: line 1 is followed by a non-blank line outside a fence`.

A path also has to pass readerform: `[[ "$1" == /?* && "$1" =~ ^[$NAMECHARS]+$ ]]`, with NAMECHARS `'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-'`, and no empty, `.` or `..` part (`scripts/lib/dev-cycle-read.sh:577-580`, `:201`). An absolute host path such as `/home/u/a+b` or `/home/café` therefore fails both walks. The sentence after this one ("a line in any other form ... fails") covers that case only implicitly.

Precise version: "... one line of absolute paths (letters, digits and `. _ - /`, no empty, `.` or `..` part, not `/` alone, each listed once) separated by single spaces ...".

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:201`, `scripts/lib/dev-cycle-read.sh:574-580`, `$S/probe1.out`

---

## Claim 3: "A second copy, a line in any other form, or a file the readers refuse (an unclosed code block, say) fails the import walks, so the floor refuses every path."

**Location:** `docs/dev-cycle.md:33-34` (the same claim is in `scripts/build-loop.sh:51-53`: "malformed (a second copy, a bad line, or a file not read) fails both walks, so the floor refuses every path")
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lib's `floor` function and both walks under a set IMPORT_READER_WHY. It does not establish an effect on `build-loop.sh --check` today: `grep -rn '\bfloor "' scripts/` finds no caller (paraphrased — no quote available because this is an absence of code: the grep returned no matches), and FLOOR_WHY is commented "read by floor's caller (U2c's --check)".

Each refusal sets `why` in reader_settings, then `IMPORT_READER_WHY="$why"` (`scripts/lib/dev-cycle-read.sh:627-629`). import_readers refuses: `[[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1` (`:1020`). truthwalk then returns 0 with `TRUTH_WHY=walk` (`:1365-1368`), so floor sets a FLOOR_WHY for every path that reaches it. Earlier branches already refuse the other paths. The test `build-loop-check.bats:511` asserts `walk failed` and `docs/other.md imported` for a bad line and for a second copy, and the floor's text for the second copy. It passes (bats.log). Probe1 "tree entry" shows a file not read giving `readers malformed: docs/dev-cycle.md is not a regular file on the default branch`.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:600-634`, `scripts/lib/dev-cycle-read.sh:1365-1368`, `scripts/lib/dev-cycle-read.sh:1397-1420`, `test/scripts/build-loop-check.bats:526-536`, `$S/bats.log`, `$S/probe1.out`

---

## Claim 4: "Only the default branch's copy is read (`scripts/build-loop.sh --settings` prints its `readers` line)."

**Location:** `docs/dev-cycle.md:34-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reading through main_file (`git cat-file blob "$MAIN_SHA:$f"`) and the --settings printout. It does not establish which commit MAIN_SHA names under an origin/HEAD redirect in dev-cycle.sh, which override row Q-103 already settles.

main_file reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:544`). `--settings` prints `"$READERS_LINE"` (`scripts/build-loop.sh:741`). The test at `build-loop-read.bats:633-637` (a loop branch and a working-tree copy are ignored) and the test at `build-loop-check.bats:518-523` (a root only the working tree names is not read) both pass.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:534-549`, `scripts/build-loop.sh:739-742`, `$S/bats.log`

---

## Claim 5: (no prose line of docs/dev-cycle.md is counted as a copy by SETTINGS_AWK's letters-only prefix rule; test comment "The host alias and HOME (Q-121, Q-123), and no prose line read as a copy.")

**Location:** `docs/dev-cycle.md:24-35`, `test/scripts/build-loop-read.bats:77-78`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD's docs/dev-cycle.md. It does not establish that future prose stays clear: a line such as "Reader rootstock ..." counts as a copy (probe1).

An awk pass over `git show HEAD:docs/dev-cycle.md` using SETTINGS_AWK's key test (`s = tolower($0); gsub(/[^a-z]/, "", s)` with prefixes readerroots, readerhomes, buildloop and selfmergenever) printed only `7: Build-loop policy: review (interim; Q-103)`, `24: Reader roots: /home/magfrump/claude-workflows` and `26: Reader homes: /home/magfrump`. The test, which copies the real file, asserts `readers 1-roots 1-homes set` and passes. Probe1 "prose line starting Reader roots-like" gave `more than one line starts "Reader roots:" (lines 1 and 3)`, which confirms the rule is letters-only.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:556-572`, `test/scripts/build-loop-read.bats:71-78`, `$S/bats.log`, `$S/probe1.out`

---

## Claim 6: "`--settings` → ... and (U2b3b1) `readers N-roots M-homes set|none|malformed: WHY` (the `Reader roots:` and `Reader homes:` lines of `docs/dev-cycle.md`)."

**Location:** `docs/working/plan-build-loop-handoff.md:204`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three READERS_LINE forms. It does not establish the other four lines' grammar, which this diff does not change.

reader_settings emits `readers $nr-roots $nh-homes set: ...`, `readers none: ...` and `readers malformed: $why; both import walks fail` (`scripts/lib/dev-cycle-read.sh:599, 602, 629, 632-633`). All three appear in probe1.out and in the passing `build-loop-read.bats:599` test.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:596-634`, `$S/probe1.out`, `$S/bats.log`

---

## Claim 7: "--settings  five lines from the default branch's commit"

**Location:** `scripts/build-loop.sh:11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count and order. It does not establish per-line content beyond the readers line.

`printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE" "$READERS_LINE"` (`scripts/build-loop.sh:741`). The test at `build-loop-read.bats:198` asserts 5 lines with `lines[4] == readers *` and passes.

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:739-742`, `test/scripts/build-loop-read.bats:198-202`, `$S/bats.log`

---

## Claim 8: "readers N-roots M-homes set|none|malformed: WHY ... "Reader roots: PATH ..." (host spellings of the main worktree) and "Reader homes: PATH ..." (host homes), or "...: none". Each is one line, single spaces, the next line outside a fence blank or the end; a PATH is absolute, not / alone, of letters, digits and . _ - / with no empty, . or .. part, listed once. none: no file or no such line. ... its WHY ends "; both import walks fail"."

**Location:** `scripts/build-loop.sh:43-53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every rule named. It does not establish that "listed once" compares resolved spellings: `rd_seen` keys on the spelling as written, and a path appearing in both roots and homes is allowed because `rd_seen=()` is reset per key.

The single-space check is `[[ "$t" != "$key "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]` (`scripts/lib/dev-cycle-read.sh:614`). The next-line check is `[[ "${next[$k]}" != 1 ]]` (`:615`). The path form is readerform (`:577-580`). Duplicates are caught by `[[ -n "${rd_seen[$p]-}" ]]` (`:621`). The none cases are `[[ "$FILE_WHY" == absent ]]` (`:602`) and `[[ -z "${cnt[roots]-}${cnt[homes]-}" ]]` (`:633`). A WHY becomes `READERS_LINE="readers malformed: $why; both import walks fail"` (`:630`), and the no-main case also ends that way (`:599`). The fourteen malformed path forms, the seven bad-spacing forms, the duplicate, the markup copy, the continued line and the unclosed fence in `build-loop-read.bats:599-638` all pass. Probe1 adds a fenced block followed by a non-blank line (malformed), end of file (set) and a leading space (malformed).

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:574-634`, `test/scripts/build-loop-read.bats:599-638`, `$S/bats.log`, `$S/probe1.out`

---

## Claim 9: "The reader lists both import walks take, from main's settings (the lib's caller contract item 9), before any walk; --settings prints its line. Not read_settings below: without this call the walks model no host reader."

**Location:** `scripts/build-loop.sh:304-307`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers call order and the no-call consequence. It does not establish a walk in build-loop.sh: none exists until U2c, so "before any walk" holds trivially today.

The call `reader_settings` (`scripts/build-loop.sh:307`) comes after `main_by_name || { ... exit 1; }` (`:302`) and before mode dispatch. With no call, the lists stay as sourcing set them: `IMPORT_READER_ROOTS=""` (the import_readers globals line, "Sourcing the lib clears them", `:984`) and `IMPORT_READER_WHY=""` (`:591`). import_readers then adds no caller root (`[[ -z "$IMPORT_READER_ROOTS" ]] || mapfile -t rs_c ...`, `:1027`).

**Legibility-target:** for-author
**Evidence:** `scripts/build-loop.sh:296-307`, `scripts/lib/dev-cycle-read.sh:590`, `scripts/lib/dev-cycle-read.sh:1014-1033`

---

## Claim 10: "The walk also models the host readers the default branch's docs/dev-cycle.md names ("Reader roots:", "Reader homes:"; see build-loop.sh --settings), and fails when those lines are malformed or no default branch is found by name."

**Location:** `scripts/dev-cycle.sh:56-60`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the modelling and both named failure causes. It does not cover a third cause the sentence leaves out.

Both named causes hold: the `dev-cycle.bats:648` test (bad line; `git branch -m main trunk`) passes. reader_settings also sets IMPORT_READER_WHY when main_file refuses the whole file: `why="$FILE_WHY"` (`scripts/lib/dev-cycle-read.sh:603`), for example on an unclosed fence anywhere in the file or on a non-regular entry (probe1 "tree entry": `readers malformed: docs/dev-cycle.md is not a regular file on the default branch`). That fails --check-fix for every path even when "those lines" are fine. The cross-reference to build-loop.sh --settings, where "malformed" includes "a file not read", supplies the missing case only by indirection.

Precise version: "... and fails when those lines are malformed, the file cannot be read, or no default branch is found by name."

**Legibility-target:** for-author
**Evidence:** `scripts/dev-cycle.sh:53-60`, `scripts/lib/dev-cycle-read.sh:600-604`, `test/scripts/dev-cycle.bats:648-665`, `$S/probe1.out`, `$S/bats.log`

---

## Claim 11: "The reader lists the import walk takes, from main's settings (the lib's caller contract item 9); without main found by name the walk fails closed."

**Location:** `scripts/dev-cycle.sh:192-194`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-fix with no main by name. It does not establish behaviour under an origin/HEAD redirect, which the override row for the Q-103 residual covers.

`if ! main_by_name; then IMPORT_READER_WHY="no default branch was found by name, ..."` (`scripts/lib/dev-cycle-read.sh:597-599`). The test `dev-cycle.bats:661-664` asserts `skip docs/notes.md: the reader settings of docs/dev-cycle.md cannot be used (no default branch was found by name...` and passes. Probe1 "no main by name" printed the matching READERS_LINE.

**Legibility-target:** for-author
**Evidence:** `scripts/dev-cycle.sh:191-194`, `scripts/lib/dev-cycle-read.sh:596-600`, `$S/bats.log`, `$S/probe1.out`

---

## Claim 12: check_fix's new walk-failure message: "skip $a: the reader settings of docs/dev-cycle.md cannot be used ($IMPORT_READER_WHY), so the instruction-file import walk failed; file it instead"

**Location:** `scripts/dev-cycle.sh:186`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message being shown exactly when the walk failed with a WHY set. It does not establish a walk that failed for another reason while a WHY is set; with a WHY set, import_readers always refuses first.

`if [[ "$TRUTH_WHY" == walk && -n "$IMPORT_READER_WHY" ]]` (`scripts/dev-cycle.sh:186`). With a WHY set, import_readers returns 1 at `:1020` before any other walk step, so the cause named is the real one. The dev-cycle.bats test asserts the text and passes.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/dev-cycle.sh:176-190`, `scripts/lib/dev-cycle-read.sh:1020`, `$S/bats.log`

---

## Claim 13: "Both walks also read the repository's worktree registry (import_readers), and reader_settings reads docs/dev-cycle.md from the default branch's commit."

**Location:** `scripts/lib/dev-cycle-read.sh:42-43`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the input list. It does not establish anything about U2b3b2's outside seeds.

`nul_list rs_l git worktree list --porcelain -z` (`:1021`). reader_settings uses `local f=docs/dev-cycle.md` and `main_file "$f" "$SETTINGS_AWK"` (`:594, :601`), and main_file reads `$MAIN_SHA:$f`.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:42-43`, `scripts/lib/dev-cycle-read.sh:594-601`, `scripts/lib/dev-cycle-read.sh:1021`

---

## Claim 14: "9. Call reader_settings after sourcing the lib (which clears the reader lists) and resolve_main, before a decision's first walk: it sets IMPORT_READER_ROOTS and IMPORT_READER_HOMES from main's docs/dev-cycle.md (host spellings of the main worktree and host HOMEs), or IMPORT_READER_WHY, which fails both walks; both scripts call it."

**Location:** `scripts/lib/dev-cycle-read.sh:86-91`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the contract's effect and both callers. It does not establish enforcement: a caller that skips the call fails open, which override row arch i1 F2 settles.

Sourcing sets `READERS_LINE=""; IMPORT_READER_WHY=""` (`:591`) and clears IMPORT_READER_ROOTS and IMPORT_READER_HOMES in the import_readers globals line. reader_settings is called at `scripts/build-loop.sh:307` and `scripts/dev-cycle.sh:194`, both after resolve_main. WHY fails both walks (Claim 3, executed).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:86-91`, `scripts/build-loop.sh:301-307`, `scripts/dev-cycle.sh:191-194`, `$S/bats.log`

---

## Claim 15: "One pass over docs/dev-cycle.md (read_settings, reader_settings): per key, how many lines start with it once all but letters is dropped and case folded (best effort), the first two line numbers, whether the next unfenced line after the first is blank or the end (NEXT 1), and the first line"

**Location:** `scripts/lib/dev-cycle-read.sh:551-554`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the callers and the output record. It does not establish build-loop.sh's handling of the new keys, beyond its suite passing.

The only callers are `main_file "$f" "$SETTINGS_AWK"` at `scripts/build-loop.sh:356` (read_settings) and lib `:601` (reader_settings). The record is printed by `print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) " " nx[k] "\t" t[k]` (`:572`).

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:551-572`, `scripts/build-loop.sh:356`

---

## Claim 16: "readerform PATH: a path the reader settings may name: absolute, of NAMECHARS alone (so no blank or control byte ...), not / alone, with no empty, . or .. part."

**Location:** `scripts/lib/dev-cycle-read.sh:574-576`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers readerform. It does not establish anything about realpath forms, which import_readers handles.

`[[ "$1" == /?* && "$1" =~ ^[$NAMECHARS]+$ ]] || return 1` and `[[ -n "$c" && "$c" != . && "$c" != .. ]] || return 1` (`:579-580`). NAMECHARS holds no blank or control byte (`:201`). The tests covering `/`, `//a`, `/a/`, `/a//b`, `/a/../b`, `/a/./b`, `/..`, a tab and a UTF-8 byte all pass.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:201`, `scripts/lib/dev-cycle-read.sh:577-580`, `test/scripts/build-loop-read.bats:612-618`, `$S/bats.log`

---

## Claim 17: "reader_settings: ... "Reader roots: PATH ..." (host spellings of the main worktree, the first git worktree list entry) ... Sets IMPORT_READER_ROOTS, IMPORT_READER_HOMES and READERS_LINE; no file or line adds no reader. A file main_file refuses, a second copy, a bad line or no main found by name (i1 security F1) sets IMPORT_READER_WHY, which fails both walks. ... a caller that never calls it models no host reader (override row)."

**Location:** `scripts/lib/dev-cycle-read.sh:582-589`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed branch of reader_settings, plus the no-call consequence (Claim 9). It does not establish a fail-closed sentinel, which does not exist and is settled by an override row dated 2026-10-09.

Every branch was exercised in probe1 and the passing tests: absent (`readers none: no docs/dev-cycle.md`), no line (`readers none: no line starts ...`), main_file refusal (tree entry, unclosed fence), second copy, bad line and no main. The override row "A caller that walks without calling reader_settings gets empty reader lists" exists in `docs/reviews/override-log.md`.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:582-634`, `docs/reviews/override-log.md` (2026-10-09 rows), `$S/probe1.out`, `$S/bats.log`

---

## Claim 18: "a parent directory's CLAUDE.md, the user's memory file (known issue A5; U2b3b2's outside starts), nor at a start file only another registered checkout holds (U2b3b2)" and "the walks read the gate's own checkout only; U2b3b2"

**Location:** `scripts/lib/dev-cycle-read.sh:721-722`, `scripts/lib/dev-cycle-read.sh:808`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plan routing. It does not establish that U2b3b2 delivers it.

The plan at `docs/working/plan-build-loop-handoff.md:302` reads: "**U2b3b2, the outside starts** (part a, C1, G9, H2, H5) ... Other roots' checkout-only starts are the C1 seeds." No bare "U2b3b" reference is left in the three scripts (paraphrased — no quote available because this is an absence result: `grep -n "U2b3b\b\|U2b3b[^12]"` returned no matches).

**Legibility-target:** for-author
**Evidence:** `docs/working/plan-build-loop-handoff.md:302`, `scripts/lib/dev-cycle-read.sh:719-722`, `scripts/lib/dev-cycle-read.sh:805-808`

---

## Claim 19a: "/workspace's walks spend about 350,000 each over its 25 reader roots ..., 8,200 with one (2026-10-09)."

**Location:** `scripts/lib/dev-cycle-read.sh:740`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's main and tree walks at main's state at 01:10 local time on 2026-10-09. It does not establish the figures after main changes; they drift with content.

`measure.out` and `measure2.out` (25 roots, no alias) gave `main rc=0 work=347710 names=128` and `tree rc=0 work=347710 names=128`. `measure-one.out` (the shim keeps only the first worktree record, so roots=1) gave `work=8240` for both walks.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:740`, `$S/measure.out`, `$S/measure2.out`, `$S/measure-one.out`

---

## Claim 19b: "... and 870,000 over 49 (one host alias)"

**Location:** `scripts/lib/dev-cycle-read.sh:740`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 49-root work figure at main's state on 2026-10-09 01:10-01:13 local time. It does not establish why the figure moved from the iteration-1 measurement (868,530 in the performance review).

With `IMPORT_READER_ROOTS=/home/magfrump/claude-workflows`, `roots=49` and both walks gave `work=899730` on five runs (`measure.out`, `measure2.out`, `measure3.out`), about 3.5% above "about 870,000". The 25-root figure (347,710) still matches, so the gap is specific to the aliased roots, perhaps because /workspace's content or worktree paths changed since iteration 1. This is not a blocking drift, and the bound's headroom claim is unaffected.

Precise version: "about 900,000 over 49" (or keep 870,000 and date it to the iteration-1 measurement).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:740`, `$S/measure.out`, `$S/measure2.out`, `$S/measure3.out`

---

## Claim 20: "Roots are about (1 + C) times the worktrees for C host aliases (G8): with one, near 285 worktrees (49 roots here: 1.5 s per walk; U2b3b1 i1 performance F1)."

**Location:** `scripts/lib/dev-cycle-read.sh:745-746`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the root multiplier, the 285 figure as half of the existing "near 570 roots", and the walk timings at load average 1.5 to 2.3. It does not re-derive the pre-existing 570 figure, which comes from the performance review's synthetic 505-root measurement.

The multiplier holds: 25 worktree records give 25 roots, and with one alias give 49, that is (1 + 1) × 25 − 1, since the main worktree itself is not re-spelled beneath the alias. 570 / 2 = 285. Timings at 49 roots: the main walk took 1.50, 1.51, 1.50, 1.52 and 1.82 s (the last under load 2.3); the tree walk took 1.70, 1.84, 1.63, 1.70 and 1.65 s (`measure2.out`, `measure3.out`). "1.5 s per walk" fits the main walk; the tree walk runs about 1.7 s. That is not caused by the alias, since the tree walk at 25 roots also took 1.61-1.70 s.

Precise version: "(49 roots here: about 1.5 s for the main walk, 1.7 s for the tree walk)".

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:741-746`, `scripts/lib/dev-cycle-read.sh:1028-1032`, `$S/measure2.out`, `$S/measure3.out`

---

## Claim 21: "import_readers' IMPORT_ROOTS and IMPORT_HOMES when its memo key is current (else ROOT_REAL alone and import_home's home: a call outside a walk; either fails on refused settings)"

**Location:** `scripts/lib/dev-cycle-read.sh:766-767`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both paths with IMPORT_READER_WHY set. It does not establish behaviour for a memoized non-settings refusal (a relative caller root, a failed listing). The comment does not claim that case; probe1 found it also fails (`it rc=1`), because the parser gets an empty root list.

`[[ -z "$IMPORT_READER_WHY" ]] || return 1` (`:1065`) runs after the memo-or-fallback choice (`:1064`), so it covers both. Probe1 "memo" printed `ir rc=1 DONE-set=y ROOTS=[]`, `it(memo) rc=1` and `it(fallback) rc=1` (after import_reset). The test at `build-loop-check.bats:538` (fallback) passes.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:1059-1066`, `test/scripts/build-loop-check.bats:537-539`, `$S/probe1.out`

---

## Claim 22: "IMPORT_ROOTS holds ROOT_REAL, every path git worktree list registers ..., each IMPORT_READER_ROOTS entry and, beneath each such entry, every registered worktree that lies beneath the main worktree (the first record), re-spelled there"

**Location:** `scripts/lib/dev-cycle-read.sh:974-978`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers spelled entries and the re-spelling rule. It does not establish realpath-form re-spelling, which is the realpath of the re-spelled string, nor a main worktree whose registry spelling differs from its realpath.

The loop is `rs_r+=("$rs_cr"); for p in "${rs_w[@]}"; do [[ -z "$rs_m" || "$p" != "$rs_m"/* ]] || rs_r+=("$rs_cr${p#"$rs_m"}"); done` (`:1031`). In probe1, from the main checkout and from a sibling worktree `../side`, the roots held `/host/cw` and `/host/cw/.claude/wt-x` and did not hold `/host/cw/../side`. The `build-loop-check.bats:542` test (from `../gate`) passes.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:1021-1033`, `test/scripts/build-loop-check.bats:542-553`, `$S/probe1.out`

---

## Claim 23: "It returns 1 when IMPORT_READER_WHY is set (reader_settings refused the settings), import_home or the listing fails, ... The result, a refusal included (but not an import_home failure, which returns first), is memoized in IMPORT_READERS_DONE, keyed on ROOT_REAL, HOME, the caller's two lists and IMPORT_READER_WHY"

**Location:** `scripts/lib/dev-cycle-read.sh:986-997`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of the return paths and the key parts. It does not establish that "HOME" means HOME as spelled: the key uses IMPORT_HOME_DONE (`x${HOME+set}:${HOME-}`), which is HOME's set-state and value, so the claim holds.

The order is `import_home || return 1` (`:1012`), then `import_readers_key`, then `IMPORT_READERS_DONE="$IMPORT_READERS_KEY"` (`:1017`) before any refusal check. The key is `"${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d ${#e}:$e"` over ROOT_REAL, IMPORT_HOME_DONE, the two lists and IMPORT_READER_WHY (`:1006-1007`). Probe1 "import_home failure not memoized" printed `ir rc=1 DONE=[]`; "memo" printed `DONE-set=y`.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:1005-1020`, `$S/probe1.out`

---

## Claim 24: "A refusal is memoized too, as an empty IMPORT_ROOTS (a result never is: ROOT_REAL leads it), so a refusing decision lists the registry once"

**Location:** `scripts/lib/dev-cycle-read.sh:1014-1015`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers refusals reached after the listing. It does not establish anything about a WHY refusal, which lists the registry zero times because it returns at `:1020` before `:1021`.

`if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi` (`:1016`). A success always holds ROOT_REAL, which `:1020` requires to be non-empty. The test `build-loop-check.bats:555` (a git stub logs each `worktree` call; walk plus two isimported calls; asserts 1 line) passes.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:1014-1021`, `test/scripts/build-loop-check.bats:555-566`, `$S/bats.log`

---

## Claim 25: "The first record is the main worktree, which each caller root spells on a host, so the worktrees registered beneath it are spelled beneath each caller root there too"

**Location:** `scripts/lib/dev-cycle-read.sh:1023-1025`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's ordering: the main worktree is listed first, as observed from both a linked worktree and the main one. It does not establish the host-side premise that a caller root is the main worktree's host spelling, which is a settings convention.

Probe1 "G8 from side worktree" listed the main repo second in IMPORT_ROOTS only because ROOT_REAL (side) leads. The re-spelled set was the same as from the main checkout (`/host/cw/.claude/wt-x`), which shows `rs_w[0]` was the main worktree even when run from `side`.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:1022-1033`, `$S/probe1.out`

---

## Claim 26: floor's new message: "the reader settings of docs/dev-cycle.md cannot be used ($IMPORT_READER_WHY), so the instruction files could not be walked for @ imports"

**Location:** `scripts/lib/dev-cycle-read.sh:1416`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the floor's text when a WHY is set. It does not establish a live caller (U2c).

`if [[ "$TRUTH_WHY" == walk && -n "$IMPORT_READER_WHY" ]]` (`:1416`). The `build-loop-check.bats:535-536` assertion of the exact text passes.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:1415-1418`, `test/scripts/build-loop-check.bats:534-536`, `$S/bats.log`

---

## Claim 27: build-loop-check.bats new comments and test names: "T_SETTINGS=1 sets them as the scripts do, with reader_settings"; "both walks take the reader lists from main's docs/dev-cycle.md, never the working tree, and a malformed line fails them"; "A root only the working tree's copy names is not read"; "A malformed line (or a second copy) fails both walks, which then answer imported for every path"; "Refused settings fail import_targets outside a walk too, which reads no memo"; "a caller root re-spells the worktrees registered beneath the main worktree"; "a refused reader set is memoized, so a decision lists the worktree registry once"; "The walk, then isimported for each path: three calls of the walk in one decision"

**Location:** `test/scripts/build-loop-check.bats:474-566`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion matching its comment, and all of them passing. It does not establish that "every path" was tested beyond the two paths the test checks; the code's every-path behaviour is Claim 3.

The `imps` and `floors` helpers call `resolve_main || true; [[ -z "${T_SETTINGS:-}" ]] || reader_settings`, matching the scripts' order. The import_targets case sets `IMPORT_READER_WHY=x` with no prior import_readers call, so IMPORT_READERS_DONE is empty and the fallback runs ("reads no memo"). imps runs the walk once and isimported once per path, and each isimported calls the walk again, so two paths make three calls. All tests pass (bats.log).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `test/scripts/build-loop-check.bats:474-492`, `test/scripts/build-loop-check.bats:508-566`, `scripts/lib/dev-cycle-read.sh:1325-1333`, `$S/bats.log`

---

## Claim 28: build-loop-read.bats new test names and comments: "--settings prints its five lines in order"; "Reader roots and Reader homes give the readers line; any other form is malformed and never echoed"; "One trailing CR is dropped, as on the policy line; a fenced copy is not read"; "A copy in markup, a continued line, or a file FENCE_AWK refuses: malformed too"; "Only main's commit decides: a loop's branch and the working tree are ignored"

**Location:** `test/scripts/build-loop-read.bats:198, 599-638`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion against its comment. It does not establish "never echoed" for inputs outside the listed set; by code, every WHY text uses only line numbers, entry indices and the fixed key (`:612-622`), so no input text is echoed.

The WHY strings are `"line ${first[$k]} lists entry $i, ..."`, `"more than one line starts \"$key\" ..."` and `"line ${first[$k]} is not exactly \"$key PATH ...\" ..."` (`scripts/lib/dev-cycle-read.sh:613-621`). SETTINGS_AWK runs `sub(/\r$/, "")` before fence() (`:557-558`). All tests pass.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `test/scripts/build-loop-read.bats:198-202`, `test/scripts/build-loop-read.bats:599-638`, `scripts/lib/dev-cycle-read.sh:556-634`, `$S/bats.log`

---

## Claim 29: dev-cycle.bats test name: "--check-fix models the host readers main's docs/dev-cycle.md names, and refuses every path on a malformed line or with no main by name (U2b3b1; H4; i1 security F1)"

**Location:** `test/scripts/dev-cycle.bats:648`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code's behaviour. It does not establish full test coverage: the malformed case asserts two paths, the no-main case one (`--check-fix docs/notes.md`).

Host-reader modelling: without settings both paths give `ok`; with `/host/cw` and `/host` both give `skip ...: an instruction file names it`. Both refusals are asserted. The test passes.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `test/scripts/dev-cycle.bats:648-665`, `$S/bats.log`

---

## Claim 30a: Commit 8ed86432: "reader_settings in the lib reads two keys ... A second copy, a malformed line or a file FENCE_AWK refuses sets IMPORT_READER_WHY ... import_readers memoizes a refusal (D7) and re-spells ... (G8). main_file and SETTINGS_AWK move from build-loop.sh into the lib; --settings prints a fifth line ... Over /workspace both walks still give 128 names, at 49 roots (was 25) ... Suites 220/220 ... 375 code lines against main (the move counted twice). ... without main found by name the lists stay empty"

**Location:** commit 8ed86432 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures and behaviours named as of that commit; the no-main sentence is true of 8ed86432's lib and was superseded in 1ece139d. It does not cover the timing pair, which is Claim 30b.

`git diff --numstat main...8ed86432 -- ':(top)' ':(top,exclude)docs/'` summed to `295 80 375`. The 220 tests are 20 + 117 + 79 in the three changed suites (`grep -c '^@test'` at 8ed86432; unchanged at HEAD) plus 2 + 2 in fixture-git-env and utility-smoke: bats.log gives 216/216 and bats2.log 4/4. 128 names at 49 vs 25 roots: measure*.out. 8ed86432's lib shows `if ! main_by_name; then READERS_LINE="readers none: no default branch found by name"; return 0; fi` (its `:606`), so "the lists stay empty" was true at that commit.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `git show 8ed86432:scripts/lib/dev-cycle-read.sh` :602-606, `$S/bats.log`, `$S/bats2.log`, `$S/measure.out`

---

## Claim 30b: Commit 8ed86432: "the main walk takes 1.5 s (was 1.3 s)"

**Location:** commit 8ed86432 message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the main walk's wall time at 25 and 49 roots under load 1.5 to 2.3. It does not establish the timing on an idle host when the commit was made.

At 49 roots the main walk took 1.50-1.52 s (one outlier of 1.82 s), which matches. At 25 roots it took 1.44 and 1.51 s, not 1.3 s, so the implied 0.2 s cost of the alias is not reproduced. The iteration-1 performance review also measured it as flat (1.39 to 1.40 s). The measured cost of the alias is within noise.

Precise version: "the main walk takes about 1.5 s, as before (fixed costs dominate)".

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `$S/measure2.out`, `$S/measure3.out`, `docs/reviews/performance-review-2026-10-09-u2b3b1.md:47`

---

## Claim 31: Commit 1ece139d: "reader_settings now sets IMPORT_READER_WHY, so --check-fix fails closed ... import_targets refuses while IMPORT_READER_WHY is set, memo or not ... the floor and --check-fix name the reader settings when they fail a walk ... Comments trimmed to keep the unit under the cap (397 lines). ... Suites 220/220."

**Location:** commit 1ece139d message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed fixes and figures. It does not re-audit the declined-finding override rows beyond confirming that they exist.

`git diff --numstat main...1ece139d -- ':(top)' ':(top,exclude)docs/'` summed to `312 85 397`. Test counts are unchanged from 8ed86432 (20/117/79), and all 220 pass. The behaviours are Claims 11, 12, 21 and 26, all executed. The "H4 test now checks two paths" fix holds for the malformed case (Claim 29).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `$S/bats.log`, `$S/bats2.log`, `$S/probe1.out`, `docs/reviews/override-log.md` (last 8 rows)

---

## Claim 32: Commit f56ba3f5: "k=1, full panel, at 8ed86432: no red; two ambers acknowledged with revisit triggers; fixes in 1ece139d (lite fix-drift: no findings)."

**Location:** commit f56ba3f5 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the committed rubric. It does not re-run the fix-drift check.

The rubric reads "Iteration 1 (Commit 8ed86432, `--loop-pass`, k=1, ..., full panel)", "### 🔴 Must Fix / None." and two 🟡 rows (A1, A2) marked "Acknowledg..." with revisit triggers (`docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b1.md:1-25`).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b1.md:1-25`

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- none

### Mostly Accurate
- **Claim 2** (`docs/dev-cycle.md:31-33`): "absolute paths" leaves out the path-form rule (NAMECHARS, not `/`, no empty, `.` or `..` part, listed once). A host path with another character fails both walks.
- **Claim 10** (`scripts/dev-cycle.sh:56-60`): "fails when those lines are malformed or no default branch is found by name" leaves out a docs/dev-cycle.md that main_file refuses (for example an unclosed fence anywhere in it), which also fails --check-fix.
- **Claim 19b** (`scripts/lib/dev-cycle-read.sh:740`): "870,000 over 49" now measures 899,730. The 25-root and 1-root figures still match.
- **Claim 20** (`scripts/lib/dev-cycle-read.sh:746`): "1.5 s per walk" fits the main walk; the tree walk is about 1.7 s, at 49 roots and at 25 alike.
- **Claim 30b** (commit 8ed86432): "(was 1.3 s)" is not reproduced. The main walk is about 1.45-1.5 s at 25 roots too, so the alias's time cost is within noise.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report at the output path your role names, structured per your skill, every finding with a verbatim Evidence quote and path:line.
- Answered: yes.
- Out of scope: H5, H2, C1, G9 and outside starts (U2b3b2's by the plan split), and the override rows dated 2026-10-09 (duplicated parser, no sentinel, origin/HEAD redirect, alias cap, three Won't-Fix nits). None was re-filed.
- Escalate: none blocking. Two notes for the synthesizer:
  - The "the floor refuses every path" wording (docs/dev-cycle.md:34, build-loop.sh:52) describes the lib's `floor`, which has no caller in scripts/ until U2c. It is Verified at function level, with that residue in Claim 3's Scope.
  - A memoized non-settings refusal also fails import_targets (`it rc=1`, probe1). That is fail-closed, and the comment does not claim otherwise.
- Decisions I made:
  - Counted "220" as the five suites (20 + 117 + 79 + 2 + 2), as iteration 1 did.
  - Measured work with an `import_work` wrapper that sums the parser's trailer, and the one-root figure with a `git` shim that keeps the first worktree record.
  - Graded the 3.5% drift on the 49-root figure as Mostly accurate rather than Verified, because the other two figures in the same sentence still match within 1%.
