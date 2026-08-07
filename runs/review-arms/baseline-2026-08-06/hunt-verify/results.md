# #4 first-red short-circuit — empirical measurement on candidates A & B (2026-08-06)

Per-agent tokens from task notifications. Both candidates run as a single `--loop-pass`: fact-check
first, then (absent a short-circuit) the Stage-1.5-gated critic panel. #4 fires **iff fact-check
confirms a behavioral 🔴** (tier policy T); when it fires it skips the whole panel.

## Candidate B — evidence-integrate `counterexamples`/`scenarios` (commit 6cf4b0d): #4 FIRES

| stage | tokens | verdict |
|---|---|---|
| fact-check (k=1) | 86,824 | **Incorrect(High), behavioral → 🔴** (schema doc names `counterexamples`; real key `scenarios`; `resolveFieldPath`→null → all scenario proposals silently dropped) |
| critic security | 74,502 | 1 Med (proto-pollution-shaped) — *skipped by #4* |
| critic api-consistency | 84,050 | **Breaking** (same field-key defect) — *skipped by #4* |
| critic architecture | 79,603 | **Structural 🔴** (field-path contract decoupled from artifact types) — *skipped by #4* |
| **panel total (what #4 skips)** | **238,155** | |

- Pass **without** #4 = 86,824 + 238,155 = **324,979**
- Pass **with** #4 = **86,824** (fact-check only; panel skipped once the 🔴 is confirmed)
- **#4 saving = 238,155 tokens = 73.3% of the red-gated pass.**

## Candidate A — throttle "last call always delivered" (commit e59c7ed): #4 does NOT fire

| stage | tokens | verdict |
|---|---|---|
| fact-check (k=1) | 66,717 | Incorrect(High) but **subject comment/doc → 🟡** (impact masked: consumers pass cumulative snapshots + final flush) — **gate does not fire** |
| critic performance | 62,230 | Low (trailing-edge stale args, masked) |
| critic api-consistency | 65,996 | **2 Breaking** (docstring contradiction + unimplemented `.cancel()`) |
| critic test-strategy | 58,049 | 5 Consider (advisory) |
| **panel total (all ran — nothing skipped)** | **186,275** | |

- Pass = 66,717 + 186,275 = **252,992**. **#4 saving = 0.**
- **The sharp point**: candidate A *does* contain a behavioral red — api-consistency rated the same
  contract lie **Breaking (🔴)**. But it surfaced from the **critic panel**, not fact-check (which
  called it 🟡 because consumers mask the runtime impact). #4's fact-check gate therefore never
  fired, and because the panel is one **parallel wave** there is nothing to short-circuit mid-flight.
  **A red was present and #4 still saved nothing.**

## What this measures about #4

1. **When it fires, #4 is large: ~73% of that pass** (the entire critic panel, once fact-check
   alone confirms the behavioral red). That is the upper bound the decision hoped for — and it's real.
2. **It fires rarely.** The trigger is a *fact-check-visible behavioral* 🔴. Across the whole program:
   canon reviewed states **0/8**; the 225-commit hunt found **2** candidates, and **1 of those 2 (A)
   still classified 🟡** at fact-check because its impact was masked. So even among hand-picked
   behavioral-lie commits, only ~half actually trip the gate. Effective trigger rate is low.
3. **A real red is not sufficient — it must be *fact-check-visible*.** A is the counterexample:
   structural/contract reds that live in the critic panel (the common case — see the whole baseline,
   where every behavioral red came from critics) give #4 nothing, because the parallel wave has
   already been dispatched.

**Expected loop saving ≈ P(pass's red is fact-check-visible) × ~73% of that pass.** With P low
(rare trigger), the expectation is small despite the large conditional saving. #4 is a
**high-variance, low-frequency** lever: near-zero most of the time, a big cut on the rare pass whose
blocker is a fact-check-visible behavioral lie. Keep it wired (it's free and safe); don't budget for
it as a steady reducer.

## Measurement cost
A pass 252,992 (fc 66,717 + panel 186,275) + B panel 238,155 + B fc 86,824 = **577,971 tokens**
(plus the earlier 3-agent history hunt ≈ 335k).
