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

Question: does today's suite already catch this, which would make the test redundant? Three seeded plain-spelling drifts, each in a scratch copy of the tree, against `test/cc-isolated-functions.bats` and `test/cc-push.bats` (baseline: 260 ok, 0 failed, `LC_ALL=C`):

| Seed | Today's suite | This test |
|---|---|---|
| S1: `cc-push.sh` gains `source "$CC_PUSH_DIR/cc-exit-scan.sh"`, not in its list | 1 fails, `test/cc-push.bats:803`, only because that fixture lacks the file: the failure does not mention the list | fails: `cc-push.sh sources cc-exit-scan.sh unchecked` |
| S2: `cc-gitdir.sh` dropped from the launcher's check | 1 fails, the refusal test that names that tool | fails: `cc-isolated.sh sources cc-gitdir.sh unchecked` |
| S3: finding A6's case: a new `cc-helper.sh` sourced by the scan, added to `host_tool_files`, PAYLOAD, the hook's regex, the fixtures and the pinned lists, but not to the launcher's check | **260 ok, 0 failed** | fails: `cc-isolated.sh sources cc-helper.sh unchecked` |

S3 settles it. The two names in use today are pinned by other tests, by accident of those tests' fixtures; a new helper is not. After every step the suite forces, the installed launcher would source a file with no hash check, and nothing says so. That breaks row 71's stated rule ("Each entry point checks the host tools it executes before sourcing them") in the quiet way H2 rules out.

The case against: the event is rare. The sourced set has not changed since Q-089, and `cc-verify.sh` joined the host tools without sourcing anything. The runtime checks do not depend on the test, and row 71 places this under non-targeted tampering, as defence in depth. But the cost is also small: one fast test file, no runtime code, no owner attention unless it goes red, and S6's observable is there (it can go red; S3 shows it does). Landing beats retiring, modestly. The old review's trouble was the claim, not the test.

## Design

Options (divergent design, Path A). Prior pruning grep: no matches found for [source, host tool, bash parse] beyond decision 017's "grep table in the bats suite", which was pruned because a bats test cannot lint another repo; that does not apply here.

Constraints: S5, S3 (one grammar), S8 (small, one revert), H3 (hermetic), H1 and S10 (no change to a host tool, which would need a `Host-tool-tested:` trailer and a re-bless), and the brief's out-of-scope line (no widening).

| Candidate | Verdict |
|---|---|
| 0. Retire (status quo) | Survives the hard lines; loses on S3's seed: leaves A6 open for about 100 lines of test saved |
| 1. fa059477's test unchanged but for its wording | Survives. Brings a second copy of the spelling grammar |
| 2. Same closure check, spelling rule read from `cc-verify.sh`'s `source_lines_ok` | **Picked** |
| 3. Loose: match only `^source "..."` lines | Survives, dominated: no refusal of a dot source or `builtin source`, so a plain variation passes silently |
| 4. Widen `source_lines_ok` to admit `$CC_PUSH_DIR` | Pruned: edits a host tool for a test's benefit (H1, S10) |
| 5. Parse with `shfmt --to-json` | Pruned: widening, out of scope; a test dependency on a tool the repo's tests do not otherwise need (S8) |
| 6. Trace the sources at run time (`extdebug`, `set -x`) | Pruned: a conditional `source` on an untaken path is not seen, and it is a new mechanism |
| 7. Derive the check list from the `source` lines inside `verify_host_tools` | Pruned: new parsing in the trust path, in two byte-pinned copies; S1 proportion |
| 8. One shared list constant per entry point | Pruned: a runtime refactor of host tools for a rare event; out of scope |

Option 2 over option 1: `cc-verify.sh` shipped the same grammar after this test was split off (its comment cites Q-147). Bringing the old regexes back would restate a rule that now exists in shipped, reviewed code, which S3 forbids, and it is shorter. The cost is one rename: `source_lines_ok` does not know `$CC_PUSH_DIR`, so the test renames that variable in its copy of `cc-push.sh`. The change in reach, from running both grammars over 19 spellings:

- Seen by fa059477 only: `FOO=1 source f`, a one-line case arm `a) source f ;;`, `"source" f`.
- Seen by `source_lines_ok` only: `\. f`, and `eval` with no `source` on the line.
- Seen by both: the plain forms, `if source`, `&& source`, `; source`, `builtin source`, `command .`, `\source`, `eval "source x"`, and a trailing comment.
- Seen by neither: `FOO=1 . f`, `a) . f ;;`, `'.' f`, `$c f`, `so""urce f`.

Neither is complete, and the file header says so, listing only what this grammar misses. Giving up three forms for one grammar is acceptable for a guard that claims only plain spellings.

Other choices, one line each:

- New file rather than the 3325-line `test/cc-isolated-functions.bats`: it has no use for that file's setup, and one revert removes it.
- Comment lines are dropped before reading the check list, so a comment quoting a call cannot stand in for it.
- A permanent seeded-drift case per failure path (H2), not only a one-off run: the repo's largest failure family is assertions that could not fail.
- `cc-verify.sh` is not walked: it has no `verify_host_tools` call and sources nothing. The `--list` argument lists (`cc-isolated.sh:527-528`) are separate copies and are not compared. The file header states both limits; widening is out of scope.

Doc change: `cc-verify.sh`'s comment ("as row 71's Q-147") and row 71 ("because grep cannot cover every bash spelling") already claim no more than the test does, so neither changes. No guide names the guard.

## Runs

Against today's code, in the worktree: `bats test/cc-host-tool-sources.bats`, 7 ok. The test as it stood at fa059477, appended to a scratch copy, also passes today's code.

Seeded run S3 (the scratch tree, then `bats`):

```
existing: ok=260 not-ok=0
new: ok=5 not-ok=2
not ok 1 plain source lines in the entry points stay inside their verify_host_tools lists
# cc-isolated.sh sources cc-helper.sh unchecked
not ok 4 a new helper in the check list but not in host_tool_files is named
```

(Case 4 fails there only because the seed has already made `cc-helper.sh` a host tool.) The seeds' sed edit of the hook's regex was imprecise and made `test/hooks/live-verify-gate.bats` case 26 fail: that case forces the regex, not the check list, so S3 still stands.

## Files read

Last verified: 2026-11-05

- `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md`
- `test/cc-isolated-functions.bats` at fa059477 and at db31db8b
- `devcontainer-config/cc-isolated.sh`, `cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`, `cc-verify.sh`
- `docs/decisions/log.md` row 71
