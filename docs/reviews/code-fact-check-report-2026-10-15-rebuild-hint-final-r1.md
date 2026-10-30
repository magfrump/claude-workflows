Commit: 2463017f

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-rebuild-hint (branch fix/rebuild-hint-recreate)
**Scope:** `git diff 9660d4f6..2463017f` (devcontainer-config/cc-isolated.sh, devcontainer-config/init-firewall.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, test/init-firewall-rules.bats), the three commit bodies (cb56299c, 980a9db4, 2463017f), and the last two rows of docs/reviews/override-log.md. Other review artifacts under docs/reviews are excluded.
**Checked:** 2026-10-15
**Total claims checked:** 33 (31 numbered, two split into a/b)
**Summary:** 25 verified, 7 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. Its five entries are all fabricated counts or statistics. No claim in this unit cites a count, and none matches a logged pattern.

Execution provenance. Each run used a throwaway tree, `git archive <sha> | tar -x`, in the scratch dir. Old script versions were written into those trees with `git show <sha>:<path>`. Nothing was checked out. All suites ran via `bash scripts/run-tests.sh test/cc-isolated-functions.bats test/init-firewall-rules.bats` (290 tests), with the tree root as the cwd:
- E1 `tree-head` (2463017f as is): exit 0, 290/290 ok. Started 2026-10-15T11:35:29Z. Log: `/home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-final-r1/logs/head.log`
- E2 `tree-old9660` (HEAD tests, 9660d4f6 scripts): exit 1. Fails tests 27, 102 and 290, the three regression tests. Started 2026-10-15T11:35:29Z. Log: `.../fc-final-r1/logs/old9660.log`
- E3 `tree-old980a` (HEAD tests, 980a9db4 scripts): exit 1. Fails test 290 only, at `:1493`. Started 2026-10-15T11:35:29Z. Log: `.../fc-final-r1/logs/old980a.log`
- E4 the same tree as E3 with the `:1493` ordering assertion deleted: `timeout 300 bats -f 'fail-closed trap points at the launcher' test/init-firewall-rules.bats` exits 1, failing at `:1497`, the first `grep -qx`. Run 2026-10-15T11:38:14Z. Log: `.../fc-final-r1/logs/old980a-gx.log`
- E5 `tree-cb56old` (cb56299c tests, 9660d4f6 scripts): exit 1. Fails 27, 102 and 289, the three tests cb56299c names. Started 2026-10-15T11:40:15Z. Log: `.../fc-final-r1/logs/cb56old.log`
- E6 zsh 5.9: a command line piped into `zsh -f -i` (interactive, interactivecomments off) passes `#` and every word after it as arguments. With `setopt interactivecomments` it does not. Run 2026-10-15T11:38:34Z, exit 0. Logs: `.../fc-final-r1/logs/zsh-stdin-nocomments.log`, `.../zsh-stdin-comments.log`
- E7 `resolve_workspace launches`, run from inside a fresh repo whose `launches/` is a plain subdirectory, returns that repo's toplevel (rc 0). `resolve_workspace nonexist` prints `ERROR: not a directory`. Run 2026-10-15T11:38:48Z. Log: `.../fc-final-r1/logs/resolve-ws.log`
- E8 a bats 1.8.2 probe: `run ! grep -q x f` fails the test when grep matches ("expected nonzero exit code!"). This shows the `run !` assertions in the new tests can fail. File: `.../fc-final-r1/runbang/t.bats`

---

## Claim 1: "cc-isolated --probe-only [WS]  # recreate WS's container from the blessed config, run the boundary self-probe, record it verified live"

**Location:** `devcontainer-config/cc-isolated.sh:13-15`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the `--probe-only` branch does (recreate, probe, record). It does not establish that the image is rebuilt rather than reused from cache, which is devcontainer CLI behaviour.
**Legibility-target:** for-author

The recreate and the probe match the branch: `devcontainer up --remove-existing-container "${dc[@]}"` / `probe_boundary "$ws"` / `exit 0` (`cc-isolated.sh:894-896`). The record happens only on a pass. `probe_boundary` returns 1 before `record_verified_live` when `failures > 0` (`cc-isolated.sh:708-712`: `if [ "$failures" -gt 0 ]; then ... return 1; fi` / `record_verified_live`). The line drops that "on a pass" qualifier, which the guide's copy at `guides/cc-isolated-usage.md:25-26` keeps ("record the config verified live on a pass"). The qualifier was missing before this diff too. The diff only rewrapped the line.

**Evidence:** `devcontainer-config/cc-isolated.sh:13-15`, `devcontainer-config/cc-isolated.sh:708-712`, `devcontainer-config/cc-isolated.sh:891-896`, `guides/cc-isolated-usage.md:25-26`

---

## Claim 2: "A launch on an unverified config says so, recreates the container if it was built from another config so the probe exercises the new config rather than an old image (--probe-only always recreates), and refuses to start a session unless the baked firewall script reached its completion marker."

**Location:** `devcontainer-config/cc-isolated.sh:61-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main()'s NOTE, the hash-mismatch recreate, the unconditional `--probe-only` recreate and the firewall-marker refusal. It does not establish that the recreate rebuilds image layers. Note that the conditional recreate runs on every launch, not only on unverified ones.
**Legibility-target:** for-orchestrator-synthesis

- "says so": `if ! is_verified_live; then echo "NOTE: blessed config ... has NOT been verified ..."` (`cc-isolated.sh:882-883`).
- Recreate only on mismatch: `devcontainer up "${dc[@]}"` then `if ! container_config_matches "${dc[@]}"; then ... devcontainer up --remove-existing-container` (`cc-isolated.sh:899-907`). `container_config_matches` compares `/etc/cc-config-hash` against `CC_CONFIG_HASH` (`cc-isolated.sh:580-584`).
- `--probe-only` recreates unconditionally (`cc-isolated.sh:894`).
- The marker refusal: `if ! devcontainer exec "${dc[@]}" test -f /run/cc-firewall/complete; then ... failures=$((failures + 1))` (`cc-isolated.sh:700-706`). A failed probe outside an `if` exits under `set -e` before `devcontainer exec ... claude` (`cc-isolated.sh:929`, `:938`).

**Evidence:** `devcontainer-config/cc-isolated.sh:61-65`, `:580-584`, `:700-712`, `:882-907`, `:929-938`

---

## Claim 3: "Next: cc-isolated --probe-only <repo>" / "(recreates the container from it and probes as node)"

**Location:** `devcontainer-config/cc-isolated.sh:318-319`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `--probe-only` recreate from the just-blessed config, and the probes running as the container's remoteUser `node`. It does not establish which root-run checks exist inside the probe. That is pre-existing text.
**Legibility-target:** for-orchestrator-synthesis

The line is printed by `bless_manifest` on the unverified branch (`cc-isolated.sh:314-320`). `--probe-only` sets `CC_CONFIG_HASH="$(blessed_hash)"` (`:841-842`) and runs `devcontainer up --remove-existing-container` (`:894`). Probes run through `devcontainer exec`, and `devcontainer.json:71` sets `"remoteUser": "node"`. The command now stands alone on its line, with no trailing `#`.

**Evidence:** `devcontainer-config/cc-isolated.sh:314-320`, `:841-842`, `:894`, `devcontainer-config/devcontainer.json:71`

---

## Claim 4: "a plain launch recreates only when the baked config hash differs, so a fail-closed container built from the blessed config would be reused, not recovered."

**Location:** `devcontainer-config/cc-isolated.sh:563-565`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main()'s plain-launch recreate decision and the fail-closed path (hash matches, marker missing, re-run of init-firewall.sh fails). It does not establish real Docker/devcontainer behaviour; the test stubs the CLI.
**Legibility-target:** for-orchestrator-synthesis

The only `--remove-existing-container` on the launch path is gated: `if ! container_config_matches "${dc[@]}"; then` (`cc-isolated.sh:904`). On a fail-closed container the re-assert fails and main returns before any recreate: `if ! devcontainer exec "${dc[@]}" sudo /usr/local/bin/init-firewall.sh; then ... rebuild_hint ...; return 1` (`:922-927`). E1 runs test 102 (`test/cc-isolated-functions.bats:1392-1412`), which asserts `run ! grep -q -- '--remove-existing-container' "$DC_LOG"`, and it passes. E8 shows that assertion can fail.

**Evidence:** `devcontainer-config/cc-isolated.sh:899-927`, `test/cc-isolated-functions.bats:1392-1412`, `.../fc-final-r1/logs/head.log`, `.../fc-final-r1/runbang/t.bats`

---

## Claim 5: "--probe-only always recreates, and exits non-zero on a failed probe, so the `&&` never starts a session after one."

**Location:** `devcontainer-config/cc-isolated.sh:565-566`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--probe-only` branch's recreate and its exit status on a probe failure (and on a failed `devcontainer up`, via `set -e`). It does not establish that the recreate fixes the failure; see Claim 7b.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:891-896
  if [ "$action" = "probe" ]; then
    # --probe-only is the verification command, so it always recreates: ...
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
  fi
```
(excerpt ends :896; enclosing main() continues to :950 — read)

`probe_boundary` runs outside a conditional, so its `return 1` (`:710`) ends the script non-zero under `set -euo pipefail` (`:68`). The branch has no `claude` exec. In E1, tests 103 and 104 (`test/cc-isolated-functions.bats:1414-1442`) pass: test 104 gets `status -ne 0`, a forced recreate and no receipt.

**Evidence:** `devcontainer-config/cc-isolated.sh:68`, `:708-712`, `:891-896`, `test/cc-isolated-functions.bats:1414-1442`, `.../fc-final-r1/logs/head.log`

---

## Claim 6: "The explanation is on its own line, not a trailing `# ...`: interactive zsh without interactivecomments would pass those words to step 2 as arguments."

**Location:** `devcontainer-config/cc-isolated.sh:567-568`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers zsh 5.9's interactive parsing with the option off (its default), and the fact that the printed command line now has nothing after it. It does not establish behaviour of other shells (bash treats `#` as a comment interactively).
**Legibility-target:** for-orchestrator-synthesis

In E6, `printf "[%s]\n" cc-isolated proj # the supported path: ...` piped into `zsh -f -i` printed `[#]`, `[the]`, ... `[re-launches]` as arguments. The same line under `setopt interactivecomments` printed only `[cc-isolated]` and `[proj]`. Line `:569` echoes only the command, and `:570` carries the explanation.

**Evidence:** `devcontainer-config/cc-isolated.sh:567-570`, `.../fc-final-r1/logs/zsh-stdin-nocomments.log`, `.../fc-final-r1/logs/zsh-stdin-comments.log`

---

## Claim 7a: Printed recipe `cc-isolated --probe-only WS && cc-isolated WS` is the right recovery for the fail-closed caller (main, plain launch)

**Location:** `devcontainer-config/cc-isolated.sh:569-570` (caller `:926`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the launcher's side: step 1 recreates the container unconditionally, which reruns postStartCommand's init-firewall.sh on a fresh container (`devcontainer.json:141`); step 2 runs only on a passing probe. It does not establish that a transient outage has cleared by the time the user reruns it (external).
**Legibility-target:** for-orchestrator-synthesis

The fail-closed caller is reached only after the hash matched, so a plain relaunch would reuse the container (Claim 4). Step 1's forced recreate (`:894`) is the one path that discards it. `ws` is the resolved toplevel, shell-quoted: `$(printf '%q' "$ws")` (`:569`).

**Evidence:** `devcontainer-config/cc-isolated.sh:569-570`, `:894`, `:922-927`, `devcontainer-config/devcontainer.json:141`

---

## Claim 7b: The same recipe is the right recovery for the image-provenance and config-identity callers when reached from a plain launch

**Location:** `devcontainer-config/cc-isolated.sh:676-677`, `:690-691`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what step 1 does for these two failures on the plain-launch path. It does not establish devcontainer CLI image-cache behaviour, and it does not cover the `--probe-only`-run case the override log already defers (C4).
**Legibility-target:** for-author

The recipe is safe here: the `&&` stops step 2 on a failed probe (Claim 5). It is no worse than the old bare relaunch. But for these two callers it is a retry, not a recovery:
- Config identity: a plain launch has already recreated on a hash mismatch (`cc-isolated.sh:904-907`) by the time the probe reports one. Step 1 repeats the same `devcontainer up --remove-existing-container "${dc[@]}"` with the same exports (`:894`).
- Image provenance: its causes are build-side, such as the shadowing `.devcontainer/Dockerfile` that `guides/cc-isolated-usage.md`'s provenance row names. Every egress profile file is in the manifest and so changes the hash, which means a provenance failure with a matching hash points at the build, not at a stale container. (Paraphrased: no quote available because this conclusion is inferred from `enforcement_files` (`cc-isolated.sh:130-154`) together with the probe at `:665-680`.)

The override log's C4 row records the same limitation for the `--probe-only` run. The plain-launch path shares it. The hint's "the supported path" wording stays accurate.

**Evidence:** `devcontainer-config/cc-isolated.sh:130-154`, `:665-693`, `:894`, `:904-907`, `docs/reviews/override-log.md` (penultimate row)

---

## Claim 8: "This run is that verification: the container is recreated if it was built from another config, and the self-probe must pass ... before anything starts. A pass records the hash in $(verified_path)."

**Location:** `devcontainer-config/cc-isolated.sh:882-887`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the plain-launch path (conditional recreate, probe gate, record on pass). Under `--probe-only` the recreate is unconditional, so the sentence is true but narrower than what happens. It does not establish a first launch, where no container exists to "recreate".
**Legibility-target:** for-orchestrator-synthesis

See Claim 2 for the code. Recording happens only on the full pass (`cc-isolated.sh:712`). In E1, test 102 passes its assertions `*"has NOT been verified in a live container"*` and `!= *"the container is rebuilt from it"*` (`test/cc-isolated-functions.bats:1407-1408`). In E2, the 9660d4f6 NOTE fails that test, which stops first at the hint assertion `:1405`.

**Evidence:** `devcontainer-config/cc-isolated.sh:882-887`, `:712`, `:894`, `:904-907`, `test/cc-isolated-functions.bats:1406-1408`, `.../logs/head.log`, `.../logs/old9660.log`

---

## Claim 9: "--probe-only is the verification command, so it always recreates"

**Location:** `devcontainer-config/cc-isolated.sh:892`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unconditional `--remove-existing-container` on the probe branch. It does not establish image-layer reuse.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer up --remove-existing-container "${dc[@]}"` is the first statement of the branch (`cc-isolated.sh:894`), with no condition.

**Evidence:** `devcontainer-config/cc-isolated.sh:891-896`

---

## Claim 10: init-firewall.sh comments: "--probe-only always recreates the container from the blessed config and re-probes. The explanations are not trailing `# ...` comments on the command lines: interactive zsh without interactivecomments passes those words to cc-isolated as arguments, and the last positional becomes the workspace."

**Location:** `devcontainer-config/init-firewall.sh:346-349`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--probe-only` recreate, zsh's parsing (E6) and main()'s argument loop (`*) ws_arg="$1"`, so the last positional wins). It does not establish what happens next with that workspace, which is not claimed here; see Claim 16b.
**Legibility-target:** for-orchestrator-synthesis

The argument loop has `*)            ws_arg="$1"; shift ;;` (`cc-isolated.sh:759`), so each later bare word overwrites the earlier one. On the zsh part, see E6. On "re-probes", see Claim 5. The surrounding unit, `fail_closed_on_abort` (`init-firewall.sh:300-357`), was read in full. The recipe prints only on the incomplete-run branch, after the forced DROP.

**Evidence:** `devcontainer-config/init-firewall.sh:300-357`, `devcontainer-config/cc-isolated.sh:741-761`, `.../logs/zsh-stdin-nocomments.log`

---

## Claim 11: init-firewall.sh printed recipe: "The first command recreates it from the blessed config and re-probes; the second starts the session:" / "cc-isolated --probe-only <repo>" / "cc-isolated <repo>"

**Location:** `devcontainer-config/init-firewall.sh:350-355`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text, the commands being alone on their lines, and what each command does. It does not establish the outcome of pasting both lines at once: they have no `&&` (api i1 #5, pre-existing), though step 2 then runs its own probe gate.
**Legibility-target:** for-orchestrator-synthesis

The command lines are `echo "         cc-isolated --probe-only <repo>" >&2` and `echo "         cc-isolated <repo>" >&2` (`init-firewall.sh:354-355`). "Starts the session" holds subject to the plain launch's probe gate (Claim 2). Test 290 passes at HEAD (E1).

**Evidence:** `devcontainer-config/init-firewall.sh:350-355`, `test/init-firewall-rules.bats:1484-1500`, `.../logs/head.log`

---

## Claim 12: "cc-isolated --probe-only [REPO]   # RECREATE REPO's container from the blessed config, run the self-probe, record the config verified live on a pass"

**Location:** `guides/cc-isolated-usage.md:25-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the probe branch and the record-on-pass condition. It does not establish image-layer reuse.
**Legibility-target:** for-orchestrator-synthesis

See Claim 1: `:894` recreates, and `:708-712` records only after `failures` is 0.

**Evidence:** `guides/cc-isolated-usage.md:25-26`, `devcontainer-config/cc-isolated.sh:708-712`, `:894`

---

## Claim 13: "Run the verification explicitly after any boundary change — it always recreates the container first, so it can never verify a leftover container"

**Location:** `guides/cc-isolated-usage.md:841-842`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unconditional recreate before `probe_boundary`. "Never verify a leftover" additionally relies on the probe's config-identity check (`:681-693`), which was read.
**Legibility-target:** for-orchestrator-synthesis

The recreate is at `cc-isolated.sh:894` and runs before `probe_boundary "$ws"` at `:895`.

**Evidence:** `guides/cc-isolated-usage.md:841-842`, `devcontainer-config/cc-isolated.sh:681-693`, `:891-896`

---

## Claim 14: "Expected after `install.sh`, `--bless` or `--register`. The launch recreates the container if it was built from another config, then verifies"

**Location:** `guides/cc-isolated-usage.md:955`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the NOTE's trigger (an unverified hash after any bless path: install.sh runs `--bless` at `install.sh:607`, and `register_project` calls `bless_manifest` at `cc-isolated.sh:479`) and the conditional recreate. It does not establish whether a given bless actually changed the hash.
**Legibility-target:** for-orchestrator-synthesis

On the conditional recreate, see Claim 2 (`:904-907`). On the NOTE condition, see `:882`.

**Evidence:** `guides/cc-isolated-usage.md:955`, `devcontainer-config/cc-isolated.sh:479`, `:882`, `:904-907`, `devcontainer-config/install.sh:607`

---

## Claim 15: "Relaunch with `cc-isolated <repo>`, which recreates it with both set."

**Location:** `guides/cc-isolated-usage.md:963`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's scenario: the container was built by hand with empty `CC_CONFIG_HASH`, so `/etc/cc-config-hash` is empty. It does not establish the `CC_EGRESS_PROFILE` value beyond what registration supplies.
**Legibility-target:** for-orchestrator-synthesis

An empty baked hash differs from the blessed one. `container_config_matches` therefore fails (`[ "$have" = "$CC_CONFIG_HASH" ]`, `cc-isolated.sh:583`), and the launch recreates with the exports set at `:823-831` and `:841-842`.

**Evidence:** `guides/cc-isolated-usage.md:963`, `devcontainer-config/cc-isolated.sh:580-584`, `:823-842`, `:904-907`

---

## Claim 16a: "It is the guides' two-step recipe, never a bare relaunch: a plain launch recreates only on a config-hash mismatch, so in the fail-closed state it does not recover"

**Location:** `test/cc-isolated-functions.bats:351-353`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment and the exact-line assertion `:360`. That assertion fails on the 9660d4f6 text (E2, test 27) and on cb56299c's version of the test (E5).
**Legibility-target:** for-orchestrator-synthesis

The assertion is `[ "$(echo "$output" | head -1)" = "    cc-isolated --probe-only $ws && cc-isolated $ws" ]` (`:360`). The guide's two-step recipe appears at `guides/cc-isolated-usage.md:957`.

**Evidence:** `test/cc-isolated-functions.bats:349-363`, `guides/cc-isolated-usage.md:957`, `.../logs/old9660.log`, `.../logs/cb56old.log`

---

## Claim 16b: "the last positional becomes the workspace, so step 2 fails or, if that word names a git repo in the cwd, launches it"

**Location:** `test/cc-isolated-functions.bats:355-359`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers resolve_workspace's handling of the stray word. It does not establish other shells.
**Legibility-target:** for-author

`resolve_workspace` does `git -C "$start" rev-parse --show-toplevel` on any existing directory (`cc-isolated.sh:357-370`). The word therefore does not need to name a git repo. Any directory of that name in the cwd that lies inside some git work tree resolves to that work tree's toplevel. In E7, a plain `launches/` subdirectory of the current repo resolved to the repo itself. Precise version: "...so step 2 fails, unless that word names a directory in the cwd that is inside a git work tree, in which case it launches that work tree".

**Evidence:** `devcontainer-config/cc-isolated.sh:357-370`, `test/cc-isolated-functions.bats:355-359`, `.../logs/resolve-ws.log`

---

## Claim 17: "STUB_FW_BRICKED=1 → re-running the baked init-firewall.sh fails (fail-closed state)."

**Location:** `test/cc-isolated-functions.bats:1157`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the stub case and its ordering. No earlier case matches main's `sudo /usr/local/bin/init-firewall.sh` exec.
**Legibility-target:** for-orchestrator-synthesis

The stub case is `*init-firewall.sh*)      [ -z "${STUB_FW_BRICKED:-}" ] ;;` (`:1171`). The earlier patterns (`*cc-config-hash*`, `*rev-parse*`, `*cc-firewall/complete*`) do not occur in that command.

**Evidence:** `test/cc-isolated-functions.bats:1160-1185`, `devcontainer-config/cc-isolated.sh:922`

---

## Claim 18: Fail-closed launch test: comments "in the fail-closed state the container was built from the blessed config, so a plain launch does not recreate it, and the hint used to send the user straight back into that launch", "The unverified-config NOTE must not promise the recreate this launch skips", "this launch reused the container and never started claude"

**Location:** `test/cc-isolated-functions.bats:1389-1412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each comment against its assertion. It also covers the test failing on 9660d4f6 (E2: `:1405`) and on cb56299c's test against the old scripts (E5). It does not establish real-container behaviour.
**Legibility-target:** for-orchestrator-synthesis

The 9660d4f6 hint line was `cc-isolated $(printf '%q' "$ws")        # the supported path: rebuilds, re-probes, re-launches` (diff, removed line), a bare relaunch. The `run !` assertions at `:1410-1411` can fail (E8).

**Evidence:** `test/cc-isolated-functions.bats:1389-1412`, `.../logs/old9660.log`, `.../logs/cb56old.log`, `.../runbang/t.bats`

---

## Claim 19: "The hint's `&&` relies on this: a failed probe after the forced recreate must exit non-zero and never start claude"

**Location:** `test/cc-isolated-functions.bats:1427-1442`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit status, the forced recreate and the missing receipt, all asserted. "Never start claude" is true of the code, because the probe branch has no claude exec (`cc-isolated.sh:891-896`), but the test no longer asserts it. 2463017f dropped that assertion and renamed the test.
**Legibility-target:** for-orchestrator-synthesis

The assertions are `[ "$status" -ne 0 ]`, `grep -q '^devcontainer up --remove-existing-container ' "$DC_LOG"` and `[ ! -f "$(verified_path)" ]`. They pass in E1.

**Evidence:** `test/cc-isolated-functions.bats:1427-1442`, `devcontainer-config/cc-isolated.sh:891-896`, `.../logs/head.log`

---

## Claim 20: "--probe-only recreates the container (cached image layers are reused), the word the guides use"

**Location:** `test/init-firewall-rules.bats:1491-1492`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers "recreates" (Verified, `cc-isolated.sh:894`) and "the word the guides use" (`guides/cc-isolated-usage.md:25`, `:841`, `:957`). The parenthetical depends on devcontainer CLI and Docker build-cache behaviour, which no code here shows.
**Legibility-target:** for-orchestrator-synthesis

Verifying layer reuse would need a host with Docker and the devcontainer CLI. The sandbox has neither. The parenthetical is incidental and nothing asserts it.

**Evidence:** `test/init-firewall-rules.bats:1491-1494`, `devcontainer-config/cc-isolated.sh:894`

---

## Claim 21: "Each command line is the command alone: a trailing `# ...` is passed as arguments by interactive zsh without interactivecomments" (with the two `grep -qx` pins), and the 2463017f claim that each new assertion fails on the previous text

**Location:** `test/init-firewall-rules.bats:1495-1499`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first `grep -qx` failing on the 980a9db4 text (E4) and the whole test failing on 980a9db4 (E3) and 9660d4f6 (E2). The second pin's failure on the old `cc-isolated <repo>                 # then start the session` line is static (it cannot match `-x`). It does not establish a pin on the bless "Next:" line, and 2463017f does not claim one.
**Legibility-target:** for-orchestrator-synthesis

The pins are `printf '%s\n' "$output" | grep -qx ' *cc-isolated --probe-only <repo>'` and `... grep -qx ' *cc-isolated <repo>'`. In E4 the run stopped at `:1497`.

**Evidence:** `test/init-firewall-rules.bats:1495-1499`, `.../logs/old980a.log`, `.../logs/old980a-gx.log`

---

## Claim 22: cb56299c body: mechanism, edit list, and "All three [tests] fail on the old text"

**Location:** commit cb56299c (body, paragraphs 1-3)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the description of the fail-closed reuse, the edited sites (the two "Rebuild with:" lead-ins, main's `--probe-only` comment, init-firewall's comment and echo, guide `:25` and `:963`) and the three tests failing on 9660d4f6 (E5). The Notes are Claim 23.
**Legibility-target:** for-orchestrator-synthesis

`git show cb56299c -- guides/` touches exactly the `:25` and `:963` rows. E5 fails tests 27, 102 and 289, matching the body's three tests.

**Evidence:** `devcontainer-config/cc-isolated.sh:676`, `:690`, `:892`, `devcontainer-config/init-firewall.sh:346`, `guides/cc-isolated-usage.md:25`, `:963`, `.../logs/cb56old.log`

---

## Claim 23: cb56299c Notes: "(a guide row quotes it verbatim)" and "the next launch recreates each project's container once (init-firewall.sh is baked into the image)"

**Location:** commit cb56299c (Notes)
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both Notes clauses and 980a9db4's correction of them. It does not reopen the immutable commit.
**Legibility-target:** for-orchestrator-synthesis

The guide row reads `Blessed config changed since this container was built — rebuilding` (`guides/cc-isolated-usage.md:956`). The code prints `... — rebuilding it.` (`cc-isolated.sh:905`), so the quote is not verbatim. The recreate is caused by the hash change: both scripts are in `enforcement_files` (`cc-isolated.sh:135`, `:138`). The script reaches the image through `COPY init-firewall.sh /usr/local/bin/` (`Dockerfile:487`). 980a9db4's A4 paragraph states both corrections accurately.

**Evidence:** `guides/cc-isolated-usage.md:956`, `devcontainer-config/cc-isolated.sh:130-140`, `:905`, `devcontainer-config/Dockerfile:484-487`

---

## Claim 24: 980a9db4 body, A1: "main() keeps the last positional, so the launch retargeted to ./launches"

**Location:** commit 980a9db4 (A1)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism. cb56299c's line ended `... re-probes, then launches`, so the last word is `launches` (`git show cb56299c:devcontainer-config/cc-isolated.sh`, line 564). It does not reopen the commit; 2463017f corrects the outcome.
**Legibility-target:** for-orchestrator-synthesis

The mechanism is right (E6, `cc-isolated.sh:759`). The outcome is overstated: usually `ERROR: not a directory: launches` (E7). See Claims 16b and 26 for the precise condition.

**Evidence:** `devcontainer-config/cc-isolated.sh:357-370`, `:759`, `.../logs/resolve-ws.log`

---

## Claim 25: 980a9db4 body, A2-A4, C1-C3, C6, and its "rebuild stays where the image really is rebuilt" note

**Location:** commit 980a9db4 (A2, A3, A4, C1, C2, C3, C6, Notes)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the following:
- The three NOTE/header/guide-row rewrites.
- The `--help` wording.
- Guide `:841`.
- The new `--probe-only` fail test and the C6 rename.
- The A4 correction.
- "rebuild" kept at `cc-isolated.sh:481` ("Next launch rebuilds the image for the new profile.") and in the HOST_TOOLS re-bless notes (`:768`, `:770`).
- The "rebuilding it." line, which "a test matches": `test/cc-isolated-functions.bats:1360` matches its prefix only.

C1's label is Claim 27. C3's original test name ("starts no session") was renamed in 2463017f. Neither sentence is reopened here.
**Legibility-target:** for-orchestrator-synthesis

"In the fail-closed state the receipt is missing and the hash matches, so it does not [rebuild]". The causal part is the hash match (`:904`). The receipt is missing in the scenario where the NOTE prints at all (`:882`). The sentence is accurate as a scenario description.

**Evidence:** `devcontainer-config/cc-isolated.sh:13-15`, `:61-64`, `:481`, `:768-770`, `:882-887`, `:904-905`, `guides/cc-isolated-usage.md:841`, `:955`, `test/cc-isolated-functions.bats:1360`

---

## Claim 26: 2463017f body, A5: "the launch retargeted to ./launches happens only when ./launches is a git repo; otherwise step 2 errors out" (and the test-comment description "launches that word's repo only if it names a git repo in the cwd")

**Location:** commit 2463017f (A5)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers resolve_workspace's two outcomes for a stray word. It does not reopen the immutable commit.
**Legibility-target:** for-author

In E7, `./launches` as a plain subdirectory of a git work tree resolves to that work tree's toplevel and does not error out. `git -C launches rev-parse --show-toplevel` succeeds for any directory inside a work tree (`cc-isolated.sh:363`). Precise version: "...only when ./launches is a directory inside a git work tree (then that work tree is launched); otherwise step 2 errors out". This narrows, without overturning, the iteration-2 A5 correction.

**Evidence:** `devcontainer-config/cc-isolated.sh:357-370`, `.../logs/resolve-ws.log`

---

## Claim 27: 2463017f body, A6: "the 'Next:' line it calls the --list line is printed by bless_manifest (--bless, --register, install.sh), not by --list"

**Location:** commit 2463017f (A6)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the callers of `bless_manifest` and the contents of `--list`. It does not cover the HOST_TOOLS refusal path, which never calls bless.
**Legibility-target:** for-orchestrator-synthesis

The callers are: `bless) bless_manifest; exit 0 ;;` (`cc-isolated.sh:798`); `register_project` → `bless_manifest` (`:479`); and install.sh → `"$DEST/cc-isolated.sh" --bless` (`install.sh:607`). `list_projects` prints `verified live: NO (run: cc-isolated --probe-only <repo>)`, with no "Next:" and no "recreates" (`:490`).

**Evidence:** `devcontainer-config/cc-isolated.sh:314-320`, `:479`, `:490`, `:798`, `devcontainer-config/install.sh:607`

---

## Claim 28: 2463017f body, A7, the test-drop, C9, and Notes ("commands are now alone on their lines with the explanation above or below"; "the init-firewall test pins both command lines with grep -x"; "drops its 'no claude' assertion, which could never fail"; "--help's --probe-only line rewrapped to the block's width"; "no iptables call, probe check, recreate decision or exit status changed")

**Location:** commit 2463017f (A7, test paragraph, C9, Notes)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the following:
- The layout: init-firewall's explanation sits above its commands (`:351-353`) and bless's below (`:319`).
- The `grep -x` pins (E4).
- The probe branch having no claude exec (`:891-896`).
- The `--help` widths: 83/86/59 columns, against neighbours of 83-94; previously 99.
- The script diffs touching only `echo` and comment lines.
**Legibility-target:** for-orchestrator-synthesis

The script hunks in `diff-final.patch` alter only `echo` strings and `#` comments. No test, `iptables`, `devcontainer` or `return`/`exit` line changes. (Paraphrased: no quote available because this claim covers the absence of non-echo/non-comment changes across the whole patch.)

**Evidence:** `devcontainer-config/cc-isolated.sh:13-15`, `:318-319`, `:891-896`, `devcontainer-config/init-firewall.sh:346-355`, `test/init-firewall-rules.bats:1495-1499`, `.../logs/old980a-gx.log`

---

## Claim 29: Override-log row (fix/rebuild-hint-recreate, C4): "A provenance or config-identity failure printed inside a `--probe-only` run points back at `--probe-only` ... (`devcontainer-config/cc-isolated.sh:670-689`, fact-check claim 3, security #3, api-consistency F6; pre-existing)"

**Location:** `docs/reviews/override-log.md` (penultimate row)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the description, the cited review items and the line range at HEAD. It does not cover the plain-launch extension noted in Claim 7b.
**Legibility-target:** for-author

The description matches the code (`--probe-only` → `probe_boundary` → `rebuild_hint` at `:677`, `:691`). The cited items exist: the i1 fact-check `## Claim 3:` on the hint line; the security i1 `#### 3. Hint printed during a --probe-only run points back at --probe-only`; and the api i1 `#### 6. The provenance/config-identity hint is printed during a --probe-only run ...`. The range `:670-689` is 980a9db4's numbering. At 2463017f the blocks span `:665-693`, and the config-identity hint call (`:691`) and its lead-in (`:690`) fall outside the cited range.

**Evidence:** `devcontainer-config/cc-isolated.sh:665-693`, `docs/reviews/code-fact-check-report-2026-10-15-rebuild-hint.md:91`, `docs/reviews/security-review-2026-10-15-rebuild-hint.md:63`, `docs/reviews/api-consistency-review-2026-10-15-rebuild-hint.md:118`

---

## Claim 30: Override-log row (fix/rebuild-hint-recreate, install.sh): "`install.sh`'s 'Next steps' block prints placeholder commands with trailing `# ...` notes ... and its `--probe-only` row still says 'rebuilds' (`devcontainer-config/install.sh:612-617` ...)"; "install.sh is a third enforcement file with its own tests"

**Location:** `docs/reviews/override-log.md` (last row)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited lines, the "rebuilds" wording, install.sh being in the live-verify gate's set and the existence of its tests. It does not cover the row's likelihood/severity judgement, which is not a checkable claim.
**Legibility-target:** for-orchestrator-synthesis

The block is `echo "Next steps:"` (`install.sh:611`), followed by six lines with trailing `#` notes (`:612-617`). Line `:613` reads `# REQUIRED after any boundary change: rebuilds from`. The gate's header says "any enforcement file under devcontainer-config/ (the ones the trust manifest hashes, plus install.sh per decision 035)" (`hooks/live-verify-gate.sh:13-15`). `test/install-host.bats` exists.

**Evidence:** `devcontainer-config/install.sh:607-617`, `hooks/live-verify-gate.sh:13-16`, `test/install-host.bats`

---

## Claim 31: 2463017f body: "C4 (pre-existing --probe-only loop on a build failure) is logged in the override log with its revisit trigger" and "install.sh's 'Next steps' block ... is deferred (override log row, revisit trigger: its next edit)"

**Location:** commit 2463017f (A7, C4 lines)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of both rows, their Defer decisions and their revisit triggers. Its correctness about line numbers is Claim 29.
**Legibility-target:** for-orchestrator-synthesis

The two rows read "Revisit trigger: a user reports a `--probe-only` loop on either failure, or the next change to probe_boundary's failure messages" and "Revisit trigger: the next edit to install.sh's 'Next steps' block, or a user report of a stray workspace argument" (`docs/reviews/override-log.md`, last two rows).

**Evidence:** `docs/reviews/override-log.md` (last two rows)

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 1** (`devcontainer-config/cc-isolated.sh:13-15`): the `--help` line says "record it verified live" without "on a pass". The guide's copy keeps the qualifier. Pre-existing, rewrapped here.
- **Claim 7b** (`devcontainer-config/cc-isolated.sh:676-677`, `:690-691`): for provenance/config-identity failures on a plain launch, the recipe is a safe retry, not a recovery. The cause is the build, and the launch already recreated on a mismatch. This is the deferred C4 limitation, which the plain-launch path shares.
- **Claim 16b** (`test/cc-isolated-functions.bats:355-359`): "if that word names a git repo in the cwd" should be "names a directory in the cwd that is inside a git work tree". resolve_workspace takes the toplevel of any directory (E7).
- **Claim 23** (commit cb56299c Notes): non-verbatim quote, and the stated cause of the recreate is wrong. Already corrected in 980a9db4.
- **Claim 24** (commit 980a9db4 A1): the "retargeted to ./launches" outcome is overstated. Already corrected in 2463017f.
- **Claim 26** (commit 2463017f A5): "otherwise step 2 errors out" also misses a plain directory inside a git work tree, which launches that work tree. Same refinement as Claim 16b.
- **Claim 29** (`docs/reviews/override-log.md`, C4 row): `cc-isolated.sh:670-689` is 980a9db4's numbering. At HEAD the blocks are `:665-693`, and the second hint call `:691` is outside the range.

### Unverifiable
- **Claim 20** (`test/init-firewall-rules.bats:1491`): "(cached image layers are reused)" needs a Docker host with the devcontainer CLI to observe.

## Goal-Alignment Note
- Success criterion (restated verbatim): a code-fact-check report saved at the path below, structured per the skill, verdicting at least the claims listed above.
- Answered: yes. All seven brief items are verdicted, each regression test was executed against the old script text, and zsh and resolve_workspace were run directly.
- Out of scope: real-container behaviour (no Docker); install.sh's block itself (deferred, only its override row checked); review artifacts other than the two override rows.
- Escalate: nothing blocking. Claims 16b/26 (resolve_workspace takes any directory inside a work tree) refine an earlier correction. Claim 7b extends deferred C4 to the plain-launch path.
- Decisions I made: I counted guide `:957` (the PROBE FAIL firewall row) as "the guides' two-step recipe" for Claim 16a. I verdicted the immutable commit bodies' already-corrected sentences Mostly accurate rather than skipping them as superseded.
