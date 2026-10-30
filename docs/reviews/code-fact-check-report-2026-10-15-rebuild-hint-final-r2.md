# Code Fact-Check Report

Commit: 2463017f

**Repository:** claude-workflows (worktree /workspace/.claude/wt-rebuild-hint, branch fix/rebuild-hint-recreate)
**Scope:** `git diff 9660d4f6..2463017f` minus docs/reviews review artifacts (devcontainer-config/cc-isolated.sh, devcontainer-config/init-firewall.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, test/init-firewall-rules.bats), plus the two override-log rows the branch appends (docs/reviews/override-log.md:847-848) and the bodies of cb56299c, 980a9db4, 2463017f
**Checked:** 2026-10-15
**Replication:** k=3 final confirming pass, replicate r2
**Total claims checked:** 37
**Summary:** 28 verified, 6 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Sub-claims (4a-c, 5a-b, 25a-b) are counted individually. One of the two Incorrect verdicts (25b) was already corrected on the branch by 980a9db4.

Execution provenance (shared by every `executed` claim). Scratch dir `S=/home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-final-r2`; captured output in `$S/`. The worktree's own run-tests.sh refused ("another run-tests.sh run is in progress in this checkout": the sibling replicates), so R1 ran on a `git archive 2463017f` copy, which is byte-identical to the tracked tree at HEAD. Filtered runs (R2-R5) used bare `bats -f` with `LC_ALL=C.UTF-8` (the three locale-sensitive tests are not selected).

| Run | Command | cwd | Exit | UTC |
|---|---|---|---|---|
| R1 HEAD suites | `timeout 600 bash scripts/run-tests.sh test/cc-isolated-functions.bats test/init-firewall-rules.bats` | `$S/tree-head` (archive of 2463017f) | 0 (290/290 ok) | 2026-10-15T11:36:50Z → `$S/bats-2463017f.log` |
| R2 HEAD tests, 9660d4f6 scripts | `bats -f 'rebuild_hint names the launcher\|fail-closed container does not recreate\|probe-only' test/cc-isolated-functions.bats; bats -f 'fail-closed trap points at the launcher' test/init-firewall-rules.bats` | `$S/tree-base` (archive of 2463017f, both scripts from 9660d4f6) | 1 / 1 (not ok at :360, :1405, init-firewall :1493; both --probe-only tests ok) | 2026-10-15T11:39:02Z → `$S/bats-base-scripts.log` |
| R3 HEAD tests, 980a9db4 scripts | same as R2; then the init-firewall test with :1493-1494 deleted, then also with the first grep -x deleted | `$S/tree-i1` | 0 / 1 / 1 / 1 (init-firewall not ok at :1493; then at the first `grep -qx` (orig :1498); then at the second (orig :1499)) | 2026-10-15T11:39:05Z → `$S/bats-i1-scripts.log`, `$S/bats-i1-gx.log`, `$S/bats-i1-gx2.log` |
| R4 cb56299c tests, 9660d4f6 scripts | `bats -f 'rebuild_hint names\|fail-closed container' test/cc-isolated-functions.bats; bats -f 'fail-closed trap points' test/init-firewall-rules.bats` | `$S/tree-cb` | 1 / 1 (not ok at :355, :1400, init-firewall :1493) | 2026-10-15T11:40:58Z → `$S/bats-cb-tests-base-scripts.log` |
| R5 config-identity from a plain launch | `bats -f 'PROBE: plain launch' test/probe-cfgid.bats` (a scratch copy of the suite plus one test: smart stub, `STUB_IMAGE_HASH=stale`, plain launch) | `$S/tree-head` | 0 (probe test records, asserts nothing) | 2026-10-15T11:40:41Z → `$S/probe-cfgid-run.log`, `$S/probe-cfgid-out.txt` |
| R6 zsh | `bash zsh-probe.sh` (feeds a trailing-comment line and the bare command to `zsh -f -i`, with `f` printing each argument in brackets) | `$S` | 0 | 2026-10-15T11:39:31Z → `$S/zsh-probe.log` |
| R7 resolve_workspace | `bash rw-probe.sh $S` (sources cc-isolated.sh, runs `resolve_workspace launches` from a repo with a plain `launches/` subdir, a non-repo dir with one, and a dir without one) | `$S` | 0 | 2026-10-15T11:39:39Z → `$S/rw-probe.log` |
| R8 non-text diff | `git diff 9660d4f6..2463017f -- devcontainer-config \| grep '^[-+]' \| grep -v '^[-+][-+]' \| grep -v '^[-+]\s*#' \| grep -v '^[-+]\s*echo'` | worktree | 1 from last grep (no lines) | 2026-10-15T11:41:05Z → `$S/non-comment-diff.log` |

No process was left running; every run was a foreground `timeout` call.

I read `docs/reviews/hallucination-patterns.md`. None of its logged patterns (corpus statistics, measured test counts, symbol/consumer associations) resembles any claim below.

---

## Claim 1: "cc-isolated --probe-only [WS]  # recreate WS's container from the blessed config, run the boundary self-probe, record it verified live"

**Location:** `devcontainer-config/cc-isolated.sh:13-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers "recreate" and the probe branch of main(); does not establish that the verified-live record is unconditional (it is written only on a pass, pre-existing wording) or any real Docker behaviour.

The probe branch of main() (main spans `:739-950`, all read):

```bash
# devcontainer-config/cc-isolated.sh:891-897
  if [ "$action" = "probe" ]; then
    # --probe-only is the verification command, so it always recreates: probing a
    # container left over from an earlier config would verify the wrong boundary.
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
  fi
```

`record_verified_live` is called only after `failures` is 0 (`cc-isolated.sh:708-714`: `if [ "$failures" -gt 0 ]; then ... return 1; fi; record_verified_live`). R1's "--probe-only always recreates before probing" passes. Rewrap (C9): the three lines are 83, 86 and 59 characters; the block's other lines run to 94 (paraphrased — no quote available because this is a line-length measurement, `awk '{print length}'` over `:7-17`).

**Evidence:** `devcontainer-config/cc-isolated.sh:13-15`, `devcontainer-config/cc-isolated.sh:891-897`, `devcontainer-config/cc-isolated.sh:708-714`, `$S/bats-2463017f.log`

---

## Claim 2: "A launch on an unverified config says so, recreates the container if it was built from another config so the probe exercises the new config rather than an old image (--probe-only always recreates), and refuses to start a session unless the baked firewall script reached its completion marker."

**Location:** `devcontainer-config/cc-isolated.sh:62-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the launch path's NOTE, its hash-mismatch recreate, --probe-only's unconditional recreate and the firewall-marker probe gate; does not establish real devcontainer CLI behaviour.

```bash
# devcontainer-config/cc-isolated.sh:901-907
  # `devcontainer up` never rebuilds an existing container. If the config was
  # re-blessed since this one was built, it is running the previous boundary;
  # recreate it (the ~/.claude volume and the repo are unaffected).
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi
```

The firewall gate: `if ! devcontainer exec "${dc[@]}" test -f /run/cc-firewall/complete; then echo "PROBE FAIL (firewall) ..."` (`cc-isolated.sh:700-706`). R1: "a launch on a matching, verified container does not rebuild" (no `--remove-existing-container`) and the mismatch test (`test/cc-isolated-functions.bats:1360-1361`) pass.

**Evidence:** `devcontainer-config/cc-isolated.sh:580-584`, `devcontainer-config/cc-isolated.sh:700-714`, `devcontainer-config/cc-isolated.sh:894-907`, `$S/bats-2463017f.log`

---

## Claim 3: "Next: cc-isolated --probe-only <repo>" / "(recreates the container from it and probes as node)"

**Location:** `devcontainer-config/cc-isolated.sh:318-319`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the command line being alone on its line, the recreate, and "as node"; does not establish that any test pins these two lines (none does).

```bash
# devcontainer-config/cc-isolated.sh:317-320 (inside bless_manifest(), :283-322, read)
    echo "Verified live:  NO — a bless is a review, not a test. Nothing has run this config."
    echo "  Next: cc-isolated --probe-only <repo>"
    echo "        (recreates the container from it and probes as node)"
    echo "  Commits that change the boundary carry a 'Live-verified:' trailer naming this hash."
```

`devcontainer-config/devcontainer.json:71` is `"remoteUser": "node",`, so `devcontainer exec` probes run as node. The recreate is the probe branch quoted in Claim 1.

**Evidence:** `devcontainer-config/cc-isolated.sh:317-320`, `devcontainer-config/devcontainer.json:71`

---

## Claim 4a: "a plain launch recreates only when the baked config hash differs, so a fail-closed container built from the blessed config would be reused, not recovered."

**Location:** `devcontainer-config/cc-isolated.sh:563-565`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main()'s launch path (the only recreate is `container_config_matches` failing); does not establish real Docker behaviour on a bricked container.

`container_config_matches` is `[ -n "${CC_CONFIG_HASH:-}" ] && [ "$have" = "$CC_CONFIG_HASH" ]` (`cc-isolated.sh:580-584`), and the only `--remove-existing-container` on the launch path is the one in Claim 2's quote; the fail-closed branch (`cc-isolated.sh:922-928`) prints the hint and `return 1` without recreating. R1's "a launch on a fail-closed container does not recreate it ..." asserts `run ! grep -q -- '--remove-existing-container' "$DC_LOG"` and passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:580-584`, `devcontainer-config/cc-isolated.sh:900-930`, `test/cc-isolated-functions.bats:1392-1412`, `$S/bats-2463017f.log`

---

## Claim 4b: "--probe-only always recreates, and exits non-zero on a failed probe, so the `&&` never starts a session after one."

**Location:** `devcontainer-config/cc-isolated.sh:565-566`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the probe branch under `set -euo pipefail` (`:68`) and main's top-level call; does not establish behaviour when the shell running the recipe is not POSIX-`&&`-compatible.

`probe_boundary "$ws"` (`:895`) is not in a conditional, so its `return 1` ends the script under `set -e`; main is called as `main "$@"` in the guard body (`:953-955`), not a condition. R1's "--probe-only exits non-zero and records nothing when the probe fails" asserts `[ "$status" -ne 0 ]` and passes; the probe branch has no `claude` exec (Claim 1 quote).

**Evidence:** `devcontainer-config/cc-isolated.sh:68`, `devcontainer-config/cc-isolated.sh:891-897`, `devcontainer-config/cc-isolated.sh:953-955`, `test/cc-isolated-functions.bats:1429-1442`, `$S/bats-2463017f.log`

---

## Claim 4c: "interactive zsh without interactivecomments would pass those words to step 2 as arguments."

**Location:** `devcontainer-config/cc-isolated.sh:567-568`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers zsh 5 on this host with `-f` (interactivecomments off); does not establish other shells or user rc files that set the option.

R6 output: `f --probe-only WS && f WS        # the supported path: ...` printed `[WS][#][the][supported][path:][recreates]...[launches]` for step 2, while the bare line printed `[WS]`.

**Evidence:** `devcontainer-config/cc-isolated.sh:567-570`, `$S/zsh-probe.log`

---

## Claim 5a: The printed recipe (`cc-isolated --probe-only WS && cc-isolated WS`, explanation on the next line) is the right recovery for main()'s fail-closed caller

**Location:** `devcontainer-config/cc-isolated.sh:569-570`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the caller at `:926` (init-firewall.sh re-run failed, hash matched, no recreate this launch); does not establish that a freshly recreated container's firewall run succeeds (a persistent outage would fail step 1, which then stops the `&&`).

```bash
# devcontainer-config/cc-isolated.sh:569-570 (inside rebuild_hint(), :560-577, read)
  echo "    cc-isolated --probe-only $(printf '%q' "$ws") && cc-isolated $(printf '%q' "$ws")" >&2
  echo "      (the supported path: recreates the container from the blessed config, re-probes, then launches)" >&2
```

In that state the launch did not recreate (Claim 4a), and step 1 forces the recreate the launch skipped (Claim 1). R1 asserts the recipe follows "Recreate it" in the fail-closed output.

**Evidence:** `devcontainer-config/cc-isolated.sh:560-577`, `devcontainer-config/cc-isolated.sh:922-928`, `test/cc-isolated-functions.bats:1405`, `$S/bats-2463017f.log`

---

## Claim 5b: The same recipe is the right recovery for the two probe_boundary callers (provenance `:677`, config identity `:691`) when reached from a plain launch

**Location:** `devcontainer-config/cc-isolated.sh:676-677`, `devcontainer-config/cc-isolated.sh:690-691`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what the printed text says and what step 1 does; does not establish recovery when the cause is the build: from a plain launch, a config-identity failure (and a provenance failure on an image without the baked hash) is printed after the launch has already run the same `devcontainer up --remove-existing-container`, so step 1 repeats it.

The hint text is accurate and the recipe is the supported path. But the config-identity check is the same comparison as `container_config_matches` (`cc-isolated.sh:686-687`: `if [ -z "$want_hash" ] || [ "$have_hash" != "$want_hash" ]`), so on a plain launch it can fail only after `:904-907` has already recreated the container. R5 shows it: DC_LOG holds `devcontainer up --workspace-folder ...` then `devcontainer up --remove-existing-container --workspace-fold...`, and the output then prints "Blessed config changed since this container was built — rebuilding it." followed by "PROBE FAIL (config identity): this container was built from config 'stale'" and "Recreate it with: / cc-isolated --probe-only ... && cc-isolated ..." (printed twice, once per probe_boundary call). For a cause that survives a recreate (the guide's shadowing `.devcontainer/Dockerfile` row), step 1 repeats the action that just failed. This is the C4 class, pre-existing (the old hint pointed at a plain relaunch, which does the same), and not a regression. The C4 override-log row (Claim 11) scopes the loop to "printed inside a `--probe-only` run", but R5 shows it is reached from a plain launch too.

**Evidence:** `devcontainer-config/cc-isolated.sh:669-693`, `devcontainer-config/cc-isolated.sh:900-930`, `$S/probe-cfgid-out.txt`, `$S/probe-cfgid-run.log`

---

## Claim 6: "This run is that verification: the container is recreated if it was built from another config, and the self-probe must pass (including the node-run firewall probes) before anything starts. A pass records the hash in $(verified_path)."

**Location:** `devcontainer-config/cc-isolated.sh:884-887`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the launch path; does not establish the narrower --probe-only case, where the same NOTE prints (it precedes the action branch) and the container is always recreated, so "if it was built from another config" understates but does not contradict.

The NOTE is inside `if ! is_verified_live; then` at `:882-888`, before `if [ "$action" = "probe" ]` at `:891`. R1's fail-closed test asserts the NOTE appears and `[[ "$output" != *"the container is rebuilt from it"* ]]`; R5's output prints the new NOTE text verbatim.

**Evidence:** `devcontainer-config/cc-isolated.sh:882-897`, `test/cc-isolated-functions.bats:1406-1408`, `$S/probe-cfgid-out.txt`

---

## Claim 7: "--probe-only is the verification command, so it always recreates: probing a container left over from an earlier config would verify the wrong boundary."

**Location:** `devcontainer-config/cc-isolated.sh:895-896`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the unconditional `--remove-existing-container` at `:894`; does not establish image-cache behaviour.

`devcontainer up --remove-existing-container "${dc[@]}"` (`:894`) has no condition (Claim 1 quote). R1 "--probe-only always recreates before probing" passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:891-897`, `test/cc-isolated-functions.bats:1414-1425`

---

## Claim 8: "--probe-only always recreates the container from the blessed config and re-probes."

**Location:** `devcontainer-config/init-firewall.sh:346`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the launcher's probe branch (`cc-isolated.sh:891-897`) and that `CC_CONFIG_HASH` is the blessed hash (`:841-842`); does not establish image-cache behaviour.

Claim 1's quote shows the recreate and probe; `CC_CONFIG_HASH="$(blessed_hash)"` (`cc-isolated.sh:841`) is exported before it.

**Evidence:** `devcontainer-config/init-firewall.sh:343-349`, `devcontainer-config/cc-isolated.sh:841-842`, `devcontainer-config/cc-isolated.sh:891-897`

---

## Claim 9: "The explanations are not trailing `# ...` comments on the command lines: interactive zsh without interactivecomments passes those words to cc-isolated as arguments, and the last positional becomes the workspace."

**Location:** `devcontainer-config/init-firewall.sh:347-349`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers zsh's word splitting (R6) and main()'s argument loop; does not establish what happens next with that workspace word (fails or launches, see Claim 18).

`*)            ws_arg="$1"; shift ;;` (`cc-isolated.sh:759`) overwrites `ws_arg` for each non-flag word, so the last wins. R6 shows the comment words arriving as arguments.

**Evidence:** `devcontainer-config/cc-isolated.sh:742-761`, `devcontainer-config/init-firewall.sh:347-349`, `$S/zsh-probe.log`

---

## Claim 10: init-firewall.sh's fail-closed recipe: "The first command recreates it from the blessed config and re-probes; the second starts the session:" followed by the two bare command lines

**Location:** `devcontainer-config/init-firewall.sh:350-355`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the text and the command-alone lines within fail_closed_on_abort() (`:300-357`, read); does not establish that the user is told to skip the second command if the first fails (unlike rebuild_hint, there is no `&&`).

```bash
# devcontainer-config/init-firewall.sh:350-355 (inside fail_closed_on_abort(), :300-357, read)
    echo "       If this container can no longer bootstrap, recreate it from the HOST" >&2
    echo "       with the launcher (the ~/.claude volume and the repo are unaffected)." >&2
    echo "       The first command recreates it from the blessed config and re-probes;" >&2
    echo "       the second starts the session:" >&2
    echo "         cc-isolated --probe-only <repo>" >&2
    echo "         cc-isolated <repo>" >&2
```

R1 passes the `grep -qx` assertions on both command lines.

**Evidence:** `devcontainer-config/init-firewall.sh:300-357`, `test/init-firewall-rules.bats:1482-1500`, `$S/bats-2463017f.log`

---

## Claim 11: Override-log row: "A provenance or config-identity failure printed inside a `--probe-only` run points back at `--probe-only`, which just repeats the recreate; the cause there is the build ... (`devcontainer-config/cc-isolated.sh:670-689`, ...; pre-existing)" — Defer, revisit trigger "a user reports a `--probe-only` loop on either failure, or the next change to probe_boundary's failure messages"

**Location:** `docs/reviews/override-log.md:847`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the row's description and its cited range; does not establish that the row covers every route to the loop.

The description holds for --probe-only runs. Two imprecisions. (1) The range `:670-689` starts inside the provenance `if` (which opens at `:669`) and ends before the config-identity hint (`:690-691`: `echo "  you blessed. Recreate it with:" >&2` / `rebuild_hint "$ws" "${dc[@]}"`) and the block's end at `:693`. (2) Per Claim 5b (R5), the same repeat-the-recreate loop is reached from a plain launch whose hash-mismatch recreate (`:904-907`) already ran, and the row names only "inside a `--probe-only` run". Its first revisit trigger names only "a `--probe-only` loop".

**Evidence:** `docs/reviews/override-log.md:847`, `devcontainer-config/cc-isolated.sh:669-693`, `devcontainer-config/cc-isolated.sh:904-907`, `$S/probe-cfgid-out.txt`

---

## Claim 12: Override-log row: "`install.sh`'s "Next steps" block prints placeholder commands with trailing `# ...` notes ... and its `--probe-only` row still says "rebuilds" (`devcontainer-config/install.sh:612-617`, ...)" — Defer, revisit trigger "the next edit to install.sh's "Next steps" block, or a user report of a stray workspace argument"

**Location:** `docs/reviews/override-log.md:848`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the cited lines and the "rebuilds" word; does not establish the row's likelihood assessment.

```bash
# devcontainer-config/install.sh:612-614 (the block continues to :617, read)
  echo "  touch ~/.ssh/canary                    # once, if you haven't — strengthens the H1 probe"
  echo "  cc-isolated --probe-only <repo>        # REQUIRED after any boundary change: rebuilds from"
  echo "                                         # this config and records it verified live on a pass"
```

`:615-617` carry the same trailing-`#` form.

**Evidence:** `devcontainer-config/install.sh:607-622`

---

## Claim 13: "cc-isolated --probe-only [REPO]   # RECREATE REPO's container from the blessed config, run the self-probe, record the config verified live on a pass"

**Location:** `guides/cc-isolated-usage.md:25-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the verb and "on a pass"; does not establish real Docker behaviour.

Same code as Claim 1 (paraphrased — no quote available because the evidence is Claim 1's quoted probe branch and `:708-714`).

**Evidence:** `devcontainer-config/cc-isolated.sh:891-897`, `devcontainer-config/cc-isolated.sh:708-714`

---

## Claim 14: "Run the verification explicitly after any boundary change — it always recreates the container first, so it can never verify a leftover container"

**Location:** `guides/cc-isolated-usage.md:841-842`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the unconditional recreate; does not establish that cached image layers are rebuilt.

Same evidence as Claim 7 (paraphrased — no quote available because it is the `:897` line already quoted in Claim 1).

**Evidence:** `devcontainer-config/cc-isolated.sh:891-897`, `$S/bats-2463017f.log`

---

## Claim 15: "Expected after `install.sh`, `--bless` or `--register`. The launch recreates the container if it was built from another config, then verifies"

**Location:** `guides/cc-isolated-usage.md:955`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the launch path's conditional recreate; does not establish the --probe-only case (always recreated).

Same evidence as Claims 2 and 6 (paraphrased — no quote available because the recreate condition is quoted in Claim 2). install.sh, --bless and --register all reach bless_manifest (`install.sh:607`, `cc-isolated.sh:798`, register_project at `:479`), which does not write verified-live.

**Evidence:** `devcontainer-config/cc-isolated.sh:479`, `devcontainer-config/cc-isolated.sh:882-907`, `devcontainer-config/install.sh:607`

---

## Claim 16: "Relaunch with `cc-isolated <repo>`, which recreates it with both set."

**Location:** `guides/cc-isolated-usage.md:963`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a container whose `/etc/cc-config-hash` is empty (the row's symptom): the hash differs, so the launch recreates with `CC_EGRESS_PROFILE` and `CC_CONFIG_HASH` exported; does not establish Docker's handling of the build args.

`container_config_matches` fails when `have` is empty and `CC_CONFIG_HASH` is set (`:583`), triggering `:906`; the exports are `export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR` (`:831`) and `export CC_CONFIG_HASH` (`:842`). R1's mismatch test (`test/cc-isolated-functions.bats:1360-1361`) passes, and the matching-container test checks `CC_CONFIG_HASH=` in `up`'s env (`:1384`).

**Evidence:** `devcontainer-config/cc-isolated.sh:580-584`, `devcontainer-config/cc-isolated.sh:825-842`, `test/cc-isolated-functions.bats:1350-1387`

---

## Claim 17: rebuild_hint test comments and assertions: "It is the guides' two-step recipe, never a bare relaunch: a plain launch recreates only on a config-hash mismatch, so in the fail-closed state it does not recover" and the three assertions (line 1 exactly the command; line 2 "recreates the container from the blessed config"; no "rebuilds")

**Location:** `test/cc-isolated-functions.bats:351-362`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the assertions matching the comment and failing on the 9660d4f6 text; does not establish the zsh outcome sentence (Claim 18).

```bash
# test/cc-isolated-functions.bats:360-362
  [ "$(echo "$output" | head -1)" = "    cc-isolated --probe-only $ws && cc-isolated $ws" ]
  [[ "$(echo "$output" | sed -n 2p)" == *"recreates the container from the blessed config"* ]]
  [[ "$output" != *"rebuilds"* ]]
```

R1 passes; R2 fails it at `:360` on the 9660d4f6 script.

**Evidence:** `test/cc-isolated-functions.bats:346-363`, `$S/bats-2463017f.log`, `$S/bats-base-scripts.log`

---

## Claim 18: "and the last positional becomes the workspace, so step 2 fails or, if that word names a git repo in the cwd, launches it"

**Location:** `test/cc-isolated-functions.bats:357-358`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the outcome of a stray last word through resolve_workspace; does not establish any other cc-isolated argument handling.

```bash
# devcontainer-config/cc-isolated.sh:357-370 (resolve_workspace(), whole unit)
resolve_workspace() {
  local start="${1:-$PWD}" top
  if [ ! -d "$start" ]; then
    echo "ERROR: not a directory: $start" >&2
    return 1
  fi
  if ! top="$(git -C "$start" rev-parse --show-toplevel 2>/dev/null)"; then
    ...
    return 1
  fi
  echo "$top"
}
```

(The `...` elides three `echo` lines of the error message, `:364-366`, read.) A launch happens whenever the word names a directory *inside* any git repo, not only when it is a git repo, and what launches is that directory's toplevel. R7: from a repo `R` that contains a plain `launches/` subdirectory, `resolve_workspace launches` printed `.../rw/R` with rc 0, so step 2 would launch the cwd's own repo. A tighter version: "step 2 fails, or, if that word names a directory inside a git repo, launches that repo".

**Evidence:** `devcontainer-config/cc-isolated.sh:357-370`, `devcontainer-config/cc-isolated.sh:759`, `$S/rw-probe.log`

---

## Claim 19: "STUB_FW_BRICKED=1 → re-running the baked init-firewall.sh fails (fail-closed state)."

**Location:** `test/cc-isolated-functions.bats:1157`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stub's case arm and that no earlier arm captures the call; does not establish real container behaviour.

`*init-firewall.sh*)      [ -z "${STUB_FW_BRICKED:-}" ] ;;` (`:1171`) follows `*cc-config-hash*`, `*rev-parse*` and `*cc-firewall/complete*`, none of which match `exec ... sudo /usr/local/bin/init-firewall.sh` (`cc-isolated.sh:922`). R1's fail-closed test reaches "ERROR: init-firewall.sh failed".

**Evidence:** `test/cc-isolated-functions.bats:1160-1185`, `devcontainer-config/cc-isolated.sh:922`, `$S/bats-2463017f.log`

---

## Claim 20: Fail-closed launch test: comment "in the fail-closed state the container was built from the blessed config, so a plain launch does not recreate it, and the hint used to send the user straight back into that launch"; "The unverified-config NOTE must not promise the recreate this launch skips."; "The premise of the hint: this launch reused the container and never started claude."

**Location:** `test/cc-isolated-functions.bats:1389-1412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each comment against its assertions and the regression property; does not establish that the test asserts the new NOTE wording (it asserts only the absence of the old phrase).

The assertions are `[[ "$output" == *"Recreate it"*"cc-isolated --probe-only $ws && cc-isolated $ws"* ]]`, `[[ "$output" != *"the container is rebuilt from it"* ]]`, `run ! grep -q -- '--remove-existing-container' "$DC_LOG"` and `run ! grep -q ' claude$' "$DC_LOG"` (`:1405-1411`; the suite declares `bats_require_minimum_version 1.5.0` at `:13`, so `run !` fails the test on a zero exit). R1 passes; R2 fails it at `:1405` on 9660d4f6 (the NOTE assertion at `:1408` would also fail there: the 9660d4f6 NOTE text was "the container is rebuilt from it", per the diff).

**Evidence:** `test/cc-isolated-functions.bats:13`, `test/cc-isolated-functions.bats:1389-1412`, `$S/bats-2463017f.log`, `$S/bats-base-scripts.log`

---

## Claim 21: "--probe-only always recreates before probing" (renamed test)

**Location:** `test/cc-isolated-functions.bats:1414-1425`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the name against `grep -q '^devcontainer up --remove-existing-container ' "$DC_LOG"` (`:1423`); does not establish ordering (the test does not check that the recreate precedes the probe calls).

R1 passes.

**Evidence:** `test/cc-isolated-functions.bats:1414-1425`, `$S/bats-2463017f.log`

---

## Claim 22: "The hint's `&&` relies on this: a failed probe after the forced recreate must exit non-zero and never start claude" / test name "--probe-only exits non-zero and records nothing when the probe fails"

**Location:** `test/cc-isolated-functions.bats:1427-1442`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the comment and name against the assertions; does not establish anything beyond the stubbed devcontainer.

The test asserts `[ "$status" -ne 0 ]`, the firewall PROBE FAIL line, the forced recreate in DC_LOG and `[ ! -f "$(verified_path)" ]` (`:1438-1441`). The comment's "and never start claude" is no longer asserted: 2463017f removed `run ! grep -q ' claude$' "$DC_LOG"` because it could not fail. The property still holds by construction, since the probe branch (`cc-isolated.sh:891-897`) has no claude exec. The comment reads as what the test checks, so "never start claude" could say "(no claude exec on this path; not asserted)". The name's "records nothing" is asserted only for verified-live. The test passes on 9660d4f6 too (R2), as expected: it pins unchanged behaviour, not text.

**Evidence:** `test/cc-isolated-functions.bats:1427-1442`, `devcontainer-config/cc-isolated.sh:891-897`, `$S/bats-2463017f.log`, `$S/bats-base-scripts.log`

---

## Claim 23: "--probe-only recreates the container (cached image layers are reused), the word the guides use"

**Location:** `test/init-firewall-rules.bats:1491-1492`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers "the word the guides use" (Verified: `guides/cc-isolated-usage.md:25`, `:841`, `:957`); the parenthetical about cached image layers is devcontainer CLI/Docker behaviour this sandbox cannot run (no Docker).

`devcontainer up --remove-existing-container` passes no `--build-no-cache` (`cc-isolated.sh:894`; paraphrased — no quote available because the claim covers absence of a flag). The deferred security i2 #2 item ("no documented way to refresh the cached CC layer") matches the parenthetical. Needed: a host run with Docker.

**Evidence:** `devcontainer-config/cc-isolated.sh:894`, `guides/cc-isolated-usage.md:25`, `test/init-firewall-rules.bats:1491-1494`

---

## Claim 24: "Each command line is the command alone: a trailing `# ...` is passed as arguments by interactive zsh without interactivecomments" and its two `grep -qx` assertions

**Location:** `test/init-firewall-rules.bats:1495-1499`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each assertion matching the comment and each failing on 980a9db4's text on its own; does not establish the zsh claim beyond R6.

```bash
# test/init-firewall-rules.bats:1498-1499
  printf '%s\n' "$output" | grep -qx ' *cc-isolated --probe-only <repo>'
  printf '%s\n' "$output" | grep -qx ' *cc-isolated <repo>'
```

R3: with 980a9db4's init-firewall.sh (`cc-isolated --probe-only <repo>    # recreates it from the blessed config, re-probes`), the test fails at `:1493` first; with `:1493-1494` removed it fails at the first `grep -qx`; with that removed too it fails at the second. R1 passes.

**Evidence:** `test/init-firewall-rules.bats:1482-1500`, `$S/bats-i1-scripts.log`, `$S/bats-i1-gx.log`, `$S/bats-i1-gx2.log`

---

## Claim 25a: cb56299c body: mechanism and change list: "A plain launch recreates the container only when its baked config hash differs from the blessed one, so in the fail-closed state ... it reuses the bricked container, fails the same way, and prints the same hint"; "--probe-only always recreates and exits non-zero on a failed probe"; "The by-hand form is unchanged"; the changed sites (the two "Rebuild with:" lead-ins, the --probe-only comment in main, init-firewall.sh's comment and echo, two guide lines); "Tests: ... All three fail on the old text"; "Message text and comments only"

**Location:** commit `cb56299c` body
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed atom; does not cover the two Notes atoms in Claim 25b.

Mechanism: Claims 4a, 4b. Change list: `git show cb56299c` touches exactly those sites (the guide's `:25` and the "which rebuilds with both set" row) (paraphrased — no quote available because the evidence is the diff hunks, summarised). R4 runs cb56299c's own tests against the 9660d4f6 scripts: all three fail (`:355`, `:1400`, init-firewall `:1493`). R8: no non-comment, non-echo line changed across the whole range.

**Evidence:** `devcontainer-config/cc-isolated.sh:560-577`, `$S/bats-cb-tests-base-scripts.log`, `$S/non-comment-diff.log`

---

## Claim 25b: cb56299c Notes: "The printed "Blessed config changed ... rebuilding it." line is left as is (a guide row quotes it verbatim)" and "the next launch recreates each project's container once (init-firewall.sh is baked into the image)"

**Location:** commit `cb56299c` body (Notes)
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both Notes atoms; the verdict is carried by "verbatim" (the cause attribution is Mostly accurate). Both atoms are already corrected in 980a9db4's A4 paragraph (Claim 27), so nothing is left to act on.

The guide row is `` `Blessed config changed since this container was built — rebuilding` `` (`guides/cc-isolated-usage.md:956`), while the script prints `"Blessed config changed since this container was built — rebuilding it."` (`cc-isolated.sh:905`). The recreate is caused by the hash changing: both scripts are manifest entries (`echo "init-firewall.sh"`, `echo "cc-isolated.sh"`, `cc-isolated.sh:135`, `:138`), not by init-firewall.sh being baked.

**Evidence:** `guides/cc-isolated-usage.md:956`, `devcontainer-config/cc-isolated.sh:130-152`, `devcontainer-config/cc-isolated.sh:905`

---

## Claim 26: 980a9db4 Notes: "C4 (a provenance or config-identity failure inside a --probe-only run points back at --probe-only; pre-existing) is deferred with a revisit trigger in the rubric and override log."

**Location:** commit `980a9db4` body (Notes)
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the repository state at 980a9db4; it does not establish the state at HEAD, where the claim has become true (2463017f added the rubric deferral and override-log row, Claim 33).

At 980a9db4 the rubric row reads `| C4 | ... | Informational | for-author | — | 🟢 Open |` (`git show 980a9db4:docs/reviews/code-review-rubric-2026-10-15-fix-rebuild-hint-recreate.md`, line 34), with no revisit trigger. `git show 980a9db4:docs/reviews/override-log.md | grep -c rebuild-hint-recreate` returns 0, and `git show --stat 980a9db4` does not touch override-log.md; both rows (`override-log.md:847-848`) arrive in 2463017f. 2463017f's body ("C4 ... is logged in the override log with its revisit trigger") makes the record true but does not say it corrects 980a9db4, unlike its A5/A6 corrections. Commit bodies are immutable, so the only action is an override-log or rubric note (Accepted-immutable). No earlier fact-check pass covered this atom.

**Evidence:** `docs/reviews/override-log.md:847`, `docs/reviews/code-review-rubric-2026-10-15-fix-rebuild-hint-recreate.md:37`

---

## Claim 27: 980a9db4 body: A2, A3, C3, C6, the A4 correction of cb56299c, and "rebuild stays where the image really is rebuilt (--register's note, the re-bless notes) and in the "Blessed config changed ... rebuilding it." line, which a guide row and a test match"

**Location:** commit `980a9db4` body
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers these atoms; does not cover A1's outcome sentence (Claim 28) or C1's naming (Claim 29).

A2 "the receipt is missing and the hash matches": the NOTE prints only under `! is_verified_live` (`:882`), and in the fail-closed state the hash matches (Claim 4a). The fail-closed test asserts it (Claim 20). A3: Claim 1. C3/C6: the tests at `:1414` and `:1429` (C3's "starts no session" assertion was later dropped, Claim 22). A4: Claim 25b. Kept "rebuild": `echo "Next launch rebuilds the image for the new profile."` (`:481`), the host-tool boundary_note "the next launch then rebuilds and probes" (`:770`), the guide row `:956` and `[[ "$output" == *"Blessed config changed since this container was built"* ]]` (`test/cc-isolated-functions.bats:1360`).

**Evidence:** `devcontainer-config/cc-isolated.sh:481`, `devcontainer-config/cc-isolated.sh:770`, `devcontainer-config/cc-isolated.sh:882`, `guides/cc-isolated-usage.md:956`, `test/cc-isolated-functions.bats:1360`

---

## Claim 28: 980a9db4 A1: "Interactive zsh without interactivecomments passed those words to step 2 as arguments, and main() keeps the last positional, so the launch retargeted to ./launches." — and 2463017f's correction: "the launch retargeted to ./launches" happens only when ./launches is a git repo; otherwise step 2 errors out.

**Location:** commit `980a9db4` body (A1); commit `2463017f` body (A5)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both bodies' outcome sentences; the mechanism (words become arguments, last positional wins) is Verified (Claims 4c, 9).

The correction is closer, but its condition is too narrow in the same way as Claim 18: a launch happens whenever `./launches` is a directory inside a git repo, and what launches is that repo's toplevel (R7: `resolve_workspace launches` from repo R with a plain `launches/` subdir printed R). "Otherwise step 2 errors out" is therefore false for that case. Commit bodies are immutable. Low stakes, since the trailing-comment form is gone from this hint.

**Evidence:** `devcontainer-config/cc-isolated.sh:357-370`, `$S/rw-probe.log`

---

## Claim 29: 980a9db4 C1: "the --list "Next:" line ... say[s] recreates" — and 2463017f's correction (A6): the line "is printed by bless_manifest (--bless, --register, install.sh), not by --list"

**Location:** commit `980a9db4` body (C1); commit `2463017f` body (A6)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** The verdict is for 980a9db4's naming; 2463017f's correction is Verified.

list_projects prints `"Blessed config $b — verified live: NO (run: cc-isolated --probe-only <repo>)"` (`:490`) and no "Next:". The "Next:" line is in bless_manifest (`:318`), reached by `bless) bless_manifest` (`:798`), `register_project` (`:479`) and `install.sh:607` (`"$DEST/cc-isolated.sh" --bless`).

**Evidence:** `devcontainer-config/cc-isolated.sh:318`, `devcontainer-config/cc-isolated.sh:479`, `devcontainer-config/cc-isolated.sh:484-535`, `devcontainer-config/cc-isolated.sh:798`, `devcontainer-config/install.sh:607`

---

## Claim 30: 2463017f A7: "init-firewall.sh's fail-closed recipe and the bless "Next:" line still ended their command lines in `# ...` ... The commands are now alone on their lines with the explanation above or below; the init-firewall test pins both command lines with grep -x. install.sh's "Next steps" block has the same form and is deferred (override log row, revisit trigger: its next edit)."

**Location:** commit `2463017f` body (A7)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each atom; does not establish that the bless line is test-pinned (the body does not claim it is).

The 980a9db4 texts carried trailing comments (`git show 980a9db4:devcontainer-config/init-firewall.sh`, lines 349-350, and the diff's `-    echo "  Next: cc-isolated --probe-only <repo>   # rebuilds from it and probes as node"`). The HEAD forms are in Claims 3 and 10; the pins are in Claim 24; the deferral is Claim 12.

**Evidence:** `devcontainer-config/cc-isolated.sh:318-319`, `devcontainer-config/init-firewall.sh:350-355`, `test/init-firewall-rules.bats:1498-1499`, `docs/reviews/override-log.md:848`, `$S/bats-i1-gx.log`

---

## Claim 31: 2463017f: "The --probe-only fail-case test drops its "no claude" assertion, which could never fail (--probe-only has no claude exec); renamed accordingly." and "C9: --help's --probe-only line rewrapped to the block's width."

**Location:** commit `2463017f` body
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the removal, the reason, the rename and the rewrap; the leftover comment wording is Claim 22.

The diff removes `-  run ! grep -q ' claude$' "$DC_LOG"` and renames "...starts no session..." to "...records nothing..."; the probe branch has no claude exec (Claim 1). Rewrap: Claim 1.

**Evidence:** `test/cc-isolated-functions.bats:1429`, `devcontainer-config/cc-isolated.sh:13-15`, `devcontainer-config/cc-isolated.sh:891-897`

---

## Claim 32: 2463017f Notes: "Printed text, comments, tests and review records only; no iptables call, probe check, recreate decision or exit status changed. Each new assertion fails on the previous text (trailing-comment command lines)." (and the same "no ... changed" note in cb56299c and 980a9db4)

**Location:** commit `2463017f` body (Notes); commits `cb56299c`, `980a9db4` (Notes)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the whole 9660d4f6..2463017f script diff and 2463017f's two new assertions; does not cover the test edits that are not new assertions (comment rewording, the dropped assertion).

R8 output is empty: every changed script line is a comment or an `echo`. R3 shows each new `grep -qx` fails on 980a9db4's init-firewall.sh on its own.

**Evidence:** `$S/non-comment-diff.log`, `$S/bats-i1-gx.log`, `$S/bats-i1-gx2.log`

---

## Claim 33: 2463017f: "C4 (pre-existing --probe-only loop on a build failure) is logged in the override log with its revisit trigger."

**Location:** commit `2463017f` body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the row's existence and trigger; its content's precision is Claim 11.

`override-log.md:847` carries the row with "Revisit trigger: a user reports a `--probe-only` loop on either failure, or the next change to probe_boundary's failure messages."

**Evidence:** `docs/reviews/override-log.md:847`

---

## Claims Requiring Attention

### Incorrect
- **Claim 26** (commit `980a9db4` Notes): says C4 "is deferred with a revisit trigger in the rubric and override log". At that commit the rubric showed C4 "🟢 Open" and the override log had no row. 2463017f made it true without labelling a correction. The body is immutable, so record it as Accepted-immutable.
- **Claim 25b** (commit `cb56299c` Notes): "a guide row quotes it verbatim". The row quotes only up to "rebuilding". Already corrected in 980a9db4's A4, so nothing to do.

### Mostly Accurate
- **Claim 5b** (`devcontainer-config/cc-isolated.sh:677`, `:691`): from a plain launch, a config-identity failure is printed after the launch already ran the same `--remove-existing-container`, so the recipe's step 1 repeats it. This is the C4 class (pre-existing), but it is reached outside --probe-only too.
- **Claim 11** (`docs/reviews/override-log.md:847`): the C4 row scopes the loop to "inside a `--probe-only` run", and its first trigger to "a `--probe-only` loop". Its range `:670-689` stops before the config-identity hint at `:690-691`.
- **Claim 18** (`test/cc-isolated-functions.bats:357-358`): "if that word names a git repo in the cwd" should be "names a directory inside a git repo". That repo, possibly the cwd's own, is what launches.
- **Claim 22** (`test/cc-isolated-functions.bats:1427-1428`): the comment's "never start claude" is no longer asserted (true by construction).
- **Claim 28** (commits `980a9db4` A1 / `2463017f` A5): the correction's "only when ./launches is a git repo; otherwise step 2 errors out" misses a `launches/` directory inside a repo.
- **Claim 29** (commit `980a9db4` C1): called the bless_manifest "Next:" line the --list line. Already corrected by 2463017f's A6.

### Unverifiable
- **Claim 23** (`test/init-firewall-rules.bats:1491`): "cached image layers are reused" is Docker/devcontainer CLI behaviour. It needs a host run with Docker.

## Goal-Alignment Note
- Success criterion (restated verbatim): Success criterion: a code-fact-check report saved at the path below, structured per the skill, verdicting at least the claims listed above.
- Answered: yes. All seven listed claim groups are verdicted (1: Claims 4a-c; 2: 5a-b; 3: 1-3, 6; 4: 8-10; 5: 13-16; 6: 17-24; 7: 11-12, 25-33), with executed regression runs against the 9660d4f6, cb56299c-era and 980a9db4 texts.
- Out of scope: real Docker/devcontainer behaviour (no Docker in the sandbox; the branch's Live-verified trailers already defer it to the host probe); install.sh's block beyond checking the override row's citation.
- Escalate: Claim 26 is a new record-accuracy finding no earlier pass covered (immutable body, so an override-log note). Claims 5b and 11 widen C4's described scope to plain launches. That is pre-existing and fits the existing Defer, but the row's wording and first trigger could name it.
- Decisions I made: I took "right recovery" in brief item 2 to mean "step 1 changes the state that caused the failure", which is how I split 5a from 5b. I counted cb56299c's already-corrected "verbatim" note as Incorrect rather than skipping it, for completeness.
