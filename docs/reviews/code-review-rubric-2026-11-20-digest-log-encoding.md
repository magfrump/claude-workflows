Commit: f8dd7db9
# Code Review Rubric

**Scope:** fix/digest-log-encoding, `git diff f48a1c2b...f8dd7db9` (f8dd7db9) | **Reviewed:** 2026-11-20 | **Status:** iteration 1: 🟢 PASSES (0 red, 0 amber)

Pipeline: one read-only reviewer covering code-fact-check, security/reliability and test checks, with executed git probes (git 2.39.5) in the review's scratch dir. The diff adds one config pair to `HARDEN` and drops one per-call flag, so the full parallel critic set was not dispatched (S2).

## 🔴 Must Fix

| ID | Finding | Domain | Severity | Source | Location | Status | Author note |
|---|---|---|---|---|---|---|---|

## 🟡 Must Address

| ID | Finding | Domain | Severity | Source | Location | Status | Author note |
|---|---|---|---|---|---|---|---|

## 🟢 Consider

| ID | Finding | Domain | Source | Location | Status | Author note |
|---|---|---|---|---|---|---|
| C1 | In a checkout that sets `i18n.commitEncoding` to a non-UTF-8 encoding, `--check`/`--status` marker reads now get UTF-8 where they got that encoding; the strict-UTF-8 marker-body check now parses them. Intended direction. | Reliability | reviewer, executed | `scripts/lib/dev-cycle-read.sh:335` | Acknowledged | Covered in the research doc's safety section. |

## Verified claims

- No repo setting either key: output with and without the pin is byte-identical for `%s`, `%B` and `%cs %H %h %ad %s`, via `git log` and `git rev-list --format`, including a commit with an `encoding ISO-8859-1` header and one with invalid UTF-8 bytes (executed).
- `landings.sh` is sourced only by `dev-cycle.sh`, after `git_harden`; with the old lib and the new `landings.sh`, the landings UTF-16 case fails, so the move is guarded (executed).
- The new `dev-cycle.bats` case fails on the old code (subject printed as `caf�   �n�code`) and passes on HEAD (executed).
- `build-loop.sh`'s `gate_git` keeps `GIT_CONFIG_COUNT` (`callervar`), so the pin reaches `gate_repo`, which sets no i18n key.
