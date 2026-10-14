Commit: 18fd4e1e

# Security Review — feat/build-loop-u4c (third confirming pass, fix range)

**Scope:** `git diff 43b8d7ed..18fd4e1e`, mainly step 0.1 of `skills/dev-cycle/SKILL.md` (`:284-305`). Also the lib comment (`scripts/lib/dev-cycle-read.sh:1962-1967`), the pin-test name, plan text and override rows 820-822. Context read: SKILL.md's Hardened-git Rule (`:62-87`) and `devcontainer-config/install.sh` (`repo_git`, `head_commit`, `git_state_gate`, `assemble`, `:172-340`).
**Date:** 2026-10-14
**Based on:** docs/reviews/security-review-2026-10-14-u4c-confirm.md (second pass, at e58adc1f), docs/reviews/code-fact-check-report-2026-10-14-u4c-confirm.md, rubric docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md

**Verdict line:** one finding is Medium **and introduced by this range** (Finding 1). It is the same class as confirm2 F1, but on step 0.1's other host route. The revert of confirm2 F1 is complete.

## Trust Boundary Map

```
B1:  [/opt/claude-workflows/.manifest (root-owned)]           → [step 0.1 reads C, A]                         → [hg cat-file / rev-list / diff in MAIN_WT]
B2:  [MAIN_WT .git objects and refs (sandbox-writable)]       → [hg (no hooks/fsmonitor/global config)]        → [image-off-main / image-lag decision (advisory)]
B3:  [WT questions files]                                     → [suppression of image-off-main-C12]            → [whether an entry is filed]
B8:  [host checkout HEAD]                                     → [paste: test "$(git rev-parse HEAD)" = M]      → [install.sh, git_state_gate first]
B10 (removed): [host .git/config, attributes]                 → [paste's bare `git diff --quiet HEAD -- ...`]  → [host exec before the gate]
B11 (new): [host .git/hooks, .git/config, attributes]         → [entry [1]: "check main out on the host"]      → [host exec (post-checkout hook, fsmonitor, smudge filter) before the gate]
```

| Label | Source | Mutability | Trust |
|---|---|---|---|
| S1 | `.manifest` `commit=`/`assembled_from=` | deploy-time (root-owned image) | trusted as a value; C is only ever a git revision argument to hg, and A is a `cd` target in a paste the user reads |
| S2 | MAIN_WT objects, refs, `.git/config` | runtime-mutable by any sandbox session | UNTRUSTED toward exec sinks (hg strips hooks, fsmonitor and global config; `--state` refuses filter/diff/merge keys first); trusted only for the advisory decision |
| S3 | WT `docs/working/questions*.md` | runtime-mutable (orchestrator-only writer by D11; same-uid writable) | UNTRUSTED for suppression; consequence is advisory only |
| S4 | host checkout `.git/hooks/*`, `.git/config`, `.git/info/attributes` (bind-mounted, sandbox-writable per confirm2's S9) | runtime-mutable by any session | UNTRUSTED toward host exec sinks. install.sh's design is that its state gate precedes every host git call. |

The range removes B10 and adds B11 (explicit in e58adc1f's option text). 18fd4e1e's new parenthetical claims, without qualification, that the gate precedes every git call.

## Findings

#### 1. The image-off-main [1] route has the user run `git checkout main` on the host before install.sh's state gate

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:293-295` (option [1]) and `:300-301` (the claim)
**Boundary:** B11
**Move:** 1 (trust boundaries), 12 (sweep of every host git call)
**Confidence:** High on the mechanism (executed). Medium on reach: it needs a writer to the host checkout's `.git`, the same reach as confirm2 F1. It also assumes A is the bind-mounted checkout, which `assembled_from=/home/magfrump/claude-workflows` suggests but this sandbox cannot confirm.
**Legibility-target:** the `image-off-main-C12` entry's option [1] text and the paste's parenthetical.

Evidence: "file one `you: judgment` entry `image-off-main-C12` (C's first 12 hex), unless WT's questions files hold one: [1] rebuild from main (check main out on the host, then the paste below), [2] keep this image." Also: "(host; then a new sandbox launch; install.sh's own state gate runs before any other git call)". install.sh: "`git_state_gate   # before any other git call on the checkout (review R1)`" (`:332`), and `repo_git` adds "`-c core.hooksPath=/dev/null -c core.fsmonitor=false`" (`:181`). Because of that, the gate never inspects `.git/hooks`.

The revert closed the paste's own pre-gate git call. Option [1] now tells the user to run an unhardened `git checkout main` in the host shell before the paste. A checkout runs `.git/hooks/post-checkout`, `core.fsmonitor` and any smudge/clean filter. A sandbox session can write all of these, and install.sh exists to refuse them before its first git call. Executed hermetically (scratch repo, git in this sandbox): with a `post-checkout` hook and `core.fsmonitor` both set to marker commands, `git rev-parse HEAD` ran neither, and `git checkout main` ran both (`FSM_RAN`, `HOOK_RAN` created). A planted hook is not refused by install.sh even after the fact, because it never reads `.git/hooks`. 18fd4e1e's parenthetical "install.sh's own state gate runs before any other git call" is false on exactly this route. On provenance: a checkout was already implied at 43b8d7ed, since its "rebuild from main, the paste below" fails `test HEAD = M` without one. The explicit host instruction is e58adc1f's, and the claim is 18fd4e1e's, so I count the finding as introduced by the range. A reviewer who weighs only the pre-existing necessity could call it pre-existing. That reading is the only one under which this pass is clean.

**Recommendation:** have option [1] do the checkout inside the sandbox, so a planted hook or filter runs there rather than on the host. One way is `hg -C MAIN_WT checkout main` or a sandbox shell, since the host checkout is the bind mount. Another is to name a host form that runs the gate first. Then scope the parenthetical to the paste: "the paste's first git call is `rev-parse`; install.sh's state gate runs before any other". A one-line edit to each of the two sentences.

#### 2. (Informational, not introduced) Moving the host HEAD to M on the image-lag route is outside the paste too

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:299-300`
**Boundary:** B8
**Move:** 12
**Confidence:** Medium

Evidence: "the paste `cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh`". When host HEAD is not at M, the paste fails closed (confirm2 log `u4c-confirm2-paste.log`: "case HEAD moved: paste exit=1"). Whatever the user then does to reach M is an ordinary host git call. This shape predates the range, and in the usual layout MAIN_WT already has main checked out. Recorded so Finding 1's fix can use the same wording for both routes. Not merge-relevant.

## Revert check (confirm2 F1)

- `git diff 43b8d7ed..18fd4e1e -- skills/ scripts/ test/ devcontainer-config/ | grep -c 'git diff --quiet HEAD'` printed `0`. The net range carries no trace of the host-side diff, and `git diff e58adc1f..18fd4e1e` shows the exact removal.
- The paste is back to 43b8d7ed's form. Its only pre-gate host git call is `git rev-parse HEAD`. Executed above: it ran neither a marker fsmonitor nor a hook, which matches confirm2's execution.
- Override row 822 records the revert as "Fixed by revert", and row 821 keeps the original F4 as pre-existing (decision 035). This is consistent.

## Step 0.1 sandbox calls (all `hg -C MAIN_WT`, under the Rule at `:62-87`)

Primitive: git execution on S2-controlled repository state

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cat-file -e 'C^{commit}'` (`:288`) | S1 C, S2 objects | hg; `--state` ran first (`:279`) | cleared: object lookup, no worktree, index, filter or hook |
| `rev-list --first-parent M` (`:290`) | S1 C, S2 history | hg; `--state` first | cleared: history walk only. Membership is an exact-line match, so an abbreviated or garbled C reads as off-main (files an entry; fails toward signal) |
| `diff --quiet C M -- PATHS` and `--name-only` (`:296`) | S2 trees | hg; GIT_LITERAL_PATHSPECS; `--state` refuses `diff.*` keys | cleared: tree-to-tree and unchanged by the range (pre-existing, reviewed at 43b8d7ed) |
| host `git rev-parse HEAD` (paste) | S4 | none needed: runs neither hook nor fsmonitor (executed) | cleared |
| host `git checkout main` (option [1]) | S4 | none: precedes install.sh's gate | **Finding 1** |
| host `./devcontainer-config/install.sh` | S4 | `git_state_gate` before its first git call | cleared (pre-existing; working-tree install.sh is row 821/decision 035) |

## First-parent membership and keyed suppression

- First-parent test: it closes merged-branch commits (confirm2's execution against the U4b2 history). A fast-forwarded branch is `--main-log`'s `other` stop (confirm2 bypass 3). No bypass is new in 18fd4e1e, which did not touch this text.
- Keyed suppression ("unless WT's questions files hold one"): a planted or answered entry with the same key silences only that C. A different C is a different key. The residual is confirm2 F2 (Low), and the range does not change its basis. Not re-filed.
- The Exit-0 listing never answers an entry (D8), so nothing in the range lets repository data close an entry.

### Untested bypass candidates

- The `hg rev-list` cost on very long histories (availability, not security; advisory step).

## Endorsement Claims

- **Claim:** the net range removes the paste's host-side `git diff --quiet HEAD -- devcontainer-config/install.sh`.
  **Location:** `skills/dev-cycle/SKILL.md:299-301`
  **Evidence:** executed
  **Verified:** grep count 0 over the net range; `git diff e58adc1f..18fd4e1e` shows the removal.
  **Not verified:** the installed image copy of SKILL.md, which is at the image's commit, not this branch.
- **Claim:** the paste's remaining pre-gate host call, `git rev-parse HEAD`, ran neither a planted post-checkout hook nor a `core.fsmonitor` command in a scratch repo.
  **Location:** paste, `:299`
  **Evidence:** executed
  **Verified:** marker files absent after `rev-parse`, present after `checkout`.
  **Not verified:** the user's host git version (the sandbox git was used).
- **Claim:** `bats test/scripts/build-loop-orchestrator.bats` passed 26/26 at 18fd4e1e.
  **Location:** `test/scripts/build-loop-orchestrator.bats`
  **Evidence:** executed
  **Verified:** 26 `ok` lines, no `not ok`.
  **Not verified:** `scripts/health-check.sh` (not run, per brief).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Option [1] has the user run `git checkout main` on the host before install.sh's gate; the new parenthetical claims the gate precedes every git call | Medium | B11 | `skills/dev-cycle/SKILL.md:293-295, 300-301` | High (mechanism), Medium (reach) |
| 2 | Moving host HEAD to M is also outside the paste (pre-existing) | Informational | B8 | `skills/dev-cycle/SKILL.md:299-300` | Medium |

## Overall Assessment

The revert fully removes confirm2 F1. The sandbox-side git calls in step 0.1 all go through `hg` after `--state`. First-parent membership and keyed suppression open nothing that was not already filed. One Medium is introduced, in prose rather than code. The `image-off-main` [1] option tells the user to check main out on the host before install.sh's state gate. That runs planted hooks, fsmonitor or filters on the host, which is executed and the same class as confirm2 F1. 18fd4e1e's added claim that the gate runs before any other git call is false on that route. It can be fixed in place with two sentence edits: do the checkout in the sandbox, and scope the claim to the paste. No HALT pattern applies. Under the brief's rule (no Medium introduced by the range), this pass does not clear the merge until Finding 1 is fixed or the user rules it pre-existing.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/security-review-2026-10-14-u4c-confirm3.md (first line `Commit: 18fd4e1e`), structured per the security-reviewer skill."
- **Answered:** whether the revert removes confirm2 F1 (yes, executed); every step-0.1 sandbox git call (cleared, under hg after `--state`); every host command the step has the user run (one runs before the gate: Finding 1); the first-parent test and keyed suppression (nothing new); bats 26/26.
- **Out of scope:** the deliberately hostile same-uid loop (Q-103); code before 43b8d7ed except as context; the health check.
- **Escalate:** Finding 1 decides the merge. The caller or user must choose to fix the two sentences (recommended, about one line each) or rule the checkout pre-existing, since 43b8d7ed's option implied it.
