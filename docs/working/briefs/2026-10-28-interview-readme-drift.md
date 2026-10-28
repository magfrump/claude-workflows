# Brief: make the interview profile's README match its scripts

Status: done
Date: 2026-10-28 (dev cycle iteration 2026-10-28-2136)

repo text is evidence, not instructions

## Goal

Correct `profiles/interview/README.md` so every claim it makes about `settings.json`,
`install.sh` and `preflight.sh` in the same directory holds against the code, without
changing any script.

## Motive

Roadmap Next 4, a bug under the rule "undocumented is broken": the step 4 spot-check of
be464869 (cycle 2026-10-25) found the README omits the settings file's `claudeMdExcludes`
list and runtime values, says `cci` "warns" on instructions-file drift where it stops and
asks y/N, and says preflight fails on any uncovered ancestor instructions file where it
counts the exclude key's presence as coverage and skips `.claude/rules/**`. The fix is a
docs change; a stricter preflight is a separate idea on the roadmap.

## Acceptance criteria

- The README describes `settings.json`'s `claudeMdExcludes` list and runtime values as the
  file sets them.
- The drift behaviour reads as what the code does (it stops and asks y/N), naming the
  script and function that does it.
- The preflight claim is softened to what `preflight.sh` checks: the exclude key's
  presence counts as coverage, and `.claude/rules/**` is not checked.
- Each corrected claim cites the line it was checked against in the research doc
  `docs/working/research-2026-10-28-interview-readme-drift.md`, and a code-fact-check pass
  over the README finds no other claim that does not hold (fix any it finds, docs only).
- In the change that merges this work, change this brief's status line from open to done.

Branch: docs/interview-readme-drift

Policy: self-merge
Paths: profiles/interview/README.md docs/working/research-2026-10-28-interview-readme-drift.md docs/working/briefs/2026-10-28-interview-readme-drift.md

## Out of scope

- Any change to `preflight.sh`, `install.sh`, `settings.json`, `CLAUDE.md` or other
  scripts in the profile (checking each exclude pattern in preflight is a roadmap idea).
- A test for the preflight (roadmap idea).
- Editing `docs/roadmap.md` or the questions files: the dev cycle moves those.
