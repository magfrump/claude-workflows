Commit: 12f96cd

# API Consistency Review — review/q065 (Q-065 [1])

**Scope:** `git -C /workspace/.claude/wt-q065 diff main...HEAD` (main 6405e43 → HEAD 12f96cd), full branch
**Date:** 2026-09-28
**Based on:** `docs/reviews/q065-code-fact-check-report.md` (Stage 1, k=1)

## Baseline Conventions

- `scripts/lib/*.sh` are sourced shell libraries with a direct-execution guard and a header `Functions:` list naming each public function (`scripts/lib/si-input.sh:8-11`). Public functions are `snake_case` verb-noun (`parse_si_input`, `parse_si_priority_hypotheses`); internal helpers carry a leading underscore (`_save_si_section`, `_trim_blank_lines`).
- The declared consumer of `si-input.sh` is `scripts/self-improvement.sh` (header line 6). It sources the library and calls only `parse_si_input` (`scripts/self-improvement.sh:231`, `:493`, per fact-check Claim 1).
- The installed surface: `devcontainer-config/install.sh:135` and `devcontainer-config/link-claude-home.sh:50` stage/link the whole `scripts/` directory into `~/.claude/scripts`, so `si-input.sh` is reachable at `~/.claude/scripts/lib/si-input.sh` in every project. The documented reasons for installing `scripts/` name only three installed-path consumers: `lib/skill-paths.sh` (sourced by `hooks/log-usage.sh`), `lite-review.py` and `questions.sh` (`devcontainer-config/link-claude-home.sh:43-49`, `devcontainer-config/install.sh:125-130`). `si-input.sh` is not among them.
- Function-existence contract tests live in `test/function-inventory.bats`; it lists `parse_si_input` (`:52-53`, `:69`) and never listed the deleted function.
- Test files are named `<subject>.bats`, with an `si-` prefix for self-improvement units (`si-clean-state.bats`) and `parse-…` for parser units (`parse-si-priority-hypotheses.bats`).

## Name-Pattern Audit

The diff introduces no new public function, type, flag or schema name. The one new name is a test file:

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `si-input-parse-comments.bats` | test file | `si-input-rejected-history.bats` (deleted), `si-clean-state.bats`, `parse-si-priority-hypotheses.bats` | `test/si-*.bats`, `test/parse-si-*.bats` | Consistent — keeps the `si-input-` prefix of the file it replaces |

Removed public name: `prepend_si_input_rejected_history` (function, `main:scripts/lib/si-input.sh:214`). Consumer-contract analysis below.

## Findings

No findings.

Consumer-contract trace for the removal (move #3 / #6), recorded so the "no findings" verdict is auditable:

- **In-repo callers:** none at main or HEAD, and none ever (fact-check Claim 1: `git log --all -S` shows 06903d6 added only the definition and tests). A HEAD grep of `si-input` outside `archive/` and `docs/` returns only the library itself, `self-improvement.sh` (which calls `parse_si_input` only), `test/parse-si-priority-hypotheses.bats`, and an unrelated string in `si-morning-summary.sh:1676`.
- **Installed consumers (`~/.claude/scripts/lib/si-input.sh`):** the file is reachable in every project through the wholesale `scripts` link, but no skill, workflow, guide, pattern, or `global-instructions` file references `lib/si-input` (grep returned nothing), and the installer's documented installed-path contract names only `skill-paths.sh`, `lite-review.py` and `questions.sh`. The function was never documented outside the library's own header and never wired into a caller, so there is no consumer whose code could break. Removing it is not a breaking change in practice; no version or migration note is warranted.
- **Header contract:** the `Functions:` list (`scripts/lib/si-input.sh:8-11`) drops the entry together with the definition, so the header still matches the file's public functions exactly (fact-check Claim 5).
- **Remaining public contract unchanged:** `parse_si_input` and `parse_si_priority_hypotheses` keep their signatures, exports and return codes; the diff touches only the deleted block and the header.

## What Looks Good

- The deletion is complete: definition, header entry and dedicated tests go together, leaving no dangling public name and no stale entry in the header's function list.
- The two `parse_si_input` tests that lived in the deleted file are kept byte-identical in a file named after the unit they test, with a provenance note in the header.
- `test/function-inventory.bats` needed no change, because the deleted function was never part of the inventoried contract.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | High |

## Overall Assessment

The change is consistent with the codebase's API conventions. It removes a public-by-naming shell function that had no caller in the repo and no documented consumer on the installed `~/.claude/scripts` surface, and it updates the library header in the same commit. Consumer impact is nil as far as the repo and its install contract can show. The one residual gap is test coverage, not API shape. `parse_si_input` still discards content above the first `##` heading, since `current_section` is empty and `_save_si_section` no-ops (`scripts/lib/si-input.sh:44`, `:76`, `:103-113`), but the only assertion of that behaviour went with the deleted file (fact-check Claim 2). That belongs to test-strategy/synthesis, not to this critic.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the output path named in your role-specific tail, structured per your skill, ending with a Goal-Alignment Note."
- **Answered:** Whether any consumer, in-repo or installed via `devcontainer-config/install.sh` / `link-claude-home.sh` into `~/.claude/scripts`, could depend on `prepend_si_input_rejected_history`. None found. The header contract stays accurate, and the one new name (the test file) follows the existing naming.
- **Out of scope:** Callers outside this repo (other projects or ad-hoc shells sourcing `~/.claude/scripts/lib/si-input.sh`). I can't observe these, but nothing documents such use. Test coverage of `parse_si_input`'s pre-heading preamble handling is also out of scope here.
- **Escalate:** (for orchestrator synthesis) The coverage gap from fact-check Claim 2 still stands. `parse_si_input`'s discard of a pre-heading comment/preamble is now unasserted. I'd suggest a parse-only test in `test/si-input-parse-comments.bats`. I'm not filing it as an API finding because the contract itself is unchanged.
