Commit: 258f9ec4

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1)
**Scope:** Submitted claims only (security-reviewer endorsements 11-12), at HEAD 258f9ec4; no harvesting from the diff
**Checked:** 2026-10-15
**Total claims checked:** 2
**Summary:** 2 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read; neither claim matches a logged pattern.

Execution harness (shared by both claims): `/home/node/.claude/jobs/00bcf178/tmp/doc-drift/sc/run.sh`, run as `timeout 300 bash /home/node/.claude/jobs/00bcf178/tmp/doc-drift/sc/run.sh` from cwd `/home/node/.claude/jobs/00bcf178/tmp/doc-drift/sc` at 2026-10-15T07:53:43Z. It runs the worktree's real `devcontainer-config/cc-isolated.sh` with hermetic `HOME`, `CLAUDE_DEVC_CONFIG_DIR` (a blessed temp copy of `devcontainer-config/`) and a temp git repo. A PATH stub `devcontainer` (`sc/bin/devcontainer`) logs each call with the five `CC_*` variables it sees, exits 0 for `up`, 1 for every in-container probe `exec`, `$STUB_FW_RC` for `init-firewall.sh`, and logs `CLAUDE STARTED` for `exec … claude`. No docker or devcontainer ran, and `pgrep` found no leftover processes afterwards. Scenario exit codes: bless 0; A (`--probe-only`) 1; B (launch, init-firewall re-assert succeeds) 1; C (launch, init-firewall fails) 1; D (positive control: sourced, `probe_boundary` overridden to return 0) 0. Harness log: `sc/run.log`. Per-scenario call logs and outputs: `sc/{A_probe_only,B_launch_fw_ok,C_launch_fw_fail,D_control}.{calls,out}`.

---

## Submitted Claims

## Claim 11: "Both guides' recreate advice names the launcher path. That path exports CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR (and CC_CONFIG_HASH) before any `devcontainer up`, and its `--probe-only` branch recreates and then probes."

**Submitted by:** security-reviewer
**Location:** `guides/devcontainer-setup.md:397-398`, `guides/cc-isolated-usage.md:935`, `devcontainer-config/cc-isolated.sh:813-821`, `devcontainer-config/cc-isolated.sh:879-885`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three things: both guides name `cc-isolated --probe-only <repo>` then `cc-isolated <repo>`; all five variables are exported, and seen by the stub, before every `devcontainer up` call on the probe and launch paths; and `--probe-only` runs an unconditional `up --remove-existing-container` and then `probe_boundary`. Does not establish four things: that devcontainer.json consumes each variable correctly in a real build (no docker ran); behaviour of the hand-run fallback that `rebuild_hint` prints; that `CC_EGRESS_PROFILE` is non-empty (for an unregistered project it is exported as the empty string, which means base-only); or the bless/list/register actions, which never call `up`.

Guides. `guides/devcontainer-setup.md:397-399` says: "To recreate a container by hand, use the launcher: `cc-isolated --probe-only <repo>` (always recreates it from the blessed config and re-probes), then `cc-isolated <repo>`. Not a bare `devcontainer up --remove-existing-container …`" (excerpt ends :399; paragraph continues to the list of effects — read). `guides/cc-isolated-usage.md:935`, row `PROBE FAIL (firewall)`, says: "recreate it from the host with the launcher: `cc-isolated --probe-only <repo>` (recreates the container from the blessed config and re-probes), then `cc-isolated <repo>`." Both name the launcher.

Exports. The four variables are assigned and exported before the first `up`:

```bash
# devcontainer-config/cc-isolated.sh:813-821
  CC_PROJECT_ID="$pid"
  CC_PROJECT_NAME="$(basename "$ws")"
  CC_EGRESS_PROFILE="$eff_profile"
  ...
  CC_CONFIG_DIR="$(config_dir)"
  export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR
```

`CC_CONFIG_HASH` follows at `cc-isolated.sh:831-832` (`CC_CONFIG_HASH="$(blessed_hash)"` / `export CC_CONFIG_HASH`). The only `devcontainer up` calls in the file are at `:883`, `:888` and `:895`, all later (paraphrased, no quote available because the claim is about where code is absent: `grep -n 'devcontainer up'` matches only those three lines plus comments and the `rebuild_hint` echo at `:566`). In execution, every `up` call the stub logged in scenarios A, B and C carried all five values, for example `CALL up --remove-existing-container | CC_PROJECT_ID=b534d90f0706 CC_PROJECT_NAME=repo CC_EGRESS_PROFILE= CC_CONFIG_DIR=…/sc/t/cfg CC_CONFIG_HASH=b5bbeeb7a41c7fbd` (A_probe_only.calls).

Probe branch:

```bash
# devcontainer-config/cc-isolated.sh:880-885
  if [ "$action" = "probe" ]; then
    ...
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
  fi
```

`--probe-only` sets `action="probe"` (`cc-isolated.sh:735`). In scenario A the stub logged exactly one `up --remove-existing-container`, then the seven probe `exec` calls in order (H1, egress, workspace, H6, provenance, config hash, firewall marker). So the branch recreates first and probes second, and the recreate does not depend on `container_config_matches`.

**Evidence:** `guides/devcontainer-setup.md:397-399`, `guides/cc-isolated-usage.md:935`, `devcontainer-config/cc-isolated.sh:735`, `devcontainer-config/cc-isolated.sh:813-832`, `devcontainer-config/cc-isolated.sh:879-896`, /home/node/.claude/jobs/00bcf178/tmp/doc-drift/sc/run.log, /home/node/.claude/jobs/00bcf178/tmp/doc-drift/sc/A_probe_only.calls, /home/node/.claude/jobs/00bcf178/tmp/doc-drift/sc/B_launch_fw_ok.calls

---

## Claim 12: "`--probe-only` cannot report success after a failed probe, and `cc-isolated <repo>` cannot start claude after a failed re-probe, because the script runs under `set -euo pipefail` (cc-isolated.sh:66, :883-884, :918, :927)."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-isolated.sh:883-884`, `devcontainer-config/cc-isolated.sh:918`, `devcontainer-config/cc-isolated.sh:927`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script run as a command, where the guard at `:941-943` calls `main "$@"` outside any conditional context. On that path a failed `probe_boundary` at `:884` or `:918` aborts with a non-zero status before `exit 0` or the `claude` exec, no "passed" line is printed, and no verified-live receipt is written. The separate init-firewall-failure path (`:911-916`) also stops before claude, but through an explicit `return 1`, not errexit. Does not establish three things: behaviour when a caller sources the file and runs `main` inside `if`/`||`, where bash suspends errexit inside the function; that every probe check detects a real-container failure (the probe's own sensitivity is a separate question); or the exit-scan path after claude.

Mechanism. `cc-isolated.sh:66` reads `set -euo pipefail`. On the probe path, `probe_boundary "$ws"` at `:884` is a bare command, so errexit fires on its non-zero return before `exit 0` at `:885`. `probe_boundary` returns 1 whenever any check failed:

```bash
# devcontainer-config/cc-isolated.sh:701-708
  if [ "$failures" -gt 0 ]; then
    echo "Boundary self-probe FAILED ($failures) — not starting Claude Code." >&2
    return 1
  fi
  record_verified_live
  echo "Boundary self-probe passed (...)."
  echo "Recorded config $want_hash as verified live in $(verified_path)."
}
```

On the launch path, the first probe sits in `if ! probe_boundary "$ws"; then` at `:901`, where a failure is intended and handled. The re-probe `probe_boundary "$ws"` at `:918` is bare, so its failure aborts before `devcontainer exec "${dc[@]}" claude || rc=$?` at `:927`. When the init-firewall re-assert fails instead, `:911-916` print an error and `return 1` before claude. `main` is called plainly: `if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi` (`cc-isolated.sh:942-944`).

Execution:
- **A (`--probe-only`, probe fails):** rc=1. Output has `Boundary self-probe FAILED (7) — not starting Claude Code.` and no "passed" line. `sc/t/cfg/verified-live.sha256` does not exist afterwards.
- **B (launch, first probe fails, re-assert succeeds, re-probe fails):** rc=1. FAILED is printed twice, the stub logged the `sudo /usr/local/bin/init-firewall.sh` exec, and `grep -c 'CLAUDE STARTED'` is 0.
- **C (launch, re-assert fails):** rc=1, `ERROR: init-firewall.sh failed…`, no claude.
- **D (positive control, `probe_boundary` stubbed to pass):** rc=0 and `CLAUDE STARTED` is logged. This shows the harness can reach claude, so B's absence of claude comes from the probe failure.

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-isolated.sh:577-708`, `devcontainer-config/cc-isolated.sh:880-927`, `devcontainer-config/cc-isolated.sh:941-944`, /home/node/.claude/jobs/00bcf178/tmp/doc-drift/sc/run.log, /home/node/.claude/jobs/00bcf178/tmp/doc-drift/sc/A_probe_only.out, /home/node/.claude/jobs/00bcf178/tmp/doc-drift/sc/B_launch_fw_ok.calls, /home/node/.claude/jobs/00bcf178/tmp/doc-drift/sc/C_launch_fw_fail.out, /home/node/.claude/jobs/00bcf178/tmp/doc-drift/sc/D_control.calls

---

## Claims Requiring Attention

None. Both submitted claims are Verified within their scopes. Residues worth knowing:
- Claim 11: an unregistered project exports `CC_EGRESS_PROFILE` as the empty string.
- Claim 12: the init-firewall-failure stop at `:916` is an explicit `return 1`, not errexit.
- Claim 12: the guarantee holds only when the script is run, not when it is sourced and `main` is called in a conditional context.

## Goal-Alignment Note
- Success criterion (restated verbatim): A submitted-claims fact-check report saved to the given path.
- Answered: Claims 11 and 12 were verdicted (both Verified, both executed) against the real worktree `cc-isolated.sh` at 258f9ec4, using a hermetic stub-`devcontainer` harness with a positive control. The report is saved at the given path with `Commit: 258f9ec4` as its first line.
- Out of scope: Whether the probe detects real-container failures; real devcontainer.json variable consumption; `rebuild_hint`'s hand-run fallback (A4/C3/C4 deferrals); harvesting new claims from the diff.
- Escalate: Nothing.
