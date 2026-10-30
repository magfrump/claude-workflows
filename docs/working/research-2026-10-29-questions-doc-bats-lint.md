# Research: questions-doc.bats shellcheck findings

Brief: `docs/working/briefs/2026-10-29-questions-doc-bats-lint.md` (dispatch 1). Test-only change.

## Findings

Running the health check's own invocation, `shellcheck -x -e SC1091 -s bash -S warning test/questions-doc.bats`, at 2b239b87 reports three findings:

- line 286, SC2154: `$stderr` referenced but not assigned. The test already uses
  `run --separate-stderr`. Shellcheck cannot see that bats assigns `$stderr`, and it reports
  only the first read of each variable, which is why line 297 was not flagged. The same file
  already silences this at its other first-read site (former line 389) with
  `# shellcheck disable=SC2154  # $stderr is set by \`run --separate-stderr\``.
- lines 306 and 324, SC2314: a bare `! grep ...` that is not the last command. Bats runs tests
  under `set -e`, and bash ignores `set -e` for a `!`-negated pipeline. A match therefore
  did not fail the test, so both assertions were inert (shown below).

Bats in the sandbox is 1.8.2, and the file already declares `bats_require_minimum_version 1.5.0`,
so `run !` is available. It is the house idiom (`test/init-firewall-rules.bats`,
`test/code-review-gate.bats`, `test/cc-verify.bats`).

## Design choice

One option clearly wins. The options considered:

- SC2154: (a) a per-line directive at 286; (b) a file-level directive, as in
  `test/cross-model-review-stage1.bats`; (c) assign `stderr` to something. Option (b) would
  also hide a real unassigned `$stderr` in any future test. Option (c) changes the test. (a)
  matches this file's own convention. I probed it on a copy: with the directive at 286,
  line 297 is not reported, because shellcheck flags each variable once. **Chosen: (a).**
- SC2314: (a) `run ! grep ...`; (b) `if grep ...; then return 1; fi`; (c) a file-level
  disable. (c) leaves the assertions inert, and (b) works but is not the house idiom.
  **Chosen: (a)**, followed by `[ "$status" -eq 1 ]`. `run !` accepts any nonzero exit,
  including grep's 2 for an unreadable or missing file, so the status line keeps "no match"
  separate from "file gone". That makes the check stricter and does not change what it is
  meant to check. Neither `run` overwrites an `$output`/`$status` that a later line reads:
  each is followed by its own `run` or by plain commands.

Constraints: H3 (hermetic, sandbox-verified) holds. S8 holds (a one-revert change of a few lines).
No other constraint applies to a test-only edit.

## Hand-broken checks

Each negative grep was broken once by widening its pattern so it matches, in copies under
the scratchpad with a copied `scripts/`. The run uses `bats -f` on the one test:

| Break | Old (bare `!`) | New (`run !`) |
|---|---|---|
| A: `'^### Q-004'` → `'^#'` in the live file (archive test) | `ok`: inert | `not ok`, line 309: `run ! grep -aq '^#' ...` failed, expected nonzero exit code |
| B: `` '^\| `' `` → `'^'` in the archive (init route-table test) | `ok`: inert | `not ok`, line 328: `run ! grep -aq '^' ...` failed, expected nonzero exit code |
| C: archive path → `docs/working/no-such-file.md` (grep exits 2) | n/a | `not ok`, line 329: `[ "$status" -eq 1 ]` failed |

## Result

- `shellcheck -x -e SC1091 -s bash -S warning test/questions-doc.bats`: no output, exit 0.
- `bats test/questions-doc.bats`: 32/32 ok.
- `bash scripts/health-check.sh`: exit 0, "All checks passed."
