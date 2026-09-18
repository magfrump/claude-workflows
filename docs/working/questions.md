# Running questions

Questions raised during autonomous work that did not justify stopping.

**To answer:** write `Q-0NN: <your answer>` anywhere — a reply, a file, a commit.
The ID is the whole handle; you never have to restate the question. Answers move
the entry to `questions-archive.md`, so this file only ever holds what is still open.

**Needs** is the route — who or what actually discharges the item, from
`docs/working/triage-2026-09-17-backlog.md` §3.1:

| Route | Meaning |
|---|---|
| `you: judgment` | Needs your taste or authority. The only real attention spend. |
| `you: terminal` | Needs your machine, not your mind. Collected into one paste below. |
| `agent` | Mechanical. Should not be here long. |
| `trigger` | Not a question yet — a condition being watched. Costs you nothing. |
| `deferred` | Scheduled behind an event that has not happened. |

Maintained by `scripts/questions.sh` (`check` · `index` · `archive` · `next-id` · `open`).
The index below is generated — edit entries, not the table.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-011](#q-011--mathlib-cache-host) | you: terminal | What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.) | 2026-09-12 |
| [Q-012](#q-012--elan-sha256-pins) | you: terminal | Pin the per-arch SHA-256 of the elan release as build ARGs | 2026-09-12 |
| [Q-019](#q-019--worktree-cleanup) | you: terminal | Reclaim the 231 MB under `.claude/worktrees/` — the git half is done, the disk half is a plain `rm -rf` I... | 2026-09-17 |
<!-- index:end -->

## Open

### Q-011 · mathlib-cache-host
**Needs:** you: terminal · **Opened:** 2026-09-12 · **Status:** OPEN

What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.)

- **Attempt 2026-09-17 — your run was against the right file, and the answer is that the question's shape is wrong.** `rg -o 'https://[^"]*' .../mathlib/Cache/Requests.lean` returned exactly two strings: a bare `https://` and `https://github.com/leanprover-community/mathlib4.git`. A bare prefix means the cache URL is **assembled at runtime**, not written down as a constant — which is also what your sketched docstring describes (`MATHLIB_CACHE_GET_URL` → `--cache-from` → `MATHLIB_CACHE_FROM` → `defaultContainersForRepo repo`). So there may be no single hostname to list: the host comes from a per-repo container list, and an allowlist entry has to name whatever `defaultContainersForRepo` resolves to for mathlib4.
- **Read:** `devcontainer-config/egress/lean.txt` (the `lakecache.blob.core.windows.net` entry and its ACCEPTED RISK note)
- **The paste** — same checkout you used, wider net:

```bash
M=verifier/lean-project/.lake/packages/mathlib     # any mathlib4 checkout works
head -80 "$M/Cache/Requests.lean"
rg -n -A8 'defaultContainersForRepo|CACHE_FROM|CACHE_GET_URL|def .*[Cc]ontainer' "$M"/Cache/*.lean | head -60
```

- **What I do with it:** if the resolved container is a registry host (ghcr.io or similar) rather than the Azure blob, `lakecache.blob.core.windows.net` is a dead entry and `egress/lean.txt` gains the real one; if it still resolves to the blob host, the existing entry's VERIFY comment is discharged and nothing changes.
- **Interim:** `lakecache.blob.core.windows.net` stays listed, carrying its VERIFY comment. A wrong entry degrades to "stays blocked", never to a wider allowlist, so the cost of being wrong is a slow first build rather than an exposure.
- **If the answer differs:** correct `egress/lean.txt`, re-install, re-bless.

### Q-012 · elan-sha256-pins
**Needs:** you: terminal · **Opened:** 2026-09-12 · **Status:** OPEN

Pin the per-arch SHA-256 of the elan release as build ARGs

- **Answering "I don't see what action" (2026-09-17):** my entry was wrong to imply a container. No Lean, no egress profile and no container are involved — the two files are ordinary GitHub release assets, so **any machine with plain internet** produces the digests, including the host you are reading this on. The reason it is yours at all is only that this authoring environment has no egress; that is the whole blocker. Route corrected from `deferred` to `you: terminal`.
- **Context:** the Dockerfile's elan layer fetches `elan-<target>.tar.gz` from the GitHub release with no checksum, following the rustup layer's documented deferral. `ELAN_VERSION` ships as `v4.2.4` (`devcontainer-config/devcontainer.json:42`; the `Dockerfile:446` default is a stale fallback).
- **The paste:**

```bash
V=v4.2.4
for t in x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu; do
  printf '%s  ' "$t"
  curl -sL "https://github.com/leanprover/elan/releases/download/$V/elan-$t.tar.gz" | sha256sum | cut -d' ' -f1
done
```

- **What I do with it:** add `ELAN_SHA256_AMD64` / `ELAN_SHA256_ARM64` build ARGs and a `sha256sum -c` to the elan layer, matching the shfmt and .NET layers (`devcontainer-config/Dockerfile:165-176` is the shape).
- **Interim:** version-pinned, unverified — bounded by running at build time, but this layer installs into a node-writable tree, so the pin is worth more here than in the rustup layer.
- **If the answer differs:** if you would rather not run it, this stays as-is until the next `ELAN_VERSION` bump, which is the natural moment to collect both digests anyway.

### Q-019 · worktree-cleanup
**Needs:** you: terminal · **Opened:** 2026-09-17 · **Status:** OPEN

Reclaim the 231 MB under `.claude/worktrees/` — the git half is done, the disk half is a plain `rm -rf` I am not allowed to run.

- **Your run worked; my paste was incomplete (2026-09-17).** `git worktree list` now shows only `/workspace` and `.git/worktrees/` is gone entirely, so the `remove`/`prune` half succeeded — the registrations are all cleared. `du` still reports 231 MB because **`git worktree prune` deletes registrations, not directories**: what is left under `.claude/worktrees/` is 14 ordinary directories that git no longer knows about. That is my omission, not a failure of yours.
- **Nothing unique is in them, checked this session.** Against `main`'s tree, the files each directory holds that `main` does not are all *historical* paths (old `docs/working/` drafts, `scripts/review-arms.py` and friends now under `archive/benchmark/`) — i.e. stale bases, recoverable from `git log`. No directory holds work that exists only there.
- **One wrinkle:** three of them — `agent-a4569e6741d6f71c8`, `agent-ae5933c7c8f651ef7`, `agent-af8ebf915c7a1c66d` — carry a `.git` file pointing at `/home/magfrump/claude-workflows/.git`, not `/workspace/.git`. They belong to the **host** clone, so if that clone still lists them, remove them there with git rather than by hand.
- **The paste** (run where `.claude/worktrees` lives):

```bash
cd /path/to/claude-workflows          # the host clone
git worktree list                     # expect: only the main checkout
rm -rf .claude/worktrees/*            # the 14 orphaned directories
du -sh .claude/worktrees              # expect ~0
```

- **Interim:** the 231 MB stays. It is inert — no registration, no ref, nothing reads it — so this is disk, not risk.
- **If the answer differs:** if you would rather keep a couple as reference checkouts, keep `agent-af8ebf915c7a1c66d` (the widest set of historical paths of the fourteen) and delete the rest, which are older checkouts of the same tree at various points.

