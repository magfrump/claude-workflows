# API Consistency Review — batch-feedback subagent routing

Commit: eb545b103fa2e55ec6deed43d775c4c2eea761c8

**Scope:** `git diff main...HEAD` on `feat/batch-feedback-subagent-routing` — adds `hooks/batch-feedback-routing-reminder.sh` (sibling of `hooks/dd-routing-reminder.sh`), CLAUDE.md decision-tree row 2 + "Batch fan-out" section + row renumber (old 2→3 … 10→11), a README hooks-listing entry, and two `docs/working/` artifacts (a wiring doc and a verify script).
**Date:** 2026-06-23
**Based on:** code-fact-check report (`docs/reviews/code-fact-check-report.md`), 16/16 verified, zero Incorrect/Stale. This review builds on that foundation and adds the consistency lens (sibling-hook divergence, cross-doc row-number referential integrity) the fact-check did not fully cover.

The three consumer-facing contracts in this diff are: (1) the hook's stdin/stdout/exit I/O contract and its parallelism with the dd sibling; (2) the CLAUDE.md decision-tree "row-number interface" that other docs cross-reference; (3) the README hooks-listing format.

---

## Baseline Conventions

**Hook script convention** (from `hooks/dd-routing-reminder.sh`, the prime sibling, and `hooks/log-usage*.sh`):
- Shebang `#!/usr/bin/env bash`; executable bit set (both new and old hooks are `-rwxr-xr-x`).
- Header block: one-line summary, mechanism paragraph, "Mandatory mitigations" list, `Input:`/`Output:` contract lines.
- No `set -e` (deliberate — internal failure must fall through to clean exit 0).
- `INPUT=$(cat)` → jq `.prompt // ""` extraction guarded by `command -v jq`, silent fallback to empty on missing-jq/malformed → `[[ -z "$PROMPT" ]] && exit 0`.
- A single uppercase regex var holding the match pattern (`ALLOWLIST` in dd).
- Match with `grep -iqE`; on match, `printf '%s\n'` exactly one reminder line; `exit 0` always.
- Reminder message format: `💡 Routing reminder: <one sentence> … (Non-blocking suggestion.)`.

**Settings wiring convention** (from `docs/working/scope-exception-dd-...md` and the log-usage hooks): each hook is a per-script symlink from `~/.claude/hooks/` into the checkout; wired as `bash $HOME/.claude/hooks/<script>.sh`.

**Decision-tree row-number "interface":** rows are numbered 1..N and referenced by number from prose elsewhere in CLAUDE.md and from `docs/` planning artifacts (`row 5`, `row 2`, etc.). Renumbering rows is a breaking change to every consumer that cites a number.

**README hooks-listing format:** `` - `hooks/<name>.sh` — <description> ``, one line per hook.

The batch hook honors the great majority of these. The findings below are the divergences.

---

## Name-Pattern Audit

New public names introduced by the diff, each against its closest existing neighbor(s):

| New name | Category | Closest existing neighbor(s) | Precedent | Verdict |
|---|---|---|---|---|
| `hooks/batch-feedback-routing-reminder.sh` | hook filename | `dd-routing-reminder.sh`, `log-usage.sh`, `log-usage-post.sh` | `*-routing-reminder.sh` in `hooks/` | **Consistent** — follows the `<topic>-routing-reminder.sh` shape the dd hook established. |
| `ENUM` (regex pattern var) | shell var | `ALLOWLIST` in `dd-routing-reminder.sh:47` | `ALLOWLIST` for the match-pattern var in `hooks/dd-routing-reminder.sh` | **Inconsistent** — sibling names this role `ALLOWLIST`; see Finding 2. |
| `emit()` | shell function | dd hook inlines the `printf …; (exit)` with **no helper** (`dd-routing-reminder.sh:52-54`) | No `emit()`/helper-function precedent in `hooks/` | **Divergent (new pattern)** — see Finding 1; no-precedent ⇒ severity floored. |
| `numbered`, `bullets` (count vars) | shell var | (no counting in dd hook) | No existing precedent in `hooks/` | **Acceptable** — lowercase locals for grep counts; no sibling pattern to match, this establishes one. |
| `💡 Routing reminder: … (Non-blocking suggestion.)` | output message string | dd hook's reminder string (`dd-routing-reminder.sh:53`) | `💡 Routing reminder: …(Non-blocking suggestion.)` prefix/suffix in `hooks/dd-routing-reminder.sh` | **Consistent** — same prefix and same `(Non-blocking suggestion.)` suffix. |
| CLAUDE.md row `2` ("Batch fan-out") | decision-tree row id | rows 1, 3–11 | numbered decision-tree rows in `CLAUDE.md` | **Consistent within CLAUDE.md**, but the renumber breaks external citations — see Finding 3. |

No category was empty. The two findings the audit surfaces are `ENUM`-vs-`ALLOWLIST` (Finding 2) and the `emit()` helper (Finding 1, floored to Informational for lack of precedent).

---

## Findings

#### 1. `emit()` helper present in batch hook, absent in dd sibling — siblings diverge in control-flow shape
**Severity:** Informational
**Location:** `hooks/batch-feedback-routing-reminder.sh:41-44` vs `hooks/dd-routing-reminder.sh:52-54`
**Move:** #7 (look for the asymmetry), #2 (naming)
**Confidence:** High
No existing precedent in `hooks/` (dd inlines `printf …; exit` with no helper; log-usage hooks have helpers but for logging, not emit-and-exit).

The batch hook factors the reminder-and-exit into an `emit()` function called from three branches (numbered/bullets/enum); the dd hook inlines a single `printf` with no helper because it has only one match path. This is a *defensible* divergence — the batch hook genuinely has three exit points and a helper reduces duplication, whereas dd has one. It is not a bug. But a maintainer who reads the two siblings expecting parallel structure (the diff explicitly markets "the same pattern as the sibling dd-routing-reminder.sh", `batch-feedback-routing-reminder.sh:12`, `CLAUDE.md:61`) will find the control flow differs. Because there is no established helper precedent to violate, this is floored to Informational per the no-precedent rule.
**Recommendation:** Accept as-is (the multi-branch structure justifies the helper). Optionally add a one-line comment at `emit()` noting "dd's single-match sibling inlines this; batch has three match paths so it factors out" to pre-empt the "why do these differ" question. No code change required.

#### 2. Match-pattern variable named `ENUM` where the sibling names the same role `ALLOWLIST`
**Severity:** Minor
**Location:** `hooks/batch-feedback-routing-reminder.sh:38` (`ENUM=…`) vs `hooks/dd-routing-reminder.sh:47` (`ALLOWLIST=…`)
**Move:** #2 (naming against the grain), #7 (asymmetry)
**Confidence:** Medium
Precedent: `ALLOWLIST` used for the match-pattern variable in `hooks/dd-routing-reminder.sh`.

Both hooks hold their "fire only on these phrasings" regex in a single uppercase var. The dd sibling calls it `ALLOWLIST` (and its header repeatedly frames detection as an "allowlist"). The batch hook calls the analogous var `ENUM` (for "enumeration phrasings"). The two are not wrong individually, but they name the identical structural role differently, so a maintainer grepping `ALLOWLIST` across `hooks/` to audit "what makes these reminders fire" will miss the batch hook's pattern. Note the batch hook *also* has two other detection branches (numbered/bullets) that `ENUM` does not cover, so `ENUM` is arguably the narrower-but-accurate name for just the phrasing branch — a mitigating factor that keeps this Minor rather than Inconsistent.
**Recommendation:** Either rename `ENUM` → `ENUM_ALLOWLIST` (or `PHRASE_ALLOWLIST`) to keep the `ALLOWLIST` grep-anchor the sibling established, or leave `ENUM` and accept the small divergence. Low stakes; flag for author preference rather than mandating.

#### 3. Decision-tree renumber breaks stale row-number citations in pre-existing `docs/` artifacts
**Severity:** Minor
**Location:** `docs/superpowers/plans/2026-05-18-superpowers-integration.md:453,612,678` and `docs/working/dd-skill-trigger-shim-plan.md:26` (consumers); `CLAUDE.md` table (the renumbered interface)
**Move:** #3 (trace the consumer contract)
**Confidence:** High
The diff renumbers the decision tree and correctly updates every *live* reference inside CLAUDE.md (the lone "row 4"→"row 5" prose update, the row-7-vs-row-2 distinction, the composition note) — fact-check confirmed no dangling refs remain *in CLAUDE.md*. But row numbers are cross-referenced from other docs, and a grep beyond CLAUDE.md finds two pre-existing artifacts now pointing at the wrong row:
- `docs/superpowers/plans/2026-05-18-superpowers-integration.md` says "decision tree row 5 (RPI)" three times (lines 453, 612, 678). RPI was row 5 before this diff; it is **row 6** now. Those references are stale.
- `docs/working/dd-skill-trigger-shim-plan.md:26` says "CLAUDE.md row 2" meaning the divergent-design row. DD was row 2 before; it is **row 3** now.

These are *planning/working artifacts* (a dated integration plan and a shim plan), not live routing contracts the harness reads, so the consumer impact is low — no behavior breaks, and a reader hitting "row 5 (RPI)" still has the parenthetical "(RPI)" / "(divergent-design)" disambiguator to recover the intent. But they are exactly the cross-doc referential-integrity drift the renumber introduces, and they will mislead anyone who follows the number. This is the structural reason raw row numbers are a fragile "interface": each renumber silently breaks external citations.
**Recommendation:** Update the four stale references (3 in the superpowers plan, 1 in the shim plan) to the new numbers, OR — better long-term — note in CLAUDE.md that historical `docs/` plans reference pre-renumber row numbers and should be read by the parenthetical label, not the digit. Lowest-effort acceptable fix: leave the dated `docs/superpowers/plans/` artifact (it is a historical snapshot) and fix only the still-active `docs/working/dd-skill-trigger-shim-plan.md:26`. Author's call on how much of the historical doc to touch.

#### 4. README "Hooks (Claude Code PreToolUse hooks)" header mislabels the `UserPromptSubmit` hooks it now lists
**Severity:** Minor
**Location:** `README.md:104` (header) vs `README.md:106-107` (the new + dd entries)
**Move:** #3 (consumer contract / documentation drift), #7 (asymmetry between header and entries)
**Confidence:** High
The README hooks section header reads "Hooks (Claude Code **PreToolUse** hooks)", but the new `batch-feedback-routing-reminder.sh` entry (and the dd entry above it) are `UserPromptSubmit` hooks — the entries themselves say so. So the section now lists three hooks of which only `log-usage.sh`/`log-usage-post.sh` are PreToolUse; the two routing reminders are UserPromptSubmit, contradicting the header. This is a pre-existing drift (the dd entry already sat under the wrong header), but this diff adds a second UserPromptSubmit entry, widening the mismatch rather than correcting it. The new entry's *line format* matches the existing `log-usage.sh` style correctly (`` - `path` — description ``), so the listing-format contract (contract #3) is honored; only the section header is wrong.
**Recommendation:** Broaden the header to "Hooks (Claude Code PreToolUse + UserPromptSubmit hooks)" or just "Hooks". One-line fix; cheap to do while this file is already being edited.

---

## What Looks Good

- **I/O contract is a faithful mirror of the sibling.** `INPUT=$(cat)`, jq-`.prompt // ""` with `command -v jq` guard and silent malformed-input fallback, `[[ -z "$PROMPT" ]] && exit 0`, `exit 0` on every path — all identical to `dd-routing-reminder.sh`. The error-consistency move (#4) finds no divergence: jq-missing and malformed-JSON both stay silent in both hooks, never block.
- **Idempotency/safety (move #9):** the hook is side-effect-free and reads stdin only, consistent with the sibling. Safe to fire on every submit.
- **Reminder string format** keeps the `💡 Routing reminder:` prefix and `(Non-blocking suggestion.)` suffix verbatim from the sibling — the consumer-visible output contract is consistent.
- **Header block** matches the sibling's structure (summary / mechanism / "Mandatory mitigations" / `Input:`/`Output:`), and even cross-references the sibling explicitly.
- **CLAUDE.md internal referential integrity** is clean: the row-7-vs-row-2 distinction, the "Batch fan-out" section, and the composition-paths bullet all use the *new* numbers consistently; the lone live "row 4"→"row 5" update was made. The renumber was done carefully *within* the file.
- **README entry format** for the new hook matches the `log-usage.sh` entry style exactly.
- **Settings wiring shape** documented in `wire-batch-feedback-reminder.md` matches the established per-script-symlink + `bash $HOME/.claude/hooks/<script>.sh` convention, and correctly adds the batch hook *alongside* dd in one `UserPromptSubmit` array rather than replacing it (additive, per the mitigations).

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 4 | README header says "PreToolUse" but lists UserPromptSubmit hooks | Minor | `README.md:104` vs `106-107` | High |
| 3 | Renumber breaks stale row-number citations in `docs/` plan artifacts | Minor | `docs/superpowers/plans/2026-05-18-…:453,612,678`; `docs/working/dd-skill-trigger-shim-plan.md:26` | High |
| 2 | Match-pattern var `ENUM` where sibling names it `ALLOWLIST` | Minor | `batch-…sh:38` vs `dd-…sh:47` | Medium |
| 1 | `emit()` helper present in batch, absent in dd sibling (control-flow asymmetry) | Informational | `batch-…sh:41-44` vs `dd-…sh:52-54` | High |

---

## Overall Assessment

This change is **strongly consistent** with the conventions the codebase has already established, and all findings are **fixable in place** — none requires a convention survey or rethink. The batch hook is a near-exact structural mirror of its `dd-routing-reminder.sh` sibling on every contract that matters to a consumer: the stdin/stdout/exit-0 I/O shape, the jq-with-silent-fallback error handling, the `💡 Routing reminder: … (Non-blocking suggestion.)` output format, the header structure, the additive settings wiring, and the README entry format. The two sibling-hook divergences are benign: `emit()` is justified by the batch hook's three match paths (Informational, no precedent to violate), and `ENUM`-vs-`ALLOWLIST` is a low-stakes naming drift that only mildly weakens a maintainer's grep (Minor). The one genuine cross-doc consequence is the decision-tree renumber: CLAUDE.md's *internal* references are all correctly updated, but two pre-existing `docs/` planning artifacts now cite stale row numbers (RPI "row 5"→6, DD "row 2"→3). Consumer impact is low because those are historical/working docs with parenthetical labels that preserve intent, but it is the textbook fragility of a numeric interface and worth a quick fix to the still-active shim plan at minimum. The README "PreToolUse" header mislabel is pre-existing but widened by this diff and is a one-line fix. Net: ship-ready after the optional Minor fixes; nothing here is a blocker.

## Goal-Alignment Note
- Answered: yes — sibling-hook consistency and cross-doc row-reference integrity both audited.
- Out of scope: hook *correctness*/regex behavior (fact-check verified the 15-case suite passes; this review covers consistency, not whether detection is right) and live `settings.json` state (verified by fact-check).
- Escalate: the four stale row-number citations in `docs/superpowers/plans/2026-05-18-superpowers-integration.md` and `docs/working/dd-skill-trigger-shim-plan.md` are outside this diff — the orchestrator should decide whether to fix them in this PR or note them as known drift, since editing untouched docs widens the diff.
- Questions I would have asked: omitted — scope was clear.
