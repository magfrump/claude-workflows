Commit: 840f39b0

# API Consistency Review — Q-089 unit A2 (cc-push self-check)

**Scope:** `git diff f2533b33 840f39b0` (branch feat/q089a2-cc-push-self-check, stacked on A1 f2533b33): `devcontainer-config/cc-push.sh`, `test/cc-isolated-functions.bats`, `test/cc-push.bats`. A1 and unit B (feat/q089b2-host-tool-gate, 613c0ade) read as sibling context only.
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report-q089a2.md` (21 claims; Claim 3 "nothing unchecked runs" Incorrect). Prior history (advisory): the unit-A review round, landed in b1539159.
**Pass:** iteration 1 of 3 (`--loop-pass`), full scope of the stacked unit.

Probes ran under `timeout` with `LC_ALL=C` and `HOME`/`TMPDIR`/`CC_PUSH_CLONES_DIR` redirected into `/home/node/.claude/jobs/00bcf178/tmp/acr-q089a2.1iuKaA/`, against a `git archive 840f39b0` extract. Nothing outside that dir was touched.

## Baseline Conventions

- **Exit codes (decision log #58).** Host tools follow install.sh's convention: 0 success; 1 an error or a declined prompt; 2 bad usage. cc-push's header (`cc-push.sh:29-34`) and `guides/cc-isolated-usage.md:236-239` both list them.
- **Error output in cc-push.** Each error is one `ERROR: <reason>` line on stderr, printed by `die` (exit 1) or `usage_die` (exit 2, then the help). Both pipe through `vis` (`cc-push.sh:215-225`). A reason usually ends with the next step to take, e.g. `... Stop it first (docker stop $ctrs), then rerun` (`:290`).
- **The launcher's host-tool refusal (A1, `cc-isolated.sh:734-750` at f2533b33).** It prints `ERROR: $HOST_TOOLS_ERR — refusing to run the session-exit scan's code.`, then indented hint lines, and the bless command names the directory it checked: `printf '    CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless\n' "$CC_ISOLATED_DIR"`. The rule is stated at `bless_cmd()` (`:309-317`): "names CLAUDE_DEVC_CONFIG_DIR when it is set, so a hint printed for a non-default dir does not bless the default one". `check_manifest` uses `$(bless_cmd)` in both its refusals (`:325`, `:334`).
- **The bare form exists too.** `--list` prints `Host tools: CHANGED (review, then: cc-isolated --bless)` (`cc-isolated.sh:493`), and `verify_host_tools`'s missing-manifest reason says `cc-isolated --bless after reviewing` (`cc-push.sh:161`). So the bare hint has a precedent in a status summary and in the shared function. Every exit-1 refusal in A1 that ends in a command to run uses the dir-qualified form.
- **When the launcher refuses.** It parses its arguments first. `--help` exits 0 at `:727`, before the host-tool refusal at `:734`. `--bless` and `--list` stay available.
- **Shared code.** `verify_host_tools` is one copy in two files, kept the same by a test. Its marker comments follow the `# --- name` / `# --- end name` shape.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `verify_host_tools` | function (shared host-tool API) | `verify_host_tools` (A1), `check_manifest`, `check_checkout` | `devcontainer-config/cc-isolated.sh:219-259` (f2533b33) | Consistent. The same name and body as A1, pinned by the parity test. |
| `CC_PUSH_DIR` | global (script's resolved dir) | `CC_ISOLATED_DIR` | `devcontainer-config/cc-isolated.sh:695` | Consistent. Follows the `CC_<TOOL>_DIR` shape. |
| `host_tools_err` | global (captured refusal reason) | `HOST_TOOLS_ERR` (launcher global), `push_err`, `lerr`/`perr` (locals) | `devcontainer-config/cc-isolated.sh:696`, `:742`, `:488-489` | Minor and internal only. The launcher's global for the same value is uppercase. Here it is lowercase, as a local would be. Not a consumer surface, so it is not raised as a Finding. |
| `# --- verify_host_tools` / `# --- end verify_host_tools` | marker comment (test contract) | the same markers in A1 | `devcontainer-config/cc-isolated.sh:219`, `:259` | Consistent. The parity test greps for these markers. |
| refusal text `cc-push refuses to run` | user-facing message | `refusing to run the session-exit scan's code` (launcher), `cc-push refuses` (`--list` line) | `cc-isolated.sh:735`, `:499` | Consistent. `--list` already prints `cc-push refuses: …`, so the wording matches what users see there. |
| test `verify_host_tools is the same code in cc-isolated.sh and cc-push.sh` | test name | other `verify_host_tools: …` tests | `test/cc-isolated-functions.bats:880-925` | Consistent. |

No new flags, options or exit codes. The only new contract is the refusal's behaviour and text.

## Findings

#### F1. The refusal's bless hint drops CLAUDE_DEVC_CONFIG_DIR, unlike every A1 refusal

**Severity:** Inconsistent
**Location:** `devcontainer-config/cc-push.sh:189`
**Move:** 4 (error consistency), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** the user acting on the refusal, and anyone keeping the two entry points' refusals in step

Precedent: dir-qualified bless hint (`CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless`, or `$(bless_cmd)`) used in `devcontainer-config/cc-isolated.sh:747` and `:325`/`:334` (f2533b33)

Evidence:
```bash
# cc-push.sh:189
echo "ERROR: $host_tools_err — cc-push refuses to run. Review it, then: cc-isolated --bless" >&2
```
```bash
# cc-isolated.sh:747 (A1)
printf '    CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless\n' "$CC_ISOLATED_DIR" >&2
```

The probe installed cc-push in a non-default dir (`$W/custom`) and changed it. The refusal was the same byte for byte whether or not `CLAUDE_DEVC_CONFIG_DIR` was set: `... cc-push refuses to run. Review it, then: cc-isolated --bless`. Bare `cc-isolated --bless` blesses `config_dir()`, which is `${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}` (`cc-isolated.sh:68-70`). Take a user who installed with a one-off `CLAUDE_DEVC_CONFIG_DIR=… ./install.sh`, which install.sh supports (`install.sh:1310`). The hint has them bless the default dir. If one exists there, that bless accepts a config nobody asked them to review, and cc-push keeps refusing. A1 avoids this on purpose, and `bless_cmd()`'s comment says why. cc-push already has the right value: `CC_PUSH_DIR` is the resolved dir that was checked. On the default install the two hints are equivalent, so the gap shows only on a custom install. This is the fact-check's open point, judged against A1's `bless_cmd`: A1 sets the convention, and this line departs from it.

**Recommendation:** Print the checked dir, as the launcher does: `printf 'ERROR: %s — cc-push refuses to run.\n  Review it, then: CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless\n' "$host_tools_err" "$CC_PUSH_DIR" >&2`. Have the test assert that the dir appears in the hint.

#### F2. The header's "nothing unchecked runs" overstates the contract the exception documents

**Severity:** Minor
**Location:** `devcontainer-config/cc-push.sh:35-39`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a `--help` reader (the header is the help text), and future editors who place code above the check

Evidence: `# exits 1 before parsing anything, --help included (decision log row 71): nothing` / `# unchecked runs.`

Fact-check Claim 3 found this Incorrect. Probe P1 inserted a line above the check, and that line ran before the refusal. P3 made the check skip itself, and the tampered copy ran unrefused. Unit B's row 71 lists "a self-skipping tampered cc-push" under "Not covered". The `--help` text therefore promises more than the decision record does, and this header is the place users read the contract. The exit-code part of the paragraph is accurate and consistent with #58, since a refusal is an error, which is 1. Only the guarantee clause is wrong.

**Recommendation:** Reword the clause to match row 71, e.g. "nothing past this check runs from a changed copy; a change that removes the check is caught only by the launcher's warning or the next bless."

#### F3. The usage guide's cc-push exit-code list and `--help` line do not mention the refusal

**Severity:** Minor
**Location:** `guides/cc-isolated-usage.md:35`, `:236-239` (unchanged by A2, and by unit B, whose guide change is in `guides/devcontainer-setup.md`)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a user who checks the guide for what cc-push's exit 1 means, or why `cc-push --help` failed

Evidence: `cc-push --help                    # usage header, exit codes included` and `Exit codes: 0 pushed (or nothing to push); 1 an error (a refused checkout, container or git version, a failed fetch, a rejected push, an interruption …`

`cc-push --help` can now exit 1 with no help printed (probe: stdout 0 bytes). The guide's own quick-reference line and exit-code list say nothing about this. The header documents the exception and the guide does not, though #58 calls these "both tools' `--help` and `guides/cc-isolated-usage.md`" contracts. Unit B describes the refusal in `devcontainer-setup.md`, which is not where a user looks up exit codes.

**Recommendation:** Add one clause to `:236-239`, e.g. "a changed installed copy of cc-push or cc-gitdir.sh, refused before anything is parsed, `--help` included". This can go in A2 or in unit B's guide commit.

#### F4. The ERROR line's shape with several mismatches, and the duplicate hint on a missing manifest

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:189` (with `verify_host_tools` `:160-176`)
**Move:** 4 (error message consistency)
**Confidence:** High
**Legibility-target:** the user reading the refusal

Evidence (probe, both files changed):
```
ERROR: …/custom/cc-push.sh changed since the last bless$
…/custom/cc-gitdir.sh changed since the last bless — cc-push refuses to run. Review it, then: cc-isolated --bless$
```
Evidence (probe, manifest missing): `ERROR: no host-tool manifest at …/host-tools.sha256 (re-run install.sh, or cc-isolated --bless after reviewing) — cc-push refuses to run. Review it, then: cc-isolated --bless`

The launcher's ERROR line embeds the multi-line reason the same way (`cc-isolated.sh:735`), so this matches A1, and A1 has the same quirk. Three small things for the user: the second path has no `ERROR:` prefix; "Review it" is singular when two files are named; and the missing-manifest case gives two bless hints. `--list` already joins the reasons with `; ` (`:495`). The `echo` here also skips cc-push's `vis` filter, the one `die` uses. That is defensible, because `die` is defined later (`:215`) and the path is the script's own resolved dir rather than session-controlled. The F1 fix, a reason line plus a separate hint line, resolves most of this.

**Recommendation:** Fold this into F1's fix. Put the hint on its own line and say "Review them" (or name the dir). Optionally join reasons with `; ` as `--list` does. No change to the shared function is needed.

#### F5. `--help` order differs from the launcher (refused here, honoured there)

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:187-191` vs `cc-isolated.sh:727`, `:734` (A1)
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** a user who knows one tool's behaviour and expects the other to match

Evidence: header `exits 1 before parsing anything, --help included`; launcher `--help|-h)    usage; exit 0 ;;` at `:727`, ahead of the refusal block at `:734`.

The two entry points disagree on `--help` under a failed host-tool check: the launcher exits 0 and prints help, cc-push exits 1. The difference has a reason. cc-push would have to `source cc-gitdir.sh` before parsing, while the launcher simply skips sourcing the scan. It is documented in cc-push's header and in B's setup-guide note ("refuses to run, `--help` included"). Recorded so the choice stays deliberate, not as a defect.

**Recommendation:** None required. If F2's rewording touches the header anyway, a few words on why `--help` is refused here would help, e.g. "cc-gitdir.sh would be sourced first".

## What Looks Good

- **Exit status follows #58.** The refusal is an error, so it exits 1. No new code was invented, and the header lists it as an ordered exception, not a new number.
- **The `ERROR:` prefix, stderr, and wording match.** "cc-push refuses to run" matches the `--list` line `cc-push refuses: …` that A1 already prints, so the summary and the tool use the same words.
- **One shared function under one name,** pinned by a parity test that greps the marker comments. The two entry points cannot drift on what a mismatch is, or on the positive repo-checkout marker.
- **`CC_PUSH_DIR`** follows `CC_ISOLATED_DIR`. The resolved dir is computed once and reused for the check and the `source`, so the dir checked is the dir sourced.
- **No flag, option or exit-code change.** For callers on the default install who have not changed anything, behaviour is the same, so the change is additive.
- **Tests cover the contract:** the refusal message, exit 1 on `--help`, the no-run marker for cc-gitdir.sh, and the deleted-manifest case.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Bless hint drops CLAUDE_DEVC_CONFIG_DIR, unlike A1's refusals | Inconsistent | `devcontainer-config/cc-push.sh:189` | High |
| 2 | Header's "nothing unchecked runs" overstates row 71 | Minor | `devcontainer-config/cc-push.sh:35-39` | High |
| 3 | Usage guide's exit-code list and `--help` line omit the refusal | Minor | `guides/cc-isolated-usage.md:35`, `:236-239` | High |
| 4 | Multi-mismatch ERROR shape, "Review it", doubled hint | Informational | `devcontainer-config/cc-push.sh:189` | High |
| 5 | `--help` refused here, honoured by the launcher (deliberate) | Informational | `cc-push.sh:187-191` vs `cc-isolated.sh:727` | High |

## Overall Assessment

The change fits the host tools' conventions where it matters most. Exit 1 follows #58, there is no new flag or code, the refusal uses `ERROR:` on stderr, the wording matches `--list`, and the shared function is one pinned copy. One real inconsistency remains, F1. The refusal's bless hint is bare, while A1 qualifies every refusal hint with the checked dir and documents why in `bless_cmd()`. On a custom install the hint points at the wrong directory. The fix is one line, because `CC_PUSH_DIR` is already in hand. F2 and F3 are documentation fixes: reword the header guarantee to match row 71, and add the refusal to the usage guide's exit-code list. None of the findings breaks a caller. Everything can be fixed in place, and the author clearly surveyed the launcher.

## Goal-Alignment Note

The goal is for cc-push to refuse with exit 1, before parsing and `--help` included, when its installed copy or cc-gitdir.sh differs from host-tools.sha256, with the exception documented in the header's exit-code block. The code does this, and its exit status and message shape are consistent with #58 and A1. The refusal fails the user at its last step: the command it hands them must bless the directory that was checked. A1 made that a rule (`bless_cmd`), and cc-push's hint does not follow it (F1). The documented contract also promises more than the mechanism and row 71 deliver (F2), and the user guide does not yet carry the exception (F3). Fixing F1 and F2 in this unit, and F3 here or in unit B, brings the documented contract, the printed instruction and the behaviour into line.
