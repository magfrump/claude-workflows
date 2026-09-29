Commit: 5ee8315

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-agents-md`, branch `fix/agents-md-no-imports`)
**Scope:** branch diff `git diff main...HEAD` (4 files: `AGENTS.md`, `docs/decisions/log.md`, `scripts/health-check.sh`, `test/agents-gemini-sync.bats`) plus the commit message of 5ee8315
**Checked:** 2026-09-29
**Total claims checked:** 18 (16 numbered claims; 5 and 7 split into a/b)
**Summary:** 11 verified, 1 mostly accurate, 0 stale, 1 incorrect, 5 unverifiable

Replicate r1 of 3. Execution logs for every `executed` claim are under `docs/reviews/execution-logs/fc-r1/` (untracked). The hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read first; no claim matches a logged pattern, though Claim 7b is the same class as the logged "specific measured value" entries and is flagged there as a watch item, not a match. Sub-claims 5a/5b and 7a/7b are split because their parts earn different verdicts.

---

## Claim 1: "AGENTS.md names workflows by bare filename, never by `@` import."

**Location:** `docs/decisions/log.md:88`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the AGENTS.md file at HEAD (no line matches the guard regex, and `extract_workflows` finds the same nine bare names as GEMINI.md); does not establish the absence of import forms the guard regex cannot see (see Claim 3), though a manual read of the 76-line file shows none.

The new list lines have the form:

```
// AGENTS.md:9
- **research-plan-implement.md** — The default development loop. ...
```

Running the test's regex against HEAD's AGENTS.md produced no match (`grep exit=1`, `regex.txt`), and `extract_workflows` returned the nine filenames `branch-strategy.md … user-testing-workflow.md` (`extract.txt`). A manual read of `AGENTS.md:1-76` found no `@` token of any form (paraphrased — no quote available because the claim covers absence of text in the file).

Execution provenance: `timeout 30 bash scratchpad/regex.sh <old-AGENTS.md>` and `timeout 30 bash scratchpad/extract.sh <old-AGENTS.md>`, cwd `/workspace/.claude/wt-agents-md`, exit 0 each, 2026-09-29T07:01:09Z.

**Evidence:** `AGENTS.md:9-18`, `docs/reviews/execution-logs/fc-r1/regex.txt`, `docs/reviews/execution-logs/fc-r1/extract.txt`

---

## Claim 2: "Its workflow list now matches GEMINI.md byte for byte below the header" (also commit: "AGENTS.md uses bare filenames, matching GEMINI.md below the header")

**Location:** `docs/decisions/log.md:88`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers everything from line 4 to the end of both files at HEAD (a stronger property than the workflow list alone); does not establish that the 3-line headers match (they deliberately differ: `AGENTS.md:3` names Copilot/Cursor/Cline, `GEMINI.md:3` names Antigravity/Gemini CLI).

`diff <(tail -n +4 AGENTS.md) <(tail -n +4 GEMINI.md)` exited 0 with no output (`sync-diff.txt`, cwd `/workspace/.claude/wt-agents-md`, 2026-09-29T07:00:14Z). GEMINI.md is unchanged on the branch (`git diff --quiet main HEAD -- GEMINI.md` succeeded), so the match comes entirely from the AGENTS.md edit. The bats sync test also passes: `ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)` (`bats.txt`).

**Evidence:** `AGENTS.md:4-76`, `GEMINI.md:4-76`, `docs/reviews/execution-logs/fc-r1/sync-diff.txt`, `docs/reviews/execution-logs/fc-r1/bats.txt`

---

## Claim 3: "`test/agents-gemini-sync.bats` fails on any `@path` import in AGENTS.md."

**Location:** `docs/decisions/log.md:88` (the guard it describes is `test/agents-gemini-sync.bats:33-39`, test name "AGENTS.md has no @-imports")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the regex's behaviour on the old AGENTS.md and on 16 synthetic lines; does not establish Claude Code's exact import grammar, which is not documented anywhere in this repo (the forms counted as imports below are taken from Claude Code's memory documentation — `@README`, `@docs/…`, `@~/.claude/…` — which could not be fetched here because the sandbox has no egress; confidence is Medium for that reason).

The guard is:

```bash
# test/agents-gemini-sync.bats:34
  if matches=$(grep -nE '(^|[[:space:]*`])@\.{0,2}/' "$AGENTS"); then
```

(excerpt ends :34; enclosing test continues to :39 — read: on a match it prints the lines and `return 1`; otherwise the test passes.)

The regex requires `@` to be followed by `/`, `./` or `../`, and to be preceded by start-of-line, whitespace, `*` or a backtick. Executed against synthetic lines (`regex.txt`):

- MATCH: `- **@./workflows/x.md**`, `@./workflows/x.md`, `see @../x.md here`, `@/abs/path.md`, `` `@./x.md` ``
- miss: `@x.md`, `see @x.md here`, `@workflows/x.md`, `@~/x.md`, `see @~/.claude/x.md`, `(@./x.md)`, `"@./x.md"`, `[@./x.md]`

So the guard catches every line the old AGENTS.md actually had (9 of 9 matched, Claim 15) and the `@../` and `@/abs` forms, but misses bare relative imports (`@docs/x.md`, `@README`), home-relative imports (`@~/…`), and any `@./` preceded by `(`, `"` or `[`. "Fails on any `@path` import" overstates it; the precise statement is "fails on `@/`, `@./` and `@../` imports that begin a line or follow whitespace, `*` or a backtick".

False positives: `contact magfrump@gmail.com`, `user@./weird` and `foo@/bar` did not match, so email-style prose is safe (the preceding-character class excludes letters). The regex does match `@./x` inside a backtick code span, which Claude Code's documentation says is not expanded (paraphrased — no quote available because this is external harness documentation, not repo code); that is a possible false positive if AGENTS.md ever documents the syntax.

Execution provenance: `timeout 30 bash scratchpad/regex.sh <old-AGENTS.md>`, cwd `/workspace/.claude/wt-agents-md`, exit 0, 2026-09-29T07:01:09Z.

**Evidence:** `test/agents-gemini-sync.bats:33-39`, `docs/reviews/execution-logs/fc-r1/regex.txt`

---

## Claim 4: "The sections AGENTS.md shares with the global instructions (Context Packing, Shared Thoughts, General Principles) stay"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of the three H2 headings in both files at HEAD and that the diff does not touch them; does not establish that the section bodies are identical between the two files (they are not claimed to be, and the global versions are longer).

```
// AGENTS.md:41, :52, :65
## Context Packing
## Shared Thoughts
## General Principles
// global-instructions/CLAUDE.md:126, :153, :303
## Context Packing
## Shared Thoughts
## General Principles
```

The branch diff changes only `AGENTS.md:9-18` (paraphrased — no quote available because this is about which hunks the diff contains, from `git diff main...HEAD`). The commit's "(~40 lines)" is an approximation of `AGENTS.md:41-76`, which is 36 lines (paraphrased — no quote available because this is a line count, `wc -l AGENTS.md` = 76).

**Evidence:** `AGENTS.md:41`, `AGENTS.md:52`, `AGENTS.md:65`, `global-instructions/CLAUDE.md:126`, `global-instructions/CLAUDE.md:153`, `global-instructions/CLAUDE.md:303`

---

## Claim 5a: "Claude Code loads AGENTS.md as this repo's project instructions and expands `@` imports inline"

**Location:** `docs/decisions/log.md:88` (repeated at `test/agents-gemini-sync.bats:28-29` and in the commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the harness behaviour observed in this review session only, with the main checkout's (pre-branch) AGENTS.md; does not establish it from anything in the repo (no repo file documents Claude Code's instruction loading), nor for other Claude Code versions or configurations.

Nothing inside the repository can establish this: it is a property of the Claude Code harness (paraphrased — no quote available because the claim covers harness behaviour outside the codebase). It is, however, directly observable in the context this review agent received: the harness injected "Contents of /workspace/AGENTS.md (project instructions, checked into the codebase)" followed by the full contents of all nine files the old AGENTS.md imported — `workflows/research-plan-implement.md`, `divergent-design.md`, `parallel-worktrees.md`, `task-decomposition.md`, `pr-prep.md`, `spike.md`, `branch-strategy.md`, `user-testing-workflow.md`, `codebase-onboarding.md` — each labelled "(project instructions, checked into the codebase)" (paraphrased — no quote available because the evidence is this session's system context, not a file). That is the load-and-expand behaviour the claim describes.

**Evidence:** `AGENTS.md` (main, via `git show main:AGENTS.md`), this session's injected project-instructions context

---

## Claim 5b: "After row 47 moved the root CLAUDE.md out, Claude Code loads AGENTS.md …" (causal link to log row 47)

**Location:** `docs/decisions/log.md:88` (also `test/agents-gemini-sync.bats:28-29`, commit message "Since decision log row 47 moved the root CLAUDE.md into global-instructions/")
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers that row 47 exists and records the move, and that no root CLAUDE.md exists now; does not establish that the move is what caused Claude Code to start loading AGENTS.md (it may have loaded AGENTS.md before as well).

Row 47 records the move:

```
// docs/decisions/log.md:70
| 47 | 2026-09-11 | **The global instructions file moves out of the repo root to `global-instructions/CLAUDE.md`.** ...
```

and `ls CLAUDE.md` at the worktree root fails ("No such file or directory"). Whether Claude Code loads AGENTS.md only when no root CLAUDE.md exists is a harness rule not recorded in the repo (paraphrased — no quote available because the claim covers absence of any such documentation). Row 47's own rationale counts ~8K tokens of duplication and does not mention AGENTS.md workflow expansion, which is consistent with, but does not prove, AGENTS.md not being loaded before. Verifying needs Claude Code's instruction-file precedence rules or a session run with a root CLAUDE.md present.

**Evidence:** `docs/decisions/log.md:70`

---

## Claim 6: "the nine `@./workflows/*.md` entries"

**Location:** `docs/decisions/log.md:88` (also commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of `@./workflows/` references in main's AGENTS.md; does not establish that no other `@` import form existed there (none did, per the regex count equalling the entry count and the diff showing only these lines changed).

`git show main:AGENTS.md | grep -c '@\./workflows/'` printed `9`, and the list in `sizes.txt` names nine distinct files. The diff removes exactly these nine lines (eight at `AGENTS.md:9-16`, one at `:18`).

**Evidence:** `AGENTS.md:9-18` (main), `docs/reviews/execution-logs/fc-r1/sizes.txt`

---

## Claim 7a: "put ~358 KB … of workflow text into every session here"

**Location:** `docs/decisions/log.md:88` (also commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the raw byte size of the nine workflow files at main (decimal KB); does not establish the exact size of what the harness injects (wrapper text, or whether it recurses into further imports — the workflow files contain no `@`-import-shaped strings, checked with the same regex plus `@~/`).

Per-file byte counts at main (`sizes.txt`): 68867 + 80340 + 7596 + 21556 + 44652 + 24471 + 25541 + 30395 + 54996 = 358,414 bytes = 358.4 KB (350.0 KiB). The workflow files are unchanged main..HEAD. Character count is 355,598 (`chars.txt`).

Execution provenance: `git show main:workflows/<f>.md | wc -c` per file, cwd `/workspace/.claude/wt-agents-md`, exit 0, 2026-09-29T07:00:14Z; sum via awk.

**Evidence:** `docs/reviews/execution-logs/fc-r1/sizes.txt`, `docs/reviews/execution-logs/fc-r1/chars.txt`

---

## Claim 7b: "(~85K tokens)"

**Location:** `docs/decisions/log.md:88` (also `test/agents-gemini-sync.bats:30`, commit message)
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the arithmetic relation between the verified byte/char counts and the token figure; does not establish the real token count, which needs the Claude tokenizer (not available in the sandbox, no egress to the token-counting API).

~85K tokens for 358,414 bytes / 355,598 characters implies 4.22 bytes or 4.18 characters per token (`chars.txt`: `4.216635294117647`). The common 4-bytes-per-token heuristic gives 89.6K. So "~85K" is in the right range but at the low end of the usual estimate; no repo artifact records how it was measured (paraphrased — no quote available because the claim covers absence of a measurement record). Verifying needs a `count_tokens` call over the nine files.

Execution provenance: `wc -c -m -w` over the concatenated files and `python3 -c "print(358414/85000, 358414/1024, 358414/4)"`, cwd `/workspace/.claude/wt-agents-md`, exit 0, 2026-09-29T07:02:46Z.

**Evidence:** `docs/reviews/execution-logs/fc-r1/chars.txt`

---

## Claim 8: "`hooks/log-usage.sh` cannot see `@` loads, so workflow use went unmeasured"

**Location:** `docs/decisions/log.md:88` (also `test/agents-gemini-sync.bats:31` "invisible to the usage hook", commit message)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hook's tool-name gate and its own coverage comment; does not establish that no workflow use was logged at all — explicit `Read` calls on workflow files are still logged, so "unmeasured" is accurate only for the content delivered by the `@` expansion.

The hook's coverage comment:

```bash
# hooks/log-usage.sh:7-10
# COVERAGE: only Skill, Read and Agent tool calls are seen. A workflow or skill
# read through Bash (`cat`), an `@` import, or text inlined into a subagent
# brief produces no event, and nothing fires in sessions without the wiring.
# Counts from this log are lower bounds; see Q-017 (questions-archive.md).
```

The code matches it: `hooks/lib/usage-common.sh:27-31` reads `TOOL_NAME` and exits 0 for anything not in its allowed case list (`*) exit 0 ;;`), and `hooks/log-usage.sh` handles only `Skill)`, `Read)` (logging a `workflow` event when the path contains `*/workflows/*`) and `Agent)` (paraphrased — no quote available because the case arms span `:51-91`). An `@` expansion is not a tool call, so no PreToolUse event fires for it.

**Evidence:** `hooks/log-usage.sh:7-10`, `hooks/log-usage.sh:51-91`, `hooks/lib/usage-common.sh:27-31`

---

## Claim 9: "Bare names cost nothing and are what GEMINI.md already used."

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that main's GEMINI.md used bare bold filenames; "cost nothing" is read narrowly as "trigger no import expansion", which follows from Claim 5a's observation that only `@` forms were expanded — it does not establish zero token cost of the list text itself.

```
// GEMINI.md:9 (main, unchanged on branch)
- **research-plan-implement.md** — The default development loop. ...
```

**Evidence:** `GEMINI.md:9-18`

---

## Claim 10: "Handles three syntaxes: CLAUDE.md: `**research-plan-implement.md**` … GEMINI.md: `**research-plan-implement.md**`"

**Location:** `scripts/health-check.sh:204-207`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment's syntax list against the regex in `extract_workflows`; does not cover the changed AGENTS.md line itself (Claim 11). The inaccurate row (`:205`, CLAUDE.md) is unchanged context, not part of this diff.

The regex does handle three syntaxes:

```bash
# scripts/health-check.sh:214-215
    { grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$file" || true; } \
        | sed 's/\*\*//g; s/`//g; s|@\./workflows/||' \
```

— bold bare, bold `@./workflows/`-prefixed, and backtick-delimited. But the example list now shows the same bold-bare form three times, and its CLAUDE.md row is wrong: the function's own inner comment says "CLAUDE.md uses backticks for all filenames" (`scripts/health-check.sh:210-211`), and the global file does use backticks (`global-instructions/CLAUDE.md:24`: `` `research-plan-implement.md` ``). The precise list is: `**name.md**` (AGENTS.md, GEMINI.md), `**@./workflows/name.md**` (legacy AGENTS.md), `` `name.md` `` (CLAUDE.md).

**Evidence:** `scripts/health-check.sh:203-217`, `global-instructions/CLAUDE.md:24`

---

## Claim 11: "AGENTS.md: `**research-plan-implement.md**` (legacy form: `**@./workflows/…**`)"

**Location:** `scripts/health-check.sh:206`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `extract_workflows` on HEAD's AGENTS.md, main's AGENTS.md, GEMINI.md and the global file, plus both callers on HEAD; does not establish handling of `@./workflows/` inside backticks beyond the regex reading (the regex permits it).

`extract_workflows` (sourced from the script and run directly) returned the identical nine names for HEAD's AGENTS.md (bare form), main's AGENTS.md (legacy form), GEMINI.md and `global-instructions/CLAUDE.md` (`extract.txt`). Both callers pass on HEAD: `scripts/health-check.sh` with `HEALTH_CHECK_SKIP_BATS=1` printed `✓ AGENTS.md: all workflow references resolve` (check_workflow_crossrefs) and `✓ All MD files reference the same workflows` (check_md_consistency), ending `All checks passed.`, exit 0 (`health-check-skipbats.txt`).

Execution provenance: `timeout 30 bash scratchpad/extract.sh <old-AGENTS.md>` (exit 0, 2026-09-29T07:01:09Z) and `HEALTH_CHECK_SKIP_BATS=1 timeout 300 scripts/health-check.sh` (exit 0, 2026-09-29T07:01:43Z), both cwd `/workspace/.claude/wt-agents-md`.

**Evidence:** `scripts/health-check.sh:208-217`, `scripts/health-check.sh:219-243`, `scripts/health-check.sh:247-290`, `docs/reviews/execution-logs/fc-r1/extract.txt`, `docs/reviews/execution-logs/fc-r1/health-check-skipbats.txt`

---

## Claim 12: "Strips the first 3 lines (tool-specific headers) from each file, then diffs."

**Location:** `test/agents-gemini-sync.bats:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sync test body; does not establish that the first three lines are always the tool-specific header (true today: title, blank, description line).

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

`tail -n +4` starts output at line 4, i.e. drops lines 1-3, and no prefix strip remains. The test passes (`ok 1`, `bats.txt`; `timeout 120 bats test/agents-gemini-sync.bats`, cwd worktree, exit 0, 2026-09-29T07:01:34Z).

**Evidence:** `test/agents-gemini-sync.bats:15-28`, `docs/reviews/execution-logs/fc-r1/bats.txt`

---

## Claim 13: "Claude Code loads AGENTS.md as this repo's project instructions (the root CLAUDE.md moved to global-instructions/, decision log row 47) and expands `@path` imports inline. The old `@./workflows/*.md` list pulled ~85K tokens of workflow text into every session here, invisible to the usage hook."

**Location:** `test/agents-gemini-sync.bats:28-31`
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the comment as a whole by reference to its atoms; does not add evidence beyond Claims 5a, 5b, 7b and 8.

Not split, because each atom repeats a log-row claim already verdicted: loading and expansion Verified (Claim 5a), the row-47 causal parenthetical Unverifiable (Claim 5b), "~85K tokens" Unverifiable (Claim 7b), "invisible to the usage hook" Verified (Claim 8). Under most-severe-wins the comment takes Unverifiable, carried by the token figure and the causal link (paraphrased — no quote available because this verdict is a roll-up of the cited claims).

**Evidence:** `test/agents-gemini-sync.bats:28-31`

---

## Claim 14: "AGENTS.md has no @-imports" (test name, as a description of what a passing test guarantees)

**Location:** `test/agents-gemini-sync.bats:33`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the test passes on HEAD and that HEAD's AGENTS.md has no imports of any form by manual read; does not establish the invariant for future edits, because the regex misses several import forms (Claim 3), and whether those forms are expanded by Claude Code cannot be confirmed in-repo.

The test passes (`ok 2 AGENTS.md has no @-imports`, `bats.txt`), and today the name is true of the file (Claim 1). As a guarantee, a pass does not imply the name: a future `@docs/x.md` or `@~/x.md` line would pass the test (`regex.txt`). Kept at Unverifiable rather than Incorrect only because the gap depends on external harness grammar; the actionable finding is Claim 3.

**Evidence:** `test/agents-gemini-sync.bats:33-39`, `docs/reviews/execution-logs/fc-r1/bats.txt`, `docs/reviews/execution-logs/fc-r1/regex.txt`

---

## Claim 15: "gains a guard that fails on any @-import in AGENTS.md (verified to fail on the previous AGENTS.md)"

**Location:** commit 5ee8315 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parenthetical "verified to fail on the previous AGENTS.md"; the "any @-import" part is the same overclaim verdicted Incorrect in Claim 3 and is not re-verdicted here.

The guard regex matched 9 lines of main's AGENTS.md (`regex.txt`: `== old AGENTS.md matches (count):` `9`), so `grep` succeeds and the test body reaches `return 1` (`test/agents-gemini-sync.bats:34-38`).

Execution provenance: `timeout 30 bash scratchpad/regex.sh <old-AGENTS.md>`, cwd `/workspace/.claude/wt-agents-md`, exit 0, 2026-09-29T07:01:09Z.

**Evidence:** `test/agents-gemini-sync.bats:34-38`, `docs/reviews/execution-logs/fc-r1/regex.txt`

---

## Claim 16: "Verified: scripts/health-check.sh, \"All checks passed.\""

**Location:** commit 5ee8315 message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers every health check except check 5 (the BATS gate) on HEAD, plus the one BATS file this diff touches; does not establish the full BATS gate (fast + slow suites) passing.

With `HEALTH_CHECK_SKIP_BATS=1`, `scripts/health-check.sh` ended `All checks passed.` with exit 0 and printed `⚠ HEALTH_CHECK_SKIP_BATS=1 — BATS gate skipped` (`health-check-skipbats.txt`). `bats test/agents-gemini-sync.bats` passed 2/2 (`bats.txt`). The full gate could not be run: `scripts/run-tests.sh --fast` refused with `another run-tests.sh run is in progress in this checkout` (`run-tests-fast.txt`, cwd worktree, 2026-09-29T07:03:10Z), presumably a sibling replicate or the orchestrator; I did not stop it. Blocker: concurrent test run in the shared worktree.

**Evidence:** `docs/reviews/execution-logs/fc-r1/health-check-skipbats.txt`, `docs/reviews/execution-logs/fc-r1/bats.txt`, `docs/reviews/execution-logs/fc-r1/run-tests-fast.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3** (`docs/decisions/log.md:88`, guard at `test/agents-gemini-sync.bats:34`): the guard does not fail on "any `@path` import"; it misses bare relative (`@docs/x.md`, `@README`), home-relative (`@~/…`) and `@./` after `(`, `"` or `[`. Either widen the regex (e.g. any `@` followed by a path character, not preceded by a word character) or narrow the log row to the forms it catches.

### Stale
- None.

### Mostly Accurate
- **Claim 10** (`scripts/health-check.sh:204-207`): the "three syntaxes" list now shows one syntax three times, and its CLAUDE.md row (unchanged) says bold where the file uses backticks; the three real forms are bold bare, bold `@./workflows/` legacy, and backtick.

### Unverifiable
- **Claim 5b** (`docs/decisions/log.md:88`): that row 47's move *caused* AGENTS.md to be loaded needs Claude Code's instruction-file precedence rules.
- **Claim 7b** (`docs/decisions/log.md:88`): "~85K tokens" needs a tokenizer count; the 4-bytes/token heuristic gives ~89.6K.
- **Claim 13** (`test/agents-gemini-sync.bats:28-31`): rolls up 5b and 7b.
- **Claim 14** (`test/agents-gemini-sync.bats:33`): the test name as a guarantee depends on the regex gap in Claim 3 and on external import grammar.
- **Claim 16** (commit message): full BATS gate not re-run (concurrent `run-tests.sh` in the worktree); all non-BATS checks and the touched suite pass.

---

## Goal-Alignment Note

- **Answered:** every claim the brief listed: byte count and arithmetic (7a/7b), byte-for-byte match (2), log-usage.sh coverage (8), harness loading (5a/5b, including what the repo can and cannot establish), the guard regex against old and synthetic lines including false positives (3, 14, 15), `extract_workflows` and both callers on the new AGENTS.md (10, 11), the sync-test header (12), and the shared section headings (4).
- **Out of scope:** code-quality or design opinions on the regex fix; the full slow/fast BATS gate (blocked by a concurrent run, not stopped).
- **Escalate:** Claim 3 is the one blocking-grade finding. Its Medium confidence rests on Claude Code's import grammar (`@README`, `@~/…` being valid imports), which I know from Claude Code's documentation but could not fetch here; the orchestrator may want to confirm it. Execution logs were written as new untracked files under `docs/reviews/execution-logs/fc-r1/`; no tracked file other than this report was edited, and no hallucination-log entry was added (Claim 3 is an overclaim, not a fabricated symbol).
