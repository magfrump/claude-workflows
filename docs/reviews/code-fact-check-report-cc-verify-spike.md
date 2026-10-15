# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-branch-verify (branch `docs/branch-verify-without-install`)
**Scope:** `git diff 22a4bb1f..12fcb61c`: the single new file `docs/working/spike-cc-verify-q117.md` (prose, citation table and the embedded `spike-q117.sh` heredoc), plus the commit message of 12fcb61c
**Commit:** 12fcb61c
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-15
**Total claims checked:** 33
**Summary:** 20 verified, 7 mostly accurate, 0 stale, 5 incorrect, 1 unverifiable

Line numbers of the form `doc:N` refer to `docs/working/spike-cc-verify-q117.md`. The heredoc body (doc:34-333) is byte-identical to `/home/node/.claude/jobs/00bcf178/tmp/branch-verify/spike-q117.sh` (E12), so `script:N` = `doc:N+33`. Hallucination-pattern log read before checking. No claim matches a logged pattern, and no claim names a symbol, flag or file that does not exist.

## Execution log index

Every executed probe ran in scratch directories under `/home/node/.claude/jobs/00bcf178/tmp/fc/` (written `$FC` below), with fake `docker`/`devcontainer` stubs. Nothing ran docker, the devcontainer CLI, install.sh or cc-isolated against the real host. The harness is a copy of the author's `setup-t.sh`/`run-t.sh` with its paths repointed to `$FC/h`, so the author's `t1/` was not touched. No process is left running (checked with `pgrep` after the last probe).

| ID | Command (abridged; full text in the log or script) | cwd | Exit | UTC | Output |
|---|---|---|---|---|---|
| E1 | `LC_ALL=C timeout 300 bash setup-t.sh` | `$FC/h` | 0 | 2026-10-15T08:39:41Z | `$FC/execution-logs/setup.out` |
| E2 | `LC_ALL=C timeout 300 bash run-t.sh t1/home/claude-workflows 2>&1 \| cat` (pass path) | `$FC/h` | 0 (`RESULT spike-q117 exit=0`) | 08:40:35Z | `$FC/execution-logs/run-pass.out` |
| E3 | `FAKE_FAILS=3 FAKE_POOL='142.250.1.1 142.250.9.9 ' … run-t.sh …` (Q-117 fail and no rotation) | `$FC/h` | 2 | 08:40:43Z | `$FC/execution-logs/run-fail-norotation.out` |
| E4 | `FAKE_FAILS=3 … run-t.sh …` (Q-117 fail, rotated) | `$FC/h` | 1 | 08:40:4xZ | `$FC/execution-logs/run-fail.out` |
| E5 | `capture.sh`, block 3: plants `run-1-1.env` (PID/IMG of a pre-existing project) and `run-evil.env` (`../` values), then `spike-q117.sh --clean` | `$FC/h` | 1 | 08:47:32Z | `$FC/execution-logs/run-clean-planted.out` |
| E6 | spike run with a slow fake `devcontainer`, then `kill -TERM <script pid>` during step 8 | `$FC/h` | 130 | 08:42:39Z | `$FC/execution-logs/run-term.out` |
| E7 | `timeout 120 bash oldtest.sh`: a stage built like step 2, blessed and checked by the pre-Q-089 launcher (`626dc300^1`) and by main's | `$FC` | 0 | 08:43:21Z | `$FC/execution-logs/old-and-current-bless.out` |
| E8 | the doc's paste block fed to `zsh -f -i` and to `bash --norc -i` with `HOME=<scratch>` | `$FC/zhome`, `$FC/bhome` | 1, 1 | 08:43:55Z | `$FC/execution-logs/paste-zsh-interactive.out`, `paste-bash-interactive.out` |
| E9 | `bash -n ext.sh; shellcheck -S warning ext.sh` (ShellCheck 0.9.0) | `$FC` | 0, 0 | 08:44:03Z | `$FC/execution-logs/lint.out` |
| E10 | the spike with `BRANCH=feat/q125-cc-isolated-sandbox` | `$FC/h` | 1 | 08:44:32Z | `$FC/execution-logs/run-conflict.out` |
| E11 | spike run, `kill -9 <script pid>` during step 8, then a rerun, then `--clean` | `$FC/h` | rerun 1, clean 0 | 08:45:09Z | `$FC/execution-logs/run-after-kill9.out`, `run-clean-after-kill9.out` (the leftover listing between the kill and the rerun went to the terminal only: `VERIFY-65e65962`, `run-…env`, `snap-…-before`, `src-….git`, `stage-65e65962`, plus the container, two volumes and image of project `eabd29072688`) |
| E12 | `capture.sh`, block 4: `cmp` of the paste-written scripts, the doc heredoc and the author's script; `zsh -f -i` trailing-comment probe; `cmp` of the Q-117 block | `$FC` | 0 | 08:47:32Z | `$FC/execution-logs/paste-and-verbatim.out` |
| E13 | `timeout 200 bash sigpipe.sh`: 200 runs each of step 2's two `git show … \| grep -qxF …` pipelines in a bare clone | `$FC` | 0 | 08:46:11Z | `$FC/execution-logs/sigpipe-step2.out` |
| E14 | `capture.sh`, block 1: `git rev-parse`, `merge-tree --write-tree` for both branches, `git diff --name-only main <tree>` | `/workspace/.claude/wt-branch-verify` | 0 | 08:47:32Z | `$FC/execution-logs/git-facts.out` |
| E15 | `capture.sh`, block 2: `git clone --bare --no-local` of a repo with a local filter, a merge driver and `info/attributes` | `$FC` | 0 | 08:47:32Z | `$FC/execution-logs/bare-clone-copies.out` |
| E16 | fresh clone, `git merge origin/fix/egress-dnsmasq-ipset` into main, print `HEAD^{tree}` | `$FC/mg` | 0 | 08:47:52Z | `$FC/execution-logs/merge-equals-tree.out` |

---

## Claim 1: "Last verified: 2026-10-15 against main b279a2ba, `fix/egress-dnsmasq-ipset` b26d4b8b (their merge tree today: `65e65962b12e…`)."

**Location:** `docs/working/spike-cc-verify-q117.md:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three ids as of the check time; does not establish that main has not moved since, which would change the tree the spike verifies.

E14 prints `main=b279a2ba2a8f…`, `branch=b26d4b8b23aa…` and `merge-tree … 65e65962b12e40d59c586aa429e580388e051cd9` with `exit=0`.

**Evidence:** `$FC/execution-logs/git-facts.out`

---

## Claim 2: "It never writes `~/.config/claude-devcontainer`, `~/.local/bin`, `~/.claude`, your checkout's working tree, or any container, volume or image it did not create. It runs no branch code on the host"

**Location:** `docs/working/spike-cc-verify-q117.md:25`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers every write the script and main's launcher make on the normal run path; does not establish the devcontainer CLI's own host writes, or the `--clean` path fed a planted record (Claim 24b).

The launcher's host-side writes are all under `config_dir`: `mkdir -p "$(config_dir)"` / `mktemp "$(config_dir)/.manifest.XXXXXX"` / `mv -f "$new_m" "$(manifest_path)"` (`devcontainer-config/cc-isolated.sh:283-304`), `printf '%s\n' "$profiles" > "$(projects_dir)/$pid.profile"` (`:458`), and `blessed_hash > "$(verified_path)"` (`:114`). The only other host write is `snap_err="$(mktemp)"`, inside `if [ "$action" = "launch" ]` (`:843-844`), and the spike never uses that action. No staged file is executed (Claim 21). The script writes only under `$V`.

The exception is the image half. The trap also removes any image whose tag contains `verify-<T8>`, whoever created it: `case "$tags" in *verify-"$T8"*) docker image rm -f "$i"` (`script:51`). A leftover from an earlier run of the same merge tree (the doc says such leftovers are not removed and show under `NOTE`, doc:385) is removed by the next run, although that run did not create it.

**Evidence:** `devcontainer-config/cc-isolated.sh:114`, `:283-304`, `:458`, `:843-844`, `docs/working/spike-cc-verify-q117.md:84` (script:51), `:385`

---

## Claim 3: "The run proves each of these claims by checking: the before/after snapshot (`CHECK` lines), the path-keyed identity checks in step 4, and the launcher writing `projects/<PID>.profile` under the *stage*."

**Location:** `docs/working/spike-cc-verify-q117.md:25`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what `snapshot`/`compare` record; does not dispute that the listed checks run, only that they cover the claims on the same line.

The snapshot of main records three files and two links:

```bash
# docs/working/spike-cc-verify-q117.md:102-106 (script:69-73)
  for f in manifest.sha256 host-tools.sha256 verified-live.sha256; do
    if [ -e "$MAIN_CFG/$f" ]; then sha256sum < "$MAIN_CFG/$f" | sed "s|-\$|$f|" >> "$d/main"
    else echo "absent $f" >> "$d/main"; fi
  done
  for f in cc-isolated cc-push; do echo "$f -> $(readlink -f "$MAIN_BIN/$f" 2>/dev/null || echo absent)" >> "$d/main"; done
```
(excerpt ends script:73; enclosing `snapshot()` closes at script:74 — read)

Nothing records `~/.claude`, the checkout's working tree, or any other file under `~/.config/claude-devcontainer` (its `devcontainer.json`, `projects/`, `egress/`, scripts). Editing one of those without a re-bless leaves `manifest.sha256` unchanged, so `CHECK main install untouched` cannot see it (paraphrased — no quote available because the claim is about the absence of any snapshot line for those paths in `snapshot()`/`compare()`, script:62-98). Three of the five "never writes" claims (`~/.claude`, the checkout, main's config files other than its three manifests) have no runtime check. A reader of the `CHECK` lines would take them as attested. They rest on static reading only (Claim 2).

**Evidence:** `docs/working/spike-cc-verify-q117.md:95-131` (script:62-98)

---

## Claim 4: "Paths are derived from RUN and T8, never read from a file; PID and IMG are format-checked."

**Location:** `docs/working/spike-cc-verify-q117.md:62` (script:29)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `teardown()`'s path construction and its regex guards; does not establish what a format-valid but planted value can reach (Claim 24b), or that `--clean` reads RUN and T8 themselves from `run-*.env`, format-checked by `sed`.

`teardown` builds every path from the variables: `rm -rf -- "$V/stage-$T8" "$V/stage-$T8.raw" "$V/VERIFY-$T8"` behind `[[ "$T8" =~ ^[0-9a-f]{8}$ ]]`, and `rm -rf -- "$V/src-$RUN.git"` behind `[[ "$RUN" =~ ^[0-9]+-[0-9]+$ ]]` (script:46-57). PID and IMG are guarded by `^[0-9a-f]{12}$` and `^sha256:[0-9a-f]{64}$` (script:33, :43). In `--clean`, the values come from `sed -n 's/^RUN=\([0-9]*-[0-9]*\)$/\1/p' "$f"` and its siblings (script:124-127).

**Evidence:** `docs/working/spike-cc-verify-q117.md:64-93` (script:31-60), `:157-160` (script:124-127)

---

## Claim 5: "The devcontainer CLI tags its images after the workspace folder (unverified)"

**Location:** `docs/working/spike-cc-verify-q117.md:80-81` (script:47-48)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only whether the repo can settle this; does not touch the trap's by-id removal of a new image, which does not depend on naming.

This is a property of the external `@devcontainers/cli`. The sandbox has no CLI or dockerd, and the comment itself says it is unverified (doc:432). Settling it needs the host run, which prints the image tag under `NOTE … still present` or in `CHECK no pre-existing image tag moved or removed`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:80-85` (script:47-52), `:432`

---

## Claim 6: "install.sh's PAYLOAD in the merged tree is not the list this spike stages; update the spike." (and the CLAUDE_HOME_SRC twin), as the stated cause of the step-2 refusal

**Location:** `docs/working/spike-cc-verify-q117.md:224-227` (script:191-194)
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two `git show | grep -qxF` checks under `set -euo pipefail`; does not establish the failure rate on the host, which depends on pipe timing there.

```bash
# docs/working/spike-cc-verify-q117.md:224-227 (script:191-194)
"${G[@]}" show "$TREE:devcontainer-config/install.sh" | grep -qxF "$EXPECT_PAYLOAD" \
  || die "install.sh's PAYLOAD in the merged tree is not the list this spike stages; update the spike."
"${G[@]}" show "$TREE:devcontainer-config/install.sh" | grep -qxF "$EXPECT_HOME_SRC" \
  || die "install.sh's CLAUDE_HOME_SRC in the merged tree is not the list this spike stages; update the spike."
```

The script runs under `set -euo pipefail` (script:11). The merged tree's install.sh is 65,632 bytes, more than the 64 KiB pipe buffer. `grep -q` exits at the match (line 110 or 135, early in the file), and if `git show` still has bytes to write it dies with 141, which pipefail makes the pipeline's status. The script then refuses with a message saying the list differs, although it matches. In E13 (a bare clone, as in the script), PIPESTATUS was `141/0` in 4 of 200 PAYLOAD runs and 7 of 200 CLAUDE_HOME_SRC runs: about 5% of runs refuse spuriously. The same pipeline run in the review worktree, where the object is loose, failed 50 of 50 times. The failure is fail-safe (nothing is created), but the message sends the user to "update the spike" when nothing needs updating. E2's pass is one draw from that distribution.

**Evidence:** `docs/working/spike-cc-verify-q117.md:44` (script:11), `:224-227` (script:191-194), `devcontainer-config/install.sh:110`, `:135`, `$FC/execution-logs/sigpipe-step2.out`

---

## Claim 7: "`PID=… | sha256sum | cut -c1-12`   # = project_id, cc-isolated.sh:372-374"

**Location:** `docs/working/spike-cc-verify-q117.md:264` (script:231)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pipeline's equality with `project_id`; does not cover the input path equality, which is Claim 17.

`project_id() { printf '%s' "$1" | sha256sum | cut -c1-12; }` (`devcontainer-config/cc-isolated.sh:372-374`, split over three lines). The script uses `printf '%s' "$WS" | sha256sum | cut -c1-12`.

**Evidence:** `devcontainer-config/cc-isolated.sh:372-374`

---

## Claim 8: "`HASH=… cut -c1-16`   # = blessed_hash, cc-isolated.sh:89-94"

**Location:** `docs/working/spike-cc-verify-q117.md:282` (script:249)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line range and the computation; does not cover blessed_hash's callers.

The computation matches: `sha256sum < "$m" | cut -c1-16` (`devcontainer-config/cc-isolated.sh:92`). The function spans `:88-93` (`blessed_hash() {` at 88, `}` at 93, 94 blank). The doc's own table has it right (doc:411, Claim 20). This comment should read `cc-isolated.sh:88-93`.

**Evidence:** `devcontainer-config/cc-isolated.sh:88-93`

---

## Claim 9a: "verdict = Q-117's own rule … exit 2 when it never rotated" / "`2`: the pool did not rotate within 45 min" / "`1`: anything else: a refusal, a Q-117 fail, …"

**Location:** `docs/working/spike-cc-verify-q117.md:387-390`, `:416`, code at `:322-333` (script:289-300)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how the verdict variable is computed when a fail condition and a non-rotation coincide; does not dispute the pure-pass, pure-fail or pure-no-rotation cases.

```bash
# docs/working/spike-cc-verify-q117.md:321-327 (script:288-294)
v=pass
printf '%s\n' "$out" | grep -qx 'dnsmasq instances (expect 2): 2' || v=fail
printf '%s\n' "$out" | grep -qx 'fetch 1 (expect 200): 200' || v=fail
printf '%s\n' "$out" | grep -qx 'fetch 2 (expect 200): 200' || v=fail
printf '%s\n' "$out" | grep -qx 'FAIL lines for dl.google.com (expect 0): 0' || v=fail
if [ -z "$first" ] || [ "$first" = NONE ]; then v=fail
elif printf ' %s ' "$pool" | grep -qF " $first "; then v=no-rotation; fi
```
(excerpt ends script:294; the enclosing top-level step 9 continues to script:300 — read: `case "$v" in pass) exit 0 ;; no-rotation) … exit 2 ;; *) exit 1 ;;`)

The `elif` overwrites an earlier `v=fail`. A run with FAIL lines, a failed fetch, or the wrong dnsmasq count, where the pool also did not rotate, reports `RESULT Q-117 no-rotation` and exits 2. E3 (3 FAIL lines, first address still in the pool) printed `FAIL lines for dl.google.com (expect 0): 3`, then `RESULT Q-117 no-rotation`, then `RESULT spike-q117 exit=2`. The doc says a Q-117 fail exits 1, and Q-117's own rule (questions-archive.md:2478) makes rotation one condition of four, not a override of the other three. A user told "rerun later" would discard a real failure.

**Evidence:** `docs/working/spike-cc-verify-q117.md:319-333` (script:286-300), `:387-390`, `:416`, `docs/working/questions-archive.md:2478`, `$FC/execution-logs/run-fail-norotation.out`, `$FC/execution-logs/run-fail.out`

---

## Claim 9b: "`1`: anything else: a refusal, a Q-117 fail, a failed CHECK, or an incomplete teardown"

**Location:** `docs/working/spike-cc-verify-q117.md:390`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit codes reachable outside the verdict block; does not cover the fail/no-rotation case (Claim 9a).

`die` exits 1, and `on_exit` forces `rc=1` on an incomplete teardown or a failed `compare` (script:107-111). But `trap 'exit 130' INT TERM HUP` (script:159) reaches `on_exit` with `local rc=$?` = 130, which it keeps: E6 (SIGTERM during step 8) printed `RESULT spike-q117 exit=130` with every CHECK ok. A command failing under `set -e` outside a `|| die` (e.g. the step-4 `git clone`, script:229) exits with that command's status, not 1 (paraphrased — no quote available because this follows from bash's `set -e` semantics applied to the unguarded commands at script:229-230, not from a single line). The list should add "130 on Ctrl-C/TERM/HUP, other non-zero codes on an unexpected command failure".

**Evidence:** `docs/working/spike-cc-verify-q117.md:133-148` (script:100-115), `:191-192` (script:158-159), `$FC/execution-logs/run-term.out`

---

## Claim 10: Preflight rows: "`CLAUDECODE` mirrors install.sh's target-2 rule (decision 037). An inherited `CLAUDE_DEVC_CONFIG_DIR` would change which config is 'main's' (cc-isolated.sh:68-70)." / "install.sh links it there (install.sh:598, defaults :1310-1311)."

**Location:** `docs/working/spike-cc-verify-q117.md:398-399`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited lines; does not establish that the PATH check stops a user who runs a non-installed launcher by full path (the script always calls `$LAUNCHER` directly).

`if [ -n "${CLAUDECODE:-}" ]; then echo "Skipped host target (~/.claude): …"` (`devcontainer-config/install.sh:779-780`). `echo "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"` (`devcontainer-config/cc-isolated.sh:69`). `ln -sf "$DEST/cc-isolated.sh" "$BIN_DIR/cc-isolated"` (`install.sh:598`). `DEST="${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"` / `BIN_DIR="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"` (`install.sh:1310-1311`).

**Evidence:** `devcontainer-config/install.sh:598`, `:779-780`, `:1310-1311`, `devcontainer-config/cc-isolated.sh:68-70`

---

## Claim 11a: "A bare clone copies objects and refs only: no `.git/config` filters, merge drivers, attributes or hooks."

**Location:** `docs/working/spike-cc-verify-q117.md:401`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `git clone --bare --no-local` copies at clone time; does not establish that nothing writes into `src-<RUN>.git` afterwards. A racing same-uid writer could plant `config`/`info/attributes` there before `merge-tree`/`archive` run (override-log row 509), and the `-c` flags switch off neither merge drivers nor filters. Hooks were not executed (a sandbox policy blocks writing a hooks dir); they rest on git's documented clone behaviour.

E15: a source repo with `filter.evil.smudge`, `merge.evil.driver` and `info/attributes` set produced a bare clone whose `config` holds only `[core]` and `[remote "origin"]`, and whose `info/attributes` does not exist. `git_state_gate` is at `devcontainer-config/install.sh:209-252` as cited.

**Evidence:** `devcontainer-config/install.sh:209-252`, `$FC/execution-logs/bare-clone-copies.out`

---

## Claim 11b: "every later git call with `-c core.hooksPath=/dev/null -c core.fsmonitor=false`"

**Location:** `docs/working/spike-cc-verify-q117.md:401`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which git invocations after the bare clone carry the flags; does not assess how much the omission exposes beyond the user's own global or template hooks.

`G=(git -C "$SRCGIT" -c core.hooksPath=/dev/null -c core.fsmonitor=false)` (script:166) covers steps 1-2. Step 4 does not use it: `git clone -q --no-local -- "$SRCGIT" "$W" </dev/null` and `WS="$(git -C "$W" rev-parse --show-toplevel)"` (script:229-230). That clone checks out a working tree, so a `post-checkout` hook from the user's global `core.hooksPath` or `init.templateDir` runs, and committed `.gitattributes` meet global filter drivers (the latter is in the doc's residuals, doc:443; the hook is not).

**Evidence:** `docs/working/spike-cc-verify-q117.md:199` (script:166), `:262-263` (script:229-230), `:443`

---

## Claim 11c: "The flags match `repo_git` (install.sh:180-182)."

**Location:** `docs/working/spike-cc-verify-q117.md:401`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the flag sets; does not claim the missing flag matters for the bare repo.

`git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"` (`devcontainer-config/install.sh:181`). The spike's `G` has the two `-c` flags but not `--no-optional-locks`. A bare repo has no index, so this makes no difference there. Precise version: "the same two `-c` flags as `repo_git`".

**Evidence:** `devcontainer-config/install.sh:180-182`

---

## Claim 12: "`git merge-tree --write-tree --name-only main fix/egress-dnsmasq-ipset`: exit 1 refuses with the conflict list, any other non-zero refuses … Verified in the sandbox: today it is clean (tree `65e65962…`), and `feat/q125-cc-isolated-sandbox` is refused on `hooks/live-verify-gate.sh`."

**Location:** `docs/working/spike-cc-verify-q117.md:402`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 here; does not establish the host's git version (doc:436 lists it as unverified). Override-log row 507 (a missing tip tree exits 0) does not bite here: the `--no-local` clone transfers a connectivity-checked pack, and the tips are resolved with `rev-parse --verify -q "refs/heads/…^{commit}"` (script:167-168).

E14: main + branch prints the tree with `exit=0`. main + q125 prints `CONFLICT (content): Merge conflict in hooks/live-verify-gate.sh` with `exit=1`. E10 ran the whole spike with the branch swapped: `REFUSED: feat/q125-cc-isolated-sandbox does not merge cleanly with main`, `RESULT spike-q117 exit=1`, and no docker call other than preflight's `docker info`. The `case "$mrc"` mapping is at script:173-177.

**Evidence:** `docs/working/spike-cc-verify-q117.md:200-210` (script:167-177), `$FC/execution-logs/git-facts.out`, `$FC/execution-logs/run-conflict.out`

---

## Claim 13: "refuses unless the merged tree's `install.sh` has exactly the `PAYLOAD=(…)` and `CLAUDE_HOME_SRC=(…)` lines the spike stages | install.sh:110 and :135. The egress branch does not touch install.sh."

**Location:** `docs/working/spike-cc-verify-q117.md:403`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "refuses if absent" direction and the citations; does not cover the converse, that it passes when present, which fails in about 5% of runs (Claim 6).

The script's `EXPECT_PAYLOAD`/`EXPECT_HOME_SRC` (script:20-21) equal `devcontainer-config/install.sh:110` and `:135` character for character, and `grep -qxF` requires a whole-line match. E14's `git diff --name-only main <tree>` lists only `devcontainer-config/init-firewall.sh` among payload paths: no install.sh.

**Evidence:** `docs/working/spike-cc-verify-q117.md:53-54` (script:20-21), `devcontainer-config/install.sh:110`, `:135`, `$FC/execution-logs/git-facts.out`

---

## Claim 14: "Same sources and the same no-symlink rule as `extract_commit` (install.sh:257-317, the symlink refusal at :288)."

**Location:** `docs/working/spike-cc-verify-q117.md:404`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers sources and the symlink rule; does not claim parity on the rest of `extract_commit`. The spike omits its NUL-byte refusal (install.sh:297-316) and its `-c tar.umask=022 … | tar -xpf` modes (`:281-282`). Modes have no effect, because the Dockerfile resets them (`chmod 0555`/`0444`, Dockerfile:516-523).

`extract_commit` runs `repo_git -c tar.umask=022 archive --format=tar "$commit" -- "$@"` over the PAYLOAD and CLAUDE_HOME_SRC paths, and its symlink block starts at `:288` with `# No symlinks (review R1).` and refuses on `find . -type l`. The spike archives `devcontainer-config global-instructions/CLAUDE.md` plus the six dirs and refuses on `find "$S.raw" -type l` (script:196-198). Its check covers the whole `devcontainer-config/` directory, a superset of the payload.

**Evidence:** `devcontainer-config/install.sh:257-317`, `devcontainer-config/Dockerfile:516-523`, `docs/working/spike-cc-verify-q117.md:229-231` (script:196-198)

---

## Claim 15: Layout row: "the 10 PAYLOAD files and dirs at the stage root, `claude-home/` built from `CLAUDE.md` and the six dirs, a `.manifest`, `chmod +x` on three scripts | Matches `install_devcontainer` (install.sh:471-508), `assemble`'s `.manifest` keys (:356-361) and install.sh:596. The Dockerfile copies `claude-home/` (Dockerfile:500), `egress/` (:486) and the scripts (:487-491) from the build context, which is `CC_CONFIG_DIR` (devcontainer.json:24-26)."

**Location:** `docs/working/spike-cc-verify-q117.md:405`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the layout as consumed by the Dockerfile and by `compute_manifest`/`compute_host_tools_manifest` of the current and pre-Q-089 launchers; does not establish that nothing in the container reads `.manifest`'s `commit=` as a commit id (the spike writes a tree id there, script:206-207).

Every citation lands: `install_devcontainer() {` at `install.sh:471`; `echo "commit=$commit"` … `echo "assembled_from=$REPO_ROOT"` at `:357-360`; `chmod +x "$DEST/cc-isolated.sh" "$DEST/cc-push.sh" "$DEST/init-firewall.sh"` at `:596`; `COPY claude-home/ /opt/claude-workflows/` at `Dockerfile:500`; `COPY egress/` at `:486`; `COPY init-firewall.sh`, `cc-sni-proxy.py`, `link-claude-home.sh` at `:487-491`; `"dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile"` and `"context": "${localEnv:CC_CONFIG_DIR}"` at `devcontainer.json:25-26`. E7 built a stage the same way: the pre-Q-089 launcher's `--bless` hashed 140 entries, including `cc-exit-scan.sh`, `cc-gitdir.sh`, `cc-push.sh` (its `enforcement_files` lists them) and `claude-home/.manifest`, and wrote no `host-tools.sha256`. `check_manifest` passed. Main's launcher's `bless_manifest` plus `check_manifest` passed on a copy and wrote a three-entry `host-tools.sha256`. E2 ran main's real launcher end to end against a real stage.

**Evidence:** `devcontainer-config/install.sh:471-508`, `:356-361`, `:596`, `devcontainer-config/Dockerfile:486-500`, `devcontainer-config/devcontainer.json:24-26`, `$FC/execution-logs/old-and-current-bless.out`, `$FC/execution-logs/run-pass.out`

---

## Claim 16: "main's copy has no `initializeCommand`, and its runArgs (devcontainer.json:58-69) and mounts (:77-80) are the reviewed ones. The egress branch does not change the file."

**Location:** `docs/working/spike-cc-verify-q117.md:406`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citations and the gate's logic (`grep -n 'initializeCommand'` then a whole-file `cmp`); does not establish that the user's installed copy equals main's (the gate checks that at run time).

`grep -n initializeCommand devcontainer-config/devcontainer.json` returns nothing. `"runArgs": [` is at `:58` and its `],` at `:69`. `"mounts": [` is at `:77` and `],` at `:80`. The lifecycle command is `"postStartCommand": "sudo /usr/local/bin/init-firewall.sh && /usr/local/bin/link-claude-home.sh"` (`:141`), which runs in the container. E14's merge diff does not list devcontainer.json.

**Evidence:** `devcontainer-config/devcontainer.json:58-80`, `:141`, `docs/working/spike-cc-verify-q117.md:246-252` (script:213-219), `$FC/execution-logs/git-facts.out`

---

## Claim 17: "`resolve_workspace` uses `git rev-parse --show-toplevel` (cc-isolated.sh:354-367), and `project_id` is that exact pipeline (cc-isolated.sh:372-374). The display name is `basename` of the workspace (cc-isolated.sh:814 → devcontainer.json:22)"

**Location:** `docs/working/spike-cc-verify-q117.md:407`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers path and identity equality between the spike and main's launcher; does not cover the devcontainer CLI's use of `name`.

`top="$(git -C "$start" rev-parse --show-toplevel 2>/dev/null)"` (`cc-isolated.sh:360`), `CC_PROJECT_NAME="$(basename "$ws")"` (`:814`), `"name": "cc-isolated (${localEnv:CC_PROJECT_NAME})"` (`devcontainer.json:22`). In E2 the spike's check `[ "$(cat "$S/projects/$PID.profile" 2>/dev/null)" = "$PROFILE" ]` (script:247) passed, so the launcher computed the same PID (`eabd29072688`).

**Evidence:** `devcontainer-config/cc-isolated.sh:354-367`, `:372-374`, `:814`, `devcontainer-config/devcontainer.json:22`, `$FC/execution-logs/run-pass.out`

---

## Claim 18: "The launcher selects the container by `--id-label cc-project=$pid` (cc-isolated.sh:836) and names volumes `cc-${CC_PROJECT_ID}-…` (devcontainer.json:78-79). A fresh PID means `--remove-existing-container` (cc-isolated.sh:883) can only hit this run's container."

**Location:** `docs/working/spike-cc-verify-q117.md:408`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the label/volume keying and the step-4 freshness checks; does not cover a concurrent process creating a same-label container between step 4 and step 7.

`--id-label "cc-project=$pid")` (`cc-isolated.sh:836`); `"source=cc-${localEnv:CC_PROJECT_ID}-bashhistory,…"` and `"source=cc-${localEnv:CC_PROJECT_ID}-claude-config,…"` (`devcontainer.json:78-79`); `devcontainer up --remove-existing-container "${dc[@]}"` (`cc-isolated.sh:883`). Step 4 refuses on any existing label or volume (script:236-237).

**Evidence:** `devcontainer-config/cc-isolated.sh:834-836`, `:883`, `devcontainer-config/devcontainer.json:78-79`, `docs/working/spike-cc-verify-q117.md:269-270` (script:236-237)

---

## Claim 19: "Flag syntax: cc-isolated.sh:9-11 and :736, guide `cc-isolated-usage.md:23,537`. `register_project` checks `$(config_dir)/egress/android.txt`, writes `$(config_dir)/projects/<pid>.profile` and re-blesses (cc-isolated.sh:434-480). `bless_manifest` writes only under `config_dir` (cc-isolated.sh:281-319)."

**Location:** `docs/working/spike-cc-verify-q117.md:410`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the current launcher (the pre-Q-089 `bless_manifest` writes only `$(manifest_path)`, also under config_dir); does not cover `--register`'s precondition that main's own host tools pass `verify_host_tools` (cc-isolated.sh:753), which refuses the step if main's install is in a changed state.

`if [ ! -r "$(config_dir)/egress/$p.txt" ]` (`:440`), `printf '%s\n' "$profiles" > "$(projects_dir)/$pid.profile"` (`:458`), `bless_manifest` (`:476`). The writes in `bless_manifest` are `mkdir -p "$(config_dir)"`, two `mktemp "$(config_dir)/…"` and two `mv -f` into `host_tools_path`/`manifest_path` (`:283-304`). `--register)   action="register"` is at `:736`, the header at `:9-11`, and the guide lines read `cc-isolated --register ~/code/api --profile python` (23) and `… --profile android` (537). In E2 the stage gained `projects/eabd29072688.profile`, and `CHECK main install untouched: ok`.

**Evidence:** `devcontainer-config/cc-isolated.sh:9-11`, `:281-319`, `:434-480`, `:736`, `guides/cc-isolated-usage.md:23`, `:537`, `$FC/execution-logs/run-pass.out`

---

## Claim 20: "stage hash = `sha256sum < stage/manifest.sha256 | cut -c1-16` | = `blessed_hash` (cc-isolated.sh:88-93)."

**Location:** `docs/working/spike-cc-verify-q117.md:411`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the formula and the range; does not cover the script comment's different range (Claim 8).

`sha256sum < "$m" | cut -c1-16` inside `blessed_hash() {` … `}` at `devcontainer-config/cc-isolated.sh:88-93`.

**Evidence:** `devcontainer-config/cc-isolated.sh:88-93`

---

## Claim 21: "The probe action always rebuilds (cc-isolated.sh:880-885), runs `probe_boundary` (:577-705), and only a full pass calls `record_verified_live` into `config_dir` (:113-115, :702). Main's launcher loads host code only from its own directory (cc-isolated.sh:714-718; the pre-Q-089 launcher also did …). So the stage's copies of `cc-isolated.sh` and the host tools are hashed but never executed. They are staged because `enforcement_files`/`host_tool_files` (cc-isolated.sh:128-151, :199-203) and the bless need them present."

**Location:** `docs/working/spike-cc-verify-q117.md:412`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every launcher action the spike uses (register, probe) for both launcher generations, including `verify_host_tools`, the sourced `cc-exit-scan.sh`→`cc-gitdir.sh` chain, `logical_workspace`, and every host write; does not cover the devcontainer CLI, which reads the stage's `devcontainer.json` on the host (Claim 16's gate) and hands the stage's `Dockerfile` to docker, whose `RUN` steps execute in build containers.

```bash
# devcontainer-config/cc-isolated.sh:714-718
CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
HOST_TOOLS_ERR=""
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
  # shellcheck source=cc-exit-scan.sh
  source "$CC_ISOLATED_DIR/cc-exit-scan.sh"
```
(excerpt ends :718; the enclosing top-level `if` closes at :721 — read)

`$LAUNCHER` is `$MAIN_CFG/cc-isolated.sh`, so `CC_ISOLATED_DIR` is main's dir, and `cc-exit-scan.sh` sources `"$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"` from that same dir (`cc-exit-scan.sh:12`). Its other top-level statements are variable assignments. In the pre-Q-089 launcher (`git show 626dc300^1:…`) it is `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-exit-scan.sh"` at line 562, with no host-tool check. `verify_host_tools` is only called on `CC_ISOLATED_DIR` (`:716`, `:759`, `:764`, `:777`) and, in `--list`, on config_dir (`:502-503`), which the spike never runs. It only reads files. In the probe path, `devcontainer up --remove-existing-container "${dc[@]}"; probe_boundary "$ws"` (`:883-884`). `record_verified_live` has one call site, `:702`, reached only when `failures` is 0 (`:698-701`). The stage's `cc-isolated.sh` is listed by `enforcement_files` (`:136`), the host tools by `host_tool_files` (`:199-203`), and `compute_manifest` refuses a missing file (`echo "ERROR: enforcement file missing: $f"`, `:172`). E2's log shows the probe's `NOTE: blessed config … has NOT been verified` and the receipt landing in the stage.

**Evidence:** `devcontainer-config/cc-isolated.sh:113-115`, `:128-151`, `:199-203`, `:577-705`, `:714-721`, `:753-779`, `:880-885`, `devcontainer-config/cc-exit-scan.sh:12-29`, `$FC/execution-logs/run-pass.out`, `$FC/execution-logs/old-and-current-bless.out`

---

## Claim 22: "Exactly the five variables `rebuild_hint` says the by-hand CLI needs (cc-isolated.sh:561-563), and the same `dc` args the launcher uses (:834-836). `bash -c` with the block as one argument is how the probe runs in-container scripts (cc-isolated.sh:608)."

**Location:** `docs/working/spike-cc-verify-q117.md:414`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers equality with the launcher's code, values included; does not establish that `devcontainer exec` needs or uses these variables, or passes the inner exit status back (both listed as unverified at doc:434-435).

`for var in CC_PROJECT_ID CC_PROJECT_NAME CC_CONFIG_DIR CC_EGRESS_PROFILE CC_CONFIG_HASH; do` (`cc-isolated.sh:562`). The values match `main()`: `CC_PROJECT_ID="$pid"`, `CC_PROJECT_NAME="$(basename "$ws")"`, `CC_EGRESS_PROFILE="$eff_profile"` (the profile file's `android`), `CC_CONFIG_DIR="$(config_dir)"` = the stage, `CC_CONFIG_HASH="$(blessed_hash)"` (`:813-831`). `dc` is `--workspace-folder "$ws" --override-config "$(config_dir)/devcontainer.json" --id-label "cc-project=$pid"` (`:834-836`). The probe passes its scripts as `bash -c '…'` (`:608`).

**Evidence:** `devcontainer-config/cc-isolated.sh:557-567`, `:608`, `:813-836`, `docs/working/spike-cc-verify-q117.md:313-316` (script:280-283)

---

## Claim 23: "Q-117's container block, verbatim | questions-archive.md:2463-2475 (checked byte for byte). It runs as `remoteUser: node` (devcontainer.json:71). node can read the proxy log: on the branch, `/run/cc-sni-proxy` is 0755 (`init-firewall.sh:1392-1393` on the branch) and the log is opened 0644 (`cc-sni-proxy.py:260`). The `ALLOW sni=… -> <ip>:<port>` field order is the proxy's (`cc-sni-proxy.py:207`). dl.google.com is only in `egress/android.txt`."

**Location:** `docs/working/spike-cc-verify-q117.md:415`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block's text, the cited modes and the log format; does not establish the log's effective mode. The `0o644` is filtered by the creating process's umask, and `O_TRUNC` on an existing file keeps its old mode.

E12: `cmp` of `questions-archive.md:2463-2475` against the spike's `Q117BLOCK` body: byte-identical. On the branch, `mkdir -p "$SNI_RUN_DIR"` / `chmod 0755 "$SNI_RUN_DIR"` are at `init-firewall.sh:1392-1393`, with `SNI_RUN_DIR="${CC_SNI_RUN_DIR:-/run/cc-sni-proxy}"` (`:771`) and `SNI_LOG="$SNI_RUN_DIR/proxy.log"` (`:774`). `log_fd = os.open(args.log, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)` is at `cc-sni-proxy.py:260`, and `log(f"ALLOW sni={sni} -> {ip}:{upstream_port} orig_dst={orig}")` at `:207`, so the block's `awk '{print $4}'` takes the address. `"remoteUser": "node"` is at `devcontainer.json:71`. In the merged tree, `dl.google.com` is an entry only in `egress/android.txt:33`.

**Evidence:** `docs/working/questions-archive.md:2463-2475`, `devcontainer-config/devcontainer.json:71`, `fix/egress-dnsmasq-ipset:devcontainer-config/init-firewall.sh:771-774`, `:1392-1393`, `fix/egress-dnsmasq-ipset:devcontainer-config/cc-sni-proxy.py:207`, `:260`, `$FC/execution-logs/paste-and-verbatim.out`

---

## Claim 24a: "So a planted `run-*.env` cannot steer `rm -rf` outside `~/cc-verify`"

**Location:** `docs/working/spike-cc-verify-q117.md:417`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `rm -rf` targets under `--clean`; does not cover which `~/cc-verify` entries a valid-format planted T8 or RUN can remove (another run's stage or clone, still inside `~/cc-verify`).

Every `rm` target is `"$V/<fixed prefix>-$X"`, with X guarded by an anchored hex or digit regex (Claim 4). In E5, a planted `run-evil.env` holding `RUN=../../x` and `T8=../../../` was skipped (`skipping malformed …`), and a probe directory outside `~/cc-verify` survived.

**Evidence:** `docs/working/spike-cc-verify-q117.md:151-168` (script:118-135), `$FC/execution-logs/run-clean-planted.out`

---

## Claim 24b: "…or `docker rm` outside one 12-hex label"

**Location:** `docs/working/spike-cc-verify-q117.md:417`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the docker removals a format-valid planted record drives; does not assess who can plant one (the doc's threat model, doc:442, says cc-isolated agents cannot reach `~/cc-verify`).

```bash
# docs/working/spike-cc-verify-q117.md:160-161 (script:127-128)
    IMG="$(sed -n 's/^IMG=\(sha256:[0-9a-f]\{64\}\)$/\1/p' "$f" | head -1)"
    IMG_NEW=0; [ -n "$IMG" ] && IMG_NEW=1
```
(excerpt ends script:128; the enclosing `for f` loop continues to script:133 — read)

Any well-formed `IMG=` line sets `IMG_NEW=1`, and `teardown` runs `docker image rm -f "$IMG"` (script:44). No label constrains that image. The label itself can be any project's: `PID=` drives `docker rm -f` of that project's containers and `docker volume rm cc-<PID>-claude-config`, its credential and memory volume (script:33-41). In E5, a record naming a pre-existing project (`PID=cccccccccccc`, `IMG=` its image id) made `--clean` remove that project's container, its `cc-cccccccccccc-claude-config` volume and its image (`vsc-realproject-zzz`). Precise version: "rm -rf stays inside ~/cc-verify. A planted record can still remove any one project's containers and volumes, and any one image."

**Evidence:** `docs/working/spike-cc-verify-q117.md:64-78` (script:31-45), `:157-164` (script:124-131), `$FC/execution-logs/run-clean-planted.out`

---

## Claim 25: "What was tested here, without a host": pass path exit 0 with harness objects surviving; conflicting branch "refused at step 1 … with no docker call made"; `devcontainer.json` difference refused at step 3; Q-117 failure exit 1, no rotation exit 2; `kill -9` then refusal then `--clean`; `bash -n` and `shellcheck -S warning` clean.

**Location:** `docs/working/spike-cc-verify-q117.md:421-428`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Re-ran pass, conflict, fail, no-rotation, kill -9 + `--clean`, and the two linters; did not re-run the devcontainer.json-refusal case. The results establish the harness outcomes, not the defects in Claims 6 and 9a, which the tested inputs did not reach.

Reproduced: E2 `RESULT Q-117 pass`, every CHECK ok, `exit=0`. E10 conflict refused at step 1. E4 `RESULT Q-117 fail`, exit 1. E11: the kill left the stage, workspace, clone, run record, container, volumes and image; the rerun refused with `a previous run left state`; `--clean` removed exactly those and kept the other project's objects. E9: both linters exit 0 with no output. Two atoms are imprecise. "With no docker call made": preflight's `docker info` (script:148) ran in E10, and only teardown made no call. "No rotation: exit 2" holds only when nothing else failed (Claim 9a, E3).

**Evidence:** `$FC/execution-logs/run-pass.out`, `run-conflict.out`, `run-fail.out`, `run-fail-norotation.out`, `run-after-kill9.out`, `run-clean-after-kill9.out`, `lint.out`

---

## Claim 26: "Main's launcher hashes the stage's enforcement files at bless and at `--probe-only` (cc-isolated.sh:332-350), which covers `devcontainer.json`, `Dockerfile` and `init-firewall.sh`."

**Location:** `docs/working/spike-cc-verify-q117.md:442`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the check at probe time; does not cover the window between that check and the docker build reading the files (the doc names it as residual).

`check_manifest` (`:332-350`) compares `cat "$manifest"` with `compute_manifest` and refuses on a difference. It runs for the probe action at `:828`, before `devcontainer up` (`:883`). `enforcement_files` lists the three files (`:131-133`).

**Evidence:** `devcontainer-config/cc-isolated.sh:128-151`, `:332-350`, `:828`, `:880-885`

---

## Claim 27: "With no main commits in between, a clean `git merge` gives exactly this tree."

**Location:** `docs/working/spike-cc-verify-q117.md:445`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's main and branch with git 2.39.5's default (ort) strategy; does not cover a merge made with a non-default strategy or custom merge drivers.

E16: `git merge origin/fix/egress-dnsmasq-ipset` into main in a fresh clone gives `HEAD^{tree}=65e65962b12e40d59c586aa429e580388e051cd9`, the merge-tree id.

**Evidence:** `$FC/execution-logs/merge-equals-tree.out`

---

## Claim 28: Commit message bullets: "stages `git merge-tree --write-tree main fix/egress-dnsmasq-ipset` from a bare scratch clone, refusing on conflict before anything else exists; lays the stage out like install.sh's payload; refuses a devcontainer.json that differs …; clones a VERIFY-<tree8> workspace whose path-keyed project id is checked fresh; runs main's installed cc-isolated …; snapshots docker and main's manifests …, with a --clean fallback driven by a format-checked run record. Each step is cited to file:line." / Notes: "pass, conflict refusal, devcontainer.json refusal, Q-117 fail, no-rotation and kill -9 + --clean all behaved as documented."

**Location:** commit `12fcb61c` message (`git log -1 --format=%B 12fcb61c`)
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the script; does not repeat the per-step checks (Claims 12-24).

Each bullet matches the script (Claims 12-24). Two qualifiers are missing. "Before anything else exists": the run record and the bare clone already exist when merge-tree runs (`printf 'RUN=%s\n' "$RUN" > "$V/run-$RUN.env"` at script:157, the clone at script:165); the doc's own phrasing, "Nothing outside `~/cc-verify` exists yet" (doc:402), is the precise one. "Behaved as documented": the documented exit semantics are wrong when a fail and a non-rotation coincide (Claim 9a), and the "format-checked run record" still lets a planted record steer docker removals (Claim 24b).

**Evidence:** `docs/working/spike-cc-verify-q117.md:190-198` (script:157-165), `:402`, `$FC/execution-logs/run-fail-norotation.out`, `$FC/execution-logs/run-clean-planted.out`

---

## Claim 29: Commit message: "the paste round-trips under bash and zsh."

**Location:** commit `12fcb61c` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paste written into an interactive bash and an interactive zsh with no rc files (`zsh -f -i`); does not cover zsh setups that turn on `INTERACTIVE_COMMENTS` (many frameworks do), where the run line works.

E8/E12: in both shells the heredoc writes a `spike-q117.sh` byte-identical to the doc's body. But in zsh's default interactive mode, `#` does not start a comment. The first line gives `zsh: command not found: #`, and the last line, `bash ~/cc-verify/spike-q117.sh ~/claude-workflows    # EDIT: your host checkout of claude-workflows`, passes `#`, `EDIT:`, … as six extra arguments. The script then refuses with `REFUSED: usage: …` (E8; E12's probe shows `echo a # b c` printing `a # b c`). It refuses safely, but the documented "edit the path, paste" (doc:29) does not run the spike in a default zsh. The precise version: "the script round-trips under both; in zsh the run line needs `setopt interactivecomments` or the trailing comment moved off that line".

**Evidence:** `docs/working/spike-cc-verify-q117.md:29`, `:32`, `:335`, `$FC/execution-logs/paste-zsh-interactive.out`, `$FC/execution-logs/paste-bash-interactive.out`, `$FC/execution-logs/paste-and-verbatim.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3** (`docs/working/spike-cc-verify-q117.md:25`): the `CHECK` snapshot covers only main's three manifest files, two bin links and docker lists. `~/.claude`, the checkout and main's other config files have no runtime check, so drop them from "the run proves" or snapshot them.
- **Claim 6** (`docs/working/spike-cc-verify-q117.md:224-227`, script:191-194: `git show <65,632-byte blob> | grep -qxF` under pipefail exits 141 in about 5% of runs (E13), so step 2 refuses with a false "PAYLOAD … is not the list". Grep from a file or a here-string, or drop `-q`.
- **Claim 9a** (`docs/working/spike-cc-verify-q117.md:326-327` (script:293-294), `:387-390`, `:416`): the `elif … v=no-rotation` overwrites `v=fail`, so a Q-117 failure with an unrotated pool exits 2 ("rerun later") instead of 1 (E3).
- **Claim 11b** (`docs/working/spike-cc-verify-q117.md:401`): the step-4 `git clone` and `rev-parse` (script:229-230) do not carry the `-c` flags. The clone's checkout runs any global or template `post-checkout` hook.
- **Claim 24b** (`docs/working/spike-cc-verify-q117.md:417`): a planted record's `IMG=` removes any image, and its `PID=` can name any project, whose containers and `claude-config` volume `--clean` then removes (E5).

### Stale
- (none)

### Mostly Accurate
- **Claim 2** (`docs/working/spike-cc-verify-q117.md:25`): the `*verify-<T8>*` tag removal also takes a same-tree leftover from an earlier run, which this run did not create.
- **Claim 8** (`docs/working/spike-cc-verify-q117.md:282`, script:249: the comment cites `cc-isolated.sh:89-94`; `blessed_hash` is at `:88-93`.
- **Claim 9b** (`docs/working/spike-cc-verify-q117.md:390`): Ctrl-C/TERM/HUP exits 130 (E6), and an unguarded `set -e` failure exits with its own status. Neither is 1.
- **Claim 11c** (`docs/working/spike-cc-verify-q117.md:401`): `repo_git` also passes `--no-optional-locks`. Say "the same two `-c` flags".
- **Claim 25** (`docs/working/spike-cc-verify-q117.md:421-428`): preflight's `docker info` runs before the conflict refusal, and "no rotation: exit 2" holds only with no other failure.
- **Claim 28** (commit 12fcb61c): the run record and bare clone exist before the merge check, and "behaved as documented" inherits Claims 9a and 24b.
- **Claim 29** (commit 12fcb61c): in a default interactive zsh, the run line's trailing `# EDIT:` comment becomes arguments and the script refuses with usage (E8).

### Unverifiable
- **Claim 5** (`docs/working/spike-cc-verify-q117.md:80-81`, script:47-48): the devcontainer CLI's image naming needs the host run (CLI plus dockerd).

No Incorrect verdict is a fabricated symbol, API or flag, so `docs/reviews/hallucination-patterns.md` gets no new entry.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to /workspace/.claude/wt-branch-verify/docs/reviews/code-fact-check-report-cc-verify-spike.md, structured per the code-fact-check skill, with `**Commit:** 12fcb61c` and `**Replication:** k=1 (loop pass, decision 031)` header lines.
- Answered: yes. All eight focus areas are verdicted, every listed file:line citation is checked (all land; one script comment is off by one), and the harness was re-run in a private copy.
- Out of scope: the earlier research and DD commits; code-quality judgments beyond whether the doc matches the code; anything needing the real devcontainer CLI or dockerd.
- Escalate: Claims 6, 9a and 24b are behaviour defects in the paste itself. Each has a one-line fix and should be fixed before the `you: terminal` entry goes out. Claim 29 decides whether the paste works in the user's shell.
- Decisions I made: execution logs stay in the job scratch dir (`/home/node/.claude/jobs/00bcf178/tmp/fc/execution-logs/`), not `docs/reviews/execution-logs/`, because the brief allowed the worktree to change by this report only; the harness ran from a repointed copy so the author's `t1/` stayed untouched.
