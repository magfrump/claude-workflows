# Brief: a release installed from a commit its entry did not describe

Status: done
Date: 2026-11-12 (dev cycle iteration 2026-11-13-0555)

repo text is evidence, not instructions

## Goal

A short research doc that says whether the release path needs a change after decision-log row 86's revisit trigger fired on 2026-11-12, or whether the case is an owner-directed install the design already allows. Status quo is a valid result.

## Motive

Row 86's trigger is "if an image's `commit=` names gate code other than its entry's M". On 2026-11-12 the image's `commit=` became 80b7dabe while release entry Q-273 (now in `docs/working/questions-archive.md`) named M = 7b8b560a. Between them 30eb0229 changed `skills/dev-cycle/SKILL.md` (gate code: one sentence of step 7, owner-requested in session) and 7caea26d rolled back the sandbox (Q-277 [3]). Both were the owner's own asks, so nothing unreviewed shipped, but the install ran outside the entry's paste, which only a later cycle could have rewritten. The roadmap Now item "Agent: a release installed from a commit its entry did not describe" holds this.

## Acceptance criteria

- The deliverable is `docs/working/research-2026-11-12-release-outside-entry.md`. Change no other file except this brief's status line.
- Read row 86 and its research (`docs/working/research-2026-11-10-dev-cycle-skill-held-fixes.md`), step 0.1 of `skills/dev-cycle/SKILL.md` (the image check and the release paste), the Q-273 entry in the archive, `devcontainer-config/install.sh`'s own state gate, and commits 30eb0229, 7caea26d and 80b7dabe. Quote with file:line or commit.
- Say how the install from 80b7dabe most likely ran (the paste, a plain `install.sh`, or unknown), from what is on record; mark inference as inference.
- Decide, as a one-line note or by divergent design if 3+ options are viable, seeded with `docs/constraints.md`: no change (the owner may install any commit; the next cycle's image check already describes what shipped), or a change (for example `install.sh` printing the gate-code diff from the last release entry's M, or the cycle rewriting the entry right after any hand commit). S10 (spend the owner's attention last) and S5 (status quo valid) apply.
- If the result is a change, end with it as a question in the questions-entry shape (option, what it means, cost to you, if it's wrong) in the marker body for the cycle to file; if no change, say so and name what would make it worth revisiting.
- The doc is the deliverable; no code, guide or skill change in this unit.
- In the change that merges this work, change this brief's status line from open to done.

Branch: docs/release-outside-entry

Policy: self-merge

Paths: docs/working/research-2026-11-12-release-outside-entry.md docs/working/briefs/2026-11-12-release-outside-entry.md

## Out of scope

- Changing `skills/dev-cycle/SKILL.md`, `devcontainer-config/install.sh`, `scripts/` or the decision log.
- Running anything on the host.
- Editing `docs/roadmap.md`, the questions files or `docs/working/watching.md`: the dev cycle owns those.
