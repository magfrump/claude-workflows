Commit: 53770142

# Security Review: cc-verify Q-117 spike, final pass (iteration 2)

**Scope:** `git diff main...HEAD -- docs/working/spike-cc-verify-q117.md` at 53770142 (the whole file: the paste, the embedded `spike-q117.sh`, the step table, the residuals). The script text is byte-identical to `spike-q117.final.sh`; I checked this with `cmp` against the heredoc body extracted from the doc. Context read: main's `devcontainer-config/devcontainer.json` (every `localEnv`, `runArgs`, `mounts`, `postStartCommand`, header comment :1-30), `cc-isolated.sh` (every `config_dir` use, the `source` at :718, `probe_boundary` :595-625), main's Dockerfile `COPY`/sudoers lines, and the branch's `init-firewall.sh` (where the SNI proxy starts, :770-777 and :1421).
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report-cc-verify-spike.md` (iteration 2, k=3, merged) and iteration 1's `docs/reviews/security-review-2026-10-15-cc-verify-spike.md` (F1-F8). Verdicts that the fact-check executed are taken as established and are not re-verified here.

`doc:N` means line N of `docs/working/spike-cc-verify-q117.md` at 53770142. Execution was limited to a copy of the stub harness in my own scratch dir (`sec2.XT3zRh`; t1/ and the final script were not modified). No real docker, devcontainer, install.sh or cc-isolated was run. The only background process (a watcher, under `timeout 90`) had exited before this report was written, which I checked with `ps`.

## Trust Boundary Map

```
B1: [checkout .git refs (cc-isolated containers write it; agents merge to main)] → [bare clone, EXPECT_BR pin, five-path rule]       → [TREE staged on the host]
B2: [stage files (S2: merged tree; S4: same-uid writers of ~/cc-verify)]          → [step-3 cmp pins, post-bless manifest check]     → [host dockerd: build + create]
B3: [~/cc-verify (script, run-*.env, snap-*, log-*) (S4)]                         → [the paste's `cat >`/`bash`, `--clean`, redirects] → [user-uid process outside any agent sandbox, with docker]
B4: [user's terminal env (S6)]                                                    → [devcontainer.json localEnv substitution]          → [verify container running branch code]
B5: [launcher, CLI and container output (S5)]                                     → [vis/relay]                                         → [user's terminal, LOG, verdict]
B6: [docker daemon state (S7) + snap-RUN-before (S4)]                             → [teardown image-proof rule]                         → [docker rm / volume rm / image rm]
B7: [verify container root (branch init-firewall.sh; planted-main cc-sni-proxy.py)] → [rw bind of ~/cc-verify/VERIFY-T8]               → [host filesystem under ~/cc-verify]
```

B1, B2, B4, B5 and B6 were mapped in iteration 1 and are re-checked here. B3 is drawn wider than iteration 1's B6: it now includes the script file itself and every predictable path the script writes. B7 is drawn explicitly for this pass.

Input sources:

```
S1: refs/heads/main, refs/heads/<branch> — runtime-mutable (cc-isolated containers write .git) — UNTRUSTED for build/exec/daemon sinks;
                                           branch now pinned (EXPECT_BR); main still trusted only as "a name"
S2: merged-tree file contents            — derived from S1 — UNTRUSTED toward host sinks; accepted for in-container sinks
S3: ~/.config/claude-devcontainer        — install-time, human-reviewed — trusted as the comparison baseline
S4: ~/cc-verify/* (script, run-*.env, snap-*, log-*, stage-*) — runtime-mutable by any same-uid writer that can reach it —
                                           UNTRUSTED for exec, file-open (symlink-follow), removal-proof and bless sinks
S5: launcher/CLI/container output        — request-time, partly branch-produced — UNTRUSTED for terminal, verdict and file sinks
S6: user's shell env                     — the user's own — trusted source; the sink (container env) is UNTRUSTED
S7: docker daemon state (labels, ids, tags) — runtime-mutable by docker-capable processes — UNTRUSTED for removal decisions
S8: script constants (BASE, BRANCH, EXPECT_BR, BRANCH_PATHS, PINNED, regexes) — code-constant — trusted
```

From outside, the run takes in two refs (S1, now pinned for the branch), the stage and other files under `~/cc-verify` (S4), and output (S5). Iteration 1's fixes close the routes from the merged tree to the host daemon (F1-F3) and from planted run records to other projects' docker objects (F4). This pass finds that `~/cc-verify` itself (S4) is still treated as trusted in three places: the script the user is told to run, the files the script opens by predictable name, and the "proof" snapshot. The design gives the same writer class a much bigger lever there than the one F4 closed.

## Status of iteration 1's findings (F1-F8)

| # | Iteration-1 finding | Fix at 53770142 | Status |
|---|---|---|---|
| F1 | Dockerfile not pinned (base-image metadata, Critical) | `PINNED=(devcontainer.json Dockerfile)`, whole-file `cmp` against main's installed copies (doc:76, :311-316) | **Complete.** The runArgs are only `NET_ADMIN`/`NET_RAW` (devcontainer.json:58-60), and main's json has no `features`. The fact-check executed the refusals. |
| F2 | No pin to the reviewed tree (High) | `EXPECT_BR` (doc:66, :254) plus the five-path rule (doc:266-271). `main` by name is a documented residual (doc:529). | **Complete as scoped.** A planted `main` reaches only in-container code. Under B7, that code includes code that runs as root (`cc-sni-proxy.py` starts as root, init-firewall.sh:1421). That gives no host gain here: see "Cleared candidates". |
| F3 | Stage edit blessed after the gate | Post-bless manifest check of both pinned files (doc:346-352) | **Complete for the build.** A later re-read of the stage's devcontainer.json at step 8 has no re-check: Finding 4. |
| F4 | Planted run record steers `--clean` | Names derived from format-checked RUN/T8, pid recomputed from the path, images only with snapshot proof, tag prefix anchored (doc:93-142, :204-219) | **Complete for containers and volumes.** I executed it: a planted record touched neither the harness's container nor its volume. The image "proof" can itself be planted: Finding 5, informational, because only images with verify names are reachable. |
| F5 | Verdict attested by the code under test | Residual, documented (doc:528) | Accepted. Unchanged. |
| F6 | Credential forwarding | `unset GH_TOKEN OPENROUTER_API_KEY` (doc:57) | **Complete against main's json.** These are its only credential `localEnv` uses (grep: the others are TZ, CC_*). Finding 4 shows a post-check stage edit could add more at step 8. |
| F7 | Leftover VERIFY `.git` | Doc warnings (doc:40, :533) | Advisory fix. Acceptable for a spike. |
| F8 | Unfiltered terminal output | `vis`/`relay` on the launcher, exec, conflict list, step-3 diff and register tail | **Incomplete:** one unfiltered path remains (Finding 3). |

## Findings

#### 1. A writer of `~/cc-verify` can get its own code run, unsandboxed and with docker, by planting a run record and swapping `spike-q117.sh` before the user follows the script's `--clean` instruction

**Severity:** High
**Location:** `docs/working/spike-cc-verify-q117.md:43` (`cat > ~/cc-verify/spike-q117.sh`), `:239` (the refusal that tells the user to run it), `:192` (the same instruction after an incomplete teardown), `:410` (doc instruction)
**Boundary:** B3
**Move:** 1 (runtime-mutable ⇒ compromise-reachable), 5 (invert: what stops a file under `~/cc-verify` from being exec'd?)
**Confidence:** Medium. The mechanism follows from the script text. Whether a writer exists that can write `~/cc-verify` but cannot already run code outside its sandbox depends on the host's agent sandbox policy. It is the same writer that iteration 1's F4 assumed, and that the F4 fix was built to defeat.
**Legibility-target:** for-user

Evidence:
```
[ "${#left[@]}" -eq 0 ] || die "a previous run left state (${left[*]}). Run: bash $V/spike-q117.sh --clean"
```
(doc:239, preflight; read through to `trap` at :244)
```
      echo "TEARDOWN INCOMPLETE. Fallback: bash $V/spike-q117.sh --clean" >&2
```
(doc:192, inside `on_exit` :183-201, read whole)

The F4 fix makes a planted `run-*.env` harmless *as data*. But planting one is also a reliable way to make the user's next paste print `REFUSED: … Run: bash ~/cc-verify/spike-q117.sh --clean`. The paste has just rewritten that file. Between the refusal and the user typing the command (seconds at least), the same writer replaces `~/cc-verify/spike-q117.sh`. The user then runs the replacement from their own terminal. That process is outside every agent sandbox and has docker access, so it is root-equivalent on the host. The same holds days later after a real crash: the doc keeps the script in `~/cc-verify` on purpose and points the user back to it (doc:410). A writer that has only `~/cc-verify` therefore gets far more than F4's "delete another project's volume". Iteration 1 noted the replacement and declined to file it, on the ground that it "gains only what a write to any other user dotfile gains" (iteration-1 F4 note). That holds for an unsandboxed writer. It fails for exactly the sandboxed writer F4 was defending against, and the planted-record lure is new: it converts a narrow race into a prompt the script itself prints.

**Recommendation:** Never tell the user to execute a file that has sat in `~/cc-verify`. Make the fallback "re-paste the same block with `--clean` in place of the checkout path" (the paste rewrites the script immediately before running it), and change the two messages at doc:192 and :239 to match. Also add `~/cc-verify` to the agents' sandbox `denyWrite`, as decision 037 does for `~/.claude`, and name it under "Residual risks".

#### 2. The log and snapshot paths are predictable and opened through symlinks, so a `~/cc-verify` writer can make the paste overwrite any user-writable file. Executed: the run still reports `exit=0` with every CHECK ok

**Severity:** Medium
**Location:** `docs/working/spike-cc-verify-q117.md:241-245` (RUN, then LOG named from it), `:342` (`>"$LOG"`), `:356` (`relay >> "$LOG"`), `:144-157` (`snapshot`: `mkdir -p "$d"` and `> "$d/containers"` etc.)
**Boundary:** B3, B5
**Move:** 4 (TOCTOU: name revealed at :242, file first opened at :342), 12 (sweep of file-open sinks on `$V`)
**Confidence:** High for the mechanism (executed). Medium for exposure, which depends on the same writer as Finding 1.
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
RUN="$(date +%s)-$$"
printf 'RUN=%s\n' "$RUN" > "$V/run-$RUN.env"
...
LOG="$V/log-$RUN.txt"
```
(doc:241-245)
```
CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" --register "$WS" --profile "$PROFILE" >"$LOG" 2>&1 </dev/null \
```
(doc:342)

`run-<RUN>.env` appears in step 0 and announces RUN. `log-<RUN>.txt` is first opened at step 6, after the clone, the archive and the step-3 diff. A watcher has ample time to create `log-<RUN>.txt` as a symlink. `>` follows it and truncates the target. `relay >> "$LOG"` (doc:356) then appends every launcher and `devcontainer up` line, unindented. On the real host those lines include output from the branch's root-run postStart. Executed in the harness copy: a watcher planted `log-<RUN>.txt -> victim` when the record appeared. `victim` (one line, `VICTIM-ORIGINAL`) was replaced by 170 lines of register and probe output, and the run ended `RESULT spike-q117 exit=0` with all six CHECKs `ok`. The snapshot has the same shape: a pre-created `snap-<RUN>-before` symlink to a directory makes `mkdir -p` succeed, and `containers`, `volumes`, `images`, `main` are truncated and rewritten inside the target directory. Targets that matter: `~/.bashrc`/`~/.zshrc` (destroyed, or appended with output lines that become shell input), or a file in `~/.claude` that the writer's sandbox denies. That makes it a confused-deputy write. The CHECKs cover only `~/.config/claude-devcontainer`, so nothing reports the damage. `run-<RUN>.env` itself is safe in practice: the preflight glob also matches a dangling symlink, and the window before `printf` is microseconds.

**Recommendation:** Create one per-run directory with `mkdir "$V/run-$RUN.d"` (atomic, and it fails on an existing name or symlink), right after the preflight. Put the log and both snapshots inside it. Alternatively, `set -o noclobber` before the first write: bash then opens with `O_EXCL`, which refuses a pre-planted symlink. Either way, `mkdir -p` on `snap-*` becomes plain `mkdir`.

#### 3. Step 3 prints matching lines of the staged devcontainer.json to the terminal unfiltered (F8 incomplete)

**Severity:** Medium
**Location:** `docs/working/spike-cc-verify-q117.md:308-310`
**Boundary:** B5, B1
**Move:** 2 (assumed sanitisation: every other foreign print goes through `vis`)
**Confidence:** Low. It needs a planted `main` (devcontainer.json is not one of the branch's five paths, so its content comes from `main` resolved by name), and its effect depends on the terminal. That matches F8's own calibration.
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
if grep -n 'initializeCommand' "$S/devcontainer.json"; then
  die "the staged devcontainer.json names initializeCommand, which runs ON THE HOST."
fi
```
(doc:308-310, whole `if`)

Every other line the script did not write goes through `vis`. The doc says so at doc:414: "Every line the script did not write itself is shown indented under `  | ` with control bytes removed". This one does not. A planted `main` whose devcontainer.json has a line containing `initializeCommand` together with ESC/OSC bytes reaches the terminal raw: a screen rewrite, a CR-overwritten fake `RESULT`/`CHECK`, or an OSC 52 clipboard write, just as the user is told to copy lines back. The run then refuses, so this is terminal integrity, not a host action.

**Recommendation:** `grep -q 'initializeCommand' "$S/devcontainer.json" && die …`, or pipe the `grep -n` output through `vis | sed 's/^/  | /'`. The whole-file `cmp` that follows already refuses that file anyway.

#### 4. Step 8 re-reads the stage's devcontainer.json minutes after `check_manifest`, with no re-check, although main's identical copy is at hand

**Severity:** Medium
**Location:** `docs/working/spike-cc-verify-q117.md:385-387`; residual text `:530`
**Boundary:** B2, B4
**Move:** 4 (TOCTOU), 6 (follow the secrets)
**Confidence:** Medium. That the CLI's `exec` honours `remoteEnv`/`remoteUser` and substitutes `${localEnv:…}` there comes from the dev container spec. It was not executed.
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
out="$(devcontainer exec --workspace-folder "$WS" --override-config "$S/devcontainer.json" \
         --id-label "cc-project=$PID" bash -c "$Q117" </dev/null 2>&1 | relay)" \
```
(doc:385-386)

The last pin on the stage's devcontainer.json is the launcher's `check_manifest` inside step 7. Step 8 then reads the file again, after the whole build and probe. A stage writer (S4) who edits it in that window can add `"remoteEnv": {"K": "${localEnv:AWS_SECRET_ACCESS_KEY}"}` or similar. The CLI resolves those from this shell's environment, so values beyond the two that F6 unsets reach a container running branch code, with GitHub egress open. The writer can also set `remoteUser: root`. The residual at doc:530 accepts a swap only "between the launcher's `check_manifest` and the docker build reading it". This read is a separate, later one. Step 3 has already proved the file byte-identical to `$MAIN_CFG/devcontainer.json`.

**Recommendation:** Pass `--override-config "$MAIN_CFG/devcontainer.json"` at step 8 (identical by step 3, and outside `~/cc-verify`). This is a one-token change and closes the window, so nothing needs re-checking.

#### 5. The image "proof" is itself a same-uid-writable file, so "a planted record removes no image" is overstated (bounded to verify-named images)

**Severity:** Informational
**Location:** `docs/working/spike-cc-verify-q117.md:117-134` (teardown image rules), `:494` (step-table claim), `:22`, `:513` (stale wording)
**Boundary:** B6
**Move:** 11 (bypass enumeration for the new image rule)
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
| … A planted `run-*.env` … It has no snapshot, so it removes no image at all. …
```
(doc:494)
```
    local before="$V/snap-$RUN-before/images"
```
(doc:117; the image loops run to :134, read whole)

The proof is "`snap-<RUN>-before/images` exists and does not list the id". The writer who plants the record can plant that file too, for example empty. Executed: `run-1-1.env` (`RUN=1-1`, `T8=deadbeef`) plus an empty `snap-1-1-before/images`, then `--clean`, issued `docker image rm vsc-verify-deadbeef-x:latest`. The reach stays narrow. The container-image rule needs a container labelled with a `VERIFY-<hex>` pid, which a writer without docker cannot create. The tag rule needs the anchored prefix `vsc-verify-<8 hex>-` or `vsc-verify-<8 hex>:`, which in practice is a spike build. (The exception would be a user project folder literally named `verify-<8 hex>-…`.) So I am not filing this as a deletion of something the spike did not create. The doc's wording is too strong, though. Also, Not-verified #1 (doc:513) still describes the removed unanchored rule ("any image whose tag contains `verify-<TREE8>`").

**Recommendation:** At doc:494, say that the image rules depend on a snapshot that a `~/cc-verify` writer could also plant, and that this reaches only `vsc-verify-<8 hex>` builds. Update doc:513 to the anchored `vsc-verify-<TREE8>-` prefix. Finding 2's per-run `mkdir` directory would also make the snapshot harder to plant.

## Cleared and untested candidates

Guardrails exercised this pass: the step-3 pins plus the post-bless check, the image-proof rule, and `relay`.

| Candidate | Status |
|---|---|
| Setuid-root file planted into the rw-bound `VERIFY-<T8>` by root in the container (branch init-firewall.sh via sudo; planted-main `cc-sni-proxy.py` before its privilege drop). runArgs drop no caps (devcontainer.json:58-60). | Traced, **cleared for this host**: the user is docker-capable (root-equivalent already), and agent sandboxes (bwrap) run with no_new_privs, so setuid does not elevate there. It is a teardown-blocking leftover (root-owned dir), which doc:523 already covers. Not executed. |
| Planted record removing another project's container or volume | Executed: none touched (harness container `charness111`, volume `cc-aaaaaaaaaaaa-claude-config` intact). Cleared. |
| `RUN=-` (the `--clean` sed allows empty digit runs) | Traced: `teardown`'s `^[0-9]+-[0-9]+$` fails, so nothing is removed and the record stays (DoS only). Cleared. |
| `docker image ls --no-trunc` ID vs `docker inspect .Image` format mismatch (e.g. containerd image store) | Untested (no docker here; doc Not-verified #8). The failure direction is *open*: no id would match the snapshot, so every image a verify-labelled container ran counts as new and gets `rm -f`. Bounded, because such a container runs the stage build. Worth a host check before the image rule is reused in a tool. |
| `docker ps --filter ancestor=<id>` semantics on the host | Untested (doc Not-verified #4). If it under-reports, a shared image could be `rm -f`'d. That still needs a verify-labelled container to have run it. |
| Workspace content: `VERIFY-<T8>` checks out the checkout's HEAD branch (unpinned, S1), and under `--override-config` the CLI sets configFilePath to `<ws>/.devcontainer/devcontainer.json` (devcontainer.json:9-16) | Untested (carried over from iteration 1). Main's json has absolute build paths and no features. Whether the CLI reads anything else from the workspace's `.devcontainer/` is unverified. `git clone --no-checkout` + `checkout --detach "$BR_SHA"` would remove the question. |
| Tar extraction through a symlink in the merged tree (doc:291-293) | Traced: a git tree cannot hold both a symlink `a` and entries under `a/`, and symlinks are refused after extraction. Cleared. |
| `>> run-$RUN.env` (doc:279) after a swap to a symlink | Traced: appends only `T8=<8 hex>`. Low value. Subsumed by Finding 2's fix. |

Because untested candidates remain against the image rule, it does not appear in Endorsement Claims.

## Endorsement Claims

- **Claim:** In `teardown`, every `docker rm`/`volume rm` target is derived from `T8` (anchored `^[0-9a-f]{8}$`) via `sha256("$VP/VERIFY-$T8")`. In the executed planted-record run, no other project's container or volume was touched.
  **Location:** `docs/working/spike-cc-verify-q117.md:97-113`
  **Evidence:** executed (harness copy, `--clean` with `run-1-1.env`, T8=deadbeef)
  **Verified:** the docker calls recorded in `dstate/calls`. The harness container and volume survived.
  **Not verified:** real docker's `--filter label=` matching. The fake implements exact match only.
  **route: code-fact-check**
- **Claim:** `unset GH_TOKEN OPENROUTER_API_KEY` covers every credential-bearing `${localEnv:…}` in main's `devcontainer.json`. The others are TZ and CC_* values that the script sets.
  **Location:** `docs/working/spike-cc-verify-q117.md:57`; `devcontainer-config/devcontainer.json:22-131`
  **Evidence:** read-static (grep of `localEnv`)
  **Verified:** the full `localEnv` list in main's json.
  **Not verified:** a stage-side edit read at step 8 (Finding 4).
- **Claim:** In `--register`/`--probe-only`, main's launcher touches `config_dir` only to write manifests, project profiles and receipts, to test `egress/<p>.txt` for readability, and to hand its path to the CLI. Its only `source` is from `CC_ISOLATED_DIR`.
  **Location:** `devcontainer-config/cc-isolated.sh:73-81, 206-216, 283-285, 440-443, 718, 820-835`
  **Evidence:** read-static (grep of `config_dir)`, `source`). The fact-check executed the no-staged-file-executed claim.
  **Verified:** each listed line.
  **Not verified:** what the devcontainer CLI itself reads from the stage beyond the two pinned files (the build context goes into the image).
  **route: code-fact-check**

## Primitive sweep

Primitive: file open/create on a predictable path under `$V` (symlink-following `>`, `>>`, `mkdir -p`, `cat >`)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `doc:43` `cat > ~/cc-verify/spike-q117.sh` | S4 | none | Finding 1 (the file later exec'd) |
| `doc:146-150` snapshot `mkdir -p`, `> $d/*` | S4 | none | Finding 2 |
| `doc:152-156` `>> "$d/main"` | S4 | none | Finding 2 |
| `doc:242` `> run-$RUN.env` | S4 | preflight glob (matches dangling symlinks) | cleared: microsecond window |
| `doc:279` `>> run-$RUN.env` | S4 | none | cleared: fixed low-value content |
| `doc:290`, `:294` `mkdir "$S.raw"`, `mkdir "$S"` | S4 | atomic `mkdir`, existence check :277 | cleared |
| `doc:302` `> "$S/claude-home/.manifest"` | S4 | inside a dir this run just created | cleared: stage-writer residual (doc:530) |
| `doc:342` `>"$LOG"` | S4 | none | Finding 2 (executed) |
| `doc:356` `>> "$LOG"` | S4/S5 | none | Finding 2 |

Primitive: destructive docker calls
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `doc:107` `docker rm -f` by label | S7, pid from T8 | anchored hex, path-derived pid | cleared (executed) |
| `doc:111` `docker volume rm cc-$pid-*` | pid from T8 | same | cleared (executed) |
| `doc:122` `docker image rm -f $img` | S7 | sha256 regex, snapshot proof, `ancestor` check | Finding 5. Format-mismatch candidate untested. |
| `doc:132` `docker image rm "$tags"` | S7 | anchored `vsc-verify-$T8-`/`:` prefix, snapshot proof, no `-f` | Finding 5 (executed) |

Primitive: `rm -rf`
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `doc:135` stage/raw/VERIFY | T8 | anchored hex | cleared (symlink removed, not followed) |
| `doc:138` `src-$RUN.git` | RUN | `^[0-9]+-[0-9]+$` | cleared |
| `doc:179`, `:195`, `:216` snap dirs | RUN | RUN from own run or validated `--clean` | cleared |
| `doc:304` `$S.raw` | t8 from TREE regex | created by this run | cleared |

Primitive: unfiltered terminal output of foreign text
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `doc:261-262` merge-tree output | S1/S2 | vis + indent | cleared |
| `doc:308` `grep -n initializeCommand` | S2 | none | Finding 3 |
| `doc:313` `diff -u` | S2 | vis + indent | cleared |
| `doc:343` register log tail | S5 | vis + indent | cleared |
| `doc:356`, `:386` relay | S5 | vis + indent | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Planted record + swapped `spike-q117.sh` → user runs attacker code via the `--clean` instruction | High | B3 | `doc:43, :192, :239, :410` | Medium |
| 2 | Predictable log/snapshot paths followed through symlinks overwrite any user file (executed) | Medium | B3, B5 | `doc:241-245, :342, :356, :144-157` | High (mechanism) |
| 3 | `grep -n initializeCommand` prints staged lines unfiltered (F8 incomplete) | Medium | B5, B1 | `doc:308-310` | Low |
| 4 | Step 8 re-reads the stage devcontainer.json after `check_manifest` | Medium | B2, B4 | `doc:385-387` | Medium |
| 5 | Image proof snapshot is plantable; doc:494 and :513 wording | Informational | B6 | `doc:117-134, :494, :513` | High |

## Overall Assessment

The iteration-1 fixes hold for what they targeted. With the Dockerfile and devcontainer.json pinned and re-checked after the bless, and the branch pinned, a hostile tree no longer reaches the host daemon. The F4 rewrite means a planted record cannot reach another project's containers or volumes. The remaining problems share one root cause: the design hardens `~/cc-verify` as *data* but still trusts it as *code and file targets*. The script the user is told to re-run, and the log and snapshot paths, all live there under predictable names. For the writer class that F4 assumed, Finding 1 is a bigger prize than anything F4 closed. All five findings can be fixed in place in a few lines: re-paste instead of re-running the stored script, one atomic per-run directory (or `noclobber`), `grep -q`, and `$MAIN_CFG/devcontainer.json` at step 8. They do not point to an architectural problem. The most important fix is Finding 1's: change the `--clean` fallback to a re-paste, and add `~/cc-verify` to agent `denyWrite`. No findings within the code paths read beyond those listed; endorsement claims pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved to the path named at the end of this prompt, structured per your role's skill, with a `Commit: 53770142` first line."

This report is saved at `docs/reviews/security-review-2026-10-15-cc-verify-spike-final.md` with that first line, structured per `skills/security-reviewer/SKILL.md`. Against the user goal (a reviewed, safe one-paste host spike that live-verifies a branch without installing it), the paste does not install the branch and keeps branch content off the host daemon. "Safe" still has a gap for a sandboxed same-uid writer (Findings 1-2), which the doc's own threat model (decision 037, iteration-1 F4) treats as in scope.
