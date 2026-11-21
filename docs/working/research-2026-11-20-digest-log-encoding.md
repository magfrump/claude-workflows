# Research: the digest reads commit text under UTF-8, whatever the repo's log encoding

**Goal:** every git read in the dev-cycle digest (`scripts/dev-cycle.sh` and the lib code it calls) prints message text in UTF-8, even when the repo sets `i18n.logOutputEncoding` (brief `docs/working/briefs/2026-11-20-digest-log-encoding.md`).
**Problem framing:** the setting changes the bytes git prints for a formatted commit, not just `%s`, so the fix belongs where every git call gets its config: the lib's `HARDEN` pairs. Considered and discarded: pinning per call site (`git -c ...` at each `%s` read), which restates the flag (S3) and misses the reads that print only dates.
**Project state:** before this branch only `scripts/lib/landings.sh`'s `gate_git` pinned the key (cite: f48a1c2b | scripts/lib/landings.sh:22).
**Task status:** done; review clean (docs/reviews/code-review-rubric-2026-11-20-digest-log-encoding.md).

## What exists

- `HARDEN` / `git_harden` (`scripts/lib/dev-cycle-read.sh`) exports config pairs through `GIT_CONFIG_COUNT`. Env pairs outrank repo-local config. `dev-cycle.sh`, `build-loop.sh`, `board.sh` and `d6.sh` call `git_harden`; `questions.sh` passes `HARDEN` as `-c` pairs.
- `landings.sh`'s `gate_git` was the only site pinning `i18n.logOutputEncoding=UTF-8` (review R1 of the out-of-loop-landings loop, FP-188).
- Probe (git 2.39 in the sandbox): with `i18n.logOutputEncoding=UTF-16`, `git log --format='%cs %H %s'` re-encodes the whole formatted line, BOM and NULs included, so `%cs`-only reads (the commit count, section 7's dates) are affected as well, not just subjects. The same pin through `GIT_CONFIG_COUNT` env pairs prints plain UTF-8.
- The message-text reads in the digest: `dev-cycle.sh` section 1 (`%cs %H %h %ad %s`), the commit count (`%cs`), the decision-record dates (`%cd`), section 7 (`@%cs`), the lib's `%H`/`%cs` reads, and `rubric-check.sh`'s `rev-list --format=%s` (through `gate_git`). `cat-file` reads print raw objects and are not re-encoded.

## Design choices

Three options: (A) add the pair to `HARDEN`, (B) a digest-only wrapper function used at each site, (C) `-c i18n.logOutputEncoding=UTF-8` at each site. A dominates (Path A, no divergent-design matrix needed): it is the one place every git call already passes through (S3), it covers the date-only reads that B and C would have to find one by one, and the brief names it as the preferred spot. B and C cost more edits and drift when a new read is added.

Keep or drop `landings.sh`'s per-call pin: dropped. `HARDEN` now covers it, `landings.sh` is sourced only by `dev-cycle.sh` after `git_harden`, and its existing UTF-16 bats case still passes (one source of truth, S3).

### Why the pin is safe for `--main-log` and the other gate modes that share `HARDEN`

- When neither `i18n.logOutputEncoding` nor `i18n.commitEncoding` is set, git's output encoding is already UTF-8. Pinning UTF-8 then changes no byte. That is true for `gate_repo` (a fresh repository with no such config) and for any repo that leaves the keys alone, which covers what `--main-log`, `--check` and `--status` read today.
- When a repo does set one of them, gate reads go from that encoding to UTF-8. The gate's grammars (`handoff:`, `Build-loop-gate:`, the strict-UTF-8 marker-body check) are ASCII or UTF-8, so this only makes them match what they were written to parse. Under UTF-16 they would have read NUL-padded text.
- A commit with an `encoding` header is re-encoded to UTF-8 under both the default and the pin, so nothing changes for it.
- The pair changes no object, ref or merge result: it only affects how messages are printed. `questions.sh`'s merge and `board.sh`'s reads (out of scope to edit) get the pin as a side effect. For them, too, it is a no-op unless the repo sets the key, and then a fix.
- H1: repo config stays input, not logic, because the env pair outranks it. H2: no new failure path is added; a read that fails still fails as before.

## Invariants

- `HARDEN` is read by two bats suites key by key (`build-loop-orchestrator.bats` "every git call dev-cycle.sh makes", `build-loop-check.bats` "every git call --check makes"), so the new key is now checked on every call. The exact-list test ("git_harden exports HARDEN's pairs") was updated (8 to 9 pairs).
- The caller's own pairs still apply after `HARDEN`'s (`git -c` ones). A caller can still choose another encoding on purpose.

## Prior art

`landings.sh`'s `gate_git` pin and its bats case "a repo-local log output encoding changes nothing in the section" (`test/scripts/dev-cycle-landings.bats`). The new case follows that shape for section 1.

## Gotchas

- Failure-pattern grep: FP-188
  - FP-188: hardened git log in a checkout still follows a repo-local `i18n.logOutputEncoding`; UTF-16 cut subjects and a stale rubric line vanished silently. This branch generalizes that fix from one section to every digest and gate read. FP-188's entry is a record and is not edited.
- Failure-pattern skip: this branch's fix(...) commit applies FP-188's own cause and fix (environment-divergence, align-config) to more call sites; it adds no new cause-and-fix shape.
- `rg -E` is rg's encoding flag, not alternation (seen during the grep).

## Tests

- New case in `test/scripts/dev-cycle.bats`: "a repo-local log output encoding changes nothing in the activity section". It builds a fixture with a merge subject `merge: café — ünïcode`, takes section 1 without the setting and again with `i18n.logOutputEncoding UTF-16`, and requires the two to be identical, with no "null byte" warning on stderr. On the old code it fails: the subject printed as `merge: caf�   �n�code` (checked before the fix).
- `scripts/confine-tests.sh --probe` exited 3: "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the touched suites ran through `scripts/run-tests.sh` instead: dev-cycle, dev-cycle-landings, build-loop-orchestrator and build-loop-check, 250 ok, exit 0. `scripts/hermeticity-lint --root .` passed (152 files), and `scripts/health-check.sh` printed "All checks passed." (rc 0) on this branch.

## Files read

Last verified: 2026-11-20
docs/working/briefs/2026-11-20-digest-log-encoding.md
docs/constraints.md
docs/failure-patterns.md
scripts/lib/landings.sh
scripts/lib/dev-cycle-read.sh
scripts/lib/rubric-check.sh
scripts/dev-cycle.sh
scripts/d6.sh
scripts/questions.sh
scripts/board.sh
hooks/live-verify-gate.sh
test/scripts/dev-cycle.bats
test/scripts/dev-cycle-landings.bats
test/scripts/build-loop-orchestrator.bats
test/scripts/build-loop-check.bats
workflows/research-plan-implement.md
workflows/pr-prep.md
