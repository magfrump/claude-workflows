Commit: e1654266

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b)
**Scope:** `git diff main...e1654266 -- . ':!docs/reviews'` (scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md) and the commit messages `git log main..e1654266` (be94c871, dd51e9a7, 98e3b1df, e1654266 in detail)
**Checked:** 2026-10-07
**Total claims checked:** 48 (Claims 1-47, with 27 split into 27a/27b)
**Summary:** 34 verified, 7 mostly accurate, 4 stale, 1 incorrect, 2 unverifiable
**Commit:** e1654266
**Replication:** k=3 (this report is replicate r2 of the final confirming pass)

Method. I read the whole of `scripts/lib/dev-cycle-read.sh` from the header (`:1-38`), need_root/rawfile/plaindir/blocker/inrepo_here (`:98-135`), and the walk section from INSTRUCTION_FILE to isimported (`:440-780`), including all of IMPORT_AWK. I also read `check_fix` and the `--check-fix` help in `scripts/dev-cycle.sh:40-60,144-186`, and every added test in both bats files. Code was mutated only in `git archive` copies (`/tmp/u2a3bfcfin-Q1w0` holds e1654266; `/tmp/u2a3bfcfin-Q1w0-tmp/old-*` holds be94c871 and 98e3b1df with e1654266's tests; mutant copies are in `/tmp/u2a3bfcfin-m-*`). The Claude Code oracle was the installed 2.1.292 binary, `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` (`claude --version` prints `2.1.292 (Claude Code)`). I read its strings at these offsets: `Ye` (resolver) ≈205304326, `ZMe`/`teo`/`kOe`/`reo`/`EF` ≈212104518-212112000, marked's `inlineText` 210336074, `lex` 210336957, `EP` 212114352, `AD` 212104475. Bun could not be run: `BUN_BE_BUN=1 claude.exe -e` prints `error: unknown option '-e'`. Node v22.23.2 stands in where noted. The system awk is mawk. Execution logs are in `/tmp/u2a3bfcfin-Q1w0-tmp/`, and no worktree file except this report was written. I read the hallucination-pattern log; its nearest patterns are the measured-value entries (test counts, corpus figures), and every count below was re-executed. No fabrication was found.

Suites (executed): `TMPDIR=$(mktemp -d /tmp/u2a3bfcfinT-XXXX) timeout 1500 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`, cwd `/workspace/.claude/wt-build-loop-u2a3b` (HEAD e1654266), 2026-10-07T09:08:56Z-09:09:45Z, exit 0, **143/143 ok** (`/tmp/u2a3bfcfin-Q1w0-tmp/suite.log`).

---

## Claim 1: A3: "Imports through a symlinked file or directory, and absolute-path imports into the repo, print `ok`."

**Location:** `docs/working/known-issues-dev-cycle.md:17`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absolute-path half of A3 for `--check-fix` (the tree walk). It does not establish the symlinked-file and symlinked-directory halves, which this unit did not change.
**Legibility-target:** for-author

A3's absolute-import half no longer holds. The unit makes every candidate absolute and keeps it when it lies below ROOT_REAL: `if (substr(c, 1, 1) != "/") c = root "/" dir "/" c` … `if (index(out, pre) != 1 || length(out) <= length(pre)) return` (`scripts/lib/dev-cycle-read.sh:551,559`). The unit also deleted the matching "absolute imports into the repo" item from A5's "Not covered" list and from the main_imports header (diff lines in A5 and `:474-477`), but A3, one row above, still says they print `ok`. I ran this in a fixture repo whose CLAUDE.md holds `See @<root>/docs/x.md`. main's `dev-cycle.sh --check-fix docs/x.md` prints `ok docs/x.md`, while e1654266 prints `skip docs/x.md: an instruction file names it after an @ …` (`a3.log`). The absolute-path half of A3 is closed for `--check-fix`.

**Evidence:** `docs/working/known-issues-dev-cycle.md:17`, `scripts/lib/dev-cycle-read.sh:551-563`, `/tmp/u2a3bfcfin-Q1w0-tmp/a3.log` (command: fixture in `/tmp/u2a3bfcfin-a3-kEbR/r`, `timeout 60 bash <lib copy>/dev-cycle.sh --check-fix docs/x.md docs/y.md` for main and e1654266, 2026-10-07T09:23:08Z, exit 0)

---

## Claim 2: A5: "Both walks share one token parser (`import_targets`) … the claim, its rules and its exceptions are stated once, in the comment above `import_targets`"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one-parser call structure and the pointer to the statement. It does not establish that the statement is complete (Claims 23-24).
**Legibility-target:** for-orchestrator-synthesis

The tree walk calls `out="$(head -c 4194305 -- "$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d")"` (`scripts/lib/dev-cycle-read.sh:669`). The main walk calls `git cat-file blob "$MAIN_SHA:$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d"` (`:711`). The statement opens with `# The superset claim (the one statement of it; known issue A5 and plan F11` (`:501`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:501,669,711`

---

## Claim 3: A5: "Its cost is false positives (none among this repo's tracked docs on 2026-10-06)."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-fix` over every tracked `docs/*.md` and README.md in the worktree (948) and in /workspace's main checkout (919), as of today. It does not establish the 2026-10-06 measurement itself.
**Legibility-target:** for-orchestrator-synthesis

I ran main's `dev-cycle.sh` and e1654266's on the same path list. With the two wordings normalized (main says "imports it with @", e1654266 says "names it after an @"), the outputs are byte-identical on 948 paths in the worktree and on 919 in /workspace. Both list 14 `ok` and 0 import refusals (`timing.log`, `wn-main.txt`, `wn-head.txt`, `n-main.txt`, `n-head.txt`).

**Evidence:** `/tmp/u2a3bfcfin-Q1w0-tmp/timing.log`, `/tmp/u2a3bfcfin-Q1w0-tmp/wn-{main,head}.txt`, `/tmp/u2a3bfcfin-Q1w0-tmp/n-{main,head}.txt` (cwd `/workspace/.claude/wt-build-loop-u2a3b` and `/workspace`, about 09:20Z-09:22Z, exit 0 each)

---

## Claim 4: A5: "The oracle it was checked against was Claude Code 2.1.292's import regex and Markdown lexer, extracted from the installed package into a scratch fuzzer by the U2a2 and U2a3b security reviews; that harness is not kept"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the cited reviews say about how they built their harnesses. It does not re-run those harnesses.
**Legibility-target:** for-author

This is unchanged since the L2-i2 fact-check (its Claim 2, Mostly accurate). That check found the import regex was transcribed, not extracted; only the lexer bytes were extracted. It also found U2a2's harness was a 27-line differential harness, not a fuzzer (quoted there from `security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:13,123`). No harness is tracked (paraphrased; no quote available because the claim concerns absence: no fuzz or harness file for this unit is in `git ls-files`). The rubric records no disposition for that claim. Precise version: "transcribed (regex) and extracted (lexer) … into a differential harness (U2a2) and a fuzzer (U2a3b)".

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i2.md:45`

---

## Claim 5: A5: "`test/agents-gemini-sync.bats` holds a separate, older finder for where an import starts (v2.1.284), not these rules."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file's own version note and its grep. It does not check that finder's accuracy.
**Legibility-target:** for-orchestrator-synthesis

`# Claude Code v2.1.284 (its extractor, read from the binary during review)` (`test/agents-gemini-sync.bats:37`). Its finder is `grep -nE '(^|[^[:alnum:]])@(\./|~/|/|[[:alnum:]._-])'` (`:51`), which is not IMPORT_AWK.

**Evidence:** `test/agents-gemini-sync.bats:37-51`

---

## Claim 6: A5: "Traced in Claude Code 2.1.292 … a symlinked instruction file's imports resolve from its target's directory (`path.resolve(dirname(realpath(importer)), name)`), as the walk does, and an `@` token's `..` after a directory link is resolved lexically, as the walk does."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the minified resolver chain in the installed binary. It does not run Claude Code (Bun could not be started).
**Legibility-target:** for-orchestrator-synthesis

Binary strings (paraphrased; no quote available with path:line because the source is a minified 251 MB executable, so offsets stand in for lines). `EF` takes `{resolvedPath:he}` from `ro(se(),e)` and calls `kOe(e,n,he,S)`, which calls `ZMe(h,e,n,r)` with `r`=`he`. `ZMe` calls `reo(G,s)`, and `reo` calls `Ye(H,FT(n))` with `n` the resolved importer path. `Ye` ends `return Hn(x(i,o))`, with `x` path's `resolve` (offset ≈205304326: `let n=e.trim();…if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)));…return Hn(x(i,o))`). `Hn` in that region is `function Hn(t){return t}` (offset 203416965). Both halves of A5's sentence match the walk's lexical `put` (`scripts/lib/dev-cycle-read.sh:550-563`) and the main walk's symlink arm.

**Evidence:** claude.exe offsets 203416965, ≈205304326, ≈212108000-212112000; `scripts/lib/dev-cycle-read.sh:550-563,712-731`

---

## Claim 7: plan F11: "Gaps: known issue A5 (… checkout conversions …, and three shapes untraced against Claude Code)"; lib: "and three shapes A5 lists as untraced against Claude Code."

**Location:** `docs/working/plan-build-loop-handoff.md:126`; `scripts/lib/dev-cycle-read.sh:477-478`
**Type:** Staleness / Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of untraced items. It does not judge whether the remaining item matters.
**Legibility-target:** for-author

A5 now moves two of its three former untraced items into a "Traced in Claude Code 2.1.292" sentence and keeps one: `Untraced (no host probe yet): whether `@` references in `.claude/commands/` files load.` (`docs/working/known-issues-dev-cycle.md:18`). F11 still says "three shapes untraced against Claude Code" (`plan-build-loop-handoff.md:126`). The main_imports header comment, in a block this unit edited, still says `# checkout conversions (A5), and three shapes A5 lists as` / `# untraced against Claude Code.` (`scripts/lib/dev-cycle-read.sh:477-478`). Both should say one shape (`.claude/commands/` files).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:477-478`

---

## Claim 8: plan F11: "The shared token parser reads a superset of Claude Code 2.1.292's import grammar (U2a3b; the claim and its exceptions are stated once, above `import_targets`); a Claude Code upgrade that changes its import grammar reopens this row."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pointer. Completeness of the superset is Claims 23-24.
**Legibility-target:** for-orchestrator-synthesis

The statement sits above `import_targets` (`scripts/lib/dev-cycle-read.sh:501-532`) and ends `# Re-check the superset when Claude Code changes its import grammar` (`:530`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:501-532`

---

## Claim 9: plan step 5, U2a3c bullet: "one capped and drained reader (4 MiB + 1, Claude Code's limit) … (a bare `head` after `git cat-file` exits 141 under pipefail …); … no third path resolver (IMPORT_AWK's `put` and the symlink arm's `realpath -ms` are the two)"

**Location:** `docs/working/plan-build-loop-handoff.md:281`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 141 status, Claude Code's byte limit, and the count of resolvers in the lib. It does not establish U2a3c's future design.
**Legibility-target:** for-orchestrator-synthesis

I ran `set -o pipefail; git cat-file blob <6,000,000-byte blob> | head -c 4194305 >/dev/null` and it printed `cat-file|head rc=141` (`catfile.log`). Claude Code reads `length:nH+1` and skips `if(s.totalBytes>nH)` (`teo`, offset ≈212105900). Only two path resolvers appear in the lib's import code: `put` (`scripts/lib/dev-cycle-read.sh:550-563`) and the symlink arm's `realpath -ms --relative-to="$ROOT_REAL"` (`:724,727`).

**Evidence:** `/tmp/u2a3bfcfin-Q1w0-tmp/catfile.log` (cwd `/tmp/u2a3bfcfin-cat-*`, about 09:24Z, rc 141 as the probe's subject), claude.exe ≈212105900, `scripts/lib/dev-cycle-read.sh:550-563,724,727`

---

## Claim 10: plan step 5, U2b bullet: "the parser's root and home are the gate's own, but a session in another checkout (`git worktree list`) or under another HOME reads absolute and `~/` names against its own"

**Location:** `docs/working/plan-build-loop-handoff.md:283`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parser's inputs. It does not establish U2b's root-set design.
**Legibility-target:** for-orchestrator-synthesis

The parser's only root and home inputs are `IT_ROOT="${ROOT_REAL:-}" IT_HOME="$IMPORT_HOME" IT_HOMER="$IMPORT_HOMER"` (`scripts/lib/dev-cycle-read.sh:631`), and `import_home` reads this process's HOME (`:606`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:606,631-632`

---

## Claim 11: dev-cycle.sh help: "or a file an instruction file names after an @, read broadly; compared ignoring case) or README.md; "skip <path>: <reason>" otherwise, and for every path when the import walk fails."

**Location:** `scripts/dev-cycle.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix's branch order and the walk-failed arm. It does not establish wording for globs and path-form refusals, which are unchanged.
**Legibility-target:** for-orchestrator-synthesis

Every branch before `check_path` prints `skip`, and the walk-failed arm comes before the only `ok` path: `elif ! imported_names; then echo "skip $a: the instruction-file import walk failed, …"` … `else check_path "$a"; fi` (`scripts/dev-cycle.sh:181-185`). The test "--check-fix words a failed import walk as one and refuses (U2a3b)" passes in the 143/143 run.

**Evidence:** `scripts/dev-cycle.sh:170-186`, `test/scripts/dev-cycle.bats:1048-1056`, `/tmp/u2a3bfcfin-Q1w0-tmp/suite.log`

---

## Claim 12: lib header: "The import walks also need python3 when an instruction file holds text that is not well-formed UTF-8; without it they fail closed."

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when python3 forks and the failure arm. It does not establish other decoders.
**Legibility-target:** for-author

The mechanism holds. python3 forks only when the gate rejects a line (`if [[ "$toks" == *[$'\x80'-$'\xff']* ]] && ! printf '%s\n' "$toks" | env LC_ALL=C awk -v ok="$UTF8_OK" '$0 !~ ok { exit 1 }'; then`, `:622`), and a failing python3 returns 1 (`:623`). The test "both walks fail closed when python3 fails …" passes. The trigger is wider than "an instruction file", though. The parser runs on every file the walk reads, including imported docs and, in the tree walk, the first 4 MiB of any plain file a prefix candidate names (`if [[ -f "$p" && …` at `:678` queues any such file, then `:669` reads it). Precise version: "when a file the walk reads holds text …".

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-13,622-625,669,678`, `test/scripts/build-loop-check.bats:573-580`, `/tmp/u2a3bfcfin-Q1w0-tmp/gate.log`

---

## Claim 13: lib header: "(check_answer, brief_fields, tree_starts, imported_names and main_imports also set pipefail for themselves)"; "imported_names and main_imports return 1 when the walk fails: call them under if or ||."

**Location:** `scripts/lib/dev-cycle-read.sh:14-16,21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three walk functions this unit touched. check_answer and brief_fields are unchanged and were not re-read here.
**Legibility-target:** for-orchestrator-synthesis

`tree_starts() { local -; set -o pipefail; …` (`:647`), `local - f d p lp out used=0 …; set -o pipefail` (`:649`), and `local - rec f d p i c lk out used=0 …; set -o pipefail` (`:693`). Both walks' failure arms `return 1`, and the callers in scripts/ use `elif ! imported_names` (`scripts/dev-cycle.sh:181`) and `main_imports || return 0` (`:775`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:647,649,693,775-776`, `scripts/dev-cycle.sh:181`

---

## Claim 14: imported_names header: "(import_targets reads a superset of its names, ~/ against this process's HOME, and drops paths outside the repo) … It returns 1, with IMPORTED set to "error", when the start listing (git ls-files, untracked_md, instruction_names), lower, a file read or the parser fails, or a start file's name holds a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:452-458`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `return 1` in imported_names (`:648-680`, read whole). It does not establish callers outside scripts/.
**Legibility-target:** for-author

Each listed arm exists. The list leaves out two arms this unit added: `import_home || return 1` (`:662`), and the walk-wide budget, `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED=error; return 1; }` (`:671`). That second arm is described only in the IMPORT_OUT_MAX comment (`:484`). Each of these returns 1 with IMPORTED still or again "error", so the conclusion holds and only the list is incomplete. "~/ against this process's HOME" is right in effect, with the passwd fallback (`:606`; Claim 27).

**Evidence:** `scripts/lib/dev-cycle-read.sh:452-458,648-680`

---

## Claim 15: main_imports header: "returns 1, with IMPORTED_MAIN set to "error" … when main is not found by name, … a blob cannot be read, symlink text … or an imported path main lacks lies under …"

**Location:** `scripts/lib/dev-cycle-read.sh:680-691`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arms this unit added to main_imports (`:692-766`, read whole). Older arms were checked in U2a3's review and not re-verdicted.
**Legibility-target:** for-author

The header names no parser failure, IMPORT_OUT_MAX budget, `import_home` or per-file `lower` arm. This unit added three of them: `import_home || return 1` (`:719`), `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED_MAIN=error; return 1; }` (`:747`) and `i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }` (`:750`). "a blob cannot be read" covers the parser arm only loosely: `out="$(git cat-file blob … | … import_targets "$d")" || {…}` (`:711`) also fails on the parser's own failures (Claim 25). Every arm fails closed, so only the list is incomplete.

**Evidence:** `scripts/lib/dev-cycle-read.sh:680-691,711,719,747,750`

---

## Claim 16: IMPORT_OUT_MAX: "Each walk fails once import_targets has printed more than this in all (characters, newlines between names counted; awk counts bytes, so it may stop first) … A fresh clone's walks print about 2 KB, /workspace's about 6 KB. A caller that changes it clears IMPORTED_DONE and IMPORTED_MAIN_DONE before walking again."

**Location:** `scripts/lib/dev-cycle-read.sh:484-490`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the boundary, the units, the two size figures (via ${#IMPORTED}, which adds one newline per file) and the cache key. It does not establish the size of other checkouts.
**Legibility-target:** for-orchestrator-synthesis

The walks charge `${#out}` (characters in the caller's locale), while awk under `LC_ALL=C` counts bytes (`printed += length(out) + 1`, `:563`). The check is `<= IMPORT_OUT_MAX` (`:671,747`), so the walk fails on "more than", and the test asserting `26 tree ok` at exactly 26 passes. Sizes (`sizes.log`): a fresh clone of e1654266 has `IMPORTED=2020` and `IMPORTED_MAIN=2020`; /workspace's tree walk has `IMPORTED=5607` (5.6 KB, "about 6 KB"); /workspace's main walk fails, as A5 documents. The cache key is `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` or `"$ROOT_REAL"` (`:651,696`), which omits IMPORT_OUT_MAX, so the instruction to clear the DONE caches is needed and correct. The tests do exactly that (`IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""`, `test/scripts/build-loop-check.bats:404,604`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:484-490,563,651,671,696,747`, `/tmp/u2a3bfcfin-Q1w0-tmp/sizes.log` (09:15:47Z, exit 0)

---

## Claim 17: import_targets header: "one repo-relative path per line, case kept, each once."

**Location:** `scripts/lib/dev-cycle-read.sh:498-499`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers one call's output. Names repeat across calls (the walks dedup separately).
**Legibility-target:** for-orchestrator-synthesis

`if (out in seen) return` / `seen[out] = 1; …; print out` (`:561-564`). No case folding happens before print.

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-564`

---

## Claim 18: UNI_SPACES: "U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F, U+3000 and U+FEFF (Claude Code's token ends at JavaScript's \s)"

**Location:** `scripts/lib/dev-cycle-read.sh:491-496`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the non-ASCII members of JS `\s` and the array's bytes. JS `\s` also holds `\v` and `\f`, which awk does not treat as blanks; that only over-reads, since every prefix is emitted.
**Legibility-target:** for-orchestrator-synthesis

The array holds the 19 UTF-8 encodings `$'\xc2\xa0'` … `$'\xef\xbb\xbf'` (`:494-496`). `reo`'s regex is `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` (offset ≈212107518).

**Evidence:** `scripts/lib/dev-cycle-read.sh:491-496`, claude.exe ≈212107518

---

## Claim 19: The superset statement's rules: "Every @ in a line starts a candidate … each prefix of the run after it, up to the first blank (a NUL or a UNI_SPACES space counts as one), is a candidate name, with a backslash-escaped space read as a space. A line holding <!-- is also read with its closed HTML comments removed … text holding a byte above 0x7f is also read decoded … Each candidate is trimmed of spaces, made absolute (ROOT_REAL/$1/name unless it starts with /) and resolved lexically, .. stopping at / … kept only when it lies below ROOT_REAL, and printed repo-relative. A ~/ name is joined to this process's home (import_home), in its spelled and real forms."

**Location:** `scripts/lib/dev-cycle-read.sh:504-516`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each rule against IMPORT_AWK and import_targets (`:533-632`, read whole). Whether the rules are a superset of Claude Code is Claim 20.
**Legibility-target:** for-orchestrator-synthesis

Each rule maps to a line of code:
- Every @: `if (substr(line, i, 1) != "@") continue` over all `i` (`:568-569`).
- Every prefix to the first blank: `name = name ch; emit(name)` until `ch == " " || ch == "\t" || ch == "\r"` (`:573-575`).
- Escaped space: `if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ }` (`:573`).
- NUL and UNI_SPACES become blanks: `s=(-e 's/\x0/ /g')` plus one `s/$u/ /g` per space (`:612-614`).
- Splice: `{ scan($0); if (index($0, "<!--")) scan(splice($0)) }` (`:592`), where `splice` removes only closed comments (`j = index(r, "-->"); if (j == 0) break`, `:583`).
- U+FFFD decoding, gated: `:622-625` (Claim 26).
- Trim: `sub(/^ +/, "", c); sub(/ +$/, "", c)` (`:539`).
- Absolute, clamp and below-root, as quoted in Claim 1 (`:551-560`).
- ~/: `if (homer != home) put(homer "/" substr(c, 3))` / `c = home "/" substr(c, 3)` (`:545-546`).

Executed: the superset, re-entry, absolute, backslash, long-name, splice3, clamp, HOME and HOME-symlink tests all pass at HEAD (`suite.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:504-516,533-632`, `/tmp/u2a3bfcfin-Q1w0-tmp/suite.log`

---

## Claim 20: "these rules read every name Claude Code 2.1.292 can import … Known exceptions, where a session reading the file can import what these rules do not yield: a session whose home differs from this process's (its ~/ names), a session in another checkout of the repo …, names that differ only in case on a case-insensitive file system (docs/reviews/override-log.md line 350), Claude Code's approved external includes, and any further decoding it may add (an entity, a percent escape)."

**Location:** `scripts/lib/dev-cycle-read.sh:502-523`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers 2.1.292's name pipeline as read from the binary: marked's `lex` (only CR normalization outside pedantic mode), `inlineText` (`text:n[0]`, no entity escaping), `reo`'s regex, `#` cut, `\ ` replace, its filter and HTML-block splice, and `Ye`'s trim, `~/` join and `resolve`. It does not establish Bun's runtime behaviour (not runnable), what `AD`/`Pd` compares (the module-local `Pd` could not be identified in the bundle), or Claude Code's handling of an empty `homedir()` (Claim 27b).
**Legibility-target:** for-orchestrator-synthesis

I checked each step of Claude Code's pipeline for a name it could reach that the rules do not yield, quoting the binary strings by offset (paraphrased with offsets; no path:line exists in a minified executable). `lex(e){e=e.replace(_r.carriageReturn,…)` with `carriageReturn:/\r\n|\r/g`, and tabs are replaced only `if(this.options.pedantic)` (210336957, 210315713). Inline text is raw: `return{type:"text",raw:n[0],text:n[0],…}` (210336074). So the text `reo` scans is a contiguous source substring, or for an HTML block whose `trimStart()` starts with `<!--`, its raw text with `/<!--[\s\S]*?-->/g` removed. A comment HTML block ends at the first line holding `-->`, so its removals never join pieces across lines. awk's per-line splice reproduces this, since the block's first comment opens at its start. `reo` cuts at `#` and replaces `\ ` with a space, and those yield prefixes or the escaped-space spelling of the awk run. `EP` (UNC, `^[\\/]{2}`) and the `^[a-zA-Z0-9._-]`/`./`/`~/`/`/` filter only narrow Claude Code's set. `ZMe` skips non-text extensions (`if(g&&!f8n.has(g))`), which also narrows. `Ye` trims, joins `~/` to `c()` (homedir) and otherwise uses `resolve`, all mirrored in emit/put (Claim 19). I found no shape outside the five named exceptions. Bun's decoder (Claim 26) and empty HOME (Claim 27b) are the residues. Case-insensitive names: `docs/reviews/override-log.md:350` is the row "other names on a case-insensitive checkout". Verified for that row.

**Evidence:** claude.exe offsets 203416965, ≈205304326, 210315713, 210336074, 210336957, ≈212104518-212112000, 212114352; `scripts/lib/dev-cycle-read.sh:502-523,533-592`; `docs/reviews/override-log.md:350`

---

## Claim 21: "The cost is false positives: a prefix that is itself a file counts as imported, and so does a name led by an escaped space."

**Location:** `scripts/lib/dev-cycle-read.sh:522-524`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named over-reads. It does not enumerate every over-read (code spans, `user@`, `~x` are pinned in the over-read test too).
**Legibility-target:** for-orchestrator-synthesis

The over-read test pins `docs/pre.md` (from `@docs/pre.md.bak`) and `docs/lead.md` (from `@\ docs/lead.md`) as imported in both walks, and it passes. `reo`'s filter rejects a name led by a space before `Ye` trims anything (no branch accepts a leading space; offset ≈212107518).

**Evidence:** `test/scripts/build-loop-check.bats:365-388`, `scripts/lib/dev-cycle-read.sh:539`, claude.exe ≈212107518

---

## Claim 22: "It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is empty, when a ~/ name appears and the home is not absolute, or when the candidates and comment splices run past a work bound or print past IMPORT_LEFT"

**Location:** `scripts/lib/dev-cycle-read.sh:526-529`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every non-zero path out of import_targets (`:611-633`, read whole, plus awk's `exit 2/3/4`). It does not establish behaviour when `printf` itself fails, which can only add a non-zero status.
**Legibility-target:** for-orchestrator-synthesis

The failure arms are:
- `import_home || return 1` (`:613`).
- `toks="$(env LC_ALL=C sed "${s[@]}")" || return 1` (`:617`).
- `d="$(… python3 …)" || return 1` (`:623`).
- `awk "$IMPORT_AWK" || return 1` (`:632`), which covers `if (root == "") exit 2` (`:590`), `exit 4` for a non-absolute home (`:544`), and `exit 3` for the work bound (`:536,580`) and IMPORT_LEFT (`:563`).

No arm returns 0 on failure. A failing gate awk falls through to python3 (Claim 26), and that is decoding, not a silent pass. Executed (each test passes at HEAD): the sed shim (`imps` with a failing sed), the python3 shim, `ROOT_REAL=""` → `rc=1`, `HOME=rel` → `tilde=1`, the IMPORT_LEFT test `12=1`, and the comments test (non-zero, not 124). An unset ROOT_REAL under `set -u` also gives `rc=1` (`unset.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:526-529,536,544,563,580,590,611-633`, `/tmp/u2a3bfcfin-Q1w0-tmp/suite.log`, `/tmp/u2a3bfcfin-Q1w0-tmp/unset.log` (09:25:27Z)

---

## Claim 23: emit: "Claude Code trims the name; it rejects a name led by a space first, so trimming one only over-reads." and "~/ joins the home directory (Claude Code: path.join(os.homedir(), rest)), also spelled through its real path, since ROOT_REAL is real."

**Location:** `scripts/lib/dev-cycle-read.sh:537-543`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the binary's trim and filter order and the `~/` join. It does not establish whether Claude Code imports the real-path spelling (its `AD(Pe)` check reads the spelled path, and `Pd` was not identified), so the real form may be an over-read.
**Legibility-target:** for-orchestrator-synthesis

`reo` applies its filter to `H`, and only then calls `Ye(H,FT(n))`, which does `let n=e.trim()` and `if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))` (offsets ≈212107518, ≈205304326). The prior report identified `b` and `c` as path's `join` and os's `homedir` from the import list. emit: `if (homer != home) put(homer "/" substr(c, 3))` (`:545`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:537-547`, claude.exe ≈205304326, ≈212107518

---

## Claim 24: "printed counts as the walks count: each name, a newline between names."

**Location:** `scripts/lib/dev-cycle-read.sh:562-563`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte equality under LC_ALL=C. Under a UTF-8 caller locale, `${#out}` counts characters (≤ bytes), as Claim 16 says.
**Legibility-target:** for-orchestrator-synthesis

awk adds `length(out) + 1` per name and tests `printed - 1 > left`. That total is Σlen + (n−1), which is `${#out}` after `$(...)` strips the final newline. The tests show it at the boundary: `see @a.md` with `IMPORT_LEFT` 12 gives 1 and with 13 gives 0, and two files pass at an exact `IMPORT_OUT_MAX=26` (both pass in `suite.log`). Removing the stop fails only test 42 (`mutants.log`: `no_left_stop`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:562-563,669-671`, `test/scripts/build-loop-check.bats:600-607,655-660`, `/tmp/u2a3bfcfin-Q1w0-tmp/mutants.log`

---

## Claim 25: UTF8_OK: "Well-formed UTF-8 (RFC 3629 …), as an awk ERE for a C-locale awk -v: it agreed with python3's decoding on 20,013 cases (U2a3b L2-i2 performance F1). Only text it rejects forks python3, since well-formed text decodes to itself."

**Location:** `scripts/lib/dev-cycle-read.sh:593-597`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk (the only awk installed) and python3's `replace` decoding over 30,017 lines, plus the fork condition. It does not establish gawk or busybox awk, which are not installed.
**Legibility-target:** for-orchestrator-synthesis

The figure is the critic's: "It agrees with python3's `replace` decode on all 20,013 cases" (`docs/reviews/performance-reviewer-review-2026-10-07-L2i2-build-loop-u2a3b.md:66`). I re-ran the committed `UTF8_OK` under `env LC_ALL=C mawk -v ok=…` against `l.decode("utf-8","replace").encode()==l` over 30,017 lines: 17 edge cases (surrogates, F4 90, overlongs, F5/F8 leads, BOM, U+FFFE) plus 30,000 random ones. The results were identical, 1,241 well-formed and 28,776 not (`utf8chk.log`). Fork condition: with valid `é`, python3 ran 0 times; with the gate awk forced to exit 2, python3 ran once and the output was still right (`gate.log`). So a failing gate fails toward decoding. Removing the fork (`gate_never_forks`) fails tests 31, 33 and 100 (`mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:593-597,622-625`, `/tmp/u2a3bfcfin-Q1w0-tmp/utf8chk.log`, `/tmp/u2a3bfcfin-Q1w0-tmp/gate.log` (09:15:30Z), `/tmp/u2a3bfcfin-Q1w0-tmp/mutants.log`

---

## Claim 26: import_targets: "Claude Code decodes the file as UTF-8 and turns each invalid sequence into U+FFFD … (python3's "replace" decoding matched Claude Code's byte for byte: U2a3b L2 security F1)."

**Location:** `scripts/lib/dev-cycle-read.sh:618-621`
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the binary calls (`Buffer.from(…).toString("utf8")` in `teo`, offset ≈212105900). It does not establish Bun's decoder, which could not be run.
**Legibility-target:** for-orchestrator-synthesis

The call is Node-API UTF-8 decoding, and the L2-i2 fact-check matched python3 against Node v22 on 20,000 strings. Claude Code runs on Bun, and `BUN_BE_BUN=1 claude.exe -e …` prints `error: unknown option '-e'` (this session). So "matched Claude Code's" is established only for Node, as the L2-i2 report's Claim 15 recorded (Mostly accurate there). The blocker is that Bun cannot run in this sandbox. A Bun runtime of the matching version, run over the same corpus, would settle it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:618-621`, claude.exe ≈212105900, `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i2.md:267`

---

## Claim 27a: import_home: "from HOME as Node's os.homedir reads it (unset …: the passwd entry). A walk calls it once, so the parser's $(...) calls inherit it; it recomputes only when HOME changes. A relative … home is kept, and the parser fails on a ~/ name then."

**Location:** `scripts/lib/dev-cycle-read.sh:598-609`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unset HOME, the cache key and a relative home. It does not establish the empty-HOME half (Claim 27b).
**Legibility-target:** for-orchestrator-synthesis

Node v22.23.2: `env -u HOME node -e …homedir()` prints `[/home/node]`, the passwd entry `node:x:1000:1000::/home/node:/bin/bash` (`homedir.log`). The code: `h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}" || h=""`, `[[ "$IMPORT_HOME_KEY" != "x$h" ]] || return 0`, `IMPORT_HOME="$h"; IMPORT_HOMER="${hr:-$h}"; IMPORT_HOME_KEY="x$h"` (`:606-609`). Both walks call `import_home || return 1` before their loop (`:662,719`), and import_targets calls it again (`:613`), which hits the inherited key. Recompute is keyed on the resolved home, which differs from "HOME changes" only when HOME goes from unset to empty. Node with `HOME=rel` returns `rel`, and the parser test gives `tilde=1` (passes); removing `exit 4` fails test 41 (`mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:598-613,662,719`, `/tmp/u2a3bfcfin-Q1w0-tmp/homedir.log` (09:13:58Z), `/tmp/u2a3bfcfin-Q1w0-tmp/mutants.log`

---

## Claim 27b: import_home: "from HOME as Node's os.homedir reads it (… empty: the passwd entry)"

**Location:** `scripts/lib/dev-cycle-read.sh:599-600,606`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Node v22's `os.homedir()` with `HOME=""`. It does not establish Bun's behaviour (not runnable) or how Claude Code then resolves a `~/` name against an empty home (`path.join("", rest)` is relative, and `Pd` was not identified).
**Legibility-target:** for-author

`HOME= node -e 'console.log(require("os").homedir())'` prints `[]`, an empty string, not the passwd entry (`homedir.log`). libuv reads HOME whenever it is set, even when it is empty. The code reads `${HOME:-…}`, so an empty HOME takes the passwd entry (`HOME empty -> IMPORT_HOME=[/home/node]`, `unset.log`). Node's `path.join("", "docs/a.md")` is `docs/a.md` (`unset.log`). If Claude Code's Bun runtime behaves like Node here, an `@~/docs/a.md` in a session with `HOME=""` names a path relative to the session, and the walk resolves it under `/home/node` instead. The superset statement's first exception ("a session whose home differs from this process's") arguably covers that session, because this process's home is import_home's value. But the comment's claim about Node is wrong. Precise version: "(unset: the passwd entry; Node keeps an empty HOME, which this reads as unset)", or `${HOME-…}` together with a fail-closed rule for an empty home on a ~/ name. Changing `${HOME:-` to `${HOME-` fails no test in build-loop-check.bats or dev-cycle.bats (`mutants.log`: `empty_home_kept`), so no test pins either reading.

**Evidence:** `scripts/lib/dev-cycle-read.sh:599-600,606`, `/tmp/u2a3bfcfin-Q1w0-tmp/homedir.log` (09:13:58Z), `/tmp/u2a3bfcfin-Q1w0-tmp/unset.log` (09:25:27Z), `/tmp/u2a3bfcfin-Q1w0-tmp/mutants.log`

---

## Claim 28: instruction_names: "It returns 0 when no name matches and 1 when grep fails (grep's own no-match is 1)."; tree_starts: "failing when any of the three commands fails."

**Location:** `scripts/lib/dev-cycle-read.sh:637-647`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both one-line functions. It does not establish behaviour under a non-GNU grep.
**Legibility-target:** for-orchestrator-synthesis

`grep -zaiE … || [[ $? -eq 1 ]]` (`:639`) maps grep's 2 to 1 and its 1 to 0. tree_starts is `{ git ls-files -z && untracked_md; } | instruction_names` under `set -o pipefail` (`:647`). The grep-shim, tracked-listing-only git-shim and corrupt-index tests pass (`suite.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:637-647`, `test/scripts/build-loop-check.bats:417-420,477`

---

## Claim 29: imported_names: "Claude Code skips a file over 4 MiB, so reading only its start over-reads at worst, and a huge file a prefix candidate names cannot stall the walk (L2 security F2)."

**Location:** `scripts/lib/dev-cycle-read.sh:667-669`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk. The main walk still reads blobs whole (routed to U2a3c, override row).
**Legibility-target:** for-orchestrator-synthesis

Claude Code: `if(s.totalBytes>nH)return{kind:"skipped",…}` with `nH` = 4194304 (offset ≈212105900, per the L2-i2 report's quoted `nH=4194304`). The code is `head -c 4194305` (`:669`). The sparse 300 MB test (20 s timeout) and the exact-4 MiB test both pass (`suite.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:667-669`, `test/scripts/build-loop-check.bats:564-571,609-616`, claude.exe ≈212105900

---

## Claim 30: main_imports: "A .git component itself (a prefix candidate from @.gitignore, or a nested repository's) is a checkout file or directory git never stores. Files under it are not skipped: they fail below, since main lacks them."

**Location:** `scripts/lib/dev-cycle-read.sh:756-759`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip and what follows for a path under `.git`. It does not establish U2a3c's general prefix-meets-checkout-file rule (routed).
**Legibility-target:** for-author

The skip is exactly a bare component: `[[ "$p" != .git && "$p" != */.git ]] || continue` (`:759`). Below it, a path main lacks fails only when the checkout holds it as something other than a plain directory: `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }` (`:763`). "They fail below" therefore holds for files that exist under `.git`. An absent name under `.git` (`@.git/absent.md`) and a plain directory (`@.git/info`) are recorded and pass. In a fixture with both, the main walk printed `walk ok` and recorded 13 `.git/` lines (`a3.log`). This is safe, because a file that does not exist has no imports to hide. Precise version: "Files under it are not skipped: one the checkout holds fails below, since main lacks it." Widening the skip to `.git/*` fails test 39 (`mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:756-763`, `/tmp/u2a3bfcfin-Q1w0-tmp/a3.log` (09:23:08Z), `/tmp/u2a3bfcfin-Q1w0-tmp/mutants.log`

---

## Claim 31: main_imports: "pok holds parents already checked: a token's prefixes share them, so the loop stops at the first."

**Location:** `scripts/lib/dev-cycle-read.sh:761-762`
**Type:** Invariant / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers correctness of the early stop and its timing. The memo mutant is time-only (override row).
**Legibility-target:** for-orchestrator-synthesis

`c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ -z "${pok[$c]+set}" ]] || break; pok[$c]=1; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }; done` (`:762`). A parent enters `pok` only on a pass that goes on to check it, and that pass then continues to its own parent, unless a failing check returns. So every ancestor of a memoized parent has been checked, and stopping is safe. Timing in my runs (`deep.log`): a 2,820-byte `a/` token takes 14.23 s at 98e3b1df and 1.01 s at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:761-762`, `/tmp/u2a3bfcfin-Q1w0-tmp/deep.log`

---

## Claim 32: main_imports: "One lower per file, not per candidate, as in imported_names." (and that IMPORTED_MAIN is unchanged by the hoist)

**Location:** `scripts/lib/dev-cycle-read.sh:749-750`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the string IMPORTED_MAIN builds. It does not establish timing.
**Legibility-target:** for-orchestrator-synthesis

Before (main): `IMPORTED_MAIN+="$(lower "$p")"$'\n'` for every non-empty `p` of `out`, read before the `seen` test. Now: `i="$(lower "$out")" || …; IMPORTED_MAIN+="$i"$'\n'` (`:750`), after `[[ -n "$out" ]] || continue` (`:746`). awk never prints an empty line (`length(out) <= length(pre)` returns, `:559`), and the symlink arm's `out` is one non-empty path, so both forms give the same lines in the same order: Σ(p\n) equals out + "\n". The per-file lower guard is exercised by the trfail test (passes).

**Evidence:** `scripts/lib/dev-cycle-read.sh:745-751,559`, `test/scripts/build-loop-check.bats:463-467`

---

## Claim 33: isimported: "A failed walk, a failed lower of $2, or a walk name that is neither answers imported (0) … a caller that words a failed walk runs the walk first (imported_names or main_imports, under if)."

**Location:** `scripts/lib/dev-cycle-read.sh:768-780`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers isimported's four arms and check_fix's order.
**Legibility-target:** for-orchestrator-synthesis

`lp="$(lower "$2")" || return 0`, `main) main_imports || return 0;`, `tree) imported_names || return 0;`, `*) return 0 ;;` (`:774-778`). check_fix runs `elif ! imported_names` before `elif isimported tree` (`scripts/dev-cycle.sh:181-183`). The bogus-name, trfail and corrupt-index tests pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:768-780`, `scripts/dev-cycle.sh:181-183`

---

## Claim 34: skills/dev-cycle/SKILL.md: "or a file an instruction file names after an `@`, read broadly; compared ignoring case) or `README.md`, and refuses every path when the import walk fails"

**Location:** `skills/dev-cycle/SKILL.md:72-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with check_fix (Claim 11).
**Legibility-target:** for-orchestrator-synthesis

It mirrors `scripts/dev-cycle.sh:50-55` and `:181-182`.

**Evidence:** `skills/dev-cycle/SKILL.md:72-76`, `scripts/dev-cycle.sh:50-55,181-182`

---

## Claim 35: build-loop-check.bats helper and token-test comments: "imps …: "walk: ok" or "walk: failed" (main_imports' or imported_names' return)"; "Two NBSPs in one run: the token ends at the first. docs/z.md is imported only after the NUL; gone/ does not exist, and the path is still resolved as written."; "Docs/NB.MD and CLAUDE.md: isimported takes a path in any case."; "Without ROOT_REAL it stops (need_root) for any walk name, before answering."; the 19 code points; "An untracked start: the tree walk reads it (the main walk fails closed on it until U2a3c)."

**Location:** `test/scripts/build-loop-check.bats:13-20,28-36,47-50,53-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each comment against its test's assertions and the code.
**Legibility-target:** for-orchestrator-synthesis

`imps` prints `walk: ok` when `{ [[ "$w" == main ]] && main_imports; } || { [[ "$w" == tree ]] && imported_names; }` (`:19`). Each assertion passes (`suite.log`).

**Evidence:** `test/scripts/build-loop-check.bats:13-68`, `/tmp/u2a3bfcfin-Q1w0-tmp/suite.log`

---

## Claim 36: superset test title: "… ~x is over-read, ~/ dropped; …"

**Location:** `test/scripts/build-loop-check.bats:339`
**Type:** Staleness / Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "~/ dropped" phrase. "~x is over-read" is right: `~g.md` fails `reo`'s `^[a-zA-Z0-9._-]` branch.
**Legibility-target:** for-author

Since e1654266, a `~/` name is joined to the home directory, not dropped: `c = home "/" substr(c, 3)` (`scripts/lib/dev-cycle-read.sh:546`). The test's `want '~/x.md' -` (`:361`) passes because the fixture's HOME is `"$BATS_TEST_TMPDIR/home"` (`test/lib/build-loop-fixtures.bash:19`), so `@~/x.md` resolves outside the repo and is kept out. The title describes the pre-e1654266 rule. Precise version: "~/ read against HOME (outside the repo here)".

**Evidence:** `test/scripts/build-loop-check.bats:339,345,361`, `scripts/lib/dev-cycle-read.sh:542-546`, `test/lib/build-loop-fixtures.bash:19`

---

## Claim 37: superset test comments: "an escaped space and an absolute path inside the repo are imports"; "A link or code span between two @s does not hide the second (Claude Code reads both)."; over-read test: "Claude Code 2.1.292 reads none of docs/mail.md, docs/pre.md and docs/lead.md (its path filter rejects a name led by a space; …)"

**Location:** `test/scripts/build-loop-check.bats:341-349,366-371`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers `reo`'s regex, filter and token walk, read from the binary. It does not run marked's lexer on these exact lines (done by the security fuzz reviews).
**Legibility-target:** for-orchestrator-synthesis

`reo` matches `(?:^|\s)@((?:[^\s\\]|\\ )+)`, so `\ ` stays in the name and `user@` (no `\s` before the `@`) never starts one. Each text token is scanned on its own (`if(S.type==="text")s(S.text||"")`), so a text token right after a link or a code span starts at `^` (offset ≈212107518). An absolute name passes the `H.startsWith("/")&&H!=="/"` branch.

**Evidence:** `test/scripts/build-loop-check.bats:341-371`, claude.exe ≈212107518

---

## Claim 38: heavy-input comment: "Seven 4200-byte runs after an @ pass the candidate-work bound (each prefix's length is charged; the sixth run trips it): the parser returns 1." (test title: "… the work bound fails the walk")

**Location:** `test/scripts/build-loop-check.bats:365,383-388`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which bound stops the parser on this input at e1654266, and whether any test still pins emit's work bound. It does not establish the work bound's value as a design.
**Legibility-target:** for-author

The arithmetic would hold on its own: each run charges Σk = 8,822,100, so the 50,000,000 bound trips in run 6. Since e1654266, though, the parser stops at the printed budget first. The test sets no IMPORT_LEFT, so `IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}"` is 4,000,000 (`scripts/lib/dev-cycle-read.sh:632`). The prefixes of run 1 print Σ(k+1) and pass 4,000,000 at name length 2,827. Executed (`heavy.log`): by default the parser returns `rc=1` after printing 2,826 lines (the longest 2,826 bytes). With `IMPORT_LEFT=1e12` it prints all 4,200 names of run 1 and then fails on the work bound. Dropping `work += length(c); if (work > 50000000) exit 3` from emit leaves build-loop-check.bats and dev-cycle.bats at 120/120 (`mut-emitwork.log`). So no test pins emit's work bound any more. The comments test pins only splice's charge to it. The comment, and the title's "the work bound fails the walk", describe 98e3b1df. Fix: set `IMPORT_LEFT` high in that run, or reword the comment to the printed budget and add a work-bound case that sets `IMPORT_LEFT`.

**Evidence:** `test/scripts/build-loop-check.bats:383-388`, `scripts/lib/dev-cycle-read.sh:536,563,632`, `/tmp/u2a3bfcfin-Q1w0-tmp/heavy.log` (09:17:37Z, rc 1 each run), `/tmp/u2a3bfcfin-Q1w0-tmp/mut-emitwork.log` (command: `TMPDIR=… timeout 900 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats` in `/tmp/u2a3bfcfin-Q1w0-tmp/mut`, 120 ok, 0 not ok)

---

## Claim 39: "The four superset holes the L2 fact-check executed … Each FAILS at be94c871 and passes once its hole is closed"; dev-cycle.bats "--check-fix refuses a doc imported through the repo's parent directory, as main did (FAILS at be94c871 …)"

**Location:** `test/scripts/build-loop-check.bats:480-526`; `test/scripts/dev-cycle.bats:1058-1063`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers be94c871's lib and scripts with e1654266's tests.
**Legibility-target:** for-orchestrator-synthesis

`bats -f 'FAILS at be94c871'` over `old-be94c871` (be94c871 code, e1654266 tests) fails all six: four hole tests, the comments test, and the dev-cycle test. The dev-cycle test prints `ok docs/notes.md`, so it fails on the import, not on wording (`fails-be94.log`). All six pass at HEAD.

**Evidence:** `/tmp/u2a3bfcfin-Q1w0-tmp/fails-be94.log` (cwd `/tmp/u2a3bfcfin-Q1w0-tmp/old-be94c871`, about 09:10Z, exit 1 as expected)

---

## Claim 40: comments test: "(FAILS at be94c871: L2 fact-check Claim 18b; about 10 s)"; "320,000 comments in one 2.24 MB line took 27 s with status 0 at be94c871"

**Location:** `test/scripts/build-loop-check.bats:545-551`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers runtimes at be94c871 and HEAD on this machine.
**Legibility-target:** for-author

Executed (`comments.log`): be94c871 takes 28.55 s with `rc=0`, so "27 s with status 0" holds. HEAD takes 0.2 s with `rc=1`. The title's "about 10 s" is the test's own `timeout 10`, which only be94c871 reaches (it fails there with `rc=124`, `fails-be94.log`). It is not the parser's runtime at HEAD. This was carried from L2-i2 Claim 30 with no disposition.

**Evidence:** `test/scripts/build-loop-check.bats:545-551`, `/tmp/u2a3bfcfin-Q1w0-tmp/comments.log` (09:18:32Z)

---

## Claim 41: "import_targets prints 13 bytes for each file (a, a., a.m, a.md; 26 in all)."; "see @a.md prints a, a., a.m, a.md: 13 with the newlines between them."; "4194304 bytes in all, the last 14 an import with no newline after it."

**Location:** `test/scripts/build-loop-check.bats:601,612,656`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three figures.
**Legibility-target:** for-orchestrator-synthesis

1+2+3+4+3 = 13. `printf '\n@docs/late.md'` is 1+13 = 14 bytes, and the test asserts `wc -c` equals 4194304. All three tests pass.

**Evidence:** `test/scripts/build-loop-check.bats:600-616,655-660`, `/tmp/u2a3bfcfin-Q1w0-tmp/suite.log`

---

## Claim 42: "both walks read an @~/ import into a repo under HOME … (FAILS at 98e3b1df: L2-i2 fact-check Claim 9)"; the .git fail-closed test comment; the HOME-symlink and relative-home tests

**Location:** `test/scripts/build-loop-check.bats:618-653`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 98e3b1df's code with e1654266's tests, and the mutants of each fix.
**Legibility-target:** for-orchestrator-synthesis

At 98e3b1df the HOME, HOME-symlink and relative-home tests all fail (`fails-98.log`), and they pass at HEAD. The .git comment ("Only a bare .git component is skipped: .git/notes.md is a checkout file main lacks, so the walk fails rather than drop docs/t.md") matches `:759,763`. Each fix's mutant fails its test: `no_homer` fails 40, `no_rel_home_fail` fails 41, and `git_skip_wide` fails 39 (`mutants.log`).

**Evidence:** `/tmp/u2a3bfcfin-Q1w0-tmp/fails-98.log`, `/tmp/u2a3bfcfin-Q1w0-tmp/mutants.log`

---

## Claim 43: dev-cycle.bats: "Mail user@docs/email.md is no import for Claude Code, but the superset reads it."; the U+FFFD --check-fix test; the failed-walk wording test

**Location:** `test/scripts/dev-cycle.bats:1048-1080`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three tests' claims against `reo` and check_fix.
**Legibility-target:** for-orchestrator-synthesis

`user@` has no `^|\s` before its `@` (Claim 37). All three tests pass, and the U+FFFD test fails under `gate_never_forks` (test 100, `mutants.log`).

**Evidence:** `test/scripts/dev-cycle.bats:1048-1080`, `/tmp/u2a3bfcfin-Q1w0-tmp/mutants.log`

---

## Claim 44: commit messages: test counts "121/121" (be94c871), "130/130" (dd51e9a7), "133/133" (98e3b1df), "143/143" (e1654266); changed code lines "350" / "486" / "525" / "679"

**Location:** commits be94c871, dd51e9a7, 98e3b1df, e1654266
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five suites' `bats --count` at each commit, and numstat outside `docs/` against `main...<commit>` (merge base f6fdda68).
**Legibility-target:** for-orchestrator-synthesis

`bats --count` over the five suites gives 121, 130, 133 and 143. `git diff --numstat main...<c> -- . ':!docs'` (added + deleted) gives 350, 486, 525 and 679. The full run at e1654266 is 143/143.

**Evidence:** command output in this session (cwd `/tmp/u2a3bfcfin-Q1w0-tmp/cnt` per commit; `/workspace/.claude/wt-build-loop-u2a3b` for numstat), `/tmp/u2a3bfcfin-Q1w0-tmp/suite.log`

---

## Claim 45: commit e1654266 measurements: "python3 forks only when an awk ERE … rejects the text (42 of 45 walked files forked before, none changed)"; "a long a/ run fails in 1.0 s (10.1 s before)"; "a 2,820-byte deep token takes 1.0 s (16.6 s)"; "--check-fix over 942 paths identical to main; interleaved, main 2.39-2.76 s, this branch 2.63-2.77 s"

**Location:** commit e1654266
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each figure re-run on this machine today. Timings vary with load.
**Legibility-target:** for-author

- python3 forks in the clone's main walk: 42 at 98e3b1df and 0 at HEAD (`pycount.log`). This holds.
- A 9,990-byte `a/` run fails in 1.04 s (tree) and 1.06 s (main) at HEAD, against 8.16 s and 8.10 s at 98e3b1df (`deep.log`). The direction holds; "10.1 s before" was 8.1 s here.
- The 2,820-byte token: 1.01 s against 14.23 s.
- --check-fix is identical to main on all 948 paths now tracked; 942 was the count before this commit added its reports.
- Interleaved, three runs: main 2.43-2.59 s and this branch 2.78-2.82 s (`timing.log`), slightly above the stated 2.63-2.77.

These are commit messages, so Accepted-immutable applies, as for the override row at `docs/reviews/override-log.md:429`.

**Evidence:** `/tmp/u2a3bfcfin-Q1w0-tmp/{pycount,deep,timing}.log`

---

## Claim 46: commit e1654266: "Mutants: each fix's mutant fails a test except the parent memo and the LC_ALL=C guard (time only and equivalent here; override rows)."

**Location:** commit e1654266
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the mutants I built for e1654266's fixes: the gate, the IMPORT_LEFT stop, homer, the .git skip, the relative-home exit and the parent memo. It does not cover the empty-HOME reading (Claim 27b), which is not a fix the commit names, or the LC_ALL=C guard.
**Legibility-target:** for-orchestrator-synthesis

From `mutants.log`, over build-loop-check.bats and dev-cycle.bats: `gate_never_forks` fails tests 31, 33 and 100. `no_left_stop` fails 42, `no_homer` fails 40, `git_skip_wide` fails 39 and `no_rel_home_fail` fails 41. `no_parent_memo` fails none (time only, as stated). `empty_home_kept` also fails none.

**Evidence:** `/tmp/u2a3bfcfin-Q1w0-tmp/mutants.log` (mutant copies `/tmp/u2a3bfcfin-m-*`, 09:24Z-09:29Z)

---

## Claim 47: commits dd51e9a7 / 98e3b1df: "3.4 s against main's 4.0 s", "941 tracked docs"

**Location:** commits dd51e9a7, 98e3b1df
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers only the existing disposition. I did not re-time dd51e9a7.
**Legibility-target:** for-orchestrator-synthesis

These are already recorded as Incorrect / Mostly accurate and Accepted-immutable (`docs/reviews/override-log.md:429`: "Commit dd51e9a7's "3.4 s against main's 4.0 s" does not reproduce …"). No new evidence, so they are not re-raised. Path counts by tree: dd51e9a7 has 941 and 98e3b1df has 942 (`git ls-tree`, this session).

**Evidence:** `docs/reviews/override-log.md:429`

---

## Claims Requiring Attention

### Incorrect
- **Claim 27b** (`scripts/lib/dev-cycle-read.sh:599-600,606`): Node's `os.homedir()` returns `""` for an empty HOME, not the passwd entry. `${HOME:-…}` reads empty as unset. Fix the parenthetical, or use `${HOME-…}` with an empty home failing on a ~/ name. No test pins either reading (its mutant survives).

### Stale
- **Claim 1** (`docs/working/known-issues-dev-cycle.md:17`): A3 still says absolute-path imports into the repo print `ok`, but `--check-fix` now refuses them (executed).
- **Claim 7** (`docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:477-478`): "three shapes untraced": A5 now lists one (`.claude/commands/`).
- **Claim 36** (`test/scripts/build-loop-check.bats:339`): the superset test title says "~/ dropped"; ~/ is now joined to HOME.
- **Claim 38** (`test/scripts/build-loop-check.bats:383-388`): the heavy-input test now trips IMPORT_LEFT at name length 2,827 in run 1, not the work bound in run 6. emit's work-bound mutant survives both suites, so no test pins it.

### Mostly Accurate
- **Claim 4** (A5): the oracle was transcribed (regex) and extracted (lexer), and U2a2's was a differential harness (carried from L2-i2 Claim 2).
- **Claim 12** (`:12-13`): python3 is needed for any file the walk reads, not only instruction files.
- **Claim 14** (`:453-458`): imported_names' failure list omits `import_home` and the IMPORT_OUT_MAX budget.
- **Claim 15** (`:680-691`): main_imports' failure list omits the parser, the budget, `import_home` and the per-file lower.
- **Claim 30** (`:756-759`): only files the checkout holds under `.git` fail; absent names and plain directories are recorded.
- **Claim 40** (`build-loop-check.bats:545`): "about 10 s" is be94c871's timeout, while HEAD takes 0.2 s.
- **Claim 45** (e1654266): timings re-run at 8.1 s / 14.2 s "before" and branch 2.78-2.82 s (immutable).

### Unverifiable
- **Claim 26** (`:618-621`): python3 matched Node's UTF-8 decoder; Bun's could not be run.
- **Claim 47** (dd51e9a7/98e3b1df): already Accepted-immutable (override-log line 429); not re-timed.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: e1654266` line at the top.
- **Answered:**
  - Item 1: rules match IMPORT_AWK (Claim 19). The five exceptions are real, and I found no shape Claude Code 2.1.292 imports outside them (Claim 20, residues Bun and `Pd`). "It returns 1 when ..." lists every arm, and none returns 0 (Claim 22).
  - Item 2: Claim 25 (re-run on 30,017 cases, fork and fail-toward-decoding executed).
  - Item 3: Claims 27a/27b (empty HOME is wrong for Node).
  - Item 4: Claims 16 and 24.
  - Item 5: Claims 29-32.
  - Item 6: Claims 7, 11-15, 34, 2-10.
  - Item 7: Claims 35-43.
  - Item 8: Claims 44-47.
  - Suites: 143/143 (exit 0).
  - Fix-holds check on the L2-i2 rubric: A1, A2, C1-C6, C8 and C9 hold. C7 holds for the statement, but the lib's main_imports header and F11 still say "three shapes" (Claim 7). C9's test changes left the heavy-input comment stale (Claim 38).
- **Out of scope:** whether emit's work bound is still needed now that IMPORT_LEFT bounds the same input (a performance/design question); routed rows (reader root set to U2b; the main walk's capped blob read and the phase-2 rules to U2a3c), not re-raised.
- **Escalate:** none blocking. Each finding is for-author wording or test labelling. The only behavioural item is Claim 27b (empty HOME). Its effect is a session with `HOME=""`, which the superset's first exception arguably covers.
- **Questions I would have asked:** whether an empty HOME should fail closed on a `~/` name, as a relative one does, rather than take the passwd entry.
- **Decisions I made:**
  - I used the installed claude.exe strings as the oracle and Node v22 in place of Bun.
  - I kept execution logs in `/tmp/u2a3bfcfin-Q1w0-tmp/` rather than `docs/reviews/execution-logs/`, per the brief's no-other-files rule.
  - I counted the heavy-input finding as Stale (true at 98e3b1df) rather than Incorrect.
  - No hallucination-pattern entry: the one Incorrect verdict is a wrong runtime reading, not a fabricated symbol.
