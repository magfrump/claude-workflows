# Session: builder (simulated)

**Run:** 2026-11-17, protocol v1, built the attachment from a fresh unzip (run logs: cache.out, build.out, axioms.out and thresholds.out, in the scratch bundle). **Isolation note:** wrote one scratch file (names.txt) one level outside the allowed folder.

# Builder read of the MAIS-O20 post and its attachment

## 1. Blind first take (lines 1–11 only)

The post is partial progress on O20, in two halves. On the lemma half, it says the problem's certificates suffice for a bounded Payor lemma, that a weaker gap of about `log k + const(premise length)` is enough, and that the `log k` gap cannot be removed for derivations that use only the permitted rules. Line 9 states the assumptions up front: Lean structures whose fields are A1's cost facts (not checked against PA_bin), a `le_cert` field equal to A1's comparison conjecture O13 in the `CritchBHP` statements, and quantifier distribution at every threshold, which A1 does not state. On the agent half, it claims the literal PB_k cannot be shown to cooperate by Payor-only rules, because its inner and outer budgets are equal. It proves cooperation for a repaired agent PB^A_k instead and leaves the comparison with k̂* open. From these lines a builder already knows which Lean names to look for first: `CertBHP.payor_family`, `CritchBHP`, `le_cert`.

## 2. Answers

### B1. One open question, stated precisely

From "Open", first bullet: *"Is there a $p$, and budgets at the $\lambda$ scale with $g-f=o(\lambda)$, such that $\mathsf{PA}_{\mathrm{bin}}$ proves the Payor premise but no tail of $p$?"* The bullet also says: *"§3 shows no gap is needed once $g$ is internally regular, so necessity can only bite at logarithmic $g$"*, and *"The instance $p=\bot$ cannot be such a $p$ … whenever $S$ proves $g-\log k$ unbounded."*

My working statement:
- **System:** S = PA_bin (A1's fixed system).
- **Question:** do there exist p ∈ Lang₁(S) and represented budgets f, g with the following properties?
  - g = O(λ) and g is not internally regular.
  - g − f = o(λ). I read this as an external (metatheoretic) o(λ).
  - S ⊢ ∀k (□_{g(k)}(□_{f(k)} p(k) → p(k)) → p(k)). I took the problem page's no-threshold form; the post's Theorem 1 allows ∀k>k₀.
  - For no standard k̂ does S ⊢ ∀k>k̂ p(k).
- **What counts as an answer:** such a pair (f, g) with a witness p, or a proof that none exists.
- **Constraint from the post:** p = ⊥ is excluded whenever S ⊢ "g − log k unbounded". So a witness must be either a non-⊥ p, or a g for which S does not prove that.

**What I had to fill in.**
- "Budgets at the λ scale" is never defined. I read it as g = Θ(λ) or O(λ).
- The post does not say whether o(λ) is external or internal (≤*_S).
- The post does not say whether the premise carries a threshold k₀.
- "Internally regular" is used here before it is defined in prose. The Lean defines it (`CritchBHLG.Regular`: ∀b ∃K ∀k>K, E(2λ)+bλ ≤ F).

The post was enough to start work, but not enough to fix the quantifiers on the budgets without guessing.

### B2. Two reusable results: Lean hypotheses against the post

**(a) `BHP.payor`** (Payor.lean, lines 264–272). Post, §1 Theorem 1: *"Suppose $\forall k>k_0\ (\Box_g q\to p)$ has a proof of length $n_0$. Suppose $\mathrm{comb}(\mathrm{qd}(T_0),f)\le g$ is proved beyond $k_1\ge k_0$, and $\mathrm{qd}(N)\le g$ is proved beyond $\hat k\ge k_1$ … Then $\forall k>\hat k\ p(k)$ has a proof of explicit length."*

Lean hypotheses:
- `hf : B.Rep f`, `hg : B.Rep g`
- `h₀₁ : k₀ ≤ k₁`, `h₁ : k₁ ≤ kHat`
- `hyp : B.U n₀ k₀ (B.imp (B.box g (B.q p f)) p)`
- `i₁ : B.U m₁ k₁ (B.le (B.cP p f f) g)`
- `i₃ : B.U m₃ kHat (B.le (B.qd (B.lenN p f g k₀ k₁ n₀ m₁)) g)`
- Conclusion: `B.U (B.lenP p f g k₀ k₁ kHat n₀ m₁ m₃) kHat p`.

How it matches:
- The quantifiers match.
- The post omits `Rep f` and `Rep g`. They are implicit in the problem page's "represented budgets".
- N depends on m₁, the length of the i₁ proof. The post's "the length of line 4" covers this.
- "Explicit length" means `lenP`, which is opaque in the abstract `BHP`.
- The structure `BHP` supplies threshold-form `qdist`, as the post's "A subtlety" section says.

**Second result, a caution: `BHP₀.payor_literal`.** The Lean premise is `hyp : B.U n₀ 0 …`, with threshold 0, not k₀. The post's §1 says only that it "uses A1's form verbatim … needs a finite check … taken as a hypothesis." The post never says the premise loses its k₀. The README and the docstring do say it ("no threshold, as printed in MAIS-O20").

**(b) `CritchBHP.pbA_cooperates`** (PayorCost.lean, lines 105–123). Post, §4 Theorem 4: *"Suppose program inspection gives $\forall k>k_0\ (\Box_k(\Box_{k-\log_2 k-A}c\to c)\to c)$, of length $n_0$, and $A\ge C_S+2T_0+c_S$. Then $\forall k>\hat k^{\ast}_{\mathrm P}\ c(k)$ is provable, with $\hat k^{\ast}_{\mathrm P}=\max(k_0,\ 2A,\ 2C_S+4N_P)$"*, together with *"that both budgets are represented is also a hypothesis there"*.

Lean hypotheses:
- `hf : B.Rep (B.fA A)`, `hg : B.Rep B.gId`
- `hA : B.CS + 2 * B.T₀ c (B.fA A) + B.cS ≤ A`
- `hyp : B.U n₀ k₀ (B.imp (B.box B.gId (B.q c (B.fA A))) c)`
- Conclusion: `∃ M, B.U M (B.kHatA c A k₀ n₀) c`, where `kHatA = max (max k₀ (2A)) (2CS + 4·NA)`.

How it matches:
- The threshold and quantifiers match.
- The structure `CritchBHP` assumes `le_cert`. The post says this.

Differences the post does not mention:
1. `fA A` is truncated subtraction, `k - Nat.log2 k - A` on ℕ.
2. T₀ in `hA` depends on A through `fA A`, so `hA` is not a free choice. The post handles this only in its "Choosing A" bullet (`exists_large_A`, with hypothesis `T₀ ≤ a·log₂A + d`).
3. N_P (`NA`) contains `leL`, the length of the `le_cert` certificate. The post does not say that N_P depends on certificate lengths.

**Mismatch on a related result: `CertBHP.payor_family`.** Post, §1: *"The threshold is explicit: $\hat k=\max(k_1,K(C_S+2N))$."* The Lean conclusion is `∃ m₁ M, B.U M (max (k₁F K p f k₀) (K (CS + 2·lenN … m₁))) p`. Here m₁ is existentially chosen because `PLe` records no lengths, so k̂ is explicit only up to an unknown m₁. The docstring says this ("`N` is explicit up to it"); the post does not. The post also leaves k₁ undefined in Theorem 2. The Lean value is `k₁F = max(k₀, K(C_S+2T₀+c_S))`.

### B3. Running it

| Step | Command (from `lean/`) | Wall clock | Result |
|---|---|---|---|
| Cache | `lake exe cache get` | 105 s | exit 0. Included a mathlib git clone; 8690 files downloaded and decompressed. |
| Build | `lake build` | **81 s** | exit 0, "Build completed successfully (8713 jobs)", 0 warnings or errors. The first file, LenSys, took 44 s (Mathlib load); each of the other six took 4.3–6.5 s. |
| Axioms | `lake env lean Axioms.lean` | 5 s | exit 0, **41** `#print axioms` lines. |
| Toy script | `python3 scripts/thresholds.py` (from the bundle root) | 0.035 s | Output is byte-identical to `scripts/thresholds.log` (`diff` is empty). |

The elan toolchain `leanprover/lean4:v4.33.1` was already installed, so no toolchain download was needed.

Axioms output against the post:
- **9 declarations** depend on no axioms: `BHP.payor`, `BHP.payor_eventually`, `BHP₀.payor_literal`, `BHPcore.lob_premise`, `BHLG.pblt`, `BHLGX.pblt`, `BHLG.payor_via_lob`, `BHLGX.payor_via_lob`, `CertBHP.smul_le_of_add`. This matches the post's "(… and three more), and `CertBHP.smul_le_of_add`".
- The rest use subsets of {propext, Quot.sound, Classical.choice}. **14** use Classical.choice, which matches. Nothing non-standard appears.

Match with what the post promises: everything matches except build time. The post says *"about 35 s on top of the Mathlib cache"* and the README says *"under a minute"*. I observed 81 s, about 37 s of it outside the cold first file.

Minor: the post's "Checking it" section does not say to `cd lean` first. The README does.

### B4. Is everything the post claims actually in the zip?

Checked and true:
- Seven extract files under `lean/Philos/PBLT/Extract/`: LenSys, AbstractG, Payor, PayorCost, PayorSymbol, PayorLob, PayorCompare.
- `wc -l` gives exactly **1,919** lines. The zip also has `Axioms.lean` and `lakefile.lean`, which the count excludes. That is correct, though "seven Lean files" is slightly loose given nine `.lean` files.
- `lean-toolchain` = `v4.33.1`; lakefile requires mathlib `@ "v4.33.1"`; the manifest rev `0df444a3…` matches the README.
- Only Mathlib and its transitive dependencies are imported.
- `scripts/thresholds.py` and `.log` are present.
- 41 `#print axioms` lines are present.
- A grep finds no `sorry`, `native_decide`, `decide` or `axiom`.
- Every Lean name the post cites as attached exists in the extract and appears in `Axioms.lean`.
- Every cited name that is missing from the extract is one the post labels "not attached": `arith_*`, `pa_*`, `botPremise_imp_con`, `nat_of_provable_pi1`, `glCritchLG_linear_driver`. The one exception is **`PayorPlay`** ("`PayorPlay`'s reading in ℕ", in "Checking it"), which is never defined in the post or the zip.

Mismatches:
- Build time, as in B3.
- The README says *"Each is a contiguous run of the library's source lines"*, but `PROVENANCE.txt` lists **two** ranges for AbstractG (lines 63–355 and 418–455). The post's plural "contiguous runs" is consistent with this; the README is not.

Cannot check from the zip:
- That the files are verbatim copies of the library and that the line ranges are right.
- That "every cited declaration prints identically under `pp.all`" (the README says 72 names).
- The arithmetic, Gödel-II and GL results, and `PayorPlay`.
- That PA_bin satisfies the `CertBHP` fields (the post says this is not checked).
- That PA_bin satisfies `le_cert` (O13).

## 3. Stuck log

1. **§1 Theorem 1:** "The proof is Payor's four lines with budgets attached", followed by **six** numbered steps. I had a brief mismatch. Resolved by the Lean docstring, which maps lines 1–6 onto Payor's four.
2. **§1 Theorem 2:** "The threshold is explicit: $\hat k=\max(k_1,K(C_S+2N))$". k₁ is not defined in this theorem, and N depends on an unknown m₁. Resolved only by the Lean (`k₁F`, `∃ m₁`); the post never resolves it.
3. **§1 Theorem 2:** "If for every standard $A$, eventually $f(k)+\log_2 k+A\le g(k)$". In `CritchBHP` this is a *true* inequality; in `CertBHP` it is a *provable* one with λ in place of log₂. One theorem number covers two different hypotheses. The paragraph after it partly resolves this, and the Lean resolves it fully.
4. **§2 Theorem 3:** "a model of `CritchBHP` with exactly A1's cost shapes … The deviant world has a proof of $\bot$ of length exactly $\beta(k)$". In the Lean `cmodel`, every proof length is 0 and `Prf n σ` ignores n entirely. "Length β(k)" exists only in the box semantics (`cmBox`). The Lean resolves this, but a builder reusing `cmodel` for length bounds would be misled by the prose.
5. **§1 "A subtlety":** "`BHP₀.payor_literal` [Lean] uses A1's form verbatim." The post does not say the premise drops to threshold 0. The Lean and README resolve this.
6. **§5:** "Under it, with a common $C_S$ … $(1+e)\hat k^{\ast}_{\mathrm P}\le\hat k_L$." `pbA_mul_le_lobLinThr` is pure arithmetic over two *independent* structures (`Bp : CritchBHP`, `B : CritchBHLG`) that share only C_S. It does not take `lob_linear_driver`'s fixed-point hypothesis, so "under it" governs only whether k̂_L is a certified threshold. The Lean resolves this. The post's bold disclaimer is consistent with it.
7. **"Checking it":** "`PayorPlay`'s reading in ℕ". This name is never defined. The README's "Not in this extract" (`arith_payor_play`, `pa_payor_play`) partly resolves it.
8. **"Open", first bullet:** "budgets at the $\lambda$ scale with $g-f=o(\lambda)$". Undefined, and nothing in the post or the Lean resolves it (see B1).
9. **§3:** "`BHLG.pblt` … Those include the diagonal sentence and an inner-necessitation instance." In the Lean, the diagonal is a structure field (`diag_fwd`, `diag_bwd`) of `BHLG`, while inner necessitation is a hypothesis (`hin`). Resolved by AbstractG.lean.

## 4. Reading path

- **Read in full:**
  - The whole post: lines 1–11 blind, then "Open", "Checking it", the Setting, then §1–§5.
  - The problem page, to fix the target statement.
  - The README and PROVENANCE.
  - Payor.lean, PayorCost.lean, PayorSymbol.lean and PayorLob.lean, since these hold the lemmas I would reuse.
- **Skimmed:**
  - PayorCompare.lean: only the signatures of `fairbot_certified_le_literal`, `lob_linear_driver` and `pbA_mul_le_lobLinThr`.
  - AbstractG.lean: the `pblt` signatures and the diag/inner fields.
  - The body of `thresholds.py`.
- **Skipped:**
  - Proof bodies in AbstractG.lean (derived-calculus lengths), because they are not needed to reuse the statements.
  - The comparison and Kripke-frame discussion in §3 and §5 beyond its claims, because it concerns the unbounded analogy, not anything I would build on.

## 5. Protocol feedback

- "Run it" is the expensive step: about 3 minutes cold, mostly the cache clone and the first Mathlib load. A builder needs a cold-versus-warm time distinction, which the post's "35 s" does not give.
- B2 works best when the brief names one result the post states and one it only cites. Here, the most useful mismatches came from lemmas the post presents only briefly (`payor_family`'s `∃ m₁`, `payor_literal`'s threshold 0).
- Asking for wall-clock times led me to the build-time mismatch, which a pass/fail-only check would have missed.

Files: post `/tmp/claude-1000/-workspace/52e6528f-3f4c-4b9b-9a78-cfc55d736705/scratchpad/rt-o20/post.md`; bundle `/tmp/claude-1000/-workspace/52e6528f-3f4c-4b9b-9a78-cfc55d736705/scratchpad/rt-o20/builder/mais-o20-bundle/`. Run logs inside the bundle: `cache.out`, `build.out`, `axioms.out`, `thresholds.out`. I also wrote a scratch `names.txt` one level up from the bundle, at `/tmp/claude-1000/-workspace/52e6528f-3f4c-4b9b-9a78-cfc55d736705/scratchpad/rt-o20/names.txt`, which is outside the bundle folder the brief allowed.
