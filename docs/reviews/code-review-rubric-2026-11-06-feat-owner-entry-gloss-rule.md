Commit: 407a2714
Loop closed at 407a2714

# Code Review Rubric

**Scope:** feat/owner-entry-gloss-rule, `62687b97..407a2714` (full branch) | **Reviewed:** 2026-11-06 | **Status: 🟢 PASSES** — no red or amber items open; single-sample review; absence of findings is not an attestation

Three iterations. Iteration 1: fact-check k=3 at 626e3a39, fixed at 58434175. Iteration 2: security and API-consistency critics plus fact-check k=1 at 58434175, fixed at ab46783b. Terminal pass: fact-check k=3 and both critics over the whole branch at ab46783b, fixed at 407a2714, then fact-check k=1 on that last delta: 0 Incorrect.

Departures from the skill: skill text was read by each agent from the worktree, not pasted; replicate and critic reports stayed in the session scratchpad, so `docs/reviews/code-fact-check-report*.md` and the critics' files are not on this branch; the 407a2714 delta got fact-check only, not a further critic panel, as the third and last iteration.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | The rule's only example glossed T3 as the weekly digest; T3 is the batched-answers trial (T5 is the digest) | Documentation | High | Fact-check, k=3 unanimous | `global-instructions/CLAUDE.md` | for-author | — | ✅ Fixed 58434175 |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Research doc claimed the glossed labels were those the trial rewrites touched | Documentation | Medium | Fact-check, k=3 | for-author | — | ✅ Fixed 58434175 | Claim removed |
| A2 | Audit claimed label-level precision a hand reading cannot support, and row 84 carried it | Documentation | Medium | Fact-check | for-author | — | ✅ Fixed ab46783b, 407a2714 | 5 of 6 entries is firm; bare labels are a range, about 11 to 16 of 21 |
| A3 | Observable mixed own-text and marker counts | Documentation | Medium | Fact-check | for-author | — | ✅ Fixed 58434175 | Two baselines, counted separately |
| A4 | A gloss line opening `Q-NNN:` or `- Q-NNN:` in an entry matches the gate's answer pattern, and the cycle's land is refused | Consistency | Low | Security critic, executed | for-author | — | ✅ Fixed ab46783b, 407a2714 | Bullet names both forms |
| A5 | The prompt then said such a line reads as an answer, which is false for marker bodies: they are filed quoted (log row 81) | Consistency | Minor | Fact-check, k=3; API critic | for-author | — | ✅ Fixed 407a2714 | Clause dropped from the prompt |
| A6 | Gloss plus link can push a marker table row past the 300-byte cut | Consistency | Medium | API critic; security critic | for-author | — | ✅ Fixed ab46783b, 407a2714 | Prompt keeps a long gloss or link above the table |
| A7 | "By ID and name" still prescribed the bare form | Consistency | Medium | API critic | for-author | — | ✅ Fixed ab46783b | Both places gain a plain line |
| A8 | Step 7 had no slot or source for the cycle's gloss lines | Consistency | Medium | API critic; security critic | for-author | — | ✅ Fixed ab46783b, 407a2714 | Default branch's docs; marker text attributed to the loop; merge entries included |
| A9 | The bats case missed the final message's pointer | Testing | Minor | Fact-check, k=3 | for-author | — | ✅ Fixed 58434175 | Mutation-checked by the fact-check |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `skills/code-review/references/chat-synthesis.md` lists bare IDs in a summary; if the owner reads it directly, it pulls against the rule | API critic | Minor | for-author | — | Deferred: outside the brief's three writers; the research doc records it |
| C2 | The `### Q-NNN · slug` heading is not exempted the way the Needs line is | API critic | Informational | for-author | — | Won't-Fix: a heading is grammar, and the rule covers what an entry says |
| C3 | The commit messages of 626e3a39 and ab46783b each carry a claim a later commit corrects | Fact-check | Minor | for-author | — | Won't-Fix: the branch only adds commits; the later messages say so |
| C4 | Step 7's "attributed" does not say quoted | Security critic | Informational | for-author | — | 🟢 Open |

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | Copy-only diff | The one script change is a line of prompt text; no logic, loop, query or dependency change |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## 🧩 Composition check

A6 cluster (`scripts/build-loop.sh` prompt line, security and API critics): distinct sources, same defect stated whole by each; `distinct defects` does not apply, and no composed row is needed since each states the mechanism and fix. No other multi-source co-located clusters qualified.

---

## ✅ Confirmed Good

| Claim | Evidence | Backing |
|---|---|---|
| No convention migration is due | All five fingerprints equal at 62687b97 and ab46783b; `scripts/questions.sh` diff is empty | Fact-check, executed |
| The prompt line reaches a loop | Real `--start` and `--prompt` runs print it, with `$BODY_BYTES` expanded to 300 | Fact-check, executed |
