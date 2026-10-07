Commit: 7ddff454

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b)
**Scope:** range 45ad17b0..7ddff454, iteration 2 (loop pass). Covers the comments added or changed in `scripts/lib/dev-cycle-read.sh` (the imported_names header :450-455, the import_targets token comment :487-499 and its inline comments, the imported_names start-list comment :533), the test names and comments added or changed in `test/scripts/build-loop-check.bats`, and the commit message of 7ddff454. 1ccc8b65's message is not re-checked (it is in Accepted-immutable rows).
**Checked:** 2026-10-06
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 25
**Summary:** 22 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

**Execution provenance (applies to every `executed` claim).** All runs used a scratch copy of 7ddff454 (`git -C /workspace/.claude/wt-build-loop-u2a3b archive 7ddff454 | tar -x -C /tmp/u2a3b-fc2-HKGh`), working directory `/tmp/u2a3b-fc2-HKGh`, between 2026-10-06T23:47Z and 23:52Z, with GNU bash 5.2.15 and GNU sed 4.9. Captured output is in `/tmp/u2a3b-fc2-HKGh/logs/`, outside the worktree, because the dispatch allows only this file in the worktree. Fixture repos for the probes were created under `/tmp/u2a3b-fc2-HKGh/repo-*`. Mutants were applied one at a time by `python3 -I /tmp/u2a3b-fc2-HKGh/mut.py <lib> <name>`, which asserts that exactly one match is replaced. Each mutant was followed by `TMPDIR=$(mktemp -d /tmp/u2a3b-fc2-tmp-XXXX) bats test/scripts/build-loop-check.bats` (or a `-f` filter, as named), and the lib was restored from `lib.orig` and `cmp`-checked after each one. Claude Code's side comes from the installed binary `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` (`--version` → `2.1.292 (Claude Code)`). Its import regex was re-read with `grep -aoE` for this pass.

**Hallucination-pattern log:** read (`docs/reviews/hallucination-patterns.md`, 5 patterns). Claims 22 and 23 (test and line counts in a commit message) are the shape of the logged "All 85 tests … but the suites hold 97" pattern. Both were re-counted and both reproduce. No Incorrect verdicts, so there is nothing to log.

---

## Claim 1: imported_names "returns 1, with IMPORTED set to "error", when the start listing (git ls-files, untracked_md, instruction_names), lower, a file read or the parser fails …; an inrepo_here that fails skips its path. … a cached error returns 1 again."

**Location:** `scripts/lib/dev-cycle-read.sh:450-455`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named failure source in a fresh shell and on a second call, and empty and non-empty listings. It does not establish behavior when `need_root` fails (that exits, as documented elsewhere), or for failures of `inrepo_here`'s own helpers beyond "skip".

```bash
# scripts/lib/dev-cycle-read.sh:531-541
  [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }
  IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error
  # The start list ends with "rc=0" only when both listings and the name filter succeeded, as in main_imports.
  mapfile -d '' recs < <(set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names && printf rc=0 || printf rc=1)
  [[ ${#recs[@]} -gt 0 && "${recs[-1]}" == rc=0 ]] || return 1
  for f in "${recs[@]:0:${#recs[@]}-1}"; do
    lp="$(lower "${f##*/}")" || return 1
    if [[ ! "$lp" =~ $INSTRUCTION_FILE ]] || ! inrepo_here "$f"; then continue; fi
    [[ "$seen" == *$'\n'"$f"$'\n'* ]] && continue
    seen+="$f"$'\n'; queue+=("$f")
  done
```
(excerpt ends :541; enclosing imported_names() continues to :553 — read: `:546` `out="$(import_targets "$d" < "$f")" || { IMPORTED=error; return 1; }`, `:549` the per-target lower guard, `:550` `inrepo_here "$p"` as a skip condition)

`IMPORTED=error` is set at :532 before every early `return 1`, and :546/:549 set it again, so the cache test at :531 returns 1 on a second call. Executed (`/tmp/u2a3b-fc2-HKGh/probe1.sh`, cwd `/tmp/u2a3b-fc2-HKGh`, exit 0, 2026-10-06T23:48Z). Each case calls imported_names twice:

| Case | First call | Second call |
|---|---|---|
| normal (AGENTS.md → docs/a.md) | walked, `docs/a.md` | walked |
| empty listing (no instruction file; grep exits 1) | walked, empty | walked |
| corrupt `.git/index` | `walk failed IMPORTED=error` | walk failed |
| shimmed `git ls-files -z` exits 3 | failed | failed |
| shimmed `untracked_md` exits 3 (before, or after writing output) | failed | failed |
| shimmed grep (instruction_names) exits 2 (with or without output) | failed | failed |
| unreadable start file (`chmod 000`) | failed | failed |
| failing `tr` | failed | failed |

On the record format, the start list is NUL-terminated because `grep -z` terminates every record it prints (paraphrased — no quote available because this is GNU grep's documented `-z` output behavior; executed in `/tmp/u2a3b-fc2-HKGh/logs/instnames.txt`, where `od -c` shows `C L A U D E . m d \0`). The trailing `rc=0`/`rc=1` has no NUL, so `mapfile -d ''` makes it the last element. A listed name cannot equal `rc=0`, because every name passes a filter that requires `\.md$` (`:524`). The slice `"${recs[@]:0:${#recs[@]}-1}"` evaluates its length arithmetically and is empty for the empty-listing case, which the probe executed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:450-455`, `:524`, `:528-553`; `/tmp/u2a3b-fc2-HKGh/logs/probe1.txt`, `/tmp/u2a3b-fc2-HKGh/logs/instnames.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "it ends at a blank, a UNI_SPACES space included, or at a backslash, as the import token of Claude Code does, and at #, where Claude Code cuts the name it captured (so a token after a # is an over-read …)"

**Location:** `scripts/lib/dev-cycle-read.sh:487-490`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the token end set compared with Claude Code 2.1.292's regex and its `#` cut. It does not establish other Claude Code versions, the `\ ` form (Claim 3), or the separate "a token may follow any byte but a letter or digit" clause (unchanged here).

The parser's regex is `IMPORT_RE='(^|[^[:alnum:]])@[^[:space:]\\#]+'` (`scripts/lib/dev-cycle-read.sh:482`). The UNI_SPACES characters become blanks first (`:502` `s+=(-e "s/$u/ /g")`). Re-read from the binary (`grep -aoE` on claude.exe 2.1.292, 2026-10-06T23:51Z):

```
/(?:^|\s)@((?:[^\s\\]|\\ )+)/g,w;while((w=S.exec(h))!==null){let H=w[1];if(!H)continue;let G=H.indexOf("#");if(G!==-1)H=H.substring(0,G);if(!H)continue;if(H=H.replaceAll("\\ "," "),H){if(!EP
```

Claude Code's capture ends at whitespace or at a backslash not followed by a space, and it cuts the name at `#` after capture. So the reworded comment now matches the mechanism that iteration 1's Claim 5 asked for. The one exception, the backslash inside `\ `, is handled by the parenthetical (Claim 3). A second `@` after a `#` is read by the parser but not by Claude Code, which is an over-read, as stated.

**Evidence:** `scripts/lib/dev-cycle-read.sh:482`, `:487-490`, `:502`; claude.exe 2.1.292; `docs/reviews/code-fact-check-report-build-loop-u2a3b.md` Claim 5; `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "a backslash-escaped space is known issue A5"

**Location:** `scripts/lib/dev-cycle-read.sh:490`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether A5 exists and where the escaped-space form is routed. It does not establish whether A5's text should be edited, which is the author's call.

A5 exists in `docs/working/known-issues-dev-cycle.md:18`, but its text never mentions a backslash or an escaped space. It lists "start files under a symlinked directory …, a path through a directory main stores as a symlink …, other names one file has on a case-insensitive checkout, or absolute imports into the repo". `rg -i "backslash|escaped"` over the file finds nothing. The routing does exist, in override-log row 350: "… and a backslash or trailing-`_` token form … | Defer | Known issue A5 (docs/working/known-issues-dev-cycle.md)". Row 356 adds that "The backslash-escaped space (`\ `) stays under that row's Defer and trigger." So the pointer is right by the ledger. A reader who opens A5, though, finds nothing about the escaped space. The defect is comment/doc only, in the A5 row's text rather than the code comment.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`; `docs/reviews/override-log.md:350`, `:356`
**Legibility-target:** for-author

---

## Claim 4: "each token yields its whole, its part before the first of [ ] ( ) < ! * _ or a backtick, and each of those with trailing . , ; : ! ? * _ ~ ) ] or backticks stripped, each path once"

**Location:** `scripts/lib/dev-cycle-read.sh:494-496`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cut and strip expressions in bash 5.2. It does not establish that this set is every point where Claude Code's Markdown lexer ends a text token (iteration 1's Claim 7b residue, deferred).

```bash
# scripts/lib/dev-cycle-read.sh:509-510
    for c in "$t" "${t%%[][()<!*_"$b"]*}"; do  # b: a backtick, written as \x60
      v="$c"; while [[ "$v" == *[.,\;:!?*_~\)\]] || "$v" == *"$b" ]]; do v="${v%?}"; done
```
(excerpt ends :510; enclosing import_targets() continues to :519 — read)

The quoted `"$b"` inside the bracket expression acts as a literal member, and the other members still cut. Executed with `bash /tmp/u2a3b-fc2-HKGh/probe2.sh` (exit 0, 23:48Z): `` a.md`x` ``→`a.md`, and each of `a[b a]b a(b a)b a<b a!b a*b a_b` → `a`. `a"b`, `a$bc` and `a\b` are unchanged, so neither the quote character nor `$`/`b` becomes a member. The strip loop still strips backticks: ``x.md`` `` → `x.md` and `` x.md`.)` `` → `x.md`. Across commits, for `` Read @docs/a.md`code` `` the new lib yields `docs/a.md`, 1ccc8b65 does not, and 45ad17b0 does (`r1-shapes.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:500-519`; `/tmp/u2a3b-fc2-HKGh/logs/probe2.txt`, `/tmp/u2a3b-fc2-HKGh/logs/r1-shapes.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: "The start list ends with "rc=0" only when both listings and the name filter succeeded, as in main_imports."

**Location:** `scripts/lib/dev-cycle-read.sh:533`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the :534 pipeline's status under pipefail for each component. It does not establish behavior if `printf` itself fails.

`{ git ls-files -z && untracked_md; } | instruction_names && printf rc=0 || printf rc=1` (`:534`): a failing ls-files skips untracked_md and fails the group. Pipefail carries any stage's failure to the `&&`. instruction_names maps grep's "no match" (1) to 0 and anything else to non-zero (`:524`). Claim 1's table executed each component's failure. main_imports uses the same shape, `mapfile -d '' recs < <(untracked_md && printf rc=0 || printf rc=1)` (`:583`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:524`, `:534-535`, `:573-574`, `:583-584`; `/tmp/u2a3b-fc2-HKGh/logs/probe1.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "Two NBSPs in one run: the token ends at the first."

**Location:** `test/scripts/build-loop-check.bats:28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behavior the comment states. It does not establish that the second NBSP pins anything under the new parser: mutant `nbsp-no-g` (`s/$u/ /` without `g`) passes the whole suite, because no `@` follows the second NBSP.

The fixture line is `'See @docs/nb.md\xc2\xa0for\xc2\xa0you, …'` (`:30`) and the test wants `docs/nb.md imported` (`:36` `ps=(docs/nb.md …)`). The test passes at 7ddff454 (`suites.txt`, ok 1). A token that ran on past the first NBSP would never yield `docs/nb.md`. The second NBSP was Patch A's kill for U2a2's `%`-vs-`%%` cut, which no longer exists. Mutant `nbsp-no-g`: `bats test/scripts/build-loop-check.bats` exit 0, 0 failing (`mut-nbsp-no-g.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:26-41`; `scripts/lib/dev-cycle-read.sh:502`; `/tmp/u2a3b-fc2-HKGh/logs/suites.txt`, `/tmp/u2a3b-fc2-HKGh/logs/mut-nbsp-no-g.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "docs/z.md is imported only after the NUL; gone/ does not exist, and the path is still resolved as written", with test name "… a NUL hides no import …"

**Location:** `test/scripts/build-loop-check.bats:26`, `:28-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's shape and the test's pass. It does not establish that this test alone pins the NUL rule. Under mutant `nul-sed` (no `s/\x0/ /g`), test 1 still reports `docs/z.md: imported` and fails only on bash's "ignored null byte" stderr check. The parser test's `@docs/h.md\0@docs/i.md` is the case that loses an import.

`@docs/z.md` appears in the fixture only after `\0` (`:30`), and nothing else imports it. `@gone/../docs/m.md` is resolved with `realpath -ms` (`scripts/lib/dev-cycle-read.sh:513`), which needs no existing directory, and the test wants `docs/m.md imported`. Mutant `nul-sed`, `bats -f "tree walk shares|both walks read"`, exit 1: both test 1 (at `:38`, the stderr assertion) and test 2 fail (`mut-nul-sed.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:26-41`; `scripts/lib/dev-cycle-read.sh:501`, `:513`; `/tmp/u2a3b-fc2-HKGh/logs/mut-nul-sed.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "Docs/NB.MD and CLAUDE.md: isimported takes a path in any case."

**Location:** `test/scripts/build-loop-check.bats:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk's isimported. It does not establish non-ASCII case folding (`lower` is ASCII-only).

`isimported` does `lp="$(lower "$2")" || return 0` (`scripts/lib/dev-cycle-read.sh:637`) and matches the lower-cased IMPORTED list (`:640`). The test passes with `Docs/NB.MD` and `CLAUDE.md` in `ps` (`suites.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:634-643`; `test/scripts/build-loop-check.bats:36-40`; `/tmp/u2a3b-fc2-HKGh/logs/suites.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "Without ROOT_REAL it stops (need_root) for any walk name, before answering."

**Location:** `test/scripts/build-loop-check.bats:47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unknown-walk-name branch the test exercises. It does not establish exit-vs-return for callers that run isimported in a subshell.

`isimported` calls `need_root` at `:636`, before `case "$1"`. `need_root` does `exit 1` with "ROOT_REAL is not set" (`scripts/lib/dev-cycle-read.sh:95`). The test passes (`suites.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:94-98`, `:634-643`; `/tmp/u2a3b-fc2-HKGh/logs/suites.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: test "both walks: every Unicode space JavaScript's \s holds ends a token; SKILL.md and an untracked upper-case .MD start the walk (U2a3b)", with comment "U+00A0, U+1680, U+2000-200A, U+2028, U+2029, U+202F, U+205F, U+3000, U+FEFF as UTF-8."

**Location:** `test/scripts/build-loop-check.bats:53-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 19 non-ASCII members of JavaScript's `\s` (ASCII blanks are `[:space:]`), the `sub/SKILL.md` start, the untracked `docs/AGENTS.MD` start, and both walks. It does not establish JavaScript engines that still treat U+180E as a space.

The 19 escapes at `:56-58` are the listed code points in UTF-8, the same 19 as `UNI_SPACES` (`scripts/lib/dev-cycle-read.sh:479-481`). The loop runs `for w in tree main` (`:63`) and asserts `want walk ok` and every `docs/u$i.md` plus `docs/k.md`. `docs/AGENTS.MD` is written after `commit_all`, so it is untracked. Mutants: `drop-1680` (U+1680 removed from UNI_SPACES) fails with `want: docs/u1.md: imported`, and `untracked-no-icase` fails with `want: docs/k.md: imported` (both exit 1, `bats -f "every Unicode space"`).

**Evidence:** `test/scripts/build-loop-check.bats:53-68`; `scripts/lib/dev-cycle-read.sh:479-481`, `:527`; `/tmp/u2a3b-fc2-HKGh/logs/mut-drop-1680.txt`, `/tmp/u2a3b-fc2-HKGh/logs/mut-untracked-no-icase.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: test "both walks read what Claude Code reads: an @ after a Unicode space, Markdown and a code span around a token, ( ) in a name; ~x is over-read, ~/ dropped (U2a3)"

**Location:** `test/scripts/build-loop-check.bats:292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser test's shapes over both walks, and "over-read" against 2.1.292's path filter. It does not establish Claude Code's Markdown handling beyond the shapes in the fixture.

The fixture adds `` @docs/j.md\x60x\x60 `` and `@~/x.md` (`:295`), wants `docs/j.md` imported and `want '~/x.md' -` (`:301`), and runs `for w in tree main`. On the over-read: iteration 1's Claim 23b quotes 2.1.292's path filter, which accepts only `./`, `~/`, `/` or a `[a-zA-Z0-9._-]` first character. `~g.md` fails every branch, so Claude Code never loads it, while the walks list it (`ps` holds `'~g.md'`). Mutants `backtick-cut` (fails with `want: docs/j.md: imported`) and `tilde-drop` (fails with `want: ~/x.md: -`) both fail this test (exit 1).

**Evidence:** `test/scripts/build-loop-check.bats:292-303`; `scripts/lib/dev-cycle-read.sh:509`, `:512`; `docs/reviews/code-fact-check-report-build-loop-u2a3b.md` Claim 23b; `/tmp/u2a3b-fc2-HKGh/logs/mut-backtick-cut.txt`, `/tmp/u2a3b-fc2-HKGh/logs/mut-tilde-drop.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: test "both walks fail closed when tr fails or the start listing fails, and the parser returns 1 when it cannot read its input (U2a3)"

**Location:** `test/scripts/build-loop-check.bats:305`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what this test exercises per walk. It does not establish main_imports' listing failures, which test `:225` covers instead.

In this test, "the start listing fails" is exercised only for the tree walk (`:320-326`: `printf 'junk' > .git/index`, then `imported_names` and `isimported tree`). The main walk is never run against the corrupt index here. Main's listing failure is covered by the separate test `:225` "main walk returns, not exits, when main's tree or the untracked list cannot be listed". The tr half covers both walks, but differently. For main, `want walk failed` (`:311`) is main_imports' own failure, confirmed by tracing it to its candidate check (`main-tr.txt`: `+ [[ 0 -eq 1 ]]` / `+ return 1`). For tree, the `imps` loop answers "imported" from isimported's own `lower` at `:637` before any walk runs. The tree walk's tr failure is proven only by the direct `imported_names` calls at `:315-316`. A precise name would say the start-listing half is the tree walk's.

**Evidence:** `test/scripts/build-loop-check.bats:225-239`, `:305-327`; `scripts/lib/dev-cycle-read.sh:588-589`, `:637`; `/tmp/u2a3b-fc2-HKGh/logs/main-tr.txt`
**Legibility-target:** for-author

---

## Claim 13: "The tree walk itself, called twice: the second call returns its cached error."

**Location:** `test/scripts/build-loop-check.bats:313`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache return at `:531` after a lower failure. It does not establish caching across a ROOT_REAL change.

Mutant `cached-error` (`:531` → `{ return 0; }`) fails this test at `:319` with output `failed / walk failed / walked` (exit 1). That shows the second call is what reaches the cache.

**Evidence:** `scripts/lib/dev-cycle-read.sh:531-532`; `test/scripts/build-loop-check.bats:313-319`; `/tmp/u2a3b-fc2-HKGh/logs/mut-cached-error.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "A corrupt index: git ls-files fails, so the tree walk has no start list."

**Location:** `test/scripts/build-loop-check.bats:320`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that this case reaches the new rc check, rather than failing earlier. It does not establish that a corrupt index fails only ls-files (`untracked_md` also fails on it).

`need_root` passes, because `.git` exists (`:97`). git prints `fatal: .git/index: index file smaller than expected`, and the walk returns 1 at `:535` (`probe1.txt`). Mutant `listing-check` (`:535` → `:`) fails this test at `:326` with output `walked`, so the assertion is reached only through the new check. The same fixture at 1ccc8b65 answers `docs/a.md: -` (not imported), and at 7ddff454 it answers `imported` (`r2-old-new.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:94-98`, `:534-535`; `test/scripts/build-loop-check.bats:320-326`; `/tmp/u2a3b-fc2-HKGh/logs/mut-listing-check.txt`, `/tmp/u2a3b-fc2-HKGh/logs/r2-old-new.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: commit 7ddff454, R1: "for "Read @docs/a.md" followed by a closed code span, --check-fix said ok for docs/a.md where 45ad17b0 said skip and Claude Code imports it. The cut set now holds a backtick ($'\x60' in a variable, quoted in the pattern)."

**Location:** commit 7ddff454 message, bullet R1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser's output on the adjacent code-span shape at the three commits. The --check-fix wording rests on its use of the tree walk, which was not re-run here.

For input `` Read @docs/a.md`code` ``, 45ad17b0 yields `docs/a.md`, 1ccc8b65 yields only `` docs/a.md`code` `` and `` docs/a.md`code ``, and 7ddff454 adds `docs/a.md` (`r1-shapes.txt`). Claude Code 2.1.292 skips `codespan` tokens and scans the preceding text token (`docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:11`). The implementation is `b=$'\x60'` (`:501`) and `"${t%%[][()<!*_"$b"]*}"` (`:509`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:501`, `:509`; `/tmp/u2a3b-fc2-HKGh/logs/r1-shapes.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16a: commit 7ddff454, R2: "imported_names never checked its start listing …, so a failing ls-files gave an empty walk that reads "not imported". The listing now ends with rc=0 only when it succeeded, as in main_imports … The header lists the failures that return 1 and that a cached error returns 1 again."

**Location:** commit 7ddff454 message, bullet R2
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the before/after behavior on a corrupt index and the header's content. It does not cover instruction_names' status (16b).

1ccc8b65 answers `docs/a.md: -`, and 7ddff454 answers `imported` (`r2-old-new.txt`). Claims 1 and 5 cover the rest.

**Evidence:** `scripts/lib/dev-cycle-read.sh:450-455`, `:534-535`; `/tmp/u2a3b-fc2-HKGh/logs/r2-old-new.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16b: commit 7ddff454, R2: "instruction_names returns grep's error status"

**Location:** commit 7ddff454 message, bullet R2; `scripts/lib/dev-cycle-read.sh:524`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers instruction_names' exit status and all its callers in the repo. It does not establish a test that pins the change, because none does.

```bash
# scripts/lib/dev-cycle-read.sh:524
instruction_names() { env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$' || [[ $? -eq 1 ]]; }
```

On a grep error, the function returns the status of `[[ 2 -eq 1 ]]`, which is 1, not grep's status. Executed: a grep shim exiting 2 gives `grep2 rc=1`, and no match gives `nomatch rc=0` (`instnames.txt`). The precise version is "instruction_names returns non-zero (1) on a grep error". For callers, `rg -n instruction_names` outside docs/reviews finds only the definition, the call at `:534`, and the function list in `test/scripts/dev-cycle.bats:1086`. Nothing in `scripts/dev-cycle.sh` or `build-loop.sh` calls it, so no caller breaks. Mutant `instnames-true` (back to `|| true`) passes the whole build-loop-check suite (exit 0). The status change is untested, and the iteration-1 Defer row does not list it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:524`, `:534`; `test/scripts/dev-cycle.bats:1085-1086`; `/tmp/u2a3b-fc2-HKGh/logs/instnames.txt`, `/tmp/u2a3b-fc2-HKGh/logs/mut-instnames-true.txt`
**Legibility-target:** for-author

---

## Claim 17: commit 7ddff454, A1: "the token comment says Claude Code cuts the name at # after capturing it (ending at # only over-reads), and names the escaped space as A5."

**Location:** commit 7ddff454 message, bullet A1
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the comment says these things. Whether A5 covers the escaped space is Claim 3.

The comment reads "and at #, where Claude Code cuts the name it captured (so a token after a # is an over-read; a backslash-escaped space is known issue A5)" (`scripts/lib/dev-cycle-read.sh:489-490`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:487-490`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: commit 7ddff454, A2/A3: "the parser test is renamed (~x is an over-read; Claude Code never loads it) and checks that @~/x.md is dropped; the tr test asserts the main walk fails, calls imported_names twice (cached error) and adds a corrupt index (tree walk fails, isimported answers imported)."

**Location:** commit 7ddff454 message, bullet A2/A3
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed test change. The test name's imprecision is Claim 12.

The diff shows the rename and `want '~/x.md' -` (`:292`, `:301`), `want walk failed` (`:311`), the two `imported_names` calls (`:315-316`), and the corrupt index with `docs/z.md: imported` (`:320-326`). Claims 11, 13 and 14 executed each one.

**Evidence:** `test/scripts/build-loop-check.bats:292-327`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: commit 7ddff454, C2: "test-strategy final Patch A from U2a2 (override row 362), applied as checked; its new test runs over both walks."

**Location:** commit 7ddff454 message, bullet C2
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the match between Patch A's diff and the landed test. It does not establish that every Patch A case still kills a mutant under the new parser (the two-NBSP case no longer does; Claim 6).

Patch A in `docs/reviews/test-strategy-review-2026-10-06-final-build-loop-u2a2.md:152-198` matches the landed hunks line for line. The one difference is the new test, which Patch A wrote as `@test "tree walk: …"` with `imps tree`. It landed as `"both walks: …"` with `for w in tree main` and `want walk ok`, and the message says so. Override row 362 reads "Checked patch A in the report's Appendix. Revisit trigger: U2a3b's first review applies the parts that still apply".

**Evidence:** `docs/reviews/test-strategy-review-2026-10-06-final-build-loop-u2a2.md:152-198`; `docs/reviews/override-log.md:362`; `test/scripts/build-loop-check.bats:26-68`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: commit 7ddff454: "Commit-message claims on 1ccc8b65 (A4) are Accepted-immutable rows; the surviving mutants (C1) are a Defer row."

**Location:** commit 7ddff454 message, closing paragraph
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two rows this range adds to the override log. It does not establish that the Defer row lists every surviving mutant (Claim 16b's `instnames-true` is not in it).

The range adds two `feat/build-loop-u2a3b` rows. The first is "Commit 1ccc8b65's message: …" with disposition `Accepted-immutable`. The second is "Mutants no test kills: …" with `🟢 Consider (Low) | Defer` (`git diff 45ad17b0..7ddff454 -- docs/reviews/override-log.md`).

**Evidence:** `docs/reviews/override-log.md` (the last two rows added in the range)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: commit 7ddff454: "Mutants of the backtick cut, the listing check, the cached error and the ~/ drop each fail a test."

**Location:** commit 7ddff454 message, closing paragraph
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one natural mutant of each named control. It does not establish the other mutants (Claims 6, 16b and the iteration-1 Defer row survive).

Command per mutant: `python3 -I mut.py scripts/lib/dev-cycle-read.sh <m>; TMPDIR=$(mktemp -d /tmp/u2a3b-fc2-tmp-XXXX) timeout 600 bats test/scripts/build-loop-check.bats`, cwd `/tmp/u2a3b-fc2-HKGh`, 23:48-23:49Z:

| Mutant | Change | Exit | Failing |
|---|---|---|---|
| backtick-cut | `[][()<!*_"$b"]` → `[][()<!*_]` | 1 | test 16 (`want: docs/j.md: imported`) |
| listing-check | `:535` → `:` | 1 | test 17 at `:326` (`walked`) |
| cached-error | `:531` → `{ return 0; }` | 1 | test 17 at `:319` |
| tilde-drop | drop `&& "$w" != \~/*` | 1 | test 16 (`want: ~/x.md: -`) |

**Evidence:** `/tmp/u2a3b-fc2-HKGh/mut.py`; `/tmp/u2a3b-fc2-HKGh/logs/mut-backtick-cut.txt`, `mut-listing-check.txt`, `mut-cached-error.txt`, `mut-tilde-drop.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: commit 7ddff454: "Tests: 115/115 across the five suites; shellcheck clean"

**Location:** commit 7ddff454 message, closing paragraph
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five named suites, and shellcheck on the changed `.sh` file. It does not establish shellcheck on the `.bats` file. That file reports findings at both 45ad17b0 and 7ddff454 and is outside the health check's ".sh/.bash" scope (`scripts/health-check.sh:34`).

`TMPDIR=$(mktemp -d /tmp/u2a3b-fc2-tmp-XXXX) bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`, cwd `/tmp/u2a3b-fc2-HKGh`, 2026-10-06T23:47:19Z, exit 0, with 115 `ok` and 0 `not ok`. `shellcheck scripts/lib/dev-cycle-read.sh` exits 0 (23:50:27Z).

**Evidence:** `/tmp/u2a3b-fc2-HKGh/logs/suites.txt`, `/tmp/u2a3b-fc2-HKGh/logs/shellcheck.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: commit 7ddff454: "155 changed code lines against 45ad17b0"

**Location:** commit 7ddff454 message, closing paragraph
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pr-prep step 1a's count (outside `docs/`) for 45ad17b0..7ddff454. It does not establish the U2a3 base's count.

`git diff --numstat 45ad17b0..7ddff454 -- . ':!docs'` gives `57 33 scripts/lib/dev-cycle-read.sh` and `63 2 test/scripts/build-loop-check.bats`, so 120 + 35 = 155. This is the method in `workflows/pr-prep.md:86-91`.

**Evidence:** `workflows/pr-prep.md:86-91`; command run in `/workspace/.claude/wt-build-loop-u2a3b`, 23:50Z, exit 0
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: commit 7ddff454 Notes: "main_imports' own lower guard is reached only after its candidate check, which already fails on a failing tr (C1)."

**Location:** commit 7ddff454 message, Notes
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a tr that always fails. It does not establish a tr that fails only on some calls, which could reach the guard at `:622`; that guard stays unpinned (Defer row).

```bash
# scripts/lib/dev-cycle-read.sh:588-589
  [[ ${#cand[@]} -eq 0 ]] || mapfile -d '' low < <(printf '%s\0' "${cand[@]}" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')
  [[ ${#low[@]} -eq ${#cand[@]} ]] || return 1
```
(excerpt ends :589; enclosing main_imports() continues to :628 — read; the guard `i="$(lower "$p")" || { IMPORTED_MAIN=error; return 1; }` is at :622, inside the queue loop. That loop is empty when `cand` is empty.)

The xtrace under a failing tr ends `+ [[ 0 -eq 1 ]]` / `+ return 1` / `main failed` (`main-tr.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-628`; `/tmp/u2a3b-fc2-HKGh/logs/main-tr.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 3** (`scripts/lib/dev-cycle-read.sh:490`): "a backslash-escaped space is known issue A5". The routing is in override rows 350/356, but A5's text (`docs/working/known-issues-dev-cycle.md:18`) never mentions a backslash or an escaped space. Add it to A5, or point the comment at row 350. This is comment/doc only.
- **Claim 12** (`test/scripts/build-loop-check.bats:305`): "both walks fail closed when … the start listing fails". In this test, only the tree walk meets a failing listing; main's listing failure is in test `:225`. Narrow the name.
- **Claim 16b** (commit 7ddff454, R2; `scripts/lib/dev-cycle-read.sh:524`): "instruction_names returns grep's error status". It returns 1, not grep's 2. Nothing pins the change: the `|| true` mutant passes the suite.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: 7ddff454` line at the top.
- Answered: yes. All six dispatch focus items were checked, by execution and mutants where executable. R1 and R2 are complete for the shapes named, and they introduce no behavioral defect. The new listing check fails closed for every component tested, and passes for empty and non-empty listings.
- Out of scope: the hallucination-pattern log update (there were no fabrications, and the dispatch allows only this file in the worktree). Execution logs are in `/tmp/u2a3b-fc2-HKGh/logs/` for the same reason.
- Escalate (test-strategy): two controls this range adds or relies on are unpinned. instruction_names' new grep-error status (the `|| true` mutant survives; not in the iteration-1 Defer row), and the sed `g` flag on UNI_SPACES (the `nbsp-no-g` mutant survives; Patch A's two-NBSP case no longer kills anything under the new parser). Both are low severity, because each failure mode needs a grep error or two Unicode spaces before an `@` on one line.
- Decisions I made: I rated Claim 3 Mostly accurate rather than Incorrect, because the ledger routes the escaped space to A5 and only A5's prose is missing it. I counted Claim 23 with pr-prep 1a's exclusion of `docs/`. I treated "shellcheck clean" as covering the `.sh` file, per the health check's scope.
