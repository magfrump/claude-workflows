Commit: 0304a2c

# Security Review — review/q065 (Q-065 [1], final confirming pass)

**Scope:** `git diff main...HEAD` at 0304a2c: `scripts/lib/si-input.sh`, `test/si-input-parse-comments.bats` (new), `test/si-input-rejected-history.bats` (deleted), `docs/reviews/override-log.md` (one added row). The `docs/reviews/q065-*.md` review artifacts are out of scope.
**Date:** 2026-09-28
**Based on:** `docs/reviews/q065-code-fact-check-report.md` (Commit 0304a2c; 19 verified, 1 mostly accurate, 0 incorrect)

## Trust Boundary Map

```
B1 (removed): [round-<N>-report.json reject_reason text] → [prepend_si_input_rejected_history: jq extract + mktemp/mv rewrite] → [si-input.md on disk]
B2:           [si-input.md (user-edited file)]           → [parse_si_input comment/heading state machine]                   → [SI_* vars → USER_INPUT_CONTEXT prompt injection]
B3:           [bats fixtures (code-constant)]            → [mktemp -d scratch dir]                                          → [parse_si_input under test]
```

The diff removes B1 entirely and leaves B2's code unchanged (the library hunks are `@@ -9,9 +9,6 @@` and `@@ -196,117 +193,6 @@`, both pure deletions; fact-check Claims 3 and 13). B3 is test-only.

Input-source classification:

```
S1: round-<N>-report.json reject_reason   — runtime-mutable (written by prior SI rounds / model output) — UNTRUSTED for file-write and prompt sinks; source removed with B1
S2: $WORKING_DIR/si-input.md              — runtime-mutable (user-edited)  — trusted as user intent for prompt content; untrusted for shell-eval sinks (none exist)
S3: printf fixtures in the bats file      — code-constant                  — trusted (all sinks)
S4: mktemp -d path (TEST_TMPDIR)          — runtime-generated              — trusted for the test's own rm -rf sink
```

The diff makes no new trust assumption. It removes the one path (B1) by which text from S1, which a model-produced rejection reason could shape, was written into a file the loop later parses.

## Findings

No findings.

Moves applied: #1 (boundary map above), #2 (S2 flows only into assignment and `[[ ]]` pattern tests at `scripts/lib/si-input.sh:52-112`; no `eval`, command substitution, or unquoted expansion of line content: unchanged by the diff), #3 (teardown `rm -rf "$TEST_TMPDIR"` at `test/si-input-parse-comments.bats:15`: if `mktemp -d` failed, the variable is empty and `rm -rf ""` removes nothing; quoted, so no word-splitting), #4 (the removed helper's `mktemp "${input_file}.XXXXXX"` → `mv` sequence at `main:scripts/lib/si-input.sh:284-305` is deleted, so its non-atomic read-then-rewrite of si-input.md no longer exists), #12 (sweep below). Moves #5-#11 have no subject in this diff: no auth, secrets, serialization changes, crypto, dependency manifests or guardrail edits. The HTML-comment skip in `parse_si_input` is a parser rule, not a security guardrail, and is unchanged.

## Endorsement Claims

- **Claim:** The diff removes every call site of the `mktemp`→`mv` file-rewrite primitive and the `jq`-over-report-JSON read that fed it, and adds no new file-write, exec, or eval primitive to `scripts/`.
  **Location:** `main:scripts/lib/si-input.sh:199-308` (deleted); `scripts/lib/si-input.sh:1-204`
  **Evidence:** executed
  **Verified:** `git diff --stat main...HEAD` shows `scripts/lib/si-input.sh | 114 ---------` (deletions only); the deleted hunk contains the only `mktemp`, `mv` and `jq ... "$report"` in that file at main; `git grep` over `scripts hooks` at HEAD finds `parse_si_input` called only at `scripts/self-improvement.sh:493`.
  **Not verified:** whether any out-of-repo installed copy of the library (e.g. under `~/.claude/scripts/lib/`) still carries the old function until the next install.
  **route: code-fact-check**

- **Claim:** The deleted function had no committed caller, so its removal changes no runtime write to si-input.md.
  **Location:** `scripts/self-improvement.sh:490-499`
  **Evidence:** executed (via fact-check Claim 10 callers log)
  **Verified:** `git log -S prepend_si_input_rejected_history 06903d6^..6405e43` and `git grep` show no caller outside the definition and its tests.
  **Not verified:** a manual shell invocation by a user, which would leave a preamble that `parse_si_input` drops through the comment-skip path (`scripts/lib/si-input.sh:53-63`).
  **route: code-fact-check**

- **Claim:** The new test file writes and deletes only inside its own `mktemp -d` directory.
  **Location:** `test/si-input-parse-comments.bats:8-16`
  **Evidence:** read-static
  **Verified:** `setup()` derives `INPUT_FILE` from `TEST_TMPDIR=$(mktemp -d)`; every `printf ... > "$INPUT_FILE"` and the quoted `rm -rf "$TEST_TMPDIR"` reference that path.
  **Not verified:** the behaviour of the sourced `scripts/lib/si-input.sh` top level when `BATS_TEST_DIRNAME` resolves elsewhere (not exercised here).

## Primitive sweep

Primitive: temp-file create + rename / recursive delete (file I/O)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `main:scripts/lib/si-input.sh:284` `mktemp "${input_file}.XXXXXX"` | S2 path, S1 content | none | cleared — deleted by this diff |
| `main:scripts/lib/si-input.sh:305` `mv "$tmpfile" "$input_file"` | S1 content | none | cleared — deleted by this diff |
| `test/si-input-parse-comments.bats:10` `mktemp -d` | S4 | — | cleared — test-only scratch dir |
| `test/si-input-parse-comments.bats:15` `rm -rf "$TEST_TMPDIR"` | S4 | quoted; empty value is a no-op | cleared — test-only |

Primitive: jq over external JSON (deserialization)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `main:scripts/lib/si-input.sh:250` `jq -r ... "$report"` | S1 | `2>/dev/null \|\| round_rows=""` | cleared — deleted by this diff |
| `scripts/lib/si-input.sh:189` `jq -R -s` in `parse_si_priority_hypotheses` | S2 via awk | jq builds JSON (no hand quoting) | cleared — unchanged by diff, out of delta |

No other dangerous primitive (exec, eval, SQL, HTML, network) occurs in the diff scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

The change is a net reduction in attack surface: it deletes an uncalled helper that read model-influenced rejection text from round reports and rewrote a user-edited input file through a temp-file-and-rename sequence, and it leaves the live parser (B2) byte-identical. The added tests use code-constant fixtures in a private scratch directory. No findings within the code paths read; the two routed endorsement claims are backed by executed evidence in the fact-check logs. Safe to merge from a security standpoint.

## Goal-Alignment Note
- **Answered:** Security review of the full Q-065 branch at 0304a2c: trust boundaries, source classification, file-I/O and jq primitive sweep, test-file scratch-dir hygiene; no findings.
- **Out of scope:** The `docs/reviews/q065-*.md` artifacts; the pre-existing `parse_si_input` → prompt-injection path (B2), which the diff does not touch; installed copies of the library outside the repo.
- **Escalate:** None.
