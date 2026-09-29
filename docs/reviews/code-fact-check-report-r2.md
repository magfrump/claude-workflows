Commit: 832932a

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-agents-md (branch `fix/agents-md-no-imports`)
**Scope:** `git diff main...HEAD -- . ':(exclude)docs/reviews'` (AGENTS.md, docs/decisions/log.md, scripts/health-check.sh, test/agents-gemini-sync.bats) plus the commit messages in `git log main..HEAD`. Final confirming pass, replicate 2 of 3.
**Checked:** 2026-09-29
**Total claims checked:** 18
**Summary:** 10 verified, 7 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

---

**Ground truth for "what Claude Code imports".** `claude --version` prints `2.1.284 (Claude Code)` (`docs/reviews/execution-logs/fc-final2-r2-misc.txt`). I did not read the binary myself: the harness's auto-mode classifier denied my grep of `claude.exe`. So the grammar below is the extractor excerpt a previous replicate captured from the same 2.1.284 binary, committed in 832932a. This is secondhand but reproducible:

```js
// docs/reviews/execution-logs/fc-final-r2-misc.txt:28 (claude.exe 2.1.284, function yRn), excerpt
let S=/(?:^|\s)@((?:[^\s\\]|\\ )+)/g ... let F=M.indexOf("#");if(F!==-1)M=M.substring(0,F);if(!M)continue;
... if(!fC(M)&&(M.startsWith("./")||M.startsWith("~/")||M.startsWith("/")&&M!=="/"||
   !M.startsWith("@")&&!M.match(/^[#%^&*()]+/)&&M.match(/^[a-zA-Z0-9._-]/))) ...
function g(h){for(let S of h){if(S.type==="code"||S.type==="codespan")continue;
 if(S.type==="html"){ ... strip <!--...--> then s(W) ...}
 if(S.type==="text")s(S.text||"");if(S.tokens)g(S.tokens);if(S.items)g(S.items)}}
(excerpt ends inside yRn; the rest of the function is `return g(e),[...r]}`, read)
```

So the regex runs on each marked `text` token (plus comment-stripped HTML). `^` means the start of that token. `code` tokens are skipped, and in marked these include indented blocks and `~~~` fences as well as backtick fences. Three details the branch's descriptions leave out: a bare `@/` is excluded, a `#fragment` is stripped, and there is an extra `fC(M)` filter whose body I did not see. No `marked` package was available offline, so every statement below about how marked tokenizes a construct (link text, strikethrough, tables, inline HTML) is inferred from marked's documented token model. None of it was executed.

---

## Claim 1: "AGENTS.md uses bare filenames, matching GEMINI.md below the header." (commit 5ee8315)

**Location:** `AGENTS.md:9-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the whole of AGENTS.md below line 3 matching GEMINI.md, and main→branch changing only the `@./workflows/` prefixes; does not establish that bare names resolve to the repo's copies rather than the installed `~/.claude/workflows` (override-log row 152).

`cmp <(tail -n +4 AGENTS.md) <(tail -n +4 GEMINI.md)` printed `identical`. `diff <(git show main:AGENTS.md | sed 's|@\./workflows/||g') AGENTS.md` printed `no other difference`. The line now reads `- **research-plan-implement.md** — The default development loop.` (`AGENTS.md:9`). Command: `timeout 60 docs/reviews/execution-logs/fc-final2-r2-misc.sh`, run from the worktree root at 2026-09-29T07:51:50Z, exit 0.

**Evidence:** `AGENTS.md:9-18`, `GEMINI.md:9-18`, `docs/reviews/execution-logs/fc-final2-r2-misc.sh`, `docs/reviews/execution-logs/fc-final2-r2-misc.txt`

---

## Claim 2: Row 65: "Its workflow list now matches GEMINI.md byte for byte below the header … The sections AGENTS.md shares with the global instructions (Context Packing, Shared Thoughts, General Principles) stay … `hooks/log-usage.sh` cannot see `@` loads"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte comparison, the three shared headings in both files, and log-usage.sh's stated coverage; does not establish that no other hook or log records `@` loads.

The byte comparison is Claim 1's executed `cmp`. The headings are present in both files: `AGENTS.md:41 ## Context Packing`, `:52 ## Shared Thoughts`, `:65 ## General Principles`, and `global-instructions/CLAUDE.md:126`, `:153`, `:303` with the same titles. log-usage.sh states `# COVERAGE: only Skill, Read and Agent tool calls are seen. A workflow or skill read through Bash (`cat`), an `@` import, … produces no event` (`hooks/log-usage.sh:7-9`).

**Evidence:** `docs/decisions/log.md:88`, `AGENTS.md:41-65`, `global-instructions/CLAUDE.md:126-303`, `hooks/log-usage.sh:7-14`, `docs/reviews/execution-logs/fc-final2-r2-misc.txt`

---

## Claim 3: Row 65: "Claude Code's own grammar as read from the v2.1.284 binary during review (`@` at a token start or after whitespace, then `./`, `~/`, `/` or `[A-Za-z0-9._-]`; fenced blocks and code spans skipped)"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the regex and prefix rule against the captured 2.1.284 excerpt; does not establish the body of `fC`, other Claude Code versions, or any runtime marked behavior (not executed offline).

Against the excerpt above, the core is right: `(?:^|\s)@` plus the `./` / `~/` / `/` / `^[a-zA-Z0-9._-]` branches, and `code` and `codespan` are skipped. Three points need tightening. First, "fenced blocks" undersells the skip: Claude Code skips every `code` token, so indented code blocks and `~~~` fences are skipped too (paraphrased — no quote available because the fact that indented and tilde blocks are `code` tokens comes from marked's token model, not a string in the excerpt). Second, the summary drops `M!=="/"` (a bare `@/` is not an import), the `#`-fragment strip, the `fC(M)` filter, and the stripping of `<!-- -->` comments. Third, "token" means a marked `text` token, which also begins at link text, strikethrough, table cells and after inline HTML, not only at line starts and emphasis (inferred from marked's token model). The precise version: "`@` at the start of a marked text token or after whitespace …; code blocks of every kind, code spans and HTML comments skipped; bare `@/` excluded."

**Evidence:** `docs/decisions/log.md:88`, `docs/reviews/execution-logs/fc-final-r2-misc.txt:28`, `docs/reviews/execution-logs/fc-final2-r2-misc.txt`

---

## Claim 4: Row 65 and the test name: the test "fails on an `@` import in AGENTS.md or `global-instructions/CLAUDE.md`, using Claude Code's own grammar … with a synthetic-case test pinning what the finder matches"; `@test "the import finder matches Claude Code's import grammar"`

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the finder's output on 30 adversarial probes and the pinned synthetic cases; does not establish how Claude Code tokenizes the under-matched forms at runtime (marked not available; inferred), or whether any such form is likely in the two guarded files (none is present today).

The finder is an approximation of the grammar, not the grammar itself. The executed probes (`fc-final2-r2-probes.txt`) show it errs in both directions.

- **Under-matching (forms Claude Code would import, inferred from marked's token model):** `~~@x~~` → `-`, `[@./x.md](http://e)` → `-`, `[a](b)@x` → `-`, `>@x` → `-`, `|@x|` → `-`, `<b>@x</b>` → `-`. In each case the `@` begins a marked text token (strikethrough, link text, the text after a link, blockquote content, a table cell, the text after an inline HTML tag), but the finder's preceding-character class is only `(^|[[:space:]*_])` (`test/agents-gemini-sync.bats:50`).
- **Over-matching (forms Claude Code would not import):** `a*@x`, `snake_@x`, `<!-- @x -->`, `see @/ here`, a `~~~` fence, an indented code block, and a nested ```` fence holding a ```js line. All are flagged (Claims 10 and 11).

The synthetic test does pin exactly what the finder matches (Claim 12), so that half of the row is accurate. What needs tightening is "using Claude Code's own grammar" and the test name. The precise wording: "an approximation of Claude Code's grammar that treats only line starts, whitespace, `*` and `_` as token starts." Under-matching is the risky direction for a guard. The missed forms are rare in a workflow list, which is why I scored this Mostly accurate rather than Incorrect.

Command: `timeout 60 docs/reviews/execution-logs/fc-final2-r2-probes.sh > docs/reviews/execution-logs/fc-final2-r2-probes.txt`, run from the worktree root at 2026-09-29T07:49:44Z, exit 0. The script `eval`s `find_imports` extracted verbatim from the bats file.

**Evidence:** `docs/decisions/log.md:88`, `test/agents-gemini-sync.bats:46-53`, `docs/reviews/execution-logs/fc-final2-r2-probes.sh`, `docs/reviews/execution-logs/fc-final2-r2-probes.txt`, `docs/reviews/execution-logs/fc-final-r2-misc.txt:28`

---

## Claim 5: Row 65: "the nine `@./workflows/*.md` entries put ~358 KB (~89K tokens at chars/4) of workflow text into every session and subagent here"

**Location:** `docs/decisions/log.md:88`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file count, the byte and character totals of main's nine imported files, and a subagent receiving them; does not establish Claude Code's exact tokenizer count (chars/4 is the stated heuristic).

The probes script reports `files: 9 bytes: 358414 chars: 355598 chars/4: 88899` (`fc-final2-r2-probes.txt`), which gives ~358 KB and ~89K. For "and subagent": this replicate is a subagent, and its injected context contains "Contents of /workspace/AGENTS.md (project instructions…)" followed by the contents of each `workflows/*.md` file (paraphrased — no quote available because the evidence is this agent's own injected system context, not a repository file).

**Evidence:** `docs/decisions/log.md:88`, `docs/reviews/execution-logs/fc-final2-r2-probes.txt`

---

## Claim 6: "Handles three syntaxes: CLAUDE.md: `research-plan-implement.md` / AGENTS.md, GEMINI.md: **research-plan-implement.md** / legacy AGENTS.md: **@./workflows/research-plan-implement.md**"

**Location:** `scripts/health-check.sh:203-207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the extraction regex accepting all three delimiters and the optional prefix, and the current files using those styles; does not establish the caller's filtering against `workflows/`.

The regex is `grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)'`, followed by `sed 's/\*\*//g; s/`//g; s|@\./workflows/||'` (`scripts/health-check.sh:213-214`). `GLOBAL_MD="global-instructions/CLAUDE.md"` (`:54`) uses backticks (`global-instructions/CLAUDE.md:24` `` `research-plan-implement.md` ``, with 0 bold `.md` names). AGENTS.md and GEMINI.md use bold (`AGENTS.md:9`, `GEMINI.md:9`). main's AGENTS.md has 9 `**@./workflows` lines.

**Evidence:** `scripts/health-check.sh:54`, `scripts/health-check.sh:203-216`, `global-instructions/CLAUDE.md:24`, `AGENTS.md:9`

---

## Claim 7: "Strips the first 3 lines (tool-specific headers) from each file, then diffs."

**Location:** `test/agents-gemini-sync.bats:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sync test body; does not establish that the first three lines are the only tool-specific ones.

`agents_body=$(tail -n +4 "$AGENTS")` / `gemini_body=$(tail -n +4 "$GEMINI")`, then `diff <(echo "$agents_body") <(echo "$gemini_body")` (`test/agents-gemini-sync.bats:20-23`). No prefix stripping remains.

**Evidence:** `test/agents-gemini-sync.bats:15-28`

---

## Claim 8: "Claude Code loads AGENTS.md as this repo's project instructions (the root CLAUDE.md moved to global-instructions/, decision log row 47) … pulled ~89K tokens … global-instructions/CLAUDE.md loads in every project"

**Location:** `test/agents-gemini-sync.bats:30-35`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the root CLAUDE.md being absent, row 47's move, the ~89K figure, and AGENTS.md reaching this subagent's context; does not establish Claude Code's precedence rules if a root CLAUDE.md came back (only direct observation in 2.1.284).

`ls ./CLAUDE.md` fails with `No such file or directory` (`fc-final2-r2-misc.txt`). Row 47 reads `**The global instructions file moves out of the repo root to `global-instructions/CLAUDE.md`.** … `~/.claude/CLAUDE.md` still resolves to the same content` (`docs/decisions/log.md:70`), so the global file loads everywhere. ~89K is from Claim 5. That AGENTS.md is loaded as project instructions is observed directly in this subagent's context (paraphrased — no quote available because the evidence is this agent's injected system context). Confidence is Medium because that last point is harness behavior, observed but not in-repo (override-log row 153 records the same limitation).

**Evidence:** `test/agents-gemini-sync.bats:30-35`, `docs/decisions/log.md:70`, `docs/reviews/execution-logs/fc-final2-r2-misc.txt`, `docs/reviews/execution-logs/fc-final2-r2-probes.txt`

---

## Claim 9: "The finder mirrors Claude Code's own import extractor …: an `@` at the start of a text token or after whitespace, followed by `./`, `~/`, `/` or a character in [A-Za-z0-9._-]. So `@README`, `@x.md`, `@dir/x` and even `@alice` are imports, while `(@./x)`, `foo@bar` and email addresses are not."

**Location:** `test/agents-gemini-sync.bats:37-41`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the grammar sentence against the captured excerpt and the named examples against the finder; does not establish `fC`'s effect on any example, or runtime marked tokenization.

The grammar sentence matches the excerpt ("start of a text token" is the accurate phrasing, and better than row 65's). The examples behave as stated both in the finder (`@README` and `@alice` match, `(@./x.md)` and `someone@example.com` do not; `fc-final2-r2-probes.txt`) and under the excerpt's rules. What needs tightening is "mirrors": as Claim 4 shows, the finder does not treat link text, strikethrough, table cells or text after inline HTML as token starts, and it flags a bare `@/`, which the excerpt excludes with `M!=="/"`. The precise version: "approximates".

**Evidence:** `test/agents-gemini-sync.bats:37-41`, `test/agents-gemini-sync.bats:50`, `docs/reviews/execution-logs/fc-final-r2-misc.txt:28`, `docs/reviews/execution-logs/fc-final2-r2-probes.txt`

---

## Claim 10: "Emphasis markers (`**@./x**`) do not start a new token in the markdown text, so `*` and `_` count as token starts here."

**Location:** `test/agents-gemini-sync.bats:42-43`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the conclusion (emphasis-wrapped `@` is an import and the finder catches `**@x**`, `*@x*`, `_@x_`); does not establish the finder's handling of `*`/`_` outside emphasis, which over-matches.

The conclusion holds. The wording of the mechanism reads backwards: in marked, `**` opens a `strong` token whose child `text` token begins at the `@`. That is exactly why the excerpt's `^` matches (`if(S.tokens)g(S.tokens)`, excerpt above). The markers do not appear in the text token; they do start a new token. The finder accepts any `*` or `_` before `@`, so it also flags `a*@x` and `snake_@x` (`fc-final2-r2-probes.txt`: `1:a*@x`, `1:snake_@x`). Claude Code would read those as plain text with no token start (inferred from CommonMark flanking rules). This is over-matching, the safe direction. The precise version: "Emphasis markers are not part of the text token that follows them, so …".

**Evidence:** `test/agents-gemini-sync.bats:42-43`, `test/agents-gemini-sync.bats:50`, `docs/reviews/execution-logs/fc-final2-r2-probes.txt`

---

## Claim 11: "Fenced code blocks and inline code spans (single or double backtick) are blanked first, keeping line numbers: Claude Code skips both."

**Location:** `test/agents-gemini-sync.bats:43-45`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers backtick fences, one-line spans, CRLF, and line-number preservation; does not establish handling of every CommonMark fence and span form (several are listed as over-matches below).

What works: backtick fences are blanked, including CRLF fences (`crlf-fence -`). Single- and double-backtick spans are removed, and so is a triple-backtick inline span (`nested-triple-span -`). Line numbers are kept (`tilde-fence 2:…`, `indented-code 3:…`). The awk rule is `/^[[:space:]]*```/ { fence = !fence; print ""; next }` (`test/agents-gemini-sync.bats:48`).

What is not blanked, although Claude Code skips it as `code`/`codespan`:
- `~~~` fences (`tilde-fence 2:@./in/tilde.md`)
- indented code blocks (`indented-code 3:    @./in/indented.md`)
- a ```js line inside a ```` fence, which toggles the fence off (`fence-info-inside 3:@./a.md`)
- spans broken across lines (`span-multiline 2:@x` c`)

"Fenced code blocks" is therefore true only for backtick fences. Every mismatch over-matches, so the guard fails loudly rather than silently. Other adversarial rows behaved correctly: `tab-before` and `crlf` match, and `@@x`, `@#x`, `@(x)` and `\@x` do not.

**Evidence:** `test/agents-gemini-sync.bats:43-49`, `docs/reviews/execution-logs/fc-final2-r2-probes.txt`

---

## Claim 12: The synthetic test's cases: 11 positive lines, all imports; every negative a non-import under the stated grammar; the finder matches all positives and no negatives.

**Location:** `test/agents-gemini-sync.bats:53-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each pinned case under the stated grammar and the finder's output on them; does not establish that the cases cover the under-matched token starts (Claim 4), and the positive assertion checks a count, not per-line identity (sound here because grep -n emits at most one line per input line).

`pos lines: 11; matched: 11`, with lines 1–11 each listed. `neg lines: 7 … matched: 0` (`fc-final2-r2-probes.txt`). Under the excerpt's rules:

- **Positives:** line 1 is a strong token whose text starts `@./`. Lines 2–5 and 8–10 start their lines with `[A-Za-z0-9._/-]`. `@~/…` (line 6), `@../y.md` (line 7) and `@alice` (line 11) follow a space.
- **Negatives** (`:69-75`), each checked individually:
  - `someone@example.com`: the `@` follows `e`.
  - `` `@./x.md` `` and ``` ``@./y.md`` ```: codespans.
  - `the @ sign alone`: the `@` is followed by a space, so the regex's `+` has nothing to capture.
  - `foo@bar/baz`: the `@` follows `o`.
  - `(@./x.md)`, `"@../y.md"`, `[@/abs/z.md]`: the `@` follows `(`, `"` or `[` inside one text token. The unresolved `[…]` reference falls back to text and merges (inferred from marked).
  - the fenced line: a `code` token.

The assertions are `-eq 11` (`:78`) and `[ -z "$output" ]` (`:80`). The targeted bats run passed: `ok 2 the import finder matches Claude Code's import grammar` (`fc-final2-r2-bats.txt`).

**Evidence:** `test/agents-gemini-sync.bats:53-81`, `docs/reviews/execution-logs/fc-final2-r2-probes.txt`, `docs/reviews/execution-logs/fc-final2-r2-bats.txt`

---

## Claim 13: "The no-imports test fails if a guarded file is missing" (commit 2f5fba3), and the test fails on an import in either file.

**Location:** `test/agents-gemini-sync.bats:83-94`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing global instructions file and the no-match / match branches; does not establish behavior for a present but unreadable-by-awk file beyond the `-r` check.

The code is `[ -r "$f" ] || { echo "$f is missing or unreadable"; failed=1; continue; }` … `[ "$failed" -eq 0 ]` (`:86`, `:93`). I ran a copy of the bats file in a scratch dir holding AGENTS.md and GEMINI.md but no `global-instructions/`. Result: `not ok 1 … '[ "$failed" -eq 0 ]' failed … global-instructions/CLAUDE.md is missing or unreadable`, exit 1. In the worktree all three tests pass, exit 0. On the other branch, `if matches=$(find_imports "$f")` takes grep's exit status (the last command in the pipeline). main's AGENTS.md yields 9 matches, which trips it (Claim 15). Commands: `timeout 120 bats test/agents-gemini-sync.bats` (cwd worktree) and `timeout 60 bats -f 'no @-imports' test/agents-gemini-sync.bats` (cwd scratch copy), 2026-09-29T07:50:41Z. The scratch dir was removed afterwards.

**Evidence:** `test/agents-gemini-sync.bats:83-94`, `docs/reviews/execution-logs/fc-final2-r2-bats.txt`

---

## Claim 14a: "The synthetic test pins 11 positives (incl. @README, @alice)" (commit 2f5fba3)

**Location:** `test/agents-gemini-sync.bats:55-67`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the positive count and the two named cases; does not establish anything about the negatives (14b).

The heredoc has 11 lines, including `@README` (`:57`) and `ping @alice about it` (`:66`). The finder matched all 11 (`fc-final2-r2-probes.txt`).

**Evidence:** `test/agents-gemini-sync.bats:55-67`, `docs/reviews/execution-logs/fc-final2-r2-probes.txt`

---

## Claim 14b: "… and 6 negatives" (commit 2f5fba3)

**Location:** `test/agents-gemini-sync.bats:68-76`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count only; does not affect the test, which asserts zero matches regardless of the number.

The negative heredoc holds `neg lines: 7` (`fc-final2-r2-probes.txt`). That is 4 prose lines (`:69-72`) plus a 3-line fence (`:73-75`), so 5 lines carry a case and 9 distinct `@` forms are exercised. No natural count gives 6. The precise version: "7 negative lines (9 non-import forms)". The miscount is harmless because nothing reads the number.

**Evidence:** `test/agents-gemini-sync.bats:68-76`, `docs/reviews/execution-logs/fc-final2-r2-probes.txt`

---

## Claim 15: "the old AGENTS.md still yields 9 matches; GEMINI.md, README.md and every workflow file yield none … Log row 65 states the grammar instead of 'any'." (commit 2f5fba3)

**Location:** commit 2f5fba3
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the files listed at this commit; does not establish that files outside that list lack `@` forms.

The probes script prints `main:AGENTS.md: 9`, then `GEMINI.md: 0` and `README.md: 0`, then `0` for each of the ten `workflows/*.md` files (including `review-fix-loop.md`). The branch's AGENTS.md and global instructions also yield 0. Row 65 now gives the grammar in parentheses, and the word "any" does not appear in its guard sentence (`docs/decisions/log.md:88`).

**Evidence:** `docs/reviews/execution-logs/fc-final2-r2-probes.txt`, `docs/decisions/log.md:88`

---

## Claim 16: "find_imports mirrors the extractor … `@` at a token start or after whitespace (plus emphasis markers) …; fenced blocks and single/double code spans are blanked first, line numbers kept." (commit 2f5fba3)

**Location:** commit 2f5fba3
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Same evidence as Claims 4, 10 and 11; does not establish runtime marked tokenization.

This restates the test comment. As Claims 4, 10 and 11 show, the finder approximates the extractor rather than mirroring it. It under-matches the token starts at link text, strikethrough, tables, inline HTML, `>` and `)`, and it over-matches bare `@/`, intraword `*`/`_`, HTML comments, `~~~` and indented code, and multi-line spans (paraphrased — no quote available because the evidence is the probe table across Claims 4, 10 and 11). The commit's own `Notes:` line ("if CC widens it, this guard under-matches silently") shows the author knew it approximates, but not that it already under-matches for 2.1.284.

**Evidence:** `test/agents-gemini-sync.bats:46-51`, `docs/reviews/execution-logs/fc-final2-r2-probes.txt`

---

## Claim 17: Commit 5ee8315 "~358 KB (~85K tokens)" and commit 7b43db2 subject "catch every @-import form"

**Location:** commits 5ee8315, 7b43db2
**Type:** Configuration / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two historical statements; does not reopen them. Both are already settled as `Accepted-immutable` (override-log rows 154-155) and corrected by later commits.

355,598 chars / 4 = 88,899, not ~85K (`fc-final2-r2-probes.txt`). 7b43db2's finder missed `@README`-style bare names, which 2f5fba3 added (its message quotes `@README`, `@package.json`, `@x.MD`). Both corrections are already on the branch: 7b43db2 states "~85K -> ~89K", and the current code and row 65 give ~89K. I report these only so the replicate is complete.

**Evidence:** `docs/reviews/execution-logs/fc-final2-r2-probes.txt`, `docs/reviews/override-log.md:154-155`

---

## Claims Requiring Attention

### Incorrect
- **Claim 17** (commits 5ee8315, 7b43db2): ~85K should be ~89K, and "every @-import form" overclaims. Both are settled as Accepted-immutable (override-log 154-155), so there is no action.

### Mostly Accurate
- **Claim 3** (`docs/decisions/log.md:88`): the grammar summary omits the skipping of indented and `~~~` code, bare `@/` exclusion, `#` stripping, `fC`, and HTML comments; "token" means a marked text token.
- **Claim 4** (`docs/decisions/log.md:88`, `test/agents-gemini-sync.bats:53`): "using Claude Code's own grammar" and the test name overclaim. The finder under-matches `~~@x~~`, `[@x](u)`, `)@x`, `>@x`, `|@x|` and `<b>@x` (inferred) and over-matches several forms. Suggested wording: "approximates".
- **Claim 9** (`test/agents-gemini-sync.bats:37`): replace "mirrors" with "approximates".
- **Claim 10** (`test/agents-gemini-sync.bats:42-43`): the mechanism wording reads inverted (markers do open a token and are excluded from the text token); the finder also over-matches intraword `*` and `_`.
- **Claim 11** (`test/agents-gemini-sync.bats:43-45`): only backtick fences are blanked; `~~~`, indented code, nested ```` fences and multi-line spans are not (all over-match).
- **Claim 14b** (commit 2f5fba3): "6 negatives" should be 7 lines / 9 forms.
- **Claim 16** (commit 2f5fba3): "mirrors" should be "approximates" (immutable history, so this can only be fixed going forward).

---

## Goal-Alignment Note

- **Answered:** Every brief item. The grammar was checked against the captured 2.1.284 extractor excerpt: Mostly accurate, with omissions listed. The finder was executed on the synthetic cases and 30 adversarial probes (tabs, `**@x**`, `_@x_`, `~~~`, indented code, nested backticks, CRLF and more). It over-matches in the safe direction on code blocks, comments and intraword `*`/`_`, and under-matches on non-emphasis token starts (inferred from marked). Synthetic counts: 11 Verified; "6 negatives" is actually 7 lines / 9 forms. Each negative is a non-import. The missing-file failure was Verified by execution. 2f5fba3's 9/none claims were Verified. Row 65 as a whole: its facts and ~89K are Verified, its grammar/guard wording is Mostly accurate. The extract_workflows comment is Verified. The targeted bats file passed 3/3.
- **Out of scope:** I did not run the full suite or health-check, as the brief instructed.
- **Escalate:** My direct read of the Claude Code binary was denied by the auto-mode classifier, and per that denial I did not pursue it further. The grammar rests on the extractor excerpt a prior replicate committed (`fc-final-r2-misc.txt:28`); the version, 2.1.284, I confirmed myself. `marked` is not installed offline, so the under-match cases (link text, `~~`, tables, inline HTML, `>`, `)`) are inferred, not executed. Whether to widen the finder's token-start class or narrow the wording is the author's call. I created untracked files `docs/reviews/execution-logs/fc-final2-r2-{probes,misc}.{sh,txt}` and `fc-final2-r2-bats.txt`. No tracked file other than this report was edited. All probe processes ran under `timeout` and have exited.
