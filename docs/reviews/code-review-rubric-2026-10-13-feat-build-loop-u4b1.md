Commit: ea59b0c3
Loop-pass short-circuit: used at 458dc170

# Code Review Rubric: feat/build-loop-u4b1

**Scope:** full branch, `git diff main...HEAD` (main 596966f0; first pass of the loop). Delivery mode: self-read (shared brief on disk).
**Iteration 1** (`--loop-pass`, k=1 fact-check). Behavioral red at fact-check (SKILL.md is the orchestrator's instructions, so a wrong safety claim there is behavioural): first-red short-circuit, critics skipped this pass. No enforcement file in the diff (mechanic 7 not triggered). Stage 2.5 skipped (loop pass).
**Reports:** `docs/reviews/code-fact-check-report-2026-10-13-u4b1-i1.md` (33 claims: 24 Verified, 4 Mostly accurate, 1 Stale, 4 Incorrect).

## 🔴 Must Fix

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| R1 | The hardened-git Rule says neither `.git/config` nor `~/.gitconfig` "runs anything here: no ... filter or signature program"; under hg's exact line a filter in `.git/config` plus info/attributes ran, and commit.gpgSign ran gpg.program. Only `--state` refuses these, at the moment it runs. | fact-check 9b (executed) | Incorrect (high) | `SKILL.md:62-63` "so neither runs anything here: no hook, fsmonitor, filter or signature program" | Fixed: the Rule names what hg covers and what only `--state` refuses, runs `--state` again before the iteration's commits, and names the residual (Q-103) |
| R2 | "Never export these settings: `--state` refuses a caller that sets one": with hg's seven environment variables exported, `--state` printed ok; only config pairs are refused. | fact-check 11b (executed) | Incorrect (high) | `SKILL.md:66-67` | Fixed: "set them per command ... `--state` refuses a caller's config pair for a HARDEN key" |

## 🟡 Must Address

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| A1 | An undocumented exit or a timed-out call "means nothing ran"; the script's header says nothing decided (a writing mode may stop part way). | fact-check 5b | Incorrect (doc-level wording of a stop rule) | `SKILL.md:48-49` | Fixed |
| A2 | "step 9" / "step 10's dispatch" name steps the file does not have yet (U4b2 writes them). | fact-check 24 | Incorrect | `SKILL.md:129, 213` | Fixed: named by mode (`--cycle-diff`) and "this iteration's dispatch" |
| A3 | A `refuse main-log:` line has three causes, and the bootstrap's own refusal was not exempted: the first iteration would file a judgment entry and block dispatch. | fact-check 18 | Mostly accurate (behavioural consequence) | `SKILL.md:212-214` | Fixed |
| A4 | Identity read with bare `git config` is an unstated exception to "never bare git", and a loop-writable user.name pasted as `-c user.name=NAME` into script text has no quoting rule. | fact-check 7, escalation to security | Mostly accurate | `SKILL.md:53-56, 215-217` | Fixed: read into variables inside the committing script, never pasted |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| C1 | Cycle rules do not admit "any .md under docs/"; the three row cases plus docs/working and docs/reviews do pass. | fact-check 14 | Fixed |
| C2 | The pending D6 section's refusal list is partial. | fact-check 15 | Fixed (points to the header) |
| C3 | Step 7 still lands through pr-prep and its record has no `Main at:`/`Branch:` line, so SINCE always bootstraps until U4b2. | fact-check 25 (Stale) | Defer to U4b2 (plan split note) |
| C4 | The pin test checks only `-c` and `GIT_*=` tokens of the hg line. | fact-check residue | Won't-Fix: the line's other tokens are `env`, `git` and `"$@"`; the one-line count pins its shape |

## ⏭️ Skipped Core Critics

| Critic | Reason |
|---|---|
| security-reviewer, performance-reviewer, api-consistency-reviewer | loop-pass short-circuit (behavioral red confirmed) |

## Considered overrides

Rows 702, 704, 720, 726, 727, 735, 736, 742, 744, 750, 764, 769, 771 (the hand-offs this unit answers); none re-flagged.

**Status:** 2 red, 4 amber, all fixed in the next commit (unreviewed). Next: iteration 2, full panel over the fix range.

---

## Iteration 2 (`--loop-pass`, short-circuit already used: full panel)

**Scope:** fact-check over the fix range 458dc170..0cd86cc0 (k=1); security, performance and api-consistency critics over the full branch (no critic had reviewed it). Architecture not selected (no module structure change). Stage 2.5 skipped (loop pass): the security critic's three executed claims stay *pending execution verification*.
**Reports:** `code-fact-check-report-2026-10-13-u4b1-i2.md` (15 claims: 12 Verified, 2 Mostly accurate, 1 Incorrect), `security-review-2026-10-13-u4b1-i2.md` (3 Medium, 2 Low), `performance-review-2026-10-13-u4b1-i2.md` (1 Medium, 1 Low), `api-consistency-review-2026-10-13-u4b1-i2.md` (4 Inconsistent, 3 Minor, 4 Informational).
**Prior items:** R2, A1-A4 resolved (fact-check i2); R1 partly: see B1.

### 🔴 Must Fix

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| B1 | The Rule says `--state` refuses commit signing; it refuses gpg.* but not commit.gpgSign/user.signingKey, so hg's commits (and the merge of main into WT) ran gpg after a clean `--state`. | fact-check i2 3c (executed), security F1 (executed), api 4 | Incorrect (high) / Medium | `SKILL.md:66` "a filter, a merge driver, commit signing): `--state` refuses those" | Fixed: commit.gpgSign=false joins HARDEN (lib), the snippet's G and hg (pin test: count 10); the Rule lists signing under what hg covers |

### 🟡 Must Address

| ID | Finding | Source | Severity | Status |
|---|---|---|---|---|
| B2 | author.*/committer.* in the repo config outrank `-c user.name/user.email`. | security F2 (executed) | Medium | Fixed: identity as GIT_AUTHOR_*/GIT_COMMITTER_* on the command |
| B3 | The by-hand fallback reads as if `--state`'s protection held; it never runs there. | security F3 | Medium | Fixed: the gap named; hg applies in the fallback |
| B4 | Fallback too narrow: check modes still said "through the D6 block"; no worktree/branch for a by-hand run. | api 1 | Inconsistent | Fixed |
| B5 | A stop is "quoted in the record" vs step 0's "no record". | api 2 | Inconsistent | Fixed: no record; agent entry and final message |
| B6 | Exit codes: a documented exit 1 was not a stop; overlap with the check-mode rule. | api 3 | Inconsistent | Fixed: build-loop.sh answers are 0 or 2 with refuse lines; dev-cycle.sh check modes keep the paths rule |
| B7 | The per-iteration worktree is never removed (disk, and the walks' reader set grows: +0.13 s per worktree per walk). | performance F1 | Medium | Fixed: step 0.3 says WT is removed once the land is verified (U4b2's step 9 runs it) |

### 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| B8 | An abandoned health check still takes the lock later. | performance F2 | Fixed: stopped by its PID |
| B9 | "the residual Q-103 names": Q-103 names none yet. | fact-check i2 claim 5 | Fixed: "a residual for Q-103's list (U5)" |
| B10 | `--check-fix` passes a tracked file below a directory named like an instruction file. | fact-check i2 claim 9 | Fixed: "a new file below ..." |
| B11 | `questions.sh` and the fallback's dev-cycle.sh go through the uid-owned ~/.claude/scripts symlink. | security F4 | Defer (override row; Q-103 class) |
| B12 | An `other` commit blocks dispatch but step 1 still runs main's health check. | security F5 | Defer (override row) |
| B13 | Step 7's `chore/dev-cycle-<date>`, 3 slots hard-coded, record date clock; U4b2's checklist (description, Flow, `--land-cycle` fast-forwarding MAIN_WT, the SINCE read, `--no-edit` on merges, rerere). | api Minor/Informational, security untested candidates | Defer to U4b2 (override row) |
| B14 | `hg` shadows Mercurial's command name. | api Minor | Won't-Fix: defined inside each `bash -s` script only |
| B15 | Quiesce terms ("this task" in pr-prep, "iteration"/"session" in the skill). | api Informational | Won't-Fix: each is the scope of its own workflow |

**Status:** 1 red, 6 amber; all fixed or routed in the next commit (unreviewed). Next: iteration 3 = the final confirming pass (k=3, full panel, no `--loop-pass`).

---

## Iteration 3: the final confirming pass (no `--loop-pass`)

**Scope:** full branch. Stage 1: k=3 fact-check at 4c911717 (`code-fact-check-report-2026-10-13-u4b1-final.md`, merged most-severe-wins: 37 clusters, 25 Verified, 8 Mostly accurate, 1 Stale, 3 Incorrect; agreement 28/37, 75.7%). Fact-Check Gate: high-confidence behavioural Incorrect; /away choice **fix first** (U3c precedent): ea59b0c3. Stage 2: security, performance, api-consistency and architecture (selected: the shared HARDEN list) on the full branch at ea59b0c3. Stage 2.5 not run: the routed security and performance claims back no ✅ row here (this rubric lists none) and stay *pending execution verification*; their substance was executed by the critics themselves.
**Reports:** `code-fact-check-report-2026-10-13-u4b1-final{,-r1,-r2,-r3}.md`, `security-review-2026-10-13-u4b1-final.md` (1 Medium, 2 Low, 1 Info), `performance-review-2026-10-13-u4b1-final.md` (2 Low), `api-consistency-review-2026-10-13-u4b1-final.md` (1 Inconsistent, 1 Minor, 1 Info), `architecture-review-2026-10-13-u4b1-final.md` (1 Coupling, 3 Minor, 1 Info; no Structural).
**Prior items:** B1-B7 confirmed fixed by the critics (executed: signing, identity, fallback wording).

### 🔴 Must Fix

| ID | Finding | Source | Severity | Status |
|---|---|---|---|---|
| D1 | Stopping a waiting health check by its PID left take_lock's flock child, which took the lock later and ran the check. | fact-check claim 27 (r1-r3, executed) | Incorrect (high) | Fixed in ea59b0c3 (process group), then replaced (D4) |
| D2 | `--state`'s exit 1 routed to an agent entry by the Rules and a judgment entry by step 0.1. | fact-check claim 10 | Incorrect (high) | Fixed in ea59b0c3; D5 states the routing once |

### 🟡 Must Address

| ID | Finding | Source | Severity | Status |
|---|---|---|---|---|
| D3 | Bootstrap fail-open: a newest record without a `Main at:` line (a commit outside this design dropped it) bootstraps, so --main-log reports nothing and dispatch proceeds. | security F1 | Medium | Fixed: bootstrap only when no record holds the line; else a stop with a judgment entry |
| D4 | The skill encoded take_lock's process tree (setsid, PGID); setsid forks when its caller leads a group, so the PID can miss. | architecture 1 (Coupling), performance F2, security F2 | Coupling / Low | Fixed: `HEALTH_CHECK_LOCK_WAIT` (flock -w, exit 75, nothing run) in health-check.sh with a test that fails on the old script; the skill sets it |
| D5 | "Stop" had three routes; a timed-out dev-cycle.sh call and a `refuse d6:` line had none. | api-consistency 1 | Inconsistent | Fixed: one sentence (filed once, the step's judgment entry or an agent entry) |

### 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| D6 | A stopped iteration leaves its worktree. | performance F1 | Fixed: a stop after step 0.3 removes WT |
| D7 | The identity rule did not name the merge of main into WT; `env VAR=… hg` would run Mercurial. | security F3 | Fixed |
| D8 | build-loop.sh's header HARDEN key list is not pinned. | architecture 2 (executed) | Fixed: the header refers to the lib's list |
| D9 | The fallback contradicts the D6 Rule; U4c's plan entry did not delete it. | architecture 3 | Fixed: a pointer in the Rule; U4c's entry deletes both |
| D10 | Exit-2 wording, merge.verifySignatures under hg, the fallback's wider gap, Q-140 scope, the --check-fix list, `git mv`, "the gate" lock wording. | fact-check claims 6, 7, 9, 11, 13, 19, 20, 26 | Fixed in ea59b0c3 |
| D11 | The installed skill cites this repo's plan D-numbers, override rows and Q-IDs, which dangle in other projects. | architecture 4 | Defer (override row; U5) |
| D12 | Step 9's chore commit should say whether it goes through a gated mode; one `--state` re-run, once, before which commits. | architecture 5, api-consistency 3 | Defer to U4b2 (override row) |
| D13 | `merge.verifySignatures=false` could join HARDEN. | security F4 | Won't-Fix (override row): --state refuses the key |
| D14 | Commit messages: 0cd86cc0's R1 ("only --state refuses commit signing"), 4c911717's "count 10" (GIT_CONFIG_COUNT; HARDEN has 9). | fact-check claims 32, 35 | Accepted-immutable: corrected in the merge message |

## 🧩 Composition check

| Cluster | Fragments | Disposition |
|---|---|---|
| SKILL.md step 1 health check (lines ~264-276) | fact-check 27, performance F2, security F2, architecture 1 | composed: one root, the skill re-implementing take_lock's process handling; fix in the script (D4) |
| SKILL.md Rules stop paragraph (~52-64) | fact-check 9, 10, api 1 | distinct defects: wording vs routing, both fixed |

**Status:** after the fix batch, no open Must Fix or Must Address. The batch (D3-D9, a health-check.sh change) is unreviewed: next, the iteration-4 gate.
Single-sample review; absence of findings is not an attestation.
