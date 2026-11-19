Commit: 89eb9b65

# API Consistency Review — measure/a8-cache-probe, pass 2 (139aeedd)

**Scope:** `git diff f87a1455..139aeedd` (loop pass, delta range); 4363a15c, f87a1455 and 89eb9b65 context only. Public surface = the record contracts: rubric status words and status line (`skills/code-review/references/rubric.md`), `rubric_parse` (`scripts/lib/rubric-check.sh`, read by `build-loop.sh --check/--merge`), the token-ledger/manifest convention (`docs/working/review-canon.md:112-131`), the brief's file and scope limits.
**Date:** 2026-11-19
**Based on:** `docs/reviews/code-fact-check-report-2026-11-19-measure-a8-cache-probe-pass2.md` (k=1), its Escalation and Claims 2, 3b, 12, 16.

## Baseline Conventions

- **Status words** (`rubric.md:190-211`): a Status cell's first word is its class. `Open` = open, needs nothing. `Fixed` = fixed, carries the fixing commit. `Split` = "moved to another unit", must carry "the tracked follow-up (Q-ID, roadmap item or branch)" (`:204`). `Acknowledged` needs a qualifying author note, which is (a) a tracked follow-up the note links to or (b) a concrete revisit trigger (`:170-186`).
- **Review of code already on main** (`rubric.md:233-240`): "the commit that adds its rubric lands only after every open 🔴 and 🟡 row is routed: a question entry, a roadmap item or an override-log row, named in the row." The 2026-08-07 rubric reviews `main`, so this rule binds it.
- **Split inside a build loop** (`workflows/review-fix-loop.md:84`): the split-off part is filed "before the rest merges: a roadmap item or question entry, or in a build loop a line in the marker body for the cycle to file. Each split-off 🔴/🟡 row then reads `Split` and names that item." This is the existing route for a loop that may not edit the questions files or the roadmap.
- **Handoff marker** (`scripts/build-loop.sh:979-1000`): a tip commit whose subject starts `handoff:`, with no file changes. Its body is read by the cycle (`skills/dev-cycle/SKILL.md:733`).
- **Parser** (`scripts/lib/rubric-check.sh:65-71`, `:113-115`): "An amber, whatever its first word, closes on a qualifying author note ... found by keyword: a Q-ID ... Keyword presence is not a check that the reference exists or says what it should." `rubric_lines` (`:218-290`) reads every changed `docs/reviews/code-review-rubric-*.md`, newest per slug, and prints `clean` when no row parses `open`.
- **Ledger convention** (`review-canon.md:112-117`): "any run or sub-run that reports per-agent token figures MUST (a) append one row per agent to a `token-ledger.md` ... and (b) register the sub-run's agents and totals in the run's `manifest.json`". The amendment (`:124-131`) makes it unconditional for runs with a manifest. Its last clause, "A run that nonetheless finishes with empty `tokens` maps must state the omission explicitly in its results doc", is the fallback. The sibling results doc in the same run directory follows the main rule: `runs/review-arms/a8-2026-11-19/results.md:153` "No `tokens` map is empty: every agent's figure is in `manifest.json` and in `token-ledger.md`."

Evidence run (cwd the worktree, 2026-11-19, exit 0): `timeout 60 bash -c 'source scripts/lib/rubric-check.sh && rubric_parse docs/reviews/code-review-rubric-2026-08-07-main.md'` gives `row	amber	A8	closed	🟡 Open — measured 2026-11-19: the claim fails on its benefit. ...`, and every other red/amber row parses `fixed`. On `main` the same row's Status cell is the bare `🟡 Open` (no Q-ID), which classifies `open` (`:116`). The same parser on `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md` gives A1-A7 `fixed`, A8 `closed` (Accepted-immutable). So the gate would print `clean` for both rubrics this branch changes. Inferred from `rubric_lines`; I did not run `build-loop.sh --check` itself.

## Name-Pattern Audit

The diff adds no new public names. It uses existing status vocabulary and edits prose cells. The words it uses, checked against the canon:

| Word used | Where | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `🟡 Open` (A8) | `code-review-rubric-2026-08-07-main.md:35` | `Open`, `Split`, `Acknowledged` | `skills/code-review/references/rubric.md:199-204` | Consistent as a word. The parser contradicts it (Finding 2). |
| `🟡 CONDITIONAL PASS — 1 amber item awaiting resolution (...)` | `code-review-rubric-2026-08-07-main.md:4` | the template line `[N] amber item(s) awaiting resolution or justification` | `rubric.md:608`; `code-review-rubric-2026-11-19-measure-a8-cache-probe.md:5` | Near-consistent. Drops "or justification", which was inherited from `main` (Finding 6). |
| `✅ Fixed (139aeedd — ...)` (A1-A3) | `code-review-rubric-2026-11-19-measure-a8-cache-probe.md:26-28` | `Fixed` + commit | `rubric.md:200` | The form is consistent. For A1 the word is wrong (Finding 1). |

## Findings

#### 1. A1 is marked `✅ Fixed`, but its finding still stands, and its note points at a marker that does not exist

**Severity:** Inconsistent
**Location:** `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:26`; `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `docs/working/research-2026-11-19-a8-cache-probe.md:72-77`, `:83`
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

A1 found that "The text A8 was filed against, now measured false, is routed nowhere" and that this breaks "Review of code already on main" (`rubric.md:233-238`). 139aeedd changed the A8 word from `Split` to `🟡 Open`. That makes the row honest: it now says "Still open: ... no tracked item corrects them yet" (`code-review-rubric-2026-08-07-main.md:35`). It does not route anything. The main-review rule still requires every open 🟡 row to be "routed: a question entry, a roadmap item or an override-log row, named in the row", and A8 is still unrouted for the skill-text part. Only Q-308 is named, and Q-308 covers the settling runs.

A1's Status says "filing the skill-text correction is the cycle's, named in the hand-off marker". No marker exists: the branch tip 89eb9b65 has subject "docs(reviews): commit the cache-probe review pass ...", not `handoff:`. `rg -i marker` over the brief, the research doc and `runs/review-arms/a8-2026-11-19/` finds only `research-...:83` "3. Review-fix loop over the doc changes; brief Status line to done; marker.", which does not commit the marker body to carrying this item. The research doc's hand-off is only "it is for the cycle to file" (`:76-77`). The A8 cell does not name a marker either, so even after one is written, row A8 will not point at it. The `Fixed` therefore describes a future, unpromised artifact as present.

The canon already offers the route the author thought was closed. `workflows/review-fix-loop.md:84` lets a build loop file a split-off part as "a line in the marker body for the cycle to file", after which "Each split-off 🔴/🟡 row then reads `Split` and names that item". That route needs no edit to the questions files or the roadmap, so it fits the brief (`docs/working/briefs/2026-11-19-a8-cache-probe.md:32`).

**Recommendation:** Set A1 to `🟡 Open` until the route exists, or take the canon's route: (a) commit to a marker-body line naming the correction of `SKILL.md:274-277`, `:347-351` and `:352-354` (state that in the research doc's "Follow-up for the cycle"); (b) put A8 back to `Split` naming Q-308 and that marker line; (c) the 2026-08-07 status line can then return to the all-resolved form; (d) A1 then reads `Fixed` with the commit. Option (b) also makes Finding 2 moot, because the parser's `closed` becomes the right reading.

#### 2. The merge gate reads A8 as closed, so "Open" is not visible to it; this branch flips the gate from open to clean

**Severity:** Inconsistent
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `scripts/lib/rubric-check.sh:65-71`, `:113-115`
**Move:** 3 (consumer contract), 7 (asymmetry between the status word and the parser class)
**Confidence:** High (parser re-run); Medium for the gate line (inferred from `rubric_lines`, not executed)
**Legibility-target:** for-orchestrator-synthesis

I re-ran the parser and confirmed the fact-check escalation: `row	amber	A8	closed	🟡 Open — measured 2026-11-19 ...`. The cause is `:113-114`: `return ("closed", $qids) if $qids ne "-" || ...`, which applies to every amber whatever its first word. The cell names Q-306 ("merge approved Q-306") and Q-308 ("are Q-308's"). On `main` the cell was a bare `🟡 Open` and parsed `open`. With this branch, `rubric_lines` will print `clean ... none open` for the 2026-08-07 rubric, because it is a changed rubric with slug `main`. The status line meanwhile says "1 amber item awaiting resolution". The rubric's two consumers, the human-read status line/word and the gate, now disagree, and the disagreement was introduced by this branch's wording. The parser documents this as a known limit ("Keyword presence is not a check"), and the gate is advisory, so nothing breaks. But the open state reaches only someone who reads the cell. That is the gap A1 named ("The parser still reads the row as closed, so no gate catches it"), and 139aeedd did not close it.

**Recommendation:** Prefer Finding 1's `Split` route, which makes `closed` correct. If A8 stays Open, record in A8's Author note (or the research doc) that the gate reads the row as closed because of the cited Q-IDs, so the merge entry does not report it clean without comment. Do not strip the Q-IDs to fool the parser: that costs legibility for a cosmetic gain.

#### 3. The A3 fix states the omission, but its reason contradicts the canon it cites

**Severity:** Minor
**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:98-102`
**Move:** 1 (baseline), 3
**Confidence:** High
**Legibility-target:** for-author

The probe doc says: "These two agents are not rows in `token-ledger.md` or `manifest.json`: those record the A8 review pass, and the probe is a separate two-call measurement whose full per-agent record is the table above (the omission `docs/working/review-canon.md:131` asks a results doc to state)." The canon binds "any run **or sub-run** that reports per-agent token figures" (`review-canon.md:112-117`), and the amendment is "unconditional" for runs with a manifest (`:124-126`). The probe lives in that run directory and reports per-agent figures (`cache-probe.md:34`). So "a separate two-call measurement" is the case the convention covers, not an exemption from it. `:131` is the fallback for a run that "nonetheless finishes with empty `tokens` maps". The sibling `results.md:153` follows the main rule. The real reason is the brief's file list (`briefs/2026-11-19-a8-cache-probe.md:21`: "the probe doc, the rubric row, any skill change, and your research doc"), which the previous A3 named ("since the brief's file list omits them, state the omission explicitly"). So the fallback form conforms, but the stated reason would teach a reader that sub-runs are exempt. This agrees with fact-check Claim 16.

**Recommendation:** Reword to "The convention (`review-canon.md:112-117`) asks for ledger and manifest rows; the brief's file list does not include those files, so per its fallback (`:130-131`) the omission is stated here, and the table above is the full per-agent record."

#### 4. The A8 cell and the research doc state A7's cross-pass loss as measured; the probe doc and the A2 note say inferred

**Severity:** Minor
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `docs/working/research-2026-11-19-a8-cache-probe.md:74-76`; `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:27`
**Move:** 7 (asymmetry across citing records)
**Confidence:** High
**Legibility-target:** for-author

The probe doc labels the A7 consequence: "so by this mechanism it buys no cross-pass cache hit. That is inferred from the records, not measured." (`cache-probe.md:94-95`). The A8 cell drops the label: "A7's cross-pass claim (`:347-351`) now describe a saving that does not occur". The research doc says "its stable-parts-first rule claims cross-pass warmth (`:347-351`, rubric row A7); the probe shows that saving does not occur". A2's Fixed note says "cache-probe.md and A8's cell record the A7 implication, marked inferred". That holds for the probe doc only. Prior C4 asked for the follow-up to record it as inferred. Whoever files the correction will copy from the cell or the research doc, which are the less precise copies (FP-089 shape).

**Recommendation:** Add "(inferred, not measured)" after `:347-351` in the A8 cell and the research doc's Follow-up.

#### 5. The research doc's title still promises a "closing note" for a row it now keeps open

**Severity:** Minor
**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:1`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

"# Research: A8 cache probe and the closing note for rubric row A8" contradicts `:66` "So the row stays open until the cycle files the correction". This is fact-check Claim 12, made stale by 139aeedd. (The brief's own title "closing rubric row A8", `briefs/...:1`, is the owner's text and should stay as it is.)

**Recommendation:** Retitle to "... and the measured verdict for rubric row A8".

#### 6. Author note C2 is still a pending instruction, and beside an Open status it now reads as the reason the row is open

**Severity:** Minor
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35` (Author note cell)
**Move:** 7
**Confidence:** Medium
**Legibility-target:** for-author

The Author note still reads "User decision 2026-08-07: run the post-restructure measurement once code/prompt changes are fully settled". Beside the old `Split` it was a stale leftover (prior C2). Beside `🟡 Open` it sits where a reader looks for why the row is open, and it names a measurement that has run (358c2332). C2 stayed 🟢 Open and 139aeedd did not touch it. The status change makes it more misleading.

**Recommendation:** Append "— done 2026-11-19 (358c2332; probe 4363a15c)".

#### 7. Status-line and citation wording (cosmetic)

**Severity:** Informational
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4`, `:35`
**Move:** 2
**Confidence:** High
**Legibility-target:** for-author

Precedent: `**Status: 🟡 CONDITIONAL PASS** — [N] amber item(s) awaiting resolution or justification` used in `skills/code-review/references/rubric.md:608` and `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:5`

The line reads "1 amber item awaiting resolution (A8: ...)". It drops "or justification" and adds a parenthetical, which is the form `main` already had. No script reads it: `rg` of `scripts/` and `test/` matches only the verdict keyword. Separately, "the skill text this row cites (`SKILL.md:274-277`, `:352-354`)": the row cites only today's `:352-354`, and `:274-277` is its premise (fact-check Claim 3b).

**Recommendation:** Optional: "1 amber item(s) awaiting resolution or justification (A8: ...)" and "the skill text this row cites (now `:352-354`) and its premise (`:274-277`)".

## What Looks Good

- A2 is resolved. The A7 implication is recorded in `cache-probe.md:91-95` with its inference label, and both `:347-351` and A7 are carried into the A8 cell and the research doc's follow-up (subject to Finding 4's label).
- The status word `🟡 Open` and the conditional-pass status line now agree with each other and with the cell's prose. On the human-read surface, the earlier premature ✅ is gone.
- Every cell edit keeps the 9-cell row shape, so the parser reads all rows (no `bad` records).
- A4-A7's label and figure fixes match the records (fact-check Claims 5-7, 10, 13, 14).
- The brief's scope limits hold: no questions, roadmap or watching edit, no skill edit.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A1 `✅ Fixed` while A8 is still unrouted; "named in the hand-off marker" names nothing that exists; the canon's marker-line `Split` route was available | Inconsistent | `code-review-rubric-2026-11-19-measure-a8-cache-probe.md:26` | High |
| 2 | Parser reads A8 `closed` (Q-IDs in cell); gate goes from open on main to clean | Inconsistent | `code-review-rubric-2026-08-07-main.md:35`; `rubric-check.sh:113-114` | High |
| 3 | A3 reason ("separate measurement") contradicts canon's "run or sub-run"; `:131` is a fallback, the brief's file list is the reason | Minor | `cache-probe.md:98-102` | High |
| 4 | A7 cross-pass loss stated as fact in A8 cell and research doc; "inferred" only in probe doc | Minor | `code-review-rubric-2026-08-07-main.md:35`; `research-...:74-76` | High |
| 5 | Research doc title says "closing note" | Minor | `research-2026-11-19-a8-cache-probe.md:1` | High |
| 6 | Author note's pending 2026-08-07 instruction now sits beside an Open status | Minor | `code-review-rubric-2026-08-07-main.md:35` | Medium |
| 7 | Status line drops "or justification"; "this row cites :274-277" | Informational | `code-review-rubric-2026-08-07-main.md:4`, `:35` | High |

## Overall Assessment

Question 1: A1 is not resolved. 139aeedd made the A8 row honest, but the skill-text correction is still routed nowhere, and A1's `✅ Fixed (... named in the hand-off marker)` cites a marker that does not exist and that nothing commits to. A1 should read `🟡 Open`. Alternatively, the author can take the existing build-loop route (`review-fix-loop.md:84`): write the correction as a marker-body line, set A8 back to `Split` naming Q-308 and that line, and then A1 is truly Fixed. That route also removes the parser disagreement (Finding 2). Without it, "Open" stays invisible to the merge gate, which reads A8 `closed` from its Q-IDs and would report the 2026-08-07 rubric clean.

A2 is resolved, apart from a missing "inferred" label in two copies.

Question 2: the A3 fix conforms in form, using the fallback the prior pass offered, but its stated reason misreads the canon.

Question 3: no breaking change. The new inconsistencies are the A7-label asymmetry, the stale title, and the Author note that the new status makes misleading. The status-line form is inherited and cosmetic. All are fixable in place within the brief's file list.

## Goal-Alignment Note

The goal is to confirm that the fixes are accurate and complete before merge. They are accurate. They are not complete for A1, and the rubric that records A1 overstates that: it says Fixed and points to a marker that does not exist. The branch should not merge with A1 reading Fixed. Either the marker-line Split route is taken (Finding 1, which also settles Finding 2), or A1 is set to Open and the gate's `closed` reading of A8 is recorded. Findings 3-7 are wording fixes in files the brief permits. Scope was the delta range. I read the whole changed rows and paragraphs and their sections, plus the parser, `rubric_lines`, the canon sections and `review-fix-loop.md:84`. I did not run `build-loop.sh --check`. I started no background processes.
