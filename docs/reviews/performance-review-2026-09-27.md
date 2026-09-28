Commit: 795ff71

# Performance Review — integrate/q077-q078-q080

**Scope:** `git diff main...HEAD -- . ':!docs/reviews'` (Q-077 hook deny rules, Q-078 report stamp, Q-080 skill descriptions)
**Date:** 2026-09-27
**Based on:** docs/reviews/iter2-code-fact-check-report.md, code-fact-check-report-r1/-r2/-r3.md (Q-077/Q-078), pass2-code-fact-check-report-r1/-r2/-r3.md (Q-080)

## Data Flow and Hot Paths

- **`hooks/auto-approve-allowed-commands.sh` — HOT.** A PreToolUse hook that runs once per Bash tool call, synchronously, before the command runs or a prompt appears. It is a new process each time, so nothing is cached between calls: every call re-reads the settings files. N is small: 3 settings files, about 11 deny rules and about 20 allow rules in this container, 1–10 commands extracted per call. The cost is dominated by process spawns (`jq`, `sed`, `sort`, `git`, `shfmt`), not by the matching loops.
- **`test/skills/runner-contract.bash` `report_stamp` — COLD.** Runs once per report check (test runs, health-check) and once per generation. It hashes the skill dir, the runner and the fixture.
- **`skills/*/SKILL.md` descriptions — per-session context.** Frontmatter descriptions are loaded into the skill listing at the start of every session, so their length costs context tokens on every session.

### Measurements (this container, WSL2, bash 5.2, 2026-09-27)

Scratch scripts are in the session scratchpad (`perf/bench.sh`). Hook input: `git status && ls -la | grep foo`, run from `/workspace` against the real settings files. There were 5 interleaved rounds of 30 calls each.

| Version | Per-call latency (5 rounds, µs) | Median |
|---|---|---|
| main `old.sh` | 89,857 / 106,593 / 108,482 / 108,574 / 116,310 | ~108 ms |
| HEAD `new.sh` | 168,490 / 174,692 / 193,014 / 231,907 / 240,824 | ~193 ms |

Component costs (20-run means): one `jq -r` on settings.json ≈ 14.8 ms; `git rev-parse --show-toplevel` ≈ 0.9 ms; one trivial `sed` ≈ 1.0 ms; `sort -u` ≈ 0.9 ms. The new deny loader adds 3 `jq`, 6 `sed`, 1 `sort` and a second `git rev-parse` per call, about 50 ms of spawns. That accounts for most of the measured increase. The rest is noise in this shared environment.

## Findings

#### Deny-rule loader roughly doubles the per-Bash-call hook latency with a second set of per-file `jq` spawns

**Severity:** Low
**Location:** `hooks/auto-approve-allowed-commands.sh:124-148` (`extract_deny_from_file`, `get_deny_globs`), called from `main` at `:262`
**Move:** Hidden multiplication / work in the wrong place
**Classification:** Micro (constant per-call process-spawn overhead) / Hot path (runs on every Bash tool call)
**Confidence:** High (measured)
**Baseline:** Per-call hook latency is ~108 ms median on main and ~193 ms median on HEAD. Both were measured 2026-09-27 in this container (5×30 interleaved runs, `perf/bench.sh`).

Evidence:
```
extract_deny_from_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  jq -r '.permissions.deny[]? // empty' "$file" 2>/dev/null | deny_rules_to_globs
}
...
get_deny_globs() {
  ...
  local git_root
  git_root=$(find_git_root)
  {
    extract_deny_from_file "$HOME/.claude/settings.json"
    if [[ -n "$git_root" ]]; then
      extract_deny_from_file "$git_root/.claude/settings.json"
      extract_deny_from_file "$git_root/.claude/settings.local.json"
    ...
  } | sort -u
}
```
(excerpt; `get_deny_globs` :133-148 read in full, and `deny_rules_to_globs` :120-123 is two `sed` processes)

`get_allowed_prefixes` (:170-194, unchanged) already runs `find_git_root` and one `jq` per file over the same three files. The new loader parses the same JSON again with its own `jq` per file and calls `git rev-parse` a second time. That raises the `jq` spawns per call from 4 (3 allow + 1 input) to 7, and each `jq` costs about 15 ms here. The deny list is also loaded before the "no Bash allow rules → exit" early return at :274. A host with no Bash allow rules now pays ~50 ms for a hook that cannot approve anything. At a few hundred Bash calls per session this adds seconds to tens of seconds of wall time per session. That is not user-visible per call next to model-turn latency, which is why this is rated Low and not Medium. The fix is cheap and would make HEAD faster than main: a single `jq -rn '[inputs] | .[] | ((.permissions.allow[]? | "A\t"+.), (.permissions.deny[]? | "D\t"+.))' f1 f2 f3` over all three files measured 14 ms, against ~84 ms for the current 6 per-file `jq` calls.

**Recommendation:** Read allow and deny in one `jq` over the existing files, compute `git_root` once, and split the output in bash. Also move the "no allow prefixes" early exit ahead of the deny load, or merge the two loads. Re-measure against the 108 ms / 193 ms baselines above. Correctness is the reason this code exists, so it is fine to defer the fix. Keep the per-command deny check in any refactor.

#### `report_stamp` no longer hashes the shared contract — one less hash per check (informational)

**Severity:** Informational
**Location:** `test/skills/runner-contract.bash:198-203`
**Move:** Find the work that moved
**Classification:** Micro / Cold path (test-time report check)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

Evidence:
```
report_stamp() {
  local sk="$1" skill="$2" fixture="$3"
  printf 'skill %s\n' "$(_stamp_hash_path "$sk/../../skills/$skill")"
  printf 'runner %s\n' "$(_stamp_hash_path "$sk/$skill/runner.bash")"
  printf 'fixture %s\n' "$(_stamp_hash_path "$sk/$skill/fixtures/$fixture")"
}
```
The diff drops one single-file hash (`runner-contract.bash`) from each stamp computation. That is a small reduction, not a regression. The larger effect is operational: a harness edit no longer marks every skill's reports stale, so fewer expensive `claude -p` regenerations are triggered. That trade is accepted in the branch intent. The unchanged per-file `_stamp_sha256` subprocess loop in `_stamp_hash_path` (:163-179) still scales linearly with the number of files in the skill dir. That cost is outside this diff.

**Recommendation:** None required.

## Endorsements

- Q-080 cuts the total frontmatter description length of the 25 skills from 37,064 to 10,004 characters (−73%; per-skill 951–2,969 → 364–426), measured by parsing `git show main:`/`HEAD:` frontmatter. This reduces per-session listing context wherever the listing is not already truncated. `[read: skills/*/SKILL.md frontmatter at main and HEAD, parsed by perf/desc.py]`
- `matches_deny` is linear in (extracted commands × deny globs). The shipped rule `*\.credentials\.json*` against a 1 MB adversarial `.`-filled command took 2.7 ms (10 KB: 0.6 ms), so long commands do not cause catastrophic glob backtracking with the wired rule. `[read: hooks/auto-approve-allowed-commands.sh:150-167; timed in scratch]` Rules with many `*` that users add themselves were not measured.
- The deny globs are loaded once per call and reused for both the raw-string check and the per-command check. They are not reloaded inside the per-command loop. `[read: hooks/auto-approve-allowed-commands.sh:262-266, 309-322]`
- Claim for the fact-check stage: the skill listing in this session drops the description entirely for several skills (cowen-critique, yglesias-critique, self-eval, design-space-situating, business-plan-critique-*) even though `/opt/claude-workflows/skills/*/SKILL.md` has one. That is consistent with a total listing-size budget, in which case Q-080's shorter descriptions would bring those entries back. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Deny loader adds ~3 `jq` + 6 `sed` + `sort` + `git` spawns per Bash call (~108 → ~193 ms median) | Low | `hooks/auto-approve-allowed-commands.sh:124-148, 262` | High |
| 2 | `report_stamp` drops the contract hash (one less hash; fewer forced regenerations) | Informational | `test/skills/runner-contract.bash:198-203` | High |

## Overall Assessment

The branch's only runtime-relevant regression is in the per-Bash-call hook. Loading deny rules by spawning a second set of per-file `jq`/`sed` pipelines nearly doubles hook latency, measured at roughly +85 ms per call here. That is a constant factor, not a scaling problem: N (files, rules, extracted commands) is tiny and the matching itself is negligible. It can be fixed in place by consolidating to one `jq` over all settings files, which would put the hook below its pre-branch cost. Q-078 is slightly cheaper at test time and much cheaper in regeneration churn. Q-080 cuts the per-session listing footprint by about three quarters. No profiling beyond the measurements above is needed. If the consolidation is done, re-run `perf/bench.sh` against the baselines in this report.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to /workspace/docs/reviews/performance-review-2026-09-27.md, structured per the performance-reviewer skill, with a Goal-Alignment Note.
- **Answered:** I measured the hook's added per-call cost (main vs HEAD, with a component breakdown and a prototype of the fix), checked that deny-glob matching is safe on large inputs, assessed the cost change in `report_stamp` hashing, and quantified the change in skill-description length.
- **Out of scope:** Correctness and bypass semantics of the deny matching (security critic); wording and routing quality of the descriptions (fact-check/API critics); pre-existing `_stamp_hash_path` per-file subprocess cost; Q-076.
- **Escalate:** None blocking. Finding 1 is a cheap follow-up the author can take or log.
- **Decisions I made:** I rated finding 1 Low, not Medium, because ~85 ms per call is small next to model-turn latency even though it is a +80% relative increase. I measured with the real settings files, whose global file has no Bash deny rule yet. That does not affect cost, because the spawns happen whether or not any rule matches.
