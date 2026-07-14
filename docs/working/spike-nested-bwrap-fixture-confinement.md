# Spike: Can a bats suite run under a nested bwrap profile that provably denies network and confines writes on this WSL2 host?

> ## ⚠ SUPERSEDED 2026-07-13 — the primitive this spike validated is GONE. Do not action the recommendation below.
>
> Re-probed 2026-07-13 in the current session environment. Decisions 015/016 moved sessions out of the
> bwrap sandbox and into the `cc-isolated` **Docker devcontainer**, which measured a different boundary
> than this spike did:
>
> | | this spike (2026-07-09) | re-probe (2026-07-13) |
> |---|---|---|
> | `bwrap` | present (0.6.1) | **ABSENT** |
> | `unshare -rn true` | exit 0 | **EPERM** — seccomp blocks `CLONE_NEWUSER` |
> | `uid_map` | `1000 1000 1` | `0 0 4294967295` (Docker init userns) |
> | `CapEff` | — | **`0000000000000000`** (zero effective capabilities) |
> | `iptables -L` | — | Permission denied |
>
> **The "Proceed to RPI" recommendation below is invalid as written**: the agent cannot create a
> user/network namespace, so it cannot self-apply confinement to its own test runs. Confinement remains
> achievable *at the container boundary from the host* (`docker run --network=none` for a test step),
> but the in-container agent has no `docker` CLI, no socket, and no capabilities to invoke it — so this
> is **host/CI-side infrastructure, not a runnable script this repo can ship.**
>
> This is the spike's own **pre-mortem narrative 1** — *"Platform pulls the rug… the harness gets
> bypassed instead of fixed"* — realized within four days, before anything was built. The mitigation it
> prescribed (a runner preflight probe + loud unconfined-mode warning) is now a hard requirement of any
> revival, not an optional nicety.
>
> Also observed on re-probe: egress from a test is **live** (`curl https://github.com` → `200` inside the
> session). The devcontainer's ipset allowlist bounds the blast radius but necessarily permits
> `api.anthropic.com`, so the original 4d39475 incident class — a test making a real, billable
> `claude -p` call — is **unmitigated at runtime today**.
>
> Superseding analysis and the resulting decision: `docs/working/dd-polyglot-test-hermeticity.md`.

Date: 2026-07-09
Last verified: 2026-07-13 — **findings falsified by environment change; see the superseded banner above**
Relevant paths: test/guide-index-sync.bats, docs/decisions/014-secure-tool-guidance-layers.md, docs/working/dd-secure-tool-guidance.md, docs/decisions/016-multi-project-devcontainer-central-config.md
Branch: worktree-agent-af8ebf915c7a1c66d (worktree branch; spike is doc-only, no throwaway code to discard)
Time spent: ~25 minutes of probing (within the 30-45 min timebox)

- **Goal**: Determine whether decision 014's layer-3 stretch goal — per-suite provable fixture confinement via nested bwrap — is feasible at all inside Claude Code's already-bwrapped Bash environment on this WSL2 host.
- **Project state**: executes layer 3 of decision 014 · follows the 2026-07-09 hardening and the DD in docs/working/dd-secure-tool-guidance.md · not blocked
- **Task status**: complete

## Question (step 2)

Can `bats` run under a bwrap profile launched from inside Claude Code's own bwrap
sandbox, such that the child provably (kernel-enforced, not convention) has no network
and can write only to a designated scratch directory?

Binary feasibility criteria:

- **Success looks like:** (a) `bwrap --unshare-net ...` exits 0 from inside the sandbox;
  (b) inside the profile, a TCP connect to an external IP AND to the outer sandbox's
  127.0.0.1:3128 proxy both fail at the syscall level; (c) a write to the repo/`$HOME`
  fails while a scratch-dir write succeeds; (d) an existing suite
  (`test/guide-index-sync.bats`) passes under the full profile.
- **Failure looks like:** the minimal probe `bwrap --ro-bind / / -- true` (or the
  `--unshare-net` variant) exits nonzero with a namespace-creation error, and no cheaper
  in-sandbox primitive (unshare, proxy poisoning as *enforcement*) achieves kernel-level
  network denial.
- **Ambiguous if:** bwrap exits 0 but network remains reachable inside (isolation
  cosmetic), or the suite can't run for tooling reasons unrelated to confinement.

Graveyard check (step 1): `grep -iE "bwrap|sandbox|nested|confine|namespace|unshare"
docs/thoughts/spike-graveyard.md` → no matches. No prior abandoned attempt.

## Answer

**Yes — unambiguous go.** Nested bwrap works inside the current sandbox on this host
(bubblewrap 0.6.1, kernel 6.18.33.2-microsoft-standard-WSL2): `--unshare-net` and
`--unshare-all` both succeed, network denial is kernel-enforced (fresh netns with an
empty `lo`; external connects get `ENETUNREACH`, the outer sandbox's proxy at
127.0.0.1:3128 gets `ECONNREFUSED` because no listener exists in the child netns), write
confinement via `--ro-bind / /` + scratch bind is enforced (`Read-only file system`), and
a real suite passes under the full profile with ~5ms overhead. All four success criteria
met; sub-questions 2 (fallback primitives) and 3 (outside-sandbox runner) were
conditional on failure and are moot.

## Key findings

**What worked**

- `bwrap --ro-bind / / -- true`, `+ --unshare-net`, `+ --unshare-all`: all exit 0 from
  inside the already-bwrapped Bash environment. `unshare -rn true` (userns+netns) also
  works. Nesting depth ≥3 works (outer sandbox → bwrap → bwrap, exit 0).
- Why it works: unprivileged user namespaces are unrestricted here. We are already inside
  a userns (`/proc/self/uid_map` = `1000 1000 1`), `/proc/sys/user/max_user_namespaces`
  = 2147483647, no `kernel.unprivileged_userns_clone` or apparmor restriction sysctl
  exists, and `bwrap` is not setuid (mode 755) — so it uses plain unprivileged userns
  creation, which the kernel allows to nest.
- Network denial is **enforcement, not convention**: inside `--unshare-net` the only
  interface is a fresh zero-traffic `lo`. Hidden test code cannot bypass it — the outer
  sandbox's network path runs through a proxy on 127.0.0.1:3128, and that listener does
  not exist in the child's loopback. Proxy env vars are dead weight there (but see
  gotcha on `--clearenv` below).
- Write confinement is enforcement: `--ro-bind / /` makes writes to the repo and `$HOME`
  fail with `EROFS`; a `--bind`-ed scratch dir accepts writes. `--tmpfs /tmp` masks the
  shared /tmp.
- Working profile (demoed):
  `bwrap --ro-bind / / --dev /dev --proc /proc --tmpfs /tmp --bind "$SCRATCH" "$SCRATCH"
  --unshare-net --unshare-pid --die-with-parent --setenv TMPDIR "$SCRATCH" --chdir "$REPO"
  -- bats <suite>`
- Demo A: `bats test/guide-index-sync.bats` passes under the profile (`1..1 ok`).
  Demo B: a hostile fixture asserting that `curl https://github.com`, a raw
  `socket.connect(('140.82.112.3',443))`, and `touch $HOME/HOSTILE_ESCAPE` all fail —
  all three assertions pass, and no escape file exists afterward.
- Overhead is negligible: 0.133s confined vs 0.128s bare for the demo suite.

**What didn't / gotchas**

- Bare `unshare -n true` fails (`Operation not permitted`) — netns without a userns needs
  CAP_SYS_ADMIN. Harmless: bwrap and `unshare -rn` create the userns first.
- `--ro-bind / /` alone breaks bats with `/dev/null: Permission denied` — the child must
  get a fresh `--dev /dev` (and `--proc /proc` when using `--unshare-pid`).
- The outer sandbox's proxy **credentials are visible in the child's environment**
  (HTTP_PROXY etc. carry a user:password pair). Useless for egress inside the netns, but
  readable by fixture code — the profile must add `--clearenv` + an explicit allowlist
  (`PATH`, `HOME`, `TMPDIR`, `BATS_*`).
- Reads are NOT confined: `--ro-bind / /` leaves ~everything readable (the outer
  sandbox's read denials on `~/.ssh` etc. still apply underneath). "Provably scoped"
  means network+writes, not reads.

**Surprises**

- The DD's risk assessment ("WSL2 nested-bwrap fragility", matrix row 11 rated high
  risk) did not materialize. The prior managed-settings incident
  (`project_sandbox_bwrap_wsl_broken.md`) was an *outer*-sandbox mount-point problem,
  now resolved, and never evidenced a nesting restriction.

## Recommendation

**Proceed to RPI** for the per-suite capability-manifest harness. This maps to decision
014's revisit trigger: *"if the spike shows nested bwrap works on WSL2 → open an RPI for
per-suite confinement (and reconsider pruned candidate 15)."* That trigger has fired.
Pruned candidate 15 (nested per-command sandboxes for re-allowlisting) may also be
reconsidered, though its H1 surface-widening objection still stands independently of
feasibility.

Pre-mortem run per spike workflow step 5:
`docs/reviews/pre-mortem-capability-manifest-harness.md` (4 narratives, summarized in
the seed below).

## RPI seed

- **Scope for RPI**: Build a capability-manifest bats runner: each suite gets a declared
  capability profile (default `network: none, write: scratch-only`), and a runner script
  executes bats under the corresponding nested-bwrap profile, with a preflight probe and
  a confinement self-test suite.
- **Known invariants**:
  - The profile skeleton that works: `--ro-bind / / --dev /dev --proc /proc --tmpfs /tmp
    --bind <scratch> <scratch> --unshare-net --unshare-pid --die-with-parent` plus
    `--clearenv` and an explicit env allowlist.
  - Manifest content is trusted policy: it must ship in the runner's deployed copy, NOT
    be read at run time from the agent-writable repo (014's copy-not-symlink rule;
    pre-mortem narrative 2 is the must-address).
  - H1 from the DD still binds: the harness must not add any allowlist entry capable of
    arbitrary execution.
  - Runner must be non-interactive (H3) — degrade loudly, never prompt.
- **Relevant files/APIs**: `test/*.bats` (suite inventory + `@category` tags),
  `test/guide-index-sync.bats` (demoed suite), `hooks/` deployment convention for the
  copy-not-symlink pattern, `docs/decisions/014-secure-tool-guidance-layers.md` (layers
  1-2 this composes with), bubblewrap 0.6.1 man page (`--unshare-*`, `--clearenv`,
  `--die-with-parent`).
- **Gotchas to carry forward**: fresh `--dev /dev` is mandatory (bats dies on
  `/dev/null` otherwise); `--proc /proc` needed with `--unshare-pid`; bare `unshare -n`
  doesn't work (use bwrap/userns); proxy creds leak via env without `--clearenv`; bats
  lives under `~/.nvm/...` so the env allowlist must preserve a working `PATH`; suites
  that legitimately need network (`claude`/`gh` invokers) need a deployed-copy manifest
  entry, not a repo-side override.
- **Failure narratives (from /pre-mortem)**: (1) *Platform pulls the rug* — a Claude
  Code/WSL update blocks nested userns and the harness gets bypassed instead of fixed;
  mitigate with a runner preflight probe + loud unconfined-mode warning. (2) *Manifests
  self-declared by the code they confine* — laxity creep / poisoned widening; mitigate
  with deployed-copy manifest table (must-address). (3) *Env-drift rot* — `--clearenv`
  breaks suites in confusing ways and contributors bypass the runner; mitigate with a
  single env-allowlist function + `test/confinement-selftest.bats`. (4) *"Provably
  scoped" oversells* — reads (incl. settings.json) remain unconfined and scratch output
  can stage exfil for later unconfined steps; mitigate by documenting the read-scope
  limitation and treating scratch artifacts as untrusted. Full narratives:
  `docs/reviews/pre-mortem-capability-manifest-harness.md`.
- **What the spike did NOT answer**:
  - Behavior under `bats --jobs` parallelism and with suites that spawn daemons
    (`--die-with-parent` interaction).
  - Whether suites invoking `git` need extra binds/env (`~/.gitconfig` is readable, but
    `HOME` handling under `--clearenv` is untested).
  - Longevity: whether future Claude Code sandbox versions keep userns nesting open
    (pre-mortem narrative 1) — the preflight probe is the detector.
  - Manifest schema/granularity (per-file vs per-`@category`) — a small DD inside the
    RPI plan step.
  - Whether the fixture-hermeticity lint (layer 2) and this harness should share suite
    metadata.

## Verdict mapped to decision 014

**Nested confinement feasible → seed an RPI for per-suite capability manifests.**
Update 014's layer-3 line from "may be infeasible on this platform" to "feasible,
validated 2026-07-09" when the RPI opens. No graveyard entry (recommendation is
proceed).

## Appendix — probe transcript (key commands, exact output)

Proxy credentials in env output are redacted as `<redacted>`.

```
$ bwrap --ro-bind / / -- true                      ; echo exit=$?
exit=0
$ bwrap --ro-bind / / --unshare-net -- true        ; echo exit=$?
exit=0
$ bwrap --ro-bind / / --unshare-all -- true        ; echo exit=$?
exit=0
$ unshare -rn true                                 ; echo exit=$?
exit=0
$ unshare -n true                                  ; echo exit=$?
unshare: unshare failed: Operation not permitted
exit=1

$ cat /proc/sys/kernel/unprivileged_userns_clone
cat: /proc/sys/kernel/unprivileged_userns_clone: No such file or directory
$ cat /proc/sys/user/max_user_namespaces
2147483647
$ cat /proc/self/uid_map
      1000       1000          1
$ ls -la /usr/bin/bwrap
-rwxr-xr-x 1 nobody nogroup 72160 Sep 23  2024 /usr/bin/bwrap        # not setuid
$ uname -r
6.18.33.2-microsoft-standard-WSL2
$ bwrap --version
bubblewrap 0.6.1

# Baseline: outer sandbox has network via proxy
$ env | grep -i proxy | head -3
https_proxy=http://<redacted>@localhost:3128
HTTP_PROXY=http://<redacted>@localhost:3128
all_proxy=http://<redacted>@localhost:3128
$ curl -sS -o /dev/null -w "%{http_code}" https://github.com
200

# Inside --unshare-net: network is severed at kernel level
$ bwrap --ro-bind / / --unshare-net -- curl -sS --max-time 10 https://github.com
curl: (7) Failed to connect to localhost port 3128 after 0 ms: Connection refused
$ bwrap --ro-bind / / --unshare-net -- python3 -c \
    "import socket; s=socket.socket(); s.settimeout(5); s.connect(('140.82.112.3',443))"
OSError: [Errno 101] Network is unreachable
$ bwrap --ro-bind / / --unshare-net -- python3 -c \
    "import socket; s=socket.socket(); s.settimeout(5); s.connect(('127.0.0.1',3128))"
ConnectionRefusedError: [Errno 111] Connection refused
$ bwrap --ro-bind / / --unshare-net -- cat /proc/net/dev
    lo:       0       0    0 ...        # only a fresh, zero-traffic loopback

# Write confinement
$ bwrap --ro-bind / / --tmpfs /tmp --bind "$SCRATCH" "$SCRATCH" --unshare-net \
    -- touch "$WT/PROBE_SHOULD_FAIL"
touch: cannot touch '.../PROBE_SHOULD_FAIL': Read-only file system
$ bwrap ... -- sh -c "echo ok > $SCRATCH/probe && cat $SCRATCH/probe"
ok
$ bwrap ... -- touch "$HOME/PROBE_SHOULD_FAIL"
touch: cannot touch '/home/magfrump/PROBE_SHOULD_FAIL': Read-only file system

# Gotcha: ro-bind alone breaks bats
$ bwrap --ro-bind / / --tmpfs /tmp ... -- bats test/guide-index-sync.bats
.../bats: line 18: /dev/null: Permission denied     # fix: add --dev /dev --proc /proc

# Demo A: real suite under the full profile
$ bwrap --ro-bind / / --dev /dev --proc /proc --tmpfs /tmp --bind "$SCRATCH" "$SCRATCH" \
    --unshare-net --unshare-pid --die-with-parent --setenv TMPDIR "$SCRATCH" \
    --chdir "$WT" -- bats test/guide-index-sync.bats
1..1
ok 1 every guide in guides/ is linked from guides/README.md

# Demo B: hostile fixture under the same profile — all denials hold
$ bwrap <same profile> -- bats "$SCRATCH/hostile.bats"
1..3
ok 1 curl to allowed host fails under confinement
ok 2 raw socket egress fails under confinement
ok 3 write outside scratch fails under confinement
$ ls /home/magfrump/HOSTILE_ESCAPE
ls: cannot access '/home/magfrump/HOSTILE_ESCAPE': No such file or directory

# Depth and overhead
$ bwrap ... -- bwrap --ro-bind / / --dev /dev --proc /proc --unshare-net -- true
exit=0                                              # triple nesting works
$ time bats test/guide-index-sync.bats              # bare:     0.128s
$ time bwrap <profile> -- bats test/guide-index-sync.bats   # confined: 0.133s
```
