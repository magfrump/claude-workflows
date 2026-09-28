# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q086 (branch `review/q086`)
**Scope:** `git diff 1ef3090..577bef7` only: the 3 added Dockerfile header lines (read as the whole header block, `devcontainer-config/Dockerfile:1-9`), the commit message of 577bef7, and the 7 new `review/q086` rows in `docs/reviews/override-log.md`. Commit 1ef3090 is context only.
**Commit:** 577bef7
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-09-28
**Total claims checked:** 16
**Summary:** 10 verified, 2 mostly accurate, 1 stale, 0 incorrect, 3 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) first. No claim below matches a logged pattern.

Sandbox caveat: no network egress, no Docker, `parallel` is not installed, and `apt-cache show parallel` returns nothing because the package index is empty. Anything that needs a package index or a built image is marked Unverifiable.

Line-numbering note: 577bef7 added 3 lines to the header. The base apt `RUN` moved from `:19-43` (at 1ef3090) to `:22-46` (at 577bef7), and `parallel \` moved from `:40` to `:43`. The override-log rows were written in 577bef7, so I checked their Dockerfile line citations against the 577bef7 tree.

---

## Claim 1: "`bats --jobs N` with N>1 needs it to run test files concurrently"

**Location:** `devcontainer-config/Dockerfile:4-5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bats 1.8.2 (the sandbox's `1.8.2-1`, the bookworm package): parallel is required only for across-file parallelism when N>1. It does not establish behaviour in other bats versions, or that the image's bats is the same version (assumed, same bookworm base).
**Legibility-target:** for-orchestrator-synthesis

The suite runner aborts only when N≠1, parallel is missing and across-file parallelism is on:

```bash
# /usr/libexec/bats-core/bats-exec-suite:99-104
if [[ "$num_jobs" != 1 ]]; then
  if ! type -p parallel >/dev/null && [[ -z "$bats_no_parallelize_across_files" ]]; then
    abort "Cannot execute \"${num_jobs}\" jobs without GNU parallel"
```
(excerpt ends :101; the enclosing `if` continues to :105 — read. It sources `semaphore.bash`, not parallel.)

The only place parallel is invoked is the across-files branch:

```bash
# /usr/libexec/bats-core/bats-exec-suite:415,420
if [[ "$num_jobs" -gt 1 ]] && [[ -z "$bats_no_parallelize_across_files" ]]; then
  parallel --keep-order --jobs "$num_jobs" bats-exec-file ... ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1
```
(excerpt is elided at `...` for width. The `else` branch at :421-428 is a serial `for` loop — read.)

Within-file parallelism (`bats-exec-file:294-296`, `bats_run_tests_in_parallel`) runs on bats' own semaphore and does not need parallel. So the qualifier "to run test files concurrently" is exact.

I re-ran the probe with two test files and no parallel on PATH. `--jobs 2` gave `Error: Cannot execute "2" jobs without GNU parallel` and exit 1. `--jobs 1` gave 3/3 ok and exit 0. `--jobs 2 --no-parallelize-across-files` gave 3/3 ok and exit 0.

Command: `bash -c '<probe>'`, run in a mktemp dir (`/tmp/tmp.9pq5aZaebM`). The overall exit code was 0; each per-case exit code is in the log. Timestamp: 2026-09-28T21:40:11Z.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-105`, `/usr/libexec/bats-core/bats-exec-suite:415-428`, `/usr/libexec/bats-core/bats-exec-file:294-296`, docs/reviews/execution-logs/q086-bats-jobs-probe-iter2.log

---

## Claim 2: "bats' Debian package only Recommends it"

**Location:** `devcontainer-config/Dockerfile:5`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the installed `bats 1.8.2-1` control data in the sandbox. It does not establish the control data of whatever bats version the image build resolves (assumed to be the same bookworm package).
**Legibility-target:** for-orchestrator-synthesis

`dpkg -s bats | grep -E 'Version|Depends|Recommends'` (cwd `/workspace/.claude/wt-q086`, exit 0, 2026-09-28T21:3xZ) printed:

```
Version: 1.8.2-1
Recommends: parallel
```

There is no `Depends:` line, so parallel is only a Recommends. The output is quoted inline in full (two lines) and was not captured to a separate file.

**Evidence:** `dpkg -s bats` output quoted above

---

## Claim 3: "the install below uses --no-install-recommends"

**Location:** `devcontainer-config/Dockerfile:6`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the base apt `RUN` that installs `bats` and `parallel`. It does not establish whether any later `RUN` could pull in Recommends (the two other apt `RUN`s, at the 1ef3090 tree's :195 and :220, also carry the flag).
**Legibility-target:** for-orchestrator-synthesis

The base install sits below the header and carries the flag:

```dockerfile
# devcontainer-config/Dockerfile:22,42-46
RUN apt-get update && apt-get install -y --no-install-recommends \
  bats \
  parallel \
  ripgrep \
  shellcheck \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
```
(excerpt skips :23-41, the other package names — read.)

**Evidence:** `devcontainer-config/Dockerfile:22-46`

---

## Claim 4: "A1: the Dockerfile header's "Local changes" list now names parallel and why: ..."

**Location:** commit 577bef7 message, paragraph 1
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the match between the commit paragraph and the diff's header text. It does not re-verify the technical content, which Claims 1-3 cover.
**Legibility-target:** for-orchestrator-synthesis

The commit says the header records that "`bats --jobs N` with N>1 needs it ... bats' Debian package only Recommends it while the base install uses --no-install-recommends". The header at `devcontainer-config/Dockerfile:4-6` says the same, quoted under Claims 1-3. The diff touches only those 3 lines of the Dockerfile (`git diff --stat`: `devcontainer-config/Dockerfile | 3 +`).

**Evidence:** `devcontainer-config/Dockerfile:4-6`, `git diff --stat 1ef3090..577bef7`

---

## Claim 5: "A2: ... only --jobs N>1 across files needs it; --jobs 1 and --no-parallelize-across-files run without it. The reviewed commit is not rewritten"

**Location:** commit 577bef7 message, paragraph 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bats 1.8.2 behaviour without parallel and the fact that 1ef3090 is unchanged. It does not establish behaviour with `--no-parallelize-within-files` alone (which, per `bats-exec-suite:99-101`, still needs parallel when N>1).
**Legibility-target:** for-orchestrator-synthesis

This is the same probe and code as Claim 1: all three cases in `q086-bats-jobs-probe-iter2.log` match the stated behaviour. `git log main..HEAD` still lists `1ef3090 build(image): add GNU parallel so bats --jobs can run (Q-086)` as the parent of 577bef7, so the commit was not rewritten.

**Evidence:** docs/reviews/execution-logs/q086-bats-jobs-probe-iter2.log, `/usr/libexec/bats-core/bats-exec-suite:99-105`

---

## Claim 6: "Adds the iteration-1 review artifacts (q086-prefixed) and seven override-log rows for the declined findings (A2, C1-C6)"

**Location:** commit 577bef7 message, paragraph 3
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file list and row count in the diff. It does not establish that A2 and C1-C6 are the complete set of declined iteration-1 findings (I did not re-read the iteration-1 rubric).
**Legibility-target:** for-orchestrator-synthesis

`git diff --stat 1ef3090..577bef7` shows five `docs/reviews/q086-*.md` files, `execution-logs/q086-bats-jobs-probe.log`, and `docs/reviews/override-log.md | 7 +`. The 7 added rows are labelled A2, C1, C2, C3, C4, C5 and C6, all with PR ref `review/q086`. (Paraphrased — no quote available because the claim is a count of rows and files; the row texts are quoted under Claims 9-14.)

**Evidence:** `docs/reviews/override-log.md:80-86`, `git diff --stat 1ef3090..577bef7`

---

## Claim 7a: "Live-verified: no — comment-only change to the Dockerfile header; the image build is unchanged apart from the layer text"

**Location:** commit 577bef7 message, `Live-verified:` trailer
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the "comment-only" part, which the diff confirms, and the effect on the build. It does not establish Docker cache behaviour empirically: Docker was not run.
**Legibility-target:** for-author

"Comment-only" is right: all three added lines start with `#` (`devcontainer-config/Dockerfile:4-6`, quoted under Claim 1).

"Apart from the layer text" is imprecise. Docker's Dockerfile parser discards `#` comment lines, so they belong to no instruction. No layer's text or cache key changes, and the build is fully unchanged, not "unchanged apart from" anything. (Paraphrased — no quote available because this is documented Docker parser behaviour, not code in this repo; not executed, since the sandbox has no Docker.)

A precise version: "comment-only change; Dockerfile comments do not enter any layer or cache key, so the built image is unchanged." The error is conservative, not misleading.

**Evidence:** `devcontainer-config/Dockerfile:4-6`

---

## Claim 7b: "verified at the Q-086 host rebuild (`parallel --version` inside cc-isolated)"

**Location:** commit 577bef7 message, `Live-verified:` trailer
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the claim's form. It does not establish that the host rebuild happened or that `parallel --version` succeeded in the image.
**Legibility-target:** for-orchestrator-synthesis

This refers to a host-side image rebuild. The sandbox has no Docker and no host access, and `parallel` is absent here (`command -v parallel` printed nothing). The wording reads as either past or deferred. The C1 and C3 rows treat the rebuild as future ("Revisit at the Q-086 host step"), which suggests it has not happened yet. Verifying it needs `parallel --version` run inside a rebuilt cc-isolated container on the host.

**Evidence:** `docs/reviews/override-log.md:81`, `docs/reviews/override-log.md:83`

---

## Claim 8: A2 row — "commit 1ef3090 message says "bats --jobs needs GNU parallel"; precisely, only `--jobs N>1` across files needs it (`--jobs 1` and `--no-parallelize-across-files` run without it)"

**Location:** `docs/reviews/override-log.md:80`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quoted 1ef3090 wording and the bats behaviour. The Reason's claim "the precise wording is now in the Dockerfile header comment and the fix commit body" is covered by Claims 1 and 5. It does not establish the Reason's rationale about sha stability (design rationale, not checkable).
**Legibility-target:** for-orchestrator-synthesis

The 1ef3090 subject is `build(image): add GNU parallel so bats --jobs can run (Q-086)`. I did not re-read its body here: iteration 1 quoted it, and it is context-only for this pass. The behavioural part matches the executed probe (Claim 1).

**Evidence:** docs/reviews/execution-logs/q086-bats-jobs-probe-iter2.log, `/usr/libexec/bats-core/bats-exec-suite:99-105`

---

## Claim 9: C1 row — "user's 20210822 = Ubuntu 22.04; bookworm ships 20221122"

**Location:** `docs/reviews/override-log.md:81`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Scope:** Covers only the sandbox's inability to resolve the version. It does not establish either version number.
**Legibility-target:** for-orchestrator-synthesis

`timeout 5 apt-cache show parallel` (cwd the worktree, exit 0, 2026-09-28T21:3xZ) printed no `Version:` line, because the package index is empty. `apt-cache depends parallel` printed only `<parallel>`. The output is quoted inline in full. The row labels this finding unverifiable-offline and defers it to the host step, which is consistent with what the sandbox shows. Verifying it needs a bookworm package index or `parallel --version` in the built image.

**Evidence:** `apt-cache show parallel` / `apt-cache depends parallel` output quoted above

---

## Claim 10: C2 row — "`bats-exec-suite:420` runs `parallel ... 2>&1`, no `--will-cite`"

**Location:** `docs/reviews/override-log.md:82`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the location, the `2>&1` and the absence of `--will-cite` on that command line. It does not establish whether parallel actually prints a citation notice in a non-interactive run (needs parallel installed).
**Legibility-target:** for-orchestrator-synthesis

```bash
# /usr/libexec/bats-core/bats-exec-suite:420
  parallel --keep-order --jobs "$num_jobs" bats-exec-file "$(printf "%q " "${flags[@]}")" "{}" "$TESTS_LIST_FILE" ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1
```

`grep -n parallel bats-exec-suite` shows no `--will-cite` anywhere in the file.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`

---

## Claim 11a: C3 row — location "`devcontainer-config/Dockerfile:19-46`"

**Location:** `docs/reviews/override-log.md:83`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the cited range lands in the 577bef7 tree. It does not re-verify the row's rationale ("image has no cron or init").
**Legibility-target:** for-author

The range mixes the two numberings: the start `19` comes from 1ef3090 (where the `RUN` was `:19-43`) and the end `46` from 577bef7. In 577bef7, line 19 is `ARG CLAUDE_CODE_VERSION=latest` and the base apt `RUN` spans `:22-46`:

```dockerfile
# devcontainer-config/Dockerfile:19-22
ARG CLAUDE_CODE_VERSION=latest

# Install basic development tools and iptables/ipset
RUN apt-get update && apt-get install -y --no-install-recommends \
```

A reader still lands on the right block, 3 lines early. The precise citation is `devcontainer-config/Dockerfile:22-46`.

**Evidence:** `devcontainer-config/Dockerfile:19-46`, `git show 1ef3090:devcontainer-config/Dockerfile` (RUN at :19, clean at :43)

---

## Claim 11b: C3 row — "Debian `parallel` may hard-depend on `sysstat` (cron/systemd units), not stopped by --no-install-recommends"

**Location:** `docs/reviews/override-log.md:83`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Scope:** Covers the attempt only. It does not establish parallel's `Depends:` field.
**Legibility-target:** for-orchestrator-synthesis

`apt-cache depends parallel` returned only `<parallel>`, because the package index is empty (same run as Claim 9). The row already states the claim with "may" and "Unverifiable offline", so its framing is accurate. Verifying it needs `apt-cache depends parallel` against a bookworm index, as the row's revisit step says.

**Evidence:** `apt-cache depends parallel` output quoted under Claim 9

---

## Claim 12: C4 row — location "`devcontainer-config/Dockerfile:43`" and "invalidates every later layer (git-delta, uv, JDK, Android SDK, Rust, claude-code@latest…)"

**Location:** `docs/reviews/override-log.md:84`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line citation and the fact that git-delta and uv are later layers. I did not individually locate the JDK, Android SDK, Rust and claude-code layers beyond an Android-layer comment at `:158`, and I did not check the Reason's "re-bless" claim.
**Legibility-target:** for-orchestrator-synthesis

At 577bef7, `devcontainer-config/Dockerfile:43` is `  parallel \` (quoted under Claim 3). Later layers include `ARG GIT_DELTA_VERSION=0.18.2` (`:89`) and `ARG UV_VERSION=0.11.28` (`:115`), both after the base `RUN` ending at `:46`. A change to an earlier `RUN` invalidates the cache of every later instruction (documented Docker cache semantics — paraphrased, no quote available because this is Docker's behaviour, not repo code).

**Evidence:** `devcontainer-config/Dockerfile:43`, `devcontainer-config/Dockerfile:89`, `devcontainer-config/Dockerfile:115`, `devcontainer-config/Dockerfile:158`

---

## Claim 13: C5 row — "`bats --jobs N` in 1.8.2 also parallelises within each file (`bats-exec-file:294-296`), and `install-host.bats`'s real-/proc scan in `install.sh` `procs_in_checkout`"

**Location:** `docs/reviews/override-log.md:85`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both locations and that the scan reads the real `/proc`. It does not establish that `install-host.bats` would actually flake under concurrency (the row says "may").
**Legibility-target:** for-orchestrator-synthesis

```bash
# /usr/libexec/bats-core/bats-exec-file:294-296
  if [[ "$num_jobs" != 1 && "${BATS_NO_PARALLELIZE_WITHIN_FILE-False}" == False ]]; then
    export BATS_SEMAPHORE_NUMBER_OF_SLOTS="$num_jobs"
    bats_run_tests_in_parallel "$BATS_RUN_TMPDIR/parallel_output" || bats_exec_file_status=1
```
(excerpt ends :296; the enclosing `bats_run_tests()` continues with a serial `else` — read.)

```bash
# devcontainer-config/install.sh:1165-1169
procs_in_checkout() {
  local root d pid cwd cmd kind
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 3
  for d in /proc/[0-9]*; do
```
(excerpt ends :1169; the function continues to :1181 — read.)

The row writes the bare name `install.sh`. The only tracked file with that name is `devcontainer-config/install.sh`, so the reference is unambiguous. `test/install-host.bats` exists and edits this probe (T90 at `:1563-1567`).

**Evidence:** `/usr/libexec/bats-core/bats-exec-file:286-305`, `devcontainer-config/install.sh:1150-1181`, `test/install-host.bats:1563-1567`

---

## Claim 14: C6 row — location "`devcontainer-config/Dockerfile:1-6`" for the header "Local changes" list

**Location:** `docs/reviews/override-log.md:86`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the line range. It does not re-verify the list of missing entries (dnsmasq-base, uv, poppler-utils, JDK/SDK, Rust), which iteration 1 verdicted.
**Legibility-target:** for-author

`:1-6` was the whole header block at 1ef3090, where line 6 was `# Keep this file minimal-diff against upstream so refreshes are easy.`. The row was written in 577bef7, whose own 3 added lines push the block to `:1-9`. In that tree, `:1-6` ends in the middle of the new Q-086 entry and leaves out the `decision 016` entry (`:7-8`) and the closing line (`:9`):

```dockerfile
# devcontainer-config/Dockerfile:6-9
#     install below uses --no-install-recommends)
#   - decision 016: egress profiles baked in; the profile is written root-owned to
#     /etc/cc-egress-profile so an in-container agent cannot widen its own allowlist.
# Keep this file minimal-diff against upstream so refreshes are easy.
```

The precise citation at 577bef7 is `devcontainer-config/Dockerfile:1-9`, or `:2-8` for the list itself.

**Evidence:** `devcontainer-config/Dockerfile:1-9`, `git show 1ef3090:devcontainer-config/Dockerfile` lines 1-6

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 14** (`docs/reviews/override-log.md:86`): the C6 row cites `Dockerfile:1-6`, the 1ef3090 numbering. At 577bef7 the header block is `:1-9`; cite `:1-9` (or `:2-8`).

### Mostly Accurate
- **Claim 7a** (577bef7 `Live-verified:` trailer): "unchanged apart from the layer text" overstates the change. Dockerfile comments enter no layer or cache key, so the build is fully unchanged.
- **Claim 11a** (`docs/reviews/override-log.md:83`): the C3 row cites `Dockerfile:19-46`, which mixes the two numberings. The base apt `RUN` is `:22-46` at 577bef7.

### Unverifiable
- **Claim 7b** (577bef7 trailer): the host rebuild with `parallel --version` needs Docker on the host.
- **Claim 9** (`override-log.md:81`): the parallel version numbers need a bookworm index or the built image.
- **Claim 11b** (`override-log.md:83`): the `sysstat` hard dependency needs `apt-cache depends parallel` against a bookworm index.

---

## Goal-Alignment Note

- **Answered:** all three priority groups in the brief. (1) The new header claims hold: parallel is needed only for across-file parallelism with N>1 (re-executed with two files, log `docs/reviews/execution-logs/q086-bats-jobs-probe-iter2.log`), bats only Recommends parallel (`dpkg -s`), and the base apt `RUN` below the header carries `--no-install-recommends`. (2) The fix commit's A1/A2 descriptions and the "seven rows (A2, C1-C6)" count are accurate. The `Live-verified` trailer is slightly imprecise ("apart from the layer text"), and its rebuild reference is unverifiable here. (3) Of the line citations in the 7 rows, `bats-exec-file:294-296`, `bats-exec-suite:420`, `Dockerfile:43` and `install.sh procs_in_checkout` point where they say. `Dockerfile:19-46` (C3) mixes pre- and post-header-growth numbering (should be `:22-46`), and `Dockerfile:1-6` (C6) is stale after 577bef7 (should be `:1-9`).
- **Out of scope:** the iteration-1 review artifacts added by 577bef7, which are not under review. One observation from them: the iteration-1 log `q086-bats-jobs-probe.log` is internally inconsistent. The `--jobs 2` case shows `exit=0` right after the error line, but its summary line says `exit-code bats --jobs 2: 1`. The iter-2 re-run records exit 1 for that case, which matches the summary. I also did not re-check the rows' design rationales (sha stability, "re-bless", "image has no cron or init") or C6's list of missing packages.
- **Escalate:** nothing blocking. The two citation drifts (Claims 11a and 14) are one-token fixes in `override-log.md` if the author wants them exact.
