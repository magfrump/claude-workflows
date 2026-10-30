Commit: c9ff3e84

# Critics, pass 2: Q-092 unit 2 (q092b)

**Scope:** `git diff ed06dec1..c9ff3e84 -- hooks/ test/ docs/decisions/` in `/workspace/.claude/wt-q092` (branch fix/q092-drop-hook-deny-reader); commits 72b8c825, fdae7834, plus unit 1's b973e678/dbb15ec6 merged in (reviewed separately in `critics-q092a-pass2-2026-10-15.md`).
**Date:** 2026-10-15
**Based on:** `code-fact-check-report-q092b-2026-10-15.md`, `code-fact-check-report-q092b-pass2-2026-10-15.md`, pass-1 rubric `code-review-rubric-2026-10-15-fix-q092-drop-hook-deny-reader.md`
**Roles:** performance-reviewer, api-consistency-reviewer, architecture-review (in that order)

The key change: `SETTINGS_RULES_JQ` (`hooks/auto-approve-allowed-commands.sh:146-161`) now requires a present `permissions` to be an object, and a present `permissions.allow`, `.deny` or `.ask` to be an array of NUL-free strings. Before this, non-string allow entries were skipped, `null`/`false` counted as absent, and `ask` was unchecked. Any violation is a jq error, and `load_rules` then keeps no rule (lines 224-240, read in full). Also in the delta: the ROLE version note and re-test trigger (lines 55-59), the FAILS CLOSED rewrite (lines 74-82), the rule-table row, decision log row 53, and tests.

Suite: `timeout 600 bats test/auto-approve-allowed-commands.bats` → 34/34 ok, 0 `not ok` (executed at c9ff3e84).

Probe artifacts: `/home/node/.claude/jobs/00bcf178/tmp/q092/agents/critics-q092-pass2/` (`filter.jq` is byte-identical to the hook's heredoc, checked with `diff`; `old.jq` is ed06dec1's; `probe-real.sh`, `bench.sh`).

---

## 1. Performance Review — q092b pass 2

### Data Flow and Hot Paths

`read_settings_rules` runs one `jq` process per Bash tool call over up to three settings files: global, project and project-local. That makes it per-call (hot), but N is small. The real files on this machine hold 16, 4 and 12 rules. The new filter now explodes every string in allow, deny and ask to look for a NUL. Before, it exploded only the emitted allow strings and type-checked deny without exploding. So the work is still linear in total rule characters, with a larger constant and more strings covered.

Measured, 20 runs each, under `timeout 60` per call (jq 1.6, this container; `bench.sh`):

| Input | old (ed06dec1) | new (c9ff3e84) |
|---|---|---|
| 3 files shaped like the real ones (16 allow / 4 allow / 12 deny) | 32 ms/call | 33 ms/call |
| 1 file, 2000 allow + 2000 deny + 2000 ask, ~80-char rules | 228 ms/call | 528 ms/call |
| 1 file, one 1 MB allow rule | 1090 ms/call | 838 ms/call |

### Findings

#### `explode | any(. == 0)` is the costly way to find a NUL, and the filter now applies it to deny and ask as well

**Severity:** Informational
**Location:** `hooks/auto-approve-allowed-commands.sh:155-157`
**Move:** 1 (hidden multiplication), 9 (constant vs asymptote)
**Classification:** Micro (per-string constant factor; still linear) / Hot path (once per Bash tool call), N small in practice
**Confidence:** High (executed)
**Baseline:** 33 ms/call for the new filter on three files shaped like this machine's real settings (32 ms before), measured with `bench.sh` on 2026-10-15
**Evidence:** `| if type == "array" and all(.[]; type == "string" and (explode | any(. == 0) | not))`
**Legibility-target:** for-author

`explode` builds a codepoint array for every rule string. That now covers deny and ask too, which the old filter only type-checked. At realistic sizes this is noise: +1 ms on a ~85 ms hook call. It only shows on synthetic input, where 6000 rules took 228 → 528 ms. A direct search costs much less on the same 6000-rule input: `[.permissions[][] | test("\u0000")] | any` took 32 ms and `index("\u0000")` 38 ms, against 360 ms for the explode form (5 runs each). Both return true for `"a\u0000b"` and false/null for `"abc"` (executed). One trap: **do not use `contains("\u0000")`**. On jq 1.6, which this image has, it returns `true` for `"abc"` (executed), so it would fail closed on every file.

**Recommendation:** Optional. If you touch this filter again, `test("\u0000") | not` (or `index("\u0000") == null`) is a drop-in replacement. Add a comment warning off `contains`. No action is needed for this unit.

### Endorsements (evidence-gated)

- The new filter's per-call cost is unchanged at realistic settings sizes (32 → 33 ms/call over three real-shaped files). [read: bench.sh output above, executed 2026-10-15]
- When a file fails the shape check, the hook does not parse it twice: the error stops jq, and `load_rules` discards any records printed before it. [read: hooks/auto-approve-allowed-commands.sh:224-240, 165-192]

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| P1 | `explode`-based NUL check is ~10x slower than `test`/`index` on large inputs; now also runs over deny/ask | Informational | `hooks/auto-approve-allowed-commands.sh:155-157` | High |

### Overall Assessment

The performance posture is unchanged where it matters. The extra validation costs about 1 ms per call at real sizes. The superlinear-looking jump on 6000 rules is a constant factor, not a complexity change. A cheaper NUL test exists if anyone revisits the filter. Pass 1's performance review had no findings to carry forward.

---

## 2. API Consistency Review — q092b pass 2

### Baseline Conventions

The settings files are a contract the hook shares with Claude Code, which owns the schema. Two consumers read the same file:

- **Claude Code 2.1.300** (the binary in this image). Its permissions schema is `allow: T(Vl()).optional()`, `deny: T(fr()).optional()`, `ask: T(fr()).optional()`, inside a `.passthrough()` object. Validation is preceded by a pre-filter, `yb(e,n,r)`, which for each of `["allow","deny","ask"]` that is an array removes non-string entries ("`Non-string value in ${g} array was removed`") and invalid rules ("`Invalid permission rule "${y}" was skipped`"). Both are pushed with `severity:"warning"`. The "ignores the whole file" message (`HFr`) counts only errors where `u.severity!=="warning"`. A value that is not an array (`null`, `false`, a string) is skipped by the pre-filter (`if(!Array.isArray(m))continue`) and then fails the zod `.optional()` array type. That is a non-warning error, so it is a whole-file drop. (Read from the binary with `strings`/`grep -ao`. This is code reading, not an executed Claude Code run.)
- **The hook.** Before this delta: non-string allow entries were skipped, `null`/`false` lists counted as absent, `permissions: null` counted as absent, and `ask` was unchecked. After: each of those, when present, fails the whole call closed.
- **Producers in this repo**, all checked:
  - `hooks/wiring.json` has only `permissions.deny`, 12 strings.
  - The linker (`devcontainer-config/link-claude-home.sh:150-161`) normalizes `.permissions //= {}`, so its output never has `permissions: null`. It writes only wiring's string rules and preserves the user's own entries unchanged. It never creates `ask`.
  - No `.claude/settings*.json` is tracked in the repo (`git ls-files`). The untracked live files `/workspace/.claude/settings.json` (16 string allow), `/workspace/.claude/settings.local.json` (4 string allow) and `~/.claude/settings.json` (12 string deny) pass the new filter with the same rule counts as the old one (`probe-real.sh`, executed).
  - No managed-settings file is rendered by devcontainer-config (`rg managed-settings devcontainer-config/` finds nothing).
  - The only other test fixtures with `permissions` (`test/link-claude-home-wiring.bats`, `test/scripts/health-check.bats`) are not fed to the hook, and all of their lists are string arrays.

### Name-Pattern Audit

The diff introduces no new public names. The new jq error strings (`permissions.\($k) is not an array of NUL-free strings`) go to stderr, and stderr is dropped (`2>/dev/null`, line 191), so they are not a consumer surface. No flags, keys or output fields were added.

### Findings

#### A non-string entry in `allow` or `ask` now turns off all auto-approval, though Claude Code keeps such a file and drops only the entry

**Severity:** Minor
**Location:** `hooks/auto-approve-allowed-commands.sh:155-157` (filter), `:77-80` (FAILS CLOSED rationale), `:143-144` (filter comment); `test/auto-approve-allowed-commands.bats:211-212` (fixtures `{"permissions":{"allow":[5]}}`, `{"permissions":{"ask":[1]}}`); `docs/decisions/log.md:76` (row 53, 2026-10-15 amendment)
**Move:** 3 (consumer contract: narrowed accepted input), 7 (asymmetry with the schema owner)
**Confidence:** Medium. The Claude Code behaviour is read from the 2.1.300 binary, not run. The hook behaviour is executed by the suite fixtures.
**Evidence:** hook lines 77-80: "deny and ask are shape-checked, never read: Claude Code can ignore a whole settings file for an invalid value, and a file it drops should not feed allow rules here." Claude Code 2.1.300: `if(typeof y!=="string")return c.push({file:n,path:`permissions.${g}`,message:`Non-string value in ${g} array was removed`,severity:"warning",invalidValue:y}),!1;` and `let p=ME(n).filter((u)=>u.file===r&&u.severity!=="warning")` … "`does not load (`…`), so Claude Code ignores the whole file`".
**Legibility-target:** for-author

The delta narrows what the hook accepts in two ways that are new in this unit. A non-string `allow` entry, which used to be skipped, now fails closed. So does any `ask` value that is not an array of strings, which used to be unchecked. (`deny: [1]` already failed closed at ed06dec1, so that part is not new.) The stated reason is Claude Code's whole-file drop. That reason holds for a non-array value (`null`, `false`, a string), which is what the `permissions: null`, `deny: null` and `ask: "Bash"` fixtures pin. It does not hold for a non-string *entry*. Claude Code's pre-filter removes such an entry with a warning, and its whole-file-drop path explicitly excludes warnings. So with `{"permissions":{"allow":["Bash(cat:*)",5],"deny":["Bash(*.credentials.json*)"]}}`, Claude Code most likely keeps the file and its deny rule, while the hook now approves nothing from any of the three files. The impact is usability, not safety: one stray entry, which the linker would carry over from a user's own file, silently turns every allow-listed Bash call back into a prompt. The only trace is `--debug` output. No settings file in this repo, its fixtures or the linker's output has such an entry (checked above), so no current consumer breaks.

This also means pass 1's motivating example is not a Claude Code whole-file drop. That example is security-review q092b's `"allow":["Bash(cat:*)",5]` before/after, carried into rubric A1. The `ask:"bogus"` and `deny:null/false` parts of A1 still stand.

**Recommendation:** Pick one and say it in the header and row 53. (a) Keep failing closed on non-string entries, and reword lines 77-80 so they say the check is deliberately stricter than Claude Code: Claude Code drops a non-string entry with a warning and keeps the file; the hook refuses the whole call. Or (b) go back to skipping non-string entries in all three lists, matching Claude Code's per-entry removal, and keep failing closed only on non-array values and NUL. Both are safe. (a) is the smaller change. Either way, a test-file comment on the `[5]`/`[1]` fixtures should name which choice they pin.

### What Looks Good

- `permissions: null`, `allow/deny: null|false` and a non-array `ask` now fail closed. These match the cases where Claude Code 2.1.300's zod schema rejects the value and drops the file, so the hook no longer approves from a file Claude Code ignores for those reasons.
- The NUL check now covers deny and ask. This resolves pass-1 API finding 1: test "a NUL inside a settings deny or ask rule fails closed", lines 284-292, passes.
- Every repo producer of settings, including the linker's merge (`.permissions //= {}`, string rules only), yields files the new filter accepts with the same rule count as before.
- Pass-1 Informational items 2 and 3 (`--permissions` skips the settings check; `--deny` is swallowed): Won't-Fix per #123, unchanged and still accurate.

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| A1 | Non-string `allow`/`ask` entry now fails the whole hook closed; Claude Code 2.1.300 strips the entry with a warning and keeps the file, so the stated rationale does not cover this case | Minor | `hooks/auto-approve-allowed-commands.sh:77-80, 143-144, 155-157`; `test/…bats:211-212`; `docs/decisions/log.md:76` | Medium |

### Overall Assessment

For every settings file this repo produces or tests, the change is consistent and backward-compatible. The one contract change that goes beyond what Claude Code itself does is failing closed on a non-string entry. It is safe, and no current file trips it, but the header and row 53 justify it with a Claude Code behaviour that, per the binary, applies to non-array values and not to non-string entries. A wording fix, or a narrower check, resolves it.

---

## 3. Architecture Review — q092b pass 2

### Scope check

In scope: category 4 (configuration loading). The delta changes the validation contract for the settings files the hook shares with Claude Code. Other files in the scope (log row 53, tests) are context.

### Dependency Map

The hook depends on three external contracts: Claude Code's hook I/O (stdin JSON → stdout decision), Claude Code's settings-file schema (read-only, through `SETTINGS_RULES_JQ`), and the linker's choice of global path (`settings_files`, lines 130-135). Nothing depends on the hook except Claude Code, through `hooks/wiring.json`. The delta does not add a dependency. It deepens the existing coupling to Claude Code's schema, from shape-checking `deny` to shape-checking `allow`, `deny` and `ask` plus `permissions` itself. The coupling is still stamp-level: types of three keys. The hook does not read deny/ask semantics. That keeps pass-1 architecture finding 1's distinction ("shape coupling, not semantic").

### Findings

No findings.

Pass-1 items:
- Finding 1 (shape check mirrors only part of the schema; premise unverified): resolved as the rubric records. `ask` is checked, and the comment names the whole-file-drop premise and its residual (lines 77-82). Reading the binary verifies the premise for non-array values and refutes it for non-string entries. That divergence is filed once, as API finding A1, because its consequence is a consumer-contract change, not a structural one. No new structural finding: the remedy is a wording or check-narrowing change inside the same function.
- Finding 2 (row 53 points at deleted sections): resolved. The 2026-10-15 amendment now says "its DENY RULES ARE CLAUDE CODE'S and FAILS CLOSED sections replace WHAT THE DENY CHECK GUARANTEES".
- Finding 3 (`--deny` swallowed): Won't-Fix per #123.

### What Looks Good

- The new check is one generic loop over `["allow","deny","ask"]`, not three copies, so one more list key would be a one-word change (Open/Closed at the right scale).
- Validation and extraction still happen in one jq pass with one failure exit, so "fail closed" has a single enforcement point (`load_rules`'s `wait $!`).
- The version note and re-test trigger in ROLE (lines 55-59) make the hook's dependence on Q-082's host result explicit and give it a revisit condition.

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | none (divergence filed as API A1) | — | — | — |

### Overall Assessment

The delta keeps the structure that pass 1 endorsed: one reader, one pass, one failure point, and coupling to Claude Code's settings types only. The one concern is how accurate the premise behind that coupling is, and that is a contract and documentation matter, handled under API A1.

---

## Goal-Alignment Note

Goal: land Q-092 (the hook stops interpreting deny rules) as two units, each reviewed clean. This delta closes pass 1's A1/A2/A3/C9 items, and the suite passes. One new item, API A1 (Minor), concerns accuracy rather than safety. It does not reopen a deny bypass: failing closed only ever sends a call to the prompt. What it changes is a documented premise. The header, row 53 and plan F6 attribute the non-string-entry check to Claude Code's whole-file drop, but per the 2.1.300 binary, Claude Code removes such entries with a warning. Either reword or narrow the check before calling the unit clean. The performance note (P1) is optional.
