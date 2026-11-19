# Research: dev-cycle section 5 follow-ups (R5, A11)

**Goal**: Section 5 of the digest never shows an item an open watch holds as unheld, and the wording and tests split off as A11 match the code.
**Problem framing**: R5 is a fail-open branch in section 3 (a missing live questions file read as "nothing is open" though `watching.md` can hold open watches); considered and discarded: reading `watching.md` directly in that branch, since `questions.sh open` refuses a missing live file and a second parser of the watch grammar would break the one-source rule (constraint S3).
**Project state**: follow-up to `fix/dev-cycle-roadmap-staleness`, split at its review cap · standalone · not blocked (cite: docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md)
**Task status**: complete (implemented, tested, mutation-checked; review-fix loop run)

Brief: `docs/working/briefs/2026-11-18-section5-followups.md` (at 34bbbe89).

## What exists

- `scripts/dev-cycle.sh` section 3 sets `open_ok=0; open_q=""`, then branches: skipped live file, no live file (`open_ok=1`), `questions.sh` missing, skipped archive, skipped `watching.md`, else both `qopen` calls (`open_ok=1` when both succeed). `qa_at`/`qw_at` are computed up front through `skipped` (the lib's `blocker` walk), so a non-plain path is caught before any test follows a symlink.
- Section 5 prints the NOT-checked line unless `open_ok=1`, else one line per first-Now/first-Next column-0 item: `- Now N · open: … · "TITLE"` or `- Now N · no open entry or watch names it · "TITLE"`.
- The items awk extracts IDs only as `/Q-[0-9]+/` after mapping tab and 0x1f to a space, so the IDS field can hold only `Q-` plus digits; the `read -ra` split and the `^Q-[0-9]+$` recheck are a second guard no roadmap text can reach while the mapping stands (fact-check final r3, claim 31).
- `questions.sh` (`LC_ALL=C` exported) already cuts summaries at a byte count and drops a trailing split sequence with `sub(/[\302-\364][\200-\277]*$/, "", summary)` (`scripts/questions.sh:236-248`).
- Skill step 3 lists the causes of "Watched questions were NOT checked"; step 6 already says no item moves on account of section 5's NOT-checked line.

## Invariants

- Section 5's line shapes (step 6 reads them) and the record template (fingerprinted by `scripts/lib/migrations.sh`): unchanged. Step 3's prose is not in a fingerprinted convention, so no `record` registry line.
- No test follows a symlink before `blocker` has walked the path (section 3's header comment).
- A repo with neither questions file still lists every item as unheld (test "section 5 lists every item as unheld when the repo has no questions file").

## Prior art

- R4 of the earlier branch added the no-file `open_ok=1`; R5 narrows it.
- FP-170: the same multibyte cut, fixed the same way in `questions.sh`.

## Gotchas

- Failure-pattern grep: FP-033, FP-035, FP-037, FP-038, FP-042, FP-045, FP-048, FP-081, FP-087, FP-090, FP-092, FP-094, FP-100, FP-102, FP-131, FP-151, FP-157, FP-168, FP-170, FP-183 (see Prior failures section)
- Criterion 3 as written ("revert to `for id in $ids` and the test fails") cannot hold with the real script: the 0x1f mapping keeps every `*` out of IDS, so the loop alone is undetectable. The test therefore also runs a copy of `scripts/` with the 0x1f mapping removed (a `sed` on the copy, refusing if nothing changed), where the `*` does reach IDS and only `read -a` plus the recheck keep the tracked file `Q-001` (an open entry's ID) from printing as a hold.

### Prior failures

`grep -n -i -E 'multibyte|cannot-fail|guard-misses|missing-file|absent-file|unread' docs/failure-patterns.md`. Most hits are the generic `guard-misses-subject` cause. The ones that bear here:
- FP-170: truncation splitting a multibyte character made grep read a file as binary; the same holds for the digest, so the cut now drops a split sequence.
- FP-168: an assertion that cannot fail; test 97's glob half was one.
- FP-183: a guard keyed on something its input never carries; here the read-a guard sat behind a mapping that made it unreachable.

## Design choices

- R5 (two viable options: report NOT checked, or read `watching.md` some other way): the brief prescribes NOT checked; reading watches without a live file would need a second parser or a `questions.sh` change. Path A, NOT checked. The condition is `[[ -n "$qw_at" || -f "$QW" ]]`: with `qw_at` empty, `blocker` found no symlink on the path, so `-f` follows none.
- "First 80 characters" (two options, the brief's call): fix the cut rather than reword only, since a split character is invalid UTF-8 and grep then reads the digest as binary (FP-170). The items awk runs under `LC_ALL=C` (bytes under any awk) and reuses `questions.sh`'s `sub`; the `sub` drops only a trailing lead byte whose continuation bytes are missing (review round 1: `questions.sh`'s `[\302-\364][\200-\277]*$` ate the last whole character of every non-ASCII title, cut or not), so a whole character always stays, and the comment says "first 80 bytes, cut back to a character boundary". A length guard was tried and dropped: with this regex it changes nothing a test could see. A symlinked or other non-plain `watching.md` with no questions file prints section 3's skip note, since `questions.sh init` refuses to write through a symlink.
- Test 97's glob half (options: the real script only, which cannot fail; a mutated copy without the 0x1f mapping; extracting the loop into a function, which grows a 695-line file; dropping the guard, out of scope): one dominates under the brief's "confirm by reverting" criterion, the mutated copy. Path A.

## Plan

1. `scripts/dev-cycle.sh`: R5 branch before the no-file branch; comment fixes; `LC_ALL=C` and the split-sequence `sub` in the items awk.
2. `skills/dev-cycle/SKILL.md` step 3: add the new cause to the NOT-checked list.
3. `test/scripts/dev-cycle.bats`: R5 test; second Next heading in the first-heading test; glob half with an open `Q-001`, a no-bold `*` item, and the mutated-copy run; multibyte cut test.
4. Docs: the earlier plan's step 1 shape and research line 35.

## Verification

- `bats test/scripts/dev-cycle.bats test/scripts/convention-migrations.bats`: 114 ok.
- Review round 1 (fresh reviewer): one must-fix (the greedy `sub`), two should-fix (the non-plain `watching.md` message and its missing test), nits; all fixed, with tests for a short non-ASCII title, cuts on and inside 2-, 3- and 4-byte characters, and a dangling-symlink `watching.md`. Mutations of the round-1 code: the old greedy regex, no `sub`, and dropping `-n "$qw_at" ||` each fail a test.
- Mutations, each in a scratch copy of `scripts/` and `test/` (the section 5 tests only): `for id in $ids` loop → test 9 (glob) fails; R5 condition removed → test 8 fails; split-sequence `sub` removed → test 10 fails; `!seen_next` guard removed → test 4 fails.

## Files read

Last verified: 2026-11-18
docs/working/briefs/2026-11-18-section5-followups.md
docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md
docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness-final-r1.md
docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness-final-r2.md
docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness-final-r3.md
scripts/dev-cycle.sh
scripts/lib/dev-cycle-read.sh
scripts/lib/migrations.sh
scripts/questions.sh
skills/dev-cycle/SKILL.md
test/scripts/dev-cycle.bats
docs/working/plan-2026-11-18-roadmap-staleness.md
docs/working/research-2026-11-18-roadmap-staleness.md
docs/failure-patterns.md
hooks/live-verify-gate.sh
