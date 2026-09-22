Commit: 16f2978

# Code Review Rubric: Iteration 2

**Scope:** `f023357..answers-2026-09-20` (fix commits after iteration 1; 23 files, +888/−157). This scope is partial: earlier commits were context only. **Reviewed:** 2026-09-21. **Status: 🟡 CONDITIONAL PASS**: 11 amber items are awaiting resolution or justification.

Iteration 1 (the red/amber IDs referenced below) is in `code-review-rubric-2026-09-21-answers-2026-09-20.md`.

Pipeline:
1. Fact-check, k=3 on opus, merged most-severe-wins into `code-fact-check-report-iter2.md`.
2. Stage 1.5 gate: no core critic was skipped.
3. Critics ran in parallel on opus: security-reviewer, performance-reviewer and api-consistency-reviewer, plus architecture-review (structural) and tech-debt-triage (contextual, triggered by >10 files and >1000 lines).
4. Stage-2.5 fact-check of submitted claims (k=1, opus), appended to the merged report.

test-strategy was not triggered, because every source change carries test changes.

Delivery mode was `self-read`. The diff alone is about 23k tokens, and its enclosing files push it over the 25k budget. The prompts carried a shared brief file instead of the inlined diff. Critics and fact-checkers read their skill files from disk rather than having them pasted in, since they share the filesystem.

The diff is just over 1000 lines. It was run as a single pass because the dispatch was non-interactive; the brief prioritised the hook and questions.sh.

Artifacts:
- `code-fact-check-report-iter2.md` (merged, with Stage-2.5 claims 30–35 appended), built from replicates `code-fact-check-report-iter2-r1.md`, `-r2.md` and `-r3.md`, plus `code-fact-check-submitted-claims-iter2.md`.
- `security-review-2026-09-21-answers-iter2.md`
- `performance-review-2026-09-21-answers-iter2.md`
- `api-consistency-review-2026-09-21-answers-iter2.md`
- `architecture-review-2026-09-21-answers-iter2.md`
- `tech-debt-triage-review-2026-09-21-answers-iter2.md`

---

## Iteration-1 finding status

| ID | Status | Basis |
|---|---|---|
| R1 | ✅ resolved | All 13 spellings listed in c5a7c96 are now denied, plus 4 more (FC Claims 16 and 30, executed; 15 of the 17 deferred on f023357). The regression against e8d5fa1 is closed. The bypasses that remain predate the fixes and are carried as **N2** (security R1 status, TD2, api R3 status). |
| R2 | ✅ resolved | Default paths can no longer write through a symlink or outside the repo: symlinked files and directories, dangling links and outside-repo ancestors are all refused (FC Claims 18, 19 and 31b, executed). The header comment claims more than this; see **N5**. |
| R3 | ✅ resolved as 🔴, carried as 🟡 **N1** | `config_dir()` now matches the linker for unset, empty and absolute values (FC Claims 8 and 32). The single `CONFIG_DIR` removes (a) and (b), and (c) is disclosed. The HARD set is still copied by hand, and the case-folding plus resolve-target matching is a new gap: architecture Coupling, api Inconsistent. |
| R4 | ✅ resolved as 🔴, carried as 🟡 **N1** | The file tools no longer return "ask" on `~/.claude` HARD paths with `..`, in the installed symlink layout, or through a symlinked project `.claude` (FC Claim 17, executed). The payload CLAUDE.md, reached by its real path, now defers (security #2, Medium). |
| R5 | ✅ resolved | The no-op path really does nothing, and a real migration keeps the inode and mode (FC Claim 21, executed k=3). The awk exit-code collision that remains is in **N9**. |
| A1 | ✅ resolved | The anchor resolves from `workflows/pr-prep.md` and `workflows/review-fix-loop.md`. The new in-template link is dead; see **N8**. |
| A2 | ✅ resolved | FC Claim 27, k=3 Verified. |
| A3 | ✅ resolved | FC Claim 18; api A3. |
| A4 | ✅ resolved | One spelling, `QS_CMD` (`scripts/questions.sh:70`); architecture and api A4. |
| A5 | ✅ resolved | FC Claim 28. The stale 4c7a2bb row is **N7**; api F5 is 🟢 C19. |
| A6 | 🟡 still-open (narrowed) | (a) same-day id collision, (b) absent-file match and (c) Run-cell traversal are all fixed (FC Claims 22 and 23). Still open: the run-id regex now exists in 3 copies, the explicit archive prefix is not validated, and the date-only fallback in `archive-working-docs.sh:49` can still overwrite (FC Claim 23, architecture #2, api F4, TD3). |
| A7 | ↩️ acknowledged | Settled Defer row in `docs/reviews/override-log.md`. |
| A8 | ↩️ acknowledged | Settled Defer row; the `TODO(A8)` is present (FC Claim 29). |
| A9 | ✅ resolved | The file now takes 54–60 s, down from 405 s (FC Claim 15). The two remaining full-script runs are 🟢 C17. |
| A10 | ✅ resolved | All listed spellings are denied. Obfuscated `.claude` directory names were already unguarded before the fixes; they are in **N2**. |
| A11 | ✅ resolved | `scripts/questions.sh:76-78` (FC Claim 18). |
| A12 | 🟡 partially-resolved → **N4** | `_split_row_fields` is fixed (FC Claim 24). The sibling reader `_project_state_open_hypotheses` still splits on every pipe. |
| A13 | ✅ resolved | FC Claim 27. |

Regressions introduced by the fixes:
- **N1**: case-folding, and resolved payload targets that defer.
- **N8**: a dead in-template anchor.

No other before/after probe got worse.

---

## 🔴 Must Fix

None open.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|---|
| N1 | **This is a regression.** The file-tool HARD set is a superset of `permissions.deny`, so the hook defers on paths that no deny rule names.<br>• `_is_hard` lowercases path segments, so `~/.claude/HOOKS/x` and `~/.claude/SETTINGS.JSON` count as HARD, but the deny rules are case-sensitive.<br>• Paths that resolve onto `_HARD_FILE_TARGETS` or `_HARD_DIR_TARGETS` are also HARD. That includes the payload CLAUDE.md addressed by its real path.<br>• These cases were "ask" at f023357 and now get no opinion. That breaks the docstring's own SOFT rule and its "HARD == exactly what permissions.deny covers".<br>• There is no impact in the devcontainer, where `/opt` is root-owned and read-only. On a bare host with a writable payload, the payload CLAUDE.md now has no gate.<br>• Root cause: the HARD set is copied by hand in four places (`wiring.json` deny rules, `_is_hard`, the Bash regexes and the docstring), and no contract test ties them together.<br>Evidence: `first = rel.parts[0].lower()` (`:110`); `if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):` / `return "hard"` (`:133-134`). | Security / Architecture / API | Medium / Coupling / Inconsistent / Mostly accurate | security #2 + architecture #1 + api-consistency F1 + Fact-check Claim 7 (k=3) | `hooks/guard-trusted-writes.py:10,104-119,133-134`; `hooks/wiring.json:120-127` | for-author | — | 🟡 Open | — |
| N2 | **This is pre-existing, not a regression.** Bash writes to global policy files still get no opinion when the command text carries no indicator token:<br>• Bare `cd` to home: `cd; echo x > CLAUDE.md`.<br>• `/home/$USER/CLAUDE.md`.<br>• An obfuscated `.claude` directory name: `~/.clau*/settings.json`, `~/.cl""aude/…`, `D=.cl; ~/${D}aude/…`.<br>• Quoting inside the file name: `~/.claude/"settings".json`, `hoo"ks"`.<br>• `/opt/claude-workflows/hooks/…`.<br>• Copying a whole tree into `~/.claude`: `cp -r /tmp/p/. ~/.claude/`, `rsync -a /tmp/p/ ~/.claude/`, `cd ~/.claude && cp /tmp/p/* .`. This replaces `settings.json`, which holds both the hook wiring and the deny list. It gets no opinion even in a tainted session.<br>The CLAUDE.md cases ask when tainted; the settings/hooks and whole-tree cases have no gate at all. Every case was checked against f023357 and behaves the same there.<br>Security suggests treating "write primitive plus config dir named anywhere" as HARD, the same fail-closed direction Q-048 accepts. Normalising the text alone would not close the glob and `$D` cases. The immutable commit-message understatement is logged as Accepted-immutable.<br>Evidence: `if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):` / `return "hard"` (`:200-201`). | Security | Medium (security #1) / Incorrect-high on commit message (FC Claim 1, k=3) | security-reviewer + Fact-check + tech-debt TD2 + api-consistency | `hooks/guard-trusted-writes.py:190-205` | for-author | Accepted-immutable row (c5a7c96 residual) — the commit message is not re-raised; the live gap is | 🟡 Open | — |
| N3 | **This is unverified.** Claude Code may read a deny-rule path that starts with a single `/` as relative to the settings file, and `//` as absolute. If so, the substituted `Edit(/home/node/.claude/…)` deny rules match nothing, and every file-tool path the hook defers has no gate at all. That would undercut the premise behind the hook's HARD tier and N1. It predates this diff. It needs a live host check (`you: terminal`), since the sandbox has no egress and there is no deny-matcher here to test against. | Security | Medium (Low confidence) | security #3 + Fact-check r2 escalation + architecture escalation | `hooks/wiring.json:120-127` | for-author | — | 🟡 Open | — |
| N4 | **A12 is incomplete.** `_project_state_open_hypotheses` splits on every `\|`, escaped ones included. On a row with a pipe in its hypothesis, `$(oc)` reads the "Checked at Round" cell, which the writer always fills, instead of Outcome. The row is then dropped from Open Hypotheses. A probe with 2 open rows reported `Open hypotheses: 1`. The three readers now split three different ways; copy the `\036` mask from `flag-removal-candidates.sh:103-110`, or call `_split_row_fields`.<br>Evidence: `rows=$(awk -F'\|' -v oc="$outcome_col" -v sc="$source_col" '` … `round = $2; tid = $3; hyp = $4; outcome = $(oc)`. | API / Behavioral | Inconsistent (api F3) / 🟡 (TD1) | api-consistency + tech-debt-triage (executed) | `scripts/lib/si-morning-summary.sh:402-418` | for-author | — | 🟡 Open | — |
| N5 | The `questions.sh` header comment says "Writes never go through a symlink", but only the file and its immediate directory are checked.<br>• An explicit override path with a symlinked grandparent is written through, and outside the repo. The overrides are deliberately exempt from containment.<br>• An in-repo ancestor symlink such as `docs -> .git` or `docs -> ./x` passes both checks.<br>• Default paths cannot escape the repo (FC Claim 18).<br>• The submitted Claim 31c showed the refusal of `docs/working -> ../other` comes from the directory check, not from containment.<br>• Related wording point: noclobber follows a symlink that points to an existing non-regular file (FC Claim 9).<br>Fix the comment, or check every ancestor.<br>Evidence: `# Writes never go through a symlink.` (`:47`); `[[ -L "$dir" ]] && die "refusing to write: directory $dir is a symlink"` (`:94`). | Docs / Security | Incorrect (high, doc-only) / Informational | Fact-check Claim 4 (r2+r3) + Claims 9, 31c + security #5 | `scripts/questions.sh:47-51,91-100,428-430` | for-author | — | 🟡 Open | — |
| N6 | The user will answer Q-048 from its description, and the description misstates the rule:<br>• For settings/hooks, only `.claude` or the config dir triggers a deny; `~`, `$HOME` and `global-instructions` do not.<br>• `git commit … HEAD~1` is denied only when the command also contains a write primitive; the description drops the word "write".<br>Evidence: `a write that names \`CLAUDE.md\`, \`settings*.json\` or \`hooks\` is denied whenever the command also contains \`~\`, \`$HOME\`, \`.claude\`, \`global-instructions\` or the config dir anywhere. That also denies \`git commit\` with \`HEAD~1\` …` | Docs | Incorrect (high, doc-only) | Fact-check Claim 5 (r1 Incorrect, r3 Mostly accurate) | `docs/working/questions.md:38` | for-author | — | 🟡 Open | — |
| N7 | The override-log row for 4c7a2bb cites `hooks/guard-trusted-writes.py:56-132` and says the hook "now matches only literal spellings". That describes the file before c5a7c96. Pin the reference to `4c7a2bb:` and put the sentence in the past tense. | Docs | Stale | Fact-check Claim 6 (r1, single-replicate) | `docs/reviews/override-log.md` (4c7a2bb row) | for-author | Departs from nothing: the row's verdict stands and only its present-tense code reference is stale | 🟡 Open | — |
| N8 | **This is a regression.** The in-template link `[qualifying author note](#qualifying-author-note)` sits inside the rubric template's code fence (lines 31–157), so it is dead in every rubric that is emitted. The plain-text pointer it replaced worked. The definition is also duplicated, at `:49-59` and `:159-176`.<br>Evidence: `carry a [qualifying author note](#qualifying-author-note). 🟢 items are optional.` (`:156`). | Docs | Mostly accurate / Minor | Fact-check Claim 26 (r1) + architecture #4 | `skills/code-review/references/rubric.md:156` | for-author | — | 🟡 Open | — |
| N9 | Comments and messages in the SI scripts are inaccurate:<br>• The detection awk's failure exits 2, the same code as the no-header sentinel, so "Awk failure now propagates" (685030e) is only half true (FC Claim 14, executed; TD4).<br>• The pointer "si_default_run_id below" is wrong; the function is defined above, at `:469` (FC Claim 11).<br>• "ASCII Record Separator: never present in a log row" is assumed, not enforced (FC Claim 12).<br>• The nameref `out_ref` has no `_srf_` prefix (FC Claim 13).<br>• On the transition day a legacy date-only id misorders; this is disclosed in 14bfbdd's Notes (FC Claim 10). | Docs / Behavioral | Mostly accurate | Fact-check Claims 10–14 | `scripts/lib/si-functions.sh:469,481,545-588`; `scripts/lib/si-morning-summary.sh:1522,1527` | for-author | — | 🟡 Open | — |
| N10 | Two claims in the hook and docs overstate:<br>• `config_dir()` is said to match the linker "exactly". A relative or `~/` `CLAUDE_CONFIG_DIR` is made absolute from the hook's own working directory, while the linker and health-check keep the string as written. The docstring discloses this, but the "exactly" overclaims (FC Claims 8 and 32).<br>• The questions-archive entry says "42s". It measured 54–60 s here under contention (FC Claim 15). | Docs | Mostly accurate | Fact-check Claims 8, 15, 32 + architecture #5 | `hooks/guard-trusted-writes.py:63-74`; `docs/working/questions-archive.md:833` | for-author | — | 🟡 Open | — |
| A6 | Carried from iteration 1, narrowed (see the status table): the run-id regex is now copied 3 times, the explicit archive prefix is not validated (`scripts/archive-working-docs.sh:33`), and the date-only fallback at `:49` can overwrite, because `mv` has no `-n`. | Architecture / API | Coupling→Minor / Mostly accurate | architecture #2 + api F4 + Fact-check Claim 23 + TD3 | `scripts/self-improvement.sh:460`; `scripts/archive-working-docs.sh:33,45,49`; `scripts/lib/si-morning-summary.sh:1155` | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C17 | `test/scripts/health-check.bats:127,140`: the two negative frontmatter tests still run the whole `health-check.sh` to check one gate, which is about 2/3 of the file's ~55 s. Iteration 1 suggested calling `check_skill_frontmatter` directly through the `BASH_SOURCE` guard. | performance #1 | Low | for-author | — | 🟢 Open |
| C18 | The hypothesis-log **Round** cell reaches path construction without validation (`scripts/lib/si-morning-summary.sh:1199-1203,1360-1364`). A Round of `1/../../outside/x` read a JSON file outside the working dir. The read is read-only and requires commit access. Fix: treat any Round that is not purely digits as absent. Pre-existing. | security #4 (executed) | Low | for-author | — | 🟢 Open |
| C19 | Older hand-written `Accepted-immutable` rows record `🟡 Must-Address` as the Original verdict, where the new definition says `Fact-check Incorrect`. | api-consistency F5 | Minor | for-author | — | 🟢 Open |
| C20 | "HARD" means different sets in Bash and the file tools (managed-settings; `~/.claude` when the config dir points elsewhere). Bash is stricter everywhere, so no hole opens. This extends C8. | api-consistency F2 + architecture #3 | Minor | for-author | — | 🟢 Open |
| C21 | `QS_CMD` hard-codes `~/.claude`, but the linker installs to `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`. | api-consistency F6 | Informational | for-author | — | 🟢 Open |
| C22 | `cat tmp > file` in the R5 migration keeps the inode but is not atomic: an interrupted run truncates the tracked log. It is a one-time migration of a git-tracked file. | tech-debt TD4 | advisory | for-author | — | 🟢 Open |
| C23 | Scoping question: `~/.claude.json`, which holds the MCP server config, has no gate in either tier. It is outside the hook's declared policy set. | security (escalation) | Informational | for-author | — | 🟢 Open |
| C24 | `docs/reviews/hallucination-patterns.md` does not log the c5a7c96 test-count mismatch (FC Claim 2). | Fact-check r2 escalation | Informational | for-author | — | 🟢 Open |
| C3, C4, C5, C6, C7, C8, C9, C10 | Unchanged from iteration 1 and still open. C3 (`_days_since_round` without `$run`) and C4 (WRITE_PRIMITIVE pathological time) were re-confirmed as unchanged by performance. C11 is partially addressed: see N2 and TD2. C1 (taint only from WebSearch/WebFetch) is still open and keeps N2's CLAUDE.md cases weakly gated. | per iteration 1 | — | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override row | Applied to | Disposition |
|---|---|---|
| 2026-09-21 A8 Defer (WRITE_PRIMITIVE primitives) | security's A8 status; N2's list excludes the A8 primitives | **Inherits.** Not re-raised. |
| 2026-09-21 A7 Defer (`~/.claude/scripts/` exposes all of `scripts/`) | architecture's A7 status | **Inherits.** Not re-raised. |
| 2026-09-21 4c7a2bb Accepted-immutable | N7 | **Departs, narrowly.** The immutable verdict stands. Only the row's present-tense code reference is stale. |

This run appended two new `Accepted-immutable` rows for c5a7c96 (the understated residual, and the test count and pre-fix failure claim).

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The repo hook denies each of the 13 R1/A10 spellings listed in c5a7c96, plus 4 more. 15 of those 17 deferred on f023357. This does not cover spellings outside the list (N2). | ✅ Confirmed | `hooks/guard-trusted-writes.py:196-201`: `if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):` / `return "hard"`. FC Claims 16 (k=3) and 30 (executed). Scope: "all 17 commands return deny". | Fact-check (Claim 30 submitted by security-reviewer) | for-orchestrator-synthesis |
| For **default paths**, `questions.sh` refuses a symlinked target file, a symlinked target directory, a dangling link, and an ancestor that resolves outside the repo. This does not cover in-repo ancestor symlinks or override paths (N5). | ✅ Confirmed | `scripts/questions.sh:93-100`: `[[ -L "$file" ]] && die …` / `[[ "$resolved" == "$root"/* ]]`. FC Claims 18 and 31b (executed). | Fact-check | for-orchestrator-synthesis |
| The R5 migration does nothing on its no-op path and keeps the inode and mode on a real migration. The awk-failure path is excluded (N9). | ✅ Confirmed | `scripts/lib/si-functions.sh:568-588`. FC Claim 21 (executed, k=3). | Fact-check | for-orchestrator-synthesis |
| Moving managed-settings.json to SOFT for the file tools gates it more strictly: all 12 cases deferred before, and now a tainted session gets "ask". | ✅ Confirmed | FC Claims 25 (k=3) and 33 (executed). | Fact-check (submitted by api-consistency) | for-orchestrator-synthesis |
| The fixes add about 0.17 ms in-process per hook call. `WRITE_PRIMITIVE` is byte-identical, and the pathological timings are unchanged. | ✅ Confirmed | FC Claim 35 (executed, Medium confidence). | Fact-check (submitted by performance) | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

N3 rests on deny-matcher semantics that could not be tested here; it is tiered 🟡 with a host check as its resolution path. Every other finding's evidence was resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; none were skipped.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `hooks/guard-trusted-writes.py:63-205` | FC-1, FC-7, FC-8, FC-30, FC-32, sec-1, sec-2, sec-3, arch-1, arch-5, api-F1, api-F2, TD2 | Distinct defects. arch-1 already states the root of N1 (hand-copied HARD set); TD2 states the root of N2 (text classification). These are two mechanisms with separate fixes. |
| 2 | `scripts/questions.sh:47-130,428` | FC-4, FC-9, FC-31a/c, sec-5 | Distinct defects. N5 already states the one mechanism. |
| 3 | `scripts/lib/si-morning-summary.sh:402-418,1515-1540` | api-F3, TD1, FC-12, FC-13, FC-24 | Distinct defects. TD1 states the root of N4. |
| 4 | Run-id: `si-functions.sh:469` / `archive-working-docs.sh:33-49` / `si-morning-summary.sh:1155-1203` | FC-10, FC-23, arch-2, api-F4, TD3, sec-4 | Distinct defects. arch-2 states A6's root; sec-4 (the Round cell) is a separate field. |
| 5 | `skills/code-review/references/rubric.md:49-176` | FC-26, arch-4 | Distinct defects. Both describe the same finding, N8. |

---

To pass review, all 🔴 items must be resolved, and every 🟡 item must be fixed or carry an author note. 🟢 items are optional.

Tokens (from sub-agent completion notices):
- Fact-check: 309k + 307k + 287k
- Critics: security 260k, performance 212k, api-consistency 249k, architecture 247k, tech-debt 223k
- Submitted-claims pass: 223k
- Total ≈ 2.32M, excluding the orchestrator
