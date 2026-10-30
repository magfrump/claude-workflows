Commit: 980a9db4

# Security Review — fix/rebuild-hint-recreate, iteration 2 (hint comment on its own line)

**Scope:** `git diff cb56299c..980a9db4` (devcontainer-config/cc-isolated.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats); cb56299c is context only
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-2026-10-15-rebuild-hint-i2.md; iteration 1: docs/reviews/security-review-2026-10-15-rebuild-hint.md

## Trust Boundary Map

```
B1: [host workspace path ($ws, git toplevel)]   → [printf %q in rebuild_hint :567]       → [terminal text the user copies into a host shell]
B2: [copied hint lines in the user's host shell] → [main() arg parser :758, last positional wins] → [which repo is recreated, probed, launched]
B3: [--probe-only exit status :891-893]          → [`&&` in the printed recipe]           → [second `cc-isolated WS`, which re-probes before claude]
B4: [placeholder recipes in sibling output (cc-isolated.sh:317, init-firewall.sh:349-350, install.sh:613-616)] → [user substitutes <repo>, pastes] → [B2 parser]
```

Input sources:

```
S1: $ws (git toplevel of the user's arg)   — request-time  — UNTRUSTED toward the shell-source sink (printed copy line); trusted for identity once resolved
S2: hint/recipe literal text               — code-constant — trusted as text; becomes ARGUMENTS when pasted into a shell that does not treat `#` as a comment
S3: CC_* launcher env (by-hand form)       — launcher-set  — unchanged by this diff
S4: STUB_* test env                         — test-only     — trusted
```

The commit changes only printed text, comments, a guide and tests. No non-comment, non-echo line of cc-isolated.sh changed (fact-check: Verified; confirmed by reading the diff and `rebuild_hint` :558-574, `probe_boundary` through :713, and the `--probe-only` branch :888-894 in full). The arg parser (:740-759) is unchanged and still overwrites `ws_arg` with each positional, which is why S2 text on a copyable line matters.

### Iteration-1 findings re-checked

- **#1 (Medium) — resolved for the line it named.** :567 now prints only the command; the explanation is on :568. Executed (scratch stub of `cc-isolated` that reports its last positional, workspace `/tmp/my proj`, both printed lines pasted together): `bash --norc -i`, `zsh -f -i`, `zsh -f -i -o extendedglob` and `zsh -f -i -o interactivecomments` all ran both steps with `ws_arg=[/tmp/my proj]`. The test at test/cc-isolated-functions.bats:360 now pins the whole first line by equality, so a re-added trailing comment fails it.
- **Line 2 pasted along with line 1 — not harmful.** `      (the supported path: ... then launches)` parses as a subshell running a command named `the`; every shell above printed `command not found: the` and nothing else ran. It would execute something only if an executable named `the` were on PATH. In the real flow step 2 holds the terminal (it ends in `claude`), so a pasted line 2 may instead arrive as typed text in the Claude prompt inside the container. That is a benign sentence sent to the sandboxed agent, not host shell input.
- **#2 (Informational) — resolved.** New test :1428-1442 asserts non-zero status, `PROBE FAIL (firewall)`, the forced `--remove-existing-container`, and no `verified-live.sha256` receipt. The status and receipt assertions are the ones that hold weight: wrapping `probe_boundary "$ws"` as `|| true`, or in an `if` that falls through to `exit 0` (:893), would fail them. See Finding 2 for the one assertion that cannot fail.
- **#3 (Informational, deferred)** — unchanged, as expected.

## Findings

#### 1. Placeholder recipes elsewhere keep the trailing-`# ...` form; once `<repo>` is filled in, default zsh retargets the launch to `node` or `session`

**Severity:** Medium (floor rule: same named mechanism as iteration-1 #1, reachable in default interactive zsh; the likelihood is low, see Confidence)
**Location:** `devcontainer-config/init-firewall.sh:350` (session-starting; pre-existing, outside this commit); also `devcontainer-config/cc-isolated.sh:317` (reworded by this commit), `devcontainer-config/init-firewall.sh:349`, `devcontainer-config/install.sh:613-616` (pre-existing)
**Boundary:** B4 → B2
**Move:** 12 (sweep sibling sites of the primitive the iteration-1 fix engaged), 2
**Confidence:** High that the mechanism exists (executed); Low that it ever reaches a wrong repo (needs the user to keep the comment and a git repo named `session`/`node` in their cwd; otherwise `ERROR: not a directory`)
**Legibility-target:** users copying recipes from the init-firewall abort message and the bless output; the rebuild_hint comment at cc-isolated.sh:565-566, which states the hazard for one line only

Evidence (verbatim):
- init-firewall.sh:350: `    echo "         cc-isolated <repo>                 # then start the session" >&2`
- cc-isolated.sh:317: `    echo "  Next: cc-isolated --probe-only <repo>   # recreates from it and probes as node"`
- cc-isolated.sh:758: `      *)            ws_arg="$1"; shift ;;`

To answer the brief directly: no copyable line with a trailing comment prints a **real** path any more. All the remaining ones print the `<repo>` placeholder. A placeholder exists to be replaced, though, and the comment is likely to survive the edit. Executed in `zsh -f -i` with the stub: `cc-isolated --probe-only /tmp/api   # recreates from it and probes as node` gave `ws_arg=[node]`, and `cc-isolated /tmp/api                 # then start the session` gave `ws_arg=[session]`. If `./session` were a git repo, the second would start a session on a repo the user did not name. That is the H1 property iteration-1 #1 was rated on. The line is printed on the exact fail-closed path this branch is about. The :317 variant reaches only `--probe-only`, which starts no session, and the receipt it writes is config-scoped (`record_verified_live` :114-115 writes `blessed_hash`), so a probe of `./node` still genuinely verifies the blessed config. Taken alone, that variant violates no security property. The iteration-1 fix was applied to one call site of a pattern that has five.

**Recommendation:** Apply the same fix to the siblings: put each explanation on its own line, or drop it (cheap, five echo lines; init-firewall.sh:350 first). If this is deferred, record it in the override log as the iteration-1 #1 sweep remainder, since init-firewall.sh is boundary code and its output is what the fail-closed user sees. The optional hardening from iteration 1 still applies and would close the whole class: make `main()` reject a second positional instead of overwriting `ws_arg`.

#### 2. The new --probe-only fail-case test's "starts no session" assertion cannot fail, and the test comment overstates the iteration-1 mechanism

**Severity:** Informational
**Location:** `test/cc-isolated-functions.bats:1440`; `test/cc-isolated-functions.bats:355-358`
**Boundary:** B3
**Move:** 3
**Confidence:** High (fact-check: Mostly accurate on both)
**Legibility-target:** future editors of the --probe-only branch and of rebuild_hint's test

Evidence: `  run ! grep -q ' claude$' "$DC_LOG"` (:1440); `  # and the last positional wins, retargeting the launch (security review` (:357)

The --probe-only branch (:888-894) has no `claude` exec on any path, so :1440 holds even if the probe passes. The test's real guards are `[ "$status" -ne 0 ]` and `[ ! -f "$(verified_path)" ]`, and those are sound. The comment at :357 says the trailing comment "retargets the launch". Usually it does not: the result is `ERROR: not a directory: launches` unless `./launches` is a git repo. That is accurate as a mechanism but reads as the common outcome. Neither line weakens a guard.

**Recommendation:** Optional. Reword :357 to "can retarget the launch (usually a not-a-directory error)", and either drop :1440 or comment it as documenting intent rather than guarding.

## Untested bypass candidates

None open. The B1 shell-quoting candidates from iteration 1 (space, `;`, `$(...)`, backticks, quotes, `!`, newline, `*`) are unaffected: :567 keeps the same `printf '%q'` expansions and only drops trailing text. I re-ran a path containing a space through all four shell configurations above. The candidates for the new line 2 (bash, zsh default, zsh extendedglob, zsh interactivecomments) were executed: each ran only `the` and reported command not found.

## Endorsement Claims

- **Claim:** Pasting rebuild_hint's first printed line (alone or together with line 2) passes the workspace path as the last positional to both steps in bash and zsh, with or without `interactivecomments`/`extendedglob`.
  **Location:** `devcontainer-config/cc-isolated.sh:567-568`
  **Evidence:** executed
  **Verified:** the printed line shape for `/tmp/my proj`, piped into `bash --norc -i` and three `zsh -f -i` variants with a stub `cc-isolated` that reports its last positional: `ws_arg=[/tmp/my proj]` for both steps in every shell.
  **Not verified:** user shells with rc-file aliases or functions named `cc-isolated` or `the`; the tty hand-off when step 2's `claude` reads the rest of a multi-line paste.
  **route: code-fact-check**
- **Claim:** No executable line of cc-isolated.sh changed in this commit. The only edits are comments and the text of echo/printed lines (:10, :61-63, :317, :565-568, :882-885).
  **Location:** `devcontainer-config/cc-isolated.sh` (diff-i2.patch)
  **Evidence:** read-static
  **Verified:** every hunk of diff-i2.patch for cc-isolated.sh; matches the fact-check's Verified claim.
  **Not verified:** runtime behaviour of the full launcher beyond the bats suite (195 tests, all ok, via `scripts/run-tests.sh`).
  **route: code-fact-check**
- **Claim:** A --probe-only run whose probe fails exits non-zero and writes no verified-live receipt, and a test pins both.
  **Location:** `devcontainer-config/cc-isolated.sh:706-709, :888-894`; `test/cc-isolated-functions.bats:1428-1442`
  **Evidence:** executed
  **Verified:** test 104 passes. I read `probe_boundary`'s `return 1` before `record_verified_live` and the `--probe-only` branch under `set -euo pipefail`.
  **Not verified:** callers that invoke cc-isolated.sh under `|| true` or `set +e` wrappers (none in this repo's recipes; not swept outside them).
  **route: code-fact-check**

## Primitive sweep

Primitive: printed text a user pastes into a host shell (shell-source sink, S2; S1 where a real path is interpolated)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `devcontainer-config/cc-isolated.sh:567` | S1 $ws | `printf %q`, no trailing text | cleared, executed (iteration-1 #1 fixed) |
| `devcontainer-config/cc-isolated.sh:568` | S2 | none needed | cleared: subshell runs `the` → not found |
| `devcontainer-config/cc-isolated.sh:572-573` (by-hand form) | S1, S3 | `printf %q` | cleared: unchanged, iteration-1 executed |
| `devcontainer-config/cc-isolated.sh:317` | S2 + user-filled `<repo>` | none | Finding 1 (probe-only: no session, config-scoped receipt) |
| `devcontainer-config/init-firewall.sh:349` | S2 + user-filled `<repo>` | none | Finding 1 (probe-only) |
| `devcontainer-config/init-firewall.sh:350` | S2 + user-filled `<repo>` | none | Finding 1 (session-starting, `ws_arg=session`) |
| `devcontainer-config/install.sh:613-616` | S2 + user-filled `<repo>` | none | Finding 1 (pre-existing; not executed individually, same form) |
| `guides/cc-isolated-usage.md:83` (troubleshooting row) | S2 inline code spans | separate spans, no trailing `#` | cleared: read-static |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Placeholder recipes keep trailing `# ...`; filled-in `<repo>` retargets to `node`/`session` in default zsh | Medium | B4→B2 | `init-firewall.sh:350` (+ `cc-isolated.sh:317`, `init-firewall.sh:349`, `install.sh:613-616`) | High mechanism / Low likelihood |
| 2 | New fail-case test's no-claude assertion cannot fail; test comment overstates the retarget | Informational | B3 | `test/cc-isolated-functions.bats:1440, :357` | High |

## Overall Assessment

The commit resolves iteration-1 #1 for the line it named and adds the fail-case test that #2 asked for. It changes no enforcement logic, and executed checks confirm that the printed recipe now targets the named repo in every shell configuration tried. Pasting line 2 along with it is harmless. The one open item is the iteration-1 pattern at its sibling sites. These print a placeholder rather than a real path, so they are less likely to be pasted unedited. Still, init-firewall.sh:350 sits on the same fail-closed path and can start a session on an unnamed repo in default zsh. It is fixable in place (five echo lines), is pre-existing and outside this commit's diff, and the most important thing is to sweep it now or defer it explicitly. No findings within the code paths read block this unit. The endorsement claims are pending execution verification by code-fact-check.

## Goal-Alignment Note

The user goal is to stop the launcher's hint from misleading after a fail-closed firewall. This commit serves it directly: the hint's recipe is now a clean copyable command, and "recreate" means recreate in the help text, the NOTE and the guide. Finding 1 is adjacent to the goal, not a regression from it. The same fail-closed abort message in init-firewall.sh gives a recipe whose trailing comment can redirect the second step in default zsh. Sweeping it would finish the "hint doesn't mislead" intent across both places the user sees a recovery recipe. Deferring it is defensible if it is logged.
