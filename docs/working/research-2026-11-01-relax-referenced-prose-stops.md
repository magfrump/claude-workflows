# Research: narrow the stops and over-wide rules in the workflows and skills the dev cycle uses

- **Goal**: The workflows, skills and global instructions the dev cycle and its build loops run stop or wait on the owner only where a specific, in-scope failure would follow, and their security review is scoped to S1 where a project's constraints say so.
- **Problem framing**: Prose written for a present owner (stop and wait, ask the user) is read unchanged by unattended runs, so an /away session or build loop either hangs on a question nobody answers or files a blocking entry for a choice that had a safe default. Considered and discarded: "the stops are right and the loops should ignore them"; that is today's state (the loop prompt waives some of them), and it leaves the same rule stated at two strengths in two files (FP-093).
- **Project state**: Prose edits across `global-instructions/CLAUDE.md`, `workflows/`, `skills/` and `guides/` · unit 2 of the 2026-11-01 restriction audit (`docs/working/research-2026-11-01-restriction-audit.md`, Units) · not blocked (cite: 269cef09 | docs/relax-referenced-prose-stops | docs/working/briefs/2026-11-01-relax-referenced-prose-stops.md)
- **Task status**: complete (implemented; review-fix loop run)

Failure-pattern grep: FP-030, FP-051, FP-052, FP-055, FP-073, FP-084, FP-085, FP-093, FP-113, FP-126, FP-127, FP-138, FP-162, FP-174

Command: `grep -inE 'instruction-drift|contradict|stop-and-wait|approval|waiver|hostile|overbroad-guard' docs/failure-patterns.md`. The one that bears on this work is **FP-093** (three instruction surfaces still stated a rule unconditionally after it became conditional; fix: align every surface). Its guard here: for each rule changed, every file restating it was found by `rg` and changed in the same commit (table below, column "Other surfaces"). FP-085 and FP-126 (instruction drift) are the same family. The rest are guard-scope bugs in scripts and do not apply to prose.

## What exists

Each row was re-read against the text at 269cef09 [observed]. The audit's line numbers held within a line or two (corrected below where they did not).

| Row | Where | Text today | Verdict after re-check | Other surfaces restating it |
|---|---|---|---|---|
| K108 | `global-instructions/CLAUDE.md:223-234, 291` | "Still require user approval (regardless of mode)" lists "Decisions where guessing wrong would waste significant work"; "/away: Stop and wait for the user when" tests fail with no obvious fix, merge conflicts arise, requirements are ambiguous and costly, anything irreversible | NARROW as briefed. The line 226 bar (any mode) and the line 231 bar (/away) are the same judgment at two strengths. In-scope failures that stay a stop: irreversible operations (data loss), and a conflict resolution that would drop either side's content (data loss). Failing tests and ambiguity have a safe alternative (defer the task, file the question, keep working), which S10 prefers | line 234 and 291 refer to "the stop-and-wait bar"; both keep working with the narrowed list |
| K55 | `workflows/research-plan-implement.md:115-117, 364-386` | "The gate on implementation is firm"; step 4 "This is the hard gate ... implementation does not begin until the user has reviewed the plan" | NARROW as briefed. Global CLAUDE.md:202 already lists the plan gate under /active only; in /away the plan is recorded for async review. No in-scope failure: an unreviewed plan in /away is reviewed at the PR or merge, and a wrong plan is cheap to revert (S8) | `skills/research-plan-implement/SKILL.md:15` ("Its hard gate is plan approval"); `patterns/requesting-user-input.md:89,142` describe the prompt when it is asked, so they stay true |
| K94 | `skills/code-review/SKILL.md:662-673` | Fact-Check Gate asks the user (continue / fix first / skip critics) unless `--no-gate` | NARROW, but **default Continue, not Fix first** (deviation from the brief; see D3). Only the terminal or a standalone pass reaches the gate (`--loop-pass` implies `--no-gate`), and K95 says the terminal pass never skips critics; Fix first would skip them | `--loop-pass` flag text (SKILL.md:246-251) is unchanged and stays consistent |
| K101 | `skills/security-reviewer/SKILL.md:470-475` | Floor rule: a named mechanism in a reachable environment is never below Medium; only "attacker already controls the host" is excluded | NARROW as briefed, conditional on the project's own constraints (see D4): this skill runs in every project, and a hostile contributor is in scope for most of them | Where a review brief is built from it: `skills/code-review/SKILL.md` critic dispatch item 4 (the skill file is pasted verbatim, so the rule travels; item 4 adds the constraints doc's scope lines) |
| K61 | `workflows/research-plan-implement.md:235, 351` | Enforcement-file plans list "every bypass or attack family" | NARROW as briefed: the enumeration is scoped to the project's threat model; out-of-scope families are named as out of scope, not designed against. Q-076 is the evidence, and its growth came from families S1 now puts out of scope [inferred from the audit's K61 row] | checklist line 351 |
| K37 | `workflows/review-fix-loop.md:53, 55-63`; `workflows/pr-prep.md:244` | Past ~800 lines the loop stops until the user answers a waiver, in /away too; "the agent does not split the unit itself" | NARROW as briefed. The re-check and the 800 limit have evidence (Q-104, Q-160) and stay. The no-split-in-/away reading is Q-160's, not the owner's (log row 62 says so). Splitting is what the entry gate (pr-prep 1a) and the early split trigger already do in /away; a split is one revert away | early split trigger (review-fix-loop.md:53, "where the user decides"); pr-prep.md:244 |
| K87 | `skills/constraints-builder/SKILL.md:245-247` | A success check that runs repo code goes in the draft as "author to run. Never execute it yourself" | NARROW as briefed. The skill's scope is sole-author repos only (SKILL.md:31-37, K83), where running the repo's own tests is what every build loop does. Keep: never in a shared, forked or third-party repo (already a stop), run under `timeout` and inside the sandbox (H3) | none (`rg "author to run"` hits only this file and the drafts it writes) |
| K68 | `workflows/research-plan-implement.md:203, 448, 458` | 2x overall or +50% per phase: pause, checkpoint, "then stop and either narrow scope, start a fresh session, or escalate"; "Do not proceed silently" | NARROW as briefed. The estimates are rough (line 203: "Precision is not the point"). Keep the checkpoint and the record; stop only when the overrun comes with scope growth past the plan | line 203, checklist line 458 |
| K48 | `workflows/review-fix-loop.md:141-170` | On a re-fire: flag, deeper read, surface to the user; "The user decides what to do" | NARROW as briefed. /active: unchanged. /away and loops: apply the deeper fix (or accept and document when the structural fix is out of scope), recording the flag | "Relationship to the hard cap" paragraph says "surfaces a pivot recommendation to the user"; adjusted |
| K62 | `workflows/research-plan-implement.md:256-260, 357` | A Rollback that is only `git revert` is disallowed | NARROW as briefed. A rollback that names the commit range and says why the change is revert-clean (no schema, data, external or installed state) is change-specific; S8 makes it the normal case here. Generic "revert and redeploy" stays disallowed | checklist line 357 |
| K105 (text) | `guides/convention-changes.md:51-57` | "files one `you: terminal` entry per pending migration" | NARROW as briefed, matching `skills/dev-cycle/SKILL.md` step 1b (already "two or more filed this iteration: one paste, in the first") and global CLAUDE.md ("Several terminal entries collect into a single paste"). The guide now points at step 1b instead of restating it (S3). The cycle running the remedy itself stays a later unit | `skills/dev-cycle/SKILL.md:460-475` (out of scope, already right) |

Rows kept after all: none. Every row's in-scope failure (irreversibility, dropped conflict content, the 800 limit, the sole-author scope, scope growth) is kept as the remaining stop.

### Cross-file contradictions (Appendix C list)

| # | In these files? | Resolution |
|---|---|---|
| 1 K24 vs DD Path C | no (`scripts/build-loop.sh`, unit 4) | out of scope |
| 2 K94 | yes | gate defaults to Continue when no one is there to ask |
| 3 K55 | yes | RPI and its router say /active only, as global CLAUDE.md does |
| 4 K105 vs one paste | yes | guide points at dev-cycle step 1b, which collects one paste |
| 5 K62 vs S8 | yes | a revert-clean change may name its revert range |
| 6 K22 + K25 | no (floor is in the lib; log row 78 already took `docs/thoughts/` off it and moved the library) | out of scope, and resolved by row 78 |
| 7 K108 226 vs 231 | yes | line 226 removed; the narrowed /away list is the one statement |

## Invariants

- Always-loaded text (`global-instructions/CLAUDE.md`) must not grow by more than ~30 lines (S2); expected net shrink.
- `global-instructions/CLAUDE.md` holds no `@` import (`test/agents-gemini-sync.bats`).
- Headings tests anchor on stay: `### Fact-Check Gate` (`test/skills/code-review-factcheck-replication.bats:30,137`), the `Size re-check` and `Early split trigger` anchors linked from pr-prep, `## Rollback`, `### 4. Annotate`.
- /active behaviour is unchanged everywhere (the owner opts into control by switching mode, K106).
- Stops that stay: irreversible or destructive operations, conflict resolution that drops content, the 800-line limit when no split exists, the iteration-3 cap gate, constraints-builder's sole-author scope.

## Prior art

- `workflows/pr-prep.md:96` (size gate) and `review-fix-loop.md:51` (early split): /away splits without asking and records the split as an interim. K37 reuses that wording.
- `workflows/divergent-design.md` Path C: proceed on a tentative pick, file the question asynchronously. K108's "defer, file, continue" is the same move.
- Memory "Hostile author out of scope" and S1: the scope line K101 adds.

## Gotchas

- `security-reviewer` and `research-plan-implement` ship to every project. An unconditional S1 rule there would drop hostile-contributor findings in repos where those are real. The scope is keyed to the project's constraints doc (D4).
- Fix first on the terminal pass would contradict K95 (terminal pass never short-circuits), a new FP-093-style contradiction (D3).

## Design choices (divergent design, seeded with docs/constraints.md and the brief)

Most rows are prescribed by the brief and have one answer. Four had real alternatives.

- **D1, K108 shape.** (a) delete line 226 and narrow the /away list; (b) keep 226 but restrict it to irreversible decisions; (c) move the whole list into the questions section. (b) restates the "irreversible" line above it (S3); (c) moves always-loaded text without shrinking it. **(a), Path A.**
- **D2, K37 when no split exists.** (a) wait for a waiver only then; (b) continue past 800 and file a waiver; (c) abandon. (b) removes a limit with evidence (Q-104); (c) loses work. **(a), Path A**, as briefed.
- **D3, K94 default.** (a) Fix first (brief); (b) Continue; (c) Fix first but run the security critic. (a) skips critics on the terminal pass, which K95 forbids, and a standalone review then needs a second full pass; (c) re-implements part of the short-circuit's mechanic 7 (S3). (b) runs the full panel, so it is recall-neutral (S7), and the high-confidence Incorrect lands in the rubric as Must Fix, so the loop still fixes it before merge. **(b), Path A.** This departs from the brief's wording, recorded here and in the commit body.
- **D4, K101 scope.** (a) unconditional S1 text in security-reviewer; (b) conditional on the project's constraints doc, with code-review passing those lines; (c) only in code-review's dispatch brief. (a) breaks other projects; (c) misses a direct `/security-reviewer` run. **(b), Path A.** Review iteration 1 added: the threat model is read from the target branch the change merges into, never a commit on the branch (a branch could otherwise scope out its own attack in a project where hostile contributors are in scope), and a hard line such as H1 stays in scope whatever the attacker.

## Plan

One commit per file group, docs only (no code, no tests change; the size gate counts 0 code lines outside `docs/`... prose under `workflows/`, `skills/`, `guides/` counts, expected well under 400).

1. `global-instructions/CLAUDE.md`: K108.
2. RPI workflow + router: K55, K61, K62, K68.
3. `review-fix-loop.md` + `pr-prep.md`: K37, K48.
4. `code-review` + `security-reviewer`: K94, K101.
5. `constraints-builder`: K87. `guides/convention-changes.md`: K105.
6. `docs/decisions/log.md` row 79.
7. Full health check to a file; review-fix loop; brief Status open → done last.

Test specification: no behaviour in scripts changes. Verification is the existing suite (`scripts/health-check.sh`, including `test/agents-gemini-sync.bats`, `test/skills/code-review-factcheck-replication.bats`), plus `rg` checks that no surface still states a changed rule at its old strength (FP-093).

Failure modes considered: (1) a surface still restates an old rule (FP-093) → guard: the "Other surfaces" column, re-grepped after editing; (2) a test anchored on a heading breaks → guard: headings kept, full health check; (3) a scope rule meant for this repo leaks into every project → guard: D4's conditional. `/pre-mortem`: not triggered (no enforcement file, docs only, under 500 lines). `/architecture-review`: not triggered (prose only, no module boundaries).

## Review

Iteration 1: a fact-check subagent (claims against the cited files) and a contradiction and scope critic. Fixed: two remaining /away contradictions (RPI line 108, the cap gate's `split` default), the H1 carve-out and base-read for the threat-model rule, no unattended Accept-and-document of a Must Fix, the conflict-stop wording, the split keeping the iteration counter, the re-install step in revert-clean rollbacks, constraints-builder's parser exception and scratch-copy test runs, and four research-doc line numbers. Declined C7, C8, C9 with override-log rows.

Failure-pattern skip: the branch has no fix(...) commits; its review fixes are prose alignments of the FP-093 shape already recorded.

## Rollback

`git revert` of this branch's merge commit restores every file: the change is prose only, with no schema, data, installed or external state, so it is revert-clean (the K62 rule this change adds). The installed copy (`~/.claude/`) picks the old text up at the next install.

## Files read

Last verified: 2026-11-01

docs/working/briefs/2026-11-01-relax-referenced-prose-stops.md
docs/working/research-2026-11-01-restriction-audit.md
docs/constraints.md
docs/failure-patterns.md
docs/decisions/log.md
global-instructions/CLAUDE.md
workflows/research-plan-implement.md
workflows/review-fix-loop.md
workflows/pr-prep.md
skills/research-plan-implement/SKILL.md
skills/code-review/SKILL.md
skills/security-reviewer/SKILL.md
skills/constraints-builder/SKILL.md
skills/dev-cycle/SKILL.md
guides/convention-changes.md
patterns/requesting-user-input.md
patterns/orchestrated-review.md
test/agents-gemini-sync.bats
test/skills/code-review-factcheck-replication.bats
hooks/live-verify-gate.sh
