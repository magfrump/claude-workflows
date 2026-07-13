# Devcontainer setup — isolated Claude Code sessions (decision 015)

Last verified: 2026-07-13
Relevant paths: `.devcontainer/`, `scripts/devcontainer-session.sh`, `test/devcontainer-session-functions.bats`

How this closes decision 015's two residual vectors: every tool (Read included)
runs inside the container's mount namespace, and host credentials are simply
not mounted (H1); the enforcement config is gated by a trust manifest stored in
host `~/.config/claude-devcontainer/`, which the container never sees (H2).

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
3. **Plant the canary** (host): `touch ~/.ssh/canary` — the launcher's H1
   probe checks this exact file is invisible in-container.
4. **Bless the enforcement config** (host, after reading the four files
   yourself): `scripts/devcontainer-session.sh --bless`

## Starting a session

```bash
scripts/devcontainer-session.sh
```

The launcher, in order: refuses to run if `.devcontainer/` or itself differs
from the blessed manifest → `devcontainer up` (bind-mounts the repo at
/workspace; first run builds the image, ~minutes) → boundary self-probe
(canary invisible + egress default-deny live) → `devcontainer exec claude`.

VS Code alternative: "Dev Containers: Reopen in Container" gives the same
boundary but skips the manifest gate and self-probe — prefer the launcher for
agent sessions; use VS Code attach for interactive poking.

First session only: run `claude` login inside the container. Credentials and
memory persist in the named volume `claude-workflows-claude-config` (mounted
at /home/node/.claude), surviving rebuilds. Per decision 015, **never** mount
host `~/.claude` or any host credential directory.

Git push auth: the container gets no host SSH keys by design. Use a
fine-grained PAT scoped to the repos the agent works on (`gh auth login`
inside the container, or `GH_TOKEN`), never your real host credentials.

## Verifying the boundary (H1/H2 canary probes)

The Continue trigger in decision 015 requires these to pass:

- **H1 (credential denial):** inside a session, ask CC to read
  `~/.ssh/canary` (host path) via the Read tool AND via Bash. Both must fail —
  the file simply doesn't exist in the container's namespace. The launcher
  probes the Bash half automatically at every start.
- **H2 (control-plane immutability):** edit `.devcontainer/init-firewall.sh`
  from inside a session, exit, and relaunch. The launcher must refuse with
  "enforcement files changed since last bless". (The in-container edit is
  possible — the repo is bind-mounted rw — but it cannot take effect without
  a human re-bless at the rebuild gate. Revert with git after the test.)
- **Egress:** `curl https://example.com` inside must fail; `git fetch` /
  `api.anthropic.com` must work. `init-firewall.sh` self-verifies both at
  container start, and the launcher re-probes example.com per session.
- **Tests:** `bats test/` green inside the container.

## Known limits and maintenance

- **Firewall allowlist is resolve-at-start:** domains behind rotating CDN IPs
  (openrouter.ai is on Cloudflare) can go stale mid-session; rerun
  `sudo /usr/local/bin/init-firewall.sh` inside the container if a previously
  working host starts timing out.
- **Image lifecycle:** `CLAUDE_CODE_VERSION=latest` is baked at build time.
  Rebuild (`devcontainer up --remove-existing-container` after a `--bless` if
  config changed) when CC falls behind; staleness >1 version for >2 weeks is
  a decision-015 Revisit trigger.
- **SI loop / cron (H5, unverified):** overnight runs need reworking to
  `devcontainer exec` non-interactively. Do not rely on overnight isolation
  until this is proven — decision 015 lists it as a Revisit trigger.
- **Drift-back hazard:** if >20% of agent work is still in host sessions
  after week 2, the boundary is failing behaviorally (Revisit trigger). The
  2-week Continue-trigger clock starts at first working devcontainer session.
