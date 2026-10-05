Commit: 0ae7d801

# Test Strategy: build-loop U1b (`scripts/build-loop.sh --settings`)

**Scope:** `test/scripts/build-loop-read.bats`, `test/lib/build-loop-fixtures.bash` against `scripts/build-loop.sh --settings`, and the plan's test spec (rev 4 T1–T4, T45; rev 2 T1–T3 via `git show 3a005378:...`)
**Reviewed:** 2026-10-05 (review-fix loop iteration 2, full panel)
**Budget:** the unit is at 398 of pr-prep's 400 changed-code-line cap. Each gap below gives its line cost.

## Method

I ran mutation checks only on copies in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/test-strategy/` (dirs `base`, `m1`–`m8`, `fixtests/`), with `LC_ALL=C.UTF-8` and bats. The unmodified suite passes all 9 tests.

| Mutant | Change to `scripts/build-loop.sh` | Suite at HEAD | Suite with fixes G1–G3, G5 |
|---|---|---|---|
| m1 | `:164` `globform` → `pathform "${g%/}" glob` (the A4 regression) | **9/9 pass** | test 7 fails at `:127` |
| m2 | `:157` drops the `*[$'\t\v\f\r']*` guard | 9/9 pass | test 7 fails at the new G3 line |
| m3 | `:161` `IFS=' ' read -ra` → `read -ra` | 9/9 pass | 9/9 pass (unobservable, see What NOT to Test) |
| m4 | m2 + m3 together | test 7 fails | — |
| m5 | `:165` dup message swapped for the glob-form message | 9/9 pass | 9/9 pass (G7) |
| m8 | `MAIN_SHA="$(git rev-parse HEAD)"` inserted after `:70` (reads HEAD's commit, not main's) | **9/9 pass** | tests 5, 7 and 9 fail |

I read `main_file` (`:79-94`) and `read_settings` (`:135-185`) whole. Neither function sets `MAIN_SHA`: only `resolve_main` (lib `:376-398`) sets it, and the mutant overrides it after that call.

## Test Conventions

- bats ≥ 1.5 (`run --separate-stderr`), one hermetic throwaway repo per test via `bl_setup` (`test/lib/build-loop-fixtures.bash:7-21`).
- Helpers: `settings LINE...` writes and commits `docs/dev-cycle.md`. `settings_is` / `settings_like KEY WANT` run `--settings` and assert one output line, printing the whole output on a mismatch. `line KEY` greps the line for one key.
- Assertions follow the `[ ... ] && [ ... ] || { echo ...; return 1; }` pattern, so explicit `return 1` carries most failures. The bare-helper lines rely on bats' `set -e`.
- **The `set -e` hazard behind E2:** bash does not trigger `set -e` (or bats' ERR trap) on a failing command that is not the last one in an `&&` list. A bare `A && B` line therefore checks nothing when A fails, unless it is the test's final command.

## Untested Paths Touched by the Change

- **G1** — `test/scripts/build-loop-read.bats:80`, `:126` — the first operands of `settings_like … && settings_like …` (the T4 working-tree policy check at `:80`, and the A4 `.github/ .gitignore` regression check at `:126`) are not enforced. When the first one fails, `set -e` ignores the list and the test passes. m1 (the A4 regression) passes the whole suite — not covered (E2, Claim 38 confirmed)
- **G2** — `scripts/build-loop.sh:70`, `:89` (`git cat-file blob "$MAIN_SHA:$f"`) — the "never HEAD, only main's commit" arm. Every `--settings` run in the suite happens with HEAD at main's commit: `:81` and `:130` check out main before running, `:83`'s `lower` branch sits at main's commit, and `:162`'s `wt` is created at main. A script that reads HEAD's commit passes all 9 tests (m8). A build loop runs on its own branch, so this is the arm that matters — not covered
- **G3** — `scripts/build-loop.sh:157` — the explicit tab/VT/FF refusal (`"$v" == *[$'\t\v\f\r']*`, reason "is not exactly … with single spaces"). The T45 loop asserts only the prefix `never malformed: line 2 ` (`build-loop-read.bats:111`). When the guard is removed, `globform` still refuses the tab with a different reason, so m2 passes. Neither tab guard is pinned on its own (Claim 39 confirmed) — not covered
- **G4** — `scripts/build-loop.sh:106-110` — a copy whose markup closes before the colon (`**Build-loop policy**: review`, `**Self-merge never**: b/`) is neither counted nor flagged. I reproduced it: with `Build-loop policy: self-merge` on line 1 and `**Build-loop policy**: review` on line 2, the output is `policy self-merge set: line 1 …`. The `:33` / `:120` copy lists hold only colon-inside markup (Claims 5b, 29) — not covered, and the code is wrong (E1)
- **G5** — `test/scripts/build-loop-read.bats:161-167` — the subdirectory and linked-worktree runs: main's commit, the working tree and the worktree's HEAD all say `self-merge`, so the test cannot tell which one was read (Claim 30 confirmed) — partially covered (the cd-to-root path runs; the source of the value is not distinguished)
- **G6** — `test/scripts/build-loop-read.bats:114` — the no-echo check catches an echo only for `\xc3`, `../x`, `/etc`, `-x` and `./b`. An echo of the tab-bearing entries (`a\tb`, `\ta`, `a\t`, `a \tb`) is not caught. The scrub keeps TAB, so an echoed tab would split the line differently for a reader (Claim 28) — partially covered
- **G7** — `scripts/build-loop.sh:164`, `:165` — the reasons "lists entry N, which is not an allowed glob form" and "lists entry N twice" are never asserted (m5 passes) — not covered
- **G8** — `scripts/build-loop.sh:176` (else arm at `:178`) — `Build-loop policy: review` together with a malformed never line should print `policy review set:`, not the self-merge-off message. Only the self-merge arm is tested — not covered
- **G9** — `scripts/build-loop.sh:141` — `SLOTS_LINE` for a file that is absent or not read (`slots 3 default: <why>`) is never asserted. T3 asserts only the policy and never lines — not covered
- **G10** — `test/lib/build-loop-fixtures.bash:26-28` — the comment says "Pass no lines for an empty file", but `printf '%s\n'` with no arguments writes one newline (Claim 23). No caller passes zero lines. The empty-file input is also untested. I checked by hand that an empty blob prints the three `none`/`default`/`unset` lines — not covered
- **G11** — `scripts/build-loop.sh:60` — `-h|--help` (exit 0, `sed -n '2,41p'` header range) is untested. The range is correct at HEAD and ends on the `Exit:` paragraph — not covered

## Findings

### F1 (G1) — Non-final `&&` assertions are dead, so the A4 regression check is disabled

- **Severity:** high
- **Location:** `test/scripts/build-loop-read.bats:126` (also `:80`)
- **Evidence:**
  ```
  80:    settings_like policy "policy review set:" && settings_like slots "slots 3 default:"
  126:    settings_like never "never .github/ .gitignore set:" && settings_like policy "policy self-merge set:"
  ```
  m1 (`pathform … glob` instead of `globform`) passes all 9 tests at HEAD. With `;` in place of `&&`, test 7 fails at `:127` with `never malformed: line 2 lists entry 1, which is not an allowed glob form`. The `:80` check is currently saved only because its second operand (slots) also fails when the working tree is read.
- **Fix (0 net lines):** replace ` && ` with `; ` on both lines. A simple command followed by `;` is subject to `set -e`. `:84` is the test's last command, so its `&&` is enforced. Leave it, or change it too for uniformity.
- **Confidence:** high (reproduced)
- **Legibility-target:** the test author. A reader assumes `&&` asserts both sides.

### F2 (G2) — "Reads main's commit, never HEAD" has no discriminating test

- **Severity:** high
- **Location:** `test/scripts/build-loop-read.bats:81-83`, `:129-130` (code: `scripts/build-loop.sh:89`)
- **Evidence:**
  ```
  81:    git checkout -q -b loop && commit_all raise && git checkout -q main
  82:    settings_like policy "policy review set:"
  130:    git checkout -q main && printf 'Build-loop policy: self-merge\n' > docs/dev-cycle.md
  ```
  m8 (`MAIN_SHA="$(git rev-parse HEAD)"`) passes all 9 tests at HEAD. Plan rev 2 T4 ("the commit wins") and rev 4 T45 ("the line raised only on the loop's branch → ignored") both imply that the loop's own branch is checked out when the script runs. The tests check out main first.
- **Fix (0 net lines):**
  - `:81` → `git checkout -q -b loop && commit_all raise`, so `:82` runs with HEAD on `loop`, which says self-merge.
  - `:83` → prefix `git checkout -q main && `.
  - `:130` → drop `git checkout -q main && `, so the run happens on `loop`, whose HEAD holds a malformed never line, with a working tree that has none.

  With these changes m8 fails tests 5 (`:82`) and 7 (`:132`), and the unmodified script passes.
- **Confidence:** high (reproduced)
- **Legibility-target:** the plan's T4/T45 reader, who reads "other branches never decide" as including the checked-out one.

### F3 (G3) — The explicit tab refusal is not pinned on its own

- **Severity:** medium
- **Location:** `test/scripts/build-loop-read.bats:111` (code: `scripts/build-loop.sh:157`)
- **Evidence:**
  ```
  111:        settings_like never "never malformed: line 2 "
  157:      if [[ "$t" != "Self-merge never: "* || "$v" == *[$'\t\v\f\r']* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
  ```
  m2 (guard removed) passes. Only m4 (guard and `IFS=' '` both removed) fails test 7.
- **Fix (+1 line)**, after the loop:
  `settings x $'Self-merge never: a\tb'; settings_is never 'never malformed: line 2 is not exactly "Self-merge never: GLOB ..." with single spaces'`.
  m2 then fails at this line.
- **Confidence:** high (reproduced)
- **Legibility-target:** the A1/R1 fix's reader. The guard is the documented defence, so a test should name it.

### F4 (G4) — A copy with the colon outside the bold is hidden and self-merge stays set

- **Severity:** medium (test gap; the code defect's severity is security-reviewer's call under E1)
- **Location:** `test/scripts/build-loop-read.bats:33`, `:120` (code: `scripts/build-loop.sh:106`)
- **Evidence:** a repro with `Build-loop policy: self-merge` / `**Build-loop policy**: review` / `**Self-merge never**: b/` printed
  ```
  policy self-merge set: line 1 of docs/dev-cycle.md on the default branch
  never none: no line starts "Self-merge never:"
  ```
- **Fix (0 test lines):** add `'**Build-loop policy**: review'` to the `:33` list and `'**Self-merge never**: b/'` to the `:120` list, in the same commit as E1's code fix. Both entries fail at HEAD.
- **Confidence:** high
- **Legibility-target:** E1's fixer, as the regression pin for A2's actual shape.

### F5 (G5) — The subdirectory/worktree test cannot tell what it read

- **Severity:** low (once F2 lands, T4 covers HEAD in the main checkout; this adds only the linked worktree's own HEAD)
- **Location:** `test/scripts/build-loop-read.bats:161-162`
- **Evidence:**
  ```
  161:    settings 'Build-loop policy: self-merge'
  162:    git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main && mkdir -p sub
  ```
- **Fix (+1 line, or 0 by appending to `:162`):**
  `printf 'Build-loop policy: review\n' > docs/dev-cycle.md && cp docs/dev-cycle.md "$BATS_TEST_TMPDIR/wt/docs/" && git -C "$BATS_TEST_TMPDIR/wt" commit -qam lower`.
  Verified: the unmodified script passes, and m8 fails test 9.
- **Confidence:** high
- **Legibility-target:** the test's title, which promises "reads the same main".

### F6 (G6) — The no-echo check misses tabs

- **Severity:** low
- **Location:** `test/scripts/build-loop-read.bats:114`
- **Evidence:** `[[ "$output" != *$'\xc3'* && "$output" != *../x* && "$output" != */etc* && "$output" != *-x* && "$output" != *./b* ]]`
- **Fix (0 lines):** append `&& "$output" != *$'\t'*` inside the same `[[ ]]`.
- **Confidence:** medium (I did not mutate an echo for this case)
- **Legibility-target:** the A3 fix's reader.

### F7 (G7–G9) — Unpinned reason strings and arms

- **Severity:** low
- **Location:** `scripts/build-loop.sh:141`, `:164-165`, `:178`
- **Evidence:** m5 passes. No test runs `review` with a malformed never line. No test asserts `slots` when the file is not read.
- **Fix (+1 line each):** defer. The cap cannot hold all three, and each one is message or branch fidelity on a fail-closed path.
- **Confidence:** high
- **Legibility-target:** U1c/U2 authors extending this suite.

### F8 (G10) — The fixture comment is false

- **Severity:** low
- **Location:** `test/lib/build-loop-fixtures.bash:27`
- **Evidence:** `# committed. Pass no lines for an empty file.` — `printf '%s\n'` with no arguments writes `\n`.
- **Fix (0 lines):** reword to "Pass no lines for a one-blank-line file". Or drop the sentence: no caller passes zero lines.
- **Confidence:** high
- **Legibility-target:** later suite authors (U1c, U2).

## Recommended Tests

#### T4 and T45 run on the loop's branch; their assertions are enforced
**Closes gaps:** G1, G2
**Type:** unit (bats)
**Priority:** high
**File:** `test/scripts/build-loop-read.bats` (`:80-83`, `:126`, `:130`)
**What it verifies:** a value raised in HEAD's commit or the working tree never decides, and the `.github/ .gitignore` never line stays valid.
**Key cases:**
- On `loop` (HEAD says self-merge; main says review) → `policy review set:`.
- On `loop` (HEAD has `x/ ../y`; the working tree has none; main has `workflows/`) → `never workflows/ set:`.
- `Self-merge never: .github/ .gitignore` → `never .github/ .gitignore set:`, enforced through `;`.

**Setup needed:** none. The edits are 0 net lines.

#### A tab in the never line is refused by the single-spaces rule
**Closes gaps:** G3
**Type:** unit
**Priority:** medium
**File:** `test/scripts/build-loop-read.bats`, after `:116`
**What it verifies:** `$'Self-merge never: a\tb'` → exactly `never malformed: line 2 is not exactly "Self-merge never: GLOB ..." with single spaces`.
**Setup needed:** none (+1 line).

#### Copies with the colon outside the markup count as a second line
**Closes gaps:** G4
**Type:** unit
**Priority:** medium (lands with E1's fix)
**File:** `test/scripts/build-loop-read.bats:33`, `:120` lists
**Key cases:** `'**Build-loop policy**: review'` → `more than one line starts "Build-loop policy:" (lines 1 and 2)`; `'**Self-merge never**: b/'` → `never malformed: more than one line …`.
**Setup needed:** none (0 lines).

#### The linked worktree reads main, not its own HEAD or working tree
**Closes gaps:** G5
**Type:** integration
**Priority:** low
**File:** `test/scripts/build-loop-read.bats:162`
**Setup needed:** +1 line (or 0 if appended to `:162`).

#### No echo of a tab
**Closes gaps:** G6
**Type:** unit
**Priority:** low
**File:** `test/scripts/build-loop-read.bats:114`
**Setup needed:** 0 lines.

Line budget: G1 + G2 + G4 + G6 = 0 lines, plus G3 = +1, which puts the unit at 399. G5 fits as +1 (400) or 0 if appended to `:162`.

## What NOT to Test

- **`IFS=' '` at `scripts/build-loop.sh:161` as a tab guard (G3's twin).** While `:157` holds, no tab, VT or FF can reach the `read`, so a black-box test cannot see it (m3 survives every variant). Its stated purpose is to keep the shell from expanding globs. That expansion would only affect validation, and it fails closed: an expansion can turn a valid line malformed, but cannot make a malformed one valid. It is not worth a fixture.
- **The CR branch of `:157`.** It is unreachable: FENCE_AWK refuses a mid-line CR (Claim 18).
- **main_file's `error` arm** (`main_entry` → `error`, misreported as "not a regular file", Claim 13). Reaching it needs a broken object store. Fix the message in the code instead.
- **G7–G9 and G11 (`-h`).** Deferred for the cap. They are message fidelity or arms on fail-closed paths. Queue them for U1c's suite additions.
- **`perl` missing.** It needs PATH surgery that the lib's own suite already has.

## Coverage Gaps Beyond Current Scope

**1.** Plan rev 4's test-spec preamble says each test prints `git log --oneline --graph --all` on failure. The helpers print only the output. This is settled (override log, deferred to U2), so I am not re-raising it.

**2.** T45's "`workflows/x.md` refused under self-merge even when listed, ok under review" is the gate's half. It is U2's (`build-loop-check.bats`), not U1b's.

**3.** The `set -e`/`&&` hazard is general. Other suites using the same helper style (U1c, U2) should adopt the `;` or `|| return 1` convention from the start. One sentence in the fixtures header would carry it, at 0–1 lines.

## Summary

The highest-value fixes cost no lines. G2 makes T4 and T45 run with the loop's branch checked out: today a script that reads HEAD instead of main passes the whole suite (m8). G1 turns the dead `&&` first operands into enforced checks: today the A4 regression passes the whole suite (m1). G3 (+1 line) pins the explicit tab refusal on its own. G4 adds two list entries that fail until E1's code fix lands. After these, the main residual risk is the rendered key shapes the counter does not model (E3, Claim 5a), which only the code side can close. Open question for the orchestrator: does E1's fix land in U1b, so that G4's entries can go in with it, or in a follow-up unit?

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved to /workspace/.claude/wt-build-loop-u1b/docs/reviews/test-strategy-review-2026-10-05-build-loop-u1b.md, structured per the test-strategy skill (named gaps G1, G2... mapped to concrete test cases)."
- **Answered:**
  - E2 is confirmed by mutation, with a 0-line fix (G1).
  - A new high gap: main-vs-HEAD is untested (G2), with a 0-line fix verified against m8.
  - Claim 39 is confirmed: the `:157` guard can be pinned for +1 line; the `:161` guard cannot be observed (G3).
  - Claim 28 is partially confirmed (G6, 0 lines).
  - Claim 30 is confirmed (G5, +1 or 0 lines).
  - Claim 5b has its test entries defined (G4, 0 lines, tied to E1).
  - Claim 23 is noted (G10).
- **Out of scope:**
  - The severity and fix of the 5b and 5a code defects (E1, E3 → security-reviewer / api-consistency-reviewer).
  - U2's gate half of T45.
  - U1c's T44.
- **Escalate:**
  - G2 to the orchestrator as a new high finding, not raised in Stage 1.
  - G4's test entries depend on E1's code fix landing in this unit.
- **Questions / Decisions:**
  - Spend the last 2 cap lines on G3 (+1) and G5 (+1), or keep G5 at 0 by appending it to `:162`. The interim recommendation is G3 at +1 and G5 appended.
