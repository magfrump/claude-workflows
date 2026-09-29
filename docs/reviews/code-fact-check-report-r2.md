Commit: 5ee8315

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-agents-md`, branch `fix/agents-md-no-imports`)
**Scope:** branch diff `git diff main...HEAD` (4 files: `AGENTS.md`, `docs/decisions/log.md`, `scripts/health-check.sh`, `test/agents-gemini-sync.bats`) plus the commit message of 5ee8315
**Checked:** 2026-09-29
**Total claims checked:** 16
**Summary:** 13 verified, 1 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) was read first. The closest prior pattern is the "specific measured value quoted from a checked-in artifact set that does not contain it" class (the `crb-cell-status.py` 3 KB entry); Claim 6a was checked against it and does not match (the 358 KB figure reproduces exactly).

Execution logs for this run are in the session scratchpad, `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc-r2/` (abbreviated `$S/` below). They were kept out of the worktree so that no file other than this report changes.

`AGENTS.md` itself has no new checkable claims: the diff only rewrites the nine list-item labels, and every description is unchanged.

---

## Claim 1: "Its workflow list now matches GEMINI.md byte for byte below the header"

**Location:** `docs/decisions/log.md:88`
**Type:** Invariant
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte identity of `tail -n +4` of AGENTS.md and GEMINI.md at 5ee8315 (the whole body, which is broader than just the workflow list); does not establish that the first three header lines are the only lines that differ in future edits, or anything about GEMINI.md's own loading semantics.

Command (cwd `/workspace/.claude/wt-agents-md`, 2026-09-29T00:00:30-07:00): `diff <(tail -n +4 AGENTS.md) <(tail -n +4 GEMINI.md)` exited 0 and `cmp` of the same streams exited 0. The whole body matches below line 3, not only the workflow list. The headers differ only on line 3: AGENTS.md reads `It is tool-agnostic and works with any agent that reads AGENTS.md`, and GEMINI.md reads `This file provides workflow instructions for Antigravity and Gemini CLI.` (quoted from the captured log). `git show main:GEMINI.md | diff - GEMINI.md` produced no output, so GEMINI.md is unchanged on the branch.

**Evidence:** `AGENTS.md:1-76`, `GEMINI.md:1-3`, `$S/gemini-diff.log`

---

## Claim 2: "`test/agents-gemini-sync.bats` fails on any `@path` import in AGENTS.md"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Incorrect
**Legibility target:** for-author
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers which spellings the guard regex matches, tested on the old AGENTS.md and on 18 synthetic lines; does not establish exactly which of the missed spellings Claude Code would expand, because the harness's import grammar is not documented anywhere in the repo.

The guard is:

```bash
# test/agents-gemini-sync.bats:34-40
@test "AGENTS.md has no @-imports" {
  if matches=$(grep -nE '(^|[[:space:]*`])@\.{0,2}/' "$AGENTS"); then
    echo "AGENTS.md contains @-imports, which Claude Code expands into every session:"
    echo "$matches"
    return 1
  fi
}
```

It matches `@` only when a `/` follows directly, or after `.` or `..`, and only when the `@` sits at line start or after whitespace, `*` or a backtick. Probe results (cwd `/workspace/.claude/wt-agents-md`, 2026-09-29T00:00:47-07:00; output in `$S/regex.log`):

- **Matched:** all 9 lines of `git show main:AGENTS.md`, plus `- **@./workflows/x.md**`, `@./x.md`, `see @../x.md`, `see @/abs/path.md`, `**@../x**`, `` `@./x.md` `` and a tab-indented `@./tab.md`.
- **Missed:** `see @x.md`, `see @~/x.md`, `see @workflows/x.md`, and `@./x.md` right after `(`, `"` or `[`.
- **No false positives:** `magfrump@gmail.com`, `foo@/bar`, `@pytest.mark`, `@@./x` and `@.../x`. The `(^|[[:space:]*\`])` prefix keeps email-style `x@y` from matching.

The missed spellings `@README`-style bare names, `@docs/x.md` and `@~/…` are ordinary Claude Code import forms. That comes from the reviewer's knowledge of Claude Code's memory-import docs (paraphrased — no quote available because the source is external documentation and the sandbox has no egress; nothing in the repo documents the grammar). So the guard does not fail on "any" `@path` import. It catches the `@/`, `@./` and `@../` family, which covers every line the old file used. A reader relying on "any" would wrongly believe `@docs/x.md` or `@~/x.md` would be caught. Confidence is Medium only because the import grammar is external. The regex's reach was established by running it.

**Evidence:** `test/agents-gemini-sync.bats:34-40`, `$S/regex.log`

---

## Claim 3: "The sections AGENTS.md shares with the global instructions (Context Packing, Shared Thoughts, General Principles) stay"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that all three headings exist in both files and that the diff did not touch those sections; does not establish that the sections' contents are identical between the two files.

`grep -nE '^## '` on AGENTS.md gives `41:## Context Packing`, `52:## Shared Thoughts`, `65:## General Principles`. `global-instructions/CLAUDE.md` has `126:## Context Packing`, `153:## Shared Thoughts`, `303:## General Principles`. The AGENTS.md hunk covers only lines 6-21 (`@@ -6,16 +6,16 @@`).

**Evidence:** `AGENTS.md:41`, `AGENTS.md:52`, `AGENTS.md:65`, `global-instructions/CLAUDE.md:126`, `global-instructions/CLAUDE.md:153`, `global-instructions/CLAUDE.md:303`

---

## Claim 4: "After row 47 moved the root CLAUDE.md out"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that log row 47 exists and records that move; does not establish when the harness started loading AGENTS.md as a result (see Claim 5).

Row 47 reads: `**The global instructions file moves out of the repo root to `global-instructions/CLAUDE.md`.**` (docs/decisions/log.md:70). `scripts/health-check.sh:54` has `GLOBAL_MD="global-instructions/CLAUDE.md"`.

**Evidence:** `docs/decisions/log.md:70`, `scripts/health-check.sh:54`

---

## Claim 5: "Claude Code loads AGENTS.md as this repo's project instructions and expands `@` imports inline … into every session here"

**Location:** `docs/decisions/log.md:88` (same claim restated at `test/agents-gemini-sync.bats:30-33` and in the error text at `test/agents-gemini-sync.bats:36`)
**Type:** Behavioral
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the harness behaviour seen in this reviewer's own session (cwd `/workspace`, main checkout, AGENTS.md at main); does not establish the behaviour from anything in the repo, for other Claude Code versions or configurations, or for whether sessions started without that AGENTS.md also expand it.

Nothing in the repo establishes this. No file documents Claude Code's loading or import behaviour (paraphrased — no quote available because the claim covers the absence of code: grepping `*.md` for `@~/`, `@README` and import-expansion wording found only unrelated curl `-d @~/` discussions in `docs/reviews/`). Out-of-repo evidence does support it. This reviewer's own session context (a subagent launched under `/workspace`) contained `Contents of /workspace/AGENTS.md (project instructions, checked into the codebase)`, followed by one `Contents of /workspace/workflows/<name>.md (project instructions, …)` block for each of the nine imported workflows, in AGENTS.md's list order (quoted from the harness-supplied context, not a repo file). That is direct observation of load plus inline expansion. It is one session on one harness version, hence Medium. An orchestrator that needs in-repo proof should treat this as Unverifiable-from-repo.

**Evidence:** `docs/decisions/log.md:88`, `test/agents-gemini-sync.bats:30-36`, reviewer session context (harness-supplied, not a repo path)

---

## Claim 6a: "the nine `@./workflows/*.md` entries put ~358 KB … of workflow text"

**Location:** `docs/decisions/log.md:88` (also commit 5ee8315 message)
**Type:** Configuration
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte size at `main` of the nine files AGENTS.md imported; does not include recursive imports inside those files (a regex scan found no import-shaped `@` in them; the only `@` hit was `@pytest.mark.integration` in prose) or the size of AGENTS.md itself.

Command (cwd `/workspace/.claude/wt-agents-md`, 2026-09-29T00:00:11-07:00): for each `@./workflows/*.md` in `git show main:AGENTS.md`, run `git show main:<file> | wc -c`. There are 9 entries: research-plan-implement 68,867; divergent-design 80,340; parallel-worktrees 7,596; task-decomposition 21,556; pr-prep 44,652; spike 24,471; branch-strategy 25,541; user-testing-workflow 30,395; codebase-onboarding 54,996. python3 gives a total of 358,414 bytes, which is 358.4 KB (decimal) or 350.0 KiB. "~358 KB" is exact in decimal units.

**Evidence:** `$S/sizes.log`

---

## Claim 6b: "(~85K tokens)"

**Location:** `docs/decisions/log.md:88` (also `test/agents-gemini-sync.bats:32` and commit 5ee8315 message)
**Type:** Configuration
**Verdict:** Unverifiable
**Legibility target:** for-orchestrator-synthesis
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the arithmetic ratio behind the figure only; does not establish the actual token count, which needs the model's tokenizer.

358,414 / 85,000 = 4.22 bytes per token, and the common bytes/4 heuristic gives 89,604 tokens (python3; `$S/sizes.log` holds the byte counts). Both land in the 85-90K range, so the figure is plausible for English markdown. No tokenizer or token-counting endpoint is available in the sandbox (no egress), so the exact count cannot be confirmed. To verify, run the nine files through the Anthropic token-counting API.

**Evidence:** `$S/sizes.log`

---

## Claim 7: "`hooks/log-usage.sh` cannot see `@` loads, so workflow use went unmeasured"

**Location:** `docs/decisions/log.md:88` (also "invisible to the usage hook", `test/agents-gemini-sync.bats:33`)
**Type:** Architectural
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `hooks/log-usage.sh`, its PreToolUse wiring and the sibling PostToolUse `log-usage-post.sh` matcher; does not establish that no other hook in the repo observes instruction loading.

The hook's own coverage comment says so:

```bash
# hooks/log-usage.sh:7-10
# COVERAGE: only Skill, Read and Agent tool calls are seen. A workflow or skill
# read through Bash (`cat`), an `@` import, or text inlined into a subagent
# brief produces no event, and nothing fires in sessions without the wiring.
```

The code matches the comment: the `case "$TOOL_NAME" in` block handles only `Skill)`, `Read)` and `Agent)` (hooks/log-usage.sh:51-88), and `hooks/lib/usage-common.sh:28-31` exits 0 for anything else (`*) exit 0 ;;`). The wiring is `"matcher": "Skill|Read|Agent"` for both log-usage.sh and log-usage-post.sh (hooks/wiring.json:86, :115). An `@` import is expanded by the harness, not by a tool call, so none of these fire.

**Evidence:** `hooks/log-usage.sh:7-10`, `hooks/log-usage.sh:51-88`, `hooks/lib/usage-common.sh:24-31`, `hooks/wiring.json:85-92`, `hooks/wiring.json:114-121`

---

## Claim 8: "Bare names cost nothing and are what GEMINI.md already used"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers GEMINI.md's naming at main and that bare bold names contain no import syntax; does not establish how any non-Claude agent resolves a bare filename.

GEMINI.md is byte-identical between main and HEAD (Claim 1), and its body now equals AGENTS.md's bare-name list, e.g. `- **research-plan-implement.md** — The default development loop.` (GEMINI.md, identical to AGENTS.md:9). The guard regex (Claim 2) does not match these lines: `grep -nE` on the new AGENTS.md exited 1 (`$S/regex.log`).

**Evidence:** `GEMINI.md:9-17`, `AGENTS.md:9-17`, `$S/gemini-diff.log`, `$S/regex.log`

---

## Claim 9: "AGENTS.md:  **research-plan-implement.md** (legacy form: **@./workflows/…**)"

**Location:** `scripts/health-check.sh:206`
**Type:** Behavioral
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `extract_workflows` on the new AGENTS.md, the main-branch AGENTS.md and GEMINI.md; does not establish handling of other `@` spellings (e.g. `@workflows/x.md` without `./` is not stripped).

```bash
# scripts/health-check.sh:208-216
extract_workflows() {
    local file="$1"
    ...
    { grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$file" || true; } \
        | sed 's/\*\*//g; s/`//g; s|@\./workflows/||' \
        | sort -u
}
```
(excerpt elides the comment at :210-213; function ends :216 — read)

The optional `(@\./workflows/)?` group and the matching `sed` strip handle both forms. I sourced the function and ran it (cwd `/workspace/.claude/wt-agents-md`, 2026-09-29T00:01:21-07:00). The new AGENTS.md, `git show main:AGENTS.md` and GEMINI.md each produced the same 9 names, and `diff` of the new and old outputs exited 0 (`$S/extract.log`).

**Evidence:** `scripts/health-check.sh:203-216`, `$S/extract.log`

---

## Claim 10: "Handles three syntaxes: CLAUDE.md: **research-plan-implement.md** … GEMINI.md: **research-plan-implement.md**"

**Location:** `scripts/health-check.sh:204-207`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility target:** for-author
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header's enumeration against the regex and the function's own inner comment; does not establish anything about the AGENTS.md line itself (Claim 9).

After this edit the three listed lines show one syntax (bold bare name) three times plus a parenthetical legacy form. The CLAUDE.md example is also wrong about the delimiter. The function's own comment says `CLAUDE.md uses backticks for all filenames` (scripts/health-check.sh:210-211), and `global-instructions/CLAUDE.md:24` indeed has `` `research-plan-implement.md` ``. What the regex actually accepts is `**name.md**`, `` `name.md` `` and `**@./workflows/name.md**` (health-check.sh:214). The CLAUDE.md line predates this branch (unchanged context in the hunk). The branch edit makes the "three syntaxes" count harder to map, since two of the three listed lines are now identical. A precise header would list: bold (AGENTS.md, GEMINI.md), backticks (global CLAUDE.md), legacy `**@./workflows/…**`.

**Evidence:** `scripts/health-check.sh:204-214`, `global-instructions/CLAUDE.md:24`

---

## Claim 11: "Strips the first 3 lines (tool-specific headers) from each file, then diffs."

**Location:** `test/agents-gemini-sync.bats:4`
**Type:** Behavioral
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sync test body; does not establish detection of trailing-newline-only differences, which `$(…)` command substitution strips from both sides before the diff.

```bash
# test/agents-gemini-sync.bats:19-27
  local agents_body gemini_body
  agents_body=$(tail -n +4 "$AGENTS")
  gemini_body=$(tail -n +4 "$GEMINI")

  if ! diff_output=$(diff <(echo "$agents_body") <(echo "$gemini_body")); then
    echo "AGENTS.md and GEMINI.md have drifted (after stripping headers):"
    echo "$diff_output"
    return 1
  fi
```

`tail -n +4` starts at line 4, so it drops lines 1-3. No `sed` prefix strip remains. Running `LC_ALL=C timeout 60 bats test/agents-gemini-sync.bats` (cwd worktree, 2026-09-29T00:01:00-07:00) gave `ok 1` and `ok 2`, exit 0.

**Evidence:** `test/agents-gemini-sync.bats:15-28`, `$S/bats-head.log`

---

## Claim 12: "`extract_workflows` callers (check_workflow_crossrefs, check_md_consistency) still pass on the new AGENTS.md"

**Location:** `scripts/health-check.sh:219-290`
**Type:** Behavioral
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two checks as run by the full gate on this commit; does not establish behaviour if AGENTS.md later adds `@` forms the regex does not strip.

`check_workflow_crossrefs` tests `[[ ! -f "$REPO_ROOT/workflows/$wf" ]]` for each extracted name (health-check.sh:233-236). `check_md_consistency` compares the `workflow_sets` strings across the three files (health-check.sh:261-270). Full gate: `LC_ALL=C timeout 590 scripts/health-check.sh` (cwd worktree, started 2026-09-29T00:01:3x, ended 00:13:02-07:00, exit 0). It printed `✓ AGENTS.md: all workflow references resolve` and `✓ All MD files reference the same workflows`.

**Evidence:** `scripts/health-check.sh:219-290`, `$S/health-full.log:34-40`

---

## Claim 13: "agents-gemini-sync.bats … gains a guard that fails on any @-import in AGENTS.md (verified to fail on the previous AGENTS.md)"

**Location:** commit 5ee8315 message
**Type:** Behavioral
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parenthetical (the guard fails on main's AGENTS.md); the "any @-import" part carries Claim 2's Incorrect verdict and is not re-verdicted here.

I built a temp tree with the branch's test file, `git show main:AGENTS.md` and the current GEMINI.md, then ran `LC_ALL=C timeout 60 bats test/agents-gemini-sync.bats` (cwd `$S/oldtree`, 2026-09-29T00:01:09-07:00). Output: `not ok 2 AGENTS.md has no @-imports`, listing lines 9-15 and more of the old file. Test 1 also failed, as expected, because the prefix strip is gone.

**Evidence:** `test/agents-gemini-sync.bats:34-40`, `$S/bats-oldagents.log`

---

## Claim 14: "Verified: scripts/health-check.sh, \"All checks passed.\""

**Location:** commit 5ee8315 message
**Type:** Behavioral
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full gate, including fast and slow BATS, re-run on 5ee8315; does not establish the 4 report-dependent BATS suites, which the gate itself reports as NOT RUN.

`LC_ALL=C timeout 590 scripts/health-check.sh` (cwd worktree, exit 0, ended 2026-09-29T00:13:02-07:00) printed `✓ Fast BATS suites passed (excluding 4 report-dependent suite(s) not run)`, `✓ Slow BATS suites passed`, a warning `⚠ 4 report-dependent BATS suite(s) NOT RUN`, and the final line `All checks passed.`

**Evidence:** `$S/health-full.log:1378`, `$S/health-full.log:1680-1681`

---

## Claim 15: "kept the sections AGENTS.md shares with the global instructions (~40 lines)"

**Location:** commit 5ee8315 message
**Type:** Configuration
**Verdict:** Verified
**Legibility target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count of the three shared sections in AGENTS.md; does not establish their equality with the global file's text.

The shared sections run from `41:## Context Packing` to the end of the file, and `wc -l AGENTS.md` gives 76. That is 36 lines, which fits "~40".

**Evidence:** `AGENTS.md:41-76`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`docs/decisions/log.md:88`): the guard does not fail on "any" `@path` import. Its regex only matches `@/`, `@./` and `@../` after line start, whitespace, `*` or a backtick. It misses `@x.md`, `@docs/x.md`, `@~/x.md`, and `@./x` right after `(`, `"` or `[`. Either narrow the row's wording to the `@/`, `@./`, `@../` family, or widen the regex.

### Stale
- None.

### Mostly Accurate
- **Claim 10** (`scripts/health-check.sh:204-207`): the "three syntaxes" header now lists the bold form three times, and its CLAUDE.md example is wrong. Global CLAUDE.md uses backticks, as the function's own comment at :210-211 says. List the three forms as bold, backtick and legacy `**@./workflows/…**`.

### Unverifiable
- **Claim 6b** (`docs/decisions/log.md:88`, `test/agents-gemini-sync.bats:32`): "~85K tokens" implies 4.22 bytes per token over 358,414 bytes. That is plausible, but confirming it needs a tokenizer or token-counting API, and the sandbox has none.

---

## Goal-Alignment Note
- **Answered:** Every brief item was checked. Size and arithmetic: Claims 6a and 6b. GEMINI byte-identity: Claim 1. log-usage coverage: Claim 7. The harness claim, with what the repo can and cannot establish: Claim 5. Regex coverage and false positives, by execution: Claim 2. `extract_workflows` and its callers: Claims 9, 10 and 12. The sync-test header: Claim 11. Shared headings: Claim 3. Also covered: the commit message's "verified to fail", "All checks passed" and "~40 lines" claims (Claims 13-15), all executed or read.
- **Out of scope:** No code-quality or refactor advice. Claude Code's exact import grammar is outside the repo and could not be fetched (no egress), which is why Claim 2 has Medium confidence.
- **Escalate:** Claim 2 (Incorrect wording in log row 65 about the guard's coverage) is the one author-facing fix. Claim 5 is Verified only from harness-observed session context. If the orchestrator needs in-repo proof, it should read that claim as Unverifiable-from-repo.
