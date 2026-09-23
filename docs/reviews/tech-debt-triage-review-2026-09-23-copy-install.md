Commit: d0fdd04

# Tech Debt Triage: `ans/copy-install` (712c626..d0fdd04)

Critic: tech-debt-triage (advisory). Scope: debt this diff adds or carries forward in `devcontainer-config/install.sh`, the second `.claude-workflows-manifest` writer, and `test/install-host.bats`. Correctness verdicts belong to the fact-check report (`docs/reviews/code-fact-check-report.md`). I cite its claims and escalations and do not re-run them. I read install.sh in full (1-464), `link-claude-home.sh:30-80`, `test/install-host.bats:1-112` plus the test index, the plan, and the architecture review.

Evidence status: all findings come from reading the code, plus greps run from a script under `$TMPDIR`. I did not run the installer. Execution evidence comes from the fact-check replicates.

## Triage Summary

| # | Debt item | Carrying cost | Cost of deferral | Failure cost | Fix cost | Urgency | Recommendation |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| 1 | Swap block (steps 2–3) has no rollback, no recovery message and no run lock | Low | +0 (inert until it fires) | Low × High: a partly emptied live `~/.claude` | Hours, ~20–40 LOC, one file | **Imminent** (plan step 9 runs it on the real host) | **Fix now** |
| 2 | install.sh is 464 lines holding two targets with different bless semantics | Medium | +~10–40 lines per host-target fix; the pending fix wave crosses 500 | (none) | Days if split; the split has its own cost | Near: this PR's own review-fix loop | **Defer and monitor** |
| 3 | Two `.claude-workflows-manifest` producers, zero readers; `installed_parent` known inaccurate | Low | +0 (inert) until a reader exists | (none) | Hours | None (trigger: first reader) | **Carry intentionally** |
| 4 | `test/install-host.bats` at 391 lines, driven through a util-linux `script` pty | Low | ~+15 lines per new host test; ~7 more tests reach 500 | (none) | Hours | None | **Carry intentionally** |

Counts: Fix now 1 · Defer and monitor 1 · Carry intentionally 2.

---

## 1. Tech Debt Triage: swap block has no rollback or recovery path

**Location:** `devcontainer-config/install.sh:408-437` (`install_claude_home`, steps 2 and 3). The enclosing function runs from :279 to :459. I read all of it.
**Nature:** Robustness/structural debt added by this diff. A multi-step filesystem transaction runs without compensation.
**Cost of Deferral:** `+0 — inert`. The cost does not grow over time. It lands in one step, when the user runs plan step 9 on the live host.
**Failure Cost:** `Low × High`. Probability is low: the `mv` calls are same-filesystem renames, and two concurrent human-TTY runs are rare. Severity is high. A failure between :425 and :436 leaves some of the seven entries in the backup and the rest missing from `~/.claude`. `set -e` then exits with no message naming `$backup`, so every bare-host session loses its skills and hooks until the user reconstructs the state by hand. Fact-check E2 and E7 cover this. E7 includes an executed concurrent run (r2 E5b) in which "the destination ended with none of the seven entries".
**Legibility-target:** for-orchestrator-synthesis

**Evidence** (`install.sh:423-437`):
```
    for name in "${CLAUDE_HOME_NAMES[@]}"; do
      if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
        mv "$dest/$name" "$backup/$name"
      fi
    done
  fi

  # 3. Swap the new copies in.
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
      echo "ERROR: $dest/$name reappeared during the install; the new copy is left at $dest/.cw-new.$name." >&2
      exit 1
    fi
    mv "$dest/.cw-new.$name" "$dest/$name"
  done
```

### Carrying Cost: Low
Day to day, nothing touches this code. Step 1 (:392-406) handles a copy failure correctly. Steps 2 and 3 have none of that care. A bare `mv` failure under `set -e` exits with no message. The "reappeared" error leaves a half-swapped destination and names only the `.cw-new` path, not `$backup`.

### Fix Cost
- **Scope:** localized. One function in one file.
- **Effort:** hours. Add an ERR/failure path over steps 2–3 that moves the backup entries back and prints `$backup`. Take a lock with `mkdir "$dest/.cw-lock"` (no `-p`) before step 1 so concurrent runs refuse rather than collide on `.cw-new.*` (E7).
- **Risk:** low to medium. The fix is itself host-executed boundary code (decision 035), so it needs its own hermetic test, for example T16's read-only trick applied to the backup dir after step 1.
- **Incremental?** yes.

### Urgency Triggers
- Plan step 9: the user's real `~/.claude` is the first production run. Imminent.

### Recommendation

**Recommendation:** Fix now

The failure-cost axis drives this. Carrying cost is near zero, but the only planned run is on the user's live config. The fix is small and local, below the ~50 LOC bar, so fix it in place in this PR's review-fix loop without an RPI loop. At minimum, the error path should print where the backup is and how to move it back.

---

## 2. Tech Debt Triage: install.sh size and two targets in one file

**Location:** `devcontainer-config/install.sh` (464 lines; 158 at 712c626).
**Nature:** Structural. One host-executed, agent-writable file now carries two targets with different bless semantics (hash-receipt bless vs. "human typed y"), three shared helpers (`assemble`, `review_diff`, `confirm`) and module-level shared state (`DECLINED`, `HOST_TMP` plus its EXIT trap).
**Cost of Deferral:** about `+10–40 lines per host-target fix`. The pending review-fix wave for this very diff has several items: the rollback in item 1; fact-check Claim 16, printing REPLACE only for staged paths; E3, naming the dangling path; E5, showing that `$dest` is itself a symlink; E6, empty dirs and nested WIRED matching. Together they very likely add more than the 36 lines left under the 500 guideline (inferred; not measured).
**Legibility-target:** for-author

**Evidence** (plan `docs/working/plan-copy-install-bare-host.md:115` and `:130`):
```
| 5 | ~150 lines added to install.sh (→ ~340; under 500) |
```
```
- **install.sh is 464 lines**, under the 500 guideline.
```
**Evidence** (`install.sh:461-464`, shared state defined after the functions that write it):
```
DECLINED=0
install_devcontainer
install_claude_home
exit "$DECLINED"
```

### Carrying Cost: Medium
The architecture review's structure is in place: one function per target over shared helpers (arch review finding 1). Intra-file coupling is therefore modest, and `CLAUDE_HOME_NAMES` is derived from `CLAUDE_HOME_SRC` (:248-250), which closes the FP-066 subset risk. The real cost is review load. Decision 035 makes every install.sh change a boundary change whose only gate is the Live-verified trailer, and the human now reads about three times as many boundary lines per edit. The plan's estimate missed by ~124 lines (~37%). That overshoot is itself the signal that the host target keeps growing as guards are found. Four more were found in this review.

### Fix Cost
- **Scope:** localized, with a boundary side effect.
- **Effort:** a day. Extract `install_claude_home` and its helpers (:235-459, ~225 lines) into a sourced `devcontainer-config/install-host.sh`.
- **Risk:** medium. This is the second-order cost. A sourced file is equally host-executed and agent-writable, so the split turns one non-inert file into two. Decision 035's trailer rule, and any future hook enforcing it, would have to cover both, or the split quietly opens an ungated path. `cc-isolated.sh`'s `enforcement_files()` deliberately excludes install.sh (arch review :18), and the new file would need the same deliberate treatment.
- **Incremental?** yes. It is a mechanical move once the 035 coverage is decided.

### Urgency Triggers
- install.sh exceeds ~500 lines after this PR's review-fix wave (near-term).
- A third install target is proposed.
- The Live-verified trailer becomes a hook (037 "Until it lands"). The split must be in its path set from day one.

### Recommendation

**Recommendation:** Defer and monitor

The split is the right shape eventually, but today it trades review load for a wider set of non-inert files, and that trade is worse. Revisit when the fix wave lands. If the file is past ~520 lines, split, with the new file named explicitly in decision 035's trailer scope in the same commit. Until then, the function-per-target structure keeps the file workable.

---

## 3. Tech Debt Triage: second manifest producer, no consumer

**Location:** `devcontainer-config/install.sh:439-447`; `devcontainer-config/link-claude-home.sh:70-72`.
**Nature:** Contract debt. Two writers of one file format, with no reader in the repo. A grep of `scripts/`, `hooks/`, `devcontainer-config/` and `docs/decisions/` finds only these two writers and decision 037.
**Cost of Deferral:** `+0 — inert`. The two writers never write the same file: the container's `~/.claude` is the volume `cc-${CC_PROJECT_ID}-claude-config` (`devcontainer.json:79`), and the host's is the real `~/.claude`. They cannot disagree on shared keys, because both copy the `.manifest` that `assemble` wrote (:123-127). The host copy only appends keys.
**Legibility-target:** for-author

**Evidence** (`install.sh:441-447`):
```
  rm -f "$dest/.claude-workflows-manifest"
  cp "$stage/.manifest" "$dest/.claude-workflows-manifest"
  {
    echo "installed_by=host-tty"
    echo "installed_parent=$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d ' ' || echo unknown)"
    echo "installed_at=$stamp"
  } >> "$dest/.claude-workflows-manifest"
```
**Evidence** (`link-claude-home.sh:70-72`):
```
if [ -f "$SRC/.manifest" ]; then
  cp -f "$SRC/.manifest" "$DEST/.claude-workflows-manifest" 2>/dev/null || true
fi
```

### Carrying Cost: Low
The debt only shows up when someone writes the first reader, such as the SessionStart staleness hook or DD [9] that the architecture review names. `installed_parent` is the one field with a trap in it. Fact-check Claim 22 (Incorrect) and E4 show it records `bash`/`sh`, not `script`, under a compound pty command. Decision 037's revisit trigger leans on it anyway. A future reader that trusts the field would be trusting a known-wrong audit trace.

### Fix Cost
- **Scope:** localized. **Effort:** hours. **Risk:** low. **Incremental?** yes.
- Cheapest option: rename the key to something that doesn't imply an audit trace, or add a comment at :445 stating its limits, and correct 037's revisit trigger to match. The fact-check owns the correctness side of this.

### Urgency Triggers
- The first manifest reader is written. It must handle both producers, the host's extra keys included, and must not treat `installed_parent` as evidence of how the installer was run.

### Recommendation

**Recommendation:** Carry intentionally

Two producers with additive keys and no consumer cost nothing today, and the architecture review's "keep the format a superset" rule is honored. Record the trigger. The `installed_parent` wording is the one cheap thing worth doing now, and it rides along with the Claim 22 fix.

---

## 4. Tech Debt Triage: test/install-host.bats size and pty dependence

**Location:** `test/install-host.bats` (391 lines, `# @category slow`, T1–T24).
**Nature:** Testing/portability debt.
**Cost of Deferral:** about `+15 lines per new host-target test`. Item 1's rollback and the other fix-wave items each want a test, so ~7 more reach 500. That is not compounding harm.
**Legibility-target:** for-author

**Evidence** (`test/install-host.bats:42-44`, `:104-108`):
```
need_script() {
  command -v script >/dev/null || skip "util-linux script not installed (needed for a pty)"
}
```
```
run_pty() {
  local input="$1"; shift
  run bash -c 'set -o pipefail; printf "%b" "$1" | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d "\r"' \
      _ "$input" "$*"
}
```

### Carrying Cost: Low
The suite is hermetic, and structured well for its purpose. It runs a copied installer in a throwaway repo and pins HOME, CLAUDE_HOME_DIR, TMPDIR and the devcontainer dirs (:22-35). The pty is unavoidable, because the TTY rule is the thing under test. The costs:
- **Slow-only.** The `--fast` gate (the "864 ok" in d0fdd04) never runs it. The host target is covered only by `--slow` and health-check.
- **Portability (inferred, not run).** `need_script` checks only that some `script` exists. On macOS/BSD, `script` exists but rejects `-qec`, so the pty tests would fail instead of skipping (fact-check E8). Low weight: the user's host is WSL/Linux with util-linux 2.38.1.
- **Tests double as the bypass recipe.** `env -u CLAUDECODE script -qec` is exactly the agent route decision 037 accepts as residual (fact-check Claim 2). That is a documented, accepted cost, not new debt.

### Fix Cost
- **Scope:** localized. **Effort:** hours. **Risk:** low. **Incremental?** yes.
- One-line hardening: have `need_script` probe `script -qec true /dev/null` and skip when it fails. When the file nears 500 lines, splitting by concern (skip rules / migration review / swap and rollback) is mechanical.

### Urgency Triggers
- A macOS host joins (E8).
- The file passes ~500 lines after the fix-wave tests are added.

### Recommendation

**Recommendation:** Carry intentionally

The size is proportional to a 24-case plan, and the pty is inherent. Take the one-line `need_script` probe when someone is next in the file.

---

## Recommended Order
1. **Item 1 now**, in this PR's review-fix loop and before plan step 9. Batch it with the fact-check's Claim 16, E3, E5 and E6 message fixes, since they touch the same function.
2. **Re-measure install.sh after that wave** (item 2's trigger). If it is past ~520 lines, split, and extend decision 035's trailer scope to the new file in the same commit.
3. Items 3 and 4 ride along opportunistically: the `installed_parent` wording with the Claim 22 fix, and the `need_script` probe with the item 1 tests.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: d0fdd04` line.
- Answered: yes
- Out of scope: correctness verdicts on the claims (the fact-check owns those); macOS behavior (not run); line-count growth from the fix wave is estimated, not measured.
- Escalate: item 1 (fact-check E2/E7). The step 2–3 swap has no rollback or recovery message, and its first run is the user's live `~/.claude` in plan step 9. Fix it before that run.
