# Code Fact-Check Report

Commit: 2463017f

**Repository:** claude-workflows (worktree /workspace/.claude/wt-rebuild-hint, branch fix/rebuild-hint-recreate)
**Scope:** `git diff 9660d4f6..2463017f` minus docs/reviews review artifacts (devcontainer-config/cc-isolated.sh, devcontainer-config/init-firewall.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, test/init-firewall-rules.bats), plus the two override-log rows the branch appends and the bodies of cb56299c, 980a9db4, 2463017f
**Checked:** 2026-10-15
**Commit:** 2463017f
**Replication:** replicate r3 of k=3 (final confirming pass)
**Total claims checked:** 43
**Summary:** 34 verified, 8 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read first; no claim below matches a logged pattern.

Execution provenance (shared by every `executed` claim). Scratch dir `S=/home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-final-r3`; captured output in `$S/`:

| Run | Command | cwd | Exit | UTC | Output |
|---|---|---|---|---|---|
| R1 | `timeout 600 bash scripts/run-tests.sh test/cc-isolated-functions.bats` | worktree | 0 (195/195 ok) | 2026-10-15T11:35:12Z | `$S/bats-new-cc.log` |
| R2 | `timeout 600 bash scripts/run-tests.sh test/init-firewall-rules.bats` | worktree | 0 (95/95 ok) | 2026-10-15T11:36Z | `$S/bats-new-fw.log` |
| R3 | `timeout 600 bash scripts/run-tests.sh test/cc-isolated-functions.bats test/init-firewall-rules.bats` on a `git archive 2463017f` copy with both scripts replaced by their 9660d4f6 versions | `$S/tree-old` | 1: not ok 27 (rebuild_hint, :360), 102 (fail-closed launch, :1405), 290 (fail-closed trap, init-firewall-rules :1493); 103, 104 ok | 2026-10-15T11:37:35Z | `$S/bats-old.log` |
| R4 | same, both scripts at 980a9db4 (init-firewall.sh identical to cb56299c's) | `$S/tree-980` | 1: only not ok 290 (:1493) | 2026-10-15T11:37:35Z | `$S/bats-980.log` |
| R5 | `bash $S/gx-probe.sh` (runs each version's fail-closed recipe echo lines, applies the test's two `grep -qx` checks) | worktree | 0; cb56299c: both greps exit 1; 2463017f: both 0 | 2026-10-15T11:39:51Z | `$S/gx-probe.log` |
| R6 | `bash $S/zsh-probe.sh` (feeds `f --probe-only /some/ws # the supported path: ...` to `zsh -f -i`, with and without `setopt interactivecomments`; `f` prints each arg in brackets) | `$S` | 0 | 2026-10-15T11:40:25Z | `$S/zsh-probe.log` |
| R7 | `resolve_workspace launches` (sourced cc-isolated.sh) from inside a fresh git repo whose `launches/` is a plain subdirectory | `$S/rw/repo` | 0, printed `$S/rw/repo` | 2026-10-15T11:40:30Z | `$S/rw.log` |
| R8 | `LC_ALL=C timeout 300 bats -f 'fail-closed container does not recreate'` on an archive copy whose `container_config_matches` starts with `return 1` (mutant: always recreate) | `$S/tree-mut` | 1 (caught at :1410) | 2026-10-15T11:40:33Z | `$S/bats-mutant-recreate.log` |
| R9 | `git diff 9660d4f6..2463017f -- devcontainer-config \| grep '^[-+]' \| grep -v '^[-+][-+]' \| grep -v '^[-+]\s*#' \| grep -v '^[-+]\s*echo'`; `grep -n -i rebuil` on both scripts | worktree | 1 (no lines) | 2026-10-15T11:41:49Z | `$S/non-comment-diff.log` (0 bytes), `$S/rebuild-grep.log` |
| R10 | cb56299c's own tests against 9660d4f6 scripts: `LC_ALL=C timeout 300 bats -f '...'` (three tests) | `$S/tree-cb56` | 1 (all three not ok) | 2026-10-15T11:42:14Z | `$S/bats-cb56-tests-old-scripts.log` |

---

## Claim 1: "--probe-only [WS] # recreate WS's container from the blessed config, run the boundary self-probe, record it verified live"

**Location:** `devcontainer-config/cc-isolated.sh:13-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe branch of main() and the record-on-pass in probe_boundary; does not establish the devcontainer CLI's own recreate semantics (no Docker here).
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/cc-isolated.sh:894-896`: `devcontainer up --remove-existing-container "${dc[@]}"` / `probe_boundary "$ws"` / `exit 0`. `dc` carries `--override-config "$(config_dir)/devcontainer.json"` and main exports `CC_CONFIG_HASH="$(blessed_hash)"` before it. probe_boundary records only after `failures` is 0: `record_verified_live` follows `if [ "$failures" -gt 0 ]; then ... return 1; fi`. R1 test 103 ("--probe-only always recreates before probing") passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:13-15`, `devcontainer-config/cc-isolated.sh:708-714`, `devcontainer-config/cc-isolated.sh:891-896`, `$S/bats-new-cc.log`

---

## Claim 2: "A launch on an unverified config says so, recreates the container if it was built from another config so the probe exercises the new config rather than an old image (--probe-only always recreates), and refuses to start a session unless the baked firewall script reached its completion marker."

**Location:** `devcontainer-config/cc-isolated.sh:61-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NOTE print, the hash-mismatch recreate, the forced recreate under --probe-only and the firewall-marker gate before `claude`; does not establish that the recreated image actually reflects the new config (Docker build, not runnable here).

`:882-888` prints the NOTE under `if ! is_verified_live`. `:899-907`: `devcontainer up "${dc[@]}"`, then `if ! container_config_matches "${dc[@]}"; then ... devcontainer up --remove-existing-container`. `:912-929`: the probe and the re-probe both run before `devcontainer exec "${dc[@]}" claude` (`:938`); the second `probe_boundary "$ws"` (`:929`) sits in an if-body under `set -euo pipefail` (`:68`), so a failure exits. The firewall check is `if ! devcontainer exec "${dc[@]}" test -f /run/cc-firewall/complete` (`:700`). R1 test 102 runs a launch with the marker missing and asserts no ` claude` call.

**Evidence:** `devcontainer-config/cc-isolated.sh:61-66`, `devcontainer-config/cc-isolated.sh:68`, `devcontainer-config/cc-isolated.sh:700-706`, `devcontainer-config/cc-isolated.sh:882-938`, `$S/bats-new-cc.log`

---

## Claim 3: bless "Next:" lines: "Next: cc-isolated --probe-only <repo>" / "(recreates the container from it and probes as node)"

**Location:** `devcontainer-config/cc-isolated.sh:318-319`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the command is alone on its line, that --probe-only recreates from the blessed config, and that the probe runs as node; does not establish install.sh's own "Next steps" block (deferred, Claim 14).

The command line is `echo "  Next: cc-isolated --probe-only <repo>"` with nothing after it (`:318`). Recreate: Claim 1. "as node": `devcontainer.json:71` `"remoteUser": "node"`, so probe_boundary's `devcontainer exec` calls run as node. The printer is bless_manifest, reached from `--bless` (`:798` `bless) bless_manifest; exit 0`), `--register` (`:479` `bless_manifest` inside register_project) and install.sh (`install.sh:607` `"$DEST/cc-isolated.sh" --bless`).

**Evidence:** `devcontainer-config/cc-isolated.sh:314-321`, `devcontainer-config/cc-isolated.sh:479`, `devcontainer-config/devcontainer.json:71`, `devcontainer-config/install.sh:607`

---

## Claim 4: "a plain launch recreates only when the baked config hash differs, so a fail-closed container built from the blessed config would be reused, not recovered."

**Location:** `devcontainer-config/cc-isolated.sh:563-565`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launch path's only recreate site; "differs" includes an unreadable or empty baked hash (container_config_matches fails then too); does not establish what Docker does on recreate.

```bash
# devcontainer-config/cc-isolated.sh:580-584
container_config_matches() {
  local have
  have="$(devcontainer exec "$@" cat /etc/cc-config-hash 2>/dev/null | tr -d '[:space:]' || true)"
  [ -n "${CC_CONFIG_HASH:-}" ] && [ "$have" = "$CC_CONFIG_HASH" ]
}
```

`:904-907` is the only `--remove-existing-container` on the launch path; the init-firewall re-run (`:922`) does not recreate. R1 test 102 (matching hash, marker missing, re-run fails) asserts `run ! grep -q -- '--remove-existing-container' "$DC_LOG"`; R8's always-recreate mutant fails that line (:1410).

**Evidence:** `devcontainer-config/cc-isolated.sh:580-584`, `devcontainer-config/cc-isolated.sh:899-930`, `$S/bats-new-cc.log`, `$S/bats-mutant-recreate.log`

---

## Claim 5: "--probe-only always recreates, and exits non-zero on a failed probe, so the `&&` never starts a session after one."

**Location:** `devcontainer-config/cc-isolated.sh:565-566`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe branch's exit status on a probe failure (and on a failed `devcontainer up`, which also exits under errexit); does not establish shell behavior of `&&` beyond POSIX semantics.

`:895` `probe_boundary "$ws"` is a plain command in main under `set -euo pipefail` (`:68`); probe_boundary ends `return 1` on any failure (`:708-711`), so the script exits non-zero before `exit 0` (`:896`). The probe branch contains no `claude` exec (paraphrased — no quote available because the claim is the absence of a call between `:891` and `:897`). R1 test 104 asserts `[ "$status" -ne 0 ]`, `PROBE FAIL (firewall)`, the forced recreate, and no receipt.

**Evidence:** `devcontainer-config/cc-isolated.sh:68`, `devcontainer-config/cc-isolated.sh:708-711`, `devcontainer-config/cc-isolated.sh:891-897`, `$S/bats-new-cc.log`

---

## Claim 6: "The explanation is on its own line, not a trailing `# ...`: interactive zsh without interactivecomments would pass those words to step 2 as arguments."

**Location:** `devcontainer-config/cc-isolated.sh:567-570`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers zsh 5 under `zsh -f -i` (no rc files); does not establish the default in a user's rc (oh-my-zsh, for example, turns interactivecomments on).

R6: without the option, `f --probe-only /some/ws # the supported path: ...` printed `[--probe-only][/some/ws][#][the][supported][path:][recreates][the][container,][then][launches]`; with `setopt interactivecomments` it printed `[--probe-only][/some/ws]`. The echo at `:569` ends at the second `$(printf '%q' "$ws")`, and `:570` holds the explanation.

**Evidence:** `devcontainer-config/cc-isolated.sh:569-570`, `$S/zsh-probe.log`

---

## Claim 7: The recipe `cc-isolated --probe-only WS && cc-isolated WS` (with "the supported path: recreates the container from the blessed config, re-probes, then launches") is the right recovery for all three rebuild_hint callers reached from a plain launch

**Location:** `devcontainer-config/cc-isolated.sh:569-570`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what the recipe does (forced recreate, probe, launch only after a pass) for each of the three callers (`:677` provenance, `:691` config identity, `:926` init-firewall failure), and that it recovers every container-level cause; does not establish recovery from build-level causes (for example a shadowing `.devcontainer/Dockerfile`). For those, a plain launch has already recreated on the hash mismatch before probing, so `--probe-only` repeats the same recreate and fails safely: the deferred C4 limitation, reached from a plain launch too (see Claim 13).

Callers: `:676-677` `"  not the one you blessed. Recreate it with:"` / `rebuild_hint "$ws" "${dc[@]}"`; `:690-691` the same for config identity; `:925-926` `"  Recreate it (the ~/.claude volume and your repo are not affected):"` / `rebuild_hint`. The init-firewall caller is the fail-closed case, and R1 test 102 confirms the recipe there. For provenance, a container built with the right hash but the wrong profile (a by-hand build with a wrong assignment) is reused by a plain launch (`:904`) and recreated with the launcher's exports by `--probe-only` (paraphrased — no quote available because this is an inference from the hash check at `:580-584` and the exports at `:831` and `:842`). A shadowing repo Dockerfile bakes no `/etc/cc-config-hash`, so `container_config_matches` fails and the plain launch recreates before the probe, and `--probe-only` rebuilds from the same inputs (same inference). In every case the `&&` stops after a failed probe (Claim 5).

**Evidence:** `devcontainer-config/cc-isolated.sh:569-570`, `devcontainer-config/cc-isolated.sh:676-691`, `devcontainer-config/cc-isolated.sh:899-929`, `guides/cc-isolated-usage.md:964`, `$S/bats-new-cc.log`

---

## Claim 8: NOTE "This run is that verification: the container is recreated if it was built from another config, and the self-probe must pass (including the node-run firewall probes) before anything starts. A pass records the hash in $(verified_path)."

**Location:** `devcontainer-config/cc-isolated.sh:883-887`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launch and probe branches that follow the NOTE; does not establish the wording "node-run firewall probes" beyond probe_boundary running as remoteUser node (pre-existing text, only rewrapped).

Launch branch: recreate only on mismatch (Claim 4). Under --probe-only the recreate is unconditional, which the conditional sentence does not contradict. Record on pass: Claim 1. R1 test 102 asserts the NOTE prints and `!= *"the container is rebuilt from it"*`.

**Evidence:** `devcontainer-config/cc-isolated.sh:882-907`, `$S/bats-new-cc.log`

---

## Claim 9: "--probe-only is the verification command, so it always recreates: probing a container left over from an earlier config would verify the wrong boundary."

**Location:** `devcontainer-config/cc-isolated.sh:892-893`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unconditional `--remove-existing-container` at `:894`; does not establish Docker-side behavior.

`devcontainer-config/cc-isolated.sh:894`: `devcontainer up --remove-existing-container "${dc[@]}"`, with no condition inside `if [ "$action" = "probe" ]`.

**Evidence:** `devcontainer-config/cc-isolated.sh:891-896`

---

## Claim 10: "--probe-only always recreates the container from the blessed config and re-probes."

**Location:** `devcontainer-config/init-firewall.sh:346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same coverage as Claims 1 and 9; does not establish Docker-side behavior.

See `devcontainer-config/cc-isolated.sh:894-895` (`devcontainer up --remove-existing-container "${dc[@]}"` / `probe_boundary "$ws"`), with `CC_CONFIG_HASH="$(blessed_hash)"` exported at `:841-842`.

**Evidence:** `devcontainer-config/init-firewall.sh:346`, `devcontainer-config/cc-isolated.sh:841-842`, `devcontainer-config/cc-isolated.sh:894-895`

---

## Claim 11: "interactive zsh without interactivecomments passes those words to cc-isolated as arguments, and the last positional becomes the workspace."

**Location:** `devcontainer-config/init-firewall.sh:347-349`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers zsh's word passing (R6) and main's argument loop; does not establish what happens next (that depends on the word, see Claim 20).

`devcontainer-config/cc-isolated.sh:759`: `*)            ws_arg="$1"; shift ;;` overwrites `ws_arg` for every non-flag word, so the last one wins. `#` and words like `re-probes` do not start with `-` and reach that arm. R6 shows the words passed.

**Evidence:** `devcontainer-config/init-firewall.sh:347-349`, `devcontainer-config/cc-isolated.sh:741-762`, `$S/zsh-probe.log`

---

## Claim 12: printed recipe: "The first command recreates it from the blessed config and re-probes; the second starts the session:" / `cc-isolated --probe-only <repo>` / `cc-isolated <repo>`

**Location:** `devcontainer-config/init-firewall.sh:350-355`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text inside fail_closed_on_abort's incomplete-run branch and what each command does; does not establish the lock-timeout branch, which returns early without the recipe (`:302-307`).

`init-firewall.sh:354-355`: `echo "         cc-isolated --probe-only <repo>" >&2` / `echo "         cc-isolated <repo>" >&2`, each command alone. The second command is a plain launch, which re-probes before `claude` (Claim 2). R5: both `grep -qx` checks pass on this text and fail on cb56299c's.

**Evidence:** `devcontainer-config/init-firewall.sh:300-357`, `$S/gx-probe.log`

---

## Claim 13: override-log row 1: "A provenance or config-identity failure printed inside a `--probe-only` run points back at `--probe-only`, which just repeats the recreate; the cause there is the build ... (`devcontainer-config/cc-isolated.sh:670-689` ...; pre-existing)" — Defer, revisit trigger named

**Location:** `docs/reviews/override-log.md:847`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the described behavior, the line range, the "pre-existing" label and the guide remedy; does not establish the row's full reach: the same loop happens from a plain launch.

Inside --probe-only, the provenance and identity hints at `:676-677` and `:690-691` print the `--probe-only` recipe after a forced recreate (`:894`), as the row says. The range 670-689 spans both `PROBE FAIL` headers (`:673`, `:688`); the identity block's hint is at `:690-691`, just past it. The guide's provenance row (`guides/cc-isolated-usage.md:964`, "Delete `.devcontainer/` **before** verifying") names the real remedy. Pre-existing: 9660d4f6's hint pointed at a plain relaunch for the same callers. What the row understates: for a build-level cause (a shadowing Dockerfile bakes no `/etc/cc-config-hash`), a plain launch has already recreated at `:904-906` before its probe, so its hint also sends the user to a recreate that fails the same way (paraphrased — no quote available because this is an inference from `:580-584` and `:899-912`). A precise row would say "printed inside a `--probe-only` run, or after a plain launch's own hash-mismatch recreate".

**Evidence:** `docs/reviews/override-log.md:847`, `devcontainer-config/cc-isolated.sh:670-693`, `devcontainer-config/cc-isolated.sh:899-912`, `guides/cc-isolated-usage.md:964`

---

## Claim 14: override-log row 2: install.sh's "Next steps" block has trailing `# ...` notes and its `--probe-only` row says "rebuilds" (`devcontainer-config/install.sh:612-617`); "install.sh is a third enforcement file with its own tests and adds a gate trailer"

**Location:** `docs/reviews/override-log.md:848`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the location, the "rebuilds" text, install.sh's gate status and its tests; does not establish the row's forward reference ("asked of the user in this unit's report"), since that report is not yet written.

`install.sh:613`: `echo "  cc-isolated --probe-only <repo>        # REQUIRED after any boundary change: rebuilds from"`; `:612-617` all carry trailing `# ...` notes. `hooks/live-verify-gate.sh:13-16`: "any enforcement file under devcontainer-config/ (the ones the trust manifest hashes, plus install.sh per decision 035), the commit message must carry a `Live-verified:` trailer". Its tests: `test/install-host.bats` exists.

**Evidence:** `docs/reviews/override-log.md:848`, `devcontainer-config/install.sh:611-617`, `hooks/live-verify-gate.sh:13-16`, `test/install-host.bats`

---

## Claim 15: "cc-isolated --probe-only [REPO] # RECREATE REPO's container from the blessed config, run the self-probe, record the config verified live on a pass"

**Location:** `guides/cc-isolated-usage.md:25-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 1.

See Claim 1 (`cc-isolated.sh:894-896`, record only after `failures` is 0).

**Evidence:** `guides/cc-isolated-usage.md:25-26`, `devcontainer-config/cc-isolated.sh:891-896`

---

## Claim 16: "it always recreates the container first, so it can never verify a leftover container"

**Location:** `guides/cc-isolated-usage.md:841-842`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --probe-only's ordering (recreate before probe); does not establish Docker-side behavior.

`cc-isolated.sh:894-895` recreates and then probes; R1 test 103 asserts `grep -q '^devcontainer up --remove-existing-container ' "$DC_LOG"`.

**Evidence:** `guides/cc-isolated-usage.md:841-842`, `devcontainer-config/cc-isolated.sh:894-895`, `$S/bats-new-cc.log`

---

## Claim 17: NOTE row: "Expected after `install.sh`, `--bless` or `--register`. The launch recreates the container if it was built from another config, then verifies"

**Location:** `guides/cc-isolated-usage.md:955`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the launch path; does not establish that a verified receipt is absent after every install.sh (one is if install.sh blesses a never-probed config).

All three paths call bless_manifest (Claim 3), which replaces the manifest, and the NOTE prints under `if ! is_verified_live` (`:882`). Recreate only on mismatch, then probe: `:904-912`.

**Evidence:** `guides/cc-isolated-usage.md:955`, `devcontainer-config/cc-isolated.sh:882-912`

---

## Claim 18: "Relaunch with `cc-isolated <repo>`, which recreates it with both set."

**Location:** `guides/cc-isolated-usage.md:963`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's state (empty `/etc/cc-config-hash`); does not establish Docker-side behavior.

In that state `have` is empty, so `[ "$have" = "$CC_CONFIG_HASH" ]` fails (`:583`) and `:906` recreates, with `CC_EGRESS_PROFILE` and `CC_CONFIG_HASH` exported (`:831`, `:842`).

**Evidence:** `guides/cc-isolated-usage.md:963`, `devcontainer-config/cc-isolated.sh:580-584`, `devcontainer-config/cc-isolated.sh:824-842`, `devcontainer-config/cc-isolated.sh:904-907`

---

## Claim 19: rebuild_hint test: "a plain launch recreates only on a config-hash mismatch" and the assertions (line 1 is exactly the two-step command, line 2 carries the explanation, no "rebuilds"); fails on the 9660d4f6 text

**Location:** `test/cc-isolated-functions.bats:346-363`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions and the mismatch comment; the "last positional" comment is Claim 20.

`:360` `[ "$(echo "$output" | head -1)" = "    cc-isolated --probe-only $ws && cc-isolated $ws" ]` is exact equality, so a trailing comment fails it; `:361-362` check line 2 and `!= *"rebuilds"*`. R1 passes; R3 fails at `:360` on the 9660d4f6 script.

**Evidence:** `test/cc-isolated-functions.bats:346-363`, `$S/bats-new-cc.log`, `$S/bats-old.log`

---

## Claim 20: "the last positional becomes the workspace, so step 2 fails or, if that word names a git repo in the cwd, launches it" (test comment), and the same in 2463017f's body A5: "the launch retargeted to ./launches happens only when ./launches is a git repo; otherwise step 2 errors out"

**Location:** `test/cc-isolated-functions.bats:355-359`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers resolve_workspace's handling of the stray last word; does not establish anything about the user's cwd beyond the R7 fixture.

```bash
# devcontainer-config/cc-isolated.sh:357-370
resolve_workspace() {
  local start="${1:-$PWD}" top
  if [ ! -d "$start" ]; then
    echo "ERROR: not a directory: $start" >&2
    return 1
  fi
  if ! top="$(git -C "$start" rev-parse --show-toplevel 2>/dev/null)"; then
  ...
  echo "$top"
}
```

The word does not have to name a git repo. Any directory inside a git work tree resolves to that work tree's toplevel. In R7, `resolve_workspace launches`, run from a repo where `launches/` is a plain subdirectory, printed the enclosing repo. Precise version: "fails, or, if that word names a directory inside a git work tree (relative to the cwd), launches that work tree".

**Evidence:** `test/cc-isolated-functions.bats:355-359`, `devcontainer-config/cc-isolated.sh:357-370`, `$S/rw.log`

---

## Claim 21: "STUB_FW_BRICKED=1 → re-running the baked init-firewall.sh fails (fail-closed state)."

**Location:** `test/cc-isolated-functions.bats:1157`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the stub's case arm; does not establish real init-firewall.sh behavior.

`:1171` `*init-firewall.sh*)      [ -z "${STUB_FW_BRICKED:-}" ] ;;`. None of the earlier arms (`*cc-config-hash*`, `*rev-parse*`, `*cc-firewall/complete*`) matches main's `sudo /usr/local/bin/init-firewall.sh` call (paraphrased — no quote available because this is a comparison of patterns against the call at `cc-isolated.sh:922`).

**Evidence:** `test/cc-isolated-functions.bats:1155-1182`, `devcontainer-config/cc-isolated.sh:922`

---

## Claim 22: fail-closed launch test: comments ("in the fail-closed state the container was built from the blessed config, so a plain launch does not recreate it"; "The premise of the hint: this launch reused the container and never started claude") and assertions; regression fails on 9660d4f6

**Location:** `test/cc-isolated-functions.bats:1389-1412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion against its comment; the NOTE assertion checks only that the old phrase is absent, not that the new one is present (see Claim 31).

The setup sets `STUB_IMAGE_HASH="$(blessed_hash)"`, `STUB_FW_MISSING=1`, `STUB_FW_BRICKED=1`. The test asserts a non-zero status, `ERROR: init-firewall.sh failed`, `"Recreate it"*"cc-isolated --probe-only $ws && cc-isolated $ws"`, then `run ! grep -q -- '--remove-existing-container'` and `run ! grep -q ' claude$'` (bats 1.8.2: `run !` requires a non-zero exit). R3 fails at `:1405` on the 9660d4f6 script; R8's always-recreate mutant fails at `:1410`.

**Evidence:** `test/cc-isolated-functions.bats:1389-1412`, `$S/bats-new-cc.log`, `$S/bats-old.log`, `$S/bats-mutant-recreate.log`

---

## Claim 23: "The hint's `&&` relies on this: a failed probe after the forced recreate must exit non-zero and never start claude"

**Location:** `test/cc-isolated-functions.bats:1427-1428`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against the test body; does not dispute that the property holds (Claim 5).

After 2463017f the test (`:1429-1443`) asserts `[ "$status" -ne 0 ]`, `PROBE FAIL (firewall)`, `grep -q '^devcontainer up --remove-existing-container '` and `[ ! -f "$(verified_path)" ]`. It no longer asserts "never start claude"; that line was removed (diff 980a9db4..2463017f: `-  run ! grep -q ' claude$' "$DC_LOG"`). The property holds by construction (the probe branch has no claude exec), but the comment states two properties and the test checks one. Precise version: "...must exit non-zero (it has no claude exec to reach)".

**Evidence:** `test/cc-isolated-functions.bats:1427-1443`, `devcontainer-config/cc-isolated.sh:891-897`

---

## Claim 24: "--probe-only recreates the container (cached image layers are reused)"

**Location:** `test/init-firewall-rules.bats:1491-1492`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers "recreates" (Claim 9); does not establish the cache claim, which is devcontainer CLI and Docker behavior.

"Recreates": `cc-isolated.sh:894`. Layer reuse depends on how `devcontainer up --remove-existing-container` drives `docker build` and on what changed (the `ARG CC_CONFIG_HASH=""` at `Dockerfile:484` invalidates every later layer when the hash changes). There is no Docker in this sandbox. Verifying it needs a host run of `--probe-only` with build output.

**Evidence:** `test/init-firewall-rules.bats:1491-1492`, `devcontainer-config/Dockerfile:484`, `devcontainer-config/cc-isolated.sh:894`

---

## Claim 25: init-firewall test assertions: explanation before the command; no "rebuilds"; each command line alone (`grep -qx`); each new assertion fails on the previous text

**Location:** `test/init-firewall-rules.bats:1493-1499`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions against the 9660d4f6, cb56299c/980a9db4 and 2463017f texts; does not cover install.sh's block (deferred).

R2 passes. R3 and R4 fail at `:1493` (`*"recreates it from the blessed config"*"cc-isolated --probe-only <repo>"*`) on both older texts. R5 shows that the two `grep -qx` lines (`:1498-1499`) each fail on cb56299c's trailing-comment lines (exit 1) and pass on 2463017f's (exit 0).

**Evidence:** `test/init-firewall-rules.bats:1488-1500`, `$S/bats-new-fw.log`, `$S/bats-old.log`, `$S/bats-980.log`, `$S/gx-probe.log`

---

## Claim 26: cb56299c body: the old first line said a plain launch "rebuilds, re-probes, re-launches"; a plain launch recreates only on a baked-hash mismatch, so in the fail-closed state it "reuses the bricked container, fails the same way, and prints the same hint"; the new line is the two-step recipe; "--probe-only always recreates and exits non-zero on a failed probe"; "The by-hand form is unchanged."

**Location:** `devcontainer-config/cc-isolated.sh:569-576`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit body's mechanism paragraph; the "on one line" form was superseded by 980a9db4 (explanation moved to its own line).

The old text appears as a removed line in the diff (`# the supported path: rebuilds, re-probes, re-launches`). Mechanism: Claims 4 and 5. Fail-closed reuse: R1 test 102. The by-hand lines (`:571-576`) do not appear in the 9660d4f6..2463017f diff (paraphrased — no quote available because the claim is the absence of a hunk).

**Evidence:** `devcontainer-config/cc-isolated.sh:560-577`, `$S/bats-new-cc.log`

---

## Claim 27: cb56299c body: recreate wording applied to "the two 'Rebuild with:' lead-ins, the --probe-only comment in main, init-firewall.sh's fail-closed hint (comment and echo), and two lines of guides/cc-isolated-usage.md"

**Location:** `devcontainer-config/cc-isolated.sh:676`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers cb56299c's hunks (`git diff 9660d4f6..cb56299c --stat`: guides 2 lines, init-firewall.sh 4 lines).

`:676`/`:690` read `Recreate it with:`; `:892` "always recreates"; cb56299c's init-firewall.sh had the comment "--probe-only always recreates the container ..." and the echo "# recreates it from the blessed config, re-probes"; the guide hunks are `:25` and `:963`.

**Evidence:** `devcontainer-config/cc-isolated.sh:676`, `devcontainer-config/cc-isolated.sh:690`, `devcontainer-config/cc-isolated.sh:892`, `guides/cc-isolated-usage.md:25`, `guides/cc-isolated-usage.md:963`

---

## Claim 28: cb56299c body, Tests: the new launch test "asserts no recreate, no session, and the recipe in the hint"; the rebuild_hint and fail-closed trap tests require the new text; "All three fail on the old text."

**Location:** `test/cc-isolated-functions.bats:1389-1412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cb56299c's own test versions against 9660d4f6 scripts (R10) and the current versions (R3).

R10: all three cb56299c tests are not ok on the 9660d4f6 scripts. R3: the same three, as later amended, also fail.

**Evidence:** `$S/bats-cb56-tests-old-scripts.log`, `$S/bats-old.log`

---

## Claim 29: cb56299c body, Notes: the "Blessed config changed ... rebuilding it." line is left as is "(a guide row quotes it verbatim)"; "the next launch recreates each project's container once (init-firewall.sh is baked into the image)"

**Location:** `devcontainer-config/cc-isolated.sh:905`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both Notes sentences and 980a9db4's A4 correction of them.

The guide row (`guides/cc-isolated-usage.md:956`) quotes `Blessed config changed since this container was built — rebuilding`, a prefix of `:905`'s `"... — rebuilding it."`, not the line verbatim. The one-time recreate comes from the blessed hash changing (`:904` container_config_matches), not from init-firewall.sh being baked. 980a9db4's A4 says exactly this, and the correction is accurate (Claim 36).

**Evidence:** `devcontainer-config/cc-isolated.sh:904-906`, `guides/cc-isolated-usage.md:956`

---

## Claim 30: all three bodies, Notes: "no iptables call, probe check, recreate decision or exit status changed"

**Location:** `devcontainer-config/cc-isolated.sh:560-577`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every changed line in devcontainer-config/ over 9660d4f6..2463017f; does not establish behavior of the unchanged code.

R9: after dropping comment and `echo` lines, the diff of devcontainer-config/ is empty (0 bytes).

**Evidence:** `$S/non-comment-diff.log`

---

## Claim 31: 980a9db4 body, A1: "main() keeps the last positional, so the launch retargeted to ./launches"

**Location:** `devcontainer-config/cc-isolated.sh:759`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the original statement as corrected by 2463017f's A5 (whose residual imprecision is Claim 20).

Last positional wins: `:759`. The retarget happens only when the word resolves to a git work tree; otherwise resolve_workspace errors out (`:359-367`). 2463017f's A5 corrects this, still with the "is a git repo" narrowing (Claim 20).

**Evidence:** `devcontainer-config/cc-isolated.sh:357-370`, `devcontainer-config/cc-isolated.sh:759`, `$S/rw.log`

---

## Claim 32: 980a9db4 body, A2: the NOTE, the header paragraph and the guide's NOTE row said a plain launch rebuilds; "In the fail-closed state the receipt is missing and the hash matches, so it does not"; "They now say the container is recreated if it was built from another config."

**Location:** `devcontainer-config/cc-isolated.sh:883-887`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the case where both the NOTE and the hint print, which needs the receipt to be missing; does not cover a fail-closed container on a previously verified config (no NOTE prints there).

The old texts appear as removed lines in the diff ("the container is rebuilt from it", "rebuilds the container", "The launch rebuilds and verifies"). The new texts are at `:62-63`, `:884-885` and `guides/cc-isolated-usage.md:955`.

**Evidence:** `devcontainer-config/cc-isolated.sh:61-66`, `devcontainer-config/cc-isolated.sh:882-888`, `guides/cc-isolated-usage.md:955`

---

## Claim 33: 980a9db4 body, A2: "The fail-closed launch test asserts it."

**Location:** `test/cc-isolated-functions.bats:1406-1408`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the test asserts about the NOTE wording.

The test asserts `*"has NOT been verified in a live container"*` and `!= *"the container is rebuilt from it"*`: the old promise is absent, but nothing checks that "recreated if it was built from another config" is present. Precise version: "the fail-closed launch test asserts the old promise is gone".

**Evidence:** `test/cc-isolated-functions.bats:1406-1408`

---

## Claim 34: 980a9db4 body, A3, C3, C6: --help's --probe-only line says recreate; a new test checks that --probe-only exits non-zero and starts no session on a failed probe; the test is named "--probe-only always recreates before probing"

**Location:** `devcontainer-config/cc-isolated.sh:13-15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these three items as of 980a9db4; the C3 test's later rename and assertion drop are Claim 39.

`:13` "recreate WS's container"; `test/cc-isolated-functions.bats:1414` `@test "--probe-only always recreates before probing"`; the C3 test exists at `:1429` (renamed by 2463017f).

**Evidence:** `devcontainer-config/cc-isolated.sh:13-15`, `test/cc-isolated-functions.bats:1414-1443`

---

## Claim 35a: 980a9db4 body, C1: "the --list 'Next:' line ... say[s] recreates"

**Location:** `devcontainer-config/cc-isolated.sh:318`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the attribution of the "Next:" line; the wording change itself is Claim 3.

`list_projects` prints `"Blessed config $b — verified live: NO (run: cc-isolated --probe-only <repo>)"` and no "Next:" line; the "Next:" line is bless_manifest's (`:318`). 2463017f's A6 corrects this (Claim 35b).

**Evidence:** `devcontainer-config/cc-isolated.sh:318`, `devcontainer-config/cc-isolated.sh:484-535`

---

## Claim 35b: 2463017f body, A6: "the 'Next:' line it calls the --list line is printed by bless_manifest (--bless, --register, install.sh), not by --list."

**Location:** `devcontainer-config/cc-isolated.sh:314-321`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all three callers of bless_manifest that reach the line.

See Claim 3: `:798` (`--bless`), `:479` (register_project), `install.sh:607`.

**Evidence:** `devcontainer-config/cc-isolated.sh:479`, `devcontainer-config/cc-isolated.sh:798`, `devcontainer-config/install.sh:607`

---

## Claim 36: 980a9db4 body, A4: the guide row quotes the line "only up to 'rebuilding', not verbatim"; the one-time recreate "is caused by the blessed hash changing after the bless (both scripts are in the manifest), while init-firewall.sh being baked is why its new text reaches a container only through that recreate"

**Location:** `guides/cc-isolated-usage.md:956`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quote extent, manifest membership and the baking; does not establish Docker layer behavior.

`enforcement_files` lists `init-firewall.sh` and `cc-isolated.sh` (`cc-isolated.sh:135`, `:138`); `Dockerfile:487` `COPY init-firewall.sh /usr/local/bin/`; the guide row ends at "rebuilding".

**Evidence:** `guides/cc-isolated-usage.md:956`, `devcontainer-config/cc-isolated.sh:130-138`, `devcontainer-config/Dockerfile:487`

---

## Claim 37: 980a9db4 body, Notes: "'rebuild' stays where the image really is rebuilt (--register's note, the re-bless notes) and in the 'Blessed config changed ... rebuilding it.' line, which a guide row and a test match."

**Location:** `devcontainer-config/cc-isolated.sh:905`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the remaining "rebuild" sites (R9 grep) and what each matcher pins.

`:481` "Next launch rebuilds the image for the new profile."; `:768`/`:770` the re-bless notes; `:905` kept. The guide row (`:956`) quotes "— rebuilding". The test (`test/cc-isolated-functions.bats:1360`) matches only `*"Blessed config changed since this container was built"*` and stops before the word "rebuilding", so it does not tie the line to that word.

**Evidence:** `devcontainer-config/cc-isolated.sh:481`, `devcontainer-config/cc-isolated.sh:768-770`, `devcontainer-config/cc-isolated.sh:905`, `test/cc-isolated-functions.bats:1360`, `$S/rebuild-grep.log`

---

## Claim 38: 2463017f body, A7: init-firewall.sh's recipe and the bless "Next:" line ended in `# ...`; commands are now alone with the explanation above or below; the init-firewall test pins both command lines with grep -x; install.sh's block has the same form and is deferred

**Location:** `devcontainer-config/init-firewall.sh:350-355`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three sites named and the test.

980a9db4's `:317`: `"  Next: cc-isolated --probe-only <repo>   # recreates from it and probes as node"`; cb56299c's recipe lines end in `# ...` (R5 output). Now: `cc-isolated.sh:318-319`, `init-firewall.sh:350-355`. Test: Claim 25. install.sh: Claim 14.

**Evidence:** `devcontainer-config/cc-isolated.sh:318-319`, `devcontainer-config/init-firewall.sh:350-355`, `test/init-firewall-rules.bats:1498-1499`, `$S/gx-probe.log`

---

## Claim 39: 2463017f body: the --probe-only fail-case test "drops its 'no claude' assertion, which could never fail (--probe-only has no claude exec); renamed accordingly"

**Location:** `test/cc-isolated-functions.bats:1429`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the probe branch's lack of a claude exec and the rename; the stale comment above the test is Claim 23.

The probe branch (`cc-isolated.sh:891-897`) ends with `exit 0` or an errexit before `:938`'s `devcontainer exec "${dc[@]}" claude`. Renamed to `"--probe-only exits non-zero and records nothing when the probe fails"`.

**Evidence:** `devcontainer-config/cc-isolated.sh:891-897`, `devcontainer-config/cc-isolated.sh:938`, `test/cc-isolated-functions.bats:1429`

---

## Claim 40: 2463017f body, C9: "--help's --probe-only line rewrapped to the block's width."

**Location:** `devcontainer-config/cc-isolated.sh:13-15`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers line lengths in the header usage block.

`awk '{print length}'`: the 980a9db4 line was 99 columns; the new lines are 83, 86 and 59, within the block's widest line (94, `:12`).

**Evidence:** `devcontainer-config/cc-isolated.sh:7-17`

---

## Claim 41: 2463017f body: "C4 ... is logged in the override log with its revisit trigger."

**Location:** `docs/reviews/override-log.md:847`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's presence and trigger; its accuracy is Claim 13.

The row ends "Revisit trigger: a user reports a `--probe-only` loop on either failure, or the next change to probe_boundary's failure messages."

**Evidence:** `docs/reviews/override-log.md:847`

---

## Claim 42: 2463017f body, Notes: "Each new assertion fails on the previous text (trailing-comment command lines)."

**Location:** `test/init-firewall-rules.bats:1493-1499`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions 2463017f adds or changes (`:1493`, `:1498`, `:1499`); the cc-isolated test change in that commit is a comment edit plus an assertion removal, not a new assertion.

R4 fails `:1493` on the 980a9db4 text; R5 fails both `grep -qx` lines on it.

**Evidence:** `$S/bats-980.log`, `$S/gx-probe.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 13** (`docs/reviews/override-log.md:847`): C4's row scopes the "--probe-only repeats the recreate" loop to failures "inside a `--probe-only` run". For build-level causes, a plain launch has already recreated on the hash mismatch before probing, so its provenance and identity hints loop the same way. Widen the row's description.
- **Claim 20** (`test/cc-isolated-functions.bats:355-359`, also 2463017f A5): "names a git repo in the cwd" should be "names a directory inside a git work tree", which then launches that work tree's toplevel (R7).
- **Claim 23** (`test/cc-isolated-functions.bats:1427-1428`): the comment still says "and never start claude", which the test no longer asserts.
- **Claim 29** (commit cb56299c Notes): "verbatim" and the baked-image causal parenthetical were both corrected by 980a9db4 A4 (immutable).
- **Claim 31** (commit 980a9db4 A1): "retargeted to ./launches" was corrected by 2463017f A5 (immutable; see Claim 20 for the residue).
- **Claim 33** (commit 980a9db4 A2): the test asserts that the old NOTE wording is absent, not that the new wording is present.
- **Claim 35a** (commit 980a9db4 C1): "--list" should be bless_manifest; corrected by 2463017f A6.
- **Claim 37** (commit 980a9db4 Notes): the test at `:1360` stops before "rebuilding", so only the guide row ties that word.

### Unverifiable
- **Claim 24** (`test/init-firewall-rules.bats:1491`): "(cached image layers are reused)" is devcontainer CLI and Docker behavior; checking it needs a host `--probe-only` run with build output.

## Goal-Alignment Note
- Success criterion (restated verbatim): a code-fact-check report saved at the path below, structured per the skill, verdicting at least the claims listed above.
- Answered: yes. All seven brief items are verdicted (43 claims), 21 of them executed: both suites green at 2463017f; the regression tests fail on the 9660d4f6 text (and on cb56299c/980a9db4 where applicable); zsh's word passing confirmed; the no-recreate assertion caught by a mutant. No Incorrect or Stale verdicts.
- Out of scope: Docker and devcontainer CLI behavior (no Docker here); install.sh's block (deferred); review artifacts under docs/reviews other than the two override rows.
- Escalate: Claim 13 (C4 row understates reach: plain-launch provenance/identity hints loop too for build-level causes) and Claim 23 (stale test comment) are the two worth a one-line edit; the rest are immutable commit-body imprecisions already corrected by later bodies.
- Decisions I made: treated cb56299c/980a9db4 imprecisions that a later body corrects as Mostly accurate rather than Incorrect; verdicted brief item 2 as Verified on what the recipe does, with build-level recovery named as the residue rather than as a defect of this unit.
