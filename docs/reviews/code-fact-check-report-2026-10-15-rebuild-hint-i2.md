# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-rebuild-hint, branch fix/rebuild-hint-recreate)
**Scope:** `git diff cb56299c..980a9db4` minus docs/reviews (devcontainer-config/cc-isolated.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats) plus the commit message of 980a9db4
**Checked:** 2026-10-15
**Commit:** 980a9db4
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 20
**Summary:** 17 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance (shared by every `executed` claim). Scratch dir `S=/home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/code-fact-check-i2`; captured output in `$S/`:

| Run | Command | cwd | Exit | UTC |
|---|---|---|---|---|
| R1 new suite | `timeout 600 bash scripts/run-tests.sh test/cc-isolated-functions.bats` | worktree | 0 (195/195 ok) | 2026-10-15T11:16:27Z → `$S/bats-980a9db4.log` |
| R2 old scripts | `timeout 300 bats -f 'rebuild_hint names the launcher\|fail-closed container does not recreate\|--probe-only' test/cc-isolated-functions.bats`, on a `git archive 980a9db4` copy with `cc-isolated.sh` replaced by `git show cb56299c:devcontainer-config/cc-isolated.sh` | `$S/tree-old` | 1 (test "rebuild_hint names the launcher…" not ok at :359; "fail-closed container…" not ok at :1407; both --probe-only tests ok) | 2026-10-15T11:17:55Z → `$S/bats-cb56299c-scripts.log` |
| R3 zsh | `bash zsh-probe.sh` (feeds the old hint's shape, with `f` printing each argument in brackets, to `zsh -f -i`) | `$S` | 0 | 2026-10-15T11:18:10Z → `$S/zsh-probe.log` |
| R4 last positional | `cc-isolated.sh <worktree> '#' the supported path: recreates from the blessed config, re-probes, then launches` (stub devcontainer, throwaway HOME/config dir) | `$S` | 1 | 2026-10-15T11:18:20Z → `$S/lastpos.log` |
| R5 mutant | `bats -f 'probe-only exits non-zero'` on an archive copy whose --probe-only branch reads `probe_boundary "$ws" \|\| true` | `$S/tree-mut` | 1 (mutant caught at :1437 `[ "$status" -ne 0 ]`) | 2026-10-15T11:18:26Z → `$S/bats-mutant-probe-swallowed.log` |
| R6 diff filter | `git diff cb56299c..980a9db4 -- devcontainer-config \| grep '^[-+]' \| grep -v '^[-+][-+]' \| grep -v '^[-+]\s*#' \| grep -v '^[-+]\s*echo'` | worktree | 1 from last grep (no lines) | 2026-10-15T11:19:24Z → `$S/non-comment-diff.log` (0 bytes); `grep -n rebuil` → `$S/rebuild-grep.log` |

I read `docs/reviews/hallucination-patterns.md`. None of its 8 logged patterns resembles any claim below.

---

## Claim 1: "cc-isolated --probe-only [WS]  # recreate WS's container from the blessed config, run the boundary self-probe, record it verified live"

**Location:** `devcontainer-config/cc-isolated.sh:13-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the verb this commit changed ("recreate") and the probe-action branch of main(). It does not establish that "record it verified live" happens unconditionally (it happens only on a pass, pre-existing wording) or any real Docker behaviour.

The probe branch (`cc-isolated.sh:887-893`, inside main(), which continues to `:957`, all of it read):

```bash
  if [ "$action" = "probe" ]; then
    # --probe-only is the verification command, so it always recreates: ...
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
  fi
```

`probe_boundary` calls `record_verified_live` only after `failures` is 0 (`cc-isolated.sh:706-713`: `if [ "$failures" -gt 0 ]; then ... return 1; fi` then `record_verified_live`). R1's "--probe-only always recreates before probing" passes, and it greps `^devcontainer up --remove-existing-container ` in the stub log.

**Evidence:** `devcontainer-config/cc-isolated.sh:13-14`, `devcontainer-config/cc-isolated.sh:887-893`, `devcontainer-config/cc-isolated.sh:706-713`, `$S/bats-980a9db4.log`

---

## Claim 2: "A launch on an unverified config says so, recreates the container if it was built from another config so the probe exercises the new config rather than an old image (--probe-only always recreates), and refuses to start a session unless the baked firewall script reached its completion marker."

**Location:** `devcontainer-config/cc-isolated.sh:60-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the plain-launch recreate condition (`container_config_matches`), the --probe-only unconditional recreate, and the firewall-marker refusal. It does not establish what `devcontainer up` does to a stopped container (it starts it rather than recreating it, which needs Docker to observe). The recreate is triggered by a hash mismatch whether or not the config is verified; the paragraph's "unverified" framing is narrower than that but not false.

The plain launch (`cc-isolated.sh:896-905`):

```bash
  devcontainer up "${dc[@]}"
  ...
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi
```

`container_config_matches` (`cc-isolated.sh:578-582`) is `[ -n "${CC_CONFIG_HASH:-}" ] && [ "$have" = "$CC_CONFIG_HASH" ]`, where `have` is the container's `/etc/cc-config-hash`. The firewall check `devcontainer exec "${dc[@]}" test -f /run/cc-firewall/complete` (`:698`) counts as a probe failure, and a failed probe never reaches `devcontainer exec ... claude` (`:936`): main() runs under `set -euo pipefail` (`:67`). R1 covers this: "a launch rebuilds a container whose baked config is not the blessed one" (recreate on mismatch), "a launch on a matching, verified container does not rebuild" (no `--remove-existing-container`), and the fail-closed test (no claude started).

**Evidence:** `devcontainer-config/cc-isolated.sh:60-63`, `devcontainer-config/cc-isolated.sh:67`, `devcontainer-config/cc-isolated.sh:578-582`, `devcontainer-config/cc-isolated.sh:698`, `devcontainer-config/cc-isolated.sh:896-936`, `test/cc-isolated-functions.bats:1347-1385`, `$S/bats-980a9db4.log`

---

## Claim 3: "Next: cc-isolated --probe-only <repo>   # recreates from it and probes as node"

**Location:** `devcontainer-config/cc-isolated.sh:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the "recreates" verb against the probe branch. It does not establish "probes as node" (pre-existing text about init-firewall.sh's node-run probes, not touched here). It also does not establish which command prints the line: see Claim 16 for that.

This is the same probe branch quoted in Claim 1 (`cc-isolated.sh:889-891`, `devcontainer up --remove-existing-container "${dc[@]}"` then `probe_boundary "$ws"`). The line is inside `bless_manifest()` (`:282-322`, read in full), in its `else` branch after `is_verified_live` fails.

**Evidence:** `devcontainer-config/cc-isolated.sh:282-322`, `devcontainer-config/cc-isolated.sh:889-891`

---

## Claim 4: "The explanation is on its own line, not a trailing `# ...`: interactive zsh without interactivecomments would pass those words to step 2 as arguments."

**Location:** `devcontainer-config/cc-isolated.sh:565-566`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers zsh 5.x started with `-f -i` (no rc files, interactivecomments at its default of off). It does not establish behaviour under users' rc files (many frameworks such as oh-my-zsh set interactivecomments) or under bash, which treats `#` as a comment interactively by default.

R3 fed `f --probe-only WS && f WS   # the supported path: ... then launches` to `zsh -f -i`. The output shows step 2 receiving every word after `#`:

```
[--probe-only][WS]
[WS][#][the][supported][path:][recreates][from][the][blessed][config,][re-probes,][then][launches]
```

`$S/zsh-probe.log`. The same shell then ran `setopt interactivecomments` and treated `#` as a comment on the next line.

**Evidence:** `devcontainer-config/cc-isolated.sh:565-566`, `$S/zsh-probe.sh`, `$S/zsh-probe.log`

---

## Claim 5: The hint's first line is now only the command (`echo "    cc-isolated --probe-only $(printf '%q' "$ws") && cc-isolated $(printf '%q' "$ws")"`), with the explanation on line 2

**Location:** `devcontainer-config/cc-isolated.sh:567-568`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers rebuild_hint's output order and line 1's exact content for the test workspace. It does not establish how the three callers' surrounding text reads (each prints its own lead-in line before calling rebuild_hint).

```bash
  echo "    cc-isolated --probe-only $(printf '%q' "$ws") && cc-isolated $(printf '%q' "$ws")" >&2
  echo "      (the supported path: recreates the container from the blessed config, re-probes, then launches)" >&2
```
(`cc-isolated.sh:567-568`; rebuild_hint continues to `:575` with the by-hand form, read.) R1's "rebuild_hint names the launcher before the by-hand form" asserts `[ "$(echo "$output" | head -1)" = "    cc-isolated --probe-only $ws && cc-isolated $ws" ]` (`test/cc-isolated-functions.bats:359`) and passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:558-575`, `test/cc-isolated-functions.bats:345-362`, `$S/bats-980a9db4.log`

---

## Claim 6: "This run is that verification: the container is recreated if it was built from another config, and the self-probe must pass (including the node-run firewall probes) before anything starts."

**Location:** `devcontainer-config/cc-isolated.sh:880-885`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both actions that print the NOTE: the plain launch, which recreates exactly on a hash mismatch (Claim 2), and --probe-only, which recreates unconditionally, so the conditional is still true there, only understated. It does not establish "node-run firewall probes" (those live in init-firewall.sh, not re-read for this pass).

The NOTE is printed before the action split (`cc-isolated.sh:880-885`, then `if [ "$action" = "probe" ]` at `:887`), so both actions show it. For a plain launch the recreate is the `container_config_matches` branch (`:902-905`). For --probe-only it is `:891`, which runs regardless. R1's fail-closed test asserts the NOTE is present and `!= *"the container is rebuilt from it"*`. R2 shows that assertion fails on cb56299c's text (`:1407`).

**Evidence:** `devcontainer-config/cc-isolated.sh:880-905`, `test/cc-isolated-functions.bats:1404-1407`, `$S/bats-980a9db4.log`, `$S/bats-cb56299c-scripts.log`

---

## Claim 7: "Run the verification explicitly after any boundary change — it always recreates the container first, so it can never verify a leftover container"

**Location:** `guides/cc-isolated-usage.md:841-842`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers --probe-only's unconditional `--remove-existing-container`. It does not establish what the devcontainer CLI does with that flag against real Docker.

The guide's next block is `cc-isolated --probe-only ~/code/api`. The code is `cc-isolated.sh:891` (`devcontainer up --remove-existing-container "${dc[@]}"`, quoted in Claim 1), with no condition. R1's "--probe-only always recreates before probing" asserts it.

**Evidence:** `guides/cc-isolated-usage.md:841-845`, `devcontainer-config/cc-isolated.sh:887-893`, `$S/bats-980a9db4.log`

---

## Claim 8: "Expected after `install.sh`, `--bless` or `--register`. The launch recreates the container if it was built from another config, then verifies"

**Location:** `guides/cc-isolated-usage.md:955`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the plain-launch recreate condition and probe order. It does not establish the "Expected after" list (it is pre-existing; a re-bless that leaves the manifest unchanged keeps the receipt valid, so the NOTE does not appear then).

See Claim 2's quote of `cc-isolated.sh:896-905`. `probe_boundary "$ws"` follows at `:910`. R1's recreate and no-recreate tests pass.

**Evidence:** `guides/cc-isolated-usage.md:955`, `devcontainer-config/cc-isolated.sh:896-910`, `$S/bats-980a9db4.log`

---

## Claim 9: "interactive zsh without interactivecomments passes a trailing `# ...` to step 2 as arguments, and the last positional wins, retargeting the launch"

**Location:** `test/cc-isolated-functions.bats:355-358`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the zsh word passing (R3) and main()'s last-positional rule (R4). It does not establish an actual retarget: that happens only if a directory named after the last word (`launches`) exists under the cwd and is inside a git repo; otherwise the launch errors out.

main()'s argument loop overwrites on every non-flag word: `*)            ws_arg="$1"; shift ;;` (`cc-isolated.sh:757`). R4 passed the old hint's words after a real repo path. The launcher printed `ERROR: not a directory: launches` and exited 1 (`$S/lastpos.log`). This comes from `resolve_workspace` (`cc-isolated.sh:355-368`: `if [ ! -d "$start" ]; then echo "ERROR: not a directory: $start"`). In the usual case the trailing comment makes step 2 fail. It does not open a session on another repo. A more precise wording: "the last positional wins, so step 2 targets ./launches (an error unless that directory exists)". The fix and the test are right either way.

**Evidence:** `test/cc-isolated-functions.bats:355-359`, `devcontainer-config/cc-isolated.sh:741-761`, `devcontainer-config/cc-isolated.sh:355-368`, `$S/zsh-probe.log`, `$S/lastpos.log`

---

## Claim 10: The tightened rebuild_hint assertions (line 1 exactly the command; line 2 says "recreates the container from the blessed config"; no "rebuilds" anywhere) fail on the cb56299c text

**Location:** `test/cc-isolated-functions.bats:359-361`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line-1 equality, which is the assertion that catches the cb56299c regression. It does not establish that the `!= *"rebuilds"*` assertion fails on cb56299c on its own: cb56299c's hint already said "recreates", so that assertion guards the older 9660d4f6 text instead.

R2: `not ok 1 rebuild_hint names the launcher before the by-hand form ... line 359 ... [ "$(echo "$output" | head -1)" = "    cc-isolated --probe-only $ws && cc-isolated $ws" ]' failed` (`$S/bats-cb56299c-scripts.log`). It passes on 980a9db4 (R1).

**Evidence:** `test/cc-isolated-functions.bats:345-362`, `$S/bats-cb56299c-scripts.log`, `$S/bats-980a9db4.log`

---

## Claim 11: "The unverified-config NOTE must not promise the recreate this launch skips." (fail-closed launch test's new assertions)

**Location:** `test/cc-isolated-functions.bats:1405-1407`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the negative assertion against cb56299c's exact phrase plus the NOTE being printed. It does not positively assert the new NOTE wording, so a different wrong wording would pass.

The test (`:1391-1410`, read in full) sets the stub's baked hash to the blessed one with the marker missing and the firewall bricked. It asserts `[[ "$output" == *"has NOT been verified in a live container"* ]]` and `[[ "$output" != *"the container is rebuilt from it"* ]]`, and that no `--remove-existing-container` was issued. R2 fails it at `:1407` on cb56299c. R1 passes it.

**Evidence:** `test/cc-isolated-functions.bats:1391-1410`, `$S/bats-cb56299c-scripts.log`, `$S/bats-980a9db4.log`

---

## Claim 12: "--probe-only always recreates before probing" (renamed test)

**Location:** `test/cc-isolated-functions.bats:1413`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the name matching its assertions (`--remove-existing-container` issued, exit 0, no claude). It does not establish ordering: the test does not check that the recreate precedes the probe's execs in the log.

The body asserts `grep -q '^devcontainer up --remove-existing-container ' "$DC_LOG"` (`:1422`). It passes in R1 and R2.

**Evidence:** `test/cc-isolated-functions.bats:1413-1424`, `$S/bats-980a9db4.log`

---

## Claim 13: "The hint's `&&` relies on this: a failed probe after the forced recreate must exit non-zero and never start claude." (new --probe-only fail-case test)

**Location:** `test/cc-isolated-functions.bats:1426-1443`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test reaching the failed-probe exit through the firewall check only, and catching a swallowed probe failure. It does not establish that "never start claude" can fail in this test: the probe branch has no claude exec at all, so that assertion is trivially true. The test also passes on cb56299c, because it is new coverage of a property that already held, not a regression test.

The stub's baked hash equals the blessed one, the fingerprint matches and `STUB_CLAUDE_DIR` is unset, so H1, egress, workspace, H6, provenance and config identity all pass (`smart_devcontainer_stub`, `test/cc-isolated-functions.bats:1159-1184`, defaults to `exit 0`). Only `*cc-firewall/complete*) [ -z "${STUB_FW_MISSING:-}" ]` fails. probe_boundary then returns 1 (`cc-isolated.sh:706-708`) and `set -e` ends main() before `exit 0` (`:892`). R5 replaced that call with `probe_boundary "$ws" || true`, and the test failed at `:1437` `[ "$status" -ne 0 ]` (`$S/bats-mutant-probe-swallowed.log`). It also asserts `[ ! -f "$(verified_path)" ]` and the forced recreate.

**Evidence:** `test/cc-isolated-functions.bats:1159-1184`, `test/cc-isolated-functions.bats:1426-1443`, `devcontainer-config/cc-isolated.sh:706-713`, `devcontainer-config/cc-isolated.sh:887-893`, `$S/bats-mutant-probe-swallowed.log`, `$S/bats-cb56299c-scripts.log`

---

## Claim 14: "Interactive zsh without interactivecomments passed those words to step 2 as arguments, and main() keeps the last positional, so the launch retargeted to ./launches."

**Location:** commit 980a9db4 body (A1)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the word passing and the last-positional rule. It does not establish a working retarget: "./launches" is resolved, and the launch errors out unless that directory exists inside a git repo.

Same evidence as Claim 9: R3 (`$S/zsh-probe.log`) and R4, which printed `ERROR: not a directory: launches` with exit 1 (`$S/lastpos.log`), from `cc-isolated.sh:356-358`. A more precise wording: "step 2 targeted ./launches, which errors unless it exists".

**Evidence:** `devcontainer-config/cc-isolated.sh:757`, `devcontainer-config/cc-isolated.sh:355-368`, `$S/zsh-probe.log`, `$S/lastpos.log`

---

## Claim 15: "In the fail-closed state the receipt is missing and the hash matches, so it does not [rebuild] ... They now say the container is recreated if it was built from another config. The fail-closed launch test asserts it."

**Location:** commit 980a9db4 body (A2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the NOTE case: the NOTE prints only when the receipt is missing (`is_verified_live` false), and in that case a matching hash means no recreate. It does not establish a fail-closed state where the receipt is present (no NOTE then). "Asserts it" means the negative assertion of Claim 11, not a positive match on the new text.

`if ! is_verified_live; then echo "NOTE: ..."` (`cc-isolated.sh:880`), and the recreate is gated on `! container_config_matches` (`:902`). The NOTE, header and guide-row edits are in the diff (Claims 2, 6, 8). The test assertion is Claim 11.

**Evidence:** `devcontainer-config/cc-isolated.sh:104-109`, `devcontainer-config/cc-isolated.sh:880-905`, `test/cc-isolated-functions.bats:1404-1407`

---

## Claim 16: "C1, C2 (api F3, F4): the --list "Next:" line and guide :841 say recreates."

**Location:** commit 980a9db4 body (C1, C2)
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers both edits being present. It does not support the "--list" attribution: the edited "Next:" line is printed by bless_manifest, not by --list.

`grep -n 'Next:' cc-isolated.sh` returns only `:317`, inside `bless_manifest()` (`:282-322`). bless_manifest runs on `--bless` (`:796`), at the end of `--register` (`register_project`, `:477`) and from install.sh (`install.sh:607`, `"$DEST/cc-isolated.sh" --bless`). `list_projects()` (`:482-533`, read in full) prints its own hint with no verb: `echo "Blessed config $b — verified live: NO (run: cc-isolated --probe-only <repo>)"` (`:488`). The rubric's C1 row reads "`--bless`/`--list` "Next:" line", which is where the label comes from. Precise: "the --bless/--register "Next:" line".

**Evidence:** `devcontainer-config/cc-isolated.sh:282-322`, `devcontainer-config/cc-isolated.sh:477`, `devcontainer-config/cc-isolated.sh:482-533`, `devcontainer-config/install.sh:607`, `guides/cc-isolated-usage.md:841`

---

## Claim 17: "C3 (security #2): new test, --probe-only exits non-zero and starts no session when the probe fails (the property the hint's `&&` relies on)."

**Location:** commit 980a9db4 body (C3)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test's existence and sensitivity (Claim 13). It does not establish the `&&`'s behaviour in every shell, though `&&` short-circuits on non-zero in both bash and zsh.

See Claim 13 (R5 mutant caught).

**Evidence:** `test/cc-isolated-functions.bats:1426-1443`, `$S/bats-mutant-probe-swallowed.log`

---

## Claim 18: "A4 ... correcting cb56299c's Notes: the guide row quotes the "Blessed config changed ..." line only up to "rebuilding", not verbatim; and the one-time recreate on each project's next launch is caused by the blessed hash changing after the bless (both scripts are in the manifest), while init-firewall.sh being baked is why its new text reaches a container only through that recreate."

**Location:** commit 980a9db4 body (A4)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the quote extent, both scripts being manifest entries, and init-firewall.sh being COPY'd into the image. It does not establish Docker layer-cache behaviour on the recreate.

The guide row reads `` `Blessed config changed since this container was built — rebuilding` `` (`guides/cc-isolated-usage.md:956`). The code prints `"Blessed config changed since this container was built — rebuilding it."` (`cc-isolated.sh:903`). `enforcement_files()` lists `echo "init-firewall.sh"` and `echo "cc-isolated.sh"` (`cc-isolated.sh:132-137`). `blessed_hash` is `sha256sum < "$m" | cut -c1-16` over that manifest (`:89-94`). A change to either file therefore changes the hash, `container_config_matches` fails, and the next launch recreates. The Dockerfile has `COPY init-firewall.sh /usr/local/bin/` (`Dockerfile:487`).

**Evidence:** `guides/cc-isolated-usage.md:956`, `devcontainer-config/cc-isolated.sh:89-94`, `devcontainer-config/cc-isolated.sh:129-152`, `devcontainer-config/cc-isolated.sh:903`, `devcontainer-config/Dockerfile:487`

---

## Claim 19: "Still message text, comments, guide prose and tests; no iptables call, probe check, recreate decision or exit status changed."

**Location:** commit 980a9db4 body (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every non-test file in the diff (cc-isolated.sh: only `#` and `echo` lines changed; guide: prose). It does not establish anything about init-firewall.sh, which this commit does not touch.

R6 filtered the cc-isolated.sh diff to changed lines that are neither comments nor `echo` and found nothing (`$S/non-comment-diff.log`, 0 bytes). The diff stat lists only cc-isolated.sh, the guide, the bats file and docs/reviews.

**Evidence:** `$S/non-comment-diff.log`, `git diff --stat cb56299c..980a9db4`

---

## Claim 20: ""rebuild" stays where the image really is rebuilt (--register's note, the re-bless notes) and in the "Blessed config changed ... rebuilding it." line, which a guide row and a test match."

**Location:** commit 980a9db4 body (Notes)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the named user-facing uses. It does not establish actual Docker image rebuilding: a changed build arg forces the layers after it to be rebuilt, but this was not run. Uses not named are left: comments at `:39`, `:535`, `:680`, `:899` and the message at `:922`. Those are accurate in their own sense ("never rebuilds" describes `devcontainer up`; `:922` means rebuilding iptables rules) except `:535`'s comment "The rebuild instruction printed by …", which names the function, not a rebuild.

`--register` writes a profile under `projects/`, which `enforcement_files` hashes (`:140-147`), and re-blesses (`:477`). The next launch's recreate passes the new `CC_EGRESS_PROFILE`/`CC_CONFIG_HASH` as build args (`devcontainer.json:50,54`; `Dockerfile:478,484`), so the image is rebuilt from those ARGs on. The re-bless note "causes no rebuild" (`:766`) applies when only host tools changed, which are hashed separately in host-tools.sha256 (`:200-218`), so blessed_hash and the container are unchanged. The test is `[[ "$output" == *"Blessed config changed since this container was built"* ]]` (`test/cc-isolated-functions.bats:1359`). The guide row is `:956` (Claim 18). Full grep: `$S/rebuild-grep.log`.

**Evidence:** `devcontainer-config/cc-isolated.sh:129-152`, `devcontainer-config/cc-isolated.sh:200-218`, `devcontainer-config/cc-isolated.sh:477-479`, `devcontainer-config/cc-isolated.sh:766-768`, `devcontainer-config/devcontainer.json:50-54`, `devcontainer-config/Dockerfile:478-484`, `test/cc-isolated-functions.bats:1359`, `$S/rebuild-grep.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 9** (`test/cc-isolated-functions.bats:357-358`): "retargeting the launch" overstates the outcome. The last positional ("launches") wins, but resolve_workspace errors out unless ./launches exists in a git repo.
- **Claim 14** (commit 980a9db4, A1): same point. "the launch retargeted to ./launches" is in practice `ERROR: not a directory: launches`.
- **Claim 16** (commit 980a9db4, C1): the "Next:" line is printed by `bless_manifest` (--bless, --register, install.sh), not by `--list`.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): a code-fact-check report saved at that path, structured per the skill, verdicting at least the claims listed above.
- Answered: yes. Focus 1 → Claims 4, 5, 9, 14. Focus 2 → Claims 1, 2, 3, 6. Focus 3 → Claims 7, 8. Focus 4 → Claims 10-13. Focus 5 → Claims 15-20. The behavioural ones were executed against the stubbed launcher, including a cb56299c-scripts run and a mutation check of the new --probe-only test.
- Iteration-1 items: A1, A2, A3, C1, C2, C3 and C6 are resolved in the code and tests. A4's correction is accurate (Claim 18).
- Out of scope: real Docker behaviour (stopped-container restart, layer-cache rebuild extent) and zsh under user rc files.
- Escalate: none blocking. The three Mostly-accurate items are wording in a test comment and the commit body. None changes behaviour or a test's power.
- Decisions I made: I verdicted the NOTE (Claim 6) Verified although it understates --probe-only's unconditional recreate, because the conditional stays true and the header paragraph says "--probe-only always recreates". I treated the trivially true "starts no session" assertion in the new test as Scope residue rather than a downgrade, because the R5 mutant shows the exit-status assertion carries the test.
