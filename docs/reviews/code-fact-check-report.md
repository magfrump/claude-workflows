# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-agents-md`, branch `fix/agents-md-no-imports`)
**Scope:** branch diff `git diff main...HEAD` (4 files: `AGENTS.md`, `docs/decisions/log.md`, `scripts/health-check.sh`, `test/agents-gemini-sync.bats`) plus the commit message of 5ee8315
**Checked:** 2026-09-29
**Total claims checked:** 20
**Summary:** 12 verified, 2 mostly accurate, 1 stale, 2 incorrect, 3 unverifiable
**Commit:** 5ee8315
**Replication:** k=3

Merged from `docs/reviews/code-fact-check-report-r1.md`, `-r2.md` and `-r3.md` by most-severe-wins (mechanical collation; no claims or evidence added). Claims are clustered at the finest granularity any replicate used, so the 20 rows are sub-claim rows (r1 split the harness-load and row-47 claims and the size and token claims; r3 split the CLAUDE.md example line from the AGENTS.md line and the bats comment's load and token halves). A replicate that verdicted only a compound records that verdict on each part, annotated `(compound)`. Execution logs: r1 under `docs/reviews/execution-logs/fc-r1/` (untracked), r3 under `docs/reviews/execution-logs/fc-r3-*.txt`, r2 in the session scratchpad `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc-r2/` (`$S/` below). Where r2 covered a `test/agents-gemini-sync.bats` comment only by citing it as an "also" location of a `docs/decisions/log.md:88` claim, its verdict on the bats row is shown as `—`.

---

## Claim 1: "Its workflow list now matches GEMINI.md byte for byte below the header" (also commit: "AGENTS.md uses bare filenames, matching GEMINI.md below the header")

**Location:** `docs/decisions/log.md:88`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers everything from line 4 to the end of both files at HEAD (a stronger property than the workflow list alone); does not establish that the 3-line headers match (they deliberately differ: `AGENTS.md:3` names Copilot/Cursor/Cline, `GEMINI.md:3` names Antigravity/Gemini CLI).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: "does not establish that the first three header lines are the only lines that differ in future edits" / "does not establish that the two files stay in sync after later edits, which the sync test guards" · r2: "nothing about GEMINI.md's own loading semantics"

`diff <(tail -n +4 AGENTS.md) <(tail -n +4 GEMINI.md)` exited 0 with no output (r1: `sync-diff.txt`, cwd `/workspace/.claude/wt-agents-md`, 2026-09-29T07:00:14Z; r2 and r3 re-ran it with the same result; r2 also `cmp` exit 0). GEMINI.md is unchanged on the branch (`git diff --quiet main HEAD -- GEMINI.md` succeeded), so the match comes entirely from the AGENTS.md edit. The bats sync test also passes: `ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)`.

**Evidence:** `AGENTS.md:4-76`, `GEMINI.md:4-76`, `docs/reviews/execution-logs/fc-r1/sync-diff.txt`, `docs/reviews/execution-logs/fc-r1/bats.txt`

---

## Claim 2: "`test/agents-gemini-sync.bats` fails on any `@path` import in AGENTS.md"

**Location:** `docs/decisions/log.md:88` (the guard it describes is `test/agents-gemini-sync.bats:34-40`, test "AGENTS.md has no @-imports")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the regex's behaviour on the old AGENTS.md and on 16-20 synthetic lines; does not establish Claude Code's exact import grammar, which is not documented anywhere in this repo (the forms counted as imports below are taken from Claude Code's memory documentation, which could not be fetched because the sandbox has no egress; confidence is Medium for that reason).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1: "possible false positive: the regex matches `@./x` inside a backtick code span, which Claude Code's documentation says is not expanded" · r3: "the backtick in the class makes the guard fire on a documented example inside a code span" · r1+r2+r3: "email-style prose (`magfrump@gmail.com`, `foo@/bar`) does not match, no false positives" · r1+r2+r3: "Claude Code's import grammar is external, hence Medium"

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

The regex requires `@` to be followed by `/`, `./` or `../`, and preceded by start-of-line, whitespace, `*` or a backtick. Executed against synthetic lines (all three replicates agree):

- MATCH: `- **@./workflows/x.md**`, `@./workflows/x.md`, `see @../x.md here`, `@/abs/path.md`, `` `@./x.md` `` and all 9 lines of `git show main:AGENTS.md`.
- miss: `@x.md`, `see @x.md here`, `@workflows/x.md`, `@~/x.md`, `see @~/.claude/x.md`, `- **@README.md**`, and `@./x.md` right after `(`, `"` or `[`.

So the guard catches every line the old AGENTS.md had and the `@../` and `@/abs` forms, but misses bare relative imports (`@docs/x.md`, `@README`), home-relative imports (`@~/...`), and `@./` preceded by `(`, `"` or `[`. "Fails on any `@path` import" overstates it; the precise statement is "fails on `@/`, `@./` and `@../` imports that begin a line or follow whitespace, `*` or a backtick" (paraphrased — no quote available because the import grammar is external harness documentation, not repo code).

**Evidence:** `test/agents-gemini-sync.bats:34-40`, `docs/reviews/execution-logs/fc-r1/regex.txt`, `docs/reviews/execution-logs/fc-r3-regex.txt`, `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc-r2/regex.log`

---

## Claim 3: "The sections AGENTS.md shares with the global instructions (Context Packing, Shared Thoughts, General Principles) stay"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of the three H2 headings in both files at HEAD and that the diff does not touch them; does not establish that the section bodies are identical between the two files (they are not claimed to be, and the global versions are longer).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

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

The branch diff changes only `AGENTS.md:9-18` (a single `@@ -6,16 +6,16 @@` hunk) (paraphrased — no quote available because this is about which hunks the diff contains, from `git diff main...HEAD`).

**Evidence:** `AGENTS.md:41`, `AGENTS.md:52`, `AGENTS.md:65`, `global-instructions/CLAUDE.md:126`, `global-instructions/CLAUDE.md:153`, `global-instructions/CLAUDE.md:303`

---

## Claim 4a: "Claude Code loads AGENTS.md as this repo's project instructions and expands `@` imports inline"

**Location:** `docs/decisions/log.md:88` (repeated at `test/agents-gemini-sync.bats:28-33` and in the commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the harness behaviour observed in the reviewers' own sessions only, with the main checkout's (pre-branch) AGENTS.md; does not establish it from anything in the repo (no repo file documents Claude Code's instruction loading), nor for other Claude Code versions or configurations, nor whether AGENTS.md loads because no root CLAUDE.md exists or unconditionally.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "an orchestrator that needs in-repo proof should treat this as Unverifiable-from-repo" · r3: "does not establish recursive-import depth"

Nothing inside the repository can establish this: it is a property of the Claude Code harness (paraphrased — no quote available because the claim covers harness behaviour outside the codebase). It is directly observable in the context each review agent received: the harness injected "Contents of /workspace/AGENTS.md (project instructions, checked into the codebase)" followed by the full contents of all nine files the old AGENTS.md imported (`workflows/research-plan-implement.md`, `divergent-design.md`, `parallel-worktrees.md`, `task-decomposition.md`, `pr-prep.md`, `spike.md`, `branch-strategy.md`, `user-testing-workflow.md`, `codebase-onboarding.md`), each labelled "(project instructions, checked into the codebase)" (paraphrased — no quote available because the evidence is the session's injected system context, not a file). That is the load-and-expand behaviour the claim describes; it is one session on one harness version.

**Evidence:** `AGENTS.md` (main, via `git show main:AGENTS.md`), reviewer session injected project-instructions context (no repo path)

---

## Claim 4b: "After row 47 moved the root CLAUDE.md out, Claude Code loads AGENTS.md …" (causal link to log row 47)

**Location:** `docs/decisions/log.md:88` (also `test/agents-gemini-sync.bats:28-31`, commit message "Since decision log row 47 moved the root CLAUDE.md into global-instructions/")
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers that row 47 exists and records the move, and that no root CLAUDE.md exists now; does not establish that the move is what caused Claude Code to start loading AGENTS.md (it may have loaded AGENTS.md before as well).
**Replicate verdicts:** r1=Unverifiable · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "covers only that log row 47 exists and records that move; does not establish when the harness started loading AGENTS.md as a result" · r3: "does not establish whether AGENTS.md is loaded because no root CLAUDE.md exists or unconditionally"

Row 47 records the move:

```
// docs/decisions/log.md:70
| 47 | 2026-09-11 | **The global instructions file moves out of the repo root to `global-instructions/CLAUDE.md`.** ...
```

and `ls CLAUDE.md` at the worktree root fails ("No such file or directory"); `scripts/health-check.sh:54` has `GLOBAL_MD="global-instructions/CLAUDE.md"`. Whether Claude Code loads AGENTS.md only when no root CLAUDE.md exists is a harness rule not recorded in the repo (paraphrased — no quote available because the claim covers absence of any such documentation). Row 47's own rationale counts ~8K tokens of duplication and does not mention AGENTS.md workflow expansion, which is consistent with, but does not prove, AGENTS.md not being loaded before. Verifying needs Claude Code's instruction-file precedence rules or a session run with a root CLAUDE.md present.

**Evidence:** `docs/decisions/log.md:70`, `scripts/health-check.sh:54`

---

## Claim 5: "the nine `@./workflows/*.md` entries"

**Location:** `docs/decisions/log.md:88` (also commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of `@./workflows/` references in main's AGENTS.md; does not establish that no other `@` import form existed there (none did, per the regex count equalling the entry count and the diff showing only these lines changed).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

`git show main:AGENTS.md | grep -c '@\./workflows/'` printed `9` (r3: `grep -c '@\./workflow'` also 9), and the list in `sizes.txt` names nine distinct files. The diff removes exactly these nine lines (eight at `AGENTS.md:9-16`, one at `:18`).

**Evidence:** `AGENTS.md:9-18` (main), `docs/reviews/execution-logs/fc-r1/sizes.txt`

---

## Claim 6: "put ~358 KB … of workflow text into every session here"

**Location:** `docs/decisions/log.md:88` (also commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the raw byte size of the nine workflow files at main (decimal KB); does not establish the exact size of what the harness injects (wrapper text, or whether it recurses into further imports; the workflow files contain no `@`-import-shaped strings, the only other `@` being `@pytest.mark.integration` in prose at `workflows/codebase-onboarding.md:267`), or the size of AGENTS.md itself.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

Per-file byte counts at main (`git show main:workflows/<f>.md | wc -c`): 68,867 + 80,340 + 7,596 + 21,556 + 44,652 + 24,471 + 25,541 + 30,395 + 54,996 = 358,414 bytes = 358.4 KB (350.0 KiB). The workflow files are unchanged main..HEAD. Character count is 355,598 (r1 `chars.txt`). All three replicates reproduced the same figure.

**Evidence:** `docs/reviews/execution-logs/fc-r1/sizes.txt`, `docs/reviews/execution-logs/fc-r1/chars.txt`, `docs/reviews/execution-logs/fc-r3-sizes.txt`

---

## Claim 7: "(~85K tokens)"

**Location:** `docs/decisions/log.md:88` (also commit message; the same figure recurs at `test/agents-gemini-sync.bats:32`, see Claim 14b)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the arithmetic from measured size to tokens under this repo's documented chars/4 convention; does not establish an actual tokenizer count, which would need the Claude token-counting API (not available in the sandbox).
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Mostly accurate
**Replicate annotations:** r1+r2: "does not establish the real token count, which needs the Claude tokenizer (not available, no egress); the 4-bytes-per-token heuristic gives ~89.6K" · r1: "~85K implies 4.22 bytes or 4.18 characters per token; no repo artifact records how it was measured"

The nine files hold 358,414 bytes and 355,598 characters. The repo's stated estimate is "tokens ≈ chars/4" (`skills/code-review/SKILL.md:328`: "estimated as chars/4"; also `docs/decisions/log.md:55`). That gives about 88.9K tokens (89.6K from bytes/4), not ~85K. "~85K" implies about 4.18 chars per token: plausible for English markdown, but not the repo's convention and about 4-5% low against it. Order of magnitude and conclusion are right; the precise version is "~89K tokens (chars/4)". This is a mild case of the logged "numeric claim in a commit message" family (`hallucination-patterns.md:28`, `:30`) but an estimate, not a fabricated count (r3).

**Evidence:** `skills/code-review/SKILL.md:328`, `docs/decisions/log.md:55`, `docs/reviews/execution-logs/fc-r3-sizes.txt`, `docs/reviews/execution-logs/fc-r1/chars.txt`

---

## Claim 8: "`hooks/log-usage.sh` cannot see `@` loads, so workflow use went unmeasured"

**Location:** `docs/decisions/log.md:88` (also `test/agents-gemini-sync.bats:31-33` "invisible to the usage hook", commit message)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hook's tool-name gate and its own coverage comment; does not establish that no workflow use was logged at all (explicit `Read` calls on workflow files are still logged, so "unmeasured" is accurate only for content delivered by the `@` expansion), nor that no other hook or telemetry observes instruction loading.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "wiring matcher `Skill|Read|Agent` for both log-usage.sh and log-usage-post.sh (hooks/wiring.json:86, :115)" · r3: "a workflow event is emitted only on `Read` with `*/workflows/*` (hooks/log-usage.sh:62-67)"

The hook's coverage comment:

```bash
# hooks/log-usage.sh:7-10
# COVERAGE: only Skill, Read and Agent tool calls are seen. A workflow or skill
# read through Bash (`cat`), an `@` import, or text inlined into a subagent
# brief produces no event, and nothing fires in sessions without the wiring.
# Counts from this log are lower bounds; see Q-017 (questions-archive.md).
```

The code matches it: `hooks/lib/usage-common.sh:27-31` exits 0 (`*) exit 0 ;;`) for any tool name outside its allowed list, and `hooks/log-usage.sh` handles only `Skill)`, `Read)` and `Agent)` (paraphrased — no quote available because the case arms span `:51-91`). An `@` expansion is not a tool call, so no PreToolUse event fires for it.

**Evidence:** `hooks/log-usage.sh:7-10`, `hooks/log-usage.sh:51-91`, `hooks/lib/usage-common.sh:24-31`, `hooks/wiring.json:85-92`, `hooks/wiring.json:114-121`

---

## Claim 9: "Bare names cost nothing and are what GEMINI.md already used."

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that main's GEMINI.md used bare bold filenames (unchanged on the branch); "cost nothing" is read narrowly as "trigger no import expansion", which follows from Claim 4a's observation that only `@` forms were expanded; does not establish zero token cost of the list text itself, nor how any non-Claude agent resolves a bare filename.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: "does not establish that Gemini/Antigravity treat `@` specially or how a non-Claude agent resolves a bare filename"

```
// GEMINI.md:9 (main, unchanged on branch)
- **research-plan-implement.md** — The default development loop. ...
```

**Evidence:** `GEMINI.md:9-18`, `AGENTS.md:9-17`

---

## Claim 10: "AGENTS.md: `**research-plan-implement.md**` (legacy form: `**@./workflows/…**`)"

**Location:** `scripts/health-check.sh:206`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `extract_workflows` on HEAD's AGENTS.md, main's AGENTS.md, GEMINI.md and the global file; does not establish handling of `@./workflows/` inside backticks beyond the regex reading, nor other `@` spellings (`@workflows/x.md` without `./` is not stripped).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

```bash
# scripts/health-check.sh:214-215
    { grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$file" || true; } \
        | sed 's/\*\*//g; s/`//g; s|@\./workflows/||' \
```

`extract_workflows` (sourced and run directly) returned the identical nine names for HEAD's AGENTS.md (bare form), main's AGENTS.md (legacy form), GEMINI.md and `global-instructions/CLAUDE.md` (r1 `extract.txt`; r2 `$S/extract.log`; r3 `fc-r3-healthcheck-sections.txt`), exit 0.

**Evidence:** `scripts/health-check.sh:203-217`, `docs/reviews/execution-logs/fc-r1/extract.txt`, `docs/reviews/execution-logs/fc-r3-healthcheck-sections.txt`

---

## Claim 11: "Handles three syntaxes: CLAUDE.md: `**research-plan-implement.md**` … GEMINI.md: `**research-plan-implement.md**`" (the CLAUDE.md example and the "three syntaxes" list)

**Location:** `scripts/health-check.sh:204-207`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the example syntax the header gives for the CLAUDE.md input against the file the check now reads; does not establish any functional defect, since the regex accepts both delimiters. The line predates this branch (blame 79cab0ea, 2026-03-23) and sits next to the changed line.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate (compound) · r3=Stale
**Replicate annotations:** r1+r2: "the example list now shows the same bold-bare form three times, so the 'three syntaxes' count is harder to map" · r1+r2: "the inaccurate row (`:205`, CLAUDE.md) is unchanged context, not part of this diff" · r1+r2+r3: "the three syntaxes the regex actually handles are bold `**name.md**`, backtick `` `name.md` `` and the legacy `**@./workflows/name.md**`"

The function's own inline comment contradicts the header: "CLAUDE.md uses backticks for all filenames (so the result is filtered against workflows/ in the caller); AGENTS.md and GEMINI.md use bold." (`scripts/health-check.sh:210-212`). `global-instructions/CLAUDE.md:24` has `` `research-plan-implement.md` `` and `rg -c '\*\*[a-z-]+\.md\*\*' global-instructions/CLAUDE.md` finds 0 bold filenames. After this branch the header's "three syntaxes" shows bold three times plus a legacy parenthetical. The precise version is `CLAUDE.md:  `research-plan-implement.md``.

**Evidence:** `scripts/health-check.sh:204-214`, `global-instructions/CLAUDE.md:24`

---

## Claim 12: "`extract_workflows` callers (`check_workflow_crossrefs`, `check_md_consistency`) still pass on the new AGENTS.md"

**Location:** `scripts/health-check.sh:219-290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two checks as run on this commit (r2: full gate; r1: `HEALTH_CHECK_SKIP_BATS=1`; r3: sourced functions); does not establish behaviour if AGENTS.md later adds `@` forms the regex does not strip.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "`check_md_semantic_divergence` also passes: AGENTS.md and GEMINI.md have identical section structure"

`check_workflow_crossrefs` tests `[[ ! -f "$REPO_ROOT/workflows/$wf" ]]` for each extracted name (`scripts/health-check.sh:233-236`); `check_md_consistency` compares the `workflow_sets` strings across the three files (`:261-270`). Runs on HEAD printed `✓ AGENTS.md: all workflow references resolve` and `✓ All MD files reference the same workflows`, ending `All checks passed.`, exit 0 (r2 `$S/health-full.log:34-40`; r1 `health-check-skipbats.txt`; r3 `fc-r3-healthcheck-sections.txt`).

**Evidence:** `scripts/health-check.sh:219-290`, `docs/reviews/execution-logs/fc-r1/health-check-skipbats.txt`, `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc-r2/health-full.log`

---

## Claim 13: "Strips the first 3 lines (tool-specific headers) from each file, then diffs."

**Location:** `test/agents-gemini-sync.bats:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sync test body; does not establish that the first three lines are always the tool-specific header (true today: title, blank, description line), nor detection of trailing-newline-only differences (which `$(...)` strips), nor the second (@-import) test case.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "trailing-newline-only differences are not detected because `$(...)` strips them from both sides" · r3: "the old `sed 's|@\./workflows/||'` strip is gone, so the comment no longer mentions it"

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

`tail -n +4` starts output at line 4, i.e. drops lines 1-3. The test passes (`ok 1`, `bats.txt`; `timeout 120 bats test/agents-gemini-sync.bats`, cwd worktree, exit 0, 2026-09-29T07:01:34Z).

**Evidence:** `test/agents-gemini-sync.bats:15-28`, `docs/reviews/execution-logs/fc-r1/bats.txt`

---

## Claim 14a: "Claude Code loads AGENTS.md as this repo's project instructions (the root CLAUDE.md moved to global-instructions/, decision log row 47) and expands `@path` imports inline. … invisible to the usage hook." (test comment)

**Location:** `test/agents-gemini-sync.bats:28-33`
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the comment as a whole by reference to its atoms; does not add evidence beyond Claims 4a, 4b, 7 and 8.
**Replicate verdicts:** r1=Unverifiable (compound) · r2=— · r3=Verified
**Replicate annotations:** r1: "loading and expansion Verified (Claim 4a), the row-47 causal parenthetical Unverifiable (Claim 4b), 'invisible to the usage hook' Verified (Claim 8); the comment takes Unverifiable under most-severe-wins, carried by the token figure and the causal link" · r3: "same basis and residue as Claims 4a and 8 (row 47 at `docs/decisions/log.md:70`; session-context observation; hook matcher `Skill|Read|Agent`); does not establish version-independence of the harness behavior"

The comment's atoms repeat log-row claims already verdicted: loading and expansion (Claim 4a, Verified), the row-47 causal parenthetical (Claim 4b, Unverifiable), "invisible to the usage hook" (Claim 8, Verified) (paraphrased — no quote available because this verdict is a roll-up of the cited claims). r3 read the comment text at `test/agents-gemini-sync.bats:30-32` ("Claude Code loads AGENTS.md as this repo's project instructions (the root CLAUDE.md moved to global-instructions/, decision log row 47) and expands `@path` imports inline") and found the row reference and mechanism matching Claim 4a's evidence, and "invisible to the usage hook" matching `hooks/log-usage.sh:7-8`.

**Evidence:** `test/agents-gemini-sync.bats:28-33`, `docs/decisions/log.md:70`, `hooks/log-usage.sh:7-10`

---

## Claim 14b: "The old `@./workflows/*.md` list pulled ~85K tokens of workflow text into every session here" (test comment)

**Location:** `test/agents-gemini-sync.bats:30-33`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Same measurement as Claim 7; does not establish an actual tokenizer count.
**Replicate verdicts:** r1=Unverifiable (compound) · r2=— · r3=Mostly accurate
**Replicate annotations:** r1: "Unverifiable, carried by the token figure and the causal link (roll-up of Claims 4b and 7)"

358,414 bytes / 355,598 chars, so ~88.9K tokens under the repo's chars/4 convention (`skills/code-review/SKILL.md:328`). "~85K" is about 4-5% low; "~89K" is the precise figure.

**Evidence:** `docs/reviews/execution-logs/fc-r3-sizes.txt`, `skills/code-review/SKILL.md:328`

---

## Claim 15: "AGENTS.md has no @-imports" (test name, and failure text "AGENTS.md contains @-imports, which Claude Code expands into every session", as a description of what a passing test guarantees)

**Location:** `test/agents-gemini-sync.bats:33-40`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what the test's pass asserts, from the regex executed in Claim 2; does not establish the harness import grammar (external).
**Replicate verdicts:** r1=Unverifiable · r2=— · r3=Incorrect
**Replicate annotations:** r1: "kept at Unverifiable rather than Incorrect only because the gap depends on external harness grammar; the test passes (`ok 2`) and today the name is true of the file (Claim 1 manual read shows no `@` token of any form); the actionable finding is Claim 2"

A passing test is named as a guarantee that AGENTS.md has no `@`-imports. The regex it runs, `grep -nE '(^|[[:space:]*`])@\.{0,2}/' "$AGENTS"` (`test/agents-gemini-sync.bats:35`), passes on `@README.md`, `@workflows/x.md`, `@~/x.md` and `(@./x.md)` (executed, Claim 2). So a green test does not establish the property its name states for bare-relative or home-relative imports. This is the same gap as Claim 2, recorded at the test's own location.

**Evidence:** `test/agents-gemini-sync.bats:34-40`, `docs/reviews/execution-logs/fc-r3-regex.txt`, `docs/reviews/execution-logs/fc-r1/regex.txt`

---

## Claim 16: "gains a guard that fails on any @-import in AGENTS.md (verified to fail on the previous AGENTS.md)"

**Location:** commit 5ee8315 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parenthetical "verified to fail on the previous AGENTS.md"; the "any @-import" part is the same overclaim verdicted Incorrect in Claim 2 and is not re-verdicted here.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "the old-AGENTS.md run also fails test 1 (drift), as expected, because the prefix strip is gone"

The guard regex matched 9 lines of main's AGENTS.md (r1 `regex.txt`: `== old AGENTS.md matches (count):` `9`), so `grep` succeeds and the test body reaches `return 1` (`test/agents-gemini-sync.bats:34-38`). r2 and r3 built a scratch tree with the branch's test file, `git show main:AGENTS.md` and the current GEMINI.md and got `not ok 2 AGENTS.md has no @-imports` listing lines 9-16 and 18.

**Evidence:** `test/agents-gemini-sync.bats:34-40`, `docs/reviews/execution-logs/fc-r1/regex.txt`, `docs/reviews/execution-logs/fc-r3-bats.txt`

---

## Claim 17: "Verified: scripts/health-check.sh, \"All checks passed.\""

**Location:** commit 5ee8315 message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers every health check except check 5 (the BATS gate) on HEAD, plus the one BATS file this diff touches; does not establish the full BATS gate (fast + slow suites) passing.
**Replicate verdicts:** r1=Unverifiable · r2=Verified · r3=Unverifiable
**Replicate annotations:** r1: "the full gate could not be run: `scripts/run-tests.sh --fast` refused with 'another run-tests.sh run is in progress in this checkout'; blocker: concurrent test run in the shared worktree" · r3: "check 5 deliberately skipped because concurrent sibling replicates share the uid and process table; pr-prep step 5a requires quiescing first" · r2: "the full gate passed in r2's run, ending `All checks passed.` with 4 report-dependent BATS suites NOT RUN (`$S/health-full.log:1378`, `:1680-1681`)"

With `HEALTH_CHECK_SKIP_BATS=1`, `scripts/health-check.sh` ended `All checks passed.` with exit 0 and printed `⚠ HEALTH_CHECK_SKIP_BATS=1 — BATS gate skipped` (r1 `health-check-skipbats.txt`; r3 same). `bats test/agents-gemini-sync.bats` passed 2/2. r1 and r3 could not run the full gate because of concurrent runs (r1 `run-tests-fast.txt`, cwd worktree, 2026-09-29T07:03:10Z). r2 ran the full gate to exit 0 (2026-09-29T00:13:02-07:00), printing `✓ Fast BATS suites passed (excluding 4 report-dependent suite(s) not run)`, `✓ Slow BATS suites passed`, and `All checks passed.`; r2's Verified stands as a single-replicate observation of the full gate, outvoted under most-severe-wins by the two replicates that could not run it.

**Evidence:** `docs/reviews/execution-logs/fc-r1/health-check-skipbats.txt`, `docs/reviews/execution-logs/fc-r1/run-tests-fast.txt`, `docs/reviews/execution-logs/fc-r3-healthcheck-skipbats.txt`, `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc-r2/health-full.log`

---

## Claim 18: "kept the sections AGENTS.md shares with the global instructions (~40 lines)"

**Location:** commit 5ee8315 message, Notes line
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count of the three shared sections in AGENTS.md; does not establish their equality with the global file's text beyond the headings (Claim 3).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "verdicted inside its Claim 4 (shared sections); '~40 lines' is an approximation of `AGENTS.md:41-76`, which is 36 lines"

The three shared sections run from `AGENTS.md:41` (`## Context Packing`) to the end of the file at `:76` (`wc -l AGENTS.md` = 76), which is 36 lines, so "~40" fits (paraphrased — no quote available because this is a line count, not a code excerpt).

**Evidence:** `AGENTS.md:41-76`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`docs/decisions/log.md:88`): the guard does not fail on "any `@path` import"; it misses `@x.md`, `@docs/x.md`, `@~/x.md` and `@./` after `(`, `"` or `[`. Narrow the wording to the `@/`, `@./`, `@../` family or widen the regex.
- **Claim 15** (`test/agents-gemini-sync.bats:33-40`): the test name "has no @-imports" states a guarantee the regex does not give for bare-relative or home-relative imports (same gap as Claim 2).

### Stale
- **Claim 11** (`scripts/health-check.sh:204-207`): the CLAUDE.md example shows bold, but `global-instructions/CLAUDE.md` uses backticks; the real three syntaxes are bold, backtick and legacy `@./workflows/`. The line predates the branch.

### Mostly Accurate
- **Claim 7** (`docs/decisions/log.md:88`): "~85K tokens" is about 4-5% below the repo's chars/4 convention (~89K).
- **Claim 14b** (`test/agents-gemini-sync.bats:30-33`): same "~85K" figure in the test comment.

### Unverifiable
- **Claim 4b** (`docs/decisions/log.md:88`): that row 47's move caused AGENTS.md to be loaded needs Claude Code's instruction-file precedence rules.
- **Claim 14a** (`test/agents-gemini-sync.bats:28-33`): roll-up of Claims 4a, 4b and 8; carried by the row-47 causal link.
- **Claim 17** (commit message): the full BATS gate was not re-run by r1 or r3 (concurrent runs); r2 ran it green.

---

## Escalations

- **`test/agents-gemini-sync.bats:34` and `docs/decisions/log.md:88` (Claims 2, 15), addressee: author / orchestrator** — raised by r1, r2, r3. The guard does not fail on "any `@path` import"; it is the one blocking-grade finding. Either narrow the log row and test name to the `@/`, `@./`, `@../` family, or widen the regex (r3 suggests `(^|[^[:alnum:]_.])@[~./[:alnum:]]`, noting the code-span false-positive trade-off). r1: the Medium confidence rests on Claude Code's import grammar (`@README`, `@~/…` being valid imports), which could not be fetched here; the orchestrator may want to confirm it.
- **`docs/decisions/log.md:88` (Claims 4a, 4b), addressee: orchestrator** — raised by r2 (and r1 via Claim 4b). Claim 4a is Verified only from harness-observed session context, not from any repo file; an orchestrator that needs in-repo proof should read it as Unverifiable-from-repo, and the row-47 causal link is Unverifiable.
- **commit 5ee8315 message (Claim 17), addressee: orchestrator** — raised by r1, r3 (out-of-scope notes). The full fast+slow BATS gate was not run by r1 or r3 because of concurrent runs in the shared worktree; only r2 ran it (green). A quiesced run is needed to close it.
- **`docs/reviews/execution-logs/fc-r1/` (untracked), addressee: orchestrator** — raised by r1. r1's execution logs are new untracked files; r3's are `docs/reviews/execution-logs/fc-r3-*.txt`; r2's live in the scratchpad.

---

## Verdict stability

- **Total clusters:** 20
- **All reporting replicates agreed:** 13 (Claims 1, 2, 3, 4a, 5, 6, 8, 9, 10, 12, 13, 16, 18)
- **Verdicts disagreed:** 7
  - Claim 4b: r1=Unverifiable · r2=Verified · r3=Verified (compound) → Unverifiable
  - Claim 7: r1=Unverifiable · r2=Unverifiable · r3=Mostly accurate → Mostly accurate
  - Claim 11: r1=Mostly accurate (compound) · r2=Mostly accurate (compound) · r3=Stale → Stale
  - Claim 14a: r1=Unverifiable (compound) · r2=— · r3=Verified → Unverifiable
  - Claim 14b: r1=Unverifiable (compound) · r2=— · r3=Mostly accurate → Mostly accurate
  - Claim 15: r1=Unverifiable · r2=— · r3=Incorrect → Incorrect
  - Claim 17: r1=Unverifiable · r2=Verified · r3=Unverifiable → Unverifiable
- **Agreement rate:** 13/20 = 65%
