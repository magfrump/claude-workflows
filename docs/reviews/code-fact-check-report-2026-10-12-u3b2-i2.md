Commit: cca66dc2

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b2 (branch `feat/build-loop-u3b2`)
**Scope:** PARTIAL: the fix range `1d829fee..cca66dc2` (iteration 2). Files: `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md` (new), `docs/reviews/override-log.md` (rows 719, 721-726), `docs/working/plan-build-loop-handoff.md:325` (U3b2 as-built note), `scripts/build-loop.sh` (--main-log header, gate_msg, ANSWERS_AWK, log_class, main_log), `scripts/lib/dev-cycle-read.sh:2019-2020`, `test/scripts/build-loop-orchestrator.bats` test 10, and the commit message of cca66dc2. Commits 1d829fee and 250ea69a are context only.
**Checked:** 2026-10-12
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 36
**Summary:** 29 verified, 5 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries, all about measured values quoted from artifact sets that don't contain them, or about which files use a symbol). One claim here quotes a measurement (Claim 16, the timing row). I re-measured it: the figure is close but low, and nothing was fabricated. No claim matches a logged pattern. Per the brief's rule to write only my own report, I did not edit the log, and no fabrication qualifies for it anyway.

Execution provenance (all run on 2026-10-12, every process under `timeout` and finished before this report; temp dirs under `/tmp/u3b2rv-fc2-`; the worktree was never edited):

- **E1 (pre-fix and mutant runs of the --main-log tests).** Script: `scratchpad/fc2-mutants.sh`. It runs `git archive cca66dc2 scripts test` into `/tmp/u3b2rv-fc2-sEMN/base`, then makes one copy per variant: `head` (unchanged), `prefix` (`git show 1d829fee:scripts/build-loop.sh`), `m1` (the merge-tree block in log_class deleted), `m2` (ANSWERS_AWK's pre-fix counting restored), `m2b` (only `{ if (s == "+") n++; next }` changed to `{ n++; next }`), `m4` (both `echo "main $MAIN_SHA -"` removed) and `m9` (`[[ -n "$SUBJ" ]] || SUBJ=-` removed). For each variant it runs `TMPDIR=$(mktemp -d …) timeout 300 bats -f main-log test/scripts/build-loop-orchestrator.bats`, cwd `/tmp/u3b2rv-fc2-sEMN/<variant>`, between 22:55:27Z and 22:55:33Z. Exits: head 0 (tests 9 and 10 ok); prefix, m1, m2, m2b, m4 and m9 each 1, with test 9 ok and test 10 failing. Where test 10 fails: prefix and m1 at `:202` (the gate `ml`); m2, m2b and m9 at `:217-218`; m4 at `:220`. Outputs and diffs: `/tmp/u3b2rv-fc2-sEMN/logs/<variant>.out` and `.diff`.
- **E2 (fixture probe for the Status flip).** Script: `scratchpad/fc2-flip.sh`. It appends to a copy of the suite a test that replays test 10's second half and prints each commit's changed files and the Status-flip commit's patch. Command: `timeout 200 bats -f 'fc2 probe' …`, cwd `/tmp/u3b2rv-fc2-ab9z/base`, 22:56:15Z, exit 0. Output: `/tmp/u3b2rv-fc2-ab9z/flip.out`.
- **E3 (merge-tree equivalence and class probes).** Script: `scratchpad/fc2-mt.sh`, a throwaway repo under `/tmp/u3b2rv-fc2-kxNl/r` with `GIT_CONFIG_GLOBAL=/dev/null`. It runs HEAD's script and the m1 mutant, each `timeout 60 bash …/build-loop.sh --main-log SINCE`, ending 22:56:55Z, exit 2 for every --main-log run, as each window holds an other. Cases: A, criss-cross (2 merge bases); B, rename against modify; C, `merge.directoryRenames=true` in a caller global config; D, an amended chore merge; E, a second parent that is an ancestor of the first; F, a Status flip alone, an added answer, and a revert. Output: `scratchpad/fc2-mt.out`.
- **E4 (merge=union attribute).** Script: `scratchpad/fc2-union.sh`, repo `/tmp/u3b2rv-fc2-IaBH/r`, 22:59:09Z, --main-log exit 2. Output: `scratchpad/fc2-union.out`.
- **E5 (timing).** Script: `scratchpad/fc2-perf.sh`. It makes a `git clone --single-branch --branch main /workspace` into `/tmp/u3b2rv-fc2-BfL9/r` (1,119 first-parent commits, 422 of them merges), then runs `timeout 600 bash …/{pre,head}/scripts/build-loop.sh --main-log <root>`, cwd that clone. pre (1d829fee): rc 2, 8.01 s, 22:58:03Z. head (cca66dc2): rc 2, 9.95 s, 22:58:13Z. Both printed 1,117 other and 1 answers. Outputs: `/tmp/u3b2rv-fc2-BfL9/{pre,head}.out`, summary `/tmp/u3b2rv-fc2-BfL9/timing.txt`.

`scratchpad` = `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad`.

---

## Claim 1: "Status (iteration 1): no 🔴 · 🟡 3 · 🟢 9. D1-D5 and D9 fixed in the iteration-1 fix commit; the rest carry override rows dated 2026-10-12."

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:7`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the rubric's reader (the next iteration's orchestrator, the merge reviewer)
**Scope:** Covers the 🟢 count and the fixed/row partition against the rubric's own tables and override-log rows 718-726; does not establish whether each Fixed status is true (Claims 2-8).

The 🟢 table has ten rows, `| D4 |` through `| D13 |` (`:25-34`), not nine. The table also marks D6 and D7 Fixed: `| D6 | … | Fixed (comments both ways); shared fragment deferred with D8 |` (`:27`) and `| D7 | … | Fixed (comment on gate_msg) |` (`:28`). So "D1-D5 and D9 fixed" leaves out two of the fixed items, and "the rest carry override rows" is wrong for D6 and D7. No override row dated 2026-10-12 for this branch names architecture 1 or 4. Rows 718-726 cite i1 api-consistency 2/4, architecture 3, security F3/F4, architecture 2, architecture 3, and architecture 5/performance 1-2/api-consistency 3 (paraphrased — no quote available because the claim covers absence of a row; the nine rows were read in full). The precise version: "🟢 10. D1-D7 and D9 fixed; D8 and D10-D13 carry override rows". This is a text error; no code behaviour is involved.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:7`, `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:25-34`, `docs/reviews/override-log.md:718-726`

---

## Claim 2: "D1 … An amended gate or chore merge keeps its class … Fixed (tree must equal merge-tree's clean merge of the parents; test; mutant killed)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the rubric's reader (next iteration, merge reviewer)
**Scope:** Covers both halves (gate and chore) of the amended-merge case and that the test fails without the fix; does not establish that test 10 alone kills a mutant that breaks only the chore half (E3 case D shows that half directly), nor equivalence with every git merge configuration (Claim 20b).

The fix is the block at `scripts/build-loop.sh:1639-1642`:

```bash
  if [[ ${#ps[@]} -eq 2 ]]; then
    x="$(gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}")" \
      && [[ "$x" == "$(LC_ALL=C awk '/^tree / { print $2; exit }' "$GATE_TMP/c")" ]] || return 0
  fi
```

It runs before both the gate and chore branches of log_class, and `return 0` leaves `CLASS=other` (set at `:1633`). In E1 the pre-fix script and the m1 mutant (only this block deleted) both fail test 10 at `:202`. Each printed `gate a6ae0b47… Merge branch 'feat/x' (build-loop self-merge)` for the merge built over the slip tree (`tip main "$M" "$(git merge-tree --write-tree main feat/x)" "$(git rev-parse main)" "$X"`, test `:201`); HEAD prints other. For the chore half, E3 case D (`git merge --no-ff` of a chore branch, then `git commit --amend` adding slip.txt) printed `other c4592c00… Merge branch 'chore/dev-cycle-2026-10-15'` at HEAD and `chore c4592c00…` under m1.

**Evidence:** `scripts/build-loop.sh:1631-1642`, `test/scripts/build-loop-orchestrator.bats:195-207`, `test/scripts/build-loop-orchestrator.bats:213`, /tmp/u3b2rv-fc2-sEMN/logs/prefix.out, /tmp/u3b2rv-fc2-sEMN/logs/m1.out, scratchpad/fc2-mt.out

---

## Claim 3: "D2 | answers passes a commit that adds no answer: a Status flip alone, a deleted answer, a revert … Fixed (at least one added answer line; tests; mutant killed)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the rubric's reader (next iteration, merge reviewer)
**Scope:** Covers the code fix for all three cases and the tests' coverage of each; does not establish anything about answers commits beyond the three named shapes.

The code fix is right: `if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) { if (s == "+") n++; next }` (`scripts/build-loop.sh:1619`) with `END { flush(); exit !(n > 0 && !bad) }` (`:1623`). E3 case F printed `other 75c8ca2a… flip`, `answers 6f8dbf52… add` and `other 0e203629… Revert "add"`. Only one of the three cases has a test, though. The deleted-answer case is real and killed: m2b, which counts removed answer lines again, fails at `:217-218`, and its output reads `answers c19b559a… answer` for the deletion. The "Status flip alone" case is vacuous (Claim 33): that fixture commit is empty, and it reads other under every variant, m2 included (`other 426887bb… answer`). No test has a revert. Precise version: "tests: deleted answer (mutant killed); the Status-flip fixture is empty and the revert has no test".

**Evidence:** `scripts/build-loop.sh:1604-1623`, `test/scripts/build-loop-orchestrator.bats:215-218`, /tmp/u3b2rv-fc2-sEMN/logs/m2.out, /tmp/u3b2rv-fc2-sEMN/logs/m2b.out, /tmp/u3b2rv-fc2-ab9z/flip.out, scratchpad/fc2-mt.out

---

## Claim 4: "D3 | The U4 hand-off text omitted the subject tail rule, mode 100644 (not "regular"), and that a short SINCE is usage (exit 1) … Fixed (text)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:19`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the rubric's reader
**Scope:** Covers the presence of the three items in the header, plan note and row 719; does not establish that row 719 is otherwise complete (Claim 10).

Header: `parents, a subject "Merge branch 'B'" then the end, " into "` / `or ":" (any other text after the quote is other)` (`scripts/build-loop.sh:153-154`), `mode 100644) holding the line "Branch: B", anywhere in it` (`:157`), `mode 100644 on both sides` (`:160`), `id; a short one is a usage error, exit 1)` (`:173`). Plan `:325`: `SINCE is a full id (a short one is a usage error, exit 1)`, `(mode 100644)`, `(mode 100644 both sides)`. Row 719: `a subject "Merge branch 'B'" then the end, " into " or ":"`, `mode 100644`.

**Evidence:** `scripts/build-loop.sh:153-160`, `scripts/build-loop.sh:172-176`, `docs/working/plan-build-loop-handoff.md:325`, `docs/reviews/override-log.md:719`

---

## Claim 5: "D4 | No main SHA printed before a refusal … Fixed (`main MAIN -` first)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the rubric's reader
**Scope:** Covers both refusal paths of main_log; does not establish the listing-failure path at run time (static only: rev-list on MAIN_SHA, which state_start has just re-hashed, could not be made to fail without corrupting the store).

`|| { echo "main $MAIN_SHA -"; echo "refuse main-log: the default branch's first-parent history could not be listed"; return 1; }` (`scripts/build-loop.sh:1678`) and `|| { echo "main $MAIN_SHA -"; echo "refuse main-log: $1 is not on the default branch's first-parent history at $MAIN_SHA"; return 1; }` (`:1681`). In E1 the m4 mutant fails test 10 at `:220` (`want 2: main 4ea63edf… -`), and HEAD passes.

**Evidence:** `scripts/build-loop.sh:1674-1687`, `test/scripts/build-loop-orchestrator.bats:219-221`, /tmp/u3b2rv-fc2-sEMN/logs/m4.out

---

## Claim 6: "D5 | "only main's tip tree is re-hashed"; "its objects are not re-hashed" (MAIN itself is) … Fixed (row and header text)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the rubric's reader
**Scope:** Covers that both texts were changed and that row 721's new text is right; does not establish that the header's new wording is precise (Claim 25: "below MAIN" is ambiguous).

Row 721 now reads `(only main's own commit and tree are re-hashed, by state_start)`, which matches `store_check --main "$MAIN_SHA"` in state_start (`scripts/build-loop.sh:1219`). The header now reads `objects below MAIN are not re-hashed` (`:170`). Both texts changed as stated.

**Evidence:** `docs/reviews/override-log.md:721`, `scripts/build-loop.sh:169-171`, `scripts/build-loop.sh:1215-1221`

---

## Claim 7: "D6 … Fixed (comments both ways)" and "D7 | gate_msg's shape parsed a second time by the reader | … | Fixed (comment on gate_msg)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:27-28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the rubric's reader
**Scope:** Covers the presence of the comments; their accuracy is Claims 27, 28 and 31.

`--check-answer's (the lib's ANSWER_AWK, which points back here).` (`scripts/build-loop.sh:1602`). `# build-loop.sh's ANSWERS_AWK (--main-log's answers class) copies these labels` (`scripts/lib/dev-cycle-read.sh:2019`). `log_class parses the fields` / `# back out by the same shape (subject, line 3, line 4)` (`scripts/build-loop.sh:1365-1366`).

**Evidence:** `scripts/build-loop.sh:1363-1368`, `scripts/build-loop.sh:1597-1602`, `scripts/lib/dev-cycle-read.sh:2019-2020`

---

## Claim 8: "D9 | Empty subject printed as a trailing space | … | Fixed (`-`)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the rubric's reader
**Scope:** Covers a message whose first line is empty; does not establish behaviour for a subject made only of blanks (it is non-empty, so it prints as is).

`mapfile -t -n 5 m < "$GATE_TMP/m"; SUBJ="${m[0]-}"; [[ -n "$SUBJ" ]] || SUBJ=-` (`scripts/build-loop.sh:1638`). In E1, m9 fails test 10 at `:217` (`[ "${lines[4]}" = "other $E -" ]`). Its output line for that commit is `other 64d7f087…85b1a73c…`, with no `-`.

**Evidence:** `scripts/build-loop.sh:1638`, `test/scripts/build-loop-orchestrator.bats:214-217`, /tmp/u3b2rv-fc2-sEMN/logs/m9.out

---

## Claim 9: "D8 … Defer (row; U3c)", "D10 … Defer (row; U4) + hand-off text", "D11 … Defer (row; U3c/U4)", "D12 … Won't-Fix (row; U3b1's design)", "D13 … Defer (row; U4)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:29-34`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the rubric's reader
**Scope:** Covers the existence of a matching row with that disposition; the rows' content is Claims 10-16.

The rows exist with these dispositions. `| 🟢 Consider (Minor) | Defer | … Revisit trigger: U3c's --cycle-diff, the fourth reader` (row 724, D8). Row 725 is D10's Defer, and row 719 carries D10's hand-off text (`gathers one Branch: line per iteration, any of which counts`). Row 722 is D11's `Defer`, row 723 is D12's `Won't-Fix`, and row 726 is D13's `Defer`.

**Evidence:** `docs/reviews/override-log.md:719`, `docs/reviews/override-log.md:722-726`

---

## Claim 10: "--main-log's chore class needs U4's land to match it: a `git merge --no-ff` of `chore/dev-cycle-DATE[-HHMM]` … with no hand-resolved conflict (the merge's tree must be merge-tree's), a subject "Merge branch 'B'" then the end, " into " or ":", and the cycle record (docs/working/cycles/cycle-*.md, mode 100644) it adds or changes holding the line "Branch: B" as an unfenced line near the top; a record updated in place over several iterations of a day gathers one Branch: line per iteration, any of which counts"

**Location:** `docs/reviews/override-log.md:719`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** U4 implementer (writes the chore merge and the record)
**Scope:** Covers each requirement against log_class's chore branch and the merge-tree check; does not establish U4's land (not yet written).

The subject tail, the mode and the "any Branch line counts" parts match the code. The subject regex is `\'(chore/dev-cycle-…(-[0123456789]{4})?)\'($|\ into\ |:)` (`scripts/build-loop.sh:1650`), the mode test is `"$meta" =~ ^:[01234567]{6}\ 100644\ …\ [AM]$` (`:1654`), and the awk is `$0 == w { f = 1 }` over the whole blob (`:1656`). Two parts are off:

- **The record line.** "as an unfenced line near the top" is not what the reader needs. The awk accepts the line anywhere in the blob, fenced or not, and the header says `holding the line "Branch: B", anywhere in it` (`:157`). Writing it unfenced near the top is a safe practice, but stating it as the class's requirement is stricter than the code.
- **"no hand-resolved conflict" understates what makes an honest merge read as other.** A clean `git merge` also reads other when the caller's git config or the tree's attributes change the merge. In E3 case C, with `merge.directoryRenames = true` in the caller's global config, `git merge --no-ff` was clean (`git merge (directoryRenames=true) clean: e/one.txt e/three.txt e/two.txt`), merge-tree in the gate repository conflicted (`merge-tree exit 1`), and the merge printed `other a8b09db5… Merge branch 'chore/dev-cycle-2026-10-14'`. In E4, a `.gitattributes` line `docs/working/log.md merge=union` gave the same result: `git merge (checkout attributes, merge=union) clean`, then `other feeb8513… Merge branch 'chore/dev-cycle-2026-10-12'`.

The state gate refuses `merge.*` keys only in the repository's own config, not the global one (`STATE_KEYS_RE` checked "in the common config and this worktree's config.worktree", `scripts/build-loop.sh:519-527`). It reads no in-tree `.gitattributes`. Precise version: "… with no hand-resolved conflict, under git's default merge settings (no merge.*/diff.renames config, no merge attribute) …". Both deviations fail closed, toward other.

**Evidence:** `scripts/build-loop.sh:1639-1659`, `scripts/build-loop.sh:157`, `scripts/build-loop.sh:514-527`, `scripts/build-loop.sh:916-933`, scratchpad/fc2-mt.out (case C), scratchpad/fc2-union.out

---

## Claim 11: "--main-log reads history commits without store_check (only main's own commit and tree are re-hashed, by state_start)"

**Location:** `docs/reviews/override-log.md:721`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** future reviewer of the F19 residual
**Scope:** Covers the --main-log dispatch and log_class/main_log (no store_check call); does not establish store_check's own completeness.

The dispatch is `main-log)` / `state_start` / `main_log "${ARGS[0]}" || exit 2` (`scripts/build-loop.sh:1698-1700`). state_start runs `store_check --main "$MAIN_SHA"` (`:1219`). Neither main_log nor log_class calls store_check (paraphrased — no quote available because the claim covers absence of code; both functions, `:1631-1687`, were read in full).

**Evidence:** `scripts/build-loop.sh:1215-1221`, `scripts/build-loop.sh:1631-1687`, `scripts/build-loop.sh:1698-1700`

---

## Claim 12: "A chore merge's other paths are not read: a slip committed onto the chore branch itself lands as chore"

**Location:** `docs/reviews/override-log.md:722`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** U3c / U4 implementer
**Scope:** Covers the chore loop's handling of non-record paths; does not establish whether U3c's --cycle-diff will close it.

`[[ "$p" =~ ^docs/working/cycles/cycle-[^/]+\.md$ && "$meta" =~ … ]] || continue` (`scripts/build-loop.sh:1654`). A non-record path is skipped, and any matching record sets `CLASS=chore; return 0` (`:1656`). A slip committed on the chore branch merges cleanly, so the merge-tree check (`:1639-1642`) passes as well.

**Evidence:** `scripts/build-loop.sh:1639-1659`

---

## Claim 13: "--main-log runs with the caller's git -c pairs unchecked (only --state reads them)"

**Location:** `docs/reviews/override-log.md:723`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** future security reviewer
**Scope:** Covers where caller_gate runs; does not establish what each possible pair changes in log_class.

`if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` (`scripts/build-loop.sh:626`) is the only call of caller_gate (paraphrased — no quote available because the claim covers absence of other call sites: `grep -n caller_gate` finds only its definition `:575`, comments `:494`, `:559`, and `:626`).

**Evidence:** `scripts/build-loop.sh:575-590`, `scripts/build-loop.sh:620-627`

---

## Claim 14: "Three readers of `diff-tree --raw -z` (check_line, log_class's chore and answers loops) with different strictness … Each fails closed today (the chore loop skips an unparsed record: no record, other)."

**Location:** `docs/reviews/override-log.md:724`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** U3c implementer
**Scope:** Covers log_class's two loops; does not re-check check_line's reader (outside the fix range, verified in i1).

The answers loop returns on any unmatched record and checks the NUL count: `[[ "$x" -gt 0 && "$(tr -cd '\000' < "$GATE_TMP/d" | wc -c)" -eq $((2 * x)) ]] || return 0` (`scripts/build-loop.sh:1666`). The chore loop `continue`s past anything it cannot match (`:1654`), so an unparsed record never sets chore. Confidence is Medium because "fails closed" for the chore loop depends on diff-tree's `--no-renames` output always being meta/path pairs. That holds for `-r --no-renames --raw -z` (paraphrased — no quote available because it is a property of git's output format, not of this file).

**Evidence:** `scripts/build-loop.sh:1652-1669`

---

## Claim 15: "The cycle-record name is cycle-*.md here but cycle-YYYY-MM-DD.md in the lib's writable and dev-cycle.sh"

**Location:** `docs/reviews/override-log.md:725`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** U4 implementer
**Scope:** Covers the three patterns named; does not establish other readers of cycle records.

`^docs/working/cycles/cycle-[^/]+\.md$` (`scripts/build-loop.sh:1654`); `"$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$` inside `writable()` (`scripts/lib/dev-cycle-read.sh:243-245`); `for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do` (`scripts/dev-cycle.sh:217`).

**Evidence:** `scripts/build-loop.sh:1654`, `scripts/lib/dev-cycle-read.sh:243-245`, `scripts/dev-cycle.sh:217`

---

## Claim 16: "per-commit cost ~6-9 ms, ~8 s for a SINCE at this repo's root; --state and --main-log each re-hash main's tree"

**Location:** `docs/reviews/override-log.md:726`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** U4 implementer (bootstrap SINCE choice)
**Scope:** Covers one timed run each of the pre-fix and fixed script on a clone of /workspace main; does not establish run-to-run variance or timing on another machine.

The "~8 s" figure comes from i1, before the fix. It was extrapolated there ("That figure is extrapolated, not run", `docs/reviews/performance-review-2026-10-12-u3b2-i1.md:55`). In E5 the pre-fix script took 8.01 s at the root SINCE (1,118 commits). The fixed script took 9.95 s (about 8.9 ms/commit), because each of the 422 two-parent commits now also runs a merge-tree (`scripts/build-loop.sh:1639-1642`). The per-commit range still holds, but the root figure should read about 10 s. The re-hash part is right: both modes call state_start (`scripts/build-loop.sh:1694-1700`).

**Evidence:** `scripts/build-loop.sh:1639-1642`, `scripts/build-loop.sh:1694-1700`, `docs/reviews/performance-review-2026-10-12-u3b2-i1.md:55`, /tmp/u3b2rv-fc2-BfL9/timing.txt

---

## Claim 17: "SINCE is a full id (a short one is a usage error, exit 1) on main's first-parent history, else `main MAIN -` and `refuse main-log: WHY`. … (SUBJECT `-` when empty)"

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** U4 implementer
**Scope:** Covers the usage check, the not-on-history refusal and the empty subject; does not establish the listing-failure refusal at run time (static, Claim 5).

The usage check is `[[ $# -eq 2 && "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage "--main-log takes one full 40- or 64-hex commit id"` (`scripts/build-loop.sh:448`). `usage` exits 1 (`:439`). Test 10's `:222` asserts exit 1 and that stderr, and passes in E1 head. The refusal and `-` are covered in Claims 5 and 8.

**Evidence:** `scripts/build-loop.sh:439-448`, `scripts/build-loop.sh:1674-1687`, `test/scripts/build-loop-orchestrator.bats:219-222`, /tmp/u3b2rv-fc2-sEMN/logs/head.out

---

## Claim 18: "A two-parent commit is gate or chore only when its tree is merge-tree's clean merge of its parents (an amended merge keeps message and parents: i1 security F1) … answers: one parent, only the questions files modified (mode 100644 both sides) … at least one answer line added (i1 security F2)."

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** U4 implementer
**Scope:** Covers the literal mechanism (merge-tree in the gate repository) and the answers rules; the note's hand-off "no hand-resolved conflict" has the same missing qualifier as row 719 (Claim 10).

The mechanism is quoted in Claim 2 (`scripts/build-loop.sh:1639-1642`). The answers meta test is `[[ "$meta" =~ ^:100644\ 100644\ [0123456789abcdef]+\ [0123456789abcdef]+\ M$ && ( "$p" == docs/working/questions.md || "$p" == docs/working/questions-archive.md ) ]] || return 0` (`:1662`), and the added-answer count is at `:1619`. E1 and E3 cases D and F confirm the behaviour.

**Evidence:** `scripts/build-loop.sh:1639-1642`, `scripts/build-loop.sh:1660-1669`, scratchpad/fc2-mt.out, /tmp/u3b2rv-fc2-sEMN/logs/m1.out

---

## Claim 19: "oldest first ("-" before a refusal)" and "SUBJECT: the message's first line ("-" when empty)"

**Location:** `scripts/build-loop.sh:146-148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** --main-log caller (orchestrator author)
**Scope:** Covers the N field before a refusal and the empty subject; see Claims 5 and 8 for the code and the mutant runs.

`echo "main $MAIN_SHA -"` precedes both refusals (`:1678`, `:1681`), and `[[ -n "$SUBJ" ]] || SUBJ=-` is at `:1638`. The m4 and m9 mutants are killed (E1).

**Evidence:** `scripts/build-loop.sh:1638`, `scripts/build-loop.sh:1678-1681`, /tmp/u3b2rv-fc2-sEMN/logs/m4.out, /tmp/u3b2rv-fc2-sEMN/logs/m9.out

---

## Claim 20a: "A two-parent commit is gate or chore only when its tree is the clean merge of its parents (merge-tree), as --merge … write[s] it; an amended or hand-resolved merge is other."

**Location:** `scripts/build-loop.sh:148-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** --main-log caller; U4 implementer
**Scope:** Covers --merge's own merges, amended merges, conflicted (hand-resolved) merges, and git merge under default settings with several merge bases, renames, and a second parent that is an ancestor of the first; does not cover git merge under non-default config or merge attributes (Claim 20b).

--merge computes its tree with the same call in the same repository: `out="$(gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1")"` (`scripts/build-loop.sh:1012`, inside merge_result `:1006-1016`, which returns 1 on conflict). It then commits that tree on the parents `-p "$MAIN_SHA" -p "${VERDICT[tip]}"` (`:1457`). So log_class's recomputation over the same parents gives the same tree, and test 9 (E1 head ok) reads a real `--merge` commit as gate. A conflicted merge makes merge-tree exit 1, so `x="$(…)" && …` fails and `|| return 0` leaves other.

Against `git merge --no-ff` with default settings, E3 gave identical trees and the chore class in each case:

- **A, criss-cross with 2 merge bases:** `git merge tree 7e7bc849… merge-tree 7e7bc849…`, `chore c8a916d6…`.
- **B, rename against modify:** `git merge tree 2f2ff4ca… merge-tree 2f2ff4ca…`, `chore 96d31518…`.
- **E, a second parent that is an ancestor of the first:** merge-tree returned the first parent's tree (`a43a22fa… vs HEAD^1 tree a43a22fa…`). That commit read other only because its record was unchanged against the first parent.

An amended merge is other (Claim 2).

**Evidence:** `scripts/build-loop.sh:1006-1016`, `scripts/build-loop.sh:1456-1458`, `scripts/build-loop.sh:1639-1642`, scratchpad/fc2-mt.out, /tmp/u3b2rv-fc2-sEMN/logs/head.out

---

## Claim 20b: "… as --merge and git merge write it"

**Location:** `scripts/build-loop.sh:150-151`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** U4 implementer (lands chore with git merge)
**Scope:** Covers git merge in a checkout whose caller config or tree attributes change the merge; does not enumerate every such setting (merge.renames, diff.renames, -X options and others are inferred from git's documented defaults, not each run).

"As git merge writes it" holds only when git merge runs with git's default merge settings and no merge attribute applies. The gate repository reads no config but its object format (`printf '[core]\n\trepositoryformatversion = 1\n[extensions]\n\tobjectformat = %s\n'`, `scripts/build-loop.sh:931`), and no checkout `.gitattributes` (the comment at `:918-921` explains the empty work dir). git merge in the main checkout reads the caller's global config and the checkout's `.gitattributes`. Two executed cases diverge. In E3 case C (global `merge.directoryRenames = true`), git merge was clean while merge-tree exit 1 → `other`. In E4 (`merge=union` in `.gitattributes`), git merge was clean → `other`. Both diverge toward other (a false positive that stops dispatch, never a false class). Precise version: "as --merge writes it, and as git merge writes it with git's default merge settings and no merge attribute".

**Evidence:** `scripts/build-loop.sh:916-933`, `scripts/build-loop.sh:1639-1642`, scratchpad/fc2-mt.out (case C), scratchpad/fc2-union.out

---

## Claim 21: "a subject "Merge branch 'B'" then the end, " into " or ":" (any other text after the quote is other)"

**Location:** `scripts/build-loop.sh:153-154`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** U4 implementer
**Scope:** Covers the chore subject regex; does not establish what happens to a chore-named merge whose subject happens to match the gate regex first (impossible: the gate regex needs "(build-loop", which is not one of the three chore tails).

`"$SUBJ" =~ ^Merge\ branch\ \'(chore/dev-cycle-[0123456789]{4}-[0123456789]{2}-[0123456789]{2}(-[0123456789]{4})?)\'($|\ into\ |:)` (`scripts/build-loop.sh:1650`). A two-parent commit that matches neither branch falls through to `return 0` with `CLASS=other` (`:1670`).

**Evidence:** `scripts/build-loop.sh:1644-1671`

---

## Claim 22: "a cycle record the merge adds or changes (docs/working/cycles/cycle-*.md, mode 100644) holding the line "Branch: B", anywhere in it (a trailing CR dropped)"

**Location:** `scripts/build-loop.sh:156-158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** U4 implementer
**Scope:** Covers the path, mode, status and line match; does not establish the record's other content (row 722).

The path regex is `^docs/working/cycles/cycle-[^/]+\.md$`, and the meta must match `^:[01234567]{6}\ 100644\ [0123456789abcdef]+\ ([0123456789abcdef]+)\ [AM]$` (`:1654`). The line check is `awk -v w="Branch: $b" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }'` (`:1656`), which accepts the line anywhere in the blob.

**Evidence:** `scripts/build-loop.sh:1652-1659`

---

## Claim 23: "answers: one parent, and only docs/working/questions.md or questions-archive.md change, mode 100644 on both sides"

**Location:** `scripts/build-loop.sh:159-160`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** U4 implementer
**Scope:** Covers the meta and path check; the line rules are Claims 24 and 28.

See the regex quoted in Claim 18 (`scripts/build-loop.sh:1662`): both modes are `100644` and the status is `M`.

**Evidence:** `scripts/build-loop.sh:1660-1669`

---

## Claim 24: "at least one answer line added"

**Location:** `scripts/build-loop.sh:167`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** --main-log caller
**Scope:** Covers removed answer lines, a Status flip and a revert; does not establish behaviour for an added answer label with an empty value (it counts: the label regex alone decides).

`{ if (s == "+") n++; next }` (`scripts/build-loop.sh:1619`). E3 case F and E1 m2b support it (Claim 3).

**Evidence:** `scripts/build-loop.sh:1615-1623`, scratchpad/fc2-mt.out, /tmp/u3b2rv-fc2-sEMN/logs/m2b.out

---

## Claim 25: "The class is read from the commit's own text (and objects below MAIN are not re-hashed)"

**Location:** `scripts/build-loop.sh:169-170`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** future security reviewer
**Scope:** Covers what store_check re-hashes for --main-log; does not establish store_check's correctness.

The intended meaning, that history commits before MAIN are not re-hashed, is right (Claim 11). But this file uses "below" for the objects under a tree. store_check's comment reads `Each REV (a commit or a tree), its root tree, and every tree and blob below it … are read in one cat-file --batch and re-hashed` (`scripts/build-loop.sh:946-949`). In that vocabulary, "objects below MAIN" are MAIN's tree and blobs, and those are re-hashed (`store_check --main "$MAIN_SHA"`, `:1219`). Precise version: "commits before MAIN, and objects not in MAIN's tree, are not re-hashed".

**Evidence:** `scripts/build-loop.sh:944-956`, `scripts/build-loop.sh:1215-1221`

---

## Claim 26: "or "main MAIN -" and refuse main-log: WHY, when SINCE (a full id; a short one is a usage error, exit 1) is not on that history … or it cannot be listed."

**Location:** `scripts/build-loop.sh:172-176`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** --main-log caller
**Scope:** Same as Claims 5 and 17.

The code is quoted in Claims 5 and 17 (`scripts/build-loop.sh:448`, `:1678`, `:1681`). The test assertions at `:219-222` pass at head and fail under m4.

**Evidence:** `scripts/build-loop.sh:448`, `scripts/build-loop.sh:1676-1681`, /tmp/u3b2rv-fc2-sEMN/logs/m4.out

---

## Claim 27: "log_class parses the fields back out by the same shape (subject, line 3, line 4) and compares bytes, so a change here must change its parser too; gate merges already on main keep the old shape and would read as other inside a SINCE window."

**Location:** `scripts/build-loop.sh:1365-1368`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer of gate_msg
**Scope:** Covers the parse positions and the byte compare; the last clause is a consequence of the byte compare, not an observed event.

The parser reads `SUBJ="${m[0]-}"` (the subject) at `:1638`, then `[[ "${m[2]-}" =~ ^Build-loop-gate:\ (.+)$ ]]` (line 3) at `:1645` and `[[ "${m[3]-}" =~ ^Build-loop-approved:\ (Q-[0123456789]+)$ ]]` (line 4) at `:1648`. It compares bytes with `cmp -s "$GATE_TMP/want" "$GATE_TMP/m"` (`:1649`).

**Evidence:** `scripts/build-loop.sh:1369-1372`, `scripts/build-loop.sh:1638-1649`

---

## Claim 28: "at least one answer line is added (a Status flip, a deleted answer or a revert alone adds none: i1 security F2). The labels are --check-answer's (the lib's ANSWER_AWK, which points back here)."

**Location:** `scripts/build-loop.sh:1597-1602`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer of ANSWERS_AWK
**Scope:** Covers the three cases and the label set; does not claim the label match is identical in id scope (ANSWERS_AWK accepts any `Q-NNN:` line, ANSWER_AWK only its own entry's id), which the comment does not assert.

E3 case F printed `other … flip` and `other … Revert "add"`. The deleted-answer case is in E1 m2b. The labels are ANSWER_AWK's: `line = $0; sub(/^- /, "", line)`, `if (index(line, id ":") == 1)` and `if (low !~ /^\*\*answer(:|ed| \()/) next` (`scripts/lib/dev-cycle-read.sh:2055-2058`) against ANSWERS_AWK's `t = l; sub(/^- /, "", t)` / `if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/)` (`scripts/build-loop.sh:1618-1619`).

**Evidence:** `scripts/build-loop.sh:1597-1623`, `scripts/lib/dev-cycle-read.sh:2045-2058`, scratchpad/fc2-mt.out

---

## Claim 29: "C, its changes and the record it adds are read in the gate repository … any failed read makes C other. A two-parent commit counts only when its tree is the clean merge of its parents, as land and git merge write it: an amended merge keeps both parents and the message (i1 security F1)."

**Location:** `scripts/build-loop.sh:1624-1630`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer of log_class
**Scope:** Covers the gate_git reads and the merge-tree check under default git merge settings; the "git merge" qualifier gap is the one in Claim 20b, which applies here too and is not counted twice.

Every read goes through gate_git (`:1634`, `:1640`, `:1652`, `:1656`, `:1659`, `:1667`), and each failure path leads to `return 0` with `CLASS=other`. gate_git returns 3 on any stderr (`:937-942`). Amended merges read other (Claim 2).

**Evidence:** `scripts/build-loop.sh:937-942`, `scripts/build-loop.sh:1631-1671`, /tmp/u3b2rv-fc2-sEMN/logs/m1.out, scratchpad/fc2-mt.out

---

## Claim 30: "Main's commit first, even before a refusal (U4 records it: i1 api-consistency 1)."

**Location:** `scripts/build-loop.sh:1676`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer of main_log
**Scope:** Same as Claim 5.

The code and runs are cited in Claim 5.

**Evidence:** `scripts/build-loop.sh:1674-1687`, /tmp/u3b2rv-fc2-sEMN/logs/m4.out

---

## Claim 31: "build-loop.sh's ANSWERS_AWK (--main-log's answers class) copies these labels and the header line's Status field: change both together."

**Location:** `scripts/lib/dev-cycle-read.sh:2019-2020`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer of ANSWER_AWK
**Scope:** Covers the labels and the Status-field parse; does not cover the trailing-blank trim (ANSWER_AWK trims the value's end, ANSWERS_AWK drops the value entirely, so the trim is moot there).

ANSWER_AWK reads the Status field with `for (i = 1; i <= n; i++) { f = fld[i]; sub(/^[ \t]+/, "", f); if (substr(f, 1, 12) == "**Status:** ") v = substr(f, 13) }` (`scripts/lib/dev-cycle-read.sh:2050`). ANSWERS_AWK's `needs()` does `t = f; sub(/^[ \t]+/, "", t); if (substr(t, 1, 12) == "**Status:** ") f = "**Status:**"` (`scripts/build-loop.sh:1607`), the same field rule. The labels are quoted in Claim 28.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2045-2058`, `scripts/build-loop.sh:1604-1609`

---

## Claim 32: "The gate message on two parents with their clean merge is gate; with a line more, on one parent, approved without its trailer, or over another tree (an amended merge: i1 security F1), other."

**Location:** `test/scripts/build-loop-orchestrator.bats:195-196`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** test maintainer
**Scope:** Covers the five fixtures at `:197-201` and their expected lines `:202-207`.

The fixtures do what the comment says. G sits on `"$(git merge-tree --write-tree main "$X")" "$S" "$X"`. Then come `$'\nmore'`, `tip main "$M"` with one parent, the approved message without `Build-loop-approved`, and the amended case: tree `merge-tree main feat/x` after the slip commit, parents `main` and the old `$X`. E1 shows head passing and both prefix and m1 failing at `:202`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:195-207`, /tmp/u3b2rv-fc2-sEMN/logs/prefix.out, /tmp/u3b2rv-fc2-sEMN/logs/m1.out

---

## Claim 33: "… a Status flip alone; deleting an answer (i1 security F2)."

**Location:** `test/scripts/build-loop-orchestrator.bats:210`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** test maintainer; the next review iteration (D2's "tests")
**Scope:** Covers the Status-flip fixture only (the deletion fixture is real: Claim 34); does not establish the script's behaviour, which is right (Claim 24).

The fixture `q 's/\*\*Status:\*\* OPEN/**Status:** ANSWERED/'` (`:216`) runs after `:215`. That line already changed the header to `agent · **Opened:** 2026-10-12 · **Status:** ANSWERED`, and the file has no other `**Status:** OPEN`. So the sed matches nothing, and `commit_all` (`git commit -q --allow-empty`, `test/lib/build-loop-fixtures.bash:29`) makes an empty commit. E2 printed `== answer files: ` (no files) for that commit, and the file's only Status line is `4:**Needs:** agent · **Opened:** 2026-10-12 · **Status:** ANSWERED`. The commit reads other because its diff is empty (`x -gt 0` fails, `scripts/build-loop.sh:1666`), not because of D2's rule. Under m2 (pre-fix counting) it still printed `other 426887bb… answer`. The test therefore does not exercise a Status flip. This is behavioural in the test code (a vacuous fixture), not in the script. A real Status flip reads other at HEAD (E3 case F).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:208-218`, `test/lib/build-loop-fixtures.bash:29`, `scripts/build-loop.sh:1666`, /tmp/u3b2rv-fc2-ab9z/flip.out, /tmp/u3b2rv-fc2-sEMN/logs/m2.out

---

## Claim 34: "A chore merge whose record names another branch, a branch outside the pattern, or amended with another file; an empty commit (subject printed as -); a header line whose route changes too; a blank line alone; … deleting an answer"

**Location:** `test/scripts/build-loop-orchestrator.bats:208-210`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** test maintainer
**Scope:** Covers these seven fixtures (E2 shows each commit's files); does not establish the reason each one reads other beyond the amended chore (E3 case D), the empty subject (m9) and the deletion (m2b).

E2 lists the following, each matching its comment:

- the three chore merges, each changing `docs/working/cycles/cycle-2026-10-12.md`, the third also `slip2.txt`;
- the empty-subject commit (`==  files: `);
- three questions commits;
- the empty Status-flip commit (Claim 33).

The m9 and m2b mutants fail on the empty-subject and deletion lines respectively.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:211-218`, /tmp/u3b2rv-fc2-ab9z/flip.out, /tmp/u3b2rv-fc2-sEMN/logs/m9.out, /tmp/u3b2rv-fc2-sEMN/logs/m2b.out

---

## Claim 35: Commit message of cca66dc2: "D1 (security F1): … a two-parent commit now counts only when its tree equals merge-tree's clean merge of its parents. D2 (security F2): a Status flip, a deleted answer or a revert passed as answers; at least one added answer line is required. D4: "main MAIN -" before a refusal. D9: an empty subject prints "-". Text: the U4 hand-off (subject tail, mode 100644, short SINCE is usage), the re-hash scope, back-pointers between the lib's ANSWER_AWK and ANSWERS_AWK, gate_msg's parser note. … Notes: a hand-resolved chore merge now reads as other (fail closed); handed to U4 in the row."

**Location:** `scripts/build-loop.sh:1639-1642` (subject of the D1 claim; commit cca66dc2 message)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** `git log` reader
**Scope:** Covers each stated change against the diff and the runs above; does not repeat the test-coverage gap (Claim 33), since the message does not claim a Status-flip test.

Each item is in the diff and was checked: D1 in Claim 2, D2 in Claim 24, D4 in Claim 5, D9 in Claim 8, the text items in Claims 4, 6 and 7. For the hand-off, row 719 says `with no hand-resolved conflict (the merge's tree must be merge-tree's)`.

**Evidence:** `scripts/build-loop.sh:1597-1687`, `docs/reviews/override-log.md:719`, /tmp/u3b2rv-fc2-sEMN/logs/

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:7`): the status line says 🟢 9 where the table has 10 rows (D4-D13), and "D1-D5 and D9 fixed; the rest carry override rows" leaves out D6 and D7, which are marked Fixed and have no rows. Text.
- **Claim 33** (`test/scripts/build-loop-orchestrator.bats:210`, fixture at `:216`): the "Status flip alone" case is an empty commit, because `:215` already flipped Status, so the test never exercises D2's Status-flip case. Behavioural in the test code; the script is right.

### Stale
(none)

### Mostly Accurate
- **Claim 3** (`docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:18`): D2 "tests; mutant killed" holds only for the deleted answer. The Status-flip test is vacuous and no test has a revert.
- **Claim 10** (`docs/reviews/override-log.md:719`): "unfenced line near the top" is stricter than the reader, which accepts the line anywhere. "No hand-resolved conflict" also needs "under git's default merge settings and no merge attribute": a global `merge.directoryRenames=true` or a `merge=union` attribute makes an honest merge read as other.
- **Claim 16** (`docs/reviews/override-log.md:726`): a root SINCE now takes about 10 s (9.95 s measured), not ~8 s, since each merge also runs merge-tree.
- **Claim 20b** (`scripts/build-loop.sh:150-151`): "as … git merge write[s] it" needs "with git's default merge settings and no merge attribute".
- **Claim 25** (`scripts/build-loop.sh:169-170`): "objects below MAIN are not re-hashed". In this file "below" means under a tree, and MAIN's tree objects are re-hashed. Should read: commits before MAIN, and objects not in MAIN's tree.

### Unverifiable
(none)

---

## Goal-Alignment Note

Success criterion: "A code-fact-check report saved to docs/reviews/code-fact-check-report-2026-10-12-u3b2-i2.md in the worktree, per the code-fact-check skill." Met: this file is at that path, with first line `Commit: cca66dc2` and the Replication line in the header. It carries the skill's header fields and the seven mandatory per-claim fields plus a Legibility-target tag on every claim.

The brief listed five areas to check. Each was checked against the code that exercises it, with execution where the subject was executable:

1. **The fix commit and rubric rows D1-D13:** each named test was run against the pre-fix script and against one mutant per fix. All mutants are killed except that the Status-flip fixture is vacuous.
2. **The new header text.**
3. **The comment blocks.**
4. **The override rows and the plan note.**
5. **merge-tree equivalence:** criss-cross, rename and ancestor-parent cases match git merge. Caller global merge config and merge attributes diverge, but only toward other.

The two Incorrect verdicts are a rubric count/partition (text) and a vacuous test fixture (test code). No Incorrect is behavioural in `scripts/`. I made no edits to the worktree but this file, and I ran no writing git command outside my own throwaway repositories.
