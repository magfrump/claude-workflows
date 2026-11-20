# Research: should a judgment entry's "Why it's yours" quote the constraint it relies on?

**Goal:** decide, by divergent design, whether and how a `you: judgment` entry that justifies reaching the owner by a constraint number (`H1`, `S10` and so on) should quote that constraint's text, so a citation that does not cover the case is caught before it costs the owner a read.
**Problem framing:** treated as "is there a recurring miscitation worth a rule, and if so where does the rule live". Considered and discarded: treating it as a wording fix to the entry grammar alone. That framing assumes the motive, which S5 (motive first, in `docs/constraints.md`) says to test first.
**Project state:** main at aaaacb80. The "Gloss every reference" rule (decision-log row 84, merged 2026-11-06) is live. Its falsifier watch (Q-264, in `docs/working/watching.md`) closed on 2026-11-11 with the falsifier not shown.
**Task status:** research complete. Outcome: no change for now (Path A, medium confidence): the evidence is too thin to act on. The item closes with a revisit trigger for the dev cycle to record. Review round 1 (an independent fact-check) is applied below.

Brief: `docs/working/briefs/2026-11-20-why-its-yours-constraint-research.md`. Research only: this doc is the whole output (acceptance criterion 4). The only commands run were `git`, `rg`, `grep` and reads (criterion 5; `grep -inE` is the failure-pattern lookup's prescribed form).

## What exists

- **The signal.** F-007 in `docs/working/feedback/philosophy-research.md` (2026-11-01, verdict fails): Q-133, an entry in the philosophy-research repo, cited H1 for Proof-mark changes. That repo's H1 covers changes of meaning, not of working status, so the entry should never have reached the owner. F-007's main complaint, in the owner's words, was different: the entry pointed at decisions D1–D16 inside a 566-line report "without giving links/pointers". The quote rule was one of its two suggested changes. The other was "each sub-decision in the entry or behind a line-anchored link". F-007 links no later entry.
- **The grammar** (`global-instructions/CLAUDE.md`, "Running questions document"): `- **Why it's yours:** <what only the user can decide — omit if obvious>`. It asks for no constraint and no quote. Three nearby rules already bear on F-007:
  - "Route, don't rank": "Before routing to `you: judgment`, check the item actually needs a human".
  - "Gloss every reference": a constraint number is named among the labels that must be "say[s] in plain words what each internal reference is and why it matters here", with a link to the defining doc.
  - "Answering costs one line": everything needed to act must be in the entry.
- **The dev cycle** (`skills/dev-cycle/SKILL.md`). The Rules' "Attention is the budget" sends mechanical findings to the roadmap. Only real choices become `you: judgment` entries, and each entry glosses its references and opens with `**If you say no:**`. Step 7's merge-entry body is mechanical: the full TIP, `--check`'s lines, and a note on each instruction, dot-path or gate-code path. Blocked and stopped entries quote the loop's marker, then gloss it. None of these bodies carries a "Why it's yours" line by rule. A merge entry's reason to reach the owner is the review policy or the self-merge floor, not a constraint.
- **`questions.sh check`** (`scripts/questions.sh`, `cmd_check`, lines 292–391) is purely structural. It checks UTF-8, the heading grammar, duplicate IDs, the route, the Opened date, the status, the file that matches the status and route, the watching file's `## Closed` placement and index freshness. It reads no entry body text. It is a gate only in this repo (`scripts/health-check.sh`). The global instructions say so: "elsewhere nothing runs it for you". In philosophy-research it runs only when a session follows the advice to run it before committing, so a rule there is not enforced.
- **Row 84** (`docs/decisions/log.md`) rejected a `check` rule for glosses. Its reason: "a regex can find a label but not judge its gloss". About a third of 21 labels were glossed already, and a check sees a marker only once it is filed.

## Motive (criterion 2, S5)

How "cites a constraint" was counted: every `Why it's yours` line in `docs/working/questions.md` and `docs/working/questions-archive.md` was grepped for `\b[HS][0-9]{1,2}\b` and for `constraint`/`constraints.md`. Every constraint-label hit in both files was also read in its context (71 lines: 69 in the archive, plus `questions.md:120` and `:182`, Q-323 and Q-333, which cite H1's stated exception as context, not as a routing reason), to find entries whose *routing reason* rests on a constraint outside the Why line.

How "covers" was judged: a citation covers the case when the thing the entry asks about falls under a clause of that constraint's text as written in `docs/constraints.md` at aaaacb80. The test is not whether the constraint is merely related. The citation passes only when one could point at the clause.

| Population | Count |
|---|---|
| entries in both files | 312 (6 live, 306 archive) |
| `you: judgment` entries | 247 (3 live, 244 archive) |
| `Why it's yours` lines | 153 (4 live, 149 archive; archive line 3147 matches the grep but is a table cell, not a Why line) |
| Why lines citing a constraint **by number** | **0** |
| Why lines naming constraints without a number | 5 (archive lines 3185, 3632, 6524, 6592, 7490) |
| entries whose routing reason rests on a specific numbered constraint anywhere in the entry | 2: Q-272 and Q-278 |
| of those, citations that do not cover the case | **0** |

The brief asks for a sample of at least 20 "if there are more". There are not more, so every case is listed:

- **Q-272** (archive 6522–6524, opened 2026-11-10, `confine-tests-fallback-run-or-refuse`). Its "Why it comes to you" paragraph quotes H2's text: "a ... degraded primitive refuses and names what went unenforced ... degradation only ever narrows access". Running tests under the weaker `unshare` is a degraded primitive that does not refuse. H2's clause names it, so the citation **covers**. The Why line says "an exception to a hard constraint, which only you grant". This entry already does what F-007 asks for.
- **Q-278** (archive 7481–7490, 2026-11-11, the same question returned with data). It paraphrases H2 in a gloss ("a degraded tool refuses and names what went unenforced"), and the case is the same, so it **covers**. The owner later withdrew it for other reasons: it was "not meaningfully answered", should be rewritten around the bwrap research, and had not named the test-confinement script.
- **Constraint-subject entries** (Q-155 at 3185, Q-200 at 3632, Q-281/Q-282/Q-283/Q-284 at 6921–7006). Their subject is the constraints doc itself (write it, ratify revision 3, keep, promote or drop S4, S8 or S10, add a fork rule). They cover the case by construction and are not at risk of F-007's failure. Q-269 (6592) asks about a constraint audit's scope and timing; its Why line is about promoting or dropping constraints in general, with no number.
- **Not routing reasons.** All other label hits are tiebreakers on a loop's pick (5977, 6047, 6357), the reasons a loop's design is safe (S1 out-of-scope findings, H1/H2 in merge notes), or false positives (`S3-F1` review finding IDs, `H2 ## Revisit triggers` meaning a level-2 heading, "S3 buckets").

**Reading.** In this repo the failure F-007 reports has not happened once in 247 judgment entries. The two entries that rest on a constraint both quote or paraphrase its text. Both were opened after the gloss rule landed (row 84, 2026-11-06), and Q-133 was opened before it. One reported instance in one other repo, 19 days old, is the whole signal. This count does not test the other repo, whose questions files are outside this brief's scope. S5 also says value in real use outside this repo outranks loop-internal metrics, so the in-repo zero does not refute F-007. It shows only that this repo gives no second case. The honest reading is "too little evidence to act", not "no motive", and the revisit trigger below keys on the outside repo.

## Invariants

- One source of truth for the entry grammar: the global instructions' "Running questions document" (S3). The dev-cycle skill points at it and never restates it.
- `questions.sh check` stays structural (row 84). A blocking check keys on something re-checkable from the artifact (H4).
- Always-loaded context grows by at most about 30 lines without a measured delta (S2). The global instructions are always loaded.
- Editing `global-instructions/CLAUDE.md` is an instruction-file change. Editing `scripts/questions.sh` or `skills/dev-cycle/` is gate code (GATE_CODE in `scripts/lib/dev-cycle-read.sh`). Either one is a review merge, which costs the owner a merge entry, a `merge-gate-` entry for gate code. Each reaches other repos only through a release paste.

## Prior art

- Row 84 / `docs/working/research-2026-11-06-owner-entry-gloss-rule.md`: the same kind of question, about references in owner text. It chose a written rule over a `check` rule and recorded a falsifier. Q-264 counted that falsifier on 2026-11-11, and it did not show.
- `docs/working/research-2026-11-11-self-answer-measure.md` §9.2 (lines 1450–1470) sketched an unbuilt "exceptions rule": an entry does not ask about an exception to a hard constraint that its writer recommends against; the cycle self-answers instead, and that self-answer "quotes the constraint line (G1)" in the final message. Its trigger was Q-272's answer. Q-272 was answered [1] "to start" (a provisional grant), and the sketch says "If the owner grants it, drop candidates [14] and [15]". So that idea already closed on its own condition. It is a neighbour, not this rule: it quotes in a self-answer, not in an entry's Why line.
- Idea-promotion research (`docs/working/research-2026-11-19-ideas-promotion.md`, row 6) lists this item with signal F-007, "unheld".

## Gotchas

- Failure-pattern grep: no matches found
  (`grep -inE 'questions\.md|questions\.sh|judgment|why-its-yours|miscit|misrout|constraint|gloss' docs/failure-patterns.md`)
- `rg` reads a flag-like pattern beginning with `routed|...` after `-E` as an encoding name. Use `grep -inE` as the workflow says, or `rg -e`.
- A regex for `[HS][0-9]` overcounts: review IDs (`S3-F1`), heading levels (`H2`) and cloud names (`S3 buckets`) all match. Any mechanical rule keyed on the label inherits this.
- Constraint labels are per repo. H1 here (gates run from an uneditable copy) is not philosophy-research's H1 (changes of meaning). A rule or check must read the citing repo's own `docs/constraints.md`.

## Divergent design (criterion 3)

**Diagnosis.** The failure is a writer's misjudgment ("this is the owner's because of Hn") that reaches the owner. Who could catch it: the writer while writing, a mechanical check after writing, the dev cycle before filing, or the owner while reading, which is the cost to avoid. Seeded constraints: S5 (motive), S10 (attention last), S3 (one source), S2 (context budget), H4 (judgment is a detector, never a gate), S6 (a call site that runs), S8 (small units).

**Candidates.**

| Option | Binds | Paths | Merge kind | Owner reading cost | Would it have caught Q-133? |
|---|---|---|---|---|---|
| **[1] Quote rule in the entry grammar** | every session in every repo, after a release | `global-instructions/CLAUDE.md` (one clause in "Gloss every reference" or the Why line's placeholder) | review (instruction file) | one merge entry and a release paste. Then each constraint-citing entry runs ~20–40 words longer (2 of 247 here) | only if the writer, while copying the clause, sees it does not fit. Otherwise the owner sees the mismatch faster but still pays the read |
| **[2] `questions.sh check` rule** | only where `check` runs: a gate here, nowhere in philosophy-research | `scripts/questions.sh`, `test/` | review, `merge-gate-` entry (GATE_CODE) | one gate-code merge entry and a release paste | no. `check` did not run there. It could test that a quote is a verbatim substring of that label's line in `docs/constraints.md` (re-checkable, so H4 holds), but not that the clause covers the case. That is row 84's limit again. Legacy entries need a date cutoff, and false positives come from `S3-F1` and `H2` |
| **[3] Dev-cycle pre-filing step** (re-read the cited constraint; drop or reroute the entry if it does not apply) | only the dev cycle, in every repo that runs it | `skills/dev-cycle/SKILL.md` | review, `merge-gate-` entry (GATE_CODE) | one gate-code merge entry and a release paste. Saves a read on each miscited entry | possibly. F-007 says the dev cycle wrote Q-133. But this is an LLM judgment (a detector under H4), and it restates the grammar's existing "check the item actually needs a human" rule, which Q-133 already failed. S3 counts against it |
| **[4] No change** | n/a | none | n/a | none now | no, but 0 of 247 entries here repeat the failure, and the two at-risk entries since the gloss rule both quote or paraphrase |

**What-if on the two leading options.**
- [1] What if it ships? It adds one clause to the gloss rule, which fires on about 1 entry in 100 here. Where the writer does not catch the mismatch while quoting, the owner still pays the read, though they spot the mismatch faster than today. What if it is wrong and miscites recur? Then the recurrence shows in the harness feedback files, which the owner already copies here, and [1] can be built then at the same cost.
- [4] What if miscites are common in philosophy-research and never reported again? The owner reported F-007 once, without being asked. The harness-feedback channel exists for exactly this, so a recurrence costs one more feedback entry, not silent drift.

**Pick: [4] no change for now (Path A, medium confidence).** The evidence is too thin to act on: one outside instance, no case in this repo's 247 judgment entries, and the only post-gloss-rule cases already quote the constraint. F-007's larger complaint, buried references, is addressed in part by row 84's rule. Q-264 found its falsifier not shown, but that count was made by the session that wrote the entries, covered only this repo, and was taken before the owner withdrew Q-278 (2026-11-18), in part for a missing reference. So that complaint is not settled either; it is row 84's watch, not this item. Every build option costs a review merge and a release paste (S10), and spending it on one instance ranks below the cheaper next step, a count in the outside repo. [2] and [3] also land in gate code to catch a case they would not have caught: [2] did not run there, and [3] repeats a rule Q-133 already broke. Runner-up: [1], in the smallest form below, if the trigger fires.

Smaller choices, one line each:
- Where a future quote would go: inside the existing "Gloss every reference" bullet, as "a constraint an entry cites as the reason it is the owner's is quoted, not just glossed". That adds no new bullet (S2). A quote inside an entry does not restate a rule, so S3 does not count against it.
- Whether to count philosophy-research's files: out of this brief's scope, so it is left to the revisit trigger.
- A merge-entry rule: not needed. Merge entries reach the owner by policy or floor, never by a constraint.

## Plan

Research only: write this doc, then, in the final change, set the brief's Status to done. Change no other path.

## Files read

Last verified: 2026-11-20
docs/working/briefs/2026-11-20-why-its-yours-constraint-research.md
docs/working/feedback/philosophy-research.md
global-instructions/CLAUDE.md
skills/dev-cycle/SKILL.md
scripts/questions.sh
docs/constraints.md
docs/decisions/log.md
docs/working/questions.md
docs/working/questions-archive.md
docs/working/watching.md
docs/working/research-2026-11-11-self-answer-measure.md
docs/working/research-2026-11-19-ideas-promotion.md
docs/working/idea-log.md
docs/failure-patterns.md
workflows/research-plan-implement.md
workflows/pr-prep.md

## For the dev cycle

**Close the roadmap Now item "A judgment entry's 'Why it's yours' quotes the constraint it relies on" with no build.** Reason: in this repo, 0 of 153 "Why it's yours" lines in 247 `you: judgment` entries cite a constraint by number. The two entries whose routing rests on a numbered constraint (Q-272, Q-278, both about H2's fail-closed rule) cover their case, and they already quote or paraphrase its text. The one reported miscitation (F-007's Q-133, philosophy-research) predates the gloss rule (decision-log row 84), which already asks each constraint number to say what it means. One outside instance is too little to spend a review merge and a release paste on.

Suggested record, for the cycle to write (`docs/decisions/log.md` is the cycle's file, not this loop's): a log row "no quote rule for constraint-cited routing", citing this doc. **Revisit trigger:** either a second harness-feedback entry, from any repo, reports a judgment entry routed by a constraint that does not cover it, or a session in philosophy-research runs this doc's audit on its own questions files and finds a second miscited entry there. When it fires, build option [1] in the smallest form above, as a review brief with Paths `global-instructions/CLAUDE.md`. No test is needed, since the change is prose in an instruction file, which the floor sends to review. The doc change is the clause itself. A count of philosophy-research's own `you: judgment` entries, the same audit as above, should come first if a session there can run it.
