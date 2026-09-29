Commit: 7c2253a

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-agents-md (branch fix/agents-md-no-imports)
**Scope:** Final confirming pass, replicate r2: `git diff main...HEAD -- . ':(exclude)docs/reviews'` (AGENTS.md, docs/decisions/log.md, scripts/health-check.sh, test/agents-gemini-sync.bats) plus the commit messages in `git log main..HEAD` (5ee8315, 7b43db2; 64671f0 and 7c2253a only touch docs/reviews)
**Checked:** 2026-09-29
**Total claims checked:** 19
**Summary:** 13 verified, 1 mostly accurate, 0 stale, 5 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The closest logged class is "a specific measured value quoted from a checked-in artifact set that does not contain it". I recomputed every measured value in scope (7/5 synthetic counts, 9 legacy lines, 358 KB, 355,598 chars, ~89K). All match except the superseded ~85K figure in commit 5ee8315 (Claim 18), which was a rounding error, not a fabricated value.

**Ground truth used for "what Claude Code treats as an import".** The sandbox has no network access, so I read the import extractor in the installed Claude Code binary (`claude --version` → `2.1.284 (Claude Code)`), captured in `docs/reviews/execution-logs/fc-final-r2-misc.txt`:

```js
// claude.exe 2.1.284, function yRn (memory-file import extractor), excerpt
let S=/(?:^|\s)@((?:[^\s\\]|\\ )+)/g ...
if(!fC(M)&&(M.startsWith("./")||M.startsWith("~/")||M.startsWith("/")&&M!=="/"||
   !M.startsWith("@")&&!M.match(/^[#%^&*()]+/)&&M.match(/^[a-zA-Z0-9._-]/))){ ... r.add(K)}
...
function g(h){for(let S of h){if(S.type==="code"||S.type==="codespan")continue; ... if(S.type==="text")s(S.text||""); if(S.tokens)g(S.tokens) ...
```

(excerpt ends inside `g`; the enclosing `yRn` continues to `return g(e),[...r]}` — read.) So in this version an import is `@` at the start of a markdown **text token** or after whitespace, followed by any token starting with `./`, `~/`, `/`, or `[A-Za-z0-9._-]`. Code blocks and code spans are skipped. Claims 2b, 10 and 13b rest on this reading of minified code from one version, so their confidence is Medium.

---

## Claim 1: "Its workflow list now matches GEMINI.md byte for byte below the header"

**Location:** `docs/decisions/log.md:88`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers AGENTS.md vs GEMINI.md from line 4 to EOF at commit 7c2253a; does not establish that lines 1-3 (the tool-specific headers) match, which they are not meant to.

`cmp` on `tail -n +4` of each file printed `identical below line 3`. Command: `timeout 180 bash docs/reviews/execution-logs/fc-final-r2-misc.sh`, cwd `/workspace/.claude/wt-agents-md`, exit 0, 2026-09-29T07:37:08Z. The sync test also passes (`ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)`, `docs/reviews/execution-logs/fc-final-r2-bats.txt`).

**Evidence:** `AGENTS.md:9-18`, `GEMINI.md`, docs/reviews/execution-logs/fc-final-r2-misc.txt, docs/reviews/execution-logs/fc-final-r2-bats.txt

---

## Claim 2a: "`test/agents-gemini-sync.bats` fails on … `@path` import (`@/`, `@./`, `@../`, `@~/`, `@dir/x`, `@x.md`; not inside code spans) in AGENTS.md or `global-instructions/CLAUDE.md`, with a synthetic-case test pinning what the finder matches"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed form being matched, inline code spans being excluded, both files being scanned, and the synthetic test existing; does not establish that the list is complete (Claim 2b) or that the finder has no false positives (Claim 13b).

The finder:

```bash
# test/agents-gemini-sync.bats:41-45
find_imports() {
  # shellcheck disable=SC2016  # the backticks are literal regex characters
  sed -E 's/`[^`]*`//g' "$1" \
    | grep -nE '(^|[^[:alnum:]_.@/-])@(~?/|\.{1,2}/|[[:alnum:]_][[:alnum:]_.-]*(/|\.md([^[:alnum:]]|$)))'
}
```

I replayed it verbatim in `fc-final-r2-probes.sh`. It matched `@/abs/z.md`, `@./x.md`, `@../y.md`, `@~/.aws/credentials`, `@workflows/x.md`, `@README.md` and `@CLAUDE.md`, and did not match `` `@./x.md` `` in a code span. The file loop is `for f in "$AGENTS" "$REPO_ROOT/global-instructions/CLAUDE.md"; do` (`test/agents-gemini-sync.bats:73`). Command: `timeout 60 bash docs/reviews/execution-logs/fc-final-r2-probes.sh`, cwd worktree root, exit 0, 2026-09-29T07:35:42Z.

**Evidence:** `test/agents-gemini-sync.bats:41-45`, `test/agents-gemini-sync.bats:47-69`, `test/agents-gemini-sync.bats:71-81`, docs/reviews/execution-logs/fc-final-r2-probes.txt

---

## Claim 2b: "`test/agents-gemini-sync.bats` fails on any `@path` import"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the finder's output on relative imports that don't end in `.md`, `.`-prefixed paths and uppercase `.MD`; does not establish that any such import exists in AGENTS.md or the global instructions today (none does, Claim 14), or that Claude Code versions other than 2.1.284 accept these forms.

The single-line probes printed:

```
-  | @package.json
-  | @README
-  | @notes.txt
-  | @.claude/settings.md
-  | @x.MD
```

(`-` = not matched; `docs/reviews/execution-logs/fc-final-r2-probes.txt`.) Claude Code 2.1.284 accepts all five as imports: each starts with a character in `M.match(/^[a-zA-Z0-9._-]/)` and is not excluded by `fC`, `^[#%^&*()]+` or a leading `@` (quoted above). The finder's relative branch only accepts a token that starts with `[[:alnum:]_]` and then has a `/` or ends in lowercase `.md`, so `@package.json`, `@README`, `@notes.txt` and `@x.MD` fall through. `@.claude/...` falls through because `\.{1,2}/` needs `/` right after the dots. "Any" is therefore wrong. The enumeration in the same sentence (Claim 2a) is accurate as a list of what is caught, but it is not a complete list of import forms.

**Evidence:** `test/agents-gemini-sync.bats:44`, docs/reviews/execution-logs/fc-final-r2-probes.txt, docs/reviews/execution-logs/fc-final-r2-misc.txt

---

## Claim 3: "Claude Code loads AGENTS.md as this repo's project instructions and expands `@` imports inline: the nine `@./workflows/*.md` entries put … workflow text into every session and subagent here"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers Claude Code 2.1.284's extractor accepting the legacy `- **@./workflows/x.md**` form, and this subagent session receiving main's AGENTS.md with the workflows expanded; does not establish behavior in other Claude Code versions or whether a root CLAUDE.md would take precedence over AGENTS.md.

The extractor walks marked tokens and runs the regex on each `text` token, recursing into `S.tokens` (quoted in the header). The legacy line is a list item containing a `**strong**` whose inner text token is `@./workflows/pr-prep.md`, so the regex's `^` matches and the `./` prefix branch accepts it. (Paraphrased — no quote available because the tokenization comes from the marked library's runtime behavior, not from a string in the binary.) The binary also has a dedicated AGENTS.md probe, `let n=xf(e,"AGENTS.md")` in `vRn` (`fc-final-r2-misc` grep context). Direct observation: this subagent's context contained "Contents of /workspace/AGENTS.md (project instructions, checked into the codebase)", followed by the full text of `workflows/research-plan-implement.md` and the other eight files. That is main's AGENTS.md with its imports expanded, reaching a subagent. (Paraphrased — no quote available because the evidence is this agent's own injected system context, not a repository file.)

**Evidence:** docs/reviews/execution-logs/fc-final-r2-misc.txt, `git show main:AGENTS.md` lines 9-18

---

## Claim 4: "~358 KB (~89K tokens at chars/4) of workflow text"

**Location:** `docs/decisions/log.md:88` (same figure: `test/agents-gemini-sync.bats:32` "~89K tokens")
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte and character totals of the nine files `git show main:AGENTS.md` imports, as they stand on main; does not establish actual model token counts, which chars/4 only approximates.

```
total bytes 358414 KB(1000) 358.414 KiB 350.013671875 chars 355598 chars/4 88899.5
```

Per-file sizes range from `parallel-worktrees.md bytes=7596` to `divergent-design.md bytes=80340`. 358 KB is decimal bytes (358,414), and 355,598 / 4 = 88,899.5 ≈ 89K. The command is in `fc-final-r2-tokens.txt`: for each file imported by `git show main:AGENTS.md`, `wc -c` plus a python `len()`. cwd worktree root, exit 0, 2026-09-29T07:36:37Z.

**Evidence:** docs/reviews/execution-logs/fc-final-r2-tokens.txt

---

## Claim 5: "`hooks/log-usage.sh` cannot see `@` loads, so workflow use went unmeasured"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which tool events the hook records; does not establish whether other usage instrumentation exists.

```
# hooks/log-usage.sh:7
# COVERAGE: only Skill, Read and Agent tool calls are seen. A workflow or skill
```

Workflow consultation is recorded only on a `Read)` of a path matching `*/workflows/*` (`hooks/log-usage.sh:59,66`). An `@` import is expanded into context without any tool call, so the hook never sees it.

**Evidence:** `hooks/log-usage.sh:4-13`, `hooks/log-usage.sh:52-66`

---

## Claim 6: "The sections AGENTS.md shares with the global instructions (Context Packing, Shared Thoughts, General Principles) stay"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three headings being present in both files at HEAD; does not establish that the section bodies are identical between the two files.

`grep -n '^## ' AGENTS.md` printed `41:## Context Packing`, `52:## Shared Thoughts` and `65:## General Principles`. The global file has the same headings at `126`, `153` and `303` (`fc-final-r2-misc.txt`). The branch diff leaves those AGENTS.md lines untouched.

**Evidence:** `AGENTS.md:41`, `AGENTS.md:52`, `AGENTS.md:65`, `global-instructions/CLAUDE.md:126`, docs/reviews/execution-logs/fc-final-r2-misc.txt

---

## Claim 7: "Handles three syntaxes: CLAUDE.md: `` `research-plan-implement.md` ``; AGENTS.md, GEMINI.md: `**research-plan-implement.md**`; legacy AGENTS.md: `**@./workflows/research-plan-implement.md**`" (and unchanged `:210` "CLAUDE.md uses backticks for all filenames")

**Location:** `scripts/health-check.sh:203-207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `extract_workflows` on `$GLOBAL_MD`, AGENTS.md and GEMINI.md at HEAD and on main's AGENTS.md; does not establish the cross-file consistency check at `:261` beyond what these outputs imply.

```bash
# scripts/health-check.sh:214-216
    { grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$file" || true; } \
        | sed 's/\*\*//g; s/`//g; s|@\./workflows/||' \
        | sort -u
```

`GLOBAL_MD="global-instructions/CLAUDE.md"` (`:54`). In the replay, every match in the global file used a backtick delimiter, and it has `0` bold `.md` filenames. AGENTS.md, GEMINI.md and legacy main:AGENTS.md each had `9 **` matches. All four files produced the same nine workflow names. Command: `timeout 60 bash docs/reviews/execution-logs/fc-final-r2-extract.sh`, cwd worktree root, exit 0, 2026-09-29T07:36:58Z.

**Evidence:** `scripts/health-check.sh:54`, `scripts/health-check.sh:203-217`, docs/reviews/execution-logs/fc-final-r2-extract.txt

---

## Claim 8: "Strips the first 3 lines (tool-specific headers) from each file, then diffs."

**Location:** `test/agents-gemini-sync.bats:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers test 1's body; does not establish that `echo "$var"` preserves trailing blank lines (command substitution strips them, so trailing-newline drift goes undetected; Claim 1's `cmp` shows none exists now).

```bash
# test/agents-gemini-sync.bats:20-22
  agents_body=$(tail -n +4 "$AGENTS")
  gemini_body=$(tail -n +4 "$GEMINI")

  if ! diff_output=$(diff <(echo "$agents_body") <(echo "$gemini_body")); then
```

(excerpt ends :22; enclosing test continues to :27 — read.)

**Evidence:** `test/agents-gemini-sync.bats:15-27`

---

## Claim 9: "The old `@./workflows/*.md` list pulled ~89K tokens of workflow text into every session and subagent here, invisible to the usage hook. global-instructions/CLAUDE.md loads in every project, so it is held to the same rule."

**Location:** `test/agents-gemini-sync.bats:30-35`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the token figure (Claim 4), the hook's blindness (Claim 5), subagent loading (Claim 3), and this install's `~/.claude/CLAUDE.md` resolving to a byte-identical copy of the global file; does not establish that every installation deploys the global file.

`readlink -f ~/.claude/CLAUDE.md` gives `/opt/claude-workflows/CLAUDE.md`, and `cmp` against `global-instructions/CLAUDE.md` printed `same`. That file is loaded as the user's global instructions in every project on this install. (Paraphrased — no quote available because the evidence is a filesystem link and a cmp result run inline, not a file snippet.)

**Evidence:** `test/agents-gemini-sync.bats:30-35`, docs/reviews/execution-logs/fc-final-r2-tokens.txt, docs/reviews/execution-logs/fc-final-r2-misc.txt

---

## Claim 10: "An import is `@` followed by a path: `@/abs`, `@./x`, `@../x`, `@~/x`, or a relative `@dir/x` / `@x.md`."

**Location:** `test/agents-gemini-sync.bats:37-38`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the comment read as a definition of what Claude Code (2.1.284) expands; does not establish that the finder fails to implement its own stated definition (it implements it, Claim 2a).

Claude Code 2.1.284 accepts any `@token` whose first character matches `^[a-zA-Z0-9._-]`, so `@package.json`, `@README` and `@.claude/x.md` are imports too (header excerpt). It also requires `(?:^|\s)` before the `@`, so `(@./x.md)`, `"@../y.md"` and `[@/abs/z.md]` are not imports in that version. The comment's definition is too narrow on the path side and too broad on the preceding-character side. A reader who adds an `@notes.txt` line and trusts this definition will not expect the text to be loaded.

**Evidence:** `test/agents-gemini-sync.bats:37-40`, docs/reviews/execution-logs/fc-final-r2-misc.txt, docs/reviews/execution-logs/fc-final-r2-probes.txt

---

## Claim 11: "The `@` must not follow a word character, so an email address or `foo@bar/baz` is not one."

**Location:** `test/agents-gemini-sync.bats:38-39`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex's preceding-character class and the email / `foo@bar/baz` / `mailto:` / `user@host:/path` probes; does not establish that the extra exclusions match Claude Code's rule (Claude Code requires start-of-token or whitespace, which is stricter still).

The preceding class is `(^|[^[:alnum:]_.@/-])` (`test/agents-gemini-sync.bats:44`). That excludes word characters as the comment says, and also `.`, `@`, `/` and `-`. The probes confirm the conclusion: `someone@example.com`, `foo@bar/baz`, `[mail me](mailto:me@example.com)`, `<me@example.com>` and `ssh user@host:/path` were not matched. They also show the unstated exclusions: `x-@./y.md`, `a/@./y.md`, `.@./y.md` and `@@./y.md` were not matched either (`fc-final-r2-probes.txt`). A precise version would say "must not follow a word character or one of `. @ / -`". The mechanism is incomplete, not refuted.

**Evidence:** `test/agents-gemini-sync.bats:44`, docs/reviews/execution-logs/fc-final-r2-probes.txt

---

## Claim 12: "Inline code spans are removed first: Claude Code does not expand imports inside them."

**Location:** `test/agents-gemini-sync.bats:39-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers single-backtick spans on one line and Claude Code 2.1.284 skipping `codespan` tokens; does not establish handling of fenced code blocks (the finder still flags `@./inside-fence.md` inside a fence, which Claude Code skips as `code`), double-backtick spans (`` ``@./y.md`` `` is flagged), or spans that break across lines.

The finder runs `sed -E 's/`[^`]*`//g'` before grep (`:43`), and `use `@./x.md` in a code span` was not matched. Claude Code's walker does `if(S.type==="code"||S.type==="codespan")continue;` (header excerpt). The residue appears in the probes as `2:@./inside-fence.md` with `rc=0`, and as `M  | ``@./y.md``` (`fc-final-r2-probes.txt`). Both are false positives, which make the guard fail, not miss.

**Evidence:** `test/agents-gemini-sync.bats:43`, docs/reviews/execution-logs/fc-final-r2-probes.txt, docs/reviews/execution-logs/fc-final-r2-misc.txt

---

## Claim 13a: Synthetic test asserts exactly 7 matches on the positive file and none on the negative, each positive matched as intended

**Location:** `test/agents-gemini-sync.bats:47-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and which regex alternative matches each positive line; does not establish that each positive is a real Claude Code import (Claim 13b).

The replay printed `count=7` and, for the negatives, `rc=1 (1 = no match)`. `grep -o` shows the branch each positive hits: `1:*@./`, `2:@README.md`, `3:@workflows/`, `4: @~/`, `5:(@./`, `6:"@../`, `7:[@/`. Each line matches through its intended alternative, one match per line, so `grep -c .` counts lines correctly. bats ran `ok 2 the import finder catches every @-import form and nothing else`, exit 0, 2026-09-29T07:36:59Z.

**Evidence:** `test/agents-gemini-sync.bats:47-69`, docs/reviews/execution-logs/fc-final-r2-probes.txt, docs/reviews/execution-logs/fc-final-r2-bats.txt

---

## Claim 13b: "the import finder catches every @-import form and nothing else"

**Location:** `test/agents-gemini-sync.bats:47` (same claim: commit 7b43db2 subject "catch every @-import form")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers both halves against Claude Code 2.1.284's extractor; does not establish whether the gaps matter in practice for the two guarded files (neither contains a missed form today, Claim 14).

"Every": `@package.json`, `@README`, `@notes.txt`, `@.claude/settings.md` and `@x.MD` are not matched (Claim 2b), but Claude Code 2.1.284 imports each of them. "Nothing else": the test's own positives 5-7, `(@./x.md)`, `"@../y.md"` and `[@/abs/z.md]`, have the `@` after `(`, `"` or `[`, so they fail `(?:^|\s)@` and Claude Code does not import them. Lines inside fenced code blocks are also flagged, although Claude Code skips them (Claim 12). The failures run in the safe direction on the "nothing else" side, but the test name and commit subject overstate completeness in both directions.

**Evidence:** `test/agents-gemini-sync.bats:44`, `test/agents-gemini-sync.bats:47-59`, docs/reviews/execution-logs/fc-final-r2-probes.txt, docs/reviews/execution-logs/fc-final-r2-misc.txt

---

## Claim 14: "AGENTS.md and the global instructions have no @-imports"

**Location:** `test/agents-gemini-sync.bats:71-81`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the finder's result on both files at 7c2253a, plus a manual check of every raw `@` in them against Claude Code's rule; does not establish future edits.

`find_imports` returned `rc=1` for AGENTS.md, global-instructions/CLAUDE.md and GEMINI.md. The only `@` in either guarded file is `global-instructions/CLAUDE.md:76`, `` `claude plugin install <name>@claude-plugins-official` ``. It sits inside a code span and follows `>`, so it is not an import under Claude Code's rule either. bats `ok 3`.

**Evidence:** `test/agents-gemini-sync.bats:71-81`, `global-instructions/CLAUDE.md:76`, docs/reviews/execution-logs/fc-final-r2-probes.txt, docs/reviews/execution-logs/fc-final-r2-bats.txt

---

## Claim 15: "put ~358 KB (~85K tokens) of workflow text into every session in this repo"

**Location:** commit 5ee8315 message body
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the token figure only; the byte figure is right (Claim 4). Commit 7b43db2 already corrects it to ~89K in both the log row and the test comment.

355,598 chars / 4 = 88,899.5 (`fc-final-r2-tokens.txt`), not ~85K. That is a 4.6% understatement. It lives in an immutable commit message and has been superseded, so it needs no fix; I record it for completeness.

**Evidence:** docs/reviews/execution-logs/fc-final-r2-tokens.txt

---

## Claim 16: Commit-message facts: 5ee8315 "verified to fail on the previous AGENTS.md"; 7b43db2 "the regex caught only @/, @./, @../", "7 positives, 5 negatives", "Still catches all 9 lines of the previous AGENTS.md", "ignores email-like foo@bar and inline code spans", "now also covers global-instructions/CLAUDE.md", "355,598 chars / 4", "health-check extract_workflows comment: CLAUDE.md uses backticks"

**Location:** commit messages 5ee8315, 7b43db2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed atom; does not cover the 7b43db2 subject's "every @-import form" (Claim 13b) or 5ee8315's "~85K" (Claim 15).

The 5ee8315 guard was `grep -nE '(^|[[:space:]*`])@\.{0,2}/' "$AGENTS"` (`git show 5ee8315:test/agents-gemini-sync.bats:35`). It only matches `@/`, `@./` and `@../`, and it matches `**@./` because `*` is in its class. The current finder on `git show main:AGENTS.md` printed 9 lines (`count=9`). The synthetic heredocs have 7 and 5 lines (`:49-55`, `:57-63`). The rest is covered by Claims 4, 7, 11, 12 and 14.

**Evidence:** `test/agents-gemini-sync.bats:49-63`, docs/reviews/execution-logs/fc-final-r2-probes.txt, docs/reviews/execution-logs/fc-final-r2-tokens.txt, docs/reviews/execution-logs/fc-final-r2-extract.txt

---

## Claim 17: "fix(agents-md): catch every @-import form; correct token figure"

**Location:** commit 7b43db2 subject
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the "every @-import form" half, which shares Claim 13b's evidence; the "correct token figure" half is Verified (Claim 4).

The finder does not match `@package.json`, `@README`, `@notes.txt`, `@.claude/settings.md` or `@x.MD`, all of which Claude Code 2.1.284 imports (Claim 2b). "Every" overstates the change: it widened the guard from three prefix forms to six, not to every form.

**Evidence:** docs/reviews/execution-logs/fc-final-r2-probes.txt, docs/reviews/execution-logs/fc-final-r2-misc.txt

---

## Claims Requiring Attention

### Incorrect
- **Claim 2b** (`docs/decisions/log.md:88`): "fails on any `@path` import" is wrong. Relative imports not ending in lowercase `.md` and not containing `/` (`@package.json`, `@README`, `@notes.txt`, `@x.MD`), and `.`-prefixed paths (`@.claude/x.md`), are not caught. Drop "any", or widen the finder.
- **Claim 10** (`test/agents-gemini-sync.bats:37-38`): the definition of an import doesn't match Claude Code 2.1.284, which accepts any `@token` starting `[A-Za-z0-9._-]` after start or whitespace, and does not import after `(`, `"` or `[`.
- **Claim 13b** (`test/agents-gemini-sync.bats:47`): the test name "every @-import form and nothing else" overstates in both directions: it misses the forms above, and it counts `(@./x.md)`, `"@../y.md"`, `[@/abs/z.md]` and fenced-block lines as imports.
- **Claim 15** (commit 5ee8315): "~85K tokens" should be ~89K; already corrected in 7b43db2. Informational, since the message is immutable.
- **Claim 17** (commit 7b43db2 subject): "catch every @-import form" has the same gap as Claim 2b. Immutable, so fix the claim where it lives in files (Claims 2b, 13b).

### Stale
(none)

### Mostly Accurate
- **Claim 11** (`test/agents-gemini-sync.bats:38-39`): the preceding-character exclusion also covers `.`, `@`, `/` and `-`, not only word characters.

### Unverifiable
(none)

## Goal-Alignment Note
- **Answered:** Every claim the brief listed. Log row 65's enumeration and file coverage (Verified), the "any"/"every" completeness (Incorrect, executed probes plus the installed Claude Code 2.1.284 extractor source), the word-character comment (Mostly accurate), the 7/0 synthetic counts with the reason each line matches (Verified), ~89K recomputed from main's nine files (Verified: 358,414 bytes, 355,598 chars), commit 7b43db2's facts (Verified, apart from its subject), and the health-check comment at `:203-207` (Verified against all three files plus legacy AGENTS.md). The targeted bats file passed 3/3.
- **Out of scope:** Code quality, and whether the guard's gaps are worth closing. The current guarded files contain no missed form, so the gaps are overclaims, not live leaks. I did not run health-check.sh or the full suite, per the brief.
- **Escalate:** The Incorrect verdicts rest on reading minified source from one Claude Code version (2.1.284), because the sandbox has no network access to the docs. The code-span skip and the `(?:^|\s)@` rule came from that same source. If the orchestrator wants the finder aligned with Claude Code rather than the claims narrowed, that alignment is a design choice for the author. I created untracked probe and log files under `docs/reviews/execution-logs/fc-final-r2-*`. All probe processes ran under `timeout` and have exited.
