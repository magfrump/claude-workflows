# Code Fact-Check Report

Commit: 435f46a

**Repository:** /workspace
**Scope:** `git diff 3a94fdc~1..HEAD` — commits `3a94fdc`, `8980861`, `435f46a`; files `devcontainer-config/install.sh`, `docs/decisions/log.md`, `docs/working/questions.md`, `scripts/cross-model-review.py`, `scripts/lite-review.py`, `test/cc-isolated-functions.bats`, `test/lite-review-grammar.bats`, plus the three commit messages
**Checked:** 2026-09-12
**Total claims checked:** 17 (16 numbered, Claim 4 split into 4a/4b)
**Summary:** 12 verified, 3 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Three of its four
entries are the same class — *a specific measured value quoted from a checked-in artifact set
that does not contain it*. Every numeric claim in this diff was compared against that pattern
and executed where possible; see Claims 8, 13, 14, 15.

---

## Claim 1: "`|| reply=\"\"` so a closed/EOF stdin (piped or non-tty run) falls through to the abort case below instead of dying on `read`'s non-zero exit under `set -e`, which killed the script before it could say why."

**Location:** `devcontainer-config/install.sh:103-105`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the EOF/closed-stdin path through the `if [ "$ASSUME_YES" != "--yes" ]` block and the `case` that follows, for both the pre-fix and post-fix install.sh; does not establish behavior for a non-empty reply, for `--yes`, or for a `read` failure other than EOF (e.g. a signal-interrupted read).

The script runs under errexit:

```bash
# devcontainer-config/install.sh:16
set -euo pipefail
```

The complete enclosing block, signature to final line:

```bash
# devcontainer-config/install.sh:101-110
if [ "$ASSUME_YES" != "--yes" ]; then
  printf 'Install this config and bless it? [y/N] '
  # `|| reply=""` so a closed/EOF stdin (piped or non-tty run) falls through to
  # the abort case below instead of dying on `read`'s non-zero exit under
  # `set -e`, which killed the script before it could say why.
  read -r reply || reply=""
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Aborted. Nothing was changed."; exit 1 ;;
  esac
fi
```

The empty `reply` falls to the `*)` arm, which prints the abort line and exits 1 (excerpt ends
`:110` at `fi`; the enclosing `if` block is complete — read; execution continues at
`mkdir -p "$DEST" "$BIN_DIR"` on `:112`, reached only when the `[yY]` arm is taken).

Executed against the pre-fix script to confirm the "killed the script before it could say why"
half. Command:
`bash scratchpad/oldrepo.sh <tmpdir>` (stages `git show 8980861~1:devcontainer-config/install.sh`
into a fake repo tree and runs it with `</dev/null`), cwd `/workspace`, exit code 1, at
2026-09-12T12:21:07-07:00. Output ends at the prompt with no abort line:

```
Install this config and bless it? [y/N] EXIT=1
```

The post-fix path was executed as part of Claim 14 (bats test 4 asserts the `Aborted.` line and
passes).

**Evidence:** `devcontainer-config/install.sh:16`, `devcontainer-config/install.sh:101-110`, `docs/reviews/execution-logs/r2-old-install-behavior.txt`, `docs/reviews/execution-logs/r2-install-sh-tests.txt`

---

## Claim 2: log row 48's citations — the pre-flight WARNING shipped in `cb5351d`, the grammar-copy text at `lite-review.py:24-26`, and the linked decisions 030/031 and log 37

**Location:** `docs/decisions/log.md:69`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and content of the four cited artifacts (`cb5351d`, `lite-review.py:24-26` at the parent commit, `030`, `031`, log 37); does not establish that the WARNING's behavior is correct, nor that the judge pin resolves on OpenRouter (untestable here — no funded OpenRouter account).

`cb5351d` exists and is the commit that added the pre-flight warning:

```
# git log -1 --format="%h %s" cb5351d
cb5351d fix(cross-model-review): warn pre-flight on an unpriced judge; title the reference files
```

and it introduced exactly the WARNING row 48 describes:

```python
# git show cb5351d, added hunk
        if pricing and pricing.get(args.judge, (0, 0)) == (0, 0):
            print(f"WARNING: no pricing for judge {args.judge} — unknown or unpriced model id. "
```

The `lite-review.py:24-26` citation is exact for the state row 48 was written against: the
`435f46a` hunk header is `@@ -21,9 +21,14 @@` with three context lines, so the removed
copy-description occupied old lines 24, 25 and 26 (paraphrased — no quote available because the
claim is about line *numbering* in a prior revision, which is a property of the diff header
rather than of any quotable line).

Both linked decision records exist:

```
# ls
docs/decisions/030-lightweight-review-path.md
docs/decisions/031-review-loop-tier-and-factcheck-policy.md
```

Log 37 exists at `docs/decisions/log.md:59` and itself states `Wired into pr-prep Step 3 /
review-fix-loop.md`.

**Evidence:** `docs/decisions/log.md:59`, `docs/decisions/log.md:69`, `docs/decisions/030-lightweight-review-path.md`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md`, `scripts/cross-model-review.py:378`

---

## Claim 3: "a Sonnet 5 pass is `--model claude-sonnet-5`, not new code" / "a flag, not a build"

**Location:** `docs/decisions/log.md:69`, `docs/working/questions.md:11`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `--model` is plumbed unvalidated to the `claude` CLI and that the literal string `claude-sonnet-5` resolves to a real first-party model on this machine; does not establish that a full lite-review run under that model produces parseable FINDINGS output, nor that the id remains valid on a host with different CLI/auth state.

The plumbing is end-to-end and unvalidated — `argparse` takes any string and it reaches the
subprocess argv directly:

```python
# scripts/lite-review.py:141
    ap.add_argument("--model", default=DEFAULT_MODEL)
```

```python
# scripts/lite-review.py:160
    env = run_claude(prompt, args.model, args.timeout)
```

```python
# scripts/lite-review.py:113-126
    with tempfile.TemporaryDirectory(prefix="lite-review-") as empty_cwd:
        proc = subprocess.run(
            [
                "claude", "-p",
                "--model", model,
                "--output-format", "json",
                ...
```

(excerpt ends `:126`; the enclosing `run_claude` continues to `:132` — read: the remainder
decodes `proc.stdout` as JSON and `sys.exit`s with the raw output when decoding fails, so an
invalid model id would surface as a non-JSON exit rather than a validation error.)

There is no `choices=` constraint and no allowlist check on the value, so the gap the brief asks
about — "a flag exists" vs "this specific value works" — was closed by execution. Command:
`claude -p --model claude-sonnet-5 --output-format json --tools "" --no-session-persistence <<< "say hi"`,
cwd `/workspace`, exit code 0, at 2026-09-12T12:19:29-07:00. The envelope reports
`"canonicalModel":"claude-sonnet-5"`, `"provider":"firstParty"`, `"is_error":false`,
`"num_turns":1` — the two fields `lite-review.py` judges success by. The id resolves.

**Evidence:** `scripts/lite-review.py:113-132`, `scripts/lite-review.py:141`, `scripts/lite-review.py:160`, `docs/reviews/execution-logs/r2-claude-sonnet-5-resolve.txt`

---

## Claim 4a: log row 49 — "The two regexes were byte-identical at the moment ownership moved"

**Location:** `docs/decisions/log.md:70`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `FINDING_RE`'s compiled pattern string and flags in the two files at `435f46a`; does not establish that the two files' *parsers* agree (they do not — see Claim 4b) or that the two prompts elicit the same output.

The two compiled objects are identical in both pattern and flags. Command:
`python3` inline script loading both modules by path and comparing
`FINDING_RE.pattern` / `FINDING_RE.flags`, cwd `/workspace`, exit code 0, at
2026-09-12T12:19:29-07:00:

```
regex pattern identical: True | flags identical: True
```

The source text is likewise identical apart from the surrounding blank line:

```python
# scripts/lite-review.py:73-78 and scripts/cross-model-review.py:139-144 (identical)
FINDING_RE = re.compile(
    r"^\s*\d+\.\s*(?P<path>[^|:]+?)(?::(?P<lines>[\d\-, ]+))?\s*\|"
    r"\s*(?P<sev>Critical|High|Medium|Low|Informational)\s*\|"
    r"\s*(?P<domain>[^|]+)\|\s*(?P<title>[^|]+)\|\s*(?P<desc>.+)$",
    re.IGNORECASE,
)
```

The two prompt templates' format lines also agree (`FINDINGS:` / the numbered row /
`(or the single line "FINDINGS: NONE"). Nothing after the list.`) at
`scripts/lite-review.py:51-54` and `scripts/cross-model-review.py:121-124`.

**Evidence:** `scripts/lite-review.py:73-78`, `scripts/cross-model-review.py:139-144`, `scripts/lite-review.py:51-54`, `scripts/cross-model-review.py:121-124`, `docs/reviews/execution-logs/r2-parser-divergence.txt`

---

## Claim 4b: "This file OWNS the FINDINGS **grammar** and its regex" / "the two were byte-identical when ownership moved here"

**Location:** `scripts/lite-review.py:24-31`, restated at `docs/decisions/log.md:70`
**Type:** Architectural / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what constitutes "the grammar" beyond `FINDING_RE` — the block-header detection, the `FINDINGS: NONE` short-circuit, and the `parse_ok` contract — across both files; does not establish which behavior is the intended one, nor whether the divergence predates this diff (it does; this diff did not create it).

`FINDING_RE` is byte-identical (Claim 4a) and the prompt format lines agree, but the rest of the
grammar — everything in `parse_findings` other than the row regex — has already diverged in three
observable ways. The two implementations, read complete:

```python
# scripts/lite-review.py:86-108 (complete function)
def parse_findings(text):
    """Parse the FINDINGS block; returns (findings, parse_ok)."""
    if re.search(r"FINDINGS:\s*NONE", text):
        return [], True
    rows = []
    in_block = False
    for line in text.splitlines():
        if line.strip().startswith("FINDINGS:"):
            in_block = True
            continue
        ...
    return rows, bool(rows) or "FINDINGS" in text
```

```python
# scripts/cross-model-review.py:300-322 (complete function)
def parse_findings(text):
    """Parse the FINDINGS block; returns (findings, parse_ok)."""
    if re.search(r"FINDINGS:\s*NONE", text, re.IGNORECASE):
        return [], True
    ...
        if re.match(r"\s*FINDINGS\s*:", line):
    ...
    return rows, in_block or bool(rows)
```

Executed differential. Command: `python3` inline script loading both modules and calling both
`parse_findings` on three inputs, cwd `/workspace`, exit code 0, at 2026-09-12T12:19:29-07:00:

```
--- 'lowercase none'          ("findings: none")
  lite : ([], False)          cross: ([], True)
--- 'space before colon'      ("FINDINGS :\n1. a.py:1 | High | d | T | D")
  lite : ([], True)           cross: ([{...one row...}], True)
--- 'substring only'          ("I cannot emit FINDINGS for this diff.")
  lite : ([], True)           cross: ([], False)
```

The third case is the operationally significant one: `lite-review.py`'s `parse_ok` returns True
for any text containing the substring `FINDINGS` anywhere, including a refusal that never emitted
a block — the exact "no rows read as clean" hazard `test/lite-review-grammar.bats:80-87` says the
grammar must prevent. The header's claim is true of the regex and of the on-the-wire row format;
it is imprecise about "the grammar" as a whole. The precise version: *the two `FINDING_RE`
definitions were byte-identical when ownership moved; the surrounding parsers already differ in
`FINDINGS: NONE` case-sensitivity, block-header tolerance, and `parse_ok` semantics.*

**Evidence:** `scripts/lite-review.py:24-31`, `scripts/lite-review.py:86-108`, `scripts/cross-model-review.py:300-322`, `docs/decisions/log.md:70`, `docs/reviews/execution-logs/r2-parser-divergence.txt`

---

## Claim 5: "test/lite-review-grammar.bats pins the shape" (lite-review.py header) / "pins the shape with 7 contract tests over `parse_findings`" (log row 49)

**Location:** `scripts/lite-review.py:30-31`, `docs/decisions/log.md:70`, `test/lite-review-grammar.bats:6-10`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the 7 tests constrain and what a contract-altering `FINDING_RE` edit can change while still passing; does not establish that the untested regions matter in practice, nor that any specific future edit is likely.

The suite exists, has exactly 7 tests, and passes. Command: `bats test/lite-review-grammar.bats`,
cwd `/workspace`, exit code 0, at 2026-09-12T12:16:00-07:00 — `1..7`, all `ok`.

It constrains `parse_findings`' *behavior*, and through it several regex properties: field
decomposition (`"path"`/`"lines"` split, `"severity"`, `"domain"`, `"title"`, `"description"`),
case-insensitive severity matching with `.capitalize()` normalization, the optional line range,
block-header detection, and the parse-failure distinction. No test reads `FINDING_RE` itself
(paraphrased — no quote available because the claim covers the *absence* of a reference: `grep -n
FINDING_RE test/lite-review-grammar.bats` returns nothing).

Mutation probe: two contract-altering edits to `FINDING_RE` both pass all 7 tests. Command:
`bats test/lite-review-grammar.bats` in a copied tree whose `scripts/lite-review.py` had the
severity alternation widened to include `Blocker` and the line-range class narrowed from
`[\d\-, ]+` to `[\d\-]+`, cwd
`/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/mut`, exit code 0,
at 2026-09-12T12:19:46-07:00 — `1..7`, all `ok`. The second mutation silently drops
comma-separated line lists (`1. a.py:12, 40 | ...`), which the shipped grammar admits.

Precise version: the suite pins `parse_findings`' behavior on seven sampled inputs, which is
what protects the caller contract; it does not pin the regex, so the severity vocabulary and the
line-range character class can change without a red test. Prompt/regex drift is also unpinned —
no test asserts `PROMPT_FULL`'s format line matches `FINDING_RE`.

**Evidence:** `test/lite-review-grammar.bats:1-97`, `scripts/lite-review.py:73-78`, `docs/reviews/execution-logs/r2-lite-review-grammar.txt`, `docs/reviews/execution-logs/r2-mutation-probe.txt`

---

## Claim 6: "the exit status alone does not discriminate (both old and new behavior exit 1), so the message is the assertion that has teeth"

**Location:** `docs/working/questions.md:7`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit status and stdout of `install.sh` on a closed stdin at `8980861~1` and at `HEAD`; does not establish anything about other non-interactive callers (e.g. `--yes`) or about stderr content.

Pre-fix run: exit 1, output ends at the prompt with no abort line (command, cwd, timestamp and
captured output in Claim 1). Post-fix: the shipped test asserts both `[ "$status" -eq 1 ]` and
the `Aborted. Nothing was changed.` line and passes (Claim 14). A minimal synthetic pair
confirmed the same shape independently. Command:
`bash t.sh </dev/null` (old form) and `bash t2.sh </dev/null` (new form), cwd
`/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad`, exit codes 1 and 1,
at 2026-09-12T12:15-07:00:

```
OLD:  prompt? [y/N]   status=1
NEW:  prompt? [y/N] Aborted.
        status=1
```

Both exit 1; only the new form prints. The claim's mechanism and conclusion both hold.

**Evidence:** `docs/working/questions.md:7`, `devcontainer-config/install.sh:101-110`, `docs/reviews/execution-logs/r2-old-install-behavior.txt`

---

## Claim 7: "The only consumers of the pin are the benchmark harness `scripts/cross-model-review.py` and the archival `scripts/dd-cross-model-sweep.py`"

**Location:** `docs/working/questions.md:11`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which `.py`/`.sh` files contain the literal pin `anthropic/claude-sonnet-5`; does not establish the conclusion the sentence draws from the enumeration ("neither on the production path"), which holds independently — none of the three real consumers is on the live review path.

Enumerated rather than sampled. `grep -rn "anthropic/claude-sonnet-5" --include="*.py" --include="*.sh"`
finds three code sites, not two:

```python
# scripts/cross-model-review.py:378
    ap.add_argument("--judge", default="anthropic/claude-sonnet-5", help="pinned judge model for stage-2 matching")
```

```python
# archive/benchmark/scripts/review-arms.py:69,73
    "base": {"model": "anthropic/claude-sonnet-5", "replicates": 1, "consensus": None,
    "k3": {"model": "anthropic/claude-sonnet-5", "replicates": 3, "consensus": 2,
```

Two errors in one sentence. (a) `archive/benchmark/scripts/review-arms.py` is an unnamed third
consumer — two sites — and it is a wrapper *over* the harness, so it would follow the harness to
the fork:

```python
# archive/benchmark/scripts/review-arms.py:2
"""Named lightweight-review arm set (decision 030) over cross-model-review.py.
```

(b) `scripts/dd-cross-model-sweep.py` is **not** a consumer of the pin at all. It contains no
`anthropic/` slug and no judge concept; its model list is:

```python
# scripts/dd-cross-model-sweep.py:30
MODELS = ["moonshotai/kimi-k3", "openai/gpt-5.6-sol", "google/gemini-3.1-pro-preview"]
```

A reader acting on this enumeration — to retire the pin, re-slug it, or check what breaks if
`anthropic/claude-sonnet-5` is wrong — would edit a file that never references it and miss the
one that references it twice. The conclusion ("neither on the production path") survives: all
three sites are benchmark/archive, none is reached by `lite-review.py`. Log row 48's
parallel sentence is *not* affected — it says the two scripts "stay frozen and are not to be run
from here", which is a directive about the scripts, not a claim about the pin.

**Evidence:** `docs/working/questions.md:11`, `scripts/cross-model-review.py:378`, `archive/benchmark/scripts/review-arms.py:2`, `archive/benchmark/scripts/review-arms.py:69`, `archive/benchmark/scripts/review-arms.py:73`, `scripts/dd-cross-model-sweep.py:30`

---

## Claim 8: "the production diff-only review already runs on the Claude subscription via `scripts/lite-review.py` (decision log 37, wired into `workflows/pr-prep.md` Step 3 and `workflows/review-fix-loop.md`)"

**Location:** `docs/working/questions.md:11`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `lite-review.py` is invoked from both named workflow files and that the pr-prep invocation sits inside the numbered step 3; does **not** establish that the `--mode full` review is wired anywhere — both workflow call sites invoke `--mode fix-drift` only, and `--mode full` appears in no workflow, so "the production diff-only review" is wired in its fix-drift form alone, with full-mode reachable only as a manual CLI entry point.

Both files invoke it. In `pr-prep.md` the invocation sits under the heading `#### 3. Review-fix
loop` (`workflows/pr-prep.md:148`), inside the `c. Run tests` → drift-check subsection:

```bash
# workflows/pr-prep.md:218
python3 scripts/lite-review.py --repo . --range <last-review-commit>..HEAD --mode fix-drift
```

```
# workflows/review-fix-loop.md:69
`scripts/lite-review.py --mode fix-drift` over the fix commits before starting the next
```

The subscription half is stated by the script itself and matches its argv (Claim 3): it calls
`claude -p` and deliberately omits `--bare`:

```python
# scripts/lite-review.py:17-19
- NOT --bare: --bare restricts auth to ANTHROPIC_API_KEY and never reads
  OAuth, which defeats the whole point (subscription auth). Instead the call
  minimizes context with --system-prompt (replaces the default harness
```

Log 37 corroborates the wiring in the same words (`docs/decisions/log.md:59`: "Wired into
pr-prep Step 3 / review-fix-loop.md"). `--mode full` is the argparse default
(`scripts/lite-review.py:140`) but appears in no workflow file (paraphrased — no quote available
because the claim covers the absence of a call site: `grep -rn "mode full" workflows/` returns
nothing).

**Evidence:** `docs/working/questions.md:11`, `workflows/pr-prep.md:148`, `workflows/pr-prep.md:218`, `workflows/review-fix-loop.md:69`, `scripts/lite-review.py:17-19`, `scripts/lite-review.py:140`, `docs/decisions/log.md:59`

---

## Claim 9: "churn across 19 links at 17 sites for a saving that lands on one path"

**Location:** `docs/working/questions.md:9`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the link count reproduced by A10's own stated method (links into `references/` from `skills/code-review/SKILL.md`) at `435f46a`; does not establish the count at the moment A10 was written, nor the "saving lands on one path" half, which is an architecture judgement rather than a checkable figure.

Compared against the logged hallucination pattern *"a specific measured value quoted from a
checked-in artifact set that does not contain it"* (first seen 2026-08-18) — this is the same
shape, so it was recounted rather than accepted. The figure is a restatement of A10, whose method
is stated in the source:

```
# docs/reviews/architecture-review-2026-09-12.md:35
edge set is denser: SKILL.md carries **19 links into `references/`** from 17 distinct sites
```

Reproducing that method today gives 21, not 19 (paraphrased — no quote available because the
claim is a count: `grep -o "references/[a-z-]*\.md[^)\" ]*" skills/code-review/SKILL.md | wc -l`
→ 21, over 21 distinct lines). The magnitude and the conclusion it supports (re-cutting the split
is real churn across ~20 call sites) are unaffected; the precise version is *21 links from 21
sites as of `435f46a`*, or the figure should be attributed as A10's snapshot. Note that the
narrower reading — links carrying a `rubric.md#` anchor — gives 11, so the sentence is only true
under A10's broader "links into `references/`" reading.

**Evidence:** `docs/working/questions.md:9`, `docs/reviews/architecture-review-2026-09-12.md:35`, `docs/reviews/code-review-rubric-2026-09-12-main-prompt-audit.md:30`, `skills/code-review/SKILL.md`

---

## Claim 10: "The FINDINGS grammar is DEFINED by scripts/lite-review.py (decision log 48); this is the copy. It was byte-identical when ownership moved."

**Location:** `scripts/cross-model-review.py:135-138`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment's referent — the `FINDING_RE` definition it is attached to — and the existence of decision log row 48; does not establish that `cross-model-review.py`'s `parse_findings` is a copy of lite-review's (it is not — see Claim 4b), and the comment does not claim it is.

The comment sits immediately above `FINDING_RE`, so "this" resolves to the regex, which is
byte-identical (Claim 4a, executed):

```python
# scripts/cross-model-review.py:135-140
# The FINDINGS grammar is DEFINED by scripts/lite-review.py (decision log 48);
# this is the copy. It was byte-identical when ownership moved. If this harness
# moves to the SWRBench fork, keep it in step with the owner deliberately or
# state in the fork that the two have diverged - do not silently re-fork it.
FINDING_RE = re.compile(
    r"^\s*\d+\.\s*(?P<path>[^|:]+?)(?::(?P<lines>[\d\-, ]+))?\s*\|"
```

(excerpt ends `:140`; the enclosing `re.compile(...)` call continues to `:145` — read: the
remaining pattern fragments and the `re.IGNORECASE` flag were included in the executed
comparison.) Decision log row 48 exists at `docs/decisions/log.md:69` and asserts the same
ownership. The trailing sentences are forward-looking instructions to the fork, not checkable
claims.

**Evidence:** `scripts/cross-model-review.py:135-145`, `scripts/lite-review.py:73-78`, `docs/decisions/log.md:69`, `docs/reviews/execution-logs/r2-parser-divergence.txt`

---

## Claim 11: "Changing the grammar here breaks that comparability" / "output stays comparable with the E2/E3 lite-arm artifacts"

**Location:** `scripts/lite-review.py:26-30`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the attempt to trace the E2/E3 lite-arm artifacts to a producer whose output shape depends on this regex; does not establish that the claim is false — only that the artifact set needed to confirm or refute it was not identifiable in-repo within this pass.

The comparability claim is about historical benchmark artifacts, not about code in this repo. The
`runs/review-arms/` and `runs/cross-model/` trees contain artifacts produced by the OpenRouter
harness (paraphrased — no quote available because the claim concerns which *producer* wrote a
directory of checked-in JSON, which is not recorded in the files themselves in a form this pass
could quote). Confirming that a regex change would break comparison against the E2/E3 lite arm
specifically requires the E2/E3 experiment definition and its arm-to-script mapping, which lives
in the benchmark material scoped out of this repo (memory: SWRBench work is a separate fork).
What would be needed: the E2/E3 arm manifest naming which script produced the lite-arm rows, plus
the rows themselves, to re-parse under a mutated regex and observe the delta.

**Evidence:** `scripts/lite-review.py:26-30`, `docs/decisions/log.md:70`

---

## Claim 12: "An EOF stdin must decline *and say so*: before `read -r reply || reply=\"\"`, errexit killed the script at the prompt and this line never printed."

**Location:** `test/cc-isolated-functions.bats:483-484`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the truth of the historical statement about the pre-fix script and the discriminating power of the `Aborted. Nothing was changed.` assertion the comment introduces; does **not** establish that the assertion on the next line, `[ "$status" -eq 1 ]`, discriminates — it does not, and the comment sits directly above it, so a reader could take the status check as the new teeth.

The comment's factual content — errexit killed the script at the prompt and the abort line never
printed — was confirmed by running the pre-fix script (Claim 1: exit 1, output ends at
`Install this config and bless it? [y/N] ` with no abort line). The complete assertion block it
annotates:

```bash
# test/cc-isolated-functions.bats:474-490 (complete @test body)
@test "install.sh assembles the payload when every source is present" {
  # Complement of the two above: proves the guard is not firing wholesale.
  # Stdin is closed, so the run declines at the bless prompt — reaching that
  # prompt is the marker that assembly got all the way past the guard.
  root=$(fake_install_repo)
  run env CLAUDE_DEVC_CONFIG_DIR="$BATS_TEST_TMPDIR/nodest" \
      bash "$root/devcontainer-config/install.sh" </dev/null
  [[ "$output" != *'payload source(s) not found'* ]]
  [[ "$output" == *'bless it?'* ]]
  # An EOF stdin must decline *and say so*: before `read -r reply || reply=""`,
  # errexit killed the script at the prompt and this line never printed.
  [ "$status" -eq 1 ]
  [[ "$output" == *'Aborted. Nothing was changed.'* ]]
  [ -e "$root/devcontainer-config/claude-home/CLAUDE.md" ]
  [ -d "$root/devcontainer-config/claude-home/skills" ]
}
```

(the `@test` body is complete — read; the two trailing filesystem assertions pass under both old
and new behavior because the payload is staged before the prompt, which is what the pre-existing
"reaching that prompt is the marker" comment describes.)

Of the two assertions the comment introduces, only the second discriminates: the pre-fix run also
exited 1, so `[ "$status" -eq 1 ]` would have passed against the old code. The comment's wording
("this line never printed") is true of the output assertion, and the commit message for `8980861`
makes the same point explicitly — so the claim is accurate; the placement is the residue noted in
`Scope`.

**Evidence:** `test/cc-isolated-functions.bats:474-490`, `devcontainer-config/install.sh:101-110`, `docs/reviews/execution-logs/r2-old-install-behavior.txt`, `docs/reviews/execution-logs/r2-install-sh-tests.txt`

---

## Claim 13: "nothing but this file holds the shape in place once the harness leaves" / "Keyless and offline throughout: parse_findings() is pure, so no `claude` call."

**Location:** `test/lite-review-grammar.bats:6-12`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that no other test file exercises this grammar and that the suite ran to completion with no API key in the environment and no network call; does not establish that the shape it holds is complete (Claim 5 shows it is not) nor that `lite-review.py`'s module-level import is free of side effects beyond the constants and function definitions read.

No other test touches the grammar: `grep -rln "parse_findings\|FINDING_RE\|FINDINGS" test/` returns
`test/lite-review-grammar.bats`, `test/skills/helpers.bash` and
`test/skills/architecture-review-format.bats`, and the latter two match on an unrelated symbol —
the skills' report-section heading, not this parser:

```bash
# test/skills/helpers.bash:71
  FINDINGS_BODY=$(echo "$REPORT_CONTENT" | sed -nE '/^## Findings/,/^## [^#]/p' | sed '1d;$d')
```

Purity: `parse_findings` performs no I/O (complete function quoted at Claim 4b), and the module's
only executable top level is imports and constants — the entry point is guarded:

```python
# scripts/lite-review.py:208-209
if __name__ == "__main__":
    sys.exit(main())
```

Executed keyless: `env | grep -c ANTHROPIC_API_KEY` → 0, and the suite passed. Command:
`bats test/lite-review-grammar.bats`, cwd `/workspace`, exit code 0, at
2026-09-12T12:16:00-07:00 — `1..7`, all `ok`.

**Evidence:** `test/lite-review-grammar.bats:1-12`, `test/skills/helpers.bash:71`, `scripts/lite-review.py:86-108`, `scripts/lite-review.py:208-209`, `docs/reviews/execution-logs/r2-lite-review-grammar.txt`

---

## Claim 14: commit `8980861` — "All 5 install.sh tests pass"

**Location:** commit message `8980861`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and pass state of the bats tests whose names contain `install.sh` at `435f46a` (HEAD), on this machine; does not establish the state at `8980861` itself, nor that five is the complete set of tests exercising `install.sh` behavior indirectly.

Command: `bats -f "install.sh" test/cc-isolated-functions.bats`, cwd `/workspace`, exit code 0, at
2026-09-12T12:16:17-07:00. Exactly five tests, all passing:

```
1..5
ok 1 install.sh stages the payload from the repo root
ok 2 install.sh aborts when a payload source is missing
ok 3 install.sh names every missing payload source, not just the first
ok 4 install.sh assembles the payload when every source is present
ok 5 every regular file in install.sh's PAYLOAD is hashed by enforcement_files
```

Compared against the logged hallucination pattern *"'All 85 tests across the code-review suites
pass' claimed in commit 59ca38f … but the suites hold 97"* (first seen 2026-09-12) — same class
(a test-count denominator in a commit message). Recounted; this one holds.

The accompanying sentence "verified both behaviors directly before writing it" is a claim about
the author's process, not about code — not checkable here; the *behaviors* it refers to were
independently confirmed under Claims 1 and 6.

**Evidence:** `test/cc-isolated-functions.bats:420-490`, `docs/reviews/execution-logs/r2-install-sh-tests.txt`

---

## Claim 15: commit `435f46a` — "Fast suite: 623 passed, 0 failed" and "7 contract tests over parse_findings, keyless and offline since the parser is pure"

**Location:** commit message `435f46a`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fast-category suite's total and failure count and the new file's test count at `435f46a` on this machine; does not establish the slow-category suite's state (not run) nor that 623 was the count at the moment the message was written.

Command: `scripts/run-tests.sh --fast`, cwd `/workspace`, exit code 0, at
2026-09-12T12:16:40-07:00. The TAP plan is `1..623`; `grep -cE "^(ok|not ok) "` → 623 and
`grep -c "^not ok"` → 0. The new file is included in that run (`grep -c lite-review-grammar` → 1
on the captured log) and contributes exactly 7 (Claim 13). Both numeric claims reproduce exactly.

Compared against the same logged hallucination pattern as Claim 14; both denominators verified
rather than accepted.

The "keyless and offline" half is verified under Claim 13; "pins the shape" is verdicted
separately at Claim 5 (Mostly accurate).

**Evidence:** `scripts/run-tests.sh`, `test/lite-review-grammar.bats:1-97`, `docs/reviews/execution-logs/r2-fast-suite.txt`, `docs/reviews/execution-logs/r2-lite-review-grammar.txt`

---

## Claim 16: commit `435f46a` — "questions.md now has no open entries"

**Location:** commit message `435f46a`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unchecked checkbox entries (`- [ ]`) in `docs/working/questions.md` at `435f46a`; does not establish that every closed entry's answer is correct (Claim 7 shows one is not), nor that no open question exists elsewhere in `docs/working/`.

Command: `grep -c "^- \[ \]" docs/working/questions.md`, cwd `/workspace`, exit code 1 (grep's
no-match status), at 2026-09-12T12:20-07:00, output `0`. All eight entries are `- [x]`
(`docs/working/questions.md:6-13`).

**Evidence:** `docs/working/questions.md:6-13`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`docs/working/questions.md:11`): the pin's consumer enumeration is wrong in both directions — `scripts/dd-cross-model-sweep.py` does not reference `anthropic/claude-sonnet-5` at all (its `MODELS` list is kimi/gpt/gemini, no judge), and `archive/benchmark/scripts/review-arms.py:69,73` is an unnamed third consumer. Fix: replace "the archival `scripts/dd-cross-model-sweep.py`" with "the archived arm-set wrapper `archive/benchmark/scripts/review-arms.py`", or reword to "the only OpenRouter callers", which is what the surrounding argument actually needs. The conclusion ("neither on the production path") is unaffected.

### Stale
- None.

### Mostly Accurate
- **Claim 4b** (`scripts/lite-review.py:24-31`, `docs/decisions/log.md:70`): "the two were byte-identical" is true of `FINDING_RE` but not of the grammar as a whole — the two `parse_findings` already differ on `FINDINGS: NONE` case-sensitivity, `FINDINGS :` block-header tolerance, and `parse_ok` semantics (lite returns `parse_ok=True` for any text containing the substring `FINDINGS`, including a refusal that emitted no block). Tighten to "the two `FINDING_RE` definitions were byte-identical; the surrounding parsers already differ."
- **Claim 5** (`scripts/lite-review.py:30-31`, `docs/decisions/log.md:70`): "pins the shape" overstates — the suite pins `parse_findings`' behavior on seven sampled inputs and never reads `FINDING_RE`; a demonstrated mutation (severity set widened, line-range class narrowed to drop comma lists) passes all 7. Tighten to "pins the parser's behavior" and, if the regex is meant to be held, add a test that asserts on `FINDING_RE` or on a comma-separated line range.
- **Claim 9** (`docs/working/questions.md:9`): "19 links at 17 sites" is A10's 2026-09-12 snapshot; the same method gives 21 links from 21 sites at `435f46a`. Attribute the figure to A10 or restate it.

### Unverifiable
- **Claim 11** (`scripts/lite-review.py:26-30`): the E2/E3 lite-arm comparability invariant needs the E2/E3 arm manifest (which script produced the lite-arm rows) plus those rows, to re-parse under a mutated regex and observe the delta. That material is benchmark-side and scoped to the SWRBench fork.

### Routing note
None of the Incorrect or Mostly-accurate findings lands on an immutable already-merged commit
message: Claim 7 is in `docs/working/questions.md` (editable), Claims 4b/5 are in
`scripts/lite-review.py`, `docs/decisions/log.md` and `test/lite-review-grammar.bats` (editable),
Claim 9 is in `docs/working/questions.md` (editable). The commit-message claims checked here
(Claims 14, 15, 16) all verified, so no override-log routing is required. Note that `435f46a`'s
message repeats the Claim 5 wording ("pins the shape") and `docs/decisions/log.md:70` repeats it
in a mutable file — fixing the log row is sufficient; the commit message stays as shipped.

### Legibility targets
- Claim 1 — for-author
- Claim 2 — for-orchestrator-synthesis
- Claim 3 — for-author
- Claim 4a — for-automated-gate
- Claim 4b — for-author
- Claim 5 — for-author
- Claim 6 — for-orchestrator-synthesis
- Claim 7 — for-author
- Claim 8 — for-orchestrator-synthesis
- Claim 9 — for-author
- Claim 10 — for-orchestrator-synthesis
- Claim 11 — for-orchestrator-synthesis
- Claim 12 — for-author
- Claim 13 — for-automated-gate
- Claim 14 — for-automated-gate
- Claim 15 — for-automated-gate
- Claim 16 — for-automated-gate

---

## Goal-Alignment Note

**Answered.** The user's goal — review the last three commits on main before the work is
considered settled — is served by this pass on the fact-check dimension. Every claim the brief
named was checked; eleven verified (six by execution), three tightened, one refuted, one left
Unverifiable with the specific missing artifact named. The one refutation (Claim 7) is a
documentation error inside a closed question entry, not a code defect: the argument that closed
Q6 survives it, because all three real consumers of the pin are benchmark/archive code and none
is on the production review path. The grammar-ownership move (`435f46a`) is sound at the level it
claims — `FINDING_RE` is byte-identical and the test suite is real, keyless and green — but two
of its supporting claims overstate: "the grammar" is broader than the regex and the two files'
parsers have already diverged, and the new suite pins the parser's behavior rather than the
regex.

**Out of scope.** Whether the parser divergence between `lite-review.py` and
`cross-model-review.py` *should* be reconciled, whether the `parse_ok` substring check is a bug,
and whether the missing regex-level test is worth adding — all code-quality judgements belonging
to `api-consistency-reviewer` / `architecture-review` / `test-strategy`, not to this pass. Also
out of scope: whether `anthropic/claude-sonnet-5` resolves on OpenRouter (untestable — no funded
account), which row 48 deliberately leaves unverified.

**Escalate.** One item for the orchestrator: Claim 4b's executed differential shows
`lite-review.py`'s `parse_findings` returns `parse_ok=True` for model output that contains the
word `FINDINGS` but emitted no block — the exact failure mode
`test/lite-review-grammar.bats:80-87` exists to detect, and the live review path is the consumer.
That is a behavioral divergence a critic should look at on its merits; this pass records only
that the header's identity claim does not cover it.

**Questions I would have asked.** (1) Was `scripts/dd-cross-model-sweep.py` named in Q6 because
it calls OpenRouter, rather than because it uses the pin? If so, the sentence needs "OpenRouter
callers", not "consumers of the pin", and `archive/benchmark/scripts/review-arms.py` should
still be listed. (2) Is the E2/E3 lite-arm comparability invariant meant to bind
`parse_findings` as well as `FINDING_RE`? The answer determines whether Claim 4b's divergence is
a latent comparability break or an intended difference.
