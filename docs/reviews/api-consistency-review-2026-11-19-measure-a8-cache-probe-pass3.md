Commit: 3ab2183a

# API Consistency Review: measure/a8-cache-probe, pass 3 (b3fb2349)

**Scope:** `git diff 89eb9b65..b3fb2349 -- docs/reviews/code-review-rubric-2026-08-07-main.md runs/ docs/working/research-2026-11-19-a8-cache-probe.md` (loop pass, delta range, partial). The rest of `git log main..HEAD` (4363a15c, f87a1455, 139aeedd, 89eb9b65, 3ab2183a) is context only. The three files are identical at b3fb2349 and HEAD 3ab2183a (`git diff b3fb2349..HEAD --stat` touches only the branch rubric). Public surface: the parsed record contracts, meaning the rubric status words and status-line template (`skills/code-review/references/rubric.md`), `rubric_parse` (`scripts/lib/rubric-check.sh`), the hand-off marker channel (`workflows/review-fix-loop.md`, `skills/dev-cycle/SKILL.md`, `scripts/build-loop.sh`) and the ledger convention (`docs/working/review-canon.md:112-131`).
**Date:** 2026-11-19
**Based on:** `docs/reviews/code-fact-check-report-2026-11-19-measure-a8-cache-probe-pass3.md` (18 claims: 15 Verified, 3 Mostly accurate), its Claims 1-4 and its escalations.

## Baseline Conventions

- **Status words** (`rubric.md:190-206`). The first word is the class. `Split` (🔴, 🟡) means "moved to another unit" and must carry "the tracked follow-up (Q-ID, roadmap item or branch)" (`:204`). `Acknowledged` needs a qualifying author note: a tracked follow-up or a concrete revisit trigger (`:61-70`).
- **Review of code already on main** (`rubric.md:233-238`). Every open 🔴/🟡 row is routed to "a question entry, a roadmap item or an override-log row, named in the row". The 2026-08-07 rubric reviews `main`.
- **Split cells in practice** (`rg -n "Split" docs/reviews/code-review-rubric-*.md`). These cells name their destination by its title. One example: `Split: roadmap Now item "Agent: dev-cycle section 5 follow-ups (R5, A11)"` (`docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:18`, `:34`). Another: `Split out (013f1b3d → q096b)` (`code-review-rubric-2026-10-15-q096-exit-scan-insteadof-target.md:62`). No rubric outside this branch uses a marker line as a Split destination (`rg -n Split … | rg -i marker` gives only this branch's rubric).
- **Status line** (`rubric.md:607-609`). The all-resolved form is `**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation`. A trailing note after the label has precedent: 4 of the 15 PASSES lines in `docs/reviews/code-review-rubric-*.md` add one.
- **Hand-off marker body.** Two readings exist:
  - `workflows/review-fix-loop.md:84` says a split in a build loop may be filed as "a line in the marker body for the cycle to file".
  - Every reader of a *ready* body defines that body as a tentative-pick question:
    - `scripts/build-loop.sh:112-113`: "(a ready marker's body is a question the loop proceeded past on a tentative pick)"
    - `:1912`: "a tentative pick's question goes after a blank line"
    - `skills/dev-cycle/SKILL.md:716-721`: "A body (lines after the `ok` line) is a question the loop proceeded past on a tentative pick … a review brief's merge entry quotes it under the `--check` lines, so [1] accepts the pick". No step files a follow-up line.
  - In practice the cycle does file such lines. The ready body of a3ef5a38 ("One follow-up idea for the cycle to weigh: the live-verify commit hook … ignores MERGE_HEAD") became the roadmap item at `git show main:docs/roadmap.md` :126-132 ("The live-verify hook reads a merge commit's staged diff against HEAD only. Signal: the F-009 loop's pre-mortem item 5 …").
- **Parser** (`rubric-check.sh:65-71`, `:113-116`). An amber of any first word closes on keyword presence: a Q-ID, an override-log row, a TODO, "roadmap" or a trigger. "Keyword presence is not a check that the reference exists or says what it should."
- **Ledger** (`review-canon.md:112-117`, `:120-131`). A run that reports per-agent token figures "MUST (a) append one row per agent to a `token-ledger.md` … and (b) register the sub-run's agents and totals in the run's `manifest.json`". The fallback (`:130-131`) covers only empty `tokens` maps.
- **Brief limits** (`docs/working/briefs/2026-11-19-a8-cache-probe.md`). Criterion 4 limits the doc change to the probe doc, the rubric row, any skill change and the research doc. Out of scope: editing `docs/roadmap.md`, the questions files or `docs/working/watching.md`. Policy: review.

## Name-Pattern Audit

| New name / form | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Split` as A8's first word (amber) | status word | `Split` (`rubric.md:204`); `Split:` / `Split out` cells | `skills/code-review/references/rubric.md:190-206`; `docs/reviews/code-review-rubric-2026-11-18-*.md:18,34` | Consistent as a word. The second destination is a new form (Findings 1, 2). |
| "Moved on: X to Q-308; Y to …" | cell sub-label | `Split: roadmap Now item "…"`; `Split out (sha → slug)` | `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:18`; `…-2026-10-15-q096-exit-scan-insteadof-target.md:62-66` | Consistent in substance (it names the destinations). The phrase itself is new and harmless. |
| "the follow-up the `handoff: ready` marker of branch `measure/a8-cache-probe` asks the cycle to file" | Split destination reference | quoted roadmap title; Q-ID; branch slug | same as above | Inconsistent: names the channel, not the item (Finding 2) |
| `✅ PASSES REVIEW` + "(A8 split on 2026-11-19 …)" | status line | template `:609`; `…-2026-09-24-ans-copy-install-q058.md:5` "(after 4 passes. …)" | `skills/code-review/references/rubric.md:607-609`; `docs/reviews/code-review-rubric-*.md` | Consistent |
| "the brief's file list … leaves those files out" | ledger-omission statement | canon fallback "must state the omission explicitly" | `docs/working/review-canon.md:130-131` | Consistent as a statement. It does not name the MUST it departs from (Finding 6). |

## Findings

#### 1. A8's second Split destination relies on a marker-body reading that the marker's readers do not define

**Severity:** Inconsistent
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35` (A8 Status cell); contract at `workflows/review-fix-loop.md:84` vs `skills/dev-cycle/SKILL.md:716-721`, `scripts/build-loop.sh:112-113`, `:1912`
**Move:** 3 (consumer contract)
**Confidence:** Medium (the cycle has filed such a line once before, so it works in practice. The written contract does not promise it.)
**Legibility-target:** for-author
**Evidence:** cell: "… correcting the skill text this row cites (`SKILL.md:352-354`), its premise (`:274-277`) and, by the same mechanism (inferred, not measured), A7's cross-pass claim (`:347-351`) to the follow-up the `handoff: ready` marker of branch `measure/a8-cache-probe` asks the cycle to file" (cell, final clause; the clause before it, "Moved on: net inline cost and recall effect to Q-308;", is not shown). dev-cycle: "A body (lines after the `ok` line) is a question the loop proceeded past on a tentative pick (divergent design's Path C): a review brief's merge entry quotes it under the `--check` lines, so [1] accepts the pick and [3] with another names it" (sentence; the self-merge clauses that follow are not shown, and this brief is `Policy: review`).

`rubric.md:204` wants "the tracked follow-up". `rubric.md:235-237` lists the three destinations allowed for a review of main, and a marker line is not one of them. Only `review-fix-loop.md:84` allows the marker line, as a request for the cycle to file. That line's readers are the dev cycle's ready step and `--marker`. Both treat a ready body as a tentative-pick question, which `[1] merge` "accepts", and neither has a step that turns a follow-up line into a roadmap item. So on this review-policy brief, the written path ends with the line quoted in the merge entry. The owner's [1] then reads as accepting a pick, and nothing assigns the filing. The precedent (a3ef5a38's ready body, which became the roadmap item at main's `docs/roadmap.md:126-132`) shows that the orchestrator files such lines by judgment. That makes this a doc-contract gap, not a dead channel. This delta is the first rubric row that rests on that judgment.

**Recommendation:** This fits the brief, since no roadmap, questions or watching edits are needed. Make the marker line explicit and self-contained, for example: "For the cycle to file as a roadmap item (not a question): <title>. Rubric row A8 of docs/reviews/code-review-rubric-2026-08-07-main.md is Split to it." Put the same title in the cell (Finding 2). The reader of the merge entry should check that the item was filed before answering [1]. The `review-fix-loop.md:84` ↔ `dev-cycle SKILL.md:716-721` gap is for the cycle, which could itself be a line in the same marker body. The brief lists no skill or workflow edits beyond the code-review skill, so this branch cannot close the gap.

#### 2. The Split destination is named by its channel, not by the item, unlike sibling Split cells

**Severity:** Minor
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** for-author
Precedent: Split cells name the destination by its title or ID, e.g. `Split: roadmap Now item "Agent: dev-cycle section 5 follow-ups (R5, A11)"`, used in `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:18`, `:34`; `Split out (013f1b3d → q096b)` in `docs/reviews/code-review-rubric-2026-10-15-q096-exit-scan-insteadof-target.md:62`
**Evidence:** "to the follow-up the `handoff: ready` marker of branch `measure/a8-cache-probe` asks the cycle to file" (final clause of the cell)

**Does the wording identify the future marker?** Yes, as a commit. The cell names the branch and the exact subject, and a loop ends with one marker at its tip. After merge the marker stays reachable as the second parent of `Merge branch 'measure/a8-cache-probe' (build-loop …)` (`scripts/build-loop.sh:1625`, `:1712`). It does not identify the item. The cell names neither the line in the body nor a title, so when the item lands on the roadmap no string in A8 matches it, and A8 gets no back-link. A reader of the row today also cannot tell what is being requested. The sibling cells avoid both problems by quoting the destination's name.

**Recommendation:** Quote the intended roadmap title in the cell, e.g. `… to the roadmap item "<title>" that the handoff: ready marker of branch measure/a8-cache-probe asks the cycle to file`, and use the same string in the marker body. This also gives the fact-check's suggested "request until filed" wording.

#### 3. The gate's `closed` reading of A8 rests on the Q-306/Q-308 keywords alone

**Severity:** Informational
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `scripts/lib/rubric-check.sh:113-116`
**Move:** 3 (consumer contract)
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `rubric_parse` at HEAD gives `row	amber	A8	closed	Split — measured 2026-11-19: …` (record truncated). With Q-306 and Q-308 replaced in a scratch copy it gives `row	amber	A8	open	Split — …`. Run from `…/review3/api/` (`noq.md`).

This is the parser working as documented ("Keyword presence is not a check that the reference exists or says what it should", `:71-72`). Q-306 is the merge approval of the earlier A8 results, a provenance cite, and it alone would close the row. The marker route adds nothing the parser can see. A cell that also said "roadmap" would read `closed` without any Q-ID (verified in scratch `road.md`). So `rubric_lines`' "clean" for this file means "cites a Q-ID". It does not mean "both destinations tracked".

**Recommendation:** No cell change. A cell must not add keywords to steer the parser. The merge entry's `rubric … clean` line for this file should be read with Finding 1's check, as the fact-check's escalation 2 says.

#### 4. The row's Finding and Status cells cite the same text at different line numbers with no commit mapping

**Severity:** Minor
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:** Finding cell: "\"Leave it on because it is free\" / \"0% of token count\" (`SKILL.md:276-278`) is not established …" (first sentence; the remainder is not shown). Status cell: "correcting the skill text this row cites (`SKILL.md:352-354`)" (mid-clause).

Fact-check Claim 3 confirms that :276-278 at 2f5ad0b equals HEAD :352-354 byte for byte. A reader of the row sees "this row cites" next to a range the row does not cite and has to rediscover that mapping.

**Recommendation:** Write "the skill text this row cites (`SKILL.md:276-278` at 2f5ad0b, now `:352-354`)".

#### 5. The research doc still states A7's loss as measured and describes A8 as `🟡 Open`, so the likely marker source text disagrees with the cell

**Severity:** Minor
**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:77-80` (outside the changed lines; branch rubric C11, open), `:25`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:** :77-80, whole paragraph: "The skill still says the cache \"serve[s] the shared block to all ~8 agents\" and \"Leave it on because it is free\" (`SKILL.md:274-277`, `:352-354`), and its stable-parts-first rule claims cross-pass warmth (`:347-351`, rubric row A7); the probe shows that saving does not occur on the Agent-tool path. Correcting that text is a pipeline change the brief puts out of scope, so it is for the cycle to file." :25: "Rubric row: `docs/reviews/code-review-rubric-2026-08-07-main.md:35`, `🟡 Open`; status words in …"

The delta qualified the A7 claim as "(inferred, not measured)" in the A8 cell. This "Follow-up for the cycle" paragraph is the one built to become the marker body, and it still says "the probe shows" for A7. If it is copied into the marker, the cycle files an unqualified claim. Line :25 is the starting state in a context section, but it now contradicts the row it points at.

**Recommendation:** In :77-80, write "the probe shows that saving does not occur … (for A7's cross-pass claim, inferred from the same mechanism, not measured)". In :25, write "`🟡 Open` at the start; now `Split`". Draft the marker body from the corrected text.

#### 6. The probe's ledger omission is stated, but the statement does not name the rule it departs from

**Severity:** Informational
**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:98-102`
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:** "These two agents are not rows in `token-ledger.md` or `manifest.json`: the brief's file list for this change (the probe doc, the rubric row, any skill change and the research doc) leaves those files out, so the table above is the probe's per-agent record, and this paragraph states the omission." (sentence complete; the paragraph's first two sentences on cost are not shown)

The reason is now accurate: the brief's criterion 4 lists exactly those four files. The text no longer claims backing from the canon. Under `review-canon.md:114-117`, however, this is a departure from a MUST. Someone summing the run directory's `token-ledger.md` (present in `runs/review-arms/a8-2026-11-19/`) will miss 101,370 tokens, and nothing in the ledger or the canon points here.

**Recommendation:** Optional: add "(`docs/working/review-canon.md:114-117` asks for those rows)" so the departure can be found from the rule. Transcribing the rows needs a file outside the brief's list, so that can go as a further line in the marker body if the cycle wants it.

## What Looks Good

- `Split` is the right status word. It is defined for 🟡, both destinations are named, and the cell no longer leads with `🟡 Open` while the parser reads it closed. That was the pass-2 A9 contradiction.
- The status line follows the template's all-resolved form verbatim. It carries the single-sample label once, and the trailing note follows the q058 precedent. The rubric's tiers now agree with its status line.
- A12's wording distinguishes "this row cites" (:352-354) from its premise (:274-277), and fact-check Claim 3 verified the ranges.
- The A7 implication is marked "(inferred, not measured)" in the cell, which matches `cache-probe.md:94`.
- The ledger-omission reason is now the brief's file list. This is the true reason, and it no longer misstates `review-canon.md`.
- The fix stays within the brief: no roadmap, questions or watching edits.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Split's marker-line destination relies on `review-fix-loop.md:84`, which the ready-marker readers do not define (they read a ready body as a tentative-pick question); a review of main allows only question/roadmap/override-log | Inconsistent | `code-review-rubric-2026-08-07-main.md:35`; `dev-cycle/SKILL.md:716-721` | Medium |
| 2 | Destination named by channel, not by title; it identifies the marker commit but not the item | Minor | `code-review-rubric-2026-08-07-main.md:35` | High |
| 3 | Gate's `closed` rests on Q-ID keywords alone (Q-306 is provenance) | Informational | `rubric-check.sh:113-116` | High |
| 4 | Finding cites `:276-278`, Status says "this row cites (`:352-354`)" with no mapping | Minor | `code-review-rubric-2026-08-07-main.md:35` | High |
| 5 | Research follow-up paragraph still says "the probe shows" for A7; :25 says `🟡 Open` | Minor | `research-2026-11-19-a8-cache-probe.md:25`, `:77-80` | High |
| 6 | Ledger omission does not name the canon MUST it departs from | Informational | `cache-probe.md:98-102` | High |

## Overall Assessment

The delta brings A8 and the 2026-08-07 status line into line with the rubric's status words and template. The pass-2 contradiction, where the parser read the row closed while the status line said open, is gone. What is left is one contract question and some precision fixes. The `Split` cell's second destination is a marker-body request. One workflow allows that form, but the marker's own readers do not define it, and on a review-policy brief nothing assigns the filing (Finding 1). The cell identifies the marker commit, but not the item (Finding 2). All fixes fit the brief: quote one roadmap title in both the cell and the marker body, word that marker line as an explicit filing request, and correct the research doc's follow-up paragraph before using it as the marker source. Consumer impact is low. The parser and gate are unaffected, and the risk is a correction that never gets filed, which the merge-entry check in Finding 1 covers.

## Goal-Alignment Note

The goal is to confirm that the last fixes are accurate before merge. They are accurate. The pass-2 rows they claim to fix (A9 status-line/parser contradiction, A11 ledger reason, A12 line wording, A13 status-line form, the C11 qualifier in the cell) are fixed as stated. A1 (a tracked follow-up beside Q-308) is fixed only as far as the marker route allows. The branch can merge once the marker body carries an explicit filing line whose title the A8 cell quotes, and once the merge-entry reader confirms the cycle filed it (Findings 1-2). Findings 4-5 are wording fixes in permitted files, and 3 and 6 need no change. Scope: the delta range. I read the whole A8 row, the status line, the research doc in full, the probe doc's method, result and cost sections, the canon ledger section, `rubric.md` status words, status line and review-of-main sections, the full `rubric_parse`, the `--marker` and `--status` contracts, the loop prompt's marker rules, and the dev-cycle ready step. I ran `rubric_parse` on the HEAD file and two scratch variants. I did not run `build-loop.sh --check`. I started no background processes.
