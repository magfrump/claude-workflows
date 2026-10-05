Commit: c143b929

# Test Strategy: build-loop U1c, final confirming pass (iteration 2)

**Scope:** `git diff feat/build-loop-u1b...feat/build-loop-u1c` (scripts/build-loop.sh `--settings` constraints line and `--status`, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats), with focus on what fix commit c143b929 changed, plus override row 246's deferred U1b gaps (G7, G8, G9, G11).
**Reviewed:** 2026-10-05
**Method:** I ran the suite at HEAD (`LC_ALL=C.UTF-8 bats test/scripts/build-loop-read.bats`, 16/16 ok). I then ran 15 single-line mutants of scripts/build-loop.sh against a copy of the suite and probed the real script in throwaway repos built with the fixtures. Scratch: /home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/test-strategy/.

## Test Conventions

- bats ≥ 1.5 with `run --separate-stderr`. Each test builds a hermetic repo through `bl_setup`, which exports `LC_ALL=C`, a null global git config and a fixed identity.
- Fixture helpers: `settings`, `constraints`, `brief`, `work`, `tip` (commit-tree, so a test can control parents and the tree), and `line KEY`. Hand-made objects are built with `git hash-object -t commit --literally` (the T7 two-tree case).
- Style: one `@test` per plan T-id. Variant tables are loops over inputs with one expected line. Every assertion prints `$output` when it fails.
- Budget: the unit is at 426 lines against the waived cap of about 430 (Q-114), so I rank every gap below by value per line added.

## Untested Paths Touched by the Change

Mutation results. Five mutants survived the suite: removing the open-status filter in `shared_branches`, the END `nosuccess` check, the `success:` text requirement, the NUL check, and the 1-character stopped reason. Four of these matter. Three more survivors are equivalent or untestable here (see What NOT to Test). Seven mutants were killed: lazy shared-set, `st == open` guard, soft count, `- ` before `success:`, the near-miss leading-strip, the `- `-prefix regex, and case-folding.

- **G1** — scripts/build-loop.sh:177-181 — a hard constraint pending at end of file (last constraint, no `success:` line after it) goes through the END branch `if (bad == "" && pend != "") bad = "nosuccess ..."` — not covered. Every existing nosuccess case is triggered mid-file, by a following S line (bats:167) or a heading (bats:183). If the END check is deleted, the suite stays green and `- S1: a` / `- H1: b` reads `constraints ok 1-hard 1-soft`. That is a silent `ok` for a hard constraint with no success line, the case Q-112 asks to hear about.
  ```
    else {
      if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl
      print (bad != "" ? bad : "ok " hard + 0 " " soft + 0)
    }
  ```
  Severity: high · Confidence: high (mutant run plus direct probe) · Legibility-target: a reviewer reading T44 should see that the END path is exercised.

- **G2** — scripts/build-loop.sh:279 — the `bad it holds a NUL byte` refusal in `marker_kind` — not covered. When the check is removed, the suite stays green. A probe then showed that a commit `handoff: ready\n\0x` (and a body-NUL variant) reads `ok ... ready`: `git log --format=%B` truncates at the NUL, so the hidden bytes go unseen. The A1/A2 fix in c143b929 claims this guard, and nothing pins it.
  ```
    if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi
  ```
  Severity: medium · Confidence: high (mutant run plus probe output `ok ... feat/a ready 5ae0af2f... 1970-01-01 0`) · Legibility-target: T7 should list NUL among the spoof shapes.

- **G3** — scripts/build-loop.sh:175 — a bare `success:` (or `success: ` with only blanks) must not satisfy a hard constraint. Only the `[^ \t]` after `success: ` enforces this — not covered. A mutant that accepts `/success:/` survives and then reads `- H1: a` / `  success:` as `ok 1-hard`.
  ```
  /^[ \t]*(- )?success: [^ \t]/ { pend = "" }
  ```
  Severity: medium · Confidence: high · Legibility-target: the help's "success: <observable>" should have a failing example.

- **G4** — scripts/build-loop.sh:304 — the F31 shared set counts only `Status: open` briefs — partially covered. The `st == open` guard on the queried brief is covered (its mutant was killed at bats:364). The filter on the *other* briefs is not: in T28 the only non-open brief that shares a branch (c, `done`, feat/x) shares it with two open briefs that skip anyway. If the filter is removed, the suite stays green, and then an open brief is skipped whenever a done or dropped brief once used its branch name. That fails closed, but it would quietly stop a loop from being dispatched.
  ```
      [[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue
  ```
  Severity: medium · Confidence: high · Legibility-target: T28 should show "a done brief on the same branch does not block".

- **G5** — scripts/build-loop.sh:291 — the lower bound of a stopped REASON (1 character, the `(...)?` arm) — not covered. Tests use 120, 121 and a multi-word reason. A mutant that needs 2 or more characters survives. It fails closed: a valid `handoff: stopped: x` would be skipped. Severity: low · Confidence: high · Legibility-target: T6 boundary.

- **G6** — scripts/build-loop.sh:321 — `Dispatched: 99` (upper accepted bound) and an explicit `Dispatched: 0` — not covered. Only 1 and 2 are accepted in tests, and 100, 01, -1, x and empty are rejected. Severity: low · Confidence: medium (I did not mutate this one; read from the regex `^Dispatched:\ (0|[123456789][0123456789]?)$`).

- **G7** — scripts/build-loop.sh:163, :35-37 — a constraint line inside a code fence (``` / `H2: hidden` / ```) is skipped, and the file reads `constraints ok 1-hard` (probe). This behaviour has no test either way. Its outcome waits on the Stage-1 escalation (Claim 8), so a test should pin whichever rule the orchestrator settles. Severity: low (as a test gap; the design question belongs to Claim 8) · Confidence: high.

Override row 246 (U1b G7, G8, G9, G11), re-checked at c143b929. All four are **still open**, and U1c's edits to build-loop-read.bats did not touch them:
- **G8 (U1b G7)** — scripts/build-loop.sh:232-233 — the `lists entry N, which is not an allowed glob form` and `lists entry N twice` reasons. bats:123 asserts only the prefix `settings_like never "never malformed: line 2 "`, so swapping the two reasons would pass. Severity: low.
- **G9 (U1b G8)** — scripts/build-loop.sh:243-247 — `Build-loop policy: review` with a malformed never line should read `policy review set:`. No test pairs the two; bats:81 has review with no never line at all. Severity: low.
- **G10 (U1b G9)** — scripts/build-loop.sh:207 — `slots 3 default: <why>` for an absent or unread file. bats:57-58 and :48-49 assert policy and never, not slots. Severity: low.
- **G11 (U1b G11)** — scripts/build-loop.sh:96 — `-h`/`--help`. No test runs it. The help is now 75 lines and includes the `--status` section (probe), which is what the orchestrator reads. Severity: low.

## Recommended Tests

Ranked by value per line. Gaps G1-G4 cost **+4 lines and 2 edited lines** (426 → 430, at the waived cap). I verified the patch: the patched suite passes on HEAD, and each of the four mutants (open-filter, end-nosuccess, success-text, nul) now fails exactly one test.

#### T44: a hard constraint left pending at the end, with a bare success: line
**Closes gaps:** G1, G3 · **Type:** unit · **Priority:** high · **File:** test/scripts/build-loop-read.bats, after line 184
**What it verifies:** the END check refuses a trailing hard constraint, and a `success:` line with no text does not satisfy it.
**Key cases:** `'- S1: a' '- H1: b' '  success:'` gives `constraints unreadable: hard constraint H1 (line 2) has no success: line before the next constraint or heading`.
```
    constraints '- S1: a' '- H1: b' '  success:'; run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints unreadable: hard constraint H1 (line 2) has no success: line before the next constraint or heading" ] || { echo "$output"; return 1; }
```
**Setup needed:** none.

#### T7: a marker holding a NUL byte is a skip
**Closes gaps:** G2 · **Type:** unit · **Priority:** high · **File:** test/scripts/build-loop-read.bats, after line 287 (reuses `base`, `n` and `check`)
**What it verifies:** a NUL after the subject, which `%B` would hide, is refused.
```
    o="$(printf 'tree %s\nparent %s\nauthor t <t> 0 +0000\ncommitter t <t> 0 +0000\n\nhandoff: ready\n\0x\n' "$(git rev-parse "$base^{tree}")" "$base" | git hash-object -t commit --literally -w --stdin)"
    git update-ref refs/heads/feat/a "$o" && check "skip $B: $n: it holds a NUL byte" nul
```
**Setup needed:** none.

#### T28: a dropped brief on the same branch does not block an open one (zero added lines)
**Closes gaps:** G4 · **Type:** unit · **Priority:** medium · **File:** test/scripts/build-loop-read.bats:370 and :378
**What it verifies:** only open briefs count toward F31.
**Key cases:** change brief e to `'Branch: feat/d'` and its expected line to `ok $e dropped review feat/d absent - - 0`. `lines[0]` (d, open, feat/d) must still be `ok`. The later closed/ case still skips d, because two open briefs then name feat/d.

#### Folds that cost no new lines (optional)
**Closes gaps:** G5, G6 · **Priority:** low.
- G6: change T6's `'Dispatched: 2'` (bats:229) to `'Dispatched: 99'` and its trailing ` 2` expectations to ` 99`.
- G5: change T6's `new dependency (left-pad)` reason to one character, or add `'handoff: stopped: x'` as an accepted case wherever a line is freed.

#### Row 246 gaps (G8-G11): keep deferred
**Closes gaps:** none now · **Priority:** low. Each one needs 2 or more new lines: G8 two `settings_is` lines, G9 one pair, G10 one `settings_is` beside bats:57, G11 a two-line `-h` assertion. All of them are wording or fail-closed paths. With the unit at the cap after G1-G4, their value is below G1-G4's. I suggest updating row 246's revisit trigger to "U2's tests".

## What NOT to Test

- **The `LC_ALL=C` on the reason grep (A8, :290-291).** `bl_setup` exports `LC_ALL=C`, so the suite cannot see the difference. My probe of the mutant without it, under C.UTF-8 (the only UTF-8 locale installed), refused `café`, U+202E and a bare 0xE9 byte just as HEAD does. A test would need a locale the sandbox does not have.
- **The heading's `pend = ""` (:174) and `if (!(id in seen))` (:168).** These are equivalent mutants. `bad` is already set whenever `pend` is non-empty at a heading, and the first dup is reported before `seen` could be overwritten.
- **`status_line`'s `brief_fields ... || skip "the brief is not read"` (:316).** It is reachable only through a race after `check_brief` succeeded.
- **CRLF constraint files.** The ID and success regexes match with or without the `\r` strip (probe: CRLF reads `ok 1-hard`).
- **A message that starts with a blank line (reads `working`) and a whitespace-only second line (refused, per probe).** Both fail closed, and the fact-check already documents them.

## Coverage Gaps Beyond Current Scope

**1.** `--status` on a `docs/working/briefs/closed/` path is accepted by `check_brief` and then read through status_line. No test runs `--status` on a closed/ path. That is U2/U3 territory, where closed briefs feed In flight.
**2.** An open brief that main cannot read (FENCE_AWK refuses it) does not count toward F31. A readable brief naming the same branch then proceeds as unique. This looks intended, but nothing documents or pins it.

## Summary

The highest-value addition is the two-line T44 case `'- S1: a' '- H1: b' '  success:'`. It closes the one way the suite would let a regression print `constraints ok` for a hard constraint with no success line (G1), and in the same run it catches a bare `success:` being accepted (G3). Next come the NUL-marker case (G2), which pins the A1 guard that c143b929 added, and a zero-line edit to T28 that pins F31's open-only counting (G4). Together these need 4 new lines, which brings the unit to the waived cap of about 430. Override row 246's four gaps are still open, and I recommend keeping them deferred. The residual risk is the fenced-constraint behaviour (G7), which needs a decision on Claim 8 before a test can pin it.

## Goal-Alignment Note
- Success criterion (restated verbatim): "A markdown report saved at the output path your task names, structured per your skill, with a `Commit: c143b929` first line."
- Answered: (1) Row 246's G7/G8/G9/G11 re-checked at c143b929: all still open (listed as G8-G11 here). (2) Gaps in U1c's own tests for the c143b929 behaviour: END nosuccess (G1), the NUL marker (G2), a bare `success:` (G3) and the F31 open-only filter (G4), each found by a surviving mutant and each closed by a patch I verified. The plan's T5-T8, T21, T28 and T44 (settings part) cases are all present. The gaps are below the plan's case lists. Ranked under the 430-line cap: +4 lines for G1-G4.
- Out of scope: whether fenced or look-alike constraint lines should be refused (Claim 8 escalation, Q-112). The `--start`/`--check`/`--marker` parts of T5, T21 and T44 (U2/U3).
- Escalate: G1 to the orchestrator, as the only test gap behind which a regression would yield a silent `constraints ok` for a hard constraint with no success line (Q-112's report condition, applied to tests rather than to code).
