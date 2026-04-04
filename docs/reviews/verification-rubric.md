# Draft Verification Rubric

**Draft:** Church-Turing Antithesis | **Checked:** 2026-03-27 | **Status: 🔴 DOES NOT PASS** — 2 red item(s) unresolved

---

## 🔴 Must Fix

Factual errors identified by fact-check. Draft cannot pass verification with any red items unresolved.

| # | Claim in draft | Issue | Status |
|---|---|---|---|
| R1 | "The Church-Turing Thesis is a foundational theorem in computer science" / "the theorem states that..." | The Church-Turing Thesis is not a theorem — it is an unproven thesis/conjecture. Called "theorem" twice. The distinction is fundamental to the claim's epistemic status. | 🔴 Unresolved |
| R2 | "the theorem states that the overhead cost in computing steps of simulating a different computational substrate is at worst polynomial" | This polynomial overhead claim belongs to the *Extended* Church-Turing Thesis (Strong CT Thesis / Invariance Thesis), a separate and distinct conjecture. The original CT Thesis makes no efficiency claims. | 🔴 Unresolved |

---

## 🟡 Must Address

Imprecise/unverified claims, plus structural issues flagged by multiple critics (high-signal). Each must be fixed or acknowledged by author with a note explaining why it stands.

| # | Item | Type | Status | Author note |
|---|---|---|---|---|
| A1 | O(S * log(S)) space bound not matched to any standard result. The Invariance Thesis claims the stronger O(S) bound. | Unverified claim | 🟡 Open | — |
| A2 | Connection between CT Thesis and "unreasonable effectiveness of mathematics" is author's original interpretation, not a standard view. Should be flagged as personal interpretation. | Unverified claim | 🟡 Open | — |
| A3 | Draft conflates description-length complexity (expressiveness/comprehensibility) with computational complexity (step count). Game of Life example is about expressiveness, but the conjecture targets computational cost. Both fact-checker and critic flag this. | Structural (fact-check + critic) | 🟡 Open | — |
| A4 | No mention of quantum computation, which is the primary challenge to the Extended CT Thesis the essay engages with. | Structural (critic) | 🟡 Open | — |
| A5 | "Substrate" used loosely — sometimes a model of computation, sometimes something physical. Conjecture's meaningfulness depends on crisper definition. | Structural (critic) | 🟡 Open | — |

---

## 🟢 Consider

Ideas from one critic or tensions between critics. Not required to pass. For the author's consideration only.

| # | Idea | Source |
|---|---|---|
| C1 | The essay undersells its own motivating observation — market evidence for substrate-specific advantages (GPUs, TPUs, ASICs, DSLs) is strong and could be cited as empirical motivation. | Cowen critique |
| C2 | The philosophical coda is the part the author most cares about but is least supported by the technical content. Either develop the connection or frame explicitly as personal reflection. | Cowen critique |
| C3 | The false modesty ("I don't take the idea too seriously") is contradicted by the act of naming the conjecture and writing the essay. Own the speculation. | Cowen critique |
| C4 | Musical transcription analogy (Paganini Caprices as "native violin music") structurally parallels the conjecture and suggests a framing: substrates should be general-purpose instruments, not player pianos. | Cowen critique |
| C5 | Existing literature on simulation overhead, relationships between computational models, and Kolmogorov complexity may contain relevant precedents. Even a brief gesture toward this literature would strengthen positioning. | Cowen critique |
| C6 | The market for specialized hardware supports the intuition at the level of constant factors and parallelism, but not at the level of asymptotic complexity — which is what the conjecture targets. This gap is worth acknowledging. | Cowen critique |

---

## Verified ✅

Claims confirmed accurate by the fact-check. No action needed.

| Claim | Verdict |
|---|---|
| "[The CT Thesis] says, effectively, any computer can simulate any other computer" | ✅ Mostly Accurate (reasonable informal gloss; elides computability vs. efficiency distinction) |
| "the potentially immense cost of O(t²) slowdowns on LLM training runs from simulating RAM via classical Turing machine" | ✅ Mostly Accurate (correct under logarithmic cost model; Cook & Reckhow 1973) |
| "Creating theoretical lower bounds on the computational complexity of an algorithm is harder than proving upper bounds" | ✅ Mostly Accurate (widely recognized in complexity theory) |

---

To pass verification: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
