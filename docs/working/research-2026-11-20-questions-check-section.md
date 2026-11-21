# Research: `questions.sh check` flags an entry outside `## Open`; `migrate` drops a heading it empties

Brief: `docs/working/briefs/2026-11-20-questions-check-section.md` (at 063a07d94).
Branch: `fix/questions-check-section`. Workflow: research-plan-implement (no plan gate), then pr-prep's review-fix loop.

## What exists

- `scripts/questions.sh` `entry_sections` printed `ID<TAB>0|1` (under `## Closed` or not) and was used only for `watching.md`. It was not fence-aware, and neither are `parse_entries`, `extract_entry` or `live_without_entry`.
- `cmd_check` validated each entry's grammar, route and status, and the route rule already splits on `LEGACY_BEFORE` (2026-10-30): ⚠ before, ✗ on or after.
- `cmd_migrate` moved non-owner entries out and never touched `##` headings.
- The one fence model in the repo is `FENCE_AWK` in `scripts/lib/dev-cycle-read.sh`. `--check-answer` already applies it to `questions.md`, and `questions.sh counts` already sources the lib (for `ANSWER_AWK`). This repo's three questions files pass `FENCE_AWK` with no refused line and no open fence.
- No guide describes `check`'s rules one by one. `global-instructions/CLAUDE.md` says only "`check` validates", so the doc change is the usage text in `scripts/questions.sh`.
- The migration fingerprint for the `questions` convention covers the "Entry grammar" header block and the files `init` writes (`scripts/lib/migrations.sh`). Neither changes here, so no `mig` line is needed (`bash scripts/lib/migrations.sh check` passes).
- `--cycle-diff --migrated` (build-loop.sh `QKEYS_AWK`) keys on entry lines only. A `##` line resets the entry and is not compared, so a heading that `migrate` drops does not trip the cycle's diff rules.

## Design (choices, one line each unless 3+ options)

- **Fence reader.** Reuse the lib's `FENCE_AWK`, sourced through a `need_lib` helper (S3: one fence model; the brief says "fence-aware, as the existing readers are"). Without the lib, `check` and `migrate` stop and name the missing file (H2). Writing a second fence tracker would break S3, and leaving fences out would fail the brief. Path A.
- **One section reader.** `entry_sections` now prints `ID<TAB>h<TAB>heading` (or `ID<TAB>u<TAB>why`). Both the watching `## Closed` rule and the new live `## Open` rule read it (S3).
- **Entries the reader cannot place** sit after a line `FENCE_AWK` refuses (CR, NUL, BOM, an indented or list fence, an unclosed `<!--`) or inside a fence that never closes. Each one is named, with the same `LEGACY_BEFORE` split: ✗ for a new entry, ⚠ for an old one. This fails closed for new entries without turning every older clone red (FP-113). Refusing the whole file would hit old clones; skipping it silently would break H2.
- **A fenced `### Q-` line** is text, so it is not placed or judged, in either file. The brief requires this for the live file; using the same reader makes it true in `watching.md` too.
- **`## Index`.** An entry under `## Index` is reported like any other heading. I read the brief's "(and other than the `## Index` block)" as saying that the index table's rows are not entries. Exempting the heading would hide a real misfiling. Low stakes either way, since `init` puts nothing between the index markers and `## Open`.
- **An entry above every `##` heading** is reported too ("sits above every ## heading").
- **A non-owner route in `questions.md`** gets only the existing route error, not the section error as well. Its remedy, `migrate`, moves it out of the file entirely, so "move it under ## Open" would be the wrong advice.
- **Which headings `migrate` drops.** Three options: (a) only headings this run emptied; (b) any `##` heading other than Index and Open whose section holds only blank lines; (c) any heading with no entry under it, dropping only the heading line. Option (b) dominates (Path A). It loses nothing, because only a heading line and blank lines are removed. It is safe to resume: a run interrupted after its last move still drops the heading on the re-run, which (a) misses. It never re-attaches prose to the section above, which (c) does. Headings are read outside fences. A refused line and everything after it count as content, so a file the reader cannot read loses no heading.
- **What (b) leaves.** A heading with an owner entry still under it is kept, and `check` keeps naming that entry. Moving entries under `## Open` would be a grammar or filing change: option (c) of the triage, out of scope.

## Residual risk

- A project whose `questions.md` has an indented fence (for example inside a list bullet) has every entry after that line reported as unplaced: ✗ for entries opened on or after 2026-10-30. `--check-answer` already skips such a file whole, so its answers are already unreadable to the cycle. The new message names the line and why, which is the fix-forward path. That project's `check` goes red at install, but only for entries opened since the cutoff.
- The entry spans that `archive` and `migrate` move (`extract_entry`, `live_without_entry`) are still not fence-aware. A fenced `## ` line ends an entry's span. This predates the change and is unchanged; the bats fixture keeps clear of it.

## Gotchas

- Failure-pattern grep: FP-113, FP-152, FP-184
  - FP-113 (a new gate that every existing clone fails): avoided with the `LEGACY_BEFORE` split, also for unplaced entries.
  - FP-152 (a sed range that runs past its heading, so an assertion goes vacuous): the new tests assert the full `## ` heading list and pair every green case with the same text unfenced or un-cut, which must fail.
  - FP-184 (a missing input read as "nothing open"): a missing lib stops `check` and `migrate` and names the path. A file the reader cannot read names each entry it could not place.

## Verification

- `bats test/questions-doc.bats` (50 cases, 8 new) and `bats test/scripts/questions-counts.bats` pass.
- Mutations: making `fence()` a no-op fails 3 of the new cases, dropping the ✗ rc fails the cutoff case, and disabling heading removal fails the migrate case.
- `scripts/hermeticity-lint --root .` passes. `scripts/confine-tests.sh --probe` exited 3, with first line: "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the runner plus the lint stand in for confinement.
- `bash scripts/questions.sh check` on this repo passes, and `bash scripts/lib/migrations.sh check` passes.
- `scripts/health-check.sh`: see the commit that records it.
