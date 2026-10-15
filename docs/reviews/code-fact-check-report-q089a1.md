# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-q089)
**Commit:** b3b37e16
**Replication:** k=1 (loop pass, decision 031)
**Scope:** `git diff f2533b33 b3b37e16` (feat/q089a1-host-tool-manifest, iteration-1 fix delta): `devcontainer-config/cc-isolated.sh`, `test/cc-isolated-functions.bats`, the b3b37e16 commit message, and the rubric `docs/reviews/code-review-rubric-2026-10-14-feat-q089a1-host-tool-manifest.md` A1-A6 status cells. f2533b33 is committed context; A2 (feat/q089a2b-cc-push-self-check) and B (feat/q089b3-host-tool-gate) are sibling context only. Iteration 2 of 3.
**Checked:** 2026-10-14
**Total claims checked:** 17
**Summary:** 12 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution provenance for every `executed` claim: probe root `/home/node/.claude/jobs/00bcf178/tmp/fc-a1-it2.3M42ES` (`src/` = `git archive b3b37e16`), run as uid 1000 (not root) under `env -i PATH=/usr/bin:/bin`, `HOME`/`TMPDIR`/`CLAUDE_DEVC_CONFIG_DIR` inside the probe root, `LC_ALL=C`, `devcontainer` stubbed to `exit 0`, every command under `timeout`. Commands, exit codes and timestamps: `docs/reviews/execution-logs/fc-q089a1-it2/suites.txt`. No real config dir was touched and install.sh was not run. Hallucination pattern log read; no claim below matches a logged pattern.

---

## Claim 1: "DIR is the directory to check: an entry point's own resolved directory (`--list` passes config_dir())."

**Location:** `devcontainer-config/cc-isolated.sh:223-224`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every caller of `verify_host_tools` in cc-isolated.sh at b3b37e16; does not establish the cc-push.sh caller, which does not exist at b3b37e16 (it arrives with A2, `cc-push.sh:198`, passing `$CC_PUSH_DIR`).

The five callers in the file pass either the launcher's resolved dir or `--list`'s resolved config dir:

```bash
# devcontainer-config/cc-isolated.sh:496-498
cfg_real="$(readlink -f -- "$(config_dir)")" || cfg_real="$(config_dir)"
lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true
perr="$(verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh)" || true
# :707-709
CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
```

`:756` and `:769` also pass `"$CC_ISOLATED_DIR"` (`push_err="$(verify_host_tools "$CC_ISOLATED_DIR" cc-push.sh)"`). `--list` passes `readlink -f` of `config_dir()`, falling back to the unresolved path, so "passes config_dir()" is accurate up to resolution. (The neighbouring, unchanged `:219-220` "KEEP IN STEP with the copy in cc-push.sh (a test compares the two byte for byte)" names a copy and a test that exist only from A2 on (`git grep` at b3b37e16 finds neither); the merge constraint covers this.)

**Evidence:** `devcontainer-config/cc-isolated.sh:219-230`, `devcontainer-config/cc-isolated.sh:496-498`, `devcontainer-config/cc-isolated.sh:707-709`, `devcontainer-config/cc-isolated.sh:756`, `devcontainer-config/cc-isolated.sh:769`

---

## Claim 2: The format check `grep -qvE '^[0-9a-f]{64}  [A-Za-z0-9._-]+$'` accepts every manifest `compute_host_tools_manifest` writes

**Location:** `devcontainer-config/cc-isolated.sh:244`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the manifest bless writes for the current `host_tool_files` list (three names, GNU sha256sum text mode); does not establish acceptance for a future host-tool name outside `[A-Za-z0-9._-]` (sha256sum would also escape a name holding `\` or a newline) or behaviour under a non-C locale's bracket ranges.

The writer is fixed-format: `(cd "$(config_dir)" && sha256sum "${files[@]}")` (`devcontainer-config/cc-isolated.sh:216`) over `echo "cc-exit-scan.sh"`, `echo "cc-gitdir.sh"`, `echo "cc-push.sh"` (`:200-202`). Executed: a fresh bless's manifest (probe Q2a, shown with `cat -A`, three `<64 hex>  <name>$` lines) passes `verify_host_tools` with rc=0, and Q2k confirms every `host_tool_files` name matches `[A-Za-z0-9._-]+`. A manifest without a trailing newline is also accepted (Q2c rc=0); bless never writes one.

Command: `timeout 300 env -i PATH=/usr/bin:/bin bash docs/reviews/execution-logs/fc-q089a1-it2/probe.sh $P`, cwd the probe root, exit 0, 2026-10-15T00:50:46Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:199-217`, `devcontainer-config/cc-isolated.sh:244`, docs/reviews/execution-logs/fc-q089a1-it2/probe.out (Q2a, Q2c, Q2k)

---

## Claim 3a: "an unreadable or malformed host-tools.sha256 is named as the problem instead of calling every tool changed" (unreadable file; a line not in sha256sum's format)

**Location:** `devcontainer-config/cc-isolated.sh:242-247`; commit b3b37e16 message, bullet A2; rubric A2
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a mode-000 manifest read by a non-root user and manifests containing a CRLF line, a blank line, a `*` binary-mode marker or a junk line; does not establish the root case (where `-r` is always true and grep reads the file, so it falls to the format check) or the structural anomalies in Claim 3b.

```bash
# devcontainer-config/cc-isolated.sh:244-247
  if [ ! -r "$m" ] || grep -qvE '^[0-9a-f]{64}  [A-Za-z0-9._-]+$' "$m"; then
    echo "host-tool manifest $m is unreadable or malformed: inspect it before any bless overwrites it"
    return 1
  fi
```

Executed as uid 1000: mode 000 (Q2h), CRLF (Q2e), a trailing blank line (Q2d) and `*`-marker lines (Q2i) each print only the "unreadable or malformed" line, rc=1, and no "changed since the last bless" line. Through `--list` (Q3f) the same reason reaches both the "launches refuse:" and "cc-push refuses:" lines. Provenance as Claim 2.

**Evidence:** `devcontainer-config/cc-isolated.sh:242-247`, docs/reviews/execution-logs/fc-q089a1-it2/probe.out (Q2d, Q2e, Q2h, Q2i, Q3f)

---

## Claim 3b: Same claim, for a manifest that is "not sha256sum's own output" in content rather than line format

**Location:** `devcontainer-config/cc-isolated.sh:242-243`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an empty manifest, a duplicated entry and a dropped entry; does not establish anything about the line-format cases (Claim 3a).

The check is per line: `grep -v` has no line to report on an empty file, and a duplicated or missing entry is well-formed line by line. Those fall through to the per-file loop, whose `awk ... END { if (n == 1) print h }` (`devcontainer-config/cc-isolated.sh:257`) yields an empty `want`, giving "changed since the last bless". Executed: an empty file reports all three tools changed (Q2b), which is the outcome the comment says the check prevents. A duplicated first entry (Q2f) and a dropped first entry (Q2g) each report `cc-exit-scan.sh changed since the last bless`. The precise version: "a manifest that cannot be read, or that has any line not in sha256sum's text-mode format, is named as the problem; an empty manifest or a missing or duplicated entry is still reported per tool as changed." Provenance as Claim 2.

**Evidence:** `devcontainer-config/cc-isolated.sh:242-264`, docs/reviews/execution-logs/fc-q089a1-it2/probe.out (Q2b, Q2f, Q2g)

---

## Claim 4: "every bless hint goes through bless_cmd ..., so a hint never blesses the default dir by mistake"

**Location:** commit b3b37e16 message, bullet A1; rubric A1 status ("every hint goes through `bless_cmd`"); counterexample at `devcontainer-config/cc-isolated.sh:239`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `--bless` hint in cc-isolated.sh at b3b37e16 and its reachable outputs; does not establish cc-push.sh's hint, which arrives with A2 and prints its own `CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless` form (`cc-push.sh:203` on feat/q089a2b-cc-push-self-check).

The new hints at `:500`, `:504` and `:760` and check_manifest's at `:332` and `:341` call `$(bless_cmd)`. One literal hint survives in the byte-copied `verify_host_tools`:

```bash
# devcontainer-config/cc-isolated.sh:238-241
  if [ ! -f "$m" ] || [ -L "$m" ]; then
    echo "no host-tool manifest at $m (re-run install.sh, or cc-isolated --bless after reviewing)"
    return 1
  fi
```

Executed: with `host-tools.sha256` a symlink to a good manifest under a non-default `CLAUDE_DEVC_CONFIG_DIR`, `--list` prints the `bless_cmd` form on the header line and the bare `cc-isolated --bless` on both reason lines (Q3d). The same reason line reaches the refusal at `:748`. Run as written from a shell where the dir was given as a prefix assignment, it blesses the default dir. In every A1 output examined, the `bless_cmd` form also appears in the same block, so the practical risk is low. Still, "every" is false, and a reader who trusts it would not look at `:239`. Provenance as Claim 2.

**Evidence:** `devcontainer-config/cc-isolated.sh:238-241`, `devcontainer-config/cc-isolated.sh:318-324`, `devcontainer-config/cc-isolated.sh:332`, `devcontainer-config/cc-isolated.sh:341`, `devcontainer-config/cc-isolated.sh:500-510`, `devcontainer-config/cc-isolated.sh:748`, `devcontainer-config/cc-isolated.sh:760`, docs/reviews/execution-logs/fc-q089a1-it2/probe.out (Q3d)

---

## Claim 5: Bless's host block shows the entry count: "Blessed host tools in … (N entries; not boundary config, no probe needed)"

**Location:** `devcontainer-config/cc-isolated.sh:303`; rubric A3
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count printed after a successful bless; does not establish the wording of the boundary block, which is unchanged.

`echo "Blessed host tools in $(host_tools_path) ($(wc -l < "$(host_tools_path)") entries; not boundary config, no probe needed):"` (`:303`) runs after `mv -f "$new_h" "$(host_tools_path)"` (`:298`), so it counts the file just installed. Executed: `... host-tools.sha256 (3 entries; not boundary config, no probe needed):` (Q1). Provenance as Claim 2.

**Evidence:** `devcontainer-config/cc-isolated.sh:298-304`, docs/reviews/execution-logs/fc-q089a1-it2/probe.out (Q1)

---

## Claim 6: The refusal's hint `$(CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" bless_cmd)` names the launcher's dir, so pasting it blesses that dir

**Location:** `devcontainer-config/cc-isolated.sh:760`, `devcontainer-config/cc-isolated.sh:316-324`; commit bullet A1 ("the refusal with the launcher's dir")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a launcher run directly by path with `CLAUDE_DEVC_CONFIG_DIR` naming a different dir; does not establish the hint's `$0` when the launcher is reached through a PATH symlink (`$0` is then the symlink path, which still resolves to the same copy), or architecture F1's single dir owner (rubric C1).

```bash
# devcontainer-config/cc-isolated.sh:318-323
bless_cmd() {
  if [ -n "${CLAUDE_DEVC_CONFIG_DIR:-}" ]; then
    printf 'CLAUDE_DEVC_CONFIG_DIR=%q %s --bless' "$CLAUDE_DEVC_CONFIG_DIR" "$0"
  else
    printf '%s --bless' "$0"
  fi
```

In bash, a prefix assignment on a function call applies for the length of that call, and the `$(...)` subshell contains it anyway, so the override cannot leak. Executed (Q1): with `CLAUDE_DEVC_CONFIG_DIR=$P/q1/other` and the launcher in `$P/q1/inst`, the refusal printed `CLAUDE_DEVC_CONFIG_DIR=$P/q1/inst $P/q1/inst/cc-isolated.sh --bless`. `eval` of that exact line exited 0. `--list` on the launcher dir then showed `Host tools — match the bless (...)`, and `$P/q1/other` gained no `host-tools.sha256`. Provenance as Claim 2.

**Evidence:** `devcontainer-config/cc-isolated.sh:316-324`, `devcontainer-config/cc-isolated.sh:759-760`, docs/reviews/execution-logs/fc-q089a1-it2/probe.out (Q1)

---

## Claim 7: "an entry point checks its own dir, which differs whenever the command run is not the copy in config_dir() (a repo checkout, or CLAUDE_DEVC_CONFIG_DIR naming another dir or unset for a custom install)"

**Location:** `devcontainer-config/cc-isolated.sh:489-492`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how the launcher's checked dir (`CC_ISOLATED_DIR`) relates to `--list`'s (`config_dir()` resolved); does not establish that the parenthetical lists every case (it is illustrative, and the general condition before it is the claim).

The launcher checks `CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"` (`:707`). `--list` checks `readlink -f` of `config_dir()`, which is `echo "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"` (`:68-70`). Both are resolved, so they differ exactly when the script that runs is not the copy in the config dir. The three named cases each produce that: a checkout's `devcontainer-config/`, an override naming a different dir, or no override (so the default) while the copy lives elsewhere.

**Evidence:** `devcontainer-config/cc-isolated.sh:68-70`, `devcontainer-config/cc-isolated.sh:487-498`, `devcontainer-config/cc-isolated.sh:707`

---

## Claim 8: `--list` shapes: "No blessed host tools (… run: <bless_cmd>)", "Host tools — match the bless (…)", "Host tools — CHANGED (…)"

**Location:** `devcontainer-config/cc-isolated.sh:499-511`; commit bullet A3/A4; rubric A3
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three branches with a regular manifest, a missing one, a CHANGED and a malformed state, with the override set and unset; does not establish the symlink cases, where a dangling-symlink manifest is reported as "No blessed host tools" (`! -e` follows the link) rather than as the symlink anomaly `verify_host_tools` names.

```bash
# devcontainer-config/cc-isolated.sh:499-504
  if [ ! -e "$(host_tools_path)" ]; then
    echo "No blessed host tools (review them, then run: $(bless_cmd))."
  elif [ -z "$lerr" ] && [ -z "$perr" ]; then
    echo "Host tools — match the bless ($(host_tool_files | tr '\n' ' ' | sed 's/ $//'))"
  else
    echo "Host tools — CHANGED (review, then run: $(bless_cmd))"
```

Executed: match → `Host tools — match the bless (cc-exit-scan.sh cc-gitdir.sh cc-push.sh)` (Q3a). Missing → `No blessed host tools (review them, then run: CLAUDE_DEVC_CONFIG_DIR=<dir> <dir>/cc-isolated.sh --bless).` (Q3b). With the override unset it prints `<path>/cc-isolated.sh --bless` with no assignment, which blesses the default dir `--list` checked (Q3g). CHANGED prints the header plus "launches refuse:" and "cc-push refuses:" lines (Q3e). A dangling symlink → "No blessed host tools" (Q3c). The bats suite pins all three shapes (`test/cc-isolated-functions.bats:991`, `:1034`, `:1038`), all passing. Provenance as Claim 2.

**Evidence:** `devcontainer-config/cc-isolated.sh:499-511`, `test/cc-isolated-functions.bats:987-993`, `test/cc-isolated-functions.bats:1028-1040`, docs/reviews/execution-logs/fc-q089a1-it2/probe.out (Q3a-Q3g)

---

## Claim 9: "main refuses every action but --bless and --list (--help and usage errors are answered first; neither touches the scan)"

**Location:** `devcontainer-config/cc-isolated.sh:705-706`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--help`, `-h`'s shared branch, an unknown flag, a bare `--profile`, `--list`, `--register`, `--probe-only` and a launch, all with a tampered cc-exit-scan.sh; does not establish that `--bless`/`--list` themselves never call a scan function (static: `bless_manifest` and `list_projects` call none).

The argument loop exits before the refusal at `:746`: `--help|-h)    usage; exit 0 ;;` (`:739`), `-*)  echo "ERROR: unknown flag: $1" >&2; usage >&2; exit 2 ;;` (`:741`), and the bare `--profile` branch's `exit 2` (`:733-737`). Executed (probe2): `--help` rc=0 printing usage, `--bogus` rc=2, `--profile` rc=2, `--list` rc=0, and `--register`, `--probe-only` and a launch each rc=1 with the refusal line. Command: `timeout 300 env -i PATH=/usr/bin:/bin bash docs/reviews/execution-logs/fc-q089a1-it2/probe2.sh $P`, exit 0, 2026-10-15T00:52:37Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:722-746`, docs/reviews/execution-logs/fc-q089a1-it2/probe2.out

---

## Claim 10: "ERROR: host tools differ from the bless — refusing to launch, probe or register:"

**Location:** `devcontainer-config/cc-isolated.sh:747`; rubric A4
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the set of actions that reach this branch; does not establish the layout of what follows (Claim 11).

`action` is one of `launch` (default, `:723`), `bless`, `probe`, `register`, `list` (`:727-730`). The guard `[ "$action" != "bless" ] && [ "$action" != "list" ]` (`:746`) leaves exactly launch, probe and register, the three verbs the message names. probe2 confirms all three refuse with this line.

**Evidence:** `devcontainer-config/cc-isolated.sh:723-730`, `devcontainer-config/cc-isolated.sh:746-747`, docs/reviews/execution-logs/fc-q089a1-it2/probe2.out

---

## Claim 11: "reasons print one per line under a fixed ERROR line" (and "--list and the cc-push line join them with '; '")

**Location:** `devcontainer-config/cc-isolated.sh:747-748`, `devcontainer-config/cc-isolated.sh:757`; commit bullet A2; rubric A2
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal with two failing launcher files and a changed cc-push; does not establish layout when check_manifest's boundary diff is interleaved (it prints between the reasons and the "also changed" line).

```bash
# devcontainer-config/cc-isolated.sh:747-748
    echo "ERROR: host tools differ from the bless — refusing to launch, probe or register:" >&2
    printf '  %s\n' "$HOST_TOOLS_ERR" >&2
```

`printf` gets one argument, a string with embedded newlines, so only the first reason gets the two-space indent. Executed (Q1, `cat -A`):

```
  .../q1/inst/cc-exit-scan.sh changed since the last bless$
.../q1/inst/cc-gitdir.sh changed since the last bless$
  also changed (cc-push refuses until re-blessed): .../q1/inst/cc-push.sh changed since the last bless$
```

The reasons do print one per line under the fixed ERROR line, but the second starts at column 0 and so reads as outside the block. The "; " join is accurate: `:757` uses `"${push_err//$'\n'/; }"`, and `:506`/`:510` do the same for `--list`. Precise version: "reasons print one per line under a fixed ERROR line, the first indented". Provenance as Claim 2.

**Evidence:** `devcontainer-config/cc-isolated.sh:747-761`, `devcontainer-config/cc-isolated.sh:506`, `devcontainer-config/cc-isolated.sh:510`, docs/reviews/execution-logs/fc-q089a1-it2/probe.out (Q1, lines 3-9)

---

## Claim 12: "The boundary config is unchanged: the re-bless changes no boundary state, so it causes no rebuild (a config not yet verified live is still probed at its next launch, as before)."

**Location:** `devcontainer-config/cc-isolated.sh:751`; rubric A5 (fourth correction)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch taken when `check_manifest` passes for `CC_ISOLATED_DIR` and the bless named by Claim 6 then runs; does not establish that an already verified config skips probing (every launch probes, `:893`), or anything about the pre-existing NOTE at `:865-868`, which says an unverified run "is rebuilt" although the launch path rebuilds only on a hash mismatch (`:885-888`).

The note prints only when `CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" check_manifest` passes (`:752`), meaning `compute_manifest` equals the blessed manifest. A rebuild is triggered only by `if ! container_config_matches "${dc[@]}"; then` (`:885`), which compares the baked hash with `blessed_hash`, i.e. `sha256sum < "$m" | cut -c1-16` (`:92`). Executed (Q4): bless, `record_verified_live`, tamper cc-exit-scan.sh. The refusal printed this note, then re-bless printed the same `Blessed config: 8e85c68afeb27132` and `Verified live:  yes`, reported only `Changed since the last bless (host-tools.sha256):`, and left `manifest.sha256` byte-identical. "Still probed at its next launch" holds because `probe_boundary` runs on every launch (`if ! probe_boundary "$ws"; then`, `:893`) and `--probe-only` always probes (`:872-877`). Provenance as Claim 2.

**Evidence:** `devcontainer-config/cc-isolated.sh:88-108`, `devcontainer-config/cc-isolated.sh:751-754`, `devcontainer-config/cc-isolated.sh:864-893`, docs/reviews/execution-logs/fc-q089a1-it2/probe.out (Q4)

---

## Claim 13: Test "verify_host_tools: an unreadable or malformed host manifest is named as the problem" (rubric A2: "New test")

**Location:** `test/cc-isolated-functions.bats:995-1002`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test detects; does not establish runtime behaviour, which Claim 3a checks directly.

The test exercises only the malformed half: `printf 'not a sha256sum line\r\n' >> "$(host_tools_path)"` (`:997`). Executed mutation (mut.sh): a mutant without the format check fails the test (`[ "$status" -eq 1 ]` failed, line 999). A mutant without only `[ ! -r "$m" ]` passes it, so the "unreadable" half of the name has no test. Precise version: the test pins the malformed-line case; the unreadable case is untested (runtime-verified in Claim 3a, as non-root). Command: `timeout 500 env -i PATH=/usr/bin:/bin bash docs/reviews/execution-logs/fc-q089a1-it2/mut.sh $P`, cwd the probe root, exit 0, 2026-10-15T00:51:30Z.

**Evidence:** `test/cc-isolated-functions.bats:995-1002`, docs/reviews/execution-logs/fc-q089a1-it2/mut.sh, docs/reviews/execution-logs/fc-q089a1-it2/mut.out

---

## Claim 14: "the bless-failure test now checks both manifests against a different Dockerfile" (comment: "so a rewritten boundary manifest would show")

**Location:** `test/cc-isolated-functions.bats:1014-1022`; commit bullet A5/A6; rubric A6
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a mutant that installs the new boundary manifest before the host-tool computation fails; does not establish detection of a split between the two final `mv` calls (`:298-299`), which the test does not exercise.

```bash
# test/cc-isolated-functions.bats:1016-1022
  echo 'FROM node:23' > "$CLAUDE_DEVC_CONFIG_DIR/Dockerfile"
  rm "$CLAUDE_DEVC_CONFIG_DIR/cc-gitdir.sh"
  run bless_manifest
  [ "$status" -ne 0 ]
  [[ "$output" == *"host tool missing: cc-gitdir.sh"* ]]
  [ "$(cat "$(host_tools_path)")" = "$h" ]
  [ "$(cat "$(manifest_path)")" = "$m" ]
```

Executed mutation (mut.sh): with bless_manifest changed to `cp "$new_m" "$(manifest_path)"` before `compute_host_tools_manifest`, the b3b37e16 test fails at line 1022. The f2533b33 version of the test passes against the same mutant. The b3b37e16 test passes against unmutated code. Provenance as Claim 13.

**Evidence:** `test/cc-isolated-functions.bats:1004-1026`, `devcontainer-config/cc-isolated.sh:276-299`, docs/reviews/execution-logs/fc-q089a1-it2/mut.out

---

## Claim 15: "Tests under LC_ALL=C: cc-isolated-functions 181/181."

**Location:** commit b3b37e16 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suite at b3b37e16 in a plain `git archive` extract with stubbed devcontainer/pgrep/docker; does not establish install-host.bats, which the commit does not claim this round, or any live Docker path.

Command: `env -i PATH=/usr/bin:/bin HOME=$P/home TMPDIR=$P/tmp CLAUDE_DEVC_CONFIG_DIR=$P/home/cfg LC_ALL=C timeout 600 bats test/cc-isolated-functions.bats`, cwd `$P/src`, exit 0, 2026-10-15T00:47:55Z..00:50:10Z. The output's plan line is `1..181` with 181 `ok` and 0 `not ok`, and `bats --count` gives 181. f2533b33's run was 180 (`docs/reviews/execution-logs/fc-q089a1/suites.txt`); the +1 is the new test in Claim 13.

**Evidence:** docs/reviews/execution-logs/fc-q089a1-it2/cc-isolated-functions.log, docs/reviews/execution-logs/fc-q089a1-it2/suites.txt, `test/cc-isolated-functions.bats:995`

---

## Claim 16: "A1 is 418 lines after this round (392 when the loop started)."

**Location:** commit b3b37e16 message (Notes); rubric footer
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers insertions plus deletions outside `docs/` from base `4ab9a51f`; does not establish that this is the counting rule decision log 62 specifies (inferred because it reproduces both figures).

paraphrased — no quote available because the figure is a sum over `git diff --numstat` rows. Excluding `docs/`, `4ab9a51f..f2533b33` is 370+22 = 392 and `4ab9a51f..b3b37e16` is 396+22 = 418 (cc-isolated.sh 190/11, bats 198/6, cc-exit-scan.sh 3/2, cc-gitdir.sh 3/2, install.sh 2/1). 418 is over the 400 cap. The rubric says the cap is checked before the loop, and the commit states the number openly.

**Evidence:** `devcontainer-config/cc-isolated.sh:1`, `test/cc-isolated-functions.bats:1` (numstat over both files and three others)

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`devcontainer-config/cc-isolated.sh:239`): "every bless hint goes through bless_cmd" is false. verify_host_tools' "no host-tool manifest" reason still says a bare `cc-isolated --bless`, and it reaches `--list` and the refusal (in both, a `bless_cmd` line also appears). Fix the hint, or narrow the claim to "every hint outside the byte-copied verify_host_tools".

### Mostly Accurate
- **Claim 3b** (`devcontainer-config/cc-isolated.sh:242-243`): the check is per line. An empty manifest, or a missing or duplicated entry, is still reported as every affected tool "changed".
- **Claim 11** (`devcontainer-config/cc-isolated.sh:748`): `printf '  %s\n' "$HOST_TOOLS_ERR"` indents only the first reason; later reasons start at column 0.
- **Claim 13** (`test/cc-isolated-functions.bats:995`): the test name says "unreadable or malformed" but it pins only malformed. Dropping `[ ! -r "$m" ]` passes it.

---

## Goal-Alignment Note

The goal is to land a security-sensitive trust-manifest change whose messages a user can act on safely. The iteration-1 fixes mostly do what the commit says, checked by running them: the refusal's hint blesses the launcher's dir and leaves another dir alone, the bless-failure test now catches a boundary-manifest rewrite the old test missed, the boundary note's "no rebuild" holds byte for byte, and 181/181 reproduces. The finding that matters for A1's own goal is Claim 4: one bare `cc-isolated --bless` hint survives inside the byte-copied `verify_host_tools`. That is the hint class A1 set out to remove. A fix there must change cc-push.sh's copy in A2 in step, or the parity test fails. Claims 3b, 11 and 13 are smaller: a gap in what counts as malformed, an indentation slip, and an untested branch. None changes what the gate refuses. Under the merge constraint (A1 lands only with A2 and B), the `:219` "KEEP IN STEP ... a test compares" comment is accurate as landed, though not at A1 alone.
