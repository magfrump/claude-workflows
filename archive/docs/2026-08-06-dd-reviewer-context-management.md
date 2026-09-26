# DD working doc: how should code-review models be given context?

**Goal**: Choose a point (or staged path) on the reviewer-context spectrum — diff-only →
structured enrichment → full agentic repo access — for the cross-model / cheap-critic
review pipeline.
**Project state**: worktree off the cross-model-review sweep line · standalone DD feeding
`docs/decisions/021-reviewer-context-management.md` · not blocked.
**Task status**: complete (decision drafted, Path A/staged recommendation).

This is the off-console full prose for the DD; the archival record is decision 021.

---

## 1.0 Pre-generation grep — prior pruning

Ran `git grep`/`git log` across `exp/cross-model-openrouter-sweep` for
`context / enrich / full file / function body / sibling commit / diff-only / repo access /
agentic / headless` over `docs/decisions/**`, `docs/working/**`, `skills/**`,
`docs/decisions/log.md` (31 rows), and `hypothesis-backlog.md`.

**Prior pruning grep: no matches found for [reviewer context, enrichment, diff-only,
function body, sibling commit, agentic].** No decision record and no `log.md` row treats
reviewer context management. The closest prior artifacts are *evidence*, not a decision:

- `docs/working/experiment-cross-model-review-2026-07-30.md` — Results 3c & 5 (the two
  most severe false positives, both from diff-only misattribution across a boundary the
  diff flattens) and follow-up #5 ("*Consider a second-family critic … it must have repo
  access, not diff-only*"). A recommendation, not a resolved decision.
- `docs/working/experiment-results-code-review-2026-07-29.md` — Result 10 method note:
  "*this headless arm (diff inline, no tools) is … the same configuration
  `scripts/cross-model-review.py` uses*", and Result 8's cross-file ceiling (MD1 R1
  defeated every single-pass run). Describes the tradeoff; does not decide it.
- Two research docs the experiments cite — `research-agentic-review-evidence-vs-repo-setup.md`
  and `research-cross-model-review-hypotheses.md` — are **not in git on any branch**
  (scratchpad only). No committed prior discussion survives.

**Conclusion: this DD is the first real treatment of the decision.**

---

## 1. Diverge — candidates

Anchored by candidate 0 = status quo (diff-only). The spectrum runs left (harness-authored,
deterministic, portable) → right (model-authored retrieval, adaptive, provider-bound).

- **0. Diff-only (status quo).** Harness `PROMPT_TEMPLATE` pastes the unified diff for one
  commit; "*You cannot run commands or read files; judge only from the diff below.*"
  Supplies: only the hunks. Fixes: nothing — it is the thing under review.
- **1. Diff-only + N surrounding lines** (`git diff -U<big>`). Supplies: adjacent unchanged
  lines within each touched file. Fixes: tiny within-file cross-hunk gaps only.
- **2. Function-body enrichment.** For every function/method a hunk touches, append its full
  *current* body (post-change tree) via an AST/symbol extractor. Supplies: the whole
  enclosing function. Fixes: "flagged as missing/wrong" when the handling is elsewhere in
  the same function; Result 3c-style block-boundary confusion.
- **3. Enclosing-file / module enrichment.** Append the whole touched file(s), not just
  hunks — git-only, no AST. Superset of #2 within a file. Fixes: Result 3c fully (both
  heredoc blocks live in one file); all within-file misattribution.
- **4. Sibling-commit / full-changeset enrichment.** Review the *whole logical change*
  (`git diff main...HEAD`, or append the sibling commits' diffs as labelled context)
  instead of one isolated commit. Supplies: code that "landed in a sibling commit." Fixes:
  Result 5 (Tier A/B in sibling commits flagged unanimously as missing) — the exact
  highest-value FP class. Git-only, deterministic, portable.
- **5. Repo map / symbol index.** Append a ctags-style symbol → `file:line` + signature
  index for the repo. Supplies: existence + signatures of symbols outside the diff. Fixes
  (partial): cross-file "X is undefined/missing" FPs — existence, not bodies.
- **6. On-demand constrained file read.** Give the reviewer one read-only tool
  (`read_file`/`grep`). Model-authored retrieval, bounded. Fixes: whatever the model
  chooses to look up (highest recall of the mid-spectrum) — but reintroduces
  non-determinism, defeats prompt-caching, needs per-provider tool plumbing, confounds
  model vs retrieval skill.
- **7. Full agentic repo access (production today).** Reviewer is an agent with
  Read/Grep/Bash in a checkout. Supplies: anything. Fixes: cross-file interaction bugs
  (MD1 R1, caught only by the historical agentic pipeline). Expensive, non-deterministic,
  provider-bound, un-portable.
- **8. Ideal-if-free.** Full agentic + unbounded budget + multi-family multi-sample union.
  Best recall; impractical.
- **9. Reframe — diff-only as a recall probe, re-verified by the agentic incumbent.** Keep
  the cheap portable critics diff-only, but treat their output as *candidates* that the
  production agentic critic (which has repo access) must re-verify before anything
  surfaces. Moves the sibling-commit guard downstream instead of enriching the cheap
  reviewer. Satisfies Result 5's "must have repo access" at the *verification* gate.
- **10. Judge-side enrichment.** Keep reviewers diff-only; give the *judge/synthesis* stage
  repo access to filter sibling-commit FPs post-hoc. Downstream variant of #9.

**Health check.** Do-nothing (#0) ✓; ideal-if-free (#8) ✓; naive (#1) ✓; reframe (#9/#10)
✓. Dimensional spread: *what context is materialized* (1,2,3,4,5), *who materializes it*
(6,7), *where the guard sits* (9,10). Cluster {2,3,5} = "harness pre-computes structural
context" is real but balanced by the who/where axes — not anchored.

---

## 2. Diagnose — constraints

**Hard**
- **H1 — the sibling-commit FP class must be eliminated or made rare.** This is the
  highest-value thing to fix cheaply: the run's two most severe FPs (Results 3c, 5) and its
  highest-*consensus* finding (all four families, several at High, on D4) were all diff-only
  misattributions across a boundary the diff flattens. `success:` re-running the chosen
  harness config on D3 (`31e2d3a`, sibling-heredoc) and D4 (`7ceba3f`, sibling-commit)
  produces **zero** High/Critical findings asserting that code is "missing"/"wrong" which in
  fact exists elsewhere in the same branch — i.e. Results 3c & 5 no longer reproduce.
- **H2 — provider-agnostic / no-tools portable.** `success:` the config runs unchanged
  through `scripts/cross-model-review.py` plain chat-completions against all four families
  (kimi-k3, gpt-5.6-sol, gemini-3.1-pro, claude-sonnet-5) in one sweep, with no
  per-provider tool-calling code path.
- **H3 — preserve confound-control for measurement.** Model identity must not be confounded
  with retrieval/agentic skill. `success:` for a given diff every model receives
  byte-identical harness-authored context (the two rendered prompts differ only in the
  `{diff}`/`{context}` fill), so cross-model finding differences are attributable to the
  model, not to what each chose to fetch.
- **H4 — stay in the cost/latency envelope.** `success:` per-call cost stays in the observed
  ≤~$0.33 median band with no multiplicative tool-round-trip inflation, and a full sweep
  stays < $10 as this run did; single round-trip (no agentic loop).

**Soft**
- **S1** prompt prefix stays cacheable (fixed template + appended context).
- **S2** cross-file interaction-bug recall (MD1 R1 class) — nice to have, explicitly
  acknowledged as beyond any single-pass deterministic config.
- **S3** low implementation complexity — prefer git-only pre-computation over building an
  AST symbol extractor.
- **S4** latency stays single round-trip.

---

## 3. Match and prune

| # | Approach | H1 sibling-FP | H2 portable | H3 confound | H4 cost | Recall | Verdict |
|---|----------|:---:|:---:|:---:|:---:|:---:|---|
| 0 | diff-only | ✗ | ✓ | ✓ | ✓ | low | baseline; fails hard H1 |
| 1 | +context lines | ~ | ✓ | ✓ | ✓ | low | within-file only; too weak |
| 2 | function-body | ~ | ✓ | ✓ | ✓ | ~ | fixes within-function; needs AST (S3 cost) |
| 3 | enclosing file/module | ~+ | ✓ | ✓ | ~ | ~ | fixes Result 3c fully; git-only ✓ |
| 4 | **sibling-commit / branch diff** | **✓** | ✓ | ✓ | ✓ | ~+ | **git-only; kills Result 5 FP class** |
| 5 | repo map / symbol index | ~ | ✓ | ✓ | ~ | ~ | existence only; complements #4 |
| 6 | on-demand file read | ✓ | ✗ | ✗ | ~ | high | fails H2+H3 → out of portable sweep |
| 7 | full agentic | ✓ | ✗ | ✗ | ✗ | highest | production endpoint, not the sweep |
| 8 | ideal-if-free | ✓ | ✗ | ✗ | ✗ | highest | discard (cost) |
| 9 | reframe: probe + agentic re-verify | ✓ | ✓ | ✓ | ✓ | n/a | complementary downstream guard |
| 10 | judge-side enrichment | ✓~ | ✓ | ✓ | ✓ | n/a | downstream variant of #9 |

Discarded on a hard constraint: **#6, #7, #8** (⚠ on H2 and/or H3 — they break exactly the
portability + confound-control that give the cross-model sweep its value). **#1** discarded
as strictly dominated by #3/#4. **#0** retained only as the do-nothing anchor (fails H1).

Survivors into step 4: **#4** (sibling-commit), **#3** (enclosing-file, the git-only
boring version of function-body #2), **#5** (repo map), **#9** (reframe / agentic
re-verify). Fix-sketch for #2/#3: prefer whole-file (#3, git-only) for Stage 1 and reserve
AST function-extraction (#2) for files too large to inline.

---

## 4. Tradeoff matrix, hypotheses, stress-test

Matrix-analysis structure applied inline (survivor set = 4, axes judgment-light and
git-mechanical; single-agent scoring per the workflow's opt-out for mechanically-determined
axes — no sub-agent dispatch, to avoid deep nesting from an already-dispatched agent).

| # | Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|----------|--------|------|:---:|--------------|
| 4 | ★ sibling-commit / branch diff | ● ~1 h (git-only harness edit) | ● low | ● 4/4 | reviews already-merged code unless it is labelled "context, not under review" (mitig.) |
| 3 | enclosing-file enrichment | ● ~1 h | ● low | ◐ 3/4 (H1 within-file only) | doesn't reach sibling-*commit* misattribution |
| 5 | repo map / symbol index | ◐ ~half day (index build) | ◐ med | ◐ 3/4 (existence not bodies) | token cost + staleness; partial H1 |
| 9 | probe + agentic re-verify | ◐ pipeline wiring | ◐ med | ● 4/4 | doesn't fix the cheap reviewer; adds an agentic gate downstream |

**Falsifiable hypotheses**
- **#4**: If we review the full branch changeset instead of one commit, we expect Results 3c
  & 5 to stop reproducing on D3/D4 within a single re-run; counter-evidence = a model still
  flags sibling-commit code as "missing" once that code is present-and-labelled in the
  prompt.
- **#3**: If we inline whole touched files, we expect the Result 3c heredoc-confusion FP to
  vanish; counter-evidence = a model still merges two `<<'PYEOF'` blocks with both bodies
  visible.
- **#5**: If we append a symbol index, we expect cross-file "X undefined/missing" FPs to
  drop; counter-evidence = FP rate on cross-file symbol claims unchanged vs Stage-1.
- **#9**: If cheap diff-only critics feed an agentic re-verify gate, we expect surfaced
  findings to reach the incumbent's precision while cheap critics still add recall (Result
  4's Sol High bugs); counter-evidence = the re-verify gate rejects the real cheap-found
  bugs along with the FPs.

**Stress-test moves**
- **Boring alternative (#2 vs #3/#4)**: the boring version is "just paste whole touched
  files + the full branch diff" — no AST extractor. Function-body extraction (#2) only earns
  its complexity on very large files; for the common case #3/#4 (git-only) get ~80% of the
  benefit. → downgraded #2's effort; Stage 1 is git-only.
- **Invert the thesis (#4)**: argue for keeping diff-only. The sweep's value is
  portability + confound-control — but #4 is *still* deterministic, portable, and
  byte-identical across models, so the inversion doesn't threaten H2/H3; it only adds
  tokens and one real hazard: the model may flag already-merged context as new. →
  mitigation: label sibling-commit context explicitly as "already committed, context only,
  not under review." Added as a build requirement.
- **What-if / push-to-extreme (#6)**: does "request full files on demand" reintroduce
  non-determinism + provider-dependence? Yes — confirmed; that is exactly why #6 is out of
  the portable sweep. And where does structured enrichment *still* fail? Cross-file
  call-graph bugs (MD1 R1), macro/codegen, config-driven behavior — none live in the
  touched functions or sibling commits, so only #5 (partially) or #7 reach them. Stage 1
  fixes *misattribution*, not cross-file interaction recall — kept honest in the record.
- **Failure-driven (#4)**: new failure mode — a malicious branch could inject
  prompt-injection text via sibling-commit context (the Gate 1h "review input is untrusted"
  thread). But this is still diff text pasted into a prompt: same trust posture diff-only
  already carries, no new tool surface. Low marginal risk; noted.

---

## 5. Decision presentation block (Path C — non-interactive /away)

```
┌─ DECISION: how to give code-review models context (portable cross-model sweep) ─────────┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes                        │
└──────────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                 effort       risk     coverage        key downside
  ───  ──────────────────────  ──────────  ────────  ────────────  ─────────────────────────────
   4  ★ sibling-commit/branch    ● ~1 h      ● low     ● 4/4 hard    reviews merged code unless labelled (mitig.)
   3    enclosing-file           ● ~1 h      ● low     ◐ 3/4 hard    misses sibling-COMMIT misattribution
   9    probe + agentic re-verify ◐ wiring    ◐ med     ● 4/4 hard    doesn't fix the cheap reviewer itself
   5    repo map / symbol index  ◐ ½ day     ◐ med     ◐ 3/4 hard    token cost + staleness; existence only

╭─ [4] sibling-commit / full-branch-diff enrichment   ★ recommended ───────────────────────╮
│ effort    ~1 h (git-only harness edit)                 risk   low                        │
│ coverage  4/4 hard · 3/4 soft (S2 cross-file recall unmet by design)                     │
│ hypothesis  If chosen, Results 3c & 5 stop reproducing on D3/D4 in one re-run;           │
│             counter-evidence = a model flags sibling-commit code as "missing" once       │
│             that code is present-and-labelled in the prompt.                             │
│ stress-tests applied                                                                     │
│   · Invert-thesis → still deterministic/portable/byte-identical; only hazard is          │
│     flagging merged code as new → mitig. label context "not under review"                │
│   · Boring-alt → git-only (whole files + branch diff) beats AST function-extraction      │
│   · Failure-driven → prompt-injection via context = same posture as diff-only, no new    │
│     tool surface                                                                         │
│ key downside  reviews already-merged sibling code unless it is explicitly labelled       │
│               context-only (mitigated by the label requirement)                          │
╰──────────────────────────────────────────────────────────────────────────────────────────╯

▶ recommend [4]+[3] (Stage 1, combined) · confidence 85% · runner-up [9], axis = fix-at-source vs guard-downstream
```

**Decision (Path C, staged):**
- **Stage 1 — do first (git-only, portable, confound-preserving):** switch the harness from
  a single-commit diff to the **full logical changeset** (`git diff main...HEAD` or
  sibling-commit diffs appended as **labelled** "context, already committed, not under
  review"), and **inline the enclosing files** of touched hunks (#4 + #3). Kills the two
  most severe FP classes (Results 3c, 5) with no tool plumbing, no confound, no cost blow-up.
- **Stage 2 — add only if measured recall justifies:** a **repo-map / symbol index** (#5)
  for cross-file symbol-existence FPs Stage 1's same-branch scope can't cover.
- **Stage 3 — production, not the sweep:** keep the **incumbent agentic critic** as the
  authority that **re-verifies** any finding the cheap portable critics surface (#9). This
  is where Result 5's "must have repo access" is honoured — at the *verification* gate, not
  the *generation* fan-out. On-demand read (#6) and full agentic (#7) stay out of the
  portable sweep because they break H2/H3.

**Tie note:** #4 vs #9 sit within ~1 cell — axis of disagreement is *fix-at-source
(enrich the prompt) vs guard-downstream (agentic re-verify)*. No stated project preference;
tiebreaker = "fix the cheapest, most-portable defect first" → Stage 1 = #4/#3, with #9 as
Stage 3 rather than an either/or. They compose.

**Multi-model tie-back:** Result 4 shows a cheap second family (Sol ~$0.03/60-90 s) finds
real High bugs the incumbent missed 0/6. Stage-1 sibling-commit+enclosing enrichment is the
*lowest* context level that makes such a cheap second-family critic viable — it removes the
FP class that would otherwise flood the cheap critic's output with confident, unanimous,
wrong findings (Result 5), while staying on plain chat-completions so the whole OpenRouter
sweep still runs and stays model-attributable.
