Commit: cb56299c

# Security Review: fix/rebuild-hint-recreate (rebuild hint gives the --probe-only recipe)

**Scope:** `git diff 9660d4f6..cb56299c` (cc-isolated.sh, init-firewall.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, test/init-firewall-rules.bats)
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-2026-10-15-rebuild-hint.md (k=1)

## Trust Boundary Map

```
B1: [host workspace path (user arg → git toplevel)] → [printf %q in rebuild_hint]   → [terminal text the user copies into a host shell]
B2: [copied hint line in the user's host shell]     → [main() arg parser / resolve_workspace] → [which repo's container is recreated, probed and launched]
B3: [--probe-only exit status]                      → [`&&` in the printed recipe]   → [second `cc-isolated WS`, which re-probes before `claude`]
B4: [stubbed devcontainer (tests)]                  → [smart_devcontainer_stub case] → [assertions about main()'s recreate decision]
```

Input sources:

```
S1: workspace path ($ws, git toplevel of the arg) — request-time (host user; a cloned repo's dir name can be attacker-chosen)
                                                     — UNTRUSTED toward shell-source sinks (the printed copy line); trusted for identity once resolved
S2: hint text literals (comment words)            — code-constant — trusted as text; but they become ARGUMENTS when the shell does not treat `#` as a comment (Finding 1)
S3: CC_* launcher env (by-hand form)              — deploy-time/launcher-set — unchanged by this diff
S4: STUB_FW_BRICKED (test env)                    — test-only — trusted
```

The diff changes only what is printed (B1) and therefore what the user runs next (B2, B3). No iptables rule, probe check, recreate decision or exit status changed (fact-check: Verified; confirmed by reading `main()` :733-942 and `probe_boundary` in full). The `&&` is belt-and-braces: the second step's own `probe_boundary` gates `claude` regardless.

## Findings

#### 1. The copyable hint line's trailing `# ...` comment becomes extra arguments in default zsh, and the last one silently retargets the launch

**Severity:** Medium (floor rule: named mechanism, reachable environment; usual outcome is a fail-safe error, see Confidence)
**Location:** `devcontainer-config/cc-isolated.sh:564` (with the parser at `:753`)
**Boundary:** B2
**Move:** 2 (implicit sanitization assumption: "the shell will drop the comment"), 11
**Confidence:** High that the mechanism exists (executed); Low likelihood of a wrong-repo launch (needs a git repo at `./launches` relative to the user's cwd)
**Legibility-target:** the user copying the line from a terminal; the code comment at :597-603 that promises the line "copies out as one word, never as shell source"

Evidence (verbatim, line :564):
`echo "    cc-isolated --probe-only $(printf '%q' "$ws") && cc-isolated $(printf '%q' "$ws")   # the supported path: recreates from the blessed config, re-probes, then launches" >&2`

and the parser (:753): `      *)            ws_arg="$1"; shift ;;`

Interactive zsh does not treat `#` as a comment unless `interactivecomments` is set (off by default; zsh is macOS's default login shell). Pasting the whole printed line runs step 1 correctly, then step 2 as `cc-isolated WS '#' the supported path: ... then launches`. `main()` keeps the **last** positional, so `ws_arg=launches`. Executed (scratch bats copy, `$TEST_TMPDIR` cwd): with no `./launches` the launch fails with `ERROR: not a directory: launches` (status 1); with `./launches` a git repo, it prints `Project: /tmp/tmp.c2w7yHZYoa/launches ...` and proceeds to launch **that** repo. Under `zsh -o extendedglob` it fails with `zsh: bad pattern: #`. The boundary is not widened (the retargeted repo gets its own blessed-config container and probe), but a session starts on a repo the user did not name, which is what resolve_workspace's "never guess, never fall back to some other repo" (H1) rules out. Pre-existing: the old line ended `... re-launches`, same mechanism (`ws_arg=re-launches`); this diff rewrote the line and kept the form, and the two-step version now makes it look like step 1 succeeded.

**Recommendation:** Print the explanation on its own line (e.g. `echo "    # the supported path: ..."` above it) so the copyable line is only the command. Optionally, outside this unit, make `main()` reject a second positional instead of overwriting `ws_arg`.

#### 2. No test pins the property the `&&` relies on (--probe-only exits non-zero on a failed probe)

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:560-563`; `test/cc-isolated-functions.bats:1406-1414`
**Boundary:** B3
**Move:** 3
**Confidence:** High
**Legibility-target:** future editors of the --probe-only branch

Evidence (comment, :562-563): `# would be reused, not recovered. --probe-only always recreates, and exits` / `# non-zero on a failed probe, so the `&&` never starts a session after one.`

The only --probe-only test asserts the pass case (`[ "$status" -eq 0 ]`). The fail case holds today only through `set -euo pipefail` (:66) plus `main "$@"` being a plain command in the guard's if-body; wrapping `probe_boundary "$ws"` (:888) in a condition, or `main "$@" || ...`, would silently make the failed probe exit 0. I executed it in a scratch copy (stub with `STUB_FW_MISSING=1`): status 1, `--remove-existing-container` logged, no ` claude` call. Impact if it regressed is limited because step 2 re-probes before `claude`. Recommendation: add that scratch test (fail case for --probe-only, asserting non-zero and no `claude`) to the suite.

#### 3. Hint printed during a --probe-only run points back at --probe-only (pre-existing, from fact-check)

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:670-671`, `:684-685`
**Boundary:** B2
**Move:** 3
**Confidence:** Medium
**Legibility-target:** user hitting a provenance/config-identity failure

Evidence: `echo "  not the one you blessed. Recreate it with:" >&2` / `rebuild_hint "$ws" "${dc[@]}"`

When the cause is the build (e.g. a shadowing `.devcontainer/Dockerfile`), re-running the recipe loops; a frustrated user's next option on screen is the by-hand `devcontainer up` form. That form is pre-filled with every launcher assignment (:566-570), so it is not a narrower boundary here, and it is unchanged by this diff. No action needed for this unit.

## Untested bypass candidates

None open. Candidates for B1 (shell injection through S1) were all executed: a path containing space, `;`, `$(touch PWNED)`, backticks, `'`, `"`, `!`, newline and `*`, fed as the printed line to `bash --norc -i`, `zsh -f -i`, `zsh -o interactivecomments` and `zsh -o extendedglob`: every shell passed the path as one argument to both commands, no `PWNED` file was created, and no history expansion happened. Paths always start with `/` (git toplevel), so neither a leading `-` nor a leading `~` case arises.

## Endorsement Claims

- **Claim:** The printed recipe passes a hostile workspace path as one argument to both `cc-isolated` calls in bash and zsh, with no command substitution, globbing or history expansion.
  **Location:** `devcontainer-config/cc-isolated.sh:564`
  **Evidence:** executed
  **Verified:** generated the line via `rebuild_hint` for the path above; ran it in four shell configurations against a stub `cc-isolated` that prints its argv
  **Not verified:** fish or other non-POSIX shells (`$'...'` quoting from `%q` is bash/zsh/ksh syntax)
  **route: code-fact-check**
- **Claim:** `cc-isolated --probe-only WS` exits non-zero and never calls `claude` when the firewall-complete marker is missing after the forced recreate, so the `&&` does not run step 2.
  **Location:** `devcontainer-config/cc-isolated.sh:884-889`
  **Evidence:** executed
  **Verified:** scratch bats test with `smart_devcontainer_stub`, `STUB_FW_MISSING=1`: status 1, DC_LOG has `--remove-existing-container` and no ` claude`
  **Not verified:** failures from a real `devcontainer up --remove-existing-container` (stubbed)
  **route: code-fact-check**
- **Claim:** The diff changes no iptables rule, probe check, recreate condition or exit status. Only echo text, comments, docs and tests differ.
  **Location:** whole diff
  **Evidence:** read-static
  **Verified:** read every hunk; read `main()` :733-942 and `probe_boundary` through :709
  **Not verified:** the rest of init-firewall.sh beyond the `fail_closed_on_abort` hunk (only echo/comment lines changed there)
  **route: code-fact-check**
- **Claim:** The stub's new `*init-firewall.sh*` arm returns 0 when `STUB_FW_BRICKED` is unset, the same as the old `*)` default, so other tests see no behaviour change.
  **Location:** `test/cc-isolated-functions.bats:1166`
  **Evidence:** read-static
  **Verified:** read the full stub case :1162-1176. The earlier arms (`cc-config-hash`, `rev-parse`, `cc-firewall/complete`) do not match the `sudo /usr/local/bin/init-firewall.sh` call.
  **Not verified:** whether a `$TEST_TMPDIR` path could ever contain the substring `init-firewall.sh` (mktemp names make it implausible)
- The new regression test (:1384-1404) and the existing pass test both passed when run (scratch copy, `bats --filter`).

## Primitive sweep

Primitive: shell source the user re-executes (printed copy-paste commands)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-isolated.sh:564` supported-path line | S1, S2 | `printf %q` on S1 | S1 cleared (executed); S2 → Finding 1 |
| `cc-isolated.sh:566-571` by-hand form | S1, S3 | `printf %q` on every value and arg | cleared, unchanged by this diff |
| `init-firewall.sh:357-358` | code-constant `<repo>` placeholder | n/a | cleared: a placeholder, not copy-runnable (in zsh `<repo>` is a redirect). The same trailing `#` pattern applies, but there is no path to retarget |
| `cc-isolated.sh:316` `Next: cc-isolated --probe-only <repo>   # rebuilds ...` | code-constant | n/a | out of diff; placeholder; residual "rebuilds" wording (consistency only) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Trailing `#` comment becomes extra args in default zsh; last-positional-wins retargets the launch | Medium | B2 | `cc-isolated.sh:564`, `:753` | High (mechanism) / Low (likelihood) |
| 2 | No test pins --probe-only's non-zero exit on a failed probe, which the `&&` relies on | Informational | B3 | `cc-isolated.sh:560-563`, bats :1406 | High |
| 3 | Hint printed during --probe-only loops back to --probe-only (pre-existing) | Informational | B2 | `cc-isolated.sh:670`, `:684` | Medium |

## Overall Assessment

This is a message-only change. It moves the user toward the correct, same-width boundary: --probe-only recreates from the blessed config and re-probes, and the second step re-probes again before `claude`. The quoting of hostile workspace paths holds up in bash and zsh (executed). No boundary behaviour changed. The one real issue (Finding 1) is pre-existing and fixable in place by taking the explanatory comment off the copyable line. Then a zsh user who pastes the whole line cannot have step 2 retargeted to `./launches`. It does not widen the boundary, but it breaks the "never guess the repo" property. Most important: move the comment to its own line. Within the code paths read, there are no further findings. Endorsement claims are executed or scoped, and they await code-fact-check verdicts.

## Goal-Alignment Note

The goal is for the hint to stop misleading after a fail-closed firewall. The diff serves it: the first line is now the two-step recipe that actually recovers, and the `&&` cannot start a session after a failed probe. Finding 1 is the one place where the printed recipe can still do something other than what it says, and only for users who copy the whole line into default zsh. It is cheap to fix inside this unit, because this unit owns line :564.
