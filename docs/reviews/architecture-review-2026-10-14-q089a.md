# Architecture Review — Q-089 unit A (host-only tools get their own trust manifest)

Commit: dce5b039
**Scope:** `git diff 4ab9a51f dce5b039`: `devcontainer-config/cc-isolated.sh`, `devcontainer-config/cc-push.sh`, `devcontainer-config/install.sh`, `test/cc-isolated-functions.bats`, `test/cc-push.bats`. Files read as of dce5b039. Unit B (6e00137b: gate trailer, guide, decision log row 71) was read as context only.
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report.md` (unit A, 27 claims); `docs/reviews/q076-architecture-review-2026-09-27.md` Findings 2 and 3

**Scope check:** in scope. The diff changes a cross-cutting concern (the trust/bless pipeline). It adds a persisted contract (`host-tools.sha256`, beside `manifest.sha256`). It changes what goes into `blessed_hash`, which is the identity baked into the image. It also adds a function that two entry points share (`verify_host_tools`).

**Trust-boundary cross-reference:** a no-op. The most recent security review, `docs/reviews/security-review-egress-zone-entries-2026-09-19.md` (Commit: `7c970bfe`), maps egress boundaries only. None of its labels coincide with the host-tool or bless boundary this diff changes. No security review of this diff exists.

## Dependency Map

- **`cc-isolated.sh` (launcher, boundary config).** Owns `config_dir`, `enforcement_files`, `compute_manifest`, `blessed_hash` and `check_manifest`. It now also owns `host_tool_files`, `host_tools_path`, `compute_host_tools_manifest` and one copy of `verify_host_tools`. At source time it verifies `cc-exit-scan.sh` and `cc-gitdir.sh` before sourcing the scan (`:616-629`). `main` refuses everything except `--bless` and `--list` when that check fails (`:661-667`). The refusal comes before `check_manifest` (`:716`).
- **`cc-exit-scan.sh` (host tool).** Sources `cc-gitdir.sh` from its own directory (`cc-exit-scan.sh:10-11`). This file is unchanged by the diff.
- **`cc-push.sh` (host tool, standalone entry point).** Holds the second copy of `verify_host_tools` (`:137-170`). It verifies itself and `cc-gitdir.sh`, then sources `cc-gitdir.sh` (`:175-181`). It does not depend on `cc-isolated.sh`. Its only shared knowledge is the file names `host-tools.sha256` and `manifest.sha256`, and the default config path.
- **`install.sh`.** Runs `CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless` (`:607`). That is the only writer of both manifests outside a manual `--bless`. The upgrade path depends on `--bless` being exempt from the host-tool refusal: an old install has `manifest.sha256` but no `host-tools.sha256`.
- **`hooks/live-verify-gate.sh` (unit B).** Holds a regex copy of each list. A test pins each regex to its function: `host_tool_files` at `live-verify-gate.bats:325`, `enforcement_files` at `:111-122`.

Dependencies point the right way. The host tools do not depend on the launcher, and the launcher depends on the host tools only by verifying and sourcing them. There are no cycles. The pressure points are these:
- One bless verb now spans two trust categories (Finding 1).
- The knowledge of which files each entry point executes is written down three times and pinned nowhere (Finding 2).
- The "is this an installed copy" predicate is inferred from side facts (Finding 3).

## Findings

#### 1. One bless verb spans both trust categories, and the host-tool refusal hides the boundary diff behind it

**Severity:** Coupling
**Location:** `devcontainer-config/cc-isolated.sh:250-266` (`bless_manifest`), `:661-667` (host-tool refusal in `main`), `:716` (`check_manifest`)
**Move:** 7 (coupling surface), 2 (responsibility)
**Confidence:** High (probed)
**Legibility-target:** the `main` refusal message and `bless_manifest`'s printout, read by whoever runs `--bless` after a host-tool refusal

Evidence:
```
bless_manifest() {
  mkdir -p "$(config_dir)"
  compute_host_tools_manifest > "$(host_tools_path)"
  compute_manifest > "$(manifest_path)"
  echo "Blessed $(manifest_path) ($(wc -l < "$(manifest_path)") entries):"
  cat "$(manifest_path)"
```
```
    echo "ERROR: $HOST_TOOLS_ERR — refusing to run the session-exit scan's code." >&2
    echo "  Review the host tools in $CC_ISOLATED_DIR (cc-exit-scan.sh, cc-gitdir.sh), then:" >&2
    echo "    cc-isolated --bless" >&2
    echo "  A host-tool change does not alter the blessed config: no rebuild or probe is needed." >&2
```

The data split is clean, but the verb is shared: one `--bless` rewrites both manifests. The diff also orders the host-tool refusal ahead of `check_manifest`. Together these mean that when both a host tool and a boundary file have changed, the user sees only the host-tool error. That error tells them to run the verb that also accepts the boundary change, and says no rebuild is needed.

Probe (temp install with stub boundary files; bless; then append to `init-firewall.sh` and `cc-exit-scan.sh`; then launch):
- The launch printed only `cc-exit-scan.sh changed since the last bless … no rebuild or probe is needed`. `check_manifest`'s diff, which names `init-firewall.sh`, was never shown.
- The prescribed `--bless` then printed the new `init-firewall.sh` hash with no diff and accepted it.
- `bless_manifest` never prints `host-tools.sha256`, so the review the error asks for has no on-screen record of what was blessed.

Before this diff, a scan edit tripped `check_manifest`, which printed the full diff. The later "Verified live: NO" line and the launch-time rebuild limit the damage: the boundary change still gets rebuilt and probed on the next launch. What is lost is the review evidence, not enforcement.

**Recommendation:** pick one of two fixes.
- **Keep one verb.** Have the host-tool branch in `main` also run a quiet `check_manifest` and print its diff (or a "boundary config also changed" line) before suggesting `--bless`. Have `bless_manifest` print the host-tool lines next to the boundary lines.
- **Split the verb.** Give host tools their own verb (`--bless-host-tools`) that writes only `host-tools.sha256`. That also makes the "no rebuild is needed" line true by construction.

Either way, the message should say "no rebuild" only when `check_manifest` passes.

#### 2. The files each entry point executes are recorded in three unpinned places

**Severity:** Coupling
**Location:** `devcontainer-config/cc-isolated.sh:624` (launcher's argument list), `devcontainer-config/cc-push.sh:176` (cc-push's argument list), `devcontainer-config/cc-isolated.sh:199-203` (`host_tool_files`), `devcontainer-config/cc-exit-scan.sh:10-11` (its own `source`)
**Move:** 7 (coupling), 8 (extension points)
**Confidence:** Medium-High (traced from the code; no test pins the closure)
**Legibility-target:** whoever next adds a helper sourced by a host tool

Evidence:
```
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
```
```
if ! host_tools_err="$(verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh)"; then
```
```
source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"
```

The launcher's argument list encodes `cc-exit-scan.sh`'s source graph: it verifies `cc-gitdir.sh` only because the scan sources it. `host_tool_files` is the union of both lists, but nothing derives either list from it, and nothing derives either list from the `source` lines.

The tests pin three things: PAYLOAD ⊆ enforcement ∪ host, the host list exactly (`:835`), and the gate regex to `host_tool_files` (unit B). None of them pins "every file an entry point sources, transitively, is in that entry point's `verify_host_tools` arguments".

Suppose `cc-exit-scan.sh` grows a `source …/cc-foo.sh`. The PAYLOAD test and the exact-list test force `cc-foo.sh` into `host_tool_files`. The launcher would still source it unverified, and every test would pass. This is the same failure mode as q076 Finding 2: hand-kept lists drift unless a test pins them.

Keeping a per-entry-point list is right: verifying all of `host_tool_files` in cc-push would make a scan edit block pushes, which is the coupling this unit removes. The gap is only the missing pin.

**Recommendation:** add one bats test that does three things:
1. Parse the `source "…/<name>"` lines of each entry point and of every file they source.
2. Assert each entry point's transitive closure equals the arguments at its `verify_host_tools` call site (extracted with the same marker or grep technique as the parity test).
3. Assert those arguments ⊆ `host_tool_files`.

That moves the knowledge to the `source` lines, where an editor naturally makes the change.

#### 3. "Is this an installed copy" is inferred from two side facts, and one of them restates `config_dir`'s default

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:223-230`, `devcontainer-config/cc-push.sh:145-152` (`verify_host_tools`, the checkout-vs-installed predicate)
**Move:** 7 (coupling), 3 (module boundary)
**Confidence:** Medium
**Legibility-target:** the `verify_host_tools` header comment ("an installed copy cannot opt out by deleting host-tools.sha256")

Evidence:
```
  cfg="$(readlink -f -- "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}" 2>/dev/null || true)"
  if [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
    return 0
  fi
```

The verifier fails open by default. It treats any directory as a repo checkout unless it holds a manifest or is the run-time config dir. Two pieces of launcher knowledge are copied into it:
- the boundary manifest's file name;
- `config_dir()`'s default path, rewritten inline because the function has to be self-contained for the parity test.

The fact-check (Claim 9b, "Mostly accurate") shows the consequence. With a custom `DEST` and `CLAUDE_DEVC_CONFIG_DIR` unset when cc-push runs, deleting both manifests turns the installed cc-push back into an unchecked "checkout". The header's "cannot opt out" overstates this.

The structural issue is the direction of the default. Repo checkouts, the case that wants no check, get no positive marker. Installed copies, the case that wants the check, get one only by coincidence of layout. The predicate also drifts if `config_dir`'s default or the manifest name ever changes, because neither copy is pinned to the launcher's definitions.

**Recommendation:** make the checkout case explicit. Check that `$dir/../.git` exists and `$dir` is named `devcontainer-config`, or require an opt-in variable for running unchecked from a checkout. Treat everything else as installed. Failing that, add a test asserting that the inline default equals `config_dir`'s with the variable unset. Correct the header comment either way.
**Security implication:** this changes which directories the host-tool integrity check covers, which is the bless → host-tool-execution boundary. No security review labels it yet. Settle the fail-closed default in a security review rather than here.

#### 4. The host tools' own headers still put them in the boundary category

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:1-5`, `devcontainer-config/cc-gitdir.sh:1-5` (unchanged by unit A or unit B)
**Move:** 2 (responsibility boundaries)
**Confidence:** High (fact-check: Stale)
**Legibility-target:** the header of each host tool, the first thing an editor of that file reads

Evidence (`cc-gitdir.sh:3-5`; `cc-exit-scan.sh:3-5` says the same):
```
# installed in; not run on its own. It defines functions only. It ships with the
# launcher: install.sh's PAYLOAD installs it, enforcement_files() hashes it into
# the trust manifest, and hooks/live-verify-gate.sh gates commits to it.
```

The category a file belongs to decides which trailer its commits need (unit B) and what a change to it costs: a re-bless, not a rebuild. Each file's header says the opposite of row 71, so the next editor learns the wrong cost from the file they are editing.

**Recommendation:** rewrite both headers along these lines: "a host tool: `host_tool_files()` hashes it into `host-tools.sha256`; `verify_host_tools` checks it before it is sourced; commits to it carry `Host-tool-tested:` (decision log row 71)".

#### 5. Duplicating the verifier, pinned by a byte-parity test, is the right shape

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:215-248`, `devcontainer-config/cc-push.sh:137-170`, `test/cc-isolated-functions.bats:923-930`
**Move:** 7 (coupling), 1 (dependency direction)
**Confidence:** High
**Legibility-target:** the `KEEP IN STEP` marker comments

Evidence:
```
# --- verify_host_tools: KEEP IN STEP with the copy in cc-push.sh (a test
# compares the two byte for byte).
```

The alternative, a shared `cc-verify.sh` that both entry points source, would itself be executable code loaded before anything has been checked. The verifier would then need its own hash anchored in something already trusted, which at that point is only the entry point's own text. Embedding the verifier in each entry point puts it inside the file the user already chose to run. That is the only trust root available without a separate binary.

The parity test (`:923-930`) follows the q076 Finding 2 precedent: an intentional copy pinned by a test. It also asserts the extracted block is non-empty and contains the function, so a renamed marker cannot pass vacuously.

The cost is small. The function is about 25 lines, and any edit fails the test until both copies match.

**Recommendation:** none. If a third entry point appears, extend the parity test to a list of files rather than adding a pairwise comparison.

## What Looks Good

- **The category split does what q076 Finding 3 recommended.** It adds a separate list and a separate persisted file. `blessed_hash` now covers only boundary config, so the image identity, the verified-live receipt and the rebuild trigger no longer move on host-tool edits. Test `:869` verifies this directly.
- **The lists are pinned.** The PAYLOAD test now checks that the two lists are disjoint and that the host list is exact, so moving a boundary file into the host list fails. It also checks that the image COPYs no host tool, which pins "host tool ⇒ not in the image" from both sides.
- **Integrity is checked where the code runs.** Each entry point verifies before it sources, as q076 recommended ("check it where cc-push runs, not in the launcher"). A cc-push-only change no longer blocks launches, and a scan-only change no longer blocks pushes.
- **Blocking the launcher on a scan change is the right boundary.** The launcher executes the scan: it takes the snapshot before the session and runs the scan at exit. Launching without it would silently drop the tripwire. Requiring only a re-bless, not a rebuild and probe, prices that correctly.
- **The `--bless` / `--list` exemption keeps the upgrade path working.** `install.sh:607` runs `--bless` on an install that has `manifest.sha256` but no `host-tools.sha256`, and the exemption lets that run. The fact-check verified the upgrade path. Without the exemption, the new verifier would block its own installer.
- **The scan is not sourced when the check fails.** No function the scan defines exists in that process, so no later code path can reach unverified code by accident. Test `:932` confirms this with a marker file.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | One bless verb spans both categories; the host-tool refusal hides the boundary diff and prescribes the verb that accepts it | Coupling | `cc-isolated.sh:250-266, 661-667, 716` | High |
| 2 | Per-entry-point verify lists encode the source graph in three unpinned places | Coupling | `cc-isolated.sh:624`, `cc-push.sh:176`, `cc-exit-scan.sh:10-11` | Medium-High |
| 3 | Installed-vs-checkout predicate is inferred and fails open; it restates `config_dir`'s default | Minor | `cc-isolated.sh:223-230`, `cc-push.sh:145-152` | Medium |
| 4 | Host-tool headers still claim `enforcement_files` hashes them | Minor | `cc-exit-scan.sh:1-5`, `cc-gitdir.sh:1-5` | High |
| 5 | Duplicated verifier with byte-parity test is the right shape | Informational | `cc-isolated.sh:215-248`, `cc-push.sh:137-170` | High |

## Overall Assessment

The change improves the system's structural health. It removes a real mis-categorization (q076 Finding 3) along a clean seam: a separate list and a separate persisted manifest, checked by each entry point where the code runs, with the lists pinned by tests. Nothing found needs restructuring, and all findings are fixable in place.

The most important concern is Finding 1. The data is split, but the operator workflow is not. One `--bless` rewrites both manifests, and the new refusal runs before `check_manifest`. So the case of a host tool and a boundary file changed together produces a message that is wrong in that case ("no rebuild or probe is needed") and hides the boundary diff that was the evidence for the review. Finding 2 is the next fix: one test that ties each entry point's verify list to its `source` lines.

## Goal-Alignment Note

The goal was a pass-1 architecture review of unit A before merge. Unit A achieves Q-089's aim: a host-tool edit leaves `blessed_hash`, the baked image hash and the verified-live receipt unchanged, and the test at `:869` checks this directly. Row 71 records one deviation, that a scan or gitdir edit still stops a launch, and this review agrees with it.

The remaining gaps are an operator-message and verb-scope issue (Finding 1), a missing pin (Finding 2), a fail-open default that belongs to a security review (Finding 3), and two stale headers (Finding 4). None of them reopens the original problem.

For merging: if the review-fix loop treats Coupling as must-address, Findings 1 and 2 are small and local. They need a message change plus either a printout change or a verb split, and one bats test.
