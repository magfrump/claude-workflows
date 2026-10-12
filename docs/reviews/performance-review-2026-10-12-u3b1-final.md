# Performance Review — feat/build-loop-u3b1 (U3b1, final confirming pass)

**Scope:** `git diff main...HEAD` on `feat/build-loop-u3b1` at 5e816c5b (`scripts/build-loop.sh`; tests and plan note read for intent only)
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-u3b1-final.md` (Claims 2, 7), `docs/reviews/performance-review-2026-10-12-u3b1-i1.md` (findings 1-4), override-log rows dated 2026-10-12

Probe provenance: perl 5.36.0, bash 5.2, WSL2. Each probe ran under `set -eu` in its own `mktemp -d /tmp/u3b1fperf-XXXX` directory, refused to run git outside it, and removed it at the end. No worktree file was changed. Scripts and logs are in `/tmp/claude-1000/-workspace/402ec840-a464-40f5-96ae-98af0cc535cf/scratchpad/u3b1/fperf/` (`f1.sh`/`f1.log`, `f2.sh`/`f2.log`), abbreviated `$FP` below. Peak RSS comes from iteration 1's `rss.py` (`RUSAGE_CHILDREN.ru_maxrss`), which reports the largest single descendant process, not the sum.

## Data Flow and Hot Paths

- **`--marker BRIEF`** (`marker()`, `scripts/build-loop.sh:822-870`) runs once per blocked or stopped marker SHA, so it is a cold path. Its input, the commit message the loop wrote, is untrusted. Since iteration 1 it reads the object size first and stops before reading the body when the commit is larger than `MARKER_MAX`:
  ```bash
  n="$(git cat-file -s "${STATUS[sha]}")" || { echo "skip $a: its marker could not be read"; return; }
  [[ "$n" -le "$MARKER_MAX" ]] || { echo "skip $a: its marker is $n bytes, over the $MARKER_MAX-byte cap"; return; }
  ```
  (`:829-830`, with `MARKER_MAX=65536` at `:810`.) So the body read, `scrub`, the Perl rule and cap pass (`:837-850`) and the two FENCE_AWK passes all run on at most 64 KiB. Before the cap, `status_fields` → `marker_kind` (`:793`, `:721-753`) still reads the whole commit twice. That code is unchanged on this branch and `--status` already ran it.
- **`--state`** (`state_start`, `:1172-1178`, plus `caller_gate` and the new `default_gate` check at `:564-565`) runs once per orchestrator iteration. That makes it warm, not a tight loop. Its cost is the pre-existing `store_check --main` plus a handful of constant-size git processes.

### Iteration 1 finding 1 is resolved by the 64 KiB cap (measured)

| Input (blocked marker, `$FP/f1.log`) | Object size | `--marker` (3 runs) | `--status` | Output |
|---|---|---|---|---|
| 1-byte lines, just under cap | 62,208 B | 0.21 s / 10-11 MB | 0.16 s / 10 MB | `ok` + 100 lines + note "100 of 31000 lines shown" |
| 2-byte lines, just under cap | 62,208 B | 0.16 s / 9-10 MB | 0.11 s / 9 MB | `ok` + note "100 of 20667" |
| 1000-byte lines, just under cap | 62,208 B | 0.11 s / 10 MB | 0.12 s / 10 MB | `ok`, "62 of 62 lines shown, 62 cut at 300 bytes" |
| 2-byte lines, over cap | 70,208 B | 0.11 s / 10 MB | 0.11 s / 9 MB | `skip ...: its marker is 70208 bytes, over the 65536-byte cap` |
| 2-byte lines, 16 MiB | 16,777,424 B | 1.07-1.17 s / 131-132 MB | 1.17 s / 132 MB | same skip line |

Iteration 1 measured 16.7 s and 1,156 MB for a 16 MB short-line body. The same input now takes 1.1 s and 132 MB, which equals `--status` on that tip. The worst case under the cap is 0.21 s and 11 MB. The Perl slurp at `:837` (`my @l = map { s/\n\z//r } <STDIN>; ...`) is unchanged, but it can now hold at most about 32 k lines, and at that size it is harmless. Finding 2 (scrub over an unbounded body) is resolved by the same cap. Findings 3 and 4 are settled by override rows (Won't-Fix and Defer) and were not re-filed.

The 16 MiB residual (1.1 s, 132 MB) is `marker_kind`'s pre-existing pair of whole-commit reads. Override row "`--marker` reads the marker commit a fourth time" records it as "~1.2 s and ~145 MB". My measurement reproduces the time. RSS came out at 131-132 MB, a little under the row's ~145 MB. This gives fact-check Claim 7 (Unverifiable: no `/usr/bin/time`) a measured figure. The difference is cosmetic and needs no action.

`--state` in a 3-commit repo took 0.055-0.060 s over 5 runs (`$FP/f2.log`). Iteration 1 measured 0.33 s on a full clone of /workspace main, which is store_check-dominated. The branch changes since then add `stray_vars` (one `rev-parse --local-env-vars`, shared with `checkout_gate`, so that call count is unchanged) and `default_gate`'s `show-ref` + `cat-file -t` (2 processes). These are constant-size.

## Findings

#### The strict-UTF-8 regex fails, with no error, on a line of more than 65,534 characters. Only scrub's 4096-byte line cut keeps it from doing so

**Severity:** Informational
**Location:** `scripts/build-loop.sh:842` (the rule's UTF-8 alternative); the guard is in `scripts/lib/dev-cycle-read.sh` `scrub()` (`$_ = substr($_, 0, 4096) . " [line cut at 4096 bytes]" if length($_) > 4096;`)
**Move:** Asymptotic behaviour (a cliff, not a slope)
**Classification:** Macro (input-length cliff) / Cold path (once per marker SHA)
**Confidence:** High for the mechanism (executed). Low that it ever bites, because the guard holds today.
**Baseline:** no baseline available — flagged as speculative (the cliff point, 65,534 iterations on perl 5.36.0, was measured; its impact on the pipeline was not)
**Legibility-target:** implementer of `marker()`; whoever next edits scrub's line cut or the order of scrub → rules

Evidence (verbatim, `:842`, inside the rule loop `:838-844`. The perl program continues to `:850`):
```perl
        || $l[$i] !~ /\A(?:[\x00-\x7F]|[\xC2-\xDF][\x80-\xBF]|\xE0[\xA0-\xBF][\x80-\xBF]|[\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}|\xED[\x80-\x9F][\x80-\xBF]|\xF0[\x90-\xBF][\x80-\xBF]{2}|[\xF1-\xF3][\x80-\xBF]{3}|\xF4[\x80-\x8F][\x80-\xBF]{2})*\z/) { print "rule ", $i + 1, "\n"; exit 0 }
```
Run directly on a line of plain ASCII `a`: 32,000, 33,000 and 65,000 bytes give `match`. 66,000 bytes gives `Complex regular subexpression recursion limit (65534) exceeded` and `NOMATCH`. The limit is 32,766 on perls before 5.30. A NOMATCH there would print a spurious "breaks the blocked-body rule" skip. That fails closed, but the reason given is wrong. The match is linear, with no backtracking blow-up, because each alternative starts on a distinct lead byte. In the pipeline, scrub has already cut every line to 4096 bytes plus a 26-byte note, so the regex never sees a line long enough to fail. MARKER_MAX alone would also keep a line under about 65,380 bytes. That is too close to 65,534 to rely on, and it is not enough on an older perl. No action is needed now. The coupling is not written down anywhere.

**Recommendation:** Add one comment at `:842` naming scrub's 4096-byte cut as what keeps the regex under perl's recursion limit. Alternatively, test the UTF-8 rule with a loop-free form, e.g. `utf8::decode` on a copy plus a surrogate/range check, so the limit cannot apply.

## Escalations (outside this lane)

- **Correctness/API (for api-consistency or security):** a valid UTF-8 body line over 4096 bytes is skipped as a rule break. scrub runs before the rule and cuts at byte 4096. That can split a multibyte character, and the strict-UTF-8 regex then refuses the line. Executed (`$FP/f2.log`): a body of `Which option?` plus 1,400 × U+4E2D (4,200 bytes) gives `skip ...: a line of its marker's body breaks the blocked-body rule (...)`. The same body with 1,300 × U+4E2D (3,900 bytes) gives `ok`. The loop prompt tells the loop "at most $BODY_LINES lines of $BODY_BYTES bytes (longer is cut ...)" (`:1538`), so a loop following it would expect a long line to be cut, not skipped. The header's "a character is never split" (`:103`) is true of the 300-byte cut only. The outcome fails closed (no paste) and is rare: it takes a single line over 4 KB of non-ASCII text. I found no rubric or override row that settles it. Iteration 2's fact-check (`code-fact-check-report-u3b1-i2.md:170`) notes the 4096 cut but not this interaction.

## Endorsements

- The 64 KiB cap is checked with `git cat-file -s` before the body is read. A 16 MiB marker skips in 1.1 s and 132 MB, the same as `--status` on that tip, instead of 16.7 s and 1,156 MB. `[unverified — submitted as claim]` (measured in `$FP/f1.log`; not a fact-check execution verdict)
- Under the cap, `--marker`'s worst case (about 31 k one-byte lines) is 0.21 s and 11 MB. The Perl slurp at `:837` is bounded by MARKER_MAX. `[unverified — submitted as claim]` (measured in `$FP/f1.log`)
- `checkout_gate` now calls `stray_vars` and takes its first line, where it used to run its own `rev-parse --local-env-vars` loop. It still spawns one git process. `[read: scripts/build-loop.sh:517, 1096-1097]`
- `--state`'s additions are constant-size: one `rev-parse --local-env-vars`, one `git config --list`, and `show-ref` + `cat-file -t`. In a tiny repo `--state` takes 0.055-0.060 s, where store_check dominates. `[unverified — submitted as claim]` (measured in `$FP/f2.log`)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Strict-UTF-8 regex fails, with no error, past perl's 65,534 recursion limit; only scrub's 4096 cut guards it | Informational | `scripts/build-loop.sh:842` | High (mechanism) / Low (impact) |

## Overall Assessment

The branch is performance-sound. Iteration 1's one real issue was `--marker` materializing an unbounded, loop-written body before its cap. The 64 KiB `cat-file -s` check now bounds that path, and the numbers confirm it. The worst case under the cap is 0.21 s and 11 MB. Over the cap, the cost is `marker_kind`'s pre-existing reads, the same as `--status`. Those reads are already logged as Won't-Fix, and my figure (132 MB) is slightly under the row's ~145 MB. `--state` adds only constant-size git calls on top of `store_check`. The remaining performance note is Informational: a latent perl-regex cliff that scrub's cut keeps out of reach. The one item worth routing is outside this lane: scrub's 4096-byte cut can split a UTF-8 character, which turns a long non-ASCII line into a spurious rule skip. No further profiling is needed.

## Goal-Alignment Note

- Success criterion (restated): a markdown report at `docs/reviews/performance-review-2026-10-12-u3b1-final.md`, structured per the performance-reviewer skill, including verification that iteration 1's finding 1 is resolved by the 64 KiB cap.
- Answered: yes. Finding 1 is resolved (measured: 16.7 s / 1,156 MB → 1.1 s / 132 MB at 16 MiB; worst case under the cap 0.21 s / 11 MB). Finding 2 is resolved by the same cap. Findings 3 and 4 are settled by override rows and were not re-filed.
- Unit goal: `--marker` bounds both its work and its output, and `--state` is cheap enough to run every iteration. Both hold. Nothing in this lane blocks landing U3b1.
- Escalate: the 4096-byte scrub cut splitting a multibyte character, which causes a spurious body-rule skip (to api-consistency or security / synthesis). Override row "fourth read": RSS is 131-132 MB measured, not ~145 MB (cosmetic, for fact-check Claim 7).
