Commit: a80955a2

# Security Review — feat/build-loop-u4c (confirm3 F1 fix, narrow pass)

**Scope:** `git show a80955a2 -- skills/dev-cycle/SKILL.md`, the two sentence edits in step 0.1 (`:293-294` option [1], `:300-303` the paste's parenthetical). Context: docs/reviews/security-review-2026-10-14-u4c-confirm3.md (F1, F2) and `devcontainer-config/install.sh:181,332`.
**Date:** 2026-10-14
**Threat model:** a hostile same-uid loop is out of scope (Q-103). In scope: text that makes the user's host run repository config that a sandbox session planted.

**Verdict line:** confirm3 F1 is closed. The scoped claim holds when executed. The commit introduces no Medium-or-above finding.

## Q1. Does a80955a2 close confirm3 F1?

Yes, both halves.

- **The instruction.** Old: "[1] rebuild from main (check main out on the host, then the paste below)". New: "[1] rebuild from main (the paste below, which refuses until the host checkout is at M)". The skill no longer tells the user to run an unhardened host git command. The paste fails closed when HEAD is not M: `test ... = M && ./devcontainer-config/install.sh`, so install.sh never runs (confirm2's log: "case HEAD moved: paste exit=1").
- **The claim.** Old: "install.sh's own state gate runs before any other git call", which was false on the checkout route. New: "the paste's only git call before install.sh's state gate is `rev-parse`, which runs no hook or fsmonitor; any other git command the user runs on the host here, a checkout to reach M included, can run one a sandbox session planted, install.sh's own trust model". This now claims only what the paste does, and it names the remaining exposure instead of denying it.
- A grep of `skills/ scripts/ test/ devcontainer-config/install.sh` for "check main out" and "before any other git call" finds only install.sh's own code comment (`:332`, which is about install.sh's own calls and is accurate). No stale copy of the old claim is left.

## Q2. Is the new parenthetical true? (executed)

Setup: a scratch repo under `mktemp -d /tmp/claude-1000/u4c-n.XXXXXX`, deleted afterwards. Sandbox git version 2.39.5. Planted config:
- marker hooks in `.git/hooks/` (`post-checkout`, `pre-commit`, `reference-transaction`, `post-index-change`, `pre-auto-gc`), and the same hooks in a second directory set as `core.hooksPath`
- `core.fsmonitor`
- `filter.evil.{smudge,clean,process}`, with `.gitattributes` applying `filter=evil diff=evil`
- `diff.evil.textconv`, `diff.external`
- `core.pager`, `pager.rev-parse`
- `core.sshCommand`, `core.alternateRefsCommand`
- `gc.auto=1`, `core.untrackedCache=true`

Commands and results:
- `GIT_TRACE=2 sh -c 'test "$(git rev-parse HEAD)" = M && echo PASTE_TEST_OK'`, run once with `.git/hooks` and once with `core.hooksPath`. Both printed `PASTE_TEST_OK`. The trace showed only `trace: built-in: git rev-parse HEAD`, with no child process. No marker file was created.
- `git rev-parse HEAD` under a pty (`script -qc`), to give the pager a chance to run: no marker file.
- Control, to show the harness detects execution. `git checkout` created `FSM_RAN` and `PROCESS`, and once the process filter was removed it also created `CLEAN`, `HP_post-checkout`, `HP_post-index-change` and `HP_reference-transaction` (hooksPath), then `HOOK_post-checkout` and `HOOK_post-index-change` (`.git/hooks`).

The parenthetical says rev-parse "runs no hook or fsmonitor". That is true, and the test supports a stronger statement: rev-parse ran none of the configured commands above. One limit remains: the user's host git version was not tested.

## Q3. Findings introduced by a80955a2

#### 1. (Low, residual of confirm3 F1/F2) Option [1] still requires a host-side move to M, and the warning sits only in the image-lag paste's parenthetical

**Severity:** Low
**Confidence:** Medium
**Location:** `skills/dev-cycle/SKILL.md:293-294`, `:300-303`
**Evidence:** "[1] rebuild from main (the paste below, which refuses until the host checkout is at M)"; and "any other git command the user runs on the host here, a checkout to reach M included, can run one a sandbox session planted, install.sh's own trust model".

In the off-main case the host checkout is usually not at M, so choosing [1] still means the user has to move HEAD somehow before the paste will run. The skill no longer prescribes that command. It also discloses the risk, but only inside the image-lag paste's parenthetical. The text does not say whether that warning is copied into the `image-off-main-C12` entry's body, so a user answering [1] from that entry may never see it. This is the same shape as confirm3 F2, which was rated Informational and pre-existing. It is the trust model install.sh already accepts, and nothing in this commit makes it reachable in a new way. Optional fix: have the `image-off-main` entry carry the same "any other host git command ... install.sh's own trust model" clause. Not merge-relevant.

No Medium-or-above finding.

### Untested bypass candidates

- After a refused paste, the shell has already run `cd A`. A git-aware prompt or direnv in the user's host shell could then run `git status` in A, which runs fsmonitor and hooks. That is the user's shell configuration, outside the skill's text, and it already applied before this commit.
- The user's host git version (only the sandbox's 2.39.5 was tested).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The host move to M is still needed for [1], and the warning is only in the image-lag parenthetical | Low | `skills/dev-cycle/SKILL.md:293-303` | Medium |

## Goal-Alignment Note

- **Success criterion (verbatim):** "a short report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/security-review-2026-10-14-u4c-confirm3b.md (first line `Commit: a80955a2`), with findings (Severity, Confidence, verbatim Evidence) and a Goal-Alignment Note."
- **Answered:** (1) F1 closed, yes. (2) Parenthetical true, executed: rev-parse ran no hook (either location), fsmonitor, filter, textconv, pager or other configured command, while the checkout control ran them. (3) Nothing Medium or above introduced. One Low residual.
- **Out of scope:** the hostile same-uid loop (Q-103); the rest of the branch; the health check and bats (not run, since the change is prose only).
- **Escalate:** nothing. Finding 1 is optional polish.
