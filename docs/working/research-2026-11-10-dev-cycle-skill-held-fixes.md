# Research: three small dev-cycle skill fixes that waited on the release

**Goal**: fix three passages of `skills/dev-cycle/SKILL.md` that every recent iteration worked around: the identity check, the release paste's pinned commit, and the record's silence about a free slot.
**Problem framing**: each passage asks the orchestrator, or the owner, for something that cannot be done as written, so it is skipped or worked around and guards nothing. Considered and discarded: "the orchestrator is not following the skill" (the records show it tried each one as written, and the workaround was the only way on).
**Project state**: this branch delivers the three prose fixes and the tests that run the skill's own commands · standalone, from the roadmap's Now item "after the Q-261 release" · not blocked (cite: docs/working/briefs/2026-11-10-dev-cycle-skill-held-fixes.md)
**Task status**: in-progress (implemented; review-fix loop next)

## What exists

- `skills/dev-cycle/SKILL.md` is the orchestrator's whole procedure, and it is gate code (`GATE_CODE` in `scripts/lib/dev-cycle-read.sh`), so this branch comes to the owner as a `merge-gate-` entry and its text runs only after the next image release. [observed]
- **Item 1.** The Rules bullet "The orchestrator's git" (lines 66-69 at a37733cc) says `git -C WT config user.email` and `… user.name` must each print one, and none is a stop. [observed] In this sandbox both print nothing: `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME` and `GIT_COMMITTER_EMAIL` are set and git config holds no `user.*`. [observed: `env`, `git config user.email`] The records since iteration 2026-11-05-2347 say "Identity from the environment" and go on. [observed: `docs/working/cycles/cycle-2026-11-06.md`]
- The gate's own check is `merge_ident` in `scripts/build-loop.sh` (line 1547): `git -c user.useConfigOnly=true var GIT_AUTHOR_IDENT`, and the same for the committer, refusing when either fails. Its comment says why the flag: without it git takes `EMAIL` or guesses from the passwd entry and the host's domain. `test/scripts/build-loop-merge.bats` lines 94-103 hold its three cases. [observed]
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
- Q-156's paste (2026-10-14, `docs/working/questions-archive.md`) compared, with `rev-parse` only, each installed directory's tree at HEAD with M's, plus checks for replace refs, grafts and `core.attributesFile`. It refused on the day ("devcontainer-config differs from M": later merges had moved released paths), and the owner then installed from main without the paste. The restriction audit later cut the paste to today's single test.
- The last two releases, checked from the manifest history: Q-252's paste pinned `3a663f88` and the image was built from `dff98910`; Q-261's pinned `3dbf43cb` and the image was built from `536b7082`. Both builds are cycle-land commits past the pinned M with M's gate code (`git diff --quiet M C -- PATHS` exits 0 for both). [observed] So the pinned test cannot have passed either time: the owner released from main's tip without it.
- The orchestrator already rewrites the entry after a merge in the same iteration: "Q-261 rewritten for M 771c84e8, after the merge below" (`docs/working/cycles/cycle-2026-11-06.md`, iteration 2026-11-07-0621). [observed]
- Records already give a reason for a free slot when the orchestrator thinks of it: "queue 0/3. The rest of Now waits on the owner, a host run or a choice." (`cycle-2026-11-06.md`), against "queue 0/3." alone (`cycle-2026-11-05.md`, iteration 2026-11-06-0630) and "not briefed this iteration" (`cycle-2026-11-03.md`). [observed]

## Gotchas

- Failure-pattern grep: FP-157
  - FP-157 (a pinned value bypassed a fail-closed guard; cause guard-misses-subject): the same shape from the other side. Here the pinned value made the guard refuse every honest run, and the run went ahead without the guard. The fix must keep a refusal for the case the pin existed for (gate code the entry did not describe).
  - Grep run: `grep -inE 'identity-unknown|git-config|user\.email|image-lag|paste|rev-parse|pinned|moved-main|dev-cycle|free-slot|skill-prose' docs/failure-patterns.md`.
- `git rev-parse` echoes an argument it cannot resolve (and exits 128), and prints nothing outside a repository. So a bare `test "$(git rev-parse HEAD:p)" = "$(git rev-parse M:p)"` refuses a missing path only because the two echoed arguments differ, and passes when both sides print nothing. The paste does not lean on what a failed call prints: each left side goes through `x="$(…)" &&`, which fails on git's exit status. [observed: `git rev-parse HEAD:no/such/path` prints `HEAD:no/such/path`; a mutation that dropped the `&&` form still passed every test case, so the form is structure, not something a case here can tell apart]
- The Bash tool here runs zsh, which does not split an unquoted `$P`. The paste writes its path list out, so it does not depend on word splitting, and it was run under both shells.
- `git diff-tree --quiet` and `git status` read the index and so start `core.fsmonitor`; `merge-base`, `rev-list` and `diff-tree` run as a bare command start a pager that `pager.<cmd>` and `core.pager` name. `rev-parse` does neither, bare or in `$( )`. [observed: the planted-state probe below, git 2.39.5] The host's git version is not known from here. [assumed: `rev-parse` behaves the same there; it takes no pager in any version I know of, and in `$( )` its stdout is not a terminal]
- `scripts/confine-tests.sh --probe` exits 3 here. Its first line: `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.` The tests rely on `scripts/run-tests.sh` and `scripts/hermeticity-lint`.

## Design choices

### Item 1: the identity check (two options, no divergent design)

One-line note: reuse `merge_ident`'s command, `git -C WT -c user.useConfigOnly=true var GIT_AUTHOR_IDENT` and the same for `GIT_COMMITTER_IDENT`, over the other option, keeping `git config` and adding "or the four environment variables are set". The second restates git's own lookup order in prose (and would bring `GIT_AUTHOR_NAME` back into the skill, which a test forbids); the first asks git, as the gate does (S3).

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
3. `rev-parse` only: HEAD is main's tip, and each PATHS entry names the same object at HEAD as at M.
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
- *Invert the thesis*: argue for 5. The old test meant "the release ships exactly what the entry lists", and `docs/dev-cycle.md` says reviewing the entry is the check on a self-merged `install.sh`. What survives: under 3, code outside PATHS committed after M ships without appearing in any entry. What does not: with the entry written again after a step 7 merge (below), main moves past M only by cycle lands (docs), a hand commit, or another session's merge, and the first cannot touch code. The image-lag trigger itself is keyed on gate code, so one list (S3) defines both when the entry exists and what its paste holds the release to. 5 adds a second list and refuses the owner's own later commits, the friction that got Q-156's paste skipped (S1, S10). 3 stands, with the residual stated.
- *Revealed preferences*: both recent releases were built from a cycle-land commit past M with M's gate code and no path outside `docs/` changed. 3 and 5 would both have run as written; 0 was skipped both times.
- *Failure-driven*: the bypass families, next.

**Bypass families** (the adversarial pass the brief asks for; threat model S1: honest slips by a same-uid loop, with H1 in scope whatever the attacker):

| Family | Covered? |
|---|---|
| A git command in the paste runs something the checkout's `.git` names (hooks, `core.fsmonitor`, a pager, filters, textconv, an external diff) | Covered: the only command is `rev-parse` in `$( )`. Probe: nothing ran. |
| The owner is pushed to another git command to make the paste pass | Covered for the normal case: the checkout is already at main's tip. Off the tip, the owner still has to move it, and the skill keeps the sentence saying that command can run a planted hook. |
| The checkout is on a branch, or behind main | Covered: the tip test refuses, saying so. |
| Gate code moved after the entry was written (a step 7 merge, a hand commit) | Covered: the PATHS loop refuses, naming the path; the cycle writes the entry again after a step 7 merge. |
| Fail-open on a failed read (no repository, M absent, a path absent, git missing) | Covered: each left side is taken through `&&` on git's exit status, and an unresolved right side prints its own argument, which never equals an object name. |
| The shell runs the installer after a refusal (`a && b \|\| c` precedence) | Covered: the checks sit in a subshell that exits 1, joined to the installer by `&&`. Test: the stub installer's marker is absent after each refusal. |
| The orchestrator mistypes the paste | Partly: a wrong M or path refuses. A paste with the checks dropped is prose's risk, as today; the test pins the skill's line. |
| PATHS drifts from `GATE_CODE` | Covered: the existing test pins the line, and the new test builds the paste from that line. |
| HEAD moves between the test and the install | Not covered by the paste; `install.sh` refuses while a session runs, and the manifest's `commit=` shows what was built, which step 0.1 reads next. |
| Uncommitted edits in the checkout | Covered by `install.sh`: it installs HEAD's committed content and lists the rest as not included. |
| Code outside PATHS committed after M ships unlisted | Not covered, by choice (candidate 5 covers it): the stated residual. |
| A planted promisor remote (`extensions.partialClone` with a `remote.x.uploadpack` program) and an object the clone lacks | Not covered, and out of scope (S1: a hostile session). Found by the test-strategy pass and confirmed: `git rev-parse "M:p"` for an M the clone lacks ran the planted program; with M present nothing ran. The old flow has the same reach one step later: `install.sh`'s `git archive` of HEAD ran it when one of HEAD's objects was gone, and its state gate reads no promisor key. What is new is one trigger, an M the clone lacks, and the session that would plant this also writes the paste. `GIT_NO_LAZY_FETCH=1` stopped it on git 2.39.5; not added, since the restriction audit (Q-259) took hostile-only checks out of the paste. |
| A mode-only change to one of the four file entries (a blob's name holds no mode) | Not covered, harmless: the image build sets every `.sh` file to 0555, and the two directory entries do refuse a mode change inside them. |
| The orchestrator writes the paste with an empty path list | Not covered beyond the template: a loop over nothing passes, leaving the tip test alone. The test pins `for p in PATHS;` in the skill's line. |
| Planted refs, replace refs, grafts, alternates (a hostile session) | Out of scope (S1), listed once. `M:path` is content-addressed, so only a replace ref or a forged `refs/heads/main` reaches it. |

**Decision (Path A): candidate 3.** The paste, with A, M and PATHS written out:

```
cd A && ( h="$(git rev-parse HEAD)" && test "$h" = "$(git rev-parse refs/heads/main)" || { echo "release refused: this checkout is not at main's tip"; exit 1; }; for p in PATHS; do g="$(git rev-parse "HEAD:$p")" && test "$g" = "$(git rev-parse "M:$p")" || { echo "release refused: $p is not as at M; the next dev-cycle iteration rewrites this paste"; exit 1; }; done ) && ./devcontainer-config/install.sh
```

It keeps the one command the skill already argues for, reuses the PATHS line, refuses loudly, and runs from where the checkout already is. See alternatives considered → the matrix above.

**Pruned candidates and why.** Each entry is `[candidate]: reason`. [0]: cannot pass at main's tip, and sends the owner to `checkout`. [1]: needs a second command that is safe only in `$( )`, and a second value. [2]: `merge-base` run bare starts a planted pager. [4]: lets an off-main checkout release. [5]: a second list, and the refusals that got Q-156's paste skipped. [6]: a commit cannot name itself. [7]: no refusal. [8]: grows `install.sh`. [9]: check code in an agent-writable checkout. [10], [11]: a checkout runs hooks. [12]: `diff-tree` starts a planted fsmonitor and pager. [13]: same check as 3 with more to copy.

**Stress-test mitigations.** How to read: *Invert the thesis* mitigation: added the sentence that step 7's merge has the image check run again, so M trails main only by cycle lands, which narrows candidate 3's residual to hand commits and other sessions' merges.

**Consequences.** Easier: a release is the paste, from where the checkout is. Harder: the paste is about 480 characters, copied from the skill by the orchestrator; a test pins the line and runs it. Residual risk, stated once (S1) and written into the skill beside the paste: code outside the six gate-code paths that reaches main after the entry's M ships with that release without appearing in the entry. No decision-log row: an in-flight branch (`feat/q125-sandbox-on-main`) appends to `docs/decisions/log.md`, and a second append would conflict at merge; this section is the record.

**Revisit triggers.** Each entry is an observable condition. if an image's `commit=` names a commit with gate code other than the entry's M. if an `image-off-main` entry is filed after a paste ran. if the owner reports a release that shipped a self-merge the entry did not flag. if `GATE_CODE` gains a path that does not exist at some M (the paste would refuse until it does).

**The paste's cases**, run by hand in a scratch repository under bash and again under zsh (the same output from both, and the test adds `sh`; M is the scratch repository's base commit; the first runs printed "is not as at M" alone, before the message gained its second half):

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

### Item 2, second choice: the entry after a step 7 merge (two options)

One-line note: add the sentence "a step 7 merge moves main: run the image check again before step 9 stages", over leaving the entry at step 0.1's M. Without it, the release that follows an approved gate merge is refused at main's tip until another iteration runs; the records show the orchestrator already rewrites the entry there (prior art above).

### Item 3: the free slot (two options)

One-line note: one clause on the record's `8.` line and one sentence in step 8, over a `### Free slots` section in the template, which the brief rules out. The clause gives the reason once when it is the same for every free slot.

## Failure patterns

Two `fix(...)` commits earn an entry each in `docs/failure-patterns.md`: FP-177 (the identity check modelled one of git's two identity sources) and FP-178 (a guard pinned to a value its own workflow moves, refused every honest run and was skipped).

## Files read

Last verified: 2026-11-10
skills/dev-cycle/SKILL.md
docs/dev-cycle.md
docs/constraints.md
docs/failure-patterns.md
docs/roadmap.md
docs/working/idea-log.md
docs/working/questions-archive.md
docs/working/cycles/cycle-2026-11-03.md
docs/working/cycles/cycle-2026-11-05.md
docs/working/cycles/cycle-2026-11-06.md
docs/working/cycles/cycle-2026-11-07.md
docs/working/research-2026-11-01-relax-dev-cycle-skill-prose.md
docs/working/research-2026-11-06-codify-trial-practices.md
docs/reviews/security-review-2026-10-14-u5-i2.md
docs/decisions/log.md
scripts/build-loop.sh
scripts/lib/dev-cycle-read.sh
devcontainer-config/install.sh
hooks/live-verify-gate.sh
test/scripts/build-loop-orchestrator.bats
test/scripts/build-loop-merge.bats
test/lib/build-loop-fixtures.bash
workflows/research-plan-implement.md
workflows/divergent-design.md
workflows/pr-prep.md
