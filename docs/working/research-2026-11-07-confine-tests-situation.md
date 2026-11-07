# Research: what `scripts/confine-tests.sh` needs, and where it can run today

- **Brief**: `docs/working/briefs/2026-11-07-confine-tests-situation.md` (self-merge, docs only)
- **Date**: 2026-11-07 · **Branch**: `docs/confine-tests-situation` from f93c043c
- **Sources read**: `scripts/confine-tests.sh`, `docs/decisions/017-polyglot-test-hermeticity.md`,
  `guides/test-hermeticity.md`, `docs/reviews/review-fix-loop-polyglot-test-hermeticity.md`,
  the Q-125 branch `feat/q125-cc-isolated-sandbox` (Dockerfile, devcontainer.json,
  seccomp profile, managed settings, plan), Q-126/Q-161/Q-263 entries, cycle records,
  the archive spike `archive/docs/2026-08-06-spike-nested-bwrap-fixture-confinement.md`.

Failure-pattern grep: FP-050, FP-052, FP-058, FP-076

The grep was `rg -in -e 'confine|hermetic|netns|unshare|bwrap|namespace|landlock' docs/failure-patterns.md`.
FP-050 (an `unshare` tier shares the host mount namespace, so writes land on the host) is
the same trade `confine-tests.sh` already documents for its `unshare` path.
FP-058 (a bwrap failure at runtime dropped the work without a word) is the fail-open
pattern the script's exit 3 exists to prevent. FP-052 (a too-broad write block crashed a
font cache) predicts the main risk once the bwrap path can run (see Q2, place 2). FP-076 is
about a headless read limited to the working directory and does not apply here.

## Q1. What it needs, and how it fails here

The script takes the first primitive that works, in this order:
`bwrap --ro-bind / / --unshare-net -- true`, then `unshare -rn true`. With either
`--probe` or a real command it exits 3 when neither works. It never runs tests unconfined.
The `unshare` path also needs `ip` (iproute2) to bring `lo` up.

Run here on 2026-11-07, in this worktree, under `timeout 30`, with output sent to a file:

| Command | Exit | First error lines |
|---|---|---|
| `scripts/confine-tests.sh --probe` | 3 | `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.` / `Your tests were NOT run.` |
| `scripts/confine-tests.sh -- true` | 3 | same message: the refusal comes before any command runs |
| `unshare -rn true` | 1 | `unshare: unshare failed: Operation not permitted` |
| `unshare -n true` / `unshare -r true` | 1 | same EPERM: both the user and the net namespace are refused |
| `command -v bwrap` | 1 | not installed (`unshare` and `ip` are both present, at `/usr/bin/unshare` and `/usr/sbin/ip`) |

Environment facts behind it: `CapEff: 0000000000000000`, `Seccomp: 2` with 3 filters,
uid 1000 in the initial user namespace, `/.dockerenv` present, kernel
6.18.54.1-microsoft-standard-WSL2. The Bash tool is not itself wrapped in a sandbox
(Q-125 is unmerged). This matches decision 017 finding 1 exactly: Docker's default seccomp
profile blocks `CLONE_NEWUSER` without `CAP_SYS_ADMIN`, so nothing can create a namespace.

**What is missing:** (a) a seccomp rule that lets `clone`/`unshare` create a user
namespace, and (b) for the hardened path, the `bwrap` binary. With (a) alone, the `unshare -rn`
path would work (`ip` is installed). That path denies the network but gives no read-only
rootfs and no private `/tmp`, so FP-050 applies to it.

## Q2. Where it could run

| # | Place | Works today? | What it needs | Cost to the owner | Recorded run? |
|---|---|---|---|---|---|
| 1 | This container (cc-isolated, main's image) | **No**, exit 3 (above) | the seccomp change plus bwrap, which is what place 2 is | n/a | refusals only: the 2026-11-05 q089 loop (exit 3, `cycle-2026-11-05.md` step 7), the 2026-11-06 gloss-rule loop (Q-263 "Not met"), and this run |
| 2 | A session after Q-125 merges | **Expected yes, untested** | Q-125's image: `bubblewrap` in the Dockerfile, and `seccomp-cc-sandbox.json`, which lets clone/unshare/mount/pivot_root through inside a user namespace. Q-126's host probe saw bwrap start in a container under that profile, with a fresh `/proc`. But every Bash call would then already run inside Claude Code's own bwrap, so `confine-tests.sh` becomes a **nested** bwrap. Q-125's plan (residuals table) says Claude Code passes no `--disable-userns`, so a nested user namespace should be allowed [inferred]. The 2026-07-09 spike showed nested bwrap working, but on the pre-Docker host [observed then; boundary since changed]. | Nothing new: one `scripts/confine-tests.sh --probe` line could ride along in Q-125's already-queued live run (roadmap Next 1). This is what the Q-161 watch waits for. | none |
| 3 | The owner's WSL2 host | **Probably**, unverified | Q-126 recorded "no LSM" on that kernel, so the AppArmor block on unprivileged user namespaces should not apply and `unshare -rn` likely works. Whether bwrap is on the host is unknown: the probe installed it inside throwaway containers. It also needs a checkout of the branch plus the suite's tools (bats, python3 and the rest) on the host. | One paste per verification. A one-off baseline run is within S10. Requiring it per merge would be a new recurring host chore, which S10 rules out. | none |
| 4 | CI | **No CI exists** | the repo has no `.github/workflows`, and the owner's practice is local merge only, with no push (memory: no GitHub routing). GitHub's ubuntu-24.04 runners are also reported to restrict unprivileged user namespaces through AppArmor [web knowledge, unverified here: no egress to check]. | setting up a remote and CI would reverse a standing practice | none |
| 5 | This container, with a different kernel primitive (Landlock) | **Partly, today** (see below) | a change to `confine-tests.sh` and an amendment to decision 017, both out of this brief's scope | none: no host step | the probe below is the first |

**No recorded run exists of `scripts/confine-tests.sh` with a primitive available.** I
searched `docs/working/cycles/`, `docs/working/questions-archive.md`, `docs/reviews/`
(including `execution-logs/`) and `archive/docs/` for `confine-tests`, and the whole repo
for its success banners (`denying network via`, `primitive available:`). The banners occur
only in the script itself. `docs/reviews/review-fix-loop-polyglot-test-hermeticity.md`
weak seams (2) and (3) say the bwrap paths "have never been executed" and that the script
"ships with no automated test at all". `cycle-2026-10-20.md` records "no `confine-tests.sh`
run". The execution-log hits are health-check file listings, not runs.

### Place 5: Landlock works in this container now

Decision 017 finding 1 says "the agent cannot confine its own test runs". That holds for
namespaces, but not for every kernel primitive. Landlock is a Linux kernel access-control
feature that any unprivileged process can apply to itself. Its rules carry across `exec` to
every descendant and cannot be removed. Since ABI 4 it can deny TCP `connect`. Probe run
here (stdlib python3 via `ctypes`; scripts in the session scratchpad, not committed):

- `landlock_create_ruleset(NULL, 0, VERSION)` returned **ABI 7**. Docker's default seccomp
  profile allows `landlock_*` syscalls.
- With `handled_access_net = CONNECT_TCP`, no allow rules, then `exec`:
  - a TCP connect to `127.0.0.1:53` went from OK to `PermissionError 13`;
  - one to the SNI proxy `172.17.0.3:3443` went from OK to `PermissionError 13`;
  - **a child `curl https://github.com` went from HTTP `200` to `curl: (7) Failed to connect`**.
    That `curl` is a separate binary, exec'd after the restriction, so this is the
    subprocess case decision 017 says no in-process blocker covers.
- Gaps observed or known: **UDP is not covered** (`getent hosts github.com` still resolved,
  so DNS works). Rules are by **port only**, not by address, so loopback TCP is denied too,
  and allowing a port for a fixture server allows that port everywhere. There is no
  filesystem confinement unless fs rules are added as well. Unix sockets are only partly
  covered (abstract-socket scoping since ABI 6).

This is not a drop-in replacement for the namespace. It is a third, weaker primitive that
works in-session today. TCP is the protocol every live `claude`, `gh`, `curl` or `wget`
call needs, so it would catch the 4d39475 class (a test reaching a live, billable
`claude -p`) in the agent's own session. Adding it means changing `confine-tests.sh` and
decision 017, which this brief rules out, so this doc records it as a candidate for the
cycle to weigh, not as a decision.

## Q3. Brief wording

Briefs carry this requirement inconsistently. The line "tests are hermetic and pass under
`scripts/confine-tests.sh`" appears in exactly one brief
(`briefs/closed/2026-11-06-owner-entry-gloss-rule.md`). The next brief
(`briefs/closed/2026-11-06-codify-trial-practices.md`) already says "Do not require
`scripts/confine-tests.sh`: it cannot run in this container". No template,
skill or script under `skills/`, `workflows/`, `scripts/build-loop.sh`, `scripts/dev-cycle.sh`
or `scripts/lib/` contains the line. So this is the brief writer's (the dev cycle's) wording
practice, and the choice is about which wording to use going forward.

**What the lint covers meanwhile** (`scripts/hermeticity-lint --root .`, exit 0 here:
"142 test file(s) checked, no unstubbed network spawns"): bash and python test files that
spawn `claude`, `curl`, `wget` or `gh`, directly or through a sourced repo script, without
a stub in `setup()` or a `# @network: allowed` marker. **Not covered** (decision 017, and
the lint's own output): in-process HTTP, C-extension egress, a network binary outside those
four (`nc`, `ssh`, `git fetch` from a remote URL), and indirect reach such as
`python3 -c "import requests…"`. Note also that Q-125's sandbox will not close this gap by
itself: its network allowlist admits the project's egress profile, so a test inside a
sandboxed Bash call could still reach the API host.

### Divergent design: the wording (seeded with H1-H4, S1-S11 and the brief)

| Option | Meetable today | After Q-125 | Owner cost | Constraint notes |
|---|---|---|---|---|
| **A. Keep** "pass under confine-tests" | no: every loop reports "Not met" (Q-263) | yes, if nested bwrap works | an unmeetable line in every merge entry | breaks S10 (owner reads the same noise each time); a requirement no loop can meet is "present-but-inert" in H2's sense |
| **B. Drop**, require `scripts/run-tests.sh` plus `scripts/hermeticity-lint --root .` | yes | does not upgrade itself; someone must remember to re-add the line | none | S10's "no safety that depends on remembering" cuts against it once Q-125 lands |
| **C. Replace with a conditional**: "run `scripts/confine-tests.sh --probe`; if it exits 0, tests must pass under `scripts/confine-tests.sh -- scripts/run-tests.sh`; if it exits 3, quote its first line and rely on `scripts/run-tests.sh` plus `scripts/hermeticity-lint --root .`" | yes (the probe refuses loudly and the lint covers) | upgrades itself when the primitive appears | none | H2: the gap is named in each loop's report, not hidden. Costs about a second per loop (S2). Still prose, though (S4: a script would be better, see follow-ups) |
| **D. Owner host run per merge** | yes, via the owner | yes | one paste per merge | breaks S10 (a new recurring host chore) |
| **E. Wait for a Landlock tier** in `confine-tests.sh` | no (not built) | n/a | none | out of scope here. It is a follow-up, not a wording |

D breaks a hard-edged S10 line, E is not a wording, and A is unmeetable and noisy. C costs
the same as B today (one probe line) and adds the upgrade when Q-125 lands. **Path A
(dominant option): adopt C.** No owner judgment is needed: this is the cycle's own
brief-writing practice, and C changes nothing the owner pays for.

Risk accepted with C: once the probe passes, the bwrap profile's read-only rootfs may fail
suites that write outside `$PWD` and `/tmp` (for example `~/.cache`). That is FP-052's
shape. Wording for that case: a failure caused by confinement and not by the network is a
finding to report, not a blocker. The loop names the failing tests and the write that was
refused.

Other choices, one line each:
- Where to record a host baseline: one-off and optional. Do not ask for it now, because
  place 2 is cheaper and already queued (S10).
- Whether to file anything to the owner: no. Nothing here needs taste or authority.

## Follow-ups for the cycle (not done here: out of this brief's Paths)

1. **Brief wording**: use option C's sentence in briefs whose acceptance includes tests.
2. **Q-125 live run**: add `scripts/confine-tests.sh --probe` and one
   `scripts/confine-tests.sh -- bats test/<one fast suite>` to the in-session checks. If both
   pass, this is the first recorded run and Q-161's condition is met. If the probe exits 3
   under the sandbox, the nested-bwrap inference above is refuted.
3. **Candidate roadmap item, a scripted conditional (S4)**: let `scripts/run-tests.sh` (or a
   wrapper) run the probe and confine itself when it can, so prose need not carry the
   condition.
4. **Candidate roadmap item, a Landlock tier**: a TCP-connect-deny tier in `confine-tests.sh`,
   labelled weaker than the namespace (no UDP, port-only, loopback denied), with a bats case.
   This needs a decision 017 amendment, because finding 1 is partly refuted for TCP. Revisit
   once Q-125's outcome is known: if nested bwrap works, the tier adds less.
5. `confine-tests.sh` still has no bats case (review weak seam 3). Once place 2 works, one
   hermetic case (probe exit codes with stubbed `bwrap`/`unshare` on PATH) can be written
   even without a primitive.
