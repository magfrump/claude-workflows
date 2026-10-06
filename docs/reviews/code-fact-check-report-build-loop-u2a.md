Commit: 36b79f72

# Code Fact-Check Report

**Commit:** 36b79f72
**Replication:** k=1 (loop pass, decision 031)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a, branch feat/build-loop-u2a)
**Scope:** fix range `git diff b9ffe7a8..36b79f72` (iteration 2): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `docs/reviews/override-log.md` rows 321-323, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md`, and commit 36b79f72's message. Commits cfbf34d2 and b9ffe7a8 were read as context only. Iteration 1's report (this file at 36b79f72) was read as the reference for the rubric's and override rows' statements about it.
**Checked:** 2026-10-06
**Total claims checked:** 25
**Summary:** 16 verified, 5 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Execution logs (all under `/tmp/claude-1000/-workspace/f2b09f27-e8e1-48a1-9e62-9ab10d974ed8/scratchpad/review-u2a/fc2/`; each script builds its repos in its own `mktemp -d` under that directory and removes them):
- `bats-head.log`: `timeout 900 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats`, cwd the worktree at HEAD 36b79f72, exit 0, 2026-10-06T06:23:24Z (`bats-head.ts`). **96/96 pass** (`1..96`).
- `probe.log` (script `probe.sh`, run as `timeout 120 bash probe.sh <worktree>/scripts/lib/dev-cycle-read.sh <fc2>`, cwd the worktree): exit 0, 2026-10-06T06:22:58Z. Probes P1, P2, P2b, P2c, P2d, P3, P4, P8, P8b, P9, P10. (Its P3b section failed for want of `xxd` and is superseded by `probe3b.log`.)
- `probe3b.log` (script `probe3b.sh`, same invocation): exit 0, 2026-10-06T06:23:14Z. An unsorted tree storing directory `x` before symlink `x`.
- `probe-first.log` (script `probe-first.sh <fc2>`): exit 0, 2026-10-06T06:25:48Z (`probe-first.ts`). Which copy git reads for a doubled name.
- `mutants.log` (script `mutants.sh <worktree> <fc2>`): exit 0, 2026-10-06T06:24:09Z. Three `git archive 36b79f72` extracts with the regex guard, the `listed` guard, or both deleted, each running `bats -f 'lists twice, or one holding a newline' test/scripts/build-loop-check.bats`: all three exit 1.
- Iteration 1's probes (`../fc/probe.log`, P2, P3, P4) were re-run in this pass as P2, P3 and P4 against HEAD.

No claim matches a logged pattern in `docs/reviews/hallucination-patterns.md`. The three Incorrect verdicts are one behavioral gap (a crafted newline name), not fabricated symbols, so nothing is added to the log.

---

## Claim 1: Rubric iteration-1 tally and mapping: "36 claims: 1 Incorrect, 7 Mostly accurate, 28 Verified; 0 Stale, 0 Unverifiable"; R1 = FC Claim 11a, A1 = 5, A2 = 16, A3 = 21, A4 = 22, C1 = 26; "FC Claims 28 and 29 (Mostly accurate) are commit-message claims in cfbf34d2"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:9-20`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts and claim-number mapping against iteration 1's report as committed at 36b79f72; does not establish that iteration 1's verdicts were themselves right (re-checked only where the fix range touches them, Claims 2 and 8-12).

Iteration 1's report header reads `**Total claims checked:** 36` and `**Summary:** 28 verified, 7 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable` (`git show 36b79f72:docs/reviews/code-fact-check-report-build-loop-u2a.md`, lines 9-10). Its verdict lines put Incorrect on `## Claim 11a` and Mostly accurate on Claims 5, 16, 21, 22, 26, 28 and 29 (paraphrased — no quote available because the mapping is the set of 36 `**Verdict:**` lines, read with `rg -n '^## Claim|^\*\*Verdict'`). Claims 28 and 29 locate on cfbf34d2's message: `## Claim 28: "the walk failing closed (...)" (commit cfbf34d2)` and `## Claim 29: "these fail until the U2a code commit" (commit cfbf34d2)`.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:9-20`, `docs/reviews/code-fact-check-report-build-loop-u2a.md` at 36b79f72 lines 9-10, 189-193, 511-531

---

## Claim 2: Rubric probe results: R1 "(probe P4: `we\nird/CLAUDE.md` imports `docs/d.md`, floor prints `docs/d.md: -`) ... (P2: `docs/b.md: -`)"; A1 "(P1: `floor CLAUDE.md` with ROOT_REAL unset returns its refusal)"; A2 "(P3; the walk still fails closed at the read)"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:13-15`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what iteration 1's probes printed at b9ffe7a8 and that the same shapes behave as stated; does not establish A2's "fails closed" for trees git did not sort (Claim 9b).

Iteration 1's `fc/probe.log` prints `docs/d.md: -` under P4, `docs/b.md: -` under P2, `early arm returned: an instruction file, which sessions load from the checkout` under P1, and for P3 `fatal: path 'x/CLAUDE.md' does not exist in ...` followed by `docs/c.md: the default branch's instruction files could not be walked for @ imports`. Re-run at HEAD, P3 prints the same two lines (fc2/probe.log).

**Evidence:** `../fc/probe.log` (P1-P4, 2026-10-06T06:11:43Z), fc2/probe.log (P3)

---

## Claim 3: Rubric line citations: R1 "`scripts/lib/dev-cycle-read.sh:443-445`, `:502-510`"; A1 "`lib:15-17`"; A2 "`lib:502-503`"; A3 "plan D2 and dev-cycle.sh:168 call it the user's. `lib:576`"; A4 "`lib:565`"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:13-17`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each cited line at b9ffe7a8 (the rubric's commit); does not establish the lines at HEAD, where the fix moved them.

At b9ffe7a8 the library lines match: `:443-445` is `# main_imports walks the default branch's commit instead, for floor: it starts / # at every instruction file stored there as a regular file under plain`, `:502-503` is the old `# -r lists blobs, symlinks and gitlinks, never what lies under a symlinked` comment, `:565` is `FLOOR_WHY=""  # read by build-loop.sh`, `:576` is the `docs/constraints.md` arm, and `:15-17` names `floor and the import walks exit 1 (need_root)`. One cite is a line off: `scripts/dev-cycle.sh:168` reads `# outside the cycle's own files, working/, human-author/ (the user's), reviews/` (the "user's" there is human-author/), while constraints.md is on the next line, `# and decisions/ (records), the settings file, constraints.md (the user's: plan` (`scripts/dev-cycle.sh:169`). Precise version: `dev-cycle.sh:169`.

**Evidence:** `git show b9ffe7a8:scripts/lib/dev-cycle-read.sh` lines 15-17, 443-445, 502-510, 565, 576; `scripts/dev-cycle.sh:168-169`

---

## Claim 4: Rubric: "No enforcement file is in the diff (hooks/live-verify-gate.sh regex), so mechanic 7 does not apply."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:24`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch's changed paths against the hook's `enforcement` regex; does not establish what "mechanic 7" requires.

The hook's pattern is `enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|...|egress/)'` (`hooks/live-verify-gate.sh:73`). No path in `git diff --name-only main...HEAD` matches it (paraphrased — no quote available because the claim covers absence: the `rg -f` match over the nine changed paths returned rc 1).

**Evidence:** `hooks/live-verify-gate.sh:73`

---

## Claim 5a: Override row 321: "Row 319's short header lines remain at `scripts/lib/dev-cycle-read.sh:13` and `:25` (fact-check Claim 26)"; "moved lines count twice against the 400-line cap"

**Location:** `docs/reviews/override-log.md:321`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two short lines and the cap rule's source; does not establish the row's Won't-Fix decision, which is the author's call.

At HEAD `scripts/lib/dev-cycle-read.sh:13` is `# pipefail for themselves),` and `:25` is `# with one printed line per argument that`, both short lines, as iteration 1's Claim 26 found. The cap rule is the plan's: "moved lines count twice under the 400-line cap" (`docs/working/plan-build-loop-handoff.md:192`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-26`, `docs/working/plan-build-loop-handoff.md:192`

---

## Claim 5b: Override row 321: "(the first rewrap measured 445)"

**Location:** `docs/reviews/override-log.md:321`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only whether the 445 figure has an artifact; does not establish whether a reflow would exceed the cap.

The rewrap was never committed, so its measured size has no artifact on the branch (paraphrased — no quote available because the claim covers absence: no commit or working doc on `main..HEAD` holds a reflowed header). Verifying it would need the discarded rewrap or its pr-prep 1a output.

**Evidence:** `docs/reviews/override-log.md:321`

---

## Claim 6: Override row 322: cfbf34d2's "a tree listing a name twice" "holds only for a doubled import target, not a doubled start file (fact-check Claim 28)"; "fixed by the iteration-1 fix commit (doubled start files now fail the walk)"

**Location:** `docs/reviews/override-log.md:322`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row's summary of Claim 28 and the doubled-start fix for two 100644 copies and for symlink-then-regular copies; does not establish the row's convention: `override-log.md:31` defines `Fact-check Incorrect` as the only Original verdict for an Accepted-immutable row, and this row (like row 316, its precedent) writes `Fact-check Mostly accurate`.

Iteration 1's Claim 28 says "the doubled name in test 4 is an import target ... A doubled start instruction file does not fail closed (P2; Claim 11a)". At HEAD, P2 (two 100644 `CLAUDE.md`) prints `docs/a.md: the default branch's instruction files could not be walked for @ imports` and the same for `docs/b.md`, and P2b (a 120000 `AGENTS.md` then a 100644 one) prints `docs/b.md: the default branch's instruction files could not be walked for @ imports`.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a.md` at 36b79f72 lines 511-524, fc2/probe.log (P2, P2b)

---

## Claim 7: Override row 323: cfbf34d2's "these fail until the U2a code commit": "10 tests fail there, but the rows 317/318 edits and the bl_setup change already pass (fact-check Claim 29)"

**Location:** `docs/reviews/override-log.md:323`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's fidelity to iteration 1's Claim 29 and its log; does not re-run the suites at cfbf34d2 (same convention residue as Claim 6).

Iteration 1's Claim 29 reads "At cfbf34d2, 10 tests fail ... The commit's build-loop-read.bats edits (rows 317/318) and the bl_setup change pass there", backed by `fc/bats-cfbf34d2.log` (exit 1).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a.md` at 36b79f72 lines 527-540, `../fc/bats-cfbf34d2.log`

---

## Claim 8: "inrepo, dirok, skipped, check_brief, isimported, floor and the import walks exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level" (now true of floor's every arm, commit A1)

**Location:** `scripts/lib/dev-cycle-read.sh:15-17`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's entry (all arms) and need_root's three conditions; does not re-check the other listed functions, which the fix range did not touch.

floor now starts with the check:

```bash
# scripts/lib/dev-cycle-read.sh:573-575
floor() {
  local lp low
  need_root
```

(excerpt ends :575; enclosing floor() continues to :589 — read). need_root exits on each condition: `[[ -n "${ROOT_REAL:-}" ]] || { ... exit 1; }`, `[[ "$ROOT_REAL" == "$(pwd -P)" ]] || { ... exit 1; }`, `[[ -e .git ]] || { ... exit 1; }` (`scripts/lib/dev-cycle-read.sh:93-97`). P1 at HEAD: `floor CLAUDE.md` (the instruction arm, which iteration 1 saw return) and `floor .x` (the dot arm) each print `dev-cycle-read.sh: ROOT_REAL is not set; ...` and exit 1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:15-17`, `:93-97`, `:573-589`, fc2/probe.log (P1)

---

## Claim 9a: "-r lists blobs, symlinks and gitlinks; a 100644/100755 entry is a regular file"

**Location:** `scripts/lib/dev-cycle-read.sh:502-503`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `ls-tree -r` lists and what the two modes mean; does not establish that every regular-file instruction file reaches the queue (Claims 11 and 12).

The start set takes only those modes: `if [[ "$mode" == 100644 || "$mode" == 100755 ]] && [[ "$(lower "${f##*/}")" =~ $INSTRUCTION_FILE ]]; then seen+="$f"$'\n'; queue+=("m:$f"); fi` (`scripts/lib/dev-cycle-read.sh:515`). In P2b and P3, `git ls-tree` prints `120000 blob` for symlinks and `100644 blob` for files, and no 040000 line under `-r`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:496-537`, fc2/probe.log (P2b, P3)

---

## Claim 9b: "(a crafted tree naming x as both a symlink and a directory can list x/CLAUDE.md too, whose read then fails, failing the walk)" (also commit A2: "names the symlink-and-directory tree and why it still fails closed")

**Location:** `scripts/lib/dev-cycle-read.sh:503-504`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers trees in git's sorted order (any `git mktree` output) and one hand-ordered tree; does not establish how the checkout or a session would load such a tree.

For a sorted tree the read fails: P3 prints `fatal: path 'x/CLAUDE.md' does not exist in '...'` and `docs/c.md: the default branch's instruction files could not be walked for @ imports`, through `out="$(git cat-file blob "$MAIN_SHA:$f" | import_targets "$d")" || { IMPORTED_MAIN=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:524`). The read does not always fail. In a tree written with `hash-object -t tree --literally` that stores directory `x` before symlink `x`, `git cat-file blob main:x/CLAUDE.md` succeeds (`cat-file rc=0`), the walk reads the file, and floor prints `docs/c.md: an instruction file on the default branch imports it with @ ...` and `docs/other.md: -` (probe3b.log). That outcome follows the file's imports, so nothing fails open. Precise version: "whose read then fails (failing the walk) or, in a tree git did not sort, succeeds and is walked".

**Evidence:** `scripts/lib/dev-cycle-read.sh:496-537`, fc2/probe.log (P3), fc2/probe3b.log

---

## Claim 10: "Records turn NUL- into newline-separated, so a record that does not start with a mode, a type and an object id ... fails the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:505-506`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers malformed records; does not establish that every name holding a newline yields one (Claim 11).

```bash
# scripts/lib/dev-cycle-read.sh:508-511
  out="$(git ls-tree -r -z --full-tree "$MAIN_SHA" | instruction_names | tr '\0' '\n')" || return 1
  while IFS= read -r rec; do
    [[ -n "$rec" ]] || continue
    [[ "$rec" =~ ^[01234567]{6}\ [abcdefghijklmnopqrstuvwxyz]+\ [0123456789abcdef]{40,64}$'\t' ]] || return 1
```

(excerpt ends :511; enclosing main_imports() continues to :537 — read). `return 1` leaves `IMPORTED_MAIN=error`, set at `:500`, and isimported's `main_imports || return 0` refuses every path (`:544`). P4 (`we\nird/CLAUDE.md`) now prints `docs/d.md: the default branch's instruction files could not be walked for @ imports`, and deleting this line makes the test fail at `want docs/d.md "$WALKFAIL"` (mutants.log, mutant `regex`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:496-537`, `:541-546`, fc2/probe.log (P4), fc2/mutants.log

---

## Claim 11: "(a name holding a newline splits)" — i.e. a start file whose name holds a newline fails the walk

**Location:** `scripts/lib/dev-cycle-read.sh:506`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start files on main whose directory name holds a newline; does not establish whether such a tree can reach main through a self-merge (the N rules' pathform, U2b), which decides how reachable the gap is.

A split fails the walk only when one of its halves is malformed. A directory named `x\n120000 blob <40 hex>\tdocs` holding a regular `AGENTS.md` lists as one record that `tr` splits into two well-formed ones (probe P8):

```
100644 blob d575b63111087e1882a14530b6156d213f004574^Ix$
120000 blob 0123456789abcdef0123456789abcdef01234567^Idocs/AGENTS.md$
```

Both pass the regex at `:511`. The first is not an instruction name, and the second's forged mode 120000 fails the mode test at `:515`, so neither is queued. `main_imports` returns `rc=0` with `IMPORTED_MAIN` empty, and floor prints `x\n120000 blob ...\tdocs/docs/e.md: -`, the file that start file imports, and `docs/other.md: -`. The checkout-tree walk on the same repo lists that target (`imported_names` prints `120000 blob ...^Idocs/docs/e.md$`). P8b (forged `040000 tree`) gives the same `-`. A forged 100644 half (P9) does fail, because the read of the forged path fails. So the walk still fails open on one shape of R1: a regular-file start file on main is skipped and the walk succeeds. The unchanged header claim "it starts at every instruction file stored there as a regular file under plain directories" (`:443-445`, iteration 1's Claim 11a) is still Incorrect for the same reason.

**Evidence:** `scripts/lib/dev-cycle-read.sh:443-445`, `:508-516`, fc2/probe.log (P8, P8b, P9)

---

## Claim 12: "and so does a name listed twice (git reads the first copy, whatever mode)"

**Location:** `scripts/lib/dev-cycle-read.sh:507`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers doubled names among the records that reach the loop; does not establish anything about doubled names elsewhere in the tree beyond the two probed.

The check sees only records that `instruction_names` passes, because `listed` is filled inside the loop over that filtered output: `[[ "$listed" != *$'\n'"$f"$'\n'* ]] || return 1` / `listed+="$f"$'\n'` (`scripts/lib/dev-cycle-read.sh:513-514`). A doubled name that is not an instruction file does not fail the walk: in P2d (`z.txt` listed twice) floor prints `docs/b.md: an instruction file on the default branch imports it ...` and `docs/other.md: -`. A doubled import target fails by another path (main_entry's `error`, P2c). The parenthetical holds: for a symlink then a regular `AGENTS.md`, `git cat-file blob` prints `symlink-target`, and with the order reversed it prints `regular copy` (probe-first.log). Precise version: "a start-file name listed twice".

**Evidence:** `scripts/lib/dev-cycle-read.sh:508-516`, fc2/probe.log (P2, P2b, P2c, P2d), fc2/probe-first.log

---

## Claim 13: `FLOOR_WHY=""  # read by floor's caller (U2c's --check)`

**Location:** `scripts/lib/dev-cycle-read.sh:571`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the planned reader; does not establish a current one: nothing outside the lib and its tests reads FLOOR_WHY today, and `--check` itself is planned in U2b, with U2c adding the floor to it.

The plan puts the floor in U2c: "**U2c, the S rules**: `Paths:` parsing, own files, the floor, `Self-merge never:` matching, the stricter policy" (`docs/working/plan-build-loop-handoff.md:276`), and `--check` runs "D7, the N rules, and the S rules" (`:212`). No script reads the variable now (paraphrased — no quote available because the claim covers absence: `rg -n FLOOR_WHY` outside `docs/reviews/` hits only `scripts/lib/dev-cycle-read.sh:566-584`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:571`, `docs/working/plan-build-loop-handoff.md:212`, `:275-276`

---

## Claim 14: `FLOOR_WHY="the user's constraints doc, which every loop prompt carries"` (commit A3: "docs/constraints.md refuses as the user's constraints doc")

**Location:** `scripts/lib/dev-cycle-read.sh:584`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arm's reach and its wording against plan D2; does not establish that any loop prompt carries the doc today: `--prompt` is not yet written.

`elif writable "$lp" || [[ "$lp" == docs/dev-cycle.md ]]; then FLOOR_WHY="one of the dev cycle's own files"` / `elif [[ "$lp" == docs/constraints.md ]]; then FLOOR_WHY="the user's constraints doc, which every loop prompt carries"` (`scripts/lib/dev-cycle-read.sh:583-584`). The plan says "Every loop prompt carries `docs/constraints.md` from main's commit" (`docs/working/plan-build-loop-handoff.md:44`), and build-loop.sh's header uses the same words (`scripts/build-loop.sh:33`). The table test expects `docs/constraints.md "$USER"` (`test/scripts/build-loop-check.bats:50`) and passes (bats-head.log, test 1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:583-584`, `docs/working/plan-build-loop-handoff.md:44`, `scripts/build-loop.sh:33`, `test/scripts/build-loop-check.bats:28`, `:50`, fc2/bats-head.log

---

## Claim 15a: "A start file listed twice (a symlink first, which git reads) fails the walk rather than reading one copy"

**Location:** `test/scripts/build-loop-check.bats:110-111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture at `:113-117`; does not establish other doubled shapes (Claim 12).

The fixture is `printf '120000 blob %s\tAGENTS.md\n100644 blob %s\tAGENTS.md\n' "$l" "$b" | git mktree` with `want docs/b.md "$WALKFAIL"` (`test/scripts/build-loop-check.bats:115-117`). git reads the symlink copy (probe-first.log), and the test passes at HEAD (bats-head.log, test 4).

**Evidence:** `test/scripts/build-loop-check.bats:110-117`, fc2/probe-first.log, fc2/bats-head.log

---

## Claim 15b: Test title "a name the tree lists twice, or one holding a newline, fails the walk" and comment "so does a start file whose name holds a newline"

**Location:** `test/scripts/build-loop-check.bats:98`, `:111`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the general statement; the fixture itself (`we\nird/AGENTS.md`, `:118-124`) does fail the walk and passes. Same defect as Claim 11, not a separate one.

The fixture's split leaves a malformed half (`ird/AGENTS.md`), which the regex refuses. A newline name crafted so both halves look like records does not fail the walk (Claim 11, P8: `rc=0`, the import target floors `-`). The title's "one holding a newline" is therefore true only for names whose split produces a malformed record. The title's "a name the tree lists twice" is narrower than it reads too (Claim 12).

**Evidence:** `test/scripts/build-loop-check.bats:98`, `:110-124`, fc2/probe.log (P8)

---

## Claim 16a: Commit 36b79f72 subject and R1: "the main import walk fails closed on split or doubled start files"; "a start file whose name holds a newline split ... and was dropped ... [now] Every record must ... start with a mode, a type and an object id"

**Location:** commit 36b79f72 message (subject, R1 bullet)
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "split" half of the subject; the "doubled" half is Claim 16b.

The subject's "fails closed on split ... start files" is refuted by P8: a start file whose name holds a newline, split into two well-formed records, is still dropped and the walk returns 0 (Claim 11). R1 (iteration 1's Claim 11a) is closed only for accidental splits such as `we\nird`.

**Evidence:** `git log -1 36b79f72`, `scripts/lib/dev-cycle-read.sh:508-516`, fc2/probe.log (P4, P8)

---

## Claim 16b: R1's pre-fix description ("split at the NUL-to-newline turn and was dropped, and a tree listing CLAUDE.md twice read only the first copy, so floor let their imports through") and the doubled-start half of the fix

**Location:** commit 36b79f72 message (R1 bullet)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers b9ffe7a8's behavior on the two iteration-1 shapes and HEAD's behavior on doubled start files; does not cover crafted splits (Claim 16a).

At b9ffe7a8, iteration 1's probes printed `docs/d.md: -` (P4) and `docs/a.md: an instruction file ... imports it` with `docs/b.md: -` (P2). At HEAD, P2 and P2b fail the walk for every path (Claim 6).

**Evidence:** `../fc/probe.log` (P2, P4), fc2/probe.log (P2, P2b, P4)

---

## Claim 16c: R1: "and any name listed twice (any mode) fails the walk"

**Location:** commit 36b79f72 message (R1 bullet)
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 12.

"Any name" is any instruction-file name: a doubled `z.txt` passes (P2d), a doubled import target fails through main_entry (P2c), and a doubled start file fails through the new `listed` check (P2, P2b). See Claim 12.

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-514`, fc2/probe.log (P2-P2d)

---

## Claim 16d: R1: "Tests: both shapes in build-loop-check.bats; deleting either guard fails the test."

**Location:** commit 36b79f72 message (R1 bullet)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers deleting the regex line, the `listed` check line, or both, one at a time in an extract of 36b79f72; does not establish that the test catches the crafted split of Claim 11 (it does not exercise it).

mutants.log: mutant `regex` (1 line removed) fails at `want docs/d.md "$WALKFAIL"` (line 124, `docs/d.md: -`); mutant `listed` fails at `want docs/b.md "$WALKFAIL"` (line 117, `docs/b.md: -`); mutant `both` fails at line 117. Each `bats exit 1`.

**Evidence:** fc2/mutants.log (2026-10-06T06:24:09Z), `test/scripts/build-loop-check.bats:110-124`

---

## Claim 16e: A1 "floor runs need_root first, as the header says"; A3 "docs/constraints.md refuses as the user's constraints doc"; A4 "FLOOR_WHY's comment names its future reader"

**Location:** commit 36b79f72 message (A1, A3, A4 bullets)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three bullets against the diff; see Claims 8, 13 and 14 for each one's own scope.

`need_root` is floor's first statement (`scripts/lib/dev-cycle-read.sh:575`, P1), the constraints arm is its own (`:584`), and the comment reads `# read by floor's caller (U2c's --check)` (`:571`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:571-584`, fc2/probe.log (P1)

---

## Claim 16f: A2: "the ls-tree comment names the symlink-and-directory tree and why it still fails closed"

**Location:** commit 36b79f72 message (A2 bullet)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 9b.

The comment names the tree, but "fails closed" holds only for sorted trees. In a hand-ordered tree the read succeeds and the file is walked, which is safe but is not the walk failing (Claim 9b, probe3b.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:503-504`, fc2/probe3b.log

---

## Claim 16g: "Review artifacts: iteration-1 rubric (short-circuited at fact-check), fact-check report, three override rows (C1 Won't-Fix, Claims 28-29 Accepted-immutable)"; Notes "critics deferred to iteration 2 by the once-per-loop short-circuit"

**Location:** commit 36b79f72 message (last bullet, Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the files and rows the commit adds; does not establish the override decisions themselves.

`git diff --stat b9ffe7a8..36b79f72` adds the rubric (30 lines) and the report (651 lines) and 3 lines to `docs/reviews/override-log.md`, rows 321 (`🟢 Consider | Won't-Fix`), 322 and 323 (`Accepted-immutable`). The rubric says "Loop-pass short-circuit: used at b9ffe7a8" and lists the four core critics as skipped, "routed to the next pass" (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:2`, `:24`).

**Evidence:** `docs/reviews/override-log.md:321-323`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:1-24`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (`scripts/lib/dev-cycle-read.sh:506`): a directory name holding a newline that splits into two well-formed records (e.g. `x\n120000 blob <hex>\tdocs`) passes the new regex, the start file under it is skipped, and the walk returns 0, so floor lets its import through (P8, P8b). R1 is still open for this shape; the header at `:443-445` is still Incorrect for it.
- **Claim 15b** (`test/scripts/build-loop-check.bats:98`, `:111`): "one holding a newline fails the walk" holds only for accidental splits; same defect as Claim 11.
- **Claim 16a** (commit 36b79f72 subject/R1): "fails closed on split ... start files" is refuted by P8.

### Mostly Accurate
- **Claim 3** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:16`): A3 cites `dev-cycle.sh:168`; the constraints.md text is on `:169`.
- **Claim 9b** (`scripts/lib/dev-cycle-read.sh:503-504`): in a tree git did not sort (directory before symlink) the read succeeds and the file is walked; the walk does not fail.
- **Claim 12** (`scripts/lib/dev-cycle-read.sh:507`): "a name listed twice" covers only instruction-file names; a doubled `z.txt` passes.
- **Claim 16c** (commit 36b79f72 R1): "any name listed twice (any mode)", same narrowing as Claim 12.
- **Claim 16f** (commit 36b79f72 A2): "still fails closed", same residue as Claim 9b.

### Unverifiable
- **Claim 5b** (`docs/reviews/override-log.md:321`): "the first rewrap measured 445" has no artifact; it needs the discarded rewrap's pr-prep 1a count.
