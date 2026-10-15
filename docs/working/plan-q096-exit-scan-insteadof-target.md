# Plan: Q-096 — the exit scan follows insteadOf targets

**Goal**: The cc-isolated exit scan walks the URL a `url.<base>.insteadOf` / `pushInsteadOf` rule rewrites a remote to, so a session cannot repoint a push through a rewrite the scan ignores (closes Q-096).
**Project state**: one enforcement unit on `fix/q096-exit-scan-insteadof-target` · standalone (Q-097 follows on the same file) · not blocked (cite: docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md)
**Task status**: complete (implemented; review-fix loop in pr-prep)
Research: [research-q096-exit-scan-insteadof-target.md](research-q096-exit-scan-insteadof-target.md)

## Pre-mortem: bypass families (enforcement file; decision log row 61 (4))

Assume this shipped and a session still pushed through a rewrite to a hook it planted. The ways that could happen, each marked:

| # | Bypass family | Covered? | How |
|---|---|---|---|
| B1 | Rule in the checkout's own config, `remote.*.url` matches it (the Q-096 case) | covered | every URL × every rule; `<base><rest>` walked by `_snap_remote` in the URL's working tree |
| B2 | `pushInsteadOf` (applies to `url` when no `pushurl`) | covered | both kinds collected and applied to every URL, whatever git's choice |
| B3 | `pushurl` rewritten by `insteadOf` | covered | pushurl values are URLs like any other |
| B4 | Overlapping prefixes: git takes the longest, the session counts on the scan taking another | covered | the scan walks every matching rule, not only the longest |
| B5 | Rule or URL in an include target in the checkout | covered | `_snap_config` already reads includes; collection happens there |
| B6 | Rule or URL in an embedded repo, a submodule's git dir, a nested worktree, a common dir | covered | rules and URLs are pooled from every config read; over-applying a rule across repos only walks more |
| B7 | Rule in YOUR global/system config (container cannot write it), URL planted in repo config | covered | `_snap_host_config` collects `url.*.insteadof`/`pushinsteadof`, empty values included |
| B8 | Path-valued `branch.*.remote` / `pushRemote` / `remote.pushDefault`, rewritten | covered | unresolved names are queued as URLs in the closing loop |
| B9 | Legacy `remotes/*` / `branches/*` URL, rewritten | covered | those URLs are queued too |
| B10 | Rule or URL found only inside a rewritten target's own config | covered | growing worklist: new URLs meet all rules, new rules meet all URLs, each pair once |
| B11 | Relative rewritten target (base `""`, `.`, `sub/`), resolved in a worktree added later | covered | `_snap_remote` leaves a W record for a relative target, which refuses the note |
| B12 | Target missing at launch, created in the session | covered | `_snap_file` records `missing`; creation is a change |
| B13 | `..` in the URL's rest climbing out of the base into the checkout, or `file://`/`file://localhost` forms | covered | `_snap_remote`'s existing `realpath -m` and `file://` handling |
| B14 | Stall the scan with thousands of URLs × rules (quadratic) | covered | `GIT_EXIT_SCAN_MAX_REWRITES` comparisons, then the snapshot fails closed (exit 4) |
| B15 | Empty `insteadOf` value (matches every URL) | covered | an empty prefix is a match (bash `${u#""}`) |
| B16 | Case games (`HTTPS://` vs `https://`) | covered | git's match is case-sensitive; so is ours |
| B17 | Target outside the checkout | not covered, by design | not container-writable (existing `_snap_remote` rule) |
| B18 | `~` in a base | not covered | existing known route "`~` forms" (a `~` in a local remote is taken as relative) |
| B19 | `submodule.*.url` rewrites (fetch/clone, not push) | not covered, unchanged | `submodule.*` keys are already findings when changed; a fetch runs no hooks in its source |
| B20 | URL typed on the command line (`git push <url>`) | not covered | not config; no scan can see it |

No uncovered family needs a design change: B17–B20 are outside what a config scan can or must see, and B18 stays a listed known route.

Round-1 triggers: `/pre-mortem` — fired (enforcement file); this table is the adversarial pass, backed by the hermetic experiment in the research doc (acting as the spike). `/architecture-review` — not triggered (one module, `devcontainer-config/`, plus its test and guide).

## Approach

Collect URLs and rewrite rules while walking, then resolve them in the closing loop of `git_exec_snapshot` alongside the existing remote-name loop: a growing worklist where each URL is tried against each rule exactly once, and each match walks `<base><rest>` with `_snap_remote` in the URL's own working tree. Rewritten targets are never queued as URLs (git does not chain), which also rules out loops.

## Steps

1. `cc-exit-scan.sh`: new locals `_snap_urls`/`_snap_ubases`, `_snap_rbases`/`_snap_rpfx`; helper `_snap_url <url> <wt>` (queue, then `_snap_remote`); call it for `remote.*.url|pushurl`, legacy remotes/branches, and unresolved names. `_snap_config` and `_snap_host_config` queue `url.*.insteadof|pushinsteadof` rules. Closing loop: names → URLs × old rules → rules × all URLs, until nothing new; comparison cap fails closed. Update the header's WHAT IS SNAPSHOTTED text.
2. Tests in `test/cc-isolated-functions.bats`: top-level rewrite, nested (embedded repo), non-local target ignored, `pushInsteadOf`, overlapping prefixes (both targets walked), path-valued `branch.*.pushRemote` rewritten, a rule in your global config, a relative target leaving a W record, the cap.
3. Guide: drop the Known-routes bullet, describe the new behavior in the follow list.
4. Brief status `open` → `done`.

## Implementation order

1 → 2 (tests need the code) ; 3, 4 independent.

## Size estimate

~60 code lines, ~110 test lines, ~10 guide lines: ~180 changed lines outside `docs/`, under the 400 cap.

## Estimated context cost

Small: one file plus its suite.

## Actual context cost (post-implementation)

Within estimate.

## Test specification

Each new bats case plants a pre-receive hook in the rewritten target after the launch snapshot and expects `git_exit_scan` status 1 naming the hook, and `no_ran`. The non-local case expects no `remote` record for the rewritten https URL. The cap case sets `GIT_EXIT_SCAN_MAX_REWRITES` low and expects the snapshot to fail with "too many". Run `bats test/cc-isolated-functions.bats` and, before landing, `scripts/health-check.sh`.

## Risks

- Over-walking pooled rules could add W records in repos where git would not apply the rule, refusing the worktree note more often. Fail-closed direction; accepted.
- Quadratic cost: bounded by the cap.

## Rollback

Revert the commit; the scan returns to walking bases only and the guide's known route returns.
