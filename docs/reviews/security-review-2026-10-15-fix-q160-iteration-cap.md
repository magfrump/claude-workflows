Commit: 7d61c39b

# Security Review — fix/q160-iteration-cap (final confirming pass)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-q160` (3 commits, a94e01c7..7d61c39b), full branch; markdown only
**Date:** 2026-10-15
**Based on:** merged final fact-check (k=3, no Incorrect) as summarized in the critic brief; its non-Verified clusters are not re-filed here
**User goal:** review branch fix/q160-iteration-cap before it merges locally.

Lens for a markdown-only process change: can an agent following these documents game or bypass the new size re-check, and does the change weaken an existing trust gate.

## Trust Boundary Map

```
B1: [agent-chosen BASE + agent-placed file paths] → [step 1a count command, re-run in loop] → [stop / continue decision]
B2: [user answer in questions.md (agent-editable file)] → [waiver entry, quoted in PR/merge msg] → [new size limit]
B3 (new): [loop state: rubric open/closed, unit grown in review] → [precedence rule + step 1a re-entry] → [autonomous split vs. user stop]
B4: [code-review rubric next action (chat-synthesis rule 2/5)] → [pr-prep 6c final re-check] → [publish / local merge]
```

```
S1: BASE value                 — runtime-mutable (agent sets per run) — UNTRUSTED for the gate decision (no validation, Q-085 R1)
S2: file placement (docs/ vs not) — runtime-mutable (agent commits)   — UNTRUSTED for the gate decision (exclude pathspec)
S3: user waiver answer text    — runtime-mutable (file agent can edit) — trusted for intent only when quoted verbatim; not verifiable from the file
S4: rubric `Loop closed at` marker — runtime-mutable (written by the pass) — trusted for scope selection; UNTRUSTED as proof a unit is "new"
S5: 400 / 800 thresholds       — code-constant (in docs)               — trusted
```

The change adds one new decision boundary (B3: when the agent may split on its own versus must stop for the user) and reuses step 1a's count unchanged (B1). The new stop raises the agent's incentive to get a favorable count, since in /away mode a count past 800 now halts the unit instead of letting the agent split.

## Findings

#### 1. Re-entering step 1a converts the user-only stop into an autonomous /away split

**Severity:** Medium
**Location:** `workflows/review-fix-loop.md:172` (precedence paragraph); `workflows/pr-prep.md:96` (step 1a /away split)
**Boundary:** B3
**Move:** 11 (bypasses for a guardrail), 5 (invert the control model)
**Confidence:** Medium
**Legibility-target:** agent following review-fix-loop.md in /away mode

Evidence (verbatim, review-fix-loop.md:172): "When the unit has grown past 800 during review, the agent does not split on its own to get back under: not by the early split trigger, and not by the iteration-4 gate's /away default `split`. [...] (A unit already past 800 at entry falls under step 1a, which splits it in /away mode.)" And pr-prep.md:96: "In /away mode, split without asking".

The precedence rule names two forbidden split paths but not a third: restarting pr-prep on the same grown branch. A unit at 850 lines that re-enters pr-prep (a new loop after `Loop closed at`, an abandoned-and-restarted loop, or a resumed session that reads the branch as fresh) is "past 800 at entry", and the parenthetical then directs step 1a to split it without asking. The parenthetical is meant for units never reviewed, but nothing in the text distinguishes "at entry" from "at re-entry", so the user's decision on growth during review can be skipped by a path the document itself points to. Impact is bounded (a split is reversible and recorded in `questions.md`), which is why this is Medium rather than higher.

**Recommendation:** Scope the parenthetical to a unit whose first step 1a check is past 800 (no review loop has run on it); state that a unit that grew past 800 under any earlier loop stays under the waiver stop on re-entry, and that a rubric for the branch (open or closed) is the marker.

#### 2. Relocating product content into `docs/` lowers the count past both gates

**Severity:** Medium
**Location:** `workflows/pr-prep.md:89-92` (count command), reused by `workflows/review-fix-loop.md:166`
**Boundary:** B1 (S2)
**Move:** 11
**Confidence:** Low (mechanism executed; likelihood low and visible in diff)
**Legibility-target:** agent running the size re-check; human reading the merge

Evidence (executed in a throwaway repo): a branch adding `skills/new.md` (100 lines) counts `100`; after `git mv skills/new.md docs/new.md` the same command prints `0`. The exclude pathspec `':(top,exclude)docs/'` is by design (decision log 62), and this is pre-existing for step 1a. The re-check makes it matter more: past 800 the /away agent is now blocked rather than free to split, so moving reference material a skill links to into `docs/` (e.g. `docs/thoughts/`) is the cheapest way to keep working. Renames inside code paths were also tested and count only edited lines, which is not a dodge.

**Recommendation:** One sentence in step 1a: content that a skill or workflow loads or links to counts as code wherever it lives, and a commit that moves such content into `docs/` during a loop is noted in its `Size:` line. No command change needed.

#### 3. Rubric can still print `merge` while the size stop holds; only 6c backstops it

**Severity:** Informational
**Location:** `skills/code-review/references/chat-synthesis.md:140-151`
**Boundary:** B4
**Move:** 3 (error path), 11
**Confidence:** Medium
**Legibility-target:** agent acting on `Recommended next action:`

Evidence: "Rule 2 does not apply on later passes of the review-fix loop. [...] No next action here, `merge` included, overrides that stop." The override sentence sits inside rule 2's body; under "first matching rule wins", an evaluator on a later pass skips rule 2 and reaches rule 5's `merge` without reading it. The pr-prep 6c re-check (pr-prep.md:132) is the real gate, so this is defense in depth, not a hole. Relatedly, a re-check waiver (e.g. to 900) does not waive the entry cap, so a fresh-loop rule 2 on that unit would recommend `split PR` against the user's waiver.

**Recommendation:** Move the "no next action overrides the size stop" sentence above the rule list (it applies to every rule), and let a re-check waiver count as a waiver for rule 2.

## Untested bypass candidates

- **Wrong BASE to print a low count (S1).** Pre-existing and user-accepted (Q-085 R1). Not re-tested; the new `Size:` commit lines make an unexplained drop between iterations auditable after the fact, but nothing checks it.
- **Forged or over-read waiver answer (S3).** `questions.md` is agent-editable, and "the answer quoted verbatim" is not verifiable from the file. Pre-existing for step 1a's waiver; not tested because it depends on agent honesty, not on text the diff adds.
- **Squash folding the `Size:` commits.** Known (fact-check r3); not re-filed.
- **GitHub path: pushes after 6c not re-checked.** Known (fact-check r1, r3); not re-filed.
- **Binary files count 0.** Pre-existing; not tested, unrealistic for markdown product.

## Endorsement Claims

- **Claim:** The diff adds no new way to lift the entry gate: an entry-gate waiver does not lift the re-check unless its answer says so.
  **Location:** `workflows/review-fix-loop.md:170`
  **Evidence:** read-static
  **Verified:** read the waiver paragraph: "A waiver of the entry gate does not lift this check unless its answer says so."
  **Not verified:** how step 1a's own waiver text (pr-prep.md:96) is read by an agent holding an old entry waiver that names no limit.
- **Claim:** The re-check stop applies in /away mode and is placed before the drift check, re-review and merge.
  **Location:** `workflows/review-fix-loop.md:166-168`; `workflows/pr-prep.md:105`, `:132`
  **Evidence:** read-static
  **Verified:** the three placements (3c, 6c, review-fix-loop § Size re-check) as written in the diff.
  **Not verified:** the GitHub-path pushes after 6c (known gap, fact-check r1/r3).
  **route: code-fact-check**
- **Claim:** The change does not touch the security-critic guarantees of decision log 60 (enforcement-file diffs) or any file in `hooks/live-verify-gate.sh`'s enforcement set.
  **Location:** diff `--stat`
  **Evidence:** read-static
  **Verified:** all 13 changed paths are under `docs/`, `guides/`, `skills/code-review/references/`, `workflows/`.
  **Not verified:** the enforcement regex itself against these paths.

## Primitive sweep

Primitive sweep: no dangerous primitives in scope (markdown only). The one command the diff engages, step 1a's `git diff --numstat` count, is reused unchanged; its two call sites (pr-prep.md:92 entry, review-fix-loop.md:166 re-check) share sources S1/S2 and are covered by Findings 1-2 and the untested list.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Step 1a re-entry turns the user-only stop into an /away split | Medium | B3 | `workflows/review-fix-loop.md:172` | Medium |
| 2 | Moving product content into `docs/` lowers the count | Medium | B1 | `workflows/pr-prep.md:89-92` | Low |
| 3 | Rubric `merge` can precede the size stop; 6c backstops | Informational | B4 | `skills/code-review/references/chat-synthesis.md:140-151` | Medium |

## Overall Assessment

The change adds a stop and weakens no existing trust gate: it only removes autonomous split paths past 800 and adds checks at 3c and 6c. The one gap with real consequence is Finding 1: the precedence rule closes two split paths but the step 1a parenthetical opens a third on re-entry, so the user's decision can be skipped. That is a one-sentence fix. Finding 2 is a pre-existing count dodge that the new stop makes more tempting. Both can be fixed in place; neither is architectural. No findings within the code paths read beyond these; endorsement claims pending execution verification.

## Goal-Alignment Note

The goal is to review the branch before it merges locally. From a security-and-gaming lens the branch does what Q-104 [2] asks and leaves no merge-blocking issue. Finding 1 is worth fixing before merge because it is a hole in the very rule the branch adds (precedence over the agent's own splits) and costs one sentence. Finding 2 and 3 can merge as acknowledged ambers.
