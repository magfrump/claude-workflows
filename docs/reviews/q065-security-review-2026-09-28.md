Commit: 12f96cd

# Security Review — review/q065 (Q-065 [1], delete `prepend_si_input_rejected_history`)

**Scope:** `git -C /workspace/.claude/wt-q065 diff main...HEAD` (main 6405e43 → HEAD 12f96cd), full branch: `scripts/lib/si-input.sh` (−114), `test/si-input-rejected-history.bats` (deleted, −214), `test/si-input-parse-comments.bats` (new, +33)
**Date:** 2026-09-28
**Based on:** `docs/reviews/q065-code-fact-check-report.md` (Stage 1, k=1)

## Trust Boundary Map

```
B1 (removed): [round-<N>-report.json .validation[].verdict_detail.reject_reason (model-authored text from prior rounds)] → [prepend_si_input_rejected_history: jq extract, first line only, mktemp + mv rewrite of si-input.md] → [si-input.md preamble, discarded by parse_si_input]
B2:           [si-input.md (user-authored, in WORKING_DIR)] → [parse_si_input state machine: comment stripping, ## section routing, preamble dropped] → [SI_FEEDBACK / SI_PRIORITIES / SI_OFF_LIMITS / SI_CONTEXT → planner prompt]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | `round-*-report.json` reject reasons | runtime-mutable (written by earlier loop rounds, model-generated) | UNTRUSTED toward file-write and prompt sinks; its only path into si-input.md was B1, now removed |
| S2 | `si-input.md` content | runtime-mutable (user-edited between runs) | Trusted as user intent for the prompt sink (it is the user's own channel); not fed to exec/eval/path sinks in the code read |
| S3 | `$1` path argument to the library functions | deploy-time (`$WORKING_DIR/si-input.md` from `scripts/self-improvement.sh:493`) | trusted (all sinks) |

The diff only removes a boundary. B1 was the one place where model-generated text (S1) was written into the user's input file. Because the function never had a caller (fact-check Claim 1), B1 was never live. Deleting it removes a dormant file-rewrite path (`mktemp "${input_file}.XXXXXX"`, `awk … >> tmpfile`, `mv tmpfile input_file`; see `main:scripts/lib/si-input.sh:290-306`) and a dormant route by which S1 could reach si-input.md. B2 is unchanged: `parse_si_input` (`scripts/lib/si-input.sh:26-100`) appears only as context in the diff.

## Findings

No findings.

Considered and cleared:

- **Lost preamble-discard assertion (fact-check Claim 2, Escalate b).** The deleted test "comment block does not pollute parsed sections" (`main:test/si-input-rejected-history.bats:178-188`) was the only test showing that text before the first `##` heading never reaches the `SI_*` prompt variables. The code still behaves this way: `_save_si_section` is called with an empty heading, and its `case` (`scripts/lib/si-input.sh:107-112`) matches nothing. For security purposes that assertion mattered only while B1 wrote untrusted S1 text into the preamble. With B1 gone, only the user writes to the preamble (S2, the user's own channel), so a regression would leak user text into the user's own prompt. That is a correctness and coverage question, not a trust-boundary one, and it is left to test-strategy / code-review synthesis as the fact-check routed it. Not rated.
- **Moved tests' fixture handling.** `test/si-input-parse-comments.bats:7-15` uses `mktemp -d` under the bats tmp and `rm -rf "$TEST_TMPDIR"` on a variable that `setup()` always sets. It has the same shape as the deleted file's setup/teardown and no new filesystem reach.

## Endorsement Claims

- **Claim:** The branch removes only code: the si-input.sh hunks are the header lines 12-14 and the function block `main:scripts/lib/si-input.sh:199-310`, and they add no executable line to `scripts/`.
  **Location:** `scripts/lib/si-input.sh:1-204`
  **Evidence:** read-static
  **Verified:** Read the diff hunks for `scripts/lib/si-input.sh` (only `-` lines) and lines 1-100 of the post-change file; `git diff --stat` shows `114 ----` for that file.
  **Not verified:** Whether `scripts/self-improvement.sh` (the sourcer, `:231`) depends on a side effect of the deleted definition at source time. The fact-check found no call and no dynamic construction, but I did not re-read self-improvement.sh.
  **route: code-fact-check**
- **Claim:** At HEAD, no file under `scripts/`, `hooks/`, `test/` or `skills/` references `prepend_si_input_rejected_history` except the provenance comment at `test/si-input-parse-comments.bats:5`.
  **Location:** repo at 12f96cd
  **Evidence:** executed
  **Verified:** `git grep -n prepend_si_input_rejected_history -- scripts hooks test skills` returned exactly that one line.
  **Not verified:** `devcontainer-config/` and install-time copies under `~/.claude/scripts/lib/` on the host. An already installed copy keeps the old function until it is reinstalled, which is harmless because nothing calls it.

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. The branch adds no exec, eval, deserialization, fetch, SQL or HTML sink. The file-write primitives it touches (`mktemp` / `awk >>` / `mv` in the deleted function, and `mktemp -d` / `rm -rf` in the new test's setup and teardown) are either deleted or confined to a test-owned temp directory. Both are dispositioned above.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

This is a pure dead-code deletion, and it slightly shrinks the attack surface. It removes a never-called path that would have rewritten the user's `si-input.md` with model-generated reject-reason text (B1, removed). The B2 parsing boundary into the planner prompt is unchanged. Within the code paths I read there are no findings. The first endorsement claim is pending execution verification through code-fact-check (the no-source-time-side-effect hop in `scripts/self-improvement.sh`). The lost preamble-discard assertion is a coverage item for synthesis, not a security finding.

## Goal-Alignment Note

- **Success criterion (verbatim):** a markdown report saved at the output path named in your role-specific tail, structured per your skill, ending with a Goal-Alignment Note.
- **Answered:** Security review of the full q065 branch diff at 12f96cd. It covers the trust-boundary map (one boundary removed, one unchanged), the source classification, the primitive sweep, and the disposition of the fact-check's coverage escalation from a security angle. No findings.
- **Out of scope:** Re-verifying the fact-check's caller and no-behaviour-change claims (taken as foundation). Test-coverage adequacy of the lost preamble-discard assertion (routed to test-strategy / code-review synthesis). The questions.md hash-staleness bookkeeping (fact-check Escalate a).
- **Escalate:** None from security. I agree with the fact-check's routing of Escalate (b) to coverage synthesis. Once B1 is gone it carries no trust-boundary weight.
