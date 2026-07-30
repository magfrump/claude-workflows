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

The strongest new result, and it runs the other way. On ND2, opus and fable independently
produced the **same three 🔴 rows**, all fact-check Incorrect:

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

## Decision table delta

| Prior position | Status after this arm |
|---|---|
| Thread 4: in-loop scaffolding not evaluable | **Closed.** Evaluable with `--permission-mode acceptEdits --add-dir`. Local repo history + pre-fix worktrees is a working corpus. |
| R7/R8: do not run critics below opus | **Softened for ND3-class defects** (all tiers recovered A1), **reaffirmed for MD1-class** (only opus recovered the cross-file 🔴). Tier still buys the hardest band. |
| R8b: single-pass ceiling below cross-file bugs | **Confirmed as a config property.** The pipeline clears it at opus. |
| R8b: weak reviews are false attestations | **Widened.** Observed at sonnet *and* fable, on the branch's actual 🔴, with the disconfirming evidence present in the same run's fact-check. Tier does not protect against this. |
| R9 H1: non-total ordering across models | **Replicated per-row** on MD1. |
| R6: ~99% precision of persisted rubrics | **Caveat sharpened.** Result 14 shows the corpus is blind to defects the original panel never raised, not merely to ones it raised and the author rejected. |
| R7: dominant FP class is true-mechanism / disputed-intent | **Extended to false negatives.** Result 15. |

## Highest-value follow-ups

1. **Replicates.** n=1 per cell; ND2's opus/fable convergence deserves a second replicate
   before it is treated as settled.
2. **A `✅ Confirmed Good` audit.** Result 12 makes that section the most dangerous output
   in the rubric. Nothing currently checks it, and it is where two of three tiers filed
   MD1's blocking defect.
3. **Fix `self-improvement.sh:1295`** to pass both flags — Gate 1h is currently running
   paraphrased critics and discarding their artifacts.
4. **Adjudicate the MD1 nonce severity empirically** — three configs say 🔴, history says
   🟡, and one prod build settles it.

## Reproduction

- Runner: `run-review.sh` / `driver.sh` in the session job scratchpad; run artifacts under
  `/home/node/cr-eval/runs/<diff>-<tier>-r1/` (full `docs/reviews/` tree per cell).
- Worktrees: detached at `2d0ee3c`, `319f229`, `d90d6bb` in `external/`.
- Ground truth: `31fd3c4:docs/reviews/code-review-rubric.md` (ND2),
  `1b0dcc8:…` (ND3), `6e88a5b:docs/reviews/csp-headers/code-review-rubric.md` (MD1).
