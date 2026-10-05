Commit: 4aa2e98e

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1a (claude-workflows, branch feat/build-loop-u1a)
**Scope:** `git diff main...feat/build-loop-u1a` at 4aa2e98e, code files only (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats; docs/reviews/ excluded as review artifacts), plus the branch's commit messages (c8435580, 4aa2e98e). Iteration 4, final confirming pass, merged from three replicates.
**Checked:** 2026-10-05
**Commit:** 4aa2e98e
**Replication:** k=3
**Total claims checked:** 66
**Summary:** 60 verified, 4 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable (claims 1-39 merged k=3: 44 verified, 3 mostly accurate, 1 stale, 1 unverifiable; Stage 2.5 submitted claims 40-56 appended from `code-fact-check-submitted-claims-build-loop-u1a.md`: 16 verified, 1 mostly accurate)

Merged most-severe-wins from `code-fact-check-report-build-loop-u1a-r1.md` (29 claims), `-r2.md` (40) and `-r3.md` (32), each stamped `Commit: 4aa2e98e`. The 49 claim sections are 39 numbered clusters emitted at the finest granularity any replicate used (sub-claims 2a/2b, 5a/5b, 6a/6b, 8a/8b, 12a/12b/12c, 15a/15b, 31a/31b, 36a/36b, 38a/38b). A replicate that verdicted only a compound carries its verdict onto each part, marked `(compound)`; where that replicate's own text names which part carries a non-Verified compound verdict (decision 033, intra-claim most-severe-wins), the verdict decides only that part's row and is recorded, not decisive, on the sibling rows (2a, 6b), with the replicate's own words in the annotations. Evidence and reasoning are the winning replicate's (ties: most specific Scope, then lowest replicate). Annotations are the union of every replicate's caveats.

Log paths keep each replicate's scratch dir under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i4/`: `fc-r1/` (r1's `$S/`), `fc-r2/` (r2's `$FC/`), `fc-r3/` (r3's cwd). Run IDs are prefixed by replicate (r1-E1, r2-E4, ...). All three replicates ran `bats test/scripts/dev-cycle.bats` at 4aa2e98e: 68/68 ok (r1-E1 `fc-r1/logs/bats-full.txt`, r2-E1 `fc-r2/logs/E1-bats-full.log`, r3-E2 `fc-r3/logs/bats-base.out`). Hosts: GNU bash 5.2.15, GNU sed 4.9, mawk 1.3.4. All three read `docs/reviews/hallucination-patterns.md`; none matched a logged pattern. Execution logs stay in the scratch dirs (no tracked path but the replicate reports was written).

Replicate run tables (command, cwd, exit, time, log), condensed:
- r1: E1 full bats (0, 16:31:16Z); E2 `--help` (0, 80 lines, `fc-r1/logs/help.txt`); E3 help mutants m1 `'2,80p'` / m2 `'2,77p'` (1, 1, `fc-r1/logs/mut1.txt`, `mut2.txt`); E4 `bats -f 'unreadable blob'` on m3 (check_answer no pipefail), m4 (brief_fields no pipefail), m5/m6 (no `local -`) (1,1,1,1, `fc-r1/logs/mut3.txt`..`mut6.txt`); E5 `local -` restore probe (`fc-r1/logs/probe-localdash.txt`); E6 sed edge probes (`fc-r1/logs/sed-edge.txt`); E7 no-options / `set -eu` probe (`fc-r1/logs/probe-noopts.txt`); E8 duplicate-name tree read (`fc-r1/logs/dup-read.txt`); E9 NUL/CR in a fenced questions.md (printed in session); E10 per-commit help range.
- r2: E1 full bats (0, 16:32:36Z); E2 `--help` vs `sed -n '2,81p'` and sed probes p1-p4 (`fc-r2/logs/E2-help.log`, `E2-sed-probes.log`); E3 help mutants m80/m77 (1, 1); E4 mpf_ans / mpf_bf (1, 1); E5 mnl (`local` for `local -`) (1); E6 `local -` probe under none/eu/euo (`fc-r2/logs/E6-local-dash.log`); E7 duplicate-name tree (`fc-r2/logs/E7-dup-tree.log`); E8 symlinked briefs dir, main's vs branch's dev-cycle.sh (`fc-r2/logs/E8-notdir.log`).
- r3: E1 `--help` (0, `fc-r3/logs/help.out`); E2 full bats on `base/` (0); E3 help80 mutant (1); E4 control `'2,81p'` (0); E5 ans_nopf (1); E6 bf_nopf (1); E7 `localdash.sh` (`fc-r3/logs/localdash.out`); E8 `probe2.sh` (awk identity, doubled tree name, fenced NUL/CR, line-2 BOM; `fc-r3/logs/probe2.out`); E9 sed range probes `hdr.sh` / `hdr2.sh`, GNU and `--posix`.

## Claims Requiring Attention

### Incorrect
- none

### Stale
- **Claim 22** (`test/scripts/dev-cycle.bats:767`): the test title says modes other than --check-brief/--check-branch do not need a default branch found by name, but --check-answer now does (`scripts/dev-cycle.sh:193`). Rename the title, or add --check-answer to its loop. (r2 only; single-replicate detection.)

### Mostly Accurate
- **Claim 2b** (`scripts/dev-cycle.sh:59`): "until committed" should be "until it lands on the default branch"; a commit on any other branch, including the one the cycle runs on, is still not seen (T34). All three replicates.
- **Claim 6a** (`scripts/dev-cycle.sh:111`): the range ends at the first *non-empty* line not starting with `#` (an empty line does not end it; an indented ` #` does; line 2 never ends it). Output is exact for the current header. All three replicates.
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:256-257`): "The caller has checked main_by_name" is not a caller precondition (brief_fields does not check it; main_entry checks it itself at `:261`); the pathform half is accurate. All three replicates.

### Unverifiable
- **Claim 15b** (`scripts/lib/dev-cycle-read.sh:292`, `:548`): whether `local -` restores pipefail on bash 4.4-5.0. Bash 4.4 NEWS says it saves only single-letter options, and 5.1 changed it; checking needs a 4.4/5.0 bash. No minimum bash version is stated for these scripts. (r2 Unverifiable; r1 and r3 verdicted the compound Verified on bash 5.2.)

---

## Claim 1: "a stray carriage return, a NUL byte, or a byte-order mark on line 1" (--check-brief skip reasons)

**Location:** `scripts/dev-cycle.sh:42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL-byte addition to --check-brief's skip list, end to end through dev-cycle.sh; does not re-establish the pre-existing reasons on that line (CR, BOM, fence, HTML, refdef), which this diff did not change.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: "does not establish NUL handling under awks other than mawk (override row 224)" · r3: also covers the same reason in --check-answer's list (`scripts/dev-cycle.sh:68`), asserting `skip Q-1: line 4 of docs/working/questions.md holds a NUL byte, ...`

(r1) FENCE_AWK refuses a NUL line before any fence logic, `scripts/lib/dev-cycle-read.sh:216`: `if (index(l, "\0")) { refuse("nul"); return 1 }`, and oddwhy maps it, `:237`: `nul) echo "holds a NUL byte" ;;`. check_brief reaches it through brief_fields (`:340-342`: `odd\ *) read -r _ n why <<<"$BRIEF_ODD"; echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read" ;;`). Test 64 passes in r1-E1 with `[ "$output" = "skip $b: line 2 holds a NUL byte, so the brief is not read" ]`.

**Evidence:** `scripts/dev-cycle.sh:42`, `scripts/lib/dev-cycle-read.sh:216`, `scripts/lib/dev-cycle-read.sh:237`, `scripts/lib/dev-cycle-read.sh:340-346`, `test/scripts/dev-cycle.bats:1177-1193`, `fc-r1/logs/bats-full.txt`

---

## Claim 2a: "read from docs/working/questions.md or its archive on the default branch's commit"

**Location:** `scripts/dev-cycle.sh:56-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that check_answer reads both files' blobs from `$MAIN_SHA` and never the working tree; does not establish which commit MAIN_SHA is beyond resolve_main's by-name order.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=— · r3=Verified
**Replicate annotations:** r1 (compound, verdict carried by 2b): "The opening clause (\"on the default branch's commit\") carries the right rule, so the mechanism and conclusion hold"; r1's Mostly accurate attaches to "until committed" (Claim 2b)

(r3) The reader:

```bash
# scripts/lib/dev-cycle-read.sh:551-562
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
    ...
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
      || { echo "skip $a: $f could not be read from the default branch"; return; }
```
(excerpt ends :562; enclosing check_answer() continues to :575 — read). No working-tree read remains in the function (paraphrased — no quote available because the claim covers absence of code: the whole unit :547-575 was read and its only file reads are `git ls-tree` via main_entry and `git cat-file`). T34 passed in r3-E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:547-575`, `test/scripts/dev-cycle.bats:1118-1135`, `fc-r3/logs/bats-base.out`

---

## Claim 2b: "an answer only in the working tree is not seen: it reads what main's copy says, until committed"

**Location:** `scripts/dev-cycle.sh:57-59`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the source of the read (the default branch's commit) and the working-tree-only case; does not hold for the literal "until committed", which a commit on a branch other than the default branch does not satisfy.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: precise wording is "until it lands on / is committed to the default branch", SKILL.md's "until it lands" (`skills/dev-cycle/SKILL.md:294`) · r1: "The same is true when the cycle runs on a non-default branch and commits there: `$MAIN_SHA` does not move" · r3: "A build-loop worktree on a feature branch that commits an answer would still read main's copy" · r3: "does not establish anything about how the skill records answers (override row 227)" · r3: rated Mostly accurate rather than Incorrect because the same help sentence names "the default branch's commit"

(r1) The reader takes both files only from `$MAIN_SHA`, `scripts/lib/dev-cycle-read.sh:561`: `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")"`. T34 (passing in r1-E1) shows the gap in "until committed": after `git checkout -q -b side && git commit -qam answer && git checkout -q main`, the answer is committed yet `--check-answer Q-1` still prints `open Q-1`; only after `git merge -q side` does it print `drop Q-1`. The opening clause ("on the default branch's commit") carries the right rule, so the mechanism and conclusion hold; the precise version is "until it is committed to the default branch".

**Evidence:** `scripts/dev-cycle.sh:56-59`, `scripts/lib/dev-cycle-read.sh:551-562`, `test/scripts/dev-cycle.bats:1118-1135`, `fc-r1/logs/bats-full.txt`

---

## Claim 3: "keep, drop, done, open (not marked ANSWERED yet) or unrecognized (answered, but no answer line was found, or the first one's text does not start with one of the options)"

**Location:** `scripts/dev-cycle.sh:59-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the outcome words check_answer prints as a positive line; does not establish ANSWER_AWK's option-token grammar (unchanged by this diff).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not re-check the pre-existing \"does not start with one of the options\" wording (unchanged context, not in this diff)"

(r1) ANSWER_AWK's END prints exactly these for a single entry, `scripts/lib/dev-cycle-read.sh:539`: `else if (count) print (!answered ? "open" : done ? result : "unrecognized")`, with `result` from `option()` returning only keep, drop, done or unrecognized (`:488-501`), and check_answer prints `"$hit $a"` (`:573`). "first one's text" matches the `!done` rule taking the first answer line (`:519-533`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:488-501`, `scripts/lib/dev-cycle-read.sh:519-540`, `scripts/lib/dev-cycle-read.sh:573`

---

## Claim 4: --check-answer skip list "(not a question ID, no such entry, a heading twice in one file or in both files, a code fence never closed ..., a NUL byte, ..., a question heading inside a fence, a questions file that is not a regular file under plain directories on the default branch, or a default branch whose tree or file could not be read)"

**Location:** `scripts/dev-cycle.sh:62-71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers completeness against every `echo "skip ..."` in check_answer reachable through dev-cycle.sh; does not cover the lib's "no default branch found by name" skip (`:550`), which dev-cycle.sh never reaches because it exits 1 first (Claim 5a).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the "no default branch found by name" skip (`scripts/lib/dev-cycle-read.sh:550`) is unreachable through the CLI, which exits 1 first (`scripts/dev-cycle.sh:193-195`) · r3: "No echo is missing from the list" (static mapping)

(r1) check_answer's skip lines, `scripts/lib/dev-cycle-read.sh:549-574`, map one to one: `not a question ID (Q- and digits)` (:549); `notdir` and notfile (:556, :558) = "not a regular file under plain directories"; `the default branch's tree could not be read` (:557) and `could not be read from the default branch` (:562) = "tree or file could not be read"; `more than one entry with this heading in $f` (:564) and `an entry with this heading in both` (:570) = "a heading twice in one file or in both files"; `odd` (:566, every FENCE_AWK reason incl. `nul`), `unbalanced` (:567), `quoted` (:568, "question heading inside a fence"); `no such entry` (:574). r1-E9 confirms the NUL and CR reasons through check_answer (`skip Q-2: line 7 of docs/working/questions.md holds a NUL byte, ...`); tests 62, 64 and 67 cover notfile, notdir, NUL, unreadable blob, both-files and duplicate-tree outputs (r1-E1).

**Evidence:** `scripts/dev-cycle.sh:62-71`, `scripts/lib/dev-cycle-read.sh:549-574`, `fc-r1/logs/bats-full.txt`

---

## Claim 5a: "--check-brief, --check-branch and --check-answer need a default branch found by name (origin/HEAD, main or master): they read its commit."

**Location:** `scripts/dev-cycle.sh:72-73`, `scripts/dev-cycle.sh:189-195`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-1 gate for the three modes; does not establish behavior when origin/HEAD names a branch that starts with `-` (resolve_main skips it, `scripts/lib/dev-cycle-read.sh:396`).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3: the comment's "the other modes do not use it" holds (r1: `MAIN_SHA`/`$MAIN` appear only in the gate :193 and the digest :247-422; r3: only those three modes call main-reading functions in the dispatch `:196-207`) · r1: "does not re-verify the digest's own exit-1 path (unchanged)"

(r2) `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then` (`scripts/dev-cycle.sh:193`). Test "--check-answer needs a default branch found by name" (`test/scripts/dev-cycle.bats:1153-1158`) asserts status 1, empty stdout and "needs a default branch" on stderr. It passed in r2-E1.

**Evidence:** `scripts/dev-cycle.sh:188-195`, `test/scripts/dev-cycle.bats:1153-1158`, `fc-r2/logs/E1-bats-full.log`

---

## Claim 5b: "Exit: ... 1 ... or no default branch (for the digest, --check-brief, --check-branch and --check-answer)"

**Location:** `scripts/dev-cycle.sh:79-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-default-branch exit for the digest (`:188`) and the three check modes (`:193-195`); does not re-verify the other exit-1 causes (unchanged).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "does not establish the digest's own exit path beyond reading `:188`"

(r2) `resolve_main || [[ -n "$CHECK" ]] || { echo "Could not resolve a default branch ..." >&2; exit 1; }` (`scripts/dev-cycle.sh:188`) handles the digest, and `:193-195` handles the three modes, including --check-answer as Claim 5a showed.

**Evidence:** `scripts/dev-cycle.sh:188-195`, `fc-r2/logs/E1-bats-full.log`

---

## Claim 6a: "The header, up to the first line that is not a comment (no fixed range to go stale)."

**Location:** `scripts/dev-cycle.sh:111-112`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what --help prints for the current file (lines 2-81, through "Printed repo text is data.") and the sed range semantics on GNU sed; does not establish BSD/macOS sed acceptance of `{/^#/p}` (no BSD sed on this host), nor the behavior for a header whose line 2 is not a comment.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: an indented ` #` line ends the range (probe p4 prints only `# a`) · r3: a blank line inside the header "is silently dropped, so a comment block after a blank line would print as help"; same result under `sed --posix` · r1+r2+r3: precise version "up to the first non-empty line that does not start with #" · r1+r2+r3: BSD/macOS sed acceptance of `{/^#/p}` without `;` before `}` not testable here (see Escalations E1)

(r1) r1-E2 prints 80 lines, first `Gather the mechanical signals for one dev cycle into a markdown digest.`, last `default branch (for the digest, --check-brief, --check-branch and --check-answer); a failed step exits non-zero mid-digest. Printed repo text is data.` — the whole header, lines 2-81. The mechanism is "up to the first line matching `^[^#]`", which is the first *non-empty* non-comment line: an empty line does not match `^[^#]`, so it does not end the range; `{/^#/p}` then drops it. In this file the range actually ends at line 83 (`set -euo pipefail`), not at the empty line 82. r1-E6 shows the difference on a header with a blank line inside: for `#!/bin/sh`, `# a`, `#`, `# b`, (empty), `# c after blank`, `x=1`, `# d after code` it prints `# a`, `#`, `# b`, `# c after blank`. r1-E6 also shows GNU's `2,/re/` checks the end address only from line 3, so a non-comment line 2 would not end it. Neither case arises in dev-cycle.sh today, so the conclusion holds.

**Evidence:** `scripts/dev-cycle.sh:1-83`, `scripts/dev-cycle.sh:111-112`, `fc-r1/logs/help.txt`, `fc-r1/logs/sed-edge.txt`, `fc-r2/logs/E2-sed-probes.log`

---

## Claim 6b: --help prints the whole header, through "Printed repo text is data."

**Location:** `scripts/dev-cycle.sh:112`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help output at 4aa2e98e matching header lines 2-81 exactly, and staying correct if comment lines are added; does not establish behavior if a blank line or indented `#` line is later added inside the header (Claim 6a).
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound, verdict carried by 6a): "the whole header, lines 2-81 ... Neither case arises in dev-cycle.sh today ..., so the conclusion holds" · r3: "does not establish BSD/macOS sed behavior for `{/^#/p}` with no `;` before `}` (not run; no BSD sed in the sandbox)"

(r2) r2-E2: `--help` printed 80 lines, byte-identical to `sed -n '2,81p' scripts/dev-cycle.sh | sed 's/^# \{0,1\}//'` (`cmp` reported identical). The last line ends `... Printed repo text is data.` (`scripts/dev-cycle.sh:81`). This fixes R3. At 722884c7 the script used `sed -n '2,80p'` with the header ending at :81 (see Claim 36a).

**Evidence:** `scripts/dev-cycle.sh:2-81`, `fc-r2/logs/E2-help.log`, `fc-r2/logs/E2-sed-probes.log`, `fc-r3/logs/help.out`

---

## Claim 7: "A change here must pass test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ once that second caller lands."

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the named suite exists and passes and that build-loop.sh does not exist yet; does not establish any future suite.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish any enforcement of the \"must pass\" rule"; the only caller sourcing the lib is `scripts/dev-cycle.sh:91`

(r2) `ls scripts/build-loop.sh` reports "No such file or directory" (paraphrased — no quote available because the claim covers absence of a file). r2-E1 shows `test/scripts/dev-cycle.bats` passing 68 of 68.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `scripts/dev-cycle.sh:91-94`, `fc-r2/logs/E1-bats-full.log`

---

## Claim 8a: "The caller sets -euo pipefail, cds to the repo root and sets ROOT_REAL"

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the caller contract as dev-cycle.sh meets it; does not establish that every lib function is pipefail-independent (only brief_fields and check_answer set it themselves).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish that every future caller sets -euo pipefail"; the contract is stricter than brief_fields and check_answer need · r3: functions other than brief_fields and check_answer still rely on the caller's options

(r1) dev-cycle.sh still sets the options, `scripts/dev-cycle.sh:83`: `set -euo pipefail`. The sentence remains a true statement of the caller's contract even though brief_fields and check_answer no longer depend on its pipefail (`:292`, `:548`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-18`, `scripts/dev-cycle.sh:83`, `scripts/lib/dev-cycle-read.sh:289-292`, `scripts/lib/dev-cycle-read.sh:548`

---

## Claim 8b: "inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:15-18`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the need_root caller list after check_answer's removal; does not re-verify need_root's own three conditions (unchanged from main).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

(r1) `rg -n need_root` finds calls in inrepo (`:121`), dirok (`:124`), skipped (`:125`), check_brief (`:323`) and imported_names (`:433`), and none in check_answer (`:547-575`), so removing check_answer from the list is correct.

**Evidence:** `scripts/lib/dev-cycle-read.sh:91-125`, `scripts/lib/dev-cycle-read.sh:323`, `scripts/lib/dev-cycle-read.sh:433`

---

## Claim 9: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:21-23`, `scripts/lib/dev-cycle-read.sh:242-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer's new main_by_name guard; does not cover the order of checks (a non-ID argument is skipped as "not a question ID" before the main check, still a skip).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: the ID-form check (`:549`) comes first, so a malformed ID gets "not a question ID" · r2: "does not establish behavior if a caller sets MAIN_SHA/MAIN_BY_NAME by hand"; same guard in check_brief `:324` and check_branch `:372` · r3: "does not establish resolve_main's candidate order"

(r1) `scripts/lib/dev-cycle-read.sh:550`: `if ! main_by_name; then echo "skip $a: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi`. Test 65 calls `check_answer Q-1` before `resolve_main` and asserts that exact skip line as its first output (r1-E1, pass).

**Evidence:** `scripts/lib/dev-cycle-read.sh:21-23`, `scripts/lib/dev-cycle-read.sh:324`, `scripts/lib/dev-cycle-read.sh:372`, `scripts/lib/dev-cycle-read.sh:549-550`, `fc-r1/logs/bats-full.txt`

---

## Claim 10: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree, which the cycle writes); imported_names reads the working tree at ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:29-32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the content each function reads (git objects at `$MAIN_SHA`, never working-tree file contents) with check_brief's stated lstat exception; does not mean check_branch reads only the default branch (it also resolves `refs/heads/<name>` and counts against `$MAIN_SHA`, unchanged by this diff).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: check_branch also reads `refs/heads/<name>` (`:378`), which the wording leaves out but which is not the working tree · r2: "does not establish isolation from repo config or refs/replace (override row 235)"

(r1) main_entry reads `git ls-tree -t --full-tree "$MAIN_SHA"` (`:263`); brief_fields `git cat-file blob "$MAIN_SHA:$1"` (`:297`); check_answer `git cat-file blob "$MAIN_SHA:$f"` (`:561`); check_brief calls `blocker "$a" file` (`:329`, the stated exception) then main_entry and brief_fields. Test 66 overwrites the brief in the working tree (`printf 'Status: dropped\nBranch: wt\n' > "$b"`) and still reads `status=[Status: open]` (r1-E1, pass); T34 shows the same for answers.

**Evidence:** `scripts/lib/dev-cycle-read.sh:29-32`, `scripts/lib/dev-cycle-read.sh:263`, `scripts/lib/dev-cycle-read.sh:297`, `scripts/lib/dev-cycle-read.sh:329-340`, `scripts/lib/dev-cycle-read.sh:561`, `fc-r1/logs/bats-full.txt`

---

## Claim 11: "and anywhere in the file, fenced or not, a carriage return inside a line (CommonMark ends a line there), a NUL byte (a caller reading the output through $(...) would lose it), or a byte-order mark on line 1"

**Location:** `scripts/lib/dev-cycle-read.sh:173-176`, `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of checks in fence() (CR, NUL, BOM before the infence branch) and the fenced case through check_answer under mawk; does not establish "\0" handling under other awks (covered by override row 224).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: one-true-awk / busybox NUL handling not established (override row 224) · r3: a BOM on line 2 is not refused (r3-E8)

(r1) `scripts/lib/dev-cycle-read.sh:214-218`: `if (odd) return 1` / `if (index(l, "\r")) { refuse("cr"); return 1 }` / `if (index(l, "\0")) { refuse("nul"); return 1 }` / `if (NR == 1 && substr(l, 1, 3) == "\357\273\277") { refuse("bom"); return 1 }` / `if (infence) {` — all three precede the fence state (excerpt ends :218; enclosing fence() continues to :229 — read). r1-E9: with a NUL, then a CR, on line 7 inside a ``` block, check_answer printed `skip Q-2: line 7 of docs/working/questions.md holds a NUL byte, ...` and `... holds a carriage return that does not end it, ...`. The `$(...)` rationale matches 2da477b7's R1 description ("Status: op<NUL>en" read as open) and test 64's brief (`Status: op\0en`) now refused.

**Evidence:** `scripts/lib/dev-cycle-read.sh:173-176`, `scripts/lib/dev-cycle-read.sh:213-229`, `fc-r1/logs/bats-full.txt`, `fc-r3/logs/probe2.out`

---

## Claim 12a: main_entry prints "blob" (100644 or 100755), "absent", "notfile", "notdir PART" or "error" (no default branch found by name, ls-tree failed, ...)

**Location:** `scripts/lib/dev-cycle-read.sh:247-252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each result word against the code; does not cover a tree entry whose name holds a slash (override row 236) or gitlinks beyond the mode switch (override row 230).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: r2-E8 shows `notdir` for a symlinked parent directory on main

(r1) `scripts/lib/dev-cycle-read.sh:261`: `main_by_name || { echo error; return; }`; `:263`: `... 2>/dev/null)" || { echo error; return; }`; `:271`: `case "${m[$p]-}" in '') echo absent; return ;; 040000) ;; *) echo "notdir $p"; return ;; esac`; `:273`: `case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac`. Test 64 (`MAIN_SHA=000...; main_entry` → `error`, and before resolve_main → `error`) passes (r1-E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:247-274`, `fc-r1/logs/bats-full.txt`, `fc-r2/logs/E8-notdir.log`

---

## Claim 12b: "or the tree lists a name twice; git's own reads would take the first copy, which may not be the one a check saw, so this answers error instead; never read as absent"

**Location:** `scripts/lib/dev-cycle-read.sh:252-254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the duplicate-name error and git's first-copy read for a symlink-then-blob tree; does not establish ordering for other duplicate shapes (fsck-invalid trees, override row 236).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: the error comes from main_entry's dup detection (`:269`), not a failed ls-tree (ls-tree exits 0 and lists both entries, r2-E7)

(r3) `[[ -z "${m[$path]+set}" ]] || dup=1` then `[[ -z "$dup" ]] || { echo error; return; }` (`:266`, `:269`). r3-E8 built a tree listing `questions.md` as a symlink (`x`) and then as a blob (`real`); `git cat-file -p "$w:questions.md"` printed `[x]`, the first copy. The bats test's mktree case asserts the "tree could not be read" skip (r3-E2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:264-269`, `fc-r3/logs/probe2.out`, `fc-r1/logs/dup-read.txt`, `fc-r2/logs/E7-dup-tree.log`

---

## Claim 12c: "One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory)."

**Location:** `scripts/lib/dev-cycle-read.sh:254-256`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the single call and its flags; does not cover its cost (override row 220).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: cost of `-t` on large directories not established (override row 220)

(r1) `scripts/lib/dev-cycle-read.sh:262-263`: the loop builds `want` from each prefix of the path, then one `git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1"`. Test 65 runs `cd docs; check_answer Q-1` with ROOT_REAL unset and still gets the archive's notfile skip, so the paths resolve from the top level from a subdirectory (r1-E1, pass).

**Evidence:** `scripts/lib/dev-cycle-read.sh:254-263`, `fc-r1/logs/bats-full.txt`, `fc-r2/logs/E7-dup-tree.log`

---

## Claim 13: "The caller has checked main_by_name and the path's form (pathform, so ls-tree prints it unquoted)."

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Architectural / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three in-lib callers (check_brief, brief_fields, check_answer) and the pathform half; does not establish anything about U1b/U1c callers, which do not exist yet.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r3: check_answer passes two literal paths (`:551`) without pathform, "safe because they are fixed"; "does not establish any misbehavior (main_entry fails closed without main by name)" · r1+r2+r3: precise version "The caller has checked the path's form (pathform ...); main_entry checks main_by_name itself"

(r1) The pathform half holds: check_brief checks `pathform "$a"` (`:325`), brief_fields `! pathform "$1"` (`:294`), and check_answer passes only the two constant paths `docs/working/questions.md docs/working/questions-archive.md` (`:551`), which pathform accepts. The main_by_name half does not hold for every caller: brief_fields calls `[[ "$(main_entry "$1")" != blob ]]` (`:294`) without a main_by_name check of its own, relying on main_entry's `main_by_name || { echo error; return; }` (`:261`); test 64 calls `main_entry "$2"` before `resolve_main` and expects `error`. Since main_entry checks main_by_name itself and the comment's own result list names that case (`:252`), the precondition sentence is half redundant rather than misleading.

**Evidence:** `scripts/lib/dev-cycle-read.sh:252`, `scripts/lib/dev-cycle-read.sh:256-261`, `scripts/lib/dev-cycle-read.sh:294`, `scripts/lib/dev-cycle-read.sh:325`, `scripts/lib/dev-cycle-read.sh:551`

---

## Claim 14: brief_fields comment: first unfenced line per key, "whole, after one trailing CR is dropped"; "a key with no such line stays unset"; "Otherwise it sets no key and returns 1, with BRIEF_ODD 'odd N WHY' ..., 'unbalanced N' ... or 'error' (no default branch found by name, a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read)"

**Location:** `scripts/lib/dev-cycle-read.sh:275-287`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed outcome against the code and tests 64, 65, 66, 67; does not establish how later callers (U1b/U1c) judge the values.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

(r1) `scripts/lib/dev-cycle-read.sh:293-294`: `BRIEF=(); BRIEF_ODD=""` / `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi`; `:298`: `{ sub(/\r$/, "") }`; `:301`: `if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 }`; `:304`: `|| { BRIEF_ODD=error; return 1; }`; `:308`: `odd\ *|unbalanced\ *) BRIEF=(); BRIEF_ODD="$l"; return 1 ;;`. Test 66 asserts `status=[Status: open]` from a `Status: open\r\n` line after a fenced `Status: done`, `refused [odd 2 fence] 0`, `refused [unbalanced 2] 0` and an unset branch; test 64 `refused [odd 2 nul] 0`; test 67 `refused [error]` for a deleted blob (r1-E1, all pass).

**Evidence:** `scripts/lib/dev-cycle-read.sh:275-312`, `fc-r1/logs/bats-full.txt`

---

## Claim 15a: "pipefail for this function only (local -), so a failed read is caught whatever the caller set." (brief_fields; check_answer "# as brief_fields"), on bash 5.2

**Location:** `scripts/lib/dev-cycle-read.sh:290-292`, `scripts/lib/dev-cycle-read.sh:548`
**Type:** Error-handling / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers catching a failed `git cat-file` with no caller options, with `set -eu` only, and with `-euo pipefail`, and restoring the caller's options after a normal or early return on bash 5.2; does not establish behavior on bash older than 4.4, where `local -` is not supported (no minimum bash version is stated for the lib).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: bash 4.4-5.0 is not established (Claim 15b) · r1+r3: bash < 4.4 rejects `local -`; the lib already needs 4.2+ for `declare -gA`; no minimum bash version is stated (see Escalations E2) · r3: a function that sets `+e` and `-x` after `local -` returns with `-e` back and `-x` off

(r1) `scripts/lib/dev-cycle-read.sh:292`: `local - out l; set -o pipefail`; `:548`: `local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields`. r1-E7, with no shell options: `opts before: hBc pf-off`, then `skip Q-1: docs/working/questions.md could not be read from the default branch`, then `opts after: hBc pf-off`; with `set -eu` only, the same skip and `after: pf-off`. r1-E5: after a function doing `local - x; set -o pipefail; set -f; set +u; return 1`, the caller's `$-` (`huB`) and pipefail (`off`) are unchanged. r1-E4: m3 (check_answer without pipefail) falls through to the archive and prints `keep Q-1`; m4 (brief_fields without it) loses `refused [error]`; m5 and m6 (no `local -`) leak pipefail and lose `caller unchanged` — every mutant fails test 67.

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-312`, `scripts/lib/dev-cycle-read.sh:547-575`, `fc-r1/logs/probe-noopts.txt`, `fc-r1/logs/probe-localdash.txt`, `fc-r1/logs/mut3.txt`, `fc-r1/logs/mut6.txt`, `fc-r2/logs/E6-local-dash.log`, `fc-r3/logs/localdash.out`

---

## Claim 15b: the same claim ("for this function only"; 4aa2e98e: "the caller's options come back on return") on bash 4.4-5.0

**Location:** `scripts/lib/dev-cycle-read.sh:290-292`, `scripts/lib/dev-cycle-read.sh:548`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what bash's own release notes say about `local -` before 5.1; does not establish actual behavior on 4.4/5.0 (no such bash in the sandbox), and does not apply to bash 5.1+ (Claim 15a).
**Replicate verdicts:** r1=Verified (compound) · r2=Unverifiable · r3=Verified (compound)
**Replicate annotations:** r1+r3 (compound): scope limited to bash 5.2 and excludes bash < 4.4; neither addressed 4.4-5.0 · r2: "This would not weaken the read check itself" (the residue is the caller's pipefail possibly leaking) · r2: escalated a minimum-bash-version question (Escalations E2)

(r2) Bash's NEWS for 4.4 (`/usr/share/doc/bash/NEWS.gz:601-603`) says: "The `local' builtin takes a new argument: `-', which will cause it to save and the single-letter shell options and restore their previous values at function return." pipefail has no single-letter form. CHANGES for bash-5.1-alpha (`/usr/share/doc/bash/CHANGES.gz:647-648`) says: "i. Several changes to how `local -' restores the values of options and $SHELLOPTS." So on 4.4/5.0 the function-local pipefail may leak to a caller that had it off. Bash older than 4.4 rejects `local -`, but the lib already needs 4.2+ for `declare -gA` (`:288`). No minimum bash version is stated for these scripts (paraphrased — no quote available because the claim covers the absence of a version statement; `rg` over the repo). Verifying this needs a bash 4.4 or 5.0 binary.

**Evidence:** `scripts/lib/dev-cycle-read.sh:288-292`, `/usr/share/doc/bash/NEWS.gz:601-603`, `/usr/share/doc/bash/CHANGES.gz:647-648`

---

## Claim 16: "The whole blob is read (no early exit: SIGPIPE under pipefail)."

**Location:** `scripts/lib/dev-cycle-read.sh:295`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers brief_fields' awk program having no `exit`; does not cover FENCE_AWK's functions (they contain no exit either, checked).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: no measured SIGPIPE case

(r1) The awk program at `scripts/lib/dev-cycle-read.sh:297-303` uses only `next` and an `END` block (`fence($0) { next }`, `END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline; else for (i = 1; i <= nk; i++) print kv[i] }`), and FENCE_AWK (`:186-230`) holds no `exit` (paraphrased — no quote available because the claim covers absence of code; `rg -n 'exit'` over :186-230 returns nothing).

**Evidence:** `scripts/lib/dev-cycle-read.sh:186-230`, `scripts/lib/dev-cycle-read.sh:295-304`

---

## Claim 17: check_brief: "its Status line from brief_fields ... A brief FENCE_AWK refuses ... is not read at all, and neither is one stored as anything but a regular file under plain directories (main_entry). 'new' when the default branch has no file at that path"

**Location:** `scripts/lib/dev-cycle-read.sh:313-320`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main_entry and brief_fields paths in check_brief; does not cover the commit-selection `git log -G` logic below (unchanged).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not re-test gitlinks (override row 230)"; r2-E8 symlinked-parent case before/after (Claim 35) · r3: "does not re-verify the Status-commit lookup at `:357-358` (unchanged from main)"

(r1) `scripts/lib/dev-cycle-read.sh:332-339`: `e="$(main_entry "$a")"` / `absent) echo "ok $a new"; return ;;` / `blob) ;;` / `notdir\ *) ... is not a directory on the default branch"` / `error) ... the default branch's tree could not be read"` / `*) ... not a regular file on the default branch"`; then `:340`: `if ! brief_fields "$a"; then` and `:348`: `st="${BRIEF[status]-}"`. Tests 65 and 66 assert `ok $b open ...` agreeing with brief_fields; test 67 asserts `skip $b: the brief could not be read from the default branch` (r1-E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:313-360`, `fc-r1/logs/bats-full.txt`

---

## Claim 18: check_answer "on the default branch's commit, never the working tree ... It reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED."

**Location:** `scripts/lib/dev-cycle-read.sh:541-546`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer's whole body (`:547-575`); does not cover main_entry's git config/environment inputs (refs/replace, override row 235).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: refs/replace not established (override row 235) · r2: "does not establish that git itself reads no working-tree state (config, alternates)"

(r1) check_answer's body calls only `main_by_name`, `main_entry` (git ls-tree), `git cat-file` and `oddwhy`; no need_root, skipped, blocker, inrepo or file test (paraphrased — no quote available because the claim covers absence of calls across the 29-line function, read whole at :547-575). Test 65 runs `check_answer` with `ROOT_REAL` set and a symlinked archive on main and prints `skipped=0`, then `unset ROOT_REAL; cd docs; check_answer Q-1` answers without exiting (r1-E1, pass). The diff removed the old `if skipped "$f"; then ...` line.

**Evidence:** `scripts/lib/dev-cycle-read.sh:541-575`, `fc-r1/logs/bats-full.txt`

---

## Claim 19: "A failed read is a skip, never a fall-through to the other file."

**Location:** `scripts/lib/dev-cycle-read.sh:560-562`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing blob for questions.md with both files on main; does not cover a git failure that exits 0 with partial output (none known).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish a partially readable blob (truncated object)" · r3: "does not establish the stderr scrub of cat-file's `fatal:` line (override row 238)"

(r1) `scripts/lib/dev-cycle-read.sh:561-562`: `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk ...)"` / `|| { echo "skip $a: $f could not be read from the default branch"; return; }`. Test 67 deletes questions.md's blob and asserts that skip (r1-E1); mutant m3 (pipefail removed) prints `keep Q-1` from the archive instead, so the skip depends on the function's own pipefail (r1-E4).

**Evidence:** `scripts/lib/dev-cycle-read.sh:560-563`, `fc-r1/logs/bats-full.txt`, `fc-r1/logs/mut3.txt`

---

## Claim 20: "it reads `questions.md` and `questions-archive.md` from the default branch's commit, so an answer, or an archive move, made only in the working tree is not seen until it lands (it reads what main's copy says, usually `open` or no such entry)"

**Location:** `skills/dev-cycle/SKILL.md:292-295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read source and the hedged outcome set ("usually"); does not cover the skill's flow of when step 1's answers get committed (override row 227, deferred to U4).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: the skill's recording steps not established (override row 227) · r2: "usually" hedges the other outcomes (main's older answer, `unrecognized`, a skip), which A14 asked to be acknowledged; "does not establish each of those outcomes by test"

(r1) Same reader as Claim 2b (`scripts/lib/dev-cycle-read.sh:561`). "until it lands" is the precise rule T34 shows (`open Q-1` until `git merge -q side`, then `drop Q-1`). An archive move only in the working tree leaves main's questions.md holding the entry, which is read from main; an entry created only in the working tree yields `no such entry ... on the default branch` (`:574`); "usually" covers main's old answer and the skips (paraphrased — no quote available because the outcome set is inferred from check_answer's branches :549-574 together with T34).

**Evidence:** `skills/dev-cycle/SKILL.md:292-295`, `scripts/lib/dev-cycle-read.sh:549-574`, `fc-r1/logs/bats-full.txt`

---

## Claim 21: "A questions.md that is not plain is reported, not passed over to the archive."

**Location:** `test/scripts/dev-cycle.bats:650`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the committed-symlink case in the test; the assertion is a prefix match (`*`), so it does not pin the rest of the line.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

(r2) The archive written at `:642` holds Q-100. After `git add -A && git commit -qm link` (`:652`) the test asserts `skip Q-100: docs/working/questions.md is not a regular file on the default branch"*` (`:654`), not an archive answer. It passed in r2-E1.

**Evidence:** `test/scripts/dev-cycle.bats:625-655`, `scripts/lib/dev-cycle-read.sh:558`

---

## Claim 22: test title "--check-brief and --check-branch need a default branch found by name; the others do not"

**Location:** `test/scripts/dev-cycle.bats:767`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title against the gate at 4aa2e98e; the test body checks only --check-path for "the others", so its assertions still hold.
**Replicate verdicts:** r1=— · r2=Stale · r3=— · single-replicate detection
**Replicate annotations:** r2: "The title is unchanged context in a file this branch edits, and it is not in the override log"; escalated as new to this pass (Escalations E3)

(r2) This branch adds --check-answer to the modes that need a default branch: `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then` (`scripts/dev-cycle.sh:193`). Test "--check-answer needs a default branch found by name" (`test/scripts/dev-cycle.bats:1153`) asserts exit 1, and it passed in r2-E1. So "the others do not" is no longer true of --check-answer. A precise title: "--check-brief, --check-branch and --check-answer need a default branch found by name; --check-path does not". Optionally `--check-answer` could join the loop at `:770`.

**Evidence:** `test/scripts/dev-cycle.bats:767-778`, `test/scripts/dev-cycle.bats:1153-1158`, `scripts/dev-cycle.sh:193`

---

## Claim 23: sourcing test now checks `main_entry brief_fields` and `BRIEF BRIEF_ODD`

**Location:** `test/scripts/dev-cycle.bats:1029-1036`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test's name and assertions name what it checks and that it passes; does not establish anything beyond the names listed at `:1032` and `:1035`.
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** none

(r3, part of r3's compound claim on the branch's new and changed test names) "The sourcing test now checks `main_entry brief_fields` and `BRIEF BRIEF_ODD` (`:1032`, `:1035`)." r3-E2: 68 ok lines, no `not ok`.

**Evidence:** `test/scripts/dev-cycle.bats:1029-1036`, `fc-r3/logs/bats-base.out`

---

## Claim 24: T34 test "--check-answer reads main's commit: a working-tree or branch-only answer is open (T34)" and its comments

**Location:** `test/scripts/dev-cycle.bats:1118-1135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh's side of T34; does not cover T34's build-loop.sh and `--marker` parts (override row 221).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: build-loop.sh's side of T34 not covered (override row 221)

(r1) The test asserts `open Q-1` after a working-tree-only answer, `open Q-1` with the answer committed only on `side` (plus `[ "$(git show main:docs/working/questions.md | grep -c ANSWERED)" -eq 0 ]`), and `drop Q-1` after merging with the working-tree file removed; it passes (r1-E1).

**Evidence:** `test/scripts/dev-cycle.bats:1118-1135`, `fc-r1/logs/bats-full.txt`

---

## Claim 25: test "--check-answer refuses a questions file or directory that is not plain on main, whatever the working tree holds" and comments at :1141, :1146

**Location:** `test/scripts/dev-cycle.bats:1137-1151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlinked file and a symlinked parent directory on main; does not cover a gitlink.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

(r2) The test asserts `skip Q-1: docs/working/questions.md is not a regular file on the default branch, so no entry in it is read` with a plain working-tree file present (`:1144`). It then asserts `skip Q-1: docs/working is not a directory on the default branch, so docs/working/questions.md is not read` (`:1149`). It passed in r2-E1.

**Evidence:** `test/scripts/dev-cycle.bats:1137-1151`, `scripts/lib/dev-cycle-read.sh:556-558`

---

## Claim 26: test "--check-answer needs a default branch found by name"

**Location:** `test/scripts/dev-cycle.bats:1153-1158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test's name names what its assertions check and that it passes; does not establish the stale sibling title at `:767` (Claim 22).
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** none

(r3, part of r3's compound claim on the branch's new and changed test names) Each name was read against its body (paraphrased — no quote available because r3's compound covers nine tests and quotes only some of them). The test is the one r1 (Claim 5a evidence) and r2 (Claim 5a) cite: it asserts status 1, empty stdout and "needs a default branch" on stderr. r3-E2: 68 ok lines.

**Evidence:** `test/scripts/dev-cycle.bats:1153-1158`, `fc-r3/logs/bats-base.out`

---

## Claim 27: test "check_answer reads git only: no ROOT_REAL needed, SKIPPED untouched, skip without main by name"

**Location:** `test/scripts/dev-cycle.bats:1160-1175`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title's three properties against the assertions; does not re-run the comment's historical claim that the old working-tree reader added the symlinked archive to SKIPPED (78703f22 reports this as mutation-checked).
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

(r2) The expected output is the no-main skip line, then the archive-not-regular skip, then `skipped=0`, then the same skip from `docs/` with ROOT_REAL unset (`:1171-1174`). It passed in r2-E1.

**Evidence:** `test/scripts/dev-cycle.bats:1160-1175`, `fc-r2/logs/E1-bats-full.log`

---

## Claim 28: "# A symlinked archive on main (and in the working tree): with ROOT_REAL set at the top level, the old working-tree reader added it to SKIPPED."

**Location:** `test/scripts/dev-cycle.bats:1163-1164`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main's check_answer calling `skipped`; does not re-run main's code (78703f22's message says the mutation was checked).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r2 (Claim 27 scope): the historical claim was not re-run by r2

(r1) main's check_answer held `if skipped "$f"; then echo "skip $a: $SKIP_AT is not a plain file or directory, so $f is not read"; return; fi` (removed in the diff), and `skipped` appends to SKIPPED, `scripts/lib/dev-cycle-read.sh:125`: `skipped() { need_root; SKIP_AT="$(blocker "$1" "${2:-file}")"; [[ -n "$SKIP_AT" ]] || return 1; SKIPPED+=("$SKIP_AT"); }`.

**Evidence:** `test/scripts/dev-cycle.bats:1159-1174`, `scripts/lib/dev-cycle-read.sh:125`

---

## Claim 29: test "a NUL byte refuses a brief or a questions file, never dropped into a value; main_entry fails closed"

**Location:** `test/scripts/dev-cycle.bats:1177-1193`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief, the questions file and main_entry's error without main or with a bad MAIN_SHA; does not cover awks other than mawk.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

(r2) The test asserts the brief skip, the questions skip at `line 4`, and `error` / `refused [odd 2 nul] 0` / `error` (`:1190-1192`). It passed in r2-E1.

**Evidence:** `test/scripts/dev-cycle.bats:1177-1193`, `fc-r2/logs/E1-bats-full.log`

---

## Claim 30: T31 tests "a brief shaped like the skill's template parses: check_brief and brief_fields agree" and "brief_fields reads each machine line's first unfenced copy from main in one pass; check_brief agrees"

**Location:** `test/scripts/dev-cycle.bats:1195-1208`, `test/scripts/dev-cycle.bats:1210-1243`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the titles and the :1219 and :1230 comments against the assertions; "in one pass" is checked statically (one awk invocation, `scripts/lib/dev-cycle-read.sh:297`); the template test does not compare against the skill's live template text.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

(r2) The first test asserts `[Status: open] [unset]` and `ok $b open ...` (`:1207`). The second asserts all six keys from the first unfenced copies, ignoring the fenced `Status: done`/`Branch: fenced` and the later duplicates. It also asserts that the working-tree overwrite is ignored, and the `odd`/`unbalanced` refusals (`:1226-1242`). Both passed in r2-E1.

**Evidence:** `test/scripts/dev-cycle.bats:1195-1243`, `scripts/lib/dev-cycle-read.sh:297-303`

---

## Claim 31a: test 67 "an unreadable blob or a tree naming a file twice is a skip, never a fall-through or a read of the other copy"; ":1254 Delete the two blobs ...: neither read may pass as absent or empty"

**Location:** `test/scripts/dev-cycle.bats:1245-1257`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the assertions can fail: three mutants make the test fail; does not cover a caller with no options at all inside the test (r2-E6 covers that outside the suite).
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

(r2) The test passed in r2-E1. Mutants that drop `set -o pipefail` from check_answer (r2-E4 mpf_ans: output `keep Q-1`) or from brief_fields (r2-E4 mpf_bf: no `refused [error]`) each fail at `:1266`. So does one that drops `local -` (r2-E5 mnl: no `caller unchanged`).

**Evidence:** `test/scripts/dev-cycle.bats:1245-1274`, `fc-r2/logs/E4-mpf_ans.log`, `fc-r2/logs/E4-mpf_bf.log`, `fc-r2/logs/E5-mnl.log`

---

## Claim 31b: "# The same without the caller's pipefail: each function sets its own." (asserts `caller unchanged`)

**Location:** `test/scripts/dev-cycle.bats:1260-1266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both functions' own pipefail and their `local -` restore; does not cover a caller with `set +e` (covered separately by r1-E7's no-options probe).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "does not establish coverage of other functions that rely on the caller's pipefail"

(r1) The block runs `set -eu` only, then `check_answer Q-1; brief_fields "$2" || echo "refused [$BRIEF_ODD]"; [[ -o pipefail ]] || echo "caller unchanged"` and expects the skip, `refused [error]` and `caller unchanged`. Each of m3-m6 fails it (r1-E4): m3 prints `keep Q-1`, m4 loses `refused [error]`, m5 and m6 lose `caller unchanged`.

**Evidence:** `test/scripts/dev-cycle.bats:1260-1266`, `fc-r1/logs/mut3.txt`, `fc-r1/logs/mut6.txt`, `fc-r3/logs/bats-ans_nopf.out`, `fc-r3/logs/bats-bf_nopf.out`

---

## Claim 32: "# A tree that lists questions.md twice (a symlink first, which git reads): error."

**Location:** `test/scripts/dev-cycle.bats:1267`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's read of the duplicated name and the test's expected skip; does not cover how other git commands (checkout, fsck) treat such a tree.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: `git mktree` accepts the duplicate; the error comes from main_entry's dup detection, not a failed ls-tree

(r1) r1-E8 reproduces the test's tree: `git cat-file -p "$w:questions.md"` prints `x`, the symlink blob listed first. The test expects `skip Q-1: the default branch's tree could not be read, so docs/working/questions.md is not read` and passes (r1-E1).

**Evidence:** `test/scripts/dev-cycle.bats:1267-1273`, `fc-r1/logs/dup-read.txt`, `fc-r1/logs/bats-full.txt`

---

## Claim 33: test "--help prints the whole header, through its last line"

**Location:** `test/scripts/dev-cycle.bats:1276-1280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's power to catch a too-short fixed range (main's and iteration 3's); does not check every middle line of the help.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: control mutant `'2,81p'` passes the test (r3-E4)

(r1) The test asserts `[[ "${lines[0]}" == "Gather the mechanical signals"* ]] && [[ "${lines[${#lines[@]}-1]}" == *"Printed repo text is data." ]]`. It passes on HEAD (r1-E1) and fails against both mutants: m1 (`sed -n '2,80p'`) and m2 (`sed -n '2,77p'`) each report `not ok 1 --help prints the whole header, through its last line` at the last-line assertion (r1-E3).

**Evidence:** `test/scripts/dev-cycle.bats:1276-1280`, `fc-r1/logs/mut1.txt`, `fc-r1/logs/mut2.txt`

---

## Claim 34: c8435580: "dev-cycle.sh --check-answer exits 1 without such a branch, like --check-brief and --check-branch"

**Location:** commit `c8435580` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit code and stderr; same evidence as Claim 5a.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

(r2) `echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1` (`scripts/dev-cycle.sh:194`). The test at `test/scripts/dev-cycle.bats:1153-1158` passed in r2-E1.

**Evidence:** `scripts/dev-cycle.sh:193-195`, `test/scripts/dev-cycle.bats:1153-1158`

---

## Claim 35: c8435580: "check_brief also skips a brief whose directory is not a directory on main (before, ls-tree printed nothing and it read as 'new')"

**Location:** commit `c8435580` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the symlinked-parent-directory case before and after the change, and the Status read through brief_fields; does not re-test gitlinks (override row 230).
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "the old behavior was read, not run" (static, Medium)

(r2) r2-E8 put a symlinked `docs/working/briefs` on main and a plain copy in the working tree. Main's dev-cycle.sh printed `ok docs/working/briefs/2026-01-01-a.md new`, while the branch's printed `skip docs/working/briefs/2026-01-01-a.md: docs/working/briefs is not a directory on the default branch`. The code is `notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch"; return ;;` (`scripts/lib/dev-cycle-read.sh:336`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:321-360`, `fc-r2/logs/E8-notdir.log`

---

## Claim 36a: 4aa2e98e: "R3: --help printed a fixed `sed -n '2,80p'` that 78703f22's new help line pushed past, so help stopped mid-sentence."

**Location:** commit `4aa2e98e` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the history of the help range across the branch; does not establish who introduced `2,80p` beyond c8435580, where it was in sync with the header.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: 78703f22 added the "or a default branch whose tree or file could not be read" help line

(r1) r1-E10: `main` `'2,77p'` with the first non-comment line at 79 (header ends at 77, fits); `c8435580` and `2da477b7` `'2,80p'` with the header ending at 80 (line 81 empty, code at 82: fits); `78703f22` and `722884c7` `'2,80p'` with the header ending at 81 (`# default branch (for the digest, --check-brief, --check-bra...`), so that last line was cut; `4aa2e98e` `'2,/^[^#]/{/^#/p}'`.

**Evidence:** `scripts/dev-cycle.sh:81`, `scripts/dev-cycle.sh:112`, `fc-r1/logs/mut1.txt`

---

## Claim 36b: 4aa2e98e: "It now prints the header up to the first non-comment line; a test checks the last line."

**Location:** commit `4aa2e98e` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new range and the test; "first non-comment line" carries the empty-line nuance of Claim 6a.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r2: "first non-comment line" carries Claim 6a's imprecision · r3: verdicted with the help output (Claim 6b), not BSD sed

(r1) The range at 4aa2e98e is `'2,/^[^#]/{/^#/p}'` (`scripts/dev-cycle.sh:112`); the test is Claim 33, which fails against the old ranges (r1-E3).

**Evidence:** `scripts/dev-cycle.sh:112`, `test/scripts/dev-cycle.bats:1276-1280`, `fc-r1/logs/mut1.txt`, `fc-r1/logs/mut2.txt`

---

## Claim 37: 4aa2e98e: "A17: check_answer and brief_fields set pipefail for themselves (`local -; set -o pipefail`), so a failed `git cat-file` is caught whatever the caller set; the caller's options come back on return. Tested under `set -eu` alone, and a mutant without it fails."

**Location:** commit `4aa2e98e` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code, the test and the mutant claim on bash 5.2; the literal snippet `local -; set -o pipefail` is a condensed form of `local - out l; set -o pipefail` and the `local - a=...` line, not a quote.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the literal `local -; set -o pipefail` is shorthand for the code's `local - out l; set -o pipefail` (equivalent, r3-E7) · r2: the "caller's options come back" residue on bash 4.4-5.0 is Claim 15b · r3: "does not establish the commit's own mutant run (re-run here, not observed)"

(r1) See Claims 15a and 31b: r1-E7 (no options and `set -eu`), r1-E5 (options restored after `return 1`), r1-E4 (m3 and m4, each "without it", fail the test).

**Evidence:** `scripts/lib/dev-cycle-read.sh:292`, `scripts/lib/dev-cycle-read.sh:548`, `fc-r1/logs/probe-noopts.txt`, `fc-r1/logs/probe-localdash.txt`, `fc-r1/logs/mut3.txt`, `fc-r1/logs/mut4.txt`

---

## Claim 38a: 4aa2e98e: "A14/A15: the help and SKILL.md say a working-tree-only answer reads what main's copy says (usually open or no such entry)."

**Location:** commit `4aa2e98e` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of the described wording; the help's own wording precision is Claim 2b.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: the parenthetical "usually open or no such entry" appears only in SKILL.md; the help says "until committed" instead

(r1) `scripts/dev-cycle.sh:58-59`: `branch's commit (an answer only in the working tree is not seen:` / `it reads what main's copy says, until committed)`; `skills/dev-cycle/SKILL.md:294-295`: `(it reads what main's copy says, usually `open` or no such entry)`. The help itself does not say "usually open or no such entry"; the commit groups both files under one parenthetical, which describes SKILL.md's text (minor; the help carries the substance).

**Evidence:** `scripts/dev-cycle.sh:56-59`, `skills/dev-cycle/SKILL.md:292-295`

---

## Claim 38b: 4aa2e98e: "A16: --check-answer's skip list names 'not a question ID' and a heading in both files."

**Location:** commit `4aa2e98e` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two named additions; completeness of the whole list is Claim 4.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

(r1) `scripts/dev-cycle.sh:63-64`: `<reason>" when it cannot be read (not a question ID, no such` / `entry, a heading twice in one file or in both files, ...`.

**Evidence:** `scripts/dev-cycle.sh:62-71`

---

## Claim 39: 4aa2e98e: "Override-log rows: A18 and iteration 3's C9 residue, C11-C15."

**Location:** commit `4aa2e98e` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers row presence; does not judge the rows' decisions (settled).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: `git show 4aa2e98e --stat` lists `docs/reviews/override-log.md | 7 +++++++`, so the rows were added in this commit

(r1) `docs/reviews/override-log.md:232` names A18; `:233`-`:237` name iteration 3 C11, C12, C13, C14, C15; `:238` names "iteration 3 C9 residue".

**Evidence:** `docs/reviews/override-log.md:232-238`

---

## Escalations

- **E1** — `scripts/dev-cycle.sh:112`: BSD/macOS sed portability of the new `--help` range `sed -n '2,/^[^#]/{/^#/p}'` (no `;` before `}`); if macOS hosts are in scope, `{/^#/p;}` is the conservative spelling (not executed). Raised by r1 (Escalate) and r3 (Escalate); r2 listed it as Out of scope (no BSD sed in the sandbox). Addressee: api-consistency-reviewer / architecture-review (r1), api-consistency-reviewer / orchestrator (r3).
- **E2** — `scripts/lib/dev-cycle-read.sh:292`, `scripts/lib/dev-cycle-read.sh:548`: whether a minimum bash version should be stated for the lib now that `local -` needs bash 4.4 (r1), or 5.1+ for `local -` to restore pipefail (r2, Claim 15b). A portability/contract question, not a correctness defect in the read check. Raised by r1 (Escalate) and r2 (Escalate); r3 listed bash < 4.4 as Out of scope. Addressee: api-consistency-reviewer / architecture-review (r1), api-consistency-reviewer or orchestrator (r2).
- **E3** — `test/scripts/dev-cycle.bats:767`: Claim 22, a stale test title new to this pass and not in the override log. Raised by r2 (Escalate). Addressee: orchestrator / rubric synthesis.

## Verdict stability

- Total clusters (claim rows, sub-claims counted separately): 49
- All reporting replicates agreed: 46
- Verdicts disagreed: 3
  - Claim 2a: r1=Mostly accurate (compound) · r2=— · r3=Verified (r1's compound verdict is carried by 2b)
  - Claim 6b: r1=Mostly accurate (compound) · r2=Verified · r3=Verified (r1's compound verdict is carried by 6a)
  - Claim 15b: r1=Verified (compound) · r2=Unverifiable · r3=Verified (compound)
- Agreement rate: 46/49 = 93.9%
- Single-replicate detections (counted as agreed; one reporting replicate): Claims 22 (r2), 23 (r3), 26 (r3), 28 (r1), 34 (r2). Excluding them, 41/44 = 93.2%.
- No Incorrect verdict from any replicate, so no blocking verdict depends on a single replicate; the one non-Verified single-replicate detection is Claim 22 (Stale, r2).

## Submitted Claims

## Claim 40: "check_answer prints a skip line ("could not be read from the default branch") when main's questions.md blob cannot be read, under caller options -euo pipefail, -eu, and +e +u, and leaves the caller's pipefail setting as it found it."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:548`, `scripts/lib/dev-cycle-read.sh:561-562`
**Type:** Error-handling / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a deleted loose object for `docs/working/questions.md` while the archive holds a conflicting ANSWERED entry (a fall-through would print `keep Q-1`), under the caller option sets `-euo pipefail`, `-eu`, `+e +u` and `-e -o pipefail -o noglob`. In each, the skip line prints, there is no fall-through, and `$-` plus the pipefail state match before and after, early-return paths included. It does not establish five things: behaviour on bash older than 5.2 (`local -` semantics; see Claim 48), a packed or truncated object, a read that fails after awk has already printed an answer, git's own `fatal:` line on stderr (it reaches the caller unscrubbed when the lib is used directly; override row 238), or the archive's own unreadable blob.

The function makes pipefail local, and the read's failure branch returns:

```bash
# scripts/lib/dev-cycle-read.sh:548
  local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields
# scripts/lib/dev-cycle-read.sh:560-562
    # A failed read is a skip, never a fall-through to the other file.
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
      || { echo "skip $a: $f could not be read from the default branch"; return; }
```
(excerpt ends :562; enclosing check_answer() continues to :575 — read)

Probe: `./probe.sh /workspace/.claude/wt-build-loop-u1a/scripts/lib/dev-cycle-read.sh`, cwd `$S/opts`, 2026-10-05T16:48:13Z, exit 0. Controls: `drop Q-1` with the blobs intact, and `keep Q-1` with the archive alone. After the blob is deleted, every option set prints `skip Q-1: docs/working/questions.md could not be read from the default branch`. The state lines `before:`/`after check_answer:` are identical in each, for example `[ehuBc set +o pipefail]` both times under `-eu`, and `[hBc set +o pipefail]` both times under `+e +u`. Mutant (`$S/opts/mutant-nopipefail.sh`, `set -o pipefail` removed from both functions), same probe at 16:48:24Z: under `-eu` it prints `keep Q-1`, which is the fall-through. The function's own pipefail is load-bearing.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:547-575`, `$S/opts/probe.sh`, `$S/opts/probe.out`, `$S/opts/mutant.out`

---

## Claim 41: "brief_fields returns 1 with BRIEF_ODD=error when cat-file fails or awk alone fails, under -eu."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:292`, `scripts/lib/dev-cycle-read.sh:297-304`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two failures: a deleted brief blob, and an `awk` that exits 2 after draining stdin (a PATH shim, which `env LC_ALL=C awk` resolves) with the blob intact. Under `-eu`, and also under `-euo pipefail` and `+e +u`, brief_fields returns 1 with `BRIEF_ODD=error` and 0 keys. It does not establish an awk that crashes after printing partial key lines, nor bash versions other than 5.2.

```bash
# scripts/lib/dev-cycle-read.sh:292-294
  local - out l; set -o pipefail
  BRIEF=(); BRIEF_ODD=""
  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
# scripts/lib/dev-cycle-read.sh:303-304
    END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline; else for (i = 1; i <= nk; i++) print kv[i] }')" \
    || { BRIEF_ODD=error; return 1; }
```
(excerpt ends :304; enclosing brief_fields() continues to :312 — read; the `while read` loop at :305-311 runs only on success)

Runs. (1) The deleted blob, in `$S/opts/probe.sh` (2026-10-05T16:48:13Z, exit 0): `brief_fields rc=1 odd=[error] keys=0` under all four option sets. (2) The awk shim, run inline from cwd `$S/opts/repo2` with `PATH="$S/opts/shim:$PATH"` at 16:48:24Z: `-eu: brief_fields rc=1 odd=[error] keys=0`, and the same line for `-euo pipefail` and `+e +u`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-312`, `$S/opts/probe.out`, `$S/opts/awkfail.out`, `$S/opts/shim/awk`

---

## Claim 42: "check_answer reads only main_entry and `git cat-file blob "$MAIN_SHA:$f"` over a two-item constant list; a working-tree-only answer reads open (test 60, T34)."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:547-575`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git argv check_answer issues for two IDs (logged by a git PATH shim): `ls-tree -t --full-tree <sha> -- docs docs/working <file>` (main_entry) and `cat-file blob <sha>:<file>`, for the two constant files only. It also covers the working-tree independence case: a working-tree-only ANSWERED entry reads `open`, and still does after the working-tree questions.md is made unreadable (mode 000) and the archive is replaced by a dangling symlink. awk gets no file operand. It does not establish syscall-level absence of file opens (no strace in the sandbox), nor anything about git's own repository discovery, which uses the current directory.

```bash
# scripts/lib/dev-cycle-read.sh:551-552
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
```
(excerpt ends :552; enclosing check_answer() continues to :575 — read; the only other external command is the `git cat-file blob … | env LC_ALL=C awk …` pipeline at :561, which passes awk no file name)

Probe: `./probe.sh`, cwd `$S/s3`, 2026-10-05T16:51:00Z, exit 0. Output: `open Q-1`, `open Q-2`, then exactly 8 logged argv lines, alternating `git ls-tree -t --full-tree <sha> -- docs docs/working docs/working/questions{,-archive}.md` and `git cat-file blob <sha>:docs/working/questions{,-archive}.md`. After the working tree was broken, the output was again `open Q-1`, `open Q-2`. Bats test 60 (T34) passed in the full run.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:547-575`, `scripts/lib/dev-cycle-read.sh:258-274`, `test/scripts/dev-cycle.bats:1118-1135`, `$S/s3/probe.sh`, `$S/s3/probe.out`, `$S/bats/bats-full.out`

---

## Claim 43: "4aa2e98e's check_brief and check_answer run within noise of 722884c7, with identical git call counts (check_brief: cat-file 1, log 1, ls-tree 2; check_answer: cat-file 2, ls-tree 2) and byte-identical output."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:321-360`, `scripts/lib/dev-cycle-read.sh:547-575`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a fixture with both questions files present (20 answered and 20 open entries), and a brief whose Status line was committed. The counts are per call after resolve_main, for an `ok … open` brief and for IDs that answer, read open and are absent. Output was compared over 41 IDs and four brief arguments. Timing came from 30 alternating runs per side. It does not establish the counts in other shapes. With an absent archive check_answer issues 1 cat-file. A brief that skips before brief_fields issues no cat-file. The `:358` fallback issues 2 logs. Other machines or loads were not measured.

The two revisions differ in code only by `local -` and `set -o pipefail` at `:292` and `:548` (paraphrased — no quote available because this summarises `git diff 722884c7 4aa2e98e -- scripts/lib/dev-cycle-read.sh`, a 6-line diff, reproduced above in my run log rather than in the source).

Counts: an inline loop sourced each revision's lib with a logging git shim (`$S/perf/shim/git`), cwd `$S/perf/repo`, about 16:48Z. Both revisions give `1 cat-file, 1 log, 2 ls-tree` for check_brief and `2 cat-file, 2 ls-tree` for `check_answer Q-5|Q-25|Q-99`, with identical answer lines. Timing and bytes: `../timing.sh $S`, cwd `$S/perf/repo`, 2026-10-05T16:49:11Z, exit 0. It printed `byte-identical` (cmp of 41-line answer output and 4-line brief output). Medians, old vs new: `--check-answer` with 41 IDs 312.9 vs 315.0 ms (+0.7%); `--check-brief` × 5 73.5 vs 74.2 ms (+0.9%). Minima differ by under 2%.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-360`, `scripts/lib/dev-cycle-read.sh:547-575`, `$S/perf/counts.out`, `$S/perf/timing.sh`, `$S/perf/timing.out`, `$S/perf/timing.raw`, `$S/perf/ans.old`, `$S/perf/ans.new`

---

## Claim 44: "The `2,/^[^#]/` help range costs the same as `2,80p` (sed reads the whole 471-line file both times); --help takes ~8 ms."

**Submitted by:** performance-reviewer
**Location:** `scripts/dev-cycle.sh:112`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU sed 4.9. Neither program stops reading early: the script plus a 10 MB tail was piped in, and the producer exited 0 for both, while the control `2,80p;80q` got SIGPIPE (141). The file has 471 lines. Wall time of the whole `--help` invocation is about 8 ms on both revisions. It does not establish BSD or busybox sed, nor a per-sed-process time apart from the script's startup.

```bash
# scripts/dev-cycle.sh:111-112
    # The header, up to the first line that is not a comment (no fixed range to go stale).
    -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```

Probe: `./probe.sh`, cwd `$S/sedread`, 2026-10-05T16:49:46Z, exit 0. Output: `sed -n '2,80p': producer status 0`, `sed -n '2,/^[^#]/{/^#/p}': producer status 0`, `sed -n '2,80p;80q': producer status 141`, and `471` lines. `--help` timing from `$S/perf/timing.out`: median 8.0 ms (722884c7, `2,80p`) against 7.9 ms (4aa2e98e).

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/dev-cycle.sh:111-112`, `$S/sedread/probe.sh`, `$S/sedread/probe.out`, `$S/perf/timing.out`

---

## Claim 45: "--help prints the whole header, and test 68 checks its last line (scripts/dev-cycle.sh:111-112; bats end)."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/dev-cycle.sh:111-112`, `test/scripts/dev-cycle.bats:1276-1280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's header. `--help` output is byte-identical to lines 2-81 with `# ` stripped (80 lines, ending "Printed repo text is data."). Line 82 is empty and line 83 is `set -euo pipefail`. Test 68 fails against the `2,80p` and `2,77p` mutants. It does not establish the range's behaviour if the header later gains a line that is empty or starts with an indented `#` (`^[^#]` skips an empty line, so such a header would run on), nor BSD sed's acceptance of `{/^#/p}` without a `;`.

```bash
# test/scripts/dev-cycle.bats:1276-1280
@test "--help prints the whole header, through its last line" {
    run --separate-stderr bash "$DC" --help
    [ "$status" -eq 0 ] && [[ "${lines[0]}" == "Gather the mechanical signals"* ]] \
        && [[ "${lines[${#lines[@]}-1]}" == *"Printed repo text is data." ]] || { echo "$output"; return 1; }
}
```

Runs from cwd `$S/help`, 2026-10-05T16:49:59Z: `bash dev-cycle.sh --help > help.out` exited 0. `cmp help.out expect.out` printed "help == header lines 2-81", where `expect.out` is `sed -n '2,81p' | sed 's/^# \{0,1\}//'`. `grep -v '^#'` over lines 1-81 found nothing. Two mutants were run in a copy of `scripts/` and the test file under `$S/help/mut`, each with `bats -f 'help prints the whole header'`. `2,80p` gave exit 1 (`not ok 1`), and so did `2,77p`. The real file gave exit 0.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/dev-cycle.sh:1-83`, `test/scripts/dev-cycle.bats:1276-1280`, `$S/help/help.out`, `$S/help/expect.out`, `$S/help/mutants.out`, `$S/help/real.out`

---

## Claim 46: "The --check-answer default-branch gate is consistent across help (:72-73), Exit text (:81), code (:193) and its test (bats ~:1153)."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/dev-cycle.sh:72-73`, `scripts/dev-cycle.sh:81`, `scripts/dev-cycle.sh:193`, `test/scripts/dev-cycle.bats:1153-1158`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four sites named. All say --check-answer needs a default branch found by name and exits 1 without one. A repo whose only branch is `trunk` gives exit 1, empty stdout and `--check-answer needs a default branch …` on stderr, the same as --check-brief and --check-branch. --check-path and --check-write exit 0 there. It does not cover other sites. The title of `test/scripts/dev-cycle.bats:767` ("--check-brief and --check-branch need a default branch found by name; the others do not") is now stale: the body tests only --check-path as an "other", but the title contradicts the gate. Stage 1 replicate r2 flagged this.

Help: `#   --check-brief, --check-branch and --check-answer need a default branch` / `#   found by name (origin/HEAD, main or master): they read its commit.` (`scripts/dev-cycle.sh:72-73`). Exit text: `# default branch (for the digest, --check-brief, --check-branch and --check-answer)` (`scripts/dev-cycle.sh:81`). Code: `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then` (`scripts/dev-cycle.sh:193`), followed by `exit 1` at `:194`. Test: `[ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"needs a default branch"* ]]` (`test/scripts/dev-cycle.bats:1157`).

Probe: `./probe.sh`, cwd `$S/gate`, 2026-10-05T16:50:10Z, exit 0. For example: `--check-answer Q-1 -> exit 1 stdout=[] stderr=[--check-answer needs a default branch (origin/HEAD, main or master); found none]`. After the branch is renamed to `main`, it gives `exit 0 [keep Q-1]`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/dev-cycle.sh:72-81`, `scripts/dev-cycle.sh:188-195`, `test/scripts/dev-cycle.bats:767-778`, `test/scripts/dev-cycle.bats:1153-1158`, `$S/gate/probe.sh`, `$S/gate/probe.out`

---

## Claim 47: "The --check-answer skip list in the help names every skip reason check_answer can print through dev-cycle.sh."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/dev-cycle.sh:62-71`, `scripts/lib/dev-cycle-read.sh:547-575`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full enumeration. check_answer has 13 echo lines; 12 are skips. The `odd` line carries 7 oddwhy reasons, from the `refuse("…")` calls: bom, comment, cr, fence (twice), html, nul, refdef. Each of the 18 distinct reachable skips was produced through `dev-cycle.sh --check-answer` and maps to a phrase in the help. The one unmapped skip ("no default branch found by name …", `:550`) is unreachable through dev-cycle.sh, because `:193-194` exits 1 first (Claim 46). It does not establish the wording's precision for each reason (the help paraphrases), nor reasons reachable only when the lib is called directly.

The enumeration, by grepping `echo` in `:547-575` (paraphrased — no quote available because it covers 13 lines; the full list is in my run log and every line's output is quoted in `$S/skips/probe.out`): not a question ID (:549); no default branch (:550); notdir, error and notfile (:556-558); cat-file failure (:562); dup (:564); odd, unbalanced and quoted (:566-568); both files (:570); the answer itself (:573); no such entry (:574).

Mapping to the help at `scripts/dev-cycle.sh:63-71` ("not a question ID, no such entry, a heading twice in one file or in both files, a code fence never closed or not in plain column-0 form, a line starting (after blanks) with < …, a line leaving a <!-- open, … link reference definition …, a stray carriage return, a NUL byte, a byte-order mark on line 1, a question heading inside a fence, a questions file that is not a regular file under plain directories on the default branch, or a default branch whose tree or file could not be read"):

| Probe case | Printed skip (abridged) | Help phrase |
|---|---|---|
| notid | not a question ID | not a question ID |
| noentry | no such entry … on the default branch | no such entry |
| dup / both | more than one entry … / in both … | a heading twice in one file or in both files |
| unbalanced / fence | fence … never closed / fence-like line not plain column-0 | code fence never closed or not in plain column-0 form |
| html / comment / refdef | starts with < / opens an HTML comment / link reference definition | the three matching phrases |
| cr / nul / bom | carriage return / NUL byte / byte-order mark | stray carriage return / NUL byte / byte-order mark on line 1 |
| quoted | question heading inside a code fence | a question heading inside a fence |
| notfile / notdir | not a regular file / docs/working is not a directory | not a regular file under plain directories |
| treeerror / lstreefail / unreadable | tree could not be read / file could not be read | default branch whose tree or file could not be read |

Probe: `./probe.sh`, cwd `$S/skips`, 2026-10-05T16:50:36Z, exit 0. There are 18 cases, each in a fresh repo. "treeerror" uses a tree listing questions.md twice, built with `git mktree`. "lstreefail" deletes the root tree object, and "unreadable" deletes the blob.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/dev-cycle.sh:56-73`, `scripts/dev-cycle.sh:193-194`, `scripts/lib/dev-cycle-read.sh:213-241`, `scripts/lib/dev-cycle-read.sh:534-575`, `$S/skips/probe.sh`, `$S/skips/probe.out`

---

## Claim 48: "check_answer and brief_fields set pipefail themselves and restore the caller's options on return (bash 5.2); test 67 asserts "caller unchanged"."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:292`, `scripts/lib/dev-cycle-read.sh:548`, `test/scripts/dev-cycle.bats:1261-1266`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15. `$-` and the pipefail state are unchanged after both functions under four caller option sets, including after early returns (`check_answer bogus`, `brief_fields ../x`, an absent ID). Test 67 fails under each of four mutants: `local -` dropped from either function, or `set -o pipefail` dropped from either. It does not establish bash 4.4-5.0, where `local -` saves only single-letter options and pipefail is a `-o` option, so its restore there is unverified (stage 1 r2). No minimum bash version is stated in the repo. It does not establish options other than those probed either.

```bash
# test/scripts/dev-cycle.bats:1261-1266
    # The same without the caller's pipefail: each function sets its own.
    run --separate-stderr env LC_ALL=C bash -c 'set -eu; source "$1"; ROOT_REAL="$(pwd -P)"; resolve_main
        check_answer Q-1; brief_fields "$2" || echo "refused [$BRIEF_ODD]"; [[ -o pipefail ]] || echo "caller unchanged"' _ \
        "$REPO_ROOT/scripts/lib/dev-cycle-read.sh" "$b"
    [ "$output" = "skip Q-1: docs/working/questions.md could not be read from the default branch
refused [error]
caller unchanged" ] || { echo "$output $stderr"; return 1; }
```
(excerpt ends :1266; enclosing test continues to :1274 — read)

Runs. (1) `$S/opts/probe.sh` (Claim 40), 2026-10-05T16:48:13Z: `after early returns: […] same=yes` for all four option sets. (2) Mutants of test 67 under cwd `$S/t67`, 2026-10-05T16:50:47Z, each run with `bats -f 'an unreadable blob or a tree naming a file twice'`. nolocal-brief, nolocal-answer, nopipefail-answer and nopipefail-brief each gave exit 1, `not ok 1`. nopipefail-answer printed `keep Q-1`, the fall-through.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-312`, `scripts/lib/dev-cycle-read.sh:547-575`, `test/scripts/dev-cycle.bats:1245-1274`, `$S/opts/probe.out`, `$S/t67/mutants.out`

---

## Claim 49: "check_brief (:343) and check_answer (:562) use the same "could not be read from the default branch" wording."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:343`, `scripts/lib/dev-cycle-read.sh:562`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the trailing phrase of the two unreadable-blob skip lines. Their subjects differ by design ("the brief" against the file path). It does not establish that the other skip lines in the two functions match each other. For example, check_brief's `error` line has no ", so … is not read" tail, while check_answer's has one.

`error) echo "skip $a: the brief could not be read from the default branch" ;;` (`scripts/lib/dev-cycle-read.sh:343`) and `|| { echo "skip $a: $f could not be read from the default branch"; return; }` (`scripts/lib/dev-cycle-read.sh:562`). Observed output: `skip Q-1: docs/working/questions.md could not be read from the default branch` (`$S/opts/probe.out`). Test 67 asserts `skip $b: the brief could not be read from the default branch`, and it passed in the full run.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:340-347`, `scripts/lib/dev-cycle-read.sh:560-562`, `test/scripts/dev-cycle.bats:1257-1259`, `$S/opts/probe.out`, `$S/bats/bats-full.out`

---

## Claim 50: "bats test/scripts/dev-cycle.bats passes 68/68 at 4aa2e98e."

**Submitted by:** api-consistency-reviewer
**Location:** `test/scripts/dev-cycle.bats:1`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this sandbox (bash 5.2.15, git 2.39.5, mawk, `LC_ALL=C.UTF-8`, TMPDIR unset) at 4aa2e98e's code files. It does not establish a dotted TMPDIR (test 21 is known to fail there, outside this diff), gawk or other awks, or other git versions.

Run: `bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-build-loop-u1a`, 2026-10-05T16:46:44Z, exit 0. 68 lines start `ok` and none `not ok`. The last line is `ok 68 --help prints the whole header, through its last line`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/scripts/dev-cycle.bats:1-1280`, `$S/bats/bats-full.out`, `$S/bats/start`

---

## Claim 51: "check_answer no longer depends on the working tree: no need_root, no ROOT_REAL, nothing added to SKIPPED (lib:547-575; bats:1160)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:547-575`, `test/scripts/dev-cycle.bats:1160-1175`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer and every lib function it reaches (main_by_name, main_entry, oddwhy). None references ROOT_REAL, SKIPPED, SKIP_AT, need_root, skipped, rawfile, plaindir, blocker, inrepo, dirok or a `[[ -f/-e/-d` test. Test 63 passes: with ROOT_REAL unset, from `docs/`, a symlinked archive leaves `skipped=0`. Claim 42 shows a broken working tree does not change an answer. It does not establish independence from the current directory for git's own repository discovery: the caller must still be inside the repo, and `--full-tree` makes paths independent of the subdirectory.

The removed working-tree reads are visible in the diff: `-    if skipped "$f"; then …` and `-    [[ -f "$f" ]] || continue` (paraphrased — no quote available because those lines no longer exist in the file at HEAD; they are in the diff hunk `@@ -462,13 +538,28 @@` of `shared/diff.patch`).

Runs: `./enum.sh` (cwd `$S/g1`, about 16:51Z, exit 0) printed `check_answer (547,575): 0 working-tree references`, and the same for main_entry (258,274), main_by_name (246) and oddwhy (231,241). Bats test 63 passed in the full run.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:231-274`, `scripts/lib/dev-cycle-read.sh:547-575`, `test/scripts/dev-cycle.bats:1160-1175`, `$S/g1/enum.sh`, `$S/g1/enum.out`, `$S/bats/bats-full.out`

---

## Claim 52: "A brief has one parser: check_brief takes its status from brief_fields (lib:289-312, 340-351)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:289-312`, `scripts/lib/dev-cycle-read.sh:340-351`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the brief's field values in `scripts/dev-cycle.sh` and the lib. The only reader of a brief's content is brief_fields' awk, check_brief's status is `BRIEF[status]`, and dev-cycle.sh touches `docs/working/briefs` only through `skipdir` (`:463`). It does not establish two things. First, check_brief's commit lookup `git log … -G'^Status: '` (`:357`) is a separate, deliberately fence-blind line match over the brief's history, documented at `:352-356` (iteration 3 Claim 60a, Mostly accurate, made the same point against a broader wording). Second, it does not cover the skill's prose instructions for reading briefs.

```bash
# scripts/lib/dev-cycle-read.sh:340-351
  if ! brief_fields "$a"; then
    case "$BRIEF_ODD" in
      odd\ *) read -r _ n why <<<"$BRIEF_ODD"; echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read" ;;
      error) echo "skip $a: the brief could not be read from the default branch" ;;
      *) echo "skip $a: the code fence opened at line ${BRIEF_ODD#unbalanced } is never closed, so the brief is not read" ;;
    esac
    return
  fi
  st="${BRIEF[status]-}"
  if [[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]; then
    echo "skip $a: its first Status: line is not exactly Status: open, done or dropped"; return
  fi
```
(excerpt ends :351; enclosing check_brief() continues to :360 — read: the git log lookup and the `ok` line)

A grep of `scripts/dev-cycle.sh` and the lib for `Status:|Branch:|Asked:|Policy:|Paths:|Dispatched:|briefs/` in non-comment lines finds only `isbrief`/`writable` path regexes, check_brief's `:349-359`, brief_fields, and ANSWER_AWK's unrelated `**Status:**` (paraphrased — no quote available because this summarises a grep's output, recorded in my session, not a source span). Tests 65 and 66 (check_brief and brief_fields agree, T31) passed.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-360`, `scripts/dev-cycle.sh:463`, `test/scripts/dev-cycle.bats:1195-1243`, override-log row 226

---

## Claim 53: "main_entry is the one function for "regular file under plain directories on main" and answers error on no default branch, an ls-tree failure, or a name listed twice (lib:258-274)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:258-274`
**Type:** Architectural / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `scripts/dev-cycle.sh` and the lib. The enumeration of `ls-tree|cat-file|git show|rev-parse …:` shows one ls-tree (in main_entry) and two `cat-file blob "$MAIN_SHA:…"` reads (brief_fields :297, check_answer :561), each gated on main_entry answering `blob`. The other `cat-file` (`dev-cycle.sh:296`) is a pre-existing `-e "HEAD:$f"` existence check for a decision record's date, which reads HEAD, not main. All six error triggers probed answer `error`: before resolve_main, the current-branch fallback (MAIN_BY_NAME empty), a branch named only `trunk`, a bad MAIN_SHA, a deleted root tree object, and a name listed twice (symlink+regular, and regular+regular). It does not cover the error list as exhaustive. A slash-named tree entry with no real path reads `absent`, not `error` (override row 236). It does not cover scripts outside these two files either.

```bash
# scripts/lib/dev-cycle-read.sh:261-269
  main_by_name || { echo error; return; }
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
  while IFS=$'\t' read -r mode path; do
    [[ -n "$path" ]] || continue
    [[ -z "${m[$path]+set}" ]] || dup=1
    m["$path"]="${mode%% *}"
  done <<<"$out"
  [[ -z "$dup" ]] || { echo error; return; }
```
(excerpt ends :269; enclosing main_entry() continues to :274 — read)

Probe: `./probe.sh`, cwd `$S/g3`, 2026-10-05T16:51:53Z, exit 0. It printed `before resolve_main: error`, `control: blob / absent path: absent / tree: notfile`, `current-branch fallback (MAIN_BY_NAME empty): error`, `bad sha: error`, `only branch trunk (…by name=[]): error`, `root tree object deleted: error`, and both `questions.md listed twice …: error`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:247-274`, `scripts/lib/dev-cycle-read.sh:294-297`, `scripts/lib/dev-cycle-read.sh:552-561`, `scripts/dev-cycle.sh:296`, `$S/g3/probe.sh`, `$S/g3/probe.out`

---

## Claim 54: "Dependencies point one way: dev-cycle.sh -> lib -> git and awk; build-loop.sh appears only in comments."

**Submitted by:** architecture-review
**Location:** `scripts/dev-cycle.sh:91-95`, `scripts/lib/dev-cycle-read.sh:1-575`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** The direction holds. No dev-cycle.sh function (need, skipdir, skipnote, exact, matches, check_path, check_write, check_fix, trig) is used in the lib, and the lib names no script except in comments. The `build-loop.sh` mentions in the four code files are the comments `scripts/lib/dev-cycle-read.sh:3`, `:11` and `scripts/dev-cycle.sh:87`. The lib's outgoing edge list is incomplete for the lib as a whole: besides git and awk it runs perl (`scrub`), grep, tr, realpath and pwd. The functions this diff adds (main_entry, brief_fields, check_answer) use only git, awk and env. Two things are not established: the runtime callback `scrub_reexec` (`bash "$self"`, which re-runs a caller-supplied script path), and the scripts outside these files.

The precise version: "dev-cycle.sh → lib → git, awk, perl, grep, tr, realpath (the new functions: git and awk only)". The lib's re-exec of its caller is `{ DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub` (`scripts/lib/dev-cycle-read.sh:79`). The extra commands appear as `env -u PERL_UNICODE -u PERL5OPT -u PERLIO LC_ALL=C perl -C0 -ne '` (`:50`), `r="$(realpath -e -- "$1" 2>/dev/null)"` (`:93`), `lower() { printf '%s' "$1" | tr …` (`:430`) and `| env LC_ALL=C grep -zaiE …` (`:446`). The command count from a grep of non-comment lines was awk 2, git 14, grep 2, perl 1, pwd 1, realpath 3, tr 2 (paraphrased — no quote available because this is a tally over the whole file, recorded in my session).

**Legibility-target:** for-author

**Evidence:** `scripts/lib/dev-cycle-read.sh:3`, `scripts/lib/dev-cycle-read.sh:11`, `scripts/lib/dev-cycle-read.sh:48-80`, `scripts/lib/dev-cycle-read.sh:93-96`, `scripts/lib/dev-cycle-read.sh:430-458`, `scripts/dev-cycle.sh:87-95`

---

## Claim 55: "--help is taken from the header and a test pins its last line (dev-cycle.sh:111-112; bats:1276-1280)."

**Submitted by:** architecture-review
**Location:** `scripts/dev-cycle.sh:111-112`, `test/scripts/dev-cycle.bats:1276-1280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same evidence as Claim 45. The output is byte-identical to header lines 2-81, and test 68 fails against the `2,80p` and `2,77p` mutants. It does not establish the range's behaviour for a future header with an empty or indented-`#` line, nor BSD sed.

`-h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;` (`scripts/dev-cycle.sh:112`), and the test's `[[ "${lines[${#lines[@]}-1]}" == *"Printed repo text is data." ]]` (`test/scripts/dev-cycle.bats:1279`). Runs: see Claim 45 (cwd `$S/help`, 2026-10-05T16:49:59Z).

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/dev-cycle.sh:111-112`, `test/scripts/dev-cycle.bats:1276-1280`, `$S/help/help.out`, `$S/help/mutants.out`

---

## Claim 56: "The test of the lib's sourced names lists main_entry, brief_fields, BRIEF and BRIEF_ODD (bats:1032, 1036)."

**Submitted by:** architecture-review
**Location:** `test/scripts/dev-cycle.bats:1032`, `test/scripts/dev-cycle.bats:1036`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two lines and the test's power to fail. Test 54, "sourcing the reader lib defines its functions and calls neither git nor perl", fails with `missing main_entry`, `missing brief_fields` and `unset BRIEF_ODD` against the three corresponding mutants. It does not establish detection of an undeclared `BRIEF` alone (not mutated), nor that the test checks `BRIEF`'s associative type (`declare -p` passes for any declared variable).

```bash
# test/scripts/dev-cycle.bats:1032
                 oddwhy check_brief check_branch resolve_main main_by_name main_entry brief_fields lower imported_names check_answer; do
# test/scripts/dev-cycle.bats:1036
        for v in SKIPPED SKIP_AT MAIN MAIN_SHA MAIN_BY_NAME IMPORTED IMPORTED_DONE BRIEF BRIEF_ODD; do declare -p "$v" >/dev/null 2>&1 || echo "unset $v"; done
```
(excerpt ends :1036; enclosing test continues to :1040 — read)

Mutants: a copy of `scripts/` and the test under `$S/g6/mut`, cwd `$S/g6`, 2026-10-05T16:52:24Z, each run with `bats -f 'sourcing the reader lib defines its functions and calls neither git nor perl'`. Renaming `main_entry()` gave exit 1 with `# missing main_entry`. Renaming `brief_fields()` gave exit 1 with `# missing brief_fields`. Dropping `BRIEF_ODD=""` from `:288` gave exit 1 with `# unset BRIEF_ODD`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/scripts/dev-cycle.bats:1024-1040`, `scripts/lib/dev-cycle-read.sh:288`, `$S/g6/mutants.out`, `$S/g6/main_entry.out`, `$S/g6/brief_fields.out`, `$S/g6/BRIEF_ODD.out`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 54** (`scripts/lib/dev-cycle-read.sh:48-80, 430-458`): the direction is right, but the lib also runs perl, grep, tr and realpath, not only git and awk. Say "dev-cycle.sh → lib → git, awk, perl, grep, tr, realpath; the new functions use git and awk only".

### Unverifiable
(none)

## Legibility notes

- The residues named in the Scope fields are already known. `local -` before bash 5.1 (Claims 40, 41, 48) and BSD sed (Claims 45, 55) were escalated by stage 1. The stale bats:767 title (Claim 46) was flagged by stage-1 r2. The slash-named tree entry (Claim 53) is override row 236. The unscrubbed `fatal:` line (Claim 40) is override row 238.
- All claims were checked under mawk and GNU sed only.

