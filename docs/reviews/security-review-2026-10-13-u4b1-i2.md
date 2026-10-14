Commit: 0cd86cc0

# Security Review — feat/build-loop-u4b1, iteration 2

**Scope:** `git diff main...HEAD` (HEAD 0cd86cc0): `skills/dev-cycle/SKILL.md`, `workflows/pr-prep.md`, `test/scripts/build-loop-orchestrator.bats`, `docs/working/plan-build-loop-handoff.md`. Context read: `scripts/build-loop.sh` (`STATE_KEYS_RE`/`state_gate`/`caller_gate` :600-680, `--main-log` argument check :543-545, `merge_ident` :1423-1436, `commit-tree --no-gpg-sign` :1558), `scripts/lib/dev-cycle-read.sh` (`git_harden`, `HARDEN` :330-360), `test/lib/d6-snippet.bash:45`.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b1-i1.md`, `docs/reviews/code-fact-check-report-2026-10-13-u4b1-i2.md`
**Probes:** `sec-probe1.sh`/`.out`, `sec-probe2.sh`/`.out` in the session scratchpad `u4b1-i2/`; each ran in its own `mktemp -d /tmp/u4b1-sec-XXXX` repo, removed afterwards (checked: no `/tmp/u4b1-sec-*` left).

## Trust Boundary Map

```
B1: loop-writable .git/config, config.worktree, ~/.gitconfig → hg's -c/env pairs (always) + --state (when it runs) → orchestrator's git: worktree add, add, commit, merge of main into WT
B2: loop-writable ~/.gitconfig user.name/email (fallback identity) → plain `git config --global --get` into $N/$E → hg -c user.* → orchestrator commit author/committer
B3: script output (refuse d6:, refuse state, main-log lines, undocumented exits, timeouts) → SKILL.md's stop rules → whether the iteration continues, dispatches or lands
B4: until Q-140: by-hand fallback → ~/.claude/scripts/dev-cycle.sh (a node-owned symlink to /opt/...) / the checkout's scripts/ → orchestrator session
B5: main's history (gate, chore, answers, other commits) → --main-log classification → dispatch block only; step 1 still runs main's health check from WT
```

```
S1: .git/config + config.worktree (common and per-worktree) — runtime-mutable (any same-uid loop) — UNTRUSTED for exec (filters, drivers, gpg), identity and merge-content sinks
S2: ~/.gitconfig                                            — runtime-mutable — UNTRUSTED for exec; accepted by design as the fallback identity source (as build-loop.sh's merge_ident does), so attribution only
S3: orchestrator's environment (GIT_AUTHOR_*, GIT_CONFIG_*) — caller-trusted by the design (git_harden's model); --state snapshots it
S4: build-loop.sh / dev-cycle.sh output                     — produced by main's committed copy through D6 (once it exists) — trusted for decisions only when its first line and exit are documented
S5: Main at: line in a record on main                       — repo text on main — format-checked by --main-log (40/64 hex, build-loop.sh:545)
S6: ~/.claude/scripts symlink (node-owned → /opt/claude-workflows/scripts, root-owned files) — runtime-mutable link — UNTRUSTED for exec
```

What crosses: the orchestrator's own git commands read S1/S2, which any build loop can write. hg neutralises global/system config, hooks, fsmonitor and replace refs by override (always on); everything else in the repository's own config is only *detected*, by `--state`, at the moment it runs. The diff's central trust assumption (SKILL.md:65-68) is that `--state`'s refusal set covers "a filter, a merge driver, commit signing"; it covers the first two, not the third, and not identity keys.

## Findings

#### F1. `--state` does not refuse commit signing; the Rule says it does (fact-check i2 claim 3c)

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:65-68`; `scripts/build-loop.sh:612`
**Boundary:** B1
**Move:** 11 (bypass the guardrail), 2 (implicit sanitisation)
**Confidence:** High (executed: fact-check i2 probe 1; this review's P2/P3)
**Legibility-target:** for-author

Evidence: "It does not switch off what the repository's own config can still name (a filter, a merge driver, commit signing): `--state` refuses those, but only when it runs" (SKILL.md:65-67), against `STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'` (build-loop.sh:612), which has `gpg\.` (the program and format) but not the switch `commit.gpgsign`, nor `tag.gpgsign` or `user.signingkey`. The fact-check executed `commit.gpgSign true`, `tag.gpgSign true`, `user.signingKey X` each → `--state` prints `ok`, and `hg … commit` then ran `gpg` from PATH. This review's P3 adds the merge: with `commit.gpgSign true` planted, `git merge --no-edit main` in WT printed `error: gpg failed to sign the data` / `fatal: failed to write commit object` and the shim gpg ran. So "re-run `--state` right before the commits" does not cover one of the three things it names.

Preconditions: a same-uid build loop writes `commit.gpgSign=true` (optionally `user.signingKey`) into the shared `.git/config`. Impact: every orchestrator commit and merge of main into WT runs `gpg` (the default program; `gpg.program` itself is refused) with the user's keyring: either the user's key signs commits whose tree carries content the orchestrator merged from main, with a loop-chosen key ID, or (no key, a pinentry) every commit fails or hangs until the Bash tool times out, which the Rules then read as "nothing decided" and stop on, every iteration. Not code execution beyond what a same-uid loop already has; the real cost is a guard the text promises that does not exist, plus a cheap repeatable stop.

**Recommendation (the brief's three options weighed):**
1. **Preferred: add `commit.gpgSign=false` to `HARDEN`, the snippet's `G=(…)` line and `hg`** (one pair each; update the pin test's `GIT_CONFIG_COUNT=9` to 10). Executed here (P2): `hg -c commit.gpgSign=false … commit` with `commit.gpgSign true` planted committed (rc 0) and gpg did not run; `-c` outranks every config file, so this closes the case whenever the plant happens, with no time-of-check gap, and the same pair covers `git merge`'s commit (merge-with-override not executed; git applies `commit.gpgSign` to merge commits, P3 shows the setting is read there). Cost to the shared list is nil in behaviour: dev-cycle.sh and the D6 snippet never commit, and build-loop.sh's only `commit-tree` already passes `--no-gpg-sign` (build-loop.sh:1558), so the pair changes nothing for them; the user's own signing setting lives in `~/.gitconfig`, which `GIT_CONFIG_GLOBAL=/dev/null` already drops for every hardened call, so the orchestrator's commits are unsigned today for every user who signs globally. It is the pattern HARDEN already follows for `log.showSignature=false` (override, with the key also in `STATE_KEYS_RE`). The pin test keeps lib, snippet and hg equal mechanically; the one cost is that `caller_gate` will now refuse a caller pair for `commit.gpgsign` (row 702's rule), which is the intended effect. `tag.gpgSign=false` is not needed (the orchestrator makes no tags); skip it rather than grow three pinned lists.
2. Optional, alongside 1: add `commit\.gpgsign|tag\.gpgsign|user\.signingkey` to `STATE_KEYS_RE`, matching `log\.showsignature`'s precedent, so a plant is reported as planted state instead of silently overridden. Alone (without 1) it leaves the plant-after-check window and blocks a user who legitimately signs in repo-local config, the same trade `gpg\.` already makes.
3. Narrowing the text ("a filter, a merge driver, a signing program") only is acceptable as an interim if the lib cannot change in this unit, but then the Rule must also say that a planted `commit.gpgSign` makes the iteration's commits run gpg, and the hardening goes to a row for U4b2/U5. Not recommended: it documents a cheap stop rather than removing it.

With 1 in place, SKILL.md:63-66 should list signing among what `hg` switches off, and keep only filters and merge drivers in the `--state` sentence.

#### F2. Repo-local `author.*` / `committer.*` override the identity recipe, and `--state` passes them

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:69-74`
**Boundary:** B1, B2
**Move:** 11, 1 (per-consequence trust)
**Confidence:** High (executed, P1/P2 of sec-probe1, sec-probe2)
**Legibility-target:** for-author

Evidence: "without them, the same script reads `N="$(git config --global --get user.name)"` and `E=…user.email…` … and commits with `hg -c user.name="$N" -c user.email="$E" …`" (SKILL.md:71-73). git ranks `author.name`/`author.email`/`committer.name`/`committer.email` above `user.*` for the commit identity, and `hg -c user.*` does not touch those keys. Executed: with `author.name LoopAuthor`, `author.email loop@evil`, `committer.email loopc@evil` planted in the common `.git/config`, `hg -c user.name=Orch -c user.email=orch@x commit` in the linked WT recorded `author=LoopAuthor <loop@evil> committer=Orch <loopc@evil>`; `build-loop.sh --state` on the same repo printed `ok`, exit 0. The environment path (`GIT_AUTHOR_*`/`GIT_COMMITTER_*`) is not affected: environment variables outrank every config scope.

Preconditions: the fallback identity path (no `GIT_AUTHOR_*` in the orchestrator's environment) and a same-uid loop writing the common config. Impact: the orchestrator's chore commits and merges of main into WT are attributed to an identity the loop picks. Nothing in the gate classifies by author (`--main-log` classifies by structure and subject), so this is attribution integrity in the user's history, not a gate bypass; it does make a loop's influence on the chore branch harder to see after the fact. (Same mechanism, not under review: build-loop.sh's `merge_ident` resolves identity with `git var` and may be subject to repo-local `author.*` too; not executed here.)

**Recommendation:** set the identity as environment for the one command, which outranks every config file: `GIT_AUTHOR_NAME="$N" GIT_AUTHOR_EMAIL="$E" GIT_COMMITTER_NAME="$N" GIT_COMMITTER_EMAIL="$E" hg commit …` (executed: `Orch <orch@x>` for both with all four keys planted). `hg -c author.name=… -c author.email=… -c committer.name=… -c committer.email=…` also works (executed) but is longer. This keeps "never export" true (a per-command prefix, not an export) and makes both identity paths the same mechanism. Not recommended: adding `user\.|author\.|committer\.` to `STATE_KEYS_RE`, which would refuse a repo-local `user.email`, a common legitimate setting.

#### F3. The by-hand fallback runs no `--state`, so the hardened-git Rule's second half never holds until Q-140

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:19-23`, with `:65-68` and `:209-214`
**Boundary:** B1, B4
**Move:** 3 (error/alternate path), 5 (what does it not cover)
**Confidence:** Medium (depends on reading "no step that needs one" as skipping step 0.1 and the pre-commit re-run, which is its plain reading)
**Legibility-target:** for-author

Evidence: "Run the cycle by hand instead: the digest as `~/.claude/scripts/dev-cycle.sh` … from an up-to-date checkout of the default branch, no `build-loop.sh` call and no step that needs one, and the branch landed through `pr-prep`" (SKILL.md:20-23), while the Rule says hg "does not switch off what the repository's own config can still name (a filter, a merge driver, commit signing): `--state` refuses those … so run it again … right before the iteration's commits" (SKILL.md:65-68). `--state` is a `build-loop.sh` call, so in the fallback (the only mode that can run today) neither step 0.1 nor the pre-commit re-run happens, and the fallback text does not say which Rules still bind (hg at all? the WT? `chore/dev-cycle-DATE-HHMM`?). Meanwhile the fallback hands briefs to the user "who starts each", so same-uid build loops do run beside the cycle.

Preconditions: a user-started loop plants a clean filter or merge driver in the shared config during a by-hand cycle. Impact: the orchestrator's `add`/`merge` run the planted command; this is the status quo on main (bare git, no `--state`), so not a regression, but the new text reads as if the protection were in force. 

**Recommendation:** in the fallback paragraph, either run `build-loop.sh --state` by the same route the fallback already uses for `dev-cycle.sh` (main's committed copy in claude-workflows, the image copy elsewhere) at step 0 and before the commits, or say in one sentence that until the D6 block lands, repository-config filters and merge drivers are not checked during a by-hand cycle (a named residual). Also say the hardened-git Rule (hg, F1's and F2's fixes) applies in the fallback; F1's preferred fix removes signing from this gap regardless.

#### F4. `questions.sh` and the fallback's `dev-cycle.sh` run through `~/.claude/scripts`, a loop-writable symlink

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:52-53`, `:20`, `:264-265`
**Boundary:** B4
**Move:** 1 (runtime-mutable ⇒ compromise-reachable)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: "`questions.sh` runs as `~/.claude/scripts/questions.sh`" (SKILL.md:52-53), in the same Rule that says D6 calls never use `~/.claude/scripts/` "so nothing a build loop edits runs as the gate" (:45-47). On this host `~/.claude/scripts` is `lrwxrwxrwx node node … -> /opt/claude-workflows/scripts`: the files are root-owned, the link is owned by the uid loops run as, so a loop can repoint it. questions.sh then runs as the orchestrator, in WT, and writes the questions files the cycle commits. Rated Low because a same-uid loop already reaches the orchestrator's session through its shell profile (the Bash tool initialises from it; `caller_gate`'s header names BASH_ENV/PATH as not covered), so this adds no new capability; it is an inconsistency between the D6 Rule's reasoning and the next sentence.

**Recommendation:** name questions.sh (and the fallback's dev-cycle.sh outside claude-workflows) by the root-owned image path the D6 block will use, or add one clause that this call rests on the same-uid residual Q-103 is to name.

#### F5. An `other` line on main blocks only dispatch; step 1 still runs main's health check

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:222-226`, `:255-257`
**Boundary:** B5
**Move:** 5
**Confidence:** Low
**Legibility-target:** for-author

Evidence: "Any `other` line, or a `refuse main-log:` line other than the bootstrap's own … blocks this iteration's dispatch and gets one `you: judgment` entry" (:222-226); step 1 then says "run the repo's health check from WT" (:255-256), WT being `worktree add … WT MAIN`, i.e. main including the ungated commit. `other` means a commit moved main that neither the gate nor the cycle landed; its scripts and tests then run in the orchestrator's session. Low for the same reason as F4 (a same-uid writer can already run code there), and because a user's own direct commit also reads as `other`, so blocking all execution on it would stall ordinary cycles.

**Recommendation:** either state that an `other` or rewritten-main line also skips step 1's health check and tests for that iteration (recorded), or leave it and name it with F4 in the same-uid residual. A judgment call; no change is defensible.

## Untested bypass candidates (move 11, guardrail: hg + `--state` over repo config)

Tested: `author.*`/`committer.*` (bypass, F2); `commit.gpgSign` on commit and merge (bypass, F1); `core.worktree` in the common config (linked WT unaffected; `--state` from MAIN_WT refused, `refuse state config: its path could not be read`, exit 2: fails closed); `trailer.x.command` + `ifMissing add` (did not run on `commit -m`).

Not tested:
- `rerere.enabled` / `rerere.autoUpdate` with a planted `rr-cache` resolution: on a conflicting merge of main into WT, a loop-chosen resolution could be applied (and staged) silently; `rerere.*` is not in `STATE_KEYS_RE`. Not tested for lack of time; the most plausible remaining content-integrity candidate.
- `core.autocrlf` / `core.eol` / `core.safecrlf`: transform staged content on `add`; data integrity, not execution.
- `gc.auto` / `gc.pruneExpire` after a commit: auto-gc with hooks off; plausible only as an availability nuisance.
- `core.editor` / `sequence.editor` on a merge without `--no-edit`: git opens no editor without a terminal; SKILL.md does not state the merge's form, so worth naming `--no-edit` when U4b2 writes it.

Because these are untested, the `hg` + `--state` combination does not appear in Endorsement Claims as a guardrail.

## Endorsement Claims

- **Claim:** SKILL.md's `hg` line carries exactly HARDEN's `-c` pairs and git_harden's environment, and the bats test fails if either drifts or a second `hg()` line appears.
  **Location:** `skills/dev-cycle/SKILL.md:60`, `test/scripts/build-loop-orchestrator.bats:355-372`
  **Evidence:** read-static (here); executed by fact-check i2 claim 2
  **Verified:** read the test's grep for one `^  hg() { env .* "\$@"; }$` line and its two set comparisons against `$H` and `$E`.
  **Not verified:** that the D6 block, when copied in under U4c, still matches (byte-equality test not yet written).
  **route: code-fact-check**
- **Claim:** `hg -c commit.gpgSign=false … commit` commits without running gpg when `commit.gpgSign true` is planted in `.git/config` (supports F1's preferred fix).
  **Location:** probe P2, `sec-probe1.out`
  **Evidence:** executed
  **Verified:** shim `gpg` first on PATH; commit rc 0; shim's marker absent.
  **Not verified:** the same pair on `git merge` (P3 ran the merge without it).
  **route: code-fact-check**
- **Claim:** with all four `author.*`/`committer.*` keys planted, a per-command `GIT_AUTHOR_*`/`GIT_COMMITTER_*` prefix on `hg commit` records the intended identity (F2's fix).
  **Location:** `sec-probe2.out`
  **Evidence:** executed
  **Verified:** `env-form: author=Orch <orch@x> committer=Orch <orch@x>`.
  **Not verified:** the prefix applied to `git merge` in WT.
  **route: code-fact-check**
- **Claim:** the identity recipe keeps a hostile `user.name` as data (no command substitution runs).
  **Location:** `skills/dev-cycle/SKILL.md:71-74`
  **Evidence:** executed by fact-check i2 claim 6 (not re-run here)
  **Verified:** that report's probe with a quote, `$(touch …)`, backticks and `;`.
  **Not verified:** a name holding a newline.
  **route: code-fact-check**
- **Claim:** `--main-log` accepts SINCE only as a full 40- or 64-hex id, so a `Main at:` line from a record cannot carry shell or option text into the call.
  **Location:** `scripts/build-loop.sh:543-545`
  **Evidence:** read-static
  **Verified:** the `[[ $# -eq 2 && "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage` test.
  **Not verified:** the orchestrator's own quoting of SINCE in its command line before the script sees it (SKILL.md's charset rule at :165-167 names "any check"; the D6 call form does not restate it).
- **Claim:** pr-prep's quiesce now stops probe processes only by PID after reading the command line, never by pattern.
  **Location:** `workflows/pr-prep.md:333`
  **Evidence:** read-static
  **Verified:** the replaced sentence.
  **Not verified:** that a command line identifies the owning session (two sessions' probes can look alike; the text accepts that).

## Primitive sweep

Primitive: process exec through git config (filters, drivers, gpg) in the orchestrator's git commands

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:227` `hg -C MAIN_WT worktree add … WT MAIN` (checkout: smudge filters) | S1 | `--state` at 0.1 (filter.* refused) | cleared — checked minutes before; time gap is the named residual |
| commits in WT (`SKILL.md:54-75`) | S1 | hg; `--state` re-run (filter.*, gpg.*) | F1 (commit.gpgSign not refused) |
| merge of main into WT (`SKILL.md:55`) | S1 | hg; `--state` re-run (merge.*) | F1 (signing, executed P3); rerere untested |
| `hg -C MAIN_WT show` (step 0.2) | S1 | hg; `--state` at 0.1 | cleared — object read, `log.showSignature=false`, textconv only via `diff.*` (refused) |
| `hg -C MAIN_WT worktree list/prune` (step 1) | S1 | hg | cleared — no content transform or exec path |
| plain `git config --global --get` (`SKILL.md:71`) | S2 | none needed (reads one file) | cleared for exec; value feeds F2 |
| fallback git (`SKILL.md:19-23`) | S1 | none (no `--state`) | F3 |
| `~/.claude/scripts/questions.sh` | S6 | none | F4 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | `--state` does not refuse commit signing; orchestrator commits and merges run gpg | Medium | B1 | `skills/dev-cycle/SKILL.md:65-68`, `scripts/build-loop.sh:612` | High |
| F2 | Repo-local `author.*`/`committer.*` override the `-c user.*` identity; `--state` passes | Medium | B1, B2 | `skills/dev-cycle/SKILL.md:69-74` | High |
| F3 | By-hand fallback runs no `--state`; the Rule's detection half never holds until Q-140 | Medium | B1, B4 | `skills/dev-cycle/SKILL.md:19-23` | Medium |
| F4 | `questions.sh` via the node-owned `~/.claude/scripts` symlink | Low | B4 | `skills/dev-cycle/SKILL.md:52-53` | Medium |
| F5 | `other` on main blocks dispatch only; health check still runs main's code | Low | B5 | `skills/dev-cycle/SKILL.md:222-226` | Low |

## Overall Assessment

The frame is sound in shape: `--state` first, before any other git command, then `--main-log` with a format-checked SINCE, then the worktree and the digest; stop rules that treat an undocumented exit or a timeout as "nothing decided"; and an `hg` line pinned to the lib's list. The weak point is the boundary between what `hg` overrides (always) and what `--state` only detects (when it runs): two classes of repository config fall in neither, commit signing (F1, the open fact-check Incorrect) and identity keys (F2), and the only mode that can run today, the by-hand fallback, has no `--state` at all (F3). All three are fixable in place: one `commit.gpgSign=false` pair added to HARDEN, the snippet and `hg` (the pin test keeps them equal; no behaviour change for the scripts, which never sign); a per-command `GIT_AUTHOR_*`/`GIT_COMMITTER_*` prefix in the identity recipe; and one fallback sentence. None is architectural. The single most important change is F1's HARDEN pair, because it turns a race-prone detection into an always-on override and makes the Rule's sentence true. No findings beyond these within the code paths read; endorsement claims pending execution verification where marked.

## Goal-Alignment Note

The goal is landing U4b1 after a clean review-fix loop, with SKILL.md as instructions an orchestrator executes. F1 is the fact-check's open Incorrect seen from the security side, and the recommendation picks the hardening fix over the wording fix because the pair is tiny, held by the existing pin test and inert for the scripts that share HARDEN; if the unit's cap or scope keeps lib edits out, the wording fix plus a filed row is the fallback, stated in F1. F2 is new, executed, and a one-line change to text this unit owns. F3 asks only for a sentence in the fallback paragraph. F4 and F5 are Low, sit inside the same-uid residual the plan already routes to Q-103, and should not hold the merge.
