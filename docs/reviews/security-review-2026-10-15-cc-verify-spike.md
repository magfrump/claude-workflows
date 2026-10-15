Commit: 12fcb61c

# Security Review: cc-verify Q-117 spike (one-paste host verify without install)

**Scope:** `git diff 22a4bb1f..12fcb61c`: `docs/working/spike-cc-verify-q117.md` (the paste and the embedded `spike-q117.sh`, doc:33-335). Context read: `devcontainer-config/devcontainer.json` (whole file), `devcontainer-config/cc-isolated.sh` (`project_id`, `ws_fingerprint`, `rebuild_hint`, `probe_boundary`, the host-tool sourcing block, `main()`'s probe path :800-885), `devcontainer-config/install.sh` (`repo_git`, `git_state_gate`), decision 037 "Trust model", `docs/working/dd-branch-verify-without-install.md` (pre-mortem).
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report-cc-verify-spike.md` (Stage 1, k=1). Its incorrect claims (6, 9a, 24b, 3, 11b) are taken as established. They are cross-referenced below, not re-verified.

Line references `doc:N` are lines of `docs/working/spike-cc-verify-q117.md`. Nothing was executed for this review: no docker, devcontainer CLI, install.sh or cc-isolated, and no process was started.

## Trust Boundary Map

```
B1: [checkout .git refs + objects (agent-writable: cc-isolated bind mount, bare-host agents)] → [bare clone, rev-parse refs/heads/{main,branch}, merge-tree] → [TREE id the host trusts]
B2: [merged-tree payload files (Dockerfile, init-firewall.sh, egress/, claude-home)]     → [step-3 gate: devcontainer.json cmp only]                → [stage = config dir + docker build context]
B3: [stage Dockerfile + its base image's labels]                                         → [devcontainer CLI + host dockerd (build, create)]        → [build-step sandboxes; container create flags]
B4: [user's terminal environment (GH_TOKEN, OPENROUTER_API_KEY)]                         → [devcontainer.json containerEnv ${localEnv:…}]           → [verify container running branch code as root]
B5: [verify container stdout (Q-117 block inside the branch-built image)]                 → [grep verdict; tee /dev/stderr]                          → [user's verdict, user's terminal, Live-verified trailer]
B6: [~/cc-verify contents: stage, run-*.env, the script (same-uid writable)]             → [launcher bless at step 6; --clean]                      → [blessed manifest; docker rm / volume rm / image rm]
B7: [scratch clone's .git, bind-mounted rw into the verify container]                   → [host git: probe's ws_fingerprint; any later user git]  → [host process as the user]
```

All seven are new: the spike introduces them (none existed for a branch before, because a branch reached the host only through install.sh's review-and-y).

Input sources:

```
S1: checkout refs/heads/main, refs/heads/fix/egress-dnsmasq-ipset — runtime-mutable — UNTRUSTED for build/exec/daemon sinks
                                    (cc-isolated containers write .git through the bind mount; agents in this
                                    project also merge to main locally); trusted only as "a name to resolve"
S2: merged-tree file contents       — derived from S1   — UNTRUSTED for host-daemon sinks (build, create flags);
                                    acceptable for in-container sinks (that is what is being verified)
S3: ~/.config/claude-devcontainer   — install-time, human-reviewed via install.sh y — trusted as comparison
                                    baseline (037 accepts that a writer reaching it can re-bless directly)
S4: ~/cc-verify/* (stage, run-*.env, spike-q117.sh) — runtime-mutable by any same-uid process — UNTRUSTED for
                                    bless, docker-removal and exec sinks
S5: verify-container stdout         — request-time, produced by branch code — UNTRUSTED for verdict and terminal sinks
S6: user's shell env                — deploy-time (user's own) — trusted as a source; sink is UNTRUSTED (B4)
S7: docker daemon state (labels, image ids, tags) — runtime-mutable by any docker-capable process — UNTRUSTED for removal decisions
S8: script constants (BASE, BRANCH, EXPECT_PAYLOAD, DC_ITEMS) — code-constant — trusted
```

What enters from outside: the content of two refs in an agent-writable repository (S1→S2), and container output (S5). The design's stated assumption is that only `devcontainer.json` (plus host-sourced launcher code) can turn staged content into host effects, so pinning that one file to main's installed copy keeps branch code off the host. Findings 1-2 show that assumption is too narrow: the Dockerfile reaches the host daemon too, and nothing pins S1 to what was reviewed.

## Findings

#### 1. The devcontainer.json gate does not cover the Dockerfile, which reaches the host daemon and can set the container's create flags

**Severity:** Critical
**Location:** `docs/working/spike-cc-verify-q117.md:244-258` (step 3), `:233-236` (Dockerfile staged unchecked), `devcontainer-config/devcontainer.json:24-26`
**Boundary:** B2, B3
**Move:** 11 (bypass enumeration for the gate), 1 (trust per sink)
**Confidence:** Medium. The mechanism depends on the devcontainer CLI's image-metadata merge, which could not be run here (no CLI, no network). It matches the published dev container spec as I know it.
**Legibility-target:** for-user

Evidence:
```
# --- 3. devcontainer.json is host-trusted config: it must equal main's installed copy --
...
echo "   staged files that differ from main's install (expect init-firewall.sh; more if main's install is behind main):"
for i in "${DC_ITEMS[@]}" claude-home; do
  [ "$i" = claude-home ] && [ ! -e "$MAIN_CFG/claude-home" ] && { echo "     claude-home (none installed)"; continue; }
  diff -rq "$MAIN_CFG/$i" "$S/$i" >/dev/null 2>&1 || echo "     $i"
done
```
(doc:244, :254-258; step 3 ends at :258, read in full)
```
    "dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile",
    "context": "${localEnv:CC_CONFIG_DIR}",
```
(devcontainer.json:25-26)

Step 3 refuses only a changed `devcontainer.json`. Every other differing payload file, the Dockerfile included, is listed and then used. The pinned `devcontainer.json` points the build at the stage's Dockerfile, so branch content picks the image. That content reaches the host in two ways the gate's rationale ("runArgs, mounts, lifecycle commands unchanged", doc:253) does not cover:

- **Create flags via image metadata.** The devcontainer CLI merges the `devcontainer.metadata` label of the Dockerfile's final base image into the effective config. Per the dev container spec, that metadata can set `privileged`, `capAdd`, `securityOpt`, `mounts`, `init`, `entrypoint` and the container-side lifecycle commands. Not `initializeCommand`. `privileged` is OR-ed across entries, and mounts and caps are unioned. A branch whose final stage is `FROM <image whose label sets "privileged": true or a bind of />` followed by main's own instructions gets a privileged container with the reviewed `devcontainer.json`. A public devcontainer image built with the docker-in-docker feature carries such a label (unverified here). The branch's `init-firewall.sh` then runs as root through `postStartCommand` (devcontainer.json:141). That is root on the host in one step, before `probe_boundary` runs. The probe would pass anyway if the Dockerfile keeps main's instructions after the `FROM`, because its checks look for files the branch can bake in.
- **Build-time daemon features.** A `# syntax=` frontend image, `RUN --network=host` (subject to the daemon's entitlement default) and `ADD <url>` all run on the user's dockerd with the user's registry credentials. See "Untested bypass candidates".

For *this* branch the risk is latent: the fact-check's E14 shows the merged tree's only payload change is `init-firewall.sh`. But the spike resolves the branch at run time from an agent-writable checkout (Finding 2), so the tree that runs is not necessarily the tree that was reviewed. Its own pre-mortem names this bypass family ("A hostile `devcontainer.json` on the branch … Under the status quo the install diff showed it. Here nothing would", dd-branch-verify-without-install.md:178) but closes only the `devcontainer.json` door.

**Recommendation:** Refuse unless every staged file outside an explicit in-container allowlist (`init-firewall.sh`, `cc-sni-proxy.py`, `egress/`, `claude-home/`, `link-claude-home.sh`) is byte-identical to main's installed copy. That makes the `Dockerfile` (and the host tools, which are hashed) part of the identity rule the json already gets. For a branch that has to change the Dockerfile, stop with a diff and a y/N, as install.sh does, rather than proceeding.

#### 2. Nothing pins the verified tree to the reviewed one: the refs are read at run time from an agent-writable checkout, and no human diff stop replaces install.sh's review

**Severity:** High
**Location:** `docs/working/spike-cc-verify-q117.md:198-216` (step 1), `:50-51`
**Boundary:** B1
**Move:** 1 (runtime-mutable ⇒ compromise-reachable), 4 (TOCTOU between review and run)
**Confidence:** High
**Legibility-target:** for-user

Evidence:
```
git clone -q --bare --no-local -- "$REPO_TOP" "$SRCGIT" </dev/null || die "could not clone $REPO_TOP."
G=(git -C "$SRCGIT" -c core.hooksPath=/dev/null -c core.fsmonitor=false)
MAIN_SHA="$("${G[@]}" rev-parse --verify -q "refs/heads/$BASE^{commit}")" || die "no local branch $BASE in $REPO_TOP."
BR_SHA="$("${G[@]}" rev-parse --verify -q "refs/heads/$BRANCH^{commit}")" || die "no local branch $BRANCH in $REPO_TOP."
```
(doc:198-201; step 1 continues to :220, read)

`BASE=main` and `BRANCH=fix/egress-dnsmasq-ipset` are names. They are resolved when the user pastes, from the checkout's `.git`, which a cc-isolated container writes through its bind mount (037 "Trust model"). In this project agents also merge to `main` locally. Whatever both refs point to at paste time is staged, built and booted, and no human sees a diff. The `merged tree=` line is printed, but nothing compares it to the reviewed one. The spike's own design context carries 037's pruned-worktree rule forward: "stage from a resolved tree id, never from a worktree or branch name read later" (dd:18). Here the tree id *is* resolved from names read later. install.sh accepts the same "agent rewrites the commit" residual (037: "Neither target catches an agent that rewrites the commit…"), but only behind a human-read diff, a y, and an agent gate. The spike has none of the three. That is by design for the gate, but the diff stop goes with it. This is the enabler for Finding 1 and for the verdict-forgery case in Finding 5.

**Recommendation:** Pin the reviewed ids in the paste and refuse on any mismatch: `EXPECT_TREE=65e65962b12e40d59c586aa429e580388e051cd9`, plus the two commit ids if the trailer is meant to name them. A moved ref then refuses instead of running unreviewed content, and the pin costs one line per verify. The future `cc-verify` tool should take the tree id as an argument, not branch names.

#### 3. The step-3 gate runs before the bless, so a stage edit in between is blessed rather than caught; the doc's residual claim understates the window

**Severity:** Medium
**Location:** `docs/working/spike-cc-verify-q117.md:249-252` (gate), `:278-282` (bless at step 6), `:442` (residual claim)
**Boundary:** B6, B2
**Move:** 4 (TOCTOU)
**Confidence:** Medium. The mechanism is certain. Whether any same-uid writer exists that can write `~/cc-verify` but lacks docker itself is a host-configuration question (see the note in Finding 4).
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
if ! cmp -s "$MAIN_CFG/devcontainer.json" "$S/devcontainer.json"; then
```
(doc:249, step 3) … then, after step 4's clone and docker queries:
```
CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" --register "$WS" --profile "$PROFILE" >"$LOG" 2>&1 </dev/null \
```
(doc:278)
```
- **Stage swapped between review and build.** A same-uid process could rewrite a stage file after step 3. Main's launcher hashes the stage's enforcement files at bless and at `--probe-only` (cc-isolated.sh:332-350), which covers `devcontainer.json`, `Dockerfile` and `init-firewall.sh`. A swap-and-revert inside that window stays open
```
(doc:442)

The launcher's bless (`register_project` → `bless_manifest`) hashes whatever the stage holds at step 6. A `devcontainer.json` replaced after the `cmp` at doc:249 (for example with `--privileged` in `runArgs`, or an `initializeCommand`) is hashed into the stage manifest. `check_manifest` at `--probe-only` then *confirms* it. The window spans step 4's `git clone` and two docker queries (seconds). It needs no revert. The residual at doc:442 implies that only a swap-and-revert gets through, which is wrong for the gate-to-bless interval. `~/cc-verify` is a fixed, predictable path, and `stage-<tree8>` is printed before the window opens (doc:216, :223).

**Recommendation:** After step 6, check that the stage manifest's entry for `devcontainer.json` (and the Dockerfile, once Finding 1 pins it) equals `sha256sum` of main's installed copy, and refuse otherwise. `check_manifest` then catches any later swap up to the CLI's own read. Simpler still: since the file must equal main's, copy main's installed `devcontainer.json` into the stage (after the merged-tree comparison) and re-check it after the bless.

#### 4. `--clean` trusts same-uid-writable run records to drive docker removals (confused deputy)

**Severity:** Medium
**Location:** `docs/working/spike-cc-verify-q117.md:151-168` (`--clean`), `:64-93` (`teardown`)
**Boundary:** B6
**Move:** 5 (invert the access model), 2 (format-checked is not ownership-checked)
**Confidence:** Medium. The mechanism was reproduced by the fact-check (E5, Claim 24b). Who can plant a record depends on the host's sandbox policy.
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
    PID="$(sed -n 's/^PID=\([0-9a-f]\{12\}\)$/\1/p' "$f" | head -1)"
    IMG="$(sed -n 's/^IMG=\(sha256:[0-9a-f]\{64\}\)$/\1/p' "$f" | head -1)"
    IMG_NEW=0; [ -n "$IMG" ] && IMG_NEW=1
```
(doc:159-161; the enclosing `for f` loop ends at :166, read)

Building on fact-check Claim 24b, which is not restated here. The regexes check *format*, not *ownership*. A format-valid `PID` names any project, so `--clean` removes that project's containers and its `cc-<PID>-claude-config` volume (credentials, memory). Any format-valid `IMG` is `docker image rm -f`'d. The writer gains docker authority it may not have itself. A bare-host agent whose sandbox lets it write `~/cc-verify` but denies the docker socket can make the user's own `--clean` delete another project's credential volume. The doc's own instruction drives the user to run `--clean` after any crash (doc:338, and the refusal at :187). The 037 precedent keeps such writes out through `denyWrite ~/.claude`. `~/cc-verify` is in no `denyWrite`. Note: the same writer could also replace `spike-q117.sh` between the paste's `cat >` and `bash` (doc:33, :335). That gains only what a write to any other user dotfile gains, so it is noted, not filed.

**Recommendation:** In `--clean`, remove a container only if its `devcontainer.local_folder` label (set by the devcontainer CLI; verify the label name on the host) equals `$V/VERIFY-$T8`. Remove the volumes only when that check held for the PID, or when `PID` equals `sha256("$V/VERIFY-$T8")` recomputed from T8 (the path is deterministic). Never remove `IMG` from a record. Remove only images whose tag carries `verify-$T8`, and only if no container outside the label uses them.

#### 5. The Q-117 verdict is attested by the code under test

**Severity:** Medium
**Location:** `docs/working/spike-cc-verify-q117.md:313-333` (steps 8-9)
**Boundary:** B5
**Move:** 1 (trust per sink: container output toward a security verdict)
**Confidence:** Medium
**Legibility-target:** for-user

Evidence:
```
out="$(devcontainer exec --workspace-folder "$WS" --override-config "$S/devcontainer.json" \
         --id-label "cc-project=$PID" bash -c "$Q117" </dev/null 2>&1 | tee /dev/stderr)" \
```
(doc:314-315)
```
printf '%s\n' "$out" | grep -qx 'FAIL lines for dl.google.com (expect 0): 0' || v=fail
```
(doc:325; the verdict block ends at :333, read)

The block runs inside an image the branch's Dockerfile built, after the branch's `init-firewall.sh` has run as root (`sudo` in `postStartCommand`). Root at that point can replace `curl`, `getent` or `grep`, or rewrite `/run/cc-sni-proxy/proxy.log`, so the host-side grep sees the pass strings regardless of real behaviour. The output is the only evidence the verdict uses. A pass therefore shows that the branch did not sabotage its own test, not that the firewall works, and it is meant to back a `Live-verified` trailer, which is itself a security control. This is the same trust `probe_boundary` already gives main's own `init-firewall.sh`, so it is a pre-existing class. The spike extends it to unreviewed content, which Finding 2 makes reachable. Fact-check Claim 9a (a real fail reported as `no-rotation`, exit 2) is a separate integrity defect on the same sink.

**Recommendation:** With Findings 1-2 fixed (pinned tree, Dockerfile identical to main's), only `init-firewall.sh` and `cc-sni-proxy.py` remain branch-controlled, and the human reviews those in the diff before merging anyway. State in the doc that the verdict is self-attested within that scope, and fix Claim 9a so a fail always wins over `no-rotation`.

#### 6. Host credentials from the user's terminal pass into a container running unreviewed branch code, behind the branch's own firewall

**Severity:** Medium
**Location:** `devcontainer-config/devcontainer.json:116`, `:131`; spike `docs/working/spike-cc-verify-q117.md:278`, `:285`, `:313-315`
**Boundary:** B4
**Move:** 6 (follow the secrets)
**Confidence:** Medium. Exposure depends on whether the user's terminal exports either variable. The spike neither checks nor clears them.
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
    "OPENROUTER_API_KEY": "${localEnv:OPENROUTER_API_KEY}",
    "GH_TOKEN": "${localEnv:GH_TOKEN}"
```
(devcontainer.json:116, :131; `containerEnv` closes at :132)

The launcher runs `devcontainer up` with the spike's environment, which is the user's terminal environment. A `GH_TOKEN` or `OPENROUTER_API_KEY` exported there (in a shell profile, for example) becomes `containerEnv` in a container whose root-run startup code and egress firewall both come from the branch. devcontainer.json's own comments describe these as opt-in, per-session credentials. For a verify run nobody opted in. The paste is designed to be run "while other sessions keep running", from whatever terminal the user has open. Even under main's firewall GitHub is always reachable, so a token exported there can leave.

**Recommendation:** Run both launcher calls and the `devcontainer exec` under `env -u GH_TOKEN -u OPENROUTER_API_KEY`, or refuse in preflight when either is set. The preflight already refuses an inherited `CLAUDE_DEVC_CONFIG_DIR` for the same reason.

#### 7. A leftover `VERIFY-<tree8>` after an incomplete teardown holds a `.git` that branch code could write

**Severity:** Medium
**Location:** `docs/working/spike-cc-verify-q117.md:262-263` (workspace clone), `:86` (its only removal), `:338`; launcher `cc-isolated.sh:379-384`, `:603-616`
**Boundary:** B7
**Move:** 3 (error path)
**Confidence:** Low. It requires a failed or skipped teardown, and then the user running git in that directory (a git-aware shell prompt is enough).
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated",
```
(devcontainer.json:134)
```
  head="$(git -C "$ws" rev-parse HEAD 2>/dev/null || echo 'no-head')"
  remote="$(git -C "$ws" config --get remote.origin.url 2>/dev/null || echo 'no-remote')"
```
(cc-isolated.sh:381-382, `ws_fingerprint`, called by `probe_boundary` at :603 *after* `devcontainer up`)

The scratch clone is bind-mounted read-write, so the branch's root startup code can plant `core.fsmonitor`, `core.hooksPath` or hooks in `/workspace/.git`. On the normal path, the only host git that reads it afterwards is the probe's `rev-parse HEAD` / `config --get`, which I do not expect to execute config commands (037 probed 17 keys on git 2.39.5 with none firing; not re-tested here), and the trap then `rm -rf`s it. After a `kill -9` or a failed removal, the planted state stays in `~/cc-verify/VERIFY-<tree8>` until `--clean`. The doc points the user at that directory, and the user may `cd` into it to look. The exit scan that guards real checkouts runs only for the `launch` action (cc-isolated.sh:843), which the spike never uses.

**Recommendation:** Keep the workspace's `.git` out of the container's reach (e.g. clone with `--separate-git-dir` outside `~/cc-verify/VERIFY-*`), or say at doc:338 not to run git inside a leftover `VERIFY-*` and to use `--clean` or `rm -rf` only.

#### 8. Raw container output is copied to the user's terminal

**Severity:** Medium
**Location:** `docs/working/spike-cc-verify-q117.md:285`, `:315`, `:392`
**Boundary:** B5
**Move:** 2 (implicit sanitisation)
**Confidence:** Low. Whether it works depends on the terminal (OSC 52 clipboard-write support and its defaults vary).
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
         --id-label "cc-project=$PID" bash -c "$Q117" </dev/null 2>&1 | tee /dev/stderr)" \
```
(doc:315)
```
**What to paste back:** the `RESULT` lines, every `CHECK` line, and the `NOTE` block if one appeared.
```
(doc:392)

Bytes printed by branch-built binaries (and the launcher's build/postStart output at doc:285) reach the terminal unfiltered. Escape sequences can rewrite what the user sees (forged `RESULT`/`CHECK` lines) or, on terminals that honour OSC 52, set the clipboard just as the user is told to copy lines out of the output. Main's launcher has the same exposure for its own output. The spike adds unreviewed producers.

**Recommendation:** Filter the container stream before display (e.g. `LC_ALL=C tr -d '\000-\010\013-\037\177'`, or `cat -v`), and print the `RESULT`/`CHECK` lines from host-side variables, as the script already does for the final verdict.

## Untested bypass candidates

Gate under test: step 3's "staged `devcontainer.json` must equal main's installed copy", read as the guard for "no branch content reaches the host".

| Candidate | Status |
|---|---|
| Byte tricks in the JSONC (comments, duplicate keys, Unicode escapes) | Tested by reading: `cmp -s` of the whole file (doc:249). Any byte difference refuses. Cleared. |
| `initializeCommand` added | Tested by reading: grep plus the whole-file `cmp` (doc:246-252). Cleared. |
| Final base image's `devcontainer.metadata` label (privileged, mounts, capAdd, securityOpt) | Analysed statically → Finding 1. Not executed: no devcontainer CLI or network here. |
| Stage swapped between gate and bless | Traced → Finding 3. |
| `# syntax=<image>` BuildKit frontend in the staged Dockerfile | Untested: needs dockerd/BuildKit. A custom frontend runs on the user's daemon with the user's registry auth. Its reach beyond the build is bounded by BuildKit entitlements, not verified. |
| `RUN --network=host` in the staged Dockerfile | Untested: whether the user's daemon and the CLI's `docker buildx build` invocation allow the `network.host` entitlement by default was not verified. If allowed, build steps reach host-local services. |
| `RUN --mount=type=cache` poisoning main's later builds | Partly tested: main's Dockerfile uses no `--mount` (grep), so no shared cache id to poison today. Layer-cache poisoning by key collision is not believed possible. Not executed. |
| Workspace `.devcontainer/` content under `--override-config` (the CLI sets configFilePath to the workspace's path, devcontainer.json:9-16) | Partly tested: main's json has only absolute build paths and no `features`. Whether the CLI reads anything else from `<workspace>/.devcontainer/` (a lockfile, for example) is untested. |
| `git clone --no-local` runs `upload-pack` inside the agent-writable checkout with its local config (doc:198) | Untested: git restricts `uploadpack.packObjectsHook` to protected config. Other upload-pack config paths on the host's git version not probed. install.sh's `git_state_gate` is not applied to the source. |
| Bare-repo `attr.tree` (git ≥ 2.42 reads HEAD's `.gitattributes` in a bare repo) assigning a merge driver or filter defined in the user's global config during `merge-tree`/`archive` | Untested: this sandbox has git 2.39. The doc's residual (doc:443) covers filters but not merge drivers. Same class, user-global config only. |
| Verify container probing peer cc-isolated containers on the shared default bridge (no `--network` in `runArgs`) | Untested: depends on peers' INPUT rules in main's `init-firewall.sh`, not read. A compromised agent container already has the same reach, so this is not new exposure. |

Because candidates remain untested, the step-3 gate does not appear in Endorsement Claims.

## Endorsement Claims

- **Claim:** Every `rm -rf` target in `teardown` and `--clean` is `"$V/<fixed prefix>-$X"` with X matched by an anchored hex or digit regex, so a planted record did not steer a removal outside `~/cc-verify` in the fact-check's probe.
  **Location:** `docs/working/spike-cc-verify-q117.md:79-91`, `:157-165`
  **Evidence:** executed (fact-check E5, Claim 24a). Read-static by me.
  **Verified:** the regex guards at doc:79, :88 and `--clean`'s sed captures at :157-158. E5's `../` record was skipped.
  **Not verified:** which entries *inside* `~/cc-verify` a format-valid planted T8/RUN can remove (another run's stage or clone).
  **route: code-fact-check**
- **Claim:** In the actions the spike uses (`--register`, `--probe-only`), main's launcher sources host code from its own directory (`CC_ISOLATED_DIR`), not from `CLAUDE_DEVC_CONFIG_DIR`. Staged `cc-isolated.sh`/host tools are hashed by the launcher, not executed by it.
  **Location:** `devcontainer-config/cc-isolated.sh:714-718`
  **Evidence:** executed (fact-check E2/E7, Claim 21). Read-static by me.
  **Verified:** the `readlink -f BASH_SOURCE` derivation and the `source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` line.
  **Not verified:** what the devcontainer CLI and dockerd do with the staged Dockerfile (Finding 1). That is the hop where branch content does reach host-side software.
  **route: code-fact-check**
- **Claim:** The verify container's declared mounts are the two `cc-${CC_PROJECT_ID}-*` volumes plus the workspace bind of the scratch clone. No host credential file or socket is declared.
  **Location:** `devcontainer-config/devcontainer.json:77-80`, `:134`
  **Evidence:** read-static
  **Verified:** the whole `devcontainer.json`.
  **Not verified:** mounts merged in from the built image's `devcontainer.metadata` label (Finding 1), and `containerEnv` credentials (Finding 6).
- **Claim:** The workspace's project id is derived from a path inside `~/cc-verify`, and step 4 refuses an existing container label or volume prefix, so the launcher's `--remove-existing-container` at probe time targets a label no other project's container carried at step 4.
  **Location:** `docs/working/spike-cc-verify-q117.md:264-270`
  **Evidence:** read-static (fact-check Claim 18 executed the label keying)
  **Verified:** the `sha256sum` pipeline equals `project_id` (cc-isolated.sh:372-374) and the two refusals.
  **Not verified:** a docker-capable process creating a container with that label between step 4 and step 7.

## Primitive sweep

Primitive: destructive docker calls (`docker rm -f`, `docker volume rm`, `docker image rm -f`)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `doc:67-68` container rm by label | S4 (`--clean`) / run-derived PID | `^[0-9a-f]{12}$` | Finding 4 (format, not ownership) |
| `doc:70-72` volume rm `cc-$PID-*` | S4 / run-derived PID | same | Finding 4 |
| `doc:76-77` image rm `$IMG` | S4 (`--clean`) / S7 (`docker inspect`) | sha256 format + `IMG_NEW` | Finding 4 (any IMG from a record), fact-check 24b |
| `doc:82-85` image rm by tag `*verify-$T8*` | S7 tags | T8 hex | fact-check Claim 2 (an earlier same-tree leftover). Not filed again. |

Primitive: `rm -rf`
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `doc:86` stage/raw/VERIFY | T8 (run or S4) | hex regex | cleared: stays under `$V` (fact-check E5) |
| `doc:89` src clone | RUN (run or S4) | digit regex | cleared, same |
| `doc:129` snapshot dirs | RUN from the run | none needed (internal) | cleared |
| `doc:165` snapshot dirs in `--clean` | S4 RUN | digit regex via sed | cleared |
| `doc:242` `$S.raw` | t8 from merge-tree output | hex regex at doc:212 | cleared |

Primitive: host process exec fed by branch-controlled content (git, launcher, devcontainer CLI, docker build)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `doc:198` `git clone --bare --no-local` of the checkout | S1 | none on the source repo's config | Untested candidate (upload-pack) |
| `doc:200-203` rev-parse, merge-tree | S1 | `-c hooksPath/fsmonitor`, bare clone | Finding 2 (unpinned refs). Merge driver via `attr.tree` untested. |
| `doc:224-229` `git show`, `git archive` | S2 | same flags | cleared for exec except global filters (doc's residual, doc:443). SIGPIPE: fact-check 6, fail-safe. |
| `doc:262-263` workspace `git clone`, `rev-parse` | S1/S2 | no flags | fact-check 11b (global/template hooks). Not refiled. |
| `doc:278`, `:285` launcher `--register`/`--probe-only` (→ `devcontainer up`, docker build) | S2 Dockerfile, S4 stage | step-3 json cmp; launcher manifest | Findings 1 and 3 |
| `doc:314-315` `devcontainer exec … bash -c "$Q117"` | S8 block text (constant); runs in an S2-built image | n/a (in-container) | Findings 5, 8 |
| `cc-isolated.sh:381-382` probe's host git on the bind-mounted clone | written by S2 code at container start | none | Finding 7 |
| `doc:33`, `:335` paste `cat >` then `bash` of `~/cc-verify/spike-q117.sh` | S4 path | none | Noted in Finding 4. No gain beyond any same-uid dotfile write. |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Dockerfile not covered by the json gate; base-image metadata sets privileged/mounts | Critical | B2, B3 | `doc:244-258`, `devcontainer.json:25-26` | Medium |
| 2 | Refs resolved at run time from an agent-writable checkout; no pin, no diff stop | High | B1 | `doc:198-216` | High |
| 3 | Gate before bless: a swap in between is blessed; residual at doc:442 understated | Medium | B6, B2 | `doc:249`, `:278`, `:442` | Medium |
| 4 | `--clean` drives docker removals from same-uid-writable records | Medium | B6 | `doc:151-168` | Medium |
| 5 | Verdict attested by the code under test | Medium | B5 | `doc:313-333` | Medium |
| 6 | GH_TOKEN / OPENROUTER_API_KEY passed into the branch-code container | Medium | B4 | `devcontainer.json:116,131`; `doc:278,285` | Medium |
| 7 | Leftover VERIFY clone's `.git` writable by branch code | Medium | B7 | `doc:262`, `cc-isolated.sh:381-382` | Low |
| 8 | Unfiltered container output to the terminal (escape sequences, OSC 52) | Medium | B5 | `doc:285`, `:315` | Low |

## Overall Assessment

The spike's mechanics are careful: run-keyed names, format-checked teardown, `rm -rf` confined to `~/cc-verify`, no launcher action that sources staged code. Its central security claim, "no branch code executing on the host", rests on a gate that is too narrow. The gate pins `devcontainer.json` and treats the Dockerfile as in-container content, but the Dockerfile picks a base image whose metadata label the devcontainer CLI merges into the container's create flags. The refs that pick the Dockerfile are read at paste time from a checkout that cc-isolated agents write. Together these give an agent-written ref a plausible path to a privileged container started on the user's daemon with no human diff, which is exactly the hop install.sh's review-and-y exists to cover. Both are fixable in place, and cheaply: pin the reviewed tree id in the paste (one line, closes Finding 2 and, for this branch, Finding 1 too), and extend the identity rule to every staged file outside an in-container allowlist (the generalisation the `cc-verify` tool needs). Then add the post-bless manifest check (Finding 3), `env -u` for the two credentials (Finding 6), and ownership checks in `--clean` (Finding 4). The single most important change is the tree-id pin. Endorsement claims are scoped to the code paths read. The step-3 gate is not endorsed while its bypass candidates are untested. This is not a categorical all-clear: no findings beyond those listed within the code paths read, and endorsement claims are pending execution verification.

## Goal-Alignment Note

**Success criterion (verbatim):** "a markdown report saved to /workspace/.claude/wt-branch-verify/docs/reviews/security-review-2026-10-15-cc-verify-spike.md, structured per the security-reviewer skill, with a `Commit: 12fcb61c` first line."

**User goal:** a reviewed, safe one-paste host spike that live-verifies a branch without installing it. This review serves it by naming what keeps the paste from being "safe" today. It is not safe to hand over as written: Findings 1-2 must be fixed before the paste goes into a `you: terminal` entry, and the fix for both is small. The rest (3-8) are hardening that can land in the same revision. Nothing here argues against the design (main's launcher on an ephemeral stage). The gaps sit in what the gate pins and in when the refs are read, not in the architecture.
