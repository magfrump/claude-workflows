# Code Fact-Check Report

**Commit:** 435f46a
**Replication:** k=3
**Repository:** /workspace
**Scope:** `git diff 3a94fdc~1..HEAD` — commits `3a94fdc`, `8980861`, `435f46a`; files `devcontainer-config/install.sh`, `docs/decisions/log.md`, `docs/working/questions.md`, `scripts/cross-model-review.py`, `scripts/lite-review.py`, `test/cc-isolated-functions.bats`, `test/lite-review-grammar.bats`, plus the three commit messages
**Checked:** 2026-09-12
**Total claims checked:** 19 clusters merged from three replicates (r1: 19 claims, r2: 17, r3: 17)
**Summary:** 12 Verified, 5 Mostly accurate, 1 Stale, 1 Incorrect, 0 Unverifiable-only clusters

Merged most-severe-wins from `code-fact-check-report-r{1,2,3}.md`. Verdicts are the
replicates'; annotations merge by union. Execution logs under `docs/reviews/execution-logs/`.

---

## Claim 1: `install.sh`'s `|| reply=""` comment — EOF previously died at `read` under errexit before the abort line printed; now falls through to the abort case

**Location:** `devcontainer-config/install.sh:102-106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: all three rebuilt the payload fixture at `8980861~1` and at HEAD — old exits 1 with no `Aborted.` line, new exits 1 with it · r2: "does not establish anything about other non-interactive callers (e.g. `--yes`)"
**Scope:** Covers both halves of the comment for the `ASSUME_YES != --yes` branch, read to the end of the enclosing `if`/`case`. Does not establish behavior of the `--yes` path.
**Evidence:** `devcontainer-config/install.sh:106` — `read -r reply || reply=""`; A/B runs in `docs/reviews/execution-logs/r2-*`, `r3-install-eof-old-vs-new.txt`.

---

## Claim 2: "a Sonnet 5 pass is `--model claude-sonnet-5`, a flag, not a build"

**Location:** `docs/decisions/log.md:69`, `docs/working/questions.md:11`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: "does not establish that the string `claude-sonnet-5` is a value the CLI accepts" · r2: executed `claude --model claude-sonnet-5` → `canonicalModel":"claude-sonnet-5"`, `provider":"firstParty"`, `is_error:false`
**Scope:** Covers the plumbing — `--model` is parsed, defaulted and passed verbatim to `claude` argv with no code change required.
**Evidence:** `scripts/lite-review.py:136` (`--model` default), `:112` (`"--model", model` in argv).

---

## Claim 2b: that `claude-sonnet-5` is a value that actually resolves

**Location:** `docs/decisions/log.md:69`, `docs/working/questions.md:11`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed (r2) / static (r1, r3)
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (executed) · r3=Unverifiable
**Replicate annotations:** r2: resolved live on this machine — `canonicalModel":"claude-sonnet-5"`, `provider":"firstParty"` · r1+r3: `--model` is an unvalidated pass-through, so a wrong id fails at runtime rather than at parse time; the only Claude-CLI id pinned in-repo is the fully-dated `claude-haiku-4-5-20251001`
**Scope:** Merged verdict follows most-severe-wins and therefore reads more cautiously than r2's executed check, which did resolve the id. The residual caveat is the unvalidated pass-through, not the id itself.
**Evidence:** `scripts/lite-review.py:36` (`DEFAULT_MODEL = "claude-haiku-4-5-20251001"`), `:111-126` (argv assembly).

---

## Claim 3: log row 48 — the two sweep scripts "stay frozen and are not to be run from here"

**Location:** `docs/decisions/log.md:69`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Verified
**Replicate annotations:** r1: "stay frozen" was contradicted comment-only by `435f46a` in the same range — "functionally frozen" is the precise form · r3: "does not establish that any mechanism enforces the freeze"
**Scope:** Covers the two files' identities and that the diff leaves both functionally unmodified. No mechanism enforces the directive.
**Evidence:** `scripts/cross-model-review.py:135-138` (comment added in the same range).

---

## Claim 4: log row 48's pointer `lite-review.py:24-26` to the "copied from" wording

**Location:** `docs/decisions/log.md:69`
**Type:** Documentation
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Verified (checked at the parent commit) · r3=Verified (checked as part of the cross-reference set)
**Replicate annotations:** r1: the cited range now lands on the *ownership* wording, not the "copied from" wording the row describes, and the questions.md item it calls "tracked" is closed; row 49 records the resolution — a "superseded by 49" marker beats editing a dated row · r2: the citation was accurate at the moment row 48 was written
**Scope:** Covers whether the cited line range still contains the text the row describes, at HEAD. Does not touch row 48's substantive judgment.
**Evidence:** `docs/decisions/log.md:69`; `scripts/lite-review.py:24-31` at HEAD.

---

## Claim 5: log row 48 — the unpriced-`--judge` pre-flight WARNING shipped in `cb5351d`

**Location:** `docs/decisions/log.md:69`
**Type:** Documentation
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-automated-gate
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish that the warning fires on every unpriced-judge path"
**Scope:** Covers that `cb5351d` exists and added the pre-flight judge warning, and that pin and warning are unchanged by this diff.
**Evidence:** commit `cb5351d`; `scripts/cross-model-review.py` judge pre-flight.

---

## Claim 6: log row 49 / both file headers — "the two regexes were byte-identical at the moment ownership moved"

**Location:** `docs/decisions/log.md:70`, `scripts/lite-review.py:25-26`, `scripts/cross-model-review.py:136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: SHA-256 of both blocks identical · r2: pattern string *and* flags compared at `435f46a` · r3: extracted and compared at both `3a94fdc~1` and HEAD (sha256 prefix `c1490d5383e227b6`) · all three: "does not establish that the *parsers* around the regex agree"
**Scope:** Covers the `FINDING_RE = re.compile(...)` block in each file, character for character. Does not extend to `parse_findings`.
**Evidence:** `scripts/lite-review.py:68-72`, `scripts/cross-model-review.py:135-140`.

---

## Claim 7: "test/lite-review-grammar.bats pins the shape"

**Location:** `scripts/lite-review.py:28-31`, `docs/decisions/log.md:70`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** All three replicates independently mutation-tested `FINDING_RE`. Caught: dropping `re.IGNORECASE` (r1), making the line range mandatory / deleting the line-range group (r1, r3). NOT caught — 7/7 still green: adding a severity value such as `Blocker` (r1, r2, r3), making the description optional `.+`→`.*` (r1, r3), letting the path group swallow `:` (r1), widening the row prefix to accept `- ` bullets (r3), narrowing the line-range class from `[\d\-, ]+` to `[\d\-]+` so comma-separated line lists are silently dropped (r2). · r2: "no test reads `FINDING_RE`" · r1: "the suite catches narrowing, misses widening — material given the file's stated job is to hold the contract after the harness leaves"
**Scope:** Covers what the seven tests constrain when `FINDING_RE` is mutated, measured by mutation. The count (7), the subject (`parse_findings`), and keyless/offline operation are separately Verified (Claim 15).
**Evidence:** `test/lite-review-grammar.bats`; mutation runs in `docs/reviews/execution-logs/r3-finding-re-mutations.txt`.

---

## Claim 8: questions.md Q2 — "the exit status alone does not discriminate (both old and new behavior exit 1)"

**Location:** `docs/working/questions.md:7`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish that the test's other assertions are necessary"
**Scope:** Covers the EOF-stdin path with a complete payload, old versus new.
**Evidence:** A/B execution logs, all three replicates.

---

## Claim 9: questions.md Q6 — "the only consumers of the pin are `scripts/cross-model-review.py` and the archival `scripts/dd-cross-model-sweep.py`"

**Location:** `docs/working/questions.md:11`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** All three: wrong in both directions. (a) `scripts/dd-cross-model-sweep.py` consumes the pin not at all — no `anthropic/` slug, no judge concept; `MODELS = ["moonshotai/kimi-k3", "openai/gpt-5.6-sol", "google/gemini-3.1-pro-preview"]` at `:30`. (b) r2+r3: an unnamed third consumer exists at `archive/benchmark/scripts/review-arms.py:69,73`, a tracked file that also reads `OPENROUTER_API_KEY`. · r3: that file is currently unrunnable — its `ENGINE = os.path.join(HERE, "cross-model-review.py")` (`:52`) points at a path that does not exist in `archive/benchmark/scripts/`, so it raises at import · r2: it is a wrapper *over* the harness, so it would follow the harness to the fork · All three: the entry's **conclusion** ("neither on the production path") survives — all real consumers are benchmark/archive · All three: this is an editable working doc, not an immutable commit message, so no override-log routing is triggered.
**Scope:** Covers which files reference the literal pin `anthropic/claude-sonnet-5`. Does not dispute the conclusion drawn from the enumeration.
**Evidence:** `scripts/cross-model-review.py:378`, `archive/benchmark/scripts/review-arms.py:69,73`, `scripts/dd-cross-model-sweep.py:30`.

---

## Claim 10: Q6 — "wired into `workflows/pr-prep.md` Step 3 and `workflows/review-fix-loop.md`"

**Location:** `docs/working/questions.md:11`
**Type:** Documentation
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: "does not establish which *mode* is invoked" — see Claim 11.
**Scope:** Covers that both workflow docs contain a concrete `lite-review.py` invocation and that pr-prep's sits inside its numbered step 3.
**Evidence:** `workflows/pr-prep.md:218`, `workflows/review-fix-loop.md:69`.

---

## Claim 11: Q6 / log row 48 — "the production diff-only review already runs on the Claude subscription via `scripts/lite-review.py`"

**Location:** `docs/working/questions.md:11`, `docs/decisions/log.md:69`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: `--mode full` has **no wired caller** — both pr-prep §3c and review-fix-loop invoke only `--mode fix-drift`, a comment/doc-drift check that the workflow text explicitly says is "not a second reviewer". The "production diff-only review already runs via lite-review.py" framing, and the "Sonnet 5 is just a flag" inference resting on it, apply to a mode nothing currently runs.
**Scope:** Covers what the wired workflows actually invoke. Does not dispute that the subscription backend is real.
**Evidence:** `workflows/pr-prep.md:218` (`--mode fix-drift`), `workflows/review-fix-loop.md:69` (`--mode fix-drift`), `scripts/lite-review.py:135` (`--mode` choices).

---

## Claim 12: `cross-model-review.py`'s new comment — "The FINDINGS grammar is DEFINED by scripts/lite-review.py … this is the copy"

**Location:** `scripts/cross-model-review.py:135-138`
**Type:** Documentation
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: "does not establish that 'DEFINED by' is true of `parse_findings` semantics, which have diverged" — the comment's referent is the regex it is attached to, and for that it is exact.
**Scope:** Covers the comment's referent (the `FINDING_RE` definition) and the existence of log row 48.
**Evidence:** `scripts/cross-model-review.py:135-138`.

---

## Claim 13: `lite-review.py` header — "This file OWNS the FINDINGS grammar and its regex … so output stays comparable with the E2/E3 lite-arm artifacts"

**Location:** `scripts/lite-review.py:24-31`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Replicate annotations:** All three: the regex is byte-identical and the prompt format-spec lines match, but the two `parse_findings` bodies have **already diverged**, in four ways — (1) `FINDINGS: NONE` case-sensitivity, (2) block detection (`startswith` vs regex), (3) `parse_ok` derivation (`bool(rows) or "FINDINGS" in text` vs `in_block`), (4) row keys / severity capitalization. · r1: the E2/E3 artifacts carry the harness's `sev`/`desc` keys, not lite-review's `severity`/`description` — comparability holds at the line grammar, not the record schema · r2: worked divergent inputs — `"findings: none"` → lite `(…, False)` / cross `(…, True)`; `"FINDINGS :"` header → lite parses no rows / cross parses one; `"I cannot emit FINDINGS for this diff."` → lite `parse_ok=True` / cross `False`. **That last one is lite-review's substring check marking a model refusal as a successful clean review** — on the live path. Pre-existing, not introduced by this diff. · r2 escalated this as a behavioral question for a critic to judge on its merits.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Scope:** Covers what constitutes "the grammar" beyond `FINDING_RE`. "Owns the grammar" is precise for the wire format and regex, not for parse semantics.
**Evidence:** `scripts/lite-review.py:82-103`, `scripts/cross-model-review.py` `parse_findings`.

---

## Claim 14: bats comment — "before `read -r reply || reply=\"\"`, errexit killed the script at the prompt and this line never printed"

**Location:** `test/cc-isolated-functions.bats:483-484`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-automated-gate
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** All three confirmed by A/B run that `[ "$status" -eq 1 ]` alone would have passed under the old code, so the message assertion is the discriminating one.
**Scope:** Covers the discriminating power of the two added assertions.
**Evidence:** A/B execution logs.

---

## Claim 15: "7 contract tests over `parse_findings`, keyless and offline since the parser is pure" / "nothing but this file holds the shape"

**Location:** `docs/decisions/log.md:70`, `test/lite-review-grammar.bats:6-12`, commit `435f46a`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-automated-gate
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: re-ran with `ANTHROPIC_API_KEY`/`AUTH_TOKEN` unset · r3: every test exercises `parse_findings` with no `claude` spawn · r2: no other test file references `parse_findings` or `FINDING_RE` · Note: the *count* and *purity* are Verified; how much the suite constrains is Claim 7.
**Scope:** Covers test count, subject under test, and keyless/offline operation.
**Evidence:** `bats test/lite-review-grammar.bats` → 7/7, `docs/reviews/execution-logs/r3-lite-review-grammar.txt`.

---

## Claim 16: commit `8980861` — "All 5 install.sh tests pass"

**Location:** commit message `8980861`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-automated-gate
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: "does not establish the count at `8980861` itself — only HEAD was measured"
**Scope:** Covers the count and pass state at HEAD.
**Evidence:** `bats test/cc-isolated-functions.bats -f 'install.sh'` → 5/5.

---

## Claim 17: commit `435f46a` — "Fast suite: 623 passed, 0 failed"

**Location:** commit message `435f46a`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-automated-gate
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: flagged that this claim has the exact shape of the three logged hallucination-pattern entries (a measured value quoted from an artifact set) and executed it for that reason — it held · r2+r3: exactly `1..623`, 0 `not ok` · All: does not cover the slow category (not run).
**Scope:** Covers the fast-category total and failure count at HEAD.
**Evidence:** `scripts/run-tests.sh --fast`, `docs/reviews/execution-logs/r3-fast-suite.txt`.

---

## Claim 18: commit `435f46a` — "questions.md now has no open entries"

**Location:** commit `435f46a`, `docs/working/questions.md:7-13`
**Type:** Documentation
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: "does not establish that every closed entry's answer is substantively correct — Claim 9 shows one is not"
**Scope:** Covers unchecked (`- [ ]`) versus checked (`- [x]`) entries at HEAD: 0 open, 8 checked.
**Evidence:** `docs/working/questions.md`.

---

## Claim 19: Q4 / commit `435f46a` — "churn across 19 links at 17 sites"

**Location:** `docs/working/questions.md:9`, commit `435f46a`
**Type:** Measurement
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Unverifiable
**Replicate annotations:** r2: the figure is A10's snapshot; the same method gives 21 links from 21 sites today · r3: three plausible counting rules give 11/2, 46/17 and 18/4 — none gives 19/17, and A10's counting rule is not recorded; "same shape as the logged hallucination-pattern class, but not refutable here" · Both: the figure is inherited from the A10 review, not authored by this diff.
**Scope:** Covers whether the figure can be reproduced today. Does not establish it was wrong when A10 recorded it.
**Evidence:** `docs/working/questions.md:9`.

---

## Escalations

| # | Entry | `path:line` | Raised by | Addressee |
|---|---|---|---|---|
| E1 | `parse_findings`' `parse_ok = bool(rows) or "FINDINGS" in text` marks a model refusal ("I cannot emit FINDINGS for this diff.") as a successful clean review, on the live review path. Pre-existing; the ownership claim does not cover it. Behavioral question to judge on its merits. | `scripts/lite-review.py:103` | r2 | security-reviewer / api-consistency-reviewer |
| E2 | The new grammar suite constrains narrowing but not widening of `FINDING_RE`; the file's stated job is to hold the contract after the harness leaves. | `test/lite-review-grammar.bats`, `scripts/lite-review.py:28-31` | r1, r2, r3 | api-consistency-reviewer |
| E3 | `--mode full` has no wired caller; only `--mode fix-drift` is invoked by either workflow. | `scripts/lite-review.py:135`, `workflows/pr-prep.md:218` | r1 | api-consistency-reviewer / orchestrator |
| E4 | `archive/benchmark/scripts/review-arms.py` is a tracked OpenRouter consumer that is unrunnable at HEAD (`ENGINE` points at a non-existent path) and was missed by the Q6 scope call. | `archive/benchmark/scripts/review-arms.py:52,69,73` | r2, r3 | orchestrator |

## Claims Requiring Attention

- **Incorrect:** Claim 9 (Q6 consumer enumeration).
- **Stale:** Claim 4 (log row 48's `lite-review.py:24-26` pointer).
- **Mostly accurate:** Claims 2b, 3, 7, 11, 12, 13, 19.

## Verdict stability

- **Total clusters:** 19
- **Clusters where all reporting replicates agreed:** 12
- **Clusters with disagreement:** 7 — Claim 2b (Mostly accurate / Verified / Unverifiable), Claim 3 (Mostly accurate / — / Verified), Claim 4 (Stale / Verified / Verified), Claim 11 (Mostly accurate / Verified / Verified), Claim 12 (Mostly accurate / Verified / Verified), Claim 19 (— / Mostly accurate / Unverifiable), Claim 15 vs 7 split (all three agreed once the count claim and the strength claim were separated).
- **Agreement rate:** 12/19 = 63%.
- Note: every disagreement is a *severity* disagreement on a documentation-strength claim, not a contested fact. The three replicates agreed unanimously on all four executed behavioral clusters and on the single Incorrect. The agreement rate is well below the ≥90% threshold that would license dropping to k=2.

---

## Submitted Claims (Stage 2.5)

Verdicted from `docs/reviews/code-fact-check-submitted-claims.md` (k=1, opus). 4 Verified,
1 Mostly accurate, 1 Incorrect; 5 of 6 executed.

| # | Submitting critic | Claim | Verdict | Mode |
|---|---|---|---|---|
| SC1a | security-reviewer | The bless prompt fails closed on every stdin shape but a literal `y`/`yes` | Mostly accurate | executed |
| SC1b | security-reviewer | The assignment in `\|\| reply=""` is load-bearing — `\|\| true` blesses on `printf 'y'` | Verified | executed |
| SC2 | security-reviewer | No call site in diff scope builds a shell string; all argv-form | Verified | static (enumerated) |
| SC3a | api-consistency-reviewer | The three recommended negative tests **fail** against the current `FINDING_RE` | Incorrect | executed |
| SC3b | api-consistency-reviewer | Each recommended test catches its targeted widening mutation | Verified | executed |
| SC4 | api-consistency-reviewer | `in_block or bool(rows)` leaves all seven tests green | Verified | executed |

Material residues:
- **SC1a:** "a literal `y`/`yes`" understates the matcher — `[yY]|[yY][eE][sS]` plus `read`'s
  whitespace stripping means `Y`, `YES` and ` y` all bless.
- **SC1b:** the partial-read shape (`printf 'y'`) is the **only** stdin shape on which
  `|| reply=""` and `|| true` differ. `</dev/null`, the shape the new test uses, behaves
  identically under both — so the property the chosen spelling actually buys is untested and
  unrecorded; the comment and commit message both motivate it via errexit-on-EOF instead.
- **SC3a:** all three recommended inputs yield zero rows against the *current* regex, so the
  tests would land green, not red. That is the right state for a regression pin, but the
  submitted sentence asserts the opposite.
- **SC4:** the one-line change fixes `"I cannot emit FINDINGS for this diff."` (HEAD: prints
  `FINDINGS: NONE`, exit 0 → changed: `PARSE FAILURE`, exit 2) but does **not** close the class:
  `"FINDINGS: I cannot review this diff."` sets `in_block` and still exits 0 as a clean pass.
  Closing it needs `main()`'s empty-block arm to require the `NONE` sentinel. Also: the submitted
  location `:103` is off by five — the derivation is at `scripts/lite-review.py:108`.
