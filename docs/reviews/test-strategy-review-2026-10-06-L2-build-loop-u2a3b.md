Commit: be94c871

# Test Strategy: feat/build-loop-u2a3b, loop 2 iteration 1 (the superset parser)

**Scope:** `git diff main...HEAD -- scripts test docs/working skills`, focused on `IMPORT_AWK` and `import_targets` (`scripts/lib/dev-cycle-read.sh:493-559`), `tree_starts`, `imported_names`, `isimported` and `check_fix`'s new failed-walk arm (`scripts/dev-cycle.sh:181-182`); tests in `test/scripts/build-loop-check.bats:26-452` and `test/scripts/dev-cycle.bats:1048-1072`.
**Reviewed:** 2026-10-06 (role: test-strategy, contextual and advisory; scratch `/tmp/u2a3b-tsL2-23Ad` for mutants, `/tmp/u2a3b-tsL2-p-7ZkH` for the patch)
**Method:** read the whole awk program and the four walk functions; 32 mutants of IMPORT_AWK and import_targets against build-loop-check.bats plus dev-cycle.bats `-f 'check-fix|import|sourced|IMPORTED'`; new cases checked against the Claude Code 2.1.292 harness (`/tmp/u2a3b-fcL2-FvuR/h/cc.js`, which wraps `reo()` as extracted from the installed 2.1.292 binary); the Appendix patch run through all five suites with and without a fix sketch.

## Stage-1 escalations

The fact-check escalated nothing to test-strategy by name. Its brief, though, asks for the Claim 1 holes as failing tests, so I wrote them: one test per hole (classes 1-4), a `--check-fix` end-to-end test for the class 1 regression, and a test for Claim 18b, where the work bound does not cover `splice`. All six fail at be94c871. All 128 tests pass with the fix sketch in Appendix B. The `~/`-under-`$HOME` residue is still unverified against Claude Code, so I left it out of the patch (see What NOT to Test). Test names and comments the fact-check corrected (Claims 29 and 30, the stale `:341-347` comments) are the orchestrator's; I only note how they bear on what the tests pin (F5).

## Test Conventions

- bats 1.8.2. `build-loop-check.bats` loads `test/lib/build-loop-fixtures.bash` (`bl_setup`: throwaway repo at `$BATS_TEST_TMPDIR/repo`, `HOME=$BATS_TEST_TMPDIR/home`, `LC_ALL=C`). `imps WALK PATH...` prints `walk: ok|failed` and `PATH: imported|-`, and `want PATH WORD` asserts one line. Each case loops `for w in tree main` so that both walks share every assertion.
- Fault injection is done with PATH shims (tr, sed, grep, git) in `$BATS_TEST_TMPDIR`, and direct parser probes source the lib inside `bash -c`.
- `dev-cycle.bats` runs `scripts/dev-cycle.sh --check-fix` end to end in `make_repo`'s repo (`$BATS_TEST_TMPDIR/repo`).
- At be94c871 the five named suites hold 121 tests, all passing (46.7 s here).

## Mutation results (32 mutants, scratch copy)

The full table is in the Appendix. 22 were killed and 10 survived. The survivors fall into three groups:

- **Real test gaps (2).** M21: splice drops the text before the second comment (`o = substr(...)` instead of `o = o substr(...)`). M22: a line holding `<!--` is scanned only after splicing, not raw as well. Under either mutant the parser misses a name Claude Code 2.1.292 imports (harness-checked). The Appendix test kills both.
- **Precision-only, no test pins it (2).** M16: a blank no longer ends a candidate, so every `@` reads to the end of the line. M05: the root prefix is matched without its `/`, so a sibling `/root2/docs/x.md` reads as `docs/x.md`. Both keep the superset intact and only raise false positives or time. I pinned M16 with one precision assertion. I left M05 unpinned (low).
- **Equivalent under the superset design (6).** M09 clamps `..` at the root, which is the direction the class 1 fix takes. M11 drops dedup (the bash side dedups anyway). M13 removes the 4096 cap, which is the class 4 fix. M15 drops CR and TAB as blanks, and M28 drops the UNI_SPACES-to-blank step: both only add prefixes. M29 prints an empty line for a root-resolving name (harmless). None should be pinned, because pinning would pin implementation.

The kill rate on the superset-relevant mutants is good. Every mutant that removes a Claude Code import was killed, except M21 and M22.

## Findings

**F1 — Severity: high (test gap: superset holes not asserted). Location** `test/scripts/build-loop-check.bats:339-381`, whose parser `scripts/lib/dev-cycle-read.sh:515,521,533,558`. **Evidence:** the superset test's only absolute case is the literal one (`printf 'See @docs/my\\ notes.md and @%s/docs/abs.md\n' "$(pwd -P)"`, `:366`), and no test holds `..` re-entry, a backslash directory or a long name. The parser drops each of them: `if (root == "" || index(c, root "/") != 1) return` (`:515`), `if (part[i] == "..") { if (k == 0) return; k--; continue }` (`:521`), `length(name) < 4096` (`:533`) and `awk -v dir="$1" -v root="$ROOT_REAL"` (`:558`). In scratch, each of the four Appendix tests fails at be94c871 with `walk: ok` and `<path>: -` for both walks. The `--check-fix` test shows the class 1 regression end to end (main prints skip; be94c871 prints ok, per the fact-check e2e). **Fix:** apply the Appendix A tests, marked `FAILS at be94c871`. If a hole is deferred, add `skip "<row>"` as the test's first line rather than drop it. Appendix B is a fix sketch under which all 128 pass: resolve every name to an absolute path (`root "/" dir "/" c`), clamp `..` at `/`, keep a result only if it starts with `root "/"`, drop the cap (the work bound covers it), and pass dir and root through ENVIRON, which mawk does not escape-process. **Confidence:** high (executed). **Legibility-target:** for-author. [unverified — submitted as claim]: the four classes are Claude Code imports, per the fact-check's harness runs and my reruns of the class 1 and 2 shapes.

**F2 — Severity: medium (test gap: splice paths). Location** `scripts/lib/dev-cycle-read.sh:545,549`; tests `test/scripts/build-loop-check.bats:339-360`. **Evidence:** `o = o substr(line, 1, i - 1)` (`:545`) and `{ scan($0); if (index($0, "<!--")) scan(splice($0)) }` (`:549`). Mutants M21 (no accumulation) and M22 (`{ scan(splice($0)) }`) both survive the suites, because every existing splice fixture has its first comment at column 1 and keeps no `@` in text that the splice removes. The harness imports `docs/abc.md` from `<!-- 0 --> @docs/a<!-- 1 -->b<!-- 2 -->c.md` and `docs/cs.md` from ``See `<!--` @docs/cs.md `-->` ``. Both mutants miss one of these. **Fix:** the Appendix test "three pieces...". It passes at be94c871 and kills both mutants. **Confidence:** high. **Legibility-target:** for-author.

**F3 — Severity: medium (test gap: time bound on splice). Location** `scripts/lib/dev-cycle-read.sh:541-548` (bound at `:512` only). **Evidence:** `r = substr(line, i + 4); j = index(r, "-->"); if (j == 0) break` (`:544`) never touches `work`. In scratch, one line of 320,000 `<!---->` reached `timeout 10` (rc=124) at be94c871. With the Appendix B line `work += length(r); if (work > 50000000) exit 3`, the same test passes in about 3 s, bats included. **Fix:** the Appendix test "fails, not stalls". It costs about 10 s while it fails and about 3 s after the fix, and it accepts any nonzero status except 124, so it does not pin awk's `3`. **Confidence:** high. **Legibility-target:** for-author. This is the performance-reviewer's finding; the test is offered for it.

**F4 — Severity: low (precision unpinned). Location** `scripts/lib/dev-cycle-read.sh:536`. **Evidence:** `else if (ch == " " || ch == "\t" || ch == "\r") break`. M16 (`else if (0) break`) survives: no test notices candidates running past a blank, although the false-positive and time cost the design accepts rests on this break. **Fix:** one precision assertion (`want 'docs/a.md x' -`, a file of that name existing) in the F2 test, labelled "precision, not superset". **Confidence:** high. **Legibility-target:** for-author.

**F5 — Severity: low (pins implementation, not contract). Location** `test/scripts/build-loop-check.bats:362-374`. **Evidence:** `ps=(docs/span.md docs/mail.md docs/pre.md docs/fence.md 'docs/my notes.md' docs/abs.md)` all `want ... imported`. `docs/pre.md` (from `@docs/pre.md.bak`) and `docs/mail.md` (from `user@`) are pure over-reads. Claude Code reads neither, so these lines pin the prefix-everything mechanism, and a more precise parser that is still a superset would fail them. Conversely, `docs/my notes.md` and `docs/abs.md` are real imports (fact-check Claim 29), and they sit in the "over-reads" test. **Fix (no patch, to avoid clashing with the orchestrator's renames):** move the escaped-space and absolute cases into the superset test. Keep span, fence, mail and pre under a comment saying they record the 2026-10-06 over-approximation decision, so a future precision change deletes them deliberately instead of "fixing" them. **Confidence:** high. **Legibility-target:** for-author.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:521 — the `..` that passes above the walk's top and re-enters (`k == 0` return) — not covered; `@../CLAUDE.md` from `docs/` covers only `..` within the repo
- **G2** — scripts/lib/dev-cycle-read.sh:514-517 — absolute names inside ROOT_REAL not spelled with the literal `ROOT_REAL/` prefix (`//R`, `/./R`, `R/../<name>`) — not covered; only the literal spelling (`:366`)
- **G3** — scripts/lib/dev-cycle-read.sh:558 — `-v dir=` and `-v root=` values holding a backslash — not covered
- **G4** — scripts/lib/dev-cycle-read.sh:533 — the 4096 cap reached by a name that normalizes short — not covered (the heavy test reaches the cap only with plain `x` runs)
- **G5** — scripts/lib/dev-cycle-read.sh:545 — accumulation of text before a second spliced comment — not covered (M21 survives)
- **G6** — scripts/lib/dev-cycle-read.sh:549 — the raw scan of a line holding `<!--`, when the splice removes an `@` Claude Code reads — not covered (M22 survives)
- **G7** — scripts/lib/dev-cycle-read.sh:541-548 — splice cost outside the work bound — not covered
- **G8** — scripts/lib/dev-cycle-read.sh:536 — a blank ending a candidate (precision) — not covered (M16 survives)
- **G9** — scripts/lib/dev-cycle-read.sh:515 — the `/` in `root "/"` excluding a sibling directory that shares the root's prefix (precision) — not covered (M05 survives)
- **G10** — scripts/lib/dev-cycle-read.sh:513 — `~/` names when the repo is under `$HOME` — not covered; Claude Code's `~/` expansion is not verified

## Recommended Tests

#### Superset holes, one test each (Appendix A, 4 tests in build-loop-check.bats)
**Closes gaps:** G1, G2, G3, G4
**Type:** integration (both walks through `imps`)
**Priority:** high
**File:** test/scripts/build-loop-check.bats (appended)
**What it verifies:** each Claude Code import class the fact-check found missing is listed by both walks.
**Key cases:**
- `@../<repo>/docs/re.md` at the top and `@../../<repo>/docs/sub.md` from `sub/CLAUDE.md` → both imported. The repo name comes from `pwd -P`, not a hard-coded value.
- `@//R/docs/a1.md`, `@/./R/docs/a2.md`, `@R/../<name>/docs/a3.md` → imported.
- `docs/a\tb/AGENTS.md` holding `@z.md` → `docs/a\tb/z.md` imported.
- `@` + 2100 × `./` + `docs/long.md` → `docs/long.md` imported.
- Each test also asserts `docs/other.md -`, so a fix that marks everything imported does not pass.

**Setup needed:** none beyond `bl_setup`. All four currently fail and are marked `FAILS at be94c871` in their names.

#### --check-fix refuses a doc imported through the parent (Appendix A, dev-cycle.bats)
**Closes gaps:** G1
**Type:** e2e
**Priority:** high
**File:** test/scripts/dev-cycle.bats, next to the U2a3b check-fix test
**What it verifies:** the user-visible regression: main printed skip, and be94c871 prints `ok docs/notes.md`.
**Key cases:** `CLAUDE.md` holding `See @../<repo>/docs/notes.md` → `skip docs/notes.md: an instruction file imports it...`. Currently fails.

#### Splice pieces, a code-span comment, `@./` and the blank pin (Appendix A)
**Closes gaps:** G5, G6, G8
**Type:** integration
**Priority:** medium
**File:** test/scripts/build-loop-check.bats
**What it verifies:** names Claude Code builds through an HTML comment block, or between code spans that hold comment markers, are listed; a blank still ends a candidate.
**Key cases:** `docs/abc.md`, `docs/cs.md` and `docs/dot.md` imported; `'docs/a.md x'` `-` (labelled precision). Passes at be94c871 and kills M21, M22 and M16 (checked).

#### Splice work is bounded (Appendix A)
**Closes gaps:** G7
**Type:** unit (direct parser probe)
**Priority:** medium
**File:** test/scripts/build-loop-check.bats
**What it verifies:** a line of 320,000 empty comments makes `import_targets` fail on its own, not hang until `timeout 10`.
**Key cases:** rc nonzero and not 124. Currently fails (rc=124 after 10 s).

## What NOT to Test

- **G9 (M05)** and the equivalent mutants (M09, M11, M13, M15, M28, M29): these change only precision or internal dedup. Pinning them would pin implementation, and M09 and M13 are the directions the F1 fix takes.
- **G10 (`~/` under `$HOME`)**: no test until a host probe shows that Claude Code 2.1.292 expands `~/` in `@` names. The installed binary was not read for this (one direct read of its resolver was denied by the permission system, so I did not pursue it). The case to add once verified: `HOME` is the fixture's `$BATS_TEST_TMPDIR/home`, so `@~/../repo/docs/x.md` should read `docs/x.md`.
- Exact exit status 3 at the bound: the tests accept any nonzero, which matches the documented contract ("returns 1" is the fact-check's Claim 18a wording issue, not a test target).
- Timing assertions on the whole walk (650 to 863 ms): too flaky for CI. The commit's measurement is the record.

## Coverage Gaps Beyond Current Scope

**1.** The fix sketch in Appendix B drops every name when ROOT_REAL is `/` (`index(out, "//")`), and when ROOT_REAL is empty (at be94c871 relative names still resolve then). The walks always set ROOT_REAL through need_root, but a test of `import_targets` with a repo at `/` is not practical, so this sits in this gap list rather than in a test.
**2.** No differential (property) test runs the harness against `import_targets` in CI. The fuzz harness lives only in /tmp, and its generator never emitted `..` re-entry or absolute paths (fact-check Claim 1 residue). A checked-in corpus of harness-verified `(input, dir) -> names` rows would turn the next Claude Code grammar change into a table update. Its revisit trigger is the one A5 names.
**3.** With the cap removed (Appendix B), a blank-free run of about 10 KB after an `@` trips the 50M bound and fails the walk, which makes `--check-fix` refuse every path. In scratch, none of /workspace's 1,495 tracked `.md` files trips it (11.5 s for all 1,495, one parser fork each, `lib.fixed`), so the false-fail risk is currently zero. No test pins this, and none should.

## Summary

The highest-value addition is the four superset-hole tests plus the `--check-fix` re-entry test (Appendix A): they turn the fact-check's executed counterexamples into regressions, and all five fail at be94c871. Mutation testing shows the existing suite is strong on everything it already lists (22 of 32 mutants killed, including the bound, the escape, the sed and awk failure paths and the here-string). It has two real blind spots in `splice` (M21, M22), which a passing test closes. Residual risk after the plan: the `~/`-under-`$HOME` class stays unverified, and any Claude Code grammar change still needs a harness rerun, because no differential corpus is checked in. Appendix B shows that a 17-line awk change closes all four holes and the splice bound, with 128/128 passing.

## Appendix: mutant table

| Mutant | Change | Result |
|---|---|---|
| M01 | bound never trips | killed (pinned test) |
| M02 | bound ×10 | killed |
| M03 | bound exits 0 | killed |
| M04 | keep `~/` | killed |
| M05 | `index(c, root)` without `/` | **survived** (precision) |
| M06 | drop all absolute | killed |
| M07 | no dir join | killed |
| M08 | keep `.` parts | killed |
| M09 | clamp `..` at root | survived (equivalent; fix direction) |
| M10 | ignore `..` | killed |
| M11 | no dedup | survived (equivalent) |
| M12 | cap 40 | killed |
| M13 | no cap | survived (superset-increasing; fix direction) |
| M14 | no `\ ` escape | killed |
| M15 | CR/TAB not blanks | survived (precision) |
| M16 | no blank break | **survived** → killed by Appendix A |
| M17 | skip column 1 | killed |
| M18 | emit before append | killed |
| M19 | emit only the full name | killed |
| M20 | no splice | killed |
| M21 | splice drops accumulation | **survived** → killed by Appendix A |
| M22 | spliced scan only | **survived** → killed by Appendix A |
| M23 | splice off by one | killed |
| M24 | sed failure ignored | killed |
| M25 | here-string (no pipe) | killed |
| M26 | empty root | killed |
| M27 | no NUL→blank | killed |
| M28 | no UNI_SPACES→blank | survived (precision) |
| M29 | no empty-path guard | survived (equivalent) |
| M30 | awk failure ignored | killed |
| M31 | last char at line end not emitted | killed |
| M32 | first `@` only | killed |

Mutant script: `/tmp/u2a3b-tsL2-23Ad/mut.py`; runner `runm.sh`; log `mut.log`.

## Appendix A: test patch (`git apply --check` against be94c871: OK)

At be94c871 it gives 128 tests, of which exactly 6 fail (#23-26 and #28 in build-loop-check.bats, #104 in dev-cycle.bats), all named `FAILS at be94c871`. With Appendix B, 128/128 pass. Source copy: `/tmp/u2a3b-tsL2-23Ad/tests.patch`.

```diff
diff --git a/test/scripts/build-loop-check.bats b/test/scripts/build-loop-check.bats
index e6417a0..f55fdb4 100644
--- a/test/scripts/build-loop-check.bats
+++ b/test/scripts/build-loop-check.bats
@@ -450,3 +450,77 @@ docs/z.md: imported" ] || { echo "$output $stderr"; return 1; }
     # The tracked listing fails while the untracked listing works.
     PATH="$gb:$PATH" imps tree docs/a.md docs/z.md; want walk failed; want docs/a.md imported; want docs/z.md imported
 }
+
+# The four superset holes the L2 fact-check executed against the Claude Code 2.1.292
+# harness (Claim 1). Each FAILS at be94c871 and passes once its hole is closed; a
+# deferred hole gets `skip "<its row>"` as its first line, not a deleted assertion.
+@test "both walks read an import that leaves the repo and re-enters it through its parent (FAILS at be94c871: L2 fact-check Claim 1 class 1)" {
+    mkdir -p docs sub && n="$(basename "$(pwd -P)")"
+    printf 'See @../%s/docs/re.md\n' "$n" > AGENTS.md
+    printf 'See @../../%s/docs/sub.md\n' "$n" > sub/CLAUDE.md
+    commit_all reentry
+    for w in tree main; do
+        imps "$w" docs/re.md docs/sub.md docs/other.md
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
+        want walk ok; want docs/re.md imported; want docs/sub.md imported; want docs/other.md -
+    done
+}
+
+@test "both walks read an absolute import into the repo however it is spelled: //root, /./root, root/../<name> (FAILS at be94c871: L2 fact-check Claim 1 class 2)" {
+    mkdir -p docs && r="$(pwd -P)"
+    printf 'See @/%s/docs/a1.md, @/.%s/docs/a2.md and @%s/../%s/docs/a3.md\n' "$r" "$r" "$r" "${r##*/}" > AGENTS.md
+    commit_all abs
+    for w in tree main; do
+        imps "$w" docs/a1.md docs/a2.md docs/a3.md docs/other.md
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
+        want walk ok; for p in docs/a1.md docs/a2.md docs/a3.md; do want "$p" imported; done; want docs/other.md -
+    done
+}
+
+@test "both walks resolve an import against a directory whose name holds a backslash, taken literally (FAILS at be94c871: L2 fact-check Claim 1 class 3)" {
+    # mawk reads escape sequences in a -v value: dir a\tb became a<TAB>b.
+    d='docs/a\tb' && mkdir -p "$d" && printf 'See @z.md\n' > "$d/AGENTS.md"
+    commit_all backslash
+    for w in tree main; do
+        imps "$w" "$d/z.md" docs/other.md
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
+        want walk ok; want "$d/z.md" imported; want docs/other.md -
+    done
+}
+
+@test "both walks read a name over 4096 bytes that resolves to a short path (FAILS at be94c871: L2 fact-check Claim 1 class 4)" {
+    mkdir -p docs
+    { printf 'See @'; for i in $(seq 2100); do printf './'; done; printf 'docs/long.md\n'; } > AGENTS.md
+    commit_all long
+    for w in tree main; do
+        imps "$w" docs/long.md docs/other.md
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
+        want walk ok; want docs/long.md imported; want docs/other.md -
+    done
+}
+
+@test "both walks read a name an HTML comment block splices from three pieces, an @ between code spans that hold <!-- and -->, and an @./ name; a blank ends every name (U2a3b L2 test-strategy)" {
+    # Claude Code 2.1.292 (harness) reads docs/abc.md (HTML block, comments removed),
+    # docs/cs.md (text between two code spans) and docs/dot.md; it never reads "docs/a.md x".
+    mkdir -p docs
+    { printf '<!-- 0 --> @docs/a<!-- 1 -->b<!-- 2 -->c.md\n'; printf 'See \x60<!--\x60 @docs/cs.md \x60-->\x60\n'
+      printf 'See @./docs/dot.md and @docs/a.md x\n'; } > AGENTS.md
+    printf 'x\n' > 'docs/a.md x'
+    commit_all splice3
+    for w in tree main; do
+        imps "$w" docs/abc.md docs/cs.md docs/dot.md docs/a.md docs/other.md 'docs/a.md x'
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
+        want walk ok; for p in docs/abc.md docs/cs.md docs/dot.md docs/a.md; do want "$p" imported; done
+        # Precision, not superset: the false-positive cost the design states (to the first blank).
+        want docs/other.md -; want 'docs/a.md x' -
+    done
+}
+
+@test "the parser fails, not stalls, on one line of many HTML comments (FAILS at be94c871: L2 fact-check Claim 18b; about 10 s)" {
+    # 320,000 comments in one 2.24 MB line took 27 s with status 0 at be94c871: splice's
+    # copying is quadratic and outside the work bound. 124 is timeout's status, not a failure the parser chose.
+    { head -c 320000 /dev/zero | sed 's/\x0/<!---->/g'; printf '\n'; } > "$BATS_TEST_TMPDIR/comments.txt"
+    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
+        timeout 10 bash -c "source \"\$1\"; ROOT_REAL=\"\$2\"; import_targets \"\" < \"\$3\" >/dev/null" _ "$1" "$ROOT_REAL" "$2"; echo "rc=$?"' _ "$LIB" "$BATS_TEST_TMPDIR/comments.txt"
+    [[ "$output" == rc=* && "$output" != rc=0 && "$output" != rc=124 ]] || { echo "$output $stderr"; return 1; }
+}
diff --git a/test/scripts/dev-cycle.bats b/test/scripts/dev-cycle.bats
index d5bfdda..f1714b4 100644
--- a/test/scripts/dev-cycle.bats
+++ b/test/scripts/dev-cycle.bats
@@ -1056,6 +1056,13 @@ EOF
     [[ "$output" == "skip docs/notes.md: the instruction-file import walk failed"* ]] || { echo "$output $stderr"; return 1; }
 }
 
+@test "--check-fix refuses a doc imported through the repo's parent directory, as main did (FAILS at be94c871: L2 fact-check Claim 1 class 1)" {
+    mkdir -p docs && printf 'See @../%s/docs/notes.md\n' "$(basename "$(pwd -P)")" > CLAUDE.md && echo x > docs/notes.md
+    git add -A && git commit -qm docs
+    run --separate-stderr bash "$DC" --check-fix docs/notes.md
+    [[ "$output" == "skip docs/notes.md: an instruction file imports it"* ]] || { echo "$output $stderr"; return 1; }
+}
+
 @test "--check-fix reads an import token whole: underscores, emphasis, #fragments, link text; an email-shaped token is over-read (superset)" {
     mkdir -p docs
     { echo 'See @docs/my_notes.md and **@docs/bold.md** and _@docs/em_one.md_ and *@docs/star.md*.'
```

## Appendix B: fix sketch (`git apply --check` against be94c871: OK; 128/128 with Appendix A)

This is offered to the security and performance reviewers. It is not a test-strategy finding. Caveat: Coverage gap 1 (a ROOT_REAL of `/` or empty). Source copy: `/tmp/u2a3b-tsL2-23Ad/fix.patch`.

```diff
diff --git a/scripts/lib/dev-cycle-read.sh b/scripts/lib/dev-cycle-read.sh
index c92c3c4..d7acd45 100644
--- a/scripts/lib/dev-cycle-read.sh
+++ b/scripts/lib/dev-cycle-read.sh
@@ -511,18 +511,16 @@ IMPORT_AWK='
 function emit(c,   n, i, k, part, st, out) {
   work += length(c); if (work > 50000000) exit 3
   if (c == "" || substr(c, 1, 2) == "~/") return
-  if (substr(c, 1, 1) == "/") {
-    if (root == "" || index(c, root "/") != 1) return
-    c = substr(c, length(root) + 2)
-  } else if (dir != "") c = dir "/" c
+  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
   n = split(c, part, "/"); k = 0
   for (i = 1; i <= n; i++) {
     if (part[i] == "" || part[i] == ".") continue
-    if (part[i] == "..") { if (k == 0) return; k--; continue }
+    if (part[i] == "..") { if (k > 0) k--; continue }
     st[++k] = part[i]
   }
-  if (k == 0) return
-  out = st[1]; for (i = 2; i <= k; i++) out = out "/" st[i]
+  out = ""; for (i = 1; i <= k; i++) out = out "/" st[i]
+  if (root == "" || index(out, root "/") != 1) return
+  out = substr(out, length(root) + 2)
   if (!(out in seen)) { seen[out] = 1; print out }
 }
 function scan(line,   i, j, L, ch, name) {
@@ -530,7 +528,7 @@ function scan(line,   i, j, L, ch, name) {
   for (i = 1; i <= L; i++) {
     if (substr(line, i, 1) != "@") continue
     name = ""
-    for (j = i + 1; j <= L && length(name) < 4096; j++) {
+    for (j = i + 1; j <= L; j++) {
       ch = substr(line, j, 1)
       if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ }
       else if (ch == " " || ch == "\t" || ch == "\r") break
@@ -541,11 +539,13 @@ function scan(line,   i, j, L, ch, name) {
 function splice(line,   o, i, j, r) {
   o = ""
   while ((i = index(line, "<!--")) > 0) {
-    r = substr(line, i + 4); j = index(r, "-->"); if (j == 0) break
+    r = substr(line, i + 4); work += length(r); if (work > 50000000) exit 3
+    j = index(r, "-->"); if (j == 0) break
     o = o substr(line, 1, i - 1); line = substr(r, j + 3)
   }
   return o line
 }
+BEGIN { dir = ENVIRON["IT_DIR"]; root = ENVIRON["IT_ROOT"] }
 { scan($0); if (index($0, "<!--")) scan(splice($0)) }'
 import_targets() {
   local u toks s=(-e 's/\x0/ /g')
@@ -555,7 +555,7 @@ import_targets() {
   toks="$(env LC_ALL=C sed "${s[@]}")" || return 1
   # A pipe, not a here-string: bash writes a long here-string to a temp file,
   # and a failed write would read as no imports.
-  printf '%s\n' "$toks" | env LC_ALL=C awk -v dir="$1" -v root="$ROOT_REAL" "$IMPORT_AWK"
+  printf '%s\n' "$toks" | env LC_ALL=C IT_DIR="$1" IT_ROOT="$ROOT_REAL" awk "$IMPORT_AWK"
 }
 # Instruction-file names among NUL-separated paths on stdin: one grep, before
 # the tree walk forks lower and a plain check per path (forking for every tracked
```

## Goal-Alignment Note

Success criterion (verbatim): "A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: be94c871` line at the top."

This report is saved at the named output path, opens with `Commit: be94c871`, and follows the test-strategy skill's structure (Conventions, the gap list G1-G10, Recommended Tests, What NOT to Test, Coverage Gaps Beyond Current Scope, Summary). It adds the findings with severity, location, evidence, confidence and legibility target that the brief requires, and the checked patches in appendices. It answers the brief's question: the tests do not yet assert everything Claude Code loads (F1, F2), the over-approximation pins partly pin the implementation (F5), and the mutants are run and tabulated.
