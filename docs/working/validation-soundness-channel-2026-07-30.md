# Validation replay: decision 028's Soundness-Contradiction Channel against the archived eval corpus

**Goal**: Run decision 028's falsifier — a retrospective replay of the Soundness-Contradiction
Channel trigger (`skills/code-review/SKILL.md` § "Soundness-Contradiction Channel") over all 11
archived eval cells at `/home/node/cr-eval/runs/` — measuring recall on the known ND2
FLEE/CONTENT soundness defect and false-lift precision over the full finding corpus, before the
channel can be trusted (and before its 🟡 cap could ever be raised).
**Project state**: exp/cross-model-openrouter-sweep, standalone, not blocked.
**Task status**: complete.

## Method

- Cells: 11 (md1×3, nd2×5, nd3×3), per the inventory in
  `docs/working/retrospective-confirmed-good-2026-07-30.md` §1. Run-written artifacts selected by
  write-timestamp (worktree-checkout files are all 11:30:55; run outputs minutes later) and
  content — Trap 1 (state doc §5.4) avoided; the nd2-fable cells carry stale undated duplicates of
  tech-debt/api-consistency/fact-check reports beside the dated run-written ones, and
  `dependency-upgrade-review.md`/`override-log.md` are stale checkout in every cell.
- Trigger applied mechanically to each finding's actual text, per the channel's three conditions:
  **C1** stated intent quoted verbatim with `path/to/file:line` · **C2** mechanism quoted or
  reconstructed with `path/to/file:line` · **C3** the report itself states the mechanism defeats
  or inverts that intent. Precision guard as written (intent claim alone, missing quote on either
  side, or design-wisdom disagreement never qualifies).
- Scope: critic reports only (security / performance / api-consistency / architecture /
  tech-debt-triage / test-strategy), matching the Stage-3 cross-check's sweep. Fact-check reports
  and rubrics are not critic reports; rubrics were used only to identify each finding's filed tier.
- Corpus size: **315 findings** (md1 89 · nd2 ≈144 · nd3 82) across ~27 run-written critic reports.
- Condition 3 was pre-filtered by inversion vocabulary (invert/defeat/negate/contradict/
  self-cancel/opposite/undermine), then every intent-quoting finding was tested individually
  regardless of vocabulary, so C3-absence was established from finding text, not assumed.

## 1. Positive case — the FLEE-interrupted-song/CONTENT defect (must lift)

**Only one of the five ND2 cells filed the defect: nd2-opus-r2**, tech-debt-triage item 2
("`MOOD_MULTIPLIER` applies to FLEE, so an interrupted song self-cancels",
`/home/node/cr-eval/runs/nd2-opus-r2/repo/docs/reviews/tech-debt-triage-review.md:118-182`),
carried into the rubric as **C1, filed 🟢** ("Highest-signal advisory") — exactly the Results
15/14a miss decision 028 exists to fix.

| Condition | Met? | The finding's actual text |
|---|---|---|
| C1 intent verbatim + file:line | **yes** (one nuance) | "The commit's headline design claim is that SINGING is the most skittish state (commitment 1.4) so that \"interrupting a song (FLEE) [is] the failure mode players learn to avoid\" (`behavior.ts:152-154`)". Source at behavior.ts:152-154 reads "makes interrupting a song (FLEE) the failure mode players learn to avoid" — verbatim-contiguous with one bracketed editorial `[is]` replacing the elided verb "makes". Also quotes the docstring's "a deliberate small mercy" (located via the finding's `sim.ts:637-640` evidence). |
| C2 mechanism + file:line | **yes** | Two labeled verbatim evidence blocks — `MOOD_MULTIPLIER` at `behavior.ts:172-176` and the `from === "SINGING"` → `c.mood = "CONTENT"` branch at `sim.ts:637-640` — plus the full arithmetic reconstruction (4.0×1.4=5.6 → FLEE; next tick 4.0×1.0×0.5=2.0 → exits FLEE in one tick). |
| C3 stated inversion | **yes** | "The 'failure mode' is, mechanically, a reward. That inverts the learnability the design soul requires" · "silently negates one of the two features the commit exists to add". |

**Verdict: LIFT — 🟢 → 🟡 `Contested-Soundness`.** The rubric row C1 itself repeats both quotes
with file:line (`behavior.ts:152-156` + `sim.ts:637-640`), so the lift is executable from either
artifact. This is the human panel's ground-truth band (H8).

**Calibration finding (the step-1 wording check):** C1 is satisfied **only if "verbatim" admits
standard bracketed alterations and elision**. A byte-exact reading of "verbatim" fails the one
finding the channel exists to lift, on the `[is]` bracket. The trigger's evidence bar is right at
the edge of real critic quoting practice.

**Non-filings in the other four ND2 cells (confirmed by content search):**

- nd2-opus-r1: tech-debt item 5 reaches the code and *accepts* it — "Note this interacts with the
  deliberate design choice documented at `sim.ts:623-627` (a FLEE-interrupted song still earns the
  CONTENT mood); **that choice is fine**". Paraphrase, no inversion claim → correctly no-lift.
  This is the H4 doc-deference path surviving, not a wording near-miss: the critic genuinely did
  not contest the design.
- nd2-fable-r1 / r2: fact-check Claim 25 records the SINGING→FLEE-sets-CONTENT fact in both runs
  but explicitly punts ("code-quality/design judgments … critic stages own those"), and no critic
  report files it.
- nd2-sonnet-r1: no mention of the defect in any critic report.

**Channel recall: 1/1 over cells that filed the defect.** 1/5 over all ND2 cells is a
finding-*generation* gap (§1.1 / k≥3 territory), not a channel gap — the channel is a promotion
mechanism and cannot lift what no critic wrote.

## 2. Negative controls (must not lift)

**md1 `proxy.ts:14` style-src carve-out — HOLDS, 0 lifts, non-vacuously.** Seven findings across
the three md1 cells touch the carve-out comment; every one fails ≥1 condition. The strongest
stress: md1-opus security F8 quotes the carve-out comment verbatim with `proxy.ts:12-14` **and**
the directive verbatim at `proxy.ts:23` — both quotes present — and is stopped by **condition 3
alone** ("the carve-out is defensible… this is not a request to change it" = cost-framing/wisdom
disagreement; precision guard applies). This is the guard doing exactly its designed work.

**ND3 fixed `sim.ts:625-628` docstring — HOLDS, 0 lifts, but vacuously.** The fixed docstring
exists in the ND3 repos (sim.ts:613-629: "CONTENT is gated on the song ending CALMLY
(`to !== "FLEE"`): a song the player SPOOKED into FLEE must NOT make the creature more
approachable"), but the ND3 diff under review is the serialization/session commit (319f229) and
**zero findings in any of the 16 run-written ND3 critic reports touch sim.ts:613-641, onEnterState,
or the mood system at all** (grep-verified). The named control is trivially satisfied — it has no
probing power in this corpus and does not test whether the trigger declines a coherent-rationale
docstring. The md1 control (and ND2's opus-r1 doc-deference no-lift) carry that burden instead.

## 3. Negative sweep — full corpus

### md1 group (89 findings)

6 mechanical fires — **all six the same underlying defect** (the nonce mis-wiring: fable security
F1, fable arch F1, fable api F1, fable perf F1, opus security F1, opus perf F1), each with
verbatim layout-comment intent quotes (`app/layout.tsx:27-31`), verbatim mechanism quotes
(`proxy.ts:41-48`), and stated defeat ("ships a policy that either breaks the app or provides none
of the claimed protection"). All are already filed 🔴 R1 or 🟡 A1/A3 via the existing
fact-check-`Incorrect` / api-`Breaking` channels. **False lifts from 🟢: 0.** Notable no-lifts:

- The x-nonce dead-contract family (4 findings, 3 cells) quotes intent verbatim with file:line and
  reconstructs the zero-reader mechanism, failing only C3 — and only under a strict "behavioral
  inversion" reading of "defeats". A loose reading lifts all four (three falsely).
- The known sonnet miss (`connect-src` "sound with no unintended carve-outs") produces nothing for
  the channel to act on — a What-Looks-Good line with no quotes and no inversion; correctly silent.
- Quoting habits split identical defects: the same nonce finding lifts where the report quotes the
  comment (fable api F1) and fails C1 where it paraphrases (opus api F1, sonnet security F1).

### nd2 group (≈144 findings)

6 mechanical lifts: the intended positive (above); **4 true-class band no-ops** on the
EATING_INTERRUPT/SECRET-tier rarity inversion (opus-r2 tech-debt #3, opus-r2 arch #8, fable-r1
arch #1, fable-r1 tech-debt D5 — all with verbatim `behavior.ts:107-114` docstring quotes,
located mechanism reconstructions, and "the rarity ladder … inverts" claims; all already 🟡 A1 via
fact-check+architecture convergence, so the lift changes the severity label, not the band); and
**1 judged FALSE lift**: opus-r2 security #2 (NaN photo score — quotes the "clamp defensively
against float drift" comment inside its `observation.ts:288-295` evidence block, mechanism at
`catalog.ts:114-117`, states "the clamp does not clamp … defeats the catalog's dedup invariant";
filed 🟢 C3). A Low-severity, reachability-hypothetical robustness bug whose wrong comment is
fact-check-`Incorrect` territory, not correctly-reasoned soundness — 🟢→🟡 would over-band it.

Precision-guard saves worth naming: opus-r1 security's seed-aliasing "undermines 'same seed →
same run'" fails C1 (no file:line on the intent phrase); the singingTimer findings quote
*angryTimer's* doc — the quoted intent holds, the defeated thing is an unstated symmetry
expectation, C3 fails relative to the quoted intent; opus-r2 perf #3 (WARY makes FLEE absorbing)
has both quotes but frames the issue as emergent tuning, no inversion claim. Borderline: fable-r1
api #6 (WARY "scaled down" contradicts its doc) lifts only under a loose C3 reading — band no-op
(already 🔴 R2 via fact-check `Incorrect`), but it is the sharpest datum that C3 must mean
*behavioral defeat of intent*, not *any doc-vs-code contradiction*.

### nd3 group (82 findings)

**7 mechanical lifts on a diff that should produce none** (4 distinct underlying issues):

| Lift | Class | Judgment |
|---|---|---|
| fable tech-debt #3 — serialized `category` field "contradicting the format's own no-redundancy principle" (quotes persistence.ts:57-59 intent, :86/:105-107 mechanism) | convention/hygiene | **FALSE** — nothing behaviorally inverted |
| opus arch #2 + opus api F5 — session.ts serializes itself, "contradicting the rule persistence.ts states in its own header" (persistence.ts:6-9 vs session.ts:150-151) | convention | **FALSE ×2** — the quoted intent (catalog stays persistence-free) is not actually defeated |
| opus arch #4 + opus tdt #2 — score weight vs "without letting it dwarf shot quality" (session.ts:92) | doc factually false | **out-of-class ×2** — fact-check Claim 14 `Incorrect` territory; lift redundant, band coincidentally defensible |
| opus arch #7 + opus tdt #3 — documented migration path "not reachable through the gate the code actually installs" (persistence.ts:16-21 vs :118-121) | genuine intent-vs-mechanism, latent | **debatable ×2** — real contradiction but fires only at v2; critic severity Minor; 🟡 over-bands it |

Near-misses on C1 (calibration data, opposite direction): fable security F1 and sonnet security F1
both quote a docstring verbatim and state defeat ("the exact failure mode the module's docstring
says it's designed to prevent") but attach file:line only to the *mechanism* quotes — one added
line ref would make each lift (both are core-critic Medium findings that reach 🟡 natively, so
band no-ops). And a guard success that doubles as a fragility datum: sonnet arch declines to
assert contradiction on the *same migration facts* that lift in the opus cell ("That's correct and
appropriately minimal … Not a defect") — the channel keys on the report's own assertion, so the
same defect lifts or not depending on critic phrasing.

## 4. Tallies

| Measure | Value |
|---|---|
| Corpus | 315 findings, 11 cells, ~27 run-written critic reports |
| **Recall on the known soundness defect** | **1/1** cells that filed it lift (nd2-opus-r2 C1, 🟢→🟡, the human panel's band). 4/5 ND2 cells never filed it — generation gap, out of channel scope |
| Mechanical fires, total | 19 findings (md1 6 · nd2 6 · nd3 7) |
| — intended true positive, band-changing | 1 (the ND2 C1 lift) |
| — true-class, band no-op (already 🟡) | 4 (nd2 EATING/SECRET-tier cluster) |
| — redundant with existing channels (already 🔴/🟡) | 8 (md1 nonce ×6; nd3 score-weight ×2) |
| **— false lifts (clear)** | **4** (nd2 opus-r2 security #2; nd3 fable tdt #3, opus arch #2, opus api F5) — **rate 4/315 ≈ 1.3%** |
| — debatable lifts | 2 (nd3 migration-gate pair — genuine contradiction, latent, over-banded) |
| False + debatable rate | 6/315 ≈ 1.9% (distinct underlying issues: 3) |
| Named negative controls | md1 `proxy.ts:14`: 0 lifts (7 probes, guard held on the strongest) · ND3 `sim.ts:625-628`: 0 lifts, **vacuous** (no report text in scope) |
| Precision-guard saves | ≥8 defeat-vocabulary candidates correctly blocked (missing located intent quote, wrong intent's quote, no inversion claim, explicit disavowal) |

## 5. Headline verdict

**Pass-with-recalibration-needed.**

- The falsifier as written **passes 3/3**: the ND2 replay lifts C1 to 🟡 `Contested-Soundness`,
  and neither named negative control lifts anything. Neither of decision 028's tighten-or-revert
  conditions fired. The counter-evidence branch "critics never quote both sides verbatim" did not
  materialize — the load-bearing critic did quote both sides, with file:lines.
- But the full-corpus sweep the falsifier did not require shows the trigger's precision problem:
  **condition 3's "defeats or inverts" cannot distinguish a behavioral soundness inversion from a
  convention/structure contradiction** ("code contradicts the module header's stated principle" —
  the dominant ND3 false-lift shape), and it also fires redundantly on
  fact-check-`Incorrect`-class findings (inaccurately-documented broken code — all 6 md1 fires,
  the nd3 score-weight pair) that the existing verdict channels already promote. 4 clear false
  lifts (3 distinct issues) in one replay session is already adjacent to the decision's own "≥3
  Contested-Soundness rows adjudicated wrong → precision guard too loose; re-run step 4" revisit
  trigger — those would very likely be author-dismissed rows.
- And the ND3 named control is **vacuous** in this corpus — negative-control assurance actually
  rests on md1's `proxy.ts:14` (which held non-vacuously) and ND2 opus-r1's doc-deference no-lift.

## 6. What this changes

1. **The 🟡 cap stands, doubly.** The cap-raise precondition (validation pass **and** a ≥10
   correct-lift corpus) is not close to met, and the precision data says the cap is currently
   load-bearing: at ~1.3% clear-false-lift rate the bounded cost argument (a 🟡 dismissal costs
   the author one sentence) is what makes the channel acceptable at all.
2. **Recalibration to make before trusting lifts in anger** (skill-text edits, no new mechanism):
   - **C3 wording**: require the report to assert a *behavioral* defeat/inversion — the mechanism
     produces runtime behavior contrary to the stated intent — explicitly excluding
     convention/structure/hygiene contradictions ("breaks the header's stated principle") and
     doc-falseness findings (fact-check-`Incorrect` territory). This single edit removes all 4
     clear false lifts and both out-of-class pairs while keeping the ND2 positive and the
     EATING/SECRET-tier cluster.
   - **Already-promoted no-op clause**: "place in (or move to) 🟡" must not *demote* — a
     qualifying finding already at 🔴 keeps its band (8 of 19 fires in this corpus are
     already-🔴/🟡 rows; read literally the channel would move 🔴 R1 rows down).
   - **"Verbatim" definition**: state that standard bracketed alterations and elisions count —
     the byte-exact reading fails the channel's own raison d'être on an `[is]` bracket.
3. **Do not loosen C1's file:line bar** — it blocked real would-be false lifts (nd2 seed-aliasing)
   and its near-miss cost in this corpus was zero band-changes (both nd3 near-misses reach 🟡
   natively). The existing revisit trigger ("consider requiring critics to emit the quote pair
   explicitly") is the right lever if generation-side quoting proves unreliable, not a looser bar.
4. **A future falsifier needs a live negative control**: ND3's named control tests nothing here;
   md1 `proxy.ts:14` is the control with actual probing power and should be named as such.
5. Recall over cells (1/5 filed the defect) re-confirms §1.1: the channel fixes promotion, not
   generation. Cross-family/k≥3 work remains the path to making more cells *file* the finding.
