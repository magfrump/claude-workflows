# Plan: build-loop handoff (revision 4)

- **Goal**: The dev cycle runs as an orchestrator loop. It dispatches build briefs to autonomous build loops, collects their results, and merges what the gate allows. The state and the merge checks live in a small tested script (`scripts/build-loop.sh`) rather than in prose.
- **Project state**: delivers the build-loop handoff (script, lib, tests, skill and doc changes) · roadmap In flight item; Q-103 waits on it · blocked on approval of this revision (cite: docs/working/briefs/2026-10-02-build-loop-handoff.md, docs/working/handoff-build-loop-handoff.md)
- **Task status**: in progress (revision 4, 2026-10-04: you walked through D1–D14 and approved them with the changes below; revision 4 folds those changes in)

Research: docs/working/research-build-loop-handoff.md
Design conversation (2026-10-02/03, your 12 answers): docs/working/handoff-build-loop-handoff.md
Plan-time reviews: `docs/reviews/pre-mortem-build-loop-handoff.md` (rev 2), `docs/reviews/pre-mortem-build-loop-handoff-rev3.md` (this revision: 5 narratives, 3 reproduced experiments, F38–F53), `docs/reviews/architecture-review-build-loop-handoff.md`, `docs/reviews/test-strategy-build-loop-handoff.md`

## What changed from revision 2

| Kept | Changed | Dropped |
|---|---|---|
| D5 allowlist gate over the `check_fix` floor; D7 merge-tree → diff-tree rules → commit-tree → CAS, hardened git; the lib extraction; F1–F31; `--status`, `--check`, `--merge`, `--start`, `--prompt` | Who starts loops (the orchestrator, D1); markers (`ready`, `blocked`, `stopped`; D3); who runs the gate (the orchestrator, from main's commit, D6); review handoff (a PR, else one merge entry; D4); answers read from main's commit (D8); slots (D9); the orchestrator's own isolation (D13) | You start each loop; plan approval in loops; early keep-or-drop entries; the 14-day idle timer; the user-run merge command; the bless prerequisite for the gate; the brief's "the user reads each brief" criterion (you overrode it on 2026-10-03; recorded as a decision-log row, D10) |

**Revision 4 (your walk-through of D1–D14, 2026-10-04):**

| D | Change |
|---|---|
| D2 | Loops ask by divergent-design's criterion: Path A (one option dominates) → proceed; no clear winner, or no surviving option → `blocked`. A repo with no `docs/constraints.md` gets no dispatch. A drift check samples Path A decisions in the spot-check |
| D4 | Future direction only: on a refused self-merge, send it back to the loop once before asking you |
| D5 | The floor narrows to what takes effect on merge with no later review. Scripts and skills are self-mergeable within `Paths:`. Gate code needs a `merge-gate-` review. Per-project `Self-merge never:`. In this repo, a release is the real gate for code |
| D12 | C5 answered: a full cycle every iteration for now; revisit the light pass once costs are visible |

Two places where this revision departs from the handoff's v2 flow, both for safety:

1. **The orchestrator runs the gate, not the loop.** The handoff had the loop run `--merge` under self-merge. Whoever runs the gate chooses which bytes run, and a loop can run a copy it has edited (rev 2 pre-mortem, narrative 3). The loop still runs `--check` itself as an advisory dry run. Self-merge stays hands-off: the orchestrator merges as soon as the loop reports `ready`.
2. **Step order: collect, then write briefs, then land, then dispatch.** The v2 flowchart has dispatch (7) before land (9). Loops read their brief from main's commit, so a brief must land before its loop starts. Collecting first also frees slots before they are filled.

## What the gate can and cannot do (read first)

Loops run as your uid, with a shell, in worktrees that share `/workspace/.git`. No script can contain a loop that turns hostile with its shell. It could run plain `git merge` or `git push`, write any working tree under `/workspace`, or plant `.git` state. What this design does is make the **honest path** safe and checkable, and make the commonest honest slip, a git command run in the wrong directory, fail loudly instead of landing (D13).

Content reaches main only through a gate that decides from main's committed state and the exact merge result, and that gate never runs bytes a loop could have changed (D6). Each iteration checks that main moved only by the orchestrator's own merges, the gate's merges and answer-only commits (D13). With no human reading briefs (D10), the gate and your review of `ready` work are the checks on what lands. The residual families are stated plainly in Q-103, so the policy choice is made knowing them.

## Decisions for you to confirm at approval

- **D1. The orchestrator starts loops.** For each brief that has landed, it runs `build-loop.sh --start BRIEF`. That creates the branch and a worktree at `.claude/wt-<stem>` from main's commit, locks the worktree (`git worktree lock --reason "<session> <UTC time>"`), increments the brief's `Dispatched:` count, and prints the loop prompt. The orchestrator then launches a background subagent (Agent tool, no isolation; memory `agent-worktrees-stall-and-stale-base`) with that prompt.
  - Loops live as long as the orchestrator session. After a restart, a branch with no marker is re-dispatched with `--prompt BRIEF`, which refuses a worktree still locked by a live session unless `--steal` is given and the tip is over 2 hours old.
  - A live loop with no new commit across 4 consecutive fallback wakeups (about 2 hours) is stopped (TaskStop) and marked `stopped: stalled`.
  - `Dispatched:` caps a brief at 4 dispatches in total (`--start` plus `--prompt`), whatever its commits, after which it is `stopped: dispatch cap`. The count lives on the brief, read from main, so a restart does not reset it (F45).
- **D2. Loops run RPI with no plan-approval gate, and ask by divergent-design's criterion.**
  - **Seeding.** Every loop prompt carries `docs/constraints.md` from main's commit. Every design choice inside a loop runs DD seeded with those constraints plus the brief's own.
  - **Path A** (one option dominates at over 80% confidence): the loop decides and continues.
  - **No clear winner:** the async form of DD's Path B. The loop ends with `handoff: blocked`, with DD's scorecard, the options and the axis of disagreement in the body. The orchestrator files it as `you: judgment`, the task is deferred and its slot freed. On your answer the loop resumes with your pick.
  - **No option survives** the hard constraints even after DD's Double Diamond reframe: `blocked`, framed as "these constraints contradict", not as a choice.
  - **A fact only you have:** `blocked`.
  - **A loop never waits.**
  - **Constraints doc required.** `docs/constraints.md` holds hard constraints with IDs (`H1`…) and DD's `success:` lines, plus soft constraints (`S1`…). Without it, or with no hard constraint in it, the orchestrator dispatches nothing in that repo and files one `you: judgment` entry saying so; the rest of the cycle runs. Creating the doc is your work: a roadmap item, "a process for writing a repo's constraints doc", is filed as owner-attention (U5).
  - **Drift check.** Step 4's spot-check reads one Path A decision from each sampled build-loop merge (the DD record in the loop's research doc, which the loop must force-add as one of its own files). Two findings count: a soft constraint that pruned an option, and a constraint not in `docs/constraints.md` that decided the pick. A finding is a deep-audit trigger. The audit gains a "constraints and project guidance still match intent" dimension, which samples Path A records more widely and asks you, per constraint, to promote it, keep it soft or drop it.
- **D3. Three markers**, each an empty single-parent commit at the branch tip, at least one commit ahead of main:
  - `handoff: ready`: pr-prep's review-fix loop is clean, and the final change sets the brief's Status line to `done`.
  - `handoff: blocked`: the body holds the question (D2: DD's scorecard, options and axis, or the contradicting constraints, or the missing fact) as **plain prose plus an options table**. There are no `**Needs:**`, `**Status:**`, `**Answer…`, `Q-NNN:` or heading lines; the orchestrator adds all of those (F41).
  - `handoff: stopped: REASON`: a stop condition was hit (adding a dependency, a symlink, an edit the rules forbid, or a refused `--check` it cannot fix within `Paths:`).
- **D4. Collect results** (skill step 7), per brief, by `--status`:
  - `done` on main → Done (today's check 1, unchanged).
  - `ready` with the stricter policy `self-merge` → the orchestrator runs the gate (D6) with `--merge --expect TIP`. If it refuses, the item falls through to review, with the refusal quoted in the entry. (Future direction, not in this unit: send a refusal back to the loop once before asking you.)
  - `ready` under `review` → where `docs/dev-cycle.md` says `Review handoff: pull request`, push the branch and open a draft PR. Only the orchestrator does this, never the loop or the script. Otherwise it files one merge entry, `### Q-NNN · merge-<stem>-<first 12 of TIP>`. The entry body is `--check`'s output: the full 40-hex TIP, every changed path, and each S-rule refusal flagged (for example "changes CLAUDE.md") (F48). The options are **[1] merge**, **[2] drop** and **[3] changes needed** (your note goes back to the loop).
    - Answer [1] → `--merge BRIEF --expect TIP --approved Q-NNN`. The script checks, on main's commit, that Q-NNN is ANSWERED with option 1 and that its slug names this brief and TIP's prefix.
    - A change to the gate's own files (`scripts/{build-loop,dev-cycle,questions}.sh`, `scripts/lib/`, `skills/dev-cycle/`) gets its own slug, `merge-gate-…`. Plain `--approved` refuses such a change (F52).
    - Answer [3] → re-dispatch with the note.
  - `blocked` → `--marker BRIEF` prints the body with every line prefixed `> ` (F41). The orchestrator files each question as an entry with its own header and the quoted body, writes `Asked: Q-NNN@MARKER-SHA, …` on the brief, and frees the slot. Once every Asked ID is answered (D8), the brief goes back in the queue on its existing branch, and the loop is re-dispatched with `--prompt` plus the answers.
  - `stopped` → one entry with **[1] re-dispatch** and **[2] drop**, quoting the reason.
  - An entry is filed once per marker SHA (`Asked: …@SHA`), so a marker is never re-asked (rev 2's L2). Dispatch waits until the land that recorded it is on main (D13).
- **D5. The self-merge gate is an allowlist over a narrow floor.**
  - **Allowlist.** A path may change only if the brief's `Paths:` lists it, or it is one of the loop's own files keyed on the full brief stem. The cycle writes `Paths:` as wide as the task needs, code included.
  - **The floor** refuses, even when `Paths:` lists them, only paths that **take effect on merge with no later review**:
    1. files sessions load straight from the checkout: instruction files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `SKILL.md`, any case, any directory) and their `@`-imports;
    2. any `.`-prefixed component. That covers the files you agreed on, `.claude/`, `.gitattributes` and `.gitmodules`, plus others that run on their own, such as `.envrc` (direnv runs it on `cd`), `.npmrc`, `.devcontainer/` and `.github/`. Revision 4 keeps the whole dotfile family rather than listing it;
    3. the gate's own code (`scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/questions.sh`, `scripts/lib/dev-cycle-read.sh`). D6 runs main's copy, so it is live at the next merge. Self-merge refuses it, and it falls to review under a `merge-gate-` entry (your pick [1]);
    4. files the cycle and later loops read as truth on their next run: the cycle-owned files (also N-denied), `docs/constraints.md`, `docs/decisions/`, `docs/thoughts/`, `docs/human-author/` and other briefs' working docs;
    5. symlinks and gitlinks. The executable bit is allowed.
  - **Per project.** `docs/dev-cycle.md` may add `Self-merge never: GLOB …` (pathform globs, one line, read from main's commit). A malformed line turns self-merge off for that repo (`--settings` says why).
  - **In this repo.** Code such as scripts, skills, hooks and guides reaches running sessions only through a release you cut (the image copies under `/opt/claude-workflows`). So the release is the real gate, and the release entry lists every commit and changed path since the image's `.manifest` commit. The exception is `workflows/`: by the global instruction "this repo's own file when working inside claude-workflows", every later loop here reads the workflows from its own checkout, so they take effect on merge. The interim is `Self-merge never: workflows/` in this repo's settings, asked as an entry in U5.
  - **Future direction:** whether the fixed floor itself should come from per-project settings.
- **D6. The gate runs from main's commit, run by the orchestrator, through a hardened snippet.** The snippet is inline in the installed SKILL.md, which is the root-owned image copy. It never trusts a file the uid can write:
  - It runs only after `GIT_NO_REPLACE_OBJECTS=1 git for-each-ref refs/replace/` prints nothing and `info/grafts` is absent (F38).
  - It extracts `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/questions.sh` and `scripts/lib/dev-cycle-read.sh` from `MAIN_SHA` with `GIT_NO_REPLACE_OBJECTS=1 git --no-optional-locks -c core.hooksPath=/dev/null cat-file blob`. They go into a fresh `mktemp -d` with the same `scripts/` and `scripts/lib/` layout (F40).
  - It checks each file's `hash-object` against its `ls-tree MAIN_SHA` id immediately before running it.
  - It uses main's copy only when main's first-parent root commit is claude-workflows' (`640cf007…`, written into the snippet). In any other repo it runs `/opt/claude-workflows/scripts/build-loop.sh` by absolute path, after checking that the file and its directory are root-owned and not writable by the uid. It never goes through the uid-owned `~/.claude/scripts` symlink (F39).
  - The digest runs the same way, so in this repo the orchestrator never runs working-tree scripts (F34).
  - A loop's own `--check` runs are advisory and never move main.
- **D7. Merges are computed, not checked out** (unchanged), with one fix: "clean" means no tracked changes, and the merge refuses only when an untracked file collides with a path the merge adds (F50). The steps are: `merge-tree --write-tree MAIN TIP`, every rule on `diff-tree -r --no-renames --raw -z MAIN R`, then `commit-tree R -p MAIN -p TIP` with a `Build-loop-gate: <stem>` trailer, and a CAS on main. All git calls are hardened, with the state gate from `install.sh`. When main is checked out in a worktree, that worktree must be on main, clean, and not mid rebase, bisect or merge; then a hardened `merge --ff-only` runs.
- **D8. Answers that unblock autonomous work are read from main's commit.** `--check-answer` reads `MAIN_SHA:docs/working/questions{,-archive}.md`, not the working tree, because a loop can write any working tree under `/workspace` (F28). An answer reaches main in one of two ways:
  - you commit it yourself;
  - you tell the orchestrator in its session, and it commits that answer.

  The orchestrator never commits an answer it did not receive from you in-session. `--cycle-diff` enforces this (D13). The wait message lists working-tree-only answers as "not applied: tell me, or commit it yourself"; it never offers to commit them (F42).
- **D9. Slots cap the running loops.** `Build-loop slots: N` (1–9) in `docs/dev-cycle.md`; anything else, or no line, means 3. Only a live dispatched loop holds a slot. A `blocked`, `ready`-awaiting-review or `stopped` item holds none (C2 default).
- **D10. Briefs are not read by you before dispatch, and loops have no plan gate.** You overrode the brief's criterion on 2026-10-03 ("the point is to work through all threads until they are blocked on questions"). The brief asks for this decision as a questions entry. It is recorded instead as decision-log row 70, quoting your answers 1, 5, 8 and 9, because you made it in conversation. If you want an entry anyway, U5 files it pre-answered.
- **D11. The orchestrator is the only writer of `questions.md`** (C1 default). Loops carry questions in their `blocked` marker. `--marker` refuses a body line that starts (after blanks, `>` and list markers) with `#`, `**Needs:**`, `**Status:**`, `**Answer` or `Q-` and a digit. It scrubs controls and bidi, caps the body at 100 lines of 300 bytes, and prefixes every line with `> `. Both questions readers anchor at column 0, so a quoted line can never be read as a header or an answer (reproduced as E2/E3 in the rev 3 pre-mortem).
- **D12. The cycle is a loop** (C3 default). You start it once with `/loop /dev-cycle`, self-paced. Each iteration is one full cycle (every trigger checked every time; your 2026-10-01 comment). After dispatch the iteration ends:
  - If any loop is running, the next iteration starts when one finishes (the background agent's notification), with a 1800 s fallback wakeup.
  - If every thread is blocked on you, a cheap check runs every 1200–1800 s. It runs a full cycle only when main's tip moved, an Asked ID was answered, or you wrote; otherwise it is a no-op wakeup.
  - The cost per iteration (F53) was C5. You answered on 2026-10-04: a full cycle every iteration for now, and a move to a light pass of steps 7, 8 and 10 between full cycles once the costs are visible. U5 files C5 as ANSWERED and adds a roadmap Next item to revisit it.
- **D13. The orchestrator isolates itself and checks main.**
  - **Where it runs.** The orchestrator session's working directory is `$TMPDIR/dev-cycle-orchestrator/`, which is not a git checkout. Every git or script call names its checkout (`git -C`, `cd X &&`). A loop subagent's shell starts in the orchestrator's directory before every call, so a loop's forgotten `cd` fails with "not a git repository" instead of committing to main (F43).
  - **Its own worktree.** Each iteration works in a fresh worktree, `.claude/wt-dev-cycle-<date>-<HHMM>`, on `chore/dev-cycle-<date>-<HHMM>` from `MAIN_SHA` (F49). The digest reads the roadmap, idea log, triggers and questions from `MAIN_SHA` (F42, F21).
  - **Start of each iteration.**
    - `build-loop.sh --state` refuses planted `.git` state before any porcelain git runs (F51).
    - `build-loop.sh --main-log SINCE`, where SINCE is the last record's `Main at:` SHA, classifies each first-parent commit on main as `gate`, `chore`, `answers` or `other`. `gate` is a commit-tree merge with the trailer. `chore` is a merge of a `chore/dev-cycle-*` branch the record names. `answers` is a non-merge commit whose diff touches only answer and Status lines in the questions files.
    - Any `other` stops dispatch and files one `you: judgment` entry naming the commit (F43). This is the minimal part of roadmap item (d), moved into this unit.
  - **Before the chore commit**, `build-loop.sh --cycle-diff --answered Q-…` compares the staged files with `MAIN_SHA`. It refuses a change to an existing entry's header or answer lines whose ID is not in `--answered` (answers you gave in-session), and a roadmap or idea-log line removed or edited other than by the cycle's own documented moves (F42).
  - **Dispatch** happens only after `git merge-base --is-ancestor <chore tip> main` confirms the land. A failed land is retried before the next iteration's step 7, so `Asked:` state is never re-derived from a main that lacks it (F49).
- **D14. Loops and the orchestrator share the machine.** The quiesce in step 1, and pr-prep's quiesce before its gate, cover only subagents this task started, and never stop or reap a process this task did not start (by PID). `scripts/health-check.sh` takes a `flock` on `$(git rev-parse --git-common-dir)/health-check.lock`, so the orchestrator's gate and each loop's gate run one at a time (F46; decision-log row 61). The loop prompt allows subagents only for research and review, each with scratch dir `<scratchpad>/<brief stem>/`. It forbids build loops, background agents, schedules, pushes and publishing (F47, F35).

C4 (merged-branch deletion) belongs to separate roadmap item (a), not this unit.

## Bypass-family pre-mortem (before any code)

Assume the handoff shipped and an autonomous loop landed something you never reviewed. "N" marks a rule that applies under both policies, "S" a self-merge-only rule. Rows F1–F31 and L1–L3 carry over from revision 2 (`docs/reviews/pre-mortem-build-loop-handoff.md`). Rows F32–F37 were this revision's first draft; F38–F53 and the re-marks come from `docs/reviews/pre-mortem-build-loop-handoff-rev3.md`.

| # | Family | Covered? | Guard (tests) |
|---|---|---|---|
| F1 | Policy text variants (interim suffix, case, spaces, two lines, fence, HTML comment, BOM) | covered | Exactly one unfenced line, byte-exact after one trailing CR; FENCE_AWK refusal → review (T1–T3) |
| F2 | Policy raised on the loop's branch (settings or brief `Policy:`) | covered | Read from main's commit only; stricter of main and brief; both files N-denied (T4, T5, T14) |
| F3 | Policy lowered after a loop started | covered | Re-read at merge; stricter wins (T5) |
| F4 | Root-level scripts (`install.sh`, `Makefile`) | covered (re-marked, rev 4) | No longer floor-denied: self-mergeable when `Paths:` lists them. Not live on merge in this repo (release-gated); a repo where one runs on merge (for example a package `prepare` hook) lists it in `Self-merge never:` (T10, T45) |
| F5 | Dotfiles and dot-directories (`.gitattributes`, `.gitmodules`, `.claude/`, `.envrc`, `.github/`) | covered | Floor item 2: any `.`-prefixed component (T10) |
| F6 | Renames out of a denied directory | covered | `--no-renames`; the D side refuses (T11) |
| F7 | Symlinks: added or type-changed | covered | Old and new mode of each raw entry ∈ {100644, 100755, absent} (T12) |
| F8 | Mode-only change, gitlink | covered (with F25) | Modes ∈ {100644, 100755, absent}: the exec bit is allowed (rev 4); gitlinks refuse; plumbing `diff-tree` with `diff.ignoreSubmodules=none` (T12, T26) |
| F9 | Instruction-file basenames in allowed dirs | covered | Floor item 1: `INSTRUCTION_FILE`, any case, any dir, including under `skills/` (T10) |
| F10 | Files later runs read as rules or truth | covered (re-checked, rev 4) | Floor item 4 keeps the docs `check_fix` denies (`docs/decisions/`, `docs/human-author/`, other briefs' working docs, cycle files) and adds `docs/thoughts/`, which `check_fix` still fixes (a living doc); own files keyed on the full brief stem. The rest of `check_fix`'s code-directory denials are gone (T10) |
| F11 | Files an instruction file `@`-imports | **partly** | Floor item 1 walks main's commit (`main_imports`, U2a3: NUL-safe listings, symlinks on main followed, `.claude/rules/` at any depth as starts; a name listed twice or as both a file and a directory, a name holding a newline, link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, or an imported path main lacks under a directory main stores as a symlink or gitlink fails the walk, so floor refuses every path). Until U2a3c it fails closed on the checkout: a start file main lacks (untracked, ignored, or only in the checkout's index), or anything but a plain directory at an imported path main lacks, fails the walk, so the gate needs a fresh worktree (U2b) and U2a4's floor should not be relied on before U2a3c lands; U2a3c walks them as a second phase that only appends. Gaps: known issue A5 (start files under a symlinked directory or in a submodule or untracked nested repo, case-insensitive names, checkout conversions (`working-tree-encoding`/`filter`/`ident` attributes from any attribute source, `core.symlinks=false`), and one shape untraced against Claude Code, and instruction files outside the repo). The walks share one name parser but not one start rule (A2's `.claude/rules/`, the outside-repo starts, U2b's reader model): U2a4's shared predicate is where one start predicate belongs (U2a3b L2-final architecture F5). The shared token parser reads a superset of Claude Code 2.1.292's import grammar (U2a3b; the claim and its exceptions are stated once, above `import_targets`); a Claude Code upgrade that changes its import grammar reopens this row. U2b names the checkout `--check` runs in. Listed in Q-103 |
| F12 | Cycle-owned files, any other brief including a new one, `briefs/closed/` | covered | N-denied via the lib's `writable()` plus `docs/dev-cycle.md` (T14) |
| F13 | Own brief edited beyond its Status line | covered | Merge-result blob = main's blob with the first unfenced `Status: open` → `Status: done` (T15) |
| F14 | Diff base differs from what lands | covered | Rules run on MAIN→R (D7); conflict → refuse (T16) |
| F15 | Tip moved after review; `--expect` given a name | covered | `--expect` is 40/64-hex and equals `show-ref --verify` of the branch (T17) |
| F16 | A closed brief's live loop merges | covered | Brief must read `open` on main at merge time (T18) |
| F17 | Non-ASCII, quoted or odd names | covered | `pathform` on every changed path; refuse without echoing (T13) |
| F18 | Case folding | covered | Lower-cased comparison (T10, T14) |
| F19 | The loop merges, pushes or commits to main with plain git | **partly** (was: not covered) | D13 makes the honest slip fail (no checkout in the orchestrator's directory) and detects any non-orchestrator commit on main at the next iteration (`--main-log`, T39). A deliberate `git push` or a commit disguised as `answers` is not caught. Listed in Q-103 as reachable by an honest loop without D13 |
| F20 | Marker spoofing | covered | Empty, single-parent tip, ≥ 1 commit ahead, exact subject, reason charset, body rules (T6, T7, T32) |
| F21 | Brief or plan text injection, with no human read of briefs (D10) | **partly** | Briefs are written from main's commit (D13 digest reads) and read from main's commit (T21); the evidence line in every prompt (T19). Under self-merge the allowlist bounds what lands; under review you read the result. What a steered loop *does* outside git is bounded only by the sandbox. Listed in Q-103 |
| F22 | The merge disturbs a shared checkout | covered | D7: nothing checked out; see F29, F50 (T22, T23) |
| F23 | Review artifacts as a write channel | covered | S: only *added* `docs/reviews/*` whose name contains the full brief stem (T10) |
| F24 | Gitignored working docs | covered | Only the diff lands (T9) |
| F25 | Shared `.git` state: config, hooks, attributes, replace refs | covered for the gate's git calls | D7 hardening and state gate (T26). The orchestrator's own git: F51 |
| F26 | The loop edits the gate | covered (with F38–F40) | D6: only the orchestrator's run of the hardened snippet can move main (T27, T33, T36, T37) |
| F27 | Slug collision between briefs | covered | Own files keyed on the full brief stem (T10) |
| F28 | Forged answers or roadmap edits in a working tree | covered (with F42) | D8 reads answers from main's commit (T34). D13: the orchestrator reads from main and `--cycle-diff` stops it from committing edits it did not make (T38). A forged commit on main is F19 |
| F29 | Main checked out, under rebase or bisect, or switched mid-merge | partly | As revision 2 (T22, T23); residual recorded |
| F30 | The loop adds a new brief | covered | F12 (T14) |
| F31 | Two open briefs name the same branch | covered | `--status`/`--check` skip both (T28) |
| L1 | Cycle commits on main break review merges | covered | D7 drops the ancestry rule (T16) |
| L2 | Entries re-filed or answered against a stale marker | covered | D4: entries keyed `Q-NNN@SHA`; dispatch only after the land (F49); merge entries pin TIP, checked by `--approved` (T35) |
| L3 | No way to re-prompt an existing branch | covered | `--prompt` (T24) |
| F32 | Loop-authored question text reaches `questions.md` | covered (by F41) | See F41 |
| F33 | A forged "[1] merge" answer makes a review merge skip the S rules | covered (with F42) | `--approved` reads main's commit and the slug (T35); the orchestrator cannot launder the answer (T38); gate files need a `merge-gate-` entry (F52). A forged commit on main is F19 |
| F34 | The orchestrator runs scripts a loop can write | covered (with F38–F40) | D6 (T33, T36) |
| F35 | A loop uses the orchestrator's other tools (push, publish, spawn build loops, schedule) | **not covered** | The prompt forbids each (T19); the subagent shares the orchestrator's permission mode. Same trust as F19. Listed in Q-103 |
| F36 | A stuck loop is re-dispatched forever | covered (by F44, F45) | Dispatch cap on the brief; the stall rule |
| F37 | Two orchestrators at once | partly | Worktree lock (F44) and atomic `worktree add -b` stop a second loop on one brief. Two chore branches can mint the same Q-ID; `questions.sh check` catches it at land time. Listed in Q-103 |
| F38 | D6 extraction honours `refs/replace` (E1, reproduced) | covered | The snippet refuses replace refs and grafts and compares hashes (T36) |
| F39 | D6 copy choice by file existence; the installed copy reached through the uid-writable `~/.claude/scripts` | covered | Root-commit identity; `/opt/...` by absolute path with an ownership check (T37) |
| F40 | D6 copy layout (`lib/`, `questions.sh` fallback) | covered | Same layout; `questions.sh` extracted too (T33) |
| F41 | Loop body in entry grammar: the first-vs-last `**Needs:**` split, planted answer lines, headings (E2, E3, reproduced) | covered | D3 body grammar; `--marker` refuses grammar lines and `> `-prefixes every line (T32, T34) |
| F42 | The orchestrator launders working-tree edits into its own commit | covered | D13: own worktree, digest reads from main, `--cycle-diff --answered` (T38) |
| F43 | Loop commands run in the orchestrator's directory (the shell starts there each call) | covered | D13: orchestrator directory outside any checkout; `--main-log` (T39) |
| F44 | Two agents in one worktree after re-dispatch; a live but stalled loop holds its slot | covered | Worktree lock; `--prompt` refuses a locked worktree without `--steal` (T40); the stall rule (D1) |
| F45 | The resume count is not persisted | covered | `Dispatched:` on the brief, read from main; `--prompt` refuses at 4 (T41) |
| F46 | Quiesce rules vs live loops; concurrent test gates | covered | D14: quiesce scoped to own subagents; `flock` in `health-check.sh` (T43) |
| F47 | The prompt forbids the subagents pr-prep needs; loops share the scratchpad | covered | D14 prompt wording (T19) |
| F48 | A merge entry asks [1] without showing the diff | covered | D4 entry body is `--check`'s output with the full TIP (T35). The slug pins 48 bits; a loop that grinds a prefix collision is F19-level |
| F49 | Many iterations a day; state lost when a land fails | covered | `-<HHMM>` branch names; dispatch only after the land; retry a pending land first (D13) |
| F50 | "Clean" vs `/workspace`'s untracked files | covered | D7: tracked changes only; an untracked collision refuses (T23) |
| F51 | The orchestrator's own porcelain git runs planted `.git` state | covered | `--state` at the start of each iteration (T42) |
| F52 | A review merge changes the gate itself | covered | `merge-gate-` slug required (T35); the release entry lists `scripts/` commits since the last release |
| F53 | Cost per iteration | a decision | C5, answered: full cycles now, revisit later (D12) |
| F54 | A loop edits `docs/constraints.md`, the input that steers every loop | covered | Cycle-owned, N-denied under both policies; read only from main's commit (T14, T44) |
| F55 | Dispatch with no constraints doc, or one with no hard constraints | covered | `--settings` reports `constraints missing` or `constraints none-hard`; `--start` refuses (T44) |
| F56 | A malformed or loop-raised `Self-merge never:` line | covered | Read from main's commit; malformed → self-merge off for the repo; `docs/dev-cycle.md` is N-denied (T45) |
| F57 | Self-mergeable code that takes effect on merge in a repo-specific way (here: `workflows/`, read from the loop's own checkout) | covered per project | `Self-merge never:` (interim `workflows/` in this repo; entry in U5). A repo whose list misses such a path is a settings gap, which the deep audit's guidance dimension checks |
| F58 | Self-mergeable code reaches running sessions through a release you skim | partly | The release entry lists every commit and changed path since the image `.manifest` commit, flagging self-merged ones. Your release review is the gate. Listed in Q-103 |
| F59 | Quiet constraint drift in Path A decisions you never see | partly | D2's drift check samples one Path A decision per sampled merge; a finding triggers the deep audit's constraints dimension |

**Not covered: F35. Partly: F11, F19, F21, F29, F37, F58, F59.** None of them blocks self-merge mechanically. Each is a way around the gate by a loop that already has a shell and the session's tools, not a hole in the gate's own rules. All are listed in Q-103 when it is re-routed (step 13), together with "what the gate can and cannot do". The policy stays `review` until you answer it.

## Approach

U0 extracts dev-cycle.sh's reader into `scripts/lib/dev-cycle-read.sh`, as revision 2 described:

- `scrub` and its re-exec wrapper;
- `pathform`, FENCE_AWK and `oddwhy`, `INSTRUCTION_FILE` and the import walk;
- `writable` and `isbrief` (`check_fix`'s predicate stays in dev-cycle.sh: amended 2026-10-05, see below);
- default-branch resolution, which returns instead of exiting;
- `check_brief`, `check_branch` and `check_answer`;
- `brief_fields` (built in U1, step 3, not moved in U0).

**Amendment (2026-10-05, U0 review).** `check_fix` is an allowlist of docs an in-cycle fix may edit; D5's floor is a denylist over any path, and the two differ (`working/`, `reviews/`, `thoughts/`, `constraints.md`). Moving the predicate in U0 would mean splitting `check_fix`, which a pure move cannot do, and building a policy switch for a caller that does not exist yet. The predicate therefore stays in dev-cycle.sh; it is not extracted later either. U2 instead writes the floor as its own lib function from the shared pieces already in the lib (`INSTRUCTION_FILE`, the import walk, `writable`) plus a dot-component test that also refuses a leading-dot top-level path such as `.envrc` (`check_fix`'s `*/.*` test misses it, harmlessly there because such a path also fails `^docs/`), adds an `isimported` predicate so neither caller reads the walk's cache format, and either shares one read-as-truth list with `check_fix` or files the difference as a `you: judgment` entry. The import walk reads the working tree at `ROOT_REAL`, so the gate must run it in a worktree checked out at `MAIN_SHA` or use a commit-reading variant; F11's row above and step 13's Q-103 text now carry this precondition. The gate's worktree must have no untracked instruction files of its own, and the gate cds to its top level (need_root refuses anything else). The walk also starts from the checkout's untracked and ignored instruction files (`CLAUDE.local.md`), which a clean worktree or a commit-reading variant lacks; U2 either adds the orchestrator checkout's local instruction files to the gate's start set or records the gap in F11, and tests it. Floor item 1 makes the gate a second user of the walk's refusal set (boundary B2 in the pass-38 security review), so the walk's known gaps (F11 "partly") become gate gaps too; U2's architecture and security review confirms that rather than inheriting it. Source: `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md`. U0 also split into three units (U0a/U0b/U0c), not two: moved lines count twice under the 400-line cap.

Both scripts source the lib from their own `SCRIPT_DIR`, so the copy D6 extracts is self-contained. `build-loop.sh` resolves `MAIN_SHA` once and calls the lib directly, with no subprocess. Output follows dev-cycle.sh's check-mode conventions:

- `skip X: why` means unreadable; `refuse X: why` is a verdict;
- read modes exit 0 when every argument was answered;
- writing modes exit 2 on any refusal;
- usage errors exit 1.

## Script interface (`scripts/build-loop.sh`)

Read modes:
- `--settings` → from main's commit: `policy self-merge|review set|unset: WHY`, `slots N set|default: WHY`, `never GLOB… set|none|malformed: WHY` (from `docs/dev-cycle.md`), and `constraints ok N-hard M-soft|missing|none-hard|unreadable: WHY` (from `docs/constraints.md`, read under FENCE_AWK).
- `--status BRIEF…` → `ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]`, where LOOP is `absent | working | ready | blocked | stopped`.
- `--marker BRIEF` → `ok BRIEF SHA`, then the `blocked` or `stopped` body under D11's rules; otherwise `skip`.
- `--state` → `ok`, or `refuse KEY` for each planted `.git` state the gate refuses (exit 2).
- `--main-log SINCE` → one `gate|chore|answers|other SHA SUBJECT` line per first-parent commit after SINCE.
- `--cycle-diff [--answered Q-…]` → `ok`, or `refuse PATH: why` (exit 2); run in the orchestrator's worktree against `MAIN_SHA`.

Gate:
- `--check BRIEF… [--expect SHA]` → D7, the N rules, and the S rules when the stricter policy is self-merge. Advisory when a loop runs it.
- `--merge BRIEF --expect SHA [--approved Q-NNN]` → as `--check`, then commit-tree and CAS. Without `--approved`, the stricter policy must be self-merge and the S rules apply. With it, only the N rules apply; Q-NNN must read option 1 on main's commit with slug `merge-STEM-SHA12`, or `merge-gate-STEM-SHA12` when the result touches the gate's own files.

Dispatch:
- `--start BRIEF [--dir DIR]` → the constraints doc must read `ok` (D2), and the brief must be `open` on main, with a `Branch:` that does not exist yet. Runs `worktree add -b BRANCH DIR MAIN_SHA`, locks the worktree, and prints the prompt. On failure, nothing is left behind.
- `--prompt BRIEF [--steal]` → the brief must be `open`, with its branch present and `Dispatched:` under 4. Prints the prompt; adds a worktree only if the branch has none; refuses a locked worktree unless `--steal` and the tip is over 2 hours old.
- `--start` and `--prompt` print `dispatched N` for the orchestrator to write as `Dispatched: N` on the brief in its next chore commit. The script writes no file on main.

Other details:
- `--check-answer` moves into the lib and reads main's commit (D8). dev-cycle.sh keeps its flag.
- Prompt content:
  - the evidence line;
  - "your worktree is ABS-PATH: start every command with `cd ABS-PATH &&`; your shell starts outside any checkout";
  - the brief path and main's commit (`git show COMMIT:PATH`);
  - the resolved policy;
  - `docs/constraints.md` from main's commit, quoted, and the rule: every design choice runs DD seeded with it; Path A → proceed; no clear winner, no survivor or a missing fact → `blocked`;
  - "force-add your research doc (`git add -f`), so your DD records land with your work";
  - the three markers, when to use each, and the blocked-body grammar;
  - "subagents only for research and review, each with scratch dir SCRATCH/STEM/; never start build loops, background agents or schedules; never push, merge, open a PR or publish";
  - "never write the questions files, the roadmap, `docs/dev-cycle.md` or any other brief";
  - "in your own brief, change only the Status line, open→done, in your final change";
  - "run RPI with no plan-approval gate: questions go in a `blocked` marker";
  - "`--check` is advisory; the orchestrator's run decides".
- Brief machine lines (the orchestrator writes them; `brief_fields` reads the first unfenced line of each from main's commit):
  - `Branch: NAME` (required);
  - `Policy: self-merge|review` (anything else is review);
  - `Paths: P…` (a malformed or duplicate entry means no self-merge);
  - `Asked: Q-NNN@SHA, …` (D4);
  - `Dispatched: N` (D1).

## Skill changes (`skills/dev-cycle/SKILL.md`)

The flow becomes:

```
start: --state, --main-log → 0 digest (from main) → 1 health → { 2 triggers | 3 questions | 4 spot-check | 4b audit check }
  → 5 brainstorm → 6 roadmap → 7 collect results → 8 briefs into free slots → 9 record, --cycle-diff, land (pr-prep, no gate)
  → 10 dispatch (after the land is verified) → wait or go again (D12)
```

- **Rules** gain D13's isolation (the orchestrator's directory, its worktree, `git -C`), D6's snippet, D11, and D14's quiesce scope. "This skill does not read the policy" is removed.
- **Step 1** quiesce covers only this iteration's subagents (D14).
- **Step 4, spot-check**: D2's drift check on one Path A decision per sampled build-loop merge.
- **Step 4b, deep audit**: a drift finding is a trigger; the audit gains the "constraints and project guidance still match intent" dimension (it also checks that `Self-merge never:` covers paths that take effect on merge, F57).
- **Step 6, In flight**: check 1 (done/dropped → Done/Ideas, `git mv` to `closed/`) is kept. Checks 2–3 (keep-or-drop, 14 days) are removed; step 7 replaces them.
- **Step 7, collect**: D4, through D6's snippet.
- **Step 8, briefs**: as today's "Build briefs", plus the machine lines, with `Paths:` only when the stricter policy and the floor allow it. Only free slots are filled (D9), and briefs whose questions are all answered come first.
- **Step 9, close**: today's step 7, plus `Main at:` and the SHAs of the merges this iteration made, a line per dispatched, collected and merged brief, and `--cycle-diff` before the commit. pr-prep runs with no approval gate (your answer 7).
- **Step 10, dispatch**: only when `--settings` prints `constraints ok` (D2; otherwise one entry, filed once); D1; then the wait or go-again rule (D12). The final message lists new `you: judgment` IDs, merge entries or PRs, and working-tree-only answers.
- `workflows/pr-prep.md:333`: the quiesce covers subagents this task started; the reap is by PID only (D14).
- The "does not run yet" and "not built yet" wording is removed throughout.

## Steps

Stacked review units (log row 62: about 400 changed code lines outside `docs/`; moved lines count twice). Tests come first in each unit.

1. **U0, extract the lib** (~260 lines moved; U0a/U0b if it measures over 400). Behaviour unchanged. Tests: T25 (53 green), T29, T30. Commit `refactor:`.
2. **U1 tests**: T1–T8, T21, T28, T34, T44 (settings part) in `test/scripts/build-loop-read.bats`, with `test/lib/build-loop-fixtures.bash`. Commit `test:`.
3. **U1 code** (~280): `brief_fields`, `--settings` (with constraints and `Self-merge never:`), `--status`, and `check_answer` reading main's commit. The dev-cycle.bats answer tests are updated to commit their fixtures. Commit `feat:`.
4. **U2 tests**: T9–T18, T20, T26, T27, T45 in `build-loop-check.bats`. Commit `test:`.
5. **U2 code** (~200): `--check`, the state gate, merge-tree, the N rules, the S rules over the rev 4 floor and `Self-merge never:`, `--expect`. Commit `feat:`.
   **U2 split (2026-10-06).** U1 measured four units against a planned one, and U2 carries 26 override rows, so it lands as stacked units:
   - **U2a1**: `main_entry`'s `badform` word with one shared reason mapping, `entry_why` (rows 228, 306); one spelling of the closed/ rule, `isclosed` (row 292); `check_fix` also refuses `docs/constraints.md` (row 204: the user writes it, D2; `docs/thoughts/` stays fixable in-cycle as a living doc, so `check_fix` and the floor differ there on purpose); U1d's carried wording and fixture rows.
   - **U2a2, the shared token parser** (no new mode): `import_targets` (UTF-8 spaces including U+FEFF end a token; a token ending in punctuation yields its whole and its stripped name; a `..x` name is followed; text holding a NUL is read), `isimported tree`, which `check_fix` calls, and U2a1's carried rows C12-C14. Split from the walk at its review's iteration 2 for size.
   - **U2a3, the commit-reading walk** (no new mode): `main_imports` and `isimported main`, an import walk that reads main's commit, started from main's instruction files and `.claude/rules/`. It refuses the tree and link shapes it does not model (a name listed twice or as both a file and a directory, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an imported path main lacks under a directory main stores as a symlink or gitlink), as FENCE_AWK does, and fails closed on the checkout (a start file main lacks, or anything but a plain directory at an imported path main lacks). First built as U2a, which hit the review cap modelling those shapes one by one (Q-119, rubric `code-review-rubric-2026-10-06-feat-build-loop-u2a.md`); carries U2a2 iteration 2's rows B2-B6, B8, B10-B12, B14. Split at its own cap (2026-10-06, the user chose split): the checkout-side reads moved to U2a3c.
   - **U2a3c, the checkout phase** (no new mode): after main's walk reaches a fixpoint, a second phase walks the checkout's start files main lacks and the imported paths main lacks, and only appends; an unsearchable checkout directory fails the walk. One drain loop run over two seedings (phase 2 shares `ent` and `seen` and reads a path main stores through main's arms), and every phase-2 item passes one admission check (main's links and gitlinks, the checkout's links) before it is marked seen (U2a3 L2 architecture F1, F5). Stacks above U2a3b. Carried from U2a3b loop 2 (2026-10-07): phase 2's fail rules must be safe for every superset prefix candidate (fail on a non-plain node, never merely because the checkout holds a file main lacks: an ignored `.env` beside `@.env.example`); one capped and drained reader (4 MiB + 1, Claude Code's limit) for checkout files and main's blobs alike (a bare `head` after `git cat-file` exits 141 under pipefail: check `git cat-file -s` first or drain); phase 2 stays in main_imports' one drain loop, charged to the same IMPORT_OUT_MAX budget; no third path resolver (IMPORT_AWK's `put` and the symlink arm's `realpath -ms` are the two); memoize `blocker` per directory prefix (L2-C6).
   - **U2a4, the floor in the lib** (no new mode): `floor`, `ownfile` and `GATE_CODE` over U2a3's walk, with the shared check_fix/floor predicate (rows C1, C3, 308).
   - **U2b, `--check` and the N rules**: the hardened git wrapper and state gate, `--expect`, the brief's state, F31 (brief enumeration moves into the lib, row 298), merge-tree, the raw `diff-tree` parse with the mode rule, `pathform` per path, the N rules, the own brief's Status-only rule, `check_branch`'s refusal under a broken config (row 307). It names the checkout `--check` runs from: a fresh worktree at MAIN_SHA, since until U2a3c the walk fails on any start file main lacks, ignored ones included, and on anything but a plain directory at an imported path main lacks; U2b is to refuse (not built yet; the walk does not check this) a checkout where `git check-attr` shows a `working-tree-encoding`, `filter` or `ident` attribute on any path the walk reads (from `.gitattributes`, `$GIT_DIR/info/attributes` or `core.attributesFile`), or whose `core.symlinks` is false, and runs the walk under `LC_ALL=C` (A5). Tests T11–T18, T20, T26. Carried from U2a3b loop 2 (architecture L2-i2 F1, L2-final F1-F3; security L2-final F1): a reader model in three parts, since a reading session differs from the gate in (a) which instruction files it loads, including files outside the repo (a parent directory's CLAUDE.md, the user's memory file, managed policy; which memory file counts when a loop runs under its own CLAUDE_CONFIG_DIR), (b) which directory its relative names resolve against (`@../wtB/docs/x.md` re-enters another checkout through its directory name), and (c) which absolute and `~/` paths count as repo paths and which repo path each maps to (every `git worktree list` path, the sessions' HOME; project a name under the longest matching root, since worktrees nest inside the main checkout). The reader set includes the host: sessions normally run in cc-isolated, but when the image breaks the user runs one on the host in `~/claude-workflows` under the host HOME (Q-121, answered 2026-10-07), so that checkout and that HOME's instruction files are readers too, or a named exception. The parser takes the home from its caller then, not from its own import_home call. The main checkout's working tree is a parent of every worktree here, so its instruction files load as parent memory and no walk of main's commit models them: name that as an exception or bar it.
   - **U2c, the S rules**: `Paths:` parsing, own files, the floor, `Self-merge never:` matching, the stricter policy. Tests T9, T10, T45.
   - T27 moves to U3b, beside the D6 snippet it tests.
6. **U3 tests**: T19, T22–T24, T35, T40, T41, T44 (`--start` part) in `build-loop-merge.bats`. Commit `test:`.
7. **U3 code** (~230): `--start`, `--prompt` (lock, steal, dispatch cap), `--merge`, `--approved` (with the `merge-gate-` rule). Commit `feat:`.
8. **U3b tests**: T32, T33, T36, T37, T39, T42 in `build-loop-orchestrator.bats`. T33, T36 and T37 test the D6 snippet, which U3b ships as `test/lib/d6-snippet.bash`, a byte copy of the SKILL.md block; a test asserts the two match. Commit `test:`.
9. **U3b code** (~230): `--marker`, `--state`, `--main-log`, the D6 snippet copy. Commit `feat:`. Then **U3c**: T38, T43 tests, then `--cycle-diff` and the `flock` in `scripts/health-check.sh` (~150).
10. **U4, skill and pr-prep** (~300 lines in `skills/` and `workflows/`): the flow, Rules, step 1, steps 4 and 4b (drift check and constraints dimension), steps 6–10, the D6 snippet, and pr-prep's quiesce line. Commit `feat:`.
11. **U5, settings and docs**:
    - `docs/dev-cycle.md` describes the handoff as built: the policy, slots, `Review handoff:` and `Self-merge never:` lines (interim `workflows/` here); "not built yet" is removed.
    - `workflows/codebase-onboarding.md` step 13 also asks for `docs/constraints.md` and points to the roadmap item for writing one.
    - `workflows/codebase-onboarding.md:453` drops "a planned unit".
    - Decision-log row 70 (D1–D14, what the gate cannot do, your override as D10).
    - The seed's Status line → "superseded by log row 70".
    - Research gotcha corrected.
12. **U5, roadmap and questions**:
    - Roadmap items from your answers: (a) merged-branch deletion (needs C4), (b) the audit dimension menu, (c) brainstorm confidence routing (the hard-constraints part is now D2's `docs/constraints.md`). Plus (d) the rest of "build-loop audit": re-running the N/S rules over past gate merges; (e) a process for writing a repo's constraints doc (owner attention: routed `you: judgment`, never dispatched); (f) revisit C5's light pass once costs are visible; (g) future directions from the walk-through: one loop retry on a refused self-merge (D4), and a per-project floor (D5).
    - `you: judgment` entries for C1–C3 (defaults as Interim), C4 under item (a), C5 filed as ANSWERED with your in-session answer, and one for `Self-merge never: workflows/` in this repo (keep or drop).
    - One `you: judgment` entry: this repo has no `docs/constraints.md`, so dispatch stays off here until you write it (D2).
    - One `you: terminal` release entry: rebuild and bless, so the image's dev-cycle skill carries this unit. The gate does not need it (D6), but the installed skill does. Release entries list every commit and changed path since the image's `.manifest` commit, flagging self-merged ones (F58); the skill's close step says so for future releases.
13. **U5, Q-103 and brief**: re-route Q-103 to `you: judgment`, listing F11 (with its `MAIN_SHA` precondition for the import walk), F19, F21, F29, F35, F37, F58 and F59 and "what the gate can and cannot do". Set this brief's Status to `done` in U5's merge.

## Implementation order

`1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 (U3b, U3c) → 10 → [11, 12, 13]`. Sequential: each unit stacks on the previous one and lands through its own review-fix loop.

## Size estimate

- `scripts/build-loop.sh` ~720.
- `scripts/lib/dev-cycle-read.sh` ~340.
- `dev-cycle.sh` ~880 → ~600.
- `health-check.sh` +5.
- Tests: four bats files of ~220 each, plus fixtures of ~110.
- SKILL.md: net about +90.
- Units: U0 ~520 changed as moves (probably U0a/U0b); U1 ~400; U2 ~420; U3 ~410; U3b ~400; U3c ~260; U4 ~300; U5 ~170.

## Estimated context cost

Research is done (~150k, plus this revision ~200k with its pre-mortem). Implementation ~380k across nine units. Review ~320k (nine review-fix loops). One fresh session per unit, each loading the checkpoint.

## Actual context cost (post-implementation)

__

## Test specification

The hermetic throwaway-repo setup is the same as `test/scripts/dev-cycle.bats`. On failure, each test prints the script's whole output and `git log --oneline --graph --all`. T1–T31 are as in revision 2 (`git show 3a005378:docs/working/plan-build-loop-handoff.md`), with these changes:

| T | Case | Expected | Level |
|---|---|---|---|
| T1–T3 | As rev 2, via `--settings`; plus `Build-loop slots:` 0, 10, `3 `, two lines, in a fence | policy as rev 2; slots default 3 + why | unit |
| T10 | Rev 4 floor. Refuse even when listed: `CLAUDE.md`, `skills/x/SKILL.md`, an `@`-imported doc, `.claude/settings.json`, `.envrc`, `.gitattributes`, `docs/x/.y`, `scripts/build-loop.sh` and `scripts/lib/dev-cycle-read.sh` (gate code), `docs/constraints.md`, `docs/decisions/001-x.md`, `docs/thoughts/x.md`, another stem's checkpoint, an added review for another stem, a modified review. Pass when listed: `scripts/other.sh`, `skills/x/helper.md`, `hooks/x.sh`, `install.sh`, `test/x.bats`. Refuse when not listed: any of those. `Paths:` boundaries (`docs/a` vs `docs/ab.md`); duplicate or malformed entries | as listed | integration |
| T12 | Symlink added; file → symlink; gitlink → refuse. Exec bit added on a listed `scripts/x.sh`, and a new 100755 file → ok | as listed | integration |
| T6 | Loop states absent/working/ready/blocked/stopped; every field asserted, `DISPATCHED` included; reason at 120 and 121 chars | as listed | unit |
| T7 | Spoofed markers: with content, a merge commit, a suffixed subject (`handoff: blocked!`), control/bidi in the reason, an orphan commit, a marker at main's tip with 0 ahead | working / `unreadable` | unit |
| T19 | `--start`: the prompt holds every required line (the `cd ABS-PATH &&` rule, the scratch-dir line with the stem, no blanket "never start agents", "no plan-approval gate", "`--check` is advisory"); worktree HEAD = MAIN_SHA; worktree locked; `dispatched 1`; default dir; `--dir` rules | as listed | integration |
| T23 | As rev 2, plus: an untracked unrelated file in W → merge; an untracked file at a path the merge adds → refuse | as listed | integration |
| T27 | A gate copy with a patched rule, run from the loop's worktree, prints ok; the D6 snippet's copy refuses the same tip | refuse from main's copy | integration |
| T32 | `--marker`: a plain 3-question body → printed, every line `> `-prefixed; E2's body, E3's line, `### Q-001 · x`, `Q-1: [1]` → skip; 101 lines or a 301-byte line → capped with a note; control/bidi scrubbed; an open fence → skip; a `ready` marker → skip | as listed | unit |
| T33 | The D6 snippet: extracts the four files into `$T/scripts/{,lib/}`; the copy sources its own lib and `questions.sh`; a working-tree edit has no effect; the SKILL.md block and `test/lib/d6-snippet.bash` are byte-equal | as listed | integration |
| T34 | `--check-answer` (both scripts): an answer only in the working tree → `open`; committed on main → read; committed only on another branch → `open`; the E2 fixture with the body quoted by `--marker` → option 2, and `questions.sh open` omits the ID | as listed | unit |
| T35 | `--merge --approved`: Q-NNN answered [1] with a matching slug → merges with N rules only; answered [2]/[3]/open; a slug naming another brief or an older TIP; an answer only in the working tree; a gate path under a plain `merge-` slug → refuse, under `merge-gate-` → ok | as listed | integration |
| T36 | A blob replace ref, and separately a commit replace ref, on main's `build-loop.sh`; `info/grafts` present → the snippet refuses before running anything | refuse | integration |
| T37 | A non-claude-workflows fixture repo with `scripts/build-loop.sh` on main → the snippet picks the `/opt` path (stubbed), not main's; a uid-owned stub dir → refuse | as listed | integration |
| T38 | `--cycle-diff`: a planted ANSWERED flip on an entry not in `--answered` → refuse; the same with the ID listed → ok; an appended entry → ok; a roadmap line edited outside the cycle's moves → refuse | as listed | integration |
| T39 | `--main-log`: a gate merge, a chore merge, an answers-only commit, and a non-merge commit touching `docs/x.md` → classified `gate`, `chore`, `answers`, `other`; an `answers`-shaped commit that also changes an options table → `other`. A bare `git rev-parse` from a non-checkout directory fails | as listed | integration |
| T40 | `--prompt` on a locked worktree → refuse; `--steal` with a tip under 2 h → refuse; over 2 h → ok and relocked | as listed | integration |
| T41 | A brief with `Dispatched: 4` → `--prompt` refuses; `Dispatched: 3` → ok, prints `dispatched 4` | as listed | integration |
| T42 | `--state`: `core.fsmonitor`, a local filter, a hook key, `refs/replace/`, `info/attributes` → refuse each, exit 2; a clean repo → ok | as listed | unit |
| T43 | Two concurrent `health-check.sh` runs (stubbed suites) serialize on the lock | second starts after first ends | integration |
| T44 | `--settings` constraints: no file → `missing`; only soft constraints → `none-hard`; an `H1` with a `success:` line → `ok 1-hard`; a file FENCE_AWK refuses → `unreadable`; only in the working tree → `missing`. `--start` refuses unless `ok`; a branch change to `docs/constraints.md` → refuse under both policies | as listed | unit + integration |
| T45 | `Self-merge never:` `workflows/` → `workflows/x.md` refused under self-merge even when listed, ok under review; two lines, a bad glob or `..` → `malformed`, self-merge off; the line raised only on the loop's branch → ignored | as listed | unit + integration |

Dropped from revision 2: none of the T-ids. T19 and T24 now test the orchestrator's commands rather than your own.

## Failure modes considered

| Failure mode | Guard |
|---|---|
| The extraction changes dev-cycle.sh's behaviour | U0 is its own unit; T25, T29, T30 |
| A self-merge lands a denied path through an unlisted family | The allowlist is primary (D5); F1–F53 |
| A review merge can never complete after a cycle lands | D7; T16 |
| The gate runs a loop's bytes | D6 snippet; T27, T33, T36, T37 |
| An honest loop commits to main from the wrong directory | D13; T39 |
| The user's answer is read as something else | D3 body grammar, D11 quoting; T32, T34 |
| A loop waits on you | D2: `blocked` marker, slot freed |
| The orchestrator spends without bound | D9 slots; D1 dispatch cap and stall rule; D12 no-op wakeups; C5 |
| The docs describe a design the script lacks | U4–U5 land last; code-fact-check runs in their review loop |

- `/pre-mortem`: run twice. Revision 2's output is `docs/reviews/pre-mortem-build-loop-handoff.md`. This revision's is `docs/reviews/pre-mortem-build-loop-handoff-rev3.md`: 5 narratives, 3 reproduced experiments (E1 replace refs, E2 an answer read as the wrong option, E3 an entry archived out of sight), folded in as D13, D14, the D6 hardening, the D3/D11 body rules and F38–F53.
- `/architecture-review`: revision 2's still holds for the lib and script. The orchestrator flow and the new modes are reviewed in U3b's and U4's review-fix loops.

## Risks

- **The design grew.** Revision 3 adds about 230 lines of script (U3b) to close what the pre-mortem reproduced. The alternative was to leave the policy at `review` forever and file F41–F43 in Q-103. F41 (answers misread) and F43 (an honest commit to main) bite under `review` too, so they could not just be listed.
- **The image lags main.** The installed skill (`~/.claude/skills`) is the image copy, so the orchestrator loop runs in this repo only after a release (step 12). The gate itself does not wait (D6).
- **Subagent loops die with the orchestrator session.** D1 re-dispatches them; the cost is one resumed RPI session per restart, capped by `Dispatched:`.
- **D8 adds a step for you:** an answer typed into the working tree counts only once you commit it or tell the orchestrator. The wait message lists such answers.
- **The state gate (F25, F51) can refuse** when a legitimate local config sets a `diff.*` or `merge.*` key. The refusal names the key.
- **F35 rests on same-uid trust**, stated in Q-103.
- **macOS is not tested.** dev-cycle.sh is already GNU-only, and `flock` is util-linux.

## Rollback

1. Each unit lands as its own `--no-ff` merge on main. Revert in reverse order: `git revert -m 1 <U5> <U4> <U3c> <U3b> <U3> <U2> <U1> <U0c> <U0b> <U0a>`. After the U0 reverts, run `bats test/scripts/dev-cycle.bats` (53 pass).
2. Set Q-103 back to `deferred` with its old Deferred line, remove the C1–C5 and release entries, and run `scripts/questions.sh index`.
3. Stop a running orchestrator: end the `/loop` (or the session). Its subagent loops stop with it, and their branches and locked worktrees stay for inspection (`git worktree unlock` before removing).
4. A bad self-merge: commit `Build-loop policy: review` on main first. That binds running loops, because the stricter value wins and the gate re-reads it at merge time. Then `git revert -m 1 <that merge>` and set its brief to `Status: dropped`.
5. Worktrees from `--start`: `git worktree unlock` then `git worktree remove .claude/wt-<stem>`. Branch deletion is your call (roadmap item (a)).

Irreversible part: none in git. A self-merged doc that a later session already read can't be un-read. The allowlist and the floor keep such changes away from files that later runs follow.
