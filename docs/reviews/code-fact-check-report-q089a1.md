# Code Fact-Check Report

**Commit:** f2533b33
**Replication:** k=1 (loop pass, decision 031)
**Repository:** /workspace (worktree /workspace/.claude/wt-q089)
**Scope:** `git diff 4ab9a51f f2533b33` (branch feat/q089a1-host-tool-manifest, Q-089 unit A1): `devcontainer-config/{cc-exit-scan.sh,cc-gitdir.sh,cc-isolated.sh,install.sh}`, `test/cc-isolated-functions.bats`, and commit f2533b33's message. Files read as of f2533b33. Sibling context consulted, not reviewed: A2 (840f39b0), unit B (feat/q089b-host-tool-gate, 6e00137b), prior branch feat/q089-host-tool-trust (548fe6f9) and its rubric.
**Checked:** 2026-10-14
**Total claims checked:** 28
**Summary:** 21 verified, 7 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The relevant prior pattern is the commit-message test tally (for example "All 85 tests ... pass" when the suites held 97). Claim 19 is checked against it and does not match it: the tally is correct.

Execution environment: probe root `/home/node/.claude/jobs/00bcf178/tmp/fc-a1.D6wSfK`, with `src/` = `git archive f2533b33`. HOME, TMPDIR and CLAUDE_DEVC_CONFIG_DIR all point under the probe root, with `LC_ALL=C`, every command under `timeout`, and a stub `devcontainer` (exit 0) on PATH. Logs are in `docs/reviews/execution-logs/fc-q089a1/`, and `suites.txt` records commands, cwd, exit codes and timestamps for the suite runs. No processes were left running afterwards (checked with `ps`).

---

## Claim 1: "it is a host tool (decision log row 71), so the bless hashes it into host-tools.sha256, not the boundary manifest, and cc-isolated.sh checks it against that file before sourcing it"

**Location:** `devcontainer-config/cc-exit-scan.sh:4-6`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hashing destination and the launcher's check-before-source of cc-exit-scan.sh. Does not establish that decision log row 71 exists at f2533b33: it lands in unit B, see Claim 20.

The file is in `host_tool_files` and no longer in `enforcement_files` (`devcontainer-config/cc-isolated.sh:199-203`: `echo "cc-exit-scan.sh"` / `echo "cc-gitdir.sh"` / `echo "cc-push.sh"`). The source line is guarded:

```bash
# devcontainer-config/cc-isolated.sh:695-702
CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
HOST_TOOLS_ERR=""
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
  # shellcheck source=cc-exit-scan.sh
  source "$CC_ISOLATED_DIR/cc-exit-scan.sh"
else
  HOST_TOOLS_ERR="${HOST_TOOLS_ERR:-host-tool check failed}"
fi
```

Executed: probe P3 shows the A1 manifest with 0 host-tool entries, against 3 at base. The test at `test/cc-isolated-functions.bats:928` passes: a `touch` appended to the scan never runs on a refused launch. Row 71 is absent from `docs/decisions/log.md` at f2533b33, where the last row is 70. It is present on unit B (`feat/q089b-host-tool-gate:docs/decisions/log.md:94`).

**Evidence:** `devcontainer-config/cc-isolated.sh:199-203`, `devcontainer-config/cc-isolated.sh:695-702`, `test/cc-isolated-functions.bats:928-953`, docs/reviews/execution-logs/fc-q089a1/probe.out, docs/reviews/execution-logs/fc-q089a1/cc-isolated-functions.log

---

## Claim 2: "hashed into host-tools.sha256. Both entry points check it against that file before it is sourced: cc-push for itself, the launcher for cc-exit-scan.sh."

**Location:** `devcontainer-config/cc-gitdir.sh:4-6`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the A1 launcher half and the A2 cc-push half (840f39b0). Does not hold at f2533b33 alone, where `cc-push.sh:139-140` still sources cc-gitdir.sh unchecked.

Launcher half: the launcher checks `cc-exit-scan.sh cc-gitdir.sh` (`cc-isolated.sh:697`) before sourcing the scan. The scan then sources cc-gitdir.sh from its own resolved dir (`cc-exit-scan.sh:12`: `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"`). That is the same dir, because verify_host_tools refuses a symlinked tool. cc-push half: at f2533b33 cc-push has no check (`cc-push.sh:140`: `source "$(dirname -- ...)/cc-gitdir.sh"`). A2 adds `if ! host_tools_err="$(verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh)"` at `840f39b0:devcontainer-config/cc-push.sh:188`, before `source "$CC_PUSH_DIR/cc-gitdir.sh"` at `:193`.

**Evidence:** `devcontainer-config/cc-isolated.sh:697`, `devcontainer-config/cc-exit-scan.sh:12`, `devcontainer-config/cc-push.sh:139-140`, 840f39b0 `devcontainer-config/cc-push.sh:188-193`

---

## Claim 3: "a bats test now pins PAYLOAD ⊆ this list ∪ host_tool_files, the two disjoint"

**Location:** `devcontainer-config/cc-isolated.sh:120-121`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the subset check, the disjointness check, the exact three-item host list and the no-COPY-of-a-host-tool check. Does not establish anything about directories (egress, claude-home), which the test skips by design.

```bash
# test/cc-isolated-functions.bats:849-861 (excerpt; enclosing @test continues to :866 — read)
  [ "$host" = $'cc-exit-scan.sh\ncc-gitdir.sh\ncc-push.sh' ]
  for item in $host; do
    if echo "$enf" | grep -qx "$item"; then echo "in both lists: $item"; return 1; fi
  done
  ...
    printf '%s\n%s\n' "$enf" "$host" | grep -qx "$item" || { echo "PAYLOAD item not hashed: $item"; return 1; }
```

The PAYLOAD at `install.sh:110` lists all three host tools, and the Dockerfile COPY sources (`Dockerfile:486-500`) are egress/, init-firewall.sh, cc-sni-proxy.py, link-claude-home.sh and claude-home/, so none of them is a host tool. The test passes (it is in the 180/180 run).

**Evidence:** `test/cc-isolated-functions.bats:835-866`, `devcontainer-config/install.sh:110`, `devcontainer-config/Dockerfile:486-500`, docs/reviews/execution-logs/fc-q089a1/cc-isolated-functions.log

---

## Claim 4a: "They run on the host, after or outside the container, so no live probe can exercise them and the image never copies them"

**Location:** `devcontainer-config/cc-isolated.sh:191-193`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Dockerfile COPY list and the host-side call sites. Does not establish what other host processes might run these files.

No Dockerfile `COPY` line names a host tool (`Dockerfile:486`: `COPY egress/ /usr/local/share/cc-egress/` ... `:500`: `COPY claude-home/ /opt/claude-workflows/`). The scan is sourced by the host launcher (`cc-isolated.sh:699`), and cc-push is a separate host command linked by install.sh (`install.sh:603`: `ln -sf "$DEST/cc-push.sh" "$BIN_DIR/cc-push"`).

**Evidence:** `devcontainer-config/Dockerfile:486-500`, `devcontainer-config/cc-isolated.sh:699`, `devcontainer-config/install.sh:603`

---

## Claim 4b: "so a change to one leaves blessed_hash (the baked config identity), the verified-live receipt and the container alone"

**Location:** `devcontainer-config/cc-isolated.sh:194-195`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers blessed_hash and is_verified_live across a host-tool edit plus re-bless. Does not establish anything about a live container: no Docker in the sandbox.

`blessed_hash` hashes only `manifest.sha256` (`cc-isolated.sh:88-93`: `sha256sum < "$m" | cut -c1-16`), and `is_verified_live` compares the receipt to it (`:103-108`). Executed: in probe P3, `Blessed config: de595abc22a2e5d5` held across an edit of cc-push.sh followed by `--bless`, while the bless reported `Changed since the last bless (host-tools.sha256)`. The test at `:869` asserts `[ "$(blessed_hash)" = "$before" ]` and passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:88-108`, `test/cc-isolated-functions.bats:869-884`, docs/reviews/execution-logs/fc-q089a1/probe.out (P3)

---

## Claim 4c: "Commits that change them carry `Host-tool-tested:`, not `Live-verified:` (hooks/live-verify-gate.sh)."

**Location:** `devcontainer-config/cc-isolated.sh:197-198`
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gate as unit B ships it. Does not hold at f2533b33 or at A1+A2, where the gate still demands `Live-verified:` for all three host tools.

At f2533b33 the gate's enforcement regex still contains the host tools:

```bash
# hooks/live-verify-gate.sh:73 (at f2533b33)
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh|install\.sh$|egress/)'
```

Unit B removes them and adds `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)$'` (`feat/q089b-host-tool-gate:hooks/live-verify-gate.sh:73,78`). The precise wording would make the comment conditional on unit B, or the claim lands with B. Commit f2533b33 carries both trailers, so A1 itself passes either gate. The gate's own comment at `:70-71` ("what cc-isolated.sh's enforcement_files() hashes ... Keep in step with that function") is out of scope, but A1 makes it untrue until B lands.

**Evidence:** f2533b33 `hooks/live-verify-gate.sh:70-73`, 6e00137b `hooks/live-verify-gate.sh:73-78`

---

## Claim 5a: "KEEP IN STEP with the copy in cc-push.sh (a test compares the two byte for byte)"

**Location:** `devcontainer-config/cc-isolated.sh:219-220`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the copy and the parity test in A2 (840f39b0). Does not hold at f2533b33 alone, where neither exists, as the commit's Notes disclose. Does not establish that the parity test passes; A2's report covers that.

At 840f39b0, `devcontainer-config/cc-push.sh:142` reads `# --- verify_host_tools: KEEP IN STEP with the copy in cc-isolated.sh (a test`, and `test/cc-isolated-functions.bats:928` reads `@test "verify_host_tools is the same code in cc-isolated.sh and cc-push.sh"`.

**Evidence:** 840f39b0 `devcontainer-config/cc-push.sh:142-182`, 840f39b0 `test/cc-isolated-functions.bats:928`

---

## Claim 5b: "Only a repo checkout is left unchecked, and it must say so positively: install.sh beside the script (install.sh is never installed, it is not in PAYLOAD), no manifest of either kind, and not the config dir. Anything else is checked, so deleting manifests is not enough to opt an installed copy out."

**Location:** `devcontainer-config/cc-isolated.sh:224-228`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four-part test, install.sh's absence from PAYLOAD and from the installed dir, and the test's opt-out cases. Does not establish resistance to an attacker who also plants an install.sh, which is outside the stated threat model (non-targeted tampering).

```bash
# devcontainer-config/cc-isolated.sh:233-235
  if [ -f "$dir/install.sh" ] && [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
    return 0
  fi
```

`install.sh:110`'s PAYLOAD has no install.sh, and install_devcontainer copies only `for item in "${PAYLOAD[@]}"` (`install.sh:579`). The test at `:886` covers each case: no manifest is refused, install.sh alone is unchecked, install.sh plus a manifest is refused, and the config dir is refused. It passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:229-258`, `devcontainer-config/install.sh:110`, `devcontainer-config/install.sh:579-580`, `test/cc-isolated-functions.bats:886-926`, docs/reviews/execution-logs/fc-q089a1/cc-isolated-functions.log

---

## Claim 5c: "DIR is the script's own resolved directory."

**Location:** `devcontainer-config/cc-isolated.sh:223-224`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the launcher's two call sites in main and at source time. Does not cover `--list`, which passes a different directory.

The launcher passes `"$CC_ISOLATED_DIR"` (`:697`, `:743`, `:756`). `list_projects` passes the resolved config dir instead: `lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true` (`:488`), where `cfg_real="$(readlink -f -- "$(config_dir)")"` (`:487`). The precise version: "DIR is the resolved directory to check: the entry point's own, or config_dir() for --list."

**Evidence:** `devcontainer-config/cc-isolated.sh:487-489`, `devcontainer-config/cc-isolated.sh:697`, `devcontainer-config/cc-isolated.sh:743`, `devcontainer-config/cc-isolated.sh:756`

---

## Claim 5d: "Prints the reason and returns 1 on any mismatch." / "Every file is checked and every mismatch named, so the refusal lists all of what the bless it points to would accept."

**Location:** `devcontainer-config/cc-isolated.sh:228`, `devcontainer-config/cc-isolated.sh:241-242`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers missing, symlinked, unlisted, duplicated and changed files across all arguments. Does not establish that the refusal names boundary-manifest changes; Claim 11 covers that.

```bash
# devcontainer-config/cc-isolated.sh:243-257 (excerpt; verify_host_tools ends :258 — read)
  for f in "$@"; do
    if [ ! -f "$dir/$f" ] || [ -L "$dir/$f" ]; then
      echo "$dir/$f is missing or a symlink"
      bad=1
      continue
    fi
    want="$(awk -v f="$f" '$2 == f { n++; h = $1 } END { if (n == 1) print h }' "$m")"
    ...
  done
  return "$bad"
```

The loop does not stop at the first mismatch. Executed: the test at `:955` asserts `*"cc-exit-scan.sh changed"*"cc-gitdir.sh changed"*` plus the cc-push line, and it passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:229-258`, `test/cc-isolated-functions.bats:955-984`, docs/reviews/execution-logs/fc-q089a1/cc-isolated-functions.log

---

## Claim 6: "Both manifests are computed into temp files first and moved into place only when both succeed, so a bless that fails to compute either changes neither. The two same-directory renames can still split ...: host-tools.sha256 is then new and manifest.sha256 old ... What changed since the previous bless is printed first"

**Location:** `devcontainer-config/cc-isolated.sh:261-268`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers compute failures of either manifest, temp-file cleanup, rename order and diff-before-move. Does not establish behavior on an interrupt between the renames, which was read statically only.

```bash
# devcontainer-config/cc-isolated.sh:274-292 (excerpt; bless_manifest continues to :307 — read)
  if ! compute_manifest > "$new_m" || ! compute_host_tools_manifest > "$new_h"; then
    rm -f "$new_m" "$new_h"
    echo "ERROR: nothing blessed." >&2
    return 1
  fi
  ...
  mv -f "$new_h" "$(host_tools_path)"
  mv -f "$new_m" "$(manifest_path)"
```

The rename order matches the stated split (host tools first). The diff loop (`:281-290`) runs before both `mv` calls. Executed: probe P4 changed the Dockerfile and removed cc-gitdir.sh, then ran `--bless`. It got rc=1 with `ERROR: host tool missing: cc-gitdir.sh` and `ERROR: nothing blessed.`, and reported "manifest unchanged", "host-tools unchanged" and "no temp files".

**Evidence:** `devcontainer-config/cc-isolated.sh:261-307`, `test/cc-isolated-functions.bats:994-1013`, docs/reviews/execution-logs/fc-q089a1/probe.out (P4)

---

## Claim 7: "names CLAUDE_DEVC_CONFIG_DIR when it is set, so a hint printed for a non-default dir does not bless the default one"

**Location:** `devcontainer-config/cc-isolated.sh:309-310`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers bless_cmd and its two callers in check_manifest. Does not cover the other bless hints, which do not use bless_cmd: `--list`'s `cc-isolated --bless` at `:493` and verify_host_tools' `cc-isolated --bless after reviewing` at `:237`.

```bash
# devcontainer-config/cc-isolated.sh:311-317
bless_cmd() {
  if [ -n "${CLAUDE_DEVC_CONFIG_DIR:-}" ]; then
    printf 'CLAUDE_DEVC_CONFIG_DIR=%q %s --bless' "$CLAUDE_DEVC_CONFIG_DIR" "$0"
  else
    printf '%s --bless' "$0"
  fi
}
```

It is used at `:325` and `:334`. Probe P5 shows `--list` under a custom dir printing the bare `Host tools: CHANGED (review, then: cc-isolated --bless)`. That hint is outside this claim, but it is the nearest place where a reader would assume the same guarantee holds.

**Evidence:** `devcontainer-config/cc-isolated.sh:311-337`, `devcontainer-config/cc-isolated.sh:493`, docs/reviews/execution-logs/fc-q089a1/probe.out (P5)

---

## Claim 8a: "the launcher refuses on the two files it executes (and only warns on cc-push); cc-push refuses on itself and cc-gitdir.sh"

**Location:** `devcontainer-config/cc-isolated.sh:480-482`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher's file lists (A1) and cc-push's file list (A2 at 840f39b0:188). Does not hold for cc-push at f2533b33 alone.

The launcher refuses on `cc-exit-scan.sh cc-gitdir.sh` (`:697`, `:734`) and warns on `cc-push.sh` (`:755-758`). A2 checks `cc-push.sh cc-gitdir.sh` (840f39b0 `cc-push.sh:188`). Executed: the test at `:1015` asserts "launches warn (cc-push changed) but run" for a cc-push-only edit, and "launches refuse" without "cc-push refuses" for a scan-only edit. It passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:480-500`, `devcontainer-config/cc-isolated.sh:734-758`, 840f39b0 `devcontainer-config/cc-push.sh:188`, `test/cc-isolated-functions.bats:1015-1036`

---

## Claim 8b: "Checked in config_dir(); an entry point checks its own dir, which differs only for a custom install run without CLAUDE_DEVC_CONFIG_DIR."

**Location:** `devcontainer-config/cc-isolated.sh:482-483`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the installed-launcher cases. Does not cover a launcher run from a repo checkout, or CLAUDE_DEVC_CONFIG_DIR naming a dir other than the one the launcher lives in. In both, the dirs differ, and `--list`'s "launches refuse" does not describe what that launcher does.

`--list` checks `cfg_real` (`:487-489`), while the launcher checks `CC_ISOLATED_DIR` (`:695`). Executed (probe2): the repo-checkout launcher (`$P/src/devcontainer-config/cc-isolated.sh`) was run with `CLAUDE_DEVC_CONFIG_DIR` pointing at an installed dir with a tampered cc-gitdir.sh. `--list` printed `launches refuse: .../p5/cfg/cc-gitdir.sh changed since the last bless`. A launch from the same launcher printed no host-tool refusal (`grep -c 'refusing to run the session-exit scan'` → 0) and went on to the verified-live NOTE. The test at `:986` exercises the same mismatch: a repo launcher, with the env pointing at a missing dir, reports "launches refuse". The precise version: "...which differs for a custom install run without CLAUDE_DEVC_CONFIG_DIR, or when the variable names a dir the running launcher does not live in (e.g. a repo checkout)."

**Evidence:** `devcontainer-config/cc-isolated.sh:482-489`, `devcontainer-config/cc-isolated.sh:695`, `test/cc-isolated-functions.bats:986-992`, docs/reviews/execution-logs/fc-q089a1/probe2.sh, docs/reviews/execution-logs/fc-q089a1/probe2.out, docs/reviews/execution-logs/fc-q089a1/probe2.ts, docs/reviews/execution-logs/fc-q089a1/probe2.rc

---

## Claim 8c: "Not a bare assignment: readlink -f fails when the dir's parent is missing, and under set -e that would end --list silently."

**Location:** `devcontainer-config/cc-isolated.sh:485-487`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing-parent case and the test that guards it. Does not establish other readlink failure modes.

`cfg_real="$(readlink -f -- "$(config_dir)")" || cfg_real="$(config_dir)"` (`:487`). Executed mutation (`mut.sh`): dropping the `|| cfg_real=...` fallback makes the test at `:986` fail (`not ok 1 ... [ "$status" -eq 0 ]' failed`, mutant rc=1). The unmutated copy passes (rc=0).

**Evidence:** `devcontainer-config/cc-isolated.sh:487`, `test/cc-isolated-functions.bats:986-992`, docs/reviews/execution-logs/fc-q089a1/mut.sh, docs/reviews/execution-logs/fc-q089a1/mut.out, docs/reviews/execution-logs/fc-q089a1/mut.ts, docs/reviews/execution-logs/fc-q089a1/mut.rc

---

## Claim 9: "When the check fails the scan is not loaded, and main refuses everything but --bless and --list."

**Location:** `devcontainer-config/cc-isolated.sh:692-694`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "scan not loaded" and the refusal of launch, --probe-only and --register. Does not cover --help/-h and argument errors, which exit (0 or 2) during parsing, before the refusal.

The refusal test sits after the argument loop (`:734`), and the loop exits early on `--help|-h)    usage; exit 0 ;;` (`:727`) and on unknown flags (`exit 2`, `:729`). Executed (probe P1, with a tampered cc-exit-scan.sh): `--help rc=0`, while `--register` printed the refusal and returned rc=1. Neither path sources the scan, so the safety property holds. The precise version: "...refuses everything but --bless, --list and --help." Matches the prior branch's rubric C4 ("`--help` is also answered"), still open.

**Evidence:** `devcontainer-config/cc-isolated.sh:692-702`, `devcontainer-config/cc-isolated.sh:710-749`, docs/reviews/execution-logs/fc-q089a1/probe.out (P1), docs/reviews/execution-logs/fc-q089a1/probe.sh

---

## Claim 10: "The boundary config is unchanged: after the re-bless, no rebuild or probe is needed."

**Location:** `devcontainer-config/cc-isolated.sh:738`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message's condition (check_manifest passed) and blessed_hash staying put across the re-bless. Does not hold as stated when the blessed config was never verified live: the next launch then still rebuilds and probes.

The re-bless adds no rebuild (Claim 4b). But main still runs the unverified path whenever `! is_verified_live`:

```bash
# devcontainer-config/cc-isolated.sh:851-856 (excerpt; main continues past :868 — read to the devcontainer up / probe calls)
  if ! is_verified_live; then
    echo "NOTE: blessed config $CC_CONFIG_HASH has NOT been verified in a live container."
    echo "      This run is that verification: the container is rebuilt from it, and the"
```

Executed (probe P2): with host-tools.sha256 deleted and the boundary unchanged, the refusal printed "The boundary config is unchanged: after the re-bless, no rebuild or probe is needed." on a config that had never been probed (P1 to P7 never record a receipt). The precise version: "...the re-bless adds no rebuild or probe."

**Evidence:** `devcontainer-config/cc-isolated.sh:734-749`, `devcontainer-config/cc-isolated.sh:851-868`, docs/reviews/execution-logs/fc-q089a1/probe.out (P2)

---

## Claim 11: "Never let this refusal hide a boundary change: run the boundary check too, and show its diff" / "The BOUNDARY config changed too (above). ... the re-bless accepts both, and the next launch then rebuilds and probes."

**Location:** `devcontainer-config/cc-isolated.sh:736-741`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_manifest running against the launcher's own dir (via a temporary function-prefix assignment) and its diff reaching stderr. Does not establish the wording when manifest.sha256 itself is missing, where "(above)" points at "no blessed manifest" rather than at a diff.

`if ! CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" check_manifest; then` (`:739`). check_manifest prints `diff <(echo "$expected") <(echo "$actual") >&2` (`:335`). A blessed_hash change makes `is_verified_live` false, so the next launch takes the rebuild-and-probe path (`:851`). Executed: the test at `:955` asserts "installed config changed since last bless", "init-firewall.sh", "BOUNDARY config changed too", and the absence of "no rebuild or probe is needed". It passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:320-338`, `devcontainer-config/cc-isolated.sh:736-741`, `test/cc-isolated-functions.bats:955-972`

---

## Claim 12: "Also changed (cc-push refuses until re-blessed): $push_err"

**Location:** `devcontainer-config/cc-isolated.sh:744`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the launcher printing every cc-push mismatch, and cc-push refusing once A2 lands. Does not hold at f2533b33 alone (cc-push has no check there). The "Also changed" label is also printed when the cause is a missing host-tools.sha256 rather than a change.

The launcher side was executed: the test at `:955` asserts `*"Also changed (cc-push refuses until re-blessed)"*"cc-push.sh changed"*` and passes. Probe P2 printed `Also changed (cc-push refuses until re-blessed): no host-tool manifest at ...`. cc-push refusing is A2's behavior (840f39b0 `cc-push.sh:188`) and was read statically here. Confidence is Medium because that half was not run in this pass.

**Evidence:** `devcontainer-config/cc-isolated.sh:742-745`, 840f39b0 `devcontainer-config/cc-push.sh:186-191`, docs/reviews/execution-logs/fc-q089a1/probe.out (P2)

---

## Claim 13: "cc-push is not executed by the launcher, so a change to it never blocks a launch, but the launcher still says so: cc-push's self-check cannot catch a tampered cc-push that skips it."

**Location:** `devcontainer-config/cc-isolated.sh:751-753`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absence of any cc-push execution in cc-isolated.sh or cc-exit-scan.sh, and the warning-only path. Does not establish user behavior on seeing the warning.

Every cc-push reference in `cc-isolated.sh` and `cc-exit-scan.sh` is a comment, a hash argument or an echoed hint (for example `cc-exit-scan.sh:995`: `echo "  and pushes from there:  cc-push $ws"`). There is no invocation (paraphrased — no quote available because the claim covers the absence of code; grep `cc-push` over both files returns only comments, echo strings and `verify_host_tools` arguments). The warn path is `echo "WARNING: $push_err — do not run cc-push ..."` (`:757`) with no exit. The test at `:1015` asserts the WARNING and the absence of the refusal text, and passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:751-758`, `devcontainer-config/cc-exit-scan.sh:994-1056`, `test/cc-isolated-functions.bats:1027-1030`

---

## Claim 14: "The bless hashes it into host-tools.sha256 (a host tool, decision log row 71), which cc-push checks before sourcing cc-gitdir.sh."

**Location:** `devcontainer-config/install.sh:601-602`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers install.sh's bless call writing host-tools.sha256 (A1) and cc-push's check-before-source (A2). Does not hold for cc-push at f2533b33 alone, and row 71 lands with unit B.

install.sh blesses through the launcher: `CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless` (`install.sh:607`), and the launcher's bless writes host-tools.sha256 (`cc-isolated.sh:291`). In A2, cc-push's check (840f39b0 `cc-push.sh:188`) precedes `source "$CC_PUSH_DIR/cc-gitdir.sh"` (`:193`).

**Evidence:** `devcontainer-config/install.sh:601-607`, `devcontainer-config/cc-isolated.sh:291`, 840f39b0 `devcontainer-config/cc-push.sh:188-193`

---

## Claim 15: Test names in `test/cc-isolated-functions.bats` match their assertions: ":835 every regular file in install.sh's PAYLOAD is hashed by enforcement_files or host_tool_files", ":869 bless writes host-tools.sha256; a host-tool edit leaves the boundary manifest and blessed hash alone", ":886 verify_host_tools: repo checkout unchecked; an installed dir must match, and cannot opt out", ":928 launch: a tampered cc-exit-scan.sh is never sourced; --bless still works and clears it", ":955 launch: a host-tool refusal still shows a boundary change made alongside it, and bless prints both", ":986 --list still reports everything when the config dir's parent is missing (set -e)", ":1015 --list reports host-tool state; a changed cc-push warns at launch but does not refuse"

**Location:** `test/cc-isolated-functions.bats:835-1036`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its assertions, and that all seven pass. Does not establish that ":1015 ... does not refuse" checks the exit status: it asserts only the absence of the refusal text, and under the stub the launch exits through later code.

Each name's property is asserted directly. For example, `:928` asserts `[ ! -e "$mark" ]` after the refused launch, after `--list` and after `--bless`, then `[ -e "$mark" ]` after the clean launch. `:986` is mutation-killed (Claim 8c). `:1015` asserts `[[ "$output" != *"refusing to run the session-exit scan"* ]]` (`:1030`). All pass in the 180/180 run.

**Evidence:** `test/cc-isolated-functions.bats:835-1036`, docs/reviews/execution-logs/fc-q089a1/cc-isolated-functions.log

---

## Claim 16: "bless: a failure changes neither manifest"

**Location:** `test/cc-isolated-functions.bats:994`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both failure cases' exit status, the first case's two manifests, and temp-file cleanup. Does not establish, from this test, that manifest.sha256 is untouched in the second (missing host tool) case.

```bash
# test/cc-isolated-functions.bats:1004-1009 (excerpt; @test continues to :1013 — read)
  echo 'FROM node:22' > "$CLAUDE_DEVC_CONFIG_DIR/Dockerfile"
  rm "$CLAUDE_DEVC_CONFIG_DIR/cc-gitdir.sh"
  run bless_manifest
  [ "$status" -ne 0 ]
  [[ "$output" == *"host tool missing: cc-gitdir.sh"* ]]
  [ "$(cat "$(host_tools_path)")" = "$h" ]
```

The second case asserts only host-tools.sha256. Even an assertion on manifest.sha256 could not catch a write here: the Dockerfile is restored to the same `FROM node:22` that setup wrote, so a rewritten manifest would be byte-identical. The code does leave both manifests alone: probe P4 used a different Dockerfile (`FROM node:23`) and reported "manifest unchanged". The test's name is broader than its second case's assertions.

**Evidence:** `test/cc-isolated-functions.bats:994-1013`, `test/cc-isolated-functions.bats:32`, docs/reviews/execution-logs/fc-q089a1/probe.out (P4)

---

## Claim 17: "Re-cut of the reviewed feat/q089-host-tool-trust (dce5b039..548fe6f9, four review passes: rubric docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md) into units under the 400-line cap (decision log 62). After the iteration-4 split, the unit was 485 lines."

**Location:** commit f2533b33 message
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit range, the rubric's existence, the line counts and the 400 cap. Does not establish that the rubric is in A1's tree: it lives only on feat/q089-host-tool-trust.

`git log dce5b039^..548fe6f9` shows dce5b039 plus four fix commits: b1539159 (pass 1), d2fe61bb (pass 2), fa059477 (pass 3) and 548fe6f9 (iteration 4). The rubric is at `548fe6f9:docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md`, not in f2533b33's tree. Line counts outside docs/ (`git diff --numstat ... -- . ':!docs'`): 4ab9a51f..548fe6f9 = 461+24 = 485; A1 = 370+22 = 392 (under 400); A1+A2 (840f39b0) = 485. `git diff --stat 548fe6f9 840f39b0 -- . ':!docs'` is empty, so the re-cut is code-identical to the reviewed tip. Row 62 says "a hard size cap of ~400 changed code lines, counted outside `docs/` ... Added and removed lines both count" (`docs/decisions/log.md:85`).

**Evidence:** `docs/decisions/log.md:85`, 548fe6f9 docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md (paraphrased — no quote available because the numstat sums are command output; commands listed above)

---

## Claim 18: "cc-exit-scan.sh, cc-gitdir.sh and cc-push.sh leave enforcement_files() for host_tool_files(); bless writes host-tools.sha256 beside manifest.sha256 ...; so a host-tool change leaves blessed_hash, the baked image hash and the verified-live receipt alone. The launcher checks ... before sourcing the scan. On a mismatch it names every changed tool, runs the boundary check too and shows its diff, and refuses everything but --bless/--list. It warns, without refusing, on a changed cc-push.sh. Only a positively marked repo checkout ... is left unchecked. --list reports each entry point's host-tool state."

**Location:** commit f2533b33 message, paragraph 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each sentence against Claims 1, 3, 4b, 5b, 5d, 6, 8a, 11 and 13. Carries the same --help residue as Claim 9 and the same --list dir residue as Claim 8b.

Each sentence matches the code and passing tests cited in the claims listed (paraphrased — no quote available because the paragraph summarizes behavior spread across eight claims already quoted above).

**Evidence:** `devcontainer-config/cc-isolated.sh:199-307`, `devcontainer-config/cc-isolated.sh:480-500`, `devcontainer-config/cc-isolated.sh:695-758`

---

## Claim 19: "Tests under LC_ALL=C: cc-isolated-functions all pass, install-host 92/92."

**Location:** commit f2533b33 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both suites at f2533b33 under LC_ALL=C in a hermetic extract. Does not cover other suites, and install-host's T9 needs the tree to be a git checkout.

Commands (cwd `$P/src`; `env -i PATH=/usr/bin:/bin HOME=$P/home TMPDIR=$P/tmp CLAUDE_DEVC_CONFIG_DIR=$P/home/cfg LC_ALL=C timeout 600 bats <suite>`):
- `test/cc-isolated-functions.bats`: exit 0, 180/180 ok (2026-10-15T00:23:38Z).
- `test/install-host.bats` in the plain archive extract: exit 1, 91/92. T9 fails because `git -C "$CONFIG_SRC/.." archive HEAD` needs a repo (`fatal: not a git repository`), which comes from the extract, not the code.
- `test/install-host.bats` after `git init` plus one commit of the same extract: exit 0, 92/92 (2026-10-15T00:26:09Z).

Compared against the prior pattern "All 85 tests ... pass" (commit test tally, hallucination log): no match, the tally is right.

**Evidence:** docs/reviews/execution-logs/fc-q089a1/suites.txt, docs/reviews/execution-logs/fc-q089a1/cc-isolated-functions.log, docs/reviews/execution-logs/fc-q089a1/install-host.log, docs/reviews/execution-logs/fc-q089a1/install-host-gitinit.log

---

## Claim 20: "Notes: the verify_host_tools comment names the cc-push copy and its parity test, which land in A2; the two units merge in order."

**Location:** commit f2533b33 message, Notes
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the named A2 dependency, which is accurate. Does not cover the other forward references in A1, so the note understates them.

A1 also contains text that is true only after A2: `cc-gitdir.sh:5-6` ("cc-push for itself"), `install.sh:602` ("which cc-push checks before sourcing"), `cc-isolated.sh:196-197` ("below and in cc-push.sh"), `:481` ("cc-push refuses on itself"), the `--list` output `cc-push refuses:` (`:499`), the refusal's "cc-push refuses until re-blessed" (`:744`), and `:752` ("cc-push's self-check"). It also contains text that is true only after unit B: `decision log row 71` (cited at `cc-exit-scan.sh:4`, `cc-gitdir.sh:4-5`, `cc-isolated.sh:191` and `:221`, `install.sh:602` and the test at `:839`; absent from `docs/decisions/log.md` at f2533b33, whose last row is 70) and the `Host-tool-tested:` gate claim (Claim 4c). The precise version: "A1's comments and messages about cc-push's self-check land with A2; its row-71 and Host-tool-tested references land with unit B."

**Evidence:** `devcontainer-config/cc-gitdir.sh:4-6`, `devcontainer-config/install.sh:601-602`, `devcontainer-config/cc-isolated.sh:191-198`, `devcontainer-config/cc-isolated.sh:480-499`, `devcontainer-config/cc-isolated.sh:744-753`, f2533b33 `docs/decisions/log.md:68-93`

---

## Claim 21: "Live-verified: no — sandbox has no Docker; blessed_hash changes once on the next install.sh"

**Location:** commit f2533b33 message, trailer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers blessed_hash moving once when an install goes from base code to A1 and staying put afterwards, including across a host-tool edit. Does not establish the live-container result the trailer defers.

Probe P3 used the same installed files, blessed first with the base (4ab9a51f) launcher and then with the A1 launcher. The base gave `Blessed config: 4550ab996414d17d` with 10 entries (3 host tools). A1 gave `Blessed config: de595abc22a2e5d5` with 7 entries (0 host tools), and the bless printed the four `<` host-tool and launcher lines plus the new launcher line. A second A1 bless and a bless after a cc-push.sh edit both stayed at `de595abc22a2e5d5`.

**Evidence:** docs/reviews/execution-logs/fc-q089a1/probe.sh, docs/reviews/execution-logs/fc-q089a1/probe.out (P3), docs/reviews/execution-logs/fc-q089a1/probe.ts, docs/reviews/execution-logs/fc-q089a1/probe.rc

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 4c** (`devcontainer-config/cc-isolated.sh:197-198`): "carry `Host-tool-tested:`, not `Live-verified:`" is true only once unit B lands. At A1 (and A1+A2) the gate still requires Live-verified for all three tools, and the gate's own "keep in step with enforcement_files()" comment is untrue until then.
- **Claim 5c** (`devcontainer-config/cc-isolated.sh:223-224`): "DIR is the script's own resolved directory". `--list` passes the resolved config_dir instead.
- **Claim 8b** (`devcontainer-config/cc-isolated.sh:482-483`): "differs only for a custom install run without CLAUDE_DEVC_CONFIG_DIR". The dirs also differ for a repo-checkout launcher, or when the variable names another dir. There, `--list` says "launches refuse" while the launch does not (probe2).
- **Claim 9** (`devcontainer-config/cc-isolated.sh:692-694`): "refuses everything but --bless and --list". `--help`/`-h` (exit 0) and argument errors (exit 2) are answered first. Safe, because the scan is still not sourced.
- **Claim 10** (`devcontainer-config/cc-isolated.sh:738`): "no rebuild or probe is needed" holds only on a config already verified live. Say "the re-bless adds no rebuild or probe".
- **Claim 16** (`test/cc-isolated-functions.bats:994`): the name says "changes neither manifest", but the second failure case asserts only host-tools.sha256, and its restored Dockerfile could not reveal a manifest write anyway.
- **Claim 20** (commit f2533b33 Notes): names only the verify_host_tools/parity A2 dependency. A1 also carries six or more cc-push-self-check statements that need A2, and row-71 and Host-tool-tested references that need unit B.

### Unverifiable
(none)

---

## Goal-Alignment Note

A1 does what the PR says it does. The three host tools leave the boundary manifest, and a host-tool edit no longer moves blessed_hash (executed, P3). The launcher checks what it sources before sourcing it (executed, tamper mark never created). A mismatch refuses everything that would run scan code while still showing any boundary diff (executed). cc-push changes warn without refusing. The re-cut is code-identical to the four-pass-reviewed tip once A2 is stacked (`git diff 548fe6f9 840f39b0 -- . ':!docs'` is empty), and A1 alone is 392 lines, under the cap.

The prior rubric's open wording items show up again here, mostly unchanged: C4 (`--help`, "no rebuild or probe") is now Claims 9 and 10.

No claim is Incorrect at the level the PR claims to operate, but A1 does not stand on its own. Its comments and messages claim behavior from both A2 (cc-push's self-check) and unit B (decision row 71, the `Host-tool-tested:` gate), and the commit's Notes disclose only the A2 part. One thing for the orchestrator: unit B (feat/q089b-host-tool-gate, 6e00137b) is stacked on dce5b039, the pre-review unit-A commit, not on A1/A2. Merging B as it stands would bring in dce5b039's version of cc-isolated.sh/cc-push.sh/tests, which differs from the re-cut. The "merge in order" plan therefore needs B rebased onto A2 first. Until B lands, the live-verify gate on main still demands `Live-verified:` for host-tool commits, which is the cost this work set out to remove.
