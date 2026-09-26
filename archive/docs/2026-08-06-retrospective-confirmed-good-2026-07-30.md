# Retrospective: Confirmed-Good rules applied to all archived eval cells

Goal: resolve open question #4 of `docs/thoughts/code-review-evaluation-state.md` §3 — does the Confirmed-Good-vs-fact-check cross-check actually catch the misses? — by applying the four shipped rules (`skills/code-review/SKILL.md` § "Confirmed Good is a claim, not an output") retrospectively to every ✅ row in every archived eval cell, not just the sampled two.
Project state: exp/cross-model-openrouter-sweep, standalone, not blocked.
Task status: complete.

## 1. Cell inventory

Archived cells live at `/home/node/cr-eval/runs/` (referenced from
`docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md` §231 "Artifacts at
`/home/node/cr-eval/runs/nd2-{opus,fable}-r2/`"). Exactly **11 cells** exist, matching
decision 25's count. `runs/cross-model/` and `runs/dd-cross-model-2026-07-30/` in-repo hold
only `findings.jsonl` / single-model reports — no rubrics, not cells.

Every cell contains both a run-written rubric with a `## ✅ Confirmed Good` section and a
same-run fact-check report → **11/11 pairable, 0 UNPAIRABLE**. Because worktrees carry
stale in-tree rubrics (Trap 1, state doc §5.4), the run's own files were selected by
write-timestamp (worktree checkout files are all `11:30:55`; run outputs are minutes-later)
and confirmed by content (`Reviewed: 2026-07-30`, matching commit).

| Cell | Rubric (run-written) | Fact-check (run-written) | ✅ rows |
|---|---|---|---|
| md1-fable-r1 | `code-review-rubric.md` | `code-fact-check-report.md` | 8 |
| md1-opus-r1 | `code-review-rubric.md` | `code-fact-check-report.md` | 12 |
| md1-sonnet-r1 | `code-review-rubric-2026-07-30-commit-range-d86d2dc-d90d6bb.md` | `code-fact-check-report.md` | 7 |
| nd2-fable-r1 | `code-review-rubric.md` | `code-fact-check-report-2026-07-30.md` | 5 |
| nd2-fable-r2 | `code-review-rubric.md` | `code-fact-check-report-2026-07-30.md` | 4 |
| nd2-opus-r1 | `code-review-rubric.md` | `code-fact-check-report.md` | 8 |
| nd2-opus-r2 | `code-review-rubric.md` | `code-fact-check-report.md` | 10 |
| nd2-sonnet-r1 | `code-review-rubric.md` | `code-fact-check-report.md` | 7 |
| nd3-fable-r1 | `code-review-rubric.md` | `code-fact-check-report.md` | 6 |
| nd3-opus-r1 | `code-review-rubric.md` | `code-fact-check-report.md` | 11 |
| nd3-sonnet-r1 | `code-review-rubric-2026-07-30-commit-319f229.md` | `code-fact-check-report.md` | 12 |

**Total ✅ Confirmed Good rows: 90 — not 82.** Decision 25 (log row 25) states "0 of 82
Confirmed Good rows across all 11 archived eval cells carry a mechanically checkable
citation." The per-cell recount above (8+12+7+5+4+8+10+7+6+11+12) gives 90. The "0 carry a
mechanically checkable citation" half **holds at n=90**: no row has an `Evidence` cell or a
`path:line` citation (the old rubric format had only Item/Verdict/Source/Legibility-target
columns). Three rows reference their enumeration in prose ("verified by grep", "verified by
import grep both directions", fact-check Claim 14's `Math.random` grep) but without
pattern+scope, so none is mechanically checkable. The 82 figure appears to be a miscount.

Classification key (counterfactual: what would the shipped rules have done to this row):
PASS = specific claim, groundable in same-run artifacts, no contradicting observation.
EVIDENCE-FAIL = rule 2, ungroundable anywhere → deleted. ENUM-FAIL = rule 3, universally
quantified with **no enumeration executed anywhere in the run** → reword or drop.
CROSS-CHECK-HIT = rule 4, a same-run fact-check observation makes the claim as worded
false → 🟡 Contested. "UQ" flags a universally quantified row whose enumeration *does*
exist in same-run artifacts but is not cited in-row — survives rule 3 only after citing it
(soft fail, not counted as ENUM-FAIL).

## 2. Per-row classification

### md1-fable-r1 (8 rows)

| # | Row (abridged) | Class | Note |
|---|---|---|---|
| 1 | No `dangerouslySetInnerHTML`, no `rehype-raw` anywhere (verified by grep) | PASS (UQ) | Enumeration named in-row; grep exists in fact-check. No pattern/scope cited. |
| 2 | `connect-src 'self'` is accurate — Anthropic and OpenRouter calls are all server-side | **CROSS-CHECK-HIT** | The known fable miss. Same report, line 109 (inside Claim 6, marked Verified): "client fetches are all relative `/api/...` paths **or `data:` URLs in `app/lib/utils/exportGraph.ts:24,37`**" — a `data:` fetch is exactly what `connect-src 'self'` blocks. Rule 3 also fails it (implicit "all calls" with the disconfirming instance in the enumeration itself). |
| 3 | Gold-standard directive shape (nonce + `'strict-dynamic'` …); unspoofable `x-nonce` overwrite; **clean nonce lifecycle** | **CROSS-CHECK-HIT** (new) | Same report, Claim 2, verdict **Incorrect**: "The forwarded request carries only `x-nonce`, which Next.js does not recognize. … it never sees the nonce, does not tag its bootstrap scripts, and under `script-src … 'nonce-…' 'strict-dynamic'` … those un-nonced scripts would be blocked." The same rubric files this as 🔴 R1 ("CSP nonce is never delivered where Next.js reads it") — a ✅ "clean nonce lifecycle" row coexisting with it cannot survive rule 4's "if this observation is true, is the ✅ claim still true?". Not recorded in decision 25. |
| 4 | Canonical matcher hygiene; 16 LLM API routes take zero proxy overhead; proxy synchronous, I/O-free | PASS | Specific, groundable (`proxy.ts` matcher). |
| 5 | `proxy`/`config` export names correctly shaped for `next@16.2.4`; `RootLayout` sync→async safe | PASS | |
| 6 | `proxy.ts` single-responsibility: framework-only imports, zero domain leakage, clean dependency direction | PASS (UQ) | "zero domain leakage" needs the import enumeration; trivially available (single small file). |
| 7 | d90d6bb refactor claims verified by diff | PASS | Matches fact-check Claim 17-equivalent. |
| 8 | Static count of test declarations is exactly 221 (pass status unverifiable) | PASS | Well-scoped; the model rule-3 rewording. |

### md1-opus-r1 (12 rows)

| # | Row (abridged) | Class | Note |
|---|---|---|---|
| 1 | Nonce entropy sound, no CSP header-injection path (base64-of-UUID alphabet argument) | PASS | Universal claim carried by a complete argument, not an instance. |
| 2 | `set` (not `append`) on `x-nonce` overwrites client-supplied values | PASS | |
| 3 | `frame-ancestors`/`base-uri`/`object-src` correct; `img-src` scoped without exfiltration channel | PASS | Does not cover `connect-src` — the defect was filed 🔴 R2 in this rubric. |
| 4 | XSS posture clean — no `dangerouslySetInnerHTML` anywhere, `rehype-raw` not a dependency | PASS (UQ) | Grep exists in same-run fact-check. |
| 5 | Middleware→Proxy naming/shape consistent with Next 16 | PASS | |
| 6 | Matcher exclusions correct; API routes pay nothing | PASS | |
| 7 | `buildCsp` flat array + join; no regex/loops/I/O/locks/shared state | PASS (UQ) | Enumerable in one screen of code. |
| 8 | Import direction one-way, nothing in `app/` imports it, no cycles | PASS (UQ) | Grep-backed in architecture review. |
| 9 | Naming conventions correct (`buildCsp`, Title-Case header, per-line directives) | PASS | |
| 10 | `style-src 'unsafe-inline'` named as deliberate tradeoff | PASS | |
| 11 | d90d6bb "no behavior change" verified | PASS | |
| 12 | Anthropic/OpenRouter calls genuinely server-to-server — `connect-src` rationale correct **for those two providers** | PASS | The rule-3-compliant narrowing done voluntarily: same fact (server-side providers) as fable row 2, worded as the instance actually checked, while the same report's Claim 8 (**Incorrect**) carries the `exportGraph` defect and the rubric files it 🔴 R2. This is what surviving looks like. |

### md1-sonnet-r1 (7 rows)

| # | Row (abridged) | Class | Note |
|---|---|---|---|
| 1 | CSP directive set (`frame-ancestors 'none'`, `object-src 'none'`, `base-uri 'self'`, `connect-src 'self'`) is **sound with no unintended carve-outs** | **ENUM-FAIL** (hard) | The known sonnet miss. Universally quantified; no enumeration of client fetch destinations was executed anywhere in the run: case-insensitive grep for `exportGraph`/`data:`-fetch across all 8 run artifacts returns nothing (the only `connect-src` mentions are the security review's assertion at `security-review.md:88` and this row). Rule 4 has nothing to fire on — confirmed below. |
| 2 | `buildCsp` directives byte-identical across all 3 commits | PASS | Fact-check Claim 4, Verified. |
| 3 | `config.matcher` exclusions match comment exactly | PASS | Fact-check Claim 5, Verified. |
| 4 | Nonce freshly generated per request, no cross-request reuse | PASS | Not contradicted by Claim 1 (Incorrect — nonce *forwarding* is dead plumbing; generation is real). |
| 5 | `buildCsp` naming matches helper convention | PASS | |
| 6 | Dependency direction sound; `buildCsp` small/pure | PASS | |
| 7 | Per-request work fixed-cost O(1) | PASS | |

### nd2-fable-r1 (5 rows)

| # | Row (abridged) | Class | Note |
|---|---|---|---|
| 1 | Pure-FSM/world boundary holds; `behavior.ts` imports only `Phenotype` type | PASS | Matches fact-check evidence. |
| 2 | **All** tuning constants match documented values (0.6/1.5s/3.0s/30s/6s, ×1.5/×0.5); rarity ordering as documented | PASS (UQ, tension) | Cites "Fact-check (19 Verified claims)" as its enumeration. Same report's Claim 9 is **Incorrect** — but about the WARY comment's *rationale* ("Scaled down to the sim's faster tempo" is false; "30.0 s equals the original ~30 s"), not the value: values do match. Rule 4's "is the ✅ claim still true?" phrasing spares it; a naive topic-overlap matcher would wrongly contest it. False-positive-risk exemplar. |
| 3 | Test-count 93→108 verified statically | PASS | |
| 4 | Hot-path additions O(1), no new per-tick allocations | PASS | |
| 5 | Exhaustive `Record<BehaviorState,…>` maps; determinism directly tested | PASS | |

### nd2-fable-r2 (4 rows)

| # | Row (abridged) | Class | Note |
|---|---|---|---|
| 1 | FSM/world boundary holds under stateful-timer pressure; zero new imports | PASS | Claim 4 (Incorrect, the wanderTimer/reproCooldown mirror comment) does not touch the mutation-fencing claim — the report itself calls that half accurate. |
| 2 | All constant values … and every `initial_concept.md` reference verified exactly (19 Verified claims) | PASS (UQ, tension) | Same report's Claim 6 finds the WARY comment's "Scaled down" qualifier false while confirming "The reference is real — initial_concept.md:98". As worded ("reference verified") it survives; borderline. |
| 3 | Hot-path O(1)/creature, allocation-free | PASS | |
| 4 | Record maps compiler-policed; `CatalogCategory` template-literal absorbed 12→18 | PASS | |

### nd2-opus-r1 (8 rows)

| # | Row (abridged) | Class | Note |
|---|---|---|---|
| 1 | FSM-reads-context invariant preserved; fields threaded via `buildContext` | PASS | The report's Claim 7 (Incorrect) kills the *mirror analogy*, not the threading itself — and this row does not repeat the analogy. |
| 2 | Dependency direction preserved, no cycles | PASS | |
| 3 | Tier ordering, **all** new constant values, `TOTAL_CATEGORIES`, test count check out statically | PASS (UQ, tension) | Claim 9 (Incorrect, WARY "scaled down" rationale) adjacent but values do match. Same false-positive-risk shape as nd2-fable-r1 row 2. |
| 4 | `moodTimer > 0 ? mood : "NEUTRAL"` fail-safe; stealth clamped; snapshot independent | PASS | |
| 5 | No new loop/scan/allocation in hot path; SINGING cheaper than WANDER | PASS (UQ) | |
| 6 | Naming consistent; `Record<BehaviorState,_>` forced the update | PASS | |
| 7 | No security escalation: no secrets, auth surface, injection sink, TLS path, or crypto keys in the diff | PASS (UQ) | Universal over the diff; the security review's scan is the enumeration, uncited in-row. |
| 8 | Constants centralized; commit well-tested | PASS (tension) | Claim 20 (Incorrect) shows one new test's *comment* miscomputes the threshold (2.1, not 1.6) while the test's outcome is unaffected. "Well-tested" as worded survives; would deserve a caveat, not revocation. |

### nd2-opus-r2 (10 rows)

| # | Row (abridged) | Class | Note |
|---|---|---|---|
| 1 | FSM invariant holds: one import, `decideNextState` pure | PASS | Cites fact-check Claims 1/3/11. |
| 2 | Timer/mood ownership correct; `onEnterState` inside transition guard | PASS | Cites Claim 18. |
| 3 | Determinism: no `Math.random`/`Date.now` anywhere in `packages/sim-core/src`, no new rng draws | PASS (UQ, cited) | Cites Claim 14, which ran the grep — in-row enumeration reference. |
| 4 | `snapshot()` deep-frozen, reference-independent | PASS | |
| 5 | No perf regression: no new O(n²), no new per-tick allocation | PASS (UQ) | |
| 6 | Every constant quoted **in the commit message** matches its declaration; formula docstring term-for-term | PASS | Scoped to the commit message, which the report's Claim 7 (Incorrect on the *comment's* "scaled down") explicitly exempts: "The commit message consistently says WARY_MOOD_DURATION (30s) — that part is accurate" (r1 wording). Correctly narrowed → no hit. |
| 7 | Rarity ordering right; `CatalogCategory` auto-extends; `TOTAL_CATEGORIES` derived | PASS | Cites Claims 13/16/24. |
| 8 | API extension discipline (`Mood` union, `MOOD_MULTIPLIER` mirror, appended `CATALOG_STATES`) | PASS | |
| 9 | Test-count 93→108 checks out statically, no `it.each` skew | PASS | Cites Claim 21. |
| 10 | No security vulnerabilities: no network I/O, auth, persistence, deserialization, crypto, or manifest change | PASS (UQ) | |

### nd2-sonnet-r1 (7 rows)

| # | Row (abridged) | Class | Note |
|---|---|---|---|
| 1 | FSM invariant: one import, zero coupling | PASS | |
| 2 | Timer ownership/ordering, no read-after-write hazard | PASS | |
| 3 | Extension pattern followed correctly and completely for both new states | PASS (UQ) | Compiler-enforced Record maps are the de-facto enumeration. |
| 4 | Naming matches conventions | PASS | |
| 5 | No manifest/lockfile changes; no auth/crypto/network/serialization surface in this diff | PASS (UQ) | |
| 6 | `World.step` stays O(N); no hidden per-tick multiplication | PASS | |
| 7 | All specific constant values, `TOTAL_CATEGORIES`, 93→108 | PASS (UQ) | This report (15 claims, 0 Incorrect) never examined the WARY "scaled down" comment at all — the sonnet pattern again: nothing observed, so nothing for rule 4 to fire on, and the row survives even though sibling runs' reports found an Incorrect in exactly this cluster. |

### nd3-fable-r1 (6 rows)

| # | Row | Class | Note |
|---|---|---|---|
| 1 | 19 of 21 commit/doc claims Verified (list) | PASS | Consistent with report (21 claims; 1 Unverifiable + 1 Mostly accurate). |
| 2 | Fail-closed version check; Map-keyed catalog; pure-data format | PASS | |
| 3 | Collections capped at 18; copy-on-write; zero-allocation no-change returns | PASS | |
| 4 | Conventions kept (`Serialized*`, empty-constructor symmetry, purity) | PASS | |
| 5 | Clean inward dependency direction, no cycles | PASS (UQ) | |
| 6 | 17 new tests pin the stated invariants | PASS | |

### nd3-opus-r1 (11 rows)

All 11 PASS. Rows are specific and fact-check-corroborated (Claims 7/18/20 cited in-row);
row 11's "18 of 21 fact-checked claims Verified" is arithmetically consistent with the
report (21 claims = 18 Verified + 1 Incorrect + 2 Mostly accurate). The report's one
**Incorrect** (Claim 14, "coverage … never dwarfs quality", `session.ts:92`) has **no**
corresponding ✅ row — the rubric did not confirm the claim its fact-check refuted. No hits.

### nd3-sonnet-r1 (12 rows)

All 12 PASS. Notables: row 9 ("dependency direction … **verified by import grep both
directions**") is the only row in the corpus that names its enumeration with direction and
method — closest existing row to the shipped rule-3 format; row 12 ("barrel export matches
the internal surface exactly") is UQ with the enumeration implicit in the api-consistency
review. Report has 0 Incorrect; nothing to cross-check against.

## 3. Tallies

| Classification | Count | Rows |
|---|---|---|
| PASS | 87 | everything not listed below |
| CROSS-CHECK-HIT (rule 4) | **2** | md1-fable rows 2 and 3 — both in the same cell, both contradicted by the same fact-check report |
| ENUM-FAIL, hard (rule 3) | **1** | md1-sonnet row 1 |
| EVIDENCE-FAIL (rule 2) | **0** | no row cites a location that fails to resolve; conversely **0/90** carry a mechanically checkable citation at all (decision 25's datum, corrected from 82) |
| UNPAIRABLE | **0** | all 11 cells have a same-run fact-check report |

Sub-flags within PASS:

- **UQ (universally quantified, enumeration exists in same-run artifacts but is not cited
  in-row): ~14 rows** (md1-fable 1, 6; md1-opus 4, 7, 8; nd2-opus-r1 5, 7; nd2-opus-r2 5,
  10; nd2-sonnet 3, 5, 7; nd3-fable 5; nd3-sonnet 12). Under the shipped rule 3 these must
  cite their enumeration or be reworded; retrospectively all would survive after citation,
  so they are compliance work, not latent misses — with the caveat that nd2-sonnet row 7
  shows a UQ row surviving because its fact-check was thin, which is the sonnet-class gap
  in miniature.
- **Tension (false-positive risk for rule 4): 4 rows** (nd2-fable-r1 2; nd2-fable-r2 2;
  nd2-opus-r1 3, 8). Each sits adjacent to an **Incorrect** verdict about a *comment's
  rationale* (WARY "scaled down"; a test comment's arithmetic) while the ✅ claim as worded
  (values match; commit is well-tested) remains true. Rule 4's exact question — "if this is
  true, is the ✅ claim still true?" — spares all four; a naive same-file/same-symbol
  overlap trigger would wrongly contest them. The rule's phrasing is load-bearing.

**Per-rule catch counts (retrospective):** rule 1/2 (Evidence): 0 catches, 0 false kills —
its value is prophylactic, and the 0/90-citation datum shows it changes every row's form.
Rule 3 (enumeration): 1 hard catch (the sonnet miss, weakly — forces rewording, does not
force observation), ~14 rewordings, 0 wrong kills. Rule 4 (cross-check): 2 catches
(including 1 previously unrecorded), 0 wrong kills *if applied as phrased*, 4 near-misses
that a sloppier matcher would wrongly kill.

## 4. The two known misses, re-derived from artifacts

**fable MD1 — decision 25 confirmed, and understated.** The ✅ row (`code-review-rubric.md:71`)
reads "`connect-src 'self'` is accurate — Anthropic and OpenRouter calls are all
server-side". The same run's `code-fact-check-report.md:109`, inside Claim 6 (**Verified**),
records: "client fetches are all relative `/api/...` paths or `data:` URLs in
`app/lib/utils/exportGraph.ts:24,37`" — the disconfirming observation, verbatim, buried
under a Verified claim, exactly the case rule 4's "including observations recorded … under
a claim the fact-check itself marked Verified" clause exists for. The cross-check fires.
The enumeration rule also fires (the row's implicit "all client calls" enumeration contains
the counterexample). *Understated:* the same cell has a **second** hit decision 25 did not
record — row 3's "clean nonce lifecycle" contradicted by the same report's Claim 2
(**Incorrect**: the nonce "is never placed on the request `Content-Security-Policy` header
where Next.js documents reading it") and by the rubric's own 🔴 R1 two sections up.

**sonnet MD1 — decision 25 confirmed, and strengthened.** The ✅ row
(`code-review-rubric-2026-07-30-commit-range-d86d2dc-d90d6bb.md:54`) reads "CSP directive
set … is sound with no unintended carve-outs" (Source: Security review; the security
review's basis is `security-review.md:88`: "`connect-src 'self'` is consistent with the
stated server-to-server API architecture"). Decision 25 said the *fact-check* contains no
observation about `connect-src`/`data:`/`exportGraph`; this retrospective checked **all
eight** of the run's artifacts case-insensitively — none contains any `exportGraph` or
`data:`-fetch observation. So not only does rule 4 as shipped (fact-check-scoped) miss it;
**widening the cross-check to every critic report in the run would still miss it.** Only
rule 3 touches it, and only weakly: "sound with no unintended carve-outs" must either cite
an enumeration of client fetch destinations (which surfaces the defect) or be reworded to
the narrow claim actually checked (which withdraws the false assurance but leaves the
defect unfound). Making the run observe the fact is §1.1's k≥3 / §5.0's second-vendor
territory, exactly as decision 25 scoped.

**Contrast row:** md1-opus row 12 shows the compliant behavior occurring naturally — same
underlying fact narrowed to "correct for those two providers", with the defect filed 🔴 R2.
The rules formalize what the one non-missing tier already did.

## 5. What this changes

Open question #4 should be **closed**, upgraded from decision 25's two-cell sample to the
full corpus. Headline: **yes, the cross-check catches every miss for which a same-run
fact-check observation exists — 2 of 2 such rows, one of them previously unrecorded — and
it cannot catch the observation-free class, of which the corpus contains exactly 1
(md1-sonnet).** False-positive risk is real but bounded and entirely dependent on rule 4's
"is the ✅ claim still true?" phrasing (4 near-miss rows); the phrasing should be treated
as load-bearing and preserved verbatim in any future edit. Two bookkeeping corrections:
the Confirmed Good row count is 90, not 82; and the fable cell contains a second
cross-check hit ("clean nonce lifecycle" vs fact-check Claim 2).

Suggested one-line status for state-doc §3 row 4:

> **Closed (full retrospective, `docs/working/retrospective-confirmed-good-2026-07-30.md`):
> 90 rows / 11 cells — rule 4 catches 2/2 observation-backed misses (fable MD1 ×2, one new),
> 0 wrong kills; the 1 observation-free miss (sonnet MD1) is reachable only by rule 3's
> rewording, closing it needs §1.1. Count corrected 82→90.**
