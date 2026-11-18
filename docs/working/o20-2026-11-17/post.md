# Issue title: MAIS-O20: partial progress — the certificates suffice for a bounded Payor lemma; literal PB_k needs the Löb route

(Attachment: mais-o20-bundle.zip)

**A bounded Payor lemma: the certificates suffice and are sharp for Payor-only arguments, but the literal $\mathrm{PB}_k$ is out of their reach**

This answers the lemma half of O20. The certificates suffice, and the problem's pair is stronger than necessary: a gap of $\log k$ plus a constant that depends on the premise's proof length is enough. For derivations from the permitted rules, a gap of order $\log k$ cannot be removed.

**What the lemma half assumes.** The proofs are over a structure whose fields are A1's cost facts and elementary arithmetic, and that $\mathsf{PA}_{\mathrm{bin}}$ satisfies those fields is not checked. The version that assumes nothing more is `CertBHP.payor_family`. The `CritchBHP` statements also assume `le_cert`, which for $\mathrm{Bud}$-terms is A1's comparison conjecture (MAIS-O13). Both versions use quantifier distribution at every threshold, which A1 does not state. With A1's form taken verbatim, the lemma needs an extra finite check, and $\hat k$ stays explicit but becomes much larger (§1).

On the agent half we found a defect in the statement. The literal $\mathrm{PB}_k$ has equal inner and outer budgets, and no argument from bounded necessitation, quantifier distribution and implication distribution alone proves that it cooperates. We prove cooperation for a repaired agent $\mathrm{PB}^A_k$ instead. The numerical comparison with $\hat{k}^{\ast}$ stays open.

Every claim is labelled **[Lean]** (theorem named), **[hand]** (hand proof), or **[toy]** (made-up constants).

### Setting

To make "uses only the permitted rules" precise, the Lean statements are over a structure whose fields are the rules. Proof lengths are explicit cost functions. $U(n,t,\Phi)$ means "a proof of at most $n$ symbols of $\forall k>t\ \Phi(k)$".

- `BHP` has the propositional calculus (K, S, modus ponens), threshold shift, bounded necessitation, implication distribution, monotonicity of $\Box_a$ in $a$, and quantifier distribution. It has **no diagonal lemma and no inner necessitation**. Implication distribution turns budgets $a,b$ into $\mathrm{comb}(a,b)$, and quantifier distribution of a proof of length $n$ yields box budget $\mathrm{qd}(n)$. The proof of Theorem 1 applies implication distribution only once, to the box of a provable implication (line 2). That is the "weak distributivity" ($\vdash x\to y$ gives $\vdash\Box x\to\Box y$) that [Demski 2023](https://www.lesswrong.com/posts/ZWhJcHPmRaXAPAK5k/probabilistic-payor-lemma) showed is all Payor's argument needs. Vladimir Nesov noted in a comment there that it needs no inner necessitation.
- `CritchBHP` extends it with the cost shapes of MAIS-A1 §2.2: implication distribution costs $a+b+c_S$, and quantifier distribution's box budget is $C_S+2n+\log_2 k$. It also has a field `le_cert`: a pointwise true budget inequality beyond $t$ is provable beyond $t$. For $\mathrm{Bud}$-terms this is A1's comparison conjecture (O13). **It is an assumption of the Lean statements in `CritchBHP`.**

Nothing is checked in A1's symbol measure for $\mathsf{PA}_{\mathrm{bin}}$ itself. The symbol-measure readings below are Lean theorems over structures whose fields are A1's cost facts and elementary arithmetic (`CertBHP`, `CritchBHLG`); that $\mathsf{PA}_{\mathrm{bin}}$ satisfies those fields is not checked.

### 1. The lemma

Write $q(k)$ for $\Box_{f(k)}p(k)\to p(k)$, and $T_0$ for the length of the K-instance $\forall k\ (p\to q)$.

**Theorem 1 (bounded Payor)** [Lean: `BHP.payor`]. Suppose $\forall k>k_0\ (\Box_g q\to p)$ has a proof of length $n_0$. Suppose $\mathrm{comb}(\mathrm{qd}(T_0),f)\le g$ is proved beyond $k_1\ge k_0$, and $\mathrm{qd}(N)\le g$ is proved beyond $\hat k\ge k_1$, where $N$ is the length of line 4 below. Then $\forall k>\hat k\ p(k)$ has a proof of explicit length.

The proof is Payor's four lines with budgets attached:

1. $\vdash\forall k\ (p\to q)$, the K-axiom, of length $T_0$.
2. Quantifier distribution and implication distribution give $\vdash\forall k\ (\Box_f p\to\Box_{\mathrm{comb}(\mathrm{qd}T_0,f)}\ q)$.
3. Monotonicity with the first inequality gives $\vdash\forall k>k_1\ (\Box_f p\to\Box_g q)$.
4. Composing with the premise gives $\vdash_N\forall k>k_1\ q(k)$.
5. Necessitate line 4 and distribute, then read it at budget $g$ through the second inequality: $\vdash\forall k>\hat k\ \Box_g q$.
6. Modus ponens with the premise gives $\vdash\forall k>\hat k\ p$.

**Theorem 2 (the certificates suffice)** [Lean, without `le_cert`: `CertBHP.payor_family`, `CertBHP.payor_problem_certificates`; with `le_cert`: `CritchBHP.payor_certificates`, `CritchBHP.payor_lam_family`]. If for every standard $A$, eventually $f(k)+\log_2 k+A\le g(k)$, then every premise at $(f,g)$ gives $\forall k>\hat k\ p$ for some $\hat k$. The two certificates used are $A=C_S+2T_0+c_S$ and $A=C_S+2N$.

In Lean, the step from a true inequality to a proved one is `le_cert`. In $S$ the problem's certificates are themselves the proofs, after elementary arithmetic [Lean: `CertBHP.payor_family`, which has no `le_cert`; the arithmetic is `CertBHP`'s fields]. In the symbol measure, $\log_2 k\le\lambda(k)$, so the family **$f+\lambda+A\le_S^{\ast} g$ for every standard $A$** suffices. The problem's pair implies it [Lean: `CertBHP.family_of_two_lam`]. The first member of the pair, $b\lambda\le_S^{\ast} g$, is redundant, because it follows from the second, $f+b\lambda\le_S^{\ast} g$, when $f\ge0$ [Lean: `CertBHP.smul_le_of_add`]. The threshold is explicit: $\hat k=\max(k_1,K(C_S+2N))$, where $K(A)$ is the threshold of the certificate at $A$ [Lean: `CertBHP.payor_family`]. It is where $g$ overtakes $C_S+2N+\log k$. Neither $\mathcal E\circ\lambda$ nor $d_S$ appears.

**A subtlety about quantifier distribution.** Line 5 necessitates a formula proved only beyond $k_1$, but A1 states quantifier distribution for $\forall k\ \varphi(k)$ with no threshold. A1's own `thm:pbl` has the same need (its eq. 5.7 step). There are two ways to read it:

- `BHP` takes quantifier distribution at every threshold as a field. That is what Theorems 1 and 2 use.
- `BHP₀.payor_literal` [Lean] uses A1's form verbatim. It needs a finite check $\vdash\forall k\ (k\le K\to q(k))$ instead, taken as a hypothesis. That the check is provable for standard $K$ is Lean-checked in the arithmetic instance, Gödel-code measure, by absoluteness of standard proofs, and `payor_literal` then runs with it discharged [Lean, not attached: `arith_finite_check`, `arith_payor_literal`]. In the symbol measure it remains a hand proof by $\Sigma_1$-completeness and A1's finite-check device, and its cost there can be exponential in $f(K)$ [hand estimate]. So $\hat k$ stays explicit but becomes much larger.

**Arithmetic instance** [Lean, not attached: `arith_payor`, `arith_payor_canonical`, `pa_payor_canonical`, `arith_payor_premise_reading`]. Theorem 1 holds verbatim for every $\Delta_1$ theory $T\supseteq\mathsf{I\Sigma}_1$, at every threshold, with budgets given as provably total $\Sigma_1$ graphs. `arith_payor_premise_reading` is `Iff.rfl`: the premise is the intended arithmetic sentence. This instance is in the Gödel-code measure, where every quantifier-distribution budget exceeds $2^{2^{2^k}}$. So it shows the rule is sound and diagonal-free in a real arithmetic. It does not give thresholds. This instance sits on a larger library over FormalizedFormalLogic's `Foundation`, which is not in the attachment.

### 2. The gap is necessary for Payor-only arguments

**Theorem 3** [Lean: `cmodel`, `cm_payor_threshold`]. For every inner budget $\beta$ and constants $c_S,C_S$ there is a model of `CritchBHP` with exactly A1's cost shapes in which, for every outer budget $g$:

- if $g(k)<\beta(k)+C_S+\log_2 k$ on a tail, the Payor rule at $(\beta,g)$ fails for $p=\bot$;
- if $g(k)\ge\beta(k)+C_S+\log_2 k+c_S$ on a tail, the rule holds for every $p$.

The model has two worlds, one sound and one "deviant". The deviant world has a proof of $\bot$ of length exactly $\beta(k)$ at parameter $k$, and nothing shorter except valid formulas, which cost $C_S+\log_2 k$. The formula $\Box_\beta\bot\to\bot$ is neither valid nor empty, so only ex falso can box it, and ex falso costs $\beta+C_S+\log_2 k$.

So for derivations from the permitted rules with A1's cost shapes, the gap $\log_2 k+A$ of Theorem 2 is optimal up to the constant $c_S$.

**Scope.** The model's boxes at parameter $k$ say nothing about other parameters. So it does not cover a derivation that reasons about varying $k$ inside $S$. It covers the request as posed: the three rules, each used at a fixed parameter as A1 states them.

### 3. A defect in the statement: the literal $\mathrm{PB}_k$

Program inspection gives $S\vdash\forall k\ (\Box_k(\Box_k c\to c)\to c)$, so the literal agent has $f=g=k$. That violates the certificate $f+b\lambda\le_S^{\ast} g$ for every $b\ge1$. In the model of §2, with $f=g=\beta$:

- the premise holds and $\bot$ holds above no threshold [Lean: `cm_literal_rule_fails`];
- the converse also holds, so $\bot$ satisfies the agent's full fixed-point equation $c\leftrightarrow\Box_\beta(\Box_\beta c\to c)$ [Lean: `cm_literal_fixed_point`];
- bounded inner necessitation holds with $\mathcal E(a)=2a$ wherever $C_S+\log_2 k\le\beta$ [Lean: `cm_inner`], but there is no Löb fixed point in the range $C_S+\log_2 k\le g<\beta$ [Lean: `cm_no_fixed_point`], and the bounded Löb rule fails at every $f<\beta$ [Lean: `cm_lob_rule_fails`].

So no derivation from the permitted rules, schematic in $p$, proves that two copies of $\mathrm{PB}_k$ cooperate. Adding inner necessitation and the agent's fixed-point equation does not help. What is missing is the diagonal lemma. (A1 notes that Payor's lemma removes the diagonal sentence from the proof, not the quine from the agent. The obstruction here is about budgets, not the quine.)

The literal agent does cooperate in $S$, but only through the Löb route:

- **[Lean: `BHPcore.lob_premise`]** The Payor premise at $(f,g)$ gives a bounded Löb premise $\forall k>k_1\ (\Box_{f'}p\to p)$ for every $f'$ with $\mathrm{comb}(\mathrm{qd}T_0,f')\le g$. Here $f$ enters only through $T_0$.
- **[Lean: `BHLG.payor_via_lob`]** Composing with Critch's parametric bounded Löb theorem (`BHLG.pblt`, also in the attachment) finishes, for any $f,g$, including $f=g$, once $f'$ meets that theorem's hypotheses. Those include the diagonal sentence and an inner-necessitation instance. The arithmetic versions (`arith_payor_via_lob`, `pa_payor_via_lob`) are Lean-checked too, in the Gödel-code measure, but not attached.
- **[Lean: `CritchBHLG.literal_pb_via_lob`, `CritchBHLG.payor_via_lob_regular`, `CritchBHLG.pblt_of_regular`, over `CritchBHLG`, which assumes `le_cert`]** In the symbol measure, take $f'=k-\lambda-A$. Under A1's standing hypothesis that $f(k)=k$ is internally regular, the same hypothesis as A1's FairBot theorem, `thm:pbl` applies. The threshold is the Löb route's at budget $k-\lambda-A$, so the literal $\mathrm{PB}_k$ gains nothing over $\mathrm{FairBot}_k$ by this route [Lean: `CritchBHLG.fairbot_certified_le_literal`. It compares **certified** thresholds, the ones these proofs produce, not least thresholds, and it assumes that FairBot's route length, diagonal-proof length and premise threshold are no larger than the literal agent's].

This is the bounded counterpart of a known unbounded fact: in $\mathsf{PA}$, the Payorian FairBot $A\leftrightarrow\Box(\Box A\to B)$ is equivalent to the original FairBot $A\leftrightarrow\Box B$, and the equivalence uses Löb's theorem (a comment on [Payorian cooperation is easy with Kripke frames](https://www.lesswrong.com/posts/LaCP6WyNzX8kiZn3w/payorian-cooperation-is-easy-with-kripke-frames), 2026).

*Suggested repair:* name an agent with an inner budget below the outer one, as below, or say that $\mathrm{PB}_k$ needs the Löb route. Critch's bounded conjecture in the comments of [his 2023 post](https://www.lesswrong.com/posts/2WpPRrqrFQa6n2x3W/modal-fixpoint-cooperation-without-loeb-s-theorem) has this shape too: if $\mathrm{ShortProof}(x\leftrightarrow\mathrm{LongProof}(\mathrm{ShortProof}(x)\to x))$, then $\mathrm{MediumProof}(x)$. He gives no calculation.

### 4. Two copies of $\mathrm{PB}^A_k$ cooperate

$\mathrm{PB}^A_k$ searches all proofs of at most $k$ symbols for a proof of $\Box_{k-\log_2 k-A}\ c\to c$, and plays $\mathsf C$ if it finds one.

**Theorem 4** [Lean: `CritchBHP.pbA_cooperates`]. Suppose program inspection gives $\forall k>k_0\ (\Box_k(\Box_{k-\log_2 k-A}c\to c)\to c)$, of length $n_0$, and $A\ge C_S+2T_0+c_S$. Then $\forall k>\hat k^{\ast}_{\mathrm P}\ c(k)$ is provable, with

$$\hat k^{\ast}_{\mathrm P}=\max(k_0,\ 2A,\ 2C_S+4N_P),$$

where $N_P$ is the length of line 4 of Theorem 1. The proof uses no diagonal sentence and no inner necessitation.

What Lean does not check (that both budgets are represented is also a hypothesis there):

- **The two comparison certificates** come from the field `le_cert`. In $\mathsf{PA}_{\mathrm{bin}}$ they are elementary inequalities between $\mathrm{Bud}$-terms, covered by A1's comparison conjecture but not formalized here.
- **Program inspection** [modelling assumption]. This is the same assumption A1's FairBot theorem makes, and it is not verified here.
- **Choosing $A$** [Lean: `CritchBHP.exists_large_A`, `CritchBHP.pbA_cooperates_large`, with $T_0\le a\log_2 A+d$ as a hypothesis]. $T_0=O(\delta+\log A)$, where $\delta$ is the generator length, so $A\ge C_S+2T_0+c_S$ holds for all large $A$.
- **From provability to play** [Lean, not attached: `nat_of_provable_pi1`, `arith_payor_play`, `pa_payor_play`, for the arithmetic instance with $c\in\Pi_1$; that $c$ means cooperation is the program-inspection assumption]. $c(k)$ is about a terminating computation, so $\Sigma_1$-completeness and consistency of $S$ turn $S\vdash c(\bar k)$ into actual cooperation.
- **Unexploitability is not claimed.** Against an opponent that provably defects, whether $\neg\Box_f c$ has a short proof is a bounded-consistency question that we have not settled. The same question arises for the literal $\mathrm{PB}_k$.

### 5. Comparison with the bounded Löb route

| | hypothesis shape | budget window | threshold driver | uses |
|---|---|---|---|---|
| Löb (A1 `thm:pbl`) | $\forall k>K_0\ (\Box_f p\to p)$ | $f$ internally regular | $\approx(1+e)(2N_L+C_S)+2d_S$ | diagonal, inner nec. |
| Payor (§1) | $\forall k>k_0\ (\Box_g(\Box_f p\to p)\to p)$ | $f+\lambda+A\le_S^{\ast} g$ for all $A$; sharp up to $c_S$ for Payor-only (§2) | $\approx 2N_P+C_S$ | neither |
| Payor premise via Löb (§3) | as Payor | $g$ internally regular, any $f$ | Löb's at budget $g-\lambda-A$ | diagonal, inner nec. |
| literal $\mathrm{PB}_k$ | Payor, $f=g=k$ | outside the Payor window (§3) | Löb's at $k-\lambda-A$ | diagonal, inner nec. |
| $\mathrm{PB}^A_k$ (§4) | Payor, $f=k-\log_2 k-A$, $g=k$ | inside the Payor window | $\max(k_0,2A,2C_S+4N_P)$ | neither |

Here $e$ is the slope of $\mathcal E(m)=em+e_0$, and logarithmic terms are dropped. The Löb driver as Lean states it (below) adds $C_S+2c_S+e_0$ to the table's expression, and once logarithms are absorbed each threshold is twice its driver, where that term attains the maximum.

- **Lean-checked:** the Payor route lives in `BHP`, which has no diagonal or inner-necessitation field; the model of §2 separates the two routes; the $\mathrm{PB}^A_k$ threshold; the literal agent's reduction to the Löb route; the Löb column's threshold driver, under the fixed-point hypothesis stated below.
- **The Löb column's driver rests on an unverified hypothesis** [Lean: `CritchBHLG.lob_linear_driver`, `pbA_mul_le_lobLinThr`, over `CritchBHLG`, which assumes `le_cert`]. With $\mathcal E(m)\le em+e_0$, the Löb route at $f=k$ certifies $\hat k_L=\max(k_0,\ 2D_L,\ 2^{2e+8})$, $D_L=(1+e)(2N_L+C_S)+2d_S+C_S+2c_S+e_0$, when $d_S$ bounds the diagonal sentence's proof length and $N_L$ bounds the route's own proof length at the budget $g=C_S+2N_L+\log_2 k$ chosen from $N_L$. That last hypothesis is a fixed point, since the route's length depends on $N_L$ through $g$. Its only known witness is the GL model, where every length is $0$ [Lean, not attached: `glCritchLG_linear_driver`], and it is not known to hold for $\mathsf{PA}_{\mathrm{bin}}$. Under it, with a common $C_S$, $N_P\le N_L$, and $\hat k^{\ast}_{\mathrm P}$ attained by its term $2C_S+4N_P$, $(1+e)\,\hat k^{\ast}_{\mathrm P}\le\hat k_L$. **This is not a claim that the Payor route is faster.** It compares the upper bounds these two proofs certify, under a hypothesis with no non-trivial witness, and neither threshold has a known lower bound.
- **A numerical comparison with $\hat k^{\ast}$ cannot be made today.** $\hat k^{\ast}$ is not known to be finite (MAIS-O16), and $\mathcal E_S$ and $d_S$ for $\mathsf{PA}_{\mathrm{bin}}$ are open (MAIS-O12).

### Checking it

The attached zip holds `lean/`, a Lake project pinned to Lean and Mathlib `v4.33.1` that imports only Mathlib, plus `scripts/thresholds.py`, a toy with made-up constants that illustrates the $1+e$ scaling of §5. Nothing in this post depends on the script.

- The seven Lean files (1,919 lines) are an extract of a larger library: contiguous runs of its source, copied verbatim, with new import lines and module docstrings. Every cited declaration prints identically under `pp.all` in the extract and in the library. The extract covers everything in this post except the arithmetic instance (with the finite check and the Gödel-II reduction), `PayorPlay`'s reading in ℕ, and the GL models.
- Build with `lake exe cache get && lake build` (about 35 s on top of the Mathlib cache), then `lake env lean Axioms.lean`.
- No file uses `sorry`, `native_decide`, `decide` or `axiom`. `Axioms.lean` prints `#print axioms` for 41 declarations. The abstract lemma, Critch's theorem and their compositions (`BHP.payor`, `BHP₀.payor_literal`, `BHPcore.lob_premise`, `BHLG.pblt`, `BHLG.payor_via_lob` and three more), and `CertBHP.smul_le_of_add`, depend on no axioms. The rest depend on a subset of `propext`, `Quot.sound` and `Classical.choice`; 14 of them use `Classical.choice`.
- `python3 scripts/thresholds.py` runs in under a second and reproduces `scripts/thresholds.log`.

| Theorem | Statement |
|---|---|
| `BHP.payor` | the bounded Payor lemma, explicit threshold and length |
| `BHP₀.payor_literal` | the same with A1's quantifier distribution verbatim, plus a finite check |
| `CritchBHP.payor_certificates` | $f+\log_2 k+A\le g$ eventually, for every $A$, suffices |
| `cm_payor_threshold` | in a model with A1's cost shapes, the gap is necessary and sufficient up to $c_S$ |
| `cm_literal_rule_fails`, `cm_literal_fixed_point` | the literal $\mathrm{PB}_k$ is out of reach of the permitted rules |
| `BHPcore.lob_premise`, `BHLG.payor_via_lob` | the Payor premise gives a Löb premise, and Löb (`BHLG.pblt`) finishes for any $f,g$ |
| `CritchBHP.pbA_cooperates` | two copies of $\mathrm{PB}^A_k$ cooperate above $\max(k_0,2A,2C_S+4N_P)$ |
| `CertBHP.payor_family` | with certificates as proofs: $f+\lambda+A\le_S^{\ast} g$ for every $A$ suffices, at $\hat k=\max(k_1,K(C_S+2N))$ |
| `CertBHP.family_of_two_lam`, `CertBHP.smul_le_of_add` | the pair's $f+2\lambda\le_S^{\ast} g$ implies the family; $b\lambda\le_S^{\ast} g$ follows from $f+b\lambda\le_S^{\ast} g$ |
| `CertBHP.payor_problem_certificates` | the problem's pair of certificates suffices |
| `cmCert`, `cmCert_pair` | the countermodel carries `CertBHP`'s fields, and the pair holds there at one budget $g=\beta+\lambda^2$ for every $b$ |
| `CritchBHP.payor_lam_family` | the same family reading in `CritchBHP`, with $\log_2 k\le\lambda(k)$ and the explicit threshold |
| `CritchBHP.exists_large_A`, `CritchBHP.pbA_cooperates_large` | if $T_0\le a\log_2 A+d$, then $A\ge C_S+2T_0+c_S$ for all large $A$, and $\mathrm{PB}^A_k$ cooperates |
| `CritchBHLG.pblt_of_regular` | A1's `thm:pbl` in the cost model: an internally regular budget gives the Löb rule, at an explicit threshold `lobThr` |
| `CritchBHLG.regular_sub`, `CritchBHLG.lob_premise_regular` | regularity survives $-\lambda-A$; the Payor premise gives the Löb premise at $g-\lambda-A$ |
| `CritchBHLG.payor_via_lob_regular`, `CritchBHLG.literal_pb_via_lob` | an internally regular outer budget needs no gap, at the Löb route's threshold for budget $g-\lambda-A$; the literal $\mathrm{PB}_k$ cooperates if $\mathrm{id}$ is internally regular |
| `CritchBHLG.fairbot_certified_le_literal` | the literal $\mathrm{PB}_k$'s threshold is at least $\mathrm{FairBot}_k$'s, as certified bounds, at a FairBot route length, diagonal-proof length and premise threshold no larger than the literal agent's |
| `CritchBHLG.lob_linear_driver`, `pbA_mul_le_lobLinThr` | the Löb driver $\hat k_L$, given that $N_L$ bounds the route's own length (a fixed point); $(1+e)\hat k^{\ast}_{\mathrm P}\le\hat k_L$ with a common $C_S$, $N_P\le N_L$ and $\hat k^{\ast}_{\mathrm P}=2C_S+4N_P$ |

### Open

- **Necessity in $S$ itself.** §2 is about Payor-only derivations. In $S$, §3 shows no gap is needed once $g$ is internally regular, so necessity can only bite at logarithmic $g$. Is there a $p$, and budgets at the $\lambda$ scale with $g-f=o(\lambda)$, such that $\mathsf{PA}_{\mathrm{bin}}$ proves the Payor premise but no tail of $p$? This is the Payor counterpart of the Löb window (MAIS-O14). The instance $p=\bot$ cannot be such a $p$: its premise is $\forall k\ \neg\Box_{g(k)}\mathrm{Con}_{f(k)}$, with $\mathrm{Con}_m=\neg\Box_m\bot$, and a consistent $S$ does not prove it whenever $S$ proves $g-\log k$ unbounded. The proof reduces it to Gödel's second incompleteness theorem [hand in the symbol measure; Lean, not attached, in the arithmetic instance's Gödel-code measure: `botPremise_imp_con`, `arith_payor_bot_not_provable`, `pa_payor_bot_canonical`. There the growth condition is that in every model of $T$, for every $N$, the budget $g$ reaches quantifier distribution's $\mathrm{qd}(N)$ somewhere above $k_0$; in the symbol measure that condition is "$g-\log k$ unbounded", and the symbol-measure statement is not checked].
- **Diagonal-free arguments across parameters.** §3 does not exclude an argument for the literal $\mathrm{PB}_k$ that reasons about varying $k$ inside $S$. We know of none.
- **Unexploitability, for both agents.** Neither $\mathrm{PB}^A_k$ nor the literal $\mathrm{PB}_k$ is shown to defect against an opponent that provably defects. That needs a short proof of $\neg\Box_f c$, a bounded-consistency question we have not settled (§4). In the unbounded setting, James Payor proves in a comment on Critch's post that $A\leftrightarrow\Box(\Box A\to B)$ cooperates only if $\Box B$. Even there, proving that this agent defects against DefectBot needs a consistency assumption, as noted in the comments on the Kripke-frames post above. In the same thread Payor sketches, unvetted, a bounded PrudentBot that searches for proofs of $\Box A\to B$ and $\Box\neg A\to B$ with budgets $m$ and $f(m)=2m+C$.
- **Symbol-measure constants.** The cost of threshold-form quantifier distribution in $\mathsf{PA}_{\mathrm{bin}}$, and of the finite check, are not computed.
- **The numerical comparison with $\hat k^{\ast}$**, blocked on MAIS-O12 and MAIS-O16.

We found no bounded Payor lemma with explicit budgets or threshold in print. The nearest items are two comments on Critch's post: his conjecture quoted in §3, and James Payor's bounded agent $A_k(B)\leftrightarrow\exists i\le k\ \Box_i(\Box_{i+C}A_k(B)\to B(A_k))$, which he claims, without proof, cooperates with a copy of itself for large $k$. Its inner budget exceeds its outer one, outside the window of Theorem 2. It also searches over $i$, so it reasons across parameters, which §2's model does not cover. We have not settled his claim. Theorem 1 is close to Payor's proof with budgets attached, so the new content is mainly §2 to §4.

*Mitchell Owen, with Claude Opus 5.5.*
