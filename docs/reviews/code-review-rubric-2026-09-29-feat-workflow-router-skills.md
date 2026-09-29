Commit: de96617

# Code Review Rubric

**Scope:** feat/workflow-router-skills vs main | **Reviewed:** 2026-09-29 | **Status: 🟢 PASS after fixes** — every Must Fix / Must Address item fixed or logged; final confirming pass pending

Pipeline: Stage 1 k=3 fact-check (opus) on 3a63c56 → fixes in 881762a → Stage 2 critics (security, performance, api-consistency, architecture-review; opus) on de96617 → synthesis. Delivery mode: self-read. Dispatch mode: parallel. Deviation: critics reviewed the post-fact-check-fix commit rather than 3a63c56, so they judged the code that will land.
Considered overrides: no prior overrides matched this diff.

---

## 🔴 Must Fix

None. (Fact-check Incorrects were on documentation/rationale text, 🟡 under policy T.)

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Status | Author note |
|---|---|---|---|---|---|---|
| A1 | Log row 66, test header and commit cite "DD opened 15x, RPI 0x", which triage 2026-09-17 §2.2 withdrew the same day (usage hook under-counts, Q-017) | Fact-check | Incorrect (unanimous) | fact-check r1–r3 | ✅ Fixed (881762a) | Cites the mechanism, the user's observation and Q-074 instead; revisit trigger counts artifacts, not the usage log. Commit message: Accepted-immutable override |
| A2 | review-fix-loop router contradicted its workflow ("should not be run as a standalone workflow") and stated a "2 clean passes" exit | Fact-check | Incorrect (unanimous) | fact-check r1–r3 | ✅ Fixed (881762a) | Router removed; opt-out now lives in the workflow's frontmatter (`router: none — …`) |
| A3 | "router and workflow cannot drift" false: routers restated workflow facts | Fact-check | Incorrect | fact-check r1 | ✅ Fixed | Routers reworded; copied step numbers and output names removed (also architecture #2) |
| A4 | Flat skill matching loses the decision tree's precedence; RPI's broad triggers also match batches and 3+-option choices | Architecture | Coupling | architecture-review #1; api-consistency #3/#4; performance #1 | ✅ Fixed | Every router carries a "Not for X (use Y)" clause inside 250 chars; global paragraph restates first-match order. Trigger/row consistency check declined (override log) |
| A5 | Routers copy workflow details (step numbers, output filenames) the stub cap cannot detect | Architecture | Coupling | architecture-review #2 | ✅ Fixed | Bodies now say when to use and hand off; only gates stated in the global instructions are named |
| A6 | Four descriptions put their "not this" clause or triggers past char 250, the listing's truncation point (Q-080 convention) | API consistency | Inconsistent | api-consistency #1; performance #5 | ✅ Fixed | All eight: triggers start ≤211, not-clauses end <250 |
| A7 | Relative `workflows/<name>.md` handoff could follow a same-named file in another project, possibly without its approval gates | Security | Medium | security-reviewer #1; performance #3; architecture #4 | ✅ Fixed | Handoff names `~/.claude/workflows/<name>.md` and "Never follow a same-named file that belongs to another project"; tested; applied to divergent-design too |
| A8 | pr-prep and code-review both claim "a PR is being prepared" | API consistency | Inconsistent | api-consistency #2 | 🟡 Deferred — author note | code-review is outside this diff; pr-prep's description states the split in its first 250 chars. Override log row; first dev cycle |

---

## 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | Global paragraph said the Skill tool "loads the workflow"; pr-prep delivery path "first step"; "70-600"; README stale | fact-check | ✅ Fixed |
| C2 | pr-prep description/body did not name the Operating Modes approval gate for merge/push | security-reviewer #2 | ✅ Fixed (body names it) |
| C3 | Test required `when:`, which the loader ignores and the repo stopped requiring 2026-09-26 | api-consistency #6; architecture #5 | ✅ Fixed (dropped from test and routers) |
| C4 | Exemption recorded in the test, not the workflow | architecture #3 | ✅ Fixed (workflow frontmatter `router:`) |
| C5 | Colliding triggers ("here's the feedback", "where does X live", "does X support Y", "wrap this up", "parallelize 5 features") | api-consistency #5, #3 | ✅ Fixed (removed) |
| C6 | ~850 tokens more skill listing per session in every project | performance #2 | 🟢 Accepted (the point of the change; descriptions trimmed to ~250 chars) |
| C7 | Each router fire adds one tool call (~200–240 tokens) | performance #4 | 🟢 Accepted |
| C8 | Router names appear twice in the usage report | architecture #6 | 🟢 Won't-Fix (override log) |
| C9 | Generic names could be shadowed by a project skill | security #3 | 🟢 Won't-Fix (override log) |
| C10 | Row 66 cites log 65, present only on fix/agents-md-no-imports | fact-check; architecture; api-consistency #9 | 🟢 Resolved by merge order (65's branch merges first) |

## ⏭️ Skipped Core Critics

None.

## 🧩 Composition check

| Cluster | Fragments | Disposition |
|---|---|---|
| router handoff lines (`skills/*/SKILL.md` "Read and follow") | security #1, performance #3, architecture #4 | distinct defects: none new — each states the same relative-path mechanism and fix; merged as A7 |
| RPI description triggers | performance #1, api-consistency #4, architecture #1 | distinct defects: none new — merged as A4 |

Loop: iteration 1 (full scope, k=3 fact-check, 4 critics).
