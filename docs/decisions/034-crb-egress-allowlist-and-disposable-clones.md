# 034 — CRB harness: egress allowlist and disposable clones

**Date**: 2026-08-19 · **Status**: accepted · **Branch**:
`feat/crb-direction1-harness` · **Supersedes**: the in-place containment reset
introduced at `cf6e7c9`

## Context

The CRB direction-1 harness runs our review pipeline against 50 third-party PRs
in a container with `--dangerously-skip-permissions`, a read-write mount of the
repository under review, and a live `ANTHROPIC_API_KEY`. Two reviews found
problems with that arrangement that three rounds of patching did not close:

- **2026-08-18 R3** — unrestricted container egress. The merged upstream PR (the
  answer key) was one `curl` away, and repository-controlled content could
  exfiltrate the key.
- **2026-08-19 R1, R2, R4** — the host ran `git` (`status`, `checkout --force`,
  `reset --hard`, `clean -qffdx`, `gc`, `fsck`) against a `.git` the container
  had just written. The reviewer *executed* five host-side code-execution paths
  out of that (hooks, `core.hooksPath`, `core.fsmonitor`, a smudge filter
  reachable from tracked `.gitattributes` with no agent action) plus a
  `core.worktree` redirect that deleted files in an unrelated host directory.
  And the reset/void split's only discriminator was git-fetch traces, so any
  non-git retrieval classified as benign agent work.

The review-fix loop hit its 3-iteration cap and recorded `escalate`, on the
grounds that the remaining reds were one design question rather than three
defects, and that the same containment code had produced three consecutive
mechanism errors — a signal that the next change should be a decision, not a
fourth patch.

## Decision

**1. The host never reads a container-written `.git`.** Each verified clone is
frozen at materialize time into a sha256-pinned baseline tar. A cell is a
wipe-and-extract of that tar, not a repair of the previous cell's tree. The
post-run containment audit moved into a throwaway container (`--network none`,
no key), where a hostile `.git` can reach nothing that outlives the audit.
Artifacts are collected by walking the tree and diffing `.md`/`.json` against a
baseline index, so no host `git` remains anywhere in the cell path.

**2. Answer-key retrieval is prevented, not detected.** The review container
runs on an `--internal` docker network whose only route out is a tinyproxy
sidecar that `CONNECT`s to `api.anthropic.com` on 443 and nothing else. The CLI
is baked into the review image rather than `npx`-installed per cell, so a
running cell needs only one reachable host (it will *attempt* others — the
autoupdater and telemetry endpoints listed in `devcontainer-config/egress/base.txt`
— which the allowlist refuses). A five-leg egress preflight — the network really
is `--internal`, the API is reachable through the proxy, github is refused
through it over HTTPS and over plain HTTP, and github is unroutable without it —
must pass before any paid cell. `PREFLIGHT_ONLY=1` runs exactly that and stops.

## Alternatives rejected

| Option | Why not |
|---|---|
| Sanitize `.git/config` + `.git/hooks` from a stored baseline before each host git call | Relies on enumerating every config key that can execute code. `core.fsmonitor` and the `.gitattributes` smudge filter were both missed by the reviewers' first pass at exactly this list; the next one will be missed too. |
| Hardened `-c` overrides on every host-side git call | Same enumeration problem, spread across more call sites, with no single place that fails closed. |
| Run the reset inside a container but keep it in-place | Closes R1/R2 but keeps every classification question the reset had (agent work vs contamination, nested repos, staged edits) — the source of three mechanism errors in three iterations. Wiping deletes the questions along with the state. |
| Accept: the forks are a public benchmark org, not an adversary | Defensible for R1/R2 in isolation; useless for R4, where the threat is our own agent being resourceful about a repo whose merged fix is one fetch away. |
| Block egress with `--network none` only | The cell cannot reach the API and cannot run at all. |
| Allowlist github as well, and rely on the audit | Restores exactly the path the arm's numbers depend on not existing. |

## Consequences

- Disk roughly doubles: pilot ~670 MB → ~1.3 GB, `--all` ~6.5 → ~13 GB. Each
  cell pays a few seconds of tar extraction against a $10–40 review.
- R3 (nested clone) and A8 (a voided cell leaving a permanently dead clone) are
  closed structurally rather than by a flag or a message.
- The harvest changed shape rather than strictly improving: it now sees files
  under gitignored paths, which `git status --untracked-files=all` could not (a
  rubric written to an ignored path used to vanish) — but it also stops copying
  symlinked artifacts, which the old loop copied with `cp --no-dereference`, and
  imposes 5 MB / 50 MB / 500-file caps the old loop had none of. "Strictly more
  complete" was the original wording and it is refuted as a set relation.
- `--reset` and `--heal` are gone; `--restore` replaces them. **R6 did not
  dissolve — it moved.** Every clone materialized before this change lacks a
  baseline, so `run-host.sh` skips all of them and exits 3, which is R6's exact
  symptom. It fails safe at $0, and the remedy is a rebuild
  (`--slug <id> --force`) rather than a repair, but "dissolves" was wrong and
  the 2026-08-19 review caught it against disk. A pre-existing clone is
  **re-cloned**, never baselined in place: the mode that did that in place
  (`--snapshot`) was the last host-git-on-an-untrusted-`.git` path and was
  deleted for reopening R1 — see the note in `crb-materialize.py`'s `main()`.
- **Not verified here**: everything docker-shaped. This session has no docker,
  so the images, the network and the proxy have never run. The allowlist is
  verified on the host by its own preflight, at $0, before the first cell — a
  control whose only honest verification is execution.
- Residual and unclosed: a low-bandwidth DNS side channel through docker's
  embedded resolver (`run-host.sh` names it where spend is authorized, not only
  here), and training-data leakage, which no container control touches.
- The preflight's verdict logic lives in `scripts/crb-egress-verdict.sh` rather
  than inline in the runner, because inline it was unpinnable: three separate
  mutations that neutered the legs — including dropping `--internal` — left the
  whole suite green.
