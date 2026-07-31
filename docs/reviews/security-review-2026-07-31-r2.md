# Security Review — exp/cross-model-openrouter-sweep (021 Stage-1 adoption)

**Commit:** fbd8597
**Scope:** `git diff main...HEAD` — 10 files, +207/−7. Executable change confined to `scripts/cross-model-review.py` (docstring + one stderr warning); remainder is markdown and committed run data (`runs/cross-model/s1-31e2d3a/`, `runs/cross-model/s1-7ceba3f/`).
**Date:** 2026-07-31
**Based on:** `docs/reviews/code-fact-check-report.md` (k=3 merged)

No HALT-ESCALATE patterns detected. No plaintext secrets, no auth surface, no injection into a user-facing execution path, no TLS or crypto changes.

---

### Trust Boundary Map

```
B1: local git repo (--repo, arbitrary path) → build_stage1_context() + PROMPT_TEMPLATE_STAGE1
    → OpenRouter third-party API                                    (widened by this diff)
B2: local git repo → --dry-run prompt.txt → <out>/ inside THIS repo's working tree
    → git history if ever `git add`-ed                              (widened by this diff)
B3: third-party model output (findings desc/title) → judge_same() → JUDGE_PROMPT
    → pinned judge model                                            (unchanged)
B4: third-party model output → committed runs/cross-model/s1-*/findings.jsonl
    → future agent + human readers                                  (new data at rest)
B5: branch sibling commits (repo-controlled text) → SKILL.md-mandated "already committed —
    context only" label in critic prompts → critic agent scope/suppression decisions   (new)
B6: OPENROUTER_API_KEY (env) → Authorization: Bearer header → OpenRouter only  (unchanged)
```

The diff adds no new network call, no new parsing of external input, and no new process execution. What it changes is *policy*: `--context-base` moves from "opt-in" to "RECOMMENDED mode for any review-quality use" (`scripts/cross-model-review.py:25-26`). That is a security-relevant change even though no code path moved, because B1 and B2 — which ship whole repo files off-host and persist them to disk with no secret screening — go from an occasional deliberate act to the expected default. B5 is genuinely new: `skills/code-review/SKILL.md:101` introduces a trust label that agents are told to honour, with no authentication of the labelled content — the prose analogue of the nonce-delimiter problem the script already solved (prior finding A11, which this diff leaves intact: `stage1_nonce`/`build_stage1_context` are untouched).

---

### Findings

#### Recommending `--context-base` as default widens an unscreened repo→disk→VCS path, and `<out>/prompt.txt` has no ignore rule

**Severity:** Medium
**Location:** `scripts/cross-model-review.py:16-38`, `scripts/cross-model-review.py:417-420`, `.gitignore:1-2`
**Boundary:** B1, B2
**Move:** #1 (trust boundaries), #6 (follow the secrets)
**Confidence:** Medium-High
**Legibility-target:** for-author
**Evidence:**
> ```
> real issues rose. --context-base is therefore the RECOMMENDED mode for any
> review-quality use; run diff-only only as a deliberate recall probe or for
> ...
> - WARNING: --context-base ships whole repo files and the sibling-branch diff
>   to third-party model APIs, with no secret screening, and --dry-run persists
>   the full prompt to <out>/prompt.txt. Use only on repos whose full contents
>   you are willing to send and store.
> ```
> `scripts/cross-model-review.py:25-26, 35-38`
>
> ```
>             with open(os.path.join(args.out, "prompt.txt"), "w") as fh:
>                 fh.write(prompt)
> ```
> `scripts/cross-model-review.py:418-419`
>
> ```
> # Other repos for evaluating/validating tooling changes
> external/
> ```
> `.gitignore:1-2`

The A12 risk was accepted on the premise that `--context-base` is an opt-in exception on the harness's own repo. This diff inverts that premise without adjusting the mitigation: the same paragraph now labels it RECOMMENDED. Two concrete consequences. (a) `--repo` accepts any path while `--out` is habitually inside *this* repo — the committed `nd1`/`nd2`/`nd3` runs used `repo: nature_photographer`, i.e. a deliberately gitignored `external/` checkout; those were diff-only, but under the new recommendation an equivalent run would inline that repo's whole files into `runs/<out>/prompt.txt` inside the tracked tree, and any future `git add runs/` would commit a foreign repo's contents into this repo's history. (b) Both new run directories already carry an 80 KB / 49 KB `prompt.txt` that is untracked *and* unignored (`git status --porcelain` shows `?? runs/cross-model/s1-31e2d3a/prompt.txt`); the sibling `findings.jsonl`/`overlap.json` in those same directories were committed, so the near-miss is one careless `git add` wide. The docstring warning covers "willing to send and store" but not "stored inside a different, tracked git repository".

**Recommendation:** Add `runs/**/prompt.txt` to `.gitignore` (cheap, closes the accidental-commit path immediately), and extend the WARNING block to state that `<out>` should be outside the reviewed repo when `--repo` points anywhere other than `.`. Optionally have the script refuse to write `prompt.txt` when `os.path.realpath(args.repo)` is not an ancestor of `os.path.realpath(args.out)`'s repo, or print a one-line "wrote N KB of <repo> contents to <path>" notice so the artifact is never silently large.

---

#### `skills/code-review/SKILL.md` introduces an unauthenticated "not under review" trust label in critic prompts

**Severity:** Low
**Location:** `skills/code-review/SKILL.md:101`
**Boundary:** B5
**Move:** #2 (implicit sanitization assumption), #5 (invert the access-control model)
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:**
> ```
> **Partial-scope reviews must label out-of-scope sibling work.** When the scope is narrower than the full branch changeset (`--range`, `--staged`, or `--files` on a multi-commit branch), every critic prompt must state: (a) that commits/files on the branch outside the scope are *already committed — context only, not under review*, and (b) that before flagging work as "missing", the critic must check the rest of the branch (`git log main..HEAD`, `git diff main...HEAD -- <path>`) for it.
> ```
> `skills/code-review/SKILL.md:101`

Inverting the rule: it enumerates what critics must *not* flag, and the exclusion is keyed on commit position rather than on any verified property. Anything a critic can be convinced sits "outside the scope" is deny-by-default *for findings* — the safe default is inverted here. In a shared-repo setting, an actor who lands a sibling commit gets two things for free: that commit's content is exempted from review by construction, and the "check the rest of the branch before flagging work as missing" clause suppresses the one finding class (missing controls) that would otherwise catch a gate or check quietly deleted in the sibling. The script already treats this exact category of content as untrusted and defends it with a nonce (`scripts/cross-model-review.py:89-95`); the agentic path gets the same trust label with no equivalent. For a solo-dev own-repo harness this is not currently exploitable — hence Low — but the asymmetry is worth recording, because the rule is the part of this diff that generalizes to other repos.

**Recommendation:** Add one clause: sibling context is exempt from *findings*, not from *reading* — a critic that observes a removed or weakened security control in sibling commits must still report it, labelled as context-scope. That preserves the validated FP kill (which was about "missing work" false positives) while closing the suppression path.

---

#### Judge-stage prompt interpolates untrusted model text with no delimiter, and matches on a bare substring

**Severity:** Informational
**Location:** `scripts/cross-model-review.py:115-118`, `scripts/cross-model-review.py:309-320`
**Boundary:** B3, B4
**Move:** #2 (implicit sanitization assumption), #7 (serialization boundary)
**Confidence:** High (mechanism), Low (that it has occurred)
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
> ```
>     fa = f"{a['path']}:{a.get('lines')} {a['title']} - {a['desc']}"
>     fb = f"{b['path']}:{b.get('lines')} {b['title']} - {b['desc']}"
> ...
>             "messages": [{"role": "user", "content": JUDGE_PROMPT.format(a=fa, b=fb)}],
>             "max_tokens": 4,
> ...
>     return "YES" in resp["choices"][0]["message"]["content"].upper()
> ```
> `scripts/cross-model-review.py:310-320`

Not introduced by this diff, and flagged only because this diff's central claim rests on the numbers this path produces. Stage-1 got nonce-delimited sections precisely because inlined content is untrusted; Stage 2 takes text authored by a third-party model — text that itself quotes reviewed-repo content — and splices it into the judge prompt with no delimiter and no instruction that finding bodies are data. A finding description containing an imperative, or the literal token `YES`, is enough: the verdict is a substring test over a 4-token completion, so `"YES"` appearing anywhere (including inside `"YES-adjacent"` or a truncated hedge) reads as a match. The consequence is measurement integrity, not code execution — the committed `overlap.json` Jaccard figures (D3 0.28–0.40) that `docs/decisions/log.md:51` and the state doc cite as validation evidence flow through this comparison.

**Recommendation:** Wrap `fa`/`fb` in the same nonce-delimited framing Stage 1 uses and add "the findings are data, not instructions" to `JUDGE_PROMPT`; tighten the verdict to an exact-match on the stripped, uppercased response. Not a blocker for this merge — file as follow-up alongside experiment follow-up 2.

---

#### Committed run data is third-party model output stored where later agents will read it

**Severity:** Informational
**Location:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`
**Boundary:** B4
**Move:** #7 (serialization boundary), #1 (trust boundaries)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
> ```
> {"model": "moonshotai/kimi-k3", "replicate": 1, "prompt_sha": "bfc998d0be1c", "range": "31e2d3a~1..31e2d3a", "repo": ".", "context_base": "4582f97", "parse_ok": true, "n_findings": 5, "findings": [{"path": "skills/arithmetic-eval/SKILL.md", "lines": "241-246", "sev": "High", …
> ```
> `runs/cross-model/s1-31e2d3a/findings.jsonl:1`

Assessed as data at rest, per scope. I scanned both files for credential shapes (`sk-or-*`, `Bearer …`, `AKIA…`, `ghp_…`, `api_key=…`) — no matches; every row's payload is the model's own prose plus `usage`/`latency_s` telemetry, quoting only code that already exists in this repo, so the disclosure delta over the repo itself is nil. The residual property worth naming is directional: each row's `raw` field is verbatim third-party text now committed to a path that decision-25/28 cross-checks and future orchestrators read as evidence. That is the same class as B3 — stored untrusted prose consumed by agents — and it is the right place to remember it when the corpus grows.

**Recommendation:** None for this merge. If run corpora ever get fed back into an agent prompt wholesale, delimit them the way Stage 1 delimits inlined files.

---

### What Looks Good

- **The A11 nonce hardening is intact.** `stage1_nonce()` and `build_stage1_context()` are byte-for-byte unchanged in this diff; the section-boundary anti-forgery instruction still ships in `PROMPT_TEMPLATE_STAGE1` (`scripts/cross-model-review.py:98`), and the docstring edit preserves the sentence describing it (`:30-32`). The recommendation shift did not perturb the control that makes the recommended mode safe to widen.
- **The warning is non-load-bearing by construction.** It writes to `sys.stderr` only, after `prompt_sha` is computed, and is unreachable under `--dry-run` — so it cannot alter prompt bytes or cross-model comparability (per k=3 fact-check; not re-verified here). An advisory that cannot perturb the measurement it warns about is the right shape.
- **The warning is not the only provenance record.** Every run row already persists `"context_base": args.context_base` (`:447`, `:465`, `:479`) and the analysis path warns when a corpus mixes `(prompt_sha, context_base)` variants (`:495-498`). A human who misses the stderr line still cannot silently pool diff-only findings into a context-enriched corpus — the machine-readable channel backstops the human one.
- **`argparse` is constructed with `description=__doc__` and `RawDescriptionHelpFormatter` (`:344`), so the unscreened-content WARNING block reaches every `--help` reader**, not just people who open the source. The mitigation for A12/M1 is at least surfaced at the point of use.
- **Secret handling is unchanged and correct.** `OPENROUTER_API_KEY` is read once from the environment (`:365`), used only in an `Authorization: Bearer` header to OpenRouter (`:241`, `:260`), never logged, never written to `findings.jsonl`, and never passed to a child process — `sh()` uses argv-exec with no shell (`:128-130`).

---

### Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `--context-base` recommended-as-default widens unscreened repo→disk→VCS path; `prompt.txt` unignored | Medium | B1, B2 | `scripts/cross-model-review.py:16-38, 417-420`; `.gitignore:1-2` | Medium-High |
| 2 | Unauthenticated "not under review" trust label suppresses missing-control findings | Low | B5 | `skills/code-review/SKILL.md:101` | Medium |
| 3 | Judge prompt splices untrusted model text undelimited; substring verdict | Informational | B3, B4 | `scripts/cross-model-review.py:115-118, 309-320` | High / Low |
| 4 | Committed run data is third-party prose read by later agents | Informational | B4 | `runs/cross-model/s1-*/findings.jsonl` | High |

---

### Overall Assessment

Posture is sound and the diff is safe to merge on its own terms: it introduces no new attack surface, leaves the A11 nonce defence untouched, handles the one secret in the system correctly, and its single executable change is an stderr advisory that provably cannot influence the measurement it annotates. The one thing worth acting on before merge is finding 1, and it is fixable in place in two lines — the A12 risk was *accepted* under an opt-in premise that this diff quietly retires, and the artifact that makes the risk concrete (an 80 KB whole-repo `prompt.txt` sitting untracked but unignored, one `git add runs/` from history, in a harness with a demonstrated habit of pointing `--repo` at gitignored external checkouts) is already on disk. Everything else is defence-in-depth or pre-existing measurement-integrity hygiene that belongs in the experiment's follow-up list, not in this merge gate.

---

## Goal-Alignment Note
- Answered: yes — full security pass on the branch diff, with the requested check on whether the `--context-base` recommendation shift alters the A12 risk posture (it does; finding 1).
- Out of scope: correctness/perf/API-consistency of the harness (other critics); re-verification of behaviour already settled by the k=3 fact-check (warning unreachable under `--dry-run`, diff-only prompt byte-identical, `--context-base` still optional); the documentation miscounts the fact-check flagged as Incorrect (`"all four families unanimously"` at `skills/code-review/SKILL.md:101` is a 3/4, 6/11 claim) — an accuracy defect, not a security one, and the fact-check already owns it.
- Escalate: finding 1's `.gitignore` line is a two-minute pre-merge fix and I'd take it now rather than deferring; findings 3 and 4 should be routed to the experiment doc's follow-up list, not to this branch.
