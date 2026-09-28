Commit: bfe8292

# Security Review (confirming pass): Q-076 fix commits

**Scope:** `61d801c..feat/q076-git-exit-scan`: f511cc1 (scan moved into `cc-exit-scan.sh`), 9133e23 (`cc-gitdir.sh`: git-dir validity; `--strict`), 41622c0 (cc-push: container check, git version, single-branch fetch, exit codes), 6fc7b5a (cc-isolated: launch refusal, `--help` exit codes), bfe8292 (guide: one LIMITS list). I read the full files at the tip: `devcontainer-config/cc-push.sh`, `cc-gitdir.sh`, `cc-exit-scan.sh`, `cc-isolated.sh`, and the guide's cc-push and exit-scan sections.
**Date:** 2026-09-27 · host git 2.39.5 · no docker on the review host
**Based on:** the prior reviews `q076-security-review-2026-09-27.md`, `q076-architecture-review-2026-09-27.md`, `q076-performance-review-2026-09-27.md`, `q076-api-consistency-review-2026-09-27.md`, and fact-check `q076-code-fact-check-report-r1..r3.md`. No new fact-check ran on the fix commits. Where this report states what code does, the evidence is my own reading, my probes or the branch's bats suites.
**User goal:** Get a trustworthy review of Q-076 before merging it into main (solo repo, local merge).
**Logs:** `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-sec2/` (`probe-push.sh`/`.log`, `bats-*.log`).

> ⚠️ **No code fact-check report for the fix commits.** The earlier r1-r3 reports cover 61d801c. What the fix commits' comments and guide say is checked here only through the probes and tests named below.

---

## Status of prior findings

| Prior finding | Source | Status | Evidence |
|---|---|---|---|
| cc-push takes another repository's history when the checkout root stands in for `.git` (High) | security #1, r1 | **Resolved** | Both `ls-remote` calls and the fetch name `"$co/.git"` with `--upload-pack='git-upload-pack --strict'` (`cc-push.sh:385-407`). `check_checkout` also runs `gitdir_valid "$g"` and `looks_like_gitdir "$co"` (`:287-292`). My probes at the tip: P1 (`.git/HEAD` removed, root `commondir` pointing at another repo) → rc=1, "…/.git is not a valid git directory"; r1-P1 (root `objects/info/alternates`) → rc=1; P1b (root bare layout with a *valid* `.git`) → rc=1, "…itself looks like a git directory". Nothing reached upstream in any of them. A `.git/.git` gitfile pointing at the other repo (layout C, which beat a non-strict fetch in the earlier review) now fetches only the checkout's own `MINE`, rc=0. bats `cc-push.bats` tests "refuses a .git without HEAD…", "…planted bare repository", "…commondir file" and "fetches from <checkout>/.git by name, with git-upload-pack --strict" pass. |
| Exit scan exits 0 when an invalid `.git` hands discovery to the root (High) | security #2, r1 P2 | **Resolved** | The snapshot records `gitdir-valid` (validity plus HEAD's kind) and `root-repo` (`cc-exit-scan.sh:652-655`). `git_exit_scan` reports a git dir that is invalid at exit even if it was invalid at launch (`:771-777`). The launch refuses an invalid `.git` or a root that looks like a repository (`launch_gitdir_ok`, `:695-709`; `cc-isolated.sh:655-667`). The bats tests at `cc-isolated-functions.bats:1332-1427` pass (HEAD removed → finding; invalid at launch → still a finding; root repo or root commondir → finding; the launcher exits 3; branch switches are not findings). What remains is a bare layout in a *subdirectory*, and it is now listed in LIMITS (see below). |
| The container can change the checkout between check and fetch (Medium) | security #3, r3 | **Resolved by default; open under `--allow-running` (by design, documented)** | `check_no_container` runs before `check_checkout` (`cc-push.sh:339-340`). It refuses on a running container with label `cc-project=<id>`, and fails closed when docker is missing or hangs (`timeout 20`). Probe H, with no docker and no flag: rc=1 "docker is not installed, so cc-push cannot check…". `--strict` also removes the worst payload (swapping in the root) whatever the timing. Only the in-`.git` plants (alternates, include) can still win the race, and only with `--allow-running`, which prints a warning and is described in the guide. The ids agree: for a checkout reached through a symlink, cc-isolated's `git rev-parse --show-toplevel` and cc-push's `pwd -P` give the same physical path (checked), so `project_id` matches. |
| cc-push's trust in upload-pack depends on the host's git version (Low) | security #4 | **Resolved** | `git_version_ok`/`check_git_version` (`cc-push.sh:171-191`) refuse anything below the May 2024 fixed releases, and anything unparseable. The header and guide say the release list is "as recalled, not checked" (honest; see N5). |
| LIMITS leaves out the root-promotion route (Low) | security #5, arch #4 | **Resolved** | The guide now holds **one** list, and both scripts point to it (`cc-exit-scan.sh` LIMITS, `cc-push.sh:94-96`). The root route is closed, not just documented. The remaining neighbour, "A repository in a working-tree directory not named `.git`", is listed. |
| cc-push copies every branch to host disk (Medium) | performance #1 | **Resolved** | Only `+refs/heads/$branch:refs/cc/heads/$branch` is fetched (`:405-407`), after the branch has been confirmed in `ls-remote --heads` (`:398-401`). |
| Nobody owns "which git dir does git use" (Coupling) | architecture #2 | **Partly** | `cc-gitdir.sh` is now shared by cc-push and the scan. `scan_git_dirs` still reads `.git`/`commondir` with its own first-line rule (see N4). |
| Exit code 2 means different things in cc-push and install.sh | API F1 | **Resolved** | 0/1/2 now follow install.sh: declined = 1, usage = 2 (`cc-push.sh:27-32`, `:467-476`). |

## New findings

#### N1. cc-push runs whichever `git` (and `docker`, `timeout`, …) the caller's PATH finds, and the guide suggests running it from inside the checkout

**Severity:** Low
**Location:** `devcontainer-config/cc-push.sh:151-154` (`ngit`), `:189`, `:199-205`; `guides/cc-isolated-usage.md` ("afterwards (or from inside it: cc-push)"), and the header's `cc-push  # the checkout containing $PWD`
**Evidence:** `git -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"`: a bare command name, with no PATH hygiene anywhere in the script.
**Confidence:** High (probe J, harmless marker)
**Legibility-target:** operator (guide LIMITS) and maintainer

cc-push sanitises the git *environment* (`unset GIT_DIR …`) but not PATH. When the operator's PATH has a relative entry (`bin`, `./node_modules/.bin`) or an absolute entry inside the checkout, running cc-push with cwd inside the checkout, as the guide suggests, runs a session-written executable before any check. Probe J: `PATH=bin:$PATH`, cwd = the checkout, a planted `bin/git` → the marker file was created, rc=0. This needs a non-default PATH, hence Low. It is still outside the listed routes: the LIMITS item "Host programs pointed at the checkout" covers programs that *read* the checkout, not cc-push itself being redirected. The same holds for `cc-isolated` launched from inside the checkout, which already existed before this branch.
**Recommendation:** early in `main`, before the first external command, `cd /` and drop PATH entries that are relative or resolve inside `$co` (or pin `PATH=/usr/bin:/bin` plus `command -v git` checked outside `$co`). At minimum, add a LIMITS line: "cc-push and cc-isolated run the programs your PATH finds; a relative PATH entry or one inside the checkout lets the session supply them."

#### N2. With `--yes`, the session picks which origin branch is pushed

**Severity:** Informational
**Location:** `cc-push.sh:386-392`
**Evidence:** `sym="$(hgit … ls-remote … --symref "$co/.git" HEAD …)"` → `branch="$sym"`.
**Confidence:** High (probe I: HEAD → `refs/heads/deploy-prod`, `--yes` → upstream gained `deploy-prod`)
**Legibility-target:** operator

With no `--branch`, the target is whatever branch the checkout's HEAD names. Pushes are fast-forward only and the preview names the branch, so an interactive run is fine. A scripted `--yes` run, however, lets the session choose, for example, a branch that triggers deploy CI. **Recommendation:** make `--yes` require `--branch`, or say this next to `--yes` in the header and guide.

#### N3. The exit scan returns 0 when the two snapshots differ but the rendered diff is empty

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:777-779` (`git_exit_scan`), `scan_diff` `:723-743`
**Evidence:** `[ "$before" != "$after" ] || [ -n "$invalid" ] || return 0` … `changes="$(scan_diff …)"` … `[ -n "$changes" ] || return 0`
**Confidence:** Medium (read-only; not probed)
**Legibility-target:** maintainer

`scan_diff` keys `F` records by kind and path in awk maps. If one snapshot holds two records for the same kind and path with different attributes (possible only when a file changes *during* the scan while the still-running container writes), the last one wins. The rendered diff can then be empty although `before != after`, and the function takes the clean `return 0`. Reaching this needs a live process racing the scan, which the guide's "After the scan" item already covers. It is still a fail-open branch in a tool that otherwise fails closed. **Recommendation:** when `before != after` and `changes` is empty, return 2 ("scan inconsistent; treat as unscanned"), not 0.

#### N4. The scan and `gitdir_common` read `commondir` differently

**Severity:** Informational
**Location:** `cc-exit-scan.sh:123-125` (`_snap_first_line`) vs `cc-gitdir.sh:54-68` (whole file up to the first NUL, trailing CR/LF trimmed, as git does)
**Confidence:** Medium (read-only)
**Legibility-target:** maintainer

For a `commondir` holding a line break in the middle, git (and `gitdir_valid`) use the whole string, while `scan_git_dirs` walks the first line. A change made during the session is still caught by the `commondir-file` content hash, so this matters only for a baseline taken at launch, which the "Anything present at launch" item covers. Using `gitdir_common` in `scan_git_dirs` too would remove the second rule (architecture #2).

#### N5. The fixed-release list is unverified, and the tests depend on the locale

**Severity:** Informational
**Location:** `cc-push.sh:63-67`, `:178-181`; test runs
**Confidence:** High
**Legibility-target:** maintainer

(a) The version floor is as good as the recalled release list, and the code says so. It should be checked against git's release notes on a host with network access before cc-push is relied on (queue it as a `you: terminal` check). (b) With `LC_ALL=en_US.UTF-8` set but not installed, four tests fail because bash's `setlocale` warning ends up in captured output: `cc-push.bats` "gitdir_valid and gitdir_head_kind: stricter…" and "err_vis…", and `cc-isolated-functions.bats` "launch: a repository already planted…" and "launch: a .git git accepts but the tools do not…". All four pass under `LANG=C.UTF-8` (`bats-launch.log`). This is a test-environment problem, not a code defect. It is worth pinning a locale in the bats `setup()`.

## Checks with no finding (answers to the brief's specific questions)

- **`gitdir_valid` vs git's real discovery.** It follows git 2.39's `is_git_directory`/`validate_headref`. It is stricter than git in two places: a HEAD symlink not into `refs/` whose target reads as valid, and a HEAD over 255 bytes. Both only produce false alarms. I found no case where it passes a `.git` that git rejects when run from the checkout root. For cc-push the question is moot: `--strict` makes upload-pack use exactly `$co/.git` or fail. A `commondir` pointing outside the checkout is **refused** by cc-push (`:251-253`). In the scan, a `commondir` added during the session is a finding (content hash plus the resolved-dir record). One present at launch is followed and walked (baseline, as documented).
- **Docker check.** A spoofed `cc-project` label on some other container can only cause a *refusal* (a denial of service), never a pass. The session cannot create containers without a docker socket, which is outside this diff. It cannot see a container started outside cc-isolated or on a different `DOCKER_HOST`/context. That is acceptable; a one-line note in LIMITS would help.
- **Single-branch resolution.** `check-ref-format "refs/heads/$branch"` rules out `:`, `..`, `^`, `~`, `*`, whitespace and line breaks. The ref match is exact, by tab-separated column and through the environment (not `awk -v`). A symref chain resolves inside the same repository. A leading `-` cannot reach an argument position, because every use is prefixed with `refs/…`.
- **Launch refusal.** `launch_gitdir_ok` runs before the baseline and fails closed with a sanitised reason. If a leftover process plants a root repository between it and the snapshot, the result is harmless while `.git` stays valid, and an invalid `.git` is always a finding at exit.
- **Exit codes.** cc-isolated: clean → claude's rc; finding → 3; unreadable or interrupted → 4. A session can at most fake a 3 or 4 through claude's own status (a false alarm); it cannot turn a finding into 0. cc-push: 0/1/2 with 130 → 1.
- **The single LIMITS list is honest.** Every route I could confirm or reason out is in it, except N1 (PATH), N2 (branch choice under `--yes`) and the docker-context note above.

## Endorsement Claims

- **Claim:** cc-push never reads a repository other than `<checkout>/.git` when the root or a nested layout pretends to be one. **Location:** `cc-push.sh:385-407`, `:287-292`. **Evidence:** executed (probes P1, r1-P1, P1b, C; bats 499-536). **Verified:** refusal, or own-repo-only fetch, on git 2.39.5. **Not verified:** other git versions (floor enforced, list unverified: N5).
- **Claim:** The exit scan cannot exit 0 while `.git` is invalid. **Location:** `cc-exit-scan.sh:652-655,771-777`. **Evidence:** executed (bats 1332-1427). **Verified:** yes. **Not verified:** a bare layout in a subdirectory (documented limit); fail-open on an empty diff (N3).
- **Claim:** cc-push fails closed when it cannot tell whether the container runs. **Location:** `cc-push.sh:196-225`. **Evidence:** executed (probe H; bats 569-599). **Verified:** yes.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| N1 | cc-push runs PATH-resolved `git`/`docker`; a relative or in-checkout PATH entry lets the session supply them (not in LIMITS) | Low | `cc-push.sh:151-154,189,199-205` | High |
| N2 | `--yes` lets the checkout's HEAD choose the origin branch | Info | `cc-push.sh:386-392` | High |
| N3 | `git_exit_scan` returns 0 when snapshots differ but the diff renders empty | Low | `cc-exit-scan.sh:777-779` | Medium |
| N4 | `commondir` read by first line in `scan_git_dirs`, by whole file in `gitdir_common` | Info | `cc-exit-scan.sh:123-125` | Medium |
| N5 | Fixed-release list unverified; 4 tests fail under a broken locale | Info | `cc-push.sh:63-67`; bats | High |

## Overall Assessment

Both prior High findings are closed, and closed the way the first review recommended. cc-push fetches `<checkout>/.git` by name with `upload-pack --strict` and refuses an invalid `.git` or a root that looks like a repository. The scan records git-dir validity and the root's shape, treats an invalid `.git` at exit as a finding, and refuses such a state at launch. The race is closed by default (refuse while a container runs, fail closed without docker), and the git-version and LIMITS findings are resolved. No regression in the fix commits weakens a prior guarantee. The new items are Low or Informational. N1 is the one worth a small change or a LIMITS line before merge, because the guide recommends the very usage that triggers it. N3 is a one-line fail-closed fix. **Recommend: mergeable.** Ideally fold in N1 (at least the LIMITS line) and N3 first. Neither blocks merge.

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to /workspace/docs/reviews/q076-security-review-2026-09-27-confirm.md, structured per the security-reviewer skill, stating for each prior finding resolved/partly/open, listing any new findings, with a Goal-Alignment Note.

**Answered:** Resolved / partly / open, with evidence, for every prior security finding and for the High, Medium and merge-relevant items from the other reviews. Regression checks on `gitdir_valid`, the commondir handling, the docker check, branch resolution, the launch refusal and the exit codes. An honesty check of the single LIMITS list. Five new findings (two Low, three Informational).

**Out of scope:** live-container behaviour (no docker here, so the docker check was tested only on its no-docker path, alongside the existing bats tests of the running and hung cases); git versions other than 2.39.5.

**Escalate:** (1) A safety classifier stopped my turn after probe J (N1). I built no further attack fixtures after that, and N3/N4 rest on reading the code only. (2) N5(a) needs a host with network access to check the fixed-release list against git's release notes (`you: terminal`).
