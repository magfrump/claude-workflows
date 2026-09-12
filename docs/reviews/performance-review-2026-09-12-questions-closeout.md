# Performance Review — questions.md close-out (`3a94fdc~1..HEAD`)

**Commit:** 435f46a
**Scope:** `git diff 3a94fdc~1..HEAD` — commits `3a94fdc`, `8980861`, `435f46a`; files `devcontainer-config/install.sh`, `docs/decisions/log.md`, `docs/working/questions.md`, `scripts/cross-model-review.py`, `scripts/lite-review.py`, `test/cc-isolated-functions.bats`, `test/lite-review-grammar.bats`
**Date:** 2026-09-12
**Based on:** `docs/reviews/code-fact-check-report.md` (merged, k=3, commit 435f46a)

---

## Data Flow and Hot Paths

126 insertions across 7 files. Three of the seven are pure documentation (`docs/decisions/log.md`, `docs/working/questions.md`, and the header comment in `scripts/lite-review.py`); one is a four-line comment in a script the same diff declares out of scope (`scripts/cross-model-review.py`); one is a one-line shell change plus two assertions. The only executable-surface addition is `test/lite-review-grammar.bats`.

Path temperatures, established by reading the enclosing units end to end:

- **`devcontainer-config/install.sh:100-110`** — **Cold.** The `read -r reply || reply=""` sits inside `if [ "$ASSUME_YES" != "--yes" ]`, whose `case` either falls through or `exit 1`s; the payload `cp -r` loop and `chmod` follow after the `fi`. One interactive human decision per install. There is no per-item or per-request work here, and the change removes zero work and adds zero work — it converts an errexit abort into a `case` fall-through on the same single evaluation. Nothing to price.
- **`scripts/lite-review.py` `parse_findings` (lines 86-108)** — **Cold, but on the live review path.** Called exactly once per `lite-review` invocation (`lite-review.py:167`), after `run_claude` has already paid a multi-second headless `claude -p` round trip. Its input is one LLM response, bounded by the model's output budget. This is the one place in the diff where an algorithmic question exists, because the diff is what promotes this parser from "a copy of cross-model-review's" to **the** owned definition of the FINDINGS contract.
- **`test/lite-review-grammar.bats`** — **Cold (developer/CI loop).** Seven tests, each one `run parse`, each `parse` spawning one `python3` that `exec_module`s `scripts/lite-review.py`. It carries `# @category fast`, so it joins the pre-commit-relevant `scripts/run-tests.sh --fast` run.

Measured cost shape of the new suite, executed here on 2026-09-12:

| Measurement | Value |
|---|---|
| `bats test/lite-review-grammar.bats` wall time | **0.298 s** |
| 7 × (`python3` spawn + `exec_module` of `lite-review.py`) | **0.139 s** (~20 ms each) |
| `scripts/run-tests.sh --fast` wall time (623 tests, per fact-check Claim 17) | **61.1 s** |
| New suite's share of the fast gate | **~0.49 %** |

The per-assertion interpreter spawn the brief flagged as a candidate is real — it is about half the suite's own runtime — but it buys ~0.14 s against a 61 s gate. Amortizing it (one interpreter, seven cases) would save roughly 0.12 s and cost the suite its one-process-per-case isolation. That is not worth doing, and I am not filing it as a finding.

`exec_module` is safe to call seven times because `lite-review.py`'s only top-level work is imports, constants, and one `re.compile`; `main()` is behind `if __name__ == "__main__"` (`lite-review.py:208-209`), so no `claude` process is spawned — consistent with fact-check Claim 15.

---

## Findings

#### `FINDING_RE` backtracks super-linearly on a whitespace run, and the diff makes this repo the owner of that behavior

**Severity:** Medium
**Location:** `scripts/lite-review.py:73-78` (regex), consumed at `scripts/lite-review.py:98` inside `parse_findings` (lines 86-108)
**Move:** 9 — asymptotic behavior, not just the constant (with move 6, parsing untrusted-ish input with a parser slow on adversarial input)
**Classification:** Macro (wrong complexity class — super-linear in one line's length) / **Cold path** (once per `lite-review` invocation, after a multi-second API call; `parse_findings` is called at `lite-review.py:167` and nowhere else in the diff's scope)
**Confidence:** High (measured, not inferred)
**Legibility-target:** for-author
**Baseline:** Measured — **7,599 ms** for a single `parse_findings` call on a FINDINGS block containing one 3,203-character line whose body is a 3,200-character whitespace run; and **877,638 ms (14 min 38 s)** for one `FINDING_RE.match` against a 16,003-character line of the same shape. Python 3.11.2, this sandbox, 2026-09-12.

**Evidence** (verbatim, `scripts/lite-review.py:73-78`):

```python
FINDING_RE = re.compile(
    r"^\s*\d+\.\s*(?P<path>[^|:]+?)(?::(?P<lines>[\d\-, ]+))?\s*\|"
    r"\s*(?P<sev>Critical|High|Medium|Low|Informational)\s*\|"
    r"\s*(?P<domain>[^|]+)\|\s*(?P<title>[^|]+)\|\s*(?P<desc>.+)$",
    re.IGNORECASE,
)
```

**Evidence** (verbatim, `scripts/lite-review.py:92-99`; the remainder of `parse_findings` — the `rows.append({...})` dict build at 100-107 and the `return rows, bool(rows) or "FINDINGS" in text` at 108 — was read and is not load-bearing for this finding):

```python
    for line in text.splitlines():
        if line.strip().startswith("FINDINGS:"):
            in_block = True
            continue
        if not in_block:
            continue
        m = FINDING_RE.match(line)
        if m:
```

`(?P<path>[^|:]+?)` and the following `\s*` both match a space, and the optional `(?::(?P<lines>[\d\-, ]+))?` sits between them. For a line inside the FINDINGS block that starts `\d+\.` but contains no `|`, the engine must try every split of a contiguous whitespace run between the lazy `path` group and `\s*` before it can fail. Measured growth is roughly **O(n^2.8)** in the length of that run — every doubling costs ~7×:

| Contiguous whitespace run | `parse_findings` wall time |
|---|---|
| 200 chars | 5.4 ms |
| 400 chars | 39.1 ms |
| 800 chars | 184.8 ms |
| 1,600 chars | 1,038.9 ms |
| 3,200 chars | 7,598.9 ms |

A separate longer-running probe against `FINDING_RE.match` directly carries the curve out further, and the tail is worse than the extrapolation suggests: 1,000 chars → 274.7 ms, 2,000 → 1,951.8 ms, 4,000 → 14,182.0 ms, 8,000 → 111,679.4 ms, and **16,000 chars → 877,637.7 ms (14 min 38 s for one line)**. The ratio is ~7.9× per doubling and does not flatten; for practical purposes a single sufficiently padded line is an unbounded hang rather than a slow parse.

Well-formed rows and ordinary non-matching prose are unaffected, and the same probe confirms the trigger is specifically a long *contiguous* whitespace run rather than line length: at 32,000 characters, a line of alternating `"a "` pairs fails in 2.3 ms, a `"1,"`-repeated colon-digit run in 1.0 ms, and a solid alphanumeric run in 1.0 ms — all linear, all sub-millisecond-per-1,000-chars. A 2,021-char valid row matches in 0.068 ms. Realistic sources of a solid whitespace run are deeply-indented code the model echoed back, a padded ASCII table, or trailing whitespace carried out of the diff into the response.

**Why this is in scope for this diff even though the regex byte-didn't change.** Fact-check Claim 6 establishes the two regexes were byte-identical when ownership moved; this behavior is inherited, not introduced. What `435f46a` changes is who is accountable for it: `lite-review.py:24-31` now says "This file OWNS the FINDINGS grammar and its regex," and `test/lite-review-grammar.bats` is described as what "pins the shape … once the harness leaves." A contract suite that pins the grammar's *shape* but says nothing about its *cost* leaves the owner with no guard against a future grammar edit moving the curve further left. The curve is already steep enough that the distinction between "slow" and "hung" is academic: 16,000 padding characters on one line cost 14 min 38 s, measured.

Impact today is still low in expectation — a cold path, one call, after an API call that already took seconds, on input the same machine's own subscription produced, at line lengths a model realistically emits. It is Medium rather than Low because the complexity class is wrong (macro problems bite on data growth, not on call frequency), because the degradation cliffs rather than degrades gracefully, and because this diff is the moment the repo took the liability on. It is Medium rather than High because reaching the pathological region requires input this path does not normally see and no attacker supplies.

**Recommendation:** Make the path group non-greedy over a bounded, non-whitespace-ambiguous class — e.g. `(?P<path>[^|:\s][^|:]*?)` plus a length bound, or the simplest fix, an early `if "|" not in line: continue` guard before the `FINDING_RE.match(line)` at line 98, which sheds every pathological case for one substring scan. Add one timing-bounded case to `test/lite-review-grammar.bats` (a 4,000-space line must parse in well under a second) so the owned contract covers cost, not only shape.

---

#### The new contract suite constrains grammar narrowing but not widening — the cost is re-review rounds, not CPU

**Severity:** Informational
**Location:** `test/lite-review-grammar.bats:33-97` (the seven `@test` blocks), against `scripts/lite-review.py:73-78`
**Move:** 3 — work that moved to the wrong place (correctness work moved from the parser's guard into a later human round)
**Classification:** Macro (a structural gap in the guard) / **Cold path** (CI/pre-commit gate)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** no baseline available — flagged as speculative

This is escalation E2; it is primarily an api-consistency concern and I defer the correctness framing to that critic. The cost angle the brief asked for is this: fact-check Claim 7 records that all three replicates mutation-tested `FINDING_RE` and that **narrowing the line-range class from `[\d\-, ]+` to `[\d\-]+` left 7/7 green while silently dropping comma-separated line lists**. A dropped row is a finding that never reaches the reviewer, so the loop pays for it later as an extra review round — on this repo's own accounting, a `lite-review` pass plus a human read. That is a materially larger unit of cost than any CPU figure in this diff, and it is invisible to a shape-only contract suite.

The same gap is what leaves Finding 1 unguarded: no mutation in the recorded set would be caught by a timing assertion either, because there is no timing assertion.

**Recommendation:** Treat this as one item with Finding 1's test recommendation — when adding the cost-bounded case, also add the comma-separated line-range case (`1. a.py:12,18-20 | ...`) that the r2 mutation showed is currently unpinned. No baseline capture is needed; both are cheap deterministic assertions.

---

## Endorsements (evidence-gated)

- The seven new tests exercise `parse_findings` with no `claude` spawn and no credentials, so adding them to the `fast` category does not put an API call behind the commit gate. `[fact-check: claim 15 — Verified (executed)]`
- The fast gate is green at HEAD with the new suite included — 623 tests, 0 failures — so the suite does not introduce a flaky or failing cost on the gate. `[fact-check: claim 17 — Verified (executed)]`
- `install.sh`'s `read -r reply || reply=""` adds no work to the install path: it changes one `read`'s failure handling inside a branch that runs once per interactive install, and the enclosing `case` still `exit 1`s on decline before the payload `cp -r` loop begins. `[read: devcontainer-config/install.sh:100-121]`
- `test/lite-review-grammar.bats` costs 0.298 s wall, of which 0.139 s is the seven `python3` spawns, against a 61.1 s `run-tests.sh --fast` run — about 0.49 % of the gate, so the per-assertion interpreter spawn does not warrant amortizing. `[unverified — submitted as claim]`
- Loading `scripts/lite-review.py` seven times via `exec_module` triggers no side effect beyond imports, constants and one `re.compile`, because `main()` is guarded by `if __name__ == "__main__"` at `scripts/lite-review.py:208-209`. `[read: scripts/lite-review.py:33-40, 73-78, 208-209]`

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `FINDING_RE` backtracks ~O(n^2.9) on a contiguous whitespace run (16k chars = 14 min 38 s, measured); ownership moves here with no cost guard | Medium | `scripts/lite-review.py:73-78`, `:98` | High |
| 2 | Contract suite pins grammar shape but not cost or widening; the price is re-review rounds | Informational | `test/lite-review-grammar.bats:33-97` | Medium |

---

## Overall Assessment

The honest headline is that this diff has essentially no performance surface. Three files are documentation, one is a comment in a script the diff itself scopes out, the shell change is a one-line errexit fix on a once-per-install interactive prompt, and the new test suite costs 0.3 s against a 61 s gate — the interpreter-per-assertion shape the brief flagged is real and not worth fixing. I found nothing to say about the install path or the decision-log entries beyond confirming they add no work.

The one substantive item is Finding 1, and it is a liability-transfer finding rather than a regression: `FINDING_RE` has always had a super-linear failure mode on whitespace runs, but `435f46a` is the commit that declares this repo the grammar's owner and ships a contract suite that pins shape without pinning cost. It is Medium, not High, because the path is cold, single-call, downstream of a multi-second API round trip, and fed by input the same machine produced — nobody is going to notice 7 s once, and no attacker is positioned to supply the 16,000-character line that costs 14 minutes. It deserves a fix now anyway because the degradation cliffs rather than degrades, because the fix is one line (`if "|" not in line: continue` before line 98) and because the whole point of the ownership move is that this file is what the contract will be read from after the benchmark harness leaves. Findings 1 and 2 share a single remedy: two more assertions in `test/lite-review-grammar.bats` — one cost-bounded, one for the comma-separated line range the r2 mutation showed is unpinned. No profiling is needed; the numbers in Finding 1 are measured, and the remaining questions are contract questions, not measurement questions.

---

## Goal-Alignment Note

**Answered.** The user's goal was a review of the last three commits before the work is considered settled, closing out `docs/working/questions.md`. From the performance angle the answer is: settle it. The diff is safe to consider closed; nothing in it degrades a hot path, adds an allocation per request, or makes the commit gate meaningfully slower.

**Out of scope.** I did not evaluate whether the OpenRouter questions were *correctly* closed as moot (a scoping/architecture judgment), nor the four-way `parse_findings` divergence recorded in fact-check Claim 13 — including r2's observation that a model refusal parses as `parse_ok=True` on the live path. That last one is a correctness bug with real cost consequences (a refused review reads as a clean review), but it is pre-existing, not in this diff, and belongs to the correctness/api-consistency critics, not to me.

**Escalate.** E2's cost angle, as Finding 2: the recorded mutation showing a line-range narrowing passing 7/7 while dropping rows means the suite can go green while findings vanish. The synthesis should treat Findings 1 and 2 as one two-assertion follow-up rather than two separate tickets.

**Questions I would have asked.**
1. Is `lite-review` ever run over anything other than its own `claude -p` output — a saved transcript, a pasted review, another model's output? If yes, Finding 1's input stops being self-produced and the severity argument changes.
2. Is there a target wall-clock budget for `run-tests.sh --fast`? 61.1 s is the measured number here; without a stated budget I cannot say whether 0.3 s is comfortable or whether the gate is already near a threshold someone cares about.
