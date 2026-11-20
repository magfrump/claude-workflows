# Research: letting the dev cycle record harness feedback where no feedback file exists yet

- **Goal**: decide how a dev-cycle iteration in another project can create and append to that project's `docs/harness-feedback.md`, and draft the change.
- **Problem framing**: philosophy-research's harness feedback F-002 (`docs/working/feedback/philosophy-research.md`): an iteration found a harness failure, the project had no feedback file, the cycle could not create one, and the owner made it by hand. Considered and discarded as the frame: "the cycle cannot append to the feedback file". It can, once the file exists (see What exists, item 3); only creating it is blocked.
- **Project state**: research only; this doc is the whole output (brief `Paths: none`) · standalone · not blocked.
- **Task status**: complete. Pick (Path A): no code change; close the roadmap Now item, with the route below written into the close.

Brief: `docs/working/briefs/2026-11-19-harness-feedback-file-in-cycle.md` · Branch: `docs/harness-feedback-file-in-cycle` from 14d450d9 · Date: 2026-11-19

## What exists

All [observed] by reading the files at 14d450d9 unless tagged otherwise.

1. **The instruction.** `global-instructions/CLAUDE.md` "Harness feedback" (heading line 169, rule line 171): any session in a project other than claude-workflows appends one entry to that project's `docs/harness-feedback.md`, using `~/.claude/scripts/harness-feedback.py` (`init`, `next-id`, `check`). `guides/harness-feedback.md` holds the grammar; `init` writes the preamble (`# Harness feedback`, a grammar pointer, `Project: NAME`) only when the file is absent (`cmd_init`, `scripts/harness-feedback.py` lines 275-291).
2. **Why creation is blocked in a cycle.** `skills/dev-cycle/SKILL.md` lines 153-172 ("Paths from repo text go through the digest's check"): the cycle writes its own files freely; an in-cycle fix edits only a file `--check-fix` prints `ok` for, and "a new file ... is filed, not written". `check_fix` (`scripts/dev-cycle.sh` lines 183-196) ends in `check_path`, which prints `skip PATH: no tracked file ... matches` for an untracked path (lines 155-170). That is the only barrier: `--cycle-diff`'s `cycle_rules` (`scripts/build-loop.sh` lines 2324-2421) passes any `.md` under `docs/` that is not a truth or cycle file, new or edited, with no further check (a non-cycle path reaches the `case` arm `*) continue`, line 2363).
3. **Appending already works once the file exists.** `docs/harness-feedback.md` is not in `writable()` (the cycle's files, `scripts/lib/dev-cycle-read.sh` line 236) nor in `truthrule` (lines 983-993), and it matches `^docs/.*\.md$`, so `--check-fix` reaches `check_path` and prints `ok` for the tracked file [observed in code; inferred for a client repo, provided no instruction file there imports it with `@`]. philosophy-research's later entries F-015 and F-016 cite cycle iterations as their evidence, consistent with in-cycle appends [inferred; the commits are in that repo, not here].
4. **Append-only today.** Nothing in the cycle's gate keeps the file append-only: `--cycle-diff` lands any edit to it. The detector is downstream: `harness-feedback.py ingest` refuses a copy whose entries do not start with the stored copy's (same IDs, slugs and meta lines, in order; `sig()` and `cmd_ingest`, `scripts/harness-feedback.py` lines 294-342), per `guides/harness-feedback.md` "Ingesting a copy". Any other change to an old entry's body passes, rewritten Context or Observed text included; belegarth-herald relies on this (its F-001 carries a "Recheck 2026-11-12" line added after filing).
5. **A build loop can already create the file.** The self-merge floor (`floor()`, `scripts/lib/dev-cycle-read.sh` lines 1064-1081) refuses truth files, gate code, the cycle's own files, others' working docs and reviews, files an instruction file imports with `@` (or all paths when that walk fails), and paths below an instruction file's name; `docs/harness-feedback.md` is none of these [inferred for a client repo: the import walk is per repo], so a self-merge brief with `Paths: docs/harness-feedback.md` lands it without an owner review. belegarth-herald's file was likely made this way: its preamble names "the brief that asked for this file" [inferred].
6. **Gate code.** `GATE_CODE` (`scripts/lib/dev-cycle-read.sh` line 1037) is `scripts/(build-loop|d6|dev-cycle|questions).sh`, `scripts/lib/` and `skills/dev-cycle/`. A change to any of them is a review merge (a merge-gate entry the owner answers) and reaches client repos only at the next image release. The 2026-10-29 design (`docs/working/research-2026-10-29-harness-feedback-file.md` line 28) already named this limit when it picked pr-prep's retrospective and the global instruction, not a cycle step, as the call sites.

## Motive (S5: is the benefit real?)

- **Occurrences.** Two projects' feedback files have been copied here (`docs/working/feedback/`): philosophy-research (F-002, this case) and belegarth-herald (file made by a build loop's brief, no friction recorded). One occurrence in two projects, on 2026-10-29 [observed].
- **It cannot recur in a project.** The block applies only while the file is absent; after the first entry, item 3 holds. Both known projects now have the file. The harness ran in four real repos for the constraints-builder trials (`docs/working/constraints-builder-notes-2026-10-20.md`); whether the other two have a feedback file is not known from here [unverified]. So the remaining exposure is at most one event in each of about two projects, plus any new project.
- **Other writers.** Any session that is not a cycle (pr-prep's retrospective question 5, `workflows/pr-prep.md` line 491, or an ordinary session following the global instruction) can run `init` and create the file; so can a build loop (item 5). The gap is only a finding a cycle makes before any of these has created the file.
- **What it cost.** No finding was lost: F-002 records that it went to the project's roadmap Ideas and idea log, and the owner made the file by hand (one commit). The cost was one manual commit, once.

Conclusion: the benefit is real but small and self-limiting. The status quo is a live option, and any option that costs an owner review now has to beat "at most about two more one-time events".

## Divergent design

Constraints that bite: S5 (motive), S10 (owner attention last), S3 (reuse the reviewed mechanism), S2 (no mandatory dispatch per pass), H1/H2 (a gate change is reviewed and fails closed), S8 (`build-loop.sh` is 2619 lines). Every option here passes the hard lines H1-H4 if built carefully; the soft lines rank them.

| Option | Paths | Gate code? | How `--cycle-diff` keeps the file append-only | Cost now | Cost per event |
|---|---|---|---|---|---|
| **A. A cycle-own file** | `scripts/lib/dev-cycle-read.sh` (`writable`), `scripts/build-loop.sh` (an idea-log-style prefix rule), `skills/dev-cycle/SKILL.md`, bats cases | yes: review merge, image release | a `cmp -n` prefix rule, as for the idea log; a new file passes, its grammar left to `harness-feedback.py check` | one review merge, about 20-40 lines in gate code | none |
| **B. A `you: terminal` paste of `init`** | `skills/dev-cycle/SKILL.md` (one rule) | yes (the skill) | not at all, as today | one review merge | one owner paste per project |
| **C. No change** | none | no | not at all, as today; `ingest` detects only a changed ID, slug or meta line | none | the finding waits in the project's roadmap, or a build brief carries it (item 5) |
| **D. A `--check-fix` carve-out for creating this one file** | `scripts/dev-cycle.sh` (`check_fix`), `skills/dev-cycle/SKILL.md`, bats cases | yes: review merge | not at all, as today; `--cycle-diff` already lands the new file | one review merge, about 10 lines | none |
| **E. A one-line skill rule naming the build-brief route** | `skills/dev-cycle/SKILL.md` | yes (the skill) | not at all, as today | one review merge | one build loop per project |

Notes per option:

- **A is dominated.** Putting the file in `writable()` makes `truthrule` answer `cycle`, so `floor()` refuses it (item 5): every self-merge build loop in a client project, and pr-prep's retrospective run inside one, could then no longer land a feedback entry without an owner review. That is a regression for the main writers, bought to fix one event. Its prefix rule would also refuse the in-entry "Recheck" bullets belegarth-herald uses, which `ingest` accepts: stricter than the one reader needs.
- **B is dominated by E and C.** It costs the owner a paste per project (S10: no step that waits on the user when a fail-closed alternative exists), while E and C reach the same file with no owner act.
- **D is the full fix**, and it is small, but it adds a second creation path beside the build loop (S3), a special case in a gate whose rule is "a new file is filed" (H1 review merge, image release), all to remove at most about two more one-time events.
- **E's only gain over C** is that the orchestrator takes the build-brief route at once rather than parking the finding in Ideas; it still costs a review merge of gate code (the skill) now.
- **C** uses the route that already exists and is self-merge-clean: the cycle files the finding (record and project roadmap, as F-002's iteration did), and a brief whose `Paths:` is `docs/harness-feedback.md` lets a build loop run `init` and append it. Once the file exists the problem is gone in that project.

**Pick (Path A, one option dominates): C, no change.** On S5 and S10 it beats every option that needs an owner review now: the event is rare and cannot repeat in a project, nothing was lost the one time it happened, and the existing loop route needs no new mechanism. The tiebreak against E is cost now (a review merge) against a saving of one parked idea per project. If a third occurrence is reported, or a new project starts running the cycle often, E is the cheap next step: fold its one line into the next reviewed change to the "Paths from repo text" paragraph rather than give it its own review.

## Gotchas

- Failure-pattern grep: no matches found
  (`rg -in -e harness-feedback -e check-fix -e cycle-diff -e 'new file' -e append-only -e idea-log docs/failure-patterns.md`; the one hit was the file's own header, line 3.)
- `--cycle-diff` is wider than `--check-fix` (the skill says so, line 171): it lands a new `.md` under `docs/`. So D needs no `--cycle-diff` change, and the "new file" rule rests on the skill's prose and `--check-fix` alone.
- The client repos' commits cited by F-002 (`72e3e6ea`) are not in this repo; claims about them are read from the feedback entry.

## Review

pr-prep Step 0 (failure-pattern advisory): the grep above found no prior pattern for this area. Review-fix loop: one fact-check pass of this doc's claims against the code. It confirmed all five load-bearing claims (check-fix, cycle_rules, floor today, floor if cycle-own, ingest's prefix rule) and found four wrong line ranges, an overstated ingest claim and an incomplete floor list; all are fixed. No second round was run: each fix takes its wording or line number from the review's own report.

## For the dev cycle

Close the roadmap Now item "The cycle cannot create a project's harness-feedback file" with this reason: rare (one event in the two projects whose feedback is here) and one-time per project, since `--check-fix` already allows appending once the file exists; a self-merge build brief with `Paths: docs/harness-feedback.md` can create it today without an owner review (the floor does not cover that path). No brief suggested. Reopen as option E (one line in `skills/dev-cycle/SKILL.md` naming that route, folded into the next reviewed change to that paragraph) if a third project reports it.
