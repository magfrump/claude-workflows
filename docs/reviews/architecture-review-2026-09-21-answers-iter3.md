Commit: 31f53e8

# Architecture Review — answers-2026-09-20, review-fix iteration 3 (final)

**Scope:** partial. `git diff 2d93589..answers-2026-09-20` covers 818c568, a577546, 739cbbb, fd0ad24 (merge), b951c4f and 31f53e8. Earlier branch commits are context only.
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report-iter3.md` (merged k=3, Commit 31f53e8). Trust-boundary labels come from `docs/reviews/security-review-2026-09-21-answers-iter2.md`. That map predates a577546: its `B3` still reads "treated as HARD, so defer", but the resolved tier now denies.

**Scope check:** in scope. The diff changes a cross-cutting concern: the guard hook's authorization pipeline now has a new `hard-resolved` tier and a new `deny` outcome for the file tools. It also changes the return contract of an error-handling path (`_migrate_hypothesis_log_run_column`, exit 3), and it adds a write-side copy of the run-id contract (`archive-working-docs.sh:52`). The doc-only commits (739cbbb, b951c4f, 31f53e8) are reviewed only where they record structural dispositions.

**Fact-check escalations:** none are addressed to architecture-review. The awk-exit escalation to the orchestrator (FC Claim 26) is noted as Finding 5, Informational. I have not re-verified it.

## Dependency Map

- **Policy-path contract (`B1`/`B2`/`B3`).** After a577546, `hooks/guard-trusted-writes.py` classifies a file-tool path in three steps:
  - **Covered HARD** (`:145-148`): `_is_hard(cand, [CONFIG_DIR])` on the as-given and normpath spellings. The hook defers, and relies on `permissions.deny` to block.
  - **Resolved HARD** (`:149-155`): `_is_hard(cand, GLOBAL_DIRS)` on all three candidates, plus the `_HARD_FILE_TARGETS`/`_HARD_DIR_TARGETS` sets built at import from wherever the global entries resolve (`:95-102`). The hook denies.
  - **SOFT or none** (`:156-169`).

  The hook still reads nothing from `hooks/wiring.json`. The protected set is re-encoded in these places:
  - `wiring.json:120-127`, the deny rules;
  - the docstring, at `:10-11` and `:18-27`;
  - `_is_hard`, at `:121-131`;
  - the target sets, at `:95-102`, which carry their own literal names;
  - the Bash regexes, at `:219-220`;
  - the new bats lists, at `test/hooks/guard-trusted-writes.bats:502-503` and siblings.

  The tiers now also depend on two external semantics the hook cannot see: how Claude Code's deny matcher normalizes a path (`..`, `//`, case), and how the host filesystem treats case.
- **Install layout → policy.** `_HARD_FILE_TARGETS` is whatever `~/.claude/CLAUDE.md` resolves to at import. That makes the installer layout (`README.md:14`, `devcontainer-config/link-claude-home.sh`) an input to which paths the hook denies.
- **Run-id contract (`B5`).** One writer, `self-improvement.sh`, feeds two consumers, `archive-working-docs.sh` and the morning-summary reader. The charset regex now appears 4 times in 3 files: `self-improvement.sh:460`, `archive-working-docs.sh:45,52` and `si-morning-summary.sh:1162`. No shared helper owns it.
- **Hypothesis-row splitting.** The `\|` escape rule is written in `si-functions.sh`. It is read in three places, each with its own implementation of the escape mask:
  - `flag-removal-candidates.sh:103-110` (awk);
  - `si-morning-summary.sh:412,421` (awk, new in 818c568);
  - `_split_row_fields` at `si-morning-summary.sh:1537-1545` (bash).

## Findings

#### 1. The root of N1 is still open: the HARD set has no single owner. The covered/resolved split adds a second, unenforced contract on the "covered" side.

**Severity:** Coupling
**Location:** `hooks/guard-trusted-writes.py:95-102,121-131,145-155`; `hooks/wiring.json:120-127`
**Move:** 7 (coupling surface), 3 (module boundary on `B2`/`B3`)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
146	    for cand in (p, norm):
147	        if _is_hard(cand, [CONFIG_DIR]):
148	            return "hard"
```
```
126	        if len(rel.parts) == 1 and first.startswith("settings") and first.endswith(".json"):
```
```
100	for _n in {"settings.json", "settings.local.json"} | _settings_names:
101	    _HARD_FILE_TARGETS.add(_safe_resolve(CONFIG_DIR / _n))
102	_HARD_DIR_TARGETS = {_safe_resolve(CONFIG_DIR / "hooks")}
```
```
      "Edit({{CLAUDE_DIR}}/settings*.json)",
      "Edit({{CLAUDE_DIR}}/hooks/**)",
```

a577546 fixes N1's two concrete drifts:
- The case-folding superset is gone (FC Claims 12b and 12c).
- A resolve-only HARD path now denies instead of deferring (FC Claim 13, executed k=3 sweep; no probed HARD path asks).

That is a real structural improvement. A drift on the **resolved** side now fails closed, because an over-inclusive target set produces a false deny, not a no-gate path.

The root that iteration 2's architecture #1 named is unchanged:
- No code derives the HARD list from `wiring.json`.
- No contract test ties the two together. `grep wiring.json test/hooks/*.bats` still hits only `live-verify-gate.bats:217`.
- The list is still written by hand: `_is_hard` spells `settings*.json` as `startswith/endswith` (`:126`), while the target set spells it as two literals plus an import-time glob (`:97-101`). So the file-tool tier encodes one rule twice.

The split also makes the **covered** side carry a stronger claim than before. "A deny rule names that string" (`:18-21`) is now the only thing between a covered path and no gate. That claim rests on the external matcher's normalization of `..`, `//`, MultiEdit and case. FC Claim 14 notes that the docstring states this as fact while the commit Notes call it unverified. That is N3/Q-049's substance and is settled; I raise only the structure here.

A drift on the covered side still fails open, silently. That is the direction that matters, and it is the direction a `wiring.json`-driven test would guard.

Net status: **still open.** The damage from a drift is halved, but the root is not addressed. The number of copies is unchanged. The new bats lists are hand copies too, and they would not catch a rule added to `wiring.json`.

**Recommendation:** Add the contract test iteration 2 proposed. For each `Edit|Write(...)` rule in `wiring.json` `permissions.deny`, substitute `{{CLAUDE_DIR}}`, expand `~`, and assert that `classify_path` returns `hard` for a representative path. Also assert that nothing *outside* those globs returns `hard`, using case variants and a sibling like `~/.claude/hooksx`. Derive the rule list from the file, following the prior art at `live-verify-gate.bats:217-230`. Change the docstring's "A deny rule names that string" to say it is assumed pending Q-049.

**Security implication:** none from this recommendation. It changes where `B2`'s classification data is checked, not where the boundary sits.

#### 2. The resolved tier's deny set is a function of the install layout, so the README bare-host install extends policy to the developer's own checkout

**Severity:** Minor
**Location:** `hooks/guard-trusted-writes.py:95,154-155`; `README.md:14`
**Move:** 2 (responsibility), 7 (coupling to installer layout)
**Confidence:** High (the behaviour is FC Claim 15, executed k=3). I have not verified intent.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
95	_HARD_FILE_TARGETS = {_safe_resolve(CONFIG_DIR / "CLAUDE.md"), _safe_resolve(HOME / "CLAUDE.md")}
```
```
154	    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
155	        return "hard-resolved"
```
```
ln -s ~/claude-workflows/global-instructions/CLAUDE.md ~/.claude/CLAUDE.md
```

In iteration 2, I listed "match on `resolve()` targets, not a hard-coded `/opt` path" under What Looks Good, because the hook deferred on those targets. Now that it denies on them, the same design means the protected set is "wherever the installer pointed the entry".

On the README install, that is the repo checkout's `global-instructions/CLAUDE.md`. Edit and Write on it are now denied, clean or tainted. At `2d93589` they deferred (FC Claim 15). The design conflates two things: "the protected file reached by another name" and "the source file the protected entry is built from". Whether the source should be protected is a policy decision. Today it falls out of the installer layout, and neither the docstring nor a test states it.

`hooks/*.py` is not affected, because README links hooks per file into a real directory. That asymmetry is itself layout-dependent.

**Recommendation:** Decide the policy explicitly and write it in one place. Either state in the docstring and a test that the linked source is protected, or exclude link targets inside a git working tree the user owns. Pair it with the Finding-1 contract test, so installer changes surface as test changes.

**Security implication:** this is `B3` (moved: defer → deny). Whether to narrow it is security-reviewer's call, and the fact-check escalation routes it there. This finding records only the structural cause.

#### 3. The run-id Defer row's facts are now wrong: there are 4 copies, and its revisit trigger misses the one that exists

**Severity:** Minor
**Location:** `docs/reviews/override-log.md` (iter2 A6-remainder row); `scripts/archive-working-docs.sh:45,52`
**Move:** 7
**Confidence:** High (FC Claim 3, r2 and r3)
**Legibility-target:** for-author

**Evidence:**
```
| 2026-09-21 | `answers-2026-09-20` | iter2 A6 remainder: the run-id charset `^[A-Za-z0-9._-]+$` is copied in `scripts/self-improvement.sh`, `scripts/archive-working-docs.sh` and `scripts/lib/si-morning-summary.sh` `_valid_run_id` (architecture/tech-debt). | 🟡 Must-Address | Defer | All three copies are identical and tested; ... Revisit trigger: any change to the run-id format, or a fourth reader of the Run cell. |
```
```
45	  if [[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
...
52	if ! [[ "$PREFIX" =~ ^[A-Za-z0-9._-]+$ ]]; then
```

The Defer disposition itself stands and is not re-raised. Two of its facts are now wrong:
- 818c568, which the row itself credits, added a fourth copy at `archive-working-docs.sh:52`. "All three copies" is wrong.
- The trigger, "a fourth reader of the Run cell", counts readers. The new copy is a write-side validation, so the trigger would not fire on the kind of growth that just happened.

**Recommendation:** Amend the row to read "four copies in three files", and widen the trigger to "any new copy of the charset, or any change to the run-id format".

#### 4. On a case-insensitive filesystem, the case-sensitive HARD encoding depends on the host

**Severity:** Informational
**Location:** `hooks/guard-trusted-writes.py:14-15,118-120`
**Move:** 7
**Confidence:** Medium. No case-insensitive mount was available to test (FC Claim 12a).
**Legibility-target:** for-author

**Evidence:**
```
14	          like Linux paths: ~/.claude/HOOKS/x is not the hooks dir (it falls to SOFT).
```

Matching the deny rules' case is the right choice for keeping HARD ⊆ deny-covered. It adds a third external dependency, though: the filesystem's case semantics. On macOS, which README supports, `SETTINGS.JSON` *is* the real settings file, so the "covered" contract then depends on whether the deny matcher folds case.

A `wiring.json` contract test cannot capture this, because it is a platform assumption. The impact belongs to the security reviewer, and FC routed it there.

**Recommendation:** Name the assumption in the docstring ("assumes a case-sensitive filesystem; on macOS see …"), so the dependency is visible where the tiers are defined.

#### 5. The migration helper's error contract widened, and no caller was designed for it

**Severity:** Informational
**Location:** `scripts/lib/si-functions.sh:566-580`
**Move:** 4 (error-handling pipeline)
**Confidence:** High (FC Claim 26, executed k=3)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    case "$state" in
        0|3) return 0 ;;
        1) ;;
        *) return "$state" ;;
    esac
```

This matches the comment's intent, and N9's half-truth is fixed. Structurally, a helper that used to be total can now return 2. Under `set -euo pipefail` in `self-improvement.sh`, that aborts the run at the hypothesis-logging step, after merges (FC Claim 26). The error now propagates, but no layer decides what should happen next. This is the orchestrator escalation from the fact-check report, noted here for synthesis.

**Recommendation:** Handle the non-zero return at the call site explicitly, either log-and-continue or abort before merges, and document the choice.

#### 6. The `\|` escape rule is now implemented by three readers plus the writer

**Severity:** Informational
**Location:** `scripts/lib/si-morning-summary.sh:412,421,1537-1545`; `scripts/flag-removal-candidates.sh:103-110`
**Move:** 7
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
412	            line = $0; gsub(/\\\|/, "\036", line); $0 = line
```
```
110	        gsub(/\\\|/, "\036", line)
```

N4 is fixed, and all three readers now split consistently (FC Claim 27). The fix copied the mask from `flag-removal-candidates.sh` rather than calling `_split_row_fields`, which iteration 2 offered as the other option. The copies deliberately differ on restore: plain `|` for display at `:421`, and `\|` in the other two. This is consistent today, but the escape rule has no owner, which is the same pattern as the run-id regex.

**Recommendation:** None required now. If the log grammar changes, move the awk mask into one sourced snippet, or have the awk readers emit raw lines for `_split_row_fields`.

## What Looks Good

- **The deny/defer split puts fail-closed where it is cheap.** A path the deny rules demonstrably do not name is denied by the hook, not deferred into nothing. Over-inclusion on that side costs a false deny (Finding 2), not a bypass. (route: code-fact-check — FC Claim 13.)
- **HARD is checked on every candidate before SOFT** (`:143-155`). The ordering invariant "a HARD path never reaches ask" is structural, not incidental. (route: code-fact-check — FC Claim 13 sweep.)
- **The N1 tests pin both sides.** The resolved spelling denies, and the covered spelling still defers, for example `guard-trusted-writes.bats` "a symlinked config dir addressed by its resolved path is denied" together with its `assert_defer` twin. That is the first test pair that encodes the covered/resolved boundary. (route: code-fact-check — FC Claim 22.)
- **N4's `\037` join** removes the display-pipe re-split hazard within the reader itself. The comment explains why not tab.
- **The archive prefix is validated before it becomes a path**, and a collision skips instead of overwriting (FC Claims 23 and 24; the dangling-symlink caveat is security's).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | HARD set still hand-copied with no `wiring.json` contract test; covered side now rests on an unenforced "a deny rule names this string" | Coupling | `hooks/guard-trusted-writes.py:95-102,121-131,145-155`; `hooks/wiring.json:120-127` | High |
| 2 | Resolved-tier deny set follows installer layout; bare-host install protects the repo checkout's global CLAUDE.md | Minor | `hooks/guard-trusted-writes.py:95,154-155`; `README.md:14` | High (behaviour) |
| 3 | Run-id Defer row: "three copies" is now four; the revisit trigger misses write-side copies | Minor | `docs/reviews/override-log.md` A6 row; `scripts/archive-working-docs.sh:52` | High |
| 4 | Case-sensitive HARD assumes a case-sensitive filesystem (macOS) | Informational | `hooks/guard-trusted-writes.py:14-15,118-120` | Medium |
| 5 | Migration helper can now return 2; no caller handling was designed | Informational | `scripts/lib/si-functions.sh:566-580` | High |
| 6 | `\|` escape mask has three reader copies | Informational | `scripts/lib/si-morning-summary.sh:412,1537-1545`; `scripts/flag-removal-candidates.sh:110` | High |

## Iteration-2 🟡 status (architecture view)

| Item | Status | Basis |
|---|---|---|
| N1 | **Surface resolved; root still-open** | The case superset was removed (`:118-131`, FC 12b/12c), and resolve-only paths now deny (`:149-155`, FC 13). The hand-copied HARD set and the missing `wiring.json` contract test remain (Finding 1). A new consequence is the bare-host deny (Finding 2). |
| N4 | resolved | `si-morning-summary.sh:412,421,436`; FC 27; the test fails pre-fix (FC 31a). The structural residue is Finding 6 (Informational). |
| N5 | still-open | The `questions.sh:49-50` comment still overclaims for in-repo ancestor symlinks (FC 29b, Incorrect). Doc-only, security's domain. |
| N6 | resolved (residual wording) | The two iteration-2 errors are fixed. Omissions remain: HARD_FRAG single-token denies, the `CLAUDE_CONFIG_DIR` token, and case-insensitivity (FC 10, Mostly accurate). |
| N7 | resolved | The row is pinned to `4c7a2bb` and written in the past tense (FC 4). "Fixed in c5a7c96" is partial for R1, whose residue is N2. |
| N8 | resolved | `rubric.md:155-157` is plain text again (FC 30). The duplicated definition (`:49-59` / `:160+`) is still there, and the section declares it deliberate. |
| N9 | resolved | Exit 3 vs 2 (FC 26), the "above" pointer (FC 25), the `\x1e` assumption now stated (FC 28, Mostly accurate: pass-through from task JSON), and the nameref renamed to `_srf_out`. |
| N10 | resolved | `config_dir()` docstring (FC 16) and Q-023 timings (FC 5, Mostly accurate under contention). |
| A6 remainder | acknowledged (Defer), with the disposition's facts wrong | The prefix is validated and a collision no longer overwrites (FC 23/24). The regex copies are deferred in the override-log, but there are 4 copies, not 3, and the trigger misses them (Finding 3). |
| A12 remainder | resolved | Folded into N4. The three readers split consistently (FC 27). |

## Overall Assessment

The fix commits improve the pipeline's structure. The file-tool tier now fails closed wherever the hook can *see* that no deny rule applies, and HARD is checked before SOFT on every candidate. The single most important structural concern is unchanged from iterations 1 and 2: which paths are protected is still written out by hand in `wiring.json`, `_is_hard`, the target sets, the Bash regexes, the docstring and the tests, and nothing checks one against another. The covered/resolved split makes the drift direction that still fails open (covered ⊆ deny-matched) the load-bearing one. It also makes the resolved set depend on installer layout (Finding 2).

Both problems can be fixed in place without restructuring, with one `wiring.json`-driven contract test and one explicit policy line on link targets. The SI and archive changes are sound. Their residues are duplicated-contract debt that is already deferred (Finding 3 corrects the record) or Informational.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** An architecture critique saved to /workspace/docs/reviews/architecture-review-2026-09-21-answers-iter3.md with `Commit: 31f53e8` on the first line, structured per the architecture-review skill, every finding carrying Evidence and Legibility-target, plus the iteration-2 status table and a Goal-Alignment Note.
- **Answered:** yes. The N1 root is still open. The split halves the damage from a drift, but no contract test exists, and the covered side now carries an unenforced external-matcher assumption (Finding 1). The run-id Defer row is factually wrong: there are 4 copies, not 3 (Finding 3). The three SI row readers are consistent but not consolidated (Finding 6, Informational).
- **Out of scope:** whether the bare-host deny of `global-instructions/CLAUDE.md` is acceptable policy, the case-insensitive FS impact, the dangling-symlink overwrite, and the Q-049 paste soundness (security). The deny-message wording (FC 19) belongs to api-consistency. N2, N3, A7, A8 and Q-048 are settled.
- **Escalate:** (1) Security should decide Finding 2's policy, because `B3` moved from defer to deny and the iteration-2 security Trust Boundary Map still says "defer". (2) The orchestrator should route FC 26's caller-handling gap (Finding 5) for an explicit disposition, since it can abort an SI run after merges.
