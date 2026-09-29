Commit: 7c2253a

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-agents-md`, branch `fix/agents-md-no-imports`)
**Scope:** `git diff main...HEAD -- . ':(exclude)docs/reviews'` (AGENTS.md, docs/decisions/log.md row 65, scripts/health-check.sh comment, test/agents-gemini-sync.bats) plus commit messages `git log main..HEAD` (5ee8315, 7b43db2; 64671f0 and 7c2253a are review-artifact commits with no code claims). Final confirming pass, replicate r3.
**Checked:** 2026-09-29
**Total claims checked:** 22
**Summary:** 15 verified, 3 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Hallucination-pattern log: `docs/reviews/hallucination-patterns.md` read; no claim below matches a logged pattern (no fabricated symbol, flag or API is claimed on this branch).

Execution provenance (applies to every `executed` claim below): cwd `/workspace/.claude/wt-agents-md`; scripts `docs/reviews/execution-logs/fc-final-r3/run.sh` (2026-09-29T07:35:36Z, exit 0), `run2.sh` (07:36:15Z, exit 0), `run3.sh` (07:37:10Z, exit 0), each run as `bash <script> 2>&1 | tee <script>.out`; captured output in `run.out`, `run2.out`, `run3.out` in the same directory. `fi.sh` is a byte-for-byte copy of `find_imports` from `test/agents-gemini-sync.bats:41-45` (minus the shellcheck comment); `pos.md`/`neg.md` copy the test's heredocs; `probe.md` holds extra adversarial lines. The bats file itself was run once (`timeout 120 bats test/agents-gemini-sync.bats`, inside `run.sh`): `1..3`, all ok, exit 0.

---

## Claim 1: "Its workflow list now matches GEMINI.md byte for byte below the header"

**Location:** `docs/decisions/log.md:88`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers AGENTS.md vs GEMINI.md from line 4 onward at commit 7c2253a; does not establish that the three-line headers match (they are meant to differ) or future drift beyond what `test/agents-gemini-sync.bats` test 1 enforces.

`diff <(tail -n +4 AGENTS.md) <(tail -n +4 GEMINI.md); echo diffrc=$?` printed nothing and `diffrc=0` (`run.out`, "== head diff agents/gemini"). The bats test that enforces it passed: `ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)` (`run.out`).

**Evidence:** `AGENTS.md:4-`, `GEMINI.md:4-`, `test/agents-gemini-sync.bats:15-27`, `docs/reviews/execution-logs/fc-final-r3/run.out`

---

## Claim 2: "`test/agents-gemini-sync.bats` fails on any `@path` import (`@/`, `@./`, `@../`, `@~/`, `@dir/x`, `@x.md`; not inside code spans) in AGENTS.md or `global-instructions/CLAUDE.md`" — the enumerated forms and the two covered files

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six enumerated forms, the single-backtick code-span exclusion, and that test 3 loops over exactly AGENTS.md and global-instructions/CLAUDE.md; does not establish the word "any" (see Claim 3), behavior inside fenced code blocks or double-backtick spans (see Claim 14), or behavior if global-instructions/CLAUDE.md is absent (see Claim 17).

The finder:

```bash
# test/agents-gemini-sync.bats:43-44
  sed -E 's/`[^`]*`//g' "$1" \
    | grep -nE '(^|[^[:alnum:]_.@/-])@(~?/|\.{1,2}/|[[:alnum:]_][[:alnum:]_.-]*(/|\.md([^[:alnum:]]|$)))'
```

The alternation after `@` is `~?/` (`@/`, `@~/`), `\.{1,2}/` (`@./`, `@../`), and a name followed by `/` (`@dir/x`) or `.md` plus non-alnum/end (`@x.md`). Executed, each form matched on `pos.md` (lines 1-7 all printed, `run.out` "== pos"), and ``use `@./x.md` in a code span`` did not match (`run.out` "== neg", rc=1). Test 3 iterates exactly the two files:

```bash
# test/agents-gemini-sync.bats:73
  for f in "$AGENTS" "$REPO_ROOT/global-instructions/CLAUDE.md"; do
```

(excerpt ends :73; enclosing @test continues to :81 — read)

**Evidence:** `test/agents-gemini-sync.bats:41-45`, `test/agents-gemini-sync.bats:71-81`, `docs/reviews/execution-logs/fc-final-r3/run.out`

---

## Claim 3: "fails on any `@path` import" (the universal "any")

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the finder's behavior on extensionless, non-`.md` and uppercase-extension bare-relative forms and on fenced code blocks; does not establish Claude Code's actual import grammar, which is external documentation not fetchable in this sandbox (the Medium confidence rests on it).

The parenthetical enumeration is exact (Claim 2), so the mechanism is right, but "any" overstates it. Executed on `probe.md` (`run.out` "== probe"): `See @README for overview`, `and @package.json for commands` and `@x.MD` produce no match, because the name branch requires a following `/` or a lowercase `.md`:

```bash
# test/agents-gemini-sync.bats:44
[[:alnum:]_][[:alnum:]_.-]*(/|\.md([^[:alnum:]]|$))
```

Claude Code's own memory documentation uses `@README` and `@package.json` as its import example (paraphrased — no quote available because the documentation is external and the sandbox has no egress; recalled, not fetched), and pass 1's r1 replicate named `@README` as a missed form (`docs/reviews/code-fact-check-report.md:61`). Precise version: "fails on `@/`, `@./`, `@../`, `@~/`, `@dir/x` and `@name.md` imports", not "any". The practical exposure is small (neither file currently contains such a line; `run.out` "== @ in AGENTS" empty, "== @ in global" only a backticked `<name>@claude-plugins-official`).

**Evidence:** `test/agents-gemini-sync.bats:44`, `docs/reviews/execution-logs/fc-final-r3/probe.md`, `docs/reviews/execution-logs/fc-final-r3/run.out`, `docs/reviews/code-fact-check-report.md:61`

---

## Claim 4: "The sections AGENTS.md shares with the global instructions (Context Packing, Shared Thoughts, General Principles) stay"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence of the three headings in both files; does not establish that the section bodies are identical between the two files.

`grep -n '^## '` output (`run2.out`, "== shared headings"): AGENTS.md has `41:## Context Packing`, `52:## Shared Thoughts`, `65:## General Principles`; global-instructions/CLAUDE.md has `126:## Context Packing`, `153:## Shared Thoughts`, `303:## General Principles`. The branch diff does not touch those AGENTS.md sections (paraphrased — no quote available because the claim concerns absence of changes; the AGENTS.md hunk is confined to lines 9-18).

**Evidence:** `AGENTS.md:41`, `AGENTS.md:52`, `AGENTS.md:65`, `global-instructions/CLAUDE.md:126`, `docs/reviews/execution-logs/fc-final-r3/run2.out`

---

## Claim 5: "Claude Code loads AGENTS.md as this repo's project instructions and expands `@` imports inline: the nine `@./workflows/*.md` entries put ... workflow text into every session and subagent here"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the harness behavior as observed in this replicate's own injected context (a subagent session in this repo, main checkout still on the old AGENTS.md); does not establish the behavior for every Claude Code version or for other agents (Copilot, Cursor, Gemini).

Paraphrased — no quote available because the evidence is this agent's own system context, not a repo file: this subagent's injected context lists `/workspace/AGENTS.md` as "project instructions, checked into the codebase", with the `**@./workflows/…**` lines, immediately followed by the full contents of `/workspace/workflows/research-plan-implement.md`, `divergent-design.md`, `parallel-worktrees.md`, `task-decomposition.md`, `pr-prep.md`, `spike.md`, `branch-strategy.md`, `user-testing-workflow.md` and `codebase-onboarding.md`. That confirms both the expansion and the "and subagent" part. It agrees with override-log row 153, which accepted this claim on the same kind of observation.

**Evidence:** `docs/reviews/override-log.md:153`, `AGENTS.md:9-18` (main version via `git show main:AGENTS.md`)

---

## Claim 6: "~358 KB (~89K tokens at chars/4)"

**Location:** `docs/decisions/log.md:88`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte and UTF-8 character counts of the nine files `git show main:AGENTS.md` imports, and the chars/4 arithmetic; does not establish actual tokenizer counts.

Python over the nine paths extracted from `git show main:AGENTS.md`: `9 files; main bytes 358414 chars 355598 chars/4 88899.5 bytes/4 89603.5`; the HEAD copies are identical in size (`run2.out`, first lines). 358,414 bytes ≈ 358 KB; 355,598 / 4 = 88,899.5 ≈ 89K. (`wc -m` in `run.out` reports chars equal to bytes only because the sandbox locale is unset; the Python UTF-8 count is the authoritative one.)

**Evidence:** `docs/reviews/execution-logs/fc-final-r3/run2.sh`, `docs/reviews/execution-logs/fc-final-r3/run2.out`

---

## Claim 7: "`hooks/log-usage.sh` cannot see `@` loads, so workflow use went unmeasured"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hook's tool-name dispatch (Skill, Read, Agent only); does not establish whether other telemetry in the repo records `@` loads.

```bash
# hooks/log-usage.sh:7-8
# COVERAGE: only Skill, Read and Agent tool calls are seen. A workflow or skill
# read through Bash (`cat`), an `@` import, or text inlined into a subagent
```

(excerpt ends :8; the coverage comment continues — read) and the dispatch `case "$TOOL_NAME" in` (`hooks/log-usage.sh:51`) has arms only for Skill, `Read)` (`:59`) and Agent (`:75` area). An `@` import is expanded by the harness into the prompt, with no tool call for the hook to see (paraphrased — no quote available because this is the harness's loading path, not repo code).

**Evidence:** `hooks/log-usage.sh:7-13`, `hooks/log-usage.sh:51-75`, `docs/reviews/execution-logs/fc-final-r3/run2.out`

---

## Claim 8: "Handles three syntaxes: CLAUDE.md: `research-plan-implement.md` / AGENTS.md, GEMINI.md: **research-plan-implement.md** / legacy AGENTS.md: **@./workflows/research-plan-implement.md**"

**Location:** `scripts/health-check.sh:203-207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `extract_workflows` on the current global-instructions/CLAUDE.md, AGENTS.md, GEMINI.md and the main-branch AGENTS.md; does not establish the rest of `check_workflow_crossrefs` or behavior on mixed delimiters.

```bash
# scripts/health-check.sh:213-215
    { grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$file" || true; } \
        | sed 's/\*\*//g; s/`//g; s|@\./workflows/||' \
        | sort -u
```

Both delimiters and the optional legacy prefix are in the regex. Executed (the function body `eval`'d from the script), all four files yield the same nine names (`run3.out`, "== extract …"). "CLAUDE.md" here is `GLOBAL_MD="global-instructions/CLAUDE.md"` (`scripts/health-check.sh:54`), which uses backticks, e.g. `` `codebase-onboarding.md` `` (`global-instructions/CLAUDE.md:19`).

**Evidence:** `scripts/health-check.sh:54`, `scripts/health-check.sh:203-216`, `global-instructions/CLAUDE.md:19`, `docs/reviews/execution-logs/fc-final-r3/run3.out`

---

## Claim 9: "CLAUDE.md uses backticks for all filenames (so the result is filtered against workflows/ in the caller); AGENTS.md and GEMINI.md use bold"

**Location:** `scripts/health-check.sh:210-212`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the delimiter style of workflow-style filenames in the three files; does not establish the caller-side filtering sentence (unchanged context, not in this diff).

`grep -cE '\*\*[a-z][-a-z0-9]*\.md\*\*' global-instructions/CLAUDE.md` → `0` (`run3.out`); AGENTS.md and GEMINI.md list entries are bold, e.g. `- **research-plan-implement.md** — …` (`GEMINI.md:9`, identical in AGENTS.md per Claim 1).

**Evidence:** `scripts/health-check.sh:210-212`, `GEMINI.md:9`, `docs/reviews/execution-logs/fc-final-r3/run3.out`

---

## Claim 10: "Strips the first 3 lines (tool-specific headers) from each file, then diffs."

**Location:** `test/agents-gemini-sync.bats:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers test 1's transformation; does not establish that line 3 of each file is always the last header line.

```bash
# test/agents-gemini-sync.bats:19-23
  local agents_body gemini_body
  agents_body=$(tail -n +4 "$AGENTS")
  gemini_body=$(tail -n +4 "$GEMINI")

  if ! diff_output=$(diff <(echo "$agents_body") <(echo "$gemini_body")); then
```

(excerpt ends :23; enclosing @test continues to :28 — read) No prefix stripping remains.

**Evidence:** `test/agents-gemini-sync.bats:15-28`

---

## Claim 11: "The old `@./workflows/*.md` list pulled ~89K tokens of workflow text into every session and subagent here ... global-instructions/CLAUDE.md loads in every project"

**Location:** `test/agents-gemini-sync.bats:32-35`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the token figure (Claim 6 arithmetic) and the global file's install path as documented in health-check.sh and observed in this session; does not establish the install script's staging code, which was not read.

The ~89K figure is Claim 6's 88,899.5 (`run2.out`). For the global file:

```bash
# scripts/health-check.sh:49-53
# The global instructions file lives under global-instructions/ rather than the
# repo root: at the root, Claude Code loads it a second time as this project's
# own instructions on top of the ~/.claude copy the image links (prompt audit
# 2026-09-11, F1). devcontainer-config/install.sh stages it to the payload root,
# so the installed layout is unchanged — only the source path moved.
```

This session's context also shows the global file loaded as `/home/node/.claude/CLAUDE.md` "user's private global instructions for all projects" (paraphrased — no quote available because the evidence is this agent's injected context).

**Evidence:** `test/agents-gemini-sync.bats:30-35`, `scripts/health-check.sh:49-54`, `docs/reviews/execution-logs/fc-final-r3/run2.out`

---

## Claim 12: "An import is `@` followed by a path: `@/abs`, `@./x`, `@../x`, `@~/x`, or a relative `@dir/x` / `@x.md`."

**Location:** `test/agents-gemini-sync.bats:37-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sentence as a description of what `find_imports` matches; does not establish that this is Claude Code's full import grammar (see Claim 3).

The regex alternation maps one-to-one onto the listed forms (quoted in Claim 2, `test/agents-gemini-sync.bats:44`), and each listed form matched in `pos.md` (`run.out` "== pos").

**Evidence:** `test/agents-gemini-sync.bats:37-44`, `docs/reviews/execution-logs/fc-final-r3/run.out`

---

## Claim 13: "The `@` must not follow a word character, so an email address or `foo@bar/baz` is not one."

**Location:** `test/agents-gemini-sync.bats:38-39`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the preceding-character class and the two named consequences; does not establish every email-like or scoped-name form in prose (see note on `@alice/pkg`).

The actual preceding-character class is wider than "word character":

```bash
# test/agents-gemini-sync.bats:44
(^|[^[:alnum:]_.@/-])@
```

It also excludes `.`, `@`, `/` and `-`. Executed on `probe.md`: `x.@./y.md`, `-@./y.md`, `/@./y.md`, `@@./y.md` and `foo@./y.md` all produce no match (`run.out` "== probe": only lines 1, 6, 12, 13, 17, 19, 20 print). The two consequences hold: `someone@example.com`, `foo@bar/baz`, `user@host:/path/x` and `mailto:a@b.com` do not match. Precise version: "must not follow a word character, `.`, `@`, `/` or `-`". Note for readers: `install @alice/pkg from npm` does match, since an npm scope after a space has the `@dir/x` shape (consistent with the stated definition, not a mismatch with this comment).

**Evidence:** `test/agents-gemini-sync.bats:38-44`, `docs/reviews/execution-logs/fc-final-r3/probe.md`, `docs/reviews/execution-logs/fc-final-r3/run.out`

---

## Claim 14: "Inline code spans are removed first: Claude Code does not expand imports inside them."

**Location:** `test/agents-gemini-sync.bats:39-40`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `sed` removal on single- and double-backtick spans and fenced blocks; does not establish Claude Code's own code-span rule (external).

```bash
# test/agents-gemini-sync.bats:43
  sed -E 's/`[^`]*`//g' "$1" \
```

This removes single-backtick spans (``use `@./x.md` in a code span`` → no match, `run.out` "== neg"). A double-backtick span is not removed: ``` ``@./double.md`` ``` matches (`run.out` "== probe", line 19), because the pattern deletes the two empty `` `` `` pairs and leaves the contents. Fenced code blocks are not code spans and are not removed either: `@./fenced.md` between ```` ``` ```` fences matches (line 17). Precise version: "single-backtick inline code spans are removed first". Neither form currently appears in AGENTS.md or the global file (test 3 passes).

**Evidence:** `test/agents-gemini-sync.bats:43`, `docs/reviews/execution-logs/fc-final-r3/probe.md`, `docs/reviews/execution-logs/fc-final-r3/run.out`

---

## Claim 15: "the import finder catches every @-import form and nothing else" (test name)

**Location:** `test/agents-gemini-sync.bats:47`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the finder's behavior on the probe lines and what the test asserts; does not establish Claude Code's grammar for `@README`/`@package.json` or fenced blocks (external; the Medium confidence rests on it), nor that the misses are currently exploitable (neither guarded file contains such a line).

Both halves are refuted by execution. "Every": `@README`, `@package.json` and `@x.MD` do not match (Claim 3). "Nothing else": text inside a fenced code block and inside a double-backtick span does match (Claim 14), though the finder's own comment says imports inside code are not expanded. The test asserts only its own 7 positives and 5 negatives:

```bash
# test/agents-gemini-sync.bats:65-68
  run find_imports "$pos"
  [ "$(printf '%s\n' "$output" | grep -c .)" -eq 7 ] || { echo "missed imports; matched:"; echo "$output"; return 1; }
  run find_imports "$neg"
  [ -z "$output" ] || { echo "false positives:"; echo "$output"; return 1; }
```

(excerpt ends :68; enclosing @test ends :69 — read) A green result establishes "catches these 7 forms and none of these 5", not "every form and nothing else". Pass 1's r1 named `@README` as a missed form (`docs/reviews/code-fact-check-report.md:61`); the widened regex still misses it. A precise name would be e.g. "the import finder matches the listed @-import forms and skips the listed non-imports".

**Evidence:** `test/agents-gemini-sync.bats:44-69`, `docs/reviews/execution-logs/fc-final-r3/probe.md`, `docs/reviews/execution-logs/fc-final-r3/run.out`, `docs/reviews/code-fact-check-report.md:61`

---

## Claim 16: The synthetic-case test asserts exactly 7 matches on the positive file and none on the negative, each positive matched for the intended form

**Location:** `test/agents-gemini-sync.bats:47-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 7/0 counts and which regex branch each positive line hits; does not establish coverage beyond these 12 lines (Claim 15).

`find_imports pos.md` printed exactly lines 1-7 (rc=0); `find_imports neg.md` printed nothing (rc=1) (`run.out`). Branch per line, from the regex at `test/agents-gemini-sync.bats:44`: line 1 `**@./workflows/…` — `\.{1,2}/` after `*`; line 2 `@README.md` — name + `.md$` at `^`; line 3 `@workflows/x.md` — name + `/`; line 4 `@~/.aws/…` — `~?/`; line 5 `(@./x.md)` — `\.{1,2}/` after `(`; line 6 `"@../y.md"` — `\.{1,2}/` after `"`; line 7 `[@/abs/z.md]` — `~?/` after `[`. The count is of matching lines (`grep -c .`), and each positive line holds one import, so lines = imports. `bats` reported `ok 2` (`run.out`).

**Evidence:** `test/agents-gemini-sync.bats:47-69`, `docs/reviews/execution-logs/fc-final-r3/pos.md`, `docs/reviews/execution-logs/fc-final-r3/neg.md`, `docs/reviews/execution-logs/fc-final-r3/run.out`

---

## Claim 17: "AGENTS.md and the global instructions have no @-imports" (test 3 name and assertion)

**Location:** `test/agents-gemini-sync.bats:71-81`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both files at 7c2253a under the finder's definition; does not establish forms the finder misses (Claim 3), and does not establish that the test fails if global-instructions/CLAUDE.md is missing or unreadable — it passes silently in that case.

`find_imports AGENTS.md` and `find_imports global-instructions/CLAUDE.md` both return rc=1 with no output (`run.out` "== AGENTS", "== GLOBAL"); the global file's only `@` is ``claude plugin install <name>@claude-plugins-official`` inside backticks (`global-instructions/CLAUDE.md:76`). `bats` reported `ok 3`. Residue, executed: `find_imports /nonexistent/x.md` returns rc=1 with only sed's stderr message (`run3.out` "== missing-file behaviour"), so `if matches=$(find_imports "$f")` (`:74`) is false and the file counts as clean.

**Evidence:** `test/agents-gemini-sync.bats:71-81`, `global-instructions/CLAUDE.md:76`, `docs/reviews/execution-logs/fc-final-r3/run.out`, `docs/reviews/execution-logs/fc-final-r3/run3.out`

---

## Claim 18: Commit 5ee8315: "put ~358 KB (~85K tokens) of workflow text into every session" and "gains a guard that fails on any @-import in AGENTS.md"

**Location:** `5ee8315` (commit message)
**Type:** Configuration / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the token figure and the guard regex as of commit 5ee8315; does not establish anything about HEAD, where both were corrected by 7b43db2 (Claims 21-22).

Token figure: 355,598 chars / 4 = 88,899.5 and 358,414 bytes / 4 = 89,603.5 (`run2.out`), so ~85K is low by either measure. Guard: at 5ee8315 the regex was

```bash
# 5ee8315:test/agents-gemini-sync.bats:35
  if matches=$(grep -nE '(^|[[:space:]*`])@\.{0,2}/' "$AGENTS"); then
```

(`run3.out` "== 5ee8315 regex"), which matches only `@/`, `@./`, `@../` after start, whitespace, `*` or a backtick — not "any @-import". Both parts are Incorrect; 7b43db2's message acknowledges and corrects them. Commit messages are immutable, so this is a historical record only.

**Evidence:** `docs/reviews/execution-logs/fc-final-r3/run2.out`, `docs/reviews/execution-logs/fc-final-r3/run3.out`

---

## Claim 19: Commit 5ee8315: "Verified: scripts/health-check.sh, \"All checks passed.\""

**Location:** `5ee8315` (commit message)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing about the gate's result; the brief for this pass forbids running `scripts/health-check.sh`, and the claim concerns a past commit's tree.

Execution required but blocked by the pass's constraints (paraphrased — no quote available because the claim is an executable guarantee that was not run). The components this replicate did run — the one bats file (all 3 ok) and `extract_workflows` on the three files (Claim 8) — pass at 7c2253a.

**Evidence:** `scripts/health-check.sh:203-240`, `docs/reviews/execution-logs/fc-final-r3/run.out`

---

## Claim 20: Commit 7b43db2 subject: "catch every @-import form"

**Location:** `7b43db2` (commit message)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the finder at 7b43db2 (unchanged through 7c2253a); same residue as Claim 15.

Same finding as Claim 15: `@README`, `@package.json` and `@x.MD` are not caught (`run.out` "== probe"). The body's own enumeration (Claim 21) is accurate; the subject's "every" is not.

**Evidence:** `test/agents-gemini-sync.bats:44`, `docs/reviews/execution-logs/fc-final-r3/run.out`

---

## Claim 21: Commit 7b43db2 body: "the regex caught only @/, @./, @../. find_imports now catches @~/, @dir/x and @x.md too, ignores email-like foo@bar and inline code spans, and a synthetic-case test pins exactly what it matches (7 positives, 5 negatives). Still catches all 9 lines of the previous AGENTS.md."

**Location:** `7b43db2` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old regex's forms, the new forms, the 7/5 synthetic counts and the nine old AGENTS.md lines; "inline code spans" holds for single-backtick spans only (Claim 14), and "pins exactly what it matches" holds for those 12 lines, not in general (Claim 15).

Old regex (quoted in Claim 18) matches only `@/`, `@./`, `@../`. New forms: `pos.md` lines 2-4 (Claim 16). Counts: `pos.md` has 7 lines, `neg.md` 5 (`test/agents-gemini-sync.bats:49-64`). Old AGENTS.md: `find_imports` on `git show main:AGENTS.md` printed lines 9-16 and 18, nine lines, rc=0; `grep -c '@\./workflows'` = 9 (`run.out` "== old AGENTS").

**Evidence:** `test/agents-gemini-sync.bats:41-69`, `docs/reviews/execution-logs/fc-final-r3/run.out`, `docs/reviews/execution-logs/fc-final-r3/run3.out`

---

## Claim 22: Commit 7b43db2 body: "The guard now also covers global-instructions/CLAUDE.md, which loads in every project" and "~85K -> ~89K tokens (355,598 chars / 4)"; "health-check extract_workflows comment: CLAUDE.md uses backticks"

**Location:** `7b43db2` (commit message)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file list in test 3, the character count and arithmetic, and the health-check comment edit; does not establish the missing-file case (Claim 17).

Test 3 loops over both files (`test/agents-gemini-sync.bats:73`, quoted in Claim 2). UTF-8 character count of the nine files is exactly 355,598 (`run2.out`), and 355,598 / 4 = 88,899.5 ≈ 89K. The comment now reads `#   CLAUDE.md:            `research-plan-implement.md`` (`scripts/health-check.sh:205`), matching the global file's backticks (Claim 9).

**Evidence:** `test/agents-gemini-sync.bats:73`, `scripts/health-check.sh:205`, `docs/reviews/execution-logs/fc-final-r3/run2.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 15** (`test/agents-gemini-sync.bats:47`): test name says "every @-import form and nothing else"; the finder misses `@README`, `@package.json`, `@x.MD` and matches fenced-block and double-backtick content. Narrow the name to the listed forms, or widen the finder.
- **Claim 18** (`5ee8315`): "~85K tokens" (actual ~89K) and "fails on any @-import" (regex covered only `@/`, `@./`, `@../`); historical, already corrected by 7b43db2.
- **Claim 20** (`7b43db2`): subject "catch every @-import form"; same gap as Claim 15. Historical (immutable message).

### Mostly Accurate
- **Claim 3** (`docs/decisions/log.md:88`): "fails on any `@path` import" — the enumeration is exact, "any" is not (`@README`, `@package.json` not caught).
- **Claim 13** (`test/agents-gemini-sync.bats:38-39`): preceding-character class also excludes `.`, `@`, `/`, `-`, not only word characters.
- **Claim 14** (`test/agents-gemini-sync.bats:39-40`): only single-backtick spans are removed; double-backtick spans and fenced blocks are still scanned.

### Unverifiable
- **Claim 19** (`5ee8315`): "health-check.sh: All checks passed" — needs a health-check run, forbidden in this pass.

---

## Goal-Alignment Note
- **Answered:** Every claim the brief flagged was checked by execution: row 65's enumeration and file coverage (Verified), the "any"/"every" universals (Mostly accurate in row 65; Incorrect in the test name and 7b43db2's subject), the word-character comment (Mostly accurate), the 7/0 synthetic counts and per-line branches (Verified), ~89K at chars/4 (Verified: 355,598 chars), 7b43db2's 7/5 and nine-line claims (Verified), and the health-check comment (Verified). Adversarial probes found misses (`@README`, `@package.json`, `@x.MD`) and false positives (fenced blocks, double-backtick spans, `@alice/pkg` by design).
- **Out of scope:** Did not run `scripts/health-check.sh` or the full suite (brief), so Claim 19 is Unverifiable. Did not fetch Claude Code's import-grammar docs (no egress); Claims 3, 15 and 20 rest on the recalled `@README`/`@package.json` doc example, hence Medium confidence.
- **Escalate:** The blocking-grade question for the orchestrator is whether the remaining gap (extensionless or non-`.md` bare imports) is fixed or the test name and row 65 are narrowed. The practical exposure is nil today: neither guarded file contains such a line. The missing-file silent pass in test 3 (Claim 17 residue) is a note, not a claim mismatch. Probe logs are new untracked files under `docs/reviews/execution-logs/fc-final-r3/`; no tracked file other than this report was edited, and no processes remain.
