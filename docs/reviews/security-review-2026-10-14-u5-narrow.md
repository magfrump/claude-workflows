Commit: 1a3d432a

# Security Review — feat/build-loop-u5, narrow check of the post-final-pass fix batch

**Scope:** `git diff b5eaedf6..1a3d432a` (8cff4877, 1a3d432a): Q-156's paste and prose, SKILL.md step 10's constraints-entry rule, `docs/dev-cycle.md` Policy/Slots/Never-line prose, Q-103 [2], Q-149, Q-151, roadmap and override rows. Review artifacts in the range were read as context only. Read for context: `devcontainer-config/install.sh` (`repo_git`, `git_state_gate`, `extract_commit`), `scripts/build-loop.sh` (`nrules`, `srules`, `never_res`, `read_settings`), `scripts/run-tests.sh` and `scripts/health-check.sh` (test and shellcheck discovery), SKILL.md step 10, Q-155.
**Date:** 2026-10-14
**Based on:** `security-review-2026-10-14-u5-final.md` (F1, the item this batch fixes), `-i1`, `-i2`; rubric `code-review-rubric-2026-10-14-feat-build-loop-u5.md` (A13, A14, C22, C28, C30, C31). No code-fact-check report for this batch was provided to me.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and
> documentation have not been independently verified. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

## Trust Boundary Map

```
B4: host checkout .git (config, config.worktree, refs, info/) → Q-156 paste guard (now + core.attributesFile) → install.sh git_state_gate → git archive → host image, ~/.claude
B1: build-loop branch tree (same-uid loop)                    → gate N rules (both policies) / S rules (self-merge) → main
B6: WT's questions files (main's copy + orchestrator edits)   → SKILL.md step 10 constraints-entry rule           → one you: judgment entry, or none
```

Input-source classification:

```
S4: host checkout .git: config, config.worktree, extensions.*, include targets — runtime-mutable (bind-mounted rw into
        sandboxes) — UNTRUSTED for host exec and for any git read that decides what installs
S1: loop branch tree                     — request-time    — UNTRUSTED (all sinks)
S6: pinned M = 8cff4877aa30a9417b48bd792ef60319502d7e78 — code-constant in the entry — trusted as a name
S8: questions.md / questions-archive.md on main — runtime-mutable (orchestrator; loops refused by the N rules; F19 residual)
        — trusted only for notification de-duplication; not for dispatch decisions
S9: host HOME's ~/.config/git/attributes, global/system git config — deploy-time, host-owned — trusted (outside the
        reachable-environment bar)
```

The batch changes text only, but B4's text is a command the user will paste on the host. The new `core.attributesFile` test closes final F1's `.git/config` path. A sibling config file the same writer controls, `config.worktree`, still steers the archive and passes both the paste and install.sh's gate (Finding 1). B1's prose changes match the code. B6's rule change de-duplicates a notification and leaves dispatch gated on `constraints ok`.

## Findings

#### 1. `core.attributesFile` in `config.worktree` (with `extensions.worktreeConfig`) passes the new paste test and install.sh's gate, and still shapes the archive

**Severity:** Medium
**Location:** `docs/working/questions.md:494` (the new `git config --local --get core.attributesFile` test), `:491` (prose: "the checkout's config sets no `core.attributesFile`"); `devcontainer-config/install.sh:208` (`GIT_EXEC_KEYS_RE`), `:180-182` (`repo_git`), `:279-280` (archive)
**Boundary:** B4
**Move:** 11 (bypass enumeration), 12 (sweep of the archive primitive)
**Confidence:** High for the mechanism (executed, git 2.39.5). Medium for impact: same as final F1. install.sh's `review_diff` shows a dropped file as a whole-file deletion before the y prompt.

`git config --local` reads `$GIT_DIR/config` only. A writer of `.git` can set `extensions.worktreeConfig=true` in `config`, then put `core.attributesFile` in `.git/config.worktree`. Git's normal lookup honors that, so `git archive` does too. In `/home/node/.claude/jobs/00bcf178/tmp/u5/sec-narrow/r1` (`probe.sh`, case E), a replica of the paste guard printed `PASS`. A replica of `git_state_gate`'s read printed nothing for either file: it does read `config.worktree`, but only for exec keys. The archive of `scripts/` dropped `scripts/a.sh` (`export-ignore`). This is the attack final F1 named, through the one config file the fix does not read. Q-156's prose says the paste checks "that the checkout's config sets no `core.attributesFile`", and that sentence is broader than the test.

The other enumerated candidates do not open anything new (all executed in the same probe):
- `[CORE] ATTRIBUTESFILE` (case): refused by the paste.
- `include.path` or `includeIf` pointing at a file that sets it: the paste passes, because `--local` does not follow includes. install.sh's gate then refuses the `include` key before the archive, so the release still stops.
- Empty value: the paste passes, and the archive is unchanged (no attributes file).
- Valueless key (`[core] attributesFile` with no `=`): every git call fails, so every paste comparison is empty = empty and the paste passes (see Informational note). install.sh's gate then fails on the bad config and exits before installing.

**Recommendation:** Make the paste test scope-aware and include-following, for example
`test -z "$(git config --includes --show-scope --get-all core.attributesFile | grep -Ev '^(global|system)[[:space:]]')" || { echo "release refused: core.attributesFile set"; exit 1; }`.
In the scratch repo this refused the `config.worktree`, `include.path` and local cases and printed nothing on a clean repo. A simpler alternative is a second test with `git config --worktree --get core.attributesFile`, which reads `config.worktree` when the extension is on and `config` otherwise. Then reword the prose to "no repo-level config (`config`, `config.worktree`, or an include) sets `core.attributesFile`". Note the `config.worktree` case on the deferred install.sh roadmap item and its override row (`docs/roadmap.md:78`, `override-log.md:833`). The `-c core.attributesFile=/dev/null` fix in `repo_git` covers this case too.

### Informational: the paste's guard treats a git failure as a pass

**Severity:** Informational (pre-existing shape; the new line follows it) · **Boundary:** B4 · **Move:** 3 · **Confidence:** High (executed, probe case F)

Every check is `test -z "$(git …)"` or `test "$(git …)" = "$(git …)"`. A config that makes git fail (case F) empties every output, so all checks pass and install.sh runs. install.sh's `git_state_gate` fails closed on the same config (`could not read … git config exit`), so nothing installs. This is not exploitable today because install.sh is the backstop. If the paste is ever meant to stand alone, start the subshell with `git rev-parse --verify -q HEAD >/dev/null || { echo "release refused: git cannot read the checkout"; exit 1; }`.

### Untested bypass candidates

- `~/.config/git/attributes` (git's default when `core.attributesFile` is unset; probe case H showed the archive honors it) and global/system `core.attributesFile`. These are host-owned. I did not check whether any sandbox mounts the host `~/.config`. If one does, this becomes reachable.
- `attr.tree` / `GIT_ATTR_SOURCE` (git 2.42+). Not testable on 2.39.5. Reading attr.c from memory, archive's index direction ignores it. Not confirmed against the host's git version.
- A `config.worktree` or other config written between the paste and install.sh (TOCTOU). Carried from the final review, unchanged.

## Endorsement Claims

- **Claim:** In a scratch repo with a hooks directory full of hooks, `core.fsmonitor`, `core.pager`, `pager.config`/`pager.rev-parse`/`pager.for-each-ref`, `filter.x.*` with `info/attributes` assigning it, `gc.auto=1` and `core.alternateRefsCommand` all planted to log to a marker, the post-fix paste guard (run under a pty) wrote 0 marker lines. A control `git status` afterwards wrote 3, which shows the plants were live.
  **Location:** `docs/working/questions.md:491`, `:494`
  **Evidence:** executed (`sec-narrow/probe2.sh`, git 2.39.5)
  **Verified:** that set of plants, with the guard copied verbatim except the cd, M, the path list and install.sh (replaced by echo).
  **Not verified:** the host's git version and shell (aliases or functions named `git`/`test`), and planted state outside that set (for example `core.sshCommand`, which these commands do not reach by reading).
  **route: code-fact-check**
- **Claim:** The new test refuses a `core.attributesFile` in `.git/config` in any key case. That is the path final F1 executed.
  **Location:** `docs/working/questions.md:494`
  **Evidence:** executed (probe cases A, B)
  **Verified:** `release refused`-equivalent output for a lower-case key and an upper-case `[CORE] ATTRIBUTESFILE`.
  **Not verified:** `config.worktree` (Finding 1) and include targets (refused later by install.sh's gate, not by the paste).
- **Claim:** At 1a3d432a, the root `.gitattributes` and the eight released directories have the same tree as at the new M=8cff4877, and 8cff4877..1a3d432a changes only `docs/` paths.
  **Location:** `docs/working/questions.md:470`
  **Evidence:** executed (`git rev-parse` per path; `git diff --name-only`)
  **Verified:** all nine paths are equal, and no non-`docs/` path changed.
  **Not verified:** the merge commit on main (not yet created).
- **Claim:** The new both-policy clause "any symlink, gitlink or `.git*` path" matches `nrules`: a mode outside 100644/100755 is denied, and `pathform` denies any part starting `.git`. `nrules` also denies other path forms (characters, leading `-`), which the clause does not list but does not claim to exhaust.
  **Location:** `docs/dev-cycle.md:33`; `scripts/build-loop.sh:1143-1146`
  **Evidence:** read-static
  **Verified:** the `nrules` branches and the DENY texts.
  **Not verified:** `pathform`'s body (I read only its DENY text).
- **Claim:** "Any path under a new top-level name" is self-mergeable as stated, and in the health check such a path is only read statically: `run-tests.sh` collects `.bats` files under `test/` only, and repo-wide discovery feeds `shellcheck`, which does not execute.
  **Location:** `docs/dev-cycle.md:55-57`; `scripts/run-tests.sh:185,214`; `scripts/health-check.sh:497-504`
  **Evidence:** read-static
  **Verified:** those discovery lines, and `srules`, which lets an off-floor, off-never path through when Paths: lists it.
  **Not verified:** the other health-check gates' file discovery beyond those lines, and whether a session loads anything (skills, instructions) from a non-dot new top-level directory.
- **Claim:** A duplicated, bold or listed copy of a settings key fails toward the safe side: the policy reads `review` unset, and the never line reads malformed, which turns self-merge off. Slots falls back to 3.
  **Location:** `docs/dev-cycle.md:16-18`; `scripts/build-loop.sh:803-825`
  **Evidence:** read-static
  **Verified:** `read_settings`' `cnt > 1` branches and the never line's next-line check.
  **Not verified:** `SETTINGS_AWK`'s letters-only matching (the prose's "found by its letters alone").
- **Claim:** Step 10's new rule changes only whether a duplicate `constraints-doc-missing` entry is filed. Dispatch still runs only while `--settings` prints `constraints ok`, so a planted or stale answered entry suppresses a notification, not the gate.
  **Location:** `skills/dev-cycle/SKILL.md:770-772`
  **Evidence:** read-static
  **Verified:** the step 10 sentence, and the N rules' refusal of loop edits to the questions files (`nrules` cycle word).
  **Not verified:** how the orchestrator matches "holds one with that slug" in `questions-archive.md` (prose rule, no script).

## Primitive sweep

```
Primitive: host execution of install.sh after a git-read guard / git archive of HEAD
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `docs/working/questions.md:494` (Q-156 paste, new M) | S4, S6 | HEAD==main; no refs/replace; no info/grafts; no --local core.attributesFile; 9-path tree pin | final F1's .git/config path closed (executed); Finding 1 (config.worktree); git-failure pass = Informational |
| `skills/dev-cycle/SKILL.md:309-310` (step 0.1 paste) | S4, S6 | HEAD==main's M | not in this diff; carries i2 F2 / final F1, deferred (roadmap:76-80, override rows 832-833) |
| `devcontainer-config/install.sh:279-280` (archive) | S4 | no-agent gate; git_state_gate | pre-existing, deferred (out of scope per brief); Finding 1 also reaches it |
```

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `core.attributesFile` in `config.worktree` passes the new `--local` test and install.sh's gate | Medium | B4 | `questions.md:491,494`; `install.sh:180-182,208,279-280` | High (mechanism) / Medium (impact) |
| — | Paste guard passes when git cannot read the checkout (install.sh fails closed) | Informational | B4 | `questions.md:494` | High |

## Overall Assessment

The batch closes final F1 for the path that review executed (`.git/config`, any key case). It adds no command that runs planted state before install.sh's gate: `config --get`, like `rev-parse` and `for-each-ref`, ran no hook, fsmonitor, pager or filter in an executed probe under a pty. It does not fully close F1 for this release. The same writer can put `core.attributesFile` in `config.worktree` behind `extensions.worktreeConfig`, and that passes both the paste and install.sh's gate. The fix stays in place in Q-156: a scope-aware `--show-scope --get-all` test (or a second `--worktree` test) and a one-clause prose correction. install.sh's whole-file payload diff remains the backstop, so this stays Medium. The step 10 rule and the settings prose (both-policy refusals, new top-level names, copy handling) match the code I read and change no decision input for Q-103/Q-149 in a misleading direction. There are no other findings within the code paths read. Endorsement claims are pending execution verification where they are read-static.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u5/docs/reviews/security-review-2026-10-14-u5-narrow.md, first line `Commit: 1a3d432a`, structured per the security-reviewer skill.
- Answered: focus (1): partly closes F1. No pre-gate execution. One new Medium (Finding 1). Focus (2): no security effect, and dispatch stays gated. Focus (3): accurate against `nrules`, `srules`, `read_settings` and test discovery.
- Out of scope: install.sh's halves (deferred), the review artifacts in the range, and doc-consistency items. One I noticed: Q-155's Interim still says step 10 files nothing more "while this entry is open", but after 8cff4877 an answered entry also suppresses filing. That is for the narrow fact-check, not this review.
- Decisions I made: rated Finding 1 Medium under the floor rule, matching final F1, because the same writer and mechanism are reachable. I did not re-raise the TOCTOU and host-shell candidates, which are carried from the final review.
- Processes: both probes ran under `timeout` in the foreground and exited. No probe process remains (`ps` count 0).
