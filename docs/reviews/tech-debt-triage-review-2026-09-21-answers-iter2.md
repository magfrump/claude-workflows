Commit: 16f2978

# Tech Debt Triage: review-fix iteration 2 (`f023357..answers-2026-09-20`)

**Critic:** tech-debt-triage (contextual, advisory)
**Scope:** partial. Covers the fix commits for R5, A6, A12 and C11 only. Commits before f023357 are context.
**Foundation:** `docs/reviews/code-fact-check-report-iter2.md`. I rely on Claims 1, 10, 12, 13, 14, 17, 21, 22, 23 and 24 as they stand and do not re-verify them.
**Probes:** hermetic, run under a temp HOME. Output is in `scratchpad/tech-debt-triage/` (`probe.py`, `wd/hypothesis-log.md`).

---

## Findings

### TD1: The A12 fix corrected one of three hypothesis-log readers, and a second reader still drops piped rows

- **Severity:** 🟡 Must Address (behavioral, pre-existing, not a regression)
- **Location:** `scripts/lib/si-morning-summary.sh:404-418` (`_project_state_open_hypotheses`)
- **Evidence:**
  ```
      rows=$(awk -F'|' -v oc="$outcome_col" -v sc="$source_col" '
          /^\|/ {
              if ($0 ~ /^\|[ \t]*(Round|----)/) next
              round = $2; tid = $3; hyp = $4; outcome = $(oc)
  ```
  (excerpt; the rest of the function trims the fields, prints the rows whose `outcome == ""`, and counts them)

  The awk splits on every `|`, including the `\|` that `append_approved_hypotheses` writes (`scripts/lib/si-functions.sh:546`, `hyp="${hyp//|/\\|}"`). On a piped row, `$(oc)` therefore lands one cell to the left of Outcome, in "Checked at Round". The writer always fills that cell (`%d` = `round + window`, `si-functions.sh:548-549`), so every **open** row with a piped hypothesis looks closed and is left out.
  Probe with two open rows, one plain and one containing `a \| b`:
  ```
  Open hypotheses: 1
  - **plain** (round 1): no pipe here *[planner-authored — review framing]*
  ```
- **Debt shape:** there is no shared row parser for `hypothesis-log.md`. Three readers use three different split strategies:
  - `_split_row_fields` masks `\|` with `\x1e`. This is the e6a6a5f fix.
  - `scripts/flag-removal-candidates.sh:103-110` already masked `\|` with `\036`. That is prior art the fix repeated rather than reused.
  - `_project_state_open_hypotheses` does not mask at all.
- **Cost of deferral:** `+1 silently-miscounted open hypothesis per approved task whose hypothesis contains a pipe`. The count feeds the morning summary's Project State block.
- **Fix cost:** hours, localized to one file. Apply the same `gsub(/\\\|/, "\036", line); $0 = line` mask used in `flag-removal-candidates.sh`, or iterate with `_split_row_fields`. Add one bats case next to e6a6a5f's in `test/morning-summary-clusters.bats`.
- **Recommendation:** **Fix now**. It is a trivial fix of under ~10 LOC in one file and closes the rest of A12.
- **Confidence:** High (executed).
- **Legibility-target:** for-author

### TD2 (C11): The Bash tier root was patched with co-occurrence rules, not normalised. The debt moved from spelling bypasses to token bypasses plus false denies

- **Severity:** 🟢 Consider (advisory)
- **Location:** `hooks/guard-trusted-writes.py:166-205`
- **Evidence:**
  ```
  _HOME_INDICATORS = [r"~", r"\$HOME\b", r"\$\{[!#]?HOME\b", r"\.claude\b",
                      r"global-instructions", r"CLAUDE_CONFIG_DIR"]
  ...
      if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):
          return "hard"
      # A10: settings*.json / hooks plus the config dir named anywhere.
      if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
          return "hard"
  ```
  (excerpt of `bash_targets`; the remainder returns `"soft"` on `SOFT_FRAG`, else `None`)

  I probed the pre-fix hook (`f023357`) against HEAD with the same HOME:
  ```
  echo x > /home/$USER/CLAUDE.md               old=defer  new=defer
  cd; echo x > CLAUDE.md                       old=defer  new=defer
  echo x > ~/.clau*/settings.json              old=defer  new=defer
  cp y ~/.cl*/hooks/x.sh                       old=defer  new=defer
  cd ~/.cl""aude && echo {} > settings.json    old=defer  new=defer
  echo x > ~/.claude/"settings".json           old=defer  new=defer
  echo x > ~/.claude/set\tings.json            old=defer  new=defer
  echo x > "$HOME"/CLAUDE.md                   old=defer  new=deny
  echo x > ~//CLAUDE.md                        old=defer  new=deny
  cd ~ && echo x > CLAUDE.md                   old=defer  new=deny
  ```
- **Assessment:** C11 recommended canonicalising the text before matching. The fix instead widened what the matcher accepts. Every variant that spells the path *prefix* (`~`, `$HOME`, `${HOME…}`, `//`, `/./`, `..`) now falls into one indicator test. That closes the class that kept reopening, including iteration 1's accepted residual `cd ~ && … CLAUDE.md`.
  - The remaining escapes (Claim 1) all obfuscate a **token**: the `.claude` directory name, `settings`/`hooks`/`CLAUDE.md` via quotes, globs or backslashes, or a home dir reached with no home indicator.
  - All of them are **pre-existing** (old=defer). None is a regression.
  - Canonicalisation alone would not close the glob and `$D` cases either, because they need shell expansion. The underlying root is structural: a regex over shell text cannot know where the shell writes.
  - The trade is now explicit. Bypasses got rarer, and false denies became the accepted Q-048 behaviour.
- **Cost of deferral:** `+0 (inert)` while the rule stays broad. It becomes `+1 reopened spelling class per narrowing change` if Q-048 is answered by tightening the indicators, the same dynamic C11 described.
- **Failure cost:** `Low × High`. The escapes need deliberate obfuscation by injected content. An escape writes to a trusted-policy file with no gate, and the sandbox that used to back this up is down.
- **Recommendation:** **Defer and monitor**. Re-trigger when either happens: (a) the Q-048 answer narrows `_HOME_INDICATORS`/`_CFG_INDICATORS`, or (b) the next change to `bash_targets`. At either point, weigh a post-hoc check against the regex tier, e.g. a PostToolUse diff of the protected files' hashes, which does not depend on spelling.
- **Confidence:** High (executed) on the old/new comparison. Medium on the recommendation.
- **Legibility-target:** for-orchestrator-synthesis

### TD3 (A6): The run-id contract is still enforced only by convention, and its charset regex now has three copies

- **Severity:** 🟢 Consider
- **Location:** `scripts/self-improvement.sh:460`, `scripts/archive-working-docs.sh:45`, `scripts/lib/si-morning-summary.sh:1155`; naming rule at `si-morning-summary.sh:1199`; overwrite at `scripts/archive-working-docs.sh:49,135`
- **Evidence:**
  ```
  scripts/self-improvement.sh:460:if [[ ! "$SI_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
  scripts/archive-working-docs.sh:45:  if [[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
  scripts/lib/si-morning-summary.sh:1155:    [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
  scripts/lib/si-morning-summary.sh:1199:                 printf '%s\n' "$working_dir/archive/${run}-tasks-round-$round.json"
  scripts/archive-working-docs.sh:49:PREFIX="${PREFIX:-$(date +%Y-%m-%d)}"
  scripts/archive-working-docs.sh:135:    mv -- "$f" "$dest"
  ```
- **Assessment:** the three concrete defects are fixed:
  - (a) The default id is unique per second (`si-functions.sh:469-471`).
  - (b) An absent or empty `si-run-id.txt` no longer matches every run (Claim 22).
  - (c) The Run cell is validated at all three readers (Claim 23).

  The structural part of A6 remains:
  - The charset rule went from 2 copies at f023357 (morning-summary had 0) to 3.
  - `archive/<run>-<name>` is still re-derived by the reader rather than shared with `archive-working-docs.sh`.
  - When `si-run-id.txt` is absent, which is the normal state after one archive, the date-only fallback plus `mv` without `-n` still lets a second manual archive on the same day overwrite the first.
  - An explicit prefix argument is not validated (Claim 23 r2).
- **Cost of deferral:** `+0 (inert)`. The three copies agree today, and the values are single-maintainer, low-churn constants.
- **Fix cost:** hours. `archive-working-docs.sh` is standalone and does not source `si-functions.sh`, so sharing the rule means sourcing a lib from it.
- **Recommendation:** **Carry intentionally**. Revisit if the charset or the archive naming scheme changes, since that edit has to land in three files.
- **Confidence:** High (static).
- **Legibility-target:** for-author

### TD4 (R5): Non-atomic in-place rewrite. Residual only

- **Severity:** 🟢 Consider
- **Location:** `scripts/lib/si-functions.sh:586`
- **Evidence:**
  ```
      ' "$log_file" > "$tmp" && cat "$tmp" > "$log_file" || rc=$?
  ```
- **Assessment:** `cat tmp > file` keeps the inode and mode, as intended, but gives up atomicity. If the process is interrupted between the truncate and the write, the tracked log is left truncated. Separately, the detection awk exits 2 on failure, which is also the no-header sentinel (Claim 14, already reported). That debt is inherent to the chosen trade-off. The file is git-tracked, and the migration runs once per log, so the log can be restored from git.
- **Cost of deferral:** `+0 (inert)`. It is a one-time migration.
- **Recommendation:** **Carry intentionally**.
- **Confidence:** High (static).
- **Legibility-target:** for-author

---

## Iteration-1 finding status

- R5: resolved. `scripts/lib/si-functions.sh:568-588` is a true no-op on the Run-present and no-header paths and keeps inode and mode on migration (Claim 21 Verified). The residuals are TD4 and Claim 14's exit-code collision.
- A6: partially-resolved. Same-day collision (`si-functions.sh:469-471`), live-match (`si-morning-summary.sh:1166-1173`) and Run-cell validation (`:1018`, `:1189`, `:1350`) are fixed. The coupling by convention and the duplicated regex remain and have grown to 3 copies. The date-fallback archive overwrite at `archive-working-docs.sh:49,135` also remains (TD3).
- A12: partially-resolved. `_split_row_fields` (`si-morning-summary.sh:1521-1540`) is fixed (Claim 24). The sibling reader `_project_state_open_hypotheses` (`:404-418`) still splits naively, and a probe shows a piped open row dropped (TD1). The writer's fixed 12-cell `printf` (`si-functions.sh:548`) is unchanged.
- C11: partially-resolved (re-patched, not addressed). Co-occurrence widening at `hooks/guard-trusted-writes.py:171-201` replaced canonicalisation. It closes the path-prefix spelling class, including the iteration-1 residual `cd ~ && …`. All remaining escapes are pre-existing token obfuscations (TD2). The installed-symlink fixture half of C11 is done (Claim 17 Verified).

**Regressions introduced by the fixes (my domain):** none found. Every probed Bash spelling either stayed at `defer` or moved from `defer` to `deny`. None moved the other way.

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "A markdown critique saved to /workspace/docs/reviews/tech-debt-triage-review-2026-09-21-answers-iter2.md, structured per your role skill, with an `## Iteration-1 finding status` section covering your domain items, ending with a Goal-Alignment Note."
- **Answered:** R5, A6, A12 and C11 are each adjudicated with file:line. Four findings: TD1 Must Address (new evidence, executed), TD2–TD4 Consider.
- **Out of scope:** security severity of the Claim 1 bypasses (security-reviewer's escalation); questions.sh (R2/A3/A4/A11); Q-048 wording; the wiring.json `/` vs `//` escalation.
- **Escalate:** TD1 is a live miscount on the A12 path that none of the fact-check claims covered, so the orchestrator should tier it. No positive "Confirmed Good" assertions made. The resolution statements above rest on fact-check Claims 17, 21, 22, 23 and 24 (`route: code-fact-check`).
