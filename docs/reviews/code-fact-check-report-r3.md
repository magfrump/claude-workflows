# Code Fact-Check Report

Commit: 435f46a

**Repository:** /workspace
**Scope:** `git diff 3a94fdc~1..HEAD` — 3 commits (3a94fdc, 8980861, 435f46a) across `devcontainer-config/install.sh`, `docs/decisions/log.md`, `docs/working/questions.md`, `scripts/cross-model-review.py`, `scripts/lite-review.py`, `test/cc-isolated-functions.bats`, `test/lite-review-grammar.bats`, plus the three commit messages
**Checked:** 2026-09-12
**Total claims checked:** 17
**Summary:** 12 verified, 2 mostly accurate, 0 stale, 1 incorrect, 2 unverifiable

Pre-run check against `docs/reviews/hallucination-patterns.md`: the three logged
patterns are all of one class — *a specific measured value quoted from a checked-in
artifact set that does not contain it*. Two claims in this diff are of that class and
are flagged against it explicitly: Claim 12 ("19 links at 17 sites", Unverifiable) and
Claim 16 ("Fast suite: 623 passed", Verified by execution).

---

## Claim 1: "`|| reply=\"\"` so a closed/EOF stdin (piped or non-tty run) falls through to the abort case below instead of dying on `read`'s non-zero exit under `set -e`, which killed the script before it could say why."

**Location:** `devcontainer-config/install.sh:103-105`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both halves — the pre-change EOF behavior (script dies at `read`, abort line never printed) and the post-change behavior (falls into the `*)` case, prints, exits 1) — for a closed-stdin, no-`--yes`, first-install run; does not establish behavior when stdin is an open tty that later closes mid-read, when `--yes` is passed (the whole block is skipped), or for the non-EOF read-error cases (`read` returning non-zero for a reason other than EOF).

The enclosing block is read to its end. `set -euo pipefail` is in force at
`devcontainer-config/install.sh:16`:

```bash
# devcontainer-config/install.sh:16
set -euo pipefail
```

The complete `if` block, signature to final line:

```bash
# devcontainer-config/install.sh:101-111
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

(excerpt covers the whole `if`; the next statement at `:113` is `mkdir -p "$DEST" "$BIN_DIR"` — read, and it is unreachable on the EOF path because the `*)` arm `exit 1`s.)

Executed A/B reproduction. Two clean `git archive HEAD` extracts were made; in one
the three comment lines and `|| reply=""` were reverted to bare `read -r reply`.
Both were run with `</dev/null` and a nonexistent `CLAUDE_DEVC_CONFIG_DIR`:

- command: `bash devcontainer-config/install.sh </dev/null` with
  `CLAUDE_DEVC_CONFIG_DIR=<scratch>/<variant>-nodest CLAUDE_DEVC_BIN_DIR=<scratch>/<variant>-bin`
- cwd: `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/iv/{old,new}`
- timestamp: 2026-09-12
- old variant: exit code 1, output ends at `Install this config and bless it? [y/N] ` —
  zero occurrences of `Aborted. Nothing was changed.`
- new variant: exit code 1, output ends `Install this config and bless it? [y/N] Aborted. Nothing was changed.` —
  one occurrence

**Evidence:** `devcontainer-config/install.sh:16`, `devcontainer-config/install.sh:101-113`, `docs/reviews/execution-logs/r3-install-eof-old-vs-new.txt`

---

## Claim 2: "a Sonnet 5 pass is `--model claude-sonnet-5`, not new code" (decision log row 48) / "a Sonnet 5 pass there is `--model claude-sonnet-5`, a flag, not a build" (questions.md Q6)

The compound splits: the flag's existence and end-to-end plumbing earns a different
verdict from the specific value resolving.

### Claim 2a: a `--model` flag exists on `lite-review.py` and its value reaches the `claude` invocation without requiring code changes

**Location:** `docs/decisions/log.md:69`, `docs/working/questions.md:11`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `--model` is parsed, defaulted, and passed verbatim as `claude --model <value>` with no code change required; does not establish that any particular value is accepted by the `claude` CLI, nor that `lite-review.py` surfaces a bad model id as anything other than a generic envelope/JSON-decode failure.

The flag is declared with a pinned Haiku default:

```python
# scripts/lite-review.py:41
DEFAULT_MODEL = "claude-haiku-4-5-20251001"
```

```python
# scripts/lite-review.py:141
    ap.add_argument("--model", default=DEFAULT_MODEL)
```

It is threaded straight through `main()` into `run_claude` and onto the argv with no
validation, normalization, or allowlist anywhere in between:

```python
# scripts/lite-review.py:160
    env = run_claude(prompt, args.model, args.timeout)
```

```python
# scripts/lite-review.py:111-126
def run_claude(prompt, model, timeout_s):
    """One headless subscription call; returns the decoded JSON envelope."""
    with tempfile.TemporaryDirectory(prefix="lite-review-") as empty_cwd:
        proc = subprocess.run(
            [
                "claude", "-p",
                "--model", model,
                ...
```

(excerpt ends `:118`; the enclosing `run_claude` continues to `:132` with the
`json.loads(proc.stdout)` / `JSONDecodeError` → `sys.exit` tail — read, and it
contains no model validation either.)

**Evidence:** `scripts/lite-review.py:41`, `scripts/lite-review.py:111-132`, `scripts/lite-review.py:141`, `scripts/lite-review.py:160`

### Claim 2b: `claude-sonnet-5` is a value that would actually resolve

**Location:** `docs/decisions/log.md:69`, `docs/working/questions.md:11`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the literal string `claude-sonnet-5` is corroborated anywhere in this repo as a Claude-CLI model id; does not establish that it is invalid — only that nothing in-repo and nothing runnable here confirms it.

Blocker: resolving a model alias requires a live `claude -p` call, and this sandbox
has no egress (an execution the mandatory-execution rule would otherwise require).
The string `claude-sonnet-5` appears nowhere in the repo as a Claude-CLI `--model`
argument — the only in-repo occurrences of the family are the OpenRouter-slug form
and the archived arm pins:

```python
# scripts/cross-model-review.py:378
    ap.add_argument("--judge", default="anthropic/claude-sonnet-5", help="pinned judge model for stage-2 matching")
```

```python
# archive/benchmark/scripts/review-arms.py:69
    "base": {"model": "anthropic/claude-sonnet-5", "replicates": 1, "consensus": None,
```

The only Claude-CLI model id this repo actually pins is the fully-dated Haiku form
at `scripts/lite-review.py:41` (quoted in Claim 2a), which is a different shape from
the bare `claude-sonnet-5` the two docs assert. The gap the brief asked about is real
but narrow: the *flag* claim is fully established (2a); the *value* claim is an
untested alias with no in-repo corroborating precedent, and nothing validates it
before it reaches argv, so a wrong alias would surface only as a runtime envelope
failure.

**Evidence:** `scripts/lite-review.py:41`, `scripts/cross-model-review.py:378`, `archive/benchmark/scripts/review-arms.py:69`, `archive/benchmark/scripts/review-arms.py:73`

---

## Claim 3: "`scripts/cross-model-review.py` (benchmark sweep) and `scripts/dd-cross-model-sweep.py` (archival DD sweep) stay frozen and are not to be run from here"

**Location:** `docs/decisions/log.md:69`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two files' stated identities (benchmark sweep / archival DD sweep) and that this diff leaves both unchanged apart from one comment; does not establish that any mechanism *prevents* them from being run (there is no gate — "not to be run from here" is policy, not enforcement), nor that no other OpenRouter-calling script exists in the repo (see Claim 8).

`dd-cross-model-sweep.py` self-describes exactly as the row characterizes it:

```python
# scripts/dd-cross-model-sweep.py:2-6
"""One-shot divergent-design sweep: same prompt to N OpenRouter models, save raw markdown.

This is a post-hoc reconstruction of the runner that produced
runs/dd-cross-model-2026-07-30/ (the original lived in job tmp; behavioral
equivalence to the *.meta.json outputs is verified, identity is not).
```

(excerpt ends `:6`; the module docstring continues to `:21` — read; it also names
the distinction from `cross-model-review.py` explicitly at `:18-20`.)

`cross-model-review.py` is untouched by this diff except for the four-line comment
added above `FINDING_RE` (see Claim 6); `dd-cross-model-sweep.py` is not in the diff
at all (paraphrased — no quote available because the claim covers the absence of a
file from `git diff --stat 3a94fdc~1..HEAD`, which lists seven paths and neither of
these among the changed-logic ones).

**Evidence:** `scripts/dd-cross-model-sweep.py:1-21`, `scripts/cross-model-review.py:135-138`

---

## Claim 4: "The unverified judge pin `anthropic/claude-sonnet-5` and the unpriced-`--judge` pre-flight WARNING (`cb5351d`) are left as shipped rather than hardened."

**Location:** `docs/decisions/log.md:69`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `cb5351d` exists, is the commit that added the pre-flight judge WARNING, and that the pin and the warning are unchanged by this diff; does not establish that the warning behaves as described at runtime (not executed — it needs an OpenRouter key and egress).

The referenced commit resolves and its subject is the one the row attributes to it:

```
cb5351d286bd2cd8f19664a0a84d8097b98bc691 fix(cross-model-review): warn pre-flight on an unpriced judge; title the reference files
```

Its body states the same rationale the row and questions.md Q7 restate — "A warning
rather than an abort because the judge is consulted only when stage-2 matching runs,
which is not knowable at guard time" (`git show cb5351d`, commit body). The pin
itself is unchanged at HEAD:

```python
# scripts/cross-model-review.py:378
    ap.add_argument("--judge", default="anthropic/claude-sonnet-5", help="pinned judge model for stage-2 matching")
```

**Evidence:** `scripts/cross-model-review.py:378`, commit `cb5351d`

---

## Claim 5: Row 48's cross-references — decisions 030 and 031 and "log 37" / "decision 37"

**Location:** `docs/decisions/log.md:69`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the two linked decision files exist at the linked paths and that log row 37 says what row 48 attributes to it; does not establish that 030/031's *contents* still match row 48's characterization of the lightweight-review path beyond the row-37 assertion checked here.

Both link targets exist (`docs/decisions/030-lightweight-review-path.md`,
`docs/decisions/031-review-loop-tier-and-factcheck-policy.md` — paraphrased, no
quote available because the claim is about file existence, not a snippet). Row 37
carries the substance row 48 leans on:

```
# docs/decisions/log.md:59
| 37 | 2026-08-20 | **The lite review path's loop consumer runs on the Claude subscription, not OpenRouter.** New `scripts/lite-review.py`: headless `claude -p` ... Wired into pr-prep Step 3 / review-fix-loop.md. 030's OpenRouter harness (`cross-model-review.py`) is unchanged and remains the benchmark-arm form
```

**Evidence:** `docs/decisions/log.md:59`, `docs/decisions/030-lightweight-review-path.md`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md`

---

## Claim 6: Row 49 — "`test/lite-review-grammar.bats` pins the shape with 7 contract tests over `parse_findings` (keyless/offline — the parser is pure)" and "The two regexes were byte-identical at the moment ownership moved"

**Location:** `docs/decisions/log.md:70`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test count (7), that every test exercises `parse_findings` rather than a mocked `claude` call, that the suite runs with no API key and no network, and that the two `FINDING_RE` blocks are byte-identical both before and after the ownership move; does not establish the strength of "pins the shape" — that is verdicted separately in Claim 9b, which finds the pinning one-directional.

Byte-identity, checked at both revisions by extracting the `FINDING_RE = re.compile(` block
through its closing `)` from each file and comparing:

- command: `git show <rev>:scripts/lite-review.py` / `:scripts/cross-model-review.py` into scratch, then a Python string compare of the extracted blocks
- cwd: `/workspace`
- exit code: 0
- timestamp: 2026-09-12
- result: `3a94fdc~1 identical: True`, `HEAD identical: True` (sha256 prefix of both blocks at HEAD: `c1490d5383e227b6`)

The blocks themselves:

```python
# scripts/lite-review.py:73-78
FINDING_RE = re.compile(
    r"^\s*\d+\.\s*(?P<path>[^|:]+?)(?::(?P<lines>[\d\-, ]+))?\s*\|"
    r"\s*(?P<sev>Critical|High|Medium|Low|Informational)\s*\|"
    r"\s*(?P<domain>[^|]+)\|\s*(?P<title>[^|]+)\|\s*(?P<desc>.+)$",
    re.IGNORECASE,
)
```

```python
# scripts/cross-model-review.py:139-144
FINDING_RE = re.compile(
    r"^\s*\d+\.\s*(?P<path>[^|:]+?)(?::(?P<lines>[\d\-, ]+))?\s*\|"
    r"\s*(?P<sev>Critical|High|Medium|Low|Informational)\s*\|"
    r"\s*(?P<domain>[^|]+)\|\s*(?P<title>[^|]+)\|\s*(?P<desc>.+)$",
    re.IGNORECASE,
)
```

Test count and keyless/offline execution:

- command: `bats test/lite-review-grammar.bats` and `bats --count test/lite-review-grammar.bats`
- cwd: `/workspace`
- exit code: 0; `1..7`, all `ok`; count `7`
- timestamp: 2026-09-12

The suite's only external process is `python3` loading the module by path and calling
`parse_findings` — no `claude`, no HTTP:

```bash
# test/lite-review-grammar.bats:22-31
  python3 - "$REPO_ROOT/scripts/lite-review.py" "$1" <<'PY'
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location("lite_review", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
rows, ok = mod.parse_findings(sys.argv[2])
print(ok)
print(json.dumps(rows))
PY
```

(excerpt ends `:31`; the enclosing `parse()` function closes at `:32` with `}` — read.)
Note for scope: `OPENROUTER_API_KEY` *is* present in this sandbox's environment, so
"keyless" is established by the code path not reading any key, not by the run having
been key-free.

**Evidence:** `scripts/lite-review.py:73-78`, `scripts/cross-model-review.py:139-144`, `test/lite-review-grammar.bats:19-32`, `docs/reviews/execution-logs/r3-lite-review-grammar.txt`

---

## Claim 7: Q2 — "the exit status alone does not discriminate (both old and new behavior exit 1), so the message is the assertion that has teeth"

**Location:** `docs/working/questions.md:7`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the closed-stdin run exits 1 under both the pre-change and post-change `install.sh` and that only the `Aborted.` line differs; does not establish that the test's *other* assertions (`bless it?`, `payload source(s) not found`) discriminate anything, nor that exit 1 is reached by the same mechanism in both (old: errexit on `read`; new: the `*)` case's explicit `exit 1`).

Both variants returned exit 1 in the A/B reproduction recorded under Claim 1: old
exit 1 with zero `Aborted. Nothing was changed.` occurrences, new exit 1 with one.
Same command, cwd, and timestamp as Claim 1; raw output captured.

**Evidence:** `docs/reviews/execution-logs/r3-install-eof-old-vs-new.txt`, `devcontainer-config/install.sh:101-111`

---

## Claim 8: Q6 — "The only consumers of the pin are the benchmark harness `scripts/cross-model-review.py` and the archival `scripts/dd-cross-model-sweep.py`"

**Location:** `docs/working/questions.md:11`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the enumeration of source-level consumers of the literal pin `anthropic/claude-sonnet-5` across all tracked files; does not establish anything about the question's *conclusion* — that no consumer sits on the production path — which independently survives (the third consumer is in `archive/` and is itself broken; see below).

The claim's antecedent is the specific slug (the entry opens "Confirm
`anthropic/claude-sonnet-5` resolves on OpenRouter"). Grepping every tracked file for
that literal gives three code sites, and the enumeration is wrong in both directions.

**`dd-cross-model-sweep.py` does not consume the pin at all.** It has no `--judge`
option and its model list does not contain the slug:

```python
# scripts/dd-cross-model-sweep.py:30
MODELS = ["moonshotai/kimi-k3", "openai/gpt-5.6-sol", "google/gemini-3.1-pro-preview"]
```

(excerpt is a single module-level constant; the enclosing unit is the module — the
lines after it, `:31` onward, were read and contain no further model pin. `grep -n
"judge\|JUDGE" scripts/dd-cross-model-sweep.py` returns no hits — paraphrased, no
quote available because the claim covers the absence of matches.)

**A third, unnamed consumer exists**: the archived arm driver pins the same slug
twice and is a tracked file (`git ls-files archive/benchmark/scripts/review-arms.py`
resolves; last touched in `eefbcf0`):

```python
# archive/benchmark/scripts/review-arms.py:69
    "base": {"model": "anthropic/claude-sonnet-5", "replicates": 1, "consensus": None,
```

```python
# archive/benchmark/scripts/review-arms.py:73
    "k3": {"model": "anthropic/claude-sonnet-5", "replicates": 3, "consensus": 2,
```

It reads `OPENROUTER_API_KEY` and calls the OpenRouter key endpoint directly
(`archive/benchmark/scripts/review-arms.py:135-161` — paraphrased, no quote
available because the pre-flight key check spans ~25 lines of error prose that reads
more clearly as a summary than as a multi-fragment quote).

Why a reader is misled rather than merely under-informed: the entry uses the
enumeration as the load-bearing step ("the only consumers … neither on the production
path"), so a reader auditing the pin before the harness moves would grep two files,
find the slug in one of them, and miss the third site entirely. What rescues the
conclusion — and is worth recording because the entry does not say it — is that
`review-arms.py` is currently unrunnable: it resolves its engine next to itself,

```python
# archive/benchmark/scripts/review-arms.py:52
ENGINE = os.path.join(HERE, "cross-model-review.py")
```

and `archive/benchmark/scripts/` contains no `cross-model-review.py`, so the
module load at `:56-58` raises at import time (paraphrased, no quote available
because the claim covers the absence of a file from a directory listing).

Checked against `docs/reviews/hallucination-patterns.md`: this is **not** a
fabrication — the two named files both exist and one of them really is a consumer.
It is a miscounted enumeration, which the log explicitly excludes ("Stale renames,
off-by-one complexity claims, and outdated configuration values are tracked in the
per-run report only"). No log entry is appended.

Routing note: this Incorrect lands in `docs/working/questions.md` at HEAD — a mutable
working doc — not in an already-merged commit message, so it routes to a normal rubric
tier, not the override log. Commit `3a94fdc`'s message does not restate the
enumeration.

**Evidence:** `docs/working/questions.md:11`, `scripts/dd-cross-model-sweep.py:1-30`, `archive/benchmark/scripts/review-arms.py:52-58`, `archive/benchmark/scripts/review-arms.py:69`, `archive/benchmark/scripts/review-arms.py:73`, `scripts/cross-model-review.py:378`

---

## Claim 9: Q6 — "the production diff-only review already runs on the Claude subscription via `scripts/lite-review.py` (decision log 37, wired into `workflows/pr-prep.md` Step 3 and `workflows/review-fix-loop.md`)"

**Location:** `docs/working/questions.md:11`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both named workflow docs contain a concrete `lite-review.py` invocation and that the `pr-prep.md` one sits inside the document's numbered section 3; does not establish that the invocation is ever actually executed by a run (the workflows are prose instructions, not a runner), nor that `--mode full` — as opposed to the `--mode fix-drift` call the docs actually specify — is wired anywhere.

`pr-prep.md`'s numbered section 3 is `#### 3. Review-fix loop` at `workflows/pr-prep.md:148`,
and its sub-step c is followed immediately by the invocation:

```bash
# workflows/pr-prep.md:216-219
**Fix-commit drift check (decision 031, L=fix-drift).** After fixes and tests, before the re-review pass, run the lite reviewer over just the fix commits:

```bash
python3 scripts/lite-review.py --repo . --range <last-review-commit>..HEAD --mode fix-drift
```

(the invocation at `:218` sits between `**c. Run tests.**` at `:213` and
`**d. Re-review.**` at `:223`, i.e. inside section 3 — read.) The document has no
literal heading spelled "Step 3"; the numbering is `#### 3.`, and the repo's own
prose uses both forms interchangeably (`workflows/pr-prep.md:204` says "the next run
reads at Step 3.5").

`review-fix-loop.md` carries the matching section:

```markdown
# workflows/review-fix-loop.md:66-69
## Fix-commit drift check (lite)

Decision 031 chose `L=fix-drift`: after each fix batch (pr-prep Step 3c), run
`scripts/lite-review.py --mode fix-drift` over the fix commits before starting the next
```

(excerpt ends `:69`; the enclosing section continues to `:80` — read.)

**Evidence:** `workflows/pr-prep.md:148`, `workflows/pr-prep.md:213-223`, `workflows/review-fix-loop.md:66-80`, `docs/decisions/log.md:59`

---

## Claim 10: lite-review.py header — "This file OWNS the FINDINGS grammar and its regex (decision log 48). The grammar originated in cross-model-review.py and the two were byte-identical when ownership moved here"

The compound splits: the byte-identity assertion and the "owns the grammar"
assertion earn different verdicts once "the grammar" is read as more than the regex.

### Claim 10a: the two regexes were byte-identical when ownership moved

**Location:** `scripts/lite-review.py:24-26`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `FINDING_RE = re.compile(...)` block only, at both `3a94fdc~1` and HEAD; does not establish identity of anything else in either file.

Same execution and quoted blocks as Claim 6.

**Evidence:** `scripts/lite-review.py:73-78`, `scripts/cross-model-review.py:139-144`

### Claim 10b: this file owns "the FINDINGS grammar and its regex"

**Location:** `scripts/lite-review.py:24-31`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the two files share (the regex and the prompt's format-spec lines, both identical) versus what they do not (their `parse_findings` bodies, which have diverged in four ways); does not establish which of the two `parse_findings` behaviors is intended to be canonical, nor whether the divergence predates this diff (it does — neither `parse_findings` is touched here).

Mechanism and conclusion are both right — the regex really is shared and byte-identical,
and the format-spec lines the prompts emit are identical across both files:

```
# scripts/lite-review.py:51-54 and scripts/cross-model-review.py:96-99 (identical text)
FINDINGS:
1. <path>:<lines> | <Critical/High/Medium/Low/Informational> | <domain> | <short title> | <1-2 sentence description>

(or the single line "FINDINGS: NONE"). Nothing after the list.
```

The imprecision is the unqualified word "grammar". The *parsers* built on that regex
have already diverged in four respects, so "owns the grammar" is true of the regex and
the wire format but not of parse semantics. Precise version: *owns the FINDINGS wire
format and its regex; the two parsers' surrounding block-detection and row-shaping
differ.*

```python
# scripts/lite-review.py:88-108 (parse_findings)
    if re.search(r"FINDINGS:\s*NONE", text):
        return [], True
    ...
        if line.strip().startswith("FINDINGS:"):
    ...
                "severity": m.group("sev").capitalize(),
    ...
    return rows, bool(rows) or "FINDINGS" in text
```

(excerpt is discontiguous within `parse_findings`, `:86-108`; the whole function was
read — the omitted lines are the loop scaffolding and the remaining five dict keys.)

```python
# scripts/cross-model-review.py:300-321 (parse_findings)
    if re.search(r"FINDINGS:\s*NONE", text, re.IGNORECASE):
        return [], True
    ...
        if re.match(r"\s*FINDINGS\s*:", line):
    ...
            d = {k: (v.strip() if v else v) for k, v in m.groupdict().items()}
            d["basename"] = os.path.basename(d["path"])
    ...
    return rows, in_block or bool(rows)
```

(excerpt is discontiguous within `parse_findings`, `:300-321`; the whole function was
read — the omitted lines are the loop scaffolding and the `line_start`/`line_end`
derivation.) The four differences: `FINDINGS: NONE` is case-insensitive in the copy
and case-sensitive in the owner; block detection is a regex tolerating whitespace
before the colon in the copy versus a literal `startswith` in the owner; the owner
capitalizes severity and emits `severity`/`description` keys where the copy emits raw
`sev`/`desc` plus `basename`/`line_start`/`line_end`; and `parse_ok` is
`bool(rows) or "FINDINGS" in text` in the owner versus `in_block or bool(rows)` in the
copy — these disagree on, e.g., a text mentioning "FINDINGS" in prose with no block.

**Evidence:** `scripts/lite-review.py:49-57`, `scripts/lite-review.py:86-108`, `scripts/cross-model-review.py:94-101`, `scripts/cross-model-review.py:300-321`

---

## Claim 11: lite-review.py header — "test/lite-review-grammar.bats pins the shape"

**Location:** `scripts/lite-review.py:28-30`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the seven tests do and do not catch when `FINDING_RE` is mutated, measured by mutation testing; does not establish anything about non-regex changes to `parse_findings` (block detection, `parse_ok` semantics) beyond the two tests that touch them, nor about prompt-template drift, which no test constrains at all.

Mechanism and conclusion are both right — the suite is real, it runs against
`parse_findings`, and it does fail on a contract change — but "pins the shape" reads
as bidirectional and the pinning is one-directional: it catches *narrowings* of the
grammar and misses *widenings*. Four mutations were applied to `FINDING_RE` in clean
`git archive HEAD` extracts and the suite re-run against each:

- command: `bats test/lite-review-grammar.bats`
- cwd: `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/mut`
- timestamp: 2026-09-12
- baseline (unmutated): exit 0, 7/7 pass
- mutation A — delete the optional `(?::(?P<lines>[\d\-, ]+))?` line-range group so path and lines no longer split: **caught**, test 2 fails
- mutation D — accept `- ` bullet rows alongside `1. ` numbered rows: **not caught**, 7/7 pass
- mutation E — widen the severity alternation with a new `Blocker` level: **not caught**, 7/7 pass
- mutation F — make the description optional (`(?P<desc>.*)` instead of `.+`): **not caught**, 7/7 pass

Precise version: *pins the fields and their order against removal; does not
constrain widening the row prefix, the severity enum, or the description's
non-emptiness.* The brief's question — "would a change to FINDING_RE that alters the
contract still pass?" — answers yes for any widening.

For the adjacent architectural half of the header claim ("nothing but this file holds
the shape in place"): `parse_findings` and `FINDING_RE` appear in exactly one test
file repo-wide, this one (`rg -n "parse_findings|FINDING_RE" test/` returns hits only
in `test/lite-review-grammar.bats` — paraphrased, no quote available because the claim
covers the absence of matches elsewhere). `test/cross-model-review-stage1.bats` covers
the Stage-1 context path, not the parser (`test/cross-model-review-stage1.bats:4-5`).

**Evidence:** `test/lite-review-grammar.bats:1-97`, `scripts/lite-review.py:73-78`, `docs/reviews/execution-logs/r3-finding-re-mutations.txt`, `docs/reviews/execution-logs/r3-lite-review-grammar.txt`

---

## Claim 12: Q4 — "churn across 19 links at 17 sites for a saving that lands on one path"

**Location:** `docs/working/questions.md:9`; restated in commit `435f46a`'s message
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the 19/17 figure can be reproduced from the repo by any obvious counting rule; does not establish that the figure is wrong — only that the counting rule it came from (review artifact A10) is not stated anywhere, so the number cannot be re-derived or refuted.

The figure is restated from a prior review artifact, which states it without a method:

```
# docs/reviews/code-review-rubric-2026-09-12-main-prompt-audit.md:30
| A10 | ... `references/rubric.md` holds severity semantics the *running* pipeline consults at Stage 1.5, Stage 2.5 and all four Stage-3 cross-checks — 19 links from 17 sites — ...
```

Three plausible counting rules were run and none returns 19/17:

- anchored links (`rubric.md#<anchor>`) across `skills/`, `workflows/`, `guides/`: **11 links across 2 files**
- all `rubric.md` mentions excluding `docs/reviews/` and `runs/`: **46 occurrences across 17 files** (the file count matches "17 sites", the link count does not match "19")
- `rubric.md` mentions inside `skills/` only: 18 occurrences across 4 files

(paraphrased for the counts — no quote available because these are `rg -c` / `rg -o | wc -l`
aggregate results over many files rather than a snippet; the per-file breakdown is
reproducible with `rg -c "rubric\.md" -g '!docs/reviews/**' -g '!runs/**'`.)

To verify would require A10's original counting rule — specifically which links it
counted as "the running pipeline consults", which is the discriminating restriction
and is not recorded. Flagged against the logged hallucination pattern class *"a
specific measured value quoted from a checked-in artifact set that does not contain
it"* (three prior instances in `docs/reviews/hallucination-patterns.md`): this claim
is the same shape, but unlike those three it is not refutable here, so it stays
Unverifiable and no log entry is appended.

**Evidence:** `docs/working/questions.md:9`, `docs/reviews/code-review-rubric-2026-09-12-main-prompt-audit.md:30`, `skills/code-review/SKILL.md`, `skills/code-review/references/chat-synthesis.md`

---

## Claim 13: "The FINDINGS grammar is DEFINED by scripts/lite-review.py (decision log 48); this is the copy. It was byte-identical when ownership moved."

**Location:** `scripts/cross-model-review.py:135-138`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte-identity assertion and that decision log row 48 exists and concerns this scoping; does not establish that "DEFINED by" is true of `parse_findings` semantics, which have diverged — see Claim 10b, which carries that residue. The reference is to log **48** while the ownership move is recorded in log **49**; 48 is the scoping decision that made it necessary, so the citation is defensible but points one row short of the record of the change itself.

Byte-identity: same execution as Claim 6 (`identical: True` at both revisions,
block sha256 prefix `c1490d5383e227b6` on both sides at HEAD). Row 48 exists at
`docs/decisions/log.md:69` and names the prerequisite:

```
# docs/decisions/log.md:69
Blocking prerequisite before the harness actually moves: `lite-review.py` must own the FINDINGS grammar outright instead of documenting it as a copy (`lite-review.py:24-26`)
```

Note the row-48 line reference `lite-review.py:24-26` is correct for the *pre-change*
header (the wording it quotes) and now points at the first three lines of the
replacement block, which spans `:24-31`.

**Evidence:** `scripts/cross-model-review.py:135-144`, `scripts/lite-review.py:24-31`, `docs/decisions/log.md:69-70`

---

## Claim 14: "An EOF stdin must decline *and say so*: before `read -r reply || reply=\"\"`, errexit killed the script at the prompt and this line never printed."

**Location:** `test/cc-isolated-functions.bats:483-484`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the added `Aborted. Nothing was changed.` assertion is the one that discriminates pre- from post-change behavior, and that the accompanying `[ "$status" -eq 1 ]` does not; does not establish that the test would catch a *different* regression (e.g. a change that prints the line but then continues past the `exit 1`, which `-eq 1` does cover).

The complete test body, signature to final line:

```bash
# test/cc-isolated-functions.bats:474-489
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

The A/B reproduction under Claim 1 confirms the discrimination directly: under the
old code the run exits **1** (so `[ "$status" -eq 1 ]` would have passed unchanged)
and the `Aborted.` substring is **absent** (so only the second assertion fails). The
comment's claim that "this line never printed" is exactly what the old-variant
capture shows.

**Evidence:** `test/cc-isolated-functions.bats:474-489`, `docs/reviews/execution-logs/r3-install-eof-old-vs-new.txt`

---

## Claim 15: "the two regexes were byte-identical when ownership moved, and nothing but this file holds the shape in place once the harness leaves"

**Location:** `test/lite-review-grammar.bats:8-10`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identity (as in Claim 6) and that no other test file in the repo references `parse_findings` or `FINDING_RE`; does not establish that no *non-test* mechanism constrains the shape (the prompt templates in both scripts also encode the format and are unguarded by any test — see Claim 10b's residue).

Byte-identity: same execution as Claim 6. Test-file exclusivity: `rg -n
"parse_findings|FINDING_RE" test/` returns hits only in `test/lite-review-grammar.bats`
(paraphrased, no quote available because the claim covers the absence of matches in
the other 30+ suites under `test/`).

**Evidence:** `test/lite-review-grammar.bats:1-12`, `test/cross-model-review-stage1.bats:1-15`, `docs/reviews/execution-logs/r3-lite-review-grammar.txt`

---

## Claim 16: Commit-message claims — "All 5 install.sh tests pass" (8980861), "Fast suite: 623 passed, 0 failed" and "7 contract tests over parse_findings, keyless and offline since the parser is pure" (435f46a)

**Location:** commit messages `8980861`, `435f46a`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three counts as measured at HEAD in this sandbox; does not establish that the counts held at the moment each commit was authored (only HEAD was measured), nor that the slow suite passes (not run).

- command: `bats -f "install.sh" test/cc-isolated-functions.bats`; cwd `/workspace`; exit 0; timestamp 2026-09-12. Output: `1..5`, five `ok` lines, zero `not ok`.
- command: `scripts/run-tests.sh --fast`; cwd `/workspace`; exit 0; timestamp 2026-09-12. `grep -cE "^ok "` → **623**; `grep -cE "^not ok "` → **0**.
- command: `bats --count test/lite-review-grammar.bats`; cwd `/workspace`; exit 0 → **7**; all seven call `mod.parse_findings` (quoted under Claim 6) and spawn no `claude`.

Flagged against the logged hallucination pattern *"All 85 tests across the code-review
suites pass claimed in commit 59ca38f … but the suites hold 97"* — the same shape
(a test-count denominator in a commit message). This instance reproduces exactly, so
it is a match on form only, not a recurrence.

**Evidence:** `docs/reviews/execution-logs/r3-install-sh-tests.txt`, `docs/reviews/execution-logs/r3-fast-suite.txt`, `docs/reviews/execution-logs/r3-lite-review-grammar.txt`

---

## Claim 17: "questions.md now has no open entries" (commit `435f46a`)

**Location:** commit `435f46a`; `docs/working/questions.md:7-13`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of unchecked (`- [ ]`) versus checked (`- [x]`) checkbox entries in `docs/working/questions.md` at HEAD; does not establish that every checked entry is *substantively* resolved (Claim 8 finds one closed entry resting on a wrong enumeration), nor that no open questions live elsewhere (e.g. `docs/working/` siblings).

- command: `grep -c "^- \[ \]" docs/working/questions.md` → **0**; `grep -c "^- \[x\]" docs/working/questions.md` → **8**
- cwd: `/workspace`; exit 0 (for the `[x]` count; the `[ ]` grep exits 1 on zero matches by design); timestamp 2026-09-12

**Evidence:** `docs/working/questions.md:7-13`

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (`docs/working/questions.md:11`): Q6's enumeration of pin consumers is wrong in both directions — `scripts/dd-cross-model-sweep.py` does not reference `anthropic/claude-sonnet-5` at all (its `MODELS` list is kimi-k3 / gpt-5.6-sol / gemini-3.1-pro-preview and it has no `--judge`), and an unnamed third consumer exists at `archive/benchmark/scripts/review-arms.py:69,73`. Fix: name `cross-model-review.py` and `archive/benchmark/scripts/review-arms.py` as the two consumers, and either drop `dd-cross-model-sweep.py` or re-describe it as an unrelated OpenRouter caller. The entry's conclusion (no consumer on the production path) survives — `review-arms.py` is archived and unrunnable, its `ENGINE` pointing at a `cross-model-review.py` that does not exist in `archive/benchmark/scripts/`.

### Stale
- None.

### Mostly Accurate
- **Claim 10b** (`scripts/lite-review.py:24-31`): "owns the FINDINGS grammar" is precise for the regex and the prompt's wire format, which are identical across both files, but the two `parse_findings` implementations have already diverged in four ways (`FINDINGS: NONE` case-sensitivity, block detection, row keys/severity capitalization, `parse_ok` semantics). Tighten to "owns the wire format and its regex" or state that parse semantics are deliberately per-file.
- **Claim 11** (`scripts/lite-review.py:28-30`): "pins the shape" is one-directional. Mutation testing shows the suite catches removing the line-range group but passes unchanged when the row prefix is widened to bullets, a severity level is added, or the description is made optional. Tighten to "pins the fields and their order against removal", or add a negative test for each widening.

### Unverifiable
- **Claim 2b** (`docs/decisions/log.md:69`, `docs/working/questions.md:11`): whether `claude-sonnet-5` resolves as a Claude-CLI model alias. Needs one `claude -p --model claude-sonnet-5` call with egress. Worth noting the gap the flag claim leaves open: `--model` is passed to argv with zero validation (`scripts/lite-review.py:111-126`), the only Claude-CLI id pinned in-repo is the fully-dated `claude-haiku-4-5-20251001`, and a bad alias would surface only as a runtime envelope/JSON-decode failure.
- **Claim 12** (`docs/working/questions.md:9`): the "19 links at 17 sites" figure restated from review finding A10. Needs A10's counting rule, which is not recorded anywhere. Three plausible rules give 11/2, 46/17, and 18/4 — none gives 19/17.

---

## Legibility targets

| Claim | Legibility-target |
|---|---|
| 1 | for-author |
| 2a | for-orchestrator-synthesis |
| 2b | for-author |
| 3 | for-orchestrator-synthesis |
| 4 | for-orchestrator-synthesis |
| 5 | for-orchestrator-synthesis |
| 6 | for-automated-gate |
| 7 | for-author |
| 8 | for-author |
| 9 | for-orchestrator-synthesis |
| 10a | for-automated-gate |
| 10b | for-author |
| 11 | for-author |
| 12 | for-author |
| 13 | for-orchestrator-synthesis |
| 14 | for-author |
| 15 | for-orchestrator-synthesis |
| 16 | for-automated-gate |
| 17 | for-automated-gate |

---

## Goal-Alignment Note

**Answered.** The user's goal — reviewing the last three commits on main before the
work is considered settled — is served by this pass on the checkable-claims axis. All
eleven items in the shared brief were addressed, nine of them by execution (the
install.sh A/B reproduction, the fast suite, the install.sh suite, the grammar suite,
the byte-identity comparison at two revisions, and four-way mutation testing of
`FINDING_RE`). The one finding that would change a shipped artifact is Claim 8: Q6's
consumer enumeration in `docs/working/questions.md` is wrong, though its conclusion
survives. Two claims are genuinely imprecise rather than wrong (Claims 10b and 11) and
both concern how strongly the new ownership is actually held — directly relevant to
the commit's stated purpose of letting the harness leave safely.

**Out of scope.** Whether `review-arms.py`'s broken `ENGINE` path should be fixed or
the file deleted; whether the grammar suite should gain negative tests for the three
uncaught widenings; whether `parse_findings`' divergence between the two files is a
defect. These are code-review judgments belonging to the sibling critics, not to a
fact-check pass — this report records only that the divergence exists and that the
comments over-describe what is held in place.

**Escalate.** Nothing. No Incorrect verdict landed on an immutable already-merged
commit message, so no override-log routing is required; Claim 8's Incorrect is in a
mutable working doc and routes to a normal rubric tier. No hallucination-pattern entry
was appended — Claim 8 is a miscounted enumeration, which the log explicitly excludes,
and Claim 12 is unverifiable rather than refuted.

**Questions I would have asked.** (1) Does A10's "19 links at 17 sites" have a
recorded counting rule, or should the figure be dropped from the won't-fix rationale
now that the decision is settled? (2) Is the `parse_findings` divergence between owner
and copy intentional — i.e. does "owns the grammar" mean the wire format only, or is
the copy expected to converge before it forks?
