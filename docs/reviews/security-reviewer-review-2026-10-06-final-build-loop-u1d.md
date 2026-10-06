Commit: ab71bce5

# Security Review: feat/build-loop-u1d, final confirming pass

**Scope:** full branch, `git diff main...HEAD -- scripts test` (83cdb005, 6c83af2a, 07c354c5, merged with main at ab71bce5). Enclosing units read in full: `main_entry`, `pathform`, `brief_fields`, `check_brief` (head), `main_file`, `marker_kind`, `shared_branches`, `status_line`, build-loop.sh's guard block (`:112-117`), `bl_setup` and its helpers, and dev-cycle.bats' `setup`.
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u1d.md` (k=3, `Commit: ab71bce5`; 15 verified, 4 mostly accurate, 1 incorrect)

Probes ran under `timeout` in `/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/f-sec/` (`$S` below). Each one has exited. Each probe repo and `git archive HEAD` copy is in its own fresh directory under `$S`.

## Trust Boundary Map

```
B1: path argument (caller argv today; U2's changed paths next) → main_entry's guard (main_by_name, pathform) → git ls-tree pathspec on main's commit
B2: docs/dev-cycle.md blob on main                            → SETTINGS_AWK copy count + exact-line parse → POLICY / NEVER (self-merge gate)
B3: brief blobs on main (git grep, brief_fields)              → shared_branches (F31), status_line         → open-brief skip / ok line
B4: branch-tip commit object (loop-written)                   → marker_kind (NUL, parents, tree, subject)  → LOOP state
B5: caller environment (GIT_CONFIG_COUNT pairs)               → guard pair appended at index COUNT         → config of every git read (replace refs off)
B6: object-store health (missing / corrupt objects)           → git grep exit code                         → SHARED_BRANCHES=error, or "not counted"
B7: test runner env + fixture steps (bats)                    → bl_setup / dev-cycle.bats setup, && chains → whether a guard's regression test asserts anything
```

B1 is moved: the pathform precondition was the caller's duty and is now inside main_entry. The other boundaries are unchanged in code. Their comments, help text and tests change.

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | path argument to main_entry (argv, brief paths, U2's diff paths) | request-time | UNTRUSTED for the pathspec / ls-tree sink; must pass pathform |
| S2 | docs/dev-cycle.md on main | runtime-mutable (any merge to main) | UNTRUSTED for value-setting: only an exact line sets a value |
| S3 | brief files on main | runtime-mutable | UNTRUSTED for output text and branch names (scrub, check_branch); trusted as the dispatch record |
| S4 | loop branch tips and their objects | request-time (the loop writes them) | UNTRUSTED for all sinks: the boundary the script exists to police |
| S5 | caller env (`GIT_CONFIG_*`, `git -c`) | deploy-time (the orchestrator's process) | trusted, per the script's own comment (`build-loop.sh:112-116`); it already runs code |
| S6 | object-store state | runtime-mutable | untrusted for availability: must fail closed |
| S7 | bats runner env and fixture command results | deploy-time | must be neutralized or checked by the test, not trusted |

What crosses: the only executable changes are main_entry's guard (B1) and one skip line's wording (B3). Everything else on the branch is comments, help text or tests on B2-B7. So the security questions are these. Does the moved guard hold against bypass inputs? Does the reworded fail-closed text promise more than the code does? And does each new test of a guard fail when that guard regresses, including when a fixture step fails?

## Findings

#### 1. The U1d replace-ref guard test is `&&`-chained: a failed `git replace` lets the test pass with the guard pair removed

**Severity:** Low
**Location:** `test/scripts/build-loop-read.bats:434-438` (siblings on B3: `:464`, `:469`)
**Boundary:** B5 (the replace-ref guard pair), B7 (fixture)
**Move:** 3 (error path), 11 (bypass of a guard's regression test)
**Confidence:** High
**Legibility-target:** for-author

Evidence (verbatim, `build-loop-read.bats:434-438`; the enclosing `@test` ends at `:439`, read):

```
    settings 'Build-loop policy: review' '' 'Self-merge never: none'
    printf 'Build-loop policy: self-merge\n\nSelf-merge never: none\n' > x.md
    git replace "$(git rev-parse main:docs/dev-cycle.md)" "$(git hash-object -w x.md)" && git config core.useReplaceRefs true
    run --separate-stderr env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller bash "$BL" --settings
    [[ "$(line policy)" == "policy review set:"* ]] || { echo "$output $stderr"; return 1; }
```

This is the shape 07c354c5 fixed in T7. errexit does not fire when a non-final command in an `&&` list fails. So if `git replace` fails, `core.useReplaceRefs` is never set and no replace ref exists. main then reads `review` whether or not the guard exists, and the assertion passes. I ran this in three `git archive HEAD` copies under `$S/m/` with `bats -f "deferred cases: reasons"`:

- `ctl` (unchanged): `ok 1`.
- `guardonly`: build-loop.sh's guard export line (`cfg=...; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" ...`) is replaced by `:`. The test **fails**, printing `policy self-merge set: line 1 ...`. So the step does pin the guard, and the exported `GIT_NO_REPLACE_OBJECTS=1` alone is overridden by the repo config, as the comment at `build-loop.sh:112-115` says.
- `both`: the same guard mutant, plus `git replace` → `git replace --no-such-flag` in the test. The result was **`ok 1`**: the guard is gone and the test still passes.

Fact-check Claim 18 found the same vacuous-pass shape at `:464` (CRLF overwrite, F31 count) and `:469` (closed-directory file). Both sit on B3's shared-branch skip.

Why this is Low and not Medium: no runtime code path is weakened. The mechanism needs two independent events: `git replace` failing in a fresh temp repo, and a regression in the guard. The guard is also pinned by the pre-existing T-step at `:83-85`, but that step has the same `&&` shape (`:84`, on main and out of range). This is a test-integrity gap on the one guard B5 protects. It is a different line from the T7 finding the loop fixed, so it is not a re-file. 07c354c5's "The two other new && chains are split too" (fact-check Claim 18, Mostly accurate) did not reach it.

**Recommendation:** Put `git replace ...` and `git config core.useReplaceRefs true` on separate lines, so a failed fixture fails the test. Do the same for the `printf ... > "$B"` / `commit_all` steps at `:464` and `:469`. Splitting `:84` on main is a one-line follow-up for whichever unit next touches T-step `:83-85`.

#### 2. main_entry's new test has no positive control showing that main was found by name

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:1330-1337`
**Boundary:** B1
**Move:** 5 (invert the guard: what else produces the asserted answer?)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence (verbatim, the whole `@test`):

```
@test "main_entry answers error for a path pathform refuses (U1d)" {
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main
        for p in "a\"b.md" "../x" "-x" "docs//x.md"; do main_entry "$p"; done' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh"
    [ "$output" = "error
error
error
error" ] || { echo "$output $stderr"; return 1; }
}
```

`error` is also main_entry's answer when `main_by_name` is false. Suppose a future change to dev-cycle.bats' `setup` or `make_repo` left resolve_main returning 0 without a by-name main. All four lines would still read `error`, and reverting the pathform half of the guard would go unnoticed. Today that does not happen: setup builds `main` (`dev-cycle.bats:17-19`), and fact-check Claim 14 executed the guard-reverted mutant, which fails. This is not exploitable and not a regression. It is a cheap anchor.

**Recommendation:** Optional: add one accepted path to the loop (for example `main_entry x`, which answers `absent` in that repo), and expect `absent` as the fifth line.

## Focus questions

- **main_entry's guard (B1).** `if ! main_by_name || ! pathform "$1"; then echo error; return; fi` now runs before the `want` loop and before `git ls-tree` (`dev-cycle-read.sh:265`; enclosing `main_entry` read through `:278`). I probed it with `$S/probe.sh` under `LC_ALL=C`, `C.UTF-8` and an uninstalled `en_US.UTF-8`. Each of these answered `error`: `""`, `docs/`, `docs/a.md/`, `.GIT/x`, `docs/.Git/x`, `:(top)docs/a.md`, `docs/*.md`, a path with a newline, a path with a tab, `docs/café.md`, a full-width letter, `/docs/a.md`, `./docs/a.md`, `docs/./a.md`, `docs/../docs/a.md` and `--`. `docs/a.md` answered `blob` and `x` answered `absent`, the same in all three locales. `NAMECHARS` lists its characters one by one, so the locale cannot widen the set. One consequence for U2: a changed path with any non-ASCII byte answers `error`. That is the fail-closed direction, and how U2 words or treats it is already deferred (`badform`; U2 treating `error` as a refusal).
- **Fail-closed wording (B3, B6).** The `shared_branches` comment (`build-loop.sh:310-314`) claims no more than the code does. Exit above 1 → `SHARED_BRANCHES=error` (`:316`), and `status_line` then skips every open brief (`:343`). The fact-check executed this for a corrupt loose object, and the i2 security pass did so for a corrupt packed object. The missing-object half is a documented fail-open on F31 (row 293), stated plainly and not re-filed. Dropping "(git grep failed)" from the skip line removes no information an attacker could use or a reader needs to stay safe. The line is still a refusal.
- **Never-line rule (B2).** At HEAD the help text names an unchecked task box as counted and a checked one as missed. Fact-check Claim 1 executed every markup form, beside a valid line and alone. The residual case (a hidden copy beside an exact line is ignored) is the user's Q-112 ruling, Won't-Fix.
- **Test fixtures' hermeticity (B7).** The new tests write only into `$BATS_TEST_TMPDIR/repo`, with `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, a temp `HOME` and fixed identities (`bl_setup`, `dev-cycle.bats:8-20`). `x.md`, the replace ref and `core.useReplaceRefs` stay in that temp repo. T7's NUL object is piped straight to `git hash-object`, never through a shell variable, and its steps are now standalone (fact-check Claim 12, executed). The new main_entry test sources the lib from `$REPO_ROOT` but runs git in the temp repo (cwd). The one gap is Finding 1's `&&` chains. bl_setup not clearing `GIT_DIR` is deferred and not re-filed.

## Untested bypass candidates

- **B1:** a path that pathform accepts but git's pathspec matching would still treat specially. Not tested beyond the probe list above. pathform permits only `[A-Za-z0-9._/-]`, the lib's callers export `GIT_LITERAL_PATHSPECS=1` (`build-loop.sh:117`, `dev-cycle.sh:126`), and none of the accepted characters is pathspec magic without `:`. It stays listed because a direct sourcer of the lib that omits `GIT_LITERAL_PATHSPECS` was not exercised. That sourcer would still be limited to that alphabet.
- **B5:** a non-numeric `GIT_CONFIG_COUNT` (for example `a[$(id)]`) reaches bash arithmetic at `build-loop.sh:116`. Not tested: the source is S5, a trusted caller that already runs code, the line is not in this range, and the i2 pass already listed it.
- **B6:** a promisor or partial clone with a missing brief blob (a lazy fetch or a different exit). Not tested: there is no promisor remote in a probe repo. Row 293 covers the missing-object case.

## Endorsement Claims

- **Claim:** main_entry answers `error`, with no ls-tree call, for each of the 16 refused path forms listed above, in the C, C.UTF-8 and unset-UTF-8 locales, and answers `blob` / `absent` for the two accepted ones.
  **Location:** `scripts/lib/dev-cycle-read.sh:262-278`
  **Evidence:** executed
  **Verified:** `$S/probe.sh` output in all three locales. The fact-check's GIT_TRACE showed 0 git calls for refused paths (Claim 9).
  **Not verified:** U2's floor feeding it paths from `git diff -z` output, since that caller does not exist yet.
  **route: code-fact-check**
- **Claim:** The U1d `--settings` caller-config step fails when build-loop.sh's guard pair export is removed, provided its `git replace` fixture succeeds.
  **Location:** `test/scripts/build-loop-read.bats:434-438`
  **Evidence:** executed
  **Verified:** the `$S/m/guardonly` copy fails with `policy self-merge set:`, and `$S/m/ctl` passes.
  **Not verified:** the fixture-failure path, which passes vacuously (Finding 1).
- **Claim:** The could-not-be-listed skip at `build-loop.sh:343` still fires for every open brief when git grep exits above 1, and the reworded line is a refusal (`skip`).
  **Location:** `scripts/build-loop.sh:315-316`, `:343`
  **Evidence:** executed (fact-check Claim 6, and the U1d --status test at `:476-478` with the caller's bogus `grep.patternType`)
  **Verified:** `skip $o: the open briefs on the default branch could not be listed` at HEAD.
  **Not verified:** a corrupt tree object (as opposed to a blob) under `docs/working/briefs/` on main.
  **route: code-fact-check**

## Primitive sweep

Primitive: git pathspec / path lookup on main's commit (path-traversal family)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:267` `git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1"` | S1 | main_by_name + pathform (new, `:265`); `--`; GIT_LITERAL_PATHSPECS from both callers | cleared: probed (Endorsement 1) |
| `scripts/lib/dev-cycle-read.sh:301` `git cat-file blob "$MAIN_SHA:$1"` (brief_fields) | S1 | pathform + main_entry == blob (`:298`) | cleared: unchanged; guarded before the read |
| `scripts/build-loop.sh:136` `git cat-file blob "$MAIN_SHA:$f"` (main_file) | code-constant names | main_entry == blob | cleared: fixed names that pathform accepts (fact-check Claim 9) |
| `scripts/build-loop.sh:315` `git grep ... "$MAIN_SHA" -- docs/working/briefs/` | code-constant pathspec | literal pathspecs; exit > 1 fails closed | cleared: unchanged pathspec |

Primitive: bash arithmetic evaluation (eval-family), sibling context only

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:116` `$((cfg + 1))` | S5 GIT_CONFIG_COUNT | none | cleared: S5 is trusted; not in range (listed under untested bypass candidates) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | The replace-ref guard test's `git replace && git config` chain lets the test pass with the guard removed if the fixture fails (siblings `:464`, `:469`) | Low | B5, B7 | `test/scripts/build-loop-read.bats:436` | High |
| 2 | main_entry's test has no positive control that main was found by name | Informational | B1 | `test/scripts/dev-cycle.bats:1330-1337` | High |

## Overall Assessment

The branch adds one guard and moves one boundary. main_entry now refuses any path pathform refuses before any git call, and every bypass input I tried answered `error` in three locales. The reworded fail-closed and never-line text claims no more than the code delivers. The new tests are hermetic and pin the guards they name, with one exception (Finding 1). Three of the new fixture `&&` chains, including the one in the replace-ref guard test, can turn a fixture failure into a silent pass. I showed this by execution for the guard test. It is Low because no runtime path is weaker and the trigger needs a git failure in a fresh temp repo. Finding 2 is optional. Within the code paths read and executed, nothing blocks the merge. The endorsement claims are executed and each names its `Not verified` hop. The most useful single change is to split `:436` (and `:464`, `:469`) into standalone statements, the same fix T7 got in 07c354c5.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u1d.md (first line `Commit: ab71bce5`), structured per the security-reviewer skill.
- Answered: yes. Whole branch reviewed: main_entry's guard (probed), the fail-closed wording (checked against code and the fact-check's executed probes), and fixture hermeticity (read, plus mutant runs).
- Out of scope: the `&&` chain at `build-loop-read.bats:84` (on main); the deferred and Won't-Fix items listed in the shared context, none re-filed.
- Escalate: nothing. No HALT pattern matched.
