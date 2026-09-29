# Security Review — branch q093-cc-push-self-commondir, pass 2

Commit: b9f6cc4
**Scope:** `git diff 2c8163f..b9f6cc4` (cc-push.sh `commondir_is_self` read + refusal text, test/cc-push.bats symlink case, plan wording); `git diff dfe4c0d..HEAD` checked for combined regressions. Read in full: `commondir_is_self` (cc-push.sh:271-279), `check_checkout` (:284-337), `safe_path` (:121-134), `main` through `check_checkout` (:354-389), both Q-093 bats tests (:262-311).
**Date:** 2026-09-28
**Based on:** pass-1 review `docs/reviews/q093-security-review-2026-09-28.md`; pass-2 code-fact-check `docs/reviews/q093-code-fact-check-report-pass2.md` (12 Verified, 1 Mostly accurate, since fixed)

## Trust Boundary Map

```
B1 (modified): [session-written .git/commondir: type, size, bytes] → [commondir_is_self: -L/-f, stat, timeout 5 head -c 2 | od] → [host git-upload-pack --strict resolving the common dir]
B2:            [session-written .git/* other entries]              → [find -P scan, include/promisor grep, gitdir_valid, looks_like_gitdir] → [upload-pack reads refs/objects/config]
B3:            [container liveness between check and fetch]         → [check_no_container, --allow-running override]                         → [fetch runs on what was checked]
B4:            [host $PATH]                                          → [safe_path "$co" (absolute, not inside checkout)]                     → [exec of stat / timeout / head / od]
```

Input sources:

```
S1: <co>/.git/commondir (type, size, bytes) — request-time (session writes it) — UNTRUSTED for path-resolution / blocking-read sinks
S2: <co>/.git/* other entries               — request-time — UNTRUSTED (all sinks); unchanged by this delta
S3: host $PATH after safe_path              — deploy-time  — trusted for exec of coreutils (timeout, head, od, stat)
S4: docker ps result                        — host-authoritative — trusted for the "container stopped" availability decision; overridable by --allow-running
S5: host git's protocol default (v2 on git >= 2.26; cc-push requires >= 2.39.4) — deploy-time — trusted; relevant only to what B13 evidence covers
```

The delta changes nothing about what the helper accepts: it bounds the one read of S1 (`timeout 5`), rewords the refusal, and makes the symlink test discriminate the helper's `-L` check. The attacker model (session writes anything in `.git`; container stopped before `check_checkout`, since `check_no_container` runs first at :388) is unchanged.

## Bypass enumeration (move #11) — the timed read in `commondir_is_self`

Probe (executed, `scratchpad/p2/probe.sh`): the read line copied verbatim into a script under `set -euo pipefail`, run against scratch FIFOs and files. Bats: `LC_ALL=C bats -f Q-093 test/cc-push.bats` → both tests `ok`.

| # | Candidate | Dispatch | Result |
|---|---|---|---|
| D1 | FIFO swapped in after the type test, no writer | Tested (executed, `timeout 2`) | `rc=124 hex=[]` → `|| return 1`: refused, bounded (pre-delta: hang) |
| D2 | FIFO, writer sends `.` and holds it open (partial read of 1 byte, then timeout kill) | Tested (executed) | `rc=124 hex=[]`: refused. Even had `head` flushed `.` before the kill, pipefail carries 124 into the assignment's status, so the partial bytes are never compared |
| D3 | FIFO, writer sends `.` and closes | Tested (executed) | `rc=0 hex=[2e]`: **accepted by the helper** — see Finding 2. Not introduced by the delta (untimed `head` behaved the same) and needs a live writer; the later `find -P ... ! -type f` scan (:305) refuses the FIFO if it is still there |
| D4 | Regular 2-byte file truncated to `.` between `stat` and `head` (1-byte read) | Read-static | `head -c 2` on a regular file loops until 2 bytes or EOF; a 1-byte result means the file then held exactly `.`, which git reads as self. Any later rewrite is B11 (git re-reads later), same as pre-delta |
| D5 | `timeout` missing / not executable (e.g. macOS without coreutils) | Tested (executed, PATH emptied) | `rc=127` → refused: fail-closed. Same dependency as the pre-existing `timeout 20 docker ps` (:228) |
| D6 | `timeout` resolved from a session-planted binary | Read-static | `safe_path "$co"` (:383) runs before `check_checkout` (:389); same resolution as `stat`/`head`/`od` in pass 1 |
| D7 | pipefail not in effect inside `$(...)` | Tested (executed) | `x="$(false | cat)"` returned 1 under the script's `set -o pipefail`: inherited, so 124/127 reach `|| return 1` |
| D8 | Symlink `commondir -> d` (1-byte target) with the `-L` test removed | Tested by fact-check pass 2 (mutation m1 → test rc=1) + read | New test at bats:307 fails the mutant; the refusal still exits 1 via the find scan, and the `*"commondir exists"*` assertion is what catches it |
| D9 | Self-commondir changing what upload-pack reads under protocol v2 / the pack phase (plan B13) | **Untested** | listed below |

### Untested bypass candidates

- **D9 — B13 under protocol v2 and the pack phase.** Fact-check pass 2 reproduced B13 (identical advertisement, `config.worktree` values and HEAD for commondir absent, `.`, `.\n`) but scoped it to the protocol v0 ref advertisement. cc-push's `ls-remote` and `fetch` (:438, :447, :454) set no `protocol.version`, so on the git versions it permits (>= 2.39.4) they run protocol v2 (`ls-refs`, then `fetch`). Read-static expectation: the common dir is resolved at repository setup, before any protocol negotiation, and v2 `ls-refs` applies hideRefs through the same ref iteration, so the result should match; objects resolve to `<g>/./objects` = `<g>/objects`. Not executed: git outside this worktree is off-limits in this session. Host check: repeat the fact-check's `b13.sh` with `git -c protocol.version=2 ls-remote --upload-pack='git-upload-pack --strict' <gitdir>` and a full `fetch` into a scratch bare repo, diffing refs and `rev-list --all --objects` across absent / `.` / `.\n`.

## Findings

#### 1. B13 is marked "Covered … Verified" on protocol v0 evidence, while cc-push fetches with protocol v2

**Severity:** Informational
**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:75`; fetch calls `devcontainer-config/cc-push.sh:438,447,454`
**Boundary:** B1
**Move:** #11 (bypass enumeration), #2 (implicit assumption)
**Confidence:** Medium (that v2 behaves identically; the evidence gap itself is High)

The plan row's verification sentence names "upload-pack --strict's ref advertisement" without saying which protocol; the fact-check scope line says it covers v0 only and "does not establish protocol v2 `ls-refs` … or the full fetch (pack) phase". The production path is v2 on every git cc-push accepts. No mechanism is known by which v2 or the pack phase would read differently with a `.` commondir (common-dir resolution happens at setup), so this is an evidence-scoping gap, not a bypass.

**Recommendation:** Either run the D9 host check and extend the row to "v0 and v2, including fetch", or scope the row's wording to "v0 ref advertisement" so a later reader does not take it as covering the production protocol.

#### 2. The helper accepts a FIFO swapped in after its type test if a writer supplies `.` and closes

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:271-279` (read at :276); backstop `:305-311`
**Boundary:** B1, B3
**Move:** #4 (TOCTOU)
**Confidence:** High

Evidence (probe, executed): `rc=0 hex=[2e]` for `( printf . > fifo ) & timeout 2 head -c 2 -- fifo | od -An -tx1`. The comment "(and the read is timed, should one be swapped in between)" is accurate about hanging but could be read as "a swapped FIFO is refused"; it is refused only when no writer completes within 5 s. This requires a live writer during cc-push (i.e. `--allow-running` or docker misreporting), and the `find -P` scan that follows refuses any FIFO still present; an attacker who swaps back to a regular file in time is in plan B11's residual window, which exists with or without this helper. The delta neither creates nor widens this (the untimed read returned the same bytes).

**Recommendation:** None required. If the comment is touched again, say "a FIFO swapped in cannot hang it" rather than implying refusal; B11 already records the residual.

## Endorsement Claims

None for `commondir_is_self` as a guardrail: D9 is an untested candidate (move #11 bars it). Scoped observations on the delta:

- **Claim:** Every failure of the timed read — timeout kill (124), missing `timeout` (127), `head` error — makes `commondir_is_self` return 1, including when some bytes were read before the kill.
  **Location:** `devcontainer-config/cc-push.sh:276`
  **Evidence:** executed
  **Verified:** D1, D2, D5, D7 probes of the verbatim line under `set -euo pipefail`; the script sets `pipefail` at :112 before `main`.
  **Not verified:** behaviour of non-GNU `timeout` implementations (e.g. BusyBox) on a host PATH.
  **route: code-fact-check**
- **Claim:** The new symlink case in test 15 (bats:307) is refused by the helper's `-L` test and not by the size gate.
  **Location:** `test/cc-push.bats:304-310`
  **Evidence:** executed
  **Verified:** Q-093 bats tests pass at b9f6cc4; fact-check pass 2 mutation m1 (drop `-L`) fails the test, m0 (old long-target link) did not.
  **Not verified:** a mutation that drops `-L` *and* changes the find-scan message (the assertion keys on the message).
- **Claim:** The reworded refusal still contains `commondir exists`, the substring both Q-093 tests and the http-alternates test assert on; no other file quotes the old text.
  **Location:** `devcontainer-config/cc-push.sh:295`
  **Evidence:** read-static
  **Verified:** grep of the repo (excluding docs/reviews) for the old phrases; bats assertions read.
  **Not verified:** external scripts outside the repo that parse cc-push's stderr.

## Primitive sweep

Primitive: blocking open/read of a session-controlled path (S1)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-push.sh:274` `stat -c %s` | S1 | `! -L && -f` | cleared — lstat-level, no open |
| `cc-push.sh:276` `timeout 5 head -c 2` | S1 | type test, size 1-2, 5 s bound | cleared for hang (D1); Finding 2 for the live-writer FIFO accept |
| `cc-gitdir.sh:57-61` `read < "$c"` in `gitdir_common` | S1 | `-f && -r`, size cap | cleared — unchanged; reached only after the helper and the find scan |
| `cc-push.sh:305` `find -P` over `.git` | S2 | never follows links, `-quit` | cleared — unchanged; backstop for D3/D8 |
| git-upload-pack `--strict` reading `commondir` (v2 ls-refs / fetch) | S1 | all of `check_checkout` | Untested candidate D9 (Finding 1) |

Primitive: process exec by name

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-push.sh:276` `timeout`, `head`, `od` | S3 | `safe_path "$co"` (:383) | cleared — same resolution as `timeout 20 docker ps` (:228) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | B13 evidence is protocol v0; production fetch is v2 | Informational | B1 | plan:75; `cc-push.sh:438-454` | Medium |
| 2 | Helper accepts a swapped FIFO fed `.` by a live writer (backstopped; B11 residual) | Informational | B1, B3 | `cc-push.sh:276` | High |

## Overall Assessment

The pass-2 delta is a strict improvement and introduces no fail-open path: the timeout converts the one blocking-read case into a refusal, and pipefail guarantees a killed or missing `timeout` is refused even when partial bytes were read (answering the "partial `.` from a 2-byte file" question: on a regular file a 1-byte read means the file then held exactly `.`; on a timed-out FIFO the status, not the bytes, decides). Combined with dfe4c0d..2c8163f, no regression: the accepted set is still exactly `.`/`.\n` regular non-symlink files, every later `check_checkout` guard still runs, and pass-1 Finding 1 (symlink test) is fixed and mutation-checked. Protocol v2 matters to B13 only as evidence scope (Finding 1); no mechanism is known. Verdict: *no findings within the code paths read; endorsement claims pending execution verification* — mergeable; the D9 host check is worth running before the plan calls B13 fully verified.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/worktrees/agent-ab977469478643bc3/docs/reviews/q093-security-review-pass2-2026-09-28.md structured per skills/security-reviewer/SKILL.md.
- Answered: yes; both requested considerations (timeout fail-open, protocol v2 / B13) are covered.
- Out of scope: running git outside the worktree (D9 left as a host command).
- Escalate: none blocking; D9 host check optional before merge.
- Decisions I made: rated both findings Informational (neither names a mechanism that violates a property in a reachable environment without a live writer, which B3 gates); did not flag that GNU `timeout` moves itself to its own process group (a Ctrl-C leaves it running up to 5 s, reading only), as it has no security effect and matches the existing `docker ps` call.
