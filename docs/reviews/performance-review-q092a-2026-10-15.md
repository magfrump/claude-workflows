Commit: 1a831ffe

# Performance Review — Q-092 unit 1 (fix/q092a-drop-deny-option)

**Scope:** `git diff 00a27a2f..1a831ffe` (hooks/auto-approve-allowed-commands.sh, test/auto-approve-allowed-commands.bats, docs/working/plan-q092-drop-hook-deny-reader.md)
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-q092a-2026-10-15.md

## Data Flow and Hot Paths

`hooks/auto-approve-allowed-commands.sh` is wired as a `PreToolUse` hook on every Bash call (`hooks/wiring.json:74-79`, no options). That makes `main` a **hot path**: one run per Bash tool call. A run starts these processes: `jq` (read the input), `git rev-parse` and one `jq` over the settings files (`load_rules` → `read_settings_rules`), then `perl`, `shfmt`, a `jq` shape check and a `jq` extraction (`extract_commands_raw`). The data is small: one command string, three settings files, and in this checkout 12 deny rules and 20 allow rules.

What unit 1 changes on that path:
- `matches_deny` (`hooks/auto-approve-allowed-commands.sh:296-311`) no longer builds the de-quoted string. It used to do a `${str//[\'\"\\]/}` substitution and a `while [[ =~ $PARAM_DEFAULT_RE ]]` loop each time it was called: once for the raw command and once for each extracted command. That was pure-bash string work and started no process.
- `load_rules` (`:267-290`) now always reads the settings files. Before, the only way to skip the read was to pass both `--permissions` and `--deny`, which happens in tests only. The production call (no options) read the settings files before and still does, so it starts the same processes.
- The `--deny` jq pass is gone, but it only ran with `--deny`, so tests only.

Measured per call. The script is in `agents/performance-review-q092a-2026-10-15/bench.sh`: 20 sequential runs per cell after one warm-up, on this container, 2026-10-15. Each run used a non-repo project dir with 4 allow rules, and `CLAUDE_CONFIG_DIR` pointed at a file with 12 deny rules (about this checkout's global file) or 200.

| command | deny rules | base 00a27a2f | U1 1a831ffe |
|---|---|---|---|
| `git status` (allow) | 12 | 85.6 ms | 85.9 ms |
| `git status` (allow) | 200 | 109.7 ms | 109.5 ms |
| `ls -la \| grep foo \| head -5` (allow) | 12 | 99.8 ms | 95.5 ms |
| same | 200 | 125.7 ms | 126.7 ms |
| `cat x` (no rule) | 12 | 100.1 ms | 88.3 ms |
| `--permissions` path, `git status` | 12 | 110.8 ms | 116.8 ms |

Run-to-run noise is about ±5 ms, judging from cells that should match. Unit 1 is neutral on the production path. The 12 ms gap on `cat x` is within one noisy sample, not a mechanism. Every `--permissions` run read the settings files on both commits.

## Findings

No findings.

## Endorsements

- The de-quoted match is gone from `matches_deny`, so each call does one glob comparison per deny rule instead of a string substitution, a regex loop and two comparisons. The new function body at `:296-311` calls nothing except `debug`. [read: hooks/auto-approve-allowed-commands.sh:296-311]
- Checkable claim: unit 1 does not change how many processes the production call starts. `load_rules` still makes one `read_settings_rules` call (one `git rev-parse`, one `jq`), and `matches_deny` started no process before or after. The table above shows the means within noise: 85.6 vs 85.9 ms at 12 deny rules. [unverified — submitted as claim]
- Making the settings read unconditional costs nothing in production. The only branch it removes, both `--permissions` and `--deny` set, never happened in the wired call. [read: hooks/auto-approve-allowed-commands.sh:267-281, hooks/wiring.json:74-79]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

Unit 1 only removes code from the hook's hot path: a bash string pass in `matches_deny`, and a test-only jq pass with its branch. It adds no process, loop or I/O. The measured per-call time is the same as the base within noise, both at a realistic 12-rule deny list and at 200 rules. The deny-rule cost that does grow with the list, `add_deny_rule`'s per-character escaping loop, is still here. Unit 2 removes it. No profiling is needed before merge.

## Goal-Alignment Note

The goal is to land Q-092's first unit clean: drop `--deny` and the de-quoted match because Q-082 showed that Claude Code's `permissions.deny` beats a hook "allow". On performance, the unit does what it says and costs nothing. The production call starts the same processes, and its measured latency is unchanged. Nothing here blocks the merge. The fact-check items listed in critic-common (the header table row, the NUL test, the stale ROLE text, the residual list) are text and test issues with no performance angle, so I have not re-filed them.
