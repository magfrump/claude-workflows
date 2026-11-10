# Research: three small dev-cycle skill fixes that waited on the release

**Goal**: fix three passages of `skills/dev-cycle/SKILL.md` that every recent iteration worked around: the identity check, the release paste's pinned commit, and the record's silence about a free slot.
**Problem framing**: each passage asks the orchestrator, or the owner, for something that cannot be done as written, so it is skipped or worked around and guards nothing. Considered and discarded: "the orchestrator is not following the skill" (the records show it tried each one as written, and the workaround was the only way on).
**Project state**: this branch delivers the three prose fixes and the tests that run the skill's own commands · standalone, from the roadmap's Now item "after the Q-261 release" · not blocked (cite: docs/working/briefs/2026-11-10-dev-cycle-skill-held-fixes.md)
**Task status**: complete (implemented; the review-fix loop ran its three iterations, and the rubric says how it ended)

## What exists

- `skills/dev-cycle/SKILL.md` is the orchestrator's whole procedure, and it is gate code (`GATE_CODE` in `scripts/lib/dev-cycle-read.sh`), so this branch comes to the owner as a `merge-gate-` entry and its text runs only after the next image release. [observed]
- **Item 1.** The Rules bullet "The orchestrator's git" (lines 66-69 at a37733cc) says `git -C WT config user.email` and `… user.name` must each print one, and none is a stop. [observed] In this sandbox both print nothing: `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME` and `GIT_COMMITTER_EMAIL` are set and git config holds no `user.*`. [observed: `env`, `git config user.email`] The records since iteration 2026-11-05-2347 say "Identity from the environment" and go on. [observed: `docs/working/cycles/cycle-2026-11-06.md`]
- The gate's own check is `merge_ident` in `scripts/build-loop.sh` (line 1547): `git -c user.useConfigOnly=true var GIT_AUTHOR_IDENT`, and the same for the committer, refusing when either fails. Its comment says why the flag: without it git takes `EMAIL` or guesses from the passwd entry and the host's domain. `test/scripts/build-loop-merge.bats` lines 91-103 hold its cases (none, `EMAIL` only, a global config, a committer with no email). It also refuses an output without a name and an address, by shape. [observed]
- **Item 2.** Step 0.1 files the `image-lag` entry (also the release entry) when the image's gate code differs from main's. Its paste is `cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh`, with A the host checkout (`assembled_from=` in `/opt/claude-workflows/.manifest`) and M main's commit at step 0.1. [observed: lines 250-254]
- The same iteration's step 9 lands the record on main, so main is past M before the owner reads the entry. `--land-cycle` fast-forwards the main checkout when it has main checked out, so the host checkout sits at main's tip, never at M. [observed: step 9.4; `/workspace` is on `main` at main's tip today]
- What that land carries: `--cycle-diff` refuses "any path but the cycle's own files, a `.md` under `docs/` or `README.md`" and "the gate's own code". [observed: step 9.3] So a cycle land never changes gate code.
- The paste's reason for `rev-parse`: it is the paste's only git call before `install.sh`'s state gate (`git_state_gate`, `devcontainer-config/install.sh` line 220), and it runs no hook or fsmonitor. The host checkout's `.git` is writable by a sandbox session, so any other git command on the host can run what a session planted. [observed: skill lines 251-254, install.sh lines 205-215]
- `install.sh` installs committed content only (`git archive` of HEAD) and stamps `commit=` with HEAD, which becomes C at the next step 0.1. [observed: `assemble`, lines 341-372]
- **Item 3.** The record template's line is `8. briefs: <written this iteration, or none>; queue <k>/<slots> (full: no new briefs)`. Step 8 says when a brief is written and nothing about a slot left free. [observed: lines 701-706, 773]
- `docs/dev-cycle.md` describes the slots and the queue, and says the release entry flags self-merged subjects. It does not describe the identity check, the paste's pin or the record's `8.` line. [observed] A build loop may not change that file (the gate's N rules deny it), and nothing in it needs to change.
- Tests that pin the skill's prose live in `test/scripts/build-loop-orchestrator.bats`. One forbids the string `GIT_AUTHOR_NAME` in the skill (the removed identity ritual, brief 2026-11-01-relax-dev-cycle-skill-prose); one pins step 0.1's PATHS line to `GATE_CODE`; one needs the words "and the one paste" in step 0. One extracts the skill's d6 call and runs it. [observed: lines 273-300, 421-470]

## Invariants

- The skill never holds `GIT_AUTHOR_NAME` (test "SKILL.md's orchestrator runs plain git…"). The new check names `GIT_AUTHOR_IDENT`, which the pattern does not match. [observed]
- Step 0.1's PATHS line stays alone on its line, three spaces in, equal to `GATE_CODE`'s paths. [observed: test at line 464]
- The entry stays one paste (constraint S10 and the global instructions' terminal-entry rule), written whole each iteration from C, M and THE LOG (test "the first trial set's practices…").
- Step 0.1's close rule reads the image's commit C and main's M: after a release from main's tip T, C is T, which is on main's first-parent history, and `diff --quiet C M -- PATHS` exits 0. [observed: lines 226-262] A release from main's tip therefore closes the entry exactly as a release from M did.
- No change to `scripts/d6.sh`, and no new owner stop, entry or host chore (the brief).

## Prior art

- `merge_ident` (above) is the identity question already answered once in gate code. Reusing its command is constraint S3.
- Q-156's paste (2026-10-14, `docs/working/questions-archive.md`) compared, with `rev-parse` only, each installed directory's tree at HEAD with M's, plus checks for replace refs, grafts and `core.attributesFile`. It refused on the day ("devcontainer-config differs from M": later merges had moved released paths), and the owner then installed from main without the paste. That long paste was Q-156's own: the skill's paste has been the single test since 43b8d7ed (2026-10-13). [corrected in review: an earlier draft credited the restriction audit]
- Q-222 and Q-227 (`docs/working/questions-archive.md`) pasted `git merge-base --is-ancestor M HEAD && ./devcontainer-config/install.sh`: candidate 2 below, already written once by an orchestrator working around the pin, with `merge-base` run bare.
- The last two releases, checked from the manifest history: Q-252's paste pinned `3a663f88` and the image was built from `dff98910`; Q-261's pinned `3dbf43cb` and the image was built from `536b7082`. Both builds are cycle-land commits past the pinned M with M's gate code (`git diff --quiet M C -- PATHS` exits 0 for both). [observed] So the pinned test cannot have passed either time: the owner released from main's tip without it.
- The override log (`docs/reviews/override-log.md`, rows of 2026-10-14 on `feat/build-loop-u4c`) records the earlier try at a second command: a paste that added `git diff --quiet HEAD -- devcontainer-config/install.sh` ran a planted `core.fsmonitor` and a clean filter on the host before `install.sh`'s state gate, and was taken out again. A later row settles as won't-fix that the paste runs the working tree's `install.sh`, not M's blob; this change does not reopen it.
- The orchestrator already rewrites the entry after a merge in the same iteration: "Q-261 rewritten for M 771c84e8, after the merge below" (`docs/working/cycles/cycle-2026-11-06.md`, iteration 2026-11-07-0621). [observed]
- Records already give a reason for a free slot when the orchestrator thinks of it: "queue 0/3. The rest of Now waits on the owner, a host run or a choice." (`cycle-2026-11-06.md`), against "queue 0/3." alone (`cycle-2026-11-05.md`, iteration 2026-11-06-0630) and "not briefed this iteration" (`cycle-2026-11-03.md`). [observed]

## Gotchas

- Failure-pattern grep: FP-157
  - FP-157 (a pinned value bypassed a fail-closed guard; cause guard-misses-subject): the same shape from the other side. Here the pinned value made the guard refuse every honest run, and the run went ahead without the guard. The fix must keep a refusal for the case the pin existed for (gate code the entry did not describe).
  - Grep run: `grep -inE 'identity-unknown|git-config|user\.email|image-lag|paste|rev-parse|pinned|moved-main|dev-cycle|free-slot|skill-prose' docs/failure-patterns.md`.
- `git rev-parse` echoes an argument it cannot resolve (and exits 128), and prints nothing outside a repository. So a bare `test "$(git rev-parse HEAD:p)" = "$(git rev-parse M:p)"` refuses a missing path only because the two echoed arguments differ, and passes when both sides print nothing. The paste does not lean on what a failed call prints: each left side goes through `x="$(…)" &&`, which fails on git's exit status. [observed: `git rev-parse HEAD:no/such/path` prints `HEAD:no/such/path`] Both forms show in a test since the paste counts its checks: outside a repository both sides of a bare compare print nothing, so without the loop's `g=… &&` all seven path checks would count there in silence (the tip check alone keeps the count short), and the no-repository case, which expects a refusal for the tip and for every path, fails. The tip test's form is pinned as text as well. [corrected in review, twice]
- The Bash tool here runs zsh, which does not split an unquoted `$P`. The paste writes its path list out, so it does not depend on word splitting, and it was run under both shells.
- `git diff-tree --quiet` and `git status` read the index and so start `core.fsmonitor`; `merge-base`, `rev-list` and `diff-tree` run as a bare command start a pager that `pager.<cmd>` and `core.pager` name. `rev-parse` does neither, bare or in `$( )`. [observed: the planted-state probe below, git 2.39.5] The host's git version is not known from here. [assumed: `rev-parse` behaves the same there; it takes no pager in any version I know of, and in `$( )` its stdout is not a terminal]
- `scripts/confine-tests.sh --probe` exits 3 here. Its first line: `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.` The tests rely on `scripts/run-tests.sh` and `scripts/hermeticity-lint`.

## Design choices

### Item 1: the identity check (two options, no divergent design)

One-line note: reuse `merge_ident`'s command, `git -C WT -c user.useConfigOnly=true var GIT_AUTHOR_IDENT` and the same for `GIT_COMMITTER_IDENT`, over the other option, keeping `git config` and adding "or the four environment variables are set". The second restates git's own lookup order in prose (and would bring `GIT_AUTHOR_NAME` back into the skill, which a test forbids); the first asks git, as the gate does (S3). A set but empty address exits 0 and prints `a <>` (security finding 5), so the skill asks for a name and an address both non-empty, as `merge_ident`'s shape test does.

The cases, run by hand in a scratch repository with no global or system config and an empty environment (`env -i`, `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`), each line the two commands' exit status and what they printed before the timestamp:

```
case 1: neither config nor environment
  AUTHOR exit=128: fatal: no email was given and auto-detection is disabled
  COMMITTER exit=128: fatal: no email was given and auto-detection is disabled
  => STOP
case 2: environment only
  AUTHOR exit=0: EnvA <a@env.invalid>
  COMMITTER exit=0: EnvC <c@env.invalid>
  => pass
case 2b: author in the environment, no committer
  AUTHOR exit=0: EnvA <a@env.invalid>
  COMMITTER exit=128: fatal: no email was given and auto-detection is disabled
  => STOP
case 2c: EMAIL only (git would take it and guess the name)
  AUTHOR exit=128, COMMITTER exit=128 (same message)
  => STOP
case 3: config only
  AUTHOR exit=0: Cfg <cfg@config.invalid>
  COMMITTER exit=0: Cfg <cfg@config.invalid>
  => pass
case 4: name in config, no email anywhere
  => STOP (same message)
case 4b: name in config, email in the environment
  AUTHOR exit=0: Cfg <a@env.invalid>
  COMMITTER exit=0: Cfg <c@env.invalid>
  => pass
email in the environment, no name: fatal: no name was given and auto-detection is disabled
```

(Git's "Please tell me who you are" help text, printed before each `fatal:` line, is cut here.) In this session the new check passes (exit 0, the environment's identity) where the old one printed nothing. The test added on this branch runs the same cases from the skill's own text.

### Item 2: the release paste (divergent design, seeded with `docs/constraints.md`)

**Context.** The paste's test pins M, the cycle's own land moves main past M, so the test fails on a checkout at main's tip. The entry tells the owner to check out M first, and a checkout is the command the paste was built to avoid: in the planted-state probe below it ran `post-checkout`, `reference-transaction`, `post-index-change`, the fsmonitor and the pager. The last two releases were built from main's tip without the test.

**Prior pruning grep:** no matches found for [paste, image-lag, rev-parse, release entry] in `docs/decisions/*.md` "Pruned candidates" sections.

**Candidates.**

0. Status quo: `test "$(git rev-parse HEAD)" = M` (the prior choice, Q-252 and Q-261).
1. Pin the last gate-code commit G (from the idea log): `test "$(git rev-list -1 --first-parent HEAD -- PATHS)" = G`.
2. A first-parent descendant of M with the same gate code (from the idea log): `git merge-base --is-ancestor M HEAD && git diff --quiet M HEAD -- PATHS`.
3. `rev-parse` only: HEAD is main's tip, and each PATHS entry names the same object at HEAD as at M. (As decided, also the installer itself: see the review mitigations below.)
4. As 3 without the tip test: gate-code equality alone.
5. As 3 over every directory the release installs (Q-156's list) instead of PATHS.
6. Write the entry last and pin the land's own commit.
7. No test: `cd A && ./devcontainer-config/install.sh`, leaving step 0.1's checks to find a wrong release afterwards.
8. Move the test into `install.sh` (`--expect-gate M`).
9. A checked-in `scripts/release-check.sh M` that the paste runs.
10. The paste checks M out itself (`git checkout --detach M && …`).
11. The paste installs from a temporary worktree at M.
12. One plumbing call: `git diff-tree --quiet M HEAD -- PATHS`, plus the tip test.
13. As 3 with the six object names written into the paste instead of `M:path`.

**Constraints that bear.** Hard, each with its observable:

- B1 (brief): the paste runs from a checkout at main's tip. success: the test's case "main moved past M by a docs-only commit" runs the stub installer.
- B2 (brief): it refuses a checkout whose gate code is not M's. success: the test's case "gate code changed after M" prints a refusal naming the path and does not run the installer.
- B3 (brief, and repo H1: the check's logic is not sourced from git config, hooks or attributes a session can write): no git command before `install.sh`'s state gate can run a hook, fsmonitor or pager. success: with every hook, `core.fsmonitor`, `core.pager` and `pager.<cmd>` planted, the test's marker file does not exist after the paste.
- repo H2: it fails closed and loudly. success: test cases for a checkout off main's tip, an M the clone lacks, a gate file missing and a directory that is no repository each print "release refused" and do not run the installer.
- repo H3: verifiable hermetically. success: the test extracts the paste from `SKILL.md` and runs it in a scratch repository.
- B4 (brief): no change to `scripts/d6.sh`, no new owner stop, entry or host chore.

Soft: S1 (proportionate; honest slips, not a hostile loop), S3 (one list, one mechanism: the PATHS line and `rev-parse` exist), S4 (mechanical steps in scripts; the brief asks for prose unless prose cannot state the fix), S8 (small; no growth of `install.sh`), S10 (one paste, fewest refusals of an honest run), S11 (plain shell, bash and zsh).

**Match and prune.**

| # | B1 tip | B2 gate | B3/H1 | H2 | H3 | B4 | Verdict |
|---|---|---|---|---|---|---|---|
| 0 | ✗ | ✓ | ⚠ (pushes the owner to `checkout`) | ~ silent | ✓ | ✓ | pruned: B1 |
| 1 | ✓ | ✓ | ~ (`rev-list` bare runs a pager; safe only in `$( )`) | ✓ | ✓ | ✓ | survives, weaker |
| 2 | ✓ | ✓ | ⚠ (`merge-base` bare ran the planted pager) | ✓ | ✓ | ✓ | pruned: B3 |
| 3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | survives |
| 4 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | survives |
| 5 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | survives |
| 6 | ✗ | - | - | - | - | - | pruned: a commit cannot name itself |
| 7 | ✓ | ✗ | ✓ | ✗ | ✓ | ✓ | pruned: B2 |
| 8 | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | pruned: grows `install.sh` (S8), an enforcement file, for a prose fix |
| 9 | ✓ | ✓ | ⚠ (the check's code is in the checkout a session writes) | ✓ | ✓ | ✓ | pruned: H1 |
| 10 | ✓ | ✓ | ⚠ (checkout ran three hooks, fsmonitor, pager) | ✓ | ✓ | ✓ | pruned: B3 |
| 11 | ✓ | ✓ | ⚠ (`worktree add` checks out) | ✓ | ✓ | ✗ (a worktree to clean up, S10) | pruned |
| 12 | ✓ | ✓ | ⚠ (`diff-tree` ran the planted fsmonitor and pager) | ✓ | ✓ | ✓ | pruned: B3 |
| 13 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | folded into 3: six 40-hex names to copy for no gain, since `M:path` is content-addressed |

**Tradeoff among the survivors.**

| | Effort | Risk | Coverage | Key downside |
|---|---|---|---|---|
| 1 last gate commit | one more value for the cycle to compute (G); a second git command to argue | medium: safe only inside `$( )`, and that has to stay true in prose | gate code only; no off-main test unless added | a change and its revert after G refuse though the code is the same |
| 3 tip and PATHS | one loop over the pinned PATHS line | low | gate code, and the checkout is main's | non-gate code committed after M ships unlisted (below) |
| 4 PATHS only | least | low | gate code only | a branch left checked out with M's gate code releases unmerged code; found only afterwards, by `image-off-main` |
| 5 tip and installed dirs | a second pinned list, restating `install.sh`'s arrays, with its own test | low | everything installed | refuses on any hand commit to an installed path after M; the Q-156 paste did, and was then skipped |

Hypotheses. 3: the next two releases run the paste as written from main's tip; counter-evidence is an image whose `commit=` is past M with the entry noting the paste was skipped or refused for a reason other than new gate code. 5: the same, with counter-evidence more likely, since any installed path counts. 4: no `image-off-main` entry is ever filed after a paste; one such entry refutes it. 1: as 3.

**Stress tests.**

- *Boring alternative*: is 4 enough? It drops one test and its message. But the old paste did refuse an off-main checkout (M is on main), and a session or the owner can leave the main checkout on a branch (seven other worktrees and their branches are registered here today). Dropping the tip test is a weakening the brief rules out; it costs one `rev-parse`. 4 loses to 3.
- *Invert the thesis*: argue for 5. The old test meant "the release ships exactly what the entry lists", and `docs/dev-cycle.md` says reviewing the entry is the check on a self-merged `install.sh`. What survives: under 3, code outside PATHS committed after M ships without appearing in any entry, and the installer is the one such file that runs on the host before any review of its own (so it joined the compared paths: mitigations below). What does not: with the image check run again after a step 7 merge (below), main moves past M by cycle lands (docs), a hand commit, another session's merge, or a paste the owner copied from an earlier iteration; both recent releases had one docs merge between M and the build besides the lands. The image-lag trigger itself is keyed on gate code, so one list (S3) defines both when the entry exists and what its paste holds the release to. 5 adds a second list and refuses the owner's own later commits, the friction that got Q-156's paste skipped (S1, S10). 3 stands, with the residual stated.
- *Revealed preferences*: both recent releases were built from a cycle-land commit past M with M's gate code and no path outside `docs/` changed. 3 and 5 would both have run as written; 0 was skipped both times.
- *Failure-driven*: the bypass families, next.

**Bypass families** (the adversarial pass the brief asks for; threat model S1: honest slips by a same-uid loop, with H1 in scope whatever the attacker):

| Family | Covered? |
|---|---|
| A git command in the paste runs something the checkout's `.git` names (hooks, `core.fsmonitor`, a pager, filters, textconv, an external diff) | Covered: the only command is `rev-parse` in `$( )`. Probe: nothing ran. |
| The owner is pushed to another git command to make the paste pass | Covered for the normal case: the checkout is already at main's tip. Off the tip, the owner still has to move it, and the skill keeps the sentence saying that command can run a planted hook. |
| The checkout is on a branch, or behind main | Covered: the tip test refuses, saying so. |
| Gate code moved after the entry was written (a step 7 merge, a hand commit) | Covered: the loop refuses, naming the path; step 7 runs the image check again after a merge, and every iteration writes the paste again in the `image-lag` entry and in an open `image-off-main` entry (a stop repeats it in its final message). |
| The installer changed after M (a self-merged `install.sh` runs on the host before any review of its own) | Covered since the security review: the loop compares `devcontainer-config/install.sh` too, so `docs/dev-cycle.md`'s sentence that reviewing the entry is the check on a self-merged installer still holds. |
| The terminal or a renderer breaks the paste into lines | Covered, in two steps. Security review: with `exit 1`, a break between the two words printed the refusal and then ran the installer. Confirming pass: with `( … ) && ./devcontainer-config/install.sh`, a copy broken in two or more places, typed into an interactive shell already in the checkout, hit a syntax error that dropped the checks, and the last line, the installer alone, ran (62 of 274 widths). Last confirming pass: as one quoted word with `&&` chains, a copy with CR LF line ends piped to a shell ran the line after a CR on its own, and installed. Now the paste is one quoted word, each count sits inside an `if`, and the installer inside a `case` arm. Test: typed into an interactive bash sitting in the checkout, and piped with CR LF ends into `sh`, with a break before each word and folded at 40 to 240 columns, it never installs from a refusing checkout. By hand: the sweeps under "The break sweeps" below. |
| Fail-open on a failed read (no repository, M absent, a path absent, git missing) | Covered: each left side is taken through `&&` on git's exit status, and an unresolved right side prints its own argument, which never equals an object name. |
| The shell runs the installer after a refusal (`a && b \|\| c` precedence) | Covered: no refusal leads anywhere; the installer sits in the `case` arm that matches a count of nine, and each check adds to the count only when both reads succeed and agree. Test: the stub installer's marker is absent after each refusal. |
| A is wrong or missing while the shell sits in another checkout that passes | Covered: the `cd` is one of the nine counted checks. Test: run from a passing checkout with an A that is not there, nothing installs. An A written as empty or `.` is not refused: `cd` succeeds, and the paste installs from the shell's own directory when that is a checkout that passes every other check. Harmless. |
| The orchestrator mistypes the paste | Partly: a wrong path, a short id that does not resolve, the literal `M` or an empty M refuses. A symbolic M (`HEAD`, `main`) compares the checkout with itself and passes: the skill asks for all 40 hex digits, and the paste does not enforce it. A paste with the checks dropped is prose's risk, as today; the test pins the skill's line. |
| PATHS drifts from `GATE_CODE` | Covered: the existing test pins the line, and the new test builds the paste from that line. |
| HEAD moves between the test and the install | Not covered by the paste; `install.sh` refuses while a session runs, and the manifest's `commit=` shows what was built, which step 0.1 reads next. |
| Uncommitted edits in the checkout | Covered by `install.sh`: it installs HEAD's committed content and lists the rest as not included. |
| Code outside PATHS and the installer committed after M ships unlisted (also through a paste copied from an earlier iteration, which passes while gate code and installer are unchanged) | Not covered, by choice (candidate 5 covers it): the stated residual. |
| The orchestrator writes an empty M | Refuses, through the two directory entries (`:scripts/lib/` names no index entry; the five file entries do resolve from the index and count). With a planted `core.fsmonitor` that index read starts it: out of scope (S1), found by the security review. |
| A planted promisor remote (`extensions.partialClone` with a `remote.x.uploadpack` program) and an object the clone lacks | Not covered, and out of scope (S1: a hostile session). Found by the test-strategy pass and confirmed: `git rev-parse "M:p"` for an M the clone lacks ran the planted program; with M present nothing ran. The old flow has the same reach one step later: `install.sh`'s `git archive` of HEAD ran it when one of HEAD's objects was gone, and its state gate reads no promisor key. What is new is one trigger, an M the clone lacks, and the session that would plant this also writes the paste. `GIT_NO_LAZY_FETCH=1` stopped it on git 2.39.5; not added: S1 puts a hostile session out of scope, and the installer's own archive has the same reach. |
| A mode-only change to one of the five file entries (a blob's name holds no mode) | Not covered, harmless: the image build sets every `.sh` file to 0555, and the two directory entries do refuse a mode change inside them. |
| The orchestrator writes the paste with a short or empty path list | Covered since the count: fewer paths than seven leave it under nine, nothing installs, and the last line says how many of the nine checks passed. |
| The owner's shell exports `CDPATH` | Covered: the installer starts as `./devcontainer-config/install.sh`, as before the branch. Started without `./` (one form this branch tried), its own `cd` to its directory followed `CDPATH` and it died. |
| A break inside the installer's path makes part of it a lookup on `PATH` | Covered: the path sits inside the `case` arm, reached only at a count of nine. |
| Planted refs, replace refs, grafts, alternates (a hostile session) | Out of scope (S1), listed once. `M:path` is content-addressed, so only a replace ref or a forged `refs/heads/main` reaches it (the security review ran the replace-ref case: the installer ran with changed gate code). |

**Decision (Path A): candidate 3, with the installer among the compared paths.** The paste, with A, M and PATHS written out:

```
sh -c 'n=0; if cd "A"; then n=1; fi; if h="$(git rev-parse HEAD)" && test "$h" = "$(git rev-parse refs/heads/main)"; then n=$((n+1)); else echo "release refused: this checkout is not at the tip of main"; fi; for p in PATHS devcontainer-config/install.sh; do if g="$(git rev-parse "HEAD:$p")" && test "$g" = "$(git rev-parse "M:$p")"; then n=$((n+1)); else echo "release refused: $p changed after M: run the dev cycle for a new paste"; fi; done; case "$n" in 9) ./devcontainer-config/install.sh;; *) echo "release refused: $n of 9 checks passed"; false;; esac'
```

It keeps the one command the skill already argues for, reuses the PATHS line, refuses loudly, and runs from where the checkout already is. Its shape came from the review, in three steps (mitigations below): the whole of it is one single-quoted word handed to `sh`; each check adds to a count inside an `if`; and the installer sits in the arm of a `case` that matches only a count of nine (the `cd`, the tip, PATHS' six and the installer). Nothing follows a bare `&&` and nothing exits early, so a line break, with an LF or a CR LF end, cannot part a count or the installer from its condition. See alternatives considered → the matrix above.

**Pruned candidates and why.** Each entry is `[candidate]: reason`. [0]: cannot pass at main's tip, and sends the owner to `checkout`. [1]: needs a second command that is safe only in `$( )`, and a second value. [2]: `merge-base` run bare starts a planted pager. [4]: lets an off-main checkout release. [5]: a second list, and the refusals that got Q-156's paste skipped. [6]: a commit cannot name itself. [7]: no refusal. [8]: grows `install.sh`. [9]: check code in an agent-writable checkout. [10], [11]: a checkout runs hooks. [12]: `diff-tree` starts a planted fsmonitor and pager. [13]: same check as 3 with more to copy.

**Stress-test mitigations.** How to read: *Invert the thesis* mitigation: step 7 runs the image check again after a merge, which keeps this cycle's own merges out of candidate 3's residual. How to read: *Failure-driven* mitigations from the review (iteration 1): the installer joined the compared paths (security finding 2: an installer changed after M ran on the host unlisted); the refusals became `false; exit` (security finding 1: a wrapped line refused and then installed); the refusal's message stopped promising a rewrite, and every iteration writes the paste again in the `image-lag` entry and in an open `image-off-main` entry (consistency finding 1, security finding 4: an `image-off-main` entry's paste was filed once and would have refused for good). From the confirming pass (iteration 2): the paste became one quoted word run by `sh -c`, with the installer behind a count of every check and no early exit (finding F1, above); its refusal names the way forward ("run the dev cycle for a new paste"); A is quoted; step 7's rerun says what happens to an entry the same iteration filed. From the last confirming pass (iteration 3): each count and the installer moved inside an `if` or the `case` (its finding 1: a CR after `&&` ran the next line alone, 135 installs in 21,260 runs with CR LF ends); the installer got its `./` back, now safe inside the `case` arm (without it an exported `CDPATH` broke the installer's own `cd`); a refusal ends by saying how many of the nine checks passed, so a short path list no longer refuses in silence; the skill asks for M in full. The same class of finding, a broken copy that installs, came back in each of the three passes; the rubric records that, what was done about its cause, and that no reviewer read the final shape.

**Consequences.** Easier: a release is the paste, from where the checkout is. Harder: the paste is about 560 characters as a template and about 800 written out, copied from the skill by the orchestrator onto one line of a fenced block; a test pins the line and runs it, broken into lines too. Residual risk, stated once (S1) and written into the skill beside the paste: code outside the six gate-code paths and the installer that reaches main after the entry's M ships with that release without appearing in the entry. Decision log row 86 records the choice and its revisit triggers. [corrected in review: an earlier draft, and commit f5eef430's Notes line, said an in-flight branch appends to the log; it edits row 53 in place]

**Revisit triggers.** Each entry is an observable condition. if an image's `commit=` names a commit with gate code other than the entry's M. if an `image-off-main` entry is filed after a paste ran. if the owner reports a release that shipped a self-merge the entry did not flag. if `GATE_CODE` gains a path that does not exist at some M (the paste would refuse until it does). if `GATE_CODE` loses a path (an older image's skill would still write it into the paste, which then refuses until an install by hand).

**The paste's cases**, run by hand in a scratch repository under bash and again under zsh (the same output from both, and the test adds `sh`; M is the scratch repository's base commit). These runs predate the review: the paste was then a subshell with `exit 1`, its message read "is not as at M", the installer was not yet compared, and it stopped at the first refusal where it now names every path that differs. The test holds the current text and runs every case again:

```
1. at M:                                        INSTALL RAN                                           exit=0
2. main's tip, one docs-only land past M:       INSTALL RAN                                           exit=0
3. main's tip, non-gate code past M:            INSTALL RAN                                           exit=0
4. a branch checked out, same gate code:        release refused: this checkout is not at main's tip   exit=1
5. detached at M while main is past it:         release refused: this checkout is not at main's tip   exit=1
6. main's tip, gate code past M:                release refused: scripts/lib/ is not as at M          exit=1
7. main's tip, a gate file gone:                fatal: path 'scripts/d6.sh' does not exist in 'HEAD'
                                                release refused: scripts/d6.sh is not as at M         exit=1
8. an M this clone does not hold:               fatal: path 'scripts/build-loop.sh' exists on disk, but not in '0123…'
                                                release refused: scripts/build-loop.sh is not as at 0123…  exit=1
9. not a git checkout:                          fatal: not a git repository (or any of the parent directories): .git
                                                release refused: this checkout is not at main's tip   exit=1
```

Case 3 is the residual. Case 5 is the state the old entries asked the owner to make.

**The planted-state probe** (every hook git 2.39.5 knows in `.git/hooks`, `core.fsmonitor`, `core.pager` with `pager.<cmd>=true` for each command, `diff.external`, a textconv; each command run with its output on a terminal through `script(1)`, as a paste runs it):

```
rev-parse in $( ), the paste as written: nothing ran
rev-parse run bare (not in $( )): nothing ran
diff --quiet M HEAD -- PATHS: nothing ran
diff-tree --quiet M HEAD -- PATHS: fsmonitor,pager
merge-base --is-ancestor M HEAD: pager
rev-list -1 --first-parent HEAD -- PATHS: pager
rev-list in $( ): nothing ran
status --porcelain: fsmonitor,hook post-index-change,pager
checkout M (what the old paste made the owner do): fsmonitor,hook post-checkout,hook post-index-change,hook reference-transaction,pager
```

**The promisor probe** (`extensions.partialClone`, a promisor remote whose `uploadpack` is a planted program):

```
old paste: rev-parse HEAD: exit 0; nothing ran
new paste, honest: rev-parse HEAD:p and M:p, M present: exit 0; nothing ran
new paste, an M the clone lacks: exit 128; promisor-program
the same with GIT_NO_LAZY_FETCH=1: exit 128; nothing ran
old flow, HEAD's tree object gone: rev-parse HEAD: exit 0; nothing ran
old flow, HEAD's tree object gone: install.sh's archive of HEAD: exit 128; promisor-program
```

**The break sweeps** (the paste as decided; 865 characters written out for a 126-character checkout path, template 559; each variant fed on the shell's standard input from inside the checkout, with the checkout in each of three refusing states: off main's tip, gate code changed after M, installer changed after M; under `bash -s`, `bash -i`, `sh -s`, `sh -i`, `zsh -s` and `zsh -i`; a run counts as an install when the stub installer ran). Variants: word wrap and hard wrap at every second width (30 or 20 to 520 columns), one break at every character, and 300 random sets of two to five breaks; each with LF and with CR LF line ends.

```
wordwrap, lf ends: 0 installs in 4428 runs
wordwrap, crlf ends: 0 installs in 4428 runs
hardwrap, lf ends: 0 installs in 4518 runs
hardwrap, crlf ends: 0 installs in 4518 runs
onechar, lf ends: 0 installs in 15552 runs
onechar, crlf ends: 0 installs in 15552 runs
random, lf ends: 0 installs in 5400 runs
random, crlf ends: 0 installs in 5400 runs
```

That is 0 installs in 59,796 runs. Unbroken, the paste installed at main's tip under all six shells with LF ends; with CR LF ends it installed only under interactive bash and failed, closed, under the others (the CR joins the quoted word). The history of the shape, for comparison: the paste before this branch (one `test`, about 120 characters) had no break that installed; the first paste here (`( … exit 1 … ) && ./devcontainer-config/install.sh`) installed when broken between `exit` and `1`; with `false; exit` it installed at 62 of 274 widths in an interactive shell sitting in the checkout (the second reviewer's sweep, not kept in the repository); as one quoted word with `&&` chains it had 0 installs in 41,094 LF runs here and 188,074 by the last reviewer, and 135 in that reviewer's 21,260 runs with CR LF ends.

