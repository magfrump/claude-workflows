Commit: ca95fead
**Replication:** k=1 (confirming pass)

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u4a, branch feat/build-loop-u4a)
**Scope:** partial: fix range b1a6f0a2..ca95fead (8d18e566 code, tests and commit message; ca95fead plan text). Part 2: five routed endorsement claims verdicted at HEAD ca95fead. The rest of the branch is context only.
**Checked:** 2026-10-13
**Total claims checked:** 18
**Summary:** 12 verified, 4 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Hallucination log (`docs/reviews/hallucination-patterns.md`) read first. No claim below matches a logged pattern, and neither Incorrect is a fabricated symbol. The log was not updated: the brief allows writing only this file, and nothing here qualifies anyway.

Execution provenance. Every probe ran from cwd `/workspace/.claude/wt-build-loop-u4a`. It invoked `scripts/build-loop.sh` by absolute path inside its own `mktemp -d /tmp/u4a-fcc-*` repository, which it removed afterwards. Captured outputs are in the session scratchpad `/tmp/claude-1000/-workspace/8681a912-a74a-4649-a416-551a1bfd4a4f/scratchpad/u4a-fcc/`, abbreviated `$S` below. No process was left running (checked with `pgrep`).
- E0: `LC_ALL=C TMPDIR=/tmp/u4a-fcc-qQMd timeout 900 bats -f 'cycle-diff|land-cycle|roadmap' test/scripts/build-loop-orchestrator.bats`, 2026-10-13T21:20:22Z, exit 0, 5/5 ok. Output in `$S/bats.txt`.
- E1: `timeout 300 bash $S/p1.sh`, 2026-10-13T21:21:05Z, exit 0. Output in `$S/p1.out`. It probes the allowlist, the STEM binding, qrc 1/2 and rule order.
- E2: `timeout 500 bash $S/p2.sh <wt>/scripts/build-loop.sh $S`, 2026-10-13T21:22:38Z, exit 0. Output in `$S/p2.out`. It runs the land through CAS and through ff with planted hooks, the S2 refusals, S4 record shapes and wall-clock timing.
- E3: `timeout 300 bash $S/p3.sh <wt> $S`, 2026-10-13T21:23:28Z, exit 0. Output in `$S/p3.out`. It times each function of a `git archive ca95fead` copy on a small repository.
- E4: `timeout 500 bash $S/p4.sh <wt> $S`, 2026-10-13T21:23:51Z, exit 0. Output in `$S/p4.out`. It repeats E3's timing on a 3,484-file clone of main.
- E5: `timeout 200 bash $S/p5.sh <wt>/scripts/build-loop.sh`, 2026-10-13T21:24:50Z, exit 0. Output in `$S/p5.out`. It probes the F3/F4 shapes, a docs-level "below" shape, and a loop's docs-only commit carried on the chore branch.

---

## Claim 1: "A path other than the cycle's own files, a .md under docs/ or README.md refuses (what --check-fix may allow an in-cycle fix)." (also 8d18e566: "the scope --check-fix gives an in-cycle fix")

**Location:** `scripts/build-loop.sh:215-218`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the allowlist test at `:1933` and its order after the gate-code, truth and case rules. It does not establish that the allowlist equals `--check-fix`'s scope. It is wider (docs/working/, docs/reviews/ and @-imported docs .md pass) and narrower on case (`readme.md`, `Docs/x.md` refuse).

The rule as coded:
```bash
# scripts/build-loop.sh:1933
if [[ "$TRUTH_WHY" != cycle && "$p" != docs/*.md && "$p" != README.md ]]; then echo "refuse $p: not a file the cycle changes ..."; bad=1; continue; fi
```
`truthrule` resets `TRUTH_WHY=""` on entry (`scripts/lib/dev-cycle-read.sh:1915`), so a previous path's `cycle` word cannot carry over. E1 results:
- `test/t.bats`, `docs/x.txt`, `readme.md` and `Docs/y.md` refuse with the allowlist message.
- `docs/reviews/r.md`, `docs/thoughts/t.md`, `docs/working/handoff.md` and the cycle record pass.
- `AGENTS.md`, `docs/.x.md` and `scripts/build-loop.sh` refuse by the earlier gate-code and truth rules, not by the allowlist.

`--check-fix` is narrower inside docs/. It skips anything under `docs/(working|reviews)/` and runs the import walk:
```bash
# scripts/dev-cycle.sh:191
elif [[ -n "$TRUTH_WHY" || ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|reviews)/ ]]; then
```
It also compares lower-cased (`^readme\.md$` on `lp`), where cycle_rules matches `README.md` exactly. So the parenthetical "what --check-fix may allow" reads as an equality but describes a bound that is looser in some places and tighter in others. The rule itself is as stated.

**Evidence:** `scripts/build-loop.sh:1919-1933`, `scripts/lib/dev-cycle-read.sh:1914-1922`, `scripts/dev-cycle.sh:184-196`, `$S/p1.out`

---

## Claim 2: "Any other path is one --check-fix could allow an in-cycle fix: a .md under docs/ or README.md. A commit the chore branch carries from elsewhere (a loop's branch) refuses here (final security F1, F3, F4)."

**Location:** `scripts/build-loop.sh:1930-1932`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a carried commit that touches a path outside the allowlist, which refuses. It does not establish that a carried commit refuses as such: a loop commit changing only docs/*.md lands.

E5 merged a `feat/loop` commit that added `docs/loop-notes.md` into the chore branch, then added the record. `--land-cycle` printed `landed chore/dev-cycle-2026-10-12 ...` (exit 0), and main's merge lists `docs/loop-notes.md`. The rule judges paths, not provenance (paraphrased — no quote available because the claim concerns the absence of any history read in `cycle_rules`/`land_cycle`; `grep` finds no rev-list or reachability call in either). The precise version would be: "a carried commit that changes any path outside the allowlist refuses here."

**Evidence:** `scripts/build-loop.sh:1930-1933`, `$S/p5.out`

---

## Claim 3a: An added Asked: item's entry heading must end "-STEM-N" (STEM the brief's file name without .md)

**Location:** `scripts/build-loop.sh:230-233`, `:1966-1968`, `:1989`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex test on the heading text after the first " · ", including a plain-suffix stem (`ax` vs `x`) and a heading without " · ". It does not establish uniqueness of the binding when one brief's stem is a hyphen-suffix of another's (claim 3b).

```bash
# scripts/build-loop.sh:1964
while IFS=$'\t' read -r id k; do newh[$id]="$k"; done < "$t.new"
# scripts/build-loop.sh:1989
elif ! [[ "${newh[$id]#* · }" =~ (^|-)"${f%.md}"-[0123456789]+$ ]]; then echo "refuse ... whose entry's heading does not end -${f%.md}-N (an entry filed for this brief)"; bad=1
```
The heading reaches `newh` through cy.new's new tab field (`:2035`: `print $1 "\t" l`, where `l` is the QKEYS line with its first three fields stripped). E1: an entry `keep-or-drop-2026-10-01-ax-1` named on brief `2026-10-01-x.md` refuses, and so does a heading `### Q-002 2026-10-01-x-1` with no " · ". In E0 test 3, `keep-or-drop-2026-10-01-x-1` passes for x and the same ID on y refuses. The slug form matches the skill's rule: `skills/dev-cycle/SKILL.md:316`, "slug `keep-or-drop-<brief file name without .md>-<n>`".

**Evidence:** `scripts/build-loop.sh:1964`, `:1989`, `:2035`, `skills/dev-cycle/SKILL.md:316`, `$S/p1.out`, `$S/bats.txt`

---

## Claim 3b: "naming an entry this change files ... for this brief" / refusal text "(an entry filed for this brief)"; brief claim 2 "a stem that is a suffix of another's cannot match the wrong one"

**Location:** `scripts/build-loop.sh:1966`, `:1989`; `docs/working/plan-build-loop-handoff.md:209` ("for that brief")
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the binding of an Asked: ID to the brief its entry was filed for. It does not assess how likely such brief names are or what severity that carries; that belongs to the security critic.

The test anchors STEM only at a hyphen or the start, `(^|-)"${f%.md}"-[0-9]+$` (`:1989`, quoted under claim 3a). An entry filed for a brief whose stem ends in `-<another brief's stem>` therefore also satisfies the other brief's test. SLUG allows digits and hyphens (`scripts/lib/dev-cycle-read.sh:239`: `SLUG='[abcdefghijklmnopqrstuvwxyz0123456789-]+'`), so `2026-10-01-y-2026-10-01-x.md` is a legal brief name. E1 tested this: entry `### Q-002 · keep-or-drop-2026-10-01-y-2026-10-01-x-1` (filed for brief `2026-10-01-y-2026-10-01-x`), with Q-002 appended to brief `2026-10-01-x.md`'s Asked: line, gave `--cycle-diff` → `ok`, exit 0.

The plain-suffix case (`ax` vs `x`) is refused, so the brief's "suffix" claim holds for a non-hyphen suffix only. What the code establishes is "the heading ends -STEM-N". That holds, and the entry need not be the brief's own. A follow-up brief whose slug embeds its parent's full stem is the realistic shape. The defect is behavioral (the rule accepts it), with a narrow trigger.

**Evidence:** `scripts/build-loop.sh:1989`, `scripts/lib/dev-cycle-read.sh:239-240`, `$S/p1.out` (section "hyphen-suffix stem")

---

## Claim 4: questions_rules "returns 1 on an entry's refusal, 2 when a copy is refused whole or a read fails (cy.new then says nothing)"; cy.new is "one per line with its heading line after a tab: empty when no questions file changed"

**Location:** `scripts/build-loop.sh:1996-2002`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers all seven fatal exits and the entry-refusal path. It does not establish behavior when `$t.new` itself cannot be written, since the `: >` truncation at `:2007` is not checked.

There are seven `return 2` sites: `:2013` (side not 100644 or unreadable), `:2016` (ls-tree), `:2018` (base copy), `:2024` (copy refused whole), `:2025` (QKEYS read), `:2029` (QDIFF compare) and `:2036` (cy.new compare, after `: > "$t.new"`). cy.new is truncated first (`:2007`: `: > "$t.new"`), so every early return leaves it empty. Entry refusals set `bad=1` (`:2031`) and fall through to the cy.new write and `return "$bad"` (`:2037`). In cycle_rules, `questions_rules ... || { qrc=$?; bad=1; }` (`:1963`) captures the function's own status.

E1 "qrc 1" case: Q-001 was changed without `--answered` while a correct Q-002 was appended. Only the Q-001 refusal printed, with no "names no entry" for Q-002, so cy.new was written. E1 "qrc 2" case: the only refusals were the whole-file one and the bad-form item.

**Evidence:** `scripts/build-loop.sh:2003-2038`, `:1963`, `$S/p1.out`

---

## Claim 5: "When a questions file is refused whole or unread, only the item's form is judged." / "When the questions files were not read (qrc 2), only the item's form is judged."

**Location:** `scripts/build-loop.sh:234-235`, `:1972-1973`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the form check and the skip of the entry, heading and once rules under qrc 2. It does not establish that the run still refuses overall; it does, through `bad=1` from questions_rules.

```bash
# scripts/build-loop.sh:1986-1987
if ! [[ "$x" =~ ^(Q-[0123456789]+)(@[0123456789abcdef]{7,64})?$ ]]; then echo "refuse ... which is not Q-NNN or Q-NNN@SHA"; bad=1; continue; fi
id="${BASH_REMATCH[1]}"; [[ "$qrc" -ne 2 ]] || continue
```
E1 (`Asked: Q-002, zz` with an unbalanced fence appended) printed the whole-file refusal and `adds "zz", which is not Q-NNN or Q-NNN@SHA` only. E0 test 3 asserts the same for a correct item (`cd_is "refuse docs/working/questions.md: --check-answer refuses its index copy whole (unbalanced 12)"`), and it passed.

**Evidence:** `scripts/build-loop.sh:1986-1990`, `$S/p1.out`, `$S/bats.txt`

---

## Claim 6: Renamed comments: "The cycle rules' questions reader (--cycle-diff, --land-cycle)", "against the listing side's", "The cycle rules' roadmap rule ... the listing's side"

**Location:** `scripts/build-loop.sh:1813`, `:1828`, `:1849`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the callers of QKEYS_AWK, QDIFF_AWK and ROADMAP_AWK through cycle_rules and questions_rules. It does not establish any other caller of those awk programs outside build-loop.sh.

`cycle_rules` is called from `cycle_diff` (`:1904`: `cycle_rules "$base" index`) and from `land_cycle` (`:2068`: `cycle_rules "$MAIN_SHA" merge || return 1`). It runs ROADMAP_AWK at `:1957` and questions_rules, which runs QKEYS_AWK and QDIFF_AWK at `:2025` and `:2028`. In both modes the second file is the listing's side (the index, or the merge R).

**Evidence:** `scripts/build-loop.sh:1904`, `:1957`, `:2025-2028`, `:2068`

---

## Claim 7: 8d18e566 message: "this also refuses AGENTS.md/x (F3) and a Kelvin-sign SKILLS/ path (F4)"

**Location:** commit 8d18e566 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two shapes as filed (root `AGENTS.md/x`, `SKILLS/dev-cycle/x.md` written with U+212A). It does not establish that the floor's "below" class is closed under docs/: `docs/AGENTS.md/x.md` passes, because it is a .md under docs/.

E5 `--cycle-diff` printed `refuse AGENTS.md/x: not a file the cycle changes ...` and `refuse SKILLS/dev-cycle/x.md: not a file the cycle changes ...` (exit 2). `docs/AGENTS.md/x.md` was not refused.

**Evidence:** `scripts/build-loop.sh:1933`, `$S/p5.out`

---

## Claim 8: Test name "... (row 745, U4a, i1 security F1-F3, i2 F-a to F-d, final F1-F4)" and comment "Only the cycle's files, a .md under docs/ or README.md: a loop's commit carried on the chore branch refuses (final F1, F3, F4)."

**Location:** `test/scripts/build-loop-orchestrator.bats:466`, `:495-498`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers which findings the test plants. It does not establish coverage of F3's directory shape or F4's SKILLS shape as filed.

The test plants `src/app.sh` (F1), `docs/x/y.md` and `README.md` (allowed), and `"AGENTS.md$(printf 'K')"`, a file named AGENTS.md followed by a Kelvin sign. The last one is neither F3's `AGENTS.md/x` nor F4's `SKILLS/...` (`:496`: `echo k > "AGENTS.md$(printf 'K')"`). F2 is tested at `:478` (the -STEM-N refusal on Y). E0 passed. E5 shows both filed shapes refuse anyway (claim 7), so only the test's coverage claim is loose.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:466-498`, `$S/bats.txt`, `$S/p5.out`

---

## Claim 9: U3c roadmap test: "Step 6's rewrites: ... an idea appended, any other path." with `other.md` moved to `docs/other.md`

**Location:** `test/scripts/build-loop-orchestrator.bats:449-451`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test passing with `docs/other.md`. It does not establish that "any other path" passes, since a non-docs path now refuses.

E0 test 2 passed with `echo x > docs/other.md` (`:451`). After the allowlist, the comment's "any other path" would be more precise as "any other allowed path (a .md under docs/)".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:449-451`, `$S/bats.txt`

---

## Claim 10: Plan --cycle-diff bullet: "U4a adds rules every path meets: only the cycle's own files, a .md under docs/ or README.md; no gate code, no truthrule file but the cycle's own, no cycle file spelled in another case; a brief's Asked: line only extended, each item exactly Q-NNN or Q-NNN@SHA, naming an entry the change files whose heading ends -STEM-N for that brief, added once ... Refusals: `refuse PATH`, `refuse HEAD`, `refuse index`."

**Location:** `docs/working/plan-build-loop-handoff.md:209`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed rule against `cycle_rules` and the three refusal prefixes in `cycle_diff`. It does not establish uniqueness of "for that brief" (claim 3b).

The rules sit at `:1925`, `:1929`, `:1933` and `:1980-1991`, and E0/E1 exercised each one. The prefixes appear as `echo "refuse HEAD: ..."` (`:1881`, `:1883`) and `echo "refuse index: ..."` (`:1887`, `:1897`).

**Evidence:** `scripts/build-loop.sh:1879-1905`, `:1913-1994`, `$S/p1.out`, `$S/bats.txt`

---

## Claim 11: Plan as-built: "`--main-log`'s chore class now reads only a record named cycle-YYYY-MM-DD.md (isrecord), narrower than U3b2's cycle-*.md above."

**Location:** `docs/working/plan-build-loop-handoff.md:339`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the predicate change from main's code to HEAD's. Execution of the narrowed reading is in claim 15.

main's `log_class` matched `^docs/working/cycles/cycle-[^/]+\.md$` (`git show main:scripts/build-loop.sh`, line 1706). HEAD's `chore_record` uses `isrecord` (`scripts/lib/dev-cycle-read.sh:246`: `^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$`). The plan's U3b2 note says "a changed docs/working/cycles/cycle-*.md" (`:326`).

**Evidence:** `scripts/build-loop.sh:1742-1748`, `scripts/lib/dev-cycle-read.sh:246`, `docs/working/plan-build-loop-handoff.md:326`

---

## Submitted Claims

## Claim 12: "S1: `--land-cycle` writes exactly what it judged: commit-tree of merge_result's R with parents MAIN_SHA and HEAD's commit h, message `chore_msg B`, then update-ref from MAIN_SHA or `merge --ff-only` in W, with no hooks run."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:2042-2078` (land_cycle), `:1485-1575` (land)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both move paths, the CAS and the fast-forward in W where main is checked out, with hooks planted in the repository. It does not establish behavior when W's own config.worktree sets other merge options than the cleared `branch.main.mergeOptions`, nor races after the re-gate (Q-103's class).

land_cycle sets `VERDICT=([tip]="$h" [tree]="$r" ... [branch]="$b" ...)` (`:2071`), where `r` is merge_result's output (`:2051`). land writes:
```bash
# scripts/build-loop.sh:1560-1562
{ if [[ "$1" == cycle ]]; then chore_msg "${VERDICT[branch]}"; else gate_msg ...; fi; } > "$GATE_TMP/msg" \
  && x="$(gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}" < "$GATE_TMP/msg")" \
```
It then runs `update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA"` or `merge --ff-only -q "$NEW"` in W (`:1566-1574`). Hooks are off because the lib exports `core.hooksPath=/dev/null` through GIT_CONFIG_COUNT (`scripts/lib/dev-cycle-read.sh:352`, `:360-363`).

E2 planted pre-merge-commit, post-merge, reference-transaction, post-commit, pre-commit and post-checkout hooks. A sanity line confirmed the fixture's own git runs them. CAS land: parents equal `M H`, the tree equals `git merge-tree --write-tree main HEAD`, the message is exactly `Merge branch 'chore/dev-cycle-2026-10-12'`, and no hook ran. FF land in W: parents and tree match likewise, W's HEAD equals main, the reflog reads `build-loop: cycle land of chore/dev-cycle-2026-10-13-0900: Fast-forward`, and no hook ran.

**Evidence:** `scripts/build-loop.sh:2051`, `:2071-2074`, `:1560-1574`, `scripts/lib/dev-cycle-read.sh:352-363`, `$S/p2.out`

---

## Claim 13: "S2: `--land-cycle` refuses when `--main` is not main's commit at run time, and when the index differs from HEAD's commit."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:2047-2052`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the check of `--main` against MAIN_SHA as resolved at start, with the CAS from MAIN_SHA as the later guard, and staged additions or deletions. It does not establish refusal for unstaged or untracked working-tree changes, which the land ignores by design because it takes HEAD's commit.

```bash
# scripts/build-loop.sh:2047, 2050-2051
[[ "$LAND_MAIN" == "$MAIN_SHA" ]] || { echo "refuse HEAD: the default branch is at $MAIN_SHA, not --main's $LAND_MAIN; ..."; return 1; }
git diff-index --cached --quiet --ignore-submodules=none "$h" -- 2>"$GATE_TMP/err" && [[ ! -s "$GATE_TMP/err" ]] \
  || { echo "refuse HEAD: the index holds changes its commit lacks, or could not be read; commit them first"; return 1; }
```
E2: a wrong `--main` refused with exit 2, and so did a staged new file and a staged deletion (`git rm --cached`). E0 test 4 also checks the moved-main text.

**Evidence:** `scripts/build-loop.sh:2047-2052`, `$S/p2.out`, `$S/bats.txt`

---

## Claim 14: "S3: `--land-cycle` judges the merge against main, not the index: a rename git pairs into a new questions file carrying main's answer refuses."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:2063-2068`, cycle_rules `:1913-1994`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rename-into-questions case and the conflict refusal. It does not establish the fence-pair capture without a rename, which uses the same listing but was not run separately.

```bash
# scripts/build-loop.sh:2065-2068
gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$r" > "$GATE_TMP/diff" && raw_records "$GATE_TMP/diff" \
  || { echo "refuse HEAD: the paths its merge changes could not be listed"; return 1; }
# cycle_rules reads RAW_* and leaves it as raw_records filled it, for chore_record and CHANGED.
cycle_rules "$MAIN_SHA" merge || return 1
```
E0 test 5 passed. `--cycle-diff` printed ok, while `--land-cycle` printed `refuse docs/working/questions.md: Q-001 is a new entry filed answered ..., and Q-001 is not in --answered`, and a conflicting x.md refused.

**Evidence:** `scripts/build-loop.sh:2063-2068`, `test/scripts/build-loop-orchestrator.bats:529-537`, `$S/bats.txt`

---

## Claim 15: "S4: log_class's chore arm reads a record only at docs/working/cycles/cycle-YYYY-MM-DD.md, mode 100644, status A or M."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:1742-1748` (chore_record), `:1777-1782`; `scripts/lib/dev-cycle-read.sh:246` (isrecord)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the name, mode and status filters and the exact `Branch: B` line. It does not establish the mid-pipe read-failure path (pipefail), which was read but not run.

```bash
# scripts/build-loop.sh:1745-1747
isrecord "${RAW_P[i]}" && [[ "${RAW_NM[i]}" == 100644 && "${RAW_S[i]}" =~ ^[AM]$ ]] || continue
# pipefail: a failed read is no record.
gate_git cat-file blob "${RAW_NO[i]}" | LC_ALL=C awk -v w="Branch: $1" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }' && return 0
```
E2 merged four `chore/dev-cycle-2026-10-20` branches with `git merge --no-ff`. `--main-log` read `cycle-x.md` (100644) as other, `cycle-2026-10-14.md` (100755) as other, `Cycle-2026-10-16.md` as other, and `cycle-2026-10-15.md` (100644) as chore.

**Evidence:** `scripts/build-loop.sh:1742-1748`, `:1777-1782`, `scripts/lib/dev-cycle-read.sh:246`, `$S/p2.out`

---

## Claim 16a: "P1: the ~130 ms `--land-cycle` adds over `--state` is mostly land's existing re-checks"

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:2042-2078` (land_cycle), `:1485-1575` (land)
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the time split inside land_cycle on a 3,484-file clone and on a small fixture, CAS path. It does not establish the fast-forward path's split (which runs one more state_gate in W) or the reviewer's exact host.

The reviewer's own decomposition attributes the remainder to "`land`'s existing second state gate and default_gate" (performance report `:48`). E4 timed each function on a clone of main (3,484 files, wrappers on a `git archive ca95fead` copy, three runs). land_cycle took 72-81 ms in all:

| Part | Time | Share of land_cycle |
|---|---|---|
| land() | 28-34 ms | about 40% |
| land()'s re-gates (state_gate + default_gate) | 17-21 ms | about 25% |
| store_check(h, r) | 20-24 ms | about 30% |
| merge_result | about 10 ms | about 13% |
| cycle_rules | 1.8 ms | about 2% |
| chore_record | 2.4 ms | about 3% |
| the rest (rev-parse, diff-index, is-ancestor, diff-tree) | about 8 ms | |

Whole-run wall clock was 412-455 ms against `--state`'s 342-349 ms, a difference of about 65-110 ms (E2 unwrapped, small repo: 60-66 vs 156-171 ms). land's re-checks are therefore about a quarter of the added time, not most of it; store_check of HEAD and R costs about as much. The ~130 ms total also did not reproduce here (65-110 ms). Doc-only: this is a review-report attribution, with no code or comment text affected.

**Evidence:** `$S/p4.out`, `$S/p3.out`, `$S/p2.out`, `docs/reviews/performance-review-2026-10-13-u4a-final.md:34-48`

---

## Claim 16b: "P1: ... not U4a's new code"

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:1913-1994` (cycle_rules), `:1742-1748` (chore_record)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers U4a's new judging code (cycle_rules, chore_record) at about 4 ms, roughly 6% of land_cycle. It does not establish this for land_cycle's own new calls into existing helpers (store_check, merge_result, diff-tree), which U4a added and which make up most of the time.

The E4 per-function times are in claim 16a. The new rule code is cheap at this N. Under the stricter reading, where "U4a's new code" includes land_cycle's calls to pre-existing helpers, the claim would not hold.

**Evidence:** `$S/p4.out`, `$S/p3.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3b** (`scripts/build-loop.sh:1989`): the -STEM-N test does not bind an ID to its own brief. An entry filed for brief `2026-10-01-y-2026-10-01-x` passes on brief `2026-10-01-x`'s Asked: line (executed). Behavioral, high confidence.
- **Claim 16a** (performance report P1): land()'s re-gates are about 25% of land_cycle's time, not most of it. store_check(h, r) costs about as much, and the delta measured 65-110 ms, not 130. Doc-only, medium confidence.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`scripts/build-loop.sh:215-218`): the allowlist is not `--check-fix`'s scope. It is wider in docs/working/ and docs/reviews/ and on imported docs, and stricter on case.
- **Claim 2** (`scripts/build-loop.sh:1930-1932`): a carried loop commit refuses only if it touches a non-allowlisted path. A docs-only one lands.
- **Claim 8** (`test/scripts/build-loop-orchestrator.bats:466`): the "final F1-F4" test plants neither F3's `AGENTS.md/x` nor F4's `SKILLS/` shape.
- **Claim 9** (`test/scripts/build-loop-orchestrator.bats:449`): "any other path" is now "any other allowed path".

### Unverifiable
- None.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the exact path your own prompt names, structured per your skill." This report is saved at `/workspace/.claude/wt-build-loop-u4a/docs/reviews/code-fact-check-report-2026-10-13-u4a-confirm.md`. Its first line is `Commit: ca95fead` and the replication tag is k=1. Part 1 covers the fix range's comments, header, tests, plan text and the 8d18e566 message. Part 2 sits under `## Submitted Claims`, with each claim's submitting critic named. Every claim carries the seven fields and a Legibility-target. Executed verdicts cite command, cwd, exit code, time and captured output.
