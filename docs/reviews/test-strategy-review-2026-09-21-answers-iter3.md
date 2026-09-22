Commit: 31f53e8

# Test Strategy: answers-2026-09-20, iteration 3 (fix commits after iteration 2)

**Scope:** `git diff 2d93589..answers-2026-09-20` (818c568, a577546, 739cbbb, fd0ad24, b951c4f, 31f53e8). This is a partial scope. Commits before 2d93589 are context only.
**Reviewed:** 2026-09-21
**Role:** test-strategy critic (contextual, advisory). Iteration 3 of 3, the final confirmation pass.
**Inputs:** the shared brief `iter3-brief.md`; the merged fact-check report `docs/reviews/code-fact-check-report-iter3.md` (cited below as FC-n); the full diff; the enclosing files.

**Method.** I ran mutation probes on scratch copies of HEAD's tree (`git archive HEAD`, under the session scratchpad). Nothing ran against `/workspace` or the real `~/.claude`. For each probe I made one targeted source change, then ran the affected bats files and counted the failures. A mutant that **survives** (0 failures) marks a path whose regression the suite would not catch.

- Script: `scratchpad/ts-mutate.sh.txt`.
- Unmutated baseline: `guard-trusted-writes.bats` 58/58; SI trio (`append-approved-hypotheses` + `precondition-gate` + `morning-summary-clusters`) 85/85; `archive-working-docs.bats` 14/14; `morning-summary-clusters.bats` 25/25.
- The SI trio's 85 matches the arithmetic FC-31b inferred for "85/85 SI suites pass". That is consistent with the claim, but it does not prove which suite set the author meant. `route: code-fact-check`.

Hermetic hook probes (fake HOME, `CLAUDE_CONFIG_DIR` unset, scratch taint dir) are in `scratchpad/ts-probe.sh.txt`, with output in `ts-probe.out`. The awk-error discrimination probe is `scratchpad/ts-migrate.sh.txt`.

## Mutation results (summary)

| Mutant | Change | Result | Killed by |
|---|---|---|---|
| M1 | `hard-resolved` → defer | killed (3) | N1 project-.claude, payload-real-path, symlinked-config-dir tests |
| M2 | `_is_hard` case-folds again | killed (1) | N1 case-variant test only |
| M3 | covered tier matches `GLOBAL_DIRS` (resolved config dir counts as "covered") | killed (1) | N1 symlinked-config-dir test only |
| M4 | `_HARD_FILE_TARGETS` / `_HARD_DIR_TARGETS` branch removed | killed (2) | N1 project-.claude, payload-real-path |
| M5 | `cand.parent == HOME` clause removed | killed (2) | R3 + N1 lexical-defer |
| **M6** | `*) return "$state"` → `*) return 0` (awk runtime error swallowed again, i.e. the pre-N9 behaviour) | **survives: 0/85 fail** | — |
| M7 | awk sentinel back to `exit 2` (case arm unchanged) | killed (1) | "no-op when no header row is found" |
| **M8** | `[ -e "$dest" ]` → `[ -f ] && [ ! -L ]` | **survives: 0/14 fail** (equivalent on every tested input; the dangling-link case is untested) | — |
| M9 | prefix regex also allows `/` | killed (1) | explicit-prefix refusal test |
| **M10** | collision check only when not `--dry-run` | **survives: 0/14 fail** | — |
| M11 | `\036` escaped-pipe swap removed (N4) | killed (1) | the N4 open-hypotheses test |

Headline: the new hook tests do discriminate, since every N1 mutant is killed. But M2 and M3 are each caught by exactly one hand-listed test. The awk-exit fix (N9) and two edges of the archive no-overwrite fix (A6) have no regression guard.

## Test Conventions

- **Framework:** bats. Tests live in `test/*.bats`, `test/hooks/*.bats` and `test/scripts/*.bats`. `test/lib/hermetic-env.bash` supplies `pin_hermetic_locale`.
- **Hook tests** (`test/hooks/guard-trusted-writes.bats`) use a fake `$HOME` and `CC_WEB_TAINT_DIR` under a `mktemp -d`, and `unset CLAUDE_CONFIG_DIR` in `setup()`.
  - Helpers: `bash_payload`, `file_payload` (Edit/Write/MultiEdit + `file_path`), `guard`, `assert_decision`, `assert_defer`, `taint`.
  - `install_layout` builds the devcontainer's /opt-payload symlink layout.
  - Tests are table-style loops over path lists that echo the failing path.
- **SI lib tests** source `scripts/lib/si-functions.sh` / `si-morning-summary.sh` and call functions directly on a temp `$LOG` / `$HYP_LOG` built with `printf`.
- **Archive tests** run `bash "$SCRIPT"` inside a temp repo that holds a synthetic `docs/working/`.
- **Deny-rule wiring:** `test/link-claude-home-wiring.bats:238-254` asserts that the rendered `settings.json` *contains* the eight HARD deny rules. That checks one direction only (deny ⊇ listed rules).

## Untested Paths Touched by the Change

- **G1** — `hooks/guard-trusted-writes.py:95,154-155` — README bare-host layout. `~/.claude/CLAUDE.md` is a file symlink into the user's checkout (`README.md:14`), and the non-security hooks are per-file symlinks into the checkout (`README.md:26-29`).
  - Edit of `~/claude-workflows/global-instructions/CLAUDE.md` now returns **deny**.
  - Edit of `~/claude-workflows/hooks/<linked>.sh` returns **defer**.
  - No test installs this layout, so neither outcome is pinned. The first is an undisclosed behaviour change (FC-15). The second is a live hook reachable through a spelling no deny rule names.
  - Status: not covered.
- **G2** — `hooks/guard-trusted-writes.py:146-148` against `hooks/wiring.json:120-127` — the reverse direction of the invariant is not covered: every path the file tools classify `"hard"` (defer) should be matched by a rendered deny rule for that tool. The iteration-2 rubric named "no contract test ties them together" as the N1 root cause. Today only single hand-listed cases catch M2 and M3.
- **G3** — `hooks/guard-trusted-writes.py:14-15,118-133,158` — the case-variant branch on a case-insensitive filesystem (macOS bare host, WSL `/mnt/c`). There, `~/.claude/SETTINGS.JSON` is the real settings file, falls to SOFT, and defers untainted (FC-12a). Not covered: the suite runs only on case-sensitive ext4 and has no platform-conditional test.
- **G4** — `hooks/guard-trusted-writes.py:270-285` — the `hard-resolved` deny reached via `tool_name: MultiEdit` and via the `path` key. Not covered: the N1 tests use only Edit/Write with `file_path`. My probe returns deny for both, so this is a pin only.
- **G5** — `hooks/guard-trusted-writes.py:89,95,149-153` — `GLOBAL_DIRS` / `_HARD_FILE_TARGETS` when `$HOME` itself is a symlink, and when `CLAUDE_CONFIG_DIR` is set to a symlink. Not covered by bats: the N1 symlinked-config-dir test links `$HOME/.claude` with the env var unset. My probe: resolved `settings.json` → deny, resolved `~/CLAUDE.md` → deny, lexical → defer.
- **G6** — `hooks/guard-trusted-writes.py:281-285` — the `hard-resolved` deny *reason* text. Not covered, and the text is currently wrong (FC-19). Only worth pinning after the text is fixed.
- **G7** — `scripts/lib/si-functions.sh:576-580` — the `*) return "$state"` arm (an awk runtime error, e.g. an unreadable log, now returns 2). Not covered: mutant M6 survives all 85 SI tests. The caller arm (`si-functions.sh:514`, called from `scripts/self-improvement.sh:1874` under `set -euo pipefail`) is also not covered, and its intended handling is undecided (FC-26 escalation).
- **G8** — `scripts/archive-working-docs.sh:138-143` — a **dangling symlink** at `$dest`. `[ -e ]` is false, so `mv` replaces the link, contradicting "an existing archive copy is never overwritten" (FC-24). Not covered: M8 survives.
- **G9** — `scripts/archive-working-docs.sh:138-146` — the `--dry-run` arm on a collision. Today it prints `skip` and does not count the file. Not covered: M10 survives, so a regression that made dry-run report `move` for a file the real run will skip would go unnoticed.
- **G10** — `scripts/archive-working-docs.sh:49,138` — the scenario the new comment names: a date-only fallback (no argument, no `si-run-id.txt`) run twice. Partially covered: the new test uses the explicit prefix `same-day`, and the code path after `PREFIX` is shared.
- **G11** — `scripts/questions.sh:47-51,91-100` — an in-repo ancestor symlink (`docs -> .git`, `docs -> ./x`). Not covered. The new header comment says it "is caught by that check", but `init` writes through it with exit 0 (FC-29b). `test/questions-doc.bats:367-378` covers only an ancestor pointing *outside* the repo.
- **G12** — `scripts/lib/si-morning-summary.sh:412,421-422` — an escaped pipe in the Task ID, Round or Source cell. Only `hyp` has `\036` restored to `|`, so those fields would print a raw `\036` byte. Not covered. Low: writers do not put pipes in those cells.

## Findings

### F1 — The N9 exit-code fix has no regression guard (G7)

- **Severity:** Must Address (test gap on a fix that iteration 2 required). Advisory.
- **Location:** `scripts/lib/si-functions.sh:576-580`
- **Evidence:**
  ```
      case "$state" in
          0|3) return 0 ;;
          1) ;;
          *) return "$state" ;;
      esac
  ```
- **What the probes show:**
  - Replacing `*) return "$state"` with `*) return 0` (the exact pre-fix semantics) fails 0 of 85 SI tests.
  - The candidate test below returns rc=2 on HEAD and rc=0 on the mutant (`ts-migrate.sh.txt`), so it discriminates.
  - The existing no-header test (`test/append-approved-hypotheses.bats`, "migration is a true no-op when no header row is found") guards only the `3` arm.
- **Confidence:** High (executed).
- **Legibility-target:** for-author

### F2 — The bare-host layout behaviour is unpinned in both directions (G1)

- **Severity:** Must Address. A behaviour change that no test pins, plus an inconsistency the tests would surface. Advisory.
- **Location:** `hooks/guard-trusted-writes.py:95`, `:154-155`
- **Evidence:**
  ```
  _HARD_FILE_TARGETS = {_safe_resolve(CONFIG_DIR / "CLAUDE.md"), _safe_resolve(HOME / "CLAUDE.md")}
  ```
  ```
      if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
          return "hard-resolved"
  ```
- **Probe** (`ts-probe.out`, README layout under a fake HOME):
  - `Edit checkout global CLAUDE.md: deny`
  - `Edit checkout hooks/guard.py: defer`
  - `Edit checkout hooks/new.py: defer`
- **Why the tests matter here:**
  - Both links are file symlinks from `~/.claude` into the same checkout, but they get opposite outcomes.
  - The per-file hook links (e.g. `claude-config-audit.sh`) are live hooks. `_HARD_DIR_TARGETS` holds only the resolved `hooks` *dir*, and in this layout that dir is a real directory. So a resolved per-file hook target is neither HARD nor SOFT, and no deny rule names the checkout spelling.
  - The README says repo edits are meant to be live, so the defer may be intended. The deny on `global-instructions/CLAUDE.md` is the undisclosed change (FC-15).
  - Whichever policy the author picks, an `install_readme_layout` test should pin both outcomes so the next change to `_HARD_*_TARGETS` cannot flip either silently.
- **Escalate:** security-reviewer / orchestrator. Is the per-file-hook defer consistent with the invariant "never defer on a protected path no deny rule covers"? This is the same file-symlink mechanism as the CLAUDE.md case, which the hook now denies.
- **Confidence:** High for the behaviour (executed). Medium for whether the hook defer is a defect.
- **Legibility-target:** for-orchestrator-synthesis

### F3 — No contract test between the hook's "covered" tier and the rendered deny rules (G2)

- **Severity:** Consider (medium value). Advisory.
- **Location:** `hooks/guard-trusted-writes.py:146-148`; `test/link-claude-home-wiring.bats:238-254`
- **Evidence:**
  ```
      for cand in (p, norm):
          if _is_hard(cand, [CONFIG_DIR]):
              return "hard"
  ```
- **Current state:**
  - The wiring test checks that the rendered deny list *contains* eight literal rules.
  - Nothing checks that a path the hook **defers** on is one those rules match.
  - M2 (case-folding back) and M3 (resolved dir treated as covered) are each killed by exactly one hand-written test. A new spelling class, like the case variants that caused N1, would not be caught unless someone thought to list it.
- **Confidence:** High (executed mutation counts).
- **Legibility-target:** for-author

### F4 — The archive no-overwrite claim has two untested edges (G8, G9)

- **Severity:** Consider. Advisory.
- **Location:** `scripts/archive-working-docs.sh:138-143`
- **Evidence:**
  ```
    if [ -e "$dest" ]; then
      # Two archives under one prefix (a date-only fallback run twice in a day)
      # must not overwrite the first run's copy.
      echo "  skip  $name: archive/${PREFIX}-${name} already exists" >&2
      continue
    fi
  ```
- **Current state:**
  - M8 and M10 both survive.
  - A dangling-symlink `dest` is overwritten today (FC-24). That is a red test at HEAD: the fix is `[ -e "$dest" ] || [ -L "$dest" ]`.
  - Practical impact is low. The link pointed nowhere, so no archived content is lost, but the comment's "never overwritten" is untrue for it.
- **Confidence:** High (executed).
- **Legibility-target:** for-author

### F5 — The questions.sh ancestor-symlink comment contradicts untested behaviour (G11)

- **Severity:** Consider (doc/test). Advisory. N5 is still open in substance; see the table below.
- **Location:** `scripts/questions.sh:49-50`
- **Evidence:**
  ```
  # ancestor symlink such as a symlinked docs/ is caught by that check, not by
  # the per-file one). Explicit QUESTIONS_LIVE/ARCHIVE paths get only the
  ```
- **Current state:**
  - The only ancestor test (`test/questions-doc.bats:367`, "refuses a docs/ directory that resolves outside the project") uses an outside target.
  - FC-29b shows that `docs -> .git` and `docs -> ./x` let `init` write, with exit 0.
  - A test for the in-repo case would force the choice: refuse it (change the code), or pin that it is allowed (change the comment to "an ancestor symlink that leads outside the repo").
- **Confidence:** High (FC-29b, executed).
- **Legibility-target:** for-author

## Recommended Tests

#### Migration propagates an awk runtime error and leaves the log untouched

**Closes gaps:** G7
**Type:** unit
**Priority:** high
**File:** `test/append-approved-hypotheses.bats`, next to the R5 "true no-op" tests
**What it verifies:** A detection-awk failure (exit 2) makes `_migrate_hypothesis_log_run_column` return nonzero, and the log is not rewritten.
**Key cases:**
- Pre-Run header log, `chmod 000 "$LOG"` → `run _migrate_hypothesis_log_run_column "$LOG"`; `[ "$status" -eq 2 ]`. `chmod 644` it again in the test, not in teardown, so the before/after stat compare still works.
- A portable variant that works even as root: define `awk() { return 2; }` in the test, then call the function → status 2, and the header line is unchanged (`head -1` is still without ` Run |`). On HEAD this returns 2; on the M6 mutant it returns 0.
- Caller contract, once decided (FC-26 escalation): `append_approved_hypotheses` on an unreadable log should either return nonzero *before* appending, or append nothing. Today the migration's return code is ignored inside the caller (`si-functions.sh:514`), so the only thing that stops the append is `set -e` in `self-improvement.sh`.

**Setup needed:** none beyond the existing `$LOG` / `write_tasks` fixtures.

#### README bare-host layout: pin the file-tool outcome for each checkout-linked entry

**Closes gaps:** G1
**Type:** integration (hook process, fake HOME)
**Priority:** high. Order it after the author decides the policy (F2).
**File:** `test/hooks/guard-trusted-writes.bats`, as a new `install_readme_layout` helper next to `install_layout`
**What it verifies:** In the README layout (a real `~/.claude/hooks/` dir with per-file links, a file-link CLAUDE.md, and *copied* security hooks), the checkout spellings get the decided decision. The `~/.claude` spellings still defer.
**Key cases:**
- `Edit ~/claude-workflows/global-instructions/CLAUDE.md`, clean and tainted → the decided outcome (today: deny).
- `Edit ~/claude-workflows/hooks/claude-config-audit.sh` (per-file linked), clean and tainted → the decided outcome (today: defer, ask-free).
- `Edit ~/claude-workflows/hooks/guard-trusted-writes.py` (copied, not linked) → defer. The installed copy is a different file.
- `Edit ~/.claude/CLAUDE.md` and `~/.claude/hooks/claude-config-audit.sh` → defer (covered tier).

**Setup needed:** a helper that mirrors `README.md:10-35` under `$HOME`.

#### Contract: every file-tool "hard" defer is matched by a rendered deny rule

**Closes gaps:** G2, and indirectly G3 as a documented exception
**Type:** property / contract
**Priority:** medium
**File:** `test/hooks/guard-trusted-writes.bats`, or `test/link-claude-home-wiring.bats`, which already renders `settings.json` with the linker
**What it verifies:** For a generated set of candidate paths, whenever the hook defers under the covered tier for tool T, some `T(<glob>)` rule in the rendered `permissions.deny` matches the path.
- Use a simple `fnmatch` model: `**` = any depth, `*` = one segment, and case-sensitive.
- An explicit allowlist records the disclosed N3 exceptions (`..`, `//`, MultiEdit), so they stay visible, not silent.

**Key cases:**
- Case variants (`HOOKS/x`, `SETTINGS.JSON`, `Claude.md`) → must not defer while tainted (they ask). The contract holds.
- `settings.foo.json` and `hooks/a/b/c.sh` → defer, and a rule matches.
- A new spelling class added later, e.g. a Unicode-normalised name → fails the contract unless it is added to the allowlist on purpose.

**Setup needed:** a small python or jq glob matcher over the rendered deny list, plus a path generator (a table is enough; no property library is needed).

#### Archive: a dangling symlink at the destination is not replaced; dry-run reports a collision as skip

**Closes gaps:** G8, G9, G10
**Type:** integration (script in a temp repo)
**Priority:** medium (G8 is red at HEAD and needs the one-line fix first); G9 and G10 are low
**File:** `test/scripts/archive-working-docs.bats`
**What it verifies:** The "never overwritten" contract holds for every kind of existing `dest`, and in dry-run.
**Key cases:**
- `ln -s nowhere docs/working/archive/p-plan-foo.md`; `bash "$SCRIPT" p` → the link is still a link (`[ -L … ]`), `plan-foo.md` is still in `docs/working/`, and stderr contains `skip`. Red at HEAD.
- Pre-seed `archive/p-plan-foo.md`; `bash "$SCRIPT" -n p` → output contains `skip  plan-foo.md` and does not contain `move  plan-foo.md`, and the summary count excludes it.
- No argument and no `si-run-id.txt`, run twice. Stub `date` via `PATH`, or accept today's date → the first copy is intact and the second source stays in place.

**Setup needed:** existing `setup()`.

#### questions.sh: an in-repo ancestor symlink

**Closes gaps:** G11
**Type:** integration
**Priority:** low (security impact is small: the write stays inside the repo). But the comment is wrong today.
**File:** `test/questions-doc.bats`, next to `:367`
**What it verifies:** The decided behaviour for `docs -> ./x` and `docs -> .git`: either refused, or allowed with the comment corrected to say so.
**Key cases:** `ln -s .git "$proj/docs"`; `run bash "$QS" init` → the decided status. Assert `.git/working/` presence or absence to match.
**Setup needed:** none.

#### Hook: MultiEdit / `path` key, symlinked HOME, and symlinked CLAUDE_CONFIG_DIR reach the resolve-only deny

**Closes gaps:** G4, G5
**Type:** integration
**Priority:** low. My probes pass today; these are pins against a future refactor of `main()` or `config_dir()`.
**File:** `test/hooks/guard-trusted-writes.bats`
**Key cases:**
- `install_layout`; `MultiEdit` with `{"path": "$PAYLOAD/CLAUDE.md"}` → deny.
- `HOME` = a symlink to `real/`; Write `real/.claude/settings.json` → deny; Write `$HOME/.claude/settings.json` → defer; Write `real/CLAUDE.md` → deny.
- `CLAUDE_CONFIG_DIR=$TEST_TMPDIR/cfglink` (a symlink to `real-cfg`); Write `real-cfg/hooks/x` → deny; Write `cfglink/hooks/x` → defer.

**Setup needed:** none beyond `install_layout`.

#### Case-insensitive filesystem: case variants of HARD entries are never an ungated defer

**Closes gaps:** G3
**Type:** integration, platform-conditional
**Priority:** medium, but only once a case-insensitive runner exists (macOS CI, or a `/mnt/c` WSL job). Until then, record it in What NOT to Test.
**File:** `test/hooks/guard-trusted-writes.bats`
**What it verifies:** Where `$TEST_TMPDIR` is case-insensitive (`touch a; [ -e A ]`, else `skip`), Write `~/.claude/SETTINGS.JSON` in a clean session does not defer.
**Key cases:** `SETTINGS.JSON`, `HOOKS/x.sh`, `claude.md`, each clean → not defer. Red at HEAD on such a filesystem (FC-12a), so it needs a code decision first: for example, compare `samefile`/inode against the real targets.
**Setup needed:** a `skip` guard that detects case-insensitivity.

## What NOT to Test

- **The `_split_row_fields` nameref rename (`out_ref` → `_srf_out`).** It is a pure rename, and the existing `_split_row_fields` callers' tests exercise it. Add a shadowing test only if a caller array is ever named `_srf_*`.
- **`.` / `..` as an archive prefix.** They pass the regex, but the dest is `archive/..-name`, a filename inside `archive/` (FC-23). This is harmless, so a test would only pin trivia.
- **The check-then-`mv` race in the archive script.** Single-operator tool; a test would be flaky and low value.
- **Doc-only edits** (Q-048 and Q-049 text, override-log rows, `rubric.md:156`, the Q-023 timings). Fact-check verifies these (FC-1..6, 10, 30), not bats.
- **The Q-049 paste.** It needs a real logged-in `claude`, which the sandbox cannot run. The defect (FC-7: no control run, output discarded) is a correctness fix to the paste, not a suite test.
- **The G6 deny reason text.** Do not pin it until the wording is fixed (FC-19). Pinning today's text would lock in wrong advice.
- **N3 residue (`..`, `//`, MultiEdit vs Edit/Write deny rules).** Settled as Q-049. The contract test above lists these as explicit exceptions, not assertions.
- **G12 (escaped pipe in Task ID, Round or Source).** The writer never produces one. If the reader is ever refactored onto `_split_row_fields`, the existing tests will cover it.

## Coverage Gaps Beyond Current Scope

**1.** No test drives `scripts/self-improvement.sh` through the hypothesis-logging step with a failing `append_approved_hypotheses`. Whether an SI run should abort there (after merges, at `:1874`) is an undesigned contract (FC-26). An integration test with a stubbed round would pin it.

**2.** The Bash-side HARD matcher (`bash_targets`, `hooks/guard-trusted-writes.py:225-240`) and the file-tool HARD set are still maintained separately, with no shared table-driven test. The TODO(N2) shapes (`:172-184`) are a natural red-test list once N2 is picked up. N2 is deferred and not re-raised here.

**3.** `test/link-claude-home-wiring.bats:238-254` checks the deny rules only in the devcontainer linker's rendering. No test renders or checks the README bare-host `settings.json` wiring the hook relies on (`guides/bare-host-hook-wiring.md`).

## Iteration-2 status (test-strategy view)

| Item | Status | Basis |
|---|---|---|
| N1 | ✅ resolved (behaviour); test residue G1–G5 | Five new N1 tests. M1–M5 are all killed. FC-13 and FC-20 (144/144). The contract test the iter-2 rubric named as the root cause (G2) is still absent, and the bare-host layout (G1) and case-insensitive filesystems (G3) are unpinned. |
| N4 | ✅ resolved | The new test kills M11 and fails on the pre-fix lib (FC-31a). All three readers now split consistently (FC-27). |
| N5 | 🟡 still-open | The comment was reworded but still overclaims for in-repo ancestors (FC-29b). No test covers them (G11). |
| N6 | 🟡 partially resolved (out of my domain) | Both iter-2 errors were fixed. The HARD_FRAG single-token denies and the `CLAUDE_CONFIG_DIR` token are still unmentioned (FC-10). |
| N7 | ✅ resolved | The re-pin to `4c7a2bb` is correct (FC-4). "Fixed" is partial for R1, whose residue is carried as N2. |
| N8 | ✅ resolved | Plain-text pointer (FC-30). |
| N9 | 🟡 code resolved, **test still-open** | Exit 3 vs 2 is implemented and propagates (FC-26). The pointer and `\x1e` comments are fixed (FC-25, FC-28), and the nameref is renamed. The awk-error arm has **no regression test**: M6 survives 0/85 (F1, G7). |
| N10 | ✅ resolved | `config_dir()` docstring (FC-16). Timings hold roughly (FC-5). |
| A6 remainder | ✅ resolved with test residue | The explicit prefix is validated, and its test kills M9 (FC-23). Real-file collisions are skipped and tested. Two edges are untested: a dangling-link dest is overwritten (FC-24, G8), and the dry-run arm is unguarded (G9). The regex copies are settled (Defer). |
| A12 remainder | ✅ resolved | Same as N4. |

## Summary

- **Highest-value test:** the awk-runtime-error test for `_migrate_hypothesis_log_run_column` (G7). It is cheap, and it discriminates (rc 2 vs 0 on the mutant). Without it, the N9 fix can silently revert.
- **N1 tests:** the new hook tests are good and kill every N1 mutant. But the fix still rests on hand-listed spellings. A deny-rule contract test (G2) is what would stop the next N1-class regression.
- **Main residual risk:** the README bare-host layout (G1). It is untested, and my probe shows a checkout-linked global CLAUDE.md is denied while checkout-linked live hooks defer with no gate. That inconsistency is a policy question for security, and the answer should be pinned by a test either way.
- **Open questions:**
  - Should an unreadable hypothesis log abort an SI run after merges (FC-26)?
  - Should a case-insensitive host get a samefile-based HARD check (G3)?
  - Should in-repo ancestor symlinks be refused or just documented (G11)?

## Goal-Alignment Note
- **Success criterion (restated verbatim):** A test-strategy critique saved to /workspace/docs/reviews/test-strategy-review-2026-09-21-answers-iter3.md with `Commit: 31f53e8` on the first line, structured per the test-strategy skill, every finding carrying Evidence and Legibility-target, plus the iteration-2 status table and a Goal-Alignment Note.
- **Answered:**
  - Gaps G1–G12 in the new tests for the hook's hard-resolved/covered split: bare-host README layout, case-insensitive filesystems, MultiEdit/`path` key, symlinked HOME and CLAUDE_CONFIG_DIR, and the contract direction.
  - The awk exit-3-vs-2 propagation: untested; the mutant survives 0/85.
  - Archive no-overwrite: the dangling symlink and dry-run edges are untested.
  - questions.sh ancestor symlink: untested, and the comment is wrong.
  - Whether the tests catch regressions of the invariant: 11 mutation probes, 8 killed and 3 surviving.
  - Recommended tests mapped to gaps, and the iteration-2 status table.
- **Out of scope:**
  - Re-verifying documented behaviour that the fact-check report covers (cited as FC-n).
  - The settled items A7, A8, N2, N3/Q-049, the A6 regex copies and Q-048.
  - Running on a case-insensitive filesystem or with a live `claude`.
  - I modified no tracked file other than this report and made no commit. Scratch scripts are in the session scratchpad.
- **Escalate:**
  - (1) security-reviewer / orchestrator: in the README bare-host layout, per-file-linked live hooks edited by their checkout path **defer**, while the file-linked global CLAUDE.md is **denied** (F2, probe `ts-probe.out`). Decide whether this is consistent with the "never defer on a protected path no deny rule covers" invariant.
  - (2) Orchestrator: FC-26's escalation still stands. The caller handling of a failed migration is undesigned and untested (G7, Beyond-scope 1).
