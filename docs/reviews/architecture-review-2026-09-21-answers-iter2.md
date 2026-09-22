Commit: 16f2978

# Architecture Review — answers-2026-09-20, review-fix iteration 2

**Scope:** partial — `git diff f023357..answers-2026-09-20` (23 files, the iteration-1 fix commits). Commits before f023357 are context only.
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report-iter2.md` (merged k=3, Commit 16f2978); trust-boundary labels from `docs/reviews/security-review-2026-09-21-answers.md` (Commit: `654c0ed`). That security review predates this diff, so its boundaries may be stale.

Scope check: in scope. The diff changes a cross-cutting concern (the guard hook's authorization tiers, `hooks/guard-trusted-writes.py`). It changes a data contract (the SI run-id format that the hypothesis-log Run cell and the archive file names share). It adds a public helper (`si_default_run_id`). It adds a public doc anchor (`rubric.md#qualifying-author-note`). The questions.sh hardening is mostly security, so this review treats it only for structure.

## Dependency Map

- **Policy-path contract (B1/B2).** Four artifacts encode "which paths are protected": `hooks/wiring.json:120-127` (`permissions.deny`), `hooks/guard-trusted-writes.py` for file tools (`_is_hard` :104-119 and `_HARD_FILE_TARGETS`/`_HARD_DIR_TARGETS` :86-93), the same file for Bash (`HARD_FRAG`/`CLAUDE_MD`/`SETTINGS_OR_HOOKS` :183-201), and the docstring (:10-38). The hook owns none of this data. It re-derives it by hand. The only dependency the hook shares with the others is the shape of the `{{CLAUDE_DIR}}` expression, `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`. That expression now appears in three executable places: `devcontainer-config/link-claude-home.sh:36`, `scripts/health-check.sh:575,585`, and `config_dir()` at :63-73.
- **Run-id contract (B5).** `scripts/self-improvement.sh` is the writer. It sources `lib/si-functions.sh` (the new `si_default_run_id`) and `lib/si-morning-summary.sh`. `scripts/archive-working-docs.sh` is a standalone script that consumes `si-run-id.txt`. `si-morning-summary.sh` reads the Run cells back and rebuilds `archive/${run}-<name>` itself (:1199). Dependencies flow writer → file → readers. No shared module owns the charset or the naming rule.
- **questions.sh** stays self-contained. Its messages now use a single display constant, `QS_CMD` (:70).

## Findings

#### 1. The HARD set is still hand-copied into four places, and the copies disagree (R3 residue)

**Severity:** Coupling
**Location:** `hooks/guard-trusted-writes.py:10,104-119,183-185`; `hooks/wiring.json:120-127`
**Move:** 7 (coupling surface), 3 (module boundary on `B2` — see the security review, Commit `654c0ed`, which predates this diff)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
10	  HARD  = exactly what permissions.deny covers (hooks/wiring.json): {{CLAUDE_DIR}}/hooks/**,
...
110	        first = rel.parts[0].lower()
111	        if first == "hooks":
```
```
185	HARD_FRAG = re.compile(r"\.claude/hooks(/|\b)|\.claude/settings|managed-settings", re.I)
```
```
"Edit({{CLAUDE_DIR}}/settings*.json)",
"Edit({{CLAUDE_DIR}}/hooks/**)",
```

c5a7c96 fixed the directory half of R3: one `CONFIG_DIR`, no `~` expansion, and an empty value falls back. The path-list half is unchanged. The list lives in `wiring.json`, in `_is_hard`, in the Bash regexes and in the docstring, and no test ties them together. The copies already disagree in two ways:

- **Case.** File-tool HARD lowercases path segments (`:110`, and the same at `:113` and `:115`), so it is a superset of the case-sensitive deny rules. Fact-check Claim 7 (k=3 unanimous, executed) shows `~/.claude/HOOKS/x` now defers with no gate. That path got an ask before this change, so this is a regression.
- **managed-settings.** The Bash tier treats `managed-settings` as HARD (`:30`, `:185`), which denies. The file-tool tier treats `managed-settings.json` as SOFT (`:22-25`, `:142`). So "HARD" names different sets inside one module. The docstring claim at `:10` is true only for the file tools.

Why this matters: the hook defers on HARD, so its safety depends on HARD ⊆ deny-covered. Hand copies drift, and they have drifted twice across three commits (4c7a2bb, then c5a7c96). Each drift opens a silent no-gate path. On case-sensitive filesystems the case drift is still a no-gate path today.

**Recommendation:** Treat `hooks/wiring.json` `permissions.deny` as the single source. Either have the hook load and match those rules at import (it sits next to `wiring.json`), or add a contract test like `test/hooks/live-verify-gate.bats:217-230` (prior art: it already derives expectations from `wiring.json`). That test should assert `classify_path` is `hard` for every deny rule's path, and is not `hard` for a case variant or for anything no rule names. Fix the docstring to say the Bash tier's HARD set is a fail-closed superset. **Security implication:** this changes where `B2`'s classification data comes from, not where the boundary sits. The security reviewer should confirm that case-folding was not intended as extra protection.

#### 2. The run-id contract is now enforced by three copies of the regex and two default-id generators (A6 residue)

**Severity:** Minor
**Location:** `scripts/lib/si-morning-summary.sh:1154-1156`; `scripts/self-improvement.sh:460`; `scripts/archive-working-docs.sh:45,49`; `scripts/lib/si-functions.sh:469-471`
**Move:** 7 (coupling surface), 2 (responsibility)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
1154	_valid_run_id() {
1155	    [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
1156	}
```
```
45	  if [[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
...
49	PREFIX="${PREFIX:-$(date +%Y-%m-%d)}"
```
```
469	si_default_run_id() {
470	    date +%F-%H%M%S
471	}
```

14bfbdd and efd66e4 fix every concrete A6 defect: the same-day id collision, reads outside `archive/`, and match-all once `si-run-id.txt` is gone (FC Claims 22 and 23 verified). The ownership gap A6 named has grown, though. The charset regex was in two copies and is now in three. The comment at `:1150-1151` makes the reader's safety depend on "the charset self-improvement.sh and archive-working-docs.sh enforce on the writer side", which is a cross-file promise with nothing enforcing it. `archive-working-docs.sh:49` still falls back to a date-only id, not `si_default_run_id`, so two same-day archives without `si-run-id.txt` still share a prefix. That is pre-existing for non-SI use. Changing the id format or charset now takes three coordinated edits, and a missed edit fails open on the read side.

**Recommendation:** Move `_valid_run_id` next to `si_default_run_id` in a helper that every script can source (for example, a small `scripts/lib/si-run-id.sh`). Have all three validation sites and the `archive-working-docs.sh` fallback call it. Leave the `archive/${run}-<name>` rule where it is, but put a comment on it naming `archive-working-docs.sh` as its source.

#### 3. The two managed-settings tiers disagree inside one module

Covered as the second bullet of Finding 1. It is listed separately in the summary table so synthesis can map it. It fails closed in the Bash tier, so the severity is Minor on its own.

#### 4. The qualifying-author-note definition is now duplicated, and the in-template link is dead in every emitted rubric (A1 follow-on)

**Severity:** Minor
**Location:** `skills/code-review/references/rubric.md:49-59,156,159-176`
**Move:** 3 (public surface of a doc module)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
156	carry a [qualifying author note](#qualifying-author-note). 🟢 items are optional.
```
```
161	A 🟡 Must Address row closes by a fix or by a **qualifying author note**. (The template
162	above repeats this definition so it reaches the emitted rubric; this heading is the
```

The external anchors now resolve (FC Claim 26). But line 156 sits inside the template's code fence (:31-157), so every emitted `code-review-rubric-*.md` file gets a link to an anchor that doesn't exist in that file. Before this change, the text there was plain ("see the 🟡 Must Address heading"), so this is a small regression. The definition now also exists twice, at :49-59 and :159-176, and the section itself says so. The next edit has to change both.

**Recommendation:** In the template, go back to plain text, or link to the reference file's absolute repo path. Keep one normative copy of the definition and mark the other "summary; see …".

#### 5. The relative-CLAUDE_CONFIG_DIR divergence is disclosed, not removed

**Severity:** Informational
**Location:** `hooks/guard-trusted-writes.py:69-73`
**Move:** 7
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
72	    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
73	    return Path(os.path.abspath(cfg)) if cfg else HOME / ".claude"
```

The linker writes a relative value verbatim. The hook anchors it at its cwd. The docstring's "exactly what the linker substitutes" is qualified two lines later (FC Claim 8), which is acceptable. It is listed here so that Finding 1's single-source fix covers it too.

## What Looks Good

- `config_dir()` returns one directory with the linker's fallback semantics. The dual-dir `_global_dirs()` that caused R3(a)/(b) is gone.
- The file-tool classifier matches on `resolve()` targets (`_HARD_FILE_TARGETS`/`_HARD_DIR_TARGETS`), not a hard-coded `/opt/claude-workflows`. The installed layout is handled without the hook depending on where that layout lives. The mention at :17/:83 is only a comment. (route: code-fact-check — FC Claim 17 verified the fixture.)
- `si_default_run_id` gives the default id a single named generator, and `self-improvement.sh:459` uses it.
- `QS_CMD` (`scripts/questions.sh:70`) collapses the three command spellings from A4 into one constant. It matches `global-instructions/CLAUDE.md:235` and `workflows/divergent-design.md:340`.
- `_split_row_fields` stays positional-compatible. The escape handling is contained in the splitter, not spread across callers.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | HARD set hand-copied into 4 places that disagree (case superset regression; managed-settings split) | Coupling | `hooks/guard-trusted-writes.py:10,104-119,183-185`; `hooks/wiring.json:120-127` | High |
| 2 | Run-id regex in 3 copies; two default-id generators | Minor | `scripts/lib/si-morning-summary.sh:1154-1156`; `scripts/archive-working-docs.sh:45,49` | High |
| 3 | managed-settings HARD in Bash, SOFT for file tools | Minor | `hooks/guard-trusted-writes.py:22-25,30,142,185` | High |
| 4 | Duplicated qualifying-note definition; dead in-template anchor | Minor | `skills/code-review/references/rubric.md:156,159-176` | High |
| 5 | Relative CLAUDE_CONFIG_DIR diverges from the linker (disclosed) | Informational | `hooks/guard-trusted-writes.py:69-73` | High |

## Iteration-1 finding status

- R3: partially-resolved — the single `CONFIG_DIR` fixes (a) and (b), and the resolve targets fix (d) (`hooks/guard-trusted-writes.py:63-93`). (c) is now cwd-anchored and disclosed (`:69-73`). The HARD *path list* still has no single owner, and case-folding at `:110` introduced a no-gate regression for `~/.claude/HOOKS/x` (Finding 1).
- A1: resolved — `#qualifying-author-note` exists at `skills/code-review/references/rubric.md:159` and resolves from `workflows/pr-prep.md:190` and `workflows/review-fix-loop.md:43`. The follow-on dead in-template link is Finding 4.
- A4: resolved — one spelling via `QS_CMD` (`scripts/questions.sh:70`), and the usage header at :28-34 and `workflows/divergent-design.md:340` now use `~/.claude/scripts/questions.sh`.
- A6: partially-resolved — the concrete defects are fixed (`si-functions.sh:469`, `si-morning-summary.sh:1154,1170-1173`). The contract still lives in duplicated copies, now three regex copies (Finding 2).
- A7: acknowledged — settled Defer row, `docs/reviews/override-log.md:81`.
- C6: still-open — `[auto: code-review]` is still a free-text token that `workflows/pr-prep.md:229` counts on. It is now defined in two places (`docs/reviews/override-log.md:41-47` and `skills/code-review/references/override-log.md:29-30`, the latter declared canonical).
- C10: still-open — the diff doesn't touch the pr-prep local-merge rule.

Regressions introduced by the fixes: the case-folded HARD match (Finding 1, `hooks/guard-trusted-writes.py:110`) and the dead in-template anchor (Finding 4, `rubric.md:156`). No structural regression in the SI or questions.sh changes.

Remaining Bash bypasses (FC Claim 1: bare `cd`, `/home/$USER`, an obfuscated `.claude` directory name, quoting inside file names, `/opt/...`) are security's domain. Structurally they are the C11 debt root: text classification without normalization. The bare-`cd`-to-home class is a pre-existing residual from iteration 1. Obfuscated `.claude` directory names and in-name quoting are new-to-this-scope spellings, not regressions: f023357 didn't catch them either. This review files no separate finding for them.

## Overall Assessment

The fixes improve the structure. The dual-config-dir design is gone, the installed layout is handled by resolution, not by path literals, and the run id and the questions.sh command name each got a single named source. The remaining structural concern is the one R3 named: the protected-path set has no owner. c5a7c96 re-synced the hand copies instead of deriving them, and a new drift (case-folding) appeared in the same commit. This can be fixed in place with a `wiring.json`-driven contract test (prior art in `live-verify-gate.bats`), without restructuring. That test is the single most useful follow-up, because it turns every future drift into a red test, not a silent no-gate path.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown critique saved to /workspace/docs/reviews/architecture-review-2026-09-21-answers-iter2.md, structured per your role skill, with an `## Iteration-1 finding status` section covering your domain items, ending with a Goal-Alignment Note.
- **Answered:** yes — saved at that path with `Commit: 16f2978`. It covers R3, A1, A4, A6, A7, C6 and C10, with regressions flagged.
- **Out of scope:** the Bash bypass completeness (security), questions.sh symlink reach (security, FC Claim 4), commit-message count errors (FC Claims 2 and 3), and Q-048 wording (FC Claim 5).
- **Escalate:** (1) The orchestrator or security reviewer should confirm Finding 1's case-folding regression on the real deny matcher. Whether Claude Code's deny matching is case-sensitive was not testable here. (2) The r2 escalation about `wiring.json`'s single leading `/` in substituted deny rules bears on Finding 1's premise (HARD ⊆ deny-covered) and needs a live host check.
