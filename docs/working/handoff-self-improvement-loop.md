# Handoff — what to do with `scripts/self-improvement.sh`

**Written:** 2026-09-17
**Status:** Decision open, and reframed twice since the DD ran (see §3, §3.1).
Investigation and cheap fixes complete; the substantive
call is deliberately not made.
**Start here in the next session.** Read this file first, then
`docs/working/dd-self-improvement-loop-future.md` (the divergent-design run, 728
lines) — but read §3 and §3.1 before trusting the DD's recommendation: its
premise was falsified twice after it ran, and **its scorecard cannot be adopted
as-is.**

**The framing that matters, in one line:** the binding constraint is no longer
tokens but **human attention**, which is saturated rather than unspent, so the
question is whether a version of this loop can *produce* attention triage rather
than consume attention. See §3.1 and candidate #7 in §4.

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
for answering them was reframed twice after the analysis ran — see §3 and §3.1.

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

### 2.3 The attention problem — saturation, not neglect

**This section was rewritten after the user corrected an earlier draft. The
earlier version claimed the loop's attention asks went unanswered and
generalised to "documented-but-unforced steps do not execute in this repo."
That was mostly wrong, and the correction matters more than the original
finding.**

What actually happened: the asks **were** serviced. The remaining hypothesis
questions were answered, and the pattern was promoted into the standing
instruction set — `global-instructions/CLAUDE.md:231` now carries the *Running
questions document* protocol (append-don't-block, interim choice recorded in
both the entry and the commit body, surfaced explicitly on return to `/active`).
`docs/working/questions.md` currently stands at **9 answered, 7 open**. The
mechanism works and is maintained.

The real failure is one stage further on:

> the *success* of human attention asks means that, effectively, I have been
> able to eat up my entire human attention budget

**The asks are serviced until the budget is saturated, and nothing decides which
asks were worth it.** A mechanism that reliably converts attention into answers,
with no triage over *which* questions deserve the attention, will consume all
available attention at whatever quality the queue happens to hold. The last
morning summary's action block — *"Answer the 50 matured deferred hypothesis
questions"* — is the anti-pattern in its purest form: fifty undifferentiated
asks, no ranking, no indication of which three would change a decision.

So the deficiency is **triage and identification of where human attention is
most efficiently applied**, and per the user that is *itself a workstream
belonging in this repo* — the one they are returning to now.

Two residues from the earlier draft that do survive, demoted to what they are:
`docs/thoughts/failure-patterns.md` holds **0 entries** across 84 lines despite
`workflows/pr-prep.md` Step 0 saying *"do not skip this step"*, and
`docs/working/incident-journal.md` is empty against its own "≥3 entries within 3
rounds" criterion. These are narrower than the generalisation they were used to
support: they are *unprompted ledger appends with no consumer*, not evidence
that instructions go unexecuted. The contrast with the running-questions doc is
the actual lesson — **what got promoted into core instructions executes; what
stayed a step inside a workflow doc did not.** That is a usable design rule for
§4, and a much narrower claim than the one it replaces.

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

### 3.1 The constraint hierarchy has now flipped — this is the live framing

A second correction from the user, after the above was written, and it
supersedes it as the dominant axis:

> token budget is slightly less constrained and human attention budget is
> significantly more constrained

So the scarce resource is **no longer tokens**. Tokens are easing (the benchmark
work is done); **human attention is now the binding constraint**, and per §2.3 it
is saturated rather than unspent. That changes the scoring axis twice over:

- *Cost per round in tokens* drops from dominant to a secondary affordability
  check. Worth knowing, no longer decisive.
- **Human-attention cost per round becomes the dominant axis** — and, crucially,
  it is a *signed* quantity. An option can spend attention (another queue of
  undifferentiated questions) or **produce** it (triage that tells the user
  which three things are worth looking at).

That reframes the loop's purpose, not just its budget. Its historical product was
merged markdown diffs, with attention-asks as a side effect. Under the new
constraint the valuable product would be **triage**: identifying where the
user's attention is most efficiently applied. Note this partly defuses §2.2 — if
the loop's output is a ranked attention queue rather than merged diffs, the
finding that its *merge* gates catch little stops being decisive against it.

So the honest reframe is **not** retire-vs-keep, and no longer
cost-per-round either. It is:

> **Is there a version of this loop whose product is attention triage — telling
> the user where to look — rather than merged changes that then ask for
> attention?**

The DD scored none of its candidates on this axis, because the axis did not
exist when it ran. **Its recommendation cannot be adopted as-is.** Its
measurement (§2.2) and couplings inventory (§5) remain valid and carry forward
unchanged; its scorecard does not.

---

## 4. Candidates, re-stated for the real constraint

Scored on the §3.1 axis: does the option **spend** the user's attention or
**produce** triage? Token cost is retained as a secondary affordability column.
None of these has been scored properly under this framing — that is the next
session's job.

| # | Option | Attention effect | Token cost | Note |
|---|---|---|---|---|
| 7 | **Attention-triage loop** *(new — implied by §2.3 + §3.1, in no prior analysis)* | **produces** | TBD | The loop's product becomes a ranked "here is where to look" queue rather than merged diffs. The morning summary is the existing hook and currently does the opposite (50 undifferentiated asks). Defuses §2.2, since merge-gate value stops being the point. **Most aligned with the constraint that actually binds, and the least specified.** |
| 1 | **Retire entirely** | neutral | zero | Was the DD's pick at 75%. Premise falsified twice (§3, §3.1); needs re-scoring, not adoption. Note retiring also forecloses #7. |
| 2 | **Retire with carve-out** — `tap_failing_names`/`tap_new_failures` (25 lines) into `scripts/run-tests.sh` + its 11 tests | neutral | ~zero | The DD's pre-named **Revisit** fallback; lost to #1 by 25 lines. Cheap insurance. |
| 3 | **Budget-capped loop** *(generated by §3)* | spends, but bounded | bounded by construction | Drop or degrade Gate 1h to the T-tier/lite path of 030/031, cap rounds and tasks. Was the leading candidate under the token framing; **demoted by §3.1**, since capping tokens does not cap attention. |
| 4 | **Extract `si-gates.sh`**, wire into pr-prep | neutral | low | My own first recommendation. §2.2 undercuts it (no gate clears the extraction bar); §2.3's narrowed lesson also warns that a step living in a workflow doc does not execute unless promoted to core instructions. |
| 5 | **Retarget at `scripts/`** rather than prose | spends | high | Best keep-it argument: output was weak *because* it targeted markdown, where Gates 1e/1f record `skip`. But it produces more merged changes to review — i.e. more attention demand, against the binding constraint. |
| 6 | **Keep as-is and resume** | **spends most** | highest | Generated the 50-question queue that §2.3 identifies as the anti-pattern. Bottom on the axis that now matters. |

Not mutually exclusive: **#7 combines with #2** (retire the driver, keep the
25-line carve-out, build triage as a separate thing) and that pairing may
dominate. Whether triage even needs the loop's machinery is an open question —
it may be a new, much smaller artifact that inherits nothing.

For each surviving candidate the next session should answer: **does it spend or
produce attention, and how is that measured**; token cost per round as an
affordability check; what breaks if it is wrong; what evidence within one cycle
would show it was right; and what happens to the 197 tests.

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
the very next feature commit (`1c36357`).

Read it against §3.1 rather than as a forcing-mechanism failure, because the
forcing mechanism **worked**: `health-check.sh` shellchecks the tree, it went
red, and it stayed red on `main` for five days. Detection was never the problem.
What was missing is the step after detection — *this red matters more than the
other things competing for your attention this week, because three firewall
assertions are vacuous.* A red health-check reports a count; it does not rank.

That is candidate #7's case in miniature, drawn from a real incident during this
session: the repo is better at generating signals than at telling the user which
signal to spend attention on. It should weigh in the §4 decision.

---

## 7. Open questions for the next session

Ordered by what unblocks the rest. The first item is the workstream; the others
are inputs to it.

- [ ] **Specify the attention-triage workstream (#7).** This is the user's
      stated returning priority and the least specified thing here. What is the
      unit of triage — a ranked queue, a single "look at this first" line, a
      severity model over existing signals (health-check reds, open questions,
      stale docs, failing gates)? What makes a ranking trustworthy enough to act
      on without re-deriving it? Candidate for its own DD, framed around
      §3.1 — and note it may be a **new small artifact that inherits nothing**
      from the loop, which would make the retire/keep question separable and much
      easier.
- [ ] **How is attention cost/production measured at all?** §3.1 makes it the
      dominant axis but supplies no unit. Without one, #7 cannot be scored and
      the §4 table stays qualitative. Possible anchors: questions asked per
      round vs answered; time-to-first-useful-action on a signal; count of
      signals outstanding (health-check reds + open questions + refuted-but-
      unrecorded hypotheses).
- [ ] Re-score the §4 candidates on the spend-vs-produce axis. Does **#7 + #2**
      dominate both retirement and any version of the full loop?
- [ ] Triage the existing backlog as the workstream's **first test case**: 7 open
      questions in `docs/working/questions.md`, 0 entries in
      `docs/thoughts/failure-patterns.md` against 104 `fix(...)` commits, and the
      empty incident journal. Which of these deserve attention and which should
      be deleted? A triage mechanism that cannot answer this is not yet working.
- [ ] What is a round worth in tokens? Now a secondary affordability check
      rather than the decision driver. `docs/working/archive/2026-08-06-si-run-*.log`
      may support an estimate.
- [ ] Retarget at `scripts/` (#5)? The argument that prose output was the problem
      is strong and independent of both budget questions — but it increases
      attention demand, so it needs #7 first.
- [ ] Reconcile Gate 1h vs decision 020 (§5).
- [ ] Fix or drop the finding-4 doc staleness (§2.1) once the decision is made.
