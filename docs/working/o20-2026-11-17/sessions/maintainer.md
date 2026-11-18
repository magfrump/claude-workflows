# Session: maintainer (simulated)

**Run:** 2026-11-17, protocol v1. Read the attachment's statements, not its proofs; did not build. **Raised substantive referee questions** (Bud-terms for PB^A_k's certificates; the Lean quantifier-distribution field against A1's rule; the scope of "optimal up to c_S"). These are recorded in findings.md for checking, and are not yet verified.

# Reader report: MAIS-O20 post, read as the maintainer

Files read: post.md (157 lines), MAIS-O20-problem-page.md, MAIS-A1.tex (§2.2 bookkeeping, conventions, `thm:fairbot`, `thm:pbl`, `conj:comparison`, the PB_k definition and `prob:payor`, lines 119–162, 200–235, 330–345, 474–500), and the attachment folder (README, PROVENANCE, Axioms.lean, lakefile, toolchain, manifest, the seven Extract files read in part, scripts). I did not build anything.

## 1. Blind first take (lines 1–11 only)

The title says this is partial progress. The problem's certificates suffice for a bounded Payor lemma, and the literal PB_k can only be reached through the Löb route. The opening (line 7) claims the lemma half is answered: a gap of log k plus a constant that depends on the premise's proof length is enough, and for derivations from the permitted rules a gap of order log k "cannot be removed". Line 9 lists the assumptions up front:
- The proofs are over an abstract structure, and that PA_bin satisfies it is not checked.
- One version needs `le_cert`, which is the comparison conjecture O13.
- Both versions use quantifier distribution "at every threshold", which A1 does not state. A1's verbatim form needs an extra finite check and gives a much larger k̂.

Line 11 says the statement has a defect: the literal PB_k has f = g, and the three permitted rules alone cannot prove that it cooperates. Cooperation is proved instead for a repaired agent PB^A_k, and the comparison with k̂* stays open. Three things are still undefined at this point: `CertBHP.payor_family`, `CritchBHP` and PB^A_k. `le_cert` is glossed only by its link to O13.

## 2. M1, the screen

What I read for the screen: lines 1–11, the 9 headings, the ~25 lines that carry bracketed labels (grep), and the 30-line problem page. That is roughly a ten-minute screen. I did not read the body prose.

- **Good faith?** Yes. Line 13 declares a label set. Limitations are stated before the results (line 9, "that PA_bin satisfies those fields is not checked"). An "Open" section exists, and some labels deliberately say "Lean, not attached".
- **Followable?** Mostly. The claims in lines 7 and 11 are stated in A1's notation and are followable. Line 9, though, cites `CertBHP.payor_family`, `CritchBHP` and `le_cert` before any of them is defined. `CritchBHP` and `le_cert` are defined in §Setting (line 20) and `CertBHP` in line 22, so on first reading the paragraph is half opaque.
- **Bears on the problem as stated?** Yes, on both halves:
  - Lemma half: "test whether the certificates … suffice" gets the answer "yes, and the first member is redundant".
  - Agent half: the problem asks to "prove that two copies of PB_k cooperate". The post answers instead that this cannot be done with the permitted rules, and proves a variant. That is a legitimate answer for a referee to adjudicate, but it is an answer to a variant plus a defect report, not the requested proof.
- **What would make me reply "needs revision" at the screen:** nothing blocking. Two near-misses:
  1. The Lean names in the opening paragraph are undefined there.
  2. The label grep turns up labels outside the declared set ("Lean, not attached", "hand estimate", and later "modelling assumption"). A referee then has to ask whether "Lean, not attached" counts as checked.

## 3. M2, every claim and its status label

Declared set (line 13): "**[Lean]** (theorem named), **[hand]** (hand proof), or **[toy]** (made-up constants)."

**Claims with a label**

| # | Claim (section) | Label |
|---|---|---|
| 1 | Theorem 1, bounded Payor (§1, l.28) | [Lean: `BHP.payor`] |
| 2 | Theorem 2, the certificates suffice (§1, l.39) | [Lean: `CertBHP.payor_family`, `…payor_problem_certificates`; with `le_cert`: `CritchBHP.payor_certificates`, `…payor_lam_family`] |
| 3 | The problem's certificates are themselves proofs in S (l.41) | [Lean: `CertBHP.payor_family`] |
| 4 | The pair implies the family (l.41) | [Lean: `CertBHP.family_of_two_lam`] |
| 5 | "bλ ≤* g is redundant" (l.41) | [Lean: `CertBHP.smul_le_of_add`] |
| 6 | Explicit k̂ = max(k₁, K(C_S+2N)) (l.41) | [Lean: `CertBHP.payor_family`] |
| 7 | `BHP₀.payor_literal` with A1's quantifier distribution verbatim (l.46) | [Lean] |
| 8 | The finite check is provable for standard K, arithmetic instance (l.46) | [Lean, not attached] |
| 9 | Finite check in the symbol measure (l.46) | "remains a hand proof"; the [hand] label is not used as such |
| 10 | Cost of the finite check "can be exponential in f(K)" (l.46) | [hand estimate] (not in the set) |
| 11 | Arithmetic instance: Theorem 1 holds for every Δ₁ T ⊇ IΣ₁ (l.48) | [Lean, not attached] |
| 12 | Theorem 3, the gap is necessary in a model (§2) | [Lean: `cmodel`, `cm_payor_threshold`] |
| 13 | Literal PB_k in the model: rule fails, fixed point, inner nec., no Löb fixed point, Löb rule fails (§3, l.67–69) | [Lean] ×5 |
| 14 | Payor premise ⇒ Löb premise (l.75) | [Lean: `BHPcore.lob_premise`] |
| 15 | Payor via Löb, any f, g (l.76) | [Lean: `BHLG.payor_via_lob`]; arithmetic versions "Lean-checked … but not attached" |
| 16 | Literal PB_k via Löb in the symbol measure, under "id internally regular" (l.77) | [Lean, over `CritchBHLG`, assumes `le_cert`] |
| 17 | "literal PB_k gains nothing over FairBot_k" (l.77) | [Lean: `…fairbot_certified_le_literal`, certified thresholds only, with three side assumptions] |
| 18 | Theorem 4, PB^A_k cooperates above max(k₀, 2A, 2C_S+4N_P) (§4) | [Lean: `CritchBHP.pbA_cooperates`] |
| 19 | Program inspection (l.96) | [modelling assumption] (not in the set) |
| 20 | Choosing A (l.97) | [Lean, with T₀ ≤ a log₂A + d as a hypothesis] |
| 21 | From provability to play (l.98) | [Lean, not attached, arithmetic instance only] |
| 22 | Löb driver k̂_L and (1+e)k̂*_P ≤ k̂_L (§5, l.114) | [Lean, over `CritchBHLG`, under an unverified fixed-point hypothesis]; GL witness "Lean, not attached" |
| 23 | p = ⊥ cannot witness necessity in S, via Gödel II (Open, l.149) | "[hand in the symbol measure; Lean, not attached, in the arithmetic instance's Gödel-code measure …]" (mixed) |

**Claims with no label**

- l.7: "a gap of log k plus a constant that depends on the premise's proof length is enough"; "a gap of order log k cannot be removed". These are summaries of Theorems 1–3, acceptable.
- l.48: "every quantifier-distribution budget exceeds 2^{2^{2^k}}" in the Gödel-code measure. A number with no label.
- l.57: the countermodel's description ("ex falso costs β+C_S+log₂k"). Explanatory, but it carries the argument.
- l.59: "the gap log₂k + A of Theorem 2 is optimal up to the constant c_S". A derived claim with no label.
- l.61 (Scope): "It covers the request as posed: the three rules, each used at a fixed parameter as A1 states them." This is an interpretive claim about the problem statement.
- **l.71: "So no derivation from the permitted rules, schematic in p, proves that two copies of PB_k cooperate. Adding inner necessitation and the agent's fixed-point equation does not help. What is missing is the diagonal lemma."** This is the headline defect claim, and it is unlabelled. It is an inference (the model is a model of the calculus, so it is sound for derivations) from the labelled model lemmas. The soundness step itself has no label, and "what is missing is the diagonal lemma" is not a labelled claim.
- l.79: "the Payorian FairBot … is equivalent to the original FairBot … uses Löb's theorem". Cited to a LessWrong comment, no label.
- l.97: "T₀ = O(δ+log A)". This is the claim that discharges the Lean hypothesis T₀ ≤ a log₂A + d for the real encoding, and it has no label.
- l.98: "Σ₁-completeness and consistency of S turn S ⊢ c(k̄) into actual cooperation". Labelled only for the arithmetic instance. For PA_bin in the symbol measure it carries no label. [from my own knowledge: this step is standard.]
- §5 table: every "≈" driver, and l.111 "once logarithms are absorbed each threshold is twice its driver".
- l.155: "We found no bounded Payor lemma with explicit budgets or threshold in print"; "Its inner budget exceeds its outer one". A literature claim and an inspection claim, both with no label. The second can be checked from the displayed formula.

**Labels that are unclear or outside the declared set**

- "[Lean, not attached]" is used 6+ times and is not in the set. It is unclear whether it counts as checked. I treat it as "asserted Lean, uncheckable here".
- "[hand estimate]" and "[modelling assumption]".
- The mixed bracket at l.149.
- l.113, "**Lean-checked:**", is an unbracketed list label.
- **[toy]** is declared but never attached to a claim. The script is described as a toy in "Checking it" (l.119) without the bracket.

## 4. M3, the assumptions Theorem 2 rests on that are not checked

I could not find all of them in one place. Line 9 gathers the main three, but the rest had to be assembled from §Setting, §1 and the attachment README. One I found only by reading the Lean and A1.

1. **PA_bin satisfies the structure's fields** (`CertBHP`: elementary arithmetic on +, numerals, log₂, λ, and A1's cost shapes as upper bounds).
   - l.9: "that PA_bin satisfies those fields is not checked"
   - l.22: "Nothing is checked in A1's symbol measure for PA_bin itself."
   - README: "`PA_bin` proves them, but that is not checked here."
2. **Quantifier distribution at every threshold**, which is not A1's form.
   - l.9: "Both versions use quantifier distribution at every threshold, which A1 does not state."
   - l.43–45: "`BHP` takes quantifier distribution at every threshold as a field. That is what Theorems 1 and 2 use."
   - The fallback `BHP₀.payor_literal` needs a finite check, which is a hand proof in the symbol measure (l.46). The cost of threshold-form quantifier distribution in PA_bin is "not computed" (Open, l.152).
3. **`le_cert` / comparison conjecture O13**, for the `CritchBHP` form only. Line 20: "**It is an assumption of the Lean statements in `CritchBHP`.**" Theorem 2's displayed statement (l.39, "eventually f(k)+log₂k+A ≤ g(k)", a truth condition) is the `le_cert` form. The internal form without `le_cert` is the next paragraph's ≤*_S family. A reader has to work out for themselves which hypothesis goes with which Lean name.
4. **Represented budgets** (`Rep f`, `Rep g`). This is a hypothesis in the Lean (`hf`, `hg`). The post says so only for Theorem 4 (l.93: "that both budgets are represented is also a hypothesis there"), not for Theorem 2.
5. **The modelling of the three rules as structure fields.** l.17: "the Lean statements are over a structure whose fields are the rules". `BHP` also contains propositional K, S, MP, threshold shift and budget monotonicity (l.19). Monotonicity is A1's "provable monotonicity", so this is fine.
   - Not in the text, found by reading Payor.lean: the quantifier-distribution field takes a proof of the *sentence* □_n(∀k>t Φ) as input (after `nec`), whereas A1 states it meta-level (S ⊢_{≤N} ∀k φ ⇒ S ⊢ ∀k □_{C_S+2N+log k} φ). I would ask whether these are equivalent for the purposes here. The post does not discuss this.
6. **The certificate lengths enter the threshold.** N (the length of line 4) includes the length m₁ of the first comparison proof (Lean `lenN … m₁`). The threshold is therefore "explicit" only relative to that certificate's length, which `le_cert` / `CertBHP` leave unbounded. The post does not say this in words.

## 5. M4, what the attachment can and cannot check

**Post's description versus the folder**

| Post says (§Checking it) | Folder |
|---|---|
| `lean/`, a Lake project pinned to Lean and Mathlib v4.33.1, imports only Mathlib | Matches: `lean-toolchain` v4.33.1; lakefile `mathlib @ "v4.33.1"`; manifest rev 0df444a3… matches the README |
| "seven Lean files (1,919 lines)" | 7 files, `wc` total 1919. Matches |
| `Axioms.lean` prints 41 declarations | 41 `#print axioms` lines. Matches |
| No `sorry`, `native_decide`, `decide`, `axiom` | grep over the Extract files: none found. Matches (by text) |
| Every cited declaration prints identically under `pp.all` in extract and library | Not checkable: the library is not attached. README says 72 names. PROVENANCE gives line ranges in an absent library |
| Build "about 35 s" | README says "under a minute". Minor inconsistency |
| `scripts/thresholds.py` reproduces `thresholds.log` | Both present. The script docstring calls itself "NOT a computation of real PA_bin thresholds" |

Every Lean name the post cites as attached exists in the extract. I checked each name against the declarations in the files (`BHP.payor`, all `CertBHP.*`, `CritchBHP.*`, `CritchBHLG.*`, `cm_*`, `cmodel`, `cmCert(_pair)`, `pbA_mul_le_lobLinThr`, `lobThr`), and every one except `lobThr` also appears in Axioms.lean. The README lists more theorems than the post (`BHP.payor_eventually`, the `BHLGX.*` variants, `minReg_anti`, `lobCertThr_anti`, `literal_certThr_ge_fairbot`).

**Can be checked from the attachment alone** (by building and reading statements against the prose): Theorems 1–4; the certificate reductions (claims 3–6); `BHP₀.payor_literal` with the finite check as a hypothesis; the countermodel lemmas of §2–§3; the Löb-route compositions (l.75–77); choosing A under its hypothesis; the §5 driver under its fixed-point hypothesis; the axiom footprint.

What I spot-read in the Lean:
- `pbA_cooperates` really has inner budget `k - Nat.log2 k - A` and outer `id`, uses `le_cert` twice, and takes the program-inspection premise as `hyp`. This matches l.87–96.
- `cm_payor_threshold`'s statement matches Theorem 3's two bullets.
- `payor_problem_certificates` uses only the b = 2 member of the pair's second certificate, which matches "the pair's f+2λ implies the family".

**Cannot be checked from the attachment:**
- Every "[Lean, not attached]" item: `arith_finite_check`, `arith_payor_literal`, `arith_payor*`, `pa_payor_canonical`, `arith_payor_premise_reading`, `arith_payor_via_lob`/`pa_payor_via_lob`, `nat_of_provable_pi1`, `arith_payor_play`, `pa_payor_play`, `glCritchLG_linear_driver` (the only witness for §5's hypothesis), `botPremise_imp_con`, `arith_payor_bot_not_provable`, `pa_payor_bot_canonical`.
- The pp.all identity claim.
- All hand claims: the finite check in the symbol measure, its exponential cost, Gödel II in the symbol measure.
- Program inspection.
- That PA_bin satisfies the fields.
- T₀ = O(δ + log A).
- The 2^{2^{2^k}} figure.
- The cited LessWrong facts.

## 6. M5, the problem's quantifiers and constraints

The verbatim statement (problem page, l.15–21) has these requirements: "for every p ∈ Lang₁(S)", "with explicit k̂", "test whether the certificates … suffice", "prove that two copies of PB_k cooperate above an explicit threshold k̂*_P, and compare it with k̂* in a common system and encoding", and "use only bounded necessitation, quantifier distribution, and implication distribution".

- **For every p.** Theorems 1 and 2 are schematic in p, an arbitrary `S₁` formula. Met, within the abstract calculus. The premise is taken beyond k₀ rather than ∀k (l.28, "∀k>k₀"), which is a generalization and fine.
- **Explicit k̂.** Given (l.41, "k̂ = max(k₁, K(C_S+2N))"), but explicit relative to the lengths of the comparison proofs, which are unconstrained (M3 item 6). Partially met.
- **Only the three rules.** Met with qualifications:
  - (a) Quantifier distribution at every threshold is a strengthening of A1's form (l.43, "A1 states quantifier distribution for ∀k φ(k) with no threshold"). The version that uses A1's form verbatim adds a finite check whose symbol-measure proof is by Σ₁-completeness, a fact beyond the three rules (l.46).
  - (b) Propositional calculus, threshold shift, budget monotonicity and budget arithmetic are also used (l.19). This is reasonable, and A1 lists monotonicity among its bookkeeping.
- **In S / PA_bin.** Not met for any claim. Everything is over abstract structures (l.22, "Nothing is checked in A1's symbol measure for PA_bin itself"). The arithmetic instance is in the Gödel-code measure and "does not give thresholds" (l.48).
- **Theorem 3 (necessity).** This answers a variant: necessity in a model of the abstract calculus, for "Payor-only" fixed-parameter derivations (l.61). The Open section says plainly that necessity in S itself is open (l.149). Theorem 3 also shows only the log k order and C_S to be necessary. It does not show that the "for every standard A" form of Theorem 2's hypothesis is necessary, so l.59's "optimal up to the constant c_S" claims more than Theorem 3 shows.
- **"Prove two copies of PB_k cooperate."** Not met as stated. The post replaces the task with:
  - (i) a defect claim, relative to schematic, fixed-parameter derivations in the abstract calculus (l.71; the open item at l.150 concedes cross-parameter arguments);
  - (ii) PB^A_k, a different agent (§4);
  - (iii) literal PB_k via Löb, which violates the "only" constraint (uses the diagonal lemma and inner necessitation) and rests on "id internally regular", which is open for PA_bin.
  
  On (ii): Theorem 4's conclusion is provability of ∀k>k̂ c(k). Turning that into actual play is "Lean, not attached", arithmetic instance only (l.98).
- **Explicit k̂*_P.** Given for PB^A_k: max(k₀, 2A, 2C_S+4N_P). N_P includes certificate lengths again.
- **Compare with k̂* in a common system and encoding.** Not met. l.115: "A numerical comparison with k̂* cannot be made today." The §5 comparison is between certified upper bounds under "a hypothesis with no non-trivial witness" (l.114). It also uses "a common C_S" and N_P ≤ N_L as assumptions, not a common system.
- **A point that relies on my reading of A1.** PB^A_k's inner budget k − log₂k − A is not a Bud-term: A1's Bud has no subtraction and no log₂, only λ. Yet l.95 says the two certificates "are elementary inequalities between Bud-terms, covered by A1's comparison conjecture". A1 (conventions) admits non-Bud budgets only "when supplied with the corresponding internal certificates". So O13 would not cover Theorem 4's certificates as stated. I would ask the submitter about this. The post does not address it.

## 7. M6, the record (progress page)

**Proved** (Lean-checked over abstract rule-structures, in the attachment; not in PA_bin):
1. Bounded Payor lemma (Theorem 1). Assume a premise ∀k>k₀ (□_g(□_f p → p) → p), plus provable inequalities comb(qd(T₀), f) ≤ g beyond k₁ and qd(N) ≤ g beyond k̂. Then ∀k>k̂ p is provable, with explicit length, in a calculus with no diagonal lemma and no inner necessitation. Quantifier distribution is taken at every threshold. A variant with A1's verbatim quantifier distribution needs a finite check ⊢ ∀k (k≤K → q(k)) as a hypothesis.
2. Certificates (Theorem 2). If f+λ+A ≤*_S g for every standard A, the rule holds with k̂ = max(k₁, K(C_S+2N)). The problem's pair implies this family. The first member of the pair (bλ ≤* g) follows from the second when f ≥ 0. Elementary budget arithmetic and A1's cost shapes are assumed as fields.
3. Necessity for Payor-only arguments (Theorem 3). There is a two-world model of the calculus with A1's cost shapes, for each β. In it the rule at (β, g) fails for p = ⊥ if g < β+C_S+log₂k on a tail, and holds for all p if g ≥ β+C_S+log₂k+c_S on a tail. Scope: derivations that use each rule at a fixed parameter.
4. Literal PB_k in that model (f = g = β): the premise and the full fixed-point equation hold, ⊥ holds at no threshold, inner necessitation holds in a range, and the Löb rule fails below β.
5. The Payor premise yields a bounded Löb premise. With Critch's parametric bounded Löb theorem (also proved in the extract), this gives the conclusion for any f, g, at the cost of the diagonal lemma and inner necessitation. Under `le_cert` and "id internally regular", the literal PB_k cooperates at the Löb route's threshold, and its certified threshold is no better than FairBot_k's (under stated side conditions).
6. PB^A_k (inner budget k−log₂k−A, outer k) cooperates in the provability sense above max(k₀, 2A, 2C_S+4N_P), assuming `le_cert`, represented budgets, the program-inspection premise, and A ≥ C_S+2T₀+c_S (shown achievable for large A if T₀ ≤ a log₂A + d).

**Numerical / conditional:**
- §5 comparison: (1+e)·k̂*_P ≤ k̂_L. Lean-checked under a fixed-point hypothesis on N_L whose only witness is a GL model (not attached), with a common C_S and N_P ≤ N_L. These are certified upper bounds only. The post explicitly does not claim the Payor route is faster.
- A toy script with made-up constants illustrating the 1+e ratio. No claim depends on it.
- Asserted Lean in an unattached library (arithmetic instance, Gödel-code measure): soundness of the rule in Δ₁ T ⊇ IΣ₁, the finite check discharged, provability-to-play, and p = ⊥ excluded by Gödel II. These cannot be verified from the submission.

**Open:**
- Everything in PA_bin's symbol measure: that PA_bin satisfies the fields; the cost of threshold-form quantifier distribution and of the finite check; the comparison certificates (O13, plus non-Bud budgets for PB^A_k).
- Necessity in S itself, at budgets with g−f = o(λ) (the Payor analogue of O14).
- Whether any diagonal-free argument reasoning across parameters handles the literal PB_k.
- Unexploitability of PB^A_k and PB_k.
- Numerical comparison with k̂*, blocked on O12 and O16.
- Payor's own bounded agent (claimed in a comment), not settled.
- Recommended statement repair: name an agent with inner budget below outer, or state that PB_k needs the Löb route.

**What I had to ask or guess:**
- (a) Whether "[Lean, not attached]" goes under proved. I did not put it there.
- (b) Whether Lean's quantifier-distribution field matches A1's meta-level rule.
- (c) The Bud-term issue for PB^A_k's certificates.
- (d) Whether "optimal up to c_S" includes the "for every A" quantifier.
- (e) What "the generator length δ" is.

## 8. Stuck log

| Quote | Section | Why stuck | Resolved later? |
|---|---|---|---|
| "The version that assumes nothing more is `CertBHP.payor_family`. The `CritchBHP` statements also assume `le_cert`" | Opening l.9 | Lean names undefined at first use | Partly: `CritchBHP`/`le_cert` at l.20, `CertBHP` at l.22 ("structures whose fields are A1's cost facts and elementary arithmetic"). Full field list only in the README / Lean |
| "A bounded Payor lemma … PB^A_k" | l.11 | Agent named before definition | Yes, l.85 |
| "threshold shift" | §Setting l.19 | Not defined in words | No. Inferred from Lean `shift` (move ∀k>t to ∀k>t') |
| "$U(n,t,\Phi)$ means …" | l.17 | Defined, then never used in the post body | n/a; noise for the reader |
| "Theorem 2 … If for every standard A, eventually f(k)+log₂k+A ≤ g(k)" vs the next paragraph's "f+λ+A ≤*_S g" | §1 l.39–41 | Two hypotheses (truth versus provability), two Lean families; which is "Theorem 2"? Reread three times | Partly: "In Lean, the step from a true inequality to a proved one is `le_cert`". I had to work out the pairing myself |
| "K(A) is the threshold of the certificate at A" | l.41 | Notation K reused (A1's K for ≤*_S, the K-axiom in line 1, K in BHP₀'s finite check) | Resolved locally; the overload remained confusing |
| "Gödel-code measure" | l.46, l.48 | Undefined term | No. [from my own knowledge: proof length measured by the Gödel number, hence the towering budgets] |
| "the gap log₂k + A of Theorem 2 is optimal up to the constant c_S" | §2 l.59 | Theorem 3 shows only the β+C_S+log k threshold; it does not show "for every A" is needed | No |
| "Adding inner necessitation and the agent's fixed-point equation does not help" | §3 l.71 | `cm_inner` holds only "wherever C_S+log₂k ≤ β". Is that full inner necessitation? | No |
| "What is missing is the diagonal lemma." | l.71 | An unlabelled claim of sufficiency | Partly: `BHLG.payor_via_lob` adds the diagonal *and* inner necessitation, so "what is missing" is both |
| `BHLG`, `BHPcore`, `CritchBHLG` | §3 l.75–77 | Never defined in words in the post | `BHLG` only in the README ("rule sets with the diagonal lemma and inner necessitation"). `CritchBHLG`: l.22 calls it a structure of A1's cost facts; the README says "Critch's calculus with A1's cost shapes" |
| "Program inspection gives S ⊢ ∀k (□_k(□_k c→c)→c)" | §3 l.65 | "Program inspection" undefined | Partly: l.96 marks it a modelling assumption "same as A1's FairBot theorem" |
| "T₀ = O(δ+log A), where δ is the generator length" | §4 l.97 | "generator" undefined (the quine? the formula generator?) | No |
| "In PA_bin they are elementary inequalities between Bud-terms" | §4 l.95 | k−log₂k−A is not a Bud-term per A1 | No |
| "once logarithms are absorbed each threshold is twice its driver, where that term attains the maximum" | §5 l.111 | Hard to parse; reread twice | Partly, via the Lean table row |
| "`PayorPlay`'s reading in ℕ", "the GL models", "Gödel-II reduction" | Checking it l.121 | Undefined names in the coverage statement | `PayorPlay` no; GL models via l.114's `glCritchLG_linear_driver`; Gödel II via l.149 |
| "budget g reaches quantifier distribution's qd(N) somewhere above k₀" | Open l.149 | Long nested bracket inside a label; hard to tell what is hand and what is Lean | Partly |

## 9. Reading path

- **Read in full:**
  - post.md: everything, after the blind and screen passes.
  - The problem page.
  - A1's bookkeeping paragraph, the expansion definition, the conventions (Bud, ≤*_S, internal regularity), `thm:fairbot`, `thm:pbl`, `conj:comparison`, and the PB_k definition and `prob:payor`. These carry the exact rules and quantifiers M5 needs.
  - The README, PROVENANCE, Axioms.lean and the lakefile/toolchain, to compare the post's claims about the attachment.
- **Read selectively:**
  - Payor.lean structures and `BHP.payor`.
  - PayorCost.lean: `CritchBHP`, `payor_certificates`, `pbA_cooperates`, `cm_payor_threshold`'s statement.
  - PayorSymbol.lean: `CertBHP` fields, `payor_family`, `payor_problem_certificates`.
  - The script docstring and log.
  
  I read these to see whether the stated hypotheses match the prose, as the attachment-check step allows.
- **Skipped:** the proof bodies in all Lean files, AbstractG.lean, PayorLob.lean, PayorCompare.lean beyond name checks, the rest of A1, and the lake manifest beyond the revision lines. They were not needed for a disposition, and I am not building.

## 10. Protocol feedback

- The three-pass structure and the M-questions were clear. The blind 1–11 window fit the opening exactly.
- The suggested label searches (`[Lean`, `[hand`, `[toy`) miss "[modelling assumption]" and the unbracketed "**Lean-checked:**" list. A general `\[[A-Za-z]` grep works better.
- "Say how long the screen took" is ambiguous for a simulated reader. "How much you had to read" was the workable reading.
- Allowing the attachment to be read but not built left open how far to read the Lean. I stopped at statements and hypotheses. A line saying "statements yes, proofs no" would make that explicit.

