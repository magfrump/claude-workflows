Commit: 72b8c825

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q092 (branch fix/q092-drop-hook-deny-reader)
**Scope:** `git diff ed06dec1..72b8c825 -- hooks/ test/ docs/decisions/` plus commit 72b8c825's message (Q-092 unit 2, loop pass 2). Unit 1 (b973e678) and the docs/reviews/ and plan files are context only.
**Checked:** 2026-10-15
**Replication:** k=1 (loop pass, decision 031)
**Commit:** 72b8c825
**Total claims checked:** 27 (26 numbered; Claim 11 split into 11a/11b)
**Summary:** 24 verified, 1 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Environment: jq-1.6, Claude Code 2.1.300 in this container (`claude --version`). Execution logs (not committed; the pass may write only this report) live in `/home/node/.claude/jobs/00bcf178/tmp/q092/agents/code-fact-check-report-q092b-pass2-2026-10-15/`: `jqprobe.out` (filter probes, 2026-10-15T12:03:42Z), `mutate.out` (mutations and BOM probe, 12:04:42Z), `mutate2.out` (NUL-check mutation, 12:05:39Z), `mutate3.out` (no-ask mutation on the NUL test, `ls *` probes, 12:06:56Z), `suite.out` (full suite, 12:05:12Z). Every command ran with cwd as given below and exited 0 at the shell level; per-test outcomes are in the logs.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries); no claim below matches a logged pattern.

## Pass-1 rubric fixes

| Rubric item | Status claimed | Holds? | Evidence |
|---|---|---|---|
| A1 bypass family (non-string allow, null/false deny, any ask) | Fixed in part | Yes for the three keys; residual stated | Claims 1, 9-11b, 15, 17 |
| A2 NUL in deny no longer fails closed | Fixed | Yes (deny and ask) | Claims 14, 18 |
| A3 version drift / Q-082 version | Fixed | Yes | Claims 5, 7 |
| C1 "array of strings" overstated | Fixed by A1 | Yes | Claim 14 |
| C2 `Bash(ls *)` row wrong | Fixed | Yes | Claims 13, 20 |
| C3 ask unchecked, premise unstated | Fixed | Yes | Claims 10, 15 |
| C4 row 53 points at deleted sections | Fixed | Yes | Claim 6 |

---

## Claim 1: "The hook still fails closed on an unreadable or ill-shaped settings file, now also when `permissions.allow`, `.deny` or `.ask` is present but not an array of NUL-free strings."

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named keys present with null, false, string, object, number-element and NUL-string values, through the jq filter and through the hook (bats); does not establish behavior for keys other than these three, which the row's next sentences correctly leave as a residual.

The filter's check runs per key, only when the key exists:

```
# hooks/auto-approve-allowed-commands.sh:156-158
    (["allow", "deny", "ask"][] as $k | select(has($k)) | .[$k]
     | if type == "array" and all(.[]; type == "string" and (explode | any(. == 0) | not))
       then empty else error("permissions.\($k) is not an array of NUL-free strings") end),
```

Executed (`bash jqprobe.sh`, cwd the temp dir, extracting the filter verbatim from the hook): `{"permissions":{"allow":null}}`, `allow:false`, `allow:[5]`, `allow:[null]`, `allow:["a\u0000b"]`, `deny:null`, `deny:false`, `deny:[1]`, `deny:["a\u0000"]`, `ask:"Bash"`, `ask:[1]`, `ask:null`, `ask:{}` each give `rc=5` and the error text; `ask:[]`, `ask:["ok"]`, `permissions:{}` give `rc=0`, no output. `load_rules` then keeps no rule (Claim 15). Full suite 34/34 ok.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:152-162`, `hooks/auto-approve-allowed-commands.sh:225-241`; `jqprobe.out`; `suite.out`

---

## Claim 2: "Not verified on a host: whether Claude Code's matcher catches a quote or backslash spelling (`.cred""entials.json`) or a denied subcommand in a list, which the hook used to send to the prompt"

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the historical claim that the pre-Q-092 hook de-quoted (removing `'`, `"` and `\`) and checked extracted commands; does not establish Claude Code's own matcher behavior, which the sentence correctly marks unverified.

The pre-unit-1 hook stated its de-quoting: "de-quoted form of either (every `'`, `"` and `\` removed" (`git show 1a831ffe^:hooks/auto-approve-allowed-commands.sh`, line 71), and its deny check matched "the string or its de-quoted form" (same file, line 318). Unit 1's 1a831ffe header: "The hook never approves a command when a Bash deny rule matches the raw command or any extracted command" (line 67-68 of that revision), which is the subcommand-in-a-list case.

**Evidence:** `1a831ffe^:hooks/auto-approve-allowed-commands.sh:71`, `1a831ffe^:hooks/auto-approve-allowed-commands.sh:318-336`, `1a831ffe:hooks/auto-approve-allowed-commands.sh:67-68`

---

## Claim 3: "a glob spelling gets past both matchers anyway"

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond the hook side (the old reader matched text, so `.c*` never contained the denied string); does not establish Claude Code's matcher behavior on a glob spelling.

Carried over unchanged from ed06dec1's amendment; pass 1's Claim 3 and rubric C7 already accept it (plan F3/F4/F5). Verifying it needs a host run of Claude Code with `Bash(*.credentials.json*)` denied and a `.c*` spelling (paraphrased — no quote available because the claim's unverified half concerns Claude Code's closed binary, not repo code).

**Evidence:** `docs/decisions/log.md:76`; `docs/reviews/code-review-rubric-2026-10-15-fix-q092-drop-hook-deny-reader.md:37`

---

## Claim 4: "New residual: Claude Code can ignore a whole settings file for an invalid value the hook does not check, dropping its deny rules while the hook still approves from its allow rules."

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that Claude Code 2.1.300 carries a whole-file-ignore path and that the hook emits allow rules from a file with an unchecked invalid-looking value (`defaultMode: 7`); does not establish which values trigger Claude Code's drop (not traced, as the commit says).

Claude Code binary string (`grep -a` on `.../@anthropic-ai/claude-code/bin/claude.exe`): `does not load (${m}), so Claude Code ignores the whole file, including anything this command wrote there`, with `m` built from "`is not valid`", "`it could not be read`" or "`it is not a JSON object`". Hook side, executed: `{"permissions":{"defaultMode":7,"allow":["Bash(ls)"]}}` → `rc=0 out=Bash(ls)`.

**Evidence:** `jqprobe.out`; `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` (string)

---

## Claim 5: "Q-082 did not record its Claude Code version and the image installs `@latest`"

**Location:** `docs/decisions/log.md:76`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-082's archived text and the image build default; does not establish what version the Q-082 host actually ran.

`grep -i 'version\|2\.1\.'` over Q-082's archive entry matches nothing about a Claude Code version (paraphrased — no quote available because the claim covers absence of text). `devcontainer-config/Dockerfile:19` `ARG CLAUDE_CODE_VERSION=latest`, `:403` `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`, and `devcontainer-config/devcontainer.json:29` `"CLAUDE_CODE_VERSION": "latest",`.

**Evidence:** `docs/working/questions-archive.md` (`### Q-082`), `devcontainer-config/Dockerfile:19`, `devcontainer-config/Dockerfile:403`, `devcontainer-config/devcontainer.json:29`

---

## Claim 6: "the hook header's ROLE gives the re-test trigger, and its DENY RULES ARE CLAUDE CODE'S and FAILS CLOSED sections replace WHAT THE DENY CHECK GUARANTEES"

**Location:** `docs/decisions/log.md:76`
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the named sections and the trigger, and the absence of the old section; does not establish that every statement the old section held moved over (the deny guarantee itself was intentionally dropped).

`hooks/auto-approve-allowed-commands.sh:57-59`: "re-run Q-082's test when a Claude Code release changes how a PreToolUse permissionDecision combines with permission rules, or before relying on this after a major version." Sections at `:63` "DENY RULES ARE CLAUDE CODE'S (Q-092)." and `:74` "FAILS CLOSED on its inputs". `grep -n 'WHAT THE DENY CHECK'` on the hook: no match (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:49-82`

---

## Claim 7: "Q-082 did not record the Claude Code version (Q-091 saw 2.1.284 on the host that day) and the image installs @latest"

**Location:** `hooks/auto-approve-allowed-commands.sh:55-57`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that Q-091's answer records a host `claude --version` of 2.1.284 on 2026-09-28, the date of Q-082's answer; does not establish that Q-082's run used that same binary (the note says "that day", not "that run").

Q-091 archive: "**Answer (2026-09-28): [1].** The user ran `rm ~/claude-workflows/.git/commondir && claude --version`. ... it printed `2.1.284 (Claude Code)`". Q-082 archive: "**2026-09-28, second run** ... **Answer (2026-09-28):** the user confirmed `/hooks` listed the test hook." Q-093 adds "the host runs 2.1.284". `@latest`: see Claim 5.

**Evidence:** `docs/working/questions-archive.md` (`### Q-091`, `### Q-082`, `### Q-093`)

---

## Claim 8: "quote or backslash spelling (`.cred""entials.json`, `.c\redentials.json`, `git "push"`, `cat "secret"` against `Bash(cat secret)`) ... The hook used to send both to the prompt."

**Location:** `hooks/auto-approve-allowed-commands.sh:66-70`
**Type:** Behavioral (historical)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pre-Q-092 hook's de-quote (all `'`, `"`, `\` removed) and exact matching of a wildcard-free deny rule, so each listed spelling de-quoted to the denied text; does not establish Claude Code's matcher (stated unverified).

`1a831ffe^` header line 71: "de-quoted form of either (every `'`, `"` and `\` removed"; `.c\redentials.json` → `.credentials.json`, `cat "secret"` → `cat secret`. Unit 1's own fixes (b973e678) list the same examples in the then-residual list.

**Evidence:** `1a831ffe^:hooks/auto-approve-allowed-commands.sh:71`, `b973e678:hooks/auto-approve-allowed-commands.sh` (RESIDUALS)

---

## Claim 9: "if any settings file below exists but cannot be read, does not hold exactly one JSON object, or has a permissions that is not an object, or a permissions.allow, .deny or .ask (present at all) that is not an array of NUL-free strings, no command is approved on that call."

**Location:** `hooks/auto-approve-allowed-commands.sh:74-77`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed failure condition through the filter and `load_rules`; does not establish the literal reading of "a permissions that is not an object" for `null`, which is exempted.

`permissions: null` is not an object but is accepted, contributing nothing:

```
# hooks/auto-approve-allowed-commands.sh:153-155 (excerpt ends :155; enclosing filter continues to :162 — read)
| .permissions
| if . == null then empty
  elif type != "object" then error("permissions is not an object")
```

Executed: `{"permissions":null}` → `rc=0 out=''`, so other files' allow rules still approve. Every other listed condition fails (Claim 1; `[]`, `{}{}`, empty file in the wrong-shape test). Precise version: "has a permissions that is neither null nor an object". The `null` exemption predates this commit (ed06dec1 has the same branch); the new wording introduced the imprecision.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:146-162`; `jqprobe.out`

---

## Claim 10: "deny and ask are shape-checked, never read: Claude Code can ignore a whole settings file for an invalid value, and a file it drops should not feed allow rules here."

**Location:** `hooks/auto-approve-allowed-commands.sh:77-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that only allow strings are emitted and that Claude Code 2.1.300 has a whole-file-ignore path; does not establish the triggering values (Claim 11b).

Only `(.allow // [])[]` is emitted (`:159`); the check branch emits `empty`. Executed: `{"permissions":{"deny":["Bash(x)"],"allow":["Bash(ls)"]}}` → `out=Bash(ls)` only; `{"permissions":{"deny":["x"]}}` → empty. Binary string: Claim 4.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:156-159`; `jqprobe.out`

---

## Claim 11a: "RESIDUAL: a value the hook does not check (another key, a BOM)"

**Location:** `hooks/auto-approve-allowed-commands.sh:80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that another permissions key and a UTF-8 BOM pass the hook's loader with allow rules emitted; does not establish Claude Code's reaction (11b).

Executed: `{"permissions":{"defaultMode":7,"allow":["Bash(ls)"]}}` → `Bash(ls)`. BOM (`printf '\xef\xbb\xbf{"permissions":{"allow":["Bash(ls)"]}}'`, jq 1.6) → `B a s h ( l s ) \0`, `rc=0`.

**Evidence:** `jqprobe.out`; `mutate.out` ("BOM probe")

---

## Claim 11b: "can still make Claude Code drop the file, and its deny rules with it, while its allow rules approve here"

**Location:** `hooks/auto-approve-allowed-commands.sh:80-82`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about which values Claude Code treats as invalid; the hook half (allow rules approve) is Verified in 11a, and the drop path exists (Claim 4).

Whether a BOM or an unknown/invalid key such as `defaultMode: 7` triggers Claude Code's whole-file ignore was not traced (the commit's Notes say so). Needs either reading Claude Code's settings validator or a host run with such a file and a deny-listed command (paraphrased — no quote available because the subject is Claude Code's closed binary behavior). The modal "can" keeps this a stated risk, not a false claim.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:80-82`; commit 72b8c825 Notes

---

## Claim 12: "the deny reader used to cover that case."

**Location:** `hooks/auto-approve-allowed-commands.sh:82`
**Type:** Behavioral (historical)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that 1a831ffe's reader loaded deny rules from every readable settings file regardless of unrelated keys and refused approval on a raw or extracted-command match; does not establish coverage of spellings the reader itself missed (globs etc.).

```
# 1a831ffe:hooks/auto-approve-allowed-commands.sh:171-173
    ((.deny // []) | if type == "array"
                     then .[] | if type == "string" then "D\t" + . else error("non-string deny rule") end
                     else error("permissions.deny is not an array") end)
```

No check of other keys, so a file Claude Code dropped still had its deny rules applied by the hook.

**Evidence:** `1a831ffe:hooks/auto-approve-allowed-commands.sh:160-176`

---

## Claim 13: "Bash(ls *)   literal prefix, not a glob: `ls *` and `ls * -la` (bash then expands that `*`), never `ls -la` (use `Bash(ls:*)`)"

**Location:** `hooks/auto-approve-allowed-commands.sh:99-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named commands; does not establish an exhaustive list (`ls */x` is also approved via the path-prefix branch, consistent with "literal prefix").

`is_command_allowed` compares with quoted `"$allowed"` (`:260-261`), so `*` is literal. Executed (`bash mutate3.sh`, unmutated copy, `--permissions '["Bash(ls *)"]'`): `ls *` → allow, `ls */x` → allow, `ls -la` → empty. Test 20 covers `ls * -la`.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:251-268`; `mutate3.out`

---

## Claim 14: "Output records are NUL-terminated allow rules, so a rule string containing a newline stays one record. permissions.allow, .deny and .ask, when present (even as null or false), must each be an array of strings with no NUL; only allow is emitted."

**Location:** `hooks/auto-approve-allowed-commands.sh:141-145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers record framing, the three keys' shape rule including null/false, and allow-only emission; does not establish shape checks on other keys (none, as stated elsewhere).

`| . + "\u0000"` (`:161`). Executed: `allow:["x\ny"]` → `out=$'x\ny'` (one record); null/false/NUL cases per Claim 1; deny/ask never emitted per Claim 10.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:146-162`; `jqprobe.out`

---

## Claim 15: SETTINGS_RULES_JQ semantics in jq 1.6 (brief's checklist): `has`, `all(gen; cond)`, error ordering vs emitted records, and `load_rules` keeping no record on failure ("On failure no rule is kept, not even the records jq printed before its error")

**Location:** `hooks/auto-approve-allowed-commands.sh:152-162`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers jq 1.6 support for the builtins, ordering within one file and across files, and `load_rules`' discard; does not establish behavior under jq versions other than 1.6.

jq 1.6: `{"a":null} | has("a"), has("b")` → `[true,false]`; `[] | all(.[]; false)` → `true` (empty list passes, so `ask:[]` is valid). Within one file the check expression precedes `(.allow // [])[]` in the comma, so an error is raised before any allow record: `{"permissions":{"allow":["Bash(ls)"],"ask":[1]}}` and `{"permissions":{"deny":[1],"allow":["Bash(ls)"]}}` both print 0 bytes, `rc=5`. Across files a good earlier file's record is printed before a later file's error (`a.json` then `b.json`: `Bash(ls)\0` then `rc=5`); `load_rules` discards it:

```
# hooks/auto-approve-allowed-commands.sh:234-240 (excerpt ends :240; load_rules continues to :241 — read)
    mapfile -d '' records < <(read_settings_rules)
    if ! wait $!; then
      debug "A settings file could not be read or parsed: approving nothing"
      return 0
    fi
  fi
  for rec in "${records[@]}"; do add_allow_rule "$rec"; done
```

`permissions` with allow absent but deny present: `{"permissions":{"deny":["x"]}}` → empty, `rc=0`; `permissions:{}` → empty, `rc=0`.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:225-241`; `jqprobe.out`

---

## Claim 16: "Stdout alone (stderr dropped), over main's exit paths for approved, refused, unparseable, unlisted, empty and malformed input (the jq-missing exit is not reached)."

**Location:** `test/auto-approve-allowed-commands.bats:148-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping of the test's inputs to main's exits at `:305`, `:315`, `:333`, `:345`, `:366` and a `set -e` abort; does not establish the jq-missing exit `:292`, which the comment excludes.

Inputs: `'ls -la'` (approved, `:366`), `'ls $(pwd)'` and `$'ls ('` (refused/unparseable, `:333`), `'python3 x'` (unlisted, `:366` no output), `''` and `{}` (empty, `:305`), `'# comment'` (`:345`), `'{not json'` settings (`:315`), `'not json'` input (malformed; `jq` failure under `set -euo pipefail`). Main's `exit` lines per `grep -n 'exit '`: 292, 305, 315, 333, 345, 366.

**Evidence:** `test/auto-approve-allowed-commands.bats:147-171`, `hooks/auto-approve-allowed-commands.sh:271-367`

---

## Claim 17: New wrong-shape cases (`deny:null`, `deny:false`, `allow:[5]`, `allow:null`, `ask:"Bash"`, `ask:[1]`) in "settings files of the wrong shape fail closed" fail if the check is removed

**Location:** `test/auto-approve-allowed-commands.bats:206-219`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two mutations (drop `ask` from the key list; replace `select(has($k)) | .[$k]` with `(.[$k] // [])`); does not establish detection of every possible weakening.

Command: `bash mutate.sh` (copies hook and test into `mut/<name>/`, one edit each, `bats -f 'wrong shape'`). Unmutated: ok. `no-ask`: "not ok 1 ... approved with global settings: {"permissions":{"ask":"Bash"}}". `no-has`: "not ok 1 ... approved with global settings: {"permissions":{"deny":null}}".

**Evidence:** `test/auto-approve-allowed-commands.bats:206-219`; `mutate.out`

---

## Claim 18: "a NUL inside a settings deny or ask rule fails closed" (test) fails if the check is removed

**Location:** `test/auto-approve-allowed-commands.bats:284-292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the deny iteration (NUL check removed) and the ask iteration (ask removed from the key list), plus a non-vacuity control; does not establish independent detection of a NUL-only weakening confined to ask (impossible with the shared check).

`no-nul-check` (`bash mutate2.sh`, removes `and (explode | any(. == 0) | not)` from SETTINGS_RULES_JQ only): "not ok 2 ... approved with a NUL in deny" (and the allow NUL test fails too). `no-ask` (`bash mutate3.sh`): "not ok 1 ... approved with a NUL in ask". Control: same allow rule with no deny/ask, command `cat ~/.claude/.credentials.json` → allow JSON, so the test is not vacuous.

**Evidence:** `test/auto-approve-allowed-commands.bats:284-292`; `mutate2.out`; `mutate3.out`

---

## Claim 19: "Split rather than dropped, the second half would approve curl."

**Location:** `test/auto-approve-allowed-commands.bats:295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--permissions` filter's NUL drop; does not establish settings-file NUL handling (Claim 18).

Mutation `perm-no-nul-select` (`select(type == "string")` in `load_rules`' `--permissions` filter, `:232`): "not ok 1 a NUL inside a --permissions rule drops that rule only" at the `curl x` `not_approved` line.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:225-233`, `test/auto-approve-allowed-commands.bats:294-300`; `mutate.out`

---

## Claim 20: "rule table: Bash(ls *) is a literal prefix, not a glob" (test) fails if matching became a glob

**Location:** `test/auto-approve-allowed-commands.bats:318-323`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a glob mutation of the first comparison; does not establish detection of other matcher changes.

Mutation `glob-match` (`[[ $full_command == $allowed ]]` unquoted): "not ok 1 rule table: Bash(ls *) is a literal prefix, not a glob" at the `ls -la` `not_approved` line.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:260`, `test/auto-approve-allowed-commands.bats:318-323`; `mutate.out`

---

## Claim 21: "Merges fix/q092a-drop-deny-option (b973e678), taking this unit's version of the hook and tests and porting unit 1's fixes (NUL --permissions test, `Bash(ls *)` rule-table row and test, stdout-test comment)."

**Location:** commit 72b8c825 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of the three ported fixes in `ed06dec1..72b8c825`; does not establish that b973e678's deny-side tests (moot) were intentionally left out beyond "this unit's version".

The diff carries the `# Split rather than dropped` test (`test/...bats:295-296`), the rule-table row (`hook:99-100`) and test (`test/...bats:318-323`), and the stdout comment (`test/...bats:148-152`), each identical to b973e678's version (`git show b973e678 -- hooks/ test/`). 72b8c825's parents are ed06dec1 and b973e678 (`git show --stat`).

**Evidence:** `git diff ed06dec1..72b8c825 -- hooks/ test/`; `git show b973e678`

---

## Claim 22: "the hook still approved from a file with a non-string allow entry, a null or false deny, or any ask value"

**Location:** commit 72b8c825 message
**Type:** Behavioral (historical, ed06dec1)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ed06dec1's filter; does not establish Claude Code drops such files (Claim 11b).

```
# ed06dec1:hooks/auto-approve-allowed-commands.sh (SETTINGS_RULES_JQ)
  elif ((.deny // []) | type != "array" or any(.[]; type != "string"))
    then error("permissions.deny is not an array of strings")
  else
    (.allow // []) | if type == "array" then .[] | select(type == "string")
```

`null // []` and `false // []` are `[]`; non-string allow entries are filtered by `select`; `ask` is never read.

**Evidence:** `ed06dec1:hooks/auto-approve-allowed-commands.sh` (SETTINGS_RULES_JQ heredoc)

---

## Claim 23: "permissions.allow, .deny and .ask, when present, must now each be an array of NUL-free strings, which also restores fail-closed on a NUL inside a deny rule (api-consistency)."

**Location:** commit 72b8c825 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new rule (Claim 1) and that 1a831ffe failed closed on a NUL in a deny string; does not establish anything about ed06dec1's NUL handling beyond it being absent for deny.

1a831ffe: deny strings were emitted as `"D\t" + .` and then `| if explode | any(. == 0) then error("NUL inside a rule string")` (lines 171-175). ed06dec1 applied that NUL check only to emitted allow strings (Claim 22 excerpt). Now: `deny:["a\u0000"]` → `rc=5`.

**Evidence:** `1a831ffe:hooks/auto-approve-allowed-commands.sh:171-175`; `jqprobe.out`

---

## Claim 24: "A value outside those keys stays a stated residual. ROLE records that Q-082 did not note its Claude Code version and gives a re-test trigger. Log row 53 updated."

**Location:** commit 72b8c825 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of the residual (`hook:80-82`), ROLE note (`hook:55-59`), and row 53 change (`docs/decisions/log.md:76`); does not re-verify their content (Claims 1-12).

`git diff ed06dec1..72b8c825 --stat` lists `docs/decisions/log.md | 2 +-`; texts quoted in Claims 6, 7, 11.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:55-59`, `hooks/auto-approve-allowed-commands.sh:80-82`, `docs/decisions/log.md:76`

---

## Claim 25: "Unit size vs unit 1 is 409 (loop tolerance ~800)."

**Location:** commit 72b8c825 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief's measurement command; does not establish the tolerance figure's source.

Command (cwd `/workspace/.claude/wt-q092`, exit 0, 2026-10-15T12:06Z): `git diff --numstat fix/q092a-drop-deny-option..72b8c825 -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` → `409` (rows: 10 guides, 257 hook, 8 wiring.json, 129 hook test, 5 linker test; branch tip b973e678).

**Evidence:** command output above (inline; re-runnable)

---

## Claim 26: "Non-string allow entries now fail closed instead of being skipped (stricter than before)."

**Location:** commit 72b8c825 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers settings files; does not cover `--permissions`, which still skips non-strings (`hook:232`), a test-only path.

Executed: `{"permissions":{"allow":["Bash(ls)",5]}}` → `rc=5`; ed06dec1 used `select(type == "string")` (Claim 22).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:156-158`; `jqprobe.out`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 9** (`hooks/auto-approve-allowed-commands.sh:76`): "a permissions that is not an object" includes `null`, which the filter accepts (`if . == null then empty`); say "neither null nor an object".

### Unverifiable
- **Claim 3** (`docs/decisions/log.md:76`): Claude Code's matcher on a glob spelling; carried over and accepted (rubric C7); needs a host run.
- **Claim 11b** (`hooks/auto-approve-allowed-commands.sh:80-82`): which values (another key, a BOM) make Claude Code drop a file; needs Claude Code's validator traced or a host run.

## Goal-Alignment Note

The user's goal is to land Q-092 unit 2 clean. The pass-1 fixes hold: the three-key shape check works under jq 1.6 with null/false/non-string/NUL values, errors before emitting within a file, and every new test fails under a mutation of the check it guards. The one documentation imprecision (Claim 9) is a wording nit with no behavioral consequence. The two Unverifiable items are host-side Claude Code questions already recorded as residuals; neither blocks the merge.
