Commit: b1539159

# Security Review: Q-089 unit A, review-fix pass 2 (pass-1 fix delta)

**Scope:** `git diff dce5b039 b1539159` (`devcontainer-config/cc-isolated.sh`, `cc-push.sh`, `install.sh`, `cc-exit-scan.sh`/`cc-gitdir.sh` headers, `test/cc-isolated-functions.bats`, `test/cc-push.bats`). Every file was read as committed at b1539159 with `git show`, not from the working tree, which the author is editing concurrently. dce5b039 and `git diff 4ab9a51f b1539159` were read as context.
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report.md` (pass 2, Commit b1539159); pass-1 report `docs/reviews/security-review-2026-10-14-q089a.md` (F1 to F4); decision log rows 45 and 71.
**Probes:** all ran under `timeout` in `/home/node/.claude/jobs/00bcf178/tmp/secrev2.2pMYz6/`, with `HOME` redirected to `$E/h` and `CLAUDE_DEVC_CONFIG_DIR` pointing at fake dirs under `$E`. Each fake config dir held the nine b1539159 payload files and was blessed by its own `cc-isolated.sh --bless`. I did not touch the real config dirs and did not run install.sh.

## Pass-1 fix verdicts

| Pass-1 | Claimed fix | Verdict | Evidence |
|---|---|---|---|
| F1 (Medium): refusal hid the boundary diff, and bless accepted it unseen | The refusal runs `check_manifest` and shows its diff. Bless prints what changed | **Holds when the launcher dir is the config dir** (the default install). P1: the refusal printed the Dockerfile hash diff plus "The BOUNDARY config changed too", and bless printed both changes. **Residuals:** findings 1 and 2 | P1, P2, P5, P7 |
| F2 (Low): launcher no longer noticed a tampered cc-push | Launch warns on a cc-push.sh mismatch and does not refuse | **Holds.** P3: `WARNING: …/cc-push.sh changed since the last bless — do not run cc-push…`. A prepend still runs when cc-push is invoked directly, which is inherent. `--list` wording is wrong (finding 3) | P3 |
| F3 (Low): opt-out by deleting manifests | Positive repo marker: install.sh present, no manifest of either kind, not the config dir | **Holds.** The pass-1 bypass (P4a) now refuses, and so does a planted install.sh with the env var unset (P4c). The remaining bypass is to plant install.sh **and** point the env var elsewhere. That costs as much as editing a tool, so it adds no capability (finding 4) | P4a to P4d |
| F4d (Info): bless ordering | Both manifests go to temp files, then `mv`. A failure changes neither | **Holds for a compute failure** (P6: `ERROR: nothing blessed.`, host-tools.sha256 byte-identical, no temp file left). The mktemp-2 and mv-2 leaks match the fact-check and fail closed (finding 5) | P6 |
| F4e (Info): stale headers | Headers of cc-exit-scan.sh and cc-gitdir.sh updated | Holds (read-static) | diff |

## Trust Boundary Map

```
B1:         [host-tools.sha256 + host tool files in script dir]          → [verify_host_tools (hash, -f/-L)]                → [source into cc-isolated / cc-push]
B3:         [manifest.sha256 boundary files (Dockerfile, firewall…)]    → [check_manifest / --bless (human review)]         → [blessed_hash baked into image]
B4 (moved): [presence of install.sh + manifests, CLAUDE_DEVC_CONFIG_DIR] → [repo-checkout opt-out, now a positive marker]  → [verification skipped]
B5 (new):   [refusal text + bless "Changed since" output]                → [human reading it (S6)]                           → [decision to run --bless, which rewrites both manifests]
B6 (new):   [bless temp files in config_dir]                             → [mktemp + mv]                                     → [manifest.sha256 / host-tools.sha256 (B1, B3 references)]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | Host tool files in the installed dir | runtime-mutable (any user-uid process) | UNTRUSTED toward the source/exec sink until hashed |
| S2 | `host-tools.sha256`, `manifest.sha256` | runtime-mutable, same writer as S1 | Trusted only as a defence-in-depth reference (row 45 accepts that a targeted attacker rewrites them) |
| S3 | `CLAUDE_DEVC_CONFIG_DIR` | invocation-time, user shell | UNTRUSTED toward the opt-out decision (B4) and toward which dir the refusal checks (B5). Trusted for choosing the config location |
| S4 | Presence of `install.sh` / manifests in the script dir | runtime-mutable | UNTRUSTED toward the opt-out. Creating install.sh costs the same as deleting a manifest |
| S5 | `CC_ISOLATED_DIR` (`readlink -f` of BASH_SOURCE) | resolved per call | Trusted for locating files (canonical). It can differ from `config_dir` |
| S6 | Human reading the refusal and bless output | n/a | The final check at B3 and B1. Anything that changes what they see is in scope |

The fix delta changes what the human is shown (B5) and how the references are written (B6). It narrows the opt-out (B4). Threat model as in pass 1 (row 45): non-targeted host-side tampering by a user-uid process, so severity measures lost detection or legibility relative to the intended control. The floor-rule exemption (the attacker already controls the host) applies uniformly, as in pass 1. Low means a real loss of detection within the stated threat model.

## Findings

#### 1. Bless shows changes only after committing them. The refusal names only the first changed host tool, and with the prior manifests gone bless shows nothing

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:240-255` (`verify_host_tools` returns at the first mismatch), `:260-284` (`bless_manifest`), `:697-708` (refusal)
**Boundary:** B5, B1
**Move:** 3 (error path), 5 (what does the new output prevent?)
**Confidence:** High (executed: P2, P7)
**Legibility-target:** the human deciding whether to run `--bless` (S6)

Evidence:
```bash
  for old in "$(manifest_path):$new_m" "$(host_tools_path):$new_h"; do
    if [ -f "${old%%:*}" ] && ! cmp -s "${old%%:*}" "${old#*:}"; then
      echo "Changed since the last bless ($(basename "${old%%:*}")):"
      diff "${old%%:*}" "${old#*:}" | grep '^[<>]' || true
      echo
    fi
  done
  mv -f "$new_h" "$(host_tools_path)"
  mv -f "$new_m" "$(manifest_path)"
```
```bash
    echo "  Review the host tools in $CC_ISOLATED_DIR, then re-bless (it prints what changed):" >&2
```

The fix moved the full host-tool picture into bless, but bless prints it and then moves both files into place without asking. The refusal is the last point before the commit, and it names only the first mismatch, because `verify_host_tools` returns 1 on the first bad file. P7 tampered all three host tools. The refusal named only `cc-exit-scan.sh`, and the cc-push WARNING never printed because the refusal exits first. Bless then printed three `>` lines, after it had already accepted them. A user who reviews the one named file and re-blesses has accepted cc-gitdir.sh and cc-push.sh unseen, and only learns that from scrollback. P2 deleted both manifests and appended to the Dockerfile. The refusal correctly said "BOUNDARY config changed too", but bless, which the refusal says "prints what changed", printed no `Changed since` line at all, because the guard `[ -f old ]` skips the comparison silently. For the boundary there is a backstop: the new hash is unverified, so the next launch rebuilds and probes. For host tools there is none.

**Recommendation:** Make the refusal list every mismatched host tool (loop without the early return, or diff `compute_host_tools_manifest` against `host-tools.sha256` the way `check_manifest` does). In bless, when an old manifest is missing, print "no previous <file>: every entry below is new, review all of it". Optionally, when stdin is a tty and something changed, confirm before the `mv` (install.sh already has `confirm`). That makes the bless the review its comment claims.

#### 2. When the launcher dir is not the config dir, the refusal checks one dir and recommends blessing another, and says no rebuild or probe is needed

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:700-706` (refusal), `:296-313` (`check_manifest` uses `config_dir`), `:458` (`--list` uses `config_dir`)
**Boundary:** B5, B3
**Move:** 1 (two sources, S3 and S5, naming "the" config), 3
**Confidence:** High (executed: P5); Medium on reachability (needs a custom install dir and the env var unset at launch)
**Legibility-target:** the human reading the refusal (S6)

Evidence:
```bash
    local boundary_note="The boundary config is unchanged: after the re-bless, no rebuild or probe is needed."
    if ! check_manifest; then
```
```bash
    printf '    CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless\n' "$CC_ISOLATED_DIR" >&2
```

`check_manifest` compares `config_dir` (env or default), but the printed bless targets `$CC_ISOLATED_DIR`. P5 used a custom install at `$E/inst` and a separate, clean default dir, with the env var unset at launch. I tampered `inst/cc-exit-scan.sh` and `inst/Dockerfile`. The refusal printed "The boundary config is unchanged: after the re-bless, no rebuild or probe is needed." The bless it recommends then accepts the changed `inst/Dockerfile`. With the env var set (P5b), the note was correct. This is fact-check C5 viewed as a security issue: the sentence written to stop F1 from recurring states the opposite of the truth in this case. The new bless diff output is a backstop (it would print the Dockerfile line), but the user has just been told the boundary needs no attention. `check_manifest`'s own nested hint (`$0 --bless`, no env var) targets the other dir, so the refusal shows two different bless commands. `--list` has the same split.

**Recommendation:** Run the refusal's boundary check against the dir the printed bless targets (`CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" check_manifest`, in a subshell or with the variable scoped to the call). Or, when `$CC_ISOLATED_DIR` is not the canonical `config_dir`, say so and drop the "unchanged" sentence.

#### 3. `--list` says "launches refuse" for a cc-push-only mismatch, which only warns

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:458-462`
**Boundary:** B5
**Move:** 5
**Confidence:** High (executed: P3; matches fact-check "Incorrect")
**Legibility-target:** the human using `--list` as the status check

Evidence:
```bash
    echo "Host tools: CHANGED — $err (launches refuse; review, then: cc-isolated --bless)"
```

In P3, `--list` printed `…/cc-push.sh changed since the last bless (launches refuse; …)` while the launch only warned. The direction matters a little. It tells the user that the launcher stops on this state, so a user who sees launches proceed may conclude the change was cleared. The useful message is the opposite: "cc-push will refuse; launches only warn".

**Recommendation:** Pick the wording by which file mismatched. Fixing it in place is enough.

#### 4. Residual opt-out: planting install.sh with the env var pointing elsewhere

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:234`, `devcontainer-config/cc-push.sh:156` (identical copies)
**Boundary:** B4
**Move:** 11
**Confidence:** High (executed: P4b, P4d)
**Legibility-target:** maintainers relying on the header's "deleting manifests is not enough"

Evidence:
```bash
  if [ -f "$dir/install.sh" ] && [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
```

P4b deleted both manifests in the default dir, appended to cc-gitdir.sh, planted an empty `install.sh` and set `CLAUDE_DEVC_CONFIG_DIR` elsewhere. Running cc-push printed `PWNED-gitdir`. P4d showed that a symlinked install.sh also satisfies `-f`. With the env var unset (P4c), the dir is checked. This needs three writes plus control of the invoking environment, which costs more than editing cc-push.sh, so it adds no capability against row 45's attacker. The header's claim ("deleting manifests is not enough") is accurate. The fix is the right shape.

**Recommendation:** None required. Do not add `! -L` or similar here: it would be theatre at equal attacker cost.

#### 5. Bless hygiene notes

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:260-275`; `test/cc-isolated-functions.bats` (source-set test)
**Boundary:** B6, B5
**Move:** 3, 12
**Confidence:** High for the colon case (executed: P8); Medium otherwise (read-static plus fact-check)
**Legibility-target:** future maintainers of `bless_manifest`

- **A colon in the config path disables the diff.** `${old%%:*}` splits at the first colon, so with `CLAUDE_DEVC_CONFIG_DIR=…/a:b`, `[ -f ]` tests a nonexistent prefix and the comparison is skipped silently. P8: Dockerfile tampered, re-bless, `Changed since` count 0. This is rare, but it fails open on legibility. Use two parallel variables or arrays instead of a `:`-joined string.
- **Temp files.** Fact-check confirmed two cases. A mktemp-2 failure leaves `.manifest.XXXXXX`, and nothing traps SIGINT between the mktemps and the `mv`s. A leftover dotfile is never read as a manifest. `enforcement_files` lists named files, egress, projects and claude-home only, so it does not affect hashing. It does land in the Docker build context (`devcontainer.json: "context": "${localEnv:CC_CONFIG_DIR}"`), but no `COPY` picks it up. The temp files sit in the config dir, so `mv` is a same-filesystem rename, and `mktemp` uses O_EXCL, so there is no symlink-race concern. A `trap 'rm -f …' RETURN INT` would tidy it.
- **Manifest mode is now 0600**, inherited from mktemp (seen in the probe dir listing). Both readers run as the same user, and the image never copies the manifests, so this is slight hardening and changes nothing for availability.
- **mv-2 failure** leaves host-tools.sha256 new and manifest.sha256 old. `check_manifest` then refuses launches (fails closed), while cc-push trusts the new host tools. Same-filesystem rename failure is rare. Swapping the order (boundary first) would make the half-state fail closed for cc-push too, but that is low value.
- **Source-set test** misses `.` and mid-line `source` (fact-check). The primitive sweep below found no such call site at b1539159, so the test is correct today and only weak against future additions.

## Untested bypass candidates (move #11)

| # | Candidate | Disposition |
|---|---|---|
| 1 | Delete manifests, default dir, env var elsewhere (pass-1 P2) | **Tested** (P4a): refused. F3 fixed |
| 2 | Plant install.sh + delete manifests + env var elsewhere | **Tested** (P4b): bypass, finding 4 (no capability gain) |
| 3 | Plant install.sh, env var unset | **Tested** (P4c): refused |
| 4 | Symlinked install.sh | **Tested** (P4d): accepted as the marker, finding 4 |
| 5 | Tamper scan + Dockerfile together (pass-1 F1) | **Tested** (P1): both shown. Dir-split variant (P5) misleads, finding 2 |
| 6 | Tamper all three host tools | **Tested** (P7): only the first is named before the bless, finding 1 |
| 7 | Delete both manifests + boundary tamper | **Tested** (P2): bless prints nothing, finding 1 |
| 8 | Colon in the config path | **Tested** (P8): diff skipped, finding 5 |
| 9 | **Untested:** swap a file between hash and `source` (TOCTOU), or hardlink | Not exercised. Needs a timed race. Accepted (plan B7, pass-1 F4) |
| 10 | **Untested:** repoint the PATH link to a dir with a self-consistent manifest | Not exercised. Accepted (plan B6), and the same before this diff |

Rows 9 and 10 keep `verify_host_tools` out of Endorsement Claims as a guardrail.

## Endorsement Claims

- **Claim:** With the launcher dir equal to the config dir, a host-tool refusal prints `check_manifest`'s boundary diff and the "BOUNDARY config changed too" note before exiting 1.
  **Location:** `devcontainer-config/cc-isolated.sh:697-708`
  **Evidence:** executed (P1)
  **Verified:** P1's stderr contained the `Dockerfile` hash diff and the note. Exit status 1.
  **Not verified:** the case where `$CC_ISOLATED_DIR` is not `config_dir` (P5 refutes it there, finding 2).
  **route: code-fact-check**
- **Claim:** A `compute_host_tools_manifest` failure during bless leaves host-tools.sha256 byte-identical and leaves no temp file.
  **Location:** `devcontainer-config/cc-isolated.sh:264-269`
  **Evidence:** executed (P6, with cc-push.sh removed)
  **Verified:** `ERROR: nothing blessed.`, `cmp` equal to the pre-bless copy, `ls -A` showed no dotfile.
  **Not verified:** mktemp-2 failure and mv-2 failure (the fact-check says both leak, finding 5).
- **Claim:** A launch with only cc-push.sh mismatched prints a WARNING naming cc-push.sh and continues past the host-tool gate.
  **Location:** `devcontainer-config/cc-isolated.sh:713-718`
  **Evidence:** executed (P3; it reached the `devcontainer CLI not found` check next)
  **Verified:** P3 stderr.
  **Not verified:** whether the warning stays visible once a real devcontainer build's output follows it.
- **Claim:** In an installed dir without install.sh, deleting both manifests no longer skips verification, whatever the env var says.
  **Location:** `devcontainer-config/cc-push.sh:156`, `cc-isolated.sh:234`
  **Evidence:** executed (P4a)
  **Verified:** cc-push refused with `no host-tool manifest`.
  **Not verified:** the launcher copy under the same conditions (byte-identical by the pinned test, but not run here).

## Primitive sweep

Primitive: `source` / script execution of host-tool files (exec sink)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-isolated.sh:662` `source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` | S1, S2 | `verify_host_tools … cc-exit-scan.sh cc-gitdir.sh` | Guarded. Opt-out narrowed (finding 4). TOCTOU accepted |
| `cc-exit-scan.sh:12` `source …/cc-gitdir.sh` | S1 | Transitively guarded: same canonical dir, the scan is not a symlink | Cleared |
| `cc-push.sh:187` `source "$CC_PUSH_DIR/cc-gitdir.sh"` | S1, S2 | `verify_host_tools … cc-push.sh cc-gitdir.sh` | Guarded. Finding 4 |
| `cc-push.sh` itself, via the PATH link | S1, S5 | Self-check plus the launcher's new WARNING | Partial. A prepend runs on direct invocation (P3b, inherent) |
| `cc-isolated.sh` itself | S1, S5 | `check_manifest` after top-level code | Not changed by this diff |
| `.` (dot) sourcing anywhere in the four files | — | — | None found (`rg` sweep; the `.` hits at `cc-exit-scan.sh:363, 892` are string comparisons) |

Primitive: file write into the config dir (B6, reference-file writes)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-isolated.sh:263-264` `mktemp "$(config_dir)/.manifest.XXXXXX"` / `.host-tools.XXXXXX` | S3 | O_EXCL (mktemp) | Cleared. Leak on mktemp-2 failure or interrupt, finding 5 |
| `cc-isolated.sh:266` `rm -f "$new_m" "$new_h"` | internal | — | Cleared |
| `cc-isolated.sh:274-275` `mv -f` ×2 | internal | same-filesystem rename | Cleared. Half-state on mv-2 failure fails closed for launches, finding 5 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Bless commits before it shows; refusal names one host tool; no-prior-manifest prints nothing | Low | B5, B1 | `cc-isolated.sh:240-284, 697-708` | High |
| 2 | Refusal checks `config_dir` but recommends blessing `$CC_ISOLATED_DIR`; says "unchanged" | Low | B5, B3 | `cc-isolated.sh:700-706` | High / Medium reach |
| 3 | `--list` says "launches refuse" for cc-push-only drift | Informational | B5 | `cc-isolated.sh:458-462` | High |
| 4 | Residual opt-out via planted install.sh + env var elsewhere | Informational | B4 | `cc-isolated.sh:234`, `cc-push.sh:156` | High |
| 5 | Colon path skips diff; temp leaks; 0600 mode; mv order; source-set test | Informational | B6, B5 | `cc-isolated.sh:260-275` | High / Medium |

## Overall Assessment

All four pass-1 fixes hold on the default install. F1's Medium is closed there: P1 shows a boundary change made alongside a host-tool change. F2 and F3 are closed as recommended, and F4d is closed for the compute-failure path. The fixes add no new capability for an attacker. The temp files are O_EXCL, same-filesystem and never hashed, and the install.sh marker can only be planted at a cost equal to editing a tool. What remains is legibility at B5, the human-facing step this control depends on. The refusal names only the first changed host tool. Bless commits before it shows and prints nothing when the prior manifests are gone (finding 1). On a custom install with the env var unset, the refusal's new sentence states the boundary is unchanged when it is not (finding 2). Both can be fixed in place in a few lines and are not architectural. The most important fix is to make the refusal list every mismatched host tool and to make bless announce "no previous manifest". No findings within the code paths read rise above Low. Endorsement claims are executed, with their `Not verified` hops named, and one claim is routed to code-fact-check.

## Goal-Alignment Note

The goal is to let host-tool edits avoid the boundary rebuild and probe while keeping tamper detection, and to make sure the host-tool refusal never lets a boundary change through unseen. This pass achieves that on the default install. The rebuild and probe are still avoided (unchanged from pass 1), the boundary diff now shows in the refusal, cc-push drift is noticed again, and deleting manifests no longer opts out. The remaining gaps all concern what the human sees between refusal and bless: one tool named rather than all, accept-then-show, and the dir-split note. They work against the "the bless is the review" comment the fix added. None needs a redesign, and none blocks the unit's purpose under row 45. Findings 1 and 2 are cheap enough to fold into the current fact-check fix round. Finding 3 overlaps an item the author is already fixing (the `--list` message).
