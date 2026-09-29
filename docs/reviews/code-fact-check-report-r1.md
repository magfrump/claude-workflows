Commit: 832932a

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-agents-md`, branch `fix/agents-md-no-imports`)
**Scope:** `git diff main...HEAD -- . ':(exclude)docs/reviews'` (AGENTS.md, docs/decisions/log.md row 65, scripts/health-check.sh, test/agents-gemini-sync.bats) plus commit messages `git log main..HEAD` (5ee8315, 7b43db2, 2f5fba3; the docs(reviews) commits carry no checkable claims). Final confirming pass, replicate r1.
**Checked:** 2026-09-29
**Total claims checked:** 19
**Summary:** 13 verified, 5 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern.

Claude Code source read: the installed binary `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe`, `claude --version` = `2.1.284 (Claude Code)`. The extractor is function `yRn` (quoted in Claim 2). All executed evidence is in `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (cwd `/workspace/.claude/wt-agents-md` unless the log section says otherwise; timestamps per section, 2026-09-29T07:48-07:52Z). `find_imports` was run from a verbatim copy of the test's function (identical except the shellcheck comment line; checked with `diff`).

---

## Claim 1: "Its workflow list now matches GEMINI.md byte for byte below the header" / "AGENTS.md names workflows by bare filename, never by `@` import"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers AGENTS.md vs GEMINI.md from line 4 onward at 832932a and the absence of `@` imports in AGENTS.md under `find_imports`; does not establish sync of lines 1-3 (tool-specific headers, deliberately excluded).
**Legibility-target:** for-orchestrator-synthesis

`diff <(tail -n +4 AGENTS.md) <(tail -n +4 GEMINI.md)` printed "identical below line 3", and `bats test/agents-gemini-sync.bats` passed all three tests (exit 0). The workflow list uses `- **research-plan-implement.md** — ...` form (`AGENTS.md:9`), and `find_imports AGENTS.md` returned 0 lines.

**Evidence:** `AGENTS.md:9-19`, `GEMINI.md`, `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (sections "bats", "repo files", "byte-for-byte below header")

---

## Claim 2: "using Claude Code's own grammar as read from the v2.1.284 binary during review (`@` at a token start or after whitespace, then `./`, `~/`, `/` or `[A-Za-z0-9._-]`; fenced blocks and code spans skipped)"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the regex and path-prefix conditions of `yRn` in CC 2.1.284 and its token-type skips; does not establish marked-lexer tokenization of any specific input (no marked library was available to run), nor later CC versions.
**Legibility-target:** for-author

The extractor in the binary:

```js
// claude.exe (2.1.284), function yRn
function s(h){let S=/(?:^|\s)@((?:[^\s\\]|\\ )+)/g,w;while((w=S.exec(h))!==null){let M=w[1];...
  let F=M.indexOf("#");if(F!==-1)M=M.substring(0,F);if(!M)continue;...
  if(!fC(M)&&(M.startsWith("./")||M.startsWith("~/")||M.startsWith("/")&&M!=="/"||
     !M.startsWith("@")&&!M.match(/^[#%^&*()]+/)&&M.match(/^[a-zA-Z0-9._-]/))){...r.add(K)}}}
function g(h){for(let S of h){if(S.type==="code"||S.type==="codespan")continue;
  if(S.type==="html"){... if(M.startsWith("<!--")&&M.includes("-->")){... s(W)} continue}
  if(S.type==="text")s(S.text||"");if(S.tokens)g(S.tokens);if(S.items)g(S.items)}}
```

The row's summary is right on the core (`^` is the start of each `text` token, `\s` is whitespace, then the four prefix alternatives; `code` and `codespan` tokens skipped). It is imprecise in what it leaves out: `code` covers indented code blocks and `~~~` fences too, not only backtick fences; non-comment HTML tokens are skipped entirely and HTML-comment content is stripped; a `#fragment` is cut off first (so `@#x` is not an import); bare `@/` and `@@x` are rejected. "Token start" means the start of any inline `text` token, so text after `~~`, inside link text `[@x](u)`, after a blockquote `>` and after inline HTML also counts (paraphrased — no quote available because this follows from marked's token model, which the minified `g()` walk above relies on but does not itself contain).

**Evidence:** `claude.exe` function `yRn` (grep offsets in the log's method line), `docs/decisions/log.md:88`

---

## Claim 3: "`test/agents-gemini-sync.bats` fails on an `@` import in AGENTS.md or `global-instructions/CLAUDE.md`"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the forms the synthetic test pins, the old AGENTS.md form, and the files' current clean state; does not establish detection of the under-matched forms listed below (CC imports them, the guard does not).
**Legibility-target:** for-author

The guard is `find_imports` (`test/agents-gemini-sync.bats:46-51`, quoted in Claim 11) applied in the loop at `:85-93`. It catches all 11 positive forms and the 9 lines of the old AGENTS.md. Executed adversarial lines found forms CC 2.1.284 would import that the guard misses: `D ~~@strike.md~~`, `F >@quote2.md`, `G [@link.md](http://x)`, `H <span>@html.md</span>` (none reported), and text after a four-backtick fence that contains a three-backtick line (`after @x.md` blanked, see Claim 10). So "fails on an `@` import" holds for the common forms, not for every form. Neither guarded file contains `~~~` or four-backtick fences today (grep counts 0 and 0).

**Evidence:** `test/agents-gemini-sync.bats:46-51`, `test/agents-gemini-sync.bats:83-94`, `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (sections "adversarial", "adversarial-2")

---

## Claim 4: "with a synthetic-case test pinning what the finder matches"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the existence and passing of the synthetic test at `:53-81`; does not establish that its cases exhaust the grammar (see Claim 3).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/agents-gemini-sync.bats:77-80
run find_imports "$pos"
[ "$(printf '%s\n' "$output" | grep -c .)" -eq 11 ] || { ...
run find_imports "$neg"
[ -z "$output" ] || { ...
```

`ok 2 the import finder matches Claude Code's import grammar` in the bats run.

**Evidence:** `test/agents-gemini-sync.bats:53-81`, `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (section "bats")

---

## Claim 5: "The sections AGENTS.md shares with the global instructions (Context Packing, Shared Thoughts, General Principles) stay"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of the three headings in AGENTS.md at 832932a; does not establish that their text is identical to the global file's sections.
**Legibility-target:** for-orchestrator-synthesis

`grep -n '^## ' AGENTS.md` gives `41:## Context Packing`, `52:## Shared Thoughts`, `65:## General Principles`; the branch diff does not touch them.

**Evidence:** `AGENTS.md:41`, `AGENTS.md:52`, `AGENTS.md:65`

---

## Claim 6: "Claude Code loads AGENTS.md as this repo's project instructions and expands `@` imports inline: ... into every session and subagent here"

**Location:** `docs/decisions/log.md:88` (same claim at `test/agents-gemini-sync.bats:30-33`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers CC 2.1.284 extracting and recursively loading `@` paths (depth limit 5) and the observed loading in this subagent's context; does not establish the exact precedence rules between AGENTS.md and a CLAUDE.md in the same directory.
**Legibility-target:** for-orchestrator-synthesis

`yRn` collects `includePaths` (Claim 2) and the loader recurses with `var _Rn=5;` as the depth cap (`if(r.has(h)||s>=_Rn)return;`, claude.exe). Direct observation: this replicate is itself a subagent, and its injected context contains "Contents of /workspace/AGENTS.md (project instructions, checked into the codebase)" (main's version, with `@./workflows/` entries) followed by the full contents of exactly the nine imported workflow files; the worktree's AGENTS.md at 832932a, injected on read, carried no workflow files after it (paraphrased — no quote available because the evidence is this session's system context, not a repository file).

**Evidence:** `claude.exe` functions `yRn`, `_et` (`_Rn=5`), `vRn` (`xf(e,"AGENTS.md")`); session context

---

## Claim 7: "~358 KB (~89K tokens at chars/4) of workflow text"

**Location:** `docs/decisions/log.md:88` (and "~89K tokens" at `test/agents-gemini-sync.bats:32`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the nine workflow files named by main's AGENTS.md at main; does not establish tokenizer-accurate counts (chars/4 is the stated heuristic).
**Legibility-target:** for-orchestrator-synthesis

The size script summed `git show main:<file> | wc -c` and `| LC_ALL=C.UTF-8 wc -m` over the nine files: "total bytes=358414 chars=355598 chars/4=88899".

**Evidence:** `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (section "sizes of the nine workflows")

---

## Claim 8: "`hooks/log-usage.sh` cannot see `@` loads, so workflow use went unmeasured"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hook's matcher and its own coverage comment; does not establish that no other hook logs `@` loads (none has a matcher for them, since `@` loads are not tool calls).
**Legibility-target:** for-orchestrator-synthesis

```bash
# hooks/log-usage.sh:7-9
# COVERAGE: only Skill, Read and Agent tool calls are seen. A workflow or skill
# read through Bash (`cat`), an `@` import, or text inlined into a subagent
# brief produces no event, ...
```

`hooks/wiring.json:86` wires it with `"matcher": "Skill|Read|Agent"`.

**Evidence:** `hooks/log-usage.sh:7-9`, `hooks/wiring.json:86-90`

---

## Claim 9: "CLAUDE.md: `research-plan-implement.md` / AGENTS.md, GEMINI.md: **research-plan-implement.md** / legacy AGENTS.md: **@./workflows/research-plan-implement.md**"

**Location:** `scripts/health-check.sh:204-207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three syntaxes against the regex and the files the caller passes; does not establish that every workflow name in those files is extracted (names must match `[a-z][-a-z0-9]*\.md`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/health-check.sh:214-215
{ grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$file" || true; } \
    | sed 's/\*\*//g; s/`//g; s|@\./workflows/||' \
```

The caller loops over `"$GLOBAL_MD" AGENTS.md GEMINI.md` (`:221`) with `GLOBAL_MD="global-instructions/CLAUDE.md"` (`:54`); that file uses backticks (1 hit for `` `research-plan-implement.md` ``), AGENTS.md and GEMINI.md use bold (1 hit each), and the optional `(@\./workflows/)?` still accepts the legacy form.

**Evidence:** `scripts/health-check.sh:54`, `scripts/health-check.sh:204-217`, `scripts/health-check.sh:221`

---

## Claim 10: "Fenced code blocks and inline code spans (single or double backtick) are blanked first, keeping line numbers: Claude Code skips both."

**Location:** `test/agents-gemini-sync.bats:43-45` (also 2f5fba3 message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers backtick fences of matching length and single-line spans; does not hold for `~~~` fences, fences of four or more backticks containing a three-backtick line, or code spans that cross a line break.
**Legibility-target:** for-author

```bash
# test/agents-gemini-sync.bats:48-49
awk '/^[[:space:]]*```/ { fence = !fence; print ""; next } fence { print ""; next } { print }' "$1" \
  | sed -E 's/``([^`]|`[^`])*``//g; s/`[^`]*`//g' \
```

Line numbers are kept (blanked lines are printed as ""). Executed gaps: `~~~` fence content `@tildefence.md` is reported (over-match; CC skips it); inside a ```` ```` ```` fence the ```` ``` ```` line toggles the fence off, so `@inquadfence.md` is reported (over-match) and the closing ```` ```` ```` toggles it back on, blanking the real import `after @x.md` and everything to end of file (under-match); a span `` `start\n@multilinespan.md` `` reports line 2 (over-match). Nested backticks inside double spans (``` ``a ` @nested.md `` ```) are blanked correctly, and CRLF fences (```` ```\r ````) toggle correctly.

**Evidence:** `test/agents-gemini-sync.bats:46-51`, `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (sections "adversarial", "adversarial-2", "adversarial-3")

---

## Claim 11: "The finder mirrors Claude Code's own import extractor ... So `@README`, `@x.md`, `@dir/x` and even `@alice` are imports, while `(@./x)`, `foo@bar` and email addresses are not." / test name "the import finder matches Claude Code's import grammar"

**Location:** `test/agents-gemini-sync.bats:37-41` (name at `:53`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the listed examples (all correct under `yRn`) and the finder's behaviour on the synthetic and adversarial lines; does not establish exact equivalence: the finder errs in both directions on the forms named below. Medium because CC-side tokenization is inferred from marked's model, not executed.
**Legibility-target:** for-author

```bash
# test/agents-gemini-sync.bats:50
| grep -nE '(^|[[:space:]*_])@(\./|~/|/|[[:alnum:]._-])'
```

The examples match `yRn`: `(@./x)` and `foo@bar` fail `(?:^|\s)`, `@alice` passes `^[a-zA-Z0-9._-]`. Mismatches from the executed adversarial set: under-matches (CC imports, finder silent) `~~@x~~`, `>@x`, `[@x](url)`, `<span>@x</span>`, and text after a four-backtick fence (Claim 10); over-matches (finder reports, CC does not) intraword `foo_@x` and `foo**@x**`, `<!-- @x -->`, indented code blocks, `~~~` fences, multi-line spans, bare `@/`. Tabs, `**@x**`, `_@x_`, `@@x`, `@#x` and CRLF lines agree with CC. "Mirrors" is accurate as a description of the rule's shape, imprecise as a claim of equivalence.

**Evidence:** `test/agents-gemini-sync.bats:37-53`, `claude.exe` function `yRn`, `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (sections "adversarial", "adversarial-2", "adversarial-3")

---

## Claim 12: "Emphasis markers (`**@./x**`) do not start a new token in the markdown text, so `*` and `_` count as token starts here."

**Location:** `test/agents-gemini-sync.bats:42-43`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the finder's treatment of `*` and `_` (executed: `**@bold.md**` and `_@em.md_` reported); does not establish CC's handling of intraword `_`/`*`, where marked makes no emphasis and CC does not import.
**Legibility-target:** for-author

The conclusion is right: in CC, `**@./x**` is a strong token whose child `text` token is `@./x`, so `^@` matches, and the finder emulates that by treating `*`/`_` as token starts. The first clause reads backwards for the CC side: emphasis markers do start a new token in CC's parse; it is only in the raw line the finder scans that they do not (paraphrased — no quote available because marked's strong/em token model is not in the minified snippet). The emulation over-matches intraword forms (`foo_@intraword.md` and `foo**@intraword2.md**` reported).

**Evidence:** `test/agents-gemini-sync.bats:42-50`, `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (section "adversarial", lines B, C, J, K)

---

## Claim 13: "global-instructions/CLAUDE.md loads in every project, so it is held to the same rule."

**Location:** `test/agents-gemini-sync.bats:34-35`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the file is guarded and that it is installed as the user-level instructions; does not establish install behaviour on hosts other than the devcontainer path log row 47 describes.
**Legibility-target:** for-orchestrator-synthesis

The loop covers it: `for f in "$AGENTS" "$REPO_ROOT/global-instructions/CLAUDE.md"; do` (`test/agents-gemini-sync.bats:85`). Log row 47: "`~/.claude/CLAUDE.md` still resolves to the same content" (`docs/decisions/log.md:70`), and this session's context carries it as the user's global instructions for all projects. `find_imports` on it returned 0 lines.

**Evidence:** `test/agents-gemini-sync.bats:85`, `docs/decisions/log.md:70`, `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (section "repo files")

---

## Claim 14: "Strips the first 3 lines (tool-specific headers) from each file, then diffs."

**Location:** `test/agents-gemini-sync.bats:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sync test body; does not establish the headers are exactly 3 lines in both files (the passing diff implies lines 4+ agree).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/agents-gemini-sync.bats:20-23
agents_body=$(tail -n +4 "$AGENTS")
gemini_body=$(tail -n +4 "$GEMINI")
if ! diff_output=$(diff <(echo "$agents_body") <(echo "$gemini_body")); then
```

**Evidence:** `test/agents-gemini-sync.bats:15-28`

---

## Claim 15: synthetic cases: 11 positives are imports and every negative line is a non-import

**Location:** `test/agents-gemini-sync.bats:55-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each case against `yRn`'s regex and prefix rules and the finder's output; does not establish marked-lexer tokenization of `[@/abs/z.md]` (inferred to stay one text token since no link definition exists).
**Legibility-target:** for-orchestrator-synthesis

All 11 positive lines (`:56-66`) pass `(?:^|\s)@` and one of `./`, `~/`, `/`, or a `[a-zA-Z0-9._-]` start (`../y.md` via `.`, `README` / `alice` via alnum); the bats run reported them all. Negatives (`:69-75`): `someone@example.com` and `foo@bar/baz` have no preceding whitespace; `@ sign` has no non-space after `@`; the two spans are `codespan` tokens; `(`, `"`, `[` precede the `@` on `:72`; the fence content is a `code` token. The finder output on the negative file was empty.

**Evidence:** `test/agents-gemini-sync.bats:55-80`, `claude.exe` function `yRn`, `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (section "bats")

---

## Claim 16: "The no-imports test fails if a guarded file is missing (r3 note)."

**Location:** commit 2f5fba3 message (code at `test/agents-gemini-sync.bats:86`)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both guarded paths absent; does not establish behaviour for a present-but-unreadable file beyond the `-r` test (not exercised).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/agents-gemini-sync.bats:86
[ -r "$f" ] || { echo "$f is missing or unreadable"; failed=1; continue; }
```

Running a copy of the bats file in a scratch dir with only GEMINI.md present gave `not ok 3 AGENTS.md and the global instructions have no @-imports` with both "missing or unreadable" lines, exit 1 (cwd: scratchpad `t/`).

**Evidence:** `test/agents-gemini-sync.bats:83-94`, `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (section "copy of the bats file; AGENTS.md and the global instructions file absent")

---

## Claim 17: "the guard still missed bare imports with no .md (`@README`, `@package.json`, `@x.MD`), flagged forms Claude Code does not import (`(@./x)`, `"@../y"`, fenced blocks, double-backtick spans)" / "the old AGENTS.md still yields 9 matches; GEMINI.md, README.md and every workflow file yield none"

**Location:** commit 2f5fba3 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 7b43db2 finder on the named cases and the 832932a finder on main's AGENTS.md, GEMINI.md, README.md and all ten `workflows/*.md`; does not establish CC-side import status beyond Claim 2.
**Legibility-target:** for-orchestrator-synthesis

The 7b43db2 finder (`sed -E 's/`[^`]*`//g' ... | grep -nE '(^|[^[:alnum:]_.@/-])@(~?/|\.{1,2}/|...(/|\.md([^[:alnum:]]|$)))'`, `git show 7b43db2:test/agents-gemini-sync.bats`) reported lines 4, 5, 7, 9 (`(@./x)`, `"@../y"`, fenced, double-span) and not lines 1-3 (`@README`, `@package.json`, `@x.MD`). The current finder reported lines 9-16 and 18 of main's AGENTS.md (9 matches) and 0 for GEMINI.md, README.md and each workflow file.

**Evidence:** `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (sections "old (7b43db2) finder", "repo files")

---

## Claim 18: "The synthetic test pins 11 positives (incl. @README, @alice) and 6 negatives"

**Location:** commit 2f5fba3 message
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the heredocs at `:55-76`; does not establish which counting the author intended.
**Legibility-target:** for-author

11 positives is exact (`-eq 11`, `:78`; `@README` at `:57`, `@alice` at `:66`). The negative heredoc has 7 lines (`:69-75`, including two fence markers) and 9 distinct negative forms (email, single span, double span, lone `@`, `foo@bar`, `(`, `"`, `[`, fenced), so "6" matches neither count. Every negative is correctly a non-import (Claim 15).

**Evidence:** `test/agents-gemini-sync.bats:55-80`

---

## Claim 19: "~358 KB (~85K tokens) of workflow text"

**Location:** commit 5ee8315 message
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the token figure in this historical commit message; the 358 KB half is right, and 7b43db2 and log row 65 carry the corrected ~89K.
**Legibility-target:** for-author

355,598 chars / 4 = 88,899 (Claim 7), so ~85K understates by about 4K; 7b43db2's message corrects it ("~85K -> ~89K tokens (355,598 chars / 4)"). Immutable history, so nothing to change in the tree. 7b43db2's own counts ("7 positives, 5 negatives", "Still catches all 9 lines") match its test (`-eq 7`; 5 negative lines) and the 9-line result in Claim 17. 5ee8315's "Verified: scripts/health-check.sh" was not re-run (brief forbids the full gate).

**Evidence:** `docs/reviews/execution-logs/fc-final2-r1-832932a.log` (section "sizes of the nine workflows"), `git show 7b43db2:test/agents-gemini-sync.bats`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19** (commit 5ee8315): "~85K tokens" should be ~89K; already corrected in 7b43db2 and log row 65. Immutable history, nothing to fix.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`docs/decisions/log.md:88`): the grammar summary leaves out that CC skips all code tokens (indented, `~~~`) and non-comment HTML, strips `#fragment`, and treats any inline text-token boundary (strikethrough, link text, blockquote, inline HTML) as a token start.
- **Claim 3** (`docs/decisions/log.md:88`): the guard misses `~~@x~~`, `>@x`, `[@x](url)`, `<span>@x</span>` and text after a four-backtick fence holding a three-backtick line; neither guarded file uses such forms today.
- **Claim 10** (`test/agents-gemini-sync.bats:43-45`): only backtick fences of matching length are blanked; a four-backtick fence containing a three-backtick line inverts the fence state and hides later imports to end of file.
- **Claim 11** (`test/agents-gemini-sync.bats:37-53`): "mirrors"/"matches" overstates equivalence; the finder errs both ways (under-matches listed in Claim 3, over-matches intraword `_`/`**`, HTML comments, indented code, `~~~`).
- **Claim 12** (`test/agents-gemini-sync.bats:42-43`): emphasis markers do start a new token in CC's parse; they just don't in the raw line the finder scans. The conclusion (count `*`/`_` as token starts) is right.
- **Claim 18** (commit 2f5fba3): "6 negatives" matches neither the 7 heredoc lines nor the 9 negative forms.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report at the output path below, in the skill's exact schema, first line `Commit: 832932a`, ending with a Goal-Alignment Note.
- Answered: every claim the brief named was checked: grammar against the CC 2.1.284 binary, find_imports on synthetic and adversarial lines (tabs, `**@x**`, `_@x_`, `~~~`, indented code, nested backticks, CRLF), the 11/6 counts, the missing-file failure, 2f5fba3's 9/none results, log row 65, the ~89K figure and the extract_workflows comment.
- Out of scope: CC-side tokenization was inferred from marked's token model, not run (no marked library installed); the full health-check gate was not run, per the brief.
- Escalate: the four-backtick fence parity bug (Claim 10) is the one under-match that hides every later line in a file; it cannot fire on the guarded files today, but the test comment and log row do not mention it.
