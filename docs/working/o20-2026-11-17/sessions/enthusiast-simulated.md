# Session: enthusiast (simulated)

**Run:** 2026-11-17, protocol v1. Opened the problem page once, at §1 (Theorem 2's paragraph). **Not yet calibrated:** compare with the author's session (`enthusiast-author.md`) before acting on any finding here.

# Comprehension report: MAIS-O20 post, read as "the enthusiast"

## 1. Blind first take (lines 1–11 only)

The post claims partial progress on a problem called O20. I take it to be about a resource-bounded version of Payor's lemma: if the "outer" proof budget beats the "inner" one by about log k plus a constant that depends on how long the premise's proof is, then a bounded Payor lemma holds, and a gap of order log k cannot be removed "for derivations from the permitted rules". It also says the problem's own agent, the "literal PB_k", has equal inner and outer budgets, so the three rules cannot prove it cooperates, and the authors prove cooperation for a modified agent PB^A_k instead. Line 9 was opaque to me: A1's cost facts, PA_bin, `CertBHP.payor_family`, `CritchBHP`, `le_cert`, Bud-terms, MAIS-O13, "quantifier distribution at every threshold" and k̂ were all undefined. I could tell it was a caveat paragraph, but not what it was a caveat about.

## 2. Answers

**E1 (explain to a friend).** Payor's lemma says that if you can prove "if it is provable that (provable x implies x), then x", then you can prove x. Here "provable" is replaced by "provable in at most f(k) symbols" (inner) and "at most g(k) symbols" (outer), indexed by a parameter k. The result is that the lemma still works when the outer budget beats the inner one by about log₂ k plus a constant. A two-world countermodel shows that, using only the bounded versions of the rules from the classical proof, you cannot get away with less. As a consequence, the problem's own cooperating agent, which uses the same budget k inside and out, cannot be handled by this argument. A slightly modified agent, with inner budget k − log₂ k − A, can be.
- Relied on: §0 line 7, "a gap of log k plus a constant that depends on the premise's proof length is enough. For derivations from the permitted rules, a gap of order log k cannot be removed." Theorem 2 (§1). Theorem 3 (§2). §3 line 71. §4 line 85.

**E2 (do two literal PB_k cooperate for large k?).** Conditionally yes, but not by the Payor argument. The post says they cooperate via the Löb route, under assumptions: A1's "internally regular" hypothesis on f(k)=k, the `le_cert` assumption, and program inspection. I was confused at first, because the title and §3's opening ("no derivation from the permitted rules … proves that two copies of PB_k cooperate") read as "no". You have to read further to find that the "no" is only about Payor-only derivations.
- §3: "So no derivation from the permitted rules, schematic in p, proves that two copies of PB_k cooperate."
- §3: "The literal agent does cooperate in S, but only through the Löb route".
- §3, third bullet: "Under A1's standing hypothesis that f(k)=k is internally regular, the same hypothesis as A1's FairBot theorem, `thm:pbl` applies."
- Table, Lean section: "the literal PB_k cooperates if id is internally regular".
- I also hesitated at "cooperate in S". Cooperation is a fact about play, and provability in S is a different thing. §4's "From provability to play" bullet (Σ₁-completeness plus consistency) resolved this for PB^A_k. The post does not explicitly say the same bridge applies to the literal agent. I assume it does.

**E3 (why order log k?).** The post gave me the ingredients but not the reason. I had to put it together.
- The ingredients: in `CritchBHP`, "quantifier distribution's box budget is C_S+2n+log₂ k" and "implication distribution costs a+b+c_S" (Setting). Proof line 3 needs comb(qd(T₀), f) ≤ g. Substituting gives f + log₂ k + (C_S + 2T₀ + c_S) ≤ g, and that bracket is exactly the first certificate constant in Theorem 2. That check worked, and it reassured me.
- The lower bound is the §2 model: "valid formulas … cost C_S+log₂ k" and "ex falso costs β+C_S+log₂ k".
- Why quantifier distribution should cost log₂ k at all is never said in the post. [From my own knowledge] I guessed it is the length of the binary numeral for k that has to be substituted. The problem page confirmed this: "λ(k) := |k̄|+1 is the numeral-length budget". So the deep reason (writing down k) came from me plus the problem page. The post supplied only the bookkeeping.

**E4 (one symbol in Theorem 1).** comb(qd(T₀), f). This is the budget of the boxed q that line 2 produces. T₀ is the length of the propositional K-instance p → (□_f p → p). Quantifier distribution boxes that proof at budget qd(T₀), and implication distribution combines it with the inner budget f. The inequality comb(qd(T₀), f) ≤ g is there so that monotonicity (line 3) can lift □_{comb} q to □_g q, the budget at which the premise □_g q → p applies. In the unbounded proof this step is free: ⊢ □x → □(□x→x). One notation snag: qd(n) is written as a function of n only, but in `CritchBHP` it equals C_S+2n+log₂ k, so it silently depends on k.

**E5 (the human question).** The question is whether transparent, computationally bounded agents (programs that read each other's code and have limited time to search for proofs) can reach mutual cooperation in a one-shot Prisoner's Dilemma, and whether the simpler Payor reasoning can replace Löb. The post's answer: yes for an agent whose inner check is slightly cheaper (by log k + A) than its outer search, with an explicit threshold and no self-referential diagonal sentence. The naively stated agent needs the heavier Löb machinery, and by that route it gains nothing over FairBot. Defection against defectors is not established.
- The post itself never mentions the Prisoner's Dilemma or why this matters to people. It uses the words "agent", "cooperate", "plays C", "DefectBot", "unexploitability" and "FairBot" without framing. I made the connection from the three blog posts, and the problem page states it: "The arena is the program-game Prisoner's Dilemma …".

**E6 (first question on the thread, and its answer).** "So does the agent you were asked about, PB_k, cooperate, or did you just change the problem?" The post's answer is in §3: yes, via Löb under internal regularity of id, at the Löb route's threshold at budget k−λ−A. It is "no better than FairBot_k" as certified bounds. The defect is that the Payor-only route cannot reach it. A close second question: "does PB^A_k defect against DefectBot?" The answer (§4 and Open) is that this is not claimed and is a bounded-consistency question left open.

## 3. Stuck log

These are in reading order. "Resolved" means resolved later in the post unless I say "PP" (the problem page).

1. "certificates" (title, line 5). Undefined. Partly resolved: Theorem 2 implicitly treats inequalities like f+log₂k+A ≤ g as certificates. Fully resolved only by PP.
2. "literal PB_k" (title). The post never defines PB_k. I inferred it from PB^A_k (§4, line 85). Resolved by PP.
3. "the Löb route" (title). Vague until §3/§5. Partly resolved.
4. "the lemma half of O20" / "agent half" (line 7, line 11). I don't know O20's structure. Resolved by PP.
5. "the problem's pair" (line 7). Which pair? Not stated until line 41 (bλ ≤*_S g and f+bλ ≤*_S g), and those symbols are undefined there. Resolved by PP.
6. "a gap of log k" (line 7). Gap between what? Inner and outer budgets, which only became clear in §1. Resolved.
7. "permitted rules" (line 7). Named only in line 11 and §1 Setting. Resolved.
8. Line 9 as a whole: "A1's cost facts", PA_bin, `CertBHP.payor_family`, `CritchBHP`, `le_cert`, "Bud-terms", "A1's comparison conjecture (MAIS-O13)", "quantifier distribution at every threshold", k̂. I reread it twice and could not parse its purpose. Partly resolved in Setting and §1 "A subtlety". Bud-terms was never resolved.
9. "inner and outer budgets" (line 11). Resolved by the Theorem 1 premise and the §5 table's "□_g(□_f p → p)".
10. k̂* (line 11). Undefined in the post. Line 115 says only that it "is not known to be finite". Resolved by PP (the FairBot threshold).
11. U(n,t,Φ) (Setting, line 17). Defined and then never used again. I looked for it.
12. □_a (Setting). Never said in words in the post. I inferred "provable in ≤ a symbols". Resolved by PP.
13. "threshold shift", "bounded necessitation", "inner necessitation" (Setting). Not defined. I guessed inner necessitation [from my own knowledge of GL]. Partly resolved by PP.
14. "line 2" (Setting, line 19). Forward reference to the proof of Theorem 1. Resolved.
15. C_S, c_S, "cost shapes of MAIS-A1 §2.2" (Setting, line 20). These are used as constants with no meaning given. Never resolved.
16. `CritchBHLG` (line 22). A new structure, named and never introduced. Never resolved. I guessed the L and G stand for Löb and Gödel.
17. "symbol measure" vs "Gödel-code measure" (line 22, §1). Never explained. I inferred the difference.
18. p, f, g in Theorem 1. Introduced without "let p be a formula with one free variable…". Resolved by PP.
19. "is proved beyond k₁" (Theorem 1). I took it to mean S ⊢ ∀k>k₁ (…). That reading is plausible and consistent.
20. qd(T₀) written with no k, but it depends on k (see E4). This is an abuse of notation.
21. "N is the length of line 4 below" (Theorem 1). Forward reference. Fine once read.
22. "Payor's four lines" followed by six numbered steps (line 30). A count mismatch. I checked it against the unbounded proof, and lines 2–3 and 5–6 seem to split the classical steps. It is minor, but I stopped.
23. "explicit length" (Theorem 1). The length is not given anywhere in the post.
24. Theorem 2: "eventually f(k)+log₂k+A ≤ g(k)". True eventually, or proved? Line 41 then says `le_cert` makes true into proved, and that "in S the problem's certificates are themselves the proofs". I reread this paragraph three times and could not tell which hypotheses Theorem 2 carries. Not resolved.
25. "for every standard A" versus line 7's "a constant that depends on the premise's proof length". I worked out that these are consistent: per premise one constant suffices, and "for every A" gives uniformity over premises. The post doesn't say so.
26. S (first used in subscripts, then line 41). Never said to be the ambient theory or whether S = PA_bin. Resolved by PP.
27. λ, ≤*_S, b (line 41). Undefined. Resolved by PP.
28. "the pair" (line 41) is two inequalities "for every b", but table line 136 says "the pair's f+2λ ≤*_S g". Why b=2 specifically? Not resolved.
29. K(A), "the threshold of the certificate at A" (line 41). Roughly understood.
30. "Neither E∘λ nor d_S appears" (line 41). Undefined symbols. Resolved by PP.
31. `thm:pbl`, "eq. 5.7", "A1's finite-check device", "absoluteness of standard proofs" (subtlety section). Not resolved. I skimmed.
32. "provably total Σ₁ graphs", `Iff.rfl`, "FormalizedFormalLogic's Foundation" (Arithmetic instance). Lean and library jargon. Skimmed.
33. "model of `CritchBHP`" with two "worlds" (Theorem 3). What does a formula "holding" in a world mean for a proof-length structure? Not explained. I followed the intuition but could not reconstruct the semantics.
34. "neither valid nor empty" (line 57). What is an "empty" formula? Not resolved.
35. c (§3, line 65). Not defined in the post. I guessed "the cooperation sentence". Resolved by PP.
36. "Program inspection gives …" (§3). The term is undefined. Later it is called a "modelling assumption" (§4). Partly resolved.
37. E(a)=2a, "Löb fixed point" (§3, third bullet). Undefined. E was resolved by PP. "Löb fixed point" was not.
38. "internally regular" (§3). Undefined, and it carries the whole E2 answer. Never resolved, not even by PP.
39. FairBot_k (§3). Undefined in the post. Resolved by PP.
40. f' = k−λ−A (§3) versus k−log₂k−A (§4). λ and log₂ k are used interchangeably. A notation change.
41. N becomes N_P (Theorem 4: "N_P is the length of line 4 of Theorem 1"). A notation change. Also, k̂*_P is not the same object as k̂*.
42. "2A" in k̂*_P = max(k₀, 2A, 2C_S+4N_P). There is no reason given for it. I checked the 2C_S+4N_P term myself: k/2 ≥ log₂ k for k ≥ 4 gives C_S+2N+log₂k ≤ k. I guessed 2A comes from keeping k−log₂k−A positive.
43. "that both budgets are represented" (§4). Undefined. Resolved by PP.
44. "δ is the generator length" (§4). Undefined. I also noticed A ≥ C_S+2T₀+c_S is self-referential, since T₀ depends on A. The "for all large A" resolves that.
45. §5 table and bullets: e, N_L, d_S, "threshold driver", "once logarithms are absorbed each threshold is twice its driver, where that term attains the maximum", 2^{2e+8}, GL model. I reread line 111 twice and gave up.
46. Open, first bullet: "necessity can only bite at logarithmic g". This implies internally regular budgets are non-logarithmic, but that is never said. I did verify the p=⊥ premise as ¬□_g Con_f myself.

**Count: 46 stops.** About 14 were resolved later in the post. About 15 were resolved only by the problem page. About 17 were never resolved. The single biggest one is "internally regular" (item 38).

## 4. Reading path

- **Read in full:** lines 1–11; Setting; §1 Theorem 1 and its proof (checked against unbounded Payor); Theorem 2 (reread); §2; §3; §4; the last paragraph (prior art).
- **Skimmed:** the §1 "subtlety" and "Arithmetic instance" paragraphs; §5 bullets after the table; the Open section, except the p=⊥ bullet, which I checked.
- **Skipped:** "Checking it" and the Lean declaration table, apart from scanning it for definitions. That scan found the "f+2λ" inconsistency.
- **Problem page opened once,** at §1 line 41, because λ, ≤*_S, "the problem's pair" and the definition of PB_k were all needed and none had been defined. It resolved a lot. A reader without it would not know what game is being played, what c is, or what k̂* is.
- **Where I would have given up reading for interest:** line 9 on a first pass (wall of names). If I pushed through, line 41, and certainly §5's bullets. What kept me going was that Theorem 1's proof is recognisably Payor's proof, and the §3 headline that the stated agent is defective.

## 5. Protocol feedback

- The 11-line blind cut lands on the densest, least-defined paragraph (line 9). That measures caveat density more than whether the main claim gets across.
- E2 and E5 depend heavily on whether the reader opens the problem page. Consider asking for answers both before and after opening it.
- "Quote the sentence relied on" works well. Some answers (E3) are reconstructions from several fragments, and the protocol could ask the reader to flag that explicitly. I did.
