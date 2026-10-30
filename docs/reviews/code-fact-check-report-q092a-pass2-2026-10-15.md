Commit: b973e678

# Code Fact-Check Report

**Repository:** /home/node/.claude/jobs/00bcf178/tmp/q092/wt-u1 (branch fix/q092a-drop-deny-option)
**Scope:** `git diff 1a831ffe..b973e678` (hooks/auto-approve-allowed-commands.sh, test/auto-approve-allowed-commands.bats, docs/working/plan-q092-drop-hook-deny-reader.md rows F3, F6, F6b, F10) plus the commit message of b973e678. Loop pass 2 of Q-092 unit 1. Review artifacts added under docs/reviews/ are inputs, not claims under check. Earlier commits (00a27a2f..1a831ffe) are context only.
**Checked:** 2026-10-15
**Replication:** k=1 (loop pass, decision 031)
**Commit:** b973e678
**Total claims checked:** 21
**Summary:** 19 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution artifacts live under `/home/node/.claude/jobs/00bcf178/tmp/q092/agents/code-fact-check-report-q092a-pass2-2026-10-15/` (called `$A` below): scripts `mut.sh`, `m4.sh`, `probe.sh`, `old.sh`, `extra.sh`; captured output in `$A/logs/`. Every run used cwd `/home/node/.claude/jobs/00bcf178/tmp/q092/wt-u1` (bats) or an isolated `$A/probe*/proj` git repo with a fake `HOME` (probes). Mutants were built on copies under `$A/m*/`; the worktree was not modified.

Baseline: `timeout 600 bats test/auto-approve-allowed-commands.bats`, 2026-10-15T12:03:48Z, exit 0, 43/43 ok (`$A/logs/baseline.txt`).

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The relevant class is "a specific measured value quoted from an artifact set that does not contain it" (entries first seen 2026-09-12 and 2026-09-25). Claim 16 ("Unit size 403") matches that class and was re-measured. The value holds.

## Rubric "Fixed" items: do the fixes hold?

| Rubric item | Holds? | Claim |
|---|---|---|
| A1 NUL `--permissions` test could not tell drop from split | Yes. The mutant without the NUL filter now fails test 27 | 14 |
| A2 `Bash(ls *)` "approves nothing" | Yes. Header and test corrected; executed probe agrees | 11, 15 |
| A3 ROLE called the check unverified and load-bearing | Yes. ROLE cites Q-082 | 8 |
| A4 per-extracted check and escaping untested | Yes. Both mutants now fail test 14 (they passed 42/42 against the 1a831ffe test file) | 13a, 17 |
| C2 stdout test comment "every exit path" | Yes | 12 |
| C3 residual list lacked backslash/whole-word quoting | Yes. Executed | 9 |
| C4 `--permissions` line and relative CLAUDE_CONFIG_DIR line | Yes. Executed | 7, 10 |
| C5 plan F3 listed `${X:-push}` | Yes. Executed | 1 |

---

## Claim 1: "Quote or backslash spellings (`.cred""entials.json`, `.c\redentials.json`, `git "push"`, `cat "secret"` vs `Bash(cat secret)`; `${X:-push}` is refused by the shape allowlist anyway) | hook's de-quoted match fell through → prompt | hook allows"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's decision for the five listed spellings at 00a27a2f (before) and at b973e678 (after unit 1), with an allow list that covers their words and deny rules `Bash(*.credentials.json*)`, `Bash(git push:*)`, `Bash(cat secret)`. Does not establish Claude Code's own matcher behaviour (the row's "Not verified" status, accepted per the preamble), and does not cover spellings beyond the five.

Executed: `timeout 300 bash $A/probe.sh` (2026-10-15T12:05:52Z, exit 0) against b973e678, and `timeout 300 bash $A/old.sh` against `git show 00a27a2f:hooks/auto-approve-allowed-commands.sh`. Captured output:

```
# $A/logs/probe-old.txt (00a27a2f)          # $A/logs/probe.txt (b973e678)
cat ~/.claude/.cred""entials.json  not approved    APPROVED
cat ~/.claude/.c\redentials.json   not approved    APPROVED
git "push" origin                  not approved    APPROVED
cat "secret"                       not approved    APPROVED
git ${X:-push} origin              not approved    not approved
```

The `${X:-push}` refusal comes from the shape filter, `hooks/auto-approve-allowed-commands.sh:691-692`: `elif .Type == "ParamExp" and (plain_param | not) then "parameter expansion with an operator"`.

**Evidence:** `docs/working/plan-q092-drop-hook-deny-reader.md:38`, `hooks/auto-approve-allowed-commands.sh:691-692`, `$A/logs/probe.txt`, `$A/logs/probe-old.txt`

---

## Claim 2: "no approval for bad JSON or a bad `permissions`, `allow`, `deny` or `ask` (U2 makes each, when present, an array of NUL-free strings)"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "After" column read as the state after both stacked units, against unit 2's jq at `/workspace/.claude/wt-q092` (72b8c825, which contains b973e678). Does not establish that unit 1 alone checks `ask`: it does not (executed probe: `"ask":7` still approves, `$A/logs/probe.txt` line `F6-unit1-ask-not-checked`). The row attributes the check to U2, and the plan's table describes the whole stack.

Unit 2's program, `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:156-158`:

```
    (["allow", "deny", "ask"][] as $k | select(has($k)) | .[$k]
     | if type == "array" and all(.[]; type == "string" and (explode | any(. == 0) | not))
       then empty else error("permissions.\($k) is not an array of NUL-free strings") end),
```

(excerpt ends :158; the enclosing SETTINGS_RULES_JQ heredoc continues to :161 — read)

**Evidence:** `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:146-161`, `hooks/auto-approve-allowed-commands.sh:157-175`, `$A/logs/probe.txt`

---

## Claim 3: "Security review q092b: Claude Code 2.1.300 can ignore a whole settings file for an invalid value"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:41`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that security-review-q092b says this and that the installed 2.1.300 binary carries the message. Does not establish which values, or which load path (startup vs. a settings-writing command), trigger the drop. The review itself rates reachability Low.

The review (`/workspace/.claude/wt-q092/docs/reviews/security-review-q092b-2026-10-15.md:50`): "Claude Code 2.1.300 (the binary in this image) has a path that drops an entire settings file: its strings include "`does not load (`... `is not valid), so Claude Code ignores the whole file`"". Executed: `claude --version` gives `2.1.300 (Claude Code)`. `grep -a -o` on `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` returns `` `${Ks(r)} does not load (${m}), so Claude Code ignores the whole file, including anything `` and a nearby `not valid` reason string (2026-10-15, exit 0, output shown in this session; not captured to a file because the binary match is a single minified line).

**Evidence:** `/workspace/.claude/wt-q092/docs/reviews/security-review-q092b-2026-10-15.md:39-54`

---

## Claim 4: "for a value outside those keys the hook still approves from the file's allow rules while its deny rules are gone. Before Q-092 the reader still saw the deny rule. Residual, stated in the header"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:41`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's approval from a file with an invalid off-key value (`defaultMode:42`, `ask:7`) and the pre-U2 deny reader still matching that file's deny rule, plus the header statement in unit 2. Does not establish that Claude Code drops such a file (Claim 3). "The header" means unit 2's header: b973e678's own header does not carry this residual.

`$A/logs/probe.txt` at b973e678 (deny reader still present): settings `{"defaultMode":42,"permissions":{"allow":["Bash(cat:*)"],"deny":["Bash(*.credentials.json*)"],"ask":7}}` → `cat x` APPROVED, `cat ~/.claude/.credentials.json` not approved. The reader still sees the deny rule. Unit 2's header, `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:80-82`: "RESIDUAL: a value the hook does not check (another key, a BOM) can still make Claude Code drop the file, and its deny rules with it, while its allow rules approve here".

**Evidence:** `$A/logs/probe.txt`, `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:74-82`

---

## Claim 5: "F6b | Settings file Claude Code drops for a reason the hook does not check (e.g. a bad `defaultMode`, a BOM) | the hook's deny reader still matched its deny rules | no backstop"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "Before" column for both examples at b973e678, where the reader is still present. Does not establish that Claude Code actually drops a BOM or bad-`defaultMode` file (Claim 3's residue).

`$A/logs/extra.txt` (2026-10-15T12:08–12:09Z, exit 0): a BOM-prefixed settings file gives `BOM | cat x | {"hookSpecificOutput":...,"permissionDecision":"allow"}` and `BOM | cat ~/.claude/.credentials.json | <empty>`. jq accepts the BOM, allow rules feed approval, and the deny rule still blocks. For bad `defaultMode`, see Claim 4.

**Evidence:** `$A/logs/extra.txt`, `$A/logs/probe.txt`

---

## Claim 6: "Q-082 did not record its version (Q-091, the same day, saw 2.1.284 on the host); the image installs `@latest` (2.1.300 here). Re-test trigger in the header."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:46`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Q-082 and Q-091 archive text, the Dockerfile default, the installed version and unit 2's header. Does not establish the host's current version. The header with the trigger is unit 2's (b973e678's header has none).

Q-082's archive entry (`docs/working/questions-archive.md`, `### Q-082`) contains no `2.1.` version string (paraphrased — no quote available because the claim covers absence of text; checked by reading the whole entry). Q-091 (answered 2026-09-28, the same day as Q-082's answer): "it printed `2.1.284 (Claude Code)`" from the user's host command `rm ~/claude-workflows/.git/commondir && claude --version`. `devcontainer-config/Dockerfile:19`: `ARG CLAUDE_CODE_VERSION=latest`. `:403`: `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`. Executed: `claude --version` → `2.1.300 (Claude Code)`. Unit 2 header `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:57-59`: "re-run Q-082's test when a Claude Code release changes how a PreToolUse permissionDecision combines with permission rules, or before relying on this after a major version."

**Evidence:** `docs/working/questions-archive.md` (Q-082, Q-091), `devcontainer-config/Dockerfile:19`, `devcontainer-config/Dockerfile:403`, `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:55-59`

---

## Claim 7: "--permissions JSON      Use custom allow rules instead of the settings files' allow lists"

**Location:** `hooks/auto-approve-allowed-commands.sh:15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers load_rules with a non-empty `--permissions`: settings allow rules skipped, settings deny rules and DENY_ALL still applied, custom rules added. Does not cover `--permissions ''`, which is treated as absent (the `-z` test).

`hooks/auto-approve-allowed-commands.sh:274-277`:

```
    if [[ "$rec" == A$'\t'* && -z "$CUSTOM_PERMISSIONS" ]]; then
      add_allow_rule "${rec#A$'\t'}"
    elif [[ "$rec" == D$'\t'* ]]; then
      add_deny_rule "${rec#D$'\t'}"
```

(excerpt ends :277; load_rules continues to :288 — read; :281-287 add the custom rules)

Executed (`$A/logs/probe.txt`): settings allow `Bash(ls:*)`, deny `Bash(ls -la)` → `--permissions '["Bash(ls:*)"]'` with `ls -la` not approved (settings deny kept). `--permissions '["Bash(cat:*)"]'` with `ls -x` not approved (settings allow replaced). `cat x` approved.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:265-288`, `$A/logs/probe.txt`

---

## Claim 8: "A host test (Q-082, 2026-09-28) showed Claude Code still applies permissions.deny after a hook "allow" (a hook "ask" overrides it, Claude Code issue #39344, and this hook never asks), so the deny check below is redundant, and Q-092's second unit removes it."

**Location:** `hooks/auto-approve-allowed-commands.sh:57-60`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Q-082 record and date, the hook's single decision string, and unit 2 removing the check. Does not open issue #39344 (no egress); it is cited as recorded in Q-082, Q-092 and decision log 53, as in pass 1's Claim 13.

Q-082: "**Answer (2026-09-28):** the user confirmed `/hooks` listed the test hook. So a PreToolUse hook `allow` does **not** override a matching `permissions.deny` rule." Executed: `grep -o '"permissionDecision":"[a-z]*"' hooks/auto-approve-allowed-commands.sh | sort -u` → only `"permissionDecision":"allow"`. This is also the first assertion of test 12, which passed in the baseline. The only stdout write is `:440`: `echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'`. Unit 2 (ed06dec1, in `/workspace/.claude/wt-q092`) drops `matches_deny`. Its header at `:63-65` reads "The hook used to read Bash deny rules itself ... so it is gone".

**Evidence:** `docs/working/questions-archive.md` (Q-082), `hooks/auto-approve-allowed-commands.sh:440`, `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:63-65`, `$A/logs/baseline.txt`

---

## Claim 9: "a quote or backslash inside or around a word (`.cred""entials.json`, `.c\redentials.json`, `git "push"` against `Bash(git push:*)`, `cat "secret"` against `Bash(cat secret)`) ... gets past them"

**Location:** `hooks/auto-approve-allowed-commands.sh:68-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four new examples against the hook's deny check at b973e678 (raw and extracted strings keep the quotes and backslash). Does not cover the pre-existing glob, brace and ANSI-C examples, which are context.

The extractor keeps quoting. `:557-561`: `elif .Type == "Lit" then .Value // ""` / `"\"" + (...) + "\""` / `"'" + (.Value // "") + "'"`. So neither the raw string nor the extracted string contains the denied text. Executed (`$A/logs/probe.txt`): all four are APPROVED, while their literal spellings (`cat ~/.claude/.credentials.json`, `git push origin`, `cat secret`) are not.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:555-569`, `hooks/auto-approve-allowed-commands.sh:385-436`, `$A/logs/probe.txt`

---

## Claim 10: "(an empty value falls back; a relative value approves nothing)"

**Location:** `hooks/auto-approve-allowed-commands.sh:81-82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers relative and empty CLAUDE_CONFIG_DIR, with and without `--permissions`. Does not cover a CLAUDE_CONFIG_DIR holding a newline (separate check at :192).

`:184-187`: `if [[ -n "${CLAUDE_CONFIG_DIR:-}" && "$CLAUDE_CONFIG_DIR" != /* ]]; then ... return 1`. load_rules then sets `DENY_ALL=true` (`:269-271`), and `matches_deny` returns 0 (`:296-298`). Executed (`$A/logs/probe.txt`): `CLAUDE_CONFIG_DIR=relhome` → `ls -la` not approved, also with `--permissions '["Bash(ls:*)"]'`. `CLAUDE_CONFIG_DIR=` → approved from the project rules.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:179-205`, `hooks/auto-approve-allowed-commands.sh:265-272`, `hooks/auto-approve-allowed-commands.sh:294-309`, `$A/logs/probe.txt`

---

## Claim 11: "Bash(ls *)   literal prefix `ls *`: `ls *` and `ls * -la`, never `ls -la` | glob: `ls -la`" and "it approves only commands that start with the text `ls *` (bash then expands that `*`)"

**Location:** `hooks/auto-approve-allowed-commands.sh:98-99`, `hooks/auto-approve-allowed-commands.sh:104-107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers is_command_allowed's three match forms for the prefix `ls *`, and the deny column's glob. "Only ... start with" is a necessary condition, not a sufficient one: `ls *x` starts with that text but is not approved (no space, slash or exact match). Does not establish Claude Code's own reading of the rule.

`:328-329`: `if [[ "$full_command" == "$allowed" ]] || [[ "$full_command" == "$allowed "* ]] || { [[ "$allowed" == *[\ /]* ]] && [[ "$full_command" == "$allowed/"* ]]; }`. The right-hand side is quoted, so the match is literal. Executed (`$A/logs/probe.txt`): `ls *` APPROVED, `ls * -la` APPROVED, `ls -la` not approved, `ls */x` APPROVED. All of these are consistent with "start with the text `ls *`". Deny side: add_deny_rule escapes the space and keeps `*`, so the pattern is `ls\ *`, which matches `ls -la` (`:249-256`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:314-337`, `hooks/auto-approve-allowed-commands.sh:241-258`, `$A/logs/probe.txt`

---

## Claim 12: "over main's exit paths for approved, refused, unparseable, unlisted, empty and malformed input (the jq-missing exit is not reached)"

**Location:** `test/auto-approve-allowed-commands.bats:148-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping from the test's inputs to main's exits at `:371-373`, `:380-383`, `:387-390`, `:404-408`, `:417-420`, `:438-445`, plus the set -e failure on non-JSON input. Does not claim the jq-missing exit (`:358-361`) is reached, and it is not.

Inputs at `:157-158`: `'ls -la'` (approved), `'cat ~/.claude/.credentials.json'` (raw deny exit), `'ls $(pwd)'` and `$'ls ('` (extraction fails: shape refusal or parse error), `'python3 x'` (unlisted), `''` (no command), `'# comment'` (extracts to nothing), and `"$REPRO"`. Then `:162-168`: a malformed global file (no allow prefixes, since jq errors before emitting), `'{}'` (no command) and `'not json'` (jq fails under set -e). The test passed in the baseline (`$A/logs/baseline.txt`).

**Evidence:** `test/auto-approve-allowed-commands.bats:147-169`, `hooks/auto-approve-allowed-commands.sh:339-446`

---

## Claim 13a: "Pins the per-extracted-command check and add_deny_rule's escaping, which the raw check alone does not exercise"

**Location:** `test/auto-approve-allowed-commands.bats:213-224`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two mutants: deleting the per-extracted `matches_deny` block (`:427-430`), and making add_deny_rule append every character unescaped (`:254`). Does not cover partial-escaping mutants (see 13b).

Command: `timeout 600 bash $A/mut.sh` (2026-10-15T12:04:27Z–12:05:15Z). Each mutant runs the full suite on a copy. m0 (unmodified) gives 43 ok. m1 (per-extracted check deleted) gives 42 ok, `not ok 14 ... only * is a wildcard`, failing at line 219 (`ls | rm -rf x` approved). m2 (no escaping) gives 42 ok, `not ok 14`, failing at line 221 (`cat notes[1].txt` approved). For `ls | rm -rf x`, the raw string does not match the glob `rm\ \-rf*` because it starts with `ls`, so only the per-extracted check at `:427` catches it.

**Evidence:** `test/auto-approve-allowed-commands.bats:213-224`, `hooks/auto-approve-allowed-commands.sh:241-258`, `hooks/auto-approve-allowed-commands.sh:422-436`, `$A/logs/mutants-summary.txt`, `$A/logs/m1.bats.txt`, `$A/logs/m2.bats.txt`

---

## Claim 13b: test title "...; only * is a wildcard"

**Location:** `test/auto-approve-allowed-commands.bats:213`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test pins about wildcard characters. Does not dispute the code's behaviour: add_deny_rule does escape `?` and extglob characters (`:251-255`). The test only fails to pin them.

The test exercises only `[...]` (`Bash(cat notes[1].txt)`). Mutant m4 lets `?` through as a live wildcard: `[[ "$c" == [A-Za-z0-9*?] ]]` at `:251`. The suite still passes 43/43 (`timeout 600 bash $A/m4.sh`, 2026-10-15T12:07:40Z, bats exit 0). The precise title would be "brackets are literal" or similar, or the test could add a `?` case.

**Evidence:** `test/auto-approve-allowed-commands.bats:213-224`, `hooks/auto-approve-allowed-commands.sh:249-256`, `$A/logs/m4-summary.txt`, `$A/logs/m4.bats.txt`

---

## Claim 14: "Split rather than dropped, the second half would approve curl."

**Location:** `test/auto-approve-allowed-commands.bats:364-366`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--permissions` NUL filter at `:285`. Does not cover the settings-file NUL check (separate tests).

Mutant m3 removes `and (explode | any(. == 0) | not)` from `:285`. It gives 42 ok, `not ok 27 a NUL inside a --permissions rule drops that rule only`, failing at line 366 (`not_approved` for `curl x`) (`$A/logs/m3.bats.txt`). Pass 1's A1 defect is fixed.

**Evidence:** `test/auto-approve-allowed-commands.bats:363-369`, `hooks/auto-approve-allowed-commands.sh:281-287`, `$A/logs/m3.bats.txt`

---

## Claim 15: test title "rule table: Bash(ls *) is a literal prefix, not a glob"

**Location:** `test/auto-approve-allowed-commands.bats:403-408`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two assertions (`ls -la` not approved, `ls * -la` approved) and the header row they pin. Does not cover the deny column.

Passed in the baseline. The probe results match (Claim 11).

**Evidence:** `test/auto-approve-allowed-commands.bats:403-408`, `$A/logs/baseline.txt`, `$A/logs/probe.txt`

---

## Claim 16: "Unit size 403 after this commit (loop tolerance ~800)."

**Location:** commit b973e678 message (Notes line)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pr-prep step 1a's count against base `merge/ready-2026-10-15` (= 00a27a2f, the merge-base) and the ~800 limit in review-fix-loop's size re-check. Does not check the commit-body format: the workflow asks for `Size: <count> code lines against <BASE>`.

Command from `workflows/pr-prep.md` step 1a: `git diff --numstat 00a27a2f...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` → `403` (cwd worktree, exit 0, 2026-10-15). Per file: hook 40+77, test 117+169. 1a831ffe counted 365. `workflows/review-fix-loop.md:57`: "The unit's limit is ~800 lines (twice the entry cap)". Matches prior hallucination pattern class (measured value), and the value holds here.

**Evidence:** `workflows/pr-prep.md:89-92`, `workflows/review-fix-loop.md:57`, command output in this session

---

## Claim 17: "a settings-file test pins the per-extracted-command deny check and add_deny_rule's escaping, which lost their only tests"

**Location:** commit b973e678 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers m1/m2 against the 1a831ffe test file (no test kills them) and against b973e678's (test 14 kills both). The b973e678 hook diff is comment-only, so the same mutants apply to both. "Escaping" is pinned for brackets only (Claim 13b).

`timeout 600 bash $A/extra.sh`: the hook diff 1a831ffe..b973e678 has no non-comment lines ("(none)"). m1 and m2 against `git show 1a831ffe:test/...` each give bats exit 0, 42 ok (`$A/logs/m1.oldtest.txt`, `$A/logs/m2.oldtest.txt`). Against b973e678, see Claim 13a.

**Evidence:** `$A/logs/extra.txt`, `$A/logs/m1.oldtest.txt`, `$A/logs/m2.oldtest.txt`, `$A/logs/mutants-summary.txt`

---

## Claim 18: "plan F3, F6 and F10 updated from the unit 2 security review"

**Location:** commit b973e678 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which review each plan-row change traces to. Does not judge the rows' content (Claims 1-6).

F6 and F10 do trace to security-review-q092b (Finding 1 at `:39-54`, the F10/version text at `:69`). F3's changes trace to unit 1's reviews: the `${X:-push}` removal is security-review-q092a Finding 2 (`docs/reviews/security-review-q092a-2026-10-15.md:78`: "Drop `${X:-push}` from F3, or note that the shape check refuses it"). The backslash and whole-word spellings are rubric C3 (fact-check and security-reviewer, q092a). The q092b review mentions F3 only as "known and accepted" (`:79`). The commit also adds row F6b, which it does not mention. Precise version: "plan F3 updated from the unit 1 reviews; F6, F6b and F10 from the unit 2 security review".

**Evidence:** `docs/reviews/security-review-q092a-2026-10-15.md:74-78`, `/workspace/.claude/wt-q092/docs/reviews/security-review-q092b-2026-10-15.md:39-79`, `docs/reviews/code-review-rubric-2026-10-15-fix-q092a-drop-deny-option.md` (C3, C5)

---

## Claim 19: "false/null permission lists counting as absent is left to unit 2's stricter check"

**Location:** commit b973e678 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unit 1 still treating `deny:false` as absent, and unit 2's jq rejecting a present-but-null/false key. Does not run unit 2's test suite.

Unit 1 `:169`: `((.deny // []) | ...`. Executed: `deny:false` with `cat x` → APPROVED (`$A/logs/probe.txt`, `C1-deny-false`). Unit 2 `:156`: `select(has($k)) | .[$k] | if type == "array" and ... then empty else error(...)`. A present `false` or `null` is not an array, so it errors. Unit 2's header `:143-144` says "when present (even as null or false), must each be an array of strings".

**Evidence:** `hooks/auto-approve-allowed-commands.sh:167-171`, `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:143-161`, `$A/logs/probe.txt`

---

## Claim 20: "two pre-existing header errors (--permissions, relative CLAUDE_CONFIG_DIR) are corrected"

**Location:** commit b973e678 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both old lines were present at 00a27a2f (before the unit) and were wrong. Correctness of the new text is Claims 7 and 10.

`git show 00a27a2f:hooks/auto-approve-allowed-commands.sh`: `:15` `--permissions JSON      Use custom permissions instead of reading from settings files` (the settings deny lists were still read, see `:274-277` now). `:90` `back; a relative value is used as written, from the hook's cwd), then`, while the same file's `:193` already had `debug "CLAUDE_CONFIG_DIR is relative: denying everything"`.

**Evidence:** `git show 00a27a2f:hooks/auto-approve-allowed-commands.sh` lines 15, 90, 193

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 13b** (`test/auto-approve-allowed-commands.bats:213`): the title says "only * is a wildcard", but only `[...]` is pinned. A mutant that leaves `?` live passes 43/43. Add a `?` case or narrow the title.
- **Claim 18** (commit b973e678 message): F3's update came from the unit 1 reviews (security q092a Finding 2, rubric C3), not the unit 2 security review. Row F6b was also added and is not mentioned.

### Unverifiable
- None.

## Goal-Alignment Note

The goal is to land Q-092 as two stacked units, each reviewed clean. Every pass-1 rubric item marked Fixed (A1-A4, C2-C5) holds under execution. The two new tests kill the mutants they were written for (per-extracted check, escaping, NUL filter), and those mutants survived the 1a831ffe tests. The header's ROLE, RESIDUALS and rule table match the code. Plan rows F3/F6/F6b/F10 match the code, the archive and the installed binary, with "the header" in F6/F10 meaning unit 2's header. The unit size is 403, under the ~800 loop limit. Neither remaining finding is blocking: a test-title overstatement and a commit-message attribution slip. Nothing found beyond the accepted F3/F4 residual: the newly listed spellings are approved exactly as the header says.
