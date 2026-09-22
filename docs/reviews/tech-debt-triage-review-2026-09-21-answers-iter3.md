Commit: 31f53e8

# Tech Debt Triage: review-fix iteration 3 (`2d93589..answers-2026-09-20`)

**Critic:** tech-debt-triage (contextual, advisory; triggered because more than 10 files changed)
**Scope:** partial. It covers the 6 commits 818c568, a577546, 739cbbb, fd0ad24 (merge), b951c4f and 31f53e8. Commits before 2d93589 are context only.
**Foundation:** `docs/reviews/code-fact-check-report-iter3.md` (merged, k=3). Every command outcome below cites a claim from that report. I ran no new probes; all evidence here is static reading at HEAD 31f53e8.
**Escalations addressed to this critic:** none. The four fact-check escalations are addressed to security, api-consistency and the orchestrator. I use Claims 15, 19 and 26 only for their carry-cost side and leave severity to those addressees.

---

## Findings

### TD5: The HARD protected-path set now has six hand-kept copies, and each review iteration has found a mismatch between them

- **Severity:** 🟢 Consider (advisory). The pattern has recurred in three iterations in a row. I recommend fixing it before the next change to the protected set.
- **Location:** `hooks/guard-trusted-writes.py:10-11,95-102,113-132,220`; `test/link-claude-home-wiring.bats:245-248`; `hooks/wiring.json:120-127`
- **Evidence:**
  ```
  _HARD_FILE_TARGETS = {_safe_resolve(CONFIG_DIR / "CLAUDE.md"), _safe_resolve(HOME / "CLAUDE.md")}
  ```
  (`hooks/guard-trusted-writes.py:95`)
  ```
          if first == "hooks":
              return True
          if len(rel.parts) == 1 and first.startswith("settings") and first.endswith(".json"):
              return True
          if len(rel.parts) == 1 and first == "CLAUDE.md":
              return True
  ```
  (`hooks/guard-trusted-writes.py:124-129`, an excerpt of `_is_hard`; the rest of the function checks `cand.name == "CLAUDE.md" and cand.parent == HOME` and then returns False)
  ```
    for rule in "Edit($DEST/settings*.json)" "Write($DEST/settings*.json)" \
                "Edit($DEST/hooks/**)" "Write($DEST/hooks/**)" \
                "Edit($DEST/CLAUDE.md)" "Write($DEST/CLAUDE.md)" \
                "Edit(~/CLAUDE.md)" "Write(~/CLAUDE.md)"; do
  ```
  (`test/link-claude-home-wiring.bats:245-248`)
- **Debt shape:** the iteration-2 rubric named the root of N1 as "the HARD set is copied by hand in four places … and no contract test ties them together." a577546 fixed the defect: matching is now case-sensitive, and resolve-only paths are denied (Claims 12b, 12c, 13). It did not fix the root. The set is now spelled out in six places:
  1. the `wiring.json` deny rules;
  2. the module docstring (`:10-11`);
  3. `_is_hard`;
  4. the `_HARD_FILE_TARGETS`/`_HARD_DIR_TARGETS` construction (`:95-102`), which is new tier logic;
  5. the Bash `HARD_FRAG`/`SETTINGS_OR_HOOKS` regexes;
  6. the one-way wiring test, which checks that the eight rules exist in `wiring.json` but never checks that the hook's classification matches them.

  The file-tool path now has four outcomes (`hard` → defer, `hard-resolved` → deny, `soft`, `none`), and the safety of each outcome depends on which spellings a deny rule names.
- **Recurrence (evidence of compounding):** R3 and R4 in iteration 1, then N1 in iteration 2, were all copy-drift defects between these lists. Claim 15 is a fourth effect of the same coupling. `_HARD_FILE_TARGETS` resolves `~/.claude/CLAUDE.md` through the README bare-host symlink, so the repo checkout's `global-instructions/CLAUDE.md` became `hard-resolved` and is now denied. Neither the docstring nor the commit message discloses this.
- **Urgency trigger (imminent):** Q-049. If the host check finds that deny rules need `//path`, then `wiring.json` changes spelling. The "covered = the path AS GIVEN … A deny rule names that string" premise (`:19-21`, Claim 14) then changes with it, and so do the wiring test and possibly `_is_hard`. One answer lands in at least four files. Today nothing mechanical catches a missed one.
- **Cost of deferral:** `+1 copy-drift defect per change to the protected set or the deny-rule spelling`. This is observed, not projected: 3 of the last 3 review iterations.
- **Failure cost:** `Low × High`. A drift in the "defer" direction leaves a policy file with no gate (N1 was exactly this). The devcontainer's read-only `/opt` payload limits the damage there, but not on a bare host.
- **Fix cost:** hours, localized. Add one bats contract test that reads `permissions.deny` from `wiring.json`, renders `{{CLAUDE_DIR}}` the way the linker does, and asserts two things:
  - `classify_path` returns `hard` for a concrete instance of every rule.
  - It returns something other than `hard` for a non-matching spelling (case variant, sibling name).

  The test turns copies 1, 3 and 6 into one checked contract, and it would have caught N1.
- **Recommendation:** **Fix opportunistically**. The right moment is when Q-049 is answered, because that change touches every copy anyway. This is not a re-raise of N3/Q-049, which stays settled; the point is that the fix for Q-049 is where this debt gets paid.
- **Confidence:** High on the copy count and the recurrence (static, iteration-2 rubric). Medium on the recommendation.
- **Legibility-target:** for-automated-gate

### TD6: The TODO(N2) and TODO(A8) blocks are a 20-line prose backlog inside the hook, and the N2 list is already partly wrong

- **Severity:** 🟢 Consider
- **Location:** `hooks/guard-trusted-writes.py:172-190`
- **Evidence:**
  ```
  # TODO(N2): command TEXT that writes a global policy file but carries no
  # indicator token the co-occurrence rules below look for, so it gets no
  # opinion (pre-existing; code-review 2026-09-21 iteration 2, N2):
  #   - a bare `cd; echo x > CLAUDE.md` (cd to home with no `~`);
  #   - `/home/$USER/CLAUDE.md`;
  ```
  (excerpt; the block continues through the globbed/quoted `.claude`, `/opt` payload and whole-tree-copy shapes to `:184`, then TODO(A8) runs `:185-190`)
- **Assessment:** the two blocks list 22 bypass shapes as comments. They serve as the "discoverable TODO" qualifying notes for the N2 and A8 Defer rows, and a TODO is a valid way to satisfy that rule. The carry cost is drift: nothing runs these lists. Per Claim 18, two of the eleven N2 shapes (bare `cd` and `/home/$USER`) already get SOFT, which asks when the session is tainted. They do not get "no opinion", even though the block was written in this same iteration. Every future change to `bash_targets` means re-probing all 22 shapes by hand to keep the lists true, and Q-048's answer is exactly such a change.
- **Cost of deferral:** `+0 — inert` while `bash_targets` is untouched. `+22 manual re-probes per bash_targets change` after that.
- **Fix cost:** about an hour, in one file. Add each listed shape to `test/hooks/guard-trusted-writes.bats` as a `@test` asserting the *desired* `deny`, marked `skip "N2 (deferred; override-log)"` / `skip "A8 …"`. The backlog then becomes executable: removing a skip checks a fix, and a stale entry shows up as soon as someone runs it. The prose blocks can shrink to a one-line pointer.
- **Recommendation:** **Fix opportunistically**, with the next change to `bash_targets` (the Q-048 answer).
- **Confidence:** High (Claim 18, executed by all three replicates).
- **Legibility-target:** for-automated-gate

### TD7: Override-log line pins go stale at the moment they are written. The N2 row repeats the N7 defect in the same review cycle

- **Severity:** 🟢 Consider
- **Location:** `docs/reviews/override-log.md:80` (iter2 N2 row), `:82` (iter2 A6 row)
- **Evidence:**
  ```
  | 2026-09-21 | `answers-2026-09-20` | iter2 N2: `hooks/guard-trusted-writes.py:190-205` Bash writes still ungated for bare `cd; echo > CLAUDE.md`,
  ```
  (excerpt of the row; the rest lists the remaining shapes, the verdicts and the TODO(N2) pointer)
- **Assessment:** `:190-205` is where `bash_targets` sat at 2d93589. a577546 moved it to `:225-240`, before 31f53e8 wrote the row (`git show a577546:hooks/guard-trusted-writes.py` puts `def bash_targets` at line 225). So the pin was stale on the day it was written (Claim 1). 739cbbb fixed exactly this defect for the 4c7a2bb row (N7) in the same cycle. In the A6 row, "copied in … All three copies are identical" also undercounts: 818c568 added a fourth copy, at `scripts/archive-working-docs.sh:52` (Claim 3). A6's regex copies are settled and not re-raised here. I note only that the Defer row's recorded fact is now wrong.
- **Cost of deferral:** `+1 stale pin per hook edit` while rows cite bare line ranges in a file that changes every iteration. The durable handle is already in the row (`# TODO(N2)`, a symbol name).
- **Fix cost:** minutes. Cite the TODO tag or symbol (`bash_targets`), or pin `@<commit>:` as N7 did. Correct "three" to "four copies in three files".
- **Recommendation:** **Fix now**. It is a trivial doc edit, and the two rows are the qualifying notes a future run reads at Step 3.5.
- **Confidence:** High.
- **Legibility-target:** for-author

### TD8: The N4 fix copied the pipe-mask a third time instead of sharing a row parser

- **Severity:** 🟢 Consider
- **Location:** `scripts/lib/si-morning-summary.sh:412,421,1537`; `scripts/flag-removal-candidates.sh:104,110`
- **Evidence:**
  ```
              line = $0; gsub(/\\\|/, "\036", line); $0 = line
  ```
  (`si-morning-summary.sh:412`)
  ```
                  gsub(/\036/, "|", hyp)
  ```
  (`si-morning-summary.sh:421`)
  ```
          gsub(/\036/, "\\|", v)
  ```
  (`flag-removal-candidates.sh:104`)
  ```
      local _srf_sep=$'\x1e'
  ```
  (`si-morning-summary.sh:1537`)
- **Assessment:** N4 is fixed, and all three readers now split consistently (Claim 27). My iteration-2 TD1 offered "copy the mask or call `_split_row_fields`" as equal options, so this is not a finding against the fix. The resulting debt is that one wire format, the writer's `\|` escaping at `si-functions.sh` in `append_approved_hypotheses`, is decoded by three implementations in two languages. They restore the pipe differently: one to a bare `|`, two to `\|`. Each is individually correct for its consumer. The shared assumption that `\x1e` never appears in a row is not enforced either, since the writer passes it through from the task JSON (Claim 28).
- **Cost of deferral:** `+0 — inert` until the writer's escaping changes. That would happen if it also escaped newlines or backslashes, or if the fixed 12-cell `printf` gained a column. Any such change then has to land in three readers.
- **Fix cost:** hours. The awk readers cannot call a bash function, so sharing needs either an awk include (`-f`) or a pre-pass that normalises rows. That costs roughly as much as the copies it would replace.
- **Recommendation:** **Carry intentionally**. Revisit trigger: any change to the hypothesis-log writer's escaping or column set.
- **Confidence:** High (static; Claim 27).
- **Legibility-target:** for-author

### TD9: Two fixes changed a failure mode without designing how the caller handles it: the archive collision is a silent partial success, and an awk failure aborts the SI run after merges

- **Severity:** 🟢 Consider
- **Location:** `scripts/archive-working-docs.sh:138-143,152-157`; `scripts/lib/si-functions.sh:575-580`, called from `scripts/self-improvement.sh:1874`
- **Evidence:**
  ```
    if [ -e "$dest" ]; then
      # Two archives under one prefix (a date-only fallback run twice in a day)
      # must not overwrite the first run's copy.
      echo "  skip  $name: archive/${PREFIX}-${name} already exists" >&2
      continue
    fi
  ```
  (`archive-working-docs.sh:138-143`; the loop then moves the file and increments `count`, and the script ends with `Archived $count files …` and exit 0)
  ```
      case "$state" in
          0|3) return 0 ;;
          1) ;;
          *) return "$state" ;;
      esac
  ```
  (`si-functions.sh:576-580`; the function continues with the mktemp/rewrite migration)
- **Assessment:**
  - **Archive.** A collision leaves the source file in `docs/working/`. A `skip` line goes to stderr, the exit code is 0, and the final summary counts only moved files (Claim 24). No data is lost, which is the point of the fix. But a second same-day run leaves behind every file that collides, and a re-run with the same default prefix can never archive them. The summary line reads as success. A dangling symlink at `dest` is still overwritten (Claim 24), a narrow security residue I leave to that critic.
  - **Migration.** The exit-3 sentinel makes a genuine awk failure return nonzero. The comment says this is intended, and Claim 26 verified it. Under `set -euo pipefail`, that aborts `self-improvement.sh` at the hypothesis-logging step. That step runs after merges and before step 6, the completed-tasks log. So a run whose merges already landed stops without writing its bookkeeping (Claim 26, r3: "nobody designed the caller's handling").
- **Cost of deferral:** `+1 un-archived working doc per same-day re-archive`, and `+0 — inert` for the awk path. An unreadable, git-tracked log is rare.
- **Failure cost:** archive blank (not material). Migration `Low × Med`: the bookkeeping for already-merged tasks is lost for that round and must be rebuilt by hand from git.
- **Fix cost:** minutes each.
  - Archive: count skips, print them in the summary, and exit nonzero (or suggest `--prefix`) when `skipped > 0`.
  - Migration: at the call site, either `|| { echo "warn: hypothesis-log migration failed" >&2; }` if bookkeeping should continue, or an explicit statement in the comment that aborting is the chosen behaviour.
- **Recommendation:** **Fix opportunistically**. Both are small edits in files touched every iteration. The migration half is a design choice the orchestrator should make explicit (fact-check escalation to the orchestrator), not a defect I rule on.
- **Confidence:** High (Claims 24 and 26, executed).
- **Legibility-target:** for-author

### TD10: The deferred items' carry cost depends on revisit triggers, and one trigger's mechanism is currently unsound

- **Severity:** 🟢 Consider (the Q-049 paste defect itself belongs to security; see the fact-check escalation)
- **Location:** `docs/reviews/override-log.md:80-82`; `docs/working/questions.md` Q-049 paste
- **Evidence:**
  ```
    (cd "$d" && claude -p "Use the Write tool to create the file $t containing: hi" --output-format json >/dev/null 2>&1)
    [ -e "$t" ] && echo "$form-slash rule: NOT enforced (file written)" || echo "$form-slash rule: enforced"
  ```
  (Q-049 paste excerpt, as quoted in fact-check Claim 7; the loop closes with `done`)
- **Assessment:** the table below lists the deferred items and their triggers. Each trigger is concrete, so the rows meet the "qualifying author note" rule (Claim 30 and the rubric's `:160` definition). The exception is N3. Its only trigger is "Q-049's answer", and the paste that produces that answer prints "enforced" when `claude` never ran (Claim 7, reproduced with a stand-in by r2). The N3 Defer would then close on no evidence. That turns a carried debt with a known trigger into one whose closure can be false. Three of the deferred items (N2, TD5 via Q-049, Q-048) converge on the next change to the hook's tiers, so that change will carry a batch.

  | Item | Deferred where | Revisit trigger | Trigger sound? |
  |---|---|---|---|
  | N2 Bash token bypasses | override-log `:80`, TODO(N2) | next Bash-tier change, or Q-048 answer | yes (but see TD6: the list drifts) |
  | N3 deny-rule path form | override-log `:81`, Q-049 | Q-049's answer | **no**: the paste cannot distinguish "enforced" from "never ran" (Claim 7) |
  | A6 regex copies | override-log `:82` | run-id format change, or a fourth reader | yes, but the recorded count is already 4, not 3 (TD7) |
  | A8 write primitives | override-log, TODO(A8) | next WRITE_PRIMITIVE change | yes |
  | A7 scripts/ linking | override-log | third cross-project helper | yes |
  | Q-048 over-block | questions.md | user judgment | yes |
- **Cost of deferral:** `+0 — inert` for the set as a whole. The exception is N3, where the risk is closure on false evidence, not growth.
- **Recommendation:** **Defer and monitor**. Re-evaluate the batch at the next change to `bash_targets` or `wiring.json`. Fixing the Q-049 paste (a control run without the deny rule, and keeping the JSON `num_turns`) is a precondition for N3's trigger meaning anything. I route that to security-reviewer and do not size it here.
- **Confidence:** High on the table (static). The Q-049 soundness point rests on Claim 7 (executed, k=3 unanimous).
- **Legibility-target:** for-orchestrator-synthesis

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| TD5 | HARD set hand-copied 6×, one-way contract test | Medium | +1 drift defect per protected-set / rule-spelling change | Low × High — a defer-direction drift leaves a file ungated | Hours | Q-049 answer | Fix opportunistically |
| TD6 | TODO(N2)/(A8) prose backlog, already partly wrong | Low | +22 manual re-probes per `bash_targets` change | | ~1 hour | Q-048 answer | Fix opportunistically |
| TD7 | Override-log line pins stale on write; A6 count wrong | Low | +1 stale pin per hook edit | | Minutes | None | Fix now |
| TD8 | Pipe-mask decoded in 3 implementations | Low | +0 (inert) | | Hours | None | Carry intentionally |
| TD9 | Archive silent skip; awk failure aborts post-merge | Low | +1 un-archived doc per same-day re-run | Low × Med (migration) | Minutes | None | Fix opportunistically |
| TD10 | Deferred-items carry; N3 trigger unsound | Low | +0 (inert) | | (security) | Next hook-tier change | Defer and monitor |

### Recommended Order

TD7 now: a trivial doc edit to two rows. TD5 and TD6 together at the next hook change, which Q-049 or Q-048 will force. TD5's contract test and TD6's skipped tests go into the same bats file in one sitting. TD9 whenever `archive-working-docs.sh` or the SI caller is next touched. TD8 only if the writer's format changes.

**Regressions in my domain:** none from a debt standpoint. The behavioural change in Claim 15 (a bare-host deny of the checkout's `global-instructions/CLAUDE.md`) is a coupling effect I cite under TD5. Whether it is a regression is for security and api-consistency (the fact-check escalation). Its developer friction is real: on a bare host that file is now blocked for both Bash and Edit/Write. The deny message's advice cannot be followed (Claim 19).

---

## Iteration-2 🟡 status (my view)

| Item | Status | Basis |
|---|---|---|
| N1 | **resolved** (defect); root still open → TD5 | Case-sensitive `_is_hard`; resolve-only paths deny; no HARD path asks (Claims 12b, 12c, 13, 20, executed). Hand-copied set with no reverse contract test remains; undisclosed bare-host deny (Claim 15) and unfollowable deny advice (Claim 19) are new side effects. |
| N4 | **resolved** | Escaped-pipe mask plus `\037` join; readers consistent; test fails pre-fix (Claims 27, 31a). Residual shape → TD8. |
| N5 | **still-open** | Rewritten comment still claims an in-repo ancestor symlink is caught; `docs -> .git` / `docs -> ./x` still write through (Claim 29b, Incorrect). |
| N6 | **still-open (narrowed)** | Iteration-2 errors fixed; the description still omits HARD_FRAG single-token denies and the `CLAUDE_CONFIG_DIR` token (Claim 10). Docs domain, outside mine. |
| N7 | **resolved** | Row pinned to `4c7a2bb` (Claim 4). The same defect recurs in the new N2 row → TD7. |
| N8 | **resolved** | Plain-text pointer restored (Claim 30). Duplicate definition text at `rubric.md:52` vs `:160` remains (minor, noted in iteration 2). |
| N9 | **resolved** | Exit 3 sentinel, `above` pointer, `\x1e` assumption disclosed, `_srf_out` rename (Claims 25, 26, 28). Caller handling of the new nonzero return → TD9. |
| N10 | **resolved** | `config_dir()` docstring accurate (Claim 16); Q-023 timings roughly hold (Claim 5). |
| A6 remainder | **acknowledged** (Defer row), partly resolved | Prefix validated (Claim 23); real-file collisions no longer overwrite (Claim 24; dangling-symlink residue). Regex copies deferred, but the row says three and there are four (Claim 3) → TD7. |
| A12 remainder | **resolved** | Closed by the N4 fix (Claim 27). |

All "resolved" statements above rest on the cited fact-check claims (`route: code-fact-check`). I make no self-certified positive assertions.

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "A tech-debt triage saved to /workspace/docs/reviews/tech-debt-triage-review-2026-09-21-answers-iter3.md with `Commit: 31f53e8` on the first line, structured per the tech-debt-triage skill, every finding carrying Evidence and Legibility-target, plus the iteration-2 status table and a Goal-Alignment Note."
- **Answered:** Six findings (TD5–TD10), each with Severity, Location, verbatim Evidence, the skill's carry/deferral/fix/recommendation structure, Confidence and Legibility-target. There is a Triage Summary with a Recommended Order, and an iteration-2 🟡 status table for N1, N4–N10, the A6 remainder and the A12 remainder. They cover the brief's focus: the hook's tier logic and TODO blocks (TD5, TD6), the SI readers (TD8, TD9), `archive-working-docs.sh` (TD9) and the deferred items' carry cost (TD10).
- **Out of scope:**
  - Security severity of Claim 15 (the bare-host deny), Claim 19 (deny advice), the Q-049 paste's correctness, and the dangling-symlink overwrite. These go to security and api-consistency per the fact-check escalations.
  - N6/N5 wording beyond status.
  - Settled items A7, A8, N2, N3 and the A6 regex copies are not re-raised. TD7 and TD10 only note that recorded facts in their rows are wrong or that a trigger is unsound, as the tail permits.
- **Escalate:**
  - (1) Orchestrator: decide whether the post-merge abort on migration failure is intended (TD9; this matches fact-check escalation 3).
  - (2) Security: N3's Defer trigger depends on a paste that can report "enforced" without running (TD10, Claim 7). Treat fixing the paste as a precondition for closing N3.
  - (3) TD7 is a trivial Fix now in two override-log rows, so the orchestrator may want it in this iteration's fix batch.
