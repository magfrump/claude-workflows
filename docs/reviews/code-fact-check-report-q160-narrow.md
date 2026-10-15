Commit: 1a118c80

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q160`, branch `fix/q160-iteration-cap`)
**Scope:** fix commit only: `git diff 7d61c39b..1a118c80 -- workflows guides skills docs/decisions docs/working`, the commit message of 1a118c80, the rubric's "Iteration 3" section and the new override-log rows (other `docs/reviews/*` files are context)
**Checked:** 2026-10-15
**Total claims checked:** 20
**Summary:** 12 verified, 8 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable
**Replication:** k=1 (narrow check)

Partial-scope label: commits before 7d61c39b are context only, not under review. Execution evidence is quoted inline because the brief said not to write execution-log files.

---

## Claim 1: "The unit's limit is ~800 lines (twice the entry cap) until a waiver sets another." / waiver limit rules

**Location:** `workflows/review-fix-loop.md:57`, `:59`, `:61`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the owner section's definition of "limit" and how a waiver sets it (F4); does not establish that every restatement elsewhere uses the same definition (Claims 8, 11, 13).

`review-fix-loop.md:57`: "The unit's limit is ~800 lines (twice the entry cap) until a waiver sets another. The check fires above the limit". `:59`: "its waive option proposes a new limit with headroom above the current count". `:61`: "A granted waiver sets the limit the re-check uses from then on: the one its answer names, or the one the chosen option proposed. If neither names one, the limit is the count the entry asked about". These agree with each other, and the F4 fix (an option with headroom grants that headroom) is in place.

**Evidence:** `workflows/review-fix-loop.md:57-61`

---

## Claim 2: F7, F13, F14: counts with no following commit, GitHub-path re-run, squash

**Location:** `workflows/review-fix-loop.md:57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the three rules are in the text and that pr-prep step 4 exists; does not establish that step 4's own text tells the agent to carry `Size:` lines (step 4 is unchanged and does not mention them).

`:57`: "On the GitHub path, run it again before merging if commits landed after 6c." … "a count with no following commit (the one that stops the loop, a pass with no fixes, the one at 6c) goes in the waiver entry or the PR description. When pr-prep step 4 squashes commits, carry their `Size:` lines into the squashed commit's body". Step 4 exists: `workflows/pr-prep.md:296` "#### 4. Clean up commit history".

**Evidence:** `workflows/review-fix-loop.md:57`, `workflows/pr-prep.md:296`

---

## Claim 3: F5: "Work on independent units goes on; units stacked above this one wait with it."

**Location:** `workflows/review-fix-loop.md:59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the clause performance L1 asked for is present; does not establish any change to the stacking rules in pr-prep 1a/1b.

The quoted sentence is at `:59` verbatim.

**Evidence:** `workflows/review-fix-loop.md:59`

---

## Claim 4: F10: the /away reading named as Q-160's (loop doc and row 62)

**Location:** `workflows/review-fix-loop.md:59`, `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quotes from Q-104 against `docs/working/questions-archive.md` ### Q-104; does not establish what the user meant by "Same as [1]".

Loop doc: "Q-104 [2] says the loop \"asks you for a waiver\" and has no /away wording; reading it as not inheriting option [1]'s /away split ([2] opens \"Same as [1], but\") is Q-160's reading". Row 62: "([2] has no /away wording, though it opens \"Same as [1], but\" and [1] split automatically in /away mode)". The archive has [1]: "Past 400 lines, the loop stops and the growth is split into a stacked unit (in /away mode, automatically)." and [2]: "Same as [1], but growth up to ~800 lines is tolerated. Past that, the loop stops and asks you for a waiver." Every quote matches, and [2] has no /away wording.

**Evidence:** `docs/working/questions-archive.md` (### Q-104 options table), `docs/decisions/log.md:85`, `workflows/review-fix-loop.md:59`

---

## Claim 5: F16: "Everything else in this section is Q-160's reading of it, for example …"

**Location:** `workflows/review-fix-loop.md:65`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the attribution no longer claims to be a complete list; does not re-check each item against Q-104 (done in the final pass).

`:65`: "Q-104 [2] gives the re-measure, the ~800 tolerance and the waiver. Everything else in this section is Q-160's reading of it, for example the before-merge point, …".

**Evidence:** `workflows/review-fix-loop.md:65`

---

## Claim 6: F1: "step 1a's /away split covers only a unit no review loop has run on; a unit that grew under review stays under the stop when it re-enters pr-prep (any rubric for the branch marks it)"

**Location:** `workflows/review-fix-loop.md:63`; commit 1a118c80 body; rubric F1
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the loop doc's precedence paragraph and pr-prep step 1a's text at 1a118c80; does not establish how an agent re-entering pr-prep actually orders its reading.

The loop doc says it (`:63`): "Step 1a's /away split covers only a unit that no review loop has run on yet. A unit that grew under review stays under this stop when it re-enters pr-prep … any rubric for the branch, open or closed, shows that a loop has run." Step 1a itself is unchanged and unqualified (`workflows/pr-prep.md:96`): "In /away mode, split without asking and record the split as an interim". Its only link to the re-check sits in another sentence, about re-counting ("the review-fix loop re-runs the same count after each iteration and before merge, and tolerates growth to ~800 lines ([size re-check](…))"). That link does not say step 1a's split is limited. Security M1's path is an agent re-entering pr-prep at step 1a, and that agent reads an unconditional instruction there. The limit is stated only in another doc's last paragraph. A clause at the step 1a /away sentence ("for a unit no review loop has run on; see § Size re-check") would close it. The link alone does not.

A second gap, also paraphrased (no quote available because it comes from an absence across two sections): the new sentence takes step 1a's /away split away from *every* unit a loop has run on, not only units past the limit. A unit that grew to, say, 600 lines under review and re-enters pr-prep is over step 1a's 400 cap ("must split"). It is also under the 800 limit, so "this stop" does not apply. Neither doc says what an /away agent does with it. The security recommendation scoped the qualifier to units past 800.

**Evidence:** `workflows/review-fix-loop.md:63`, `workflows/pr-prep.md:96`, `docs/reviews/security-review-2026-10-15-fix-q160-iteration-cap.md:33-46`

---

## Claim 7: F15: iteration-4 gate "otherwise (no separable parts, or past that limit), the default is `escalate`"

**Location:** `workflows/review-fix-loop.md:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gate's /away default and its consistency with the precedence paragraph (`:63`); does not cover the /active path.

`:84`: "`split` is the default when the unit has separable parts and is within the [size re-check]'s limit (~800 lines, or a waiver's) …; otherwise (no separable parts, or past that limit), the default is `escalate`." This agrees with `:63`: "not by the iteration-4 gate's /away default `split`".

**Evidence:** `workflows/review-fix-loop.md:63`, `:84`

---

## Claim 8: F6 / commit body: "every restatement says \"~800 or a waiver's limit\""

**Location:** commit 1a118c80 body; rubric F6
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every "800" in `workflows/`, `guides/`, `skills/` at 1a118c80; does not cover decision log row 62, which states Q-104's figure and names waiver limits as Q-160's reading.

`rg -n "800" workflows guides skills` (cwd `/workspace/.claude/wt-q160`, exit 0, 2026-10-15) lists the size-rule sites. Those at pr-prep 3c `:244`, 6c `:458`, the criteria `:287` and `:467`, quick-ref `:53`, completion-signals `:82`, chat-synthesis `:128`, the early split `:53` and the gate `:84` all name the waiver's limit. One does not: step 1a, `workflows/pr-prep.md:96`: "the review-fix loop re-runs the same count after each iteration and before merge, and tolerates growth to ~800 lines". The api N1 list behind F6 did not name `:96`, so the fix did not reach it. "Every" is therefore one site too strong.

**Evidence:** `workflows/pr-prep.md:96`, `:244`, `:287`, `:458`, `:467`; `guides/pr-prep-quick-ref.md:53`; `guides/completion-signals.md:82`; `skills/code-review/references/chat-synthesis.md:128`

---

## Claim 9: pr-prep 3c and 6c restatements

**Location:** `workflows/pr-prep.md:244`, `:458`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that 6c is no longer unbounded after a waiver; does not cover the GitHub-path post-6c re-run (stated only in the loop doc, Claim 2).

`:244`: "Past ~800 lines (or the limit a waiver set), stop and ask the user for a waiver". `:458`: "past ~800 lines, or past the limit a waiver set, do not publish or merge." The old 6c wording, "with no waiver from the user", is gone.

**Evidence:** `workflows/pr-prep.md:244`, `:458`

---

## Claim 10: F12: step 3 criterion "(the before-merge run is step 6c's) … or within a waiver's limit, (…), OR the user waived it and the PR description records the waiver"

**Location:** `workflows/pr-prep.md:287`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the criterion's wording against the loop doc's waiver-record rule (`review-fix-loop.md:61`); does not cover the 6c criterion at `:467` (unchanged in this commit).

F12's pointer to 6c is in place. The new first disjunct, "the unit is at most 800 changed code lines, or within a waiver's limit, (step 1a's command, …)", now admits a waived unit *without* the record that the second disjunct, "OR the user waived it and the PR description records the waiver with its `Q-NNN` entry and the limit it grants", requires. A unit within a waiver's limit with no PR-description record passes the checkbox. Before this commit, a waived unit could pass only through the record branch. The owner (`review-fix-loop.md:61`) still requires the record, so the criterion is looser than the rule it checks. There is also a stray comma before the parenthesis.

**Evidence:** `workflows/pr-prep.md:287`, `workflows/review-fix-loop.md:61`

---

## Claim 11: quick-ref and completion-signals restatements (F6, F9)

**Location:** `guides/pr-prep-quick-ref.md:53`, `guides/completion-signals.md:82`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers both guide lines' agreement with the owner; does not cover other completion-signals checklist items.

Quick-ref is correct: "growth to 800 lines (or the limit a waiver set) is tolerated". Completion-signals fixes F9 ("after each iteration and before merge, or within a waiver's limit"). Its tail now reads "…, with the waiver cited by its `Q-NNN` entry?". The old "or does the description cite the user's waiver" made a waiver one of two alternatives. The new text reads as if a waiver always exists, which is ambiguous for the common no-waiver case.

**Evidence:** `guides/pr-prep-quick-ref.md:53`, `guides/completion-signals.md:82`

---

## Claim 12: chat-synthesis: "On every pass, the review-fix loop's size re-check … comes before this ladder"

**Location:** `skills/code-review/references/chat-synthesis.md:128`
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the sentence against the loop doc's schedule for the re-check; does not establish how often a first-review unit exceeds 800 in practice (step 1a should split it first).

The F3 move is done: the override sentence now sits before rule 1, "past its limit (~800 lines, or a waiver's), the loop stops for the user's waiver, and no next action below, `merge` included, overrides that stop". But "On every pass" includes the first review. The loop doc runs the re-check only "after each iteration's fix commits and tests (pr-prep 3c) … and once more at pr-prep 6c" (`review-fix-loop.md:57`), never before the first pass's ladder. Before this commit, the loop doc gave the first pass to step 1a: "(A unit already past 800 at entry falls under step 1a, which splits it in /away mode.)" This commit removes that sentence (diff of `review-fix-loop.md`, old `:172`). An entry-waived unit at 900 with a 🔴 on its first review now gets a stop from this sentence. The loop doc schedules no re-check at that point, and the owner section no longer says which rule governs. The sentence is not wrong after the first iteration. The overreach is "every".

The ladder still has exactly five numbered actions: 1 block on architectural review, 2 split PR, 3 escalate to /pre-mortem, 4 fix red items then re-review, 5 merge (`chat-synthesis.md:130-163`). Rule 2's "Rule 2 does not apply on later passes …, where growth falls under the size re-check (above)" agrees with the new sentence.

**Evidence:** `skills/code-review/references/chat-synthesis.md:128-163`, `workflows/review-fix-loop.md:57`, `:63`

---

## Claim 13: F11: rule 2 "no canonical rubric for the branch before this pass, or the newest one is closed: the first-pass test in code-review's SKILL.md Step 1"

**Location:** `skills/code-review/references/chat-synthesis.md:140-142`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the wording against `skills/code-review/SKILL.md` Step 1 (`:111-129`) and short-circuit mechanic 6 (`:735-745`); does not cover callers of rule 2.

The wording rule 2 now uses comes almost verbatim from the First-red short-circuit's mechanic 6 (`SKILL.md:739`), not from Step 1: "If no canonical rubric exists yet, or the newest one is closed (`Loop closed at`; the first pass of a loop)". Step 1 states the same test in other words (`:121-123`): "If that file carries a `Loop closed at <sha>` line …, the previous loop has ended and this pass starts a new one". The cited test is equivalent, so the commit's claim that the wording is "SKILL.md Step 1's" is right in substance but points to the wrong place. One part is still missing: mechanic 6's unreadable-history case (`:740-742`): "If rubrics for this branch exist but none has the canonical name, or HEAD is detached, the loop's history cannot be read". Under rule 2's wording, a branch with only non-canonical rubrics counts as a first review. Final-pass r3 flagged this and it was not addressed.

**Evidence:** `skills/code-review/SKILL.md:111-129`, `:735-745`; `skills/code-review/references/chat-synthesis.md:140-147`

---

## Claim 14: F3: "rule 2 needs neither waiver"

**Location:** `skills/code-review/references/chat-synthesis.md:144-145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers rule 2's waiver condition; does not cover the fall-through text ("A waived unit with a 🔴 falls through"), which agrees with it.

`:144-145`: "the user has waived neither the cap nor the size re-check for this unit". A re-check waiver now stops rule 2, as security finding 3 recommended.

**Evidence:** `skills/code-review/references/chat-synthesis.md:144-146`

---

## Claim 15: Row 62's new amendment wording about Q-104 [1]/[2]

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthetical and "waiver limits" against Q-104's archive entry and the loop doc; does not re-check the row's growth figures (Verified in the final pass).

"growth up to ~800 lines is tolerated, and past 800 the loop stops until the user answers a waiver entry (Q-104 [2])" matches the archive's answer note: "Growth up to ~800 lines is tolerated; past that the loop stops and asks for a waiver." The [1]/[2] parenthetical matches (Claim 4). "waiver limits" is listed as Q-160's reading, which agrees with `review-fix-loop.md:65`.

**Evidence:** `docs/decisions/log.md:85`, `docs/working/questions-archive.md` ### Q-104

---

## Claim 16: Plan refresh (F17)

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:20`, `:30`, `:36-37`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three changed plan lines against HEAD and the archive; does not verify "the caller's brief lists skills/dev-cycle/ as gate code" (the brief is outside the repo).

`:20` quotes Q-113 as "417 \"after the Q-112 fixes\"", and the archive (`questions-archive.md:1934`) has "~417 changed code lines after the Q-112 fixes". `:36-37` now describe the shipped section: heading, 3c/6c, `BASE` as in step 1a, counts in commit bodies, limit "~800 or a waiver's". `:30` no longer calls dev-cycle gate code by the regex. `rg -n "skills/dev-cycle" hooks/live-verify-gate.sh` returns nothing.

**Evidence:** `docs/working/plan-2026-10-15-q160-size-recheck.md:20-37`, `docs/working/questions-archive.md:1934`

---

## Claim 17: New override row (F2): "The exclusion is step 1a's, decided in Q-085 (override row 144)"; location `workflows/pr-prep.md:89-92`

**Location:** `docs/reviews/override-log.md:832`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the row's citations; does not judge the Won't-Fix.

The location holds: `pr-prep.md:89-92` spans the count block, including `git diff --numstat "$BASE"...HEAD -- ':(top)' ':(top,exclude)docs/'`. Override-log line 144 is the `review/q085` row "Excluding all of `docs/` from the size gate …" (Won't-Fix). But the user did not decide the exclusion in Q-085. Option [3], the one chosen, reads only "~400 code lines, every unit", and only option [1] said "reviews and docs excluded from the count". Row 62 itself calls the exclusion the "agent's reading of \"code lines\"" (`log.md:85`). Precise version: "the exclusion is step 1a's, set when Q-085 [3] was implemented (agent's reading, row 62; review row 144)." The row's conclusion, that changing it is a row-62 decision, stands.

**Evidence:** `docs/reviews/override-log.md:144`, `:832`; `docs/working/questions-archive.md` ### Q-085; `docs/decisions/log.md:85`; `workflows/pr-prep.md:89-92`

---

## Claim 18: Reworded override row (F18): "no script or test checks the `Size:` count lines"

**Location:** `docs/reviews/override-log.md:829`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reference to the current count format; does not re-verify the absence of a script.

The row now names the `Size:` lines, which matches `review-fix-loop.md:57` ("`Size: <count> code lines against <BASE>`"). The retired `Size after iteration N` name is gone from the row.

**Evidence:** `docs/reviews/override-log.md:829`, `workflows/review-fix-loop.md:57`

---

## Claim 19: Rubric "Iteration 3" figures

**Location:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:76`, `:9`, `:56`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size count and the per-report tallies; does not re-tier the findings (tiering belongs to the orchestrator).

Command `git diff --numstat "main...7d61c39b" -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` (cwd `/workspace/.claude/wt-q160`, exit 0, 2026-10-15) printed `50`. The rubric says "Size after iteration 2's fixes: 50 code lines against main". The merged fact-check header reads "0 Incorrect, 3 Stale, 10 Mostly accurate, 1 Unverifiable". The security report has two `**Severity:** Medium` and one Informational, performance has one Medium and one Low, and the api final report has N1/N2 Minor and N3/N4 Informational. All match `:76`. F8's rewording (`:9` "Entry size (step 1a)", `:56` "Size after iteration 1's fixes") drops the exact `Size after iteration N` shape.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:9`, `:56`, `:76`; `docs/reviews/code-fact-check-report-q160-final.md:8`; `docs/reviews/security-review-2026-10-15-fix-q160-iteration-cap.md:35,50,63`; `docs/reviews/performance-review-2026-10-15-fix-q160-iteration-cap.md:21,38`; `docs/reviews/api-consistency-review-2026-10-15-fix-q160-iteration-cap-final.md:40,59,80,98`

---

## Claim 20: Commit body: "Size: 50 code lines against main." and "F20: Q-160's entry is only on chore/dev-cycle-2026-10-15-0357"

**Location:** commit 1a118c80 message
**Type:** Configuration / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size count at 1a118c80 and where Q-160's entry lives; does not cover the body's per-finding claims (Claims 1-18).

The size holds. The same command against `main...1a118c80` printed `50` (exit 0). The merge base is `b279a2ba`, which is main's tip. For Q-160: `git grep -c "Q-160" main -- docs/working/questions.md docs/working/questions-archive.md` exited 1, so the entry is not on main. `git branch -a --contains 63af3551` printed `chore/dev-cycle-2026-10-15-0357`, `merge/build-loop-u5-resolved` and `merge/u5-and-q145`, and the last is not an ancestor of main (`merge-base --is-ancestor` exit 1). "only on chore/…" leaves out two unmerged merge branches that carry the same commit. The practical point holds: landing the chore branch brings the entry. The body's other claims (F1-F18 handled, F2 Won't-Fix, k=1 narrow pass) match the diff, except where Claims 6, 8, 10, 12, 13 and 17 above qualify them.

**Evidence:** commit `1a118c80`; `docs/working/questions.md`; branches listed above

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 6** (`workflows/pr-prep.md:96`, `workflows/review-fix-loop.md:63`): step 1a's own "/away, split without asking" is still unqualified. Add the "no review loop has run on it" qualifier (or a link) at that sentence. Also, a re-entering unit between 400 and 800 now has no defined /away action.
- **Claim 8** (`workflows/pr-prep.md:96`): step 1a's "tolerates growth to ~800 lines" leaves out the waiver's limit, so "every restatement" is one site short.
- **Claim 10** (`workflows/pr-prep.md:287`): "or within a waiver's limit" lets a waived unit pass without the PR-description record. Fold it into the OR branch, and remove the stray comma.
- **Claim 11** (`guides/completion-signals.md:82`): "with the waiver cited" reads as if a waiver always exists.
- **Claim 12** (`chat-synthesis.md:128`): "On every pass" includes the first review, which the loop doc does not re-check, and the removed parenthetical leaves no rule for a unit already past 800 at its first pass. Say "on loop passes after the first", or restore the entry case.
- **Claim 13** (`chat-synthesis.md:140-142`): the wording is mechanic 6's (`SKILL.md:739`) but is cited as Step 1, and the unreadable-history case is still missing.
- **Claim 17** (`override-log.md:832`): the user did not decide the `docs/` exclusion in Q-085. Row 62 calls it the agent's reading.
- **Claim 20** (commit body): Q-160's entry is also on two unmerged `merge/` branches. Not on main is the part that matters, and that holds.
