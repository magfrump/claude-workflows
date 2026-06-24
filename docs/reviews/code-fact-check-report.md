# Code Fact-Check Report

**Commit:** eb545b103fa2e55ec6deed43d775c4c2eea761c8
**Repository:** /home/magfrump/claude-workflows
**Scope:** `git diff main...HEAD` (CLAUDE.md, README.md, docs/working/verify-batch-feedback-reminder.sh, docs/working/wire-batch-feedback-reminder.md, hooks/batch-feedback-routing-reminder.sh)
**Checked:** 2026-06-23
**Total claims checked:** 16
**Summary:** 16 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

---

## Claim 1: "fires only on (a) >=2 numbered list items, (b) >=2 bullet list items, or (c) an explicit multi-item enumeration phrasing. A single task, however it's phrased, must not match."

**Location:** `hooks/batch-feedback-routing-reminder.sh:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The script implements exactly three detection branches: numbered list via `grep -cE '^[[:space:]]*[0-9]+[.)][[:space:]]'` gated on `>= 2` (lines 50-51), bullet list via `grep -cE '^[[:space:]]*([-*•])[[:space:]]'` gated on `>= 2` (lines 54-55), and an enumeration regex `ENUM` (lines 60-64). The verify harness confirms single-task prompts ("single bug", "single feature", "one numbered step", "prose w/ number", "explain question") all produce empty output. All 15 cases pass.

**Evidence:** `hooks/batch-feedback-routing-reminder.sh:50-65`; verify run output ALL PASS

---

## Claim 2: "Non-blocking: always exits 0 and never emits a block decision"

**Location:** `hooks/batch-feedback-routing-reminder.sh:38-39`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The script omits `set -e`, the `emit()` function ends in `exit 0`, and the script ends in a bare `exit 0` (line 73). It writes only a reminder line to stdout, never a JSON block decision. The verify harness asserts `rc == 0` for every one of the 15 cases (including malformed JSON and missing prompt) and all pass.

**Evidence:** `hooks/batch-feedback-routing-reminder.sh:42,46,73`; verify run `exit=0` on all 15 cases

---

## Claim 3: "Additive ... a standalone script wired as an *additional* UserPromptSubmit hook in settings.json; it does not replace existing hooks."

**Location:** `hooks/batch-feedback-routing-reminder.sh:40-42`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Live `~/.claude/settings.json` `.hooks.UserPromptSubmit` contains a single entry with a `hooks` array of two commands: `bash $HOME/.claude/hooks/batch-feedback-routing-reminder.sh` and `bash $HOME/.claude/hooks/dd-routing-reminder.sh`. The batch hook is added alongside the dd hook, not replacing it.

**Evidence:** `jq '.hooks.UserPromptSubmit' ~/.claude/settings.json` output (two-command block)

---

## Claim 4: shellcheck-clean

**Location:** `hooks/batch-feedback-routing-reminder.sh` (whole file)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`shellcheck hooks/batch-feedback-routing-reminder.sh` produced no findings (exit 0, "SHELLCHECK CLEAN").

**Evidence:** shellcheck run output

---

## Claim 5: "the same pattern as the sibling dd-routing-reminder.sh"

**Location:** `hooks/batch-feedback-routing-reminder.sh:21-23`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`hooks/dd-routing-reminder.sh` exists and follows the same structure: no `set -e`, `INPUT=$(cat)`, jq `.prompt // ""` extraction with malformed-input fallback, `[[ -z "$PROMPT" ]] && exit 0`, narrow regex match, single one-line reminder, `exit 0`. The batch hook mirrors this pattern (with additional list-detection branches).

**Evidence:** `hooks/dd-routing-reminder.sh` (full file read); structural comparison

---

## Claim 6: CLAUDE.md rows renumbered correctly (old 2→3 … 10→11)

**Location:** `CLAUDE.md:18-28` (decision-tree table)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The table now has rows numbered 1 through 11 sequentially with no gaps or duplicates. Row 2 is the new batch fan-out row; old row 2 (divergent-design) is now row 3, and each subsequent old row shifted +1, ending at old row 10 (branch-strategy) → row 11.

**Evidence:** `grep -oE '^\| [0-9]+ ' CLAUDE.md` → 1,2,3,4,5,6,7,8,9,10,11

---

## Claim 7: the single "row 4" prose reference was updated to "row 5" and no dangling/incorrect row-number references remain

**Location:** `CLAUDE.md:65` (Tooling discovery section)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The Tooling-discovery prose now reads "Triggered by row 5 of the decision tree" (skill-creator is now row 5). Grep for `row 4|row 8|row 9|row 10` returns nothing. The only remaining row-number prose references are row 2, row 6, and row 7 — all consistent with the new numbering (row 6 = RPI, row 7 = task-decomposition).

**Evidence:** `CLAUDE.md:65`; `grep -n 'row 4...' CLAUDE.md` → none

---

## Claim 8: row 7 (task-decomposition) is correctly described as distinct from row 2

**Location:** `CLAUDE.md:25`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Row 7's Notes column contains "**Distinct from row 2:** this is *one* task whose research fans out (implementation stays sequential in the main agent); row 2 is *N independent tasks* that can each implement in parallel." The "Batch fan-out" section (line 59) and composition note (line 118) reinforce the same distinction consistently.

**Evidence:** `CLAUDE.md:25,59,118`

---

## Claim 9: the "Batch fan-out" section accurately names `superpowers:dispatching-parallel-agents` and `superpowers:using-git-worktrees` (skills are real)

**Location:** `CLAUDE.md:46-66` and table row 2 (line 19)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both skills exist as installed superpowers plugin skills. `find ~/.claude/plugins` locates `skills/dispatching-parallel-agents/SKILL.md` and `skills/using-git-worktrees/SKILL.md` (versions 5.1.0, 6.0.0, 6.0.3). Both also appear in the available-skills list. Neither is a fabricated symbol.

**Evidence:** `find ~/.claude/plugins/cache/.../superpowers/6.0.3/skills/{dispatching-parallel-agents,using-git-worktrees}/SKILL.md`; available-skills list

---

## Claim 10: "both reminders are now wired live"

**Location:** `docs/working/wire-batch-feedback-reminder.md:19-22`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Live settings show both commands present in `.hooks.UserPromptSubmit`, and both symlinks exist and resolve to existing target files in the checkout.

**Evidence:** `jq '.hooks.UserPromptSubmit'` output; `ls -l`/`readlink -f` on both symlinks

---

## Claim 11: ".hooks.UserPromptSubmit contains the two-command block"

**Location:** `docs/working/wire-batch-feedback-reminder.md:20-21`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The live `UserPromptSubmit` array has one entry whose `hooks` array contains exactly the two `command` entries (batch then dd), matching the documented JSON block (lines 39-55 of the wiring doc).

**Evidence:** `jq '.hooks.UserPromptSubmit' ~/.claude/settings.json`

---

## Claim 12: "both `~/.claude/hooks/*-reminder.sh` symlinks exist and resolve"

**Location:** `docs/working/wire-batch-feedback-reminder.md:21-22`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both `~/.claude/hooks/batch-feedback-routing-reminder.sh` and `~/.claude/hooks/dd-routing-reminder.sh` are symlinks into `/home/magfrump/claude-workflows/hooks/`, and `readlink -f` confirms each resolves to an existing file.

**Evidence:** `ls -l` and `readlink -f` output — both `[EXISTS]`

---

## Claim 13: "a missing target yields a non-zero (127) exit, which is a non-blocking error"

**Location:** `docs/working/wire-batch-feedback-reminder.md:13-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

`bash <missing-path>` returns 127 (standard "no such file" behavior for bash on a nonexistent script). UserPromptSubmit hooks treat a non-zero exit as non-blocking unless exit code 2 specifically (the documented blocking code for that hook); 127 is not a block. Confidence Medium because the precise harness semantics were inferred from Claude Code's documented hook contract rather than executed; the directional claim (127, non-blocking) is correct.
Paraphrased — no quote available because this is harness runtime behavior, not code in the diff.

**Evidence:** `docs/working/wire-batch-feedback-reminder.md:13-15`; bash exit-code convention

---

## Claim 14: README hook-listing lines accurately describe the two hooks

**Location:** `README.md:106-107`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Line 106 describes `hooks/dd-routing-reminder.sh` as a `UserPromptSubmit` hook nudging comparison/decision prompts toward divergent-design (non-blocking) — matches the dd hook's behavior and header. Line 107 describes `hooks/batch-feedback-routing-reminder.sh` as a `UserPromptSubmit` hook nudging multi-item prompts toward parallel-subagent fan-out per decision-tree row 2 (non-blocking), with wiring in `docs/working/wire-batch-feedback-reminder.md` — matches the batch hook's behavior, the row-2 reference, and the existing wiring-doc path.

**Evidence:** `README.md:106-107`; `hooks/dd-routing-reminder.sh`, `hooks/batch-feedback-routing-reminder.sh`

---

## Claim 15: verification harness "15 cases" and "all pass"

**Location:** `docs/working/wire-batch-feedback-reminder.md:81` and `docs/working/verify-batch-feedback-reminder.sh`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The harness contains exactly 15 `check` invocations (7 MATCH + 5 NO-MATCH + 3 ROBUSTNESS). Running `bash docs/working/verify-batch-feedback-reminder.sh` prints "ALL PASS" with exit 0; every case reports OK with `exit=0`.

**Evidence:** `grep -cE '^[[:space:]]*check ' ...` → 15; verify run output "ALL PASS", RC=0

---

## Claim 16: verify.sh header "every case exits 0 (never blocks)"

**Location:** `docs/working/verify-batch-feedback-reminder.sh:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The harness asserts `rc == 0` per case and all 15 cases report `exit=0`. The header also claims "multi-item batches emit one reminder, single tasks emit nothing, malformed/empty input is silent" — all confirmed by the MATCH/NO-MATCH/ROBUSTNESS results.

**Evidence:** verify run — all 15 cases `exit=0`

---

## Claims Requiring Attention
### Incorrect
- (none)
### Stale
- (none)
### Mostly Accurate
- (none)
### Unverifiable
- (none)

All 16 claims verified. No documentation rot, no fabricated symbols, no dangling row references. The renumbering is internally consistent, both named superpowers skills are real and installed, and the wiring doc's "wired live" status matches actual machine state.

## Goal-Alignment Note
- Answered: yes — all prioritized claims verified
- Out of scope: code-quality/design judgments on the hook and CLAUDE.md prose (deferred to downstream critics per skill scope)
- Escalate: nothing
