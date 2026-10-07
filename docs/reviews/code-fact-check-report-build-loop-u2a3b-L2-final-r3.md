Commit: e1654266

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b)
**Scope:** `git diff main...e1654266 -- . ':!docs/reviews'` (scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md) and the commit messages `main..e1654266`. U2a3b loop 2, final confirming pass, Stage 1 replicate r3.
**Checked:** 2026-10-07
**Commit:** e1654266
**Replication:** k=3
**Total claims checked:** 50
**Summary:** 37 verified, 8 mostly accurate, 2 stale, 2 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries): no claim here matches a logged pattern. Neither Incorrect verdict is a fabrication (Node's `os.homedir` exists; its behaviour is misdescribed), so nothing is added to the log.

## How the checking was done

- **Suites (executed).** `TMPDIR=<fresh mktemp> timeout 1500 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats` in a `git archive e1654266` copy (cwd `/tmp/u2a3bfcfin-suite-pNQe`), 2026-10-07T09:18:38Z to 09:19:27Z: **exit 0, 143/143 ok, 0 skipped** (42 + 78 + 19 + 2 + 2). Log: `/tmp/claude-1000/-workspace/d85c9919-8193-4546-8b61-a9f00fc88d03/scratchpad/u2a3bfcfin-logs/suites-e1654266.txt` (the logs below are in the same directory, written as `logs/`).
- **Claude Code 2.1.292 (executed against the installed binary).** `claude --version` prints `2.1.292 (Claude Code)`. The probe runs `claude -p hi` in a scratch repo with its own `CLAUDE_CONFIG_DIR`, a dummy API key and an `InstructionsLoaded` hook passed through `--settings`, which logs each file Claude Code loads (`load_reason: include` for an `@` import). Every run was killed by `timeout 25` (exit 124) after the load phase. Script: `logs/cc-probe.sh`; results: `logs/cc-shapes.txt`, `logs/cc-home.txt`.
- **Claude Code 2.1.292 (read from the bundle).** I read the strings of `.../@anthropic-ai/claude-code/bin/claude.exe` (Bun-compiled). Import regex `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g`; `#` cuts the name; `replaceAll("\\ "," ")`; a path filter (`./`, `~/`, `/` other than a bare `/`, or a first character in `[a-zA-Z0-9._-]`); resolver `Ye(H, dirname(resolvedPath))`, which trims the name, uses `path.join(os.homedir(), rest)` for `~/`, `path.normalize` for an absolute name, and otherwise `path.resolve(dir, name)`. `Hn` is the identity on Linux. Tokens come from `new QM({gfm:!1}).lex(h)`, whose `inlineText` returns `text:n[0]` (raw). Skipped: `code`/`codespan` tokens, and `html` tokens unless they start with `<!--` (those have `/<!--[\s\S]*?-->/g` removed). The size limit is `nH=4194304` (`if(s.totalBytes>nH)return{kind:"skipped"...}`).
- **Mutants (executed).** `logs/mut.py` makes the mutants and `logs/mutants.txt` holds the results (build-loop-check and dev-cycle suites on each).

---

## Claim 1: "Both walks share one token parser (`import_targets`) that reads a superset of Claude Code 2.1.292's import grammar ... the claim, its rules and its exceptions are stated once, in the comment above `import_targets`"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both walks call `import_targets` and that the superset statement sits above it. It does not establish that the superset holds; Claims 15a-15d check that.

Both walks call the parser: `out="$(head -c 4194305 -- "$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d")"` (`scripts/lib/dev-cycle-read.sh:669`) and `100644|100755) out="$(git cat-file blob "$MAIN_SHA:$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d")"` (`:726`). The statement opens with `# The superset claim (the one statement of it; known issue A5 and plan F11` (`:501`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:501-533`, `:669`, `:726`

---

## Claim 2: "Its cost is false positives (none among this repo's tracked docs on 2026-10-06)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-fix` giving the same answer per path from main's scripts (8f24e63a) and from e1654266's, compared after the reason text, in three checkouts on 2026-10-07. It does not establish the same for the future or for untracked docs.

Each run sent every listed path to both scripts' `--check-fix` and diffed the answers after the reason text. All runs exited 0, the diff was 0 lines every time, and both scripts printed `ok` for 14 paths:
- the worktree (`git ls-files 'docs/*.md' README.md`, 948 paths);
- /workspace on main (919 paths);
- a fresh clone at e1654266 (`git ls-files '*.md' README.md`, 1,524 paths).

Commands: `/tmp/u2a3bfcfin-meas-w1N2/cmp2.sh <checkout>` (worktree and /workspace) and `cmp.sh` (the clone), cwd the checkout, each exit 0, run 2026-10-07 between 09:28Z and 09:36Z. Output: `logs/checkfix-worktree.txt` and `logs/checkfix-workspace.txt`.

**Evidence:** `logs/checkfix-worktree.txt`, `logs/checkfix-workspace.txt`, `scripts/dev-cycle.sh:180-185`

---

## Claim 3: "Traced in Claude Code 2.1.292 ...: a symlinked instruction file's imports resolve from its target's directory (`path.resolve(dirname(realpath(importer)), name)`), as the walk does, and an `@` token's `..` after a directory link is resolved lexically, as the walk does"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the resolver's base directory and its lexical `..`, read from the 2.1.292 bundle. It does not establish whether Claude Code loads a symlinked instruction file in the first place: `EF` returns `[]` when `iH(e,Y)` holds for a non-canonical symlink, which I did not trace.

The reader calls `ZMe(h,e,n,r)` with `r` = the resolved path, and `ZMe` calls `reo(G,s)` with that resolved path. `reo` resolves each name with `let Y=Ye(H,FT(n))`, where `FT` is `dirname`. `Ye` ends in `return Hn(x(i,o))`, with `x` = `path.resolve` (imported as `resolve as x`), and path.resolve is lexical. I quoted these from the bundle strings; no line numbers are available because the source is a minified bundle.

**Evidence:** bundle strings of `claude.exe` (lines 414155 and 421255 of `strings -n 8` output: `function Ye(e,r){...if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)));...return Hn(x(i,o))}`)

---

## Claim 4: "`test/agents-gemini-sync.bats` holds a separate, older finder for where an import starts (v2.1.284), not these rules"

**Location:** `docs/working/known-issues-dev-cycle.md:18`; `scripts/lib/dev-cycle-read.sh:530-532`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the file exists and names v2.1.284. It does not establish what that finder does.

`test/agents-gemini-sync.bats:37`: `# Claude Code v2.1.284 (its extractor, read from the binary during review)`.

**Evidence:** `test/agents-gemini-sync.bats:37`

---

## Claim 5: "Gaps: known issue A5 (... checkout conversions ..., and three shapes untraced against Claude Code)"

**Location:** `docs/working/plan-build-loop-handoff.md:126` (row F11, edited on this branch)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of untraced shapes against A5's current text. It does not judge whether the traced items are right (Claim 3 does).

This branch's A5 now reads `Traced in Claude Code 2.1.292 (...): a symlinked instruction file's imports resolve from its target's directory ..., and an `@` token's `..` after a directory link is resolved lexically ... Untraced (no host probe yet): whether `@` references in `.claude/commands/` files load.` (`docs/working/known-issues-dev-cycle.md:18`). A5 lists one untraced shape, but F11 still says three. The commit e1654266 body says "A5 records two traced items", and the rubric's L2-I2-C7 says "Fixed: ... A5 records the traced items". F11 was not updated with them. The same stale count appears in the lib (Claim 13).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 6: U2a3c bullet: "a bare `head` after `git cat-file` exits 141 under pipefail: check `git cat-file -s` first or drain"; "no third path resolver (IMPORT_AWK's `put` and the symlink arm's `realpath -ms` are the two)"

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pipeline status for a blob over 4 MiB + 1, and that the lib resolves paths in exactly those two places. It does not establish the U2a3c design.

Command: `bash -c 'set -o pipefail; git cat-file blob HEAD:big | head -c 4194305 > /dev/null; echo rc=$?'` on a 5,000,000-byte blob, in `/tmp/u2a3bfcfin-cat-*`, 2026-10-07. It printed `rc=141`, and `PIPESTATUS` was `141 0 0` (output transcribed in this report; it was not captured to a file). The two resolvers are `function put(c, ...)` in IMPORT_AWK (`scripts/lib/dev-cycle-read.sh:550`) and `p="$(realpath -ms --relative-to="$ROOT_REAL" -- ...)"` in main_imports' symlink arm (`:736`). Paraphrased, no quote available because the claim is about absence: no other path resolution in import_targets, imported_names or main_imports (grep).

**Evidence:** `scripts/lib/dev-cycle-read.sh:550-565`, `:733-741`

---

## Claim 7: "the parser's root and home are the gate's own, but a session in another checkout (`git worktree list`) or under another HOME reads absolute and `~/` names against its own"

**Location:** `docs/working/plan-build-loop-handoff.md:279` (U2b bullet)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which name forms depend on the reading session's checkout. It does not establish U2b's root-set design.

A relative name can also re-enter another checkout through that checkout's directory name, not only an absolute one. In a repo `wtA` with a linked worktree `wtB`, AGENTS.md held `See @../wtB/docs/x.md`. Run from wtA, `import_targets "" < AGENTS.md` printed nothing (`rc=0`). Run from wtB, it printed `docs/x.md`, the file a session in wtB imports, since Claude Code uses `path.resolve(dirname(realpath(importer)), name)` (Claim 3). (Command in `/tmp/u2a3bfcfin-wt-*`, 2026-10-07; output transcribed here.) The precise version is: "reads absolute names, `~/` names and relative names that re-enter through its own directory name against its own". Claim 15c has the same narrowing in the lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:559-560` (`if (index(out, pre) != 1 || length(out) <= length(pre)) return`), `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 8: help text: "a file an instruction file names after an @, read broadly; ... "skip <path>: <reason>" otherwise, and for every path when the import walk fails"

**Location:** `scripts/dev-cycle.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix's arms. It does not establish which reason a path gets when an earlier arm already skips it.

`elif ! imported_names; then echo "skip $a: the instruction-file import walk failed, ..."` (`scripts/dev-cycle.sh:181-182`) comes before the only `ok` arm (`else check_path "$a"; fi`, `:185`), so a failed walk leaves no path `ok`. The test "--check-fix words a failed import walk as one and refuses (U2a3b)" passed in the suite run.

**Evidence:** `scripts/dev-cycle.sh:170-186`, `logs/suites-e1654266.txt`

---

## Claim 9: "The import walks also need python3 when an instruction file holds text that is not well-formed UTF-8; without it they fail closed."

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers python3's failure returning 1 through both walks. It does not establish behaviour when python3 is present but differs from Bun's decoder outside the tested cases.

`d="$(printf '%s\n' "$toks" | python3 -I -c '...')" || return 1` (`:621`). The test "both walks fail closed when python3 fails on text holding a byte above 0x7f" passed (`want walk failed; want docs/a.md imported; want docs/other.md imported`). "An instruction file" here covers any file the walk reads, imported files included, which are read as instructions.

**Evidence:** `scripts/lib/dev-cycle-read.sh:619-623`, `test/scripts/build-loop-check.bats:573-580`, `logs/suites-e1654266.txt`

---

## Claim 10: header: "The caller sets -euo pipefail (check_answer, brief_fields, tree_starts, imported_names and main_imports also set pipefail for themselves) ... imported_names and main_imports return 1 when the walk fails: call them under if or ||"

**Location:** `scripts/lib/dev-cycle-read.sh:14-22`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three functions this branch added to the list. check_answer and brief_fields were not re-read, since they are unchanged.

`tree_starts() { local -; set -o pipefail; ...` (`:647`); `local - f d p lp out used=0 seen=$'\n' queue=() recs=(); set -o pipefail` (`:649`); `local - rec f d p i c lk out used=0 ...; set -o pipefail` (`:693`). The only callers in scripts/ are `elif ! imported_names; then` (`scripts/dev-cycle.sh:181`) and isimported's `main_imports || return 0` and `imported_names || return 0` (`:777-778`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:647-649`, `:693`, `:772-781`; `scripts/dev-cycle.sh:181-183`

---

## Claim 11: "import_targets reads a superset of its names, ~/ against this process's HOME, and drops paths outside the repo"

**Location:** `scripts/lib/dev-cycle-read.sh:452-453`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ~/ join and the drop of out-of-repo paths. It does not cover an unset or empty HOME, where import_home uses the passwd entry rather than "HOME" (Claim 21a).

The tests "both walks read an @~/ import into a repo under HOME" and "the parser keeps every path below ROOT_REAL /" passed. The no_homer mutant fails the symlinked-HOME test (`logs/mutants.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:543-548`, `:559`, `test/scripts/build-loop-check.bats:618-626`

---

## Claim 12: imported_names: "It returns 1, with IMPORTED set to "error", when the start listing (git ls-files, untracked_md, instruction_names), lower, a file read or the parser fails, or a start file's name holds a newline ...; an inrepo_here that fails skips its path ... a cached error returns 1 again."

**Location:** `scripts/lib/dev-cycle-read.sh:453-458`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `return 1` in imported_names (`:648-678`, read whole). It does not establish behaviour under need_root, which exits.

Every listed arm exists and fails closed, and the cache arm is `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }` (`:651`). Two arms the branch added are missing from the list: `import_home || return 1` (`:662`, IMPORTED is still "error" there) and the walk-wide budget `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED=error; return 1; }` (`:671`). The budget overrun usually shows up as a parser failure (awk stops at IMPORT_LEFT first), but import_home's failure is a separate arm. Precise version: add "import_home fails, or the walk prints past IMPORT_OUT_MAX".

**Evidence:** `scripts/lib/dev-cycle-read.sh:648-678`

---

## Claim 13: "Not covered (known issue A5): ... checkout conversions (A5), and three shapes A5 lists as untraced against Claude Code."

**Location:** `scripts/lib/dev-cycle-read.sh:475-478`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count against A5's text at e1654266. Same finding as Claim 5, in the lib.

This branch edited this sentence (it dropped "absolute imports,"), but A5 now lists one untraced shape (the `.claude/commands/` question) and two traced ones (quoted in Claim 5). Precise version: "and the shape A5 lists as untraced against Claude Code".

**Evidence:** `scripts/lib/dev-cycle-read.sh:477-478`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 14: IMPORT_OUT_MAX: "Each walk fails once import_targets has printed more than this in all (characters, newlines between names counted; awk counts bytes, so it may stop first) ... A fresh clone's walks print about 2 KB, /workspace's about 6 KB. A caller that changes it clears IMPORTED_DONE and IMPORTED_MAIN_DONE before walking again."

**Location:** `scripts/lib/dev-cycle-read.sh:484-490`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "more than" boundary, characters against bytes, and both size figures as measured on 2026-10-07. It does not cover /workspace's main walk, which fails there (A5: ignored instruction files), so "/workspace's" walks means its tree walk.

- **Boundary.** The test with IMPORT_OUT_MAX 20/25/26 passed (`26 tree ok`, `26 main ok`). Under C.UTF-8, a name holding `\xc3\xa9` printed 19 bytes, which bash counts as 15 characters, so awk's byte count trips first, as stated.
- **Sizes.** Measured by wrapping import_targets and summing `${#o}` (`/tmp/u2a3bfcfin-meas-w1N2/meas.sh`): the fresh clone printed 2,014 characters over 5 files, in both the tree and the main walk; the worktree also printed 2,014; /workspace's tree walk printed 5,596 over 10 files.
- **Clearing the caches.** The tests clear `IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""` before re-walking (`test/scripts/build-loop-check.bats:339`).

(The size outputs are transcribed here: `tree ok 5596 10`, `tree ok 2014 5`, `main ok 2014 5`.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:484-490`, `:562-564`, `:669-671`, `:744-747`; `test/scripts/build-loop-check.bats:600-607`

---

## Claim 15a: the superset statement's rules match IMPORT_AWK and import_targets: every @; each prefix to the first blank (NUL and UNI_SPACES count as blanks); escaped space; splice; U+FFFD decoding gated by UTF8_OK; trim; absolute with `..` stopping at /; kept only below ROOT_REAL; ~/ joined to import_home's home, spelled and real

**Location:** `scripts/lib/dev-cycle-read.sh:501-525`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule-by-rule match between the statement and the code. Whether the rules are a superset of Claude Code is Claims 15b-15d.

Each rule against the code:
- **Every @.** `if (substr(line, i, 1) != "@") continue` scans every byte (`:569-570`).
- **Prefixes.** `name = name ch; emit(name)` emits every prefix (`:576`).
- **Blanks.** The run breaks at `ch == " " || ch == "\t" || ch == "\r"` (`:575`), after `s=(-e 's/\x0/ /g')` and `s+=(-e "s/$u/ /g")` (`:612-614`) turn NUL and each UNI_SPACES space into a blank.
- **Escaped space.** `if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ }` (`:574`).
- **Splice.** `if (index($0, "<!--")) scan(splice($0))` (`:592`).
- **U+FFFD.** The decoded copy is added only when a high byte is present and the UTF8_OK awk rejects a line (`:619-623`).
- **Trim.** `sub(/^ +/, "", c); sub(/ +$/, "", c)` (`:539`).
- **Absolute, `..` stops at /.** `if (substr(c, 1, 1) != "/") c = root "/" dir "/" c` and `if (part[i] == "..") { if (k > 0) k--; continue }` (`:551-555`).
- **Kept below ROOT_REAL.** `index(out, pre) != 1 || length(out) <= length(pre)` (`:559`).
- **~/ spelled and real.** `if (homer != home) put(homer "/" substr(c, 3))` then `c = home "/" substr(c, 3)` (`:545-546`).

The superset tests passed, and every rule's mutant I ran fails a test (no_trim, no_homer, no_left, gate_never: `logs/mutants.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:534-592`, `:611-633`, `logs/mutants.txt`

---

## Claim 15b: "these rules read every name Claude Code 2.1.292 can import (its import regex and Markdown lexer ...)" (outside the named exceptions)

**Location:** `scripts/lib/dev-cycle-read.sh:501-504`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the import regex, the `#` cut, the escaped-space rule, the path filter, the resolver, marked's inline-text rawness, the code and HTML-comment rules, CR handling and the U+FFFD decoder, read from the 2.1.292 bundle. It also covers 13 shapes and 5 invalid-UTF-8 cases run through the real binary. It does not cover lexer paths I did not enumerate (for example, every marked block rule's text transforms), the start-file set (A2/A5), or the exceptions (15c).

**Why each Claude Code name is a prefix the parser yields.** Each Claude Code name is a prefix of the run after an `@` in a raw text substring, or in an HTML-comment block with its comments removed. The reasons, from the bundle:
- inline text is raw (`return{type:"text",raw:n[0],text:n[0],escaped:r}`);
- escapes are separate `escape` tokens, so they only cut a name short;
- `lex` turns only `\r\n|\r` into `\n`;
- the regex token stops at `\s` or a backslash that is not followed by a space;
- the name is cut at `#` and trimmed.

The parser emits every such prefix, and it breaks later than Claude Code: it does not stop at `\v`, `\f` or a lone backslash.

**HTML-comment blocks.** Claude Code removes comments only from an HTML block that starts with `<!--`. That block ends on the line holding the first `-->`, so a name can cross only the comments on that last line. The parser's per-line splice pairs them the same way.

**Executed shapes.** Claude Code loaded `docs/aa.md docs/abc.md docs/abs.md docs/ca.md docs/cb.md docs/cs.md docs/dot.md docs/em.md docs/la.md docs/lb.md "docs/my notes.md" docs/q1.md docs/q2.md`. It did not load the span, mail, pre, fence or lead files, nor `docs/aa.md x` (`logs/cc-shapes.txt`). The parser yields every loaded name (the superset and splice tests, `test/scripts/build-loop-check.bats:339-363`, `:528-543`).

**Executed decoding.** For `@f/1\xe2\x80.md` and four other invalid sequences, Claude Code loaded `f/1�.md`, `f/2���.md`, `f/3���.md`, `f/4��.md` and `f/5����.md`. import_targets printed exactly those five names (1, 3, 3, 2 and 4 U+FFFD), matching python3's counts.

Two observations, both over-reads and not misses:
- a name holding a NUL makes Claude Code drop the whole file, because `f7t` throws `if(e.includes("\x00"))`. My first probe file was not loaded at all;
- Claude Code did not load `~/...` through a symlinked HOME (`logs/cc-home.txt`, HOME=`.../hl`), so the "real form" join only over-reads.

**Evidence:** bundle strings (functions `reo`, `ZMe`, `Ye`, `QM.lex`, `inlineText`, `escape`), `logs/cc-shapes.txt`, `logs/cc-home.txt`, `scripts/lib/dev-cycle-read.sh:534-633`

---

## Claim 15c: "Known exceptions ...: a session whose home differs from this process's (its ~/ names), a session in another checkout of the repo (an absolute name into that checkout; the gate's root set is U2b's), names that differ only in case on a case-insensitive file system (docs/reviews/override-log.md line 350), Claude Code's approved external includes, and any further decoding it may add (an entity, a percent escape)."

**Location:** `scripts/lib/dev-cycle-read.sh:516-523`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each exception's reality and the "another checkout" parenthetical. The case-insensitive exception is not reproducible on this host (case-sensitive filesystem), and "further decoding it may add" is about future versions.

- **Another home: real.** With HOME=$d, Claude Code loaded `repo/c.md` from `@~/repo/c.md` (`logs/cc-home.txt`).
- **Another checkout: real, but the parenthetical is too narrow.** A relative name that re-enters another checkout through that checkout's directory name (`@../wtB/docs/x.md`) is missed too (executed: Claim 7). Precise version: "(an absolute name into that checkout, or a relative one re-entering through its directory name; ...)".
- **override-log.md line 350: right line.** It is the row about "other names on a case-insensitive checkout".
- **Approved external includes: real** in the bundle. `if(g>0&&!z&&!AD(he))return[]` loads an include outside the project only when `z` is set, and such a file can import repo files the walk never reads.
- **Entity and percent decoding.** 2.1.292 does neither: inline text is raw and `Ye` does not decode. That fits "may add".

**Evidence:** `scripts/lib/dev-cycle-read.sh:516-523`, `docs/reviews/override-log.md:350`, `logs/cc-home.txt`

---

## Claim 15d: the five named exceptions are complete (no other name Claude Code imports is missed)

**Location:** `scripts/lib/dev-cycle-read.sh:516-523`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the candidate misses I tested or traced; none of them is outside the named classes. It does not establish completeness over every marked transform or every host state, and it is subject to the parenthetical in 15c.

Candidates I checked and ruled out:
- **Symlinks outside the repo into it.** `@/proc/self/cwd/c.md`, `@/proc/self/root/<repo>/d.md` and `@../lnk/e.md` (lnk → repo): Claude Code loaded none of them, since `iH` rejects a non-canonical symlinked path (executed; transcript). Through a symlinked HOME: also not loaded (`logs/cc-home.txt`).
- **Empty HOME.** Claude Code uses the passwd home, as import_home does (Claim 21a).
- **Relative HOME.** Claude Code imports a cwd-relative `sub/a.md`, and the parser fails closed on the `~/` name (Claim 21d).
- **Escaped Markdown, pipes in tables, autolinks, HTML entities, CR.** Ruled out from the bundle: escapes are separate tokens, `gfm:!1` turns off tables and GFM autolinks, text is raw, and CR becomes LF.
- **4 MiB+ files.** Claude Code skips them.
- **Non-text extensions.** Claude Code skips them (`Skipping non-text file in @include`).

These make Claude Code read fewer names, never names outside the parser's prefixes.

**Evidence:** bundle strings (`EF`, `iH`, `kOe`, `ZMe`, `reo`), `logs/cc-home.txt`, `logs/cc-shapes.txt`

---

## Claim 16: "It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is empty, when a ~/ name appears and the home is not absolute, or when the candidates and comment splices run past a work bound or print past IMPORT_LEFT"

**Location:** `scripts/lib/dev-cycle-read.sh:526-529`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every failure arm of import_targets (`:611-633`, read whole) and awk's exits 2, 3 and 4. It does not cover a caller without pipefail when `printf` into awk fails (not listed; under the walks' pipefail it returns 1).

Each arm returns 1:
- `import_home || return 1`;
- `toks="$(env LC_ALL=C sed "${s[@]}")" || return 1`;
- python3's `|| return 1`;
- the final awk `|| return 1`, where the awk exits 2 when `root == ""` (`:590`), 3 at the work bound or IMPORT_LEFT (`:536`, `:563`, `:582`), and 4 for a home that is not absolute (`:544`).

No failure arm returns 0. The only failure that does not return 1 is the UTF8_OK gate's awk, which by design falls through to decoding (Claim 20).

Tests (all passed):
- "the parser returns 1 when it cannot read its input" (`import_targets "" < docs` → `failed`);
- the empty ROOT_REAL case (`rc=1`);
- the relative home (`tilde=1`);
- the work bound (`rc=1`);
- `IMPORT_LEFT` (`12=1`).

The no_reltilde_fail and no_left mutants fail (`logs/mutants.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:534-633`, `test/scripts/build-loop-check.bats:383-388`, `:582-587`, `:648-659`

---

## Claim 17: "Claude Code trims the name; it rejects a name led by a space first, so trimming one only over-reads."

**Location:** `scripts/lib/dev-cycle-read.sh:537-538`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the leading-space case and the trim. The trailing-space trim matches Claude Code's (`let n=e.trim()`).

The bundle's filter needs `H.startsWith("./")||H.startsWith("~/")||H.startsWith("/")&&H!=="/"||...H.match(/^[a-zA-Z0-9._-]/)`, which a name starting with a space fails. Executed: `@\ docs/lead.md` was not loaded (`logs/cc-shapes.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:537-540`, `logs/cc-shapes.txt`

---

## Claim 18: "~/ joins the home directory (Claude Code: path.join(os.homedir(), rest)), also spelled through its real path, since ROOT_REAL is real."

**Location:** `scripts/lib/dev-cycle-read.sh:541-542`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the join and the real-path spelling the code adds. It does not establish that Claude Code loads the real-path spelling: under a symlinked HOME it does not (executed), so that spelling, and the test name "both walks read an @~/ import when HOME is a symlink..." (`test/scripts/build-loop-check.bats:638`), describe an over-read.

Bundle: `if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))`, where `b` is `join` and `c` is `homedir` (imports `homedir as c` and `join as b`). Executed: with HOME=`.../hl` (a link to the repo's parent), Claude Code loaded only CLAUDE.md, not `~/repo/c.md`. With HOME set to the real directory, it loaded `repo/c.md` (`logs/cc-home.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:541-548`, `logs/cc-home.txt`

---

## Claim 19: "printed counts as the walks count: each name, a newline between names."

**Location:** `scripts/lib/dev-cycle-read.sh:562-563`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers equivalence in a C locale. In a UTF-8 locale bash counts characters, fewer than awk's bytes (Claim 14), so awk stops first.

`printed += length(out) + 1; if (printed - 1 > left) exit 3` gives the sum of name lengths plus n-1, which is `${#out}` for `$(...)` output with its trailing newline dropped. The test at `:655-659` (`12=1`, `13=0`) and the walk-wide 25/26 boundary test passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:562-564`, `:671`, `:745`

---

## Claim 20: UTF8_OK: "Well-formed UTF-8 (RFC 3629 ...) as an awk ERE for a C-locale awk -v: it agreed with python3's decoding on 20,013 cases ... Only text it rejects forks python3, since well-formed text decodes to itself."

**Location:** `scripts/lib/dev-cycle-read.sh:593-597`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's agreement with python3's strict decode on an independent sample (mawk 1.3.4), and the fork condition. The 20,013 figure itself is from the performance report; I did not rerun it.

Independent differential: 30,000 random 1-8-byte lines (70% high bytes, seed 7) under `env LC_ALL=C awk -v ok="$UTF8_OK"` against python3's strict decode. They agreed on all 30,000 (27,908 invalid and 2,092 valid). Run in `/tmp/u2a3bfcfin-utf-*`, 2026-10-07; output transcribed here. The fork condition is `if [[ "$toks" == *[$'\x80'-$'\xff']* ]] && ! printf ... | env LC_ALL=C awk -v ok="$UTF8_OK" '$0 !~ ok { exit 1 }'; then` (`:619`), so a failing gate awk (any non-zero status) also forks python3: it fails toward decoding. The performance report says "agrees with python3's `replace` decode on all 20,013 cases" (`docs/reviews/performance-reviewer-review-2026-10-07-L2i2-build-loop-u2a3b.md:66`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:593-597`, `:619-623`

---

## Claim 21a: import_home: "(unset or empty: the passwd entry)"

**Location:** `scripts/lib/dev-cycle-read.sh:598-600`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code and Claude Code 2.1.292 (whose runtime is Bun). The attribution to Node is Claim 21b.

The code: `h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}" || h=""` (`:606`). Executed: with `HOME=` and with HOME unset, import_home set `/home/node`, the passwd entry.

Claude Code: with `HOME=` and with HOME unset, it loaded `repo/b.md` through `@~/../../tmp/u2a3bfcfin-cc-OhOV/repo/b.md`. That name resolves only from a home two levels deep (`/home/node`); with `""` it would be cwd-relative and miss (`logs/cc-home.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:604-610`, `logs/cc-home.txt`

---

## Claim 21b: "from HOME as Node's os.homedir reads it (unset or empty: the passwd entry)" (also commit e1654266: "unset or empty: the passwd entry, as Node reads it"; rubric L2-I2-A1)

**Location:** `scripts/lib/dev-cycle-read.sh:599-600`
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Node's behaviour for an empty HOME. It does not change Claim 21a: the code matches Claude Code.

Command: `env HOME= node -e 'console.log(JSON.stringify(require("os").homedir()))'` with Node v22.23.2, 2026-10-07T09:39Z. It printed `""`. With HOME unset it printed `"/home/node"` (`logs/cc-home.txt`, last lines). Node keeps an empty HOME. Claude Code 2.1.292 runs on Bun, which uses the passwd entry, and the code follows Claude Code. Someone who checks the comment against Node and "fixes" the code to keep an empty HOME would make the parser fail on every `~/` name (fail-closed, but a divergence). Precise version: "as Claude Code's runtime (Bun) reads it; Node keeps an empty HOME".

**Evidence:** `scripts/lib/dev-cycle-read.sh:599-600`, `logs/cc-home.txt`

---

## Claim 21c: "A walk calls it once, so the parser's $(...) calls inherit it; it recomputes only when HOME changes."

**Location:** `scripts/lib/dev-cycle-read.sh:600-601`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers import_home's cache key and its callers. It does not measure cost.

import_targets also calls `import_home || return 1` on every file (`:613`), so "once" means it is computed once. The per-file call returns at `[[ "$IMPORT_HOME_KEY" != "x$h" ]] || return 0`. The key is the computed home, not HOME. With a realpath shim, `HOME=/tmp`, `/tmp` again, `/usr`, `""` and then unset gave 3 realpath calls; the unset case reused the empty case's `/home/node`. With HOME unset or empty, the `getent` fork still runs on every call, once per file read. Precise version: "it re-resolves (realpath) only when the computed home changes; with HOME unset each call runs getent".

**Evidence:** `scripts/lib/dev-cycle-read.sh:604-613`

---

## Claim 21d: "A relative or empty home is kept, and the parser fails on a ~/ name then."

**Location:** `scripts/lib/dev-cycle-read.sh:601-602`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HOME=rel and a failing getent. Claude Code with a relative HOME imports a cwd-relative path (it loaded `sub/a.md` with HOME=sub, `logs/cc-home.txt`), so failing closed there is safe.

With HOME=rel: `rel->[rel][rel]`. With HOME unset and a getent shim that exits 2: `getent-fail->[]`. In both cases `printf "see @~/x.md\n" | import_targets ""` gave `tilde rc=1`. The test at `test/scripts/build-loop-check.bats:648-653` passed, and the no_reltilde_fail mutant fails it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:543-545`, `:606-609`, `logs/mutants.txt`

---

## Claim 22: "python3's "replace" decoding matched Claude Code's byte for byte: U2a3b L2 security F1"

**Location:** `scripts/lib/dev-cycle-read.sh:617-621`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers five invalid sequences: a truncated 3-byte sequence, an overlong 4-byte sequence, a surrogate, an overlong 2-byte sequence and one past U+10FFFF. It does not cover every invalid shape.

Claude Code loaded exactly the U+FFFD-spelled files import_targets printed, with 1, 3, 3, 2 and 4 replacement characters (Claim 15b).

**Evidence:** transcript of the `/tmp/u2a3bfcfin-cc-OhOV` probe, `scripts/lib/dev-cycle-read.sh:619-623`

---

## Claim 23: "IMPORT_LEFT, set by a walk, is what its IMPORT_OUT_MAX budget has left, so awk stops there rather than after."

**Location:** `scripts/lib/dev-cycle-read.sh:629-630`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' `IMPORT_LEFT=$((IMPORT_OUT_MAX - used))` and awk's check. It does not cover the 1.0 s timing (Claim 44).

`IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d"` appears at `:669` and `:726`, and awk checks `if (printed - 1 > left) exit 3` before `print out` (`:563-564`). The no_left mutant fails "the parser itself stops once it has printed more than IMPORT_LEFT allows".

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-564`, `:632-633`, `:669`, `:726`, `logs/mutants.txt`

---

## Claim 24: "Claude Code skips a file over 4 MiB, so reading only its start over-reads at worst"

**Location:** `scripts/lib/dev-cycle-read.sh:667-668`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk's cap against Claude Code's limit. The main walk still reads blobs whole (routed to U2a3c; override row).

Bundle: `nH=4194304` and `if(s.totalBytes>nH)return{kind:"skipped",isDirectory:!1}`, with the log message `skipping ${e}: not a regular file or exceeds ${nH} byte limit`. `head -c 4194305` reads a file of exactly 4 MiB whole (the test at `:609-616` passed) and stops a larger one. The no_cap mutant fails the 300 MB test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:667-669`, `test/scripts/build-loop-check.bats:564-571`, `:609-616`

---

## Claim 25: main_imports: "returns 1, with IMPORTED_MAIN set to "error", ... when main is not found by name, ... a blob cannot be read, symlink text it follows is ..., or an imported path main lacks lies under a directory main stores as a symlink or gitlink or exists in the checkout as anything but a plain directory below the root"

**Location:** `scripts/lib/dev-cycle-read.sh:680-691`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list against main_imports' `return 1` arms (`:692-770`, read whole). Unchanged pre-existing arms were checked only for presence.

Three arms this branch added are missing from the list:
- `import_home || return 1` (`:719`);
- the budget `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED_MAIN=error; return 1; }` (`:745`);
- `i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }` (`:747`).

"A blob cannot be read" also covers the parser's own failure only loosely (`out="$(git cat-file blob ... | ... import_targets "$d")" || {...}`). The new bare-`.git` exception (`:759`) is not in the "anything but a plain directory" clause either. It is stated inline instead.

**Evidence:** `scripts/lib/dev-cycle-read.sh:680-770`

---

## Claim 26: hoisted lower: "One lower per file, not per candidate, as in imported_names." (IMPORTED_MAIN unchanged by the hoist)

**Location:** `scripts/lib/dev-cycle-read.sh:748-749`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the set of lower-cased names recorded, compared with main's per-line form. It does not cover the new failure arm, which is a behaviour change by design (fail closed).

Main appended `IMPORTED_MAIN+="$(lower "$p")"$'\n'` for every non-empty line, before the `seen` check. The branch appends `i="$(lower "$out")"; IMPORTED_MAIN+="$i"$'\n'`. `tr` is bytewise and `out` holds no empty lines: awk prints only names longer than the root prefix (`:559`), and the symlink arm rejects empty text (`:731`). So the recorded `\n`-delimited set is the same. All main-walk tests passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:744-751`, `git show main:scripts/lib/dev-cycle-read.sh` (the old line `IMPORTED_MAIN+="$(lower "$p")"$'\n'`)

---

## Claim 27: "A .git component itself (a prefix candidate from @.gitignore, or a nested repository's) is a checkout file or directory git never stores. Files under it are not skipped: they fail below, since main lacks them."

**Location:** `scripts/lib/dev-cycle-read.sh:756-759`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what happens to a `.git/...` candidate. It does not establish what Claude Code does with a `.git/` import.

A file under `.git` fails only when the checkout holds it as anything but a plain directory: `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }` (`:763`). An absent one (such as any `.git/x` in a linked worktree, where `.git` is a file) is recorded as imported and not walked, which is harmless because it has no imports to hide. A plain directory under `.git`, such as `.git/info`, passes. The test at `:628-636` passed (`.git/notes.md` exists → walk failed), and the gitskip_star mutant (skip `.git/*` too) fails it. Precise version: "Files under it are not skipped: one the checkout holds fails below, since main lacks it."

**Evidence:** `scripts/lib/dev-cycle-read.sh:752-765`, `test/scripts/build-loop-check.bats:628-636`, `logs/mutants.txt`

---

## Claim 28: "pok holds parents already checked: a token's prefixes share them, so the loop stops at the first."

**Location:** `scripts/lib/dev-cycle-read.sh:761-762`
**Type:** Invariant / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the memo's soundness. The loop sets `pok[c]` before checking c and returns 1 on a failure, so a set entry means c and all its ancestors were checked. It does not cover the 16.6 s → 1.0 s timing (Claim 44).

`c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ -z "${pok[$c]+set}" ]] || break; pok[$c]=1; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }; done`. The no_pok mutant survives (0 failures), as the commit message and override row say (time only).

**Evidence:** `scripts/lib/dev-cycle-read.sh:762`, `logs/mutants.txt`

---

## Claim 29: isimported: "A failed walk, a failed lower of $2, or a walk name that is neither answers imported (0) ...; a caller that words a failed walk runs the walk first (imported_names or main_imports, under if)."

**Location:** `scripts/lib/dev-cycle-read.sh:767-771`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers isimported (`:772-781`, read whole) and check_fix's order.

`lp="$(lower "$2")" || return 0`, `main) main_imports || return 0;` and `tree) imported_names || return 0;`, then `*) return 0 ;;`. check_fix runs `imported_names` before `isimported tree` (`scripts/dev-cycle.sh:181-183`). The tests "the walks fail closed past the start list" (`docs/trfail.md imported`) and the bogus-walk test (including the new need_root stop) passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:772-781`, `test/scripts/build-loop-check.bats:40-47`, `:448-481`

---

## Claim 30: SKILL.md: "file an instruction file names after an `@`, read broadly; ... and refuses every path when the import walk fails"

**Location:** `skills/dev-cycle/SKILL.md:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 8: it covers the wording against check_fix.

It mirrors `scripts/dev-cycle.sh:181-185` (Claim 8), and the dev-cycle tests passed.

**Evidence:** `skills/dev-cycle/SKILL.md:72-78`, `scripts/dev-cycle.sh:181-185`

---

## Claim 31: the "FAILS at be94c871" and "FAILS at 98e3b1df" test names

**Location:** `test/scripts/build-loop-check.bats:483`, `:495`, `:506`, `:517`, `:545`, `:618`; `test/scripts/dev-cycle.bats:1059`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named test failing with the named commit's lib swapped into an e1654266 copy (scripts/dev-cycle.sh stays at e1654266). It does not establish that each fails only for its stated reason; I read the HTML-comment test's failure (`rc=124`) and the dev-cycle test's failed assertion.

Commands, run 2026-10-07:
- in `/tmp/u2a3bfcfin-oldbe94c871-*`, `TMPDIR=... bats -f 'FAILS at be94c871' test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats`: `1..6`, all six `not ok`;
- in `/tmp/u2a3bfcfin-old98e3b1df-*`, `bats -f 'FAILS at 98e3b1df'`: `1..1`, `not ok`.

All seven pass at e1654266 (`logs/suites-e1654266.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:480-552`, `:618-626`, `test/scripts/dev-cycle.bats:1059-1064`

---

## Claim 32: "the parser fails, not stalls, on one line of many HTML comments (FAILS at be94c871 ...; about 10 s)"; "320,000 comments in one 2.24 MB line took 27 s with status 0 at be94c871"

**Location:** `test/scripts/build-loop-check.bats:545-547`
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line size, the be94c871 run and the test's run time at e1654266.

The line is 320,000 × 7 bytes = 2,240,000. At be94c871 the parser took 30.1 s with `rc=0` (`timeout 90`, 2026-10-07), close to 27 s. At e1654266 the parser returned `rc=1` in 0.205 s, and the whole bats test ran in 0.465 s. "About 10 s" is true only for be94c871, where the test's inner `timeout 10` ends it (`rc=124`). At HEAD the test takes under a second. Precise version: "(FAILS at be94c871 after its 10 s timeout ...)".

**Evidence:** `test/scripts/build-loop-check.bats:545-552`

---

## Claim 33: "Seven 4200-byte runs after an @ pass the candidate-work bound (each prefix's length is charged; the sixth run trips it): the parser returns 1."

**Location:** `test/scripts/build-loop-check.bats:383-388`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic against `work += length(c); if (work > 50000000) exit 3`. The test passed with `rc=1`.

Each run charges 4200·4201/2 = 8,822,100. Five runs total 44,110,500 (under 50,000,000) and six total 52,932,600 (over), so the sixth trips the bound.

**Evidence:** `scripts/lib/dev-cycle-read.sh:536`, `test/scripts/build-loop-check.bats:383-388`

---

## Claim 34: "import_targets prints 13 bytes for each file (a, a., a.m, a.md; 26 in all)" and "see @a.md prints a, a., a.m, a.md: 13 with the newlines between them."

**Location:** `test/scripts/build-loop-check.bats:601`, `:656`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic (1+2+3+4+3 = 13) and the boundary outputs `12=1 13=0` and `25 ... failed`, `26 ... ok`, both of which passed.

**Evidence:** `test/scripts/build-loop-check.bats:600-607`, `:655-659`

---

## Claim 35: test comments on what Claude Code 2.1.292 reads: "reads none of docs/mail.md, docs/pre.md and docs/lead.md"; "(harness) reads docs/abc.md ..., docs/cs.md ... and docs/dot.md; it never reads "docs/a.md x""; "A link or code span between two @s does not hide the second (Claude Code reads both)"; "an escaped space and an absolute path inside the repo are imports"

**Location:** `test/scripts/build-loop-check.bats:340-352`, `:366-371`, `:529-530`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these shapes through the real 2.1.292 binary in a scratch repo, via one imported file. It does not cover the shapes on lines I did not reproduce (the NUL, `~g.md` and `e(f).md` cases).

Claude Code loaded `docs/abc.md`, `docs/cs.md`, `docs/dot.md` and `docs/aa.md` (the test's `docs/a.md`). It also loaded `docs/la.md`, `docs/lb.md`, `docs/ca.md`, `docs/cb.md`, `"docs/my notes.md"`, `docs/abs.md`, `docs/em.md`, `docs/q1.md` and `docs/q2.md`. It loaded none of span, mail, pre, fence, lead or `docs/aa.md x` (`logs/cc-shapes.txt`, captured 2026-10-07, exit 124 by design).

**Evidence:** `logs/cc-shapes.txt`, `test/scripts/build-loop-check.bats:339-389`, `:528-543`

---

## Claim 36: test names and comments: "both walks fail once the parser has printed more than IMPORT_OUT_MAX bytes in all"; "4194304 bytes in all, the last 14 an import with no newline after it"; "An untracked sparse 300 MB file at the prefix "big""; "the main walk fails closed on an import of a file under .git ..."

**Location:** `test/scripts/build-loop-check.bats:400`, `:564-571`, `:609-616`, `:628-636`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these tests passing and their figures. "bytes" equals the comment's "characters" under the test's `LC_ALL=C`.

`'\n@docs/late.md'` is 14 bytes, and the test asserts `[ "$(wc -c < big)" -eq 4194304 ]`. All passed, and each test's mutant (no_cap, gitskip_star) fails it.

**Evidence:** `test/scripts/build-loop-check.bats:400-406`, `:564-636`, `logs/mutants.txt`

---

## Claim 37: dev-cycle.bats: "--check-fix words a failed import walk as one and refuses"; "A corrupt index: git ls-files fails"; "--check-fix refuses a doc imported through a name Claude Code decodes with U+FFFD"; "an email-shaped token is over-read (superset)"

**Location:** `test/scripts/dev-cycle.bats:1048-1085`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tests passing and the Claude Code half of the email line. `user@docs/mail.md` was not loaded by Claude Code, by the same shape as Claim 35.

All passed in the suite run. The gate_never mutant fails the U+FFFD test (`not ok 100`).

**Evidence:** `test/scripts/dev-cycle.bats:1048-1085`, `logs/suites-e1654266.txt`, `logs/mutants.txt`

---

## Claim 38: commit messages: "130/130" (dd51e9a7), "133/133" (98e3b1df), "143/143" (e1654266)

**Location:** commit messages dd51e9a7, 98e3b1df, e1654266
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `@test` count in the five suites at each commit (121, 130, 133, 143) and an executed pass at e1654266. It does not cover re-running the two earlier commits.

`git show <c>:<suite> | grep -c '^@test'` summed over the five suites gives 130 at dd51e9a7, 133 at 98e3b1df and 143 at e1654266. At e1654266 the run gave 143/143 with exit 0 (`logs/suites-e1654266.txt`).

**Evidence:** `logs/suites-e1654266.txt`

---

## Claim 39: commit messages: "350 changed code lines at be94c871", "486", "525", "679" against main

**Location:** commit messages dd51e9a7, 98e3b1df, e1654266
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers adds plus deletes outside `docs/` (the plan's row-62 measure, `docs/working/plan-build-loop-handoff.md:266`) for `main...<c>`.

`git diff --numstat main...<c> -- . ':!docs'` summed gives 284+66 = 350, 413+73 = 486, 452+73 = 525 and 603+76 = 679.

**Evidence:** `docs/working/plan-build-loop-handoff.md:266`

---

## Claim 40: e1654266: "--check-fix over 942 paths identical to main; interleaved, main 2.39-2.76 s, this branch 2.63-2.77 s"; dd51e9a7 and 98e3b1df: "identical to main" over 941 docs

**Location:** commit messages dd51e9a7, 98e3b1df, e1654266
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers "identical" at e1654266 in three checkouts, and a timing reproduction in the worktree. The path counts and timings depend on time and host. It does not cover the earlier commits' "identical" lines, which were not re-run.

On 2026-10-07 the answers were identical in the worktree (948 paths), /workspace (919) and a fresh clone (1,524 .md). Interleaved timings in the worktree: main 2.36-2.54 s, branch 2.62-2.72 s, close to the stated ranges (`logs/checkfix-worktree.txt`). In /workspace (more untracked instruction files; a 5,596-character tree walk), main took 2.62-2.75 s and the branch 3.23-3.28 s (`logs/checkfix-workspace.txt`). The stated ranges hold for a checkout like the worktree, not for /workspace.

**Evidence:** `logs/checkfix-worktree.txt`, `logs/checkfix-workspace.txt`

---

## Claim 41: e1654266: "Mutants: each fix's mutant fails a test except the parent memo and the LC_ALL=C guard (time only and equivalent here; override rows)"; rubric L2-I2-C1: "the gate mutant fails"

**Location:** commit message e1654266; `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3b.md:25`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutants I ran in `logs/mutants.txt`. It does not cover the original authors' exact mutants.

These fail one or more tests: no_homer (1), no_gitskip (1), gitskip_star (1), no_left (1), no_trim (1), no_reltilde_fail (1), no_cap (1) and gate_never (3, a gate that never sends text to python3). no_pok survives (0), as stated. The mutant that removes the UTF-8 gate itself, gate_always (always fork python3 on a high byte, which reverts performance F1), also survives with 0 failures. Like the memo, the gate is a time-only fix. "The gate mutant fails" holds only for the gate_never mutant. Precise version: "...except the parent memo, the UTF-8 gate's removal (time only) and the LC_ALL=C guard".

**Evidence:** `logs/mutants.txt`, `logs/mut.py`

---

## Claim 42: e1654266: "a ~/ name is a real import (Claude Code joins it to the home directory)"

**Location:** commit message e1654266
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a ~/ name under the session's real home. It does not cover a symlinked home, which Claude Code does not load (Claim 18).

With HOME=`/tmp/u2a3bfcfin-cc-OhOV`, Claude Code loaded `repo/c.md` from `@~/repo/c.md`. With HOME=`.../repo/sub`, it loaded `repo/sub/a.md` from `@~/a.md` (`logs/cc-home.txt`).

**Evidence:** `logs/cc-home.txt`

---

## Claim 43: e1654266: "(unset or empty: the passwd entry, as Node reads it)"

**Location:** commit message e1654266 (and rubric L2-I2-A1)
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same evidence as Claim 21b. The commit message cannot be changed; the comment can be fixed.

Node v22.23.2 returns `""` for `HOME=`. The passwd fallback is what Claude Code's runtime (Bun) does (`logs/cc-home.txt`).

**Evidence:** `logs/cc-home.txt`

---

## Claim 44: commit timings: "a long a/ run fails in 1.0 s (10.1 s before)"; "a 2,820-byte deep token takes 1.0 s (16.6 s)"; "42 of 45 walked files forked before"; dd51e9a7 "3.4 s against main's 4.0 s"

**Location:** commit messages e1654266, dd51e9a7
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Not re-run. The exact inputs are in the performance reports, not in the commits. They are accepted-immutable under rubric L2-I2-C11.

To verify, rerun the performance report's `a/` run and its 2,820-byte deep-token input against be94c871, 98e3b1df and e1654266 on one host.

**Evidence:** `docs/reviews/performance-reviewer-review-2026-10-07-L2i2-build-loop-u2a3b.md`

---

## Claims Requiring Attention

### Incorrect
- **Claim 21b** (`scripts/lib/dev-cycle-read.sh:599-600`): "as Node's os.homedir reads it": Node v22 keeps an empty HOME (`""`). The passwd fallback is Claude Code's runtime (Bun), which the code correctly matches. Name Bun or Claude Code instead. Legibility-target: for-author.
- **Claim 43** (commit e1654266): the same attribution, in an immutable commit message and rubric row L2-I2-A1. Legibility-target: for-author (fix the comment; the commit stays as is).

### Stale
- **Claim 5** (`docs/working/plan-build-loop-handoff.md:126`): F11 still says "three shapes untraced against Claude Code"; A5 now lists one untraced and two traced. Legibility-target: for-author.
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:477-478`): the same "three shapes A5 lists as untraced", in the main_imports comment. Legibility-target: for-author.

### Mostly Accurate
- **Claim 7** (`docs/working/plan-build-loop-handoff.md:279`) and **Claim 15c** (`scripts/lib/dev-cycle-read.sh:519-520`): the "another checkout" exception also covers a relative name that re-enters that checkout through its directory name (`@../wtB/docs/x.md`, executed), not only an absolute name. Legibility-target: for-author.
- **Claim 12** (`scripts/lib/dev-cycle-read.sh:453-458`): imported_names' return-1 list omits import_home's failure and the IMPORT_OUT_MAX overrun. Legibility-target: for-author.
- **Claim 21c** (`scripts/lib/dev-cycle-read.sh:600-601`): import_home is keyed on the computed home and called again per file. With HOME unset, getent runs on every call. Legibility-target: for-author.
- **Claim 25** (`scripts/lib/dev-cycle-read.sh:680-691`): main_imports' return-1 list omits the branch's import_home, lower and budget arms, and the bare-.git exception. Legibility-target: for-author.
- **Claim 27** (`scripts/lib/dev-cycle-read.sh:756-758`): files under .git fail only when the checkout holds them; absent ones are recorded, not failed (harmless). Legibility-target: for-author.
- **Claim 32** (`test/scripts/build-loop-check.bats:545`): "about 10 s" is be94c871's failure time (its 10 s timeout); at HEAD the test takes 0.5 s; be94c871 measured 30 s against "27 s". Legibility-target: for-author.
- **Claim 41** (commit e1654266; rubric `:25`): removing the UTF-8 gate (always fork python3) is a surviving time-only mutant, like the memo. Only the never-decode mutant fails. Legibility-target: for-author.

### Unverifiable
- **Claim 44** (commits e1654266, dd51e9a7): historic timings need the performance reports' inputs rerun on one host. Legibility-target: for-orchestrator-synthesis.

Every Verified claim (1-4, 6, 8-11, 14, 15a, 15b, 15d, 16-20, 21a, 21d, 22-24, 26, 28-31, 33-40, 42) has Legibility-target: for-orchestrator-synthesis. The prior "Fixed" dispositions I checked hold: L2-I2-A1 (behaviour; only the Node attribution is wrong), A2, C1 (the gate works; its mutant claim is Claim 41), C2, C3, C4, C5, C6, C7 (except the F11 and lib "three shapes" text: Claims 5 and 13) and C9. Override-log premises: none changed. The reader-root-set row (2026-10-07) is still accurate, with Claim 7's addition of relative re-entry.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: e1654266` line at the top.
- **Answered:** All eight requested areas are covered:
  - the superset statement, rule by rule, against IMPORT_AWK, Claude Code 2.1.292's bundle and the live binary (15a-15d, 16-18);
  - UTF8_OK (20, 22);
  - import_home (21a-21d);
  - IMPORT_OUT_MAX and IMPORT_LEFT (14, 19, 23);
  - main_imports' .git, memo, hoist and 4 MiB comments (24-28);
  - the header, help, SKILL.md, A5, F11 and the U2a3c/U2b bullets (1-13, 30);
  - the tests' names and figures, including every "FAILS at" name, which I executed against its commit (31-37);
  - the commit messages (38-44).
- **Suites:** build-loop-check, dev-cycle, build-loop-read, fixture-git-env and fixture-hermeticity: **143/143 ok**, exit 0.
- **Out of scope:** Code quality and design; whether U2b's root set should include relative re-entry (a design question, raised only as a doc precision in Claim 7).
- **Escalate:** Nothing blocking. No claim found the superset false outside its named exception classes. The two Stale and two Incorrect items are wording.
- **Decisions I made:**
  - I executed Claude Code 2.1.292 headless, with a dummy key and an `InstructionsLoaded` hook in a /tmp scratch repo, every run under `timeout 25`. The scratch CLAUDE.md was written with the Write tool because a hook blocks Bash writes to CLAUDE.md. All probe processes ended (no leftover PIDs).
  - I mutated only `git archive` copies.
  - The execution logs are in the session scratchpad (`.../scratchpad/u2a3bfcfin-logs/`), not under `docs/reviews/execution-logs/`, because the brief allows editing only this report.
  - I did not append to the hallucination log: no fabrication was found.
