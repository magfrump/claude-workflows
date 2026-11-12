# Research: a light pass between full dev cycles

Brief: `docs/working/briefs/2026-11-11-light-pass.md` (dispatch 1). Branch `feat/dev-cycle-light-pass`, base ee637249.

## What the owner chose

Q-270 [2] (archived in `docs/working/questions-archive.md`; owner's words in
`answers-11-11-26.txt`: "[2] seems low cost to do now, but agreed that [4] is warranted as
well"): a full cycle on each day's first iteration and whenever main gained anything but the
cycle's own land since the last full cycle; a light pass otherwise. [4] (token measurement)
is a separate roadmap unit, out of scope here.

Section 9 of `docs/working/research-2026-11-10-cycle-overhead-numbers.md` gives the cost of
[2] as the owner accepted it: what is not a commit on main (a model change, a release, a
dated trigger, a stale item) waits for the next day's first iteration; replayed, 4 of 22
catches waited, two really (1 h and 3.8 h). Section 7 says a rule must state whether the
health check stays.

## What the skill already reads

- Step 0.2's `--main-log SINCE` prints `main MAIN N`, then one `gate|chore|answers|other SHA
  SUBJECT` line per first-parent commit after SINCE, or `main MAIN -` and `refuse main-log:`
  (header of `scripts/build-loop.sh`, lines 145-186). SINCE is the newest record's last
  `Main at:` line, so the lines cover exactly what moved main since the last iteration that
  landed a record.
- Step 0.2 also names the newest record on the default branch, by file name date.
- Step 1's health check already skips itself when the previous `1.` line reads
  `passed at P` / `unchanged since P` and step 0.2 printed only `chore` lines.
- Step 5 runs only when one of its own triggers holds (most read from the digest).
- Step 4b's model trigger compares the current model with "the last record's `Model:` line".

**Why "since the last iteration" equals "since the last full cycle".** An iteration is light
only when 0.2 printed only `chore` lines since the previous landed record. By induction over a
run of light passes, main gained only cycle lands since the last full one. A stop before
step 9 lands no record, so the next iteration reads from the same `Main at:`. A merge that
step 7 of a light pass makes moves main after its `Main at:`, so the next iteration sees a
`gate` line and runs full.

## Gotchas

- Failure-pattern grep: FP-125, FP-177, FP-178, FP-179, FP-180 (keywords `light-pass|skip-if-present|dev-cycle|cycle-record`)
  - FP-125 (a skip-if-present state reported a previous run's score): the old ad-hoc light
    passes wrote "as 2026-11-02-0718" for steps 2 and 3, a stale value dressed as a verdict.
    The new rule records `skipped: light pass (REASON)` and an empty `### Trigger verdicts`
    instead, so nothing reads a repeat as a fresh check.
  - FP-177 to FP-180 are dev-cycle skill fixes about identity, the release paste and a test
    fixture; none touches step selection. Noted only because the grep matched `dev-cycle`.
- A light pass writes the record's `Model:` line too. Left as it was, 4b's model trigger would
  compare a later full cycle against that light block, and a model change first seen by a light
  pass would never fire. Fixed: 4b compares against the last block whose `4b.` line is not
  `skipped: light pass`.
- Records written before this change: old light passes wrote `4. spot-check: skipped: light
  pass.`, so the light-block test (a `4.` line reading `skipped: light pass` right after its
  label, a prefix match) reads them as light. Full cycles also write `4. spot-check: skipped:
  no new merge`, so the test keys on the light-pass prefix, not on `skipped` (review round 1,
  A1).
- `AGENTS.md` and `global-instructions/CLAUDE.md` say "every revisit trigger". That means every
  trigger in a cycle that checks them, not every iteration, and both are instruction files
  (on the self-merge floor and loaded every session). Left as they are.
- Decision-log row 72's D12 ("one full cycle per iteration under `/loop /dev-cycle`") and the
  plan `docs/working/plan-build-loop-handoff.md` D12 still say a full cycle per iteration. The
  log is a decision record and the plan a working doc not this loop's, so both are off limits
  here. Q-270 replaces D12's answer; whether to add a log row is for the cycle to file.
- No doc in `workflows/`, `guides/` or `docs/` (outside working docs and records) names the
  four steps as "every iteration"; the one statement was the skill's own intro ("checks all of
  them every time"), now changed.

## Design choices

Seeded with `docs/constraints.md` (H1-H4, S1-S11) and the brief's own criteria (fail toward
the full cycle; decide from what the cycle already reads; under ~400 lines).

### DD-1: what counts as "main moved" (3 options)

| Option | Full cycle on | Fit to the rule | H2 (fail toward full) | Cost |
|---|---|---|---|---|
| **A. any line but `chore`** | `gate`, `answers`, `other`, a `refuse`, the bootstrap | The rule's words ("anything but the cycle's own land") and the replay's rule, as the owner read it | Yes | A few more full cycles: an owner answer commit runs one |
| B. `gate` and `other` only | not `answers` | Departs from the words; an answer can release a watch or fire a trigger (2026-11-07-0500's trigger fired on owner feedback) | Partly | Fewer full cycles |
| C. `gate` only | not `answers`, `other` | Departs further: a hand commit is exactly the change no gate read | No | Fewest |

Path A: option A. It is the rule as answered, it is the replay the owner saw, and the others
trade catches for a saving that is unmeasured (S7). A `refuse main-log:` line or the bootstrap
is "cannot be read": full (the brief's fall-through).

### DD-2: steps outside the four (health check, 1b, 5, 6) in a light pass (3 options)

| Option | Effect | Assessment |
|---|---|---|
| **A. run every other step as written** | Health check skips itself on chore-only lines unless the last one failed; step 5 runs only on its own triggers | Under DD-1 A a light pass sees only chore lines, so the health check's existing skip already applies; it re-runs only after a failure, when re-running is wanted. Step 5's "Now has 0-1 ready items" trigger is what keeps slots filled. 1b runs before collect by its own rule ("catching up comes before continuing"); 6's In flight checks feed step 8. |
| B. skip step 1 and step 5 too | Cheaper on paper | Drops worktree freeing, branch cleanup and `questions.sh archive`, which collect and dispatch rely on; leaves slots empty when Now runs dry. |
| C. skip only the health check and step 5 | In between | Saves nothing the self-skip does not already save, and loses step 5's refill. |

Path A: option A. It adds no rule (S3), and the two steps already gate themselves on the
same condition.

### DD-3: where the decision lives (3 options)

| Option | Size | Takes effect | Constraints |
|---|---|---|---|
| **A. a short rule in the skill (step 0.5)** | ~17 lines of prose plus one bats case | With the skill | Two comparisons over lines the model already reads by position (H4: inputs re-checkable from the record and the `--main-log` lines; nothing is judged). S8, S3 |
| B. a mode in `scripts/build-loop.sh` | small mode plus tests, in a 2505-line file | Only after an image release (it is gate code run through d6); until then the skill must fall through to full | S4 favours it; S8 (no growth of big files), S10 (a release step) against |
| C. a "Pass:" line in the digest (`scripts/dev-cycle.sh`) | the digest does not run `--main-log`; it would need the classes re-derived | After a release, as B | S3 against (a second reader of main's classes) |

Path A: option A. The brief prefers a script "only if it stays small"; here the decision is
two comparisons on data already printed, and a script would add a release dependency and a
second path for the same classes. A light pass is a cost-saving pre-step, not a gate: a wrong
call can only run a full cycle when a light one would do (or the reverse, which the record
line shows and a later full cycle repairs), so H4's enforcement rule does not bind it.

### Small choices (one line each)

- The day test uses the newest record's file name against `date +%F` (local), as the record
  itself is dated, and needs a full block in it, so a record holding only light blocks (not
  reachable today, but cheap to rule out) does not count.
- No model or release input: the owner accepted that these wait for the day's first
  iteration (Q-270's "If it's wrong" column); adding one would change the rule as answered.
- The skill's frontmatter description is unchanged: it names the steps a cycle can run, and
  is always loaded (S2).

## Plan

1. `skills/dev-cycle/SKILL.md`: intro sentence; Flow note; step 0.5 rule; 4b's model trigger;
   record template's `4b.` line; step 9's "one verdict for every trigger" scoped to a full
   cycle.
2. `test/scripts/build-loop-orchestrator.bats`: one case pinning the rule's lines, 4b's
   trigger, the template line and the removed "every time".
3. Tests: `scripts/confine-tests.sh --probe` exits 3 here (first line: "confine-tests: NO
   CONFINEMENT PRIMITIVE AVAILABLE — refusing to run."), so `scripts/run-tests.sh` plus
   `scripts/hermeticity-lint --root .`.

Test strategy: the change is prose in the skill, read by the model; the only machine check
is the pinning case (the house pattern for skill rules), which fails if a line of the rule
is reworded away. No script changed, so no behavioural case applies.

## Review-fix loop

Round 1 (one general-purpose reviewer on the diff, read-only):

- M1 fixed: the record template's change moved the record convention's fingerprint, so
  `test/scripts/convention-migrations.bats` refused it. Added the registry line
  `record-light-pass` (no remedy: every record written before stays valid) to
  `scripts/lib/migrations.sh`, as `record-1b-ran` and `record-8-free-slot` did. That file is
  gate code (`scripts/lib/`), so the merge entry is a `merge-gate-` one; the line is data
  the registry check reads, not logic.
- A1, A2 fixed: one definition of a light block (its `4.` line reads `skipped: light pass`
  right after its label) in step 0.5; 4b's model trigger and step 9's reading list name
  "the last full block".
- A3 fixed: step 9's record-reading list names verdicts and `Model:` from the last full
  block, and the `4.` line step 0.5 reads.
- N1, N4, N6, N3 fixed (0.4 dropped; template shows the `4.` line; a line count other than
  N is unreadable, so full; a midnight-crossing iteration counts for the new day). N2: the
  rule now says "the brainstorm" rather than "step 5" next to "step 0.5". N5: another
  session's cycle land counts as `chore`, now stated.

Round 2: the targeted suites (convention-migrations, build-loop-orchestrator,
questions-doc: 106 cases) pass; `scripts/lib/migrations.sh check .` exits 0.

Final gate: `scripts/confine-tests.sh --probe` exit 3 ("confine-tests: NO CONFINEMENT
PRIMITIVE AVAILABLE — refusing to run."); `scripts/run-tests.sh` on e4b00ebc: 2052 of 2052
ok, exit 0; `scripts/hermeticity-lint --root .`: exit 0.

Failure-pattern skip: the branch has no fix(...) commits; round 1's registry miss was caught in review before merge, and the brief named the SKILL.md-pinning tests but not the registry check, a brief-scoping gap rather than a code bug.
