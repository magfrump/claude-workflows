Commit: f2533b33

# Security Review: Q-089 unit A1 (feat/q089a1-host-tool-manifest)

**Scope:** `git diff 4ab9a51f f2533b33`: `devcontainer-config/{cc-isolated.sh,cc-exit-scan.sh,cc-gitdir.sh,install.sh}` and `test/cc-isolated-functions.bats`. Files were read via `git show f2533b33:<path>`.
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report-q089a1.md` (0 Incorrect, 7 Mostly accurate). I checked prior passes (`security-review-2026-10-14-q089a.md`, `-pass2.md`, rubric `code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md`, all on `feat/q089-host-tool-trust`) for their findings, but they were not used as verdicts.
**Loop:** review-fix loop iteration 1 of 3 (`--loop-pass`), full scope. Sibling context, not reviewed: A2 (`feat/q089a2-cc-push-self-check`, 840f39b0/9bd33e26) and B (`feat/q089b2-host-tool-gate`).

## Trust Boundary Map

```
B1 (new):   [installed cc-exit-scan.sh, cc-gitdir.sh (host-writable)] → [verify_host_tools vs host-tools.sha256, launcher top level] → [`source` into the host launcher]
B2 (moved): [installed cc-push.sh (host-writable)]                   → [A1: launcher WARNING only; self-check arrives in A2]       → [run by the user, pushes with the user's git credentials]
B3 (new):   [host-tools.sha256, same dir, same writer as B1/B2]       → [no external anchor (unlike manifest.sha256 → baked image hash)] → [trust root for B1/B2]
B4:         [CLAUDE_DEVC_CONFIG_DIR/HOME env, dir layout markers]     → [repo-checkout opt-out predicate]                             → [check skipped]
B5:         [installed files at bless time]                           → [bless_manifest: temp files, then two mv -f]                  → [manifest.sha256 + host-tools.sha256]
B6:         [verify_host_tools output strings]                        → [refusal text, --list, WARNING]                               → [the human's decision to run cc-push or to bless]
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | Installed host-tool files | runtime-mutable (any process running as the user) | UNTRUSTED for `source`/exec until hash-matched |
| S2 | `host-tools.sha256` | runtime-mutable, same writer as S1 | Adequate against non-targeted tampering (decision log 45). UNTRUSTED against a targeted writer, who can rewrite it to match |
| S3 | `manifest.sha256` | runtime-mutable | Anchored for the boundary set by the baked image hash and the verified-live receipt. Host tools are no longer in it |
| S4 | `CLAUDE_DEVC_CONFIG_DIR`, `HOME` | request-time (per invocation) | UNTRUSTED for the opt-out decision. Trusted for the location of the config the user picked |
| S5 | Layout markers (`install.sh` present, manifests absent) | runtime-mutable | UNTRUSTED for the opt-out decision (forgeable by S1's writer) |
| S6 | `BASH_SOURCE` → `readlink -f` → `CC_ISOLATED_DIR` (PATH symlink) | runtime-mutable | UNTRUSTED toward `source`. Same trust as before this diff |
| S7 | `host_tool_files` names, the per-entry-point file lists | code-constant | trusted |

The diff moves three host-executed scripts from a manifest whose identity is baked into the image (S3) to an unanchored sibling file (S2). The launcher's executed set (B1) gets an equivalent pre-source check. For cc-push (B2), A1 replaces "launch refuses" with "launch warns", and the guarantee that cc-push refuses lands only with A2. The assumptions are that a host-side writer is non-targeted (it does not rewrite S2 or forge S5) and that A1 never ships without A2.

## Findings

#### 1. At A1 alone, the launcher reports "cc-push refuses" but cc-push does not refuse, and a tampered cc-push.sh downgrades from launch-refused to launch-warns

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:742-745` (refusal), `:498-499` (`--list`), `:751-758` (warning), comments `:196-197` and `:205-206`; `devcontainer-config/cc-push.sh:139-140` (unchanged at A1)
**Boundary:** B2, B6
**Move:** 5 (invert the access model: what A1 alone prevents), 3 (the failure-state message)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (verbatim, f2533b33):

```
      echo "  Also changed (cc-push refuses until re-blessed): $push_err" >&2
...
    if [ -n "$perr" ]; then printf '  cc-push refuses: %s\n' "${perr//$'\n'/; }"; fi
```

`cc-push.sh` at f2533b33 still does this:

```
# shellcheck source=cc-gitdir.sh
source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"
```

It has no `verify_host_tools`. Probes (hermetic install, `git archive f2533b33`):

- **P1a.** `--list` after a cc-push.sh tamper printed `launches warn (cc-push changed) but run` / `cc-push refuses: …/cfg/cc-push.sh changed since the last bless`.
- **P1c.** The tampered `cc-push.sh --help` then exited 0, and its injected top-level `touch` ran (marker created).
- **P2.** With the scan and cc-push both tampered, the launch refusal printed `Also changed (cc-push refuses until re-blessed)`.
- **P3.** With only cc-gitdir.sh tampered, `--list` printed `cc-push refuses: …cc-gitdir.sh changed`. `cc-push --help` exited 0, and cc-gitdir.sh's injected line ran.
- **P4.** At 4ab9a51f the same cc-push.sh tamper made the launch refuse (`ERROR: installed config changed since last bless — refusing to build/launch.`). At f2533b33 the launch printed the WARNING and went on.

If A1 lands and `install.sh` runs before A2 lands, the only signal against a changed cc-push is now a warning, and two messages tell the user that cc-push guards itself. A user who sees `cc-push refuses` in `--list` can reasonably run it to confirm, and that runs the tampered code with their push credentials. The tests pin these strings (`test/cc-isolated-functions.bats`, A1 diff lines 196 and 243), so they check text and not behaviour. The commit body's "the two land in order" is the only safeguard.

The rating is Low under the floor rule's host-control exception: the tamper itself needs code running as the user. The finding is still merge-order blocking. Before A1 cc-push had no self-check either, so the regression is the launcher's refusal plus the false assurance.

**Recommendation:** Land A1 and A2 as one merge (merge the A2 branch, which contains A1, or fast-forward main to A2's tip), and never run `install.sh` from a main that holds A1 without A2. If A1 must land alone, drop "cc-push refuses" from the A1 strings until A2, or keep cc-push.sh in the refusing set.

#### 2. An unreadable or garbled host-tools.sha256 fails closed, but the message names every tool as "changed" and the refusal splices a multi-line reason mid-sentence

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:229-257` (`want` from awk, the "changed" message), `:697-701`, `:735`
**Boundary:** B3, B6
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence:

```
    want="$(awk -v f="$f" '$2 == f { n++; h = $1 } END { if (n == 1) print h }' "$m")"
...
      echo "$dir/$f changed since the last bless"
```

- **P5.** With `host-tools.sha256` set to mode 000, the launch exited 1. That is correct. The output was two raw `awk: cannot open … (Permission denied)` lines, then `ERROR: …/cc-exit-scan.sh changed since the last bless` followed by a newline and `…/cc-gitdir.sh changed since the last bless — refusing to run the session-exit scan's code.`
- **P6.** A CRLF-converted manifest was likewise refused, as "changed".

In both cases the tools were unchanged and the manifest was the anomaly. The hint then points straight to a bless, which would overwrite that evidence. This is not exploitable: every case fails closed.

**Recommendation:** Optionally check `[ -r "$m" ]` and report "host-tool manifest unreadable or malformed" instead of a per-tool "changed". Join the reason lines (as `--list` already does with `; `) before splicing them into the `ERROR:` sentence.

## Untested bypass candidates (move 11, `verify_host_tools` and the opt-out)

| # | Candidate | Disposition |
|---|---|---|
| 1 | Tamper the scan at top level | **Tested** (P2): refused, injected line not run |
| 2 | Tamper cc-gitdir.sh | **Tested** (P3, `--list` executed; launch traced, same call `:697`): launch refuses. cc-push runs it at A1 (Finding 1) |
| 3 | Tamper cc-push.sh | **Tested** (P1, P4): launch warns and continues, cc-push runs (Finding 1) |
| 4 | Unreadable manifest | **Tested** (P5): fails closed (Finding 2) |
| 5 | CRLF manifest | **Tested** (P6): refused |
| 6 | Bless with a missing enforcement file | **Tested** (P7): rc 1, `ERROR: nothing blessed.`, both manifests byte-identical, no leftover temp files |
| 7 | Duplicate or `*`-prefixed lines, symlinked tool or manifest | Traced: `n == 1` / `$2 == f` give an empty `want` and a refusal, and `-L` refuses (prior pass-1 probes agree) |
| 8 | Planted `install.sh` plus deleted manifests, variable set elsewhere or to a path whose parent is missing (`cfg` becomes empty) | Traced: opt-out taken, tampered scan sourced. Same as prior pass-2 F4; needs a deliberate, targeted writer (outside decision log 45) and costs more than rewriting S2 |
| 9 | **Untested:** rewrite host-tools.sha256 to match a tampered tool | Passes by construction (S2 unanchored). Unlike S3, it changes no `blessed_hash`, so no rebuild or "NOT verified" signal appears either. Accepted residual under decision log 45 |
| 10 | **Untested:** swap a file between hash and `source` (TOCTOU), or a hardlink | Needs a timed race. Accepted (plan B7) |
| 11 | **Untested:** repoint the PATH symlink to a dir with a self-consistent manifest | Not exercised. Same as before this diff |

Because of rows 9–11 and Finding 1, `verify_host_tools` does not appear in the Endorsement Claims as a guard. The claims below cover specific executed behaviours only.

## Endorsement Claims

- **Claim:** At f2533b33, a launch with a top-level-tampered `cc-exit-scan.sh` exits 1 without running the injected line, names the tool, and runs the boundary check.
  **Location:** `devcontainer-config/cc-isolated.sh:695-702, 734-750`
  **Evidence:** executed
  **Verified:** P2: marker absent, rc 1, the refusal printed the boundary note.
  **Not verified:** a tamper landing between the hash at `:697` and the `source` at `:699`.
  **route: code-fact-check**
- **Claim:** A bless whose boundary compute fails leaves both manifests byte-identical and no `.manifest.*`/`.host-tools.*` temp files.
  **Location:** `devcontainer-config/cc-isolated.sh:270-279`
  **Evidence:** executed
  **Verified:** P7 (`cmp` on both manifests, `ls -a`).
  **Not verified:** an interrupt between the two `mv -f` at `:291-292`. The comment documents that split.
  **route: code-fact-check**
- **Claim:** An unreadable `host-tools.sha256` makes the launch refuse.
  **Location:** `devcontainer-config/cc-isolated.sh:229-257`
  **Evidence:** executed
  **Verified:** P5, rc 1.
  **Not verified:** the same path when run as root, where mode 000 does not deny the read.

## Primitive sweep

Primitive: `source` (host code execution)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-isolated.sh:699` | S1, S6 | `verify_host_tools` on cc-exit-scan.sh and cc-gitdir.sh (`:697`) | cleared, apart from untested rows 9–11 |
| `cc-exit-scan.sh:12` (sources cc-gitdir.sh) | S1 | covered by the launcher's check at `:697` (same dir, cc-gitdir.sh in the list) | cleared |
| `cc-push.sh:140` (sources cc-gitdir.sh; not in diff, behaviour changed by it) | S1 | none at A1 (A2 adds one) | Finding 1 |
| Execution of `cc-push.sh` itself | S1 | launcher WARNING only at A1 | Finding 1 |

Primitive: path construction plus `mv -f` (bless)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-isolated.sh:272-273` (`mktemp` in `config_dir`), `:291-292` (`mv -f`) | S4 | same-dir mktemp, renames within the dir | cleared: S4 is the user's own choice of config dir |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---|---|---|---|---|
| 1 | At A1 alone, "cc-push refuses" is false; tampered cc-push.sh goes from launch-refused to launch-warns | Low (merge-order blocking) | B2, B6 | `cc-isolated.sh:742-745, 498-499`; `cc-push.sh:139-140` | High |
| 2 | Unreadable or garbled manifest reported as every tool "changed"; mid-sentence splice | Informational | B3, B6 | `cc-isolated.sh:229-257, 735` | High |

## Overall Assessment

Within the code paths read and executed, A1's launcher-side check does what it says for the files the launcher sources. A tampered scan or cc-gitdir.sh is refused before any of its code runs, and a failed bless changes nothing. What A1 exposes on its own is cc-push. A1 removes cc-push.sh from the manifest that used to make launches refuse, and it prints "cc-push refuses" in two places at a commit where cc-push has no self-check (executed: the tampered copy ran). That is fixable in place, and it disappears entirely if A1 and A2 merge as one unit. That is the single most important thing to get right.

Prior passes already carry the rest: the unanchored `host-tools.sha256`, the opt-out forgeable by a deliberate writer, TOCTOU, and the dir-split wording the fact-check flagged. All of these sit within decision log 45's non-targeted threat model.

Out of scope but adjacent: `--register` re-blesses both manifests without running `check_manifest` first. That predates this diff. A1 improves it, because the bless now prints what changed.

No findings above Low within the code paths read. Endorsement claims are pending execution verification by code-fact-check.

## Goal-Alignment Note

The goal is to review a security-sensitive trust-manifest change before it merges, with a focus on what earlier passes missed and on A1 landing without A2. Finding 1 answers the second question directly: A1 is safe to merge only together with A2, never ahead of it. Nothing in A1 weakens the boundary manifest's anchoring for the files it still covers. Probes ran under `timeout` in `/home/node/.claude/jobs/00bcf178/tmp/secA1.cv1p2q`, from `git archive` extracts of f2533b33 and 4ab9a51f, with HOME, CLAUDE_DEVC_CONFIG_DIR, TMPDIR and LC_ALL=C redirected and a stub `devcontainer`. No real config dir was touched, `install.sh` was not run, and no processes were left running (checked with `ps`).
