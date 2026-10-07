Commit: be94c871

# Security Review — feat/build-loop-u2a3b (loop 2, iteration 1: the superset parser)

**Scope:** `git diff f6fdda68...be94c871 -- scripts test docs/working skills`, reviewed from a `git archive be94c871` copy, not the live worktree. I read `import_targets` and `IMPORT_AWK`, `tree_starts`, `imported_names`, `main_imports`, `isimported`, `blocker` and `inrepo_here` in full (`scripts/lib/dev-cycle-read.sh:96-130`, `:440-700`), and `check_fix` (`scripts/dev-cycle.sh:170-186`).
**Date:** 2026-10-07
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i1.md` (Stage 1: 42 claims, 10 Incorrect), the loop 2 section and iteration-4 gate of `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3b.md`, the previous security report `security-reviewer-review-2026-10-06-final-build-loop-u2a3b.md`, and `performance-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md` (read for its DoS findings, so they are not re-filed here).

**Threat model (from the brief).** `import_targets` should read a superset of the names Claude Code's `@`-import grammar could load, and fail toward "imported". A fail-open is a name Claude Code imports that neither walk lists, so `--check-fix` prints `ok` or the U2a4 floor passes it. Over-reading only over-refuses.

**Method.**
- **Harness.** The previous harness under `/tmp/u2a3b-sec*` is gone, so I rebuilt it from the installed binary (`@anthropic-ai/claude-code` 2.1.292, `bin/claude.exe`). The marked lexer sits at the same offsets as before (210313891 to 210341941, `function lw()` to `class dd`), and I ran it in node. I transcribed `reo` verbatim from offset 212107457, together with its callers `kOe`/`ZMe`/`DH` and the resolver `Ye` (offset 205304326: `path.resolve(base, name.trim())`, throwing on NUL).
- **Runtime proxy.** The file read is `readFile(path, {encoding:"utf8"})`. I ran it under node, not Bun. I tried `BUN_BE_BUN=1 claude.exe`, but it started Claude Code itself (no output; `timeout 30` killed it, rc 124).
- **Fuzzer.** I wrote a new random-document fuzzer from 84 fragments (`gen.js`, `gen2.js`). Its alphabet covers comments, HTML blocks, containers, escapes, entities, `\v` `\f` `\r` NUL, UNI_SPACES, a BOM, invalid UTF-8, front matter and `@@`. It leaves out the known classes (re-entry, absolute paths, names over 4096 bytes, a backslash in dir). Ten seeds produced 19,000 documents.
- **End-to-end checks.** Fixture repos ran `dev-cycle.sh --check-fix` and `isimported main` / `isimported tree` (`e2e.sh`).
- **Environment.** Everything ran in `/tmp/u2a3bsecL2r-KlOU` under `timeout`, with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 LC_ALL=C`. No background processes.
- **Suites.** I ran the three suites that source the lib (`build-loop-check`, `build-loop-read`, `dev-cycle`) on the F1 candidate, with `TMPDIR=/tmp/u2a3bsecL2rT-*`. They passed 117/117.

## Trust Boundary Map

```
B1: [instruction / imported file bytes (S1)]   → [import_targets: sed (NUL, UNI_SPACES → blank) → IMPORT_AWK scan/splice/emit] → [IMPORTED (tree)]
B2: [main's blobs (S6)]                         → [git cat-file | import_targets (shared)]                                    → [IMPORTED_MAIN → U2a4 self-merge floor]
B3: [Claude Code 2.1.292 loader (S5): UTF-8 decode → marked → reo → Ye]  ⊆? [the bytewise candidate set (S4)]                 → [fail-open iff not a superset]
B4: [candidate names (S4)]                      → [-f / inrepo_here / blocker / seen / ent lookups]                           → [files read by the walk]
B5: [IMPORTED]                                  → [isimported tree, check_fix]                                                → [autonomous in-cycle doc edit (--check-fix ok)]
```

| Label | Source | Mutability | Trust, by sink class |
|---|---|---|---|
| S1 | Bytes of every instruction file and imported file in the checkout | runtime-mutable (any commit, or an untracked file written by any process running as the same user) | UNTRUSTED toward the imported/not-imported decision and toward which files the walk reads |
| S4 | Candidate names from `IMPORT_AWK` | derived from S1/S6 | UNTRUSTED toward path lookups (`[[ -f ]]`, `realpath --`, assoc-array keys); never reaches exec or eval |
| S5 | Claude Code 2.1.292's loader | external, version-dependent | The reference, executed from the shipped bytes (node standing in for Bun's decoder) |
| S6 | main's committed blobs | runtime-mutable at every merge | As S1 |

## Findings

#### F1. Claude Code decodes each file as UTF-8 and turns every invalid byte sequence into U+FFFD, so it imports a name whose bytes appear nowhere in the file. The bytewise parser never lists that name, so both walks miss the file and everything it imports.

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:550-559` (`import_targets`: `env LC_ALL=C sed` then `env LC_ALL=C awk`, both bytewise). It is consumed at `scripts/dev-cycle.sh:181-183` (tree) and `scripts/lib/dev-cycle-read.sh:647` (main, the U2a4 floor).
**Boundary:** B3, B1 → B5, B2
**Move:** 2 (the parser assumes the loader reads the file's bytes; it reads their UTF-8 decoding), 11 (bypass of the superset claim)
**Confidence:** High for the mechanism. Both sides were executed: node's `readFile(…,{encoding:"utf8"})` with the extracted lexer and `reo`, and the walks end to end. That Bun's decoder replaces invalid bytes the same way is reasoned, not run (Bun follows the WHATWG decoder, as node does).
**Pre-existing:** yes. main f6fdda68 misses the same names. This is not a regression, but it is a gap in the superset this commit claims.
**Legibility-target:** for-author. The code comment (`:492-497`) claims a superset with no exception, and A5 (`docs/working/known-issues-dev-cycle.md:18`) says it misses only "a name Claude Code builds that is not a prefix of one blank-free run after an `@` (for example a Markdown entity it might decode)". The fact-check found the entity example does not occur (Claim 5). This one does.

Evidence (verbatim, `:557` and `:559`):
`  toks="$(env LC_ALL=C sed "${s[@]}")" || return 1`
`  printf '%s\n' "$toks" | env LC_ALL=C awk -v dir="$1" -v root="$ROOT_REAL" "$IMPORT_AWK"`

Claude Code's read is `DH`: `return await e.readFile(n,{encoding:"utf8"})`, then `ZMe` → `QM({gfm:!1}).lex(h)` → `reo`. The name therefore holds U+FFFD, and `path.resolve` writes it back to disk as `EF BF BD`. The awk sees the raw byte (`\xff`), and no file has that name.

Reproducer (executed, `R/`):
```
AGENTS.md          : "x @docs/\xff.md y\n"
docs/\xef\xbf\xbd.md : "@c.md\n"        (tracked; a valid UTF-8 name, U+FFFD)
docs/c.md          : "c\n"
```
| | Claude Code (harness) | main f6fdda68 | be94c871 | F1 candidate |
|---|---|---|---|---|
| `AGENTS.md` names | `docs/�.md` | `docs/\xff.md` and prefixes | same | adds `docs/�.md` |
| `--check-fix docs/c.md` | loaded (through `docs/�.md`) | **ok** | **ok** | skip (imported) |
| `isimported main` / `tree docs/c.md` | — | **- / -** | **- / -** | imported / imported |

The control: when AGENTS.md spells the name as valid UTF-8 (`@docs/\xef\xbf\xbd.md`), be94c871 refuses `docs/c.md` in both walks. So decoding is the only cause. `docs/�.md` itself fails `pathform` and cannot be a `--check-fix` target. It is still the hop that hides `docs/c.md`, which passes pathform, and the main walk (the floor) never lists it either.

Fuzz differential (`comm -23` of Claude Code's names against the walk's names; dir "" for every document):

| Seeds | Docs | Names Claude Code resolves | be94c871 misses | of which not U+FFFD | F1 candidate misses |
|---|---|---|---|---|---|
| 1-6 (`gen.js`) | 9,000 | 809 | 40 | 0 | 0 |
| 11-14 (`gen2.js`, more `@` after a blank) | 10,000 | 5,942 | 413 | 0 | 0 |
| 11 at main f6fdda68 | 2,500 | 1,492 | 411 (101 U+FFFD) | — | — |

Every miss at be94c871 is a U+FFFD name. Within this alphabet the rest of the superset holds. That covers comments and the splice, HTML blocks, containers, escapes, entities, `\v` `\f` `\r`, NUL, UNI_SPACES, a BOM, front matter and `@@`. The net gain over main is large: on seed 11, main misses 411 names and be94c871 misses 101.

**Recommendation:** When the text holds a byte ≥ 0x80, also scan a copy decoded the way Claude Code decodes it. Python's `decode("utf-8","replace")` matched node byte for byte on truncated, overlong, surrogate, out-of-range and lone-continuation sequences (`dec.bin`). The tested candidate is in the Appendix. It closes the reproducer and all ten fuzz seeds, and passes 117/117. Two caveats. It adds a python3 dependency on non-ASCII files only, and fails closed if python3 is absent. And its `[[ == *[\x80-\xff]* ]]` test matched an invalid byte under both `C` and `C.UTF-8`, but `env LC_ALL=C grep -qa $'[\x80-\xff]'` would remove the dependence on the locale. Without python3, the same replacement can be written in awk (WHATWG maximal-subpart rules), or the walk can fail on any file that is not valid UTF-8 (`iconv -f UTF-8 -t UTF-8`), at the price of refusing every path while such a file is in the graph. Add the reproducer to the "both walks read what Claude Code reads" fixture. Then correct the comment, A5 and F11: the exception is "a name Claude Code builds by decoding", and the entity example goes.

#### F2. Under the prefix rule the walk reads whole any regular file a candidate names, including files Claude Code never reads. Claude Code skips files over 4 MiB (`nH=4194304`); the walk has no cap, so one large file stalls it.

**Severity:** Low (availability. It stalls rather than failing open, and needs a large file at a path that is a prefix of an `@` run)
**Location:** `scripts/lib/dev-cycle-read.sh:597-598` (`[[ -f "$p" … ]] && inrepo_here "$p"` → queued → `import_targets "$d" < "$f"` at `:592`), and the main walk's `git cat-file blob` at `:647`
**Boundary:** B4
**Move:** 8 (what if the file is huge), 1 (the over-read widens which files cross into the reader)
**Confidence:** High (executed)
**Relation to performance F2/F5:** this extends those findings and does not re-file them. They bound awk's output and its per-byte scan. This finding is about which files enter that scan at all.

Reproducer (executed, `R3/`). AGENTS.md holds `see @d/x.md`, and `d` is an untracked 80 MB file of base64 (no `@`). Claude Code resolves only `d/x.md`, which does not exist (ENOTDIR), so it reads nothing. It would also skip `d` itself if `d` were imported, because `d` is larger than `nH`. The tree walk lists the candidates `d d/x d/x. d/x.m d/x.md`. `d` is a regular file, so the walk reads it: `imported_names` took **47 s** and returned ok. Many such files, or larger ones, make every `--check-fix` call stall that long, for each process.

**Recommendation:** Skip a file Claude Code would skip. A regular file over 4,194,304 bytes is never loaded (`DH`: `if(!t.isFile()||t.size>r)return null`), so skipping it is exact, not a loss of the superset. In the tree walk, check `stat -c %s` (or `wc -c`) before queueing. In the main walk, check `git cat-file -s "$MAIN_SHA:$f"`. Record the bound with the grammar's revisit trigger, because `nH` is per version.

## Already known and agreed: confirmed or extended only

- **Re-entry `@../<repo>/…`, absolute spellings without the literal ROOT_REAL prefix, `-v` backslash mangling, the 4096-byte cap.** The fuzzer leaves these classes out by construction; I did not re-run them. The resolver transcription adds one fact: `Ye` resolves `path.resolve(dirname(realpath(importer)), name.trim())`. The architecture/test-strategy fix (resolve to an absolute path, keep only names under `root "/"`) is therefore the right model, as long as it also applies `trim()`. trim only removes blanks that come from trailing `\ `, which a prefix already covers. That is why trim alone never caused a miss.
- **splice: quadratic and outside the work bound.** Confirmed by reading; performance F1 measured it. On the fail-open question I found no miss. Claude Code splices only inside an HTML block that starts with `<!--`, and only that block's first comment can span lines (marked's comment block ends on the line of its first `-->`; executed: `"<!-- a\nb -->@docs/s<!-- x\ny -->ret.md"` gives html `"<!-- a\nb -->@docs/s<!-- x\n"` plus a paragraph). The awk scans every `@` on the original line and splices each line, which covers every spliced name. The fuzzer's comment fragments (`<!--`, `-->`, `<!-->`, `<!-- c -->`, HTML blocks) produced no non-U+FFFD miss.
- **Work bound per file, bash side unbounded.** These are performance F2/F3/F5. F2 above adds the file-selection side.
- **`.git` from `@.gitignore` in a linked worktree; return code 3.** Not re-derived. The tree walk also reads `.git/config` and similar files when a candidate names them. That is consistent with Claude Code, whose extension filter passes a name with no extension, and it is harmless.

## Checked and cleared (no finding)

- **NUL.** marked keeps NUL in text (executed). A Claude Code name holding NUL makes `Ye` throw (`f7t`), and `kOe`'s catch then drops the whole file. So Claude Code loads less, and turning NUL into a blank (`sed`) only over-reads.
- **UNI_SPACES next to invalid bytes.** The UNI_SPACES lead bytes (C2, E1, E2, E3, EF) can never be continuation bytes. So a bytewise match of one is always a code point the decoder sees, even after an invalid sequence. Fuzzed with `\xc2\xa0`, `\xe2\x80\x80`, a BOM, `\xe2\x80` and `\xc2\x85`; no miss.
- **`\v`, `\f`, `\r`.** JavaScript's `\s` ends a name at `\v` and `\f`, while the awk continues past them. The shorter name is still a prefix, so the superset holds (fuzzed). `\r` ends both.
- **Assoc-array keys `@` and `*` in main_imports** (`seen[$p]`, `${ent[$p]+set}`, where `@@` yields the candidate `@`). bash 5.2.15 treats them as literal keys (executed), so a stray `@@` neither skips nor fails the walk.
- **Very long lines.** A 3 MB line followed by ` @docs/a.md` yields `docs/a.md` in 0.2 s (mawk 1.3.4).
- **Injection.** Candidate names reach only `[[ -f ]]`/`[[ -e ]]`/`[[ -d ]]`, `realpath -e --`/`-ms --`, quoted `[[ == ]]` patterns, `printf '%s'`, assoc-array keys and `<` redirection. Blob reads use only main's own tree names (`"$MAIN_SHA:$f"`). The awk program has no `system`, pipe or `getline`. No candidate can hold a newline (awk reads one record per line), so the newline-delimited `IMPORTED`/`seen` lists cannot be forged.

## Untested bypass candidates

- **Bun's own UTF-8 decoder** (F1 used node's). I could not run the bundled runtime: `BUN_BE_BUN=1` started Claude Code itself.
- **Claude Code versions other than 2.1.292, or a marked upgrade.** Not testable here.
- **The front-matter strip (`p8n`) and the text-extension filter (`f8n`).** The harness skips both, so its Claude Code side reads more than Claude Code does. That makes the harness stricter, not weaker. I did not transcribe them.
- **Nested repos, submodules, `.claude/rules/` starts in the tree walk, case-insensitive checkouts.** Carried from A2/A5, not re-run.

## Endorsement Claims

- **Claim:** At be94c871, for every name the extracted Claude Code 2.1.292 lexer and `reo` resolve in 19,000 random documents built from 84 fragments (the known classes left out), `import_targets` lists the name unless it holds a U+FFFD that came from decoding an invalid UTF-8 byte (F1).
  **Location:** `scripts/lib/dev-cycle-read.sh:498-559`
  **Evidence:** executed
  **Verified:** `comm -23 cc.N wh.N` for seeds 1-6 and 11-14 (453 misses, every one holding `EF BF BD`).
  **Not verified:** shapes outside the fragment alphabet, and Bun's decoder.
  **route: code-fact-check**
- **Claim:** With the Appendix candidate applied, the same corpus has no misses, the F1 reproducer refuses `docs/c.md` in both walks, and the three suites that source the lib pass 117/117.
  **Location:** the Appendix diff
  **Evidence:** executed
  **Verified:** `wf.N` for all ten seeds, `e2e.sh R docs/c.md`, and `bats` on `fix/`.
  **Not verified:** the cost of the extra python3 fork on non-ASCII files (a performance-reviewer question).
  **route: code-fact-check**

## Primitive sweep

Primitive: path construction and lookup from untrusted text

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `IMPORT_AWK` `emit` (`:510-526`) | S1, S6 | `~/` dropped; absolute only under a literal `root "/"`; lexical `..` with a floor at the root | Known re-entry/absolute gaps (not re-filed). The bytes it reads are F1 |
| `imported_names` `[[ -f "$p" ]] && inrepo_here "$p"` (`:597-598`) | S4 | `blocker` walks top down with `realpath -e --` | Cleared for injection; F2 (no size cap) |
| `imported_names` `import_targets "$d" < "$f"` (`:592`) | S4 (queued) | rawfile at queue time; status checked | F2. A same-user swap to a FIFO between check and read would stall it (TOCTOU, pre-existing, not executed) |
| `main_imports` `seen[$p]`, `ent[$p]`, `blocker "$p" dir` (`:668-676`) | S4 | literal assoc keys (executed for `@`, `*`) | Cleared |
| `main_imports` `git cat-file blob "$MAIN_SHA:$f"` (`:647`, `:651`) | main tree names | `ent` lookup only | Cleared |
| `isimported` `[[ "$IMPORTED…" == *$'\n'"$lp"$'\n'* ]]` (`:690-691`) | S3/S4 | quoted, newline-free | Cleared |

No exec, eval, deserialization or network primitive is in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Claude Code imports the U+FFFD spelling of a name holding an invalid UTF-8 byte; the bytewise parser misses it and every file it imports (both walks, `--check-fix` and the floor; pre-existing) | Medium | B3, B1→B5, B2 | `scripts/lib/dev-cycle-read.sh:550-559` | High (node decoder; Bun reasoned) |
| F2 | The prefix rule reads any regular file a candidate names, with no 4 MiB cap like Claude Code's; one 80 MB file stalls the tree walk for 47 s | Low | B4 | `scripts/lib/dev-cycle-read.sh:592-598`, `:647` | High |

## Overall Assessment

Beyond the agreed list, the over-approximation holds up. Across 19,000 fuzzed documents, the only names Claude Code imports that the parser misses come from F1, which is UTF-8 decoding and not grammar. Main misses about four times as many names on the same corpus. The comment splice, NUL, the Unicode spaces, `\v`/`\f`, very long lines and the assoc-array keys are all cleared, and no candidate name reaches an exec or eval sink. F1 is a real fail-open that predates this unit. It reaches `--check-fix` through one hop, and the U2a4 floor directly. It needs a deliberately shaped instruction file, like the earlier Medium splice and link shapes, and its candidate fix is about five lines. F2 is availability only. Of the remaining work, the agreed resolution fix (absolute resolution, ENVIRON, no 4096 cap) matters most for security. F1 should land with it, so the superset claim the comment, A5 and F11 make is true.

## Appendix: F1 candidate patch (tested, not applied)

```diff
@@ import_targets() {
   toks="$(env LC_ALL=C sed "${s[@]}")" || return 1
+  # Claude Code decodes the file as UTF-8 and turns each invalid sequence into
+  # U+FFFD, so a name can hold bytes the file does not: read that spelling too.
+  if [[ "$toks" == *[$'\x80'-$'\xff']* ]]; then
+    u="$(printf '%s\n' "$toks" | python3 -I -c 'import sys; sys.stdout.buffer.write(sys.stdin.buffer.read().decode("utf-8","replace").encode())')" || return 1
+    [[ "$u" == "$toks" ]] || toks+=$'\n'"$u"
+  fi
   # A pipe, not a here-string: bash writes a long here-string to a temp file,
```
(`u` is already a `local` in `import_targets`.)

Evidence files are in `/tmp/u2a3bsecL2r-KlOU/`:
- `marked.js` (the extracted lexer), `cc.js` and `ccall.js` (the `reo` transcription)
- `gen.js`, `gen2.js` and `walkall.sh` (the fuzzer)
- `fz*`/`fy*` (corpora) and the name sets `cc.*`, `wh.*`, `wf.*`, `wm.11`
- `e2e.sh` and the fixtures `R`, `R2`, `R3`
- `fix/` (the patched copy) and `dec.bin` (the decoder comparison)

## Goal-Alignment Note

- **Answered:** I looked for fail-open shapes beyond the agreed list, in the loop 2 superset parser at be94c871, and tested them against the rebuilt Claude Code 2.1.292 harness and end to end. I found one new Medium fail-open (F1, UTF-8 decoding, pre-existing) with a tested fix, and one Low availability issue (F2). The splice, NUL, Unicode, injection and DoS questions are each dispositioned above.
- **Out of scope:** re-deriving the agreed items, and checkout-side reads (U2a3c).
- **Escalate:** F1 to this loop's fix pass, alongside the agreed resolution fix. F2 to the same pass, or to the performance backlog with performance F2.
