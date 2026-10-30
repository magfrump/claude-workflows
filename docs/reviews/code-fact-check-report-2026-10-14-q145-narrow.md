Commit: c4bab9ca

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q145 (branch fix/q145-ancestor-vanish, HEAD c4bab9ca)
**Scope:** fix range `29b807dc..c4bab9ca` (one commit, c4bab9ca): scripts/lib/dev-cycle-read.sh (walk header, config_seeds header, listing comment; config_seeds, top_files and nul_list read in full as context), test/scripts/build-loop-check.bats (Q-145 test comment, new top_files test), and c4bab9ca's commit message. Earlier branch commits (`git log main..HEAD`) are context only. Narrow check after the final k=3 pass at 29b807dc (`code-fact-check-report-2026-10-14-q145-final-r{1,2,3}.md`).
**Replication:** k=1 (narrow check after the final pass)
**Checked:** 2026-10-14 (executions 2026-10-15T04:59Z to 05:01Z UTC)
**Total claims checked:** 11
**Summary:** 11 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution environment: GNU findutils 4.9.0 (`/usr/bin/find`, named explicitly in the probes), bash 5.2, uid node. All runs used a `git archive HEAD` copy at `S/src`, where `S=/home/node/.claude/jobs/00bcf178/tmp/q145/review/narrow`. Main's lib, for reference, is at `S/main-lib.sh`. No tracked file in the worktree was changed apart from this report. Every command ran under `timeout` and finished; nothing is left running. Captured logs (under `S/logs/`):

- `test-head.log`: `timeout 500 env LC_ALL=C bats --filter 'Q-145' test/scripts/build-loop-check.bats`, cwd `S/src`, exit 0, 2026-10-15T04:59:43Z. Both Q-145 tests `ok`.
- `mutants.log`: `timeout 590 bash S/mutants.sh`, exit 0 for the script, 2026-10-15T04:59:58Z to 05:00:09Z. Each mutant is a fresh copy of `S/src` with one exact-once replacement of top_files' recheck line, run through the same bats filter. The mutants are `noempty` (recheck returns 1 without emptying NAME), `norecheck` (recheck removed) and `firstonly` (recheck of the first DIR only).
- `probe.log`: `timeout 120 bash S/probe.sh S/probe`, exit 0, 2026-10-15T05:00:30Z. It covers files, links and directories deleted between readdir and stat, with and without `-ignore_readdir_race`. It also covers a delete-and-re-create closed before the stat, a gap spanning the readdir, a dangling linked DIR as a `-H` start point, and a trace of where the test shim's clause runs.
- `cs-stderr.out` / `cs-stderr.err`: real `config_seeds` from the copy's lib with `IMPORT_ROOTS=S/probe-cs/r/root` and an unreadable ancestor config dir `S/probe-cs/r/.claude` (`chmod 000`), `timeout 60`, cwd `S/probe-cs`, exit 0, 2026-10-15T05:00:50Z.

I read the hallucination log `docs/reviews/hallucination-patterns.md`. No logged pattern matches any claim here.

---

## Claim 1: "since a name no longer there holds nothing to load (a file deleted and re-created mid-listing can be missed: config_seeds' comment)"

**Location:** `scripts/lib/dev-cycle-read.sh:832-833`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a delete-and-re-create can leave a file out of the listing, whether the gap spans the stat (skipped) or spans the readdir (not seen), and that config_seeds' comment states this. It does not establish behaviour on findutils other than 4.9.0, and it does not cover the rename-in case, which this pointer does not name and the config_seeds comment covers.
**Legibility-target:** for-author

This addresses r3 Claim 2. The pointed-to text exists inside config_seeds: `# deleted and re-created there (a non-atomic save), which find may not see, or` / `# now skips when the gap spans its stat (i2 security F1)` (`scripts/lib/dev-cycle-read.sh:1561-1562`). Both miss paths were executed under top_files' flags (`probe.log`):

- With the gap open at the stat (`race kind=file mode=delete flag=irr`), the output is `top/a0`, `top/vic2`, `rc=0`, so the deleted names are skipped silently.
- With the gap spanning the readdir (`gap spans readdir`), the output is `top/a0`, `rc=0`, and afterwards `after: a0 vic1`: the file is back but was not listed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:826-834`, `scripts/lib/dev-cycle-read.sh:1559-1564`, `S/logs/probe.log`

---

## Claim 2: "the top-level listing (top_files) fails it only when all three of its tries fail (a directory entry that vanishes mid-listing fails one; a vanished file is skipped: Q-145)"

**Location:** `scripts/lib/dev-cycle-read.sh:1510-1512`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three-try chain and how find 4.9.0 treats a vanished file, link and directory under top_files' expression. It does not establish behaviour on other findutils versions. It also leaves unsaid that a vanished link is skipped too, which "file" covers only loosely.
**Legibility-target:** for-author

This addresses r1 3b, r2 3b and r3 4b. The chain is `top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1` (`scripts/lib/dev-cycle-read.sh:1566`). top_files runs `find -H "${@:2}" -maxdepth 1 -ignore_readdir_race '(' -xtype f -o -xtype l ')' -print0` (`:1594`).

Results under `-ignore_readdir_race` (`probe.log`):

| Vanished entry | Output | Exit |
|---|---|---|
| File | `top/a0`, `top/vic2` | `rc=0` |
| Link | `top/a0`, `top/vic2` | `rc=0` |
| Directory | `/usr/bin/find: 'top/vic1': No such file or directory` | `rc=1` |

So only a directory fails a try.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1508-1512`, `scripts/lib/dev-cycle-read.sh:1566`, `scripts/lib/dev-cycle-read.sh:1593-1596`, `S/logs/probe.log`

---

## Claim 3: "a transient one of any kind is retried away when a later try is clean, its message dropped (three in a row fail the walk, the third's message shown)"

**Location:** `scripts/lib/dev-cycle-read.sh:1557-1559`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the retry-then-use path, the dropped stderr of tries 1 and 2, and a three-failure run, observed at config_seeds' own stderr. It does not establish that callers above `outside_seeds` leave stderr alone, since the call sites at `:1736` and `:1839` add no redirect but their callers were not traced. It also does not cover a third failure from the `-d` recheck, which prints no message at all.
**Legibility-target:** for-author

This addresses r2 Claim 7. Only tries 1 and 2 carry `2>/dev/null`, and the third ends `|| return 1` (`:1566`). In the executed config_seeds run with a persistently unreadable config dir:

- stdout is `config_seeds rc=1`.
- stderr holds exactly one line, `find: '.../probe-cs/r/.claude': Permission denied` (`cs-stderr.out`, `cs-stderr.err`).

That is three failures in a row, with only the third's message shown. The retried-away case passes at HEAD: the Q-145 test asserts the shim log `1 0` and `[ -z "$stderr" ]` (`test/scripts/build-loop-check.bats:759-762`, `test-head.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1566`, `scripts/lib/dev-cycle-read.sh:1736`, `scripts/lib/dev-cycle-read.sh:1839`, `test/scripts/build-loop-check.bats:757-762`, `S/logs/cs-stderr.out`, `S/logs/cs-stderr.err`, `S/logs/test-head.log`

---

## Claim 4: "before Q-145 such a gap failed the walk when it was still open at find's stat of the name readdir had returned, and was missed silently when it spanned the readdir."

**Location:** `scripts/lib/dev-cycle-read.sh:1562-1564`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's listing line and its outcome for each of the three gap timings, using a single readdir over a small directory. It does not establish behaviour when a re-created name lands in a directory being read across several getdents calls. The comment already calls that unspecified, so "missed" is the usual outcome there, not a guaranteed one.
**Legibility-target:** for-orchestrator-synthesis

This addresses r1 Claim 9 and r3 Claim 10. Main's listing has no `-ignore_readdir_race` and no retry: `nul_list fl find -H "${tops[@]}" -maxdepth 1 '(' -xtype f -o -xtype l ')' -print0 || return 1` (`S/main-lib.sh:1539`). Main's flags were run for each gap timing (`probe.log`):

| Gap timing | Output | Exit | Effect on main |
|---|---|---|---|
| Still open at the stat (`race kind=file mode=delete flag=none`) | `/usr/bin/find: 'top/vic1': No such file or directory` | `rc=1` | `\|\| return 1` fails the walk |
| Spanning the readdir (`gap spans readdir`) | `top/a0` | `rc=0` | `vic1` is back afterwards but not listed: missed silently |
| Opened and closed between readdir and stat (`race kind=file mode=recreate flag=none`) | all four names | `rc=0` | the case the old wording got wrong; the new wording no longer claims it fails |

The new wording also makes visible that the first case is the one HEAD now skips (`flag=irr` row, Claim 1).

**Evidence:** `S/main-lib.sh:1535-1542`, `scripts/lib/dev-cycle-read.sh:1559-1564`, `S/logs/probe.log`

---

## Claim 5: "a shim adds, to the -H top-level listing only, a clause that runs at each entry under the fixture's ancestor; the first run deletes every other vic* there."

**Location:** `test/scripts/build-loop-check.bats:725-727`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers where the clause runs and what the first run deletes, traced with the same clause shape. The comment does not say that later runs can delete the first-visited survivor, and they can. The test's "at most the first-visited victim is left" check (`:753`) allows for that.
**Legibility-target:** for-author

This addresses r2 Claim 13 and r3 Claim 14. The clause is `'(' -path "$a/*" -exec sh -c 'for f in "\$1"/vic*; do [ "\$f" = "\$2" ] || rm -rf "\$f"; done' sh "$a" {} ';' -false ')' -o "\$@"`, added only when the first argument is `-H` (`test/scripts/build-loop-check.bats:738`, `:742`). The trace, with start points `top` and `top/.claude` (`probe.log`), shows:

- `run at top/vic2` deletes vic1, vic3 and vic4.
- The clause then runs at every other entry, including the already-deleted names, the `.claude` start point and `top/.claude/x`: `run at top/vic4`, `run at top/vic1`, `run at top/.claude`, `run at top/a0`, `run at top/vic3`, `run at top/.claude`, `run at top/.claude/x`. `-path` needs no stat, so deleted names still reach the clause.
- One later run, `run at top/vic4`, `deletes top/vic2`.

**Evidence:** `test/scripts/build-loop-check.bats:724-742`, `test/scripts/build-loop-check.bats:753`, `S/logs/probe.log`

---

## Claim 6: test name "top_files lists a directory's files, links and a linked DIR itself, and fails with its array empty when a DIR is no longer a directory (Q-145 final fact-check r3)"

**Location:** `test/scripts/build-loop-check.bats:779-788`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts and that it passes at HEAD. It does not establish that the test exercises a plain DIR that vanished (only a dangling linked DIR stands for "no longer a directory") or top_files' find-error branch, whose emptying comes from nul_list and which this test does not reach.
**Legibility-target:** for-orchestrator-synthesis

The fixture is `mkdir -p "$d/real/sub" && echo > "$d/real/f" && ln -s nowhere "$d/real/dangle" && ln -s real "$d/link" && ln -s gone "$d/dead"` (`:780`). The expected output is `$'ok:real/dangle\nok:real/f\nok:link\nok:link/dangle\nok:link/f\ndead: failed, 0 left'` (`:787`). That asserts:

- Files and links are listed, and the subdirectory is not.
- The linked DIR itself is listed (`ok:link`), along with its entries.
- The array was replaced, since the `fl=(stale)` seed (`:782-785`) is absent.
- After the failure the array is empty (`0 left`).

Result: `ok 2` (`test-head.log`).

**Evidence:** `test/scripts/build-loop-check.bats:779-788`, `scripts/lib/dev-cycle-read.sh:1593-1596`, `S/logs/test-head.log`

---

## Claim 7: "A linked DIR whose target is gone: find lists the link and exits 0; the -d recheck fails it."

**Location:** `test/scripts/build-loop-check.bats:784`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers find 4.9.0 on a dangling link as a `-H` start point and the recheck's effect. The test does not assert find's output or exit on this case directly. The mutants show both indirectly.
**Legibility-target:** for-author

Direct probe (`dangling linked DIR start`): output `lk/dead`, `rc=0`, `-d: no` (`probe.log`). The recheck is `for tf_d in "${@:2}"; do [[ -d "$tf_d" ]] || { local -n tf_a="$1"; tf_a=(); return 1; }; done` (`scripts/lib/dev-cycle-read.sh:1595`). The mutants confirm it in the test itself (`mutants.log`):

- With the recheck removed (`norecheck`), the case prints `dead: passed`, so find exited 0.
- With emptying removed (`noempty`), it prints `dead: failed, 3 left`: the two real entries plus the listed `dead` link.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1593-1596`, `test/scripts/build-loop-check.bats:784-787`, `S/logs/probe.log`, `S/logs/mutants.log`

---

## Claim 8: c4bab9ca "Final confirming pass (k=3 fact-check at 29b807dc): 0 code defects; the Mostly-accurate comment findings are fixed here." plus the per-bullet citations "(r1, r2, r3)", "(r1, r3 claim 10)", "(r3 claim 2)", "(r2 13, r3 14)"

**Location:** `git show c4bab9ca` (commit message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each code-comment Mostly-accurate finding in r1, r2 and r3 against the diff, and the citations' targets. It does not establish a clean fourth full pass. Also, r2 Claim 7 is the source of the "retried away only when a later try is clean" fix, but the message cites only "(r1, r3 claim 10)" after the main-behaviour clause. The transient fix is uncited, not miscited.
**Legibility-target:** for-orchestrator-synthesis

The three reports' Claims Requiring Attention sections list these comment-level Mostly accurate items: r1 3b and 9; r2 3b, 7 and 13; r3 2, 4b, 10 and 14 (paraphrased — no quote available because this collates three report sections rather than one snippet). Every one maps to a hunk:

- 3b/4b → `:1510-1512` (Claim 2)
- r2 7 → `:1557-1559` (Claim 3)
- r1 9 / r3 10 → `:1562-1564` (Claim 4)
- r3 2 → `:832-833` (Claim 1)
- r2 13 / r3 14 → `bats:725-727` (Claim 5)

The remaining Mostly accurate and Incorrect items concern immutable commit messages (r1 16b, 16c; r2 20; r3 19a). On code defects, r3 says "0 behavioural defects in code", and r1 and r2 both say "Escalate: nothing".

**Evidence:** `docs/reviews/code-fact-check-report-2026-10-14-q145-final-r1.md`, `docs/reviews/code-fact-check-report-2026-10-14-q145-final-r2.md`, `docs/reviews/code-fact-check-report-2026-10-14-q145-final-r3.md`, `scripts/lib/dev-cycle-read.sh:826-834`, `scripts/lib/dev-cycle-read.sh:1508-1564`

---

## Claim 9: c4bab9ca "the block is rewrapped" / "these are comment fixes plus one test"

**Location:** `git show c4bab9ca` (commit message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full diff `29b807dc..c4bab9ca`. It does not establish anything about earlier commits.
**Legibility-target:** for-orchestrator-synthesis

`git diff --stat` shows two files: `scripts/lib/dev-cycle-read.sh | 49`, `test/scripts/build-loop-check.bats | 15`. `git diff -U0 ... -- scripts/lib/dev-cycle-read.sh | grep -E '^[+-][^+-]' | grep -vE '^[+-]\s*#'` prints nothing, so no non-comment lib line changed. `--word-diff` of the listing block shows, outside the two reworded sentences, only moved `#` markers (`[-#-]` / `{+#+}`), which is a rewrap (paraphrased — no quote available because the evidence is command output captured in this session, not a source snippet). The bats changes are the two comment lines and the new test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1545-1564`, `test/scripts/build-loop-check.bats:725-727`, `test/scripts/build-loop-check.bats:779-788`

---

## Claim 10: c4bab9ca "New test: top_files lists a directory's files and links and a linked DIR itself, and fails with its array empty when a DIR is no longer a directory; r3's surviving mutant (recheck returning 1 without emptying NAME) now fails it."

**Location:** `git show c4bab9ca` (commit message body); `test/scripts/build-loop-check.bats:779-788`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the named mutant plus two extra recheck mutants against the Q-145 filter. It does not establish that the new test catches mutants of the find-error branch (nul_list's emptying) or a recheck weakened to `-e`.
**Legibility-target:** for-orchestrator-synthesis

Mutant results (`mutants.log`):

| Mutant | Replacement | Test 1 | Test 2 | Failure output |
|---|---|---|---|---|
| `noempty` (r3's survivor) | `{ return 1; }` | `ok 1` | `not ok 2` | `dead: failed, 3 left` |
| `norecheck` | recheck removed | `not ok 1` | `not ok 2` | `dead: passed` |
| `firstonly` | recheck of the first DIR only | `not ok 1` | `not ok 2` | `dead: passed` |

Test 1 still passes under `noempty`, as r3 found. HEAD passes both tests (`test-head.log`).

**Evidence:** `S/mutants.sh`, `S/logs/mutants.log`, `S/logs/test-head.log`, `scripts/lib/dev-cycle-read.sh:1595`

---

## Claim 11: c4bab9ca "Notes: the loop is at its iteration cap; these are comment fixes plus one test, narrow-checked separately rather than by a fourth full pass."

**Location:** `git show c4bab9ca` (commit message body)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the cap value and the recorded iteration count, with the final k=3 pass counted as iteration 3. It does not establish whether a written cap decision is needed for this narrow check. The rubric artifact at HEAD still reads "final confirming pass pending".
**Legibility-target:** for-orchestrator-synthesis

The cap is "bounded at **3 iterations**" (`workflows/review-fix-loop.md:26`). The rubric records `## Iteration 1 (3a8164d5)` and `## Iteration 2 (0d573a7b)` (`docs/reviews/code-review-rubric-2026-10-14-fix-q145-ancestor-vanish.md:9`, `:18`). The final confirming pass at 29b807dc (r1 to r3) is the third. Medium confidence because whether a confirming pass counts as an iteration is read from the workflow, not stated in the rubric.

**Evidence:** `workflows/review-fix-loop.md:24-47`, `docs/reviews/code-review-rubric-2026-10-14-fix-q145-ancestor-vanish.md:6-20`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None.

Residues named in Scope fields, none of them blocking:

- The commit cites r1 and r3 for the listing fix but not r2 Claim 7, the transient-retry wording (Claim 8).
- The new test pins the recheck branch only through a dangling linked DIR, not a vanished plain DIR or the find-error branch (Claims 6 and 10).
- The rubric still says "final confirming pass pending" (Claim 11).

## Goal-Alignment Note
- **Success criterion (restated verbatim):** "a markdown report saved to /workspace/.claude/wt-q145/docs/reviews/code-fact-check-report-2026-10-14-q145-narrow.md per the code-fact-check skill, first line `Commit: c4bab9ca`, header `**Replication:** k=1 (narrow check after the final pass)`."
- **Answered:** yes. Every item in the brief was checked by execution:
  - the config_seeds header
  - the listing comment's transient clause
  - main's delete-and-re-create behaviour
  - the walk-header pointer
  - the test-comment clause
  - the new unit test, which kills `noempty`
  - c4bab9ca's commit message
- **Out of scope:**
  - Full affected suites. The brief limits runs to the Q-145 filter, and a health check may be running.
  - Earlier commits, which are context only.
  - The docs/reviews artifacts, apart from reading r1 to r3 to map findings to fixes.
- **Escalate:** nothing. All comment fixes match the code. The new test closes r3's surviving mutant.
- **Decisions I made:**
  - I verdicted Claim 5 Verified even though later shim runs can also delete. The comment states what the first run does and claims no exclusivity.
  - I verdicted Claim 8 Verified despite the missing r2 7 citation, because nothing is miscited.
