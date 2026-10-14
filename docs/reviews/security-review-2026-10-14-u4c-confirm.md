Commit: e58adc1f

# Security Review — feat/build-loop-u4c (second confirming pass, fix range)

**Scope:** `git diff 43b8d7ed..e58adc1f`: step 0.1 of `skills/dev-cycle/SKILL.md` (manifest-first, first-parent membership, `image-off-main-C12`, the Exit-0 listing, the paste's install.sh check), the lib comment, the pin test name, step 9's wording, override rows 820-821, the plan text. Context read: `devcontainer-config/install.sh` (`repo_git`, `git_state_gate`, `assemble`), step 0.2 (`--main-log`, the `other-commit-SHA12` precedent), the 43b8d7ed final reviews.
**Date:** 2026-10-14
**Based on:** `security-review-2026-10-13-u4c-final.md`, `api-consistency-review-2026-10-13-u4c-final.md`, rubric `code-review-rubric-2026-10-13-feat-build-loop-u4c.md`
**Threat model applied:** a deliberately hostile same-uid loop is out of scope for the gate's containment (Q-103). Step 0.1 is advisory. The host boundary that install.sh defends (repository `.git` state must not run a command on the host: `install.sh:193-200`, review R1) is treated as in scope, as install.sh treats it.

## Trust Boundary Map

```
B6:  [.manifest commit= (C), assembled_from= (A)]               → [step 0.1: cat-file, rev-list --first-parent membership, diff --quiet] → [which entry is filed / listed]
B7:  [MAIN_WT refs/heads/main (M), objects]                     → [the same hg calls]                                                     → [which entry is filed / listed]
B8:  [host checkout HEAD and working tree]                       → [paste: test HEAD = M]                                                  → [install.sh runs, builds the image]
B10 (new): [host checkout .git/config, .gitattributes, info/attributes] → [paste: bare `git diff --quiet HEAD -- install.sh` on the host] → [host command execution, before install.sh's git_state_gate]
B11 (moved): [WT's questions files (from main's commit)]        → [image-off-main-C12 suppression]                                        → [whether a new off-main C is filed]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S2 | `.manifest` `commit=` / `assembled_from=` (root 0444) | deploy-time | trusted as "what the image holds"; C is full 40-hex (`commit=774a0eef3ff8…`) |
| S4 | MAIN_WT refs, objects | runtime-mutable by any loop | UNTRUSTED for the advisory verdict; moving main is `--main-log`'s stop |
| S6 | host checkout HEAD and working tree | runtime-mutable by any session | UNTRUSTED as reviewed code toward the image |
| S9 | host checkout `.git/config`, `config.worktree`, `.gitattributes`, `info/attributes` (bind-mounted, sandbox-writable) | runtime-mutable by any session | UNTRUSTED toward exec sinks; install.sh refuses filter/fsmonitor/include/hook keys before any other git call for exactly this reason |
| S10 | first-parent membership of C in `rev-list --first-parent M` | derived from S2, S4 | trusted as "C landed on main through a path `--main-log` reads" (not "C passed review": see Informational 3) |
| S11 | existing `image-off-main-C12` entries in WT's questions files | WT made from main's commit | trusted for suppression: entries reach main only through the gate's questions rule |

The range newly trusts S10 (sound, aligned with `--main-log`) and S11 (keyed, same precedent as `other-commit-SHA12`). It also newly sends S9 to an exec sink on the host, through the paste's added `git diff` (Finding 1).

## Closure of the 43b8d7ed findings

- **security final F1 (Medium, `--is-ancestor` admits merged-branch commits):** closed. `SKILL.md:290-292`: "C is on main only when it is one of the lines of `hg -C MAIN_WT rev-list --first-parent M` (the history `--main-log` reads; a merged branch's own commits are not on it)". Executed against `/workspace` (main at 000a6942): the U4b2 mid-review commit 6beca252 (`3943ab1c^2~2`) is 0 lines of first-parent; the merge 3943ab1c and the image's C 774a0eef are 1 each. 6beca252 now routes to `image-off-main-*`.
- **security final F2 (Low, the orchestrator answers `image-lag`):** closed. `SKILL.md:301-303`: "list any open `image-lag` or `image-off-main-*` entry in the final message for the user to answer `done` (the orchestrator never answers one itself: D8)". Grep finds no other instruction to answer either slug, so `--cycle-diff` is no longer asked to accept an orchestrator answer and no `--answered` workaround is invited.
- **security final F3 (Low, slug-keyed) and api final F1 (Inconsistent):** closed. The slug is `image-off-main-C12`, suppressed "unless WT's questions files hold one" (the archive included, as `other-commit-SHA12` at `:322`), options numbered [1]/[2], and the on-main path lists a stale open entry for the user. A second off-main C gets its own key, so a new image is filed, not hidden behind the first. One residual is Finding 2.
- **security final F4 (Low, working-tree install.sh):** the gap is closed: an edited install.sh fails the new test. The fix, though, introduces Finding 1.

## Findings

#### 1. The paste's new `git diff --quiet HEAD -- install.sh` runs on the host before install.sh's git-state gate, so a planted `core.fsmonitor` or clean filter executes there

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:298-300`; compare `devcontainer-config/install.sh:181`, `:193-200`, `:332`
**Boundary:** B10, B8
**Move:** 1 (trust boundaries), 3 (the guard's own path), 11 (bypasses)
**Confidence:** High on the mechanism (executed); Medium on reach (needs a writer to the checkout's `.git/config` or `.gitattributes`)
**Legibility-target:** for-author

Evidence: paste "`cd A && test "$(git rev-parse HEAD)" = M && git diff --quiet HEAD -- devcontainer-config/install.sh && ./devcontainer-config/install.sh`". install.sh: "`git archive` runs a `filter.<x>.smudge` that an attributes file assigns, and `git status` runs `core.fsmonitor` and clean" (`:195-196`); "`git_state_gate   # before any other git call on the checkout (review R1)`" (`:332`); `repo_git` runs git with "`-c core.hooksPath=/dev/null -c core.fsmonitor=false`" (`:181`).

install.sh's defense is that no git call on the checkout runs before `git_state_gate` refuses filter, fsmonitor, include and hook keys. The paste now runs a bare `git diff` first, unhardened and in the user's host shell. A working-tree diff refreshes the index, which invokes `core.fsmonitor`, and it hashes a stat-dirty file through its clean filter. Executed hermetically (git 2.39.5, scratch repo): with `core.fsmonitor` set to a marker script, `git rev-parse HEAD` touched nothing, and `git diff --quiet HEAD -- devcontainer-config/install.sh` ran it (marker created, rc 0). With `filter.x.clean` in config, `install.sh filter=x` in `devcontainer-config/.gitattributes` and the file's mtime changed, the clean filter ran too. The `/workspace` `.git/config` and working tree are writable from every sandbox session, so a session that writes either key gets a command run on the host with the user's privileges the next time the user pastes. Before this range, install.sh would have refused that same state ("Nothing was installed"). The `test HEAD = M` step does not help: an attacker who only writes config leaves HEAD alone. This is introduced by e58adc1f. A deliberately hostile loop is Q-103's class, but install.sh treats this exact host route as in scope, and the paste routes around it. Honest writers exist too (`git lfs install --local` sets `filter.lfs.*`), but those run benign programs.

**Recommendation:** Compare without running git's working-tree machinery: `test "$(git rev-parse HEAD:devcontainer-config/install.sh)" = "$(git hash-object --no-filters devcontainer-config/install.sh)"`. Executed in the same planted repo: no marker, exit 0 when equal and 1 after an edit. Alternatively, move the check into install.sh after `git_state_gate`, through `repo_git`.

#### 2. An answered `image-off-main-C12` silences the same C for good, including after a [1] "rebuild" answer that was not carried out

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:292-296`, `:301-303`
**Boundary:** B11, B6
**Move:** 5 (invert the model)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: "file one `you: judgment` entry `image-off-main-C12` (C's first 12 hex), unless WT's questions files hold one: [1] rebuild from main (check main out on the host, then the paste below), [2] keep this image." The Exit-0 listing is reached only on the on-main path.

Suppression holds for any entry with the key, answered or not, and nothing distinguishes a [1] from a [2]. If the user answers [1] but the rebuild does not happen (the paste fails, or is forgotten), the image keeps running C, step 0.1 files nothing, and the not-on-main path lists nothing. The off-main gate then runs with no further signal. That is the state i2 F1 asked to surface. It cannot hide a *different* off-main image (a new C is a new key; a 48-bit prefix collision is the hostile class), so it is Low. Introduced by e58adc1f.

**Recommendation:** Suppress only on a `keep` ([2]) answer or an open entry. After an answered [1] with the same C, re-file it or list it in the final message.

## Informational

3. **Fast-forwarded main.** If a branch is fast-forwarded into main, its mid-review commits join first-parent history, and an image built from one reads as "on main" (security final F1's shape). Read-static: each such commit is a first-parent non-merge that `--main-log` classifies, and anything not `gate`, `chore` or `answers` is step 0.2's `other` stop with an `other-commit-SHA12` entry. The residual is the same as `--main-log`'s, which the range's wording names ("the history `--main-log` reads").
4. **False positives, fail-safe.** A release from a reviewed branch tip after its merge (1da331ce, the second parent of 3943ab1c: 0 first-parent lines, executed), a rebased or rewritten main, a shallow history, or a non-canonical C (abbreviated or upper-case; the manifest writes 40 lower-case hex) all file `image-off-main-*` for the user to [2] keep. That is noise, keyed once per C. `/workspace` is not shallow (executed).
5. **Ordering, carried from the precedent.** "WT's questions files" are named at step 0.1, before step 0.3 makes WT. Step 0.2's `other-commit` wording has the same shape and resolves it by filing after 0.3. Read as the same.

## Bypass candidates for the range's checks

Tested:
- Mid-review commit of a merged branch as C: executed, 0 first-parent lines, routes to `image-off-main` (F1 closed).
- Reviewed branch tip as C, after its merge: executed, off main, so noise (Informational 4).
- The new paste check under planted `core.fsmonitor` and a clean filter: executed, both run (Finding 1). `rev-parse HEAD` alone runs neither (executed).
- The `hash-object --no-filters` alternative under the same planted state: executed, runs neither and detects an edit.
- Empty or missing `commit=`: "with no file or either line, note it in the record and skip", and `cat-file -e '^{commit}'` fails anyway (read-static). An empty C cannot whole-line-match the hex lines (executed: `grep -cx ''` over first-parent = 0).
- A second off-main C while the first's entry is open: different key, so filed (read-static).

Untested:
- A pre-filed `image-off-main-<C12>` entry from a loop's merged branch suppressing the real one: it would itself be an open judgment entry the user sees. The gate's questions rule refuses one filed answered. Hostile class (Q-103), not executed.
- `diff.external` under `git diff --quiet` on the host's git version: not executed (host git version unknown). Finding 1 does not depend on it.

## Endorsement Claims

- **Claim:** For main at 000a6942, the first-parent test lists C=774a0eef and 3943ab1c and omits 6beca252 and 1da331ce.
  **Location:** `skills/dev-cycle/SKILL.md:290-292`
  **Evidence:** executed
  **Verified:** `git rev-list --first-parent main | grep -cx <sha>` gave 1, 1, 0, 0.
  **Not verified:** the same call through `hg`'s flags, and with C read by the orchestrator rather than `sed`.
- **Claim:** The orchestrator bats pass at e58adc1f.
  **Location:** `test/scripts/build-loop-orchestrator.bats`
  **Evidence:** executed
  **Verified:** `timeout 300 bats test/scripts/build-loop-orchestrator.bats`: 26 ok.
  **Not verified:** step 0.1's prose has no test beyond the PATHS pin.
- **Claim:** The range's SKILL.md changes are confined to step 0.1 and one step 9.1 phrase; the D6 block is untouched.
  **Location:** `skills/dev-cycle/SKILL.md:286-303`, `:718`
  **Evidence:** read-static (`git diff 43b8d7ed..e58adc1f -- skills`)
  **Not verified:** a root run of the block (as before).

## Primitive sweep

Primitive: process exec / git invocations changed in the range
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:289` `hg -C MAIN_WT cat-file -e 'C^{commit}'` | S2, S4 | hg flags | cleared (unchanged call; now after the manifest check) |
| `SKILL.md:291` `hg -C MAIN_WT rev-list --first-parent M` | S2, S4 | hg flags; whole-line match | cleared (executed) |
| `SKILL.md:296` `hg -C MAIN_WT diff --quiet C M -- PATHS` | S1, S2, S4 | hg flags, literal pathspecs | unchanged, cleared at 43b8d7ed |
| `SKILL.md:298` paste `git rev-parse HEAD` (host, bare git) | S6, S9 | none needed | cleared (executed: no fsmonitor) |
| `SKILL.md:299` paste `git diff --quiet HEAD -- devcontainer-config/install.sh` (host, bare git) | S6, S9 | none | **Finding 1** |
| `SKILL.md:299` paste `./devcontainer-config/install.sh` | S6 | `git_state_gate`, now preceded by the diff | cleared (now covered by the HEAD diff) |

Primitive: file write (questions.md)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| step 0.1 `image-off-main-C12` filing | S2, S10, S11 | keyed suppression | Finding 2 |
| step 0.1 `image-lag` filing or rewrite | S2, S4 | — | unchanged, cleared |
| step 0.1 Exit-0 listing (no write) | S11 | — | cleared (no orchestrator answer) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence | Introduced by this range |
|---|---------|----------|----------|----------|------------|--------------------------|
| 1 | Paste's bare `git diff` runs fsmonitor/clean filters on the host before install.sh's git-state gate | Medium | B10, B8 | `SKILL.md:298-300` | High (mechanism, executed) | yes (e58adc1f) |
| 2 | Answered `image-off-main-C12` silences the same C after an unexecuted [1] | Low | B11, B6 | `SKILL.md:292-296` | Medium | yes (e58adc1f) |

## Overall Assessment

The fixes do what the 43b8d7ed reviews asked. First-parent membership closes final F1 (executed against the real U4b2 history), and its residual is the same as `--main-log`'s. The Exit-0 listing closes F2, keying closes F3 and api F1, and the paste now refuses an edited install.sh (F4). The keyed suppression cannot hide a later image with a different C. One regression came in with the F4 fix. The paste's new working-tree `git diff` is the first git call on the host checkout, and it runs before install.sh's `git_state_gate`. So it executes a `core.fsmonitor` or clean filter that install.sh exists to refuse (executed hermetically). The fix is in place and one line: compare `HEAD:` with `hash-object --no-filters`. No HALT pattern applies. Apart from these two findings, nothing was found in the code paths read. Endorsement claims are executed, except the scoped read-static diff-confinement claim.

**Medium or above AND introduced by this range: yes, one. Finding 1 (Medium, e58adc1f).**

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/security-review-2026-10-14-u4c-confirm.md (first line `Commit: e58adc1f`).
- Answered: yes. Covered: closure of security final F1-F4 and api final F1 (all closed; F4's fix introduces Finding 1); first-parent bypasses and false positives (fast-forward, reviewed tip, rewritten, shallow, non-canonical C); keyed suppression (no hiding of a new C; the Finding 2 residual); what the range newly trusts (S10, S11, and S9 toward a host exec sink); bats 26/26.
- Out of scope: hostile same-uid containment (Q-103) beyond install.sh's own host boundary; host runs (no host access: the experiments used a scratch repo); the image build itself.
- Escalate: Finding 1, the one introduced Medium, for the merge decision (U4c's rule: a new Medium blocks).
