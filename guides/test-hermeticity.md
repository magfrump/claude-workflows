# Test hermeticity — the rule, the stub, the opt-out

*Applies to every project and every test language. Enforced by `scripts/hermeticity-lint`
(triage) and `scripts/confine-tests.sh` (ground truth). Rationale:
[decision 017](../docs/decisions/017-polyglot-test-hermeticity.md).*

Last verified: 2026-07-13
Relevant paths: scripts/hermeticity-lint, scripts/hermeticity/adapters/, scripts/confine-tests.sh, test/hermeticity-lint.bats

## The rule

> **If a test file — or any repo-local file it transitively imports or sources — can SPAWN a
> network-capable binary (`claude`, `curl`, `wget`, `gh`), it must either stub that binary or carry an
> explicit opt-out with a reason.**

That is the whole rule. It is deliberately narrow, and the narrowness is the point.

## Why this rule and not "tests must be hermetic"

Two facts, both verified rather than assumed (017, findings 2–4):

**1. No language can block a subprocess from inside the test process.** pytest-socket, nock, MSW, gock,
`responses` — every one is an in-process monkeypatch of a language namespace, and a child process has its
own libc and makes its own syscalls. pytest-socket's maintainer says so outright
([#401](https://github.com/miketheman/pytest-socket/issues/401)): *"the settings are not carried over into
the subprocess"*, and blocking `curl` is *"impractical."* Rust and Go have no blocker at all, because
`std::net` and `net.Dial` compile to direct syscalls with no interposition point.

So the subprocess surface is the one class **nothing else covers, in any language** — and it is exactly the
class behind commit 4d39475, the incident this rule exists for: a bats suite sourced `self-improvement.sh`,
which invoked a live, billable `claude -p`.

**2. Statically *proving* hermeticity is undecidable in practice.** `client.get(url)` is byte-identical
whether `url` is a mock server's or `api.stripe.com`'s, and the URL is a runtime value threaded through a
struct field several frames away. A linter that answered "is this suite hermetic?" would be wrong most of
the time in Rust and Go.

**Therefore:** in-process HTTP (`requests`, `fetch`, `reqwest`) is **out of scope by design**. Delegate that
layer to your ecosystem's own blocker (`pytest --disable-socket`, `nock.disableNetConnect()`) — but do not
mistake it for hermeticity, because it does not see subprocesses.

## Triage vs. ground truth

| | `hermeticity-lint` | `confine-tests.sh` |
|---|---|---|
| What it is | static, portable, sub-second | a kernel network namespace |
| Catches | subprocess reach, transitively | **everything** — subprocess, C-extension, raw socket |
| Runs | anywhere, including the agent's session | CI and dev hosts **only** (see below) |
| Verdict | over-approximating triage | **ground truth** |

A green lint means *no test spawns a network binary*. It does **not** mean the suite is hermetic. The lint
prints this itself, and prints the `confine-tests.sh` command as the authoritative check.

**The runner cannot run in the agent's own session.** Decision 017, finding 1: the `cc-isolated`
devcontainer has zero effective capabilities and seccomp blocks `CLONE_NEWUSER`, so no namespace can be
created. It refuses loudly (exit 3) rather than running your tests unconfined — a guard that silently stops
guarding is worse than no guard.

## Fixing a violation

### Option 1 — stub the binary (preferred)

Put a fake earlier on `PATH`. This works in every language, and it works for child processes, which is the
whole point.

**bash / bats:**

```bash
setup() {
  mkdir -p "$BATS_TEST_TMPDIR/stub-bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$BATS_TEST_TMPDIR/stub-bin/claude"
  chmod +x "$BATS_TEST_TMPDIR/stub-bin/claude"
  PATH="$BATS_TEST_TMPDIR/stub-bin:$PATH"
}
```

**Python / pytest** — either shim `PATH`, or patch the spawn mechanism:

```python
def test_thing(monkeypatch, tmp_path):
    (tmp_path / "curl").write_text("#!/bin/sh\nexit 0\n")
    (tmp_path / "curl").chmod(0o755)
    monkeypatch.setenv("PATH", f"{tmp_path}:{os.environ['PATH']}")
```

Both halves are load-bearing, and the lint requires both: a file **named after the binary**, and `PATH`
pointed at the directory holding it. Touching `PATH` on its own stubs nothing — `env = dict(PATH=os.environ["PATH"])`
is just how you build a subprocess environment — so it does not count as a stub.

### Option 2 — opt out, with a reason

A reason is **required**. A bare annotation is rejected: 014's whole lesson is that silent, unjustified
escapes are the failure mode.

```
# @network: allowed — exercises the real gh CLI against a fixture remote
```

Put it near the top of the file (first 15 lines for bash, 40 for Python). It works in any comment syntax.

**Native markers are honored too** — do not invent syntax where the ecosystem already has a convention:

| language | native marker |
|---|---|
| Python | `pytestmark = pytest.mark.network`, `pytestmark = pytest.mark.remote_data` |
| Go | `//go:build integration` |
| Rust | `#[ignore = "<reason>"]` — the reason string is required |

Only **file-level** markers count. A per-test `@pytest.mark.network` decorator is deliberately *not* honored:
opt-outs are file-scoped, so accepting a decorator that marks one test would silently exempt every other test
in that module — including ones added long afterwards. One legitimately-online integration test at the top of
a file would blind the gate to the rest of it, which is exactly 014's failure mode. Mark the file with
`pytestmark`, or annotate it with `@network: allowed — <reason>`.

Note that none of these carries a free-text reason *and* covers the subprocess case, which is why the
universal `@network: allowed — <reason>` remains the fallback.

## Running it

```bash
scripts/hermeticity-lint --root .            # triage this repo
scripts/hermeticity-lint --lang python       # one language
scripts/hermeticity-lint --json              # machine-readable
scripts/hermeticity-lint --list-adapters

scripts/confine-tests.sh --probe             # is the primitive available?
scripts/confine-tests.sh -- scripts/run-tests.sh --all      # ground truth
```

Pre-warm dependency caches before a confined run (`go mod download`, `cargo fetch`, `npm ci`) — the denial
applies to the whole process tree, so an unwarmed run fails on a download rather than on hermeticity.

## Adopting it in another project

The lint takes `--root`, so it runs against any repo:

```bash
~/.claude/scripts/hermeticity-lint --root /path/to/other-project
```

If that project's language has no adapter, the lint says `UNCHECKED` on stderr and exits 0 — it never
silently reports green for a language it cannot read. Adding the language is a JSON file; see
`scripts/hermeticity/adapters/README.md`.

## The other axis: host-environment coupling

The lint and the netns runner both police *network* hermeticity. They say nothing about a suite that
reads the host's environment — which is the other way a green suite turns red on someone else's machine.
Two instances of this were live in the repo and are worth recognising by shape:

- **Asserting against the deployed install, not the source.** Suites resolved their subject through
  `$HOME/.claude/{workflows,hooks}` — the paths this config gets *symlinked to* (see the README). On a
  machine where the repo has never been installed, the subject simply is not there and every assertion
  reports a missing file. Resolve from `$BATS_TEST_DIRNAME/..` instead: the deployed copies are symlinks
  back into the repo, so it is the same bytes, minus the dependency on a machine having been set up. Keep
  an env override (`WORKFLOW_DIR="${WORKFLOW_DIR:-...}"`) if pointing the suite at a real deployment is
  still useful.

- **Asserting on captured output while the locale leaks into it.** bats folds stderr into `$output`, so
  *anything* a subprocess writes to stderr lands in the value under assertion. If the ambient `LC_ALL`
  names a locale that is not installed — routine in a container that inherits `en_US.UTF-8` from the host
  without generating it — every bash subprocess prints `bash: warning: setlocale: ...`, which quietly
  breaks `[ -z "$output" ]` (now non-empty) and `"${lines[0]}"` (now the warning). `load`
  `test/lib/hermetic-env.bash` and call `pin_hermetic_locale` in any suite that treats captured output as
  exact.

The general rule both cases follow: a test's result should be a function of the code under test, not of
how the machine running it happens to be configured.

## Known gaps (stated, not papered over)

- **Indirect spawn through an interpreter**: `subprocess.run(["python3", "-c", "import requests; ..."])`
  spawns `python3`, not a listed network binary. The lint misses it; the netns runner does not.
- **In-process HTTP**: out of scope by design (see above).
- **C-extension / raw-native egress** (psycopg2, grpc, pycurl): invisible to every static pass *and* to
  every language-level blocker. Only the netns runner sees it.
- **Reads are not confined** by the runner — `--unshare-net` denies network and nothing else.

Each of these is a reason the runner is the ground truth and the lint is triage. If a suite passes the lint
and still makes a live network call, that is a hole worth filing as a fixture — see 017's revisit triggers.
