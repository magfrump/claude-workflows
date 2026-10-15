Commit: 6bb29868

# Security Review — feat/q106-host-settings-merge, loop pass 3

**Scope:** `a4f3614a..6bb29868` (f14cf11a, 2298d18e, 6bb29868): `devcontainer-config/install.sh` (enforcement file), `hooks/lib/wiring-merge.jq`, `test/install-host.bats`, plus the doc edits. Checked `git diff 184396ea..HEAD` for controls deleted in sibling commits: none found.
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report.md` (pass 3: no behavioral red), rubric `code-review-rubric-2026-10-15-feat-q106-host-settings-merge.md` ("Pass 2 critics", "Loop pass 3"), `security-review-2026-10-15-q106-pass2.md`.
**Execution:** jq probes (`probe1.sh`, `probe2.sh`) and three end-to-end install.sh runs in a temp HOME (`x.bats` X1-X3, built from install-host.bats helpers), all under `/home/node/.claude/jobs/00bcf178/tmp/q106/sec3/`. Required tests: `LC_ALL=C bats -f 'T9[3-9]|T10[0-3]' test/install-host.bats`: 11/11 ok. jq 1.6.

## Prior findings (pass 2): verification

| # | Pass-2 finding | Status | How established |
|---|---|---|---|
| N1 | Two-document wiring.json passed the shape check | **Resolved** | Executed: `'{} {}'`, the empty file and `[{}]` are all refused by the extracted `WIRING_SHAPE` under `jq -se`. T100's hostile-first-document case passes. The shape check and the merge (`--slurpfile`, `$w[0]`) now parse the same document. |
| N2 | Non-command hook types passed | **Resolved for the hook entry** | Executed: T100 `type:"http"` is refused. A duplicate `type` key (`"http"` then `"command"`) passes, but jq keeps the last key, and jq writes the output, so settings.json gets a single `"type":"command"`: cleared. The group level is still open (F1 below). |
| N3 | Legacy prune deleted a single-slash Bash rule | **Resolved** | Executed (probe2): wiring `Read/Bash/NotebookEdit/MultiEdit(/{{CLAUDE_DIR}}/…)` against matching user single-slash rules. Only the `Read` one is removed; `Bash`, `NotebookEdit` and `MultiEdit` survive, and so does `Read(/secrets/**)`. T99 asserts the Bash case. |
| N4 | By-name list printed names raw | **Resolved for rule and hook names; mode labels partly** | Executed: X1 and X3 show `ADD hook: "<json>"`. A mode label with a trailing newline still prints raw (F2). |
| N6 | No line for added hooks | **Resolved** | Executed: X1 (`ADD hook: "Stop [{\"m\":1}] bash …/hooks/h.sh"`) and T102. One gap with duplicate hooks (F3). |
| N7 | Settings-only backup stamped, "entries moved" message | **Resolved** | Executed: T103 (backup holds only `settings.json`, no stamp, no "Previous entries moved"). Read-static: `:1196` gates the stamp, the count and the prune on `${#moved[@]} -gt 0`, and `moved` is declared at `:1125`. |
| N5, F4, F5 | — | Unchanged; with the user or accepted | Not re-filed. |

## Trust Boundary Map

```
B1: committed hooks/wiring.json (agent-authorable branch content) → WIRING_SHAPE (jq -s) + wiring-merge.jq → settings.json hooks/permissions run by Claude Code
B2: live ~/.claude/settings.json (user state)                     → one read into $s_view.raw, ONE_OBJ, merge → backup + mv over settings.json
B3: merged result + by-name list (strings from B1 and B2)         → vis_or_die → the human's terminal (the y decision)
B4: backup dirs under ~/.claude/.claude-workflows-backup          → stamp gate (moved > 0) → rm -rf retention prune
```

```
S1: hooks/wiring.json (payload, committed)  — request-time per install (any branch) — UNTRUSTED toward the settings sink (hook exec, permission grants) and the terminal sink
S2: ~/.claude/settings.json                 — runtime-mutable (user, denyWrite for agents) — trusted for content kept; UNTRUSTED toward the terminal sink (strings shown)
S3: hooks/lib/wiring-merge.jq (payload)     — request-time per install — UNTRUSTED code, shown in the file review; runs only inside jq (no exec or write builtins)
S4: $dest / s_dir (CLAUDE_HOME_DIR or HOME) — deploy-time (user env) — trusted
S5: WIRING_SHAPE, lbl, summary program      — code-constant in install.sh — trusted
```

The range changes only B1's guard (the shape), B1/B2's legacy prune, the B3 summary, and B4's gate. The design assumption is the same as in passes 1-2. A human reads the review, but the mechanical shape refusal is the only control that does not depend on that reader, and the by-name list is what the guide tells the reader to look at first.

## Findings

#### F1. `WIRING_SHAPE` allowlists hook entries but not the group level or value types, so a schema-invalid group is written into settings.json

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:735-738`
**Evidence:**
> `WIRING_SHAPE='length == 1 and (.[0] | type == "object") and ([.[0].hooks[]?[]? | (.hooks // []) | length > 0`
> `   and all(.type == "command" and ((keys - ["type", "command", "timeout"]) == [])`
**Boundary:** B1
**Move:** 11 (bypass enumeration on the N2 fix), 7 (shape of what is deserialized)
**Confidence:** Low. The acceptance and the write are executed. What Claude Code does with the result is not verified.
**Legibility-target:** for-author

All of the following pass the shape check, merge, and are written by install.sh after `y` (X1, executed). Probe1 confirms each separately.
- A group whose `hooks` is an **object** (`all()` iterates object values).
- `matcher` as an object.
- An extra group key (`"evil":1`).
- `timeout` as a string.

X1's settings.json: `[{"evil":1,"matcher":{"m":1},"hooks":{"a":{"type":"command","command":"bash …/hooks/h.sh","timeout":"soon"}}}]`. The executed command is still a reviewed payload hook, so N2's code-outside-the-payload threat stays closed. The new risk is how Claude Code handles a settings.json that fails its schema. If it rejects the file as a whole, the user's deny rules and guard hooks (`guard-trusted-writes.py`'s HARD-tier deny rules, decision 023 B) stop applying, and the merge fails open. If it skips only the bad entry, the group is inert. This is unverified: the sandbox has no Claude Code settings validator to run. The by-name list shows a plausible `ADD hook:` line (X1), so nothing marks the group as malformed. Pass 2 already recommended constraining group keys.

**Recommendation:** Extend the predicate to the group level. Group keys must be a subset of `["matcher","hooks"]`, `.hooks` must be an array, `matcher` (if present) a string, and `timeout` (if present) a number. Add a T100 case for an object-valued `hooks`. Queue a host check of Claude Code's behavior on a schema-invalid settings.json (whole file vs. entry).

#### F2. `lbl`'s `$` matches before a trailing newline, so a mode key `"allow\n"` prints unquoted and splits its by-name line

**Severity:** Low
**Location:** `devcontainer-config/install.sh:1051`, `:1057`
**Evidence:**
> `def lbl: if test("^[A-Za-z]+$") then . else tojson end;   # a mode name, quoted unless plain`
> `| (($b | rules($m)) - ($a | rules($m)))[] | "  ADD \($m | lbl) rule: " + tojson)]`
**Boundary:** B3
**Move:** 11 (bypass candidates for the P3-2 fix)
**Confidence:** High (executed: probe1 lbl table; X2 end to end)
**Legibility-target:** for-author

In jq 1.6 (Oniguruma), `$` matches at the end of the string and also before a final `\n`. So `"allow\n"` counts as plain (probe1: `[allow$` / `]$`), while `"\nallow"`, `"allow\nx"` and `"x\nallow"` are quoted. A committed wiring with mode `"allow\n"` produces this list (X2, `cat -A`):
`  ADD allow$`
` rule: "Bash(curl:*)"$`
Claude Code ignores the mode, since it is a different key from `allow`. So the list shows a phantom "ADD allow", and the code comment's promise "a newline in one cannot forge another line" (`:1045-1046`) is false for mode labels. The forged second line can carry only the fixed ` rule: ` text plus a JSON-quoted string, and a real `allow` mode always prints plain on its own line. This is misdirection, not concealment, which is why it is rated Low, the same rating as pass-2 N4. The same anchor also lets the command regex at `:738` accept a command with a trailing newline (probe1, `cmd trailing newline` → PASS). Run by a shell, that newline only ends the command: cleared.

**Recommendation:** Anchor with `\A…\z` in both regexes: `test("\\A[A-Za-z]+\\z")` and `…/hooks/[A-Za-z0-9_./-]+\\z`. Checked on jq 1.6: `"allow\n"` → false, the command with a trailing newline → false, `"allow"` → true.

#### F3. The by-name list compares hook keys as sets, so adding a second copy of a wired hook prints "(none — no hook … added)"

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:1053-1054`, `:1058`
**Evidence:**
> `| [((($a | cmds) - ($b | cmds))[] | "  UNWIRE hook: " + tojson),`
> `   ((($b | cmds) - ($a | cmds))[] | "  ADD hook: " + tojson),`
**Boundary:** B3
**Move:** 5 (what the summary does not cover)
**Confidence:** High (executed: X3)
**Legibility-target:** for-author

jq's array subtraction removes every equal element. Suppose a wiring change adds a second identical group (`PreToolUse [Bash] bash …/hooks/h.sh`) next to one already wired. The list then says `(none — no hook unwired or added, no rule removed or newly allowed)` while the diff adds the group (X3), and the hook fires twice. A doubled guard hook is harmless. A doubled payload hook with side effects (logging, auto-approve) is not obviously harmless. The guide tells the reader to "Read that list first", and here the list's "none" line is literally false. The diff still shows the change.

**Recommendation:** Count keys (`group_by(.) | map({k: .[0], n: length})`) and print `ADD hook:` for each extra copy, or reword the empty line so it does not claim that nothing was added.

## Untested bypass candidates

- **A wiring.json swap between the shape check (`:1025`) and the merge (`:1033`).** Both read `$dest/.cw-new.hooks/wiring.json`. `payload_hash` after `y` would catch a swap only if it was not swapped back. Needs a same-uid write inside `~/.claude` (denyWrite), the same precondition as the accepted N5. The merged output is in the diff the human approves. Not raced.
- **Claude Code's handling of the F1 shapes** (object `hooks`, object `matcher`, extra keys, string `timeout`). Needs a host Claude Code. Not run (no egress, no CC settings validator here).
- **U+2028/U+2029 inside a JSON-quoted name.** `tojson` and `vis` both pass them through. Whether a terminal breaks the line there is part of the accepted F5 class (bidi through vis). Not re-tested.

Tested and cleared: an embedded mid-string newline in the command regex, in both orders (refused). `^` does not match after a newline (`curl…\n<cmd>` refused). Event value `null` or `[]` (passes; the merge only unwires our groups for that event, which shows as `UNWIRE`). Event value as an object of groups (refused). `hooks` as a string (passes the shape; the merge then fails, so refused). A path ending in `hooks/` (refused). A duplicate `type` key (last wins, single key written). Legacy prune with the config dir mid-string (`Read(//etc/x(/{{CLAUDE_DIR}}/q)`): it removes only the user's identical single-slash string, a rule relative to the settings dir under Q-049, and the removal is listed as `REMOVE deny rule:`. Matcher `""` against absent: over-reported as UNWIRE+ADD, which is the safe direction.

## Endorsement Claims

- **Claim:** The legacy single-slash subtraction no longer removes a user's `Bash`, `NotebookEdit` or `MultiEdit` single-slash rule, or a `Read` rule outside the config dir.
  **Location:** `hooks/lib/wiring-merge.jq:52-57`
  **Evidence:** executed
  **Verified:** probe2 ran the merge on wiring `Read/Bash/NotebookEdit/MultiEdit(/{{CLAUDE_DIR}}/…)` against matching user rules plus `Read(/secrets)`. Only `Read(/h/.claude/x)` was removed. T99 passes.
  **Not verified:** the container caller `link-claude-home.sh` (same program, unchanged in this range) on a real container start.
  **route: code-fact-check**
- **Claim:** Each hook and rule name in the by-name list is printed as a JSON string, so a newline inside a rule string or hook command lands on the same output line.
  **Location:** `devcontainer-config/install.sh:1053-1057`
  **Evidence:** executed
  **Verified:** X1 and X3 output lines. Pass-2 probe E's newline-in-rule shape is escaped by `tojson` (JSON escapes U+0000-U+001F).
  **Not verified:** mode labels (F2 shows one that is not escaped) and U+2028/U+2029 rendering on real terminals.
  **route: code-fact-check**
- **Claim:** A run whose backup holds only settings.json writes no `.install-stamp` and reaches no `rm -rf`.
  **Location:** `devcontainer-config/install.sh:1196-1223`
  **Evidence:** executed
  **Verified:** T103 (backup listing is exactly `settings.json`; no "Previous entries moved"). Read: the prune loop sits inside the `${#moved[@]} -gt 0` branch.
  **Not verified:** a full install with entries moved after several settings-only backups (the retention count over mixed stamped and unstamped dirs), traced but not run.
  **route: code-fact-check**

## Primitive sweep

Primitive: JSON deserialization of S1/S2 (jq)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `install.sh:1025` shape check | S1 | `env -i`, `HOME=/nonexistent`, `-s` | F1 (group level unconstrained), F2 (command `$` anchor, cleared) |
| `install.sh:1029` ONE_OBJ | S2 | `-s`, one object | cleared — unchanged this range |
| `install.sh:1032-1034` merge | S1, S2, S3 | prior shape + ONE_OBJ | cleared for N3 (probe2); writes F1 shapes (X1) |
| `install.sh:1035` ONE_OBJ on output | merged | `-s` | cleared — unchanged |
| `install.sh:1047-1059` summary | S1 (via merge), S2 | `tojson` on names | F2 (mode label), F3 (set semantics) |

Primitive: untrusted strings to the terminal
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `install.sh:1040` NOT-merged WARNING | S4 path + constant reasons | `vis_or_die` | cleared — reason strings are constants |
| `install.sh:1066` by-name list | S1, S2 | `tojson` + `vis_or_die` | F2 |
| `install.sh:1067` settings diff | S1, S2 | `vis_or_die` | cleared — unchanged; F5 class accepted |

Primitive: `rm -rf` (retention prune)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `install.sh:1209` | B4 backup dir names | stamp present + epoch + not this run + not a link; now also `moved > 0` | cleared — the gate change narrows when it runs (T103) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Shape check does not constrain the group level or value types; schema-invalid groups are written | Medium | B1 | `install.sh:735-738` | Low |
| F2 | `$` matches before a trailing newline: mode label `"allow\n"` printed raw, list line split | Low | B3 | `install.sh:1051` | High |
| F3 | Set difference hides a duplicated hook; the list says "(none — … added)" | Informational | B3 | `install.sh:1053-1058` | High |

## Overall Assessment

Pass-2 N1, N2 (hook entries), N3, N6 and N7 are resolved, each by execution. N4 is resolved for names, with one anchor gap left in mode labels (F2). The fixes introduced no regression: no control was deleted across `184396ea..HEAD`, and the 11 required tests pass. The one remaining item worth fixing before merge is F1. The shape allowlist stops at the hook entry, so a committed wiring can write a group Claude Code may refuse. Whether that refusal drops the whole settings file, and with it the deny rules, is unverified and needs a host check. F1 and F2 are both small edits to the same predicate and regexes, plus one T100 case. None of this is architectural. No findings beyond these in the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report at /workspace/.claude/wt-q106/docs/reviews/security-review-2026-10-15-q106-pass3.md per the security-reviewer skill, first line `Commit: <HEAD short sha>`.
- Answered: yes — N1-N4, N6, N7 checked (all resolved; N4 partly, F2); three new items from bypass enumeration on the fixes.
- Out of scope: F4, F5, N5 (with the user or accepted); link-claude-home.sh (unchanged in range).
- Escalate: host check of Claude Code's behavior on a schema-invalid settings.json (decides F1's real severity).
- Decisions I made: rated F1 Medium under the floor rule with Low confidence, rather than Low, because the fail-open outcome is unverified but named; rated F2 Low to match pass-2 N4, rather than Medium, because no attacker-chosen text lands on a forged line.
