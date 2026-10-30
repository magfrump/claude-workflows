# Research: questions doc owner-only, unit 3 (the dev cycle and the global instructions read the new homes)

Brief: `docs/working/briefs/2026-10-29-questions-owner-only-unit3.md` (at 690f099d).
Branch: `feat/questions-owner-only-unit3`. Mode: build loop, no plan gate.
Design source: decision 040; unit 2's research
(`docs/working/research-2026-10-29-questions-watching-file.md`, "Left for later units").

Failure-pattern grep: `rg -i 'silent|hidden|drop|filter|status|watch|digest' docs/thoughts/failure-patterns.md`: FP-147 (an exit status lost through process substitution) and FP-058 (a failure silently drops the result) bear on it; both shaped review fixes below.
Failure-pattern skip: the two fix commits are instances of existing entries (round 1's sort read through `< <(...)` is FP-147; an allowlist filter that hid malformed watches is the fail-open class of FP-058), so they add no new FP entry, and `docs/thoughts/` is a record this loop may not edit.

## What exists

- `questions.sh open` listed only the live file. `dev-cycle.sh` section 3 filtered it for
  `trigger`/`deferred`, so watches moved by `migrate` would have left the digest.
- The skill filed `agent` entries at seven points: a stop's output (Rules), "Attention is
  the budget", step 0.4's skipped records, a failed digest, step 2's fired trigger, step 3's
  stale-agent pass, and step 10's dispatch refusals. Step 3 also told the cycle to "change the
  route" of a met watch, which `--cycle-diff` already refuses (a **Needs:** line changed
  without `--answered`), so the cycle could never close one: decision 040's motive.
- `--cycle-diff` treated `docs/working/watching.md` as any `.md` under `docs/` (free), but
  step 9.1 stages only what `--check-write` or `--check-fix` print `ok` for, and neither did
  (`--check-fix` refuses `docs/working/`). So the cycle could not land a close at all.
- `feat/convention-migrations-first` (Q-233) has not merged: no `scripts/lib/migrations.sh`
  or `guides/convention-changes.md` on main, so no registry line is needed.

## Divergent design (seeds: constraints H1-H4, S1-S3, S8, S10; decision 040; brief)

### D1. Home for agent work

1. **Roadmap Now items** marked `- **Agent: TITLE** (filed YYYY-MM-DD, step N).`
2. **A new roadmap section** (`## Agent work`).
3. **`agent` entries in `watching.md`.**
4. **Narrow exception**: keep `agent` in `questions.md` for stops only.
5. **Cycle record only.**

| # | Fails | Notes |
|---|---|---|
| 1 | — | decision 040's chosen home; Now already means "ready to start"; no gate change; the filed date keeps step 3's stale rule |
| 2 | brief (`--cycle-diff` freezes `## ` lines), S3 | needs a gate change and a template change in every repo |
| 3 | decision 040 | `check` refuses a non-watch route there |
| 4 | decision 040, H2 | `check` refuses `agent` in `questions.md` from 2026-10-30 |
| 5 | S6 | records are append-only per day; an item there is never revisited, and a stop lands no record |

**Pick: 1 (Path A).** A stop before step 9 still lands nothing, as before; its final message
carries it, unchanged by this unit.

### D2. How the digest reads watches

1. **`questions.sh open` adds `watching.md`'s OPEN entries**; the digest runs it twice
   (once with a non-existent watching path) to mark the live file's watches as legacy.
2. A new `questions.sh watching` mode.
3. `dev-cycle.sh` parses `watching.md` itself.
4. Point `QUESTIONS_LIVE` at `watching.md`.

| # | Fails | Notes |
|---|---|---|
| 1 | — | one grammar reader (S3); `open`'s only caller is the digest |
| 2 | S3 (weak) | another mode for one caller |
| 3 | S3 | a second parser of the entry grammar |
| 4 | H2 | `open` does not filter status, so closed watches would list; needs the archive too |

**Pick: 1.** `watching.md` is checked with the digest's `skipped` rule first (a symlink would
otherwise be read through), and a non-plain one stops the section, as a non-plain archive
does. All three paths are pinned on the call, and the D6 block also unsets
`QUESTIONS_WATCHING`. A missing `watching.md` is named in the section (H2: not silent).

### D3. What `--cycle-diff` allows in `watching.md`

1. Free, as now, plus making it a cycle file so it can be staged.
2. **Cycle file, free edits, but no watch dropped**: every `### Q-NNN` heading line on the
   base must be a line of the index's copy; deleting the file refuses.
3. The questions files' anti-forgery rule (heading, **Needs:** and answer lines frozen).

| # | Fails | Notes |
|---|---|---|
| 1 | — | an honest rewrite can drop a watch and its closure criterion silently |
| 2 | — | ~8 lines; holds decision 040's "closed watches kept in `## Closed`" |
| 3 | decision 040 | a close adds an answer line, so the cycle could not close its own watch |

**Pick: 2** (dominates 1 at small cost, H2/S1 honest slips). An owner entry moved from
`questions.md` into `watching.md` still refuses, as an entry gone from the questions files.

Making `watching.md` (and `migrate`'s `roadmap-from-questions.md`, which step 6 folds and
deletes) cycle files via the lib's `writable()` also puts them under the N rules, so a build
loop's merge is denied for them under either policy, matching D11 (the orchestrator is the
only writer).

### D4. Global instructions

Rewrite three existing lines in place (intro, "Route, don't rank", "Maintenance is
scripted"): four owner routes, `watching.md`, the roadmap, `migrate`. Net 0 lines (S2).

### D5. Convention registry after merging main (dispatch 2)

Main gained `scripts/lib/migrations.sh` (the convention registry). D1's one-line change to
the step 6 roadmap template preamble (it now names `watching.md`) changes the `roadmap`
fingerprint to 1178ca230944fb9f. Options: (a) a `none:` line, (b) a migration line with an
ERE on the old preamble and a remedy, (c) drop the template change. (b) has no remedy
command to name, and `--cycle-diff` freezes an existing roadmap's preamble, so an owner
edit is the only route, a new chore for no reader: nothing parses the preamble (rg finds
no reader). (c) leaves new repos' roadmaps not naming the watch file. (a) dominates:
`mig roadmap-watching-040 roadmap 1178ca230944fb9f - - 'none: ...'`. The `questions`
fingerprint already matches the registry's `questions-owner-routes-040` line.

The orchestrator's "questions: its source was not found" refusal comes from running
`check .` with a relative root: `conv_source` changes into a temp dir and then calls
`"$r/scripts/questions.sh"`, which no longer resolves. With an absolute root (as the bats
test and the health check pass it) the check is clean. That bug is in main's
`migrations.sh`, outside this brief; it is reported, not fixed here.

## Residual risks

- `questions.sh migrate` is still the owner's step; until it runs, legacy watches show in the
  digest marked "legacy", and the cycle records a met one rather than closing it.
- The watch rule compares heading lines, not fence-aware (as `questions.sh` reads them); a
  heading inside a fence counts too, which only adds refusals.
- Gate code changed (`build-loop.sh`, the lib, `dev-cycle.sh`, `questions.sh`, the skill):
  this lands as a `merge-gate` entry and runs from the next image release.

## Tests

- `test/questions-doc.bats`: `open` lists open watches, not closed; refuses a directory there.
- `test/scripts/dev-cycle.bats`: section 3 with no `watching.md`, with one (legacy marked,
  closed omitted, exported path ignored), and with a symlinked one (NOT checked, section 8);
  `--check-write` for both new cycle files.
- `test/scripts/build-loop-orchestrator.bats`: `--cycle-diff` passes a close and a new watch,
  refuses a dropped or renamed watch, a deleted file, and an owner entry moved into
  `watching.md`.
- `test/scripts/build-loop-check.bats` T14: both files denied to a build loop.

## Review rounds

- Round 1 (subagent): `open` showed only an exact `OPEN` watch, hiding a CR-ended or
  misspelt one (fixed: only an explicit ANSWERED is hidden); the watch rule's sort exit
  status was lost (fixed); comments overstated "never dropped" (reworded to the heading);
  bare `questions.md`/`watching.md` in the global instructions read as workflow refs to the
  health check (respelled). Not changed: `open` follows a link to a regular file, as for
  the live file; the digest refuses links first.
- Round 2: an empty or misspelt route dropped out of the digest's watch list (fixed: the
  route column is read by position and any route that is not an owner's or `agent` lists,
  marked malformed). Confirming review: clean.
- Not tested: the second `open` call failing alone (the first call's failure path is).

