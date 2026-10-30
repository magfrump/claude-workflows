Commit: 5ba83a3a

# Code Fact-Check Report

**Repository:** /home/node/.claude/jobs/00bcf178/tmp/q092/wt-u1 (branch fix/q092a-drop-deny-option)
**Scope:** Full unit 1 of Q-092: `git diff 00a27a2f..5ba83a3a -- ':(exclude)docs/reviews'` (hooks/auto-approve-allowed-commands.sh, test/auto-approve-allowed-commands.bats, docs/working/plan-q092-drop-hook-deny-reader.md) plus the messages of `git log 00a27a2f..5ba83a3a` (1a831ffe, b973e678, dbb15ec6, 5ba83a3a). Final confirming pass, no `--loop-pass`. Unit 2 (`/workspace/.claude/wt-q092`, HEAD 73698a91, which has 5ba83a3a as an ancestor) was read as context only.
**Checked:** 2026-10-15
**Replication:** k=3
**Commit:** 5ba83a3a
**Total claims checked:** 39
**Summary:** 34 verified, 3 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Execution artifacts are under `/home/node/.claude/jobs/00bcf178/tmp/q092/agents/code-fact-check-report-q092a-final-r3/` (called `$A` below). Scripts: `go.sh` (runner: cwd = worktree, `timeout 600`, logs to `$A/logs/<name>.txt`, prints timestamp and exit code), `probe.sh`, `probe2.sh`, `probe3.sh` (each builds an isolated git project and fake `HOME` under `$A/probe*/`), `mut.sh` (mutants on copies under `$A/m-*/`), `ctl.sh` (unmutated control copy under `$A/ctl/`). The worktree was not modified (`git status --short` empty after all runs). No background processes were left running.

Runs (all cwd `/home/node/.claude/jobs/00bcf178/tmp/q092/wt-u1`, all exit 0):

| Name | Timestamp (UTC) | Command | Log |
|---|---|---|---|
| baseline | 2026-10-15T12:25:17Z | `timeout 600 bats test/auto-approve-allowed-commands.bats` → 43/43 ok | `$A/logs/baseline.txt` |
| residuals | 2026-10-15T12:26:03Z | `go.sh residuals probe.sh <hook>` | `$A/logs/residuals.txt` |
| mutants | 2026-10-15T12:27:37Z | `go.sh mutants mut.sh` (10 mutants, each killed) | `$A/logs/mutants.txt`, `$A/m-*/bats.txt` |
| control | 2026-10-15T12:27:58Z | `go.sh control ctl.sh` (the 4 filtered tests pass unmutated) | `$A/logs/control.txt` |
| probe2 | 2026-10-15T12:28:27Z | `go.sh probe2 probe2.sh <hook>` (exit codes, settings sources, rule table) | `$A/logs/probe2.txt` |
| probe3 | 2026-10-15T12:30:44Z | `go.sh probe3 probe3.sh <hook>` (decoded-path and parent-dir spellings) | `$A/logs/probe3.txt` |

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 patterns) was read. The relevant prior pattern is the count-in-a-commit-message family ("All 85 tests…", "mode1-equiv 33"); every size claim below was recomputed with the prescribed numstat formula.

---

## Claim 1: "Q-082 (archive, answered 2026-09-28): under a PreToolUse hook that always returned `allow`, a Bash call matching `permissions.deny` was still denied, and the user confirmed `/hooks` listed the hook."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:7-9`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the repo's Q-082 record; does not re-run the host test or establish which Claude Code version ran it.

`docs/working/questions-archive.md:1715`: "`cat x.q082-canary` was **denied** … **Answer (2026-09-28):** the user confirmed `/hooks` listed the test hook. So a PreToolUse hook `allow` does **not** override a matching `permissions.deny` rule." The test hook at `:1707-1708` always emits `"permissionDecision":"allow"`.

**Evidence:** `docs/working/questions-archive.md:1693-1720`

---

## Claim 2: "Decision log 53, amendment 2026-09-28, records this and files the removal as Q-092."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and content of the amendment; does not cover later amendments of row 53.

Row 53 carries "Amended 2026-09-28 (Q-082):** a host test settled Claim 20b. … A hook `allow` does not override deny, so the hook's deny reader is redundant for `allow`; its removal is Q-092." (`docs/decisions/log.md:76`).

**Evidence:** `docs/decisions/log.md:76`, `docs/working/questions.md:446-453`

---

## Claim 3: "Architecture review 2026-09-27, finding 1 … "If deny wins, delete the deny reader and keep the hook allow-only.""

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:11-14`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quotation and the `Bash(rm *)` divergence mention; does not evaluate the review's reasoning.

`docs/reviews/architecture-review-2026-09-27.md:49`: "- If deny wins, delete the deny reader and keep the hook allow-only." The same finding cites "A known semantic divergence already exists (`Bash(rm *)` vs bare `rm`)" (`:45`).

**Evidence:** `docs/reviews/architecture-review-2026-09-27.md:30-50`

---

## Claim 4: "the only stdout write in `main` is the `allow` JSON … Every other path is `exit 0` with no output … `debug` writes to stderr only. `show_help` and `check_deps` (`exit 2`) run only under the `parse_commands` subcommand, which `wiring.json` never invokes. … (measured: malformed input JSON exits 4 …) … So no path emits `ask`, `deny` or `defer`"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:15-25`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main() as reachable from the wiring entry (no arguments) on the inputs probed and every `exit`/`echo` in main; does not establish Claude Code's treatment of non-zero exits 4/5.

The one stdout write: `echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'` (`hooks/auto-approve-allowed-commands.sh:440`). `debug` is `echo "[DEBUG] $*" >&2` (`:126`). `check_deps` is called only at `:927` inside `parse_commands()` (`:898-942`), and `show_help` only at `:902`; the dispatcher calls `main "$@"` unless `$1` is `parse_commands` (`:944-952`). The wiring passes no arguments: `"command": "bash {{CLAUDE_DIR}}/hooks/auto-approve-allowed-commands.sh"` (`hooks/wiring.json:78`). probe2: input `not json` → `exit=4 stdout=[]`; `[1]` and `"s"` → `exit=5 stdout=[]`. Mutants M1a/M1b/M1c (an `ask` line, a stray stdout line, a literal `ask`) were each killed by the stdout test (Claim 27).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:126`, `:339-446`, `:898-952`; `hooks/wiring.json:78`; `$A/logs/probe2.txt`; `$A/logs/mutants.txt`

---

## Claim 5: F1 "Literal spelling … hook falls through; CC denies | hook allows; CC's deny wins (Q-082) | Covered by the host result"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:36`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "before" column for the hook (executed) and the "after" column's reliance on Q-082; "hook allows" is the post-unit-2 state, not unit 1 (unit 1 still falls through); does not re-test Claude Code.

residuals probe: `no-allow : cat ~/.claude/.credentials.json` with `Bash(*.credentials.json*)` denied (`$A/logs/residuals.txt`). Q-082 per Claim 1.

**Evidence:** `$A/logs/residuals.txt`; `docs/working/questions-archive.md:1715`

---

## Claim 6: F2 "no path emits `ask` (see Motive); pinned by a new test | Covered"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:37`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this hook's output; does not cover other hooks (F8).

See Claim 4 and Claim 27: the test `the hook's stdout is empty or exactly the allow decision` (`test/auto-approve-allowed-commands.bats:147`) killed all three ask/stray-output mutants.

**Evidence:** `test/auto-approve-allowed-commands.bats:147-170`; `$A/m-M1a/bats.txt`, `$A/m-M1b/bats.txt`, `$A/m-M1c/bats.txt`

---

## Claim 7: F3 "Quote or backslash spellings (`.cred""entials.json`, `.c\redentials.json`, `git "push"`, `cat "secret"` vs `Bash(cat secret)`; `${X:-push}` is refused by the shape allowlist anyway) | … | hook allows | … CC 2.1.300 builds `fullyUnquoted` forms of a command (seen in the binary)"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:38`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's approval of the four spellings at 5ba83a3a and the presence of the string in the installed binary; does not establish where Claude Code uses `fullyUnquoted` (the row itself says that was not traced).

residuals probe with deny `Bash(*.credentials.json*)`, `Bash(git push:*)`, `Bash(cat secret)`: `APPROVED : cat ~/.claude/.cred""entials.json`, `APPROVED : cat ~/.claude/.c\redentials.json`, `APPROVED : git "push" origin main`, `APPROVED : cat "secret"`. `${X:-push}` is refused by `elif .Type == "ParamExp" and (plain_param | not) then "parameter expansion with an operator"` (`hooks/auto-approve-allowed-commands.sh:691-692`). `claude --version` → `2.1.300 (Claude Code)`; `grep -c -a fullyUnquoted` on `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` → `2`.

**Evidence:** `$A/logs/residuals.txt`; `hooks/auto-approve-allowed-commands.sh:691-692`

---

## Claim 8a: F4 "The wired rule `Bash(*.credentials.json*)` has leading/trailing `*` and matches the raw string anywhere, so the shipped rule is unaffected"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:39`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rule's shape in wiring.json (its only Bash deny rule); "unaffected" assumes Claude Code also matches deny globs against the whole raw string, which is not established here.

`hooks/wiring.json:131`: `"Bash(*.credentials.json*)",`; `rg 'Bash\(' hooks/wiring.json` finds no other Bash deny rule (`:39` is a comment string).

**Evidence:** `hooks/wiring.json:128-140`

---

## Claim 8b: F4 "documented CC behaviour for allow rules is operator-aware"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:39`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond noting the claim; a claim about external Claude Code documentation.

paraphrased — no quote available because the claim cites external documentation that the repo does not quote, and the sandbox has no web egress. Needed: the Claude Code permissions documentation page on compound commands.

**Evidence:** `docs/working/plan-q092-drop-hook-deny-reader.md:39`

---

## Claim 9: F5 "Glob / brace / ANSI-C / earlier-variable spellings (`.c*`, `.jso[n]`, `$F`) | approved by the hook (accepted residual, pinned) | same"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:40`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the approval of each family (executed) and which are test-pinned; does not cover Claude Code's matcher.

All approved: `APPROVED : cat ~/.claude/.c*`, `… .credentials.jso[n]`, `… .credentials.js{on,}`, `… $'\x2e'credentials.json`, `cat $F` (`$A/logs/residuals.txt`). "pinned" holds for two of the four: tests `string-match limit: a glob spelling …` (`test/auto-approve-allowed-commands.bats:230`, `.cred*`) and `… a variable set by an earlier command …` (`:242`, `$F`). No test pins `.jso[n]`, brace or ANSI-C spellings. The hook header states it precisely: "The glob and earlier-variable spellings are pinned by tests" (`hooks/auto-approve-allowed-commands.sh:77-78`). Precise version: "pinned for the `.c*` glob and `$F`".

**Evidence:** `$A/logs/residuals.txt`; `test/auto-approve-allowed-commands.bats:230-251`

---

## Claim 10: F6 "no approval for bad JSON or a bad `permissions`, `allow`, `deny` or `ask` (U2 makes each, when present, an array of NUL-free strings) … Residual, stated in the header"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:41`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers unit 2's jq check at its HEAD 73698a91 and its header residual; does not re-verify Claude Code's own drop behaviour.

Unit 2 no longer requires every entry to be a string. Its jq fails only on a non-array or a NUL string, and its header says non-strings are skipped: `| if type != "array" then error("permissions.\($k) is not an array") elif any(.[]; type == "string" and test("\u0000")) then error(…) else empty end` (`/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:161-165`); "Non-string entries are skipped, not refused: Claude Code drops those with a warning and keeps the file" (`:80-81`). This changed in unit 2's 0444b1ac after the plan row was written. Precise version: "an array, with no NUL inside any string entry (non-strings skipped)". The residual is in unit 2's header: "RESIDUAL: anything Claude Code rejects that this check accepts … can still make Claude Code drop the file, and its deny rules with it" (`:81-85`).

**Evidence:** `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:74-85`, `:146-169`; `git log -1 0444b1ac`

---

## Claim 11: F6b "Settings file Claude Code drops for a reason the hook does not check (e.g. a bad `defaultMode`, a BOM) | the hook's deny reader still matched its deny rules | no backstop"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the hook side: unit 1's jq reads only `.permissions` and emits deny records, and unit 2 emits none; whether Claude Code drops such a file is taken from the cited q092b security review, not re-tested.

Unit 1 reads deny rules regardless of other keys: `((.deny // []) | if type == "array" then .[] | if type == "string" then "D\t" + . …` (`hooks/auto-approve-allowed-commands.sh:169-171`). Unit 2: "Only allow is emitted; deny rules are Claude Code's" (`/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:151-152`), with "a BOM" named in its residual (`:82`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:157-175`; `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:78-85`

---

## Claim 12: F7 "Relative or newline-bearing `CLAUDE_CONFIG_DIR` | no approval | no approval (kept: a wrongly resolved file could add allow rules) | Covered"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both units' early return; does not cover other non-canonical paths (symlinks, `..`).

`if [[ -n "${CLAUDE_CONFIG_DIR:-}" && "$CLAUDE_CONFIG_DIR" != /* ]]; then … return 1` and `if [[ "$f" == *$'\n'* ]]; then … return 1` (`hooks/auto-approve-allowed-commands.sh:184-195`); unit 2 keeps both (`/workspace/.claude/wt-q092/…:160-170`, read). probe2: `relative CCD, cat`, `relative CCD, ls` and `relative CCD, --permissions` all `stdout=[]`. Tests at `:334` and `:346` pass (baseline).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:179-205`; `$A/logs/probe2.txt`; `$A/logs/baseline.txt`

---

## Claim 13: F8 "Another hook's `ask` (guard-trusted-writes, SOFT+tainted Bash) overriding a Bash deny | reader could not affect it"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:44`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the ask path in guard-trusted-writes for Bash; does not evaluate its trigger conditions in full.

`hooks/guard-trusted-writes.py:3`: "PreToolUse hook (matcher: Edit|Write|MultiEdit|Bash)"; `:365`: `emit("ask", "This session fetched web content and this Bash command writes to a "`. The auto-approve hook only withholds its own allow (`hooks/auto-approve-allowed-commands.sh:387-390`).

**Evidence:** `hooks/guard-trusted-writes.py:3`, `:347-366`

---

## Claim 14: F9 "Settings sources CC honours but the hook never read (managed, `--settings`) | contributed no deny here"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:45`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hook's source list; does not establish Claude Code's precedence among sources.

`printf '%s\0' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" "${root:-.}/.claude/settings.json" "${root:-.}/.claude/settings.local.json"` (`hooks/auto-approve-allowed-commands.sh:145-146`), no managed path, no `--settings` input.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:142-147`

---

## Claim 15: F10 "Q-082 did not record its version (Q-091, the same day, saw 2.1.284 on the host); the image installs `@latest` (2.1.300 here). Re-test trigger in the header."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:46`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Dockerfile default, the container's version and unit 2's header line; does not cover a pinned build arg passed by the launcher.

`ARG CLAUDE_CODE_VERSION=latest` (`devcontainer-config/Dockerfile:19`), `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}` (`:403`). `claude --version` → `2.1.300 (Claude Code)`. Q-091: "it printed `2.1.284 (Claude Code)`" (`docs/working/questions-archive.md`, Q-091 answer). Q-082's entry names no version. Unit 2 header: "# @latest: re-run Q-082's test when a Claude Code release changes how a" (`/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:57`).

**Evidence:** `devcontainer-config/Dockerfile:19`, `:403`; `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:55-59`

---

## Claim 16: "The whole change counts 652 code lines … so it is two stacked units, each under 400: … U1 … ~365 lines. … U2 … ~373 lines."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:79-88`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at the split commits and at current heads, by the prescribed numstat formula; does not judge whether the decision-62 loop tolerance is met (it is: under ~800).

The counts were true when the plan was written: `00a27a2f..1a831ffe` → `365`, `00a27a2f..ed06dec1` (the first unit 2 head) → `652`. After the review fixes, U1 at 5ba83a3a is `407` (hook 40+77, test 121+169), the whole stack at unit 2's HEAD 73698a91 is `697`, and unit 2 above 5ba83a3a is `436`. Neither unit is "under 400" now. Row 62's 2026-10-15 amendment allows growth up to ~800 inside the loop, so this does not break the cap. Precise version: give the split-time counts as of the split, and the current sizes (407 / 436).

**Evidence:** `git diff --numstat 00a27a2f..<sha> -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` for 1a831ffe, ed06dec1, 5ba83a3a, and 73698a91 (in `/workspace/.claude/wt-q092`); `docs/decisions/log.md:85`

---

## Claim 17: "`hooks/`, `test/` and `docs/` match neither gate regex, so no `Live-verified:` or `Host-tool-tested:` trailer is required (decision log 45, 71). Deploying the hook into cc-isolated changes the installed payload: `install.sh` + re-bless."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:90-94`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both gate regexes and the manifest walk over `claude-home/`; does not run install.sh.

`enforcement='^devcontainer-config/(Dockerfile|…|egress/)'` (`hooks/live-verify-gate.sh:83`) and `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'` (`:91`): both anchored to `devcontainer-config/`. The manifest hashes "claude-home/ — the baked skills/hooks payload" (`devcontainer-config/cc-isolated.sh:122`, walked at `:149`).

**Evidence:** `hooks/live-verify-gate.sh:80-93`; `devcontainer-config/cc-isolated.sh:122`, `:149`

---

## Claim 18: "--permissions JSON      Use custom allow rules instead of the settings files' allow lists"

**Location:** `hooks/auto-approve-allowed-commands.sh:15-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a non-empty `--permissions`; an empty-string value leaves `CUSTOM_PERMISSIONS` empty and the settings allow lists are used.

`if [[ "$rec" == A$'\t'* && -z "$CUSTOM_PERMISSIONS" ]]` (`:274`) skips settings allow records; deny records are always added (`:276-277`). probe2: settings allow `Bash(ls:*)`, `--permissions '["Bash(cat:*)"]'`, command `ls` → `stdout=[]`. Deny still read: `--permissions still reads settings deny` → `stdout=[]`.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:265-288`; `$A/logs/probe2.txt`

---

## Claim 19: ROLE: "A host test (Q-082, 2026-09-28) showed Claude Code still applies permissions.deny after a hook "allow" (a hook "ask" overrides it, Claude Code issue #39344, and this hook never asks), so the deny check below is redundant, and Q-092's second unit removes it."

**Location:** `hooks/auto-approve-allowed-commands.sh:57-60`
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Q-082 record, "never asks" (static plus executed plus mutants) and unit 2's removal; #39344's content is an external claim, consistent with Q-092 and log 53 but not fetched (no egress).

Q-082: Claim 1. Never asks: Claim 4; `grep -o '"permissionDecision":"[a-z]*"'` on the hook yields only `allow` (the test's static line passes). Unit 2: `grep -c 'matches_deny\|DENY_GLOBS\|add_deny_rule'` on `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh` → `0`.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:440`; `docs/working/questions-archive.md:1715`; `$A/logs/mutants.txt`

---

## Claim 20: WHAT THE DENY CHECK GUARANTEES: "The hook never approves a command when a Bash deny rule matches the raw command or any extracted command. It FAILS CLOSED on its inputs … The de-quoted match and the --deny test option are gone"

**Location:** `hooks/auto-approve-allowed-commands.sh:62-67`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the raw check (`:387`), the per-extracted check (`:427`), the shape failures listed, and the removal; "wrong shape" for permissions.allow/deny means non-array or (deny) non-string entry, while `false`/`null` count as absent (accepted pass-1 C1, deferred to unit 2).

`if matches_deny "$command"; then … exit 0` (`:387-390`) and `if matches_deny "$full_command"; then all_allowed=false; break` (`:427-430`). Mutant M2a (per-extracted check deleted) was killed. Baseline: `settings files of the wrong shape fail closed` and the malformed/unparseable tests pass. Gone: no `--deny` case in main (`:341-355`, probe2 `--deny ignored` → allow) and no de-quoting in `matches_deny` (`:294-309`); residuals probe approves `.cred""entials.json`.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:157-175`, `:265-309`, `:376-445`; `$A/m-M2a/bats.txt`; `$A/logs/residuals.txt`

---

## Claim 21: RESIDUALS: "a quote or backslash inside or around a word (`.cred""entials.json`, `.c\redentials.json`, `git "push"` against `Bash(git push:*)`, `cat "secret"` against `Bash(cat secret)`), a glob (`~/.claude/.c*`, `.credentials.jso[n]`), brace or ANSI-C spellings (`.js{on,}`, `$'\x2e'credentials.json`), a variable set by an earlier command, a decoded path, or reading the parent directory. … Settings sources Claude Code honors but this hook does not read … contribute no deny rules here. The glob and earlier-variable spellings are pinned by tests."

**Location:** `hooks/auto-approve-allowed-commands.sh:68-78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed spelling run against a matching deny rule with the command allow-listed; quoting the whole name (`".credentials.json"`) does not get past `*.credentials.json*` (the listed examples are the ones that do); a decoded path gets past the deny rule but, inside one call, is refused by the shape check, so in practice it is approved only through an earlier variable.

residuals: every listed spelling `APPROVED` (quote-split, backslash, `git "push"`, `cat "secret"`, `.c*`, `.jso[n]`, `.js{on,}`, `$'\x2e'…`, `cat $F`, `ls ~/.claude`); controls `cat ~/.claude/".credentials.json"` and `'…'` → `no-allow`. probe3: `cat $(echo … | base64 -d)` → `no-allow`, `Refusing: node type CmdSubst` (deny rule not matched; shape check refuses); `grep -r token ~/.claude` and `ls -la ~/.claude` → `APPROVED`. Settings sources: Claim 14. Pinned: tests at `test/auto-approve-allowed-commands.bats:230` and `:242`.

**Evidence:** `$A/logs/residuals.txt`; `$A/logs/probe3.txt`; `test/auto-approve-allowed-commands.bats:230-251`

---

## Claim 22: SETTINGS SOURCES: "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json, resolved like devcontainer-config/link-claude-home.sh's DEST (an empty value falls back; a relative value approves nothing), then <git root>/.claude/settings.json and settings.local.json (the cwd's .claude/ outside a repo). One jq call reads all of them"

**Location:** `hooks/auto-approve-allowed-commands.sh:80-84`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers empty, relative and absolute values, the repo/non-repo fallback by reading, and the single jq call; does not cover a symlinked config dir.

Linker: `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`devcontainer-config/link-claude-home.sh:36`); hook: `:145-146`, with `root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""` and `"${root:-.}/.claude/…"`. One call: `jq -nj "$SETTINGS_RULES_JQ" "${files[@]}" --args "${files[@]}"` (`:204`). probe2: `empty CCD falls back` → allow; relative `sub/cfg` (which holds a `Bash(cat:*)` allow) → `stdout=[]` for `cat x`, `ls`, and with `--permissions` (DENY_ALL path, `Decision: BLOCK (deny rule…`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:142-205`; `devcontainer-config/link-claude-home.sh:36`; `$A/logs/probe2.txt`

---

## Claim 23: RULE SYNTAX table and notes, incl. "`Bash(ls *)`   literal prefix `ls *`: `ls *` and `ls * -la`, never `ls -la` | glob: `ls -la`", "only `*` is a wildcard", "a rule with no wildcard, which is exact", KNOWN DIVERGENCE "Here it does not (`rm *` needs the space) … `Bash(rm:*)`, which matches `rm` alone but … also `rmdir`"

**Location:** `hooks/auto-approve-allowed-commands.sh:86-111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every table cell and the notes on the inputs probed; extglob literalness is by reading (every non-`[A-Za-z0-9*]` byte is escaped), not run; Claude Code's own semantics are not covered.

probe2 results: allow `Bash(ls)` vs `ls/x` → none; `Bash(a/b)` vs `a/b/x` → allow; `Bash(python3 d)` vs `python3 d/x` → allow; deny `Bash(ls)` vs `ls -la` → allow, vs `ls` → none; deny `Bash(rm:*)` vs `rmdir x` → none, vs bare `rm` → none; allow `Bash(ls *)`: `ls *` → allow, `ls * -la` → allow, `ls -la` → none; deny `Bash(ls *)` vs `ls -la` → none; deny `Bash(*)`, `Bash(**)` → none; deny `Bash(rm x)` vs `rm x` → none, vs `rm x y` → allow; deny `Bash(rm *)` vs bare `rm` → allow; deny `Bash(cat notes[1].txt)` vs `cat notes1.txt` → allow. Bare `Bash` as allow: test `rule table: a bare Bash rule is ignored` passes. Escaping: `if [[ "$c" == [A-Za-z0-9*] ]]; then glob+="$c"; else glob+="\\$c"` (`:251-255`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:211-258`, `:314-337`; `$A/logs/probe2.txt`

---

## Claim 24: load_rules: "--permissions replaces the settings files' allow lists (testing); their deny lists are always read. The reader's status comes from `wait $!`, as for the command parser in main (mapfile's own status is always 0); bash older than 4.4 makes that `wait` fail, which also fails closed."

**Location:** `hooks/auto-approve-allowed-commands.sh:260-264`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 behaviour and the read of the full function (`:265-288`); the bash < 4.4 clause was not executed (no older bash here).

`mapfile -d '' records < <(read_settings_rules)` then `if ! wait $!; then … DENY_ALL=true` (`:268-272`), the same pattern as main `:403-404`. Allow/deny split: Claim 18. probe2 `malformed global + --permissions` → `Decision: BLOCK (deny rule…)`, i.e. DENY_ALL set from the reader's failure.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:265-288`, `:403-408`; `$A/logs/probe2.txt`

---

## Claim 25: matches_deny: "True when a deny rule matches the string …, or when DENY_ALL is set. … add_deny_rule has already escaped everything but `*`, so `*` is the only live wildcard."

**Location:** `hooks/auto-approve-allowed-commands.sh:290-293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function body `:294-309` and add_deny_rule `:241-258`; does not cover multibyte characters under a UTF-8 locale (this environment fell back to C).

`if $DENY_ALL; then … return 0`, then `if [[ "$str" == $glob ]]` over `DENY_GLOBS` (`:296-306`). Mutants M2b (`?` live), M2c (`[ ]` live) and M2d (no escaping) were each killed by the prefix-deny test.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:241-309`; `$A/m-M2b/bats.txt`, `$A/m-M2c/bats.txt`, `$A/m-M2d/bats.txt`

---

## Claim 26: Section comment: "A hook "allow" does not override permissions.deny (host test Q-082), and the hook never emits "ask", the decision that does (Claude Code #39344). The hook still reads settings-file deny rules; --deny and the de-quoted match are gone."

**Location:** `test/auto-approve-allowed-commands.bats:114-119`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same evidence as Claims 19-20; #39344 not fetched.

See Claims 19 and 20 (`hooks/auto-approve-allowed-commands.sh:268-277`, `:440`).

**Evidence:** `test/auto-approve-allowed-commands.bats:114-119`

---

## Claim 27: Test "the hook's stdout is empty or exactly the allow decision: never ask, deny or defer" and its comment: "Stdout alone (stderr dropped), over main's exit paths for approved, refused, unparseable, unlisted, empty and malformed input (the jq-missing exit is not reached). Statically: the source spells exactly one decision."

**Location:** `test/auto-approve-allowed-commands.bats:147-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the static grep and the dynamic loop; the static grep alone misses a decision string spelled in pieces (M1a was caught only by the dynamic loop), and the dynamic loop covers only the listed inputs.

Mutants: M1a (deny path prints `"permissionDecision":"a"sk""`, invisible to the grep) failed at `:160` with `[cat ~/.claude/.credentials.json] -> {…"permissionDecision":"ask"}}`; M1b (stray `echo "parse failed"`) failed at `:160` on `[ls $(pwd)]`; M1c (literal `ask` line) failed at the static check `:153`. Control: the unmutated test passes (`$A/logs/control.txt`).

**Evidence:** `test/auto-approve-allowed-commands.bats:147-170`; `$A/m-M1a/bats.txt`, `$A/m-M1b/bats.txt`, `$A/m-M1c/bats.txt`; `$A/logs/control.txt`

---

## Claim 28: "# No allow rules, a malformed settings file, input with no command."

**Location:** `test/auto-approve-allowed-commands.bats:162`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mapping of the three checks that follow (`:163-169`) to main's exits; does not affect the test's pass/fail strength.

The three checks are a malformed global settings file (`echo '{not json' > …`, `:163-165`), `{}` (`:166-167`) and `not json` (`:168-169`). probe2 shows the first exits through `No Bash permissions found, exiting` (`:380-383`). So "no allow rules" and "a malformed settings file" are one case, and the third check, malformed hook input (`input not json: exit=4`), goes unnamed. Precise version: "A malformed settings file (no allow rules), input with no command, input that is not JSON."

**Evidence:** `test/auto-approve-allowed-commands.bats:162-169`; `hooks/auto-approve-allowed-commands.sh:364-383`; `$A/logs/probe2.txt`

---

## Claim 29: Test "a prefix deny rule blocks an extracted command inside a pipeline; only * is a wildcard" — "Pins the per-extracted-command check and add_deny_rule's escaping, which the raw check alone does not exercise"

**Location:** `test/auto-approve-allowed-commands.bats:213-228`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `?` and `[ ]` literalness and the extracted-command check; extglob characters are not exercised.

Killed: M2a (per-extracted check deleted, failed at `:219` on `ls | rm -rf x`), M2b (`?` live, failed at `:227` on `cat file1.txt`), M2c (`[ ]` live, failed at `:221`), M2d (no escaping, failed at `:221`). Control passes. `ls | rm -rf x` does not match `rm\ -rf*` as a raw string, so only the per-extracted check catches it.

**Evidence:** `test/auto-approve-allowed-commands.bats:213-228`; `$A/logs/mutants.txt`; `$A/logs/control.txt`

---

## Claim 30: Test "the hook ignores a --deny argument (the option was removed in Q-092)"

**Location:** `test/auto-approve-allowed-commands.bats:269-273`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the catch-all `*) shift` in main; with a value that starts like an option the catch-all shifts one word at a time, which the test does not probe.

`*) shift ;;` (`hooks/auto-approve-allowed-commands.sh:351-353`); probe2 `--deny ignored` → allow; baseline passes.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:341-355`; `$A/logs/probe2.txt`

---

## Claim 31: Settings-loading tests: "A settings file Claude Code may reject must not feed allow rules here." / "a malformed global settings file means nothing is approved" / "settings files of the wrong shape fail closed" / "an unparseable project settings.json fails closed even when settings.local.json is well formed"

**Location:** `test/auto-approve-allowed-commands.bats:275-310`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed shapes in each test; `false`/`null` lists are not among them (pass-1 C1).

All pass in the baseline; each asserts `not_approved` for `ls -la`/`cat notes.txt` with the bad file and (first test) `approved` with `{}`. The jq errors that produce this: `:159-173`.

**Evidence:** `test/auto-approve-allowed-commands.bats:275-310`; `hooks/auto-approve-allowed-commands.sh:157-175`; `$A/logs/baseline.txt`

---

## Claim 32: CLAUDE_CONFIG_DIR tests: "~/.claude is not the global dir while CLAUDE_CONFIG_DIR points elsewhere", "An empty CLAUDE_CONFIG_DIR falls back to $HOME/.claude", "a relative CLAUDE_CONFIG_DIR fails closed instead of reading another directory's allow rules", "a newline in the global settings path fails closed"

**Location:** `test/auto-approve-allowed-commands.bats:312-353`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions as written; the relative test's `sub/cfg` resolves from `$PROJECT`, so without the guard `ls` would be approved, which is what makes it discriminating.

Baseline passes; probe2 reproduces the relative case (`relative CCD, ls` → `stdout=[]` although `sub/cfg/settings.json` allows `cat` and the project allows `ls`). Guard: Claim 12.

**Evidence:** `test/auto-approve-allowed-commands.bats:312-353`; `$A/logs/probe2.txt`

---

## Claim 33: Test "a NUL inside a --permissions rule drops that rule only" — "Split rather than dropped, the second half would approve curl."

**Location:** `test/auto-approve-allowed-commands.bats:367-373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --permissions jq filter at `:285`; settings-file NUL handling is covered by other tests.

Mutant M3a (`select(type == "string")`, NUL filter removed) failed at `:370` (`not_approved` on `curl x`). The second half (`["Bash(ls\u0000:*)","Bash(ls:*)"]` → approved) shows the other rule survives. Control passes.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:281-287`; `$A/m-M3a/bats.txt`

---

## Claim 34: Rule-table tests, incl. "rule table: Bash(ls *) is a literal prefix, not a glob"

**Location:** `test/auto-approve-allowed-commands.bats:391-417`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the allow column only (deny cells: Claim 23); `ls *` itself is not asserted by the test (probe2 shows it is approved).

M4a (allow side matched as a glob) failed at `:409` (`ls -la` approved); M4b (rules containing `*` dropped, the old "approves nothing" reading) failed at `:411` (`ls * -la` not approved). The other three tests pass and match probe2.

**Evidence:** `test/auto-approve-allowed-commands.bats:391-417`; `$A/m-M4a/bats.txt`, `$A/m-M4b/bats.txt`

---

## Claim 35: 1a831ffe: "removes the parts nothing outside the tests used: the --deny test option and the de-quoted match"; "Split under the decision-62 cap (whole change 652 lines; this unit ~365)"; "No gate trailer: hooks/ and test/ are outside live-verify-gate's sets."

**Location:** `git log -1 1a831ffe`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sizes at the time of the commit, the absence of non-doc callers of `--deny`, and the gate regexes.

`git diff --numstat 00a27a2f..1a831ffe …` → `365`; `00a27a2f..ed06dec1` → `652` (1a831ffe is an ancestor of ed06dec1). `rg -l -- '--deny'` outside `docs/` finds only the hook (a comment, `:67`) and the test file. Gates: Claim 17.

**Evidence:** `git log -1 1a831ffe`; `hooks/live-verify-gate.sh:83`, `:91`

---

## Claim 36: b973e678: "Unit size 403 after this commit (loop tolerance ~800)."

**Location:** `git log -1 b973e678`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size claim; the message's other claims were verified in pass 2, and claim 18's misattribution (rubric C8) is accepted and not re-filed.

`git diff --numstat 00a27a2f..b973e678 -- ':(top)' ':(top,exclude)docs/' | awk …` → `403`. Tolerance: `docs/decisions/log.md:85` ("growth up to ~800 lines is tolerated").

**Evidence:** `git log -1 b973e678`; `docs/decisions/log.md:85`

---

## Claim 37: dbb15ec6: "The pass-2 fact-check showed the new test's "only * is a wildcard" title covered brackets only; a mutant that left `?` live passed. Adds the `Bash(cat file?.txt)` case."

**Location:** `git log -1 dbb15ec6`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the added case and that it now kills a `?`-live mutant; the earlier survival is taken from the pass-2 report (claim 13b), not re-run.

`git diff b973e678..dbb15ec6` adds `"Bash(cat file?.txt)"` to the deny list and the `cat file?.txt` / `cat file1.txt` assertions. M2b now fails at `:227`.

**Evidence:** `test/auto-approve-allowed-commands.bats:216`, `:225-228`; `$A/m-M2b/bats.txt`

---

## Claim 38: 5ba83a3a: "review artifacts only."

**Location:** `git log -1 5ba83a3a`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the files changed.

`git diff --name-only dbb15ec6..5ba83a3a` → three files, all under `docs/reviews/`.

**Evidence:** `git show --stat 5ba83a3a`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 16** (`docs/working/plan-q092-drop-hook-deny-reader.md:79-88`): the split section's "each under 400", "~365" and "~373" (whole change 652) were true at split time; U1 is now 407, unit 2 above it 436, the whole stack 697. Still within row 62's ~800 loop tolerance.

### Mostly Accurate
- **Claim 9** (`docs/working/plan-q092-drop-hook-deny-reader.md:40`): F5 says the family is "pinned"; only the `.c*` glob and `$F` are pinned by tests, not `.jso[n]`, brace or ANSI-C.
- **Claim 10** (`docs/working/plan-q092-drop-hook-deny-reader.md:41`): F6 says "an array of NUL-free strings"; after unit 2's 0444b1ac, non-string entries are skipped, so it is "an array with no NUL inside any string".
- **Claim 28** (`test/auto-approve-allowed-commands.bats:162`): the comment lists "no allow rules" and "a malformed settings file" as two cases (they are one exit) and does not name the third check, input that is not JSON.

### Unverifiable
- **Claim 8b** (`docs/working/plan-q092-drop-hook-deny-reader.md:39`): "documented CC behaviour for allow rules is operator-aware" needs the external Claude Code permissions docs; no web egress here.

---

## Goal-Alignment Note

The goal is to land Q-092 unit 1 (drop `--deny` and the de-quoted deny match) reviewed clean. Every code-facing claim in the unit holds: the header's ROLE, guarantee, residual, settings-source and rule-syntax text matches the hook's behaviour on every spelling run; "this hook never asks" holds statically and dynamically; and each of the four tests named in the brief kills its mutants (10 of 10). The three Mostly-accurate items and the Stale one are in the plan doc and one test comment. None changes what the hook does, and none blocks the unit. The plan's split counts and F6 wording have drifted after later review fixes in both units.
