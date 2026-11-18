# Session: conjecturer (simulated, pilot)

**Run:** 2026-11-17, general-purpose subagent, pilot brief (protocol v0). **First take not blind:** the agent's first file read loaded the whole post (protocol fix 1 in `protocol.md`).

# Reader test: MAIS-O20 post, read as the conjecturer

## First take
(This covers only the title, the bold subtitle line and the three paragraphs "This answers…", "What the lemma half assumes…" and "On the agent half…". One disclosure: my tool call loaded the rest of the post before I wrote this paragraph. I wrote it from the opening alone, but it was not a blind read.)

The post says it solves the lemma half of O20. The problem's certificates are enough, and they ask for more than is needed. A gap g − f of about log k plus a constant tied to the premise's proof length is enough, and for Payor-only derivations a gap of order log k cannot be dropped. The lemma is proved over some axiomatised structure of A1's cost facts, not in PA_bin itself. It also assumes quantifier distribution "at every threshold", which A1 does not state. If you use A1's own form, you need a finite check and k̂ gets much bigger. On the agent half, the post says the problem is misstated. The literal PB_k has f = g, and the three permitted rules cannot prove that it cooperates. So the post proves cooperation for a repaired agent PB^A_k, and leaves the comparison with k̂* open. The title adds one thing: the literal PB_k cooperates only by going through the Löb route.

## Tasks (C1-C5)

### C1. Each part of the problem, with status

**(a) Conditions on f, g with an explicit k̂.** The condition is: for every standard A, eventually f(k) + log₂k + A ≤ g(k). In the symbol measure this is the family f + λ + A ≤*_S g for every standard A. The threshold is k̂ = max(k₁, K(C_S+2N)). Here N is the length of line 4 of the Payor derivation, and K(A) is the threshold of the certificate at A.
- Status: Lean-checked over the structures `CertBHP` (certificates used as proofs, no `le_cert`) and `CritchBHP` (assumes `le_cert`, which for Bud-terms is O13). That PA_bin satisfies these structures' fields is not checked.
- Both versions assume quantifier distribution at every threshold, which goes beyond A1. With A1's form verbatim, a finite check is needed (`BHP₀.payor_literal`). In the symbol measure that check is a hand proof and may cost something exponential in f(K).
- Quotes:
  - §1, Thm 2: "If for every standard $A$, eventually $f(k)+\log_2 k+A\le g(k)$, then every premise at $(f,g)$ gives $\forall k>\hat k\ p$ for some $\hat k$."
  - §1: "the family **$f+\lambda+A\le_S^{\ast} g$ for every standard $A$** suffices" and "The threshold is explicit: $\hat k=\max(k_1,K(C_S+2N))$".
  - Opening: "a gap of $\log k$ plus a constant that depends on the premise's proof length is enough".
  - Sharpness, §2: "the gap $\log_2 k+A$ of Theorem 2 is optimal up to the constant $c_S$", in a model of `CritchBHP` and only for Payor-only, fixed-parameter derivations ("Scope").
- From the opening alone: **partly**. The gap's shape is there, but not the threshold, not what the gap is between, and not the scope of "cannot be removed".

**(b) Whether bλ ≤* g and f + bλ ≤* g suffice.** Yes, they suffice, and they are more than needed. The first certificate is redundant when f ≥ 0. Lean: `CertBHP.payor_problem_certificates`, `family_of_two_lam`, `smul_le_of_add`.
- Quotes:
  - Opening: "The certificates suffice, and the problem's pair is stronger than necessary".
  - §1: "The problem's pair implies it [Lean: `CertBHP.family_of_two_lam`]. The first member of the pair, $b\lambda\le_S^{\ast} g$, is redundant, because it follows from the second … when $f\ge0$".
- From the opening alone: **yes** for "suffice", **no** for the redundancy.

**(c) Two copies of PB_k above an explicit threshold k̂*_P.**
- For the **literal PB_k**: not by the permitted rules. Against Payor-only derivations, schematic in p and at a fixed parameter, this is a Lean-checked negative result in the countermodel.
- The literal PB_k does cooperate by the Löb route. That needs A1's standing hypothesis that id is internally regular, plus `le_cert`. Its threshold is "the Löb route's at budget k − λ − A" (`lobThr`), and the post gives no closed form for it.
- For the **repaired PB^A_k** (inner budget k − log₂k − A, outer budget k): k̂*_P = max(k₀, 2A, 2C_S + 4N_P), when A ≥ C_S + 2T₀ + c_S. Lean: `CritchBHP.pbA_cooperates`, which uses `le_cert` and program inspection as assumptions.
- Quotes:
  - §3: "So no derivation from the permitted rules, schematic in $p$, proves that two copies of $\mathrm{PB}_k$ cooperate."
  - §3: "The literal agent does cooperate in $S$, but only through the Löb route".
  - §4, Thm 4: "$\hat k^{\ast}_{\mathrm P}=\max(k_0,\ 2A,\ 2C_S+4N_P)$ … The proof uses no diagonal sentence and no inner necessitation."
- From the opening alone: **partly**. The defect and the repair are named. The threshold is not given, and the conditional Löb-route result for the literal agent is only hinted at in the title.

**(d) Comparison with k̂*.** Open.
- The post compares only *certified upper bounds*, never least thresholds:
  - The literal PB_k's certified bound is at least FairBot's (`fairbot_certified_le_literal`, under length assumptions).
  - (1+e)·k̂*_P ≤ k̂_L. This rests on a fixed-point hypothesis whose only witness is GL, where every length is 0.
- Quotes:
  - §5: "**This is not a claim that the Payor route is faster.**"
  - §5: "**A numerical comparison with $\hat k^{\ast}$ cannot be made today.** $\hat k^{\ast}$ is not known to be finite (MAIS-O16), and $\mathcal E_S$ and $d_S$ for $\mathsf{PA}_{\mathrm{bin}}$ are open (MAIS-O12)."
  - Opening: "The numerical comparison with $\hat{k}^{\ast}$ stays open."
- From the opening alone: **yes** for "open". **No** for the partial certified-bound results.

### C2. Does the cheaper route give a smaller cooperation threshold?
Unknown. The literal PB_k cannot use the cheaper route at all, and its certified threshold is no better than FairBot's. The repaired PB^A_k's certified bound beats the Löb route's certified bound by a factor of 1+e, but only under an unverified hypothesis, and the post says this is not a claim that the Payor route is faster.
- Relied on:
  - §3: "so the literal $\mathrm{PB}_k$ gains nothing over $\mathrm{FairBot}_k$ by this route".
  - §5: "Under it, … $(1+e)\,\hat k^{\ast}_{\mathrm P}\le\hat k_L$. **This is not a claim that the Payor route is faster.** It compares the upper bounds these two proofs certify, under a hypothesis with no non-trivial witness, and neither threshold has a known lower bound."
- Note: the post never answers this question in one sentence in its own words. I had to put it together from §3 and §5.

### C3. Hypotheses or certificates weakened, strengthened, rejected; additions
- **Weakened (certificates):**
  - The certificate pair is replaced by the family f + λ + A ≤* g (equivalently f + log₂k + A), and only two values of A are actually used.
  - bλ ≤* g is shown to be redundant.
  - The premise may hold only beyond k₀ instead of for all k (Thm 1: "∀k>k₀"). This last generalisation is never flagged as one.
- **Strengthened (assumptions beyond the problem or A1):**
  - Quantifier distribution at every threshold ("which A1 does not state").
  - `le_cert` in the `CritchBHP` statements, which is O13 for Bud-terms.
  - The derivation uses the propositional calculus, "threshold shift" and monotonicity alongside the three permitted rules (Setting). Monotonicity is in A1. Threshold shift is never explained.
- **Rejected:** the agent part of the problem as posed. The literal PB_k is "a defect in the statement" (§3, with the suggested repair).
- **Added:**
  - Sharpness for Payor-only derivations (Thm 3, a two-world countermodel).
  - The repaired agent PB^A_k with its threshold (Thm 4).
  - A reduction from the Payor premise to a Löb premise (`lob_premise`, `payor_via_lob`).
  - An arithmetic instance in the Gödel-code measure that shows soundness but gives no thresholds.
  - The comparison table the problem asked for (§5).
  - New open problems (see C5).

### C4. Is the literal PB_k's cooperation conditional? On what?
Yes, on all of the following:
1. A1's standing hypothesis that id is internally regular ("the same hypothesis as A1's FairBot theorem").
2. `le_cert`, since `CritchBHLG` assumes it, which is O13 for Bud-terms.
3. Critch's bounded Löb theorem's hypotheses: "the diagonal sentence and an inner-necessitation instance".
4. The program-inspection modelling assumption.
5. PA_bin satisfying the structure's fields, which is not checked (Setting).

Quotes:
- §3: "Under A1's standing hypothesis that $f(k)=k$ is internally regular, the same hypothesis as A1's FairBot theorem, `thm:pbl` applies."
- §3: "[… over `CritchBHLG`, which assumes `le_cert`]".

From the opening alone: **no**. The opening says only that the Payor rules cannot prove it. The title's "needs the Löb route" hints that it is conditional but names no condition.

### C5. Follow-up left, and whether it can be posed
The main one is "Necessity in S itself": "Is there a $p$, and budgets at the $\lambda$ scale with $g-f=o(\lambda)$, such that $\mathsf{PA}_{\mathrm{bin}}$ proves the Payor premise but no tail of $p$?" The post frames it as the Payor counterpart of O14 and rules out p = ⊥.
- It is close to posable. Two things are loose:
  - "budgets at the λ scale" is not defined: Bud-terms? Θ(λ)?
  - "o(λ)" could mean the true inequality or a certified one.
- The other follow-ups:
  - Diagonal-free arguments across parameters. Not posable as stated ("We know of none").
  - Unexploitability for both agents. Posable: does PB^A_k defect against a provable defector, that is, is there a short proof of ¬□_f c?
  - The cost of threshold-form quantifier distribution and of the finite check in PA_bin.
  - The numerical comparison, blocked on O12/O16.
  - Payor's bounded agent A_k from the comments, whose claim is unsettled (final paragraph).

## Stuck log
1. **Opening, para 1:** "a gap of $\log k$ plus a constant". Stopped on: a gap between what? Probably g − f, but the text does not say. *Resolved* by Thm 2 in §1.
2. **Opening, para 1:** "a constant that depends on the premise's proof length" versus Thm 2's hypothesis "for every standard $A$". I reread both. Does the hypothesis need one A per premise, or all A? *Partly resolved*: Thm 2 quantifies over all premises, so it needs all A, while any one premise uses the two A's listed. Nothing ever reconciles the opening's wording with Thm 2.
3. **Opening, para 1:** "a gap of order $\log k$ cannot be removed". Stopped on: in S, or in some model? *Resolved* in §2 (Thm 3 plus "Scope"): Payor-only derivations at a fixed parameter, in a model of `CritchBHP`. The opening's "For derivations from the permitted rules" hints at this, but the fixed-parameter limit only appears in §2.
4. **Opening, para 2:** "a structure whose fields are A1's cost facts", `CertBHP.payor_family`, `CritchBHP`, `le_cert`. Undefined Lean names in the opening. *Partly resolved* in Setting: `BHP` and `CritchBHP` are defined there, and `le_cert` is glossed. **`CertBHP` is never defined.** Setting only lists it in brackets. I inferred from the Checking-it table ("with certificates as proofs") that it uses the problem's certificates as S-proofs and has no `le_cert`.
5. **Opening, para 2:** "quantifier distribution at every threshold". Stopped on: what does "at every threshold" mean? *Resolved* in §1 "A subtlety…": A1 states it only for ∀k with no threshold.
6. **Opening, para 3:** "no argument from bounded necessitation, quantifier distribution and implication distribution alone proves that it cooperates". The claim reads as unconditional. *Resolved, but narrowed*: §2 "Scope" and §3 ("schematic in $p$") limit it to fixed-parameter use, and Open ("Diagonal-free arguments across parameters") admits that a cross-parameter argument is not excluded. The opening overstates what is proved.
7. **Opening, para 3:** "a repaired agent $\mathrm{PB}^A_k$". Undefined until §4. *Resolved* there.
8. **Setting:** "$U(n,t,\Phi)$ means…". Defined and then never used in anything I read. I stopped to look for where it is used.
9. **Setting:** "threshold shift". Listed as a rule of `BHP` but never explained. *Not resolved.* It matters, because the problem restricts the permitted rules.
10. **Setting:** "Implication distribution turns budgets $a,b$ into $\mathrm{comb}(a,b)$ … box budget $\mathrm{qd}(n)$". New notation. Fine, and *resolved* in place by the `CritchBHP` instance (a+b+c_S and C_S+2n+log₂k).
11. **§1:** "`CritchBHLG`", "`BHLG`", "`BHPcore`", "`BHP₀`". These structure names first appear in §1 and §3 and are never defined. I guessed that "LG" adds Löb and diagonal fields. *Not resolved.*
12. **§1, after Thm 2:** "In Lean, the step from a true inequality to a proved one is `le_cert`. In $S$ the problem's certificates are themselves the proofs". I reread this twice. Is Thm 2's "eventually … ≤ g" true or provable in S? *Partly resolved* by the two Lean citations: the `CritchBHP` versions take it as true, the `CertBHP` versions as proved.
13. **§1:** "Theorem 1 … has a proof of explicit length". The length is never given. *Not resolved.* It does not affect k̂.
14. **§3:** "In the model of §2, with $f=g=\beta$". The literal agent has budget k, and β is arbitrary. I stopped briefly to check that it was the same model. Resolved on reflection.
15. **§3:** "take $f'=k-\lambda-A$". Here λ appears where §4 uses log₂k for the analogous budget. *Not resolved:* is "log₂k" in PB^A_k a Bud-term? A1 names λ_{a/b} as the canonical logarithmic budget, and the post only says representability is "a hypothesis there".
16. **§4:** in "a proof of $\Box_{k-\log_2 k-A}\ c\to c$", c is not re-defined for PB^A_k. I assumed "PB^A_k(Opp)=C and Opp(PB^A_k)=C" by analogy.
17. **§4, Thm 4:** "$A\ge C_S+2T_0+c_S$". T₀ depends on the agent's code and so on A, which looks circular. *Resolved* by the "Choosing $A$" bullet: T₀ = O(δ + log A).
18. **§4, Thm 4:** "$N_P$ is the length of line 4 of Theorem 1". Which instance? I assumed p = c, f = k − log₂k − A, g = k. Never stated.
19. **§5 table:** "$\approx(1+e)(2N_L+C_S)+2d_S$". N_L and e are undefined at the table. *Resolved* below it: e on the next line, N_L in the second bullet.
20. **§5:** "once logarithms are absorbed each threshold is twice its driver, where that term attains the maximum". Reread three times. *Not resolved*: which "term", and maximum over what?
21. **§5:** "$\hat k_L$". This is the certified Löb bound, not k̂*. I stopped to check that the post was not answering (d) with a different quantity. *Resolved* by the next bullet, which says the comparison with k̂* cannot be made.

## Reading path
- **Read in full:** the title, subtitle and opening; Setting (because the opening used Lean names I could not parse); the statements of Thms 1, 2 and 3 and the text after Thm 2; "A subtlety about quantifier distribution" (the opening sent me there); §2's "Scope"; all of §3 (the defect surprised me, and C4 depends on it); all of §4; the §5 table and bullets (needed for (d)); Open (for C5).
- **Skimmed:** the six-line proof of Thm 1, the Arithmetic instance (it gives no thresholds, so it does not bear on any part of O20), the closing prior-art paragraph, and the Checking-it theorem table (only to work out what `CertBHP` is).
- **Skipped:** Checking-it's build instructions and the axiom audit. As the conjecturer I don't need them to learn the answers. I would delegate them to whoever checks the Lean.
- **Where I could have stopped:** after §4 I had answers to (a)-(c). I read on only because the opening's "stays open" for (d) needed checking against the partial comparison in §5.

## Protocol feedback
- "First three paragraphs" was ambiguous, because a bold subtitle sentence and an attachment line come before "This answers…". The "up to and including 'On the agent half'" note settled it.
- C1-C4 ask whether each answer is available "from the opening alone", but the opening contains only part of each answer. A scale such as "the answer / the status / the conditions" would grade this more finely than yes / partly / no.
- It is unclear whether Lean names that the opening introduces but does not define count as "introduced by the post" for the conjecturer. I treated them as undefined until defined.
- In practice, a single file read can load the whole stimulus before the first take is written. A rule to read by line range first would make the first take blind.