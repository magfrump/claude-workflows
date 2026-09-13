# Devcontainer setup — isolated Claude Code sessions (decisions 015, 016)

Last verified: 2026-09-09
Relevant paths: `devcontainer-config/`, `test/cc-isolated-functions.bats`, `.devcontainer/` (legacy), `scripts/devcontainer-session.sh` (legacy)

Every CC project on this host runs inside a devcontainer, launched by one
host-side command: `cc-isolated`.

How this closes decision 015's two residual vectors: every tool (Read included)
runs inside the container's mount namespace, and host credentials are simply not
mounted (H1); the boundary config lives in host `~/.config/claude-devcontainer/`,
which is in **no bind mount**, so a session cannot see or edit the boundary it
runs under (H2 — decision 016 strengthened this; under 015 the config was
committed in-repo and therefore agent-writable, gated only by the trust manifest).

## One-time host setup

1. **Docker Desktop WSL integration** (Windows side): Docker Desktop →
   Settings → Resources → WSL integration → enable for this Ubuntu distro →
   Apply & Restart. If `docker info` still fails in a fresh terminal, run
   `wsl --shutdown` from PowerShell (closes all WSL sessions!) and reopen.
   - Symptom of incomplete integration: `/var/run/docker.sock` exists but is a
     character device (`crw-rw-rw- ... 1, 3` — a /dev/null placeholder), not a
     socket.
   - Verify from a normal terminal, **not** a Claude Code session: CC blocks
     AF_UNIX socket creation for its whole process tree, so `docker` can never
     work from inside a session. That is expected, and is part of the security
     story — don't "fix" it.
2. **devcontainer CLI** (host): `npm install -g @devcontainers/cli`
3. **Plant the canary** (host): `touch ~/.ssh/canary` — the launcher's H1 probe
   checks this exact file is invisible in-container.
4. **Install the config** (host, from this repo):

   ```bash
   ./devcontainer-config/install.sh
   ```

   This copies `devcontainer-config/` to `~/.config/claude-devcontainer/`, links
   `~/.local/bin/cc-isolated`, and blesses the trust manifest. **Read the diff it
   prints.** That diff is the rebuild gate: `devcontainer-config/` in this repo is
   inside a bind mount and *is* agent-writable, but edits there are inert until a
   human runs this script. Re-run it after any change to the canonical config.

## Starting a session

```bash
cd ~/any/project && cc-isolated       # the repo containing $PWD
cc-isolated ~/code/other-project      # or an explicit repo
```

The launcher, in order: resolves the target to a git toplevel (refusing outright
if you're not in a repo) → checks the installed config against the blessed
manifest → `devcontainer up --override-config … --id-label cc-project=<id>`
(bind-mounts that repo at /workspace; first run builds the image, ~minutes) →
boundary self-probe → `devcontainer exec claude`.

Target repos get **zero** new files. Nothing is committed into them, and nothing
needs to be.

First session per project: run `claude` login inside the container. Credentials
and memory persist in that project's own named volume
(`cc-<project-id>-claude-config`, mounted at /home/node/.claude) and survive
rebuilds. Each project gets its **own** volume — decision 016 H6 — so a
compromised session in one project cannot read another's credentials or history.
The cost is one login per project. Per decision 015, **never** mount host
`~/.claude` or any host credential directory.

Git push auth: the container gets no host SSH keys by design. Use a fine-grained
PAT scoped to the repos the agent works on (`gh auth login` inside the container,
or `GH_TOKEN`), never your real host credentials.

## Egress profiles

Egress is default-deny. Every project gets the `base` allowlist (Anthropic API +
OAuth, npm, GitHub's IP ranges). Anything more is granted per project, **host-side
only**:

```bash
cc-isolated --register ~/code/api --profile python     # base + PyPI
cc-isolated --register ~/code/tool --profile rust,lean # profiles compose
cc-isolated --list                                     # who has what
```

Registering re-blesses (a project's egress *is* boundary config) and the next
launch rebuilds that project's image. Available profiles are the files in
`devcontainer-config/egress/`: `base`, `python`, `rust`, `lean`, `android`,
`dotnet`, `llm`, `vscode`.

Two deliberate choices here:

- **The repo never chooses its own egress.** `cc-isolated` will *suggest* a profile
  from what it sees in the repo (`pyproject.toml` → python), but never applies it.
  Letting an untrusted workspace grant itself network access would defeat the point.
- **`llm` (openrouter.ai) is not in `base` and is never suggested.** An LLM API is a
  general-purpose outbound channel — anything the agent can put in a prompt leaves
  the boundary. Grant it deliberately or not at all.

An agent inside a container cannot widen its own allowlist: the profile is written
root-owned to `/etc/cc-egress-profile` at **build** time, `node` has NOPASSWD sudo
for `init-firewall.sh` and nothing else, and sudo's `env_reset` strips the
environment. Widening requires a host-side re-register, re-bless, and rebuild.

## Python projects

The image ships **`uv`** plus Debian's `python3.11`, and deliberately ships **no pip**.
That is not an omission to work around: the `node:22` base has no `ensurepip`, so
`python3 -m venv` fails outright, and uv replaces both the venv builder and the
installer with one static binary. A uv venv also sidesteps Debian's PEP 668
`EXTERNALLY-MANAGED` marker, which would block a system-wide `pip install` anyway.

Host-side, once:

```bash
cc-isolated --register ~/code/api --profile python   # opens PyPI, re-blesses, rebuilds next launch
cc-isolated ~/code/api
```

Then inside the container:

```bash
uv venv                 # .venv on the image's python3.11
uv pip install pytest   # or `uv sync` if the repo has a uv lockfile
.venv/bin/pytest
```

Two failure modes worth recognizing on sight:

- **Missing `--profile python` breaks the install, not the venv.** `uv venv` touches no
  network and succeeds under the `base` profile; `uv pip install` then dies with
  `Network is unreachable` for `pypi.org`. That error means the project was never
  registered — it does not mean uv is broken. Registration is host-side by design
  (see above); an agent cannot grant itself PyPI.
- **uv will not fetch an interpreter.** `UV_PYTHON_DOWNLOADS=never` is baked into the
  image, so `uv venv --python 3.12` fails loudly rather than silently pulling a managed
  CPython from GitHub — reachable regardless of profile, since `init-firewall.sh` always
  admits GitHub's published IP ranges for every project. A project needing a different
  Python version needs a different base image, not a wider allowlist.

Note the asymmetry with the hermeticity story: `uv pip install` reaching PyPI is a
*build* step, not a *test* step. Test suites are still expected to be hermetic (decision
017, `guides/test-hermeticity.md` once that branch lands).

## Android projects

The image bakes **JDK 17** and an Android SDK (cmdline-tools, `platform-tools`,
`platforms;android-35`, `build-tools;35.0.0`) at `/opt/android-sdk` — the same
pattern as uv: the toolchain ships unconditionally in the shared base and the
`android` egress profile gates only the network (decision log #19). Because the SDK
is baked at build time, its download needs no egress profile, and the SDK dir is
root-owned so `node` builds against it but cannot rewrite it.

```bash
cc-isolated --register ~/code/app --profile android   # Google Maven + Central + Gradle
cc-isolated ~/code/app
# inside: ./gradlew assembleDebug
```

Same shape as the Python failure modes: dependency resolution reaching
`dl.google.com`/Maven Central is a *runtime* step that needs the profile, and a
build wanting an SDK component that isn't baked fails loudly (root-owned dir)
rather than fetching it — that's a central-image rebuild
(`ANDROID_PLATFORM`/`ANDROID_BUILD_TOOLS` in `devcontainer.json`), not a wider
allowlist. Full workflow and troubleshooting: `guides/cc-isolated-usage.md`.

## .NET / Unity projects

The image bakes a **pinned .NET SDK** (LTS) root-owned at `/opt/dotnet` — same
pattern again (decision log #38): toolchain unconditional in the shared base, the
`dotnet` egress profile gates only the network (`api.nuget.org`). The Unity editor
runs on the HOST; in-container work is editor-independent C# libraries and test
projects (`dotnet build` / `dotnet test`).

```bash
cc-isolated --register ~/code/game --profile dotnet   # NuGet
cc-isolated ~/code/game
# inside: dotnet test path/to/GameLogic.Tests.csproj
```

Same failure-mode shape: NuGet restore is a *runtime* step that needs the profile;
a build wanting a different SDK or a workload fails loudly (root-owned
`DOTNET_ROOT`, SDK host absent from `dotnet.txt`) — that's a central-image rebuild
(`DOTNET_SDK_VERSION` + both SHA-512 args in `devcontainer.json`), not a wider
allowlist. Full workflow and troubleshooting: `guides/cc-isolated-usage.md`.

## Verifying the boundary

The launcher probes seven things at every start and refuses to exec `claude` if any
fail:

- **Image provenance:** the running image was built from the central Dockerfile —
  `/usr/local/share/cc-egress/` is present and `/etc/cc-egress-profile` holds the
  profile you registered. This is what catches the target repo's own
  `.devcontainer/Dockerfile` being built instead (see Known limits).

- **H1 (credential denial):** `~/.ssh/canary` and the host home are invisible inside.
- **Egress:** `https://example.com` is unreachable (default-deny is live).
- **Workspace identity:** `/workspace` really is the repo you asked for — the git
  HEAD+remote fingerprint is computed on the host and in the container and compared.
  This is what catches an `--id-label` alias silently attaching you to another
  project's container.
- **H6 (volume not shared):** `/home/node/.claude` is stamped with this project's id;
  a mismatch means two projects are sharing one credential volume.
- **Config identity:** the image's baked `/etc/cc-config-hash` is the hash of the
  manifest blessed *now*. A container built before a re-bless is the old boundary;
  the launcher recreates it.
- **Firewall complete:** `/run/cc-firewall/complete` exists — the baked
  `init-firewall.sh` reached its sentinel on its last run, node-run probes included.
  Without this check a fail-closed container is indistinguishable from a healthy one:
  every egress check passes and `node` has no network (2026-09-09). The probe stats
  the marker as `node`, so it is 0644 in a root **0711** directory; `node` still
  cannot forge or remove it (no write bit on the directory) nor open the 0600 lock
  beside it. Under the 0700 this replaced, every healthy container failed this check
  (2026-09-12).

A full pass records the blessed hash in `~/.config/claude-devcontainer/verified-live.sha256`.
That file, not the manifest, is what "verified" means here — see the next section.

Do these by hand for the decision-015 Continue trigger:

- **H1 both ways:** inside a session, ask CC to read `~/.ssh/canary` (host path) via
  the Read tool *and* via Bash. Both must fail.
- **H2 (control-plane immutability):** edit `devcontainer-config/init-firewall.sh`
  from inside a session, exit, relaunch. Nothing happens — the edit is inert, because
  the launcher reads `~/.config/claude-devcontainer/`, which the container cannot see.
  Now run `./devcontainer-config/install.sh`: it must show your edit in the diff and
  wait for approval. That is the gate. (Revert with git afterwards.)
- **Tests:** `bats test/` green inside the container.

## Changing the boundary — the verification loop

This section exists because the same debt produced two outages. Decisions #40 and
#41 (filtering resolver, SNI proxy) each shipped with *"needs a live-container
check before bless"* in the commit message, were blessed without one, and passed
four review passes — all run in a sandbox with no kernel, so each re-read the
command sequence and none could touch the assumption. Sessions had no DNS or HTTPS
for six days while every root-run probe reported a healthy boundary (#43 refuted,
#44). The fix to the process is mechanical, not advisory:

- **Runtime half — the receipt.** A bless hashes files. It is a *review*, not a
  test. The launcher bakes the blessed hash into the image and writes
  `verified-live.sha256` only when a self-probe passes against a container that
  carries that hash and whose `init-firewall.sh` reached its completion marker.
  `cc-isolated --list` shows the blessed hash and whether it has ever passed.
- **Repo half — the trailer.** `hooks/live-verify-gate.sh` (PreToolUse on Bash)
  blocks a `git commit` that includes any manifest-hashed file under
  `devcontainer-config/` unless the message carries a `Live-verified:` trailer.
  Either the hash `--list` shows after a passing probe, or `Live-verified: no — <why,
  and what will run it>`. The gate does not judge the answer; it refuses to let the
  question go unasked. `git log --grep 'Live-verified: no'` lists the outstanding debt.

### What each layer can and cannot prove

| Layer | Proves | Cannot see |
|---|---|---|
| `bats test/init-firewall-rules.bats`, `test/cc-isolated-functions.bats`, `shellcheck` | The **command sequence**: which `iptables`/`ipset`/`dnsmasq` calls are issued, in what order, with which literals; that malformed input aborts before the flush; that the trap forces DROP. The `iptables` stub rejects repeated single-value selectors, nothing more. | **Any kernel behaviour.** Whether a rule matches a packet, whether a DNAT delivers, which device the filter chain sees, whether a daemon is reachable from the bridge. The 2026-09-09 bug shipped with 68 green tests. |
| `init-firewall.sh`'s own end-of-run probes (inside the container, at every start) | That the assembled ruleset lets `node` — not root — resolve and reach `api.anthropic.com` through the steering, and that a forged SNI against an admitted address is refused *through the DNAT* (the `orig_dst` grep). Fails closed otherwise. | Properties the design *claims* beyond the boot path: off-box unreachability, hardcoded-resolver bypass, address recomputation after a restart. |
| The launcher's self-probe + receipt | That a container built from the config blessed *now* booted with the firewall complete, and which hash that was. | Anything the firewall probes did not exercise. |
| The DD's manual probe set (`docs/working/dd-cc-isolated-loopback-redirect.md` §6, probes 3–5) | The claimed properties above, from the host and a second container. | — (this is the last layer) |

### The sequence, every time an enforcement file changes

Enforcement files are what `enforcement_files()` in `cc-isolated.sh` hashes:
`Dockerfile`, `devcontainer.json`, `init-firewall.sh`, `cc-sni-proxy.py`,
`link-claude-home.sh`, `cc-isolated.sh`, everything under `egress/`, and the
staged `claude-home/`.

1. **Unit layer, in the editing session.** `bats test/init-firewall-rules.bats
   test/cc-isolated-functions.bats test/hooks/live-verify-gate.bats`, `shellcheck
   -S warning` on every touched script, `python3 -m unittest test/test_cc_sni_proxy.py`
   if the proxy changed. Green here means the *sequence* is right. Nothing more.
2. **Pre-implementation probe for steering or bind changes.** If the change touches
   a nat rule, a bind address, a guard chain, or an accept that steered traffic
   depends on, run the relevant §6 probe on a live container *before* writing the
   rule into the script, and run it **against the assembled ruleset**, never a
   flushed one. Probe 1 of the 2026-09-09 DD passed with the filter table cleared
   and missed the second half of the outage because of it. Every functional probe
   runs as `node` via `runuser -u node --`; root is exempt from the steering and a
   root-run probe proves nothing.
3. **Install and bless, on the host.** `./devcontainer-config/install.sh` — read the
   diff it shows; that is the human review gate. It ends with *"Blessed, NOT
   verified"*. Believe it.
4. **Verify live.** `cc-isolated --probe-only <repo>`. This always recreates the
   container from the blessed config (so it cannot verify a leftover) and writes the
   receipt on a pass. Do it on **more than one project** when the change is central —
   one config, one blast radius. Then start a session and do the one thing the
   probes cannot: `/login` (or a request) as the user the boundary is for.
5. **Run the claimed-property probes when the design claims something new.** DD §6
   probes 3 (daemons unreachable from host and bridge), 4 (hardcoded resolver still
   steered), 5 (address recomputed across a renumbering restart). Record outcomes in
   the DD or diagnosis doc with `tested:` / `learned:`. These are outstanding for
   #44 as of 2026-09-09; the receipt does not cover them and does not claim to.
6. **Commit with the trailer.** `Live-verified: <hash from cc-isolated --list>` when
   step 4 passed; `Live-verified: no — <reason>; <what will run it>` when it could
   not (a sandbox session with no Docker is the usual reason). The hook refuses the
   commit without one. A `no` is a debt entry, and the next host session's first job
   is to clear it: run step 4, then amend or follow up with the hash.
7. **Before the decision-log row says "verified"**, the row cites the hash. A row
   that says "needs a live check" without a `questions.md` entry naming who runs it
   and when is the pattern this section exists to end.

### Reading a failure

- `PROBE FAIL (firewall)` — the baked script aborted and failed closed. The container
  is safe and useless. The `ERROR:` line in the `devcontainer up` output names the
  step; re-run `sudo /usr/local/bin/init-firewall.sh` inside to see it again. If the
  script's own phase-A reads are now blocked (DROP with no accepts), recreate.
- `PROBE FAIL (config identity)` — the container predates the bless. The launcher
  recreates it on a normal launch; `--probe-only` always does.
- Probes pass, `/login` fails with `getaddrinfo` — the class #44 belongs to *should*
  now be caught by the firewall-complete check. If it is not, a host is missing from
  `egress/base.txt`; remember the SNI allowlist is exact-name, so a subdomain of a
  listed host resolves and is then rejected (`/run/cc-sni-proxy/proxy.log`).

## Migrating from the 015 per-repo launcher

**Delete the legacy `.devcontainer/` BEFORE you verify the new path, not after.** A
leftover `.devcontainer/Dockerfile` in the target repo does not sit inertly beside
`cc-isolated` — it *shadows* it. See the override-config gotcha under Known limits:
a repo with its own `.devcontainer/Dockerfile` will have that one built instead of
the central one, and the resulting image bakes the repo's own (bind-mounted,
agent-writable) `init-firewall.sh`. The session comes up, the probes pass, and the
boundary is one the agent could have written. Verifying while the legacy dir is
still present tells you nothing.

```bash
git rm -r .devcontainer scripts/devcontainer-session.sh test/devcontainer-session-functions.bats
rm -f ~/.config/claude-devcontainer/claude-workflows.sha256   # the old per-repo manifest
```

Then verify — the launcher's image-provenance probe now refuses to start `claude`
unless the running image really came from the central Dockerfile.

Do not maintain both. Two copies of `init-firewall.sh` is exactly the drift decision
016 exists to prevent.

## Known limits and maintenance

- **`--override-config` resolves relative build paths against the TARGET REPO.** The
  CLI reads the override file's content but sets the config's `configFilePath` to the
  workspace's `.devcontainer/devcontainer.json`
  ([configContainer.ts](https://github.com/devcontainers/cli/blob/main/src/spec-node/configContainer.ts):
  `config.configFilePath = configFile`). So a bare `"dockerfile": "Dockerfile"` means
  `<repo>/.devcontainer/Dockerfile` — "not found" in most repos, and *silently the
  wrong Dockerfile* in any repo that has one. `devcontainer.json` therefore anchors
  `build.dockerfile` and `build.context` to `${localEnv:CC_CONFIG_DIR}`, exported by
  the launcher. **Never make those paths relative again**; three bats tests guard it,
  and the image-provenance probe catches it at runtime.
- **VS Code Dev Containers is not supported.** The extension discovers
  `.devcontainer/devcontainer.json` in the workspace and does not consume
  `--override-config`, so IDE-attach has no boundary config to find. The CLI launcher
  is the supported entry point (decision 016, soft constraint S6, knowingly unmet). If
  you need IDE attach, that's the trigger to implement candidate [4] (hybrid) from the
  decision record.
- **Firewall allowlist is resolve-at-start:** domains behind rotating CDN IPs
  (openrouter.ai is on Cloudflare) can go stale mid-session; rerun
  `sudo /usr/local/bin/init-firewall.sh` inside the container if a previously working
  host starts timing out.
- **Image lifecycle:** `CLAUDE_CODE_VERSION=latest` is baked at build time. A
  re-bless changes the baked config hash, so the next launch of each project
  recreates its container automatically; to pick up a newer CC *without* a config
  change, `devcontainer up --remove-existing-container …` by hand. Staleness >1
  version for >2 weeks is a decision-015 Revisit trigger. The egress profile and the
  config hash are the *last* layer in the Dockerfile, so projects on different
  profiles still share every heavy layer.
- **One config, one blast radius:** a bad edit to the central config breaks every
  project at once. After changing it, verify with `cc-isolated --probe-only <repo>`
  on more than one project before relying on it — see "Changing the boundary".
- **SI loop / cron (H5, unverified):** overnight runs need reworking to
  `devcontainer exec` non-interactively. Do not rely on overnight isolation until this
  is proven — decision 015 lists it as a Revisit trigger.
- **Drift-back hazard:** if >20% of agent work is still in host sessions after week 2,
  the boundary is failing behaviorally (Revisit trigger).
