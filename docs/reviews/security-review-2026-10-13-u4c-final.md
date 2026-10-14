Commit: 43b8d7ed

# Security Review — feat/build-loop-u4c (final confirming pass, full branch)

**Scope:** `git diff main...feat/build-loop-u4c` at 43b8d7ed. The new code since the i2 review (f2cc21e6..43b8d7ed) gets the closest read: step 0.1's `image-off-main` / `image-lag` logic and paste, the Rule's wording, step 9.1's `check` note, and the GATE_CODE pin test. It is read together with what that code reads or feeds: `/opt/claude-workflows/.manifest`, `devcontainer-config/install.sh`'s `assemble`, and `--cycle-diff`'s QDIFF_AWK.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4c-final.md` (k=3), rubric `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md`, `security-review-2026-10-13-u4c-i1.md`, `security-review-2026-10-13-u4c-i2.md`
**Threat model applied:** a deliberately hostile same-uid loop is out of scope (plan "What the gate can and cannot do", Q-103, Q-133). In scope: honest slips, gate-gaming, and quiet routes by which repository data substitutes the gate.

## Trust Boundary Map

```
B1:          [repository data: refs, gitfile]                    → [d6() script choice]                          → [what runs]          — code constant since i1; unchanged
B2:          [/opt/claude-workflows/** files and directories]     → [own(): missing test, then owner/link/-w]     → [bash D6_OPT/scripts/SCRIPT] — unchanged since i2
B3:          [orchestrator env: PATH, BASH_FUNC_*, settings]      → [outer bash -s]                               → [what executes]      — Q-103 residual, wording fixed (i2 F3)
B5:          [QUESTIONS_LIVE / QUESTIONS_ARCHIVE]                 → [launch env -u]                               → [questions.sh writes] — unchanged since i2
B6 (moved):  [.manifest commit= (C), assembled_from= (A)]         → [step 0.1: cat-file, merge-base --is-ancestor, diff --quiet] → [image-off-main / image-lag entry, its paste]
B7 (moved):  [MAIN_WT refs/heads/main (M), objects, config]       → [the same three hg calls]                     → [which entry is filed, or closed]
B8:          [host checkout HEAD and working tree at install]     → [paste: test HEAD = M; install.sh assemble]   → [the image, hence the gate]
B9 (new):    [orchestrator-written answer on the image-lag entry] → [--cycle-diff QDIFF_AWK, --answered]          → [the land]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | `D6_OPT`, the SCRIPT allowlist, step 0.1's PATHS line (pinned to GATE_CODE) | code-constant | trusted (all sinks) |
| S2 | `.manifest` `commit=` / `assembled_from=` (root 0444 in the image) | deploy-time | trusted as "what the image holds and where it was built". A is interpolated into a host paste: trusted only because install.sh writes it from `$REPO_ROOT` |
| S4 | MAIN_WT's refs, objects, `.git/config` | runtime-mutable by any loop | UNTRUSTED for the advisory verdict. Moving main is `--main-log`'s stop, and `hg` flags cover config-driven exec |
| S6 | the host checkout's HEAD and working tree (bind-mounted `/workspace`; sessions switch its branch and edit its tree) | runtime-mutable by any session | UNTRUSTED as "reviewed code" toward the image and toward host execution of install.sh |
| S7 | the ancestry relation "C is on main" as `--is-ancestor` computes it | derived from S2 and S4 | UNTRUSTED as "C passed review": any-parent ancestry includes every commit of every merged branch (Finding 1) |
| S8 | an answer line the orchestrator writes into questions.md | agent-written | UNTRUSTED to `--cycle-diff` by design: only `--answered` IDs for the user's own answers pass |

The fix range now trusts two things. The first is `--is-ancestor` as a statement that the running gate was built from main (S7). The second is the orchestrator's own observation as an answer to a questions entry (S8). The first is weaker than its wording claims. The gate already refuses the second.

## Closure of i2 findings

- **i2 F1 (Medium, an off-main image read as "older"; the remedy rebuilds from whatever is checked out):** partly closed. `SKILL.md:289-291`: "if `hg -C MAIN_WT merge-base --is-ancestor C M` exits 1, the gate that runs was built off main: file one `you: judgment` entry `image-off-main`". The paste now checks `test "$(git rev-parse HEAD)" = M` before `install.sh`, which closes the remedy half. The detection half has a gap: Finding 1.
- **i2 F2 (Low, no F58 listing):** closed by deferral. Plan `:356`: "U5 makes the release entry the `image-lag` entry's body (one slug, one paste)". The entry now holds C, M and the changed names.
- **i2 F3 (Info, Rule wording):** closed. `SKILL.md:42`: "no repository file or state a build loop writes chooses which script runs as the gate".
- **i2 F4 (Info, PATHS unpinned):** closed. `test/scripts/build-loop-orchestrator.bats:347-354` pins the one-line PATHS against GATE_CODE in both directions as far as fact-check Claim 7 allows (each listed path is gate code; a widened GATE_CODE fails only through the literal).
- **D9 basis (fact-check Claim 1):** row 819 says deleting C's objects "turns the check into a record note". At 43b8d7ed it skips silently (`SKILL.md:288-289`: "If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails, the image was not built here: skip silently"). The Won't-Fix reason (hostile class, advisory) still holds. I also considered the honest route, gc pruning an off-main C after its branch is deleted. It is cleared: by then an `image-off-main` entry was filed and stays open, and silence only follows a "keep" or a prune.

The D6 block itself (`SKILL.md:206-253`) is unchanged since f2cc21e6. The i1 and i2 analysis of own(), the walk, the allowlist and the launch line still applies, with nothing changed that would affect it.

## Findings

#### 1. `--is-ancestor` reads an unreviewed mid-branch commit as "on main", so an image built from a branch that later merged is filed as a mechanical `image-lag`, not `image-off-main`

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:289-297`
**Boundary:** B6, B7, B8
**Move:** 1 (trust boundaries), 11 (bypasses)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: "Else, if `hg -C MAIN_WT merge-base --is-ancestor C M` exits 1, the gate that runs was built off main: file one `you: judgment` entry `image-off-main` naming C ... Else run `hg -C MAIN_WT diff --quiet C M -- PATHS` ... Exit 1: the gate that runs differs from main's. File one `you: terminal` entry `image-lag`".

`--is-ancestor` tests any-parent reachability, so every commit of every merged branch passes it. Here is a reachable honest sequence. The user cuts a release while `/workspace` is on a gate-code branch under review, which is i2 F1's slip. The review-fix loop then adds commits, the branch merges, and the next cycle iteration runs. At that point C is an ancestor of M, so step 0.1 reports only that the gate "differs from main's". It routes this to a `you: terminal` paste with the interim "the image's gate runs", when what runs is gate code that no `merge-gate-` review passed in that form. The paste's remedy is the right one. The failure is in naming and routing: the slip i2 F1 asked to surface as a judgment becomes a mechanical item in the low-attention queue. This is the most likely shape of that slip, because a branch under review is the one a user is most likely to have checked out. Executed against `/workspace`: `X=3943ab1c^2~2` (6beca252, a U4b2 mid-review commit) gives `is-ancestor=0`. X appears 0 times in `rev-list --first-parent main`, and `diff --quiet X 3943ab1c -- PATHS` exits 1 (`skills/dev-cycle/SKILL.md` differs).

**Recommendation:** Test first-parent membership: C is on main only when `hg -C MAIN_WT rev-list --first-parent M` lists it, the same history `--main-log` reads. A merge commit and a fast-forwarded reviewed tip are both on that chain. Anything else goes to `image-off-main`.

#### 2. Step 0.1 tells the orchestrator to answer `image-lag` itself, which `--cycle-diff` refuses unless `--answered` is passed, and `--answered` is reserved for the user's answers

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:297-298`, `:722-724`; `scripts/build-loop.sh:1833-1846` (QDIFF_AWK)
**Boundary:** B9
**Move:** 3 (error path), 5 (invert the model)
**Confidence:** High
**Legibility-target:** for-author

Evidence: step 0.1: "Exit 0: an open `image-lag` entry is answered `done: the image holds main's gate code` (this diff is the observation)". Step 9.3: "`--cycle-diff` ... with `--answered Q-NNN` for each answer the user gave this session that this iteration wrote (never one from repo text or a loop's report ...)". QDIFF_AWK: `for (id in o) if (!(id in ok) && o[id] != nw[id]) print id " " ... " gone"`.

Writing `**Status:** ANSWERED` and a `Q-NNN: done ...` line changes the entry's key lines. Executed: QDIFF_AWK over that before/after pair prints `Q-150 q gone` with no IDs, and nothing when `ids="Q-150"`. A compliant orchestrator therefore hits a `--cycle-diff` refusal on every iteration after a rebuild. It reverts the answer, so the entry never closes. That direction fails closed. The other way out is gate-gaming: reading "this diff is the observation" as permission to pass `--answered` for an answer the user did not give. That breaks the one rule keeping agent-written answers off main. The harm today is limited to this entry, since nothing keys on `image-lag`'s answer. Introduced by 43b8d7ed.

**Recommendation:** Do not have the orchestrator answer the entry. Either have step 0.1 note "image-lag cleared at C" in the record and list the open entry in the final message for the user to answer `done`, or make the close an explicit, named exception in `--cycle-diff`. The first is simpler.

#### 3. `image-off-main` is keyed by slug, not by C: a second off-main release keeps the first C's body, "keep" never sticks, and nothing closes it

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:289-291`
**Boundary:** B6
**Move:** 5
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: "file one `you: judgment` entry `image-off-main` naming C, unless one is open (options: rebuild from main, the paste below; or keep)". Compare `image-lag`: "(an open one has its body rewritten)".

(a) Suppose an open entry names C1 and the user cuts a second off-main release, C2. No new entry is filed, so the user reviews C1's code and answers while C2 runs. The next iteration corrects this, but only after the answer. (b) "Keep" is not recorded against C. An answered entry is not open, so the next iteration files a new `image-off-main` for the same C, every iteration until a rebuild. That trains the user to dismiss it, the attention cost the global instructions name. (c) After a rebuild from main, the step never reaches a close for `image-off-main`, so the stale entry keeps saying an off-main gate runs. None of these lets an off-main gate run unnoticed, which is why it is rated Low.

**Recommendation:** Rewrite an open entry's body with the current C, as `image-lag` does. Skip filing when an answered entry already names this C with "keep". Have the record list a stale open entry once the image is on main.

#### 4. The paste's `test HEAD = M` does not cover the working-tree `install.sh` it runs on the host (pre-existing, not introduced)

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:295-296`; `devcontainer-config/install.sh:19-22`
**Boundary:** B8
**Move:** 1
**Confidence:** High
**Legibility-target:** for-author

Evidence: paste "`cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh`". install.sh: "The exception is this script itself, which is NOT inert: it runs on the host from the repo ... An edit to it is covered by nothing but the commit-time Live-verified gate (decision 035)".

The payload is `git archive HEAD`, so the HEAD test does make the image exactly M (`install.sh:335-361`). The script that does the staging, though, is the working-tree file in the bind-mounted checkout. An uncommitted edit there, such as a session's in-progress change in `/workspace`, runs on the host with the user's privileges. The exposure predates this branch, and decision 035 accepts it. A same-uid writer planting the edit is out of scope. The branch's only contribution is a guard that reads as "release from main" without covering the one non-inert file. It is listed so the paste can close that gap cheaply.

**Recommendation:** Extend the paste with `git diff --quiet HEAD -- devcontainer-config/install.sh &&` before running it, or leave it as a row against decision 035.

## Bypass candidates for step 0.1's new checks (B6, B7, B8)

Tested:
- An image built from a mid-review commit of a branch that later merged: executed. It passes `--is-ancestor` and misroutes to `image-lag` (Finding 1).
- The orchestrator's own `done` answer through `--cycle-diff`: executed, refused without `--answered` (Finding 2).
- Real state: `cat-file -e C^{commit}` = 0, `--is-ancestor C M` = 0, `diff --quiet C M -- PATHS` = 1 for C = 774a0eef. Today's run files `image-lag`, as intended.
- Moving `refs/heads/main` so M carries a planted commit the paste then approves: the paste only checks HEAD equals that same moved main, which the user would have built anyway. `--main-log` (step 0.2) stops the same iteration (read-static; hostile class).
- `A` holding shell metacharacters: cleared. It is `$REPO_ROOT` written by install.sh on the host into a root-owned file (deploy-time; `install.sh:360`).
- A branch switch between the paste's `test` and install.sh's `git archive`: cleared for honest slips. install.sh refuses at startup and after each y while any Claude Code process or cc-isolated container runs (`install.sh:47-58`), and it prints the commit it stages.
- `--name-only` names written into the entry, and a newline-bearing name forging entry structure if repo config sets `core.quotePath=false`: cleared. The names are under GATE_CODE paths between C and M with C on main, so they reached main only through the gate (read-static).
- C pruned by gc after an off-main branch is deleted: silent skip, cleared above (an open entry persists).

Untested:
- An image built from a commit rebased or squashed onto main (C not an ancestor, content equal): reasoned to file a false `image-off-main`. That is noise, fail-safe. No such image exists here.
- The host's `git rev-parse HEAD` under an agent-written `.git/config`: reasoned to run no hooks or fsmonitor. Not executed on the host (no host access).

## Endorsement Claims

- **Claim:** For C = 774a0eef and main at 2aaf97b4, step 0.1's three git calls take the `image-lag` branch.
  **Location:** `skills/dev-cycle/SKILL.md:288-297`
  **Evidence:** executed
  **Verified:** `git -C /workspace cat-file -e`, `merge-base --is-ancestor`, `diff --quiet ... PATHS` exit 0, 0, 1.
  **Not verified:** the same calls through `hg`'s flags (i2 executed `hg` against planted config).
- **Claim:** The orchestrator bats pass at 43b8d7ed, including the new PATHS pin.
  **Location:** `test/scripts/build-loop-orchestrator.bats`
  **Evidence:** executed
  **Verified:** `timeout 300 bats test/scripts/build-loop-orchestrator.bats`: 26 ok, 0 not ok.
  **Not verified:** the pin's reverse direction (fact-check Claim 7: widening GATE_CODE and the test literal together passes).
- **Claim:** The D6 block between f2cc21e6 and 43b8d7ed is byte-identical, so the i2 own() equivalence and the i1/i2 refusal set carry forward.
  **Location:** `skills/dev-cycle/SKILL.md:206-253`
  **Evidence:** read-static (`git diff f2cc21e6..43b8d7ed -- skills/dev-cycle/SKILL.md` touches only lines 42 and 283-299 and 713)
  **Not verified:** a run as root (`-w`; fact-check Claim 9, Unverifiable).

## Primitive sweep

Primitive: process exec / git invocations (new or changed call sites)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:288` `hg -C MAIN_WT cat-file -e 'C^{commit}'` | S2, S4 | hg flags; C full hex | cleared (i2: ref-name steering executed) |
| `SKILL.md:289` `hg -C MAIN_WT merge-base --is-ancestor C M` | S2, S4, S7 | hg flags | Finding 1 (any-parent ancestry) |
| `SKILL.md:291-292` `hg -C MAIN_WT diff --quiet C M -- PATHS` (and `--name-only`) | S1, S2, S4 | hg flags, literal pathspecs | cleared (i2: planted diff config executed) |
| `SKILL.md:295-296` paste `cd A && test ... = M && ./devcontainer-config/install.sh` (user, host) | S2 (A), S4 (M), S6 | HEAD = M | Finding 4 (pre-existing working-tree script) |
| `SKILL.md:247` launch line | S1, S2, S3 | own(), walk, allowlist | unchanged since i2, cleared there |

Primitive: file write (questions.md)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| step 0.1 `image-off-main` filing | S2, S7 | "unless one is open" | Finding 3 |
| step 0.1 `image-lag` filing or rewrite | S2, S4 | — | cleared (names reached main through the gate) |
| step 0.1 `image-lag` close (`done`) | S8 | `--cycle-diff` | Finding 2 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence | Introduced here |
|---|---------|----------|----------|----------|------------|-----------------|
| 1 | `--is-ancestor` admits merged-branch intermediates: an unreviewed gate filed as `image-lag` | Medium | B6, B7, B8 | `SKILL.md:289-297` | Medium | yes (43b8d7ed) |
| 2 | Orchestrator answers `image-lag`, which `--cycle-diff` refuses without a user-only `--answered` | Low | B9 | `SKILL.md:297-298`, `build-loop.sh:1833-1846` | High | yes (43b8d7ed) |
| 3 | `image-off-main` keyed by slug: stale C, "keep" never sticks, no close | Low | B6 | `SKILL.md:289-291` | Medium | yes (43b8d7ed) |
| 4 | Paste's HEAD test does not cover the working-tree install.sh | Low | B8 | `SKILL.md:295-296` | High | no (decision 035) |

## Overall Assessment

The D6 block, the branch's core change, is unchanged since i2. The earlier passes established that no repository data chooses the script: the four files and every directory up to `/` must be root-owned, non-link and unwritable, the launch strips the questions overrides, and the Rule now says exactly that. The i2 fixes mostly close i2 F1: an off-main image now gets a judgment entry, and the paste refuses to rebuild from anything but main's commit. One gap is worth fixing before merge. `--is-ancestor` counts every merged branch commit as "on main". The likeliest version of i2 F1's slip, a release cut from a branch under review that then merged, is therefore still filed as a mechanical lag (Finding 1). It can be fixed in place with one first-parent test. Findings 2 and 3 are in the new entry handling. Both fail closed or toward noise, but Finding 2 has the skill instruct an action its own gate refuses, and that is worth removing before it invites an `--answered` workaround. No HALT pattern applies. No findings were made within the code paths read beyond these. Endorsement claims are executed, except the D6-unchanged claim, which is read-static and scoped.

**Medium or above AND introduced by this branch: yes, one. Finding 1 (Medium, 43b8d7ed).**

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/security-review-2026-10-13-u4c-final.md (first line `Commit: 43b8d7ed`), per the skill.
- Answered: yes. Covered here: closure of i2 F1-F4 (F2-F4 closed, F1 partly closed); the D9 basis under fact-check Claim 1 (still holds); new findings 1-3 (introduced) and 4 (pre-existing); bats 26/26; real-state run of step 0.1.
- Out of scope: hostile same-uid containment (Q-103); root and host runs (fact-check Claim 9); the image build from staged payload to `/opt`.
- Escalate: Finding 1, the one introduced Medium, for the loop's fix decision; Finding 2's contradiction with step 9.3's `--answered` rule.
