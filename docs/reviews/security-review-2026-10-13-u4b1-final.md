Commit: ea59b0c3

# Security Review — feat/build-loop-u4b1, final confirming pass

**Scope:** `git diff main...HEAD` at ea59b0c3 (458dc170, 0cd86cc0, 4c911717, ea59b0c3): `skills/dev-cycle/SKILL.md`, `scripts/lib/dev-cycle-read.sh` (HARDEN), `test/lib/d6-snippet.bash` (G), `scripts/build-loop.sh` (header), `test/scripts/build-loop-orchestrator.bats`, `workflows/pr-prep.md`, `docs/`. Context read: `build-loop.sh` header (`--state` :122-139, `--main-log` :140-185, Exit :511-522), `STATE_KEYS_RE`/`state_gate`/`caller_gate` :597-680, the mode dispatch :2085-2150, the N rules on `docs/working/cycles/` :355-368 and :1150-1162; the lib's `git_harden` :330-366; `scripts/health-check.sh` `take_lock` :1104-1119.
**Date:** 2026-10-13
**Based on:** `docs/reviews/security-review-2026-10-13-u4b1-i2.md` (prior pass), `docs/reviews/code-fact-check-report-2026-10-13-u4b1-final-r{1,2,3}.md` and their execution logs, the rubric `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4b1.md`.
**Probes:** `secf-probe1.sh`/`.out` (signing and identity under `hg`), `secf-probe2.sh`/`.out` (setsid's process group), `secf-probe3.sh`/`.out` (`--state` against signing pairs), in the session scratchpad `u4b1-i3/`, plus two inline runs (setsid under job control; setsid under the Bash tool). Each made its own `mktemp -d /tmp/u4b1-secf-XXXX`, removed by exact name afterwards (checked: none left, no `hc.sh` or `sleep` left running).

## Trust Boundary Map

```
B1: loop-writable .git/config, config.worktree     → hg's -c pairs and env (always) + --state (step 0.1, 0.2's gate, re-run before commits) → orchestrator's git: worktree add, add, commit, merge of main into WT
B2: loop-writable ~/.gitconfig, harness environment → GIT_AUTHOR_*/GIT_COMMITTER_* on the command                                           → orchestrator commit and merge identity
B3: script output and exit (refuse d6:, refuse lines, other lines, undocumented exits, timeouts) → the D6 Rule's stop wording → whether the iteration continues, files, dispatches
B4: main's history and the records on it (Main at: lines) → SINCE choice, incl. the 40-zero bootstrap → --main-log → dispatch block and the user's view of ungated commits (moved/new)
B5: the health check run (setsid, process group, take_lock's flock child) → the one-hour stop → which processes the session stops (D14) and whether the check ran
B6: until Q-140: by-hand fallback → ~/.claude/scripts/dev-cycle.sh, hg, no --state → orchestrator session
```

```
S1: .git/config + config.worktree       — runtime-mutable (any same-uid loop) — UNTRUSTED for exec (filters, drivers, gpg), identity and merge-content sinks
S2: ~/.gitconfig                        — runtime-mutable — UNTRUSTED for exec; accepted fallback identity source (attribution only)
S3: orchestrator environment (GIT_AUTHOR_* set by the harness here; GIT_CONFIG_*) — caller-trusted by design; --state snapshots its config pairs
S4: cycle records on main (docs/working/cycles/cycle-*.md, Main at: lines) — written by the chore land; the gate's N rules deny them to loops; a commit that moves main directly can write them — UNTRUSTED as a choice of SINCE
S5: build-loop.sh/dev-cycle.sh output   — main's committed copy via D6 (once written) — trusted for decisions only on a documented first line and exit
S6: PID/PGID of the background health check — process table, shared uid — trusted only while it names this session's own group
```

What crosses: `hg` now overrides commit signing outright (the i2 F1 class closed by override, not detection), identity rides the command's environment, and `--state` stays the only refusal for filters, drivers, merge signature verification and the rest of its list. Two places still let repo or process state choose what the orchestrator trusts: which record supplies SINCE (B4), and which process group the one-hour stop hits (B5). Note in passing: `hg` here is also Mercurial (`/usr/bin/hg`); `env VAR=… hg …` or `timeout N hg …` runs Mercurial, which aborts ("no repository found … .hg not found", observed in my first probe draft), so a misuse fails closed rather than running unhardened git (naming settled by override row; not re-flagged).

## Findings

#### F1. A record without a `Main at:` line downgrades `--main-log` to the bootstrap, which reports no commit at all

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:225-236`
**Boundary:** B4
**Move:** 3 (alternate path), 5 (what does the check not cover), 1 (runtime-mutable source)
**Confidence:** Medium (read-static; rests on the plain reading of "with no such line yet"; the record template is U4b2's)
**Legibility-target:** for-author

Evidence: "SINCE is the newest `Main at:` line of the newest record on the default branch (read with `hg -C MAIN_WT show`, never from a working tree); with no such line yet, pass 40 zeros: it prints `main MAIN -` and refuses, and that MAIN is the bootstrap." and "Any `other` line, or a `refuse main-log:` line other than the bootstrap's own … blocks this iteration's dispatch". The bootstrap answer is `main MAIN -` then the refusal, with no class lines (build-loop.sh:183-185), and SKILL.md exempts it from the block.

Weakness: the condition for the bootstrap is "the newest record has no `Main at:` line", which is a property of repo text. `--main-log` exists to report what moved main outside the gate and the chore land (D13, F43). A commit that moves main directly (the class `other` is for; the plan's threat model includes a same-uid loop that can update refs) can add a newer-dated record with no `Main at:` line, or delete the line from the newest one. The next iteration then takes the bootstrap route: no `other` line is printed, the refusal is exempt, dispatch proceeds and no judgment entry names that commit. Loops cannot do this through the gate (the N rules deny `docs/working/cycles/`, build-loop.sh:366 and :1162), so the precondition is a direct move of main, which is exactly the event the check is there to surface. Every other way to edit a record fails closed: a `Main at:` naming an earlier main commit re-lists commits (row 731), and a record cannot name the commit that adds it, so that commit is still listed.

Impact: the one check that turns an ungated change on main into a user-visible `you: judgment` entry, and blocks dispatch on it, can be switched off by the change itself. Today it has no effect yet, because no record holds a `Main at:` line until U4b2's template (rubric C3), so every iteration bootstraps anyway; the hole opens the day U4b2 lands.

**Recommendation:** bootstrap only when no record on main has ever held a `Main at:` line (for example: no `cycle-*.md` on main at all, or none of them holding the line), and treat "records exist, but the newest has none" as a stop with one `you: judgment` entry. Better still, choose the record by structure rather than by name: the record the newest `chore` merge on main's first-parent history changed (the class `--main-log` already reads), so a newer-dated name added outside a chore merge cannot win. If this belongs with the template, add an override row handing it to U4b2 with that rule; the condition itself is text this unit wrote.

#### F2. The process-group stop assumes setsid did not fork; when it does, the wait ends at once and the PGID read can name another group

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:267-275`
**Boundary:** B5
**Move:** 3, 4 (time of check to time of use)
**Confidence:** Medium (executed: fork and no-fork cases; which case an orchestrator hits depends on how it launches the line)
**Legibility-target:** for-author

Evidence: "in the background as its own process group (`setsid scripts/health-check.sh > LOG 2>&1`), and wait for it to finish before steps 2–4b start … the run's whole process group is stopped (`kill -- -PGID`, PGID from `ps -o pgid= -p PID`: stopping its PID alone leaves the waiting `flock` child …)".

What holds: started with `&` from a non-interactive bash or zsh, or as a foreground Bash tool command, setsid is not a group leader, so it calls setsid() in place: PID equals PGID and `wait` lasted the run (secf-probe2 cases A and C; a 15 s run under the Bash tool's own wrapper returned after it finished). The fact-check's late-run fault (take_lock's `flock` child) is closed for that case.

Weakness: util-linux setsid forks when its caller is already a process-group leader (job control on, or exec'd by a shell that leads its group) and the parent exits at once. Executed: under `set -m`, `setsid ./hc.sh &` gave a `$!` that was already gone, `wait` returned 0 immediately with the run unfinished, and the run finished seconds later; `setsid bash -c "exec setsid ./hc.sh"` returned in 0.01 s the same way. Then (a) "wait for it to finish" is satisfied at once, so steps 2-4b start against a half-written LOG and its failures are read too early, and (b) after an hour the recorded PID may name an unrelated process (same uid: another session's), whose group `kill -- -PGID` would stop, which D14 forbids. (b) also needs PID reuse within the hour, so it is unlikely; (a) needs only the launch form.

**Recommendation:** make the stop and the wait conditional on the group being this run's: start with `setsid -w` (setsid waits for its child even when it forks) or from a `bash -s` script that records `$!`, and before `kill -- -PGID` check that the PGID equals the recorded PID and that its command line is the health check, as pr-prep's quiesce already says ("once its command line shows it is yours"). One clause each.

#### F3. "Commits set their identity on the command" does not name the merge of main into WT

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:63-64`, `:80-85`
**Boundary:** B2, B1
**Move:** 5
**Confidence:** Medium (the commit case executed in i2; the merge with the prefix executed here; the merge without it, under the global-config fallback, is inferred from i2's commit result)
**Legibility-target:** for-author

Evidence: the Rule lists "its commits, merging main into WT" among the orchestrator's git, then says "Commits set their identity on the command, as `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME` and `GIT_COMMITTER_EMAIL` (these outrank a planted `author.*` or `committer.*` key)". A merge writes a commit and reads the same identity keys. Executed (secf-probe1): with `author.*`/`committer.*` planted, `GIT_AUTHOR_NAME=Orch … hg merge --no-edit side` recorded `Orch <orch@x>` for both, so the prefix works on merges; i2 F2 showed that without it a planted `author.*` wins over `-c user.*`. On this host the harness exports all four variables, so every command is covered regardless; the gap is the fallback path (identity read from `~/.gitconfig`) on a host that does not. Impact: attribution only (nothing classifies by author).

**Recommendation:** "Commits and merges set their identity on the command", and add the merge's form (prefix, `--no-edit`) to U4b2's checklist row, which already names `--no-edit`. Also worth one word that the prefix is `VAR=… hg …`, not `env VAR=… hg …` (the latter runs Mercurial, see the map's note).

#### F4. `merge.verifySignatures` with a planted `gpg.program` runs a command under `hg` whenever `--state` is skipped or raced

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:72-79`, `:24-28`; `scripts/lib/dev-cycle-read.sh:354`
**Boundary:** B1, B6
**Move:** 11
**Confidence:** High (executed by fact-check r3, `execution-logs/u4b1-final-r3-fc-verifysig.log`; `--state`'s refusal re-executed here, secf-probe3)
**Legibility-target:** for-author

Evidence: "It does not switch off what the repository's own config can still name (a filter, a merge driver, signature verification on a merge): `--state` refuses those, but only when it runs". r3: "HG merge with merge.verifySignatures+gpg.program in .git/config: rc=128 gpgran=yes"; secf-probe3: `refuse state merge.verifysignatures: set in config …`, exit 2. The text is now accurate, and the case sits inside the named residual (Q-103's list) and the fallback's named gap, beside filters and merge drivers, which run commands in the same windows; so the marginal gain is small. Still, unlike filters, this key can be switched off by name at the cost the i2 F1 fix paid: `merge.verifySignatures=false` in HARDEN, G and `hg`, held equal by the same pin test, inert for the scripts (none merges with git merge). Optional; not a merge blocker.

## Untested bypass candidates (move 11, guardrail: hg + `--state` over repo config)

Tested this pass: `commit.gpgSign`+`user.signingKey` on commit and merge under `hg` (closed); the same planted for a plain `git commit` (control: gpg ran); a caller pair for `commit.gpgSign` via `GIT_CONFIG_COUNT` and via `GIT_CONFIG_PARAMETERS` in mixed case (refused, exit 2); `merge.verifySignatures` at `--state` (refused); identity env prefix on a merge (holds).

Not tested:
- Config-based hooks (`hook.<name>.command`/`.event`) on a newer git than this image's 2.39.5: if the installed git gains them, `core.hooksPath=/dev/null` may not switch them off, and only `--state` (`hook\.` is in `STATE_KEYS_RE`) would; "hg … runs no hook" (SKILL.md:73) is verified only on 2.39 (fact-check r1 hook log). Not testable here (no such git).
- `submodule.recurse=true` in `.git/config` with a `.gitmodules` on main: `worktree add`'s checkout recurses; `GIT_ALLOW_PROTOCOL=none` should stop any clone, so expected availability only.
- `core.pager`/`pager.show` on `hg -C MAIN_WT show`: git pages only on a terminal; the Bash tool's stdout is not one.
- rerere, `core.autocrlf`/`core.eol`, `gc.auto`, `core.editor` (carried from i2; the merge-time ones are in U4b2's override row).

Because these are untested, `hg` + `--state` does not appear in Endorsement Claims as a guardrail.

## Endorsement Claims

- **Claim:** with `commit.gpgSign true` and `user.signingKey` planted in the common `.git/config`, `hg commit` and `hg merge --no-edit` in a linked worktree complete and run no `gpg`, while a plain `git commit` in the same repo runs it.
  **Location:** `skills/dev-cycle/SKILL.md:69`; `secf-probe1.out`
  **Evidence:** executed
  **Verified:** shim `gpg` first on PATH; commit rc 0 (`sig=N`), merge rc 0 (two parents), marker absent; control commit rc 128 with the marker written.
  **Not verified:** `git rebase`/`cherry-pick` (the cycle names neither).
  **route: code-fact-check**
- **Claim:** `--state` refuses a caller pair for `commit.gpgSign` whatever its case or value, by `GIT_CONFIG_COUNT` or `GIT_CONFIG_PARAMETERS`, and still prints `ok` for a repo-local `commit.gpgSign` (which `hg` overrides).
  **Location:** `scripts/build-loop.sh:660-676`, `scripts/lib/dev-cycle-read.sh:354`; `secf-probe3.out`
  **Evidence:** executed
  **Verified:** exit 2 with `refuse state commit.gpgsign: set by the caller's …` for both forms; exit 0 `ok` with the key in `.git/config`.
  **Not verified:** the other gated modes' paths through `caller_gate` (only `--state` calls it, build-loop.sh:711).
  **route: code-fact-check**
- **Claim:** the pin test holds the lib's `HARDEN`, the snippet's `G` and SKILL.md's single `hg` line to the same nine pairs and seven variables.
  **Location:** `test/scripts/build-loop-orchestrator.bats:355-372`
  **Evidence:** executed (test passes at ea59b0c3 here; fact-check r1's six mutants each fail it: `execution-logs/u4b1-final-r1-fc-mutants.log`)
  **Verified:** `ok 1 git_harden exports …`; M1-M6 (pair dropped from each copy, variable dropped, second `hg` line, reordered pairs) all `not ok`.
  **Not verified:** the D6 block's copy in SKILL.md (U4c).
  **route: code-fact-check**
- **Claim:** the per-command `GIT_AUTHOR_*`/`GIT_COMMITTER_*` prefix records the intended identity on a merge with all four `author.*`/`committer.*` keys planted.
  **Location:** `skills/dev-cycle/SKILL.md:80-85`; `secf-probe1.out`
  **Evidence:** executed
  **Verified:** `merge: parents=… author=Orch <orch@x> committer=Orch <orch@x>`.
  **Not verified:** the `~/.gitconfig` fallback with no harness variables (F3).
  **route: code-fact-check**
- **Claim:** `setsid CMD > LOG 2>&1 &` from a non-interactive shell puts the run in a group whose PGID is its PID, and `wait` lasts the run.
  **Location:** `skills/dev-cycle/SKILL.md:269`; `secf-probe2.out` cases A, C
  **Evidence:** executed
  **Verified:** `P=… pgid(P)=P`, `done-exists=yes` after `wait`, under bash and zsh.
  **Not verified:** the job-control and exec launch forms, which fork (F2).
- **Claim:** a loop's branch cannot change a cycle record through the gate.
  **Location:** `scripts/build-loop.sh:362-368`, `:1155-1162`
  **Evidence:** read-static
  **Verified:** the N rules deny `docs/working/cycles/` and paths below it, lower-cased.
  **Not verified:** a commit that moves main outside the gate (F1).

## Primitive sweep

Primitive: process exec through repo git config (filters, drivers, gpg) in the orchestrator's git commands

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:237` `hg -C MAIN_WT worktree add …` (checkout: smudge) | S1 | `--state` at 0.1 and `--main-log`'s state gate at 0.2 | cleared — checked moments before; the window is the named residual |
| commits in WT (`SKILL.md:63-85`) | S1 | `hg` (signing off); `--state` re-run (filter.*, gpg.*) | cleared for signing (executed); filters: named residual |
| merge of main into WT (`SKILL.md:64`) | S1 | `hg` (signing off); `--state` re-run (merge.*) | cleared for signing (executed); verifySignatures F4; rerere in U4b2's row |
| `hg -C MAIN_WT show` (step 0.2) | S1 | `hg`, `--state` | cleared — object read, `log.showSignature=false`, textconv only via `diff.*` (refused) |
| `hg mv` (step 6, `SKILL.md:417`) | S1 | `hg` | cleared — no content transform |
| plain `git config --global --get` (`SKILL.md:83`) | S2 | none needed | cleared for exec (reads one file, no includes with `--global`) |
| by-hand fallback git (`SKILL.md:19-28`) | S1 | `hg` only, no `--state` | named gap (i2 F3, fixed as wording) |

Primitive: signal delivery to a process group

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `kill -- -PGID` (`SKILL.md:273`) | S6 | none (PGID read from `ps` of a PID) | F2 |
| pr-prep quiesce, stop by PID (`workflows/pr-prep.md:333`) | S6 | command line read first | cleared — the text requires the check F2 asks for |

## Prior findings (i2) and fact-check escalations

- i2 F1 (signing): **fixed and holds** — HARDEN, G and `hg` carry `commit.gpgSign=false`; executed on commit and merge; `caller_gate` refuses the caller pair; no HARDEN user commits with signing (build-loop.sh's one `commit-tree` already passes `--no-gpg-sign`, :1558; dev-cycle.sh and the snippet do not commit); the fact-check's full suite log shows 288/288.
- i2 F2 (identity): **fixed and holds** for commits and, executed here, merges with the prefix; wording gap F3.
- i2 F3 (fallback): **fixed as wording** — the gap now names drivers, signature verification, grafts, alternates "and the rest of `--state`'s list". Running `--state` by the same route the fallback uses for `dev-cycle.sh` (the root-owned `~/.claude/scripts/build-loop.sh` exists on this host) would narrow it; the author chose the named gap, which i2 accepted.
- i2 F4, F5: override rows, not re-flagged.
- Escalation, late health-check run: closed for the non-forking launch (F2 covers the forking one). Escalation, `merge.verifySignatures`: text accurate; F4. Escalation, fallback grafts: named.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | A record without `Main at:` sends SINCE to the bootstrap, which lists no `other` commit and is exempt from the block | Medium | B4 | `skills/dev-cycle/SKILL.md:225-236` | Medium |
| F2 | setsid's fork case: the wait ends at once, and the PGID read is unguarded | Low | B5 | `skills/dev-cycle/SKILL.md:267-275` | Medium |
| F3 | Identity rule names commits, not the merge of main into WT | Low | B2, B1 | `skills/dev-cycle/SKILL.md:80-85` | Medium |
| F4 | `merge.verifySignatures`+`gpg.program` under `hg` in the named windows; could join HARDEN | Informational | B1, B6 | `skills/dev-cycle/SKILL.md:72-79` | High |

## Overall Assessment

The iteration-2 fixes hold: signing is now overridden on every hardened git call rather than detected, identity rides the command's environment, the fallback names its gap, and the stop wording matches build-loop.sh's Exit paragraph (exit 0, or exit 2 with documented lines; anything else, or a timeout, stops with no record). The process-group stop closes the fact-check's late-run fault for the launch forms the orchestrator uses. The one Medium (F1) is new and sits in step 0.2's bootstrap condition: a record edited outside the gate can switch `--main-log`'s reporting off, which matters once U4b2 writes `Main at:` lines; it is fixable in one sentence here or by an override row handing the rule to U4b2's record template. F2 and F3 are one clause each. Nothing is architectural. No findings beyond these within the code paths read; endorsement claims marked `route: code-fact-check` are pending execution verification there, though each was executed here.

## Goal-Alignment Note

The goal is landing U4b1 after a clean review-fix loop, with SKILL.md as instructions an orchestrator executes. This pass confirms the i2 Medium fixes by execution, so the security side of the loop is closed for what it raised. F1 is the only item that could justify another fix round: it is a fail-open in text this unit wrote, but it has no effect until U4b2 adds `Main at:` lines, so an override row routing the bootstrap rule to U4b2's record template (with the rule stated) is a proportionate alternative to editing step 0.2 now. F2 and F3 are small wording fixes that can ride along or go to U4b2's checklist; F4 is optional hardening. None should hold the merge if routed.
