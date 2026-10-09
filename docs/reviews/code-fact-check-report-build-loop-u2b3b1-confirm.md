Commit: 3908e37e

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b3b1 (branch feat/build-loop-u2b3b1)
**Scope:** `git diff f56ba3f5..3908e37e` (docs/dev-cycle.md, docs/working/plan-build-loop-handoff.md line 301, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats) and 3908e37e's commit message
**Checked:** 2026-10-09
**Replication:** k=1 (confirming pass)
**Total claims checked:** 20
**Summary:** 18 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read; no claim below matches a logged pattern.

Execution logs (scratch dir `S=/tmp/claude-1000/-workspace/f2c3719b-892d-4844-84dc-9c1b5883d0c4/scratchpad/u2b3b1-confirm/fc-confirm/`), each script `set -eu` with its own `mktemp -d /tmp/fc-confirm-XXXX`:
- **E1** `bash $S/suites.sh` (cwd the worktree; HEAD 0225c19a, whose only change from 3908e37e is the rubric file): the five suites, `LC_ALL=C.UTF-8`, 2026-10-09T08:33:09Z-08:34:27Z, exit 0, output `$S/suites.out` (`1..220`, 220 `ok`, `rc=0`).
- **E2** `bash $S/measure.sh` (cwd /workspace, ROOT_REAL=/workspace), 2026-10-09T08:33:09Z, exit 0, load average 0.77, output `$S/measure.out`.
- **E3** `bash $S/edges.sh` (hermetic repo in its temp dir), 2026-10-09T08:33:54Z, exit 0, output `$S/edges.out`.
- **E4** `bash $S/oneway.sh` (two `git archive 3908e37e` copies; in `old`, import_readers is replaced by f56ba3f5's), 2026-10-09T08:33:54Z-08:33:57Z, exit 0, output `$S/oneway.out`.

---

## Claim 1: "Reader roots: /home/magfrump/claude-workflows /workspace" / "Reader homes: /home/magfrump /home/node"

**Location:** `docs/dev-cycle.md:24-26`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both lines are well formed, read as 2 roots and 2 homes, and that /workspace is the main worktree's container spelling; does not establish that /home/magfrump/claude-workflows and /home/magfrump are the host's real paths (host not reachable).
**Legibility-target:** user (the settings a host session's walk will use)

E1 passes `test/scripts/build-loop-read.bats:78`: `[ "$(line readers)" = "readers 2-roots 2-homes set: docs/dev-cycle.md on the default branch" ]`. E2 prints `worktree /workspace` as the first porcelain record, so /workspace is the record the host path re-spells.

**Evidence:** `docs/dev-cycle.md:24-26`, `test/scripts/build-loop-read.bats:77-78`, `$S/suites.out`, `$S/measure.out`

---

## Claim 2: "both spellings of the main checkout, the host's and the container's ..., and both HOMEs, so a walk run on either side reads the other side's names"

**Location:** `docs/dev-cycle.md:28-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the root set import_readers builds when a worktree is registered beneath either spelling and both are named (the host-side case simulated with temp paths); does not establish a real walk run on the host, which this sandbox cannot reach.
**Legibility-target:** user

The loop now treats the first record and every caller root as spellings and crosses them:

```bash
# scripts/lib/dev-cycle-read.sh:1027-1031
[[ ${#rs_w[@]} -eq 0 ]] || rs_m=("${rs_w[0]}")
[[ -z "$IMPORT_READER_ROOTS" ]] || mapfile -t rs_c <<<"$IMPORT_READER_ROOTS"
rs_r=("$ROOT_REAL" "${rs_w[@]}")
for rs_cr in "${rs_c[@]}"; do [[ -z "$rs_cr" ]] || { rs_r+=("$rs_cr"); rs_m+=("$rs_cr"); }; done
for p in "${rs_w[@]}"; do for rs_cr in "${rs_m[@]}"; do [[ "$p" != "$rs_cr"/* ]] || for t in "${rs_m[@]}"; do rs_r+=("$t${p#"$rs_cr"}"); done; done; done
```
(excerpt ends :1031; enclosing import_readers() continues to :1057 — read)

E3, caller root `ws` with main at `cw`: roots include `T/cw/.claude/wt-h` (registered under `ws`) and `T/ws/.claude/wt-a` (registered under `cw`), so each side's worktrees appear under the other. E2 with both spellings: `both: roots=49 homes=2 main=ok main_names=128 ... tree=ok tree_names=128`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1010-1057`, `$S/edges.out`, `$S/measure.out`

---

## Claim 3: "Each is one line of absolute paths (letters, digits and `. _ - /`, with no empty, `.` or `..` part, each listed once)"

**Location:** `docs/dev-cycle.md:31-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers readerform's character set and part rules and the duplicate check; does not establish anything about paths that pass the rule but do not exist.
**Legibility-target:** user

`NAMECHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-'` (`scripts/lib/dev-cycle-read.sh:202`). readerform: `[[ "$1" == /?* && "$1" =~ ^[$NAMECHARS]+$ ]] || return 1` then `[[ -n "$c" && "$c" != . && "$c" != .. ]] || return 1` per part (`:578-582`); `if [[ -n "${rd_seen[$p]-}" ]]; then why="line ${first[$k]} lists entry $i twice"` (`:622`). `/` alone is refused (the `/?*` test, and its one part is empty), so the doc's omission of "not /" loses nothing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:202`, `scripts/lib/dev-cycle-read.sh:575-634`

---

## Claim 4a: "without main found by name the settings cannot be read, so both walks fail: i1 security F1"

**Location:** `docs/working/plan-build-loop-handoff.md:301`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reader_settings' no-main branch and both walk entry points (import_readers, import_targets); does not establish build-loop.sh's behaviour beyond that (the floor's own no-main refusals are older code).
**Legibility-target:** agent (the next unit's builder reads the plan)

`if ! main_by_name; then IMPORT_READER_WHY="no default branch was found by name (origin/HEAD, main or master)"` (`scripts/lib/dev-cycle-read.sh:598-599`); import_readers: `[[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1` (`:1020`); import_targets: `[[ -z "$IMPORT_READER_WHY" ]] || return 1` (`:1064`). E1 passes `test/scripts/dev-cycle.bats:1418-1421` (both paths skipped with the no-main text).

**Evidence:** `scripts/lib/dev-cycle-read.sh:594-634`, `scripts/lib/dev-cycle-read.sh:1010-1066`, `test/scripts/dev-cycle.bats:1416-1421`, `$S/suites.out`

---

## Claim 4b: "import_readers caches a refusal (D7) and re-spells every worktree registered beneath any spelling of the main worktree (its record or a caller root) beneath every other (G8; final security F2); readerform keeps control bytes out (D6)"

**Location:** `docs/working/plan-build-loop-handoff.md:301`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the memo of a refusal, the two-way re-spelling and readerform's character set; does not establish that a caller root which bypasses reader_settings (the test hook) is control-byte free (import_readers checks only newline and absoluteness).
**Legibility-target:** agent

Memo: `if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi` (`scripts/lib/dev-cycle-read.sh:1016`). Two-way loop quoted under Claim 2; E3 and E4 confirm it. readerform restricts to NAMECHARS (Claim 3), which holds no control byte.

**Evidence:** `scripts/lib/dev-cycle-read.sh:575-583`, `scripts/lib/dev-cycle-read.sh:1010-1031`, `$S/edges.out`, `$S/oneway.out`

---

## Claim 4c: "This repo's docs/dev-cycle.md gains `Reader roots: /home/magfrump/claude-workflows /workspace` and `Reader homes: /home/magfrump /home/node` (... so a walk run on the host also reads `@/workspace/...`: final security F1)"

**Location:** `docs/working/plan-build-loop-handoff.md:301`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the text match with docs/dev-cycle.md and that /workspace becomes a reader root on the host; does not establish a real host run.
**Legibility-target:** agent

`docs/dev-cycle.md:24` reads `Reader roots: /home/magfrump/claude-workflows /workspace` and `:26` `Reader homes: /home/magfrump /home/node`; each caller root is added to the roots (`rs_r+=("$rs_cr")`, `scripts/lib/dev-cycle-read.sh:1030`), so an `@/workspace/...` name lies beneath a root.

**Evidence:** `docs/dev-cycle.md:24-26`, `scripts/lib/dev-cycle-read.sh:1030`

---

## Claim 5: "and fails when those lines are malformed, the file is not read, or no default branch is found by name."

**Location:** `scripts/dev-cycle.sh:56-58`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three IMPORT_READER_WHY causes in reader_settings and check_fix's skip; does not establish other walk-failure causes (bounds, git errors), which the header's earlier "when the import walk fails" covers.
**Legibility-target:** user

Causes: `why="$FILE_WHY"` when main_file refuses a non-absent file (`scripts/lib/dev-cycle-read.sh:602-604`), the malformed-line branches (`:614-622`), and the no-main branch (`:598-599`). E1 passes `test/scripts/build-loop-read.bats` (the unclosed-fence case: `the code fence opened at line 3 ... is never closed, so the file is not read`) and `test/scripts/dev-cycle.bats:1414-1421`.

**Evidence:** `scripts/dev-cycle.sh:50-58`, `scripts/lib/dev-cycle-read.sh:594-634`, `$S/suites.out`

---

## Claim 6: check_fix: "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out: the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY; file it instead"

**Location:** `scripts/dev-cycle.sh:186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text under a malformed line and under no main; does not establish the text under an unreadable file (same branch, not separately run).
**Legibility-target:** user

The branch is `if [[ "$TRUTH_WHY" == walk && -n "$IMPORT_READER_WHY" ]]` (`scripts/dev-cycle.sh:186`, read whole check_fix `:176-190`). E1 passes `test/scripts/dev-cycle.bats:1419-1421`, which asserts the exact line `skip docs/notes.md: ${W}no default branch was found by name (origin/HEAD, main or master); file it instead`. No nested parentheses remain in the template.

**Evidence:** `scripts/dev-cycle.sh:176-190`, `test/scripts/dev-cycle.bats:1414-1421`, `$S/suites.out`

---

## Claim 7: contract item 9: "Never set these from the environment or after it, nor IMPORT_ROOTS or IMPORT_HOMES: they are import_readers' results."

**Location:** `scripts/lib/dev-cycle-read.sh:86-92`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that sourcing clears the lists (so the environment cannot set them) and that both scripts set them only through reader_settings; does not establish anything about test helpers, which set them after sourcing (`imps`'s T_READER_*, settled override row 540).
**Legibility-target:** agent (a future caller of the lib)

`IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_READERS_DONE=""; IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""` at source time (`:1002`), `READERS_LINE=""; IMPORT_READER_WHY=""` (`:592`). grep finds no other assignment in scripts/ (paraphrased — no quote available because the claim covers absence of code: `grep -n 'IMPORT_READER_ROOTS=' scripts/*.sh scripts/lib/*.sh` hits only `:597`, `:630`, `:633`, `:1002`). Callers: `scripts/dev-cycle.sh:194` and `scripts/build-loop.sh:307` call `reader_settings`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:86-92`, `scripts/lib/dev-cycle-read.sh:592-634`, `scripts/lib/dev-cycle-read.sh:1002`, `scripts/dev-cycle.sh:194`, `scripts/build-loop.sh:307`

---

## Claim 8: IMPORT_READER_WHY="no default branch was found by name (origin/HEAD, main or master)"

**Location:** `scripts/lib/dev-cycle-read.sh:599`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers resolve_main's by-name candidates; does not establish anything about the current-branch fallback, which sets no MAIN_BY_NAME (the case the text reports).
**Legibility-target:** user

```bash
# scripts/lib/dev-cycle-read.sh:512-523
origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
[[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")
candidates+=(main master)
...
if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; MAIN_BY_NAME=1; break; fi
```
(excerpt ends :523; enclosing resolve_main() continues to :531 — read: the fallback sets MAIN and MAIN_SHA only)

**Evidence:** `scripts/lib/dev-cycle-read.sh:309-311`, `scripts/lib/dev-cycle-read.sh:509-531`

---

## Claim 9: "with one, near 285 worktrees (49 roots here: 1.5-1.7 s per walk; U2b3b1 i1 performance F1)"

**Location:** `scripts/lib/dev-cycle-read.sh:747`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 49 roots and wall time of both walks over /workspace with both spellings on this host; does not establish an idle-host or host-side figure.
**Legibility-target:** agent

E2 (load 0.77): `both: roots=49 ... main_s=1.39668 ... tree_s=1.53574` and `main_s=1.33728 ... tree_s=1.57068`; one spelling `main_s=1.37462 ... tree_s=1.5947`. The main walk ran 1.34-1.40 s, below the stated 1.5 s floor; the tree walk 1.54-1.59 s, inside. Earlier passes at load about 2 measured 1.39-1.84 s (fc-r2, fc-r3 reports). Precise version: "about 1.3-1.7 s per walk, by load".

**Evidence:** `scripts/lib/dev-cycle-read.sh:743-748`, `$S/measure.out`

---

## Claim 10: "a reader root (import_readers: ROOT_REAL, every registered worktree, the caller's IMPORT_READER_ROOTS, worktrees re-spelled under these)"

**Location:** `scripts/lib/dev-cycle-read.sh:796-797`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the root set's membership; does not establish the parser's dotnest rule in the same comment (unchanged).
**Legibility-target:** agent

`rs_r=("$ROOT_REAL" "${rs_w[@]}")` plus caller roots and re-spellings (`:1029-1031`, quoted under Claim 2); E3 lists exactly these classes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1029-1031`, `$S/edges.out`

---

## Claim 11: import_readers header: "IMPORT_ROOTS holds ROOT_REAL, every path git worktree list registers ..., each IMPORT_READER_ROOTS entry and, beneath each of these and the main worktree (the first record), every registered worktree beneath any of them"

**Location:** `scripts/lib/dev-cycle-read.sh:974-979`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the root set for no caller root, one, a root equal to the main record, nested roots, empty lines and `/`; does not establish that nested caller roots are meaningful (they cross-spell into extra paths such as `T/ws2/x/x/wt-n`, harmless extra roots, since caller roots are by contract spellings of the main worktree).
**Legibility-target:** agent

E3: caller root `ws` adds `T/ws`, `T/ws/.claude/wt-a`, `T/cw/.claude/wt-h`; a caller root equal to the main record gives the same set (duplicates folded by `rs_seen`, `:1047-1048`); `T/ws2/x/wt-n`, beneath no spelling, is not re-spelled; `/` gives `rc=1` (`[[ ... -n "${p//\//}" ]] || return 1`, `:1037`); empty lines are skipped (`[[ -z "$rs_cr" ]] ||`, `:1030`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:973-1057`, `$S/edges.out`

---

## Claim 12: "so a worktree registered beneath any spelling of it (one a host session added too) is spelled beneath every other (U2b3a i1 architecture F4, U2b3b1 final security F2)."

**Location:** `scripts/lib/dev-cycle-read.sh:1023-1026`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop at :1027-1031; does not establish cost beyond W x M x M string operations (49 roots here, no measured change: Claim 9).
**Legibility-target:** agent

Loop quoted under Claim 2; E3 shows both directions; E4 shows the new test fails on the one-way loop.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1023-1031`, `$S/edges.out`, `$S/oneway.out`

---

## Claim 13: FLOOR_WHY="the default branch's instruction files could not be walked for @ imports: the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY"

**Location:** `scripts/lib/dev-cycle-read.sh:1415`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the floor's text under a duplicate line; does not establish other WHY texts in this branch (same template).
**Legibility-target:** user

E1 passes `test/scripts/build-loop-check.bats:1878-1879`: `want docs/other.md "the default branch's instruction files could not be walked for @ imports: the reader settings of docs/dev-cycle.md cannot be used: more than one line starts \"Reader roots:\" (lines 1 and 3)"`. Its sibling `:1416` text is the same leading clause.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1405-1418`, `test/scripts/build-loop-check.bats:1876-1879`, `$S/suites.out`

---

## Claim 14: test "a caller root re-spells the worktrees registered beneath the main worktree" and its new comment "The other way: a worktree registered beneath a caller root (a host session's) is spelled beneath main's (final security F2)."

**Location:** `test/scripts/build-loop-check.bats:1885,1896-1902`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test checks both directions and that its second half fails on f56ba3f5's one-way loop; does not establish that the test name names the second direction (it names only the first, which it still tests).
**Legibility-target:** agent

E4: `new rc=0`; `old`: `not ok 1 ... line 1900 ... want: docs/n.md: imported ... docs/n.md: -`, `old rc=1`.

**Evidence:** `test/scripts/build-loop-check.bats:1885-1903`, `$S/oneway.out`

---

## Claim 15: "# The host alias and HOME (Q-121, Q-123), and no prose line read as a copy." over the assertion `readers 2-roots 2-homes`

**Location:** `test/scripts/build-loop-read.bats:77-78`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against the changed assertion; does not establish anything beyond wording.
**Legibility-target:** agent

The assertion now expects `readers 2-roots 2-homes set: docs/dev-cycle.md on the default branch` (`:78`), counting both spellings of the checkout and both HOMEs (`docs/dev-cycle.md:24-26`), while the comment (unchanged at `:77`) still says "The host alias and HOME", in the singular. Precise version: "Both spellings of the main checkout and both HOMEs (Q-121, Q-123)".

**Evidence:** `test/scripts/build-loop-read.bats:77-78`, `docs/dev-cycle.md:24-26`

---

## Claim 16: "# With no default branch found by name the settings cannot be read: fail closed." (step now passes two paths)

**Location:** `test/scripts/dev-cycle.bats:1416-1421`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both paths skipping with the no-main text; does not establish build-loop.sh's no-main path (tested elsewhere).
**Legibility-target:** agent

`run --separate-stderr bash "$DC" --check-fix docs/notes.md docs/h.md` then exact match on `lines[0]` and prefix match on `lines[1]` (`:1419-1421`); passes in E1.

**Evidence:** `test/scripts/dev-cycle.bats:1416-1421`, `$S/suites.out`

---

## Claim 17: 3908e37e message: "Suites 220/220"

**Location:** `3908e37e:commit-message`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers build-loop-check (117), build-loop-read (20), dev-cycle (79), fixture-git-env (2), utility-smoke (2) at the worktree; does not establish the repo's other suites.
**Legibility-target:** user

E1: `1..220`, 220 `ok`, `rc=0`.

**Evidence:** `$S/suites.out`

---

## Claim 18: 3908e37e message: "399 code lines (tests compressed to stay under the cap)"

**Location:** `3908e37e:commit-message`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the numstat count outside docs/ against main used by earlier passes; does not establish a different counting rule.
**Legibility-target:** user

`git diff --numstat main...3908e37e -- ':(top)' ':(top,exclude)docs/'` sums `313 86 399` (f56ba3f5: `312 85 397`); run 2026-10-09 about 08:33Z, cwd the worktree, exit 0 (output reproduced here in full: the six numstat rows were 17/46, 10/2, 155/31, 71/4, 42/3, 18/0).

**Evidence:** `git diff --numstat main...3908e37e`

---

## Claim 19: 3908e37e message: "both walks over /workspace give 128 names at 49 roots with both spellings"

**Location:** `3908e37e:commit-message`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's registry today (25 worktrees); does not establish the figure after the registry changes.
**Legibility-target:** user

E2: `both: roots=49 homes=2 main=ok main_names=128 ... tree=ok tree_names=128` (twice); `none: roots=25 ... 128`.

**Evidence:** `$S/measure.out`

---

## Claim 20: 3908e37e message: "a worktree a host session registered beneath a caller root is now spelled beneath every spelling (test fails on the one-way lib)"; "walk-failure texts keep their siblings' clauses (no nested parentheses); the no-main WHY names origin/HEAD, main or master; contract item 9 says never from the environment"; "the H4 test's no-main step now passes two paths"

**Location:** `3908e37e:commit-message`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fix as shown in Claims 6-8, 12-14 and 16; does not establish the review findings the message cites (their reports are context, not under review).
**Legibility-target:** user

E4 (one-way lib fails at `build-loop-check.bats:1900`), E1 for the texts and the two-path step; contract text quoted in Claim 7.

**Evidence:** `$S/oneway.out`, `$S/suites.out`, `scripts/lib/dev-cycle-read.sh:86-92`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:747`): "1.5-1.7 s per walk": the main walk measured 1.34-1.40 s at load 0.77; say "about 1.3-1.7 s, by load".
- **Claim 15** (`test/scripts/build-loop-read.bats:77`): comment says "The host alias and HOME" over a `2-roots 2-homes` assertion; say "both spellings of the checkout and both HOMEs".

### Unverifiable
(none)

## Goal-Alignment Note

3908e37e does what the rubric's iteration 2 asked: both spellings are named, G8 crosses spellings both ways (E3, E4), the texts read as stated, and the unit sits at 399 lines with 220/220 passing. Neither non-Verified item affects behaviour; both fixes are comment-only and add no code lines (Claim 15's is in a test file, so it counts toward the cap only if a line is added). One observation, not a claim defect: nested caller roots (one spelling beneath another) cross-spell into extra non-existent roots (`T/ws2/x/x/wt-n` in E3); they are harmless extra roots, and reader_settings does not refuse them. Whether that warrants a note is the reviewers' call, not this pass's.
