Commit: cebb32cd

# Security Review — Q-092 Unit 1 (fix/q092a-drop-deny-option), terminal pass

**Scope:** `git diff 00a27a2f..cebb32cd -- ':(exclude)docs/reviews'` (hooks/auto-approve-allowed-commands.sh, test/auto-approve-allowed-commands.bats, docs/working/plan-q092-drop-hook-deny-reader.md), full unit, plus the whole hook file at cebb32cd for context
**Date:** 2026-10-15
**Based on:** goal preamble and terminal brief for Q-092; prior q092a passes in docs/reviews/ read as context only

> ⚠️ **No code fact-check report provided for this pass.** Claims about security properties in comments and documentation were checked here by reading the code and running probes, not by a separate code-fact-check run.

## Trust Boundary Map

```
B1: [tool_input.command from the model (prompt-injectable)] → [main: matches_deny(raw), extract_commands_from_string + refuses_construct, matches_deny(each), is_command_allowed] → [stdout "allow" JSON → Claude Code permission engine]
B2: [settings files: ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json, <root>/.claude/settings{,.local}.json] → [read_settings_rules / SETTINGS_RULES_JQ shape check → add_allow_rule / add_deny_rule] → [ALLOW_PREFIXES, DENY_GLOBS, DENY_ALL]
B3: [hook argv (--permissions; --deny removed)] → [main arg loop] → [CUSTOM_PERMISSIONS] (moved: --deny no longer reaches DENY_GLOBS)
B4: [hook stdout + exit status] → [Claude Code hook-decision merge with permissions.deny] → [run / prompt / deny]   (Q-082: a hook "allow" does not override deny)
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | `tool_input.command` | request-time | UNTRUSTED for every sink (glob match, shfmt parse, approval decision): model-written and injection-reachable |
| S2 | settings-file `permissions.allow` / `permissions.deny` | runtime-mutable (Edit/Write guarded by guard-trusted-writes and deny rules; project files writable by the repo) | UNTRUSTED as glob syntax (escaped in add_deny_rule); trusted as policy intent, since it is the user's own policy |
| S3 | `CLAUDE_CONFIG_DIR`, `HOME`, cwd/git root | deploy-time (env) | trusted for path choice only when absolute and newline-free; otherwise fails closed |
| S4 | argv `--permissions` / ignored `--deny` | deploy-time (wiring.json passes no options) | trusted (test-only), not reachable from S1 |
| S5 | `ALLOW_JSON` / literal decision string in source | code-constant | trusted |

What crosses: S1 enters at B1 and the only consequential output is the single allow line at B4. The diff removes one normalization step (the de-quoted match) between S1 and DENY_GLOBS, and removes S4's ability to replace S2's deny list. The diff's central assumption is that B4's merge, not this hook, is what enforces deny (Q-082), and that this hook never emits a decision weaker than "allow" vs deny precedence (no "ask").

## Findings

No findings.

Everything the probes turned up falls inside the accepted residuals named in the brief (F3 quote/backslash spellings now relying on Claude Code's matcher; glob spellings already passing both). Details are in Endorsement Claims and Untested bypass candidates below.

## Bypass enumeration (move #11) — tested

Guardrail: `matches_deny` over the raw command and each extracted command, after removal of the de-quoted match. Probe: `agents/security-review-q092a-final-2026-10-15/probe.sh` (hermetic HOME and project, run under `timeout`; temp tree removed). It compared cebb32cd to base 00a27a2f, with allow `cat, git, echo, ls, rm` and deny `Bash(*.credentials.json*)`, `Bash(git push:*)`, `Bash(rm -rf:*)`:

| Candidate | new (cebb32cd) | old (00a27a2f) | Disposition |
|---|---|---|---|
| `cat ~/.claude/.credentials.json` | no | no | literal still caught |
| `cat ~/.claude/${X:-.credentials.json}` | no | no | was caught by PARAM_DEFAULT_RE; now refused by the shape allowlist (ParamExp with operator), so dropping the regex costs nothing |
| `cat ~/.claude/${X-.cred}entials.json` | no | no | same, shape refusal |
| `cat ~/.claude/".credentials.json"` | no | no | quote around the word keeps the substring; still caught |
| `cat ~/.claude/.cred\`+newline+`entials.json` | no | no | shfmt joins the continuation; the extracted command matches |
| `git<TAB>push origin`, `git  push origin` | no | no | extracted command is re-joined with single spaces, so it matches |
| `rm<TAB>-rf x`, `rm  -rf x`, `ls \| rm -rf x`, `ls; git push` | no | no | per-extracted-command check holds |
| `git "push" origin` | **ALLOW** | no | accepted residual F3 (listed in hook header line 71) |
| `git p\ush origin` | **ALLOW** | no | accepted residual F3 (backslash in a word, header line 71) |
| `git -C . push` | ALLOW | ALLOW | pre-existing; deny rule `git push:*` never named it; not a delta |

`--deny` removal: the arg loop's `*) shift` consumes both `--deny` and its value, so a stray `--deny '["Bash"]'` is inert (pinned by bats "the hook ignores a --deny argument"). Repo-wide search found no non-test caller passing `--deny`, and wiring.json invokes the hook with no options. A caller that used to pass `--deny` to *replace* the settings deny lists now gets the settings deny lists. That is stricter, not looser.

## Untested bypass candidates

- **F3 spellings against Claude Code's own deny matcher** (`git "push"`, `.cred""entials.json`, `.c\redentials.json`). Untested because it needs a host Claude Code session. Already accepted in the brief and the plan, and listed here so this guardrail stays out of Endorsement Claims for those spellings.
- **Exit status 2 on an unforeseen `set -e` failure.** Not exhaustively provable by probe. Five malformed inputs exited 0, 4 or 5 (jq 1.6), never 2. Even an exit 2 would be a block, which is stricter than deny, so it cannot weaken B4.

## Endorsement Claims

- **Claim:** The hook's stdout, across the probed exit paths, is either empty or exactly the allow JSON. The source spells exactly one `permissionDecision` value, `allow`.
  **Location:** `hooks/auto-approve-allowed-commands.sh:440`; `test/auto-approve-allowed-commands.bats:255-279`
  **Evidence:** executed
  **Verified:** bats 43/43 pass at cebb32cd, including the stdout test. `rg permissionDecision hooks/` shows the hook's only occurrence at line 440. The other hits are in guard-trusted-writes.py. Every `debug`/error write in main and its callees goes to stderr (read lines 124-128, 339-446, 726-757, 792-825).
  **Not verified:** stdout under a shfmt or perl binary that writes to stdout on failure inside a captured `$(...)`. Those are captured, not passed through, but no probe ran a substituted binary.
  **route: code-fact-check**
- **Claim:** Deny-rule glob escaping makes `?`, `[...]` and extglob characters literal, and the per-extracted-command check fires inside a pipeline. Both now use settings-file rules, not `--deny`.
  **Location:** `hooks/auto-approve-allowed-commands.sh:241-258, 294-309, 427-430`; bats test "a prefix deny rule blocks an extracted command inside a pipeline; only * is a wildcard"
  **Evidence:** executed
  **Verified:** that test passes, and the probe rows above for the tab/double-space/pipeline variants.
  **Not verified:** rules whose body holds a multibyte character. `${body:i:1}` under the caller's locale was not probed.
- **Claim:** A relative or newline-bearing `CLAUDE_CONFIG_DIR` leads to no approval, which matches the corrected header line 82 ("a relative value approves nothing").
  **Location:** `hooks/auto-approve-allowed-commands.sh:184-195, 268-272, 296-298`
  **Evidence:** executed
  **Verified:** bats tests "a relative CLAUDE_CONFIG_DIR fails closed…" and "a newline in the global settings path fails closed" pass. Read path: `read_settings_rules` returns 1, `DENY_ALL=true`, and `matches_deny` returns 0 before any allow is printed.
  **Not verified:** the `--permissions` path with a relative `CLAUDE_CONFIG_DIR`. By reading it also reaches `DENY_ALL`, but no test pins that combination.

## Primitive sweep

Primitive: bash `[[ … == <unquoted pattern> ]]` (glob/pattern injection from rule text), in diff scope.

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/auto-approve-allowed-commands.sh:303` `[[ "$str" == $glob ]]` | S1 (lhs), S2 deny rule (pattern) | add_deny_rule escapes all but `[A-Za-z0-9*]` | cleared: escaping pinned by test, `*` is the intended wildcard |
| removed: `"$dq" == $glob` (old 184) | S1 de-quoted | same escaping | removed; residual F3 (accepted) |
| `:251` `[[ "$c" == [A-Za-z0-9*] ]]` | S5 | constant pattern | cleared, code-constant |
| `:328-329` is_command_allowed | S1, S2/S4 allow prefix | RHS quoted, so literal | cleared, not touched by diff |

Primitive: process exec (`jq`, `shfmt`, `perl`, `git`). The diff adds no new call sites. `load_rules`'s settings `jq` call now runs unconditionally, where it used to be skipped when both `--permissions` and `--deny` were set. It is the same call with the same fixed program, and its arguments are file paths passed as argv (S3), not interpolated. Cleared.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

Unit 1 narrows the hook's deny check exactly as stated. `--deny` and the de-quoted match are gone, and the settings-file deny reader, its fail-closed shape checks and the per-extracted-command match remain. The only new approvals the probes found are the quote/backslash spellings that the brief and the hook header already accept as F3. The dropped `${NAME:-word}` rendering costs nothing, because the shape allowlist refuses those expansions before matching. Removing `--deny` cannot loosen policy: no production caller passes it, and the old option could only replace the settings deny lists. The precondition Q-092 rests on, that this hook never emits `ask`, holds by source and by the executed stdout test. A co-hook's `ask` (guard-trusted-writes on tainted SOFT Bash) overriding deny is independent of this hook and recorded as plan F8, so it is not re-filed here. No findings within the code paths read. The F3 behaviour of Claude Code's own matcher stays pending a host check, as already queued.

## Goal-Alignment Note

The user goal is to land Q-092 as two stacked, reviewed-clean units, removing the hook's own Bash deny reader because Q-082 showed `permissions.deny` beats a hook `allow`. Unit 1 serves that goal: it removes the test-only `--deny` path and the de-quoted match, keeps fail-closed loading for Unit 2 to rework, and adds the never-`ask` test that Q-092 names as its precondition. Nothing in this unit goes beyond the goal, and the security delta matches the accepted residual set.
