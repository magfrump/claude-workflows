# Performance Review: batch-feedback-routing-reminder hook

Commit: eb545b103fa2e55ec6deed43d775c4c2eea761c8

**Scope:** `hooks/batch-feedback-routing-reminder.sh` (the only perf-relevant file on `feat/batch-feedback-subagent-routing` vs `main`; the remaining diff is markdown/docs and a verify script).
**Date:** 2026-06-23
**Based on:** Stage-1 code-fact-check report (16/16 claims verified, zero Incorrect/Stale; confirmed three detection branches match the header, always exits 0, shellcheck-clean).

## Data Flow and Hot Paths

The hook is wired as an **additional** `UserPromptSubmit` hook. It fires **synchronously, once per prompt submission**, before the model sees the prompt. Path temperature: **warm-hot** — it is on a latency-sensitive interactive path (the user waits for it), but it runs **once per prompt**, not per-token and not in a loop. Realistic call frequency is one human prompt every few seconds; there is no fan-out or batching that multiplies invocations.

Per invocation the script does, in order:
1. `INPUT=$(cat)` — read stdin (in-process, one subshell).
2. One `jq` subprocess to extract `.prompt`.
3. Early `exit 0` if the prompt is empty.
4. `grep -cE` over the prompt (numbered-list count) — `emit`/`exit 0` if ≥2.
5. `grep -cE` over the prompt (bullet count) — `emit`/`exit 0` if ≥2.
6. `grep -iqP` over the prompt (ENUM, PCRE) — `emit`/`exit 0` if it matches.
7. `grep -iqE` over the prompt (ENUM, ERE fallback) — runs **only if step 6 did not match**.

Worst case (a non-matching prompt with `grep -P` available): **1 `jq` + 4 `grep` subprocesses**. Best case (numbered list detected): **1 `jq` + 1 `grep`**, short-circuiting before the expensive ENUM passes. The ordering is correct — cheapest, highest-signal checks (fixed-string-anchored line counts) run first; the regex-alternation ENUM passes run last and are skipped entirely when an earlier branch fires.

Prompt size is user-controlled and unbounded in principle; in practice prompts are kilobytes, occasionally low-megabytes (pasted logs/feedback batches).

## Findings

### Subprocess-spawn cost dominates per-invocation latency, and it is trivially small

**Severity:** Informational
**Location:** `hooks/batch-feedback-routing-reminder.sh:25–66` (whole pipeline)
**Move:** #1 Count the hidden multiplications; #3 work in the wrong place
**Confidence:** High
**Baseline:** Measured on this machine (WSL2, reviewer's own benchmark, 20-iteration loops, 2026-06-23): bare `bash -c 'exit 0'` ≈ 2.3 ms; one `jq` extract ≈ 15 ms; one `grep` ≈ 7 ms. Full non-matching pipeline (jq + 4 grep) ≈ **66 ms/invocation** (1.323 s / 20); matching short-circuit path ≈ **34 ms/invocation** (0.682 s / 20). These are reviewer-run, not harness-production numbers — treat as order-of-magnitude.
**Legibility-target:** for-orchestrator-synthesis

The per-invocation cost is bounded by ~5 short-lived subprocesses, dominated by the single `jq` spawn (~15 ms), with each `grep` adding ~7 ms. At one prompt every few seconds, ~66 ms of worst-case synchronous work is **negligible** against the prompt-submit latency budget (the model round-trip that follows is orders of magnitude larger). There is no loop, no N, and no per-token multiplication. **No action needed** — this is included to document that the hot-path-gate check was performed and the path, while warm, carries trivial cost at realistic scale.

### ENUM regex is bounded — no catastrophic-backtracking (ReDoS) risk

**Severity:** Informational
**Location:** `hooks/batch-feedback-routing-reminder.sh:51–63` (`ENUM` definition and both grep passes)
**Move:** #9 Asymptotic behavior / graceful degradation vs cliff
**Confidence:** High
**Baseline:** Measured on this machine (reviewer benchmark, 2026-06-23): a ~960 KB adversarial prompt of repeated near-match tokens (`"here is several multiple the following batch of "` ×20000) ran `grep -iqP "$ENUM"` in **0.058 s** and `grep -iqE` in **0.043 s**, both returning no-match. Linear, no blowup.
**Legibility-target:** for-orchestrator-synthesis

The ENUM alternatives contain only literal alternation `(a|b|c)`, word boundaries `\b`, and **bounded** wildcards `.{0,20}` / `.{0,15}`. There are no nested or overlapping unbounded quantifiers (no `(a+)+`, no `(.*)*`), which is the structural prerequisite for catastrophic backtracking. Bounded `.{0,N}` between literal anchors is linear in input length. The user-controlled, unbounded prompt size therefore does **not** open a ReDoS DoS vector. Both PCRE and ERE engines confirmed linear on a ~1 MB adversarial input. No action needed; flagged because the human explicitly requested a ReDoS assessment.

### ENUM runs TWO regex passes on a large non-matching prompt when grep -P is available

**Severity:** Low
**Location:** `hooks/batch-feedback-routing-reminder.sh:59–63` (the `if grep -iqP ... elif grep -iqE ...` ladder)
**Move:** #1 Count the hidden multiplications; #3 redundant work
**Confidence:** High
**Baseline:** `no baseline available — flagged as speculative` (the incremental cost is the second ENUM grep; on the ~960 KB adversarial input above, that second pass measured ~0.043 s, but the *realistic* prompt is kilobytes where the second pass is a few ms).
**Legibility-target:** for-author

When `grep -P` **is** available but the PCRE pass does **not** match, the `elif` falls through and runs the ENUM a **second time** under `grep -E` (with the `(?:` stripped). For every non-matching prompt this doubles the ENUM scan. The intent (per the comment) was for the ERE branch to be a *fallback for when `-P` is unavailable*, but as written it is also a *fallback for when `-P` runs and finds nothing* — which is the common case, since most prompts don't match. The two patterns are not semantically equivalent only in the `here's|here is|here are` alternative (the lone `(?:...)` group); the ERE-stripped form `here('s| is| are)` is in fact equivalent for matching purposes, so the second pass can never match when the first didn't. The second pass is therefore **pure wasted work** on every non-matching prompt where `-P` is present.

**Recommendation:** Gate the fallback on `-P` availability rather than on match result, e.g. detect `grep -P` support once (`if echo | grep -qP '' 2>/dev/null`) and choose the engine, or use `grep -iqP ... || { grep_p_supported || grep -iqE ...; }`. Simplest concrete fix: replace the `elif` with a guard so the ERE pass runs only when the PCRE pass *errored* (exit ≥2) rather than merely *did not match* (exit 1) — e.g. capture `grep -iqP; rc=$?` and run the ERE branch only `if [[ $rc -ge 2 ]]`. Impact at realistic scale is a few milliseconds per prompt, so this is a **correctness/cleanliness** fix more than a performance one — but it removes a guaranteed redundant scan and matches the documented intent.

## What Looks Good

- **Short-circuit ordering is correct.** The two cheap `grep -cE` line-count checks (fixed structural anchors) run before the expensive ENUM alternation, and each `emit` does `exit 0`, so a detected batch never pays for the ENUM passes. Cheapest-and-highest-signal-first is the right ordering.
- **No `set -e`, always `exit 0`** — failure falls through to silent no-op rather than surfacing a prompt error on the hot path; correct for a non-blocking interceptor.
- **Bounded regex by construction** — using `.{0,N}` instead of `.*` between anchors is exactly the discipline that keeps a user-controlled-input regex linear. This is a good pattern and worth preserving if the ENUM is extended.
- **Single `jq` spawn** — the dominant subprocess is invoked once; the prompt is not re-parsed.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Subprocess-spawn cost dominates but is trivial at 1 prompt / few seconds | Informational | whole pipeline (25–66) | High |
| 2 | ENUM regex bounded — no ReDoS / catastrophic backtracking | Informational | 51–63 | High |
| 3 | Both ENUM grep passes run on non-matching prompts when `grep -P` present (redundant scan) | Low | 59–63 | High |

## Overall Assessment

Performance posture is **healthy**. This is a warm-but-not-hot path — one synchronous invocation per prompt submission, no loops, no N, no per-token work — and the worst-case cost (~5 short-lived subprocesses, jq-dominated, ~66 ms in a reviewer benchmark) is negligible against the model round-trip that immediately follows. The headline concern the human requested — ReDoS on a large adversarial prompt — is **not present**: every regex alternative uses bounded `.{0,N}` wildcards with no nested unbounded quantifiers, and a ~1 MB adversarial input scanned linearly in under 60 ms. The only genuine finding is a **Low**-severity redundancy (Finding 3): when `grep -P` is available but the ENUM doesn't match — the common case — the script needlessly runs the ENUM a second time under `grep -E`, because the fallback is gated on match-result rather than on `-P` availability. That is fixable in place with a one-line guard and is more a cleanliness/correctness issue than a perf bottleneck. No profiling is needed; no structural changes are warranted.

## Goal-Alignment Note
- Answered: yes — perf review complete, report saved with all required tags
- Out of scope: markdown/docs and the `verify-batch-feedback-reminder.sh` script (no hot-path relevance); functional correctness of detection (covered by Stage-1 fact-check)
- Escalate: nothing — Finding 3 is a low-severity author fix, not an orchestrator action
- Questions I would have asked: omitted (scope was clear)
