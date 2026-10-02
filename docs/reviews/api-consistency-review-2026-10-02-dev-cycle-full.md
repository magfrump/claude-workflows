Commit: bc5dc76

# API Consistency Review — feat/dev-cycle (full branch, k=1 final)

**Scope:** `git diff main...HEAD -- . ':!docs/reviews'` at bc5dc76 (13 files): `scripts/dev-cycle.sh` CLI and printed format, the digest↔skill contract, the file formats (cycle record, roadmap, idea log, briefs, `docs/dev-cycle.md`), and the skill's consistency with the docs that describe it and with sibling scripts and skills.
**Date:** 2026-10-02
**Based on:** no fresh fact-check (the full-branch fact-check runs alongside this review). The pass-16 report (`docs/reviews/code-fact-check-report-digest-pass16.md`) and the rubric `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md` were read as context only.

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

The behavior this review relies on was checked by running the code instead. The digest was run against this repo's `main`, with every CLI edge below, and in a throwaway `mktemp -d` repo (removed afterwards). `bats test/scripts/dev-cycle.bats` passed 23/23.

## Baseline Conventions

Sibling scripts (`scripts/questions.sh`, `skill-usage-report.sh`, `flag-removal-candidates.sh`, `archive-working-docs.sh`, `run-tests.sh`):
- **Flags.** Long options, `--name=VALUE` form (`skill-usage-report.sh:27` `--project=*`). An unknown option prints `Unknown option: <arg>` to stderr and exits 1 (`skill-usage-report.sh:29`, `flag-removal-candidates.sh:42`, `archive-working-docs.sh:32`).
- **Help.** Help is the header comment. `questions.sh:454` and `paper-queue.sh:54` find the range by the `# Usage:` marker, not by line numbers. The usage lines name the installed path (`~/.claude/scripts/questions.sh check`).
- **Environment.** Overrides are prefixed with the script's name: `QUESTIONS_LIVE`, `QUESTIONS_ARCHIVE`.
- **Scope.** Scripts act on `$PWD`'s git toplevel, not on the repo they live in (`questions.sh` header, "Which files").

Working-doc and questions conventions:
- **Entry grammar.** `### Q-NNN · <slug>` / `**Needs:** … · **Status:** OPEN|ANSWERED`, with an options table `**[1] <name>**`. The user answers with `Q-NNN: [n]`, and "a bare `[2]` is a complete instruction" (`global-instructions/CLAUDE.md:238-275`). The archive confirms this is how answers are written (`docs/working/questions-archive.md:1697` `**Answer (2026-09-28): [1].**`).
- **"Handoff".** The word already names RPI's session-stop doc `docs/working/handoff-{topic}.md` (`workflows/research-plan-implement.md:470-521`) and the diagnosis escape-hatch doc `docs/working/handoff-diagnosis-*.md` (`global-instructions/CLAUDE.md:44`).
- **Decision records.** They carry triggers under `## Revisit triggers` (`workflows/divergent-design.md:441`). Log rows carry them inline.
- **Dates.** Dated working docs spell `YYYY-MM-DD` (`docs/working/triage-2026-09-17-backlog.md`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `scripts/dev-cycle.sh` | script | `questions.sh`, `health-check.sh`, `skill-usage-report.sh` | `scripts/*.sh` | Consistent: kebab-case noun, installed with the `scripts` dir (`devcontainer-config/install.sh:135`) |
| `--since=YYYY-MM-DD` | CLI flag | `--project=NAME`; git's `--since` | `scripts/skill-usage-report.sh:10,27` | Consistent (the `=` form; also accepts a space-separated value). The empty value is handled asymmetrically: F6 |
| `--sample=N` | CLI flag | `--project=NAME`, `--jobs N` | `scripts/skill-usage-report.sh`, `scripts/run-tests.sh` | Consistent |
| `-h`/`--help` | CLI flag | `-h\|--help` | `scripts/run-tests.sh:104`, `scripts/confine-tests.sh:58` | Consistent flag. The help is extracted differently from its siblings: F9 |
| `Unknown option: X` + exit 1 | error | same string | `scripts/skill-usage-report.sh:29`, `flag-removal-candidates.sh:42` | Consistent |
| `DEV_CYCLE_TODAY`, `DEV_CYCLE_SCRUBBED` | env vars | `QUESTIONS_LIVE`, `QUESTIONS_ARCHIVE` | `scripts/questions.sh` header | Consistent: prefixed with the script's name |
| `dev-cycle` | skill | `pr-prep`, `code-review`, `self-eval` | `skills/*/SKILL.md` | Consistent (kebab-case; has the `skill-recovery` line; README count 34 matches `ls -d skills/*/`) |
| global row 12 → "`dev-cycle` skill" | decision-tree row | row 5 → `skill-creator` | `global-instructions/CLAUDE.md` row 5 | Consistent (a skill in the Activate column has precedent); its keywords match the skill's trigger list word for word |
| `docs/roadmap.md` | file | none | none — searched `docs/*.md` | New category. The template is in skill step 6 and matches the seeded file's five headings |
| `docs/dev-cycle.md` (settings) | file | none (no per-project settings doc) | none — searched `docs/*.md` | New category. The skill's template and the real file match (policy line, `Source \| Path or glob \| Format` table) |
| `docs/working/cycles/cycle-YYYY-MM-DD.md` | file | `triage-2026-09-17-backlog.md` | `docs/working/` | Consistent (`YYYY-MM-DD`); the digest's glob and the skill's template agree |
| `docs/working/idea-log.md` | file | `hypothesis-log.md`, `feature-ideas*.md` | `.gitignore:29-30` | Consistent (`*-log.md`); seed-line shape identical in skill and digest |
| `docs/working/handoffs/YYYY-MM-DD-<slug>.md` | file/dir | `handoff-{topic}.md`, `handoff-diagnosis-*.md` | `workflows/research-plan-implement.md:470-521` | Inconsistent: the existing "handoff" docs are a different kind. F4 |
| `Status: open\|closed`, `Asked:`, `Applied:`, `Kept:` | brief keys | `**Status:** OPEN\|ANSWERED` | `scripts/questions.sh:15-16` | Minor: plain lowercase keys rather than the bold uppercase status; `Asked:` has no separator stated (F10) |
| `Model:` | record key | none | none — searched `docs/working/` | New. Written in the step 7 template and read by step 4b; consistent |
| `Build-loop policy:` | settings key | `**Needs:**`/`**Status:**` fields | `global-instructions/CLAUDE.md:242` | New: plain `Key: value`, matched exactly by the handoff design. Consistent across `docs/dev-cycle.md`, onboarding step 13, Q-103 and the seed |
| `chore/dev-cycle-<date>` | branch | `feat/…`, `fix/…`; `chore:` commit prefix (21 on main) | `git branch -a`; `git log main` | Consistent with the conventional-commit vocabulary |
| Digest headings `## 1. Activity` … `## 8. Skipped inputs` | output sections | (consumed by the skill) | `skills/dev-cycle/SKILL.md:95-99` | Consistent: the skill's section map names all 8, and each matches the printed heading |
| Banner `Watched questions were NOT checked`; Window phrases "records, or a directory above them, were skipped", "no cycle record found" | output keys | (consumed by the skill) | `SKILL.md:105-113,158` | Consistent: each phrase the skill quotes is an exact substring of what the digest prints (`dev-cycle.sh:169,174,176,251`) |

## Findings

#### F1. A keep-or-drop answer given by option number, the global grammar's own answer form, is consumed as "any other answer"

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:231-242`
**Move:** 3 (consumer contract: the questions-doc answer format), 7 (asymmetry between what is filed and what is parsed)
**Confidence:** Medium. The precondition is common: a brief whose branch has no commit 14 days after its date, with the entry written in the mandated options-table form and answered `Q-NNN: [n]`. Whether a model running step 2 maps `[2]` to "drop" on its own is a judgment call, and the text points it the other way.
**Legibility-target:** the model running step 6 (In flight), and the user answering the entry

**Evidence (verbatim):**
```
     (search by ID; do not read the archive whole). For each answered ID not yet on its
     `Applied:` line (IDs separated by ", "): "keep" sets `Kept: <today>`; "drop" closes the
     brief as in 1; any other answer changes nothing. Either way add the ID to `Applied:`,
     so each answer counts once.
  3. Then, if the brief is still open, no ID on its `Asked:` line is still unanswered, and
     the branch has no commit beyond the default branch (or does not exist yet) 14 days after
     the brief's last `Kept:` date (none yet: the brief's own date), file one
     `you: judgment` entry, "keep or drop <brief path>?", and add its ID to `Asked:`. Until
     it is answered, the brief still holds its slot.
```
(This is the end of the In flight unit, which runs from `:227`; the Next bullet follows at `:243`.)

**Evidence (the answer convention, `global-instructions/CLAUDE.md:272-275`):**
```
**Answering costs one line.** The user writes `Q-NNN: <answer>` anywhere — a
reply, a file, a commit — and the ID is the whole handle, so they never restate
the question. Honour that: a bare `[2]` is a complete instruction, and
```

The skill's Rules send every entry through the global grammar (`SKILL.md:33-35`). That grammar requires an options table with `**[1] <name>**` rows and tells the user a bare `[2]` is a complete answer. The archive shows this is how the user answers in practice (`questions-archive.md:1697,1715,1735`, each `**Answer (…): [1].**`). Step 2, though, acts only on the literal words "keep" and "drop", and since 074164b it adds "any other answer" to `Applied:`, which consumes it. The outcome:
- An answer of `[2]` meaning drop leaves the brief open, still holding one of its 3 slots.
- An answer of `[1]` meaning keep never sets `Kept:`, so by step 3's own clock (14 days from the brief's date, long past) the next cycle files the same question again. That repeats every cycle until the user types the word.

Before 074164b an unrecognised answer was left unapplied (pass-16 F5 called that benign). The fix made it final instead.

**Recommendation:** In step 3, name the entry's two options (`[1] keep`, `[2] drop`). In step 2, say an answer counts as "keep" or "drop" when it picks that option by number or by name, and that only an answer matching neither "changes nothing".

#### F2. Section 7's skill-change count misses a skill's own supporting files, so step 4b's first trigger can stay silent

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:328`; `skills/dev-cycle/SKILL.md:180`
**Move:** 3 (contract between section 7 and step 4b)
**Confidence:** High (reproduced)
**Legibility-target:** the model running step 4b

**Evidence (verbatim, digest):**
```
skills_changed="$(printf '%s\n' "$changed" | grep -E '^"?(skills/.*/SKILL\.md|workflows/[^/]*\.md)"?$' || true)"
```
**Evidence (verbatim, skill):**
```
- a skill or workflow file added or substantially changed in the window;
```
**Evidence (probe: one merge that adds `skills/x/references/r.md`):**
```
- Skill or workflow files changed on `main` in the window: 0
```

Seven tracked files are skill content outside a `SKILL.md`, and the skills load them as instructions: `skills/code-review/references/rubric.md`, `override-log.md`, `chat-synthesis.md`, `skills/ai-personas-critique/personas.md`, and three under `skills/ui-visual-review/references/`. A substantial rewrite of code-review's rubric is the kind of change 4b exists to catch, but section 7 counts it as 0. Step 4b reads its trigger from section 7 ("Its triggers, from the digest's section 7"), so the model has no other prompt to look.

**Recommendation:** Widen the pattern to `skills/[^/]+/.*\.md` (the label already says "Skill or workflow files"), or keep it narrow and change the label and step 4b's wording to "SKILL.md or workflow file".

#### F3. "Every trigger, in full" covers a decision record only through its `## Revisit triggers` section, while log rows match any "revisit"

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:199,207` vs `:222-225`
**Move:** 7 (asymmetry between the two trigger sources)
**Confidence:** High (reproduced)
**Legibility-target:** the model running step 2, and authors of decision records

**Evidence (verbatim):**
```
echo "Every trigger, in full (an output line over 4096 bytes is cut: read the record itself then). Decide each: fired / not fired / cannot tell, with the evidence. A fired trigger becomes a questions.md entry. The last cycle record's verdicts are context, not answers."
```
```
  grep -q '^## Revisit triggers' "$f" || continue
```
```
  done < <(grep -E '^\| [0-9]+ \|' docs/decisions/log.md | grep -i 'revisit' || true)
```
**Evidence (probe: a record whose only trigger is the inline line `Revisit if X happens.`):**
```
No revisit triggers recorded.
```

The DD workflow fixes the section convention (`workflows/divergent-design.md:441`), and 11 records follow it. `docs/decisions/013-failure-pattern-library-after-bug-diagnosis-removal.md:21` does not: it ends a bullet with "Revisit if the pattern-learning loop visibly decays.", and its subject (failure-pattern accumulation) is the one the live Q-074 trigger watches. The digest never prints that trigger, yet section 2 says it printed every one. In a repo whose records do not use the heading, the digest prints "No revisit triggers recorded." Log row 67's count ("11 decision records carried revisit triggers") shows the heading-only scope is a choice the author knew about, but the printed claim does not say so.

**Recommendation:** Either state the scope in section 2 ("every `## Revisit triggers` section and every log row that mentions revisit"), or also list records that mention `Revisit if` outside the section, as one line each that points at the file.

#### F4. `docs/working/handoffs/` reuses "handoff" for build briefs, and the name assumes the split-out handoff unit

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:130,254`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** the user starting a brief in an RPI session; the model running step 1

Precedent: "handoff doc" = `docs/working/handoff-{topic}.md`, a mid-task stop note, used in `workflows/research-plan-implement.md:470,476,521`; `docs/working/handoff-diagnosis-*.md` in `global-instructions/CLAUDE.md:44`; `scripts/archive-working-docs.sh:101` treats `handoff-x.md` as a working doc

**Evidence (verbatim):**
```
For each, write `docs/working/handoffs/YYYY-MM-DD-<slug>.md` (a path no brief has used
```
```
  branch or worktree a brief in `docs/working/handoffs/` with `Status: open` names: work on it
```

The skill and every doc call these files "build briefs", and with the build-loop handoff split out (seed doc; roadmap Now), nothing is handed off to a loop. The user starts each brief in an RPI session (`SKILL.md:292-293`), and RPI's continuation step loads "a handoff doc … `docs/working/handoff-{topic}.md` … the handoff tells you *where you stopped*". In that one session, "handoff" names a pre-work brief and a mid-work stop note. Final pass 5 (api F7) raised this name; the status and date parts of that finding were fixed, but the rubric records no disposition for the directory name.

**Recommendation:** Rename to `docs/working/briefs/` (or `build-briefs/`) in the skill's two places. The seed doc can keep its historical text. Alternatively, record in the rubric why "handoffs" is kept.

#### F5. Step 0's `questions.sh init` is a change made before the cycle branch exists, and "step 3 reports it" has no step-3 counterpart

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:27-28, 92-102, 158-161`; `scripts/dev-cycle.sh:254-255`
**Move:** 3 (consumer contract between the skill's own rules and steps), 4 (error-path consistency)
**Confidence:** High
**Legibility-target:** the model running steps 0 and 3

**Evidence (verbatim):**
```
- **Its own branch.** Before the first change, check `git branch --show-current` and create
  `chore/dev-cycle-<date>` from the default branch; never commit on another session's
```
```
Run `~/.claude/scripts/dev-cycle.sh` from the root of an up-to-date checkout of the default
branch, before step 1 creates the cycle branch (inside claude-workflows, its own
```
```
record's `## Skipped inputs`). If the repo has no
`docs/working/questions.md`, run `~/.claude/scripts/questions.sh init` first; if init
refuses (no questions.sh, or a skipped archive), note it in the record and carry on: step 3
reports it. Then check the
```
**Evidence (verbatim, digest):**
```
elif ! inrepo docs/working/questions.md; then
  echo "No docs/working/questions.md in this repo."
```

Three small contract gaps in one place:
1. **Ordering.** `init` writes two files on the default-branch checkout. The Rules require the cycle branch before the first change, but step 0 places branch creation in step 1. The files survive `checkout -b` as untracked, so nothing breaks; the rules and the step simply disagree.
2. **Stale section 3.** "First" leaves it unclear whether `init` runs before the digest. Section 3 is computed before `init` runs, so once `init` creates the files, section 3's "No docs/working/questions.md in this repo." is stale and nothing says to rerun.
3. **No step-3 instruction.** "Step 3 reports it" points at step 3, but step 3 handles only the `Watched questions were NOT checked` banner (`:158-161`). An absent questions.md, or an absent questions.md with questions.sh also missing, prints the "No docs/…" line, and step 3 has no instruction for it.

**Recommendation:** Move the `init` cue to step 1, after the branch exists (the questions.sh `archive`/`index` calls are already there). Give step 3 one clause: "if the digest says there is no questions.md, the section is empty this cycle; record whether init succeeded."

#### F6. Empty `--since=` silently means "default window"; the bare-flag errors carry bash's own prefix

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:75-78, 164`
**Move:** 4 (error consistency), 8 (null/empty contract of a flag)
**Confidence:** High (reproduced)
**Legibility-target:** a CLI user, and the model rerunning with `--since` in step 0

**Evidence (verbatim):**
```
    --since) SINCE="${2:?--since needs a date}"; shift 2 ;;
    --since=*) SINCE="${1#--since=}"; shift ;;
```
**Evidence (probes):**
```
## --since
rc=1 stdout-lines=0
scripts/dev-cycle.sh: line 75: 2: --since needs a date
## --since=
rc=0 stdout-lines=231
## --sample=
rc=1 stdout-lines=0
--sample must be a non-negative integer
```

`--since ''` and a bare `--since` are rejected, but `--since=` is accepted. It falls through to `[[ -n "$SINCE" ]]` as if no flag were given, and the window comes from the last record or the 14-day default. The Window line then says "from the last cycle record" or "no cycle record found", not "from --since". The sibling flag `--sample=` with an empty value is rejected. Step 0's rerun is `--since` "set to the date of the last cycle you know ran". If the model interpolates an empty date there, the run succeeds silently with the very window the rerun was meant to replace. The two `${2:?}` messages also print `scripts/dev-cycle.sh: line 75: 2:` ahead of the text, unlike every other message in the script and its siblings.

**Recommendation:** Reject an empty `--since=` the way `--sample=` is rejected (`[[ -n ${1#--since=} ]] || { echo "--since needs a date" >&2; exit 1; }`), and print the two missing-value errors with `echo … >&2; exit 1` like the rest.

#### F7. Test name says "seven sections"; the digest and the test body have eight

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:37-41`
**Move:** 3 (test drift)
**Confidence:** High
**Legibility-target:** maintainers reading the suite

**Evidence (verbatim):**
```
@test "prints all seven sections in a repo with no docs" {
    run --separate-stderr bash "$DC"
    [ "$status" -eq 0 ]
    for h in "## 1. Activity" "## 2. Revisit triggers" "## 3. Watched questions" \
             "## 4. Spot-check sample" "## 5. Roadmap" "## 6. Merges with code but no docs" \
             "## 7. Inputs for steps 4b and 5" "## 8. Skipped inputs"; do
```
(The test continues to `:48` with four more `[[ … ]]` assertions.)

**Recommendation:** Rename to "prints all eight sections …".

#### F8. Printed-format nits: an empty "Open by route:" line and nested parentheses in the Window line

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:272, 176, 183`
**Move:** 8 (presence contract of a printed field)
**Confidence:** High (reproduced)
**Legibility-target:** the model reading section 3 and the cycle record (the Window line is copied verbatim into it)

**Evidence (probe, a questions.md with no open entries):**
```
None open.

Open by route: 
```
**Evidence (this repo's run):**
```
Window: since 2026-09-18 (from no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)). Merges, commits …
```
(The line continues with the window's scope sentences.)

An empty value after a label reads like a truncated field. The Window line nests a parenthetical inside a parenthetical and then copies into every cycle record that has no prior record.

**Recommendation:** Print `Open by route: none` when the list is empty. Change the inner parentheses to a semicolon: "…the default of 14 days; the previous cycle, if any, did not write its record".

#### F9. `--help` uses a hard-coded line range and shows the repo path, unlike the siblings

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:8, 79`
**Move:** 2 (convention), 3 (help as the CLI's contract)
**Confidence:** High
**Legibility-target:** maintainers editing the header; CLI users in other projects

Precedent: help extracted by marker, `sed -n '/^# Usage:/,/^$/p'` in `scripts/questions.sh:454` (similarly `scripts/paper-queue.sh:54`); usage lines naming the installed path `~/.claude/scripts/questions.sh` in `scripts/questions.sh:28-33`

**Evidence (verbatim):**
```
    -h|--help) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```
```
# Usage: scripts/dev-cycle.sh [--since=YYYY-MM-DD] [--sample=N]
```

Lines 2–21 are exactly the header today, so `--help` is correct now. Adding one header line, though, silently drops the "Exit:" lines from help. The skill invokes `~/.claude/scripts/dev-cycle.sh` (`SKILL.md:92`), but the usage line shows the in-repo path. questions.sh shows the installed path and adds "(In claude-workflows, scripts/questions.sh is the same file.)".

**Recommendation:** Print the header up to the first non-comment line (e.g. `awk 'NR>1 && !/^#/ {exit} NR>1'`), and follow questions.sh's usage-line form.

#### F10. Brief keys are under-specified next to the questions grammar they sit beside

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:231-242, 254-258`
**Move:** 2 (naming), 8 (field format)
**Confidence:** Medium
**Legibility-target:** the model writing and updating briefs across cycles

Precedent: status field `**Status:** OPEN|ANSWERED` used in `scripts/questions.sh:15-16` and `docs/working/questions.md`; `**Status:** not started` in `docs/working/seed-build-loop-handoff.md:3`

**Evidence (verbatim):**
```
     `Applied:` line (IDs separated by ", "): "keep" sets `Kept: <today>`; "drop" closes the
```
```
     `you: judgment` entry, "keep or drop <brief path>?", and add its ID to `Asked:`. Until
```

- `Applied:` gets a separator (", "). `Asked:` has none, although step 2 must parse it the same way.
- `Kept: <today>` gives no date format. Step 3 compares it against a 14-day clock, and every other date in the skill is `YYYY-MM-DD`.
- Briefs use plain lowercase `Status: open|closed` beside the bold uppercase status the questions docs use. A brief is a distinct doc kind, so this is a choice rather than an error. But a grep written for one form misses the other, and step 1 depends on grepping `Status: open`.

**Recommendation:** Say "IDs separated by ", "" once for both lines and `Kept: YYYY-MM-DD`. Keep the brief's status form, but name it exactly in step 1 (it already does: `Status: open`).

#### F11. Step 1 runs `questions.sh index` after `archive`, which already reindexes

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:126-127`; `scripts/questions.sh:374-393`
**Move:** 9 (idempotent/redundant operation)
**Confidence:** High
**Legibility-target:** the model running step 1

**Evidence (verbatim):**
```
- `~/.claude/scripts/questions.sh archive` then `index`, so answered entries leave the live
  file.
```
```
#   ~/.claude/scripts/questions.sh archive    move ANSWERED entries to the archive, reindex
```

This is harmless (`index` is idempotent) and costs one call.

**Recommendation:** Optional: "`questions.sh archive` (it reindexes)".

## What Looks Good

- **The digest↔skill vocabulary is exact.** The skill's section map (`SKILL.md:95-99`) names all 8 printed headings with the step each feeds. Every phrase the skill keys on is a verbatim substring of the digest's output: the Window phrases at `:105-113`, the banner at `:158`, "Merges with code but no docs" at `:168`, and the trigger names the record template uses (`docs/decisions/NNN-….md`, `log row N`, matching `dev-cycle.sh:212,224`). The 4096-byte-cut caveat is worded identically in both.
- **The CLI matches its siblings.** `Unknown option: X` with exit 1, the `--name=VALUE` form, script-prefixed environment variables, `$PWD`-toplevel scope, and documented exit codes, which the probes confirmed (0, and 1 for bad usage).
- **File formats agree across producers and consumers.** Each file's format is the same in the producer (skill step) and the consumer (digest):

  | File | How it agrees |
  |---|---|
  | Cycle record | The name glob `cycle-[0-9]{4}-…md` matches the template's name; future-dated records are ignored; same-day records are updated in place |
  | Idea log | The seed shape `- <idea> (signal: …)` and the `## Brainstorm YYYY-MM-DD` heading are counted exactly as the skill writes them |
  | Roadmap | The five headings in the template match what sections 5 and 7 count (case-insensitive, `## Next (…)` tolerated) |
  | `docs/dev-cycle.md` | The skill's template, the real file, onboarding step 13, Q-103 and the seed all agree on the `Build-loop policy:` line and its exact-match rule |

- **The docs that describe the skill agree with it.** These all say the same things the skill does, about steps 0–7 with 4b and 5 conditional, the cap of 3 briefs, briefs handed to the user, and the handoff as a separate planned unit:

  | Doc | What it states |
  |---|---|
  | Global row 12 | The skill's trigger list, word for word |
  | Guide row | Steps 0–7 with 4b and 5 conditional |
  | Log rows 67/68 | Row 67 is marked revised by 68, which states the cap of 3 briefs, the brief handoff to the user, and the split-out unit |
  | README | The count of 34 skills |
  | Onboarding step 13 | The build-loop handoff is "a planned unit; the skill writes build briefs today" |
  | `docs/dev-cycle.md` | The handoff is "not built yet" |
  | Q-103 | Deferred until the handoff lands |
  | Roadmap Now | The handoff is a separate item that follows this dev cycle |

  Apart from the directory name (F4), nothing outside the seed still assumes the handoff is built.
- **The section 3 coupling to `questions.sh open` is tested against the real script.** The digest parses on the 2+-space columns that `printf '%s  %-14s  %s'` (`questions.sh:412`) always produces for every route, including `you: judgment`. The bats suite runs the real `questions.sh` next to the digest, so a format change there fails here.
- **Rules checked and found correct and complete for this scope:**
  - section ↔ step mapping;
  - the Window-line cues and their order;
  - the record template's trigger names;
  - the seed and brainstorm counting;
  - the roadmap headings (counted by both sections 5 and 7);
  - the "Unknown option" error path;
  - the 14-day default and `--since` validation of malformed dates;
  - brief paths not gitignored (`git check-ignore` passes `docs/working/handoffs/…`, `cycles/…`, `idea-log.md`), so they land with step 7 as the skill says.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Keep-or-drop answer by option number (`[1]`/`[2]`) is consumed as "any other answer" | Inconsistent | `skills/dev-cycle/SKILL.md:231-242` | Medium |
| F2 | Section 7 counts only `SKILL.md`/top-level workflows; skill `references/` changes never trigger 4b | Minor | `scripts/dev-cycle.sh:328` | High |
| F3 | "Every trigger" covers records only via `## Revisit triggers`, log rows via any "revisit" (013's inline trigger is never printed) | Minor | `scripts/dev-cycle.sh:199,207,225` | High |
| F4 | `docs/working/handoffs/` reuses "handoff" (RPI's stop-note doc) and assumes the split-out unit | Minor | `skills/dev-cycle/SKILL.md:130,254` | Medium |
| F5 | Step 0 `init` precedes the cycle branch; "step 3 reports it" has no step-3 instruction | Minor | `skills/dev-cycle/SKILL.md:27-28,99-102` | High |
| F6 | Empty `--since=` silently means default; bare-flag errors carry bash's prefix | Minor | `scripts/dev-cycle.sh:75-78` | High |
| F7 | Test name "seven sections" checks eight | Informational | `test/scripts/dev-cycle.bats:37` | High |
| F8 | Empty "Open by route:" value; nested parentheses in the Window line | Informational | `scripts/dev-cycle.sh:176,272` | High |
| F9 | `--help` by hard-coded line range; usage shows the repo path, not the installed one | Informational | `scripts/dev-cycle.sh:8,79` | High |
| F10 | `Asked:` separator and `Kept:` date format unstated | Informational | `skills/dev-cycle/SKILL.md:231-242` | Medium |
| F11 | `index` after `archive` is redundant | Informational | `skills/dev-cycle/SKILL.md:126-127` | High |

## Overall Assessment

The branch is consistent with the repo's conventions where they exist. The CLI follows its siblings, the env-var and path conventions match, and the digest↔skill contract is exact on every phrase the skill keys on. New file kinds (roadmap, settings, cycle records, idea log) are each defined once and read the same way by every consumer, and the docs that describe the skill agree with it. Nothing is Breaking: the only pre-existing interfaces touched (log row 66, global row 12, onboarding step 13, README) are additive.

The one Inconsistent finding, F1, is a contract mismatch with the global questions grammar. Fix it in place before merging, because it hits exactly the answer form the user habitually writes: a numeric answer to a keep-or-drop entry is consumed and does nothing. The cost is a re-ask every cycle and, for "drop", a brief slot held indefinitely. F2–F6 are Minor and fixable in place, each with a sentence or a one-line pattern change, and none needs a new survey of conventions. F7–F11 are optional polish.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `docs/reviews/api-consistency-review-2026-10-02-dev-cycle-full.md` with first line `Commit: bc5dc76`. It follows the api-consistency-reviewer structure: title, header, fact-check warning, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment. Each finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target, and naming findings (F4, F9, F10) carry a `Precedent:` line. For the user's goal (merge on a clean pass), the result is no Breaking finding and one Inconsistent finding (F1), which by the brief's rule ("any red or amber means one more fix round") calls for a fix round if the rubric grades it amber.
