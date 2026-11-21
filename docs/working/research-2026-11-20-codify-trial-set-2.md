# Research: write trials T9, T11 and T12 into the dev-cycle skill

Brief: `docs/working/briefs/2026-11-20-codify-trial-set-2.md` (read at b7663bf2).
Branch: `feat/codify-trial-set-2`. Policy: review.

Failure-pattern grep: `grep -n 'cause:vacuous-assertion' docs/failure-patterns.md` (the pin tests are text assertions; FP-119, FP-137 and kin: a pin that passes without examining the change). Applied by running the new pin test against the old `SKILL.md`: it fails (`missing: Links to the docs most worth opening ...`), so it is armed.

## What was read

- The trial doc `docs/working/trials/2026-11-06-attention-and-trust.md`: rows T9 (further reading, at most two links), T11 (one deliberate look a week, with a count) and T12 (what the checks caught), and its Feedback section.
- Q-327's archived entry (`docs/working/questions-archive.md`, answered `[2] T9 T11 T12`) and the owner's words in `docs/human-author/answers-11-20-26.txt` (commit 7df4654d).
- The first set's codifying brief `docs/working/briefs/closed/2026-11-06-codify-trial-practices.md` and its merge 3dbf43cb9: each practice written once where its writer meets it, and a bats test in `test/scripts/build-loop-orchestrator.bats` pinning the wording per step.
- `skills/dev-cycle/SKILL.md`: the Rules' "Attention is the budget" bullet, step 9's weekly digest bullets, and the "Final message" paragraph.
- The 2026-11-20 weekly digest (`docs/working/weekly/2026-11-20.md`), which ran T11 as a self-merge sample and T12 as written: its "What the checks caught" section and its "Your asks this week" table, the shape the owner held up as a good trust answer.
- `docs/constraints.md`: S3 (one source of truth per rule), S10 (spend the owner's attention last), S2, S4.

## Context

- Invariants: the entry grammar lives in the global instructions ("Running questions document"); the skill points to it and must not restate it (S3). The first set's pin test pinned "one self-merge picked at random", which T11 replaces, so that pin moves into the new test.
- `docs/dev-cycle.md` does not describe the digest sample or final-message links (grepped), so no doc there disagrees; the brief forbids editing it anyway.

## Design choices (none has 3+ viable options, so no divergent-design pass)

- **T9, where links go in an owner entry.** The brief says entries "end with links". The global entry grammar already has a `**Read:**` line for links. Options: use the `Read:` line, or add a second closing link line. The `Read:` line dominates (S3: one grammar; a second link line would restate it and could clash with `questions.sh check`). Decided: links go in the `Read:` line, written once in the Rules' "Attention is the budget" bullet, which every entry and the final message already follow; the Final message paragraph points to it.
- **T9, the cap.** The owner said more than two is fine when appropriate: "as many as help: no fixed count".
- **T11, what counts as a design pick.** One line: a divergent-design decision in a research doc merged that week, so the pool is re-checkable from history like the self-merge pool.
- **T11, the count.** Per the brief: from answers in the questions files or the owner's words in session, else "not counted". The digest's existing reply (`sample: fine`) is a session answer, so it is counted when it shows.
- **T12, placement.** Next to the ask counter, the section the owner named as the model; each line names a refusal line, a red row's file, or a count with its reproducing command (the owner's chain-of-trust note).

## Doc change

- `skills/dev-cycle/SKILL.md`: T9 in the Rules' "Attention is the budget" bullet and the Final message's pointer; T11 replaces the random self-merge bullet in step 9's weekly digest (and the intro's "optional sample" becomes "optional look"); T12 is a new digest bullet.
- `docs/working/trials/2026-11-06-attention-and-trust.md`: the owner's 2026-11-20 feedback under `## Feedback`, and an outcome line saying T9, T11 and T12 are now in the skill and T8 and T10 ended.

## Tests

- `test/scripts/build-loop-orchestrator.bats`: a new test pins T9, T11 and T12's wording at the steps that write them, checks "at most two links" and "one self-merge picked at random" are gone, and that the skill does not name the trial doc; the first set's test drops its now-replaced pin.
- Results are recorded in the commit bodies.

## Review round 1 (fresh reviewer, no reds)

Ambers fixed in the skill: the final message's links come ahead of the Wait paragraph's closing line; T11's look names its reply (`look: fine`), the count reads past editions' offers, and the design-pick pool adds `docs/decisions/` records and falls back to a self-merge when empty. Nit fixed: "finds links most valuable".

Left, with reasons:
- `docs/audiences/owner.md:40` still says a final message "gives at most two links (trials T8, T9 ...)". That file is the owner's ratified profile (0e95e3f2, Q-299), so this loop does not edit it; the cycle should offer the owner a one-line edit.
- T12 residual: the skill makes each caught-line name a fact the owner can check, as the brief's criterion 4 asks. The owner's own model was numbers they have already seen (the asks table); whether checkable-but-unseen facts answer the chain-of-trust note is for the next digests to show.

