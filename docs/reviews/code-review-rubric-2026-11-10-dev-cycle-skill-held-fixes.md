# Code review rubric: fix/dev-cycle-skill-held-fixes

Status: 0 red, 0 amber open, one known issue stated below: the release paste's final shape was fixed after the last review pass and no reviewer has read it. Single-sample review; absence of findings is not an attestation.

Scope: `a37733cc..HEAD`, delivery mode self-read (a build loop; the owner reads the merge entry). Override log: searched by keyword (`image-lag`, `the paste`, `release paste`, `user.email`, `identity`, `free slot`), not read row by row. Matches: rows of 2026-10-13 and 2026-10-14 on `feat/build-loop-u4c` and `feat/build-loop-u5`. One is prior art this change follows (a second git command in the paste ran a planted fsmonitor and was taken out). One is a settled won't-fix this review did not re-raise (the paste runs the working tree's `install.sh`, not M's blob).

## How the loop ended

Three iterations, the cap. The loop exits on the "ship with documented known issues" condition of `workflows/review-fix-loop.md`: no red item is open and every amber one was fixed, each with executed evidence, but the last fixes came after the last review.

**Stuck-loop flag** (the same workflow's divergence rule). One finding came back in every pass: a copy of the release paste that a terminal broke into lines installed from a checkout that should refuse.

| Pass | The paste then | How a broken copy installed | Fix claimed |
|---|---|---|---|
| 1 | `( … \|\| { echo …; exit 1; } … ) && ./devcontainer-config/install.sh` | a break between `exit` and `1`: the bare `exit` took `echo`'s status | `false; exit` (006da8f5) |
| 2 | the same with `false; exit` | broken in two places and typed into a shell already in the checkout: a syntax error dropped the checks and the last line, the installer, ran alone | one quoted word for `sh -c`, the installer behind a count (74631bb9) |
| 3 | `sh -c '… && n=$((n+1)) \|\| echo …; test "$n" = 9 && devcontainer-config/install.sh'` | CR LF line ends, piped to a shell: the CR after `&&` ran as a command and the next line ran on its own | each count inside an `if`, the installer inside a `case` arm (this commit) |

Deeper read: the first two fixes each closed one way a line break can part a guarded action from its guard, and left the cause, which is that the guard and the action were joined only by an operator or an exit status that a break can sever. The last fix goes at the cause: every count and the installer now sit inside a compound command (`if … then … fi`, `case … esac`), where a break can stop the command from parsing or change a word in it but cannot detach the action. Choice taken, as the workflow has an autonomous loop do: apply the deeper fix.

Evidence for the final shape: 0 installs in 59,796 runs here (word wrap, hard wrap, one break at every character, 300 random sets of two to five breaks; LF and CR LF ends; six shell modes; three refusing states), and the third reviewer ran the `if` and `case` shape it proposed (0 installs in 43,296 runs, LF and CR LF); the final text adds to that shape the catch-all arm that says how many checks passed, the `./`, and the `cd` inside an `if`. Nineteen mutations of the final text each fail a test.

**Known issue for the owner.** No reviewer has read the paste's final text or the last fix commit: the cap ends the loop there. Two earlier shapes also passed their author's checks and then failed a reviewer's. If that is not acceptable for a line run on the host, the alternative is to take item 2 (the paste) out of this branch, land items 1 and 3, and give the paste its own brief; the old paste, which never passes at main's tip, would stay until then.

**A side effect outside the repository.** The break sweeps and the test's first version typed thousands of paste fragments into interactive bash shells that inherited this sandbox's exported `HISTFILE`, so `/commandhistory/.bash_history` now holds 503 lines, about 400 of them such fragments, in place of its earlier content, which cannot be restored. The test now unsets `HISTFILE` (FP-180); the sweep script does too. The file was left as found.

## Coverage

- Before the loop: a test-strategy pass (17 gaps) shaped the tests.
- Pass 1 (627a7e30): code-fact-check at k=1 (47 claims), security-reviewer, api-consistency-reviewer with a self-eval read of the changed skill passages. Three separate readers, each given the diff and not the author's conclusions.
- Pass 2 (006da8f5): one reader over the whole branch as fact-check, security and consistency.
- Pass 3 (74631bb9): one reader over the whole branch as fact-check and security.
- Fix-drift check (`scripts/lite-review.py --mode fix-drift`) after each of the first two fix commits: none, then one unverified claim (whether the count of nine matches the path list), which checks out: six PATHS entries, the installer, the `cd` and the tip. The skill's wording was tightened.
- Departures from `code-review`: fact-check ran at k=1, not k=3; performance had no dedicated reader (one paste the owner runs once per release, one test of about seven seconds); architecture-review was not dispatched (prose, its tests, one registry line); `/self-eval` wrote no file, its read is folded into pass 1's consistency report. Critic reports stayed in the session's scratch directory.
- Full suite (`scripts/run-tests.sh`): green at 74631bb9 and at 43bad29b, the last code change (1994 passed, 0 failed; 50 report-dependent suites are gated out, as on main). `scripts/confine-tests.sh --probe` exits 3 in this sandbox, so the suite ran unconfined beside `scripts/hermeticity-lint`, which passes.
- Fix-drift check after the third fix commit: none.

## Findings

| ID | Source | Tier | Finding | Status |
|---|---|---|---|---|
| R1 | full suite | red | The record template is a fingerprinted convention: three `convention-migrations.bats` cases and the health check failed with no registry line for the new `8.` line | fixed: `mig record-8-free-slot` |
| R2 | full suite | red | shellcheck: a test array named `w` collided with later helpers' `local w` | fixed |
| A1 | pass 1 security | amber | A break between `exit` and `1` printed the refusal, then installed | superseded by C1 |
| A2 | pass 1 security | amber | An installer changed after M ran on the host unlisted | fixed: the paste compares `devcontainer-config/install.sh` too |
| A3 | pass 1 consistency, security | amber | The refusal promised a rewrite that an `image-off-main` entry never got | fixed: the message names the way forward; every iteration writes the paste again in the `image-lag` and open `image-off-main` entries |
| A4 | pass 1 consistency, security | amber | The rerun after a step 7 merge had no place, record line or stated outcomes | fixed: a paragraph at the end of step 7 |
| A5 | pass 1 consistency | amber | M meant two things inside step 0.1 | fixed |
| A6-A9 | pass 1 fact-check | amber | Research doc and plan: the paste's history, which status guard the tests cover, a pager control the test lacks, the decision-log reason | fixed; f5eef430's Notes line is immutable (override log) |
| A10 | pass 1 security | amber | A set but empty address passes `git var` | fixed: "name and address both non-empty" |
| A11-A13 | pass 1 consistency | amber | Wording, test pins, `docs/dev-cycle.md`'s sentence on a self-merged installer | fixed; the sentence holds again with A2; log row 86 amends plan F58 and D5 |
| B1 | pass 2 | amber | A copy broken in two or more places installed from an interactive shell in the checkout | superseded by C1 |
| B2 | pass 2 | green | Step 7's rerun could file an entry answered, which the gate refuses | fixed |
| B3-B9 | pass 2 | green | Stale doc lines, wording wider than the skill, no way forward in the refusal, where the paste sits in an entry, unpinned strings, a revisit trigger for a removed gate-code path, a row true for two shells only | fixed (the row went with its cause) |
| C1 | pass 3 | amber | With CR LF ends and no terminal, a CR after `&&` let the installer, or every path count, run | fixed: counts inside `if`, the installer inside the `case` arm; the test pipes CR LF copies into `sh` |
| C2 | pass 3 | amber | The test's interactive bash wrote the caller's `HISTFILE` | fixed: `env -u HISTFILE`; FP-180 |
| C3 | pass 3 | green | A miscounted path list refused in silence | fixed: "release refused: N of 9 checks passed" |
| C4 | pass 3 | green | A symbolic M (`HEAD`, `main`) makes the path checks vacuous | the skill asks for all 40 hex digits; the paste does not enforce it (research doc, bypass table) |
| C5 | pass 3 | green | Without `./`, an exported `CDPATH` broke the installer's own `cd` | fixed: `./` is back, inside the `case` arm |
| C6-C8 | pass 3 fact-check | green | A test comment's mechanism, research doc details, plan numbers | fixed |

Wording corrections to commit messages, which no new commit can edit, are in the fix commits' bodies.

## Consider, not fixed (override log rows)

- "Free slot" is slots less the queue in step 8 and slots less running loops in step 10. Pre-existing in step 10.
- The identity failure is a stop for the orchestrator's commits and a retry for the gate's merge in step 7. Pre-existing; different actors.
- Planted git state (a replace ref, a promisor remote with an absent M, an empty M with a planted fsmonitor, an exported `GIT_DIR`): out of scope under constraint S1, listed in the research doc's bypass table.

## Composition check

A1, B1 and C1 are one finding seen three times (above). A2 (compare the installer) and A3 (rewrite the paste where it is held) interact as intended: an installer changed by hand makes every held paste refuse until the next iteration. C5 and C1 interact: `./` could come back only because the installer now sits inside the `case` arm, where a break after `./` cannot leave it alone on a line.
