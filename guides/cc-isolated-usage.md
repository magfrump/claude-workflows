# cc-isolated — usage guide

Last verified: 2026-09-09
Relevant paths: `devcontainer-config/cc-isolated.sh`, `devcontainer-config/egress/`, `devcontainer-config/Dockerfile`, `test/cc-isolated-functions.bats`, `hooks/live-verify-gate.sh`

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
cc-isolated --list                # blessed config hash + verified-live status, registered projects
cc-isolated --register ~/code/api --profile python   # widen egress, then re-bless
cc-isolated --bless               # re-bless the installed config after YOU reviewed it
cc-isolated --probe-only [REPO]   # REBUILD REPO's container from the blessed config, run the
                                  # self-probe, record the config verified live on a pass
cc-isolated --help                # usage header
```

The target is always resolved to a **git toplevel**; pointing it at a non-repo
directory is a hard error (it refuses rather than guessing another repo).

## What a launch does, in order

1. Resolve the target argument (or `$PWD`) to its git toplevel.
2. Read the project's egress profile **from host-side registration only** — never
   from the repo.
3. Check the installed config against the blessed trust manifest (refuses if
   anything host-side rewrote the boundary), and derive the **blessed config hash**
   from it. If no live probe has recorded that hash yet, say so: this launch is the
   verification.
4. `devcontainer up --override-config … --id-label cc-project=<id>` — bind-mounts
   the repo at `/workspace`. First run builds the image (~minutes). The hash is a
   build arg, baked to `/etc/cc-config-hash`.
5. If the running container's baked hash is not the blessed one (you re-blessed
   since it was built), recreate it with `--remove-existing-container`. `devcontainer
   up` alone never rebuilds.
6. Run the **boundary self-probe** (seven checks; see below). A full pass writes the
   hash to `verified-live.sha256` next to the manifest.
7. `exec devcontainer exec … claude`.

Target repos get **zero** new files — nothing is committed into them.

## Egress profiles (the registrable "languages")

Egress is default-deny. Every project gets `base` (Anthropic API/OAuth, npm,
GitHub IP ranges). Language toolchains are granted per project, **host-side only**:

| Profile | Opens | Auto-suggested from repo contents |
|---------|-------|-----------------------------------|
| `base`  | Claude Code's documented hosts (`api.anthropic.com`, `claude.ai`, `claude.com`, `platform.claude.com`, `downloads.claude.ai`, `mcp-proxy.anthropic.com`, `code.claude.com`; `console.anthropic.com` kept pending one verified login without it), `registry.npmjs.org`, GitHub ranges | always applied |
| `python`| `pypi.org`, `files.pythonhosted.org` | `pyproject.toml` · `requirements.txt` · `setup.py` |
| `rust`  | `crates.io`, `index.crates.io`, `static.crates.io` | `Cargo.toml` |
| `lean`  | `elan.lean-lang.org`, Lean release host, mathlib olean cache, `reservoir.lean-lang.org` | `lean-toolchain` · `lakefile.toml` · `lakefile.lean` |
| `android`| Google Maven (`dl.google.com`, `maven.google.com`), Maven Central, `services.gradle.org`, `plugins.gradle.org` | `gradlew` · `build.gradle[.kts]` · `settings.gradle[.kts]` |
| `dotnet` | `api.nuget.org` | `ProjectSettings/ProjectVersion.txt` · `Packages/manifest.json` · top-level `*.sln` / `*.csproj` |
| `llm`   | `openrouter.ai` | never — deliberate opt-in |
| `scholar`| Literature APIs (OpenAlex, Crossref, Semantic Scholar, Unpaywall) and open-access full-text hosts (arXiv, PMC / Europe PMC, bioRxiv/medRxiv, OpenReview) | never — deliberate opt-in |
| `vscode`| VS Code marketplace hosts | never (IDE-attach is unsupported) |

Profiles compose — but `--profile` **sets** the whole grant, it does not add to it:

```bash
cc-isolated --register ~/code/tool --profile rust,lean
```

Re-registering with `--profile lean` alone would leave that project with `lean` and
drop `rust`. That is deliberate (a grant you can only widen is not a grant), so name
every profile the project needs on every `--register`. `cc-isolated --list` shows the
current grant per project, and `--register` prints the transition
(`base,rust -> base,lean`) plus an explicit note for anything it drops.

Two rules that are load-bearing for the security model:

- **The repo never chooses its own egress.** `cc-isolated` will *suggest* a profile
  from what it sees (`pyproject.toml` → `python`) but never applies it. Letting an
  untrusted workspace grant itself network access would defeat the isolation.
- **`llm` is never in `base` and never suggested.** An LLM API is a general-purpose
  outbound channel — anything the agent can put in a prompt leaves the boundary.
  Grant it deliberately or not at all.

Registering re-blesses the manifest (a project's egress *is* boundary config), which
changes the blessed hash, so the next launch of **every** project recreates its
container from the new config (step 5 above) and re-verifies it.

### What is NOT covered

There is no profile — and no image toolchain — for non-Android JVM, Go, Ruby, etc.
Supporting a new ecosystem is a real change, not a config toggle: it needs a new
`egress/<name>.txt`, toolchain layers in the central `Dockerfile`, and a detection
clause in `suggest_profiles()` (see decision log #18/#19 for the uv and Android
precedents). The current registrable language toolchains are **Python, Rust, Lean,
Android, and .NET**.

### Why `WebSearch` works everywhere and `WebFetch` almost nowhere

This surprises people, and it is not a policy choice — it falls out of *where each
tool's HTTP request originates*:

- **`WebSearch` is executed server-side.** The only socket the container opens is to
  `api.anthropic.com`, which `base` admits for every project. So search works in
  every project, including base-only ones, and no amount of egress tightening will
  break it.
- **`WebFetch` fetches from the container.** It is an ordinary outbound request to
  the URL you name, so it is subject to the allowlist and the SNI proxy exactly like
  `curl`. It works for `code.claude.com` (listed in `base`, which is why the docs are
  readable) and for whatever a granted profile adds — and fails for everything else.
  Redirects are the sharp edge: a fetch of an admitted host that 302s to a
  non-admitted one fails at the second hop.

The practical rule inside the boundary: **search freely, fetch only what your profile
lists**, and treat a `WebFetch` failure as "not in my allowlist", not as "the site is
down". `curl` and `pdftotext` are the better tools for admitted hosts anyway, since
they give you the bytes rather than a summary.

**This is orthogonal to web taint.** `hooks/web-taint-mark.py` marks a session that
has ingested web content (via either tool) so `guard-trusted-writes.py` can gate
writes to trusted-policy files afterwards. That is a *content-provenance* control
inside the session; the egress allowlist is a *reachability* control at the network
boundary. They compose but neither implements the other — taint does not widen or
narrow what is reachable, and the allowlist does not care what a response says.
Granting `scholar` therefore means: the container can reach those hosts, and any
session that reads a paper is thereafter taint-marked like any other web read.

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

## Lean / mathlib inside the container

The image bakes **elan** (the Lean toolchain manager) at `/home/node/.elan`, on
`PATH`. After registering `--profile lean`:

```bash
cc-isolated --register ~/code/proofs --profile lean
cc-isolated ~/code/proofs
# inside the container:
lake exe cache get     # download mathlib's precompiled oleans (minutes, not hours)
lake build
```

**Lean is the one toolchain that is not pinned root-owned**, and the reason is
structural rather than an oversight: a Lean project pins its exact compiler in its
own `lean-toolchain` file, mathlib moves that pin every few weeks, and two repos on
one image routinely want different ones. So elan's toolchain store (`ELAN_HOME`) is
node-writable, and a repo whose pin is not baked into the image fetches it at
runtime. Everything the other layers protect is unchanged: `/opt/{rustup,cargo,dotnet}`,
`/usr/local/bin`, `/usr/local/share/cc-egress` and `/etc/cc-egress-profile` stay
root-owned, so this widens what a session can install for *itself*, not the boundary.

To pay that download at build time instead, set `LEAN_TOOLCHAINS` in
`devcontainer.json` to the pins your repos use (space-separated; the first becomes the
default), re-install and re-bless. Build time is not subject to `init-firewall.sh`, so
a baked pin needs no egress at all.

**`lake exe cache get` is not optional in practice.** Without the cache host in the
profile a mathlib-dependent repo compiles the whole library from source — hours per
repo, per clone, every time `.lake` is cleaned.

Failure modes worth recognizing on sight:

- **`elan` hangs or times out resolving a toolchain.** Either the project was never
  registered with `--profile lean`, or the release hostname in `egress/lean.txt` is
  the wrong one. That file ships two candidates (`release.` and `releases.`
  `lean-lang.org`) precisely because it was authored without egress to confirm which
  elan uses; the SNI proxy matches names **exactly**, so a near-miss is rejected
  rather than redirected. Watch one fetch succeed, then delete the loser.
- **`lake exe cache get` downloads nothing, and `lake build` starts compiling
  `Mathlib.Init`.** The cache host is missing or wrong. Confirm it against
  `Cache/Requests.lean` in a mathlib4 checkout on the host — it has moved before —
  then correct `egress/lean.txt`, re-install, re-bless.
- **`lake` cannot resolve a dependency required by bare name.** That path goes through
  Reservoir, not GitHub; `reservoir.lean-lang.org` is in the profile for it. Git
  `require`s (what mathlib itself uses) resolve to GitHub, which every session already
  reaches.

## Literature search inside the container

`scholar` is the one profile that is not a language toolchain: it grants the
academic metadata APIs and the open-access hosts that actually serve full text, and
the image bakes `pdftotext` (poppler-utils) so a downloaded paper can be read
without any further install.

```bash
cc-isolated --register ~/code/lit-review --profile scholar
cc-isolated ~/code/lit-review
# inside the container:
curl -s 'https://api.openalex.org/works?search=sparse+autoencoder&per_page=5' | jq '.results[].title'
curl -sL https://export.arxiv.org/pdf/2509.20645 -o paper.pdf
pdftotext -layout paper.pdf - | head -40
```

`curl`/`wget` are the right tools here rather than `WebFetch` — see the note below on
why `WebFetch` is unreliable inside the boundary.

**What is reachable, and what only looks reachable.** Metadata is the easy half
(OpenAlex, Crossref, Semantic Scholar, Unpaywall); full text is the half that
disappoints. A paper is readable here only when its *bytes* live on a listed host —
arXiv, PubMed Central, Europe PMC, bioRxiv/medRxiv, OpenReview. Unpaywall will
cheerfully return a PDF URL on `sciencedirect.com` or an institutional repository,
and the SNI proxy rejects it. `doi.org` is deliberately not listed: a DOI resolves by
redirecting to a publisher host, so admitting the resolver buys a hop to a host that
is still blocked. Resolve identifiers through Crossref/OpenAlex instead.

**Google Scholar is commented out in `egress/scholar.txt`, on purpose.** It has no
API, serves a CAPTCHA interstitial to non-browser clients, and its terms forbid
scraping — listing it opens a Google front in exchange for HTML that reliably is not
results. Uncomment, re-install, re-bless and rebuild if you want to try anyway;
expect a CAPTCHA page rather than a network error, which is a *different* failure
from the ones in the table below.

**`pdftotext` does not OCR.** A born-digital paper (everything on arXiv) extracts
cleanly; a scanned page extracts to nothing at all, which looks like a silent parse
failure rather than an error. No OCR stack is baked in — adding one is a
central-image change.

**Being allowlisted is not being welcome.** arXiv asks for one request per three
seconds on a single connection; Crossref and Unpaywall want a contact email in the
query string for their "polite" pools. The firewall enforces none of that, and a
harvest loop that ignores it gets the *host's* rate limiter, not ours.

Failure modes worth recognizing on sight:

- **Connection closes instantly on a host you believe is listed.** The usual cause is
  the exact-name rule: `arxiv.org` does not cover `export.arxiv.org` (both are listed
  for that reason), and Europe PMC's REST service lives under `www.ebi.ac.uk`, not
  `europepmc.org`. Check `/run/cc-sni-proxy/proxy.log`.
- **A metadata query works and every full-text link 000s out.** Expected: the links
  point at publisher hosts. Filter results to the OA hosts above, or fetch the arXiv
  or PMC version of the same paper.

## The boundary self-probe

Every launch refuses to `exec claude` unless all seven pass:

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
- **Config identity** — `/etc/cc-config-hash` in the image equals the hash of the
  manifest that is blessed *now*. Catches a container built before a re-bless, which
  is silently the old boundary (the launcher recreates it rather than failing).
- **Firewall complete** — `/run/cc-firewall/complete` exists, meaning the baked
  `init-firewall.sh` reached its sentinel on its last run, *including its node-run
  probes* (`dig` and `curl https://api.anthropic.com` as `node`, through the steering).
  The script fails closed, and a closed container passes every egress check while
  `node` has no DNS and no HTTPS — that is exactly what the 2026-09-09 outage looked
  like from the old five-check probe. The marker is root-written and is removed before
  every flush, so it vouches for the current ruleset. It is world-readable (0644) in a
  root 0711 directory: the probe reads it as `node`, and the missing write bit on the
  directory — not a denial of traversal — is what stops `node` forging or removing it.

**Blessed is not verified.** `--bless` (and `install.sh`, which blesses) hashes
files; it cannot know whether a container built from them works. Only a passing
self-probe against a container whose baked hash *is* the blessed hash writes
`~/.config/claude-devcontainer/verified-live.sha256`. `cc-isolated --list` shows
both. Run the verification explicitly after any boundary change — it always rebuilds
first, so it can never verify a leftover container:

```bash
cc-isolated --probe-only ~/code/api
```

The repo-side half of the same gate is `hooks/live-verify-gate.sh`: a `git commit`
that includes any manifest-hashed file under `devcontainer-config/` is blocked unless
its message carries a `Live-verified:` trailer — the hash `--list` shows after a
passing probe, or `Live-verified: no — <reason>`. The full loop is in
[`devcontainer-setup.md`](devcontainer-setup.md) → "Changing the boundary".

Profile entries are `domain[:port[,port...]]`; a domain needs two or more labels (a
bare `com` would become a whole-TLD resolver zone and is rejected). **Entries are
exact names for 443.** The resolver admits a zone (so `foo.claude.ai` resolves when
`claude.ai` is listed) but the SNI proxy admits only the literal entry (so the
connection is then rejected). List every name a client actually uses; a subdomain
is not covered by its parent.

## SNI filtering (tcp/443)

The allowlist matches addresses, and CDN fronts put thousands of unrelated names
behind one address. So `init-firewall.sh` also runs a small SNI-filtering proxy
(`cc-sni-proxy.py`, stdlib Python, its own unprivileged uid) and steers every
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
  reachability probes run as root and bypass the steering; its two SNI probes are
  run as `node` on purpose so they do not. The agent runs as `node` and is always
  subject to the steering.

Both the proxy and the filtering resolver bind the container's **own** address, not
`127.0.0.1`, and the nat rules DNAT there. That detail is load-bearing rather than
stylistic: an iptables `REDIRECT` on the OUTPUT chain hardcodes `127.0.0.1`, and such
packets are matched by the rule and then discarded by the kernel before reaching any
socket — which on 2026-09-09 left every session with no DNS and no HTTPS while every
root-run boundary probe passed. If you are reading the rules and wondering why they
are not the more obvious `REDIRECT`, that is why; see decision log #44.

The same rules also carry three `OUTPUT -d <container-address> --dport {53/udp,53/tcp,
3443/tcp} -j ACCEPT` entries that look redundant next to the `-o lo -j ACCEPT` above
them. They are not. A packet the nat table rewrote to a local address is *not* matched
by `-o lo`: the LOCAL_OUT hook point fixes the out-device before any chain runs, and
the nat hook's re-route updates the route cache but not the state the filter chain is
matching against — so filter still sees the original destination's device. Without the
destination-scoped accepts, every steered packet reaches the terminal REJECT. Do not
"simplify" them away.

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
| Connection closes immediately on a 443 host that is in your profile | SNI mismatch — see "SNI filtering" above and `/run/cc-sni-proxy/proxy.log`. A *subdomain* of a listed name is the common case: the resolver admits the zone, the proxy admits only the exact entry. Add the exact name. |
| `NOTE: blessed config … has NOT been verified in a live container` at launch | Expected after `install.sh`, `--bless` or `--register`. The launch rebuilds and verifies; if it fails, read the `PROBE FAIL` line. `cc-isolated --list` shows whether the current config has ever passed. |
| `Blessed config changed since this container was built — rebuilding` | Expected once per project after a re-bless. The container is recreated (repo and `~/.claude` volume are unaffected). |
| `PROBE FAIL (firewall): init-firewall.sh did not complete` | The baked firewall script aborted and failed closed: egress is denied *and* `node` has no DNS/HTTPS. Read the `devcontainer up` output for the `ERROR:` line, or run `sudo /usr/local/bin/init-firewall.sh` inside to see it. If it cannot bootstrap any more, recreate: `devcontainer up --remove-existing-container …`. |
| `OAuth error: getaddrinfo …` at `/login`, launch probe passed | Historically the steering-to-loopback bug (decision log #44); the firewall-complete check now catches that class at launch. If it recurs with the check passing, suspect a host missing from `egress/base.txt` — including a subdomain of a listed name. |
| `Network is unreachable` mid-session for a CDN host (e.g. openrouter.ai) | Resolve-at-start allowlist went stale behind rotating CDN IPs. Inside the container: `sudo /usr/local/bin/init-firewall.sh`. |
| `docker`/probe fails only inside a Claude Code session | Expected — CC blocks AF_UNIX sockets. Run `cc-isolated` from a normal host terminal. |
| Claude Code auto-update fails every launch in ONE project (`.last-update-result.json` shows `install_failed`; npm log shows `ENOTEMPTY … rename … .claude-code-XXXXXXXX`) | An earlier update was interrupted (e.g. session exited mid-update), leaving npm's retire-staging dir behind in that project's container. The staging name is derived from the path, so every later update collides with the same leftover. Inside the container: `rm -rf /usr/local/share/npm-global/lib/node_modules/@anthropic-ai/.claude-code-*`, then `claude update`. |
| A newly registered profile has no effect — the container's egress is still base-only (`/etc/cc-egress-profile` empty, `/etc/cc-config-hash` empty, proxy startup line reports too few names) | The container was rebuilt with a bare `devcontainer up --remove-existing-container …` from your own shell. `devcontainer.json` reads `CC_EGRESS_PROFILE` and `CC_CONFIG_HASH` via `${localEnv:…}`, and only `cc-isolated` exports them — run by hand they resolve to the empty string, so the image bakes base-only egress and rebuilds "successfully". Relaunch with `cc-isolated <repo>`, which rebuilds with both set. The error messages now print the assignments inline for the by-hand form. |
| Probe fails on image provenance after migrating from the 015 launcher | A leftover `.devcontainer/Dockerfile` in the target repo shadows the central one. Delete `.devcontainer/` **before** verifying (see `devcontainer-setup.md` → Migrating). |

## Related

- [`devcontainer-setup.md`](devcontainer-setup.md) — security model, one-time host
  setup, manual boundary verification, known limits.
- `docs/decisions/015-cc-process-isolation-docker-devcontainer.md` — the isolation
  decision.
- `docs/decisions/016-multi-project-devcontainer-central-config.md` — central
  host-side config, per-project volumes and egress.
