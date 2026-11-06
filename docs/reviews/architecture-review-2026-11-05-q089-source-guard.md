Commit: cb59c2bb

# Architecture Review — test/q089-source-guard-narrow

**Scope:** `git diff db31db8b..HEAD`: `test/cc-host-tool-sources.bats` (new), the research doc, the fact-check report. Also read: `source_lines_ok` and its callers in `devcontainer-config/cc-verify.sh`, the entry points' `source` and `verify_host_tools` lines, the brief, `docs/constraints.md`, and the test at `fa059477:test/cc-isolated-functions.bats:1038`.
**Date:** 2026-11-05
**Based on:** `docs/reviews/code-fact-check-report-q089-source-guard.md`
**Severity → rubric tier:** Structural → Must Fix · Coupling → Must Address · Minor and Informational → Consider

**Scope check:** the skill would skip a test-only diff. It runs here because the dispatch asked for a judgment on a new cross-file coupling. No production file changes.

**Verdict:** the coupling is better than restating the grammar, and a new file was right. No Structural or Coupling findings. Nothing here blocks landing. One small fix is worth making (finding 1), and one sentence in the research doc should be corrected (finding 2).

## Dependency Map

```
test/cc-host-tool-sources.bats
  ├─ reads text of ─────────► cc-verify.sh: source_lines_ok, extracted by sed, then run
  │                            contract used: args DIR FILE, first bad line on stdout, global SOURCED
  ├─ greps ─────────────────► cc-isolated.sh, cc-push.sh: first verify_host_tools call
  ├─ sources in a subshell ─► cc-isolated.sh: host_tool_files (the launcher is built to be sourced)
  └─ edits its temp copy of ► cc-push.sh: CC_PUSH_DIR → CC_ISOLATED_DIR

cc-verify.sh preflight (lines 203-204, 308) ─► source_lines_ok, on cc-isolated.sh only
```

Dependencies run test → shipped code, the right direction. No shipped code depends on the test, and the diff creates no cycle. `source_lines_ok` now has two consumers, and the second is invisible from `cc-verify.sh`.

## The choice: `source_lines_ok` plus rename, against fa059477's regexes

The new design is better, by a modest margin. I probed it by mutating `cc-verify.sh` and `cc-push.sh` in a scratch copy and running the seven cases.

| Axis | fa059477 (restate) | This branch (read and rename) |
|---|---|---|
| S3, one source of truth | Fails. `canon` copies the `dirname`/`readlink` spelling from `src`, and `srcword`/`dotcmd` are a second detector. | Holds for the spelling rule. The test adds one adapter, the rename, but no regex for `source`. |
| Grammar disagreement | Already real: the research doc's 19-spelling run puts 3 spellings on fa059477's side only and `\. f` on the other. | None possible, because there is one grammar. |
| A change to `cc-verify.sh` | Not noticed. The two grammars drift apart with no failure. | Red. Five mutations all failed the suite: function renamed, `SOURCED` renamed, `src` hoisted to file scope, detector moved to a helper outside the sed range, `CC_ISOLATED_DIR` dropped from `src`. |
| A gap fixed later | Must be fixed twice. | Fixed once, and both consumers gain. |
| Reach | Wider. Any line with the word `source` is seen. | Narrower. `source` must be in a command position (finding 2). |
| Dependency shape | Self-contained test. | Content coupling to a private function, plus a rename. |
| Size | 39 lines. | 26 lines: `setup` 10, `check_entry` 16. |

**Is the coupling acceptable?** It is content coupling by the skill's definition, because the test reads a function's source text. The usual harm is silent breakage when internals change, and the probes show that harm is absent here: each mutation failed the suite rather than passing it quietly. The reasons are the `[ -s ]` check at line 24 and the `cc-gitdir.sh` positive control at line 48. The target is also a poor place to break a contract, since `cc-verify.sh:203-204` and `:308` use the same calling pattern and the same `SOURCED` global in production.

**Is it the same rule?** Mostly. Both consumers ask which files a script loads and whether each load is spelled plainly, which is what S3's "one source of truth per rule or grammar" is about. The two clauses that are not shared, `eval` and reassignment of the directory variable, are the cost (finding 1).

**Why not make it cleaner?** Each cleaner form needs a host-tool edit, which the research doc ruled out on S10 and the brief's scope:

- Making `cc-verify.sh` sourceable.
- Moving the function to a shared file. `cc-verify.sh` sources nothing today, so that adds a new sourced host tool and a new entry in the lists this test guards.
- Widening `src` to admit `$CC_PUSH_DIR`. This one also loosens a production refusal to suit a test, so rejecting it was right on the merits too.

A shared file becomes worth it if a third consumer appears.

**Is reading a shipped file from a test a precedent?** Reading is established: `test/cc-isolated-functions.bats:1136` reads the `verify_host_tools` block and `:2611` reads `GIT_EXEC_KEYS_RE` from `install.sh`. Executing extracted text is new. A search of `test/` and `scripts/` found no other case.

## Findings

Trust-boundary cross-reference: the most recent security review (`docs/reviews/security-review-q092b-pass2-2026-10-15.md`, Commit: `c9ff3e84`) maps the permission hook. No labelled boundary is touched, and that review predates this diff.

#### 1. The rename makes `cc-push.sh` pose as the launcher, and it covers one file, not the set the check walks

**Severity:** Minor
**Location:** `test/cc-host-tool-sources.bats:37-38,42,44,92`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
  sed -i 's/CC_PUSH_DIR/CC_ISOLATED_DIR/g' "$dir/cc-push.sh"
  why="$(source_lines_ok "$dir" "$entry")" || { echo "not a plain source line: $why"; return 1; }
```
```bash
  [[ "$output" == *'not a plain source line'*'. "$CC_ISOLATED_DIR/cc-gitdir.sh"'* ]]
```

`source_lines_ok` is the launcher's grammar, not a general one: `CC_ISOLATED_DIR` is in its `src` regex and in its reassignment clause. The rename is the seam where the test extends it to a file it was not written for. Rename and closure disagree on scope, and three consequences follow:

- **False red on a helper.** A helper sourced by `cc-push.sh` that itself uses `$CC_PUSH_DIR` is refused, because only `cc-push.sh` was renamed. Probe: `not a plain source line: .../cfg/cc-helper.sh: source "$CC_PUSH_DIR/cc-gitdir.sh"`. fa059477 accepted that line.
- **A message that points at text that does not exist.** A refused line in `cc-push.sh` prints as `$CC_ISOLATED_DIR`, a name absent from that file, and line 92 pins this as expected output. A developer who greps the real file finds nothing.
- **Launcher policy reaches `cc-push.sh` unstated.** `eval "true"` in `cc-push.sh` now fails as "not a plain source line" (probed), although no decision applies that rule there and the line is not a source line. Refusing a reassigned `CC_PUSH_DIR` is a gain over fa059477, so this cuts both ways.

All three fail loudly and cost minutes. The file header's "one grammar to keep" is still true for the spelling rule, but `(ISOLATED|PUSH)` at line 42 and the sed at line 44 are where a further directory variable would need adding.

**Recommendation:** rename across the set: `sed -i 's/CC_PUSH_DIR/CC_ISOLATED_DIR/g' "$dir"/cc-*.sh`. Probed: 7 of 7 still pass, and the helper seed then gets the correct `cc-helper.sh is not a host tool`. Also add to the `check_entry` comment that a refused line shows the renamed variable and that the grammar's `eval` and reassignment refusals come along with it.

#### 2. The reach given up includes a form that is plain in practice, and the research doc says it does not

**Severity:** Minor
**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`; `devcontainer-config/cc-verify.sh:56`
**Move:** 8 (extension points)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```text
Giving up those forms for one grammar is acceptable for a guard that claims only plain spellings: none of them is a plain line.
```

"Those forms" includes the one-line case arm. That is the entry points' own idiom: 17 lines in `cc-push.sh` and 13 in `cc-isolated.sh` match a loose grep for one-line arms. Sourcing a helper for one subcommand there is accidental drift of the kind this guard exists for, not obfuscation. Probe: adding `case "${1:-}" in --x) source "$CC_PUSH_DIR/cc-exit-scan.sh" ;; esac` to `cc-push.sh`, with that file not in its list, leaves case 1 green. fa059477's `srcword` sees that line. The test header does list "one-line case arms" as a miss, so the test's own claim is honest. Only the research doc's justification overreaches. The fact-check's Claim 16 already notes that the loss is wider than the three sampled forms.

This does not change the verdict. The fix for this gap is one change in `source_lines_ok`, which would close it for `cc-verify.sh`'s preflight too, and that shared fix is the benefit of a single grammar. It is not a one-character fix, though: adding `)` to the detector's prefix class refused today's launcher on prose, `(names must match exactly). Available:` at a `). ` sequence (probed).

**Recommendation:** change the sentence to say the case arm is a real, accepted loss, and why it is accepted. If the owner wants the gap closed, do it in `source_lines_ok` the next time `cc-verify.sh` is changed anyway, matching `source` after `)` but not `.`. Do not add a second detector to the test.

#### 3. Nothing in `cc-verify.sh` says the function has a second consumer

**Severity:** Informational
**Location:** `devcontainer-config/cc-verify.sh:41-47`; `test/cc-host-tool-sources.bats:23`
**Move:** 3 (module boundary)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```bash
  sed -n '/^source_lines_ok() {/,/^}/p' "$SRC/cc-verify.sh" > "$T/source-lines-ok.sh"
```

A change that breaks the contract goes red, which is the right outcome. A change that narrows the detector for `cc-verify.sh`'s own reasons also narrows the guard, and case 5 pins only two refusals, the dot source and the `$(config_dir)` path. So a detector alternative could be dropped without this suite noticing. The extraction has marker-based prior art: `# --- verify_host_tools` / `# --- end verify_host_tools` in the two copies.

**Recommendation:** no change on this branch, since it would touch a host tool and force a re-bless. The next time `cc-verify.sh` changes for another reason, add one comment line naming this test as a consumer.

## What Looks Good

- **A new file was right.** `test/cc-isolated-functions.bats` is 3325 lines and its `setup` sources the launcher, which brings in the pipefail that caused the old test's 1-in-25 flake (FP-175). The guard needs none of that, reverts in one step (S8), and carries `@category fast`. `test/cc-verify.bats` is not a better home either: its fixtures build a fake install, and the guard is about the entry points rather than `cc-verify`.
- **Dependency direction is correct.** No host tool changed, so there is no `Host-tool-tested:` trailer and no re-bless (S10).
- **Failure at the seam is loud.** The `[ -s ]` check and the positive control turn extraction and parse failures into named failures (H2).
- **The header states its own limits,** and it says where the grammar lives, so a reader can tell the guard's reach is set elsewhere.
- **Rejected options were rejected well.** The widened grammar, the shared list constant and the runtime trace were each pruned for reasons that hold up.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Rename covers one file, not the closure; misleading messages; launcher policy applied to `cc-push.sh` | Minor | `test/cc-host-tool-sources.bats:37-44,92` | High |
| 2 | Case arm is a realistic lost form; research doc says it is not plain | Minor | `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58` | High |
| 3 | Second consumer invisible from `cc-verify.sh`; guard's reach can narrow unseen | Informational | `devcontainer-config/cc-verify.sh:41-47` | Medium |

## Overall Assessment

The change keeps the system's structure intact. It adds one test-to-shipped-code dependency in the right direction, and that dependency fails loudly under every mutation tried. Against fa059477 it trades some reach for S3 compliance, and that trade is right for a guard that claims only plain spellings. The most important structural concern is the rename, because it is where a launcher-specific grammar is stretched over a second entry point. It is fixable in place with one line and a comment. Findings 1 and 2 can both be fixed on this branch without touching a host tool.

## Goal-Alignment Note
- Success criterion (restated verbatim): a critique at docs/reviews/architecture-review-2026-11-05-q089-source-guard.md with a `Commit:` line, ending in a Goal-Alignment Note. Findings carry Severity, Location, verbatim Evidence, Confidence, Legibility-target. Do not commit or edit anything else.
- Answered: yes; the coupling and rename are judged better than fa059477's restated grammar, and the new file is judged right.
- Out of scope: the runtime safety of `cc-verify.sh`'s preflight, including its shared case-arm gap, which is documented in its comment; test correctness beyond the coupling.
- Escalate: nothing
- Decisions I made: rated the coupling Minor rather than Coupling because every probed contract break failed loudly, though a strict reading of "content coupling" would rate it higher; ran the full review despite the skill's test-only skip, as dispatched.
