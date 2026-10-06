Commit: cc75db98

# Security Review: feat/build-loop-u1d, iteration 2 (fix commit 6c83af2a)

**Scope:** partial scope (loop pass). `83cdb005..cc75db98`, limited to scripts/ and test/, which is fix commit 6c83af2a. The rest of the branch is context only.
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u1d.md` (k=1, `Commit: cc75db98`, 21 verified, 2 mostly accurate)

Probe logs and copies are under `/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/i2sec/` (`$S` below). Every probe ran under `timeout` and has exited. Each probe repo or tree copy was made in its own fresh directory under `$S`.

## Trust Boundary Map

```
B1: docs/dev-cycle.md blob on main's commit  → SETTINGS_AWK copy count + exact-line parse → POLICY / NEVER (self-merge gate)
B2: brief blobs on main (git grep, brief_fields) → shared_branches (F31)                 → open-brief skip / ok line
B3: branch-tip commit object (loop-written)   → marker_kind (NUL, parents, tree, subject) → LOOP state (ready/blocked/stopped)
B4: caller environment (GIT_CONFIG_COUNT pairs) → guard pair appended at index COUNT      → config of every git read
B5: object store state (missing / corrupt objects) → git grep exit code                 → SHARED_BRANCHES=error or "not counted"
B6: test runner environment (bats)            → bl_setup's exported git env + temp repo   → fixture writes (T7 NUL object)
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | docs/dev-cycle.md on main | runtime-mutable (any merge to main) | UNTRUSTED for value-setting: only an exact line sets a value; trusted for nothing beyond that |
| S2 | brief files on main | runtime-mutable (dev cycle writes them) | UNTRUSTED for output and branch names (scrub, check_branch); trusted as the dispatch record |
| S3 | build-loop branch tip and objects | request-time (the loop writes them) | UNTRUSTED for all sinks: this is the boundary the script exists to police |
| S4 | caller env (GIT_CONFIG_*, `git -c`) | deploy-time (the orchestrator's own process) | trusted, per the script's own comment (`build-loop.sh:110-111`); it already runs code |
| S5 | repo object store health | runtime-mutable | untrusted for availability: must fail closed |
| S6 | bats runner env (GIT_DIR, GIT_INDEX_FILE, ...) | deploy-time (whoever runs the suite) | should be neutralized by the fixture, not trusted |

What crosses: the fix commit changes no executable line in scripts/. It rewrites comments and help text on B1, B2 and B5, and adds tests on B3, B4 and B6. So the security question is the one the brief poses. Do the reworded fail-closed claims promise more than the code delivers? And do the new tests pin the guards they name, without vacuous paths?

## Findings

#### 1. T7's NUL step can pass without asserting anything: a failed fixture build skips the check

**Severity:** Low
**Location:** `test/scripts/build-loop-read.bats:295-296`
**Boundary:** B3 (marker_kind's NUL refusal), B6 (fixture)
**Move:** 3 (error path), 11 (bypass of a guard's regression test)
**Confidence:** High
**Legibility target:** the test line itself (a reader sees `check ... nul` and assumes it ran)

Evidence (verbatim, `build-loop-read.bats:295-296`):

```
    o="$(printf 'tree %s\nparent %s\nauthor t <t> 0 +0000\ncommitter t <t> 0 +0000\n\nhandoff: ready\n\n\0x\n' "$(git rev-parse "$base^{tree}")" "$base" \
        | git hash-object -t commit --literally -w --stdin)" && git update-ref refs/heads/feat/a "$o" && check "skip $B: $n: it holds a NUL byte" nul
```

Bash's errexit does not fire for a failing command inside an `&&` list unless it is the last one. If `git hash-object --literally` or `git update-ref` fails, `check` never runs and the test goes on to the next step. The sibling two-trees fixture two lines above is a standalone assignment, so the same failure stops it. Executed: in a `git archive HEAD` copy (`$S/p2/base`), I changed only this line's `--literally` to `--no-such-flag` and deleted marker_kind's NUL line (`build-loop.sh:286`). `bats -f T7` printed `ok 1 ... (T7)` with exit 0, so the NUL check was gone and the test still passed. Controls: the same flag change on the two-trees fixture fails T7 at `:292` (`failed with status 129`, `$S/p2/ctl`). With only the NUL line deleted, T7 fails at `:296` (`[nul] ok ... ready`, `$S/p2/ctl2`), which matches the fact-check's nul mutant.

So the commit message's claim, "deleting marker_kind's NUL check now fails T7", holds only while the fixture builds. On git 2.39.5 it does. On a git whose `hash-object` refuses this object or drops `--literally`'s check bypass, row 291's C17 would quietly reopen. This is Low and not Medium: no code path is weakened by it. The mechanism takes two independent events, a git change and a regression in the NUL check. It is a test-integrity gap on a guard of B3, not an exploitable path.

**Recommendation:** Write the step in the two-trees fixture's shape: a standalone `o="$(...)"`, then `git update-ref ...` and `check ...` on their own lines. Any fixture failure then fails the test.

#### 2. The never-line comment's "a task box" counts as missed, but an unchecked box is counted (safe-side imprecision)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:17-20`
**Boundary:** B1
**Move:** 5 (invert the guard: what does the copy count let through?)
**Confidence:** High
**Legibility target:** the `--settings` help text (`-h` prints it)

Evidence (verbatim, `build-loop.sh:17-20`):

```
#                 also needs one exact never line. A never list in markup the
#                 copy count sees (bold, a list marker) is a second copy and
#                 turns self-merge off; one it misses (a task box, a fence) is
#                 ignored, so self-merge rests on the exact line alone.
```

This builds on fact-check Claim 1b (executed). `- [ ] Self-merge never: b/` adds no letters, so the copy count sees it, and beside an exact line it gives `never malformed` and `policy review unset`. Only a checked box (`[x]`, `[X]`) adds a letter and is missed. The error points the safe way: the code is stricter than the comment. The sentence does not over-claim, and it now states the residual risk plainly. A never list hidden in letter-adding markup next to an exact line is silently dropped, and self-merge governs on the exact line. That is the user's Q-112 [1] ruling (`docs/reviews/override-log.md:256`, Won't-Fix: "A hidden copy next to an exact line is ignored, and the exact line governs"), so it is not a finding against this range.

**Recommendation:** Optional wording: "a checked task box, a tag, a fence". No code change.

## Answers to the focus questions

- **Reworded fail-closed claims.** None claims more than the code delivers.
  - Never-line rule: see Finding 2. The comment errs on the safe side.
  - Skip-list order: the help lists the skips as alternatives joined by "or", not by precedence. The code checks F31 (`:341-342`) before the marker (`:352-357`). Either way the brief skips, and only the WHY differs. Fact-check Claim 2 (executed) confirms that the marker skip applies to every state and the two F31 skips to open briefs only.
  - Corrupt and missing objects: the fact-check executed loose-object corruption, so I extended it to a **packed** object. In `$S/p1/repo`, after `git repack -ad` and `prune-packed`, I flipped 6 bytes inside the compressed data of brief c's blob. git grep printed `fatal: packed object ... is corrupt` and exited 128, and `--status` on brief a printed `skip ...: the open briefs on the default branch could not be listed`. So "a corrupt object's included" holds for both storage forms on git 2.39.5. The missing-object half ("is not counted") is a documented fail-open on F31 that row 293 already accepts.
  - main_entry's error list: fact-check Claims 5 and 6 (executed, GIT_TRACE: 0 git calls for refused paths). The lib resets `MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""` at source time (`dev-cycle-read.sh:247`), so "without resolve_main" cannot be defeated by stale or inherited values.
- **T7 NUL fixture hermeticity.**
  - Inside its env it is hermetic. The object goes into the bats temp repo (`$BATS_TEST_TMPDIR/repo`), with `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1` and a temp `HOME`. Author and committer are fixed in the raw object. The NUL is piped straight to git, never held in a shell variable, which would drop it.
  - Two caveats. Its `&&` chain can turn a fixture failure into a silent pass (Finding 1). And bl_setup, which is shared and predates this branch, does not clear an inherited `GIT_DIR` or `GIT_INDEX_FILE` (see "Out of scope").
- **grep.patternType pair on --status.** It asserts the documented model. The pair is in the caller's environment (S4), which the script trusts by its own comment. The step pins only that the caller's pairs are kept (mutant cfg0 dies at `:472`), and the value it uses fails closed (the open brief skips). It therefore pins no fail-open behavior. The guard surviving a caller count is pinned separately, in the --settings test (mutant guardskip dies at `:433`). A caller pair on the *same* key (`core.useReplaceRefs=true` at index 0) is not tested. git applies GIT_CONFIG_COUNT pairs in order, so the guard at index COUNT would win. Under the stated model a caller may override anyway (`git -c`), so this is not a security property and needs no test.

## Untested bypass candidates

Guards whose claims this commit rewords:

- **Copy count (B1):** an HTML tag (`<b>Self-merge never: x/</b>`). Not tested: the help already says a tag can hide a copy (`:41-44`), and the user ruled on it in Q-112.
- **F31 fail-closed (B5):** a partial or promisor clone with a missing blob, where git may fetch it lazily or report it differently. Not tested: no promisor remote in a probe repo, and it is outside this repo's setup.
- **Guard pair (B4):** a non-numeric `GIT_CONFIG_COUNT` (for example `a[$(id)]`) reaches bash arithmetic at `build-loop.sh:114`. Not tested: the source is S4, a trusted caller that already runs code, and the line is not in this range.

## Endorsement Claims

- **Claim:** A corrupt packed brief blob on main makes git grep exit above 1, and every open brief then skips with "could not be listed".
  **Location:** `scripts/build-loop.sh:308-314`
  **Evidence:** executed
  **Verified:** `$S/p1/repo`, git 2.39.5: corrupt packed blob, git grep rc=128, `--status` on the other open brief printed the could-not-be-listed skip.
  **Not verified:** a corrupt *tree* object on main's commit, and git versions other than 2.39.5.
  **route: code-fact-check**
- **Claim:** The --status caller-pair step fails when the guard export overwrites the caller's `GIT_CONFIG_KEY_0`.
  **Location:** `test/scripts/build-loop-read.bats:470-472`
  **Evidence:** executed (fact-check mutant cfg0)
  **Verified:** the cfg0 mutant fails at `:472` and survives 83cdb005's tests (fact-check table).
  **Not verified:** a caller pair on the guard's own key (precedence by index).
- **Claim:** main_entry answers error for the four refused paths before making any git call.
  **Location:** `scripts/lib/dev-cycle-read.sh:261-264`
  **Evidence:** executed (fact-check Claim 6, GIT_TRACE)
  **Verified:** 0 git calls for `a"b.md`, `../x`, `-x` and `docs//x.md`; 1 call for a valid path.
  **Not verified:** brief_fields' callers in dev-cycle.sh with paths that come from argv after a cd.

## Primitive sweep

No dangerous primitive is added or changed in the fix range. The production changes are comments and help text. The test additions run git plumbing on fixture data (`hash-object --literally`, `update-ref`) and `env ... bash "$BL"`. One eval-family site, in sibling context and unchanged, came up in move 11:

Primitive: bash arithmetic evaluation (eval-family)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:114` `$((cfg + 1))` | S4 GIT_CONFIG_COUNT | none | cleared: S4 is the trusted caller, which already runs code; not in range |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | T7's NUL step is `&&`-chained; a failed fixture build skips the check, so the test passes with the NUL check deleted | Low | B3, B6 | `test/scripts/build-loop-read.bats:295-296` | High |
| 2 | "a task box" counted as missed; an unchecked box is counted (safe side) | Informational | B1 | `scripts/build-loop.sh:17-20` | High |

## Out of scope, observed (pre-existing, not filed against this range)

- **bl_setup does not clear inherited git location variables** (`test/lib/build-loop-fixtures.bash:7-19`, last changed in c143b929 on main). I ran `GIT_DIR=$S/p3/victim/.git bats -f T7 ...`. It appended three fixture commits (`initial`, `settings`, `brief a`) to the scratch victim repo's checked-out branch `keep`. A suite run from a git hook, where git exports `GIT_INDEX_FILE` and sometimes `GIT_DIR`, could write into the real repo the same way. Suggested hardening for a later unit: `unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT` in bl_setup and in dev-cycle.bats' setup.
- **check_branch ignores failures of its inner command substitutions** (`dev-cycle-read.sh:383`, `$(git rev-list --count ...) $(git log -1 --format=%cs ...)`). The fact-check saw a done brief's `ok` line with an empty DATE under the caller's bogus grep pair. The field count then shifts for a whitespace-splitting reader. When `rev-list` fails, `ahead` is empty and `[[ "" -gt 0 ]]` is false, so marker_kind is skipped and the line reads `working`. Reaching that takes a trusted caller's env or a damaged object store. Worth a fail-closed check in a later unit.

## Overall Assessment

The fix commit changes no executable code. Its reworded fail-closed claims hold, and where they are imprecise (the task box) they err on the safe side. I executed the corrupt-object claim for packed storage, beyond the fact-check's loose-object probe. The new tests pin the guards they name, with one exception: T7's NUL step is `&&`-chained, so a fixture failure would turn the C17 regression test into a silent pass (Finding 1, Low). The fix is a one-line restructure. Within the code paths read and executed, the change is safe to merge; the endorsement claims are either executed or scoped with their `Not verified` hop named. The single most useful change is to split T7's NUL step into standalone statements.

## Goal-Alignment Note

The goal was to land U1d, and this pass reviews whether 6c83af2a's fail-closed wording and tests are honest. All three focus questions are answered with executed evidence. The wording claims no more than the code delivers. The T7 fixture is hermetic inside its env, but its `&&` chain can let it pass vacuously. The caller-pair test pins the documented trust model (caller env trusted) with a fail-closed value. Neither finding blocks the merge. The two pre-existing observations (bl_setup env leakage, check_branch's unchecked substitutions) fall outside this range and belong in a later unit's backlog, not this loop.
