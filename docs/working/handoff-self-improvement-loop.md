# Handoff — what to do with `scripts/self-improvement.sh`

**Written:** 2026-09-17
**Status:** Decision open. Investigation and cheap fixes complete; the substantive
call is deliberately not made.
**Start here in the next session.** Read this file first, then
`docs/working/dd-self-improvement-loop-future.md` (the divergent-design run, 728
lines) — but read §3 of this file before trusting the DD's recommendation.

**Relevant paths:** `scripts/self-improvement.sh`, `scripts/lib/si-*.sh`,
`scripts/archive-working-docs.sh`, `guides/validation-gates.md`,
`docs/decisions/005`, `010`, `020`, `030`, `031`, `docs/working/archive/*round-*-report.json`

---

## 1. The question that started this

Three questions were asked of `scripts/self-improvement.sh`:

1. Is it up to date?
2. Is it a better mechanism for organizing autonomous improvement of this repo
   than an autonomous session without that structure?
3. Is it better as a *script* than as a workflow/skill/template an agent follows?

Q1 is answered and the cheap parts are fixed. Q2 and Q3 are open, and the basis
for answering them changed late in the session — see §3.

---

## 2. What was found and fixed

### 2.1 Q1 — the code is maintained, the scaffolding around it had rotted

The script itself is in working order: 197 SI-related bats tests across 14
suites, shellcheck clean, and it has tracked repo moves correctly (`REPO_DIR`
derives from `$SCRIPT_DIR`; Gate 1d was re-keyed to `*/CLAUDE.md` when the
instruction file moved to `global-instructions/`). Headless `claude -p` — the
primitive the whole loop is built on — was smoke-tested in this sandbox and
works.

Four staleness findings; all but the last are now fixed.

| # | Finding | Status |
|---|---|---|
| 1 | `archive-working-docs.sh` archived the loop's cross-run memory (`completed-tasks.md`, `problem-history.json`, `round-history.json`) — all three silently re-initialize empty, so the next run would start amnesiac and re-propose completed work | Fixed `84350f0` |
| 2 | `guides/validation-gates.md` documented 7 gates; the script has 8 (Gate 1h, added 2026-07-22 by decision 020, never documented). Also stale line-number pointer and a root-path `CLAUDE.md` reference | Fixed `d224ad5` |
| 3 | `workflows/workflows` was a git-tracked **dangling** symlink to a pre-relocation path | Fixed `d317721` |
| 4 | `guides/cross-project-setup.md:40` lists four scripts deleted by decision 010; `guides/subtraction-checklist.md` is built on per-task falsifiable hypotheses that decision 010 removed | **Open** — deliberately left, since both become moot under some options in §4 |

Fix 1 is load-bearing for the decision itself: `archive-working-docs.sh` prunes
the round reports that §2.2's measurement rests on. **It is now landed and
separate from any deletion, which was the required sequencing.** If the loop is
retired, do not undo this fix in the same change — it protects the evidence base
for revisiting the decision later.

### 2.2 Q2 — what the gates are actually worth (this measurement survives everything else)

Measured across the archived corpus — **55 round reports, 343 task validations**
— and independently re-verified:

| gate | fails | reading |
|---|---|---|
| self_eval | 41 | all prose-quality scores on markdown output |
| shellcheck | 17 | 8 of them on the SI infrastructure's own files |
| schema | 16 | gate 2b, task-JSON validation |
| file_scope | 14 | loop-shaped by construction |
| commits | 9 | loop-shaped by construction |
| tests | 8 | the baseline-isolation gate; real origin story |
| diff_size | 6 | duplicates `pr-prep` |
| **critical_files** | **0** | **never fired, ever** |

Applying the criterion *"a nonzero reject rate on a class nothing else catches"*,
**no gate passes.** Gate 1d has caught nothing in the loop's entire history.
`diff_size` and `shellcheck` duplicate `pr-prep` and `health-check.sh` check 6.
All 41 `self_eval` catches are on the prose class. The one gate with a genuine
origin — `tests` baseline isolation, built after 14 tasks across 3 rounds were
rejected by one stale pre-existing failure (2026-05-19, commit `8430f7f`) —
guards a *batch-parallel* phenomenon that disappears if the loop stops running
batches, and `workflows/pr-prep.md:332-343` already carries a richer three-class
triage for the single-branch case.

**This finding is independent of why the loop is dormant.** It holds whatever
the answer to §3 turns out to be, and it is the main reason "extract
`si-gates.sh` and keep the good part" is weaker than it looks: the measurement
says there is less demonstrated value in the gates than their engineering
quality suggests.

### 2.3 A design failure that is *not* about budget

Decision 010's explicit bet was: *"user reads summary, updates si-input.md, runs
next overnight session."* The last run's morning summary opens with an action
block reading **"Answer the 50 matured deferred hypothesis questions."** They
were not answered. Decision 010 had already deleted autonomous hypothesis
evaluation for being unreliable, which left the loop able to *generate*
hypotheses but not *settle* them.

Same shape elsewhere: `docs/working/incident-journal.md` is a ledger the loop's
own process created, whose own success criterion was "≥3 entries within 3
rounds", standing at **0 entries** with the refutation unrecorded. And
`workflows/pr-prep.md` Step 0 says *"do not skip this step"* about appending
failure-pattern entries — **104 `fix(...)` commits since 2026-05-18, zero
entries.**

The generalisation, which matters for every option in §4: **documented-but-unforced
steps do not execute in this repo.** With no remote and no CI, nothing forces
anything. Any option whose value depends on "and then it gets wired into
pr-prep" should be discounted accordingly.

This failure costs *human attention*, not tokens, so unlike §3 it is not
explained away by the budget constraint. The loop asks for more of the user's
attention than it has earned back.

---

## 3. The premise that changed — read before trusting the DD

The divergent-design run recommended **retire entirely, 75% confidence**. Its
central justification was that dormancy is revealed preference: last run
2026-06-23, 143 commits since 2026-08-07 with none from the loop, therefore the
motive does not survive contact with the evidence.

**The user supplied the missing fact after the DD completed, and it falsifies
that premise.** Dormancy was not a judgement about the loop's value. It was a
**capacity constraint**: a weekly usage cap, consumed by (a) the code-review
benchmark work that has only just wrapped up, and (b) use of the more expensive
Fable model. The user's account of the dynamic:

> the staleness then becomes self-propagating since work I directly need
> continues even while prospective improvement and structured enforcement lagged

Three consequences, and they cut in different directions:

1. **The headline statistic is void as evidence of preference.** "143 commits,
   none from the loop" does not show the loop was rejected. Those 143 commits
   are the *competing consumer of the same budget*. The DD itself named this
   exact risk in its "strongest argument against" section — that its case rested
   on a behavioural prediction about the user rather than a property of the code
   — and that prediction has now been answered against it.

2. **The suppressing condition is lifting, not persisting.** The benchmark work
   is finished. Retiring at the moment the constraint releases would be deciding
   on evidence gathered entirely from the constrained period.

3. **But the constraint reframes the real problem, and it is worse for the loop
   than "just run it" suggests.** If the binding resource is tokens per week,
   then the loop competes directly with the user's own work for that budget —
   and the loop as currently built is the single most token-expensive artifact in
   the repo. Gate 1h alone runs a full multi-critic `code-review` on *every task
   branch*, at the ~$14.6/instance cost that decisions 030/031 were written to
   escape. A 3-round run implements and reviews a dozen-plus tasks.

So the honest reframe is **not** retire-vs-keep. It is:

> **What does a self-improvement loop look like when the binding constraint is a
> weekly token budget it must share with the user's own work?**

Under that framing, *cost per round* becomes the dominant scoring axis. The DD
treated cost as secondary, so **its candidate scorecard needs re-running against
this axis before its recommendation is acted on.** Its measurement (§2.2) and
its couplings inventory (§5) remain valid and should be carried forward
unchanged.

---

## 4. Candidates, re-stated for the real constraint

The DD's five survivors, re-ordered by how they fare on cost-per-round. None of
these has been scored under the new framing — that is the next session's job.

| # | Option | Cost posture | Note |
|---|---|---|---|
| 1 | **Retire entirely** | zero | Was the DD's pick at 75%. Its premise is now falsified; needs re-scoring, not automatic adoption. |
| 2 | **Retire with carve-out** — keep only `tap_failing_names`/`tap_new_failures` (25 lines) relocated into `scripts/run-tests.sh` + its 11 tests | ~zero | The DD's pre-named **Revisit** fallback; lost to #1 by 25 lines. Cheap insurance. |
| 3 | **Budget-capped loop** *(new — generated by §3, not in the DD)* | bounded by construction | Drop Gate 1h (or degrade it to the T-tier/lite path of decisions 030/031), cap rounds at 1, cap tasks per round. Makes the loop's cost an input rather than an output. **This is the candidate the new framing implies and nobody has written up.** |
| 4 | **Extract `si-gates.sh`**, delete the driver, wire into pr-prep | low | Was my own first recommendation. §2.2 undercuts it (7 of 8 gates fail the extraction criterion) and §2.3 undercuts the wiring claim. |
| 5 | **Retarget at `scripts/`** rather than prose | high | The best keep-it argument: output was weak *because* it was pointed at markdown, where Gates 1e/1f record `skip`. Point it at code and every merged change carries mechanical evidence. Costs the most per round. |
| 6 | **Keep as-is and resume** | highest | Bottom on every axis the DD scored. The state bug is real but is not the failure. |

For each surviving candidate the next session should answer: **cost per round in
tokens**, what it costs to carry, what breaks if it is wrong, what evidence
within one cycle would show it was right, and what happens to the 197 tests.

---

## 5. Inventory for whoever implements (carried forward from the DD)

Three couplings that any retiring option must handle, none of which were mapped
before the DD found them:

1. **`test/hermeticity-lint.bats:806-818`** holds two *anchor* tests pinning the
   layer-2 hermeticity gate's correctness to `round-log-functions.bats` +
   `self-improvement.sh`. Commit `4d39475` is the indirect-closure incident they
   regress-test. These need a **replacement fixture, not deletion** — deleting
   them silently weakens an unrelated gate.
2. **`skills/code-review/SKILL.md:573`** documents `self-improvement.sh` as a
   consumer contract; it becomes factually false on removal.
3. **`guides/subtraction-checklist.md`**, **`scripts/skill-usage-report.sh`**,
   and **health-check check 7** are all triggered by "Step 5 of the
   self-improvement loop."

Test surface: 197 tests across 14 suites. The migrate/delete inventory must
include `test/function-inventory.bats` (which `source`s the script in `setup()`)
and `test/claude-headless-flags.bats`.

Also unresolved: **Gate 1h's shipped behaviour contradicts decision 020.** 020
records that unparseable `code-review` output *skips* rather than rejecting; the
shipped gate **fails closed** on both a non-zero reviewer exit and a
missing/conflicting sentinel. `guides/validation-gates.md` now documents the
shipped behaviour and flags the divergence. Either the code drifted or the
decision was never updated — reconcile before relying on either. This is a live
input to the decision, since Gate 1h's strictness is most of what makes a round
expensive.

State bugs confirmed but not fixed (they are not the failure, and are moot under
several options): `START_ROUND` at `:432` is a dead resume path, and
`MAX_ROUNDS` is hardcoded at `:326` despite the header documenting it as an
env var.

---

## 6. Commits from this session

| SHA | Commit |
|---|---|
| `84350f0` | `fix(archive)`: stop archiving the loop's cross-run memory |
| `d224ad5` | `docs(guides)`: document Gate 1h, de-stale the validation-gate reference |
| `d317721` | `fix`: remove the dangling tracked symlink `workflows/workflows` |
| `da4811b` | `fix(test)`: arm three vacuous assertions + silence an SC2034 false positive — restores `health-check.sh` to green |

The last one is worth noting for a reason beyond housekeeping. `health-check.sh`
had gone red on `main` because `test/init-firewall-rules.bats` carried three
`! grep` assertions that **cannot fail a bats test** (SC2314) — the negative
assertions in the `scholar` egress-profile test, checking that
`scholar.google.com` and `doi.org` are *not* admitted through the firewall, were
vacuous. They were repaired with the `run !` idiom and mutation-proven
falsifiable (mutating one turns the test red; restoring turns it green). The
underlying host list was correct all along; the tests simply were not proving it.

That defect class was fixed in a *different* bats file on 2026-09-12 (`a9f49bf`),
written up there as a real defect rather than a style nit — and it reappeared in
the very next feature commit (`1c36357`). **That is §2.3's finding happening in
real time, in the security-boundary tests, while we were measuring it.** It is
the strongest single argument that this repo needs *some* forcing mechanism, and
it should weigh in the §4 decision.

---

## 7. Open questions for the next session

- [ ] Re-score the §4 candidates with **cost per round** as a first-class axis.
      Does a budget-capped loop (#3) dominate both retirement and the full loop?
- [ ] What is a round *actually* worth in tokens? Nobody has measured it. The
      archived run logs (`docs/working/archive/2026-08-06-si-run-*.log`) may
      support an estimate.
- [ ] If the loop resumes: what stops it from producing another 50 unanswered
      hypothesis questions (§2.3)? Decision 010 removed autonomous evaluation for
      good reason; nothing replaced it.
- [ ] Retarget at `scripts/` (#5)? The argument that prose output was the problem
      is strong and independent of the budget question.
- [ ] Reconcile Gate 1h vs decision 020 (§5).
- [ ] Fix or drop the finding-4 doc staleness (§2.1) once the decision is made.
