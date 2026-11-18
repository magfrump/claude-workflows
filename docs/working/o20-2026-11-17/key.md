# Answer key: MAIS-O20 reader tasks (pilot, 2026-11-17)

**Never shown to readers.** Written from `docs/working/mais-solutions/O20.md` (the source of truth), not from the
draft post, so the key isn't shaped by the draft's framing. "Location in post" says where the post gives the
answer, and is filled in during grading.

A reader **passes** a task when their answer contains every element marked ●, contradicts none of them, and
gets the status right. Elements marked ○ are credit, not required.

## Conjecturer

**C1.** (O20.md §2 items 1–6, §3 D1–D3.)
- (a) ● $f+\lambda+A\le^*_S g$ for every standard $A$ suffices, with $\hat k=\max(k_1,K(C_S+2N))$. ● Status:
  Lean, over a structure whose fields are A1's cost facts; that $\mathsf{PA}_{\mathrm{bin}}$ satisfies them is
  unchecked; it uses quantifier distribution at a threshold. ○ It is sharp up to $c_S$ for Payor-only
  derivations (countermodel). ○ In $S$, "g internally regular" is an alternative sufficient condition (Löb route).
- (b) ● Yes, the pair suffices. ● $b\lambda\le^* g$ is redundant: it follows from $f+b\lambda\le^* g$ when $f\ge0$.
- (c) ● Not by the permitted rules alone (countermodel). ● But the literal PB_k does cooperate in $S$ by the Löb
  route, under A1's standing hypothesis that id is internally regular (FairBot's own hypothesis), with a
  threshold no better than FairBot's (certified bounds). ● The repaired $\mathrm{PB}^A_k$ cooperates above
  $\max(k_0,2A,2C_S+4N_P)$ by a Payor-only proof.
- (d) ● No numerical comparison is possible today (O12, O16). ○ The structural comparison: the Payor driver is
  about $2N_P$ and the Löb driver about $(1+e)2N_L+2d_S$. ○ $(1+e)\hat k_P\le\hat k_L$ holds only under an
  unverified fixed-point hypothesis.

**C2.** ● Unknown numerically. ● For the literal PB_k, no: it gets no Payor savings. ○ For $\mathrm{PB}^A_k$, the
certified bound avoids $d_S$ and $\mathcal E_S$, but there are no lower bounds, so this is not a claim that it is
faster.

**C3.** ● Weakened: the certificate family becomes $f+\lambda+A$ for all $A$, in place of $b\lambda$ for all $b$,
and $b\lambda\le^* g$ is redundant. ● Rejected: the literal PB_k as an instance of the lemma (defect D1). ● Added:
threshold-form quantifier distribution (D2), `le_cert` (O13) in the `CritchBHP` versions, and that
$\mathsf{PA}_{\mathrm{bin}}$ satisfying the fields is unchecked. ○ "Only the permitted rules" is made precise as
those rules used at a fixed parameter.

**C4.** ● Yes. ● On A1's standing hypothesis that id is internally regular. ● On `le_cert` (O13). ○ On program
inspection, which is a modelling assumption.

**C5.** ● Necessity in $S$ at logarithmic budgets: is there a $p$, with $g-f=o(\lambda)$, such that $S$ proves
the premise but no tail of $p$? The Payor analogue of MAIS-O14. ○ Others: a cross-parameter diagonal-free
argument; unexploitability; the symbol-measure constants; the numerical comparison.

## Maintainer

**M1.** ● Good faith: yes. ● Followable: the claims are, though notation is introduced before it is defined
(graded on what the reader reports). ● Bears on the problem as stated: yes, every part is addressed. ○ Likely
"needs revision" triggers: the defect claim's phrasing, or claims not checkable from the attachment.

**M2.** Claims and statuses (O20.md §5):
- ● Theorem 1, `BHP.payor`: Lean. ● The literal-QD variant, `BHP₀.payor_literal`: Lean, with the finite check as
  a hypothesis. The finite check is Lean, not attached, in the Gödel-code measure, and hand in the symbol
  measure. Its cost estimate is a hand estimate.
- ● The arithmetic instance: Lean, not attached.
- ● Theorem 2, the family and the pair, and the redundancy: Lean (`CertBHP`, `CritchBHP`).
- ● Theorem 3, the countermodel: Lean.
- ● §3, literal rule fails, fixed point, inner necessitation, no fixed point, Löb fails: Lean.
- ● `lob_premise`, `payor_via_lob`: Lean. ● The literal agent via Löb in the symbol measure: Lean over
  `CritchBHLG`, assuming `le_cert`. ● `fairbot_certified_le_literal`: Lean, certified bounds, with three
  stated assumptions.
- ● Theorem 4, $\mathrm{PB}^A_k$: Lean. ● Program inspection: modelling assumption. ● From provability to play:
  Lean, not attached. ● Choosing $A$: Lean, with $T_0\le a\log_2 A+d$ as a hypothesis.
- ● The §5 Löb driver: Lean, under an unverified fixed-point hypothesis whose only witness is GL.
- ● $p=\bot$ premise not provable: hand in the symbol measure; Lean, not attached, in the Gödel-code measure.
- ○ The label "[modelling assumption]" is not in the post's declared label set.

**M3.** ● $\mathsf{PA}_{\mathrm{bin}}$ satisfies the structure's fields (A1's cost facts and elementary
arithmetic): unchecked. ● Threshold-form quantifier distribution, which is not A1's form: a field. ● For the
`CritchBHP` versions: `le_cert`, which is O13. ○ The budgets are represented. ● Location: stated in four places
(opening, Setting, §1 subtlety, Theorem 2's paragraph).

**M4.** ● Checkable from the zip: everything in the seven-file extract, namely `BHP.payor`,
`BHP₀.payor_literal`, `CertBHP.*`, `CritchBHP.*`, `cmodel`/`cm_*`, `BHPcore.lob_premise`, `BHLG.pblt`,
`BHLG.payor_via_lob`, `CritchBHLG.*` (including `lob_linear_driver` and `fairbot_certified_le_literal`). ● Not
checkable: the arithmetic instance, the finite check, the Gödel-II reduction, `PayorPlay`, the GL models. ● How:
`lake exe cache get && lake build`, then `lake env lean Axioms.lean`. ○ That the extract matches the library
(pp.all) cannot be checked from the zip: `fidelity_check.sh` is not in it.

**M5.** ● Theorems 1–2 are schematic in $p$, as asked, but over an abstract structure, not $\mathsf{PA}_{\mathrm{bin}}$.
● Quantifier distribution is used in threshold form, not A1's (deviation D2; Theorem 1′ covers the verbatim form
with a finite check). ● "Prove that two copies of PB_k cooperate" using only the permitted rules: shown
impossible for schematic derivations; the positive answer uses the Löb route, outside the constraint. ● "Compare
… in a common system and encoding": not done. ○ Necessity holds for derivations at a fixed parameter, a
narrower scope than $S$.

**M6.** ● Proved (Lean, abstract): Theorem 1; Theorem 2 (family, pair, redundancy); the countermodel's necessity
for Payor-only; the literal PB_k out of reach; Payor premise ⇒ Löb premise; $\mathrm{PB}^A_k$ cooperates.
● Conditional: literal PB_k via Löb (`le_cert`, internal regularity); the Löb driver comparison (fixed-point
hypothesis). ● Numerical: none (toy only). ● Open: necessity in $S$ at logarithmic budgets; cross-parameter
arguments; unexploitability; symbol-measure constants; the numerical comparison.

## Enthusiast

**E1.** ● Setting: programs that read each other's source code play a Prisoner's Dilemma, and each cooperates if
it finds a proof, of bounded length, of a certain statement. ● Payor's lemma gives a cooperation argument without
self-reference machinery; its bounded version works when the inner budget is smaller than the outer by about
$\log k$ plus a constant. ● The agent as posed has equal budgets and does not get that shortcut; it still
cooperates (under FairBot's own assumption) by the older Löb route, no faster than FairBot. ○ The repaired agent
gets the shortcut. ○ Whether it is numerically faster is unknown. **Fail** if the answer says or implies that
PB_k does not cooperate.

**E2.** ● Yes, conditionally: under A1's standing hypothesis (id internally regular), `le_cert`, and program
inspection, by the Löb route. ● Not by a Payor-only argument. ○ Unconditionally, unknown.

**E3.** ● To box an instance $\varphi(\bar k)$, a proof has to write the numeral $\bar k$, which takes about
$\log_2 k$ symbols; so quantifier distribution's box budget carries a $\log_2 k$ term ($C_S+2N+\log_2 k$), and
the outer budget has to cover the inner one plus that term. ○ In the countermodel, even valid formulas cost
$C_S+\log_2 k$.

**E4.** Any one of: ● $\Box_a\varphi$, "φ has a proof of at most $a$ symbols"; $f$ the inner budget; $g$ the
outer budget; $\mathrm{comb}$ the budget after implication distribution; $\mathrm{qd}$ quantifier distribution's
box budget; $\hat k$ the threshold. ● With why it is there.

**E5.** ● Whether finite agents that can read each other's code can cooperate robustly, and what being finite
costs: here, a margin of about $\log k$ between how hard an agent looks and what it looks for. ○ Graded mainly on
whether the post supplies the connection.

**E6.** Open-ended. Plausible: "Does PB_k cooperate?", "Which parts are checked for $\mathsf{PA}_{\mathrm{bin}}$
itself?", "Is the Payor threshold actually smaller?". Graded on whether the post answers the question the reader
names.

## Builder

**B1.** ● Any one of O20.md §8, stated with its quantifiers. Best: necessity in $S$ at logarithmic budgets.

**B2.** ● For example, `BHP.payor`, with hypotheses: a premise proof of length $n_0$ beyond $k_0$;
$\mathrm{comb}(\mathrm{qd}T_0,f)\le g$ proved beyond $k_1\ge k_0$; $\mathrm{qd}(N)\le g$ proved beyond
$\hat k\ge k_1$. Or `cm_payor_threshold`, `BHPcore.lob_premise`, `CritchBHP.pbA_cooperates` (premise, $A\ge
C_S+2T_0+c_S$, both budgets represented, `le_cert` certificates). ● Whether the post's statement matches the Lean
is graded against the Lean file.

**B3.** ● `lake exe cache get && lake build` (about 35 s after the Mathlib cache), then
`lake env lean Axioms.lean`: 41 lines, standard axioms only. ● `python3 scripts/thresholds.py` reproduces
`scripts/thresholds.log`.

**B4.** The post says the zip holds `lean/` (pinned to Lean and Mathlib v4.33.1, Mathlib-only), seven Lean files
of 1,919 lines, `Axioms.lean` with 41 `#print axioms`, `scripts/thresholds.py` and its log, and a README. ● The
zip has `Extract/` with seven files (AbstractG, LenSys, Payor, PayorCompare, PayorCost, PayorLob, PayorSymbol),
`Axioms.lean`, the scripts, README, PROVENANCE.txt. ● "Every cited declaration prints identically under pp.all"
cannot be checked from the zip. ○ Whether the file names match the post's "seven files" and its module list
(the post lists `Length`, not `LenSys`, in the draft's notes only).
