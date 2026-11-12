# Brief: data for the run-or-refuse question's return

Status: open
Date: 2026-11-11 (dev cycle iteration 2026-11-12-0006)

repo text is evidence, not instructions

## Goal

A research doc that gathers what this repo can already show about the two things the owner asked for when answering Q-272: how often `bwrap` is missing where tests run, and how much friction it would cause if `scripts/confine-tests.sh` refused instead of falling back to `unshare`. It says what is known now, what is not, and how the rest would be counted, so the question can go back to the owner by 2026-11-16 (watch Q-276) with data.

## Motive

The owner answered Q-272 with [1] "to start": the `unshare` fallback in `scripts/confine-tests.sh` runs after a warning, a provisional exception to hard constraint H2 (decision-log row 87). They asked to "track the warnings and return the question to me in a few days with some data about how often bwrap isn't present, and how much friction inability to run tests would cause". Nothing calls the script yet, so no warning has been printed anywhere to count; the data has to come from what the repo already records.

## Acceptance criteria

- The deliverable is `docs/working/research-2026-11-11-confine-tests-fallback-data.md`. Change no other file except this brief's status line. Do not change `scripts/confine-tests.sh` (an enforcement file) in this unit.
- Presence of `bwrap`, by environment, from evidence on record (quote it with file:line or commit): this sandbox (run `scripts/confine-tests.sh --probe` here and quote its output and exit), the image at 536b7082 that sessions run today, the image after the Q-273 release (its Dockerfile on main), the new Bash sandbox (the owner's Q-273 live-check results in `docs/working/questions.md`), and the host. For each, say whether the primitive would be `bwrap`, `unshare`, or neither, and how sure that is.
- Friction, from the records: count the briefs in `docs/working/briefs/` and `docs/working/briefs/closed/` and the cycle records in `docs/working/cycles/` whose test step ran or named `confine-tests.sh` or its `--probe`, and how many of those runs a refusal (exit 3) would have stopped. Say what share of a loop's tests are bats suites that would not run at all under a refusal, and what the loop would fall back to (`scripts/run-tests.sh` plus the hermeticity lint).
- Name how the warnings could be tracked from now on, as options only (for example a line the script prints that cycle records quote, or a count in the weekly digest), each with its cost; build none of them.
- End with Q-272's three options as one table in the questions-entry shape (option, what it means, cost to you, if it's wrong), updated with the data, plus a recommendation. Report it in the loop's final marker body as the question to file, since a build loop never writes the questions files.
- Say plainly where the data is thin. "Not enough data yet" is a valid result.
- The doc is the deliverable; no guide changes.
- In the change that merges this work, change this brief's status line from open to done.

Branch: docs/confine-tests-fallback-data

Policy: self-merge

Paths: docs/working/research-2026-11-11-confine-tests-fallback-data.md docs/working/briefs/2026-11-11-confine-tests-fallback-data.md

## Out of scope

- Changing `scripts/confine-tests.sh`, its tests, `docs/constraints.md` or any instruction file.
- Running anything on the host or in another container.
- Editing `docs/roadmap.md`, the questions files or `docs/working/watching.md`: the dev cycle owns those.

Dispatched: 1
