# Code Fact-Check Report

**Commit:** 190fa1a4
**Repository:** /workspace/.claude/wt-branch-verify (branch `docs/branch-verify-without-install`)
**Scope:** `docs/working/spike-cc-verify-q117.md` at HEAD 190fa1a4 (prose, step table and the embedded `spike-q117.sh` heredoc), plus the commit messages of 12fcb61c and 190fa1a4
**Replication:** replicate 2 of k=3 (final confirming pass, decision log 63)
**Checked:** 2026-10-15
**Total claims checked:** 36
**Summary:** 26 verified, 7 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Line numbers `doc:N` refer to `docs/working/spike-cc-verify-q117.md` at 190fa1a4. The script is quoted at its doc line numbers. The heredoc body is byte-identical to `/home/node/.claude/jobs/00bcf178/tmp/branch-verify/spike-q117.v2.sh` (checked with `diff` and the paste round-trip in E14). `devcontainer-config/*`, `guides/cc-isolated-usage.md` and `docs/working/questions-archive.md` are identical on main and HEAD (`git diff main HEAD --stat` over those paths is empty), so the cited lines are main's. I read the hallucination-pattern log first. No claim matches a logged pattern, and no Incorrect verdict is a fabricated symbol, flag or file.

## Execution log index

Every probe ran in my own scratch dir, `/home/node/.claude/jobs/00bcf178/tmp/fc2r2.6ZcU88` (written `$S` below). Its logs are in `$S/logs/`. The harness is a copy of the author's `setup-t.sh` and `run-t2.sh`, repointed to `$S/t1` (main's launcher) and `$S/t0` (the pre-Q-089 launcher, `626dc300^1`). The author's `t1/` and v2 script were not touched. Every spike run went through `timeout 300`. Fake `docker` and `devcontainer` stubs were used throughout: nothing ran real docker, the devcontainer CLI, install.sh or cc-isolated against the host. I added four env switches to my copy of the fake devcontainer (`FAKE_UP_FAIL`, `FAKE_EXEC_FAIL`, `FAKE_FORGE`, `FAKE_SLEEP`) and an env-dump line. After the last probe, `ps` showed no process under `$S`. The stray subshells left by the kill -9 probe were stopped by PID.

| ID | Command (abridged) | cwd | Exit | UTC | Output |
|---|---|---|---|---|---|
| E1 | `timeout 300 bash setup.sh` (main launcher, blessed) | `$S` | 0 | 09:08Z | (terminal: `main install blessed`, `setup done`) |
| E2 | `./run.sh $S/t1/home/claude-workflows` (pass path) | `$S` | 0 | 09:08:38Z | `logs/pass.out` |
| E3 | `bash setup0.sh` then `./run0.sh …` (pre-Q-089 launcher as main's install) | `$S` | 0 | 09:10:23Z | `logs/pass-preq089.out` |
| E4 | `touch logs/marker; ./run.sh …; find t1 -newer logs/marker -not -path '*/cc-verify*' -not -path 't1/dstate*'` | `$S` | 0, find prints nothing | ~09:10Z | `logs/pass2.out` |
| E5 | plant `run-1-1.env` (`T8=deadbeef`, plus `PID=`/`IMG=` naming the harness project), `run-2-2.env`, `run-3-3.env` (`../` values), and an image tagged `acme/preverify-deadbeef:1`, then `./run.sh --clean` | `$S` | 1 | 09:10:56Z | `logs/planted.out`, `t1/dstate/calls` |
| E6 | `FAKE_UP_FAIL=1 ./run.sh …` / `FAKE_EXEC_FAIL=1 ./run.sh …` | `$S` | 1 / 1 | 09:11:06Z / 09:11:09Z | `logs/FAKE_UP_FAIL.out`, `logs/FAKE_EXEC_FAIL.out` |
| E7 | `FAKE_FORGE=1` (container prints `RESULT Q-117 pass`, ESC, CR); `FAKE_FAILS=3`; `FAKE_FAILS=3` plus non-rotating pool; non-rotating pool alone | `$S` | 0 / 1 / 1 / 2 | 09:11:22–29Z | `logs/forge.out`, `logs/fail3.out`, `logs/fail3norot.out`, `logs/norot.out` |
| E8 | `FAKE_SLEEP=4 ./run.sh … &`, then `kill -TERM <script pid>` during step 8 | `$S` | 130 | 09:12:10Z | `logs/term.out` |
| E9 | `FAKE_SLEEP=6 ./run.sh … &`, then `kill -9 <script pid>`, a rerun, then `./run.sh --clean` | `$S` | 137, then 1, then 0 | 09:12:23Z | `logs/crash.out`, `logs/after-crash.out`, `logs/clean.out` (the leftover listing went to the terminal: `VERIFY-65e65962`, `run-…env`, `snap-…-before`, `src-….git`, `stage-65e65962`, plus the container, two volumes and image of project `59aed9a4d51a`) |
| E10 | spike copies with: `BRANCH=feat/q125-cc-isolated-sandbox` and its sha; `EXPECT_BR=000…`; a branch `extra-path` (the fix branch plus `devcontainer-config/extra.txt`); main's installed devcontainer.json with `--privileged` added; installed Dockerfile with `RUN true` appended | `$S` | 1 each | 09:12:51–55Z | `logs/conflict.out`, `logs/moved.out`, `logs/extrapath.out`, `logs/djdiff.out`, `logs/dfdiff.out` |
| E11 | spike copy that appends `RUN true` to `$S/Dockerfile` (the stage's) between step 3 and step 4 | `$S` | 1 | 09:13:07Z | `logs/postbless.out` |
| E12 | 200 trials each: `git show main:devcontainer-config/install.sh \| grep -qxF "$P"` vs `inst="$(git show …)"; grep -qxF "$P" <<< "$inst"`, under `set -euo pipefail` | `/workspace/.claude/wt-branch-verify` | 0 | 09:13:10Z | `logs/sigpipe.out` |
| E13 | `bash -n spike.orig`; `shellcheck -S warning spike.orig` (ShellCheck 0.9.0) | `$S` | 0, 0 | 09:14:13Z | `logs/shellcheck.out` (empty) |
| E14 | the doc's paste block (minus its run line) run under `bash` and `zsh -f` with `HOME=<scratch>`, then `cmp` against the script; plus the whole block fed to `zsh -f -i` | `$S/ph.*`, `$S/zi.*` | 0, 0; 1 | 09:14Z, 09:16:49Z | `logs/roundtrip.out`, `logs/zsh-interactive.out` |
| E15 | `GH_TOKEN=secret OPENROUTER_API_KEY=secret2 ./run.sh …`, with the fake devcontainer logging both vars | `$S` | 0 | 09:15:40Z | `logs/creds.out`, `t1/dstate/calls` |
| E16 | spike copy with `PROFILE=nosuchprofile` (register fails); `./run.sh` with no argument; `./run.sh --clean` with nothing to clean | `$S` | 1, 1, 0 | 09:15:42–45Z | `logs/regfail.out`, `logs/usage.out`, `logs/clean2.out` |
| E17 | `FAKE_SLEEP=4 ./run.sh … &`, then a `find -maxdepth 1` of `src-*.git` and `VERIFY-*/.git` during step 8, plus `cat` of the bare clone's config and the run record | `$S` | 0 | 09:17:15Z | `logs/tmpl.out` (the listing went to the terminal; quoted in Claim 14) |
| E18 | `git merge-tree --write-tree --name-only main fix/egress-dnsmasq-ipset`; `git diff-tree -r --name-only main 65e65962…`; a real `git merge` in a scratch worktree of `$S/t1/home/claude-workflows`, then `rev-parse HEAD^{tree}` | `/workspace/.claude/wt-branch-verify`, `$S/wtm` | 0 | ~09:13Z | (terminal; quoted in Claim 16) |

---

## Claim 1: "Task status: paused (paste written; review loop iteration 2 passed; nothing has run on the host)"

**Location:** `docs/working/spike-cc-verify-q117.md:5`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the review-artifact state at commit 190fa1a4. Does not establish whether iteration 2 will pass once its replicates are merged.

At 190fa1a4, iteration 2 has not run. This report is one of its replicates. The commit's own message says `Iteration 2 (the final confirming pass) follows.`, and the rubric the doc links in its `Review:` line still reads `**Status: 🔴 DOES NOT PASS** — 5 red item(s) unresolved (iteration 1; fixes follow in the next commit)` (`docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md:6`). The status line records an outcome that had not happened when it was committed. The fix: say "iteration 2 pending", or update the line after this pass merges.

**Evidence:** `docs/working/spike-cc-verify-q117.md:5`, `docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md:6`, `git log -1 --format=%B 190fa1a4`

---

## Claim 2: "Last verified: 2026-10-15 against main b279a2ba and `fix/egress-dnsmasq-ipset` b26d4b8b23aa (pinned in the paste); their merge tree is `65e65962b12e…`."

**Location:** `docs/working/spike-cc-verify-q117.md:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three ids at check time and the paste's pin (`doc:64`, `EXPECT_BR=b26d4b8b23aa05130bc9340c0c4c81ecba75897f`). Does not establish that main has not moved since.

`git rev-parse main fix/egress-dnsmasq-ipset` printed `b279a2ba2a8f…` and `b26d4b8b23aa05130bc9340c0c4c81ecba75897f`. E2's pass run printed `main=b279a2ba2a8f  fix/egress-dnsmasq-ipset=b26d4b8b23aa  merged tree=65e65962b12e40d59c586aa429e580388e051cd9`.

**Evidence:** `logs/pass.out` (E2), `docs/working/spike-cc-verify-q117.md:64`

---

## Claim 3: The "Created / Name / Removed by" table: "Everything the script creates is kept under `~/cc-verify/` and named from the run", with run record "removed by the trap, last, and only when every removal succeeded"

**Location:** `docs/working/spike-cc-verify-q117.md:13-24`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every row's name and remover against `teardown` (`doc:98-132`) and the kill -9 leftovers. Does not establish the image row on a real devcontainer CLI (Not verified 1).

Each listed row matches the code and E9's leftovers. The run record goes only when nothing failed: `if [ "$fail" = 0 ]; then rm -f -- "$V/run-$RUN.env"; fi` (`doc:129`). The table does not list everything the script creates, though. `snapshot` makes `"$V/snap-$RUN-$1"` (`doc:135-136`), and E9's kill -9 left `snap-…-before` behind. It is removed by `compare`'s `rm -rf -- "$b" "$a"` (`doc:169`) or by `--clean` (`doc:204`). Step 2 also creates `"$S.raw"` (`doc:278`), which step 2 removes itself (`doc:292`) or the trap removes (`doc:125`). Neither appears in the table. Precise version: add the `snap-<RUN>-before/after` row (removed after the CHECKs, or by `--clean`).

**Evidence:** `docs/working/spike-cc-verify-q117.md:98-132`, `:134-147`, `:169`, `:204`, `:278`, `:292`; `logs/crash.out` (E9)

---

## Claim 4: "What the run checks at runtime (the CHECK lines). It compares, before and after: a hash over every file in `~/.config/claude-devcontainer`; the hashes of `manifest.sha256`, `host-tools.sha256` and `verified-live.sha256`; where `~/.local/bin/cc-isolated` and `cc-push` point; every container, volume and image tag that existed before the run."

**Location:** `docs/working/spike-cc-verify-q117.md:26-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what `snapshot`/`compare` record and compare. Does not establish detection of a removed *untagged* image (`<none>:<none>` lines are filtered at `doc:160`, consistent with "image tag"), or of a new empty directory in the config dir (only `-type f -o -type l` is hashed).

```bash
# docs/working/spike-cc-verify-q117.md:141-146
  for f in manifest.sha256 host-tools.sha256 verified-live.sha256; do
    if [ -e "$MAIN_CFG/$f" ]; then sha256sum < "$MAIN_CFG/$f" | sed "s|-\$|$f|" >> "$d/main"
…
  for f in cc-isolated cc-push; do echo "$f -> $(readlink -f "$MAIN_BIN/$f" 2>/dev/null || echo absent)" >> "$d/main"; done
  echo "config tree $( (cd "$MAIN_CFG" && find . \( -type f -o -type l \) -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) | sha256sum)" >> "$d/main"
```
(excerpt ends :146; enclosing `snapshot()` ends :147 — read)

`compare` (`doc:149-171`) runs `comm -23` over containers, volumes and image tags. Every run in E2–E9 printed the six CHECK lines, all `ok`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:134-171`; `logs/pass.out`, `logs/pass-preq089.out`

---

## Claim 5: "What holds by construction, not by a check. No command in the script writes `~/.claude` or your checkout's working tree. Its only operations on the checkout are `git rev-parse` and a `git clone` *from* it. It runs no branch code on the host. It needs no session to close: there is no install, so install.sh's agent gate never runs."

**Location:** `docs/working/spike-cc-verify-q117.md:34`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the script's own commands and main's launcher (both versions). Does not establish what the real devcontainer CLI or dockerd write on the host (temp or build dirs), or global-gitconfig filters that a committed `.gitattributes` could trigger during clone or archive (listed as a residual, `doc:515`).

The checkout is touched only at `REPO_TOP="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)"` (`doc:221`) and `git … clone -q --bare --no-local --template= -- "$REPO_TOP" "$SRCGIT"` (`doc:238`). Every other git call goes through `G=(git --no-optional-locks -C "$SRCGIT" …)` (`doc:239`) or targets `$W` (`doc:314-315`). install.sh is only read, as a blob: `"${G[@]}" show "$TREE:devcontainer-config/install.sh"` (`doc:273`). In E4, `find t1 -newer logs/marker` outside `cc-verify/` and the fake docker state printed nothing after a full pass. The fake HOME's checkout and `.config` were unchanged, and no `~/.claude` was created. The container's mounts are two named volumes plus the VERIFY workspace (`devcontainer.json:77-80`, `:134`), so branch code has no host `~/.claude` mount.

**Evidence:** `docs/working/spike-cc-verify-q117.md:221`, `:238-239`, `:273`, `:314-315`; `devcontainer-config/devcontainer.json:77-80,134`; `logs/pass2.out` (E4)

---

## Claim 6: "The block holds no shell comments outside the script, so it pastes the same into bash and zsh."

**Location:** `docs/working/spike-cc-verify-q117.md:38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers byte-identical script output under `bash` and `zsh -f`, and an interactive `zsh -f -i` reaching preflight with one argument. Does not establish a user's customised interactive shell (aliases, `setopt` changes).

Outside the heredoc the block has just two lines: `mkdir -p ~/cc-verify && cat > ~/cc-verify/spike-q117.sh <<'CCVERIFY'` (`doc:41`) and `bash ~/cc-verify/spike-q117.sh ~/claude-workflows` (`doc:395`). E14 printed `bash round-trip identical` and `zsh round-trip identical`. Fed to `zsh -f -i`, the run line got past the usage check (`[ $# -eq 1 ]`, `doc:210`) and refused at the next preflight item, `REFUSED: 'docker' not found on PATH.` (this sandbox has no docker).

**Evidence:** `docs/working/spike-cc-verify-q117.md:41`, `:395`; `logs/roundtrip.out`, `logs/zsh-interactive.out` (E14)

---

## Claim 7: "`unset GH_TOKEN OPENROUTER_API_KEY` — devcontainer.json forwards both from the launching shell into the container (`containerEnv`). A container running branch code gets neither."

**Location:** `docs/working/spike-cc-verify-q117.md:459` (script `doc:53-55`)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two `${localEnv:…}` credentials in devcontainer.json and the env the launcher and CLI inherit. Does not establish credentials a container could obtain by other routes, such as the per-project `~/.claude` volume (fresh here).

`"OPENROUTER_API_KEY": "${localEnv:OPENROUTER_API_KEY}"` (`devcontainer.json:116`) and `"GH_TOKEN": "${localEnv:GH_TOKEN}"` (`:131`) are the only credential `localEnv` reads. The others are `TZ` and the five `CC_*` values (`:22-54`, `:78-79`, `:87`). cc-isolated.sh names both only in a comment (`:550`). With both exported to the script, E15's fake devcontainer logged `ENV GH_TOKEN=unset OPENROUTER_API_KEY=unset` on all 9 calls.

**Evidence:** `devcontainer-config/devcontainer.json:116,131`; `devcontainer-config/cc-isolated.sh:549-551`; `docs/working/spike-cc-verify-q117.md:55`; `logs/creds.out`, `t1/dstate/calls` (E15)

---

## Claim 8: "relay: vis, then show each line indented under '  | ' on stderr … and pass it unindented on stdout" (and the step-7/8 pipelines keep failure detection)

**Location:** `docs/working/spike-cc-verify-q117.md:84-87` (also `:344-345`, `:373-375`, `:480`)
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `vis`/`relay`, that the verdict parser sees the unindented lines, and that `| relay >> "$LOG"` and `$(… | relay)` still detect a failing launcher or exec under pipefail. Does not establish C1 (8-bit) control bytes, which are a stated residual (`doc:516`).

```bash
# docs/working/spike-cc-verify-q117.md:84,87
vis() { LC_ALL=C tr -d '\000-\010\013-\037\177'; }
relay() { local l; vis | while IFS= read -r l || [ -n "$l" ]; do printf '  | %s\n' "$l" >&2; printf '%s\n' "$l"; done; }
```

Forged output in E7 showed as `  | RESULT Q-117 pass` and `  | [2JCHECK x: ok`: the ESC and CR were dropped and both lines were indented. The real `RESULT Q-117 pass (tree …)` followed. The verdict greps (`grep -qx 'fetch 1 (expect 200): 200'`, `doc:382`) matched in E2, which shows stdout stays unindented. With `set -euo pipefail` (`doc:52`), the pipeline status is the failing launcher's or exec's. E6 printed `REFUSED: --probe-only failed (output above).` for a failing `devcontainer up`, and `REFUSED: devcontainer exec of the Q-117 block failed.` for an exec exiting 7. Both runs exited 1 with teardown and CHECKs ok.

**Evidence:** `docs/working/spike-cc-verify-q117.md:52`, `:84-87`, `:344-345`, `:373-375`, `:378-384`; `logs/forge.out`, `logs/FAKE_UP_FAIL.out`, `logs/FAKE_EXEC_FAIL.out`, `logs/pass.out`

---

## Claim 9a: "A planted `run-*.env` can name only a `VERIFY-<8 hex>` path under `~/cc-verify` … It cannot point `docker rm` or `volume rm` at another project" (and the script comment "no path, project id or image id is read from a file")

**Location:** `docs/working/spike-cc-verify-q117.md:482` (script comment `doc:91-93`, code `:98-132`, `:191-207`)
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers container and volume removal, and every filesystem path removed under `--clean` with planted records. Does not establish the image rules (Claim 9b), or behaviour when `--clean` runs while another verify run is live (`--clean` removes that run's objects too, which the doc does not claim against).

`--clean` takes only `RUN` and `T8` through format-checked `sed` (`doc:199-200`) and skips a record whose name does not match (`doc:201`). The project id is recomputed: `printf '%s' "$VP/VERIFY-$1" | sha256sum | cut -c1-12` (`doc:96`). The only file `teardown` reads ids from is the before-snapshot, and only to *skip* an image (`doc:115`). In E5, records naming the harness project's id and image (`PID=aaaaaaaaaaaa`, `IMG=sha256:aaa9…`), plus a `../` record, removed none of the harness's container, volume or image. The `../` record was reported as `skipping malformed …`. No path outside `~/cc-verify/{stage,VERIFY}-<8hex>` or `src-<n>-<n>.git` was touched.

**Evidence:** `docs/working/spike-cc-verify-q117.md:91-132`, `:191-207`; `logs/planted.out`, `t1/dstate/calls` (E5)

---

## Claim 9b: "…or `image rm` at an image no verify container ran"

**Location:** `docs/working/spike-cc-verify-q117.md:482`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the tag rule in `teardown` as reached from `--clean` with a planted `T8`. Does not establish that any real image on the host carries such a tag. The match needs `verify-<8 hex>` somewhere in `repo:tag`.

The second image rule is a case-insensitive substring match on the whole `repo:tag`. Its target never comes from a container:

```bash
# docs/working/spike-cc-verify-q117.md:121-124
    while read -r i tags; do
      [ -n "$i" ] || continue
      case "$tags" in *verify-"$T8"*) docker image rm -f "$i" >/dev/null </dev/null || fail=1 ;; esac
    done < <(docker image ls --no-trunc --format '{{.ID}} {{.Repository}}:{{.Tag}}' </dev/null | tr 'A-Z' 'a-z')
```
(excerpt ends :124; enclosing `teardown()` continues to :132 — read)

In E5, a planted `run-1-1.env` with `T8=deadbeef` led `--clean` to run `docker image rm -f sha256:594e519a…`, which is the pre-existing `acme/preverify-deadbeef:1`. No verify container ran that image. The rule also uses `-f` by id, so an image carrying any other tag besides a matching one loses all its tags. A planted record can therefore steer `image rm` at any existing image whose name contains `verify-<8 hex>`. That is a narrow set, but it is not "only images a verify container ran". The doc does describe the tag rule (`doc:22`, and the last sentence of `doc:482`), so the impact is small. Precise version: "…or `image rm` at anything but an image a verify container ran or an image whose `repo:tag` contains `verify-<TREE8>`". Alternatively, anchor the match to the CLI's `vsc-verify-<T8>-` prefix.

**Evidence:** `docs/working/spike-cc-verify-q117.md:22`, `:119-124`, `:482`; `logs/planted.out`, `t1/dstate/calls` (E5)

---

## Claim 10: "Every line the launcher or the container prints is shown indented under `  | `, with control bytes removed. So only the script's own lines can start with `RESULT`, `CHECK` or `REFUSED`."

**Location:** `docs/working/spike-cc-verify-q117.md:402`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every launcher and container output path in the script. Does not establish forging potential on the unindented path. That path is main's launcher reading main-committed egress names (the five-path rule keeps `egress/` at main's content), so the branch cannot steer it.

Steps 7 and 8 go through `relay` (Claim 8). Step 6's `--register` output goes raw to `$LOG`, and on failure it is shown with `vis` only, not indented: `|| { tail -n 20 "$LOG" | vis >&2; die "--register failed (log above)."; }` (`doc:331`). E16, with an unknown profile, printed main's launcher lines `ERROR: unknown egress profile 'nosuchprofile'. Available:` and `    android` … at column 0. Precise version: "Every line the launcher prints during `--probe-only`, and everything the container prints…", or route the register tail through `relay`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:330-331`, `:344`, `:374`; `logs/regfail.out` (E16)

---

## Claim 11: Exit-status list: "Exit status, also printed as `RESULT spike-q117 exit=<n>`: 0 … 2 … 130: interrupted (Ctrl-C, TERM, HUP). The trap still tears down. 1: anything else"

**Location:** `docs/working/spike-cc-verify-q117.md:447-451`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers 0, 1, 2 and 130 (via TERM) as produced by `on_exit` and step 9. Does not establish HUP/INT delivery on a real terminal, or how the real CLI propagates exit codes (Not verified 4).

The codes hold. E2 exited 0, E7's fail cases 1, no-rotation 2, and E8's TERM 130 with `RESULT spike-q117 exit=130` after teardown and the CHECKs. `on_exit` turns any of these into 1 on a failed CHECK or an incomplete teardown (`doc:180-184`). The parenthetical "also printed as `RESULT spike-q117 exit=<n>`" does not hold for refusals before `trap on_exit EXIT` (`doc:231`) or for `--clean`. E16's no-argument run printed only `REFUSED: usage: …`, exited 1 and printed no RESULT line. Preflight refusals (`doc:210-227`) behave the same way. The paste-back guidance (`doc:453`, "On a refusal, the `REFUSED:` line") covers this in practice. Precise version: "printed as `RESULT spike-q117 exit=<n>` once the run has started (after preflight)".

**Evidence:** `docs/working/spike-cc-verify-q117.md:173-188`, `:210-232`, `:389-393`; `logs/pass.out`, `logs/norot.out`, `logs/fail3.out`, `logs/term.out`, `logs/usage.out`

---

## Claim 12: "`CLAUDECODE` mirrors install.sh's target-2 rule (decision 037). An inherited `CLAUDE_DEVC_CONFIG_DIR` would change which config is 'main's' (cc-isolated.sh:68-70)."

**Location:** `docs/working/spike-cc-verify-q117.md:460`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both citations. Does not establish that `CLAUDECODE` stops a determined agent, which the doc disclaims (`doc:518`).

`config_dir() { echo "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"; }` (`cc-isolated.sh:68-70`). install.sh skips the host target when `if [ -n "${CLAUDECODE:-}" ]; then` (`install.sh:779`). The script refuses on either variable (`doc:211-212`).

**Evidence:** `devcontainer-config/cc-isolated.sh:68-70`; `devcontainer-config/install.sh:779-780`; `docs/working/spike-cc-verify-q117.md:211-212`

---

## Claim 13: "install.sh links it there (install.sh:598, defaults :1310-1311)."

**Location:** `docs/working/spike-cc-verify-q117.md:461`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the link and the default paths. Does not establish a custom `CLAUDE_DEVC_CONFIG_DIR` install, which the script refuses (`doc:212`, `:218-219`).

`ln -sf "$DEST/cc-isolated.sh" "$BIN_DIR/cc-isolated"` (`install.sh:598`). `DEST="${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"` and `BIN_DIR="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"` (`install.sh:1310-1311`).

**Evidence:** `devcontainer-config/install.sh:598,1310-1311`

---

## Claim 14: Step 1: "The clone copies objects and refs: no `.git/config` filters or merge drivers, no `info/attributes`, no hooks (`--template=` copies none). … The flags match `repo_git` (install.sh:180-182). The run record and this clone are the only things created before the merge check"

**Location:** `docs/working/spike-cc-verify-q117.md:463`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the bare clone's layout and config, the flags on `G`, and the git_state_gate citation. Does not establish filters defined in global config (residual, `doc:515`).

During step 8, E17 listed the bare clone as `HEAD config objects packed-refs refs`: no hooks dir and no `info/`. Its config held only `[core]` and `[remote "origin"]`. The workspace `.git` likewise had no hooks dir. `repo_git` is `git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"` (`install.sh:181`), which matches `G` (`doc:239`). `git_state_gate` spans `install.sh:209-252`. Before step 1's merge-tree, only `run-$RUN.env` (`doc:230`) and `$SRCGIT` (`doc:238`) are created, besides `mkdir -p "$V"` (`doc:222`).

**Evidence:** `devcontainer-config/install.sh:180-182,209-252`; `docs/working/spike-cc-verify-q117.md:222-244`; `logs/tmpl.out` (E17)

---

## Claim 15: "the branch must resolve to the reviewed commit `b26d4b8b23aa…` (`EXPECT_BR`) … A ref moved in the checkout's `.git` … refuses the run"

**Location:** `docs/working/spike-cc-verify-q117.md:464`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the branch pin. Does not establish a pin on `main` (stated residual, `doc:513`).

`[ "$BR_SHA" = "$EXPECT_BR" ] || die …` (`doc:242`). E10 with a mismatched pin printed `REFUSED: fix/egress-dnsmasq-ipset is at b26d4b8b…, not the reviewed 0000…. Ask for a refreshed paste.`

**Evidence:** `docs/working/spike-cc-verify-q117.md:64`, `:241-242`; `logs/moved.out` (E10)

---

## Claim 16: "`git merge-tree --write-tree --name-only main <branch>`: exit 1 refuses and lists the conflicts … today the merge is clean (tree `65e65962…`, the same tree a real `git merge` produces), and `feat/q125-cc-isolated-sandbox` is refused on `hooks/live-verify-gate.sh`."

**Location:** `docs/working/spike-cc-verify-q117.md:465`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5 in this sandbox. Does not establish the host's git version (Not verified 5).

E18: `merge-tree` printed `65e65962b12e40d59c586aa429e580388e051cd9`, and a real `git merge` of the branch into main in a scratch worktree gave `HEAD^{tree}` = `65e65962b12e40d59c586aa429e580388e051cd9`. E10's conflict run printed `CONFLICT (content): Merge conflict in hooks/live-verify-gate.sh` and then `REFUSED: feat/q125-cc-isolated-sandbox does not merge cleanly with main …`. The fake docker's call log for that run held only `docker info`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:243-253`; `logs/conflict.out` (E10); E18 (terminal)

---

## Claim 17: "`git diff-tree -r --name-only <main> <tree>` may list only the branch's five paths"

**Location:** `docs/working/spike-cc-verify-q117.md:466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the five-path list against the branch's diff, and refusal of a sixth path. Does not establish anything about content within those five paths.

`BRANCH_PATHS` (`doc:66-70`) equals `git diff --name-only main...fix/egress-dnsmasq-ipset` and `git diff-tree -r --name-only main 65e65962…` (E18: the same five paths). The loop refuses any other path: `grep -qxF -- "$f" <<< "$BRANCH_PATHS" || die …` (`doc:258`). E10's `extra-path` branch printed `REFUSED: the merge changes devcontainer-config/extra.txt, which is not one of the branch's reviewed paths.`

**Evidence:** `docs/working/spike-cc-verify-q117.md:66-70`, `:255-259`; `logs/extrapath.out` (E10)

---

## Claim 18: Step 2: install.sh's `PAYLOAD`/`CLAUDE_HOME_SRC` "read into a variable first (no `git show | grep -q` under pipefail) … install.sh:110 and :135. The variable avoids SIGPIPE: install.sh is larger than a pipe buffer"

**Location:** `docs/working/spike-cc-verify-q117.md:467` (code `doc:273-277`)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the step-2 checks. Does not establish that the script's other `cmd | grep -q` pipelines are SIGPIPE-proof: `docker volume ls -q | grep -q "^cc-$PID-"` (`doc:163`, `:322`) has the same shape (paraphrased — no quote available because this is a reasoning note on two other lines: it would only misfire if the volume list exceeded a pipe buffer, about 64 KiB of names, after a match).

`install.sh:110` is `PAYLOAD=(devcontainer.json Dockerfile … egress claude-home)` and `:135` is `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`. Both match `EXPECT_PAYLOAD`/`EXPECT_HOME_SRC` exactly (`doc:76-77`). install.sh is 65,632 bytes, just over Linux's 65,536-byte default pipe capacity. In E12, over 200 trials, the old pipe form failed spuriously 199/200 and the variable form 0/200.

**Evidence:** `devcontainer-config/install.sh:110,135`; `docs/working/spike-cc-verify-q117.md:76-77`, `:271-277`; `logs/sigpipe.out` (E12)

---

## Claim 19: "The same sources and the same no-symlink rule as `extract_commit` (install.sh:257-317, the symlink refusal at :288)."

**Location:** `docs/working/spike-cc-verify-q117.md:468`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers sources and the symlink refusal only, as claimed. Does not establish parity on extract_commit's NUL-byte refusal (`install.sh:298-316`) or its `tar.umask=022`/`tar -p` modes (`:279-280`). The spike has neither, and the doc does not claim them.

`extract_commit() {` opens at `install.sh:257` and closes at `:317`. `:288` opens the block `# No symlinks (review R1).` whose check is `links="$(cd "$dir" && find . -type l …)"` (`:291`). The spike refuses with `[ -z "$(find "$S.raw" -type l -print -quit)" ] || die …` (`doc:281`).

**Evidence:** `devcontainer-config/install.sh:257-317`; `docs/working/spike-cc-verify-q117.md:279-281`

---

## Claim 20: Step 2 layout: "Matches `install_devcontainer` (install.sh:471-508), `assemble`'s `.manifest` keys (:356-361) and install.sh:596. The Dockerfile copies `claude-home/` (Dockerfile:500), `egress/` (:486) and the scripts (:487-491) from the build context, which is `CC_CONFIG_DIR` (devcontainer.json:24-26). The review checked that the current launcher and the pre-Q-089 launcher both bless and check a stage built this way."

**Location:** `docs/working/spike-cc-verify-q117.md:469`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the layout, citations and both launchers' bless and check on such a stage (fake CLI). Does not establish a real image build.

`install_devcontainer() {` starts at `install.sh:471`. `:471-508` covers its staging half, and the PAYLOAD copy loop into `$DEST` is at `:579-583` (paraphrased — no quote available because the range is long; the loop copies each PAYLOAD item to `$DEST/$item`, the same root layout). The `.manifest` keys `commit=`, `dirty=no`, `uncommitted_excluded=`, `assembled_from=` are at `:356-361`. `chmod +x "$DEST/cc-isolated.sh" "$DEST/cc-push.sh" "$DEST/init-firewall.sh"` is at `:596`. The Dockerfile lines are `COPY egress/ /usr/local/share/cc-egress/` (`:486`), `COPY init-firewall.sh`/`cc-sni-proxy.py`/`link-claude-home.sh` (`:487-491`) and `COPY claude-home/ /opt/claude-workflows/` (`:500`). The build context is `"context": "${localEnv:CC_CONFIG_DIR}"` (`devcontainer.json:24-26`). E2 (current launcher) and E3 (`626dc300^1` launcher) both reached `Boundary self-probe passed` and `RESULT spike-q117 exit=0`.

**Evidence:** `devcontainer-config/install.sh:356-361,471-508,579-583,596`; `devcontainer-config/Dockerfile:486-491,500`; `devcontainer-config/devcontainer.json:24-26`; `logs/pass.out`, `logs/pass-preq089.out`

---

## Claim 21: Step 3: refuses on `initializeCommand` or "if the staged `devcontainer.json` **or `Dockerfile`** differs at all from main's installed copy … devcontainer.json carries runArgs (devcontainer.json:58-69), mounts (:77-80)"

**Location:** `docs/working/spike-cc-verify-q117.md:470`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the whole-file pin and the citations. Does not establish the stated rationale that a base image's `devcontainer.metadata` label can add privileged/capAdd/mounts, which is a dev-container-spec claim (doc Not verified 7).

```bash
# docs/working/spike-cc-verify-q117.md:299-303
for i in "${PINNED[@]}"; do
  if ! cmp -s "$MAIN_CFG/$i" "$S/$i"; then
    diff -u "$MAIN_CFG/$i" "$S/$i" | vis || true
    die "the staged $i differs from main's installed copy (diff above). …"
  fi
```
(excerpt ends :303; the loop closes at :304 — read)

E10 refused `--privileged` in devcontainer.json and `RUN true` in the Dockerfile at step 3, showing the diff each time. `runArgs` is at `devcontainer.json:58-69` and `mounts` at `:77-80`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:74`, `:294-304`; `devcontainer-config/devcontainer.json:58-69,77-80`; `logs/djdiff.out`, `logs/dfdiff.out` (E10)

---

## Claim 22: Step 4: "`resolve_workspace` uses `git rev-parse --show-toplevel` (cc-isolated.sh:354-367), and `project_id` is that exact pipeline (cc-isolated.sh:372-374). The display name is `basename` of the workspace (cc-isolated.sh:814 → devcontainer.json:22) … selects the container by `--id-label cc-project=$pid` (cc-isolated.sh:836) and names volumes `cc-${CC_PROJECT_ID}-…` (devcontainer.json:78-79). With a fresh PID, `--remove-existing-container` (cc-isolated.sh:883) can only hit this run's container."

**Location:** `docs/working/spike-cc-verify-q117.md:471-472`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the citations and the PID agreement between the script and the launcher. Does not establish the real CLI's label matching.

`project_id() { printf '%s' "$1" | sha256sum | cut -c1-12; }` (`cc-isolated.sh:372-374`) matches `verify_pid` (`doc:96`). The other citations land: `:360` `git -C "$start" rev-parse --show-toplevel`, `:814` `CC_PROJECT_NAME="$(basename "$ws")"`, `:836` `--id-label "cc-project=$pid"`, `:883` `devcontainer up --remove-existing-container "${dc[@]}"`, and `devcontainer.json:22` and `:78-79`. In E2 the launcher wrote `stage/projects/59aed9a4d51a.profile`, the PID the script printed, which proves the two computations agree.

**Evidence:** `devcontainer-config/cc-isolated.sh:354-374,814,836,883`; `devcontainer-config/devcontainer.json:22,78-79`; `docs/working/spike-cc-verify-q117.md:312-323`; `logs/pass.out`

---

## Claim 23: Step 6: "Flag syntax: cc-isolated.sh:9-11 and :736; guide `cc-isolated-usage.md:23,537`. `register_project` checks `$(config_dir)/egress/android.txt`, writes `$(config_dir)/projects/<pid>.profile` and re-blesses (cc-isolated.sh:434-480). `bless_manifest` writes only under `config_dir` (cc-isolated.sh:281-319)."

**Location:** `docs/working/spike-cc-verify-q117.md:474`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the current launcher. The pre-Q-089 `bless_manifest` writes `compute_manifest > "$(manifest_path)"` directly, which is also under config_dir (`626dc300^1:devcontainer-config/cc-isolated.sh:195`).

`if [ ! -r "$(config_dir)/egress/$p.txt" ]` (`:440`), `printf '%s\n' "$profiles" > "$(projects_dir)/$pid.profile"` (`:458`) and `bless_manifest` (`:476`). `bless_manifest` uses `mktemp "$(config_dir)/.manifest.XXXXXX"` and the host-tools twin, then `mv -f` into `host_tools_path`/`manifest_path` (`:284-285`, `:303-304`). The flags are `--register)   action="register"` (`:736`) and the header (`:9-11`). The guide has `--register ~/code/api --profile python` (`:23`) and `--register ~/code/app --profile android` (`:537`).

**Evidence:** `devcontainer-config/cc-isolated.sh:9-11,281-319,434-480,736`; `guides/cc-isolated-usage.md:23,537`

---

## Claim 24: "after the bless, the stage manifest's `devcontainer.json` and `Dockerfile` hashes must equal main's installed copies'; stage hash = `sha256sum < stage/manifest.sha256 | cut -c1-16` … `check_manifest` at `--probe-only` (cc-isolated.sh:332-350) … `blessed_hash` (cc-isolated.sh:88-93)."

**Location:** `docs/working/spike-cc-verify-q117.md:475` (code `doc:336-341`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the manifest line format, the awk lookup and refusal of a post-step-3 edit. Does not establish protection after `check_manifest` (stated residual, `doc:514`).

`compute_manifest` emits `sha256sum`'s own `<hash>  <path>` lines for regular files and `<hash>  link:<path>` for links (`cc-isolated.sh:183-188`). With awk's default whitespace splitting, `$2 == f` matches the bare names exactly. Main's installed manifest shows `8caea995…  Dockerfile` and `0e89faee…  devcontainer.json`. The pre-Q-089 `compute_manifest` has the same format. E2/E3 passed the check (an unmatched lookup would give `have=""` and refuse). E11, which edits the stage Dockerfile after step 3, printed `REFUSED: the stage's blessed Dockerfile is not main's installed copy (changed after step 3).` `blessed_hash` is `sha256sum < "$m" | cut -c1-16` (`:92`). `check_manifest` (`:332-350`) runs at `:828` before `devcontainer up`.

**Evidence:** `devcontainer-config/cc-isolated.sh:88-93,183-188,332-350,828`; `docs/working/spike-cc-verify-q117.md:336-341`; `logs/postbless.out` (E11), `logs/pass.out`, `logs/pass-preq089.out`

---

## Claim 25: "Main's launcher loads host code only from its own directory (cc-isolated.sh:714-718), and so did the pre-Q-089 launcher … So the stage's copies of `cc-isolated.sh` and the host tools are hashed but never executed. … The review confirmed that the launcher, run against the stage, executes no staged file and writes only under it." (plus `:880-885`, `:577-705`, `:113-115`, `:702`, `:128-151`, `:199-203`)

**Location:** `docs/working/spike-cc-verify-q117.md:476`
**Type:** Invariant / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the launcher script itself, both versions, for `--register` and `--probe-only` (the launch-only `mktemp` at `:844` is not reached). Does not establish what the devcontainer CLI and dockerd write. The stage's devcontainer.json and Dockerfile are *interpreted* by the CLI and the build, not executed, and are pinned (Claim 21).

`CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"` then `source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` (`:714-718`), and cc-exit-scan.sh sources `cc-gitdir.sh` from its own dir (`cc-exit-scan.sh:12`). The pre-Q-089 launcher has `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-exit-scan.sh"` (`626dc300^1:…/cc-isolated.sh:562`). `verify_host_tools "$CC_ISOLATED_DIR" …` checks main's dir, not the stage (`:716`). The writes on these paths all land under `config_dir`: the profile (`:458`), the bless temp files and renames (`:284-304`), and `blessed_hash > "$(verified_path)"` (`:114`, called only at `:702` after `failures` is 0). `logical_workspace`, called for probe at `:842`, only reads (`cc-exit-scan.sh:19-29`). E4 found no file written outside `~/cc-verify` and the fake docker state. The other citations land: `:880-885` probe always rebuilds, `:577-705` `probe_boundary`, `:128-151` `enforcement_files`, `:199-203` `host_tool_files`.

**Evidence:** `devcontainer-config/cc-isolated.sh:113-115,128-151,199-203,577-705,714-721,842,880-885`; `devcontainer-config/cc-exit-scan.sh:12,19-29`; `git show 626dc300^1:devcontainer-config/cc-isolated.sh` (:195, :562); `logs/pass2.out` (E4), `logs/pass-preq089.out` (E3)

---

## Claim 26: Step 8: "Exactly the five variables `rebuild_hint` says the by-hand CLI needs (cc-isolated.sh:561-563), and the same `dc` args the launcher uses (:834-836). `bash -c` with the block as one argument is how the probe runs in-container scripts (cc-isolated.sh:608). stdin is `/dev/null`"

**Location:** `docs/working/spike-cc-verify-q117.md:478`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the citations and the script's arguments. Does not establish that the real CLI's `exec` honours them (doc Not verified 3-4).

`for var in CC_PROJECT_ID CC_PROJECT_NAME CC_CONFIG_DIR CC_EGRESS_PROFILE CC_CONFIG_HASH; do` (`cc-isolated.sh:562`, inside the cited `:561-563`). The `dc` array is `:834-836`, and `actual_fp="$(devcontainer exec "${dc[@]}" bash -c '` is at `:608`. The script exports the same five (`doc:372`) and passes `--workspace-folder "$WS" --override-config "$S/devcontainer.json" --id-label "cc-project=$PID" bash -c "$Q117" </dev/null` (`doc:373-374`).

**Evidence:** `devcontainer-config/cc-isolated.sh:561-564,608,834-836`; `docs/working/spike-cc-verify-q117.md:372-375`

---

## Claim 27: "questions-archive.md:2463-2475 (byte for byte). It runs as `remoteUser: node` (devcontainer.json:71). … `/run/cc-sni-proxy` is 0755 (`init-firewall.sh:1392-1393` on the branch) and the log is opened 0644 (`cc-sni-proxy.py:260`). The `ALLOW sni=… -> <ip>:<port>` field order is the proxy's (`cc-sni-proxy.py:207`). dl.google.com is only in `egress/android.txt`."

**Location:** `docs/working/spike-cc-verify-q117.md:479`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each citation on main or the branch. Does not establish the log's mode when the file already exists (`O_CREAT` sets mode only on creation; `init-firewall.sh` runs on a fresh container here).

`diff` of `questions-archive.md:2463-2475` against the script's `Q117BLOCK` heredoc printed nothing (VERBATIM). `"remoteUser": "node"` is at `devcontainer.json:71`. On the branch: `mkdir -p "$SNI_RUN_DIR"` / `chmod 0755 "$SNI_RUN_DIR"` (`init-firewall.sh:1392-1393`, with `SNI_RUN_DIR="${CC_SNI_RUN_DIR:-/run/cc-sni-proxy}"` at `:771` and `SNI_LOG="$SNI_RUN_DIR/proxy.log"` at `:774`), `log_fd = os.open(args.log, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)` (`cc-sni-proxy.py:260`) and `log(f"ALLOW sni={sni} -> {ip}:{upstream_port} orig_dst={orig}")` (`:207`). `grep -l dl.google.com devcontainer-config/egress/*.txt` lists only `android.txt`.

**Evidence:** `docs/working/questions-archive.md:2463-2475`; `devcontainer-config/devcontainer.json:71`; `fix/egress-dnsmasq-ipset:devcontainer-config/init-firewall.sh:771,774,1392-1393`; `fix/egress-dnsmasq-ipset:devcontainer-config/cc-sni-proxy.py:207,260`; `devcontainer-config/egress/android.txt`

---

## Claim 28: Step 9: "verdict = Q-117's own rule: 2 instances, both fetches 200, 0 FAIL lines, the first ALLOW address absent from 'pool now'. `no-rotation` (exit 2) applies only when nothing else failed … questions-archive.md:2478."

**Location:** `docs/working/spike-cc-verify-q117.md:481` (code `doc:378-393`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers verdict ordering on the fake output. Does not establish the real proxy-log contents.

`**Pass** = 2 instances, both fetches 200, 0 FAIL lines, and "pool now" no longer lists the first ALLOW address.` (`questions-archive.md:2478`). The code is `if [ "$v" = pass ] && printf ' %s ' "$pool" | grep -qF " $first "; then v=no-rotation; fi` (`doc:387`). E7 results: 3 FAIL lines and rotated gave `RESULT Q-117 fail`, exit 1. 3 FAIL lines and not rotated gave `RESULT Q-117 fail`, exit 1. Not rotated alone gave `RESULT Q-117 no-rotation`, exit 2.

**Evidence:** `docs/working/questions-archive.md:2478`; `docs/working/spike-cc-verify-q117.md:378-393`; `logs/fail3.out`, `logs/fail3norot.out`, `logs/norot.out` (E7)

---

## Claim 29: "What was tested here, without a host": pass path; refusals (conflict with no docker call besides `docker info`, moved branch, devcontainer.json and Dockerfile differences); failures; forged output; planted run record "removed nothing"; kill -9 + `--clean`; `bash -n` and `shellcheck -S warning` clean; byte-for-byte round trip under bash and `zsh -f`

**Location:** `docs/working/spike-cc-verify-q117.md:486-497`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every listed item, re-run independently (E2, E5, E7-E10, E13, E14). Does not establish that the planted-record test covered the tag rule. The doc's planted record named the harness's project id and image, which survive. A record whose `T8` matches an existing `*verify-<T8>*` tag does remove that image (Claim 9b).

Every bullet reproduced. E2: pass, every CHECK ok, the harness container, volume and image survived. E10: conflict refused on `hooks/live-verify-gate.sh` with only `docker info` in the call log, plus moved-branch, devcontainer.json and Dockerfile refusals. E7: fail stays fail without rotation, no rotation alone exits 2, and forged lines show indented and stripped. E5: the harness's objects survived the planted records. E9: kill -9 left the listed objects, the next run refused, and `--clean` removed exactly those. E13: `bash -n` rc 0, shellcheck rc 0 with empty output. E14: both round trips identical.

**Evidence:** `logs/pass.out`, `logs/conflict.out`, `logs/moved.out`, `logs/djdiff.out`, `logs/dfdiff.out`, `logs/fail3.out`, `logs/fail3norot.out`, `logs/norot.out`, `logs/forge.out`, `logs/planted.out`, `logs/crash.out`, `logs/after-crash.out`, `logs/clean.out`, `logs/shellcheck.out`, `logs/roundtrip.out`

---

## Claim 30: The "Not verified (needs the host run)" list, items 1-8, as the complete set of unobserved host behaviours

**Location:** `docs/working/spike-cc-verify-q117.md:499-508`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether each listed item is in fact unobserved, and what the harness assumed by construction without listing it. Does not establish that the omitted items fail on a real host.

All eight items are unobserved in the sandbox. Three assumptions the fake stubs make true by construction are missing from the list (paraphrased — no quote available because the claim is about absences in a list):
- **(a)** `docker image ls --no-trunc --format '{{.ID}}'` printing the same `sha256:<64 hex>` form as `docker inspect -f '{{.Image}}'`. The `new:` report (`doc:351`) and teardown's "absent before the run" guard (`doc:115`) depend on it. The fake docker emits that form by design.
- **(b)** The tag rule's reach beyond the CLI's own naming (Claim 9b).
- **(c)** Teardown's `rm -rf` of `VERIFY-<T8>` succeeding after the container's root-run `init-firewall.sh`/postStart, or branch code, writes root-owned files into the bind-mounted workspace. Docker has no userns remap by default. The incomplete-teardown path would catch this (`doc:180-182`), but `--clean` would hit the same permission error.

Precise version: add (a) to item 4's assumptions, and (c) as a possible incomplete-teardown cause.

**Evidence:** `docs/working/spike-cc-verify-q117.md:115`, `:121-125`, `:351`, `:499-508`; `devcontainer-config/devcontainer.json:134,141`

---

## Claim 31: "That is the same swap window decision 037 accepts for install target 1. cc-isolated agents cannot reach `~/cc-verify`."

**Location:** `docs/working/spike-cc-verify-q117.md:514`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the containers bind-mount. Does not establish decision 037's wording (not re-read).

Other projects' containers mount only their own workspace: `"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,…"` (`devcontainer.json:134`). The verify container's `localWorkspaceFolder` is `~/cc-verify/VERIFY-<T8>`, though. It reaches that subdirectory of `~/cc-verify`, a fact the doc states elsewhere (`doc:38`, `:517`). It does not reach the stage, which is what this residual is about. Precise version: "no cc-isolated container can reach the stage; the verify container reaches only its own `VERIFY-<TREE8>`".

**Evidence:** `devcontainer-config/devcontainer.json:134`; `docs/working/spike-cc-verify-q117.md:38`, `:514`, `:517`

---

## Claim 32: Commit 12fcb61c message: "stages `git merge-tree --write-tree main fix/egress-dnsmasq-ipset` from a bare scratch clone, refusing on conflict before anything else exists; … refuses a devcontainer.json that differs from main's installed copy or names initializeCommand; … Each step is cited to file:line." / Notes: "pass, conflict refusal, devcontainer.json refusal, Q-117 fail, no-rotation and kill -9 + --clean all behaved as documented. bash -n and shellcheck -S warning are clean, and the paste round-trips under bash and zsh."

**Location:** commit 12fcb61c (message body)
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the message against the 12fcb61c script (`git show 12fcb61c:docs/working/spike-cc-verify-q117.md`). Does not re-execute 12fcb61c's script. Its behaviour is recorded in the iteration-1 report.

The structural bullets match 12fcb61c. Three statements were not exact at that commit:
- "Before anything else exists": the run record and the bare clone already exist before the conflict check.
- "Q-117 fail … behaved as documented": 12fcb61c's verdict was `if [ -z "$first" ] || [ "$first" = NONE ]; then v=fail` / `elif printf ' %s ' "$pool" | grep -qF " $first "; then v=no-rotation; fi` (12fcb61c doc:326-327), so a fail without rotation reported `no-rotation`, exit 2. That is iteration 1's Claim 9a.
- "Round-trips under bash and zsh": 12fcb61c's run line carried a trailing `# EDIT: …` comment (12fcb61c doc:335). In an interactive zsh without `interactivecomments`, that comment becomes arguments (iteration 1's Claim 29).

All three are fixed at 190fa1a4.

**Evidence:** `git show 12fcb61c:docs/working/spike-cc-verify-q117.md` (:322-331, :335); `docs/reviews/code-fact-check-report-cc-verify-spike.md` (Claims 9a, 28, 29)

---

## Claim 33a: Commit 190fa1a4 message: R1 (install.sh into a variable), R2 (fail never becomes no-rotation), R4/F1 (Dockerfile pinned), R5/F2 (branch pin, five paths), A1/F3 (post-bless manifest hashes), A2/F6 (credentials unset), A6 (whole config dir hashed; runtime vs by-construction split), A8 (no shell comments outside the heredoc), and the Notes' test list ("pass, conflict, moved branch, devcontainer.json and Dockerfile refusals, fail plus no rotation, forged container output, planted run record, and kill -9 + --clean. shellcheck clean. … interactive zsh reaches preflight with the right argument.")

**Location:** commit 190fa1a4 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed fix as present and working in the harness. Does not establish the items split out below (33b, 33c).

Each item reproduces: R1 is Claim 18, R2 Claim 28, R4/F1 Claim 21, R5/F2 Claims 15 and 17, A1/F3 Claim 24, A2/F6 Claim 7, A6 Claims 4 and 5, A8 Claim 6, and the tests Claim 29. E14's `zsh -f -i` run got past the one-argument usage check.

**Evidence:** `git log -1 --format=%B 190fa1a4`; the claims and logs cited above

---

## Claim 33b: Commit 190fa1a4 message, R3/F4: "The project id is recomputed from ~/cc-verify/VERIFY-<T8>, images come only from this run's containers (and only if new and unused), so a planted record cannot steer docker rm, volume rm or image rm."

**Location:** commit 190fa1a4 (message body)
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the `image rm` half. The `docker rm`/`volume rm` half and the record holding only `RUN=`/`T8=` are Verified (Claim 9a; E17 showed `RUN=…` and `T8=65e65962` only).

"Images come only from this run's containers" leaves out teardown's second rule. That rule removes any image whose lower-cased `repo:tag` contains `verify-<T8>` (`doc:121-124`), with no container or "new and unused" condition. E5's planted `T8=deadbeef` removed the pre-existing `acme/preverify-deadbeef:1`. Same finding as Claim 9b.

**Evidence:** `docs/working/spike-cc-verify-q117.md:112-124`; `logs/planted.out`, `t1/dstate/calls` (E5)

---

## Claim 33c: Commit 190fa1a4 message, A3/F8 and A7: "launcher and container output is relayed with control bytes dropped and indented under '  | '" / "the clones use --template= with hooks and fsmonitor off; --no-optional-locks is added."

**Location:** commit 190fa1a4 (message body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the two wording points. Does not establish any security consequence: the unrelayed path is main's launcher, and fsmonitor does not run in a bare repository.

A3: `--probe-only` and container output is relayed, but `--register` output is not. On failure it is shown with `vis` only, unindented (`doc:331`, E16; Claim 10). A7: the workspace clone sets both `-c core.hooksPath=/dev/null -c core.fsmonitor=false` (`doc:314`). The bare clone sets only `git -c core.hooksPath=/dev/null clone -q --bare --no-local --template=` (`doc:238`). `--no-optional-locks` is on the later `G` calls (`doc:239`), not on either clone. Precise version: "both clones use `--template=` and hooks off; the workspace clone also turns fsmonitor off; later git calls add `--no-optional-locks`."

**Evidence:** `docs/working/spike-cc-verify-q117.md:238-239`, `:314`, `:331`; `logs/regfail.out` (E16)

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/working/spike-cc-verify-q117.md:5`): "review loop iteration 2 passed" was committed before iteration 2 ran. The linked rubric says DOES NOT PASS (iteration 1). Change to "pending", or update after this pass.
- **Claim 9b** (`docs/working/spike-cc-verify-q117.md:482`): a planted `T8` can make `--clean` run `image rm -f` on any existing image whose `repo:tag` contains `verify-<T8>` (reproduced on `acme/preverify-deadbeef:1`). Reword, or anchor the match to the CLI's `vsc-verify-<T8>-` prefix.
- **Claim 33b** (commit 190fa1a4, R3/F4): "images come only from this run's containers … cannot steer image rm" leaves out the tag rule. Same finding as 9b.

### Stale
- (none)

### Mostly Accurate
- **Claim 3** (`docs/working/spike-cc-verify-q117.md:13-24`): the created-objects table omits `snap-<RUN>-before/after` (left by a kill -9, removed by `--clean`) and the transient `stage-<TREE8>.raw`.
- **Claim 10** (`docs/working/spike-cc-verify-q117.md:402`): `--register` failure output is shown with `vis` but not indented (`doc:331`). "Every line the launcher prints" covers only `--probe-only`.
- **Claim 11** (`docs/working/spike-cc-verify-q117.md:447`): refusals before the trap is set (usage, preflight) and `--clean` print no `RESULT spike-q117 exit=` line.
- **Claim 30** (`docs/working/spike-cc-verify-q117.md:499-508`): Not-verified list omits the `image ls --no-trunc` id-format assumption, the tag rule's reach, and root-owned workspace files blocking `rm -rf VERIFY-<T8>`.
- **Claim 31** (`docs/working/spike-cc-verify-q117.md:514`): the verify container does reach `~/cc-verify/VERIFY-<TREE8>`. Say "cannot reach the stage".
- **Claim 32** (commit 12fcb61c): "before anything else exists", "Q-117 fail … behaved as documented" and the zsh round trip were not exact at that commit (all fixed at 190fa1a4).
- **Claim 33c** (commit 190fa1a4, A3/A7): `--register` output is not relayed. The bare clone does not set fsmonitor off, and `--no-optional-locks` is on the later git calls, not the clones.

### Unverifiable
- (none)

No Incorrect verdict is a fabricated symbol, API or flag, so `docs/reviews/hallucination-patterns.md` gets no new entry.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to the path named at the end of this prompt, structured per the code-fact-check skill, with a `**Commit:** 190fa1a4` line at the top.
- Answered: yes. All six focus areas are verdicted: every file:line citation lands (one range, `install.sh:471-508`, covers only the staging half of `install_devcontainer`), every iteration-1 fix was re-run in a private harness copy, and both launchers were exercised against the stage.
- Out of scope: the research and DD docs (context only), code quality beyond doc-versus-code, and anything that needs the real devcontainer CLI or dockerd.
- Escalate: Claim 1 (premature "iteration 2 passed" status) and Claims 9b/33b (a planted run record can steer `image rm` through the unanchored `*verify-<T8>*` tag rule; low impact, but it contradicts a stated guarantee). Both are one-line fixes for the author before the `you: terminal` entry goes out.
- Decisions I made: execution logs stay in my job scratch dir (`/home/node/.claude/jobs/00bcf178/tmp/fc2r2.6ZcU88/logs/`), not `docs/reviews/execution-logs/`, because the brief allows only this report in the worktree. I extended my copy of the fake devcontainer with failure, forge, sleep and env-dump switches to test pipefail, verdict and credential claims. I graded Claim 1 Incorrect rather than Unverifiable, because the artifacts at 190fa1a4 contradict it.
