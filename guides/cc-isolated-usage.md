# cc-isolated — usage guide

Last verified: 2026-09-27
Relevant paths: `devcontainer-config/cc-isolated.sh`, `devcontainer-config/cc-exit-scan.sh`, `devcontainer-config/cc-gitdir.sh`, `devcontainer-config/cc-push.sh`, `test/cc-push.bats`, `devcontainer-config/egress/`, `devcontainer-config/Dockerfile`, `test/cc-isolated-functions.bats`, `hooks/live-verify-gate.sh`, `scripts/paper-queue.sh`, `test/paper-queue.bats`

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
cc-isolated --help                # usage header, exit status included
cc-push --remote <url> [REPO]     # push a session's commits via a host-only clone; first
                                  # time. --remote is sticky: stored in the clone, reused
cc-push [REPO]                    # later pushes (REPO defaults to the checkout holding $PWD)
cc-push --branch NAME [REPO]      # a branch other than the one HEAD names
cc-push --yes [REPO]              # no [y/N] prompt (the preview still prints)
cc-push --clone DIR [REPO]        # a host-only clone other than the default
cc-push --allow-running [REPO]    # go on although the session's container runs (warns)
cc-push --help                    # usage header, exit codes included
```

`cc-push` takes one checkout (`cc-push A B` and `cc-push A -- B` are usage
errors). Both tools follow `install.sh`'s exit-status convention (decision log
#58): 1 for an error, or for a prompt you declined; 2 for bad usage.

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
7. `devcontainer exec … claude`. Before step 4 the launcher snapshots what
   host git reads to decide what to run (hooks, configs, attributes, submodule
   and embedded git dirs, local remotes, rebase todo lists); when claude exits
   it compares, and exits **3** naming anything the session added, removed or
   changed. A linked worktree added in git's own layout (an agent
   worktree left behind) is not a finding: one `note:` line, and the exit
   status is claude's. It exits 4 when the exit scan cannot list or read any of it, and
   refuses to launch (exit 1) when the baseline snapshot cannot be taken — also
   when `.git` is already not a git directory git accepts, or the checkout root
   already looks like one, so a plant from an earlier session cannot become the
   baseline. The scan is a tripwire, not a guarantee: push with `cc-push`
   either way (see [Pushing: cc-push](#pushing-cc-push)).

**Exit status.** 0 on success; 1 an error (a refused launch included); 2 bad
usage; 3 the exit scan found a change (a note about standard worktrees is not
one); 4 the exit scan could not finish. Two
things to know when a script reads it. After a clean scan the launcher passes
**claude's own exit status** through, so a 1, 2, 3 or 4 can come from claude
rather than the launcher; a 3 or 4 from the scan replaces claude's status. And a
checkout whose `.git` cannot be read exits **1 at launch** (the baseline was
never taken and no session ran) but **4 at exit** (the session ran; its result
is unknown).

Target repos get **zero** new files — nothing is committed into them.

## Egress profiles (the registrable "languages")

Egress is default-deny. Every project gets `base` (Anthropic API/OAuth, npm,
GitHub IP ranges). Language toolchains are granted per project, **host-side only**:

| Profile | Opens | Auto-suggested from repo contents |
|---------|-------|-----------------------------------|
| `base`  | Claude Code's documented hosts (`api.anthropic.com`, `claude.ai`, `claude.com`, `platform.claude.com`, `downloads.claude.ai`, `mcp-proxy.anthropic.com`, `code.claude.com`; `console.anthropic.com` kept pending one verified login without it; the zone `.frame.claudeusercontent.com` for Artifact reads), `registry.npmjs.org`, GitHub ranges | always applied |
| `python`| `pypi.org`, `files.pythonhosted.org` | `pyproject.toml` · `requirements.txt` · `setup.py` |
| `rust`  | `crates.io`, `index.crates.io`, `static.crates.io` | `Cargo.toml` |
| `lean`  | Lean release hosts, mathlib olean cache | `lean-toolchain` · `lakefile.toml` · `lakefile.lean` |
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
Commit inside the container; push from the host with `cc-push` (next section).

## Pushing: cc-push

**Why not `git push` in the checkout.** The container writes the checkout,
`.git` included, through the bind mount. Host git run *in* the checkout — a
plain `git push`, even `git status` — runs whatever the session left there, as
you and with your keys: hooks, `core.fsmonitor`, filter drivers,
`remote.*.receivepack`, a remote repointed at a repo with its own hooks, an
`exec` line in an interrupted rebase's todo list. And some routes need no
`.git` change at all: a hook that was already there when you launched and runs
a tracked file (husky's `core.hooksPath=.husky/_`, the pre-commit framework,
`exec ./scripts/check.sh`) runs whatever the session wrote into that file.
`git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` is **not** a
safe alternative: it still runs a planted `remote.*.receivepack`, pushes to a
repointed `remote.*.url`/`pushurl` (whose hooks then run), and uses planted
credential helpers and `core.sshCommand`, including ones in included config
files. (It runs no clean/smudge filter: a push refreshes no index.)

**What `cc-push` does.** It keeps a separate, bare clone that only the host
writes (default `$XDG_DATA_HOME/cc-isolated/clones/<repo>-<id>`, which is
`~/.local/share/cc-isolated/clones/<repo>-<id>` when `XDG_DATA_HOME` is unset;
override with `--clone` or `CC_PUSH_CLONES_DIR`), and runs no git command in the
checkout — its one contact with it is the fetch in step 1:

```bash
docker stop <container>                                 # first: the session's container
cc-push --remote git@github.com:me/app.git ~/code/app   # first time: names the real remote
cc-push ~/code/app                                      # afterwards (or from inside it: cc-push)
cc-push --branch feat/x ~/code/app                      # a branch other than HEAD's
```

`--remote` is **sticky**: it is stored in the clone, every later `cc-push` of
that checkout uses it, and giving it again replaces it for all later runs (the
preview always prints the remote it will push to).

1. Resolves the branch (`--branch`, or the one the checkout's `HEAD` names,
   via `git ls-remote --symref`) and `git fetch`es **that branch only** from
   the checkout into the clone (`refs/cc/heads/<branch>`): other branches the
   session made are never copied to host disk. For a local path git starts
   upload-pack in the checkout's `.git`, which **reads** there — its refs,
   objects and config (and your global config) — but runs no hook, fsmonitor
   or filter; nothing is checked out, no submodule is fetched.
2. `git fetch origin` — the real remote, as configured **in the clone** by
   `--remote`. Remotes are never read from the checkout.
3. Prints the commits the push adds, and a diff stat when origin already has
   the branch (no external diff or textconv, no signature check; every string
   from the checkout — branch name, commit text, git's and the remote's
   messages — with anything outside printable ASCII shown as `?`, so C1
   controls and bidi overrides too), and asks `[y/N]` unless `--yes`.
4. `git push origin refs/cc/heads/<branch>:refs/heads/<branch>` from the clone.
   It never forces; a rewritten branch is refused by the remote as usual.

Exit codes: 0 pushed (or nothing to push); 1 an error (a refused checkout,
container or git version, a failed fetch, a rejected push, an interruption —
git's own status is never passed through) or declined at the prompt (`n`, or
Ctrl-C); 2 bad usage.

No hook runs on the push, so **git-lfs's `pre-push` upload does not run
either**: `cc-push` does not upload LFS objects. Push those from a normal clone
once you trust the content.

**What it refuses first.** A **git older than the fixed releases** of the May
2024 git security update (2.39.4, 2.40.2, 2.41.1, 2.42.2, 2.43.4, 2.44.1,
2.45.1, or 2.46 and later — this list is from git's release notes as recalled,
not re-checked offline): that update hardened what a local clone or fetch
trusts in the repository it reads. And a **running `cc-isolated` container for
the checkout** (`docker ps`, label `cc-project=<id>`): while it runs, a process
the session left behind can change `.git` between `cc-push`'s checks and its
fetch. Stop it with `docker stop`. When `docker` is missing or does not answer,
`cc-push` cannot tell, and refuses too. `--allow-running` goes on in both cases,
with a warning; use it only when you know the container is idle.

**What it refuses in the checkout.** upload-pack's reads are not confined to the checkout: a
`.git` that is a `gitdir:` file or a symlink, a `commondir`, an
`objects/info/alternates` (or `http-alternates`) file, or a symlink inside
`.git` can point it at any repository on this machine that you can read, and
`cc-push` would then offer that repository's history for push; an `[include]`
naming a FIFO, or a FIFO in `.git`, blocks it forever. So before fetching,
`cc-push` checks the checkout with plain file tests (no git) and refuses, with
the reason, a `.git` that is not a real directory, or that holds a
`commondir`, alternates, a symlink outside `hooks/`, a FIFO, socket or device,
or an `[include]`/`[includeIf]` section in `config` or `config.worktree`. It
also refuses a `.git` that git itself would not accept as a git directory (a
HEAD that is not `ref: refs/…`, a commit id or a link into `refs/`, or no
searchable `objects/` and `refs/`), and a checkout root that looks like a
repository (a `HEAD` next to `objects/`, or a `commondir` file): with `.git`
invalid, git falls back to reading the root as a bare repository, which the
session can plant (`cc-gitdir.sh`). It then fetches from `<checkout>/.git` by
name with `git-upload-pack --strict`, which uses exactly that directory or
fails. Run it on the main checkout the session was launched on. It also
refuses a **partial clone** (`remote.*.promisor` or `extensions.partialClone`
in `.git`'s config, read as text): upload-pack there cannot send the objects the
clone never downloaded, and `cc-push` will not let it fetch them, so the fetch
could only fail. Launch sessions on a full clone. What remains is upload-pack
reading the checkout's own refs, objects and (include-free) config.

Every git command it runs passes `core.hooksPath=/dev/null` and
`core.fsmonitor=false`. `test/cc-push.bats` plants every hook `githooks(5)`
lists, fsmonitor, clean/smudge/process filters, receive-pack and upload-pack
commands, `uploadpack.packObjectsHook`, `core.alternateRefsCommand`,
`core.sshCommand`, `core.gitProxy`, a credential helper, a legacy remotes file
and a repointed `origin` in the checkout, and asserts that a `cc-push` fires
none of them and pushes the fetched commit (git 2.39); it also covers each
refusal above.

**Keep the clone hook-free.** It holds content the container wrote. It is bare,
so nothing is checked out and no `npm install` installs husky into it. If you
ever check out a working tree from it and run husky, pre-commit or lefthook
there, the fetched files run on your next commit. Do your own host-side work in
a normal clone of the real remote after the push, like any collaborator's
commits — and read what you pull before you run it.

### The exit scan is a tripwire (Q-069 [3], Q-076)

`cc-isolated` also snapshots, before the session, what host git reads to decide
what to run, compares when claude exits, and exits **3** naming anything added,
removed or changed (4 when it cannot read something; it refuses to launch, exit
1, when it cannot take the baseline or `.git` is already invalid). A clean scan
passes claude's own exit status through (see "Exit status" above). It hashes files (content, mode, symlink target)
rather than checking a list of keys, so any change is a finding, even
`user.name`. It records, for every git dir it reaches — the checkout's git and
common dir, git dirs nested at `modules/**` and `worktrees/*`, every embedded
`.git` in the working tree, every common dir a `commondir` file names, every
local-path remote — `config`, `config.worktree`, `commondir`,
`info/attributes`, the hooks dir and each hook (except `*.sample`), legacy
`remotes/*` and `branches/*` files, in-progress `rebase-merge/`,
`rebase-apply/` and `sequencer/` state, and every symlink. It follows what those
configs name: `core.hooksPath` dirs, include and `includeIf` targets,
`core.attributesFile`, and local-path remotes inside the checkout
(`remote.*.url`/`pushurl`, `remote.pushDefault`, `branch.*.remote`/`pushRemote`,
`url.<base>.insteadOf`, `file://localhost/`, relative paths such as `sub/a:b`,
resolved in the working tree of the repo whose config names them).
Your own global and system config is read with its includes evaluated for each
git dir (`includeIf "gitdir:…"` and `gitdir/i:` matched against the physical
path and against the path you launched on, symlinks kept, as git matches both;
`onbranch:` and `hasconfig:` taken as matching), so a relative
`core.hooksPath` or `core.attributesFile` there is walked in the top-level
working tree and in every embedded repo. Those are the only entries of your own
config it follows; the rest is not recorded. It also records whether git would
accept the checkout's git dir (and the kind of its `HEAD` — a branch, a commit
id or a link — not which branch, so switching branches is not a finding) and
whether the checkout root looks like a repository; a change in either is a
finding, and a git dir git would not accept at exit is a finding even if it was
so at launch (git would fall back to reading the root). It runs nothing from the checkout
(plain file reads, `git config --file … --no-includes` from `/`, and host tools:
`find` without following symlinks, `stat`, `readlink`, `realpath`,
`sha256sum`, `cat`, `tr`, `sort`, `awk`, `sed`, `grep`, `cut`, `mktemp`, `dirname`,
`rm`), and every name, value and error it prints is reduced to printable ASCII,
line breaks included (`find`'s and `git config`'s own error text is kept, as
one such line). A file
it would hash that is over 64 MiB (a sparse file counts at its apparent size),
or more than 1 GiB to hash in all, fails the scan (exit 4: treat the checkout as
unsafe) rather than stalling it; so does a `.git` file or `commondir` over 64 MiB,
before its first line is read.

**Linked worktrees left behind (Q-094).** When the only differences are
worktrees added (`git worktree add`, as agent worktrees are) in the exact
layout git writes, the scan prints one `note: exit scan: only linked worktrees
in git's standard layout changed (added: agent-x) …` line instead of the
warning and returns claude's status. A linked worktree takes its config, hooks
and `info/attributes` from the checkout's own `.git`, never from its private
dir (tested on git 2.39.5), except `config.worktree`, which refuses the note.
"Exact" (`scan_std_worktrees` has the full rule): the private dir is the
checkout's own `.git/worktrees/<name>` (`<name>` of letters, digits, `.`, `_`,
`-`) with `commondir` exactly `../..\n` and no `hooks/`, `config`,
`config.worktree` or symlink; its working tree is inside the checkout; and that
tree's `.git` file is exactly `gitdir: <private dir>\n`, by host path or by the
container's `/workspace/…` path (which, if it exists on the host, must be the
same directory). Anything else warns as before, worktree lines included — also
any other change in the session, a worktree removed during it, and **any
checkout whose config holds a relative `core.hooksPath` or
`core.attributesFile` (husky's `.husky/_`) or a relative local remote** other
than `.`, which git would resolve in the new worktree's tree, unscanned.

It catches the common plants. It **cannot** be complete, so a clean exit is not
permission to run git in the checkout.

#### Known routes it does not see

This is the one list of what the scan and `cc-push` do not cover
(`cc-exit-scan.sh` and `cc-push.sh` point here); update it here when a change
opens or closes a route.

- **A hook that runs a tracked file.** A hook present at launch that runs a
  file from the working tree (husky, the pre-commit framework, lefthook,
  `exec ./scripts/check.sh`): the session edits the tracked file and nothing
  in `.git` changes. The same holds in a linked worktree the session leaves
  behind: its tracked files are never read, only its layout (see above).
- **Anything present at launch.** The launch-time state is the baseline: an
  earlier session's plant you did not remove, a rebase left in progress, or a
  config value that names a program by path inside the checkout
  (`core.pager = ./tools/pager.sh`: the session can rewrite `tools/pager.sh`).
  (A `.git` git would not accept, or a root that looks like a repository, is
  refused at launch rather than taken as the baseline.)
- **After the scan.** The container keeps running when claude exits; a process
  the session left behind can plant after the scan. Only a stopped container
  (`docker stop`) cannot. `cc-push` refuses while the container runs.
- **No scan.** A launcher killed before claude exits (closed terminal,
  SIGTERM) scans nothing. Ctrl-C that ends the session still scans; a Ctrl-C
  *during* the scan stops it and exits 4 ("the exit scan was interrupted").
- **A slow scan.** The cost is forks per git dir, not I/O: about 2–4 s per
  snapshot on a ~400k-file repository, and about 29 ms more for each embedded
  repository (the tree walk itself is ~0.05 s per 100k files), paid at launch
  and again at exit. Hashing is capped (64 MiB a file, 1 GiB in all), but a
  session can still plant many files or embedded repos to make the exit scan
  take a long time. If you stop it, treat the checkout as unscanned.
- **A URL rewritten by `url.<base>.insteadOf`.** The base is walked, never the
  rewritten URL, so a remote rewritten to a local path the session plants runs
  that repository's hooks on push.
- **One unlistable directory blocks the scan.** The embedded-repo search walks
  the whole working tree and fails closed: a single directory you cannot list
  (a container-owned `pgdata` at mode 700, a root-owned build cache) refuses
  the launch (exit 1) or, at exit, reports exit 4. Move such data outside the
  checkout.
- **A repository in a working-tree directory not named `.git`.** Embedded
  repositories are found by a `.git` entry. A bare-layout directory (`HEAD`,
  `objects/`, `refs/`) under another name is not walked; host git run *inside*
  that directory would use it and run its hooks. (Only the checkout root is
  checked for that layout.)
- **`~` forms.** Only a leading `~/` in a config path value
  (`core.hooksPath`, `include.path`, `core.attributesFile`, an `includeIf`
  pattern) is expanded to your home. `~user/…`, a bare `~`, and a `~` in a
  local remote URL are taken as relative paths, not as git expands them.
- **Tracked `.gitattributes` and `.gitmodules`.** Not scanned. An attribute
  selects a driver that config defines; the repository configs are scanned,
  but your own global config's entries are not recorded, so an attribute that
  selects a driver defined there (`filter.lfs.*`) runs it on session-written
  content with no finding. `.gitmodules` URLs and `update` settings act on
  `git submodule update`.
- **Another route to the checkout.** `includeIf "gitdir:"` is evaluated for
  the physical path and the path you launched on; running git through a
  different symlinked route can match a condition the scan did not evaluate.
- **Another git version.** The scan and `cc-gitdir.sh` model git 2.39's rules
  (repository discovery, `is_git_directory`, `includeIf` matching, what counts
  as a local URL). A git that reads a file those rules do not, or discovers a
  repository differently, can act on something the scan never recorded.
- **Host programs pointed at the checkout.** Anything on the host that reads a
  path inside the checkout (an editor plugin, a language server, `direnv`, a
  build tool) is outside what the scan looks at.
- **What `cc-push` still trusts.** It runs only when `.git` is a valid git
  directory with none of the refused entries, the session's container is
  stopped, and the host git is at or above the May 2024 fixed releases (see
  [Pushing: cc-push](#pushing-cc-push)). Within that, upload-pack still
  **reads** the checkout's refs, objects and include-free config (and your
  global config): a bug in git's handling of a hostile repository it reads is
  not something `cc-push` can rule out. Its push runs no hook, so git-lfs's
  `pre-push` does not upload LFS objects.
- **Your PATH, and `--yes` without `--branch`.** `cc-push` drops relative PATH
  entries and entries inside the checkout, then works from `/`. The few tools
  it runs before it has located the checkout (`readlink`, `dirname`,
  `realpath`) are still looked up on your absolute PATH entries. With `--yes`
  and no `--branch`, the checkout's HEAD, which the session controls, picks the
  branch that is pushed; pass `--branch` when scripting it.

`install.sh` guards only its own git calls against a planted `.git`. Decision
034 set "the host never reads a container-written `.git`" for the benchmark
harness; `cc-push` applies the same rule to pushing.

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
  Push with **`cc-push`**, never with host git in the checkout: see
  [Pushing: cc-push](#pushing-cc-push).
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
  Reservoir, not GitHub. `reservoir.lean-lang.org` was removed from the profile on
  2026-09-23 because its front end allows domain fronting (Q-051). Switch the require to
  a git URL. Git `require`s (what mathlib itself uses) resolve to GitHub, which every
  session already reaches.

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
  or PMC version of the same paper. When neither exists, queue the paper rather than
  dropping it — see below.

**The escape hatch is a queue, not a wider allowlist.** A session that wants a paper
it cannot fetch records the request instead of losing it:

```bash
~/.claude/scripts/paper-queue.sh add 10.1016/j.neuron.2024.01.007 "cited by the review, no preprint"
~/.claude/scripts/paper-queue.sh add https://www.sciencedirect.com/science/article/pii/S0896627324000012
~/.claude/scripts/paper-queue.sh list     # what is still outstanding
~/.claude/scripts/paper-queue.sh status   # counts, plus any request whose PDF has arrived
```

The queue is a five-column TSV at `papers/requests.tsv` in the project (override with
`$PAPER_QUEUE`), created on the first `add` and idempotent on the identifier, so a
loop that rediscovers the same DOI does not pile up duplicates. On the **host**, the
human works the list: fetch each PDF however they normally would — browser session,
institutional proxy, interlibrary loan — drop it into the project's `papers/`
directory named after the identifier's slug (`10.1016-j.neuron.2024.01.007.pdf`), and
run `~/.claude/scripts/paper-queue.sh done <identifier>`. `status` notices a dropped-in file on
its own by matching that slug, so a forgotten `done` shows up as a nudge rather than
as a lost paper. Next session, `pdftotext` reads it like any other local PDF.

This is deliberately a workaround and not a fix: the boundary is **not** widened for
it. One human retrieval step covers the whole tail at once — institutional proxies,
CAPTCHA interstitials, paywalls that are inconsistent per article — where each new
allowlist entry would buy exactly one publisher and leave a permanent hole behind.

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
is not covered by its parent. The one exception is a **zone entry**, `.zone`
(leading dot, three or more labels, tcp 443 only), which admits the zone and every
name under it at all three layers — only for per-object subdomains the operator
assigns and no list can enumerate. The three-label rule does not catch a
multi-tenant apex such as `.s3.amazonaws.com`; never zone a namespace users can
claim. `base`
carries one, `.frame.claudeusercontent.com` (decision log #55); each new one needs
its residual written beside it.

## SNI filtering (tcp/443)

The allowlist matches addresses, and CDN fronts put thousands of unrelated names
behind one address. So `init-firewall.sh` also runs a small SNI-filtering proxy
(`cc-sni-proxy.py`, stdlib Python, its own unprivileged uid) and steers every
tcp/443 connection the agent makes through it. The proxy reads the TLS
ClientHello's server name, admits it only if it is an allowlisted name (or a
subdomain of a GitHub zone), resolves that name itself, connects there, and
splices bytes. Nothing is decrypted.

**What it closes:** opening a connection *by name* to a non-allowlisted host that
happens to share an address with an allowlisted one (a Cloudflare neighbour of
`api.anthropic.com`). The TLS server name must be on the list.

**What it does not cover:**

- Ports other than 443. GitHub SSH on 22 and a host model server on 11434 stay
  address+port matched only.
- A name under an allowlisted *zone* that an attacker can obtain. GitHub zones
  don't hand those out.
- Domain fronting through an exact name. The proxy sees only the SNI; the HTTP
  `Host` header travels encrypted. A client can send `SNI: dl.google.com` with
  `Host: <another tenant>`, and the front end decides where it goes. A host test
  on 2026-09-23 (questions-archive Q-045) found:
  - **Routes by Host (fronting works):** the Google front end behind
    `dl.google.com` and `maven.google.com` (so the Google-hosted surface,
    writable `storage.googleapis.com` included, is reachable in principle);
    `elan.lean-lang.org` (any GitHub Pages site); `reservoir.lean-lang.org`
    (served an unrelated third-party site). The two lean names were removed from
    the profile on 2026-09-23 (Q-051); the Google names stay under an accepted
    risk (Q-052).
  - **Refuses (403) or ignores Host:** `repo.maven.apache.org`,
    `repo1.maven.org`, `services.gradle.org`, `plugins.gradle.org`,
    `release.lean-lang.org`; `releases.lean-lang.org` serves its default page
    for any Host.
  - **Refuses a different account:** `lakecache.blob.core.windows.net` returned
    `AccountNotFound` for another storage account's Host (Q-053).

  The test covered only the `android` and `lean` names; `base`'s names were not
  tested. Closing the residual needs TLS interception, which the design rules
  out.
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
| Artifact tool: `EAI_AGAIN … <uuid>.frame.claudeusercontent.com`, or an "update" publishes a second artifact | The container predates decision log #55 (the `.frame.claudeusercontent.com` zone in `base`). Re-install, re-bless, `--probe-only`. Resolver refusals are not logged, so this shows as a DNS error, not a proxy REJECT. |
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
