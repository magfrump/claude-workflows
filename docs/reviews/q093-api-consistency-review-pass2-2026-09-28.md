# API Consistency Review — q093-cc-push-self-commondir, pass 2

**Scope:** `git diff 2c8163f..b9f6cc4` (`devcontainer-config/cc-push.sh`, `test/cc-push.bats`, `docs/working/plan-q093-cc-push-self-commondir.md`); pass 1 (`q093-api-consistency-review-2026-09-28.md`) is context only
**Date:** 2026-09-28
**Based on:** `docs/reviews/q093-code-fact-check-report-pass2.md` (12 Verified, 1 Mostly accurate: plan wording, since fixed)

## Baseline Conventions

The consumer-facing surface is cc-push's refusal text, plus the two places that describe the same rule: the `--help` header (`cc-push.sh:85-89`) and `guides/cc-isolated-usage.md:255-260`. Sibling `die` messages in `check_checkout` (`cc-push.sh:288-334`) follow a `<path> <what>: <why>. <remedy>` shape. Some of them use a parenthetical gloss, for example `:334` "(a HEAD next to objects/, or a commondir file)". Tests match on the stable fragment `commondir exists` (`test/cc-push.bats:258, 292-309`). Bounded external calls elsewhere in the script use `timeout N <cmd>` with no flags (`cc-push.sh:228`, `install.sh:1239`).

## Name-Pattern Audit

This delta adds no new public names: no flags, functions, exported variables or config fields. The only surface change is the wording of one existing refusal message, which is audited under Findings and What Looks Good. `commondir_is_self` is an internal helper that pass 1 already audited, and it is unchanged apart from its read.

## Findings

#### 1. The header still says a commondir "names another object store"; the message now says "can name"

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:86-87`
**Move:** 3 (documentation drift)
**Confidence:** High

Header: "holds a commondir, objects/info/alternates or objects/info/http-alternates file (each names another object store; the one exception is a commondir that is a regular file holding exactly `.` or `.\n` …)". The refusal message (`:295`) now hedges to "it can name another repository", because some refused spellings (`./`, `.\r\n`, the absolute path) actually name `.git` itself. The header avoids a false statement only by carving out the one accepted form, so a careful reader could still conclude that every other commondir names somewhere else. The two texts do not contradict each other on what is accepted, which is the part operators act on.

**Recommendation:** Optional: "each can name another object store". Not a blocker.

#### 2. Pass-1 finding 2 (`$run_main` remedy) and finding 4 (Q-091 cite) remain open

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:284, 295`; `guides/cc-isolated-usage.md:260`
**Move:** 4 (error consistency) / 3
**Confidence:** High

Both were marked optional in pass 1, and this delta intentionally leaves them alone. For a stray non-self commondir in the main checkout, the remedy still says "Run it on the main checkout". They are recorded here only so the merge decision can see them.

**Recommendation:** None required for merge.

## What Looks Good

- **Pass-1 finding 1 is resolved.** The message now reads "The only one accepted is a regular file holding exactly `.`, or `.` and a newline: .git itself." It matches the guide ("a regular file holding exactly `.` (or `.` and a newline)", `cc-isolated-usage.md:258-259`) and the header ("a regular file holding exactly `.` or `.\n`", `cc-push.sh:88-89`) on all three points: regular file, "exactly", and both forms. The lead is softened to "it can name another repository", as recommended.
- The stable `commondir exists (a linked worktree's layout):` prefix and the trailing `$run_main` are unchanged, so every test matcher and any operator muscle memory still apply. The parenthetical gloss has sibling precedent (`:334`).
- **Pass-1 finding 3 is resolved.** The test comment (`cc-push.bats:262-266`) now splits the refused spellings into those git reads as elsewhere or as no repository (`..`, ` .`, `.x`) and those git also reads as self (`./`, `.\n\n`, `.\r\n`, `.\0`, the absolute path), which agrees with the helper comment (`cc-push.sh:266-267`).
- `timeout 5 head …` follows the script's existing bare `timeout N` form (`:228`), with a shorter bound that suits a 2-byte local read.
- The plan doc quotes the shipped message and now lists the refused spellings the tests actually exercise. This is a working doc, so it is not consumer surface.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Header says a commondir "names" another store; message says "can name" | Informational | `devcontainer-config/cc-push.sh:86-87` | High |
| 2 | Pass-1 optional items 2 and 4 remain open | Informational | `cc-push.sh:284, 295`; `cc-isolated-usage.md:260` | High |

## Overall Assessment

This delta fixes the two pass-1 consistency findings that mattered: the message now states the same two accepted forms as the header and the guide, and the test comment now agrees with the helper. Nothing that consumers match on has changed. The remaining items are optional wording polish. The branch is consistent enough to merge.
