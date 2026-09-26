# Experiment results: full-scaffolding code-review pipeline × model tier, 2026-07-30

**Companion:** `experiment-results-code-review-2026-07-29.md` (Results 1–10),
`auto-code-review-conversation-tracker.md` (Thread 4's evaluability prerequisite).

**What ran:** the production `code-review` skill — orchestrator + code-fact-check +
auto-selected critics + synthesis — executed headless against three historical pre-fix
diffs from local repo history, at three model tiers. This is the first arm in the program
that exercises the *pipeline* rather than a single prompt.

---

## 0. Feasibility: the thing Thread 4 said was not evaluable

Thread 4 recorded that the in-loop scaffolding is "**not evaluable as-is** … no stable
input boundary, no persisted output." That is no longer true, but the enabling condition
is narrower than "decision 023 wired the hooks."

**Necessary and now satisfied:** `~/.claude/{skills,workflows,guides,patterns,hooks,
scripts}` symlink into the root-owned `/opt/claude-workflows` payload, and `settings.json`
carries the merged hook wiring. A headless child session therefore starts with the same
skills, hooks, and CLAUDE.md as an interactive one.

**Not sufficient — two headless confinements must be lifted explicitly:**

| Confinement | Symptom | Flag |
|---|---|---|
| `Write` denied by default | Pipeline runs to completion and persists **nothing**; the orchestrator reports `docs/reviews/` as "write-blocked" | `--permission-mode acceptEdits` |
| `Read` confined to cwd | Orchestrator cannot read `skills/*/SKILL.md`, so critics run on its **paraphrase** of the role prompt | `--add-dir` |

The second is disqualifying for any tier experiment: Result 8a established that the
role-skill prompt, not the tier, carried sonnet from 0/2 to 2/2 on ND3's blocking defect.
Two full batches were discarded after the first runs' own adaptation notes disclosed the
paraphrase. Verified both directions — the skill-file read returns `BLOCKED` without
`--add-dir` and the file's first heading with it.

> **Live defect this implies.** `scripts/self-improvement.sh:1295` invokes this skill via
> `claude -p` with neither flag, and instructs it to "write the rubric to `docs/reviews/`
> as usual." That write cannot be succeeding, and Gate 1h's critics are running on a
> paraphrase. Not fixed here — flagged.

## Setup

3 diffs × 3 tiers × 1 replicate = 9 runs, all rc=0.

- **ND2** `2d0ee3c~1..2d0ee3c` (nature_photographer, +621/−55) — GT A1: mood inversion on
  a FLEE-interrupted song.
- **ND3** `319f229~1..319f229` (nature_photographer, +681/−6) — GT A1: deserialize trusts
  the body past the version check. GT A2: shared version constant. GT A3: throw convention.
- **MD1** `d86d2dc..d90d6bb` (meta-formalism-copilot, +72/−1 — the whole csp-headers
  branch, matching the historical `origin/main..HEAD` scope) — GT R1: `connect-src 'self'`
  breaks PNG export via `exportGraph.ts`'s `fetch(dataUrl)`. GT R2: Edge-runtime comment.

Each run gets a private copy of a detached worktree at the pre-fix commit. **Leakage
checked, not assumed:** no worktree contains its own rubric (nd2's carries ND1's, nd3's
carries ND2's; both landed in later commits). Prompt is byte-identical across tiers except
the tier name; the tier is forced uniform across the orchestrator *and* every sub-agent,
overriding the skill's own opus-for-critics default. `--no-gate`.

Wall clock 12–28 min/run; sonnet fastest, opus slowest.

**Deviations:** `node_modules` is absent from the worktrees, so no run could execute
`npm test`/`typecheck` — every cell correctly filed the commit's "all tests green" claim as
Unverifiable rather than asserting it. n=1 per cell. Same-issue matching against ground
truth is mine, unblinded.

---

## Findings volume

| | ND2 | ND3 | MD1 |
|---|---|---|---|
| sonnet | 1🔴 / 0🟡 / 13🟢 | 0🔴 / 5🟡 / 11🟢 | 1🔴 / 3🟡 / 6🟢 |
| opus | **5🔴 / 13🟡 / 14🟢** | 2🔴 / 9🟡 / 11🟢 | 3🔴 / 8🟡 / 14🟢 |
| fable | 3🔴 / 8🟡 / 12🟢 | 0🔴 / 4🟡 / 12🟢 | 1🔴 / 4🟡 / 10🟢 |

Opus's volume dominance from Result 7 replicates. Fable's brevity replicates on ND3/MD1
but **not** on ND2, where it produced 23 rows.

---

## Result 11 — The single-pass ceiling is broken. MD1 R1 falls to opus.

Result 8b's sharpest negative: MD1's R1 — `connect-src 'self'` blocking the `data:` URL
that `exportGraph.ts:24,37` fetches, a *different module from the diff* — "defeated every
single-pass run" at every tier, and was found historically only by the multi-critic
pipeline. Under the full pipeline:

| | R1 recovered |
|---|---|
| sonnet | ✗ — and affirmatively cleared it (see Result 12) |
| **opus** | **✓** — both call sites, plus the `img-src`/`font-src`-allow-`data:`-but-`connect-src`-doesn't asymmetry, and the exact fix the human shipped (`toBlob()`) |
| fable | ✗ — and affirmatively cleared it |

This is the first local evidence that the pipeline buys something single-pass fan-out
structurally cannot, rather than just more samples. Result 8b's conclusion — "single-pass
fan-out, any tier, has a ceiling below whole-codebase interaction bugs" — stands as
written and is now bounded: **the ceiling is a property of the config, not the model.**

## Result 12 — Non-total ordering replicates per-row, and the misses are false attestations

Result 9's H1 evidence was aggregate (fable found a 🔴 opus missed; opus found things fable
missed). On MD1 the exchange is visible row by row:

| GT row | opus | fable |
|---|---|---|
| R1 (`connect-src` breaks export) | 🔴 found | ✗ cleared |
| R2 (Edge-runtime comment) | 🟡 found | 🟡 found |

Opus demoted R2 from its historical 🔴 to 🟡 ("functionally harmless here, but it imposes a
false constraint on future authors"); fable filed it in a Mostly-Accurate comment cluster.
Sonnet landed on the exact claim, ruled it **Unverifiable**, and its rationale repeated the
error the claim contains ("Next.js proxy/middleware defaults to the Edge runtime unless
overridden").

**The misses are worse than silence.** Fable's own fact-check recorded the disconfirming
evidence — *"client fetches are all relative `/api/…` paths or `data:` URLs in
`app/lib/utils/exportGraph.ts:24,37`"* — and its security review then concluded
`connect-src 'self'` **"matches reality,"** with the rubric filing it under ✅ Confirmed
Good. Sonnet did the same, calling it "consistent with the stated server-to-server API
architecture." Result 8b observed this false-attestation shape at haiku; it is **not
tier-bounded**. A ✅ Confirmed Good row is the highest-assurance output the rubric has, and
two of three tiers put the branch's actual blocking defect in it.

## Result 13 — ND3: the tier floor is gone; all three tiers recover the blocking defect

| ND3 GT row | R7 generalist | R8a +security skill | full pipeline |
|---|---|---|---|
| A1 deserialize | sonnet 0/2, opus 2/2, fable 2/2 | sonnet 2/2, haiku 1/2 | **sonnet ✓, opus ✓, fable ✓** |
| A2 shared version constant | — | — | sonnet 🟡, opus 🟡, fable 🟢 |
| A3 throw convention | — | — | sonnet 🟢 only |

All three independently reconstruct GT A1's enumerated sub-vectors (F2 NaN-score
poisoning, F3 `completionFraction > 1.0` via forged category, F4 unbounded `entries`).
Result 8a's amendment — the floor is config-dependent, sonnet+role-skill ≈
opus-generalist — holds and extends: the pipeline additionally recovers the *non-security*
amber rows that no single-prompt config ever produced.

## Result 14 — Cross-tier convergence on defects the historical panel certified as clean

> **Amended by Result 14a (n=2).** The claim as originally written — "opus and fable
> independently produced the **same three 🔴 rows**" — **does not replicate**. At r2 the
> two tiers' red sets on these three rows intersect in *nothing*: R2 is red at opus only,
> R1 at fable only, R3 at neither. What survives replication is weaker and different in
> kind: the *mechanisms* behind R1 and R2 are found in 4/4 cells, but their **severity
> band is not stable** (each flips 🔴↔🟡 across replicates via the fact-check
> Incorrect-vs-Mostly-Accurate boundary), and R3 is 2/4. The load-bearing conclusion —
> that the historical ✅ Confirmed Good row *"All new constants match their comments"* is
> falsified — **stands**, on R2's 4/4 detection plus hand verification. Read the three
> bullets below as *mechanisms found*, not as *red rows agreed*. Details: Result 14a.

On ND2, opus and fable independently produced the following three findings, all fact-check
Incorrect **in r1**:

- R1 — the timer docblock claims it "mirrors how `wanderTimer`/`reproCooldown` are
  threaded"; neither field exists on `BehaviorContext`.
- R2 — `WARY_MOOD_DURATION`'s comment says the window was "Scaled down to the sim's faster
  tempo" from the concept's "~30s"; the value is `30.0`.
- R3 — a test comment states the committed flee threshold is `1.6`; that test's genotype
  yields `2.1`. The assertion passes for the wrong documented reason.

**R2 verified by hand** against the worktree: `behavior.ts:121-127` carries the "Scaled
down" comment above `export const WARY_MOOD_DURATION = 30.0;`, and `initial_concept.md:98`
reads "stays wary for ~30s". Identical, not scaled.

The historical ND2 rubric records **0 🔴**, "Fact-check found 0 Incorrect," and lists
*"All new constants match their comments"* under ✅ Confirmed Good. This is the first case
in the program where a fresh run **falsifies a historical Confirmed-Good row** — with two
independent frontier models agreeing on three separate mechanisms. Result 6's
acceptance-filtered ~99% precision figure should be read against this: the corpus cannot
see defects the original panel never raised.

## Result 15 — ND2's A1 is missed by all three tiers, and the mechanism is legible

No tier recovered the mood-inversion defect (grant CONTENT on *any* SINGING exit, so a
spooked singer becomes maximally approachable). Opus's tech-debt critic reached the exact
code path and then wrote:

> "Note this interacts with the deliberate design choice documented at `sim.ts:623-627`
> (a FLEE-interrupted song still earns the CONTENT mood); **that choice is fine**"

Sonnet's fact-check documented both halves separately — Claim 4 (`SINGING → CONTENT`) and
Claim 5 (`FLEE` interrupts `SINGING`) — and never joined them.

> **Sharpened by Result 14a.** At r2, opus did not clear A1 — it reconstructed the
> mechanism completely ("mechanically it is a reward", "invisible to tests") and filed it
> **🟢 Consider**. The failure is therefore not comprehension and not the docstring
> deferring alone; a run can hold the full defect and still band it advisory.

This is Result 7's F18 lesson replicating exactly: **an in-code intent claim is treated as
dispositive, and the dominant false-negative class is true-mechanism / documented-intent.**
The next commit (`31fd3c4`) is the human fixing this behavior as blocking finding A1, so
revealed preference contradicts the docstring again. Result 7's conclusion — that an
adjudicator deferring to in-code intent under-counts exactly the findings humans act on —
now extends from the *adjudicator* to the *reviewer*.

## Result 16 — Escalation fires only on fact-check corroboration, as designed

Every 🔴 in all nine runs traces to a fact-check **Incorrect** verdict or an
api-consistency **Breaking** finding. Not one traces to critic convergence alone —
multiple rubrics found 3-critic convergence and explicitly declined to promote it, citing
the absent corroboration. Opus on ND3 states the rule outright while escalating
`COMPLETION_BONUS_WEIGHT` 🟡→🔴 "on the fact-check Incorrect verdict at the same constant
(corroboration is a fact-check verdict, not another critic's opinion)."

Result 2 called the escalation rule "nearly inert." It is now inert *by construction*
rather than by accident, and the corroboration channel that does fire is the one Result 5
recommended — evidence the author's values cannot dispute.

## Result 17 — Severity assignment remains the least stable output

| Item | Historical | sonnet | opus | fable |
|---|---|---|---|---|
| MD1 nonce never reaches the HTML | 🟡 A1 (api-consistency) | 🔴 | 🔴 | 🔴 |
| MD1 R2 Edge-runtime comment | 🔴 | ✗ | 🟡 | 🟡 |
| ND3 A2 shared version constant | 🟡 | 🟡 | 🟡 | 🟢 |
| ND3 A3 throw convention | 🟡 | 🟢 | ✗ | ✗ |

Result 8b flagged the first row as "a severity dispute worth adjudicating someday" after
both opus replicates rated it Critical against the historical 🟡. Three independent
configs now rate it blocking. The dispute is empirical (does the page render under this
Next version?) and remains untested. Result 1's finding stands: presence is far more stable
than tier, and gates should key on issue identity or the blocking band, not on 🟡-vs-🟢.

---

## Result 14a — ND2 replication (n=2)

Two cells, byte-identical prompts to r1, only the tier name differing: `run-review.sh nd2
opus 2` and `run-review.sh nd2 fable 2`. Both `rc=0` (opus 1700 s, fable 1111 s). Same
pre-fix worktree, same `--no-gate`, same uniform-tier dispatch. Artifacts at
`/home/node/cr-eval/runs/nd2-{opus,fable}-r2/`.

### The headline: the convergence does not reproduce

Result 14's claim was that two tiers independently produced *the same three 🔴 rows*. At
r2 the two tiers' red sets on those three rows **intersect in nothing**.

| GT-14 row | opus r1 | opus r2 | fable r1 | fable r2 | 🔴 in r2? |
|---|---|---|---|---|---|
| R1 timer docblock (`behavior.ts:77`) | 🔴 Incorrect | 🟡 Mostly Accurate (A2) | 🔴 Incorrect | 🔴 Incorrect (R2) | opus **no**, fable **yes** |
| R2 `WARY_MOOD_DURATION` (`behavior.ts:121-127`) | 🔴 Incorrect | 🔴 Incorrect (R1) | 🔴 Incorrect | 🟡 Mostly accurate (A5) | opus **yes**, fable **no** |
| R3 test comment `1.6` (`sim.test.ts:255`) | 🔴 Incorrect | **absent** | 🔴 Incorrect | **absent** | opus **no**, fable **no** |

Two of six red-reproduction opportunities landed, and they landed in *opposite* cells. The
"both tiers agree on all three" event reproduced zero times out of one.

### What does survive, and it is worth separating

**Mechanism detection is robust; severity banding is not.** R1 and R2 were each *found and
correctly described* in 4/4 cells. Every cell that demoted one still stated the defect in
plain terms — fable r2 on R2: *"WARY_MOOD_DURATION is 30.0 s, identical to the original's
'~30s'; the value was kept, not scaled"*; opus r2 on R1: *"`wanderTimer`/`reproCooldown`
… are **not** threaded into `BehaviorContext`; compare to `hunger` instead."* Identical
finding, identical evidence, different band. The flip is entirely carried by one
fact-check verdict boundary — **Incorrect vs Mostly Accurate** — which Result 16 showed is
the *sole* channel that can produce a 🔴. Result 17 said severity is the least stable
output across tiers; 14a extends that to **across replicates of the same tier**, and shows
it is a single binary classification, not a gradual disagreement.

**R3 is different — it is a genuine detection miss, and the mechanism is legible.** The
string `1.6` appears at four comment sites in the diff's test files. At three of them
(`behavior.test.ts:89,171,173`) it is *correct*: those tests hand-build a phenotype with
`fleeDistance: 4.0`, and `4.0 × STATE_COMMITMENT.EATING (0.4) = 1.6`. Only
`sim.test.ts:255` is wrong, because that test builds a `World` from seed 7 and the
resulting genotype expresses `fleeDistance = 5.25` → `2.1`. Both r2 runs checked a
`behavior.test.ts` site, verified it, and never visited `sim.test.ts:255`. This is a
sampling failure with a decoy: the claim is checkable, but the *correct* instance is more
numerous and is what claim-enumeration lands on first.

**The load-bearing conclusion holds.** The historical rubric's ✅ Confirmed Good row *"All
new constants match their comments"* is still falsified — by R2, found in 4/4 cells, and
verified by hand below. Result 14's corpus-blindness caveat on Result 6 stands unchanged.
What does not stand is treating two-tier red agreement as the evidence for it.

### Independent verification (not taken from any agent's report)

Read directly from the pre-fix worktree at
`/home/node/.claude/jobs/92e878b0/tmp/wt/nd2/`:

`packages/sim-core/src/behavior.ts:121-127` —

> ```
>  * Post-ANGRY WARY window (seconds) during which the creature's flee distance is elevated
>  * (original: "Post-ANGRY return ... stays wary for ~30s"). Scaled down to the sim's
>  * faster tempo but kept the LONGEST mood window so a spooked creature stays hard to
>  * approach for a while.
>  */
> export const WARY_MOOD_DURATION = 30.0;
> ```

`initial_concept.md:98` — `Post-ANGRY return  6.0m  Spooked, stays wary for ~30s`.
`30.0 === ~30`. Nothing was scaled. **R2 confirmed.**

R1 confirmed the same way: `BehaviorContext` (`behavior.ts:56-85`) declares `state`,
`phenotype`, `hunger`, `distanceToPlayer`, `playerSpeed`, `playerStealth`,
`distanceToNearestFood` and the four new mood/timer fields — no `wanderTimer`, no
`reproCooldown`; the only occurrence of either identifier in the whole file is the
docblock making the claim, at line 77.

R3 confirmed to the arithmetic: `sim.test.ts:255` reads *"inside the committed flee
threshold (1.6)"*, and with `STATE_COMMITMENT.EATING = 0.4`, `playerSpeed: 1 ===
CALM_PLAYER_SPEED` (speed factor 1.0) and `stealth: 0` (stealth factor 1.0), the threshold
is exactly `fleeDistance × 0.4` — so `1.6` requires `fleeDistance = 4.0`, and the r1 runs'
independently-reported `5.25` for seed 7 gives `2.1`. The comment is wrong for any
genotype except the hand-built one from the *other* test file.

### Findings volume, all four ND2 cells

| | 🔴 | 🟡 | 🟢 | total | elapsed |
|---|---|---|---|---|---|
| opus r1 | 5 | 13 | 14 | 32 | — |
| opus r2 | 3 | 10 | 19 | 32 | 1700 s |
| fable r1 | 3 | 8 | 12 | 23 | — |
| fable r2 | 2 | 6 | 12 | 20 | 1111 s |

Total volume is stable within tier (opus 32/32, fable 23/20); the *distribution across
bands* is not. Opus moved five rows down a band net; fable moved three. Result 11/7's
opus-volume dominance replicates.

### J_self — within-tier replicate agreement

**Matching criteria, stated explicitly.** Two rows match if they name the same file (or
same file pair for cross-file findings) *and* the same underlying mechanism, regardless
of: rubric band (🔴/🟡/🟢), row ID, critic of origin, or wording. Where one replicate
splits a mechanism across two rows and the other merges them (e.g. opus r1's R4 + R5 vs
opus r2's C14; fable r1's A7 + A8 vs fable r2's R1), the pair is collapsed to one cluster
before counting, so a formatting choice cannot inflate the union. Sandbox-bookkeeping rows
("`npm test` unverifiable") are excluded from both sides as artifacts of the deviation,
not findings. Matching is mine and unblinded, same as the r1 ground-truth matching.

| Tier | ∩ | r1-only | r2-only | ∪ | **J_self** |
|---|---|---|---|---|---|
| opus | 21 | 11 | 11 | 43 | **≈ 0.49** |
| fable | 14 | 7 | 4 | 25 | **≈ 0.56** |

Restricted to the red band alone, agreement collapses:

| Tier | red ∩ | red ∪ | **J_self(🔴)** |
|---|---|---|---|
| opus | 1 (`WARY_MOOD_DURATION`) | 7 | **0.14** |
| fable | 1 (timer docblock) | 4 | **0.25** |

So roughly **half** the finding set is reproducible within a tier, but only **one red row
per tier** is. Cluster-merge judgment calls move the issue-level numbers by about ±0.05;
they do not move the red-band numbers, which are small enough to enumerate by hand.

**A different cross-tier convergence did appear in r2.** Opus r2's R2+R3 (widening
`BehaviorState` breaks consumer `switch`/`Record`; four new *required* `BehaviorContext`
fields break hand-built contexts) and fable r2's R1 are the same mechanism, filed 🔴 by
both tiers. In r1 both tiers had this content too — but at 🟡 (opus A4, fable A7/A8, the
latter explicitly tier-noting "critic-native severity is Breaking (→🔴 per mapping);
tiered 🟡 because the break is fully contained in-commit"). Cross-tier convergence on ND2
is therefore real and repeatable in *kind*; it just does not stay attached to the same
rows. Both r2 cells also note this row has zero live blast radius (`private`, `0.0.0`, no
consumers), which is what the r1 cells used to justify holding it at 🟡.

### Finding in r2 but not r1 that is more severe than anything in r1

**Yes, and it is the ground truth.** Opus r2 filed as **C1** (🟢 Consider, "highest-signal
advisory"):

> "A FLEE-interrupted song still sets CONTENT (`sim.ts:637-640`, keyed on `from ===
> "SINGING"` unconditionally …). Consequence: interrupting a song halves the creature's
> flee threshold for 6 s, so it leaves FLEE almost immediately and becomes *more*
> approachable. The stated design intent (`behavior.ts:152-156`) is that interrupting a
> song is 'the failure mode players learn to avoid' — mechanically it is a reward.
> Invisible to tests, which assert only the transition, never the tick after."

That is ND2's **GT A1** — the mood inversion the human fixed as a blocking finding in the
very next commit (`31fd3c4`), and the defect Result 15 recorded as missed by all three
tiers at r1. It is categorically more severe than any r1 red row on this diff: every r1
🔴 is a comment-accuracy or contained-API-break issue, while this is a live behavioral
inversion of the feature's central mechanic.

This forces an amendment to Result 15's mechanism. At r1, opus reached the code path and
*cleared* it ("that choice is fine") — consistent with Result 15's reading that an in-code
intent claim is treated as dispositive. At r2, opus reached the code path, **rejected** the
intent claim explicitly ("mechanically it is a reward"), reconstructed the full
consequence including the test blind spot — and still filed it 🟢. Result 16's rule
explains why: no fact-check **Incorrect** verdict and no api-consistency **Breaking**
verdict attached to it, and *nothing else in the pipeline can produce a 🔴*. The escalation
rule that Result 16 praised as "inert by construction" is, on this diff, the thing standing
between a correct full-mechanism reconstruction of the branch's real defect and a red row.
A tech-debt critic cannot escalate, no matter what it finds.

(Opus r2 also surfaced 🟢 C8 — WARY's 30 s × 1.5 can raise the flee threshold to ~9.0 in a
10×10 world, making FLEE absorbing for the full window — which is new in r2 and plausibly
more severe than the r1 reds. It is downstream of R2: the window is 30 s *by accident*,
because nothing was actually scaled.)

### What this settles

- **Settled negative:** ND2's three-red cross-tier convergence is not a stable property of
  the pipeline. Do not cite it as two independent models agreeing on three rows.
- **Settled positive:** the historical ✅ Confirmed Good row on constants-match-comments is
  wrong, on 4/4 mechanism detection plus hand verification. Result 14's caveat on Result 6
  is unaffected.
- **New:** within-tier J_self ≈ 0.5 issue-level, ≈ 0.14–0.25 red-level. Any gate keyed on
  red-row identity is keying on the least reproducible output the pipeline has. Result 1's
  "presence is more stable than tier" needs the companion caveat that *presence is much
  more stable than band*, and that band is where gates read.
- **New:** the 🔴 monopoly held by fact-check-Incorrect / api-Breaking (Result 16) is now
  a demonstrated false-negative mechanism, not just a design property — it suppressed a
  fully-reconstructed GT A1 to 🟢.

---

## Decision table delta

| Prior position | Status after this arm |
|---|---|
| Thread 4: in-loop scaffolding not evaluable | **Closed.** Evaluable with `--permission-mode acceptEdits --add-dir`. Local repo history + pre-fix worktrees is a working corpus. |
| R7/R8: do not run critics below opus | **Softened for ND3-class defects** (all tiers recovered A1), **reaffirmed for MD1-class** (only opus recovered the cross-file 🔴). Tier still buys the hardest band. |
| R8b: single-pass ceiling below cross-file bugs | **Confirmed as a config property.** The pipeline clears it at opus. |
| R8b: weak reviews are false attestations | **Widened.** Observed at sonnet *and* fable, on the branch's actual 🔴, with the disconfirming evidence present in the same run's fact-check. Tier does not protect against this. |
| R9 H1: non-total ordering across models | **Replicated per-row** on MD1. |
| R6: ~99% precision of persisted rubrics | **Caveat sharpened, and it survives 14a.** The corpus is blind to defects the original panel never raised. Rests on R2's 4/4 mechanism detection + hand verification, no longer on two-tier red agreement. |
| R14: two tiers agree on three 🔴 rows | **Falsified at n=2.** Red sets on those rows intersect in nothing at r2; R3 vanishes from both cells. Mechanisms replicate 4/4 (R1, R2) and 2/4 (R3); bands do not. Result 14a. |
| R17: severity is the least stable output *across tiers* | **Widened to within-tier.** J_self(🔴) ≈ 0.14 (opus) / 0.25 (fable) across replicates of the same tier on the same diff. Result 14a. |
| R16: escalation is inert by construction, fires only on fact-check corroboration | **Reclassified as a false-negative mechanism.** Opus r2 fully reconstructed ND2's GT A1 — rejecting the docstring's intent claim outright — and filed it 🟢, because no fact-check-Incorrect or api-Breaking verdict could attach. Result 14a. |
| R7: dominant FP class is true-mechanism / disputed-intent | **Extended to false negatives (Result 15), then sharpened by 14a:** comprehension is not the binding constraint — a run can hold the whole defect and still band it advisory. |

## Highest-value follow-ups

1. **Replicates — ND2 done, and it came back negative.** Result 14a ran opus r2 and
   fable r2. The three-red convergence **did not reproduce**; within-tier J_self is ≈0.49
   (opus) / ≈0.56 (fable) issue-level and ≈0.14 / 0.25 on the red band alone. Two live
   consequences, both now higher-value than more ND2 replicates:
   (a) **Re-run ND3 and MD1 at n=2 before any of their per-row claims are cited** —
   Results 11, 12, 13 and 17 all rest on single-cell red/amber assignments, and 14a shows
   band assignment flips between replicates of the same tier on the same diff. MD1 R1
   (opus-only recovery) is the most load-bearing single cell in the program and is
   unreplicated.
   (b) **Adjudicate the Incorrect-vs-Mostly-Accurate boundary in `code-fact-check`.** It is
   the sole 🔴-producing channel (Result 16) and it is the entire mechanism of the r1↔r2
   divergence — the same defect, described identically, lands on either side of it. A
   worked rubric or few-shot calibration for that one verdict pair would buy more stability
   than a tier upgrade.
2. **A `✅ Confirmed Good` audit.** Result 12 makes that section the most dangerous output
   in the rubric. Nothing currently checks it, and it is where two of three tiers filed
   MD1's blocking defect.
3. **Fix `self-improvement.sh:1295`** to pass both flags — Gate 1h is currently running
   paraphrased critics and discarding their artifacts.
4. **Adjudicate the MD1 nonce severity empirically** — three configs say 🔴, history says
   🟡, and one prod build settles it.

## Reproduction

- Runner: `run-review.sh` / `driver.sh` in the session job scratchpad; run artifacts under
  `/home/node/cr-eval/runs/<diff>-<tier>-r<n>/` (full `docs/reviews/` tree per cell). r1 for
  all nine cells; r2 additionally for `nd2-opus` and `nd2-fable` (Result 14a).
- **Reading a cell's rubric:** each worktree carries *older* in-tree rubrics from earlier
  branches (nd2's includes `code-review-rubric-2026-06-19-feature-observation-catalog.md`,
  and the pre-existing `code-review-rubric.md` at the pre-fix commit). Select by content —
  the file must name commit `2d0ee3c` **and** `Reviewed: 2026-07-30` — not by glob order or
  mtime.
- Worktrees: detached at `2d0ee3c`, `319f229`, `d90d6bb` in `external/`.
- Ground truth: `31fd3c4:docs/reviews/code-review-rubric.md` (ND2),
  `1b0dcc8:…` (ND3), `6e88a5b:docs/reviews/csp-headers/code-review-rubric.md` (MD1).
