# API Consistency Review — questions.md closeout (3a94fdc~1..HEAD)

Commit: 435f46a

**Scope:** `git diff 3a94fdc~1..HEAD` in `/workspace` — commits 3a94fdc, 8980861, 435f46a.
Files: `devcontainer-config/install.sh`, `docs/decisions/log.md`, `docs/working/questions.md`,
`scripts/cross-model-review.py`, `scripts/lite-review.py`, `test/cc-isolated-functions.bats`,
`test/lite-review-grammar.bats`.
**Date:** 2026-09-12
**Based on:** `docs/reviews/code-fact-check-report.md` (merged, k=3). Escalations E1, E2, E3 are
routed to this critic; each is answered below. Behavioral facts established there are cited, not
re-verified.

---

## Baseline Conventions

Surveyed before judging the diff:

- **The FINDINGS record is the consumer-facing contract of the review path.** It has three
  surfaces, not one: (1) the *emit* spec — the literal grammar line inside each prompt template
  that tells the model what to print; (2) the *accept* spec — `FINDING_RE`; (3) the *record*
  spec — the dict keys `parse_findings` returns and that downstream code and on-disk artifacts
  bind to. All three are consumer-facing; only (2) is named by the ownership move.
- **Severity vocabulary.** `Critical / High / Medium / Low / Informational` is the repo's canonical
  critic-native severity set, mapped to rubric tiers in
  `skills/code-review/references/rubric.md:269-271` and restated at `:304-306`. `FINDING_RE`'s
  severity alternation matches it exactly.
- **Script CLI conventions.** `devcontainer-config/cc-isolated.sh:477-489` parses flags with a
  `while`/`case`/`shift` loop that terminates on an unknown flag (`-*) echo "ERROR: unknown flag"`).
  `scripts/lite-review.py:137-147` uses `argparse` with `choices=` on the closed-vocabulary flag
  (`--mode`) and free strings elsewhere.
- **Exit-status conventions on the lite path.** `0` = reviewed (findings or none), `2` = parse
  failure, `sys.exit(str)` = 1 with a message for operational aborts. `install.sh` aborts with 1
  and an explanation line.
- **Test-suite conventions.** `test/cross-model-review-stage1.bats:1-15` establishes the shape the
  new suite follows: `#!/usr/bin/env bats`, `# @category fast`, a `setup_file()` that computes and
  exports `REPO_ROOT`, keyless/offline, and an exported `SCRIPT` var for the script under test.

---

## Name-Pattern Audit

The diff introduces **no new runtime public names** — no new flags, modes, fields, functions, or
config keys in `scripts/lite-review.py` or `scripts/cross-model-review.py`; those two files change
only in comments. The new public names are in the test surface and the decision log. Audited
anyway per the skill's requirement:

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `test/lite-review-grammar.bats` | test file | `test/cross-model-review-stage1.bats`, `test/claude-headless-flags.bats`, `test/link-claude-home-wiring.bats` | `test/*.bats` | Consistent — `<subject>-<aspect>.bats`, `# @category fast` header present |
| `setup_file()` + exported `REPO_ROOT` | test fixture | `setup_file()` / `REPO_ROOT` in `test/cross-model-review-stage1.bats:10-14` | `test/cross-model-review-stage1.bats:10-15` | Consistent — same idiom; see Finding 9 for the one omitted member (`SCRIPT`) |
| `parse()` (bats helper) | test helper | `run_dry()` (`test/cross-model-review-stage1.bats:37`), `fake_install_repo()` (`test/cc-isolated-functions.bats:~460`) | `test/*.bats` | Consistent — bare verb helper wrapping the subject under test |
| decision log rows `48`, `49` | doc record | rows `45`, `46`, `47` | `docs/decisions/log.md:64-68` | Consistent — same column shape and monotonic numbering |
| `reply=""` (fallback value) | shell local | `reply` (same block, pre-existing) | `devcontainer-config/install.sh:101-108` | Consistent — reuses the existing variable; empty string falls into the existing `*)` arm |

Names the diff *documents ownership of* but does not rename — `FINDING_RE`, `parse_findings`, the
row keys — are audited as contract surfaces in the Findings below rather than as new names.

---

## Findings

#### 1. The ownership move covers the regex; the contract consumers bind to is `parse_findings`, and it has already diverged

**Severity:** Inconsistent
**Location:** `scripts/lite-review.py:24-31, 86-108`; `scripts/cross-model-review.py:135-144, 300-320`
**Move:** #3 (trace the consumer contract)
**Confidence:** High

The header asserts ownership over "the FINDINGS grammar and its regex" and instructs the fork to
keep the copy "in step", but the only artifact the two files actually share is `FINDING_RE`. The
two `parse_findings` bodies — the functions that *are* the grammar as far as any caller is
concerned — were already divergent at the moment ownership moved (fact-check Claim 13: four
divergences, with worked inputs). A fork told to keep "the grammar" in step will diff the regex,
find it identical, and conclude it is in step while three behaviors and the record schema differ.

**Evidence** — `scripts/lite-review.py:24-31` (complete header bullet):

```
- This file OWNS the FINDINGS grammar and its regex (decision log 48). The
  grammar originated in cross-model-review.py and the two were byte-identical
  when ownership moved here, so output stays comparable with the E2/E3
  lite-arm artifacts; cross-model-review.py is now the copy, and it is the
  OpenRouter benchmark harness, out of scope for this repo. Changing the
  grammar here breaks that comparability - test/lite-review-grammar.bats
  pins the shape, and any change to it needs a matching note in the decision
  log.
```

`scripts/lite-review.py:86-108` — `parse_findings` in full, signature to `return`:

```python
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
        if not in_block:
            continue
        m = FINDING_RE.match(line)
        if m:
            rows.append({
                "path": m.group("path").strip(),
                "lines": (m.group("lines") or "").strip(),
                "severity": m.group("sev").capitalize(),
                "domain": m.group("domain").strip(),
                "title": m.group("title").strip(),
                "description": m.group("desc").strip(),
            })
    return rows, bool(rows) or "FINDINGS" in text
```

`scripts/cross-model-review.py:300-320` — the copy's counterpart, same span:

```python
def parse_findings(text):
    """Parse the FINDINGS block; returns (findings, parse_ok)."""
    if re.search(r"FINDINGS:\s*NONE", text, re.IGNORECASE):
        return [], True
    rows = []
    in_block = False
    for line in text.splitlines():
        if re.match(r"\s*FINDINGS\s*:", line):
            in_block = True
            continue
        if not in_block:
            continue
        m = FINDING_RE.match(line)
        if m:
            d = {k: (v.strip() if v else v) for k, v in m.groupdict().items()}
            # normalize basename-shorthand hazard: keep both raw and basename
            d["basename"] = os.path.basename(d["path"])
            lines = re.findall(r"\d+", d.get("lines") or "")
            d["line_start"] = int(lines[0]) if lines else None
            d["line_end"] = int(lines[-1]) if lines else d["line_start"]
            rows.append(d)
    return rows, in_block or bool(rows)
```

**Recommendation:** Reword the two comments to say *regex*, not *grammar*, where byte-identity is
being asserted, and add one sentence naming the four known parser divergences so the fork inherits
the list rather than rediscovering it. This is a comment fix, not a code fix — do not "converge"
the two parsers now; the harness's `basename`/`line_start` enrichment is load-bearing for
`stage1_candidates` (`scripts/cross-model-review.py:322-330`).

---

#### 2. The record schema is asymmetric between owner and copy, and the artifacts on disk carry the copy's keys

**Severity:** Inconsistent
**Location:** `scripts/lite-review.py:100-107`; `scripts/cross-model-review.py:312-320`
**Move:** #7 (asymmetry) — naming-shaped, precedent line below
**Confidence:** High

Precedent: `sev` / `desc` / `basename` / `line_start` / `line_end` row keys used in
`scripts/cross-model-review.py:312-320`, `scripts/cross-model-review.py:337-338`, and
`archive/benchmark/scripts/canon-to-crb.py:126-129`.

The owner emits `severity` / `title` / `description`; the copy emits the raw group names `sev` /
`desc` plus three derived keys. Every downstream artifact consumer in this repo binds to the
copy's spelling — `canon-to-crb.py:126-129` reads `fnd.get('desc')` and `fnd.get('line_start')` —
and fact-check replicate r1 established that the E2/E3 lite-arm artifacts on disk carry `sev`/`desc`
too. So the header's "output stays comparable with the E2/E3 lite-arm artifacts" is true of the
**line grammar** and false of the **record**: a tool that reads an old lite-arm artifact and a fresh
`findings.json` from `--out` needs two field maps.

**Evidence** — `scripts/lite-review.py:100-107` (the `rows.append` block; the enclosing function
continues to `return rows, bool(rows) or "FINDINGS" in text` at :108, quoted in full in Finding 1):

```python
            rows.append({
                "path": m.group("path").strip(),
                "lines": (m.group("lines") or "").strip(),
                "severity": m.group("sev").capitalize(),
                "domain": m.group("domain").strip(),
                "title": m.group("title").strip(),
                "description": m.group("desc").strip(),
            })
```

`archive/benchmark/scripts/canon-to-crb.py:126-129` — a repo consumer bound to the copy's keys:

```python
                body = f"**{fnd.get('title', '').strip()}**\n\n{fnd.get('desc', '').strip()}"
                    "path": fnd.get("path"),
                    "line": fnd.get("line_start"),
```

**Recommendation:** Narrow the comparability claim in `scripts/lite-review.py:26-27` to the line
grammar, and say explicitly that the JSON record schema is *not* shared. If cross-artifact tooling
is wanted later, the owner should publish the mapping rather than either side renaming keys — a
rename here is a breaking change for the archived benchmark consumers.

---

#### 3. Only the accept side of the grammar got an owner; the emit side lives in four unpinned prompt strings

**Severity:** Inconsistent
**Location:** `scripts/lite-review.py:49-57, 59-71`; `scripts/cross-model-review.py:94-102, 112-131`
**Move:** #7 (asymmetry) / #3
**Confidence:** High

A grammar has two halves: what the model is told to print and what the parser accepts. The
ownership comment and the new test suite cover only the parser. The emit spec is duplicated
verbatim in four prompt templates — twice inside the owning file itself — with nothing tying them
to `FINDING_RE`. Editing `PROMPT_FULL`'s format line (adding a column, renaming a severity)
desynchronizes the emit spec from the accept spec with no test failure anywhere: the grammar suite
never reads a prompt template, and the live symptom is a silent `parse_ok=False` in production.

**Evidence** — `scripts/lite-review.py:49-57`, `PROMPT_FULL` in full:

```python
PROMPT_FULL = """You are reviewing a code diff. Review for: correctness bugs, security issues, performance problems, API/consistency drift, misleading docs/comments. Report only findings that matter - do not pad. Output format, exactly:

FINDINGS:
1. <path>:<lines> | <Critical/High/Medium/Low/Informational> | <domain> | <short title> | <1-2 sentence description>

(or the single line "FINDINGS: NONE"). Nothing after the list.

=== DIFF ({label}) ===
{diff}"""
```

The identical format block recurs at `scripts/lite-review.py:65-68` (inside `PROMPT_FIX_DRIFT`,
which continues to `{diff}"""` at :71), at `scripts/cross-model-review.py:96-99` (inside
`PROMPT_TEMPLATE`, continuing to `{diff}"""` at :102), and at
`scripts/cross-model-review.py:121-124` (inside `PROMPT_TEMPLATE_STAGE1`, continuing through the
nonce-delimited section list to `{context}"""` at :131).

**Recommendation:** Hoist the four-line format block into one module constant in
`scripts/lite-review.py` (e.g. `GRAMMAR_SPEC`) interpolated into both local prompts, and add one
test asserting that the spec string and `FINDING_RE` agree on the severity alternation — a
`for sev in ("Critical", ..., "Informational")` round-trip is enough. That makes the ownership
claim cover the half of the contract the model actually reads.

---

#### 4. The new grammar suite pins narrowing only; widenings that break documented consumers pass 7/7

**Severity:** Inconsistent
**Location:** `test/lite-review-grammar.bats:1-97`; claim at `scripts/lite-review.py:28-31`
**Move:** #3 (consumer contract) — answers escalation **E2**
**Confidence:** High

Fact-check Claim 7 established by mutation that five contract-altering widenings survive all seven
tests, including "adding a severity value (`Blocker`)", "letting the path group swallow `:`", and
"narrowing the line-range class from `[\d\-, ]+` to `[\d\-]+`". Each has a named consumer:

- A new severity value has **no row** in the unified mapping at
  `skills/code-review/references/rubric.md:269-271` (`Critical, High` / `Medium` / `Low,
  Informational`), so a finding carrying it maps to no rubric tier and is dropped at synthesis.
- A path group that swallows `:` breaks the `<path>:<lines>` split that
  `scripts/lite-review.py:202` renders (`loc = f"{f['path']}:{f['lines']}" if f["lines"] else …`)
  and that the harness's `line_start` derivation depends on.
- Dropping comma-separated line lists silently discards locations for multi-hunk findings.

The file's own stated job is to be what holds the contract after the harness leaves
(`test/lite-review-grammar.bats:6-10`), which makes one-directionality the gap that matters: after
the move there is no second implementation to diff against, so the suite is the whole defense.

**Evidence** — `test/lite-review-grammar.bats:3-10` (the file's stated remit; the header comment
continues to the `Keyless and offline` line at :12):

```
# Contract tests for the FINDINGS grammar, which scripts/lite-review.py owns.
#
# The grammar used to live in scripts/cross-model-review.py, with lite-review
# documenting its copy as a copy. cross-model-review is the OpenRouter benchmark
# harness and is out of scope for this repo (decision log 48), so the live path
# now owns the definition and these tests are what keeps it honest — the two
# regexes were byte-identical when ownership moved, and nothing but this file
# holds the shape in place once the harness leaves.
```

All seven `@test` bodies assert on *accepted* input; none asserts that a non-conforming line is
**rejected** (`test/lite-review-grammar.bats:33-97`, the last test ending at the closing `}` on
:97). The nearest thing is the malformed-row test at :88-97, and it asserts only `[]` rows for a
`- ` bullet — which is exactly the mutation (widening the row prefix to accept `- `) that the
fact-check found passes after the regex is widened, because the test would then still see one row
and the assertion `[ "${lines[1]}" = "[]" ]` is the only thing standing between the two states.

**Recommendation:** Add three negative tests, each asserting **zero rows**: an unknown severity
(`Blocker`), an empty description (`… | Title |`), and a `- ` bullet row. Add one positive test for
a comma-separated range (`a.py:10,14-16`) so the `[\d\-, ]+` class cannot be narrowed silently.
Five lines each; they convert the suite from one-directional to a real contract pin.

---

#### 5. `parse_ok`'s substring fallback reports a model refusal as a clean review, and the new tests freeze that semantics

**Severity:** Inconsistent
**Location:** `scripts/lite-review.py:108`, `:193-199`; `test/lite-review-grammar.bats:78-97`
**Move:** #4 (error consistency) — answers escalation **E1**
**Confidence:** High

`parse_ok` falls back to a substring search over the *entire* response, so any output that merely
contains the word `FINDINGS` — including a refusal like `"I cannot emit FINDINGS for this diff."` —
takes the success path: `parse_ok=True`, `n_findings=0`, `main()` prints
`lite-review [fix-drift]: FINDINGS: NONE` and returns `0`. On the wired path
(`workflows/pr-prep.md:218`, `workflows/review-fix-loop.md:69`) that is indistinguishable from a
genuine clean fix-drift pass. The copy does not have this behavior — it derives `parse_ok` from
`in_block` (`scripts/cross-model-review.py:320`), so the same input yields `False` there.

The defect is pre-existing and out of the diff's stated scope; what the diff changes is its
status. Test 6 and test 7 now encode the two poles of this behavior as *the contract*, and the
header at `:28-31` points at the suite as what holds the grammar — so the error semantics are now
pinned in the divergent direction, and the fork is told to keep in step with it.

**Evidence** — `scripts/lite-review.py:108` (final line of `parse_findings`, quoted in full in
Finding 1):

```python
    return rows, bool(rows) or "FINDINGS" in text
```

`scripts/lite-review.py:193-199` — the consumer of that flag (the enclosing `main()` continues
through the per-finding print loop to `return 0` at :205):

```python
    if not parse_ok:
        print(f"lite-review: PARSE FAILURE - raw output:\n{text}")
        return 2
    if not findings:
        print(f"lite-review [{args.mode}]: FINDINGS: NONE "
              f"({record['tokens']['output']} out-tokens)")
        return 0
```

`test/lite-review-grammar.bats:78-86` — test 6, which pins the negative pole with an input that
happens to avoid the substring (the test body ends at the closing `}` on :86):

```
@test "output with no FINDINGS block at all reports a parse failure" {
  # The distinction that matters operationally: an empty finding list is only
  # trustworthy when the model actually emitted the block.
  run parse 'I was unable to review this diff.'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "False" ]
  [ "${lines[1]}" = "[]" ]
}
```

**Recommendation:** Change `:108` to `return rows, in_block or bool(rows)` — this matches the copy,
removes the divergence, and costs nothing: `in_block` is already computed two lines above. Then add
the refusal case (`'I cannot emit FINDINGS for this diff.'` → `False`) as an eighth test, which is
the input that distinguishes the two implementations. I am flagging the interface consequence only;
the behavioral severity of a refusal reading as a green fix-drift pass is the orchestrator's call
(route: security-reviewer / orchestrator, per E1's dual addressing).

---

#### 6. Inside the owner, the `NONE` sentinel is case-sensitive while every other match is case-insensitive

**Severity:** Minor
**Location:** `scripts/lite-review.py:88`, `:73-78`
**Move:** #4 (error consistency) / #7
**Confidence:** High

`FINDING_RE` carries `re.IGNORECASE` and the suite pins case-insensitive severities
(`test/lite-review-grammar.bats:56-64`), but the sentinel check at `:88` has no flag. A model that
answers `findings: none` therefore misses the sentinel, matches no rows, and — because `"FINDINGS"
in text` is also case-sensitive — exits `2` as a parse failure. The copy accepts it
(`scripts/cross-model-review.py:302` carries `re.IGNORECASE`). Low probability given the prompt
spells the sentinel in caps, but the inconsistency is inside one function, and it is one of the
four divergences a fork is being asked to reconcile.

**Evidence** — `scripts/lite-review.py:88` versus `scripts/cross-model-review.py:302`:

```python
    if re.search(r"FINDINGS:\s*NONE", text):                 # lite-review.py:88
    if re.search(r"FINDINGS:\s*NONE", text, re.IGNORECASE):  # cross-model-review.py:302
```

`scripts/lite-review.py:73-78`, `FINDING_RE` in full, showing the flag that sets the expectation:

```python
FINDING_RE = re.compile(
    r"^\s*\d+\.\s*(?P<path>[^|:]+?)(?::(?P<lines>[\d\-, ]+))?\s*\|"
    r"\s*(?P<sev>Critical|High|Medium|Low|Informational)\s*\|"
    r"\s*(?P<domain>[^|]+)\|\s*(?P<title>[^|]+)\|\s*(?P<desc>.+)$",
    re.IGNORECASE,
)
```

**Recommendation:** Add `re.IGNORECASE` at `:88` and a test for `findings: none`. Fold it into the
same commit as Finding 5 — both are one-token changes that erase a named divergence.

---

#### 7. `--mode full` is a documented CLI mode with no wired caller

**Severity:** Informational
**Location:** `scripts/lite-review.py:6-14`, `:140`; `workflows/pr-prep.md:218`, `workflows/review-fix-loop.md:69`
**Move:** #3 — answers escalation **E3**
**Confidence:** High

The module docstring advertises two modes as peers and `--mode full` is the **default**, but both
workflow call sites pass `--mode fix-drift` explicitly, so the default value of the flag is never
exercised by any wired consumer. That is the CLI-surface half of a live-path concern: the mode the
grammar-ownership claim is nominally protecting (decision 030's Stage-1 grammar, diff-only) is
reached only by a human typing the command. It also means `PROMPT_FULL` — one of the two emit-side
specs from Finding 3 — has no automated exercise at all.

**Evidence** — `scripts/lite-review.py:140` and the two call sites:

```python
    ap.add_argument("--mode", choices=["full", "fix-drift"], default="full")
```

```
python3 scripts/lite-review.py --repo . --range <last-review-commit>..HEAD --mode fix-drift
```
(`workflows/pr-prep.md:218`)

```
`scripts/lite-review.py --mode fix-drift` over the fix commits before starting the next
```
(`workflows/review-fix-loop.md:69`)

**Recommendation:** Either wire `--mode full` into pr-prep Step 3d as the cheap first pass, or
state in the docstring that `full` is a manual/ad-hoc entry point and flip the default to
`fix-drift` so the default matches the only wired use. Leaving a default nobody selects is the
kind of drift the next reader will misread as coverage.

---

#### 8. `--model` takes free-text ids, and the two in-repo id spellings disagree

**Severity:** Minor
**Location:** `scripts/lite-review.py:41`, `:141`; `docs/decisions/log.md:69`
**Move:** #2 (naming) — precedent line below
**Confidence:** Medium

Precedent: the fully-dated Claude-CLI id form `claude-haiku-4-5-20251001` used in
`scripts/lite-review.py:41`; the bare-alias form `claude-sonnet-5` recommended in
`docs/decisions/log.md:69` and `docs/working/questions.md:11`.

`--mode` gets `choices=`; `--model` is an unvalidated pass-through into `claude` argv
(`scripts/lite-review.py:118-119`). The only id pinned in code is fully dated, while the decision
row that this diff *adds* tells the operator a Sonnet 5 pass is `--model claude-sonnet-5` — a
different naming form. A wrong id surfaces only as a `claude` runtime failure after the call is
dispatched, which on the lite path means after the diff has been sent.

**Evidence** — `scripts/lite-review.py:41` and `:141`:

```python
DEFAULT_MODEL = "claude-haiku-4-5-20251001"
```
```python
    ap.add_argument("--model", default=DEFAULT_MODEL)
```

`docs/decisions/log.md:69` (row 48, first sentence of the Decision cell):

```
The production path already satisfies this (`scripts/lite-review.py`, decision 37) — a Sonnet 5 pass is `--model claude-sonnet-5`, not new code.
```

**Recommendation:** Pick one id form and use it in both places — a dated pin in the code and a
dated pin in the log, or a documented note that the bare alias is deliberate because it floats.
Free-text `--model` is fine and matches how the CLI works; the inconsistency to fix is the
spelling, not the validation.

---

#### 9. Documentation drift on the pointers that justify the scope decision

**Severity:** Minor
**Location:** `docs/decisions/log.md:69` (pointer `lite-review.py:24-26`); `docs/working/questions.md:11`
**Move:** #3 (documentation drift)
**Confidence:** High

Two pointer-level defects, both established upstream (fact-check Claim 4 *Stale*, Claim 9
*Incorrect*), both on the load-bearing sentences of the scope call rather than on prose:

- Row 48's pointer `lite-review.py:24-26` described the "copied from" wording; those lines now hold
  the ownership wording, so the row's own citation contradicts the row above it once 49 landed.
- The Q6 consumer enumeration names `dd-cross-model-sweep.py` (not a consumer of the pin) and omits
  `archive/benchmark/scripts/review-arms.py:69,73`. Since "who consumes this" is the *premise* of
  "the harness can leave", an enumeration that names a non-consumer and misses a real one weakens
  the decision it supports. I confirmed the omitted consumer independently while tracing the
  contract: `review-arms.py:52-58` loads `cross-model-review.py` as a module for
  `stage1_candidates`/`judge_same`, making it a code-level dependent of the copy, not only of the
  pin.

**Evidence** — `archive/benchmark/scripts/review-arms.py:52-58` (the import block; the module
continues into the `ARMS` dict at :69):

```python
ENGINE = os.path.join(HERE, "cross-model-review.py")

# The engine's filename has a dash, so load it as a module for the matching
# helpers (stage1_candidates / judge_same) rather than duplicating them.
_spec = importlib.util.spec_from_file_location("cross_model_review", ENGINE)
cmr = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cmr)
```

**Recommendation:** Repoint row 48 at the questions.md entry (which quotes the old wording verbatim
and will not move) instead of at line numbers in a file the next commit edits, and correct the Q6
enumeration to `cross-model-review.py` + `archive/benchmark/scripts/review-arms.py`. Note that
`ENGINE` resolves to `archive/benchmark/scripts/cross-model-review.py`, which does not exist — that
unrunnability is E4 and belongs to the orchestrator, not to this review.

---

#### 10. `install.sh` accepts only a positional `--yes` and never rejects an unknown flag

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:21`, `:101-108`
**Move:** #2 (naming/CLI surface) — precedent line below
**Confidence:** Medium

Precedent: the `while`/`case`/`shift` loop with an explicit `-*)` unknown-flag arm used in
`devcontainer-config/cc-isolated.sh:477-489`.

`ASSUME_YES="${1:-}"` matches `--yes` only as `$1` and by exact string. `-y`, `--Yes`, or `--yes`
in second position all fall through to the interactive branch. The diff makes this *better* rather
than worse — before it, such a caller died at `read` with no output; now it prints
`Aborted. Nothing was changed.` and exits 1 — but the operator still gets "aborted" rather than
"unknown flag", and the two scripts a host user runs back to back disagree about flag handling.

**Evidence** — `devcontainer-config/install.sh:101-108` (the complete `if` block; the `case`'s
final arm and the closing `fi` at :109-110 follow, and the script continues to `mkdir -p "$DEST"
"$BIN_DIR"` at :112):

```bash
if [ "$ASSUME_YES" != "--yes" ]; then
  printf 'Install this config and bless it? [y/N] '
  # `|| reply=""` so a closed/EOF stdin (piped or non-tty run) falls through to
  # the abort case below instead of dying on `read`'s non-zero exit under
  # `set -e`, which killed the script before it could say why.
  read -r reply || reply=""
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
```

`devcontainer-config/cc-isolated.sh:486` — the convention:

```bash
      -*)           echo "ERROR: unknown flag: $1" >&2; usage >&2; exit 1 ;;
```

**Recommendation:** Optional and out of this diff's stated scope — if picked up, one `case "${1:-}"`
with a `-*)` reject arm brings `install.sh` in line with `cc-isolated.sh`. Do not change the
`--yes` spelling or the exit-1-on-abort status; both are load-bearing for existing callers and for
`test/cc-isolated-functions.bats`.

---

## What Looks Good

- **The EOF fix is non-breaking on every axis a consumer can observe.** Exit status stays 1, the
  `--yes` path is untouched, and the only change is that the existing `Aborted. Nothing was
  changed.` line now actually prints. The strengthened assertion in
  `test/cc-isolated-functions.bats:483-486` pins the message rather than the status, which is
  correct precisely because the status does not discriminate old from new — the test comment says
  so explicitly.
- **Severity vocabulary is consistent end to end.** `FINDING_RE`'s alternation
  (`Critical|High|Medium|Low|Informational`) matches the repo's canonical critic-native set in
  `skills/code-review/references/rubric.md:269-271` and `:304-306`, so a lite finding maps to a
  rubric tier with no translation. This is the part of the contract most worth protecting, and
  Finding 4's recommended negative test is what would protect it.
- **The comment in the copy is directional and names an action.** `cross-model-review.py:135-138`
  tells the fork what to do on divergence ("state in the fork that the two have diverged - do not
  silently re-fork it") rather than only asserting provenance. That is the right shape for a
  cross-repo contract note; Finding 1 asks only that it say *regex* where it says *grammar*.
- **The new test suite matches sibling conventions** — `# @category fast`, `setup_file()` exporting
  `REPO_ROOT`, keyless and offline, `importlib.util.spec_from_file_location` for the hyphenated
  module name. It mirrors `test/cross-model-review-stage1.bats:10-15` closely enough that a reader
  of one can read the other. (One omission: siblings export a `SCRIPT` variable; this file inlines
  `"$REPO_ROOT/scripts/lite-review.py"` inside `parse()`. Not worth a finding — one call site.)
- **Exit-code contract preserved.** `0` reviewed / `2` parse failure / `1` operational abort is
  unchanged by the diff, so wired callers in `workflows/pr-prep.md` and
  `workflows/review-fix-loop.md` see no behavior change.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Ownership claim covers the regex, not `parse_findings`, which already diverged | Inconsistent | `scripts/lite-review.py:24-31,86-108` | High |
| 2 | Record schema asymmetric owner vs copy; artifacts carry the copy's keys | Inconsistent | `scripts/lite-review.py:100-107` | High |
| 3 | Emit side of the grammar unowned and duplicated in four prompt strings | Inconsistent | `scripts/lite-review.py:49-71` | High |
| 4 | Grammar suite pins narrowing only; widenings break named consumers (E2) | Inconsistent | `test/lite-review-grammar.bats:1-97` | High |
| 5 | `parse_ok` substring fallback reads a refusal as a clean review (E1) | Inconsistent | `scripts/lite-review.py:108,193-199` | High |
| 6 | `NONE` sentinel case-sensitive while the row regex is not | Minor | `scripts/lite-review.py:88` | High |
| 7 | `--mode full` documented and defaulted, but unwired (E3) | Informational | `scripts/lite-review.py:140` | High |
| 8 | `--model` free-text; dated pin in code vs bare alias in the log | Minor | `scripts/lite-review.py:41,141` | Medium |
| 9 | Stale row-48 pointer and an incorrect consumer enumeration | Minor | `docs/decisions/log.md:69`, `docs/working/questions.md:11` | High |
| 10 | `install.sh` positional `--yes`, no unknown-flag arm | Minor | `devcontainer-config/install.sh:21,101-108` | Medium |

---

## Overall Assessment

The diff does the thing it says at the level it says it: `lite-review.py` now declares ownership,
the copy is labelled, and a test suite exists where none did. Nothing here is a breaking change —
no flag, mode, field, exit code, or output line changed, so every wired consumer
(`workflows/pr-prep.md:218`, `workflows/review-fix-loop.md:69`, `test/cc-isolated-functions.bats`)
is unaffected. The `install.sh` fix is a clean strict improvement and its test asserts on the one
observable that discriminates the fix from the bug.

The gap is one of **scope of the contract, not of correctness of the claim**. "The grammar" is
three surfaces — emit spec, accept regex, record schema — and the move secured exactly one of them.
The regex is owned, tested (one-directionally), and byte-identical to the copy; the emit spec sits
unreferenced in four string literals; the record schema was never shared and the on-disk artifacts
prove it. A fork reading `cross-model-review.py:135-138` and diffing the regex will correctly
conclude "in step" and be wrong about three behaviors. Findings 1–3 are comment-and-constant work,
fixable in place in well under an hour, and they are what make the ownership claim true as written.

Findings 4, 5 and 6 are the ones I would not ship without: they are each a few lines, they close
the three escalations routed here, and Finding 5 in particular is the one with a live consequence —
on the wired `--mode fix-drift` path a model refusal currently prints `FINDINGS: NONE` and returns
0, which the review-fix loop reads as a clean pass. The diff did not introduce that, but by pinning
the parser as the owned contract it made the behavior normative, and the one-line fix
(`in_block or bool(rows)`) simultaneously erases a documented divergence from the copy. Finding 4's
negative tests are the cheapest durable value in the list: five lines each, and they are the only
thing that will exist after the harness leaves.

---

## Goal-Alignment Note

**Answered.** The user's goal was a review of the last three commits before treating the work as
settled, with the FINDINGS-grammar ownership move as the load-bearing item. I judged whether the
contract is held where the diff claims it is: it is held for `FINDING_RE` and not for the emit spec
or the record schema (Findings 1–3), and the mechanism nominated to hold it after the harness
leaves is one-directional (Finding 4). All three escalations routed to this critic are answered —
E1 at Finding 5, E2 at Finding 4, E3 at Finding 7. Items (a) and (b) of the stated scope are
covered at Findings 9 and 10 respectively.

**Out of scope for this critic.** The behavioral severity of a refusal reading as a green
fix-drift pass (E1) — I report the contract consequence; the blocking decision belongs to
security-reviewer or the orchestrator. E4 (`review-arms.py` unrunnable at HEAD because `ENGINE`
resolves to a non-existent path) is orchestrator-addressed; I note it only where it corrects the
consumer enumeration in Finding 9.

**Escalate.** Nothing new beyond the routed escalations. Every positive assurance in this report
that rests on execution rather than reading — the mutation results behind Finding 4, the byte-
identity of the two `FINDING_RE` blocks, the seven-test pass, the `install.sh` old-vs-new behavior
— is taken from `docs/reviews/code-fact-check-report.md` and is not self-certified here
(route: code-fact-check). The claims I add that would need execution to confirm are: that the three
recommended negative tests in Finding 4 fail against the current regex, and that changing `:108` to
`in_block or bool(rows)` leaves all seven existing tests green (route: code-fact-check).

**Questions I would have asked.**
1. Is `--mode full` intended to stay a manual entry point, or was wiring it into pr-prep Step 3d
   dropped? The answer decides whether Finding 7 is Informational or a coverage gap.
2. After the harness moves to the SWRBench fork, does anything in this repo still need to read an
   E2/E3 lite-arm artifact? If yes, the record-schema asymmetry in Finding 2 needs a published
   field map rather than a narrowed comment.
