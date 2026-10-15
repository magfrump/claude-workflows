# Code Fact-Check Report

**Commit:** 190fa1a4

**Repository:** /workspace/.claude/wt-branch-verify (branch `docs/branch-verify-without-install`)
**Scope:** `docs/working/spike-cc-verify-q117.md` at 190fa1a4 (whole file; its script is byte-identical to `spike-q117.v2.sh`, confirmed with `cmp`), plus the commit messages of 12fcb61c and 190fa1a4. Replicate 3 of the k=3 final confirming pass (decision log 63), review iteration 2.
**Checked:** 2026-10-15
**Total claims checked:** 37
**Summary:** 27 verified, 6 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Execution environment: my own scratch dir `/home/node/.claude/jobs/00bcf178/tmp/fc2r3.k9t7/` (abbreviated `$X` below). I copied the harness from `branch-verify/setup-t.sh` with only `B=` changed, rebuilt `t1/` there (fake `docker`/`devcontainer`, main's real launcher installed and blessed in a fake `~/.config/claude-devcontainer`, a `--no-local` clone of the worktree as the "checkout"), and extended my copy of the fake `devcontainer` with `FAKE_UP_RC`, `FAKE_EXEC_RC`, `FAKE_HANG`, `FAKE_EXTRA` and an env dump. `$X/runenv.sh <args>` copies `$X/spike-q117.sh` (the v2 script) into the fake HOME and runs `env -u CLAUDECODE -u CLAUDE_DEVC_CONFIG_DIR HOME=$X/t1/home PATH=$X/t1/bin:… DSTATE=$X/t1/dstate bash ~/cc-verify/spike-q117.sh <args>`. Every run had a `timeout`. All outputs are in `$X/logs/` (`<name>.out`, `.rc`, `.ts`). No processes were left running (checked with `pgrep`). Nothing outside `$X` was written apart from this report. The brief's `t1/` and the v2 script were not modified.

Hallucination-pattern log: I read `docs/reviews/hallucination-patterns.md`. No claim below matches a logged pattern. None of the Incorrect verdicts is a fabricated symbol/API, so no entry is due (and the brief makes this run read-only apart from the report).

---

## Claim 1: "Task status: paused (paste written; review loop iteration 2 passed; nothing has run on the host)"

**Location:** `docs/working/spike-cc-verify-q117.md:5`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "iteration 2 passed" status as of commit 190fa1a4. Does not cover the "nothing has run on the host" part, which is consistent with every other source.
**Legibility-target:** for-author

The commit that wrote this line says iteration 2 had not run yet. `git log -1 --format=%B 190fa1a4` ends its Notes with "Nothing ran on the host. Iteration 2 (the final confirming pass) follows." The only review artifacts on the branch are iteration 1's (paraphrased: no quote available because the claim concerns the absence of files; `git diff main...HEAD --stat` lists only `code-fact-check-report-cc-verify-spike.md`, `code-review-rubric-2026-10-15-cc-verify-spike.md` and `security-review-2026-10-15-cc-verify-spike.md`). This report is part of iteration 2, and it finds Incorrect claims (3, 9, 29b, 33b). The line should say that iteration 2 is pending, or be updated once it actually passes.

**Evidence:** `docs/working/spike-cc-verify-q117.md:5`, commit 190fa1a4 message, `git diff main...HEAD --stat`

---

## Claim 2: "Last verified: 2026-10-15 against main b279a2ba and `fix/egress-dnsmasq-ipset` b26d4b8b23aa (pinned in the paste); their merge tree is `65e65962b12e…`."

**Location:** `docs/working/spike-cc-verify-q117.md:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two commit ids, the pin, and the merge tree id. Does not establish that main is still at b279a2ba when the paste runs (main is resolved by name; see Residual risks).
**Legibility-target:** for-orchestrator-synthesis

`git rev-parse main fix/egress-dnsmasq-ipset` printed `b279a2ba2a8f…` and `b26d4b8b23aa05130bc9340c0c4c81ecba75897f`. The script pins `EXPECT_BR=b26d4b8b23aa05130bc9340c0c4c81ecba75897f` (spike doc :64). `git merge-tree --write-tree --name-only main fix/egress-dnsmasq-ipset` printed `65e65962b12e40d59c586aa429e580388e051cd9` and exited 0 (cwd: the worktree, 2026-10-15). The harness pass run printed the same tree (`$X/logs/pass.out`).

**Evidence:** `docs/working/spike-cc-verify-q117.md:64`, `$X/logs/pass.out`, `$X/logs/realmerge.out`

---

## Claim 3: "Everything the script creates is kept under `~/cc-verify/` and named from the run" (and the table of created items and their removal)

**Location:** `docs/working/spike-cc-verify-q117.md:13-24`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which paths and docker objects the script creates and how they are removed. Does not cover what the real devcontainer CLI writes to its own caches.
**Legibility-target:** for-author

Each listed row matches the code, and the crash and pass runs left only the logs and the script behind. The table omits two run-created paths:

```bash
# spike doc script, :135-136 (snapshot)
  local d="$V/snap-$RUN-$1" f
  mkdir -p "$d"
```
```bash
# :278
mkdir "$S.raw"
```

`snap-<RUN>-before/after` are removed by `compare` (`rm -rf -- "$b" "$a"`, :169) or by `--clean` (:204). `stage-<T8>.raw` is removed at :292 or by teardown (:125). Separately, the log row says "no tool reads it", but the script itself reads it on a register failure: `tail -n 20 "$LOG" | vis >&2` (:331). Precise version: add the `snap-<RUN>-*` and `stage-<TREE8>.raw` rows, and change the log's note to "kept; nothing reads it after the run".

**Evidence:** `docs/working/spike-cc-verify-q117.md:125,135-136,169,204,278,292,331`, `$X/logs/pass.out`, `$X/logs/crash-clean.out`

---

## Claim 4: "What the run checks at runtime (the `CHECK` lines). It compares, before and after: a hash over every file in `~/.config/claude-devcontainer`; the hashes of `manifest.sha256`, `host-tools.sha256` and `verified-live.sha256`; where `~/.local/bin/cc-isolated` and `cc-push` point; every container, volume and image tag that existed before the run."

**Location:** `docs/working/spike-cc-verify-q117.md:26-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `snapshot`/`compare` record and compare. Does not establish that a removed dangling `<none>:<none>` image is detected (it is filtered out at :160, consistent with "image tag"), or that a symlink in the config dir being repointed to identical content is detected (`sha256sum` follows links).
**Legibility-target:** for-orchestrator-synthesis

```bash
# :141-146
  for f in manifest.sha256 host-tools.sha256 verified-live.sha256; do
    if [ -e "$MAIN_CFG/$f" ]; then sha256sum < "$MAIN_CFG/$f" | sed "s|-\$|$f|" >> "$d/main"
…
  for f in cc-isolated cc-push; do echo "$f -> $(readlink -f "$MAIN_BIN/$f" 2>/dev/null || echo absent)" >> "$d/main"; done
  echo "config tree $( (cd "$MAIN_CFG" && find . \( -type f -o -type l \) -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) | sha256sum)" >> "$d/main"
```

`compare` (:149-171) prints a CHECK for `main`, for `comm -23` over containers, volumes and images, and for the verify volumes and container being gone. Executed: the pass run printed all six CHECK lines as ok. My own before/after hash of the fake config dir also matched (`cfg-unchanged`). The `djdiff`/`dfdiff` runs, which edited main's installed copies before the run, refused at step 3 before any snapshot.

**Evidence:** `docs/working/spike-cc-verify-q117.md:134-171`; executed `$X/runenv.sh $X/t1/home/claude-workflows`, cwd `$X`, exit 0, 2026-10-15T09:08:41Z, output `$X/logs/pass.out`

---

## Claim 5: "No command in the script writes `~/.claude` or your checkout's working tree. Its only operations on the checkout are `git rev-parse` and a `git clone` *from* it. It runs no branch code on the host. … there is no install, so install.sh's agent gate never runs."

**Location:** `docs/working/spike-cc-verify-q117.md:34`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the script's own commands and main's launcher (current and pre-Q-089) run against the stage with a fake devcontainer CLI. Does not establish what the real devcontainer CLI and dockerd write. Does not cover host git run by the launcher's `ws_fingerprint` (cc-isolated.sh:606) in `VERIFY-<T8>` after branch code has had write access to its `.git` (that is the workspace, not the checkout; see the doc's residual at :517). Global-config git filters (residual :515) are out of scope.
**Legibility-target:** for-orchestrator-synthesis

The only uses of the checkout are `REPO_TOP="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)"` (:221) and `git -c core.hooksPath=/dev/null clone -q --bare --no-local --template= -- "$REPO_TOP" "$SRCGIT"` (:238). Every other write targets `$V` (paraphrased: no quote available because the claim covers the absence of other write targets across the whole script; I grepped every `>`, `mkdir`, `cp`, `rm` and `git` in it). Executed: I touched a marker, ran the full pass, and ran `find $X/t1/home -newer marker -not -path '*/cc-verify*'`. It found nothing, so neither `~/.claude` nor the fake checkout was written. A sentinel variant (`$X/v-sentinel.sh`, built by `$X/mk-sentinel.py`) inserted `touch sentinel/<file>-ran` into every staged shell script and `cc-sni-proxy.py` after step 3. The run passed and created no sentinel, under both main's current launcher and the pre-Q-089 launcher (a positive control proved the injection fires).

**Evidence:** `docs/working/spike-cc-verify-q117.md:221,238`; executed `bash ~/cc-verify/spike-q117.sh <checkout>` (sentinel variant), cwd `$X`, exit 0, 2026-10-15T09:14:33Z (current launcher) and 09:14:37Z (pre-Q-089), outputs `$X/logs/sentinel-current.out`, `$X/logs/sentinel-preq089.out`

---

## Claim 6: "The block holds no shell comments outside the script, so it pastes the same into bash and zsh."

**Location:** `docs/working/spike-cc-verify-q117.md:38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash, `zsh -f`, and interactive `zsh -f -i` reading the paste from stdin. Does not cover a user's zsh rc options or a terminal's bracketed-paste behaviour.
**Legibility-target:** for-orchestrator-synthesis

The paste's first line and everything after the `CCVERIFY` terminator contain no line starting with `#` (count 0). I extracted the block with its first line retargeted to a scratch dir, then ran it with `bash` and with `zsh -f`. Both wrote a file that `cmp` found identical to the v2 script. The full, unedited paste fed to `zsh -f -i` with the fake HOME expanded `~/claude-workflows` correctly. The run printed `main=b279a2ba2a8f …` and `RESULT spike-q117 exit=0`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:40-41,394-395`; executed `zsh -f -i < $X/paste-full.txt` (fake HOME/PATH), cwd `$X`, exit 0, 2026-10-15T09:16:49Z, output `$X/logs/zsh-i.out`

---

## Claim 7: "If anything kills the run before its trap fires (a `kill -9`, …), run `bash ~/cc-verify/spike-q117.sh --clean`. The next run refuses to start until you have."

**Location:** `docs/working/spike-cc-verify-q117.md:398`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `kill -9` during step 8, the next run's refusal, and `--clean` removing that run's objects. Does not cover `--clean` against real docker.
**Legibility-target:** for-orchestrator-synthesis

After `kill -9` of the spike's PID during step 8, the fake HOME held `VERIFY-65e65962`, `run-…env`, `snap-…-before`, `src-….git` and `stage-65e65962`, plus 2 containers. The next run printed `REFUSED: a previous run left state (…run-1792055574-778315.env). Run: … --clean` (preflight :225-227). `--clean` printed `cleaning run 1792055574-778315 (tree 65e65962, project b0bb651d6c0d)` and exited 0. Only the harness's container, volume and image remained.

**Evidence:** `docs/working/spike-cc-verify-q117.md:191-207,225-227`; executed `FAKE_HANG=30 $X/runenv.sh …` killed with `kill -9`, then `$X/runenv.sh <checkout>` (exit 1) and `$X/runenv.sh --clean` (exit 0), cwd `$X`, 2026-10-15T09:12:53Z, outputs `$X/logs/crash.out`, `$X/logs/crash-rerun.out`, `$X/logs/crash-clean.out`

---

## Claim 8: "Every line the launcher or the container prints is shown indented under `  | `, with control bytes removed. So only the script's own lines can start with `RESULT`, `CHECK` or `REFUSED`."

**Location:** `docs/working/spike-cc-verify-q117.md:402`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers steps 7 and 8 (relayed) and step 6 (not relayed). Does not establish that main's launcher could ever print a line starting with RESULT/CHECK (it is main's trusted code).
**Legibility-target:** for-author

Steps 7 and 8 go through `relay` (:344, :373-374). Step 6, the launcher's `--register`, does not. Its output goes unfiltered to the log, and on failure the last 20 lines are printed without indentation:

```bash
# :330-331
CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" --register "$WS" --profile "$PROFILE" >"$LOG" 2>&1 </dev/null \
  || { tail -n 20 "$LOG" | vis >&2; die "--register failed (log above)."; }
```

On success the register output is not shown at all. Executed: in `forged.out`, every step-8 container line, including a forged `RESULT Q-117 pass (tree x)`, appears under `  | `. In the pass log, the register output (`Registered …`, manifest lines) sits in `log-<RUN>.txt` with 0 indented lines. Precise version: "every line the launcher prints in step 7, and every line the container prints, is shown indented; step 6's output goes only to the log (its last 20 lines, unindented, on a failure)."

**Evidence:** `docs/working/spike-cc-verify-q117.md:330-331,344,373-374`; executed `FAKE_EXTRA='RESULT Q-117 pass (tree x)\n\033[2Jfoo\rCHECK x: ok\n…' $X/runenv.sh <checkout>`, cwd `$X`, exit 0, 2026-10-15T09:11:48Z, output `$X/logs/forged.out`; `$X/t1/home/cc-verify/log-1792055321-754798.txt`

---

## Claim 9: "`claude-home` shows under 'differ' whenever main's installed payload predates the merged tree's; its `.manifest` alone differs."

**Location:** `docs/working/spike-cc-verify-q117.md:445`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the condition under which step 3 lists `claude-home`. Does not cover whether other claude-home files differ on a given host.
**Legibility-target:** for-author

The stage's `.manifest` can never equal one written by install.sh, so `claude-home` is listed on every run, whatever the age of main's install. The spike writes:

```bash
# :289-290
printf 'commit=%s\ndirty=no\nuncommitted_excluded=0\nassembled_from=cc-verify spike, merge tree %s of %s and %s\n' \
  "$TREE" "$TREE" "$MAIN_SHA" "$BR_SHA" > "$S/claude-home/.manifest"
```

install.sh writes `echo "commit=$commit"` (a commit id, not a tree id) and `echo "assembled_from=$REPO_ROOT"` (`devcontainer-config/install.sh:357,360`). Step 3's listing is `diff -rq "$MAIN_CFG/$i" "$S/$i" >/dev/null 2>&1 || echo "     $i"` (:309), so the `.manifest` difference alone always lists it. The trigger the doc states is wrong. The expected-output block (:412) does list `claude-home`, which matches the code. Precise version: "`claude-home` is always listed: its `.manifest` records the merge tree and this spike, not a commit and a checkout path. Any other file listed under it means main's install is behind."

**Evidence:** `docs/working/spike-cc-verify-q117.md:289-290,307-310,412,445`, `devcontainer-config/install.sh:356-361`

---

## Claim 10a: "`0`: Q-117 passed and every CHECK is ok. `2`: nothing failed, but the pool did not rotate within 45 min. … `130`: interrupted (Ctrl-C, TERM, HUP). The trap still tears down. `1`: anything else: a refusal, a Q-117 fail, a failed CHECK, or an incomplete teardown (which also prints the `--clean` fallback)."

**Location:** `docs/working/spike-cc-verify-q117.md:448-451`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exits 0, 1 (fail, refusal, exec failure, probe failure), 2 and 130 (SIGINT). Does not cover TERM/HUP separately (same trap line :232), or the "incomplete teardown" branch against real docker.
**Legibility-target:** for-orchestrator-synthesis

`on_exit` keeps the incoming status unless teardown or compare fails (`[ "$crc" = 0 ] || rc=1`, :184; `rc=1` on an incomplete teardown, :180-183). Runs: pass exited 0. `FAKE_FAILS=3` with no rotation gave `RESULT Q-117 fail` and exit 1. No rotation alone gave `RESULT Q-117 no-rotation` and exit 2. A failing `devcontainer exec` exited 1, and so did a failing `up`. SIGINT during step 8 ran the teardown, printed all CHECKs ok, and printed `RESULT spike-q117 exit=130`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:173-188,232`; executed via `$X/runenv.sh <checkout>`, cwd `$X`: pass exit 0 (09:08:41Z), fail3 exit 1 (09:11:37Z), norot exit 2 (09:11:40Z), execfail exit 1 (09:11:42Z), upfail exit 1 (09:11:45Z), `FAKE_HANG=25 timeout -s INT 12 …` printed exit=130 (09:12:33Z; timeout's own status 124); outputs `$X/logs/{pass,fail3,norot,execfail,upfail,int}.out`

---

## Claim 10b: "Exit status, also printed as `RESULT spike-q117 exit=<n>`"

**Location:** `docs/working/spike-cc-verify-q117.md:447`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which exits print the RESULT line. Does not affect the exit codes themselves.
**Legibility-target:** for-author

The RESULT line comes from `on_exit`, which is installed only at :231 (`trap on_exit EXIT`). Refusals before that point (usage, `CLAUDECODE`, `CLAUDE_DEVC_CONFIG_DIR`, missing tools, no main install, launcher mismatch, docker unreachable, leftover run record) and every `--clean` exit print no RESULT line. Executed: running with no argument printed only `REFUSED: usage: …` and exited 1. The crash rerun printed only its `REFUSED:` line. The doc's "What to paste back" (:453) does cover these with "On a refusal, the `REFUSED:` line". Precise version: "printed as `RESULT spike-q117 exit=<n>` once the run has started (a preflight refusal prints only `REFUSED:`)."

**Evidence:** `docs/working/spike-cc-verify-q117.md:191-231`; executed `$X/runenv.sh` (no args), cwd `$X`, exit 1, 2026-10-15, output `$X/logs/noargs.out`; `$X/logs/crash-rerun.out`

---

## Claim 11: "`unset GH_TOKEN OPENROUTER_API_KEY`: devcontainer.json forwards both from the launching shell into the container (`containerEnv`). A container running branch code gets neither."

**Location:** `docs/working/spike-cc-verify-q117.md:459` (and script comment :53-55)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two variables in the environment of every devcontainer CLI invocation (`up` via the launcher, and `exec`). Does not cover credentials reaching the container by other routes (none are mounted; the volumes are fresh for a new PID).
**Legibility-target:** for-orchestrator-synthesis

`"OPENROUTER_API_KEY": "${localEnv:OPENROUTER_API_KEY}"` and `"GH_TOKEN": "${localEnv:GH_TOKEN}"` are the only credential-bearing `containerEnv` entries (`devcontainer-config/devcontainer.json:116,131`), and the script runs `unset GH_TOKEN OPENROUTER_API_KEY` (:55). Executed: with `GH_TOKEN=ghp_SECRET OPENROUTER_API_KEY=sk-SECRET` exported, my fake devcontainer dumped its env on `up` and `exec`. Neither dump contains `SECRET`. A control variant with the `unset` line removed (`$X/v-nounset.sh`) leaked `GH_TOKEN` into both dumps.

**Evidence:** `devcontainer-config/devcontainer.json:82-132`, `docs/working/spike-cc-verify-q117.md:55`; executed `GH_TOKEN=… OPENROUTER_API_KEY=… $X/runenv.sh <checkout>`, cwd `$X`, exit 0, 2026-10-15T09:18:47Z, output `$X/logs/cred.out`, env dumps `$X/t1/dstate/env-{up,exec}`; control `$X/logs/cred-control.out`

---

## Claim 12: "`CLAUDECODE` mirrors install.sh's target-2 rule (decision 037). An inherited `CLAUDE_DEVC_CONFIG_DIR` would change which config is 'main's' (cc-isolated.sh:68-70)." / "install.sh links it there (install.sh:598, defaults :1310-1311)." / "a leftover `run-*.env` refuses the run"

**Location:** `docs/working/spike-cc-verify-q117.md:460-462`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited lines and the preflight checks (:210-227). Does not establish that `CLAUDECODE` stops a determined agent (install.sh itself says it does not, :77-78; the doc's residual at :518 agrees).
**Legibility-target:** for-orchestrator-synthesis

The citations match: `echo "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"` (cc-isolated.sh:69), `ln -sf "$DEST/cc-isolated.sh" "$BIN_DIR/cc-isolated"` (install.sh:598), `DEST="${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"` / `BIN_DIR="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"` (install.sh:1310-1311), and `if [ -n "${CLAUDECODE:-}" ]; then echo "Skipped host target (~/.claude): …` (install.sh:779-780). The leftover-record refusal ran in Claim 7.

**Evidence:** `devcontainer-config/cc-isolated.sh:68-70`, `devcontainer-config/install.sh:598,779-780,1310-1311`, `docs/working/spike-cc-verify-q117.md:210-227`

---

## Claim 13: "The clone copies objects and refs: no `.git/config` filters or merge drivers, no `info/attributes`, no hooks (`--template=` copies none). Those are what install.sh's `git_state_gate` refuses in the checkout (install.sh:209-252 …). The flags match `repo_git` (install.sh:180-182). The run record and this clone are the only things created before the merge check, and the trap removes both."

**Location:** `docs/working/spike-cc-verify-q117.md:463`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the clone's flags, the `G` flags matching `repo_git`, and what exists before step 1. Does not establish that the bare clone itself carries `-c core.fsmonitor=false` (it does not; with no worktree it has nothing to monitor; see Claim 33c). Does not cover global-config filters (residual :515).
**Legibility-target:** for-orchestrator-synthesis

`G=(git --no-optional-locks -C "$SRCGIT" -c core.hooksPath=/dev/null -c core.fsmonitor=false)` (:239) matches `git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"` (install.sh:181). `git_state_gate` spans install.sh:209-252 and refuses `filter.`, `core.fsmonitor`, `include`, `hook.` keys and a non-empty `info/attributes` (install.sh:208, 235). Before :236 the script creates only `run-$RUN.env` (:230) and `$SRCGIT` (:238), besides `mkdir -p "$V"`. The trap removes the clone (`rm -rf -- "$V/src-$RUN.git"`, :128) and the record (:129, only when `fail` is 0).

**Evidence:** `docs/working/spike-cc-verify-q117.md:128-129,230-239`, `devcontainer-config/install.sh:180-182,208-252`

---

## Claim 14: "the branch must resolve to the reviewed commit `b26d4b8b23aa…` (`EXPECT_BR`) … A ref moved in the checkout's `.git` … refuses the run"

**Location:** `docs/working/spike-cc-verify-q117.md:464`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch pin. Does not pin `main` (stated at :466 and :513).
**Legibility-target:** for-orchestrator-synthesis

`[ "$BR_SHA" = "$EXPECT_BR" ] || die "$BRANCH is at $BR_SHA, not the reviewed $EXPECT_BR. Ask for a refreshed paste."` (:242). A variant with `EXPECT_BR=000…0` refused at step 1 with that message and exit 1. Only `spike-q117.sh` was left in `~/cc-verify`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:242`; executed `bash ~/cc-verify/spike-q117.sh <checkout>` (`$X/v-moved.sh`), cwd `$X`, exit 1, 2026-10-15T09:13:25Z, output `$X/logs/moved.out`

---

## Claim 15: "`git merge-tree --write-tree --name-only main <branch>`: exit 1 refuses and lists the conflicts; any other non-zero refuses as 'needs git ≥ 2.38' … today the merge is clean (tree `65e65962…`, the same tree a real `git merge` produces), and `feat/q125-cc-isolated-sandbox` is refused on `hooks/live-verify-gate.sh`."

**Location:** `docs/working/spike-cc-verify-q117.md:465`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-code dispatch (:247-251), the clean tree, real-merge equality, and the q125 refusal. Does not exercise the exit-2+ path (git 2.39.5 here).
**Legibility-target:** for-orchestrator-synthesis

In a scratch `--no-local` clone, `git checkout -B m origin/main && git merge origin/fix/egress-dnsmasq-ipset` gave tree `65e65962b12e40d59c586aa429e580388e051cd9`. A variant with `BRANCH=feat/q125-cc-isolated-sandbox` and its own `EXPECT_BR` refused with `CONFLICT (content): Merge conflict in hooks/live-verify-gate.sh` and `REFUSED: feat/q125-cc-isolated-sandbox does not merge cleanly with main`. Across that run and the moved-branch run, the fake docker's call log shows only `docker info;docker info;`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:243-253`; executed `git merge` in `$X/merge.*/r`, exit 0, 2026-10-15, output `$X/logs/realmerge.out`; variant `$X/v-conflict.sh`, cwd `$X`, exit 1, 2026-10-15T09:13:26Z, output `$X/logs/conflict.out`

---

## Claim 16: "`git diff-tree -r --name-only <main> <tree>` may list only the branch's five paths"

**Location:** `docs/working/spike-cc-verify-q117.md:466` (script :65-70, :254-259)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule and that the five paths equal the branch's diff. Does not cover paths git would C-quote (they would fail the `grep -qxF` and refuse, which is fail-closed).
**Legibility-target:** for-orchestrator-synthesis

`grep -qxF -- "$f" <<< "$BRANCH_PATHS" || die "the merge changes $(printf %q "$f"), which is not one of the branch's reviewed paths."` (:258). `git diff --name-only main...fix/egress-dnsmasq-ipset` and `git diff-tree -r --name-only main 65e65962` both list exactly the five `BRANCH_PATHS` entries. A variant that dropped `test/init-firewall-rules.bats` from the list refused with `REFUSED: the merge changes test/init-firewall-rules.bats, which is not one of the branch's reviewed paths.`

**Evidence:** `docs/working/spike-cc-verify-q117.md:65-70,254-259`; executed `$X/v-4paths.sh`, cwd `$X`, exit 1, 2026-10-15, output `$X/logs/fourpath.out`

---

## Claim 17: "refuses unless the merged tree's `install.sh` has exactly the `PAYLOAD=(…)` and `CLAUDE_HOME_SRC=(…)` lines …, read into a variable first … install.sh:110 and :135. The variable avoids SIGPIPE: install.sh is larger than a pipe buffer, and the review reproduced spurious refusals with the pipe"

**Location:** `docs/working/spike-cc-verify-q117.md:467` (script :271-277)
**Type:** Error-handling / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the install.sh read only. Does not cover the script's other `producer | grep -q` pipes under pipefail. `! docker volume ls -q … | grep -q "^cc-$PID-" || die` (:322) and `if docker volume ls -q … | grep -q "^cc-$PID-"` (:163) keep the same shape. They would misreport only when `docker volume ls` writes more than a pipe buffer after the match, and the doc does not claim them.
**Legibility-target:** for-orchestrator-synthesis

The citations match: install.sh:110 is the `PAYLOAD=(…)` line and :135 the `CLAUDE_HOME_SRC=(…)` line, both byte-equal to `EXPECT_PAYLOAD`/`EXPECT_HOME_SRC`. `git show 65e65962:devcontainer-config/install.sh | wc -c` gives 65632, which is more than 65536. Executed under `set -o pipefail`: the pipe form failed 200 times out of 200 (`PIPESTATUS=141 0`: git was killed by SIGPIPE after grep matched), and the variable form `inst="$(git show …)"; grep -qxF "$1" <<< "$inst"` failed 0 times out of 200.

**Evidence:** `devcontainer-config/install.sh:110,135`, `docs/working/spike-cc-verify-q117.md:273-277`; executed `bash -c 'set -o pipefail; …'` loop, cwd `/workspace/.claude/wt-branch-verify`, exit 0, 2026-10-15, output `$X/logs/sigpipe.out`

---

## Claim 18: "The same sources and the same no-symlink rule as `extract_commit` (install.sh:257-317, the symlink refusal at :288)."

**Location:** `docs/working/spike-cc-verify-q117.md:468`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the source paths and the symlink refusal. Does not cover extract_commit's other rules, which the spike does not copy and the doc does not claim: `tar.umask=022` with `tar -p` (install.sh:279-280) and the NUL-byte refusal (:302-316).
**Legibility-target:** for-orchestrator-synthesis

The spike archives `devcontainer-config global-instructions/CLAUDE.md "${HOME_DIRS[@]}"` (:279) and refuses with `[ -z "$(find "$S.raw" -type l -print -quit)" ] || die …` (:281). Its check covers the whole `devcontainer-config` dir, which is wider than install.sh's payload items. install.sh's symlink block begins at :288 with the comment `# No symlinks (review R1).` and its `find . -type l` check is at :291-297.

**Evidence:** `docs/working/spike-cc-verify-q117.md:279-281`, `devcontainer-config/install.sh:257-317`

---

## Claim 19: "layout: the 10 PAYLOAD files and dirs at the stage root, `claude-home/` …, a `.manifest`, `chmod +x` on three scripts | Matches `install_devcontainer` (install.sh:471-508), `assemble`'s `.manifest` keys (:356-361) and install.sh:596. The Dockerfile copies `claude-home/` (Dockerfile:500), `egress/` (:486) and the scripts (:487-491) …, which is `CC_CONFIG_DIR` (devcontainer.json:24-26). The review checked that the current launcher and the pre-Q-089 launcher both bless and check a stage built this way."

**Location:** `docs/working/spike-cc-verify-q117.md:469`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the layout, the citations, and bless plus check_manifest under both launchers with the fake CLI. Does not establish file modes matching install.sh's (no claim made).
**Legibility-target:** for-orchestrator-synthesis

The citations match: `COPY egress/ /usr/local/share/cc-egress/` (Dockerfile:486), `COPY init-firewall.sh`/`cc-sni-proxy.py`/`link-claude-home.sh` (Dockerfile:487-491), `COPY claude-home/ /opt/claude-workflows/` (Dockerfile:500), `"dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile", "context": "${localEnv:CC_CONFIG_DIR}"` (devcontainer.json:25-26), `chmod +x "$DEST/cc-isolated.sh" "$DEST/cc-push.sh" "$DEST/init-firewall.sh"` (install.sh:596), and the `.manifest` keys `commit`/`dirty`/`uncommitted_excluded`/`assembled_from` (install.sh:357-360). `DC_ITEMS` is PAYLOAD minus `claude-home`, 10 items. Executed: with main's current launcher and with the pre-Q-089 launcher (`626dc300^1`, installed and re-blessed in my fake config), `--register`, the bless, `check_manifest` and `probe_boundary` all passed against the stage. Both runs ended `RESULT spike-q117 exit=0`.

**Evidence:** `devcontainer-config/Dockerfile:486-491,500`, `devcontainer-config/devcontainer.json:24-26`, `devcontainer-config/install.sh:356-361,471-508,596`; executed pre-Q-089 run, cwd `$X`, exit 0, 2026-10-15T09:13:42Z, output `$X/logs/preq089.out`; current run `$X/logs/pass.out`

---

## Claim 20: "refuses if the staged `devcontainer.json` names `initializeCommand`, or if the staged `devcontainer.json` **or `Dockerfile`** differs at all from main's installed copy (shows `diff -u`) … devcontainer.json carries runArgs (devcontainer.json:58-69), mounts (:77-80) and lifecycle commands."

**Location:** `docs/working/spike-cc-verify-q117.md:470`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the whole-file pin of both files and the citations. Does not exercise the `initializeCommand` grep (it is unreachable while devcontainer.json is pinned and main's copy lacks it). Does not establish the base-image metadata-label behaviour (listed as Not verified #7).
**Legibility-target:** for-orchestrator-synthesis

`for i in "${PINNED[@]}"; do if ! cmp -s "$MAIN_CFG/$i" "$S/$i"; then diff -u … | vis || true; die …` (:299-304), with `PINNED=(devcontainer.json Dockerfile)` (:74). The runArgs block is devcontainer.json:58-69 and the mounts are :77-80. Executed: adding `"--privileged"` to main's installed devcontainer.json produced `REFUSED: the staged devcontainer.json differs …` with the `-/+` diff. Appending `RUN true` to main's installed Dockerfile produced `REFUSED: the staged Dockerfile differs …`. Both exited 1. These tests varied main's copy rather than the stage, which reaches the same `cmp`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:74,294-305`, `devcontainer-config/devcontainer.json:58-80`; executed cwd `$X`, exit 1, 2026-10-15T09:13:27Z and 09:13:28Z, outputs `$X/logs/djdiff.out`, `$X/logs/dfdiff.out`

---

## Claim 21: "`resolve_workspace` uses `git rev-parse --show-toplevel` (cc-isolated.sh:354-367), and `project_id` is that exact pipeline (cc-isolated.sh:372-374). The display name is `basename` … (cc-isolated.sh:814 → devcontainer.json:22) … The launcher selects the container by `--id-label cc-project=$pid` (cc-isolated.sh:836) and names volumes `cc-${CC_PROJECT_ID}-…` (devcontainer.json:78-79). With a fresh PID, `--remove-existing-container` (cc-isolated.sh:883) can only hit this run's container."

**Location:** `docs/working/spike-cc-verify-q117.md:471-472`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the identity derivation and the freshness checks (:316-322). Does not cover real docker's label-filter semantics.
**Legibility-target:** for-orchestrator-synthesis

`printf '%s' "$1" | sha256sum | cut -c1-12` (cc-isolated.sh:373) is the same pipeline as `verify_pid` (:96). The other citations match: `CC_PROJECT_NAME="$(basename "$ws")"` (cc-isolated.sh:814), `--id-label "cc-project=$pid")` (:836), `devcontainer up --remove-existing-container "${dc[@]}"` (:883), and the volume sources `cc-${localEnv:CC_PROJECT_ID}-bashhistory`/`-claude-config` (devcontainer.json:78-79). Executed: the launcher wrote `$S/projects/b0bb651d6c0d.profile`, the PID the script computed (otherwise :332-333 would have refused).

**Evidence:** `devcontainer-config/cc-isolated.sh:354-374,814,834-836,883`, `devcontainer-config/devcontainer.json:22,78-79`, `docs/working/spike-cc-verify-q117.md:312-323`; `$X/logs/pass.out`

---

## Claim 22: "Flag syntax: cc-isolated.sh:9-11 and :736; guide `cc-isolated-usage.md:23,537`. `register_project` checks `$(config_dir)/egress/android.txt`, writes `$(config_dir)/projects/<pid>.profile` and re-blesses (cc-isolated.sh:434-480). `bless_manifest` writes only under `config_dir` (cc-isolated.sh:281-319)."

**Location:** `docs/working/spike-cc-verify-q117.md:474`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited functions' file writes. Does not cover their stdout content.
**Legibility-target:** for-orchestrator-synthesis

The citations match: `cc-isolated --register ~/code/api --profile python` (cc-isolated.sh:9), `--register)   action="register"; shift ;;` (:736), and guide lines 23 and 537 (`--register … --profile python` / `--profile android`). `register_project` (cc-isolated.sh:434-479) tests `-r "$(config_dir)/egress/$p.txt"` (:440), writes `"$(projects_dir)/$pid.profile"` (:458) and calls `bless_manifest` (:476). `bless_manifest` writes only `mktemp "$(config_dir)/.manifest.XXXXXX"`/`.host-tools.XXXXXX` and moves them to `host_tools_path`/`manifest_path`, both under `config_dir` (:284-285, :303-304).

**Evidence:** `devcontainer-config/cc-isolated.sh:9-11,281-319,434-480,736`, `guides/cc-isolated-usage.md:23,537`

---

## Claim 23: "after the bless, the stage manifest's `devcontainer.json` and `Dockerfile` hashes must equal main's installed copies'; stage hash = `sha256sum < stage/manifest.sha256 | cut -c1-16` | Closes the window between step 3 and the bless … The hash is `blessed_hash` (cc-isolated.sh:88-93)."

**Location:** `docs/working/spike-cc-verify-q117.md:475` (script :334-341)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the awk lookup against the manifest's line format and the refusal of a stage edit made between step 3 and the bless. Does not cover a swap after `check_manifest` (accepted residual :514).
**Legibility-target:** for-orchestrator-synthesis

The manifest is `sha256sum` output, `<hash>  <path>` (cc-isolated.sh:184, sorted at :188). awk's default whitespace splitting therefore makes `$2` the path, so `awk -v f="$i" '$2 == f { print $1 }'` (:338) finds it. The pass run proves the lookup returns a non-empty, matching hash, since an empty `have` would refuse. A variant that appended `RUN true` to `$S/Dockerfile` after step 3 refused with `REFUSED: the stage's blessed Dockerfile is not main's installed copy (changed after step 3).` and exit 1. `HASH="$(sha256sum < "$S/manifest.sha256" | cut -c1-16)"` (:341) is the same as `sha256sum < "$m" | cut -c1-16` (cc-isolated.sh:92).

**Evidence:** `docs/working/spike-cc-verify-q117.md:334-341`, `devcontainer-config/cc-isolated.sh:88-93,183-188`; executed `$X/v-postedit.sh`, cwd `$X`, exit 1, 2026-10-15T09:16:58Z, output `$X/logs/postedit.out`

---

## Claim 24: "Main's launcher loads host code only from its own directory (cc-isolated.sh:714-718), and so did the pre-Q-089 launcher (`source "$(dirname …BASH_SOURCE…)/cc-exit-scan.sh"`). So the stage's copies of `cc-isolated.sh` and the host tools are hashed but never executed. … The review confirmed that the launcher, run against the stage, executes no staged file and writes only under it."

**Location:** `docs/working/spike-cc-verify-q117.md:476`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher script itself (current and pre-Q-089) under `--register` and `--probe-only` with a fake devcontainer CLI. Does not cover what the real devcontainer CLI or dockerd write (their caches, images, volumes). The doc lists the real CLI as Not verified #2.
**Legibility-target:** for-orchestrator-synthesis

`CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"` … `source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` (cc-isolated.sh:714-718). `git show 626dc300^1:devcontainer-config/cc-isolated.sh` has `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-exit-scan.sh"` at its line 562. The pre-Q-089 file's writes are `$(verified_path)`, `$(manifest_path)` and `$(projects_dir)/$pid.profile` (its lines 114, 195, 336). Its `mktemp` (line 657) runs only for `action = launch`. Executed: in the sentinel runs (Claim 5), no staged file ran under either launcher, and nothing under the fake HOME outside `~/cc-verify` changed.

**Evidence:** `devcontainer-config/cc-isolated.sh:113-115,281-319,714-718,842-886`, `git show 626dc300^1:devcontainer-config/cc-isolated.sh` lines 114,195,336,562,657; `$X/logs/sentinel-current.out`, `$X/logs/sentinel-preq089.out`

---

## Claim 25: "Exactly the five variables `rebuild_hint` says the by-hand CLI needs (cc-isolated.sh:561-563), and the same `dc` args the launcher uses (:834-836). `bash -c` with the block as one argument is how the probe runs in-container scripts (cc-isolated.sh:608). stdin is `/dev/null`"

**Location:** `docs/working/spike-cc-verify-q117.md:478`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the correspondence with the launcher's code and the values exported. Does not establish the real CLI's `exec` behaviour with them (Not verified #3, #4).
**Legibility-target:** for-orchestrator-synthesis

`for var in CC_PROJECT_ID CC_PROJECT_NAME CC_CONFIG_DIR CC_EGRESS_PROFILE CC_CONFIG_HASH; do` (cc-isolated.sh:562) names the same five the script exports (:372). The values agree with what the launcher sets at :813-821 and :831: `PID`, `VERIFY-$T8` (= `basename "$ws"`), `$S` (= `config_dir`), `android` (= the `.profile` content), and `$HASH` (= `blessed_hash`). The dc args are `--workspace-folder "$WS" --override-config "$S/devcontainer.json" --id-label "cc-project=$PID"` with `</dev/null` (:373-374). Line 608 is `actual_fp="$(devcontainer exec "${dc[@]}" bash -c '`.

**Evidence:** `devcontainer-config/cc-isolated.sh:557-567,608,813-836`, `docs/working/spike-cc-verify-q117.md:372-375`

---

## Claim 26: "Q-117's container block, verbatim | questions-archive.md:2463-2475 (byte for byte). It runs as `remoteUser: node` (devcontainer.json:71). … `/run/cc-sni-proxy` is 0755 (`init-firewall.sh:1392-1393` on the branch) and the log is opened 0644 (`cc-sni-proxy.py:260`). The `ALLOW sni=… -> <ip>:<port>` field order is the proxy's (`cc-sni-proxy.py:207`). dl.google.com is only in `egress/android.txt`."

**Location:** `docs/working/spike-cc-verify-q117.md:479`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte equality and the cited lines on `fix/egress-dnsmasq-ipset`. Does not establish that `devcontainer exec` defaults to `remoteUser` (CLI behaviour; main's probe relies on the same).
**Legibility-target:** for-orchestrator-synthesis

I extracted the script's `Q117BLOCK` body and `sed -n 2463,2475p docs/working/questions-archive.md`. `cmp` reports them byte-identical (13 lines each). On the branch: `mkdir -p "$SNI_RUN_DIR"` / `chmod 0755 "$SNI_RUN_DIR"` (init-firewall.sh:1392-1393, with `SNI_RUN_DIR="${CC_SNI_RUN_DIR:-/run/cc-sni-proxy}"` at :771). cc-sni-proxy.py has `log_fd = os.open(args.log, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)` (:260) and `log(f"ALLOW sni={sni} -> {ip}:{upstream_port} orig_dst={orig}")` (:207). `"remoteUser": "node"` is devcontainer.json:71. `git grep dl.google.com 65e65962 -- devcontainer-config/egress/` matches only `android.txt` (line 33 is the entry).

**Evidence:** `docs/working/questions-archive.md:2463-2475`, `devcontainer-config/devcontainer.json:71`, `fix/egress-dnsmasq-ipset:devcontainer-config/init-firewall.sh:771,1392-1393`, `fix/egress-dnsmasq-ipset:devcontainer-config/cc-sni-proxy.py:207,260`; executed `cmp $X/q117-script.txt $X/q117-archive.txt`, cwd worktree, exit 0, 2026-10-15

---

## Claim 27: "launcher and container output goes through `relay`: control bytes (all but tab and newline) are dropped, and each line is shown under `  | ` … its output cannot rewrite the terminal, set the clipboard through OSC 52, or print a line that looks like the script's `RESULT`/`CHECK`" (and: the verdict parsing still sees unindented lines; `| relay >> "$LOG"` and `$(… | relay)` keep pipefail semantics)

**Location:** `docs/working/spike-cc-verify-q117.md:480` (script :84-87, :344-345, :373-375)
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers steps 7 and 8, C0 control bytes and DEL, unindented stdout for the verdict, and failure propagation through both pipelines. Does not cover 8-bit C1 bytes (accepted residual :516) or step 6 (Claim 8).
**Legibility-target:** for-orchestrator-synthesis

`vis() { LC_ALL=C tr -d '\000-\010\013-\037\177'; }` and `relay() { … printf '  | %s\n' "$l" >&2; printf '%s\n' "$l"; done; }` (:84, :87). Executed: the forged lines `RESULT Q-117 pass (tree x)` and `\033[2Jfoo\rCHECK x: ok` appeared as `  | RESULT Q-117 pass (tree x)` and `  | [2JfooCHECK x: ok`, with ESC and CR removed. The real verdict line followed. The verdict greps on the unindented `$out`: pass, fail and no-rotation all came out right. On pipefail, a failing `devcontainer up` inside the launcher (step 7, `… | relay >> "$LOG" || die`) gave `REFUSED: --probe-only failed`. A failing exec (step 8, `out="$(… | relay)" || die`) gave `REFUSED: devcontainer exec of the Q-117 block failed.` Both exited 1 with teardown and all CHECKs ok.

**Evidence:** `docs/working/spike-cc-verify-q117.md:84-87,344-345,373-375`; executed cwd `$X`: forged exit 0 (09:11:48Z), upfail exit 1 (09:11:45Z), execfail exit 1 (09:11:42Z); outputs `$X/logs/{forged,upfail,execfail}.out`

---

## Claim 28: "verdict = Q-117's own rule: 2 instances, both fetches 200, 0 FAIL lines, the first ALLOW address absent from 'pool now'. `no-rotation` (exit 2) applies only when nothing else failed | questions-archive.md:2478."

**Location:** `docs/working/spike-cc-verify-q117.md:481` (script :377-393)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule's mapping and its ordering. Does not establish a verdict when the container forges its own lines (the code under test attests itself, an accepted residual at :512).
**Legibility-target:** for-orchestrator-synthesis

Archive :2478 reads: `**Pass** = 2 instances, both fetches 200, 0 FAIL lines, and "pool now" no longer lists the first ALLOW address.` The script runs `if [ "$v" = pass ] && printf ' %s ' "$pool" | grep -qF " $first "; then v=no-rotation; fi` (:387). Executed: three FAIL lines plus an unrotated pool gave `RESULT Q-117 fail` and exit 1. An unrotated pool alone gave `no-rotation` and exit 2.

**Evidence:** `docs/working/questions-archive.md:2478`, `docs/working/spike-cc-verify-q117.md:377-393`; `$X/logs/fail3.out`, `$X/logs/norot.out`

---

## Claim 29a: "Removes the label's containers, then the two named volumes, then the containers' images (only if new and unused), then images tagged `verify-<TREE8>`, then the stage, workspace and clone. Every name is derived from `RUN` and `TREE8`, format-checked; the project id is recomputed … It cannot point `docker rm` or `volume rm` at another project"

**Location:** `docs/working/spike-cc-verify-q117.md:482` (script comment :91-93)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the removal order, the format checks, and containers and volumes. Does not cover the image tag rule (Claim 29b).
**Legibility-target:** for-orchestrator-synthesis

The guards are `if [[ "$T8" =~ ^[0-9a-f]{8}$ ]] && [ -n "$VP" ]; then pid="$(verify_pid "$T8")"` (:100-101), `if [[ "$RUN" =~ ^[0-9]+-[0-9]+$ ]]` (:127), and in `--clean` the anchored `sed -n 's/^RUN=\([0-9]*-[0-9]*\)$/\1/p'` / `'s/^T8=\([0-9a-f]\{8\}\)$/\1/p'` (:199-200). The container and volume names therefore always derive from `VERIFY-<8 hex>` under `$VP`. Executed: a planted `run-1-1.env` with `T8=deadbeef` resolved to project `33d087a3504d`. It removed no container or volume, and the harness's `cc-aaaaaaaaaaaa-*` survived.

**Evidence:** `docs/working/spike-cc-verify-q117.md:94-132,191-207`; executed `$X/runenv.sh --clean`, cwd `$X`, exit 0, 2026-10-15T09:12:11Z, output `$X/logs/planted.out`, docker call log `$X/t1/dstate/calls`

---

## Claim 29b: "It cannot point … `image rm` at an image no verify container ran (review fact-check claim 24b, security F4; reproduced before the fix, re-tested after)." (with the script comment :119-120: "a tag naming this run's folder is this run's, whoever else is building meanwhile")

**Location:** `docs/working/spike-cc-verify-q117.md:482`, `:119-124`
**Type:** Invariant / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tag rule in teardown, reached from `--clean` with a planted record or from a normal run. Does not establish how likely it is that a host image carries such a tag. Does not cover real `docker image rm -f <id>` untagging every other tag on that id.
**Legibility-target:** for-author

The tag rule is a substring match over every image on the host, and a planted record chooses `T8` freely:

```bash
# :121-124
    while read -r i tags; do
      [ -n "$i" ] || continue
      case "$tags" in *verify-"$T8"*) docker image rm -f "$i" >/dev/null </dev/null || fail=1 ;; esac
    done < <(docker image ls --no-trunc --format '{{.ID}} {{.Repository}}:{{.Tag}}' </dev/null | tr 'A-Z' 'a-z')
```

Executed: I added `myproj-verify-deadbeef:latest` (an image no container ever ran) and `unrelated:latest` to the fake docker, then planted `run-1-1.env` holding `RUN=1-1` and `T8=deadbeef`. `--clean` exited 0 and the call log shows `docker image rm -f sha256:d929…` (the myproj image), which was removed. `unrelated:latest` survived. So a planted record can force-remove any image whose lower-cased `repo:tag` contains `verify-<8 hex>`, with no "new" or "unused" guard on this rule. Precise version: "…or `image rm` at an image no verify container ran, except one whose tag contains `verify-<8 hex>`: the tag rule removes those by id." Alternatively, anchor the match to the CLI's actual tag form once Not-verified #1 is settled.

**Evidence:** `docs/working/spike-cc-verify-q117.md:119-124,199-203`; executed `$X/runenv.sh --clean` with the planted record, cwd `$X`, exit 0, 2026-10-15T09:12:11Z, output `$X/logs/planted.out`, call log `$X/t1/dstate/calls` (last `docker image rm -f` lines)

---

## Claim 30: "What was tested here, without a host" (pass path; refusals: conflict with no docker call besides `docker info`, moved branch, devcontainer.json and Dockerfile differences; failures; forged output; planted run record removed nothing; crash and `--clean`; `bash -n` and `shellcheck -S warning` clean; byte-for-byte round-trip under bash and `zsh -f`)

**Location:** `docs/working/spike-cc-verify-q117.md:484-497`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed test as re-run in my own harness copy. The "planted run record removed nothing" item is true for the record it describes (one naming the harness's project id and image, which the format checks ignore). It does not extend to a planted `T8` combined with a `verify-<T8>`-tagged image (Claim 29b).
**Legibility-target:** for-orchestrator-synthesis

Re-run results: pass exited 0 with every CHECK ok and the harness objects intact. The conflict run refused at step 1, making only the `docker info` call. The moved branch refused. The devcontainer.json and Dockerfile differences each refused with a diff. Fail plus no rotation gave fail and exit 1, and no rotation alone gave exit 2. Forged lines were indented and stripped. Kill -9, refuse, `--clean` left the harness objects. `bash -n` exited 0 and `shellcheck -S warning` exited 0 with no findings. The round-trip was `cmp`-identical under bash and `zsh -f` (Claim 6). The harness's fake docker ignores `--format` for `ps`, so the snapshot's `{{.ID}} {{.Names}}` format against real docker is untested (paraphrased: no quote available because this is about the stub's case arms in `setup-t.sh`, which match on `ps` and drop `--format`).

**Evidence:** `docs/working/spike-cc-verify-q117.md:484-497`; `$X/logs/{pass,conflict,moved,djdiff,dfdiff,fail3,norot,forged,crash-clean,shellcheck}.out`; `bash -n $X/spike-q117.sh` exit 0, `timeout 60 shellcheck -S warning $X/spike-q117.sh` exit 0, cwd `$X`, 2026-10-15

---

## Claim 31: "Not verified (needs the host run)" list (items 1-8) as the complete set of unobserved assumptions

**Location:** `docs/working/spike-cc-verify-q117.md:499-508`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether host-dependent assumptions in the script appear in the list. Does not judge whether each listed item will hold on the host.
**Legibility-target:** for-author

Each listed item is a real assumption, correctly described. Not listed:
- (a) `docker image rm -f <id>` in the tag rule removes the image by id, so every tag on that id goes with it. If a `verify-<T8>` tag lands on an id that already carried another tag, the earlier tag is removed too. Item 1 covers only a retag being detected by the CHECK after the fact.
- (b) The tag rule's substring breadth (Claim 29b).
- (c) Real docker's output for `docker ps -a --no-trunc --format '{{.ID}} {{.Names}}'`, `docker volume ls -q` and `--filter label=` combined with `-aq --no-trunc`, all used by the snapshot and teardown. The stub ignores `--format` for `ps` (Claim 30).
- (d) `devcontainer exec` defaulting to `remoteUser: node` (stated as fact at :479).

All four are paraphrased: no quote available because they concern behaviour of external tools the script calls at :102-124, :137-139 and :373, not text in the doc.

**Evidence:** `docs/working/spike-cc-verify-q117.md:102-124,137-139,373,479,499-508`

---

## Claim 32: Commit 12fcb61c message — "stages `git merge-tree --write-tree main fix/egress-dnsmasq-ipset` from a bare scratch clone, refusing on conflict before anything else exists; … a --clean fallback driven by a format-checked run record. Each step is cited to file:line. … pass, conflict refusal, devcontainer.json refusal, Q-117 fail, no-rotation and kill -9 + --clean all behaved as documented."

**Location:** commit 12fcb61c
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the message against the 12fcb61c version of the script (`git show 12fcb61c:docs/working/spike-cc-verify-q117.md`, identical to the brief's harness `spike-q117.sh`). Does not re-litigate iteration 1's findings against that version (R1-R5), which 190fa1a4 supersedes.
**Legibility-target:** for-author

The bullet list matches that version. Its `--clean` does format-check the record (anchored `sed` for RUN, T8, PID and IMG), and its pass path exited 0 in my harness. The imprecise part is "refusing on conflict before anything else exists". In that version, `printf 'RUN=%s\n' "$RUN" > "$V/run-$RUN.env"` and `git clone -q --bare --no-local -- "$REPO_TOP" "$SRCGIT"` both run before the merge check (12fcb61c script lines 157 and 165). Precise version: "before the stage, workspace or any docker object exists".

**Evidence:** `git show 12fcb61c:docs/working/spike-cc-verify-q117.md` (script lines 117-135, 157-165); executed v1 pass, cwd `$X`, exit 0, 2026-10-15T09:17:22Z, outputs `$X/logs/v1-pass-*.out` (the `bash -x` trace ended `RESULT spike-q117 exit=0`)

---

## Claim 33a: Commit 190fa1a4 message — fixes R1, R2, R4/F1, R5/F2, A1/F3, A2/F6, A3/F8, A6, A8 as described, and "re-tested in the stub harness … shellcheck clean. The paste round-trips under bash and zsh -f, and interactive zsh reaches preflight with the right argument."

**Location:** commit 190fa1a4
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named fix's behaviour in the harness. Does not cover R3/F4's image clause (33b) or A7's fsmonitor wording (33c).
**Legibility-target:** for-orchestrator-synthesis

- R1: Claim 17.
- R2: Claim 28.
- R4/F1: Claim 20.
- R5/F2: Claims 14 and 16.
- A1/F3: Claim 23.
- A2/F6: Claim 11.
- A3/F8: Claim 27.
- A6: `snapshot` hashes the whole config dir (Claim 4), and the doc has the runtime/by-construction split (doc :26-34).
- A8: no `#` lines outside the heredoc (Claim 6).
- Interactive zsh: the full paste fed to `zsh -f -i` reached and passed preflight with `~/claude-workflows` expanded to the fake checkout (Claim 6).

**Evidence:** commit 190fa1a4 message; `$X/logs/{sigpipe,norot,fail3,djdiff,dfdiff,moved,fourpath,postedit,cred,forged,zsh-i}.out`

---

## Claim 33b: Commit 190fa1a4 message — "R3/F4: the run record holds only RUN and T8. The project id is recomputed from ~/cc-verify/VERIFY-<T8>, images come only from this run's containers (and only if new and unused), so a planted record cannot steer docker rm, volume rm or image rm."

**Location:** commit 190fa1a4
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "images come only from this run's containers" and "cannot steer … image rm" clauses. The RUN/T8-only record and the docker rm/volume rm clauses are Verified (Claim 29a).
**Legibility-target:** for-author

Teardown has a second image source that the message omits: the `*verify-"$T8"*` tag rule (:119-124). It has no "new" or "unused" guard and is driven by the record's `T8`. Executed (Claim 29b): a planted `T8=deadbeef` record made `--clean` force-remove `myproj-verify-deadbeef:latest`, an image no container ran. Precise version: "images come from this run's containers (only if new and unused) and from tags containing `verify-<T8>`; a planted record can steer the latter."

**Evidence:** `docs/working/spike-cc-verify-q117.md:112-124`; `$X/logs/planted.out`, `$X/t1/dstate/calls`

---

## Claim 33c: Commit 190fa1a4 message — "A7: the clones use --template= with hooks and fsmonitor off; --no-optional-locks is added."

**Location:** commit 190fa1a4
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the flags on the two `git clone` calls and the `G` array. Does not establish any practical exposure from the omission (a bare clone has no worktree, so fsmonitor has nothing to run on).
**Legibility-target:** for-author

The workspace clone has both flags: `git -c core.hooksPath=/dev/null -c core.fsmonitor=false clone -q --no-local --template= …` (:314). The first, bare clone has only `git -c core.hooksPath=/dev/null clone -q --bare --no-local --template= …` (:238), with no fsmonitor flag. `--no-optional-locks` is in `G` (:239). The doc's own table row (:463) quotes :238 accurately. Only the commit message generalises. Precise version: "both clones use --template= with hooks off; the workspace clone and all later git calls also turn fsmonitor off."

**Evidence:** `docs/working/spike-cc-verify-q117.md:238-239,314`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/working/spike-cc-verify-q117.md:5`): says "review loop iteration 2 passed", but the commit says iteration 2 follows, and this iteration finds Incorrect claims. Change it to pending until a pass is recorded.
- **Claim 9** (`docs/working/spike-cc-verify-q117.md:445`): `claude-home` is always listed under "differ", because the spike's `.manifest` (tree id, "cc-verify spike") never equals install.sh's (commit id, checkout path). It is not tied to main's install being behind.
- **Claim 29b** (`docs/working/spike-cc-verify-q117.md:482`, `:119-124`): the `*verify-<T8>*` tag rule lets a planted record force-remove any image whose tag contains `verify-<8 hex>`. This was reproduced with `myproj-verify-deadbeef:latest`. Qualify the claim or anchor the match.
- **Claim 33b** (commit 190fa1a4, R3/F4): "images come only from this run's containers … cannot steer image rm" omits the tag rule, which a planted record does steer.

### Stale
- none

### Mostly Accurate
- **Claim 3** (`:13-24`): the created-items table omits `snap-<RUN>-before/after` and `stage-<TREE8>.raw`. The log is read by the script on a register failure.
- **Claim 8** (`:402`): step 6's launcher output is not relayed. It goes to the log, and on failure its last 20 lines print unindented.
- **Claim 10b** (`:447`): preflight refusals and `--clean` print no `RESULT spike-q117 exit=` line.
- **Claim 31** (`:499-508`): Not-verified list lacks `image rm -f <id>` removing every tag on that id, the tag rule's substring breadth, real-docker output formats the stub ignores, and `exec`'s default user.
- **Claim 32** (commit 12fcb61c): "before anything else exists". The run record and the bare clone already exist at that point.
- **Claim 33c** (commit 190fa1a4, A7): the bare clone has no `core.fsmonitor=false` (harmless: it has no worktree).

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to the path named at the end of this prompt, structured per the code-fact-check skill, with a `**Commit:** 190fa1a4` line at the top.
- Answered: yes. All six focus areas are covered. Every file:line citation was checked (all accurate). Each iteration-1 fix was re-run in my own harness copy, including the planted-record attack, the post-bless manifest check, credential unset with a control, both pipefail relay paths, the SIGPIPE reproduction, and both launchers with staged-file sentinels.
- Out of scope: real docker/devcontainer/dockerd behaviour (no host; the sandbox has no docker); a fresh security assessment of the tag rule's exploitability (security-reviewer's domain); appending to hallucination-patterns.md (no fabrication found, and the brief makes this run read-only apart from the report).
- Escalate: Claim 29b/33b. The planted-record guarantee for images is overstated, reproduced in the harness. Claim 1: the doc says iteration 2 passed before it has.
- Decisions I made: tested the step-3 pin by editing main's installed copies rather than the stage (the same `cmp`). Treated "--clean and the trap cannot be steered" as covering the tag rule, since the doc's sentence names `image rm` without exception. Verdicted the 12fcb61c message against its own superseded script version.
