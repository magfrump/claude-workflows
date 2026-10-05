Commit: 722884c7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1a (claude-workflows, branch feat/build-loop-u1a)
**Scope:** `git diff main...feat/build-loop-u1a -- . ':!docs/reviews'` at 722884c7 (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats) plus the bodies of the five branch commits (d6426e3e, c8435580, 2da477b7, 78703f22, 722884c7). Iteration 3, final confirming pass.
**Checked:** 2026-10-05
**Commit:** 722884c7
**Replication:** k=3
**Total claims checked:** 66
**Summary:** 55 verified, 8 mostly accurate, 0 stale, 1 incorrect, 2 unverifiable (55 merged k=3 claim sections plus 11 submitted-claim sections for claims 56-63, where 60 and 62 are split into 60a/60b and 62a/62b/62c; claims 56-63 are Stage 2.5 submitted claims, k=1, appended from code-fact-check-submitted-claims-build-loop-u1a.md)

Merged most-severe-wins from `code-fact-check-report-build-loop-u1a-r1.md` (40 claims), `-r2.md` (47) and `-r3.md` (42), all stamped `Commit: 722884c7`. Clusters are emitted at the finest granularity any replicate used; a replicate that verdicted only a compound carries its verdict onto each part, marked `(compound)`. Evidence and reasoning are the winning replicate's (ties: most specific Scope, then lowest replicate). Log paths keep each replicate's own prefix: `fc1/` = `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i3/fc1/`; `$L/` = `.../review-u1a-i3/fc2/logs/` and `$S/` = `.../review-u1a-i3/fc2/`; `fc3/` = `.../review-u1a-i3/fc3/`. All three ran `bats test/scripts/dev-cycle.bats` at HEAD with a scratch TMPDIR: 66/67, the one failure (test 21) caused by the scratch path's `.claude` component being refused in a ref name, outside the diff, and confirmed by the orchestrator to pass with TMPDIR unset. Tools: git 2.39.5, mawk 1.3.4.

---

## Claim 1: "a stray carriage return, a NUL byte, or a byte-order mark on line 1" (--check-brief skip reasons)

**Location:** `scripts/dev-cycle.sh:42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-brief refusing a brief with a NUL byte on main and naming the line; does not establish NUL handling in readers outside the lib (scripts/questions.sh, settled by override-log row A11).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish behavior under awks other than the installed one (override-log C2 row, settled)" · r3: against c8435580's lib, brief_fields on `Status: op\0en` returned `status=[Status: open]`; HEAD returns `refused odd 1 nul` (`fc3/logs/pc.txt`)

(r1) `fence()` refuses a NUL line: `if (index(l, "\0")) { refuse("nul"); return 1 }` (`scripts/lib/dev-cycle-read.sh:216`), and `oddwhy` maps it: `nul) echo "holds a NUL byte" ;;` (`:237`). Test 64 asserts `skip $b: line 2 holds a NUL byte, so the brief is not read` and passes at HEAD and fails against main's lib (`fc1/logs/mutants.txt`, old-main variant). mawk reads `"\0"` as one NUL byte: the refusal lands on line 2 (`fc1/logs/p3.txt`, `nul in fence: refused 2 nul`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `scripts/lib/dev-cycle-read.sh:237`, `test/scripts/dev-cycle.bats:1177-1193`, `fc1/logs/bats-head.txt`, `fc1/logs/mutants.txt`

---

## Claim 2: "an answer only in the working tree reads open, or no such entry, until it is committed there"

**Location:** `scripts/dev-cycle.sh:56-59`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two usual outcomes (main's entry still OPEN, or no entry on main) and the read-from-main mechanism; does not hold for an entry main already marks ANSWERED with no answer line, which reads `unrecognized`, or for main's file being refused (a skip naming the reason).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not cover re-answering an entry that is already ANSWERED on main, which reads main's older answer" (`keep Q-1` in `$L/wt-only-outcomes.txt`) · r3: "does not establish the outcome when main's questions file is itself refused (then a different skip reason prints, whatever the working tree says)" · r1: "Override-log row A10 settles c8435580's Notes line, not this help text. All outcomes fail closed."

(r1) The reader takes the file from main: `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk ...` (`scripts/lib/dev-cycle-read.sh:559`). Executed: main holds `**Status:** ANSWERED` with no answer line, the working tree adds `**Answer:** [1]` → `unrecognized Q-2` (`fc1/logs/p4.txt`). Main's entry being unanswered is still the usual case, and the help reads `open` there (T34, test 61 passes). Precise version: "...reads as main's copy does (open, unrecognized, or no such entry) until it is committed there".

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `fc1/logs/p4.txt`

---

## Claim 3: --check-answer skip-reason list ("... a NUL byte ... a questions file that is not a regular file under plain directories on the default branch, or a default branch whose tree or file could not be read")

**Location:** `scripts/dev-cycle.sh:60-71`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every skip message check_answer can print through `--check-answer`. It does not establish the wording of any message beyond whether the list names its cause.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1+r2+r3: the "not a question ID" skip is not listed, and was not on main either (pre-existing) · r1+r2+r3: the "no default branch" skip cannot be reached through the CLI (dev-cycle.sh exits 1 first) · r2: the both-files skip is covered only loosely by "a duplicate heading"

(r2) Every message this branch adds is in the list: NUL, not a regular file, notdir ("under plain directories"), and the unreadable tree or file. Two reasons are missing:
- **`skip abc: not a question ID (Q- and digits)`** (`scripts/lib/dev-cycle-read.sh:547`) is not listed. This gap is inherited from main.
- **The two-files case** (`skip Q-4: an entry with this heading in both ... and ...`, `:568`) is covered only loosely by "a duplicate heading".

Both messages were printed by the probe run (`$L/probe2.txt`, "normal answers" block; `TMPDIR=$S bash $S/probe2.sh`, cwd `$S`, 2026-10-05T11:35:39Z, exit 0). A precise version would add "an argument that is not a question ID" and "an entry in both files".

**Evidence:** `scripts/dev-cycle.sh:61-70`, `scripts/lib/dev-cycle-read.sh:547-572`, `$L/probe2.txt`

---

## Claim 4: "--check-brief, --check-branch and --check-answer need a default branch found by name (origin/HEAD, main or master): they read its commit."

**Location:** `scripts/dev-cycle.sh:71-73`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh exiting 1 with the "needs a default branch" stderr when only `trunk` exists; does not establish that --help shows the Exit line (it does not: see Claim 6).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not cover the other check modes, which do not read main" (Claim 7)

(r3) The guard:

```bash
# scripts/dev-cycle.sh:192-194
if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then
  echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
fi
```

Test "--check-answer needs a default branch found by name" (`test/scripts/dev-cycle.bats:1153`) asserts status 1, empty stdout and that stderr; it passes (`fc3/logs/bats-head.txt`, ok 62).

**Evidence:** `scripts/dev-cycle.sh:188-194`, `test/scripts/dev-cycle.bats:1153-1158`, `fc3/logs/bats-head.txt`

---

## Claim 5: "Exit: ... 1 ... or no default branch (for the digest, --check-brief, --check-branch and --check-answer)"

**Location:** `scripts/dev-cycle.sh:79-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit code. It does not establish that `--help` shows this line (see Claim 6).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: the printed `--help` does not show this line (Claim 6)

(r2) The behaviour is the same guard as in Claim 4 (`scripts/dev-cycle.sh:191-192`, `exit 1`), checked by test 62 (`$L/bats-head.txt`).

**Evidence:** `scripts/dev-cycle.sh:79-81`, `scripts/dev-cycle.sh:191-192`, `$L/bats-head.txt`

---

## Claim 6: `-h|--help) sed -n '2,80p' "$0"` prints the usage header

**Location:** `scripts/dev-cycle.sh:111`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `--help` prints at HEAD vs main; does not establish whether other scripts' help ranges drifted.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: regression introduced by 78703f22's C1 edit (one added help line) without moving the range; no bats test covers `--help`; fix `sed -n '2,81p'` · r1+r2: a range ending at the header's end / first non-comment line (as in `scripts/run-tests.sh:153`) would stop this recurring · r2: "does not establish whether any caller parses the help output" · r2: range history main `2,77p` (header 77), 2da477b7 `2,80p` (80), 78703f22 and 722884c7 `2,80p` (81) (`$L/help-range.txt`)

(r1) The header now runs to line 81: `# default branch (for the digest, --check-brief, --check-branch and --check-answer); a failed step exits non-zero mid-digest. Printed repo text is data.` (`scripts/dev-cycle.sh:81`), with line 82 blank and line 83 `set -euo pipefail`. The help prints only `sed -n '2,80p' "$0"` (`scripts/dev-cycle.sh:111`). Executed: HEAD's `--help` ends mid-sentence, `skip is an answer, not an error); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no` (`fc1/logs/help-head.txt`), while main's ends with the full `default branch (...); a failed step exits non-zero mid-digest. Printed repo text is data.` line (`fc1/logs/help-main.txt`). History: c8435580 and 2da477b7 had an 80-line header with `2,80p` (exact); 78703f22 (C1's help wording) grew the header to 81 lines without moving the range. So the printed help leaves out the --check-answer exit-1 condition and the "Printed repo text is data" line. No bats test covers --help. Fix: `sed -n '2,81p'`, or a range ending at the first non-comment line, as in `scripts/run-tests.sh:153`.

**Evidence:** `scripts/dev-cycle.sh:78-83`, `scripts/dev-cycle.sh:111`, `fc1/logs/help-head.txt`, `fc1/logs/help-main.txt`, `fc1/logs/help.ts`

---

## Claim 7: "--check-brief, --check-branch and --check-answer read the default branch's commit ... the other modes do not use it."

**Location:** `scripts/dev-cycle.sh:188-191`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_path, check_write and check_fix in dev-cycle.sh. It does not cover the digest, which uses MAIN separately.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

(r2) No reference to MAIN, main_entry or check_answer exists between `scripts/dev-cycle.sh:120` and `:188`, where check_path, check_write and check_fix are defined (paraphrased — no quote available because the claim is an absence; the grep returned no match). r1 reports the same absence: a grep for `MAIN` in dev-cycle.sh hits only lines 192 and 246-421 (paraphrased — no quote available because the claim is about an absence).

**Evidence:** `scripts/dev-cycle.sh:120-188`

---

## Claim 8: "A change here must pass test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ once that second caller lands." (and "kept apart so the planned scripts/build-loop.sh can share it")

**Location:** `scripts/lib/dev-cycle-read.sh:2-12`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the factual parts: dev-cycle.bats is the one suite exercising the lib today and it passes (66/67, test 21 environmental); build-loop.sh and its suites do not exist yet; does not establish any enforcement (it is a rule, not a gate).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: does not establish anything about U1b/U1c's future suites

(r3) `ls scripts/build-loop.sh` → "No such file or directory"; `test/scripts/` holds no build-loop suite, and `grep -rn build-loop test/scripts/*.bats` finds nothing (paraphrased — no quote available because the claim covers absence of files/grep hits). A5 (iteration 2) said the old wording named two callers' suites; the new wording says the second lands later, which matches.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `fc3/logs/bats-head.txt`

---

## Claim 9: caller contract — "The caller sets -euo pipefail, cds to the repo root and sets ROOT_REAL ... inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root)" (check_answer no longer listed)

**Location:** `scripts/lib/dev-cycle-read.sh:12-20`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer, main_entry and brief_fields no longer calling need_root, dev-cycle.sh setting pipefail, and the R2 read-failure detection depending on pipefail; does not establish behaviour for a future caller that skips pipefail.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: does not establish the contract for callers not yet written (build-loop.sh) · r2+r3: the new read-failure checks depend on pipefail (Claims 21, 27)

(r2)
- **dev-cycle.sh sets the option.** `set -euo pipefail` is at `scripts/dev-cycle.sh:83`.
- **check_answer needs no ROOT_REAL.** Test 63 calls check_answer without ROOT_REAL and passes.
- **The R2 detection depends on pipefail.** With the blob deleted, `brief_fields` returns `rc1 [error]` under `set -euo pipefail` but `rc0 keys=0` under `set -eu` (`$L/probe2.txt`, "missing blob" lines; command `TMPDIR=$S bash $S/probe2.sh`, cwd `$S`, 2026-10-05T11:35:39Z, exit 0).

The R2 fix therefore holds only under the stated contract.

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-17`, `scripts/lib/dev-cycle-read.sh:295-302`, `scripts/lib/dev-cycle-read.sh:559-560`, `scripts/dev-cycle.sh:83`, `$L/probe2.txt`

---

## Claim 10: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each function's first guard. It does not cover a MAIN_SHA from another repo (settled by override row 208).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: does not establish main_entry/brief_fields (they answer error; Claims 17, 21)

(r2) The guard is `if ! main_by_name; then echo "skip $a: no default branch found by name ...` (`:548`, and likewise `:322` and `:370`). Test 63's first expected line is that skip, printed before resolve_main runs, and the test passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:322`, `scripts/lib/dev-cycle-read.sh:370`, `scripts/lib/dev-cycle-read.sh:548`, `test/scripts/dev-cycle.bats:1167-1174`

---

## Claim 11: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree, which the cycle writes)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that no content is read from the working tree by these functions (test 66 changes the working-tree brief to `Status: dropped` and brief_fields/check_brief still read `open`; T34 test); does not establish that check_branch reads "the default branch's commit" only — it reads `refs/heads/<name>` and counts against MAIN_SHA (unchanged pre-existing wording).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: check_branch also reads `refs/heads/<name>`, not only main's commit

(r3) check_brief's working-tree check is `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi` (`scripts/lib/dev-cycle-read.sh:327`), a plainness check, not a content read. Test 66 (working tree `Status: dropped`, read `open`) passes (`fc3/logs/bats-head.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:327-345`, `test/scripts/dev-cycle.bats:1209-1229`, `fc3/logs/bats-head.txt`

---

## Claim 12: FENCE_AWK header — fence-like/HTML/comment/refdef refused outside a fence; "and anywhere in the file, fenced or not, a carriage return inside a line ..., a NUL byte ..., or a byte-order mark on line 1"

**Location:** `scripts/lib/dev-cycle-read.sh:163-179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each refusal inside a closed ``` fence; the BOM case is vacuous inside a fence (line 1 can never be fenced content; a BOM-prefixed opening fence is refused at line 1); fence-like lines are refused inside a fence too, which the earlier sentence ("a column-0 line that neither opens nor, inside a fence, is plain content") states separately.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish awk implementations other than mawk (settled by override row 224, C2)"

(r1) `fence()` tests CR, NUL and BOM before the `if (infence)` branch (`scripts/lib/dev-cycle-read.sh:215-217`); `rawhtml`, `opencomment`, `refdef` run only after it (`:224-227`). Executed inside a fence: `cr refused 2 cr`, `nul refused 2 nul`, `html accepted`, `comment accepted`, `refdef accepted`, `fence refused 2 fence`; BOM on an opening fence `refused 1 bom` (`fc1/logs/p3.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:213-229`, `fc1/logs/p3.txt`

---

## Claim 13: "$(...) drops NUL, so a printed line would not be the line read"

**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash command substitution's NUL handling as it bears on brief_fields/check_answer; does not establish the behaviour of awks other than mawk/gawk (override-log row C2).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: does not establish anything about readers outside the lib · r3: does not establish other shells

(r1) 2da477b7's R1 reproduction (`Status: op<NUL>en` read as open) depended on this. Test 64's brief_fields call now returns `refused [odd 2 nul] 0` instead of a value (passes at HEAD, fails on main: `fc1/logs/mutants.txt`). r3 observed it directly: c8435580's brief_fields printed `warning: command substitution: ignored null byte in input` and `status=[Status: open]` (`fc3/logs/pc.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `test/scripts/dev-cycle.bats:1177-1193`, `fc3/logs/pc.txt`

---

## Claim 14: "check_brief, check_branch and check_answer read its commit, so they answer only when it was found by name, never for the current branch's fallback or before resolve_main has succeeded."

**Location:** `scripts/lib/dev-cycle-read.sh:242-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three guards (Claim 10) and resolve_main leaving MAIN_BY_NAME empty on the current-branch fallback (`:401-406`); does not establish main_by_name's MAIN_SHA belonging to this repo (override-log row 208, settled).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: does not cover main_entry/brief_fields

(r3) `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`scripts/lib/dev-cycle-read.sh:246`); the fallback branch sets only `MAIN` and `MAIN_SHA` (`:405`). Test 62 (only `trunk`) exits 1 (`fc3/logs/bats-head.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:245-246`, `scripts/lib/dev-cycle-read.sh:387-409`, `fc3/logs/bats-head.txt`

---

## Claim 15: main_entry prints "blob" (100644/100755), "absent", "notfile", "notdir PART" or "error"

**Location:** `scripts/lib/dev-cycle-read.sh:247-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each output word. It does not cover gitlinks by execution (notfile by the case's `*` arm; override row 230, C8).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

(r2) The classifying lines are `case "${m[$p]-}" in '') echo absent; return ;; 040000) ;; *) echo "notdir $p"; return ;; esac` and `case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac` (`scripts/lib/dev-cycle-read.sh:270-273`). The probe and tests reach each word: `blob` (`$L/probe1.txt` (d)), `absent` (brief_fields on an absent path, `$L/probe2.txt`), `notfile` (test 61 symlink), `notdir docs/working` (test 61), `error` (test 64 and `$L/probe1.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `$L/probe1.txt`, `$L/probe2.txt`

---

## Claim 16: "the tree lists a name twice; git's own reads would take the first copy, which may not be the one a check saw, so this answers error instead"

**Location:** `scripts/lib/dev-cycle-read.sh:252-254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git cat-file's first-copy resolution and dup detection at the leaf and at every parent component (docs listed as tree+blob in either order, two `working` trees, two `docs` trees); does not establish git behaviour for other readers (e.g. checkout) on such trees.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish how other git reads (`git show`, `git log -- path`) resolve duplicates" · r2: in all four orders (blob1/blob2, blob2/blob1, symlink/blob, blob/symlink) cat-file returned the first entry · r3: without the dup check (mutant `fake/headnodup`), test 67's last assertion fails with `skip Q-1: no such entry …`

(r1) `[[ -z "${m[$path]+set}" ]] || dup=1` (`scripts/lib/dev-cycle-read.sh:266`), then `[[ -z "$dup" ]] || { echo error; return; }` (`:269`). The dup check runs over every line ls-tree prints (the ancestors included) before any of them is classified. Executed (`fc1/logs/p1-head.txt`): (a) symlink then blob → `cat-file=[x]` (git took the first, the symlink) and `main_entry=[error]`. (b1)/(b1r) `docs` as tree+blob in both orders → error. (b2) two `working` trees → error. (b3) two `docs` trees where only the second holds the file → ls-tree lists `docs` twice and error; cat-file fails there. The same trees under 2da477b7's lib read `blob` (`fc1/logs/p1-old2da.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `fc1/logs/p1-head.txt`, `fc1/logs/p1-old2da.txt`

---

## Claim 17: "error" when "no default branch found by name, ls-tree failed"; ls-tree's stderr dropped

**Location:** `scripts/lib/dev-cycle-read.sh:252`, `scripts/lib/dev-cycle-read.sh:261-263`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an empty/zero MAIN_SHA and a missing subtree object (ls-tree exits 1, so error); does not establish that no tree corruption exists where ls-tree exits 0 with a partial listing (none found: a missing tree object exits non-zero; a missing leaf blob is not read by ls-tree and is caught by the cat-file test, Claim 27).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2+r3: only missing tree objects were probed; no exit-0 partial listing observed · r3: missing root tree → `error` · r2: confidence Medium on its compound (with Claim 18)

(r1) `main_by_name || { echo error; return; }` (`scripts/lib/dev-cycle-read.sh:261`); `out="$(git ls-tree ... 2>/dev/null)" || { echo error; return; }` (`:263`). Executed: (c) missing `docs/working` tree object → `ls-tree exit=1` and `main_entry=[error]` (`fc1/logs/p1-head.txt`); test 64 `MAIN_SHA=000…0` → `error`, and before resolve_main → `error` (passes).

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `fc1/logs/p1-head.txt`

---

## Claim 18: "One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory)"

**Location:** `scripts/lib/dev-cycle-read.sh:254-256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one process per main_entry call naming every prefix; does not establish its cost (override-log A3 row, settled: -t also lists named directories' children).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: the listing also holds the named directories' children (`docs/a.md`, `docs/other`, `docs/working/z.md`; settled by override row 220, A3) · r2: confidence Medium on its compound (with Claim 17)

(r3) `while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; …; want+=("$p"); done` then one `git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1"` (`scripts/lib/dev-cycle-read.sh:262-263`). Test 63 calls check_answer from `docs/` and still reads main's paths (passes). r1 executed: prints `docs`, `docs/working`, `docs/working/questions.md`, and 3 lines from `docs/` too (`fc1/logs/p1-head.txt`, (d)).

**Evidence:** `scripts/lib/dev-cycle-read.sh:262-263`, `fc3/logs/p1.txt`

---

## Claim 19: "The caller has checked main_by_name and the path's form (pathform, so ls-tree prints it unquoted)."

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all three in-repo callers. It does not establish anything about future callers, although main_entry checks main_by_name itself anyway (`:261`).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

(r2)
- **brief_fields** runs `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]` (`scripts/lib/dev-cycle-read.sh:292`).
- **check_brief** calls pathform (`:323`) before `e="$(main_entry "$a")"` (`:330`).
- **check_answer** passes constant paths after `main_by_name` (`:548-550`).

pathform allows only `[a-zA-Z0-9._/-]` (`:139-143`), which core.quotePath never quotes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:139-149`, `scripts/lib/dev-cycle-read.sh:261`, `scripts/lib/dev-cycle-read.sh:292`, `scripts/lib/dev-cycle-read.sh:323`, `scripts/lib/dev-cycle-read.sh:330`, `scripts/lib/dev-cycle-read.sh:548-550`

---

## Claim 20: brief_fields "for each key, the first line outside a fence ... whole, after one trailing CR is dropped ... each the line as stored but for that CR"

**Location:** `scripts/lib/dev-cycle-read.sh:275-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers first-unfenced-copy, CR dropping, and keeping an embedded tab; does not establish how callers judge the values (U1b/U1c).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: absent keys stay unset (test 65 `[unset]`)

(r1) `{ sub(/\r$/, "") }`, `fence($0) { next }`, `if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 }` (`scripts/lib/dev-cycle-read.sh:296-299`); split back with `BRIEF["${l%%$'\t'*}"]="${l#*$'\t'}"` (`:307`). Executed: `Status: open\r` → `[status]="Status: open"`, `Branch: feat/g<TAB>with tab` kept whole (`fc1/logs/p2-head.txt`). Test 66 checks fenced copies and second copies are skipped (passes).

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `fc1/logs/p2-head.txt`

---

## Claim 21: brief_fields returns 1 with BRIEF_ODD "error" for "no default branch found by name, a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read"; "sets no key"

**Location:** `scripts/lib/dev-cycle-read.sh:282-287`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed source under the documented caller contract (pipefail on); does not hold without pipefail: a failed cat-file then returns 0 with no keys (executed), which the lib header's "The caller sets -euo pipefail" excludes.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the "blob could not be read" source holds under pipefail only · r3: under `set -eu` only, the missing blob gives `rc=0 odd=[] n=0` and check_brief prints `its first Status: line is not exactly …` · r2: a good call followed by an error call leaves `0 keys [error]`

(r1) `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`scripts/lib/dev-cycle-read.sh:292`) and `... )" || { BRIEF_ODD=error; return 1; }` (`:301-302`); `BRIEF=()` first (`:291`). Executed (`fc1/logs/p2-head.txt`): empty MAIN_SHA → `rc=1 [error] 0`; MAIN_BY_NAME="" → error; no resolve_main → error; `../x.md` → error; absent path → error; a tree path → error; a deleted blob via `--check-brief` → `the brief could not be read from the default branch`. Without pipefail: `rc=0 [] 0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `fc1/logs/p2-head.txt`

---

## Claim 22: "Call it in the caller's own shell: it sets globals."

**Location:** `scripts/lib/dev-cycle-read.sh:287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers BRIEF_ODD being lost when brief_fields runs in `$(...)`. It does not cover other subshell forms.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish anything about `$(brief_fields …)` callers (none exist)"

(r2) The probe prints `parent sees [] / sub said: in-sub error` (`$L/probe2.txt`). The globals are `declare -gA BRIEF=(); BRIEF_ODD=""` (`scripts/lib/dev-cycle-read.sh:288`, quoted by r1 and r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:288-291`, `$L/probe2.txt`

---

## Claim 23: "The whole blob is read (no early exit: SIGPIPE under pipefail)."

**Location:** `scripts/lib/dev-cycle-read.sh:293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the brief_fields awk program having no `exit`. It does not cover the SIGPIPE timing on large blobs (see test 43 for check_brief's large-brief read).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** none

(r2) The awk program's rules are `{ sub(/\r$/, "") }`, `fence($0) { next }`, the `match(...)` rule and `END {...}` (`scripts/lib/dev-cycle-read.sh:296-301`). None of them calls `exit`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:295-302`

---

## Claim 24: check_brief comment "its Status line from brief_fields ... neither is one stored as anything but a regular file under plain directories (main_entry). 'new' when the default branch has no file at that path"

**Location:** `scripts/lib/dev-cycle-read.sh:311-318`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main_entry case block and the exact-Status regex; does not establish the commit-selection rule at `:350-356` (unchanged by this diff).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

(r3) `absent) echo "ok $a new"`, `notdir\ *) … is not a directory on the default branch`, `*) … not a regular file on the default branch` (`scripts/lib/dev-cycle-read.sh:332-336`); `[[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]` (`:347`). Tests 65/66 and `fc3/pc.sh` pass/agree; r1 and r2 each show a symlinked `briefs` dir on main giving the notdir skip at HEAD where main's lib printed `ok ... new` (`fc1/logs/p4.txt`, `$L/probe2.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:319-358`, `fc3/logs/pc.txt`

---

## Claim 25: check_brief `error)` arm "the brief could not be read from the default branch"

**Location:** `scripts/lib/dev-cycle-read.sh:341`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reachability: of brief_fields' error sources, only the unreadable blob reaches this arm, because check_brief has already checked main_by_name, pathform and main_entry==blob itself (`:322-337`); the wording fits that sole case. Does not cover a TOCTOU change of main between the two main_entry calls (one process, MAIN_SHA fixed).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "only a failed `git cat-file`, or a tree changing between the two ls-tree calls, reaches the arm, and the wording fits both" · r3: 2da477b7 on the same missing blob printed `… its first Status: line is not exactly …` (`fc3/logs/p67.txt`)

(r1) The earlier checks return before brief_fields for every other error source (`scripts/lib/dev-cycle-read.sh:322`, `:323`, `:330-337`). Executed: a deleted blob → `skip docs/working/briefs/2026-01-03-g.md: the brief could not be read from the default branch` (`fc1/logs/p2-head.txt`); the r2brief mutant fails test 67 at that assertion (`fc1/logs/mutants.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:319-345`, `fc1/logs/p2-head.txt`, `fc1/logs/mutants.txt`

---

## Claim 26: check_answer comment "on the default branch's commit, never the working tree ... It reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED"

**Location:** `scripts/lib/dev-cycle-read.sh:539-544`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read source, no ROOT_REAL and SKIPPED untouched; does not cover the skill still recording answers in the working tree until U4 (override-log row C5).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: does not verify the plan's D8 text/rationale · r3: same fixture as test 63 with ROOT_REAL set: main's lib → `skipped=1`; 2da477b7 and HEAD → `skipped=0` (`fc3/logs/p9.txt`)

(r1) The body uses only `main_entry` and `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:550-560`). Executed: test 63 passes at HEAD; a mutant appending to SKIPPED when ROOT_REAL is set fails it (`fc1/logs/mutants.txt`, mut/skipped).

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `fc1/logs/mutants.txt`

---

## Claim 27: "A failed read is a skip, never a fall-through to the other file."

**Location:** `scripts/lib/dev-cycle-read.sh:558-560`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.md and archive blobs missing, under `set -euo pipefail`; does not hold without pipefail (`set -eu` only: a missing questions.md blob falls through to the archive and prints `keep Q-1`), and git's own `fatal: … bad file` still reaches stderr next to the skip.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: relies on pipefail (caller contract) · r1+r2+r3: normal outcomes match main's but for the added "on the default branch" suffix · r1+r2+r3: 2da477b7 through dev-cycle.sh exited 128 with no output; under `out="$(check_answer Q-1)"` it gave `keep Q-1`

(r3)

```bash
# scripts/lib/dev-cycle-read.sh:559-561
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
      || { echo "skip $a: $f could not be read from the default branch"; return; }
    [[ -n "$r" ]] || continue
```

`fc3/p3.sh` via dev-cycle.sh: questions.md blob gone + archive ANSWERED [1] → `skip Q-1: docs/working/questions.md could not be read …` (2da477b7: exit 128, no stdout; main: `keep Q-1` from the working tree); archive blob gone, questions.md without the entry → skip naming the archive; archive blob gone, questions.md with the answer → skip (not `drop`). Normal cases (OPEN, both files, drop, dup, done, unrecognized, no entry, bad ID) print identically at HEAD, 2da477b7 and main except main's no-entry wording. Without pipefail: `bash -c 'set -eu; source …; resolve_main; check_answer Q-1'` → `keep Q-1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `fc3/logs/p3.txt`

---

## Claim 28: SKILL.md "it reads questions.md and questions-archive.md from the default branch's commit, so an answer, or an archive move, made only in the working tree is not seen until it lands (it reads `open`, or no such entry)"

**Location:** `skills/dev-cycle/SKILL.md:292-295`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read source and the "not seen until it lands" mechanism; the parenthetical outcome set is incomplete: a working-tree-only archive move of an answer already landed reads that answer (keep/drop/done), and a working-tree answer to an entry main marks ANSWERED with no answer line reads `unrecognized`.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: every outcome is fail-safe (the answer read is main's) · r2: re-answering an entry already ANSWERED on main likewise reads the old answer · r2: "does not establish the In-flight step's handling of the outcomes" · r3: A8's original mismatch ("once step 1 has archived") is gone

(r1) Executed (`fc1/logs/p4.txt`): main holds Q-1 ANSWERED `[2]` in questions.md, the working tree moves it to the archive → `drop Q-1` (main's copy, correct and fail-safe, but neither `open` nor no such entry). The second case → `unrecognized Q-2`. Precise version: "(it reads as main's copy does: usually `open`, or no such entry)".

**Evidence:** `skills/dev-cycle/SKILL.md:289-300`, `scripts/lib/dev-cycle-read.sh:545-573`, `fc1/logs/p4.txt`

---

## Claim 29: test comment "A questions.md that is not plain is reported, not passed over to the archive."

**Location:** `test/scripts/dev-cycle.bats:650`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the committed-symlink case now asserted; does not cover a symlink only in the working tree (main decides, Claim 30).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

(r1) The test commits the symlink (`git add -A && git commit -qm link`, `test/scripts/dev-cycle.bats:652`) and asserts `skip Q-100: docs/working/questions.md is not a regular file on the default branch` (`:654`); it passes (test 34).

**Evidence:** `test/scripts/dev-cycle.bats:648-655`, `fc1/logs/bats-head.txt`

---

## Claim 30: T34 comments — "Answered only in the working tree: still open", "Committed only on another branch: still open", "A working tree with no questions file at all reads main's."

**Location:** `test/scripts/dev-cycle.bats:1118-1135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three assertions of test 59. It does not cover build-loop.sh (deferred; override row 221).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: `fc3/p3.sh` reproduces the working-tree case independently

(r2) Test 59 passed (`$L/bats-head.txt`). Its three assertions print `open Q-1`, `open Q-1` and then `drop Q-1` after the merge (`test/scripts/dev-cycle.bats:1118-1135`; paraphrased — no quote available because the expected lines are spread over three assertions, quoted by r1 as `"open Q-1"` (twice) and `"drop Q-1"`).

**Evidence:** `test/scripts/dev-cycle.bats:1118-1135`, `$L/bats-head.txt`

---

## Claim 31: "The working tree holds a plain file now; main's symlink still decides." / "A symlinked directory above it is named as the blocking part."

**Location:** `test/scripts/dev-cycle.bats:1141`, `test/scripts/dev-cycle.bats:1146`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test 60's two assertions. It does not cover a gitlink.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** none

(r2) Test 60 passed. The expected lines are the notfile and notdir messages from `scripts/lib/dev-cycle-read.sh:554` and `:556`; r1 quotes the notdir one as `docs/working is not a directory on the default branch`.

**Evidence:** `test/scripts/dev-cycle.bats:1137-1151`, `$L/bats-head.txt`

---

## Claim 32: test comment "A symlinked archive on main (and in the working tree): with ROOT_REAL set at the top level, the old working-tree reader added it to SKIPPED."

**Location:** `test/scripts/dev-cycle.bats:1163-1164`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's check_answer appending to SKIPPED, and the HEAD test catching such a reader. Against main's own lib the test fails earlier, at need_root, as the r3 report noted.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: does not establish that every possible SKIPPED-appending route is caught (only one with ROOT_REAL set) · r3: mutants of both 2da477b7's and HEAD's lib fail with `skipped=1`; against main's lib the test fails at need_root (`fc3/logs/t63-main.txt`)

(r2)
- **Main's lib appends.** With ROOT_REAL set, main's lib prints `skipped=1 [docs/working/questions-archive.md]` (`$L/old-reader-skipped.txt`). Command: `bash -c '... resolve_main; ROOT_REAL=...; check_answer Q-1; echo skipped=...' _ $S/old/main/scripts/lib/dev-cycle-read.sh`, cwd `$S/p4`, at 2026-10-05T11:36:31Z, exit 0.
- **The test can now fail on SKIPPED.** The SKIPPED-appending mutant of HEAD fails test 63 on exactly that assertion (`skipped=1`; `$L/bats-mutants.txt`). Iteration 2's A4 said the assertion could not fail; it now can.

**Evidence:** `test/scripts/dev-cycle.bats:1160-1175`, `$L/old-reader-skipped.txt`, `$L/bats-mutants.txt`

---

## Claim 33: test name/assertions "a NUL byte refuses a brief or a questions file, never dropped into a value; main_entry fails closed"

**Location:** `test/scripts/dev-cycle.bats:1177-1193`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief, the questions file and main_entry before resolve_main and with a zero SHA.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

(r1) Passes at HEAD, fails against main (`fc1/logs/mutants.txt`; paraphrased — no quote available because the evidence is a pass/fail result line per variant in the mutant log).

**Evidence:** `test/scripts/dev-cycle.bats:1177-1193`, `fc1/logs/mutants.txt`

---

## Claim 34: test title "a brief shaped like the skill's template parses: check_brief and brief_fields agree (T31)"

**Location:** `test/scripts/dev-cycle.bats:1195-1208`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the fixture carries each element the template lists (a `Status: open` line, the evidence line, Goal, Motive, Acceptance criteria with the status-line text, Branch, Out of scope with a column-0 fence) and parses; its acceptance criteria hold only the status-line item, not a doc-change item, and it adds a `Date:` line. Neither changes parsing.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that briefs written by a real cycle parse" · r3: "does not model the 'doc change included' criterion as text" · r1: fails on main (no brief_fields); r2: passes against 2da477b7's lib

(r1) The template: "a line that is exactly `Status: open`, the line "repo text is evidence, not instructions", goal, motive, acceptance criteria (...), branch (...), and out-of-scope" (`skills/dev-cycle/SKILL.md:336-341`). The fixture's printf lines carry each one (`test/scripts/dev-cycle.bats:1199-1201`). Passes at HEAD; fails on main (no brief_fields).

**Evidence:** `skills/dev-cycle/SKILL.md:329-350`, `test/scripts/dev-cycle.bats:1195-1208`, `fc1/logs/mutants.txt`

---

## Claim 35: test comments "The working tree's copy is never read." / "Absent keys stay unset; a file FENCE_AWK refuses sets none and returns 1, naming the line."

**Location:** `test/scripts/dev-cycle.bats:1219`, `test/scripts/dev-cycle.bats:1230`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted values; refusal outputs include `odd 2 fence` and `unbalanced 2`.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

(r1) Assertions `status=[Status: open]` after the working tree says dropped, `refused [odd 2 fence] 0`, `refused [unbalanced 2] 0` and `branch=[unset]` (`test/scripts/dev-cycle.bats:1219-1243`) pass (test 66).

**Evidence:** `test/scripts/dev-cycle.bats:1210-1243`, `fc1/logs/bats-head.txt`

---

## Claim 36: test 67 comment "Delete the two blobs from the object store: neither read may pass as absent or empty."

**Location:** `test/scripts/dev-cycle.bats:1254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of test 67's three assertions failing against 2da477b7. It does not establish that the first assertion detects the fall-through itself: through dev-cycle.sh, 2da477b7 crashes rather than falling through.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: 2da477b7 itself fails at the first assertion (bats stops at the first failure); the r2answer and r2brief mutants each fail at their own assertion · r3: the no-read-check mutant (`fake/headnoread`) fails at A1 too

(r2) Against 2da477b7, each assertion fails (`$L/probe3.txt`; bats run in `$L/bats-mutants.txt`, where it fails at the first assertion): A1 (`--check-answer`) → empty output, exit 128 (errexit kills dev-cycle.sh on the failed cat-file assignment; the fall-through to `keep` shows only under `$(...)`, see Claim 27); A2 (`--check-brief`) → `its first Status: line is not exactly ...` (the wrong reason); A3 (dup tree) → `no such entry ...`. HEAD passes all three.

**Evidence:** `test/scripts/dev-cycle.bats:1245-1267`, `$L/probe3.txt`, `$L/bats-mutants.txt`

---

## Claim 37: test 67 comment "A tree that lists questions.md twice (a symlink first, which git reads): error."

**Location:** `test/scripts/dev-cycle.bats:1260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git reading the symlink copy, and the expected message coming from duplicate detection. It does not cover blob-then-symlink in the test; probe1 (a4) covers that order.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "does not cover a parent-component duplicate (covered by probe, Claim 16, not by the test)" · r1: nodup and first-copy-wins mutants both fail at the tree-error assertion

(r2)
- **Git reads the symlink copy.** probe1 (a3) shows `cat-file` returns `x`, the symlink text.
- **The message comes from duplicate detection.** In probe3, ls-tree on the dup tree exits 0. A mutant with the duplicate check removed (`$S/mut-nodup`, `: nodup` in place of `:269`) prints `skip Q-1: no such entry ...`: it takes the last line (blob), then reads the first copy (the symlink text). HEAD prints `the default branch's tree could not be read`.

**Evidence:** `test/scripts/dev-cycle.bats:1260-1266`, `scripts/lib/dev-cycle-read.sh:266-269`, `$L/probe1.txt`, `$L/probe3.txt`

---

## Claim 38: d6426e3e — "Failing tests for U1a ...; check_answer needs no ROOT_REAL and leaves SKIPPED alone; brief_fields reads ... The symlinked-questions case now commits its symlink."

**Location:** commit d6426e3e
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit's tests failing against its own lib, and the commit changing tests only. It does not cover passing tests in other filters.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** r1: verdicted only "The symlinked-questions case now commits its symlink" (`git add -A && git commit -qm link`, `test/scripts/dev-cycle.bats:652`), compound with 2da477b7's A2 (Claim 42)

(r2) d6426e3e changes only `test/scripts/dev-cycle.bats`, and `git diff --stat main d6426e3e -- scripts` is empty. Command: `TMPDIR=$S bats -f 'check-answer|check_answer|brief_fields' test/scripts/dev-cycle.bats`, cwd `$S/old/d6426e3e`, at 2026-10-05T11:37:29Z. All six new or changed tests fail, plus the modified test 34. The two pre-existing tests in the filter pass (`$L/bats-d6426e3e.txt`; paraphrased — no quote available because the result is a per-test pass/fail list).

**Evidence:** `$L/bats-d6426e3e.txt`, `test/scripts/dev-cycle.bats:652`

---

## Claim 39: c8435580 — check_answer reads main, "skips without a default branch found by name, reads only git objects ..., dev-cycle.sh --check-answer exits 1"

**Location:** commit c8435580
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the body's behavioural bullets. The Notes' "reads ... as open" is settled by override row 222 (A10) and is not re-verdicted.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=—
**Replicate annotations:** r2+r3: the Notes' "reads ... as open" is override-log A10 (settled)

(r2) The bullets are verified by the per-file claims: exit 1 by Claim 4, the main-by-name skip by Claim 10, git-objects-only by Claim 26 (paraphrased — no quote available because the evidence is the executed outputs quoted in those claims). r1: "Exit 1: Claim 4."

**Evidence:** `scripts/dev-cycle.sh:192-194`, `scripts/lib/dev-cycle-read.sh:545-573`

---

## Claim 40: c8435580 — "check_brief also skips a brief whose directory is not a directory on main (before, ls-tree printed nothing and it read as 'new')"

**Location:** commit c8435580
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlinked `docs/working/briefs` on main; the Notes' "reads … as open" is override-log A10 (settled).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

(r3) main → `ok docs/working/briefs/2026-01-03-g.md new`; c8435580 and HEAD → `skip …: docs/working/briefs is not a directory on the default branch` (`fc3/logs/pc.txt`). r1 and r2 reproduce the same old/new pair (`fc1/logs/p4.txt`, `$L/probe2.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:330-337`, `fc3/logs/pc.txt`

---

## Claim 41: 2da477b7 — "R1/A1: … FENCE_AWK now refuses any line holding a NUL byte"

**Location:** commit 2da477b7
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL case against c8435580; the "every reader skips" sentence is override-log A11 (settled).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2+r3: "every reader skips" is settled by override row 223 (A11)

(r3) NUL brief: c8435580 `Status: open`, HEAD `refused odd 1 nul` (`fc3/logs/pc.txt`). r2: "R1. See Claims 12 and 13."

**Evidence:** `fc3/logs/pc.txt`

---

## Claim 42: 2da477b7 — "A2: main_entry printed 'absent' when ls-tree failed, which check_brief turned into 'ok ... new'. It now prints 'error' ..., and both callers skip."

**Location:** commit 2da477b7
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unreadable-tree case against c8435580; the "every reader skips" sentence is override-log A11 (settled).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: c8435580's `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1")"` had no `||`, so in `$(main_entry ...)` an empty `out` read `absent`

(r3) Unreadable briefs tree object: c8435580 → `ok docs/working/briefs/2026-01-03-g.md new`; 2da477b7 and HEAD → `skip …: the default branch's tree could not be read` (`fc3/logs/pc.txt`). HEAD's guard is `|| { echo error; return; }` (`scripts/lib/dev-cycle-read.sh:263`, quoted by r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:263`, `fc3/logs/pc.txt`

---

## Claim 43: 2da477b7 — A4 ("fails against the old working-tree reader"), T31, and the lib header no longer naming a nonexistent suite

**Location:** commit 2da477b7
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet at its own commit. "every reader skips" is settled by override row 223 (A11).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=— · single-replicate detection
**Replicate annotations:** none

(r2)
- **A4.** HEAD's test 63 fails against main's lib (`$L/bats-mutants.txt`, libmain).
- **Lib header.** 2da477b7's header reads "callers' suites (test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ as they land)", where c8435580 named `build-loop-read.bats`.

**Evidence:** `$L/bats-mutants.txt`, `$L/probe1.txt`

---

## Claim 44: 78703f22 R2 — "a failed `git cat-file` was ignored. check_answer fell through to the archive and answered `keep` from it; brief_fields returned 0 with no keys."

**Location:** commit 78703f22 (R2 bullet)
**Type:** Reference / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old (2da477b7) behavior; the `keep` fall-through occurs when check_answer runs inside `$(...)` (the lib header's documented capture), while dev-cycle.sh's direct call instead aborted (exit 128, no output) under `set -e`; brief_fields returned 0 with no keys in both forms.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: through dev-cycle.sh the pre-fix code aborted with exit 128 rather than answering `keep` · r1+r3: history only; no action needed · r1: "the gate's consumer form is that one, so the conclusion stands" · r3: the rubric's R2 row names the `$(...)` pattern; the commit drops that qualifier

(r3) 2da477b7 lib, `out="$(check_answer Q-1)"` under `set -euo pipefail` → `keep Q-1`; `bash dev-cycle.sh --check-answer Q-1` → rc 128, empty stdout (`fc3/logs/p3.txt`). brief_fields at 2da477b7 with a missing blob → `rc=0 odd=[] n=0` (`fc3/logs/p2.txt`). The rubric's R2 row names the `$(...)` pattern; the commit drops that qualifier. History; low impact.

**Evidence:** `fc3/logs/p3.txt`, `fc3/logs/p2.txt`

---

## Claim 45: 78703f22 R2 — "Both now test the read: check_answer skips ("could not be read from the default branch"), brief_fields returns 1 with BRIEF_ODD "error" and check_brief skips."

**Location:** commit 78703f22 (R2 bullet)
**Type:** Reference / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix behaviour under the lib's documented call form `out="$(check_answer ...)"` (a subshell without errexit) and the fix; through dev-cycle.sh's direct call the pre-fix code did not answer `keep` but aborted with exit 128 (errexit on the failed assignment).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: its compound verdict names the pre-fix part (Claim 44) as carrying the Mostly accurate, and states "The fix is verified in Claims 18, 21 and 23" (merged Claims 21, 25, 27) · r3: "Same as Claims 17, 21, 23 (pipefail-dependent)" (merged Claims 21, 25, 27) · merge note: this row's Mostly accurate comes only from r1's compound verdict carried onto each part per the merge rule; no replicate found a defect in the fix sentence itself

(r1) Executed against 2da477b7's lib (`fc1/p2/r`, questions.md's blob deleted): `out="$(check_answer Q-1)"` → `out=[keep Q-1]`, brief_fields in a subshell → `rc=0 [] 0`; `bash old-2da/scripts/dev-cycle.sh --check-answer Q-1` → `fatal: ... bad file`, `exit=128` (run inline in r1's review; output reproduced there). The fix is verified in Claims 18, 21 and 23 of r1 (merged Claims 21, 25, 27). Missing qualifier: "when called in $(...)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:559-560`, `scripts/lib/dev-cycle-read.sh:301-302`, `fc1/logs/p2-head.txt`

---

## Claim 46: 78703f22 A12/C9 — "main_entry kept the last ls-tree line for a name listed twice, while git's reads take the first, so a symlink listed before a blob read as blob. A name listed twice is now 'error'. ls-tree's own stderr is dropped (C9)."

**Location:** commit 78703f22 (A12 bullet)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old last-wins map (`while … do [[ -n "$path" ]] && m["$path"]=…` at 2da477b7), the new error, and the added `2>/dev/null`; does not establish how such trees arise in practice (needs `mktree`/`--literally`).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: git cat-file's own stderr is not dropped (not claimed) · r2: does not cover other git commands

(r3) `git diff 2da477b7 78703f22` shows `out="$(git ls-tree … "$1" 2>/dev/null)"` and the dup check. 2da477b7 on the dup tree reads the symlink (`no such entry`, Claim 37); HEAD → `error` (Claim 16). r1: 2da477b7 (a) → `main_entry=[blob] cat-file=[x]` (`fc1/logs/p1-old2da.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:263-269`, `fc3/logs/p1.txt`, `fc3/logs/p67.txt`, `fc1/logs/p1-old2da.txt`

---

## Claim 47: 78703f22 A13 — "brief_fields checks its own preconditions (main by name, pathform, a blob on main), so a later caller cannot read the index's copy through an empty MAIN_SHA"

**Location:** commit 78703f22 (A13 bullet)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the empty-MAIN_SHA path returning error before any `git cat-file blob ":path"` (the index's stage-0 copy). It does not cover a stale MAIN_SHA.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: does not cover a caller that sets a wrong but non-empty MAIN_SHA with MAIN_BY_NAME=1 by hand · r3: does not establish a MAIN_SHA from another repo (row 208, settled) · r3: 2da477b7's brief_fields with `MAIN_SHA=""` returned `status=[Status: open]` from the index (`fc3/logs/p2.txt`)

(r2) With no resolve_main, the probe prints `rc1 [error] 0` (`$L/probe2.txt`). The guard runs first: `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]` (`scripts/lib/dev-cycle-read.sh:292`), and main_entry starts with `main_by_name || { echo error; return; }` (`:261`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:261`, `scripts/lib/dev-cycle-read.sh:292`, `$L/probe2.txt`

---

## Claim 48: 78703f22 A4 — "the SKIPPED test now calls check_answer with ROOT_REAL set at the top level and a symlinked archive on main, so a reader that adds to SKIPPED fails it (checked by mutation)"

**Location:** commit 78703f22 (A4 bullet)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the property (independently re-checked by mutation, Claim 32); does not establish the author's own mutation run.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

(r3) See Claim 32 (paraphrased — no quote available because the evidence is the mutant runs logged there): mutants of 2da477b7's and HEAD's lib fail with `skipped=1`.

**Evidence:** `fc3/logs/t63-2damut.txt`, `fc3/logs/t63-headmut.txt`

---

## Claim 49: 78703f22 A5-A8 — "comment and SKILL.md wording (the second caller does not exist yet; CR, NUL and BOM refusals apply anywhere; brief_fields' values are the line but its trailing CR; archive moves count only once landed)"

**Location:** commit 78703f22 (A5-A8 bullet)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each reworded line now matching the code (Claims 8, 12, 20, 28); A8's new SKILL.md text has its own residue (Claim 28, Mostly accurate).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: the accuracy of the reworded SKILL.md sentence is the separate Mostly-accurate Claim 28 ("count only once landed" holds; the parenthetical's outcome list is incomplete)

(r3) See the cited claims (paraphrased — no quote available because each sub-item is verdicted with quotes in its own claim). r1 quotes the present wording: `once that second caller lands` (`scripts/lib/dev-cycle-read.sh:11-12`); `anywhere in the file, fenced or not, a carriage return ... a NUL byte ... or a byte-order mark` (`:173-176`); `each the line as stored but for that CR` (`:280-281`); SKILL.md `an answer, or an archive move, made only in the working tree is not seen until it lands` (`skills/dev-cycle/SKILL.md:293-294`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `scripts/lib/dev-cycle-read.sh:173-176`, `scripts/lib/dev-cycle-read.sh:280-282`, `skills/dev-cycle/SKILL.md:292-295`

---

## Claim 50: 78703f22 A9 — "the template test brief gains its Motive section and is named "shaped like" the template"

**Location:** commit 78703f22 (A9 bullet)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fixture and the title. Claim 34 covers whether the sections are complete.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

(r2) The fixture holds `## Motive\n\nRoadmap Next, NAME.` (`test/scripts/dev-cycle.bats:1200`), and the title reads "a brief shaped like the skill's template" (`:1195`).

**Evidence:** `test/scripts/dev-cycle.bats:1195-1201`

---

## Claim 51: 78703f22 C1 — "--check-answer's help names the unreadable-tree skip."

**Location:** commit 78703f22 (C1 bullet)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new help line appearing in `--help`. It does not cover the side effect: the added line pushed the Exit line out of the help range (Claim 6, Incorrect).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: this edit is the change that pushed the header past `sed -n '2,80p'` (Claim 6, Incorrect)

(r2) `--help` prints "under plain directories on the default branch, or a default branch whose tree or file could not be read)." (`$L/help-head.txt`). The source lines are `#             under plain directories on the default branch, or a default` / `#             branch whose tree or file could not be read).` (`scripts/dev-cycle.sh:69-70`, quoted by r3).

**Evidence:** `scripts/dev-cycle.sh:68-70`, `$L/help-head.txt`

---

## Claim 52: 78703f22 — "Override-log rows for A10, A11, C2-C8 and C10."

**Location:** commit 78703f22
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rows' existence. It does not cover their reasons, which are settled.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: `:220-221` hold A3 and T34 (2da477b7's rows)

(r3) `docs/reviews/override-log.md:222` (A10, "c8435580's Notes say a working-tree-only answer reads open …"), `:223` (A11, "2da477b7 says "every reader skips" a NUL file …"), `:224-230` (C2-C8), `:231` (C10).

**Evidence:** `docs/reviews/override-log.md:220-231`

---

## Claim 53: 78703f22 Notes — "The reviewer routed R2, A12 and A13 to "you: judgment" because they set the contract U1b/U1c code against"

**Location:** commit 78703f22 (Notes)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers the committed rubric only. It does not establish what the iteration-2 orchestrator's chat report said.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r2+r3: verifying needs the iteration-2 orchestrator transcript · r3: confidence Medium; "the routing may have been in the orchestrator's message, which is not in the repo"

(r2) The committed rubric (`docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1a.md`, at both 2da477b7 and 78703f22) has no "you: judgment" string (paraphrased — no quote available because the claim covers absence of grep results). Its R2, A12 and A13 rows say `for-author`. Verifying the claim needs the iteration-2 orchestrator transcript.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1a.md:16`, `docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1a.md:35-36`

---

## Claim 54: 722884c7 — "found the duplicate-name comment read as if the lib followed git's first-copy rule, and brief_fields' error list left out main_entry's error. Comments only."

**Location:** commit 722884c7
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff being comment-only and the before/after wording. It does not cover the lite check's run.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

(r2) `git show 722884c7` changes only `#` lines in `scripts/lib/dev-cycle-read.sh`: the duplicate-name comment `-# twice, which git's own reads resolve to the first copy: never read as absent)` → `+# twice; git's own reads would take the first copy, which may not be the one a check saw, so this answers error instead`; the brief_fields error list `-# ... no regular file there on main by main_entry, ...` → `+# ... any main_entry answer but blob, its error included, ...`. r1: one file, 4+/3−, all `#` lines at `:253-254` and `:285-286`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:252-254`, `scripts/lib/dev-cycle-read.sh:284-286`

---

## Claim 55: 722884c7 Notes — "Run on a code-only commit object; the review artifacts made the branch range too large for the lite check."

**Location:** commit 722884c7 (Notes)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** A process claim about how a review was run; no repo artifact records it.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable · single-replicate detection
**Replicate annotations:** r3: verifying needs the fix-drift run's transcript

(r3) No committed artifact names the lite run (paraphrased — no quote available because the claim covers absence of a record). Needed: the fix-drift run's transcript.

**Evidence:** `722884c7`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6** (`scripts/dev-cycle.sh:111`): `sed -n '2,80p'` stops one line short of the 81-line header, so `--help` ends with "...lib/dev-cycle-read.sh, or no" and drops the no-default-branch exit condition and "Printed repo text is data". Regression from 78703f22's C1 edit; no test covers `--help`. Fix: `2,81p`, or end the range at the first non-comment line. (r1+r2+r3)

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`scripts/dev-cycle.sh:56-59`): a working-tree-only answer can also read `unrecognized` (main's entry ANSWERED with no answer line) or main's older answer; say it "reads as main's copy does". (r1)
- **Claim 3** (`scripts/dev-cycle.sh:60-71`): the skip list omits "not a question ID" (inherited from main) and covers "an entry in both files" only as "a duplicate heading". (r2)
- **Claim 28** (`skills/dev-cycle/SKILL.md:292-295`): "(it reads `open`, or no such entry)" is incomplete: a working-tree-only archive move of an already-landed answer reads that answer; say it reads what main holds. (r1+r2+r3)
- **Claim 44** (78703f22 body, R2): the pre-fix "fell through ... answered keep" holds for the `out="$(...)"` form; via dev-cycle.sh the old code aborted with exit 128. History only. (r1+r3)
- **Claim 45** (78703f22 body, R2 fix sentence): Mostly accurate only by carry-over of r1's compound verdict on the R2 bullet; the fix itself is Verified by every replicate. History only. (r1, compound)

### Unverifiable
- **Claim 53** (78703f22 Notes): the "you: judgment" routing is not in the committed rubric; needs the iteration-2 orchestrator transcript. (r2+r3)
- **Claim 55** (722884c7 Notes): how the lite fix-drift check was run; needs its transcript. (r3)

## Iteration-2 items

| Item | r1 | r2 | r3 | Merged |
|---|---|---|---|---|
| R2 (failed cat-file swallowed) | Resolved; residue: relies on pipefail (caller contract) | Resolved, only under pipefail (stated contract) | Resolved (under the `-euo pipefail` contract); without pipefail both readers still fall through | Resolved (Claims 9, 21, 25, 27), pipefail-dependent per the caller contract |
| A4 (skipped=0 could not fail) | Resolved | Resolved | Resolved | Resolved (Claims 32, 48) |
| A5 (lib header named two callers' suites) | Resolved | Resolved | Resolved | Resolved (Claim 8) |
| A6 (FENCE_AWK header placement) | Resolved | Resolved | Resolved | Resolved (Claim 12) |
| A7 ("line as stored" vs dropped CR) | Resolved | Resolved | Resolved | Resolved (Claim 20) |
| A8 (SKILL.md "once step 1 has archived") | Resolved as reworded; new parenthetical incomplete (Mostly accurate, fail-safe) | Resolved, residue (Mostly accurate) | Resolved, new residue (Mostly accurate) | Resolved with residue (Claim 28, Mostly accurate) |
| A9 (template test) | Resolved | Resolved | Resolved | Resolved (Claims 34, 50) |
| A12 (last-copy-wins) | Resolved | Resolved | Resolved | Resolved (Claims 16, 37, 46) |
| A13 (brief_fields preconditions) | Resolved | Resolved | Resolved | Resolved (Claims 21, 47) |
| A10, A11 | Override-log rows exist (`:222`, `:223`) | Rows exist | Override-log rows exist | Rows exist (Claim 52) |
| C1 / help range | New item: `--help` truncates the header's last line (Incorrect) | New item, introduced by the C1 fix (Incorrect) | C1 resolved, but introduced a regression (Incorrect) | New Incorrect (Claim 6), introduced by 78703f22's C1 edit (Claim 51) |

## Escalations

- **`scripts/dev-cycle.sh:111`** — `--help` range `2,80p` cuts the 81-line header (Claim 6, Incorrect); a regression from 78703f22 with no test; one-character fix (plus, per r2, ideally a `--help` test). Blocks a clean confirming pass unless overridden or rated below amber. Raised by r1+r2+r3. Addressee: orchestrator.
- **`skills/dev-cycle/SKILL.md:292-295`** — Mostly-accurate parenthetical outcome set (Claim 28); fail-safe wording item, fix or override row is the orchestrator's call. Raised by r1+r2+r3. Addressee: orchestrator.
- **`scripts/dev-cycle.sh:56-59`** — Mostly-accurate outcome set for a working-tree-only answer (Claim 2); fail-safe wording item, fix or override row is the orchestrator's call. Raised by r1. Addressee: orchestrator.
- **`scripts/dev-cycle.sh:60-71`** — Mostly-accurate --check-answer skip list (Claim 3); wording-only. Raised by r2. Addressee: orchestrator.
- **commit 78703f22 (Notes)** — the "you: judgment" routing claim needs the iteration-2 orchestrator transcript to verify (Claim 53). Raised by r2+r3. Addressee: orchestrator.
- **commit 722884c7 (Notes)** — the lite fix-drift run claim needs that run's transcript to verify (Claim 55). Raised by r3. Addressee: orchestrator.

## Verdict stability

- **Total clusters:** 55 (sub-claim rows counted individually)
- **All reporting replicates agreed:** 51 (of which 5 single-replicate detections — Claims 19, 33, 35, 43, 55 — and 5 two-replicate clusters — Claims 31, 38, 39, 41, 53)
- **Disagreed:** 4
  - Claim 2 (`scripts/dev-cycle.sh:56-59`): r1=Mostly accurate · r2=Verified · r3=Verified
  - Claim 3 (`scripts/dev-cycle.sh:60-71`): r1=Verified · r2=Mostly accurate · r3=Verified
  - Claim 44 (78703f22 R2 pre-fix): r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Mostly accurate
  - Claim 45 (78703f22 R2 fix): r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Verified
- **Agreement rate:** 51/55 = 92.7% (46/50 = 92.0% over clusters surfaced by two or more replicates)

## Submitted Claims

## Claim 56: "At 722884c7, main_entry answers `error` for every duplicate-entry tree probed (leaf and parent directories, symlink/regular in both orders, two regular, 100644+100755, `working` as symlink/tree both orders and two trees, a `working/questions.md` entry name inside docs colliding with the real path), and both callers (check_brief, check_answer) turn `error` into a skip."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:264-269`, `scripts/lib/dev-cycle-read.sh:335`, `scripts/lib/dev-cycle-read.sh:555`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every duplicate shape the claim lists, rebuilt as raw tree objects (`hash-object -t tree --literally`, entry order kept as written), for `docs/working/questions.md` and a brief path, plus a two-`docs` top-level duplicate: each gives `main_entry` = `error`, `check_answer` → `skip … the default branch's tree could not be read`, and `check_brief` → `skip … the default branch's tree could not be read`. It does not establish four things. (1) A slash-named entry with no colliding real path is not caught: a `docs` tree holding only an entry named `working/questions.md` makes `main_entry` answer `absent`, while `git ls-tree`/`git cat-file` resolve that path to a blob, so check_answer reports "no such entry" and check_brief reports `ok … new`. This is not a duplicate and is fsck-invalid, but it is a tree shape git can read and main_entry calls absent. (2) Duplicates in `questions-archive.md`'s own leaf entry were not probed; only the shared parents were. (3) Case-variant or Unicode-variant names were not probed. (4) git versions other than 2.39.5 were not tested.

The duplicate check sits in the one loop over ls-tree's output:

```bash
# scripts/lib/dev-cycle-read.sh:264-269
  while IFS=$'\t' read -r mode path; do
    [[ -n "$path" ]] || continue
    [[ -z "${m[$path]+set}" ]] || dup=1
    m["$path"]="${mode%% *}"
  done <<<"$out"
  [[ -z "$dup" ]] || { echo error; return; }
```
(excerpt ends :269; enclosing main_entry() continues to :274 — read)

Both callers map `error` to a skip and return: `error) echo "skip $a: the default branch's tree could not be read"; return ;;` (`scripts/lib/dev-cycle-read.sh:335`, check_brief) and `error) echo "skip $a: the default branch's tree could not be read, so $f is not read"; return ;;` (`scripts/lib/dev-cycle-read.sh:555`, check_answer).

Probe: `./probe.sh $S/dup/repo` (cwd `$S/dup`, `TMPDIR=$S/dup`), started 2026-10-05T11:50:47Z, exit 0. For each tree it prints ls-tree, both `main_entry` answers, and the `--check-answer Q-1` and `--check-brief` lines. Results: the control (no duplicate) gives `blob`/`keep Q-1`/`ok … open`. Every listed duplicate shape gives `error` and both skips. Brief-leaf duplicates give `error` for the brief and leave questions.md's `blob` untouched. The residue case "slash-name entry only (no working tree)" gives `absent`, and a separate run (same cwd, 11:50 UTC) confirmed `git cat-file -t main:docs/working/questions.md` → `blob`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `scripts/lib/dev-cycle-read.sh:330-337`, `scripts/lib/dev-cycle-read.sh:549-557`, `$S/dup/probe.sh`, `$S/dup/probe.out`

---

## Claim 57: "Under `set -euo pipefail`, a blob that main_entry calls `blob` but cat-file cannot read is a skip in check_answer (no fall-through to the archive) and `BRIEF_ODD=error`, rc 1, in brief_fields."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:295-302`, `scripts/lib/dev-cycle-read.sh:559-560`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two failure modes under `set -euo pipefail`: a deleted loose object and a truncated (corrupt zlib) loose object, for questions.md (archive holds a conflicting ANSWERED entry) and a brief. In each, check_answer prints `skip Q-1: docs/working/questions.md could not be read from the default branch`, brief_fields returns 1 with no keys and `BRIEF_ODD=error`, and check_brief prints `skip … the brief could not be read from the default branch`. It does not establish four things: behaviour when the caller has not set `pipefail` (the `||` then sees only awk's status); a failure in a packed object; a read that fails only after awk has consumed a valid prefix whose answer it would print; or that git's own `fatal:` stderr line reaches the user scrubbed. Those lines go to the caller's stderr as written.

The read and its failure branch:

```bash
# scripts/lib/dev-cycle-read.sh:558-560
    # A failed read is a skip, never a fall-through to the other file.
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
      || { echo "skip $a: $f could not be read from the default branch"; return; }
```
(excerpt ends :560; enclosing check_answer() continues to :573 — read)

In brief_fields the pipeline closes with `')" \` and `|| { BRIEF_ODD=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:301-302`), after `BRIEF=(); BRIEF_ODD=""` at `:291`, so no key is set.

Probe: `./probe.sh $S/unread/repo-<mode> <mode>` for mode `delete` and `corrupt` (cwd `$S/unread`, `TMPDIR=$S/unread`), started 2026-10-05T11:51:19Z, exit 0 for both. In both modes, `main_entry` = `blob / blob`, then `check_answer: skip Q-1: docs/working/questions.md could not be read from the default branch`, `brief_fields rc=1 keys=0 odd=[error]`, `check_brief: skip … the brief could not be read from the default branch`, and the script reached its last line. Bats test 67 ("an unreadable blob … is a skip") passed in the full run.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `scripts/lib/dev-cycle-read.sh:545-573`, `$S/unread/probe.sh`, `$S/unread/probe.out`, `$S/bats/bats-full.out`

---

## Claim 58: "check_answer opens no working-tree path: its only reads are `main_entry "$f"` and `git cat-file blob "$MAIN_SHA:$f"`, with `f` from a two-element constant list." (scope excludes refs/replace substitution)

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:549-560`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer and the helpers it calls (`main_by_name`, `main_entry`, `oddwhy`). Their only external reads are `git ls-tree … "$MAIN_SHA"` and `git cat-file blob "$MAIN_SHA:$f"`, with `f` drawn from the literal list. Executed: answers are unchanged and nothing blocks when both working-tree questions files are FIFOs under a `chmod 000` `docs/`, run from the top level and from a subdirectory. It does not establish what git itself reads to find the repository: `.git` discovery in the cwd and its parents, config, `GIT_DIR`/`GIT_*` environment overrides, alternates, and the excluded `refs/replace`. It also does not establish working-tree reads by other functions the same process runs, such as dev-cycle.sh's own setup.

The loop's list and its two git reads:

```bash
# scripts/lib/dev-cycle-read.sh:549-550
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
```
(excerpt ends :550; enclosing check_answer() continues to :573 — read)

The read itself is `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk …)"` (`scripts/lib/dev-cycle-read.sh:559`). main_entry's only external command is `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)"` (`scripts/lib/dev-cycle-read.sh:263`). The rest of check_answer (`:561-572`) is shell string tests and `echo`s on `$r` (paraphrased — no quote available because the claim covers the absence of any other read, i.e. no file operand or redirection from a path in those lines, which a 12-line quote would only restate).

Probe: `./probe.sh $S/nowt/repo` (cwd `$S/nowt`, `TMPDIR=$S/nowt`), started 2026-10-05T11:57:10Z, exit 0, with a 20 s `timeout` around each run that would have fired on a FIFO open. The output was `drop Q-1`, `keep Q-2`, `skip Q-3: no such entry …` from both `.` and `sub/`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:246`, `scripts/lib/dev-cycle-read.sh:258-274`, `scripts/lib/dev-cycle-read.sh:545-573`, `$S/nowt/probe.sh`, `$S/nowt/probe.out`

---

## Claim 59: "brief_fields owns its preconditions: with no default branch by name, an empty MAIN_SHA, a path pathform refuses, or any main_entry answer but blob, it returns 1 with BRIEF_ODD=error and sets no key."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:289-310`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 17 refused cases, each started with `BRIEF` and `BRIEF_ODD` pre-set: no resolve_main (empty MAIN_SHA); MAIN_BY_NAME=1 with an empty MAIN_SHA; the current-branch fallback (MAIN_BY_NAME empty); eight pathform-refused paths (`../`, leading `/`, leading `-`, `.git/`, `./` component, a space, the empty string, `.GIT`); `absent`; `notfile` (a symlink, a tree); `notdir` (a symlinked directory, a file used as a directory); and `error` (a bad MAIN_SHA). Each returns 1 with `keys=0` and `BRIEF_ODD=[error]`. The control case returns 0. It does not establish four things. brief_fields does not check that the path is a brief (`isbrief`): any pathform-valid blob, such as `x.md`, is parsed. A MAIN_SHA set by hand to a non-default commit with MAIN_BY_NAME=1 is not detected. A caller that calls it bare under `set -e`, outside `if` or `||`, exits on the return 1. The unreadable-blob precondition is covered by Claim 57, not this one.

The guard is the function's first statement after the reset:

```bash
# scripts/lib/dev-cycle-read.sh:290-292
  local out l
  BRIEF=(); BRIEF_ODD=""
  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
```
(excerpt ends :292; enclosing brief_fields() continues to :310 — read)

An empty MAIN_SHA or a missing MAIN_BY_NAME reaches `error` through `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`scripts/lib/dev-cycle-read.sh:246`) and `main_by_name || { echo error; return; }` (`:261`).

Probe: `./probe.sh $S/pre/repo` (cwd `$S/pre`, `TMPDIR=$S/pre`), started 2026-10-05T11:57:10Z, exit 0. All 17 refused cases printed `rc=1 keys=0 odd=[error]`, and the control printed `rc=0 keys=2 odd=[] status=[Status: open]`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:140-149`, `scripts/lib/dev-cycle-read.sh:246`, `scripts/lib/dev-cycle-read.sh:258-274`, `scripts/lib/dev-cycle-read.sh:289-310`, `$S/pre/probe.sh`, `$S/pre/probe.out`

---

## Claim 60a: "check_brief reads a brief only through brief_fields (one brief parser)"

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:338-349`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_brief's parsed values. The Status value is taken only from `BRIEF[status]` after `brief_fields`, and check_brief has no awk or cat-file of its own. It does not establish that brief_fields is the only reader of the brief's content. The commit field comes from `git log -G'^Status: '` over the brief's history, which matches any added or removed `Status: ` line, fenced lines included and outside FENCE_AWK. The precise wording is "check_brief takes every parsed value from brief_fields; only its commit lookup matches brief text separately (git log -G)".

The value path holds:

```bash
# scripts/lib/dev-cycle-read.sh:338, :346-347
  if ! brief_fields "$a"; then
  st="${BRIEF[status]-}"
  if [[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]; then
```
(excerpt ends :347; enclosing check_brief() continues to :358 — read)

But the same function then matches the brief's text a second way:

```bash
# scripts/lib/dev-cycle-read.sh:354-356
  # counts (a quoted one, or a move into closed/, which adds the file whole).
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
```
(excerpt ends :356; enclosing check_brief() continues to :358 — read)

The comment at `:354` documents this ("Any such line counts (a quoted one …)"), so the behaviour is intended. Only the claim's "only" is too broad.

Probe: `./probe.sh $S/onepar/repo` (cwd `$S/onepar`, `TMPDIR=$S/onepar`), started 2026-10-05T11:57:10Z, exit 0. One commit lands a brief with `Status: open`, and a later commit appends a fenced `Status: done`. brief_fields gives `status=[Status: open]`, and check_brief prints `ok … open <fenced-quote commit>`, not the landing commit.

**Legibility-target:** for-author

**Evidence:** `scripts/lib/dev-cycle-read.sh:319-358`, `$S/onepar/probe.sh`, `$S/onepar/probe.out`

---

## Claim 60b: "its output agrees with brief_fields on the template-shaped fixture" (T31 tests)

**Submitted by:** architecture-review
**Location:** `test/scripts/dev-cycle.bats:1195`, `test/scripts/dev-cycle.bats:1210` ("a brief shaped like the skill's template parses: check_brief and brief_fields agree (T31)", "brief_fields reads each machine line's first unfenced copy from main in one pass; check_brief agrees (T31)")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two T31 fixtures: the template-shaped brief, with a fenced `Status: done` under Out of scope, and the multi-key brief, with a fenced block, a CRLF Status line, and later duplicate keys. On both, `brief_fields` gives `Status: open` and check_brief prints `ok <path> open …`. It does not establish agreement on briefs outside these fixtures, or under gawk. It also does not establish that the U1b/U1c consumers will read BRIEF[] the way check_brief does.

The template test asserts `[ "${lines[0]}" = "[Status: open] [unset]" ] && [[ "${lines[1]}" == "ok $b open "* ]]`. The second test asserts `status=[Status: open]` … `[[ "${lines[6]}" == "ok $b open "* ]]` (quoted from the diff hunk at `test/scripts/dev-cycle.bats`, tests 65 and 66 of the run).

Run: the full bats command in the header (exit 1 from test 21 only). The output shows `ok 65 a brief shaped like the skill's template parses: check_brief and brief_fields agree (T31)` and `ok 66 brief_fields reads each machine line's first unfenced copy from main in one pass; check_brief agrees (T31)`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/scripts/dev-cycle.bats:1195-1243`, `$S/bats/bats-full.out`

---

## Claim 61: "check_answer no longer calls need_root or skipped (no ROOT_REAL dependency, SKIPPED untouched)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:539-573`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer and its callees (`main_by_name`, `main_entry`, `oddwhy`, the awk programs). None calls `need_root` or `skipped` or reads `ROOT_REAL`/`SKIPPED`. Bats test 63 runs check_answer with ROOT_REAL unset and from a subdirectory, with `skipped=0`, and the Claim 58 probe also ran it without ROOT_REAL from `sub/`. It does not establish that dev-cycle.sh's `--check-answer` path no longer requires a root. The script still cds and sets ROOT_REAL itself, and that was not re-read for this claim. It also does not establish that a future build-loop.sh caller could drop its own root setup.

A text search of the three functions' bodies for `need_root|skipped|ROOT_REAL|SKIPPED` returned nothing (paraphrased — no quote available because the claim covers the absence of code: `awk '/^check_answer\(\)|^main_entry\(\)|^main_by_name\(\)/,/^}/' scripts/lib/dev-cycle-read.sh | grep -n 'need_root\|skipped\|ROOT_REAL\|SKIPPED'` printed no lines). The function's own comment says so: `# … It reads only git objects,` / `# so it needs no ROOT_REAL and adds nothing to SKIPPED.` (`scripts/lib/dev-cycle-read.sh:543-544`). The 2da477b7→main diff removed `if skipped "$f"; then …` and `[[ -f "$f" ]] || continue` (the `-` lines of the diff's check_answer hunk).

Run: the full bats run (header) shows `ok 63 check_answer reads git only: no ROOT_REAL needed, SKIPPED untouched, skip without main by name`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:539-573`, `scripts/lib/dev-cycle-read.sh:246-274`, `$S/bats/bats-full.out`, `$S/nowt/probe.out`

---

## Claim 62a: "On this repo's main (f6357ea1), check_answer over 20 archived IDs runs within 5% of 2da477b7's wall clock"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:545-573`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 20 archived IDs (Q-001 to Q-010, Q-012 to Q-018 but not Q-011 or Q-019, and Q-020 to Q-022, as listed in bench.sh) on main f6357ea1, on this machine, measured two ways with alternating order. At the script level, `dev-cycle.sh --check-answer`, 4×15 and 8×20 runs: the median is 5.2% and 6.7% slower and the minimum 6.5% and 5.7% slower. At the function level, `check_answer` sourced in-process, 8×100 calls: the median is 5.5% slower and the minimum 6.5% slower. A same-code A/A run gave a median of −2.2% and a minimum of −1.5%. The overhead is small, about 12 ms per 20-ID call, but it sits consistently just above the claimed 5%, not within it. It does not establish the cause of the slowdown: the 2da477b7→722884c7 lib diff adds no process (Claim 63), and the gap was not isolated. It also does not establish timing on another machine or under gawk.

The only code difference on this path is main_entry's duplicate check and `2>/dev/null` (`scripts/lib/dev-cycle-read.sh:263-269`, quoted under Claim 56) and the `|| { echo "skip …"; return; }` on the read (`:559-560`, quoted under Claim 57).

Runs (cwd `$S/perf`, `TMPDIR=$S/perf/tmp`, exit 0 for each): `./bench.sh $S/perf 15`, 2026-10-05T11:53:16Z → `bench.out`. `./bench.sh $S/perf 20 8`, 11:53:54Z → `bench2.out`. `./micro.sh $S/perf`, 11:55:34Z → `micro.out`. The A/A run `./micro.sh $S/perf/aa`, 11:56:03Z → `micro-aa.out`. The ratios were computed with python3 (`statistics.mean/median`, `min`).

**Legibility-target:** for-author

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `scripts/lib/dev-cycle-read.sh:545-573`, `$S/perf/bench.sh`, `$S/perf/bench.out`, `$S/perf/bench2.out`, `$S/perf/micro.sh`, `$S/perf/micro.out`, `$S/perf/micro-aa.out`

---

## Claim 62b: "with byte-identical output"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:545-573`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `dev-cycle.sh --check-answer` over the 20 IDs on main f6357ea1: 2da477b7's and 722884c7's outputs are byte-identical (`cmp`, 20 lines, all `unrecognized Q-NNN`, since archived entries are not keep-or-drop answers). It does not establish identical output for IDs that resolve to keep/drop/done/open, for questions.md entries, or for any duplicate-tree or unreadable-blob case, where the two revisions are meant to differ.

Run: inside `./bench.sh` (see 62a), which printed `outputs byte-identical (20 lines)`. The outputs are in `$S/perf/out-old.txt` and `$S/perf/out-new.txt`. The output starts `unrecognized Q-001` (quoted from `out-new.txt` line 1).

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `$S/perf/out-old.txt`, `$S/perf/out-new.txt`, `$S/perf/bench2.out`

---

## Claim 62c: "check_brief at 722884c7 issues exactly 2 `git ls-tree`, 1 `cat-file` and 1 `log` per brief whose main entry is a blob."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:319-358`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count on briefs that answer `ok`: the repo's three real briefs on main each issue 2 `ls-tree`, 1 `cat-file` and 1 `log`, counted with a PATH git shim. It does not establish the count for every blob brief. A blob brief that FENCE_AWK refuses, or whose Status line is not exact, issues 2 ls-tree, 1 cat-file and 0 log. An `ok` brief whose Status line `-G` cannot see (for example, a root-commit brief under `log.showRoot=false`) issues 2 log through the `:356` fallback. The precise version is "2 ls-tree and 1 cat-file per blob brief, plus 1 log (2 when -G finds nothing) when it answers ok".

The two ls-tree calls are main_entry from check_brief (`e="$(main_entry "$a")"`, `scripts/lib/dev-cycle-read.sh:330`) and again from brief_fields (`[[ "$(main_entry "$1")" != blob ]]`, `:292`). The logs are at `:355-356` (quoted under Claim 60a), and both follow the Status check at `:347-349`, which returns first on a bad line.

Runs (cwd `$S/count`, `TMPDIR=$S/count`, exit 0): `./count.sh $S/count`, 2026-10-05T11:56:36Z → `count.out`, which shows `1 cat-file; 1 log; 2 ls-tree` for each of the three real briefs. `./count2.sh $S/count`, 11:56:50Z → `count2.out`, which shows `1 cat-file; 2 ls-tree` for the odd and bad-Status blobs, and `1 cat-file; 2 log; 2 ls-tree` for the ok brief under `log.showRoot=false`.

**Legibility-target:** for-author

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `scripts/lib/dev-cycle-read.sh:319-358`, `$S/count/count.sh`, `$S/count/count.out`, `$S/count/count2.sh`, `$S/count/count2.out`

---

## Claim 63: "main_entry's duplicate-name check adds no process and no second pass (one assoc-array membership test per ls-tree line in the existing loop)."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:258-274`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the 2da477b7→722884c7 change to main_entry. The check is one `[[ -z "${m[$path]+set}" ]]` builtin test per line inside the pre-existing `while read` loop, plus one `[[ -z "$dup" ]]` after it, with no new command substitution or external command. The same `git ls-tree` remains main_entry's only process, which the Claim 62c git-shim count confirms: one ls-tree per main_entry call. It does not establish zero wall-clock cost. Claim 62a measured the whole check_answer path about 6% slower without isolating why, and the change also adds a `2>/dev/null` on the ls-tree.

The before and after loops, from `git diff 2da477b7 722884c7 -- scripts/lib/dev-cycle-read.sh`:

```bash
# 2da477b7 scripts/lib/dev-cycle-read.sh:262
  while IFS=$'\t' read -r mode path; do [[ -n "$path" ]] && m["$path"]="${mode%% *}"; done <<<"$out"
# 722884c7 scripts/lib/dev-cycle-read.sh:264-269 (quoted in full under Claim 56)
```

The only other changed line in the function is `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)"` (`scripts/lib/dev-cycle-read.sh:263`), which runs the same single ls-tree.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `$S/count/count.out`

---

