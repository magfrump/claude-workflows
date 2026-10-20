# Plan: drop the auto-approve hook's Bash deny reader (Q-092)

Date: 2026-10-15 · Branch: `fix/q092-drop-hook-deny-reader` (from `merge/ready-2026-10-15`, 00a27a2f)

## Motive (established before deleting)

- Q-082 (archive, answered 2026-09-28): under a PreToolUse hook that always
  returned `allow`, a Bash call matching `permissions.deny` was still denied, and
  the user confirmed `/hooks` listed the hook. A hook `allow` does not override deny.
- Decision log 53, amendment 2026-09-28, records this and files the removal as Q-092.
- Architecture review 2026-09-27, finding 1: the reader is a second, partial
  Bash-deny engine coupled to Claude Code semantics it cannot see (one known
  divergence already: `Bash(rm *)` vs bare `rm`). "If deny wins, delete the deny
  reader and keep the hook allow-only."
- **The `ask` question (Q-092's constraint).** The host result covers `allow`
  only; #39344 shows a hook `ask` overriding deny. Read of the hook: the only
  stdout write in `main` is the `allow` JSON (`echo '{"hookSpecificOutput":...
  "permissionDecision":"allow"}}'`). Every other path is `exit 0` with no output
  (no opinion), and `debug` writes to stderr only. `show_help` and `check_deps`
  (`exit 2`) run only under the `parse_commands` subcommand, which `wiring.json`
  never invokes. Under `set -e` an unexpected failure exits non-zero but not 2
  (measured: malformed input JSON exits 4, a non-blocking error with no decision).
  An exit 2 would be a block, which is stricter than deny anyway. **So no path
  emits `ask`, `deny` or `defer`, and no path exists where deny precedence differs.**
  A new test pins this: the hook's stdout is either empty or exactly the allow JSON.

## Pre-mortem: bypass families (enforcement-file rule, decision log 61(4))

The hook is not in `live-verify-gate.sh`'s `enforcement`/`host_tools` regexes
(it is payload under `claude-home/`, hashed by the manifest at install), but Q-092
treats it as an enforcement file, so the pass runs. Before → after, for a command
that a Bash deny rule names and whose words the allow list covers:

| # | Family | Before | After | Covered? |
|---|---|---|---|---|
| F1 | Literal spelling (`cat ~/.claude/.credentials.json`) | hook falls through; CC denies | hook allows; CC's deny wins (Q-082) | **Covered** by the host result |
| F2 | Hook emits `ask` (#39344) on a deny-matching command | n/a | n/a: no path emits `ask` (see Motive); pinned by a new test | **Covered** |
| F3 | Quote or backslash spellings (`.cred""entials.json`, `.c\redentials.json`, `git "push"`, `cat "secret"` vs `Bash(cat secret)`; `${X:-push}` is refused by the shape allowlist anyway) | hook's de-quoted match fell through → prompt | hook allows; caught only if Claude Code's own matcher normalizes quotes | **Not verified.** CC 2.1.300 builds `fullyUnquoted` forms of a command (seen in the binary), but where they feed the deny matcher was not traced. Live check queued. Accepted, see below |
| F4 | Compound command with a denied subcommand (`ls && rm -rf x` vs `Bash(rm -rf:*)`) | hook checked each extracted command | CC's matcher must split; documented CC behaviour for allow rules is operator-aware | **Not verified for deny.** Live check queued. The wired rule `Bash(*.credentials.json*)` has leading/trailing `*` and matches the raw string anywhere, so the shipped rule is unaffected |
| F5 | Glob / brace / ANSI-C / earlier-variable spellings (`.c*`, `.jso[n]`, `$F`) | approved by the hook (accepted residual; the `.c*` glob and `$F` spellings are pinned by tests) | same | **Not covered, unchanged** (Q-070 [1] residual; the sandbox is the real fix, Q-125) |
| F6 | Malformed or ill-shaped settings file | no approval (DENY_ALL) | no approval for bad JSON or a bad `permissions`, `allow`, `deny` or `ask` (U2 makes each, when present, an array whose strings hold no NUL; non-string entries are skipped, as Claude Code drops them) | **Partly covered.** Security review q092b: Claude Code 2.1.300 can ignore a whole settings file for an invalid value; for a value outside those keys the hook still approves from the file's allow rules while its deny rules are gone. Before Q-092 the reader still saw the deny rule. Residual, stated in the header |
| F6b | Settings file Claude Code drops for a reason the hook does not check (e.g. a bad `defaultMode`, a BOM) | the hook's deny reader still matched its deny rules | no backstop | **Not covered**; accepted, see F6 |
| F7 | Relative or newline-bearing `CLAUDE_CONFIG_DIR` | no approval | no approval (kept: a wrongly resolved file could add allow rules) | **Covered** |
| F8 | Another hook's `ask` (guard-trusted-writes, SOFT+tainted Bash) overriding a Bash deny | reader could not affect it (it only withholds this hook's own allow) | same | **Out of scope, unchanged**; reported |
| F9 | Settings sources CC honours but the hook never read (managed, `--settings`) | contributed no deny here | irrelevant now: CC applies them itself | **Improved** |
| F10 | Claude Code version drift (image installs `@latest`) reverses Q-082's precedence | reader backstopped | no backstop | **Not covered**; a future CC change would need re-testing. Q-082 did not record its version (Q-091, the same day, saw 2.1.284 on the host); the image installs `@latest` (2.1.300 here). Re-test trigger in the header. Same exposure as every other CC permission semantic |

Why F3/F4 are accepted rather than blocking: the de-quoted match never stopped a
determined injection, because F5's glob spelling (`~/.claude/.c*`) already gets the
same command approved, by the hook and by Claude Code's string matcher. What
F3 removes is coverage of a spelling an attacker does not need. The live check
below settles whether even that changes. Q-092's text asks for exactly this
removal, so the branch implements it and the report carries the check.

`/pre-mortem` skill: not invoked separately; this table is the bypass-family pass
the rule requires. `/architecture-review`: not triggered (one module, `hooks/`,
plus docs; the change removes a coupling the 2026-09-27 review asked to remove).

## Steps

1. `hooks/auto-approve-allowed-commands.sh`: delete `--deny`, `CUSTOM_DENY*`,
   `DENY_GLOBS`, `add_deny_rule`, `PARAM_DEFAULT_RE`, `matches_deny`, both
   `matches_deny` calls, `RULE_LEGACY`. Keep the settings jq's shape validation;
   stop emitting `D` records. Rename `DENY_ALL` → an "unreadable settings" path
   that leaves no allow rules. With `--permissions`, the settings files are no
   longer read. Rewrite the header: ROLE, the deny-check section (replaced by a
   short "DENY RULES ARE CLAUDE CODE'S" note with F3/F4/F10), rule table (allow
   column only), drop KNOWN DIVERGENCE.
2. `test/auto-approve-allowed-commands.bats`: delete the `--deny`, de-quote,
   rule-table-deny, NUL-in-deny and string-match-limit tests; keep fail-closed
   settings tests (reworded); add (a) stdout is empty or exactly the allow JSON,
   (b) a deny rule in settings no longer changes the hook's decision.
3. Docs: `hooks/wiring.json` `_comment`, `guides/bare-host-hook-wiring.md` known
   gaps, `test/link-claude-home-wiring.bats` comment, decision log row 53
   (amendment: Q-092 done). `wiring.json` is merged by exact entry; `_comment`
   is not merged into settings, so no linker run is needed.
4. Review loop (code-review, security required), health check.

## Split (decision log 62 cap)

At the split the whole change counted 652 code lines (deletions count in full),
so it became two stacked units, each under 400 then (~365 and ~373). After the
review loops, U1 counts ~413 and U2 ~451 against U1 (706 for the stack), inside
decision 62's ~800 in-loop tolerance:

- **U1** `fix/q092a-drop-deny-option` (base `merge/ready-2026-10-15`): drop
  `--deny` and the de-quoted match; tests move off `--deny` into their final
  form wherever that form holds in both states. ~365 lines.
- **U2** `fix/q092-drop-hook-deny-reader` (base U1): drop the settings-file deny
  reader, `matches_deny`, the remaining deny tests; header and docs. ~373 lines.

## Trailers

`hooks/`, `test/` and `docs/` match neither gate regex, so no `Live-verified:` or
`Host-tool-tested:` trailer is required (decision log 45, 71). Deploying the hook
into cc-isolated changes the installed payload: `install.sh` + re-bless.

## U3: quote check (Q-177 [3], 2026-10-20)

The host check Q-176 (answers-10-16-26) settled F3 and F4. Every control was
denied, and the compound `echo hi && rm -rf ./nothing-here` was denied, so F4
is covered by Claude Code. Four quoted or backslashed spellings ran: `x.ca""nary`
and `x.c\anary` against `Bash(*.q092-canary*)`, `cat "secret"` against
`Bash(cat secret)`, `git "push"` against `Bash(git push:*)`. No version lines or
`seen.log` came back. The test hook approves only the nine exact strings, so a
run means it saw that spelling.

The user picked Q-177 [3]: `SHAPE_FILTER` refuses a word whose quoting or
escaping splits its text, which means a quoted part beside another part, a
backslash outside quotes, or a printable escape in `$'...'`. One shape passes:
`-opt=` followed by one quoted value (`--format="%h %s"`). A whole quoted word
still passes. It splits nothing, so a wildcard rule such as the shipped
`Bash(*.credentials.json*)` still matches it raw (inferred from how Q-176's
canary rule behaved; not host-tested).

Bypass families for U3, against the shipped wildcard rule:

| # | Family | After U3 | Covered? |
|---|---|---|---|
| Q1 | Empty or partial quotes mid-word (`.cred""entials`, `'.cred'entials`) | refused (prompt) | **Covered**, tested |
| Q2 | Backslash outside quotes (`.c\redentials`) | refused | **Covered**, tested |
| Q3 | ANSI-C printable escape (`$'.c\x72edentials'`, `\162`, `r`) | refused; `\n`, `\t` and the other control escapes pass | **Covered**, tested |
| Q4 | `-opt=` plus one quoted value (`--file=".credentials.json"`) | approved; the denied text stays contiguous, so the raw wildcard matches | **Covered by Claude Code** (inferred) |
| Q5 | Whole quoted word against an exact or prefix rule (`cat "secret"`, `git "push"`) | approved | **Not covered**, RESIDUAL in the header; no shipped rule has that shape |
| Q6 | Plain parameter mid-word (`.cred${E}entials.json`, `E` unset) | approved | **Not covered, unchanged**: the F5 class (Q-070 [1]); the sandbox is the fix |
| Q7 | Glob spelling (`~/.claude/.c*`) | approved | **Not covered, unchanged** (F5) |

Q6 and Q7 mean U3 does not stop a determined injection. What it restores is
main's behaviour for the Q-176 spellings: they prompt.
Cost: a quoted part beside other text (`a"b c"`, `-m"msg"`) and backslash
escapes (`\*.txt`, `foo\|bar`) now prompt even when allow-listed.
