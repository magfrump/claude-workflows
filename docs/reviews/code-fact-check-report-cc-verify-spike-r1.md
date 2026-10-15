**Commit:** 190fa1a4

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-branch-verify (branch `docs/branch-verify-without-install`, HEAD 190fa1a4)
**Scope:** `docs/working/spike-cc-verify-q117.md` at 190fa1a4 (`git diff main...HEAD -- docs/working/spike-cc-verify-q117.md`), including its embedded script (byte-identical to `spike-q117.v2.sh`, confirmed with `cmp`), plus the commit messages of 12fcb61c and 190fa1a4. Iteration 2, replicate k=3 (final confirming pass, decision log 63).
**Checked:** 2026-10-15
**Total claims checked:** 36
**Summary:** 26 verified, 6 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read before checking. None of the five logged patterns (specific measured values quoted from an artifact set that does not hold them; a file-to-symbol association asserted without grepping) matches a claim here. The doc's measured values (tree `65e65962…`, install.sh larger than a pipe buffer, the line citations) were all recomputed and hold.

**Execution provenance (applies to every `executed` claim).** Scratch dir `S=/home/node/.claude/jobs/00bcf178/tmp/fc2r1.Vni4`. The harness was copied, not run in place: `S/setup.sh` is `setup-t.sh` with `B=$S`, `T=$S/t` and the v2 script as the source; `S/run.sh` and `S/run2.sh` run the script under `timeout 300` in the fake HOME. `S/bin2/devcontainer` is a wrapper I wrote over the stub (it adds `FAKE_UP_RC`, `FAKE_EXEC_RC`, `FAKE_FORGE`, `FAKE_SLEEP` and logs the credential variables seen by `up`). `S/tripwire.sh` and `S/clonecheck.sh` are my probes. Every command ran with cwd `S` unless noted. Each captured log starts with its UTC start timestamp, and most end with `rc=<n>`. Neither `t1/` nor the v2 script was modified. Every process I started has been killed or has exited (`ps -ef | grep -c fc2r1.Vni4` gives 0). One crash attempt (`logs/crash.out`) was invalid: I killed the `timeout` wrapper instead of the script, and then killed the orphaned script by PID. `logs/crash2*.out` is the valid repetition. Nothing was run with docker, devcontainer, install.sh or cc-isolated for real. git is 2.39.5.

---

## Claim 1: "Task status: paused (paste written; review loop iteration 2 passed; nothing has run on the host)"

**Location:** `docs/working/spike-cc-verify-q117.md:5`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether iteration 2 had passed as of commit 190fa1a4; does not establish the outcome of the iteration 2 now running, which this report is one replicate of.
**Legibility-target:** for-author

The commit that wrote this line says iteration 2 had not yet run. From `git log -1 --format=%B 190fa1a4`: `Nothing ran on the host. Iteration 2 (the final confirming pass) follows.` The only rubric on the branch is iteration 1's, and it reads `**Status: 🔴 DOES NOT PASS** — 5 red item(s) unresolved (iteration 1; fixes follow in the next commit)` (`docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md:6`). No iteration-2 artifact exists in `docs/reviews/` at 190fa1a4 (paraphrased — no quote available because the claim concerns the absence of files; `ls docs/reviews | rg cc-verify` lists only the three iteration-1 files). The phrase "nothing has run on the host" is accurate. Fix: say "iteration 2 pending", or update the line once iteration 2 actually passes.

**Evidence:** `docs/working/spike-cc-verify-q117.md:5`, `docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md:6`, commit 190fa1a4 message

---

## Claim 2: "Last verified: 2026-10-15 against main b279a2ba and `fix/egress-dnsmasq-ipset` b26d4b8b23aa (pinned in the paste); their merge tree is `65e65962b12e…`."

**Location:** `docs/working/spike-cc-verify-q117.md:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two ref values, the pinned SHA and the merge-tree id today; does not establish that the refs stay put (the paste refuses if the branch moves, see Claim 15).
**Legibility-target:** for-orchestrator-synthesis

`git rev-parse fix/egress-dnsmasq-ipset main` printed `b26d4b8b23aa05130bc9340c0c4c81ecba75897f` and `b279a2ba2a8f…`. The script pins `EXPECT_BR=b26d4b8b23aa05130bc9340c0c4c81ecba75897f` (script line 64 of the paste, `docs/working/spike-cc-verify-q117.md:64`). The harness pass run printed `merged tree=65e65962b12e40d59c586aa429e580388e051cd9`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:7,64`; command `./run.sh $S/t/home/claude-workflows`, cwd S, 2026-10-15T09:08:30Z, exit 0; output `S/logs/pass.out`

---

## Claim 3: The "Created / Removed by" table (clone, stage, workspace, container, two volumes, image, run record "holding only `RUN=` and `T8=`", removed "last, and only when every removal succeeded"; log kept)

**Location:** `docs/working/spike-cc-verify-q117.md:15-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the trap path on pass, fail, interrupt and refusal runs, and `--clean` after a kill -9; does not establish the `--clean` image rule when the before snapshot is gone (Claim 12) or the tag rule against non-verify images (Claim 11).
**Legibility-target:** for-orchestrator-synthesis

The run record gets exactly two writes: `printf 'RUN=%s\n' "$RUN" > "$V/run-$RUN.env"` and `printf 'T8=%s\n' "$T8" >> "$V/run-$RUN.env"` (doc:230, :267). It is removed last and only on success: `if [ "$fail" = 0 ]; then rm -f -- "$V/run-$RUN.env"; fi` (doc:129, inside `teardown()` at doc:98-132, read in full). Executed: after the pass, fail, no-rotation, exec-failure, up-failure, forged-output and TERM runs, `~/cc-verify` held only `spike-q117.sh` and `log-*.txt`. The fake docker state held only the harness's container, volume and image.

**Evidence:** `docs/working/spike-cc-verify-q117.md:98-132,229-231,266-267`; outputs `S/logs/pass.out`, `fails3.out`, `norot.out`, `execfail.out`, `upfail.out`, `forge.out`, `term.out` (commands `[env FAKE_*=…] ./run2.sh $V $W`, cwd S, 09:11:53Z-09:14:18Z, exits as recorded in each log)

---

## Claim 4: "What the run checks at runtime (the `CHECK` lines). It compares, before and after: a hash over every file in `~/.config/claude-devcontainer`; the hashes of `manifest.sha256`, `host-tools.sha256` and `verified-live.sha256`; where `~/.local/bin/cc-isolated` and `cc-push` point; every container, volume and image tag that existed before the run."

**Location:** `docs/working/spike-cc-verify-q117.md:26-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `snapshot()`/`compare()` record and compare; does not establish detection of directory-only or mode-only changes in the config dir, or of untagged (`<none>:<none>`) pre-existing images, which `compare()` filters out on purpose.
**Legibility-target:** for-orchestrator-synthesis

```bash
# docs/working/spike-cc-verify-q117.md:141-146
  for f in manifest.sha256 host-tools.sha256 verified-live.sha256; do
    if [ -e "$MAIN_CFG/$f" ]; then sha256sum < "$MAIN_CFG/$f" | sed "s|-\$|$f|" >> "$d/main"
  ...
  for f in cc-isolated cc-push; do echo "$f -> $(readlink -f "$MAIN_BIN/$f" 2>/dev/null || echo absent)" >> "$d/main"; done
  echo "config tree $( (cd "$MAIN_CFG" && find . \( -type f -o -type l \) -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) | sha256sum)" >> "$d/main"
```
(excerpt ends :146; enclosing `snapshot()` ends :147 — read). `compare()` (doc:149-171) uses `comm -23` on the container, volume and image lists to find pre-existing entries that disappeared. The image list is filtered with `grep -v '^<none>:<none> '` (doc:160). Every CHECK printed `ok` on the pass run, and the harness's pre-existing objects survived.

**Evidence:** `docs/working/spike-cc-verify-q117.md:134-171`; `S/logs/pass.out`

---

## Claim 5: "What holds by construction, not by a check. No command in the script writes `~/.claude` or your checkout's working tree. Its only operations on the checkout are `git rev-parse` and a `git clone` *from* it. It runs no branch code on the host. It needs no session to close: there is no install, so install.sh's agent gate never runs."

**Location:** `docs/working/spike-cc-verify-q117.md:34`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the script's own commands and main's launcher (current and pre-Q-089) run against a stage with tripwires in every host-side staged file; does not establish what the real devcontainer CLI writes on the host (its own temp and cache dirs), or what a filter or merge driver in the user's global gitconfig does (listed as a residual at doc:515).
**Legibility-target:** for-orchestrator-synthesis

The script touches the checkout in exactly two places: `REPO_TOP="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)"` (doc:221) and `git -c core.hooksPath=/dev/null clone -q --bare --no-local --template= -- "$REPO_TOP" "$SRCGIT"` (doc:238). No line of the script names `.claude` (paraphrased — no quote available because the claim covers the absence of code; a search of the extracted script `S/doc.sh` finds no `.claude` path). It never invokes install.sh. Executed: `S/tripwire.sh` put a top-level `touch`/`open` tripwire into each of the stage's `cc-isolated.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`, `cc-push.sh`, `init-firewall.sh`, `link-claude-home.sh` and `cc-sni-proxy.py`. It then ran main's launcher with `--register` and `--probe-only` against that stage. Result for both launchers: `tripwires hit: none` and `written outside the stage (excluding dstate and the workspace): none`. The run is in the fake HOME, with the fake CLI.

**Evidence:** `docs/working/spike-cc-verify-q117.md:221,238`; commands `./tripwire.sh main cur` and `./tripwire.sh 626dc300^1 preq089`, cwd S, 2026-10-15T09:10:22Z, exit 0; outputs `S/logs/tripwire-cur.out`, `S/logs/tripwire-preq089.out`

---

## Claim 6: "The block holds no shell comments outside the script, so it pastes the same into bash and zsh."

**Location:** `docs/working/spike-cc-verify-q117.md:38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash, `zsh -f` and interactive `zsh -i` (fresh ZDOTDIR), each reproducing the script byte for byte; does not establish behaviour under a user's own zsh rc (e.g. a paste-bracketing plugin).
**Legibility-target:** for-orchestrator-synthesis

The only lines outside the heredoc are `mkdir -p ~/cc-verify && cat > ~/cc-verify/spike-q117.sh <<'CCVERIFY'`, `CCVERIFY` and `bash ~/cc-verify/spike-q117.sh ~/claude-workflows` (doc:41, :394, :395). The paste minus its last line, run with `HOME=<scratch>`, gave `bash round-trip identical` and `zsh -f round-trip identical`. The full paste through `env -u CLAUDECODE ... zsh -i < paste.txt` wrote an identical script and reached the preflight (`REFUSED: 'docker' not found on PATH.`).

**Evidence:** `docs/working/spike-cc-verify-q117.md:41,394-395`; outputs `S/logs/zsh-i.out` (09:16:07Z, rc=1 = the preflight refusal); the bash and zsh -f round-trips ran inline (`cmp` exit 0)

---

## Claim 7: "Opt-in credentials devcontainer.json forwards from this shell (devcontainer.json, "GH_TOKEN" and "OPENROUTER_API_KEY" in containerEnv) never reach a container running branch code." / table: "devcontainer.json forwards both from the launching shell into the container (`containerEnv`)."

**Location:** `docs/working/spike-cc-verify-q117.md:53-55,459`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two `${localEnv:…}` credentials in `containerEnv` and the environment the launcher's `devcontainer up` sees; does not establish what the real devcontainer CLI forwards by other routes (e.g. git credential helpers), which is outside devcontainer.json.
**Legibility-target:** for-orchestrator-synthesis

`"OPENROUTER_API_KEY": "${localEnv:OPENROUTER_API_KEY}"` (`devcontainer-config/devcontainer.json:116`) and `"GH_TOKEN": "${localEnv:GH_TOKEN}"` (`:131`) are the only credential reads in `containerEnv`. The script runs `unset GH_TOKEN OPENROUTER_API_KEY` (doc:55) before anything else, and the launcher never sets them (paraphrased — no quote available because the claim covers absence: `GH_TOKEN` occurs in cc-isolated.sh only in the comment at :550). Executed: with `GH_TOKEN=s3cret OPENROUTER_API_KEY=k3y` exported, the wrapper logged `up: GH_TOKEN=unset OPENROUTER_API_KEY=unset`.

**Evidence:** `devcontainer-config/devcontainer.json:82-132`, `devcontainer-config/cc-isolated.sh:550`, `docs/working/spike-cc-verify-q117.md:55`; command `GH_TOKEN=s3cret OPENROUTER_API_KEY=k3y ./run2.sh $V $W`, cwd S, 2026-10-15T09:14:49Z, exit 0; outputs `S/logs/envlog.out`, `S/logs/cred.out`

---

## Claim 8: "relay: vis, then show each line indented under "  | " on stderr ... and pass it unindented on stdout." Plus the table row on output filtering: "control bytes (all but tab and newline) are dropped, and each line is shown under `  | `"; the `| relay >> "$LOG"` and `$(… | relay)` forms keep failure detection

**Location:** `docs/working/spike-cc-verify-q117.md:82-87,480`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers C0/DEL stripping, the indentation of step 7-8 output, verdict parsing of the unindented copy, and pipefail propagation of launcher and exec failures through `relay`; does not establish C1 bytes (left in on purpose, residual at doc:516) or the paths that bypass relay (Claim 9).
**Legibility-target:** for-orchestrator-synthesis

```bash
# docs/working/spike-cc-verify-q117.md:84,87
vis() { LC_ALL=C tr -d '\000-\010\013-\037\177'; }
relay() { local l; vis | while IFS= read -r l || [ -n "$l" ]; do printf '  | %s\n' "$l" >&2; printf '%s\n' "$l"; done; }
```
The deleted ranges leave out exactly \011 (tab) and \012 (newline). `set -euo pipefail` (doc:52) applies to `"$LAUNCHER" --probe-only … 2>&1 | relay >> "$LOG" || die` (doc:344-345) and to `out="$(devcontainer exec … 2>&1 | relay)" || die` (doc:373-375). In both, the pipeline's status is the launcher's or the exec's, because relay's `while` exits 0 at EOF. Executed: `FAKE_UP_RC=5` gave `REFUSED: --probe-only failed`, rc 1. `FAKE_EXEC_RC=7` gave `REFUSED: devcontainer exec of the Q-117 block failed.`, rc 1. `FAKE_FORGE=1` showed `  | RESULT Q-117 pass (forged)` and `  | ]52;c;Zm9v[2Jfetch 1 (expect 200): 200CHECK forged`, with no ESC or CR byte left in the log. The real verdict `RESULT Q-117 pass (tree 65e65962…)` followed, and the pass run's verdict was parsed from the unindented copy.

**Evidence:** `docs/working/spike-cc-verify-q117.md:52,84-87,343-345,373-375`; outputs `S/logs/upfail.out` (09:12:03Z), `S/logs/execfail.out` (09:12:00Z), `S/logs/forge.out` (09:12:05Z), each from `env FAKE_…=… ./run2.sh $V $W`, cwd S

---

## Claim 9: "Every line the launcher or the container prints is shown indented under `  | `, with control bytes removed. So only the script's own lines can start with `RESULT`, `CHECK` or `REFUSED`."

**Location:** `docs/working/spike-cc-verify-q117.md:402`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every place the script prints launcher, git or container output; does not establish that any of the unindented paths carries branch-controlled text today (under the five-path rule and the pins it is main's text, or a reviewed path name).
**Legibility-target:** for-author

The claim holds for steps 7-8, which go through `relay`. On the `--register` failure path, the launcher's output reaches the terminal unindented: `|| { tail -n 20 "$LOG" | vis >&2; die "--register failed (log above)."; }` (doc:331). The merge-tree conflict listing (doc:249-250, `printf '%s\n' "$mt" | vis >&2`) and the step-3 `diff -u … | vis` (doc:301) are also unindented. Those two are git's and diff's output, not the launcher's, and diff lines start with `+`, `-` or a space. On each of these paths a `REFUSED:` line and `RESULT spike-q117 exit=1` follow. The precise version: "Every line the launcher prints during steps 7-8, and every line the container prints, is shown indented. On a refusal, git, diff and launcher output above the `REFUSED:` line is shown with control bytes removed but not indented."

**Evidence:** `docs/working/spike-cc-verify-q117.md:249-250,301,330-331,343-345,373-375`

---

## Claim 10: "Everything is derived from RUN and T8 (format-checked); no path, project id or image id is read from a file. The project id is the hash of ~/cc-verify/VERIFY-<T8>, a path only this script creates, so no run record can name another project's container or volume."

**Location:** `docs/working/spike-cc-verify-q117.md:91-93` (script comment, script lines 91-93)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers containers, volumes and paths under `--clean` with planted records; does not cover images (Claims 11-12), or a user who has their own project at `~/cc-verify/VERIFY-<8 hex>`.
**Legibility-target:** for-orchestrator-synthesis

`--clean` reads only `RUN` and `T8`, through anchored seds: `sed -n 's/^RUN=\([0-9]*-[0-9]*\)$/\1/p'` and `sed -n 's/^T8=\([0-9a-f]\{8\}\)$/\1/p'` (doc:199-200). `verify_pid()` hashes `"$VP/VERIFY-$1"` (doc:96). Executed: a planted `run-1-1.env` with `PID=aaaaaaaaaaaa`, `IMG=sha256:aaa9…` (the harness's container and image) and `WS=/home` cleaned `project 216985e46782`. The harness container `charness111`, volume `cc-aaaaaaaaaaaa-claude-config` and image `sha256:aaa9…` all survived.

**Evidence:** `docs/working/spike-cc-verify-q117.md:94-97,191-207`; command `./run.sh --clean`, cwd S, 2026-10-15T09:12:24Z, exit 0; output `S/logs/planted.out`

---

## Claim 11: "A planted `run-*.env` can name only a `VERIFY-<8 hex>` path under `~/cc-verify`, and only this script creates those. It cannot point `docker rm` or `volume rm` at another project, or `image rm` at an image no verify container ran (... reproduced before the fix, re-tested after)."

**Location:** `docs/working/spike-cc-verify-q117.md:482`
**Type:** Invariant / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `image rm` part through the `verify-<T8>` tag rule (the `docker rm`/`volume rm` part is Verified in Claim 10); does not establish how likely a matching tag is on a real host, or whether anything that can write `~/cc-verify` exists there.
**Legibility-target:** for-author

The tag rule removes any image whose lower-cased tag contains `verify-<T8>` as a substring, whether or not a verify container ran it:

```bash
# docs/working/spike-cc-verify-q117.md:121-124
    while read -r i tags; do
      [ -n "$i" ] || continue
      case "$tags" in *verify-"$T8"*) docker image rm -f "$i" >/dev/null </dev/null || fail=1 ;; esac
    done < <(docker image ls --no-trunc --format '{{.ID}} {{.Repository}}:{{.Tag}}' </dev/null | tr 'A-Z' 'a-z')
```
(excerpt is inside `teardown()`, doc:98-132 — read). A planted record chooses `T8`, which can be any 8 hex characters, including all-digit values. Executed: I added two images that no verify container ran, `vsc-verify-20261015-5f3a:latest` (the tag the CLI would give a project folder named `verify-20261015`) and `other/Project-VERIFY-DEADBEEF-tools:1.0`. With records `RUN=2-2/T8=20261015` and `RUN=1-1/T8=deadbeef`, `--clean` exited 0. The call log shows `docker image rm -f sha256:3e23e816…` and `docker image rm -f sha256:2e7d2c03…`, and both images were gone. The doc's own sentence "can also remove an image left by an earlier crashed run of the same tree" names only the benign case. Fix: state the real bound (an image whose tag contains `verify-<8 hex>`), or narrow the rule, for example to the CLI's `vsc-verify-<T8>-` prefix.

**Evidence:** `docs/working/spike-cc-verify-q117.md:119-124,482`; command `./run.sh --clean` after planting, cwd S, 2026-10-15T09:12:24Z, exit 0; output `S/logs/planted.out`, call log `S/t/dstate/calls`

---

## Claim 12: "Removes the label's containers, then the two named volumes, then the containers' images (only if new and unused), then images tagged `verify-<TREE8>` ..." (trap / `--clean` row)

**Location:** `docs/working/spike-cc-verify-q117.md:482`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "only if new" qualifier under `--clean`; does not establish how often a verify container runs an image that existed before the run (the Dockerfile tail bakes a per-stage hash, so it should be rare).
**Legibility-target:** for-author

The script's own comment carries the qualifier the doc row drops: `removed only if it was not present before the run (when the before snapshot exists)` (doc:112-113). The code is `if [ -f "$V/snap-$RUN-before/images" ] && grep -q " $img\$" …; then continue; fi` (doc:115). With no snapshot, "new" is never checked. `compare()` deletes both snapshots unconditionally (`rm -rf -- "$b" "$a"`, doc:169), and `on_exit` calls it even when teardown failed (doc:178-179). So the `--clean` that the failure message tells the user to run has no snapshot. Executed: I recreated that state (a `cc-project=975999043c91` container running a pre-existing `vsc-other-project-1:latest` image, a run record, no snapshot), and `--clean` removed the pre-existing image. The precise version: "only if new (when the before snapshot still exists) and unused".

**Evidence:** `docs/working/spike-cc-verify-q117.md:112-118,169,173-188`; command `./run.sh --clean`, cwd S, 2026-10-15T09:17:00Z, exit 0; output `S/logs/clean-nosnap.out`

---

## Claim 13: Preflight row: "`CLAUDECODE` mirrors install.sh's target-2 rule (decision 037). An inherited `CLAUDE_DEVC_CONFIG_DIR` would change which config is "main's" (cc-isolated.sh:68-70)." / "install.sh links it there (install.sh:598, defaults :1310-1311)."

**Location:** `docs/working/spike-cc-verify-q117.md:460-462`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited lines and the leftover-run refusal; does not establish install.sh's process-based agent gate, which this spike does not mirror (the doc says so at :518).
**Legibility-target:** for-orchestrator-synthesis

`echo "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"` (`devcontainer-config/cc-isolated.sh:69`, inside `config_dir()` :68-70). `ln -sf "$DEST/cc-isolated.sh" "$BIN_DIR/cc-isolated"` (`devcontainer-config/install.sh:598`). `DEST="${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"` and `BIN_DIR="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"` (`install.sh:1310-1311`). `if [ -n "${CLAUDECODE:-}" ]; then echo "Skipped host target (~/.claude): …"` (`install.sh:779-780`). A leftover record refuses (executed in Claim 33).

**Evidence:** `devcontainer-config/cc-isolated.sh:68-70`, `devcontainer-config/install.sh:598,779-780,1310-1311`, `docs/decisions/037*.md:33`

---

## Claim 14: Step 1 row: the bare clone with `--template=` "copies objects and refs: no `.git/config` filters or merge drivers, no `info/attributes`, no hooks ... The flags match `repo_git` (install.sh:180-182)"; git_state_gate at install.sh:209-252; step 4 clone "`--no-local --template=` (hooks and fsmonitor off)"

**Location:** `docs/working/spike-cc-verify-q117.md:463,471`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a local filter, `info/attributes` and a post-checkout hook planted in the checkout; does not establish global or system gitconfig filters (residual at doc:515).
**Legibility-target:** for-orchestrator-synthesis

`git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"` (`install.sh:181`, `repo_git()` :180-182) has the same flags as the script's `G=(git --no-optional-locks -C "$SRCGIT" -c core.hooksPath=/dev/null -c core.fsmonitor=false)` (doc:239). `git_state_gate()` spans `install.sh:209-252`. Executed: `S/clonecheck.sh` planted `filter.evil.clean`/`smudge`, `info/attributes` (`* filter=evil`) and an executable `hooks/post-checkout` in the harness checkout, ran the script's two clone commands, then removed the plants. Result: `bare hooks entries: 0; bare info:` (empty), `ws hooks entries: 0`, a bare config with no filter key, and no marker files.

**Evidence:** `devcontainer-config/install.sh:180-182,209-252`, `docs/working/spike-cc-verify-q117.md:238-239,314`; command `timeout 60 bash S/clonecheck.sh`, cwd S, 2026-10-15T09:15:12Z, exit 0; output `S/logs/clonecheck.out`

---

## Claim 15: "the branch must resolve to the reviewed commit `b26d4b8b23aa…` (`EXPECT_BR`)" ... "A ref moved in the checkout's `.git` ... refuses the run"

**Location:** `docs/working/spike-cc-verify-q117.md:464`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch ref; does not cover `main`, which is still resolved by name (stated at :466 and :513).
**Legibility-target:** for-orchestrator-synthesis

`[ "$BR_SHA" = "$EXPECT_BR" ] || die "$BRANCH is at $BR_SHA, not the reviewed $EXPECT_BR. …"` (doc:242). Executed: I moved the harness branch to a child commit, and the run refused with `REFUSED: fix/egress-dnsmasq-ipset is at ba5b91f8…, not the reviewed b26d4b8b23aa…`, rc 1.

**Evidence:** `docs/working/spike-cc-verify-q117.md:242`; command `./run2.sh $V $W`, cwd S, 2026-10-15T09:12:36Z, rc 1; output `S/logs/moved.out`

---

## Claim 16: "`git merge-tree --write-tree --name-only main <branch>`: exit 1 refuses and lists the conflicts ... Verified in the sandbox: today the merge is clean (tree `65e65962…`, the same tree a real `git merge` produces), and `feat/q125-cc-isolated-sandbox` is refused on `hooks/live-verify-gate.sh`."

**Location:** `docs/working/spike-cc-verify-q117.md:465`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the clean merge, its equality with a real merge and the q125 conflict; does not establish the "needs git ≥ 2.38" path on an older git (listed as Not verified #5).
**Legibility-target:** for-orchestrator-synthesis

A real `git merge` of `origin/fix/egress-dnsmasq-ipset` into `origin/main`, in a scratch clone, gave `HEAD^{tree}` = `65e65962b12e40d59c586aa429e580388e051cd9`. A script copy with `BRANCH=feat/q125-cc-isolated-sandbox` and its own `EXPECT_BR` printed `CONFLICT (content): Merge conflict in hooks/live-verify-gate.sh` and `REFUSED: feat/q125-cc-isolated-sandbox does not merge cleanly with main`. The docker call log held only `docker info`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:243-253`; command `./run2.sh $S/spike-q125.sh $W`, cwd S, 2026-10-15T09:15:35Z, rc 1; output `S/logs/conflict.out`; scratch merge in `S/mg` (inline, exit 0)

---

## Claim 17: "`git diff-tree -r --name-only <main> <tree>` may list only the branch's five paths"

**Location:** `docs/working/spike-cc-verify-q117.md:466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an extra path added by the branch, and the five listed paths against the branch's real diff; does not cover paths git C-quotes (those fail `grep -qxF` and refuse, which is the safe direction).
**Legibility-target:** for-orchestrator-synthesis

`git diff --name-only main...fix/egress-dnsmasq-ipset` lists exactly the five `BRANCH_PATHS` (doc:66-70). The check is `grep -qxF -- "$f" <<< "$BRANCH_PATHS" || die "the merge changes …"` (doc:258). Executed: with a branch commit adding a `README.md` change and `EXPECT_BR` set to it, the run refused with `REFUSED: the merge changes README.md, which is not one of the branch's reviewed paths.`

**Evidence:** `docs/working/spike-cc-verify-q117.md:66-70,255-259`; command `./run2.sh $S/spike-extra.sh $W`, cwd S, 2026-10-15T09:12:37Z, rc 1; output `S/logs/extrapath.out`

---

## Claim 18: "install.sh:110 and :135. The variable avoids SIGPIPE: install.sh is larger than a pipe buffer, and the review reproduced spurious refusals with the pipe"

**Location:** `docs/working/spike-cc-verify-q117.md:467`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the PAYLOAD and CLAUDE_HOME_SRC lines in the merged tree and the two forms under pipefail on this machine; does not establish the failure rate on the host kernel.
**Legibility-target:** for-orchestrator-synthesis

`install.sh:110` is `PAYLOAD=(devcontainer.json Dockerfile … egress claude-home)` and `:135` is `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`. Both equal the script's `EXPECT_PAYLOAD`/`EXPECT_HOME_SRC` (doc:76-77). The merged tree's install.sh is 65,632 bytes, more than 65,536. Executed under `set -euo pipefail`, 50 trials each: `pipe form failures: 50/50; variable form failures: 0/50`.

**Evidence:** `devcontainer-config/install.sh:110,135`, `docs/working/spike-cc-verify-q117.md:271-277`; command `timeout 120 bash sigpipe.sh`, cwd S, 2026-10-15T09:11:35Z, exit 0; output `S/logs/sigpipe.out`

---

## Claim 19: "The same sources and the same no-symlink rule as `extract_commit` (install.sh:257-317, the symlink refusal at :288)."

**Location:** `docs/working/spike-cc-verify-q117.md:468`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sources and the symlink refusal; does not establish full equivalence with `extract_commit`, which also refuses NUL-byte files (install.sh:298-316) and fixes modes (`tar.umask=022`, `tar -p`, :276-280). The spike does neither, and the doc does not claim it does.
**Legibility-target:** for-orchestrator-synthesis

`extract_commit()` spans `install.sh:257-317`. Its symlink block begins with the comment `# No symlinks (review R1).` at :288 and refuses at :292-297. The script runs `[ -z "$(find "$S.raw" -type l -print -quit)" ] || die "the merged tree holds symlinks …"` (doc:281).

**Evidence:** `devcontainer-config/install.sh:257-317`, `docs/working/spike-cc-verify-q117.md:278-281`

---

## Claim 20: Layout row: "Matches `install_devcontainer` (install.sh:471-508), `assemble`'s `.manifest` keys (:356-361) and install.sh:596. The Dockerfile copies `claude-home/` (Dockerfile:500), `egress/` (:486) and the scripts (:487-491) from the build context, which is `CC_CONFIG_DIR` (devcontainer.json:24-26)."

**Location:** `docs/working/spike-cc-verify-q117.md:469`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cited lines and the keys of `.manifest`; does not establish that the values match (the spike writes `commit=<tree id>`, which matters for Claim 30).
**Legibility-target:** for-orchestrator-synthesis

`install_devcontainer() {` starts at `install.sh:471`, and its staging runs to the claude-home mirror at :508. `.manifest` gets `commit=`, `dirty=no`, `uncommitted_excluded=` and `assembled_from=` (`install.sh:357-360`). `chmod +x "$DEST/cc-isolated.sh" "$DEST/cc-push.sh" "$DEST/init-firewall.sh"` (`install.sh:596`). `COPY egress/ /usr/local/share/cc-egress/` (Dockerfile:486), `COPY init-firewall.sh` … `COPY link-claude-home.sh` (:487-491), `COPY claude-home/ /opt/claude-workflows/` (:500). `"dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile", "context": "${localEnv:CC_CONFIG_DIR}"` (devcontainer.json:25-26). Executed: main's real launcher blessed and probed the stage the script built (`stage blessed: config db0c142dfebce641`).

**Evidence:** `devcontainer-config/install.sh:356-361,471-508,596`, `devcontainer-config/Dockerfile:486-491,500`, `devcontainer-config/devcontainer.json:24-26`; `S/logs/pass.out`

---

## Claim 21: Step 3 row: refuses `initializeCommand` or any difference in staged `devcontainer.json` or `Dockerfile`; "devcontainer.json carries runArgs (devcontainer.json:58-69), mounts (:77-80) and lifecycle commands."

**Location:** `docs/working/spike-cc-verify-q117.md:470`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the whole-file pin and the cited lines; does not establish the CLI's merge of a base image's `devcontainer.metadata` label (the rationale for pinning the Dockerfile, listed as Not verified #7).
**Legibility-target:** for-orchestrator-synthesis

`"runArgs": [` … `],` spans devcontainer.json:58-69, and `"mounts": [` … `],` spans :77-80. The script runs `if ! cmp -s "$MAIN_CFG/$i" "$S/$i"; then diff -u … | vis || true; die …` for each of `PINNED=(devcontainer.json Dockerfile)` (doc:299-304, :74). Executed: a one-line difference in main's installed `devcontainer.json`, then in its `Dockerfile`, gave `REFUSED: the staged devcontainer.json differs …` and `REFUSED: the staged Dockerfile differs …`, each with the diff shown and rc 1. Both files were restored afterwards.

**Evidence:** `devcontainer-config/devcontainer.json:58-80`, `docs/working/spike-cc-verify-q117.md:74,295-305`; outputs `S/logs/pin-devcontainer.json.out`, `S/logs/pin-Dockerfile.out` (`./run2.sh $V $W`, cwd S, rc 1)

---

## Claim 22: Step 4 rows: "`resolve_workspace` uses `git rev-parse --show-toplevel` (cc-isolated.sh:354-367), and `project_id` is that exact pipeline (cc-isolated.sh:372-374). The display name is `basename` of the workspace (cc-isolated.sh:814 → devcontainer.json:22)" ... "`--id-label cc-project=$pid` (cc-isolated.sh:836) ... `cc-${CC_PROJECT_ID}-…` (devcontainer.json:78-79) ... `--remove-existing-container` (cc-isolated.sh:883)"

**Location:** `docs/working/spike-cc-verify-q117.md:471-472`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cited lines and the PID equality on a real launcher run; does not establish CLI container selection with the real devcontainer CLI.
**Legibility-target:** for-orchestrator-synthesis

`if ! top="$(git -C "$start" rev-parse --show-toplevel 2>/dev/null)"` (cc-isolated.sh:360, `resolve_workspace()` :354-367). `printf '%s' "$1" | sha256sum | cut -c1-12` (:373, `project_id()` :372-374). `CC_PROJECT_NAME="$(basename "$ws")"` (:814). `--id-label "cc-project=$pid")` (:836). `devcontainer up --remove-existing-container "${dc[@]}"` (:883). `source=cc-${localEnv:CC_PROJECT_ID}-bashhistory` / `-claude-config` (devcontainer.json:78-79). Executed: the launcher wrote `projects/975999043c91.profile` into the stage, and the script's PID was `975999043c91`.

**Evidence:** `devcontainer-config/cc-isolated.sh:354-374,814,834-836,883`, `devcontainer-config/devcontainer.json:22,78-79`; `S/logs/pass.out`

---

## Claim 23: Step 6 row: "Flag syntax: cc-isolated.sh:9-11 and :736; guide `cc-isolated-usage.md:23,537`. `register_project` checks `$(config_dir)/egress/android.txt`, writes `$(config_dir)/projects/<pid>.profile` and re-blesses (cc-isolated.sh:434-480). `bless_manifest` writes only under `config_dir` (cc-isolated.sh:281-319)."

**Location:** `docs/working/spike-cc-verify-q117.md:474`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cited lines and the files written under the stage by `--register`; does not establish anything about the real CLI, which `--register` does not call.
**Legibility-target:** for-orchestrator-synthesis

`#   cc-isolated --register ~/code/api --profile python` (cc-isolated.sh:9). `--register)   action="register"; shift ;;` (:736). Guide :23 is `cc-isolated --register ~/code/api --profile python` and :537 is `cc-isolated --register ~/code/app --profile android`. In `register_project()` (:434-479), `if [ ! -r "$(config_dir)/egress/$p.txt" ]` (:440), `printf '%s\n' "$profiles" > "$(projects_dir)/$pid.profile"` (:458) and `bless_manifest` (:476). `bless_manifest()` (:281-319) writes only through `mktemp "$(config_dir)/.manifest.XXXXXX"` and `mv -f` into `$(manifest_path)`/`$(host_tools_path)` (:284-285, :303-304). Executed (tripwire): `written in stage: manifest.sha256 verified-live.sha256 host-tools.sha256 projects/a58497081ced.profile`, and nothing outside it.

**Evidence:** `devcontainer-config/cc-isolated.sh:9-11,281-319,434-480,736`, `guides/cc-isolated-usage.md:23,537`; `S/logs/tripwire-cur.out`

---

## Claim 24: "after the bless, the stage manifest's `devcontainer.json` and `Dockerfile` hashes must equal main's installed copies'; stage hash = `sha256sum < stage/manifest.sha256 | cut -c1-16`" ... "`check_manifest` at `--probe-only` (cc-isolated.sh:332-350) ... `blessed_hash` (cc-isolated.sh:88-93)"

**Location:** `docs/working/spike-cc-verify-q117.md:475`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the manifest line format, the awk lookup on both launchers' manifests and the hash formula; does not cover a stage swap after `check_manifest` (residual at doc:514).
**Legibility-target:** for-orchestrator-synthesis

`compute_manifest` emits `cd "$cfg" && sha256sum "${files[@]}"` sorted with `LC_ALL=C sort -k2` (cc-isolated.sh:184, :188). That is `<64 hex>  <relative path>`, so awk's default field split gives `$2 == "devcontainer.json"`. The script's lookup is `have="$(awk -v f="$i" '$2 == f { print $1 }' "$S/manifest.sha256")"` (doc:338). Executed on both the current and pre-Q-089 launchers' stage manifests: `devcontainer.json … MATCH`, `Dockerfile … MATCH`. `sha256sum < "$m" | cut -c1-16` (cc-isolated.sh:92, `blessed_hash()` :88-93) is the same formula as doc:341. `check_manifest()` is :332-350.

**Evidence:** `devcontainer-config/cc-isolated.sh:88-93,153-189,332-350`, `docs/working/spike-cc-verify-q117.md:334-341`; awk check run inline over `S/tw-cur` and `S/tw-preq089` (exit 0, output reproduced above)

---

## Claim 25: Step 7 row: "The probe action always rebuilds (cc-isolated.sh:880-885) and runs `probe_boundary` (:577-705). Only a full pass calls `record_verified_live` into `config_dir` (:113-115, :702). Main's launcher loads host code only from its own directory (cc-isolated.sh:714-718), and so did the pre-Q-089 launcher ... The review confirmed that the launcher, run against the stage, executes no staged file and writes only under it."

**Location:** `docs/working/spike-cc-verify-q117.md:476`
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the launcher's shell code at main and at `626dc300^1` (pre-Q-089) with a fake CLI; does not establish the real devcontainer CLI's own host-side writes, or its host-side execution (the `initializeCommand` refusal and the pin cover the config route).
**Legibility-target:** for-orchestrator-synthesis

`CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"` and `source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` (cc-isolated.sh:714, :718). The pre-Q-089 launcher has `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-exit-scan.sh"` (`626dc300^1:devcontainer-config/cc-isolated.sh:562`), and its cc-exit-scan.sh sources cc-gitdir.sh the same way (:11). Probe path: `devcontainer up --remove-existing-container "${dc[@]}"; probe_boundary "$ws"; exit 0` (:883-885), and `record_verified_live` (:702) writes `blessed_hash > "$(verified_path)"` (:114). The probe path also calls `logical_workspace` (:842), which only runs `cd`/`pwd` (cc-exit-scan.sh:19-29). Executed: tripwires in every staged host-side file fired for neither launcher, and nothing was written outside the stage (Claim 5).

**Evidence:** `devcontainer-config/cc-isolated.sh:113-115,577-705,714-721,842,880-885`, `devcontainer-config/cc-exit-scan.sh:19-29`; `S/logs/tripwire-cur.out`, `S/logs/tripwire-preq089.out`

---

## Claim 26: Step 8 row: "Exactly the five variables `rebuild_hint` says the by-hand CLI needs (cc-isolated.sh:561-563), and the same `dc` args the launcher uses (:834-836). `bash -c` with the block as one argument is how the probe runs in-container scripts (cc-isolated.sh:608). stdin is `/dev/null`, so nothing reads the rest of the script."

**Location:** `docs/working/spike-cc-verify-q117.md:478`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the variable list, the values (equal to what main() sets) and the args; does not establish that the real CLI's `exec` honours them (listed as Not verified #3).
**Legibility-target:** for-orchestrator-synthesis

`for var in CC_PROJECT_ID CC_PROJECT_NAME CC_CONFIG_DIR CC_EGRESS_PROFILE CC_CONFIG_HASH; do` (cc-isolated.sh:562). main() sets `CC_EGRESS_PROFILE="$eff_profile"` from `project_profile` (whitespace-stripped profile file, :391, :803, :815). For this stage that is `android`, which matches the script's `CC_EGRESS_PROFILE="$PROFILE"` (doc:372). `actual_fp="$(devcontainer exec "${dc[@]}" bash -c '` (:608). The script passes `--id-label "cc-project=$PID" bash -c "$Q117" </dev/null` (doc:373-374).

**Evidence:** `devcontainer-config/cc-isolated.sh:557-567,608,803-836`, `docs/working/spike-cc-verify-q117.md:372-375`

---

## Claim 27: "questions-archive.md:2463-2475 (byte for byte). It runs as `remoteUser: node` (devcontainer.json:71). ... `/run/cc-sni-proxy` is 0755 (`init-firewall.sh:1392-1393` on the branch) and the log is opened 0644 (`cc-sni-proxy.py:260`). The `ALLOW sni=… -> <ip>:<port>` field order is the proxy's (`cc-sni-proxy.py:207`). dl.google.com is only in `egress/android.txt`."

**Location:** `docs/working/spike-cc-verify-q117.md:479`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte identity and every cited line on the branch; does not establish a umask in the container that would narrow 0644 (0644 under the usual 022).
**Legibility-target:** for-orchestrator-synthesis

`cmp` of `questions-archive.md` lines 2463-2475 against the script's `Q117BLOCK` heredoc gave `BYTE-IDENTICAL` (13 lines each). `"remoteUser": "node",` (devcontainer.json:71). On the branch, `mkdir -p "$SNI_RUN_DIR"` / `chmod 0755 "$SNI_RUN_DIR"` (init-firewall.sh:1392-1393), with `SNI_RUN_DIR="${CC_SNI_RUN_DIR:-/run/cc-sni-proxy}"` (:771) and `SNI_LOG="$SNI_RUN_DIR/proxy.log"` (:774). `log_fd = os.open(args.log, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)` (cc-sni-proxy.py:260). `log(f"ALLOW sni={sni} -> {ip}:{upstream_port} orig_dst={orig}")` (:207), so `grep -oE '… -> [0-9.]+'` then `awk '{print $4}'` yields the IP. `rg -l dl\.google\.com devcontainer-config/egress/` lists only `android.txt`.

**Evidence:** `docs/working/questions-archive.md:2463-2475`, `devcontainer-config/devcontainer.json:71`, `fix/egress-dnsmasq-ipset:devcontainer-config/init-firewall.sh:771,774,1392-1393`, `fix/egress-dnsmasq-ipset:devcontainer-config/cc-sni-proxy.py:207,260`; `cmp` run inline, exit 0

---

## Claim 28: "verdict = Q-117's own rule: 2 instances, both fetches 200, 0 FAIL lines, the first ALLOW address absent from "pool now". `no-rotation` (exit 2) applies only when nothing else failed | questions-archive.md:2478."

**Location:** `docs/working/spike-cc-verify-q117.md:481`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four conditions, the NONE guard and the ordering; does not establish that the container's lines are honest (residual at doc:512).
**Legibility-target:** for-orchestrator-synthesis

`**Pass** = 2 instances, both fetches 200, 0 FAIL lines, and "pool now" no longer lists the first ALLOW address.` (questions-archive.md:2478). The script: `if [ "$v" = pass ] && printf ' %s ' "$pool" | grep -qF " $first "; then v=no-rotation; fi` (doc:387), after the four `grep -qx … || v=fail` lines and the NONE check (doc:381-385). Executed: `FAKE_FAILS=3` gave `RESULT Q-117 fail`, rc 1. `FAKE_FAILS=3 FAKE_POOL=142.250.1.1` gave `fail`, rc 1. `FAKE_POOL=142.250.1.1` alone gave `no-rotation`, rc 2.

**Evidence:** `docs/working/questions-archive.md:2478`, `docs/working/spike-cc-verify-q117.md:377-393`; outputs `S/logs/fails3.out` (09:11:53Z), `S/logs/fails3-norot.out`, `S/logs/norot.out` (09:11:58Z), commands `env FAKE_…=… ./run2.sh $V $W`, cwd S

---

## Claim 29: Expected output on success (the listed lines in order)

**Location:** `docs/working/spike-cc-verify-q117.md:404-443`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the harness run's line sequence; does not establish the real CLI's build output or log lines (elided in the doc).
**Legibility-target:** for-orchestrator-synthesis

The harness pass run printed the same sequence: `== 1.` to `== 8.`, the step-3 lines with `init-firewall.sh` and `claude-home`, the indented launcher lines (including `  | NOTE: blessed config … has NOT been verified`, `  | Boundary self-probe passed …` and `  | Recorded config …`), the indented Q-117 lines, `RESULT Q-117 pass`, `== teardown`, six `CHECK … ok` lines and `RESULT spike-q117 exit=0`. It also printed launcher lines the doc's `…` elides (`WARNING: no ~/.ssh/canary`, `Project: …`).

**Evidence:** `S/logs/pass.out`

---

## Claim 30: "`claude-home` shows under "differ" whenever main's installed payload predates the merged tree's; its `.manifest` alone differs."

**Location:** `docs/working/spike-cc-verify-q117.md:445`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers when the step-3 listing names `claude-home`; does not establish which other claude-home files differ on a given host.
**Legibility-target:** for-author

The staged `.manifest` can never equal an installed one. The spike writes `commit=%s` with `"$TREE"` (a tree id) and `assembled_from=cc-verify spike, merge tree …` (doc:289-290). install.sh writes `echo "commit=$commit"` (a commit id) and `echo "assembled_from=$REPO_ROOT"` (install.sh:357, :360). So `diff -rq` (doc:309) always reports `claude-home`, not only when main's install predates the merged tree. The precise version: "`claude-home` always shows under "differ": its `.manifest` names the merge tree rather than a commit. If main's install is current, the `.manifest` is the only difference."

**Evidence:** `docs/working/spike-cc-verify-q117.md:289-290,306-310`, `devcontainer-config/install.sh:356-361`

---

## Claim 31: "Exit status, also printed as `RESULT spike-q117 exit=<n>`: 0 ... 2 ... 130: interrupted (Ctrl-C, TERM, HUP). The trap still tears down. 1: anything else: a refusal, a Q-117 fail, a failed CHECK, or an incomplete teardown"

**Location:** `docs/working/spike-cc-verify-q117.md:447-451`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 0/1/2/130 and whether the RESULT line prints; does not establish SIGINT delivered from a real terminal (tested with TERM, which goes to the same trap).
**Legibility-target:** for-author

0, 1, 2 and 130 behave as listed. TERM during step 8 gave six `CHECK … ok` lines, then `RESULT spike-q117 exit=130` and rc 130, with nothing left behind. `--clean` and the preflight refusals print no `RESULT` line, because the EXIT trap is set only at doc:231 (`trap on_exit EXIT`), after the preflight at doc:210-227. Executed: running with no argument printed `REFUSED: usage: …`, rc 1, with no `RESULT` line. The precise version: "also printed as `RESULT spike-q117 exit=<n>` once the run has started. A preflight refusal prints only its `REFUSED:` line and exits 1." The doc's paste-back instruction ("On a refusal, the `REFUSED:` line") already covers what to report.

**Evidence:** `docs/working/spike-cc-verify-q117.md:173-188,210-232`; outputs `S/logs/term.out` (2026-10-15T09:14:18Z, rc 130), `S/logs/preflight.out` (09:14:52Z, rc 1)

---

## Claim 32: "What was tested here, without a host" (pass path; conflict, moved-branch, devcontainer.json and Dockerfile refusals; fail and no-rotation; forged output; planted run record; kill -9 + `--clean`; `bash -n`, `shellcheck -S warning`, paste round-trip)

**Location:** `docs/working/spike-cc-verify-q117.md:484-497`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every bullet as reproduced in my own copy of the harness; does not extend the planted-record bullet beyond its stated test (the general claim is Incorrect, Claim 11).
**Legibility-target:** for-orchestrator-synthesis

Each bullet reproduced (Claims 8, 15-17, 21, 28 and 33, plus `S/logs/planted.out`). `bash -n S/doc.sh` passed and `shellcheck -S warning S/doc.sh` exited 0 (`S/logs/shellcheck.out`). Round-trips are in Claim 6. The planted record as described ("naming the harness's project id and image") removed nothing.

**Evidence:** `S/logs/*.out` as cited in the linked claims; `shellcheck -S warning doc.sh`, cwd S, exit 0

---

## Claim 33: "Crash: `kill -9` during step 8 left the container, volumes, image, stage, clone and run record. The next run refused, `--clean` removed exactly those, and the harness's objects survived."

**Location:** `docs/working/spike-cc-verify-q117.md:496`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers kill -9 of the script process during step 8 with the snapshot present; does not cover a crash after `compare()` deleted the snapshot (Claim 12).
**Legibility-target:** for-orchestrator-synthesis

After `kill -9` of the script PID (child of `timeout`) and its process group, the run left `VERIFY-65e65962`, `run-…env`, `snap-…-before`, `src-….git`, `stage-65e65962`, container `c1234920584`, the two `cc-975999043c91-*` volumes and image `vsc-verify-65e65962-abc`. The rerun refused with `REFUSED: a previous run left state (…)`. `--clean` (`cleaning run … (tree 65e65962, project 975999043c91)`, rc 0) removed all of them, and the harness's container, volume and image remained.

**Evidence:** outputs `S/logs/crash2.out` (2026-10-15T09:13:50Z), `S/logs/crash2-rerun.out` (rc 1), `S/logs/crash2-clean.out` (09:14:09Z, rc 0); commands `FAKE_SLEEP=15 ./run2.sh $V $W` (background, then killed), `./run2.sh $V $W`, `./run.sh --clean`, cwd S

---

## Claim 34: "Not verified (needs the host run)" list (1-8) is the complete set of unverified host behaviour

**Location:** `docs/working/spike-cc-verify-q117.md:499-508`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the doc's host-dependent claims appear in the list; does not judge whether any omission matters to the verdict.
**Legibility-target:** for-author

Items 1-8 match what I could not check. One host-dependent assumption is missing: the real devcontainer CLI's own host-side writes (temp and cache dirs) and host-side actions under `up`/`exec`. Claims 5 and 25 ("writes only under the stage", "no command writes ~/.claude") rest on the launcher's code and a fake CLI (paraphrased — no quote available because the omission is an absence from the list; the list names `exec` env handling (#3) and exit status (#4), but not the CLI's filesystem footprint). Two other gaps are wrong claims rather than missing list items: the tag rule's reach (Claim 11) and the snapshot-less `--clean` (Claim 12).

**Evidence:** `docs/working/spike-cc-verify-q117.md:499-508`

---

## Claim 35: "`git clone --no-local` runs `upload-pack` against your checkout, which reads that repository's config; `uploadpack.packObjectsHook` is honoured only from protected (global/system) config."

**Location:** `docs/working/spike-cc-verify-q117.md:515`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that one key in git 2.39.5's documentation; does not enumerate other upload-pack keys read from the repository's own config.
**Legibility-target:** for-orchestrator-synthesis

`git help -m config` (git 2.39.5), under `uploadpack.packObjectsHook`: "Note that this configuration variable is only respected when it is specified in protected configuration (see the section called "SCOPES"). This is a safety measure against fetching from untrusted repositories."

**Evidence:** local `git help -m config` (git 2.39.5), entry `uploadpack.packObjectsHook`

---

## Claim 36a: Commit 190fa1a4: "R3/F4: the run record holds only RUN and T8. The project id is recomputed from ~/cc-verify/VERIFY-<T8>, images come only from this run's containers (and only if new and unused), so a planted record cannot steer docker rm, volume rm or image rm."

**Location:** commit `190fa1a4` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the image half (the RUN/T8 and container/volume halves are Verified, Claims 3 and 10); same evidence as Claims 11-12.
**Legibility-target:** for-author

Images do not "come only from this run's containers". The `verify-<T8>` tag rule (doc:121-124) removes any image whose tag contains that substring, and a planted record steered `image rm` to two images no verify container ran (Claim 11, `S/logs/planted.out`). "Only if new" also lapses under `--clean` once `compare()` has deleted the snapshot (Claim 12).

**Evidence:** `docs/working/spike-cc-verify-q117.md:112-124`; `S/logs/planted.out`, `S/logs/clean-nosnap.out`

---

## Claim 36b: Commit 190fa1a4, the remaining fix list (R1, R2, R4/F1, R5/F2, A1/F3, A2/F6, A3/F8, A6, A7, A8, A9; "Adds the iteration-1 artifacts"), and Notes: "re-tested in the stub harness ... interactive zsh reaches preflight with the right argument. Nothing ran on the host."

**Location:** commit `190fa1a4` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fix as exercised in Claims 6-8, 14-18, 21, 24, 28 and 33, and the commit's file list; does not cover R3/F4 (Claim 36a).
**Legibility-target:** for-orchestrator-synthesis

Every listed fix behaves as stated in my harness copy. `git show --stat 190fa1a4` adds exactly the three iteration-1 artifacts (`code-fact-check-report-cc-verify-spike.md`, `code-review-rubric-…`, `security-review-…`) beside the doc change. The rubric lists 5 red (R1-R5) and 9 amber (A1-A9) items (`docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md:16-20,28-36`), which matches "5 red and 9 amber". A4/A5 are recorded as residuals (doc:512, :517). Interactive `zsh -i` reached preflight (Claim 6).

**Evidence:** commit 190fa1a4 (`git show --stat`), `docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md:6-36`; logs cited in the linked claims

---

## Claim 36c: Commit 12fcb61c: "stages `git merge-tree --write-tree main fix/egress-dnsmasq-ipset` from a bare scratch clone, refusing on conflict before anything else exists; ... --clean fallback driven by a format-checked run record ... bash -n and shellcheck -S warning are clean"

**Location:** commit `12fcb61c` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 12fcb61c's own script (extracted from `git show 12fcb61c:docs/working/spike-cc-verify-q117.md`); does not re-verify the security properties iteration 1 later refuted (R3: that record's `PID=`/`IMG=` fields were format-checked but could still be steered).
**Legibility-target:** for-author

At 12fcb61c the run record and the bare clone already exist when the merge check runs: `printf 'RUN=%s\n' "$RUN" > "$V/run-$RUN.env"` (old script :157) and `git clone -q --bare --no-local -- "$REPO_TOP" "$SRCGIT"` (:165) both come before `merge-tree` (:170). "Before anything else exists" is therefore loose. 190fa1a4's doc states it precisely ("The run record and this clone are the only things created before the merge check", doc:463). `bash -n` and `shellcheck -S warning` on the 12fcb61c script both exit 0. The record fields were format-checked (`sed -n 's/^PID=\([0-9a-f]\{12\}\)$/\1/p'`, old :126). The other bullets match the old script.

**Evidence:** `12fcb61c:docs/working/spike-cc-verify-q117.md` (script lines 124-187); `shellcheck -S warning S/old.sh`, cwd S, exit 0

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/working/spike-cc-verify-q117.md:5`): says "review loop iteration 2 passed", but the commit that wrote it says iteration 2 "follows" and no iteration-2 artifact exists. Change it to "pending" until iteration 2 actually passes.
- **Claim 11** (`docs/working/spike-cc-verify-q117.md:482`): the `verify-<T8>` tag rule lets a planted record remove images no verify container ran: any tag containing `verify-<8 hex>`, matched as a case-insensitive substring. Reproduced. Narrow the rule (e.g. to the `vsc-verify-<T8>-` prefix) or state the real bound.
- **Claim 36a** (commit 190fa1a4, R3/F4): "images come only from this run's containers ... cannot steer ... image rm" is refuted by the same reproduction.

### Mostly Accurate
- **Claim 9** (`docs/working/spike-cc-verify-q117.md:402`): the `--register` failure tail (doc:331), merge-tree conflict output and the step-3 diff are shown with control bytes removed but not indented.
- **Claim 12** (`docs/working/spike-cc-verify-q117.md:482`): "only if new" holds only while the before snapshot exists. `compare()` deletes it even after a failed teardown, so the recommended `--clean` can remove a pre-existing image a verify container ran (reproduced).
- **Claim 30** (`docs/working/spike-cc-verify-q117.md:445`): `claude-home` is always listed as differing, because the staged `.manifest` names a tree id, not a commit.
- **Claim 31** (`docs/working/spike-cc-verify-q117.md:447`): preflight refusals and `--clean` print no `RESULT spike-q117 exit=` line.
- **Claim 34** (`docs/working/spike-cc-verify-q117.md:499-508`): the Not-verified list omits the real devcontainer CLI's own host-side writes, which the "writes only under the stage" and by-construction claims depend on.
- **Claim 36c** (commit 12fcb61c): "refusing on conflict before anything else exists": the run record and the bare clone already exist at that point.

### Unverifiable
- (none) The host-only behaviours are already listed in the doc's own "Not verified" section and were not claimed as verified.

---

## Goal-Alignment Note

**Success criterion (verbatim):** "a markdown report saved to the path named at the end of this prompt, structured per the code-fact-check skill, with a `**Commit:** 190fa1a4` line at the top."

The report is at the named path, with the commit line first and the skill's header, per-claim fields and attention summary. Every claim also carries a Legibility-target. Against the user goal ("a reviewed, safe one-paste host spike that live-verifies a branch without installing it"), the core safety properties hold under execution. The branch pin, the five-path rule, the devcontainer.json+Dockerfile pins with the post-bless manifest check, the credential unset, relay filtering with pipefail intact, hook-free clones, and a launcher that executes no staged file and writes only under the stage (both launcher versions) all checked out. So did the verdict ordering, the SIGPIPE fix, and crash recovery through `--clean`. What stands between this commit and "reviewed" is one behavioural overclaim, with two consequences: the teardown's image rules, which can remove images beyond what the doc and the commit promise (Claims 11, 12, 36a). There is also a premature status line (Claim 1), plus four documentation tightenings. None of these lets branch code reach the host. They concern what `--clean`/teardown may delete among the user's own docker images.
