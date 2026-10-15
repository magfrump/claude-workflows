Commit: dce5b039

# Security Review: Q-089 unit A (host-only tools get their own trust manifest)

**Scope:** `git diff 4ab9a51f dce5b039` (`devcontainer-config/cc-isolated.sh`, `cc-push.sh`, `install.sh`, `test/cc-isolated-functions.bats`, `test/cc-push.bats`). Files read as of dce5b039 via `git show`. Unit B (6e00137b: gate, guide, decision log row 71) was read as context only.
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report.md` (27 claims, Commit dce5b039), `docs/working/plan-q089-host-tool-trust.md` (pre-mortem B1 to B9), decision log rows 45 and 71.
**Probes:** all run under `timeout` in `/home/node/.claude/jobs/00bcf178/tmp/secrev-probe.O9RpLz/`, with `HOME` redirected to `$E/h*/` and `$E/old/`. Each fake config dir holds the nine dce5b039 (or 4ab9a51f) files, blessed by `cc-isolated.sh --bless`. I did not touch the real `~/.config/claude-devcontainer` and did not run install.sh.

## Trust Boundary Map

```
B1 (new):   [host-tools.sha256 + host tool files in script dir] → [verify_host_tools (hash, -f/-L)] → [source into cc-isolated / cc-push, user's host privileges]
B2 (moved): [cc-exit-scan.sh, cc-gitdir.sh, cc-push.sh]          → [was: check_manifest at launch; now: B1 only] → [host execution]
B3:         [manifest.sha256 boundary files (Dockerfile, firewall…)] → [check_manifest / --bless (human review)] → [blessed_hash baked into image]
B4 (new):   [env CLAUDE_DEVC_CONFIG_DIR + presence of manifests]  → [repo-checkout opt-out heuristic] → [verification skipped]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | Host tool files in the installed dir | runtime-mutable (any user-uid process) | UNTRUSTED toward the exec/source sink until hashed. The control exists for exactly this. |
| S2 | `host-tools.sha256` | runtime-mutable, same dir and same writer as S1 | Trusted only as a defence-in-depth reference. Anyone who can write S1 can rewrite it (B2 in the plan, accepted). |
| S3 | `CLAUDE_DEVC_CONFIG_DIR` env var | invocation-time, user-shell controlled | UNTRUSTED toward the opt-out decision (B4). Trusted for choosing the config location. |
| S4 | Presence or absence of `manifest.sha256` / `host-tools.sha256` | runtime-mutable | UNTRUSTED toward the opt-out decision. Deleting a file is as cheap as editing one. |
| S5 | Script's own dir (`readlink -f` of `BASH_SOURCE`) | resolved per call; PATH symlink is user-writable | Trusted for locating files (canonicalised). A repoint of the PATH link is accepted (plan B6). |
| S6 | Human reading the refusal / bless output | n/a | The human is the final check at B3. Anything that changes what they are shown is in scope. |

What enters: files and their hashes from a user-writable dir (S1, S2), plus two signals that decide whether to check at all (S3, S4). The diff moves the host tools from B3 (check_manifest, at launch) to the new B1 (per entry point, before sourcing). It also adds an opt-out (B4) for repo checkouts. The threat model (row 45) is non-targeted host-side tampering by a process running as the user. Decision rows 45 and 71 accept that a targeted attacker with that access wins. So I rate severity by how much **detection coverage changes relative to 4ab9a51f** against non-targeted tampering.

On the floor rule: every mechanism below needs user-uid write access on the host. That is the case the floor rule exempts ("requires the attacker to already control the host"), and it is also the only attacker this control exists for. I apply the exemption uniformly. Low means "a real loss of detection within the stated threat model, cheap to close".

## Findings

#### 1. The host-tool refusal hides concurrent boundary drift, and the `--bless` it recommends silently blesses that drift

**Severity:** Medium
**Location:** `devcontainer-config/cc-isolated.sh:661-667` (refusal), `:250-266` (`bless_manifest`), `:676` (bless dispatch), `:697` (`check_manifest` reached only after the refusal)
**Boundary:** B1, B3
**Move:** 3 (error path), 5 (invert: what does the new early exit prevent?)
**Confidence:** High (executed)
**Legibility-target:** the human reading the refusal (S6), who decides whether to run `--bless`

Evidence:
```bash
  if [ -n "$HOST_TOOLS_ERR" ] && [ "$action" != "bless" ] && [ "$action" != "list" ]; then
    echo "ERROR: $HOST_TOOLS_ERR — refusing to run the session-exit scan's code." >&2
    echo "  Review the host tools in $CC_ISOLATED_DIR (cc-exit-scan.sh, cc-gitdir.sh), then:" >&2
    echo "    cc-isolated --bless" >&2
    echo "  A host-tool change does not alter the blessed config: no rebuild or probe is needed." >&2
    exit 1
```
```bash
bless_manifest() {
  mkdir -p "$(config_dir)"
  compute_host_tools_manifest > "$(host_tools_path)"
  compute_manifest > "$(manifest_path)"
```

The refusal exits before `check_manifest`, so the diff that used to name every changed file is never printed. The message then sends the user to `--bless`, which rewrites **both** manifests. Probe P3 tampered `cc-exit-scan.sh` and appended `RUN echo evil` to the `Dockerfile`. The launch printed only the host-tool error and "no rebuild or probe is needed". Then `--bless` blessed the new Dockerfile hash (`Blessed config: 63fdd051…`) without printing a diff. At 4ab9a51f the same double tamper hit `check_manifest`, which printed a diff naming both files. A non-targeted tamperer that touches several files in the config dir now has its boundary change, the higher-consequence one, waved through by the advice that its host-tool change triggered. The next launch does rebuild and probe (the hash is unverified). But the probe tests firewall behaviour, not everything a Dockerfile can do, and the human review that B3 relies on never sees the file named. The fact-check flagged this at the wording level ("--bless also re-blesses pending boundary changes"). The security consequence is that the review step loses its input.

**Recommendation:** Before printing the refusal, run the boundary comparison too. Either call `check_manifest` without exiting, or diff `compute_manifest` against `manifest.sha256`. If the boundary also drifted, print that diff and drop the "no rebuild or probe" sentence. Alternatively, make `bless_manifest` print a diff against the previous manifest and host-tools file before writing. That also helps every other bless.

#### 2. A tampered cc-push.sh is no longer noticed by the launcher (detection regression; accepted in the plan, cheap to restore without blocking)

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:624` (launcher checks only two of the three host tools), `devcontainer-config/cc-push.sh:175-181` (self-check)
**Boundary:** B2
**Move:** 5 (what does the old design prevent that the new one does not?), 11
**Confidence:** High (executed)
**Legibility-target:** the user at the next launch

Evidence:
```bash
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
```
```bash
CC_PUSH_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
if ! host_tools_err="$(verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh)"; then
```

Probe P1 inserted `echo PWNED-cc-push >&2` at line 2 of the installed cc-push.sh. `cc-push --help` printed `PWNED-cc-push`, because a prepend runs before the self-check. In the same dir, the dce5b039 launcher left `HOST_TOOLS_ERR` empty and `check_manifest` passed. At 4ab9a51f the same tamper made `check_manifest` refuse ("installed config changed since last bless"). The self-check catches appends and edits after line ~176, because bash hashes the whole file before reading further. It cannot catch edits that run before the check or that remove it, and nothing else looks at the file any more. The plan (B1, "Partly covered") and row 71 ("A cc-push-only change no longer stops one") accept this on purpose. The stated motive was that a cc-push change should not *block launches*. That motive does not require *losing detection*.

**Recommendation:** In the launcher, hash all three `host_tool_files` and treat cc-push.sh differently. A cc-push.sh mismatch prints a loud WARNING ("cc-push.sh changed since the last bless; review it before pushing") and does not refuse. That keeps row 71's intent (no launch blocked by cc-push) and restores the old detection. It costs one extra file hashed per launch.

#### 3. The repo-checkout opt-out fails open on deleted manifests, including on the default install when the env var points elsewhere

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:227-230`, `devcontainer-config/cc-push.sh:149-152` (identical copies)
**Boundary:** B4
**Move:** 11 (bypass enumeration), 5 (default-allow)
**Confidence:** High (executed) on the mechanism, Medium on its marginal value
**Legibility-target:** maintainers relying on plan B4 "Covered" and row 71's "an installed copy cannot opt out by deleting it"

Evidence:
```bash
  cfg="$(readlink -f -- "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}" 2>/dev/null || true)"
  if [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
    return 0
  fi
```

The decision is default-allow. Any dir that is not the config dir *as named by the current environment* and has neither manifest is skipped. Fact-check 9b showed the custom-dir case. Probe P2 extends it to the **default** install. I deleted both manifests in `~/.config/claude-devcontainer`, appended `echo PWNED-gitdir` to its cc-gitdir.sh, and ran cc-push with `CLAUDE_DEVC_CONFIG_DIR=$E/elsewhere`. It printed `PWNED-gitdir`. With the var unset, the same dir refused correctly. So row 71's "cannot opt out by deleting it" holds only while the runtime env names the install dir. If `readlink -f` fails (missing parent dirs), `cfg` is empty and the third clause is always true. Marginal value: a targeted attacker who can delete two files can just edit cc-push.sh (finding 2) or set the env var from a shell rc, so this adds no capability for a targeted attacker. It matters only against non-targeted cleanup or deletion, which is unlikely. It is a correctness gap in a stated guarantee more than a new attack.

**Recommendation:** Either (a) flip the default so the skip needs a positive marker that is never installed. `install.sh` is not in PAYLOAD (`install.sh:110`), so `[ -f "$dir/install.sh" ]` marks a repo checkout. Skip only when that marker is present and both manifests are absent. Bats fixtures that copy the scripts without install.sh would need the marker or a manifest. Or (b) keep the code and correct plan B4 and row 71 to say the guarantee holds only when the runtime `CLAUDE_DEVC_CONFIG_DIR` (or the default) names the install dir. Prefer (a) if the test churn is small. An explicit marker is the right shape for an opt-out. Manifest presence is the wrong signal because deleting is as cheap as writing.

#### 4. Hardening and legibility notes

**Severity:** Informational
**Location:** `cc-isolated.sh:240-241` and `:626`, `cc-push.sh:170-181`, `cc-isolated.sh:250-253`, `cc-exit-scan.sh:3-5`, `cc-gitdir.sh:3-5`
**Boundary:** B1
**Move:** 4 (TOCTOU), 3
**Confidence:** Medium (read-static)
**Legibility-target:** future maintainers of verify_host_tools

- **TOCTOU (plan B7, accepted).** `have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"` reads the file once, and `source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` reads it again. cc-push.sh is the worse case: bash keeps reading the script from disk after the check, so a rewrite of later bytes after the hash executes. Closing it needs a copy: hash a private mktemp copy and source that. The entry point itself cannot be closed this way. Out of scope under row 45. Recorded so nobody describes the check as atomic.
- **The dir itself.** `dir` and `cfg` are both `readlink -f`-canonical, and the `-L` tests reject symlinked tool files and a symlinked manifest. A hardlinked tool file passes `-L`. That only matters together with the TOCTOU above. Directory trust reduces to "the PATH symlink points where you think" (plan B6, accepted).
- **Source of truth split.** verify reads `$dir/host-tools.sha256` and bless writes `$(config_dir)/host-tools.sha256`. Whenever these differ (custom install, var unset), the refusal's advice `cc-isolated --bless` writes to the wrong dir and cannot clear the error. That costs availability, not security, but it is the same case as finding 3.
- **Bless ordering.** `compute_host_tools_manifest >` runs before `compute_manifest >`. If the boundary compute fails (a missing enforcement file), the host tools are already re-blessed. This fails closed for launches (manifest.sha256 is truncated, so check_manifest refuses) but leaves cc-push trusting whatever was blessed. Compute both into temp files and move them into place only after both succeed.
- **Stale headers (fact-check claim 1).** `cc-exit-scan.sh:3-5` and `cc-gitdir.sh:3-5` still say `enforcement_files() hashes it into the trust manifest`. A reviewer trusting the header would assume the launch-time check from finding 2 still exists. Update both to name `host-tools.sha256`.

**Recommendation:** Fix the bless ordering (two-phase write) and the stale headers in this unit. Leave TOCTOU and hardlinks as documented non-goals.

## Untested bypass candidates (move #11)

Bypass candidates for `verify_host_tools`, with their disposition:

| # | Candidate | Disposition |
|---|---|---|
| 1 | Delete both manifests, custom install dir, var unset | **Tested** (fact-check P4/P7b): bypass, finding 3 |
| 2 | Delete both manifests, default install, var set elsewhere | **Tested** (P2): bypass, finding 3 |
| 3 | Delete only host-tools.sha256 | **Tested** (P2, var unset): refused |
| 4 | Prepend to cc-push.sh | **Tested** (P1): runs, not detected by launcher, finding 2 |
| 5 | Tamper scan + boundary file together | **Tested** (P3): boundary drift hidden then blessed, finding 1 |
| 6 | Rewrite host-tools.sha256 to match (plan B2) | Traced: passes by construction. Accepted threat model |
| 7 | Duplicate or `*`-prefixed manifest lines | Traced: the awk `n == 1` and exact `$2 == f` give empty `want`, so refused |
| 8 | Symlinked tool or manifest | Traced: `-L` refuses. Dir symlinks are canonicalised by `readlink -f` |
| 9 | **Untested:** swap the file between hash and source (TOCTOU), or a hardlink to a writable file | Not exercised. Needs a timed race. Accepted (plan B7), finding 4 |
| 10 | **Untested:** repoint the `~/.local/bin/cc-push` link to a dir with a self-consistent manifest (plan B6) | Not exercised. Accepted, and true before this diff |

Because of rows 9 and 10, plus the tested bypasses, `verify_host_tools` does not appear in Endorsement Claims as a guardrail.

## Endorsement Claims

- **Claim:** In the launcher, the host-tool check runs before `cc-exit-scan.sh` (and the `cc-gitdir.sh` it sources) is sourced, and on failure the scan is not sourced.
  **Location:** `devcontainer-config/cc-isolated.sh:622-629`
  **Evidence:** executed (fact-check P7/marker test; P3 here showed the refusal with the scan unsourced)
  **Verified:** the `if HOST_TOOLS_ERR=…; then source …; fi` structure, and P3's refusal output.
  **Not verified:** whether `list_projects` (`--list`, allowed through the refusal) reaches any scan-defined function on a path P3 did not run.
- **Claim:** cc-push's pre-check prologue (`set -euo pipefail`, `unset GIT_*`, `safe_path`) is plain code and does not source either host tool.
  **Location:** `devcontainer-config/cc-push.sh:112-135`
  **Evidence:** read-static (and fact-check "Verified")
  **Verified:** lines 112-181 read. The first `source` is line 181, after the check at 176.
  **Not verified:** what `safe_path` does with a PATH entry that resolves through a symlink into the checkout.
- **Claim:** A host-tool edit plus re-bless leaves `blessed_hash` and the verified-live receipt unchanged.
  **Location:** `devcontainer-config/cc-isolated.sh:128-137, 250-253`
  **Evidence:** executed (fact-check)
  **Verified:** fact-check probe. `enforcement_files` no longer lists the three tools.
  **Not verified:** the upgrade path from an install blessed by a pre-dce5b039 install.sh run by hand, other than the one case the fact-check ran.
  **route: code-fact-check**

## Primitive sweep

Primitive: `source` / script execution of host-tool files (exec sink)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-isolated.sh:626` `source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` | S1, S2 | `verify_host_tools … cc-exit-scan.sh cc-gitdir.sh` | Guarded. Bypass by finding 3. TOCTOU in finding 4 |
| `cc-exit-scan.sh:11` `source …/cc-gitdir.sh` | S1 | Transitively guarded: the launcher verified cc-gitdir.sh in the same canonical dir first | Cleared. Same dir, since `-L` refuses a symlinked scan |
| `cc-push.sh:181` `source "$CC_PUSH_DIR/cc-gitdir.sh"` | S1, S2 | `verify_host_tools … cc-push.sh cc-gitdir.sh` | Guarded. Bypass by finding 3 |
| `cc-push.sh` itself (executed via PATH link) | S1, S5 | Self-check at :176 | Partial. Prepend bypass in finding 2 (inherent to self-checks) |
| `cc-isolated.sh` itself | S1, S5 | `check_manifest` runs after top-level code | Not changed by this diff. Inherent, as before |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Host-tool refusal hides boundary drift; `--bless` blesses it unseen | Medium | B1, B3 | `cc-isolated.sh:661-667, 250-253` | High |
| 2 | Launcher no longer notices a tampered cc-push.sh | Low | B2 | `cc-isolated.sh:624`, `cc-push.sh:175-181` | High |
| 3 | Opt-out heuristic fails open on deleted manifests, incl. default dir with env var elsewhere | Low | B4 | `cc-isolated.sh:227-230`, `cc-push.sh:149-152` | High / Medium value |
| 4 | TOCTOU, bless ordering, dir-vs-config_dir split, stale headers | Informational | B1 | various | Medium |

## Overall Assessment

No finding gives a capability beyond what row 45's accepted threat model already concedes to a host-write attacker. The design shape is sound: a separate manifest, a check before `source`, a byte-identical copy pinned by a test, and fail-closed parsing. The issues can be fixed in place. Two are real regressions in **detection**, the thing this defence-in-depth control exists to provide. First, the new early refusal hides boundary drift from the human and then sends them to a bless that accepts it (finding 1). Second, a cc-push.sh tamper went from "blocks the next launch" to "never noticed" (finding 2). Both can be closed without undoing row 71's intent: print the boundary diff on refusal, and warn rather than refuse on cc-push drift. Finding 3 is a gap in a stated guarantee. Close it with an explicit "this is a repo checkout" marker (`install.sh` presence), or correct plan B4 and row 71. The single most important fix is finding 1. Endorsement claims are scoped with their `Not verified` hops named. No findings were found in the code paths read beyond those listed, and the one routed claim awaits execution verification.

## Goal-Alignment Note

The goal is to stop host-tool edits from changing the config hash or forcing a rebuild and probe, while keeping tamper detection for the host tools. The diff achieves the first part (fact-check verified that the hash and receipt are unchanged). On the second part it falls short in two places the plan only partly acknowledged. Detection of a cc-push.sh tamper was traded away, though the stated motive was only to stop it *blocking*. And the refusal path now hides boundary drift from the human, which works against row 45's purpose. Neither needs a redesign. Both fit inside this unit as small additions to the launcher's refusal and check path.
