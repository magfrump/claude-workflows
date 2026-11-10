# Pre-Mortem: the two confine-tests fixes

**Proposal:** the diff 23ffb16c..ca6cf3be (details below were brought up to date after the two review passes changed the warning's wording and corrected the prior-art sentence) on `fix/confine-tests-dash-and-fallback`: `scripts/confine-tests.sh` runs its `unshare` body under `"$BASH"` with `exec -- "$@"`, and a run that falls back from bwrap to unshare prints a warning first. Plan and design record: `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md`.
**Date:** 2026-11-10
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** Failure narratives are generated directly
> from the proposal. For higher-quality narratives, run `what-if-analysis` first and
> provide its output — this skill is sharpest when seeded with already-mapped assumptions
> and coupling points.

Why this ran: pr-prep's fallback check fired on a count of 539 changed lines, 301 of them the research doc; 238 lines change outside `docs/` (227 in the script and its test, 11 in the guide), none in an enforcement file. The plan had recorded "not triggered". It is run here by the author, inline, with no agent dispatch.

Prior art: `grep -ril -e 'BASH_ENV' -e 'uid 0' -e 'warning fatigue' -e 'unshare -r' docs/decisions/ docs/working/` returns 17 files: decisions 017 and 019, the three confine-tests research docs (this unit's among them) and both confine-tests briefs, five cycle logs, and five other working docs. I read the confine-tests ones and decision 017, not all 17. Decision 017 and `docs/working/research-2026-11-07-confine-tests-situation.md` already hold narrative 1's ground (the unshare tier is weaker); I found narratives 2 to 4 in none of the files I read.

## Failure Narratives

### 1. "Confined and green", ten tests short

- **Root cause:** `--probe` on a host with `unshare` and no usable `bwrap` prints `primitive available: unshare (loopback=1)` and exits 0, with no warning (the brief keeps `--probe` unchanged; `scripts/confine-tests.sh`, the block under "# --- run").
- **Chain of consequences:** The cc-isolated sandbox merges and the image gains a kernel that allows `unshare -rn` in a session where nested `bwrap` is refused. A build loop follows its brief's wording (`docs/roadmap.md:49`: "exit 0: tests pass confined"). It runs `scripts/confine-tests.sh -- scripts/run-tests.sh` with output sent to a file, as the repo rules ask. The run prints the new warning as the file's first six lines. `unshare -r` makes the suite uid 0, so ten tests skip on the guard `[ "$(id -u)" -ne 0 ] || skip`: one each at `test/cc-push.bats:417`, `test/hooks/guard-trusted-writes.bats:889` and `test/install-host.bats:680`, and the seven that call the helper `not_root()` (`test/cc-isolated-functions.bats:1970`). The loop reads the last line, sees a pass, and records "passes confined".
- **Observable outcome:** a research doc says the suite passed confined; the run's file starts with `confine-tests: WARNING — bwrap is unusable here` and lists ten skips that an unconfined run does not have. Nobody quotes either.
- **Plausibility:** Plausible
- **Severity:** Low (ten permission tests, each still run by the unconfined gate)
- **Tag:** `[PRIOR CONSIDERATION]` in part: `docs/working/research-2026-11-07-confine-tests-situation.md` (the unshare tier), FP-050.
- **Revisit trigger:** the first `scripts/confine-tests.sh --probe` in any session whose first line reads `confine-tests: primitive available: unshare`; at that point the brief wording at `docs/roadmap.md:49` ("exit 0: tests pass confined") should ask the loop to quote the run's first stderr line beside the probe's.

### 2. The wrapper that read line one

- **Root cause:** on a fallback run the first stderr line is now `confine-tests: WARNING — ...`; before, it was the banner `confine-tests: denying network via unshare (loopback=1)` (`scripts/confine-tests.sh`, the `fell_back` block printed before the banner).
- **Chain of consequences:** Another project adopts the runner as `guides/test-hermeticity.md` suggests and wraps it in a CI step that checks the first stderr line for `denying network via` to confirm confinement was on. Its runner image has no bwrap. After this change the first line is the warning, the check fails, and the job goes red on every commit with tests that never ran differently.
- **Observable outcome:** a CI step fails with "confinement banner not found" on the first run after the script is updated; the log shows the banner on line seven.
- **Plausibility:** Unlikely-but-catastrophic by label only: under 10% (no caller exists in this repo, and `grep -rn confine-tests` over code finds no caller, only a comment in `test/fixture-hermeticity.bats`), and the cost is one red job and a one-line fix.
- **Severity:** Low
- **Mitigation:** none taken in code; the order is deliberate (a warning after the banner reads as an afterthought, and `--no-loopback`'s has always come first). `scripts/confine-tests.sh`'s header, under "WHY IT NEVER DEGRADES QUIETLY", now says the warning comes first on stderr, which is the contract such a wrapper should read.

### 3. A `BASH_ENV` that phones home

- **Root cause:** the `unshare` body runs under `"$BASH" -c` (`scripts/confine-tests.sh`, `exec unshare -rn -- "$BASH" -c`), and a non-interactive bash sources the file `BASH_ENV` names; the `sh` it replaces does not, whether it is dash or bash started as `sh` (run here: `BASH_ENV=FILE bash -c`, `dash -c` and bash linked as `sh`; only the first sourced FILE).
- **Chain of consequences:** A CI image exports `BASH_ENV=/etc/ci/env.sh`, which runs a version-manager's init that checks a remote index. Outside the namespace it answers in 40 ms. The body now sources it a second time, inside the namespace, where the lookup has no route: the init waits out a 30-second connect timeout before the body's first line runs, and then the test runner (itself bash) pays it again as it did before.
- **Observable outcome:** every confined run on that image starts 30 seconds later than it did; `ps` during the wait shows `bash -c` under `unshare` with a `curl` child.
- **Plausibility:** Unlikely-but-catastrophic by label only: under 10%, and only on the unshare-with-loopback form.
- **Severity:** Low (a delay; the test command, almost always a bash runner, already pays the same cost inside the namespace)
- **Revisit trigger:** a confined run whose time to the first test line exceeds the same command's unconfined time by more than 5 seconds with `BASH_ENV` set; the fix then is `"$BASH" -p -c` or `env -u BASH_ENV` on that one line, weighed in the research doc's DD-1 under "Stress-test mitigations".

### 4. The dash test that never ran

- **Root cause:** the test "…: sh is dash" in `test/scripts/confine-tests.bats` begins `dash="$(type -P dash)" || skip "dash is not installed on this machine"`.
- **Chain of consequences:** The suite moves to a host image without dash. The test skips on every run. A later edit, made to "simplify" the body, returns it to `sh -c '...; exec -- "$@"'` because `sh` is bash on that host and the bash test passes.
- **Observable outcome:** the edit would be caught anyway: the tests build a PATH with no `sh` on it, so four other tests fail with `exec: sh: not found`, and the argv pin in the unshare run test names `"$TOOLS/bash"`. The mutation run shows it: the mutant "body under sh again" fails tests 16, 18, 19, 20 and 21, and on a host without dash it would still fail 16, 19, 20 and 21.
- **Plausibility:** Plausible that the skip happens; Unlikely that it hides anything.
- **Severity:** Low
- **Mitigation:** already in the test file: `setup()` links only `bash`, `cat` and `awk` into `$TOOLS`, so the script's independence from `sh` does not rest on the dash test.

## Recommendations

- **Must address before proceeding:** none. No narrative makes shipping without a change reckless.
- **Worth mitigating:** narrative 1, by the dev cycle and outside this brief's Paths: when a probe first names `unshare`, have briefs ask for the run's first stderr line. It is listed in the research doc's follow-ups.
- **Acknowledged risks:** narratives 2 and 3 (no known caller; the environment is the caller's own) and 4 (covered by the built PATH).
