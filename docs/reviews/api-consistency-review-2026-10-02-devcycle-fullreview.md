Commit: 2fd9401

# API Consistency Review — feat/dev-cycle, k=1 full review (whole branch)

**Scope:** `git diff main...2fd9401 -- . ':!docs/reviews'` (13 files, +2,507/−2). Surfaces reviewed: `scripts/dev-cycle.sh` (digest, six `--check-*` modes, help, exit codes) against itself and against `scripts/questions.sh`, `scripts/health-check.sh` and `scripts/run-tests.sh`; `skills/dev-cycle/SKILL.md` against the script's output and the repo's other skills and workflows; `docs/dev-cycle.md`, `docs/roadmap.md`, the seed doc, decision log rows 67–69, README, global-instructions row 12, `guides/skill-creation.md` and onboarding step 13 against the skill; `--check-answer` against the real answer lines; the 2fd9401 merge (questions files, override log).
**Date:** 2026-10-02
**Based on:** loop pass 36's k=1 fact-check (`/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass36.md`); the rubric `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md` (passes 21–36) and `docs/reviews/override-log.md`, read so that fixed or accepted items are not re-filed.
**Acceptance bar applied:** the fence reader must give the CommonMark reading or refuse, except decision log 69's accepted class (inline constructs that span lines). Refusing a file CommonMark would read counts as a finding only if a real questions file is refused.

**Probes.** All probes are under `scratchpad/apifull/`. Each was one `set -eu` script that made its own `mktemp -d` directory there and checked `$PWD` before any clone, `git init`, commit or write. Every process ran under `timeout`. Neither worktree was written except for this report, and `/workspace`'s checkout was not touched.
- P2: a clone of the worktree at 2fd9401. It covers every usage error, the check modes with mixed flags, all six modes on real paths, and the digest with and without `--since`.
- P3: `--check-answer` on every heading in the merged questions files, plus `questions.sh check`, `questions.sh open` and the override-log table shape.
- P4: a synthetic repo that runs one brief's whole lifecycle: write, land, done, merge, `closed/`, and a keep-or-drop entry in step 6.3's shape, answered, archived and re-read.

P1 was a first run that stopped early under `set -e`. Nothing was left behind.

## Baseline Conventions

- **Sibling CLI shape.** Long options. `Unknown option: X` goes to stderr with exit 1 (`skill-usage-report.sh`, `flag-removal-candidates.sh`, and `questions.sh`'s usage-on-bad-command exit 1). `run-tests.sh` is the exception: exit 2 for value errors, 1 for an unknown flag (override log: "Usage errors exit 2 for `--jobs x` but 1 for an unknown flag", Won't-Fix). The usage text lives in the header comment, printed by `sed` (`run-tests.sh:152-154`, `questions.sh:453-455`). Environment knobs carry the script's name as a prefix (`HEALTH_CHECK_*`, `RUN_TESTS_*`, `QUESTIONS_*`).
- **Scope.** Installed scripts act on `$PWD`'s git toplevel and are invoked by their installed path, `~/.claude/scripts/<name>` (`questions.sh` header; `install.sh` stages the whole `scripts/` directory, `devcontainer-config/install.sh:135`).
- **Check-mode output (this script's own convention, set earlier on this branch).** Each argument gets one line. The verdict comes first: `ok <arg> [fields…]`, `absent <name>`, `<option> Q-NNN`, or `skip <arg>: <reason>`. A skip is an answer (exit 0). Only usage or environment failures exit 1.
- **Questions grammar.** Headings are `### Q-NNN · <slug>` with slug `[a-z0-9-]+`. The header line is `**Needs:** … · **Status:** OPEN|ANSWERED` (`questions.sh:250`, `:262-271`). Answers are recorded inline. Real recorded answers start with `**Answered <date>…` (53), `**Answer (<date>…)` (7) or a `- ` variant.
- **Instruction-file mirroring.** Decision-tree workflow targets are mirrored in AGENTS.md and GEMINI.md. Skill targets are not: row 5's `skill-creator` appears in neither file.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `scripts/dev-cycle.sh` | script | `questions.sh`, `health-check.sh`, `run-tests.sh` | `scripts/*.sh` | Consistent: kebab-case noun phrase |
| `--since`, `--since=` | flag | `git log --since`; `--project=NAME`, `--round=N` | `scripts/skill-usage-report.sh:27`, `flag-removal-candidates.sh:41` | Consistent. The `=` form is documented. The space form is an additive extra, accepted in the override log (2026-09-29, F7) |
| `--sample=N` | flag | `--jobs N`, `--round=N` | `scripts/run-tests.sh:141`, `flag-removal-candidates.sh:16` | Consistent |
| `--check-path`, `--check-write`, `--check-brief`, `--check-branch`, `--check-fix`, `--check-answer` | mode flags | `questions.sh check` (a subcommand) | `scripts/questions.sh:446-452` | New family. The internal `--check-<noun>` pattern is uniform, and the variadic tail is documented as `--check-x ARG...` |
| `ok` / `absent` / `skip <arg>: <reason>` / `<option> Q-NNN` | output verbs | (this script's own, set on the branch) | `scripts/dev-cycle.sh:22-65` | Consistent with each other and with the skill's wording ("prints a skip", "prints `absent`") |
| `keep` / `drop` / `done` / `open` / `unrecognized` | answer verdicts | the `[1] keep` / `[2] drop` / `[3] done` options in step 6.3's entry | `skills/dev-cycle/SKILL.md:303-306` | Consistent: P4 shows `[2]` → `drop`, `Q-001: [3]` → `done` |
| `DEV_CYCLE_TODAY`, `DEV_CYCLE_SCRUBBED` | env vars | `HEALTH_CHECK_SKILLS_DIR`, `RUN_TESTS_NOT_RUN_FILE`, `QUESTIONS_LIVE` | `scripts/health-check.sh:11-27`, `run-tests.sh:18-20`, `questions.sh:40` | Name consistent. Absence from help was filed earlier as Informational/optional, not re-filed |
| `docs/dev-cycle.md`, `docs/roadmap.md`, `docs/working/{idea-log.md,cycles/,briefs/,briefs/closed/}` | file paths | `docs/working/questions.md`, `docs/decisions/log.md` | `docs/working/`, `docs/` | Consistent: none is gitignored (`git check-ignore` on all six shapes) |
| `chore/dev-cycle-<date>` | branch name | `feat/…`, `fix/…`, `review/q086` | override log branch column | Consistent: conventional prefix |
| `keep-or-drop-<brief name>-<n>` | question slug | `default-test-parallelism`, `dev-cycle-build-loop-policy` | `docs/working/questions.md` | Consistent: P4's entry passes `questions.sh check` |
| `Status:` / `Asked:` / `Applied:` / `Kept:` | brief keys | `**Status:**` (questions), `**Status:** not started` (seed) | `docs/working/questions.md`, `docs/working/seed-build-loop-handoff.md:3` | Consistent. Briefs use a plain key on purpose, read only by `--check-brief` |
| In flight sub-items "check 1" / "step 3" | skill cross-reference | "check 1" | `skills/dev-cycle/SKILL.md:90`, `:270` | Inconsistent (F2) |
| row 12 `dev-cycle` skill | decision-tree target | row 5 `skill-creator` | `global-instructions/CLAUDE.md` row 5 | Consistent: a skill target, not mirrored in AGENTS.md/GEMINI.md, as with row 5 |

## Findings

#### F1. `--help` still says `--check-fix` accepts any tracked `.md` file under `docs/` outside the listed exclusions, but it refuses `docs/roadmap.md`

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:50-53` (help), against `scripts/dev-cycle.sh:411` (code) and `skills/dev-cycle/SKILL.md:71-75`
**Move:** 3 (documentation drift)
**Confidence:** High (P2 probe)
**Legibility-target:** an agent or user who reads `--help` to learn which in-cycle fixes are allowed.

**Evidence** (verbatim):
- Help: `--check-fix  "ok <path>" for a file an in-cycle fix may edit: a tracked .md file under docs/ (not working/, human-author/, reviews/, decisions/, dev-cycle.md, a dot-directory or an instruction file) or README.md; "skip <path>: <reason>" otherwise.`
- Code `:411`: `if writable "$a"; then echo "skip $a: one of the cycle's own files (use --check-write)"`. The function `check_fix()` continues to `:416`, which was read.
- Skill `:72-74`: `a tracked .md file under docs/ (not the cycle's own files, docs/working/, docs/human-author/, ...`
- P2: `skip docs/roadmap.md: one of the cycle's own files (use --check-write)`

`docs/roadmap.md` is a tracked `.md` under `docs/` and is not in any of the help's exclusions, so help promises `ok` and the script prints a skip. Pass 24 (api F6) recommended both a separate skip reason and "mention it in the help line". The reason and the skill were fixed, and the code comment `:397-398` says "outside the cycle's own files". Help is now the only surface that leaves the exclusion out. The impact is small because the skip line names the right mode, and the roadmap is written through `--check-write` anyway. It is still a wrong statement in the help contract, and the rest of the help is now exact.

**Recommendation:** In the help, add "the cycle's own files" to the exclusion list (`(not the cycle's own files, working/, …)`). The line count stays the same if it is rewrapped. Otherwise move the `sed -n '2,75p'` range with it.

#### F2. The skill calls In flight's numbered checks both "check N" and "step N", and "step 3" is also a top-level step

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:286`, `:295` (against `:90`, `:270` and the `### 3. Watched questions` heading at `:190`)
**Move:** 2 (naming against the grain, inside the skill)
**Confidence:** Medium (the meaning can be recovered from context, as shown below)
**Legibility-target:** the cycle agent working through step 6's In flight list, which has to know which step files the next keep-or-drop entry.

Precedent: "check N" for In flight's numbered sub-items used in `skills/dev-cycle/SKILL.md:90` ("In flight's check 1 then moves it") and `skills/dev-cycle/SKILL.md:270` ("so check 1 can close it")

**Evidence** (verbatim):
- `:286`: `` `Asked:` line (step 3 below writes them; no other question counts). Run ``
- `:295`: `keep-or-drop entry, which step 3 files; a second reply on this one is not read). Add the`
- `:90`: `` `ok` there (In flight's check 1 then moves it to Done or Ideas by the state ``

Everywhere else in the skill, "step N" means a top-level step: "step 3" is Watched questions (`:136`, `:190`), "step 4" the spot-check, and so on. That step also edits questions entries (it changes routes). At `:295`, "which step 3 files" can therefore be read as the Watched-questions step filing the next keep-or-drop entry, although In flight's third check does it. At `:286` the word "below" makes the meaning clear, but at `:295` nothing does. The skill names the same list items "check 1" in two other places. Nothing breaks: an agent that reads on reaches check 3, which says "file one `you: judgment` entry". The cost is one ambiguous cross-reference in the step that has the most state.

**Recommendation:** Change "step 3" to "check 3" at `:286` and `:295`, matching `:90` and `:270`.

#### F3. The seeded roadmap's first Now item has no motive or first step, and becomes stale as soon as this branch merges

**Severity:** Informational
**Location:** `docs/roadmap.md` (Now, first item), against `skills/dev-cycle/SKILL.md:268` and `:323-325`
**Move:** 3 (consumer contract: the seed against the format the skill reads)
**Confidence:** High
**Legibility-target:** the first cycle run, which takes the Now items "whose first step needs no open choice" for build briefs.

**Evidence** (verbatim):
- Roadmap: `- **This dev cycle** (`feat/dev-cycle`, log row 67). First run: after install, so the` / `router skills from log row 66 are live.`
- Skill `:268`: `- **Now**: work ready to start or in progress by hand, each with its motive and first step.`
- Skill `:323-324`: ``**Build briefs.** Take the Now items whose first step needs no open choice (no open `you: judgment` names them)``

Once 2fd9401 merges, the item describes finished work on a merged branch, and it has no "Motive:" or "First step:" like the other Now item. The roadmap's own header says the first run "should re-check every line against its evidence", and the override log has already accepted a looser seed (2026-09-29: "Seeded roadmap intro differs from the skill's template intro"). A careful first cycle would move this item to Done, not brief it. This is a note, not a request.

**Recommendation:** Optional: at merge, move the item to Done (naming the merge), or leave it for the first cycle as the header says.

## What Looks Good

The following rules were checked and are correct and complete for this review's scope:
- **CLI against siblings.** `Unknown option: --bogus`, `--since needs a value`, `--sample must be a non-negative integer`, `--check-path needs at least one argument` and `--since must be a real YYYY-MM-DD date` all exit 1 (P2), which matches the majority sibling convention. Help prints header lines 2–75, which is the whole header: line 75 is the last comment line, line 76 is blank, and the Exit text is included.
- **Exit contract.** A skip is an answer: all six modes exit 0 on mixed ok/skip/absent input (P2). The digest exits 0. The help's Exit line matches what the probes saw.
- **Every output shape the skill names matches the script byte for byte.** That covers `ok <path>`, `ok <path> new`, `ok <path> open|done|dropped <commit>`, `ok <name> <commit> <n> <date>`, `absent <name>`, `<option> Q-NNN`, the "Watched questions were NOT checked" marker and its four causes, both Window-line phrases step 0 keys on ("records, or a directory above them, were skipped", "a newer record … was skipped"), the section numbers and titles the skill maps to steps (1–8), "Merges with code but no docs", section 7's 4b/5 inputs, and the `## Brainstorm YYYY-MM-DD` and `- <idea> (signal: …)` shapes the digest counts.
- **Brief lifecycle, end to end (P4).** The run goes `new` → `ok … open <land merge>` → the branch shows `ok feat/add-foo <sha> 1 <date>` → after the done-merge, `ok … done <that merge>` → after `git mv`, the `closed/` path reads `done <move commit>` and the old path `new`. This is exactly as the Rules (`:80-84`) and In flight check 1 describe it, including "or a later move".
- **`--check-answer` against the real answer lines.** On the merged questions files (P3), all 103 headings were read with 0 skips: 26 keep, 19 drop, 3 done, 13 open, 42 unrecognized. The Q-090 and Q-102 entries from main read cleanly (`unrecognized` and `open`), and the counts differ from pass 36's /workspace run (23 keep, 12 open) only by the branch's own entries: Q-099, Q-100 and Q-101 read keep, and Q-103 reads open. A keep-or-drop entry in step 6.3's exact shape passes `questions.sh check` and reads `drop` both live and after `questions.sh archive` (P4), which confirms the skill's "once step 1 has archived an entry, `questions-archive.md`".
- **Decision log 67–69 against the skill and the code.** Row 68's step list, the conditional 4b and 5 triggers, the brief handoff and the policy placement all match the skill. Row 69's refusal list now matches help, FENCE_AWK's comment and the skill's brief clause on every item, including "behind any `>` and list markers" (pass-36 F2 is fixed at `:41`, `:63`). Row 67 is marked "Revised by #68".
- **Cross-file surfaces against the skill.** The README skill count is 34 (`ls -d skills/*/` gives 34). Global-instructions row 12's triggers equal the skill description's, and its step summary matches the Flow. The skill-creation guide's "steps 0–7, with step 4b added and steps 4b and 5 conditional" is right. Onboarding step 13, `docs/dev-cycle.md`, the seed doc and Q-103 agree on the policy values, what `self-merge` covers, "unset counts as `review`", and that only the not-yet-built handoff reads the policy. The settings template the onboarding step tells the user to copy exists in the skill's "Project settings".
- **The 2fd9401 merge.** `questions.sh check` passes ("structure valid, indexes current"), `questions.sh open` lists the 13 open entries including Q-102 and Q-103, and the override log keeps main's 14 `feat/run-tests-jobs` rows intact. The field-count anomalies (one 10-field and one 9-field row) also exist on main, from escaped pipes. `run-tests.sh --jobs` is present and unchanged.
- **The digest itself (P2).** It runs on a real clone, every section is present, section 8 reports nothing skipped, and the Window line names its source and branch.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--help` omits `--check-fix`'s exclusion of the cycle's own files, so it implies `docs/roadmap.md` is `ok` (the remainder of pass-24 api F6) | Minor | `scripts/dev-cycle.sh:50-53` | High |
| 2 | In flight's sub-items are called "check 1" in two places and "step 3" in two others, and "step 3" is also the Watched-questions step | Minor | `skills/dev-cycle/SKILL.md:286`, `:295` | Medium |
| 3 | The seeded roadmap's first Now item has no motive or first step and is stale once merged | Informational | `docs/roadmap.md` Now | High |

## Overall Assessment

The branch's public surface is consistent with the repo's conventions and with itself. The CLI follows the sibling scripts' error and exit conventions. Every output shape the skill relies on matches the script exactly, the brief lifecycle and the keep-or-drop round trip work end to end, and the merge from main left the questions files and the override log valid. Nothing is Breaking or Inconsistent, and nothing falls inside or outside decision log 69's accepted class. Two Minor wording issues remain. F1 is a help line that pass 24's fix did not reach. F2 is a cross-reference in the skill that uses "step 3" where the skill elsewhere says "check". Each is a one-phrase fix. F3 is a note about the hand-made seed. By the loop's rule, F1 and F2 are known issues, so this is not a clean pass until they are fixed or explicitly accepted.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-devcycle/docs/reviews/api-consistency-review-2026-10-02-devcycle-fullreview.md` and starts with `Commit: 2fd9401`. It follows the skill's structure: title and header (with Based on), Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table and Overall Assessment. Each finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target, and the naming finding (F2) carries its `Precedent:` line. For the user goal (merge once a full pass finds no known issue), this full pass leaves two Minor wording issues open (F1, F2) and one Informational note (F3). The branch should not merge as clean on this report alone.
