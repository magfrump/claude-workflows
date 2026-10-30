Commit: 5ba83a3a

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/home/node/.claude/jobs/00bcf178/tmp/q092/wt-u1`, branch `fix/q092a-drop-deny-option`)
**Scope:** Final confirming pass, full unit 1: `git diff 00a27a2f..5ba83a3a -- ':(exclude)docs/reviews'` (hooks/auto-approve-allowed-commands.sh, test/auto-approve-allowed-commands.bats, docs/working/plan-q092-drop-hook-deny-reader.md) plus the messages from `git log 00a27a2f..5ba83a3a`. Unit 2 (`/workspace/.claude/wt-q092`, HEAD 73698a91) was read where a unit-1 claim points at it.
**Checked:** 2026-10-15
**Commit:** 5ba83a3a
**Replication:** k=3
**Total claims checked:** 32
**Summary:** 28 verified, 2 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

Execution provenance: every executed claim ran on 2026-10-15 between 12:24 and 12:32 UTC, bash 5.2.15, with scripts and captured output under `/home/node/.claude/jobs/00bcf178/tmp/q092/agents/code-fact-check-report-q092a-final-r1/` (written there because this pass may only edit its own report). The worktree was never modified. Mutants are copies of the hook (`mut/*.sh`), run against a copy of the test file whose `HOOK=` line reads `$MUT_HOOK` (`mut/t.bats`). The harness control (unmutated copy) passed all four targeted tests. Logs:
- `suite.log`: `cd wt-u1 && timeout 600 bats test/auto-approve-allowed-commands.bats`, exit 0, 43/43 ok (12:24:57Z).
- `residuals.log` (`bin/residuals.sh`), `ruletable.log` (`bin/ruletable.sh`), `exits.log` (`bin/exits.sh`), `u2check.log` (`bin/u2check.sh`): hook probes through `bin/probe.sh`, which builds a throwaway HOME and git project, writes the given settings to the project's `.claude/settings.json`, and prints ALLOW/none for each command. Each script exited 0.
- `mutants.log` (`bin/mutants.sh`), `mutant5.log` (`bin/mutant5.sh`), `dbbcheck.log` (`bin/dbbcheck.sh`): mutation runs, `timeout 600 bats -f <title> mut/t.bats`.

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read. No claim here matches a logged pattern. The one Incorrect (Claim 28b) is a mischaracterisation, not a fabricated symbol, so it does not belong in the log (and this pass edits only its own report).

---

## Claim 1: Plan Motive: Q-082, decision log 53 amendment, architecture review finding 1

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:7-14`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each of the three cited sources exists and says what the plan attributes to it. It does not establish the host result itself, which is a user-reported observation.

Q-082 in the archive: "**Answer (2026-09-28):** the user confirmed `/hooks` listed the test hook. So a PreToolUse hook `allow` does **not** override a matching `permissions.deny` rule." (`docs/working/questions-archive.md`, `### Q-082`). Decision log row 53: "**Amended 2026-09-28 (Q-082):** ... A hook `allow` does not override deny, so the hook's deny reader is redundant for `allow`; its removal is Q-092." (`docs/decisions/log.md:76`). Architecture review finding 1: "#### 1. The hook now holds a second, partial Bash-deny engine whose correctness is coupled to Claude Code semantics it cannot see", quoting the "KNOWN DIVERGENCE ... `Bash(rm *)`" note, and recommending "If deny wins, delete the deny reader and keep the hook allow-only." (`docs/reviews/architecture-review-2026-09-27.md:42-49`).

**Evidence:** `docs/working/questions-archive.md` (Q-082), `docs/decisions/log.md:76`, `docs/reviews/architecture-review-2026-09-27.md:42-49`

---

## Claim 2: Plan Motive, the `ask` question: "the only stdout write in `main` is the `allow` JSON ... `debug` writes to stderr only. `show_help` and `check_deps` (`exit 2`) run only under the `parse_commands` subcommand, which `wiring.json` never invokes ... (measured: malformed input JSON exits 4) ... So no path emits `ask`, `deny` or `defer`"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:15-25`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main()'s stdout on every exit path except the jq-missing one, and the parse_commands-only reach of show_help/check_deps. It does not establish Claude Code's handling of a non-zero, non-2 exit, which is external.

The one decision string is in main: `echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'` (`hooks/auto-approve-allowed-commands.sh:440`). `debug` writes `echo "[DEBUG] $*" >&2` (`:126`). `show_help` is called only at `:902` and `check_deps` only at `:927`, both inside `parse_commands()` (`:898-942`), which runs only through `case "${1:-}" in parse_commands)` (`:944-947`). The wiring passes no subcommand: `"command": "bash {{CLAUDE_DIR}}/hooks/auto-approve-allowed-commands.sh"` (`hooks/wiring.json:78`). Executed (`exits.log`): input `not json` gives `exit=4 stdout=[]`, a truncated object gives `exit=4 stdout=[]`, `{}` gives `exit=0 stdout=[]`. Mutation: six mutants that each print an `ask` JSON on one exit path (deny branch, parse failure, no allow rules, unlisted command, empty extraction, no command) were each caught by the stdout test (`mutants.log`, m1 to m1f).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:126`, `:440`, `:898-947`, `hooks/wiring.json:78`, `exits.log`, `mutants.log`

---

## Claim 3: Plan F1 and F2 rows (literal spelling; hook emits `ask`)

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:36-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook-side Before (00a27a2f) and After (unit 2, 73698a91) behaviour for the literal credentials spelling, and the no-`ask` property. "CC denies" / "CC's deny wins" rest on Q-082 (Claim 1) and were not run here.

Before: the 00a27a2f hook gives `none	cat ~/.claude/.credentials.json` with the wired rule (`residuals.log`, OLD). After: the unit-2 hook gives `ALLOW	cat ~/.claude/.credentials.json` (`u2check.log`). F2: see Claim 2. The stdout test asserts it (`test/auto-approve-allowed-commands.bats:147-170`).

**Evidence:** `residuals.log`, `u2check.log`, `test/auto-approve-allowed-commands.bats:147-170`

---

## Claim 4: Plan F3 row: quote/backslash spellings; "`${X:-push}` is refused by the shape allowlist anyway"; "CC 2.1.300 builds `fullyUnquoted` forms of a command (seen in the binary)"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:38`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Before/After hook behaviour for the four listed spellings, the shape refusal of `${X:-push}`, and the presence of the `fullyUnquoted` string in the installed 2.1.300 binary. It does not establish where that form feeds Claude Code's deny matcher, which the row itself leaves unverified.

Before (00a27a2f, settings-file rules): `none` for `.cred""entials.json`, `.c\redentials.json`, `git "push" origin main`, `cat "secret"`. After (unit 1): `ALLOW` for all four (`residuals.log`). The shape filter refuses any ParamExp with an operator: `elif .Type == "ParamExp" and (plain_param | not) then "parameter expansion with an operator"` (`hooks/auto-approve-allowed-commands.sh:691-692`). `claude --version` gives `2.1.300 (Claude Code)`, and `grep -c -a fullyUnquoted` on `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` gives 2.

**Evidence:** `residuals.log`, `hooks/auto-approve-allowed-commands.sh:666-668`, `:691-692`

---

## Claim 5: Plan F4 row: compound command with a denied subcommand; "the wired rule ... has leading/trailing `*` and matches the raw string anywhere"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's Before/After decision for `ls && rm -rf x` / `ls && git push` and the raw-string reach of the wired rule. It does not establish Claude Code's own splitting for deny rules, which the row says is unverified.

Before: `none	ls && git push` with `Bash(git push:*)` (`residuals.log`, OLD). After (unit 2): `ALLOW	ls && rm -rf x` with `Bash(rm -rf:*)` (`u2check.log`). Raw-anywhere: `none	ls | cat "~/.claude/.credentials.json"` under unit 1 (`residuals.log`). The wired rule's leading/trailing `*` survives escaping (`if [[ "$c" == [A-Za-z0-9*] ]]`, `hooks/auto-approve-allowed-commands.sh:251`).

**Evidence:** `residuals.log`, `u2check.log`, `hooks/auto-approve-allowed-commands.sh:241-258`

---

## Claim 6: Plan F5 row: glob / brace / ANSI-C / earlier-variable spellings "approved by the hook (accepted residual, pinned)", same after

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's decision for `.c*`, `.jso[n]`, `.js{on,}`, `$'\x2e'`, `$F` before and after. It does not establish Claude Code's matcher on these.

Both the 00a27a2f hook and the unit-1 hook give `ALLOW` for all five spellings (`residuals.log`). The glob and `$F` cases are pinned by `test/auto-approve-allowed-commands.bats:230-251`.

**Evidence:** `residuals.log`, `test/auto-approve-allowed-commands.bats:230-251`

---

## Claim 7: Plan F6 row: "no approval for bad JSON or a bad `permissions`, `allow`, `deny` or `ask` (U2 makes each, when present, an array of NUL-free strings) ... Residual, stated in the header"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:41`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unit 2's shape check on allow/deny/ask lists and the header residual. It does not establish Claude Code's own file-rejection rules (the security-review q092b claim about 2.1.300).

Unit 2 (73698a91) does not require "an array of NUL-free strings". It requires an array whose string entries hold no NUL, and it skips non-strings. Its header says "a permissions.allow, .deny or .ask (present at all) that is not an array or holds a string with a NUL ... Non-string entries are skipped, not refused: Claude Code drops those with a warning and keeps the file" (unit 2 `hooks/auto-approve-allowed-commands.sh:75-81`, commit 0444b1ac). Executed against unit 2: `{"allow":["Bash(ls:*)",1],"deny":[2,"Bash(zz)"]}` gives `ALLOW	ls -la`, and a NUL inside a deny string gives `none` (captured inline in this pass's terminal session; the commands use `bin/probe.sh` on `u2/h2.sh`). The residual is stated: "RESIDUAL: anything Claude Code rejects that this check accepts ... can still make Claude Code drop the file, and its deny rules with it, while its allow rules approve here" (unit 2 header `:81-85`). Precise version: "an array, any string in it free of NUL (non-strings skipped)".

**Evidence:** `/workspace/.claude/wt-q092` `hooks/auto-approve-allowed-commands.sh:75-85` at 73698a91, commit 0444b1ac

---

## Claim 8: Plan F6b, F7, F8, F9 rows

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:42-45`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers F7 (relative CLAUDE_CONFIG_DIR, newline path: no approval), F8 (guard-trusted-writes can emit `ask`), and F9 (the hook reads only three settings paths). It does not establish F6b's Claude Code-side rejection reasons (BOM, bad `defaultMode`), which are external.

F7: `if [[ -n "${CLAUDE_CONFIG_DIR:-}" && "$CLAUDE_CONFIG_DIR" != /* ]]; then ... return 1` and `if [[ "$f" == *$'\n'* ]]; then ... return 1` (`hooks/auto-approve-allowed-commands.sh:184-195`). Executed: relative value with `--permissions` gives `stdout=[]` (`exits.log`). The suite's relative and newline tests pass (`suite.log`). F8: guard-trusted-writes documents "SOFT ... Gated to "ask" only when the session is web-tainted" (`hooks/guard-trusted-writes.py:39`). F9: `printf '%s\0' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" "${root:-.}/.claude/settings.json" "${root:-.}/.claude/settings.local.json"` (`hooks/auto-approve-allowed-commands.sh:145-146`), and no other path.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:142-205`, `hooks/guard-trusted-writes.py:35-41`, `exits.log`, `suite.log`

---

## Claim 9: Plan F10 row: "Q-082 did not record its version (Q-091, the same day, saw 2.1.284 on the host); the image installs `@latest` (2.1.300 here). Re-test trigger in the header."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:46`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the version facts and the re-test trigger's presence in unit 2's header. It does not establish the host's current version.

Q-091 answer: "it printed `2.1.284 (Claude Code)`" after the user ran it on the host (`docs/working/questions-archive.md`, `### Q-091`). Image: `ARG CLAUDE_CODE_VERSION=latest` (`devcontainer-config/Dockerfile:19`) and `"CLAUDE_CODE_VERSION": "latest"` (`devcontainer-config/devcontainer.json:29`). Here: `claude --version` gives `2.1.300 (Claude Code)`. Unit 2 header: "re-run Q-082's test when a Claude Code release changes how a PreToolUse permissionDecision combines with permission rules, or before relying on this after a major version" (unit 2 `hooks/auto-approve-allowed-commands.sh:57-59`). The Q-082 entry records no version (paraphrased — no quote available because the claim is about an absence in the entry).

**Evidence:** `docs/working/questions-archive.md` (Q-082, Q-091), `devcontainer-config/Dockerfile:19`, `devcontainer-config/devcontainer.json:29`

---

## Claim 10: Plan Split: "The whole change counts 652 code lines ... so it is two stacked units, each under 400 ... U1 ... ~365 lines ... U2 ... ~373 lines"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:79-88`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the decision-62 counts at the split commits and now. It does not establish whether the growth needs a waiver (it is inside the ~800 in-loop tolerance of log 62's 2026-10-15 amendment).

With the prescribed count (`git diff --numstat <base>..<sha> -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'`): at split time the numbers held: 00a27a2f..1a831ffe = 365, 1a831ffe..ed06dec1 = 373, 00a27a2f..ed06dec1 = 652. Now: 00a27a2f..5ba83a3a = 407, 5ba83a3a..73698a91 (unit 2 against unit 1) = 436, whole change 697. "Each under 400" no longer holds for either unit. The plan was edited in b973e678 (F3, F6, F10) without updating this section. Log 62 tolerates in-loop growth "up to ~800 lines" (`docs/decisions/log.md:85`), so this is a stale description, not a cap breach.

**Evidence:** `docs/working/plan-q092-drop-hook-deny-reader.md:79-88`, `docs/decisions/log.md:85`; counts run 2026-10-15 ~12:33Z in the worktree (commands above)

---

## Claim 11: Plan Trailers and pre-mortem scope: "`hooks/`, `test/` and `docs/` match neither gate regex"; the hook "is payload under `claude-home/`, hashed by the manifest at install"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:29-30`, `:92-94`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two gate regexes and the manifest walk over claude-home. It does not establish that install.sh copies this specific hook (it assembles the payload from the repo root).

`enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'` and `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'` (`hooks/live-verify-gate.sh:83`, `:91`). Both are anchored at `devcontainer-config/`. The manifest walk: `if [ -d claude-home ]; then find claude-home \( -type f -o -type l \) | LC_ALL=C sort; fi` (`devcontainer-config/cc-isolated.sh:149`), and `# claude-home/ — the baked skills/hooks payload` (`:122`).

**Evidence:** `hooks/live-verify-gate.sh:83-93`, `devcontainer-config/cc-isolated.sh:122-149`, `devcontainer-config/install.sh:110-134`

---

## Claim 12: Options help: "--permissions JSON  Use custom allow rules instead of the settings files' allow lists"

**Location:** `hooks/auto-approve-allowed-commands.sh:15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that settings allow rules are dropped and settings deny rules kept under --permissions. It does not establish behaviour for a non-array --permissions value beyond "no allow rules".

`if [[ "$rec" == A$'\t'* && -z "$CUSTOM_PERMISSIONS" ]]; then add_allow_rule ...; elif [[ "$rec" == D$'\t'* ]]; then add_deny_rule ...` (`:273-279`). Executed (`exits.log`): settings allow `cat:*`, deny `Bash(ls -la)`, `--permissions '["Bash(ls:*)"]'` gives `cat x` none, `ls -la` none (settings deny kept), `ls` allow.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:265-288`, `exits.log`

---

## Claim 13: ROLE: "A host test (Q-082, 2026-09-28) showed Claude Code still applies permissions.deny after a hook "allow" (a hook "ask" overrides it, Claude Code issue #39344, and this hook never asks), so the deny check below is redundant, and Q-092's second unit removes it."

**Location:** `hooks/auto-approve-allowed-commands.sh:57-60`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Q-082 citation, "this hook never asks" (stdout over main's paths), and that unit 2 removes the deny check. It does not establish the content of Claude Code issue #39344, which needs network access (no egress here). The repo records it in decision log 53.

Q-082: see Claim 1. Never asks: see Claim 2 (one decision string at `:440`, six ask-mutants caught). Unit 2 removes it: its header says "DENY RULES ARE CLAUDE CODE'S (Q-092). The hook used to read Bash deny rules itself and never approve a match, raw or de-quoted. Q-082 made that redundant for "allow", so it is gone" (unit 2 `hooks/auto-approve-allowed-commands.sh:63-66`), and the unit-2 hook approves the literal credentials spelling (`u2check.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:57-60`, `:440`, unit 2 header `:50-66`, `mutants.log`, `u2check.log`

---

## Claim 14: WHAT THE DENY CHECK GUARANTEES: never approves when a Bash deny rule matches the raw command or any extracted command; fails closed on unreadable / non-single-object / wrong-shape settings; "The de-quoted match and the --deny test option are gone"

**Location:** `hooks/auto-approve-allowed-commands.sh:62-67`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the raw and per-extracted checks, the fail-closed paths for unreadable (chmod 000), unparseable, multi-document, empty and ill-shaped files, and the removal. It does not re-open `permissions.allow/deny: false` counting as absent (rubric C1, deferred to unit 2).

Raw check `if matches_deny "$command"; then ... exit 0` (`:387-390`), per-extracted check `if matches_deny "$full_command"; then all_allowed=false; break` (`:427-430`). Removing the loop check is caught by the test (`mutants.log`, m2). A read failure sets `DENY_ALL=true` (`:269-272`), and `matches_deny` returns 0 for it (`:296-299`). Executed: a chmod-000 settings file gives `stdout=[]`, and a malformed file with `--permissions` gives `stdout=[]` (`exits.log`). The suite's shape loop covers `{"permissions":[]}`, `deny:"Bash"`, `deny:[1]`, `deny:{}`, `allow:{}`, `[]`, `{}{}`, `''` (`test/auto-approve-allowed-commands.bats:291-301`, passing in `suite.log`). Removal: no `CUSTOM_DENY`, `--deny` case, `PARAM_DEFAULT_RE` or `dq` remain (paraphrased — no quote available because the claim covers absence: `rg 'CUSTOM_DENY|PARAM_DEFAULT_RE|dq='` in the hook returns nothing).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:265-309`, `:385-436`, `exits.log`, `mutants.log`, `suite.log`

---

## Claim 15: RESIDUALS: a quote or backslash inside or around a word (`.cred""entials.json`, `.c\redentials.json`, `git "push"` vs `Bash(git push:*)`, `cat "secret"` vs `Bash(cat secret)`), a glob (`~/.claude/.c*`, `.credentials.jso[n]`), brace or ANSI-C spellings (`.js{on,}`, `$'\x2e'credentials.json`), an earlier variable, a decoded path, the parent directory get past; "The glob and earlier-variable spellings are pinned by tests."

**Location:** `hooks/auto-approve-allowed-commands.sh:68-78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed spelling run against the unit-1 hook with the matching deny rule and an allow list that covers the command. A "decoded path" was not run: in this hook any decode needs a substitution or a wrapper, which the shape filter refuses, so it gets past the deny string match but not the hook as a whole.

Every listed spelling gives `ALLOW` (`residuals.log`, NEW): the four quote/backslash forms, `.c*`, `.jso[n]`, `.js{on,}`, `$'\x2e'credentials.json`, `curl -d @$F`, `tar c ~/.claude`. The literal controls give `none`. Pins: `test/auto-approve-allowed-commands.bats:230` (glob) and `:242` (earlier variable).

**Evidence:** `residuals.log`, `test/auto-approve-allowed-commands.bats:230-251`

---

## Claim 16: SETTINGS SOURCES: "resolved like devcontainer-config/link-claude-home.sh's DEST (an empty value falls back; a relative value approves nothing)"

**Location:** `hooks/auto-approve-allowed-commands.sh:80-84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers empty and relative values, with and without --permissions. It does not establish the linker's own behaviour with a relative value.

Linker: `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`devcontainer-config/link-claude-home.sh:36`). Hook: the same expansion at `:145`, and the relative guard at `:184-187` returns 1, which load_rules turns into `DENY_ALL=true` (`:269-272`). Executed: relative value with `--permissions '["Bash(ls:*)"]'` gives `stdout=[]` (`exits.log`). The suite's CLAUDE_CONFIG_DIR tests (empty value falls back, relative value approves neither `cat` nor `ls`) pass (`test/auto-approve-allowed-commands.bats:314-344`, `suite.log`).

**Evidence:** `devcontainer-config/link-claude-home.sh:36`, `hooks/auto-approve-allowed-commands.sh:145`, `:184-187`, `exits.log`

---

## Claim 17: RULE SYNTAX table rows (`Bash(ls)`, `Bash(rm:*)`, `Bash(ls *)` "literal prefix `ls *`: `ls *` and `ls * -la`, never `ls -la`" / deny "glob: `ls -la`", bare `Bash`, `Bash(*)`, `Bash(**)`) and "only `*` is a wildcard (`?`, `[...]` and extglob characters are literal)"

**Location:** `hooks/auto-approve-allowed-commands.sh:86-107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cell of the table and the literal-metacharacter clause, run through settings files. It does not establish Claude Code's own reading of these rules.

Executed (`ruletable.log`). Allow column: `Bash(ls)` approves `ls` and `ls -la`, not `ls/x`. `Bash(a/b)` approves `a/b/x`. `Bash(python3 d)` approves `python3 d/x`. `Bash(rm:*)` approves `rm x`, not `rmdir x`. `Bash(ls *)` approves `ls *` and `ls * -la`, not `ls -la`. Bare `Bash` approves nothing. Deny column: `Bash(ls)` blocks `ls` only. `Bash(rm:*)` blocks `rm x`, `rmdir x` and `rm`. `Bash(ls *)` blocks `ls -la` but not `ls`. `Bash`, `Bash(*)` and `Bash(**)` each block `ls -la`. Literal metacharacters: `Bash(cat file?.txt)` lets `cat file1.txt` through and blocks `cat file?.txt`. `Bash(cat notes[1].txt)` lets `cat notes1.txt` through. `Bash(cat +(a))` lets `cat a` and `cat aa` through. `Bash(cat @(a|b))` lets `cat a` and `cat b` through. Mechanism: `if [[ "$c" == [A-Za-z0-9*] ]]; then glob+="$c"; else glob+="\\$c"; fi` (`:251-255`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:211-258`, `:314-337`, `ruletable.log`

---

## Claim 18: KNOWN DIVERGENCE: "Here it does not (`rm *` needs the space) ... the legacy form `Bash(rm:*)`, which matches `rm` alone but, as a plain prefix, also `rmdir`."

**Location:** `hooks/auto-approve-allowed-commands.sh:108-111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook side of the divergence. It does not establish Claude Code's behaviour, which the comment says is undocumented.

Deny `Bash(rm *)` gives `ALLOW	rm` and `none	rm x`. Deny `Bash(rm:*)` blocks `rm`, `rm x` and `rmdir x` (`ruletable.log`).

**Evidence:** `ruletable.log`, `hooks/auto-approve-allowed-commands.sh:248`

---

## Claim 19: load_rules comment: "--permissions replaces the settings files' allow lists (testing); their deny lists are always read. The reader's status comes from `wait $!` ... bash older than 4.4 makes that `wait` fail, which also fails closed."

**Location:** `hooks/auto-approve-allowed-commands.sh:260-264`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unconditional read and the `wait $!` failure path on bash 5.2. It does not establish the pre-4.4 behaviour, which was not run (no old bash in the sandbox). That clause is unchanged from 00a27a2f.

The read is now unconditional: `mapfile -d '' records < <(read_settings_rules)` / `if ! wait $!; then ... DENY_ALL=true` (`:268-272`). The function's remaining lines (`:273-288`) add D records regardless of `CUSTOM_PERMISSIONS`. Executed: settings deny honoured under --permissions, and a malformed file under --permissions fails closed (`exits.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:265-288`, `exits.log`

---

## Claim 20: matches_deny comment: "True when a deny rule matches the string ... or when DENY_ALL is set ... add_deny_rule has already escaped everything but `*`, so `*` is the only live wildcard."

**Location:** `hooks/auto-approve-allowed-commands.sh:290-293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the single match form and the escaping. It does not establish behaviour for rule bodies holding multibyte characters beyond the `é` case the suite already runs.

`if $DENY_ALL; then ... return 0` and `if [[ "$str" == $glob ]]; then ... return 0` (`:296-306`, function ends `:309`). Live-wildcard checks are in Claim 17 (`?`, `[...]`, `+(…)`, `@(…|…)` all literal).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:294-309`, `ruletable.log`

---

## Claim 21: Test section comment: "A hook "allow" does not override permissions.deny (host test Q-082), and the hook never emits "ask" ... The hook still reads settings-file deny rules; --deny and the de-quoted match are gone. ... a construct the extraction filter did not descend into (decision log 53)."

**Location:** `test/auto-approve-allowed-commands.bats:114-119`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against Claims 1, 2 and 14 and log row 53. It does not cover tests outside this section.

Row 53 lists "arithmetic expansion (`echo $((1 + $(cmd)))`)" among the constructs the filter did not descend into (`docs/decisions/log.md:76`). The rest: see Claims 1, 2 and 14.

**Evidence:** `docs/decisions/log.md:76`, `hooks/auto-approve-allowed-commands.sh:268-279`

---

## Claim 22: Stdout test: title "the hook's stdout is empty or exactly the allow decision: never ask, deny or defer"; comment "Stdout alone (stderr dropped), over main's exit paths for approved, refused, unparseable, unlisted, empty and malformed input (the jq-missing exit is not reached). Statically: the source spells exactly one decision."; "No allow rules, a malformed settings file, input with no command."

**Location:** `test/auto-approve-allowed-commands.bats:147-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions and their power against six single-path ask-mutants. It does not establish anything in `--debug` mode (debug output is stderr, and the test passes no `--debug`). The `{not json` case covers "no allow rules" and "a malformed settings file" with one input, because a jq parse error yields no records before DENY_ALL matters.

Assertions: `[ "$(grep -o '"permissionDecision":"[a-z]*"' "$HOOK" | sort -u)" = '"permissionDecision":"allow"' ]` (`:152`), then the loop `[[ -z "$out" || "$out" == "$ALLOW_JSON" ]]` over approved, deny-refused, shape-refused, unparseable, unlisted, empty, comment-only and REPRO inputs (`:155-160`), then three `[ -z "$out" ]` checks (`:162-169`). Each of mutants m1 to m1f prints a spaced `"permissionDecision": "ask"`, which the static grep misses, and each was caught by the loop or tail checks (`mutants.log`).

**Evidence:** `test/auto-approve-allowed-commands.bats:147-170`, `mutants.log`

---

## Claim 23: Test title "a prefix deny rule blocks an extracted command inside a pipeline; only * is a wildcard"; comment "Pins the per-extracted-command check and add_deny_rule's escaping"

**Location:** `test/auto-approve-allowed-commands.bats:213-228`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's power against loop-check removal, removal of all escaping, a live `?`, an escaped `*`, and live extglob characters. It does not establish coverage of other characters' escaping (for example `\`).

The test catches m2 (no per-extracted check), m3 (no escaping), m4 (`?` live) and m5b (`*` escaped) (`mutants.log`). It does not catch extglob characters left live. Mutant m5c changes `:251` to `if [[ "$c" == [A-Za-z0-9*] || "@+!()|" == *"$c"* ]]; then`. That really changes behaviour: deny `Bash(cat +(a))` then blocks `cat a` and `cat aa`, which the unmutated hook lets through. Yet m5c passes this test and the full suite, 43/43 (`mutant5.log`). bash 5.2 matches extglob in `[[ == ]]` even with `shopt extglob` off (`[[ a == @(a|b) ]]` is true, measured). So "only * is a wildcard" is pinned for `?` and `[...]`, not for the extglob characters the header also names (`:90-91`). Precise version: "only * is a wildcard (? and [...] pinned)", or add an extglob case such as deny `Bash(cat +(a))` with `cat aa` approved. Same shape as pass-2 C7, one character class further.

**Evidence:** `test/auto-approve-allowed-commands.bats:213-228`, `hooks/auto-approve-allowed-commands.sh:251`, `mutants.log`, `mutant5.log`

---

## Claim 24: Test "the hook ignores a --deny argument (the option was removed in Q-092)"

**Location:** `test/auto-approve-allowed-commands.bats:269-273`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `--deny '["Bash"]'` changes nothing. It does not establish that the next argument cannot be misparsed (the catch-all shifts one word at a time, so the JSON value is shifted as a separate unknown word).

main's catch-all is `*) shift ;;` (`hooks/auto-approve-allowed-commands.sh:351-353`). The test asserts `approved` and passes (`suite.log`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:341-355`, `suite.log`

---

## Claim 25: Settings fail-closed and CLAUDE_CONFIG_DIR test titles: "a malformed global settings file means nothing is approved", "settings files of the wrong shape fail closed", "an unparseable project settings.json fails closed even when settings.local.json is well formed", "the global settings file is read from CLAUDE_CONFIG_DIR, as link-claude-home.sh writes it", "a relative CLAUDE_CONFIG_DIR fails closed instead of reading another directory's allow rules", "a newline in the global settings path fails closed"

**Location:** `test/auto-approve-allowed-commands.bats:278-356`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each title against its assertions and a passing run. These tests were not mutated in this pass (they were not in the requested mutant set).

Each title matches its assertions. In the relative test, `sub/cfg/settings.json` holds `Bash(ls:*)` and resolves from the test's cwd (`$PROJECT`), so a hook that used the relative value as written would approve `ls -la`. The test asserts `not_approved` for it (`:334-344`). The CLAUDE_CONFIG_DIR test checks both directions: `cat` approved from the config dir, `ls` (from `~/.claude`) not, then the reverse after `CLAUDE_CONFIG_DIR=""` (`:314-332`). All pass (`suite.log`).

**Evidence:** `test/auto-approve-allowed-commands.bats:278-356`, `suite.log`

---

## Claim 26: NUL tests: "a NUL inside a settings allow rule fails closed instead of splitting into two rules"; "a NUL inside a --permissions rule drops that rule only" with "Split rather than dropped, the second half would approve curl."

**Location:** `test/auto-approve-allowed-commands.bats:358-373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tests' power against a split (no NUL filter) and an over-broad drop (whole list dropped). It does not establish behaviour for a non-array --permissions value.

Filter: `jq -j '.[]? | select(type == "string" and (explode | any(. == 0) | not)) | . + "\u0000"'` (`hooks/auto-approve-allowed-commands.sh:285`). Mutant m6 (filter reduced to `select(type == "string")`) fails the test, because `curl x` is approved. Mutant m6b (drop every rule when any holds a NUL) fails on the `ls -la` approved half (`mutants.log`). For the settings test, the jq program errors on the NUL (`:173`), so DENY_ALL is set and `ls -la` is not approved even though it is allow-listed (`:358-365`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:173`, `:281-287`, `test/auto-approve-allowed-commands.bats:358-373`, `mutants.log`

---

## Claim 27: Rule-table tests: "Bash(ls) is a command prefix", "Bash(rm:*) is a word prefix", "Bash(ls *) is a literal prefix, not a glob", "a bare Bash rule is ignored"

**Location:** `test/auto-approve-allowed-commands.bats:393-418`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four titles against their assertions, plus mutants for the `Bash(ls *)` test. It does not establish the deny column, which unit 1 pins only through the settings-file tests in Claims 14 and 23.

`Bash(ls *)`: asserts `ls -la` not approved and `ls * -la` approved (`:407-412`). Mutant m7 (allow prefix also matched as a glob) and mutant m8 (a ` *` rule approves nothing, the old belief) both fail it (`mutants.log`). The other three tests match their titles and pass (`suite.log`). The behaviour itself: see Claim 17.

**Evidence:** `test/auto-approve-allowed-commands.bats:393-418`, `hooks/auto-approve-allowed-commands.sh:314-337`, `mutants.log`

---

## Claim 28a: Commit 1a831ffe: "removes the parts nothing outside the tests used: the --deny test option"

**Location:** commit 1a831ffe message, paragraph 1
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers in-repo callers of `--deny`. It does not cover callers outside the repo.

Confirmed in pass 1 (Claim 1 there). The one wiring entry passes no options: `"command": "bash {{CLAUDE_DIR}}/hooks/auto-approve-allowed-commands.sh"` (`hooks/wiring.json:78`).

**Evidence:** `hooks/wiring.json:78`, `docs/reviews/code-fact-check-report-q092a-2026-10-15.md:23-43`

---

## Claim 28b: Commit 1a831ffe: "removes the parts nothing outside the tests used: ... and the de-quoted match (quotes, backslashes and ${NAME:-word} defaults)"

**Location:** commit 1a831ffe message, paragraph 1
**Type:** Architectural / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the de-quoted match ran on production input at 00a27a2f. It does not judge whether removing it was right (the plan's F3 accepts that).

At 00a27a2f, matches_deny compared every settings-file deny glob against both forms. The de-quoted form was `dq=${str//[\'\"\\]/}` and the comparison was `if [[ "$str" == $glob || "$dq" == $glob ]]` (00a27a2f `hooks/auto-approve-allowed-commands.sh`, removed lines shown in the unit diff). That ran on every production call with a Bash deny rule, and wiring.json ships one. Executed with settings-file rules only (no `--deny`): the 00a27a2f hook gives `none` for `.cred""entials.json`, `.c\redentials.json`, `git "push" origin main` and `cat "secret"`, and the unit-1 hook gives `ALLOW` for all four (`residuals.log`). So the de-quoted match was live production behaviour that changed decisions for the shipped credentials rule, not a test-only part. The same message's Notes contradict it ("The quote-split spelling (.cred""entials.json) is now a listed residual"). Pass 1 verdicted only the `--deny` half (its Claim 1). A precise version: "removes the --deny test option, which only the tests used, and the de-quoted match, whose quote and backslash coverage now depends on Claude Code's own matcher." It is a commit message, so recording it (as for C8) is the only fix short of a rewrite.

**Evidence:** `git show 00a27a2f:hooks/auto-approve-allowed-commands.sh` (matches_deny), `residuals.log`

---

## Claim 29: Commit 1a831ffe, remaining claims: Q-082 / decision log 53 premise; "The settings-file deny reader stays until unit 2"; tests leave --deny; the new stdout test; "whole change 652 lines; this unit ~365"; quote-split now a listed residual; "No gate trailer: hooks/ and test/ are outside live-verify-gate's sets"

**Location:** commit 1a831ffe message
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed claim against code, counts and the gate regexes. It does not re-verify the paragraph-1 phrasing split out as 28a/28b.

Premise: Claim 1. Deny reader stays: `elif [[ "$rec" == D$'\t'* ]]; then add_deny_rule` (`hooks/auto-approve-allowed-commands.sh:276-277`). Counts: 00a27a2f..1a831ffe = 365, 00a27a2f..ed06dec1 = 652 (Claim 10). Residual listed at `:71`. Gate regexes: Claim 11. Test moves: pass 1 Claim 4, unchanged since apart from b973e678's additions.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:71`, `:276-277`, `hooks/live-verify-gate.sh:83-91`

---

## Claim 30: Commit b973e678 claims (other than the F3/F6/F10 attribution already accepted as rubric C8): NUL test now uses an input a split would approve; `Bash(ls *)` row and test corrected; ROLE cites Q-082; settings-file test pins the per-extracted check and escaping "which lost their only tests"; residual list names backslash and whole-word quoting; two pre-existing header errors corrected; "Unit size 403 after this commit"; "false/null permission lists counting as absent is left to unit 2's stricter check"

**Location:** commit b973e678 message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed claim. It does not re-verdict the C8 attribution, and does not verify that unit 2 handles `false` (only `null`, per 0444b1ac/fdae7834's subjects).

NUL test: Claim 26 (m6 caught). `Bash(ls *)`: Claims 17 and 27. ROLE: Claim 13. Pins: m2/m3 caught (Claim 23). Residuals: `:71-72`. Pre-existing errors: 00a27a2f had `--permissions JSON      Use custom permissions instead of reading from settings files` while still reading the files' deny lists when `--deny` was unset, and "a relative value is used as written, from the hook's cwd" next to a relative-value guard that returned 1 (00a27a2f lines 15, 90, 190-193). Size: 00a27a2f..b973e678 = 403. Unit 2: fdae7834 "a present but null permissions fails closed".

**Evidence:** `git show 00a27a2f:hooks/auto-approve-allowed-commands.sh` lines 15, 90, 190-193; `mutants.log`; numstat count

---

## Claim 31: Commit dbb15ec6: "a mutant that left `?` live passed. Adds the `Bash(cat file?.txt)` case."

**Location:** commit dbb15ec6 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim against b973e678's version of the test. It does not cover other characters (see Claim 23).

The `?`-live mutant (m4) passes b973e678's test (`dbbcheck.log`, `ok 1`) and fails the current one (`mutants.log`). The case is at `test/auto-approve-allowed-commands.bats:217`, `:225-228`.

**Evidence:** `dbbcheck.log`, `mutants.log`, `test/auto-approve-allowed-commands.bats:213-228`

---

## Claims Requiring Attention

### Incorrect
- **Claim 28b** (commit 1a831ffe message): says the de-quoted match was a part "nothing outside the tests used". It ran on every production call with a settings deny rule, and it caught `.cred""entials.json` and friends with the shipped rule. Commit message, so record it (like C8) rather than rewrite.

### Stale
- **Claim 10** (`docs/working/plan-q092-drop-hook-deny-reader.md:79-88`): "each under 400 ... ~365 ... ~373" held at split time. Now unit 1 counts 407 and unit 2 counts 436 against its base (whole change 697). Both are inside log 62's ~800 in-loop tolerance. Update the section or note the in-loop counts.

### Mostly Accurate
- **Claim 7** (`docs/working/plan-q092-drop-hook-deny-reader.md:41`): F6 says unit 2 makes each list "an array of NUL-free strings". Unit 2 skips non-string entries (0444b1ac), so the precise version is "an array whose strings hold no NUL".
- **Claim 23** (`test/auto-approve-allowed-commands.bats:213`): "only * is a wildcard" is pinned for `?` and `[...]` but not for extglob characters. The extglob-live mutant passes 43/43. Add an extglob case (e.g. deny `Bash(cat +(a))`, `cat aa` approved) or narrow the title.

### Unverifiable
- None. Unverified externals (the content of issue #39344, Claude Code's own matcher and file-rejection rules, the pre-4.4 bash path) are scoped out in the claims that touch them.

---

## Goal-Alignment Note

The pass serves the goal: land Q-092 unit 1 reviewed clean before merge. The code and header claims that unit 1 changes all hold under execution. The hook never emits anything but `allow` or nothing (six ask-mutants caught). The deny check covers the raw and extracted commands and fails closed. Every listed residual spelling is approved as documented. Every rule-table cell matches. The four requested mutant sets are caught, except an extglob-live variant of the escaping test. None of the four non-Verified items is a behaviour defect in the hook. Two are documentation (plan F6 wording, stale split counts), one is a test-title gap one character class wider than pass-2's C7, and one is a commit-message mischaracterisation that can only be recorded. Nothing found exceeds the known and accepted F3/F4 exposure stated in the preamble.
