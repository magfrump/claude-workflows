Commit: dbb15ec6

# Security Review — Q-092 unit 1, loop pass 2 (q092a, fix/q092a-drop-deny-option)

**Scope:** delta `git diff 1a831ffe..dbb15ec6`: `hooks/auto-approve-allowed-commands.sh` (header comments only), `test/auto-approve-allowed-commands.bats`, `docs/working/plan-q092-drop-hook-deny-reader.md` (F3/F6/F6b/F10). The review artifacts the delta adds were read as inputs, not reviewed.
**Date:** 2026-10-15
**Based on:** docs/reviews/security-review-q092a-2026-10-15.md (pass 1), docs/reviews/code-review-rubric-2026-10-15-fix-q092a-drop-deny-option.md, docs/reviews/code-fact-check-report-q092a-pass2-2026-10-15.md

## Trust Boundary Map

```
B1: [model-authored Bash command (tool_input.command)] → [matches_deny(raw), shfmt + refuses_construct, matches_deny(each extracted), is_command_allowed] → [hook stdout "allow"]
B2: [settings files: global, project, project-local]    → [read_settings_rules jq (fail closed → DENY_ALL)]                          → [ALLOW_PREFIXES / DENY_GLOBS]
B4: [hook stdout]                                        → [Claude Code permission engine (deny applied after hook allow, Q-082)]    → [execution]
```

```
S1: tool_input.command              — request-time    — UNTRUSTED (all sinks)
S2: settings files (global/project) — runtime-mutable — UNTRUSTED for the approve decision (project files are model-writable via Edit/Write)
S3: --permissions CLI arg           — deploy-time     — test-only; wiring passes no options
```

The delta changes no executable line of the hook: `git diff 1a831ffe..dbb15ec6 -- hooks/` touches only `#` comment lines (header lines 15, 54-71, 82, 98-108). Boundaries B1/B2/B4 are therefore as pass 1 mapped them; the delta adds tests on B1/B2 and corrects documentation of them.

## Pass-1 findings: fix verification

| Pass-1 finding | Rubric says | Verified |
|---|---|---|
| 1 (Low): per-extracted deny check and add_deny_rule escaping unpinned | A4 Fixed: new settings-file test | Yes. New test "a prefix deny rule blocks an extracted command inside a pipeline; only * is a wildcard" uses an anchored rule `Bash(rm -rf:*)` against `ls \| rm -rf x` (needs the extracted check: the raw string starts with `ls`), plus `Bash(cat notes[1].txt)` / `Bash(cat file?.txt)` with positive controls `cat notes1.txt` and `cat file1.txt` approved, so an unescaped `[`/`?` mutant would match `notes1.txt`/`file1.txt` and fail the test. The `?` case (dbb15ec6) closes the pass-2 fact-check gap C7. Suite 43/43 at dbb15ec6. |
| 2 (Info): `${X:-push}` listed as exposed | C5 Fixed | Yes. Plan F3 now reads "`${X:-push}` is refused by the shape allowlist anyway". |
| Fact-check residual-list gap (backslash, whole-word quoting) | C3 Fixed | Yes. Header :67-70 and plan F3 now name `.c\redentials.json`, `git "push"`, `cat "secret"` vs `Bash(cat secret)`, which is exactly the family of new ALLOWs pass 1 measured. |

## Findings

No findings.

## Bypass enumeration (move 11)

No guardrail logic changed in the delta. Candidates checked against the delta's new claims:
- The new NUL test `["Bash(zz)\u0000Bash(curl:*)"]`: a split (rather than dropped) rule would yield `Bash(curl:*)` and approve `curl x`; the test asserts not approved, and the `--permissions` filter (`select(type == "string" and (explode | any(. == 0) | not))`) drops the whole string. Tested (suite).
- `Bash(ls *)` allow rule approving `ls * -la`: bash expands `*` at run time, so this rule approves "ls of every file in cwd". That is a property of the allow side, now documented accurately rather than "approves nothing"; it is no wider than `Bash(ls:*)`. Tested (suite).
- Plan F6 row text says "U2 makes each, when present, an array of NUL-free strings": true of unit 2 (c9ff3e84), not of this unit, which still reads deny rules itself. The row is labelled U2, so it does not misstate unit 1. Read-static.

### Untested bypass candidates
None new; pass 1's two (extglob characters in a deny rule, `$"..."` mid-word) are unchanged and moot once unit 2 lands.

## Endorsement Claims

- **Claim:** The delta changes no executable line of `hooks/auto-approve-allowed-commands.sh`.
  **Location:** `hooks/auto-approve-allowed-commands.sh:15, 50-108`
  **Evidence:** executed
  **Verified:** `git diff 1a831ffe..dbb15ec6 -- hooks/` shows only lines beginning `#` changed.
  **Not verified:** nothing further needed for this claim.
- **Claim:** The per-extracted-command deny check and the add_deny_rule escaping of `[` and `?` are now pinned by a test that a mutant removing either would fail.
  **Location:** `test/auto-approve-allowed-commands.bats:213-228`
  **Evidence:** read-static (test design) + executed (suite passes 43/43)
  **Verified:** test reads an anchored rule and positive controls; suite run at dbb15ec6.
  **Not verified:** I did not re-run the mutants themselves this pass (pass 1 ran them at 1a831ffe; the rubric's C7 records the `?` mutant passing before dbb15ec6).
  **route: code-fact-check**

## Primitive sweep

Primitive sweep: no dangerous primitive call site added or changed in the delta (comment and test edits only). Pass 1's sweep of `[[ "$str" == $glob ]]` and the shfmt/jq/perl exec sites stands unchanged.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

Both pass-1 findings are fixed as the rubric says, and the fix introduced nothing: the hook delta is comment-only, the new test pins the two mechanisms pass 1 found unpinned, and the documented residual family now matches the measured one. No findings within the code paths read; the routed endorsement claim is pending execution verification of the mutants.

## Goal-Alignment Note

Unit 1's goal is to drop `--deny` and the de-quoted match without widening exposure beyond the accepted quote/backslash family. This pass confirms the documentation now names that family accurately and the remaining (soon-deleted) deny mechanisms are test-pinned for the window before unit 2.
