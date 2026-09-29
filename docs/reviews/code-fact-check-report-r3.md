Commit: 5ee8315

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-agents-md`, branch `fix/agents-md-no-imports`)
**Scope:** branch diff `git diff main...HEAD`: `AGENTS.md`, `docs/decisions/log.md`, `scripts/health-check.sh`, `test/agents-gemini-sync.bats`, plus commit message of 5ee8315 (replicate r3 of 3)
**Checked:** 2026-09-29
**Total claims checked:** 15
**Summary:** 9 verified, 2 mostly accurate, 1 stale, 2 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 patterns). The closest family is "numeric tally in a commit message does not match the artifact" (entries at `:28`, `:30`); Claims 5b and 11b are compared against it below. No claim matches a logged fabrication.

Execution logs for this run live under `docs/reviews/execution-logs/fc-r3-*.txt`. All runs used cwd `/workspace/.claude/wt-agents-md`, and each file starts with its ISO timestamp.

---

## Claim 1: "Its workflow list now matches GEMINI.md byte for byte below the header"

**Location:** `docs/decisions/log.md:88`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `tail -n +4` of AGENTS.md and GEMINI.md are byte-identical at HEAD (so the workflow list is too); does not establish that the 3-line headers match (they differ on purpose) or that the two files stay in sync after later edits, which the sync test guards.

Command: `diff <(tail -n +4 AGENTS.md) <(tail -n +4 GEMINI.md)`, run 2026-09-29T00:00:13-07:00, exit 0, no output. The whole body below line 3 is identical, not just the workflow list. The headers differ only at line 3 (`AGENTS.md:3` "It is tool-agnostic and works with any agent that reads AGENTS.md…" vs `GEMINI.md:3` "This file provides workflow instructions for Antigravity and Gemini CLI…"). The sync test's first case also passes at HEAD (Claim 13 log).

**Evidence:** `AGENTS.md:4-76`, `GEMINI.md:4-76`, `docs/reviews/execution-logs/fc-r3-sync.txt`

---

## Claim 2: "`test/agents-gemini-sync.bats` fails on any `@path` import in AGENTS.md"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers which import spellings the guard regex matches and misses, tested on `main:AGENTS.md` and 20 synthetic lines; does not establish Claude Code's exact import grammar, which is harness behavior defined outside this repo (the Medium confidence rests on that).

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

The regex requires `@` to be followed by `/`, `./` or `../`. Executed against `git show main:AGENTS.md` it matches all 9 old lines (lines 9-16 and 18), and nothing at HEAD. Executed against synthetic lines:

- **Matches:** `- **@./workflows/x.md**`, `@../x.md`, `see @../x.md here`, `@/abs/path.md`, `see @/abs/path.md`, `` `@./x.md` ``.
- **Misses:** `@x.md`, `see @x.md here`, `@workflows/x.md`, `@~/x.md`, `see @~/.claude/x.md`, `- **@README.md**`, and `(@./x.md)`, `"@./x.md"`, `[@./x.md]`. The last three miss because `(`, `"` and `[` are not in the leading character class.
- **No false positives** on `foo@bar.com`, `foo@./x` (no leading space), `a/@/b` or `@pytest.mark.integration`.

The repo's own examples do not define the import grammar: nothing in-repo documents it (paraphrased — no quote available because the claim covers absence of code: `rg` for `@~/`, `@README`, `@path` and `` `@` import `` outside archive/ found only this diff, `hooks/log-usage.sh:8` and `guides/subtraction-checklist.md:60`, none of which state the grammar). Claude Code's public memory documentation, which is outside the repo, gives bare-relative (`@README`, `@docs/…`) and home (`@~/.claude/…`) forms as imports (paraphrased — no quote available because the source is external harness documentation, not a file here). Under that grammar, an `@workflows/x.md` or `@README.md` added to AGENTS.md would pass the guard and still be expanded, so "any `@path` import" overstates it. A precise version: "fails on `@/`, `@./` and `@../` imports at line start or after whitespace, `*` or a backtick." A lesser note: the backtick in the class makes the guard fire on a documented example inside a code span (e.g. `` `@./x.md` ``). Claude Code does not expand imports inside code spans (external documentation, same caveat), so that would be a false positive.

**Evidence:** `test/agents-gemini-sync.bats:34-40`, `docs/reviews/execution-logs/fc-r3-regex.txt`

---

## Claim 3: "The sections AGENTS.md shares with the global instructions (Context Packing, Shared Thoughts, General Principles) stay"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that these three H2 headings exist in both AGENTS.md and `global-instructions/CLAUDE.md` and that the branch left them in AGENTS.md; does not establish that the section bodies are word-for-word identical across the two files.

`grep -n '^## '` gives `AGENTS.md:41` `## Context Packing`, `AGENTS.md:52` `## Shared Thoughts`, `AGENTS.md:65` `## General Principles`, and `global-instructions/CLAUDE.md:126` `## Context Packing`, `:153` `## Shared Thoughts`, `:303` `## General Principles`. The diff touches only `AGENTS.md:9-18` (paraphrased — no quote available because this is about which hunks the diff contains; see the single `@@ -6,16 +6,16 @@` hunk).

**Evidence:** `AGENTS.md:41`, `AGENTS.md:52`, `AGENTS.md:65`, `global-instructions/CLAUDE.md:126`, `global-instructions/CLAUDE.md:153`, `global-instructions/CLAUDE.md:303`

---

## Claim 4: "After row 47 moved the root CLAUDE.md out, Claude Code loads AGENTS.md as this repo's project instructions and expands `@` imports inline"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that row 47 moved the file out of the root and that, in this reviewer's own session in `/workspace` (on main, old AGENTS.md), the harness loaded AGENTS.md as project instructions plus all nine `@./workflows/*.md` targets; does not establish the behavior across Claude Code versions, whether AGENTS.md is loaded because no root CLAUDE.md exists or unconditionally, or recursive-import depth.

In-repo part: row 47 reads "**The global instructions file moves out of the repo root to `global-instructions/CLAUDE.md`.**" (`docs/decisions/log.md:70`), and `ls CLAUDE.md` at the worktree root fails with "No such file or directory". Nothing in the repo can establish harness loading behavior by itself (paraphrased — no quote available because the claim is about the Claude Code harness, which is not in this repo). Session evidence: this review agent's system context lists "Contents of /workspace/AGENTS.md (project instructions, checked into the codebase)". It is followed by "Contents of /workspace/workflows/<name>.md (project instructions…)" for exactly the nine files the old AGENTS.md imported: research-plan-implement, divergent-design, parallel-worktrees, task-decomposition, pr-prep, spike, branch-strategy, user-testing-workflow, codebase-onboarding (paraphrased — no quote available because the evidence is this agent's injected session context, not a repository file). That is a direct observation of the claimed load and expansion, but it is single-session and not reproducible from a repo command, hence Medium.

**Evidence:** `docs/decisions/log.md:70`, session context of this review agent (bare locator)

---

## Claim 5a: "the nine `@./workflows/*.md` entries put ~358 KB … of workflow text into every session"

**Location:** `docs/decisions/log.md:88`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count (9) and combined size (358,414 bytes) of the files `main:AGENTS.md` imported, measured at main; does not establish nested imports inside those files (a grep found none in `@/`, `@./` or `@../` form; the only other `@` is `@pytest.mark.integration` in prose at `workflows/codebase-onboarding.md:267`) or per-session variation.

`git show main:AGENTS.md | grep -c '@\./workflows'` gives 9. Per-file byte counts from `git show main:workflows/<f>.md | wc -c`: 68,867 + 80,340 + 7,596 + 21,556 + 44,652 + 24,471 + 25,541 + 30,395 + 54,996 = 358,414 bytes. That is 358.4 KB in decimal units (350.0 KiB). The commit message repeats the same figure.

**Evidence:** `docs/reviews/execution-logs/fc-r3-sizes.txt`

---

## Claim 5b: "(~85K tokens)"

**Location:** `docs/decisions/log.md:88`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the arithmetic from measured size to tokens under this repo's documented chars/4 convention; does not establish an actual tokenizer count, which would need the Claude token-counting API (not available in the sandbox).

The nine files hold 358,414 bytes and 355,598 characters (python3 over the concatenated `git show` output). The repo's stated estimate is "tokens ≈ chars/4" (`skills/code-review/SKILL.md:328`: "estimated as chars/4"; also `docs/decisions/log.md:55`). That gives about 88.9K tokens (89.6K from bytes/4), not ~85K. "~85K" implies about 4.18 chars per token: plausible for English markdown, but it is not the repo's convention and it runs about 4-5% low against it. Order of magnitude and conclusion are right. The precise version is "~89K tokens (chars/4)". The commit message and the test comment at `test/agents-gemini-sync.bats:32` repeat "~85K". This is a mild case of the logged "numeric claim in a commit message" family (`hallucination-patterns.md:28`, `:30`), but it is an estimate, not a fabricated count.

**Evidence:** `skills/code-review/SKILL.md:328`, `docs/decisions/log.md:55`, `docs/reviews/execution-logs/fc-r3-sizes.txt`

---

## Claim 6: "`hooks/log-usage.sh` cannot see `@` loads, so workflow use went unmeasured"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the pre- and post-tool hooks run only on Skill/Read/Agent tool calls and log workflows only on a Read of a `*/workflows/*` path; does not establish that no other telemetry anywhere records `@` loads.

The hook's own coverage note:

```bash
# hooks/log-usage.sh:7-10
# COVERAGE: only Skill, Read and Agent tool calls are seen. A workflow or skill
# read through Bash (`cat`), an `@` import, or text inlined into a subagent
# brief produces no event, and nothing fires in sessions without the wiring.
# Counts from this log are lower bounds; see Q-017 (questions-archive.md).
```

The wiring matcher is `"matcher": "Skill|Read|Agent"` for both `log-usage.sh` and `log-usage-post.sh` (`hooks/wiring.json:86-90`, `:116-120`). The gate in `hooks/lib/usage-common.sh:29-30` allows only `pre:Skill|pre:Read|pre:Agent` and `post:Skill|post:Agent`. A workflow event is emitted only on `Read` with `"$FILE_PATH" == */workflows/*` (`hooks/log-usage.sh:62-67`). An `@` import is not a tool call, so no hook fires for it (paraphrased — no quote available because this is a property of the harness's import mechanism, consistent with the hook comment above).

**Evidence:** `hooks/log-usage.sh:7-10`, `hooks/log-usage.sh:55-70`, `hooks/wiring.json:86-90`, `hooks/wiring.json:116-120`, `hooks/lib/usage-common.sh:15-30`

---

## Claim 7: "Bare names … are what GEMINI.md already used"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers GEMINI.md's workflow-list form on main (unchanged on this branch); does not establish that Gemini/Antigravity treat `@` specially.

`git show main:GEMINI.md` lines 9-10 read `- **research-plan-implement.md** — The default development…` and `- **divergent-design.md** — Structured brainstorming…`. `git diff main...HEAD --quiet -- GEMINI.md` reports the file unchanged, and `grep -n '@' GEMINI.md` finds nothing.

**Evidence:** `GEMINI.md:9-18`

---

## Claim 8: "Handles three syntaxes: … AGENTS.md: **research-plan-implement.md** (legacy form: **@./workflows/…**)"

**Location:** `scripts/health-check.sh:204-206`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `extract_workflows` returns the same 9 names for the new bare AGENTS.md and the legacy `@./workflows/` AGENTS.md, and that `check_workflow_crossrefs`, `check_md_consistency` and `check_md_semantic_divergence` pass at HEAD; does not establish the accuracy of the neighbouring CLAUDE.md example line (see Claim 9).

```bash
# scripts/health-check.sh:208-217
extract_workflows() {
    local file="$1"
    # Allow ** or ` as the delimiter. ...
    { grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$file" || true; } \
        | sed 's/\*\*//g; s/`//g; s|@\./workflows/||' \
        | sort -u
}
```

The optional `(@\./workflows/)?` group and the matching `sed` strip still handle the legacy form. Command (timeout 120): source `scripts/health-check.sh`, then call `extract_workflows` on HEAD `AGENTS.md`, on `main:AGENTS.md` (copied to scratch), on `GEMINI.md` and on `$GLOBAL_MD`, then the three check functions. Run at 2026-09-29T00:01:49-07:00, exit 0, `FAIL=0`. All four inputs gave the identical 9-name set. Output included "✓ AGENTS.md: all workflow references resolve", "✓ All MD files reference the same workflows" and "✓ AGENTS.md and GEMINI.md have identical section structure". A full `HEALTH_CHECK_SKIP_BATS=1 scripts/health-check.sh` also ended "All checks passed." (Claim 14).

**Evidence:** `scripts/health-check.sh:203-296`, `docs/reviews/execution-logs/fc-r3-healthcheck-sections.txt`

---

## Claim 9: "CLAUDE.md:  **research-plan-implement.md**" (as one of the "three syntaxes")

**Location:** `scripts/health-check.sh:205`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the example syntax the header gives for the CLAUDE.md input against the file the check now reads; does not establish any functional defect, since the regex accepts both delimiters. The line predates this branch (blame 79cab0ea, 2026-03-23) and sits next to the changed line.

The function's own inline comment contradicts the header: "CLAUDE.md uses backticks for all filenames (so the result is filtered against workflows/ in the caller); AGENTS.md and GEMINI.md use bold." (`scripts/health-check.sh:210-212`). `rg -c '\*\*[a-z-]+\.md\*\*' global-instructions/CLAUDE.md` finds 0 bold filenames, and the workflow names there appear as `` `research-plan-implement.md` `` etc. After this branch, the header's "three syntaxes" shows bold three times plus a legacy parenthetical. The three forms the regex actually handles are bold, backtick and `@./workflows/`-prefixed. The precise version is `CLAUDE.md:  `research-plan-implement.md``.

**Evidence:** `scripts/health-check.sh:204-212`, `global-instructions/CLAUDE.md:24`

---

## Claim 10: "Strips the first 3 lines (tool-specific headers) from each file, then diffs."

**Location:** `test/agents-gemini-sync.bats:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first test case's transformation and comparison; does not establish anything about the second (@-import) case, which the header comment does not describe.

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

`tail -n +4` drops lines 1-3. The old `sed 's|@\./workflows/||g'` strip is gone, so the comment no longer mentions it. The test passes at HEAD and fails against `main:AGENTS.md` with the `@./workflows/` lines shown as drift (Claim 13 log).

**Evidence:** `test/agents-gemini-sync.bats:15-28`, `docs/reviews/execution-logs/fc-r3-bats.txt`

---

## Claim 11a: "Claude Code loads AGENTS.md as this repo's project instructions (the root CLAUDE.md moved to global-instructions/, decision log row 47) and expands `@path` imports inline. … invisible to the usage hook."

**Location:** `test/agents-gemini-sync.bats:30-33`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same basis and residue as Claims 4 and 6 (row 47 at `docs/decisions/log.md:70`; session-context observation; hook matcher `Skill|Read|Agent`); does not establish version-independence of the harness behavior.

The comment reads "`# Claude Code loads AGENTS.md as this repo's project instructions (the root`" / "`# CLAUDE.md moved to global-instructions/, decision log row 47) and expands`" / "`# `@path` imports inline.`" (`test/agents-gemini-sync.bats:30-32`). The row reference and mechanism match Claim 4's evidence. "invisible to the usage hook" matches the hook's coverage note quoted in Claim 6 (`hooks/log-usage.sh:7-8`).

**Evidence:** `test/agents-gemini-sync.bats:30-33`, `docs/decisions/log.md:70`, `hooks/log-usage.sh:7-10`

---

## Claim 11b: "The old `@./workflows/*.md` list pulled ~85K tokens of workflow text into every session here"

**Location:** `test/agents-gemini-sync.bats:32-33`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Same measurement as Claim 5b; does not establish an actual tokenizer count.

358,414 bytes / 355,598 chars, so ~88.9K tokens under the repo's chars/4 convention (`skills/code-review/SKILL.md:328`). "~85K" is about 4-5% low; "~89K" is the precise figure.

**Evidence:** `docs/reviews/execution-logs/fc-r3-sizes.txt`, `skills/code-review/SKILL.md:328`

---

## Claim 12: test name "AGENTS.md has no @-imports" and failure text "AGENTS.md contains @-imports, which Claude Code expands into every session"

**Location:** `test/agents-gemini-sync.bats:34-36`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what the test's pass asserts, from the regex executed in Claim 2; does not establish the harness import grammar (external).

A passing test is named as a guarantee that AGENTS.md has no `@`-imports. The regex it runs, `grep -nE '(^|[[:space:]*`])@\.{0,2}/' "$AGENTS"` (`test/agents-gemini-sync.bats:35`), passes on `@README.md`, `@workflows/x.md`, `@~/x.md` and `(@./x.md)` (executed, Claim 2). So a green test does not establish the property its name states for bare-relative or home-relative imports. This is the same gap as Claim 2, recorded at the test's own location.

**Evidence:** `test/agents-gemini-sync.bats:34-40`, `docs/reviews/execution-logs/fc-r3-regex.txt`

---

## Claim 13: "a guard that fails on any @-import in AGENTS.md (verified to fail on the previous AGENTS.md)"

**Location:** commit 5ee8315 message (bare locator)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parenthetical, that the guard fails on `main:AGENTS.md`; the "any @-import" part is Claim 2's finding (Incorrect) and is not re-verdicted here.

Command: `timeout 120 bats test/agents-gemini-sync.bats` at HEAD gave `ok 1`, `ok 2`, exit 0. The same test file run from a scratch copy with `main:AGENTS.md` and HEAD `GEMINI.md` gave `not ok 1` (drift on lines 6-13 and 15) and `not ok 2`, listing lines 9-16 and 18. Exit 1, run 2026-09-29T00:02:07-07:00. The scratch copy was removed afterwards.

**Evidence:** `test/agents-gemini-sync.bats:34-40`, `docs/reviews/execution-logs/fc-r3-bats.txt`

---

## Claim 14: "Verified: scripts/health-check.sh, \"All checks passed.\""

**Location:** commit 5ee8315 message (bare locator)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers every health-check section except check 5 (the full bats suite), which passed with `HEALTH_CHECK_SKIP_BATS=1`, plus the one bats file this branch changed; does not establish that the full fast+slow bats suite passes at 5ee8315.

Command: `HEALTH_CHECK_SKIP_BATS=1 timeout 300 scripts/health-check.sh`, cwd worktree, run 2026-09-29, exit 0, final line "All checks passed." (warnings only in soft checks such as doc freshness). Check 5 was deliberately skipped. It runs the whole fast and slow suite, and pr-prep step 5a requires quiescing first because install tests read the shared process table. Two sibling replicate reviewers were running concurrently under the same uid, so a full run here could produce environmental failures. This is the named blocker for the full claim. `test/agents-gemini-sync.bats` itself passes (Claim 13).

**Evidence:** `scripts/health-check.sh:20-24`, `docs/reviews/execution-logs/fc-r3-healthcheck-skipbats.txt`, `docs/reviews/execution-logs/fc-r3-bats.txt`

---

## Claim 15: "kept the sections AGENTS.md shares with the global instructions (~40 lines)"

**Location:** commit 5ee8315 message, Notes line (bare locator)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count of the three shared sections in AGENTS.md; does not establish overlap in content with the global file beyond the headings (Claim 3).

The three sections run from `AGENTS.md:41` (`## Context Packing`) to end of file at `:76`, which is 36 lines, so "~40" (awk count from the heading to EOF).

**Evidence:** `AGENTS.md:41-76`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`docs/decisions/log.md:88`): "fails on any `@path` import" is too broad. The regex catches only `@/`, `@./`, `@../` after start, whitespace, `*` or a backtick, and misses `@README.md`, `@workflows/x.md`, `@~/x.md` and `(@./x.md)`. Either narrow the wording or widen the regex. [for-author]
- **Claim 12** (`test/agents-gemini-sync.bats:34-36`): the test name "has no @-imports" states a guarantee the regex does not give for bare-relative or home imports (same gap as Claim 2). [for-author]

### Stale
- **Claim 9** (`scripts/health-check.sh:205`): the CLAUDE.md example shows bold, but `global-instructions/CLAUDE.md` uses backticks (the function's own comment at `:210` says so). The real three syntaxes are bold, backtick and `@./workflows/`. This line predates the branch. [for-author]

### Mostly Accurate
- **Claim 5b** (`docs/decisions/log.md:88`, also the commit message): "~85K tokens". Under the repo's chars/4 convention, 355,598 chars comes to ~89K. [for-author]
- **Claim 11b** (`test/agents-gemini-sync.bats:32`): same "~85K", should be ~89K. [for-author]

### Unverifiable
- **Claim 14** (commit message): "All checks passed". Every section except the full bats suite passed with `HEALTH_CHECK_SKIP_BATS=1`. Confirming the full suite needs a quiesced run of check 5 (no concurrent reviewers). [for-orchestrator-synthesis]

Verified claims 1, 3, 4, 5a, 6, 7, 8, 10, 11a, 13, 15: [for-orchestrator-synthesis]. Claims 4 and 11a are Verified at Medium on session-context evidence of the harness behavior, not on in-repo evidence.

No Incorrect verdict here is a fabricated symbol, API or behavior (both are coverage overstatements), so `docs/reviews/hallucination-patterns.md` is unchanged.

---

## Goal-Alignment Note

- **Answered:** All eight claims the brief flagged. Size and token arithmetic: 358,414 B is right; ~85K tokens is ~4-5% low against chars/4. Byte-for-byte sync verified. log-usage blindness verified. Harness claim verified via this agent's session context, which is not reproducible in-repo. Regex executed on the old file and 20 synthetic forms: it misses bare-relative, `~/` and bracketed or quoted forms; no email false positive; one code-span false positive. extract_workflows handles both forms and its callers pass. The sync header comment matches the code. The shared headings exist in both files.
- **Out of scope:** The full bats suite (health-check check 5) was not run, because concurrent sibling replicates share the uid and process table. Claude Code's import grammar comes from external documentation and was not confirmed in-repo.
- **Escalate:** Claim 2/12 (the guard's "any @-import" overclaim) is the only blocking-grade finding. Decide whether to narrow the wording or widen the regex (e.g. `(^|[^[:alnum:]_.])@[~./[:alnum:]]`, noting the code-span false-positive trade-off).
