Commit: 9075003

# Tech-debt triage — Q-094 unit A (`q094-exit-scan-worktree-layout`, dfe4c0d..9075003), final confirming pass

Critic: tech-debt-triage (contextual; unit >500 changed lines). Advisory.
Scope: `devcontainer-config/cc-exit-scan.sh` (+175/-?), `test/cc-isolated-functions.bats` (+189), guide (+32), plan (+111), `cc-isolated.sh` (+3/-1). `docs/reviews/` excluded (prior artifacts).
Inputs: the whole of `scan_std_worktrees` (806–896) and its helpers `_snap_hash_str` (777–781), `_snap_file_is` (785–792), `_snap_wrel` (290–294), plus `scan_git_dirs` (120–144), `_snap_size_ok`, `_snap_first_line`, `_snap_gitdir`, `git_exec_snapshot` (656–), `git_exit_scan` (904–), `cc-gitdir.sh` `gitdir_common`; plan; the Stage-1 fact-check summary; override-log row 135; unit B's diff stat (HEAD of the worktree), used only to see where the function is heading.

Executed (archive of 9075003 in scratch, `TMPDIR`/`LC_ALL=C`/isolated git config):
- `bats test/cc-isolated-functions.bats`: 169/169 pass. `bats --timing`: suite 87.9 s of test time, the nine Q-094 tests 33.3 s, one of them 17.4 s.
- Direct timing of `scan_std_worktrees` under `pipefail`: 49 ms on a real snapshot, 161 ms with 40 000 padding records. The function is not slow; the test is (finding T1).
- `bash -c 'set -u; echo $((zz + 1))'` → `zz: unbound variable` (relevant to finding T4).

Headline: no carrying-cost item is High and none has a material failure cost, because every piece of debt found here fails **closed** (a drift makes the scan decline and warn, not pass). One item is cheap and worth doing before merge (T1, a one-line test change that cuts ~18 % off the suite's runtime). One is a lapsed commitment that needs one line of paperwork, not code (T2). The long function is real but tolerable debt with a clear revisit trigger (T3).

---

## Findings

### T1 — Pipefail test spends 16 s building its padding in a bats-traced loop

- **Severity:** Low
- **Location:** `test/cc-isolated-functions.bats:2280` (test at 2273, "large snapshots under pipefail neither lose the note nor skip the W refusal")
- **Evidence:**
  ```
    for i in $(seq 40000); do pad+="F"$'\t'"zz"$'\t'"/p/$i"$'\t'"missing"$'\n'; done
  ```
  Measured in a throwaway bats file, same loop vs one `printf`:
  ```
  ok 1 loop in 16064ms
  ok 2 printf in 99ms
  ```
  The test takes 17 432 ms of the suite's 87 881 ms (20 % of runtime for 1 of 169 tests). `scan_std_worktrees` itself on the padded input: 161 ms. The cost is bats' per-command DEBUG trap firing 40 000 times, not the code under test.
- **Triage:** Carrying cost Low–Medium (every local run and every review-loop run pays ~16 s; the review-fix loop runs this suite many times per unit). Cost of deferral: `+16 s per full-suite run`. Fix cost: minutes, one line, no risk, the same bytes:
  `pad="$(printf 'F\tzz\t/p/%s\tmissing\n' $(seq 40000))"$'\n'`
  **Recommendation: Fix now** (trivial, single file, in place).
- **Confidence:** High (measured both ways).
- **Legibility-target:** whoever runs the suite next / the parent before merge.

### T2 — Override-log row 135's "next scan change" trigger fired here and was neither honoured nor re-deferred

- **Severity:** Medium (process/legibility; no correctness impact found)
- **Location:** `docs/reviews/override-log.md:135` (in the branch); new caller at `devcontainer-config/cc-exit-scan.sh:814`
- **Evidence:** row 135:
  ```
  | 2026-09-27 | `integrate/q076` | The scan reads `commondir`'s first line itself instead of via cc-gitdir.sh (`devcontainer-config/cc-exit-scan.sh`) — architecture 2 remainder, security confirm N4 | 🟡 Must-Address | Acknowledged | Only matters for a state already present at launch, which launch_gitdir_ok now refuses; fold into cc-gitdir.sh at the next scan change. |
  ```
  Unit A is that next scan change. `cc-gitdir.sh` is not in the diff; no commit message in dfe4c0d..9075003 (or in unit B up to 2eebdf8) mentions row 135, `gitdir_common`, or a deferral; the plan does not either. Unit A adds a third caller of the duplicate reader:
  ```
    dirs="$(scan_git_dirs "$ws" 2>/dev/null)" || return 1
  ```
  and a third ad-hoc size cap for a small git pointer file next to `gitdir_common`'s:
  ```
    [ "$(stat -c %s -- "$p/gitdir" 2>/dev/null || echo 99999)" -le 4097 ] || return 1   # PATH_MAX + \n
  ```
  vs `cc-gitdir.sh:59` `[ "$s" -gt 0 ] && [ "$s" -le 4096 ] || return 1`.
- **Why it is not a correctness problem in A:** `scan_std_worktrees` takes `common` from `scan_git_dirs` and then requires it to equal the exit snapshot's own `F commondir` record (818–819), which the same reader produced — so the two can only agree or decline. The new worktree's `commondir` is never parsed, only byte-hashed against `H("../..\n")`. The divergence from git's reading (CR/LF trimming, empty/oversize handling) still only matters for a launch-time state, as row 135 says.
- **Triage:** Carrying cost Low. Cost of deferral: `+1 call site per scan change` (A added one; the fold gets slightly bigger each time, and the "next scan change" promise can keep slipping unseen). Failure cost: blank (not material; fail closed). Fix cost: hours — two readers in one file (`scan_git_dirs` 134–136, `_snap_gitdir` 585–589) switched to `gitdir_common`, plus tests for CR/empty `commondir`; risk medium-low because snapshot record values could change for odd `commondir` files. Folding it into A now would reopen a unit that just finished a 3-iteration loop, which is poor value.
  **Recommendation: Fix opportunistically** — as its own small unit — but record the re-deferral **now** (one line updating row 135's resolution, e.g. "Q-094 A/B did not fold it; next: <trigger>"), so the Must-Address acknowledgment does not silently lapse. That line is the only action needed before merge.
- **Confidence:** High that the trigger lapsed unrecorded (grep of commits, plan, diff). Medium that no correctness effect exists beyond what row 135 already describes (reasoned from 814–819, not separately executed).
- **Legibility-target:** the parent/merger and the next reader of the override log.

### T3 — `scan_std_worktrees` is one 91-line function with 28 exits, and unit B grows it to 119

- **Severity:** Low
- **Location:** `devcontainer-config/cc-exit-scan.sh:806–896`
- **Evidence:** signature and locals:
  ```
  scan_std_worktrees() {
    local ws="$1" before="$2" after="$3" dirs common wsp ccommon="" cws="$GIT_EXIT_SCAN_CONTAINER_WS"
    local diff line rec q attrs n p hk dk k wtrel wt g h ok std re pre lnk _snap_bytes=0
    local -a added=()
    local -A left=() used=() dot=()
  ```
  26 scalar/array locals; `return 1` appears 28 times between 806 and 896. `line`, `attrs` and `re` are each reused for 3+ unrelated values (e.g. `line` is the expected commondir record at 818, the diff line at 829, the parsed record tail at 841, the back-pointer content at 862, and the note text at 894). The function does six jobs in sequence: preconditions (W refusal, commondir record), record-level diff, classification, per-worktree validation (private dir on disk → back-pointer → `.git` file → container form), completeness, note rendering. At the worktree HEAD (unit B) the same function is 119 lines.
- **Triage:** Carrying cost Medium-Low: it is the most security-sensitive function in the file, and every review iteration so far edited it; reviewers have to hold all 26 names at once, and reused names (`line`) are how a future edit checks the wrong value. Mitigated well by tests: 9 tests (12 with B), each negative case paired with a positive control, and every check that returns 1 fails closed. Cost of deferral: `+~25 lines and one more branch per accepted shape` (B added the removal shape; plan B25, git ≥ 2.48 relative paths, is the obvious next one). Failure cost: blank — a mistaken edit most plausibly declines (false warning); the fail-open risk is an edit that skips a check, which the pairing tests catch. Fix cost: hours; extract the per-worktree block (840–889) into a helper (e.g. `_std_wt_added <n>`) returning 0/1 and the consumed keys, and give the reused `line`/`attrs` distinct names. Incremental: yes. Risk: medium (dynamic scoping of `left`/`used`/`dot` and `_snap_bytes` must survive the move).
  **Recommendation: Defer and monitor** — revisit trigger: the next acceptance shape added to this function (e.g. accepting `worktree.useRelativePaths` output, plan B25), or any change after unit B that touches 840–889. Doing it now would reset the review loop on A and conflict with B, which already rewrites this region.
- **Confidence:** High on the measurements; Medium on the carrying-cost judgment.
- **Legibility-target:** the next maintainer of `cc-exit-scan.sh` and the unit-B reviewer.

### T4 — Record format and helper contracts are re-encoded by hand in the reader (duplicated path/quoting logic)

- **Severity:** Low
- **Location:** `devcontainer-config/cc-exit-scan.sh:818, 848, 850, 874, 880` (reader) vs `_snap_file` (222–256) and `git_exec_snapshot:675` (writer); `_snap_hash_str` 777–781 vs `_snap_hash` 167–174; `local … _snap_bytes=0` at 808.
- **Evidence:**
  - Hand-built record strings duplicating the writer's format:
    ```
    line="F"$'\t'"commondir"$'\t'"$(printf '%q' "$ws/.git")"$'\t'"$(printf '%q' "$common")"
    hk="+F"$'\t'"hooksdir"$'\t'"$(printf '%q' "$p/hooks")"$'\t'"missing"
    dk="${dot["+F"$'\t'"dotgit"$'\t'"$(printf '%q' "$wt/.git")"]:-}"
    re="^file [0-7]+ $std\$"
    ```
    (the last duplicates `_snap_file`'s `attrs="file $m $h"`).
  - The 16-hex truncation now lives twice: `_snap_hash` `printf '%s' "${h:0:16}"` (173) and `_snap_hash_str` `printf '%s' "${h:0:16}"` (780).
  - `_snap_bytes=0` in `scan_std_worktrees`' locals is load-bearing and uncommented: `_snap_file_is` calls `_snap_size_ok`, which does `_snap_bytes=$((_snap_bytes + s))`; under the launcher's `set -euo pipefail` an unset name there is an error (`bash -c 'set -u; echo $((zz + 1))'` → `zz: unbound variable`). The header at 144 says the `_snap_*` helpers "run inside git_exec_snapshot and share its locals"; `_snap_hash_str` and `_snap_file_is` now also run outside it, borrowing that contract.
- **What makes this cheap to carry:** every drift fails closed. A change to the attrs format, the hash length, or the `%q` form makes the reader's strings stop matching → decline → full warning. Removing `_snap_bytes=0` makes `_snap_size_ok` error inside the `note="$(...)"` subshell → decline. The one fail-open drift — renaming the `W` record letter in `_snap_wrel` without updating the `$'\n'W$'\t'` check at 812 — is caught by the relative-hooksPath test (test at `test/cc-isolated-functions.bats:2367` expects `warns_listing_wt`). The container mount path duplication (`GIT_EXIT_SCAN_CONTAINER_WS=/workspace` vs `devcontainer.json`) is likewise pinned by a test (`grep -q "target=$GIT_EXIT_SCAN_CONTAINER_WS,"`). Good practice; no finding there.
- **Triage:** Carrying cost Low (the symptom of drift is a false warning, i.e. the Q-094 problem coming back, not a bypass). Cost of deferral: `+0 — inert` until the record format changes. Fix cost: hours: a `_snap_rec <kind> <path> <attrs>` constructor used by writer and reader, `_snap_hash_str` sharing a `_snap_trunc` with `_snap_hash`, and a one-line comment on the `_snap_bytes=0` local. The comment is minutes and worth doing whenever the function is next touched.
  **Recommendation: Carry intentionally** (add the `_snap_bytes` comment opportunistically; revisit the constructor if the record format ever changes).
- **Confidence:** High (read and executed).
- **Legibility-target:** the next maintainer of `cc-exit-scan.sh`.

### T5 — The acceptance rule is stated in four places, and they already disagree

- **Severity:** Low
- **Location:** `cc-exit-scan.sh:75–84` (header STANDARD WORKTREES), `cc-exit-scan.sh:793–805` (function doc comment), `guides/cc-isolated-usage.md:334–351`, `docs/working/plan-q094-exit-scan-worktree-layout.md` rule 5.
- **Evidence:** the Stage-1 fact-check lists drift across all four after three iterations, e.g. header "(Your own config's relative hooksPath is walked in each new worktree, so its records refuse the note as well.)" is false for a container-form worktree (executed, rc 0); the doc comment and plan rule 5 omit the `.`/`..` name decline, the 4097-byte cap, `.`/`..`/`//` path parts, the working-tree-inside-common-dir decline; guide "(other than `.`)" misses the insteadOf `.`/`""` cases. Commit `5fadfc2 docs(cc-exit-scan): review iteration 2 — drop stale "or removed" wording` is a whole commit spent on this drift.
- **Triage:** Carrying cost Low (comments, not behaviour), but it compounds: cost of deferral `+1 doc-fix per rule change` (each of the three review iterations produced one). Fix cost: under an hour: make the function doc comment the single normative statement ("the full rule is here"), and have the header, guide and plan point to it with a one-sentence summary each — the header already half-does this ("scan_std_worktrees has the rule"). The plan is a dated working doc and can simply be marked superseded for rule details.
  **Recommendation: Fix opportunistically** — when the comment-accuracy fixes from the fact-check are applied (they touch the same lines).
- **Confidence:** High (drift documented by fact-check, sampled here).
- **Legibility-target:** users reading the guide; the next reviewer.

### Not a finding: test-suite growth

+189 lines / +9 tests (2 205 → 2 394 lines, 160 → 169 tests); unit B adds +77 / +3. The new tests reuse existing fixtures (`scan_repo`, `plant_hook`, `session_stub`, `make_repo`), add two small helpers (`std_wt`, `warns_listing_wt`), and pair negatives with positive controls. Growth is proportional to a security-relevant acceptance rule. Other than T1, their runtime is about 11 s total. Carry.

---

## Triage Summary

| # | Debt item | Carrying cost | Cost of deferral | Failure cost | Fix cost | Urgency | Recommendation |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| T1 | 40k-iteration padding loop in the pipefail test (16 s) | Low–Med | +16 s per suite run | | Minutes | None | Fix now |
| T2 | Row 135 "next scan change" lapsed without record; +1 `scan_git_dirs` caller | Low | +1 call site per scan change | | Hours (fold) / 1 line (re-defer) | Now (for the record line) | Fix opportunistically |
| T3 | `scan_std_worktrees` 91 lines, 26 locals, 28 exits (119 in B) | Med–Low | +~25 lines per accepted shape | | Hours | Next acceptance shape (B25) | Defer and monitor |
| T4 | Record format / hash truncation / `_snap_bytes` contract re-encoded in the reader | Low | +0 — inert | | Hours | None | Carry intentionally |
| T5 | Acceptance rule stated in 4 places, drifting | Low | +1 doc-fix per rule change | | < 1 hour | None | Fix opportunistically |

### Recommended order
1. T1 before merge (one line, no review risk).
2. T2's record line before merge (override-log row 135 resolution updated with the new trigger); the fold itself as its own unit.
3. T5 together with the fact-check comment fixes.
4. T3 and T4's constructor at the next acceptance-shape change, as one refactor; T4's `_snap_bytes` comment whenever 806–812 is next edited.

## Goal-Alignment Note

The unit's goal — stop the exit scan crying wolf on agent worktrees without letting a sandboxed session make host git run something new unwarned — is served, and none of the debt above works against it: every structural shortcut found (hand-built record strings, duplicate hash truncation, the borrowed `_snap_*` contract, the long function) fails **closed**, so its failure mode is the old false warning returning, not a bypass. The one fail-open drift path (the `W` letter) and the one external coupling (the `/workspace` mount path) are both pinned by tests. The debt worth attention is about the loop's own economics rather than the code's safety: a test that costs 20 % of suite time for no coverage reason (T1), and a Must-Address acknowledgment whose trigger passed silently (T2). Neither blocks merge; T1 and T2's record line are cheap enough to do first.
