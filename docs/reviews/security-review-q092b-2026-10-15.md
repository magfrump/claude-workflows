Commit: ed06dec1

# Security Review — Q-092 unit 2 (fix/q092-drop-hook-deny-reader)

**Scope:** `git diff 1a831ffe..ed06dec1` (hook, wiring.json `_comment`, bare-host guide, decision log row 53, two bats files), plus the full hook file and the PreToolUse wiring it sits in
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-q092b-2026-10-15.md; plan docs/working/plan-q092-drop-hook-deny-reader.md (F1-F10)

## Trust Boundary Map

```
B1: [tool_input.command from CC stdin]       → [shfmt parse + SHAPE_FILTER + allow-prefix match] → [stdout "allow" or nothing]
B2: [settings files: global, project .claude] → [SETTINGS_RULES_JQ shape check, read_settings_rules] → [ALLOW_PREFIXES]
B3 (removed): [permissions.deny in those files] → [matches_deny]                                    → [withhold this hook's allow]
B4: [this hook's stdout/exit + guard-trusted-writes + live-verify-gate] → [CC hook merge, then permissions.deny] → [run / prompt / deny]
B5: [env CLAUDE_CONFIG_DIR, HOME]             → [settings_files resolution + relative/newline checks] → [file list for B2]
```

```
S1: tool_input.command                 — request-time    — UNTRUSTED (all sinks; model output, prompt-injectable)
S2: ${CLAUDE_CONFIG_DIR}/settings.json — runtime-mutable — UNTRUSTED toward the approval sink (user, CC's own /permissions UI and
                                                           future CC versions write it; agent writes are guarded, not impossible)
S3: <git root>/.claude/settings*.json  — runtime-mutable — UNTRUSTED toward the approval sink (repo content)
S4: CLAUDE_CONFIG_DIR / HOME env       — deploy-time     — trusted for path selection, validated (relative/newline fail closed)
S5: hook code constants (filters)      — code-constant   — trusted
```

The diff removes B3. After it, the only thing standing between an allow-listed S1 command and execution, for a command a Bash deny rule names, is Claude Code's own deny evaluation at B4 (Q-082). The hook still decides at B2 which files' allow rules count, and that decision is now the only point where the hook's view of a settings file and Claude Code's view can diverge in a way that matters (Finding 1).

## Answers to the brief's direct questions

- **Can the hook output anything but "allow" or nothing?** No path found. The only stdout write in `main` is line 352; `debug`, the shfmt parse error and jq errors go to stderr; `show_help`/`check_deps` (`exit 2`) are reachable only via the `parse_commands` argv, which wiring.json never passes. Executed: 33 probe inputs (malformed JSON, non-object input, non-string `command`, NUL in command, two concatenated documents, every settings defect below, unset HOME, minimal PATH). stdout was empty or exactly the allow JSON every time; exit codes observed were 0, 4 (malformed JSON) and 5 (non-object input), never 2. JSON on stderr is not read by CC on exit 0, and a non-2 non-zero exit is a non-blocking error with no decision.
- **Does removing B3 change the combined decision with the other PreToolUse hooks?** No, by reading. guard-trusted-writes.py documents CC's merge as `deny > defer > ask > allow` (header lines 16-17), and live-verify-gate exits 2 (block). The removed reader only ever withheld this hook's own `allow`; it never emitted a decision. So wherever guard says ask/deny or the gate blocks, the result is the same before and after; where both are silent, the result is this hook's `allow` followed by CC's `permissions.deny` (Q-082). The guard's Bash `ask` overriding a deny rule (plan F8) is unchanged and not this diff's.
- **Fail-closed loading after the refactor.** Executed, all approve nothing: relative `CLAUDE_CONFIG_DIR`, newline in it, unset HOME, NUL inside an allow string, partial output (jq prints records then errors: `load_rules` returns before the `for` loop, so nothing is kept), a directory, empty file, chmod-000 file, trailing garbage, `allow` as a string, non-string `deny` entry. Approve normally (treated as absent or skipped): `deny: null`, `deny: false`, non-string `allow` entries, an `ask`/`defaultMode` of any shape, a UTF-8 BOM. These last five are Finding 1.
- **Residual statements.** Honest about F3/F4/F5 and about the credentials rule being the only Bash backstop. They omit F10 and the Q-082 version (Finding 2) and the family in Finding 1.

## Findings

#### 1. Missing bypass family: a settings file Claude Code ignores whole, which the hook still loads — U2 removes the last refusal on that path

**Severity:** Medium
**Location:** `hooks/auto-approve-allowed-commands.sh:69-73` (header claim), `:142-150` (SETTINGS_RULES_JQ); plan table row F6
**Boundary:** B2, B4
**Move:** 11 (bypass enumeration), 5 (invert the model)
**Confidence:** High that the hook behaves as described (executed); Low on reachability (which values make CC 2.1.300 drop a whole file was not traced)
**Legibility-target:** header FAILS CLOSED paragraph and plan F6 row

**Evidence:** header: "permissions.deny is shape-checked but not read: Claude Code may reject such a file, and then its allow rules should not count here." jq: "(.allow // []) | if type == \"array\" then .[] | select(type == \"string\")". Plan F6: "so a file Claude Code may reject never feeds allow rules".

Claude Code 2.1.300 (the binary in this image) has a path that drops an entire settings file: its strings include "`does not load (`... `is not valid), so Claude Code ignores the whole file`". When that happens to the global file, CC loses `Bash(*.credentials.json*)` along with everything else. The hook checks only the shapes of `permissions`, `permissions.allow` and `permissions.deny`, and it treats `deny: null`/`false` as absent, skips non-string allow entries, accepts any `ask`/`defaultMode`/other key, and accepts a BOM-prefixed file. Executed before/after, global settings `{"permissions":{"allow":["Bash(cat:*)",5],"deny":["Bash(*.credentials.json*)"]}}` (likewise with `"ask":"bogus"`), command `cat ~/.claude/.credentials.json`:
- hook at 1a831ffe (U1, reader present): no output, so the call goes to the prompt;
- hook at ed06dec1: `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}`.

If CC ignores that file, no deny rule applies and the hook's allow lets the command run with no prompt. The same applies to project files (S3): their deny rules are lost and their allow rules still approve. Before U2 the reader backstopped exactly this divergence. After U2 nothing does, and F1-F10 do not list it: F6 marks it "Covered" on the strength of a check that covers three keys. Reaching it requires a CC-invalid value in a settings file. Plausible routes are version drift (CC's own message says "If a newer Claude Code wrote the file") or a hand edit. The agent can't get there directly, since settings writes are guarded.

**Recommendation:** Add the family to the plan table and the header's FAILS CLOSED paragraph as a stated residual: the hook cannot know whether CC loaded a file. Make the cheap narrowing too: fail closed on a non-string `allow` entry (consistent with `deny`), on `deny`/`allow` of `null`/`false`, and on a non-array `ask`. Then reword "its allow rules should not count here" to name the keys actually checked.

#### 2. Residual statements omit version drift (F10) and the CC version Q-082 ran on

**Severity:** Low
**Location:** `hooks/auto-approve-allowed-commands.sh:50-67`; `docs/decisions/log.md:76` (2026-10-15 amendment); `guides/bare-host-hook-wiring.md:156-161`; `hooks/wiring.json:42-46`
**Boundary:** B4
**Move:** 5 (what does this now prevent), honesty of residuals
**Confidence:** High
**Legibility-target:** header DENY RULES ARE CLAUDE CODE'S section, decision-log amendment

**Evidence:** header: "a hook \"ask\" overrides permissions.deny (Claude Code issue #39344), but a hook \"allow\" does not (host test Q-082, 2026-09-28; decision log row 53)." Plan step 1: "replaced by a short \"DENY RULES ARE CLAUDE CODE'S\" note with F3/F4/F10".

All of U2's safety now rests on one host observation about CC precedence, and the image installs `claude-code@latest` (this container runs 2.1.300). Q-082's entry does not record the version. Q-091, from the same day, puts the host at 2.1.284, which is inferred, not stated by Q-082. The plan says the header note would carry F10, but the header, the amendment, the guide and the `_comment` each state the precedence as a standing fact with no version and no re-test trigger. If a later CC let a hook `allow` beat deny, the credentials rule would silently stop working under this hook, and nothing in the repo would prompt a re-check. This is not a mechanism by which a property is violated today, which is why it is rated Low and not Medium.

**Recommendation:** In the header and the row-53 amendment, add one sentence: "Q-082 ran on CC <version>; re-run it (the throwaway-directory recipe in Q-082) after a CC upgrade that changes hook or permission handling." The guide and `_comment` can point to that sentence.

## Untested bypass candidates

- **CC's deny matching of the shipped rule after its own command normalization.** The hook now approves `ls && cat ~/.claude/.credentials.json` and `cat ~/.claude/.credentials.json 2>/dev/null` (executed). Plan F4 infers that `*...*` matches "the raw string anywhere". Not tested: whether CC matches deny rules against split subcommands with redirections or env prefixes stripped. Untested because it needs a CC run, which the brief excludes. The literal path stays in the argv in every form the hook approves, so a miss here looks unlikely.
- **Q-082's generality.** The test had one hook and a project-local deny rule. Production has a user-scope deny rule and three Bash hooks running together. Untested (needs a host run). Precedence across sources and the merge order above make a difference unlikely.
- **Hook `allow` against `permissions.ask` rules.** Unchanged by this diff (the hook never read ask rules), and outside Q-092. If a user relies on `ask` rules, the hook's allow may skip them. Not tested.
- **FIFO or device as a settings file** (S3, a repo can plant `.claude/settings.json` as a FIFO): `jq` would block until CC's hook timeout, then the normal flow runs. Availability only, and the code is not from this diff. Not run, to avoid a blocking probe.
- **Quote-split / backslash spellings (F3)**: known and accepted per the brief. Approval confirmed executed (`cat ~/.claude/.cred""entials.json` is approved at both 1a831ffe and ed06dec1); CC's handling is not tested.

## Endorsement Claims

- **Claim:** Across 33 probe inputs, the hook's stdout was either empty or exactly the allow JSON, and its exit status was 0, 4 or 5, never 2.
  **Location:** `hooks/auto-approve-allowed-commands.sh:262-358`
  **Evidence:** executed
  **Verified:** probe harness at `$TMP/agents/security-review-q092b-2026-10-15/probe.sh` run under `timeout`; inputs listed in "Answers" above; `bats test/auto-approve-allowed-commands.bats` 33/33 ok.
  **Not verified:** the `jq`-missing early exit (line 281-284) and a SIGPIPE/141 path from `echo | jq` under pipefail. Neither writes stdout, by reading.
  **route: code-fact-check**
- **Claim:** Removing B3 does not change the merged PreToolUse decision when guard-trusted-writes emits ask/deny or live-verify-gate exits 2. The removed code only withheld this hook's own allow.
  **Location:** `hooks/wiring.json` PreToolUse block; `hooks/guard-trusted-writes.py:16-17,68-86`; diff of `main` at 1a831ffe..ed06dec1
  **Evidence:** read-static
  **Verified:** read the wiring, the guard's documented merge order and decision emitters, and the gate's `exit 2`.
  **Not verified:** CC 2.1.300's actual merge implementation for parallel hooks (taken from the guard's header and #39344, not from the binary).
  **route: code-fact-check**
- **Claim:** After the refactor, every settings-load failure listed in "Answers" leaves `ALLOW_PREFIXES` empty, including partial jq output followed by an error.
  **Location:** `hooks/auto-approve-allowed-commands.sh:157-184,216-232`
  **Evidence:** executed
  **Verified:** probe rows relative-ccd, newline-ccd, home-unset, nul-allow, dir-as-settings, empty-proj-file, unreadable, trailing-garbage, allow-string, deny-nonstring; read `load_rules` through its last line.
  **Not verified:** bash < 4.4 (`wait $!` on a process substitution). By the comment that also fails closed; not run here.

## Primitive sweep

Primitive: path construction / file read (settings files)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/auto-approve-allowed-commands.sh:123` global path | S4 | relative and newline checks (163-174) | cleared: executed fail-closed probes |
| `hooks/auto-approve-allowed-commands.sh:124` project paths | S3 (git root) | `-e` test, newline check | cleared for path selection; content is Finding 1; FIFO hang listed as untested |
| `hooks/auto-approve-allowed-commands.sh:183` `jq -nj ... files` | S2, S3 | doc-count, type and shape checks, `wait $!` | Finding 1 (partial shape check) |

Primitive: process exec. The hook runs `jq`, `shfmt`, `perl`, `git` with S1 passed as stdin or argument data, and never as code. There is no `eval`, and no part of S1 reaches a shell. Not changed by this diff. Cleared by reading.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | File CC ignores whole still feeds allow rules; U2 removes the last refusal on that path; not in F1-F10 | Medium | B2, B4 | `hooks/auto-approve-allowed-commands.sh:69-73,142-150`; plan F6 | High (mechanism) / Low (reachability) |
| 2 | Residuals omit F10 version drift and Q-082's CC version | Low | B4 | header 50-67; log.md:76; guide 156-161; wiring.json 42-46 | High |

## Overall Assessment

The core claim holds. The hook can emit only `allow` or nothing, so #39344's `ask` override doesn't apply. Removing the reader leaves the merge with the guard and the gate unchanged. The fail-closed loading survived the refactor, including partial jq output. The removal is sound as Q-092 intends, and both findings can be fixed in place without design changes. The one gap the author's pre-mortem missed is Finding 1. The deny reader also covered the case where Claude Code drops a settings file the hook still trusts, and F6 overstates how far the remaining shape check mirrors Claude Code. The most important fix is to state that residual and tighten the cheap checks (non-string allow entries, null/false lists, `ask` shape). Within the code paths read, there are no further findings. The second endorsement claim (the merge semantics) still awaits execution verification.

## Goal-Alignment Note

The goal was to land Q-092 so that each deny rule has one interpreter, after confirming the hook never emits `ask`. This review confirms the precondition by execution and finds the removal consistent with the goal. Finding 1 does not argue for keeping a deny reader. It asks that the one remaining divergence between the hook's view of settings files and Claude Code's view be named, and narrowed where that is cheap. Finding 2 asks that the single host observation now carrying the design be dated and given a re-test trigger. Neither blocks the unit's intent. Finding 1 is Medium under the skill's floor rule and should be resolved, or recorded as an accepted residual, before merge.
