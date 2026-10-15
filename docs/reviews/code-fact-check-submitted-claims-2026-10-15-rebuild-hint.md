Commit: 2463017f

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-rebuild-hint, branch fix/rebuild-hint-recreate)
**Scope:** Submitted claims only (Stage 2.5, k=1, final pass) for `git diff 9660d4f6..2463017f`; files read: `devcontainer-config/cc-isolated.sh` (rebuild_hint, probe_boundary, record_verified_live, main), `devcontainer-config/init-firewall.sh` (diff only), `test/cc-isolated-functions.bats` (tests 102, 104 and the smart devcontainer stub)
**Checked:** 2026-10-15
**Total claims checked:** 4
**Summary:** 4 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

All runs used a `git archive 2463017f` copy at
`/home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-submitted/src` (logs in the parent
directory). No harvested claims: this pass verdicts only the submitted list, numbered from 13.

---

## Submitted Claims

## Claim 13: "`printf %q` output in rebuild_hint's printed recipe re-parses to the identical workspace path in bash and zsh, for paths containing a space, `$(...)`, a newline or `!`."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/cc-isolated.sh:569`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real first hint line emitted by `rebuild_hint` (bash 5.2.15 producing it) re-parsed by `bash -c` and `zsh -fc` (zsh 5.9), plus a direct `printf %q` round-trip under `zsh -c` and stdin-fed `zsh -fi`, for the four named path classes and one combined hostile path; does not establish behavior under a tty-interactive zsh with user options (e.g. history or `RC_QUOTES` settings from a real `.zshrc`), fish or other non-POSIX shells, or the by-hand assignment lines at `:572-576`.

The line under test, read in full with the rest of `rebuild_hint` (`:560-577`):

```bash
# devcontainer-config/cc-isolated.sh:569
  echo "    cc-isolated --probe-only $(printf '%q' "$ws") && cc-isolated $(printf '%q' "$ws")" >&2
```

`recipe-roundtrip.sh` sources the archived script (the main guard at `:953-955`, whose call is at `:954`, keeps it from
launching), captures the first stderr line of `rebuild_hint "$p" ...`, then runs that line in
each shell with `cc-isolated() { printf "<%s>" "$@"; }` defined, and compares against
`<--probe-only><$p><$p>`. All eight cases (4 paths x 2 shells) came back `identical`, and no
`PWNED` file was created. The quoted forms were `/tmp/a\ b`, `/tmp/x\$\(id\)`, `$'/tmp/n\nl'`
and `/tmp/q\!x`. The `roundtrip.sh` run adds a combined path holding `$(touch PWNED)`, a
backtick, `!!`, a newline, a tab, `'`, `"` and glob/operator characters: identical in all four
shell modes.

- Command 1: `timeout 60 bash recipe-roundtrip.sh .../fc-submitted/src/devcontainer-config/cc-isolated.sh`; cwd `/home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-submitted/rt`; exit 0; 2026-10-15T11:59:39Z.
- Command 2: `timeout 60 bash roundtrip.sh`; same cwd; exit 0; 2026-10-15T11:59:28Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:560-577`, /home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-submitted/recipe-roundtrip.log, /home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-submitted/roundtrip.log, /home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-submitted/recipe-roundtrip.sh, /home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-submitted/roundtrip.sh
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "`cc-isolated --probe-only WS` exits non-zero and writes no verified-live receipt when the probe fails."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/cc-isolated.sh:891-896`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--probe-only` branch when `probe_boundary` reports a failure (exercised through the stubbed missing firewall marker), including the forced `--remove-existing-container` up and the absence of `verified-live.sha256` afterwards; does not establish behavior when a real `devcontainer up` fails during the forced recreate (the stub always succeeds; statically `set -e` would also end the run non-zero there), and does not establish that a receipt left by an earlier pass for the same hash is removed (nothing removes it; the claim is only that none is written).

The branch, with `set -euo pipefail` at `:68` and `main "$@"` called as a plain statement at `:954`:

```bash
# devcontainer-config/cc-isolated.sh:891-896
  if [ "$action" = "probe" ]; then
    # --probe-only is the verification command, so it always recreates: probing a
    # container left over from an earlier config would verify the wrong boundary.
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
```

`probe_boundary` (`:587-715`, read in full) writes the receipt only after every check passes:

```bash
# devcontainer-config/cc-isolated.sh:708-712
  if [ "$failures" -gt 0 ]; then
    echo "Boundary self-probe FAILED ($failures) — not starting Claude Code." >&2
    return 1
  fi
  record_verified_live
```

`record_verified_live` (`:115-117`) is the only writer of `verified_path` (`blessed_hash > "$(verified_path)"`). So a failing probe returns 1 before the write, and `set -e` exits before `exit 0`.

Executed: the full file passes (195 `ok`, no `not ok`), including `ok 104 --probe-only exits non-zero and records nothing when the probe fails` (`test/cc-isolated-functions.bats:1429-1442`). A mutant that changes `:895` to `probe_boundary "$ws" || true` fails test 104 at line 1438 (`[ "$status" -ne 0 ]`), so the test discriminates.

- Command 1: `timeout 600 bash scripts/run-tests.sh test/cc-isolated-functions.bats`; cwd `.../fc-submitted/src`; exit 0; 2026-10-15T11:57:35Z.
- Command 2 (mutant): `timeout 600 bats --filter 'probe-only exits non-zero' test/cc-isolated-functions.bats`; cwd `.../fc-submitted/m1`; exit 1 (expected); 2026-10-15T11:59:08Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:68`, `devcontainer-config/cc-isolated.sh:115-117`, `devcontainer-config/cc-isolated.sh:708-712`, `devcontainer-config/cc-isolated.sh:891-896`, `test/cc-isolated-functions.bats:1429-1442`, /home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-submitted/cc-isolated-functions.log, /home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-submitted/mutant1.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "Neither enforcement script (cc-isolated.sh, init-firewall.sh) changed any line other than comments and echo lines in 9660d4f6..2463017f."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/cc-isolated.sh`, `devcontainer-config/init-firewall.sh`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every added or removed line in the two files across 9660d4f6..2463017f (48 lines: 32 added, 16 removed), each of which begins with `#` or `echo `; does not establish that the changed `echo` text is behavior-neutral (it is user-facing output, and the bless "Next" message and the init-firewall recipe now print on more lines) or that no consumer outside the diff's bats files matches the old text.

`git diff -U0 9660d4f6..2463017f -- devcontainer-config/cc-isolated.sh devcontainer-config/init-firewall.sh`, keeping `+`/`-` lines (minus the file headers), then dropping lines matching `^[-+][[:space:]]*(#|echo )`, leaves nothing (grep exit 1, empty output file). The unfiltered count is 48, which matches `--stat` (32 insertions, 16 deletions). I read the 48 lines by hand as well. One example, the recipe line, swaps one `echo` for two, plus comments above them:

```bash
# devcontainer-config/cc-isolated.sh:569-570 (post-diff)
  echo "    cc-isolated --probe-only $(printf '%q' "$ws") && cc-isolated $(printf '%q' "$ws")" >&2
  echo "      (the supported path: recreates the container from the blessed config, re-probes, then launches)" >&2
```

- Command: the pipeline above `> diff-filter.log`; cwd `/workspace/.claude/wt-rebuild-hint` (read-only git query); grep exit 1 (no non-comment/non-echo line); 2026-10-15T11:59:50Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:569-570`, /home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/diff-final.patch, /home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-submitted/diff-filter.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "A plain launch on a fail-closed container (blessed hash baked, firewall marker missing, init-firewall.sh re-run failing) does not recreate it, does not start claude, exits non-zero, and prints the new two-step hint."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/cc-isolated.sh:899-929`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the plain-launch path in `main` against the stub's fail-closed emulation (`STUB_IMAGE_HASH` = blessed, `STUB_FW_MISSING`, `STUB_FW_BRICKED`): no `--remove-existing-container`, no `devcontainer exec ... claude`, non-zero status, and the `--probe-only WS && cc-isolated WS` line after "Recreate it"; does not establish behavior against a real bricked container or real `devcontainer` CLI, nor the case where the baked hash differs (that path recreates by design at `:904-907`).

`main` from the first `devcontainer up` to the claude exec, read in full through the exit scan (`:899-952`):

```bash
# devcontainer-config/cc-isolated.sh:899 and :912-929 (truncated: :904-907 recreate-on-hash-mismatch omitted; :930-952 claude exec and exit scan follow)
  devcontainer up "${dc[@]}"
  ...
  if ! probe_boundary "$ws"; then
    ...
    if ! devcontainer exec "${dc[@]}" sudo /usr/local/bin/init-firewall.sh; then
      echo "ERROR: init-firewall.sh failed. It fails closed, so this container may now" >&2
      ...
      rebuild_hint "$ws" "${dc[@]}"
      return 1
    fi
```

With the hash matching, `container_config_matches` passes, so `:904-907` never recreates. The marker is missing, so the probe fails (`:700-707`). The re-run fails, so the hint prints and `return 1` comes before the `devcontainer exec ... claude` at `:938`. `return 1` from `main "$@"` under `set -e` exits 1. The stub maps the two inputs directly: `*cc-firewall/complete*) [ -z "${STUB_FW_MISSING:-}" ]` and `*init-firewall.sh*) [ -z "${STUB_FW_BRICKED:-}" ]` (`test/cc-isolated-functions.bats:1170-1171`).

Executed: `ok 102 a launch on a fail-closed container does not recreate it, and the hint names --probe-only first` (`test/cc-isolated-functions.bats:1392-1412`), in the same full-file run as Claim 14 (195 `ok`). It asserts `status -ne 0`, the hint after "Recreate it", no `--remove-existing-container`, and no ` claude$` in the devcontainer log. A mutant that restores the old one-step hint at `:569` fails test 102 at line 1405, so the hint assertion discriminates.

- Command 1: as Claim 14, Command 1 (exit 0, 2026-10-15T11:57:35Z).
- Command 2 (mutant): `timeout 600 bats --filter 'fail-closed container does not recreate' test/cc-isolated-functions.bats`; cwd `.../fc-submitted/m2`; exit 1 (expected); 2026-10-15T11:59:08Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:899-929`, `devcontainer-config/cc-isolated.sh:938`, `test/cc-isolated-functions.bats:1170-1171`, `test/cc-isolated-functions.bats:1392-1412`, /home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-submitted/cc-isolated-functions.log, /home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-submitted/mutant2.log
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a submitted-claims report saved at that path verdicting claims 13-16.
- Answered: yes. All four were executed and Verified, and mutants confirmed that tests 102 and 104 discriminate.
- Out of scope: harvested claims; the unchanged echo at `devcontainer-config/cc-isolated.sh:905` ("rebuilding it"), which this pass saw but does not verdict.
- Escalate: nothing
- Decisions I made: Claim 13 was tested on the real `rebuild_hint` output line, not only on bare `printf %q`, and also under stdin-fed `zsh -fi`; tty-interactive zsh with user rc options stays out of scope.
