Commit: 2e711a7b

# Test Strategy: feat/build-loop-u1b, iteration 4 of 4 (final confirming pass)

**Scope:** `feat/build-loop-u1a...2e711a7b`: scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats (override-log rows are context)
**Reviewed:** 2026-10-05
**Method:** a copy of scripts/, test/ and docs/dev-cycle.md under the scratch dir; each mutant is one perl substitution on build-loop.sh, followed by a full `bats test/scripts/build-loop-read.bats` run (LC_ALL=C.UTF-8, TMPDIR in scratch). The base copy passes 9/9. Behaviour probes ran in a scratch repo against the base and mutant copies. No process was left running.

## Test Conventions

- bats ≥1.5, `@category fast`, one throwaway repo per test via `bl_setup` (test/lib/build-loop-fixtures.bash). There is a hermetic git env (GIT_CONFIG_GLOBAL=/dev/null, NOSYSTEM), and `LC_ALL=C` is pinned.
- Helpers: `settings LINE...` commits docs/dev-cycle.md. `settings_is KEY WANT` asserts one exact output line, and `settings_like KEY PREFIX` asserts a prefix. Both print the whole output on a mismatch.
- The tests are table-driven `for v in ...` loops, each with exact WHY strings. New cases should go into the existing T4 (test 5) and T45 (test 7) blocks, not into new files.

## Iteration-3 items: closure verified by mutation

| Item | Mutant | Result |
|---|---|---|
| **A18**: a duplicate never line turns policy off | `never_ok=1` set on the `cnt[never] -gt 1` arm (`:153`) | **Killed.** Test 7 fails at bats `:129` (`settings_is policy "$no"`); its output shows `policy self-merge set` next to `never malformed: more than one line`. Closed. |
| **A19**: the worktree commits its own change | `$MAIN_SHA:$f` → `HEAD:$f` in main_file | **Killed** by tests 5, 7 and 9. With only test 9 run (`-f 'sources the lib'`), it fails at `:184` on the `wt` iteration: `policy review set`. Closed: test 9 now kills this mutant by itself. |
| **C3**: the replace guard is tested, including core.useReplaceRefs | the whole `cfg=...` guard line deleted | **Killed** (test 5). |
| C3 (variant) | `GIT_CONFIG_COUNT=$cfg` (the guard pair is exported, not counted) | **Killed** (test 5). |
| policy-without-never WHY | `[[ "$v" == self-merge && -z "$never_ok" ]]` → `[[ -z "$never_ok" ]]` (review would also go unset) | **Killed** (test 5, `:79` `settings_like policy "policy review set:"`). |
| next-line check | `nx[k] = 1` → `nx[k] = 0` at the first copy (end of file counts as non-blank) | **Killed** (tests 1, 5, 7, 9). |
| sole hidden never line (A17) | n/a. The `- [x] Self-merge never: b/` shape takes the same path as an absent never line, and treating absent as `never_ok=1` is killed by bats `:113-114`. | Covered by bats `:118` (`settings_is policy "$no"`). Closed. |

## Untested Paths Touched by the Change

- **G1**: `scripts/build-loop.sh:69`. The guard appends its pair *after a caller's GIT_CONFIG_COUNT pairs*. The arm where the caller already passes `GIT_CONFIG_COUNT≥1` (in particular a caller pair `core.useReplaceRefs=true`) is not covered. Test 5 runs only with GIT_CONFIG_COUNT unset.
- **G2**: `scripts/build-loop.sh:107` together with the lib's `fence()` (dev-cycle-read.sh:213-226). The "next line *outside a fence*" rule is untested in both directions: (a) a fenced block right after the never line followed by a non-blank line, which must stay malformed; (b) a fenced block followed by a blank line or the end of file, which must stay set. Only the plain adjacent `b/` case (bats `:140-141`) is covered.
- **G3**: `scripts/build-loop.sh:107`, `/^[ \t]*$/`. A whitespace-only line after the never line counts as blank. Untested.
- **G4**: `scripts/build-loop.sh:66-69`, caller-environment shapes that the guard does not neutralise: `GIT_CONFIG_PARAMETERS` / `git -c core.useReplaceRefs=true`, and a non-decimal `GIT_CONFIG_COUNT`. Untested, because whether they should be guarded is escalation E1 (security), not settled. This is a conditional gap.

Not re-raised (settled): `-h` is not asserted (row 246, G11). Its premise is unchanged by the range-free sed: build-loop-read.bats still never calls `-h`, so any mutant of the `-h` arm survives, as the row already accepts. The equivalent second `none` arm at `:160` and the redundant `GIT_NO_REPLACE_OBJECTS=1` are fact-check survivors, not test gaps.

## Findings

### G1: no test passes a caller GIT_CONFIG_COUNT, so a guard that skips or clobbers the caller's pairs survives

- **Severity:** medium
- **Location:** scripts/build-loop.sh:66-69; test/scripts/build-loop-read.bats:83-85 (test 5)
- **Evidence (verbatim):** `cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))` (excerpt ends `:69`; the guard block continues to `:72` (`export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1`, resolve_main, main_by_name), all read). The comment at `:67-68` says "add a command-line config pair after any the caller passed".
- **Mutant:** `[[ -n "${GIT_CONFIG_COUNT-}" ]] || export GIT_CONFIG_KEY_0=core.useReplaceRefs GIT_CONFIG_VALUE_0=false GIT_CONFIG_COUNT=1`, a plausible "don't touch the caller's config" refactor. **Survives the suite (0 failed).** In a probe repo with a replace ref swapping main's `Build-loop policy: review` blob for a self-merge one, called with `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.useReplaceRefs GIT_CONFIG_VALUE_0=true`: the base prints `policy review set: line 1 ...`; the mutant prints `policy self-merge set: line 1 ...`. The mutant raises the policy.
- **Test case** (add to test 5 after `:84`, while the replace ref and core.useReplaceRefs are in place): `run --separate-stderr env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.useReplaceRefs GIT_CONFIG_VALUE_0=true bash "$BL" --settings; [[ "$(line policy)" == "policy review set:"* ]]`. A second line can check that a caller pair is kept: `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.abbrev GIT_CONFIG_VALUE_0=12` still exits 0 with `policy review set`.
- **Confidence:** high (executed)
- **Legibility-target:** test 5's comment `:82` should say "even with core.useReplaceRefs set in the repo or by a caller's GIT_CONFIG_COUNT pair".

### G2: the "outside a fence" part of the next-line rule is untested, and a mutant that drops a continued list survives and raises self-merge

- **Severity:** medium
- **Location:** scripts/build-loop.sh:105-108 (SETTINGS_AWK; `fence()` at dev-cycle-read.sh:213-226 returns 1 for fence lines and fenced content); test/scripts/build-loop-read.bats:139-143
- **Evidence (verbatim):** `fence($0) { next }` / `if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }` (excerpt ends `:107`; SETTINGS_AWK continues to `:116`, its END block, which prints `nx[k]`; the value reaches `next[never]` at `:149` and the check at `:157`, all read).
- **Mutant A (raise direction):** `fence($0) { next }` → `fence($0) { pk = ""; next }`. **Survives (0 failed).** Probe input: `Build-loop policy: self-merge` / `Self-merge never: a/` / a fenced block (```` ``` ````, `x`, ```` ``` ````) / `b/`. The base gives `never malformed: line 2 is followed by a non-blank line outside a fence` and `policy review unset`. The mutant gives `never a/ set` and `policy self-merge set`, so the continued `b/` is silently dropped and self-merge goes on.
- **Mutant B (fail-closed direction):** the `pk` update moved above `fence($0) { next }`, so a fence line counts as the next line. **Survives (0 failed).** With the same input minus `b/`: the base gives `never a/ set`, the mutant `never malformed`.
- **Test case** (add to test 7 after `:141`, with `f=$'\x60\x60\x60'`): `settings 'Build-loop policy: self-merge' 'Self-merge never: a/' "$f" x "$f" 'b/'; settings_like never 'never malformed: line 2 is followed by a non-blank line outside a fence'; settings_is policy "$no"` (kills A). Then `settings 'Build-loop policy: self-merge' 'Self-merge never: a/' "$f" x "$f"; settings_like never "never a/ set:"` (kills B).
- **Confidence:** high (executed)
- **Legibility-target:** the T45 comment `:139` ("the next unfenced line may continue") can then name both cases.

### G3: a whitespace-only next line counts as blank, but no test asserts it

- **Severity:** low (the mutant fails closed)
- **Location:** scripts/build-loop.sh:107
- **Evidence (verbatim):** `nx[pk] = ($0 ~ /^[ \t]*$/)`
- **Mutant:** `/^[ \t]*$/` → `/^$/`. **Survives.** On the input `Self-merge never: a/` / `   ` / `z`, the base gives `never a/ set`; the mutant gives `never malformed`. A mutant that loosens the check instead (e.g. `/^[ \t]*/`, which treats any line as blank) would lose the self-merge-off case. That case is already killed by `:140-141`.
- **Test case:** `settings 'Build-loop policy: self-merge' 'Self-merge never: a/' '   '; settings_like never "never a/ set:"`.
- **Confidence:** high (executed)
- **Legibility-target:** the header `:22` says "blank"; the test would show that whitespace-only lines count.

### G4 (conditional on E1): caller-environment shapes the guard does not neutralise

- **Severity:** low as a test gap (the defect question belongs to security-reviewer, E1)
- **Location:** scripts/build-loop.sh:66-69
- **Evidence (executed on the base, same probe repo and replace ref):** `GIT_CONFIG_PARAMETERS="'core.usereplacerefs'='true'"` gives `policy self-merge set: line 1 ...`. This is a bypass, matching fact-check r1-r3. `GIT_CONFIG_COUNT=010` and `GIT_CONFIG_COUNT=08` both gave `Not inside a git repository`, exit 1: in my probe git's own `rev-parse` (`:62`) fails before the guard line runs, which fails closed with the wrong reason (E2). Fact-check r3 saw exit 0 for `08` under a different setup; I did not reproduce it.
- **Test case:** if E1 decides the caller's environment is untrusted and the guard is extended (e.g. `unset GIT_CONFIG_PARAMETERS`, or refusing a non-decimal COUNT), add to test 5: `run env GIT_CONFIG_PARAMETERS="'core.usereplacerefs'='true'" bash "$BL" --settings` → `policy review set`; and `GIT_CONFIG_COUNT=08` → exit 1 (or `policy review`), never `policy self-merge set`. If E1 decides the caller is trusted, no test is needed, and the comment `:67-68` should say "after any GIT_CONFIG_COUNT pair". There is no mutant to run today: the base already fails the first case.
- **Confidence:** high for the executed outputs; the gap itself depends on E1.
- **Legibility-target:** the guard comment `:66-68`.

## Recommended Tests

#### Caller GIT_CONFIG_COUNT pair does not undo the replace guard
**Closes gaps:** G1 · **Type:** integration (bats, real git) · **Priority:** high · **File:** test/scripts/build-loop-read.bats, test 5
**Key cases:** a caller pair `core.useReplaceRefs=true` plus a replace ref gives `policy review set`; a caller pair for an unrelated key gives exit 0 with `policy review set`.
**Setup needed:** none beyond test 5's existing replace ref (run before the `git replace -d` at `:84`).

#### The never line's next-line rule across a fence
**Closes gaps:** G2, G3 · **Type:** integration · **Priority:** medium · **File:** build-loop-read.bats, test 7 after `:141`
**Key cases:** a fenced block then `b/` gives malformed and policy `$no`; a fenced block then the end of file gives `never a/ set`; a whitespace-only line gives `never a/ set`.

#### Caller env bypasses (only if E1 rules them in scope)
**Closes gaps:** G4 · **Priority:** low · **File:** test 5 · **Key cases:** as listed in G4.

## What NOT to Test

- `-h` output: settled, row 246. dev-cycle.bats has a header-boundary test that build-loop.sh could copy in U1c.
- Hidden-markup shapes beyond the one at `:118` (task boxes, tags, entities): accepted (row 256, Q-112). They cannot raise the policy, because self-merge needs the exact never line.
- Dropping only `GIT_NO_REPLACE_OBJECTS=1`: equivalent while the config pair stands.

## Coverage Gaps Beyond Current Scope

**1.** U1c's constraints reader will reuse main_file and the guard. G1's caller-env test belongs in a shared helper once a second mode reads main.

## Summary

The iteration-3 test items are closed: A18 (duplicate never → policy off) and A19 (HEAD:$f, killed by test 9 alone) are killed by mutation, as are C3 (the guard line deleted, or exported without being counted) and the policy-without-never WHY. 2e711a7b introduces two medium gaps where a mutant survives in the direction that raises self-merge. G1: a guard that skips when the caller passes GIT_CONFIG_COUNT reads a replaced blob, `policy self-merge set`. G2: clearing the pending key on a fence line drops a list continued after a fence, again `policy self-merge set`. Each needs one or two lines in existing tests 5 and 7. G3 is a low fail-closed survivor. G4 waits on security's E1 ruling about GIT_CONFIG_PARAMETERS, which bypasses the guard on the base today.

## Goal-Alignment Note

Success criterion (verbatim): "A report saved at the output path named in your tail, structured per your skill, covering the full unit diff at 2e711a7b."

This report is saved at docs/reviews/test-strategy-review-2026-10-05-build-loop-u1b.md, with `Commit: 2e711a7b` as its first line. It follows the skill's structure (conventions, gap list, recommended tests, what not to test, beyond scope, summary). It covers all three code files of the unit diff and the specific asks: A18, A19 and C3 verified by mutation; the new gaps named with mutants and results; settled rows 246 and 260 not re-raised.
