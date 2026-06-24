# Security Review — batch-feedback → parallel-subagent routing

Commit: eb545b103fa2e55ec6deed43d775c4c2eea761c8

**Scope:** Diff `main...HEAD` on branch `feat/batch-feedback-subagent-routing`. Changed files: `CLAUDE.md`, `README.md`, `docs/working/verify-batch-feedback-reminder.sh`, `docs/working/wire-batch-feedback-reminder.md`, `hooks/batch-feedback-routing-reminder.sh`. The only security-relevant file is the hook script, which parses an untrusted prompt string from harness-provided stdin JSON.
**Date:** 2026-06-23
**Based on:** `docs/reviews/code-fact-check-report.md` (16/16 claims verified, zero Incorrect/Stale). Documented behavior (no `set -e`, always exit 0, three detection branches, shellcheck clean, additive wiring) taken as given; this pass evaluates security implications only.

No HALT-ESCALATE conditions matched: no secrets, no auth surface, no SQL/command injection reachable, no TLS/crypto. No dependency-manifest changes.

## Trust Boundary Map

- **B1: harness `UserPromptSubmit` payload (untrusted prompt text) → stdin JSON → `jq -r '.prompt'` → `$PROMPT` shell variable (new).** The prompt content is attacker-influenceable (any user/agent/tool-notification text). This is the one boundary the new code introduces: untrusted text crosses into a bash variable that is then fed to `grep`.
- **B2: `$PROMPT` → `printf '%s' "$PROMPT" | grep …` (data on stdin, never argv) (new).** The crossing of interest is whether prompt content can escape the data channel and become code, a grep flag, or a regex. The regex patterns themselves (`$ENUM`, `$ALLOWLIST`-analog) are author-controlled constants, not attacker input — so the only injection question is whether `$PROMPT` reaches a position other than grep's stdin.
- **B3: hook stdout → harness context injection (existing boundary, reused).** The hook can only append a fixed, author-written reminder string to context. It cannot emit a block decision, mutate, or drop the prompt (always exits 0, never prints a `decision` field).

Every line that touches untrusted data routes it through `printf '%s' "$PROMPT" | grep …`, i.e., the prompt is always grep's **stdin**, never an argument and never `eval`'d. That single discipline is what makes the surface safe; the findings below are all confirmations or low-severity hardening notes against that backdrop.

## Findings

#### No command/argument injection: untrusted prompt is stdin data, never argv or eval
**Severity:** Informational
**Location:** `hooks/batch-feedback-routing-reminder.sh:49,53,67,69`
**Boundary:** B2
**Move:** Trace trust boundaries / find the implicit sanitization assumption
**Confidence:** High

The reviewer-flagged concern was that a prompt beginning with `-` could be argument-injected into grep, or that shell metacharacters could trigger command substitution. Both are non-issues here. `$PROMPT` is only ever consumed as `printf '%s' "$PROMPT" | grep …`: it is the **standard input** to grep, not a positional argument, so a prompt of `-n`, `--version`, or `-e …` is read as text to be searched, never parsed as a flag. It is never word-split into argv (always inside double quotes) and never reaches `eval`/`source`/backticks. I verified empirically: prompts `"$(touch /tmp/PWNED_BATCH); …"`, `` "`id`; rm -rf …" ``, `"--version"`, and `"; cat /etc/passwd #"` all exit 0 with no side effects (`/tmp/PWNED_BATCH` was never created). The only argv-position strings are the author-controlled regex constants. No action needed — this is the correct pattern.
**Recommendation:** None. Preserve the `printf '%s' "$VAR" | grep` idiom in any future edits; do not refactor to `grep … "$PROMPT"` or `echo $PROMPT`, either of which would reintroduce the boundary.

#### Parameter-expansion fallback `${ENUM//(\?:/(}` is correct and injection-free
**Severity:** Informational
**Location:** `hooks/batch-feedback-routing-reminder.sh:69`
**Boundary:** B1/B2 (operates on author-controlled `$ENUM`, not on prompt)
**Move:** Find the implicit sanitization assumption
**Confidence:** High

The `grep -P` → `grep -E` fallback strips the PCRE non-capturing marker `(?:` down to `(` via bash pattern substitution. The substitution operates entirely on `$ENUM`, which is a **build-time author constant** assembled by string concatenation from literals — no attacker input flows into it — so there is no injection vector in the substitution itself. I confirmed the rewrite is also functionally correct: the stripped pattern still compiles under `grep -E` and `here is the feedback` matches via the fallback. One narrow correctness note (not security): the substitution only rewrites the single literal `(?:` that appears in the `here(?:'s| is| are)` alternative; that is the only `(?:` in `$ENUM`, so the rewrite is complete for the current pattern. If a future edit adds another `(?:` group, the author must remember the fallback depends on this substitution covering it — otherwise `grep -E` would error and (because of the `2>/dev/null` and the `||`-style `elif`) silently fail to match, degrading detection but not security.
**Recommendation:** Add a one-line comment at the `ENUM=` block noting "every `(?:` here must survive the `grep -E` fallback rewrite at line 69" so the coupling is visible to the next editor. Purely maintainability; no security exposure.

#### No ReDoS: all unbounded matching is line-anchored or width-bounded
**Severity:** Informational
**Location:** `hooks/batch-feedback-routing-reminder.sh:49,53,57-63`
**Boundary:** B1
**Move:** "What if there are a million of these?" (DoS)
**Confidence:** High

A malicious prompt cannot hang the hook. The numbered/bullet greps are line-anchored counters (`grep -cE '^…'`) — linear in input. The `$ENUM` alternation uses only **bounded** wildcards (`.{0,20}`), never an unbounded `.*` adjacent to alternation, so there is no catastrophic-backtracking construct for `grep -P` to blow up on. I tested two ReDoS-shaped payloads (200 KB and 100 KB crafted strings targeting the `.{0,20}` and `here is … feedback` patterns) under a 5-second timeout; both completed at rc=0 well within the limit. Even an enormous prompt is processed once, linearly. The harness would presumably bound prompt size upstream regardless.
**Recommendation:** None.

#### Fail-safe on all error paths (jq missing, malformed JSON, empty prompt)
**Severity:** Informational
**Location:** `hooks/batch-feedback-routing-reminder.sh:25-35,71`
**Boundary:** B1, B3
**Move:** Check the error path, not just the happy path
**Confidence:** High

Every failure mode collapses to "silent, exit 0," which is the safe direction for a non-blocking advisory hook. `command -v jq` guards the parser; if jq is absent, `$PROMPT` is set to `""` and the `[[ -z "$PROMPT" ]] && exit 0` guard returns immediately (verified by shadowing jq out of PATH — empty output, rc=0). Malformed JSON makes `jq -r '.prompt // ""'` fail; the `2>/dev/null` suppresses its error and command substitution yields `""`, again hitting the empty-guard (verified: `not json` → silent rc=0). The absence of `set -e` is deliberate and correct here: it guarantees an internal stumble degrades to "no reminder" rather than surfacing a prompt-submission error. Because the hook only ever appends a fixed advisory string and never emits a block/deny decision, the worst-case failure is a missing suggestion — it cannot leak data, block submission, or alter the prompt (boundary B3).
**Recommendation:** None.

#### Fires on every `UserPromptSubmit` (no matcher), including agent/tool notifications — benign
**Severity:** Low
**Location:** `hooks/batch-feedback-routing-reminder.sh` (whole script); wiring in `~/.claude/settings.json`
**Boundary:** B1, B3
**Move:** Invert the access-control model (what cases does this not gate?)
**Confidence:** High

The hook has no event matcher, so it runs on all `UserPromptSubmit` events — human prompts, but also system/tool/agent notifications (observed live firing on an agent task-notification with markdown bullets). From a security standpoint this broadens the *input* set across B1 but not the *capability* set: regardless of who authored the text, the only effect is the same fixed, non-blocking stdout reminder (B3). It cannot be coerced into blocking, leaking, or rewriting a submission. The genuine downside is a **correctness/noise** one, not security: a bulleted agent notification can spuriously trigger the reminder, mildly polluting context. That is a precision concern for the routing feature, not an exploitable condition, and it is already documented. No trust boundary is violated by the over-firing because the action behind the trigger is inert.
**Recommendation:** No security action required. If the noise is undesirable, consider gating on a payload field that distinguishes human prompts from agent/tool notifications (if the harness exposes one) — but that is a feature-precision tweak, out of scope for this security pass. Flagging to the orchestrator as a non-security follow-up.

## What Looks Good

- **Data-on-stdin discipline.** Every use of untrusted `$PROMPT` is `printf '%s' "$PROMPT" | grep …` — stdin, never argv, never `eval`. This is the single most important security property and it is applied consistently across all four match branches.
- **Defense-in-depth defaults.** No `set -e` plus an always-`exit 0` tail plus a hard `[[ -z "$PROMPT" ]]` early-return means the hook fails toward silence on every error path. For an advisory hook, "fail open to no-op" is exactly right.
- **Regex constants are author-controlled.** `$ENUM` is built from string literals at script load; no attacker input is ever concatenated into a regex, so there is no regex-injection surface.
- **Bounded wildcards.** Using `.{0,20}` rather than `.*` in the enumeration patterns forecloses ReDoS by construction.
- **Mirrors a reviewed sibling.** The structure tracks `dd-routing-reminder.sh` closely (same jq-guard, same fail-safe tail, same additive wiring), so it inherits an already-vetted shape rather than inventing a new trust posture.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | No command/arg injection — prompt is stdin data, never argv/eval | Informational | B2 | hook:49,53,67,69 | High |
| 2 | Parameter-expansion fallback `${ENUM//…}` correct & injection-free | Informational | B1/B2 | hook:69 | High |
| 3 | No ReDoS — matching is line-anchored or width-bounded | Informational | B1 | hook:49,53,57-63 | High |
| 4 | Fail-safe on jq-missing / malformed JSON / empty prompt | Informational | B1,B3 | hook:25-35,71 | High |
| 5 | Fires on every UserPromptSubmit (no matcher) — inert, benign | Low | B1,B3 | whole script | High |

## Overall Assessment

The security posture of this change is sound. The only file with a trust boundary — the hook — handles untrusted prompt text correctly: it routes that text exclusively as grep **stdin** (never as a shell argument and never through `eval`), so none of the flagged vectors (command injection, argument injection via a leading `-`, regex/ReDoS, command substitution) are reachable, which I confirmed empirically rather than by inspection alone. The regex constants are author-controlled, the `(?:`-stripping fallback operates only on those constants and is functionally correct, and every error path (missing jq, malformed JSON, empty prompt) fails silent with exit 0. The hook's sole capability is appending a fixed, non-blocking advisory string; it cannot block, leak, or alter a submission, which also neutralizes the "fires on every event including agent notifications" concern — that is a precision/noise issue for the routing feature, not a security one. Nothing here is architectural or merge-blocking. The single most important thing to preserve going forward is the `printf '%s' "$VAR" | grep` idiom: any refactor to `grep … "$PROMPT"` or `echo $PROMPT` would reintroduce the argument-injection boundary this design carefully avoids.

## Goal-Alignment Note
- Answered: yes
- Out of scope: the "fires on every UserPromptSubmit" over-firing is a routing-precision/noise concern, not a security one — flagged to orchestrator but not actioned here; README/CLAUDE.md prose changes carry no trust boundary.
- Escalate: nothing security-relevant. Non-security follow-up for the orchestrator/author: consider a payload-field matcher to suppress spurious firing on agent/tool notifications (Finding 5), and a comment documenting the `(?:`-fallback coupling (Finding 2).
- Questions I would have asked: omitted — scope was clear.
