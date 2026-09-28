Commit: b516af2

# API Consistency Review — review/q085, loop iteration 2 (49a3dbb..HEAD)

**Scope:** fix delta `49a3dbb..HEAD` (commit b516af2; 93f3b4d is review artifacts, context only). Public surface = `workflows/pr-prep.md` step 0/1a/1b/completion criteria, `guides/pr-prep-quick-ref.md`, `guides/completion-signals.md`, `skills/code-review/references/chat-synthesis.md` rule 2, `docs/decisions/log.md` row 62, `docs/reviews/override-log.md` rows (context).
**Date:** 2026-09-28
**Based on:** `docs/reviews/q085-code-fact-check-report-iter2.md` (k=1); iteration-1 report `docs/reviews/q085-api-consistency-review-2026-09-28.md`
**Iteration scope:** incremental (delta range). Prior findings verified: 6 resolved, 0 still open; 1 declined with an override-log row.

## Baseline Conventions

Same baseline as iteration 1, re-checked against the delta:

- A rule is stated in one owning place and mirrors link to it (`workflows/review-fix-loop.md:7`: "Each rule is stated in one place; the others link to it"). Step 1a owns the size gate; quick-ref, completion-signals and chat-synthesis rule 2 now defer to "step 1a's command".
- /away split recording convention: "Record the split as an interim in `docs/working/questions.md` and in the commit body's `Notes:` line" (`workflows/review-fix-loop.md:52`).
- Question lifecycle: answered entries move to `docs/working/questions-archive.md` (`docs/working/questions.md:6-7`; global CLAUDE.md "Record answers inline, set `Status: ANSWERED`, run `archive`"). The `Q-NNN` ID is the stable handle across both files.
- Separate size thresholds with different purposes are left alone: pre-mortem fallback `LOC_TOTAL > 500` (`workflows/pr-prep.md` 1c), code-review tech-debt trigger (`skills/code-review/SKILL.md:227`), SI Gate 1b (`guides/validation-gates.md:48`, out of scope per iteration 1).

## Prior findings — verification

| # (iter 1) | Finding | Status | Evidence |
|---|---|---|---|
| 1 | Quick-ref / completion-signals kept ~500 advisory | Resolved | `guides/pr-prep-quick-ref.md:11` "unit ≤ 400 changed code lines outside `docs/` (count with pr-prep step 1a's command)"; `guides/completion-signals.md:82` "within pr-prep step 1a's size gate (≤ 400 …)" |
| 2 | chat-synthesis "split PR" used a different size contract | Resolved in rule 2 (see new Finding 1 for the leftover input line) | `chat-synthesis.md:140-144` "over the size gate in `workflows/pr-prep.md` step 1a (>400 changed lines outside `docs/`, counted with that step's command…)" |
| 3 | `main...HEAD` count didn't fit stacked units | Resolved | `pr-prep.md:89` `BASE=main   # for a stacked unit whose lower unit has not merged yet: that unit's branch`; 1b now points to it (`pr-prep.md:101`). Fact-check executed: BASE=lower counts only the upper unit. |
| 4 | Step 0 comment still said "size check in step 1a" | Resolved | `pr-prep.md:43` "# Show total lines changed, all files (step 1a's size gate runs its own count)" |
| 5 | "hard cap: ~400" vs exact-bound idiom | Resolved | `pr-prep.md:93` "The gate fires above 400: the "~" marks a round number, not a tolerance band."; completion criterion now "at most 400" (`:153`); row 62 "the gate fires above 400" |
| 6 | /away split record omitted `Notes:` | Resolved | `pr-prep.md:93` "…as an interim in `docs/working/questions.md` and in the commit body's `Notes:` line, as the [early split trigger](review-fix-loop.md#early-split-trigger-after-any-iteration) does"; anchor exists (`review-fix-loop.md:48`); row 62 matches |
| 7 | Row 61 has no forward pointer | Declined | override-log row "Decision log row 61 still says A4 … — api-consistency 7 · Won't-Fix" — reason is sound (log rows record state at writing; row 62 cites 61). |

No regressions found in the fix commit: the pathspec change (`':(top)' ':(top,exclude)docs/'`) is behaviour-preserving from the repo root and fixes subdirectory runs (fact-check executed: 31 from root and subdir).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `BASE` (shell variable in step 1a snippet) | param | `FIX_COMMITS`, `PATTERN_ADDITIONS`, `LOC_TOTAL`, `PREMORTEM_EXISTS` | `workflows/pr-prep.md` step 0 and 1c snippets | Consistent — upper-snake shell vars, same as sibling snippets |
| "Size gate" (quick-ref item label, replaces "Size check") | rule/term | "Size gate (hard cap …)" step 1a heading; "Dependent PR check" | `workflows/pr-prep.md:86`, `guides/pr-prep-quick-ref.md:12` | Consistent — quick-ref label now matches the step 1a heading |
| "fires above 400" | threshold phrasing | chat-synthesis ">400"; row 62 "fires above 400"; completion "at most 400"; quick-ref/completion-signals "≤ 400" | `workflows/pr-prep.md:93,153`, `chat-synthesis.md:141`, `docs/decisions/log.md:85` | Consistent — all five surfaces agree on the boundary (400 passes, 401 splits) |

No other new public names in the delta.

## Findings

#### 1. chat-synthesis still declares the ladder's size input as `git diff --stat`, which rule 2 no longer uses

**Severity:** Minor
**Location:** `skills/code-review/references/chat-synthesis.md:128`
**Move:** 3 (consumer contract: documentation drift inside one reference)
**Confidence:** High
**Legibility-target:** for-author

Evidence:

```
# skills/code-review/references/chat-synthesis.md:128 (excerpt)
Inputs are the rubric the synthesis just produced (counts of 🔴 / 🟡 rows and which critics ran, including the `## ⏭️ Skipped Core Critics` section) and the diff size from `git diff --stat`.

# skills/code-review/references/chat-synthesis.md:140-142
2. **split PR** — The unit is over the size gate in `workflows/pr-prep.md`
   step 1a (>400 changed lines outside `docs/`, counted with that step's
   command, so review artifacts don't count) AND ≥1 🔴 item exists (and rule 1
```

The ladder's input declaration says the size input comes from `git diff --stat` (all files, including `docs/reviews/`), while the only rule that consumes size now says to count with step 1a's `--numstat … ':(top,exclude)docs/'` command. The synthesizer reads the inputs line first and may compute the wrong number, which is exactly the review-artifact inflation rule 2's parenthetical says to avoid. Fact-check iter2 records the same line as Stale.

**Recommendation:** Change the input to "the unit's size per `workflows/pr-prep.md` step 1a's count (rule 2)", so the declared input and the rule agree.

#### 2. The waiver citation points at `questions.md`, but answered entries are archived to `questions-archive.md`

**Severity:** Minor
**Location:** `workflows/pr-prep.md:99`; `guides/pr-prep-quick-ref.md:11`; `docs/decisions/log.md:85`
**Move:** 1 / 3 (baseline: question lifecycle; contract a reader verifies against)
**Confidence:** High
**Legibility-target:** for-author

Evidence:

```
# workflows/pr-prep.md:99 (excerpt)
citing the `docs/working/questions.md` entry (`Q-NNN`, ANSWERED) where the user granted it; a waiver with no such entry is not a waiver.

# docs/working/questions.md:6-7
Answers move
the entry to `questions-archive.md`, so this file only ever holds what is still open.
```

The rule makes "an ANSWERED entry in `questions.md`" the existence test for a waiver ("a waiver with no such entry is not a waiver"), but the project's own lifecycle guarantees an ANSWERED entry does not stay in `questions.md` once `questions.sh archive` runs. A reviewer or agent checking the waiver at merge time will find no entry in the named file and, read literally, conclude there is no waiver. The quick-ref ("via an ANSWERED `questions.md` entry") and row 62 ("through an ANSWERED `questions.md` entry") repeat the file name. The `Q-NNN` ID is the stable handle, so the fix is wording only. Fact-check iter2 flags the same as Mostly accurate.

**Recommendation:** Name the entry by ID and both homes, e.g. "citing the `Q-NNN` entry where the user granted it (ANSWERED; in `docs/working/questions.md` or, once archived, `questions-archive.md`)". Apply the same wording in the quick-ref and row 62, or have them say "an ANSWERED `Q-NNN` entry".

#### 3. The quick-ref's waiver line omits the `Q-NNN` citation the other three surfaces require

**Severity:** Informational
**Location:** `guides/pr-prep-quick-ref.md:11`
**Move:** 3 (mirror drift)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: waiver recorded "with its `Q-NNN` entry" used in `workflows/pr-prep.md:99,153` and `guides/completion-signals.md:82`

Evidence:

```
# guides/pr-prep-quick-ref.md:11 (excerpt)
Only the user can waive the cap (via an ANSWERED `questions.md` entry); note the waiver in the PR description and suggest a file review order
```

Step 1a, its completion criterion, and completion-signals all require the PR description to cite the `Q-NNN`; the quick-ref only says "note the waiver". An agent working from the quick-ref alone would write a waiver note that fails the step 1a completion check. Low impact because the completion criterion catches it.

**Recommendation:** "note the waiver in the PR description with its `Q-NNN`" — can be folded into the Finding 2 edit.

## What Looks Good

- All six iteration-1 fixes land cleanly and the five size surfaces (step 1a prose, step 1a completion criterion, quick-ref, completion-signals, chat-synthesis rule 2, row 62) now state one boundary (fires above 400), one count (step 1a's command, `docs/` excluded) and one waiver owner (the user).
- Mirrors reference step 1a's command rather than re-stating it, which follows the one-owner convention (`review-fix-loop.md:7`).
- `BASE` defaults to `main` with a one-line comment for the stacked case, and 1b points back to it; the gate now composes with the stacked-PR path.
- The /away recording now matches the early split trigger verbatim and links to its anchor.
- Declined finding 7 has a matching override-log row with a reason.
- The separate 500-line thresholds (pre-mortem 1c, tech-debt trigger, SI Gate 1b) were correctly left untouched.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Ladder input still says `git diff --stat` | Minor | `skills/code-review/references/chat-synthesis.md:128` | High |
| 2 | Waiver cites `questions.md`, but ANSWERED entries are archived | Minor | `workflows/pr-prep.md:99`; `guides/pr-prep-quick-ref.md:11`; `docs/decisions/log.md:85` | High |
| 3 | Quick-ref waiver line omits `Q-NNN` citation | Informational | `guides/pr-prep-quick-ref.md:11` | Medium |

## Overall Assessment

The fix delta resolves every iteration-1 finding it took on, with no regressions, and the size-gate contract is now consistent across all mirrors. Two small wording issues remain: one stale input line in chat-synthesis left over from the rule-2 rewrite, and a waiver citation that names the file answered entries leave. Both are one-line fixes with no Breaking or Inconsistent consumer impact; neither should block merge.

## Goal-Alignment Note

- **Answered:** API/contract consistency of 49a3dbb..HEAD; verified iteration-1 findings 1–6 resolved and 7 declined with an override row; found 2 Minor and 1 Informational new issues, none blocking.
- **Out of scope:** `docs/reviews/*` artifacts (context only); commit b516af2's message wording ("Deletions still count, as the user's rule says"), which fact-check owns; SI Gate 1b and other 500-line thresholds, as in iteration 1.
- **Escalate:** nothing. Findings 1–3 are fix-in-place wording edits; no probes or processes were started.
