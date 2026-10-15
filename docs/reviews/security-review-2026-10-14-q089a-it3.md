Commit: f737ba71

# Security Review — Q-089 units A1+A2, iteration 3 (fix delta and the joint merge)

**Scope:** `git diff b3b37e16 f737ba71 -- devcontainer-config test` on feat/q089a2b-cc-push-self-check (A2's re-stacked 4be0445d, 2cb03f23, cc2640b7, plus the joint fix f737ba71). Everything up to b3b37e16 is read as context. Unit B (wt-q089b, which carries decision log row 71) is read as sibling context.
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report-q089a-it3.md` (19 claims: 18 verified, 1 incorrect, a rubric reference). Prior advisory reviews: `security-review-2026-10-14-q089a1.md`, `security-review-2026-10-14-q089a2.md`.
**Probes:** `docs/reviews/execution-logs/sec-q089a-it3/probe.sh` with its output `out.log`. The probe tree was a fresh `mktemp -d` root, `/home/node/.claude/jobs/00bcf178/tmp/sec-it3.1aa0KG`, holding `src/` from `git archive f737ba71`. HOME, TMPDIR, CC_PUSH_CLONES_DIR and CLAUDE_DEVC_CONFIG_DIR were all redirected under that root, with LC_ALL=C and a stub `devcontainer`. Every command ran under `timeout 20`. install.sh never ran. Installed layouts were plain copies blessed with `sha256sum`. Nothing was left running.

## Trust Boundary Map

```
B1: installed host-tool files (cc-push.sh, cc-gitdir.sh) → verify_host_tools vs host-tools.sha256 (cc-push.sh:203-212) → bash parses the rest of cc-push.sh, then `source cc-gitdir.sh` (:214)   (new, A2)
B2: host-tools.sha256 contents                           → shape gate: -f, !-L, -r, -s (new), sha256sum line regex (cc-push.sh:163-173 = cc-isolated.sh:238-247) → per-file want/have compare (no-single-entry branch new)
B3: caller environment (PATH, exported BASH_FUNC_*, CLAUDE_DEVC_CONFIG_DIR) → safe_path (absolute entries only) and the exemption's cfg test → name resolution of sha256sum/awk/readlink inside the check
B4: verify_host_tools output                             → launcher refusal, launcher WARNING and `--list` labels (cc-isolated.sh:515, 751-776) → what the user believes about whether cc-push is safe to run
```

Input-source classification:

```
S1: cc-push.sh / cc-gitdir.sh bytes on disk  — runtime-mutable (any host writer) — UNTRUSTED toward exec/source, until hashed
S2: host-tools.sha256                        — runtime-mutable — trusted as the bless reference (row 71 accepts a rewrite as not covered); UNTRUSTED for shape (gated)
S3: caller env: PATH entries, BASH_FUNC_*%%  — request-time (per invocation) — UNTRUSTED toward the exec sink; row 45/71 treat caller control as host control (out of model)
S4: CLAUDE_DEVC_CONFIG_DIR / HOME            — request-time — trusted only for the exemption's "not the config dir" clause (a2 finding 4)
S5: ${BASH_SOURCE[0]} resolved by readlink -f — deploy-time (the symlink install.sh made) — trusted for locating the dir; a symlinked tool file is rejected
```

S1 crosses B1 into the exec sink. The diff's job is to make that crossing conditional on a hash match against S2. S3 is the one input that can steer the check itself, and the diff leaves it as before: `safe_path` removes relative PATH entries and nothing more. B4 is where the security property reaches the human, and the one Low finding sits there.

## Findings

#### 1. `--list` says "cc-push refuses:" about a copy that has dropped its check, and that copy runs

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:515` (A1 context; the label's premise is A2's check at `devcontainer-config/cc-push.sh:203-212`)
**Boundary:** B4
**Move:** 5 (invert the model: what the label covers versus what actually runs)
**Confidence:** High
**Legibility-target:** the `--list` host-tools lines, and row 71's sentence "the launcher's warning and `--list` catch those" (unit B).

**Evidence (verbatim):**
```
    if [ -n "$perr" ]; then printf '  cc-push refuses: %s\n' "${perr//$'\n'/; }"; fi
```
Probe Q10 removed the check block from an installed cc-push.sh and left the rest unchanged:
```
[Q10a-list] rc=0
      launches warn (cc-push changed) but run
      cc-push refuses: …/inst/cc-push.sh changed since the last bless
[Q10b-dropped-check-runs] rc=0
    cc-push — push the commits a cc-isolated session made, …
```
`--list` reports what an *intact* cc-push would do. Row 71 names exactly this case, "an overwrite that drops it", as one `--list` catches. It does catch it, because the tool is listed as CHANGED. But the next words the user reads assert a refusal the modified copy does not perform. The launcher's WARNING (`:772-775`) says "do not run cc-push", which is the accurate instruction. A1+A2 landing together makes the label true for every untampered install, so this is not a regression of the merge. It is a legibility gap that matters only in the exact case the label is there to report. Reaching that case requires a writer who produces a working cc-push without its check. That is targeted tampering, below row 45's bar, so the finding stays Low and the floor rule does not apply.

**Recommendation:** Word the line as a state plus an instruction, not as a prediction of cc-push's behaviour. For example: `cc-push: CHANGED — do not run it until re-blessed (an intact cc-push refuses): <reasons>`. Keep the reasons text unchanged so the existing tests' substrings still match.

#### 2. An exported bash function shadowing `sha256sum` passes both checks; row 71 names only a PATH shim

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:190` (`have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"`) and the byte-identical line in `devcontainer-config/cc-isolated.sh`
**Boundary:** B3
**Move:** 11 (bypass enumeration)
**Confidence:** High (executed). Relevance to the threat model: Low.
**Legibility-target:** row 71's "Not covered" list (unit B, `docs/decisions/log.md:94` on wt-q089b), which reads "a `sha256sum` or `awk` shim on PATH that prints the blessed hash".

**Evidence (verbatim):**
```
[Q7a-no-shim] rc=1
      …/inst/cc-gitdir.sh changed since the last bless
    Q7a payload not run
[Q7b-exported-fn-shim] rc=0
    cc-push — push the commits …
    Q7b payload RAN (exported-function bypass)
```
Q7b ran `env 'BASH_FUNC_sha256sum%%=() { … echo "<blessed hash>  -"; }' bash cc-push.sh --help` against a tampered cc-gitdir.sh, and the planted line ran at source time. `safe_path` filters PATH entries, but bash imports exported functions before any of the script runs, and a function takes precedence over a PATH lookup. This is the same class as a2 finding 3, through a different door. It needs control of the caller's environment, which is host control and outside row 45's non-targeted model. `git` is exposed the same way, so a forged `git` function is strictly more powerful. For both reasons this asks for no code change. It is listed so that row 71's enumeration does not read as "only PATH can steer the check".

**Recommendation:** In unit B, widen row 71's entry to "a `sha256sum` or `awk` shim, on PATH or as an exported shell function, that prints the blessed hash (both are found by name, as `git` is)". Do not add `unset -f` or absolute paths for these two tools alone. `git` stays resolvable by name, so that would be theater.

## Bypass candidates for the B1/B2 guard (move #11)

Tested (executed, `out.log`):

| # | Input | Result |
|---|---|---|
| Q2 | manifest line in `sha256sum -b` form (`<hash> *cc-push.sh`) | rc=1, "unreadable or malformed"; nothing sourced |
| Q3a/b | upper-case hex in the manifest, under LC_ALL=C and LC_ALL=C.utf8 | rc=1, "malformed" in both locales |
| Q4 | host-tools.sha256 is a FIFO | rc=1, "no host-tool manifest"; no hang (`-f` rejects it before any read) |
| Q5 | host-tools.sha256 is a directory | rc=1, "no host-tool manifest" |
| Q6 | executable line inserted *above* the check (after `safe_path`) | the line ran, then rc=1. This is the documented limit (header `cc-push.sh:38-43`, row 71) |
| Q7a | tampered cc-gitdir.sh, no shim | rc=1; the planted line did not run |
| Q7b | the same, with an exported `sha256sum` function | bypass, Finding 2 |
| Q10 | cc-push.sh with its check removed | runs (rc=0); `--list` flags it CHANGED, Finding 1 |
| fact-check it3 | empty manifest; missing or duplicated entry; unreadable (chmod 000); CRLF line; tamper directly below the check | all rc=1 with the named reason (claims 2, 3, 6, 14) |

## Untested bypass candidates

| Candidate | Why not tested |
|---|---|
| Rename-swap or in-place rewrite of cc-push.sh *after* the hash but before bash reads the lines below the check (bash reads a script incrementally). Likewise cc-gitdir.sh between hash and `source`. | Needs a racing writer, which is targeted. Row 71 lists TOCTOU as not covered. |
| `awk` exported-function or PATH shim that forces `want` to equal `have` | Same class as Q7b. The outcome follows from the same name lookup. |
| A config-dir path containing a newline, splitting one reason across indented lines | Cosmetic only. The refusal still exits 1 before `source`. |

Because these remain, no Endorsement Claim below asserts anything about the guard's strength.

## Endorsement Claims

- **Claim:** cc-push's re-bless hint shell-quotes the directory, so a path with a space and a quote prints as one pasteable assignment.
  **Location:** `devcontainer-config/cc-push.sh:209`
  **Evidence:** executed
  **Verified:** Q12, dir `in st'x`, printed `CLAUDE_DEVC_CONFIG_DIR=…/in\ st\'x cc-isolated --bless`.
  **Not verified:** that the `cc-isolated` this hint resolves on the user's PATH is the copy beside that dir. The hint names the command by name.
- **Claim:** the indenting `while read` loops in both refusals exit 0 under `set -euo pipefail` and are reached only with a non-empty reason string.
  **Location:** `devcontainer-config/cc-isolated.sh:751-753`, `devcontainer-config/cc-push.sh:204-207`
  **Evidence:** executed (fact-check it3, claim 4, P4), plus Q2-Q7 here (the cc-push form)
  **Verified:** loop status 0 under `-euo pipefail`; the `[ -n "$HOST_TOOLS_ERR" ]` guard; cc-push's branch is entered only on a non-zero return.
  **Not verified:** the launcher WARNING path (`:772-775`), which prints `push_err` unindented. At most one reason can arise there.
- **Claim:** every `source` of a host tool in the scope is preceded by a check of that file in the same resolved dir.
  **Location:** see Primitive sweep
  **Evidence:** read-static
  **Verified:** grep of `source`/`.`/`eval`/`exec` across cc-isolated.sh, cc-push.sh, cc-exit-scan.sh and cc-gitdir.sh at f737ba71.
  **Not verified:** other bash spellings of sourcing that grep does not match. Row 71 splits that check out as Q-147.
  **route: code-fact-check**

## Primitive sweep

Primitive: `source` (code execution from a host-tool file)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `devcontainer-config/cc-push.sh:214` `source "$CC_PUSH_DIR/cc-gitdir.sh"` | S1, S5 | `verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh` at `:204`, same dir variable | cleared for non-targeted tampering; S3 steering = Finding 2 |
| `devcontainer-config/cc-isolated.sh:716` `source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` | S1, S5 | `verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh` at `:714` | cleared (A1 context, unchanged in this delta) |
| `devcontainer-config/cc-exit-scan.sh:12` `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"` | S1, S5 | covered by the launcher's check of cc-gitdir.sh. The check rejects a symlinked cc-exit-scan.sh, so the dir it resolves is `CC_ISOLATED_DIR` | cleared |
| `devcontainer-config/cc-push.sh` lines 1-202 (parsed before the check) | S1 | none possible | documented limit (Q6); not a finding |

Primitive: process exec by name inside the check (`sha256sum`, `awk`, `readlink`, `grep`, `cut`, `dirname`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-push.sh:145-198` (= `cc-isolated.sh` copy, pinned by `test/cc-isolated-functions.bats` parity test) | S3 | `safe_path` (relative entries only) | Finding 2 (exported functions); PATH shim already in row 71 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `--list` says "cc-push refuses" about a check-less copy that runs | Low | B4 | `devcontainer-config/cc-isolated.sh:515` | High |
| 2 | Exported `sha256sum` function passes both checks; row 71 names only PATH | Informational | B3 | `devcontainer-config/cc-push.sh:190` | High |

## Overall Assessment

The fix delta introduces no new exploitable path. Each of f737ba71's changes moves toward failing closed or reporting more accurately: an empty manifest becomes malformed, a missing entry is named, and the bare bless hint is gone. The new reason-indent loops are inert under `set -e`. Every manifest-shape variant probed fails closed before anything is sourced. As a merge, A1+A2 together close a1's Finding 1: the launcher's "cc-push refuses" is now backed by a cc-push that refuses. The remaining limits are row 71's stated ones: lines above the check, a check-dropping overwrite, a rewritten manifest, name-resolved tools, and TOCTOU. All need targeted host tampering, which row 45 places out of model. The single most useful change is Finding 1's wording: in the one case `--list` is there to catch, it should tell the user not to run cc-push rather than claim cc-push refuses. Both findings are fixable in place, in wording only: Finding 1 in A1's `--list` string, Finding 2 in unit B's row 71. Neither blocks the merge. No findings within the code paths read and probed beyond these two; endorsement claims are scoped as stated, and the read-static one is pending execution verification.

## Goal-Alignment Note

The goal is a security-sensitive host-tool trust manifest that lands as A1+A2 and then B, without the review loop running past its cap. This review is iteration 3 of 3. Neither finding warrants a fourth code iteration. Finding 1 is a one-string change, and if it is deferred it belongs on the questions doc or in B's follow-up. Finding 2 is a row-71 edit that belongs in unit B, where the row lives. Three merge-level observations for the orchestrator:

1. Between the A1+A2 merge and B's merge, `main` cites "decision log row 71" in user-facing `cc-push --help` text, and in comments in cc-isolated.sh and install.sh. The row exists only on wt-q089b, so B should follow promptly.
2. After this merge, an existing install with no host-tools.sha256 gets a cc-push that refuses until install.sh is re-run or the dir is re-blessed. That is fail-closed and correctly hinted, but it is a user-visible upgrade step worth one line in B's guide changes, if B does not already cover it.
3. The fact-check's one Incorrect, A2's rubric lacking the one-merge decision, is a documentation fix, not a security one.
