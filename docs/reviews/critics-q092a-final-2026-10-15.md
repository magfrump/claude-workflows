Commit: cebb32cd

# Critics (final confirming pass): Q-092 unit 1 (fix/q092a-drop-deny-option)

**Scope:** `git diff 00a27a2f..cebb32cd -- ':(exclude)docs/reviews'`: `hooks/auto-approve-allowed-commands.sh`, `test/auto-approve-allowed-commands.bats`, `docs/working/plan-q092-drop-hook-deny-reader.md`
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report-q092a-final.md` (Commit 5ba83a3a; the cebb32cd fixes are docs, a test title and a comment)
**Roles, in sequence:** performance-reviewer, api-consistency-reviewer, architecture-review
**Suite:** `timeout 600 bats test/auto-approve-allowed-commands.bats` at cebb32cd: 43/43 pass.

Accepted residuals from earlier passes (quote and backslash spellings and denied subcommands now rest on Claude Code's matcher; globs got past both matchers before) are not re-filed.

---

## 1. Performance Review

### Data Flow and Hot Paths

The hook runs once for every Bash tool call (PreToolUse). Per call it reads settings once (one `jq` process over at most three files), parses the command with shfmt, and checks each extracted command against the allow prefixes. Until this unit, `matches_deny` also ran on the raw command and on each extracted command. Each run did a de-quote substitution, a `while` loop over `PARAM_DEFAULT_RE`, and a glob loop over `DENY_GLOBS`. The unit deletes the de-quote step and the `PARAM_DEFAULT_RE` loop, keeps one glob match per rule, and removes the second `jq` pass that `--deny` ran (test-only). Data sizes: tens to a few hundred rules, and a handful of extracted commands per call. Path temperature: hot per tool call, but N is small and bounded by the settings files.

Measured on this host (2026-10-15, load average about 2-3, 20 approved calls per round, a 201-allow / 21-deny settings file, command `git status | cmd5 x && cmd7 y`): the unit-1 hook averaged 93-94 ms in two isolated rounds and 106-135 ms in five rounds interleaved with the unit-2 hook. That is the same range as the header's existing 110-136 ms figure. Process spawn dominates, not matching.

### Findings

No findings.

### Endorsements (evidence-gated)

- Removing the de-quote rendering also removes a `while [[ "$dq" =~ $PARAM_DEFAULT_RE ]]` loop that ran once per deny check, on the raw command and on every extracted command. `matches_deny` now does one glob compare per rule. [read: hooks/auto-approve-allowed-commands.sh:294-309 at cebb32cd, and the removed lines in the unit diff]
- `load_rules` always makes exactly one `jq` call for settings now. The `--deny` branch's second `jq` pass is gone, and with it the `CUSTOM_DENY_SET` condition that could skip the settings read. [read: hooks/auto-approve-allowed-commands.sh:265-288 at cebb32cd]

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| none | | | | |

### Overall Assessment

The unit only removes per-call work. Timing is the same as the documented baseline, within noise. No profiling is needed.

---

## 2. API Consistency Review

### Baseline Conventions

The hook's consumer surface has three parts. Its CLI takes `--debug` and `--permissions JSON`, and a catch-all `*) shift` has always skipped unknown words. Its stdout is either empty or the single `allow` JSON object. It reads settings from three files, documented in the header (SETTINGS SOURCES, RULE SYNTAX). The one production caller is `hooks/wiring.json:80` (`bash {{CLAUDE_DIR}}/hooks/auto-approve-allowed-commands.sh`, no options). `--deny` had no caller in the repo except the tests (fact-check Claim 28a, r1).

### Name-Pattern Audit

This unit introduces no new public names. It removes one: the `--deny JSON` option. Internal names removed: `CUSTOM_DENY`, `CUSTOM_DENY_SET`, `PARAM_DEFAULT_RE`, `dq`.

| Removed name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--deny JSON` | CLI flag | `--permissions JSON`, `--debug` | `hooks/auto-approve-allowed-commands.sh:13-16, 339-355` | Removal only. A stale `--deny` now falls into the existing catch-all `*) shift`, which matches how the hook already treats unknown words, and a test pins it (`the hook ignores a --deny argument`). |

### Findings

No findings.

### What Looks Good

- The `--permissions` help line now says the option replaces only the allow lists (deny is still read from the files in this unit), which matches `load_rules`. Unit 2 changes both the behaviour and the line together.
- The RULE SYNTAX table's `Bash(ls *)` row now gives the literal-prefix behaviour that the `rule table: Bash(ls *) is a literal prefix` test pins.
- Production stdout is unchanged. The new stdout test pins "empty or exactly the allow decision".

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| none | | | | |

### Overall Assessment

This is a removal of a test-only flag, with no production caller. Its fallback into the catch-all is consistent with existing behaviour and is tested. No consumer is affected.

---

## 3. Architecture Review

**Scope check:** in scope (public API: a CLI option is removed, and the deny check's documented contract shrinks).

### Dependency Map

`hooks/wiring.json` invokes the hook. The hook depends on `jq`, `shfmt`, `git rev-parse` and the three settings files. `devcontainer-config/link-claude-home.sh` writes the global settings file that the hook resolves the same way (DEST parity). No module imports the hook, and no dependency direction changes. The unit is a stacked intermediate state: the settings-file deny reader stays, and the header says unit 2 removes it.

### Findings

No findings.

### What Looks Good

- The intermediate state hangs together. `load_rules` still has one settings list, one jq pass and one parser for both lists. Only the test-only override and the de-quote layer go.
- The header stays the single statement of the deny contract (WHAT THE DENY CHECK GUARANTEES). The residual list moves the quote and backslash spellings into it, and no copy elsewhere goes stale. `rg "WHAT THE DENY CHECK"` outside docs/reviews and archives hits only the hook at this commit's successor (unit 2 replaces it there and in log row 53).

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| none | | | | |

### Overall Assessment

The unit keeps the hook's structure intact and narrows its surface. Nothing in it needs restructuring.

---

## Goal-Alignment Note

The goal is to land Q-092 as two stacked, clean units. Unit 1 removes `--deny` and the de-quoted match and keeps the settings-file deny reader for unit 2. The code does that, the 43 tests pass, and none of the three lenses finds anything new beyond the accepted residuals. Unit 1 is clean from the performance, API-consistency and architecture side.
