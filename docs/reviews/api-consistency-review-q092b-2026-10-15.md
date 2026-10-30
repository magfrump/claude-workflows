Commit: ed06dec1

# API Consistency Review — Q-092 unit 2 (fix/q092-drop-hook-deny-reader)

**Scope:** `git diff 1a831ffe..ed06dec1`: the public surface of hooks/auto-approve-allowed-commands.sh (CLI options, stdout contract, the settings-file shapes it accepts, `parse_commands`), hooks/wiring.json, and callers across the repo. Unit 1 is context only.
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-q092b-2026-10-15.md

## Baseline Conventions

- **How it is invoked.** `hooks/wiring.json:76-81` wires the hook with no options. `test/link-claude-home-wiring.bats:194,205` pins that command string. The only callers that pass `--permissions` are in `test/auto-approve-allowed-commands.bats`. I searched the whole tree with `rg auto-approve-allowed-commands` and `rg -- '--deny'`, excluding `docs/reviews` and `docs/working`. That covers `devcontainer-config/`, where the only hits are Dockerfile comments at `:144-146`, plus `scripts/`, `test/`, `guides/`, `README.md` and `docs/decisions/`. The only other `--deny` hit is the history in decision log row 53.
- **Stdout contract.** The repo's PreToolUse hooks exit 0 with no stdout when they have no opinion (`hooks/guard-trusted-writes.py:68-70`) and print a single JSON decision otherwise. This hook prints only the allow decision (`hooks/auto-approve-allowed-commands.sh:352`).
- **Fail-closed settings reading.** Since the 2026-09-27 panel (log row 53), a settings file "Claude Code may reject" leaves no allow rules (`:69-73`). Before this unit, the NUL check at `:151` covered both allow and deny records (1a831ffe `:175`), and two tests pinned it for deny rules (1a831ffe `test/...:355-369`).
- **Unknown options.** `main` ignores them (`:274-276`). `parse_commands` rejects them (`:829-832`). The scripts reject them (`scripts/dev-cycle.sh:122`).

## Name-Pattern Audit

The diff adds no public names. Unit 2 removes internals (`DENY_GLOBS`, `DENY_ALL`, `add_deny_rule`, `matches_deny`, `RULE_LEGACY`) and renames no option. The new header section title "DENY RULES ARE CLAUDE CODE'S" is a cross-reference anchor, not an API. It matches the existing all-caps section-title style (`ROLE:`, `SETTINGS SOURCES.`, `RULE SYNTAX.` at `:50-90`), and all three places that cite it spell it exactly that way (`hooks/wiring.json:45-46`, `guides/bare-host-hook-wiring.md:161`, `:135`).

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| _(no new public names)_ | — | — | none: searched the `+` lines of `git diff 1a831ffe..ed06dec1 -- hooks/ test/ guides/` | — |
| header anchor `DENY RULES ARE CLAUDE CODE'S` | doc anchor | `SETTINGS SOURCES`, `RULE SYNTAX`, `ROLE` | `hooks/auto-approve-allowed-commands.sh:50-90` | Consistent; all three citations match |

## Findings

#### A NUL inside a `permissions.deny` rule no longer fails closed

**Severity:** Minor
**Location:** `hooks/auto-approve-allowed-commands.sh:133-135, 145-146, 151`; tests deleted from `test/auto-approve-allowed-commands.bats` (1a831ffe `:355-369`)
**Move:** 3 (consumer contract: narrowing or widening the accepted input), 8 (nullability, applied to shape)
**Confidence:** High on the behaviour (probed); Medium on the impact
**Legibility-target:** the author and the next reviewer of the settings-shape contract in the FAILS CLOSED header

**Evidence:** `  elif ((.deny // []) | type != "array" or any(.[]; type != "string"))` (`:145`), and `| if explode | any(. == 0) then error("NUL inside a rule string") else . end` (`:151`). Line 151 now sees allow records only, because deny records are no longer emitted. The deleted test: `@test "a NUL-split credentials deny rule fails closed instead of being dropped"`.

At 1a831ffe, a deny string with an embedded NUL failed closed: no approval on that call. At ed06dec1, the deny check at `:145` tests only that each entry is a string. Deny strings never reach the NUL check at `:151`, so such a file is now accepted and its allow rules approve. Probe, with project settings `{"permissions":{"allow":["Bash(cat:*)"],"deny":["Bash(*.cred\u0000entials.json*)"]}}` and command `cat ~/.claude/.credentials.json`: base 00a27a2f and U1 printed nothing; U2 printed the allow JSON (`/home/node/.claude/jobs/00bcf178/tmp/q092/agents/performance-review-q092a-2026-10-15/nul.sh`). This widens the accepted settings shape, and nothing says so. The fact-check's Claims 9, 10 and 18 checked null/false/non-string deny entries but not NUL. The commit, the header (`:69-73`) and the plan do not mention dropping this case, and two tests that pinned it are gone. The original reason for the check, a NUL splitting one deny record into a forged allow record, does go away once deny records are not emitted. The second test's reason, a credentials rule spelled so that it matches nothing, was a fail-closed backstop for a rule Claude Code may silently not match. Q-092 leaves that to Claude Code, unverified. The case is low-probability, since whoever can write a NUL into settings can also delete the rule. But it goes beyond the "Known and accepted" list in the preamble (quote splits, compound commands, globs).

**Recommendation:** Pick one and make it explicit. (a) Keep the old contract with a one-token change at `:145`: `any(.[]; type != "string" or (explode | any(. == 0)))`, and restore the NUL-split test. (b) Accept the change and say so in the FAILS CLOSED paragraph ("a NUL inside a deny rule is no longer checked") and in the plan's residual table.

#### `--permissions` now skips the settings files entirely, including their fail-closed check, and validates its input more loosely than they do

**Severity:** Informational
**Location:** `hooks/auto-approve-allowed-commands.sh:14-16, 79, 211-232`
**Move:** 3 (changed semantics of an existing option), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** test authors using `--permissions`

**Evidence:** `# Fill ALLOW_PREFIXES. --permissions replaces the settings files (testing), and` / `# then they are not read.` (`:211-212`), and `      | jq -j '.[]? | select(type == "string" and (explode | any(. == 0) | not)) | . + "\u0000"' 2>/dev/null)` (`:223`).

Before this unit, `--permissions` replaced only the allow lists. The settings files were still read for their deny lists, and a malformed file still failed closed. Now a call with `--permissions` ignores the settings files completely. Probe: global settings `{bad`, `--permissions '["Bash(ls:*)"]'`, command `ls -la`. U1 printed nothing; U2 printed allow. This is a semantic change to an existing option, but it is documented (`:79`, `:211-212`), it makes the usage line at `:15` ("instead of reading from settings files") true for the first time, and the wired call never passes the option. The asymmetry is older than this unit. The settings path rejects a non-array `allow` and fails closed on a NUL. `--permissions` uses `.[]?` and `select(...)`, so it accepts an object's values (`--permissions '{"a":"Bash(ls:*)"}'` approves `ls -la`; probed) and silently drops a NUL rule. Now that `--permissions` is a full stand-in for the settings files, the two input contracts diverge more visibly.

**Recommendation:** No change needed for the merge. Optionally, note at `:14-16` that `--permissions` bypasses settings validation and fail-closed handling, so that nobody writes a fail-closed test against it.

#### `--deny` is still swallowed silently (carried from unit 1)

**Severity:** Informational
**Location:** `hooks/auto-approve-allowed-commands.sh:274-276`; `test/auto-approve-allowed-commands.bats:182-186`
**Move:** 6 (versioning impact)
**Confidence:** High
**Legibility-target:** maintainers of stale callers

**Evidence:** `      *)` / `        shift` (`:274-275`); `@test "the hook ignores a --deny argument (the option was removed in Q-092)"` (`:182`).

Context only: unit 1 removed the option, and its review filed this. In this unit the consequence is stronger. A stale `--deny '["Bash"]'` caller used to get the settings deny rules as a fallback. Now it gets no deny rules at all from the hook. No such caller exists in the repo, and the test pins the behaviour.

**Recommendation:** None. Optionally add a `debug` line in the `*)` arm.

## What Looks Good

- **The stdout contract is now pinned.** The test at `test/auto-approve-allowed-commands.bats:147-168` checks the source for exactly one `permissionDecision` spelling and runs eight commands and three degenerate inputs, asserting each stdout is empty or exactly `ALLOW_JSON`. That is the precondition Q-092 asked for: the hook never emits `ask`. The "every exit path" overstatement is already a fact-check item.
- **The settings-file shapes the hook rejects are unchanged except for the NUL case above.** Non-object files, non-object `permissions`, non-array `allow`, and non-array or non-string `deny` all still fail closed (fact-check Claims 9/10/18, probed). The deny shape check now raises a single message, "permissions.deny is not an array of strings" (`:146`), instead of two. Only debug output sees that string, since jq's stderr goes to /dev/null.
- **`hooks/wiring.json`** changes only `_comment` (`:39-46`). The file is still valid JSON (`jq -e '._comment|type'` → `"array"`), and the wired hook entries (`:75-86`) are byte-identical, so the linker's merge and `test/link-claude-home-wiring.bats:194,205` are unaffected.
- **`parse_commands`** is unchanged: same option parser (`:810-853`), same output, and its test (`test/...:429-432`) still passes.
- **Docs move with the contract.** The guide (`guides/bare-host-hook-wiring.md:156-161`), the wiring comment, decision log row 53 and the linker test comment all say the hook no longer reads deny rules. `rg 'WHAT THE DENY CHECK'` finds no live reference.
- Both suites pass in this worktree: `bats test/auto-approve-allowed-commands.bats test/link-claude-home-wiring.bats`, 49/49.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A NUL inside a `permissions.deny` rule no longer fails closed (accepted settings shape widened silently; two tests deleted) | Minor | `hooks/auto-approve-allowed-commands.sh:145, 151` | High |
| 2 | `--permissions` now bypasses the settings files and their fail-closed check; its input validation is looser than theirs | Informational | `hooks/auto-approve-allowed-commands.sh:211-232` | High |
| 3 | `--deny` still swallowed silently (carried from unit 1) | Informational | `hooks/auto-approve-allowed-commands.sh:274-276` | High |

## Overall Assessment

Unit 2 is consistent with the hook's established contracts. The wired invocation, the stdout contract (now pinned by a test), `parse_commands` and `wiring.json`'s hook entries are all unchanged, and every in-repo caller still works. The one real contract change outside the known residuals is narrow: the shape check that replaced the deny reader dropped the NUL-in-deny fail-closed case, and its two tests went with it. Either restore it with one jq clause or name it in the header. The `--permissions` change is deliberate and documented. Consumer impact is limited to the test suite.

## Goal-Alignment Note

The goal is to land Q-092 unit 2 clean: the hook stops interpreting deny rules, Claude Code becomes their one interpreter, and the hook never emits `ask`. The API surface supports that. The hook's only decision is `allow`, a test pins it, and no caller in `devcontainer-config/`, `scripts/` or `test/` depends on the removed behaviour. Finding 1 is the only item that adds to the preamble's "Known and accepted" list. It is a fail-closed edge (a NUL-split deny rule), not a bypass family the plan already accepts. It should be fixed or written into the residuals before merge, but it is Minor and does not argue against the removal. Outside my lanes, for the record: `hooks/guard-trusted-writes.py:364-367` emits `ask` on some Bash calls (a SOFT-tier write in a web-tainted session) under the same `Bash` matcher. Per #39344, that can turn a deny into a prompt for that call. This predates Q-092 and the unit does not change it, but "the hook never emits ask" is true of this hook, not of every hook on Bash.
