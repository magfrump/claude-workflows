Commit: ed06dec1

# Performance Review — Q-092 unit 2 (fix/q092-drop-hook-deny-reader)

**Scope:** `git diff 1a831ffe..ed06dec1` (hooks/auto-approve-allowed-commands.sh, hooks/wiring.json, test/auto-approve-allowed-commands.bats, test/link-claude-home-wiring.bats, guides/bare-host-hook-wiring.md, docs/decisions/log.md). Unit 1 (00a27a2f..1a831ffe) is context only.
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-q092b-2026-10-15.md

## Data Flow and Hot Paths

The hook runs on **every Bash tool call** (`hooks/wiring.json:76-81`, no options), so `main` and `load_rules` are a **hot path**. The settings data is small: three files, with 12 deny and 20 allow rules in this checkout.

What unit 2 changes on that path:
- **Deny rules are no longer compiled.** At 1a831ffe, `load_rules` passed every `D<TAB>` record to `add_deny_rule`. That function escaped the rule one character at a time in a bash `for ((i...))` loop (1a831ffe `:243-260`), so it cost O(total deny-rule characters) per call, before any command was looked at. Both the loop and `matches_deny`'s O(deny rules × extracted commands) glob scan are deleted.
- **The settings jq gains a deny shape check.** `any(.[]; type != "string")` (`hooks/auto-approve-allowed-commands.sh:145`) is O(deny rules) inside the jq process that was already running, and it starts no new process.
- **Under `--permissions`, settings are not read** (`:219-230`). That saves one `git rev-parse` and one `jq` per call, but only for test calls, because the wired call passes no options.
- The production call still starts the same processes: input `jq`, `git rev-parse`, settings `jq`, `perl`, `shfmt`, shape `jq`, extraction `jq`.

Measured per call. The script is in `/home/node/.claude/jobs/00bcf178/tmp/q092/agents/performance-review-q092a-2026-10-15/bench.sh`: 20 sequential runs per cell after one warm-up, on this container, 2026-10-15. Each run used a non-repo project dir with 4 allow rules, and `CLAUDE_CONFIG_DIR` pointed at a 12-rule or 200-rule deny file. Noise is about ±5 ms.

| command | deny rules | U1 1a831ffe | U2 ed06dec1 |
|---|---|---|---|
| `git status` (allow) | 12 | 85.9 ms | 82.1 ms |
| `git status` (allow) | 200 | 109.5 ms | 85.8 ms |
| `ls -la \| grep foo \| head -5` (allow) | 12 | 95.5 ms | 94.3 ms |
| same | 200 | 126.7 ms | 95.6 ms |
| `cat x` (no rule, falls through) | 12 | 88.3 ms | 86.0 ms |
| same | 200 | 116.0 ms | 89.2 ms |
| `--permissions` path, `git status` | 12 | 116.8 ms | 93.6 ms |

At 200 deny rules, unit 2 removes about 24-31 ms per call. That cost scaled with the length of the deny list, and per call it is now flat. At this checkout's 12 rules the gain is about 1-4 ms, within noise. The `--permissions` gain of about 23 ms is the skipped `git` and `jq`, and it applies to tests only. All decisions matched the expected output: allow, allow, none.

## Findings

No findings.

## Endorsements

- Checkable claim: per-call hook latency no longer grows with the length of `permissions.deny`. With 200 deny rules, `git status` measured 109.5 ms at 1a831ffe and 85.8 ms at ed06dec1, against 85.9 → 82.1 ms at 12 rules (bench script above). [unverified — submitted as claim]
- `load_rules` now hands only allow records to `add_allow_rule` and calls nothing per deny rule. The per-character escape loop and the glob scan in `matches_deny` are deleted, not moved somewhere else. [read: hooks/auto-approve-allowed-commands.sh:203-232]
- Failure handling is cheaper and no less safe. On a failed settings read, `load_rules` returns before `add_allow_rule` runs (`:225-229`), so `main` exits at the empty-prefix check (`:304-307`) before `perl`, `shfmt` or either extraction `jq` start. That is the same early exit the old `DENY_ALL` path took at the raw-command `matches_deny`. [read: hooks/auto-approve-allowed-commands.sh:216-232, 299-307]
- The new deny shape check runs inside the existing settings `jq` call (`:136-153`), so it adds no process. [read: hooks/auto-approve-allowed-commands.sh:136-153, 181-183]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

Unit 2 makes the hook's hot path cheaper. It removes the only per-call work that grew with the deny list, a bash character loop plus a glob scan, and adds no process. The production call starts the same seven processes as before, and its measured latency is flat across deny-list sizes. One stale number is outside this diff: the header's "+25 ms (110 -> 136 ms, 2026-09-28)" at `:47-48` is a delta measured on another day. On this container an approved `git status` costs about 82-86 ms, which does not contradict a +25 ms delta. Nothing needs profiling before merge.

## Goal-Alignment Note

The goal is to land Q-092 unit 2 clean: remove the hook's Bash deny reader so that each deny rule has one interpreter, Claude Code's. On performance the unit does what it says, and does it a little better than neutral. Removing the reader removes its cost, which was only visible on large deny lists. No performance item blocks the merge. The behavioural edges of the removal are in the API-consistency review (q092b): a NUL inside a deny rule no longer fails closed, and `--permissions` now skips the settings files' fail-closed check.
