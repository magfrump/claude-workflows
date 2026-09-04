# cc-isolated — usage guide

Last verified: 2026-09-03
Relevant paths: `devcontainer-config/cc-isolated.sh`, `devcontainer-config/egress/`, `devcontainer-config/Dockerfile`, `test/cc-isolated-functions.bats`

`cc-isolated` launches an isolated Claude Code session inside a devcontainer for
**any** git repo on this host, from one central host-side config (decision 016).
This is the day-to-day command reference. For the security model, one-time host
setup, and boundary-verification procedure, see
[`devcontainer-setup.md`](devcontainer-setup.md) — this guide assumes that setup
is already done.

> **Always run from the HOST** (your normal WSL terminal), never from inside a
> session. Claude Code blocks AF_UNIX sockets for its whole process tree, so
> `docker`/`devcontainer` cannot work from within a session by design.

## Command reference

```bash
cc-isolated                       # session for the git repo containing $PWD
cc-isolated ~/code/other-project  # session for an explicit repo
cc-isolated --list                # show registered projects and their egress
cc-isolated --register ~/code/api --profile python   # widen egress, then re-bless
cc-isolated --bless               # re-bless the installed config after YOU reviewed it
cc-isolated --probe-only [REPO]   # run the boundary self-probe and exit
cc-isolated --help                # usage header
```

The target is always resolved to a **git toplevel**; pointing it at a non-repo
directory is a hard error (it refuses rather than guessing another repo).

## What a launch does, in order

1. Resolve the target argument (or `$PWD`) to its git toplevel.
2. Read the project's egress profile **from host-side registration only** — never
   from the repo.
3. Check the installed config against the blessed trust manifest (refuses if
   anything host-side rewrote the boundary).
4. `devcontainer up --override-config … --id-label cc-project=<id>` — bind-mounts
   the repo at `/workspace`. First run builds the image (~minutes).
5. Run the **boundary self-probe** (five checks; see below).
6. `exec devcontainer exec … claude`.

Target repos get **zero** new files — nothing is committed into them.

## Egress profiles (the registrable "languages")

Egress is default-deny. Every project gets `base` (Anthropic API/OAuth, npm,
GitHub IP ranges). Language toolchains are granted per project, **host-side only**:

| Profile | Opens | Auto-suggested from repo contents |
|---------|-------|-----------------------------------|
| `base`  | Anthropic API/OAuth (`api.anthropic.com`, `claude.ai`, `console.anthropic.com`, `platform.claude.com`), `registry.npmjs.org`, GitHub ranges | always applied |
| `python`| `pypi.org`, `files.pythonhosted.org` | `pyproject.toml` · `requirements.txt` · `setup.py` |
| `rust`  | `crates.io`, `index.crates.io`, `static.crates.io` | `Cargo.toml` |
| `lean`  | `elan.lean-lang.org`, `releases.lean-lang.org` | `lean-toolchain` · `lakefile.lean` |
| `android`| Google Maven (`dl.google.com`, `maven.google.com`), Maven Central, `services.gradle.org`, `plugins.gradle.org` | `gradlew` · `build.gradle[.kts]` · `settings.gradle[.kts]` |
| `dotnet` | `api.nuget.org` | `ProjectSettings/ProjectVersion.txt` · `Packages/manifest.json` · top-level `*.sln` / `*.csproj` |
| `llm`   | `openrouter.ai` | never — deliberate opt-in |
| `vscode`| VS Code marketplace hosts | never (IDE-attach is unsupported) |

Profiles compose:

```bash
cc-isolated --register ~/code/tool --profile rust,lean
```

Two rules that are load-bearing for the security model:

- **The repo never chooses its own egress.** `cc-isolated` will *suggest* a profile
  from what it sees (`pyproject.toml` → `python`) but never applies it. Letting an
  untrusted workspace grant itself network access would defeat the isolation.
- **`llm` is never in `base` and never suggested.** An LLM API is a general-purpose
  outbound channel — anything the agent can put in a prompt leaves the boundary.
  Grant it deliberately or not at all.

Registering re-blesses the manifest (a project's egress *is* boundary config) and
the next launch rebuilds that project's image.

### What is NOT covered

There is no profile — and no image toolchain — for non-Android JVM, Go, Ruby, etc.
Supporting a new ecosystem is a real change, not a config toggle: it needs a new
`egress/<name>.txt`, toolchain layers in the central `Dockerfile`, and a detection
clause in `suggest_profiles()` (see decision log #18/#19 for the uv and Android
precedents). The current registrable language toolchains are **Python, Rust, Lean,
Android, and .NET**.

## First session per project

Run `claude` login once inside the container. Credentials and memory persist in
that project's **own** named volume (`cc-<project-id>-claude-config`, mounted at
`/home/node/.claude`) and survive rebuilds. Each project gets its own volume, so
a compromised session in one project cannot read another's credentials.

Git push auth: the container gets no host SSH keys by design, and no GitHub
token unless you export one — see
[Working with collaborators](#working-with-collaborators-github-credentials).

## Working with collaborators: GitHub credentials

GitHub is reachable from **every** session — `base` carries GitHub's published
CIDRs because git needs them — and GitHub hosts arbitrary writable repos and
gists. No firewall rule scopes that to "only my repos". What a credential
decides is therefore not *whether* the agent can talk to GitHub, but *which
repos it can push to or read privately*. Pick the narrowest tier that fits:

- **No credentials (default).** Nothing is exported; `gh` and authenticated
  `git push` fail. Commit inside the container, then push from the host with
  your own keys. This is the right default for solo work and for public repos:
  the agent gets the whole workflow except the one step that needs trust.
- **Read-only PAT — for private fetches.** When the repo, or a dependency, is
  private, export a fine-grained PAT with *Contents: read* on the named repos
  only: `GH_TOKEN=github_pat_… cc-isolated ~/code/api`. `devcontainer.json`
  passes it through opt-in, exactly like `OPENROUTER_API_KEY`, and it is empty
  unless the host exports it. Still push from the host.
- **Write PAT — only when the agent must push.** Fine-grained, *Contents: write*
  on the named repos only, expiry measured in days, and **branch protection on
  `main`** (require PRs, no force-push) so the token can open branches and PRs
  but cannot rewrite history. Export it for that one session and revoke after.

Be honest about what this buys. Scoping the token bounds *credential* misuse — a
compromised session with a read-only PAT cannot push to your repos, and with a
scoped write PAT cannot touch repos it was not named on. It does **not** close
the network-level exfiltration channel: GitHub is writable for every session
regardless of what you export, and a token the *attacker* supplies (injected
through a prompt, a dependency, a fetched page) works just as well as one you
did not. The real fix is a host-side git proxy that replaces the GitHub CIDRs
with an authenticating endpoint restricted to named push targets — noted as
future work in the 2026-08-29 egress security review (finding 3), not something
a config edit can deliver.

## Python inside the container

The image ships `uv` (not pip — the `node:22` base has no `ensurepip`, so
`python3 -m venv` fails outright). After registering `--profile python`:

```bash
uv venv                 # .venv on the image's python3.11
uv pip install pytest   # or `uv sync` if the repo has a uv lockfile
.venv/bin/pytest
```

- `Network is unreachable` for `pypi.org` on `uv pip install` means the project was
  never registered with `--profile python` (`uv venv` itself touches no network and
  succeeds under `base`). Registration is host-side by design.
- `uv venv --python 3.12` fails loudly rather than fetching an interpreter —
  `UV_PYTHON_DOWNLOADS=never` is baked in. A different Python version needs a
  different base image, not a wider allowlist.

## Android inside the container

The image bakes **JDK 17** plus an Android SDK (cmdline-tools, `platform-tools`,
`platforms;android-35`, `build-tools;35.0.0`) at `/opt/android-sdk`, with
`ANDROID_HOME`/`ANDROID_SDK_ROOT` set and the tools on `PATH`. After registering
`--profile android`:

```bash
cc-isolated --register ~/code/app --profile android   # opens Google Maven / Central / Gradle
cc-isolated ~/code/app
# inside the container:
./gradlew assembleDebug
```

Two failure modes worth recognizing on sight:

- **`Could not resolve …` / `Network is unreachable` for `dl.google.com` or
  `repo.maven.apache.org`** means the project was never registered with
  `--profile android`. Dependency resolution is a runtime step and needs the
  profile; registration is host-side by design (an agent cannot grant itself
  Google Maven).
- **`sdkmanager` fails to install a missing platform/build-tools version.** The SDK
  dir is root-owned, so a build that wants an *unbaked* API level fails loudly
  rather than fetching it — mirroring uv's `UV_PYTHON_DOWNLOADS=never`. That is a
  central-image rebuild (bump `ANDROID_PLATFORM`/`ANDROID_BUILD_TOOLS` in
  `devcontainer.json`, re-install, re-bless), not a wider allowlist. The SDK
  download itself happens at **build** time (before the firewall exists), so it
  needs no egress profile.

## Rust inside the container

The image bakes a **pinned stable Rust toolchain** (rustup + `rustc`/`cargo`, with
`clippy` and `rustfmt`) under a root-owned `/opt/rustup` + `/opt/cargo`, on `PATH`.
After registering `--profile rust`:

```bash
cc-isolated --register ~/code/crate --profile rust   # opens crates.io / index / static
cc-isolated ~/code/crate
# inside the container:
cargo build            # registry cache lands in /home/node/.cargo (node-writable)
cargo test
```

The toolchain binaries are root-owned (like uv and the Android SDK) — `node` compiles
against them but cannot rewrite the compiler it runs. `CARGO_HOME` is repointed to a
node-writable `/home/node/.cargo` so the crate registry cache, config, and `cargo
install` output have somewhere to go; that only affects where cargo *writes*, not
which toolchain it runs.

Two failure modes worth recognizing on sight:

- **`Network is unreachable` / `error: failed to get … crates.io`** means the project
  was never registered with `--profile rust`. Crate resolution is a runtime step and
  needs the profile; registration is host-side by design (an agent cannot grant itself
  crates.io).
- **`rustup update` / `rustup toolchain install …` fails** (can't write the root-owned
  `RUSTUP_HOME`). The toolchain is pinned and baked at **build** time from
  `static.rust-lang.org` — a host deliberately absent from `rust.txt`, since a pinned
  toolchain never self-updates. A different Rust version is a central-image rebuild
  (bump `RUST_VERSION` in `devcontainer.json`, re-install, re-bless), mirroring uv's
  `UV_PYTHON_DOWNLOADS=never` and the Android SDK's root-owned dir — not a wider
  allowlist.

## .NET / Unity inside the container

The image bakes a **pinned .NET SDK** (LTS, currently 10.0.400) root-owned at
`/opt/dotnet`, on `PATH`, with telemetry opted out. After registering
`--profile dotnet`:

```bash
cc-isolated --register ~/code/game --profile dotnet   # opens api.nuget.org
cc-isolated ~/code/game
# inside the container:
dotnet build path/to/GameLogic.csproj
dotnet test  path/to/GameLogic.Tests.csproj
```

**The Unity editor is out of scope by design.** It is GUI-bound, licensed, and
runs on the HOST — play-mode tests, scene work, and UPM package resolution
(`packages.unity.com`) all happen there. What the agent runs in-container is the
editor-independent slice: plain C# class libraries (game rules, data models,
algorithms) and their NUnit/xUnit test projects, restored from NuGet. Structuring
game logic into such libraries — referenced from Unity via asmdefs or copied
DLLs — is what makes a Unity project agent-testable at all.

Failure modes worth recognizing on sight:

- **`Unable to load the service index for source https://api.nuget.org/…` /
  `Network is unreachable`** means the project was never registered with
  `--profile dotnet`. Restore is a runtime step and needs the profile;
  registration is host-side by design (an agent cannot grant itself NuGet).
- **`dotnet workload install` fails**, or a build demands an SDK version other
  than the baked one. The SDK dir is root-owned and its host
  (`builds.dotnet.microsoft.com`) is build-time-only, deliberately absent from
  `dotnet.txt` — mirroring rust's `static.rust-lang.org`. That is a central-image
  rebuild (bump `DOTNET_SDK_VERSION` + both SHA-512 args in `devcontainer.json`,
  re-install, re-bless), not a wider allowlist. Pin `global.json` to a
  `rollForward` policy compatible with the baked SDK rather than an exact older
  version.
- **A `.csproj` that references `UnityEngine.dll` fails to build.** Unity
  assemblies live in the host's editor installation, not in NuGet or the image.
  Either keep agent-testable code Unity-free (the clean split), or vendor the
  reference DLLs into the repo.

## The boundary self-probe

Every launch refuses to `exec claude` unless all five pass:

- **Image provenance** — built from the central Dockerfile (`/usr/local/share/cc-egress/`
  present, `/etc/cc-egress-profile` matches the registered profile). Catches the
  target repo's own `.devcontainer/Dockerfile` being built instead.
- **H1 (credential denial)** — `~/.ssh/canary` and host home are invisible inside.
- **Egress** — `https://example.com` is unreachable (default-deny is live).
- **Workspace identity** — `/workspace` really is the repo you asked for (git
  HEAD+remote fingerprint compared host-side vs in-container). Catches an
  `--id-label` alias attaching you to another project's container.
- **H6 (volume not shared)** — `/home/node/.claude` is stamped with this project's
  id; a mismatch means two projects share one credential volume.

Run just the probe without starting a session:

```bash
cc-isolated --probe-only ~/code/api
```

## SNI filtering (tcp/443)

The allowlist matches addresses, and CDN fronts put thousands of unrelated names
behind one address. So `init-firewall.sh` also runs a small SNI-filtering proxy
(`cc-sni-proxy.py`, stdlib Python, its own unprivileged uid) and redirects every
tcp/443 connection the agent makes through it. The proxy reads the TLS
ClientHello's server name, admits it only if it is an allowlisted name (or a
subdomain of a GitHub zone), resolves that name itself, connects there, and
splices bytes. Nothing is decrypted.

**What it closes:** reaching a non-allowlisted name that happens to share an
address with an allowlisted one (a Cloudflare neighbour of `api.anthropic.com`,
writable `storage.googleapis.com` behind the same Google front as `dl.google.com`).

**What it does not cover:**

- Ports other than 443. GitHub SSH on 22 and a host model server on 11434 stay
  address+port matched only.
- A name under an allowlisted *zone* that an attacker can obtain. GitHub zones
  don't hand those out; exact-name entries have no such residual.
- Root inside the container. The firewall script's own fetch and its two general
  reachability probes run as root and bypass the redirect; its two SNI probes are
  run as `node` on purpose so they do not. The agent runs as `node` and is always
  subject to the redirect.

**Debugging a blocked connection:** the proxy logs every decision to
`/run/cc-sni-proxy/proxy.log` as `ALLOW`, `REJECT` (either `sni=<name> … not in
allowlist`, or without an `sni=` field when the bytes were not a parseable TLS
ClientHello), or `FAIL` (the name could not be resolved — the filtering resolver
refused it — or the address it resolved to could not be connected to, typically
because the ipset does not admit it). A `curl` that
fails instantly with an empty reply, while the same host is in your profile,
usually means the name in the URL differs from the name in the profile (a CDN
alias, an `--resolve` override, or an HTTP/2 connection being coalesced onto a
different hostname). Add the exact name to the profile.

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `devcontainer CLI not found` | `npm install -g @devcontainers/cli` on the host. |
| `no blessed manifest` / `installed config changed` | Review `~/.config/claude-devcontainer/` by hand, then `cc-isolated --bless`. Re-run `install.sh` after any canonical-config change. |
| `unknown egress profile 'x'` | Typo — valid profiles are the files in `devcontainer-config/egress/`. `--list` and the error message enumerate them. |
| Connection closes immediately on a 443 host that is in your profile | SNI mismatch — see "SNI filtering" above and `/run/cc-sni-proxy/proxy.log`. |
| `Network is unreachable` mid-session for a CDN host (e.g. openrouter.ai) | Resolve-at-start allowlist went stale behind rotating CDN IPs. Inside the container: `sudo /usr/local/bin/init-firewall.sh`. |
| `docker`/probe fails only inside a Claude Code session | Expected — CC blocks AF_UNIX sockets. Run `cc-isolated` from a normal host terminal. |
| Claude Code auto-update fails every launch in ONE project (`.last-update-result.json` shows `install_failed`; npm log shows `ENOTEMPTY … rename … .claude-code-XXXXXXXX`) | An earlier update was interrupted (e.g. session exited mid-update), leaving npm's retire-staging dir behind in that project's container. The staging name is derived from the path, so every later update collides with the same leftover. Inside the container: `rm -rf /usr/local/share/npm-global/lib/node_modules/@anthropic-ai/.claude-code-*`, then `claude update`. |
| Probe fails on image provenance after migrating from the 015 launcher | A leftover `.devcontainer/Dockerfile` in the target repo shadows the central one. Delete `.devcontainer/` **before** verifying (see `devcontainer-setup.md` → Migrating). |

## Related

- [`devcontainer-setup.md`](devcontainer-setup.md) — security model, one-time host
  setup, manual boundary verification, known limits.
- `docs/decisions/015-cc-process-isolation-docker-devcontainer.md` — the isolation
  decision.
- `docs/decisions/016-multi-project-devcontainer-central-config.md` — central
  host-side config, per-project volumes and egress.
