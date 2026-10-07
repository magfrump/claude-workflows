Commit: 4828727d

# Test Strategy: feat/build-loop-u2a3b, loop 2 confirming pass (full unit, focus aa379ee9)

**Scope:** `git diff main...4828727d -- . ':!docs/reviews'`, looking hardest at aa379ee9. That commit changed the parser's `put` charge and `tried` memo, `import_home`'s raw-HOME key, the `IMPORT_HOME_REAL` and `UTF8_WELL_FORMED` renames, and the main walk's `.git` skip. It also landed the L2-final Appendix A tests. I also covered what no earlier pass mutated: the UTF-8 gate's byte ranges and the `..` floor.
**Reviewed:** 2026-10-07
**Method:** I read the import section of `scripts/lib/dev-cycle-read.sh` at 4828727d from line 443 (`INSTRUCTION_FILE`) to line 800 (`isimported`). That covers `IMPORT_AWK`, `import_home`, `import_targets`, `imported_names` and `main_imports` in full. I read every test that aa379ee9 added or changed. I ran 41 mutants (40 on the lib, plus F2's tree-walk mutant) on `git archive 4828727d` copies in `/tmp/u2a3btstc-4qVp/` (tools `one.sh` and `apply.py`, mutant specs in `muts/`, logs in `logs/`). Each mutant ran against all of build-loop-check.bats (48 tests) plus dev-cycle.bats `-f 'check-fix|import|sourced|IMPORTED'` (10 tests), with a fresh TMPDIR. The unmutated baseline passed 58/58. I did not repeat Stage 1's three named mutants: no-charge, skip-any-nested-.git and no-emit-bound. Everything below was executed unless it says "reasoned".

## Prior Appendix A: landed and working

All 13 mutants the L2-final Appendix A was written to kill are killed at 4828727d (executed), and so is one more on splice's charge:

| Mutant (prior report ID) | Killed by (build-loop-check.bats) |
|---|---|
| P01 emit bound deleted, P02 bound ×100 | `:673` (the work bound when nothing prints) |
| W10 / M04 `used =` per file | `:609` (the three-file budget at 20/38/39) |
| H01 empty HOME kept, H02 no passwd fallback | `:697` (empty and unset HOME, getent shim) |
| T02 no Unicode-space conversion, T03 U+FEFF dropped | `:26`, `:54` (the run-on names, `-`) |
| P20 tab, P21 CR do not end a name | `:536` |
| T05 always forks python3, T07 byte test only | `:714` (well-formed UTF-8, python3 shim exits 1) |
| P14 below-root `index` deleted | `:489` (the same-length sibling `docs/sib.md`) |
| (new) splice's work charge deleted | `:554` |

The tree walk's own pipefail test (`:724`) landed as written. Stage 1 confirms it kills the no-pipefail mutant. The nested-`.git` test landed in a different form from my proposal. Mine used a linked worktree at `sub/`. The landed test (`:683`) uses an `n/.git` directory and then an `n/.git` file, and it inverts the expectation for the file to fail closed, as aa379ee9's security F2 fix requires. It kills A14 (fail on any nested `.git`, below) and Stage 1's skip-any-nested mutant. Its title wording is Stage 1's S1. Every retitle from my F9 landed: `:342` "a ~/ name outside the repo dropped", `:370`, `:406` "characters", and `:554` "a 10 s timeout".

## Test Conventions

These are unchanged from the prior report: bats 1.8.2 and `test/lib/build-loop-fixtures.bash` (`bl_setup`, `imps`, `want`), probes that source the parser inside `bash -c`, PATH shims for fault injection, and the "precision, not superset" label on over-read pins.

## Mutation results (41 mutants)

**Killed at HEAD (22):** A01, A03, A04, A12, A14, A20, A21 and A22 below, the 13 Appendix A checks above, and S (splice's charge). **Surviving (19):** the 18 marked below, plus F2's tree-walk mutant.

| ID | Change (`scripts/lib/dev-cycle-read.sh`) | Result |
|---|---|---|
| A01 | `put`: charge moved after the `tried` check (only new spellings are charged) | killed by `:735` (depth charge) |
| A02 | `put`: the `tried` memo deleted | **survives**: equivalent in outcome (below) |
| A03 | `put`: charge the name before it is joined to `root/dir` | killed by `:735` |
| A04 | `emit`: never put the real-home form (`if (0)`) | killed by `:649` |
| A05 | `emit`: always put the real-home form | **survives**: equivalent |
| A06 | `emit`: only the real-home form (spelled form dropped) | **survives**: non-equivalent, contrived (below) |
| A07 | `import_home` key `x${HOME-}` (set and unset collapse) | **survives**: equivalent |
| A08 | `import_home` never recomputes once computed | **survives**: non-equivalent, no caller (below) |
| A09 | `import_home` keyed on the resolved home (aa379ee9's perf F3 reverted) | **survives**: time only |
| A10 | `import_home` without its cache | **survives**: time only |
| A11 | `main_imports` also skips a nested `.git` that is a plain directory | **survives**: equivalent, as `:773-775` says |
| A12 | `main_imports`: top-level `.git` skip deleted | killed by `:397` |
| A14 | `main_imports`: fail on any nested `.git`, a directory too | killed by `:683` |
| A15 | `UTF8_WELL_FORMED` accepts surrogates (`\355[\200-\277]`) | **survives**: non-equivalent fail-open (F1) |
| A16 | accepts the overlong leads C0/C1 (`[\300-\337]`) | **survives**: non-equivalent fail-open (F1) |
| A17 | accepts E0 overlongs (`\340[\200-\277]`) | **survives**: non-equivalent fail-open (F1) |
| A18 | accepts past U+10FFFF (`\364[\200-\277]`) | **survives**: non-equivalent fail-open (F1) |
| A19 | accepts F0 overlongs (`\360[\200-\277]`) | **survives**: non-equivalent fail-open (F1) |
| A20 | `emit`: relative-home `exit 4` deleted | killed by `:659` |
| A21 | `put`: `..` without the `k > 0` floor | killed by `:598` |
| A22 | `import_targets`: NUL not made a blank | killed by `:26`, `:54` |
| P06 | `if (c == "") return` deleted | survives: precision only (prior report) |
| T10 | decoded text replaces the raw text | survives: precision only (prior N17) |
| W07 / M02 | a walk does not pass `IMPORT_LEFT` | survives: time only (prior report) |
| W-ih | `imported_names`' own `import_home` call deleted | **survives**: time only; `import_targets` calls it in each `$(...)` |

Survivors that change no outcome:

- **A02.** The charge comes before `if (c in tried) return` (`:561-563`), so `work` is the same with or without the memo, and the output is deduplicated by `seen` anyway. Only resolve time differs. The comment's claim "each is resolved once per file" has no test, and none is needed.
- **A05, A07, A11.** These are equivalent by reading `:552`, `:618-620` and `:773-782`, and the executed run agrees.
- **A09 and A10.** aa379ee9's perf F3 fix (getent once for an unset HOME) has no test. Stage 1 executed it: getent ran once, against 5 times at e1654266. A test that counts getent calls through the shim would pin an implementation detail for a cost of milliseconds per file, so I do not recommend one.

## Findings

**F1. Severity: low (regression guard for a stated superset rule; the code is correct today). Location:** `scripts/lib/dev-cycle-read.sh:609` (`UTF8_WELL_FORMED`) and `:636` (the gate).
- **Evidence:** `UTF8_WELL_FORMED='^([\001-\177]|[\302-\337][\200-\277]|\340[\240-\277][\200-\277]|[\341-\354\356\357][\200-\277][\200-\277]|\355[\200-\237][\200-\277]|\360[\220-\277][\200-\277][\200-\277]|[\361-\363][\200-\277][\200-\277][\200-\277]|\364[\200-\217][\200-\277][\200-\277])*$'` and `if [[ "$toks" == *[$'\x80'-$'\xff']* ]] && ! printf '%s\n' "$toks" | env LC_ALL=C awk -v ok="$UTF8_WELL_FORMED" '$0 !~ ok { exit 1 }'; then`. Each of the five tightened ranges can be widened with no test failing (A15-A19). The only invalid-UTF-8 tests (`:563`, `:582`) use a lone `\xff`, which no plausible widening admits.
- **Why it matters:** if a range is widened, an ill-formed sequence in that class passes the gate, python3 never runs, and the U+FFFD spelling is not read. That breaks the superset rule's "text holding a byte above 0x7f is also read decoded as Claude Code decodes it" (`:517-518`). Executed under A15: AGENTS.md holds `See @docs/\xed\xa0\x80.md`, and `docs/���.md` (three U+FFFD) exists. The tree walk gives `walk ok` and `not-imported`; at HEAD it gives `imported`. That is a fail-open. The cost is a crafted name plus a file whose name holds U+FFFD, so the risk is low. But the regex is hand-written byte ranges, and its correctness rests on a performance probe (20,013 cases) that no test keeps.
- **Fix:** Appendix A adds a parser-level test with one line per class (C0 80, C1 BF, E0 80 80, ED A0 80, F0 80 80 80, F4 90 80 80), fed one line per call. The gate forks python3 for the whole text if any line is ill-formed, so a single combined input would mask a widening. For each class it expects the decoded spelling with python3's U+FFFD count (2, 2, 3, 3, 4, 4). It passes at 4828727d and kills A15-A19 each (executed).
- **Confidence:** high for the mutant behaviour and the end-to-end miss. The claim that Claude Code (Bun's decoder) yields the same U+FFFD counts for these six sequences is `[unverified — submitted as claim]`, Location `:633-634`. I reasoned it from WHATWG's maximal-subpart rule. Stage 1 executed 13 sequences against the binary, and I have not checked whether these six were among them. The test asserts python3's decoding, which is what the lib uses.
- **Legibility-target:** for-author. Executed.

**F2. Severity: low (the tree half of security F2's premise has no test). Location:** `scripts/lib/dev-cycle-read.sh:690`; test `test/scripts/build-loop-check.bats:683-695`.
- **Evidence:** the lib comment at `:775` says a `.git` file "is read by Claude Code like any file". The new test checks only `imps main`. The tree walk reads such a file through `if [[ -f "$p" && "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo_here "$p"; then`. A mutant that adds `"$p" != */.git &&` to that condition passes all 58 tests. It drops `docs/e.md`, which a `.git` file imports, so it is a fail-open. No code in the unit does this today. The test only guards against someone "harmonizing" the tree walk with the main walk's `.git` skip.
- **Fix:** Appendix A adds one line to `:683`: `imps tree docs/e.md docs/other.md; want walk ok; want docs/e.md imported; want docs/other.md -`. It passes at HEAD and kills that mutant (executed). The test's title then understates its scope, which ties in with Stage 1's S1 retitle.
- **Confidence:** high. **Legibility-target:** for-author. Executed.

**F3. Severity: informational (a non-equivalent survivor that is too contrived to test). Location:** `scripts/lib/dev-cycle-read.sh:550-553`.
- **Evidence:** `if (homereal != home) put(homereal "/" substr(c, 3))` / `c = home "/" substr(c, 3)`. A06 keeps only the real form, and it passes. It differs only when HOME's spelled path resolves lexically into the repo while its real path does not. Executed: with `HOME="$ROOT_REAL/lnk/.."`, where `lnk` is a symlink out of the repo, `@~/docs/a.md` yields `docs/a.md` at HEAD and nothing under A06. Node's `path.join` normalizes the `..` lexically, so Claude Code reads the repo file. The spelled form is therefore needed, and the code is right to keep it. A HOME that holds a symlink followed by `..` is not a configuration worth a fixture, so I propose no test.
- **Confidence:** high (executed probe). The `path.join` reading is `[unverified — submitted as claim]` at `:548`. **Legibility-target:** for-author.

**F4. Severity: informational (a stated contract without a caller). Location:** `scripts/lib/dev-cycle-read.sh:614-619`, `:480-483`.
- **Evidence:** the comment says `it recomputes only when HOME itself changes (IMPORT_HOME_DONE holds the HOME it was computed for)`. A08 (never recompute) passes. This is the prior report's H03 under aa379ee9's new key. No caller in `scripts/` changes HOME between walks. Stage 1's S2 already covers the related doc gap: `:480-483` tells a caller to clear only `IMPORTED_MAIN_DONE`. The premise of the prior "What NOT" entry still holds, so I recommend no test. If S2 is fixed by adding a caller-facing "change HOME, clear both caches, walk again" rule, a test that does exactly that would kill A08 in about 0.1 s.
- **Confidence:** high. **Legibility-target:** for-orchestrator-synthesis (relates to Stage 1 S2). Executed.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:609, :636 — each ill-formed class (overlong C0/C1, E0, F0; surrogate ED A0-BF; past F4 8F) reaching python3 — not covered (only a lone `\xff` is)
- **G2** — scripts/lib/dev-cycle-read.sh:690 — the tree walk reading a nested `.git` file and following its import — not covered (the test checks only the main walk)
- **G3** — scripts/lib/dev-cycle-read.sh:552-553 — the spelled-home form when only it lies in the repo — not covered (contrived)
- **G4** — scripts/lib/dev-cycle-read.sh:618-619 — import_home recomputing after a HOME change — not covered
- **G5** — scripts/lib/dev-cycle-read.sh:618-622, :562-563 — the getent-once cache and the per-file resolve memo (time only) — not covered

The aa379ee9 paths that are covered: the depth charge (A01, A03 by `:735`), the top-level and nested `.git` arms (A12 by `:397`, A14 by `:683`), the real-home form (A04 by `:649`), the empty and unset HOME passwd reading (H01, H02 by `:697`), and the relative-home failure (A20 by `:659`).

## Recommended Tests

Both are in Appendix A. With the patch, build-loop-check (49), build-loop-read (19), fixture-git-env (2) and dev-cycle (78) pass 148/148 at 4828727d.

#### UTF-8 gate: each ill-formed class reads its U+FFFD spelling
**Closes gaps:** G1. **Type:** unit (parser). **Priority:** medium (a fail-open guard). **File:** test/scripts/build-loop-check.bats (new test at the end).
**What it verifies:** every byte class that `UTF8_WELL_FORMED` rejects is sent to python3 and read decoded.
**Key cases:** `@d0\xc0\x80.md` → `d0` + 2×U+FFFD + `.md`; `\xc1\xbf` → 2; `\xe0\x80\x80` → 3; `\xed\xa0\x80` → 3; `\xf0\x80\x80\x80` → 4; `\xf4\x90\x80\x80` → 4, one line per call.
**Setup needed:** none beyond `$LIB`.

#### Nested `.git` file: the tree walk too
**Closes gaps:** G2. **Type:** unit (tree walk). **Priority:** low. **File:** build-loop-check.bats `:683` (one added line).
**Key cases:** `n/.git` file holding `see @../docs/e.md` → `walk ok`, `docs/e.md imported`, `docs/other.md -`.

## What NOT to Test

- **G3 (A06):** it needs a HOME that holds a symlink followed by `..`. The code already handles it, and a fixture would document an absurd configuration.
- **G4 (A08):** no caller changes HOME. Revisit if Stage 1's S2 is fixed by adding a caller-facing rule.
- **G5 (A02, A09, A10, W-ih, W07, M02):** time only, with identical outcomes. Pinning call counts would test the implementation.
- **Equivalent:** A05, A07, A11 (A11 is the arm aa379ee9 removed as equivalent; I confirmed that by execution).
- **Precision only, as in the prior report:** P06 and T10.
- **The main walk's uncapped blob read, outside-repo instruction files, and the reader set:** these are routed in the override log (U2a3c, U2b). No new evidence.

## Coverage Gaps Beyond Current Scope

**1.** The 4 MiB `head -c 4194305` cap (`:683`) applies only to the tree walk. The main walk's blob read is routed to U2a3c, and its test belongs there.

## Summary

The prior Appendix A landed and works: all 13 mutants it targeted are killed at 4828727d. aa379ee9's own changes are well covered. The depth charge, both `.git` arms, the real-home form and the HOME fallback each kill their mutants. Its unpinned parts (the `tried` memo and the getent-once cache) change only time. The highest-value addition is F1's UTF-8 class test. Five hand-written byte ranges in `UTF8_WELL_FORMED` can each be widened without a test failing, and each widening is a fail-open: executed under the surrogate mutant, the tree walk drops a U+FFFD-named import. The residual risk is that the test pins python3's decoding, and Claude Code's agreement on these six sequences rests on Stage 1's binary probes plus the WHATWG rule. No finding blocks merge.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 4828727d` line at the top.
- **Answered:** I mutated aa379ee9's code changes (charge placement, memo, home forms, HOME key and cache, `.git` arms) and the UTF-8 gate's ranges, `..` floor, NUL conversion and relative-home failure, which no earlier pass had mutated. Each survivor is classed as equivalent, time only or non-equivalent. The prior Appendix A is verified landed and killing. A `git apply --check`-verified Appendix A covers the two non-equivalent survivors worth testing.
- **Out of scope:** wording (Stage 1's S1-S7), the commit-message evidence, and the routed U2a3c and U2b items.
- **Escalate:** none.
- **Decisions I made:** I tested the UTF-8 gate at parser level, one line per call, because a single input would let one ill-formed line force the fork and mask a widened range. I did not test A06 or A08 (contrived and callerless). I did not repeat Stage 1's named mutants.

## Appendix A: test patch (`git apply --check` against 4828727d: OK)

```diff
--- a/test/scripts/build-loop-check.bats
+++ b/test/scripts/build-loop-check.bats
@@ -692,6 +692,8 @@
     # Claude Code follows its imports, so the walk fails rather than drop docs/e.md.
     rmdir n/.git && printf 'see @../docs/e.md\n' > n/.git
     imps main docs/e.md; want walk failed; want docs/e.md imported
+    # The tree walk reads that file as Claude Code does, and follows its import.
+    imps tree docs/e.md docs/other.md; want walk ok; want docs/e.md imported; want docs/other.md -
 }
 
 @test "both walks read ~/ against the passwd entry's home when HOME is empty or unset (U2a3b L2-final test-strategy)" {
@@ -742,3 +744,19 @@
         timeout 60 bash -c "source \"\$1\"; ROOT_REAL=\"\$2\"; import_targets \"\$3\" < \"\$4\" >/dev/null" _ "$1" "$ROOT_REAL" "$2" "$3"; echo "rc=$?"' _ "$LIB" "$d" "$BATS_TEST_TMPDIR/many.txt"
     [ "$output" = rc=1 ] || { echo "$output $stderr"; return 1; }
 }
+
+@test "the parser reads the U+FFFD spelling of each ill-formed class the UTF-8 gate must send to python3: overlongs, a surrogate, past U+10FFFF (U2a3b L2-confirm test-strategy)" {
+    # One line per call: the gate forks python3 for the whole text when any line is
+    # ill-formed, so each class must be the only one in its text to pin UTF8_WELL_FORMED's
+    # range for it. Counts are python3's "replace" decoding (one U+FFFD per maximal
+    # subpart, as WHATWG decoders also do).
+    seqs=($'\xc0\x80' $'\xc1\xbf' $'\xe0\x80\x80' $'\xed\xa0\x80' $'\xf0\x80\x80\x80' $'\xf4\x90\x80\x80') ns=(2 2 3 3 4 4)
+    for i in "${!seqs[@]}"; do printf '@d%s%s.md\n' "$i" "${seqs[$i]}"; done > "$BATS_TEST_TMPDIR/ill.txt"
+    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
+        while IFS= read -r l; do printf "%s\n" "$l" | import_targets ""; done < "$2"' _ "$LIB" "$BATS_TEST_TMPDIR/ill.txt"
+    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$status $stderr"; return 1; }
+    for i in "${!seqs[@]}"; do
+        w="d$i"; for ((k = 0; k < ns[i]; k++)); do w+=$'\xef\xbf\xbd'; done
+        printf '%s\n' "$output" | grep -qxF "$w.md" || { echo "missing: $w.md"; return 1; }
+    done
+}
```
