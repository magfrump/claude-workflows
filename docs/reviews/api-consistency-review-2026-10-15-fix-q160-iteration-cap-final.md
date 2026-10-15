Commit: 7d61c39b

# API Consistency Review — fix/q160-iteration-cap (final confirming pass)

**Scope:** `git diff main...HEAD` (HEAD 7d61c39b), full branch: `workflows/review-fix-loop.md`, `workflows/pr-prep.md`, `guides/pr-prep-quick-ref.md`, `guides/completion-signals.md`, `skills/code-review/references/chat-synthesis.md`, `docs/decisions/log.md` row 62, `docs/reviews/override-log.md`, branch review artifacts
**Date:** 2026-10-15
**Based on:** the merged k=3 final fact-check summarized in the critic brief (no Incorrect). Its non-Verified clusters are not re-filed here. Prior report: `docs/reviews/api-consistency-review-2026-10-15-fix-q160-iteration-cap.md` (at 57f4c871, F1-F8).

## Baseline Conventions

These are the same as in the iteration-2 report. Each rule has one owner and the other docs link to it. A threshold is written "~N" and the gate fires "above N", with "≤ N" in checklists. Control-rule headings carry a parenthetical saying when the rule runs. A waiver is cited by `Q-NNN` with the answer quoted verbatim. Decision-log amendments go in the Rationale column. `rubric.md` pins the rubric file format. One baseline is new this pass: commit bodies already carry `Key: value` lines (`Confidence:`, `Notes:`; global CLAUDE.md "Autonomous Commit Format", pr-prep 1a's "commit body's `Notes:` line"). The new `Size:` line joins that set.

## Prior findings: status

| # | Prior finding | Status at 7d61c39b | Evidence |
|---|---|---|---|
| F1 | `Size after iteration N` rubric line outside rubric.md's format | **Held.** The count moved to a `Size:` line in commit bodies, so rubric.md's pinned format is untouched. Two `Size after iteration` lines are left in the branch rubric as history (N3). | review-fix-loop.md:57: "Note each count in the body of the commit that follows it (`Size: <count> code lines against <BASE>`), so the growth stays in `git log`." 7d61c39b body: "Size: 50 code lines against main." |
| F2 | No bound stated after a re-check waiver | **Held in the owner.** Some restatements still hard-code 800 (N1). | review-fix-loop.md:61: "A granted waiver sets the limit the re-check uses from then on: the one its answer names, or, when it names none, the count the entry asked about, so any further growth asks again." |
| F3 | "Before merge" vs 6c; 6c criterion missing the check | **Held.** The wording now names publish time, with merge time on the local path, and 6c gained a criterion. The GitHub post-publish gap is a fact-check cluster, so it is not re-filed. | review-fix-loop.md:57: "once more at pr-prep 6c, before the description is published (on the local-merge path, before the merge)"; pr-prep.md:467: "- [ ] The final size re-check ran before publishing (or merging): at most 800 code lines, or within a cited waiver's limit" |
| F4 | Waiver-citation wording drift | **Held.** | quick-ref:53: "note a granted waiver in the PR description, citing that `Q-NNN`"; completion-signals:82: "cite the user's waiver by its `Q-NNN` entry"; review-fix-loop.md:61: "with the user's answer quoted verbatim and saying whether it waives the entry gate or this re-check" |
| F5 | Heading omits the before-merge run | **Held.** The heading is renamed. All five pr-prep links use the new anchor `#size-re-check-after-any-iteration-and-before-merge`, and none still uses the old one (grep). chat-synthesis cites "§ Size re-check" without an anchor, which still resolves. | review-fix-loop.md:55: "### Size re-check (after any iteration and before merge)" |
| F6 | Row 62 amendment in the Decision column | **Held.** The amendment is now in column 4 (Rationale), matching rows 53 and 60. | log.md:85 Rationale cell: "**Amended 2026-10-15 (Q-104 [2], Q-160):** the cap is re-checked inside the review-fix loop too." |
| F7 | completion-signals dropped "outside `docs/`" | **Mostly held.** "outside `docs/`" is restored. "after review fixes" remains (N4). | completion-signals:82: "(≤ 800 changed code lines outside `docs/` after review fixes)" |
| F8 | 3c re-check vs drift check order | **Held.** | pr-prep.md:244: "After the tests, before the drift check below and the re-review, re-run step 1a's count."; review-fix-loop.md:59: "no further fix commits, drift check, re-review or merge" |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `### Size re-check (after any iteration and before merge)` | rule heading | `### Early split trigger (after any iteration)`, `### Iteration 4: cap-exceeded decision gate` | `workflows/review-fix-loop.md:49,73` | Consistent. The parenthetical now gives the rule's full timing, like its sibling. |
| `Size: <count> code lines against <BASE>` | commit-body line | `Confidence: high\|medium\|low`, `Notes: ...` | global CLAUDE.md "Autonomous Commit Format"; `workflows/pr-prep.md:96` ("commit body's `Notes:` line") | Consistent `Key: value` shape. Its placement rule has gaps (N2). |
| "limit" (the waiver's granted limit) | term | "cap" (step 1a), "~800 tolerance" | `workflows/pr-prep.md:84`; `workflows/review-fix-loop.md:57-61` | Consistent. "limit" is used for the waiver-set bound in review-fix-loop:59,61, pr-prep:287 ("the limit it grants") and pr-prep:467 ("a cited waiver's limit"). |
| `~800` / "above 800" / "≤ 800" | threshold | `~400` / "above 400" / "≤ 400" | `workflows/pr-prep.md:84,96` | Consistent with step 1a. |
| "first review" (chat-synthesis rule 2) | term | code-review SKILL.md's first-pass test | `skills/code-review/SKILL.md` (First-red short-circuit) | Links to its owner. The loose paraphrase is a fact-check cluster and is not re-filed. |

## Findings

#### N1. After a waiver, five restatements still name 800 as the stop point, while the owner says the waiver's limit

**Severity:** Minor
**Location:** `workflows/pr-prep.md:244`, `:458`; `guides/pr-prep-quick-ref.md:53`; `guides/completion-signals.md:82`; `skills/code-review/references/chat-synthesis.md:147-150`
**Move:** 3 (consumer contract), 2 (terminology)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
- review-fix-loop.md:61 (owner): "A granted waiver sets the limit the re-check uses from then on: the one its answer names, or, when it names none, the count the entry asked about"
- pr-prep.md:244: "Past ~800 lines, stop and ask the user for a waiver"
- pr-prep.md:458: "past ~800 lines with no waiver from the user, do not publish or merge"
- quick-ref:53: "growth to 800 lines is tolerated; past it, stop and ask the user for a waiver"
- by contrast, pr-prep.md:287: "OR the user waived it and the PR description records the waiver with its `Q-NNN` entry and the limit it grants"; pr-prep.md:467: "or within a cited waiver's limit"

The owner now defines a moving limit. Two of the restatements (pr-prep:287 and :467) carry it, but the per-iteration instruction an agent actually executes (3c), 6c's prose and the quick-ref bullet still say 800. Take a waiver granted at 842. At 850, 3c and the quick-ref say "past 800, stop and ask". By the owner's rule that is right, since 850 is past 842, but only by coincidence of the wording. Now take a waiver whose answer names 1,000. At 900, 3c and the quick-ref say stop, while the owner says continue. 6c's "with no waiver" goes the other way: read literally, any waiver at all lets the unit publish whatever its size, while the owner bounds it by the limit. The brief's fact-check cluster names this gap only for the precedence paragraph ("past 800" not "past the current limit"). The same wording sits in four more docs that link to the owner.

**Recommendation:** Replace "800" in the restatements with "~800 (or the limit a granted waiver set)". For 6c, change "with no waiver from the user" to "beyond ~800 or a cited waiver's limit", matching its own criterion at :467. One phrase per site.

#### N2. The `Size:` line has no home for counts that no commit follows, including the count that triggers the stop

**Severity:** Minor
**Location:** `workflows/review-fix-loop.md:57`, `:59`
**Move:** 3 (consumer contract), 8 (an undefined state)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
- review-fix-loop.md:57: "Note each count in the body of the commit that follows it (`Size: <count> code lines against <BASE>`), so the growth stays in `git log`."
- review-fix-loop.md:59: "Past 800, the loop stops on this unit: no further fix commits, drift check, re-review or merge until the user answers a waiver entry"

The rule places each count in the "commit that follows it". In three states no commit follows, or none follows soon:
- The over-limit count, which is the one the audit trail most needs, stops all fix commits. Until the waiver is answered it is recorded only in the questions.md entry, if at all.
- An iteration that ends clean with no fix commits.
- 6c on the GitHub path, which runs at publish time with no merge commit of the agent's own. On the local path the merge commit is the following commit, so that case is fine.

With no placement rule for these states, agents will diverge: some will write an empty commit, some will put it in the waiver entry, some will drop it. The squash-folding risk to these lines is a separate fact-check cluster and is not re-filed here.

**Recommendation:** Add one clause: "if no commit follows (the loop stopped, or the pass made no fixes), put the count in the waiver entry or the PR description instead." Or say that the 6c count goes in the merge commit (local path) or the PR description (GitHub path).

#### N3. The branch rubric still carries two lines in the retired `Size after iteration N` shape

**Severity:** Informational
**Location:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:9`, `:56`
**Move:** 2 (naming), 3 (format contract)
**Confidence:** High
**Legibility-target:** for-author

Precedent: rubric header lines are `Commit:` plus the marker lines defined in `skills/code-review/references/rubric.md:17-27`. The size-count shape is now `Size: <count> code lines against <BASE>` in commit bodies (`workflows/review-fix-loop.md:57`).

Evidence:
- rubric:9 (between the header and the first iteration section): "Size after iteration 0 (entry, step 1a): 28 code lines against main."
- rubric:56: "Size after iteration 1: 41 code lines against main (step 1a's command)."

Since I1, nothing defines this line. Line 9 sits in the header region of a file whose format rubric.md pins. An agent copying the newest rubric as a template, which is what rubric.md's continuation rule asks for, could revive the retired shape. These are historical records, and the 7d61c39b commit body uses the new shape (with a trailing period the spec lacks, which is harmless). The stale override row at :829 is a fact-check cluster and is not re-filed.

**Recommendation:** Optional. Either leave them as iteration history, or drop line 9 (the iteration narrative at :56 is fine as prose) when the rubric is next updated for the final pass.

#### N4. completion-signals still says "after review fixes"

**Severity:** Informational
**Location:** `guides/completion-signals.md:82`
**Move:** 2 (terminology)
**Confidence:** High
**Legibility-target:** for-author

Precedent: the owner's timing words "after each iteration's fix commits and tests … and once more at pr-prep 6c", `workflows/review-fix-loop.md:57`, mirrored as "after each iteration and before merge" in `guides/pr-prep-quick-ref.md:53` and `workflows/pr-prep.md:287`

Evidence:
- completion-signals:82: "(≤ 800 changed code lines outside `docs/` after review fixes)"

The remainder of prior F7. Every other restatement uses "after each iteration and before merge". "After review fixes" is the only variant, and it can read as counting only the fixes. It does not change behaviour.

**Recommendation:** Optional: "re-counted after each iteration and before merge".

## What Looks Good

- **All eight prior findings were addressed**, six of them fully. The fixes went to the owning doc and the links were updated in the same commit. The anchor rename was carried to every pr-prep link, and none still uses the old anchor.
- **Moving the count out of the rubric (I1)** removed the cross-skill contract break rather than widening rubric.md's pinned format. That was the lower-coupling option.
- **`Size:` matches the existing `Confidence:`/`Notes:` commit-body convention**, so it can be found with the same `git log --grep` habit.
- **"limit" is used the same way** in review-fix-loop, pr-prep's step 3 criterion and 6c's criterion. The waiver's citation now says which gate it waives (entry vs re-check), so two waivers on one unit can be told apart.
- **Row 62's amendment** is in the Rationale column with the `**Amended YYYY-MM-DD (Q-NNN …):**` shape, matching rows 53 and 60, and the replaced revisit trigger is restated explicitly.
- **chat-synthesis rule 2** links to the loop's re-check instead of restating its numbers in full, and says plainly that no next action overrides the stop.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| N1 | 3c, 6c prose, quick-ref, completion-signals and chat-synthesis still name 800 as the stop point after a waiver; the owner uses the waiver's limit; 6c's "with no waiver" has no bound | Minor | `workflows/pr-prep.md:244,458`; `guides/pr-prep-quick-ref.md:53` | Medium |
| N2 | `Size:` goes in "the commit that follows", but the stop count, a no-fix pass and GitHub-path 6c have no following commit | Minor | `workflows/review-fix-loop.md:57,59` | Medium |
| N3 | The branch rubric keeps two lines in the retired `Size after iteration N` shape, one in the header region | Informational | `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:9,56` | High |
| N4 | completion-signals' "after review fixes" differs from "after each iteration and before merge" | Informational | `guides/completion-signals.md:82` | High |

## Overall Assessment

The iteration-2 fixes held. F1-F6 and F8 are resolved, and F7 is resolved apart from one phrase. The branch is now consistent with the repo's conventions: one owner with links to it, the "~N / above N / ≤ N" threshold pattern, the heading parenthetical, the waiver citation by `Q-NNN`, the amendment column and the commit-body `Key:` lines. Nothing breaks an existing consumer, and nothing here is above Minor. The one gap worth a phrase-level fix before merge is N1. The waiver-limit rule added in I2 reached the owner and the two checklists, but not the per-iteration instruction agents actually follow (3c), 6c's prose or the quick-ref. An agent reading only those would apply 800 after a waiver that named a different limit. N2 is a small placement gap for the size line, and N3 and N4 are cosmetic. All are fixable in place without re-surveying conventions.

## Goal-Alignment Note

The branch's goal is to write Q-104 [2] into the process: re-measure after each iteration, tolerate about 800 lines, and stop for a waiver past that, in /away mode too. The cross-document contract now serves that goal. Every doc that mentions the re-check uses the same name, links to the same owner, and states the same strict 800 bound. N1 is the only finding that touches the goal directly. If the restatements are not aligned with the owner's moving limit, an agent following 3c could stop at 800 after the user granted more, or (via 6c's "with no waiver") publish past a granted limit. The second case is the ballooning-under-waiver failure this branch was built to prevent. I found nothing material beyond that.
