Commit: 98e3b1df

# Test Strategy: feat/build-loop-u2a3b, loop 2 iteration 2 (fixes dd51e9a7, 98e3b1df)

**Scope:** `git diff be94c871..98e3b1df -- . ':!docs/reviews'`: `scripts/lib/dev-cycle-read.sh` (IMPORT_AWK, import_targets, imported_names, main_imports), `scripts/dev-cycle.sh` (wording), `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`
**Reviewed:** 2026-10-07
**Method:** I read the whole of IMPORT_AWK, import_targets, imported_names and main_imports at 98e3b1df, then ran 31 mutants of the range's fixes on `git archive 98e3b1df` copies (`/tmp/u2a3btsL2i2-jjzK/`: `mut.py`, `runall.sh`, `runm.sh`; logs `mut-base.log` and `mut-pat.log`). Each mutant ran against build-loop-check.bats and against dev-cycle.bats `-f 'check-fix|import|sourced|IMPORTED'`. I re-ran every mutant with the Appendix A tests added. I ran the patch, and the patch plus the Appendix B fix sketch, through four suites in full (build-loop-check, dev-cycle, build-loop-read, fixture-git-env).

## Stage-1 escalations

- **Claim 31b** (the leading-escaped-space case pinned as a Claude Code read). Confirmed by mutation: the trim mutants N01 and N02 are killed only by the U+FFFD test's `want docs/lead.md imported`. That assertion pins an over-read as though it were a superset requirement. Appendix A moves it into the over-read test, which states the deletable-on-purpose convention. See F1.
- **Claim 9** (`~/` into the repo). No test covers it. Appendix A adds a test marked `FAILS at 98e3b1df`. It fails at HEAD in both walks, and the Appendix B sketch makes it pass, with 138/138 across the four suites. See F2. Its premise (that Claude Code's in-project check `AD()` admits the path) is not verified against Claude Code, so this needs a decision (Escalate).

## Test Conventions

- bats 1.8.2, with `test/lib/build-loop-fixtures.bash` (`bl_setup`: a throwaway repo at `$BATS_TEST_TMPDIR/repo`, `HOME=$BATS_TEST_TMPDIR/home`, `LC_ALL=C`). `imps WALK PATH...` prints `walk: ok|failed` and one `PATH: imported|-` line per path, and `want` asserts one line. Each case loops `for w in tree main`.
- Fault injection uses PATH shims in `$BATS_TEST_TMPDIR`. Parser probes source the lib inside `bash -c`. A test that should fail until a hole is closed carries `FAILS at <sha>` in its title, and a deferred hole gets `skip "<row>"` as its first line.
- At 98e3b1df the two filtered suites hold 42 tests, all passing (about 10 s here).

## Do the range's tests assert the contract?

| Test (build-loop-check.bats unless noted) | Contract or implementation | Note |
|---|---|---|
| superset test (`:339`): escaped space, absolute path | Contract | Both are real Claude Code imports (L2-i1 Claim 29) |
| over-read test (`:365`) | Recorded over-read, labelled | The comment states the deletable-on-purpose convention. The work-bound probe now asserts `rc=1`, which import_targets' header states ("It returns 1 when ..."), so it is contract. The comment "the sixth run trips it" describes the accounting, but it is only a comment. |
| `.git` prefix in a linked worktree (`:389`) | Contract | It covers only `.git` itself, not `.git/*` (N27; F8) |
| IMPORT_OUT_MAX (`:398`) | Partly | It sets the knob directly (acceptable). The fixture is a single file, so it cannot tell a walk-wide bound from a per-file one, and the walk-wide bound is exactly what L2-A4 fixed (F3) |
| classes 1-4, splice, comments (`:481-550`) | Contract | Harness-backed imports. The comments test accepts any nonzero status except 124 |
| U+FFFD (`:552`) | Mixed | `docs/c.md` through U+FFFD is contract. `docs/lead.md` is an over-read under a "decodes it" title (F1) |
| 4 MiB (`:562`) | Contract, one-sided | It proves the walk does not stall. It does not prove the cap keeps everything Claude Code loads (N29 and N30 survive; F7) |
| dev-cycle.bats `:1059`, `:1066`, and the reworded `names it` asserts | Contract | User-facing wording, pinned on purpose |

## Mutation results (31 mutants, scratch copy)

| Mutant | Change | At 98e3b1df | With Appendix A |
|---|---|---|---|
| N01 | no trim | killed (U+FFFD test, over-read) | killed by the over-read test only (correct label) |
| N02 | no leading trim | killed (same) | same |
| N03 | no trailing trim | survived | survived: equivalent (the untrimmed prefix is emitted anyway; Claim 13) |
| N04 | relative name not rooted | killed | killed |
| N05 | `..` at k==0 returns (old rule) | **survived** | killed (`..` past `/`) |
| N06 | drop `length(out) <= length(pre)` | survived | survived: equivalent (out never ends in `/`, pre always does) |
| N07 | `pre = root "/"` for root `/` | **survived** | killed (ROOT_REAL `/`) |
| N08 | `pre = root` (no slash) | killed | killed |
| N09 | no `root == ""` exit | **survived** | killed (empty ROOT_REAL) |
| N10 | back to `awk -v` | killed | killed |
| N11 | 4096 cap restored | killed | killed |
| N12 | splice outside the bound | killed | killed |
| N13 | no `\|\| return 1` after awk | killed | killed |
| N14 | no `local LC_ALL=C` | survived | survived: equivalent here (below) |
| N15 | python block never runs | killed | killed |
| N16 | python3 failure ignored | **survived** | killed (python3 shim) |
| N17 | decoded text replaces raw | survived | survived: precision only (raw invalid bytes are never a Claude Code name) |
| N18 | decode always | survived | survived: cost only |
| N19 | no head cap | killed | killed |
| N20 | head 4096 | killed (long-name test) | killed |
| N21 | no tree OUT_MAX check | killed | killed |
| N22 | no main OUT_MAX check | killed | killed |
| N23 | tree bound per file (`used =`) | **survived** | killed |
| N24 | main bound per file | **survived** | killed |
| N25 | tree `<` for `<=` | **survived** | killed |
| N26 | no `.git` skip | killed | killed |
| N27 | skip `.git` only, not `.git/*` | **survived** | killed (`@.git/HEAD`) |
| N28 | also skip `*/.git`, `*/.git/*` | survived | survived: a broadening, not a defect (F8) |
| N29 | head 1 MiB | **survived** | killed (exact 4 MiB) |
| N30 | head 4194303 | **survived** | killed |
| N31 | head 4194304 | survived | survived: equivalent (a file over 4194304 bytes is one Claude Code skips) |

**The LC_ALL=C guard (N14), as you expected, survives, and here it is equivalent.** Bash's range test `*[$'\x80'-$'\xff']*` matched in C.utf8 for every byte 0x80-0xff and for 17,502 sampled code points, U+0080 to U+10FFFF (executed, `loc2.sh`). The only locales installed are C, C.utf8 and POSIX. A locale where this differs cannot be built on this machine, so no test here can kill N14. I would not add one. The guard is defensive and costs nothing.

## Findings

**F1 — Severity: low (a test pins an over-read under a contract title). Location** `test/scripts/build-loop-check.bats:552-560`. **Evidence:** `@test "both walks read a name as Claude Code decodes it: an invalid UTF-8 byte is U+FFFD; a leading escaped space is trimmed (U2a3b L2 security F1)"` with `printf 'See @docs/\xff.md and @\\ docs/lead.md\n'` and `want docs/lead.md imported`. Claude Code's `reo` filter rejects ` docs/lead.md` (fact-check Claim 31b). N01 and N02 are killed only by this assertion, so a more precise parser that is still a superset would be told it broke the superset. **Fix:** Appendix A moves the case into the over-read test (`:365`) and adds docs/lead.md to that test's "Claude Code reads none of" comment. After the move, N01 and N02 are killed by the over-read test only. The emit comment "(an escaped space can lead it)" (`scripts/lib/dev-cycle-read.sh:525`) needs the same relabel. That is the author's change and is not in the patch. **Confidence:** high (executed). **Legibility-target:** for-author.

**F2 — Severity: medium (superset hole with no test). Location** `scripts/lib/dev-cycle-read.sh:526`. **Evidence:** `if (c == "" || substr(c, 1, 2) == "~/") return`. Claude Code joins `~/` to `homedir()` (Claim 9). A repo under `$HOME` imported as `@~/<repo>/docs/x.md` is read by Claude Code, but neither walk reads it. The superset test pins only that `~/x.md` is not taken as a repo-relative path (`want '~/x.md' -`). **Fix:** Appendix A test "@~/ import into a repo under HOME" (`FAILS at 98e3b1df`; it fails in both walks). The Appendix B sketch resolves `~/` against `$HOME` (passed as `IT_HOME`) and passes 138/138. If the sketch is taken, the superset comment's "~/ names are dropped." and the superset test's "~/ dropped" title need rewording. The sketch compares lexically, so a `$HOME` path with a symlink component would still miss. If the orchestrator instead names `~/` as a known exception, give the test `skip "<row>"` and do not drop it. **Confidence:** medium. The test's premise rests on Claim 9's binary reading, and `AD()` was not traced. **Legibility-target:** for-orchestrator-synthesis. Executed (the test fails at HEAD and passes with B).

**F3 — Severity: medium (fix-drift in the test evidence for L2-A4). Location** `scripts/lib/dev-cycle-read.sh:618,694`; test `test/scripts/build-loop-check.bats:398-404`. **Evidence:** `(( (used += ${#out}) <= IMPORT_OUT_MAX ))`. The test's fixture is a single `printf 'see @docs/a.md\n' > AGENTS.md` with `IMPORT_OUT_MAX=10`. L2-A4's disposition reads "the work bound is per file; the bash side has no walk-wide limit … Fixed … tested; mutant fails". Only the removal mutants (N21, N22) fail. The per-file mutants N23 and N24 (`used = ${#out}`) pass every test, so the walk-wide property the row claims is not asserted. **Fix:** Appendix A test "IMPORT_OUT_MAX bounds what the whole walk prints". Two files print 13 bytes each: a limit of 20 fails both walks, 25 fails, and 26 passes. It kills N23, N24 and N25. **Confidence:** high (executed). **Legibility-target:** for-orchestrator-synthesis (the row's "tested" claim).

**F4 — Severity: low (an error branch with no test). Location** `scripts/lib/dev-cycle-read.sh:574`. **Evidence:** `d="$(printf '%s\n' "$toks" | python3 -I -c '…')" || return 1`. N16 (`|| true`) survives. Without the `return 1`, a missing or broken python3 silently drops every U+FFFD name, which is the fail-open that L2-A1 closed. **Fix:** Appendix A python3-shim test: both walks fail, and every path answers imported. **Confidence:** high (executed). **Legibility-target:** for-author.

**F5 — Severity: low (two BEGIN branches with no test). Location** `scripts/lib/dev-cycle-read.sh:561`. **Evidence:** `pre = (root == "/") ? "/" : root "/"; if (root == "") exit 2`. N07 survives: with root `/`, the mutant keeps nothing and so drops every import. N09 survives as well: an empty ROOT_REAL resolves everything below `/` and returns 0. The walks are shielded by need_root, but the header's promise that import_targets "returns 1 … when ROOT_REAL is empty" has no test. **Fix:** the Appendix A parser test for ROOT_REAL `/` and ROOT_REAL empty. **Confidence:** high (executed). **Legibility-target:** for-author.

**F6 — Severity: low (the clamp the fix introduced has no test). Location** `scripts/lib/dev-cycle-read.sh:531`. **Evidence:** `if (part[i] == "..") { if (k > 0) k--; continue }`. N05 restores the old `if (k == 0) return` and survives, because every re-entry test climbs only as far as the root's own depth. The comment's ".. stopping at / as Node's path.resolve does" is not pinned. `node -e 'path.resolve("/a/b","../../../../../a/b/c")'` prints `/a/b/c` (executed). **Fix:** Appendix A test with 40 `../` before the absolute root. It is [unverified against the 2.1.292 harness]: it rests on Node's `path.resolve`, which the comment names. **Confidence:** medium-high. **Legibility-target:** for-author.

**F7 — Severity: low (one side of the cap's boundary has no test). Location** `scripts/lib/dev-cycle-read.sh:616`. **Evidence:** `head -c 4194305 -- "$f"`. The 300 MB test shows only that the walk does not stall. Caps of 1 MiB (N29) and 4194303 (N30) survive, and either would drop an import from a file Claude Code loads, because Claude Code reads a file of up to `nH=4194304` bytes whole (Claim 18). **Fix:** Appendix A test: a file of exactly 4194304 bytes whose last 14 bytes are `\n@docs/late.md`. It kills N29 and N30. N31 (4194304) stays equivalent. **Confidence:** high (executed). **Legibility-target:** for-author.

**F8 — Severity: informational (the `.git` skip covers half its stated range, and nested repos fail closed). Location** `scripts/lib/dev-cycle-read.sh:703`. **Evidence:** `[[ "$p" != .git && "$p" != .git/* ]] || continue`. N27 (drop the `.git/*` half) survives. In a plain checkout, `@.git/HEAD` names a checkout file main lacks, so without that half the walk fails. Appendix A adds the plain-checkout test, which kills N27. A probe (scratch only) put a linked worktree at `sub/` with `@sub/.gitignore`. The main walk failed (`walk: failed`) and the tree walk was ok. That is the L2-A6 shape one level down. It fails closed, so I recommend no test. N28 (also skipping `*/.git` and `*/.git/*`) is exact for the same reason the top-level skip is, because git stores no path with a `.git` component, and it passes every suite. Consider it if U2a3c meets this. **Confidence:** high (executed). **Legibility-target:** for-author.

**F9 — Severity: informational (the comment does not match the code). Location** `scripts/lib/dev-cycle-read.sh:482-485`. **Evidence:** `# Each walk fails once import_targets has printed this many bytes in all`, against `<= IMPORT_OUT_MAX` (it fails only past the limit; Appendix A's 26 case passes at exactly the limit). Also, `${#out}` counts characters, and neither walk sets LC_ALL. Under a UTF-8 caller locale, then, a U+FFFD name counts 1 where it is 3 bytes. That makes the bound looser, not unsafe. **Fix:** "more than this many characters". **Confidence:** medium (reasoned for the locale half). **Legibility-target:** for-author.

## Untested Paths Touched by the Change

- **G1** — test/scripts/build-loop-check.bats:552-560 — the leading-escaped-space case pinned as a Claude Code read, which it is not — mislabelled (an over-read)
- **G2** — scripts/lib/dev-cycle-read.sh:526 — a `~/` name that resolves into a repo under `$HOME` — not covered (and missed by the parser)
- **G3** — scripts/lib/dev-cycle-read.sh:618,694 — `used` accumulating across files, as opposed to per file — not covered; the only test has one file
- **G4** — scripts/lib/dev-cycle-read.sh:618 — the boundary at exactly IMPORT_OUT_MAX (`<=`) — not covered
- **G5** — scripts/lib/dev-cycle-read.sh:574 — `|| return 1` when python3 fails — not covered
- **G6** — scripts/lib/dev-cycle-read.sh:561 — `pre = "/"` when ROOT_REAL is `/` — not covered
- **G7** — scripts/lib/dev-cycle-read.sh:561 — `exit 2` (returned as 1) when ROOT_REAL is empty — not covered at the parser
- **G8** — scripts/lib/dev-cycle-read.sh:531 — `..` clamped at `/` (k == 0) — not covered; the re-entry tests never reach `/`
- **G9** — scripts/lib/dev-cycle-read.sh:616 — a file of exactly 4194304 bytes read to its last byte — not covered; only the stall side is tested
- **G10** — scripts/lib/dev-cycle-read.sh:703 — the `.git/*` arm of the skip in a plain checkout — not covered
- **G11** — scripts/lib/dev-cycle-read.sh:703 — a nested `sub/.git` prefix candidate (the main walk fails closed) — not covered
- **G12** — scripts/lib/dev-cycle-read.sh:564 — `local LC_ALL=C` — not covered (equivalent on this host)

## Recommended Tests

All of these are in Appendix A. On their own they leave exactly one test failing at 98e3b1df: G2's, by design.

#### Over-read relabel
**Closes gaps:** G1 · **Type:** unit (walk) · **Priority:** medium · **File:** build-loop-check.bats `:365`, `:552`
**What it verifies:** `@\ docs/lead.md` is read, and it is recorded as an over-read rather than as a Claude Code read.
**Key cases:** `want docs/lead.md imported` moves to the over-read test, and the U+FFFD test keeps only `docs/\xff.md` → `docs/�.md` → `docs/c.md`.

#### `~/` into a repo under HOME (FAILS at 98e3b1df)
**Closes gaps:** G2 · **Type:** unit (walk) · **Priority:** medium (pending the escalation) · **File:** build-loop-check.bats
**Key cases:** `HOME=<repo's parent>`, `@~/repo/docs/home.md` → both walks give `docs/home.md imported` and `docs/other.md -`.

#### Walk-wide IMPORT_OUT_MAX and its boundary
**Closes gaps:** G3, G4 · **Type:** unit · **Priority:** medium · **File:** build-loop-check.bats
**Key cases:** AGENTS.md `@a.md` and GEMINI.md `@b.md` print 13 bytes each. A limit of 20 fails both walks, 25 fails both, and 26 passes both.

#### python3 failure fails closed
**Closes gaps:** G5 · **Type:** unit (fault injection) · **Priority:** medium · **File:** build-loop-check.bats
**Key cases:** a `python3` shim that exits 1, and AGENTS.md holding `\xff` → `walk failed`, with every path answering imported, in both walks.

#### ROOT_REAL `/` and empty
**Closes gaps:** G6, G7 · **Type:** unit (parser) · **Priority:** low
**Key cases:** with ROOT_REAL `/`, `@/etc/x.md`, `@docs/a.md` and `@../b.md` from `sub` print `etc/x.md`, `sub/docs/a.md`, `b.md` and rc=0. With ROOT_REAL empty, the result is rc=1.

#### `..` past `/`
**Closes gaps:** G8 · **Type:** unit (walk) · **Priority:** low
**Key cases:** 40 `../` followed by `<root without its leading slash>/docs/up.md` → imported in both walks.

#### Exactly 4 MiB
**Closes gaps:** G9 · **Type:** unit (tree walk) · **Priority:** low (about 0.3 s)
**Key cases:** an untracked sparse `big` of 4194304 bytes ending in `\n@docs/late.md` → `ok` and `late`.

#### `.git/*` in a plain checkout
**Closes gaps:** G10 · **Type:** unit (main walk) · **Priority:** low
**Key cases:** CLAUDE.md `@.git/HEAD` → `walk ok` and `.git/HEAD imported`.

## What NOT to Test

- **G11 (nested `sub/.git`):** it fails closed, and the realistic shape, an instruction-file name that runs through an in-repo linked worktree, is rare. Revisit with N28 if U2a3c's checkout reading meets it.
- **G12 (`LC_ALL=C` guard):** no installed locale distinguishes it (N14 is equivalent over all of C.utf8). A test could not fail here.
- **Equivalent mutants** N03, N06, N17, N18 and N31: pinning them would pin implementation.
- **The main walk's missing head cap:** it was deferred in rubric row L2-C5 ("The main walk still reads a blob whole (main's content, reviewed): deferred"). I have no new evidence and do not re-raise it. If it is ever taken up, note one trap: `git cat-file blob | head -c N` under pipefail fails the walk on git's SIGPIPE. `git cat-file -s` before the read, skipping a blob over 4194304 bytes, is exact (Claude Code skips such files), as security F2 suggested.

## Coverage Gaps Beyond Current Scope

**1.** The 2.1.292 harness is not kept (A5). Every "Claude Code reads X" assertion is a transcription that a version bump can silently invalidate. Nothing here can close that; it needs the revisit trigger A5 already names.

## Summary

The tests the range adds mostly assert the contract, but the fixes leave seven of their own branches unasserted: N05, N07, N09, N16, N23, N24, N25, N27, N29 and N30 all survive at 98e3b1df. The most important is F3: L2-A4's walk-wide bound is not distinguished from a per-file bound by any test, despite the row's "tested". F1 is a label fix (Claim 31b). F2 is a real superset hole (Claim 9) with a failing test and a fix sketch, pending a decision on whether to fix it or name it as a known exception. With Appendix A, every non-equivalent mutant is killed. With A and B together, all 138 tests in the four suites pass. As you expected, the LC_ALL=C guard mutant survives, and here it cannot be killed.

## Appendix A: test patch (`git apply --check` against 98e3b1df: OK)

At 98e3b1df it gives 138 tests in build-loop-check, dev-cycle, build-loop-read and fixture-git-env, of which exactly 1 fails (#38, titled `FAILS at 98e3b1df`). With Appendix B, 138/138 pass. Source copy: `/tmp/u2a3btsL2i2-jjzK/tests.patch`.

```diff
diff --git a/test/scripts/build-loop-check.bats b/test/scripts/build-loop-check.bats
index 4bcae02..b72fdc0 100644
--- a/test/scripts/build-loop-check.bats
+++ b/test/scripts/build-loop-check.bats
@@ -362,17 +362,19 @@ scripts/x.sh: imported" ] || { echo "$output $stderr"; return 1; }
     done
 }
 
-@test "the superset over-reads, pinned: an @ after a letter, a prefix that is a file; the work bound fails the walk (U2a3b)" {
+@test "the superset over-reads, pinned: an @ after a letter, a prefix that is a file, a name led by an escaped space; the work bound fails the walk (U2a3b)" {
     # These record the 2026-10-06 over-approximation decision (U2a3b iteration-4
-    # gate): Claude Code 2.1.292 reads neither docs/mail.md nor docs/pre.md. A
-    # parser that is more precise and still a superset may delete these lines on purpose.
+    # gate): Claude Code 2.1.292 reads none of docs/mail.md, docs/pre.md and
+    # docs/lead.md (its path filter rejects a name led by a space; emit's trim
+    # reads it, L2-i2 fact-check Claim 31b). A parser that is more precise and
+    # still a superset may delete these lines on purpose.
     # The code-span and fence cases were already read before the decision.
     mkdir -p docs
     { printf 'Code \x60@docs/span.md\x60 and user@docs/mail.md and @docs/pre.md.bak\n'
-      printf '\x60\x60\x60\n@docs/fence.md\n\x60\x60\x60\n'; } > AGENTS.md
-    for f in span mail pre fence; do printf 'x\n' > "docs/$f.md"; done
+      printf '\x60\x60\x60\n@docs/fence.md\n\x60\x60\x60\n'; printf 'See @\\ docs/lead.md\n'; } > AGENTS.md
+    for f in span mail pre fence lead; do printf 'x\n' > "docs/$f.md"; done
     commit_all superset
-    ps=(docs/span.md docs/mail.md docs/pre.md docs/fence.md)
+    ps=(docs/span.md docs/mail.md docs/pre.md docs/fence.md docs/lead.md)
     for w in tree main; do
         imps "$w" "${ps[@]}" docs/other.md
         [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
@@ -549,13 +551,13 @@ docs/z.md: imported" ] || { echo "$output $stderr"; return 1; }
     [[ "$output" == rc=* && "$output" != rc=0 && "$output" != rc=124 ]] || { echo "$output $stderr"; return 1; }
 }
 
-@test "both walks read a name as Claude Code decodes it: an invalid UTF-8 byte is U+FFFD; a leading escaped space is trimmed (U2a3b L2 security F1)" {
-    mkdir -p docs && printf 'See @docs/\xff.md and @\\ docs/lead.md\n' > AGENTS.md && printf 'see @c.md\n' > docs/$'\xef\xbf\xbd'.md
+@test "both walks read a name as Claude Code decodes it: an invalid UTF-8 byte is U+FFFD (U2a3b L2 security F1)" {
+    mkdir -p docs && printf 'See @docs/\xff.md\n' > AGENTS.md && printf 'see @c.md\n' > docs/$'\xef\xbf\xbd'.md
     commit_all fffd
     for w in tree main; do
-        imps "$w" docs/$'\xef\xbf\xbd'.md docs/c.md docs/lead.md docs/other.md
+        imps "$w" docs/$'\xef\xbf\xbd'.md docs/c.md docs/other.md
         [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
-        want walk ok; want docs/$'\xef\xbf\xbd'.md imported; want docs/c.md imported; want docs/lead.md imported; want docs/other.md -
+        want walk ok; want docs/$'\xef\xbf\xbd'.md imported; want docs/c.md imported; want docs/other.md -
     done
 }
 
@@ -567,3 +569,65 @@ docs/z.md: imported" ] || { echo "$output $stderr"; return 1; }
         imported_names && echo ok || echo failed; isimported tree docs/early.md && echo early' _ "$LIB"
     [ "$output" = $'ok\nearly' ] || { echo "$status $output $stderr"; return 1; }
 }
+
+@test "both walks fail closed when python3 fails on text holding a byte above 0x7f (U2a3b L2-i2 test-strategy)" {
+    mkdir -p docs && printf 'See @docs/\xff.md and @docs/a.md\n' > AGENTS.md && commit_all py
+    S="$BATS_TEST_TMPDIR/py" && mkdir -p "$S" && printf '#!/bin/sh\nexit 1\n' > "$S/python3" && chmod +x "$S/python3"
+    for w in tree main; do
+        PATH="$S:$PATH" imps "$w" docs/a.md docs/other.md
+        want walk failed; want docs/a.md imported; want docs/other.md imported
+    done
+}
+
+@test "the parser keeps every path below ROOT_REAL /, and returns 1 for an empty ROOT_REAL (U2a3b L2-i2 test-strategy)" {
+    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL=/
+        printf "See @/etc/x.md and @docs/a.md and @../b.md\n" | import_targets sub; echo "rc=$?"
+        ROOT_REAL=""; printf "See @docs/a.md\n" | import_targets "" >/dev/null; echo "rc=$?"' _ "$LIB"
+    for l in etc/x.md sub/docs/a.md b.md rc=0 rc=1; do printf '%s\n' "$output" | grep -qxF "$l" || { echo "missing $l: $output $stderr"; return 1; }; done
+}
+
+@test "both walks read an import whose .. runs past / and re-enters the repo, as Node's path.resolve stops at / (U2a3b L2-i2 test-strategy)" {
+    mkdir -p docs && r="$(pwd -P)"
+    { printf 'See @'; for i in $(seq 40); do printf '../'; done; printf '%s/docs/up.md\n' "${r#/}"; } > AGENTS.md
+    commit_all clamp
+    for w in tree main; do
+        imps "$w" docs/up.md docs/other.md
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
+        want walk ok; want docs/up.md imported; want docs/other.md -
+    done
+}
+
+@test "IMPORT_OUT_MAX bounds what the whole walk prints, not each file, and a walk that prints exactly the limit passes (U2a3b L2-i2 test-strategy)" {
+    # import_targets prints 13 bytes for each file (a, a., a.m, a.md; 26 in all).
+    printf 'see @a.md\n' > AGENTS.md && printf 'see @b.md\n' > GEMINI.md && commit_all two
+    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main || true; ROOT_REAL="$(pwd -P)"
+        for m in 20 25 26; do IMPORT_OUT_MAX=$m; IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""
+            imported_names && echo "$m tree ok" || echo "$m tree failed"; main_imports && echo "$m main ok" || echo "$m main failed"; done' _ "$LIB"
+    [ "$output" = $'20 tree failed\n20 main failed\n25 tree failed\n25 main failed\n26 tree ok\n26 main ok' ] || { echo "$output $stderr"; return 1; }
+}
+
+@test "the tree walk reads a file of exactly 4 MiB to its last byte, as Claude Code loads it (U2a3b L2-i2 test-strategy)" {
+    mkdir -p docs && printf 'See @big/x.md\n' > AGENTS.md && commit_all base
+    # 4194304 bytes in all, the last 14 an import with no newline after it.
+    truncate -s $((4194304 - 14)) big && printf '\n@docs/late.md' >> big && [ "$(wc -c < big)" -eq 4194304 ]
+    run --separate-stderr timeout 20 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
+        imported_names && echo ok || echo failed; isimported tree docs/late.md && echo late' _ "$LIB"
+    [ "$output" = $'ok\nlate' ] || { echo "$status $output $stderr"; return 1; }
+}
+
+@test "both walks read an @~/ import into a repo under HOME, as Claude Code joins ~/ to the home directory (FAILS at 98e3b1df: L2-i2 fact-check Claim 9)" {
+    mkdir -p docs && printf 'See @~/%s/docs/home.md\n' "$(basename "$(pwd -P)")" > AGENTS.md && commit_all home
+    h="$(cd .. && pwd -P)"
+    for w in tree main; do
+        HOME="$h" imps "$w" docs/home.md docs/other.md
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
+        want walk ok; want docs/home.md imported; want docs/other.md -
+    done
+}
+
+@test "the main walk reads a plain checkout whose instruction file names a file under .git (U2a3b L2-i2 test-strategy)" {
+    printf 'See @.git/HEAD\n' > CLAUDE.md && commit_all gitdir
+    imps main .git/HEAD docs/other.md
+    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
+    want walk ok; want .git/HEAD imported; want docs/other.md -
+}
```

## Appendix B: fix sketch for F2 (`git apply --check` against 98e3b1df: OK; 138/138 with Appendix A)

Source copy: `/tmp/u2a3btsL2i2-jjzK/fix.patch`. The superset comment (`:510`, "~/ names are dropped.") and the superset test's title would need rewording with it.

```diff
diff --git a/scripts/lib/dev-cycle-read.sh b/scripts/lib/dev-cycle-read.sh
index 67e8dcf..3e5edb8 100644
--- a/scripts/lib/dev-cycle-read.sh
+++ b/scripts/lib/dev-cycle-read.sh
@@ -523,7 +523,9 @@ IMPORT_AWK='
 function emit(c,   n, i, k, part, st, out) {
   work += length(c); if (work > 50000000) exit 3
   sub(/^ +/, "", c); sub(/ +$/, "", c)  # Claude Code trims the name (an escaped space can lead it)
-  if (c == "" || substr(c, 1, 2) == "~/") return
+  if (c == "") return
+  # Claude Code joins ~/ to the home directory (homedir(), which reads $HOME).
+  if (substr(c, 1, 2) == "~/") { if (substr(home, 1, 1) != "/") return; c = home "/" substr(c, 3) }
   if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
   n = split(c, part, "/"); k = 0
   for (i = 1; i <= n; i++) {
@@ -558,7 +560,7 @@ function splice(line,   o, i, j, r) {
   }
   return o line
 }
-BEGIN { dir = ENVIRON["IT_DIR"]; root = ENVIRON["IT_ROOT"]; pre = (root == "/") ? "/" : root "/"; if (root == "") exit 2 }
+BEGIN { dir = ENVIRON["IT_DIR"]; root = ENVIRON["IT_ROOT"]; home = ENVIRON["IT_HOME"]; pre = (root == "/") ? "/" : root "/"; if (root == "") exit 2 }
 { scan($0); if (index($0, "<!--")) scan(splice($0)) }'
 import_targets() {
   local u d toks s=(-e 's/\x0/ /g') LC_ALL=C
@@ -577,7 +579,7 @@ import_targets() {
   # A pipe, not a here-string: bash writes a long here-string to a temp file,
   # and a failed write would read as no imports.
   # dir and root go through the environment: awk -v would read backslash escapes in them.
-  printf '%s\n' "$toks" | env LC_ALL=C IT_DIR="$1" IT_ROOT="$ROOT_REAL" awk "$IMPORT_AWK" || return 1
+  printf '%s\n' "$toks" | env LC_ALL=C IT_DIR="$1" IT_ROOT="$ROOT_REAL" IT_HOME="${HOME:-}" awk "$IMPORT_AWK" || return 1
 }
 # Instruction-file names among NUL-separated paths on stdin: one grep, before
 # the tree walk forks lower and a plain check per path (forking for every tracked
```

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 98e3b1df` line at the top.
- **Answered:** whether the range's tests assert the contract (table above; F1 is the one mislabel). The mutants of every fix in range (31; ten real survivors at HEAD, all killed by Appendix A; seven equivalents, including the LC_ALL=C guard as you expected). Every gap you named: ROOT_REAL `/` (F5), python3 failure (F4), the IMPORT_OUT_MAX boundary and accumulation (F3), `~/` (F2), the main-walk head cap (deferred row, not re-raised), and nested `sub/.git` (F8, probe executed). A `git apply --check`-verified test patch, plus a fix sketch.
- **Out of scope:** the main-walk head cap (rubric L2-C5, deferred). Claude Code's `AD()` in-project check (not traced).
- **Escalate:** F2. Either take Appendix B, or name `~/` as a known exception and give the test `skip "<row>"`. F3 also bears on the L2-A4 row's "tested" wording.
- **Decisions I made:** I wrote the `~/` test as `FAILS at 98e3b1df` rather than skipped, to follow the iteration-1 convention. I left the emit comment's relabel (F1) and the comment wording (F9) out of the patch, because those edits are the author's. I added no test for G11 or G12.
