Commit: e1654266

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (feat/build-loop-u2a3b)
**Scope:** `main...e1654266` excluding docs/reviews (scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md) and the commit messages `main..e1654266` (be94c871 onward in detail)
**Checked:** 2026-10-07
**Total claims checked:** 47
**Summary:** 34 verified, 5 mostly accurate, 5 stale, 3 incorrect, 0 unverifiable
**Commit:** e1654266
**Replication:** k=3

Role: Stage 1 replicate r1 of the U2a3b loop 2 final confirming pass. Hallucination pattern log read (8 entries); no claim below matches a logged pattern.

Suites (executed): `TMPDIR=<fresh mktemp> timeout 1500 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`, cwd /workspace/.claude/wt-build-loop-u2a3b, 2026-10-07T09:09:25Z to 09:10:14Z, exit 0, **143/143 ok**. Log: /tmp/u2a3bfcfin-10T4/logs/suites.txt.

Claude Code oracle (executed): the installed 2.1.292 binary (`/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe`, a Bun executable). (a) Source read from the binary: `reo` (the import extractor), `ZMe`/`kOe`/`EF` (loader), `Ye` (resolver), `nH=4194304`. (b) Its marked `Lexer` (class `QM`) was extracted to /tmp/u2a3bfcfin-10T4/h/marked-ext.cjs and run under Node 22.23.2 with `reo` transcribed verbatim (harness /tmp/u2a3bfcfin-10T4/h/gen.cjs). (c) Headless probes: `claude -p hi --debug-file` with an isolated `CLAUDE_CONFIG_DIR` and HOME in a scratch project; the loader logs `[CLAUDE.md] skipping <resolved path>` for every import target that is a directory, which shows the path Claude Code resolved (script /tmp/u2a3bfcfin-10T4/probe-cc.sh; log /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt). The probes stop at "Not logged in" after memory loading; no network was used.

---

## Claim 1: "Imports through a symlinked file or directory, and absolute-path imports into the repo, print `ok`."

**Location:** `docs/working/known-issues-dev-cycle.md:17` (known issue A3)
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absolute-path half of A3 for `--check-fix`'s tree walk at e1654266; does not establish the symlinked-file and symlinked-directory halves (not re-tested).
**Severity:** Low
**Legibility-target:** for-author

The branch made the tree walk read absolute imports: `put` resolves a name that starts with `/` and keeps it when it lies below ROOT_REAL:

```awk
# scripts/lib/dev-cycle-read.sh:551, :559
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  if (index(out, pre) != 1 || length(out) <= length(pre)) return
```

The test `both walks read an absolute import into the repo however it is spelled` (`test/scripts/build-loop-check.bats:495`) runs `for w in tree main` and passes at e1654266 (suite run above), so `--check-fix` now refuses such a doc. The A3 row was not edited, while A5 and the lib comment both dropped "absolute imports" from their gaps in this diff. A3 should drop its absolute-path clause.

**Evidence:** `docs/working/known-issues-dev-cycle.md:17`, `scripts/lib/dev-cycle-read.sh:550-565`, `test/scripts/build-loop-check.bats:495-504`, /tmp/u2a3bfcfin-10T4/logs/suites.txt

---

## Claim 2: "Traced in Claude Code 2.1.292 ...: a symlinked instruction file's imports resolve from its target's directory (`path.resolve(dirname(realpath(importer)), name)`), as the walk does, and an `@` token's `..` after a directory link is resolved lexically, as the walk does."

**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Claude Code 2.1.292's loader and resolver as read from the installed binary, and main_imports' symlink arm; does not establish the tree walk (which drops symlinked starts, A2/A3).

The loader passes the importer's resolved path to the extractor: `let{resolvedPath:he,isSymlink:_e}=Y; ... await kOe(e,n,he,S)` (`EF`), `kOe` calls `ZMe(h,e,n,r)` with `r` = that real path, and `reo` resolves every name with `let Y=Ye(H,FT(n));` where `FT` is imported as `dirname as FT` from "path". `Ye` ends in `return Hn(x(i,o))` with `resolve as x` from "path" and `Hn` defined as `function Hn(t){return t}` in its chunk: so `path.resolve(dirname(realpath(importer)), name)`, lexical. main_imports reads a link's target at the target's own directory (paraphrased — no quote available because the flow spans the 120000 arm, `scripts/lib/dev-cycle-read.sh:727-743`, and the queue push at `:755` followed by `d` recomputed at `:724`).

**Evidence:** claude.exe offsets 212105067 (`EF`/`kOe`), 212107466 (`reo`), 205304326 (`Ye`), 203431908 (chunk exporting `Hn`); `scripts/lib/dev-cycle-read.sh:722-755`

---

## Claim 3: A5's "Not covered" list (start files under a symlinked directory or in a submodule or untracked nested repo, case-insensitive names, checkout conversions), now without "absolute imports"

**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5); mirrored in `scripts/lib/dev-cycle-read.sh:474-478` and plan F11 (`docs/working/plan-build-loop-handoff.md:126`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the list names every place Claude Code 2.1.292 loads instructions that import into the repo and that neither walk starts from; does not establish how often such files exist on the user's machines.
**Severity:** Medium (an undocumented fail-open class for the floor)
**Legibility-target:** for-author

Dropping absolute imports is right (Claim 1). The list omits instruction files **outside the repo** whose imports Claude Code follows into it. Executed: with a scratch repo `cc/proj` (cwd of the session) and a `CLAUDE.md` in its **parent** directory holding `@proj/docs/g and @./proj/docs/h`, Claude Code logged

```
[DEBUG] [CLAUDE.md] skipping /tmp/u2a3bfcfin-10T4/cc/proj/docs/g: not a regular file or exceeds 4194304 byte limit
[DEBUG] [CLAUDE.md] skipping /tmp/u2a3bfcfin-10T4/cc/proj/docs/h: not a regular file or exceeds 4194304 byte limit
```

so an ancestor directory's CLAUDE.md imports repo files. The user memory (`$CLAUDE_CONFIG_DIR/CLAUDE.md`, i.e. `~/.claude/CLAUDE.md`) is loaded too and its imports are followed (the same log shows its `@~/sub/dir` and `@~/.cargo` resolved). Neither walk starts outside ROOT_REAL: the tree walk's starts are `git ls-files` and `untracked_md` (`scripts/lib/dev-cycle-read.sh:647`), main's are main's tree (`:699-719`). Such an imported repo file reads as "not imported". The superset statement's exceptions (Claim 17) are about names in a file the walk reads, so they do not cover this; nothing in A5, F11 or the override log mentions ancestor or user-memory instruction files (`rg -i 'ancestor|user memory|\.claude/CLAUDE\.md'` over those files: no match on this subject). Run with an ancestor `AGENTS.md` instead, nothing was loaded (`dbg-anc.txt`), so the class is CLAUDE.md (and possibly `.claude/CLAUDE.md`) in ancestors, plus user and managed memory.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt (`== cc/dbg-anc2.txt`, `== cc/dbg-u-set.txt`), /tmp/u2a3bfcfin-10T4/probe-cc.sh, `scripts/lib/dev-cycle-read.sh:647`, `scripts/lib/dev-cycle-read.sh:699-719`

---

## Claim 4: "Its cost is false positives (none among this repo's tracked docs on 2026-10-06)."

**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-fix over every tracked `docs/*.md` and README.md of a clone at e1654266 on 2026-10-07; does not establish the main walk's precision or other repos.

`--check-fix` over 948 paths in a fresh clone at e1654266, with main's scripts and with e1654266's: verdicts identical, 14 `ok` each, and no path refused with "an instruction file names it" (skip reasons: 924 scope, 8 own files, 2 path form). Command: `bash /tmp/u2a3bfcfin-10T4/checkfix-compare.sh`, cwd the clone, exit 0, 2026-10-07T09:4x.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/checkfix-compare.txt, `scripts/dev-cycle.sh:181-184`

---

## Claim 5: "Each `@` token costs 3+ forks, and the `seen`/`queue` handling is quadratic."

**Location:** `docs/working/known-issues-dev-cycle.md:19` (C2)
**Type:** Performance / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-token fork claim against e1654266's tree walk; does not re-measure the seen/queue half.
**Severity:** Low
**Legibility-target:** for-author

The row predates this unit (not edited in the diff) but describes the parser the unit replaced. At e1654266 a file costs one sed, one awk, at most one gate awk and one python3, and one `lower` for all its candidates (`lp="$(lower "$out")"`, `scripts/lib/dev-cycle-read.sh:673`); per candidate only `inrepo_here` forks, and only for a candidate that is a file (`if [[ -f "$p" && ...`, `:676`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:19`, `scripts/lib/dev-cycle-read.sh:611-633`, `scripts/lib/dev-cycle-read.sh:664-678`

---

## Claim 6: "Gaps: known issue A5 (... checkout conversions (...), and three shapes untraced against Claude Code)."

**Location:** `docs/working/plan-build-loop-handoff.md:126` (F11)
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of untraced shapes F11 attributes to A5; does not establish the remaining shape's behavior.
**Severity:** Low
**Legibility-target:** for-author

This commit moved two of A5's three shapes to "Traced in Claude Code 2.1.292" and left one: A5 now reads "Untraced (no host probe yet): whether `@` references in `.claude/commands/` files load." (`docs/working/known-issues-dev-cycle.md:18`). F11 was edited in the same commit but still says "and three shapes untraced against Claude Code)". Claim 13 is the same drift in the lib.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 7: U2a3c bullet: "one capped and drained reader (4 MiB + 1, Claude Code's limit) ... (a bare `head` after `git cat-file` exits 141 under pipefail ...); ... no third path resolver (IMPORT_AWK's `put` and the symlink arm's `realpath -ms` are the two)"

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 141 status, the limit and the two resolvers at e1654266; does not establish the bullet's design recommendations.

Executed: `bash -c 'set -o pipefail; git cat-file blob <2.2 MB blob> | head -c 10 >/dev/null; echo $?'` printed `pipefail status: 141` (cwd the worktree, 2026-10-07). Claude Code's limit is `nH=4194304` with `if(s.totalBytes>nH)return{kind:"skipped"...}` (binary, `teo`), so reading 4 MiB + 1 detects an over-limit file. The two resolvers: `put` (`scripts/lib/dev-cycle-read.sh:550-565`) and `realpath -ms` (`:739`, `:742`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:550-565`, `scripts/lib/dev-cycle-read.sh:739-742`, claude.exe offset 212105067 (`nH=4194304`, `teo`)

---

## Claim 8: U2b bullet: "the parser's root and home are the gate's own, but a session in another checkout (`git worktree list`) or under another HOME reads absolute and `~/` names against its own"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser's single root and home; does not establish U2b's future design.

`IT_ROOT="${ROOT_REAL:-}" IT_HOME="$IMPORT_HOME"` (`scripts/lib/dev-cycle-read.sh:631`) is the only root and home the parser sees. Claude Code joins `~/` to its own process's home (probe: with `HOME=<scratch>/cc` the session resolved `@~/proj/docs/e` to `/tmp/u2a3bfcfin-10T4/cc/proj/docs/e`, `dbg-set` run).

**Evidence:** `scripts/lib/dev-cycle-read.sh:604-632`, /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt

---

## Claim 9: "a file an instruction file names after an @, read broadly; compared ignoring case) or README.md; "skip <path>: <reason>" otherwise, and for every path when the import walk fails."

**Location:** `scripts/dev-cycle.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix's arms at e1654266; does not establish the output when check_fix's own `tr` fails (override row, F3-C9).

Every arm of check_fix before `check_path` prints `skip`, and the walk runs before any `ok`:

```bash
# scripts/dev-cycle.sh:181-184
  elif ! imported_names; then
    echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"
  elif isimported tree "$lp"; then
    echo "skip $a: an instruction file names it after an @ (directly or through another import), so it may be read as instructions; file it instead"
```

Test `--check-fix words a failed import walk as one and refuses (U2a3b)` (`test/scripts/dev-cycle.bats:1048`) passes.

**Evidence:** `scripts/dev-cycle.sh:170-185`, `test/scripts/dev-cycle.bats:1048-1057`, /tmp/u2a3bfcfin-10T4/logs/suites.txt

---

## Claim 10: "The import walks also need python3 when an instruction file holds text that is not well-formed UTF-8; without it they fail closed."

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the python3 dependency of both walks; "instruction file" is read as any file the walks read (imported files included), which is when the gate runs.

python3 runs only after the gate rejects the text (`scripts/lib/dev-cycle-read.sh:622-623`), and its failure returns 1. Test `both walks fail closed when python3 fails on text holding a byte above 0x7f` (`test/scripts/build-loop-check.bats:573`) passes; a gate probe counted 0 python3 forks for valid UTF-8 and ASCII and 1 for `\xff` (/tmp/u2a3bfcfin-10T4/logs/gate-probe.txt).

**Evidence:** `scripts/lib/dev-cycle-read.sh:618-625`, `test/scripts/build-loop-check.bats:573-580`, /tmp/u2a3bfcfin-10T4/logs/gate-probe.txt

---

## Claim 11: "check_answer, brief_fields, tree_starts, imported_names and main_imports also set pipefail for themselves"

**Location:** `scripts/lib/dev-cycle-read.sh:14-15`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the five named functions; does not establish that no other function sets it.

`rg 'set -o pipefail'` finds `:325` (brief_fields), `:647` (tree_starts), `:649` (imported_names), `:693` (main_imports), `:869` (check_answer), each after `local -`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:325`, `:647`, `:649`, `:693`, `:869`

---

## Claim 12: "It returns 1, with IMPORTED set to "error", when the start listing (git ls-files, untracked_md, instruction_names), lower, a file read or the parser fails, or a start file's name holds a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:453-458` (imported_names)
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `return 1` in imported_names; does not establish callers' handling (Claim 9, Claim 30).
**Severity:** Low
**Legibility-target:** for-author

Every listed arm exists (`:653`, `:656`, `:657`, `:669`, `:673`). One arm is not listed: `import_home || return 1` (`:662`), added on this branch. The walk-wide budget arm, `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED=error; return 1; }` (`:671`), is in practice the parser's: awk stops at `IMPORT_LEFT` first (Claim 14), and a mutant deleting the bash check survives both suites (`used-check-dropped-tree`, /tmp/u2a3bfcfin-10T4/logs/mutants.txt). The precise list adds "import_home".

**Evidence:** `scripts/lib/dev-cycle-read.sh:648-679`, /tmp/u2a3bfcfin-10T4/logs/mutants.txt

---

## Claim 13: "Not covered (known issue A5): ... checkout conversions (A5), and three shapes A5 lists as untraced against Claude Code."

**Location:** `scripts/lib/dev-cycle-read.sh:474-478` (main_imports block)
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count; same drift as Claim 6.
**Severity:** Low
**Legibility-target:** for-author

The diff edited these lines (it removed "absolute imports,") but kept "three shapes A5 lists as untraced"; A5 now lists one (`whether @ references in .claude/commands/ files load`). Claim 3's omission applies here too.

**Evidence:** `scripts/lib/dev-cycle-read.sh:477-478`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 14: IMPORT_OUT_MAX: "Each walk fails once import_targets has printed more than this in all (characters, newlines between names counted; awk counts bytes, so it may stop first) ... A fresh clone's walks print about 2 KB, /workspace's about 6 KB. A caller that changes it clears IMPORTED_DONE and IMPORTED_MAIN_DONE before walking again."

**Location:** `scripts/lib/dev-cycle-read.sh:484-490`; with `:562-563`, `:628-632`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comparison, the unit, both figures and the equivalence of awk's count with `${#out}`; does not establish the figures for other checkouts.

`(( (used += ${#out}) <= IMPORT_OUT_MAX ))` fails on "more than"; `${#out}` counts characters in the caller's locale and includes the newlines between names (`$(...)` drops the last). awk counts the same way in bytes: `printed += length(out) + 1; if (printed - 1 > left) exit 3` (`:563`) with `IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}"` and `IMPORT_LEFT=$((IMPORT_OUT_MAX - used))` per file (`:669`, `:726`), so awk stops at or before the bash check; the boundary test `IMPORT_OUT_MAX bounds what the whole walk prints ... exactly the limit passes` and its off-by-one mutant agree (mutant `left-off-by-one` fails tests 36 and 42). Measured (wrapping import_targets to log `${#o}` per call, C locale): a fresh clone at e1654266 prints 2,014 in each walk (45 files); /workspace's tree walk prints 5,596 (80 files; its main walk fails closed on start files main lacks). The DONE caches are keyed on commit/root only (`:651`, `:696`), so a changed budget needs them cleared, as the comment says.

**Evidence:** `scripts/lib/dev-cycle-read.sh:484-490`, `:562-563`, `:628-632`, `:669-671`, `:726`, `:748`; /tmp/u2a3bfcfin-10T4/logs/walk-output-size.txt; /tmp/u2a3bfcfin-10T4/measure.sh; /tmp/u2a3bfcfin-10T4/logs/mutants.txt

---

## Claim 15: "UTF-8 spaces, which end an import token as a blank does ...: U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F, U+3000 and U+FEFF (Claude Code's token ends at JavaScript's \s)."

**Location:** `scripts/lib/dev-cycle-read.sh:491-496`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list against JavaScript's `\s` and Claude Code's regex; does not establish test coverage of the conversion (Claim 32).

Claude Code's extractor is `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` (binary, `reo`). JavaScript's `\s` non-ASCII members are exactly these 19 code points; `UNI_SPACES` holds 19 byte sequences matching them, and `import_targets` turns each into a blank (`for u in "${UNI_SPACES[@]}"; do s+=(-e "s/$u/ /g"); done`, `:614`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:491-496`, `:614`, claude.exe offset 212107466

---

## Claim 16: The superset rules: "Every @ in a line starts a candidate ...; each prefix of the run after it, up to the first blank (a NUL or a UNI_SPACES space counts as one), is a candidate name, with a backslash-escaped space read as a space. A line holding <!-- is also read with its closed HTML comments removed ..., and text holding a byte above 0x7f is also read decoded as Claude Code decodes it ... Each candidate is trimmed of spaces, made absolute ... and resolved lexically, .. stopping at / ..., kept only when it lies below ROOT_REAL ... A ~/ name is joined to this process's home (import_home), in its spelled and real forms."

**Location:** `scripts/lib/dev-cycle-read.sh:501-516`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that IMPORT_AWK/import_targets implement each stated rule and that the rules yield every name Claude Code 2.1.292's extractor yields from a file's text (Node's UTF-8 decoder in the fuzz, the real binary for U+FFFD); does not establish which files the walks read (Claim 3) or the decoding of Bun on inputs beyond the 8 probed sequences.

Each rule is in the code: `scan` starts at every `@` and calls `emit(name)` per character (`:566-578`); the escaped space is `if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ }` (`:573`); NUL and UNI_SPACES become blanks in sed (`:612-617`); `{ scan($0); if (index($0, "<!--")) scan(splice($0)) }` (`:592`); the decode is `:622-625`; trim, `~/` and `put` are `:539-560`.

Differential fuzz (executed): 7,000 generated byte documents (two runs, seeds 4242 and 777) through the extracted Claude Code lexer and verbatim `reo` (resolver transcribed for posix; the EP filter left out, which only enlarges Claude Code's set), against `import_targets sub` with `ROOT_REAL=/r`, `HOME=/r/hh`: **3,236 expected names, 0 misses, 0 parser failures**. Commands: `node gen.cjs 3000 4242 && bash run-parser.sh <lib> 3000`, `node gen2.cjs 4000 777 && bash run-parser.sh <lib> 4000`, cwd /tmp/u2a3bfcfin-10T4/h, exit 0, 2026-10-07T09:20Z. Harness sensitivity: main's lib misses 345 of 736 names on 1,000 of the same documents. The documented test cases (`build-loop-check.bats:339`, `:365`, `:528`) give the same names through the extracted lexer as their comments state (/tmp/u2a3bfcfin-10T4/h/check-cases.cjs). The real binary, given `@q/<k><invalid bytes>` for 8 invalid sequences (lone `\xff`, truncated 4-byte, surrogate, overlong 3- and 2-byte, past U+10FFFF, truncated 3-byte, overlong 4-byte), resolved all 8 to python3's `decode("utf-8","replace")` spellings, and `import_targets` yields all 8.

**Evidence:** `scripts/lib/dev-cycle-read.sh:534-633`; /tmp/u2a3bfcfin-10T4/logs/fuzz-1.txt, fuzz-2.txt, fuzz-main.txt; /tmp/u2a3bfcfin-10T4/h/gen.cjs; /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt (`== cc/dbg-dec2.txt`)

---

## Claim 17: "Known exceptions, where a session reading the file can import what these rules do not yield: a session whose home differs ..., a session in another checkout of the repo ..., names that differ only in case on a case-insensitive file system (docs/reviews/override-log.md line 350), Claude Code's approved external includes, and any further decoding it may add (an entity, a percent escape)."

**Location:** `scripts/lib/dev-cycle-read.sh:516-523`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers names in a file the walk reads, against Claude Code 2.1.292's extractor, resolver and loader: the five are real and no sixth name-level exception was found; does not cover files the walks never read (Claim 3: ancestor and user-memory instruction files), the tree walk's symlink gaps (A2/A3), or Bun-specific decoding beyond Claim 16's probe.

Real: `~/` uses the reading process's `os.homedir()` (`if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))`, `homedir as c`); in-project checks use the session's root (`if(!AD(Pe)&&!z)continue` in `EF`, so outside names load only as approved external includes); line 350 of the override log is the case-insensitive row. "Further decoding" is hedged ("may add"): the bundled marked returns `{type:"text",raw:n[0],text:n[0],...}` (no entity decoding), and `Hn` is the identity (no Unicode normalization). Searched for other misses, none found: marked's lex only rewrites `\r\n|\r` to `\n` (`e=e.replace(_r.carriageReturn,...)`); escape, code, codespan and non-comment html tokens are skipped, which narrows; frontmatter is stripped, which narrows; a NUL in a name makes `Ye` throw `NullBytePathError`, so the file loads nothing; imports nest at most `I9n=5` deep; names cannot be relative-to-cwd unless HOME is relative, which the parser fails on (probe: `HOME=rel` resolved `@~/proj/docs/e` to `rel/proj/docs/e`). A symlinked spelling of the repo as the session's cwd did not load an absolute name spelled through the link (`dbg-link`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:516-525`, `docs/reviews/override-log.md:350`, claude.exe offsets 205304326, 210336074, 212105067, 212107466; /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt

---

## Claim 18: "It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is empty, when a ~/ name appears and the home is not absolute, or when the candidates and comment splices run past a work bound or print past IMPORT_LEFT"

**Location:** `scripts/lib/dev-cycle-read.sh:526-529`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every failure arm of import_targets and that none returns 0; the gate awk's failure is by design a fall-through to decoding (Claim 21), not a failure arm.

Arms: `import_home || return 1` (`:613`), sed `|| return 1` (`:617`), python3 `|| return 1` (`:623`), the final awk `|| return 1` (`:632`) covering `exit 2` (empty root, `:590`), `exit 3` (work bound `:536`, `:582`; print budget `:563`) and `exit 4` (relative home, `:544`). Tests assert status 1 for an empty ROOT_REAL (`:582`), a relative home (`:648`), the print budget (`:655`), the splice bound (`:545`), python3 failing (`:573`), sed failing (`:448`). No arm returns 0 on a failed command: the only unguarded command is the gate awk, whose failure runs python3.

**Evidence:** `scripts/lib/dev-cycle-read.sh:611-633`; `test/scripts/build-loop-check.bats:448`, `:545`, `:573`, `:582`, `:648`, `:655`; /tmp/u2a3bfcfin-10T4/logs/suites.txt

---

## Claim 19: "Claude Code trims the name; it rejects a name led by a space first, so trimming one only over-reads."

**Location:** `scripts/lib/dev-cycle-read.sh:537-538`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the leading-space case in Claude Code 2.1.292's extractor and resolver; a trailing escaped space is trimmed by both and the prefix is yielded anyway.

`reo` filters before resolving: `H.startsWith("./")||H.startsWith("~/")||H.startsWith("/")&&H!=="/"||!H.startsWith("@")&&!H.match(/^[#%^&*()]+/)&&H.match(/^[a-zA-Z0-9._-]/)`, which a name starting with a space fails; only then `Ye` runs `let n=e.trim();`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:537-540`, claude.exe offsets 212107466, 205304326

---

## Claim 20: "~/ joins the home directory (Claude Code: path.join(os.homedir(), rest)), also spelled through its real path, since ROOT_REAL is real."

**Location:** `scripts/lib/dev-cycle-read.sh:541-547`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the join and both spellings; does not establish other homes (Claim 17).

Binary: `if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))` with `join as b` and `homedir as c`. Code: `if (homer != home) put(homer "/" substr(c, 3))` then `c = home "/" substr(c, 3)`. Tests `:618` and `:638` (HOME a symlink) pass; mutants `home-join-dropped` and `homer-dropped` each fail them.

**Evidence:** `scripts/lib/dev-cycle-read.sh:541-547`, `test/scripts/build-loop-check.bats:618-646`, /tmp/u2a3bfcfin-10T4/logs/mutants.txt

---

## Claim 21: UTF8_OK: "it agreed with python3's decoding on 20,013 cases (U2a3b L2-i2 performance F1). Only text it rejects forks python3, since well-formed text decodes to itself." (and, from the caller's brief, a failing gate fails toward decoding)

**Location:** `scripts/lib/dev-cycle-read.sh:593-597`, `:622`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers agreement of the ERE (mawk, C locale) with python3's strict decode, the fork condition and the failure direction; the exact 20,013 count is the earlier critic's and was not reproduced.

Fresh run: 50,000 cases (30,000 biased to edge bytes, 20,000 mostly valid code points with one byte flipped in half), 0 disagreements between `$0 ~ ok` and `bytes.decode("utf-8")` succeeding. The call is `[[ "$toks" == *[$'\x80'-$'\xff']* ]] && ! printf ... | env LC_ALL=C awk -v ok="$UTF8_OK" '$0 !~ ok { exit 1 }'`: python3 runs only when the gate exits non-zero, so a failing gate decodes. Executed with an awk shim that fails only for `-v`: valid UTF-8 then forked python3 once and still printed `docs/é.md`, rc 0; with the real awk, 0 forks for valid UTF-8 and ASCII, 1 for `\xff`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:593-597`, `:622-625`; /tmp/u2a3bfcfin-10T4/logs/utf8-gate-fuzz.txt; /tmp/u2a3bfcfin-10T4/logs/gate-probe.txt; /tmp/u2a3bfcfin-10T4/gate-probe.sh

---

## Claim 22a: "import_home: IMPORT_HOME and IMPORT_HOMER (its real path) for the parser's ~/ names, from HOME ... (unset or empty: the passwd entry)."

**Location:** `scripts/lib/dev-cycle-read.sh:598-610`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what Claude Code 2.1.292 (Bun) does with unset and empty HOME, and import_home's matching rule; Claim 22b covers the Node attribution.

`h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}"` takes the passwd entry for unset or empty HOME. Claude Code does the same: with `HOME=` and with HOME unset, the user-memory import `@~/.cargo` resolved to `/home/node/.cargo` (the passwd home, `node:x:1000:1000::/home/node:/bin/bash`); with `HOME=<scratch>/fakehome` it resolved under that directory.

**Evidence:** `scripts/lib/dev-cycle-read.sh:604-610`; /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt (`dbg-u-set`, `dbg-u-empty`, `dbg-u-unset`)

## Claim 22b: "from HOME as Node's os.homedir reads it" (also commit e1654266: "unset or empty: the passwd entry, as Node reads it")

**Location:** `scripts/lib/dev-cycle-read.sh:599-600`; commit e1654266 message
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Node 22.23.2's os.homedir for an empty HOME; does not change Claim 22a (the code matches Claude Code).
**Severity:** Low
**Legibility-target:** for-author

Node returns the empty string for an empty HOME: `HOME='' -> ""`, `unset -> "/home/node"` (`node -e 'console.log(JSON.stringify(require("os").homedir()))'`, Node v22.23.2, exit 0, 2026-10-07T09:47:18Z). Claude Code runs on Bun (a Bun single-file executable), whose `os.homedir` falls back to passwd for an empty HOME (Claim 22a). A reader checking the rule against Node would conclude the code is wrong for `HOME=`. The precise wording is "as Claude Code's runtime (Bun) reads it".

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/node-homedir.txt, `scripts/lib/dev-cycle-read.sh:599-600`

## Claim 22c: "A walk calls it once, so the parser's $(...) calls inherit it; it recomputes only when HOME changes. A relative or empty home is kept, and the parser fails on a ~/ name then."

**Location:** `scripts/lib/dev-cycle-read.sh:600-602`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache key and the failure; "recomputes" is the realpath and assignments (with HOME empty or unset, getent still runs on each call before the key check).

`[[ "$IMPORT_HOME_KEY" != "x$h" ]] || return 0` returns before `realpath` when the home is unchanged; both walks call `import_home` before their loops (`:662`, `:720`). A relative home keeps `IMPORT_HOMER="${hr:-$h}"` relative, and `if (substr(home, 1, 1) != "/") exit 4` fails a `~/` name; test `:648` prints `plain=0` and `tilde=1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:604-610`, `:544`, `test/scripts/build-loop-check.bats:648-653`

---

## Claim 23: "(python3's "replace" decoding matched Claude Code's byte for byte: U2a3b L2 security F1)"

**Location:** `scripts/lib/dev-cycle-read.sh:618-621`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 8 sequences probed in the real binary and 20,000 random sequences against Node's decoder; does not establish Bun's decoder on every input.

Claude Code reads with `Buffer.from(...).toString("utf8")` (binary, `teo`). The real binary resolved 8 of 8 invalid sequences to python3's replace spelling (Claim 16); python3 and Node's Buffer agreed on 20,000 random edge-byte strings (0 disagreements).

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/claude-code-probes.txt (`dbg-dec2`), /tmp/u2a3bfcfin-10T4/logs/utf8-gate-fuzz.txt

---

## Claim 24: "A pipe, not a here-string ...", "dir, root and home go through the environment: awk -v would read backslash escapes in them. IMPORT_LEFT, set by a walk, is what its IMPORT_OUT_MAX budget has left, so awk stops there rather than after."

**Location:** `scripts/lib/dev-cycle-read.sh:626-632`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three stated reasons via their tests and mutants.

Tests pass: a 70 KB file under `ulimit -f 0` still yields `docs/big.md` (`:408`); a directory named `docs/a\tb` resolves literally (`:506`, FAILS at be94c871); IMPORT_LEFT 12 fails and 13 passes (`:655`). Mutant `left-ignored` fails test 42.

**Evidence:** `scripts/lib/dev-cycle-read.sh:626-632`, `test/scripts/build-loop-check.bats:408-446`, `:506-515`, `:655-659`, /tmp/u2a3bfcfin-10T4/logs/mutants.txt

---

## Claim 25: "Claude Code skips a file over 4 MiB, so reading only its start over-reads at worst, and a huge file a prefix candidate names cannot stall the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:667-669`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk's read; the main walk still reads blobs whole (override row 2026-10-07, routed to U2a3c).

Binary: `nH=4194304`, `if(s.totalBytes>nH)return{kind:"skipped",isDirectory:!1}`, and the logged message `exceeds ${nH} byte limit`. Code: `head -c 4194305 -- "$f"`. Tests `:564` (sparse 300 MB under a 20 s timeout) and `:609` (exactly 4,194,304 bytes, import in the last 14) pass; mutant `tree-cap-dropped` fails `:564`. Mutant `tree-cap-4MiB` (`head -c 4194304`) survives; it is equivalent for imports (reading 4 MiB of an over-limit file only over-reads less).

**Evidence:** `scripts/lib/dev-cycle-read.sh:667-669`, `test/scripts/build-loop-check.bats:564-571`, `:609-616`, claude.exe offset 212105067, /tmp/u2a3bfcfin-10T4/logs/mutants.txt

---

## Claim 26: main_imports' failure list: "returns 1, with IMPORTED_MAIN set to "error", ... when main is not found by name, ... a blob cannot be read, symlink text ..., or an imported path main lacks lies under a directory main stores as a symlink or gitlink or exists in the checkout as anything but a plain directory below the root"

**Location:** `scripts/lib/dev-cycle-read.sh:680-691`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list against main_imports' `return 1` arms at e1654266; the override log's 2026-10-06 row (routed to U2a3, closed "Fixed (on main)") covered an earlier version of this gap.
**Severity:** Low
**Legibility-target:** for-author

Arms this branch added that the list does not name: the parser failing on a blob (sed, python3, awk, the work bound, the print budget, a relative home: `out="$(git cat-file blob "$MAIN_SHA:$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d")" || { IMPORTED_MAIN=error; return 1; }`, `:726`), `import_home || return 1` (`:720`), the walk-wide budget (`:748`) and the per-file lower (`i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }`, `:750`). "a blob cannot be read" covers only `git cat-file`. The imported_names header (Claim 12) names "the parser"; this one should too.

**Evidence:** `scripts/lib/dev-cycle-read.sh:680-766`, `docs/reviews/override-log.md` (rows 2026-10-06 "main_imports' header ..." and "Closes this unit's three ... rows")

---

## Claim 27: "One lower per file, not per candidate, as in imported_names." (the hoist; IMPORTED_MAIN unchanged by it)

**Location:** `scripts/lib/dev-cycle-read.sh:749-750`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers IMPORTED_MAIN's content in a clone at e1654266; does not establish other repos (the reasoning below does).

A copy with the old per-candidate append restored (`IMPORTED_MAIN+="$(lower "$p")"$'\n'` inside the loop after `[[ -n "$p" ]] || continue`) gives the same IMPORTED_MAIN as e1654266 in the clone: md5 `4819d72f4484152328be579972cccc70` both. awk prints each name once per file and never an empty line, so the whole-output append holds the same names in the same order.

**Evidence:** `scripts/lib/dev-cycle-read.sh:747-754`, /tmp/u2a3bfcfin-10T4/logs/hoist.txt

---

## Claim 28: "A .git component itself (a prefix candidate from @.gitignore, or a nested repository's) is a checkout file or directory git never stores. Files under it are not skipped: they fail below, since main lacks them."

**Location:** `scripts/lib/dev-cycle-read.sh:756-759`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip and what happens to paths under `.git`; does not establish Claude Code's reading of a worktree's `.git` file.
**Severity:** Low
**Legibility-target:** for-author

The skip is `[[ "$p" != .git && "$p" != */.git ]] || continue`. A path under `.git` fails only when the checkout holds it as something other than a plain directory (`:763`), not because main lacks it: executed, `@.git/none.md` (missing) and `@.git/info` (a directory) leave the main walk `ok`, both recorded as imported; an existing `.git/notes.md` fails it (test `:628`). Precise: "they fail below when the checkout holds them as a file". The nested half matters for a nested linked worktree (Claim 44).

**Evidence:** `scripts/lib/dev-cycle-read.sh:755-763`, /tmp/u2a3bfcfin-10T4/logs/git-under.txt, `test/scripts/build-loop-check.bats:628-636`

---

## Claim 29: "pok holds parents already checked: a token's prefixes share them, so the loop stops at the first."

**Location:** `scripts/lib/dev-cycle-read.sh:761-762`
**Type:** Performance / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that stopping at a checked parent skips only parents already checked, and the time effect; the memo has no behavioral test (override row 2026-10-07, equivalent).

When `c` was first added to `pok`, that loop continued through all of `c`'s ancestors unless it returned 1, so every ancestor of a memoized `c` was checked. Timing (executed): a 2,824-byte deep token, main walk `ok` in 0.98 s at e1654266 and 12.64 s with the memo removed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:761-762`, /tmp/u2a3bfcfin-10T4/logs/timings.txt

---

## Claim 30: "A failed walk, a failed lower of $2, or a walk name that is neither answers imported (0) ..."

**Location:** `scripts/lib/dev-cycle-read.sh:767-781`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers isimported's three fail-closed arms; need_root exits first.

`lp="$(lower "$2")" || return 0`, `main_imports || return 0`, `imported_names || return 0`, `*) return 0`. Tests `:43`, `:448` (failed lower of the asked path) and `:408` (corrupt index) pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:772-781`, `test/scripts/build-loop-check.bats:43-51`, `:448-481`

---

## Claim 31: "file an instruction file names after an `@`, read broadly; compared ignoring case) or `README.md`, and refuses every path when the import walk fails"

**Location:** `skills/dev-cycle/SKILL.md:75-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 9.

Matches check_fix (Claim 9) and its test.

**Evidence:** `skills/dev-cycle/SKILL.md:72-78`, `scripts/dev-cycle.sh:181-184`

---

## Claim 32: Test names "Unicode spaces end a token" and "every Unicode space JavaScript's \\s holds ends a token"

**Location:** `test/scripts/build-loop-check.bats:26`, `:53`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what these tests detect; the property itself holds in the code (Claim 15).
**Severity:** Low
**Legibility-target:** for-author

Under the superset every prefix is a name, so `docs/uN.md` is imported whether or not the space ends the token, and `docs/other.md -` cannot tell. Mutant `unispaces-not-blanked` (the UNI_SPACES sed expressions removed) passes both suites (/tmp/u2a3bfcfin-10T4/logs/mutants2.txt). The conversion now affects only precision (names running past the space). The tests pin that names before each space are read, not that the space ends them.

**Evidence:** `test/scripts/build-loop-check.bats:26-41`, `:53-70`, /tmp/u2a3bfcfin-10T4/logs/mutants2.txt

---

## Claim 33: "Seven 4200-byte runs after an @ pass the candidate-work bound (each prefix's length is charged; the sixth run trips it): the parser returns 1." (in the test named "... the work bound fails the walk")

**Location:** `test/scripts/build-loop-check.bats:383-388` (test at `:365`)
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which bound returns 1 at e1654266; does not establish the splice bound (its own test `:545`).
**Severity:** Medium (the emit work bound lost its only test)
**Legibility-target:** for-author

The arithmetic holds for the work bound alone (5 runs 44,110,500, 6 runs 52,932,600 > 50,000,000), but e1654266 made awk default `IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}"`, so the print budget trips first, in the first run. Executed on the test's input: with IMPORT_LEFT unset, rc 1 after **2,826** names; with `IMPORT_LEFT=1000000000`, the first 5 runs pass and 6 fail. The test still passes, but no longer exercises `work += length(c); if (work > 50000000) exit 3`: mutant `emit-work-bound-dropped` passes both suites. That bound still matters for candidates that are never printed (names outside the root, repeats). The test also checks the parser's return, not a walk.

```bash
# test/scripts/build-loop-check.bats:383-384
    # Seven 4200-byte runs after an @ pass the candidate-work bound (each prefix's
    # length is charged; the sixth run trips it): the parser returns 1.
```
(excerpt ends :384; the enclosing test continues to :389 — read)

**Evidence:** `test/scripts/build-loop-check.bats:365-389`, `scripts/lib/dev-cycle-read.sh:536`, `:631-632`; /tmp/u2a3bfcfin-10T4/logs/heavy-run.txt; /tmp/u2a3bfcfin-10T4/logs/mutants2.txt

---

## Claim 34: Every test named "FAILS at <rev>" fails at that revision

**Location:** `test/scripts/build-loop-check.bats:483`, `:495`, `:506`, `:517`, `:545`, `:618`; `test/scripts/dev-cycle.bats:1059`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD's tests run against the named revision's lib (HEAD's scripts and fixtures otherwise).

With be94c871's lib, all five be94c871 tests fail (four `want` failures, and `rc=124` for the comments test) and the 98e3b1df test fails; with 98e3b1df's lib, only the 98e3b1df test fails. The dev-cycle.bats test fails at be94c871 (`ok docs/notes.md`) and passes with main's lib ("as main did"). Commands: `bash fails-at.sh`, `bash fails-at-dc.sh`, cwd /tmp/u2a3bfcfin-10T4, exit 0, 2026-10-07T09:40Z.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/fails-at.txt, /tmp/u2a3bfcfin-10T4/logs/fails-at-dc.txt

---

## Claim 35: "(FAILS at be94c871: L2 fact-check Claim 18b; about 10 s)"

**Location:** `test/scripts/build-loop-check.bats:545`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Read as the test's duration when it fails at be94c871 (its inner `timeout 10`); at e1654266 it takes 0.47 s.

At be94c871 the test ends with `rc=124` (the 10 s timeout); at e1654266 the test runs in 0.47-0.48 s and the parser returns 1 in 0.23 s.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/fails-at.txt, /tmp/u2a3bfcfin-10T4/logs/time-comments.txt

---

## Claim 36: "import_targets prints 13 bytes for each file (a, a., a.m, a.md; 26 in all)" and "see @a.md prints a, a., a.m, a.md: 13 with the newlines between them"

**Location:** `test/scripts/build-loop-check.bats:601`, `:656`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts under the tests' LC_ALL=C.

1+2+3+4 = 10 characters plus 3 newlines between = 13; two files 26. Both tests pass, and IMPORT_LEFT 12 fails while 13 passes.

**Evidence:** `test/scripts/build-loop-check.bats:600-607`, `:655-659`

---

## Claim 37: Test comments on what Claude Code reads: "(Claude Code reads both)", "Claude Code 2.1.292 (harness) reads docs/abc.md ..., docs/cs.md ... and docs/dot.md; it never reads "docs/a.md x"", and "Claude Code 2.1.292 reads none of docs/mail.md, docs/pre.md and docs/lead.md"

**Location:** `test/scripts/build-loop-check.bats:347`, `:529-530`, `:366-369`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the extracted Claude Code lexer with verbatim `reo` on each test's text.

Results: links case `docs/ca.md, docs/cb.md, docs/la.md, docs/lb.md`; splice case `docs/a.md, docs/abc.md, docs/cs.md, docs/dot.md`; over-read case only `docs/pre.md.bak`; stray fence `docs/hidden.md`; `docs/secret.md`.

**Evidence:** /tmp/u2a3bfcfin-10T4/h/check-cases.cjs, `test/scripts/build-loop-check.bats:339-389`, `:528-543`

---

## Claim 38: "--check-fix refuses a doc imported through a name Claude Code decodes with U+FFFD"

**Location:** `test/scripts/dev-cycle.bats:1066`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test and its mutant.

Passes at e1654266; mutant `gate-always-ok` (never decode) fails it (test 100).

**Evidence:** `test/scripts/dev-cycle.bats:1066-1071`, /tmp/u2a3bfcfin-10T4/logs/mutants.txt

---

## Claim 39: "Mail user@docs/email.md is no import for Claude Code, but the superset reads it."

**Location:** `test/scripts/dev-cycle.bats:1077`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code's regex and the test.

`(?:^|\s)@` needs a blank before the `@`; the test passes with `skip docs/email.md: an instruction file names it`.

**Evidence:** `test/scripts/dev-cycle.bats:1073-1086`, claude.exe offset 212107466

---

## Claim 40: Commit-message counts: 121/121 (be94c871), 130/130 (dd51e9a7), 133/133 (98e3b1df), 143/143 (e1654266); 350, 486, 525, 679 changed code lines against main

**Location:** commit messages be94c871, dd51e9a7, 98e3b1df, e1654266
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Counts are `@test` lines in the five suites at each commit (143 also by running) and added+deleted lines outside `docs/` in `git diff --numstat main...<c>`.

Tests: 121, 130, 133, 143 (main 115). Lines: 350, 486, 525, 679.

**Evidence:** `git show <c>:<suite> | grep -c '^@test'`; `git diff --numstat main...<c> -- . ':!docs'`; /tmp/u2a3bfcfin-10T4/logs/suites.txt

---

## Claim 41: e1654266: "--check-fix over 942 paths identical to main; interleaved, main 2.39-2.76 s, this branch 2.63-2.77 s."

**Location:** commit e1654266 message
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers verdict identity (re-run) and one timing pair; the timings are time-varying.

948 paths in the clone at e1654266, 6 of them the review reports this commit added (942 before it); verdicts identical; one run each: main 2.49 s, e1654266 2.74 s, inside the stated ranges.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/checkfix-compare.txt

---

## Claim 42: e1654266: "python3 forks only when an awk ERE for well-formed UTF-8 rejects the text (42 of 45 walked files forked before, none changed)."

**Location:** commit e1654266 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the clone's tree walk at e1654266.

Of 45 files the tree walk parses, 42 hold a byte above 0x7f and all 42 are valid UTF-8; 3 are ASCII.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/walk-output-size.txt, /tmp/u2a3bfcfin-10T4/count-nonascii.sh

---

## Claim 43: e1654266: "a long a/ run fails in 1.0 s (10.1 s before)" and "a 2,820-byte deep token takes 1.0 s (16.6 s)"

**Location:** commit e1654266 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the e1654266 figures; the "before" figures are time-varying (memo removed: 12.64 s here, not 16.6 s).

A 9,990-byte `a/` run: tree walk failed in 1.05 s, main walk in 1.02 s; a 2,824-byte deep token: main walk ok in 0.98 s.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/timings.txt, /tmp/u2a3bfcfin-10T4/timings.sh

---

## Claim 44: e1654266: "Mutants: each fix's mutant fails a test except the parent memo and the LC_ALL=C guard (time only and equivalent here; override rows)."

**Location:** commit e1654266 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 17 mutants of e1654266's fixes run against build-loop-check.bats and dev-cycle.bats; does not establish mutants of earlier commits.
**Severity:** Low (immutable message; the substance is an untested fail-closed arm)
**Legibility-target:** for-author

The same commit lists "Only a bare .git component, top level or nested (architecture F3), is skipped now". Mutant `git-skip-top-only` (`[[ "$p" != .git ]] || continue`, dropping the nested arm) passes both suites, and it is not equivalent: in a repo whose GEMINI.md names `@sub/.gitignore` with `sub` a nested linked worktree (`sub/.git` a file), the main walk is `ok` at e1654266 and **fails** with the mutant (a nested repository with a `.git` directory passes either way). Other survivors: `gate-removed` (always fork python3; time only), `used-check-dropped-tree` (the bash budget check; unreachable, Claim 12), `tree-cap-4MiB` (equivalent), `home-key-never-cached` (time only). The killed ones: `home-join-dropped`, `homer-dropped`, `rel-home-no-fail`, `git-skip-wide`, `git-skip-none`, `gate-always-ok`, `left-ignored`, `left-off-by-one`, `tree-cap-dropped`, `trim-dropped`, `empty-root-ok`. Command: `python3 -I mutants.py`, cwd /tmp/u2a3bfcfin-10T4, exit 0, 2026-10-07T09:28:31Z.

**Evidence:** /tmp/u2a3bfcfin-10T4/logs/mutants.txt, /tmp/u2a3bfcfin-10T4/logs/nested-git.txt, /tmp/u2a3bfcfin-10T4/mutants.py, `scripts/lib/dev-cycle-read.sh:759`

---

## Claim 45: 98e3b1df: "Its resolver transcription shows name.trim(): a leading escaped space is trimmed, now in emit."

**Location:** commit 98e3b1df message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Claude Code 2.1.292's handling of a name led by an escaped space; the rubric row L2-A2 was already relabelled (override row 2026-10-07), and the commit message is immutable.
**Severity:** Low
**Legibility-target:** for-author

Claude Code's filter rejects a name starting with a space before `Ye` trims (Claim 19), so `@\ docs/x.md` loads nothing; the trim only over-reads, as the code comment at `:537-538` now says. Recorded for completeness; the existing override row covers the rubric premise, not this commit message.

**Evidence:** claude.exe offsets 212107466, 205304326; `scripts/lib/dev-cycle-read.sh:537-538`; `docs/reviews/override-log.md` (row 2026-10-07 "Rubric row L2-A2 ...")

---

## Claims Requiring Attention

### Incorrect
- **Claim 22b** (`scripts/lib/dev-cycle-read.sh:599-600`; commit e1654266): Node's os.homedir returns "" for an empty HOME; the passwd fallback is Bun's (Claude Code's runtime). Say "as Claude Code (Bun) reads it".
- **Claim 44** (commit e1654266): the nested `*/.git` arm's mutant survives and is not equivalent (a nested linked worktree fails the main walk without it); no test covers it.
- **Claim 45** (commit 98e3b1df): Claude Code rejects a name led by an escaped space before trimming; already relabelled in the rubric.

### Stale
- **Claim 1** (`docs/working/known-issues-dev-cycle.md:17`): A3 still says absolute imports into the repo print `ok`; the tree walk now refuses them.
- **Claim 5** (`docs/working/known-issues-dev-cycle.md:19`): C2's per-token forks describe the replaced parser.
- **Claim 6** (`docs/working/plan-build-loop-handoff.md:126`): F11 says three shapes are untraced; A5 now lists one.
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:477-478`): same "three shapes" drift in the lib.
- **Claim 33** (`test/scripts/build-loop-check.bats:383-384`): the heavy-run test trips the print budget after 2,826 names, not the work bound at the sixth run; the emit work bound is now untested.

### Mostly Accurate
- **Claim 3** (`docs/working/known-issues-dev-cycle.md:18`): A5's "Not covered" omits instruction files outside the repo (an ancestor directory's CLAUDE.md, user memory) whose imports Claude Code follows into the repo (executed).
- **Claim 12** (`scripts/lib/dev-cycle-read.sh:453-458`): imported_names' failure list omits import_home.
- **Claim 26** (`scripts/lib/dev-cycle-read.sh:680-691`): main_imports' failure list omits the parser, import_home, the budget and lower.
- **Claim 28** (`scripts/lib/dev-cycle-read.sh:756-758`): paths under `.git` fail only when the checkout holds them as a file, not because main lacks them.
- **Claim 32** (`test/scripts/build-loop-check.bats:26`, `:53`): the Unicode-space tests cannot detect whether a space ends a token (mutant survives).

### Unverifiable
- None.

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: e1654266` line at the top.
- **Answered:** All eight claim groups the brief listed. (1) The superset rules match IMPORT_AWK/import_targets and Claude Code 2.1.292's extractor (0 misses in 3,236 fuzzed names; U+FFFD spellings confirmed in the real binary); the five exceptions are real and no sixth name-level exception was found, but instruction files outside the repo are a start-set gap no document names (Claim 3); the return-1 list is complete and no failure arm returns 0. (2) UTF8_OK agreement, fork condition and fail-toward-decoding hold. (3) import_home matches Claude Code, but the "Node's" attribution is wrong (22b). (4) The budget comments and the awk/bash count equivalence hold; the figures are 2,014 and 5,596. (5) The .git comment is imprecise; the memo comment, the hoist and the 4 MiB cap hold. (6) The headers, help, skill, A5's traced items and plan bullets hold, except F11's and the lib's "three shapes" and A3/C2. (7) Every FAILS-at name fails where it says, the figures hold, and the heavy-run comment is stale. (8) Counts and line figures hold; the mutant sentence does not. Suites: 143/143.
- **Out of scope:** Whether the ancestor and user-memory gap should block the merge or be routed (a disposition for the orchestrator); Bun's UTF-8 decoder beyond 8 probed sequences (no Bun runtime other than the claude binary).
- **Escalate:** Claim 3 (Medium) to the orchestrator's synthesis: it is a fail-open class outside both walks' start sets, not covered by any override row; Claim 33 (Medium): the emit work bound lost its only test in e1654266.
- **Questions I would have asked:** Whether "read broadly" in A5/the superset statement is meant to cover only files in the repo (then Claim 3 is a documentation gap) or every instruction source a session loads.
- **Decisions I made:** Read the claim in the caller's item 1 ("is anything else Claude Code imports missed?") to include where the walks start, and probed the real binary headless (isolated CLAUDE_CONFIG_DIR and HOME, no login, no network) rather than only reading its source. Execution logs live under /tmp/u2a3bfcfin-10T4/logs/ because the brief forbids writing worktree files other than this report. Scratch CLAUDE.md files for the probes were written with the Write tool inside /tmp/u2a3bfcfin-10T4 only.
