Commit: 840f39b0

# Security Review — Q-089 unit A2 (feat/q089a2-cc-push-self-check)

**Scope:** `git diff f2533b33 840f39b0`, which covers `devcontainer-config/cc-push.sh`, `test/cc-isolated-functions.bats` and `test/cc-push.bats`. A1 (f2533b33) and unit B (`feat/q089b2-host-tool-gate`, 613c0ade, decision log row 71) were read as committed sibling context.
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report-q089a2.md` (17 verified, 2 mostly accurate, 2 incorrect). Its probes P1-P9 are cited as FC-Pn. Advisory history: `security-review-2026-10-14-q089a.md` and `-pass2.md`.
**Threat model:** decision log row 45, as amended by row 71: non-targeted host-side tampering, such as a malicious npm postinstall. This is defence in depth, not protection against a targeted attacker.

Probe environment for every `executed` item below: a `git archive 840f39b0 devcontainer-config` extract in `/home/node/.claude/jobs/00bcf178/tmp/sr-q089a2.pEOjSd/src`. `HOME`, `CLAUDE_DEVC_CONFIG_DIR`, `TMPDIR` and `CC_PUSH_CLONES_DIR` pointed into that dir, with `LC_ALL=C`. Every run was under `timeout 20`, and the probe script is in `.../scripts/probe.sh`. No real config dir was touched, install.sh was not run, and no process was left running. Results are cited as Qn.

## Trust Boundary Map

```
B1 (new):      [installed cc-gitdir.sh on host disk] → [verify_host_tools: sha256 vs host-tools.sha256, :187-191] → [source into cc-push's shell, :193]
B2 (new, partial): [installed cc-push.sh on host disk] → [bash runs :1-186 unchecked, then self-hash at :187-191] → [push logic :192-581]
B3 (new):      [caller env CLAUDE_DEVC_CONFIG_DIR/HOME + dir contents (install.sh, manifests)] → [repo-checkout exemption, :157-159] → [check skipped]
B4 (existing, now load-bearing): [PATH after safe_path + caller's exported functions] → [name resolution of readlink/dirname/awk/sha256sum/cut] → [the hash comparison itself]
```

Input-source classification:

```
S1: installed cc-push.sh / cc-gitdir.sh  — runtime-mutable (any same-uid host process) — UNTRUSTED toward exec/source until the hash matches
S2: host-tools.sha256                    — runtime-mutable (written by bless; same-uid writable) — trusted as the integrity reference only under the
                                            non-targeted model; a re-hashed manifest defeats the check (row 71 "Not covered", Q3)
S3: CLAUDE_DEVC_CONFIG_DIR / HOME env    — request-time (caller env) — used only to deny the exemption; UNTRUSTED as a guard input (Q4)
S4: PATH after safe_path, exported fns   — request-time (caller env) — trusted for tool resolution only as far as the host PATH is trusted (pre-existing: git is resolved the same way)
S5: presence of $dir/install.sh          — runtime-mutable (filesystem marker) — the only positive mark for "repo checkout"; content never read
S6: BASH_SOURCE[0] via readlink -f       — request-time (symlink on PATH) — names the dir that is checked AND sourced from, so check and use agree
```

The diff adds one new trust transition. Bytes on the host disk (S1) are now hashed against a same-uid-writable reference (S2) before cc-gitdir.sh is sourced (B1), and before cc-push.sh reaches its push logic (B2). B1 is complete for its purpose, because the check lives in a different file from the one it guards. B2 is partial by construction. The check lives inside the file it guards, so bytes above it run first, and bytes that remove it are never checked. Row 71 accepts this and points to the launcher's WARNING (A1) and `--list` as the detective control. B3 and B4 bound how strong the check is. Neither is introduced as a regression.

## Findings

#### 1. The `--help` text promises "nothing unchecked runs", but the self-check is partial

**Severity:** Low
**Location:** `devcontainer-config/cc-push.sh:35-39`
**Boundary:** B2
**Move:** 2 (implicit assumption), 3 (error path)
**Confidence:** High
**Legibility-target:** the user reading `cc-push --help`. `usage()` prints this header block, so the claim is user-facing assurance, not just a code comment.

**Evidence (verbatim):**
```
# One exception, before any of that: when this installed copy or the cc-gitdir.sh
# beside it differs from what the bless recorded in host-tools.sha256 (or that
# file is missing or a symlink), cc-push
# exits 1 before parsing anything, --help included (decision log row 71): nothing
# unchecked runs.
```
Probe results:
- FC-P1: code above the check runs before the refusal.
- FC-P3: a tamper that sets `if false; then` exits 0 and runs its payload.
- Q7: a whole-file overwrite (`#!/usr/bin/env bash` + `touch`) gives `exit=0`, `Q7 replacement ran unrefused`.
- Q8: a line inserted after the shebang gives `exit=1 :: ERROR: ... cc-push.sh changed since t` and `Q8 prepended line ran`.

A user who reads the help text can conclude that a changed cc-push refuses before doing anything. They may then treat the launcher's `WARNING: ... do not run cc-push until you have reviewed it` as redundant. Under the stated threat model, the tamper shapes the self-check misses are the generic ones. A blind overwrite (Q7) and a prepend (Q8) both run their payload. This is the one place where the compensating control's message and the tool's own message disagree. No code change is needed: row 71 already accepts the gap.

**Recommendation:** Reword the header to match row 71. For example: "nothing past this check runs from a changed copy. Code above it runs first, and a copy rewritten so that it never reaches the check is caught only by cc-isolated's warning and `--list`." Keep the claim's strength aligned with the launcher's WARNING text.

#### 2. The commit message and test claim "a tampered cc-push.sh is refused without running", but the test tamper is an inert comment

**Severity:** Informational
**Location:** `test/cc-push.bats:809-813`; commit 840f39b0 message, paragraph 2
**Boundary:** B2
**Move:** 11 (bypass enumeration: tested vs listed)
**Confidence:** High
**Legibility-target:** the next maintainer who moves the check or edits the prologue. Today the regression pin for the "does not run" half is the cc-gitdir.sh step only.

**Evidence (verbatim):**
```
  printf '\n# edited\n' >> "$d/cc-push.sh"
  run bash "$d/cc-push.sh" --help
  [ "$status" -eq 1 ]
  [[ "$output" == *"cc-push.sh changed since the last bless"* ]]
```
Commit message: `Tests: a tampered cc-gitdir.sh and a tampered cc-push.sh are both refused without running`.

The property does hold for edits below the check. In Q9, `touch` inserted at line 400 gave `exit=1` and `Q9 did not run`. But no test observes it, so the commit message claims a result its own test cannot produce. The `--help` → 1 assertion does pin the check ahead of argument parsing. That limits how far a future move of the check could drift, so this is not a coverage hole for the ordering, only for the no-run claim.

**Recommendation:** Change the tamper to `printf 'touch %q\n' "$M/push-ran" >> "$d/cc-push.sh"` and assert `[ ! -e "$M/push-ran" ]`. Before merge, reword the commit message to "a tampered cc-gitdir.sh is refused without running; a changed cc-push.sh is refused".

#### 3. The check is only as strong as PATH and the caller's exported functions

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:158, 173-174, 187`
**Boundary:** B4
**Move:** 1 (trust per consequence)
**Confidence:** Medium
**Legibility-target:** row 71's "Not covered" list. It names a repointed PATH *symlink* for cc-push, but not a planted coreutils shim.

**Evidence (verbatim):**
```
    want="$(awk -v f="$f" '$2 == f { n++; h = $1 } END { if (n == 1) print h }' "$m")"
    have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"
```
`safe_path` (`:122-140`) drops only relative entries at this point. Q11: a failing `sha256sum` shim first on PATH fails closed (`exit=1 ... changed since the last bless`). A shim that prints the blessed hash would pass. That case was not run (see Untested candidates). It is self-evident from the code.

This is not a regression. cc-push already resolves `git` (`:229`) the same way, and a forged `git` is strictly more powerful. It is listed so that the claim "cc-push verifies itself" is not read as independent of the host PATH. A writable absolute PATH dir ahead of `/usr/bin`, such as an npm global bin, is the one place where the stated npm-postinstall threat meets this code. A non-targeted payload would have to plant `sha256sum` or `awk` specifically, which is why confidence is Medium on relevance.

**Recommendation:** No code change. Calling `/usr/bin/sha256sum` by absolute path would not help while `git` is resolved by name. Add "a planted `sha256sum`/`awk` ahead of coreutils on PATH" to row 71's "Not covered" list.

#### 4. The exemption's "not the config dir" clause protects only when the caller's env names the install dir

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:156-159` (comment at `:147-151`)
**Boundary:** B3
**Move:** 5 (invert the access-control model)
**Confidence:** High
**Legibility-target:** the comment at `:147-151` and row 71's "planted install.sh together with deleted manifests" entry.

**Evidence (verbatim):**
```
  cfg="$(readlink -f -- "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}" 2>/dev/null || true)"
  if [ -f "$dir/install.sh" ] && [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
```
- Q4: install dir ≠ `CLAUDE_DEVC_CONFIG_DIR`, `install.sh` planted, `host-tools.sha256` removed (no `manifest.sha256` present), cc-gitdir.sh tampered. Result: `exit=0` and `Q4 payload ran (exempt)`.
- Q5: the same dir named as `CLAUDE_DEVC_CONFIG_DIR` gives `exit=1 :: ERROR: no host-tool manifest`.

install.sh takes `DEST="${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"` (`install.sh:1310`). A user who installed to a custom DEST and runs cc-push without that variable exported gets no protection from the fourth clause. Row 71 already accepts the three-step tamper (plant install.sh, delete both manifests, edit). It is listed here because the comment presents the config-dir clause as unconditional.

**Recommendation:** Reword the comment to say "and not `$CLAUDE_DEVC_CONFIG_DIR` (or the default) as set when cc-push runs". No code change under the threat model.

## Untested bypass candidates

| Candidate | Why not tested |
|---|---|
| TOCTOU: rewrite cc-gitdir.sh between the hash (`:188`) and `source` (`:193`). Or rewrite cc-push.sh in place after the hash, since bash keeps reading the script file as it runs | Needs a racing writer. Row 71 lists TOCTOU as not covered. Static reading confirms the window exists. |
| A `sha256sum` / `awk` shim, or an exported bash function `BASH_FUNC_sha256sum%%`, that prints the blessed hash | Outside the threat model, and equivalent to forging `git`. Only the fail-closed variant (Q11) was run. |
| A repointed `~/.local/bin/cc-push` symlink to an attacker dir that carries its own matching manifest | Row 71 "Not covered". It is consistent by construction, because S6 names both the dir checked and the dir sourced from. |

Tested and closed (for the record): a symlinked cc-gitdir.sh with identical content is refused (Q2). A binary-mode `*name` manifest fails closed (Q6). A CRLF manifest fails closed (Q10). A failing `sha256sum` fails closed (Q11). FC-P4/P8b: a symlinked manifest is refused, and so is a duplicate entry. A re-hashed manifest is accepted (Q3), as row 71 says.

## Endorsement Claims

`verify_host_tools` has untested bypass candidates (above), so under move 11 the guardrail itself does not appear here. The scoped claims below concern what the diff does *around* it.

- **Claim:** The diff adds no caller-controlled input to the path that is sourced. `CC_PUSH_DIR` is assigned unconditionally from `readlink -f` of `BASH_SOURCE[0]`, and the same variable feeds both the check and the `source`.
  **Location:** `devcontainer-config/cc-push.sh:187-193`
  **Evidence:** read-static
  **Verified:** Every reference to `CC_PUSH_DIR` and `host_tools_err` in the file: `:187`, `:188`, `:189` and `:193` only.
  **Not verified:** Whether `readlink` resolves to coreutils at runtime (B4, Finding 3).
- **Claim:** Against main, A2 only adds a refusal before cc-push's existing logic, and none of the pre-existing lines change behaviour. The only removed line is the inline `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"`, which now uses the same expression through `CC_PUSH_DIR`.
  **Location:** `git diff f2533b33 840f39b0 -- devcontainer-config/cc-push.sh`
  **Evidence:** read-static
  **Verified:** The full 57-line hunk. The only `-` lines are the old `source` line and the old comment line.
  **Not verified:** The tests that source cc-push.sh from the repo dir. They depend on the exemption (install.sh beside it), and that dependence was checked only via the fact-check's passing 48/48 run.
  **route: code-fact-check**
- **Claim:** A tamper below the check in an installed cc-push.sh does not run.
  **Location:** `devcontainer-config/cc-push.sh:187-191`
  **Evidence:** executed
  **Verified:** Q9 (line 400 `touch`: refused, did not run), FC-P2 (post-check and EOF lines did not run).
  **Not verified:** An in-place rewrite racing bash's incremental reads (TOCTOU).

## Primitive sweep

Primitive: execution of host files (`source` / script execution)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-push.sh:193` `source "$CC_PUSH_DIR/cc-gitdir.sh"` | S1 via S6 | `verify_host_tools` at `:188` | cleared within the model. TOCTOU is listed as untested. |
| `cc-push.sh:1-186` (bash executing its own file) | S1 | none (it precedes the check) | Finding 1 (documentation only; row 71 accepts it) |
| `cc-push.sh:192-581` (bash executing its own file) | S1 | self-hash at `:188` | cleared for edits (Q9, FC-P2). Not for a rewrite that removes the check (FC-P3, Q7): row 71 accepts it, and A1's WARNING detects it. |

Primitive: PATH-resolved process exec inside the check
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:158` `readlink` | S3, S4 | `safe_path` (absolute entries only) | Finding 3 (Informational) |
| `:173` `awk` | S2, S4 | as above | Finding 3 |
| `:174` `sha256sum`, `cut` | S1, S4 | as above | Finding 3. Fails closed on error (Q11). |
| `:187` `readlink`, `dirname` | S6, S4 | as above | Finding 3. Pre-existing on main's `source` line. |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | The `--help` header promises "nothing unchecked runs", but the self-check is partial | Low | B2 | `cc-push.sh:35-39` | High |
| 2 | "Refused without running" is untested for cc-push.sh, because the test's tamper is an inert comment | Informational | B2 | `test/cc-push.bats:809-813`, commit msg | High |
| 3 | The check's strength is bounded by PATH and exported functions | Informational | B4 | `cc-push.sh:158,173-174,187` | Medium |
| 4 | The config-dir clause of the exemption depends on the caller's env | Informational | B3 | `cc-push.sh:147-159` | High |

## Overall Assessment

No findings that need a code change were found within the code paths read. Endorsement claims are pending execution verification where marked.

**Does A2 weaken anything compared with main? No.** On main, cc-push checked nothing and ran unconditionally. A tampered copy was noticed only because `check_manifest` blocked the next *launch*. A2 only adds a refusal ahead of the existing logic. The safety trade against main sits in A1, which downgrades a cc-push change from blocking a launch to a WARNING. A2 is what makes that downgrade defensible.

**Is the self-check worth having, given that a self-skipping tamper disables it?** Yes. Coverage by tamper shape, executed:
- **Fully preventive:**
  - any edit to cc-gitdir.sh, because the check lives in another file (test 48, FC-P6)
  - any edit to cc-push.sh below line 191, which is the push logic and about 67% of the file's 581 lines (Q9, FC-P2)
- **Partly preventive:** a prepended payload runs, but the push itself is refused (Q8, FC-P1).
- **Not caught:** a blind overwrite or an edit that removes the check (Q7, FC-P3). These fall back to A1's detective WARNING and `--list`.

The preventive half guards the operation cc-push exists for: running git against container-authored state without executing it. A detective warning on its own fires only at the next launch, and only if the user reads it. The remaining cost is availability: a local edit needs a re-bless. That cost fails closed with a clear message.

The single most important item is Finding 1. The user-facing `--help` must not promise more than row 71 accepts, otherwise it undercuts the launcher's warning, which is the only control for the uncaught shapes.

Merge note (not security): this unit cites "decision log row 71", which exists only on unit B. Land A2 together with B, or after it.

## Goal-Alignment Note

The goal is a security design review of A2 before merge. The question is whether cc-push's self-check against host-tools.sha256 is sound, worth having, and no weaker than main. The mechanism does what row 71 says. It fails closed on every malformed-manifest, symlink and missing-file case probed. It checks and sources the same resolved directory. Only a positively marked checkout is exempt, and the gaps it leaves are exactly the ones row 71 lists, plus a PATH-shim note (Finding 3). The divergence from the goal is in legibility, not code. The `--help` header (Finding 1) and the commit message and test (Finding 2) claim more than the mechanism delivers. Rewording both brings the unit in line with its own decision record. Nothing here argues against merging A2 once those two texts are corrected.
