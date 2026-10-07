Commit: 98e3b1df

# Performance Review — feat/build-loop-u2a3b, loop 2 iteration 2 (be94c871..98e3b1df)

**Scope:** `git diff be94c871..98e3b1df -- . ':!docs/reviews'` (dd51e9a7, 98e3b1df), mainly `scripts/lib/dev-cycle-read.sh` `import_targets`, `imported_names`, `main_imports`
**Date:** 2026-10-07
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i2.md` (Claims 7, 12, 18, 19, 30, 36b)

All measurements below come from a clean clone at 98e3b1df (`/tmp/u2a3bperfL2i2-ZyBK/clone`, local `main` = b5eadbd8). They compare `git archive` copies of `scripts/` at be94c871, dd51e9a7, main and 98e3b1df, plus one probe variant (`sc-awkgate`, see F1). Every process ran under `timeout` and exited before this report was written. Logs and scripts are in `/tmp/u2a3bperfL2i2-ZyBK/` (`bench.log`, `longrun.log`, `instr.log`, `instr-ws.log`, `*.sh`).

## Data Flow and Hot Paths

`import_targets` runs once per walked file. It runs sed, then python3 when the text holds a byte above 0x7f, then the IMPORT_AWK pass. Both walks call it:
- the tree walk (`imported_names`) runs once per `--check-fix` process, whatever the number of paths, because it is cached in `IMPORTED_DONE`;
- the main walk (`main_imports`, no caller in `scripts/` yet; U2a3c's gate will call it) runs once per gate run.

Walk sizes I counted with an instrumented copy of the lib:
- clean clone: 45 files walked, 42 of them non-ASCII (em-dashes and the like), so **42 python3 forks, and 0 of them changed the text**;
- shared `/workspace` checkout (read-only `--check-fix README.md`): 80 files walked, 77 python3 forks, 0 changed the text.

Text decoded per walk is about 734 KB. Path temperature: cold CLI path, but one a human waits on, run every cycle and every gate. Neither walk is a per-request path.

Interleaved timings, 4 rounds, clean clone. `--check-fix` covers 942 paths (`docs/**/*.md` + README.md) and "main walk" is `main_imports` alone (`bench.log`):

| Version | --check-fix median (ms) | main walk median (ms) |
|---|---|---|
| main b5eadbd8 | 2602 | 540 |
| be94c871 | 2725 | 796 |
| dd51e9a7 | 2771 | 643 |
| **98e3b1df (HEAD)** | **3105** (mean 3210) | **1083** |
| HEAD + awk validity gate (probe, F1) | 2755 | 754 |

These numbers reproduce Claim 36b's shape: HEAD runs about 0.3-0.5 s over dd51e9a7 on `--check-fix`, and dd51e9a7 runs about 7% over main. The main walk at HEAD costs +440 ms (+69%) over dd51e9a7. Both walks produce the same output at dd51e9a7, HEAD and the probe: IMPORTED_MAIN sha256 `c5670e98…` is identical, and the `--check-fix` output files are byte-identical between HEAD and the probe.

## Findings

#### F1. python3 is forked for every non-ASCII file, though only an invalid sequence can change the text

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:573-576`
**Move:** Hidden multiplication / work in the wrong place
**Classification:** Micro (a fork of about 7.6 ms per file) / cold path, run on every `--check-fix` and gate run
**Confidence:** High (executed)
**Baseline:** main walk median 1083 ms at 98e3b1df against 643 ms at dd51e9a7, and `--check-fix` (942 paths) 3105 ms against 2771 ms, clean clone, 4 interleaved rounds, 2026-10-07 (`/tmp/u2a3bperfL2i2-ZyBK/bench.log`)

```
  if [[ "$toks" == *[$'\x80'-$'\xff']* ]]; then
    d="$(printf '%s\n' "$toks" | python3 -I -c 'import sys; sys.stdout.buffer.write(sys.stdin.buffer.read().decode("utf-8", "replace").encode())')" || return 1
    [[ "$d" == "$toks" ]] || toks+=$'\n'"$d"
  fi
```

The trigger is "any byte above 0x7f", but valid UTF-8 decodes to itself, so the fork pays off only on an invalid sequence. In this repo 42 of 45 walked files fork, and 77 of 80 in `/workspace`. None of them changed the text (`instr.log`: 42 PYSAME, 0 PYDIFF; `instr-ws.log`: 77 PYSAME, 0 PYDIFF). The cost per fork measured on the 103 KB code-review SKILL.md (`forks.sh`, 50 calls each):

| Command | Cost per call |
|---|---|
| python3 -I | 7.6 ms |
| python3 -I -S | 6.5 ms |
| GNU grep | 1.4 ms |
| iconv | 1.7 ms |
| bare fork of `cat` | 0.6 ms |

Nearly all of the measured regression comes from python3 interpreter startup multiplied by the walked-file count, and that count grows with the skills directory. Row 422's revisit trigger ("--check-fix over 2 s here") is already exceeded by main itself (2.6 s), so this cost lands on top of it.

Cheaper gates I tested, judged by whether "the gate says valid" implies "python3 would not change the text". A miss in that direction would break the superset.
- **One awk ERE for well-formed UTF-8 (RFC 3629 / Unicode Table 3-7) under LC_ALL=C.** It agrees with python3's `replace` decode on all 20,013 cases: the fact-check's 20,000 random strings plus 13 edge cases (surrogate ED A0 80, F4 90 80 80 > U+10FFFF, overlongs C0 80 / E0 80 AF / F0 80 80 AF, F8 lead, BOM, U+FFFE). It takes about 7 ms over all 685 KB of skills text (`awkvalid.sh`). In the probe lib (`sc-awkgate`) it brings `--check-fix` to 2755 ms and the main walk to 754 ms, with identical output. Its `import_targets` output equals HEAD's on 5 invalid and valid inputs (`probe-invalid.sh`), and the U+FFFD spellings are present. The test runs in mawk 1.3.4.
- **GNU grep in `C.utf8` (`grep -axv '.*'`)** also agrees on all 20,013 cases. It fails open, though, when the locale is missing (under C nothing is invalid), and `grep` is not always GNU. This session's interactive shell resolves `grep` to ugrep 7.8.4, which flagged 0 of the 19,288 invalid cases. Not recommended.
- **glibc iconv** accepts F4 90 80 80 (203 misses of 19,288). It fails open. Rejected.
- **One python3 per walk** is not feasible as the walk is written: it is breadth-first and needs each file's decoded names before it knows the next file.

**Recommendation:** Fork python3 only when the text holds an invalid sequence, with the awk ERE above (the probe's two-line change). Better still, test it inside IMPORT_AWK: on an invalid line awk exits with a dedicated status, and bash then decodes and reruns, so valid text pays no extra fork. That also removes the probe's remaining +110 ms on the main walk. Any failure of the gate should fall through to python3, so it fails toward over-reading. Keep python3 as the decoder: the gate only decides when to run it.

#### F2. With the 4096 cap gone, one blank-free run can spend about 10 s before the walk fails, because the work bound does not charge emit's path rebuild

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:524-535` (emit), `:544` (scan loop, cap removed), `:618` / `:694` (output bound checked only after `import_targets` returns)
**Move:** Asymptotic behaviour
**Classification:** Macro (the cost per candidate grows with parts × length, while the charge grows with length only) / cold path, fails closed
**Confidence:** High (executed)
**Baseline:** `import_targets` on one `@` and a 9,990-byte `a/a/…` run takes 10,105 ms at 98e3b1df against 1,367 ms at be94c871, clean clone, 2026-10-07 (`worstfile.sh`)

```
  work += length(c); if (work > 50000000) exit 3
...
  n = split(c, part, "/"); k = 0
...
  out = ""; for (i = 1; i <= k; i++) out = out "/" st[i]
```

(excerpt; emit continues through the `seen`/print lines at `:535-537`, which I read)

The work bound charges `length(c)` per candidate, which totals about L²/2 for a run of length L. emit's `split` and its concatenation loop cost about k·len per candidate, though, with k the number of parts. A slash-shaped run therefore costs about L³ while being charged L².

`longrun.log` measured the following for a slash-shaped run:

| Run length | be94c871 (cap) | HEAD |
|---|---|---|
| 4 KB | 1.05 s | 1.06 s |
| 8 KB | 1.1 s | 5.0 s |
| 10 KB and longer | 1.1-1.3 s | 8.2-8.9 s, then the work bound trips (rc=1) |

A plain `aaaa…` run is cheap at both commits: 0.24 s at HEAD with rc=1.

HEAD's per-file worst case went from about 5.9 s (be94c871, five capped 4096-byte runs) to about 10 s (one 9,990-byte run, which stays just under the bound and then prints 25 MB). The walk then fails on IMPORT_OUT_MAX, so the result is always fail-closed. Only time is lost, and only on text someone committed or placed in an instruction file.

**Recommendation:** Enforce the output budget inside awk. Pass `IMPORT_OUT_MAX - used` through ENVIRON, count the printed bytes, and `exit 3` when they pass it. A slash-shaped run then fails at about 2.8 KB in well under a second, and `$(...)` never buffers 25 MB. If you want emit's charge to track its real cost too, charge `n` (the part count) on top of `length(c)`.

#### F3. Row 386's deferred parent-link loop: its revisit trigger has fired; IMPORT_OUT_MAX now bounds it at about 17 s

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:705`
**Move:** Hidden multiplication
**Classification:** Macro (O(len × depth) per candidate, over about len/2 prefix candidates) / cold path, prints ok (slow, not fail-open)
**Confidence:** High (executed)
**Baseline:** main walk on a committed CLAUDE.md holding one 2,820-byte `a/a/…` token: 16,632 ms at 98e3b1df, 18,840 ms at be94c871; a 4,096-byte token takes 50,413 ms at be94c871 and fails in 1,266 ms at HEAD (`deepmain.sh`, 2026-10-07)

```
      c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }; done
```

Override row 386 deferred this loop with the revisit trigger "U2a3b's parser rework or a token-length cap". The parser rework has happened, and the 4096 cap it relied on has been removed. The new evidence changes the premise, and for the better: IMPORT_OUT_MAX now fails any token whose prefixes print more than 4 MB, so the worst successful walk is bounded. For this shape I measured about 17 s at 2.8 KB. That a walk-wide total stays near 17 s is reasoned from the shared output budget; I did not run several files. Before this change, be94c871 took 46-50 s per file at 4-8 KB, and several such files added up.

Each prefix candidate re-walks every parent of itself, although the candidates are prefixes of one another.

**Recommendation:** Inherit row 386 with the new bound recorded, or close it cheaply: keep a `local -A okdir` of parents already checked and `break` on the first one found, which makes the loop linear in the walk's output. Alternatively, skip the loop when main stores no 120000/160000 entry, which is the common case.

#### F4. IMPORT_OUT_MAX has about 700-1,900× headroom, and a walk near the bound takes 2-6 s

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:482-485`, `:618`, `:694`
**Move:** What's the size of N
**Classification:** Micro / cold path
**Confidence:** Medium (the timings are executed; the sizing choice is judgment)
**Baseline:** a CLAUDE.md printing 3,151,925 candidate bytes (about 23,000 flat `@dNNNNNNN/fNNNNNNN.md` tokens): tree walk 2,394 ms and main walk 5,817 ms at 98e3b1df. be94c871's main walk timed out at 300,000 ms on the same file (`outmax.sh`, 2026-10-07)

```
IMPORT_OUT_MAX=4000000
```

The real walks print 2,059 bytes in the clone (fact-check Claim 7) and 5,676 bytes in `/workspace`, so 4 MB lets a walk spend about 6 s on flat names, or about 17 s on deep ones (F3), before it fails. That is acceptable for a fail-closed CLI.

**Recommendation:** Optional: lower IMPORT_OUT_MAX to about 256 KB, still more than 40× the busiest walk seen here. A walk near the bound would then finish in under a second, and F3's worst case would drop to well under a second. The cost would be refusals on a repo with a very large import fan-out. Keep the comment's "about 2 KB" honest by naming the clone, because `/workspace` prints 5.7 KB.

## Endorsements

- The hoisted `lower` in `main_imports` (one fork per file instead of one per candidate) leaves IMPORTED_MAIN identical. On a 3.15 MB candidate file it cuts the main walk from more than 300 s (be94c871, timed out) to 5.8 s, and in the clean clone from 796 ms to 643 ms (`outmax.sh`, `bench.log`). [fact-check: Claim 19 — Verified]
- The tree walk's `head -c 4194305` adds a fork per file whose cost is lost in the noise: the probe with head ran 2755 ms against dd51e9a7's 2771 ms without it. It also stops a huge prefix-named file from stalling the walk. [fact-check: Claim 18 — Verified]
- ASCII text never forks python3, and the byte-range pre-check is cheap: 60 ms on 4 MiB of ASCII. [fact-check: Claim 12 — Verified]
- splice's new work charge bounds the comment case: 320,000 comments take about 0.2 s at HEAD, against 27 s at be94c871. [fact-check: Claim 30 — Mostly accurate]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | python3 is forked per non-ASCII file (42 of 45 here, 77 of 80 in /workspace, 0 changed); an awk UTF-8 validity gate restores dd51e9a7's timings | Low | `dev-cycle-read.sh:573-576` | High |
| F2 | With the cap removed, one 10 KB slash run costs about 10 s before the walk fails; the work bound does not charge emit's rebuild, and the output bound is checked only after awk | Low | `:524-535`, `:544`, `:618`, `:694` | High |
| F3 | Row 386's revisit trigger has fired; the parent-link loop is now bounded at about 17 s by IMPORT_OUT_MAX | Low | `:705` | High |
| F4 | IMPORT_OUT_MAX headroom is about 700-1,900×; 2-6 s near the bound | Informational | `:485` | Medium |

## Overall Assessment

The fixes are sound for performance. The hoist turns a pathological main walk from minutes into seconds. The head cap and splice charge close stall paths, and every pathological input I built fails closed.

The one regression a user will notice on every run is F1. At 98e3b1df, python3 is forked for 42 of 45 walked files when none of them needs decoding. That adds 0.3-0.5 s to each `--check-fix` and about 0.44 s (+69%) to each main walk. A UTF-8 validity gate removes nearly all of it, and the awk ERE I tested agrees exactly with python3 over 20,013 cases. F2 and F3 are slow fail-closed paths reachable only through crafted instruction text. Enforcing IMPORT_OUT_MAX inside awk, plus a parent memo in `main_imports`, would bound both well under a second. Every finding can be fixed in place; none is structural.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 98e3b1df` line at the top.
- **Answered:**
  - python3 fork count: 42 of 45 in the clone and 77 of 80 in `/workspace`, with 0 changing the text.
  - Cheaper alternatives: the awk ERE is correct on 20,013 cases and recovers the timings; grep is locale- and PATH-fragile; iconv fails open; one python3 per walk is infeasible.
  - Removing the 4096 cap costs about 10 s to failure (F2).
  - IMPORT_OUT_MAX sizing (F4).
  - The head cap and the hoisted lower are endorsed with measurements.
  - Interleaved runs, 4 rounds, clean clone, HEAD against main, be94c871 and dd51e9a7.
- **Out of scope:**
  - The main walk's lack of a 4 MiB cap: deferred in L2-C5, and not re-raised.
  - Rows 412, 413 and 422: inherited.
- **Escalate:** none.
- **Decisions I made:**
  - I measured a probe variant (`sc-awkgate`) outside the worktree to price F1's fix. No worktree file was changed except this report.
  - I treated row 386 as having a fired trigger, with new evidence (F3), rather than re-raising it unchanged.

Legibility targets:
- F1, F2 and F3: for-author.
- F3: also for-orchestrator-synthesis (an override-row revisit).
- F4: for-author.

Executed vs reasoned:
- F1, F2 and F3: executed.
- F3's walk-wide 17 s bound: reasoned.
- F4: executed timings, with a judgment on sizing.
