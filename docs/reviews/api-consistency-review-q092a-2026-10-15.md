Commit: 1a831ffe

# API Consistency Review — Q-092 unit 1 (fix/q092a-drop-deny-option)

**Scope:** `git diff 00a27a2f..1a831ffe`: the public surface of hooks/auto-approve-allowed-commands.sh (CLI options, stdout contract, the settings-file shapes it accepts, the `parse_commands` subcommand) and the callers of each
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-q092a-2026-10-15.md

## Baseline Conventions

- **How it is invoked.** `hooks/wiring.json:74-79` wires the hook as `bash {{CLAUDE_DIR}}/hooks/auto-approve-allowed-commands.sh` with no options. `test/link-claude-home-wiring.bats:194,205` asserts that exact command string. Outside the hook's own bats suite, nothing in the repo passes `--permissions` or `--deny`: I searched the whole tree with `rg -- '--deny'` and `rg auto-approve-allowed-commands`, which covers `devcontainer-config/`, `scripts/`, `test/`, `guides/`, `README.md` and `docs/decisions/`. The only other hit for `--deny` is the history in decision log row 53. So both options are test-only.
- **Unknown options.** The two entry points of this file have long handled unknown options differently. `main` swallows any unknown argument with `*) shift` (`hooks/auto-approve-allowed-commands.sh:353-355`). `parse_commands` rejects one with `echo "Unknown option: $1" >&2; exit 1` (`:919-922`). The repo's scripts reject unknown options (`scripts/dev-cycle.sh:122`, `scripts/skill-usage-report.sh:29`, `scripts/archive-working-docs.sh:32`). Hooks fail quiet (`hooks/claude-config-audit.sh:65` `*) exit 0`).
- **Stdout contract.** For a no-opinion result, PreToolUse hooks in this repo exit 0 and print nothing (`hooks/guard-trusted-writes.py:68-70`). This hook's only stdout line is the allow JSON (`:442`).
- **Settings shape.** One jq program checks all three files (`:159-177`). `permissions` must be an object. `allow` must be an array (non-string entries are skipped). `deny` must be an array of strings. A NUL inside an emitted rule is an error.

## Name-Pattern Audit

The diff adds no public names. Unit 1 only removes them: the `--deny` option, and the internals `CUSTOM_DENY`, `CUSTOM_DENY_SET` and `PARAM_DEFAULT_RE`. Removed names have no neighbours to audit.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| _(none)_ | — | — | none: searched the `+` lines of `git diff 00a27a2f..1a831ffe -- hooks/ test/` | No new public names |

## Findings

#### A removed `--deny` is swallowed silently, with its value, instead of being reported

**Severity:** Informational
**Location:** `hooks/auto-approve-allowed-commands.sh:343-357`; `test/auto-approve-allowed-commands.bats:250-253`
**Move:** 3 (consumer contract) and 6 (versioning impact)
**Confidence:** High
**Legibility-target:** a future maintainer or a stale test copy that still passes `--deny`

**Evidence:** `      *)` / `        shift` / `        ;;` (`:353-355`), and the test `@test "the hook ignores a --deny argument (the option was removed in Q-092)"` (`:250`).

Removing `--deny` is a breaking change to a CLI option. Because `main` drops unknown words one at a time, `--deny '[...]'` now costs two silent shifts, and the call runs as if the option had never been passed. In this unit the settings files' deny rules apply instead of the caller's list. In unit 2 no deny rules apply at all. A caller who relied on `--deny '["Bash"]'` to block every approval now gets approvals, with no error. Nothing in the repo is such a caller (see Baseline), the new test pins the silent behaviour on purpose, and fail-quiet matches the hook convention, so consumers see no impact. The divergence from `parse_commands` (`:919-922`) and from the repo's scripts is long-standing, not introduced here.

**Recommendation:** None needed for the merge. If you want the removal visible, add `debug "ignoring unknown argument: $1"` in the `*)` arm. It costs nothing in production and keeps exit 0.

## What Looks Good

- The wired invocation is unchanged (`hooks/wiring.json:74-79`), so no deployed consumer sees an option change.
- The stdout contract is unchanged: `main` still writes one stdout line, the allow JSON (`:442`). Unit 2 adds the test that pins this.
- The usage block (`:13-16`) and `main`'s parser drop `--deny` together, so the documented options match the parsed ones. The leftover `--permissions` wording at `:15` is fact-check item U1 line 15, already listed.
- The settings-file shapes the hook accepts are unchanged in this unit. `SETTINGS_RULES_JQ` (`:159-177`) is untouched, so a file that failed closed before still fails closed.
- `parse_commands` is untouched. Its option parser and output are the same as at the base.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A removed `--deny` is swallowed silently, with its value | Informational | `hooks/auto-approve-allowed-commands.sh:353-355` | High |

## Overall Assessment

Unit 1 narrows a test-only CLI surface and leaves the production contract alone: same invocation, same stdout, same accepted settings shapes. The one breaking change, removing `--deny`, has no consumer in the repo besides the test that now pins its removal. Because unknown options are ignored silently, a stale caller would get no error, but that follows the hook's long-standing fail-quiet convention. The consistency issues that matter in this unit are the text items the fact-check already lists (stale ROLE text, the `--permissions` usage line, the header table row). I have not re-filed them.

## Goal-Alignment Note

The goal is to land Q-092 unit 1 clean: drop `--deny` and the de-quoted match, keep the settings-file deny reader for unit 2. The public surface does exactly that, and no caller across `devcontainer-config/`, `scripts/` or `test/` breaks. My single finding is Informational and does not block the merge.
