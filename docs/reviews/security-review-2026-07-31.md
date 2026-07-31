# Security Review — exp/cross-model-openrouter-sweep

Commit: 62594fb

**Scope:** `git diff main...HEAD` — reviewable surface: `scripts/cross-model-review.py`, `scripts/dd-cross-model-sweep.py`, `scripts/self-improvement.sh` (Gate 1h hunk), `skills/code-review/SKILL.md`, `test/skills/code-review-factcheck-replication.bats`, `test/skills/code-review-soundness-crosscheck.bats`, docs changes. `runs/` artifacts and pre-existing `docs/reviews/` reports treated as immutable evidence.
**Date:** 2026-07-31
**Based on:** Stage-1 fact-check findings supplied by the orchestrator (binary-file crash in `sh()`; whole-file inlining into third-party prompts). Referenced, not re-verified.

## Trust Boundary Map

```
B1 (new):     [target repo files & diffs]        → [build_stage1_context / sh(git)]   → [prompt sent to OpenRouter → third-party model providers]
B2:           [OPENROUTER_API_KEY env var]       → [Authorization: Bearer header]     → [openrouter.ai over TLS]
B3:           [model API responses (untrusted)]  → [parse_findings / judge_same]      → [findings.jsonl, overlap metrics]
B4 (new):     [branch-committed report files]    → [Gate 1h sed/case parsing]         → [advisory replication metric in gate detail]
B5:           [OpenRouter pricing API response]  → [fetch_pricing]                    → [--max-usd spend-guard decision]
B6 (new):     [git-tracked replicate reports]    → [orchestrator merge / cross-checks per SKILL.md] → [rubric verdicts]
```

The dominant new flow is B1: decision-021 Stage-1 enrichment reads arbitrary repo content (`git show`, sibling-branch diffs) and ships it verbatim to external model APIs, with the section labels themselves built from that untrusted content's surroundings. B4 and B6 both parse review artifacts that a hostile branch can pre-commit; both are advisory by design, which correctly bounds their blast radius. The diff assumes the target repo is trusted on two axes — it contains no secrets (B1 outbound) and no prompt-shaped markers (B1 inbound to the model) — and neither assumption is enforced anywhere.

## Findings

#### Section-marker spoofing: inlined repo content can forge prompt boundaries in the Stage-1 template

**Severity:** Medium
**Location:** `scripts/cross-model-review.py:78-94, 138-175`
**Boundary:** B1
**Move:** #2 (implicit sanitization assumption)
**Confidence:** High
**Legibility-target:** for-author

The Stage-1 prompt's integrity model rests entirely on the `=== UNDER REVIEW ===` / `=== ... CONTEXT ONLY ===` labels (the module docstring calls the labelling "a build requirement, not decoration"). But `build_stage1_context` inlines file contents and sibling diffs with no escaping or uniquifying of those markers: a repo file (or a hunk in the sibling diff) containing a line `=== UNDER REVIEW (...) ===` or `=== ALREADY COMMITTED - CONTEXT ONLY ===` forges a section boundary, letting a hostile or merely unlucky repo relabel context as under-review (fabricating findings) or relabel the reviewed diff as already-committed (suppressing findings). Note the harness's own artifacts are self-triggering: `runs/dd-cross-model-2026-07-30/prompt.md` and any archived review reports contain exactly these marker strings, so a sweep over this very branch would hit the collision without any attacker.

**Recommendation:** Uniquify the delimiters with a per-run nonce (the repo already has this exact pattern in Gate 1h's `CR_NONCE`) and tell the model only nonce-tagged markers are structural; or escape lines beginning `=== ` in inlined content. Stamp the chosen scheme into `prompt_sha`-adjacent metadata so runs remain comparable.

#### Whole-file and sibling-diff contents shipped to third-party APIs with no secret screening

**Severity:** Medium
**Location:** `scripts/cross-model-review.py:122-175` (build), `319` (diff), `354-360` (dry-run persistence)
**Boundary:** B1
**Move:** #6 (follow the secrets) / #1
**Confidence:** Medium (exploitability depends on what the target repo contains)
**Legibility-target:** for-author

`--context-base` widens the outbound surface from "the reviewed diff" to (a) the full post-range contents of every touched file and (b) the entire sibling-branch diff from an arbitrary ref — all sent to OpenRouter and routed onward to whichever model providers back the chosen slugs. Nothing filters secret-like content (`.env`, key material, tokens in config or test fixtures), and the diff adds no warning that pointing `--repo`/`--context-base` at a repo with committed secrets exfiltrates them to multiple third parties in one command. `--dry-run` additionally persists the full assembled prompt (all file contents included) to `<out>/prompt.txt`, and `runs/` directories are committed in this repo by convention — a plausible path for repo-external content to end up in git history.

**Recommendation:** Document the trust expectation in the usage docstring ("everything reachable from --range/--context-base is transmitted to third-party APIs"). Cheap hardening: run a secret-pattern scan (high-entropy strings, `-----BEGIN`, `sk-…`/`AKIA…` shapes) over the assembled context and require an explicit override to send on a hit; add `prompt.txt` to the run-dir `.gitignore` guidance.

#### Committed binary/non-UTF-8 file aborts the sweep mid-run (NUL check is unreachable for undecodable files)

**Severity:** Low
**Location:** `scripts/cross-model-review.py:109-111, 154, 160`
**Boundary:** B1
**Move:** #3 (error path)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis (corroborates the Stage-1 fact-check finding)

`sh()` uses `text=True` with default strict decoding, so `git show {right}:{path}` on a committed binary raises `UnicodeDecodeError` inside `subprocess.run` — before the `"\x00" in content[:8192]` binary guard at line 160 can ever run for the files it was written for. The only handled failure is `CalledProcessError` (deletion/rename). Effect: any touched binary file crashes the whole run, uncaught — and because the crash happens during context build it wastes nothing, but the same `sh()` is used for the diff itself, so a repo engineered (or merely structured) to include non-UTF-8 blobs denies the harness entirely. Robustness/DoS-adjacent when pointed at untrusted repos, per the fact-check.

**Recommendation:** In `sh()` (or a bytes-mode variant for `git show`), capture bytes and decode with `errors="replace"`, and run the NUL check on the raw bytes; keep the existing skip-with-reason path.

#### Cost guard fails open when pricing is unavailable or a model id is unknown

**Severity:** Low
**Location:** `scripts/cross-model-review.py:202-214, 333-338, 361-362`
**Boundary:** B5
**Move:** #3 (error path) / #8 (a million of these)
**Confidence:** High
**Legibility-target:** for-author

`fetch_pricing` swallows every exception and returns `{}`, and the projection loop uses `pricing.get(m, (0, 0))` — so a failed/blocked pricing fetch, an expired key at the pricing endpoint, or a typo'd/renamed model id yields a projected spend of $0.00 and `--max-usd` never trips, while the actual completion calls proceed at real prices. The guard exists specifically to bound spend before sending; its failure mode is silent approval. (The `get` default predates this diff; the diff's `if key else {}` extends the same fail-open pattern.)

**Recommendation:** When `--models` is non-empty and any requested model is absent from the pricing map (or the fetch failed), refuse to send without an explicit `--no-cost-guard`-style override, or at minimum print a loud "cost guard inactive" warning instead of "$0.00".

#### Gate 1h stale-report guard is skippable by omitting the `Commit:` line, and matches by unanchored prefix

**Severity:** Low
**Location:** `scripts/self-improvement.sh:1489-1515`
**Boundary:** B4
**Move:** #5 (invert the access control model)
**Confidence:** High
**Legibility-target:** for-author

The staleness check only fires when `CR_FC_COMMIT` is non-empty (`[ -n "$CR_FC_COMMIT" ] && …`). A branch that pre-commits `docs/reviews/code-fact-check-report.md` containing `**Replication:** k=3` and *no* `Commit:` line — surviving to the archive if the reviewer fails to overwrite it — is accepted as full-replication rather than flagged stale, defeating exactly the "stale report carried in from an earlier commit is invisible" scenario the hunk's own comment names. Secondarily, `[ "${CR_COMMIT#"$CR_FC_COMMIT"}" = "$CR_COMMIT" ]` is a prefix match: a report stating `Commit: a` passes for ~1/16 of HEADs. Impact is bounded because the check is deliberately advisory (correct stance, per the repo's unvalidated-mechanism rule) — the harm is polluting the `factcheck_replication` metric this gate exists to make trustworthy. The shell hygiene itself is good: quoted expansions, literal `case` patterns, `head -1` bounds, `jq --arg`.

**Recommendation:** Treat a readable report with a missing/empty `Commit:` line as `stale` (untrusted), not as clean; require the extracted commit to be ≥7 hex chars before using it in the prefix match.

#### Non-ASCII/special filenames are silently mislabeled as "deleted or renamed" in the context

**Severity:** Informational
**Location:** `scripts/cross-model-review.py:149-159`
**Boundary:** B1
**Move:** #3 (error path)
**Confidence:** Medium
**Legibility-target:** for-author

With git's default `core.quotepath=true`, `git diff --name-only` emits non-ASCII paths quoted and escaped (`"\346…"`); feeding that string to `git show {right}:{path}` fails, and the `CalledProcessError` handler asserts to the model that the file "does not exist at {right} - deleted or renamed by the diff" — a false statement inlined into the review prompt, steering models toward misattribution for repos with such filenames. Not attacker-leverage beyond what B1's marker finding already covers, but a trust-degrading mislabel. Fix: add `-z` (NUL-delimited) or `-c core.quotepath=false` to the `--name-only` call, and word the fallback message as "could not be read" rather than asserting deletion.

#### dd-cross-model-sweep.py has no spend guard

**Severity:** Informational
**Location:** `scripts/dd-cross-model-sweep.py:31-40`
**Boundary:** B2
**Move:** #8
**Confidence:** High
**Legibility-target:** for-author

Unlike its sibling harness, the sweep runner has no `--max-usd` analogue and requests `max_tokens: 48000` per model (×3 models ×2 attempts). Operator-invoked with an operator-authored prompt, so this is hardening, not a vulnerability: a one-line projected-cost print (or reusing `fetch_pricing`) before sending would match the repo's stated cost-guard posture. Secrets handling is otherwise clean (env-only key, TLS default verification, no shell).

#### SKILL.md replicate-report trust rests on `Commit:` lines without stating the missing-line case

**Severity:** Informational
**Location:** `skills/code-review/SKILL.md:290-302, 655-658, 992-997`
**Boundary:** B6
**Move:** #5
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The stale-replicate guard and both cross-checks filter `code-fact-check-report-r*.md` "by `Commit:` line" but never say what to do with a report that *lacks* one — the same default-allow gap as the Gate 1h finding above, mirrored at the orchestrator layer: a git-tracked replicate report without a `Commit:` line is neither matched nor excluded by the stated rule, and an orchestrator reading the guard literally may include it. Spoofing a *matching* SHA in-branch is infeasible (the file's own commit hash is unpredictable), so the residual risk is inherited-stale, not forged-fresh, and the injected observations can only make the review harsher (dropping/contesting ✅ rows), never suppress findings — hence Informational. Beyond this, the new instructions do not induce exfiltration or execution: the pre-dispatch delete is scoped to git-tracked, recoverable files; the soundness channel quotes only local repo content into local artifacts; and its 🟡-terminal / no-corroboration design keeps an unvalidated mechanism away from blocking authority. Suggested one-line fix: "a replicate report with no `Commit:` line is treated as stale."

## What Looks Good

- **Argv-exec discipline (decision 018) holds everywhere in the diff**: `sh()` and all git invocations are list-argv with `shell` never set; no string interpolation reaches a shell in either Python script.
- **Key lifecycle is clean in both scripts**: `OPENROUTER_API_KEY` read from env only, sent solely as a Bearer header over TLS-verified `urllib` (default context), never placed in argv, filenames, JSONL rows, or log lines; `--dry-run` without a key genuinely makes zero network calls (pricing fetch gated on `key`).
- **Gate 1h shell hygiene**: quoted prefix-removal (`${CR_COMMIT#"$CR_FC_COMMIT"}`) neutralizes glob metacharacters from file content, `case` patterns are literals, extracted values are bounded by `head -1` and passed via `jq --arg` — no injection path from a crafted report into the shell or the JSON detail.
- **Fail-closed verdict spine preserved**: the new advisory checks are additive; the nonced sentinel, exit-status fail-closed, and no-verdict fail-closed paths are untouched, and the diff correctly keeps unvalidated mechanisms (replication check, soundness channel) at advisory/🟡 authority.
- **Per-run error isolation** in the sweep loop records failures as structured rows instead of aborting, and errored runs are excluded from overlap rather than scored as agreement.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Section-marker spoofing in Stage-1 prompt | Medium | B1 | `scripts/cross-model-review.py:78-94,138-175` | High |
| 2 | Whole-file/sibling-diff exfiltration, no secret screening | Medium | B1 | `scripts/cross-model-review.py:122-175,354-360` | Medium |
| 3 | Binary file crashes sweep (NUL guard unreachable) | Low | B1 | `scripts/cross-model-review.py:109-111,154` | High |
| 4 | Cost guard fails open on missing pricing | Low | B5 | `scripts/cross-model-review.py:202-214,333-338` | High |
| 5 | Gate 1h stale guard skippable via absent `Commit:` line; prefix match | Low | B4 | `scripts/self-improvement.sh:1489-1515` | High |
| 6 | Special filenames mislabeled "deleted" in context | Informational | B1 | `scripts/cross-model-review.py:149-159` | Medium |
| 7 | dd-sweep runner has no spend guard | Informational | B2 | `scripts/dd-cross-model-sweep.py:31-40` | High |
| 8 | SKILL.md missing-`Commit:`-line case unstated | Informational | B6 | `skills/code-review/SKILL.md:290-302` | Medium |

## Overall Assessment

The security posture of this diff is solid at the mechanics layer — argv-exec, key handling, TLS, and the Gate 1h quoting are all done carefully, and the repo's "advisory until validated" discipline correctly bounds every new mechanism's authority. The genuinely new risk is concentrated in one design decision: decision-021 context enrichment turns the harness from "sends a diff" into "sends arbitrary repo content to multiple third-party model providers," and the prompt's integrity depends on section markers that the shipped content can trivially forge (including by this repo's own committed artifacts). Both Medium findings are fixable in place — nonce-tagged delimiters and a documented trust expectation plus a cheap secret scan — and fixing the marker issue first matters most, because the harness's measurement validity (not just its security) rests on the labels meaning what they say.

## Goal-Alignment Note

- **Answered:** OPENROUTER_API_KEY handling and header construction in both scripts (clean — finding-free, see What Looks Good); subprocess/argv discipline per decision 018 (holds, no shell=True anywhere); `build_stage1_context` exfiltration surface and marker injection-safety (findings 1, 2); path handling from `git diff --name-only` (findings 3, 6); Gate 1h sed/case parsing of report files (finding 5 — quoting is safe, the logic gap is the missing-Commit bypass); whether the SKILL.md changes could induce an orchestrator to exfiltrate or execute untrusted content (no — finding 8 covers the one residual trust gap).
- **Out of scope:** correctness of the Jaccard/judge pipeline (pre-existing `"YES" in upper()` substring parse in `judge_same` is a metrics-correctness weakness, not security — noting for the performance/consistency critics); the immutable `runs/` artifacts and prior review reports; prior-review author notes A2/A4/A12 (nothing in this diff's security surface contradicts them).
- **Escalate:** none — no HALT-pattern matches (no plaintext secrets, no disabled TLS, no command injection, no missing auth, no hardcoded keys). Finding 1 should be fixed before the Stage-1 arm's measurements are treated as valid, but it does not meet the near-certain-exploitability bar for human escalation.
