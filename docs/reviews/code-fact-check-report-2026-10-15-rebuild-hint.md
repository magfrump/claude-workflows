# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-rebuild-hint, branch fix/rebuild-hint-recreate)
**Scope:** `git diff 9660d4f6..HEAD` (devcontainer-config/cc-isolated.sh, devcontainer-config/init-firewall.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, test/init-firewall-rules.bats) plus the commit message of cb56299c; two out-of-diff sibling claims in the same files
**Checked:** 2026-10-15
**Commit:** cb56299c
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 19
**Summary:** 12 verified, 6 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution provenance (shared by every `executed` claim). Scratch dir `S=/home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/code-fact-check-k1`. Captured output in `$S/logs/`:

| Run | Command | cwd | Exit | UTC |
|---|---|---|---|---|
| R1 new suites | `timeout 600 bash scripts/run-tests.sh test/cc-isolated-functions.bats test/init-firewall-rules.bats` | worktree | 0 (289/289 ok) | 2026-10-15T11:00:39Z → `$S/logs/new-full.log` |
| R2 old scripts | same command, with the 9660d4f6 `cc-isolated.sh` and `init-firewall.sh` copied over a `git archive HEAD` copy | `$S/old` | 1 (tests 27, 102, 289 not ok; all others ok) | ~11:02Z → `$S/logs/old-full.log` |
| R3 mutations | `timeout 600 bats --filter MUT test/cc-isolated-functions.bats` (MUT1 stale baked hash; MUT2 healthy launch; MUT3 STUB_FW_BRICKED unset) | `$S/mut` (archive copy + added tests) | 1 (all three mutants caught, as intended) | 2026-10-15T11:04:28Z → `$S/logs/mutations.log` |
| R4 fail-closed dump | `bats --filter MUT4` (the new test with output echoed) | `$S/mut` | 0 | 11:05:08Z → `$S/logs/fail-closed-output.log` |
| R5 probe-only fail | `bats --filter MUT5` (`--probe-only` with marker missing) | `$S/mut` | 0 | 11:05:23Z → `$S/logs/probe-only-fail.log` |
| R6 empty baked hash | `bats --filter MUT6` (registered `python` profile, `/etc/cc-config-hash` empty) | `$S/mut` | 0 | 11:06:24Z → `$S/logs/empty-hash-recreate.log` |
| R7 diff filter | `git diff 9660d4f6..HEAD -- devcontainer-config \| grep '^[-+]' \| grep -v '^[-+][-+]' \| grep -v '^[-+]\s*#' \| grep -v '^[-+]\s*echo'` | worktree | 1 from last grep (no lines) | 11:06:30Z → `$S/logs/non-comment-diff.log` (0 bytes) |

`docs/reviews/hallucination-patterns.md` read; no logged pattern resembles any claim below.

---

## Claim 1: "a plain launch recreates only when the baked config hash differs, so a fail-closed container built from the blessed config would be reused, not recovered"

**Location:** `devcontainer-config/cc-isolated.sh:560-562`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main()'s launch path against a RUNNING container whose baked hash equals the blessed one (the only state in which the hint is printed, since the probe has just exec'd into it); does not establish what a plain launch does to a STOPPED fail-closed container, which `devcontainer up` would start (fresh network namespace, postStartCommand re-run) rather than recreate — that path needs Docker and was not run.

The launch path is (`cc-isolated.sh:891-922`, read through `:932`):

```bash
  devcontainer up "${dc[@]}"
  ...
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi
  ...
  if ! probe_boundary "$ws"; then
    ...
    if ! devcontainer exec "${dc[@]}" sudo /usr/local/bin/init-firewall.sh; then
      ...
      rebuild_hint "$ws" "${dc[@]}"
      return 1
    fi
    probe_boundary "$ws"
  fi
```

`container_config_matches` (`cc-isolated.sh:574-578`) is the only recreate trigger on this path: `[ -n "${CC_CONFIG_HASH:-}" ] && [ "$have" = "$CC_CONFIG_HASH" ]`. The re-run of the baked script cannot recover a DROP-policy container because it collects its GitHub ranges and DNS answers before the flush (`init-firewall.sh:481` `gh_ranges=$(curl -s --connect-timeout 5 --max-time 15 https://api.github.com/meta || true)`; the DROP-then-flush is at `:721-730`), so those reads run under the closed policy. Executed: R1 test 102 passes (no `--remove-existing-container`, no `claude` exec in `$DC_LOG`), and R4 shows the launch output ending in the hint with no recreate. R3 MUT1 (baked hash `stale`) shows the same test does catch a recreate. The stopped-container case is the residue in Scope: `devcontainer.json:141` `"postStartCommand": "sudo /usr/local/bin/init-firewall.sh && ..."` runs on every start, and (paraphrased — no quote available because this is Docker runtime behaviour, not repo code) a restarted container gets a new network namespace without the old DROP rules, so a restart may recover where a reuse does not. That is not a recreate, so the comment's literal statement holds.

**Evidence:** `devcontainer-config/cc-isolated.sh:574-578`, `devcontainer-config/cc-isolated.sh:891-922`, `devcontainer-config/init-firewall.sh:481`, `devcontainer-config/init-firewall.sh:721-730`, `devcontainer-config/devcontainer.json:141`, `$S/logs/new-full.log`, `$S/logs/fail-closed-output.log`, `$S/logs/mutations.log`

---

## Claim 2: "--probe-only always recreates, and exits non-zero on a failed probe, so the `&&` never starts a session after one."

**Location:** `devcontainer-config/cc-isolated.sh:562-563`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the probe branch of main() under `set -euo pipefail` and the script's invocation guard; does not establish that a PASSING --probe-only leaves a container the following plain launch will accept (it will, by Claim 1's hash check, but the second command's own probe is what gates the session).

```bash
# cc-isolated.sh:884-890
  if [ "$action" = "probe" ]; then
    # --probe-only is the verification command, so it always recreates: probing a
    # container left over from an earlier config would verify the wrong boundary.
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
  fi
```

`set -euo pipefail` is at `cc-isolated.sh:66`; `probe_boundary` ends `return 1` on any failure (`:702-705`); main is invoked as a plain command in an `if` body (`:946-948` `if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi`), which is not an errexit-suppressing context, so the failed `probe_boundary` exits the script with status 1 before `exit 0`. Executed: R5 shows `STATUS=1`, exactly one `up --remove-existing-container` in the log, no `claude` exec and no init-firewall re-run.

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-isolated.sh:702-705`, `devcontainer-config/cc-isolated.sh:884-890`, `devcontainer-config/cc-isolated.sh:946-948`, `$S/logs/probe-only-fail.log`

---

## Claim 3: "cc-isolated --probe-only WS && cc-isolated WS   # the supported path: recreates from the blessed config, re-probes, then launches"

**Location:** `devcontainer-config/cc-isolated.sh:564`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the hint's correctness for the init-firewall-failure caller (`:919`) and for the provenance/config-identity callers (`:671`, `:685`) when reached from a plain launch; does not establish that repeating --probe-only fixes a provenance or config-identity failure that occurs inside a --probe-only run, where the recreate has just happened.

For the init-firewall caller the recipe is right (Claims 1-2; R4 prints it after `Recreate it (the ~/.claude volume and your repo are not affected):`). For the two `probe_boundary` callers the hint is also printed during a `--probe-only` run, immediately after `devcontainer up --remove-existing-container` (`:887`). In that run a provenance failure (`:665-673`, "this container was NOT built from the central Dockerfile") means the build that just ran did not come from the blessed config, so "recreates from the blessed config" does not describe what repeating the step will do; the guide's own remedy for that case is different (`guides/cc-isolated-usage.md:964` "A leftover `.devcontainer/Dockerfile` in the target repo shadows the central one. Delete `.devcontainer/` before verifying"). The same is true of a config-identity failure right after a recreate. The pre-change text had the same gap. Precise version: the line is the supported path for a container that is stale or fail-closed. When the failure follows a --probe-only recreate, the cause is in the build, not the container.

**Evidence:** `devcontainer-config/cc-isolated.sh:557-571`, `devcontainer-config/cc-isolated.sh:665-687`, `devcontainer-config/cc-isolated.sh:887`, `devcontainer-config/cc-isolated.sh:916-920`, `guides/cc-isolated-usage.md:964`, `$S/logs/fail-closed-output.log`

---

## Claim 4: "Recreate it with:" (image provenance and config identity lead-ins)

**Location:** `devcontainer-config/cc-isolated.sh:670`, `devcontainer-config/cc-isolated.sh:684`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the instruction following each lead-in (rebuild_hint's two forms) recreates the container; does not establish that the recreate cures the failure (see Claim 3).

Both lead-ins are followed by `rebuild_hint "$ws" "${dc[@]}"` (`:671`, `:685`), whose two forms are `cc-isolated --probe-only ...` (recreates per `:887`) and `devcontainer up --remove-existing-container$(printf ' %q' "$@")` (`:570`).

**Evidence:** `devcontainer-config/cc-isolated.sh:564-570`, `devcontainer-config/cc-isolated.sh:670-671`, `devcontainer-config/cc-isolated.sh:684-685`, `devcontainer-config/cc-isolated.sh:887`

---

## Claim 5: "--probe-only is the verification command, so it always recreates"

**Location:** `devcontainer-config/cc-isolated.sh:885`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the probe branch passes `--remove-existing-container` unconditionally; does not establish whether the image layers are rebuilt or taken from cache (Docker state).

Quoted in Claim 2 (`:887` `devcontainer up --remove-existing-container "${dc[@]}"`, with no condition). R1 test 103 "--probe-only always rebuilds before probing" passes; R5 logs the recreate even though the baked hash matches.

**Evidence:** `devcontainer-config/cc-isolated.sh:884-890`, `$S/logs/new-full.log`, `$S/logs/probe-only-fail.log`

---

## Claim 6: "This run is that verification: the container is rebuilt from it" (out of diff, pre-existing)

**Location:** `devcontainer-config/cc-isolated.sh:878`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the plain-launch NOTE when the blessed hash has no receipt but the container already carries that hash, which is exactly the fail-closed state (its first probe failed, so no receipt was written); does not cover the --probe-only path, where the statement is true, or the case right after a re-bless, where the hash check does trigger a recreate.

```bash
# cc-isolated.sh:876-881
  if ! is_verified_live; then
    echo "NOTE: blessed config $CC_CONFIG_HASH has NOT been verified in a live container."
    echo "      This run is that verification: the container is rebuilt from it, and the"
    echo "      self-probe must pass (including the node-run firewall probes) before anything"
    echo "      starts. A pass records the hash in $(verified_path)."
  fi
```

`record_verified_live` runs only on a full probe pass (`:706`), so a container that failed closed on its first boot leaves the receipt unwritten and every later plain launch prints this NOTE, while (Claim 1) it reuses the container. R4 shows both in one run: "the container is rebuilt from it" at the top, and at the bottom the new hint saying a plain launch does not recreate. This text predates the diff, but it is the same rebuild/recreate claim the unit fixes, and it contradicts the new hint in the scenario the unit targets. The guide repeats it at `guides/cc-isolated-usage.md:955` ("The launch rebuilds and verifies"). Precise version: "the container is recreated if it was built from another config, and the self-probe must pass".

**Evidence:** `devcontainer-config/cc-isolated.sh:103-108`, `devcontainer-config/cc-isolated.sh:706`, `devcontainer-config/cc-isolated.sh:876-881`, `devcontainer-config/cc-isolated.sh:897-900`, `guides/cc-isolated-usage.md:955`, `$S/logs/fail-closed-output.log`

---

## Claim 7: "--probe-only always recreates the container from the blessed config and re-probes." / "# recreates it from the blessed config, re-probes"

**Location:** `devcontainer-config/init-firewall.sh:346`, `devcontainer-config/init-firewall.sh:349`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main()'s probe branch (unconditional recreate with `CC_CONFIG_HASH="$(blessed_hash)"` exported after `check_manifest` has passed); does not establish that the next `cc-isolated <repo>` (`:350`) succeeds when the outage that caused the fail-closed state persists.

`cc-isolated.sh:832` `check_manifest`, `:835-836` `CC_CONFIG_HASH="$(blessed_hash)"` / `export CC_CONFIG_HASH`, then `:887` `devcontainer up --remove-existing-container "${dc[@]}"` and `:888` `probe_boundary "$ws"`. The build reads the installed config dir (`:824` `CC_CONFIG_DIR="$(config_dir)"`), which `check_manifest` has just verified against the blessed manifest.

**Evidence:** `devcontainer-config/init-firewall.sh:343-351`, `devcontainer-config/cc-isolated.sh:824`, `devcontainer-config/cc-isolated.sh:832-836`, `devcontainer-config/cc-isolated.sh:884-890`

---

## Claim 8: "cc-isolated --probe-only [REPO]   # RECREATE REPO's container from the blessed config, run the self-probe, record the config verified live on a pass"

**Location:** `guides/cc-isolated-usage.md:25-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the probe branch and `record_verified_live` on a pass; does not establish image-cache behaviour.

Same code as Claim 7; on a pass `probe_boundary` calls `record_verified_live` (`cc-isolated.sh:706`).

**Evidence:** `guides/cc-isolated-usage.md:25-26`, `devcontainer-config/cc-isolated.sh:706`, `devcontainer-config/cc-isolated.sh:884-890`

---

## Claim 9: "Relaunch with `cc-isolated <repo>`, which recreates it with both set."

**Location:** `guides/cc-isolated-usage.md:963`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a plain launch on a container whose `/etc/cc-config-hash` is empty (the row's stated symptom): the hash check fails and the recreate runs with `CC_EGRESS_PROFILE` and `CC_CONFIG_HASH` exported; does not cover a variant where the hash was baked correctly but only the profile is empty (the provenance probe, not a recreate, catches that).

`container_config_matches` requires `"$have" = "$CC_CONFIG_HASH"` with a non-empty blessed hash (`cc-isolated.sh:577`), so an empty baked hash always mismatches and `:899` recreates. The exports happen before it (`:819` `CC_EGRESS_PROFILE="$eff_profile"`, `:825` `export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR`, `:836` `export CC_CONFIG_HASH`). Executed: R6, with a registered `python` profile and an empty baked hash, logs "Blessed config changed since this container was built — rebuilding it." and the recreate's environment holds `CC_EGRESS_PROFILE=python` and `CC_CONFIG_HASH=1626246a723481c1` (the blessed hash).

**Evidence:** `guides/cc-isolated-usage.md:963`, `devcontainer-config/cc-isolated.sh:574-578`, `devcontainer-config/cc-isolated.sh:819-825`, `devcontainer-config/cc-isolated.sh:835-836`, `devcontainer-config/cc-isolated.sh:897-900`, `$S/logs/empty-hash-recreate.log`

---

## Claim 10: "it always rebuilds first" / "The launch rebuilds and verifies" (out of diff, residual wording)

**Location:** `guides/cc-isolated-usage.md:841`, `guides/cc-isolated-usage.md:955`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the two remaining "rebuild" phrasings in the guide that describe what the unit now calls a recreate; does not re-verdict `:955` for the fail-closed case beyond Claim 6.

`:841` describes --probe-only, which recreates (Claim 5). The unit changed the same wording at `:25` and in `cc-isolated.sh:885` but not here. `:955` is the guide-side copy of Claim 6's NOTE; it is true right after a re-bless that changes the hash, and false when the receipt is missing because the container's first probe failed. Precise version: "it always recreates first" and "The launch recreates the container if it was built from another config, then verifies".

**Evidence:** `guides/cc-isolated-usage.md:838-842`, `guides/cc-isolated-usage.md:955`, `devcontainer-config/cc-isolated.sh:884-900`

---

## Claim 11: "Two steps, not a bare relaunch ... It is the guides' two-step recipe, never a bare relaunch" (test comment for the rebuild_hint first-line test)

**Location:** `test/cc-isolated-functions.bats:351-358`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the assertions pin the two-step recipe, the word "recreates" and the absence of "rebuilds" on the first line; does not test the by-hand lines.

```bash
# test/cc-isolated-functions.bats:355-357
  [[ "$(echo "$output" | head -1)" == *"cc-isolated --probe-only $ws && cc-isolated $ws "* ]]
  [[ "$(echo "$output" | head -1)" == *"recreates"* ]]
  [[ "$(echo "$output" | head -1)" != *"rebuilds"* ]]
```

It passes in R1 and fails at `:355` on the old script in R2.

**Evidence:** `test/cc-isolated-functions.bats:346-358`, `$S/logs/new-full.log`, `$S/logs/old-full.log`

---

## Claim 12: "STUB_FW_BRICKED=1 → re-running the baked init-firewall.sh fails (fail-closed state)."

**Location:** `test/cc-isolated-functions.bats:1152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stub's case arm and its ordering against the other arms; does not establish anything about the real script.

`:1166` `*init-firewall.sh*)      [ -z "${STUB_FW_BRICKED:-}" ] ;;`. The earlier arms (`*cc-config-hash*`, `*rev-parse*`, `*cc-firewall/complete*`) do not match `sudo /usr/local/bin/init-firewall.sh`. R3 MUT3 (flag unset) fails the new test at the `ERROR: init-firewall.sh failed` assertion, so the flag is what produces the failure.

**Evidence:** `test/cc-isolated-functions.bats:1150-1180`, `$S/logs/mutations.log`

---

## Claim 13: "The premise of the hint: this launch reused the container and never started claude."

**Location:** `test/cc-isolated-functions.bats:1401-1403`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both `run ! grep` assertions work in this bats and would fail if the behaviour they deny happened; does not cover the stopped-container path (Claim 1's residue), which the stub cannot model.

```bash
# test/cc-isolated-functions.bats:1402-1403
  run ! grep -q -- '--remove-existing-container' "$DC_LOG"
  run ! grep -q ' claude$' "$DC_LOG"
```

The suite declares `bats_require_minimum_version 1.5.0` (`:13`) and the host has Bats 1.8.2, so `run !` fails the test on a zero exit. The hint's own `--remove-existing-container` goes to stderr, not to `$DC_LOG`, so it cannot match. R3 MUT1 (stale baked hash): the test fails at `:1421` (the mutant copy of this line) with "expected nonzero exit code!". R3 MUT2 (healthy launch): the log's last line is `devcontainer exec ... --id-label cc-project=... claude` and `run ! grep -q ' claude$'` fails, so the pattern matches a real session start.

**Evidence:** `test/cc-isolated-functions.bats:13`, `test/cc-isolated-functions.bats:1384-1404`, `$S/logs/mutations.log`

---

## Claim 14: "--probe-only recreates the container (cached image layers are reused), the word the guides use"

**Location:** `test/init-firewall-rules.bats:1491-1492`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the launcher passes no cache-disabling flag and that the guides use "recreate" for --probe-only at `:25` and `:957`; does not establish actual cache hits, which depend on Docker's builder state (and the `CC_CONFIG_HASH` build arg at `Dockerfile:484` invalidates every layer after it).

`dc=(--workspace-folder "$ws" --override-config ... --id-label "cc-project=$pid")` (`cc-isolated.sh:838-840`) carries no `--build-no-cache`. `guides/cc-isolated-usage.md:957` says "`cc-isolated --probe-only <repo>` (recreates the container from the blessed config and re-probes)". (`:841` still says "rebuilds"; see Claim 10.)

**Evidence:** `test/init-firewall-rules.bats:1488-1495`, `devcontainer-config/cc-isolated.sh:838-840`, `devcontainer-config/Dockerfile:484-487`, `guides/cc-isolated-usage.md:957`

---

## Claim 15: Commit body: "in the fail-closed state (init-firewall.sh died, DROP with no accepts, container built from the blessed config) it reuses the bricked container, fails the same way, and prints the same hint"

**Location:** cb56299c commit message, paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the running-container case under the stub; the stopped-container residue from Claim 1 applies equally here.

Same evidence as Claim 1; R4 shows reuse, the probe failure, the failed re-run and the hint.

**Evidence:** `devcontainer-config/cc-isolated.sh:891-922`, `$S/logs/fail-closed-output.log`

---

## Claim 16: Commit body: "Message text and comments only; no iptables call, probe check, recreate decision or exit status changed."

**Location:** cb56299c commit message, Notes
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every changed line under devcontainer-config/; does not cover test files (which add assertions and one stub arm, as stated elsewhere in the body).

R7 filters the diff of devcontainer-config/ to changed lines that are neither comments nor `echo` and produces an empty file (`$S/logs/non-comment-diff.log`, 0 bytes). The diff stat is 12 lines in cc-isolated.sh and 4 in init-firewall.sh, all comments or echo text (patch hunks at `:557`, `:663`, `:677`, `:878` and `init-firewall.sh:343`).

**Evidence:** `devcontainer-config/cc-isolated.sh:560-564`, `devcontainer-config/cc-isolated.sh:670`, `devcontainer-config/cc-isolated.sh:684`, `devcontainer-config/cc-isolated.sh:885`, `devcontainer-config/init-firewall.sh:346-349`, `$S/logs/non-comment-diff.log`

---

## Claim 17: Commit body: "The printed "Blessed config changed ... rebuilding it." line is left as is (a guide row quotes it verbatim)."

**Location:** cb56299c commit message, Notes
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the guide row and test that match the line; does not judge whether the line should change.

The guide row quotes the line only as far as "rebuilding": `guides/cc-isolated-usage.md:956` "| `Blessed config changed since this container was built — rebuilding` |". A test also pins a prefix: `test/cc-isolated-functions.bats:1355` `*"Blessed config changed since this container was built"*`. So the row quotes a prefix, not the whole line. The rationale still holds, because changing "rebuilding" would break the row's match. Precise version: "a guide row quotes it up to 'rebuilding'".

**Evidence:** `devcontainer-config/cc-isolated.sh:898`, `guides/cc-isolated-usage.md:956`, `test/cc-isolated-functions.bats:1355`

---

## Claim 18: Commit body: "Both scripts are in the trust manifest, so the host needs install.sh + bless, and the next launch recreates each project's container once (init-firewall.sh is baked into the image)."

**Location:** cb56299c commit message, Notes
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers manifest membership, the check_manifest refusal, and the hash-mismatch recreate; does not establish the host-side install (outside the sandbox).

Both are boundary files: `cc-isolated.sh:128-136` `echo "init-firewall.sh"` ... `echo "cc-isolated.sh"` inside `enforcement_files`, which `compute_manifest` hashes. An unblessed change is refused (`:342-343` "installed config changed since last bless — refusing to build/launch."). After the bless, `blessed_hash` changes, and every existing container mismatches at `:897` and is recreated once. The parenthetical gives a true fact but the wrong trigger: the recreate is caused by the blessed-hash change, which the cc-isolated.sh edit alone would cause even though cc-isolated.sh is not in the image. That init-firewall.sh is baked in (`Dockerfile:487` `COPY init-firewall.sh /usr/local/bin/`) is why the recreate is needed for the new echo to reach containers, not why it happens. Precise version: "the next launch recreates each project's container once (the blessed hash changes; the new init-firewall.sh text reaches containers only through that recreate)".

**Evidence:** `devcontainer-config/cc-isolated.sh:128-136`, `devcontainer-config/cc-isolated.sh:153-196`, `devcontainer-config/cc-isolated.sh:332-349`, `devcontainer-config/cc-isolated.sh:897-900`, `devcontainer-config/Dockerfile:484-487`

---

## Claim 19: Commit body: "All three fail on the old text."

**Location:** cb56299c commit message, Tests paragraph
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two suites run against the 9660d4f6 versions of both scripts with the new tests; does not establish that the tests fail on every plausible wrong text.

R2: exactly tests 27 (`:355`, the two-step recipe), 102 (`:1400`, `"Recreate it"*"cc-isolated --probe-only $ws && cc-isolated $ws "`) and 289 (`init-firewall-rules.bats:1493`, `# recreates it from the blessed config`) are `not ok`; all 286 others pass. R1 on the new scripts: 289/289 ok.

**Evidence:** `test/cc-isolated-functions.bats:355`, `test/cc-isolated-functions.bats:1400`, `test/init-firewall-rules.bats:1493`, `$S/logs/old-full.log`, `$S/logs/new-full.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6** (`devcontainer-config/cc-isolated.sh:878`, out of diff, pre-existing): the NOTE says "the container is rebuilt from it", but in the fail-closed state (no receipt, matching hash) the launch reuses the container. It contradicts the new hint in the same run (R4). Say "recreated if it was built from another config". Same text in `guides/cc-isolated-usage.md:955`.

### Stale
- none

### Mostly Accurate
- **Claim 3** (`devcontainer-config/cc-isolated.sh:564`): the recipe is right for the fail-closed and stale-container callers. When the provenance or config-identity hint prints inside a --probe-only run, repeating --probe-only recreates from the same (bad) build. The old text had the same gap.
- **Claim 10** (`guides/cc-isolated-usage.md:841`, `:955`, out of diff): leftover "rebuilds" for what is a recreate; `:955` repeats Claim 6.
- **Claim 17** (commit cb56299c): the guide row quotes the line up to "rebuilding", not "rebuilding it."
- **Claim 18** (commit cb56299c): the recreate is triggered by the blessed-hash change, not by init-firewall.sh being baked in.

### Unverifiable
- none (the stopped-container restart path in Claim 1's Scope needs Docker; it is recorded as residue, not verdicted)

## Goal-Alignment Note
- Success criterion (restated verbatim): a code-fact-check report saved at that path, structured per the skill, verdicting at least the claims listed above.
- Answered: yes. All seven focus claims are verdicted (1→Claims 1/15, 2→2/5, 3→3/4, 4→8/9, 5→7, 6→16-19, 7→12/13), most of them executed against the stubbed launcher, including the old-script run and mutation checks of the new assertions.
- Out of scope: real Docker behaviour (restart of a stopped fail-closed container, image-cache hits); the host-side install/bless probe the commit names as its live verification.
- Escalate: Claim 6 / Claim 10 (`cc-isolated.sh:878`, `guides/cc-isolated-usage.md:955`, `:841`) are rebuild/recreate claims outside the diff. One contradicts the new hint in the fail-closed run, so the orchestrator should decide whether this unit absorbs them or the override log defers them.
- Decisions I made: treated the stopped-container restart path as Scope residue rather than downgrading Claim 1, because the hint is only printed against a running container; verdicted Claim 3 Mostly accurate rather than Verified because the --probe-only-run case is real, though it predates this change.
