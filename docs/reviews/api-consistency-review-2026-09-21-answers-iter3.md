Commit: 31f53e8

# API Consistency Review: answers-2026-09-20, review-fix iteration 3 (final)

**Scope:** partial. `git diff 2d93589..answers-2026-09-20` (818c568, a577546, 739cbbb, fd0ad24 merge, b951c4f, 31f53e8). Earlier branch commits were read as context only, except where a sibling on the branch carries the same defect as a fixed line.
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report-iter3.md` (k=3 merged; cited as "FC Claim N"). Iteration-2 rubric: `docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20-iter2.md`. My iteration-2 critique: `docs/reviews/api-consistency-review-2026-09-21-answers-iter2.md`.
**Probes:** none of my own. The fact-check report covers every command outcome cited here. I read code and docs statically.

**Escalation actioned:** the fact-check escalated the bare-host "hard-resolved" deny of `global-instructions/CLAUDE.md` to me (FC Escalations, first entry). I took it; it is **F1** below. The escalation about the awk caller, addressed to the orchestrator, overlaps my exit-code focus, so I cover its contract side in **F5**.

## Baseline Conventions

- **The hook's decision contract.** The documented rule, stated in `hooks/wiring.json:26-30`, `devcontainer-config/link-claude-home.sh:127-131`, `guides/bare-host-hook-wiring.md:52-56`, `README.md:170` and decision 023 amendment B: for the file tools the hook **defers** on HARD and lets `permissions.deny` block. It **asks** on SOFT only when the session is tainted. For Bash it **denies** on HARD. a577546 changes this contract: a subset of file-tool HARD paths now gets `deny`.
- **Tier tokens.** Before this diff, `classify_path` and `bash_targets` returned single-word tiers: `"hard"`, `"soft"`, and `"none"`/`None` (`hooks/guard-trusted-writes.py:134-169,225-240`). `main()` maps each tier to one decision per tool.
- **Deny and ask reasons.** Before this diff there was one deny reason (Bash, `:263-264`) and two ask reasons (`:266-267,287-288`). Each is one or two sentences: what was hit, then what to do.
- **SI script return codes.** Library functions in `scripts/lib/si-functions.sh` document `Args:` and return 0 on "nothing to do" (`:501-502`). Bookkeeping steps in `scripts/self-improvement.sh`, which runs under `set -euo pipefail` (`:45`), are best-effort, with `|| true` (`:1863,1866`). The one existing hard-error exit-3 convention is `scripts/confine-tests.sh:27,117`.
- **archive-working-docs.sh output.** It prints two-space verbs: `keep` and `move` on stdout, `warn` on stderr (`:129,136,145`). Fatal errors print `Error: …` on stderr and exit 1 (`:59-60`). A final summary line counts files moved (`:155-157`).
- **Override-log rows.** Format per `skills/code-review/references/override-log.md:13-22`. The `Finding` cell includes `path:line` and the critic "so future runs can match by location". Allowed `Override verdict` values: `Won't-Fix`, `Defer`, `Accepted-immutable`, …
- **Running-questions `you: terminal` entries.** Q-011 and Q-045 in `docs/working/questions.md` each have a question line, a `Read:` line, one paste, `What I do with it`, `Interim`, and (Q-011) `If the answer differs`. They ask for raw output back ("Paste the whole output back"); they do not ask for a pre-judged verdict.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `"hard-resolved"` (tier token) | return value / internal enum | `"hard"`, `"soft"`, `"none"` | `hooks/guard-trusted-writes.py:134-169,225-240` | **Inconsistent.** The docstring calls this tier `resolved`, the test title and commit call it "resolve-only HARD", and the code calls it `hard-resolved`. Its sibling is `covered` in the docstring but `"hard"` in code, and `"hard"` still means the whole HARD umbrella and the Bash deny tier. See F3. |
| `_rel_under(cand, dirs)` (was `_global_rel`) | private function | `_safe_resolve`, `_is_hard`, `_split_row_fields` | `hooks/guard-trusted-writes.py:84-132` | Consistent: `_`-private, and it now takes the dir list explicitly. |
| `_is_hard(cand, dirs)` (new required param) | private function signature | `classify_path(fp)`, `bash_targets(cmd)` | same file | Consistent. Both callers are in-file (`:147,152`) and updated; there are no external callers (`rg classify_path\|_is_hard` finds only this file). |
| deny reason "This write reaches a protected policy file (…)" | user-facing message | Bash deny reason `:263-264`, ask reasons `:266-267,287-288` | same file | **Inconsistent.** The remediation differs from the Bash sibling and cannot be followed. See F2. |
| `exit 3` (no-header sentinel) | awk exit code | `confine-tests.sh` exit 3 (hard error) | `scripts/confine-tests.sh:27,117` | Minor clash. In `confine-tests.sh`, 3 means a hard error; here it means "benign, nothing to do". The sentinel is private to one function, so the clash is informational. |
| `_srf_out` (nameref, was `out_ref`) | shell local | `_srf_line`, `_srf_raw`, `_srf_sep` | `scripts/lib/si-morning-summary.sh:1531-1546` | Consistent. This closes the iter2 N9 bullet. |
| `\037` row join in `_project_state_open_hypotheses` | internal field separator | `\037` in `append_approved_hypotheses` (`si-functions.sh:522-539`); `\036` mask in `flag-removal-candidates.sh:103-110` | as listed | Consistent. It reuses both existing separators for the same purposes. |
| `  skip  <name>: …` (stderr) | CLI output verb | `keep`, `move`, `warn` | `scripts/archive-working-docs.sh:129,136,145` | Consistent in shape. The summary line does not count skips; see F6. |
| `Error: prefix '…' must match [A-Za-z0-9._-]+` | CLI error | `Error: $WORKING_DIR not found. Run from repo root.` | `scripts/archive-working-docs.sh:59` | Consistent (`Error:` prefix, stderr, exit 1). |
| `Q-049 · deny-rule-absolute-path-form` | question slug | `guard-cooccurrence-overblock`, `sni-proxy-domain-fronting`, `mathlib-cache-host` | `docs/working/questions.md` | Consistent: kebab-case noun phrase. |
| override-log `Defer` rows (N2, N3, A6) | log vocabulary | A8 and A7 `Defer` rows | `docs/reviews/override-log.md` | Consistent in verdict and column order. Two cells are stale; see F8. |

## Findings

#### F1: File-tool edits to the bare-host checkout's `global-instructions/CLAUDE.md` are now an un-approvable deny, and the change is undisclosed

**Severity:** Breaking
**Location:** `hooks/guard-trusted-writes.py:95,154-155,279-285`
**Move:** 3 (consumer contract), 6 (versioning impact)
**Confidence:** High on behaviour (FC Claim 15, executed at 31f53e8 and at 2d93589). Medium on whether it is intended.
**Legibility-target:** for-author

**Evidence:**
```
95:_HARD_FILE_TARGETS = {_safe_resolve(CONFIG_DIR / "CLAUDE.md"), _safe_resolve(HOME / "CLAUDE.md")}
154:    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
155:        return "hard-resolved"
```
```
README.md:14: ln -s ~/claude-workflows/global-instructions/CLAUDE.md ~/.claude/CLAUDE.md
```
In the README bare-host layout, `_HARD_FILE_TARGETS` resolves to the repo checkout's own `global-instructions/CLAUDE.md`. That file is therefore "hard-resolved", and a clean `Edit` of it returns `deny`, where 2d93589 deferred (FC Claim 15; `docs/reviews/execution-logs/iter3-r2-hook-probes-b.txt`). A hook `deny` cannot be approved in the permission prompt. So a bare-host session that develops this repo can no longer edit its global instructions with Edit or Write at all. That is this repo's own normal edit path: `git log -- global-instructions/CLAUDE.md` shows branch commits such as 2360a7e. The devcontainer is unaffected, because its link target is `/opt`.

This does make the file tools agree with the Bash tier, which already denies a write naming `CLAUDE.md` plus `global-instructions` (`:206-207,232-233`). So the new behaviour may be the intended policy. But nothing records it as a contract change: not the docstring (`:22-27`, whose examples are the `/opt` payload and a symlinked project `.claude`), not a577546, not the bare-host guide, and no test. Bare-host users also re-copy the hook by hand (`README.md:32-35`), so the change reaches them silently on their next re-copy.

**Recommendation:** Make it a deliberate decision. Either (a) keep the deny: name the checkout path in the docstring's `resolved` examples, add a bats case for the README layout, add a line to `guides/bare-host-hook-wiring.md`, and make the deny reason point to the real route (see F2); or (b) exempt a HARD target reached by its real path when that path is inside a git checkout. (b) is a policy call, so option (b) belongs in a `you: judgment` question, not an autonomous edit.

#### F2: The new deny reason gives a remediation that cannot be followed and that contradicts the Bash sibling's

**Severity:** Inconsistent
**Location:** `hooks/guard-trusted-writes.py:282-285` (sibling: `:263-264`)
**Move:** 4 (error consistency)
**Confidence:** High (FC Claim 19, k=3 unanimous Incorrect)
**Legibility-target:** for-author

**Evidence:**
```
282:            emit("deny", f"This write reaches a protected policy file ({Path(fp).name}: "
283:                         ".claude hooks/settings or global CLAUDE.md) through a symlink or "
284:                         "resolved path that permissions.deny does not name. Edit it at its "
285:                         "~/.claude path, with review.")
```
```
263:            emit("deny", "Bash write to a protected policy file (.claude hooks/settings, global CLAUDE.md). "
264:                         "Edit it directly with review, not via a shell write.")
```
The two deny reasons tell the agent to do different things for the same protected set, and neither route exists:

- **File tool.** "Edit it at its ~/.claude path, with review" names exactly the spelling `permissions.deny` blocks. A deny is not reviewable (FC Claim 19). If the deny rules do not match (N3), that spelling defers, so the edit goes through with **no** review.
- **Bash.** "Edit it directly with review" sends the agent to a file tool, which is blocked the same way.
- **Hard-coded `~/.claude`.** The file-tool reason ignores `CLAUDE_CONFIG_DIR`. `config_dir()` (`:81-82`) makes the config dir movable, so the protected file may not be under `~/.claude` at all. This is the same class as iter2 F6 (questions.sh hints).
- **Wrong in the bare-host case.** In F1's case the reason says "through a symlink or resolved path", but the agent used the file's real, un-symlinked path. The symlink is `~/.claude/CLAUDE.md`, which the agent never named.
- **Parenthetical shape.** The parenthetical puts the file name and the whole category list together (`(CLAUDE.md: .claude hooks/settings or global CLAUDE.md)`). The ask reasons put only the file name in parentheses (`:288`).

A consumer reading the reason, whether the agent or the user looking at the transcript, gets instructions that lead into a second deny.

**Recommendation:** Give both deny reasons one shared remediation that is true: for example, "This is a protected policy file; change it outside Claude Code (a human edit), not through the agent." Build the path from `CONFIG_DIR` rather than a literal `~/.claude`, and drop "through a symlink" or make it conditional on `p != rp`.

#### F3: The tier tokens now use three vocabularies, and `"hard"` means three things

**Severity:** Minor
**Location:** `hooks/guard-trusted-writes.py:18-27,134-136,146-155,275-279`; `test/hooks/guard-trusted-writes.bats:457`
**Move:** 2 (naming), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Precedent: single-word tier tokens `"hard"` / `"soft"` / `"none"` used in `hooks/guard-trusted-writes.py:134-169` (`classify_path`) and `:225-240` (`bash_targets`)

**Evidence:**
```
19:            covered  = the path AS GIVEN (lexical, or normpath with `..` folded) names a
22:            resolved = the path is HARD only after resolve() (or only under the config
135:    """"hard" (a deny rule names this string: defer), "hard-resolved" (HARD only
457:@test "N1: the payload CLAUDE.md and hooks by their real path are denied (resolve-only HARD)" {
```
After a577546, the covered sub-tier is `covered` in the docstring and `"hard"` in code, and the resolved sub-tier is `resolved`, `"hard-resolved"` and "resolve-only HARD" in different places. `"hard"` itself now carries three meanings:

1. The HARD umbrella in the docstring (`:10`).
2. The *defer* sub-tier returned by `classify_path` (`:148`).
3. The *deny* tier returned by `bash_targets` (`:230`).

A maintainer reading `if tier == "hard": defer()` (`:275-278`) next to `if tier == "hard": emit("deny", …)` (`:260-263`) sees the same token mapped to opposite decisions. My iteration-2 F2 flagged the shared "HARD" name across tools; this diff adds a third meaning. All the tokens are internal (no consumer outside the file), so the impact is on maintainers only.

**Recommendation:** Rename the file-tool returns to match the docstring: `"hard-covered"` and `"hard-resolved"`, or rename the docstring labels to match the code. Use one term in the test titles as well.

#### F4: Consumer docs still say the hook defers on every file-tool HARD path

**Severity:** Minor
**Location:** `README.md:170`; `guides/bare-host-hook-wiring.md:52-56`; `hooks/wiring.json:26-30`; `devcontainer-config/link-claude-home.sh:127-131`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
guides/bare-host-hook-wiring.md:52: The deny rules are not optional. On its HARD tier (`~/.claude/settings*.json`,
guides/bare-host-hook-wiring.md:54: defers for the file tools instead of returning "ask", because a hook "ask" silently
README.md:170: - `hooks/guard-trusted-writes.py` — `PreToolUse` gate on writes to trusted-policy files: hard-deny on Bash write primitives targeting protected config paths, ask on soft policy paths when the session is web-tainted
```
Every consumer-facing description of the hook's decision table predates a577546. They say the file tools defer on HARD, and README says deny happens only for Bash. The file tools now also return `deny`, for resolve-only HARD paths. The bare-host guide is where F1's affected user would look.

**Recommendation:** Add one clause to each: "…and denies outright a HARD file reached only through a symlink or its resolved path (no deny rule names it)." Decision 023's amendment is historical and can stay as it is.

#### F5: `_migrate_hypothesis_log_run_column` gained a failure return with no documented contract, and its only caller turns it into a mid-run abort

**Severity:** Minor
**Location:** `scripts/lib/si-functions.sh:556-580,514`; `scripts/self-improvement.sh:1874-1875`
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High (FC Claim 26, executed: an unreadable log returns 2 and aborts the SI run after merges)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
562:# Args: $1 = hypothesis log path
566:    # Exit 0 = header has a Run cell, 3 = no header row at all, 1 = migrate.
576:    case "$state" in
577:        0|3) return 0 ;;
578:        1) ;;
579:        *) return "$state" ;;
580:    esac
```
```
514:        _migrate_hypothesis_log_run_column "$log_file"
```
```
self-improvement.sh:1866:            git commit -m "docs(failure-patterns): harvest FP entries from round ${ROUND} fix tasks" 2>/dev/null || true
self-improvement.sh:1874:    append_approved_hypotheses "$ROUND" "$TASKS_FILE" \
```
N9 is fixed as stated: a real awk failure now propagates. But the function documents only `Args:`. The "Exit 0/3/1" line describes awk's internal codes, not what the function returns, and a reader can easily take it for the function's contract. The caller treats the call as best-effort: `append_approved_hypotheses` returns 0 when its inputs are missing (`:501-502`) and discards jq errors (`:538`). Its neighbours in `self-improvement.sh` swallow failures with `|| true` (`:1863,1866`). Yet under `set -euo pipefail` this one detection failure now ends the whole run at the logging step, after tasks have merged (FC Claim 26; r3: "nobody designed the caller's handling").

**Recommendation:** Add `# Returns: 0 = no-op or migrated; non-zero = the log could not be read or rewritten` to the header. Then pick one caller policy and write it down. Consistent with the neighbours: `_migrate_hypothesis_log_run_column "$log_file" || echo "  Warning: could not migrate $log_file" >&2`. If the log's integrity matters more than finishing the run, say so in a comment at `:514`.

#### F6: archive-working-docs.sh changed its CLI contract without updating its usage header, and a collision reports success

**Severity:** Minor
**Location:** `scripts/archive-working-docs.sh:4-8,52-55,138-143,153-157`
**Move:** 3 (documentation drift), 4 (error consistency)
**Confidence:** High (FC Claims 23, 24)
**Legibility-target:** for-author

**Evidence:**
```
4:# Usage: scripts/archive-working-docs.sh [-n|--dry-run] [PREFIX]
141:    echo "  skip  $name: archive/${PREFIX}-${name} already exists" >&2
157:  echo "Archived $count files to $ARCHIVE_DIR/ with prefix '$PREFIX'."
```
Three things are wrong:

- **Usage header.** The header (`:4-22`) states neither new rule: PREFIX must match `[A-Za-z0-9._-]+` or the script exits 1, and an existing archive copy makes the file stay in `docs/working/`.
- **Collision reads as success.** On a collision the script exits 0, and the closing line counts only moved files. A caller or a user skimming stdout sees "Archived N files" and exit 0 while files are left behind; the `skip` lines went to stderr (FC Claim 24).
- **Symlink edge.** "An existing archive copy is never overwritten" does not hold for a dangling symlink at the destination, because `[ -e ]` follows links (FC Claim 24, r1+r2).

Leaving the source file in place on a collision is the safe choice and matches the test's intent. The gap is that the outcome is not reported.

**Asymmetry, disclosed and acceptable:** an unusable *recorded* run id silently falls back to the date (`:45-49`), while an unusable *explicit* prefix is fatal. Explicit input is refused and recorded state is recovered from, which is defensible. Consider a `warn` line on the silent fallback.

**Recommendation:** Add both rules to the usage header. End with `Archived N files (M skipped: already archived)` when M > 0. Test with `[ -e "$dest" ] || [ -L "$dest" ]`.

#### F7: The questions.sh header still overclaims ancestor-symlink coverage (N5 unresolved)

**Severity:** Minor
**Location:** `scripts/questions.sh:47-51`
**Move:** 3 (documentation drift)
**Confidence:** High (FC Claim 29b, executed)
**Legibility-target:** for-author

**Evidence:**
```
48:# and, for the default paths, never land outside the git toplevel (an
49:# ancestor symlink such as a symlinked docs/ is caught by that check, not by
50:# the per-file one). Explicit QUESTIONS_LIVE/ARCHIVE paths get only the
```
The toplevel check catches a symlinked `docs/` only when the link leads *outside* the repo. `docs -> .git` and `docs -> ./x` still let `init` write through, with exit 0: the iteration-2 counterexample is unchanged (FC Claim 29b; `docs/reviews/execution-logs/iter3-r2-questions-ancestor.txt`). The comment is the script's documented write-safety contract for repos it runs in, and it still promises more than the code does.

**Recommendation:** Reword to "an ancestor symlink that leads outside the toplevel is caught by that check; one that stays inside the repo is not". Or check each ancestor with `-L`.

#### F8: Two new override-log rows carry stale facts that Step 3.5 matching reads

**Severity:** Minor
**Location:** `docs/reviews/override-log.md` (N2 row and A6 row, 2026-09-21, top of table)
**Move:** 3 (contract)
**Confidence:** High (FC Claims 1, 3)
**Legibility-target:** for-automated-gate

**Evidence:**
```
| 2026-09-21 | `answers-2026-09-20` | iter2 N2: `hooks/guard-trusted-writes.py:190-205` Bash writes still ungated for bare `cd; echo > CLAUDE.md`, …
| 2026-09-21 | `answers-2026-09-20` | iter2 A6 remainder: the run-id charset `^[A-Za-z0-9._-]+$` is copied in `scripts/self-improvement.sh`, `scripts/archive-working-docs.sh` and `scripts/lib/si-morning-summary.sh` `_valid_run_id` (architecture/tech-debt). | 🟡 Must-Address | Defer | All three copies are identical and tested; …
```
The format reference makes `path:line` in `Finding` load-bearing: "so future runs can match by location" (`skills/code-review/references/override-log.md:20`). Two cells are wrong:

- **N2 row.** It pins `:190-205`, where `bash_targets` sat at iteration 2. At this commit `bash_targets` is at `:225-240` and the `TODO(N2)` block is at `:172-184` (FC Claim 1). A future re-flag of `bash_targets` at its real lines will not location-match the row. It can still match by category.
- **A6 row.** It says "three copies … All three copies are identical", but 818c568 added a fourth copy of the regex, at `archive-working-docs.sh:52` (FC Claim 3). The Defer rests on a count that was already wrong when the row was written.

The N7 fix pins the 4c7a2bb row to its commit (`… :56-132 as of \`4c7a2bb\``). That is the right pattern, and these two rows did not follow it.

**Recommendation:** Pin the N2 location as `31f53e8:hooks/guard-trusted-writes.py:225-240` (and TODO `:172-184`), following the N7 precedent. Change the A6 row to "four copies in three files".

#### F9: N8 fixed one dead link in the rubric template, but a sibling link in the same fence is dead too, and the worked example was never mirrored

**Severity:** Minor
**Location:** `skills/code-review/references/rubric.md:60,155-157,25-29`; `test/skills/code-review/rubric-current-format.md:99-100`
**Move:** 3 (documentation drift), 2 (consistency within one artifact)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
rubric.md:28: `test/skills/code-review-format-contract.bats` asserts against, so changes to the template
rubric.md:29: here must be mirrored there in the same commit.
rubric.md:60: [next-action derivation](chat-synthesis.md#next-action-derivation).
rubric-current-format.md:99: To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
rubric-current-format.md:100: carry an author note. 🟢 items are optional.
```
Line 60 sits inside the same code fence as `:156`. A relative link to `chat-synthesis.md` is dead in every rubric emitted to `docs/reviews/`, which is the defect N8 fixed at `:156`. It is not on `main`, so it came in on this branch. Separately, the template's own rule (`:28-29`) says template changes must be mirrored in the worked example "in the same commit". The footer changed in 1ae52af and again in 739cbbb, but the example still reads "carry an author note". The contract test does not assert the footer, so nothing catches the drift.

**Recommendation:** Make `:60` plain text, the same way as `:156` ("see 'Next-action derivation' in `skills/code-review/references/chat-synthesis.md`"). Copy the `:155-157` footer into `rubric-current-format.md:99-100`.

#### F10: Q-049 departs from its `you: terminal` siblings: its paste returns a verdict, not evidence. Q-048's description still omits two triggers

**Severity:** Informational
**Location:** `docs/working/questions.md` (Q-049 paste and "What I do with it"; Q-048 body line)
**Move:** 3 (user-facing contract)
**Confidence:** High (FC Claims 6, 7, 10)
**Legibility-target:** for-author

**Evidence:**
```
  (cd "$d" && claude -p "Use the Write tool to create the file $t containing: hi" --output-format json >/dev/null 2>&1)
  [ -e "$t" ] && echo "$form-slash rule: NOT enforced (file written)" || echo "$form-slash rule: enforced"
```
(The excerpt ends inside the `for` loop; the remainder is `done`.)

**Q-049.** Its sibling terminal entries ask for raw output back ("Paste the whole output back", Q-045) so the agent can judge it. Q-049 throws the JSON and stderr away and prints a conclusion the entry then acts on ("if single-slash is enforced, N3 is closed"). FC Claim 7 shows that a failed or unauthenticated run prints "enforced". Security owns the correctness finding; the contract point is that this entry breaks the terminal-entry convention the user has learned. It also lacks the `If the answer differs:` line that Q-011 carries, although `What I do with it` covers that ground. `questions.sh check` passes (FC Claim 6).

**Q-048.** The N6 rewrite fixes both iteration-2 errors. It still omits two things (FC Claim 10): a write naming `.claude/hooks`, `.claude/settings` or `managed-settings` is denied with no second indicator, and matching is case-insensitive. The first of these predates Q-048's rule, so the omission is mostly scope. The user is still deciding "keep or narrow" from a partial rule.

**Recommendation:** Have the Q-049 paste print the JSON's `num_turns` and `is_error`, plus a control run with no deny rule, and ask for the output back. Add one clause to Q-048: "(`.claude/hooks`, `.claude/settings`, `managed-settings` are denied on their own; matching ignores case)".

## Iteration-2 status (my domain)

| Item | Status | Basis |
|---|---|---|
| N1 (my iter2 F1) | **resolved** | `_is_hard` is case-sensitive, resolve-only HARD returns `deny`, and no probed HARD path asks (FC Claims 12b, 12c, 13, 20, 22). New consequences are raised as F1–F4. The docstring's "a deny rule names that string" for `..`/`//` is N3-adjacent and settled (FC Claim 14). |
| N4 (my iter2 F3) | **resolved** | Escaped pipes are masked with `\036` and the row is joined with `\037`. All three readers now agree, and the test fails on the pre-fix code (FC Claims 27, 31a). |
| N5 | **still-open** | The rewording still overclaims for in-repo ancestor links (FC Claim 29b; F7). |
| N6 | **resolved** (Informational residue) | Both misstatements are fixed. Two omissions remain (FC Claim 10; F10). |
| N7 | **resolved** | Pinned `as of 4c7a2bb`, past tense (FC Claim 4). "Fixed in c5a7c96" is partial for R1, whose residue is N2 (settled). |
| N8 | **resolved** at `:156` | FC Claim 30. The same defect remains at `:60`, and the fixture was not mirrored (F9, new). |
| N9 | **resolved** | Sentinel 3 vs awk 2 (FC Claim 26), "above" pointer (25), the `\x1e` wording is now an explicit assumption (28), and the `_srf_out` rename. The caller contract gap is F5 (new). |
| N10 | **resolved** | `config_dir()` wording (FC Claim 16), and the timings hold roughly (FC Claim 5). |
| A6 remainder | **resolved / acknowledged** | Prefix validation and no-overwrite are fixed (FC Claims 23, 24), apart from the dangling-symlink edge (F6). The regex copies are acknowledged by the Defer row, but that row miscounts (F8). |
| A12 remainder | **resolved** | Carried by N4. |

## What Looks Good

- **Case-sensitive HARD matches the deny rules.** The case-folded SOFT fallback keeps case variants gated when tainted (FC Claim 12c). On Linux this restores "HARD == exactly what permissions.deny covers". Whether a case-insensitive filesystem (macOS) is safe is open and escalated to security (FC Claim 12a).
- **The invariant now holds for the probed layouts.** It says: never ask on a deny-covered path, never defer on an uncovered HARD path. The resolve-only tier denies instead of deferring onto nothing (FC Claim 13; `route: code-fact-check`).
- **The N4 fix reuses the existing separators.** `\036` mask, `\037` join. It adds no new convention and it has a regression test.
- **The archive script leaves the source file in place on a collision.** That is the safe default, and the new prefix error matches the script's existing `Error:` format and exit code.
- **The override-log rows use the established `Defer` vocabulary and column order**, and each carries a revisit trigger. N2 and A8 have discoverable `TODO` blocks at the code site (FC Claim 1).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | Bare-host `global-instructions/CLAUDE.md` now an un-approvable deny, undisclosed | Breaking | `hooks/guard-trusted-writes.py:95,154-155,279-285` | High (behaviour) / Medium (intent) |
| F2 | Deny remediation cannot be followed; differs from the Bash sibling | Inconsistent | `hooks/guard-trusted-writes.py:282-285` | High |
| F3 | Tier-token vocabulary split; `"hard"` has three meanings | Minor | `hooks/guard-trusted-writes.py:18-27,134-155,275-279` | High |
| F4 | Consumer docs still say file-tool HARD always defers | Minor | `README.md:170`, `guides/bare-host-hook-wiring.md:52-56` | High |
| F5 | Migrate function's failure return undocumented; caller aborts the run | Minor | `scripts/lib/si-functions.sh:562-580,514` | High |
| F6 | Archive CLI: usage header stale; collision reports success; symlink edge | Minor | `scripts/archive-working-docs.sh:4-8,138-143,157` | High |
| F7 | questions.sh ancestor-symlink comment still overclaims (N5) | Minor | `scripts/questions.sh:47-51` | High |
| F8 | Override-log N2 line pin stale; A6 copy count wrong | Minor | `docs/reviews/override-log.md` | High |
| F9 | Sibling dead link in the rubric template fence; fixture not mirrored | Minor | `skills/code-review/references/rubric.md:60`; `test/skills/code-review/rubric-current-format.md:99-100` | High |
| F10 | Q-049 paste returns a verdict, not evidence; Q-048 omissions | Informational | `docs/working/questions.md` | High |

## Overall Assessment

The fix commits close what they set out to close in my domain: N1, N4, N6–N10 and the A6 remainder. The internal names follow the existing conventions. The one substantive problem is a consumer-contract change. The new "hard-resolved" deny changes a public decision (defer → un-approvable deny) for the README bare-host layout's `global-instructions/CLAUDE.md` (F1). Its deny reason then sends the user to a route that is also denied (F2), and every consumer doc still describes the old decision table (F4). That should be decided deliberately rather than shipped silently. Everything else is fixable in place with text-level edits: a shared, truthful remediation string, one tier vocabulary, a `Returns:` line and a warning at one caller, an updated usage header, and two re-pinned log cells. No finding suggests the author skipped the survey of existing conventions. Most are drift between a fixed line and its siblings.

## Goal-Alignment Note
- **Success criterion (restated verbatim):** An API-consistency critique saved to /workspace/docs/reviews/api-consistency-review-2026-09-21-answers-iter3.md with `Commit: 31f53e8` on the first line, structured per the api-consistency-reviewer skill (including the name-pattern audit), every finding carrying Evidence and Legibility-target, plus the iteration-2 status table and a Goal-Alignment Note.
- **Answered:**
  - All ten focus areas are covered:
    - the hook's decision contract and the new tier (F1, F3);
    - the deny reason text (F2);
    - file-tool vs Bash tier semantics (F2, F3);
    - docstring vs behaviour (F3, F4);
    - the migrate exit-code contract and its callers (F5);
    - archive CLI, prefix and collision behaviour (F6);
    - Q-048/Q-049 as user-facing contracts (F10);
    - override-log row format (F8);
    - the rubric.md pointer (F9, N8 status).
  - Name-pattern audit and iteration-2 status table included.
  - The fact-check escalation addressed to me (bare-host deny) is actioned as F1.
- **Out of scope:**
  - Q-049 paste correctness and the case-insensitive-filesystem safety question belong to security-reviewer (FC Escalations). I referenced them only as contracts.
  - Settled items (A7, A8, N2, N3/Q-049 substance, A6 regex copies, Q-048 false denies) are not re-raised. F8 only notes that two settled rows now carry stale facts.
  - I ran no probes of my own. All behaviour claims cite FC claims.
- **Escalate:** F1 needs a user policy decision before merge: should the checkout's global instructions be edit-denied on bare hosts? I suggest a `you: judgment` question. The SI caller policy in F5 (warn and continue, or abort) is the orchestrator's call, per the FC escalation.
