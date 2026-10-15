Commit: afe1ae59

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q089 (branch feat/q089a2b-cc-push-self-check)
**Scope:** `git diff 4ab9a51f afe1ae59 -- devcontainer-config test` (units A1+A2, final confirming pass, replicate r1), plus the commit messages `git log 4ab9a51f..afe1ae59`. Sibling unit B (/workspace/.claude/wt-q089b, HEAD 79f22357, stacked on afe1ae59) read for row 71 and `Host-tool-tested:`.
**Checked:** 2026-10-14 (probes 2026-10-15T01:32Z-01:40Z UTC)
**Total claims checked:** 33
**Summary:** 25 verified, 3 mostly accurate, 1 stale, 4 incorrect, 0 unverifiable

Execution environment for every `executed` claim: a fresh `git archive afe1ae59` tree at `/home/node/.claude/jobs/00bcf178/tmp/fcfinal.wNrXNM` (called `$P` below). HOME, TMPDIR, CLAUDE_DEVC_CONFIG_DIR and CC_PUSH_CLONES_DIR pointed into `$P`, `LC_ALL=C`, devcontainer stubbed or absent. Probe scripts and raw output are copied to `docs/reviews/execution-logs/fc-q089a-final-r1/`. Mutants are copies under `$P/_tmp/mut-*`. In the logs, exit status 141 comes from the `| head` the probe piped into (SIGPIPE), not from the code under test. In the full-suite mutant runs, tests 68-72 ("Gate 1h ...") fail because the mutant tree copies only `devcontainer-config/` and `test/`. They pass in the real tree, so they are an artefact of the probe and not a finding.

Hallucination-pattern log consulted. The relevant pattern is "a specific measured value quoted from an artifact set that does not contain it" (test-count entries, 2026-09-12 and 2026-09-25). Every suite count in the commit messages was re-measured (Claims 30-31). None matches the pattern.

---

## Claim 1: "it is a host tool (decision log row 71), so the bless hashes it into host-tools.sha256, not the boundary manifest, and cc-isolated.sh checks it against that file before sourcing it."

**Location:** `devcontainer-config/cc-exit-scan.sh:4-6`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hashing destination and the launcher's check-before-source on an installed copy. It does not establish anything for a repo checkout, which is deliberately unchecked (Claim 5). Row 71 resolves only in unit B.

`host_tool_files` lists it (`cc-isolated.sh:199-203`: `echo "cc-exit-scan.sh"` …) and `enforcement_files` no longer does (`cc-isolated.sh:128-136`). The source is gated: `if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then … source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` (`cc-isolated.sh:716-718`). Executed: the test "launch: a tampered cc-exit-scan.sh is never sourced" passes. Row 71 exists in unit B: `docs/decisions/log.md:94` at 79f22357, "**Host-only tools are their own trust category, amending row 45's scope**".

**Evidence:** `devcontainer-config/cc-isolated.sh:199-203`, `devcontainer-config/cc-isolated.sh:714-721`, `docs/reviews/execution-logs/fc-q089a-final-r1/cc-isolated-functions.tap`; command `env HOME=$P/_home TMPDIR=$P/_tmp CLAUDE_DEVC_CONFIG_DIR=$P/_cfg CC_PUSH_CLONES_DIR=$P/_clones LC_ALL=C timeout 900 bats test/cc-isolated-functions.bats`, cwd `$P`, exit 0, 2026-10-15T01:32:23Z

---

## Claim 2: "hashed into host-tools.sha256. Both entry points check it against that file before it is sourced: cc-push for itself, the launcher for cc-exit-scan.sh."

**Location:** `devcontainer-config/cc-gitdir.sh:5-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both source sites and the checks ahead of them. It does not establish behaviour for a repo checkout (unchecked by design).

cc-exit-scan.sh sources it (`cc-exit-scan.sh:12`: `source "$(dirname -- …)/cc-gitdir.sh"`), and the launcher checks `cc-exit-scan.sh cc-gitdir.sh` before that source (`cc-isolated.sh:716`). cc-push checks it before its own source: `if ! host_tools_err="$(verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh)"; then … exit 1` then `source "$CC_PUSH_DIR/cc-gitdir.sh"` (`cc-push.sh:204-214`). Executed: the cc-push.bats test asserts that a `touch` appended to cc-gitdir.sh never runs (`[ ! -e "$M/gitdir-ran" ]`), and it passes.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:11-12`, `devcontainer-config/cc-push.sh:203-214`, `docs/reviews/execution-logs/fc-q089a-final-r1/cc-push.tap` (same env as Claim 1, `bats test/cc-push.bats`, exit 0)

---

## Claim 3: "Keep this list and host_tool_files (below) in step with install.sh's PAYLOAD … a bats test now pins PAYLOAD ⊆ this list ∪ host_tool_files, the two disjoint)."

**Location:** `devcontainer-config/cc-isolated.sh:118-121`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers subset, disjointness, the exact host list and the no-COPY rule as the test asserts them. It does not establish the reverse direction for host tools (that every host tool is in PAYLOAD), which the test does not assert.

The test checks disjointness (`if echo "$enf" | grep -qx "$item"; then echo "in both lists: $item"; return 1; fi`), the subset (`printf '%s\n%s\n' "$enf" "$host" | grep -qx "$item" || { echo "PAYLOAD item not hashed: $item"; return 1; }`) and that no image COPY source is a host tool (`test/cc-isolated-functions.bats:846-861`). It passes.

**Evidence:** `test/cc-isolated-functions.bats:835-867`, `devcontainer-config/install.sh:110`, `cc-isolated-functions.tap`

---

## Claim 4: "They run on the host … the image never copies them … a change to one leaves blessed_hash …, the verified-live receipt and the container alone. Each entry point checks the ones it executes … Commits that change them carry `Host-tool-tested:`, not `Live-verified:` (hooks/live-verify-gate.sh)."

**Location:** `devcontainer-config/cc-isolated.sh:191-198`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Dockerfile COPY list, blessed_hash being unchanged after a host-tool edit, and the gate trailer as it stands in unit B (79f22357). It does not establish the gate at afe1ae59 itself, where hooks/live-verify-gate.sh is unchanged. The trailer statement is true only once B lands, and the stack lands together.

The Dockerfile COPYs only `egress/`, `init-firewall.sh`, `cc-sni-proxy.py`, `link-claude-home.sh` and `claude-home/` (`Dockerfile:486-500`). The test "bless writes host-tools.sha256; a host-tool edit leaves the boundary manifest and blessed hash alone" asserts `[ "$(blessed_hash)" = "$before" ]` after editing cc-push.sh, and it passes. Unit B's gate has `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'` and `need+=("Host-tool-tested")` (`hooks/live-verify-gate.sh:91,154` at 79f22357). Its header says "a `Live-verified:` trailer does not satisfy them".

**Evidence:** `devcontainer-config/Dockerfile:486-500`, `test/cc-isolated-functions.bats:869-884`, wt-q089b `hooks/live-verify-gate.sh:23-27,84-93,152-154`, `cc-isolated-functions.tap`

---

## Claim 5: "Only a repo checkout is left unchecked, and it must say so positively: install.sh beside the script (install.sh is never installed, it is not in PAYLOAD), no manifest of either kind, and not the config dir. Anything else is checked, so deleting manifests is not enough to opt an installed copy out."

**Location:** `devcontainer-config/cc-isolated.sh:224-229` (byte-identical copy at `devcontainer-config/cc-push.sh:151-156`)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four-part exemption condition in code and the claim that install.sh is not installed. Test coverage of the "not the config dir" clause is a separate claim (Claim 24b). An attacker who adds an install.sh is outside decision 45's non-targeted model and is not assessed here.

```bash
# devcontainer-config/cc-isolated.sh:235-237
if [ -f "$dir/install.sh" ] && [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
  return 0
fi
```
PAYLOAD does not include install.sh: `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress claude-home)` (`install.sh:110`). Executed: the cc-push.bats case "Deleting the host manifest does not turn the installed copy into a repo checkout" passes (exit 1, "no host-tool manifest"). The comment's "(`--list` passes config_dir())" is exact only up to resolution: --list passes `readlink -f` of it (`cc-isolated.sh:501`).

**Evidence:** `devcontainer-config/cc-isolated.sh:230-270`, `devcontainer-config/install.sh:110`, `test/cc-push.bats:821-827`, `cc-push.tap`

---

## Claim 6: "The manifest itself is the anomaly when it cannot be read or is not sha256sum's own output; say so rather than call every tool changed."

**Location:** `devcontainer-config/cc-isolated.sh:245-246` (and cc-push.sh copy)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unreadable, empty, malformed and missing-entry manifests as the test exercises them. It does not establish handling of a manifest with valid lines naming extra files, which is accepted and has no effect.

`if [ ! -r "$m" ] || [ ! -s "$m" ] || grep -qvE '^[0-9a-f]{64}  [A-Za-z0-9._-]+$' "$m"; then echo "host-tool manifest $m is unreadable or malformed: …"; return 1` (`cc-isolated.sh:247-250`). The test asserts `!= *"changed since the last bless"*` on the malformed case and passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:245-250`, `test/cc-isolated-functions.bats:1006-1030`, `cc-isolated-functions.tap`

---

## Claim 7a: "Every file is checked and every mismatch named, so the refusal lists all of what the bless it points to would accept." (launcher copy)

**Location:** `devcontainer-config/cc-isolated.sh:251-252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher's refusal, which names the scan and gitdir changes, adds a cc-push-specific line and shows the boundary diff. It does not establish this for a manifest-level failure, where no individual tool is named (Claim 6 is the intended carve-out).

The loop `for f in "$@"` uses `continue` and never `return` per file. It sets `bad=1` and ends with `return "$bad"` (`cc-isolated.sh:253-269`). Executed (probe1): with cc-exit-scan.sh and cc-push.sh changed, the launch refusal printed `…/cc-exit-scan.sh changed since the last bless` and `also changed — do not run cc-push until re-blessed: …/cc-push.sh changed since the last bless`, and the bless then accepted exactly those two lines.

**Evidence:** `devcontainer-config/cc-isolated.sh:253-269`, `devcontainer-config/cc-isolated.sh:753-771`, `docs/reviews/execution-logs/fc-q089a-final-r1/probe1.sh`, `probe1.txt`; command `timeout 300 probe1.sh $P`, cwd per-run mktemp under `$P/_tmp`, exit 0, 2026-10-15T01:37:38Z

---

## Claim 7b: Same sentence, in cc-push.sh's byte-identical copy (cc-push's refusal "lists all of what the bless it points to would accept")

**Location:** `devcontainer-config/cc-push.sh:175-176`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what cc-push's refusal names compared with what `cc-isolated --bless` then accepts. It does not establish whether the user is misled in practice: the refusal's hint does say the bless "prints what changed".

cc-push checks only `cc-push.sh cc-gitdir.sh` (`cc-push.sh:204`), while the bless it points to (`CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless`, `cc-push.sh:210`) rewrites both manifests in full. Executed (probe1): with cc-exit-scan.sh and cc-push.sh both changed, `cc-push --help` printed only `…/cc-push.sh changed since the last bless`. The bless it named then accepted `< 933bcabe… cc-exit-scan.sh` / `> 50479e0e… cc-exit-scan.sh` as well. A boundary change would likewise go unnamed by cc-push and show up only in the bless's diff. Because the parity test pins the two blocks, the sentence cannot be fixed in one copy. It needs wording true of both, for example "names every mismatch among the files it is given".

**Evidence:** `devcontainer-config/cc-push.sh:176-200`, `devcontainer-config/cc-push.sh:203-212`, `probe1.txt` ("== cc-push --help with scan+push changed" and "== bless 2" sections)

---

## Claim 8a: "Both manifests are computed into temp files first and moved into place only when both succeed, so a bless that fails to compute either changes neither. … What changed since the previous bless is printed first"

**Location:** `devcontainer-config/cc-isolated.sh:272-273,278-280`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers compute failures of either manifest and the diff printed before the moves. It does not establish behaviour when `mktemp` or `mv` fails (Claim 8b).

`if ! compute_manifest > "$new_m" || ! compute_host_tools_manifest > "$new_h"; then rm -f "$new_m" "$new_h"; echo "ERROR: nothing blessed." >&2; return 1; fi` comes before the diff loop and `mv -f` (`cc-isolated.sh:286-304`). The test "bless: a failure changes neither manifest" covers both failure orders and the temp-file cleanup, and it passes. probe1 shows "Changed since the last bless (…)" and "No previous host-tools.sha256" before the "Blessed …" lines.

**Evidence:** `devcontainer-config/cc-isolated.sh:281-319`, `test/cc-isolated-functions.bats:1032-1054`, `probe1.txt`, `cc-isolated-functions.tap`

---

## Claim 8b: "The two same-directory renames can still split (one fails, or an interrupt lands between them): host-tools.sha256 is then new and manifest.sha256 old … although bless exited 1."

**Location:** `devcontainer-config/cc-isolated.sh:274-277`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of the two `mv` calls and the exit path under `set -e`. It does not establish any filesystem's rename atomicity.

The order is `mv -f "$new_h" "$(host_tools_path)"` then `mv -f "$new_m" "$(manifest_path)"` (`cc-isolated.sh:303-304`), so the stated split (host new, manifest old) arises only when the second rename fails or an interrupt lands between the two. If the first rename fails, `set -e` (main calls `bless) bless_manifest; exit 0`, `cc-isolated.sh:788`) exits with both files old and `$new_m` left behind. An interrupt exits 130, not 1. Precise version: "if the second rename fails, or an interrupt lands between them, host-tools.sha256 is new and manifest.sha256 old, although bless failed".

**Evidence:** `devcontainer-config/cc-isolated.sh:281-306`, `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-isolated.sh:787-790`

---

## Claim 9: "names CLAUDE_DEVC_CONFIG_DIR when it is set, so a hint printed for a non-default dir does not bless the default one."

**Location:** `devcontainer-config/cc-isolated.sh:321-322`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bless_cmd and its callers in check_manifest, list_projects and the refusal. It does not establish that `$0` is on PATH or invocable when the launcher was run through an unusual argv[0].

`printf 'CLAUDE_DEVC_CONFIG_DIR=%q %s --bless' "$CLAUDE_DEVC_CONFIG_DIR" "$0"` (`cc-isolated.sh:325`). The refusal wraps it as `$(CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" bless_cmd)` (`:768`). The probe1 refusal printed `CLAUDE_DEVC_CONFIG_DIR=…/cfg …/cfg/cc-isolated.sh --bless`. A grep of non-comment `--bless` strings in cc-isolated.sh finds only bless_cmd's two printfs and the flag parser.

**Evidence:** `devcontainer-config/cc-isolated.sh:323-329`, `devcontainer-config/cc-isolated.sh:336,346,505,509,768`, `probe1.txt`

---

## Claim 10: "Each entry point's file list: the launcher refuses on the two files it executes (and only warns on cc-push); cc-push refuses on itself and cc-gitdir.sh. Checked in config_dir(); an entry point checks its own dir, which differs whenever the command run is not the copy in config_dir()"

**Location:** `devcontainer-config/cc-isolated.sh:492-497`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two verify calls in list_projects and the entry points' own lists. It does not establish that --list reports per-entry-point state when host-tools.sha256 is absent (it prints only "No blessed host tools"), or for a dangling-symlink manifest, which `-e` treats as absent.

`lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true` / `perr="$(verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh)" || true` (`cc-isolated.sh:502-503`) match `cc-isolated.sh:716` and `cc-push.sh:204`. probe1's --list printed "launches refuse: …cc-exit-scan.sh changed…" and "cc-push: CHANGED — … cc-push.sh changed…".

**Evidence:** `devcontainer-config/cc-isolated.sh:481-532`, `probe1.txt` ("== --list")

---

## Claim 11: "Not a bare assignment: readlink -f fails when the dir's parent is missing, and under set -e that would end --list silently."

**Location:** `devcontainer-config/cc-isolated.sh:499-500`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parent-missing case. It does not establish other readlink failures (permission denied), which take the same fallback.

`cfg_real="$(readlink -f -- "$(config_dir)")" || cfg_real="$(config_dir)"` (`:501`). Mutant M6 removed `|| cfg_real="$(config_dir)"`, and the test "--list still reports everything when the config dir's parent is missing (set -e)" then failed at `[ "$status" -eq 0 ]`. So the test bites and the comment describes a real failure.

**Evidence:** `devcontainer-config/cc-isolated.sh:498-503`, `docs/reviews/execution-logs/fc-q089a-final-r1/mut.sh`, `M6.txt`; command `mut.sh $P M6-bareassign 's/ \|\| cfg_real="\$\(config_dir\)"//' cc-isolated.sh 'parent is missing'`, cwd `$P/_tmp/mut-M6-bareassign.*`, bats exit 1 (expected), 2026-10-15T01:38:59Z

---

## Claim 12: "An intact cc-push refuses on this; a copy that dropped its own check would not, so the line says what to do rather than predicting what cc-push does." / message "cc-push: CHANGED — do not run it until re-blessed (an intact copy refuses)"

**Location:** `devcontainer-config/cc-isolated.sh:515-517`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an intact cc-push refusing on the perr conditions. A copy without the check is trivially not refused by itself. It does not establish the case where --list's config dir differs from where the cc-push on PATH lives.

perr is computed on `cc-push.sh cc-gitdir.sh`, the same list cc-push checks (`cc-push.sh:204`). probe1: `cc-push --help` exited 1 under the same tamper that --list reported.

**Evidence:** `devcontainer-config/cc-isolated.sh:503,515-517`, `devcontainer-config/cc-push.sh:204-212`, `probe1.txt`

---

## Claim 13: "When the check fails the scan is not loaded, and main refuses every action but --bless and --list (--help and usage errors are answered first; neither touches the scan)."

**Location:** `devcontainer-config/cc-isolated.sh:711-713`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers launch, --probe-only, --register, --help, an unknown flag, --bless and --list with a tampered scan. It does not establish behaviour when the launcher is sourced by tests (HOST_TOOLS_ERR is set but main is not run).

The argument loop (`:732-751`, `--help|-h) usage; exit 0`, `-*) … exit 2`) runs before `if [ -n "$HOST_TOOLS_ERR" ] && [ "$action" != "bless" ] && [ "$action" != "list" ]` (`:753`). probe2: `--help exit=0`, `--bogus exit=2`, and --register and --probe-only both print `ERROR: host-tool check failed — refusing to launch, probe or register:`. In the test, --bless and --list exit 0 without running the planted touch.

**Evidence:** `devcontainer-config/cc-isolated.sh:729-771`, `docs/reviews/execution-logs/fc-q089a-final-r1/probe2.sh`, `probe2.txt`; command `timeout 120 probe2.sh $P`, cwd per-run mktemp, 2026-10-15T01:39:55Z

---

## Claim 14: "Never let this refusal hide a boundary change: run the boundary check too, and show its diff, before pointing at a bless that would accept both."

**Location:** `devcontainer-config/cc-isolated.sh:756-757`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_manifest being run against the launcher's dir and its diff printed before the bless hint. It does not establish ordering when stderr is interleaved with other output by a caller.

`if ! CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" check_manifest; then boundary_note="The BOUNDARY config changed too (above). …"` (`:759-761`) runs before the `printf '    %s\n' "$(… bless_cmd)"` at `:768`. In probe1's upgrade section, the refusal printed the `2,5c2` diff before the "Review the host tools" hint. The test "a host-tool refusal still shows a boundary change …" asserts `init-firewall.sh` and "BOUNDARY config changed too", and it passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:753-771`, `devcontainer-config/cc-isolated.sh:331-350`, `probe1.txt` ("-- new launcher before bless"), `cc-isolated-functions.tap`

---

## Claim 15: Message "The boundary config is unchanged: the re-bless changes no boundary state, so it causes no rebuild (a config not yet verified live is still probed at its next launch, as before)."

**Location:** `devcontainer-config/cc-isolated.sh:758`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers manifest.sha256 content, and therefore blessed_hash, being unchanged by the re-bless when check_manifest passed. It does not establish a rebuild-free launch in a real container (no Docker in the sandbox).

blessed_hash is `sha256sum < "$m" | cut -c1-16` over manifest.sha256 (`:88-93`), and the bless rewrites it from the same compute_manifest that check_manifest just matched. The test "a tampered cc-exit-scan.sh is never sourced; --bless still works …" asserts `[ "$(awk '{print $1}' "$d/manifest.sha256" | sha256sum)" = "$before" ]` after the re-bless, and it passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:88-93,758-761`, `test/cc-isolated-functions.bats:937-963`, `cc-isolated-functions.tap`

---

## Claim 16: "Only a cc-push.sh-specific reason: a manifest-level one is already above."

**Location:** `devcontainer-config/cc-isolated.sh:763-766`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers manifest-level reasons, which name `$dir/host-tools.sha256` and not cc-push.sh, so the `*cc-push.sh*` match skips them. It does not establish behaviour when the install dir's own path contains the string `cc-push.sh`: every reason would then match, including manifest-level ones, and the line would repeat.

`if ! push_err="$(verify_host_tools "$CC_ISOLATED_DIR" cc-push.sh)" && [[ "$push_err" == *cc-push.sh* ]]` (`:764`). In probe1's upgrade refusal (no host-tools.sha256) there is no "also changed" line. In the probe1 tamper case the line appears.

**Evidence:** `devcontainer-config/cc-isolated.sh:762-766`, `probe1.txt`

---

## Claim 17: "cc-push is not executed by the launcher, so a change to it never blocks a launch, but the launcher still says so: cc-push's self-check cannot catch a tampered cc-push that skips it."

**Location:** `devcontainer-config/cc-isolated.sh:772-779`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers launch, probe and register with only cc-push.sh changed. It does not establish that a launch gets past the devcontainer and workspace steps (stubbed in the test).

The warning's verify call is not followed by `exit` (`:776-779`). The test "--list reports host-tool state; a changed cc-push warns at launch but does not refuse" asserts `*"WARNING:"*"cc-push.sh changed since the last bless"*` and `!= *"refusing to launch"*`, and it passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:772-779`, `test/cc-isolated-functions.bats:1056-1076`, `cc-isolated-functions.tap`

---

## Claim 18: "when this installed copy or the cc-gitdir.sh beside it differs from what the bless recorded in host-tools.sha256 (or that file is missing, a symlink, unreadable or malformed), cc-push exits 1 before parsing anything, --help included"

**Location:** `devcontainer-config/cc-push.sh:35-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed triggers and exit 1 with --help on an installed copy. It does not list the per-file triggers (tool missing or a symlink, no single entry), which also exit 1. It does not apply to a repo checkout, which is unchecked.

The check (`cc-push.sh:203-212`) sits above `usage()` and argument parsing (`:218+`). probe1: `cc-push --help` printed `ERROR: cc-push refuses to run:` and `exit=1`. The cc-push.bats test asserts `[ "$status" -eq 1 ]` for `--help` after a self-tamper, and it passes.

**Evidence:** `devcontainer-config/cc-push.sh:29-43`, `devcontainer-config/cc-push.sh:203-219`, `probe1.txt`, `cc-push.tap`

---

## Claim 19: "What that guards: cc-gitdir.sh, and every line of this file below the check … It cannot guard the lines above the check, nor an overwrite that drops it: a tampered copy that skips its own check is caught only by cc-isolated's warning at the next launch of the copy installed beside it, and by `cc-isolated --list` for the config dir."

**Location:** `devcontainer-config/cc-push.sh:38-43`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the check guards and the two named catchers. It does not establish that "only" is exhaustive (see below).

The guard and non-guard parts hold: the check runs after `set -euo pipefail`, the `unset` and `safe_path` (`:120-142`). The test plants a `touch` directly below it and asserts that it never runs (passes). The launcher warns (`cc-isolated.sh:776-779`) and --list reports (`:517`). Two more things surface a tampered cc-push and are missing from "only". The launcher's refusal prints "also changed — do not run cc-push until re-blessed" (`cc-isolated.sh:764-765`) when the scan check also fails. The bless prints the cc-push.sh hash change before accepting it (probe1 "bless 2": `< 0b24f1b3… cc-push.sh`). Also, the warning fires on --probe-only and --register as well as on a launch. Precise version: "caught by cc-isolated (a warning or refusal line on any launch, probe or register from the copy beside it, and its bless diff) and by `cc-isolated --list`".

**Evidence:** `devcontainer-config/cc-push.sh:120-142,203-214`, `devcontainer-config/cc-isolated.sh:762-779`, `probe1.txt`, `test/cc-push.bats:808-820`

---

## Claim 20: "Checked first: a tampered cc-gitdir.sh would run at source time." / refusal "Review the host tools in DIR, then re-bless (it prints what changed): CLAUDE_DEVC_CONFIG_DIR=DIR cc-isolated --bless"

**Location:** `devcontainer-config/cc-push.sh:201-212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the check-before-source order and that the named bless prints changes for that dir. It does not establish that `cc-isolated` is on PATH (install.sh links it, `install.sh:598`).

probe1: running the printed command form (`CLAUDE_DEVC_CONFIG_DIR=$D …cc-isolated.sh --bless`) printed "Changed since the last bless (host-tools.sha256):". The cc-push.bats test asserts `*"CLAUDE_DEVC_CONFIG_DIR=$d cc-isolated --bless"*`, and it passes.

**Evidence:** `devcontainer-config/cc-push.sh:201-214`, `probe1.txt`, `cc-push.tap`

---

## Claim 21: "The bless hashes it into host-tools.sha256 (a host tool, decision log row 71), which cc-push checks before sourcing cc-gitdir.sh." (and the upgrade from an install without host-tools.sha256)

**Location:** `devcontainer-config/install.sh:600-602`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers install.sh's bless invocation (`CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless`, `:607`) run on a dir blessed by the 4ab9a51f launcher and then overwritten with the afe1ae59 payload. It does not establish a full install.sh run (not run, by instruction) or the steps before it.

probe1 upgrade section: the old bless left only `manifest.sha256`, and the new launcher refused a launch with "no host-tool manifest …" plus the boundary diff. The bless (as at `install.sh:607`) printed the manifest diff (the three tools leaving it) and "No previous host-tools.sha256: every entry below is new to this bless." Afterwards `cc-push --help` exited 0 and a launch printed no host-tool message.

**Evidence:** `devcontainer-config/install.sh:598-610`, `probe1.sh`, `probe1.txt` ("== upgrade path" onward)

---

## Claim 22: Test "every regular file in install.sh's PAYLOAD is hashed by enforcement_files or host_tool_files"

**Location:** `test/cc-isolated-functions.bats:835`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name against its assertions (Claim 3). It does not establish that a host tool missing from PAYLOAD would fail it.

**Evidence:** `test/cc-isolated-functions.bats:835-867`, `cc-isolated-functions.tap`

---

## Claim 23: Test "bless writes host-tools.sha256; a host-tool edit leaves the boundary manifest and blessed hash alone"

**Location:** `test/cc-isolated-functions.bats:869`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name. It asserts that host-tools.sha256 exists with the three names, that the manifest has no host tool, and that check_manifest is 0 with blessed_hash unchanged after a cc-push edit. It does not cover edits to cc-exit-scan.sh or cc-gitdir.sh in this test.

**Evidence:** `test/cc-isolated-functions.bats:869-884`, `cc-isolated-functions.tap`

---

## Claim 24a: Test "verify_host_tools: repo checkout unchecked; an installed dir must match, and cannot opt out" (main assertions)

**Location:** `test/cc-isolated-functions.bats:886-919`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the install.sh marker, the manifest-beside-it case, match and tamper, the duplicated entry and the symlinked tool. It does not cover the two sub-cases in 24b and 24c.

Mutant M4 (`if (n == 1)` → `if (n >= 1)`) fails at line 915, the duplicate-entry assertion, so that case bites.

**Evidence:** `test/cc-isolated-functions.bats:886-919`, `M4.txt` (mut.sh, bats exit 1, 2026-10-15T01:34:15Z)

---

## Claim 24b: "The config dir itself is never a repo checkout: no manifest there is refused."

**Location:** `test/cc-isolated-functions.bats:921-926`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether this sub-assertion exercises the `[ "$dir" != "$cfg" ]` clause. It does not dispute the clause itself (Claim 5).

The test creates `$c` with only `cc-push.sh` (`mkdir -p "$c"; echo 'a' > "$c/cc-push.sh"`) and no `install.sh`, so verify_host_tools refuses on the install.sh condition whatever the config-dir clause says. Mutant M1 deleted ` && [ "$dir" != "$cfg" ]`. The named test still passed (`M1.txt`: `ok 1`). In the full suite only the parity test failed (`M1full.txt`: `not ok 76`), and that was only because a single copy was mutated. A mutation of both copies would leave the clause untested. Asserting the clause needs `install.sh` in `$c`.

**Evidence:** `test/cc-isolated-functions.bats:921-926`, `M1.txt`, `M1full.txt` (mut.sh, cwd `$P/_tmp/mut-M1*`, exits 0 and 1, 2026-10-15T01:34:15Z / 01:34:26Z)

---

## Claim 24c: "A file the manifest does not list, or lists twice, is refused." (the not-listed half)

**Location:** `test/cc-isolated-functions.bats:909-912`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the not-listed sub-assertion in this test only. The no-entry branch is exercised, with an output check, by the malformed-manifest test (`:1019-1022`, "has no entry, or more than one, for cc-push.sh").

`run verify_host_tools "$d" cc-exit-scan.sh` runs where `$d` holds only cc-push.sh, cc-gitdir.sh, install.sh and manifest.sha256. cc-exit-scan.sh does not exist there, so the earlier branch `if [ ! -f "$dir/$f" ] || [ -L "$dir/$f" ]; then echo "$dir/$f is missing or a symlink"` (`cc-isolated.sh:255-258`) refuses before the entry lookup. The assertion checks only `[ "$status" -eq 1 ]`. Paraphrased — no quote available because the claim is about the absence of a file in the fixture: no line in the test creates `$d/cc-exit-scan.sh`. The "lists twice" half is meaningful (Claim 24a).

**Evidence:** `test/cc-isolated-functions.bats:888-912`, `devcontainer-config/cc-isolated.sh:253-264`

---

## Claim 25: Test "verify_host_tools is the same code in cc-isolated.sh and cc-push.sh"

**Location:** `test/cc-isolated-functions.bats:928`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block from the second marker line to the end marker. The first comment line ("KEEP IN STEP with the copy in …") is skipped by `tail -n +2` and differs by design.

M1 mutated only cc-isolated.sh's copy and the test failed (`M1full.txt`: `not ok 76`), so it bites.

**Evidence:** `test/cc-isolated-functions.bats:928-935`, `M1full.txt`

---

## Claim 26: Test "launch: a tampered cc-exit-scan.sh is never sourced; --bless still works and clears it"

**Location:** `test/cc-isolated-functions.bats:937`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers launch, --list and --bless not sourcing the tampered scan (`[ ! -e "$mark" ]`), the post-bless launch sourcing it (`[ -e "$mark" ]`) and the manifest hash being unchanged. It does not assert the final launch's exit status.

**Evidence:** `test/cc-isolated-functions.bats:937-963`, `cc-isolated-functions.tap`

---

## Claim 27a: Test "launch: a host-tool refusal still shows a boundary change made alongside it, and bless prints both"

**Location:** `test/cc-isolated-functions.bats:965`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name: the boundary diff and note in the refusal, and both "Changed since the last bless (…)" blocks in the bless. Ordering is not covered (27b).

**Evidence:** `test/cc-isolated-functions.bats:965-996`, `cc-isolated-functions.tap`

---

## Claim 27b: "Every changed tool is named, cc-push included, before the bless is suggested."

**Location:** `test/cc-isolated-functions.bats:983`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the following assertions check. It does not establish ordering relative to the bless hint.

The assertions match `*"cc-exit-scan.sh changed"*"cc-gitdir.sh changed"*` and `*"also changed — do not run cc-push until re-blessed"*"cc-push.sh changed"*` (`:984-990`). None places the bless line after them. The order does hold in code (`cc-isolated.sh:764-768`), but this test would not catch a reorder. Precise version: "Every changed tool is named, cc-push included."

**Evidence:** `test/cc-isolated-functions.bats:983-990`, `devcontainer-config/cc-isolated.sh:762-768`

---

## Claim 28: Tests "--list still reports everything when the config dir's parent is missing (set -e)", "verify_host_tools: an unreadable, empty or malformed manifest, or a missing entry, is named as the problem", "bless: a failure changes neither manifest"

**Location:** `test/cc-isolated-functions.bats:998`, `test/cc-isolated-functions.bats:1006`, `test/cc-isolated-functions.bats:1032`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its assertions. The first test is shown to bite by M6 (Claim 11). The second skips its unreadable case when run as root. The third checks both manifests and temp-file cleanup.

**Evidence:** `test/cc-isolated-functions.bats:998-1054`, `M6.txt`, `cc-isolated-functions.tap`

---

## Claim 29a: Test "--list reports host-tool state; a changed cc-push warns at launch but does not refuse" (name and the cc-push-changed half)

**Location:** `test/cc-isolated-functions.bats:1056-1070`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the match line, the CHANGED/warn/cc-push lines, `!= *"launches refuse"*`, and the launch WARNING without a refusal. The scan-only half is not covered (29b).

**Evidence:** `test/cc-isolated-functions.bats:1056-1070`, `cc-isolated-functions.tap`

---

## Claim 29b: "A scan-only change: launches refuse, cc-push (which does not run the scan) does not." — asserted as `[[ "$output" != *"cc-push refuses"* ]]`

**Location:** `test/cc-isolated-functions.bats:1071-1075`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the negative assertion can fail. It does not dispute the code's actual scan-only behaviour, which is correct at afe1ae59 (perr does not include the scan).

afe1ae59 renamed the --list line from "cc-push refuses: …" to "cc-push: CHANGED — do not run it until re-blessed (an intact copy refuses): …" (`cc-isolated.sh:517`). The string `cc-push refuses` no longer occurs in any --list output, so the assertion is vacuous. Mutant M3 added `cc-exit-scan.sh` to perr's list, so a scan-only change wrongly reports cc-push CHANGED. The whole suite then passed except the out-of-tree Gate 1h artefacts (`M3full.txt`), and the named test passed alone (`M3.txt`: `ok 1`). The assertion should match `cc-push: CHANGED`.

**Evidence:** `test/cc-isolated-functions.bats:1071-1075`, `devcontainer-config/cc-isolated.sh:503,517`, `M3.txt`, `M3full.txt` (mut.sh, cwd `$P/_tmp/mut-M3*`, bats exit 0 and 1, 2026-10-15T01:34:15Z / 01:34:26Z)

---

## Claim 29c: Test "installed copy: cc-push checks itself and cc-gitdir.sh before sourcing, and refuses on a change (row 71)", including "Not at the end of the file: cc-push exits at its main guard before reaching it."

**Location:** `test/cc-push.bats:797-828`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gitdir tamper never running, the self-tamper directly below the check never running, --help exiting 1, the hint naming the dir, and a deleted host manifest being refused. It does not cover lines above the check, which cannot be guarded (Claim 19).

cc-push's main guard ends with every branch calling `exit` (`cc-push.sh` tail: `0|1|2) exit "$rc" ;;` … `*) … exit 1 ;;`), so a line appended after it never runs, as the comment says. The awk insertion before `# shellcheck source=cc-gitdir.sh` puts the touch after the check's `fi` (`cc-push.sh:212-213`).

**Evidence:** `test/cc-push.bats:797-828`, `devcontainer-config/cc-push.sh:203-214`, `devcontainer-config/cc-push.sh:597-602`, `cc-push.tap`

---

## Claim 30: "Tests under LC_ALL=C: cc-isolated-functions 182/182, cc-push 48/48." (afe1ae59 and f737ba71)

**Location:** commit `afe1ae59`, commit `f737ba71`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pass counts at afe1ae59 (run) and test counts at f737ba71 (`bats --count`, which equals afe1ae59's). It does not establish that f737ba71's tests passed (not re-run).

The afe1ae59 run gave 182 `ok` / 0 `not ok` and 48 / 0, with `bats --count` 182 and 48. At f737ba71 `bats --count` gives cif=182 and push=48.

**Evidence:** `cc-isolated-functions.tap`, `cc-push.tap` (commands as in Claim 1, cwd `$P`, both exit 0, 2026-10-15T01:32:23Z)

---

## Claim 31: Earlier counts: b3b37e16 "cc-isolated-functions 181/181"; 4be0445d / 2cb03f23 / cc2640b7 "cc-push 48/48"; f2533b33 "install-host 92/92"

**Location:** commits `b3b37e16`, `4be0445d`, `2cb03f23`, `cc2640b7`, `f2533b33`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the denominators (`bats --count` on each commit's `git archive`). It does not establish that those runs passed, since only afe1ae59 was run.

`bats --count` gives b3b37e16 cif=181, 4be0445d/2cb03f23/cc2640b7 push=48, and f2533b33 ih=92. Command loop: `git archive $c test | tar -x -C $d; bats --count …`, run from /workspace/.claude/wt-q089 with output inline in this session, exit 0. Paraphrased — no quote available because the counts were printed to the session, not to a captured file. Re-run the loop to reproduce.

**Evidence:** `test/cc-isolated-functions.bats`, `test/cc-push.bats`, `test/install-host.bats` at each named commit

---

## Claim 32: afe1ae59's fix list: "--list … now says 'cc-push: CHANGED — do not run it until re-blessed (an intact copy refuses)'. The refusal's line reads 'also changed — do not run cc-push until re-blessed'"; "api F1 … adds the cc-push line only for a cc-push.sh-specific reason"; "api F2: the refusal header is cause-neutral ('host-tool check failed')"; "api F3: cc-push's guidance line is indented like the launcher's"; "api F5: 'has no entry, or more than one, for X' (both copies)"; "Recorded reviewer probe scripts … get a shellcheck disable line … behaviour is unchanged"

**Location:** commit `afe1ae59`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each code bullet against the afe1ae59 diff, and gate-6 shellcheck flags on the changed and added scripts. It does not establish which probe scripts tripped gate 6 before the change: only one existing script gained the disable line, and the three added ones pass without it.

Each string appears at `cc-isolated.sh:517`, `:765`, `:764`, `:754`, `cc-push.sh:209-210`, and in both copies of `verify_host_tools`. `fc-q089a1/probe.sh` gained `# shellcheck disable=SC2010  # recorded reviewer probe, kept as run; gate 6 only`. `shellcheck -x -e SC1091 -s bash -S warning` exits 0 on all four probe scripts and on the code files.

**Evidence:** `devcontainer-config/cc-isolated.sh:754,764-765,517`, `devcontainer-config/cc-push.sh:204-211`, `docs/reviews/execution-logs/fc-q089a-final-r1/shellcheck.txt` (cwd `$P`, all sc=0, 2026-10-15T01:38:27Z)

---

## Claim 33: 4be0445d "Tests: a tampered cc-gitdir.sh and a tampered cc-push.sh are both refused without running"

**Location:** commit `4be0445d`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cc-push.sh half at 4be0445d. The same branch corrects it (2cb03f23's message: "before this, that test's tamper was an inert comment"), and the test at afe1ae59 is meaningful (Claim 29c).

At 4be0445d the self-tamper was `printf '\n# edited\n' >> "$d/cc-push.sh"` (`test/cc-push.bats:811` at that commit). That is a comment, so "without running" was not asserted for cc-push.sh. Recorded for the log only, since it was already corrected in-branch.

**Evidence:** `test/cc-push.bats:809-812` at 4be0445d, commit `2cb03f23` message

---

## Claims Requiring Attention

### Incorrect
- **Claim 7b** (`devcontainer-config/cc-push.sh:175-176`): the shared comment says the refusal "lists all of what the bless it points to would accept". cc-push's refusal names only cc-push.sh/cc-gitdir.sh, while the bless also accepts cc-exit-scan.sh and boundary changes (probe1). Reword both copies, for example "names every mismatch among the files it is given".
- **Claim 24b** (`test/cc-isolated-functions.bats:921-926`): the "config dir is never a repo checkout" case has no install.sh in `$c`, so it passes with the `[ "$dir" != "$cfg" ]` clause deleted (M1). Add install.sh to `$c`.
- **Claim 24c** (`test/cc-isolated-functions.bats:909-912`): the "file the manifest does not list" case uses a file absent from `$d`, so the missing-file branch refuses first. Create the file, or assert the "has no entry" output.
- **Claim 33** (commit 4be0445d): "a tampered cc-push.sh [is] refused without running" was untrue at that commit. Already corrected by 2cb03f23. No action.

### Stale
- **Claim 29b** (`test/cc-isolated-functions.bats:1075`): `!= *"cc-push refuses"*` has been vacuous since afe1ae59 renamed the line to "cc-push: CHANGED"; M3 (scan wrongly in perr) passes. Match `cc-push: CHANGED` instead.

### Mostly Accurate
- **Claim 8b** (`devcontainer-config/cc-isolated.sh:274-277`): the split arises only when the second rename fails or an interrupt lands between them. A first-rename failure leaves both old. An interrupt exits 130, not 1.
- **Claim 19** (`devcontainer-config/cc-push.sh:40-43`): "caught only by" leaves out the launcher's refusal line, the bless diff, and the warning on --probe-only/--register.
- **Claim 27b** (`test/cc-isolated-functions.bats:983`): "before the bless is suggested" is not asserted.

### Unverifiable
- None. Real-container behaviour (no rebuild after a host-only re-bless) is outside the sandbox and was not claimed beyond manifest identity (Claim 15).

---

## Goal-Alignment Note

The PR's goal is that host-only tools leave the boundary manifest for host-tools.sha256, so editing one forces no rebuild or probe, while the entry points still refuse or warn on tampering. The code achieves this. Executed probes confirm the check-before-source in both entry points, the refusal surface (all actions but --bless/--list, every reason indented, boundary diff shown, dir-named bless), the warn-only treatment of cc-push, both-or-neither bless with a printed diff, --list states, and a clean upgrade from an install that predates host-tools.sha256 through install.sh's bless call. Suite counts in the commit messages are accurate (182/182, 48/48 under LC_ALL=C; earlier denominators match).

None of the remaining findings is a code defect.
- **Claim 7b**, a shared comment that overstates what cc-push's refusal shows. Low impact: the hint says the bless prints what changed.
- **Three test assertions that cannot fail** (24b, 24c, 29b). Each leaves a stated behaviour unpinned against regression: the config-dir clause of the repo-checkout exemption, the no-entry branch within that test, and --list not blaming cc-push on a scan-only change. 29b is new in iteration 3, a rename that left a negative assertion matching nothing. These matter for a security-sensitive merge because the behaviour is right today but nothing would catch it regressing.

Row 71 and `Host-tool-tested:` exist only in unit B (79f22357) and are consistent with A's comments, so landing A1+A2 before B would leave those references dangling. The recorded one-landing constraint covers this.
