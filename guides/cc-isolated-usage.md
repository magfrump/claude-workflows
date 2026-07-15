# cc-isolated — usage guide

Last verified: 2026-07-14
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
| `base`  | Anthropic API/OAuth, `registry.npmjs.org`, GitHub ranges | always applied |
| `python`| `pypi.org`, `files.pythonhosted.org` | `pyproject.toml` · `requirements.txt` · `setup.py` |
| `rust`  | `crates.io`, `index.crates.io`, `static.crates.io` | `Cargo.toml` |
| `lean`  | `elan.lean-lang.org`, `releases.lean-lang.org` | `lean-toolchain` · `lakefile.lean` |
| `android`| Google Maven (`dl.google.com`, `maven.google.com`), Maven Central, `services.gradle.org`, `plugins.gradle.org` | `gradlew` · `build.gradle[.kts]` · `settings.gradle[.kts]` |
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
and Android**.

## First session per project

Run `claude` login once inside the container. Credentials and memory persist in
that project's **own** named volume (`cc-<project-id>-claude-config`, mounted at
`/home/node/.claude`) and survive rebuilds. Each project gets its own volume, so
a compromised session in one project cannot read another's credentials.

Git push auth: the container gets no host SSH keys by design. Use a fine-grained
PAT scoped to the repos the agent works on (`gh auth login` inside the container,
or `GH_TOKEN`) — never real host credentials.

## Python inside the container

The image ships `uv` (not pip — the `node:20` base has no `ensurepip`, so
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

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `devcontainer CLI not found` | `npm install -g @devcontainers/cli` on the host. |
| `no blessed manifest` / `installed config changed` | Review `~/.config/claude-devcontainer/` by hand, then `cc-isolated --bless`. Re-run `install.sh` after any canonical-config change. |
| `unknown egress profile 'x'` | Typo — valid profiles are the files in `devcontainer-config/egress/`. `--list` and the error message enumerate them. |
| `Network is unreachable` mid-session for a CDN host (e.g. openrouter.ai) | Resolve-at-start allowlist went stale behind rotating CDN IPs. Inside the container: `sudo /usr/local/bin/init-firewall.sh`. |
| `docker`/probe fails only inside a Claude Code session | Expected — CC blocks AF_UNIX sockets. Run `cc-isolated` from a normal host terminal. |
| Probe fails on image provenance after migrating from the 015 launcher | A leftover `.devcontainer/Dockerfile` in the target repo shadows the central one. Delete `.devcontainer/` **before** verifying (see `devcontainer-setup.md` → Migrating). |

## Related

- [`devcontainer-setup.md`](devcontainer-setup.md) — security model, one-time host
  setup, manual boundary verification, known limits.
- `docs/decisions/015-cc-process-isolation-docker-devcontainer.md` — the isolation
  decision.
- `docs/decisions/016-multi-project-devcontainer-central-config.md` — central
  host-side config, per-project volumes and egress.
