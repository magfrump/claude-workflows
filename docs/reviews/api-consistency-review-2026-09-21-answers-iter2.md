Commit: 16f2978

# API Consistency Review: answers-2026-09-20, review-fix iteration 2

**Scope:** partial. `git diff f023357..answers-2026-09-20` (the fix commits). Earlier branch commits were read as context only.
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report-iter2.md` (k=3 merged); iteration-1 rubric `docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20.md`
**Probes:** hermetic, under `scratchpad/api-consistency/` (`probe.sh.txt`, `a12.sh.txt`). `old.py` = `f023357:hooks/guard-trusted-writes.py`. Temp HOME, `env -u CLAUDE_CONFIG_DIR`, temp taint dir.

> Probe note for other critics: this session's environment exports `CLAUDE_CONFIG_DIR=/home/node/.claude`. A hook probe that sets only `HOME=<tmp>` still sees the real config dir. `config_dir()` reads the variable first, so a probe that forgets `env -u CLAUDE_CONFIG_DIR` gives misleading results. My first probe run did exactly this.

## Baseline Conventions

- **The guard's tier contract.** HARD must equal the paths the `permissions.deny` rules in `hooks/wiring.json:115-127` name. On HARD the hook defers, and the deny rule does the blocking. SOFT is for paths that no deny rule names, and SOFT gets "ask when tainted" because deferring would leave the path ungated (`guard-trusted-writes.py:22-25`). The code applies this rule to `managed-settings.json` (`:136`).
- **`{{CLAUDE_DIR}}` substitution.** There are three sites, and all use `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` verbatim: `devcontainer-config/link-claude-home.sh:36,137`, `scripts/health-check.sh:575`, and now `config_dir()` (`guard-trusted-writes.py:63-73`). The one exception is disclosed: a relative value is `abspath`-anchored by the hook and written verbatim by the linker.
- **questions.sh errors.** Errors go through `die()` (`questions.sh:72`), prefixed `✗ questions.sh:`, exit 1. Remediation hints use `$QS_CMD` (`:70`).
- **Hypothesis-log row format.** The writer is `append_approved_hypotheses`, which uses `printf` and escapes `|` as `\|` (`si-functions.sh:546-550`). Readers must split on unescaped pipes only. Two readers do this: `_split_row_fields` (`si-morning-summary.sh:1521`) and `flag-removal-candidates.sh:100-110`.
- **Run-id charset.** The format is `^[A-Za-z0-9._-]+$`. The default is `si_default_run_id` → `date +%F-%H%M%S` (`si-functions.sh:469-471`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `config_dir()` | function | `_global_dirs()` (removed), `_safe_resolve`, `classify_path` | `hooks/guard-trusted-writes.py` (f023357) | Consistent. It replaces `_global_dirs` with one value, and the rename matches the single-dir semantics. |
| `CONFIG_DIR`, `GLOBAL_DIRS`, `_HARD_FILE_TARGETS`, `_HARD_DIR_TARGETS` | module constants | `TAINT_DIR`, `HOME`, `WRITE_PRIMITIVE`, `HARD_FRAG` | same file | Consistent. Public-looking constants are UPPER_CASE; the derived sets are `_`-private. |
| `_HOME_INDICATORS`/`HOME_INDICATOR`, `_CFG_INDICATORS`/`CFG_INDICATOR`, `CLAUDE_MD`, `SETTINGS_OR_HOOKS` | compiled regex | `HARD_FRAG`, `SOFT_FRAG`, `WRITE_PRIMITIVE` | `guard-trusted-writes.py:156-189` | Consistent. Each follows the `_LIST` → compiled `NAME` pattern. |
| `si_default_run_id` | shell function | `si_*` public helpers, `append_approved_hypotheses` | `scripts/lib/si-functions.sh` | Consistent (`si_` public prefix). |
| `_valid_run_id`, `_live_run_matches` | shell function (internal) | `_find_tasks_file`, `_days_since_round`, `_split_row_fields` | `scripts/lib/si-morning-summary.sh` | Consistent `_`-private naming. See F4: the validator is not reused where the same regex is repeated. |
| `replace_with`, `QS_CMD` | shell function / var | `die`, `require_files`-style helpers | `scripts/questions.sh:70-133` | Consistent. |
| `_srf_*` locals | shell locals | `out_ref`, `arr_ref` (nameref convention) | `si-morning-summary.sh:1521-1545` | Consistent. The nameref `out_ref` itself is unprefixed (FC Claim 13, informational). |
| `### Qualifying author note` anchor | doc anchor | other `###` anchors in rubric.md | `skills/code-review/references/rubric.md:20` | Consistent. |
| `Fact-check Incorrect` (Original-verdict value) | log vocabulary | `🔴 Must-Fix`, `🟡 Must-Address`, `🟢 Consider`, `Nit` | `docs/reviews/override-log.md:31`, `skills/code-review/references/override-log.md:20` | Consistent between the two definitions. See F5 on older rows. |

## Findings

#### F1: The file-tool HARD set is again a superset of `permissions.deny`; two path classes regressed from "ask" to ungated

**Severity:** Inconsistent
**Location:** `hooks/guard-trusted-writes.py:10,105-118,133`
**Move:** 3 (consumer contract), 8 (the contract the docstring states)
**Confidence:** High for the hook behaviour (executed). Medium for impact, which depends on how Claude Code's deny matcher treats case and symlinks. Neither was testable here; see FC Claim 7.
**Legibility-target:** for-author

**Evidence:**
```
10:  HARD  = exactly what permissions.deny covers (hooks/wiring.json): {{CLAUDE_DIR}}/hooks/**,
110:        first = rel.parts[0].lower()
117:    if cand.name.lower() == "claude.md" and cand.parent == HOME:
133:    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
```
The deny rules are case-sensitive literal paths under `{{CLAUDE_DIR}}` and `~` (`hooks/wiring.json:120-127`). The hook's own rule for paths no deny rule names is at `:22-25` and `:136`: those paths are SOFT, because deferring leaves them ungated. Two classes break that rule.

1. **Case variants.** `_is_hard` lowercases, so `~/.claude/HOOKS/x` and `~/.claude/SETTINGS.JSON` are HARD, and the hook defers on them. No deny rule names them on a case-sensitive filesystem.
2. **Link targets.** `:133` makes the resolved target of `~/.claude/CLAUDE.md` or `~/.claude/hooks` HARD when the target is addressed directly (e.g. `<payload>/CLAUDE.md`). The deny rule names the link path, not the target.

Probe, tainted session, `env -u CLAUDE_CONFIG_DIR`, temp HOME with `~/.claude/{CLAUDE.md,hooks}` symlinked into a writable payload dir:
```
payload-CLAUDE   old  "ask"        new  (no opinion)
HOOKS-upper      old  "ask"        new  (no opinion)
SETTINGS-upper   old  "ask"        new  (no opinion)
managed          old  (no opinion) new  "ask"          <- the rule applied correctly here
```
**Impact:** In this devcontainer `/opt/claude-workflows` is root-owned and read-only, so class 2 cannot be exploited here. On a bare host (`CC_WORKFLOWS_DIR` = a writable checkout), a tainted session editing the payload's `CLAUDE.md` by its real path used to get "ask" and now gets nothing. FC Claim 17 r1 calls this "disclosed". The disclosure sits only in the docstring's HARD definition, which still says "exactly", and that contradicts the same docstring's SOFT rationale. Class 1 is harmless on Linux, but its correctness on a case-insensitive filesystem rests on an unverified matcher assumption. This is a regression relative to f023357 for both classes.

**Recommendation:** Pick one contract and state it. Either (a) HARD = exactly the deny paths: match case-sensitively, and send link targets addressed directly to SOFT so they get the tainted "ask". Or (b) add deny rules for the resolved targets at link time. Option (a) is local to the hook. Either way, add a bats row per class.

#### F2: The Bash and file tools give the same path different tiers, and the fix widened the split

**Severity:** Minor
**Location:** `hooks/guard-trusted-writes.py:22-25,30,185`
**Move:** 7 (asymmetry)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
24:          managed-settings.json. No deny rule names these, so deferring would leave
30:  HARD  = any `.claude/hooks`, `.claude/settings`, managed-settings fragment; OR a
185:HARD_FRAG = re.compile(r"\.claude/hooks(/|\b)|\.claude/settings|managed-settings", re.I)
```
The module docstring gives "HARD" two meanings, one per tool. Probe results (tainted):

| path | Edit | Bash |
|---|---|---|
| `~/.claude/managed-settings.json` | ask | deny |
| `~/.claude/settings.json` with `CLAUDE_CONFIG_DIR` elsewhere | ask | deny |
| project `.claude/settings.json` (pre-existing, C8) | ask | deny |

The first two rows are new in this diff: they moved to SOFT for file tools and stayed HARD for Bash. Bash is stricter in every row, so no hole opens. The cost is that a consumer who reads "HARD" in the header has to find the second definition 20 lines below.

**Recommendation:** Rename the Bash tier in the docstring (e.g. "Bash DENY set") or add one sentence saying the Bash deny set is deliberately wider than file-tool HARD. The co-occurrence design makes Bash conservative, which is fine. The problem is the shared name.

#### F3: A second hypothesis-log reader still splits on every `|`; an open piped hypothesis disappears from Open Hypotheses

**Severity:** Inconsistent
**Location:** `scripts/lib/si-morning-summary.sh:404-418` (`_project_state_open_hypotheses`)
**Move:** 7 (readers disagree about one format's escape contract)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
    rows=$(awk -F'|' -v oc="$outcome_col" -v sc="$source_col" '
        /^\|/ {
            if ($0 ~ /^\|[ \t]*(Round|----)/) next
            round = $2; tid = $3; hyp = $4; outcome = $(oc)
```
(excerpt; the function continues to the `printf "%s|%s|%s|%s\n"` emit and the count/print loop below it.)

e6a6a5f fixed `_split_row_fields`, and `flag-removal-candidates.sh:100-110` already masks `\|`. This reader does neither. For a row whose hypothesis contains `\|`, `$(oc)` reads the shifted-in "Checked at Round" value, which is non-empty. The row is then treated as closed and dropped. Probe (`a12.sh.txt`): a log with open rows T1 (plain) and T2 (`a \| b …`) prints `Open hypotheses: 1` and lists only T1. The reader is pre-existing and was not modified in the diff. A12's framing ("the hypothesis-log reader splits on every `\|`") covered the whole format, so A12 is only partly closed.

**Recommendation:** Route this reader through the same `\|` → sentinel mask as `flag-removal-candidates.sh`. The awk `gsub(/\\\|/, "\036", line); $0 = line` idiom is already in the repo. Add a bats row with a piped open hypothesis. Grep for other `awk -F'|'` readers of `hypothesis-log.md` at the same time.

#### F4: The run-id charset regex is written three times; the validator helper is not reused

**Severity:** Minor
**Location:** `scripts/self-improvement.sh:460`, `scripts/archive-working-docs.sh:45`, `scripts/lib/si-morning-summary.sh:1154-1156`
**Move:** 1/2 (single definition of a format)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
scripts/self-improvement.sh:460:if [[ ! "$SI_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
scripts/archive-working-docs.sh:45:  if [[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
scripts/lib/si-morning-summary.sh:1155:    [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
```
The format has a producer in one library (`si_default_run_id`, `si-functions.sh:469`), a validator in another (`_valid_run_id`, `si-morning-summary.sh`), and two inline copies. The explicit archive prefix argument is still not validated (FC Claim 23). The regex accepts ids that break the lexical newest-first ordering (C7). All the copies agree today. This is the same drift shape as R3.

**Recommendation:** Move `_valid_run_id` next to `si_default_run_id` in `si-functions.sh`, use it at all three sites, and validate the explicit archive prefix too. This is optional for this PR.

#### F5: `Accepted-immutable` grammar is now defined, but the older hand-written rows don't follow its Original-verdict value

**Severity:** Minor
**Location:** `docs/reviews/override-log.md:31,45-46,84-85`
**Move:** 2/7 (vocabulary consistency)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
31: ... For an `Accepted-immutable` row only: `Fact-check Incorrect` (the finding never received a tier). |
45: re-raised. Older `Accepted-immutable` rows below that lack the `[auto: …]`
84: | 2026-09-12 | `59ca38f` | ... | 🟡 Must-Address | Accepted-immutable | ...
```
The definition excuses the older rows for lacking the `[auto:]` prefix, but not for recording `🟡 Must-Address` as the Original verdict. A reader or script keying on `Fact-check Incorrect` will miss them.

**Recommendation:** Extend the sentence at `:45` to say that older rows also carry the tier they were given at the time. Don't rewrite the rows.

#### F6: questions.sh hints hard-code `~/.claude`, but the install dir is `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`

**Severity:** Informational
**Location:** `scripts/questions.sh:70`; `global-instructions/CLAUDE.md:235,281`; `workflows/divergent-design.md:340`
**Move:** 2
**Confidence:** High
**Legibility-target:** for-author

Precedent: `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` used in `devcontainer-config/link-claude-home.sh:36`, `scripts/health-check.sh:575`

**Evidence:** `70:QS_CMD='~/.claude/scripts/questions.sh'`

A4 unified the spelling of the path, which is good. When `CLAUDE_CONFIG_DIR` points elsewhere, though, every hint names a path that doesn't exist. It is harmless in the default layout.

**Recommendation:** Leave it, or make `QS_CMD` derive from `${CLAUDE_CONFIG_DIR:-~/.claude}`. Not worth a change on its own.

## Iteration-1 finding status

- R3: **partially-resolved.** The linker ↔ hook half is closed: `config_dir()` (`guard-trusted-writes.py:63-73`) now matches `link-claude-home.sh:36` and `health-check.sh:575` for empty and `~` values, with the relative-value difference disclosed (FC Claim 8). The HARD ↔ `permissions.deny` half is still open, with new regressions: HARD is a superset through case-folding and link targets (F1, `:110,117,133`), and the Bash HARD set is wider again (F2, `:185`). The `/opt` and case items are **new regressions** vs f023357. The Bash-spelling bypasses in FC Claim 1 are security's domain. None of them is a regression. My hermetic probe (`old-bash.sh.txt` / `new-bash.sh.txt`, tainted session) gives identical results on f023357 and HEAD. `cd; echo x > CLAUDE.md` and `echo x > /home/$USER/CLAUDE.md` get SOFT "ask" when tainted and no opinion when untainted, which matches FC Claim 1's result on an untainted session. That is a **pre-existing residual** (not HARD deny). `echo x > ~/.clau*/settings.json` gets no opinion on both, also a **pre-existing residual**.
- A2: resolved. The high/medium/low mapping is consistent in `rubric.md` and `skills/code-review/SKILL.md` (FC Claim 27).
- A3: resolved. `next-id`/`index`/`archive`/`open` exit 1 through `questions.sh:131-133` with the same "no questions doc here — run init" text `check` uses (`:298`) (FC Claim 18).
- A4: resolved. There is one spelling, `$QS_CMD='~/.claude/scripts/questions.sh'` (`questions.sh:70`), used in DD `:340` and the global instructions. See F6 (informational).
- A5: resolved. `override-log.md:6-10,31-47` defines the row kind consistently with the canonical file (FC Claim 28). See F5 (minor) and FC Claim 6 (the 4c7a2bb row cites a stale line range).
- A12: partially-resolved. `_split_row_fields` is fixed (`si-morning-summary.sh:1521-1538`, FC Claim 24), but `_project_state_open_hypotheses` (`:404-407`) still splits on every pipe (F3). The fixed-12-cell `printf` writer (`si-functions.sh:550`) is unchanged, which is acceptable now that the header migration exists.
- C5: still-open. `Accepted-immutable` casing, the `Run` column name and `HEALTH_CHECK_RUN_TESTS` are all unchanged (`test/scripts/health-check.bats:175`). This is a Consider item and not required.
- C6: still-open, but narrower. `[auto: code-review]` is now defined identically in both override-log docs and excluded by name in `workflows/pr-prep.md:229`. It is still a free-text token.
- C7: partially-resolved. The default id is now sortable (`si-functions.sh:469-471`), and the readers validate the charset. A user `SI_RUN_ID` override can still be non-date, and the explicit archive prefix is unvalidated (F4, FC Claim 23).
- C8: still-open, and extended by F2. `managed-settings.json` and the moved-config-dir `~/.claude` now differ by tool as well. Bash now does honour `CLAUDE_CONFIG_DIR` as an indicator (`:171-181`).
- C9: still-open. There is no change to the `run-tests.sh`/`health-check.sh` ownership comments in this diff.
- A7, A8: acknowledged. They are settled Defer rows (`docs/reviews/override-log.md:80-81`).

## What Looks Good

- The linker, health-check and hook now all compute `{{CLAUDE_DIR}}` from the same expression. The R3 root cause of three independent computations is fixed. route: code-fact-check
- The `managed-settings.json` SOFT move follows the docstring's own rule, and it is an improvement: it was ungated before and now asks when tainted (FC Claim 25). route: code-fact-check
- questions.sh error surface: every refusal goes through `die` with one prefix and an actionable hint.
- `_split_row_fields` locals are prefixed to avoid nameref shadowing, which matches the file's existing `*_ref` convention.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | File-tool HARD ⊋ deny set; payload CLAUDE.md and case variants regressed ask → ungated | Inconsistent | `hooks/guard-trusted-writes.py:10,110,117,133` | High (behaviour) / Medium (impact) |
| F3 | `_project_state_open_hypotheses` still splits on escaped pipes; open piped hypothesis dropped | Inconsistent | `scripts/lib/si-morning-summary.sh:404-407` | High |
| F2 | "HARD" means different sets for Bash vs file tools; managed-settings / moved-config-dir divergence new | Minor | `hooks/guard-trusted-writes.py:22-30,185` | High |
| F4 | Run-id regex in three places; validator not reused; archive prefix unvalidated | Minor | `scripts/self-improvement.sh:460`, `scripts/archive-working-docs.sh:45`, `scripts/lib/si-morning-summary.sh:1155` | High |
| F5 | Older Accepted-immutable rows use a tier as Original verdict; definition only excuses the missing prefix | Minor | `docs/reviews/override-log.md:31,45,84-85` | High |
| F6 | `QS_CMD` hard-codes `~/.claude` | Informational | `scripts/questions.sh:70` | High |

## Overall Assessment

The fix commits mostly converge on the conventions iteration 1 asked for. There is now a single `{{CLAUDE_DIR}}` computation, one questions.sh path spelling, consistent missing-file errors, and a defined `Accepted-immutable` row kind. Two consistency gaps remain, and both can be fixed in place. First, the hook's "HARD = exactly the deny set" contract is still not true. The R4 fix overshot in the other direction, and two path classes lost their tainted "ask" (F1, a regression vs f023357, though not exploitable in the devcontainer). Second, the A12 escape contract was fixed in one reader but not in `_project_state_open_hypotheses` (F3, a pre-existing reader that iteration 1's framing covered). Neither breaks an existing consumer contract in the default layout, but both are the kind of drift R3 was about.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to /workspace/docs/reviews/api-consistency-review-2026-09-21-answers-iter2.md, structured per your role skill, with an `## Iteration-1 finding status` section covering your domain items, ending with a Goal-Alignment Note."
- **Answered:** yes. All 11 domain items have a status line. There are six findings with probes for F1, F2 and F3.
- **Out of scope:** the completeness of the Bash spelling bypasses (FC Claim 1, security's domain), whether Claude Code's deny matcher is case- or symlink-aware, and the single-`/` deny-rule syntax escalation (FC Claim 7 r2). The last two need a live host check.
- **Escalate:** F1's impact depends on the unverified deny-matcher semantics. If Claude Code resolves symlinks when it matches `Edit(~/.claude/CLAUDE.md)`, class 2 is covered and only class 1 remains. Orchestrator: route with the FC Claim 7 host check.
