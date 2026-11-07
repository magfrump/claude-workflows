# Research: write the first trial set's practices into the dev cycle

**Goal**: make T1 to T7 of `docs/working/trials/2026-10-30-friction-engagement.md` standing dev-cycle behaviour, each written once where its writer meets it, with no dependence on a session reading the trial doc.
**Problem framing**: the practices live only in a doc the skill does not name, and a new trial set is taking that doc's place in the final message, so they will quietly stop. Considered and discarded: "the skill needs a new owner-facing-writing chapter" (that restates rules away from the moment they apply, and the owner's feedback says T3 and T4 earn little).
**Project state**: this branch delivers the skill text and a small gate change for the weekly path · standalone, under the dev cycle's trial close-out · not blocked (cite: docs/working/briefs/2026-11-06-codify-trial-practices.md)
**Task status**: in-progress (research done, implementing)

## What exists

- `skills/dev-cycle/SKILL.md` is the orchestrator's whole procedure, and is gate code (GATE_CODE, so this branch is a `merge-gate` entry). [observed] Rules at lines 21-100; step 0.1 writes the `image-lag` entry, also the release entry; step 1 triages the health check log; step 3 closes watches; step 7 writes merge entries; step 9.1 stages and 9.3 holds the merge-answer rule; "Final message" closes the file.
- `scripts/lib/dev-cycle-read.sh` `writable()` is the single list of the cycle's own files. [observed] It feeds `--check-write` (`scripts/dev-cycle.sh`), and `truthrule`'s `cycle` word, which feeds `--check-fix`, `cycle_rules` (`--cycle-diff`, `--land-cycle`) and `nrules` (a loop may not touch them under either policy).
- `cycle_rules` in `scripts/build-loop.sh` passes any `.md` under `docs/` that no other rule refuses. [observed by reading] So `docs/working/weekly/DATE.md` already lands through the gate. What stopped it is the skill's staging rule ("only the cycle's own files and the paths `--check-fix` printed `ok` for") and `--check-fix`, which refuses `docs/working/`. `--check-write` is no longer called by the skill (brief 2026-11-01-relax-dev-cycle-skill-prose), so the trial doc's orchestrator note names a check the skill does not run any more.
- Section 8 of the digest lists non-plain inputs. The skill promises it "names any of their directories that is not plain" (line 141), so a new own-file directory needs a `skipdir` line in `scripts/dev-cycle.sh`.
- `docs/working/weekly/2026-11-06.md` is the template in practice: security heading, what changed (live and not live), self-merges, security reviews, ask counter, stale entries, random sample.
- The "Gloss every reference" bullet (the global instructions, merged at 771c84e8) is already pointed at from the skill's Rules and final message. `test/questions-doc.bats` pins both pointers.

## Invariants

- `--cycle-diff` refuses a change to an open entry's **Needs:** line (which holds Status) without `--answered`, except `image-lag` and migrations. [observed: header at `scripts/build-loop.sh` lines 196-216] So the cycle cannot close a `you:` entry itself, whatever its closure line says.
- A cycle file never takes an earlier `truthrule` word. [observed: comment above `truthrule`] A dated `.md` under `docs/working/weekly/` matches neither `isstart` nor a dot part.
- Step 0.1's GATE_CODE path line and the `**Final message**, then wait. Gloss every reference in it` line are pinned by tests. [observed] Neither moves.
- The entry grammar's first body line is the one-line question, and step 7 puts its own question line under **Needs:**. T2's line goes right after it. [observed: Q-261's layout]
- The image lags main: a gate change here runs only after the next release. [observed: SKILL Rules] The weekly route must work before then, and does, since the image's `--cycle-diff` already passes the path.

## Prior art

- Step 3's watch close and the roadmap's agent items are where T4's closures now happen. Both precedents were not owner entries: Q-074 was a `trigger`, Q-108 was `agent`. [observed: `docs/working/questions-archive.md`] Decision 040 moved those routes out of `questions.md`, so "the cycle closes an entry" is already built, for the entries it may close.
- `isrecord` and `isbrief` are the shape of a dated own-file predicate; `isweekly` copies `isrecord`.
- Log row 84 is the record for the sibling gloss rule; a row here matches it.

## Gotchas

Failure-pattern grep: FP-021, FP-063

- FP-021 and FP-063 matched on the word "writable" alone: an agent-writable file baked into an image, and a non-writable TMPDIR. Neither bears on this work.
- The brief asks that `docs/dev-cycle.md` agree with the change, but the N rules refuse a branch touching it and this loop's dispatch forbids it. Its text stays true in substance: line 55's "the release entry flags self-merged subjects" still holds, since T1 keeps every self-merge listed. Its line 31 lists the cycle's own files without `docs/working/weekly/` (it already omits `watching.md`). That small update is left to the cycle or the owner, and is in the marker.
- Dropping the commit list from the release entry weakens nothing the owner used (T1 feedback: not read thoroughly), but `docs/dev-cycle.md` calls that entry the check on self-merged scripts, including `install.sh`. So the self-merge list and the paths line stay whole. The wider point, that this check is weaker than the file assumes, is in the merge-friction record's section 12 and is not this brief's.
- T6's first trigger is narrower than when the trial began (`--state` refuses only a shallow or partial clone, a default branch that is not one plain main or master, or a `GIT_DIR`-style variable). The skill also says a stop is not called hostile, so the marker text says what happened, not who did it.
- "Push notification" has no tool named in the skill, and none is guaranteed in a session. It is written as "when the session has a tool for one", so nothing silently depends on it. [assumed: the orchestrator has one, since the trial said so; no record shows a firing]

## Divergent design

Prior pruning grep: no matches found for [weekly, digest, own files] in `docs/decisions/`; the trial doc's 2026-10-30 note is the prior input.

### D1: how the weekly digest reaches the land (T5)

Candidates: **[0]** status quo, its own docs commit outside the land. **[1]** Skill text only: call it a cycle file, since the gate already passes it. **[2]** Add it to `writable()` too, with a digest check, and say so in the skill. **[3]** Name it under `docs/working/cycles/` as `weekly-DATE.md`. **[4]** Fold it into the day's cycle record. **[5]** Drop the file: put it in the final message.

Constraints (from `docs/constraints.md` and the brief): H1 (a new gate path is in GATE_CODE: `scripts/lib/` is); H2 (a new failure path has a bats case); H3 (hermetic tests); S3 (one source of truth per rule); S4; S8 (small, one revert); S10 (no chore, no `other` commit each week for the owner to read); brief: a path the land may write, kept small; owner: "the location is accessible".

| | H1-H3 | S3 one list | S10 no weekly `other` commit | S8 small | Readable where it was |
|---|---|---|---|---|---|
| [0] | pass | pass | fail | pass | pass |
| [1] | pass | fail: the skill calls it the cycle's, `writable()` says not, and a loop could edit it | pass | pass | pass |
| [2] | pass | pass | pass | pass (about 4 code lines) | pass |
| [3] | pass | pass, but `isrecord` and the digest's date reading need a second pattern there | pass | fail: moves two editions and their links | fail |
| [4] | pass | pass | pass | pass | fail: buried in an append-only daily file |
| [5] | pass | pass | pass | pass | fail: gone after the message, and the sample link needs a home |

Stress test on [2]: the image lags, but its `--cycle-diff` already passes the path, so the route works before the release. A case-variant path is refused by the cycle rule. A loop that writes a digest is refused under the N rules, which is right: the digest describes the loop's own work.

**Decision: [2], Path A.** One soft cost: `docs/dev-cycle.md` line 31 goes a little staler until someone may write it.

### D2: where the practices are written

Candidates: **[a]** each inline at the step that writes the text. **[b]** one new "Owner-facing writing" section in the skill. **[c]** a reference file beside the skill. **[d]** the global instructions' questions section.

[a] is what the brief's "written once, where its writer meets it" (S3, S4) asks, and adds no always-loaded lines. [b] sits away from the step and invites restating. [c] adds an indirection and a read for text that runs in almost every iteration; it would only pay for the weekly template, which is about 15 of 880 lines. [d] spends always-loaded context (S2) in every session of every repo, for practices only the cycle's own text uses; Q-255, filed by hand, is the one entry that missed T2, and it is not a reason to pay that.

**Decision: [a], Path A.**

### D3: the commit list in the release entry (T1)

Candidates: **[i]** keep every first-parent commit (today). **[ii]** self-merges in full, what changes in plain lines, the rest a count, plus the log command for anyone who wants the whole list. **[iii]** the same with no command. **[iv]** a link to the weekly digest in place of notes.

[i] is what T1 replaced, and the 2026-11-06 digest counts it as the miss (Q-252 still carried 19 commits). [iii] drops a free escape for "did you miss the full list". [iv] fails between editions. F58 needs the unreviewed part whole, which [ii] keeps.

**Decision: [ii], Path A.**

## Where each practice now lives

- **T1 release notes, one paste:** step 0.1, in the `image-lag` paragraph, since that is where the entry is written. It also carries the trial's lesson that a rewrite reads `.manifest` and no older text.
- **T2 asks read cold:** "If you say no:" is in the Rules' "Attention is the budget" bullet, because every owner entry is written under it, and that bullet already points at "Gloss every reference" for the jargon half (not restated). The attacker line is in step 7's merge-entry paragraph, the only writer of `merge-gate-` entries, and names outside parties only.
- **T3 batched answers:** the offer is in the final message; the rule is in step 9.3, the merge-answer rule. Two sentences, kept cheap, since the owner says it targets no big blocker.
- **T4 stale sweep:** one bullet of the weekly digest's list. Closing needs no new text for watches and agent items (step 3 and the roadmap already do it). A `you:` entry whose closure line is met gets "close" as its proposed fate, as the gate refuses a cycle close and the global rule forbids closing by inference. Nothing new runs each iteration, per the owner's "no change to the interface will change what my priorities are".
- **T5 weekly digest:** a paragraph at the head of step 9, plus D1's gate change.
- **T6 security marker:** the final message's paragraph, where it fires. The digest list reports the count.
- **T7 recurring warnings:** step 1, beside the health-check triage, where the warnings are read. Filed as agent work, so no owner cost.

Observable (S6): each edition's ask counter and `⚠ SECURITY` count, and whether the next release entry stays short. It can come out negative: a release entry that regrows a commit list, or a week with no edition, is visible in `docs/working/weekly/` and the questions file.

Other choices, one line each: the T4 and "weekly due" checks stay prose rather than digest code (S4 weighed: the brief says keep T4 cheap, and the due test is one directory listing). No new record line: the digest shows under `### Paths landed`, so the record's shape, a convention with migrations, does not change. Trial notes under `docs/working/trials/` stay outside the land (the brief asks only for T5).

## Files read

Last verified: 2026-11-06
docs/working/briefs/2026-11-06-codify-trial-practices.md
docs/working/trials/2026-10-30-friction-engagement.md
docs/working/research-2026-11-06-merge-friction-design.md
docs/working/research-2026-10-29-session-answers-for-merge-entries.md
docs/working/weekly/2026-11-06.md
docs/working/questions.md
docs/working/questions-archive.md
docs/roadmap.md
docs/dev-cycle.md
docs/constraints.md
docs/decisions/log.md
docs/failure-patterns.md
skills/dev-cycle/SKILL.md
scripts/build-loop.sh
scripts/dev-cycle.sh
scripts/lib/dev-cycle-read.sh
global-instructions/CLAUDE.md
workflows/research-plan-implement.md
workflows/pr-prep.md
workflows/review-fix-loop.md
workflows/divergent-design.md
test/scripts/build-loop-orchestrator.bats
test/scripts/build-loop-check.bats
test/scripts/dev-cycle.bats
test/questions-doc.bats
