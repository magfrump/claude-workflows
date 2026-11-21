# Research: the first quarterly threat-model walkthrough

Brief: `docs/working/briefs/2026-11-20-threat-model-walkthrough-prep.md` (read at 7dc44a6c)
Branch: docs/threat-model-walkthrough-prep
Date: 2026-11-20
Status: complete. Research only: no code, test, skill, workflow or instruction file changed.

Failure-pattern grep: `rg -n '^- \*\*FP-' docs/failure-patterns.md | rg -i 'residual|doc-claim|stale-doc|drift|trust|same-uid|threat'` matched FP-089 (count claims drift across the documents that cite them) and FP-073 (a guard deferring to deny rules that were never wired). Both shaped this doc: counts below are dated "as of 2026-11-20" and each check reads git or the installed file itself, and R2's check reads the installed deny rules rather than the repo's copy.

## 1. Motive (S5)

The owner answered Q-340 [1] on 2026-11-20 (Q-340: whether to schedule a quarterly walkthrough of the risks they accepted; [1] = schedule it, the first now). The reason given, in the T12 verdict quoted in that entry (T12 is the weekly digest's "what the checks caught" trial, `docs/working/trials/2026-11-06-attention-and-trust.md`): it "doesn't really address the chain of trust between the reports and the facts in the code". So the bar for this material is not a summary of what the cycle reports. Each check in §4 is a command that reads git, the installed settings or the image directly, so the owner can confirm the fact without trusting a cycle record. Where only a record exists, the row says so.

The status quo (no walkthrough) was the owner's to reject and they did; this doc does not revisit that.

## 2. Sources read

- `docs/working/plan-build-loop-handoff.md`: "What the gate can and cannot do", the bypass-family table F1-F59 and its "Not covered / Partly" summary, the U2-U5 "As built" notes, Risks and Rollback.
- `docs/working/questions-archive.md`: Q-103 (the build-loop policy entry, answered [2] self-merge on 2026-10-17, which lists the residual families) and the entries that name it: Q-140 (D6 runs the image copy), Q-149 (never line narrowed to `workflows/`), the planted-state pass entry near line 2759, the R6-R9 entry near line 2517, Q-213 (constraints-builder).
- `docs/decisions/log.md` rows 53, 72, 73, 74, 79, 81, 83, 88 (the ones that accept or move a residual).
- `scripts/build-loop.sh` header (`--main-log`, F19) and the state-gate comment; `scripts/lib/dev-cycle-read.sh` `git_harden` (the gate's git trust model) and the FENCE_AWK note that puts contrived markup out of scope under S1.
- `devcontainer-config/install.sh` header and its no-agent gate comment; `docs/decisions/037-bare-host-copy-install.md` "Trust model (Q-058)" and "Residuals accepted".
- `skills/dev-cycle/SKILL.md` lines naming Q-103 (the D6 block's PATH residual, step 0.2's bootstrap, step 10's lost dispatch count, the `⚠ SECURITY` trigger).
- `docs/constraints.md` S1 and S10; `docs/working/research-2026-11-19-area-b-ask-habituation.md` §6 (idea B8).

## 3. The residual table

"S1" marks a residual reachable only by a deliberately hostile same-uid author, which `docs/constraints.md` S1 puts out of scope ("Gates defend against honest slips by a same-uid loop, not a deliberately hostile one"). Those are grouped in the walkthrough and asked once. Row numbers in the "Accepted" column are rows of `docs/reviews/override-log.md` unless they say "log row" (the decision log, `docs/decisions/log.md`). The check column names a check in §4, where the command and today's result are.

| # | Residual, in one line | Accepted | Becomes live when | Check | S1 |
|---|---|---|---|---|---|
| R1 | A commit reaches main outside the gate (an honest wrong-directory commit, or a hand commit); the cycle records it and goes on | Q-103 [2] (F19), log rows 72, 74 | A first-parent non-merge commit on main that you did not make and that is not an answers or records commit | C1 | half: a disguised answers commit is S1 |
| R2 | A loop steered by text in a brief or doc acts outside git; the plan says that is "bounded only by the sandbox", but cc-isolated has no Claude Code Bash sandbox, so the bound is the container plus `permissions.deny` and the approve hook | Q-103 [2] (F21), log rows 53, 88 | A file outside a loop's worktree changed by a loop, or a deny rule missing from the installed settings | C2 | no |
| R3 | A loop uses the session's other tools (push, publish, schedule, spawn) that its prompt forbids; it shares the orchestrator's permission mode | Q-103 [2] (F35) | A remote branch, artifact or schedule you did not create | C3 | no |
| R4 | Self-merged code takes effect without your review: `test/` and `scripts/` run in the next health check, and gate code and `install.sh` reach running sessions at the next release, whose review is the only gate | Q-103 [2] (F58), Q-149 [2], H1's interim exception | A code-touching self-merge you do not recognise, or a release you approved without reading its flagged self-merges | C4 | no |
| R5 | An instruction file's `@`-import puts a doc on the self-merge floor; the walk has known gaps (A5) and merge entries flag floor paths by class, not reason | Q-103 [2] (F11), rows 797, log row 83 | Any instruction file gains an `@` import, or Claude Code changes its import grammar | C5 | no |
| R6 | A worktree with main checked out switches branch between the gate's check and its fast-forward | Q-103 [2] (F29) | A worktree other than `/workspace` holds main, or a gate merge disturbs a checkout | C6 | no |
| R7 | Two orchestrators or a restart: a Q-ID minted twice, a dispatch count one low after a lost session, `--prompt --steal` taking a live loop idle for two hours | Q-103 [2] (F37), rows 786, 787 | `questions.sh check` reports a duplicate, a brief runs more than 4 loops, or one loop branch carries two sessions' commits between markers | C7 | no |
| R8 | Quiet constraint drift in decisions loops make alone (divergent design's Path A); a sampled drift check is the only look | Q-103 [2] (F59), plan D2 | A drift-check finding, or drift checks stop running | C8 | no |
| R9 | A rewrite of main restarts `--main-log`'s history check from scratch; across sessions nothing anchors it | Q-103 [2] (row 784), SKILL step 0.2 | A reset, rebase or forced update in main's reflog | C9 | half: a deliberate rewrite is S1 |
| R10 | Short windows in the cycle's own steps: `--start` reads main seconds after the last `--main-log`; `--answered` accepts any ID, so only skill text stops a merge entry being landed as answered | Q-103 [2] (rows 801, 802) | A `merge-` entry archived as answered with no answer line of yours | C10 | no |
| R11 | `install.sh`'s no-agent gate samples processes at four moments by command line, so it misses an agent between checks, a helper outside the checkout, a renamed binary or another PID namespace | decision 037 "Trust model (Q-058)", Q-061, Q-062, Q-064 | An install run from inside a container or sandbox terminal, or with a helper you left running | C11 | no |
| R12 | The constraints-builder skill trusts the operator's own repos: a repo's git config could run a command during a run | log row 73, Q-213 [1] | The skill is run on a repo not solely written by you and your own agents | C12 | no |
| R13 | A same-uid writer races the gate's temp directory (`GATE_TMP`: its git config, refs, HEAD, err, diff and `--approved`'s answer file) | Q-103 [2] (R8; rows 509, 684) | Only a hostile process | none | S1 |
| R14 | Planted git state the gate reads less carefully than git: the worktree registry, objects rewritten in place or a second copy (object re-hashing was removed), `core.bare` with the index deleted, a rebase todo with an `update-ref main` line, grafts, hooks around the orchestrator's commit, a FIFO for the health-check lock | Q-103 [2] (U2b3a, U3a1, U3a2, rows 548, 668, 749, 750), log row 79, plan D6 amendment of 2026-11-05 | Only a hostile process | none | S1 |
| R15 | A same-uid shell's PATH, exported functions or settings around the D6 block (the step that runs the image's gate) | Q-140 [1], Q-103 [2] (U4c), SKILL "The D6 block" | Only a hostile process | none | S1 |
| R16 | Markup built to hide a key line from the gate's readers (a line a renderer hides but the reader trusts, or the reverse) | log rows 69, 81; `scripts/lib/dev-cycle-read.sh` FENCE_AWK note | Only a hostile author | none | S1 |

R1 and R9 are split: the honest half (a slip, an accidental reset) is in scope and has a check; the deliberate half (a commit shaped like an answers commit, a hidden rewrite) is S1.

## 4. Checks, with today's results

Every check below was run (or read) in this worktree on 2026-11-20 against main at 7dc44a6c unless it says "host" or "you". A good result is what the owner should expect to see; today's result says what it was.

- **C1 (R1).** `git log --first-parent --no-merges --since=<last walkthrough> --format='%h %ad %<(40,trunc)%s %(trailers:key=Claude-Session,valueonly,separator=%x2C)' --date=short main`. Every commit uses your identity, so the session trailer is what tells them apart. Good: untrailered lines are commits you made; each trailered line is an answers or records commit, or work you asked a session for. Today, since 2026-11-13: 20 such commits, the top two untrailered (`harness feedback docs`, `answers`), the rest trailered docs work from two sessions. The cycle's own view of the same thing is the `### Other commits on main` section in `docs/working/cycles/` (present in the 2026-11-20 record), but C1 reads git, not that record.
- **C2 (R2).** `rg -n 'credentials' ~/.claude/settings.json` (the installed file, not the repo's `hooks/wiring.json`). Good: the `Read(...credentials.json)` and `Bash(*.credentials.json*)` deny lines are there. Today: 3 lines, both rules present. Then read log row 88's revisit trigger ("if Claude Code's sandbox lets `git worktree add` and commits inside worktrees work"): good is that it has not fired. This is the one residual whose stated bound has changed since it was accepted: Q-103 says F21 is "bounded only by the sandbox", and row 88 (2026-11-12) keeps no sandbox in cc-isolated.
- **C3 (R3).** `git reflog show refs/remotes/origin/main | rg -c 'update by push'`. Good: no output (zero). Today: zero; every entry is a `fetch: fast-forward`. A push by URL leaves no trace here, so add the host-side look: on GitHub (host, you), the repo's branch list holds only branches you pushed. Also `/artifacts` in a terminal session (you): no artifact a build loop published.
- **C4 (R4).** `git log --first-parent --diff-merges=first-parent --grep='build-loop self-merge' --name-only --format='@%h %s' main | rg '^(@|scripts/|test/|hooks/|devcontainer-config/)'`, then read the `@` lines that have paths under them. Good: each is a change you recognise from the digest or a merge entry. Today: 48 self-merges on main in all, 16 touching `scripts/`, `test/` or `guides/` (and one path under `profiles/`), none touching `hooks/` or `devcontainer-config/`. Then `rg -n commit= /opt/claude-workflows/.manifest` and `git rev-list --count --first-parent <that commit>..main`. Good: the image's commit is on main (`git merge-base --is-ancestor <commit> main` exits 0) and any open `image-lag` entry lists what the gap holds. Today: image 665dbf95 (2026-11-20), on main, 60 first-parent commits behind 7dc44a6c; Q-336 (`image-lag`) is open.
- **C5 (R5).** `rg -n '(^|\s)@[A-Za-z0-9_./~-]+\.md' -g 'CLAUDE.md' -g 'CLAUDE.local.md' -g 'AGENTS.md' -g 'GEMINI.md' .` from the repo root. Good: no output. Today: no output (this repo's `CLAUDE.md` forbids imports, log row 65). A non-empty result, or a Claude Code release note changing imports, makes R5 live.
- **C6 (R6).** `git worktree list | rg '\[main\]'`. Good: one line, `/workspace`. Today: `/workspace` only (17 worktrees in all).
- **C7 (R7).** `scripts/questions.sh check` (you: it is a script, which this research could not run). Good: it reports no error. Then `rg -n '^Dispatched:' docs/working/briefs/*.md | rg -v 'Dispatched: [0-4]$'`. Good: no output. Today: no output. For the steal case, on any loop branch: `git log --format='%h %(trailers:key=Claude-Session,valueonly,separator=)' main..<branch>`; good: one session between two markers.
- **C8 (R8).** `rg -l -i 'drift check on' docs/working/cycles/`. Good: a recent full cycle ran one, and none reported drift. Today: the newest is `cycle-2026-11-13.md`; none since in a week, because light passes (log row 89) skip the spot-check step. This check reads cycle records, not code: a drift check has no git-level trace.
- **C9 (R9).** `git reflog show refs/heads/main | rg ': reset|: rebase|forced-update'`. Good: no output. Today: no output over 537 reflog entries (the reflog is local to this clone and expires; it is not a full history).
- **C10 (R10).** `git log --first-parent --since=<last walkthrough> --format='%h %(trailers:key=Build-loop-approved,valueonly,separator=)' main | rg Q-`, then for each ID `rg -n '^Q-NNN: ' docs/working/questions.md docs/working/questions-archive.md`. Good: every approved merge's ID has an answer line of yours. Today: four approved merges since 2026-11-18 (Q-339, Q-342, Q-343, Q-348); Q-343's `[1]` line checked.
- **C11 (R11).** Host, you, at the next release: run `install.sh` from a host terminal, never from a container or a sandboxed editor terminal, with no Claude Code session or helper running. Good: the no-agent gate passes with no `NOTE` lines (a `NOTE` means docker could not be asked). Nothing to run today.
- **C12 (R12).** Read the first revisit trigger in `docs/working/constraints-builder-hardening.md`. Good: every repo the skill has run on is yours alone. Nothing to run today.

R13 to R16 have no check by design: S1 says the gates do not defend against them, and a check would be a restriction whose bypass is already allowed.

## 5. Walkthrough script (about 20 minutes)

Order: the in-scope residuals whose check reads git first, then those that need you or the host, then the S1 group once. For each row, look at its check's result (§4), then answer one question: **keep** (still accepted as is), **tighten** (the cycle should propose a control: a roadmap item, not a decision made here), or **retire** (no longer true or no longer worth listing).

| Minute | Rows | What to look at |
|---|---|---|
| 0-1 | none | §1's motive and §3's S1 column: what is in scope and what is not |
| 1-4 | R1, R9 | C1 and C9 together: did main move only by merges, answers and your own commits? |
| 4-7 | R2 | C2, and the one changed bound: the plan says "the sandbox", and row 88 removed it. Is the container plus `permissions.deny` the bound you meant to accept? |
| 7-9 | R3 | C3, then the GitHub branch list and `/artifacts` |
| 9-12 | R4 | C4: the code-touching self-merges and the image lag (Q-336) |
| 12-14 | R5, R6, R7, R10 | C5, C6, C7, C10: one command each, expected empty or clean |
| 14-16 | R8 | C8: a week with no drift check; is a sampled check during full cycles enough? |
| 16-17 | R11, R12 | read only; nothing to run until the next release or the next foreign repo |
| 17-19 | R13-R16 | one question for the group: do they stay out of scope under S1? |
| 19-20 | none | write the answer line |

**Where the answer goes:** one answer line on the walkthrough's questions entry, in the global grammar, for example `Q-NNN: keep all but R2 tighten, R8 tighten`. "keep all" is a complete answer. The cycle then turns each "tighten" into a roadmap item, drops each "retire" from the next quarter's table (with a decision-log row, since it changes what Q-103 accepted), and carries the rest forward. Answer-line recording was the only option considered against an answers file or this doc: it is the one-line handle the global instructions already define (S3, one source of truth), so it dominates (Path A).

## 6. Choices made here (one line each)

- Scope: Q-103's families plus the later acceptances that moved them (log rows 74, 79, 88, Q-149 [2]) and the two adjacent trust models the brief names (install.sh, constraints-builder); the auto-approve hook (log row 53) appears only as R2's bound, since it was accepted outside the build-loop design.
- Grouping: Q-103's "also routed here" items are folded into the family a check would watch (R7, R10, R14) rather than listed one per override row, to fit 20 minutes; each folded row keeps its override-log row numbers.
- S1 marking: a residual is S1 only when no honest slip reaches it; R1 and R9 are split because both halves exist.
- Checks use only git, `rg` and reads where they could, so the owner can run them without trusting a script the change under review could edit (H1's spirit); C7's `questions.sh check` is the one script, named as such.
- No design choice here had three or more viable options, so no divergent-design pass ran.

## 7. Gotchas

- Every commit on main carries the owner's identity, so author name cannot separate hand commits from session commits; the `Claude-Session` trailer can, and is self-applied (forging it is S1).
- Reflogs (C3, C9) are local and expire; they show what this clone saw, not what the remote saw.
- Counts in §4 are as of 2026-11-20 and will drift (FP-089); the walkthrough re-runs the commands rather than trusting these numbers.

## For the dev cycle

**Entry to file** (route `you: walkthrough`; ID from `questions.sh next-id`):

```
### Q-NNN · threat-model-walkthrough-2026-q4
**Needs:** you: walkthrough · **Opened:** <filing date> · **Status:** OPEN

Walk through the risks you accepted in the build-loop design (about 20 minutes) and say for each: keep, tighten or retire.

- **Why it's yours:** these are risks you accepted (mostly in Q-103, the build-loop policy entry, answered self-merge on 2026-10-17); only you can keep or retire them. You asked for this each quarter in Q-340 [1].
- **Read:** the table and checks in `docs/working/research-2026-11-20-threat-model-walkthrough-prep.md` §3-§5 (16 rows; R13-R16 are out of scope under constraint S1, a hostile author, and get one question together).
- **Time:** about 20 minutes; the checks are git and `rg` commands, plus a look at GitHub's branch list and `/artifacts`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] keep all** | Every residual stays accepted as listed | About 20 minutes | A risk that has moved stays unaddressed until next quarter |
| **[2] keep, with changes** | Answer per row, for example "R2 tighten, R8 retire" | About 20 minutes plus one line | A tighten becomes a roadmap item the cycle builds |

- **Blocks:** nothing.
- **Interim:** every residual stays accepted as it was; nothing changes until you answer.
- **If the answer differs:** each "tighten" becomes a roadmap item; each "retire" gets a decision-log row and leaves next quarter's table.
```

**Next walkthrough due:** on or after 2027-02-20 (one quarter after this one). The watch in `docs/working/watching.md` that brings the walkthrough back in 2027-01 (area B's B8, line 170 at 7dc44a6c) was written before Q-340 [1] scheduled the first one now; the cycle should close it or re-date it to 2027-02-20 when it files this entry.

**Worth raising when filing:** R2's stated bound changed after it was accepted (the plan says the sandbox bounds a steered loop; log row 88 removed the sandbox on 2026-11-12), and R8's check found no drift check in the week since 2026-11-13. Neither is decided here.
