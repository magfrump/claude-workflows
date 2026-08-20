# Code review — pass 3 (confirmation)

Commit: a04ef57
Branch: `feat/crb-direction1-harness`
Baseline for the fix diff: `ed68ced..a04ef57`
Reviewer: pass-3 confirmation agent, 2026-08-18
Scope: adjudicate the pass-2 findings, then hunt greenfield for defects the fixes
introduced. Advisory-tier items from passes 1–2 are deliberately not re-litigated.

Everything below marked "verified" was executed, not read. No repo state was
mutated: the only writes were to `/workspace/.scratch/p3/` and to this file.
`crb-materialize.py --verify` was run read-only against the five pilot clones.

---

## 1. Adjudication of the pass-2 findings

| # | Pass-2 finding | Status | How confirmed |
|---|----------------|--------|---------------|
| 1 | Harvest traversal regression (`tr '\0' '\n' \| cut -c4-`) | **Closed** | Synthesised porcelain-v1 `-z` byte stream, ran the exact loop |
| 2 | Resume predicate banks failures / re-pays successes | **Closed** | Predicate replayed over all 32 real `result.json` |
| 3 | Post-run containment failure only echoed | **Closed** | Both consumers traced |
| 4 | `judge.sh` endpoint glob + interpolation | **Closed** | 7 URL bypass attempts + 5 injection attempts executed |
| 5 | `--verify` passed trivially for an unmanifested slug | **Closed** | Exit codes checked |
| 6 | Constants hand-copied into a second file | **Closed** | Import works from any CWD; no second `sanitize_model` |
| 7 | Sweep exit-3 / `MAX_ATTEMPTS` / `attempts.jsonl` | **Closed**, one narrow edge (N2) | Shell edge cases executed |
| 8 | `slug_for` / `fork` regexes reject real data | **Closed** (claim wording loose — N5) | `load_prs()` run over the real dataset |

### 1.1 Harvest traversal — closed

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:249-283`

I built a NUL-delimited stream containing an absolute traversal, a relative
traversal, a rename pair, a copy pair, a filename with an embedded newline, a
filename with a space, and a non-matching extension, then ran the loop body
verbatim against it:

```
WOULD COPY -> $dest/artifacts/docs/reviews/report.md
WOULD COPY -> $dest/artifacts/src/a.json
WOULD COPY -> $dest/artifacts/new name.md
  !! X: refusing suspicious artifact path: /../../../../etc/passwd.json
  !! X: refusing suspicious artifact path: ../../etc/evil.json
WOULD COPY -> $dest/artifacts/weird
newline.md
SKIP-EXT: notmatched.txt
WOULD COPY -> $dest/artifacts/copy dest.json
WOULD COPY -> $dest/artifacts/a.md
loop exit ok
```

- `${entry:0:2}` / `${entry:3}` match porcelain v1 `-z`'s `XY<space>path` layout
  exactly. `-z` disables `core.quotePath`, so no dequoting is needed.
- The `R*|C*` second-record consumption works: `old name.md` and `copy src.json`
  were dropped, and the records *after* them (`?? /../..`, `?? a.md`) were still
  parsed correctly — i.e. the inner `read` advances the same stream without
  desynchronising it.
- **Can you still get outside `$dest/artifacts`?** No. The path is relative
  (`/*` refused), contains no `..` (`*..*` refused), and `$dest` is
  `$OUT/$id` where `$id` already had to satisfy `[ -d "$clone/.git" ]`. The
  only residual would be a symlinked directory component inside
  `artifacts/`, which requires git to report `x.json/foo.md` under a symlink —
  git does not traverse symlinks, and `[ -f "$clone/$f" ]` fails for that shape.
- `set -euo pipefail`: `read` returning non-zero at EOF terminates the `while`
  condition (not an error), the inner `read` is `|| true`, `cp` is `|| true`,
  and the loop ran to completion. The old `grep`-in-a-pipeline that `pipefail`
  would have turned into a whole-sweep abort on any cell producing no
  `.md`/`.json` is genuinely gone.
- `done < <(...)` moves the loop out of a subshell. Verified no leakage matters:
  `st`, `f`, `entry`, `_orig` are read nowhere outside the loop
  (`rg` over the script returns nothing), and no counter is set inside it.

**Confidence:** High.

### 1.2 Resume predicate — closed, and the commit's numbers are exact

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:167-183`

I replayed the predicate over all 32 `result.json` files under `runs/`.
Result: **29 banked, 3 re-run** — precisely the commit's claim.

The 3 re-runs are the 3 genuine failures:

```
RERUN len=     0 turns=1 err=True  sub=error_max_budget_usd cost=15.24  e7/mfc-hygiene/rep1
RERUN len=    56 turns=0 err=False sub=success              cost=0      e7/mfc-postfix/rep2
      head: "You've hit your weekly limit · resets Aug 18, 12am (UTC)"
RERUN len=    51 turns=0 err=False sub=success              cost=0      e7/mfc-postfix/rep3
      head: "You've hit your session limit · resets 5:10am (UTC)"
```

No genuine failure is banked; no genuine success is re-run. The 8
`e5-cc-builtin` cells with `num_turns == 0` and 3–7 KB of review text are all
banked, so the pass-1 `num_turns > 0` clause would indeed have re-paid for them.

**Is 200 chars defensible?** Yes, with margin. The shortest banked body in the
real corpus is **1208 chars** (6× the threshold); the longest non-review body is
**56 chars** (3.6× below it). Nothing sits in 56–1208. A legitimately terse
review — a real "no findings" verdict under ~200 chars — would be re-run once
and, if it reproduced, stopped by `MAX_ATTEMPTS`. That costs at most one extra
cell and cannot corrupt a measurement. The `NON_REVIEW` signature list is
redundant belt-and-braces here: both limit cells are already caught by length
alone.

**Confidence:** High (executed against the full real corpus).

### 1.3 Containment void — closed, both consumers verified

**Location:** `run-host.sh:290-303`, `scripts/crb-pipeline-to-benchmark.py:241-244`

**Evidence** (the void):

```python
d["is_error"] = True
d["subtype"] = "containment_failed"
```

- **Resume predicate:** requires `not d.get("is_error")`. The void sets it to
  `True`, so the cell is refused. The void sticks.
- **Injector:** `if (cell / "CONTAINMENT_FAILED").exists(): ... continue` runs
  *before* `load_cell`, so a voided cell's `review.md` and `artifacts/` are never
  read. Verified by reading the control flow; the check sits after the
  manifest/URL guards and before any comment extraction.
- The `except Exception: d = {}` fallback means the void still lands when
  `result.json` is absent or malformed.
- Coherence check: a voided cell will be *re-run* next sweep (predicate refuses
  it, attempts < MAX_ATTEMPTS), but the pre-run `--verify` — now hoisted above
  the payload `mktemp` — will fail on the same contaminated clone and skip it.
  So the void does not lead to re-running against a still-contaminated clone.
- `git clean -qfdx` runs before the post-run verify, but does not touch
  `.git/config` or `refs/remotes/*`, so it cannot launder a re-added remote past
  `verify_containment`'s guards (b) and (a).

**Confidence:** High.

### 1.4 `judge.sh` hardening — closed

**Location:** `scripts/crb-pipeline-to-benchmark.py:352-409`

Generated a real work dir and ran the emitted script against 7 URLs:

```
https://api.anthropic.com/v1/                    >>> === step2_extract_comments (allowed)
https://api.anthropic.com                        >>> === step2_extract_comments (allowed)
https://api.anthropic.com.evil.example/v1/       >>> Refusing
http://api.anthropic.com/v1/                     >>> Refusing
https://api.anthropic.com@evil.example/          >>> Refusing
https://evil.example/?x=https://api.anthropic.com/  >>> Refusing
https://api.withmartian.com/v1                   >>> Refusing
```

The anchored `case` is **not** bypassable by the classic suffix, userinfo,
query-string, or scheme-downgrade tricks. It fails closed on case variation too.
`CRB_ALLOW_FOREIGN_ENDPOINT=1` now warns and proceeds rather than printing
"Refusing to send" and then sending.

Injection: `--judge` and `--tool-name` carrying `$(touch …)`, backticks,
`;`, and quote-breaking payloads were all refused before `judge.sh` was written,
on both the seeded and the `--no-seed` path. No `PWNED*` file was created in any
of the 5 attempts. `bash -n` on the emitted script: clean. The charset check
plus `shlex.quote` is sufficient for a `chmod 0755` file, because the charset
`[A-Za-z0-9._/-]` excludes every shell metacharacter and `shlex.quote` handles
the residual `/` and `-` cases.

**Confidence:** High (executed).

### 1.5 `--verify` on an unmanifested slug — closed

**Location:** `scripts/crb-materialize.py:285-300`

Verified exit codes:

- unmanifested / missing clone → `sys.exit(f"containment check failed for: …")`
  → **rc=1**
- real slug → **rc=0**
- all five pilot clones → `containment ok`, rc=0

`run-host.sh:180-183` consumes it as
`python3 … --verify "$id" || { …; skipped_bad=…; continue; }`, so rc=1 correctly
skips the cell. Propagation is correct.

**Confidence:** High (executed).

### 1.6 `scripts/crb_common.py` — closed

- `sys.path.insert(0, str(Path(__file__).resolve().parent))` is CWD-independent
  by construction. Verified `--help` and normal operation for both scripts from
  `/`, `/tmp`, and `/workspace` — rc=0 in every case.
- Duplication is gone: `rg 'def sanitize_model'` returns exactly one hit
  (`scripts/crb_common.py:32`).
- Stdlib shadowing risk from inserting `scripts/` at `path[0]`: checked all 22
  entries of `scripts/` — no name collides with a stdlib module.

**Confidence:** High.

### 1.7 Sweep exit-3 / `MAX_ATTEMPTS` / ledger — closed, one narrow edge

- Counters use `x=$((x+1))`, not `((x++))` — the assignment form always returns
  0, so `set -e` cannot fire on the `ran=0 → 1` transition. Correct choice.
  All three are initialised at `run-host.sh:86` before the loop, so `set -u` is
  satisfied on every path.
- `DRY_RUN` exits at line 107, before the loop, so it cannot trip exit-3.
- `attempts=$(grep -c . … || echo 0)`: correct for **absent** (grep rc=2, no
  stdout, `echo 0` supplies "0") and for **populated** files. The **empty-file**
  case is wrong — see N2. Non-blocking.
- **Does the ledger write happen on every path that spends money?** Yes. Between
  the `docker run` and the ledger append there is no `continue` and no command
  that can abort under `set -e`: the transcript-harvest heredoc ends in
  `sys.exit(0)` even on "no result event", the harvest loop is `|| true`-guarded
  throughout, the void block is `|| true`, and the stats block reads only.
- The one path where the ledger records the *wrong* number: if a retry produces
  no `result` event, `result.json` is not rewritten and the previous attempt's
  cost is ledgered again. This over-counts, which pushes the gate toward
  stopping earlier — the fail-safe direction — and cannot bank a stale success,
  because a stale success would have been banked by the predicate rather than
  retried.

**Confidence:** High.

### 1.8 Regexes — closed

Ran `load_prs()` against the real vendored `benchmark_data.json`:

```
load_prs OK, n= 50
all selected forks+slugs pass both regexes
```

Zero false rejections on the 50 entries the code actually processes. `--all` is
not broken. See N5 for a wording nit in the commit message.

### 1.9 Test change

The rewritten bats case 8 is genuinely discriminating — I ran
`comments_from_rubric(md, ['Consider'])` against both the pre-fix (`529ecd2`)
and post-fix injector:

```
old-injector.py  rubric-current-format.md  n=2
old-injector.py  renamed.md                n=3     <- would fail
crb-pipeline…py  rubric-current-format.md  n=2
crb-pipeline…py  renamed.md                n=2     <- passes
```

`bats test/crb-injector-sections.bats`: **8/8 pass**.

---

## 2. Greenfield hunt — what the fixes broke

Read the ~200 new lines as new code rather than as a diff against the findings.
Nothing blocking. The four specific risks named in the brief:

- **Harvest loop vs `set -euo pipefail` / `read` at EOF** — clean (§1.1).
- **Subshell scoping change from `done < <(…)`** — no variable set inside the
  loop is read outside it; no counter depends on the old subshell.
- **Counters under `set -u` and arithmetic expansion** — correct (§1.7).
- **`sys.exit` after partial output in the injector** — real but non-blocking,
  see N4.

---

## Non-blocking

**N1 — The setup doc still documents the superseded resume predicate.**
**Severity:** Low (documentation) · **Confidence:** High
**Location:** `docs/working/crb-direction1-setup.md:103-108`
**Evidence:**
```
- **Completed cells are skipped only if they actually succeeded** —
  `num_turns > 0 AND NOT is_error AND subtype == "success"`. Verified against a
```
This is the pass-1 predicate that a04ef57 *replaced*. The commit's own comment
at `run-host.sh:161-163` says requiring `turns > 0` would re-pay for the 8
`e5-cc-builtin` cells. The bullet's *evidence* sentence was updated; the formula
above it was not. An operator reading the arm's spec doc would believe a clause
that no longer exists and that the code deliberately rejects. Highest-value
follow-up on this list. One-line fix.

**N2 — `attempts` becomes non-numeric when `attempts.jsonl` exists but is empty.**
**Severity:** Low · **Confidence:** High (reproduced)
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:186`
**Evidence:**
```bash
attempts=$(grep -c . "$dest/attempts.jsonl" 2>/dev/null || echo 0)
```
`grep -c` prints `0` **and** exits 1 on a zero-match file, so both the grep
output and the `echo 0` land in the substitution:
```
case=empty    attempts=$'0\n0'
bash: [: 0
0: integer expression expected
bash: 0
0: syntax error in expression (error token is "0")
```
Consequence, reproduced in the loop's real shape: the `[ -ge ]` test errors to
the else branch, then the `$((attempts+1))` expansion error causes bash to
abandon the **rest of that cell's loop body** — the `docker run` never happens —
and the loop continues to the next cell. `set -e` does not abort the sweep
(verified: outer rc=0). So it is fail-safe on money and on measurement; it costs
one silently un-run cell that `skipped_bad` does not count. Reachable only if a
ledger append is interrupted between file creation and write (e.g. Ctrl-C).
Fix: `attempts=$(grep -c . … || true); attempts=${attempts:-0}` — or
`attempts=$(wc -l < … 2>/dev/null || echo 0)`.

**N3 — `run-meta.json` still sums `result.json`, not `attempts.jsonl`.**
**Severity:** Low · **Confidence:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:366-381`
**Evidence:**
```python
rp = os.path.join(out, name, "result.json")
...
cells[name] = {"cost_usd": d.get("total_cost_usd"), ...}
```
The budget *gate* was correctly moved onto the per-attempt ledger; the
provenance record that reports total spend was not. A sweep with retries will
report a total lower than what was billed — the exact under-count the ledger was
introduced to fix, still present in the artifact a results doc would quote.
Spend remains correctly bounded, so this is reporting accuracy, not control.

**N4 — Injector's identifier charset check fires after the work dir is partly built.**
**Severity:** Low · **Confidence:** High (reproduced)
**Location:** `scripts/crb-pipeline-to-benchmark.py:356-359`
**Evidence:** with `--tool '$(touch …)'` the run emits
```
Wrote /…/out3/RUN.md (runbook for the judging steps)
refusing to generate judge.sh: --tool-name '$(…)' contains characters outside [A-Za-z0-9._/-]
```
By then `results/benchmark_data.json` is written and the judge dir seeded. The
failure is loud and the script is idempotent (`Kept existing …`), so a corrected
re-run heals it — but the validation belongs next to `args = ap.parse_args()`,
before any write. Note that traversal via `--judge` is already neutralised:
`sanitize_model` turns `/` into `_`, so `../../x` becomes `.._.._x`.

**N5 — The commit message's "2449 real dataset entries" is loose for `slug_for`.**
**Severity:** Low (accuracy of the commit record) · **Confidence:** High
**Location:** commit message of a04ef57
`fork`'s regex does accept all 2449 `repo_name` values (0 rejections, measured).
`slug_for` does **not**: 150 of the 2449 names have fewer than four `__`
components and raise `ValueError` (all `mra-*` tool forks, e.g.
`mra-claude__calcom_cal.com_pr11059`). It does not matter operationally —
`load_prs` selects exactly one fork per PR, preferring `claude-code`, and all 50
selected names pass both regexes (executed). The conclusion "`--all` is not
broken" is correct; the supporting sentence over-claims.

**N6 — `*..*` refuses legitimate filenames containing a double dot.**
**Severity:** Informational · **Confidence:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:271`
`case "$f" in /*|*..*)` rejects e.g. `notes..draft.md`. Deliberately
conservative, fail-closed, and the loop prints why. No action needed; noted so a
future reader does not mistake the stderr line for a bug.

**N7 — A voided cell still increments `ran`, so exit-3 cannot fire on a sweep that voids everything.**
**Severity:** Informational · **Confidence:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:224` vs `:389`
`ran=$((ran+1))` sits immediately after `docker run`, before the post-run
containment check. A sweep where every cell runs and every cell is then voided
exits 0. The printed `Cells: N ran, …` line and the per-cell `voiding this cell`
stderr make it visible, and the injector refuses every such cell, so no voided
data reaches the benchmark — the exit code is just less informative than it
could be.

---

## Verdict

The eight pass-2 findings are all closed, and every empirical claim in the
commit message that could change the arm's numbers was re-derived rather than
accepted: the resume predicate's 29/3 split, the traversal repro, the endpoint
and injection guards, the five clones' containment, the regexes over the real
dataset, and the test's discriminating power. The seven items above are
documentation drift and hygiene; none of them can corrupt a measurement, spend
money incorrectly, leak a credential, or destroy data. N1 is worth a one-line
commit before the sweep runs, but it does not gate the merge.

VERDICT: MERGEABLE — no blocking defects found

---

## Goal-Alignment Note
- Answered: yes — all eight pass-2 findings adjudicated, verdict issued
- Out of scope: R3's live-key/open-egress posture, the missing first-instance canary, the sequential loop, and the architecture/API items the tech-debt triage argued against — all explicitly deferred by a04ef57 and unchanged by it; also the advisory tiers of passes 1-2, per brief
- Escalate: N1 (`docs/working/crb-direction1-setup.md:104` documents the superseded `num_turns > 0` predicate) is a one-line doc fix worth landing before the sweep; N3 (`run-meta.json` under-reports retried spend) matters if any results doc quotes that total
