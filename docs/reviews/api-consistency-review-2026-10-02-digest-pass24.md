Commit: c1d0a80 (A) / fb643e2 (B)

# API Consistency Review — dev-cycle pass 24 (pass-23 fix round)

**Scope:** A `git diff ba39470..c1d0a80 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest); B `git diff 36ca12c..fb643e2 -- skills/dev-cycle/SKILL.md` (wt-devcycle, merge 0caaba2). Partial scope: everything else is context only.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass23.md` (Stage-1 context, loop pass 23) and the pass-23 rubric section.

All probes ran from one-script temp dirs under the session scratchpad (`api24/`), each beginning with `set -eu`, `mktemp -d -p`, and a `$PWD` guard. They used `git show` / `git archive` copies of the pinned commits. Nothing was written to either worktree except this file. `git status --short` in both worktrees was empty after the probes. `awk` is mawk 1.3.4. `bats test/scripts/dev-cycle.bats` on an archive of c1d0a80: 1..36, 36 ok, 0 failed.

## Baseline Conventions

- **Check-mode output contract** (dev-cycle.sh header, lines 22-44): one line per argument, and the first token is the verdict: `ok <value> [extra]` or `skip <value>: <reason>`. Before round 23, `--check-answer` printed bare `keep|drop|open|unrecognized Q-NNN`. Every skip line that echoes a raw argument folds newlines first (`${a//$'\n'/ }`, dc.sh:206, 212, 235, 247, 263, 330), so each argument yields exactly one line.
- **Reasons** are lower-case phrases after `: `, and they say what failed ("not an allowed path form", "reached through a symlink, or not a regular file").
- **Brief lifecycle vocabulary** (SKILL.md before this round): `Status: open` is written by the cycle and `Status: closed` by the cycle when a brief is dropped or done. Open briefs are the ones the `docs/working/briefs/*.md` glob lists. Questions entries use `**Status:** OPEN/ANSWERED` and move to `questions-archive.md` when answered.
- **Default branch** is resolved once (dc.sh:344-364): origin/HEAD, then main, then master, then the current branch. Git receives only a hash for it.
- **Mechanical rules for repo text live in tested check modes**, and the skill only calls them (brief goal preamble; SKILL.md:61-85).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `absent <name>` (check-branch line) | output verdict token | `ok <v>`, `skip <v>: <reason>`, `open Q-NNN` | `scripts/dev-cycle.sh:32-44` | Consistent. It is a third bare verdict token, shaped like `open Q-NNN`, and it replaces the odd `ok <name> absent` |
| `ok <name> <commit>` | output | `ok <path>` | `scripts/dev-cycle.sh:214, 239` | Consistent. Trailing payload after the value, as before |
| `skip <name>: the default branch` | skip reason | "not a valid branch name", "not an allowed branch name" | `scripts/dev-cycle.sh:247-249` | Consistent |
| `skip <a>: --check-fix takes one file, not a glob` | skip reason | "not an allowed path form" | `scripts/dev-cycle.sh:263` | Inconsistent. It does not fold newlines (Finding 2) |
| `skip Q-NNN: more than one entry with this heading[ (f1 and f2)]` | skip reason | `skip Q-NNN: no such entry in …` | `scripts/dev-cycle.sh:336, 340` | Mostly consistent. It names the files only in the cross-file case (Finding 10) |
| `skip Q-NNN: <part> is not a plain file or directory, so <f> is not read` | skip reason | `skipnote` "… is not read: … is not a plain file or directory (section 8)." | `scripts/dev-cycle.sh:160, 332` | Consistent in wording |
| `<option> Q-NNN` (help placeholder) | help text | `"ok <path>"`, `"ok <name> <commit>"` | `scripts/dev-cycle.sh:24, 32` | Consistent |
| `docs/working/briefs/closed/` | path | `docs/working/questions-archive.md`, repo `archive/` | `docs/working/` (SKILL.md:75-76), `archive/` | Minor. The directory holds done *and* dropped briefs, while `Status: closed` means dropped only (Finding 4) |
| `Status: done` | brief field value | `Status: open`, `Status: closed` | `skills/dev-cycle/SKILL.md:253, 293` | Consistent in form. Its detection is not in code and collides with brief text (Finding 1) |
| `SLUG` (shell var) | internal | `DIGIT`, `NAMECHARS` | `scripts/dev-cycle.sh:177, 225` | Consistent (private) |
| `dup` (awk sentinel) | internal | `keep/drop/open/unrecognized` | `scripts/dev-cycle.sh:325` | Private. It never reaches output, because check_answer maps it to a skip (dc.sh:336) |

## Findings

#### 1. `Status: done` is a new cross-session contract read only by prose, and every brief contains that literal text

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:251-253`, `skills/dev-cycle/SKILL.md:294-295`
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High that the text collides; Medium that a cycle misreads it
**Legibility-target:** the cycle agent running step 6, and the build session that writes the field

**Evidence:** SKILL.md:251 says: "1. The brief on the default branch says `Status: done` (the build session sets it in the change it merges; see Build briefs) → Done". SKILL.md:294-295 says the cycle writes, into every brief's acceptance criteria: "included, and "set this brief's `Status: done` in the change that merges it"), branch (a" [line continues: "new name: …"].

The Done signal is a field written by one session and read by another. Nothing defines it as a line of its own (`Status:` at the start of a line), and no check mode reads it. The cycle writes the literal string `Status: done` into the acceptance criteria of every open brief. Under the skill's own wording, "says `Status: done`", a freshly written brief therefore matches. `--check-answer` now pins exactly this kind of collision in tested code ("not `**Answering`", fences, a label "anywhere in a line", the leading token). The brief Status, which is the field that moves an item to Done, has no such rule.

Precondition for harm: a reading agent matches the phrase rather than the brief's `Status:` line. The item then goes to Done and its brief is `git mv`'d out of the glob with no work done. That is the same class of fault as pass-23's A1, which ancestry caused.

**Recommendation:** Define the field as a line that is exactly `Status: <open|done|closed>` (the first such line, outside fences) and read it through a check mode (for example `--check-brief` printing `open|done|closed <path>`). Reword the acceptance criterion so that it does not contain the token verbatim, for example "change this brief's Status line from open to done".

#### 2. The new `--check-fix` glob skip echoes the raw argument, so an argument with a newline breaks the one-line-per-argument contract

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:262`
**Move:** 4 (error consistency)
**Confidence:** High (probed)
**Legibility-target:** a caller parsing check-mode lines, for example the cycle agent reading `ok <path>`

**Evidence:** dc.sh:262 is `if [[ "$a" == *[*?]* ]]; then echo "skip $a: --check-fix takes one file, not a glob"`. Every other echo of an unvalidated argument folds newlines first, for example the next line, dc.sh:263: `elif ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"`. Probe output for `--check-fix "$(printf 'x*\nok README.md')"`:
```
skip x*$
ok README.md: --check-fix takes one file, not a glob$
```
The glob test was moved ahead of `pathform` this round, so it now sees values that `pathform` would have rejected and folded. The scrub keeps LF, so the second line starts with `ok README.md`.

Precondition: the caller passes a value with a newline. The skill forbids this before the call (SKILL.md:80-82), but that is a prose filter, and the script's own contract is to answer every argument on one line.

**Recommendation:** Use `${a//$'\n'/ }` in this branch, as the other skip lines do, and add the newline case to test 35.

#### 3. `git mv` into `briefs/closed/` fails on the first close, because nothing creates the directory

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:254-255`
**Move:** 3
**Confidence:** High (probed). Medium on impact, since an agent will probably recover with `mkdir -p`.
**Legibility-target:** the cycle agent in step 6

**Evidence:** SKILL.md:254-255: "Either way, `git mv` the brief to `docs/working/briefs/closed/` (same file name; its destination passes `--check-write`) and point the roadmap line there." Probe with git 2.39.5, in a repo with only `docs/working/briefs/2026-10-01-a.md`: `fatal: renaming 'docs/working/briefs/2026-10-01-a.md' failed: No such file or directory`, rc=128. fb643e2 tracks no `docs/working/briefs/` directory at all. `--check-write` passes the destination (`ok docs/working/briefs/closed/2026-10-01-a.md`) because absent parents are allowed (dc.sh:144), so the check does not reveal the missing directory.

**Recommendation:** Add "create `docs/working/briefs/closed/` if missing" to the step, and have the digest's `skipdir` (dc.sh:633) also cover `docs/working/briefs/closed` so that a non-plain one appears in section 8.

#### 4. "Open" and "closed" each mean two things, and a brief set to `Status: closed` by hand is not routed

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:75-77`, `skills/dev-cycle/SKILL.md:251-257`, `scripts/dev-cycle.sh:223-224, 236`
**Move:** 2 (naming), 7
**Confidence:** Medium
**Legibility-target:** the cycle agent, and the user closing a brief by hand

Precedent: `Status: closed` = dropped, used in `skills/dev-cycle/SKILL.md:253`. Location-based "open" = listed by the glob, used in `skills/dev-cycle/SKILL.md:75-76` and `scripts/dev-cycle.sh:236`.

**Evidence:** SKILL.md:75-76: "Open briefs are found only through `--check-path 'docs/working/briefs/*.md'` (a closed brief moves to `docs/working/briefs/closed/`, so the glob lists open ones only)". SKILL.md:252-253: "The user dropped it (said so, or by keep-or-drop) → Ideas, with the reason, and the brief gets `Status: closed`." The pass-23 text read "The user dropped it (closed the brief, or said so)". The "closed the brief" path was removed.

`briefs/closed/` holds `Status: done` briefs as well as `Status: closed` ones, so "closed" names both the directory for any finished brief and the field value for a dropped one. "Open" in steps 2 and 3 ("If the brief is still open") could mean the glob or the field. A brief whose `Status:` the user set to `closed` by hand, but which still sits in `briefs/`, matches no branch of step 1. It keeps a slot in the 3-brief count and keeps getting keep-or-drop questions.

**Recommendation:** Say in step 1 that any `Status:` other than `open` on the default branch closes the brief: `done` goes to Done, anything else goes to Ideas. Alternatively, name the directory for what it holds, for example `briefs/finished/`, or state outright that "closed/" means "no longer open".

#### 5. `<default-commit>` in the "shows no work" rule has no source that is a full hash

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:274-276`; `scripts/dev-cycle.sh:417`
**Move:** 3
**Confidence:** Medium
**Legibility-target:** the cycle agent in step 6, check 3

**Evidence:** SKILL.md:275-276: "prints a commit with no commit beyond the default branch (`git rev-list --count <default-commit>..<commit>` is 0)." No check mode prints the default branch's commit. The only place it appears is the digest's Window line, abbreviated (dc.sh:417: "those on \`$MAIN\` at ${MAIN_SHA:0:7} whose …"). The Rules give git a brief's branch only as a hash, but they say nothing about how the default branch reaches `rev-list`. The cycle is left to choose between a 7-character abbreviation and passing the branch name, and the latter is the form the script avoids for the default branch (dc.sh:342-343).

**Recommendation:** Have `--check-branch` print the default commit (for example on the `skip <name>: the default branch` line), or have the digest print the full hash, and name that source in step 6.

#### 6. The `--check-fix` skip reason, help and skill omit the bookkeeping-file exclusion the code enforces

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:264-265`, `scripts/dev-cycle.sh:37-39`, `skills/dev-cycle/SKILL.md:72-74`
**Move:** 4, 3 (documentation drift)
**Confidence:** High (probed)
**Legibility-target:** the cycle agent deciding whether to file or fix

**Evidence:** dc.sh:264 is `elif [[ ! "$a" =~ ^docs/.*\.md$|^README\.md$ || "$a" =~ ^docs/(working|human-author|reviews)/ ]] || writable "$a"; then`. The probe printed `skip docs/roadmap.md: in-cycle fixes edit only tracked .md files under docs/ (not working/, human-author/ or reviews/) and README.md; file it instead`. `docs/roadmap.md` *is* a tracked .md under docs/ outside those three directories, so the reason contradicts the input. The help (lines 37-39) and SKILL.md:72-74 describe the same three exclusions and do not mention `writable`. The behavior is right: the roadmap is edited under `--check-write`, not as a fix. The printed reason is what is wrong.

**Recommendation:** Give `writable` paths their own reason ("one of the cycle's own files: use --check-write"), and mention it in the help line.

#### 7. `--check-fix` allows `docs/dev-cycle.md` and decision records, which the docs describe as user-kept or final

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:264`; `skills/dev-cycle/SKILL.md:56-59`; `docs/dev-cycle.md` (fb643e2)
**Move:** 3
**Confidence:** Medium
**Legibility-target:** the user, who owns the build-loop policy line

**Evidence:** Probe: `ok docs/dev-cycle.md` and `ok docs/decisions/001-x.md`. SKILL.md:59: "**Idea sources** (read by step 5, kept by hand)." docs/dev-cycle.md: "Codebase onboarding asks the user for the build-loop policy (its step 13); the idea sources are kept by hand." That file also says the handoff will treat `Build-loop policy: self-merge` as permission to land unreviewed work. Global instructions describe decision records as final, with a log row for amendments. Under the new allow-set, an "in-cycle fix" may rewrite the user's policy line or edit a decision record in place. Precondition: the cycle judges such an edit mechanical. This is security's call more than API's. It is recorded here because the allow-set disagrees with the ownership that two documents state.

**Recommendation:** Exclude `docs/dev-cycle.md` (as `writable` files are excluded). Either say in SKILL.md that decision records are amended through `docs/decisions/log.md` rather than edited, or accept the current behavior and state that in the help.

#### 8. Keep-or-drop has no "done" outlet for a brief whose build session forgot `Status: done`

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:252-253`, `skills/dev-cycle/SKILL.md:268-276`
**Move:** 3, 7
**Confidence:** Medium
**Legibility-target:** the user answering keep-or-drop

**Evidence:** SKILL.md:272-273: "asking "keep or drop <brief path>?" with options **[1] keep** and **[2] drop**". SKILL.md:252-253: dropped → "Ideas, with the reason". Merged work whose brief still says `Status: open` "shows no work" once the branch is merged (`rev-list` gives 0) or deleted (`absent`). Fourteen days later the user is asked keep or drop. `keep` repeats the question every 14 days, and `drop` files finished work under Ideas. The only way to reach Done is an undocumented hand edit of `Status: done`.

**Recommendation:** Tell the user in the entry or the final message that a merged brief can be marked by setting `Status: done`, or add a third option (`[3] done`) and teach `--check-answer` to read it.

#### 9. The default-branch refusal follows the current-branch fallback, so on the cycle branch it refuses the wrong name

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:250`, `scripts/dev-cycle.sh:357-362`, `scripts/dev-cycle.sh:365`
**Move:** 3
**Confidence:** High (probed). The preconditions are narrow.
**Legibility-target:** the cycle agent in step 6

**Evidence:** dc.sh:250 is `elif [[ "$a" == "$MAIN" ]]; then echo "skip $a: the default branch"`, and MAIN falls back to `git symbolic-ref --quiet --short HEAD` (dc.sh:359). The probe used a repo whose default branch is `trunk` (no origin, no main or master), checked out on `chore/dev-cycle-2026-10-02`. Step 6 runs on that branch per the Rules. Output: `ok trunk cfb83ea…` / `skip chore/dev-cycle-2026-10-02: the default branch`. Step 0 runs on the default checkout, where the fallback is right. The check modes run later, on the cycle branch, where it is not.

**Recommendation:** Accept and document this ("default branch = as the digest resolved it from the current checkout"), or have the cycle pass the default commit it recorded in step 0.

#### 10. The duplicate-heading skip names its files only in the cross-file case

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:336`
**Move:** 4
**Confidence:** High (probed)
**Legibility-target:** the user fixing the questions file

**Evidence:** dc.sh:336 is `echo "skip $a: more than one entry with this heading${where:+ ($where and $f)}"`. Probe: `skip Q-006: more than one entry with this heading` for a duplicate inside questions.md, with no file named. A duplicate inside the archive, after a hit in questions.md, prints "(docs/working/questions.md and docs/working/questions-archive.md)", which names a file that is not the duplicated one. Every other check_answer skip names the file. A skip now stays off `Applied:` "until the cause is fixed" (SKILL.md:266-267), so the user needs to know where the cause is.

**Recommendation:** Have the awk report `dup` with the file, and print "(twice in <f>)" or "(in <f1> and <f2>)" as the case requires.

#### 11. The leading-token rule now reads `[1] and [2]` as keep

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:277-280, 285-286`; help `scripts/dev-cycle.sh:40-43`
**Move:** 3 (subtle semantic change)
**Confidence:** High (probed)
**Legibility-target:** the user answering

**Evidence:** Probe: `**Answer:** [1] and [2]` gives `keep Q-002`. Before this round the rule was "[1] or [2] alone decides; both together are unrecognized". Help line 42 says `unrecognized (answered, but not as keep or drop)`. The comment at dc.sh:277-280 documents the new behavior, so code and comment agree. Only the help's gloss of "unrecognized" invites the old reading. On a two-option entry, "[1] and [2]" is self-contradictory. Separately, a bold `**Answer format:**` placed in question prose ahead of the real answer is taken as the answer (probe: `keep Q-003` despite a later `Q-003: drop`). No entry the cycle files has this shape. Both are noted, not urged.

**Recommendation:** None required. Optionally keep "both" as unrecognized when the text has both `[1]` and `[2]` and no word token.

#### 12. Check modes now exit 1 where no default branch resolves, and the skill does not say what that means

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:364-366`; `scripts/dev-cycle.sh:50-52`
**Move:** 6 (versioning / changed behavior)
**Confidence:** High (probed)
**Legibility-target:** the cycle agent

**Evidence:** Probe on a detached HEAD with no main, master or origin/HEAD: `--check-path README.md` prints `Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)` with rc=1. Before this round, check modes ran ahead of that lookup. The exit line in the help already covers the case ("1 bad usage, not a git repo, no default branch or no perl"), so the contract is documented. The cycle never runs detached, so this is acceptable. SKILL.md says what to do when the digest fails (line 131) but not when a check fails. The implied answer, "nothing is ok", is the safe one.

**Recommendation:** None required. Optionally add one clause: "a check that exits non-zero answers nothing: treat every argument as skipped."

## What Looks Good

- **`--check-answer` on the real files is correct.** All 102 headings in `questions.md` and `questions-archive.md` at 0caaba2 were run under c1d0a80 and ba39470: 29 keep, 19 drop, 13 open, 41 unrecognized. The only differences are Q-070, Q-071 and Q-073, which changed from unrecognized to keep, as the brief says. All three are mid-line `**Answered 2026-09-27: [1] …**` labels, so keep is the right reading. Q-083 and Q-087 ("… Original entry:" quoting) still read keep and drop from their first answer line.
- **Leading-token edges hold under mawk:** `2 — keep it` reads drop (em-dash bytes matched), `keep both` reads unrecognized, `- **Answered …: [2] drop.** note [1]` reads drop, and `10` falls through.
- **The `absent <name>` verdict** removes the old `ok <name> absent` shape, in which `ok` meant "not there". `^{commit}` peeling matches the default-branch lookup (dc.sh:253 vs 354). The new skip reasons follow the established "skip <v>: <phrase>" shape.
- **Help range `sed -n '2,53p'`** prints exactly the header through the Exit paragraph and a blank line 53. Every documented output shape (`ok <name> <commit>`, `absent <name>`, `<option> Q-NNN`, `skip Q-NNN: <reason>`) matches what the code prints.
- **`--check-write` / `--check-brief`** treat `briefs/closed/` correctly: the closed path is writable but is not a brief, and a non-dated closed name is refused. This agrees with SKILL.md:75-77 and :254-255.
- **The skip handling on `Applied:`** (SKILL.md:263-267) separates "answered" (`keep`/`drop`/`unrecognized`) from "not read" (`skip`), and step 3 treats both `open` and skipped IDs as blockers. The questions-file contract and the brief contract now line up.
- **Done no longer depends on branch ancestry** (SKILL.md:251-256), which removes pass-23's A1 class. The "must be `absent` when written" rule (SKILL.md:295-296) means an unstarted brief cannot point at old work.
- Tests: 36/36 pass on an archive of c1d0a80.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `Status: done` read only by prose, and the literal is in every brief's criteria | Inconsistent | `skills/dev-cycle/SKILL.md:251-253, 294-295` | High / Medium |
| 2 | `--check-fix` glob skip does not fold newlines (multi-line, `ok`-led output) | Inconsistent | `scripts/dev-cycle.sh:262` | High |
| 3 | `git mv` to missing `briefs/closed/` fails on the first close | Minor | `skills/dev-cycle/SKILL.md:254-255` | High |
| 4 | "open"/"closed" double meanings; hand-set `Status: closed` not routed | Minor | `skills/dev-cycle/SKILL.md:75-77, 251-257` | Medium |
| 5 | `<default-commit>` has no full-hash source | Minor | `skills/dev-cycle/SKILL.md:274-276`; `scripts/dev-cycle.sh:417` | Medium |
| 6 | `--check-fix` reason, help and skill omit the `writable` exclusion | Minor | `scripts/dev-cycle.sh:264-265, 37-39` | High |
| 7 | `--check-fix` allows `docs/dev-cycle.md` and decision records | Minor | `scripts/dev-cycle.sh:264` | Medium |
| 8 | No "done" outlet in keep-or-drop for a forgotten `Status: done` | Minor | `skills/dev-cycle/SKILL.md:268-276` | Medium |
| 9 | Default-branch refusal uses the current-branch fallback on the cycle branch | Minor | `scripts/dev-cycle.sh:250, 357-362` | High (narrow) |
| 10 | Dup skip names its files only cross-file | Informational | `scripts/dev-cycle.sh:336` | High |
| 11 | `[1] and [2]` now reads keep; a prose `**Answer …:**` pre-empts | Informational | `scripts/dev-cycle.sh:277-286` | High |
| 12 | Check modes exit 1 with no default branch; the skill is silent on check failure | Informational | `scripts/dev-cycle.sh:364-366` | High |

## Overall Assessment

The round's code changes keep to the check-mode conventions. The new verdict `absent`, the skip reasons and the `<option> Q-NNN` help shape all match their neighbors. On every real entry, `--check-answer` gives exactly the three intended changes, and the leading-token rule is correct and tested at its edges. Finding 2 is the one regression of the established pattern: a reordered branch lost the newline fold, which can be fixed in place in one line. The main consumer-contract issue (Finding 1) is in the skill. Done now rests on a brief field that two sessions share, and it is the one lifecycle signal not read by tested code. The cycle also writes the matching literal into every brief. That runs against the user's "mechanical rules live in tested code" direction, and it reopens a misclassification path of the same shape as A1. Findings 3-9 are first-use and edge gaps in the brief lifecycle and the fix scope, each fixable in a sentence or a reason string. Nothing here breaks an existing consumer.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass24.md`, with first line `Commit: c1d0a80 (A) / fb643e2 (B)`. It follows the api-consistency-reviewer structure: header, Baseline Conventions, Name-Pattern Audit, Findings with Severity/Location/Evidence/Confidence/Legibility-target, What Looks Good, Summary Table and Overall Assessment. It covers the brief's named claims:
- the check-mode interface, output shapes and help
- the skill text against the script's output
- the brief lifecycle across SKILL.md, docs/dev-cycle.md and the roadmap format
- `--check-answer` against all real answer lines

Not committed. The probe rule was followed. No change was made outside the scratch temp dirs other than this file.
