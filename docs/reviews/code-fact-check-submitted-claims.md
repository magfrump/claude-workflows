# Code Fact-Check Report

**Commit:** 435f46a
**Repository:** /workspace
**Scope:** Submitted-claims verification pass (Stage 2.5) over the diff `3a94fdc~1..HEAD` — four endorsement claims routed by `security-reviewer` (SC1, SC2) and `api-consistency-reviewer` (SC3, SC4). No harvested claims in this report; see `docs/reviews/code-fact-check-report.md` for those.
**Checked:** 2026-09-12
**Total claims checked:** 6 (four submitted claims; SC1 and SC3 each split into two sub-claims on verdict divergence)
**Summary:** 4 verified, 1 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log consulted before checking (`docs/reviews/hallucination-patterns.md`, four entries, all of the "specific measured value quoted from an artifact set that does not contain it" or "file-to-symbol association asserted without grepping the file" class). SC2 is the nearest relative — a universally quantified file-to-symbol claim submitted on read-static evidence from two call sites — so it was checked by full enumeration rather than by re-reading the cited lines. It did not recur as a fabrication.

---

## Submitted Claims

## Claim 1a: "The `install.sh` bless prompt fails closed on every stdin shape except a literal `y`/`yes`"

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/install.sh:101-111`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five stdin shapes the critic enumerated, executed against the real `devcontainer-config/install.sh` (not a replica); does not establish behavior on the `--yes` path at `:101` (never exercised — `ASSUME_YES` skips the whole block), behavior on an interactive tty, or behavior of the `cc-isolated.sh --bless` step at `:130` beyond its exit status in this fixture.

Re-run against the **real** script through the `fake_install_repo` fixture pattern from `test/cc-isolated-functions.bats:435-448` (extended so the seven `PAYLOAD` items at `devcontainer-config/install.sh:25` exist and the blessed path can complete). All five shapes reproduced the critic's replica results exactly (`docs/reviews/execution-logs/sc1-install-real-stdin-shapes.txt`):

```
--- shape: printf 'y' (no newline)   exit: 1   aborted_line_count: 1
--- shape: printf 'y\n'              exit: 0   past_prompt_linked_count: 1
--- shape: printf ' y\n'             exit: 0   past_prompt_linked_count: 1
--- shape: printf 'yes please\n'     exit: 1   aborted_line_count: 1
--- shape: </dev/null                exit: 1   aborted_line_count: 1
```

The imprecision is in "a literal `y`/`yes`". The accepting arm is a case-insensitive glob pair, not a literal, and `read` strips the leading blank before the `case` sees it — `devcontainer-config/install.sh:106-110`:

```sh
  read -r reply || reply=""
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Aborted. Nothing was changed."; exit 1 ;;
  esac
```

The precise version: *the prompt fails closed on every stdin shape whose first line does not word-split to `y` or `yes` case-insensitively* — which admits `Y`, `YES`, `yEs`, and any of those with surrounding whitespace (the executed ` y\n` shape blesses, as the critic's own evidence recorded). The fail-closed conclusion and the mechanism are both right; only the acceptance set is stated more narrowly than the code implements, which understates rather than overstates the guard.

**Evidence:** `devcontainer-config/install.sh:101-111`, `test/cc-isolated-functions.bats:435-448`, `docs/reviews/execution-logs/sc1-install-real-stdin-shapes.txt`
**Provenance:** `bash /tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/sc1/run.sh .../install-real.sh` (a copy of the tracked `devcontainer-config/install.sh`, byte-identical), cwd `/workspace`, driver exit 0, per-shape exit codes as quoted, 2026-09-12T19:38:40Z.

---

## Claim 1b: "The assignment in `read -r reply || reply=\"\"` is load-bearing rather than cosmetic — the counterfactual `read -r reply || true` blesses on `printf 'y'`, whereas `|| reply=\"\"` discards it and aborts"

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/install.sh:103-106`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `printf 'y'` (partial read at EOF) discrimination between `|| reply=""` and `|| true`, executed on the real script; does not establish that `|| true` diverges on any other shape (it does not — see below), nor that no third spelling (e.g. `read -r reply || :`) would behave differently, nor anything about the `--yes` path.

Confirmed. The counterfactual copy (identical to HEAD except `read -r reply || true` at `:106`) blesses on the newline-less `y` where the real script aborts (`docs/reviews/execution-logs/sc1-install-counterfactual-stdin-shapes.txt`):

```
--- shape: printf 'y' (no newline)   exit: 0   aborted_line_count: 0   past_prompt_linked_count: 1
```

against the real script's `exit: 1 / aborted_line_count: 1` for the same shape, quoted in Claim 1a. That is the only shape on which the two variants diverge: `y\n`, ` y\n`, `yes please\n` and `</dev/null` produce identical exit codes and identical `Aborted`/`Linked` markers under both spellings (`docs/reviews/execution-logs/sc1-install-counterfactual-stdin-shapes.txt`, all five shape blocks). Notably `</dev/null` aborts under `|| true` as well, because `read` assigns the empty remainder before returning non-zero — so the property the assignment actually buys is *discarding a partial read*, not *defining the variable*.

This is a substantive property of the chosen fix that is recorded nowhere else: the commit message for 8980861 and the comment at `devcontainer-config/install.sh:103-105` both motivate the change by errexit ("dying on `read`'s non-zero exit under `set -e`"), and the test at `test/cc-isolated-functions.bats:474-489` closes stdin with `</dev/null`, which — as measured above — is exactly the shape on which the two spellings do **not** differ. The bless-on-partial-read discrimination is untested.

**Evidence:** `devcontainer-config/install.sh:103-106`, `test/cc-isolated-functions.bats:474-489`, `docs/reviews/execution-logs/sc1-install-counterfactual-stdin-shapes.txt`, `docs/reviews/execution-logs/sc1-install-real-stdin-shapes.txt`
**Provenance:** same driver as Claim 1a with the mutated copy `.../scratchpad/sc1/install-counterfactual.sh`, cwd `/workspace`, driver exit 0, 2026-09-12T19:38:48Z.

---

## Claim 2: "No call site in the diff scope constructs a shell string; every external process is launched argv-form (no `shell=True`, list literals only)"

**Submitted by:** security-reviewer
**Location:** `scripts/lite-review.py:83,114-126`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every process-launch site in the seven files of `3a94fdc~1..HEAD`, established by enumeration of `subprocess.*`, `os.system`, `os.popen`, `Popen`, `shlex` and `eval` across those files — not by re-reading the two cited lines; does not establish that the *arguments* passed are validated or trusted (`args.rev_range` and `args.repo` reach `git` unvalidated, which argv-form makes non-injectable but not semantically safe), and does not cover `devcontainer-config/install.sh`, which is a shell script whose every line is a shell command by construction and to which the argv/shell-string distinction does not apply.

Enumeration over `scripts/lite-review.py` (grep for `subprocess.|os.system|os.popen|os.exec|shell=|popen|Popen|shlex|eval(|check_output|check_call`) returns exactly two hits, both `subprocess.run`, both list-form, neither carrying `shell=`:

```python
# scripts/lite-review.py:81-83
def sh(args, cwd=None):
    # argv-exec, never shell strings (decision 018)
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=True).stdout
```

```python
# scripts/lite-review.py:114-126
        proc = subprocess.run(
            [
                "claude", "-p",
                "--model", model,
                "--output-format", "json",
                "--system-prompt", SYSTEM_PROMPT,
                "--tools", "",
                "--no-session-persistence",
            ],
            input=prompt,
            cwd=empty_cwd,  # empty non-repo dir: no CLAUDE.md auto-discovery
            capture_output=True, text=True, timeout=timeout_s,
        )
```

Both have exactly one caller each, and both callers pass list literals — `diff = sh(["git", "diff", args.rev_range], cwd=args.repo)` (`scripts/lite-review.py:149`) and `env = run_claude(prompt, args.model, args.timeout)` (`scripts/lite-review.py:160`). The only other `os.` uses in the file are `os.makedirs`/`os.path.join` at `scripts/lite-review.py:187-190`, which launch nothing.

The second Python file in the diff scope, `scripts/cross-model-review.py`, has one launch site with the same shape and three call sites that all build argv lists by concatenation onto a list literal:

```python
# scripts/cross-model-review.py:147-149
def sh(args, cwd=None):
    # argv-exec, never shell strings (decision 018)
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=True).stdout
```

```python
# scripts/cross-model-review.py:204
    gitq = ["git", "-C", repo, "-c", "core.quotepath=off"]
```

with `sh(gitq + ["diff", ...])`, `sh(gitq + ["show", f"{right}:{path}"])`, `sh(gitq + ["cat-file", "-s", f"{right}:{path}"])` at `scripts/cross-model-review.py:206,217,221,231`; the remaining `subprocess.` hits at `:222,232` are `except subprocess.CalledProcessError` handlers, not launches. The two `.bats` files in the diff scope launch `python3` and `bash` only through bats' own `run`/direct-invocation forms with separate arguments (paraphrased — no quote available because the assertion is about the absence of shell-string construction across `test/lite-review-grammar.bats:21-31` and `test/cc-isolated-functions.bats:435-489`, i.e. a negative grep result rather than a snippet). The remaining three diff-scope files are Markdown.

**Evidence:** `scripts/lite-review.py:81-83,114-126,149,160,187-190`, `scripts/cross-model-review.py:147-149,204-231`, `test/lite-review-grammar.bats:21-31`, `test/cc-isolated-functions.bats:435-489`

---

## Claim 3a: "The three negative tests recommended in Finding 4 fail against the current `FINDING_RE`"

**Submitted by:** api-consistency-reviewer
**Location:** `docs/reviews/api-consistency-review-2026-09-12-questions-closeout.md` Finding 4 recommendation; `scripts/lite-review.py:73-78`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the outcome of the three recommended assertions (each "asserting **zero rows**") when run against `FINDING_RE` as it stands at 435f46a; does not establish anything about the *value* of those tests — that half of the claim is Claim 3b, which is Verified.

Under the natural reading in a testing context — the test fails, i.e. goes red — this is refuted. All three recommended inputs yield **zero rows** against the current regex, which is exactly what the recommended assertions require, so all three would pass green the moment they were added (`docs/reviews/execution-logs/sc3-finding4-negative-tests.txt`):

```
--- N1 unknown severity (Blocker)
    current regex   -> rows=0 parse_ok=True  (recommended test asserts 0 rows -> PASSES)
--- N2 empty description
    current regex   -> rows=0 parse_ok=True  (recommended test asserts 0 rows -> PASSES)
--- N3 '- ' bullet row
    current regex   -> rows=0 parse_ok=True  (recommended test asserts 0 rows -> PASSES)
```

That is the correct and intended state for a regression pin: a negative test that went red against unmutated code would be reporting a live defect, not pinning a contract. The recommendation itself is consistent with this — it asks for tests "each asserting **zero rows**", and Finding 4's own argument is that the suite currently lacks rejection assertions, not that the regex currently accepts these rows.

The precise version of the submitted sentence is *the three recommended inputs fail to match the current `FINDING_RE`* (they are rejected), which is what Claim 3b verdicts. As submitted, the sentence asserts a red test suite at HEAD; a reader acting on it — adding the three tests and expecting to see them fail before fixing something — would be misled about the state of the code.

**Evidence:** `scripts/lite-review.py:73-78`, `docs/reviews/api-consistency-review-2026-09-12-questions-closeout.md:288-292` (the recommendation text), `docs/reviews/execution-logs/sc3-finding4-negative-tests.txt`
**Provenance:** `python3 /tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/sc3_probe.py`, cwd `/workspace`, exit 0, 2026-09-12T19:39Z. The probe loads the tracked `scripts/lite-review.py` unmodified and swaps `FINDING_RE` in-memory for the mutant arms.

---

## Claim 3b: "...i.e. they would actually catch the widening mutations they are meant to catch"

**Submitted by:** api-consistency-reviewer
**Location:** `test/lite-review-grammar.bats`; `scripts/lite-review.py:73-78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three recommended negative tests against the one widening mutation each names (`Blocker` added to the severity alternation; `(?P<desc>.+)` widened to `.*`; the row prefix widened to accept `- `), plus the recommended positive comma-range test against the `[\d\-, ]+` narrowing; does not establish that these four tests catch the other two of the five widenings Fact-check Claim 7 found surviving the existing suite (the path group swallowing `:` is untested here), nor that the tests as literally spelled in Finding 4 are syntactically well-formed bats.

Each recommended input flips from 0 rows to 1 row under its targeted mutation, so each assertion goes red exactly when the contract is widened (`docs/reviews/execution-logs/sc3-finding4-negative-tests.txt`):

```
--- N1 unknown severity (Blocker)
    mutation (severity alternation widened with Blocker) -> rows=1  (recommended test -> FAILS (mutation caught))
--- N2 empty description
    mutation (desc group widened from .+ to .*) -> rows=1  (recommended test -> FAILS (mutation caught))
--- N3 '- ' bullet row
    mutation (row prefix widened to accept '- ') -> rows=1  (recommended test -> FAILS (mutation caught))
```

The fourth recommended test (positive, comma-separated range) also discriminates:

```
--- P1 comma-separated range (recommended positive test)
    current regex -> rows=1 lines=10,14-16 path=a.py
    narrowing mutation ([\d\-, ]+ -> [\d\-]+) -> rows=0 (caught)
```

so `a.py:10,14-16` both survives the current grammar with its range intact and disappears under the narrowing Finding 4 names. The mutation arms operate on the live pattern string from `scripts/lite-review.py:73-78`:

```python
FINDING_RE = re.compile(
    r"^\s*\d+\.\s*(?P<path>[^|:]+?)(?::(?P<lines>[\d\-, ]+))?\s*\|"
    r"\s*(?P<sev>Critical|High|Medium|Low|Informational)\s*\|"
    r"\s*(?P<domain>[^|]+)\|\s*(?P<title>[^|]+)\|\s*(?P<desc>.+)$",
    re.IGNORECASE,
)
```

**Evidence:** `scripts/lite-review.py:73-78`, `test/lite-review-grammar.bats:33-97`, `docs/reviews/execution-logs/sc3-finding4-negative-tests.txt`
**Provenance:** same command, cwd and timestamp as Claim 3a.

---

## Claim 4: "Changing `scripts/lite-review.py:103` (the `parse_ok` derivation, currently `return rows, bool(rows) or \"FINDINGS\" in text`) to `in_block or bool(rows)` leaves all seven existing tests in `test/lite-review-grammar.bats` green"

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lite-review.py:108` (the submitted `:103` is off by five; the `return` is at `:108`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seven tests in `test/lite-review-grammar.bats` under the one-line substitution, executed on a scratch copy, plus the end-to-end refusal question for the single input the orchestrator named; does not establish that the change is safe for the wired callers' other inputs, and specifically does **not** establish that it fixes the refusal-reads-as-clean class in general — see the second refusal probed below, which still reads clean.

All seven pass under the mutation, identically to HEAD (`docs/reviews/execution-logs/sc4-parse-ok-mutation-suite.txt`): `1..7` with `ok 1` through `ok 7` and exit 0 for the baseline run of `test/lite-review-grammar.bats` at HEAD, and `1..7` with `ok 1` through `ok 7` and exit 0 for the scratch copy whose parser line reads `    return rows, in_block or bool(rows)`. The submitted location is one line-number slip: `scripts/lite-review.py:103` is a dict field inside the row append; the derivation is at `:108`:

```python
# scripts/lite-review.py:108
    return rows, bool(rows) or "FINDINGS" in text
```

**Second-order (end-to-end) result, as asked.** With `run_claude` stubbed to return a success envelope whose `result` is the refusal the security critic named, `main()` at HEAD prints `FINDINGS: NONE` and returns 0; under `in_block or bool(rows)` it returns 2 (`docs/reviews/execution-logs/sc4-refusal-end-to-end.txt`):

```
=== HEAD  (bool(rows) or "FINDINGS" in text)
  input : 'I cannot emit FINDINGS for this diff.'
  rc    : 0
  stdout: 'lite-review [fix-drift]: FINDINGS: NONE (12 out-tokens)'
=== COPY  (in_block or bool(rows))
  input : 'I cannot emit FINDINGS for this diff.'
  rc    : 2
  stdout: 'lite-review: PARSE FAILURE - raw output:\nI cannot emit FINDINGS for this diff.'
```

So for that input the fix does work end to end, exit code included — the wired callers at `workflows/pr-prep.md:218` and `workflows/review-fix-loop.md:69` would see a non-zero exit instead of a green fix-drift pass.

It does not close the class. A refusal whose first line *starts* the block sets `in_block = True` at `scripts/lite-review.py:93-94`, and both variants then report clean:

```
=== COPY  (in_block or bool(rows))
  input : 'FINDINGS: I cannot review this diff.'
  rc    : 0
  stdout: 'lite-review [fix-drift]: FINDINGS: NONE (12 out-tokens)'
```

The residual gap is that `parse_ok` remains a block-presence signal, while `main()`'s `if not findings:` arm at `scripts/lite-review.py:196-199` treats block-present-and-empty as `FINDINGS: NONE` without requiring the `NONE` sentinel that `parse_findings` already recognizes at `scripts/lite-review.py:88`. Closing the class end to end needs the empty-block arm to distinguish "sentinel seen" from "block seen, nothing parsed" — a second change, not this one.

**Evidence:** `scripts/lite-review.py:88,93-94,108,193-199`, `test/lite-review-grammar.bats:33-97`, `docs/reviews/execution-logs/sc4-parse-ok-mutation-suite.txt`, `docs/reviews/execution-logs/sc4-refusal-end-to-end.txt`
**Provenance:** (1) `bats test/lite-review-grammar.bats` and `bats /tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/sc4/repo/test/lite-review-grammar.bats`, cwd `/workspace`, both exit 0, 2026-09-12T19:40:10Z. (2) `python3 /tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/sc4_e2e.py`, cwd `/workspace`, exit 0, 2026-09-12T19:40:28Z. The mutation lives only in the scratch copy; `/workspace/scripts/lite-review.py` was never modified.

---

## Claims Requiring Attention

### Incorrect
- **Claim 3a** (`scripts/lite-review.py:73-78`): the three negative tests recommended in Finding 4 **pass** (0 rows) against the current `FINDING_RE`, not fail. The intended and true statement is that the three *inputs* fail to match; the tests go red only under the widening mutations (Claim 3b).

### Mostly Accurate
- **Claim 1a** (`devcontainer-config/install.sh:101-111`): "a literal `y`/`yes`" understates the accepting arm — `[yY]|[yY][eE][sS]` accepts `Y`/`YES`/`yEs`, and `read` strips surrounding whitespace, so ` y\n` blesses. Tighten to "any reply that word-splits to `y` or `yes`, case-insensitively".

### Unverifiable
- None. Every executable guarantee in the submitted set was run.

### Unrecorded substantive properties surfaced while verifying
- **Claim 1b**: the partial-read discrimination (`printf 'y'` with no newline: `|| true` blesses, `|| reply=""` aborts) is the only shape on which the two spellings differ, and `</dev/null` — the shape the test at `test/cc-isolated-functions.bats:474-489` uses — is not one of them. Neither commit 8980861's message nor the comment at `devcontainer-config/install.sh:103-105` records it; no test covers it.
- **Claim 4**: `in_block or bool(rows)` fixes the named refusal end to end but not the class — a refusal beginning `FINDINGS:` still exits 0 as a clean fix-drift pass.

No entries were appended to `docs/reviews/hallucination-patterns.md`: the single Incorrect verdict (Claim 3a) is a directional misstatement about a test outcome, not a fabricated symbol, API, or behavior.

---

## Goal-Alignment Note

**Answered.** The user's goal was a review of the last three commits on main before the work is considered settled; this pass verdicts the four endorsement claims the critics routed rather than self-certifying, so the orchestrator's rubric carries no self-certified positives for `3a94fdc~1..HEAD`. Five of the six entries rest on execution rather than reading, per the mandatory-execution rule: SC1 was re-run against the **real** `devcontainer-config/install.sh` through the `fake_install_repo` fixture pattern (the critic's stated Not-verified on the replica is now closed), SC3 and SC4 were run as mutation probes and a full suite run.

**Out of scope for this pass.** Whether Finding 4's tests should be added, whether Finding 5's one-line change should ship, and the blocking severity of the refusal-reads-as-clean behavior — those are the critics' and the orchestrator's calls. I report only that the recommended tests do discriminate (3b), that the proposed fix keeps the suite green and repairs the named input but not the class (4), and that one submitted sentence is wrong as written (3a).

**Escalate.** Two items for the orchestrator's rubric. (1) Claim 1b's partial-read property is load-bearing, real, and recorded nowhere — the commit message, the code comment, and the one test that covers this fix all rest on the EOF shape, on which the buggy and fixed spellings behave identically. If the working-tree fix is meant to be durable, this wants either a comment line or a second test case (`printf 'y'`, no newline) that fails against `|| true`. (2) Claim 4's end-to-end residue: adopting `in_block or bool(rows)` closes the `"I cannot emit FINDINGS…"` input but leaves `"FINDINGS: I cannot review this diff."` exiting 0 as a clean pass, so "E1 is closed" would overstate what the one-liner buys.

**Questions I would have asked.** Was the `--yes` path at `devcontainer-config/install.sh:101` intended to be covered by SC1's fail-closed endorsement? It was excluded here (the block is skipped wholesale when `ASSUME_YES = --yes`), and it is the one prompt-adjacent path with no test at all.
