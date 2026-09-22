Commit: 31f53e8

# Code Review Rubric: Iteration 3, final confirmation pass

**Scope:** `2d93589..answers-2026-09-20`, the six fix commits after iteration 2: 12 files, +236/−46. The scope is partial; earlier commits were context only.
**Reviewed:** 2026-09-21
**Status: 🔴 DOES NOT PASS**: 1 red item unresolved.

Iteration 1 is recorded in `code-review-rubric-2026-09-21-answers-2026-09-20.md` and iteration 2 in `code-review-rubric-2026-09-21-answers-2026-09-20-iter2.md`. The iteration-2 IDs used below come from those files.

**Pipeline**
- **Stage 1 fact-check:** k=3 on opus, merged most-severe-wins into `code-fact-check-report-iter3.md`. It produced 36 claims and replicate agreement was 67%.
- **Stage 1.5 gate:** no core critic was skipped.
- **Critics:** all ran in parallel on opus: security, performance and api-consistency, plus architecture-review (structural) and two contextual critics. tech-debt-triage was triggered because more than 10 files changed. test-strategy was triggered by the untested `si-functions.sh` exit-code change.
- **Stage 2.5:** a submitted-claims fact-check (k=1, opus) produced Claims 33–36, all Verified by execution, and appended them to the merged report.
- **Fact-Check Gate:** fired, with Claims 7 and 19 Incorrect at high confidence. It continued without pausing, because the dispatch was non-interactive and neither claim is behavioral red under tier policy T.
- **Delivery mode:** `inline-diff-only`, via a shared brief file with the diff at about 9.5k tokens. Agents read their skill files and enclosing files from disk.

**Artifacts**
- `code-fact-check-report-iter3.md` (merged, with Claims 33–36 appended). It was built from the replicates `code-fact-check-report-iter3-r1.md`, `-r2.md` and `-r3.md`, plus `code-fact-check-submitted-claims-iter3.md`.
- `security-review-2026-09-21-answers-iter3.md`
- `performance-review-2026-09-21-answers-iter3.md`
- `api-consistency-review-2026-09-21-answers-iter3.md`
- `architecture-review-2026-09-21-answers-iter3.md`
- `tech-debt-triage-review-2026-09-21-answers-iter3.md`
- `test-strategy-review-2026-09-21-answers-iter3.md`
- Execution logs in `execution-logs/iter3-r2-*` and `execution-logs/iter3-subm-*`.

---

## Iteration-2 finding status

| ID | Status | Basis |
|---|---|---|
| N1 | ✅ resolved as stated; its root carries as 🟡 **N16** | Case-folding is removed and HARD matching is case-sensitive (FC 12b, 12c). A path that is HARD only after `resolve()` now returns deny, tainted or not (FC 13; submitted 34: 56/56 cases denied). No HARD path reaches `ask`: 296 cases, 0 violations (submitted 33). The fix exposed a new red, **R6**, and three ambers: **N11** (case-insensitive filesystems), **N12** (per-file hook links on a bare host) and **N16** (the HARD set is still hand-copied and no contract test ties the copies together; architecture Coupling #1). |
| N4 | ✅ resolved | FC 27 executed: all three readers now split the same way, and the N4 test fails on the pre-fix code. |
| N5 | 🟡 still-open | FC 29b is Incorrect: with `docs -> .git` or `docs -> ./x`, `init` still writes. The reworded comment still overclaims. Also api F7, test-strategy, security. |
| N6 | 🟡 still-open (narrowed) | The two iteration-2 errors are fixed. The Q-048 text still omits the HARD_FRAG single-token denies and the `CLAUDE_CONFIG_DIR` token (FC 10). |
| N7 | ✅ resolved | The 4c7a2bb row is pinned (FC 4). The row's "fixed in c5a7c96" wording is only partly true for R1, whose remainder is N2; that goes into **N18**. |
| N8 | ✅ resolved | `rubric.md:156` is plain text (FC 30). A sibling dead link at `rubric.md:60`, and a worked example that was not updated, are 🟢 **C26**. |
| N9 | ✅ resolved | awk failure now exits 3 and propagates (FC 26 executed). The pointer is corrected (FC 25), and the nameref is renamed. The missing regression test and the undesigned caller handling are 🟢 **C27**. |
| N10 | ✅ resolved | The `config_dir()` docstring is accurate (FC 16). The Q-023 timings roughly hold; one run measured 63s against the stated 42–60s (FC 5, in **N18**). |
| A6 remainder | ✅ resolved / ↩️ acknowledged | The explicit prefix is validated (FC 23; submitted 35). The archive no longer overwrites a real file, but it does overwrite a dangling symlink (FC 24). Security F7 cleared that as losing no data, and it is in **N18**. The regex copies are covered by the settled Defer row, but that row's facts are now wrong (**N17**). |
| A12 remainder | ✅ resolved | Via N4 (FC 27). |
| N2, N3, A7, A8 | ↩️ acknowledged | Settled Defer rows in `docs/reviews/override-log.md`. Q-049 tracks N3, but its paste is unsound (**N14**). |

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R6 | **Undisclosed contract change** from a577546, on the README bare-host install.<br><br>**What happens:**<br>• `~/.claude/CLAUDE.md` links to the checkout's `global-instructions/CLAUDE.md` (`README.md:14`).<br>• So `_HARD_FILE_TARGETS` contains the repo's own source file.<br>• File-tool edits to it are now **denied** whether or not the session is tainted, and a hook deny cannot be approved. At 2d93589 the same edits deferred; this was executed on both commits.<br>• A bare-host session developing this repo can no longer edit its global instructions with Edit or Write.<br><br>**Context:**<br>• Security F6 calls this a hardening: before, no deny rule named the file, which broke Arm 2 of the invariant.<br>• It matches the Bash tier, which already denies such writes.<br>• Neither the docstring (`:22-27`), a577546, the README, the bare-host guide nor any test records it.<br>• Four user-facing docs still say the file tools always defer on HARD (C25).<br><br>**Resolution:** this is a policy decision for the user. Either keep the deny and record it (docstring, README, a bats test for the layout), or exempt the checkout source.<br><br>**Decide together with N12:** the checkout's live hook scripts get the opposite treatment (no gate).<br><br>Evidence: `_HARD_FILE_TARGETS = {_safe_resolve(CONFIG_DIR / "CLAUDE.md"), _safe_resolve(HOME / "CLAUDE.md")}` (`:95`); `if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):` / `return "hard-resolved"` (`:154-155`). | API / Security | Breaking (api F1) / Informational (security F6) / Mostly accurate (FC 15, k=3 executed) / Minor (architecture #2) | api-consistency F1 + FC 15 (r1+r2+r3) + security F6 + architecture #2 + test-strategy F2 + tech-debt TD5. Convergence: api + security + architecture + fact-check. | `hooks/guard-trusted-writes.py:22-27,95,154-155`; `README.md:14` | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| N11 | **Case variants on a case-insensitive filesystem.** `~/.claude/SETTINGS.JSON` and `HOOKS/x` now fall to SOFT.<br>• On macOS APFS, which the bare-host guide supports, that name *is* the real `settings.json`.<br>• If Claude Code's deny matcher ignores case, the tainted `ask` overrides the deny (Arm 1).<br>• If the matcher is case-sensitive, the clean defer leaves the file with no gate (Arm 2).<br>• This could not be tested here (no case-insensitive mount).<br>• Fix: decide HARD by file identity (`samefile`, or the same parent plus a casefolded name) and deny on a match.<br>Evidence: `first = rel.parts[0]` (`:123`); `if len(rel.parts) == 1 and first == "CLAUDE.md":` (`:128`). | Security | Medium (security F1, Medium confidence) / Mostly accurate (FC 12a) | security F1 + FC 12a (r2) + architecture #4 + test-strategy G3 | for-author | — | 🟡 Open | — |
| N12 | **Per-file hook links on a bare host get no gate.** The README links the live hooks into a real `~/.claude/hooks/` one file at a time (`README.md:27-30`).<br>• Editing one at its checkout path (e.g. `~/claude-workflows/hooks/log-usage.sh`) classifies as `none` and defers, even in a tainted session.<br>• `_HARD_DIR_TARGETS` holds only the resolved hooks directory, which is real in this layout.<br>• These scripts run on every prompt, and no deny rule names the checkout path (Arm 2).<br>• The gap predates this diff. But a577546's "resolved" tier now treats the sibling CLAUDE.md link the opposite way (R6), so the policy is inconsistent.<br>• The submitted-claims pass independently observed the same mechanism.<br>Evidence: `_HARD_DIR_TARGETS = {_safe_resolve(CONFIG_DIR / "hooks")}` (`:102`). | Security | Medium (security F2, High confidence, probed) | security F2 + test-strategy F2 + submitted-claims observation | for-author | — | 🟡 Open | — |
| N13 | **Two ways the "covered" tier's defer can be unsafe.**<br>(a) `normpath` folds `..` in the text, but the kernel follows a symlink before applying `..`. On a bare host, `~/.claude/skills/../CLAUDE.md` is written to `~/claude-workflows/CLAUDE.md`, yet the hook reads it as the covered `~/.claude/CLAUDE.md` and defers, clean or tainted. Spelled directly, the same target asks when tainted.<br>(b) The docstring states "A deny rule names that string" as fact for spellings folded from `..` or `//` (FC 14). That is unverified; a577546's Notes disclose it, but the docstring does not.<br>This is a new mechanism next to N3, not a re-raise.<br>Security recommends a fix that closes N11-Arm-1, N13 and the `..` part of N3 together: never defer on a spelling that contains `..`, or have the hook deny the covered tier itself.<br>Evidence: `norm = Path(os.path.normpath(str(p)))` (`:140`); `for cand in (p, norm):` / `if _is_hard(cand, [CONFIG_DIR]):` (`:146-147`). | Security / Docs | Medium (security F3, Low confidence) / Mostly accurate (FC 14) | security F3 + FC 14 (r3) | for-author | N3 Defer (inherits for the matcher question; this mechanism is new) | 🟡 Open | — |
| N14 | **The Q-049 paste can close N3 with no evidence.** It prints "enforced" whenever the target file is absent.<br>• It sends all output to `/dev/null` and has no allow-only control run.<br>• The target is outside the cwd.<br>• Run with a `claude` stand-in that always fails, it printed "enforced" for both rule forms.<br>• The entry's plan closes N3 on a single-slash "enforced".<br>• r2 adds that it tests project settings, while N3 is about user settings.<br>• Fix: add an allow-only control that must print "NOT enforced", put the target inside the temp dir, and keep the JSON so `is_error` and `num_turns` can be checked.<br>Evidence: `[ -e "$t" ] && echo "$form-slash rule: NOT enforced (file written)" \|\| echo "$form-slash rule: enforced"` (`:50`). | Docs / Security | Incorrect (high, doc; FC 7 unanimous, executed) / Medium (security F4) | FC 7 (r1+r2+r3) + security F4 + tech-debt TD10 + api F10 | for-author | N3 Defer's revisit trigger ("Q-049's answer") depends on this paste | 🟡 Open | — |
| N15 | **The new deny message gives advice that cannot work.** "Edit it at its ~/.claude path, with review":<br>• That spelling is exactly what `permissions.deny` blocks, and a deny cannot be reviewed. In the devcontainer the file is also root-owned and read-only.<br>• If N3 is real, that spelling has no gate at all.<br>• It hard-codes `~/.claude` and ignores `CLAUDE_CONFIG_DIR`.<br>• It says "through a symlink" in R6's bare-host case, where the agent used the file's real path.<br>• The Bash deny reason (`:263-264`) gives a different route, which is also impossible.<br>Evidence: `"resolved path that permissions.deny does not name. Edit it at its "` / `"~/.claude path, with review."` (`:284-285`). | Docs / API | Incorrect (high; FC 19 unanimous, executed) / Inconsistent (api F2) / Low (security F5) | FC 19 (r1+r2+r3) + api F2 + security F5 | for-author | — | 🟡 Open | — |
| N5 | **Carried from iteration 2; still open.** The reworded `questions.sh` header says a symlinked `docs/` "is caught by that [toplevel] check". It is caught only when the link leads outside the repo: with `docs -> .git` or `docs -> ./x`, `init` still writes (exit 0).<br>Evidence: `# ancestor symlink such as a symlinked docs/ is caught by that check, not by` (`:49`). | Docs | Incorrect (high, doc; FC 29b) | FC 29b (r1; r2 and r3 rated the compound claim Mostly accurate) + api F7 + test-strategy | for-author | — | 🟡 Open | — |
| N6 | **Carried from iteration 2, narrowed.** The Q-048 rule description omits two things:<br>• the literal `CLAUDE_CONFIG_DIR` token triggers both rules;<br>• a write naming `managed-settings`, `.claude/hooks` or `.claude/settings` is denied with no second indicator.<br>r3 also notes that matching is case-insensitive. | Docs | Mostly accurate (FC 10) | FC 10 (r1+r3) + api F10 | for-author | — | 🟡 Open | — |
| N17 | **The override-log rows written this cycle are already stale.**<br>• The N2 row pins `:190-205`; `bash_targets` has been at `:225-240` since a577546. That breaks Step-3.5 location matching, the same defect N7 fixed.<br>• The A6 row says three copies of the run-id regex; there are four, because 818c568 added a second in `archive-working-docs.sh`. Its revisit trigger ("a fourth reader of the Run cell") would not fire on the write-side copy.<br>• The Defer dispositions themselves stand.<br>Evidence: `` iter2 N2: `hooks/guard-trusted-writes.py:190-205` ``; "All three copies are identical and tested". | Docs | Mostly accurate (FC 1, 3) / Minor (api F8, architecture #3) | FC 1 (r2) + FC 3 (r2+r3) + api F8 + architecture #3 + tech-debt TD7 | for-author | Departs from nothing: the A6 and N2 Defer verdicts stand, and only the row text is stale | 🟡 Open | — |
| N18 | **Comment and doc precision, several items.**<br>• The `# Case-folded on purpose: SOFT only ever asks` comment (`:158`): SOFT never denies and asks only when tainted (FC 17).<br>• TODO(N2) says the listed shapes get "no opinion", but the bare `cd` and `/home/$USER` CLAUDE.md shapes get SOFT, which asks when tainted (FC 18).<br>• The claim that an existing archive copy is "never overwritten" does not hold for a dangling symlink at the destination (FC 24). That loses no data (security F7).<br>• `_split_row_fields` says the writer "never emits" `\x1e`, but the writer passes it through from task JSON unfiltered (FC 28).<br>• The 4c7a2bb row's "fixed in c5a7c96" is only partly true for R1 (FC 4).<br>• Q-023 timing: 63s was measured once against 42–60s, under contention (FC 5). | Docs | Mostly accurate | FC 4, 5, 17, 18, 24, 28 | for-author | — | 🟡 Open | — |
| N16 | **The root of N1 carries.** The HARD set is still hand-copied in five or six places:<br>• the `wiring.json` deny rules;<br>• the docstring;<br>• `_is_hard`;<br>• the `_HARD_*_TARGETS` sets (which spell `settings*.json` a second way, via an import-time glob);<br>• the Bash regexes;<br>• the hand-listed bats paths.<br>No contract test ties them together. The only one, `link-claude-home-wiring.bats`, checks that the rules exist, not the hook's classification. The covered/resolved split did not add copies, but the covered side now rests on an unenforced assumption about the matcher, and a drift there fails open. R6, N11, N12 and N13 are each an instance.<br>Recommendation: a test that derives the deny rules from `wiring.json` and checks `classify_path` against each, following `live-verify-gate.bats:217-230`.<br>Evidence: `"Edit({{CLAUDE_DIR}}/settings*.json)",` (`wiring.json:120`); `if len(rel.parts) == 1 and first.startswith("settings") and first.endswith(".json"):` (`:126`). | Architecture | Coupling (architecture #1) | architecture #1 + tech-debt TD5 + test-strategy (mutants M2 and M3 were each caught by only one hand-listed test) | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C25 | Four user-facing docs still say the file tools always defer on HARD: `README.md:170`, `guides/bare-host-hook-wiring.md:52-56`, `hooks/wiring.json:26-30` and `link-claude-home.sh:127-131`. Update them alongside R6. | api F4 | Minor | for-author | — | 🟢 Open |
| C26 | `rubric.md:60` has a sibling dead in-fence link. The worked example `test/skills/code-review/rubric-current-format.md:99-100` was not updated to the new pointer text, which the template's own rule requires. | api F9 | Minor | for-author | — | 🟢 Open |
| C27 | **N9 residue.** Mechanism:<br>• `_migrate_hypothesis_log_run_column` now returns 2 on an awk failure.<br>• Its only caller (`si-functions.sh:514`) runs it unchecked under `set -euo pipefail`.<br>• So an unreadable log aborts the SI run at the hypothesis-log step, after merges, and the round's bookkeeping is not written.<br>• Neighbouring bookkeeping steps use `\|\| true`, and the return values are not documented.<br>• Reverting the fix (`*) return 0`) fails 0 of the 85 SI tests; the test-strategy mutant survived. A `chmod 000` test would catch it.<br>Decide warn-and-continue or abort (orchestrator escalation from FC 26, TD9 and api F5). | api F5 + tech-debt TD9 + test-strategy F1 + FC 26 escalation | Minor / advisory | for-author | — | 🟢 Open |
| C28 | **Archive edges.**<br>• On a collision the script skips the file, exits 0, and the "Archived N" summary does not count skips.<br>• The usage header is stale.<br>• An explicit empty prefix `''` silently falls back to the date (submitted 35).<br>• The dry-run collision branch and the dangling-symlink case are untested.<br>• The collision test uses an explicit prefix, not the date-only fallback its comment names.<br>• A skipped file still pays for its `cited_by` git grep (~0.5s worst case). | api F6 + test-strategy + performance #2 + submitted 35 | Minor / Informational | for-author | — | 🟢 Open |
| C29 | **Hook test pins that are missing:**<br>• MultiEdit and the `path` key reaching the resolve-only deny;<br>• a symlinked HOME;<br>• a `CLAUDE_CONFIG_DIR` that is itself a symlink;<br>• the README bare-host layout (R6 and N12);<br>• a platform-conditional case-insensitive test (N11).<br>Also turn the 22 TODO(N2)/TODO(A8) shapes into `skip`ped bats tests. | test-strategy G1–G5 + tech-debt TD6 | advisory | for-author | — | 🟢 Open |
| C30 | Tier vocabulary is spread over three schemes: `covered`/`resolved` in the docstring, `"hard"`/`"hard-resolved"` in the code, and "resolve-only HARD" in the tests. `"hard"` alone now means the umbrella tier, the defer sub-tier and the Bash deny tier. | api F3 | Minor | for-author | — | 🟢 Open |
| C31 | The escaped-pipe mask is now implemented three times in two languages, with no owner. Revisit when the log writer's escaping or column set changes. | architecture #6 + tech-debt TD8 | Informational | for-author | — | 🟢 Open |
| C32 | The N1 bats tests cost about 1.7s of the file's 6.7s (8 hook spawns plus `jq` per test). An optional trim is to use a shell string match instead of `jq`. The hook's in-process cost rose by 5.6µs per call, which does not show against the 16ms python startup. | performance #1, #3 | Informational | for-author | — | 🟢 Open |
| C33 | `exit 3` means "benign / nothing to do" here, but "hard error" in `confine-tests.sh`. The sentinel is private to one function. | api name audit | Informational | for-author | — | 🟢 Open |
| C3–C10, C17–C24 | Unchanged from iterations 1 and 2, still open. | per prior rubrics | — | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override row | Applied to | Disposition |
|---|---|---|
| 2026-09-21 N2 Defer (Bash text gaps) | security, api | **Inherits.** Not re-raised; only the row's stale line pin is flagged (N17). |
| 2026-09-21 N3 Defer (deny-rule path form, Q-049) | N13, N14 | **Inherits** for the matcher question. **Departs narrowly:** the revisit trigger depends on the Q-049 paste, which is unsound (N14). N13(a) is a new kernel-versus-`normpath` mechanism, not the settings-relative question. |
| 2026-09-21 A6-remainder Defer (run-id regex copies) | N17 | **Inherits** the Defer. **Departs narrowly:** the row's count (3, where there are 4) and its trigger wording are wrong. |
| 2026-09-21 A7 and A8 Defer; c5a7c96 and 4c7a2bb Accepted-immutable | — | **Inherit.** Not re-raised. |
| Q-048 (Bash co-occurrence false denies, accepted and filed) | N6 | **Inherits.** Only the description's completeness is flagged. |

This run added no new override rows. Every Incorrect verdict is on an editable file.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| No file-tool path the hook classifies as HARD reaches `ask`: `"hard"` defers and `"hard-resolved"` denies, both before SOFT. This does **not** cover spellings the hook fails to classify as HARD (N11, N12). | ✅ Confirmed | `classify_path` `:146-155`; `main()` `:275-286`. Submitted Claim 33, executed: 296 HARD cases across 5 layouts, Edit/Write/MultiEdit, both path keys, clean and tainted, 0 violations. | Fact-check (submitted by security and architecture) | for-orchestrator-synthesis |
| A path that is HARD only after `resolve()` returns deny whether or not the session is tainted. This includes a `settings.*.json` that did not exist when the hook loaded. It does not cover per-file hook link targets (N12). | ✅ Confirmed | `:151-155,279-285`. Submitted Claim 34, executed: 56 of 56 cases. | Fact-check (submitted by security) | for-orchestrator-synthesis |
| An explicit archive prefix outside `[A-Za-z0-9._-]+` exits 1 before any path is built, and no directory or move is made. `.` and `..` stay inside `archive/`. | ✅ Confirmed | `scripts/archive-working-docs.sh:52-55`. Submitted Claim 35 and FC 23, executed. | Fact-check (submitted by security) | for-orchestrator-synthesis |
| a577546 adds no filesystem call per invocation; there is one resolve per call, as before. | ✅ Confirmed | Submitted Claim 36, executed by wrapping the `os`/`pathlib` calls: counts at load and for 77 paths are identical between 2d93589 and a577546. | Fact-check (submitted by performance) | for-orchestrator-synthesis |
| The N4 escaped-pipe fix counts and displays piped hypotheses, and the new test fails on the pre-fix code. | ✅ Confirmed | `scripts/lib/si-morning-summary.sh:402-445`. FC 27 and 31a, executed k=3. | Fact-check | for-orchestrator-synthesis |
| Test counts in the commit messages: `bats test/hooks/` is 144 ok, 0 not ok. | ✅ Confirmed | FC 20, executed by all three replicates and by security. "85/85 SI suites" (FC 31b) matches one set of three suites by arithmetic but is Unverifiable, because the commit names no suites. | Fact-check | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

- N11 depends on case-insensitive-filesystem behaviour. There is no APFS mount in the sandbox.
- N13(a)'s exploitability depends on Claude Code's matcher, which is the N3 question.
- Both are tiered 🟡 on a plausible, named mechanism, and each resolution path is a host check or the file-identity fix.

---

## ⏭️ Skipped Core Critics

All core critics ran; none were skipped.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `hooks/guard-trusted-writes.py:95-155` | FC-15, api-F1, sec-F2, sec-F6, arch-2, TS-F2, submitted-observation | **Distinct defects; the root is already stated.** Security F2 and architecture #2 already name the shared root: the resolved-tier target sets follow the install layout, holding per-file CLAUDE.md targets but only the hooks directory. R6 and N12 are its two outcomes. No new composed row. |
| 2 | `hooks/guard-trusted-writes.py:14-15,118-133,138-148` | FC-12a, FC-14, sec-F1, sec-F3, arch-1, arch-4 | **Distinct defects; the shared fix is already stated.** Security's main recommendation (deny the covered tier, or classify by file identity) closes N11 Arm 1 and N13 together, and architecture #1 states the root (N16). These are separate mechanisms. |
| 3 | `hooks/guard-trusted-writes.py:279-285` | FC-19, api-F2, sec-F5 | Distinct defects. All three describe the same finding, N15. |
| 4 | `scripts/lib/si-functions.sh:514,563-590` | FC-26, api-F5, TD9, TS-F1 | Distinct defects. C27 already states the one mechanism. |
| 5 | `scripts/archive-working-docs.sh:50-55,133-147` | FC-23, FC-24, api-F6, sec-F7, TS, perf-2 | Distinct defects: separate edges, each complete. |

---

To pass review, every 🔴 item must be resolved, and every 🟡 item must be fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

**Tokens**, from sub-agent completion notices:
- Fact-check: 311k + 316k + 317k.
- Critics: security 265k, performance 227k, api-consistency 285k, architecture 244k, tech-debt 244k, test-strategy 264k.
- Submitted-claims pass: 227k.
- Total ≈ 2.90M, excluding the orchestrator.

---

## Iteration-4 gate — decision: `escalate`

Recorded 2026-09-21 by the orchestrating session. Iteration 3 ended with 1 🔴 and 10 🟡, so neither exit condition holds. No further fix or re-review runs until the user authorizes it.

One exception, noted here so it is visible: two 🟡 items were text in `docs/working/questions.md` that the user is about to act on, and they were corrected after this rubric was written. N14: the Q-049 paste now has a `control` run and reports INCONCLUSIVE when `claude` doesn't run, checked with a stand-in that always fails. N6: the Q-048 rule description now includes the standalone fragments and `CLAUDE_CONFIG_DIR`. Neither change is re-reviewed.

## Iterations (3 completed)
- 1: full diff `e8d5fa1..` — 5 🔴, 13 🟡. All 🔴 fixed; A7 and A8 deferred with override rows.
- 2: `f023357..` — 0 🔴, 11 🟡. Fixed N1, N4–N10 and the A6 remainder; N2 and N3 deferred (N3 is Q-049).
- 3: `2d93589..` — 1 🔴 (R6, new, caused by the N1 fix), 10 🟡.

## Remaining Must Fix
- R6: the resolve-only HARD tier (a577546) denies Edit/Write on a bare host's checkout `global-instructions/CLAUDE.md`, because `~/.claude/CLAUDE.md` links to it. That is a policy choice, filed as Q-050.

## Remaining Must Address
N5 (questions.sh comment still overclaims for `docs -> .git`), N11 (case-insensitive filesystems), N12 (per-file linked hook scripts get no gate on a bare host; decided together with R6 in Q-050), N13 (`normpath` vs symlink `..`), N15 (the deny message points at a denied path), N16 (HARD set is hand-copied, with no contract test against wiring.json), N17 (stale facts in override rows), N18 (six small comment and doc precision fixes). N6 and N14 are corrected but not re-reviewed.

## Convergence diagnosis
Every fix to the guard hook's path tiers moves the boundary between "a deny rule covers this" and "no rule does". That boundary can't be pinned down until Q-049 shows how deny rules actually match, so each iteration trades one edge for another.

## Recommended action
Pause the hook for a redesign; everything else ships with its issues. Answer Q-049 (host check) and Q-050 (policy) first. The likely redesign is the one security has proposed twice: the hook returns `deny` itself for every protected path instead of deferring to deny rules. That closes N11, N13 and the `..` part of N3, and removes the dependence on how rules match. The non-hook work on this branch (the 23 answered questions, questions.sh, the SI scripts, the docs) has no open 🔴 and could merge separately from the hook commits if you'd rather not wait.
