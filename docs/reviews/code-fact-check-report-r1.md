Commit: 7c2253a

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-agents-md`, branch `fix/agents-md-no-imports`)
**Scope:** final confirming pass, replicate r1: `git diff main...HEAD -- . ':(exclude)docs/reviews'` (`AGENTS.md`, `docs/decisions/log.md`, `scripts/health-check.sh`, `test/agents-gemini-sync.bats`) plus commit messages `git log main..HEAD` (5ee8315, 7b43db2; 64671f0 and 7c2253a are review-artifact commits)
**Checked:** 2026-09-29
**Total claims checked:** 19
**Summary:** 14 verified, 1 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Execution provenance for every `executed` claim below: command `bash /tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc/run1.sh 2>&1 | tee …/run1.log`, cwd `/workspace/.claude/wt-agents-md` (the script `cd`s there), HEAD `7c2253a`, run at `2026-09-29T00:35:30-07:00`, exit 0 (the embedded `bats test/agents-gemini-sync.bats` under `timeout 120` printed `bats rc=0`). The script, its synthetic input and its full output are copied to `docs/reviews/execution-logs/fc-final-r1-run1.sh`, `fc-final-r1-cases.md` and `fc-final-r1-run1.log`. The script first checks that its `find_imports` copy is identical to the bats definition (it prints `FINDER IDENTICAL TO BATS`), so results carry over to the test. A separate `python3` one-liner (cwd the worktree, same minute, exit 0) counted Unicode characters of the nine files: output `355598 88899.5` (recorded in Claim 4's prose; the one-liner is quoted there).

Hallucination-pattern log read before checking; no claim matches a logged pattern.

---

## Claim 1: "Its workflow list now matches GEMINI.md byte for byte below the header"

**Location:** `docs/decisions/log.md:88`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers everything after the first three lines of both files at HEAD 7c2253a; does not establish that the three header lines match (they intentionally differ) or that the files stay in sync after this commit beyond what `test/agents-gemini-sync.bats` test 1 enforces.

`cmp <(tail -n +4 AGENTS.md) <(tail -n +4 GEMINI.md) && echo BYTE-IDENTICAL` printed `BYTE-IDENTICAL`. The headers differ only on line 3 (paraphrased — no quote available because the claim is about file-level equality, shown by `cmp`, not a snippet). Bats test 1 (`ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)`) also passed in the run log.

**Evidence:** `AGENTS.md:1-4`, `GEMINI.md:1-4`, `test/agents-gemini-sync.bats:15-28`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 2a: "`test/agents-gemini-sync.bats` fails on … `@/`, `@./`, `@../`, `@~/`, `@dir/x`, `@x.md`; not inside code spans) in AGENTS.md or `global-instructions/CLAUDE.md`"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the six enumerated forms, the single-line code-span exclusion, and that both named files are scanned; does not establish that these six are all the forms Claude Code expands (Claim 2b), nor behaviour on fenced code blocks (Claim 12).

The finder is:

```bash
# test/agents-gemini-sync.bats:41-45
find_imports() {
  # shellcheck disable=SC2016  # the backticks are literal regex characters
  sed -E 's/`[^`]*`//g' "$1" \
    | grep -nE '(^|[^[:alnum:]_.@/-])@(~?/|\.{1,2}/|[[:alnum:]_][[:alnum:]_.-]*(/|\.md([^[:alnum:]]|$)))'
}
```

Alternatives map to the enumeration: `~?/` gives `@/` and `@~/`; `\.{1,2}/` gives `@./` and `@../`; the name branch ending `/` gives `@dir/x`, ending `.md` gives `@x.md`. Executed: all 7 synthetic positives matched (one per form, Claim 13), plus from my extra cases `see @CLAUDE.local.md`, `see @~/.claude/…`, `**@README.md**`, `@x.md:` matched, while `@x.mdx` and `@x.md5` did not. Both files are scanned:

```bash
# test/agents-gemini-sync.bats:73
  for f in "$AGENTS" "$REPO_ROOT/global-instructions/CLAUDE.md"; do
```

Both currently return no match (`rc=1` for each in the run log). Plausible-prose false positives probed: `ssh user@host:/path`, `mailto:me@example.com` and `a@b.md` do not match; `install @alice/pkg from npm` and `twitter @handle/status` do match (paraphrased — no quote available because these are results from the captured run log, lines listed under `--- cases.md`). Those two are `@dir/x` by the row's own enumeration, so this is consistent with the claim, not a contradiction of it.

**Evidence:** `test/agents-gemini-sync.bats:41-45`, `test/agents-gemini-sync.bats:71-81`, `docs/reviews/execution-logs/fc-final-r1-cases.md`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 2b: "`test/agents-gemini-sync.bats` fails on any `@path` import"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the finder's behaviour on bare names without a `.md` extension or with other extensions; does not establish Claude Code's exact import grammar, which is not documented in this repo and could not be fetched (sandbox has no egress), hence Medium.

The name branch only fires if the name ends in `/` or `.md` (`[[:alnum:]_][[:alnum:]_.-]*(/|\.md([^[:alnum:]]|$))`, `test/agents-gemini-sync.bats:44`). Executed: `see @package.json`, `see @notes.txt`, `@README.MD` and `@docs` produced no match. Claude Code's public memory documentation gives `@README` and `@package.json` as its own import examples (paraphrased — no quote available because the source is external harness documentation, not a file in the repo). That is the same `@README` form pass 1's replicates cited as missed (`docs/reviews/code-fact-check-report-r1.md:77` at 5ee8315); the widened finder still misses it. So "any `@path` import" overstates what the guard fails on. Precise version: "fails on `@/`, `@./`, `@../`, `@~/`, `@dir/x` and `@name.md` imports". The row's own parenthetical already says that, so the fix is dropping "any" or widening the finder (a bare-name branch would also match `@alice`-style mentions, a trade-off for the author).

**Evidence:** `test/agents-gemini-sync.bats:44`, `docs/reviews/execution-logs/fc-final-r1-cases.md`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 3: "with a synthetic-case test pinning what the finder matches"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers existence and passing of the synthetic test at `test/agents-gemini-sync.bats:47-69`; does not establish that the test pins every behaviour of the finder (for example the non-`.md` misses in Claim 2b are not pinned either way).

```bash
# test/agents-gemini-sync.bats:65-68
  run find_imports "$pos"
  [ "$(printf '%s\n' "$output" | grep -c .)" -eq 7 ] || { echo "missed imports; matched:"; echo "$output"; return 1; }
  run find_imports "$neg"
  [ -z "$output" ] || { echo "false positives:"; echo "$output"; return 1; }
```

Run log: `ok 2 the import finder catches every @-import form and nothing else`.

**Evidence:** `test/agents-gemini-sync.bats:47-69`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 4: "the nine `@./workflows/*.md` entries put ~358 KB (~89K tokens at chars/4) of workflow text into every session"

**Location:** `docs/decisions/log.md:88`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte and character totals of the nine files named in `git show main:AGENTS.md`, at main; does not establish that Claude Code actually expanded those imports (Claim 6) or the real tokenizer count (chars/4 is the row's stated heuristic).

The run script summed `git show main:$f | wc -c` over the nine paths extracted from the old AGENTS.md; run log: `total=358414 tokens=89603` (bytes). The character count, via `python3 -c "…sum(len(subprocess.run(['git','show','main:workflows/%s.md'%f],capture_output=True).stdout.decode()) for f in fs)…"`, printed `355598 88899.5`. 358,414 bytes ≈ 358 KB; 355,598 chars / 4 ≈ 88.9K ≈ 89K. Both figures hold.

**Evidence:** `docs/reviews/execution-logs/fc-final-r1-run1.log` (section `--- chars of 9 imported files (main)`), `docs/reviews/execution-logs/fc-final-r1-run1.sh`

---

## Claim 5: "`hooks/log-usage.sh` cannot see `@` loads, so workflow use went unmeasured"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hook's own documented coverage (Skill, Read, Agent tool calls only); does not establish whether any other instrument measured workflow use.

```bash
# hooks/log-usage.sh:7-9
# COVERAGE: only Skill, Read and Agent tool calls are seen. A workflow or skill
# read through Bash (`cat`), an `@` import, or text inlined into a subagent
# brief produces no event, and nothing fires in sessions without the wiring.
```

The preamble exits for any other tool (`extracts TOOL_NAME (exits 0 for tools that aren't Skill/Read/Agent)`, `hooks/log-usage.sh:13`); an `@` expansion is not a tool call (paraphrased — no quote available because this is harness behaviour outside the repo, but it follows from the hook being a PreToolUse hook, `hooks/log-usage.sh:2`).

**Evidence:** `hooks/log-usage.sh:1-20`

---

## Claim 6: "Claude Code loads AGENTS.md as this repo's project instructions and expands `@` imports inline"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about harness behaviour; does not establish whether Claude Code expands an `@` preceded by `**` (the old AGENTS.md form), which the ~358 KB premise depends on.

This is a claim about the Claude Code harness, not about repo code (paraphrased — no quote available because the claim covers external harness behaviour with no in-repo implementation). The AGENTS.md content did appear in this session's injected project instructions (observed in my own context), which supports the "loads AGENTS.md" half, but whether `**@./workflows/x.md**` (with `**` directly before `@`) was expanded cannot be checked here. Would need: a Claude Code session on main with the old AGENTS.md and a context-size or `/memory` inspection.

**Evidence:** `AGENTS.md:1-4`

---

## Claim 7: "Handles three syntaxes: CLAUDE.md: `` `research-plan-implement.md` ``; AGENTS.md, GEMINI.md: `**research-plan-implement.md**`; legacy AGENTS.md: `**@./workflows/research-plan-implement.md**`"

**Location:** `scripts/health-check.sh:204-207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the regex accepting each of the three forms and the current files using the stated delimiters; does not establish that every workflow reference in `global-instructions/CLAUDE.md` is backticked (only the first matches were sampled) or the caller's filtering.

```bash
# scripts/health-check.sh:214-216
    { grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$file" || true; } \
        | sed 's/\*\*//g; s/`//g; s|@\./workflows/||' \
        | sort -u
```

The delimiter group accepts `**` or a backtick and the optional `(@\./workflows/)?` covers the legacy form. `GLOBAL_MD="global-instructions/CLAUDE.md"` (`scripts/health-check.sh:54`) is the "CLAUDE.md" of the comment; `grep` shows it uses backticks (`` `codebase-onboarding.md` `` etc. at lines 19-21) and no `**name.md**` matches. AGENTS.md and GEMINI.md now use `**name.md**` (Claim 1).

**Evidence:** `scripts/health-check.sh:54`, `scripts/health-check.sh:202-217`, `global-instructions/CLAUDE.md:19-21`, `AGENTS.md:9-19`

---

## Claim 8: "Strips the first 3 lines (tool-specific headers) from each file, then diffs."

**Location:** `test/agents-gemini-sync.bats:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers test 1's transformation; does not establish that line 4 of each file is blank or otherwise header-free (it is, `AGENTS.md:4`, `GEMINI.md:4`).

```bash
# test/agents-gemini-sync.bats:19-24
  local agents_body gemini_body
  agents_body=$(tail -n +4 "$AGENTS")
  gemini_body=$(tail -n +4 "$GEMINI")

  if ! diff_output=$(diff <(echo "$agents_body") <(echo "$gemini_body")); then
```

(excerpt ends :23; enclosing test continues to :28 — read.) No prefix strip remains.

**Evidence:** `test/agents-gemini-sync.bats:15-28`

---

## Claim 9: "The old `@./workflows/*.md` list pulled ~89K tokens of workflow text into every session and subagent here"

**Location:** `test/agents-gemini-sync.bats:32-33`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ~89K figure (same computation as Claim 4); does not establish the harness-side "every session and subagent" loading (Claim 6).

Same totals as Claim 4: `355598` chars / 4 = 88,899.5 (python one-liner output, quoted in Claim 4).

**Evidence:** `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 10: "An import is `@` followed by a path: `@/abs`, `@./x`, `@../x`, `@~/x`, or a relative `@dir/x` / `@x.md`" and the test name "the import finder catches every @-import form" (also commit 7b43db2 subject "catch every @-import form")

**Location:** `test/agents-gemini-sync.bats:37-38`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the finder's misses on bare names without `.md` (`@README`, `@package.json`, `@notes.txt`) and on `.MD` in upper case; does not establish Claude Code's exact grammar (external, not fetchable here, hence Medium), and does not dispute that the finder matches the listed forms (Claim 2a).

The comment defines imports as the six forms the regex matches (`test/agents-gemini-sync.bats:44`), and the test name at `test/agents-gemini-sync.bats:47` calls that "every @-import form". Executed: `see @package.json`, `see @notes.txt`, `@README.MD`, `@docs` produce no match (run log `--- cases.md`). Claude Code's memory documentation uses `@README` and `@package.json` as import examples (paraphrased — no quote available because the source is external harness documentation). A green test therefore does not mean AGENTS.md has no imports if someone adds `@package.json`. Same finding as Claim 2b at the test's own location.

**Evidence:** `test/agents-gemini-sync.bats:37-47`, `docs/reviews/execution-logs/fc-final-r1-cases.md`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 11: "The `@` must not follow a word character, so an email address or `foo@bar/baz` is not one."

**Location:** `test/agents-gemini-sync.bats:38-39`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the preceding-character class and its effect on the email and `foo@bar/baz` examples; does not establish which preceding characters Claude Code itself accepts before an import.

The class is broader than "word character":

```bash
# test/agents-gemini-sync.bats:44
    | grep -nE '(^|[^[:alnum:]_.@/-])@(…
```

It excludes alphanumerics and `_` (word characters) and also `.`, `@`, `/` and `-`. Executed: `-@./x.md`, `x.@./y.md`, `/@./y.md`, `@@./z.md` all produce no match (run log `--- cases.md`). The conclusion holds: `someone@example.com` and `foo@bar/baz` are not matched (negatives, Claim 13). Precise version: "The `@` must not follow a word character or `.`, `@`, `/`, `-`".

**Evidence:** `test/agents-gemini-sync.bats:44`, `test/agents-gemini-sync.bats:59-62`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 12: "Inline code spans are removed first"

**Location:** `test/agents-gemini-sync.bats:39-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers single-line backtick spans; does not establish removal of fenced code blocks or spans crossing a line break (sed works per line, so `@` imports inside a ``` fence would still be flagged, a conservative false positive), nor the external half "Claude Code does not expand imports inside them".

```bash
# test/agents-gemini-sync.bats:43
  sed -E 's/`[^`]*`//g' "$1" \
```

Executed: the negative line ``use `@./x.md` in a code span`` produces no match. `global-instructions/CLAUDE.md` contains a fence at lines 237-254 with no `@` path inside, so the fence limitation does not bite today (paraphrased — no quote available because this is an absence result: the finder returned no matches on the file, `rc=1` in the run log).

**Evidence:** `test/agents-gemini-sync.bats:43`, `test/agents-gemini-sync.bats:61`, `global-instructions/CLAUDE.md:237-254`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 13: the synthetic test asserts exactly 7 matches on the positive file and none on the negative

**Location:** `test/agents-gemini-sync.bats:47-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and that each positive line is matched through the intended alternative; does not establish coverage of forms absent from the fixture (Claim 10).

The script extracted both heredocs (`pos lines: 7  neg lines: 5`) and ran the finder: `pos matches: 7`, `neg matches: 0`. Each positive line contains exactly one `@`, so each match is that `@`, via: line 1 `**@./` → `\.{1,2}/` (preceded by `*`); `@README.md` → `.md$`; `@workflows/x.md` → name then `/`; `@~/.aws` → `~?/`; `(@./`, `"@../` → `\.{1,2}/` after `(` / `"`; `[@/abs` → `~?/` with no `~` (paraphrased — no quote available because the per-line alternative is my reading of the regex against the fixture lines at `test/agents-gemini-sync.bats:50-56`, confirmed only as a whole-line match by grep).

**Evidence:** `test/agents-gemini-sync.bats:47-69`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 14: "AGENTS.md and the global instructions have no @-imports" (test scans both files)

**Location:** `test/agents-gemini-sync.bats:71-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test loops over both files and fails if either matches, and that both pass at 7c2253a; does not establish absence of import forms the finder misses (Claim 10).

```bash
# test/agents-gemini-sync.bats:73-80
  for f in "$AGENTS" "$REPO_ROOT/global-instructions/CLAUDE.md"; do
    if matches=$(find_imports "$f"); then
      echo "$f contains @-imports, which Claude Code expands into every session:"
      echo "$matches"
      failed=1
    fi
  done
  [ "$failed" -eq 0 ]
```

`find_imports` returns grep's status, so a match sets `failed=1`. Run log: `ok 3 …`; the old AGENTS.md from main gives `9` matches, i.e. the test would fail on it.

**Evidence:** `test/agents-gemini-sync.bats:71-81`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 15: "put ~358 KB (~85K tokens) of workflow text into every session"

**Location:** `git:5ee8315` (commit message body)
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the token figure in the first commit's message; does not affect the current tree, where log row 65 and the test comment carry the corrected ~89K (Claims 4, 9).

358,414 bytes / 4 = 89,603 and 355,598 chars / 4 = 88,900 (Claim 4); neither rounds to 85K. Commit 7b43db2's message records the correction ("~85K -> ~89K tokens (355,598 chars / 4)"). Commit messages are immutable, so this is informational only.

**Evidence:** `git:5ee8315`, `git:7b43db2`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 16: "a synthetic-case test pins exactly what it matches (7 positives, 5 negatives). Still catches all 9 lines of the previous AGENTS.md."

**Location:** `git:7b43db2` (commit message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fixture sizes and the 9-of-9 match on `git show main:AGENTS.md`; does not establish "exactly what it matches" beyond the fixture (Claim 10).

Run log: `pos lines: 7  neg lines: 5`; `--- old AGENTS.md match count` → `9`; `old @./workflows lines: 9`.

**Evidence:** `test/agents-gemini-sync.bats:49-64`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 17: "find_imports now catches @~/, @dir/x and @x.md too, ignores email-like foo@bar and inline code spans"

**Location:** `git:7b43db2` (commit message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three added forms and the two exclusions on the fixture and extra cases; does not establish multi-line or fenced code handling (Claim 12).

Positives `load @~/.aws/credentials here`, `@workflows/x.md`, `@README.md` match; negatives `someone@example.com`, `foo@bar/baz`, `` `@./x.md` `` do not (run log).

**Evidence:** `test/agents-gemini-sync.bats:41-45`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claim 18: "~85K -> ~89K tokens (355,598 chars / 4)" and "The guard now also covers global-instructions/CLAUDE.md"

**Location:** `git:7b43db2` (commit message body)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the character count and the guard's file list; does not establish tokenizer-accurate counts.

The python one-liner printed `355598 88899.5` (Claim 4). The loop at `test/agents-gemini-sync.bats:73` includes `"$REPO_ROOT/global-instructions/CLAUDE.md"` (quoted in Claim 14).

**Evidence:** `test/agents-gemini-sync.bats:73`, `docs/reviews/execution-logs/fc-final-r1-run1.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2b** (`docs/decisions/log.md:88`): "fails on any `@path` import" overstates it; bare names without `.md` (`@README`, `@package.json`, `@notes.txt`), which Claude Code's docs use as imports, pass the guard. Drop "any" (the parenthetical is already precise) or widen the finder.
- **Claim 10** (`test/agents-gemini-sync.bats:37-38`, `:47`; commit 7b43db2 subject): the comment's definition of an import and the test name "every @-import form" miss the same bare-name forms. Narrow the wording or widen the finder.
- **Claim 15** (`git:5ee8315`): "~85K tokens" is wrong (≈89K); already corrected in 7b43db2 and the tree. Informational.

### Mostly Accurate
- **Claim 11** (`test/agents-gemini-sync.bats:38-39`): the preceding-character class also excludes `.`, `@`, `/`, `-`, not only word characters.

### Unverifiable
- **Claim 6** (`docs/decisions/log.md:88`): whether Claude Code expanded `**@./workflows/x.md**` (with `**` before `@`) needs a live Claude Code session on main.

---

## Goal-Alignment Note

- **Answered:** All six brief items. Row 65's enumeration and two-file coverage hold (executed); the test comment's "word character" understates the class; the synthetic test's 7/0 counts hold with each line matched for the intended reason; ~89K (355,598 chars/4) and ~358 KB (358,414 bytes) recompute correctly; 7b43db2's claims hold; the health-check comment matches the regex and the three files. `bats test/agents-gemini-sync.bats`: 3/3 pass.
- **Out of scope:** I did not run `scripts/health-check.sh` or the full suite (per brief). Review artifacts under `docs/reviews/` were read only for pass-1 context.
- **Escalate:** One residual gap: the widened finder still misses bare names without `.md` (`@README`, `@package.json`), the `@README` form pass 1 itself cited, so "any"/"every" in row 65 and the test name still overclaim. This rests on Claude Code's external import grammar (Medium confidence, not fetchable here). A cheap wording fix closes it. No tracked file was edited except this report. New untracked execution logs are `docs/reviews/execution-logs/fc-final-r1-*`. No hallucination-log entry was added (these are overclaims, not fabricated symbols). No processes were left running.
