Commit: 49a3dbb

# Security Review: review/q085 (Q-085 [3], review-unit size gate)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-q085` (3 files: `workflows/pr-prep.md`, `docs/decisions/log.md`, `docs/working/proposal-2026-09-27-smaller-review-units.md`). This is a loop pass, iteration 1.
**Date:** 2026-09-28
**Based on:** `docs/reviews/q085-code-fact-check-report.md` (k=1, no Incorrect)

Framing: this repo ships agent workflow docs, so `workflows/pr-prep.md` is the shipped surface and agents run its shell snippet. The diff adds no auth, crypto, network, deserialization or secret handling. The only security-relevant question is whether a process guardrail for autonomous agents can be evaded, and whether anything depends on it as a safety control. Severities are kept in proportion to that.

## Trust Boundary Map

```
B1: [branch contents, authored by the implementing agent] → [pr-prep 1a gate: git diff --numstat | awk] → [split/loop decision made by the agent]
B2: [waiver claim in PR description / merge message, written by the agent] → [pr-prep 1a completion criterion] → [oversized unit enters review-fix loop]
B3: [parallel pr-prep guidance: guides/pr-prep-quick-ref.md, guides/completion-signals.md, code-review chat-synthesis] → [agent's choice of which rule to follow] → [size decision]
```

Input-source classification:

```
S1: branch diff (paths, line counts)        — request-time (agent-authored) — UNTRUSTED toward the gate decision (the agent being gated produces it)
S2: agent's working directory when it runs  — request-time                  — UNTRUSTED toward pathspec resolution
S3: waiver text in PR description / merge msg — request-time (agent-authored) — UNTRUSTED as proof of user authorization
S4: questions.md ANSWERED entry by the user — runtime-mutable (the agent can also edit it) — trusted only as far as git authorship/the user's reply shows
S5: guides/*.md, chat-synthesis.md size rules — code-constant (repo docs)   — trusted, but they conflict with the new rule
```

What crosses boundaries: the implementing agent both produces the input the gate measures (S1) and runs the gate, and it also writes the only record of a waiver (S3). Nothing outside the agent enforces the cap. The diff treats the gate as a hard rule, but it is enforced only by the agent following the prose. No hook or script checks it (`hooks/live-verify-gate.sh`'s enforcement regex, line 73, covers only `devcontainer-config/…`).

## Findings

#### 1. Gate command undercounts to 0 when run from a subdirectory

**Severity:** Low
**Location:** `workflows/pr-prep.md:88-90`
**Boundary:** B1 (S2)
**Move:** #11 (bypass enumeration)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (pr-prep.md:89):
```
git diff --numstat main...HEAD -- . ':(exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'
```
Both `.` and `:(exclude)docs/` resolve relative to the cwd. Executed: from the worktree root this prints `12`, and from `skills/` it prints `0`. An agent whose shell is in a subdirectory (agents often `cd` between Bash calls) gets a count that covers only that subtree, and with `print n+0` a count of 0 looks like a clean pass. This bypasses the gate silently, not adversarially. It is not a security vulnerability, but it does make the "hard cap" fail open. Executed: `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'` prints `12` from the root, which matches.

**Recommendation:** Use the `:(top)` magic (`-- ':(top)' ':(top,exclude)docs/'`) or prefix `git -C "$(git rev-parse --show-toplevel)"`, so the count does not depend on the cwd.

#### 2. Waiver provenance is agent-written, so "only the user can waive it" is unverifiable

**Severity:** Low
**Location:** `workflows/pr-prep.md:92`, `:96`, `:151`
**Boundary:** B2 (S3, S4)
**Move:** #5 (invert the access control model)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence (pr-prep.md:92, truncated excerpt):
```
Only the user can waive it. In /away mode, split without asking and record the split as an interim in `docs/working/questions.md`; ... If you believe the unit can't be split, ask for the waiver there instead of starting the loop on the oversized unit.
```
Evidence (pr-prep.md:151):
```
- [ ] The unit is at most ~400 changed code lines (outside `docs/`), OR it was split into stacked units, OR the user waived the cap and the PR description records the waiver and an expanded "Reviewer's path — start here" section (step 6) that walks the larger diff in read-order
```
The authorization rule is stated, but the only evidence the completion criterion asks for is the PR description (the merge message on the local-merge path), and the gated agent writes that itself. The criterion does not require a pointer to the user's answer (a `Q-NNN` ANSWERED entry or reply). In /away mode, a "waiver recorded" line is indistinguishable from a real one. What the check does not cover is waivers claimed without a user act, and those default to allow. The impact is limited to review quality, not system security.

**Recommendation:** Require the waiver note to cite the Q-NNN entry whose `Status: ANSWERED` records the user's answer, for example `Size cap waived: Q-NNN`. Make the criterion check that citation, not the bare note.

#### 3. Parallel guidance keeps the old ~500 advisory with a self-declared escape

**Severity:** Low
**Location:** `guides/pr-prep-quick-ref.md:11`, `guides/completion-signals.md:82`, `skills/code-review/references/chat-synthesis.md:140-143` (not in the diff; this is stale guidance that conflicts with it)
**Boundary:** B3 (S5)
**Move:** #11 (alternate code path that skips the guard)
**Confidence:** High (read-static; the fact-check report makes the same observation independently)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
guides/pr-prep-quick-ref.md:11: - [ ] **Size check** — PR ≤ ~500 lines? If not, consider splitting before doing any other prep. If unsplittable, note in PR description and suggest file review order
guides/completion-signals.md:82: - [ ] If the PR exceeds ~500 lines, have you considered splitting it or documented why not?
chat-synthesis.md:140: 2. **split PR** — Total diff is >500 changed lines (added + removed per
```
An agent that works from the quick-ref or the completion-signals checklist, which are the shorter and more likely documents to be in context, finds a 500-line advisory. That advisory has an agent-self-granted "documented why not" escape, which is exactly what decision 62 removes. So the hard cap can be bypassed by following another sanctioned document. This is the most plausible real-world bypass of the three.

**Recommendation:** Update these three places to the ~400 code-line hard cap, with a user-only waiver and a pointer to pr-prep 1a. If they must stay out of scope for this ~400-line unit, file them as a follow-up.

#### 4. Code under `docs/` is excluded from the count

**Severity:** Informational
**Location:** `workflows/pr-prep.md:86-89`
**Boundary:** B1 (S1)
**Move:** #11
**Confidence:** High
**Legibility-target:** for-author

Evidence (pr-prep.md:86, truncated excerpt):
```
count the unit's changed code lines, leaving out `docs/` (review artifacts, working docs, decision records, thoughts):
```
The exclusion is the whole `docs/` tree, not the listed kinds of content. Executable or agent-steering files live there: `docs/human-author/prompts.ts`, `docs/working/scratch/health-check.py`, and `docs/reviews/execution-logs/*.sh`. Workflows also read and act on `docs/decisions/*.md` and `docs/thoughts/failure-patterns.md`. A unit can therefore carry arbitrary volume under `docs/` without triggering a split. I found no script, hook or test that sources those `docs/` code files (grep across `scripts/ hooks/ test/ skills/`), and the review loop still reviews the full diff including `docs/`. The effect is diluted review attention, not unreviewed code. No enforcement file is under `docs/` (live-verify-gate.sh:73), so the exclusion cannot hide an enforcement change.

**Recommendation:** Optional: narrow the exclusion to `docs/reviews/ docs/working/ docs/decisions/ docs/thoughts/`, or add `':(exclude)docs/**/*.md'` so non-markdown under `docs/` counts.

### Untested bypass candidates

- **"~" fuzz (for example, 430 lines).** The prose gives no tolerance band, so the agent decides whether ~400 includes 430. I did not test this, because the ambiguity is textual and there is no code path to exercise. Recommendation: state a number, for example "over 400".
- **Stale local `main`.** `main...HEAD` uses the merge base with local `main`. A stale `main` overcounts, which fails safe, and I did not identify an undercount path. I did not test with a synthetic stale ref.
- **Binary files.** numstat prints `-` for binary files, and awk adds them as 0 (the fact-check verified this). A large binary blob therefore adds nothing. I did not test whether review surfaces binaries adequately, since that is outside this diff.

## Endorsement Claims

- **Claim:** The size-gate exclusion cannot hide a change to an enforcement file, because the enforcement set (`devcontainer-config/…`) sits outside `docs/`.
  **Location:** `workflows/pr-prep.md:89`; `hooks/live-verify-gate.sh:73`
  **Evidence:** read-static
  **Verified:** Read the enforcement regex at live-verify-gate.sh:73. All its alternatives are anchored at `^devcontainer-config/`, and the gate's pathspec excludes only `docs/`.
  **Not verified:** whether `cc-isolated.sh`'s `enforcement_files()` (the list's owner, per the comment at line 70) matches the regex today.
  **route: code-fact-check**
- **Claim:** The `:(top)` form of the command gives the same count as the documented command when run from the repo root (12 on this branch).
  **Location:** `workflows/pr-prep.md:89`
  **Evidence:** executed
  **Verified:** Both commands printed `12` from the worktree root under `timeout 20`.
  **Not verified:** behavior on a branch with renames or binary files under the `:(top)` form.

## Primitive sweep

Primitive: shell exec (agent-run snippet). Scope: the diff's one command block.

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `workflows/pr-prep.md:89` `git diff --numstat … \| awk` | S1, S2 | none needed: no interpolated input, read-only git, fixed awk program | cleared: no injection surface; cwd dependence filed as Finding 1 |

No other dangerous primitives are in scope. The pre-existing snippets at pr-prep.md:119-131 are unchanged by this diff.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Gate undercounts to 0 from a subdirectory | Low | B1 | `workflows/pr-prep.md:89` | High |
| 3 | Stale 500-line advisories offer a self-granted escape | Low | B3 | `guides/pr-prep-quick-ref.md:11` (+2) | High |
| 2 | Waiver provenance is agent-written | Low | B2 | `workflows/pr-prep.md:151` | Medium |
| 4 | `docs/` exclusion covers code and agent-steering files | Informational | B1 | `workflows/pr-prep.md:86-89` | High |

## Overall Assessment

The change has no conventional security surface. It adds a read-only, fixed-string git and awk command with no injection path. The cap is a review-quality control for autonomous agents, not a security boundary. Nothing depends on it as a safety control, and every unit's review loop still covers the full diff. Enforcement-file changes also keep their own guard (live-verify-gate.sh, plus decision 60's never-skip-security rule). The cap can be evaded in three plausible, non-adversarial ways, each fixable in place:

- A cwd-relative pathspec that silently reads 0 (Finding 1, confirmed by execution).
- Older guidance that still offers the 500-line "document why not" escape (Finding 3).
- A waiver record the gated agent writes about itself (Finding 2).

The most important fix is Finding 1, a one-token change to `:(top)`, because it makes a "hard cap" fail open with no visible signal. No findings are above Low within the code paths read. The endorsement claims are still pending execution verification.

## Goal-Alignment Note

- **Answered:** Security design review of review/q085 vs main at 49a3dbb, per the security-reviewer skill. It addresses the brief's evasion angles: moving code under `docs/` (F4), subdirectory counts (F1), "~" fuzz (untested list), self-waiver in /away (F2), and the enforcement-file interaction (endorsement 1). It also finds one bypass the brief did not name, the stale parallel guidance (F3, which overlaps the fact-check's Stale items).
- **Out of scope:** the fact-check's accuracy notes (quoted old text not verbatim, the +3,613 figure, the missing commit-body `Notes:` line for /away splits per review-fix-loop.md:52) are not security issues and are left to the rubric. Q-085 is still OPEN in this branch's questions.md; that is a merge-sequencing matter for the orchestrator.
- **Escalate:** none. No HALT patterns. The only probes run were three `git diff` invocations under `timeout 20`, all finished, with no residual processes and no scratch files created.
