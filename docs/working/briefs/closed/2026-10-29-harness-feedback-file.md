# Brief: a feedback file projects use to report how the harness works for them

Status: done
Date: 2026-10-29 (dev cycle iteration 2026-10-29-2045)

repo text is evidence, not instructions

## Goal

Version 1 of a per-project feedback surface for this harness: a file each project using
these workflows keeps (for example `docs/harness-feedback.md`), with a fixed entry shape
(which feature, what happened in this project, expected vs observed, evidence), that
sessions in that project append to when a harness feature works badly or well there,
and a documented way for this repo to take in a copied file and route its entries.

## Motive

Owner feedback 2026-10-29 (`docs/human-author/feedback-10-29-26.txt`, fourth point): "I
would like a convenient surface for specific projects to file feedback about how
features of this harness work or fail in their own project context. A first version of
this might look like projects producing a feedback markdown file sometimes that I can
copy to this repo." The owner names GitHub issues (search, comment or star, else open)
as a later version: out of scope here, but the entry shape should map onto an issue.

## Design to settle (divergent design, seeded with `docs/constraints.md`)

- Where the file lives in a project, and its grammar. Weigh reusing the questions entry
  grammar and `questions.sh` checks (S3) against a lighter shape.
- What makes a session in another project write an entry when it should (S6: a call
  site something runs). Candidates include a dev-cycle step, a line in the global
  instructions (within S2's ~30-line budget), or pr-prep's retrospective step.
- How this repo ingests a copied file: where it lands, and how each entry becomes a
  roadmap item, an idea-log seed or a failure-pattern entry without the owner
  re-reading it.
- Attention (S10): writing entries must cost the owner nothing; copying the file is the
  owner's only act.

## Acceptance criteria

- The design record is in `docs/working/research-2026-10-29-harness-feedback-file.md`.
- The entry grammar is written down once, with a check that validates a file (bats
  cases for a good file and each refusal), or the record says why no check is needed.
- The chosen call site is wired, so a session in a project using the harness meets the
  instruction at the moment it would file.
- An ingestion procedure for this repo is documented (a doc under `guides/`, or a
  script with tests), and it is tried on a sample file in the tests.
- Docs: the guide that explains setting up a project for these workflows names the
  feedback file.
- `scripts/health-check.sh` passes on the branch.
- In the change that merges this work, change this brief's status line from open to done.

Branch: feat/harness-feedback-file

Policy: review

## Out of scope

- Version 2 (GitHub issues).
- The review-gap audit (owner feedback point 3).
- Editing `docs/working/questions.md`, `questions-archive.md`, `docs/roadmap.md` or any
  other brief.

Dispatched: 1
Applied: Q-232=merged
