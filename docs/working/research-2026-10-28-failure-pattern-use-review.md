# Research: how the failure-pattern library is actually used

- **Goal**: From this repo's own record, find whether and how `docs/thoughts/failure-patterns.md` is written and read in practice since 2026-09-26, and set out options for its future that the owner chooses between.
- **Problem framing**: The library's writer and reader are both prose steps, and nobody has measured whether either runs or pays off. Considered and discarded: "the writer is the only broken half, so automate it" (Q-223's original framing), because it assumes the read side works, and that is what this doc tests.
- **Project state**: research only, no workflow, skill or script change · answers Q-223 (owner: "revisit in more detail") · not blocked (cite: docs/working/briefs/2026-10-28-failure-pattern-use-review.md)
- **Task status**: complete (findings and options; the owner picks)

Window: 2026-09-26 (the day Q-074 opened, nine days after the 2026-09-17 backfill) to 2026-10-28, on `main` at f682ce93. Every count below can be re-run with the command next to it.

## Summary

- **Write side.** 358 `fix(...)` commits landed on main in the window, in 78 of the 116 first-parent merges. Two FP entries were written (FP-173, FP-174), both by one session on 2026-10-14. In a sample of 25 fix commits, about half (13) record a root cause a future search could plausibly want. The pr-prep advisory left a recorded trace once (that same session). No commit records a reason for skipping an entry, though pr-prep's checklist asks for one.
- **Read side.** 1 of the 12 RPI research docs from the window that still exist on disk has the required `Failure-pattern grep:` line (`research-build-loop-handoff.md`, 2026-10-02). In that one doc, the matched entries did shape the design: an allowlist gate, symlinks refused, renames not detected. 0 of the 11 research docs committed since 2026-10-15 (mostly build-loop research) have the line. One skill step and one workflow step tell an agent to read the library. No always-loaded file mentions it.
- **Overlap.** The library's main lesson, that 58 of 164 entries are one failure ("a check that reports success without having established it"), is now a rule in `docs/constraints.md` H2 and in CLAUDE.md's test rules. Those rules are enforced by bats cases and lints. The override log, decision log and review canon hold review dispositions and rules, not symptom-to-cause lines. The library's unique content is the symptom-keyed index of individual bugs.
- **Cost.** No always-loaded context. About 4.8 KB of RPI's 69 KB workflow and 2.4 KB of pr-prep's 47 KB workflow. Two writes in parallel collided on FP-173 (a renumber commit and a pre-resolved merge), and the roadmap's union-merge item names this file as one of two append-only files that conflict.

## What exists

- `docs/thoughts/failure-patterns.md` (316 lines, 32.5 KB, 167 entries FP-008..FP-174). Its header says to append from pr-prep and grep from research. 164 of the entries come from the 2026-09-17 backfill (ff313163). After that, FP-172 (2026-09-24, 9ab81b40) and FP-173/174 (2026-10-14) were added. The library is `Last verified: 2026-09-17`.
- **Writer**: the `workflows/pr-prep.md:51-77` Step 0 advisory. It counts `fix(...)` commits against new `FP-` lines and prints a warning. It says "Do not skip this step". The checklist item at :77 asks for an entry or a recorded skip reason.
- **Second writer (dormant)**: Step 5b of `scripts/self-improvement.sh:1844-1887` collects `Failure pattern:` notes from self-improvement retros. `git log --since=2026-09-26 --grep='harvest FP'` finds 0 commits. That loop made 4 commits in the window and none of them collected anything.
- **Reader**: the "Failure-pattern lookup" sub-step in `workflows/research-plan-implement.md:119-150`. It requires a literal `Failure-pattern grep:` line in every research doc. `workflows/task-decomposition.md:167,173` repeats the requirement. `workflows/codebase-onboarding.md:194` mentions the library in passing ("composes with").
- **Not covered by either step**: build loops. `scripts/build-loop.sh:1728` tells a loop to "Run research-plan-implement ..., then pr-prep's review-fix loop". The review-fix loop is pr-prep step 3, and the advisory is in Step 0, so no build loop is ever asked to run the advisory. A build loop is asked to do RPI research, which includes the grep.

## Write side

**Fix commits since 2026-09-26** [observed]:

```
git log --no-merges --since=2026-09-26 --format=%s main | rg -c '^fix(\(|:|!)'   # 358 (of 1029 non-merge commits)
```

These are spread over 78 of the 116 first-parent merges (at f682ce93) (each merge counted if its `^1..^2` range holds any `fix` subject). The largest scopes are `dev-cycle` (113), `build-loop` (71), `dev-cycle-read` (31) and `auto-approve` (18). Most of them are review-iteration fixes inside a unit, so the code they fix had not yet reached main ("U4a review iteration 1", "pass-26 check-mode fixes").

**Entries written**: 2 (FP-173 from f84a9dfa for Q-110; FP-174 for Q-145, first written as FP-173 in 3a8164d5 and renumbered in db325bcb). Both came from session `01VZuSDQi7…` on 2026-10-14. 3a8164d5's body says "pr-prep step 0 advisory for ba5d2d1d". Both entries were numbered FP-173, so one was renumbered to FP-174 (db325bcb), and the library had to be pre-resolved in a merge (c035f2e7, "pre-resolve the failure-patterns append"). Measured per merge: entries came from 2 of 78 merges that held fix commits.

**Where the advisory fired and what happened** [observed]: the only recorded firing is the 2026-10-14 session above, and there it produced entries. Nothing records any other firing. Searching commit messages in the window for `FP entry|no FP|FP:|failure pattern|skip vocabulary|library entry` finds nothing outside those commits. Of the committed code-review rubrics, only Q-110's mentions the library. The advisory prints to a terminal and leaves nothing behind unless an entry is written, so a skip is indistinguishable from not running. The 9 build-loop units that reached `handoff: ready` in the window were never asked to run it (see What exists).

**Sample** [observed; every 15th commit of `git log --no-merges --since=2026-09-26 --grep='^fix' -E main`, 26 picked, f50d436e dropped because its subject is `docs(questions)`, 25 classified]. "Yes" means the commit names a root cause with a symptom someone could grep for. "Partial" means there is a mechanism, but it is a review nit or a variant of a category the library already lists many times. "No" means wording, policy or ordering with no failure mechanism.

| # | Commit | Root cause a future search would want | Class |
|---|---|---|---|
| 1 | 72bbe36e exit-scan R6 pass 3 | quadratic duplicate check (23.7 s on 3,000 values) | partial |
| 2 | 464586d0 dev-cycle hand commits | policy change from user feedback | no |
| 3 | ca539c18 questions Q-180 i3 | substitution left a literal `$1`, cleanup deleted nothing; planted pager | yes |
| 4 | b973e678 auto-approve pass 1 | a test input that could not fail (vacuous) plus doc corrections | partial |
| 5 | 258f9ec4 docs B1-B4 | doc wording | no |
| 6 | b9f1d2d1 dev-cycle-read Q-145 i2 | find over a vanishing dir; **this unit wrote FP-174** | yes (entry) |
| 7 | 2cb03f23 cc-push Q-089 i1 | header overclaimed; tamper test did not assert "not run" | partial |
| 8 | 70d24331 build-loop U4a i1 | appending another question's ID applied its answer (guard misses subject) | yes |
| 9 | 575b9a86 build-loop U3d | a rewound marker released a live lock | partial |
| 10 | 83f75281 build-loop U3a1 | second pack copy shadows the checked object; awk `NR==FNR` over an empty file reads stdin | yes |
| 11 | 3908e37e build-loop final pass | host vs container path spellings dropped worktrees | yes |
| 12 | ae08688c dev-cycle-read U2b1a1 | `git log -G` ran a repo-local textconv driver | yes |
| 13 | e1654266 dev-cycle-read U2a3b | `~/` import resolved against wrong HOME; python3 on invalid UTF-8 | yes |
| 14 | ea9bf966 hooks | bidi/U+2028 chars spoof a displayed URL | yes |
| 15 | 8dc4880b dev-cycle-read U1a | hermeticity lint tokenizer misreads an apostrophe | yes |
| 16 | 934ecb41 dev-cycle | self-merge floor refused a loop's own Status line | no |
| 17 | 5085e64a dev-cycle pass-32 | wording, decision log row | no |
| 18 | b00c0574 dev-cycle pass-26 | an unclosed fence hid the next entry's heading (regression) | yes |
| 19 | d5d91215 dev-cycle pass-20 | write scope too wide, glob cost, locale | partial |
| 20 | 44d06b76 dev-cycle pass-12 | step order in skill prose | no |
| 21 | 5e8bfd9d dev-cycle final-pass-5 | policy decisions | no |
| 22 | 7b43db2a agents-md | import guard regex narrower than claimed | yes |
| 23 | 0b62e6e7 q087 D1-D3 | doc accuracy | no |
| 24 | 07db4c0c run-tests | killed run read as "nothing to re-run" (fail-open) | yes |
| 25 | 4435c738 live-verify-gate | gate regex fell out of step with the manifest | yes |

Tally: **13 yes** (1 with an entry), **5 partial**, **7 no**. If about half of the 358 commits are worth an entry, the window holds roughly 150-180 candidates, and 2 were written [inferred from a 25-commit sample, so the interval is wide]. Many "yes" rows repeat categories the library already counts heavily: `guard-misses-subject` (8, 22), `fail-open` (24), `align-the-contract`-style drift (25), path spelling (11). A new entry for one of these mostly adds another symptom string to an existing category.

## Read side

**Steps that tell an agent to read it**: the RPI research sub-step (`workflows/research-plan-implement.md:119-150`, plus the done-when line at :149), task-decomposition's synthesis checklist (:167, :173), and a passing mention in codebase-onboarding (:194). The `skills/research-plan-implement` router hands off to the workflow without naming the library. No always-loaded file (`~/.claude/CLAUDE.md`, `/workspace/CLAUDE.md`, AGENTS.md) mentions it.

**Research docs carrying the grep line** [observed]. Research docs are gitignored (`.gitignore:27`). Build loops force-add theirs.

- Committed research docs first added in the window: `research-build-loop-handoff.md` (2026-10-02) has the line, and **0 of the 11** added since 2026-10-15 do (Files read lists them).
- Ignored research docs on disk in the main checkout with an mtime in the window: 12, of which 1 has the line (the same build-loop-handoff doc). The 12 `.claude/wt-*` worktrees hold 106 research-doc copies under 17 names; apart from copies of the docs above, none carries the line (exit-scan-group1-remainder, questions-owner-routes, q168-exit-scan-remote-names lack it).
- Before the window: `research-copy-install-bare-host.md` (2026-09-23) has the line.

**Did a cited entry change a decision?** Yes, once. `research-build-loop-handoff.md:60-68` grepped `denylist|allowlist|symlink|reflection-escape|boundary-too-wide|rename|guard-misses-subject`, matched FP-033/041/043/056/146/167, and wrote three implications. All three show up in the build: the plan's D5 makes "the self-merge gate an allowlist" (`plan-build-loop-handoff.md:66`), the self-merge gate denies any entry whose mode is not 100644/100755, so a symlink (`120000`) is refused (`scripts/build-loop.sh:1195`), and the gate's diffs run with `--no-renames` (`build-loop.sh:1421,1830`, described at :366). How much the library changed the outcome is uncertain: allowlist over denylist is also standard security practice, and the repo's security critics would probably have raised it [inferred].

**Other reads in the window** [observed]:

- `docs/working/constraints-draft-2026-10-19.md:77,138` cites FP-116 and the 7 `remove-the-path` entries as sources for a constraint. This is the constraints-builder using the library as historical evidence.
- `docs/decisions/037-bare-host-copy-install.md:37` cites FP-161, and `devcontainer-config/install.sh:1340` cites FP-066. Both predate the window (2026-09-23).
- Code comments cite FP-080 (`test/skills/arithmetic-eval-gate.bats:25,58`) and FP-097 (`test/skills/generate-reports.bash:84`). These are "why this check exists" pointers.
- Every other `FP-NNN` citation in `docs/reviews/`, the cycle records and `override-log.md:844` is about writing FP-173/174 (reviews of those entries, their renumbering), not reading them.
- `scripts/questions.sh:5-8` cites the library's own pre-backfill emptiness ("0 entries against 104 eligible fix commits") as evidence that "an unenforced instruction does not execute". The window repeats that result.

## Overlap with other records

| Record | Carries the same lessons? | What the library adds |
|---|---|---|
| `docs/constraints.md` H2 ("fails closed and loudly") and S6 | Yes, for the largest group: `fail-open`, `guard-misses-subject` and `vacuous-assertion` are 58 of 164 entries (library :105-109), and H2's success line requires a bats case for each refusal path | the individual symptoms |
| `CLAUDE.md` Tests rules (stub strictness, no `skip` on presence) and `scripts/hermeticity-lint` | Yes, for the bats-specific shapes (bare `! grep`, stub too lax: log row 44) | the history behind each rule |
| `docs/decisions/log.md` (100 lines) and records | Rules adopted after bugs, with motive | not keyed by symptom |
| `docs/reviews/override-log.md` (890 lines) | Dispositions of review findings (accepted, downgraded). It is calibration data, not root causes | root cause and fix shape |
| `docs/working/canon-issue-ledger.md` | Known defects in the review-benchmark canon, to measure recall | covers this repo's bugs, not a benchmark set |
| Commit bodies of `fix(...)` commits | Yes, in full: the sample's bodies name cause and mechanism in prose (rows 3, 10, 12, 24 above) | a one-line, grep-friendly index pointing at those bodies |
| Hypothesis logs / `handoff-diagnosis-*` docs | None in the window (`docs/working/hypothesis-log.md` is gitignored; the only tracked handoff-diagnosis doc is archived from 2026-08) | — |

So the library is now an index over commit bodies plus a category tally. The tally's main conclusion has been promoted to an enforced constraint. The thing only the library offers is grepping `symptom:` tokens instead of `git log --grep`. In the one recorded use (build-loop-handoff), it was the category tokens (`guard-misses-subject`, `boundary-too-wide`) that found the hits, not the symptom tokens.

## Cost

- **Always-loaded**: 0 bytes. Neither CLAUDE.md nor AGENTS.md mentions the library.
- **Per RPI pass**: the lookup sub-step is about 4.8 KB (`research-plan-implement.md:119-150`) of a 69 KB workflow, and only matters when RPI is read. The grep output is usually a few lines. Reading the library header (the vocabulary tables, lines 1-143) would cost 9.2 KB, and the whole file 32.5 KB.
- **Per pr-prep pass**: the advisory is about 2.4 KB (`pr-prep.md:51-77`) of a 47 KB workflow, plus one `git log` and one `git diff`.
- **Merge friction**: the file is append-only and keeps a sequence number, so parallel writers collide. This happened on its only parallel write (FP-173 twice → db325bcb, c035f2e7), and the roadmap's "Union-merge the append-only review logs" item lists it.
- **Owner attention**: Q-074 (a watch), Q-223 (a judgment), a roadmap line, and this unit.

## Invariants

- Entries are cited by stable ID from code comments (FP-066, FP-080, FP-097) and decision 037 (FP-161) [observed]. Whatever the owner picks, those IDs must stay resolvable. Freezing or archiving the file in place keeps them resolvable, and deleting it does not.
- `scripts/questions.sh:5-8` quotes the library as evidence. Moving the file needs that comment updated.

## Prior art

- Q-018's 2026-09-17 backfill (ff313163) is the only writer that has produced at scale: 164 entries from 105 fix commits in one pass. It was a batch harvest from commit bodies, not a per-merge step.
- Self-improvement Step 5b is a scripted batch writer for the same file. It sits dormant because that loop seldom runs.
- Decision 013 kept the library when bug-diagnosis was removed and moved its writer to pr-prep. Decision 020 / log row 20 had the SI loop use it.

## Gotchas

- Failure-pattern grep: FP-019, FP-079 (`grep -inE 'advisory|unenforced|harvest|append-only'`). Neither bears on this question: FP-079 is a harvest pipeline that aborted on an unguarded grep, and FP-019 is an unrelated firewall ordering bug.
- "Fix commit" overstates bugs. Most of the window's `fix(...)` commits are review-iteration fixes to code that never shipped, so `fix` count is not a good denominator. The per-merge figure (2 of 78) is fairer.
- Research docs are gitignored and worktrees are removed, so the read-side count only covers docs that survive (committed, or on disk in the main checkout). The read rate could be higher than 1 in 12, but nothing that survived shows it.

## Options for the owner

Divergent design, seeded with `docs/constraints.md`, was used to shape these options and not to choose between them. Candidates considered: keep as is; automate a per-merge writer (Q-223's [1]); batch harvest on a schedule; freeze the library and drop both steps; merge the lessons into constraints or CLAUDE.md and delete the file; make the RPI grep a script so it always runs. Two were folded into others: deleting the file breaks cited IDs (Invariants), so it became "freeze", and a scripted RPI grep only pays if entries keep coming, so it became part of option [2]. The surviving options differ mainly in who keeps writing.

Constraint notes. S6 says a step that cannot run is "re-implemented or removed, never left listed as optional". Today that applies to the advisory for build loops, which are never asked to run it. S2 rules out a new mandatory per-pass dispatch, so a per-merge writer has to be a script. S4 says mechanical steps belong in tested scripts. S5 says the status quo and deciding against a feature are valid outcomes.

| Option | What changes | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep as is** | Nothing. The Q-074 watch re-arms (for example, to 2026-11-28). | None now. Another watch firing and judgment in a month. | The advisory stays unrun in build loops (an S6 gap), the RPI grep keeps being skipped, and the same finding returns. Nothing breaks. |
| **[2] Batch harvest, keep the read** | Drop pr-prep's per-branch advisory and its "do not skip" line. A scripted pass (a dev-cycle step or a monthly unit) drafts entries from the commit bodies of merged fix units, as the 09-17 backfill did, and lands them in one commit, so parallel writers never collide. The RPI grep stays and could become a script call. | One merge review of the harvest script. One harvest unit to review per period. | Agent-drafted entries could be noisy or mislabeled and could mislead the grep. The cost stays even if reads stay at about 1 in 12 research docs, so you pay a writer for an index that is rarely read. |
| **[3] Freeze and retire the steps** | Mark the library frozen at FP-174 (a header line), keep it greppable for cited IDs, and remove the pr-prep advisory and the RPI/task-decomposition grep requirement. New lessons go where they already land: constraints, CLAUDE.md test rules, decision log, and fix commit bodies (searchable with `git log --grep`). | One small doc-edit merge. | Lose a quick symptom-keyed lookup for new bugs. A recurring bug shape might go unnoticed until a reviewer or a constraint catches it. That is the one case (build-loop handoff) where it helped. |
| **[4] Read side only, scripted** | Freeze writing as in [3], but turn the RPI lookup into one script call that greps both the frozen library and `git log --grep` over fix commit bodies by keyword. The read keeps working on new bugs with no writer to maintain. | One merge review of a small tested script, plus RPI and task-decomposition text edits. | A small script that adds little if research seldom runs it either, and `git log --grep` over prose is noisier than hyphenated tokens. |

- **Interim**: [1] stays in effect until you answer, as the brief requires.
- **If the answer differs**: each option is a separate small unit. None of them needs this doc redone.

## Files read

Last verified: 2026-10-28

docs/working/briefs/2026-10-28-failure-pattern-use-review.md
docs/thoughts/failure-patterns.md
docs/thoughts/
docs/constraints.md
workflows/pr-prep.md
workflows/research-plan-implement.md
workflows/task-decomposition.md
workflows/codebase-onboarding.md
skills/dev-cycle/SKILL.md
skills/pr-prep/SKILL.md
scripts/build-loop.sh
scripts/self-improvement.sh
scripts/questions.sh
scripts/lib/dev-cycle-read.sh
docs/roadmap.md
docs/working/questions.md
docs/working/questions-archive.md
docs/decisions/log.md
docs/decisions/013-failure-pattern-library-after-bug-diagnosis-removal.md
docs/decisions/020-self-improvement-loop-dogfoods-repo-process.md
docs/decisions/037-bare-host-copy-install.md
docs/reviews/override-log.md
docs/reviews/code-fact-check-report-2026-10-15-0357.md
docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-final-r3.md
docs/reviews/api-consistency-review-2026-10-02-digest-pass21.md
docs/working/canon-issue-ledger.md
docs/working/constraints-draft-2026-10-19.md
docs/working/cycles/cycle-2026-10-14.md
docs/working/cycles/cycle-2026-10-20.md
docs/working/research-build-loop-handoff.md
docs/working/plan-build-loop-handoff.md
docs/working/research-*.md (committed: copy-install-bare-host, build-loop-handoff, branch-verify-without-install, q096-exit-scan-insteadof-target, 2026-10-17-cc-isolated-profile-names, 2026-10-17-claude-md-import-guard, 2026-10-17-q146-si-script-commits, 2026-10-20-cc-verify-host-tool, 2026-10-20-decision-015-amendment, 2026-10-25-exit-scan-r6-hookspath, 2026-10-25-log-row-73-trigger, 2026-10-25-widen-fix-drift-check, 2026-10-28-interview-readme-drift)
devcontainer-config/install.sh
test/skills/arithmetic-eval-gate.bats
test/skills/generate-reports.bash
.gitignore
CLAUDE.md
