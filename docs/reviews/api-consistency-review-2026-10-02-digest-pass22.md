Commit: bc98571 (A) / 6c8ae91 (B)

# API Consistency Review: dev-cycle pass 22 (pass-21 fix round)

**Scope:** Partial, the pass-21 fix round only. A: `git diff d5d9121..bc98571 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`, HEAD dd14ff6 adds review docs only; `git diff --stat bc98571 HEAD -- scripts test` is empty). B: `git diff fbc7101..6c8ae91 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` (worktree `/workspace/.claude/wt-devcycle`, HEAD 21026af only merges A in; `git diff --stat 6c8ae91 21026af -- skills docs/dev-cycle.md` is empty). Consumer side: the four check modes' interface, output and `--help`, the skill's instructions against what the modes print, `docs/dev-cycle.md`, and the answer rule against the archive's real answer lines. Everything else is context.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass21.md` (Stage-1 context: the pass-20 round at d5d9121 / fbc7101; its Incorrect 12a and Stale 5 are what this round fixes) and `docs/reviews/api-consistency-review-2026-10-02-digest-pass21.md` (findings 1-8 this round addresses).

Probes (scratch `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/api22/`, below `api22/`): one throwaway repo under a `mktemp -d` dir there, removed after the probe; every run under `timeout`; no process outlived its command. `timeout 300 bats test/scripts/dev-cycle.bats`: 30/30 (`api22/bats.log`). `shellcheck scripts/dev-cycle.sh`: clean. `--help` output: `api22/help.log`. Answer rule over the archive: `timeout 30 python3 api22/answers.py docs/working/questions-archive.md docs/working/questions.md` (`api22/answers.log`) and `api22/answers2.py` (`api22/answers2.log`). The environment's `LC_ALL=en_US.UTF-8` is not installed; probes set `LC_ALL=C`. Nothing was written to either worktree except this file.

Legibility-target values: **agent** (the model running the skill acts on the text), **maintainer** (someone editing the script, skill or tests), **user** (the human answering questions or reading the record).

## Baseline Conventions

- **Check-mode shape** (`scripts/dev-cycle.sh:8-12`, `:98-101`, `:230-240`): `--check-<x> ARG...`, at least one argument, one line per argument (or per match for `--check-path`), `ok <value>` or `skip <value>: <reason>`, exit 0 when every argument was answered, exit 1 on bad usage. The two new modes follow it exactly.
- **Skip reasons** are lower-case noun phrases after `skip <value>: ` (`not an allowed path form`, `reached through a symlink, or not a regular file`, `no tracked file (or ignored file under docs/working/) matches`). New: `a directory, not a file`, `not a build brief (docs/working/briefs/YYYY-MM-DD-<slug>.md)`, `not one of the dev cycle's own files`, `not an allowed branch name`, `not a valid branch name`. Same shape.
- **Helpers** in this file are run-together lower-case predicates (`rawfile`, `plaindir`, `inrepo`, `dirok`, `pathform`, `writable`); command handlers are `check_<mode>` (`check_path`, `check_write`).
- **The skill invokes each check** as `~/.claude/scripts/dev-cycle.sh --check-<x> '<value>'` (inside claude-workflows, its own `scripts/dev-cycle.sh`; `SKILL.md:64-65`) and acts only on `ok`.
- **Answer lines in the archive** (`docs/working/questions-archive.md`, 82 lines carrying an answer label, excluding index rows): `**Answered <date>: …**` (the bulk, 2026-09-12 to 09-28), `**Answered <date> (<source>): …**` / `**Answered <date>, run 3: …**` (8 lines), `**ANSWERED <date>: …**` (1), and, since 2026-09-28, `**Answer (<date>[, <source>]): [n].**` (7 lines, every answer recorded since 09-28, including the newest at :1832).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--check-brief` | CLI flag | `--check-path`, `--check-write` | `scripts/dev-cycle.sh:9-10` | Consistent: same `--check-<x>` prefix, same argument and output shape |
| `--check-branch` | CLI flag | `--check-path`, `--check-write` | `scripts/dev-cycle.sh:9-10` | Consistent shape; its usage error still says "path" (Finding 4) |
| `check_branch` | function | `check_path`, `check_write` | `scripts/dev-cycle.sh:188`, `:214` | Consistent |
| `isbrief` | function (predicate) | `writable`, `dirok`, `inrepo` | `scripts/dev-cycle.sh:140-143`, `:210` | Consistent with this file's run-together predicates (the repo's other `is_permanent`, `scripts/archive-working-docs.sh:114`, is a different file's style) |
| `NAMECHARS`, `DIGIT` | shell constants | `TODAY`, `SKIPPED`, `MAIN` | `scripts/dev-cycle.sh:125,149,243` | Consistent upper-case globals |
| `skip …: a directory, not a file` | output reason | `skip …: reached through a symlink, or not a regular file` | `scripts/dev-cycle.sh:197`, `:201` | Consistent |
| `skip …: not a build brief (…)` | output reason | `skip …: not an allowed path form` | `scripts/dev-cycle.sh:190` | Consistent; the only reason that carries its expected shape in parentheses, which helps |
| `skip …: not an allowed branch name` / `not a valid branch name` | output reason | `not an allowed path form` | `scripts/dev-cycle.sh:190` | Consistent (allowed = charset, valid = git's rule) |

## Findings

#### 1. The answer label narrowed to a literal `**Answer:**`, which matches none of the 7 answer lines written since 2026-09-28

**Severity:** Breaking
**Location:** `skills/dev-cycle/SKILL.md:254-256` (B, 6c8ae91)
**Move:** 3 (trace the consumer contract: narrowing an accepted input range)
**Confidence:** Medium
**Legibility-target:** agent

**Evidence:**
```
     user chose from their answer: the line they wrote (`Q-NNN: …`, or the entry's
     `**Answer:**` / `**Answered <date>:**` line, any case; not `**Answering …**`), never the
     options table, taking only the text after that line's label colon, with `*` removed.
```
(excerpt from In-flight check 2, `SKILL.md:249-264` — read whole.) The previous rule was `` `**Answer…**` / `**Answered …**` `` (fbc7101). Real lines that the old wording admitted and the new literal one does not (`api22/answers.log`):
```
questions-archive.md:1715  **Answer (2026-09-28): [1].** Relax cc-push to accept a `commondir` ...
questions-archive.md:1777  **Answer (2026-09-30, answers-9-30-26.txt): [1].** A fourth full pass ...
questions-archive.md:1832  - **Answer (2026-10-01, in chat):** [1]. Cut carry-forward and `Main at:` ...
questions-archive.md:1200  **Answered 2026-09-23, run 3: single-slash rules match nothing; ...
questions-archive.md:186   **Answered 2026-09-17 (probe, `docs/human-author/answers-9-17-26.txt`): keep both — neither is wrong.**
```

The new text writes placeholders as `<date>` and "anything" as `…` (`**Answering …**`), so `**Answer:**`, with neither, reads as an exact label. Read that way, it rejects the `**Answer (<date>…):**` form that every answer since 2026-09-28 uses (7 lines: :1697, :1715, :1735, :1755, :1777, :1800, :1832; six of them a clean `[1]`), and the 8 `**Answered <date> (…):` / `, run 3:` lines. The literal reading matches 66 of the 82 real label lines; a "label word, anything, first colon" reading matches 81 (all but the `**Answering …**` line, which is correctly excluded). A keep-or-drop answer the next agent records in the current house style would find no label, fall to "anything else is unrecognized", and be added to `Applied:`, so the answer is consumed without effect. The user is re-asked only when step 3 files the next keep-or-drop entry, 14 days after the last `Kept:` date. Preconditions: a keep-or-drop entry gets answered, the recorder uses the `**Answer (<date>): …**` form, and the cycle's agent reads the label literally. Confidence is Medium because a lenient agent would accept the form; the text no longer tells it to.

**Recommendation:** State the label as a shape, not a literal: "a bold label that starts `Answer` or `Answered` (any case, not `Answering`) and runs to its first colon, e.g. `**Answer (2026-09-28): [1].**`, `**Answered 2026-09-20: [1].**`". Add one real `**Answer (<date>):**` line as the example.

#### 2. "`[1]` and `[2]` together" is tested over the whole rest of the line, so two clear `[1]` answers whose notes mention `[2]` become unrecognized

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:256-257` (B, 6c8ae91)
**Move:** 3 (consumer contract against the archive's real lines)
**Confidence:** High
**Legibility-target:** agent

**Evidence:**
```
     options table, taking only the text after that line's label colon, with `*` removed.
     If that text has `[1]` or `[2]` but not both, that is the option (as in `Q-NNN: [1]`);
```
Real lines (`questions-archive.md`):
```
:1412  ... **Answered 2026-09-27: [1] supply the backstops.** Add Bash deny rules ... [2] (narrow the hook), which the entry recommended as a default alongside any choice, was not picked. ...
:1697  **Answer (2026-09-28): [1].** The user ran ... If a later sandboxed host session brings it back, reopen with [2].
:1452  ... **Answered 2026-09-27: between [1] and [2].** New reviews should not each add a canon entry. ...
```

"That text" is everything after the label colon to the end of the line, and the recorder's notes follow the bold answer on the same line. The fix makes :1452 (a genuine "between") unrecognized, as intended, but also turns :1412 and :1697 (a clean `[1]` each; :1697 under the lenient label reading of Finding 1) from correct under the old first-`[n]` rule into unrecognized (`api22/answers2.log`: `line=BOTH` for :1412, :1452, :1697). Restricting the test to the bold answer span (to the closing `**`; when the bold closes at the label colon, as at :1832, to the first `. `) reads :1412 and :1697 as `[1]` and still reads :1452 as both (`span=[1]`, `span=BOTH`, `span=[1]`). No other real line changes verdict between the two readings. The failure is safe (unrecognized is listed and re-asked), hence Minor; its cost is the 14-day re-ask path described in Finding 1.

**Recommendation:** "taking only the bold answer after the label colon (up to its closing `**`, or, when the bold ends at the colon, up to the first sentence end)". Then the both-`[1]`-and-`[2]` and first-word tests apply to that span.

#### 3. `--help` still describes `--check-write` as "a file the cycle writes" and `--check-brief` as sufficient for a roadmap brief path

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:24-27` (A, bc98571)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** agent

**Evidence:**
```
#   --check-write  the same for a file the cycle writes: only its own files
#             (roadmap, questions files, idea log, cycle records, briefs).
#   --check-brief  the same, for a build brief only (docs/working/briefs/
#             YYYY-MM-DD-<slug>.md): what a roadmap brief path must pass.
```
against the same commit's comment and skip reason, and the skill:
```
# scripts/dev-cycle.sh:204-205
# The cycle's own bookkeeping files (in-cycle fixes to other files go through
# --check-path instead); anything else named in repo text (a roadmap
```
```
SKILL.md:72-74  A roadmap brief path counts as a brief (and holds a slot) only if `--check-brief '<path>'` and
`--check-path '<path>'` both print `ok` for it.
```

bc98571's message says the write-list wording was fixed in the "comment and skip reason"; the help header, which is what `--help` prints (`api22/help.log`), still reads "a file the cycle writes: only its own files", the sentence fact-check 12a found false once in-cycle fixes exist. The `--check-brief` line says it is "what a roadmap brief path must pass", while the skill requires `--check-path` too (an absent or untracked brief passes `--check-brief`: probe printed `ok docs/working/briefs/2026-10-02-new.md` for a file that does not exist). An agent reading only `--help` gets a sufficient condition the skill says is not sufficient. `--check-branch`'s line also omits the `skip <name>: <reason>` line the others inherit through "the same" (Informational in itself).

**Recommendation:** `--check-write  the same for one of the cycle's own bookkeeping files (roadmap, …); an in-cycle fix to any other file uses --check-path.` `--check-brief  … the write check for a roadmap brief path; it must also pass --check-path to count.` Add `"skip <name>: <reason>" otherwise` to `--check-branch`.

#### 4. `--check-branch` with no argument says it "needs at least one path"

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:100` (A, bc98571)
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** agent

Precedent: `NAME...` for `--check-branch` used in `scripts/dev-cycle.sh:12` (and `PATH...` for the path modes at `:9-11`)

**Evidence:**
```
      [[ ${#CHECK_ARGS[@]} -gt 0 ]] || { echo "$CHECK needs at least one path" >&2; exit 1; }
```
Run: `--check-branch needs at least one path`, `rc=1`.

The shared usage check was extended to the new mode without its noun. Harmless in effect (exit 1 is right), but the message contradicts the usage line two screens up.

**Recommendation:** `"$CHECK needs at least one argument"`, or pick the noun by mode.

#### 5. A brief whose branch fails `--check-branch` is "left as it is", but In-flight checks 2 and 3 do not say whether they still run for it

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:246-248`, `:265-267` (B, 6c8ae91)
**Move:** 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** agent

**Evidence:**
```
  1. Its branch (checked as in the Rules; one that fails is a skip, and the brief is left as
     it is) merged into the default branch → Done. The user dropped it (closed the brief,
     or said so) → Ideas, with the reason. Either way the brief gets `Status: closed`.
```
```
  3. Then, if the brief is still open, no ID on its `Asked:` line is still unanswered, and
     the branch has no commit beyond the default branch (or does not exist yet) 14 days after
```
(excerpts from In-flight checks 1-3, `SKILL.md:244-271` — read whole.)

"Left as it is" can mean "skip check 1's branch test only" or "touch nothing on this brief". Check 2 needs no branch and writes `Applied:`/`Kept:` to the brief, so the two readings differ: under the second, a user's drop answer on that brief is never applied; under the first, check 3 has to evaluate "the branch has no commit beyond the default branch" for a name it may not give git, and the text does not say what that evaluates to. The user-dropped half of check 1 also needs no branch. Every git call with the brief's branch is still gated by the Rules (`SKILL.md:74-75`), so this is ambiguity, not an unchecked call.

**Recommendation:** "one that fails is a skip: the merged test and check 3 do not run for that brief (no keep-or-drop is filed), while the user-dropped test and check 2 still apply."

#### 6. `--check-branch` prints `ok` for names `git branch` refuses (`HEAD`)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:224-229` (A, bc98571)
**Move:** 3
**Confidence:** High
**Legibility-target:** maintainer

**Evidence:**
```
check_branch() {
  local a="$1"
  if [[ ! "$a" =~ ^[$NAMECHARS]+$ || "$a" == -* ]]; then echo "skip ${a//$'\n'/ }: not an allowed branch name"
  elif ! git check-ref-format "refs/heads/$a"; then echo "skip $a: not a valid branch name"
  else echo "ok $a"; fi
}
```
Run: `ok HEAD`, `ok main`, `ok refs/heads/x`.

`git check-ref-format refs/heads/HEAD` passes, while `git check-ref-format --branch HEAD` (and `git branch HEAD`) refuses it. Because the skill passes the name only as `refs/heads/<name>`, `HEAD` resolves to a branch that cannot exist, which the In-flight checks read as "does not exist yet"; no other ref is reached. The help's "a valid ref name" is accurate as written. Noted so the gap between "valid ref" and "valid branch" is deliberate.

**Recommendation:** None needed; optionally also run `git check-ref-format --branch "$a"` so the check matches what `git branch` accepts.

#### 7. `docs/dev-cycle.md` now names the installed copy, in the one repo where the skill says to use its own script

**Severity:** Informational
**Location:** `docs/dev-cycle.md:27` (B, 6c8ae91)
**Move:** 1 (baseline: how the skill names the script)
**Confidence:** High
**Legibility-target:** maintainer

**Evidence:**
```
Each row is passed to `~/.claude/scripts/dev-cycle.sh --check-path`, which allows tracked
```
against `SKILL.md:64-65`: "`~/.claude/scripts/dev-cycle.sh --check-path '<path or glob>' …` (inside claude-workflows, its own `scripts/dev-cycle.sh`)". fbc7101 had the unqualified `dev-cycle.sh --check-path`.

This settings file is claude-workflows' own, so the path it now names is the one the skill says not to use here. The description of the rule is otherwise exact (50 per row, directory, `.`/`..`, `.git*`, charset), checked against the probe output below. The skill governs the call, so the impact is a reader's confusion only.

**Recommendation:** Drop the `~/.claude/scripts/` prefix again, or add "(here, `scripts/dev-cycle.sh`)".

#### 8. The first-word rule reads "keep both — neither is wrong." as keep

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:258-259` (B, 6c8ae91)
**Move:** 3
**Confidence:** High
**Legibility-target:** agent

**Evidence:**
```
     with neither, its first word, with a trailing `.` or `,` removed, if that is `1`,
     `keep`, `2` or `drop` (any case).
```
Archive `:186`: `**Answered 2026-09-17 (probe, …): keep both — neither is wrong.**` reads as `keep` under the lenient label reading (`api22/answers.log`). The first-word change does what the commit says ("keep. Still wanted." reads as keep) and no real keep-or-drop line exists yet; this is the hedged-answer edge pass 21 #7 noted, now with a real example. A keep-or-drop answer is unlikely to say "keep both".

**Recommendation:** None for this pass.

## What Looks Good

Checked and correct (and complete for what each claims):
- **Character lists.** `NAMECHARS` (`scripts/dev-cycle.sh:163`) ends in `-`, and the glob set puts `*?` first (`"^[*?$NAMECHARS]+\$"`), so `-` stays a literal last; `.` and `*` inside a bracket are literal; `DIGIT='[0123456789]'` with `{4}` works unquoted inside `[[ =~ ]]` (the expansions are unquoted on purpose, so they act as regex). `^[$NAMECHARS]+$` in `check_branch` anchors correctly (`a b`, `a;b`, `HEAD@{1}`, `x@{`, `@`, empty all skipped). No range remains, so no locale dependency.
- **`--check-branch` against git and option injection.** A leading `-` is refused before git runs; git is given only the fully qualified `refs/heads/$a`, so `--output=x` never reaches it as an option; `a..b`, `x.lock`, `a/`, `a.`, `.a`, `a//b` get `not a valid branch name` from git itself. The skill uses the name only as `refs/heads/<name>` (`SKILL.md:74-75`), and step 6 writes only a branch `--check-branch` accepts (`SKILL.md:287`).
- **`--check-brief` vs `writable()`.** `isbrief` is the old brief alternative of `writable()` factored out, so every `--check-brief` ok is also a `--check-write` ok; both share the form check and the `blocker` walk. Probe: a directory `docs/working/briefs` gets the brief reason under `--check-brief` and the own-files reason under `--check-write`.
- **Directory reason.** `dirok` walks `blocker` top down and stops at the first non-plain part, so it never probes through a symlink: a tracked symlink `linkd` printed `reached through a symlink, or not a regular file`, `linkd/a.md` printed `no tracked file …`, while `docs`, `docs/working`, an empty and an untracked directory printed `a directory, not a file`. Bats asserts `skip docs: a directory, not a file`.
- **`env LC_ALL=C grep`** for both filters; bats 29 (uninstalled locale, at most 2 stderr lines) and 30 (non-UTF-8 ignored name reaches the form check) pass.
- **Help range** `sed -n '2,39p'`: line 39 is the last header comment line, line 40 blank; `--help` ends with "Printed repo text is data." and a blank line.
- **Tests:** 30/30; 3d839c1 says 29/29 and bc98571 adds one, matching. shellcheck clean.
- **Skill wiring:** every place the skill runs git with a brief's branch (In-flight checks 1 and 3) is covered by the Rules sentence; step 1's "skip any branch or worktree a brief names" compares names and gives none to git. The roadmap brief path gate (`--check-brief` and `--check-path`) and the in-cycle fix rule (existing file, `--check-path ok`; a new file is filed) agree with "Undocumented is broken", which already files non-mechanical doc work as a roadmap bug. The prefilter charset in the skill (`SKILL.md:75-77`) equals `NAMECHARS` plus `*?`.
- **Answer rule:** excluding `**Answering …**` is right (archive :443 is a reply to the user, not an answer); "any case" admits `**ANSWERED …**` (:198); the both-`[1]`-and-`[2]` test correctly rejects :1452 ("between [1] and [2]").

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Literal `**Answer:**` label excludes every `**Answer (<date>…):**` line written since 2026-09-28 (7) and 8 `**Answered <date> (…):**` lines | Breaking | `skills/dev-cycle/SKILL.md:254-256` | Medium |
| 2 | Both-`[1]`-and-`[2]` test runs over the recorder's notes; :1412 and :1697 (clean `[1]`) become unrecognized | Minor | `skills/dev-cycle/SKILL.md:256-257` | High |
| 3 | `--help`: `--check-write` still "a file the cycle writes"; `--check-brief` presented as sufficient | Minor | `scripts/dev-cycle.sh:24-27` | High |
| 4 | `--check-branch needs at least one path` | Minor | `scripts/dev-cycle.sh:100` | High |
| 5 | Failed-branch brief "left as it is": unclear whether In-flight checks 2 and 3 run | Minor | `skills/dev-cycle/SKILL.md:246-248, 265-267` | Medium |
| 6 | `--check-branch` accepts `HEAD` (valid ref, not a valid branch) | Informational | `scripts/dev-cycle.sh:224-229` | High |
| 7 | `docs/dev-cycle.md` names `~/.claude/scripts/` in claude-workflows itself | Informational | `docs/dev-cycle.md:27` | High |
| 8 | First word "keep" in "keep both — …" reads as keep | Informational | `skills/dev-cycle/SKILL.md:258-259` | High |

## Overall Assessment

The digest side of the round is consistent: the two new modes follow the existing `--check-<x> ARG...` / `ok`/`skip` contract exactly, the character lists and `--check-branch`'s git gate are correct and complete, and the tests cover both modes. What remains there is wording (help lines 24-27, the usage error). The skill side closes the pass-21 Medium (every git call with a brief's branch is now gated) and the brief-path gate. The one consumer-facing regression is in answer parsing: tightening the label to a literal `**Answer:**` drops the shape the archive has used for every answer since 2026-09-28, and the "both" test reads the recorder's trailing notes. Both fail safe (unrecognized, re-asked), but the re-ask waits 14 days. Both are fixable in place by defining the label as a shape and the answer as the bold span; the archive check in `api22/answers2.py` shows that reading gets every real line right.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass22.md`, first line `Commit: bc98571 (A) / 6c8ae91 (B)`, with the skill's sections (header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment); every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target, and the one naming finding (4) carries its `Precedent:` line. It serves the user goal (reach a clean pass, then merge) by naming the remaining known issues in this round's fixes: one Breaking (answer label) and four Minor.
