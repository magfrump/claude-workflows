**Commit:** baa46e3
**Replication:** k=3

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-digest (branch feat/dev-cycle-digest; code under review at baa46e3, identical in scripts/ and test/ to HEAD 65bd433)
**Scope:** scripts/dev-cycle.sh and test/scripts/dev-cycle.bats, full branch 4225753..baa46e3; commit messages 3aee138, 83e7895, baa46e3; fixes F1-F6. Final pass 3 (iteration 4). Merged by the orchestrator from `code-fact-check-report-r{1,2,3}-digest-final3.md` (most-severe-wins verdicts, union of annotations).
**Checked:** 2026-09-30
**Total claims checked:** 34
**Summary:** 22 verified, 7 mostly accurate, 1 stale, 3 incorrect, 1 unverifiable

Execution logs: `docs/reviews/execution-logs/r{1,2,3}-digest-final3-*.txt`. All three replicates ran the suite (13/13 pass at baa46e3; tests 2 and 3 fail on de53069's script) and probes in `mktemp -d` repos.

---

## Claim 1: "a newline in a file name cannot forge a line" (baa46e3, F5)

**Location:** commit baa46e3 body; code at `scripts/dev-cycle.sh:122`, `scripts/dev-cycle.sh:141`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the carried-forward list; does not establish other output paths (merge subjects are single-line `%s`; log rows come from line-oriented grep).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "only the heading at :119 replaces the newline; `carried+=("${f#docs/decisions/}")` stores the raw name and :141 prints it" · r1+r3: "no test covers the newline replacement; a mutant dropping it passes all 13 tests"
**Legibility-target:** for-author

Probes r1 D1, r2 P3b, r3 P4: a record whose trigger section is unchanged and whose name contains LF (e.g. `$'002-a\n### 999-forged (fake).md'`) prints `Carried forward (N): … 002-a` followed by a separate forged `### 999-forged (fake).md` line. The control filter at :42 keeps LF. Behavioral: the code does not meet the invariant its fix commit states.

**Evidence:** `scripts/dev-cycle.sh:119,122,141`; `execution-logs/r1-digest-final3-probe2.txt` (D1), `r2-digest-final3-probes.txt` (P3b), `r3-digest-final3-probes.txt` (P4)

---

## Claim 2: "Changed = its trigger section differs from the default branch's copy at the window start: merged, fast-forwarded, branch-only and uncommitted all count" / baa46e3 "That covers merges, fast-forwards, branch-only and uncommitted records" (F1) — on the date fallback

**Location:** `scripts/dev-cycle.sh:114-116` (with `:109`); commit baa46e3 body, bullet 1
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback path (record without a parseable "Main at:" line, or a non-ancestor sha); does not establish how often that path is reached — no cycle record exists yet, and the skill template writes the line verbatim.
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r1: "reached by a mis-copied line or rewritten history, not by the first cycle (no record → full print)" · r2+r3: "the first cycle after this lands will always take the fallback, because no existing record has the line" (contradicts r1's reach note when no record exists; applies only if a record exists without the line) · r2: "a new record whose trigger section is empty is listed as carried" · r3 P11: "fallback base: ece86d2 2020-01-03 late" — the fast-forwarded commit itself
**Legibility-target:** for-author

r1 probe A: with no "Main at:" line, `git rev-list -1 --first-parent --before="$SINCE_TS"` walks by committer date and returned the old-dated fast-forwarded commit at the tip; the digest printed "Carried forward (3): 001-old.md 002-new.md 003-late.md" — a record committed today and the fast-forwarded record were both carried unjudged. F1's original failure, reproduced on the fallback.

**Evidence:** `scripts/dev-cycle.sh:108-109,116`; `execution-logs/r1-digest-final3-probe1.txt` (A), `r2-digest-final3-probes.txt` (P7), `r3-digest-final3-probes2.txt` (P2, P11)

---

## Claim 3: "N merge(s) on `$MAIN`'s first-parent line; M commit(s) reachable from it, merged branches included."

**Location:** `scripts/dev-cycle.sh:89-93`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Activity counts (and section 4's sample, drawn from `$merges`) when the first-parent line holds a commit dated before the window; does not establish behavior with monotonic dates, where counts were correct in tests 1, 5 and 11. Present since 3aee138.
**Replicate verdicts:** r1=Incorrect · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "the same fast-forward, old-date scenario baa46e3's message names; test 3 builds it without checking section 1"
**Legibility-target:** for-author

git's `--since` stops the walk at an old-dated commit. Probe C: two `--no-ff` merges made today beneath a fast-forwarded commit dated 2020-01-03; digest printed "0 merge(s) on `main`'s first-parent line; 0 commit(s)" while `git log --first-parent --merges main` lists both.

**Evidence:** `scripts/dev-cycle.sh:89-94,170-174`; `execution-logs/r1-digest-final3-probe1.txt` (C)

---

## Claim 4: "control characters are stripped from everything printed" / baa46e3 "All output passes through one control-character filter" (F3)

**Location:** `scripts/dev-cycle.sh:40,42`; commit baa46e3 bullet 4
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers stdout C0/DEL stripping; does not establish stderr or C1 handling.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2: "C1 CSI U+009B (bytes C2 9B) passes" · r1+r2+r3: "stderr is not filtered (`--bogus^[X` echoes ESC)" · r3 P8: "with 2>&1 an error appears ahead of all sections, so its position does not show which step failed"
**Legibility-target:** for-author

**Evidence:** `scripts/dev-cycle.sh:31,42`; `execution-logs/r2-digest-final3-probes.txt` (P4), `r3-digest-final3-probes2.txt` (P8, P10)

---

## Claim 5: Window line "Triggers: the working tree, compared with `$MAIN` at the window start. Questions, roadmap: the working tree." / baa46e3 "Window line states exactly which sections read what" (F6)

**Location:** `scripts/dev-cycle.sh:84`; commit baa46e3 bullet 5
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Window line against sections 2 and 5; does not establish the skill's reading of it.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "log rows are date-selected from the working tree, never compared with main" · r1+r3: "window start is the recorded commit, or a committer-date estimate on the fallback" · r2: "with --since nothing is compared; roadmap date comes from HEAD's history"
**Legibility-target:** for-author

**Evidence:** `scripts/dev-cycle.sh:84,109,125-140,181`

---

## Claim 6: "Printed in full: triggers in decision records changed since $SINCE, and log rows dated on or after it."

**Location:** `scripts/dev-cycle.sh:99`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text against lines 106-140; does not establish that the recorded commit equals the state at `$SINCE`.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r3 Q2: "triggers edited on the start day but before the recorded commit are carried; a 2020-dated edit fast-forwarded in the window prints"
**Legibility-target:** for-author

**Evidence:** `scripts/dev-cycle.sh:99,106-116`; `execution-logs/r3-digest-final3-probes2.txt` (Q2)

---

## Claim 7: "Window start = the commit the last cycle recorded ("Main at:"), else by date." and baa46e3 "falls back to the last first-parent commit before the window when a record lacks it (commit dates alone are unreliable after a fast-forward)"

**Location:** `scripts/dev-cycle.sh:107-109`; commit baa46e3 bullet 2
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `(A && B) || C` at :109 with --since, no record, non-matching and non-ancestor lines; does not establish that the date branch yields the window start (Claim 2).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1+r2+r3: "the fallback is silent; no digest line says which base was used" · r1+r2+r3: "a bulleted, backticked, bold, indented, lowercase-key or uppercase-hex line falls back" · r1+r2: "the fallback chooses by committer date, the unreliability the message's own parenthetical names" · r1+r2+r3: "precedence at :109 is correct" · r3: "64-character SHA-256 hashes still resolve"
**Legibility-target:** for-author

**Evidence:** `scripts/dev-cycle.sh:106-109`; `execution-logs/r1-digest-final3-probe1.txt` (B), `r3-digest-final3-probes.txt` (P1)

---

## Claim 8: Same comment (:114-115), with a verbatim, ancestor "Main at:" line

**Location:** `scripts/dev-cycle.sh:114-116`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merged, fast-forwarded, uncommitted, in-window and edit-outside-the-section cases when `$base` comes from the record; does not establish the fallback (Claim 2).
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r1+r2: "a new record whose trigger section is empty compares equal (both sides empty) and is carried" · r1: "a git show or cmp failure reads as differs (printed), the safe direction; set -e/pipefail do not reach inside the process substitutions; a ':' in a path is fine" · r1+r3: "mutations ignoring the line or comparing whole files fail test 3"
**Legibility-target:** for-author

**Evidence:** `scripts/dev-cycle.sh:106,110-124`; `test/scripts/dev-cycle.bats:64-87`; `execution-logs/r1-digest-final3-probe2.txt` (E), `r1-digest-final3-mutations.txt`

---

## Claim 9: baa46e3 "Unit stays at 399 lines."

**Location:** commit baa46e3 bullet 6
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count; does not establish the size-cap rule.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: "399 now (187 + 212), but 396 at 83e7895/de53069 — it grew by three, so 'stays' is loose"
**Legibility-target:** for-author

**Evidence:** `wc -l` on both files at baa46e3 and de53069

---

## Claim 10: 83e7895 message: "Uncommitted files show 'never: uncommitted'…" / "counts as changed when it entered the default branch in the window (first-parent…) or is uncommitted"

**Location:** commit 83e7895 message
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against baa46e3; accurate for its own commit.
**Replicate verdicts:** r1=— · r2=Stale · r3=Stale
**Replicate annotations:** r2+r3: "historical; nothing to fix"
**Legibility-target:** for-author

**Evidence:** `scripts/dev-cycle.sh:116,119,182`

---

## Claim 11: baa46e3 "ignores edits elsewhere in the file (which also resolves the deferred file-level cost, performance Medium)"

**Location:** commit baa46e3 bullet 1
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** The "ignores edits elsewhere" half is Verified by test 3 and probes; the cost claim needs a measurement on real records.
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable (r3 Claim 26 Verified the "ignores edits" half)
**Replicate annotations:** r3: "routed to performance-reviewer"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/scripts/dev-cycle.bats:75`

---

## Claims 12-34: Verified

Each below: **Verdict:** Verified · **Confidence:** High · **Legibility-target:** for-orchestrator-synthesis · **Replicate annotations:** none unless stated.

## Claim 12: header purpose and Q-074 rationale
**Location:** `scripts/dev-cycle.sh:4-6` · **Type:** Reference · **Verdict:** Verified · **Confidence:** High · **Verification mode:** static · **Scope:** skill file exists on the stacked branch. · **Replicate verdicts:** r1=Verified · r2=— · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `scripts/dev-cycle.sh:4-6`

## Claim 13: --since default (newest cycle record, else 14 days)
**Location:** `scripts/dev-cycle.sh:10-13` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** tests and probes. · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `scripts/dev-cycle.sh:64-77`

## Claim 14: "Read-only: writes nothing to the repo" / baa46e3 "No git status call, so nothing writes .git/index" (F2)
**Location:** `scripts/dev-cycle.sh:16`; baa46e3 bullet 3 · **Type:** Invariant · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** `.git` listing unchanged with a stat-dirty index; de53069 changed it. · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `execution-logs/r2-digest-final3-probes.txt` (P5)

## Claim 15: exit codes; "a failed step exits non-zero mid-digest" (F4)
**Location:** `scripts/dev-cycle.sh:17-18` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** failing `shuf` shim exits 3 through `$(…)` and a pipe. · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `execution-logs/r2-digest-final3-probes2.txt`

## Claim 16: "before the cd: relative paths work"
**Location:** `scripts/dev-cycle.sh:36` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** relative invocation. · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `scripts/dev-cycle.sh:36,145`

## Claim 17: "File names are literal, not pathspecs" (F5 first half)
**Location:** `scripts/dev-cycle.sh:39-41` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** wildcard-named records. · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** r1+r3: "no test covers GIT_LITERAL_PATHSPECS; a mutant dropping it passes all tests" · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `execution-logs/r1-digest-final3-mutations.txt` (M5)

## Claim 18: hash-only default branch; option-named branch
**Location:** `scripts/dev-cycle.sh:43-44` · **Type:** Invariant · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** test 12. · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `scripts/dev-cycle.sh:45-62`

## Claim 19: other branch name uses the current branch
**Location:** `scripts/dev-cycle.sh:56` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** — · **Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `scripts/dev-cycle.sh:55-61`

## Claim 20: "ignore future-dated"
**Location:** `scripts/dev-cycle.sh:68` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** test. · **Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `scripts/dev-cycle.sh:68`

## Claim 21: midnight anchor
**Location:** `scripts/dev-cycle.sh:79-80` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** — · **Replicate verdicts:** r1=— · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `scripts/dev-cycle.sh:80`

## Claim 22: "Main at: $MAIN_SHA (copy this line into the cycle record; the next digest compares triggers against it)"
**Location:** `scripts/dev-cycle.sh:85` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** the verbatim, unindented form the skill template asks for (SKILL.md:137). · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** r1+r2+r3: "only the bare form parses; see Claim 7" · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `scripts/dev-cycle.sh:85,108`

## Claim 23: "An explicit --since was given, so every trigger is printed in full."
**Location:** `scripts/dev-cycle.sh:102` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** — · **Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `scripts/dev-cycle.sh:97-103`

## Claim 24: heading newline replacement and "last committed on this branch" / one spelling of "never, uncommitted" (F5 second half, F6)
**Location:** `scripts/dev-cycle.sh:118-119,182` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** heading only (carried list: Claim 1). · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** r1+r3: "a mutant dropping the replacement passes all tests" · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `execution-logs/r1-digest-final3-probe2.txt` (D2)

## Claim 25: prefer capitalised "Revisit"
**Location:** `scripts/dev-cycle.sh:131-134` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** test 2. · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `test/scripts/dev-cycle.bats:50-62`

## Claim 26: `open` column format
**Location:** `scripts/dev-cycle.sh:150-152` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** test 9. · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `scripts/dev-cycle.sh:150-159`

## Claim 27: seeded sample
**Location:** `scripts/dev-cycle.sh:171-174` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** — · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `scripts/dev-cycle.sh:173-174`

## Claim 28: test header hermeticity
**Location:** `test/scripts/dev-cycle.bats:3-4,14` · **Type:** Reference · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** — · **Replicate verdicts:** r1=— · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `test/scripts/dev-cycle.bats:1-20`

## Claim 29: test 2 asserts no ESC reaches output (F3 regression)
**Location:** `test/scripts/dev-cycle.bats:50-62` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** fails when the filter is removed. · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `execution-logs/r2-digest-final3-mutants.txt`

## Claim 30: test 3 "unchanged triggers carry forward and changed ones print"
**Location:** `test/scripts/dev-cycle.bats:64-87` · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** section 2 only. · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** r1: "does not check section 1 in the fast-forward scenario (Claim 3)" · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `execution-logs/r1-digest-final3-mutations2.txt`

## Claim 31: bats comments at :100, :175
**Location:** `test/scripts/dev-cycle.bats:100,175` · **Type:** Reference · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** — · **Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `test/scripts/dev-cycle.bats:100,175`

## Claim 32: baa46e3 "Tests: fast-forwarded old-dated record, edit outside the trigger section, recorded Main at: start, control codes in record text. Both fail on de53069."
**Location:** commit baa46e3 bullet 6 · **Type:** Reference · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** tests 2 and 3 fail on de53069. · **Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified · **Replicate annotations:** r3: "the four cases are extensions of existing tests 2 and 3, not new tests" · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `execution-logs/r3-digest-final3-bats-on-de53069.txt`

## Claim 33: baa46e3 Notes "The skill must copy the 'Main at:' line into each cycle record"
**Location:** commit baa46e3 Notes · **Type:** Reference · **Verdict:** Verified · **Confidence:** High · **Verification mode:** static · **Scope:** SKILL.md:134-137 on feat/dev-cycle. · **Replicate verdicts:** r1=— · r2=Verified · r3=Verified · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:134-137`

## Claim 34: 3aee138 "13 hermetic tests"
**Location:** commit 3aee138 message · **Type:** Reference · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed · **Scope:** — · **Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection · **Replicate annotations:** none · **Legibility-target:** for-orchestrator-synthesis · **Evidence:** `execution-logs/r3-digest-final3-bats-head.txt`

---

## Escalations

- **security-reviewer** (r1+r2+r3): forged line via a newline in a carried record name (`scripts/dev-cycle.sh:122,141`); C1 controls and unfiltered stderr (`:42`).
- **api-consistency-reviewer** (r1+r2+r3): "Main at:" parses only the undecorated form and falls back silently; the digest never says which base it used (`:108-109`); Window line omits log-row and --since handling (`:84`).
- **performance-reviewer** (r3): verify "resolves the deferred file-level cost" (baa46e3).
- **orchestrator** (r2, r3): whether the first cycle after landing reaches the fallback (r1: no — no record means full print).

## Verdict stability

- Clusters: 34 (compound rows counted per sub-claim).
- All reporting replicates agreed: 28.
- Disagreed (6): Claim 2 (r1=Incorrect, r2/r3=Mostly accurate compound); Claim 7 (r1/r2=MA, r3=Verified); Claim 8 (r1=Verified, r2/r3=MA compound); Claim 9 (r2=MA, r1/r3=Verified); Claim 11 (r3 only, Unverifiable vs its own Verified half); Claim 3 counted as agreed (single replicate) but is a single-replicate detection of an Incorrect.
- Agreement rate: 28/34 ≈ 82%. Single-replicate detections: 7 (Claims 3, 19, 20, 23, 31, 34, 11).
