# Plan — egress allowlist + disposable clones (CRB direction-1 harness)

**Date**: 2026-08-19 · **Branch**: `feat/crb-direction1-harness` · **Answers**:
the `escalate` decision recorded in
`docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness.md`
(R1, R2, R4 open) and R3 on the 2026-08-18 rubric.

## The question the escalation asked

> Should host-side git commands ever run against a `.git` directory that a
> `--dangerously-skip-permissions` container had write access to?

**Answer: no.** Not option (a) sanitize, (c) `-c` overrides, or (d) accept — all
three keep a foreign `.git` on the host git path and rely on enumerating the
config keys that can execute code. Instead the work clone becomes **disposable**:
a per-cell extract of a hash-pinned baseline tar built before any container
existed. Nothing on the host ever runs `git` against container-written state.

That is one half. The other half is R3/R4: the container has unrestricted
egress, so the answer key is one `curl` away and the containment guard is
detection-only with known fail-open paths. **An egress allowlist makes the
retrieval prevented rather than detected**, which is also what R3 asks for.

## Design

### 1. Egress allowlist

| Piece | What |
|---|---|
| `docker/Dockerfile.review` | `node:22` + `@anthropic-ai/claude-code@$CC_VERSION` installed at build time. Built once, with normal network. Removes `registry.npmjs.org` from the allowlist a running cell needs — the review container then needs exactly one host. |
| `docker/Dockerfile.proxy` + `tinyproxy.conf` | `debian:bookworm-slim` + tinyproxy, `FilterDefaultDeny Yes`, filter = `^api\.anthropic\.com$`, `ConnectPort 443` only. |
| network | `crb-inner`, created `--internal` with a pinned subnet (so the proxy's `Allow` is deterministic). The proxy container is additionally attached to `bridge`, and is the only route out. |
| review cell | `--network crb-inner`, `HTTPS_PROXY=http://crb-proxy:3128`. The API key stays in the review container; CONNECT is a TLS tunnel, so the proxy never sees it. |

**Egress preflight, mandatory, aborts the sweep on failure.** Assumption-free:
it *tests* the control rather than asserting it.

1. positive — `api.anthropic.com` reachable through the proxy;
2. negative — `github.com` through the proxy is refused (tinyproxy 403);
3. negative — `github.com` with no proxy env is unroutable (the `--internal` net).

(2) and (3) are separate because they fail for different reasons and a single
test passing for the wrong reason is exactly how this harness has gone wrong
before. The existing auth + skill-registration preflight then runs *inside the
restricted network*, so it doubles as proof a real cell can still work there.

### 2. Disposable clones

`materialize()` snapshots each verified clone to
`external/crb-eval/.baselines/<slug>.tar` plus a `.index.json` of `.md`/`.json`
hashes, and records `baseline_sha256` in the manifest. The tar is built from a
clone no container has ever touched.

Per cell:

| Old | New |
|---|---|
| pre-run `--reset` (host git surgery on foreign `.git`) | `--restore` — `rm -rf` the work clone, verify the tar's sha256, extract. No git at all. |
| harvest via host `git status --porcelain` | `crb-harvest-artifacts.py` — walk the tree, diff `.md`/`.json` against the baseline index. No git. |
| post-run `--reset` (void or reset) | `crb-audit-clone.sh` run **inside** a throwaway container (`--network none`, read-only mount, no key). Void on traces; the clone is discarded either way. |

Consequences beyond R1/R2:

- **R3 (nested clone) is closed structurally** — a nested repo cannot survive a
  wipe, so it no longer depends on `git clean` flag semantics.
- **A8 closed** — a voided cell no longer leaves a permanently dead clone.
- **The harvest gets strictly better**: `git status --untracked-files=all` honours
  `.gitignore`, so a rubric written to a gitignored path was invisible to it.
- **Cost**: disk roughly doubles (pilot ~670 MB → ~1.3 GB; `--all` ~6.5 → ~13 GB)
  and each cell pays a few seconds of extract against a $10–40 review.

### 3. What is deliberately NOT changed

- `--dangerously-skip-permissions` stays: the pipeline under test is the one a
  real unattended user runs, and the container is now the trust boundary.
- The detection code (`fetch_traces`, `classify_strays`, `verify_containment`)
  stays for **materialize time**, where it establishes the baseline. `reset_clone`
  — the in-place git surgery — is deleted; nothing else may call it.
- No auto-heal. `--heal` keeps its one-shot operator role for pre-2026-08-19
  clones, which now only need to reach a snapshot.

## Residual risk, to state in the results doc

1. **DNS.** Containers on `crb-inner` still reach docker's embedded resolver, so
   a low-bandwidth DNS side channel exists. Not closed here.
2. **The audit is still detection.** With egress closed its fail-open paths are
   much narrower, but `voided_cells: []` still means "nothing detected".
3. **Untested against a real sweep.** Everything below is verified by unit tests
   and by the preflights; no paid cell has run.

## Test plan

| Test | Closes |
|---|---|
| `test/crb-disposable-clone.bats` | snapshot/restore round-trip; restore wipes a nested repo, an agent commit, a re-added remote; a tampered tar fails the hash and refuses to restore; `--dry-run` honoured. |
| `test/crb-audit-clone.bats` | audit VOIDs on FETCH_HEAD, unreachable commit, surviving remote, foreign commit, nested repo; passes a benign agent commit; non-vacuity pin. |
| `test/crb-harvest-artifacts.bats` | new/changed `.md`/`.json` harvested incl. a gitignored path; unchanged skipped; symlinks and oversized files refused; no path escapes the artifacts dir. |
| `test/crb-egress-config.bats` | the tinyproxy filter denies by default and lists exactly one host; `run-host.sh` wires `--network crb-inner` and the proxy env onto every review container and never runs host `git` against `$clone`. |
