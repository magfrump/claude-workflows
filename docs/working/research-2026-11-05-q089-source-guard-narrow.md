# Research: land or retire the Q-089 static source-set test (Q-147)

Brief: `docs/working/briefs/2026-11-05-q089-source-guard-narrow.md` (dispatched at db31db8b).
Workflow: research-plan-implement, no plan-approval gate; then pr-prep's Step 0 and review-fix loop.

**Decision: land it,** as `test/cc-host-tool-sources.bats`, with the claim narrowed to plain spellings and accidental drift, and with the spelling rule read from `cc-verify.sh` rather than restated.

## Gotchas

Failure-pattern grep: FP-082, FP-175

- FP-082 (a literal grep broken by an inserted argument): a grep-based test goes wrong quietly when the text moves. The test keeps fa059477's positive control (both entry points must reach `cc-gitdir.sh`), and a missing check call fails, so neither case passes empty.
- FP-175 (`echo | grep -q` SIGPIPE under pipefail): the source of R2's 1-in-25 flake. The new file does not source the launcher into the test shell, so it has no pipefail, and it still uses a here-string.

## What the old review said

The rubric's "Iteration-4 gate" section records why the test left unit A. Every pass converged on the runtime code. The one thing that did not converge was a test claiming a completeness grep cannot meet (`FOO=1 . f`, case arms, `\. f`, quoted or obfuscated `source`, `$c f`). Its instruction for this unit: "scope the claim honestly: it guards plain spellings against accidental drift and is not complete for bash." The finding behind it is A6: each entry point's `verify_host_tools` list is tied to its transitive `source` lines by nothing, so a new helper sourced by the scan "would be forced into `host_tool_files` by tests, but the launcher would still source it unchecked."

## Motive test (S5)

Question: does today's suite already catch this, which would make the test redundant? Three seeded plain-spelling drifts (D1 to D3, so as not to read as constraints), each in a scratch copy of the tree, against `test/cc-isolated-functions.bats` and `test/cc-push.bats` (baseline: 260 ok, 0 failed, `LC_ALL=C`):

| Seed | Today's suite | This test |
|---|---|---|
| D1: `cc-push.sh` gains `source "$CC_PUSH_DIR/cc-exit-scan.sh"`, not in its list | 1 fails, `test/cc-push.bats:803`, only because that fixture lacks the file: the failure does not mention the list | fails: `cc-push.sh sources cc-exit-scan.sh unchecked` |
| D2: `cc-gitdir.sh` dropped from the launcher's check | 1 fails: `test/cc-isolated-functions.bats:1193` asserts that the refusal names that tool | fails: `cc-isolated.sh sources cc-gitdir.sh unchecked` |
| D3: finding A6's case: a new `cc-helper.sh` sourced by the scan, added to `host_tool_files`, PAYLOAD, the hook's regex, the fixtures and the pinned lists, but not to the launcher's check | **260 ok, 0 failed** | fails: `cc-isolated.sh sources cc-helper.sh unchecked` |

D3 settles it. Dropping a name in use today is caught, directly (`cc-isolated-functions.bats:1193`, `cc-push.bats:806`); D1's catch is a fixture accident, and with the fixture copying the file `test/cc-push.bats` passes 48 of 48 with the seed in. A new helper is not caught at all. D3 ran the two suites above; `test/cc-verify.bats` and `test/install-host.bats` also need `cc-helper.sh` in a fixture, and with that they match the baseline. The full suite was not run on the seed. A live probe from the fact-check confirmed the result: a tampered helper ran with `HOST_TOOLS_ERR` empty, while the `cc-gitdir.sh` control was refused. So after the fixes the suite asks for, the installed launcher would source a file with no hash check, and nothing says so. That breaks row 71's stated rule ("Each entry point checks the host tools it executes before sourcing them") in the quiet way H2 rules out.

The case against: the event is rare. The sourced set has not changed since Q-089, and `cc-verify.sh` joined the host tools without sourcing anything. The runtime checks do not depend on the test, and row 71 places this under non-targeted tampering, as defence in depth. But the cost is also small: one fast test file, no runtime code, no owner attention unless it goes red, and S6's observable is there (it can go red; D3 shows it does). Landing beats retiring, modestly. The old review's trouble was the claim, not the test.

## Design

Options (divergent design, Path A). Prior pruning grep: no matches found for [source, host tool, bash parse] beyond decision 017's "grep table in the bats suite", which was pruned because a bats test cannot lint another repo; that does not apply here.

Constraints: S5, S3 (one grammar), S8 (small, one revert), H3 (hermetic), H1 and S10 (no change to a host tool, which would need a `Host-tool-tested:` trailer and a re-bless), and the brief's out-of-scope line (no widening).

| Candidate | Verdict |
|---|---|
| 0. Retire (status quo) | Survives the hard lines; loses on seed D3: leaves A6 open to save about 100 lines of test |
| 1. fa059477's test unchanged but for its wording | Survives. Brings a second copy of the spelling grammar |
| 2. Same closure check, spelling rule read from `cc-verify.sh`'s `source_lines_ok` | **Picked** |
| 3. Loose: match only `^source "..."` lines | Survives, dominated: no refusal of a dot source or `builtin source`, so a plain variation passes silently |
| 4. Widen `source_lines_ok` to admit `$CC_PUSH_DIR` | Pruned: edits a host tool for a test's benefit (H1, S10) |
| 5. Parse with `shfmt --to-json` | Pruned: widening, out of scope; a test dependency on a tool the repo's tests do not otherwise need (S8) |
| 6. Trace the sources at run time (`extdebug`, `set -x`) | Pruned: a conditional `source` on an untaken path is not seen, and it is a new mechanism |
| 7. Derive the check list from the `source` lines inside `verify_host_tools` | Pruned: new parsing in the trust path, in two byte-pinned copies; S1 proportion |
| 8. One shared list constant per entry point | Pruned: a runtime refactor of host tools for a rare event; out of scope |

Option 2 over option 1: `cc-verify.sh` shipped a grammar for the same rule after this test was split off (its comment cites Q-147). Bringing the old regexes back would restate a rule that now exists in shipped, reviewed code, which S3 forbids; the code is no longer than the old test's. The cost is two adjustments to the test's copies: `source_lines_ok` does not know `$CC_PUSH_DIR`, so the test renames that variable in every copy, and it adds a final newline to each. The change in reach, from running both grammars over a sample of 19 spellings:

- Seen by fa059477 only: `FOO=1 source f`, a one-line case arm `a) source f ;;`, `"source" f`. Outside the sample, the same holds for anything with the word on the line, such as `trap 'source f' EXIT` and `bash -c 'source f'`; and fa059477's dot regex also sees `exec . f`.
- Seen by `source_lines_ok` only: `\. f`. Outside the sample, also `eval` with no `source` on the line.
- Seen by both: the plain forms, `if source`, `&& source`, `; source`, `builtin source`, `command .`, `\source`, `eval "source x"`, and a trailing comment.
- Seen by neither: `FOO=1 . f`, `a) . f ;;`, `'.' f`, `$c f`, `so""urce f`.

Neither is complete, and the file header says so, listing only what this grammar misses. The real loss is the one-line case arm, which is these files' own idiom: an unchecked `--x) source ...` in `cc-push.sh` leaves the test green. It is accepted and the file header names it. The fix belongs in `source_lines_ok`, a host-tool change, and adding `)` to its detector alone refuses today's launcher on prose. The architecture review compared the two and rated the reuse better by a modest margin.

Other choices, one line each:

- The test adds a final newline to its copies: `source_lines_ok`'s read loop never sees an unterminated last line (security review F1). The shipped function has the same gap; fixing it is a host-tool change, left as a follow-up.
- New file rather than the 3325-line `test/cc-isolated-functions.bats`: it has no use for that file's setup, and one revert removes it.
- Full-line comments are dropped before reading the check list, so such a comment quoting a call cannot stand in for it. An end-of-line comment still can.
- A permanent seeded-drift case per failure path of `check_entry` (H2), not only a one-off run: assertions that could not fail are a large family in `docs/failure-patterns.md` (17 `vacuous-assertion` entries).
- `cc-verify.sh` is not walked: it has no `verify_host_tools` call and sources nothing. The `--list` argument lists (`cc-isolated.sh:527-528`) are separate copies and are not compared. The file header states both limits, and that it checks list membership, not whether the check runs before the `source` (for the names in use, the launch tests in `test/cc-isolated-functions.bats` cover the launcher, and `test/cc-push.bats:797-808` covers cc-push); widening is out of scope.

Doc change: `cc-verify.sh`'s comment ("as row 71's Q-147") and row 71 ("because grep cannot cover every bash spelling") already claim no more than the test does, so neither changes. No guide names the guard.

## Runs

Against today's code, in the worktree: `bats test/cc-host-tool-sources.bats`, 9 ok. The test as it stood at fa059477, appended to a scratch copy, also passes today's code.

Seeded run D3 (the scratch tree, then `bats`), with the file at its final nine cases:

```
existing: ok=260 not-ok=0
new: ok=7 not-ok=2
not ok 1 plain source lines in the entry points stay inside their verify_host_tools lists
# cc-isolated.sh sources cc-helper.sh unchecked
not ok 6 a new helper in the check list but not in host_tool_files is named
```

(Case 6 fails there only because the seed has already made `cc-helper.sh` a host tool.) The seed's sed edit of the hook's regex was imprecise and made `test/hooks/live-verify-gate.bats` case 26 fail: that case forces the regex, not the check list, so D3 still stands; with the regex edited exactly, that file passes 35 of 35.

## Files read

Last verified: 2026-11-05

- `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md`
- `test/cc-isolated-functions.bats` at fa059477 and at db31db8b
- `devcontainer-config/cc-isolated.sh`, `cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`, `cc-verify.sh`
- `docs/decisions/log.md` row 71
