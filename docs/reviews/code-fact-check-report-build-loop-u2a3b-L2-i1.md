Commit: be94c871

# Code Fact-Check Report

**Replication:** k=1 (loop pass, decision 031)
**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b, HEAD be94c871, on main f6fdda68)
**Scope:** `git diff main...HEAD -- scripts test docs/working skills` (comments, IMPORT_AWK's documented behavior, test names and comments, known issue A5, plan row F11) and commit be94c871's message
**Checked:** 2026-10-07 (UTC)
**Total claims checked:** 42 (40 numbered, two split into a/b)
**Summary:** 27 verified, 3 mostly accurate, 2 stale, 10 incorrect, 0 unverifiable

Method. I read the whole of `scripts/lib/dev-cycle-read.sh:441-694` (INSTRUCTION_FILE to isimported, including the whole IMPORT_AWK program), need_root/rawfile/blocker/inrepo_here (`:96-129`) and `check_fix` (`scripts/dev-cycle.sh:170-186`). Probes ran in a `git archive be94c871` copy at `/tmp/u2a3b-fcL2-FvuR`, with main's scripts at `/tmp/u2a3b-fcL2-FvuR/main` and 47a00c46's (the last pre-superset commit) at `/tmp/u2a3b-fcL2-FvuR/pre`. Every probe ran under `timeout`, and no background process was started. Claude Code 2.1.292 was represented by the security harness (`cc.js`, `marked.js`, `gen.js`, `ccall.js`, `walkall.sh`), copied read-only from `/tmp/u2a3b-secf-XcAr/h` to `/tmp/u2a3b-fcL2-FvuR/h`. Its `reo` reads `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` from text tokens and from HTML-block comments after `w.replace(/<!--[\s\S]*?-->/g,"")`, and resolves with `path.resolve("/R/"+dir,H)` (quoted from `h/cc.js:3-4`). The measurements ran in a scratch clone of /workspace at main (`/tmp/u2a3b-fcL2-FvuR/ws`). Nothing was run in /workspace except read-only `git ls-files`/`archive` and a tar read of its 488 untracked `.md` files. Captured output is in `/tmp/u2a3b-fcL2-FvuR/logs/`. The system awk is mawk 1.3.4 20200120, with GNU sed 4.9 and bash 5.2.15. The hallucination pattern log was read. Its measured-value entries are the nearest patterns, and every count in the commit message was executed below. No fabrication was found, and no worktree file other than this report was written.

Each claim carries a **Legibility-target** (`for-author` for Incorrect/Stale/Mostly accurate, `for-orchestrator-synthesis` for Verified), and its prose names the artifact it lives in.

---

## Claim 1: A5: "Both walks share one token parser (`import_targets`) that reads a superset of Claude Code 2.1.292's import grammar ... every `@` anywhere starts a candidate, every prefix of the run after it to the first blank is a name ... and an absolute path inside the repo is read repo-relative."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** for-author (working doc)
**Type:** Behavioral / Invariant
**Verdict:** Incorrect (behavioral; high confidence)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers names Claude Code 2.1.292 (harness) imports that the parser drops or mis-resolves. It does not establish real Claude Code behaviour beyond the harness, or the `~/` case (see residue).

The shared-parser half is right: `out="$(import_targets "$d" < "$f")"` (`scripts/lib/dev-cycle-read.sh:592`) and `git cat-file blob "$MAIN_SHA:$f" | import_targets "$d"` (`:647`). The superset half is refuted by four input classes, each executed against the harness:

1. **Re-entry through the parent (a regression from main).** `emit` drops any `..` that reaches the top: `if (part[i] == "..") { if (k == 0) return; k--; continue }` (`:521`). Claude Code imports `@../<repo-dir>/docs/x.md` as `docs/x.md`, and main's `realpath -ms` code listed it. End to end, in a fixture repo named `myrepo` whose `CLAUDE.md` holds `See @../myrepo/docs/x.md`, main prints `skip docs/x.md: an instruction file imports it` while be94c871 prints `ok docs/x.md`. Both walks answer `-` at be94c871 and `imported` at main (`logs/probe-e2e-reentry.txt`). The harness differential reports MISS `[docs/x.md]` for be94c871 and none for main (`logs/probe-reentry.txt`).
2. **Absolute paths not spelled with ROOT_REAL as a literal prefix.** `if (root == "" || index(c, root "/") != 1) return` (`:515`) drops `//R/docs/x.md`, `/./R/docs/x.md` and `/R/../R/docs/x.md`. Claude Code's `path.resolve` reads each as `docs/x.md`, the harness reports MISS for all three, and `realpath -ms` gives `docs/abs.md` (`logs/probe-normalize.txt`).
3. **A directory or root holding a backslash.** `awk -v dir="$1" -v root="$ROOT_REAL"` (`:558`) has mawk process escape sequences in `-v` values. For dir `a\tb`, `@x.md` printed `a<TAB>b/x.md` (`logs/probe-mawk-v.txt`). In a fixture, `docs/a\tb/AGENTS.md` holding `See @z.md` left `docs/a\tb/z.md` unlisted by both walks at be94c871, and listed at main (`logs/probe-e2e-reentry.txt`). A root of `/r\nq` dropped an absolute import into it.
4. **Names longer than 4096 bytes.** `for (j = i + 1; j <= L && length(name) < 4096; j++)` (`:533`) stops there. `@` followed by 2100 `./` pairs and `docs/x.md` (4209 bytes) is `docs/x.md` to the harness, while the parser printed nothing (`logs/probe-mawk-edges2.txt`).

Residue, not executed: Claude Code expands `~/` to the home directory, and the parser drops every `~/` name (`:513`), so a repo under `$HOME` imported as `@~/<path-to-repo>/docs/x.md` is missed. /workspace is not under HOME. A 3000-file fuzz differential (gen.js seed 7) found 0 misses (`logs/fz-miss.txt`), but its generator never emits `..` re-entry or absolute paths.

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-526`, `:533`, `:558`, `:592`, `:647`; `/tmp/u2a3b-fcL2-FvuR/h/cc.js:3-4`; logs `probe-reentry.txt`, `probe-e2e-reentry.txt`, `probe-mawk-v.txt`, `probe-mawk-edges2.txt`, `probe-normalize.txt`. Commands: `bash /tmp/u2a3b-fcL2-FvuR/e2e.sh` and `./cmp2.sh LIB DIR cases/n*.md`, cwd `/tmp/u2a3b-fcL2-FvuR`, exit 0, 2026-10-07T06:00-06:05Z.

---

## Claim 2: A5: "Its cost is false positives (none among this repo's tracked docs on 2026-10-06)."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** for-orchestrator-synthesis (working doc)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk over a clone of main with /workspace's 488 untracked `.md` files copied in. It does not establish the live /workspace checkout, which was not run in.

The new tree walk lists 122 paths that main's does not. None is a tracked file, and none exists as a file in the clone (`logs/fp.txt`: "added: 122", both lists empty). Command: `bash fp.sh`, cwd `/tmp/u2a3b-fcL2-FvuR`, exit 0, 2026-10-07T06:08Z.

**Evidence:** `/tmp/u2a3b-fcL2-FvuR/logs/fp.txt`, `logs/imported-added.txt`

---

## Claim 3: A5: "The superset does not cover a name Claude Code builds that is not a prefix of one blank-free run after an `@` (for example a Markdown entity it might decode)."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** for-author (working doc)
**Type:** Behavioral
**Verdict:** Incorrect (doc only; high confidence)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether this is the only class the parser misses. It does not establish real Claude Code's entity handling beyond the extracted lexer.

Being a prefix is not enough. Claim 1's four classes are all prefixes of one blank-free run after an `@`, and the parser still drops them (re-entry, non-literal absolute spellings, names over 4096 bytes) or mis-resolves them (a backslash directory). The entity example also does not occur. The extracted lexer keeps text raw: `inlineText(e){...return{type:"text",raw:n[0],text:n[0],escaped:r}}` (`h/marked.js`, minified). The harness read `See @docs/a&#46;md` as `docs/a&` (cut at `#`) and `@docs/a&amp;b.md` unchanged (`logs/probe-entities.txt`).

**Evidence:** `logs/probe-entities.txt`; Claim 1 evidence

---

## Claim 4a: commit and A5/F11 edits: "the escaped-space ... gap[] leave[s] A5"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** for-orchestrator-synthesis (working doc / commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `@docs/my\ notes.md` in both walks. It does not establish an escaped space inside a directory part that holds a backslash (Claim 1, class 3).

The code is `if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ }` (`scripts/lib/dev-cycle-read.sh:535`). The harness imports `docs/my notes.md`, and both walks answer `docs/my notes.md:Y` at be94c871 but `-` at main (`logs/probe-pinned.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:535`; `logs/probe-pinned.txt`

---

## Claim 4b: commit and A5/main_imports edits: "the ... absolute-import gap[] leave[s] A5" ("absolute imports" removed from A5's and main_imports' Not covered lists)

**Location:** `docs/working/known-issues-dev-cycle.md:18`; `scripts/lib/dev-cycle-read.sh:473-476`
**Legibility-target:** for-author (working doc, code comment)
**Type:** Behavioral
**Verdict:** Incorrect (doc/comment; the underlying miss is behavioral; high confidence)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers absolute imports into the repo. It establishes that only the literal-ROOT_REAL-prefix spelling is covered.

`/R/docs/x.md` is now read (`logs/probe-reentry.txt`: no MISS at be94c871, MISS at main). `//R/...`, `/./R/...`, `/R/../R/...` and a ROOT_REAL holding a backslash escape are still dropped (Claim 1, classes 2-3). The main_imports header now lists only "start files under a symlinked directory ... other names one file has on a case-insensitive checkout, checkout conversions (A5), and three shapes" (`:473-476`). It and A5 therefore no longer list a gap that remains open.

**Evidence:** `scripts/lib/dev-cycle-read.sh:473-476`, `:514-516`; `logs/probe-reentry.txt`

---

## Claim 5: F11: "The shared token parser reads a superset of Claude Code 2.1.292's import grammar (U2a3b: every `@`, every prefix to the first blank, absolute paths inside the repo)"; "absolute imports" dropped from the row's gaps

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Legibility-target:** for-author (working doc)
**Type:** Behavioral
**Verdict:** Incorrect (doc; high confidence)
**Confidence:** High
**Verification mode:** executed
**Scope:** Same evidence as Claims 1 and 4b. It does not re-check F11's unchanged clauses.

The superset is refuted by Claim 1's classes. Absolute imports are covered only when spelled with ROOT_REAL as a literal prefix (Claim 4b).

**Evidence:** Claims 1 and 4b

---

## Claim 6: help text: "skip <path>: <reason>" otherwise, and for every path when the import walk fails

**Location:** `scripts/dev-cycle.sh:55`
**Legibility-target:** for-orchestrator-synthesis (code comment)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix's branch order. It does not establish wording for a path refused earlier for another reason, which still says skip.

The branch order is `elif ! imported_names; then echo "skip $a: the instruction-file import walk failed, ..."` (`scripts/dev-cycle.sh:181-182`). Every earlier branch also prints skip. The test `dev-cycle.bats:1048` passed (Claim 36).

**Evidence:** `scripts/dev-cycle.sh:170-186`; `logs/bats.txt`

---

## Claim 7: SKILL.md: "and refuses every path when the import walk fails"

**Location:** `skills/dev-cycle/SKILL.md:76`
**Legibility-target:** for-orchestrator-synthesis (doc)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 6.

Same code as Claim 6 (`scripts/dev-cycle.sh:181-182`, quoted there).

**Evidence:** `scripts/dev-cycle.sh:181-182`

---

## Claim 8: imported_names header: "It returns 1, with IMPORTED set to "error", when the start listing (git ls-files, untracked_md, instruction_names), lower, a file read or the parser fails, or a start file's name holds a newline ...; an inrepo_here that fails skips its path ... a cached error returns 1 again."

**Location:** `scripts/lib/dev-cycle-read.sh:451-456`
**Legibility-target:** for-orchestrator-synthesis (code comment)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed failure path. It does not establish behaviour when imported_names is called outside `if`/`||` under `set -e`.

`IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error` is set before `nul_list recs tree_starts || return 1` (`:578-579`). The start loop has `[[ "$f" != *$'\n'* ]] || return 1` and `lp="$(lower "${f##*/}")" || return 1` (`:582-583`). Reads and the parser have `out="$(import_targets "$d" < "$f")" || { IMPORTED=error; return 1; }` (`:592`), and lower has `lp="$(lower "$out")" || { IMPORTED=error; return 1; }` (`:595`). The cache is `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }` (`:577`). The suite's fail-closed tests (build-loop-check.bats:382, :422) pass. The only callers in scripts/ are `scripts/dev-cycle.sh:181` (`elif ! imported_names`) and `:691` (`imported_names || return 0`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:574-601`, `:691`; `scripts/dev-cycle.sh:181`; `logs/bats.txt`

---

## Claim 9: import_targets header: "one repo-relative path per line, case kept, each once"

**Location:** `scripts/lib/dev-cycle-read.sh:489-490`
**Legibility-target:** for-orchestrator-synthesis (code comment)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** "Each once" holds per call (one awk run). It does not establish dedup across files, which the walks handle with `seen`.

The dedup is `if (!(out in seen)) { seen[out] = 1; print out }` (`:526`). The re-entry/ROOT_REAL probes printed each name once, case kept (`logs/probe-normalize.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:526`

---

## Claim 10: import_targets header: "They read a superset of what Claude Code 2.1.292 can import (its import regex and Markdown lexer: U2a2 and U2a3b security reviews), failing toward "imported""

**Location:** `scripts/lib/dev-cycle-read.sh:492-494`
**Legibility-target:** for-author (code comment)
**Type:** Invariant
**Verdict:** Incorrect (behavioral; high confidence)
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 1.

This is the code-comment form of Claim 1, and the same four classes refute it.

**Evidence:** Claim 1

---

## Claim 11: "Every @ in a line starts a candidate, whatever precedes it and inside code spans and fences too" (commit: "after a letter, in a code span or a fence too")

**Location:** `scripts/lib/dev-cycle-read.sh:494-496`
**Legibility-target:** for-orchestrator-synthesis (code comment / commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers scan's start rule. It does not establish anything about CR-only files, where awk's record is the whole file; every @ in it is still scanned.

The start rule is `for (i = 1; i <= L; i++) { if (substr(line, i, 1) != "@") continue` (`:530-531`), with no test on the preceding byte. `user@docs/mail.md`, `` `@docs/span.md` `` and a fenced `@docs/fence.md` are all read by both walks (`logs/probe-pinned.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:528-540`; `logs/probe-pinned.txt`

---

## Claim 12: "each prefix of the run after it, up to the first blank (a NUL or a UNI_SPACES space counts as one) and at most 4096 bytes, is a candidate name"

**Location:** `scripts/lib/dev-cycle-read.sh:496-498`
**Legibility-target:** for-author (code comment)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stop set and the cap. It does not establish that the cap is safe for the superset (Claim 1, class 4).

The loop is `else if (ch == " " || ch == "\t" || ch == "\r") break` and `name = name ch; emit(name)` (`:536-537`). The precise version has three differences. A CR also ends the run, though it is not a blank. VT and FF do not end it, though JavaScript's `\s` holds them, which is harmless because more prefixes are emitted (`logs/probe-mawk-edges.txt`, item 4). And 4096 caps the name's length, so an escaped space reads two input bytes for one name byte. NUL and the UNI_SPACES become spaces in sed first: `s=(-e 's/\x0/ /g')` with `s+=(-e "s/$u/ /g")` (`:551-552`). mawk under LC_ALL=C handled a UTF-8 é and a lone 0xff byte as bytes, CRLF and lone CR, and a 1 MB line in 0.06 s.

**Evidence:** `scripts/lib/dev-cycle-read.sh:533-537`, `:551-552`; `logs/probe-mawk-edges.txt`, `logs/probe-mawk-edges2.txt`

---

## Claim 13: "with a backslash-escaped space read as a space" (mawk's `"\\"` comparison)

**Location:** `scripts/lib/dev-cycle-read.sh:498`
**Legibility-target:** for-orchestrator-synthesis (code comment)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk's reading of `"\\"` inside the single-quoted program. It does not cover `-v` values (Claim 15).

`printf '@my\\ no\\tes.md @a\\\\ b.md'` gave `my notes.md`-style prefixes ending `my no\tes.md`, and `a\ b.md` for a doubled backslash (`logs/probe-mawk-edges.txt`, item 1). Each prefix of Claude Code's name is listed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:535`; `logs/probe-mawk-edges.txt`

---

## Claim 14: "A line holding <!-- is also read with its closed HTML comments removed (Claude Code splices them)."

**Location:** `scripts/lib/dev-cycle-read.sh:498-499`
**Legibility-target:** for-orchestrator-synthesis (code comment)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-line splice against `reo`'s HTML-block splice. It does not establish the splice's cost (Claim 18b), and Claude Code splices only HTML blocks that start with `<!--`, not inline comments (over-read, harmless).

The splice loop is `while ((i = index(line, "<!--")) > 0) { r = substr(line, i + 4); j = index(r, "-->"); if (j == 0) break` (`:543-545`). On one line it pairs each opener with the first later `-->`, as JavaScript's lazy `/<!--[\s\S]*?-->/g` does. The following is paraphrased — no quote available because it is a case analysis of marked's block-html rule, not a code excerpt. An HTML block that starts with `<!--` ends on the line holding its first `-->`, so the only cross-line removal joins leading indentation to that last line, and the last line's own splice yields the same name. The superset fixture (`hid<!-- y -->den`, `sec<!-- x -->ret`) and the 3000-file fuzz showed no miss.

**Evidence:** `scripts/lib/dev-cycle-read.sh:541-549`; `h/cc.js:4`; `logs/probe-superset-test.txt`, `logs/fz-miss.txt`

---

## Claim 15: "A candidate is resolved lexically against $1 (as realpath -ms does)" (commit: "resolved lexically in one awk program (IMPORT_AWK, as realpath -ms; no fork per candidate)")

**Location:** `scripts/lib/dev-cycle-read.sh:500`
**Legibility-target:** for-author (code comment / commit message)
**Type:** Behavioral
**Verdict:** Incorrect (behavioral; high confidence)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the awk normalization against `realpath -ms --relative-to=ROOT`. It agrees on `a//b`, `./a`, `a/./b`, a trailing slash, `..x`, names with spaces, and dirs `""`, `sub` and `sub/deep`.

It agrees on those inputs (`logs/probe-normalize.txt`). It differs in two ways. A `..` above the root that re-enters is dropped where realpath gives an in-repo path: `../R/docs/x.md` with dir `""` gives `docs/x.md` under realpath and nothing from awk, and `../../R/docs/x.md` with dir `sub` gives `docs/x.md` under realpath and only `sub` from awk (`:521`). And `$1` is not taken literally, because mawk's `-v dir="$1"` (`:558`) turns `\t` into a tab (Claim 1, class 3). "No fork per candidate" is true: one awk per file.

**Evidence:** `scripts/lib/dev-cycle-read.sh:517-525`, `:558`; `logs/probe-normalize.txt`, `logs/probe-mawk-v.txt`

---

## Claim 16: "~/ paths, absolute paths outside ROOT_REAL and paths leaving the repo are dropped, and an absolute path inside ROOT_REAL is read repo-relative."

**Location:** `scripts/lib/dev-cycle-read.sh:500-502`
**Legibility-target:** for-author (code comment)
**Type:** Behavioral
**Verdict:** Incorrect (behavioral; high confidence)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause. `~/` and outside paths are dropped as stated (`~x` is kept, `/R x/...` dropped).

The code is `if (root == "" || index(c, root "/") != 1) return` (`:515`). Absolute paths inside ROOT_REAL are dropped when spelled `//R/...`, `/./R/...` or `/R/../R/...`, and when ROOT_REAL holds a backslash escape. Also, "paths leaving the repo" is applied to paths that only pass through the parent and come back (`../R/docs/x.md`). Both points are Claim 1, classes 1-3.

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-524`; `logs/probe-normalize.txt`, `logs/probe-reentry.txt`

---

## Claim 17: "The cost is false positives: a prefix that is itself a file counts as imported."

**Location:** `scripts/lib/dev-cycle-read.sh:502-503`
**Legibility-target:** for-orchestrator-synthesis (code comment)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `@docs/pre.md.bak` with `docs/pre.md` present. It does not establish that false positives are the only cost (Claim 18b).

Both walks answer `docs/pre.md:Y` at be94c871 and `-` at main and at 47a00c46 (`logs/probe-pinned.txt`).

**Evidence:** `logs/probe-pinned.txt`

---

## Claim 18a: "It returns 1 when sed or awk fails, or when the candidates run past a work bound"

**Location:** `scripts/lib/dev-cycle-read.sh:504-505`
**Legibility-target:** for-author (code comment)
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit status. It does not establish a printf write failure, which only the callers' pipefail catches.

A sed failure returns 1: `toks="$(env LC_ALL=C sed "${s[@]}")" || return 1` (`:555`). Otherwise the status is awk's, because the pipeline ends in `| env LC_ALL=C awk ... "$IMPORT_AWK"` (`:558`). At the bound, `if (work > 50000000) exit 3` (`:512`) returns 3: the heavy file printed `rc=3` (`logs/probe-mawk-edges.txt`, item 7). mawk honours `exit` inside a function. The precise version is "returns non-zero (1 for sed, awk's status otherwise: 3 at the work bound)". Every caller tests with `||` or `if`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:512`, `:555-558`; `logs/probe-mawk-edges.txt`

---

## Claim 18b: "(so a pathological file fails the walk rather than stalling it)" (commit: "a candidate-work bound (50M bytes) makes a pathological file fail the walk rather than stall it")

**Location:** `scripts/lib/dev-cycle-read.sh:505`
**Legibility-target:** for-author (code comment / commit message)
**Type:** Performance
**Verdict:** Incorrect (comment; the stall itself is behavioral; medium-high confidence)
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the splice path. It does not establish a time bound for the walk across many files, since the bound is per awk run.

The bound counts candidate bytes only: `work += length(c)` sits in `emit` (`:512`). `splice` re-copies the rest of the line for each comment (`r = substr(line, i + 4)` ... `line = substr(r, j + 3)`, `:544-545`), so a line of many comments is quadratic and never touches `work`. One line of `<!---->` repeated took 0.05 s at 20,000 comments, 0.86 s at 80,000, and 27.1 s at 320,000 (2.24 MB), all with rc=0 (`logs/probe-mawk-edges2.txt`). By the same curve, about 10 MB would take minutes. Candidate-shaped pathology does fail, as Claim 18a shows.

Commands: `time (timeout 300 bash -c 'source "$1"; ROOT_REAL=/R; import_targets "" < "$2"' _ LIB spl320.txt)`, cwd `/tmp/u2a3b-fcL2-FvuR`, exit 0, 2026-10-07T06:04Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:511-512`, `:541-549`; `logs/probe-mawk-edges2.txt`

---

## Claim 19: "(test/agents-gemini-sync.bats holds a separate, older finder for where an import starts, not these rules)"; A5 "(v2.1.284)"

**Location:** `scripts/lib/dev-cycle-read.sh:506-508`; `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** for-orchestrator-synthesis (code comment, working doc)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file and its version note.

`test/agents-gemini-sync.bats:37` reads "Claude Code v2.1.284 (its extractor, read from the binary during review)", and its finder is `grep -nE '(^|[^[:alnum:]])@(\./|~/|/|[[:alnum:]._-])'` (`:51`).

**Evidence:** `test/agents-gemini-sync.bats:37-51`

---

## Claim 20: UNI_SPACES: "UTF-8 spaces, which end an import token as a blank does (import_targets makes each one a blank first)"

**Location:** `scripts/lib/dev-cycle-read.sh:482-484`
**Legibility-target:** for-orchestrator-synthesis (code comment)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 19 listed code points through both walks. It does not establish JavaScript `\s` members outside the list (none are missing: VT/FF only add prefixes).

The replacement is `for u in "${UNI_SPACES[@]}"; do s+=(-e "s/$u/ /g"); done` (`:552`). The test `build-loop-check.bats:53` covers each of the 19 code points and passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:485-487`, `:552`; `logs/bats.txt`

---

## Claim 21: "Two steps, not a pipe: under pipefail awk's success would not hide a sed failure, but a caller without pipefail would." / "A pipe, not a here-string: bash writes a long here-string to a temp file, and a failed write would read as no imports."

**Location:** `scripts/lib/dev-cycle-read.sh:553-557`
**Legibility-target:** for-orchestrator-synthesis (code comment)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sed step and the here-string rationale. It does not establish a printf write failure for a caller without pipefail.

The sed step is `toks="$(...sed...)" || return 1` (`:555`). The test at `build-loop-check.bats:409-412` (70,000 bytes under `ulimit -f 0`) passes, and `import_targets "" < docs` returns non-zero (`:401`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-558`; `test/scripts/build-loop-check.bats:398-412`; `logs/bats.txt`

---

## Claim 22: "One lower per file, not per candidate: the superset yields many." (commit: "the tree walk lower-cases each file's candidates in one call"); does IMPORTED still hold every candidate lower-cased, one per line?

**Location:** `scripts/lib/dev-cycle-read.sh:594-595`
**Legibility-target:** for-orchestrator-synthesis (code comment / commit message)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers IMPORTED's shape. It does not establish anything about U2a4's readers of IMPORTED.

The code is `lp="$(lower "$out")" || { IMPORTED=error; return 1; }; IMPORTED+="$lp"$'\n'` (`:595`) after `IMPORTED=$'\n'` (`:588`). `out` holds awk's newline-separated names, and awk records cannot hold a newline, so each candidate sits between two newlines, lower-cased by `tr`. The walk over the clone listed 128 entries, all unique, one per line (`logs/measure-with-untracked.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:588-599`; `logs/measure-with-untracked.txt`

---

## Claim 23: "-f first: most candidates name no file, and inrepo_here forks." (commit: "checks -f before inrepo_here")

**Location:** `scripts/lib/dev-cycle-read.sh:597-598`
**Legibility-target:** for-orchestrator-synthesis (code comment / commit message)
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether `-f` first changes which paths are queued. It does not establish timings.

`inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`:129`) already requires `-f`, and `blocker` runs in `$(...)` and calls `realpath` through `rawfile` (`:101`), so it forks. The new `[[ -f "$p" && ... ]] && inrepo_here "$p"` (`:598`) is therefore the same predicate. A symlink to a file passes `-f` and is then judged by blocker, as before. A dangling link or a directory fails either way, so no queue change follows. Of the 122 extra names on the clone, none exists as a file (`logs/fp.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:101`, `:112-129`, `:598`; `logs/fp.txt`

---

## Claim 24: isimported header: "A failed walk, a failed lower of $2, or a walk name that is neither answers imported (0) ..."

**Location:** `scripts/lib/dev-cycle-read.sh:680-684`
**Legibility-target:** for-orchestrator-synthesis (code comment)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three answers. It does not establish need_root behaviour, which the header assigns to the walks.

The answers come from `lp="$(lower "$2")" || return 0`, `main_imports || return 0`, `imported_names || return 0` and `*) return 0` (`:688-692`). The tests at `build-loop-check.bats:43` and `:422` pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:685-694`; `logs/bats.txt`

---

## Claim 25: test comments: "Two NBSPs in one run: the token ends at the first. docs/z.md is imported only after the NUL; gone/ does not exist, and the path is still resolved as written." / "Docs/NB.MD and CLAUDE.md: isimported takes a path in any case."

**Location:** `test/scripts/build-loop-check.bats:28-29`, `:35`
**Legibility-target:** for-orchestrator-synthesis (test comment)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's expectations. "Resolved as written" means lexically (`gone/..` gives `docs/m.md`).

The test passes (`want docs/nb.md. -`, `docs/m.md` imported).

**Evidence:** `test/scripts/build-loop-check.bats:26-41`; `logs/bats.txt`

---

## Claim 26: test name: "both walks read everything Claude Code reads (a superset): ... ~x is over-read, ~/ dropped ..."

**Location:** `test/scripts/build-loop-check.bats:339`
**Legibility-target:** for-orchestrator-synthesis (test name)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this fixture only. It does not establish the general superset (Claim 1).

The harness's names for the fixture are all listed by the parser. The one reported MISS, `docs/h.md\0@docs/i.md,`, holds a NUL that bash dropped in the comparison, and Node cannot open such a path (`logs/probe-superset-test.txt`). `~g.md` fails `reo`'s `/^[a-zA-Z0-9._-]/`, so reading it is an over-read.

**Evidence:** `test/scripts/build-loop-check.bats:339-360`; `logs/probe-superset-test.txt`

---

## Claim 27: test comment: "A cut mark earlier in the name (my_notes) does not hide a later one"

**Location:** `test/scripts/build-loop-check.bats:341-342`
**Legibility-target:** for-author (test comment)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment's mechanism. The fixture still passes.

be94c871 removed cut marks ("The cut-mark, suffix, strip and dedup-map code is gone"), and `rg 'cut mark|cut-mark' scripts/` finds nothing. Every prefix is now emitted (`:537`), so no mark hides anything.

**Evidence:** `scripts/lib/dev-cycle-read.sh:528-540`

---

## Claim 28: test comment: "One grep match runs through a link or code span into the next @ (Claude Code reads both)."

**Location:** `test/scripts/build-loop-check.bats:347`
**Legibility-target:** for-author (test comment)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "grep match" mechanism. The parenthetical (Claude Code reads both) holds per the harness.

`IMPORT_RE` and its grep are gone (`rg IMPORT_RE scripts/` is empty), and `import_targets` now runs `sed` then `awk` (`:555-558`). Every @ starts its own candidate (`:531`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:550-559`

---

## Claim 29: test name: "the superset over-reads, pinned: an @ in a code span or fence, after a letter, a prefix that is a file, an escaped space, an absolute path in the repo" (commit: "a new test pins the over-reads (code span, fence, user@, a prefix that is a file, escaped space, absolute path)")

**Location:** `test/scripts/build-loop-check.bats:362`
**Legibility-target:** for-author (test name / commit message)
**Type:** Behavioral
**Verdict:** Incorrect (test name and commit message only; high confidence)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which cases are over-reads and which need be94c871. It does not affect the test's assertions, which pass.

The harness imports `docs/pre.md.bak docs/my notes.md docs/abs.md` from the fixture (`logs/probe-pinned.txt`). The escaped space and the absolute path are therefore real Claude Code imports, gaps closed rather than over-reads. On the brief's "fail at main" question, the code-span and fence cases are already answered `Y` at main and at 47a00c46, so only mail, pre, my notes and abs pin be94c871's change.

**Evidence:** `test/scripts/build-loop-check.bats:362-374`; `logs/probe-pinned.txt`

---

## Claim 30: test comment: "Seven 4200-byte runs after an @ pass the candidate-work bound: the parser returns 1."

**Location:** `test/scripts/build-loop-check.bats:375`
**Legibility-target:** for-author (test comment)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and the status. The test's `if ...; else echo failed` accepts any non-zero.

Each run caps at 4096, so it costs 4096·4097/2 = 8,390,656. The bound is passed during the sixth run, since six runs total 50,343,936. The parser returns 3, not 1 (`logs/probe-mawk-edges.txt`, item 7).

**Evidence:** `scripts/lib/dev-cycle-read.sh:512`, `:533`; `logs/probe-mawk-edges.txt`

---

## Claim 31: test name/comment: "an email-shaped token is over-read (superset)"; "Mail user@docs/email.md is no import for Claude Code, but the superset reads it." (commit: "the email case in dev-cycle.bats is now refused")

**Location:** `test/scripts/dev-cycle.bats:1059`, `:1063`
**Legibility-target:** for-orchestrator-synthesis (test name/comment / commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `user@` shape.

`reo` needs `(?:^|\s)` before `@`, so the harness omits `docs/mail.md` in the pinned fixture, while both walks list it (`logs/probe-pinned.txt`). The test passes.

**Evidence:** `test/scripts/dev-cycle.bats:1059-1072`; `logs/probe-pinned.txt`; `logs/bats.txt`

---

## Claim 32: commit: "two exact-output assertions check membership instead"

**Location:** `test/scripts/build-loop-check.bats:412`; `test/scripts/dev-cycle.bats:1175-1180`
**Legibility-target:** for-orchestrator-synthesis (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two edits in `git show be94c871 -- test`. The root-change test still distinguishes the roots, since each prints only its own path.

The edits are `printf '%s\n' "$output" | grep -qxF docs/big.md` (`build-loop-check.bats:412`) and `w() { for p in docs/a.md docs/b.md; do if [[ "$IMPORTED" == *...* ]]` (`dev-cycle.bats:1175`).

**Evidence:** `git show be94c871 -- test`

---

## Claim 33: commit: "--check-fix answers are identical to main's (14 ok, 0 refused as imported; the same in a clean clone of main), so 0 new false positives." (919 tracked docs/*.md and README.md)

**Location:** commit be94c871 message
**Legibility-target:** for-orchestrator-synthesis (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a clean clone at f6fdda68, and the same clone with /workspace's 488 untracked `.md` files copied in to stand in for /workspace. The live /workspace was not run. 905 of the 919 are refused before the import test, so the answer-level check exercises 14 paths. Claim 2 covers the full list.

`git ls-files 'docs/*.md' README.md | wc -l` gives 919. Both runs gave main `ok=14 imported=0 walkfailed=0 lines=919`, be94c871 the same, and "check-fix outputs identical" (`logs/measure.txt`, `logs/measure-with-untracked.txt`). Command: `bash measure.sh`, cwd `/tmp/u2a3b-fcL2-FvuR`, exit 0, 2026-10-07T06:06-06:07Z.

**Evidence:** `logs/measure.txt`, `logs/measure-with-untracked.txt`, `logs/checkfix-main.txt`, `logs/checkfix-new.txt`

---

## Claim 34: commit: "Tree walk 650 ms at main, 863 ms now (128 candidate paths against 6); main walk in a clean clone 460 ms at main, 700 ms now (64 against 3)."

**Location:** commit be94c871 message
**Legibility-target:** for-orchestrator-synthesis (commit message)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the counts exactly, and the times within single-run variance on this machine.

The tree walk took 660 → 920 ms with 6 → 128 entries (clone plus untracked files). The main walk in the clean clone took 432 → 763 ms with 3 → 64 entries (`logs/measure*.txt`).

**Evidence:** `logs/measure.txt`, `logs/measure-with-untracked.txt`

---

## Claim 35: commit: "main_imports' per-path lower stays (U2a3's code; 64 forks here)"

**Location:** commit be94c871 message; `scripts/lib/dev-cycle-read.sh:670`
**Legibility-target:** for-orchestrator-synthesis (commit message)
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the clean clone.

The code is `i="$(lower "$p")" || { IMPORTED_MAIN=error; return 1; }` (`:670`), once per non-empty line. 64 lines gives 64 forks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:668-677`; `logs/measure.txt`

---

## Claim 36: commit: "Tests: 121/121 across the five suites; shellcheck clean"

**Location:** commit be94c871 message
**Legibility-target:** for-orchestrator-synthesis (commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five named suites and shellcheck on the two changed scripts.

`TMPDIR=/tmp/u2a3b-fcL2-tmp-HBcY bats` on the five suites gave rc=0, 121 `ok` lines and no `not ok`. `shellcheck scripts/lib/dev-cycle-read.sh scripts/dev-cycle.sh` gave rc=0 with empty output. cwd `/tmp/u2a3b-fcL2-FvuR`, 2026-10-07T06:07Z.

**Evidence:** `logs/bats.txt`, `logs/shellcheck.txt`

---

## Claim 37: commit: "350 changed code lines against main"

**Location:** commit be94c871 message
**Legibility-target:** for-orchestrator-synthesis (commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pr-prep 1a's rule (changed lines outside `docs/`, against the merge base).

`git diff --numstat main...be94c871 | awk '$3 !~ /^docs\// ...'` gives `+284 -66 = 350`.

**Evidence:** `git diff --numstat main...be94c871`; `workflows/pr-prep.md:155`

---

## Claim 38: commit: "The cut-mark, suffix, strip and dedup-map code is gone (IMPORT_RE too)."

**Location:** commit be94c871 message
**Legibility-target:** for-orchestrator-synthesis (commit message)
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers scripts/ (the tests still mention the cut mark; see Claims 27 and 28).

`rg 'IMPORT_RE|cut mark|cut-mark' scripts/` returns nothing, and the sourcing test checks `IMPORT_AWK` (`dev-cycle.bats:1099`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:509-559`; `test/scripts/dev-cycle.bats:1099`

---

## Claim 39: imported_names header: "resolves each @path against the importing file's directory as Claude Code does (import_targets reads a superset of its names and drops ~/ and paths outside the repo)"

**Location:** `scripts/lib/dev-cycle-read.sh:449-451`
**Legibility-target:** for-author (code comment)
**Type:** Behavioral
**Verdict:** Incorrect (behavioral; high confidence)
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 1 and 15.

The parser also drops in-repo paths reached through the parent, and mis-resolves names under a directory holding a backslash (Claim 1, classes 1 and 3). In those cases it does not resolve as Claude Code does.

**Evidence:** Claims 1, 15

---

## Claim 40: commit: "every @ ... a line holding <!-- is also read with its closed comments spliced out; deduplicated per file; ~/, paths outside ROOT_REAL and paths leaving the repo are dropped"

**Location:** commit be94c871 message
**Legibility-target:** for-orchestrator-synthesis (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these clauses only. The "as realpath -ms", absolute-path and work-bound clauses are Claims 15, 4b/16 and 18b.

Same evidence as Claims 9, 11 and 14.

**Evidence:** `scripts/lib/dev-cycle-read.sh:511-549`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/working/known-issues-dev-cycle.md:18`): the parser is not a superset. `@../<repo>/docs/x.md` is missed (a regression from main, which refused it), as are `//root/...`, `/./root/...`, `/root/../root/...`, directories or roots holding a backslash (mawk `-v` escapes), and names over 4096 bytes. Behavioral, high.
- **Claim 3** (`known-issues-dev-cycle.md:18`): the sole stated non-coverage (non-prefix names, entity decode) is incomplete, and the lexer does not decode entities. Doc only, high.
- **Claim 4b** (`known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:473-476`): "absolute imports" removed from Not covered, though only the literal-ROOT_REAL spelling is covered. Doc/comment, high.
- **Claim 5** (`docs/working/plan-build-loop-handoff.md:126`): F11's superset and absolute-path wording, as in Claims 1 and 4b. Doc, high.
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:492-494`): the "superset" comment, as in Claim 1. Behavioral, high.
- **Claim 15** (`scripts/lib/dev-cycle-read.sh:500`; commit): "as realpath -ms does" is false for parent re-entry and for `$1` holding backslash escapes. Behavioral, high.
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:500-502`): non-literal absolute spellings inside ROOT_REAL and parent-passing paths are dropped. Behavioral, high.
- **Claim 18b** (`scripts/lib/dev-cycle-read.sh:505`; commit): the work bound does not cover `splice`, which is quadratic (27 s for a 2.24 MB comment line). Comment, medium.
- **Claim 29** (`test/scripts/build-loop-check.bats:362`; commit): escaped space and absolute path are real imports, not over-reads; the span and fence cases already pass at main. Test name/commit only, high.
- **Claim 39** (`scripts/lib/dev-cycle-read.sh:449-451`): "as Claude Code does", as in Claims 1 and 15. Behavioral, high.

### Stale
- **Claim 27** (`test/scripts/build-loop-check.bats:341-342`): the cut-mark mechanism is gone.
- **Claim 28** (`test/scripts/build-loop-check.bats:347`): "One grep match" refers to the removed IMPORT_RE grep.

### Mostly Accurate
- **Claim 12** (`scripts/lib/dev-cycle-read.sh:496-498`): CR also ends a run, VT/FF do not, and 4096 caps the name rather than the bytes read.
- **Claim 18a** (`scripts/lib/dev-cycle-read.sh:504-505`): returns awk's status (3 at the bound), not 1.
- **Claim 30** (`test/scripts/build-loop-check.bats:375`): the bound trips in the sixth run, and the parser returns 3.

### Unverifiable
- None. (Residue in Claim 1: `~/` into a repo under `$HOME` was not executed against real Claude Code.)

## Escalations

- **security-reviewer:** the superset holes in Claim 1. The `../<repo-dir>/` re-entry is a fail-open regression from main at the `--check-fix` level (main `skip`, be94c871 `ok`). The others are non-literal absolute spellings, mawk `-v` escape processing of `dir`/`root`, names over 4096 bytes, and `~/` under `$HOME`.
- **performance-reviewer:** Claim 18b, the quadratic `splice` outside the work bound. The bound is also per file, with none across the walk.
- **orchestrator:** Claims 27-30, test-name and comment corrections only.

## Goal-Alignment Note

- **Asked:** Stage-1 code fact-check (k=1, loop pass) of `main...HEAD` at be94c871. That covered import_targets' header sentence by sentence, mawk behaviour, the commit's measurements, imported_names' lower and `-f` change, A5/F11 prose, and the test names and comments, executed where possible.
- **Answered:** all six focus items, as 42 claims (27 Verified, 3 Mostly accurate, 2 Stale, 10 Incorrect). Every measurement in the commit message reproduced: 919 paths, 14 ok and 0 imported with identical answers, 0 new false positives among tracked files, 128/6 and 64/3 entries, 121/121 tests, shellcheck clean, and 350 lines.
- **Not answered / residue:** real Claude Code beyond the 2.1.292 harness, the `~/`-under-`$HOME` case, and the live /workspace checkout (approximated by a clone with its untracked `.md` files).
- **Fit:** the review question was whether the parser is really a superset. It is not: Claim 1 has four executed counterexamples, one of them a regression from main that turns a refused path into `ok`. The documented non-coverage (A5, F11, the main_imports header) understates the gaps. Fail-closed handling (Claim 8) and the false-positive cost (Claims 2 and 33) hold.
