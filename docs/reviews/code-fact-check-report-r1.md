# Code Fact-Check Report

Commit: 435f46a

**Repository:** /workspace
**Scope:** `git diff 3a94fdc~1..HEAD` — 3 commits (3a94fdc, 8980861, 435f46a) across `devcontainer-config/install.sh`, `docs/decisions/log.md`, `docs/working/questions.md`, `scripts/cross-model-review.py`, `scripts/lite-review.py`, `test/cc-isolated-functions.bats`, `test/lite-review-grammar.bats`, plus the three commit messages
**Checked:** 2026-09-12
**Total claims checked:** 16
**Summary:** 9 verified, 5 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

**Hallucination-pattern log:** `docs/reviews/hallucination-patterns.md` read before checking. Three logged patterns, all of the same class — *a specific measured value quoted from a checked-in artifact set that does not contain it* (corpus minimum 3 KB, `total_golden` 11/13, "85 tests"). Every numeric claim in this diff ("7 contract tests", "623 passed", "All 5 install.sh tests pass", "byte-identical") was therefore executed rather than read, and each is Verified below. Claim 9 is the only Incorrect and is a **wrong attribution**, not a fabrication (`scripts/dd-cross-model-sweep.py` exists and is correctly described elsewhere), so it does **not** qualify for the log; no new entry appended.

**Execution logs:** `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/logs/` — `install-old-vs-new.txt`, `lite-grammar.txt`, `install-tests.txt`, `fast-suite.txt`, `regex-mutation.txt`. (Scratchpad rather than `docs/reviews/execution-logs/` so the fact-check run leaves no untracked artifacts in the tree under review; paths are absolute and readable.)

---

## Claim 1: "`|| reply=\"\"` so a closed/EOF stdin (piped or non-tty run) falls through to the abort case below instead of dying on `read`'s non-zero exit under `set -e`, which killed the script before it could say why."

**Location:** `devcontainer-config/install.sh:102-105`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers both halves of the comment — the old EOF-under-errexit death before the abort line, and the new fall-through to the `*)` case — for the `ASSUME_YES != --yes` branch reached with `</dev/null`. Does not establish behavior when stdin is an *open* tty that returns a non-EOF read failure, nor the `--yes` branch (which never reaches `read`), nor that exit 1 is the right status for a decline.

The enclosing unit is the whole `if` block, read to its `fi`:

```sh
# devcontainer-config/install.sh:100-111
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

`set -euo pipefail` is in force from `devcontainer-config/install.sh:16` (`set -euo pipefail`), so an unguarded `read` returning non-zero would terminate the script. The empty `reply` falls to `*)`, which is the abort arm quoted above; the excerpt is the complete `if` block, so nothing after it is elided.

Executed the discriminating experiment — the pre-fix `install.sh` from `8980861~1` and the HEAD version, each against the same synthesized payload tree with `</dev/null`:

```
# scratchpad/logs/install-old-vs-new.txt
OLD_EXIT=1
OLD_ABORTED_LINE=no
OLD_PROMPT=yes
NEW_EXIT=1
NEW_ABORTED_LINE=yes
NEW_PROMPT=yes
```

Command: `bash /tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/discriminate.sh`; cwd `/workspace`; exit code 0; 2026-09-12T12:16:42-07:00.

**Evidence:** `devcontainer-config/install.sh:16`, `devcontainer-config/install.sh:100-111`, `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/logs/install-old-vs-new.txt`

---

## Claim 2a: log row 48 — "a Sonnet 5 pass is `--model claude-sonnet-5`, not new code"

**Location:** `docs/decisions/log.md:69` (also `docs/working/questions.md:11`)
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the plumbing claim — that a model change in `lite-review.py` requires only the existing `--model` flag and no code change. Does not establish that the string `claude-sonnet-5` resolves at the CLI (Claim 2b), nor that a Sonnet 5 pass produces comparable output to the Haiku default, nor that any caller actually passes it.

`--model` exists with a default and is handed straight to the CLI:

```python
# scripts/lite-review.py:141
    ap.add_argument("--model", default=DEFAULT_MODEL)
# scripts/lite-review.py:160
    env = run_claude(prompt, args.model, args.timeout)
```

and `run_claude` interpolates it into the argv with no validation. The complete function, signature to final line:

```python
# scripts/lite-review.py:111-131
def run_claude(prompt, model, timeout_s):
    """One headless subscription call; returns the decoded JSON envelope."""
    with tempfile.TemporaryDirectory(prefix="lite-review-") as empty_cwd:
        proc = subprocess.run(
            [
                "claude", "-p",
                "--model", model,
                ...
```

(excerpt ends :117; enclosing `run_claude` continues to :131 — read; the remainder sets `cwd`/`capture_output`, then `json.loads(proc.stdout)` with a `JSONDecodeError` → `sys.exit` path. No branch inspects or validates `model` anywhere between the flag and the `claude` argv.) `DEFAULT_MODEL = "claude-haiku-4-5-20251001"` (`scripts/lite-review.py:41`) is the only other value in play.

**Evidence:** `scripts/lite-review.py:41`, `scripts/lite-review.py:111-131`, `scripts/lite-review.py:141`, `scripts/lite-review.py:160`

---

## Claim 2b: log row 48 — that `claude-sonnet-5` is a value this would actually resolve

**Location:** `docs/decisions/log.md:69` (also `docs/working/questions.md:11`)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether `claude-sonnet-5` is a well-formed value for the CLI's `--model` flag. Does not establish that a live call succeeds (this sandbox has no egress and no Anthropic credential, so no call was attempted), nor that the account is entitled to Sonnet 5, nor that the JSON-envelope success check in `main()` behaves the same on a non-Haiku model.

The installed CLI documents exactly this input form:

```
# `claude --help`, /workspace, exit 0, 2026-09-12T12:17
  --model <model>    Model for the current session. Provide
                     an alias for the latest model (e.g.
                     'fable', 'opus', or 'sonnet') or a
                     model's full name (e.g. 'claude-fable-5').
```

`claude-sonnet-5` is the current full model name for Claude Sonnet 5 (paraphrased — no quote available because the authority is the bundled `claude-api` skill's model table, not a file in this repo). So the value is well-formed and of the documented shape. The gap the row's phrasing leaves open, and which nothing in the repo closes: `--model` is unvalidated end-to-end (Claim 2a), so a wrong id would surface only as a runtime `claude` failure, not as an argument error — and the repo's own default uses the *dated* form `claude-haiku-4-5-20251001`, a different spelling convention from the bare-alias form the row asserts. Precise version: "a Sonnet 5 pass is `--model claude-sonnet-5`, an unvalidated pass-through to `claude --model`; the id is well-formed but has not been exercised from this repo."

**Evidence:** `scripts/lite-review.py:41`, `scripts/lite-review.py:117`, `claude --help` (`--model` section)

---

## Claim 3: log row 48 — "`scripts/cross-model-review.py` (benchmark sweep) and `scripts/dd-cross-model-sweep.py` (archival DD sweep) stay frozen and are not to be run from here"

**Location:** `docs/decisions/log.md:69`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether the two named scripts were left functionally unmodified across this diff and whether either sits on the production review path. Does not establish anything about future edits, nor that the scripts are unrunnable (no mechanism enforces "not to be run from here" — the statement is policy, not a guard).

`dd-cross-model-sweep.py` is untouched by this diff (paraphrased — no quote available because the claim is about absence: the file does not appear in `git diff --stat 3a94fdc~1..HEAD`, whose seven entries are install.sh, log.md, questions.md, cross-model-review.py, lite-review.py, and the two bats files).

`cross-model-review.py` is *not* untouched — the very next commit in this range adds four comment lines above `FINDING_RE`:

```python
# scripts/cross-model-review.py:135-138
# The FINDINGS grammar is DEFINED by scripts/lite-review.py (decision log 48);
# this is the copy. It was byte-identical when ownership moved. If this harness
# moves to the SWRBench fork, keep it in step with the owner deliberately or
# state in the fork that the two have diverged - do not silently re-fork it.
```

The change is comment-only, so "frozen" holds in the behavioral sense but not the literal one. Precise version: "stay functionally frozen — comment-level annotation excepted". Neither script is reachable from the production path: the only workflow call sites are `python3 scripts/lite-review.py --repo . --range <last-review-commit>..HEAD --mode fix-drift` (`workflows/pr-prep.md:218`) and `` `scripts/lite-review.py --mode fix-drift` `` (`workflows/review-fix-loop.md:69`).

**Evidence:** `docs/decisions/log.md:69`, `scripts/cross-model-review.py:135-138`, `workflows/pr-prep.md:218`, `workflows/review-fix-loop.md:69`

---

## Claim 4: log row 48 — "`lite-review.py` must own the FINDINGS grammar outright instead of documenting it as a copy (`lite-review.py:24-26`)"

**Location:** `docs/decisions/log.md:69`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether the cited line range still contains the text the row describes. Does not establish anything about the row's substantive judgment (which Claim 7 covers), and does not imply the row should be rewritten — `log.md` is a dated historical record, and its citation was exact when written.

At `3a94fdc`, the citation was precise — lines 24-26 were exactly the "copy" wording:

```python
# scripts/lite-review.py:24-26 @ 3a94fdc
- The FINDINGS grammar and regex are copied from cross-model-review.py so
  output stays comparable with the E2/E3 lite-arm artifacts; if that harness
  is retired, this file is the surviving owner of the grammar.
```

At HEAD the same line numbers say the opposite:

```python
# scripts/lite-review.py:24-26 @ HEAD
- This file OWNS the FINDINGS grammar and its regex (decision log 48). The
  grammar originated in cross-model-review.py and the two were byte-identical
  when ownership moved here, so output stays comparable with the E2/E3
```

The row's dependent clause — "tracked in `docs/working/questions.md`" — is also overtaken: that entry is now closed (`docs/working/questions.md:13`, `- [x] ... **Done 2026-09-12 — resolved rather than left pending...**`). A reader arriving at row 48 and following its pointer finds the fix, not the defect it describes. Row 49 immediately below records the resolution, which is what keeps this low-severity.

**Evidence:** `docs/decisions/log.md:69`, `scripts/lite-review.py:24-26`, `docs/working/questions.md:13`

---

## Claim 5: log row 48 — "the unpriced-`--judge` pre-flight WARNING (`cb5351d`)"

**Location:** `docs/decisions/log.md:69`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-automated-gate
**Scope:** Covers that commit `cb5351d` exists and introduced the pre-flight warning on an unpriced judge id. Does not establish that the warning fires on every unpriced-judge path, nor that warning (rather than aborting) is the right behavior — that is the design question Q7 closes as moot.

The commit resolves and its subject matches:

```
cb5351d fix(cross-model-review): warn pre-flight on an unpriced judge; title the reference files
```

and the warning is live in the file:

```python
# scripts/cross-model-review.py:460
            print(f"WARNING: no pricing for judge {args.judge} — unknown or unpriced model id. "
```

(excerpt ends :460; the enclosing pre-flight guard continues past it — read: the remainder completes the message string and the `print` call, and the branch does not `sys.exit`, i.e. it warns without aborting, which is exactly what Q7 records as the shipped state.)

**Evidence:** `docs/decisions/log.md:69`, `scripts/cross-model-review.py:460`, `git log -1 cb5351d`

---

## Claim 6: log row 49 — "The two regexes were byte-identical at the moment ownership moved"

**Location:** `docs/decisions/log.md:70` (restated at `scripts/lite-review.py:25-26` and `scripts/cross-model-review.py:136`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `FINDING_RE = re.compile(...)` block in each file, character for character, at HEAD (the commit at which ownership moved). Does not establish that the *parsers* around the two regexes are identical — they are not, see Claim 11 — and does not establish that E2/E3 artifact records are schema-identical, see Claim 12.

Both blocks are textually the same:

```python
# scripts/lite-review.py:73-78 and scripts/cross-model-review.py:139-144 — identical text
FINDING_RE = re.compile(
    r"^\s*\d+\.\s*(?P<path>[^|:]+?)(?::(?P<lines>[\d\-, ]+))?\s*\|"
    r"\s*(?P<sev>Critical|High|Medium|Low|Informational)\s*\|"
    r"\s*(?P<domain>[^|]+)\|\s*(?P<title>[^|]+)\|\s*(?P<desc>.+)$",
    re.IGNORECASE,
)
```

Executed a SHA-256 comparison of the two extracted blocks rather than eyeballing them: both hash to `a91f54584096efd7…`, `IDENTICAL: True`. Command: inline `python3` heredoc extracting each `FINDING_RE = re.compile(` block through its closing `)` and hashing; cwd `/workspace`; exit code 0; 2026-09-12T12:16.

**Evidence:** `scripts/lite-review.py:73-78`, `scripts/cross-model-review.py:139-144`, `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/logs/` (hash comparison output reproduced above)

---

## Claim 7: log row 49 — "`test/lite-review-grammar.bats` pins the shape with 7 contract tests over `parse_findings` (keyless/offline — the parser is pure)"

**Location:** `docs/decisions/log.md:70` (also `scripts/lite-review.py:29-30`, `test/lite-review-grammar.bats:12`, commit 435f46a)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-automated-gate
**Scope:** Covers the test count, the subject under test (`parse_findings`), and that the suite runs with no API key and no network. Does not establish that the suite would *catch* every contract-altering change to the grammar — that separate claim is Claim 13, where the evidence is weaker.

Seven tests, all passing:

```
# scratchpad/logs/lite-grammar.txt
1..7
ok 1 FINDINGS: NONE parses as a clean review, not as a parse failure
...
ok 7 a FINDINGS block with only malformed rows yields no rows but still parses
```

Command `bats test/lite-review-grammar.bats`; cwd `/workspace`; exit code 0; 2026-09-12T12:16:02-07:00.

Keyless and offline confirmed by running the suite with both credential variables explicitly unset — `env -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN bats test/lite-review-grammar.bats`, cwd `/workspace`, 7/7 `ok`, exit 0, 2026-09-12T12:20. No Anthropic credential exists in this environment at all (`env | grep -iE "ANTHROPIC|API_KEY"` returns only `OPENROUTER_API_KEY` and `CLAUDE_CODE_EXECPATH`), and the sandbox has no egress, so the passing run is itself the proof. Purity holds through module load, not just the function: the helper `exec_module`s the whole file, and the only top-level effect is guarded —

```python
# scripts/lite-review.py:145-146
if __name__ == "__main__":
    sys.exit(main())
```

**Evidence:** `test/lite-review-grammar.bats:1-97`, `scripts/lite-review.py:145-146`, `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/logs/lite-grammar.txt`

---

## Claim 8: questions.md Q2 — "the exit status alone does not discriminate (both old and new behavior exit 1)"

**Location:** `docs/working/questions.md:7`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the EOF-stdin path of `install.sh` with a complete payload, old versus new. Does not establish that the two behaviors are indistinguishable on any other axis (they differ in stdout, which is the point), nor that exit 1 is correct for a decline.

Both versions exit 1; only the new one prints the abort line — `OLD_EXIT=1` / `OLD_ABORTED_LINE=no` versus `NEW_EXIT=1` / `NEW_ABORTED_LINE=yes` (full provenance in Claim 1). The entry's conclusion — that the message is the assertion with teeth — follows directly.

**Evidence:** `docs/working/questions.md:7`, `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/logs/install-old-vs-new.txt`

---

## Claim 9: questions.md Q6 — "The only consumers of the pin are the benchmark harness `scripts/cross-model-review.py` and the archival `scripts/dd-cross-model-sweep.py`, neither on the production path"

**Location:** `docs/working/questions.md:11`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which files reference the pinned id `anthropic/claude-sonnet-5` as a live model selection. Does not dispute the conclusion (nothing on the production path consumes it — that half is right), and does not cover checked-in run artifacts under `runs/` or prior review reports, which mention the string as recorded data rather than consuming it.

`dd-cross-model-sweep.py` does not consume the pin, or any Anthropic model. Its model list is fixed and contains no Anthropic entry:

```python
# scripts/dd-cross-model-sweep.py:30
MODELS = ["moonshotai/kimi-k3", "openai/gpt-5.6-sol", "google/gemini-3.1-pro-preview"]
```

`grep -in "anthropic" scripts/dd-cross-model-sweep.py` returns no matches (paraphrased — no quote available because the claim covers absence of code; the grep exits 1 with empty output). The sole consumer is the `--judge` default in the harness:

```python
# scripts/cross-model-review.py:378
    ap.add_argument("--judge", default="anthropic/claude-sonnet-5", help="pinned judge model for stage-2 matching")
```

What the code actually supports: *the only consumer of the pin is `scripts/cross-model-review.py`'s `--judge` default; `scripts/dd-cross-model-sweep.py` is a separate OpenRouter script that is also out of scope but does not use this id.* The entry's operative conclusion — the pin is off the production path, so verifying it is moot — is unaffected; the refuted part is the enumeration a reader would act on when hunting down the pin's blast radius before moving the harness. Not a hallucination-log entry: the file, the script's role, and the id all exist; this is a misattributed consumer.

**Evidence:** `docs/working/questions.md:11`, `scripts/dd-cross-model-sweep.py:30`, `scripts/cross-model-review.py:378`

---

## Claim 10a: questions.md Q6 — "wired into `workflows/pr-prep.md` Step 3 and `workflows/review-fix-loop.md`"

**Location:** `docs/working/questions.md:11`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both named workflow documents invoke `scripts/lite-review.py`, and that the pr-prep call site sits inside the document's step 3. Does not establish which *mode* is wired (Claim 10b), nor that any automation executes these documents.

pr-prep's call site is inside `#### 3. Review-fix loop` (`workflows/pr-prep.md:147`), under sub-step `**c. Run tests.**`:

```bash
# workflows/pr-prep.md:218
python3 scripts/lite-review.py --repo . --range <last-review-commit>..HEAD --mode fix-drift
```

The "Step 3" spelling is the repo's own: `workflows/pr-prep.md:204` refers to "Step 3.5" and `workflows/review-fix-loop.md:66` to "pr-prep Step 3c". review-fix-loop invokes it under its own `## Fix-commit drift check (lite)` heading:

```
# workflows/review-fix-loop.md:69
`scripts/lite-review.py --mode fix-drift` over the fix commits before starting the next
```

**Evidence:** `workflows/pr-prep.md:147`, `workflows/pr-prep.md:204`, `workflows/pr-prep.md:218`, `workflows/review-fix-loop.md:66-69`

---

## Claim 10b: questions.md Q6 — "the production diff-only review already runs on the Claude subscription via `scripts/lite-review.py`"

**Location:** `docs/working/questions.md:11` (same assertion in `docs/decisions/log.md:69`)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the wired workflows actually invoke. Does not dispute that the subscription backend is real (it is — Claim 2a's `run_claude` argv), and does not establish anything about how often the workflows are run in practice.

Both wired call sites pass `--mode fix-drift` (quoted in Claim 10a). That mode is deliberately *not* a general diff-only review:

```
# workflows/review-fix-loop.md:70-73
full pass. The check is deliberately narrow — it reports **only** comment/doc drift the
fix introduced (a comment now stale relative to the changed code, or a new comment making
a claim the code doesn't satisfy). It is not a second reviewer: pre-existing issues,
style, and code behavior belong to the full review passes.
```

The general mode exists — `ap.add_argument("--mode", choices=["full", "fix-drift"], default="full")` (`scripts/lite-review.py:140`) — but no workflow, skill, guide, or hook invokes it (paraphrased — no quote available because the claim covers absence: `grep -rn "--mode" workflows/ docs/decisions/*.md` returns only the two `fix-drift` call sites and decision 031's reference to them). Precise version: "the subscription-backed lite path is wired in, in its narrow `fix-drift` mode; its `full` diff-only mode is implemented and available but has no wired caller." This matters for the row's load-bearing inference — that a Sonnet 5 diff-only pass needs only a flag — because the flag would be added to a mode nothing currently runs.

**Evidence:** `docs/working/questions.md:11`, `scripts/lite-review.py:140`, `workflows/pr-prep.md:218`, `workflows/review-fix-loop.md:69-73`

---

## Claim 11: "The FINDINGS grammar is DEFINED by `scripts/lite-review.py` (decision log 48); this is the copy. It was byte-identical when ownership moved."

**Location:** `scripts/cross-model-review.py:135-138`
**Type:** Architectural / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the regex, which is byte-identical (Claim 6), and the ownership declaration, which log 48/49 do record. Does **not** establish that "the grammar" in the broader sense — the parser wrapped around the regex, and the emitted row schema — is identical between the two files; it is not. Severity carried by the "It was byte-identical" part under its natural (grammar-wide) reading.

The declaration half checks out: `docs/decisions/log.md:70` opens "**`scripts/lite-review.py` owns the FINDINGS grammar; `cross-model-review.py` is now the copy.**", and the owning file says the same (`scripts/lite-review.py:24`). The pronoun "It" is the imprecision: the sentence sits directly above `FINDING_RE`, so the regex reading is defensible, but the preceding sentence's subject is "The FINDINGS grammar", and the two parsers differ in four ways that a fork keeping them "in step" would need to know about. `lite-review`'s complete `parse_findings`, signature to `return`:

```python
# scripts/lite-review.py:85-108
def parse_findings(text):
    """Parse the FINDINGS block; returns (findings, parse_ok)."""
    if re.search(r"FINDINGS:\s*NONE", text):
        ...
        if line.strip().startswith("FINDINGS:"):
            in_block = True
        ...
            rows.append({
                "path": ..., "lines": ..., "severity": m.group("sev").capitalize(),
                "domain": ..., "title": ..., "description": ...,
            })
    return rows, bool(rows) or "FINDINGS" in text
```

against the harness copy:

```python
# scripts/cross-model-review.py:300-321
def parse_findings(text):
    """Parse the FINDINGS block; returns (findings, parse_ok)."""
    if re.search(r"FINDINGS:\s*NONE", text, re.IGNORECASE):
        ...
        if re.match(r"\s*FINDINGS\s*:", line):
        ...
            d = {k: (v.strip() if v else v) for k, v in m.groupdict().items()}
            d["basename"] = os.path.basename(d["path"])
            ...
    return rows, in_block or bool(rows)
```

The divergences: (1) the `NONE` sentinel is case-insensitive in the harness, case-sensitive in the owner; (2) block detection is a regex tolerating whitespace before the colon in the harness, a literal `startswith` in the owner; (3) `parse_ok` falls back to a substring search over the *whole text* in the owner versus the `in_block` flag in the harness — so a review that merely mentions "FINDINGS" in prose reports `parse_ok=True` from the owner; (4) row keys differ (`severity`/`title`/`description` versus raw `sev`/`title`/`desc` plus `basename`/`line_start`/`line_end`). Precise version: "the **regex** was byte-identical when ownership moved; the surrounding parser was already divergent."

**Evidence:** `scripts/cross-model-review.py:135-138`, `scripts/cross-model-review.py:300-321`, `scripts/lite-review.py:85-108`, `docs/decisions/log.md:70`

---

## Claim 12: "This file OWNS the FINDINGS grammar and its regex … the two were byte-identical when ownership moved here, so output stays comparable with the E2/E3 lite-arm artifacts"

**Location:** `scripts/lite-review.py:24-28`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the byte-identity premise (Verified, Claim 6) and the comparability conclusion at the level of the *finding grammar*. Does not establish record-level comparability with the checked-in E2/E3 artifacts, which were produced by the harness and carry the harness's key names; does not establish that model or prompt differences between the arms preserve comparability.

The premise holds (Claim 6). The conclusion is narrower than the sentence implies: the checked-in lite-arm artifacts carry the harness's `m.groupdict()` key names, not this file's:

```json
// runs/review-arms/e2/mfc-corpus/base/findings.jsonl:1
{"model": "anthropic/claude-sonnet-5", ..., "parse_ok": true, "n_findings": 3, "findings": [{"path": "app/lib/corpus/flag.ts", "lines": "16", "sev": "Medium", "domain": "correctness/build-config", "title": ...
```

`"sev"` is `cross-model-review.py`'s spelling; `lite-review.py` emits `"severity"` with `.capitalize()` applied (`scripts/lite-review.py:103`, `"severity": m.group("sev").capitalize(),`). So a future comparison against these artifacts is line-grammar-comparable but not field-name-comparable without a mapping. Precise version: "…so the *finding line grammar* stays comparable with the E2/E3 lite-arm artifacts; the emitted record schemas already differ."

**Evidence:** `scripts/lite-review.py:24-28`, `scripts/lite-review.py:103`, `runs/review-arms/e2/mfc-corpus/base/findings.jsonl:1`, `runs/review-arms/e2/run-live.sh:2`

---

## Claim 13: "test/lite-review-grammar.bats pins the shape, and any change to it needs a matching note in the decision log" / "nothing but this file holds the shape in place once the harness leaves"

**Location:** `scripts/lite-review.py:29-31`, `test/lite-review-grammar.bats:5-10`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers (a) that no other test constrains this grammar, and (b) how much of `FINDING_RE`'s contract the suite actually pins, measured by mutation. Does not establish anything about the "needs a matching note in the decision log" half, which is a process instruction with no mechanical enforcement (no hook or test checks it).

Half (a) is exact: `grep -rln "lite-review\|lite_review" test/` returns `test/lite-review-grammar.bats` alone (paraphrased — no quote available because the claim covers absence of other files; single-line grep result). `test/cross-model-review-stage1.bats` contains no `FINDING_RE` or `parse_findings` reference.

Half (b) is where "pins the shape" overstates. I mutated `FINDING_RE` in a scratch copy and re-ran the suite against each variant (command `python3 /tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/mutate2.py`; cwd `/workspace`; exit 0; 2026-09-12T12:20:19-07:00; each mutated regex is printed in the log for audit):

| Mutation | Suite result |
|---|---|
| baseline | 7/7 ok |
| drop `re.IGNORECASE` | **not ok 3** — caught |
| make the line range mandatory (drop `?`) | **not ok 4** — caught |
| widen severity set with `Blocker` | 7/7 ok — **not caught** |
| description optional (`.+` → `.*`) | 7/7 ok — **not caught** |
| path group may swallow `:` | 7/7 ok — **not caught** |

So the suite catches *narrowing* changes that break the documented examples, and misses *widening* ones — a new severity level, an empty description, or a path pattern that changes how `a.py:1:2` splits would all ship green. Precise version: "pins the shape against narrowing changes; widening the grammar (new severity values, optional fields, looser path matching) passes unnoticed." Given that the file's stated purpose is to hold the contract after the harness leaves the repo, this is the gap worth knowing about.

**Evidence:** `scripts/lite-review.py:29-31`, `test/lite-review-grammar.bats:1-97`, `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/logs/regex-mutation.txt`

---

## Claim 14: "An EOF stdin must decline *and say so*: before `read -r reply || reply=\"\"`, errexit killed the script at the prompt and this line never printed."

**Location:** `test/cc-isolated-functions.bats:483-484`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-automated-gate
**Scope:** Covers whether the two added assertions discriminate old from new behavior — specifically whether `[ "$status" -eq 1 ]` alone would have passed under the old code (it would) and whether the output assertion is what carries the discrimination (it is). Does not establish that the test would catch a *different* regression in the same block (e.g. a `y` reply mis-parsed), which no case in this file covers.

The complete test body, read to its closing brace:

```bash
# test/cc-isolated-functions.bats:474-489
@test "install.sh assembles the payload when every source is present" {
  ...
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

Executed against both `install.sh` versions under the same fixture: old gives `OLD_EXIT=1`/`OLD_ABORTED_LINE=no`, new gives `NEW_EXIT=1`/`NEW_ABORTED_LINE=yes` (log and provenance in Claim 1). So `[ "$status" -eq 1 ]` alone would have passed under the old code — the comment's implicit point, and the reason the commit message calls the message "the assertion with teeth", is correct. The suite itself is green: `bats -f "install.sh" test/cc-isolated-functions.bats`, cwd `/workspace`, `1..5`, five `ok`, exit 0, 2026-09-12T12:16.

**Evidence:** `test/cc-isolated-functions.bats:474-489`, `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/logs/install-old-vs-new.txt`, `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/logs/install-tests.txt`

---

## Claim 15: commit 8980861 — "All 5 install.sh tests pass"

**Location:** commit message `8980861`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-automated-gate
**Scope:** Covers the count and the pass status of the `install.sh` tests in `test/cc-isolated-functions.bats` at HEAD. Does not establish the count at `8980861` itself (no `install.sh` test was added or removed in `435f46a`, so the count is the same), nor that five is the right number of cases.

```
# scratchpad/logs/install-tests.txt
1..5
ok 1 install.sh stages the payload from the repo root
ok 2 install.sh aborts when a payload source is missing
ok 3 install.sh names every missing payload source, not just the first
ok 4 install.sh assembles the payload when every source is present
ok 5 every regular file in install.sh's PAYLOAD is hashed by enforcement_files
```

Command `bats -f "install.sh" test/cc-isolated-functions.bats`; cwd `/workspace`; exit code 0; 2026-09-12T12:16.

**Evidence:** `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/logs/install-tests.txt`

---

## Claim 16: commit 435f46a — "Fast suite: 623 passed, 0 failed"

**Location:** commit message `435f46a`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-automated-gate
**Scope:** Covers the fast-category suite total and failure count at HEAD, including the seven new grammar tests. Does not cover the slow category (not run), and does not establish that the pre-change total was 616.

Matches exactly — 623 `ok`, zero `not ok`, TAP plan `1..623`:

```
# scratchpad/logs/fast-suite.txt
1..623
...
ok 623 convention workflows have at least 3 process steps
```

Command `bash scripts/run-tests.sh --fast`; cwd `/workspace`; exit code 0; 2026-09-12T12:17:51-07:00. Counted mechanically: `grep -cE "^ok "` → 623, `grep -cE "^not ok "` → 0. This claim is the exact shape of the three logged hallucination patterns (a test-count denominator asserted in a commit message), including the closest prior match — *"All 85 tests across the code-review suites pass" claimed in commit 59ca38f … but the suites hold 97*, first seen 2026-09-12. This one holds up under the same check that refuted that one.

**Evidence:** `/tmp/claude-1000/-workspace/069518a5-919f-46b0-ba81-1e00bce5effa/scratchpad/logs/fast-suite.txt`, `scripts/run-tests.sh:1-40`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9** (`docs/working/questions.md:11`): Q6 names `scripts/dd-cross-model-sweep.py` as a consumer of the `anthropic/claude-sonnet-5` pin; that script's `MODELS` list holds only kimi-k3, gpt-5.6-sol and gemini-3.1-pro-preview and it references no Anthropic model. Fix: the sole consumer is `cross-model-review.py`'s `--judge` default. The entry's conclusion (moot by scope) is unaffected. **Routing note:** this text lives in an editable working doc, not in an already-merged commit message, so it is a normal rubric finding — no override-log routing is triggered by anything in this report.

### Stale
- **Claim 4** (`docs/decisions/log.md:69`): row 48's pointer `lite-review.py:24-26` now lands on the ownership wording rather than the "copied from" wording it describes, and the questions.md item it says is "tracked" is closed. Row 49 directly below records the resolution; consider a "superseded by row 49" marker rather than editing the dated row.

### Mostly Accurate
- **Claim 2b** (`docs/decisions/log.md:69`): `--model` is an unvalidated pass-through; `claude-sonnet-5` is well-formed and matches the CLI's documented full-name form, but has never been exercised from this repo and would fail at runtime, not at argument-parse time, if wrong.
- **Claim 3** (`docs/decisions/log.md:69`): "stay frozen" is true behaviorally, but `cross-model-review.py` was edited (comment-only) in the same commit range; say "functionally frozen".
- **Claim 10b** (`docs/working/questions.md:11`): what is wired into pr-prep/review-fix-loop is `--mode fix-drift`, a comment/doc-drift-only check; the `--mode full` diff-only review has no wired caller. Tighten the sentence so the "Sonnet 5 is just a flag" inference names the mode it would apply to.
- **Claim 11** (`scripts/cross-model-review.py:135-138`): "It was byte-identical" is true of the regex only — the two `parse_findings` implementations already differ in `NONE` case-sensitivity, block detection, `parse_ok` derivation, and row keys. Since the comment's audience is the fork deciding how to "keep it in step", naming the regex explicitly matters.
- **Claim 12** (`scripts/lite-review.py:24-28`): comparability with the E2/E3 lite-arm artifacts holds at the finding-line grammar; the artifacts carry the harness's `sev`/`desc` keys, not this file's `severity`/`description`.
- **Claim 13** (`scripts/lite-review.py:29-31`, `test/lite-review-grammar.bats:5-10`): mutation testing shows the suite catches narrowing changes (dropping `re.IGNORECASE`, making the line range mandatory) but not widening ones (a new severity value, an optional description, a looser path pattern) — all three shipped 7/7 green.

### Unverifiable
- None.

---

## Goal-Alignment Note

**Answered.** The user's goal was to review the last three commits on main before treating the work as settled, and this pass verified the checkable claims across all three. The load-bearing factual claims hold under execution: the `install.sh` EOF fix behaves as its comment and test say (old exits 1 silently, new exits 1 with `Aborted. Nothing was changed.`), the two `FINDING_RE` blocks are byte-identical by SHA-256, the seven grammar tests exist and pass keyless/offline, and both test-count claims in the commit messages (5 install.sh, 623 fast) match a live run — notable because that exact claim shape has produced three confirmed hallucinations in this repo.

**Out of scope.** Whether moving grammar ownership was the right call, whether the test suite should be broadened, whether `--judge` should abort rather than warn, and whether row 48's scope decision is correct — all design judgments belonging to the critics and the user. Also out of scope: any live `claude`/OpenRouter call (no egress, no Anthropic credential, and calls cost money).

**Escalate.** One item, low urgency: Claim 13's mutation evidence contradicts the strength of "pins the shape" in `lite-review.py`'s header and log row 49. Since the stated purpose of that suite is to hold the contract *after* `cross-model-review.py` leaves for the SWRBench fork, the fact that widening mutations pass green is worth a decision — either broaden the suite (a rejecting case per field) or soften the claim in the header and the log row. This is the only finding that touches the commits' stated goal rather than their prose.

**Questions I would have asked.**
1. Row 48 says the harness "stays frozen", and row 49 edits it the same day. Should `log.md` rows be treated as amendable when a later row supersedes them, or should row 49 carry an explicit "supersedes the frozen-scope wording in 48" clause?
2. `--mode full` has no wired caller anywhere in the repo. Is that intentional (the mode is for manual use), or is it a wiring gap that the "the production diff-only review already runs via lite-review.py" framing has been papering over?
