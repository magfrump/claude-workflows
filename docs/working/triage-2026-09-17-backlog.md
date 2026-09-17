# Triage run — the existing backlog, 2026-09-17

**Purpose.** This is §7 item 4 of `handoff-self-improvement-loop.md`, run *first*
and deliberately: the handoff says a triage mechanism that cannot triage this
backlog is not yet working. Doing the exercise by hand before designing the
mechanism is what keeps §7 item 1 from being speculation. §3 below is the design
output that fell out of it; §4 re-scores the handoff's §4 candidates.

**Headline.** Nineteen outstanding signal instances, printed across roughly
thirty lines in two places, reduce to **five items that need the user's
judgment** and **two that need five minutes in their own terminal**. Everything
else routes to an agent, a trigger, or deletion — and two were fixed outright
while writing this.

Three of those five became visible only because the mechanical route was
*attempted* rather than asserted (§2.1). One of them is substantive on its own
terms: **`workflows/research-plan-implement.md`, the documented default, has not
been opened once in 49 days** across 2749 logged events, while divergent-design
was opened 15 times (§2.2).

---

## 1. What the signal sources actually emit

### 1.1 `scripts/health-check.sh` — 29 warnings, 4 distinct facts

Run on `main` at `859eedb`: **0 failures, 29 `⚠` lines, exit "All checks
passed."** The warnings are not 29 things. They are 4:

| # | Fact | Lines printed | Route |
|---|---|---|---|
| HC1 | 23 of 26 skills have no test fixtures | **24** | **DROP** (see below) |
| HC2 | `AGENTS.md`/`GEMINI.md` lack the `Tool Preferences` H2 that the global instruction file has | 3 | AGENT |
| HC3 | `docs/spikes/staleness-heuristic.md` stale — 5 commits to tracked paths since 2026-06-24 | 1 | AGENT |
| HC4 | `test/skills/code-review-assurance-contract.bats:165-166` needs `bats_require_minimum_version 1.5.0` | 1 | AGENT |

**Amplification: 7.25 printed lines per fact.** One fact — HC1 — is 83% of the
entire warning volume, and `scripts/health-check.sh:21` documents it as a *"soft
warning, not a gate"*. It is a standing architectural property of the repo, not
an event: it will print 24 lines on every run until someone writes 23 fixture
sets, which nobody intends to do. It is the loudest output of the repo's main
signal generator and it is by construction unactionable.

This is the §2.2/§6 phenomenon of the handoff in its cleanest form. The
health-check's detection works perfectly. What it emits is a *count*, and the
count is dominated by the one fact that matters least.

### 1.2 `docs/working/questions.md` — 7 open, and they are not the same kind of thing

| # | Question | What it actually needs |
|---|---|---|
| Q1 | The four review findings R1 / A7 / A5+A6 from the 2026-09-12 rubric | **The user's judgment.** Behaviour and environment calls; A5 and A6 must be decided together because the proposed one-liners pull in opposite directions. |
| Q2 | elan release host — `release.` or `releases.` | Host observation (see §1.3) |
| Q3 | Current mathlib olean cache hostname | Host observation — `rg -o 'https://[^"]*' Cache/Requests.lean` in a mathlib4 checkout |
| Q4 | Per-arch SHA-256 pins for the elan release | Host observation, **not due** — its own terms defer it to the next `ELAN_VERSION` bump |
| Q5 | The three unconfirmed `scholar` hostnames | Host observation — three `curl -sI` in a `--profile scholar` container |
| Q6 | Does `scholar` need an escape hatch for publisher-hosted OA PDFs? | **Nothing. It is a trigger, not a question** — its own interim says "if this bites in practice" |
| Q7 | Should `--profile` grow additive flags? | **Nothing. Also a trigger** — "if you find yourself re-typing the full list often" |

Five of seven are not attention asks at all. Q2/Q3/Q5 are one batched terminal
session; Q4 is scheduled behind an event that has not happened; Q6 and Q7 are
written as triggers and are sitting in the queue only because nothing
distinguishes a trigger from a question.

**One of the seven needs the user.**

### 1.3 A near-miss worth recording

The triage initially routed **Q2 to DROP** — closeable from inside the file,
since the `ELAN_VERSION` answer above it establishes v4.2.4 shipped, notes that
elan 4.0.0+ resolves from `release.lean-lang.org` singular, and records a live
`elan toolchain install` succeeding in-container on 2026-09-15.

That was wrong, and `devcontainer-config/egress/lean.txt` caught it: both names
are listed, so a successful fetch does not discriminate between them. The file's
own closure criterion is *"delete the wrong one once a real toolchain fetch has
been watched succeed"* — **watched**, not inferred.

**Rule extracted:** a router may not close a question by inference when the
question's own closure criterion names an observation. The cost of the error was
zero here only because the file stated its criterion in its own text. This is the
single most likely way an automated router does damage.

### 1.4 Ledgers with no consumer

| # | Signal | Route |
|---|---|---|
| L1 | `docs/thoughts/failure-patterns.md` — **0 entries** against **104** `fix(...)` commits on `main` since the file was created (2026-05-18), despite `workflows/pr-prep.md` Step 0 saying "do not skip this step" | **USER-JUDGMENT (one bit):** backfill or delete |
| L2 | `docs/working/incident-journal.md` — **0 entries** against its own "≥3 entries within 3 rounds" criterion | **DROP.** Its input is Tier-3 skill recovery during loop rounds; with the loop dormant it has had no possible input. Delete or mark dormant. |
| L3 | `docs/working/hypothesis-backlog.md` — H-01 and H-07 `TRACKING`, last checked **2026-05-12** (128 days) | **AGENT: expire them.** Both rest on `usage.jsonl` telemetry, and H-05's own retirement rationale in the same file already establishes that this telemetry cannot answer value questions. The conclusion is written down; nobody applied it to its siblings. |
| L4 | 14 directories / **231 MB** under `.claude/worktrees/`, 12 registered in `git worktree list` | **AGENT**, after a merged-state check |

L3 is worth pausing on: the repo already contains the reasoning that closes two
of its own open items. Nothing connected the conclusion to the items. That is a
triage failure with no severity component at all.

### 1.5 Carried from the handoff

| # | Item | Route |
|---|---|---|
| D1 | Gate 1h's shipped fail-closed behaviour contradicts decision 020 | **Conditional** — only binds if a Gate-1h-bearing option survives §4. Defer *behind* the decision, not alongside it. |
| D2 | Finding-4 doc staleness (`guides/cross-project-setup.md:40`, `guides/subtraction-checklist.md`) | **Conditional**, already correctly deferred by the handoff |
| D3 | Re-score the §4 candidates | **USER-JUDGMENT — the live decision.** §4 below. |

---

## 2. The triage result

Nineteen distinct items:

First pass, before the AGENT route was actually discharged:

| Route | Count | Items |
|---|---|---|
| **USER-JUDGMENT** | 2 | Q1 · D3 — plus L1 as a one-bit call |
| **USER-TERMINAL** (one batched block) | **2 due** | Q3, Q5 · (Q4 not due) |
| **AGENT** | 5 | HC2, HC3, HC4, L3, L4 |
| **DROP / trigger** | **5** | HC1's per-skill lines, Q6, Q7, L2 · (+Q2 → batched into USER-TERMINAL) |
| **CONDITIONAL** (blocked behind D3) | **3** | D1, D2, Q4 |

### 2.1 Then the AGENT route was discharged, and it caught three misroutes

Attempting the five AGENT items is what tested the routing. **Two of the five
were genuinely mechanical and are now done. Three were misrouted, and each was
caught by the artifact itself** — the same way §1.3 caught Q2.

- **HC4 — done.** `bats_require_minimum_version 1.5.0` added to
  `test/skills/code-review-assurance-contract.bats`; 15/15 pass, BW02 gone.
- **HC3 — done.** All five commits under the spike's tracked paths since
  2026-06-24 are path-churn and check-scoping; the two-part heuristic is
  unchanged and still implemented. `Last verified` bumped to 2026-09-17 **with
  the five SHAs and what was checked**, so the next reader can audit the
  re-verification instead of trusting it.
- **HC2 — misrouted → DROP.** `scripts/health-check.sh` check 13 says in its own
  comment: *"Soft warnings only — some divergence is intentional... the check
  exists for human review, not to gate on."* And the divergence is intentional:
  the missing H2 is `Tool Preferences (sandbox-aware)`, which describes *this*
  bwrap sandbox and allowlist. `AGENTS.md` targets Copilot/Cursor/Cline, which do
  not run in it. Syncing it would have made the tool-agnostic file wrong.
- **L3 — misrouted → USER-JUDGMENT, and it is the session's most substantive
  finding.** See §2.2.
- **L4 — misrouted → USER-JUDGMENT.** Removing 12 registered worktrees and 231 MB
  is branch deletion. That needs the user regardless of how mechanical it looks —
  it is exactly the "conservative in one direction" rule of §3.2.

**Two of five AGENT items survived contact.** The router's per-item accuracy was
60%; its *safety* was 100%, because every misroute was caught before it did
damage and every catch came from the artifact stating its own constraint in its
own text. That asymmetry is the whole design claim of §3.2, and it now has
evidence rather than an argument.

### 2.2 L3: the default workflow has not been opened in 49 days

`hooks/log-usage.sh:61-63` logs a `workflow` event on any `Read` of a file under
`*/workflows/*`. Over `~/.claude/logs/usage.jsonl` — **2749 events, 2026-07-30 to
2026-09-17, 20+ projects** — the workflow events are:

| workflow | reads in 49 days |
|---|---|
| `divergent-design` | **15** |
| `pr-prep` | 5 |
| `review-fix-loop` | 2 |
| **`research-plan-implement`** | **0** |
| **`codebase-onboarding`** | **0** |

RPI is row 6 of the decision tree and its documented **default**. Nothing opened
it in 49 days. Meanwhile divergent-design — which H-04 already recorded the user
calling *"the number one best piece of prompting I use"* — is 15 of the 22.

> **Correction, 2026-09-17 (same day).** The user reports that hook measurement
> has a history of silent under-counting — some setups, notably a subagent given
> skill text already in its context, fire no hooks at all [their confidence: low
> on that mechanism specifically; **high** that the problem recurred often enough
> to lose faith in the numbers, including after fixes shipped]. **So this finding
> is withdrawn as evidence.** 0 reads is equally consistent with the doc being
> unused and with the instrument not seeing it, and the data cannot separate
> them. The 15:0 contrast goes with it: divergent-design's 15 is a lower bound
> from the same instrument, not a comparable measurement. Recorded as `Q-017` in
> `questions-archive.md`.
>
> The part that survives is a **triage** lesson, not an RPI one, and it is a real
> gap in §3.2: routing a number to USER-JUDGMENT presumes the number is real. An
> instrument with a known under-counting history should not generate attention
> asks until it is re-validated. That criterion is now in the running-questions
> protocol in the core instruction set. It is also a fourth misroute — this one
> caught by the user rather than by the artifact, which is exactly the case §3.2
> does not cover.

This does **not** expire H-01; it gives it its first real evidence, and the
direction is against it. The honest statement is narrow and defensible: *the RPI
document is not being opened*, not *RPI is not being followed* — the routing
table in the core instruction set may be carrying the process without the doc.
Which of those it is, is the user's call, and it bears directly on §4: it is the
same §2.3 lesson (**promoted to core instructions executes; left in a workflow
doc does not**) showing up a third time, now with a 15:0 ratio on it.

### 2.3 Final routing

| Route | Count | Items |
|---|---|---|
| **USER-JUDGMENT** | **5** | Q1 (four review findings) · D3 (the §4 decision) · L1 (backfill-or-delete, one bit) · **L3 (§2.2 — RPI 0 reads)** · L4 (delete 12 worktrees, 231 MB) |
| **USER-TERMINAL** (one batched block) | **2 due** | Q3, Q5 · (Q4 not due) |
| **AGENT — discharged this session** | **2** | HC3, HC4 |
| **DROP / trigger** | **6** | HC1's per-skill lines, HC2, Q6, Q7, L2 · (+Q2 → batched into USER-TERMINAL) |
| **CONDITIONAL** (blocked behind D3) | **3** | D1, D2, Q4 |

**Nineteen items, roughly thirty printed lines, `asks` = 5** (L3 later withdrawn — see §2.2 — leaving 4) — at the router's
own alarm threshold, and three of the five only became visible *because* the
AGENT route was attempted rather than asserted. Two items were fixed outright.

The morning summary's *"answer the 50 matured deferred hypothesis questions"* is
the same error one level up: fifty items, no routing, so the user must read all
fifty to find the few that are theirs.

---

## 3. What this says the mechanism should be

### 3.1 The unit of triage is a **route**, not a rank

The handoff asked whether the unit is a ranked queue, a single "look here first"
line, or a severity model. The exercise says **none of those**, and for a reason
that only shows up when you actually do it:

> **Ranking presumes the items compete for one resource. They do not.**

Of nineteen items, one needs the user's taste, two need their hands on their own
machine, five need an agent, five need deleting. A ranked list of nineteen still
forces them to read nineteen entries to discover which one is theirs — it
reorders the attention spend without reducing it. A severity model fails harder:
essentially every item here is low severity, so severity does not separate them.
What separates them is **which resource discharges them**.

Four routes:

- **USER-JUDGMENT** — needs taste, authority, or a preference only they hold.
  The only true attention spend. **If this exceeds ~5 per cycle, the router has
  failed**, and that is the router's own alarm.
- **USER-TERMINAL** — needs their machine, not their mind. Emitted as *one
  copy-pasteable block*, never as individual questions. Costs hands, not
  attention. Five of the seven open questions have sat here for five days as
  "questions" when they are three `curl -sI` and one `rg`.
- **AGENT** — mechanical, no judgment. Never shown as an ask; shown afterwards
  as a count of what was done, with a diff.
- **DROP** — no consumer, or an unmet trigger. Shown **once**, as a proposal to
  delete, then gone. A trigger is not a question and must not sit in a question
  queue.

### 3.2 What makes a route trustworthy enough to act on without re-deriving it

Trust does not come from the router being accurate. It comes from **the
misroutes being asymmetric and cheap**:

- USER-JUDGMENT → AGENT is the only dangerous error. So the router is
  conservative in exactly one direction: **anything whose fix changes behaviour
  the user would hold an opinion about routes to USER-JUDGMENT**, regardless of
  how mechanical it looks.
- AGENT → USER-JUDGMENT wastes one line of their reading. Acceptable.
- DROP → anything is recoverable: the deletion is a commit.
- §1.3's rule is the hard constraint: **never close an item by inference when the
  item's own closure criterion names an observation.** That is the failure mode
  that produces a wrong allowlist entry rather than a wasted minute.

The running-questions protocol in the global instruction set already does the
other half of this — every entry carries its interim choice — so a misroute is
recoverable by reading a diff rather than by redoing work. That protocol is also
the handoff §2.3 evidence that **what gets promoted into core instructions
executes, and what stays inside a workflow doc does not** (L1: 0 entries against
104 eligible commits). Whatever the router becomes, its output has to land
somewhere the core instruction set already points at.

### 3.3 The measurement unit §7 item 2 was missing

The handoff made signed attention the dominant axis and supplied no unit. Two,
both computable from what already exists, with no new instrumentation:

- **`asks` — items routed USER-JUDGMENT per cycle.** This *is* the attention
  spend. An option **produces** attention iff `asks` falls while route counts
  show the other items still being discharged; it **spends** attention iff `asks`
  rises. Today's baseline: **`asks` = 5**, against 19 items and ~30 printed lines
  — and note it was 2 before the AGENT route was discharged. A router that only
  *predicts* routes will under-report `asks`; the number is only honest once the
  cheap routes have actually been attempted (§2.1).
- **`amplification` — printed lines ÷ distinct facts.** Today: **7.25** for
  health-check. This is the cheap proxy; it needs no routing at all and can be
  measured on any signal generator immediately.

Both are falsifiable and both have a baseline as of this document.

### 3.4 The shape this implies — and the part that is not free

The first draft of this section claimed routing needed **no model inference**,
because every route fell out of a structural property: does the item's own text
name a trigger, does its closure criterion name an observation, is the warning
documented as soft. §2.1 falsified that within the hour. A purely structural
router would have made all three misroutes — it would have synced `AGENTS.md`
(making the tool-agnostic file wrong), expired two hypotheses that had never been
checked, and deleted twelve branches. Each catch required *reading the artifact
and reasoning about who it is for*.

The honest split is therefore two-tier, and it maps onto cost cleanly:

- **Shortlisting is free.** Collecting the items, deduplicating them (29 lines →
  4 facts), and separating triggers from questions is pure text processing. A
  read-only script over the existing sources does this on every commit at ~zero
  token cost. This tier alone captures most of the compression.
- **Committing to a route is not free.** Specifically the AGENT route: before
  acting, the artifact has to be read, because the constraint that stops you is
  usually written in it (§1.3, and all three of §2.1's catches). This is
  per-item, and only for the handful of items the shortlist marks mechanical.

So **#7 is a report with a small escalation, not a loop.** The expensive tier is
bounded by the number of candidate-mechanical items per cycle — five today, two
of which were real — rather than by rounds or tasks. That is a different cost
curve from `scripts/self-improvement.sh` by two orders of magnitude, and it
inherits none of its machinery: no worktrees, no gates, no `claude -p` per task.

This collapses the option space before the DD runs. If #7 is a report, the
retire/keep question separates completely — exactly the outcome §7 item 1 hoped
for but could not yet assert.

---

## 4. Re-scoring the handoff's §4 candidates (§7 item 3)

Scored on `asks` (§3.3). The question the handoff posed — does **#7 + #2**
dominate? — now answers **yes**, and for a stronger reason than it anticipated.

| # | Option | `asks` effect | Verdict |
|---|---|---|---|
| 7 | **Attention-triage report** *(not a loop — §3.4)* | **produces** — 19 items and ~30 printed lines → 5 asks, 2 fixed outright, 6 proposed for deletion. Measured, not projected. | **Take.** Free shortlist tier plus a per-item escalation bounded by the mechanical shortlist (5 today); inherits nothing from the loop. |
| 2 | Retire with the `tap_failing_names`/`tap_new_failures` carve-out (25 lines + 11 tests) | neutral | **Take.** Independent of #7 now that #7 inherits nothing. Cheap insurance, and §5's three couplings still have to be handled either way. |
| 1 | Retire entirely | neutral | Dominated by #2 at a cost of 25 lines. |
| 3 | Budget-capped loop | spends, bounded | **Drop.** Capping tokens does not cap `asks`; it was already demoted by §3.1 of the handoff, and #7 supplies what it was being kept for. |
| 4 | Extract `si-gates.sh` into pr-prep | neutral | **Drop.** §2.2 (no gate clears the bar) plus §2.3's narrowed lesson — a step inside a workflow doc does not execute. L1 is that lesson with a number on it: 0 entries, 104 eligible commits. |
| 5 | Retarget at `scripts/` | spends | **Defer behind #7.** The argument that prose output was the problem remains strong and independent, but it raises `asks`, and #7 has to be measurable first. |
| 6 | Keep as-is and resume | **spends most** | **Drop.** Generated the 50-question queue that is the anti-pattern. |

**#7 + #2 dominates.** The decisive new fact is §3.4: #7 shares no machinery
with the loop, so taking it costs nothing and retiring costs nothing extra.

Unchanged from the handoff and still binding on any retiring option: the three
couplings in its §5 (the `test/hermeticity-lint.bats:806-818` anchor tests need a
**replacement fixture, not deletion**; `skills/code-review/SKILL.md:573`; the
"Step 5" triggers in `guides/subtraction-checklist.md`,
`scripts/skill-usage-report.sh` and health-check check 7).

---

## 5. What the next session should do

Done this session: HC3, HC4 (§2.1). Remaining, in order:

1. **Put the five USER-JUDGMENT asks in front of the user** (§2.3) and take the
   D3 decision. Everything conditional is blocked behind it. L3 (§2.2) is the one
   to lead with — it is the only one that is news rather than a pending decision.
2. **Emit the USER-TERMINAL block** — one code block with the `rg` for Q3 and the
   three `curl -sI` for Q5 (Q2 rides along), for the user to paste once. Do not
   ask these as three questions; they are one paste.
3. **Fix HC1's output, not HC1.** Collapse check 9 to a single summary line.
   That alone takes health-check's `amplification` from 7.25 to 1.75, is a
   one-function change in `scripts/health-check.sh`, and is the smallest working
   slice of #7 in existence.
4. **Then** run the DD on #7 if one is still wanted — but note §3.4 first. If #7
   is a report with a bounded escalation rather than a loop, the DD's option
   space is much narrower than the handoff assumed, and step 3 is a slice of it
   that can ship without the DD.

## 6. Open questions this raised

- [ ] 2026-09-17 Is `asks` (§3.3) the right unit, or does it undercount a *hard*
      judgment call against several easy ones? · context: today's 2 asks are one
      four-part review decision and one strategic decision — very different
      sizes · interim: counting items, not weight, because weight needs a
      judgment to assign and that is itself an ask · answer changes: if weight
      matters, entries carry a coarse S/M/L and the alarm threshold becomes a sum.
- [ ] 2026-09-17 Should DROP items be deleted or archived? · context: L2
      (incident journal) is dormant-because-unfed, not wrong — deleting it loses
      a schema someone designed · interim: propose deletion, do not delete,
      pending §2's user pass · answer changes: if archive, DROP needs a
      destination and the route stops being free.
