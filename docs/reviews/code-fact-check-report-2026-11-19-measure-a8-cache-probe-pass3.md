Commit: 3ab2183a

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-11-19-a8-cache-probe (claude-workflows), branch `measure/a8-cache-probe`
**Commit:** 3ab2183a
**Scope:** `git diff 89eb9b65..b3fb2349 -- docs/reviews/code-review-rubric-2026-08-07-main.md runs/ docs/working/research-2026-11-19-a8-cache-probe.md` (3 files, 14+/11-), plus b3fb2349's commit message and the branch rubric's `✅ Fixed (b3fb2349 ...)` claims (rows A1, A9-A13, C11's request) as the orchestrator asked. Partial scope (loop pass, delta range); 4363a15c, f87a1455, 139aeedd, 89eb9b65 and 3ab2183a are context only. The three in-scope files are identical at b3fb2349 and HEAD.
**Checked:** 2026-11-19
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 18
**Summary:** 15 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Evidence runs (executed; script `.../review3/factcheck/e1.sh`, run with `timeout 120 bash e1.sh`, cwd the worktree after `cd` from the scratch dir, exit 0, 2026-11-19T20:40:05Z; `...` = `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe`):
- **E1** `timeout 60 bash -c 'source scripts/lib/rubric-check.sh && rubric_parse "$1"' _ docs/reviews/code-review-rubric-2026-08-07-main.md` at HEAD. Output: `.../review3/factcheck/E1.txt`.
- **E1b** the same parser on a copy of that file with the strings `Q-306` and `Q-308` deleted (counterfactual: does `Split` close A8 by itself?). Output: `.../review3/factcheck/E1b.txt`.
- **E2** the same parser on `git show 89eb9b65:docs/reviews/code-review-rubric-2026-08-07-main.md`. Output: `.../review3/factcheck/E2.txt`. `git show 89eb9b65:scripts/lib/rubric-check.sh` is identical to HEAD's (`.../review3/factcheck/parser-diff.txt`, diff exit 0).

No entry in `docs/reviews/hallucination-patterns.md` matches these claims (grep for rubric/split/marker/line-ref patterns: no hits).

---

## Claim 1: "**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation (A8 split on 2026-11-19 after its measurement and cache probe; all other reds/ambers fixed in iterations 1–3)"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4`
**Type:** Invariant / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the status line's form against the template and the "all other reds/ambers fixed" count; does not establish that A8's Split is complete in substance (Claim 2), which the ✅ form depends on.
**Legibility-target:** for-orchestrator-synthesis

The template's all-resolved form is `skills/code-review/references/rubric.md:609`: "All red and amber resolved: `**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation`". The line reproduces it verbatim and appends one parenthetical. The label occurs once in the file (`rg -c` → 1), as `rubric.md:621-626` requires. A trailing parenthetical has precedent: `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md:5` "…absence of findings is not an attestation (after 4 passes. …)". E1 reads R1 and A1-A7, A9-A12 as `fixed`, for example `row	amber	A12	fixed	✅ Fixed (iter 1 — "share only a ~330-token instruction prefix")`, and A8 as `closed`. Iterations 1-3 are named in those cells (`:17`, `:28-39`; A3/A7 "iter 2", A6 "iter 3").

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4`, `:17`, `:28-39`; `skills/code-review/references/rubric.md:607-626`; `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md:5`; `.../review3/factcheck/E1.txt`

---

## Claim 2: "Split — … Moved on: net inline cost and recall effect to Q-308; correcting the skill text this row cites … to the follow-up the `handoff: ready` marker of branch `measure/a8-cache-probe` asks the cycle to file"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Reference / Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers `Split`'s use against the status-word definition, and whether the second destination can be found and is a sanctioned form; does not establish that the marker body will contain the line (it does not exist yet, known item 1), or that the cycle will file it.
**Legibility-target:** for-author

`rubric.md:204` defines the word: "`Split` | 🔴, 🟡 | moved to another unit | the tracked follow-up (Q-ID, roadmap item or branch)". The first destination, Q-308, is a Q-ID. The second is a request, not yet a tracked item. One repo rule sanctions this form: `workflows/review-fix-loop.md:84` "files the split-off part as a tracked item before the rest merges: a roadmap item or question entry, or in a build loop a line in the marker body for the cycle to file. Each split-off 🔴/🟡 row then reads `Split` and names that item." The loop prompt agrees: `scripts/build-loop.sh:1908` "write the question … in your ready marker's body, for the cycle to file".

Can a reader find it? Yes: the cell names the branch and the marker subject. After merge the marker stays reachable, because the cycle merges with a merge commit and the marker is its second parent. Main's history shows merge subjects of the form `Merge branch 'measure/a8-token-measurement' (build-loop approved merge)` (`git log main --merges`), and the ff-only landing is at `scripts/build-loop.sh:1724`.

The imprecision is on the cycle's side. The cycle's handling of a ready body treats it only as a tentative-pick question: `skills/dev-cycle/SKILL.md:716-721` "A body (lines after the `ok` line) is a question the loop proceeded past on a tentative pick … a review brief's merge entry quotes it". No step there files a follow-up line as a roadmap item. The quoted body reaches the owner in the merge entry, but nothing makes the cycle file it. The item the cell will finally point at also gets no back-link into this row. A more precise cell would carry the marker line's own wording, so the eventual roadmap item can be matched to it, and would name it as a request, not a tracked item, until it is filed. This cell is in a review of code already on main, and that rule (`rubric.md:235-237`) lists "a question entry, a roadmap item or an override-log row, named in the row". A marker line is none of those three, so the cell is in the right form only when it is read through review-fix-loop.md:84.

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `skills/code-review/references/rubric.md:190-206`, `:233-238`; `workflows/review-fix-loop.md:84`; `scripts/build-loop.sh:1067-1088`, `:1908`, `:1912`, `:1724`; `skills/dev-cycle/SKILL.md:715-722`

---

## Claim 3: "correcting the skill text this row cites (`SKILL.md:352-354`), its premise (`:274-277`) and … A7's cross-pass claim (`:347-351`)"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each cited range at HEAD and the mapping of the row's own `:276-278` (at 2f5ad0b) to `:352-354`; does not establish that the ranges hold once main's SKILL.md changes (the branch does not touch `skills/`).
**Legibility-target:** for-orchestrator-synthesis

At 2f5ad0b, `skills/code-review/SKILL.md:276-278` reads "- **Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a / billing-rate effect, not a token-count reduction). Leave it on because it is free; do not expect / it to move the token-count ledger." (`git show 2f5ad0b:skills/code-review/SKILL.md`). HEAD's `:352-354` holds the same three lines byte for byte. HEAD `:274-277`: "This lets the Anthropic prompt cache serve the shared block to all ~8 agents in a / pass — and again on the next loop pass while it is unchanged — … zero effect on recall (decision 032 H1)." That is the premise of "free". HEAD `:347-351`: "- Across loop passes, the block's prefix stays cache-warm up to the first part that changed: … Ordering stable-parts-first is what preserves a / cacheable common prefix across passes even when the diff changes." That is A7's rule (A7 at `:34`, "Reorder stable-parts-first"). The branch changes no file under `skills/` (`git diff main...HEAD --name-only`), so the numbers are main's.

**Evidence:** `skills/code-review/SKILL.md:274-277`, `:347-351`, `:352-354`; `git show 2f5ad0b:skills/code-review/SKILL.md` `:276-278`; `docs/reviews/code-review-rubric-2026-08-07-main.md:34-35`

---

## Claim 4: "by the same mechanism (inferred, not measured), A7's cross-pass claim"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the cell now labels the A7 implication as it is labelled in the probe record (C11's cell half); does not cover the research doc's copy (Claim 16).
**Legibility-target:** for-orchestrator-synthesis

`runs/review-arms/a8-2026-11-19/cache-probe.md:88-95` says "The probe did not test reuse across loop passes. … so by this mechanism it buys no cross-pass cache hit. That is inferred from the records, not measured." The old cell's unqualified "now describe a saving that does not occur" is gone from the new cell (diff, `-`/`+` lines of `:35`). The measured half of the cell still stands without the label, as it should: "a second agent 28.5 s later, same block byte for byte, still read only 18,900 tokens" (`:35`) matches `cache-probe.md:26-36`.

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `runs/review-arms/a8-2026-11-19/cache-probe.md:26-36`, `:82-96`

---

## Claim 5: A1 "✅ Fixed (b3fb2349 — A8 is Split naming Q-308 and the skill-text correction the branch's handoff marker asks the cycle to file)"

**Location:** `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that b3fb2349's A8 cell does what this Status cell says, and that it covers every span A1's Fix lists; does not establish the substance A1 asked for, a filed roadmap or Q item (A1's Fix: "file a roadmap item (or Q entry) … and name it in A8's cell"), which remains a marker request (Claim 2).
**Legibility-target:** for-orchestrator-synthesis

A1's Fix lists "`SKILL.md:274-277`, `:347-351` and `:352-354` (see A2)". All three spans appear in the new A8 cell (Claim 3), beside "Q-308". The route differs from A1's literal Fix but matches the one pass 2 recommended (A9 at `:36`: "take A1's marker-line `Split` route, which makes `closed` correct"; composition row 3 at `:104`). The brief rules out the literal Fix: `docs/working/briefs/2026-11-19-a8-cache-probe.md:32` "Editing `docs/roadmap.md`, the questions files or `docs/working/watching.md`".

**Evidence:** `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:28`, `:36`, `:104`; `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `docs/working/briefs/2026-11-19-a8-cache-probe.md:28-32`

---

## Claim 6: A9 "✅ Fixed (b3fb2349 — A8 now reads closed and the 2026-08-07 status line is all-resolved, so parser and line agree)"

**Location:** `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser's class for A8 at HEAD and the status line's agreement with it; does not establish that `Split` produces that class, because the class comes only from the Q-IDs (E1b).
**Legibility-target:** for-orchestrator-synthesis

E1: `row	amber	A8	closed	Split — measured 2026-11-19: … Q-306 Q-308`, and the status line is ✅ (Claim 1), so the two agree. The orchestrator asked where the class comes from. It is the Q-IDs. `scripts/lib/rubric-check.sh:108` reads only `fixed`/`resolved` as first words: `return ("fixed", "-") if ($first eq "fixed" || $first eq "resolved") && !$neg;`. For an amber, `:114` closes on the cell's other content: `return ("closed", $qids) if $qids ne "-" || $ovr || $t =~ /\bTODO\b/ || $t =~ /\broadmap\b/i` (excerpt ends :114; the condition continues to `:115` with the trigger/revisit keywords — read). Nothing reads `split` as a word. The header comment says so too, at `:58-59` "Any other closure of a red, Split and Carried included, is qref" and `:65` "An amber, whatever its first word, closes on a qualifying author note". E1b, the same file with Q-306 and Q-308 deleted, gives `row	amber	A8	open	Split — …	-`. One more detail: Q-306 is a merge approval, not a follow-up ("merge approved Q-306"), and by `:110-114` it would close the row on its own.

**Evidence:** `scripts/lib/rubric-check.sh:39-75`, `:102-117`; `.../review3/factcheck/E1.txt`; `.../review3/factcheck/E1b.txt`

---

## Claim 7: A10 "✅ Fixed (b3fb2349 — the row closes again, so the title holds)"

**Location:** `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:37`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the research doc's title against the A8 cell at HEAD; does not establish the doc's other stale lines (Claim 16; `:25`, see Goal-Alignment Note).
**Legibility-target:** for-orchestrator-synthesis

`docs/working/research-2026-11-19-a8-cache-probe.md:1` "# Research: A8 cache probe and the closing note for rubric row A8". The cell is again a closing `Split` (Claim 2). The contradicting sentence A10 quoted, "So the row stays open until the cycle files the correction", was removed (diff `-` line in Design choices; `rg "stays open"` finds no hit in the file).

**Evidence:** `docs/working/research-2026-11-19-a8-cache-probe.md:1`, `:59-73`

---

## Claim 8: A11 "✅ Fixed (b3fb2349 — reason is now the brief's file list)"

**Location:** `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:38`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the stated reason changed as described; whether the new paragraph meets review-canon.md is Claim 17.
**Legibility-target:** for-orchestrator-synthesis

`runs/review-arms/a8-2026-11-19/cache-probe.md:99-102` now reads "the brief's file list for this change (the probe doc, the rubric row, any skill change and the research doc) leaves those files out". The contested citation "(the omission `docs/working/review-canon.md:131` asks a results doc to state)" is gone (diff `-` line).

**Evidence:** `runs/review-arms/a8-2026-11-19/cache-probe.md:98-102`

---

## Claim 9: A12 "✅ Fixed (b3fb2349)"

**Location:** `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:39`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cell's wording against A12's suggestion; the line mapping itself is Claim 3.
**Legibility-target:** for-orchestrator-synthesis

A12 suggested "the skill text this row cites (now `:352-354`) and its premise (`:274-277`)". The cell reads "the skill text this row cites (`SKILL.md:352-354`), its premise (`:274-277`)" (`code-review-rubric-2026-08-07-main.md:35`).

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`

---

## Claim 10: A13 "✅ Fixed (b3fb2349 — status line takes the template's all-resolved form)"

**Location:** `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:40`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the form (Claim 1); does not re-establish A8's completeness (Claim 2).
**Legibility-target:** for-orchestrator-synthesis

See Claim 1: the line is `rubric.md:609`'s form verbatim, plus a parenthetical. The "or justification" wording that A13 flagged belonged to the conditional form, which is no longer used.

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4`; `skills/code-review/references/rubric.md:607-609`

---

## Claim 11: "Rubric status word for A8: `Split`, naming Q-308 (net cost, recall) and the skill-text correction this branch's `handoff: ready` marker asks the cycle to file (… a marker body is the build loop's channel for what the cycle files)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:62-65`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the loop-side contract (the loop prompt and review-fix-loop.md); does not establish a cycle-side step that files a ready body's follow-up line (none exists; `skills/dev-cycle/SKILL.md:716-721`, see Claim 2).
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:1915-1916` forbids the loop to write those files: "Never write the questions files, docs/working/watching.md, the roadmap …". The repo names the marker body as the loop's channel for items to file in `workflows/review-fix-loop.md:84` ("in a build loop a line in the marker body for the cycle to file") and in `scripts/build-loop.sh:1908` ("in your ready marker's body, for the cycle to file"). Q-308's coverage, "(net cost, recall)", matches the pass-1 reading of it (branch rubric A1, `:28`: "Q-308 … covers only the two settling runs (net cost, recall)").

**Evidence:** `scripts/build-loop.sh:1908`, `:1915-1916`; `workflows/review-fix-loop.md:84`; `skills/dev-cycle/SKILL.md:715-722`; `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:28`

---

## Claim 12: "Review pass 1 caught a first Split that named only Q-308; pass 2 caught the interim `🟡 Open` cell, which named Q-IDs and so read as closed to `scripts/lib/rubric-check.sh` while the file's status line said open"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:65-67`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 4363a15c's A8 cell, 89eb9b65's parser output and status line, and the branch rubric rows A1/A9; does not establish anything about later revisions.
**Legibility-target:** for-orchestrator-synthesis

4363a15c's A8 Status cell ends "Net inline cost and recall effect moved to Q-308" and names no other destination (`git show 4363a15c:docs/reviews/code-review-rubric-2026-08-07-main.md`, `:35`). Branch rubric A1 (`:28`) is the pass-1 catch. E2, run on 89eb9b65's copy, gives `row	amber	A8	closed	🟡 Open — measured 2026-11-19 … Q-306 Q-308`. At that commit the status line read "**Status: 🟡 CONDITIONAL PASS** — 1 amber item awaiting resolution (A8: …" (the diff's `-` line of `:4`). The parser at 89eb9b65 is byte-identical to HEAD's (`parser-diff.txt`). This matches branch rubric A9 (`:36`).

**Evidence:** `.../review3/factcheck/E2.txt`; `.../review3/factcheck/parser-diff.txt`; `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:28`, `:36`

---

## Claim 13: "`Acknowledged` was the other viable word and needs the same tracked follow-up."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:67-68`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what `Acknowledged` requires under rubric.md; does not judge whether it would have been the better word.
**Legibility-target:** for-author

`rubric.md:201` "`Acknowledged` | 🟡, 🟢 | stands with a qualifying author note | the note". A qualifying note is either of two things (`rubric.md:63-68`): "either (a) a **discoverable TODO** — … or a tracked follow-up entry … — or (b) a **concrete revisit trigger**". So `Acknowledged` needs a tracked follow-up *or* a revisit trigger, not "the same tracked follow-up". The 89eb9b65 wording had it right: "`Acknowledged` needs a tracked follow-up or a revisit trigger". "Viable" is supported by pass 1's submitted Claim 20 ("`Acknowledged` (`:201`) was also valid", branch rubric `:80`). Precise version: "`Acknowledged` was the other viable word; it needs a tracked follow-up or a revisit trigger."

**Evidence:** `skills/code-review/references/rubric.md:61-70`, `:201`; `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:80`

---

## Claim 14: "The rubric file's status line takes the template's all-resolved form, since every other red and amber row there is fixed."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:69-70`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row classes (E1) and the form (Claim 1); does not establish that A8's Split is complete in substance (Claim 2).
**Legibility-target:** for-orchestrator-synthesis

E1: R1 and A1-A7, A9-A12 are `fixed`. The form matches `rubric.md:609` (Claim 1).

**Evidence:** `.../review3/factcheck/E1.txt`; `skills/code-review/references/rubric.md:609`

---

## Claim 15: "Research: A8 cache probe and the closing note for rubric row A8" (title still fits)

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:1`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the title against the A8 cell at HEAD; same as Claim 7.
**Legibility-target:** for-orchestrator-synthesis

The A8 cell is a `Split` closing note (Claim 2), and Plan step 2 (`:85`) names it: "Rubric row A8 Status cell, rubric status line."

**Evidence:** `docs/working/research-2026-11-19-a8-cache-probe.md:1`, `:85`

---

## Claim 16: "its stable-parts-first rule claims cross-pass warmth (`:347-351`, rubric row A7); the probe shows that saving does not occur on the Agent-tool path."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:77-80`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the research doc's copy of the A7 implication, which C11 named (as `:74-76` before the delta shifted it); unchanged text in an in-scope file. Does not challenge the inference itself, which pass 2 judged sound (C11).
**Legibility-target:** for-author

The probe record says the cross-pass loss is inferred: `cache-probe.md:88-89` "The probe did not test reuse across loop passes", and `:94-95` "That is inferred from the records, not measured". This paragraph still lumps the cross-pass rule under "the probe shows that saving does not occur", so it states the inference as a probe result. The paragraph is byte-identical to 89eb9b65's (`git show 89eb9b65:…` "Follow-up for the cycle"). Only the A8 cell received the label. That matches b3fb2349's message, which says "marked inferred in the cell too" (Claim 18), and C11 is still `🟢 Open` (branch rubric `:58`). The precise version would add a clause such as "(for `:347-351`, inferred from the same mechanism, not measured)".

**Evidence:** `docs/working/research-2026-11-19-a8-cache-probe.md:75-80`; `runs/review-arms/a8-2026-11-19/cache-probe.md:88-95`; `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:58`

---

## Claim 17: "These two agents are not rows in `token-ledger.md` or `manifest.json`: the brief's file list for this change (the probe doc, the rubric row, any skill change and the research doc) leaves those files out, so the table above is the probe's per-agent record, and this paragraph states the omission."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:99-102`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthetical against the brief's file list, and that the omission is stated; does not establish that the probe meets the review-canon convention, which it does not: it states its non-compliance.
**Legibility-target:** for-orchestrator-synthesis

Brief acceptance item 4 (`docs/working/briefs/2026-11-19-a8-cache-probe.md:21`): "Doc change: the probe doc, the rubric row, any skill change, and your research doc `docs/working/research-2026-11-19-a8-cache-probe.md` (force-added)". The parenthetical is a faithful paraphrase. The table "above" exists, with per-agent usage rows and "Notified `subagent_tokens` | 50,685 | 50,685" (`:24-34`). Both ledger files exist and the branch does not change them (`ls runs/review-arms/a8-2026-11-19/`; `git diff main...HEAD --name-only` lists neither).

Against `docs/working/review-canon.md:112-131`, which the orchestrator asked about: the convention is a MUST, "any run or sub-run that reports per-agent token figures MUST (a) append one row per agent to a `token-ledger.md` … and (b) register the sub-run's agents and totals in the run's `manifest.json`" (`:114-117`). The amendment makes it unconditional for runs with a manifest (`:124-127`). Its one fallback is "A run that nonetheless finishes with empty `tokens` maps must state the omission explicitly in its results doc" (`:130-131`). This paragraph does state the omission explicitly, with its reason, so it meets the fallback's disclosure duty. It does not meet (a) or (b). The canon names no reason that excuses them (paraphrased — no quote available because the claim covers absence: `:112-134` contains no exemption clause). The paragraph no longer claims canon backing, so it makes no false claim about the canon.

**Evidence:** `runs/review-arms/a8-2026-11-19/cache-probe.md:24-34`, `:98-102`; `docs/working/briefs/2026-11-19-a8-cache-probe.md:16-32`; `docs/working/review-canon.md:112-134`

---

## Claim 18: b3fb2349 message: "A11: the ledger omission's reason is the brief's file list. A12: the row cites only SKILL.md:352-354; :274-277 is its premise. C11: the A7 implication is marked inferred in the cell too."

**Location:** `git show b3fb2349` (commit message, body lines 3-6)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each sentence's literal claim; "in the cell too" is true of the cell only, and C11's research-doc half is undone (Claim 16).
**Legibility-target:** for-orchestrator-synthesis

The A11 sentence is borne out by Claim 8, A12 by Claims 3 and 9, and C11's cell half by Claim 4. "Too" is correct relative to `cache-probe.md:94-95`, which already carried the label. The message's first paragraph, "the interim Open cell named Q-IDs and so parsed as closed under an open status line", is Claim 12.

**Evidence:** `git show b3fb2349`; `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `runs/review-arms/a8-2026-11-19/cache-probe.md:94-95`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`): the second Split destination is a request in a marker not yet written, and the cycle has no step that files it. Quote the marker line's own wording in the cell, so the filed item can be matched to it, and call it a request until it is filed.
- **Claim 13** (`docs/working/research-2026-11-19-a8-cache-probe.md:67-68`): `Acknowledged` needs a tracked follow-up *or* a revisit trigger (`rubric.md:63-68`), not "the same tracked follow-up".
- **Claim 16** (`docs/working/research-2026-11-19-a8-cache-probe.md:77-80`): C11's research-doc half is undone. The A7 cross-pass loss is still stated as a probe result. Add "inferred, not measured" for `:347-351`.

### Unverifiable
(none)

---

## Goal-Alignment Note
- Success criterion (restated verbatim): a code-fact-check report saved to /workspace/.claude/wt-2026-11-19-a8-cache-probe/docs/reviews/code-fact-check-report-2026-11-19-measure-a8-cache-probe-pass3.md, structured per the code-fact-check skill, with `**Commit:** 3ab2183a` and `**Replication:** k=1 (loop pass, decision 031)` in the header.
- Answered: yes. All seven items were checked. b3fb2349's fixes are accurate as stated. Three wording items remain (Claims 2, 13, 16), all low impact and none blocking.
- Out of scope: context only, not verdicted. (a) The research doc's `:25`, "Rubric row: …`:35`, `🟡 Open`", dates from 4363a15c, sits under "What I know (context)", and correctly describes the starting state on main. (b) In the branch rubric (3ab2183a), the status line still reads "6 amber item(s) awaiting", the first line still reads `Commit: 89eb9b65`, and C2's parenthetical says "beside `🟡 Open`". These are in-loop bookkeeping that the next pass rewrites. No other file on the branch quotes the old `🟡 Open — measured` cell or "stays open until the cycle files the correction", except the pass-2 review reports, which are historical.
- Escalate: (1) The cycle side of the Split. `skills/dev-cycle/SKILL.md:716-721` reads a ready marker's body only as a tentative-pick question and has no step that files a follow-up line as a roadmap item. A8's skill-text correction (SKILL.md:274-277, :347-351, :352-354) therefore depends on the marker line being worded so the cycle and the owner act on it. Consider writing it as an explicit "for the cycle to file as a roadmap item" line, and checking at merge that the item was filed. (2) The parser closes A8 on its Q-IDs alone. `Split` is never read for an amber (E1b), and Q-306, a merge approval, would close the row by itself. This is advisory only, but the gate's "clean" for this file says nothing about the marker route.
- Decisions I made: I verdicted the branch rubric's `✅ Fixed` claims and b3fb2349's message although they sit outside the diff, because the brief asked. I graded Claim 2 Mostly accurate, not Incorrect, because `workflows/review-fix-loop.md:84` explicitly sanctions the marker-line form.
