# DD: Make test-hermeticity enforcement applicable across all projects and languages

- **Goal**: Decide how to extend hermeticity enforcement — today a bash/BATS-only static lint that lives inside this repo — so it applies to any project and to Python, Rust, TypeScript, and other test suites, adoptable gradually.
- **Project state**: claude-workflows main · extends decision 014 (layers 2 and 3) and composes with 015/016 (devcontainer + egress firewall) · not blocked
- **Task status**: complete (decision → `docs/decisions/017-polyglot-test-hermeticity.md`; increment 1 = scope C implemented)

## Step 5 — Outcome, and the hypothesis that was partially falsified

Decision recorded: **017**. User selected scope **C** (CLI + bash + Python adapters + the CI netns runner).

**The step-4 hypothesis for the chosen candidate was:** *"the Python adapter lands as a data file +
fixtures with **zero edits to the core closure engine**. Counter-evidence: Python's import-resolution forces
a change to the core, which would falsify the rules-as-data premise (H1)."*

**Counter-evidence was observed. H1 is partially falsified, and the record must say so.**

- The **matcher** generalized exactly as predicted. A single `spawn_call` proximity matcher (walk from the
  spawn token to its matching close paren; look for the binary in that window) covers
  `subprocess.run(["curl"])`, `Command::new("curl")`, `exec.Command("curl")` and
  `child_process.spawn("curl")` without modification. Adding Rust/Go/TS will not touch it.
- The **closure resolver** did not. Python module resolution (dotted name → path, relative-import handling,
  don't-follow-third-party) needed a second resolver implementation in the core alongside bash's
  `basename_in_dirs`. And the research says Rust and Go will each need their own too: Rust must follow
  `mod`/`include!` but never `use`; a Go `_test.go` file implicitly sees its whole package *directory* with
  no import statement at all.

**Revised claim, which is what the docs now say:** adding a language is *a data file, plus sometimes a
~20-line resolver.* That is weaker than the pitch, and it is the honest version. 017's revisit triggers
carry the consequence: **if a fourth language needs a third resolver, the rules-as-data contract is not
paying for itself and should collapse into a single AST engine** (pruned candidate [7]).

Two bugs found during implementation, both worth recording because they are the same bug twice: the
original rule's regexes were written for `grep`, which is **line-scoped**, and Python's `re` is not. Ported
verbatim, `$` silently meant end-of-file and negated classes spanned newlines — which made (a) stub
detection fail on 8 of 9 real suites, and (b) a bare `# @network: allowed` with no reason *pass*, by
matching a "reason" from the following line. Both were caught by the ported fixtures. A port that had only
been checked against "does the repo still go green" would have shipped the second one.

## Framing: the ask hides two orthogonal axes

The request — "applicable across all projects; this means applicable to tests other than BATS" — treats
cross-project reach and cross-language detection as the same thing. They are not, and separating them is
most of the decision:

- **Axis A — cross-project reach.** The lint is `test/fixture-hermeticity.bats`: a *bats test* that globs
  `$REPO_ROOT/test/*.bats`. It cannot lint another repo no matter how many languages it understands. Any
  fix must change *where the checker lives and how it is invoked* (this repo symlinks content into
  `~/.claude/`; security hooks are deployed as copies, per 014's copy-not-symlink rule).
- **Axis B — cross-language detection.** The current rule is defined in shell terms: a "call site" is a
  *network-capable binary in command position*, and hermeticity is a *PATH shim stubbing that binary*.
  Neither concept survives translation. In Python the reach is `requests.get()`, not a binary in command
  position; hermeticity is `monkeypatch` / `responses.activate` / `mock.patch`. In Rust it is `reqwest`;
  in TS, `fetch`. Every language needs a new call-site grammar *and* a new stub-recognition grammar.

A candidate can solve A without B (deploy the bash lint everywhere) or B without A (teach the in-repo bats
suite to read `.py` files). Only some candidates solve both. The matrix in step 3 scores them separately.

## The threat model is what discriminates (carried from 014)

The incident the lint exists to prevent (commit 4d39475) was **indirect**: a bats suite sourced
`self-improvement.sh`, which invoked a live `claude -p`. The reach was transitive, through a *subprocess*,
and the suite's own text contained no call site.

This is the load-bearing fact for language generalization. The Python-shaped version of 4d39475 is a test
that imports a module that calls `subprocess.run(["curl", ...])` — or a library that shells out. So the
threat model is **transitive reach including through child processes**, which is inherently a
*process-tree* property, not a language property. Any enforcement that lives at the language layer
(pytest-socket patches Python's `socket`; nock patches Node's http) is blind to a subprocess by
construction — it is defeated by exactly the incident class this lint was built for. Enforcement at the
kernel/process layer (a network namespace) is not: a netns is inherited by every descendant.

Pending confirmation from the ecosystem research (see step 2, C4), this asymmetry likely decides the
decision.

## Prior pruning grep (step 1.0)

`grep -B1 -A20 "Pruned candidates" docs/decisions/*.md | rg -i "lint|hermetic|test|network|stub|polyglot|language"`

Two prior records surfaced pruned candidates in this area; both are **carried forward**:

- `[8 skill]` from **014**: *"skills trigger on intent, not tool failure."* Carried — it prunes any candidate
  whose enforcement is a skill the agent must *choose* to invoke. Note the scope: 014 pruned a skill as the
  delivery vehicle for a *tool-denial hint*. A skill as an *advisory reviewer* is a different use and is
  re-proposed below as [8], flagged for the same objection (advisory ≠ gate).
- `[15 nested per-command sandboxes]` from **014**: pruned for *"WSL2 nested-bwrap fragility + widens
  surface."* **REVIVED.** Why this time is different: the layer-3 spike
  (`docs/working/spike-nested-bwrap-fixture-confinement.md`, 2026-07-09) ran the probe and returned an
  *unambiguous go* — the predicted WSL2 fragility did not materialize (bubblewrap 0.6.1, nesting depth ≥3
  works, network denial kernel-enforced, ~5 ms overhead, a real suite passes under the profile). 014's own
  revisit trigger fired on exactly this: *"if the spike shows nested bwrap works on WSL2 → open an RPI for
  per-suite confinement (and reconsider pruned candidate 15)."* The surface-widening objection applied to
  using bwrap to *re-allowlist* commands; using it to *remove* capability is the opposite direction and does
  not inherit that objection.

## Step 1 — Diverge (14 candidates)

Lenses represented: technical (1,2,3,7), interface (3,14), procedural (8,9,10,11), reframe (6,12,13),
time-shifted (14). Candidate 0 is the status quo.

| # | Candidate | One line |
|---|-----------|----------|
| 0 | **Status quo** | Keep the bats-only, in-repo lint; do nothing. (baseline) |
| 1 | **Grep table per language, still a bats suite** | Add per-extension call-site/stub regexes to the existing suite; scan `test/*.py`, `*.rs`, `*.ts` alongside `*.bats`. Minimal change. |
| 2 | **Extract to a standalone polyglot CLI** | Lift the lint out of bats into `hermeticity-lint` deployed to `~/.claude/scripts/`; any project invokes it on its test dir. The bats suite becomes a thin caller. |
| 3 | **Declarative per-language rules file** | As [2], but each language is a *data file* (call-site patterns, stub patterns, opt-out annotation) — adding a language means adding YAML, not code. "Gradual" is native. |
| 4 | **Runtime confinement runner (generalize 014 layer 3)** | `confine-tests <any test command>` runs bats/pytest/cargo/vitest under the spike's proven bwrap `--unshare-net` profile. Language-agnostic by construction; no grammar at all. |
| 5 | **Hybrid: confinement enforces, static lint diagnoses** | [4] is the gate; a best-effort per-language static lint stays as a *fast, portable, advisory* diagnostic that names the offending call site and the stub to write. |
| 6 | **Lean on ecosystem-native blockers** | Don't write detection: require `pytest --disable-socket` (pytest-socket), nock `disableNetConnect`, msw, etc. The "linter" degenerates into a *config* check that the project enabled its ecosystem's blocker. |
| 7 | **AST-based detection (tree-sitter / ruff-style)** | Real parsing per language instead of grep: accurate call sites, accurate stub recognition, real import-graph closure. Ideal if effort were free. |
| 8 | **Ship as a Claude Code skill** | A `test-hermeticity` skill that triggers when tests are written/reviewed; the agent applies the rule with judgment in any language, today, with no grammar. Advisory. |
| 9 | **Fold into `code-review` as a sub-critic** | `code-review` already runs in every project and already dispatches security/ui sub-critics. Zero new distribution surface. Advisory, PR-time. |
| 10 | **PostToolUse hook on test-file writes** | Hooks are already global across projects. Fire on Write/Edit to a test path; warn when a network call site is added without a stub. |
| 11 | **Publish as a `pre-commit` hook** | `pre-commit` is the existing polyglot, cross-project distribution channel (standard in Python/JS/Rust repos). Distribution solved by someone else's ecosystem. |
| 12 | **Hermetic build system (Bazel/Buck)** | Adopt a build system that sandboxes every test action and enforces hermeticity by construction. Space-widener. |
| 13 | **Deny egress in the devcontainer test step** | 015/016 already ship a central devcontainer + ipset egress firewall. Run the test step with egress denied; reuse shipped infrastructure rather than new machinery. |
| 14 | **Defer: write the spec, implement on first real need** | This repo has *zero* Python/Rust/TS test suites. Publish the rule + annotation convention now; build a language adapter the first time a project actually has that language. YAGNI. |

### Generation health check

- **Clustering**: [1][2][3][7] all cluster on *static text detection* — four variants of the same
  assumption (that we detect reach by reading code). Named the shared assumption and deliberately populated
  the non-static region: [4][5][6][10][13] enforce or observe at other layers. Cluster is acknowledged, not
  removed.
- **Dimensional anchoring**: checked. Candidates move on three distinct dimensions, not one —
  *enforcement layer* (static text / language runtime / kernel netns / network egress / build system),
  *distribution mechanism* (in-repo bats test / `~/.claude` CLI / skill / hook / pre-commit / devcontainer),
  and *detection method* (grep / AST / config-presence / LLM judgment / none-needed).
- **Missing perspectives**: do-nothing [0] present; minimal-change [1] present; ideal-if-free [7][12]
  present; naive/unconventional [6][8][12][13] present.
- **Vagueness**: each candidate names a specific mechanism testable against the step-2 constraints.

## Step 2 — Diagnose (constraints)

### Hard

- **H1 — Adding language N+1 must not require re-architecting.**
  `success:` adding one new language is demonstrated by a diff that touches only an adapter/data file (or
  touches *nothing*, for layer-agnostic candidates) — not the core checker. Verified by actually adding a
  second language and measuring the diff's file set.
- **H2 — Must be invocable from a repo unrelated to claude-workflows.**
  `success:` from a scratch git repo with no symlink into this one, a single documented command runs the
  check and exits nonzero on a planted violating fixture and zero on a hermetic one.
- **H3 — Must not expand the security surface (inherited from 014 H1).**
  `success:` no new entry in `permissions.allow` capable of arbitrary execution; any policy/manifest/opt-out
  the checker *trusts* is read from a deployed copy, never from the agent-writable repo under test
  (014's copy-not-symlink rule; spike pre-mortem narrative 2).
- **H4 — Gradual/partial adoption must be first-class (the user's explicit ask).**
  `success:` a project with only bash coverage still exits 0; a language with no adapter yet is reported as
  `unchecked: <lang> (no adapter)` on stderr with exit 0, never as a failure — and never as a silent pass.
- **H5 — Must degrade loudly, never silently pass.**
  `success:` when the checker cannot enforce (bwrap absent, language unknown, profile fails to launch), it
  emits a distinguishable exit code and a banner naming what went unenforced. The 4d39475 incident *was* a
  silent live call; a silently-degrading guard reproduces it. (Spike pre-mortem narrative 1.)
- **H6 — Non-interactive.** Runs in the SI loop, `/away` batches, and CI.
  `success:` completes with stdin closed and never issues a prompt.
- **H7 — Must catch transitive reach through child processes.** The actual 4d39475 failure mode; see the
  threat-model section above.
  `success:` a fixture whose test imports/sources a helper that *subprocesses* `curl` is caught. A checker
  that only patches in-process library calls fails this outright.

### Soft

- **S1 — Portable off this host.** bwrap is Linux-only; macOS laptops and some CI runners have no userns.
  A candidate that *only* works here is not "applicable across all projects."
- **S2 — Fast enough for the `fast` test category / pre-commit** (<2 s on this repo's suite set).
- **S3 — Zero false positives on the 13 existing bats suites** (the lint is green today; a port that
  reddens it will be disabled by the first person it annoys).
- **S4 — No new mandatory dependency per project** (pre-commit, Bazel, a language toolchain).
- **S5 — Reuse shipped infrastructure** (the 015/016 devcontainer + firewall; the spike's proven profile)
  rather than standing up new machinery.

## Interlude — two probes run during diagnosis, both [observed], both decisive

### P1. The layer-3 spike is STALE. Its primitive no longer exists.

`docs/working/spike-nested-bwrap-fixture-confinement.md` (Last verified: 2026-07-09) returned an
"unambiguous go" for bwrap confinement and recommended *"Proceed to RPI."* Re-probed today, in the
environment where the agent actually runs tests:

| | spike, 2026-07-09 | now, 2026-07-13 |
|---|---|---|
| `bwrap` | present (0.6.1) | **ABSENT** |
| `unshare -rn true` | exit 0 | **EPERM** (seccomp blocks `CLONE_NEWUSER`) |
| `max_user_namespaces` | 2147483647 | 96083 (but userns creation denied) |
| `uid_map` | `1000 1000 1` (bwrap sandbox) | `0 0 4294967295` (Docker init userns) |
| `CapEff` | — | **`0000000000000000`** (zero effective capabilities) |
| `iptables -L` | — | Permission denied |
| `/.dockerenv` | — | present; pid 1 = `sh` |

**Cause:** decisions 015/016 moved sessions out of the bwrap sandbox and into the `cc-isolated`
Docker devcontainer. The spike measured the *old* boundary. This is precisely its own pre-mortem
narrative 1 — *"Platform pulls the rug… the harness gets bypassed instead of fixed"* — and it fired
within four days, before anything was even built.

**Consequence for this DD:** candidates [4] and [5] cannot be self-applied by the agent, in the
environment that matters most. Confinement is still achievable *at the container boundary from the
host* (`docker run --network=none` for a test step) — but the in-container agent has no `docker` CLI,
no socket, and no capabilities, so it cannot invoke it. Runtime confinement is therefore **host-side
or CI-side infrastructure, not something this repo can ship as a runnable script.**

**Independent of this DD**, the spike's `Task status`/recommendation and 014's revisit trigger
(*"if the spike shows nested bwrap works on WSL2 → open an RPI"*) are now misleading and must be
corrected, or someone will build on sand.

Also observed: egress from a test *is live today* — a probe `curl https://github.com` inside the
session returned `200`. The devcontainer's ipset allowlist bounds the blast radius but certainly
permits `api.anthropic.com` (the agent needs it), so the exact 4d39475 incident class — a test making
a real, billable `claude -p` call — is **fully unmitigated at runtime right now**.

### P2. Language-layer blockers are blind to the actual incident class. [observed]

pytest-socket and friends patch the *language's* socket/http layer. The 4d39475 incident was a
*subprocess* reach. Probe:

```
in-process socket():   blocked  <-- blocker works
subprocess curl:       REACHED (HTTP 200)  <-- BLOCKER IS BLIND TO THIS
```

A child process has its own libc and makes its own syscalls; an in-process monkeypatch cannot see it.
So candidate [6] (lean on ecosystem-native blockers) **fails H7 outright** — it does not defend against
the one incident class that motivated the lint's existence. It defends against a *different*, easier
class (a test that forgot to mock `requests`).

### What P1 + P2 jointly imply

| Mechanism | Catches transitive subprocess reach (H7)? | Available in the agent's session (H2)? |
|---|---|---|
| Ecosystem blockers [6] | **No** (P2) | yes |
| Kernel netns [4][5] | Yes | **No** (P1) |
| Static closure lint [1][2][3][7] | Yes — over-approximating, by design | yes |

The static lint is the **only** mechanism that covers the real incident class in the environment where
the incident actually happened. That is not an aesthetic preference; it is the intersection of two
independently-observed constraints. It also inverts the intuition I started with (that runtime
confinement would dominate because it is language-agnostic) — language-agnosticism is worthless if the
primitive is unavailable where you need it.

## Interlude 2 — the ecosystem research collapses the scope (this is the design)

The Python research (full report in session; key points below) changes *what the linter should try to do*,
and it makes the polyglot port far smaller than the original ask implies.

**Finding A — the maintainer confirms P2.** pytest-socket issue
[#401](https://github.com/miketheman/pytest-socket/issues/401), filed by the maintainer:
*"When running a `subprocess()` command in the context of a test case, the settings are not carried over
into the subprocess, as it has its own execution context"* — and blocking non-Python commands such as
**`curl` is explicitly called impractical**. Every Python deny-tool is a Python-namespace monkeypatch
(`socket.socket`, `socket.getaddrinfo`, `socket.socket.connect`). None survives a `fork`/`exec`.

**Finding B — no kernel-level plugin exists.** The report searched and found no `pytest-no-network`-style
plugin doing netns/seccomp. Its conclusion: *"the only true all-egress denial is outside pytest —
`unshare -n`, `docker run --network=none`, a CI firewall, or your own devcontainer boundary."* Which, per
P1, the agent cannot reach.

**Finding C — statically detecting *mocks* is a false-positive swamp.** To conclude "this Python suite is
hermetic," a linter would have to resolve: `mock.patch("dotted.string.target")` (the target is a *string* —
a typo'd target patches nothing and the test still hits the network, but the linter says "stubbed");
`conftest.py` inheritance and directory scoping (a nested `conftest` calling `enable_socket()` re-opens the
network for that subtree only); module-level `pytestmark`; fixtures supplied by a shared package or a
`pytest11` entry-point plugin (a suite can be *fully hermetic with zero stub syntax in the file*); and
`@pytest.mark.vcr`, which in its **default** `record_mode=once` *records from the live network* when the
cassette is missing — so treating a VCR-marked test as hermetic is actively wrong.

### The scope collapse

Findings A–C separate cleanly by *who already covers what*:

| Reach surface | Who covers it well | Should the lint detect it? |
|---|---|---|
| **In-process HTTP** (`requests`, `httpx`, `fetch`, `reqwest`) | ecosystem runtime blockers — pytest-socket, nock `disableNetConnect`, msw. They cover this **well**. | **No.** Statically recognizing the *mocks* is Finding C's swamp. Instead: grep the *config* for a baseline blocker (`addopts = --disable-socket`). One line, "the single strongest hermeticity signal" (report). |
| **Subprocess → network binary** (`subprocess.run(["curl"])`) | **nobody.** Unblockable at the language layer (Finding A); unblockable at the kernel layer in-session (P1). | **Yes — this is the lint's job, and its whole job.** |
| **C-extension egress** (psycopg2, grpc, pycurl) | nobody (bypasses the Python `socket` namespace too) | out of scope; note as a known gap. |

**This is the key result.** The rule we already have for bash — *"can this suite invoke a network-capable
binary, transitively?"* — is **exactly the rule that no other tool covers, in any language.** It ports 1:1.
And it needs only a small, bounded per-language grammar: *how does this language spawn a process*
(`subprocess.run`/`Popen`/`os.system`; `std::process::Command`; `child_process.exec`; `exec.Command`) — a
list of ~8 literal tokens per language. It does **not** need an HTTP-library taxonomy or a mock-recognition
engine, which is where a naive port would have drowned.

So the polyglot lint is *smaller* than the bash one conceptually, not bigger. That inverts the premise of
the original request.

**Annotation grammar (Finding D).** Don't invent Python syntax. The report finds no ecosystem-wide standard
but two real conventions: `@pytest.mark.remote_data` (pytest-remotedata — uniquely *enforcing*, dominant in
scientific Python) and `@pytest.mark.network` (purely declarative, but the de-facto ad-hoc standard — used
by **pandas** and adopted by **poetry** via poetry#8288). Honor native markers where they exist, and keep
the existing `# @network: allowed — <reason>` comment as the **universal fallback**, since no marker
convention carries a free-text reason and none of them covers the subprocess case at all.

## Step 3 — Match and prune

Key: ✓ addresses · ~ partial/uncertain · ✗ doesn't address · ⚠ actively makes worse

| # | Candidate | H1 N+1 lang | H2 cross-project | H3 no surface | H4 gradual | H5 loud | H6 non-interactive | H7 subprocess reach | Verdict |
|---|-----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|---------|
| 0 | Status quo | ✗ | ✗ | ✓ | ✗ | ✓ | ✓ | ✓ | **cut** — is the thing being fixed |
| 1 | Grep table, still a bats suite | ~ | ✗ | ✓ | ~ | ✓ | ✓ | ~ | **cut** — H2 is structural: a bats test in *this* repo cannot lint another repo |
| 2 | Standalone polyglot CLI | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | **survives** |
| 3 | CLI + declarative per-language rules | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | **survives** (= [2] with the adapter as data) |
| 4 | bwrap `confine-tests` | ✓ | ✗ (P1) | ✓ | ✓ | ⚠ | ✓ | ✓ | **cut as in-session gate** — primitive absent; ⚠ H5: would silently not-enforce. Survives only as host/CI infra → folded into [13] |
| 5 | Hybrid: confine + diagnose | ✓ | ~ | ✓ | ✓ | ⚠ | ✓ | ✓ | **collapses** — enforcement half dies with [4]; diagnostic half *is* [3] |
| 6 | Ecosystem-native blockers | ~ | ✓ | ✓ | ✓ | ~ | ✓ | **✗ (P2)** | **cut on H7** — blind to the incident class. Retained as a *complementary* recommendation, not the mechanism |
| 7 | AST / tree-sitter | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **survives** — strictly better detection than [3], much higher cost |
| 8 | Claude Code skill | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | **cut on H5** — advisory, not a gate [carried from 014: *"skills trigger on intent"*] |
| 9 | `code-review` sub-critic | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | **cut as the gate** (H5) — but **adopted as a complement**: it is the only candidate with cross-project reach *today*, at zero cost |
| 10 | PostToolUse hook | ~ | ✓ | ~ | ✓ | ✗ | ✓ | ~ | **cut** — hook sprawl (014 pruned an adjacent hook); warns after the fact, gates nothing |
| 11 | pre-commit hook | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | **survives** — a *distribution channel* for [3], not a rival detector |
| 12 | Bazel / Buck | ✓ | ~ | ✓ | ✗ | ✓ | ✓ | ✓ | **cut on H4** — a build-system migration is the opposite of gradual |
| 13 | Devcontainer / CI egress-deny | ✓ | ~ | ✓ | ✓ | ~ | ✓ | ✓ | **survives** — the surviving form of [4]; host-side, coarse, but reuses 015/016 (S5) |
| 14 | Defer / spec-only | n/a | n/a | ✓ | ✓ | ✓ | ✓ | n/a | **survives** — the honest baseline: this repo has zero Python/Rust/TS *test suites* |

**Survivors into step 4: [3], [7], [11], [13], [14]** — with [9] adopted as a complement regardless of
which wins, and [2] absorbed into [3].

### Fix sketches for survivors

- **[3]** — its one weakness is H7 (`~`): grep-based closure across *imports* is weaker than across shell
  `source`. Fix: keep today's deliberate over-approximation (if an imported module contains a call site,
  the suite is flagged), which trades false positives for zero false negatives. False positives are cheap
  because the annotation opt-out already exists.
- **[7]** — the cost. Fix: AST is not an alternative to [3] but its *upgrade path* for a language where
  grep proves too noisy; the adapter interface in [3] must not preclude an AST-backed adapter.
- **[13]** — cannot be self-applied by the agent, and it is coarse. Fix: scope it to CI, and require a
  **preflight probe** that fails loudly when the confinement primitive is missing (P1 is exactly the
  bypass-instead-of-fix failure the spike's pre-mortem predicted).
- **[14]** — risks the rule rotting. Fix: publish the *convention* (annotation grammar + rule statement)
  now even if adapters land later; that is the part other projects need in order to be gradually adopted.

## Interlude 3 — Rust + Go research: the convergence is unanimous

Three independent ecosystem reports (Python, Rust, Go) reach the same three conclusions. The unanimity is
itself the finding — this is not a Python quirk, it is a property of the problem.

**1. No language has an in-process all-egress blocker, and the reason is structural.**

| | interposition point | verdict |
|---|---|---|
| Python | `socket.socket` is a mutable module attribute → monkeypatchable | pytest-socket exists, but misses subprocess + C-extension egress |
| Rust | `std::net` compiles to direct libc/syscall calls; no global indirection | **nothing exists.** cap-std is opt-in DI, not interception ("*not a sandbox for untrusted Rust code*"). mockito/wiremock/httpmock all start **real loopback servers** — they make tests loopback-only, not network-denied |
| Go | `net.Dial` is a plain function, not a variable; runtime issues raw `SYSCALL` | **nothing exists.** And `LD_PRELOAD` is *structurally dead*: pure-Go binaries are statically linked and bypass libc entirely (the same reason proxychains doesn't work on Go) |

**2. The only true denial is out-of-process — netns or container.** All three reports converge here
independently. Prior art: **rust-lang/crater** blocks external network for builds/tests
([PR #336](https://github.com/rust-lang/crater/pull/336)); **Maelstrom** runs every Rust test in a rootless
container with `network: Disabled` by default; Bazel has `--sandbox_default_allow_network=false`. The Go
recipe is exact: `unshare -rn sh -c 'ip link set lo up; go test ./...'` (a fresh netns starts with loopback
**down**, so it must be raised or `httptest` suites break).

**3. Statically proving *hermeticity* is undecidable in practice — and this is the trap a naive port falls
into.** The mock call site is byte-identical to the real one:

> *"the literal AST node the linter sees is the same whether `url` is `server.url()` or
> `"https://api.stripe.com"`. The URL is the only signal, and it is virtually always a runtime value…
> Deciding hermeticity therefore requires interprocedural dataflow across crate boundaries. That is not a
> linter; that's an abstract interpreter."* — Rust report

Its design verdict: *"Do not ship a binary hermetic/not-hermetic verdict… ship three states —
`HERMETIC`/`NETWORKED`/`UNKNOWN` — and expect UNKNOWN to be the plurality."* The Go report agrees: *"static
analysis cannot prove hermeticity; it can only produce a ranked suspicion list."*

**Why this vindicates the scope collapse.** Our rule never asks "is this hermetic?" It asks the narrow,
decidable question *"does this spawn a network-capable binary?"* — which sidesteps the dataflow problem
entirely, is **high-precision in every language**, and is the one class no runtime tool covers anywhere.
The Rust report independently identifies `Command::new("curl"|"git"|"gh"|"aws"|…)` as *"the most-missed
surface… high precision, easy to detect"*; the Go report lists `exec.Command("curl"|…)` and notes it is
*"the same shell-out escape hatch as your BATS linter — worth a shared allow/deny binary list across
languages."* That shared binary list already exists: `NETWORK_BINS`.

**4. Adopt-where-possible (the tooling-discovery gate).** No polyglot hermeticity linter exists. But for
**Go**, `golangci-lint`'s `depguard` (has a native `$test` file selector) + `forbidigo`
(`analyze-types: true`, regex on call expressions) can be **configured** into most of this rule with *zero
new code*. Recommendation: for Go, ship a **config recipe, not an adapter**. Prior art to crib for a future
AST upgrade: `sonatard/noctx` already implements the `net/http` call-site matrix on `go/analysis`+SSA.

**5. An anti-pattern worth its own rule (from the Rust report).** The hand-rolled skip —
`if std::env::var("RUN_NETWORK_TESTS").is_err() { return; }` — reports **PASS** when skipped, silently
green-washing. Same shape in Go (`if os.Getenv("INTEGRATION")=="" { t.Skip() }` is fine; a bare `return` is
not). Flag "network test that silently returns green when disabled" — it is the 4d39475 lesson (*silent* is
the enemy) in a new costume, and it maps directly to **H5**.

### Native opt-out annotations to honor (never invent syntax where a convention exists)

| lang | native "needs network" marker | strength |
|---|---|---|
| Python | `@pytest.mark.remote_data` (pytest-remotedata — uniquely *enforcing*); `@pytest.mark.network` (declarative; **pandas**, **poetry**) | good |
| Go | `//go:build integration` build tag (compile-time, machine-checkable); `testing.Short()` secondary | **strongest** |
| Rust | `#[ignore = "<reason>"]` (weak — overloaded with slow/flaky/needs-docker); env-gate à la cargo's `CARGO_PUBLIC_NETWORK_TESTS`; nextest `default-filter` (most linter-friendly) | weak/fragmented |
| bash/bats | `# @network: allowed — <reason>` (ours) | n/a |

Universal fallback stays `# @network: allowed — <reason>` (or the language's comment syntax), because **no
native convention carries a free-text reason, and none of them covers the subprocess case at all.**

## Step 4 — Tradeoff matrix and decision

The *mechanism* is now settled by evidence, not preference:

> **A standalone, polyglot, static CLI whose single rule is transitive subprocess-reach to a
> network-capable binary; per-language support is a rules *data file* (spawn grammar + import grammar +
> stub recognition + native opt-out), so "gradual" means dropping in a file rather than editing the core.
> Host language: `python3` (the only viable host — no semgrep/ast-grep/ruff in the environment). It emits
> the `unshare -n` / `--network=none` command as the ground-truth check rather than pretending to be
> sufficient.**

What remains genuinely open is **the scope of increment 1**. Four variants:

| # | Scope of increment 1 | Effort | Risk | Coverage (7 hard) | Key downside |
|---|---|---|---|---|---|
| **A** | Extract to CLI + **bash** adapter + **Python** adapter | ~5 h | low | 7/7 | Python adapter is speculative — repo has zero pytest suites |
| **B** | Extract to CLI + **bash** adapter only | ~2.5 h | low | 6/7 (H1 unproven) | H1 ("adding lang N+1 is just a data file") stays a *claim*, untested |
| **C** | A **+ the CI netns runner** (`unshare -n` ground truth) | ~9 h | med | 7/7 + real enforcement | Touches CI; per P1 the runner cannot work in-session, only in CI |
| **D** | Full polyglot now: bash + Python + TS + Rust + Go | ~2 d | med-high | 7/7 | Speculative generality ×5; Go should be a *config recipe*, not an adapter (see §4 above) |

### Falsifiable hypotheses

- **A** — *If chosen, the Python adapter lands as a data file + fixtures with **zero edits to the core
  closure engine**, and the 13 existing bats suites stay green. Counter-evidence: Python's import-resolution
  forces a change to the core, which would falsify the rules-as-data premise (H1) and mean we actually have
  [7]/AST on our hands.*
- **B** — *If chosen, the lint runs from an unrelated repo within one session. Counter-evidence: the CLI
  still needs claude-workflows-specific paths, i.e. H2 was never really about languages.*
- **C** — *If chosen, running today's suite under `unshare -n` in CI turns a live-`claude` suite red — the
  4d39475 catch, reproduced. Counter-evidence: the CI runner also lacks userns, and the runner silently
  degrades to unconfined (which is H5's exact failure and the spike's pre-mortem narrative 1, again).*
- **D** — *If chosen, five adapters land with zero core changes. Counter-evidence: Rust/Go push us to AST
  and blow the grep-only budget.*

### Stress-test pass

- **Boring alternative** (applied to D, and to the original request): the boring version of "make it
  polyglot" is *one narrow rule + a data file*, not a detection engine. The three research reports say a
  detection engine is undecidable anyway. **This move is what produced the scope collapse** and demoted D.
- **Invert the thesis** (applied to A): argue for B. The repo has **zero** Python/Rust/TS test suites — the
  Python adapter is, strictly, speculative generality, and CLAUDE.md's own bar would push back on it. What
  survives the inversion: H1 is the *whole point* of the user's ask ("applicable to other languages"), and
  an adapter contract with exactly one implementation has never been tested. A second adapter is the
  cheapest possible proof that the contract is real. **A survives, but narrowly, and only because H1 is
  load-bearing.**
- **Failure-driven** (applied to C): the runner's new failure mode is *silent non-enforcement* — exactly
  P1, exactly the spike's narrative 1, which has now demonstrably fired once. Mitigation is mandatory, not
  optional: a preflight probe that **exits nonzero and loudly** when the confinement primitive is missing,
  never a warning-and-continue. (Recorded as a stress-test mitigation.)
- **Organizational survival** (applied across): the lint is a convention; conventions rot. The thing that
  survives turnover is the *annotation grammar* + the one-line rule statement, not the implementation. Both
  A and B must ship that doc; D's five adapters do not make it more durable.
- **Push to extreme** (applied to the rule): at the limit, "spawns a network binary" misses a test that
  spawns `python3 -c "import requests; requests.get(...)"`. Accepted gap — the binary list can grow
  (`python3`/`node` with a `-c`/`-e` flag is a detectable shape), and the netns runner is the backstop. The
  lint is triage; the runner is ground truth. This is stated in the docs rather than papered over.
