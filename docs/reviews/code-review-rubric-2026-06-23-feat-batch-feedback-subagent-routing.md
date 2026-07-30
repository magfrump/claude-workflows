# Code Review Rubric

**Commit:** eb545b103fa2e55ec6deed43d775c4c2eea761c8
**Scope:** `feat/batch-feedback-subagent-routing` vs main (5 files, +227/−10) | **Reviewed:** 2026-06-23 | **Status: ✅ PASSES REVIEW**

---

## 🔴 Must Fix

None.

| # | Finding | Domain | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — |

---

## 🟡 Must Address

None.

| # | Finding | Domain | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — |

---

## 🟢 Consider

Advisory. None block merge. Ordered by practical value.

| # | Finding | Source | Legibility-target | Considered overrides |
|---|---|---|---|---|
| C1 | **Hook fires on every `UserPromptSubmit` event, including agent/tool notifications** — observed firing 6× on this review's own task-notifications. **RESOLVED — Won't-Fix (intended), 2026-06-23.** The reminder targets the *model*, not the human, so there is no alert-fatigue path; non-human submits enumerating independent results are themselves valid fan-out points; cost is ~85 tokens/firing (negligible). Broad firing is preferred; documented as intentional in the hook header. | Security (Low) + orchestrator observation | for-author | `#35` Won't-Fix (intended) — see override-log |
| C2 | **ENUM fallback `grep -E` runs a second time on non-matching prompts when `grep -P` is present** — the fallback is gated on the PCRE pass's *match result*, not on `grep -P` *availability*, so the common case (`-P` present, no match) scans the prompt twice. Fix: run the ERE branch only when the PCRE pass errored (exit ≥2), not when it merely didn't match. | Performance (Low) | for-author | — |
| C3 | **README hooks section header says "PreToolUse hooks" but lists two `UserPromptSubmit` hooks** (`README.md:104` vs `106–107`). Pre-existing mislabel widened by this diff. One-line fix (e.g., "Claude Code hooks"). | API-consistency (Minor) | for-author | — |
| C4 | **Renumber left stale row citations in untouched `docs/` artifacts** — `docs/superpowers/plans/2026-05-18-superpowers-integration.md:453,612,678` cite "row 5 (RPI)" (now row 6); `docs/working/dd-skill-trigger-shim-plan.md:26` cites "row 2" for DD (now row 3). Low impact (parenthetical labels preserve intent), but textbook numeric-interface fragility. Minimal fix: the still-active shim plan. The dated integration plan is a historical artifact — prefer leaving it or making references number-independent. | API-consistency (Minor) | for-author | — |
| C5 | **`(?:`-stripping `grep -E` fallback is coupled to the ENUM constant** — `"${ENUM//(\?:/(}"` only stays correct if every `(?:` group in ENUM tolerates the marker being stripped. A future editor adding another non-capturing group could silently break the ERE fallback. Add a comment documenting the coupling. | Security + API-consistency (Informational) | for-author | — |
| C6 | **Sibling-hook naming drift: `ENUM` vs dd's `ALLOWLIST`; `emit()` helper present here, inlined in dd.** Both benign — the batch hook has 3 detection paths (so a single `ALLOWLIST` name wouldn't fit, and `emit()` dedupes the 3 exits), whereas dd has one. No precedent violated. Noted for deliberateness, not correction. | API-consistency (Minor/Informational) | for-author | — |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| — | — | — | — | — |

---

## ✅ Confirmed Good

| Item | Verdict | Source | Legibility-target |
|---|---|---|---|
| No command/argument injection — prompt routed only as grep **stdin**, never argv/`eval` (the `printf '%s' "$VAR" \| grep` idiom is load-bearing) | ✅ Confirmed (empirically: `$(…)`, backticks, `--version`, leading `-`, `; cat /etc/passwd #` all exit 0, no side effects) | Security | for-orchestrator-synthesis |
| No ReDoS — every ENUM alternative is line-anchored or width-bounded (`.{0,N}`); ~960 KB adversarial input scans linearly <60 ms | ✅ Confirmed | Security + Performance | for-orchestrator-synthesis |
| Fail-safe on jq-missing / malformed JSON / empty prompt; always exits 0 (non-blocking) | ✅ Confirmed | Security + Fact-check | for-orchestrator-synthesis |
| CLAUDE.md table renumbered correctly (1–11, no gaps/dupes); lone "row 4"→"row 5" prose ref updated; no dangling refs *inside CLAUDE.md*; row 7 distinguished from row 2 | ✅ Confirmed | Fact-check | for-orchestrator-synthesis |
| Batch hook is a near-exact contract mirror of `dd-routing-reminder.sh` (stdin/stdout/exit-0, jq-with-silent-fallback, output format, additive wiring, README entry style) | ✅ Confirmed | API-consistency | for-orchestrator-synthesis |
| Both skills named in the Batch fan-out section (`superpowers:dispatching-parallel-agents`, `superpowers:using-git-worktrees`) are real installed plugin skills | ✅ Confirmed | Fact-check | for-orchestrator-synthesis |
| Wiring live & verified: `.hooks.UserPromptSubmit` holds the two-command block; both `~/.claude/hooks/*-reminder.sh` symlinks resolve; 15-case harness prints ALL PASS | ✅ Confirmed | Fact-check | for-orchestrator-synthesis |

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

| Critic | Reason | Signal |
|---|---|---|
| — | — | — |

Contextual critics not auto-selected: `test-strategy` (a 15-case verification harness was added alongside the hook), `dependency-upgrade` (no manifest changes), `tech-debt-triage` (<10 files, <500 lines), `ui-visual-review` (no UI), `architecture-review` (additive leaf hook + config rows; no module-structure/public-API/data-model/cross-cutting change).

---

To pass review: all 🔴 items resolved (none), all 🟡 items fixed or noted (none). 🟢 items optional.
