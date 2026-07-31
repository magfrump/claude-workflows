# Code Review Rubric — exp/cross-model-openrouter-sweep (2026-07-31)

**Commit:** 62594fb
**Reviewed:** 2026-07-31
**Scope:** `git diff main...HEAD` (34 files, +7007/−287; `runs/` + pre-existing `docs/reviews/` treated as immutable evidence)
**Pipeline:** Stage 1 k=3 fact-check (rich shared brief, step 3b — first run under the amended contract), merged most-severe-wins (agreement 20/26 ≈ 0.77); Stage 2: security, api-consistency + contextual test-strategy, tech-debt-triage (performance downgraded at Stage 1.5 — no perf-domain evidence, batch-CLI diff; architecture-review not triggered — no module-structure change). Soundness cross-check: no qualifying lifts. Considered overrides: none matched this diff.

## 🔴 Must Fix

| ID | Finding | Source | Severity | Location | Legibility | Status |
|---|---|---|---|---|---|---|
| R1 | oc fact-check briefs claimed "4.5–5.1KB … claims lists … *verbatim in both oc runs*": measured 4,524/5,067/**3,653** chars; claims list in 2/3 briefs; quoted directive verbatim only in md1-opus-r1. oc-r3 recovered R1 with a lean brief — the brief-richness mechanism narrative overstates; sizes and attribution wrong. Propagates to log row 29 (A2). | Fact-check M1 | Incorrect (High) — unanimous 3/3 | `docs/working/experiment-md1-r1-replication-2026-07-30.md:98-104` | for-author | ✅ Fixed |

## 🟡 Must Address

| ID | Finding | Source | Severity | Location | Legibility | Status |
|---|---|---|---|---|---|---|
| A1 | State doc contradicts its own branch: q#2 "Still zero data points" (two samples exist: 0.91 and ~47%, opposite directions) and §1.1 "first k=3 run has not executed" | Fact-check M2, M3 | Stale (High) | `docs/thoughts/code-review-evaluation-state.md:218` + §1.1 status | for-author | ✅ Fixed |
| A2 | Log row 29 echoes R1's wrong sizes/attribution | Fact-check M5 | Mostly Accurate (High) | `docs/decisions/log.md:50` | for-author | ✅ Fixed |
| A3 | "byte-identical" replicate prompts at 4 sites — identical except the spec-permitted output path; "7,834 bytes" is chars | Fact-check M6 | Mostly Accurate (High) | replication doc ×2, log row 29, state doc q#1 | for-author | ✅ Fixed |
| A4 | §5.0 "~18k–41k tokens" excludes MD1's ~2.2k cell | Fact-check M7 | Mostly Accurate (High) | `docs/thoughts/code-review-evaluation-state.md:282` | for-author | ✅ Fixed |
| A5 | Cost-doc footnote: MD1's empty sibling section is range-starts-at-mainline, not "already merged" (d90d6bb is not an ancestor of integration/6.1) | Fact-check M8 | Mostly Accurate (High) | `docs/working/stage1-context-cost-2026-07-31.md:42-47` | for-author | ✅ Fixed |
| A6 | Docstring drift: "per-section token estimates" are char counts; stats "char count" includes a file count; keyless dry-run prints contradictory "$0.00 … no $ projection" | Fact-check M9/M10 + api #3/#4 | Mostly Accurate (High) / Minor | `scripts/cross-model-review.py:26,125,348-359` | for-author | ✅ Fixed |
| A7 | Binary-file handling inverted: `\x00` guard unreachable (`sh()` text=True, `UnicodeDecodeError` uncaught) — a committed PNG **crashes the Stage-1 build**; sniff-caught files mislabelled under "TOO LARGE"; prompt declares 3 section kinds, emits an undeclared 4th (skip list) | Fact-check M11/M12 + security #3 + api #2/#5/#9 + test-strategy #1 (4-critic convergence, no 🔴 channel qualifies) | Mostly Accurate (Med) / Inconsistent / High | `scripts/cross-model-review.py:109-172` | for-author | ✅ Fixed |
| A8 | `split_range` three-dot semantics: for `a...b` the sibling boundary is `a`, not merge-base — sibling context can overlap the reviewed diff; undocumented, untested (all current usage two-dot) | Fact-check M13 + test-strategy #4 | Mostly Accurate (Med) | `scripts/cross-model-review.py:114-119,138` | for-author | ✅ Fixed (documented + guarded; semantic change deferred with note) |
| A9 | Merged-report contract gap: SKILL merge spec doesn't mandate `**Replication:**`/`**Commit:**` on the merged report; Gate 1h silently no-ops without them; no bats pin on the literal strings either side parses | Fact-check M14 + api #1 + test-strategy #3 | Mostly Accurate (High) / Inconsistent | `skills/code-review/SKILL.md:352-373`, `self-improvement.sh:1482-1500` | for-automated-gate | ✅ Fixed |
| A10 | Phantom "§1.0" anchor cited in 4 branch files (8 repo-wide); no such heading exists | Fact-check M15 + tech-debt D2 | Mostly Accurate (High) | state doc + SKILL.md:264 + bats:7 + log row 27 | for-author | ✅ Fixed (heading added — validates all citers) |
| A11 | Section-marker spoofing: Stage-1 prompt inlines repo content with no delimiter escaping; repo's own artifacts contain colliding `=== ` strings — forged "CONTEXT ONLY"/"UNDER REVIEW" boundaries can suppress/fabricate findings; undermines measurement validity | Security #1 | Medium | `scripts/cross-model-review.py:78-94,138-175` | for-author | ✅ Fixed (deterministic nonce-tagged delimiters) |
| A12 | Data-exfiltration surface: `--context-base` ships whole files + sibling diff to third-party APIs, no secret screening; dry-run persists full prompt into committable dirs | Security #2 | Medium | `scripts/cross-model-review.py:122-175,354-360` | for-author | 📝 Author note: inherent to Stage-1's design (own-repo experiment harness, solo dev); prominent docstring warning added + prompt.txt noted as sensitive. Secret-scanning pass deferred to pre-third-party-repo use — revisit trigger added to 021. |
| A13 | dd-sweep provenance "This is the runner that produced runs/…" unverifiable (post-hoc reconstruction per C20) | Fact-check M16 | Unverifiable (Med) | `scripts/dd-cross-model-sweep.py:4` | for-author | ✅ Fixed (docstring says "reconstruction of the runner") |

## 🟢 Consider

| ID | Finding | Source | Legibility | Status |
|---|---|---|---|---|
| C1 | Cost guard fails open: pricing-fetch failure / unknown model → $0.00 projection, `--max-usd` never trips | Security #4 (Low) | for-author | ✅ Fixed (fails closed on unpriced models unless --dry-run) |
| C2 | Gate 1h fail-opens: bolded `**Commit:**` → empty var skips stale check; missing `Commit:` skips silently; 1-char prefix false-accept | Security #5 (Low) + test-strategy #2 (High, capped) | for-automated-gate | ✅ Fixed (bold tolerated; missing line → explicit "commit-unknown" advisory note; ≥4-char prefix required) |
| C3 | False-pass bats test: Confirmed-Good pin greps SKILL_CONTENT globally — matches other sections, deleting the amendment still passes | Test-strategy #3 (High, capped) | for-automated-gate | ✅ Fixed (scoped to Stage-1 section + added `**Replication:**`/`Commit:` literal pins) |
| C4 | New-code test gap: `split_range`/`build_stage1_context`/dry-run have zero tests; Gate 1h hunk breaks the gate's extract-and-test idiom; Jaccard≤1 fix unpinned | Test-strategy #1/#2/#5 + T1–T7 plan | for-author | ✅ Partially fixed (new `test/cross-model-review-stage1.bats`: binary no-crash, oversize skip, split_range table incl. three-dot pin, keyless dry-run e2e). Gate-1h extraction + Jaccard pin: 📝 author note, follow-up |
| C5 | `--analyze-only` pools mixed `context_base`/`prompt_sha` records without warning; `(model, replicate)` keys overwrite | api #6 (Minor) | for-orchestrator-synthesis | ✅ Fixed (heterogeneity warning printed) |
| C6 | `factcheck_replication` jq key naming vs `red_findings` sibling convention | api #7 (Minor) | for-automated-gate | ✅ Fixed (renamed `fact_check_replication`, no consumers existed) |
| C7 | dd-sweep bare KeyError on missing env; no spend guard | api #8 + security #7 | for-author | ✅ Fixed (env get + sys.exit message; spend note in docstring — archival script) |
| C8 | Non-ASCII filenames fail `git show` under quotepath, falsely reported "deleted" | Security #6 (Info) | for-author | ✅ Fixed (`-c core.quotepath=off`) |
| C9 | Stale-replicate guard: missing-`Commit:` case unstated (default-allow at orchestrator layer) | Security #8 (Info) | for-orchestrator-synthesis | ✅ Fixed (SKILL: missing line = stale, delete) |
| C10 | bats section extractors have open-ended end anchors — renamed heading silently extracts to EOF (false-green trapdoor) | Tech-debt D1 | for-automated-gate | ✅ Fixed (end-anchor existence asserted in both suites) |
| C11 | Log row 29 essay-length (4th copy of the MD1-R1 narrative); violates log's own promotion rule | Tech-debt D5 | for-orchestrator-synthesis | 📝 Author note: trimmed in the A2 fix; full promotion to a decision file deferred |
| C12 | Number/unit drift structural fix: cite-the-artifact convention + generated tables | Tech-debt D4 | for-orchestrator-synthesis | 📝 Author note: adopted opportunistically in this fix pass; convention doc deferred |
| C13 | docs/working lifecycle: stamp superseded docs | Tech-debt D6 | for-author | 📝 Author note: deferred |
| C14 | Don't extract shared OpenRouter module yet (deliberate policy divergence; prompt-byte stability) | Tech-debt D3 | for-author | 📝 Agreed — no action by design |
| C15 | Gate 1h prose-defined fields drift silently while advisory | Tech-debt D7 | for-automated-gate | 📝 Carry intentionally per triage; A9's pins reduce the surface |

## ✅ Confirmed Good

| Claim | Evidence (executed enumeration) | Cross-check vs fact-check |
|---|---|---|
| argv-exec subprocess discipline (decision 018) holds — no `shell=True`, no string interpolation into commands | Security: enumerated every `subprocess.run`/`sh()` call site in both scripts + Gate 1h hunk | No contradicting observation in merged or replicate reports |
| API key env-only, Bearer-header-only, never logged; keyless dry-run makes zero network calls | Security: traced both scripts' key flow; dry-run path re-executed keyless by fact-check r1/r2/r3 with no network reach | Consistent with M22 (dry-runs reproduced offline) |
| Diff-only prompt byte-identical to pre-021 harness | Fact-check M25: template string-equality vs `git show main:` + all five diff-only token counts reproduced (3/3 replicates) | Verified 3/3 |
| k=3 vocabulary consistent across SKILL.md, both bats suites, Gate 1h parser (`**Replication:**`, `k=2 (one replicate failed)`, `r<N>.md`, severity ladder) | api-consistency: string-compared all four surfaces; 21/21 bats pass (test-strategy re-ran) | Consistent with M14's residue (the *mandate* gap, fixed as A9) — no contradiction with the consistency claim itself |
| Soundness-channel contract well-tested — mutation-checked; negative controls, terminality, lift-only pinned | Test-strategy: ran suite + mental mutations on each assertion | Consistent with M28 (Verified 3/3) |
| Prior-review consumption is real: 2 of 2026-07-30's items remediated, 1 resolved on this branch | Tech-debt: delta-checked each prior finding against branch commits | Consistent with M24 |

**Single-sample note (decision 25):** this is one review run; absence of findings is not an attestation.

## Verdict

**CONDITIONAL PASS → PASS after fix loop.** Gate: 1/1 🔴 fixed · 12/13 🟡 fixed + 1 author note (A12) · 10 🟢 fixed, 5 author-noted/intentional. Re-verified: bats suites + new stage-1 suite green, py_compile clean, dry-run reproduction spot-checked post-fix.
