Commit: afe1ae59

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q089 (branch feat/q089a2b-cc-push-self-check, HEAD afe1ae59, contains A1)
**Scope:** `git diff 4ab9a51f afe1ae59 -- devcontainer-config test` (cc-exit-scan.sh, cc-gitdir.sh, cc-isolated.sh, cc-push.sh, install.sh, test/cc-isolated-functions.bats, test/cc-push.bats) plus the commit messages `git log 4ab9a51f..afe1ae59` (f2533b33 through afe1ae59). Final confirming pass for units A1+A2, replicate r3. Unit B (feat/q089b4-host-tool-gate, stacked on afe1ae59) read as sibling context for row 71 and `Host-tool-tested:`.
**Checked:** 2026-10-14
**Total claims checked:** 41
**Summary:** 35 verified, 2 mostly accurate, 1 stale, 3 incorrect, 0 unverifiable

Hallucination-pattern log read first (`docs/reviews/hallucination-patterns.md`, 5 entries). Claims 34-37 below are suite-count claims. They look like the logged "specific measured value" pattern ("All 85 tests…", "mode1-equiv 33"), and each was re-run to rule that out: every count in the A1/A2 messages matches the plan line. The one false pass claim (Claim 37) is an "all pass" claim with no number, made untrue by a re-stack. It is not an invented number and not a fabricated symbol, so nothing is added to the pattern log.

Execution logs: `docs/reviews/execution-logs/fc-q089a-final-r3/`. Every probe ran under `timeout` from a `git archive` of afe1ae59 (or a temporary clone for the historical commits), in a fresh `mktemp -d` under `/home/node/.claude/jobs/00bcf178/tmp/`. HOME, TMPDIR, CLAUDE_DEVC_CONFIG_DIR and CC_PUSH_CLONES_DIR were redirected, LC_ALL=C was set and devcontainer was stubbed. No real config dir was touched and install.sh never ran. No process started here is still running: `ps -ef | grep -c '[b]ats'` returned 0 before this report was written.

---

## Claim 1: "it is a host tool (decision log row 71), so the bless hashes it into host-tools.sha256, not the boundary manifest, and cc-isolated.sh checks it against that file before sourcing it."

**Location:** `devcontainer-config/cc-exit-scan.sh:4-6`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hashing destination of cc-exit-scan.sh, the launcher's check-before-source order, and row 71 existing in unit B. It does not establish that row 71 exists on A's branch alone: it does not (`git grep -c '^| 71 ' afe1ae59 -- docs/decisions/log.md` prints nothing), so the reference resolves only once B lands.

`host_tool_files` lists it (`cc-isolated.sh:199-203`: `echo "cc-exit-scan.sh"`) and `enforcement_files` no longer does. The source is gated:

```bash
# devcontainer-config/cc-isolated.sh:714-721
CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
HOST_TOOLS_ERR=""
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
  # shellcheck source=cc-exit-scan.sh
  source "$CC_ISOLATED_DIR/cc-exit-scan.sh"
else
  HOST_TOOLS_ERR="${HOST_TOOLS_ERR:-host-tool check failed}"
fi
```

Executed: the test "launch: a tampered cc-exit-scan.sh is never sourced" passes (log 01). Row 71 is at `feat/q089b4-host-tool-gate:docs/decisions/log.md:94`.

**Evidence:** `devcontainer-config/cc-isolated.sh:199-203`, `devcontainer-config/cc-isolated.sh:714-721`, `test/cc-isolated-functions.bats:937-963`, docs/reviews/execution-logs/fc-q089a-final-r3/01-afe1ae59-cc-isolated-functions-bats.log (cmd `bats test/cc-isolated-functions.bats`, cwd fcr3full.6FIl74, exit 0, 2026-10-15T01:32:48Z)

---

## Claim 2: "hashed into host-tools.sha256. Both entry points check it against that file before it is sourced: cc-push for itself, the launcher for cc-exit-scan.sh."

**Location:** `devcontainer-config/cc-gitdir.sh:4-7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both source sites of cc-gitdir.sh (cc-push.sh:214 and cc-exit-scan.sh:12, reached only through the launcher's gated source). It does not establish anything about a caller that sources cc-gitdir.sh by another route; grep finds none.

cc-push checks it at `cc-push.sh:204` (`verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh`) and sources it only at `:214`. The launcher checks `cc-exit-scan.sh cc-gitdir.sh` (`cc-isolated.sh:716`) before sourcing the scan. The scan then sources cc-gitdir.sh at `cc-exit-scan.sh:12` (`source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"`). Executed: in the cc-push.bats test a tampered cc-gitdir.sh is refused and its `touch` never runs (log 02). Mutant P4, which removes cc-push's check, fails that test (log 05).

**Evidence:** `devcontainer-config/cc-push.sh:203-214`, `devcontainer-config/cc-exit-scan.sh:12`, `devcontainer-config/cc-isolated.sh:716`, docs/reviews/execution-logs/fc-q089a-final-r3/02-afe1ae59-cc-push-bats.log (exit 0, 01:32:48Z run), docs/reviews/execution-logs/fc-q089a-final-r3/05-mutants.log (`bash mutate.sh`, cwd /home/node/.claude/jobs/00bcf178/tmp, exit 0, 2026-10-15T01:36:00Z)

---

## Claim 3: "Keep this list and host_tool_files (below) in step with install.sh's PAYLOAD … a bats test now pins PAYLOAD ⊆ this list ∪ host_tool_files, the two disjoint"

**Location:** `devcontainer-config/cc-isolated.sh:118-121`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the subset and disjointness assertions of the PAYLOAD test. It does not establish the converse (that every hashed file is in PAYLOAD), which the test does not assert for host tools.

```bash
# test/cc-isolated-functions.bats:848-857 (excerpt; enclosing @test continues to :866 — read)
  [ "$host" = $'cc-exit-scan.sh\ncc-gitdir.sh\ncc-push.sh' ]
  for item in $host; do
    if echo "$enf" | grep -qx "$item"; then echo "in both lists: $item"; return 1; fi
  done
  for item in $items; do
  ...
    printf '%s\n%s\n' "$enf" "$host" | grep -qx "$item" || { echo "PAYLOAD item not hashed: $item"; return 1; }
```

PAYLOAD is at `install.sh:110` and holds the three tools. The test passes (log 01).

**Evidence:** `test/cc-isolated-functions.bats:835-866`, `devcontainer-config/install.sh:110`, docs/reviews/execution-logs/fc-q089a-final-r3/01-afe1ae59-cc-isolated-functions-bats.log

---

## Claim 4: "They run on the host … the image never copies them … so a change to one leaves blessed_hash (the baked config identity), the verified-live receipt and the container alone. Each entry point checks the ones it executes"

**Location:** `devcontainer-config/cc-isolated.sh:191-196`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Dockerfile COPY set, `blessed_hash` being a hash of manifest.sha256 only, and which files each entry point checks. It does not establish container behaviour, which needs Docker and was not run.

The Dockerfile COPYs only `egress/`, `init-firewall.sh`, `cc-sni-proxy.py`, `link-claude-home.sh` and `claude-home/` (`Dockerfile:486-500`). `blessed_hash` is `sha256sum < "$m" | cut -c1-16` over manifest.sha256 (`cc-isolated.sh:88-93`), and `verified_hash` compares against it. Executed: after a host-tool-only re-bless, manifest.sha256 is byte-identical (07-behave.log B7: "manifest.sha256 identical after host-tool-only re-bless"). The test at `:869-884` also passes (`[ "$(blessed_hash)" = "$before" ]`). The launcher checks the scan and gitdir (`:716`) and cc-push checks itself and gitdir (`cc-push.sh:204`).

**Evidence:** `devcontainer-config/Dockerfile:486-500`, `devcontainer-config/cc-isolated.sh:88-110`, `test/cc-isolated-functions.bats:869-884`, docs/reviews/execution-logs/fc-q089a-final-r3/07-behave.log (`bash behave.sh`, cwd /home/node/.claude/jobs/00bcf178/tmp, exit 0, 2026-10-15T01:37:58Z)

---

## Claim 5: "Commits that change them carry `Host-tool-tested:`, not `Live-verified:` (hooks/live-verify-gate.sh)."

**Location:** `devcontainer-config/cc-isolated.sh:197-198`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gate as it stands on unit B's branch. It does not establish the gate at afe1ae59, where `git grep 'Host-tool' afe1ae59 -- '*live-verify-gate*'` has no hits, so the comment is true only once B lands (the stated A1→A2→B order).

On B: `hooks/live-verify-gate.sh:154`: `if [ -n "$host_touched" ] && ! comment_only_diff "$host_touched"; then need+=("Host-tool-tested"); fi`, read at `feat/q089b4-host-tool-gate`.

**Evidence:** `feat/q089b4-host-tool-gate:hooks/live-verify-gate.sh:25,86,154`

---

## Claim 6: verify_host_tools header: "install.sh's bless hashes them into host-tools.sha256 … each entry point checks the files it is about to execute against that file BEFORE sourcing them. … Only a repo checkout is left unchecked, and it must say so positively: install.sh beside the script (install.sh is never installed, it is not in PAYLOAD), no manifest of either kind, and not the config dir. Anything else is checked, so deleting manifests is not enough to opt an installed copy out. Prints the reason and returns 1 on any mismatch."

**Location:** `devcontainer-config/cc-isolated.sh:219-229` (identical at `devcontainer-config/cc-push.sh:146-156`)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exemption condition and its four parts, the refusal of missing, symlinked, unreadable and malformed manifests, and the return code. It does not cover a planted install.sh together with deleted manifests in a dir that CLAUDE_DEVC_CONFIG_DIR does not name. That case is exempt by design, and B's row 71 lists it as not covered.

```bash
# devcontainer-config/cc-isolated.sh:230-240 (excerpt; enclosing verify_host_tools continues to :270 — read)
verify_host_tools() {
  local dir="$1" m f want have cfg
  shift
  m="$dir/host-tools.sha256"
  cfg="$(readlink -f -- "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}" 2>/dev/null || true)"
  if [ -f "$dir/install.sh" ] && [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
    return 0
  fi
  if [ ! -f "$m" ] || [ -L "$m" ]; then
```

install.sh is absent from `PAYLOAD=(…)` at `install.sh:110`. Executed: the test at `:886-926` covers no-manifest, install.sh-present, manifest-beside, tampered, missing/duplicate entry, symlinked tool and config-dir cases, and passes. 07/08 logs: cc-push `--help` exits 1 for missing, symlink, unreadable and malformed manifests, and 0 when blessed.

**Evidence:** `devcontainer-config/cc-isolated.sh:230-270`, `devcontainer-config/install.sh:110`, `test/cc-isolated-functions.bats:886-926`, docs/reviews/execution-logs/fc-q089a-final-r3/08-exit-codes.log (cwd fcr3-beh.nr3Agu, 2026-10-15T01:38:10Z, exit codes listed per case)

---

## Claim 7: "KEEP IN STEP with the copy in cc-push.sh (a test compares the two byte for byte)" (and the mirror line in cc-push.sh)

**Location:** `devcontainer-config/cc-isolated.sh:219`, `devcontainer-config/cc-push.sh:146`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two blocks from their second line through `# --- end verify_host_tools`. The first marker line is deliberately excluded (`tail -n +2`) because it names the other file. Whether a regression in the copies would be caught is shown below.

`diff` of the two marker-delimited blocks shows only line 1 differing (`< …copy in cc-push.sh` / `> …copy in cc-isolated.sh`). The test compares from line 2 on:

```bash
# test/cc-isolated-functions.bats:928-935
@test "verify_host_tools is the same code in cc-isolated.sh and cc-push.sh" {
  local a b
  a="$(sed -n '/^# --- verify_host_tools/,/^# --- end verify_host_tools/p' "$CONFIG_SRC/cc-isolated.sh" | tail -n +2)"
  b="$(sed -n '/^# --- verify_host_tools/,/^# --- end verify_host_tools/p' "$CONFIG_SRC/cc-push.sh" | tail -n +2)"
  [ -n "$a" ]
  [[ "$a" == *"verify_host_tools() {"* ]]
  [ "$a" = "$b" ]
}
```

The test can fail. At 4be0445d, where the copies had drifted, it reported `not ok 76` (log 04-hist-4be0445d-cc-isolated-functions.log).

**Evidence:** `test/cc-isolated-functions.bats:928-935`, docs/reviews/execution-logs/fc-q089a-final-r3/04-hist-4be0445d-cc-isolated-functions.log (cwd fcr3-clone.mPiWxk/repo at 4be0445d, 2026-10-15T01:43:08Z, 181/182)

---

## Claim 8a: "Both manifests are computed into temp files first and moved into place only when both succeed, so a bless that fails to compute either changes neither."

**Location:** `devcontainer-config/cc-isolated.sh:273-274`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers compute failures in either manifest. It does not cover a mktemp failure after the first temp file exists, where the code removes `$new_m` (read at `:283-284`).

```bash
# devcontainer-config/cc-isolated.sh:282-290 (excerpt; enclosing bless_manifest continues to :318 — read)
  mkdir -p "$(config_dir)"
  new_m="$(mktemp "$(config_dir)/.manifest.XXXXXX")" || return 1
  new_h="$(mktemp "$(config_dir)/.host-tools.XXXXXX")" || { rm -f "$new_m"; return 1; }
  if ! compute_manifest > "$new_m" || ! compute_host_tools_manifest > "$new_h"; then
    rm -f "$new_m" "$new_h"
    echo "ERROR: nothing blessed." >&2
    return 1
  fi
```

Executed: the test "bless: a failure changes neither manifest" passes. Mutant P3, which writes the boundary manifest in place, fails it at line 1050 (log 05).

**Evidence:** `devcontainer-config/cc-isolated.sh:281-318`, `test/cc-isolated-functions.bats:1032-1054`, docs/reviews/execution-logs/fc-q089a-final-r3/05-mutants.log (probe p3)

---

## Claim 8b: "The two same-directory renames can still split (one fails, or an interrupt lands between them): host-tools.sha256 is then new and manifest.sha256 old, so a launch refuses if the boundary changed too, and otherwise the host tools stand blessed although bless exited 1."

**Location:** `devcontainer-config/cc-isolated.sh:275-278`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the rename order and a failed second `mv` under `set -e`. It does not establish the exit status after an interrupt. A SIGINT between the renames ends bash with 130, not 1, so "exited 1" holds only for the failed-rename branch. A rename failure was not reproduced.

The order is host first, then manifest: `mv -f "$new_h" "$(host_tools_path)"` then `mv -f "$new_m" "$(manifest_path)"` (`:303-304`). `main` calls `bless) bless_manifest; exit 0 ;;` (`:787`) outside any conditional, so under `set -euo pipefail` (`:66`) a failing `mv` ends the script with mv's status, 1. No INT trap is set on the bless path (paraphrased — no quote available because this rests on the absence of a `trap` before `:787` in main; the only traps are at `:916-923`, after launch). So an interrupt gives 128+2. A more precise wording: "although bless failed (exit 1, or 130 on Ctrl-C)".

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-isolated.sh:303-304`, `devcontainer-config/cc-isolated.sh:786-789`

---

## Claim 9: "The bless command for the dir being checked: names CLAUDE_DEVC_CONFIG_DIR when it is set, so a hint printed for a non-default dir does not bless the default one."

**Location:** `devcontainer-config/cc-isolated.sh:321-322`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both branches of bless_cmd and its use in the launcher refusal (with CC_ISOLATED_DIR), check_manifest and --list. It does not cover cc-push's own hint, which is a separate printf (Claim 19).

```bash
# devcontainer-config/cc-isolated.sh:323-329
bless_cmd() {
  if [ -n "${CLAUDE_DEVC_CONFIG_DIR:-}" ]; then
    printf 'CLAUDE_DEVC_CONFIG_DIR=%q %s --bless' "$CLAUDE_DEVC_CONFIG_DIR" "$0"
  else
    printf '%s --bless' "$0"
  fi
}
```

Executed: the refusal prints `CLAUDE_DEVC_CONFIG_DIR=<cfg> <cfg>/cc-isolated.sh --bless` (07 B2). With the variable unset, --list prints `<path>/cc-isolated.sh --bless` (07 B8).

**Evidence:** `devcontainer-config/cc-isolated.sh:323-329`, `devcontainer-config/cc-isolated.sh:769-770`, docs/reviews/execution-logs/fc-q089a-final-r3/07-behave.log

---

## Claim 10: "the launcher refuses on the two files it executes (and only warns on cc-push); cc-push refuses on itself and cc-gitdir.sh. Checked in config_dir(); an entry point checks its own dir, which differs whenever the command run is not the copy in config_dir()"

**Location:** `devcontainer-config/cc-isolated.sh:492-497`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file sets each --list line checks and the dir --list uses (`readlink -f` of config_dir(), falling back to the unresolved path). It does not establish what an entry point in another dir would report, which --list does not inspect.

`lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)"` and `perr="$(verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh)"` (`:502-503`). These match the launcher's `:716` and cc-push's `:204`. The launcher checks `CC_ISOLATED_DIR` (`:714`), so the "differs" clause is true by construction. Executed: --list on a changed cc-push prints "launches warn (cc-push changed) but run" and the cc-push line (07 B6).

**Evidence:** `devcontainer-config/cc-isolated.sh:498-517`, docs/reviews/execution-logs/fc-q089a-final-r3/07-behave.log

---

## Claim 11: "Not a bare assignment: readlink -f fails when the dir's parent is missing, and under set -e that would end --list silently."

**Location:** `devcontainer-config/cc-isolated.sh:499-500`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback at `:501` and the test that pins it. It does not establish behaviour when config_dir() itself exists but cannot be read.

`cfg_real="$(readlink -f -- "$(config_dir)")" || cfg_real="$(config_dir)"` (`:501`). Mutant P2 removes the `|| …` and fails the test at `:998-1004` on line 1000 (`[ "$status" -eq 0 ]`), so the failure is real and the test pins it (log 05).

**Evidence:** `devcontainer-config/cc-isolated.sh:501`, `test/cc-isolated-functions.bats:998-1004`, docs/reviews/execution-logs/fc-q089a-final-r3/05-mutants.log (probe p2)

---

## Claim 12: "An intact cc-push refuses on this; a copy that dropped its own check would not, so the line says what to do rather than predicting what cc-push does." / message "cc-push: CHANGED — do not run it until re-blessed (an intact copy refuses)"

**Location:** `devcontainer-config/cc-isolated.sh:515-516`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the intact copy refusing on every condition `perr` reports, and a check-less copy not refusing. It does not establish what a tampered copy does beyond skipping the check.

perr uses the same arguments as cc-push's own call (`cc-push.sh cc-gitdir.sh`), so every non-empty perr matches a refusal by an intact cc-push. Executed: an intact copy exits 1 for each manifest state (08). Mutant P4, a copy with `if false; then`, runs past the check (its test fails at cc-push.bats:806, log 05).

**Evidence:** `devcontainer-config/cc-isolated.sh:503,515-516`, `devcontainer-config/cc-push.sh:204`, docs/reviews/execution-logs/fc-q089a-final-r3/08-exit-codes.log, docs/reviews/execution-logs/fc-q089a-final-r3/05-mutants.log (probe p4)

---

## Claim 13: "Both it and the cc-gitdir.sh it sources are host tools, checked against host-tools.sha256 first: sourcing runs a file's top level. When the check fails the scan is not loaded, and main refuses every action but --bless and --list (--help and usage errors are answered first; neither touches the scan)."

**Location:** `devcontainer-config/cc-isolated.sh:710-713`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers launch, --probe-only, --register, --help and an unknown flag with a tampered scan, and bless/list passing. It does not cover `--profile` without a value, which also exits 2 in the parse loop (`:739-744`). That case was read, not run.

The parse loop (`:732-751`) handles `--help|-h) usage; exit 0` and `-*) … exit 2` before the guard at `:753`: `if [ -n "$HOST_TOOLS_ERR" ] && [ "$action" != "bless" ] && [ "$action" != "list" ]; then`. Executed with a tampered scan: `--help` exits 0 and `--bogus` exits 2 with "ERROR: unknown flag" (08). `--probe-only` and `--register` print the refusal (07 B1). Test `:937-963` shows --list and --bless run and the scan's `touch` never happens.

**Evidence:** `devcontainer-config/cc-isolated.sh:729-780`, docs/reviews/execution-logs/fc-q089a-final-r3/07-behave.log, docs/reviews/execution-logs/fc-q089a-final-r3/08-exit-codes.log

---

## Claim 14: "ERROR: host-tool check failed — refusing to launch, probe or register:"

**Location:** `devcontainer-config/cc-isolated.sh:754`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the actions that reach the guard (launch, probe, register). It does not cover bless and list, which the guard excludes.

The actions set in the parse loop are bless, probe, register, list and the default launch (`:730-738`). The guard excludes bless and list. Executed: 07 B1 and B2.

**Evidence:** `devcontainer-config/cc-isolated.sh:730-738,753-754`, docs/reviews/execution-logs/fc-q089a-final-r3/07-behave.log

---

## Claim 15: "Never let this refusal hide a boundary change: run the boundary check too, and show its diff, before pointing at a bless that would accept both." + notes "The boundary config is unchanged: the re-bless changes no boundary state, so it causes no rebuild …" / "The BOUNDARY config changed too (above)…"

**Location:** `devcontainer-config/cc-isolated.sh:756-762`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_manifest running against CC_ISOLATED_DIR inside the refusal, the diff reaching stderr, the choice between the two notes, and manifest.sha256 staying identical on a host-only re-bless. It does not establish the "no rebuild" consequence in a live container (container_config_matches needs Docker).

`if ! CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" check_manifest; then boundary_note="The BOUNDARY config changed too …"` (`:760-762`). check_manifest prints `diff <(echo "$expected") <(echo "$actual") >&2` (`:343`). Executed: test `:965-996` asserts the init-firewall.sh diff and the BOUNDARY note. The upgrade probe shows the diff after the refusal (06). B7 shows the manifest unchanged after a host-only re-bless (07).

**Evidence:** `devcontainer-config/cc-isolated.sh:332-347,756-771`, `test/cc-isolated-functions.bats:965-996`, docs/reviews/execution-logs/fc-q089a-final-r3/06-upgrade.log (`bash upgrade.sh`, exit 0, 2026-10-15T01:36:30Z), docs/reviews/execution-logs/fc-q089a-final-r3/07-behave.log

---

## Claim 16: "Only a cc-push.sh-specific reason: a manifest-level one is already above."

**Location:** `devcontainer-config/cc-isolated.sh:763-766`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers missing and malformed host manifests (no extra line) and a changed cc-push (line printed). It does not cover a config dir whose path contains the substring "cc-push.sh", which would make a manifest-level reason match the glob.

`if ! push_err="$(verify_host_tools "$CC_ISOLATED_DIR" cc-push.sh)" && [[ "$push_err" == *cc-push.sh* ]]; then`. Executed: with a missing or malformed manifest the refusal has no "also changed" line (07 B2, B3). Test `:994` asserts the line when cc-push.sh changed.

**Evidence:** `devcontainer-config/cc-isolated.sh:763-766`, `test/cc-isolated-functions.bats:994`, docs/reviews/execution-logs/fc-q089a-final-r3/07-behave.log

---

## Claim 17: "cc-push is not executed by the launcher, so a change to it never blocks a launch, but the launcher still says so"

**Location:** `devcontainer-config/cc-isolated.sh:772-779`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a cc-push-only change at launch (warning, no refusal), and bless and list (no warning). It does not cover a launch failing later for unrelated reasons.

`echo "WARNING: $push_err — do not run cc-push until you have reviewed it and re-blessed." >&2` (`:778`). Nothing else in the launcher reads or sources cc-push.sh (paraphrased — no quote available because this is an absence; `grep -n 'cc-push.sh' cc-isolated.sh` finds only host_tool_files, list_projects, the refusal and this warning). Executed: 07 B6 shows a WARNING at launch, none for --list or --bless. Test `:1056-1076` asserts `!= *"refusing to launch"*`.

**Evidence:** `devcontainer-config/cc-isolated.sh:772-779`, `test/cc-isolated-functions.bats:1068-1070`, docs/reviews/execution-logs/fc-q089a-final-r3/07-behave.log

---

## Claim 18: "when this installed copy or the cc-gitdir.sh beside it differs from what the bless recorded in host-tools.sha256 (or that file is missing, a symlink, unreadable or malformed), cc-push exits 1 before parsing anything, --help included (decision log row 71)."

**Location:** `devcontainer-config/cc-push.sh:35-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all five triggering conditions with `--help`. It does not cover the repo-checkout exemption (Claim 6), which intentionally does not exit, or row 71, which is in B only.

The check (`:204-212`) runs at top level. `main` is defined at `:430` and called at `:592`. Executed: `--help` exits 1 when the manifest is missing, a symlink, unreadable (uid 1000) or malformed, and 0 when blessed (08). A changed cc-gitdir.sh or cc-push.sh exits 1 (cc-push.bats `:797-825`, log 02).

**Evidence:** `devcontainer-config/cc-push.sh:203-214`, `devcontainer-config/cc-push.sh:592`, `test/cc-push.bats:797-825`, docs/reviews/execution-logs/fc-q089a-final-r3/08-exit-codes.log

---

## Claim 19: "What that guards: cc-gitdir.sh, and every line of this file below the check (all the push logic). It cannot guard the lines above the check, nor an overwrite that drops it: a tampered copy that skips its own check is caught only by cc-isolated's warning at the next launch of the copy installed beside it, and by `cc-isolated --list` for the config dir." (also the refusal's hint `CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless`)

**Location:** `devcontainer-config/cc-push.sh:38-43`, `devcontainer-config/cc-push.sh:205-211`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard boundary (a touch inserted directly below the check never runs), the two outside observers, and the hint naming the copy's own dir. "Next launch" should be read as any non-bless/list run of that launcher (`--probe-only` and `--register` warn too). This report does not establish that the user runs either.

Test `:811-817` inserts `touch …/push-tamper-ran` directly before `# shellcheck source=cc-gitdir.sh`, then asserts exit 1, the hint `CLAUDE_DEVC_CONFIG_DIR=$d cc-isolated --bless`, and that the marker is absent. It passes (02), and mutant P4 fails it (05). The launcher warning checks `$CC_ISOLATED_DIR/cc-push.sh` (`cc-isolated.sh:776`), and --list checks config_dir() (`:503`).

**Evidence:** `devcontainer-config/cc-push.sh:204-212`, `devcontainer-config/cc-isolated.sh:503,775-779`, `test/cc-push.bats:809-817`, docs/reviews/execution-logs/fc-q089a-final-r3/05-mutants.log

---

## Claim 20: "Checked first: a tampered cc-gitdir.sh would run at source time."

**Location:** `devcontainer-config/cc-push.sh:201-202`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of check and source in cc-push. It does not cover cc-gitdir.sh's own content, which defines functions only (its header, not re-verified here).

The check is at `:204` and the source at `:214`. The test appends `touch "$M/gitdir-ran"` to cc-gitdir.sh, and with the check intact the marker is absent (`cc-push.bats:801-805`). Without the check (P4) the test fails.

**Evidence:** `devcontainer-config/cc-push.sh:201-214`, `test/cc-push.bats:801-805`, docs/reviews/execution-logs/fc-q089a-final-r3/05-mutants.log

---

## Claim 21: "The bless hashes it into host-tools.sha256 (a host tool, decision log row 71), which cc-push checks before sourcing cc-gitdir.sh."

**Location:** `devcontainer-config/install.sh:601-602`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bless at `install.sh:607` writing host-tools.sha256 with cc-push.sh, and cc-push's check order. Row 71 resolves only in B.

After the install.sh-style bless, host-tools.sha256 exists with 3 entries and installed `cc-push.sh --help` exits 0 (06).

**Evidence:** `devcontainer-config/install.sh:600-607`, docs/reviews/execution-logs/fc-q089a-final-r3/06-upgrade.log

---

## Claim 22: install.sh's bless path works on an upgrade from an install with no host-tools.sha256 (PR description; f2533b33 "blessed_hash changes once on the next install.sh")

**Location:** `devcontainer-config/install.sh:607`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new launcher's bless in a dir blessed by 4ab9a51f's launcher (old manifest with the three tools, no host-tools.sha256). It does not run install.sh itself (its review, staging and prompt steps), only the command at `:607` that install.sh runs.

`CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless`. At load, verify_host_tools fails ("no host-tool manifest"), but bless is exempt from the guard. Probe 06: before the bless, a launch is refused with both the host-tool reason and the boundary diff (the old manifest lists cc-exit-scan.sh, cc-gitdir.sh and cc-push.sh). The bless exits 0 and prints "Changed since the last bless (manifest.sha256)" and "No previous host-tools.sha256: every entry below is new to this bless." Then --list prints "Host tools — match the bless". The blessed hash changes once because the three lines leave manifest.sha256.

**Evidence:** `devcontainer-config/install.sh:607`, `devcontainer-config/cc-isolated.sh:281-318,753`, docs/reviews/execution-logs/fc-q089a-final-r3/06-upgrade.log (`bash upgrade.sh`, cwd /home/node/.claude/jobs/00bcf178/tmp, exit 0, 2026-10-15T01:36:30Z)

---

## Claim 23: test "every regular file in install.sh's PAYLOAD is hashed by enforcement_files or host_tool_files" (with its comment: the lists disjoint, the host list exactly the three tools, no COPYd file a host tool)

**Location:** `test/cc-isolated-functions.bats:835-866`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the four assertions named in the comment. "Moving a boundary file there would drop its Live-verified gate" is rationale whose truth depends on B's gate.

The assertions sit at `:848` (exact list), `:849-851` (disjoint), `:852-858` (subset) and `:859-861` (no COPY of a host tool). The test passes (01).

**Evidence:** `test/cc-isolated-functions.bats:835-866`, docs/reviews/execution-logs/fc-q089a-final-r3/01-afe1ae59-cc-isolated-functions-bats.log

---

## Claim 24: test "bless writes host-tools.sha256; a host-tool edit leaves the boundary manifest and blessed hash alone"

**Location:** `test/cc-isolated-functions.bats:869-884`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file's existence and contents, the absence of host tools from manifest.sha256, check_manifest passing after a cc-push edit, `blessed_hash` stable, and verify_host_tools seeing the edit. It does not cover edits to the other two tools in this test (covered at `:937`, `:965`).

The test passes (01).

**Evidence:** `test/cc-isolated-functions.bats:869-884`, docs/reviews/execution-logs/fc-q089a-final-r3/01-afe1ae59-cc-isolated-functions-bats.log

---

## Claim 25: test "verify_host_tools: repo checkout unchecked; an installed dir must match, and cannot opt out"

**Location:** `test/cc-isolated-functions.bats:886-926`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exemption, a manifest beside install.sh, a tamper, a missing or duplicate entry, a symlinked tool and the config dir. Its "cannot opt out" half is shown with manifest.sha256 present or install.sh absent. A planted install.sh with both manifests deleted outside the config dir is exempt by design and not tested as refused.

The test passes (01).

**Evidence:** `test/cc-isolated-functions.bats:886-926`, docs/reviews/execution-logs/fc-q089a-final-r3/01-afe1ae59-cc-isolated-functions-bats.log

---

## Claim 26: test "launch: a tampered cc-exit-scan.sh is never sourced; --bless still works and clears it"

**Location:** `test/cc-isolated-functions.bats:937-963`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers no sourcing at launch, --list or --bless (marker absent), the boundary manifest unchanged by the re-bless, and the scan loading afterwards (marker present). The test can fail: the appended `touch` runs at source time, because the scan has no main guard (`cc-exit-scan.sh` defines functions and runs nothing else at top level besides its `source`).

The test passes (01). Its final `[ -e "$mark" ]` shows that the tamper fires when the file is sourced, so the earlier `[ ! -e "$mark" ]` assertions are not vacuous.

**Evidence:** `test/cc-isolated-functions.bats:937-963`, docs/reviews/execution-logs/fc-q089a-final-r3/01-afe1ae59-cc-isolated-functions-bats.log

---

## Claim 27: test "launch: a host-tool refusal still shows a boundary change made alongside it, and bless prints both" (and comments "Every changed tool is named, cc-push included, before the bless is suggested", "Every reason line is indented under the ERROR line", "A bless with no previous manifest says every entry is new")

**Location:** `test/cc-isolated-functions.bats:965-996`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions as written. "Before the bless is suggested" is not asserted as an ordering against the hint line; the ordered glob at `:994` ends at "cc-push.sh changed".

The test passes (01).

**Evidence:** `test/cc-isolated-functions.bats:965-996`, docs/reviews/execution-logs/fc-q089a-final-r3/01-afe1ae59-cc-isolated-functions-bats.log

---

## Claim 28: test "--list still reports everything when the config dir's parent is missing (set -e)"

**Location:** `test/cc-isolated-functions.bats:998-1004`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regression it names (mutant P2 fails it). It does not cover other set -e hazards in list_projects.

See Claim 11.

**Evidence:** `test/cc-isolated-functions.bats:998-1004`, docs/reviews/execution-logs/fc-q089a-final-r3/05-mutants.log

---

## Claim 29: test "verify_host_tools: an unreadable, empty or malformed manifest, or a missing entry, is named as the problem"

**Location:** `test/cc-isolated-functions.bats:1006-1030`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all four cases. The unreadable case runs only as non-root (`if [ "$(id -u)" -ne 0 ]`); this run was uid 1000, so it ran.

The test passes (01). The texts match the code at `:242-260`.

**Evidence:** `test/cc-isolated-functions.bats:1006-1030`, `devcontainer-config/cc-isolated.sh:242-260`

---

## Claim 30: test "bless: a failure changes neither manifest" (comment "A Dockerfile that differs from the blessed one, so a rewritten boundary manifest would show")

**Location:** `test/cc-isolated-functions.bats:1032-1054`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both compute-failure orders and temp-file cleanup. It does not cover rename failures (Claim 8b).

Mutant P3 fails it at `:1050` (log 05).

**Evidence:** `test/cc-isolated-functions.bats:1032-1054`, docs/reviews/execution-logs/fc-q089a-final-r3/05-mutants.log

---

## Claim 31: test "--list reports host-tool state; a changed cc-push warns at launch but does not refuse"

**Location:** `test/cc-isolated-functions.bats:1056-1070`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the match line, the CHANGED block for a cc-push change, and the launch warning without a refusal. It does not cover the test's last stanza (Claim 32).

The test passes (01). The positive glob at `:1066` matches the it3 wording.

**Evidence:** `test/cc-isolated-functions.bats:1056-1070`, docs/reviews/execution-logs/fc-q089a-final-r3/01-afe1ae59-cc-isolated-functions-bats.log

---

## Claim 32: "A scan-only change: launches refuse, cc-push (which does not run the scan) does not." with `[[ "$output" != *"cc-push refuses"* ]]`

**Location:** `test/cc-isolated-functions.bats:1071-1075`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the negative assertion's ability to detect the regression the comment names (--list reporting cc-push as affected by a scan-only change). It does not dispute the production behaviour, which is correct at afe1ae59.

At f737ba71 the --list line was `printf '  cc-push refuses: %s\n'` (`f737ba71:devcontainer-config/cc-isolated.sh:515`), so the assertion could fail. afe1ae59 changed the line to `'  cc-push: CHANGED — do not run it until re-blessed (an intact copy refuses): %s\n'` (`cc-isolated.sh:516`). It updated the positive glob at `:1066` but not this negative one. "cc-push refuses" no longer occurs in any --list output: `grep -n 'cc-push refuses'` in cc-isolated.sh finds only the comments at `:493`, `:515`. Executed: mutant P1 makes perr include cc-exit-scan.sh. A scan-only change then prints `cc-push: CHANGED … cc-exit-scan.sh changed since the last bless` (verified by hand in the mutant dir), and the test still passes (`ok 1`, log 05). The assertion should be `!= *"cc-push: CHANGED"*` or `!= *"cc-push:"*`.

**Evidence:** `test/cc-isolated-functions.bats:1071-1075`, `devcontainer-config/cc-isolated.sh:515-516`, docs/reviews/execution-logs/fc-q089a-final-r3/05-mutants.log (probe p1, `ok 1`, bats exit 0)

---

## Claim 33: cc-push.bats test "installed copy: cc-push checks itself and cc-gitdir.sh before sourcing, and refuses on a change (row 71)" and comments "Its own file too: a change to cc-push.sh refuses, --help included (exit 1)", "A tamper directly below the check (the first line it guards) never runs. Not at the end of the file: cc-push exits at its main guard before reaching it.", "Deleting the host manifest does not turn the installed copy into a repo checkout."

**Location:** `test/cc-push.bats:797-825`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion and that the test fails without the check (P4). For "deleting the host manifest", the copy is refused for two reasons at once (manifest.sha256 present, install.sh absent). The test does not isolate which condition is load-bearing.

`grep -qx "touch $M/push-tamper-ran"` at `:813` makes sure the insertion happened. `main "$@"` at `cc-push.sh:592` ends in `exit` for `--help` (`:439`), so the end of the file is never reached. That supports the "Not at the end" comment.

**Evidence:** `test/cc-push.bats:797-825`, `devcontainer-config/cc-push.sh:439,592`, docs/reviews/execution-logs/fc-q089a-final-r3/02-afe1ae59-cc-push-bats.log, docs/reviews/execution-logs/fc-q089a-final-r3/05-mutants.log

---

## Claim 34: f2533b33 body: behaviour summary, "After the iteration-4 split, the unit was 485 lines", "Tests under LC_ALL=C: cc-isolated-functions all pass, install-host 92/92", "blessed_hash changes once on the next install.sh"

**Location:** commit f2533b33 message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suites at f2533b33 and the 485 figure (`git diff --shortstat 4ab9a51f 548fe6f9 -- devcontainer-config test` → 461+24). The behaviour summary is checked against afe1ae59's code (Claims 1-17). Its "Notes" about the cc-push copy landing in A2 holds.

Executed in a temporary clone at f2533b33: cc-isolated-functions 180/180 and install-host 92/92 (rc 0). The upgrade probe shows blessed_hash changing once (Claim 22).

**Evidence:** docs/reviews/execution-logs/fc-q089a-final-r3/04-hist-f2533b33-cc-isolated-functions.log, docs/reviews/execution-logs/fc-q089a-final-r3/04-hist-install-host-f2533b33.log (cmd `bats test/install-host.bats`, cwd fcr3-clone.mPiWxk/repo, exit 0, started 2026-10-15T01:38:29Z)

---

## Claim 35: b3b37e16: "Tests under LC_ALL=C: cc-isolated-functions 181/181"; "A1 is 418 lines after this round (392 when the loop started)"

**Location:** commit b3b37e16 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and the line figures as insertions+deletions over devcontainer-config and test from 4ab9a51f. It does not re-check the rubric items A1-A6, which later iterations superseded and Claims 1-17 cover at HEAD.

181/181 at b3b37e16 (log). `git diff --shortstat 4ab9a51f b3b37e16 -- devcontainer-config test` → 396+22 = 418, and for f2533b33 → 370+22 = 392.

**Evidence:** docs/reviews/execution-logs/fc-q089a-final-r3/04-hist-b3b37e16-cc-isolated-functions.log (2026-10-15T01:42:20Z)

---

## Claim 36: "Tests under LC_ALL=C: cc-isolated-functions 182/182, cc-push 48/48." (f737ba71, afe1ae59) and "Parity test and cc-push 48/48 under LC_ALL=C." (cc2640b7), "cc-push 48/48" (2cb03f23)

**Location:** commit messages f737ba71, afe1ae59, cc2640b7, 2cb03f23
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suites at afe1ae59, f737ba71 and cc2640b7. 2cb03f23's cc-push count was not run separately; cc-push.bats has 48 tests there and at its neighbours (static count).

afe1ae59: 182/182 and 48/48 (logs 01, 02, exit 0, 2026-10-15T01:32:48Z). f737ba71: 182/182 and 48/48. cc2640b7: cc-isolated-functions 182/182 including parity (rc 0) and cc-push 48/48.

**Evidence:** docs/reviews/execution-logs/fc-q089a-final-r3/01-afe1ae59-cc-isolated-functions-bats.log, docs/reviews/execution-logs/fc-q089a-final-r3/02-afe1ae59-cc-push-bats.log, docs/reviews/execution-logs/fc-q089a-final-r3/04-hist-f737ba71-cc-isolated-functions.log, docs/reviews/execution-logs/fc-q089a-final-r3/04-hist-cc2640b7-cc-isolated-functions.log

---

## Claim 37: 4be0445d: "Tests under LC_ALL=C: cc-push 48/48, cc-isolated-functions all pass."

**Location:** commit 4be0445d message
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suites at 4be0445d. It does not cover 840f39b0, the original of this commit, whose parent is f2533b33. There the claim was presumably true, but it was not run.

At 4be0445d cc-isolated-functions is 181/182: `not ok 76 verify_host_tools is the same code in cc-isolated.sh and cc-push.sh`. The re-stack onto b3b37e16 carried the old cc-push copy. cc2640b7 is the fix ("Keeps cc-push's copy byte-identical … after A1 iteration 1"), and it does not say that 4be0445d's message was wrong. History only; HEAD passes.

**Evidence:** docs/reviews/execution-logs/fc-q089a-final-r3/04-hist-4be0445d-cc-isolated-functions.log (cwd fcr3-clone.mPiWxk/repo at 4be0445d, 2026-10-15T01:43:08Z, plan 1..182, one not ok)

---

## Claim 38: 4be0445d: "Tests: a tampered cc-gitdir.sh and a tampered cc-push.sh are both refused without running"

**Location:** commit 4be0445d message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test as it was at 4be0445d. The current test (Claim 33) is correct.

At 4be0445d the cc-push.sh "tamper" was `printf '\n# edited\n' >> "$d/cc-push.sh"`, an inert comment, and nothing asserted that it did not run (`4be0445d:test/cc-push.bats`, the "Its own file too" stanza). 2cb03f23 records the correction but names the pre-re-stack hash ("Correction to 840f39b0's message"). History only.

**Evidence:** `4be0445d:test/cc-push.bats` (installed-copy test, lines after "Its own file too")

---

## Claim 39: 2cb03f23: "A3: the self-tamper test appends a touch below the check and asserts it never ran. Correction to 840f39b0's message: before this, that test's tamper was an inert comment."

**Location:** commit 2cb03f23 message
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test at 2cb03f23 and the hash reference. It does not affect HEAD, where f737ba71 moved the touch to directly below the check.

At 2cb03f23 the touch was appended to the end of the file (`printf 'touch %q\n' "$M/push-tamper-ran" >> "$d/cc-push.sh"`). The `--help` run exits in main before reaching it, so `[ ! -e "$M/push-tamper-ran" ]` could not fail. f737ba71's message says this ("at the end of the file the main guard exited first and the assertion could not fail"). The "840f39b0" reference is correct as a hash (it exists: "feat(cc-push): check itself …", parent f2533b33), but this branch carries that message as 4be0445d. The refuted part is the "asserts it never ran" mechanism. History only.

**Evidence:** `2cb03f23:test/cc-push.bats` (installed-copy test, "A tamper below the check" stanza), commit f737ba71 message

---

## Claim 40: afe1ae59 body items: security F1 (--list wording), api F1 (cc-push line only for a cc-push.sh-specific reason), api F2 (cause-neutral header), api F3 (cc-push guidance indented), api F5 ("has no entry, or more than one, for X" in both copies), fact-check 17b (A2 rubric records the one-landing constraint), "Recorded reviewer probe scripts … that tripped health-check gate 6 get a shellcheck disable line", "security F2 … goes to row 71's not-covered list in unit B"

**Location:** commit afe1ae59 message
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed item. The one imprecision is "scripts … get a shellcheck disable line": one script did.

F1: `cc-isolated.sh:516` and `:765` hold the new texts. api F1: Claim 16. api F2: `:754`. api F3: cc-push `:209` `echo "  Review the host tools …"` and `:210` 4-space hint, matching the launcher's `:769-770`. api F5: both copies, parity verified. 17b: the A2 rubric gained "**Merge constraint:** A2 lands together with A1 … and then B, in one landing". Security F2: B's row 71 lists "a `sha256sum` or `awk` stand-in, on PATH or as an exported shell function". Shellcheck: the only execution-log script changed is `fc-q089a1/probe.sh` (+`# shellcheck disable=SC2010`). Its f737ba71 version gives SC2010 (warning). Gate-6-equivalent `shellcheck -x -e SC1091 -s bash -S warning` passes on all 98 execution-log scripts at afe1ae59 (run 2026-10-15, cwd fcr3full.6FIl74, no FAIL lines; output not captured beyond "checked 98", recorded here). Precise wording: "the one recorded probe script that tripped gate 6 gets …".

**Evidence:** `devcontainer-config/cc-isolated.sh:516,754,765`, `devcontainer-config/cc-push.sh:205-211`, `docs/reviews/code-review-rubric-2026-10-14-feat-q089a2-cc-push-self-check.md`, `docs/reviews/execution-logs/fc-q089a1/probe.sh:2`, `feat/q089b4-host-tool-gate:docs/decisions/log.md:94`

---

## Claims Requiring Attention

### Incorrect
- **Claim 37** (commit 4be0445d): "cc-isolated-functions all pass" is false at 4be0445d: the parity test fails, 181/182, until cc2640b7. History only. Fixing it needs a history rewrite or a note in the landing summary.
- **Claim 38** (commit 4be0445d): the "tampered cc-push.sh … refused without running" test was an inert comment at that commit. 2cb03f23 corrects this but cites the pre-re-stack hash 840f39b0.
- **Claim 39** (commit 2cb03f23): "asserts it never ran" could not fail (touch at end of file, after main's exit). f737ba71 corrects this. History only.

### Stale
- **Claim 32** (`test/cc-isolated-functions.bats:1075`): `!= *"cc-push refuses"*` has been vacuous since afe1ae59 renamed the --list line to "cc-push: CHANGED …". Mutant P1 survives. Assert `!= *"cc-push: CHANGED"*` (or `!= *"cc-push:"*`) instead.

### Mostly Accurate
- **Claim 8b** (`devcontainer-config/cc-isolated.sh:275-278`): "although bless exited 1" holds for a failed rename. An interrupt between the renames exits 130.
- **Claim 40** (commit afe1ae59): only one recorded probe script (`fc-q089a1/probe.sh`) got the shellcheck disable line, not "scripts".

### Unverifiable
- None. Live container effects ("causes no rebuild", the probe on the next launch) are scoped out of Claims 4 and 15, not verdicted.

---

## Goal-Alignment Note

The code at afe1ae59 does what the PR description says. Host tools leave the boundary manifest: the bless writes host-tools.sha256 and manifest.sha256 via temp files and prints what changed, and a host-only re-bless leaves manifest.sha256 byte-identical. The launcher checks scan+gitdir before sourcing and refuses everything but --bless and --list. Its refusal names every reason, runs the boundary check with its diff, and gives a bless hint naming the dir. It only warns on a changed cc-push. cc-push checks itself and cc-gitdir.sh before sourcing and exits 1 before parsing, --help included. The two verify_host_tools copies are identical below their marker line, pinned by a test that has been seen to fail. Only a positively marked repo checkout is exempt. An upgrade from an install without host-tools.sha256 blesses cleanly via install.sh's `--bless` call. Every new test except one fails when the behaviour it names is broken (mutants P2, P3 and P4 killed). The exception is the last negative assertion of the --list test (Claim 32), which went vacuous in the final iteration's rewording. That is a one-line test fix, not a behaviour defect. The three Incorrect verdicts are in superseded commit messages that later commits on the branch correct. The cross-unit references (row 71, `Host-tool-tested:` in live-verify-gate.sh) resolve only in unit B, which matches the stated A1+A2-then-B landing order. They would dangle if A landed without B.
