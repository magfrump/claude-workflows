# Research: `--cycle-diff` refuses a cycle record that loses its earlier blocks

Brief: `docs/working/briefs/2026-11-20-cycle-diff-record-prefix.md` (at adf18cd0). Branch: `fix/cycle-diff-record-prefix`. Policy: review.

Reproduction: on adf18cd0, the new bats case `--cycle-diff and --land-cycle keep a cycle record's earlier blocks ...` in `test/scripts/build-loop-orchestrator.bats` fails at its 0121-shape step: `--cycle-diff` prints `ok` (exit 0) for a record rewritten to hold only a new block. With the fix it refuses.

## What exists

- `scripts/build-loop.sh` `cycle_rules` judges each changed path of the chore land (`--cycle-diff`: the index against the merge base; `--land-cycle`: the merge against main). Before this change a cycle record (`isrecord`, `scripts/lib/dev-cycle-read.sh:229`) fell to `*) continue`: no rule at all, so any rewrite, truncation or deletion passed. The brief says a deleted record "is already refused"; it was not on `--cycle-diff`'s path (only `--land-cycle` needs some record holding `Branch: B`, which a deletion of another record does not trip).
- The idea log's rule (`edited other than by appending`) is the pattern: base size `k`, then `cmp -s -n k` of base against index.
- `skills/dev-cycle/SKILL.md` step 9: each iteration appends its own block and never edits earlier ones; step 9's land commits the block with `9. land: this commit.` (and sometimes no `10.` line); step 10's land rewrites the last block's `9.` and `10.` lines (checked in history: 68aeffd2, 28b02351, 059d282d, 04daba4e, 48ecfa36 change only those lines; 68aeffd2 adds a `10.` line the step-9 land lacked). The "hash fix" commit 0661e54c edited a block's `7.` line, but on the chore branch before that block landed, so its base had no such block: still taken.
- Step 0.2 reads the record's last `Main at:` line as the next window's start, which is why losing blocks matters (the brief's motive).

## Rule implemented

A changed cycle record (BASE side present, not deleted):
1. BASE's bytes before its last `^## Iteration( |$)` line (all of BASE when it has none) start the listing's side byte for byte (`cmp -n`, as the idea log).
2. BASE's last block (from that line to EOF) and the listing's side from the same byte up to its next `## Iteration` line must match line for line, leaving out lines starting `9. land:` or `10. dispatch:` and trailing blank lines (the blank line an append puts before its new heading), except that the side may add lines inside the block's `### Paths landed` section (between that heading and the next `### ` line): skill step 9.1 says "step 10's land lists its own", and step 10 lands "as step 9 does (1 to 4)". Every base line must still appear, in order. What follows the next heading is appended and free.
3. Deleted: `refuse PATH: it is deleted` (same branch as the roadmap, idea log and watching file). New (no BASE): not judged.

Refusals: `refuse PATH: the base's text before its last ## Iteration block changed (an earlier block dropped or edited); an iteration only appends its own block` and `refuse PATH: the base's last block (## Iteration HHMM) changed other than its 9. land: and 10. dispatch: lines and lines added under its ### Paths landed; an iteration only appends its own block`. A failed read prints `refuse PATH: it could not be compared` (H2); a side not a regular 100644 file refuses as for the other cycle files.

## Design choices (none with 3+ viable options; one-line notes)

- Where: a branch in `cycle_rules`' existing per-file chain plus a `record_kept` helper and `RECORD_AWK` beside `ROADMAP_AWK`; reuses the idea log's byte-prefix compare (S3). One code path serves `--cycle-diff` and `--land-cycle`.
- Free lines matched by their template prefixes `9. land:` / `10. dispatch:` (the skill's record template), filtered out of both sides rather than position-matched, so step 10 may add a missing `10.` line (68aeffd2's shape). Residual: those two lines may move within the last block, or be dropped from it; accepted (S1: an honest slip that moves them loses nothing step 0.2 reads).
- Paths landed additions: found by review round 1 (the brief's rule, "kept except its `9.` and `10.` lines", would refuse step 10's land as the skill describes it; 17 lands on main from 2026-11-13 to 11-18 added such a line). Allowed rather than changing the skill (the records' shape is out of scope).
- Line-oriented, not fence-aware, like the watching file's heading rule and step 0.2's `Main at:` reader: a record holds no fences.
- Trailing blank lines of the last block ignored on both sides: an append writes a blank line before its heading.

## History replay and residuals

Replaying the rule over every cycle-record land on main (279 judgements, each merge as `--cycle-diff` and as `--land-cycle` would see it) refuses 10 on the `--cycle-diff` side, none since 2026-11-19 but the two the rule exists for:
- 18a43829 (iteration 0121, the motive) and b991011f (iteration 0128's restore of the dropped blocks, which changes the base's prefix back) and 60f670b0 (2026-10-30: a line inserted into an earlier block): earlier text changed.
- ceab0beb (2026-11-19: a later commit corrected the already-landed 2109 block's `Main at:` and `0.` lines): the brief refuses this on purpose.
- 6d41b0bd, 91e05ba7, c3a26cb1, 2e8efc65, fe57e352, 29d5fa88 (2026-10-16 to 11-14): older step-10 lands that added a `### Paths landed` heading the step-9 block lacked, or rewrote other lines of the last block. Today's template always carries the heading.

Residuals, all failing closed or accepted under S1 (honest slips by a same-uid loop):
- A fix to an already-landed block, or a restore of dropped blocks (b991011f's shape), cannot go through `--land-cycle`: it lands by hand (header says so).
- A `## Iteration` line inserted inside the last block ends the side's block there. Base lines after it then go unmatched and refuse (fails closed), except its `9.`/`10.` lines and trailing blank lines, which may be dropped (or moved within the block). Losing them takes nothing step 0.2 reads (the last `Main at:` stays in the block's checked head).
- Another session landing a block between this iteration's step 9 and step 10 makes step 10's rewrite fall in the base's prefix: refused (fails closed); `--state`'s one-cycle-at-a-time lock should rule it out.

## Doc changes (acceptance criterion 4)

- `scripts/build-loop.sh` header, `--cycle-diff` rule list: the cycle-record sentence after the watching file's rule.
- `skills/dev-cycle/SKILL.md` step 9, the list of what `--cycle-diff` refuses: "a cycle record whose text before its last `## Iteration` block changed, whose last block changed but for its `9.` and `10.` lines and lines added under its `### Paths landed`, or that is deleted".

## Tests

`test/scripts/build-loop-orchestrator.bats`, one case: appended block (ok); step 10's rewrite of the last block's `9.` line and an added `10.` line, alone and with a block appended (ok); the 0121 shape (refused); an earlier block's `Main at:` or its `9.` line edited (refused); the last block's `Main at:` edited, alone and with a block appended, or it cut short (refused); a line added under the last block's `### Paths landed`, alone and with a block appended (ok); a line inserted mid-section, before the next `### Roadmap diff` heading (ok); a Paths landed line dropped, or a line added elsewhere in the last block, under `### Steps` or after `### Roadmap diff` (refused); a line added to an earlier block (refused); deletion (refused); a new record (ok); `--land-cycle` refusing the 0121 shape on the merge and landing an append.

Failure-pattern grep: `grep -inE 'cycle-diff|cycle.record|truncat|append-only|appending|land-cycle|idea-log' docs/failure-patterns.md` → 3 lines: line 3 (the file's own preamble), FP-124 and FP-170 (truncation of a background-wait cell and of a multibyte char; unrelated). No prior failure in this area.

Failure-pattern skip: the one fix(...) commit adds a missing gate rule (a cycle record had no `--cycle-diff` rule at all), not a root-caused bug with a reusable cause-and-fix shape beyond "the rule was absent".
