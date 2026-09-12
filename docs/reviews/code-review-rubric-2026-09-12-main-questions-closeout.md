# Code Review Rubric

**Scope:** `3a94fdc~1..HEAD` on `main` (7 files, 126 insertions) | **Reviewed:** 2026-09-12 | **Status: 🔴 DOES NOT PASS** — 1 red item unresolved

Pipeline: fact-check k=3 (opus) → 3 core critics in parallel (opus) → submitted-claims pass (k=1, opus).
Delivery mode: self-read. No contextual critics triggered.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | `install.sh` is host-executed and agent-writable, yet sits outside all three gates covering its siblings: not in `PAYLOAD`, so the `diff -ru` review loop never shows its own changes; not in `enforcement_files()`, so it is not manifest-hashed or baked into the config hash; not in `live-verify-gate.sh:57`'s regex — and commit `8980861` modified it carrying no `Live-verified:` trailer. Its own header states the threat model ("edits here are inert"), which is true of every `PAYLOAD` entry and false of this file, which runs on the host and decides which diff the human is shown before the prompt prints. **Pre-existing structural exposure, not introduced by this diff**; the diff is what puts it in scope. | Security | High | `devcontainer-config/install.sh:14,25,83-99` (diff modifies `:103-106`); `devcontainer-config/cc-isolated.sh:107-130`; `hooks/live-verify-gate.sh:57` | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | "The grammar" is three consumer-facing surfaces and the ownership move secured one (the accept spec, `FINDING_RE`). The instruction to the fork — "keep it in step" — is therefore misaddressed: a fork will diff the regex, find it identical, and be wrong about four parser behaviors. | API consistency | Inconsistent | api-consistency F1 (+ fact-check Claim 12) | for-author | — | 🟡 Open | — |
| A2 | Record schema was never shared: the owner emits `severity`/`title`/`description`; the copy and every on-disk artifact and downstream consumer (`archive/benchmark/scripts/canon-to-crb.py:126-129`) bind to `sev`/`desc`/`line_start`. The header's "output stays comparable with the E2/E3 lite-arm artifacts" is true of the line grammar, false of the record. | API consistency | Inconsistent | api-consistency F2 (+ fact-check Claim 13) | for-author | — | 🟡 Open | — |
| A3 | The emit spec — the four-line format block the model actually reads — is duplicated verbatim in four prompt templates, two of them inside the owning file (`lite-review.py:49-57`, `:59-71`). Nothing ties them to `FINDING_RE`; editing one desyncs silently with no test failure. | API consistency | Inconsistent | api-consistency F3 | for-author | — | 🟡 Open | — |
| A4 | The new suite pins narrowing but not widening. Mutations that still pass 7/7: adding a `Blocker` severity, `.+`→`.*` on the description, path group swallowing `:`, row prefix accepting `- ` bullets, and narrowing the line-range class so comma-separated line lists are silently dropped. Each surviving widening has a named consumer — a new severity value has no row in `rubric.md:269-271` and drops at synthesis. **Convergence: api-consistency + fact-check (3/3 replicates) + performance.** | API consistency | Inconsistent | api-consistency F4, fact-check Claim 7, performance F2 | for-author | — | 🟡 Open | — |
| A5 | `parse_findings` reports a model refusal as a clean review: `:88`'s `re.search` is unanchored and `:108`'s `"FINDINGS" in text` is a bare substring over model prose. Executed — `"I cannot emit FINDINGS for this diff."` and an echoed diff literal both yield `parse_ok=True`, 0 rows → `main()` prints `FINDINGS: NONE`, exit 0, which the review-fix loop reads as a clean pass. Pre-existing, but tests 6/7 now pin it as normative. **Convergence: security + api-consistency + fact-check.** **Contested-Soundness:** the new suite's final test says verbatim "callers must not read 'no rows' as 'clean' without checking the raw text" (`test/lite-review-grammar.bats:94-95`), and `main()` at `:196` is the only caller and does exactly that. | Security + API consistency | Medium / Inconsistent / Contested-Soundness | security F3, api-consistency F5, fact-check E1, SC4 | for-author | — | 🟡 Open | — |
| A6 | `FINDING_RE` backtracks super-linearly on a contiguous whitespace run in a non-matching line inside the FINDINGS block. Measured end-to-end: 200 chars → 5.4 ms, 1,600 → 1,039 ms, 3,200 → **7,599 ms** (~O(n^2.8)); a 16,000-space line did not finish in 120 s. Well-formed rows unaffected (2,021-char valid row: 0.068 ms). Inherited, but `435f46a` is the commit declaring this repo the owner. | Performance | Medium | performance F1 (executed) | for-author | — | 🟡 Open | — |
| A7 | `hooks/wiring.json:62-72` declares `live-verify-gate.sh` as PreToolUse/Bash; the live settings file has no such entry. Eleven bats tests exercise the script; nothing tests that it is installed. So every `devcontainer-config/` change is currently committable with no live-verification question asked. Prerequisite for R1's fix. | Security | Medium | security F2 | for-author | — | 🟡 Open | — |
| A8 | Q6's consumer enumeration is wrong in both directions: `dd-cross-model-sweep.py` consumes the pin not at all (`MODELS` at `:30` is Kimi/GPT/Gemini, no judge concept), and `archive/benchmark/scripts/review-arms.py:69,73` — a tracked file that also reads `OPENROUTER_API_KEY` and loads the harness as a *module* — is unnamed. The entry's conclusion ("neither on the production path") survives. Doc-only ⇒ 🟡 under decision 031. **Unanimous across all 3 replicates.** | Fact-check | Incorrect (high confidence), doc-only | fact-check Claim 9, api-consistency F9 | for-author | — | 🟡 Open | — |
| A9 | Decision log row 48's pointer `lite-review.py:24-26` now lands on the ownership wording rather than the "copied from" wording it describes, and the questions.md item it calls "tracked" is closed. Row 49 records the resolution; a "superseded by 49" marker beats editing a dated row. | Fact-check | Stale | fact-check Claim 4 | for-author | — | 🟡 Open | — |
| A10 | `--mode full` is the default and has **no wired caller** — both `workflows/pr-prep.md:218` and `workflows/review-fix-loop.md:69` pass `--mode fix-drift`, a check the workflow text explicitly says is "not a second reviewer". The "production diff-only review already runs via lite-review.py" framing, and the "Sonnet 5 is just a flag" inference resting on it, apply to a mode nothing currently runs. | Fact-check + API consistency | Mostly accurate / Informational | fact-check Claim 11, api-consistency F7 | for-author | — | 🟡 Open | — |
| A11 | `--model` is an unvalidated pass-through to `claude` argv; the only Claude-CLI id pinned in-repo is the fully-dated `claude-haiku-4-5-20251001`, while the docs recommend the bare alias `claude-sonnet-5`. The alias does resolve (executed, r2: `canonicalModel":"claude-sonnet-5"`, `provider":"firstParty"`), so this is a convention split, not a break. | Fact-check + API consistency | Mostly accurate / Minor | fact-check Claim 2b, api-consistency F8 | for-author | — | 🟡 Open | — |
| A12 | Log row 48's "stay frozen" was contradicted comment-only by `435f46a` in the same commit range; "functionally frozen" is the precise form. No mechanism enforces the freeze either way. | Fact-check | Mostly accurate | fact-check Claim 3 | for-author | — | 🟡 Open | — |
| A13 | "19 links at 17 sites" (Q4, restated in `435f46a`'s message) cannot be reproduced: r2's replication of A10's stated method gives 21/21 today; r3 tried three plausible counting rules and got 11/2, 46/17, 18/4 — none gives 19/17, and A10's rule is not recorded. Figure is inherited from the A10 review, not authored here. | Fact-check | Mostly accurate | fact-check Claim 19 | for-author | — | 🟡 Open | — |
| A14 | api-consistency's Finding 4 asserts its three recommended negative tests "fail against the current `FINDING_RE`". Executed: all three yield zero rows against the current regex, so they would land **green** on being added. That is the correct state for a regression pin, but the report's sentence asserts the opposite and would mislead anyone triaging by it. | Fact-check | Incorrect (submitted claim refuted) | api-consistency endorsement, refuted by fact-check (SC3a) | for-author | — | 🟡 Open | — |
| X1 | **Composed.** `parse_findings` has no invariant that a line inside the FINDINGS block is either a well-formed row or the `NONE` sentinel — unmatched lines are silently skipped. That single absence is both why model prose reads as a clean review (A5) and why arbitrary prose reaches the backtracking regex at all (A6). It also makes the two proposed fixes pull in opposite directions: performance's `if "\|" not in line: continue` skips non-row lines *more* silently, while security's fix wants them rejected. The fix that closes both is to reject the block when a line inside it matches neither row nor sentinel. No fragment states this. | Composition | Composed (inherits Medium) | Composition cross-check (fragments: A5, A6, fact-check Claim 13, SC4) | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `--range` reaches `git diff` without a `--` separator; an option-shaped value (`--output=<path>`) gives rc 0, empty stdout → "empty diff", exit 0. Operator-self-inflicted, below the reachable-environment bar. | security F4 | Informational | for-author | — | 🟢 Open |
| C2 | `parse_findings`' block detection differs between owner and copy (`startswith` vs regex), so `"FINDINGS :"` parses one row in the copy and none in the owner. | api-consistency F6 | Minor | for-author | — | 🟢 Open |
| C3 | `install.sh`'s `--yes` flag is positional-matched (`$ASSUME_YES != --yes`) rather than parsed, so it is only honored in first position. | api-consistency F10 | Minor | for-author | — | 🟢 Open |
| C4 | The security critic's stdin-shape endorsement says "a literal `y`/`yes`"; the matcher is `[yY]\|[yY][eE][sS]` plus `read`'s whitespace strip, so `Y`, `YES` and ` y` also bless. Wording only — the fail-closed property holds. | SC1a | Mostly accurate | for-orchestrator-synthesis | — | 🟢 Open |
| C5 | The property `\|\| reply=""` actually buys is untested: `printf 'y'` (partial read at EOF) is the only stdin shape where it differs from `\|\| true`, and the new test uses `</dev/null`, which behaves identically under both. The comment and commit message motivate the fix via errexit-on-EOF instead. | SC1b | Verified (residue) | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. (`docs/reviews/override-log.md` read in full at Step 3.5; its entries table is empty — the log has a format spec and no rows yet.)

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The `install.sh` EOF fix is correct and its test assertion is correctly targeted — the exit status does not discriminate (old and new both exit 1); the `Aborted. Nothing was changed.` message does. | ✅ Confirmed | A/B fixture runs at `8980861~1` and HEAD by all three replicates: old → exit 1, no abort line; new → exit 1 with it. FC Claims 1, 8, 14 (all executed). | fact-check k=3 | for-orchestrator-synthesis |
| The chosen spelling `\|\| reply=""` is load-bearing, not cosmetic: the counterfactual `\|\| true` **blesses** on `printf 'y'` because the partial read at EOF leaves `reply=y`; the assignment discards it. | ✅ Confirmed | Executed against the real `install.sh` via the `fake_install_repo` fixture. SC1b (executed). | Stage-2.5 submitted claim (security-reviewer) | for-author |
| No call site in diff scope constructs a shell string; every external process is launched argv-form. | ✅ Confirmed | Enumerated across all seven diff-scope files, not sampled: two list-form `subprocess.run` calls in `lite-review.py`, one in `cross-model-review.py` with three `gitq + [...]` sites; no `shell=True`, `os.system`, `os.popen`, or `Popen` anywhere. SC2 (static, enumeration executed). | Stage-2.5 submitted claim (security-reviewer) | for-orchestrator-synthesis |
| The two `FINDING_RE` blocks were byte-identical at the moment ownership moved. | ✅ Confirmed | Extracted and compared at both `3a94fdc~1` and HEAD; SHA-256 identical (r1), pattern string *and* flags compared (r2), sha256 prefix `c1490d5383e227b6` (r3). FC Claim 6 (executed, 3/3). | fact-check k=3 | for-orchestrator-synthesis |
| The three commit-message counts hold at HEAD: 5 install.sh tests pass, fast suite `1..623` with 0 `not ok`, 7 grammar tests that spawn no `claude` and need no API key. | ✅ Confirmed | Executed by all three replicates; logs in `docs/reviews/execution-logs/r2-*`, `r3-*`. FC Claims 15, 16, 17. | fact-check k=3 | for-automated-gate |

Scope residue carried forward per the cross-check: the ✅ rows above establish the *counts* and *purity* of the new suite, **not** its strength — how much of the contract it constrains is A4, and it is not a confirmation.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/lite-review.py:86-108` | A5 (security F3 + api F5), A6 (perf F1), FC Claim 13, SC4 | composed → X1 |
| 2 | `devcontainer-config/install.sh:101-111` | R1 (security F1), C3 (api F10), FC Claim 1, SC1 | distinct defects: gating exposure, flag parsing, and comment accuracy share a file, not a mechanism |
| 3 | `docs/decisions/log.md:69` / `docs/working/questions.md:11` | A8 (FC Claim 9 + api F9), A9 (FC Claim 4), A12 (FC Claim 3) | distinct defects: each states its own mechanism and fix completely |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
