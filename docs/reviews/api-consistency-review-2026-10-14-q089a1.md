Commit: f2533b33

# API Consistency Review: Q-089 unit A1 (host-only tools get their own trust manifest, launcher side)

**Scope:** `git diff 4ab9a51f f2533b33` (`devcontainer-config/{cc-exit-scan,cc-gitdir,cc-isolated,install}.sh`, `test/cc-isolated-functions.bats`). Files read with `git show f2533b33:<path>`. Sibling context only: A2 (`feat/q089a2-cc-push-self-check`, 840f39b0) and B (`feat/q089b2-host-tool-gate`, 613c0ade).
**Date:** 2026-10-14 (loop pass, iteration 1 of 3, full scope)
**Based on:** `docs/reviews/code-fact-check-report-q089a1.md` (Commit f2533b33: 28 claims, 21 verified, 7 mostly accurate, 0 incorrect). Prior pass, advisory: `api-consistency-review-2026-10-14-q089a.md` at b1539159 (dce5b039), and the rubric `code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md`.
**Probes:** run under `timeout 30` in `mktemp -d` dir `/home/node/.claude/jobs/00bcf178/tmp/api-a1.oPKeV0/`, extracted with `git archive f2533b33 devcontainer-config`, with `LC_ALL=C` and `HOME`, `TMPDIR` and `CLAUDE_DEVC_CONFIG_DIR` all inside it. A stub `devcontainer` (exit 0) was on PATH, and `bin/cc-isolated` was a symlink to the copied `cfg/cc-isolated.sh`. The scripts are `../api-a1-probe.sh` (P1 to P7) and `../api-a1-probe2.sh` (P8). Nothing touched the real config dir, and no process was left running.

## Baseline Conventions

The consumer-facing surfaces are the `cc-isolated` CLI's stdout/stderr text and exit codes, the config dir's file layout, and the shell function names that bats (and unit B's gate test) import by sourcing `cc-isolated.sh`. No script in the repo parses `--list` or `--bless` output: `git grep` over `test scripts hooks` finds only bats assertions, plus `install.sh:607`, which runs `--bless` and passes its output through.

- **Exit codes** (decision log #58, header `cc-isolated.sh:19-31`): 0 success, 1 error or refusal, 2 bad usage. `--list` exits 0 whatever state it reports, for example `verified live: NO`.
- **Error lines**: `echo "ERROR: <what> — refusing to <what>." >&2`, then indented remedy lines, with the command on its own four-space-indented line (`check_manifest`, `cc-isolated.sh:320-338`).
- **Bless remedy command**: the diff adds `bless_cmd()` (`:309-317`), whose comment says it "names CLAUDE_DEVC_CONFIG_DIR when it is set, so a hint printed for a non-default dir does not bless the default one" (fact-check Claim 7: Verified). `check_manifest` now uses it at both of its call sites (`:325`, `:334`). Before this diff, every hint was a bare `$0 --bless` or `cc-isolated …`. Hints elsewhere in `--list` use the literal `cc-isolated` (`:475` `(run: cc-isolated --probe-only <repo>)`).
- **`--list` line shape** (`:470-478`): one line per state, `<Subject> <value> — <attribute>: <state>`, with an em-dash, `yes`/`NO` and a parenthesised remedy. A missing state is its own sentence: `No blessed config (run devcontainer-config/install.sh).`
- **`--bless` output** (`:293-305`): `Blessed <path> (<N> entries):`, the manifest, a blank line, then `Blessed config:` / `Verified live:`.
- **Config dir files**: `<content>.sha256` beside each other (`manifest.sha256`, `verified-live.sha256`).
- **Function names**: `<set>_files`, `compute_<thing>`, `<noun>_path`, `check_<thing>` for a hash gate, and `verif*` for the live-probe receipt (prior review, Finding 6).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `host_tool_files` | function | `enforcement_files` | `devcontainer-config/cc-isolated.sh:128` | Consistent: `<set>_files` |
| `host_tools_path` | function | `manifest_path`, `verified_path` | `cc-isolated.sh:72-82` | Minor, carried over: prior Finding 6. The rubric left C2 as Consider, so it is not re-raised here |
| `compute_host_tools_manifest` | function | `compute_manifest` | `cc-isolated.sh:153` | Consistent |
| `verify_host_tools` | function | `check_manifest`; `is_verified_live`, `record_verified_live` | `cc-isolated.sh:96-116`, `:320` | Minor, carried over (prior Finding 6, rubric C2 Consider) |
| `bless_cmd` | function | `rebuild_hint`, `usage` | `cc-isolated.sh:539`, `:706` | Consistent: a printer named by what it prints. It is applied unevenly, though: Finding 1 |
| `host-tools.sha256` | on-disk file | `manifest.sha256`, `verified-live.sha256` | `cc-isolated.sh:76-82` | Consistent |
| `CC_ISOLATED_DIR`, `HOST_TOOLS_ERR` | global | `GIT_EXIT_SCAN_*` | `cc-exit-scan.sh` | Consistent: UPPER_SNAKE |
| `Host tools … - match the bless` / `Host tools: CHANGED (…)` | `--list` line | `Blessed config $b — verified live: yes` / `… NO (run: …)` / `No blessed config (…)` | `cc-isolated.sh:473-478` | Inconsistent shape: an ASCII hyphen and no colon on the OK line, a colon on the CHANGED line, and CHANGED shown for an absent manifest (Findings 2, 3) |
| `  launches refuse: …` / `  launches warn (cc-push changed) but run` / `  cc-push refuses: …` | `--list` sub-line | none: `--list` had no indented sub-lines before this diff | none — searched `list_projects` (`cc-isolated.sh:469-512`) | New convention, readable. Informational |
| `No previous <file>: every entry below is new to this bless.` / `Changed since the last bless (<file>):` | `--bless` line | `ERROR: installed config changed since last bless` | `cc-isolated.sh:331` | Consistent (the wording differs by one article) |
| `Blessed host tools in <path> (not boundary config; no probe needed):` | `--bless` line | `Blessed <path> (<N> entries):` | `cc-isolated.sh:293` | Minor asymmetry (Finding 4) |
| `ERROR: <reason> — refusing to run the session-exit scan's code.` | error | `ERROR: installed config changed since last bless — refusing to build/launch.` | `cc-isolated.sh:331` | Consistent shape. The scope wording is off for `--register`/`--probe-only` (Finding 6) |
| `WARNING: <reason> — do not run cc-push until …` | warning | `WARNING: $ws has no commits and no remote — …`, `WARNING: no ~/.ssh/canary …` | `cc-isolated.sh:604`, `:803` | Consistent |

## Findings

#### 1. `--list`'s host-tool remedy ignores `CLAUDE_DEVC_CONFIG_DIR`, which is the hazard the diff's own `bless_cmd` exists to prevent

**Severity:** Inconsistent
**Location:** `devcontainer-config/cc-isolated.sh:493` (also `:238` and `:747`)
**Move:** 2 (naming/convention), 4 (error consistency)
**Confidence:** High
**Legibility-target:** a user with a non-default config dir who copies the remedy from `--list` into another shell

Precedent: the `$(bless_cmd)` remedy used in `devcontainer-config/cc-isolated.sh:311-317,325,334` (added by this diff)

Evidence: `echo "Host tools: CHANGED (review, then: cc-isolated --bless)"`. In probe P3, with `CLAUDE_DEVC_CONFIG_DIR=$P/cfg` set, `--list` printed `Host tools: CHANGED (review, then: cc-isolated --bless)`. Pasted into a shell without that variable, the command blesses `~/.config/claude-devcontainer`, not the dir that was listed. That is the case `bless_cmd`'s comment names: "so a hint printed for a non-default dir does not bless the default one". The diff has three spellings of the same remedy:
- `bless_cmd`, at `:325` and `:334`;
- the literal `cc-isolated --bless`, at `:493` and inside `verify_host_tools` at `:238`;
- `printf '    CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless\n' "$CC_ISOLATED_DIR"`, at `:747`.

In the boundary-changed refusal (probe P8), two different bless commands print in the same block: `CLAUDE_DEVC_CONFIG_DIR=…/cfg …/bin/cc-isolated --bless` from check_manifest, then `CLAUDE_DEVC_CONFIG_DIR=…/cfg cc-isolated --bless`. The `:238` copy is shared byte for byte with cc-push (A2), so it cannot call `bless_cmd`. In the launcher it only repeats the remedy that the refusal then gives.

**Recommendation:** At `:493`, print `$(bless_cmd)`, or the `:747` form with `$(config_dir)`. Pick one spelling for `:747` and `bless_cmd`: either make `bless_cmd` take the dir as an argument and use it at `:747`, or accept the literal `cc-isolated` everywhere. Add a bats assertion that `--list` names the dir when `CLAUDE_DEVC_CONFIG_DIR` is set.

#### 2. `--list` labels an absent host-tool manifest "CHANGED", where its sibling line reports an absent manifest as "No blessed …"

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:488-499`; pinned by `test/cc-isolated-functions.bats:987-990`
**Move:** 8 (nullability: absent state vs changed state), 4
**Confidence:** High
**Legibility-target:** a user reading `--list` on a fresh or partial install

Precedent: an absent state is its own sentence, `No blessed config (run devcontainer-config/install.sh).`, used in `devcontainer-config/cc-isolated.sh:478`

Evidence: probe P6 (host-tools.sha256 removed) printed `Host tools: CHANGED (review, then: cc-isolated --bless)` and then `  launches refuse: no host-tool manifest at …/host-tools.sha256 (re-run install.sh, or cc-isolated --bless after reviewing)`. The test at `:987` runs `--list` against `no/such/cfg` and asserts `*"Host tools: CHANGED"*"launches refuse: no host-tool manifest"*`. In that state the line above it reads `No blessed config`. Nothing has been blessed, so nothing has changed. The same mislabel appears in the launcher refusal: `Also changed (cc-push refuses until re-blessed): no host-tool manifest at …` (P6b; fact-check Claim 12 notes it). The state is rare after a normal `install.sh`, which blesses (`install.sh:607`).

**Recommendation:** Branch on `[ -f "$(host_tools_path)" ]`. When the file is absent, print `No blessed host tools (run devcontainer-config/install.sh, or …--bless).` and skip the sub-lines. Keep `CHANGED` for real mismatches, and update the `:990` assertion.

#### 3. The two `--list` host-tool lines differ in shape from each other and from the `Blessed config` line above them

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:491`, `:493`
**Move:** 2, 7 (asymmetry)
**Confidence:** High
**Legibility-target:** anyone grepping `--list` output, human or script

Precedent: `Blessed config $b — verified live: yes|NO (run: …)` (one subject, an em-dash and a `yes`/`NO` state) used in `devcontainer-config/cc-isolated.sh:473-475`

Evidence: P2 printed `Host tools cc-exit-scan.sh cc-gitdir.sh cc-push.sh - match the bless`, and P3 printed `Host tools: CHANGED (review, then: cc-isolated --bless)`. The OK form has no colon and uses an ASCII ` - `, which comes from `tr '\n' ' '` leaving a trailing space before `- match`. The CHANGED form has a colon and no file list. A consumer who greps `^Host tools:` sees only the bad state, and one who greps `^Host tools ` sees only the good one. The em-dash line directly above sets the house style.

**Recommendation:** Use a single prefix with a state word, for example `Host tools (cc-exit-scan.sh cc-gitdir.sh cc-push.sh) — match the bless: yes` / `…: NO (review, then: …)`, or at least `Host tools: match the bless (…)` / `Host tools: CHANGED (…)`. Update the `:1021` and `:1025` assertions.

#### 4. The `--bless` host-tools block drops the entry count its boundary sibling prints

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:293`, `:296`
**Move:** 7
**Confidence:** High
**Legibility-target:** a user reviewing bless output, and any `--bless` consumer

Precedent: `Blessed <path> (<N> entries):` used in `devcontainer-config/cc-isolated.sh:293`

Evidence: P1 printed `Blessed …/cfg/manifest.sha256 (16 entries):` and then `Blessed host tools in …/cfg/host-tools.sha256 (not boundary config; no probe needed):`. The second line has no count and adds `in`. The count is how a reviewer catches a list that grew or shrank.

**Recommendation:** `Blessed $(host_tools_path) ($(wc -l < …) entries; host tools, not boundary config, no probe needed):`, or any form that keeps `Blessed <path> (<N> entries…`.

#### 5. `--bless`, `--register` and `--list` stdout changed shape (additive, but the first line moved)

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:277-298` (bless_manifest, which `register_project` also calls at `:464`), `:480-500` (list_projects)
**Move:** 3 (consumer contract), 6 (versioning)
**Confidence:** High
**Legibility-target:** anyone with a wrapper script or alias that reads these outputs

Evidence: before the diff, the first stdout line of `--bless` was `Blessed <path> (N entries):`. Now it can be `No previous manifest.sha256: every entry below is new to this bless.` (P1) or `Changed since the last bless (host-tools.sha256):` (P5), followed by raw `<`/`>` diff lines. `--register` prints the same prelude, because it re-blesses. `--list` gains a line between `Blessed config …` and the blank line, and indented sub-lines when something has changed. No in-repo consumer parses any of this (searched `test/ scripts/ hooks/`; `install.sh:607` passes the output through). Every existing line is still printed in its original form, so a `grep '^Blessed config'` keeps working, but a `head -1` would not. `--list` still exits 0 when the host tools have changed, which matches its `verified live: NO` precedent, so a script can detect that state only from the text.

**Recommendation:** None required. If wrappers are expected, mention the new prelude in the guide (Finding 7).

#### 6. The refusal says "the session-exit scan's code" but also blocks `--register` and `--probe-only`, and `--register` is refused although it blesses

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:734-749`
**Move:** 4
**Confidence:** Medium
**Legibility-target:** a user running `--register` or `--probe-only` after editing a host tool

Evidence: P4c, `cc-isolated --register ws --profile python`, printed `ERROR: …/cc-exit-scan.sh changed since the last bless — refusing to run the session-exit scan's code.` and exited 1. `--register` runs no scan code, and it ends in `bless_manifest` (`:464`), which would bless both manifests and print the diff. The analogous refusal names what it refuses: `refusing to build/launch.` (`:331`). The blanket refusal is the safe choice and is documented in the comment at `:694` (fact-check Claim 9). The message, though, suggests the refused action needed the scan.

**Recommendation:** Reword the line to the policy (for example `— refusing everything but --bless and --list until the host tools are re-blessed.`), or exempt `--register` with a note. Wording only.

#### 7. User-facing docs are silent on the new refusal, warning, `--list` lines and file (carried over from prior Finding 7)

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:15`; `guides/cc-isolated-usage.md:22`, `:919-930` (Troubleshooting)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a user who hits `ERROR: … refusing to run the session-exit scan's code` and looks it up

Evidence: the header still reads `cc-isolated --list                   # registered projects, blessed config, verified?`. The guide reads `cc-isolated --list                # blessed config hash + verified-live status, registered projects`. The Troubleshooting table has rows for `no blessed manifest` / `installed config changed` and for the `NOTE: blessed config …` line, but none for the host-tool ERROR, the `WARNING: … do not run cc-push` line or `Host tools: CHANGED`. `git diff --stat 4ab9a51f feat/q089b2-host-tool-gate` touches `guides/devcontainer-setup.md` only, so neither sibling closes this. The commit's trailers do disclose the one-time `blessed_hash` change (prior Finding 8 is resolved).

**Recommendation:** Add "host-tool state" to both `--list` one-liners. Add a Troubleshooting row: "`… changed since the last bless — refusing to run the session-exit scan's code` / `Host tools: CHANGED`: review the named file, then re-bless; no rebuild unless the boundary changed too." This can land with A2 or B if A1 should stay small.

## What Looks Good

- **Exit codes stay inside decision log #58.** The refusal exits 1 (P4b, P6b, P8). The warning does not change the exit status. `--bless`/`--list` are exempt exactly as they are from the `devcontainer CLI not found` gate (`:734` vs `:760`).
- **The refusal keeps `check_manifest`'s shape**: an `ERROR: <what> — refusing to <what>.` line, indented remedy lines and a four-space-indented command. It now also runs the boundary check, so P8 shows both ERROR lines and the boundary diff before the bless hint.
- **`check_manifest`'s hints improved**: `bless_cmd` fixes a real hazard on its two call sites. Finding 1 asks only that it be applied everywhere.
- **The bless prelude mirrors the refusal**: `Changed since the last bless (<file>):` uses the refusal's own phrase and names which manifest changed, so the bless reads as the review the refusal promised.
- **The on-disk layout extends the pattern**: `host-tools.sha256` sits beside `manifest.sha256`, and the bless writes both atomically through temp files (prior Finding 4 is resolved).
- **The `--list` sub-lines say exactly what each entry point will do** ("launches warn … but run", "cc-push refuses"). That is the missing diagnostic prior Finding 2 asked for, and bats pins it (`:1021-1030`).
- **The WARNING line matches the existing `WARNING: <what> — <advice>` lines** (`:604`, `:803`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--list` host-tool remedy ignores `CLAUDE_DEVC_CONFIG_DIR`; three spellings of the bless command | Inconsistent | `cc-isolated.sh:493` (also `:238`, `:747`) | High |
| 2 | Absent host-tools.sha256 reported as "CHANGED" / "Also changed" | Minor | `cc-isolated.sh:488-499`, bats `:987-990` | High |
| 3 | OK and CHANGED `--list` lines differ in shape (colon, ASCII hyphen vs em-dash) | Minor | `cc-isolated.sh:491,493` | High |
| 4 | `--bless` host-tools block lacks the `(N entries)` count | Minor | `cc-isolated.sh:296` | High |
| 5 | `--bless`/`--register`/`--list` stdout gains a prelude and lines (no in-repo parser) | Informational | `cc-isolated.sh:277-298,480-500` | High |
| 6 | Refusal text names the scan but also blocks `--register`/`--probe-only` | Minor | `cc-isolated.sh:734-749` | Medium |
| 7 | Header, usage guide and Troubleshooting silent on the new lines | Minor | `cc-isolated.sh:15`; `guides/cc-isolated-usage.md:22,919-930` | High |

## Overall Assessment

A1 is consistent with the launcher's conventions where it matters: exit codes, the ERROR/WARNING shapes, the `<content>.sha256` layout, and the `*_files`/`compute_*` naming. It breaks no existing consumer, since every pre-existing output line is still printed and no in-repo script parses the changed outputs. The pass-1 findings that applied to A1 (2, 4, 5 and 8) are resolved. One real inconsistency remains (Finding 1). The diff introduces `bless_cmd` to stop hints for a non-default dir from blessing the default one, but the new `--list` hint does not use it, and the remedy is spelled three ways. The other findings are output-shape and wording polish (2, 3, 4, 6) and documentation drift (7). All can be fixed in place in a few lines plus bats updates, and none needs a design change.

## Goal-Alignment Note

The goal is to review A1's CLI and on-disk config for consistency before it merges, with the focus on the new `--list`/`--bless` lines against existing output and on what changes for scripts that parse them. This report covers both parts. The new lines are compared against `check_manifest`, the `Blessed config` line and the bless header, and Findings 1 to 4 and 6 are the mismatches. Finding 5 and the Baseline section give the parse-impact answer: the changes are additive, the first line of `--bless` moves, and nothing in-repo parses the outputs. Cross-unit references that hold only once A2 and B land (row 71, `Host-tool-tested:`, the cc-push copy) are left to the fact-check report, Claims 1, 4c and 5a, and are not repeated here. Nothing in this report argues against merging A1 in order with A2 and B. Finding 1 is the one worth fixing before merge.
