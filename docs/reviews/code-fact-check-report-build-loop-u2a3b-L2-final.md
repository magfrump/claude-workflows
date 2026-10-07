Commit: e1654266

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b)
**Scope:** `git diff main...e1654266 -- . ':!docs/reviews'` (scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md) and the commit messages `main..e1654266` (be94c871, dd51e9a7, 98e3b1df, e1654266). U2a3b loop 2, final confirming pass: merged canonical report of replicates r1, r2 and r3.
**Checked:** 2026-10-07
**Total claims checked:** 73
**Summary:** 45 verified, 15 mostly accurate, 6 stale, 4 incorrect, 3 unverifiable
**Commit:** e1654266
**Replication:** k=3

Merge provenance. This report collates `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r1.md` (47 claims), `-r2.md` (48 claims) and `-r3.md` (50 claims), all at `Commit: e1654266`, per `skills/code-review/SKILL.md` "Merging replicate verdicts (most-severe-wins)". Nothing here is new evidence: each claim carries the winning replicate's evidence, and every other replicate's caveats sit in `**Replicate annotations:**`. Where one replicate split a sentence and another verdicted it as a whole, the merged report emits the finer rows, and the compound verdict is recorded on each row marked `(compound)`. All three replicates ran the five suites at e1654266: **143/143 ok**, exit 0 (r1 `/tmp/u2a3bfcfin-10T4/logs/suites.txt`; r2 `/tmp/u2a3bfcfin-Q1w0-tmp/suite.log`; r3 `/tmp/claude-1000/-workspace/d85c9919-8193-4546-8b61-a9f00fc88d03/scratchpad/u2a3bfcfin-logs/suites-e1654266.txt`). Log paths inside claims are the reporting replicate's own. r3's bare `logs/...` paths resolve under `/tmp/claude-1000/-workspace/d85c9919-8193-4546-8b61-a9f00fc88d03/scratchpad/u2a3bfcfin-logs/`.

## Claims Requiring Attention

### Incorrect
- **Claim 34** (`scripts/lib/dev-cycle-read.sh:599-600`): "as Node's os.homedir reads it" is wrong. Node v22 returns `""` for an empty HOME. The passwd fallback is Bun's (Claude Code's runtime), and r1 and r3 showed by execution that the code matches it. No test pins either reading (r2). All three replicates agree.
- **Claim 70** (commit e1654266): "each fix's mutant fails a test except the parent memo and the LC_ALL=C guard". The nested `*/.git` arm's mutant survives and is not equivalent (r1, executed). r3 adds that the gate-removal mutant also survives (time only). r2 had Verified.
- **Claim 71** (commit 98e3b1df): Claude Code rejects a name led by an escaped space before it trims, so the trim does not make it an import (r1 only; immutable message).
- **Claim 73** (commit e1654266): the same Node attribution as Claim 34, in an immutable commit message (r1 compound, r3).

### Stale
- **Claim 1** (`docs/working/known-issues-dev-cycle.md:17`): A3 still says absolute-path imports into the repo print `ok`, but `--check-fix` now refuses them (r1, r2).
- **Claim 8** (`docs/working/known-issues-dev-cycle.md:19`): C2's per-token forks describe the replaced parser (r1 only).
- **Claim 9** (`docs/working/plan-build-loop-handoff.md:126`): F11 says three shapes are untraced, but A5 now lists one (all three).
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:477-478`): the lib has the same "three shapes" drift (all three).
- **Claim 50** (`test/scripts/build-loop-check.bats:339`): the superset test title says "~/ dropped", but ~/ is now joined to HOME (r2 only).
- **Claim 52** (`test/scripts/build-loop-check.bats:383-388`): the heavy-run test trips the print budget after 2,826 names, not the work bound in the sixth run. emit's work bound is now untested (r1, r2 Stale; r3 Verified on the arithmetic).

### Mostly Accurate
- **Claim 4** (`docs/working/known-issues-dev-cycle.md:18`): A5's oracle was transcribed (regex) and extracted (lexer), and U2a2's was a differential harness, not a fuzzer (r2 only).
- **Claim 7** (`docs/working/known-issues-dev-cycle.md:18`): A5's "Not covered" list omits instruction files outside the repo (an ancestor directory's CLAUDE.md, user memory) whose imports Claude Code follows into it. This is executed and severity Medium (r1 only, escalated).
- **Claim 12** (`docs/working/plan-build-loop-handoff.md:279`): the "another checkout" case also covers a relative name re-entering through that checkout's directory name (r3, executed).
- **Claim 14** (`scripts/lib/dev-cycle-read.sh:12-13`): python3 is needed for any file the walk reads, not only instruction files (r2).
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:452-453`): this verdict comes from r2's compound verdict, which rested on the failure-list half (Claim 18). r2's text says this parenthetical is "right in effect", and r3 verified it.
- **Claim 18** (`scripts/lib/dev-cycle-read.sh:453-458`): imported_names' failure list omits import_home and the IMPORT_OUT_MAX budget arm (all three).
- **Claim 25** (`scripts/lib/dev-cycle-read.sh:516-523`): the "another checkout" exception's parenthetical is too narrow, because relative re-entry is missed too (r3, executed).
- **Claim 35** (`scripts/lib/dev-cycle-read.sh:600-601`): import_home is keyed on the computed home and called per file, and with HOME unset or empty getent runs on every call (r3; r1 and r2 note the same in their scope and evidence).
- **Claim 42** (`scripts/lib/dev-cycle-read.sh:680-691`): main_imports' failure list omits the parser, import_home, the budget and the per-file lower (all three).
- **Claim 44** (`scripts/lib/dev-cycle-read.sh:756-759`): paths under `.git` fail only when the checkout holds them, while absent names and plain directories are recorded (all three).
- **Claim 49** (`test/scripts/build-loop-check.bats:26`, `:53`): the Unicode-space tests cannot detect whether a space ends a token, and the mutant survives (r1).
- **Claim 55** (`test/scripts/build-loop-check.bats:545`): "about 10 s" is be94c871's timeout, while HEAD takes about 0.2-0.5 s (r2, r3).
- **Claim 65** (commit e1654266): the `--check-fix` timings re-ran slightly above the stated range (r2), and /workspace's run is well above it (r3).
- **Claim 66** (commit e1654266): "42 of 45 forked before". This verdict comes from r2's compound, whose text says this item "holds" (r1 Verified, r3 Unverifiable).
- **Claim 67** (commit e1654266): the "before" timings re-ran at 8.1 s / 12.6-14.2 s, not 10.1 s / 16.6 s (r2; r1 Verified with a time-varying note).

### Unverifiable
- **Claim 37** (`scripts/lib/dev-cycle-read.sh:618-621`): "matched Claude Code's byte for byte". r2 could not run Bun. r1 (8 sequences) and r3 (5 sequences) matched the real binary on the sequences they probed.
- **Claim 68** (commit dd51e9a7): "3.4 s against main's 4.0 s" was not re-timed and is already Accepted-immutable (override-log:429).
- **Claim 69** (commits dd51e9a7, 98e3b1df): "identical to main" over 941 docs was not re-run at those commits.

---

## Claim 1: A3: "Imports through a symlinked file or directory, and absolute-path imports into the repo, print `ok`."

**Location:** `docs/working/known-issues-dev-cycle.md:17`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absolute-path half of A3 for `--check-fix`'s tree walk at e1654266; does not establish the symlinked-file and symlinked-directory halves (not re-tested).
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=—
**Replicate annotations:** r2: "does not establish the symlinked-file and symlinked-directory halves, which this unit did not change" · r2: executed fixture: main's `--check-fix docs/x.md` prints `ok`, e1654266 prints `skip ... names it after an @` (`/tmp/u2a3bfcfin-Q1w0-tmp/a3.log`)

The branch made the tree walk read absolute imports: `put` resolves a name that starts with `/` and keeps it when it lies below ROOT_REAL:

```awk
# scripts/lib/dev-cycle-read.sh:551, :559
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  if (index(out, pre) != 1 || length(out) <= length(pre)) return
```

The test `both walks read an absolute import into the repo however it is spelled` (`test/scripts/build-loop-check.bats:495`) runs `for w in tree main` and passes at e1654266, so `--check-fix` now refuses such a doc. The A3 row was not edited. In the same diff, A5 and the lib comment both dropped "absolute imports" from their gaps. A3 should drop its absolute-path clause.

**Evidence:** `docs/working/known-issues-dev-cycle.md:17`, `scripts/lib/dev-cycle-read.sh:550-565`, `test/scripts/build-loop-check.bats:495-504`, /tmp/u2a3bfcfin-10T4/logs/suites.txt, /tmp/u2a3bfcfin-Q1w0-tmp/a3.log

---

## Claim 2: A5: "Both walks share one token parser (`import_targets`) ... the claim, its rules and its exceptions are stated once, in the comment above `import_targets`"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one-parser call structure and the pointer to the statement. It does not establish that the statement is complete (Claims 23-26).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish that the superset holds"

The tree walk calls `out="$(head -c 4194305 -- "$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d")"` (`scripts/lib/dev-cycle-read.sh:669`). The main walk calls `git cat-file blob "$MAIN_SHA:$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d"` (r2 cites `:711`, r3 `:726`). The statement opens with `# The superset claim (the one statement of it; known issue A5 and plan F11` (`:501`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:501-533`, `:669`, `:726`

---

## Claim 3: A5: "Its cost is false positives (none among this repo's tracked docs on 2026-10-06)."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-fix over every tracked `docs/*.md` and README.md of a clone at e1654266 on 2026-10-07; does not establish the main walk's precision or other repos.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish the 2026-10-06 measurement itself" · r3: "does not establish the same for the future or for untracked docs" · r2+r3: also identical on /workspace (919 paths) and the worktree (948) · r3: also identical on a fresh clone's 1,524 `*.md` paths

`--check-fix` ran over 948 paths in a fresh clone at e1654266, once with main's scripts and once with e1654266's. The verdicts were identical, each run printed 14 `ok`, and no path was refused with "an instruction file names it" (skip reasons: 924 scope, 8 own files, 2 path form). Command: `bash /tmp/u2a3bfcfin-10T4/checkfix-compare.sh`, cwd the clone, exit 0, 2026-10-07T09:4x.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/checkfix-compare.txt, `scripts/dev-cycle.sh:181-184`, /tmp/u2a3bfcfin-Q1w0-tmp/timing.log, logs/checkfix-worktree.txt (r3), logs/checkfix-workspace.txt (r3)

---

## Claim 4: A5: "The oracle it was checked against was Claude Code 2.1.292's import regex and Markdown lexer, extracted from the installed package into a scratch fuzzer by the U2a2 and U2a3b security reviews; that harness is not kept"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the cited reviews say about how they built their harnesses. It does not re-run those harnesses.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
**Replicate annotations:** none

This is unchanged since the L2-i2 fact-check (its Claim 2, Mostly accurate). That check found the import regex was transcribed, not extracted; only the lexer bytes were extracted. It also found U2a2's harness was a 27-line differential harness, not a fuzzer (quoted there from `security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:13,123`). No harness is tracked (paraphrased; no quote available because the claim concerns absence: no fuzz or harness file for this unit is in `git ls-files`). The rubric records no disposition for that claim. Precise version: "transcribed (regex) and extracted (lexer) ... into a differential harness (U2a2) and a fuzzer (U2a3b)".

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i2.md:45`

---

## Claim 5: A5: "`test/agents-gemini-sync.bats` holds a separate, older finder for where an import starts (v2.1.284), not these rules."

**Location:** `docs/working/known-issues-dev-cycle.md:18`; `scripts/lib/dev-cycle-read.sh:530-532`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file's own version note and its grep. It does not check that finder's accuracy.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish what that finder does"

`# Claude Code v2.1.284 (its extractor, read from the binary during review)` (`test/agents-gemini-sync.bats:37`). Its finder is `grep -nE '(^|[^[:alnum:]])@(\./|~/|/|[[:alnum:]._-])'` (`:51`), which is not IMPORT_AWK.

**Evidence:** `test/agents-gemini-sync.bats:37-51`

---

## Claim 6: A5: "Traced in Claude Code 2.1.292 ...: a symlinked instruction file's imports resolve from its target's directory (`path.resolve(dirname(realpath(importer)), name)`), as the walk does, and an `@` token's `..` after a directory link is resolved lexically, as the walk does."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the resolver's base directory and its lexical `..`, read from the 2.1.292 bundle. It does not establish whether Claude Code loads a symlinked instruction file in the first place: `EF` returns `[]` when `iH(e,Y)` holds for a non-canonical symlink, which I did not trace.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish the tree walk (which drops symlinked starts, A2/A3)" · r2: "It does not run Claude Code (Bun could not be started)"

The reader calls `ZMe(h,e,n,r)` with `r` = the resolved path, and `ZMe` calls `reo(G,s)` with that resolved path. `reo` resolves each name with `let Y=Ye(H,FT(n))`, where `FT` is `dirname`. `Ye` ends in `return Hn(x(i,o))`, with `x` = `path.resolve` (imported as `resolve as x`), and path.resolve is lexical. I quoted these from the bundle strings; no line numbers are available because the source is a minified bundle.

**Evidence:** bundle strings of `claude.exe` (lines 414155 and 421255 of `strings -n 8` output: `function Ye(e,r){...if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)));...return Hn(x(i,o))}`); r1: claude.exe offsets 212105067, 212107466, 205304326, 203431908; `scripts/lib/dev-cycle-read.sh:722-755`

---

## Claim 7: A5's "Not covered" list (start files under a symlinked directory or in a submodule or untracked nested repo, case-insensitive names, checkout conversions), now without "absolute imports"

**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5); mirrored in `scripts/lib/dev-cycle-read.sh:474-478` and plan F11 (`docs/working/plan-build-loop-handoff.md:126`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the list names every place Claude Code 2.1.292 loads instructions that import into the repo and that neither walk starts from; does not establish how often such files exist on the user's machines.
**Severity:** Medium (an undocumented fail-open class for the floor)
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1 (Goal-Alignment Escalate): "Claim 3 (Medium) to the orchestrator's synthesis: it is a fail-open class outside both walks' start sets, not covered by any override row" · r1 (Questions): whether "read broadly" in A5/the superset statement is meant to cover only files in the repo (then a documentation gap) or every instruction source a session loads

Dropping absolute imports is right (Claim 1). The list omits instruction files **outside the repo** whose imports Claude Code follows into it. Executed: with a scratch repo `cc/proj` (cwd of the session) and a `CLAUDE.md` in its **parent** directory holding `@proj/docs/g and @./proj/docs/h`, Claude Code logged

```
[DEBUG] [CLAUDE.md] skipping /tmp/u2a3bfcfin-10T4/cc/proj/docs/g: not a regular file or exceeds 4194304 byte limit
[DEBUG] [CLAUDE.md] skipping /tmp/u2a3bfcfin-10T4/cc/proj/docs/h: not a regular file or exceeds 4194304 byte limit
```

so an ancestor directory's CLAUDE.md imports repo files. The user memory (`$CLAUDE_CONFIG_DIR/CLAUDE.md`, i.e. `~/.claude/CLAUDE.md`) is loaded too, and its imports are followed. Neither walk starts outside ROOT_REAL: the tree walk's starts are `git ls-files` and `untracked_md` (`scripts/lib/dev-cycle-read.sh:647`), and main's are main's tree (`:699-719`). A repo file imported this way reads as "not imported". The superset statement's exceptions (Claim 25) are about names in a file the walk reads, so they do not cover this. Nothing in A5, F11 or the override log mentions ancestor or user-memory instruction files. With an ancestor `AGENTS.md` instead, nothing was loaded (`dbg-anc.txt`), so the class is CLAUDE.md (and possibly `.claude/CLAUDE.md`) in ancestors, plus user and managed memory.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt (`== cc/dbg-anc2.txt`, `== cc/dbg-u-set.txt`), /tmp/u2a3bfcfin-10T4/probe-cc.sh, `scripts/lib/dev-cycle-read.sh:647`, `scripts/lib/dev-cycle-read.sh:699-719`

---

## Claim 8: C2: "Each `@` token costs 3+ forks, and the `seen`/`queue` handling is quadratic."

**Location:** `docs/working/known-issues-dev-cycle.md:19`
**Type:** Performance / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-token fork claim against e1654266's tree walk; does not re-measure the seen/queue half.
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "The row predates this unit (not edited in the diff)"

The row describes the parser this unit replaced. At e1654266 a file costs one sed, one awk, at most one gate awk and one python3, and one `lower` for all its candidates (`lp="$(lower "$out")"`, `scripts/lib/dev-cycle-read.sh:673`). Per candidate, only `inrepo_here` forks, and only for a candidate that is a file (`if [[ -f "$p" && ...`, `:676`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:19`, `scripts/lib/dev-cycle-read.sh:611-633`, `scripts/lib/dev-cycle-read.sh:664-678`

---

## Claim 9: F11: "Gaps: known issue A5 (... checkout conversions (...), and three shapes untraced against Claude Code)."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of untraced shapes F11 attributes to A5; does not establish the remaining shape's behavior.
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale (compound) · r3=Stale
**Replicate annotations:** r3: the commit e1654266 body says "A5 records two traced items" and rubric L2-I2-C7 says "Fixed: ... A5 records the traced items", but F11 was not updated · r2: "Both should say one shape (`.claude/commands/` files)"

This commit moved two of A5's three shapes to "Traced in Claude Code 2.1.292" and left one: A5 now reads "Untraced (no host probe yet): whether `@` references in `.claude/commands/` files load." (`docs/working/known-issues-dev-cycle.md:18`). F11 was edited in the same commit but still says "and three shapes untraced against Claude Code)". Claim 19 is the same drift in the lib.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 10: F11: "The shared token parser reads a superset of Claude Code 2.1.292's import grammar (U2a3b; the claim and its exceptions are stated once, above `import_targets`); a Claude Code upgrade that changes its import grammar reopens this row."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pointer. Completeness of the superset is Claims 23-26.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

The statement sits above `import_targets` (`scripts/lib/dev-cycle-read.sh:501-532`) and ends `# Re-check the superset when Claude Code changes its import grammar` (`:530`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:501-532`

---

## Claim 11: U2a3c bullet: "one capped and drained reader (4 MiB + 1, Claude Code's limit) ... (a bare `head` after `git cat-file` exits 141 under pipefail ...); ... no third path resolver (IMPORT_AWK's `put` and the symlink arm's `realpath -ms` are the two)"

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 141 status, the limit and the two resolvers at e1654266; does not establish the bullet's design recommendations.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: cites the bullet at `:281` · r3: the 141 output "transcribed in this report; it was not captured to a file" · r3: "no other path resolution in import_targets, imported_names or main_imports" is paraphrased (absence, by grep)

Executed: `bash -c 'set -o pipefail; git cat-file blob <2.2 MB blob> | head -c 10 >/dev/null; echo $?'` printed `pipefail status: 141` (cwd the worktree, 2026-10-07). Claude Code's limit is `nH=4194304`, with `if(s.totalBytes>nH)return{kind:"skipped"...}` (binary, `teo`), so reading 4 MiB + 1 detects an over-limit file. The two resolvers are `put` (`scripts/lib/dev-cycle-read.sh:550-565`) and `realpath -ms` (`:739`, `:742`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:550-565`, `scripts/lib/dev-cycle-read.sh:739-742`, claude.exe offset 212105067 (`nH=4194304`, `teo`), /tmp/u2a3bfcfin-Q1w0-tmp/catfile.log

---

## Claim 12: U2b bullet: "the parser's root and home are the gate's own, but a session in another checkout (`git worktree list`) or under another HOME reads absolute and `~/` names against its own"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which name forms depend on the reading session's checkout. It does not establish U2b's root-set design.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r2: "does not establish U2b's future design / root-set design" · r2: cites the bullet at `:283` · r3 (Out of scope): "whether U2b's root set should include relative re-entry (a design question, raised only as a doc precision)"

A relative name can re-enter another checkout through that checkout's directory name, as an absolute one can. In a repo `wtA` with a linked worktree `wtB`, AGENTS.md held `See @../wtB/docs/x.md`. Run from wtA, `import_targets "" < AGENTS.md` printed nothing (`rc=0`). Run from wtB, it printed `docs/x.md`, the file a session in wtB imports, since Claude Code uses `path.resolve(dirname(realpath(importer)), name)` (Claim 6). (Command in `/tmp/u2a3bfcfin-wt-*`, 2026-10-07; output transcribed in r3.) The precise version is: "reads absolute names, `~/` names and relative names that re-enter through its own directory name against its own". Claim 25 has the same narrowing in the lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:559-560` (`if (index(out, pre) != 1 || length(out) <= length(pre)) return`), `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 13: help text: "a file an instruction file names after an @, read broadly; compared ignoring case) or README.md; "skip <path>: <reason>" otherwise, and for every path when the import walk fails."

**Location:** `scripts/dev-cycle.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix's arms at e1654266; does not establish the output when check_fix's own `tr` fails (override row, F3-C9).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish wording for globs and path-form refusals, which are unchanged" · r3: "does not establish which reason a path gets when an earlier arm already skips it"

Every arm of check_fix before `check_path` prints `skip`, and the walk runs before any `ok`:

```bash
# scripts/dev-cycle.sh:181-184
  elif ! imported_names; then
    echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"
  elif isimported tree "$lp"; then
    echo "skip $a: an instruction file names it after an @ (directly or through another import), so it may be read as instructions; file it instead"
```

The test `--check-fix words a failed import walk as one and refuses (U2a3b)` (`test/scripts/dev-cycle.bats:1048`) passes.

**Evidence:** `scripts/dev-cycle.sh:170-185`, `test/scripts/dev-cycle.bats:1048-1057`, /tmp/u2a3bfcfin-10T4/logs/suites.txt

---

## Claim 14: lib header: "The import walks also need python3 when an instruction file holds text that is not well-formed UTF-8; without it they fail closed."

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when python3 forks and the failure arm. It does not establish other decoders.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1+r3: read "instruction file" as any file the walks read (imported files included, which are read as instructions), and on that reading Verified · r3: "does not establish behaviour when python3 is present but differs from Bun's decoder outside the tested cases" · r1: a gate probe counted 0 python3 forks for valid UTF-8 and ASCII and 1 for `\xff` (/tmp/u2a3bfcfin-10T4/logs/gate-probe.txt)

The mechanism holds. python3 forks only when the gate rejects a line (`if [[ "$toks" == *[$'\x80'-$'\xff']* ]] && ! printf '%s\n' "$toks" | env LC_ALL=C awk -v ok="$UTF8_OK" '$0 !~ ok { exit 1 }'; then`, `:622`), and a failing python3 returns 1 (`:623`). The test "both walks fail closed when python3 fails ..." passes. The trigger is wider than "an instruction file", though. The parser runs on every file the walk reads, including imported docs and, in the tree walk, the first 4 MiB of any plain file a prefix candidate names (`if [[ -f "$p" && ...` at `:678` queues any such file, then `:669` reads it). Precise version: "when a file the walk reads holds text ...".

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-13,622-625,669,678`, `test/scripts/build-loop-check.bats:573-580`, /tmp/u2a3bfcfin-Q1w0-tmp/gate.log

---

## Claim 15: lib header: "(check_answer, brief_fields, tree_starts, imported_names and main_imports also set pipefail for themselves)"

**Location:** `scripts/lib/dev-cycle-read.sh:14-15`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the five named functions; does not establish that no other function sets it.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2+r3: check_answer and brief_fields are unchanged and were not re-read

`rg 'set -o pipefail'` finds `:325` (brief_fields), `:647` (tree_starts), `:649` (imported_names), `:693` (main_imports) and `:869` (check_answer), each after `local -`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:325`, `:647`, `:649`, `:693`, `:869`

---

## Claim 16: lib header: "imported_names and main_imports return 1 when the walk fails: call them under if or ||."

**Location:** `scripts/lib/dev-cycle-read.sh:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three walk functions this unit touched. check_answer and brief_fields are unchanged and were not re-read here.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

`tree_starts() { local -; set -o pipefail; ...` (`:647`), `local - f d p lp out used=0 ...; set -o pipefail` (`:649`), and `local - rec f d p i c lk out used=0 ...; set -o pipefail` (`:693`). Both walks' failure arms `return 1`, and the callers in scripts/ use `elif ! imported_names` (`scripts/dev-cycle.sh:181`) and `main_imports || return 0` (`:775`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:647,649,693,775-776`, `scripts/dev-cycle.sh:181`

---

## Claim 17: imported_names header: "(import_targets reads a superset of its names, ~/ against this process's HOME, and drops paths outside the repo)"

**Location:** `scripts/lib/dev-cycle-read.sh:452-453`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `return 1` in imported_names (`:648-680`, read whole). It does not establish callers outside scripts/.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate (compound) · r3=Verified
**Replicate annotations:** merge note: r2 verdicted this parenthetical and the failure list (Claim 18) as one compound, and its Mostly accurate rests on the failure list. On this half r2 wrote: "'~/ against this process's HOME' is right in effect, with the passwd fallback (`:606`)" · r3 (Verified): "does not cover an unset or empty HOME, where import_home uses the passwd entry rather than 'HOME'"; the HOME and below-ROOT_REAL tests pass and the no_homer mutant fails the symlinked-HOME test

r2's evidence on this row (carried as the winning replicate's): "~/ against this process's HOME" is right in effect, with the passwd fallback (`h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}"`, `:606`; Claim 33). The compound verdict comes from the failure-list half, which is quoted in Claim 18. That half leaves out `import_home || return 1` (`:662`) and the walk-wide budget (`:671`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:452-458,648-680`, `:543-548`, `:559`, `test/scripts/build-loop-check.bats:618-626`

---

## Claim 18: imported_names: "It returns 1, with IMPORTED set to "error", when the start listing (git ls-files, untracked_md, instruction_names), lower, a file read or the parser fails, or a start file's name holds a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:453-458`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `return 1` in imported_names; does not establish callers' handling (Claim 13, Claim 46).
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Mostly accurate
**Replicate annotations:** r2: "does not establish callers outside scripts/"; the budget arm "is described only in the IMPORT_OUT_MAX comment (`:484`)"; "each of these returns 1 with IMPORTED still or again 'error', so the conclusion holds and only the list is incomplete" · r3: "does not establish behaviour under need_root, which exits"; "the budget overrun usually shows up as a parser failure (awk stops at IMPORT_LEFT first), but import_home's failure is a separate arm"; precise version: add "import_home fails, or the walk prints past IMPORT_OUT_MAX"

Every listed arm exists (`:653`, `:656`, `:657`, `:669`, `:673`). One arm is not listed: `import_home || return 1` (`:662`), added on this branch. The walk-wide budget arm, `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED=error; return 1; }` (`:671`), is in practice the parser's: awk stops at `IMPORT_LEFT` first (Claim 20), and a mutant deleting the bash check survives both suites (`used-check-dropped-tree`, /tmp/u2a3bfcfin-10T4/logs/mutants.txt). The precise list adds "import_home".

**Evidence:** `scripts/lib/dev-cycle-read.sh:648-679`, /tmp/u2a3bfcfin-10T4/logs/mutants.txt

---

## Claim 19: "Not covered (known issue A5): ... checkout conversions (A5), and three shapes A5 lists as untraced against Claude Code."

**Location:** `scripts/lib/dev-cycle-read.sh:477-478` (main_imports block)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count against A5's text at e1654266. Same finding as Claim 9, in the lib.
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale (compound) · r3=Stale
**Replicate annotations:** r1: "Claim 3's omission applies here too" (the out-of-repo instruction files of merged Claim 7)

This branch edited this sentence (it dropped "absolute imports,"), but A5 now lists one untraced shape (the `.claude/commands/` question) and two traced ones (quoted in Claim 9). Precise version: "and the shape A5 lists as untraced against Claude Code".

**Evidence:** `scripts/lib/dev-cycle-read.sh:477-478`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 20: IMPORT_OUT_MAX: "Each walk fails once import_targets has printed more than this in all (characters, newlines between names counted; awk counts bytes, so it may stop first) ... A fresh clone's walks print about 2 KB, /workspace's about 6 KB. A caller that changes it clears IMPORTED_DONE and IMPORTED_MAIN_DONE before walking again."

**Location:** `scripts/lib/dev-cycle-read.sh:484-490`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "more than" boundary, characters against bytes, and both size figures as measured on 2026-10-07. It does not cover /workspace's main walk, which fails there (A5: ignored instruction files), so "/workspace's" walks means its tree walk.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish the figures for other checkouts"; measured 2,014 per walk over 45 files in the clone and 5,596 over 80 files for /workspace's tree walk (r3 reports 5 and 10 files for the same totals); the `left-off-by-one` mutant fails tests 36 and 42 · r2: measured via `${#IMPORTED}`, "which adds one newline per file": clone 2020/2020, /workspace tree 5607; the cache key omits IMPORT_OUT_MAX, so the clearing instruction is needed

- **Boundary.** The test with IMPORT_OUT_MAX 20/25/26 passed (`26 tree ok`, `26 main ok`). Under C.UTF-8, a name holding `\xc3\xa9` printed 19 bytes, which bash counts as 15 characters, so awk's byte count trips first, as stated.
- **Sizes.** Measured by wrapping import_targets and summing `${#o}` (`/tmp/u2a3bfcfin-meas-w1N2/meas.sh`). The fresh clone printed 2,014 characters over 5 files, in both the tree and the main walk. The worktree also printed 2,014, and /workspace's tree walk printed 5,596 over 10 files.
- **Clearing the caches.** The tests clear `IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""` before re-walking (`test/scripts/build-loop-check.bats:339`).

(r3 transcribed the size outputs: `tree ok 5596 10`, `tree ok 2014 5`, `main ok 2014 5`.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:484-490`, `:562-564`, `:669-671`, `:744-747`; `test/scripts/build-loop-check.bats:600-607`; /tmp/u2a3bfcfin-10T4/logs/walk-output-size.txt; /tmp/u2a3bfcfin-Q1w0-tmp/sizes.log

---

## Claim 21: UNI_SPACES: "U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F, U+3000 and U+FEFF (Claude Code's token ends at JavaScript's \s)"

**Location:** `scripts/lib/dev-cycle-read.sh:491-496`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the non-ASCII members of JS `\s` and the array's bytes. JS `\s` also holds `\v` and `\f`, which awk does not treat as blanks; that only over-reads, since every prefix is emitted.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r1: "does not establish test coverage of the conversion (Claim 32)" (merged Claim 49: the UNI_SPACES mutant survives)

The array holds the 19 UTF-8 encodings `$'\xc2\xa0'` ... `$'\xef\xbb\xbf'` (`:494-496`). `reo`'s regex is `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` (offset ≈212107518).

**Evidence:** `scripts/lib/dev-cycle-read.sh:491-496`, `:614`, claude.exe ≈212107518

---

## Claim 22: import_targets header: "one repo-relative path per line, case kept, each once."

**Location:** `scripts/lib/dev-cycle-read.sh:498-499`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers one call's output. Names repeat across calls (the walks dedup separately).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

`if (out in seen) return` / `seen[out] = 1; ...; print out` (`:561-564`). No case folding happens before print.

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-564`

---

## Claim 23: "these rules read every name Claude Code 2.1.292 can import (its import regex and Markdown lexer ...)" (outside the named exceptions)

**Location:** `scripts/lib/dev-cycle-read.sh:501-504`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the rules yield every name Claude Code 2.1.292's extractor yields from a file's text (Node's UTF-8 decoder in the fuzz, the real binary for U+FFFD); does not establish which files the walks read (Claim 7) or the decoding of Bun on inputs beyond the 8 probed sequences.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2 (Confidence Medium): "It does not establish Bun's runtime behaviour (not runnable), what `AD`/`Pd` compares (the module-local `Pd` could not be identified in the bundle), or Claude Code's handling of an empty `homedir()`" · r3 (Confidence Medium): "does not cover lexer paths I did not enumerate (for example, every marked block rule's text transforms), the start-file set (A2/A5), or the exceptions"; executed 13 shapes and 5 invalid-UTF-8 cases through the real binary · r3: two over-reads, not misses: a name holding a NUL makes Claude Code drop the whole file; Claude Code did not load `~/...` through a symlinked HOME

Differential fuzz (executed): 7,000 generated byte documents (two runs, seeds 4242 and 777) went through the extracted Claude Code lexer and a verbatim `reo` (resolver transcribed for posix; the EP filter was left out, which only enlarges Claude Code's set), and were compared against `import_targets sub` with `ROOT_REAL=/r`, `HOME=/r/hh`: **3,236 expected names, 0 misses, 0 parser failures**. Commands: `node gen.cjs 3000 4242 && bash run-parser.sh <lib> 3000`, `node gen2.cjs 4000 777 && bash run-parser.sh <lib> 4000`, cwd /tmp/u2a3bfcfin-10T4/h, exit 0, 2026-10-07T09:20Z. Harness sensitivity: main's lib misses 345 of 736 names on 1,000 of the same documents. The documented test cases (`build-loop-check.bats:339`, `:365`, `:528`) give the same names through the extracted lexer as their comments state (/tmp/u2a3bfcfin-10T4/h/check-cases.cjs). The real binary was given `@q/<k><invalid bytes>` for 8 invalid sequences (lone `\xff`, truncated 4-byte, surrogate, overlong 3- and 2-byte, past U+10FFFF, truncated 3-byte, overlong 4-byte). It resolved all 8 to python3's `decode("utf-8","replace")` spellings, and `import_targets` yields all 8.

**Evidence:** `scripts/lib/dev-cycle-read.sh:534-633`; /tmp/u2a3bfcfin-10T4/logs/fuzz-1.txt, fuzz-2.txt, fuzz-main.txt; /tmp/u2a3bfcfin-10T4/h/gen.cjs; /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt (`== cc/dbg-dec2.txt`); logs/cc-shapes.txt (r3)

---

## Claim 24: The superset statement's rules: "Every @ in a line starts a candidate ...; each prefix of the run after it, up to the first blank (a NUL or a UNI_SPACES space counts as one), is a candidate name, with a backslash-escaped space read as a space. A line holding <!-- is also read with its closed HTML comments removed ..., and text holding a byte above 0x7f is also read decoded ... Each candidate is trimmed of spaces, made absolute ... and resolved lexically, .. stopping at / ..., kept only when it lies below ROOT_REAL ... A ~/ name is joined to this process's home (import_home), in its spelled and real forms."

**Location:** `scripts/lib/dev-cycle-read.sh:504-516`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each rule against IMPORT_AWK and import_targets (`:533-632`, read whole). Whether the rules are a superset of Claude Code is Claim 23.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: every rule's mutant run fails a test (no_trim, no_homer, no_left, gate_never: `logs/mutants.txt`)

Each rule maps to a line of code:
- Every @: `if (substr(line, i, 1) != "@") continue` over all `i` (`:568-569`).
- Every prefix to the first blank: `name = name ch; emit(name)` until `ch == " " || ch == "\t" || ch == "\r"` (`:573-575`).
- Escaped space: `if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ }` (`:573`).
- NUL and UNI_SPACES become blanks: `s=(-e 's/\x0/ /g')` plus one `s/$u/ /g` per space (`:612-614`).
- Splice: `{ scan($0); if (index($0, "<!--")) scan(splice($0)) }` (`:592`), where `splice` removes only closed comments (`j = index(r, "-->"); if (j == 0) break`, `:583`).
- U+FFFD decoding, gated: `:622-625` (Claim 32).
- Trim: `sub(/^ +/, "", c); sub(/ +$/, "", c)` (`:539`).
- Absolute, clamp and below-root, as quoted in Claim 1 (`:551-560`).
- ~/: `if (homer != home) put(homer "/" substr(c, 3))` / `c = home "/" substr(c, 3)` (`:545-546`).

Executed: the superset, re-entry, absolute, backslash, long-name, splice3, clamp, HOME and HOME-symlink tests all pass at HEAD (`suite.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:504-516,533-632`, /tmp/u2a3bfcfin-Q1w0-tmp/suite.log

---

## Claim 25: "Known exceptions, where a session reading the file can import what these rules do not yield: a session whose home differs from this process's (its ~/ names), a session in another checkout of the repo (an absolute name into that checkout; the gate's root set is U2b's), names that differ only in case on a case-insensitive file system (docs/reviews/override-log.md line 350), Claude Code's approved external includes, and any further decoding it may add (an entity, a percent escape)."

**Location:** `scripts/lib/dev-cycle-read.sh:516-523`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each exception's reality and the "another checkout" parenthetical. The case-insensitive exception is not reproducible on this host (case-sensitive filesystem), and "further decoding it may add" is about future versions.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "does not cover files the walks never read (Claim 3: ancestor and user-memory instruction files), the tree walk's symlink gaps (A2/A3), or Bun-specific decoding beyond Claim 16's probe" · r2: "does not establish Bun's runtime behaviour (not runnable), what `AD`/`Pd` compares ..., or Claude Code's handling of an empty `homedir()` (Claim 27b)" · r1: a symlinked spelling of the repo as the session's cwd did not load an absolute name spelled through the link (`dbg-link`)

- **Another home: real.** With HOME=$d, Claude Code loaded `repo/c.md` from `@~/repo/c.md` (`logs/cc-home.txt`).
- **Another checkout: real, but the parenthetical is too narrow.** A relative name that re-enters another checkout through that checkout's directory name (`@../wtB/docs/x.md`) is missed too (executed: Claim 12). Precise version: "(an absolute name into that checkout, or a relative one re-entering through its directory name; ...)".
- **override-log.md line 350: right line.** It is the row about "other names on a case-insensitive checkout".
- **Approved external includes: real** in the bundle. `if(g>0&&!z&&!AD(he))return[]` loads an include outside the project only when `z` is set, and such a file can import repo files the walk never reads.
- **Entity and percent decoding.** 2.1.292 does neither: inline text is raw and `Ye` does not decode. That fits "may add".

**Evidence:** `scripts/lib/dev-cycle-read.sh:516-523`, `docs/reviews/override-log.md:350`, logs/cc-home.txt (r3)

---

## Claim 26: the five named exceptions are complete (no other name Claude Code imports is missed)

**Location:** `scripts/lib/dev-cycle-read.sh:516-523`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers names in a file the walk reads, against Claude Code 2.1.292's extractor, resolver and loader: the five are real and no sixth name-level exception was found; does not cover files the walks never read (Claim 7: ancestor and user-memory instruction files), the tree walk's symlink gaps (A2/A3), or Bun-specific decoding beyond Claim 23's probe.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "I found no shape outside the five named exceptions. Bun's decoder (Claim 26) and empty HOME (Claim 27b) are the residues" · r3: "does not establish completeness over every marked transform or every host state, and it is subject to the parenthetical in 15c" (merged Claim 25); ruled out by execution: symlinks outside the repo into it (`iH` rejects a non-canonical symlinked path), a symlinked HOME, empty HOME, relative HOME

Real: `~/` uses the reading process's `os.homedir()` (`if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))`, `homedir as c`). In-project checks use the session's root (`if(!AD(Pe)&&!z)continue` in `EF`), so outside names load only as approved external includes. Line 350 of the override log is the case-insensitive row. "Further decoding" is hedged ("may add"): the bundled marked returns `{type:"text",raw:n[0],text:n[0],...}` (no entity decoding), and `Hn` is the identity (no Unicode normalization). r1 searched for other misses and found none:
- marked's lex only rewrites `\r\n|\r` to `\n` (`e=e.replace(_r.carriageReturn,...)`);
- escape, code, codespan and non-comment html tokens are skipped, which narrows;
- frontmatter is stripped, which narrows;
- a NUL in a name makes `Ye` throw `NullBytePathError`, so the file loads nothing;
- imports nest at most `I9n=5` deep;
- names cannot be relative-to-cwd unless HOME is relative, and the parser fails on a relative HOME (probe: `HOME=rel` resolved `@~/proj/docs/e` to `rel/proj/docs/e`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:516-525`, `docs/reviews/override-log.md:350`, claude.exe offsets 205304326, 210336074, 212105067, 212107466; /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt

---

## Claim 27: "The cost is false positives: a prefix that is itself a file counts as imported, and so does a name led by an escaped space."

**Location:** `scripts/lib/dev-cycle-read.sh:522-524`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named over-reads. It does not enumerate every over-read (code spans, `user@`, `~x` are pinned in the over-read test too).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

The over-read test pins `docs/pre.md` (from `@docs/pre.md.bak`) and `docs/lead.md` (from `@\ docs/lead.md`) as imported in both walks, and it passes. `reo`'s filter rejects a name led by a space before `Ye` trims anything (no branch accepts a leading space; offset ≈212107518).

**Evidence:** `test/scripts/build-loop-check.bats:365-388`, `scripts/lib/dev-cycle-read.sh:539`, claude.exe ≈212107518

---

## Claim 28: "It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is empty, when a ~/ name appears and the home is not absolute, or when the candidates and comment splices run past a work bound or print past IMPORT_LEFT"

**Location:** `scripts/lib/dev-cycle-read.sh:526-529`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every failure arm of import_targets (`:611-633`, read whole) and awk's exits 2, 3 and 4. It does not cover a caller without pipefail when `printf` into awk fails (not listed; under the walks' pipefail it returns 1).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: the gate awk's failure is by design a fall-through to decoding, not a failure arm · r2: "It does not establish behaviour when `printf` itself fails, which can only add a non-zero status"; an unset ROOT_REAL under `set -u` also gives `rc=1` (`unset.log`)

Each arm returns 1:
- `import_home || return 1`;
- `toks="$(env LC_ALL=C sed "${s[@]}")" || return 1`;
- python3's `|| return 1`;
- the final awk `|| return 1`, where the awk exits 2 when `root == ""` (`:590`), 3 at the work bound or IMPORT_LEFT (`:536`, `:563`, `:582`), and 4 for a home that is not absolute (`:544`).

No failure arm returns 0. The only failure that does not return 1 is the UTF8_OK gate's awk, which by design falls through to decoding (Claim 32).

Tests (all passed):
- "the parser returns 1 when it cannot read its input" (`import_targets "" < docs` → `failed`);
- the empty ROOT_REAL case (`rc=1`);
- the relative home (`tilde=1`);
- the work bound (`rc=1`);
- `IMPORT_LEFT` (`12=1`).

The no_reltilde_fail and no_left mutants fail (`logs/mutants.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:534-633`, `test/scripts/build-loop-check.bats:383-388`, `:582-587`, `:648-659`, /tmp/u2a3bfcfin-Q1w0-tmp/unset.log

---

## Claim 29: emit: "Claude Code trims the name; it rejects a name led by a space first, so trimming one only over-reads."

**Location:** `scripts/lib/dev-cycle-read.sh:537-538`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the leading-space case in Claude Code 2.1.292's extractor and resolver; a trailing escaped space is trimmed by both and the prefix is yielded anyway.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3 (executed): `@\ docs/lead.md` was not loaded by the real binary (`logs/cc-shapes.txt`)

`reo` filters before it resolves: `H.startsWith("./")||H.startsWith("~/")||H.startsWith("/")&&H!=="/"||!H.startsWith("@")&&!H.match(/^[#%^&*()]+/)&&H.match(/^[a-zA-Z0-9._-]/)`, which a name starting with a space fails. Only then does `Ye` run `let n=e.trim();`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:537-540`, claude.exe offsets 212107466, 205304326

---

## Claim 30: emit: "~/ joins the home directory (Claude Code: path.join(os.homedir(), rest)), also spelled through its real path, since ROOT_REAL is real."

**Location:** `scripts/lib/dev-cycle-read.sh:541-547`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the join and the real-path spelling the code adds. It does not establish that Claude Code loads the real-path spelling: under a symlinked HOME it does not (executed), so that spelling, and the test name "both walks read an @~/ import when HOME is a symlink..." (`test/scripts/build-loop-check.bats:638`), describe an over-read.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish other homes (Claim 17)"; mutants `home-join-dropped` and `homer-dropped` each fail tests `:618`/`:638` · r2: "It does not establish whether Claude Code imports the real-path spelling (its `AD(Pe)` check reads the spelled path, and `Pd` was not identified), so the real form may be an over-read" (r3 settled this by execution: over-read)

Bundle: `if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))`, where `b` is `join` and `c` is `homedir` (imports `homedir as c` and `join as b`). Executed: with HOME=`.../hl` (a link to the repo's parent), Claude Code loaded only CLAUDE.md, not `~/repo/c.md`. With HOME set to the real directory, it loaded `repo/c.md` (`logs/cc-home.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:541-548`, logs/cc-home.txt (r3), /tmp/u2a3bfcfin-10T4/logs/mutants.txt

---

## Claim 31: "printed counts as the walks count: each name, a newline between names."

**Location:** `scripts/lib/dev-cycle-read.sh:562-563`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte equality under LC_ALL=C. Under a UTF-8 caller locale, `${#out}` counts characters (≤ bytes), as Claim 20 says.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** none

awk adds `length(out) + 1` per name and tests `printed - 1 > left`. That total is Σlen + (n−1), which is `${#out}` after `$(...)` strips the final newline. The tests show it at the boundary: `see @a.md` with `IMPORT_LEFT` 12 gives 1 and with 13 gives 0, and two files pass at an exact `IMPORT_OUT_MAX=26` (both pass in `suite.log`). Removing the stop fails only test 42 (`mutants.log`: `no_left_stop`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:562-563,669-671`, `test/scripts/build-loop-check.bats:600-607,655-660`, /tmp/u2a3bfcfin-Q1w0-tmp/mutants.log

---

## Claim 32: UTF8_OK: "Well-formed UTF-8 (RFC 3629 ...), as an awk ERE for a C-locale awk -v: it agreed with python3's decoding on 20,013 cases (U2a3b L2-i2 performance F1). Only text it rejects forks python3, since well-formed text decodes to itself."

**Location:** `scripts/lib/dev-cycle-read.sh:593-597`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk (the only awk installed) and python3's `replace` decoding over 30,017 lines, plus the fork condition. It does not establish gawk or busybox awk, which are not installed.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: the exact 20,013 count is the earlier critic's and was not reproduced · r1: independent run of 50,000 cases, 0 disagreements · r3: independent run of 30,000 cases, 0 disagreements · r1+r2+r3: a failing gate awk forks python3, so the gate fails toward decoding

The figure is the critic's: "It agrees with python3's `replace` decode on all 20,013 cases" (`docs/reviews/performance-reviewer-review-2026-10-07-L2i2-build-loop-u2a3b.md:66`). r2 re-ran the committed `UTF8_OK` under `env LC_ALL=C mawk -v ok=...` against `l.decode("utf-8","replace").encode()==l` over 30,017 lines: 17 edge cases (surrogates, F4 90, overlongs, F5/F8 leads, BOM, U+FFFE) plus 30,000 random ones. The results were identical, 1,241 well-formed and 28,776 not (`utf8chk.log`). Fork condition: with valid `é`, python3 ran 0 times. With the gate awk forced to exit 2, python3 ran once and the output was still right (`gate.log`). So a failing gate fails toward decoding. Removing the fork (`gate_never_forks`) fails tests 31, 33 and 100 (`mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:593-597,622-625`, /tmp/u2a3bfcfin-Q1w0-tmp/utf8chk.log, /tmp/u2a3bfcfin-Q1w0-tmp/gate.log, /tmp/u2a3bfcfin-Q1w0-tmp/mutants.log, /tmp/u2a3bfcfin-10T4/logs/utf8-gate-fuzz.txt

---

## Claim 33: import_home: "IMPORT_HOME and IMPORT_HOMER (its real path) for the parser's ~/ names, from HOME ... (unset or empty: the passwd entry)."

**Location:** `scripts/lib/dev-cycle-read.sh:598-610`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what Claude Code 2.1.292 (Bun) does with unset and empty HOME, and import_home's matching rule; Claim 34 covers the Node attribution.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "It does not establish the empty-HOME half (Claim 27b)" (merged Claim 34) · r3: Claude Code with `HOME=` and unset loaded `repo/b.md` through `@~/../../tmp/u2a3bfcfin-cc-OhOV/repo/b.md`, which resolves only from `/home/node` (`logs/cc-home.txt`)

`h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}"` takes the passwd entry for unset or empty HOME. Claude Code does the same. With `HOME=` and with HOME unset, the user-memory import `@~/.cargo` resolved to `/home/node/.cargo`, the passwd home (`node:x:1000:1000::/home/node:/bin/bash`). With `HOME=<scratch>/fakehome` it resolved under that directory.

**Evidence:** `scripts/lib/dev-cycle-read.sh:604-610`; /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt (`dbg-u-set`, `dbg-u-empty`, `dbg-u-unset`); logs/cc-home.txt (r3)

---

## Claim 34: import_home: "from HOME as Node's os.homedir reads it (... empty: the passwd entry)"

**Location:** `scripts/lib/dev-cycle-read.sh:599-600,606`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Node v22's `os.homedir()` with `HOME=""`. It does not establish Bun's behaviour (not runnable) or how Claude Code then resolves a `~/` name against an empty home (`path.join("", rest)` is relative, and `Pd` was not identified).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r3: "does not change Claim 22a / 21a: the code matches Claude Code". By execution, Claude Code (Bun) uses the passwd entry for an empty HOME (merged Claim 33), so r2's conditional divergence ("if Claude Code's Bun runtime behaves like Node") does not arise. Precise version: "as Claude Code's runtime (Bun) reads it; Node keeps an empty HOME" · r3: someone who checks the comment against Node and "fixes" the code to keep an empty HOME would make the parser fail on every `~/` name (fail-closed, but a divergence) · r2 (Escalate): "The only behavioural item is Claim 27b (empty HOME). Its effect is a session with `HOME=""`, which the superset's first exception arguably covers" · r2 (Question): whether an empty HOME should fail closed on a `~/` name, as a relative one does, rather than take the passwd entry

`HOME= node -e 'console.log(require("os").homedir())'` prints `[]`, an empty string, not the passwd entry (`homedir.log`). libuv reads HOME whenever it is set, even when it is empty. The code reads `${HOME:-...}`, so an empty HOME takes the passwd entry (`HOME empty -> IMPORT_HOME=[/home/node]`, `unset.log`). Node's `path.join("", "docs/a.md")` is `docs/a.md` (`unset.log`). If Claude Code's Bun runtime behaved like Node here, an `@~/docs/a.md` in a session with `HOME=""` would name a path relative to the session, and the walk would resolve it under `/home/node` instead. The superset statement's first exception ("a session whose home differs from this process's") arguably covers that session, because this process's home is import_home's value. Either way, the comment's claim about Node is wrong. Precise version: "(unset: the passwd entry; Node keeps an empty HOME, which this reads as unset)", or `${HOME-...}` together with a fail-closed rule for an empty home on a ~/ name. Changing `${HOME:-` to `${HOME-` fails no test in build-loop-check.bats or dev-cycle.bats (`mutants.log`: `empty_home_kept`), so no test pins either reading.

**Evidence:** `scripts/lib/dev-cycle-read.sh:599-600,606`, /tmp/u2a3bfcfin-Q1w0-tmp/homedir.log, /tmp/u2a3bfcfin-Q1w0-tmp/unset.log, /tmp/u2a3bfcfin-Q1w0-tmp/mutants.log, /tmp/u2a3bfcfin-10T4/logs/node-homedir.txt

---

## Claim 35: import_home: "A walk calls it once, so the parser's $(...) calls inherit it; it recomputes only when HOME changes."

**Location:** `scripts/lib/dev-cycle-read.sh:600-601`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers import_home's cache key and its callers. It does not measure cost.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "'recomputes' is the realpath and assignments (with HOME empty or unset, getent still runs on each call before the key check)" · r2: "Recompute is keyed on the resolved home, which differs from 'HOME changes' only when HOME goes from unset to empty"; import_targets calls it again (`:613`), which hits the inherited key

import_targets also calls `import_home || return 1` on every file (`:613`), so "once" means it is computed once. The per-file call returns at `[[ "$IMPORT_HOME_KEY" != "x$h" ]] || return 0`. The key is the computed home, not HOME. With a realpath shim, the sequence `HOME=/tmp`, `/tmp` again, `/usr`, `""` and then unset gave 3 realpath calls, and the unset case reused the empty case's `/home/node`. With HOME unset or empty, the `getent` fork still runs on every call, once per file read. Precise version: "it re-resolves (realpath) only when the computed home changes; with HOME unset each call runs getent".

**Evidence:** `scripts/lib/dev-cycle-read.sh:604-613`

---

## Claim 36: import_home: "A relative or empty home is kept, and the parser fails on a ~/ name then."

**Location:** `scripts/lib/dev-cycle-read.sh:601-602`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HOME=rel and a failing getent. Claude Code with a relative HOME imports a cwd-relative path (it loaded `sub/a.md` with HOME=sub, `logs/cc-home.txt`), so failing closed there is safe.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: Node with `HOME=rel` returns `rel`; removing `exit 4` fails test 41

With HOME=rel: `rel->[rel][rel]`. With HOME unset and a getent shim that exits 2: `getent-fail->[]`. In both cases `printf "see @~/x.md\n" | import_targets ""` gave `tilde rc=1`. The test at `test/scripts/build-loop-check.bats:648-653` passed, and the no_reltilde_fail mutant fails it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:543-545`, `:606-609`, logs/mutants.txt (r3)

---

## Claim 37: import_targets: "Claude Code decodes the file as UTF-8 and turns each invalid sequence into U+FFFD ... (python3's "replace" decoding matched Claude Code's byte for byte: U2a3b L2 security F1)."

**Location:** `scripts/lib/dev-cycle-read.sh:618-621`
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the binary calls (`Buffer.from(...).toString("utf8")` in `teo`, offset ≈212105900). It does not establish Bun's decoder, which could not be run.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Unverifiable · r3=Verified
**Replicate annotations:** r1 (Verified, executed): the real binary resolved 8 of 8 invalid sequences to python3's replace spelling, and python3 and Node's Buffer agreed on 20,000 random edge-byte strings; "does not establish Bun's decoder on every input" · r3 (Verified, executed, Confidence Medium): Claude Code loaded exactly the U+FFFD-spelled files import_targets printed for 5 invalid sequences; "does not cover every invalid shape" · r1 (Out of scope): "Bun's UTF-8 decoder beyond 8 probed sequences (no Bun runtime other than the claude binary)"

The call is Node-API UTF-8 decoding, and the L2-i2 fact-check matched python3 against Node v22 on 20,000 strings. Claude Code runs on Bun, and `BUN_BE_BUN=1 claude.exe -e ...` prints `error: unknown option '-e'` (r2's session). So r2 found "matched Claude Code's" established only for Node, as the L2-i2 report's Claim 15 recorded (Mostly accurate there). The blocker is that Bun cannot run in this sandbox. A Bun runtime of the matching version, run over the same corpus, would settle it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:618-621`, claude.exe ≈212105900, `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i2.md:267`, /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt (`dbg-dec2`)

---

## Claim 38: "A pipe, not a here-string ...", "dir, root and home go through the environment: awk -v would read backslash escapes in them."

**Location:** `scripts/lib/dev-cycle-read.sh:626-629`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated reasons via their tests and mutants.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Tests pass: a 70 KB file under `ulimit -f 0` still yields `docs/big.md` (`:408`), and a directory named `docs/a\tb` resolves literally (`:506`; it FAILS at be94c871).

**Evidence:** `scripts/lib/dev-cycle-read.sh:626-632`, `test/scripts/build-loop-check.bats:408-446`, `:506-515`

---

## Claim 39: "IMPORT_LEFT, set by a walk, is what its IMPORT_OUT_MAX budget has left, so awk stops there rather than after."

**Location:** `scripts/lib/dev-cycle-read.sh:629-632`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' `IMPORT_LEFT=$((IMPORT_OUT_MAX - used))` and awk's check. It does not cover the 1.0 s timing (Claim 67).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** r1: IMPORT_LEFT 12 fails and 13 passes (`:655`); mutant `left-ignored` fails test 42

`IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d"` appears at `:669` and `:726`, and awk checks `if (printed - 1 > left) exit 3` before `print out` (`:563-564`). The no_left mutant fails "the parser itself stops once it has printed more than IMPORT_LEFT allows".

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-564`, `:632-633`, `:669`, `:726`, logs/mutants.txt (r3), /tmp/u2a3bfcfin-10T4/logs/mutants.txt

---

## Claim 40: instruction_names: "It returns 0 when no name matches and 1 when grep fails (grep's own no-match is 1)."; tree_starts: "failing when any of the three commands fails."

**Location:** `scripts/lib/dev-cycle-read.sh:637-647`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both one-line functions. It does not establish behaviour under a non-GNU grep.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

`grep -zaiE ... || [[ $? -eq 1 ]]` (`:639`) maps grep's 2 to 1 and its 1 to 0. tree_starts is `{ git ls-files -z && untracked_md; } | instruction_names` under `set -o pipefail` (`:647`). The grep-shim, tracked-listing-only git-shim and corrupt-index tests pass (`suite.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:637-647`, `test/scripts/build-loop-check.bats:417-420,477`

---

## Claim 41: imported_names: "Claude Code skips a file over 4 MiB, so reading only its start over-reads at worst, and a huge file a prefix candidate names cannot stall the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:667-669`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk's read; the main walk still reads blobs whole (override row 2026-10-07, routed to U2a3c).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: mutant `tree-cap-4MiB` (`head -c 4194304`) survives; "it is equivalent for imports (reading 4 MiB of an over-limit file only over-reads less)" · r2 (Out of scope): the main walk's capped blob read is routed to U2a3c, not re-raised

Binary: `nH=4194304`, `if(s.totalBytes>nH)return{kind:"skipped",isDirectory:!1}`, and the logged message `exceeds ${nH} byte limit`. Code: `head -c 4194305 -- "$f"`. Tests `:564` (sparse 300 MB under a 20 s timeout) and `:609` (exactly 4,194,304 bytes, import in the last 14) pass, and mutant `tree-cap-dropped` fails `:564`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:667-669`, `test/scripts/build-loop-check.bats:564-571`, `:609-616`, claude.exe offset 212105067, /tmp/u2a3bfcfin-10T4/logs/mutants.txt

---

## Claim 42: main_imports' failure list: "returns 1, with IMPORTED_MAIN set to "error", ... when main is not found by name, ... a blob cannot be read, symlink text ..., or an imported path main lacks lies under a directory main stores as a symlink or gitlink or exists in the checkout as anything but a plain directory below the root"

**Location:** `scripts/lib/dev-cycle-read.sh:680-691`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list against main_imports' `return 1` arms at e1654266; the override log's 2026-10-06 row (routed to U2a3, closed "Fixed (on main)") covered an earlier version of this gap.
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "Older arms were checked in U2a3's review and not re-verdicted"; "Every arm fails closed, so only the list is incomplete" · r3: "Unchanged pre-existing arms were checked only for presence"; "The new bare-`.git` exception (`:759`) is not in the 'anything but a plain directory' clause either. It is stated inline instead."

Arms this branch added that the list does not name:
- the parser failing on a blob (sed, python3, awk, the work bound, the print budget, a relative home): `out="$(git cat-file blob "$MAIN_SHA:$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d")" || { IMPORTED_MAIN=error; return 1; }` (`:726`);
- `import_home || return 1` (`:720`);
- the walk-wide budget (`:748`);
- the per-file lower (`i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }`, `:750`).

"a blob cannot be read" covers only `git cat-file`. The imported_names header (Claim 18) names "the parser", and this one should too.

**Evidence:** `scripts/lib/dev-cycle-read.sh:680-766`, `docs/reviews/override-log.md` (rows 2026-10-06 "main_imports' header ..." and "Closes this unit's three ... rows")

---

## Claim 43: main_imports: "One lower per file, not per candidate, as in imported_names." (IMPORTED_MAIN unchanged by the hoist)

**Location:** `scripts/lib/dev-cycle-read.sh:748-750`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the set of lower-cased names recorded, compared with main's per-line form. It does not cover the new failure arm, which is a behaviour change by design (fail closed).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1 (executed): a copy with the old per-candidate append restored gives the same IMPORTED_MAIN in the clone (md5 `4819d72f4484152328be579972cccc70` both); "does not establish other repos" · r2: "It does not establish timing"

Main appended `IMPORTED_MAIN+="$(lower "$p")"$'\n'` for every non-empty line, before the `seen` check. The branch appends `i="$(lower "$out")"; IMPORTED_MAIN+="$i"$'\n'`. `tr` is bytewise and `out` holds no empty lines: awk prints only names longer than the root prefix (`:559`), and the symlink arm rejects empty text (`:731`). So the recorded `\n`-delimited set is the same. All main-walk tests passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:744-751`, `git show main:scripts/lib/dev-cycle-read.sh` (the old line `IMPORTED_MAIN+="$(lower "$p")"$'\n'`), /tmp/u2a3bfcfin-10T4/logs/hoist.txt

---

## Claim 44: main_imports: "A .git component itself (a prefix candidate from @.gitignore, or a nested repository's) is a checkout file or directory git never stores. Files under it are not skipped: they fail below, since main lacks them."

**Location:** `scripts/lib/dev-cycle-read.sh:756-759`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip and what happens to paths under `.git`; does not establish Claude Code's reading of a worktree's `.git` file.
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "The nested half matters for a nested linked worktree (Claim 44)" (merged Claim 70) · r2+r3: an absent name under `.git` is recorded as imported and not walked, "which is harmless because it has no imports to hide" · r2: "does not establish U2a3c's general prefix-meets-checkout-file rule (routed)" · r3: "does not establish what Claude Code does with a `.git/` import"; widening the skip to `.git/*` fails test 39 (r2, r3)

The skip is `[[ "$p" != .git && "$p" != */.git ]] || continue`. A path under `.git` fails only when the checkout holds it as something other than a plain directory (`:763`), not because main lacks it. Executed: `@.git/none.md` (missing) and `@.git/info` (a directory) leave the main walk `ok`, both recorded as imported, while an existing `.git/notes.md` fails it (test `:628`). Precise: "they fail below when the checkout holds them as a file".

**Evidence:** `scripts/lib/dev-cycle-read.sh:755-763`, /tmp/u2a3bfcfin-10T4/logs/git-under.txt, `test/scripts/build-loop-check.bats:628-636`, /tmp/u2a3bfcfin-Q1w0-tmp/a3.log

---

## Claim 45: main_imports: "pok holds parents already checked: a token's prefixes share them, so the loop stops at the first."

**Location:** `scripts/lib/dev-cycle-read.sh:761-762`
**Type:** Performance / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that stopping at a checked parent skips only parents already checked, and the time effect; the memo has no behavioral test (override row 2026-10-07, equivalent).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: a 2,820-byte `a/` token takes 14.23 s at 98e3b1df and 1.01 s at HEAD (`deep.log`) · r3: the no_pok mutant survives (0 failures), as the commit message and override row say (time only); "does not cover the 16.6 s → 1.0 s timing"

When `c` was first added to `pok`, that loop continued through all of `c`'s ancestors unless it returned 1, so every ancestor of a memoized `c` was checked. Timing (executed): a 2,824-byte deep token gave main walk `ok` in 0.98 s at e1654266 and 12.64 s with the memo removed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:761-762`, /tmp/u2a3bfcfin-10T4/logs/timings.txt, /tmp/u2a3bfcfin-Q1w0-tmp/deep.log

---

## Claim 46: isimported: "A failed walk, a failed lower of $2, or a walk name that is neither answers imported (0) ...; a caller that words a failed walk runs the walk first (imported_names or main_imports, under if)."

**Location:** `scripts/lib/dev-cycle-read.sh:767-781`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers isimported's three fail-closed arms; need_root exits first.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: check_fix runs `imported_names` before `isimported tree` (`scripts/dev-cycle.sh:181-183`)

`lp="$(lower "$2")" || return 0`, `main_imports || return 0`, `imported_names || return 0`, `*) return 0`. Tests `:43`, `:448` (failed lower of the asked path) and `:408` (corrupt index) pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:772-781`, `test/scripts/build-loop-check.bats:43-51`, `:448-481`

---

## Claim 47: skills/dev-cycle/SKILL.md: "file an instruction file names after an `@`, read broadly; compared ignoring case) or `README.md`, and refuses every path when the import walk fails"

**Location:** `skills/dev-cycle/SKILL.md:72-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 13.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Matches check_fix (Claim 13) and its test.

**Evidence:** `skills/dev-cycle/SKILL.md:72-78`, `scripts/dev-cycle.sh:181-184`

---

## Claim 48: build-loop-check.bats helper and token-test comments: "imps ...: "walk: ok" or "walk: failed" (main_imports' or imported_names' return)"; "Docs/NB.MD and CLAUDE.md: isimported takes a path in any case."; "Without ROOT_REAL it stops (need_root) for any walk name, before answering."; "An untracked start: the tree walk reads it (the main walk fails closed on it until U2a3c)."

**Location:** `test/scripts/build-loop-check.bats:13-20,47-50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each comment against its test's assertions and the code.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=— · single-replicate detection
**Replicate annotations:** merge note: r2's compound also covered the Unicode-space comments, which are split out as Claim 49

`imps` prints `walk: ok` when `{ [[ "$w" == main ]] && main_imports; } || { [[ "$w" == tree ]] && imported_names; }` (`:19`). Each assertion passes (`suite.log`).

**Evidence:** `test/scripts/build-loop-check.bats:13-68`, /tmp/u2a3bfcfin-Q1w0-tmp/suite.log

---

## Claim 49: Test names "Unicode spaces end a token" and "every Unicode space JavaScript's \\s holds ends a token" (and the comment "Two NBSPs in one run: the token ends at the first ...")

**Location:** `test/scripts/build-loop-check.bats:26`, `:53`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what these tests detect; the property itself holds in the code (Claim 21).
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=—
**Replicate annotations:** r2 (Verified, compound): checked each comment against its test's assertions and the code; all assertions pass

Under the superset every prefix is a name, so `docs/uN.md` is imported whether or not the space ends the token, and `docs/other.md -` cannot tell the difference. Mutant `unispaces-not-blanked` (the UNI_SPACES sed expressions removed) passes both suites (/tmp/u2a3bfcfin-10T4/logs/mutants2.txt). The conversion now affects only precision (names running past the space). The tests pin that names before each space are read, not that the space ends them.

**Evidence:** `test/scripts/build-loop-check.bats:26-41`, `:53-70`, /tmp/u2a3bfcfin-10T4/logs/mutants2.txt

---

## Claim 50: superset test title: "... ~x is over-read, ~/ dropped; ..."

**Location:** `test/scripts/build-loop-check.bats:339`
**Type:** Staleness / Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "~/ dropped" phrase. "~x is over-read" is right: `~g.md` fails `reo`'s `^[a-zA-Z0-9._-]` branch.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Stale · r3=— · single-replicate detection
**Replicate annotations:** none

Since e1654266, a `~/` name is joined to the home directory, not dropped: `c = home "/" substr(c, 3)` (`scripts/lib/dev-cycle-read.sh:546`). The test's `want '~/x.md' -` (`:361`) passes because the fixture's HOME is `"$BATS_TEST_TMPDIR/home"` (`test/lib/build-loop-fixtures.bash:19`), so `@~/x.md` resolves outside the repo and is kept out. The title describes the pre-e1654266 rule. Precise version: "~/ read against HOME (outside the repo here)".

**Evidence:** `test/scripts/build-loop-check.bats:339,345,361`, `scripts/lib/dev-cycle-read.sh:542-546`, `test/lib/build-loop-fixtures.bash:19`

---

## Claim 51: Test comments on what Claude Code reads: "(Claude Code reads both)", "Claude Code 2.1.292 (harness) reads docs/abc.md ..., docs/cs.md ... and docs/dot.md; it never reads "docs/a.md x"", "Claude Code 2.1.292 reads none of docs/mail.md, docs/pre.md and docs/lead.md", "an escaped space and an absolute path inside the repo are imports"

**Location:** `test/scripts/build-loop-check.bats:340-352`, `:366-371`, `:529-530`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these shapes through the real 2.1.292 binary in a scratch repo, via one imported file. It does not cover the shapes on lines I did not reproduce (the NUL, `~g.md` and `e(f).md` cases).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: checked with the extracted Claude Code lexer and verbatim `reo` on each test's text (/tmp/u2a3bfcfin-10T4/h/check-cases.cjs) · r2 (static, Confidence Medium): "It does not run marked's lexer on these exact lines (done by the security fuzz reviews)"

Claude Code loaded `docs/abc.md`, `docs/cs.md`, `docs/dot.md` and `docs/aa.md` (the test's `docs/a.md`). It also loaded `docs/la.md`, `docs/lb.md`, `docs/ca.md`, `docs/cb.md`, `"docs/my notes.md"`, `docs/abs.md`, `docs/em.md`, `docs/q1.md` and `docs/q2.md`. It loaded none of span, mail, pre, fence, lead or `docs/aa.md x` (`logs/cc-shapes.txt`, captured 2026-10-07, exit 124 by design).

**Evidence:** logs/cc-shapes.txt (r3), `test/scripts/build-loop-check.bats:339-389`, `:528-543`, /tmp/u2a3bfcfin-10T4/h/check-cases.cjs

---

## Claim 52: heavy-input comment: "Seven 4200-byte runs after an @ pass the candidate-work bound (each prefix's length is charged; the sixth run trips it): the parser returns 1." (in the test named "... the work bound fails the walk")

**Location:** `test/scripts/build-loop-check.bats:383-388` (test at `:365`)
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which bound returns 1 at e1654266; does not establish the splice bound (its own test `:545`).
**Severity:** Medium (the emit work bound lost its only test)
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Verified
**Replicate annotations:** r3 (Verified): "Covers the arithmetic against `work += length(c); if (work > 50000000) exit 3`. The test passed with `rc=1`" (5 runs 44,110,500, 6 runs 52,932,600) · r2: the title's "the work bound fails the walk" also describes 98e3b1df; fix: "set `IMPORT_LEFT` high in that run, or reword the comment to the printed budget and add a work-bound case that sets `IMPORT_LEFT`"; "The comments test pins only splice's charge to it" · r2: "does not establish the work bound's value as a design" · r1 (Escalate): "Claim 33 (Medium): the emit work bound lost its only test in e1654266" · r2 (Out of scope): "whether emit's work bound is still needed now that IMPORT_LEFT bounds the same input (a performance/design question)"

The arithmetic holds for the work bound alone (5 runs 44,110,500, 6 runs 52,932,600 > 50,000,000). But e1654266 made awk default to `IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}"`, so the print budget trips first, in the first run. Executed on the test's input: with IMPORT_LEFT unset, rc 1 after **2,826** names; with `IMPORT_LEFT=1000000000`, the first 5 runs pass and the sixth fails. The test still passes, but it no longer exercises `work += length(c); if (work > 50000000) exit 3`: mutant `emit-work-bound-dropped` passes both suites. That bound still matters for candidates that are never printed (names outside the root, repeats). The test also checks the parser's return, not a walk.

```bash
# test/scripts/build-loop-check.bats:383-384
    # Seven 4200-byte runs after an @ pass the candidate-work bound (each prefix's
    # length is charged; the sixth run trips it): the parser returns 1.
```

**Evidence:** `test/scripts/build-loop-check.bats:365-389`, `scripts/lib/dev-cycle-read.sh:536`, `:631-632`; /tmp/u2a3bfcfin-10T4/logs/heavy-run.txt; /tmp/u2a3bfcfin-10T4/logs/mutants2.txt; /tmp/u2a3bfcfin-Q1w0-tmp/heavy.log; /tmp/u2a3bfcfin-Q1w0-tmp/mut-emitwork.log

---

## Claim 53: test names: "both walks fail once the parser has printed more than IMPORT_OUT_MAX bytes in all"; "An untracked sparse 300 MB file at the prefix "big""

**Location:** `test/scripts/build-loop-check.bats:400`, `:564-571`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these tests passing and their figures. "bytes" equals the comment's "characters" under the test's `LC_ALL=C`.
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** merge note: r3's compound also covered the 4194304-byte test (Claim 57) and the .git test (Claim 59)

All passed, and each test's mutant (no_cap) fails it.

**Evidence:** `test/scripts/build-loop-check.bats:400-406`, `:564-571`, logs/mutants.txt (r3)

---

## Claim 54: Every test named "FAILS at <rev>" fails at that revision

**Location:** `test/scripts/build-loop-check.bats:483`, `:495`, `:506`, `:517`, `:545`, `:618`; `test/scripts/dev-cycle.bats:1059`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD's tests run against the named revision's lib (HEAD's scripts and fixtures otherwise).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: the dev-cycle test prints `ok docs/notes.md` at be94c871, "so it fails on the import, not on wording" · r3: "does not establish that each fails only for its stated reason; I read the HTML-comment test's failure (`rc=124`) and the dev-cycle test's failed assertion"

With be94c871's lib, all five be94c871 tests fail (four `want` failures, and `rc=124` for the comments test), and the 98e3b1df test fails too. With 98e3b1df's lib, only the 98e3b1df test fails. The dev-cycle.bats test fails at be94c871 (`ok docs/notes.md`) and passes with main's lib ("as main did"). Commands: `bash fails-at.sh`, `bash fails-at-dc.sh`, cwd /tmp/u2a3bfcfin-10T4, exit 0, 2026-10-07T09:40Z.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/fails-at.txt, /tmp/u2a3bfcfin-10T4/logs/fails-at-dc.txt, /tmp/u2a3bfcfin-Q1w0-tmp/fails-be94.log, /tmp/u2a3bfcfin-Q1w0-tmp/fails-98.log

---

## Claim 55: comments test: "(FAILS at be94c871: L2 fact-check Claim 18b; about 10 s)"; "320,000 comments in one 2.24 MB line took 27 s with status 0 at be94c871"

**Location:** `test/scripts/build-loop-check.bats:545-551`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers runtimes at be94c871 and HEAD on this machine.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1 (Verified, Confidence Medium): "Read as the test's duration when it fails at be94c871 (its inner `timeout 10`); at e1654266 it takes 0.47 s" · r3: be94c871 measured 30.1 s with `rc=0`, "close to 27 s"; at e1654266 the parser returned in 0.205 s and the whole test ran in 0.465 s; precise version: "(FAILS at be94c871 after its 10 s timeout ...)"

Executed (`comments.log`): be94c871 takes 28.55 s with `rc=0`, so "27 s with status 0" holds. HEAD takes 0.2 s with `rc=1`. The title's "about 10 s" is the test's own `timeout 10`, which only be94c871 reaches (it fails there with `rc=124`, `fails-be94.log`). It is not the parser's runtime at HEAD. This was carried from L2-i2 Claim 30 with no disposition.

**Evidence:** `test/scripts/build-loop-check.bats:545-551`, /tmp/u2a3bfcfin-Q1w0-tmp/comments.log

---

## Claim 56: "import_targets prints 13 bytes for each file (a, a., a.m, a.md; 26 in all)" and "see @a.md prints a, a., a.m, a.md: 13 with the newlines between them"

**Location:** `test/scripts/build-loop-check.bats:601`, `:656`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts under the tests' LC_ALL=C.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

1+2+3+4 = 10 characters, plus 3 newlines between them, is 13, and two files make 26. Both tests pass, and IMPORT_LEFT 12 fails while 13 passes.

**Evidence:** `test/scripts/build-loop-check.bats:600-607`, `:655-659`

---

## Claim 57: "4194304 bytes in all, the last 14 an import with no newline after it."

**Location:** `test/scripts/build-loop-check.bats:609-616`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three figures.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3: the no_cap mutant fails it

`printf '\n@docs/late.md'` is 1+13 = 14 bytes, and the test asserts `wc -c` equals 4194304. The test passes.

**Evidence:** `test/scripts/build-loop-check.bats:600-616,655-660`, /tmp/u2a3bfcfin-Q1w0-tmp/suite.log

---

## Claim 58: "both walks read an @~/ import ... when HOME is a symlink" and the relative-home test

**Location:** `test/scripts/build-loop-check.bats:638-653`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 98e3b1df's code with e1654266's tests, and the mutants of each fix.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=— · single-replicate detection
**Replicate annotations:** none

At 98e3b1df the HOME, HOME-symlink and relative-home tests all fail (`fails-98.log`), and they pass at HEAD. Each fix's mutant fails its test: `no_homer` fails 40 and `no_rel_home_fail` fails 41 (`mutants.log`).

**Evidence:** /tmp/u2a3bfcfin-Q1w0-tmp/fails-98.log, /tmp/u2a3bfcfin-Q1w0-tmp/mutants.log

---

## Claim 59: the main walk fails closed on an import of a file under .git ("Only a bare .git component is skipped: .git/notes.md is a checkout file main lacks, so the walk fails rather than drop docs/t.md")

**Location:** `test/scripts/build-loop-check.bats:628-636`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 98e3b1df's code with e1654266's tests, and the mutants of each fix.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3: the gitskip_star mutant fails it

The .git comment matches `:759,763`. `git_skip_wide` fails 39 (`mutants.log`).

**Evidence:** /tmp/u2a3bfcfin-Q1w0-tmp/mutants.log, `scripts/lib/dev-cycle-read.sh:759`, `:763`

---

## Claim 60: dev-cycle.bats: "--check-fix words a failed import walk as one and refuses"; "A corrupt index: git ls-files fails"

**Location:** `test/scripts/dev-cycle.bats:1048-1057`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tests' claims against `reo` and check_fix.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

The tests pass in the 143/143 run.

**Evidence:** `test/scripts/dev-cycle.bats:1048-1080`, /tmp/u2a3bfcfin-Q1w0-tmp/suite.log

---

## Claim 61: "--check-fix refuses a doc imported through a name Claude Code decodes with U+FFFD"

**Location:** `test/scripts/dev-cycle.bats:1066`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test and its mutant.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

It passes at e1654266. Mutant `gate-always-ok` (never decode) fails it (test 100).

**Evidence:** `test/scripts/dev-cycle.bats:1066-1071`, /tmp/u2a3bfcfin-10T4/logs/mutants.txt

---

## Claim 62: "Mail user@docs/email.md is no import for Claude Code, but the superset reads it."

**Location:** `test/scripts/dev-cycle.bats:1077`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code's regex and the test.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3: `user@docs/mail.md` was not loaded by the real binary (Claim 51's probe)

`(?:^|\s)@` needs a blank before the `@`. The test passes with `skip docs/email.md: an instruction file names it`.

**Evidence:** `test/scripts/dev-cycle.bats:1073-1086`, claude.exe offset 212107466

---

## Claim 63: commit messages: test counts "121/121" (be94c871), "130/130" (dd51e9a7), "133/133" (98e3b1df), "143/143" (e1654266)

**Location:** commit messages be94c871, dd51e9a7, 98e3b1df, e1654266
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `@test` count in the five suites at each commit (121, 130, 133, 143) and an executed pass at e1654266. It does not cover re-running the earlier commits.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: main has 115 · r2: by `bats --count` over the five suites

`git show <c>:<suite> | grep -c '^@test'`, summed over the five suites, gives 130 at dd51e9a7, 133 at 98e3b1df and 143 at e1654266 (121 at be94c871 per the scope line). At e1654266 the run gave 143/143 with exit 0.

**Evidence:** logs/suites-e1654266.txt (r3), /tmp/u2a3bfcfin-10T4/logs/suites.txt

---

## Claim 64: commit messages: "350", "486", "525", "679" changed code lines against main

**Location:** commit messages be94c871, dd51e9a7, 98e3b1df, e1654266
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Counts are added+deleted lines outside `docs/` in `git diff --numstat main...<c>`.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: 284+66 = 350, 413+73 = 486, 452+73 = 525, 603+76 = 679 (the plan's row-62 measure, `docs/working/plan-build-loop-handoff.md:266`) · r2: merge base f6fdda68

The lines are 350, 486, 525 and 679.

**Evidence:** `git diff --numstat main...<c> -- . ':!docs'`; `docs/working/plan-build-loop-handoff.md:266`

---

## Claim 65: e1654266: "--check-fix over 942 paths identical to main; interleaved, main 2.39-2.76 s, this branch 2.63-2.77 s."

**Location:** commit e1654266 message
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each figure re-run on this machine today. Timings vary with load.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound) · r3=Verified (compound)
**Replicate annotations:** r1 (Verified, Confidence Medium): "Covers verdict identity (re-run) and one timing pair; the timings are time-varying"; one run each: main 2.49 s, e1654266 2.74 s, inside the stated ranges · r3 (Verified, Confidence Medium): worktree main 2.36-2.54 s, branch 2.62-2.72 s; in /workspace main took 2.62-2.75 s and the branch 3.23-3.28 s: "The stated ranges hold for a checkout like the worktree, not for /workspace" · r2: "These are commit messages, so Accepted-immutable applies, as for the override row at `docs/reviews/override-log.md:429`"

- --check-fix is identical to main on all 948 paths now tracked; 942 was the count before this commit added its reports.
- Interleaved, three runs: main 2.43-2.59 s and this branch 2.78-2.82 s (`timing.log`), slightly above the stated 2.63-2.77.

**Evidence:** /tmp/u2a3bfcfin-Q1w0-tmp/timing.log, /tmp/u2a3bfcfin-10T4/logs/checkfix-compare.txt, logs/checkfix-worktree.txt (r3), logs/checkfix-workspace.txt (r3)

---

## Claim 66: e1654266: "python3 forks only when an awk ERE for well-formed UTF-8 rejects the text (42 of 45 walked files forked before, none changed)."

**Location:** commit e1654266 message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each figure re-run on this machine today. Timings vary with load.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound) · r3=Unverifiable (compound)
**Replicate annotations:** merge note: r2's compound Mostly accurate rests on the timing items (Claims 65, 67). On this item r2 wrote "This holds" · r1 (Verified): of 45 files the tree walk parses, 42 hold a byte above 0x7f and all 42 are valid UTF-8, and 3 are ASCII · r3 (Unverifiable, compound): not re-run; accepted-immutable under rubric L2-I2-C11

r2's evidence on this item: python3 forks in the clone's main walk, 42 at 98e3b1df and 0 at HEAD (`pycount.log`). This holds.

**Evidence:** /tmp/u2a3bfcfin-Q1w0-tmp/pycount.log, /tmp/u2a3bfcfin-10T4/logs/walk-output-size.txt, /tmp/u2a3bfcfin-10T4/count-nonascii.sh

---

## Claim 67: e1654266: "a long a/ run fails in 1.0 s (10.1 s before)" and "a 2,820-byte deep token takes 1.0 s (16.6 s)"

**Location:** commit e1654266 message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each figure re-run on this machine today. Timings vary with load.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound) · r3=Unverifiable (compound)
**Replicate annotations:** r1 (Verified, Confidence Medium): "the 'before' figures are time-varying (memo removed: 12.64 s here, not 16.6 s)"; 9,990-byte `a/` run 1.05 s (tree) and 1.02 s (main); 2,824-byte deep token 0.98 s · r3 (Unverifiable): "Not re-run. The exact inputs are in the performance reports, not in the commits. They are accepted-immutable under rubric L2-I2-C11"; to verify, "rerun the performance report's `a/` run and its 2,820-byte deep-token input against be94c871, 98e3b1df and e1654266 on one host" · r2: Accepted-immutable applies (override-log:429)

- A 9,990-byte `a/` run fails in 1.04 s (tree) and 1.06 s (main) at HEAD, against 8.16 s and 8.10 s at 98e3b1df (`deep.log`). The direction holds, but "10.1 s before" was 8.1 s here.
- The 2,820-byte token: 1.01 s, against 14.23 s.

**Evidence:** /tmp/u2a3bfcfin-Q1w0-tmp/deep.log, /tmp/u2a3bfcfin-10T4/logs/timings.txt, /tmp/u2a3bfcfin-10T4/timings.sh

---

## Claim 68: dd51e9a7: "3.4 s against main's 4.0 s"

**Location:** commit dd51e9a7 message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers only the existing disposition. I did not re-time dd51e9a7.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Unverifiable (compound) · r3=Unverifiable (compound)
**Replicate annotations:** r3: accepted-immutable under rubric L2-I2-C11; to verify, rerun the performance reports' inputs on one host

This is already recorded as Incorrect / Mostly accurate and Accepted-immutable (`docs/reviews/override-log.md:429`: "Commit dd51e9a7's "3.4 s against main's 4.0 s" does not reproduce ..."). There is no new evidence, so it is not re-raised.

**Evidence:** `docs/reviews/override-log.md:429`

---

## Claim 69: dd51e9a7 and 98e3b1df: "identical to main" over "941 tracked docs"

**Location:** commit messages dd51e9a7, 98e3b1df
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers only the existing disposition. I did not re-time dd51e9a7.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Unverifiable (compound) · r3=Verified (compound)
**Replicate annotations:** r3 (Verified, compound with Claim 65; Confidence Medium): "It does not cover the earlier commits' 'identical' lines, which were not re-run"

Path counts by tree: dd51e9a7 has 941 and 98e3b1df has 942 (`git ls-tree`, r2's session). The "identical" result at those commits was not re-run by any replicate.

**Evidence:** `docs/reviews/override-log.md:429`

---

## Claim 70: e1654266: "Mutants: each fix's mutant fails a test except the parent memo and the LC_ALL=C guard (time only and equivalent here; override rows)." (and rubric L2-I2-C1: "the gate mutant fails")

**Location:** commit e1654266 message; `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3b.md:25`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 17 mutants of e1654266's fixes run against build-loop-check.bats and dev-cycle.bats; does not establish mutants of earlier commits.
**Severity:** Low (immutable message; the substance is an untested fail-closed arm)
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Verified · r3=Mostly accurate (compound)
**Replicate annotations:** r2 (Verified, Confidence Medium): its mutants (gate, IMPORT_LEFT stop, homer, the .git skip widened, relative-home exit, parent memo) behaved as stated; "It does not cover the empty-HOME reading (Claim 27b), which is not a fix the commit names, or the LC_ALL=C guard"; `empty_home_kept` also fails none · r3: "The mutant that removes the UTF-8 gate itself, gate_always ... also survives with 0 failures. Like the memo, the gate is a time-only fix. 'The gate mutant fails' holds only for the gate_never mutant"; precise version "...except the parent memo, the UTF-8 gate's removal (time only) and the LC_ALL=C guard" · r1: also lists `gate-removed` (time only) among survivors

The same commit lists "Only a bare .git component, top level or nested (architecture F3), is skipped now". Mutant `git-skip-top-only` (`[[ "$p" != .git ]] || continue`, dropping the nested arm) passes both suites, and it is not equivalent. In a repo whose GEMINI.md names `@sub/.gitignore`, with `sub` a nested linked worktree (`sub/.git` a file), the main walk is `ok` at e1654266 and **fails** with the mutant. A nested repository with a `.git` directory passes either way. Other survivors:
- `gate-removed` (always fork python3; time only);
- `used-check-dropped-tree` (the bash budget check; unreachable, Claim 18);
- `tree-cap-4MiB` (equivalent);
- `home-key-never-cached` (time only).

The killed ones: `home-join-dropped`, `homer-dropped`, `rel-home-no-fail`, `git-skip-wide`, `git-skip-none`, `gate-always-ok`, `left-ignored`, `left-off-by-one`, `tree-cap-dropped`, `trim-dropped`, `empty-root-ok`. Command: `python3 -I mutants.py`, cwd /tmp/u2a3bfcfin-10T4, exit 0, 2026-10-07T09:28:31Z.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/mutants.txt, /tmp/u2a3bfcfin-10T4/logs/nested-git.txt, /tmp/u2a3bfcfin-10T4/mutants.py, `scripts/lib/dev-cycle-read.sh:759`

---

## Claim 71: 98e3b1df: "Its resolver transcription shows name.trim(): a leading escaped space is trimmed, now in emit."

**Location:** commit 98e3b1df message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Claude Code 2.1.292's handling of a name led by an escaped space; the rubric row L2-A2 was already relabelled (override row 2026-10-07), and the commit message is immutable.
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "Recorded for completeness; the existing override row covers the rubric premise, not this commit message"

Claude Code's filter rejects a name starting with a space before `Ye` trims (Claim 29), so `@\ docs/x.md` loads nothing. The trim only over-reads, as the code comment at `:537-538` now says.

**Evidence:** claude.exe offsets 212107466, 205304326; `scripts/lib/dev-cycle-read.sh:537-538`; `docs/reviews/override-log.md` (row 2026-10-07 "Rubric row L2-A2 ...")

---

## Claim 72: e1654266: "a ~/ name is a real import (Claude Code joins it to the home directory)"

**Location:** commit message e1654266
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a ~/ name under the session's real home. It does not cover a symlinked home, which Claude Code does not load (Claim 30).
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

With HOME=`/tmp/u2a3bfcfin-cc-OhOV`, Claude Code loaded `repo/c.md` from `@~/repo/c.md`. With HOME=`.../repo/sub`, it loaded `repo/sub/a.md` from `@~/a.md` (`logs/cc-home.txt`).

**Evidence:** logs/cc-home.txt (r3)

---

## Claim 73: e1654266: "(unset or empty: the passwd entry, as Node reads it)"

**Location:** commit message e1654266 (and rubric L2-I2-A1)
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Node 22.23.2's os.homedir for an empty HOME; does not change Claim 33 (the code matches Claude Code).
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect (compound) · r2=— · r3=Incorrect
**Replicate annotations:** r3: "The commit message cannot be changed; the comment can be fixed"

Node returns the empty string for an empty HOME: `HOME='' -> ""`, `unset -> "/home/node"` (`node -e 'console.log(JSON.stringify(require("os").homedir()))'`, Node v22.23.2, exit 0, 2026-10-07T09:47:18Z). Claude Code runs on Bun (a Bun single-file executable), whose `os.homedir` falls back to passwd for an empty HOME (Claim 33). A reader checking the rule against Node would conclude the code is wrong for `HOME=`. The precise wording is "as Claude Code's runtime (Bun) reads it".

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/node-homedir.txt, logs/cc-home.txt (r3)

---

## Escalations

1. **Out-of-repo instruction files are a fail-open class outside both walks' start sets.** An ancestor directory's CLAUDE.md and user or managed memory can import repo files that neither walk reads. No override row covers this. r1 also asks the orchestrator to decide whether it should block the merge or be routed, and asks whether "read broadly" is meant to cover only files in the repo.
   - Path: `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:474-478`, `:647`, `:699-719`
   - Raised by: r1 (Escalate; Out of scope; Questions)
   - Addressee: orchestrator (synthesis)
   - Merged claim: 7
2. **emit's work bound lost its only test in e1654266.** The heavy-run test now trips the print budget first, and the `emit-work-bound-dropped` mutant survives both suites.
   - Path: `test/scripts/build-loop-check.bats:383-388`, `scripts/lib/dev-cycle-read.sh:536`
   - Raised by: r1 (Escalate)
   - Addressee: orchestrator
   - Merged claim: 52
3. **Whether emit's work bound is still needed** now that IMPORT_LEFT bounds the same input. r2 calls this a performance/design question but names no critic.
   - Path: `scripts/lib/dev-cycle-read.sh:536`, `:563`
   - Raised by: r2 (Out of scope)
   - Addressee: orchestrator
   - Merged claim: 52
4. **Empty HOME (the only behavioural item r2 found).** A session with `HOME=""` resolves `~/` names differently from the walk if its runtime keeps an empty home. r2 says the superset's first exception "arguably" covers this. r2 asks whether an empty HOME should fail closed on a `~/` name, as a relative one does. r1 and r3 executed Claude Code (Bun) and found it takes the passwd entry, as the code does.
   - Path: `scripts/lib/dev-cycle-read.sh:599-600,606`
   - Raised by: r2 (Escalate: "none blocking", with this item; Questions)
   - Addressee: orchestrator
   - Merged claim: 34
5. **Bun's UTF-8 decoder is established only on 8 (r1) and 5 (r3) probed invalid sequences.** r2 could not run Bun.
   - Path: `scripts/lib/dev-cycle-read.sh:618-621`
   - Raised by: r1 (Out of scope), r2 (Unverifiable blocker)
   - Addressee: orchestrator
   - Merged claim: 37
6. **Whether U2b's root set should include relative re-entry into another checkout** (`@../wtB/docs/x.md`). r3 raised it only as a doc precision.
   - Path: `docs/working/plan-build-loop-handoff.md:279`, `scripts/lib/dev-cycle-read.sh:519-520`
   - Raised by: r3 (Out of scope)
   - Addressee: orchestrator (U2b design)
   - Merged claims: 12, 25
7. **Already-routed rows, noted as not re-raised:** the reader root set (U2b), and the main walk's capped blob read and phase-2 rules (U2a3c).
   - Path: `scripts/lib/dev-cycle-read.sh:667-669`, `:726`
   - Raised by: r2 (Out of scope)
   - Addressee: already routed (U2b, U2a3c override rows)
   - Merged claims: 41, 42

r3's Goal-Alignment `Escalate:` read "Nothing blocking ... The two Stale and two Incorrect items are wording", and it carried no item, so it adds no entry.

## Verdict stability

- **Total clusters (merged claim rows):** 73
- **Single-replicate rows:** 14 (Claims 4, 7, 8, 10, 22, 27, 38, 40, 48, 50, 53, 58, 71, 72), with no agreement measurable
- **Rows reported by two or three replicates:** 59
  - **All reporting replicates agreed:** 45
  - **Verdicts disagreed:** 14
    - Claim 12: r1=Verified · r2=Verified · r3=Mostly accurate
    - Claim 14: r1=Verified · r2=Mostly accurate · r3=Verified
    - Claim 17: r1=— · r2=Mostly accurate (compound) · r3=Verified
    - Claim 25: r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
    - Claim 35: r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
    - Claim 37: r1=Verified · r2=Unverifiable · r3=Verified
    - Claim 49: r1=Mostly accurate · r2=Verified (compound) · r3=—
    - Claim 52: r1=Stale · r2=Stale · r3=Verified
    - Claim 55: r1=Verified · r2=Mostly accurate · r3=Mostly accurate
    - Claim 65: r1=Verified · r2=Mostly accurate (compound) · r3=Verified (compound)
    - Claim 66: r1=Verified · r2=Mostly accurate (compound) · r3=Unverifiable (compound)
    - Claim 67: r1=Verified · r2=Mostly accurate (compound) · r3=Unverifiable (compound)
    - Claim 69: r1=— · r2=Unverifiable (compound) · r3=Verified (compound)
    - Claim 70: r1=Incorrect · r2=Verified · r3=Mostly accurate (compound)
- **Agreement rate:** 45 / 59 = **76.3%** over multi-replicate rows. Counting single-replicate rows as trivially agreed gives 59 / 73 = 80.8%.
- **Detection spread:** 14 of 73 rows (19%) were surfaced by one replicate only. Two of those are non-Verified findings that only one replicate raised: Claim 7 (Mostly accurate, Medium, r1) and Claim 71 (Incorrect, r1). Three more are Stale or Mostly accurate: Claims 4, 8 and 50.
- This run is below the 90% falsifier threshold, so k stays at 3.
