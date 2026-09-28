Commit: b516af2

# Security Review: review/q085 iteration 2 (fix delta 49a3dbb..HEAD)

**Scope:** `git diff 49a3dbb..HEAD` in `/workspace/.claude/wt-q085`. Reviewed: `workflows/pr-prep.md`, `docs/decisions/log.md` row 62, `guides/pr-prep-quick-ref.md`, `guides/completion-signals.md`, `skills/code-review/references/chat-synthesis.md`. `docs/reviews/*` in the range are context only. This is a loop pass, iteration 2, incremental scope.
**Date:** 2026-09-28
**Based on:** `docs/reviews/q085-code-fact-check-report-iter2.md` (k=1, no Incorrect) and my iteration-1 report `docs/reviews/q085-security-review-2026-09-28.md`

Framing is unchanged from iteration 1. The shipped surface is agent workflow prose plus one read-only `git diff | awk` snippet. The size cap is a review-quality control for autonomous agents. It is not a security boundary, and no hook or script enforces it. Severities are kept in proportion to that, which is the same calibration iteration 1 used.

## Prior findings: verification

| Iter-1 # | Finding | Status | Evidence |
|---|---|---|---|
| 1 | Pathspec was relative to the cwd, so it read 0 from a subdirectory | **Resolved** | Executed under `timeout 20`: the new command prints `31` from the worktree root and `31` from `skills/`. |
| 2 | Waiver provenance was only agent-written PR text | **Partially resolved.** Residual risk is Informational (Finding 2 below) | pr-prep.md:99 now requires citing `Q-NNN`, ANSWERED, and says "a waiver with no such entry is not a waiver"; completion criterion :153 checks the citation. The cited file is still agent-editable. |
| 3 | Stale ~500 advisories offered a self-granted escape | **Resolved for the three named sites**, with one stale input line left (Finding 3) | quick-ref:11, completion-signals:82 and chat-synthesis rule 2 (:140-144) now point at the 1a gate. A repo-wide `rg` for `~500 / 500 lines` turns up no other PR-size escape, except `guides/validation-gates.md:274` (see Untested bypass candidates). |
| 4 | `docs/` exclusion covers code | Unchanged (was Informational, not claimed as fixed) | — |
| untested | "~" fuzz | **Resolved** | pr-prep.md:94: "The gate fires above 400: the "~" marks a round number, not a tolerance band." |

## Trust Boundary Map

```
B1: [branch diff, agent-authored]              → [pr-prep 1a: git diff --numstat "$BASE"...HEAD | awk] → [split / loop decision]
B2 (new): [BASE value, set by the gated agent]  → [revision argument to git diff]                         → [count the gate compares to 400]
B3: [waiver claim + cited Q-NNN entry]          → [1a completion criterion (:153)]                       → [oversized unit enters the loop]
B4: [parallel guidance: quick-ref, completion-signals, chat-synthesis] → [agent's choice of rule]          → [size decision]
```

Input-source classification:

```
S1: branch diff (paths, line counts)            — request-time (agent-authored) — UNTRUSTED toward the gate decision
S2: BASE shell variable                         — request-time (agent-set; shell state does not persist between harness Bash calls) — UNTRUSTED toward the revision argument and the count
S3: waiver text in PR description / merge msg   — request-time (agent-authored) — UNTRUSTED as proof of user authorization
S4: questions.md / questions-archive.md ANSWERED entry — runtime-mutable (the agent records answers there per CLAUDE.md) — trusted only as far as the user's own reply or authorship shows
S5: guides/*.md, chat-synthesis.md              — code-constant (repo docs) — trusted; now mostly aligned
```

The delta adds one new input, S2 (`BASE`). It is interpolated into the only command the gate runs, and nothing validates it. Everything else the delta does narrows the bypasses iteration 1 found.

## Findings

#### 1. Empty, unset or invalid `BASE` makes the gate print 0 and pass

**Severity:** Low
**Location:** `workflows/pr-prep.md:89-91` (also `:101`, which tells stacked units to set `BASE`)
**Boundary:** B2 (S2)
**Move:** #11 (bypass enumeration), #3 (error path)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (pr-prep.md:89, :91):
```
BASE=main   # for a stacked unit whose lower unit has not merged yet: that unit's branch
git diff --numstat "$BASE"...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'
```
I executed the command under `timeout 20` in this worktree with four values of `BASE`:

| `BASE` | Output |
|---|---|
| `main` | `31` |
| `49a3dbb` | `27` |
| empty or unset | `0` |
| `HEAD` | `0` |

With an empty `BASE`, the argument becomes `...HEAD`, which git reads as `HEAD...HEAD`, an empty diff. The command exits 0 and prints no error. With a ref that does not exist (`nosuchref`), git prints `fatal: ambiguous argument` to stderr, but the pipeline still prints `0` and exits with awk's status 0.

The empty case is reachable without any adversarial intent. The harness does not keep shell variables between Bash calls. An agent that runs the `BASE=` line and the `git diff` line as separate calls, or copies only line 91, gets `0`. So does a stacked-unit agent following :101 that mistypes the variable. `print n+0` makes that indistinguishable from a real clean count. This is the same fail-open shape as iteration-1 Finding 1, moved from the pathspec to the revision.

Severity note: the floor rule was considered. The mechanism is concrete and reachable, but the property it violates is a review-size policy, not a security property, so this stays Low for consistency with iteration 1.

**Recommendation:** Make the command fail closed. Use `"${BASE:-main}"` inline so the count cannot run without a base. Add a guard before the count, for example `git rev-parse --verify -q "$BASE^{commit}" >/dev/null && [ "$(git rev-parse "$BASE")" != "$(git rev-parse HEAD)" ] || { echo "size gate: bad BASE" >&2; exit 1; }`. Alternatively, put the snippet in one line so it cannot be split across calls, and state that a count of 0 on a non-empty branch is an error.

#### 2. The waiver citation still points at an agent-editable record, and archiving moves it

**Severity:** Informational
**Location:** `workflows/pr-prep.md:99`, `:153`; `docs/decisions/log.md:85`
**Boundary:** B3 (S3, S4)
**Move:** #5 (invert the access control model)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence (pr-prep.md:99, truncated excerpt):
```
citing the `docs/working/questions.md` entry (`Q-NNN`, ANSWERED) where the user granted it; a waiver with no such entry is not a waiver.
```
This fixes the part of iteration-1 Finding 2 that mattered most. A waiver now needs a checkable pointer, and a bare claim is ruled out. Two residual issues remain.

- The global CLAUDE.md has the agent itself "Record answers inline, set `Status: ANSWERED`". An ANSWERED status therefore shows that the agent wrote it, not that the user answered. The user's reply is the actual authority, and it lives in the conversation or the commit, not in the entry.
- The fact-check found that `questions.sh archive` moves answered entries to `questions-archive.md`. A reader checking the citation against `questions.md` alone would find nothing. That fails closed ("not a waiver"), so it only costs legibility.

The overall impact is on review quality only.

**Recommendation:** Optional. Say "`questions.md` or `questions-archive.md`". Ask that the entry quote the user's answer line verbatim (`Q-NNN: <answer>`) rather than rely on the status field.

#### 3. chat-synthesis still names `git diff --stat` as the size input

**Severity:** Informational
**Location:** `skills/code-review/references/chat-synthesis.md:128` (not changed by the delta; it conflicts with rule 2 at :140-144, which the delta did change)
**Boundary:** B4 (S5)
**Move:** #11 (alternate path to the guard)
**Confidence:** High (read-static; the Stage-1 fact-check reports this as Stale)
**Legibility-target:** for-author

Evidence (chat-synthesis.md:128, truncated excerpt):
```
Inputs are the rubric the synthesis just produced (...) and the diff size from `git diff --stat`.
```
Rule 2 now says to count "with that step's command". The inputs line still points at an all-files `--stat`. A synthesizer that follows :128 counts `docs/` too, which **overcounts**. That fails safe: it recommends more splits, never fewer. So this is a consistency issue, not a bypass.

**Recommendation:** Change :128 to "the unit's size from `workflows/pr-prep.md` step 1a's command".

### Untested bypass candidates

- **`BASE` set to a real branch that was never gated.** When `BASE` is any branch containing most of the unit (for example, a "lower unit" the agent creates only to absorb lines), the upper unit counts only its own delta. That is correct if the lower unit runs its own gate and loop, as :94 requires. Nothing in 1a checks that the lower unit did. I did not test this, because it depends on the agent's own branch-creation behavior and there is no code path to exercise. The executed `BASE=49a3dbb → 27` confirms the mechanism, not whether the lower unit was reviewed.
- **Option-shaped `BASE`.** `BASE="--output=<path>"` becomes the single argument `--output=<path>...HEAD`. Git parses that as an option, writes an (empty) file named `<path>...HEAD`, and the gate prints `0`. I executed this under `timeout 20` with the path in my scratch directory; the probe file has been removed. `BASE` is set by the agent being gated, not by an outside attacker, so this is only an accident path. The guard in Finding 1's recommendation (`rev-parse --verify`) also closes it. Listed rather than filed as a finding.
- **`guides/validation-gates.md:274`** still reads "Task scope is narrow enough to stay under 500 lines changed" as a self-improvement pre-flight item. It is a planning target, not a PR-size escape. The 1a gate still fires later, so a unit between 401 and 500 lines is caught at pr-prep. I did not confirm that the SI loop routes every task through pr-prep 1a.

## Endorsement Claims

- **Claim:** The step-1a count is identical from the repository root and from a subdirectory.
  **Location:** `workflows/pr-prep.md:91`
  **Evidence:** executed
  **Verified:** Printed `31` from the worktree root and `31` from `skills/` under `timeout 20`, with `BASE=main`.
  **Not verified:** runs from inside a nested worktree or a submodule (neither is used here).
- **Claim:** With `BASE` set to a lower unit's commit, the count covers only the upper unit's lines.
  **Location:** `workflows/pr-prep.md:89-91`
  **Evidence:** executed
  **Verified:** `BASE=49a3dbb` printed `27`, versus `31` with `BASE=main`. The Stage-1 fact-check reports the same arithmetic independently.
  **Not verified:** that the lower unit named as `BASE` was itself gated (see Untested bypass candidates).
- **Claim:** The three parallel size rules iteration 1 flagged now point at the 1a gate and offer no agent-granted escape.
  **Location:** `guides/pr-prep-quick-ref.md:11`, `guides/completion-signals.md:82`, `skills/code-review/references/chat-synthesis.md:140-144`
  **Evidence:** read-static
  **Verified:** Read each changed line in the diff. Each names the ≤400 / >400 code-line gate, and the two checklists name a user-only waiver.
  **Not verified:** chat-synthesis.md:128's input line (Finding 3), and whether other docs outside the `rg` patterns I used paraphrase a size rule.
  **route: code-fact-check**

## Primitive sweep

Primitive: shell exec (the agent runs the snippet). Scope: the command blocks changed in 49a3dbb..HEAD.

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `workflows/pr-prep.md:89-91` `git diff --numstat "$BASE"...HEAD … \| awk` | S1, S2 | `"$BASE"` is quoted, so no word splitting or shell injection; no validation of the value | Finding 1 (empty/invalid → 0); option-shaped value listed under Untested bypass candidates |

The other snippets in pr-prep.md (Step 0 at :36-44, the failure-pattern advisory, the pre-mortem fallback at :121-133) contain no `BASE` or new interpolation. The delta changed only a comment at :43.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Empty, unset or invalid `BASE` prints 0 and passes the gate | Low | B2 | `workflows/pr-prep.md:89-91` | High |
| 2 | Waiver citation points at an agent-editable, archivable record | Informational | B3 | `workflows/pr-prep.md:99`, `:153` | Medium |
| 3 | chat-synthesis :128 still names `git diff --stat` (overcounts; fails safe) | Informational | B4 | `skills/code-review/references/chat-synthesis.md:128` | High |

## Overall Assessment

The fix commit resolves iteration-1 Finding 1 (confirmed by execution), resolves Finding 3 at its three named sites, and closes the "~" ambiguity. It also narrows Finding 2 to an Informational residual. There is still no conventional security surface: no auth, crypto, network, deserialization or secrets, and nothing depends on the cap as a safety control. The one regression-shaped issue is new with the `BASE` variable. An empty, unset or invalid `BASE` makes the gate print `0` with exit status 0, which is the same silent fail-open that iteration 1 fixed for the pathspec. That is reachable without adversarial intent, because harness Bash calls do not share shell variables. Fixing it in place is a one-line guard or a `${BASE:-main}` default, and that is the single most important change. Nothing is above Low within the code paths read. The one `route: code-fact-check` endorsement is still pending execution verification.

## Goal-Alignment Note

- **Answered:** Security design review of the fix delta 49a3dbb..HEAD at b516af2, per the security-reviewer skill. Each iteration-1 finding is verified (table at top). I checked the brief's regression question directly: yes, `BASE` can under-count and pass silently (Finding 1, executed for empty, `HEAD`, invalid-ref and option-shaped values). The Stage-1 fact-check's Stale item (chat-synthesis:128) is assessed as fail-safe (F3). Its archive-path note is folded into F2.
- **Out of scope:** The fact-check's wording note on commit b516af2 ("Deletions still count, as the user's rule says" overstates the user's rule) is not a security issue and is left to the rubric. Q-085 is still OPEN in this branch's `questions.md`; merge sequencing is the orchestrator's call. Iteration-1 Finding 4 (the `docs/` exclusion) was not re-litigated.
- **Escalate:** none. No HALT patterns. Probes: about 10 `git diff` runs, each under `timeout 20`, all finished. The only `git` processes still visible belong to the harness's own status polling, not to me. The one scratch file (`out...HEAD` under `/home/node/.claude/jobs/9f431b13/tmp/q085-sec2/`) was removed, and nothing in the worktree changed except this report.
