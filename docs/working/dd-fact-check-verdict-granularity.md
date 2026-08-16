# DD — "mostly accurate" is not enough: fixing the fact-check verdict on compound claims

**Goal**: decide the schema/spec change that stops severe doc-claim defects from
stalling at **Mostly accurate** when the replicate's own prose refutes the claim's
stated mechanism. **Trigger**: fc-model-sweep 2026-08-15 — all 6 replicates (3 models)
verdicted N10 *Mostly accurate*, and 5 of 6 did the same for dep-R1, while every one
of them stated the Incorrect-grade refutation in full in the explanation. User framing
(2026-08-15): "an instance of a code claim being 'mostly true' but mostly being not
enough for the circumstance." **Task status**: decided (Path C — autonomous), decision
record 033; validation run appended below.

## The evidence, read closely (what exactly failed)

1. **The failure is unanimous, cross-model, and verdict-stable** — 11 of 12 relevant
   verdicts landed MA (sonnet-r2 alone said Incorrect on dep-R1). This is not model
   noise and not Result-14a instability; it is the spec steering all three models to
   the same wrong label. A model-choice fix cannot touch it (H3 below).
2. **The prose is right every single time.** Every MA verdict on N10/dep-R1 contains
   the refutation verbatim: "unset does not by itself produce the mock; the route
   substitutes a default URL" (opus-r2), "the writes never reach `/tmp` at all, and
   are caught-and-discarded on every invocation" (sonnet-r2, which alone followed the
   evidence to Incorrect). The *evidence* is the stable quantity; the *label* is the
   miscalibrated one. This mirrors the Unified-Severity-Mapping principle already in
   the skill: tier labels are the least stable output, native evidence the most —
   key decisions on the stable quantity.
3. **Every miscalibrated row is a compound claim.** N10 = mechanism atom ("unset →
   mock") + outcome atom ("on Vercel you get the mock"): first refuted, second true.
   dep-R1 = dev atom (true) + platform atom (true) + mechanism atom ("these writes
   go to /tmp, survive the warm container" — refuted: they target `cwd()/data`,
   throw, and are swallowed). The models verdict the *molecule* by its conclusion
   and refute an *atom* in prose. The rows that did NOT miscalibrate (csp-R2/A2/A3,
   6/6 Incorrect each) are atomic claims. The pattern is exact: **the schema fails
   precisely at compound claims and nowhere else.**
4. **The models already want the missing grain.** opus-r2 spontaneously invented a
   sub-claim split (Claim 17/17a) to give a compound commit-message claim's parts
   different verdicts (Verified vs Unverifiable). fable-r1/r2 and opus-r1/r2 all
   wrote "the *unreachable* half is exact… the *unset* half is imprecise" — a
   decomposition in prose that the one-verdict-per-claim format then forced them to
   collapse. The current skill text actively causes the collapse: "choose Mostly
   accurate when a claim is directionally right but missing a qualifier" beat
   "reserve Incorrect for mismatches that would mislead a reader acting on the
   comment" 11 times out of 12 — evidence that when two prose criteria conflict,
   the concrete one ("directionally right") wins over the judgment one ("would
   mislead").
5. **What the miscalibration actually costs downstream** (consumer map, code-review
   SKILL.md): (a) the Fact-Check Gate pauses only on Incorrect-high — never fired;
   (b) the Escalation Rule accepts only an Incorrect verdict as tier-promotion
   corroboration — MA can't corroborate; (c) tiering: MA → 🟡, while dep-R1/N10 are
   exactly 031's carve-out class ("documents a contract a future change would bind
   to and be misled by" → stays 🔴) — unreachable from MA. Under 0R+0A the row
   still gets fixed (🟡 is visible), so the loss is the gate, the corroboration
   channel, and the 🔴 authority on binding-contract misdocumentation — narrow but
   real, and dep-R1 is the canon's gold cross-file row.
6. **The constraint that bites: decision 031 deliberately narrowed the red band**
   (marginal doc-verdict variance controls loop length, ~1M tokens per marginal-red
   pass). Any fix that re-admits a *judgment-shaped* criterion into the blocking
   band partially reverses 031. A fix is admissible only if its promotion criterion
   keys on the stable quantity (a refuted atom, checkable in the prose) rather than
   a fresh holistic judgment.

## 1. Diverge

1. **Do nothing** — MA rows are 🟡-visible and fixed under 0R+0A anyway; loss is
   gate + corroboration + binding-contract 🔴 only. [reframe/baseline]
2. **Prose calibration tweak** — add "a refuted mechanism makes the claim Incorrect
   even when its practical conclusion holds" to the verdict definitions. [minimal]
3. **New verdict value `Misleading`** — right conclusion / refuted mechanism, slotted
   between Stale and MA in the severity order. [schema-small]
4. **Two-axis split** — keep the 5-enum as *Accuracy*, add an orthogonal *materiality*
   field (`Acting-on-it: Safe | Misleading | Defect-masking`); blocking keys on
   materiality × confidence. The user's stated instinct. [schema-large]
5. **Atomic decomposition mandate** — a compound claim whose parts would earn
   different verdicts MUST be split into sub-claims (7a/7b), each verdicted with the
   existing enum; when splitting is impractical, the compound takes its
   **most severe part's verdict** (intra-claim most-severe-wins, mirroring the
   k-merge rule). [procedural/schema]
6. **Merge-time re-tiering** — orchestrator scans MA prose for refutation language
   and promotes at merge. [pipeline]
7. **Gate-input widening** — Fact-Check Gate/escalation also accept "MA-at-High whose
   explanation refutes the stated mechanism." [pipeline]
8. **`If-believed:` consequence line** per non-Verified claim; tiering keys on it.
   [schema-mid; a lighter #4]
9. **Blocking on all MA-at-High.** [naive]
10. **Ideal-if-free**: formal (premise, mechanism, conclusion) triple per claim with
    derived severity. [ideal → approximated by #5]
11. **Punt to critics** — refuted-mechanism rows are code findings (dep-R1's swallowed
    EROFS *is* N12's defect); let Stage-2 own severity. [reframe]

Health check: schema (3,4,5,8,10), pipeline (6,7), spec-prose (2), baseline/naive/
ideal/reframe present (1,9,10,11). The schema cluster is intentional — the evidence
localizes the failure there.

## 2. Diagnose — constraints

- **H1 (hard)** stability: the promotion criterion must key on the measured-stable
  quantity (a specific atomic claim the code refutes), not a new holistic judgment;
  no reversal of 031's loop-stability win. `success:` on the existing 12 sweep
  reports, the criterion identifies dep-R1/N10 in ≥11/12 replicates (the refutation
  prose is present in 12/12) and matches zero benign qualifier-miss rows.
- **H2 (hard)** bounded consumer churn: format bats suite, k-merge (total severity
  order), Gate 1h parser, severity mapping, Stage-1.5 must keep working, with every
  required edit enumerable. `success:` list of consumer edits; merge order total.
- **H3 (hard)** model-independent and pin-preserving: must not invalidate the
  2026-08-15 opus pin; re-validation must be cheap (≤2 replicates, one cell).
- **H4 (hard)** k-merge compatible: clustering must handle one replicate's molecule
  matching another's atoms.
- Soft: fact-check stays a fact-checker (severity-of-consequence judgment is critic
  territory — non-goals list); auditability (verdict derivable from quoted
  evidence); minimal added tokens; lands before A8 (behavior-affecting skill prose).

## 3. Match & prune

| # | option | H1 stable-criterion | H2 churn | H3 pin-safe | H4 merge | verdict |
|---|---|---|---|---|---|---|
| 5 | atomic decomposition + intra-claim most-severe | ✓ (keys on the refuted atom; models already emit the split in prose, once spontaneously in schema) | ✓ minimal (no enum/field change; bats unchanged; one clustering amendment) | ✓ (spec change orthogonal to model; 2-rep revalidation) | ✓ (molecule clusters with its atoms; most-severe across cluster) | **survive — primary** |
| 2 | prose tweak alone | ⚠ (the existing "would-mislead" prose already lost 11/12 to "directionally right" — prose loses to prose) | ✓ | ✓ | ✓ | survive as component of #5 only |
| 4 | two-axis materiality | ⚠ ("is mostly enough *here*?" is a fresh context-dependent judgment — dev vs Vercel flips it; new instability surface, the 031 risk) | ✗ heaviest (new mandatory field: skill, merge, bats, Gate-1h, mapping, critics-as-readers) | ⚠ (pin measured on current schema; bigger delta) | ⚠ (per-axis orders + combination rule needed) | prune as default; **queue as fallback experiment** |
| 3 | `Misleading` verdict | ~ (checkable if defined by refuted-atom test — but then it *is* #5 with a label; if defined holistically, unstable) | ✗ enum change everywhere | ✓ | ✓ (insert in order) | prune (dominated by #5) |
| 7 | gate-input widening | ~ (gate re-reads prose — judgment at gate time) | ✓ light | ✓ | ✓ | prune as primary; unnecessary once #5 emits Incorrect atoms |
| 6 | merge-time re-tiering | ✗ violates "merge is mechanical collation, not analysis" (Mandatory Rule 1) | ✓ | ✓ | ✓ | prune |
| 8 | If-believed line | ~ free-prose severity — ungate-able | ~ | ✓ | ✓ | prune → folds into #4 fallback |
| 9 | block all MA-high | ✗ floods gate with qualifier-misses; reverses 031 | ✓ | ✓ | ✓ | prune |
| 11 | punt to critics | ⚠ half-true (dep-R1 ⇢ N12 is critic domain) but N10 has no code defect, and Stage-1.5 only *narrows*, never promotes — no path | — | — | — | prune, keep the insight |
| 1 | do nothing | — | — | — | — | prune (motivating class includes the gold row) |
| 10 | claim calculus | ✓ | ✗✗ | ✗ | ✗ | prune → #5 is its practical form |

## 4. Tradeoff + decision

**Decision (Path C): adopt #5 + #2 —**

1. **Atomic-verdict rule** in `code-fact-check` SKILL.md: a compound claim whose
   checkable parts would earn different verdicts must be split into sub-claims
   (`## Claim 7a:` / `## Claim 7b:`), each with the full five fields. Split only on
   verdict divergence — never atomize claims whose parts agree (anti-pedantry guard).
2. **Intra-claim most-severe-wins** when splitting is impractical: the compound's
   verdict is its most severe part's verdict, stated with which part carries it. A
   "directionally right conclusion" never outweighs a refuted mechanism — mirrors
   the k-merge aggregator and the same rationale (observed failure mode is
   under-calling).
3. **Definition tightening** (#2): *Mostly accurate* requires mechanism AND
   conclusion both right, merely imprecise; a claim whose stated mechanism the code
   refutes is *Incorrect* (or *Stale* if it was once true) for that part, whatever
   its practical conclusion. Worked example: N10 verbatim.
4. **Clustering amendment** in code-review SKILL.md merge step: a replicate's
   compound claim clusters with another replicate's sub-claims of it; most-severe
   still wins across the cluster.

**Stress tests.** *Boring alternative* (#2 alone): rejected on the sweep's own data —
the skill already contains the "would mislead a reader acting on it" criterion and it
lost 11/12 when a competing prose criterion tugged the other way; a structural rule
(where the verdict attaches) beats another sentence of guidance. *Invert #4* (argue
the user's two-axis now): the invert surfaces that materiality is context-dependent —
"unset → mock" is harmless on Vercel and wrong in dev — so a single materiality label
per claim re-imports instability; decomposition sidesteps the judgment by verdicting
each context-scoped atom with the existing calibrated enum. It also surfaces #4's
real residual value: pure *omission* hazards ("returns null on failure" — true, but
omits that failure also corrupts state) have no refuted atom and stay invisible to #5.
That class is critic territory (fsc-A1-shaped), but if the next canon measurement
shows fact-check-adjacent omission misses, #4 is the queued experiment — gated on a
recall check, exactly how k=1 and the opus pin were handled. *Failure-driven* on #5:
failure mode is decomposition drift between replicates breaking clustering →
mitigated by the clustering amendment (molecule ↔ atoms match) and by splitting only
on verdict divergence, which caps atom counts.

**Why this also serves 031 rather than reversing it**: the blocking band widens only
by atoms the replicate itself proves refuted — the stable quantity — while the
unstable holistic Inc↔MA boundary judgment is *removed* for compounds (each atom is
nearer a clean Verified-or-Incorrect call). Expected side effect: Result-14a-style
verdict flips should *drop*, since the flip-prone cases were exactly these molecules.

## 5. → decision record 033; validation run

Validation (H1/H3): re-run Stage-1 k=2, opus, mfc-deploy, amended skill text,
same brief. Pass criteria: N10 and dep-R1 mechanism atoms land Incorrect (≥1 of 2
reps each); no severity inflation on benign rows. **Result: PASSED, 2/2 on both
target atoms (N10 at Incorrect-High, dep-R1 at Incorrect-Medium), zero benign
inflation, splits spontaneous and format-clean — full table in decision 033's
validation addendum.**
