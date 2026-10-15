Commit: 2463017f

# Security Review — fix/rebuild-hint-recreate (final confirming pass)

**Scope:** `git diff 9660d4f6..2463017f` (whole unit; review artifacts excluded, override-log rows read as records), enclosing code in `devcontainer-config/cc-isolated.sh` (rebuild_hint, probe_boundary, main) and `devcontainer-config/init-firewall.sh` (fail_closed_on_abort)
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-2026-10-15-rebuild-hint-final.md; earlier passes security-review-2026-10-15-rebuild-hint.md and -i2.md; rubric code-review-rubric-2026-10-15-fix-rebuild-hint-recreate.md

## Iteration status

- **i2 #1 (Medium, placeholder recipes with trailing `# ...`):** resolved for the bless output (`cc-isolated.sh:318-319`) and the init-firewall abort message (`init-firewall.sh:352-357`). Each command line is now the command alone, and the explanations sit on their own lines. A sweep of `devcontainer-config/*.sh` for `echo …cc-isolated|cc-push … # ` finds only `install.sh:613-617`, which is deferred in the override log. Not re-raised.
- **i2 #2 (Informational, assertion that cannot fail):** resolved. The --probe-only fail test (`test/cc-isolated-functions.bats:1427-1442`) no longer has the vacuous `claude` grep. The `run ! grep -q ' claude$'` in the new launch test (:1411) can fail, because the launch path does exec claude.
- **C4 / provenance loop:** deferred (override log). The fact-check's "retry, not recovery" note is this same item, and I found nothing new about it.

## Trust Boundary Map

```
B1: [launcher stderr recovery text]     → [user copy/paste]          → [host interactive shell parse (bash/zsh)]
B2: [host shell argv]                   → [main() arg loop, resolve_workspace] → [mounted workspace + project id]
B3: [baked init-firewall.sh abort text] → [user copy/paste on HOST]  → [host shell → cc-isolated argv]
B4: [probe_boundary outcome]            → [exit status under set -e]  → [`&&` gate → session launch]  (new: the hint now chains on it)
```

```
S1: ws (resolve_workspace → git toplevel)  — request-time  — trusted as the user's own path for mount/identity;
                                                             UNTRUSTED toward shell-source sinks (copyable lines) → printf %q
S2: echo prose and placeholders            — code-constant — trusted (all sinks)
S3: user-filled <repo> in placeholder recipes — request-time — UNTRUSTED toward argv (last positional wins, cc-isolated.sh:758)
S4: probe_boundary result                  — request-time, derived from container reads — trusted for gating only through exit status
S5: CC_* launcher vars in the by-hand form — deploy-time (launcher-set) — unchanged by this diff; %q-quoted
```

Nothing new enters from outside. The diff changes only text the launcher and the firewall script print, and that text crosses B1/B3 into the user's shell. The one new trust dependency is B4. The printed recipe is `--probe-only WS && cc-isolated WS`, so its safety rests on --probe-only exiting non-zero when the probe fails. Executed: it does. The enforcement code itself did not change: no line other than a comment or an echo changed in either script (executed, see E3).

## Findings

#### 1. The init-firewall recipe is two newline-separated commands, not the `&&` chain the launcher now prints; pasting both runs step 2 after a failed step 1

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:352-357`
**Boundary:** B3, B4
**Move:** 3 (error path), 11
**Confidence:** High (read-static, plus the launch gate traced through `cc-isolated.sh:911-929`)
**Legibility-target:** users who paste both lines of the fail-closed abort message at once; future editors who want the two recovery recipes to stay in step

Evidence (verbatim):
- `    echo "         cc-isolated --probe-only <repo>" >&2`
- `    echo "         cc-isolated <repo>" >&2`
- compare `cc-isolated.sh:570`: `  echo "    cc-isolated --probe-only $(printf '%q' "$ws") && cc-isolated $(printf '%q' "$ws")" >&2`

If both lines are pasted together, step 2 runs even when step 1's probe fails. Step 2 is a plain launch, and a plain launch is itself probe-gated. A failed `probe_boundary` (`cc-isolated.sh:911`) is followed by a re-assert, and on a failed re-assert `main` returns 1 before reaching the claude exec (:925-927). Under `set -euo pipefail` (:68), an unchecked failing second `probe_boundary` (:929) also exits. So no session starts on a failed boundary, and no security property is violated. The two recovery recipes now differ only in how they behave when pasted as a whole. The rebuild_hint form stops at the first failure; this one retries, fails the same way, and prints a second error.

**Recommendation:** Optional. Print the init-firewall recipe as one `&&` line, which would also make both recipes identical. If it stays as two lines, nothing needs to change on security grounds.

## Endorsement Claims

- **Claim:** rebuild_hint's recipe line passes a workspace path as one shell word in both bash and zsh, for paths containing a space, `$(...)`, a newline and `!`.
  **Location:** `devcontainer-config/cc-isolated.sh:570`
  **Evidence:** executed
  **Verified:** I ran `printf '%q'` on `/tmp/a b`, `/tmp/x$(id)`, `/tmp/n<LF>l` and `/tmp/q!x`, then re-parsed each with `bash -c` and `zsh -fc`. Every one came back byte-identical, with no expansion.
  **Not verified:** interactive zsh with non-default options (e.g. `BANG_HIST` in an interactive shell, where bash's `\!` is relied on); fish and other non-POSIX shells (see Untested bypass candidates).
  **route: code-fact-check**

- **Claim:** `--probe-only` exits non-zero and writes no verified-live receipt when the probe fails after the forced recreate. That is the property the hint's `&&` depends on.
  **Location:** `devcontainer-config/cc-isolated.sh:891-896`, `test/cc-isolated-functions.bats:1427-1442`
  **Evidence:** executed
  **Verified:** `bash scripts/run-tests.sh test/cc-isolated-functions.bats`: test 104 `ok`, which asserts `status -ne 0`, `PROBE FAIL (firewall)`, the `--remove-existing-container` up, and no `verified-live.sha256`. The whole file passes with no `not ok` (195 tests).
  **Not verified:** a real `devcontainer up` failure during the forced recreate (the stub always succeeds). Read-static: `set -e` would end the run non-zero there too.
  **route: code-fact-check**

- **Claim:** the diff changes no line in `cc-isolated.sh` or `init-firewall.sh` other than comments and `echo` lines.
  **Location:** `devcontainer-config/cc-isolated.sh`, `devcontainer-config/init-firewall.sh`
  **Evidence:** executed
  **Verified:** I filtered `git diff 9660d4f6..2463017f -- devcontainer-config/` for added or removed lines that are neither `#` nor `echo `. Nothing matched (grep exit 1). This agrees with the merged fact-check.
  **Not verified:** whether the changed `echo` text is still read by a test other than the bats files in the diff (e.g. the health-check script).
  **route: code-fact-check**

- **Claim:** on a fail-closed container built from the blessed config, a plain launch does not recreate the container, does not exec claude, and prints the `--probe-only … && cc-isolated …` hint.
  **Location:** `devcontainer-config/cc-isolated.sh:899-928`, `test/cc-isolated-functions.bats:1392-1412`
  **Evidence:** executed
  **Verified:** test 102 `ok`. The init-firewall bats file also passes, with 95 `ok` and no `not ok`.
  **Not verified:** a real bricked container (the stub emulates the failing re-run through `STUB_FW_BRICKED`).
  **route: code-fact-check**

## Untested bypass candidates

The guardrails here are `%q` quoting into copyable lines (B1) and the `&&` gate on the probe's exit status (B4). Six candidates:

1. **Tested:** a path containing a space, `$(...)`, a newline or `!`. It round-trips in bash and zsh (E1).
2. **Tested:** a failed probe after the forced recreate. It exits non-zero, so the `&&` does not launch (E2).
3. **Traced:** the user also copies line 2 of the hint, `(the supported path: …)`. Bash and zsh run that as a subshell invoking `the`, which gives `command not found` and is harmless. It does anything only if a command named `the` is on PATH, which would mean the attacker already controls the host. Cleared.
4. **Untested:** fish (or another non-POSIX shell) given bash `%q` output. Bash emits `$'…'` for control characters, and fish's handling of that is not verified here. The failure would be a parse error or a mangled path, not injection, because the remaining specials are backslash-escaped. This is pre-existing for the by-hand form.
5. **Untested:** interactive zsh with history expansion and bash's `\!` escape. Non-interactive `zsh -f` was tested; interactive `zsh -i` with default options was not.
6. **Traced:** the init-firewall recipe pasted in full after a failed step 1 (Finding 1). The launch's own probe gate holds.

## Primitive sweep

Primitive: emitting shell source meant to be copied and run (copyable recovery and next-step command lines)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `devcontainer-config/cc-isolated.sh:570` (recipe, ws ×2) | S1 | `printf %q` | cleared (E1) |
| `devcontainer-config/cc-isolated.sh:571` (prose line) | S2 | none needed | cleared (candidate 3) |
| `devcontainer-config/cc-isolated.sh:574-576` (by-hand assignments and args) | S5, S1 | `printf %q` | cleared; unchanged by the diff, covered by tests 24-25 |
| `devcontainer-config/cc-isolated.sh:318-319` (bless "Next") | S2 + S3 | command alone on its line | cleared; i2 #1 fixed |
| `devcontainer-config/init-firewall.sh:356-357` | S2 + S3 | command alone on its line | cleared; Finding 1 (Informational) |
| `devcontainer-config/install.sh:613-617` | S2 + S3 | none | deferred (override log); not re-raised |
| `devcontainer-config/cc-isolated.sh:819` (`--register '$ws'` suggestion) | S1 | single quotes, not `%q` | outside the diff and pre-existing. A path containing `'` would break the quoting. That path is the user's own checkout, and common forge repo names cannot contain `'`. Not raised. |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | init-firewall recipe has no `&&` (paste-both reruns a probe-gated launch) | Informational | B3, B4 | `devcontainer-config/init-firewall.sh:352-357` | High |

## Overall Assessment

This pass found no exploitable issue. Within the code paths read, the change does not weaken security. The enforcement scripts change only in comments and echo text (executed). The one new dependency, the `&&` in the printed recipe, rests on --probe-only exiting non-zero on a failed probe, and the tests verify that by execution. Both earlier findings are resolved where this unit agreed to fix them. The install.sh remainder and C4 are logged deferrals, and I found nothing new about either. Finding 1 is a consistency nicety and asks for no change. Every Endorsement Claim is `Evidence: executed` with its `Not verified` hop named, so this review does not block a merge. The most important open item is still the deferred structural hardening: `main()` should reject a second positional instead of overwriting `ws_arg`, which would close the trailing-comment class everywhere, install.sh included.

## Goal-Alignment Note

The user's goal is that the launcher's rebuild hint should stop misleading after the firewall fails closed. The unit does that. The hint's first line is now the two-step recipe from the guides, as one paste-safe command chained on the probe's exit status. "Recreate" replaces "rebuild" wherever a recreate is meant, in the launcher help, the NOTE, the bless output, the init-firewall abort message and the guide. Regression tests fail on the old text. Nothing in the diff spends attention on unrelated hardening. The one place where the user still sees a different-shaped recipe, init-firewall's two lines, is safe as it stands (Finding 1).
