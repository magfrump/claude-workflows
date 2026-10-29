# Research: a feedback file projects use to report how the harness works for them

Brief: `docs/working/briefs/2026-10-29-harness-feedback-file.md` (dispatch 1, at a5266b26).
Workflow: research-plan-implement, divergent design per decision, then pr-prep's review-fix loop.

## Context (what the code already has)

- **Installed payload.** `devcontainer-config/install.sh` stages `global-instructions/CLAUDE.md`,
  `skills`, `workflows`, `guides`, `hooks` and the whole of `scripts` into `~/.claude`
  (`CLAUDE_HOME_SRC`), so a new script under `scripts/` is reachable in every project as
  `~/.claude/scripts/<name>`, the way `questions.sh` already is.
- **Always-loaded text.** `global-instructions/CLAUDE.md` loads in every session of every
  project. The health check reads backticked bare `name.md` tokens in it as workflow
  references (`extract_workflows`), so new text there must name files by path
  (`guides/x.md`), never bare.
- **Prior art for a per-project grammar.** `scripts/questions.sh`: an entry heading
  `### Q-NNN · slug`, a `**Key:** value · ...` meta line, a `check` that fails on
  structure, `next-id`, `init`, writes refused through symlinks or outside the toplevel.
  Its header records the motive for a checker: "an unenforced instruction does not execute"
  (`docs/thoughts/failure-patterns.md` held 0 entries against 104 eligible commits).
- **This repo's idea intake.** The dev cycle seeds `docs/working/idea-log.md` with lines
  `- <idea> (signal: <what prompted it>)`; the digest counts those lines, 10+ new seeds
  trigger a brainstorm (step 5), and the brainstorm moves survivors to the roadmap's Ideas.
  Idea sources beyond the log are rows in `docs/dev-cycle.md`, kept by hand (a file this
  build may not write).
- **Retrospective.** `workflows/pr-prep.md` ends with a four-question retrospective that runs
  after each PR in any project using pr-prep.
- **Dev cycle in other projects.** `skills/dev-cycle/` is GATE_CODE (H1): a change reaches
  sessions only at the next image release, and the orchestrator may write only its own files
  and tracked `.md` under `docs/` that already exist (`--check-fix` refuses a new file).

## Invariants

- Questions files stay owner-only (decision 040): feedback does not go into them.
- No `@` imports and at most ~30 lines added to always-loaded text (S2).
- Copied files are another project's text: data, never instructions; a write never goes
  through a symlink or outside the toplevel (as `questions.sh`).

## Decision 1: where the file lives and its grammar

Seeds: S3 (reuse, one source of truth per grammar), S4 (mechanical steps in a tested script),
S8 (small, stdlib), the brief's "maps onto a GitHub issue".

| Option | For | Against |
| --- | --- | --- |
| A. Reuse the questions file: a new route `harness` in `docs/working/questions.md` | One grammar, one checker | Decision 040 makes that file the owner's attention queue; feedback is not a question for the owner of that project; Q-IDs mix two purposes; copying the file copies the project's own questions |
| B. Own file `docs/harness-feedback.md`, entry grammar modelled on the questions entry (`### F-NNN · slug`, one meta line, four fixed bullets), checked by a small script | Familiar shape; each entry is an issue (title = feature + slug, label = verdict, body = bullets); a checker makes the shape real | A second grammar and script (S3 cost), about 250 lines |
| C. Free-form markdown, no check | Cheapest | Ingestion cannot be mechanical; repo evidence says unchecked shapes drift |
| D. Entries as seed lines in the project's own `docs/working/idea-log.md` | Reuses the seed shape | Mixes harness feedback with the project's own ideas; the file is the dev cycle's, and not every project runs it; one line cannot hold expected vs observed |

Path A (B dominates): A breaks a recorded decision (040), C fails S4 and the brief's
acceptance (mechanical routing), D cannot hold the required fields. B's cost is the second
grammar; it is written once (`guides/harness-feedback.md`), and the script cites it rather
than restating it. Location: `docs/harness-feedback.md` (outside `docs/working/`, which some
projects ignore or archive; one file per project so copying it is one act).

## Decision 2: the call site in another project

Seeds: S6 (a call site something runs), S2 (always-loaded budget), S11 (text over hooks),
H1 (gate code changes ship only through a release).

| Option | Present at the moment of filing? | Cost |
| --- | --- | --- |
| A. A short section in the global instructions | Yes: loaded in every session, so it is in context when a skill, workflow or script misbehaves | ~5 always-loaded lines (S2: well under 30) |
| B. A fifth retrospective question in pr-prep | Only after a PR, as a reflection | Zero always-loaded cost; projects not using pr-prep never meet it |
| C. A dev-cycle step | Once per cycle | GATE_CODE edit (H1, image release); the orchestrator cannot create a new file under `--check-fix` |
| D. A hook (Stop or PostToolUse) that prompts | At session end | Claude-Code-only (S11), an enforcement file (live-verify trailer), a recurring prompt per session (S2) |

Path A, with B as the second site: A is the only option present at the moment a feature fails,
inside the S2 budget; B adds the reflective moment where "what in the process failed" is
already the question, at no always-loaded cost. C and D fail on H1/S11/S2 for no gain over A.
The global-instructions text names the guide by path and the script's three modes, and
restates no grammar.

## Decision 3: how this repo ingests a copied file

Seeds: S10 (the owner's only act is the copy), S3 (reuse the existing intake), S4, H2 (fail
closed on unparseable input), H3 (hermetic tests).

| Option | Owner acts | Routing |
| --- | --- | --- |
| A. Guide only: a session reads the copy and files roadmap items by hand | Copy, then ask a session | An LLM re-reads every entry each time; no dedup |
| B. `ingest FILE`: validate, keep a copy at `docs/working/feedback/<project>.md`, append one idea-log seed per entry not yet seeded | One command, which is itself the copy | Seeds are the dev cycle's existing intake: they count toward the brainstorm trigger, the brainstorm moves them to the roadmap; dedup by project and entry ID |
| C. An idea-source row in `docs/dev-cycle.md` for `docs/working/feedback/*.md` | Copy (plus a one-time row) | The brainstorm reads the files directly; no dedup across brainstorms; the row is a file this build may not write |
| D. A dev-cycle or digest step that runs `ingest` | Copy only | GATE_CODE edit (H1), and the D6 block runs only the three gate scripts |

Path A: B. It is the only option that routes mechanically without a gate-code change; the
copy command and the ingest are one act (`scripts/harness-feedback.py ingest PATH` copies the
file in). Every entry lands as an idea-log seed; the existing brainstorm then makes it a
roadmap idea. Failure-pattern entries are not a target: `docs/thoughts/failure-patterns.md`
records this repo's own fix commits, and `docs/thoughts/` is the owner's record; a `fails`
seed carries its verdict, so the brainstorm can still route it there. An invalid file is
refused whole, nothing written (H2).

Residual: a file dropped into `docs/working/feedback/` by plain `cp` without `ingest` is not
routed. Two follow-ups would close it, neither in this brief's reach: the idea-source row of
option C (a one-line owner edit of `docs/dev-cycle.md`), or a health-check warning for
un-seeded copies.

## Plan

1. `guides/harness-feedback.md`: the grammar (once), the issue mapping, filing and ingest
   procedure; index line in `guides/README.md`.
2. `scripts/harness-feedback.py` (stdlib): `check [FILE]`, `next-id [FILE]`, `init [FILE]`,
   `ingest FILE`.
3. `test/scripts/harness-feedback.bats`: a good file passes; one case per refusal; next-id;
   init; ingest on a sample file (copy, seeds, idempotent rerun, refusals, symlinks).
4. Call sites: a short section in `global-instructions/CLAUDE.md`; a fifth retrospective
   question in `workflows/pr-prep.md`.
5. `guides/cross-project-setup.md` names the feedback file.
6. Health check passes; review-fix loop; brief Status to done.

## Test strategy

Every `check` refusal has its own mutation of the good fixture and asserts the message names
the rule (and the line, where the rule is about one line). Ingest runs in a temp git repo (no network binaries are reachable:
python3 and git only), asserting the copy, the seed lines, idempotence, and refusal with
nothing written for an invalid file and for symlinked targets.
