# Research: close the review rules' written gaps

Date: 2026-11-14 · Brief: `docs/working/briefs/2026-11-14-review-rules-close-gaps.md` (at fce8af4a) · Branch: `docs/review-rules-close-gaps` · Base: fce8af4a

## Question

Where does each of the brief's seven rules go so that it is read at the moment it applies (S4), stays short, adds nothing to always-loaded context (S2), and is stated once (S3)?

## What I read

- `workflows/review-fix-loop.md`: owns the exit conditions, the cap and its `escalate | split | abandon` gate, the early split trigger and the size re-check. Its header says pr-prep Step 3 owns the step sequence and when override rows are written, and code-review owns tiers and the override-log format.
- `workflows/pr-prep.md`: the local-merge bullet ("Merge locally: `git merge --no-ff`") has no word on integration branches; Step 3b says to commit fixes "referencing finding IDs" but not to update the rubric; Step 3d.2 marks prior findings "resolved or still-open" without saying where; "Capturing overrides" calls a waived Must Fix "rare enough to feel wrong" but names no authority; Step 7 is all optional.
- `skills/code-review/references/rubric.md`: owns the rubric template, file lifecycle (new file on a new date or branch), the qualifying author note, the immutable-history exception and the status line. `SKILL.md`'s Deliverable 2 section only points here, so "SKILL.md's rubric format" in the brief's criterion 9 is this file.
- `skills/code-review/references/override-log.md`: `Accepted-immutable` rows are machine-written into `docs/reviews/override-log.md`.
- `test/skills/code-review-format-contract.bats`: compares the template's table headers and `##` headings against the golden fixture, and requires every R/A/C row to carry `🔴|🟡|🟢` + `Unresolved|Open|Fixed|Won't-Fix|Deferred`. Text outside the template's code fence is not pinned.
- The audit (`docs/working/research-2026-11-13-review-gap-audit.md`), its landings 1-4 and the U2a2 D1 red; the sibling brief `docs/working/briefs/2026-11-14-merge-rubric-gate.md` (it parses Status columns; the written words are this brief's).
- Status words actually used in the October-November rubrics (first word of the 🔴/🟡 Status cell): Fixed 494, Open 49, Acknowledged 24, Accepted-immutable 10, Deferred/Defer 14, Resolved 10, Split 5, Won't-Fix 3, and a long tail (Stands, Interim, Corrected, Partly, Documented, Routed, Superseding, Covered...). The list below keeps the common words and gives each tail case one of them.

## Invariants

- The golden fixture and template headings/headers stay in sync; the template's example Status values stay inside the regex above. Nothing here changes the template's fence, so the fixture is untouched.
- Each rule has one owner: loop control in review-fix-loop.md, step actions in pr-prep.md, format and vocabulary in rubric.md.
- No gate code (`scripts/`, `skills/dev-cycle/`): the sibling brief owns it.

## Design notes

### D1: the self-merge route for an immutable-history finding (criterion 7), divergent design

Problem: on a self-merge brief, `docs/reviews/override-log.md` is on the build-loop floor, so the rubric.md exception ("append an `Accepted-immutable` row") cannot be followed, and landing 4 (b0ebed19) left three rows reading "🟡 Stands (immutable)".

Constraints: H1 and the out-of-scope line (no gate or floor change here), S3 (one record per rule), S10 (no new chore), criterion 9 (a parser can read it).

| Option | What it means | H1 / scope | Parser-readable | Cost |
|---|---|---|---|---|
| A. Rubric row is the record | Status cell `Accepted-immutable`, Author note starts `[auto: code-review]` naming the artifact | no gate change | yes, a status word | none |
| B. Let the branch append to the log | Floor exception for `Accepted-immutable` rows | gate code: out of scope | yes | a floor carve-out a same-uid slip could misuse |
| C. Research doc records it (status quo) | What b0ebed19 did | fine | no: the rubric still reads open | audit noise forever |
| D. Marker body / merge message | Say it at landing | fine | only if the gate reads messages | restates per landing |

Path A: option A dominates (it is the only one that is in scope, needs no new mechanism and leaves the rubric reading closed). 10 recent rows already use the word. Residual risk: a later run's Step 3.5 reads only the log, so it could re-raise the same immutable claim; the claim is in an already-merged message no later branch diff contains, so this is unlikely, and it would close the same way.

### Other choices (fewer than 3 viable options)

- **Where the vocabulary lives:** `references/rubric.md`, which owns the format; SKILL.md gets a pointer. A new file would split the format's owner (S3).
- **Carried-forward table in the template, or a conditional section:** conditional (only when an earlier rubric file for the branch leaves rows open). In the template it would need a "No prior rubric" line in every rubric and a golden fixture change for a case most rubrics never hit.
- **Remedy when the landing check finds a fast-forward:** an empty commit on `main` carrying the missing message. The other option, moving `main` back and re-merging, is a history rewrite the global rules put behind the user's approval.
- **Where "review before landing" lives:** rubric.md, since a review of code already on `main` runs code-review without pr-prep or the loop; pr-prep's "When to use" gets one pointer line.
- **Split follow-ups in a build loop:** a build loop cannot write the questions file or the roadmap, so its follow-up goes in the marker body for the cycle to file. The early split trigger and the size re-check each get the same parenthetical where they say to record the split in questions.md.
- **Escalate and the "no new human stops" memory:** `escalate` already hands the loop to a human and is the default only when no split exists; the rule adds a record of the wait, not a new wait.
- **Build-loop merges:** the Step 7 landing check covers merges run by pr-prep's local-merge path. A build-loop self-merge writes its own merge commit; what its message holds is the sibling gate brief's business.

## Plan

1. review-fix-loop.md: a superseding-loop paragraph by the per-loop counter rule; exit 2 needs a filled Author note on every open 🟡 and an owner Q-ID on any red not fixed; `escalate` files a question entry or blocked marker before any merge; every split files its follow-up.
2. pr-prep.md: the local-merge bullet covers integration branches; Step 3b fix commits update their rows; 3d.2 marks status in the rubric by ID; a waived red needs the owner's Q-ID; a required landing check opens Step 7; "When to use" points to the review-after-landing rule.
3. rubric.md: Status words, Carried forward table, Review of code already on main, the self-merge route in the immutable-history exception, a pointer from the status line and the new-file paragraph.
4. override-log.md and SKILL.md: one pointer each.
5. Tests: no test pins the edited lines outside the template fence (searched `test/` for each edited sentence); run the code-review format contract and workflow section tests, then the confined suite per the brief.

## Review

Docs-only diff, so a single read-only reviewer ran a combined fact-check and consistency review against the brief (no code critics).

- **Iteration 1 of 3** (at de08ed8d, full scope): 1 Must Fix, 8 Must Address, 4 Consider. All fixed in the next commit:
  - F1, the f6dc3f15 wording: four loop-1 rows were dropped, and the merge's "6 amber carried" named none, so "never accounted for" overstated it;
  - MA1, the landing check: `main^2` exists after a fast-forward of a merge-tipped integration branch. It now compares `main^1` with `ORIG_HEAD` and `main^2` with the branch tip. A hermetic probe in the scratchpad showed a `--no-ff` merge passing and a fast-forward of a merge-tipped `answers` branch failing. The record commit counts as passing;
  - MA2, emoji placement ("after any leading emoji"), plus a note that the format contract test pins only the template's subset; MA8, legacy `Resolved` and `Defer` mapped;
  - MA3, the early split trigger and size re-check now route a build loop's split record to its marker body; MA4, the escalate entry follows the questions-doc grammar and links the summary;
  - MA5, a red needs the owner's Q-ID: an override-log row or trigger alone does not close one. The sibling gate brief (`docs/working/briefs/2026-11-14-merge-rubric-gate.md`, criterion 2) accepts either, which would re-admit U2a2 D1. That is relayed in the marker for the cycle, since this brief cannot edit another;
  - MA6, `Accepted-immutable` is a 🟡 row; MA7, the new sections moved after the Legibility-target paragraph;
  - C1, SKILL.md's Step 3.5 pointer; C2, a self-merge deferral keeps its Reason in the Author note; C3, "eight known-issue rows"; C4, the landing check excludes build-loop merges.

## Gotchas

Failure-pattern grep: FP-064

- FP-064 (2026-07-29): an overwritten rubric destroyed prior findings, and the fix moved rubrics to date-stamped files. That fix is why a branch's open rows spread over several files, which the carried-forward table now closes.

Failure-pattern skip: no fix(...) commit on this branch fixes a code defect; the changes are review rules in docs, and their root cause is already recorded by the 2026-11-13 audit.
