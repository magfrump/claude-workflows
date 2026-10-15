Commit: dce5b039

# Performance Review: Q-089 unit A (host-tools.sha256 gate)

**Scope:** `git diff 4ab9a51f dce5b039` (cc-isolated.sh, cc-push.sh, install.sh, test/cc-isolated-functions.bats, test/cc-push.bats). Files read as of `dce5b039`; unit B not reviewed.
**Date:** 2026-10-14
**Based on:** docs/reviews/code-fact-check-report.md (no Incorrect verdicts; nothing perf-related flagged)

## Data Flow and Hot Paths

`verify_host_tools` runs at **source time** (top level) of both entry points:

- `cc-isolated.sh` checks `cc-exit-scan.sh` and `cc-gitdir.sh` once per invocation, before `main` and before the action is known, so it also runs for `--bless` and `--list`. A launch is interactive, one per session, and then `devcontainer up` plus the boundary probe run, which take seconds. This is a **cold** path.
- `cc-push.sh` checks itself and `cc-gitdir.sh` once per push, before a `git fetch`/`git push` round trip. Also **cold**.
- Tests: `test/cc-isolated-functions.bats` `setup()` sources the repo copy of `cc-isolated.sh` for each of its 177 tests. A repo checkout has no manifest, so the function returns early after one `readlink -f` command substitution.

N is fixed: `host_tool_files` is a hard-coded list of 3, and each entry point passes 2 names. The files are 51,553 B (`cc-exit-scan.sh`) and 4,452 B (`cc-gitdir.sh`). Nothing in the code path grows with user data.

On the bless side, `compute_host_tools_manifest` runs one `sha256sum` over all 3 files, which follows the batching rule in `compute_manifest`. The 3 files also leave `enforcement_files`, so the launch-time `compute_manifest` batch has 3 fewer entries.

**Probe** (scratch dir `/home/node/.claude/jobs/00bcf178/tmp/perfprobe.PAfs`, under `timeout`, WSL2 host, 2026-10-14, mean of 100 calls on the dce5b039 copies of the files):

| Case | Cost per call |
|---|---|
| `verify_host_tools`, installed layout, 2 files | 13.5 ms |
| `verify_host_tools`, repo checkout (early return) | 3.0 ms |
| one batched `(cd D && sha256sum f1 f2)` for comparison | 2.9 ms |

## Findings

#### Per-file fork chain repeats the pattern compute_manifest's comment warns against

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:234-246` and the byte-identical copy in `devcontainer-config/cc-push.sh` (`verify_host_tools` loop)
**Move:** Count the hidden multiplications
**Classification:** Micro (constant forks per file) / Cold path (one call per interactive launch or per push)
**Confidence:** High
**Legibility-target:** the loop body in `verify_host_tools`
**Baseline:** 13.5 ms per call (2 files), measured by the probe above (100 iterations, WSL2, 2026-10-14)

Evidence:
```bash
    want="$(awk -v f="$f" '$2 == f { n++; h = $1 } END { if (n == 1) print h }' "$m")"
    have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"
```
Each file costs two command substitutions and three external processes (`awk`, `sha256sum`, `cut`). The `compute_manifest` comment says to avoid this: "a fork per file made every launch pay for it". There the list was about 100 files. Here N is hard-coded at 2, so the total is about 13.5 ms. A single batched `sha256sum` costs 2.9 ms. Either figure is noise next to `devcontainer up` or a network push. The cost cannot grow unless someone lengthens `host_tool_files`.

**Recommendation:** No change is needed for performance. If `host_tool_files` ever grows past a handful of entries, switch to one `sha256sum` plus one `awk` join, as `compute_manifest` does. A one-line note beside `host_tool_files` would carry that rule forward, but it is optional.

#### Source-time check adds a fixed cost to every sourcing of cc-isolated.sh, including in tests

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:621-629` (top-level `CC_ISOLATED_DIR=` / `if HOST_TOOLS_ERR="$(verify_host_tools ...)"`)
**Move:** Find the work that moved to the wrong place
**Classification:** Micro / Cold path (per process start; the test suite is the only caller that repeats it)
**Confidence:** Medium. The per-call number is measured. The suite total is arithmetic and was not timed.
**Legibility-target:** the top-level block before `usage()`
**Baseline:** 3.0 ms per call on the repo-checkout early-return path, measured by the probe above

Evidence:
```bash
CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
HOST_TOOLS_ERR=""
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
```
The check has to run before `source cc-exit-scan.sh`, and that sourcing happens at top level, so the placement is forced by the security goal. It is not an accident. As a result, every `source cc-isolated.sh` pays for it, including the 177 `setup()` calls in `cc-isolated-functions.bats` and the ad-hoc `bash -c 'source ...'` calls in `cc-push.bats` and `live-verify-gate.bats`. 177 × 3.0 ms ≈ 0.5 s across the suite. That is small against the suite's other forks and well inside the parallel-gate budget. It is also the only place this change's cost repeats.

**Recommendation:** No change. Keep the check at source time. Moving it into `main` would leave `cc-exit-scan.sh` sourced before it is checked, which defeats the change.

## Endorsements (evidence-gated)

- The bless writes all 3 host tools with one `sha256sum` (`compute_host_tools_manifest`), which follows the batching rule `compute_manifest` documents. [read: devcontainer-config/cc-isolated.sh:209-213]
- Moving `cc-exit-scan.sh`, `cc-gitdir.sh` and `cc-push.sh` out of `enforcement_files` shrinks the launch-time `compute_manifest` input by 3 files, which partly offsets the new check. [read: devcontainer-config/cc-isolated.sh:128-151]
- The claim that the host-tool check adds no latency large enough for a user to notice at launch or push time (about 13.5 ms against a multi-second container start or network push) is backed by the probe, not by a fact-check verdict. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Per-file fork chain in `verify_host_tools` (N fixed at 2) | Informational | `devcontainer-config/cc-isolated.sh:234-246`, cc-push.sh copy | High |
| 2 | Source-time check cost repeats per test `setup()` | Informational | `devcontainer-config/cc-isolated.sh:621-629` | Medium |

## Overall Assessment

The change has no performance problem. The new work is a fixed, bounded check: 2 files, measured at 13.5 ms. It runs once per interactive launch and once per push, both cold paths dominated by container start and network I/O. Its per-file fork pattern goes against the `compute_manifest` comment in letter but not in effect, because N is hard-coded and tiny. The bless side batches correctly, and the boundary manifest gets slightly smaller. Nothing needs fixing before merge, and no further profiling is needed.

## Goal-Alignment Note

The PR aims to give host-only tools their own manifest so that editing one no longer changes the blessed boundary hash, and to have each entry point check the tools it is about to run before sourcing them. Performance does not stand in the way of that goal. The one structural cost (the check runs at source time) comes directly from the security requirement and should be kept. Both findings are Informational, and neither calls for a change to the diff.
