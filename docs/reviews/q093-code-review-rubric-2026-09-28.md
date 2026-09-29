# Code Review Rubric — Q-093 cc-push self-referencing commondir

**Commit:** 2c8163f (pass 1 reviewed) → fixes in b9f6cc4
**Scope:** `dfe4c0d..HEAD`, branch `q093-cc-push-self-commondir` | **Reviewed:** 2026-09-28 | **Status: ✅ PASSES (pass 1, all rows resolved)**. Single-sample review: no findings is not proof that none exist.

Pass 1 ran as a loop pass: fact-check k=1 (opus), then security, performance and api-consistency critics (opus) in parallel. No contextual critics were triggered: the tests changed with the source, the diff is small, there is no manifest and no UI, and the module structure is unchanged. The diff was delivered inline (self-read, about 7 KB).

---

## 🔴 Must Fix

None. No behavioral Incorrect, no Breaking, and no Critical or High security finding.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The plan's B1 row and Step 3 name a `../../elsewhere` test among the new refusals, but none exists there. It is in the older http-alternates test. | Docs | Incorrect (doc) | Fact-check | for-author | — | Fixed b9f6cc4 | The plan lists the actual cases. |
| A2 | A test comment implies that `./` is the only refused spelling git reads as self. `.\n\n`, `.\r\n`, `.\0` and the absolute path are read as self too. `test/cc-push.bats:262` | Docs | Incorrect (comment) | Fact-check + api-consistency F2 | for-author | — | Fixed b9f6cc4 | |
| A3 | The refusal text says "holding just `.`", but `.\n` is accepted too. Its "it names another repository" is false for the refused self-spellings. `cc-push.sh:295` | API/docs | Mostly accurate / Minor | Fact-check + api-consistency F1 + security F3 | for-author | — | Fixed b9f6cc4 | Now "it can name…", and both accepted forms are named. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | The symlink test case did not pin the helper's `-L` check: the long link target already fails the 1–2-byte size check. `test/cc-push.bats:303` | Security F1 + fact-check | Low | for-author | — | Fixed b9f6cc4. It now uses a 1-byte target, and a mutation run confirmed that dropping `-L` fails the test. |
| C2 | A FIFO swapped in between the `-f` test and `head` would hang cc-push's own read (`cc-push.sh:276`). | Performance F1 | Low | for-author | — | Fixed b9f6cc4 with `timeout 5 head -c 2`. The config greps have the same window; it predates this branch and is left as is. |
| C3 | TOCTOU between the check and git's read. | Security F2 | Informational | for-orchestrator-synthesis | — | Won't-Fix: residual B11, mitigated by `check_no_container`. The diff does not widen it. |
| C4 | Plan B13: a self-commondir might change what git reads (`worktreeConfig`, `different_commondir`). | Fact-check (unverifiable), security C12 | Informational | for-author | — | Fixed: checked empirically (git 2.39.5, linked worktree plus `extensions.worktreeConfig`). The ref advertisement, the `config.worktree` values and HEAD are identical for absent, `.` and `.\n`. |
| C5 | Case-insensitive host filesystem (`COMMONDIR`). | Security C13 | Informational | for-author | — | Deferred. It would only affect a macOS host, and git and the shell test resolve the same file there. Revisit trigger: cc-push run on a case-insensitive FS. |
| C6 | "Run it on the main checkout" is the wrong advice for a stray commondir in the main checkout. This predates the branch. | api-consistency F3 | Informational | for-author | — | Won't-Fix: out of scope. The message now names the one accepted form. |
| C7 | Only the helper comment cites Q-091; the help text and guide cite Q-093 only. | api-consistency F4 | Informational | for-author | — | Won't-Fix: Q-093 links to Q-091. |
| C8 | Plan B5's rationale is wrong: git resolves a relative commondir against the gitdir, not against the link's directory. | Security F3 | Informational | for-author | — | Fixed b9f6cc4: the plan now calls the check defence in depth. |

---

## ↩️ Considered Overrides

No prior overrides matched this diff by location. Row 135 (2026-09-27, exit scan reads commondir itself) is in the same subject area but is about `cc-exit-scan.sh`, which this branch does not change. Not re-flagged.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| git 2.39.5 reads `.` and `.\n` exactly as it reads an absent commondir | ✅ Confirmed (executed) | `rev-parse --git-common-dir` gives the gitdir, and `ls-remote` via `git-upload-pack --strict` succeeds. The scratchpad `cdexp.sh` and fact-check `exp.log` both show this. | Fact-check (executed) | for-orchestrator-synthesis |
| Only `2e` and `2e0a` are accepted | ✅ Confirmed (executed) | The security probe of 13 inputs and the fact-check hex runs show this. The bats loop refuses 8 spellings plus empty, directory, FIFO and symlink. | Fact-check + security (executed) | for-orchestrator-synthesis |

## 🧩 Composition check

The fact-check, security and api-consistency findings cluster at `cc-push.sh:291-296` (A3). Disposition: the defects are distinct, and each finding already states its own wording fix. The fact-check and security F1 cluster at `test/cc-push.bats:303` (C1) is the same defect reported twice, merged into one row. Nothing was composed.
