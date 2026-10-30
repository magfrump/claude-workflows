Commit: 1a831ffe

# Security Review — Q-092 unit 1 (q092a, fix/q092a-drop-deny-option)

**Scope:** `git diff 00a27a2f..1a831ffe`: `hooks/auto-approve-allowed-commands.sh` and `test/auto-approve-allowed-commands.bats` (the plan doc was read for context only)
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-q092a-2026-10-15.md, plus the known-findings list in the review brief

## Trust Boundary Map

```
B1: [model-authored Bash command (tool_input.command)] → [matches_deny(raw), shfmt + refuses_construct, matches_deny(each extracted), is_command_allowed] → [hook stdout "allow" → Claude Code runs it]
B2: [settings files: global, project, project-local]    → [read_settings_rules jq (fail closed → DENY_ALL)] → [ALLOW_PREFIXES / DENY_GLOBS]
B3 (removed): [--deny CLI JSON]                           → [jq array-of-strings check]  → [DENY_GLOBS]
B4: [hook stdout / exit code]                            → [Claude Code permission engine: permissions.deny is applied after a hook "allow" (Q-082)] → [execution]
```

```
S1: tool_input.command                 — request-time    — UNTRUSTED (all sinks; it is the payload being authorized)
S2: settings files (global/project)    — runtime-mutable — UNTRUSTED for the approve decision: the project files sit in the
                                                            repo the model can write to (Write/Edit), so a bad one must fail closed
S3: --permissions CLI arg              — deploy-time     — test-only; wiring.json passes no options (hooks/wiring.json:78)
S4: --deny CLI arg (removed)           — deploy-time     — now parsed as an unknown option and dropped
```

Untrusted command text (S1) reaches an "allow" only if no deny glob from S2 matches the raw text or any extracted command, and the AST shape is approved. The unit removes B3 and narrows the matcher on B1 from "raw, extracted, and the de-quoted form of each" to "raw and extracted". Since Q-082, B4 means Claude Code applies its own deny matcher after the hook's "allow", so the hook's matcher has become a second check. That makes the important question how far Claude Code's matcher reaches, and the plan rates that unverified (F3/F4).

## Findings

#### 1. Two deny-matcher mechanisms that are still live in this unit are no longer pinned by any test (shown by mutation)

**Severity:** Low
**Location:** `hooks/auto-approve-allowed-commands.sh:429-432` (deny check on each extracted command), `:251-258` (add_deny_rule escaping); `test/auto-approve-allowed-commands.bats` (tests removed at 00a27a2f:171-176, :243-258, :486-494)
**Boundary:** B1, B2
**Move:** 11 (bypass enumeration), 3
**Confidence:** High
**Legibility-target:** the test file's deny section and the header's "WHAT THE DENY CHECK GUARANTEES"

**Evidence:**
```
    if matches_deny "$full_command"; then
      all_allowed=false
      break
    fi
```
and the removed test `a legacy prefix deny rule blocks an extracted command inside a pipeline` (`... --deny '[\"Bash(rm -rf:*)\"]'`).

I applied each mutation to a copy of the hook and ran the full suite against it, at the base and at the head:

| Mutation | 00a27a2f (47 tests) | 1a831ffe (42 tests) |
|---|---|---|
| delete the per-extracted `matches_deny` (:429-432) | fails tests 12 (legacy prefix in a pipeline) and 27 (quoting) | **0 failures** |
| drop the backslash escaping in add_deny_rule (`glob+="$c"`) | fails tests 19 and 20 (`[1]`, `?` literal) | **0 failures** |
| delete the raw `matches_deny "$command"` (:389) | 0 failures | 0 failures (an existing gap, not introduced here) |
| never set DENY_ALL on a reader failure | NUL tests only | NUL tests only (no change) |

(Base test 14, "wiring.json deny rule", also failed in every base mutant. That comes from the copy layout of my scratch copy and is not a mutation result.)

Every deny test that remains uses `Bash(*.credentials.json*)`, which has a leading `*`, or a bare `Bash`. Both match the raw string, so the raw check alone satisfies them. Only an anchored rule such as `Bash(rm -rf:*)` or `Bash(git push:*)` needs the extracted check. My probes show the extracted check is what stops `ls | rm -rf x`, `git  push origin` (double space), ``git \<newline>push origin`` and `git<TAB>push origin`, all of which are still `prompt` at head. So the check works today; a regression in it would just ship without a failing test. This finding builds on the fact-check report, which notes the deny column of the rule table and the `?`/`[` tests were lost (Claims 12/rule-table, report :318-332, :532). The extracted-check gap is not in that report, and the mutation results confirm both gaps.

Impact is bounded. Unit 2 deletes all of this code, and Claude Code's own deny matcher sits behind it (B4). The gap matters only if unit 2 slips or is reverted while unit 1 is deployed.

**Recommendation:** Either restore one settings-file test in unit 1 (`Bash(rm -rf:*)` deny, `ls | rm -rf x` not approved), which unit 2 then deletes along with the reader, or say in the unit 1 commit or plan that the per-extracted check and the escaping loop are unpinned until unit 2 removes them. The second costs nothing.

#### 2. `${X:-word}` is listed as an accepted residual, but the shape allowlist already refuses it

**Severity:** Informational
**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md` F3 row; brief "accepted quote-split family"
**Boundary:** B1
**Move:** 11
**Confidence:** High
**Legibility-target:** plan F3 row

**Evidence:** plan F3: "Quote-split / backslash spellings (`.cred""entials.json`, `git "push"`, `${X:-push}`)"; hook `:693`: `elif .Type == "ParamExp" and (plain_param | not) then "parameter expansion with an operator"`.

Probes at head give `prompt` for both `git ${X:-push} origin` and `cat ~/.claude/.cred${X:-entials}.json`. refuses_construct rejects them before the deny matcher runs. Removing the `PARAM_DEFAULT_RE` loop therefore opens no approve path, so F3 lists more exposure than exists. The hook header's residual list (:76-79) does not name `${X:-}`, so only the plan overstates it.

**Recommendation:** Drop `${X:-push}` from F3, or note that the shape check refuses it.

## Bypass enumeration (move 11): approve paths the removal opens

Setup: deny `Bash(*.credentials.json*)`, `Bash(git push:*)`, `Bash(rm -rf:*)`, `Bash(cat secret)`; allow `git`, `echo`, `cat`, `curl`, `ls`, `rm`, `grep` (all `:*`). Each probe ran the hook under `timeout 30` from a mktemp project and HOME. Results are listed as base → head.

| Candidate | base | head | Family |
|---|---|---|---|
| `cat ~/.claude/.cred""entials.json`, `.cred''entials.json` | prompt | **ALLOW** | quote split (accepted) |
| `cat ~/.claude/.c\redentials.json`, `git \push origin` | prompt | **ALLOW** | backslash (accepted, fact-check list) |
| `git "push" origin main`, `git 'push' origin`, `echo ok && git "push" origin`, `git pu""sh origin` | prompt | **ALLOW** | whole-word quoting / split (accepted) |
| `ls \| rm "-rf" x` | prompt | **ALLOW** | whole-word quoting of an argument (same family) |
| `cat "secret"` under exact rule `Bash(cat secret)` | prompt | **ALLOW** | whole-word quoting against an exact deny rule (same family; worth a phrase in the residual list) |
| `cat $'\x2e'credentials.json` | ALLOW | ALLOW | ANSI-C (unchanged; the de-quote never decoded it) |
| `ls \| rm -r -f x`, `ls \| rm -fr x` | ALLOW | ALLOW | flag respelling (unchanged; string-match limit) |
| `ls \| "rm" -rf x` | prompt | prompt | quoting the command name defeats the allow prefix too, so it cannot be used to bypass |
| `git ${X:-push} origin`, `.cred${X:-entials}.json` | prompt | prompt | shape refusal (Finding 2) |
| `cat ~/.claude/".credentials.json"`, `cat "$HOME/.claude/.credentials.json"`, `cat ${HOME}/...`, `cat $".credentials.json"`, `cat ...credentials.json"" ` | prompt | prompt | denied string still contiguous |
| `` cat ~/.claude/.cred\<newline>entials.json `` | prompt | prompt | — |
| here-doc body containing `.credentials.json` | prompt | prompt | raw check |
| `git  push`, ``git \<newline>push``, `git<TAB>push`, `git push"" origin` | prompt | prompt | extracted check normalizes the whitespace |
| `bash -c 'git push'` | prompt | prompt | wrapper refusal |

Every new ALLOW comes from quote characters (`'`, `"`) or backslashes, which is exactly what the old de-quote stripped. No candidate outside that family changed. The `--deny` removal opens no path: wiring passes no options (`hooks/wiring.json:78`), and `rg -- --deny` finds no caller outside the bats file and docs. An ignored `--deny X` is consumed by the `*) shift` branch twice, so it cannot shift `--permissions` out of place.

### Untested bypass candidates
- Extglob characters in a deny rule (`@(`, `!(`) after the escaping loop. Not probed, because no shipped rule uses them, and the fact-check report notes the same.
- `$"..."` locale quoting mixed into the middle of the name (`.cred$"entials".json`). It belongs to the quote-split family, so I expect ALLOW; not run.

## Endorsement Claims

- **Claim:** At head, the raw-string and per-extracted deny checks both run on every path that can reach the allow `echo`, and the deny list is always loaded from the settings files, including when `--permissions` is given.
  **Location:** `hooks/auto-approve-allowed-commands.sh:267-290`, `:389-392`, `:426-438`
  **Evidence:** executed
  **Verified:** read load_rules, matches_deny and main to their ends. The probes above show `ls | rm -rf x` and the double-space and newline spellings of `git push` prompt at head. Mutating out `add_deny_rule` fails tests 11, 12 and 17.
  **Not verified:** deny rules in sources the hook does not read (managed settings, `--settings`), which the header excludes.
  **route: code-fact-check**

- **Claim:** Fail-closed loading is unchanged by this unit. A settings reader failure still sets DENY_ALL, and that path is still exercised by the NUL tests (25, 27, 28) in a mutation that removes it.
  **Location:** `hooks/auto-approve-allowed-commands.sh:270-274`
  **Evidence:** executed
  **Verified:** the DENY_ALL mutation fails the same NUL tests at base and at head. The malformed and wrong-shape tests pass either way, because a jq parse error yields no records and therefore no allow rules. Making `load_rules` unconditional removes the one branch (`--permissions` plus `--deny`) that skipped the reader.
  **Not verified:** a shape error in the second or third file after an earlier file emitted allow records is exercised only through the NUL-in-rule variant, not through `permissions.deny: "Bash"` in the project file.
  **route: code-fact-check**

- **Claim:** The hook's stdout is empty or exactly the allow JSON on the paths the new test drives, so it cannot emit `ask`, the decision that overrides deny in #39344.
  **Location:** `test/auto-approve-allowed-commands.bats` (stdout test); `hooks/auto-approve-allowed-commands.sh:442`
  **Evidence:** executed (suite: 42/42 pass at 1a831ffe)
  **Verified:** the suite run, and that the source contains one `permissionDecision` literal.
  **Not verified:** the jq-missing exit (:360-363), already in the known list. Its stdout is empty by reading.

- The `--permissions` and settings-file NUL handling is unchanged by this diff: the jq filter at `:287` and the jq program at `:175` are identical at base and head.

## Primitive sweep

Primitive: bash pattern match with an unquoted RHS (`[[ "$str" == $glob ]]`, a glob-injection sink)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/auto-approve-allowed-commands.sh:305` (raw) | S1 vs S2 | add_deny_rule escapes everything except `[A-Za-z0-9*]` | cleared; the escaping is no longer test-pinned (Finding 1) |
| removed `"$dq" == $glob` (00a27a2f) | S1 de-quoted | same | removed |

Primitive: process exec / parsing of S1 (`shfmt`, `jq`, `perl`)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:724` perl normalize, `:739` shfmt, `:758`/`:797` jq | S1 | data passed on stdin, never as code | unchanged by this diff; cleared |
| `:206` jq over settings files | S2 | `--args` file list, newline-in-path refused | unchanged; cleared |
| removed `--deny` jq (00a27a2f) | S4 | — | removed |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Per-extracted deny check and the rule-escaping loop are live but no longer test-pinned (mutation-proven) | Low | B1, B2 | `hooks/auto-approve-allowed-commands.sh:429-432`, `:251-258` | High |
| 2 | `${X:-word}` listed as an accepted residual although the shape check refuses it | Informational | B1 | plan F3 row | High |

## Overall Assessment

The unit opens no approve path beyond the accepted family. Every new `allow` in 30+ probe spellings comes from `'`, `"` or `\` inside or around a word. That covers quote splits, backslashes, and whole-word quoting of an argument, including against an exact rule such as `Bash(cat secret)`. ANSI-C and flag respellings were already approved at base. `${X:-word}` is refused by the shape allowlist, and quoting a command name also defeats the allow prefix. The raw and per-extracted deny checks and fail-closed loading are intact and exercised. The `--deny` removal has no production caller. The one thing to address is test coverage. Mutation runs show that the per-extracted deny check and the deny-rule escaping loop, both still live in this unit, can be removed with all 42 tests passing. Since unit 2 deletes both, a one-line note in the plan or commit, or one restored settings-file pipeline test, is enough. No findings block within the code paths read. The endorsement claims rest on executed probes and mutations, and the routed ones await code-fact-check confirmation.

## Goal-Alignment Note

The goal is to drop the hook's own deny reader in two units now that Q-082 shows `permissions.deny` beats a hook `allow`. Unit 1 serves that goal without widening exposure beyond the plan's accepted F3 family, and the new stdout test pins the precondition (never `ask`) that makes Q-082's answer apply. Finding 1 concerns only the window between the two units. Finding 2 shows the accepted exposure is slightly smaller than the plan states.
