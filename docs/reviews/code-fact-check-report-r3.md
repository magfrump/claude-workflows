Commit: 832932a

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-agents-md (branch fix/agents-md-no-imports)
**Scope:** `git diff main...HEAD -- . ':(exclude)docs/reviews'` (AGENTS.md, docs/decisions/log.md, scripts/health-check.sh, test/agents-gemini-sync.bats) plus commit messages `git log main..HEAD` (5ee8315, 7b43db2, 2f5fba3). Replicate r3 of the final confirming pass (k=3).
**Checked:** 2026-09-29
**Total claims checked:** 29
**Summary:** 18 verified, 6 mostly accurate, 0 stale, 5 incorrect, 0 unverifiable

Method note (applies to every `executed` claim below). I located the installed Claude Code (`claude --version` → `2.1.284 (Claude Code)`, binary `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe`). I cut two pieces out of the binary: the `@`-import extractor `yRn` (byte-identical to the binary text; the check is in `yrn-binary.js`), and the bundled `marked` lexer (`function Vy()` … `class rq`, 28,046 chars). Together they make a runnable harness, `cc-extract.js`. It runs `yRn(new rq({gfm:!1}).lex(text))`, the same call the binary makes: `F=w||M?new rq({gfm:!1}).lex(h):void 0 … K=F&&s!==void 0?yRn(F,s):[]`. The only stubs are `fC` (path-exclusion predicate, stubbed false) and the path resolvers `Ye`/`Nb` (identity), so the harness reports the raw captured paths. I then diffed the harness against the branch's `find_imports` on 27 adversarial files. All captured output is in `docs/reviews/execution-logs/fc-final2-r3/` (the scripts are `run-exec.sh` to `run-exec4.sh`; the logs are `exec.log` to `exec5.log`; the probe inputs are in `cases/`). Every command ran under `timeout`, in the stated cwd, with node v22.23.2, between 2026-09-29T07:52Z and 07:55Z. No process was left running.

Hallucination-pattern log consulted. Claim 18b resembles the logged count-in-commit-message class ("mode1-equiv 33" claimed in commit 37c5ea9's test tally …). No other claim matches a logged pattern.

---

## Claim 1: "Its workflow list now matches GEMINI.md byte for byte below the header"

**Location:** `docs/decisions/log.md:88`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers AGENTS.md vs GEMINI.md from line 4 onward at HEAD, as checked by the sync test; does not establish anything about the three header lines, which the test deliberately strips.

The sync test diffs the two files after stripping 3 header lines:

```bash
# test/agents-gemini-sync.bats:20-21
agents_body=$(tail -n +4 "$AGENTS")
gemini_body=$(tail -n +4 "$GEMINI")
```

Command `timeout 120 bats test/agents-gemini-sync.bats`, cwd `/workspace/.claude/wt-agents-md`, 2026-09-29T07:52:11Z, exit 0, output `ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)`.

**Evidence:** `test/agents-gemini-sync.bats:15-28`, `docs/reviews/execution-logs/fc-final2-r3/exec.log`

---

## Claim 2a: "using Claude Code's own grammar as read from the v2.1.284 binary during review (`@` at a token start or after whitespace, then `./`, `~/`, `/` or `[A-Za-z0-9._-]`…)" (the grammar as described)

**Location:** `docs/decisions/log.md:88`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex and prefix conditions in the v2.1.284 extractor. Does not establish three extractor details the summary leaves out: a `#fragment` suffix is stripped, a bare `@/` is excluded (`M!=="/"`), and paths matching `fC(...)` are dropped. It also does not establish which tokens count as "text" (see Claims 2b, 2c and 13).

The binary's extractor, quoted verbatim (`docs/reviews/execution-logs/fc-final2-r3/yrn-binary.js`, extracted from `claude.exe`):

```js
let S=/(?:^|\s)@((?:[^\s\\]|\\ )+)/g, … let F=M.indexOf("#");if(F!==-1)M=M.substring(0,F); …
if(!fC(M)&&(M.startsWith("./")||M.startsWith("~/")||M.startsWith("/")&&M!=="/"||!M.startsWith("@")&&!M.match(/^[#%^&*()]+/)&&M.match(/^[a-zA-Z0-9._-]/)))
```

The regex's `^` and `\s` match exactly "at a token start or after whitespace". The allowed prefixes are exactly `./`, `~/`, `/` or `[a-zA-Z0-9._-]`. The version is from `claude --version` → `2.1.284 (Claude Code)` (exec3.log).

**Evidence:** `docs/reviews/execution-logs/fc-final2-r3/yrn-binary.js`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`

---

## Claim 2b: "fenced blocks and code spans skipped"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code skipping `code` and `codespan` tokens. It does not establish that code-span text is never scanned: Claude Code does scan it inside tight list items, where marked's block-level `text` token carries the raw inline text.

The walker skips code tokens:

```js
// yrn-binary.js
function g(h){for(let S of h){if(S.type==="code"||S.type==="codespan")continue; … if(S.type==="text")s(S.text||"");if(S.tokens)g(S.tokens);if(S.items)g(S.items)}}
```

Fenced blocks (backtick and `~~~`) and indented code blocks are `code` tokens, and the harness confirms each is skipped (`cases/tilde_fence.md` → `[]`, `cases/indented_code.md` → `[]`). The one exception: a tight list item's block-level `text` token has `text` equal to the item's raw source, code span included, and `s()` scans that string. So `- code \`a @./listcs.md\` here` yields `["./listcs.md\`"]` (`cases/tight_list_cs.md`, exec3.log). The precise version would be: "code blocks and code spans skipped, except a code span in a tight list item whose content has whitespace before the `@`."

**Evidence:** `docs/reviews/execution-logs/fc-final2-r3/yrn-binary.js`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`, `docs/reviews/execution-logs/fc-final2-r3/cases/tight_list_cs.md`

---

## Claim 2c: "`test/agents-gemini-sync.bats` fails on an `@` import in AGENTS.md or `global-instructions/CLAUDE.md`, using Claude Code's own grammar"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the guard flags every form Claude Code v2.1.284 imports. It does not establish that the two guarded files contain any such form today (Claim 15: they do not, by either implementation).

The guard is a per-line regex applied after a backtick-only fence toggle and a code-span strip (`test/agents-gemini-sync.bats:48-50`, quoted in Claim 13). Claude Code instead walks marked's token tree. In the differential run (exec3.log), the harness imports each of the following while `find_imports` returns nothing:

- `[@./linktext.md](http://u)`: link text is a child `text` token.
- `>@./bq.md`: blockquote, no space.
- `` a`code`@aftercs.md ``, `[l](u)@afterlink.md`, `x<br>@brhtml.md`, `a\\@escbs.md`: a new text token starts after a code span, a link, inline HTML or an escape.
- `a \`b @./escbt.md \`c`: an escaped backtick opens a false span in the sed.
- `x\xc2\xa0@nbsp.md`: JS `\s` matches NBSP, while `[[:space:]]` in the test's C locale does not.
- `- code \`a @./listcs.md\` here`: see Claim 2b.
- Two cases that leave the whole rest of a file unguarded: a ```` fence that wraps a ``` line (`cases/four_fence.md`), and a line that starts with an inline ``` span (`cases/inline_triple_at_start.md`). Each toggles the awk fence state wrongly, so later real imports are blanked.

The row states the grammar correctly (Claim 2a). The claim that the test *uses* it overstates a line-level approximation that under-matches.

**Evidence:** `test/agents-gemini-sync.bats:46-51`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`, `docs/reviews/execution-logs/fc-final2-r3/cases/`

---

## Claim 3: "the nine `@./workflows/*.md` entries put ~358 KB (~89K tokens at chars/4) of workflow text into every session"

**Location:** `docs/decisions/log.md:88`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte and character totals of the nine files as they are on `main` and the chars/4 arithmetic. It does not establish a real tokenizer count.

Summing `git show main:<f> | wc -c` and the Python `len()` over the nine paths extracted from `main:AGENTS.md` gives `bytes=358414 chars=355598 chars/4=88899` (exec2.log, 07:52:27Z, exit 0). Old AGENTS.md has exactly 9 import lines (Claim 19).

**Evidence:** `docs/reviews/execution-logs/fc-final2-r3/exec2.log`

---

## Claim 4: "After row 47 moved the root CLAUDE.md out, Claude Code loads AGENTS.md as this repo's project instructions and expands `@` imports inline … into every session and subagent here"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers observed behavior in this repo with v2.1.284: this subagent's own context shows AGENTS.md from the main checkout loaded as "project instructions", with each `@./workflows/*.md` target expanded inline as its own entry. It does not establish the loader's precedence rules (for example, what happens when both CLAUDE.md and AGENTS.md exist).

Paraphrased — no quote available because the evidence is this agent's injected system context, not a repo file. The context lists "Contents of /workspace/AGENTS.md (project instructions, checked into the codebase)". It follows with "Contents of /workspace/workflows/research-plan-implement.md (project instructions …)" and the other imported workflow files, and this agent is a subagent. The mechanism is the extractor quoted in Claim 2a, applied at load time (`… new rq({gfm:!1}).lex(h) … yRn(F,s) …`, found in the binary next to `context_claude_md_load`). Row 47's move is at `docs/decisions/log.md:70`: "The global instructions file moves out of the repo root to `global-instructions/CLAUDE.md`."

**Evidence:** `docs/decisions/log.md:70`, `docs/reviews/execution-logs/fc-final2-r3/yrn-binary.js`

---

## Claim 5: "`hooks/log-usage.sh` cannot see `@` loads, so workflow use went unmeasured"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hook's tool filter. It does not establish whether any other logger records `@` loads.

```bash
# hooks/log-usage.sh:7-9
# COVERAGE: only Skill, Read and Agent tool calls are seen. A workflow or skill
# read through Bash (`cat`), an `@` import, or text inlined into a subagent
# brief produces no event, …
```

**Evidence:** `hooks/log-usage.sh:7-14`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`

---

## Claim 6: "Handles three syntaxes: CLAUDE.md `` `research-plan-implement.md` ``; AGENTS.md, GEMINI.md `**research-plan-implement.md**`; legacy AGENTS.md `**@./workflows/research-plan-implement.md**`"

**Location:** `scripts/health-check.sh:203-207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex accepting all three forms and normalizing them to bare filenames. It does not establish the caller's filtering against `workflows/`.

```bash
# scripts/health-check.sh:214-216
{ grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$file" || true; } \
    | sed 's/\*\*//g; s/`//g; s|@\./workflows/||' \
    | sort -u
```

The optional `(@\./workflows/)?` group covers the legacy form, and the delimiter alternation covers bold and backtick. Greps in exec2.log show `AGENTS.md:9` and `GEMINI.md:9` bold names, and nine distinct backticked workflow names in `global-instructions/CLAUDE.md`.

**Evidence:** `scripts/health-check.sh:203-217`, `docs/reviews/execution-logs/fc-final2-r3/exec2.log`

---

## Claim 7: "CLAUDE.md uses backticks for all filenames … AGENTS.md and GEMINI.md use bold"

**Location:** `scripts/health-check.sh:210-212`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers workflow-filename delimiters in the three files at HEAD. It does not establish delimiter use for non-workflow filenames.

`grep -cE '\*\*[a-z][-a-z0-9]*\.md\*\*' global-instructions/CLAUDE.md` → `0` (exec4.log). The backtick grep finds nine workflow names in it (exec2.log). AGENTS.md and GEMINI.md each have 9 bold names (exec2.log).

**Evidence:** `scripts/health-check.sh:210-212`, `docs/reviews/execution-logs/fc-final2-r3/exec2.log`, `docs/reviews/execution-logs/fc-final2-r3/exec4.log`

---

## Claim 8: "Strips the first 3 lines (tool-specific headers) from each file, then diffs. Any difference means an edit was made to one file but not the other."

**Location:** `test/agents-gemini-sync.bats:3-5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the strip-and-diff mechanics. It does not establish that the header really is exactly 3 lines in both files; the passing test is consistent with that but does not prove it.

```bash
# test/agents-gemini-sync.bats:20-23
agents_body=$(tail -n +4 "$AGENTS")
gemini_body=$(tail -n +4 "$GEMINI")

if ! diff_output=$(diff <(echo "$agents_body") <(echo "$gemini_body")); then
```

**Evidence:** `test/agents-gemini-sync.bats:15-28`

---

## Claim 9: "The old `@./workflows/*.md` list pulled ~89K tokens of workflow text into every session and subagent here, invisible to the usage hook. global-instructions/CLAUDE.md loads in every project"

**Location:** `test/agents-gemini-sync.bats:30-35`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Same evidence as Claims 3-5, plus row 47's install path for the global file. It does not establish the install mechanics on hosts outside the devcontainer.

The token figure, the subagent observation and the hook coverage are established in Claims 3, 4 and 5. For "loads in every project": `docs/decisions/log.md:70` reads "`~/.claude/CLAUDE.md` still resolves to the same content".

**Evidence:** `docs/decisions/log.md:70`, `hooks/log-usage.sh:7-9`, `docs/reviews/execution-logs/fc-final2-r3/exec2.log`

---

## Claim 10: "an `@` at the start of a text token or after whitespace, followed by `./`, `~/`, `/` or a character in [A-Za-z0-9._-]. So `@README`, `@x.md`, `@dir/x` and even `@alice` are imports, while `(@./x)`, `foo@bar` and email addresses are not."

**Location:** `test/agents-gemini-sync.bats:38-41`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grammar statement and every named example, run through the verbatim extractor. It does not establish that `find_imports` implements the grammar (Claim 13).

The grammar matches the extractor (Claim 2a). Per-line harness output (exec3.log and the earlier per-line run): `@README` → `["README"]`, `ping @alice about it` → `["alice"]`, `(@./x.md) "@../y.md" [@/abs/z.md]` → `[]`, `mail someone@example.com today` → `[]`, `foo@bar/baz` → `[]`.

**Evidence:** `test/agents-gemini-sync.bats:37-41`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`

---

## Claim 11a: "Emphasis markers (`**@./x**`) do not start a new token in the markdown text"

**Location:** `test/agents-gemini-sync.bats:42-43`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers how marked (as bundled in v2.1.284, `gfm:false`) tokenizes `**@./x**`. It does not establish the author's intended meaning; the sentence may mean "the markers are not part of the text", which is true.

As written, the mechanism is the reverse of what happens. marked lexes `**@./x**` as a `strong` token whose child is a `text` token `"@./x"`, and the walker recurses into it (`if(S.tokens)g(S.tokens)`, yrn-binary.js). So the emphasis marker is exactly what makes `@` start a new text token, which is why `^` matches and `cases/strong.md` yields `["./strong.md"]` (exec3.log). The conclusion the comment draws is right for real emphasis; the mechanism stated is wrong.

**Evidence:** `docs/reviews/execution-logs/fc-final2-r3/yrn-binary.js`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`, `docs/reviews/execution-logs/fc-final2-r3/cases/strong.md`

---

## Claim 11b: "so `*` and `_` count as token starts here"

**Location:** `test/agents-gemini-sync.bats:43`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the finder's treatment of `*` and `_`. It does not establish other token starts (Claim 13).

The finder counts *any* `*` or `_` before `@` as a token start:

```bash
# test/agents-gemini-sync.bats:50
| grep -nE '(^|[[:space:]*_])@(\./|~/|/|[[:alnum:]._-])'
```

Claude Code counts them only when they actually delimit emphasis. `a*@star.md` and `snake_@intra.md` yield `[]` from the harness but are flagged by the finder (exec3.log). `_@emus.md_` and `**@./strong.md**` agree. So the finder over-matches, which errs in the safe direction for a guard. The precise wording would be "`*` and `_` are treated as token starts (a superset of real emphasis)".

**Evidence:** `test/agents-gemini-sync.bats:50`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`

---

## Claim 12: "Fenced code blocks and inline code spans (single or double backtick) are blanked first, keeping line numbers: Claude Code skips both."

**Location:** `test/agents-gemini-sync.bats:43-45`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the awk and sed blanking stages and Claude Code's skip of code tokens. It does not establish correct fence detection for `~~~` fences, fences of four or more backticks, or a line that starts with an inline ``` span, and it does not establish Claude Code's tight-list exception (Claim 2b).

```bash
# test/agents-gemini-sync.bats:48-49
awk '/^[[:space:]]*```/ { fence = !fence; print ""; next } fence { print ""; next } { print }' "$1" \
  | sed -E 's/``([^`]|`[^`])*``//g; s/`[^`]*`//g' \
```

Line numbers are kept (awk prints `""` for blanked lines). Code spans, single and double, are removed. But only backtick fences are recognized, and any line starting with ``` toggles the state:

- `~~~` fences and indented code blocks are scanned. This over-matches: `cases/tilde_fence.md` and `cases/indented_code.md` are flagged, while the harness gives `[]`.
- A ```` fence containing ``` lines, and an inline ``` span at line start, flip the toggle wrongly. This under-matches everything after them (Claim 2c).

"Claude Code skips both" holds except inside tight list items (Claim 2b). Both halves earn the same verdict, so the claim is not split.

**Evidence:** `test/agents-gemini-sync.bats:48-49`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`, `docs/reviews/execution-logs/fc-final2-r3/cases/`

---

## Claim 13: "The finder mirrors Claude Code's own import extractor (read from the v2.1.284 binary during review …)"; test name "the import finder matches Claude Code's import grammar"

**Location:** `test/agents-gemini-sync.bats:37`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers equivalence between `find_imports` and the v2.1.284 extractor over 27 adversarial inputs plus the synthetic cases (also `:53`). It does not establish a wrong result on the two guarded files today; both implementations find nothing there (Claim 15).

```bash
# test/agents-gemini-sync.bats:46-51
find_imports() {
  # shellcheck disable=SC2016  # the backticks are literal regex characters
  awk '/^[[:space:]]*```/ { fence = !fence; print ""; next } fence { print ""; next } { print }' "$1" \
    | sed -E 's/``([^`]|`[^`])*``//g; s/`[^`]*`//g' \
    | grep -nE '(^|[[:space:]*_])@(\./|~/|/|[[:alnum:]._-])'
}
```

It agrees with the harness on the 11 synthetic positives and the negatives (Claim 14), and on `tab`, `crlf`, `strong`, `em_us`, `heading`, `table` (non-GFM, so plain text), `frag`, `paren` and `nested_bt`.

It diverges on 18 of the 27 probes (exec3.log):
- Under-matches (Claude Code imports, finder silent), 11: `link_text`, `blockquote` (no space), `after_codespan`, `after_link`, `br_html`, `escaped_bs`, `escaped_bt`, `nbsp`, `tight_list_cs`, `four_fence`, `inline_triple_at_start`. The last two blank every later line.
- Over-matches (finder flags, Claude Code does not), 7: `tilde_fence`, `indented_code`, `html_comment` (Claude Code strips `<!-- -->`), `html_block` (Claude Code skips non-comment HTML), `intraword_us`, `star_nonemph`, `multiline_cs`.

The finder errs in both directions. The under-matches include a plausible authoring form, a markdown link whose text is the path (`- [@./workflows/x.md](workflows/x.md)`), which Claude Code would import and this guard would pass. "Mirrors" and "matches" overstate an approximation that is correct for the regex-level grammar only.

**Evidence:** `test/agents-gemini-sync.bats:46-53`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`, `docs/reviews/execution-logs/fc-final2-r3/cc-extract.js`, `docs/reviews/execution-logs/fc-final2-r3/cases/`

---

## Claim 14: Synthetic test: 11 positive lines each an import; each negative line a non-import (as pinned by `-eq 11` and `[ -z "$output" ]`)

**Location:** `test/agents-gemini-sync.bats:55-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heredoc contents against both the finder and the verbatim extractor. It does not establish coverage of forms outside the heredocs (Claim 13).

```bash
# test/agents-gemini-sync.bats:78,80
[ "$(printf '%s\n' "$output" | grep -c .)" -eq 11 ] || …
[ -z "$output" ] || { echo "false positives:"; …
```

Running the harness on the extracted heredocs (exec3.log, 07:53:07Z, exit 0): pos → 11 distinct paths, one per line; neg → `[]`. The finder gives 11 and 0. So every positive is an import and every negative is a non-import under Claude Code's actual extractor, not only under the stated grammar. The bats run passes test 2 (exec.log).

**Evidence:** `test/agents-gemini-sync.bats:53-81`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`, `docs/reviews/execution-logs/fc-final2-r3/exec.log`

---

## Claim 15: No-imports test fails when a guarded file is missing; passes on the current files

**Location:** `test/agents-gemini-sync.bats:83-94`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing-file branch and the current AGENTS.md and global-instructions/CLAUDE.md. It does not establish detection of the under-matched forms in Claim 13.

```bash
# test/agents-gemini-sync.bats:86,93
[ -r "$f" ] || { echo "$f is missing or unreadable"; failed=1; continue; }
…
[ "$failed" -eq 0 ]
```

In a fake repo containing the test, AGENTS.md and GEMINI.md but no `global-instructions/` (cwd `…/scratchpad/fake`, 07:52:12Z), bats exits 1 with `not ok 3 … global-instructions/CLAUDE.md is missing or unreadable`. On the real worktree, test 3 is `ok` (exit 0). Both implementations find nothing in either guarded file: finder `0`, harness `[]` (exec.log).

**Evidence:** `test/agents-gemini-sync.bats:83-94`, `docs/reviews/execution-logs/fc-final2-r3/exec.log`, `docs/reviews/execution-logs/fc-final2-r3/run-exec.sh`

---

## Claim 16: "the guard still missed bare imports with no .md (`@README`, `@package.json`, `@x.MD`), flagged forms Claude Code does not import (`(@./x)`, `"@../y"`, fenced blocks, double-backtick spans)"

**Location:** commit 2f5fba3 (message, paragraph 1)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 7b43db2's `find_imports` on the listed forms. It does not establish the "log row 65 and the test name overclaimed" part beyond Claims 2c and 13.

The 7b43db2 finder (`finder-7b43.sh`, from `git show 7b43db2:test/agents-gemini-sync.bats`) run on those nine lines flags only `(@./x)`, `"@../y"`, `@./y.md` (the double-backtick span, whose inner single-backtick strip leaves `@./y.md`) and the fenced line. It misses `@README`, `@package.json` and `@x.MD` (exec4.log). The harness confirms these are the correct classifications.

**Evidence:** `docs/reviews/execution-logs/fc-final2-r3/exec4.log`, `docs/reviews/execution-logs/fc-final2-r3/finder-7b43.sh`, `docs/reviews/execution-logs/fc-final2-r3/hist.md`

---

## Claim 17a: "find_imports mirrors the extractor replicate r2 read from the Claude Code v2.1.284 binary"

**Location:** commit 2f5fba3 (message, first bullet)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 13. It does not establish that the grammar the commit message states is wrong; that grammar is right (Claim 2a).

Paraphrased — no quote available because the evidence is the differential run summarized in Claim 13 (11 under-matches, 7 over-matches across 27 probes, exec3.log). The grammar summary in the same bullet ("`@` at a token start or after whitespace (plus emphasis markers), then `./`, `~/`, `/` or [A-Za-z0-9._-]") matches the binary, but the implementation does not mirror the token-walking extractor.

**Evidence:** `test/agents-gemini-sync.bats:46-51`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`

---

## Claim 17b: "fenced blocks and single/double code spans are blanked first, line numbers kept"

**Location:** commit 2f5fba3 (message, first bullet)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 12.

Paraphrased — no quote available because it is the same awk/sed pair analysed in Claim 12. Backtick fences and code spans are blanked with line numbers kept. `~~~` fences are not blanked, and fences of four or more backticks, or a line starting with an inline ``` span, mis-toggle the fence state.

**Evidence:** `test/agents-gemini-sync.bats:48-49`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`

---

## Claim 18a: "The synthetic test pins 11 positives (incl. @README, @alice)"

**Location:** commit 2f5fba3 (message, second bullet)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the positive heredoc and its `-eq 11` pin.

```text
# test/agents-gemini-sync.bats:57,66
@README
ping @alice about it
```

The positive heredoc has 11 lines and the finder returns 11 (exec3.log).

**Evidence:** `test/agents-gemini-sync.bats:55-67,78`, `docs/reviews/execution-logs/fc-final2-r3/exec3.log`

---

## Claim 18b: "and 6 negatives"

**Location:** commit 2f5fba3 (message, second bullet)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers counting the negative heredoc. It does not establish which counting unit the author meant.

The negative heredoc has 7 lines (`sed … | wc -l` → `7`, exec4.log). Those are 4 prose lines and a 3-line fence, holding 9 distinct negative forms: email, single span, double span, lone `@`, `foo@bar/baz`, `(@./x.md)`, `"@../y.md"`, `[@/abs/z.md]`, fenced line. None of the natural counts is 6. The test itself pins no count (`[ -z "$output" ]`), so the mismatch is only in the message. Matches prior pattern: count-in-commit-message class ("mode1-equiv 33" claimed in commit 37c5ea9's test tally). This is not logged as a hallucination, because it is a miscount rather than a fabricated symbol.

**Evidence:** `test/agents-gemini-sync.bats:68-76`, `docs/reviews/execution-logs/fc-final2-r3/exec4.log`

---

## Claim 19: "the old AGENTS.md still yields 9 matches; GEMINI.md, README.md and every workflow file yield none"

**Location:** commit 2f5fba3 (message, second bullet)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `main:AGENTS.md`, GEMINI.md, README.md and all 12 `workflows/*.md` at HEAD. It does not establish files other than these.

Finder on `git show main:AGENTS.md` gives `9`, and the harness gives the nine `./workflows/*.md` paths. GEMINI.md, README.md and each `workflows/*.md` give finder `0` and harness `[]` (exec.log, 07:52:11-12Z, each exit 0).

**Evidence:** `docs/reviews/execution-logs/fc-final2-r3/exec.log`

---

## Claim 20: "The no-imports test fails if a guarded file is missing (r3 note). Log row 65 states the grammar instead of 'any'."

**Location:** commit 2f5fba3 (message, bullets 3-4)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing-file branch (Claim 15) and the row text. It does not establish that the stated grammar is fully implemented (Claim 2c).

The missing-file behaviour is verified in Claim 15. Row 65 now reads "…using Claude Code's own grammar as read from the v2.1.284 binary during review (`@` at a token start or after whitespace, …)" (`docs/decisions/log.md:88`) and no longer contains "any".

**Evidence:** `docs/decisions/log.md:88`, `docs/reviews/execution-logs/fc-final2-r3/exec.log`

---

## Claim 21: "~85K -> ~89K tokens (355,598 chars / 4)" and "Still catches all 9 lines of the previous AGENTS.md"

**Location:** commit 7b43db2 (message)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the character arithmetic and 7b43db2's finder on `main:AGENTS.md`. It does not establish the other 7b43db2 coverage claims, which 2f5fba3 later corrected (Claim 16).

`chars=355598 chars/4=88899` (exec2.log). The 7b43db2 finder on the old AGENTS.md gives `9` (exec4.log).

**Evidence:** `docs/reviews/execution-logs/fc-final2-r3/exec2.log`, `docs/reviews/execution-logs/fc-final2-r3/exec4.log`

---

## Claim 22: "put ~358 KB (~85K tokens) of workflow text into every session in this repo"

**Location:** commit 5ee8315 (message)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte total and the chars/4 estimate. It does not establish a real tokenizer count. The figure is superseded in 7b43db2, and the commit is immutable history.

The byte total, 358,414, is right. At the chars/4 rule the branch later adopted, the token figure is 88,899, not ~85K (exec2.log). The message also says "every session" without "and subagent", which 7b43db2 added.

**Evidence:** `docs/reviews/execution-logs/fc-final2-r3/exec2.log`

---

## Claim 23a: "gains a guard that fails on any @-import in AGENTS.md"

**Location:** commit 5ee8315 (message)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 5ee8315 guard regex. It is superseded by 7b43db2 and 2f5fba3, and the commit is immutable history.

```bash
# git show 5ee8315:test/agents-gemini-sync.bats:35
if matches=$(grep -nE '(^|[[:space:]*`])@\.{0,2}/' "$AGENTS"); then
```

The regex catches only `@/`, `@./` and `@../`. On `@README`, `@x.md`, `@dir/x` and `@~/x` it matches 0 lines (exec5.log, exit 1).

**Evidence:** `docs/reviews/execution-logs/fc-final2-r3/exec4.log`, `docs/reviews/execution-logs/fc-final2-r3/exec5.log`

---

## Claim 23b: "(verified to fail on the previous AGENTS.md)"

**Location:** commit 5ee8315 (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 5ee8315 regex on `main:AGENTS.md`.

The same regex matches 9 lines of the old AGENTS.md (exec5.log, 07:55:02Z, exit 0), so the guard would have failed there.

**Evidence:** `docs/reviews/execution-logs/fc-final2-r3/exec5.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2c** (`docs/decisions/log.md:88`): the test does not "use Claude Code's own grammar". It is a line-regex approximation that misses link-text, blockquote-no-space, after-code-span/link/HTML/escape and NBSP imports, and silently blanks the rest of a file after a ```` fence or a line-start inline ``` span. Reword to "approximates", or close the gaps.
- **Claim 11a** (`test/agents-gemini-sync.bats:42-43`): emphasis markers *do* start a new (child) text token, which is why `**@./x**` imports. The mechanism sentence is inverted.
- **Claim 13** (`test/agents-gemini-sync.bats:37`, `:53`): "mirrors" and "matches" Claude Code's extractor. The differential run shows 11 under-matches and 7 over-matches across 27 probes.
- **Claim 17a** (commit 2f5fba3): the same "mirrors" overclaim, in immutable history.
- **Claim 23a** (commit 5ee8315): "fails on any @-import", when the guard caught only `@/`, `@./`, `@../`. Immutable history, superseded.

### Stale
- (none)

### Mostly Accurate
- **Claim 2b** (`docs/decisions/log.md:88`): Claude Code skips code tokens, but scans code-span text inside tight list items.
- **Claim 11b** (`test/agents-gemini-sync.bats:43`): any `*`/`_` counts as a token start in the finder, a superset of real emphasis (over-match).
- **Claim 12** (`test/agents-gemini-sync.bats:43-45`): only backtick fences are blanked. `~~~` and indented code are scanned, and a ```` or line-start inline ``` mis-toggles the fence state.
- **Claim 17b** (commit 2f5fba3): as Claim 12.
- **Claim 18b** (commit 2f5fba3): "6 negatives". The heredoc holds 7 lines and 9 negative forms.
- **Claim 22** (commit 5ee8315): ~85K tokens should be ~89K at chars/4 (superseded).

### Unverifiable
- (none)

---

## Goal-Alignment Note
- **Answered:** I verified every claim the brief listed by running things. I read the @-import extractor from the installed Claude Code 2.1.284 binary and confirmed my copy is byte-identical. I ran that extractor with the binary's own bundled marked lexer, against `find_imports`, on the synthetic cases and 27 adversarial files (tabs, `**@x**`, `_@x_`, `~~~` fences, indented code, nested backticks, CRLF and more). I checked the synthetic counts and the missing-file failure, the 2f5fba3 message claims, log row 65, the ~89K figure (355,598 chars / 4 = 88,899), and the `extract_workflows` comment. The grammar as written is correct. The claim that the finder "mirrors" the extractor is not: it under-matches 11 forms, including `[@./x.md](url)` link text, and it can blank the rest of a file after a ```` fence. It also over-matches 7 forms. Neither guarded file contains an import today, by either implementation.
- **Out of scope:** I did not run health-check.sh or the full suite, per the brief. The only tracked file I edited is this report. I also wrote new captured-output files under `docs/reviews/execution-logs/fc-final2-r3/`. I did not verify `fC` path exclusions or path resolution (both stubbed), and I did not look at loader precedence beyond what this session's own context shows.
- **Escalate:** Whether to fix the finder gaps (for example, add `[` and `>` as token starts and handle ```` and `~~~` fences) or to reword the "mirrors" and "matches" claims is the author's call. The link-text form is the one a future AGENTS.md edit could realistically hit.
