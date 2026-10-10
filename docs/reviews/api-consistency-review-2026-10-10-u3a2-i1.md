# API Consistency Review — feat/build-loop-u3a2 (U3a2, `--merge`), iteration 1

**Scope:** `git diff main...HEAD` at 7d78e6d0: `scripts/build-loop.sh`, `test/scripts/build-loop-merge.bats`
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3a2-i1.md (Stage 1 findings as summarized in the shared review context); plan docs/working/plan-build-loop-handoff.md (D4, D7, Script interface, step 7 U3a2 bullet) and rev 2 (`3a005378`) T22/T23

## Baseline Conventions

Surveyed in `scripts/build-loop.sh` (`--settings`, `--status`, `--check`), `scripts/dev-cycle.sh` (`--check-*` modes) and the plan's Script interface:

- **Modes** are `--word` flags taking positional brief paths; `--expect SHA` is a modifier usable once, with exactly one brief (`--check`). Bad usage: one stderr line, `WHY (usage: ...)`, exit 1, before any git call.
- **Output** is one line per decision, led by a lower-case verdict word, then `BRIEF`, then data fields: `ok BRIEF TIP TREE`, `refuse BRIEF: WHY`, `skip BRIEF: WHY`, then `path BRIEF S PATH` / `deny BRIEF S PATH: WHY` rows after an ok, a K-of-N refusal or a checkout refusal. Start-up state findings are bare `refuse state WHAT: WHY` lines and exit 2 before any brief.
- **WHY text** is a lower-case clause naming the condition, no git stderr; the checkout refusal has a fixed prefix up to `; ` that consumers may match.
- **Exit**: 0 every verdict ok; 2 any other verdict or the state gate; 1 bad usage/environment; any other code means nothing decided.
- **Git hygiene**: every git call hardened (no global/system config, no replace objects, optional locks off); writes limited to merge objects and the temp dir.
- **History conventions** for the new commit: the repo's merges are `Merge branch 'BRANCH': summary` (`git log --merges main`); the plan fixes the trailer as `Build-loop-gate: <stem>` (D7) and U3b's `--main-log` classifies `gate` as "a commit-tree merge with the trailer".

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--merge` | CLI mode flag | `--check`, `--status`, `--settings`; dev-cycle.sh `--check-brief` | `scripts/build-loop.sh:6-10`, `scripts/dev-cycle.sh:11,112` | Consistent: bare verb mode, matches plan Script interface |
| `--merge BRIEF --expect SHA` | CLI signature | `--check BRIEF... [--expect SHA]` | `scripts/build-loop.sh:8,270-283` | Consistent: same parser, `--expect` required here; `[--approved Q-NNN]` (plan) deferred |
| `merged BRIEF NEW TIP TREE` | output verdict line | `ok BRIEF TIP TREE`, `refuse BRIEF: WHY`, `skip BRIEF: WHY` | `scripts/build-loop.sh` header `--check` section | New verdict word (no write-success precedent); field order shifts TIP/TREE right by one — see F4, F7 |
| `refuse BRIEF: WHY` (land refusals) | output line | `refuse BRIEF: WHY` from check_line | `scripts/build-loop.sh:916-990` | Consistent shape; path lines now follow a fourth refusal kind — see F5 |
| `Build-loop-gate: STEM` | commit trailer | plan D7 `Build-loop-gate: <stem>`; U3b `--main-log` reader | `docs/working/plan-build-loop-handoff.md:84,102` | Consistent with the plan; parses with `git interpret-trailers --parse` and `%(trailers:key=Build-loop-gate,valueonly)` (probed) |
| `Merge branch 'BRANCH' (build-loop self-merge)` | commit subject | `Merge branch 'feat/build-loop-u3a1': ...` | `git log --merges main` | Consistent: git's default merge subject plus a parenthetical tag |
| `build-loop: self-merge of STEM` | reflog message | git's own `merge NEW: Fast-forward` | (no reflog message elsewhere in `scripts/`) | Only on the CAS path — see F3 |
| `VERDICT`, `CHANGED`, `NEW`, `MERGE_WHY`, `land`, `merge_ident`, `verdict_ok`, `CALLER_GLOBAL` | script-internal globals/functions | `STATUS`, `DENY`, `PATHS_WHY`, `CHECKOUT_WHY`, `gate_start`, `check_line` | `scripts/build-loop.sh:913-916` | Consistent: UPPER globals with `*_WHY` reason fields, lower-case verb functions; not consumer-facing |

## Findings

#### F1. Identity refusal is host-dependent: the "none known refuses" contract holds only on hosts where git's guess is bogus

**Severity:** Minor
**Location:** `scripts/build-loop.sh:990-1000` (merge_ident); header lines 216-218
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
#                 (the environment, then git config, the caller's global
#                 file included); none known refuses. With the branch checked
...
# commit-tree in the gate repository, which has no config. Returns 1 when git
# knows none (it never guesses one from the host name).
merge_ident() {
  local w x
  for w in AUTHOR COMMITTER; do
    x="$(env "${CALLER_GLOBAL[@]}" git var "GIT_${w}_IDENT" 2>/dev/null)" || return 1
```

Fact-check claim 2b (Incorrect): `git var` with no identity guesses from the gecos name and `/etc/mailname` or the FQDN, and refuses only when the guess is bogus (this container: `node@c965a4a7cd4f.(none)`). On a host with a domain, `--merge` would print `merged` under a guessed identity instead of the documented refusal, so the refusal is a property of the host, not of the contract; test 3's no-identity step passes here for the same reason. Probed: `git -c user.useConfigOnly=true var GIT_AUTHOR_IDENT` refuses with "no email was given and auto-detection is disabled" whatever the host (also when only `$EMAIL` is set), and still accepts `GIT_AUTHOR_NAME`/`GIT_AUTHOR_EMAIL` from the environment.

**Recommendation:** Run the `git var` call with `-c user.useConfigOnly=true` so the refusal is deterministic and the comment ("it never guesses") becomes true; keep the refusal text as is.

#### F2. `--merge` with no brief says "needs at least one brief path" — contradicts its one-brief signature

**Severity:** Minor
**Location:** `scripts/build-loop.sh:281-283`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
    [[ ${#ARGS[@]} -gt 0 ]] || usage "--$MODE needs at least one brief path"
    [[ -z "$EXPECT" || ${#ARGS[@]} -eq 1 ]] || usage "--expect goes with exactly one brief path"
    [[ "$MODE" == check || -n "$EXPECT" ]] || usage "--merge takes one brief path and --expect SHA" ;;
```

Probed: `build-loop.sh --merge` prints `--merge needs at least one brief path (usage: ... --merge BRIEF --expect SHA)`. The `--check` wording is generalized by `$MODE`, but `--merge` takes exactly one brief, and the third check already has the right message. Three different first-error texts are reachable for `--merge` depending on which piece is missing (none, two briefs with `--expect`, one brief without), where one message would do.

**Recommendation:** Put the `--merge` check (`one brief path and --expect SHA`, testing `${#ARGS[@]} -eq 1 && -n "$EXPECT"`) before the generic ones, so every malformed `--merge` gives the same message.

#### F3. Two reflog messages for one operation, depending on whether main is checked out

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1068-1073`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
    git update-ref -m "build-loop: self-merge of ${VERDICT[stem]}" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" 2>/dev/null \
...
    git -C "$w" -c gc.auto=0 merge --ff-only -q "$NEW" > "$GATE_TMP/ff" 2>&1 || { MERGE_WHY="the fast-forward in $in failed"; return 1; }
```

The CAS path writes `build-loop: self-merge of STEM` to main's reflog; the worktree path writes git's default `merge <40-hex>: Fast-forward`, which names neither the gate nor the brief. Probed: with `GIT_REFLOG_ACTION="build-loop: self-merge of x"` the fast-forward writes `build-loop: self-merge of x: Fast-forward` to both `main@{0}` and `HEAD@{0}`. Anyone auditing main's reflog (the trailer is the primary record, so this is secondary) sees the two paths differently. The reflog message is also not in the header's description of what `--merge` writes.

**Recommendation:** Set `GIT_REFLOG_ACTION="build-loop: self-merge of ${VERDICT[stem]}"` on the `merge --ff-only` call, and name the reflog message once in the header.

#### F4. Path lines follow a fourth kind of refusal under `--merge`; the header's rule lists three

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1101-1106`; header lines 211-235 and the `--check` "After an ok line..." paragraph
**Move:** 3 (consumer contract / documentation drift)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    # land's result replaces only the verdict line; the path lines follow.
    if [[ -z "${VERDICT[tree]-}" ]]; then cat "$GATE_TMP/line"; exit 2; fi
    if land; then v="merged $a $NEW ${VERDICT[tip]} ${VERDICT[tree]}"; else v="refuse $a: $MERGE_WHY"; fi
    { echo "$v"; tail -n +2 "$GATE_TMP/line"; }
```
and in the header:
```
#             After an ok line, a K of N refusal or a checkout refusal, one line per path TREE
```

A land refusal (`refuse BRIEF: the brief's policy is review; ...`, `... the default branch moved after the check ...`, etc.) is followed by path lines, which the `--check` rule does not list. The `--merge` header says an ok line "becomes merged ... or refuse BRIEF: WHY", which implies it, but a consumer coded to the explicit rule would treat the path rows as unexpected. D4 quotes the refusal into a review entry, so U3b's reader is the one affected.

**Recommendation:** Add one clause to the `--merge` header: "path lines follow a merged line or a refusal of land's, as they follow ok".

#### F5. `merged` line shifts TIP and TREE one field right relative to `ok`

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1103`; header lines 211-213
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    if land; then v="merged $a $NEW ${VERDICT[tip]} ${VERDICT[tree]}"; else v="refuse $a: $MERGE_WHY"; fi
```

`ok BRIEF TIP TREE` has TIP at field 3; `merged BRIEF NEW TIP TREE` has NEW there and TIP at field 4. Both are documented and the verdict word disambiguates, so nothing breaks, but a reader sharing one field-split for `ok` and `merged` (the D4 collect step reads both modes' first lines) gets NEW where it expects TIP. The plan's Script interface does not specify the line, and U3b has not yet consumed it, so the order is still free.

**Recommendation:** Either keep the order and record `merged BRIEF NEW TIP TREE` in the plan's Script interface, or use `merged BRIEF TIP TREE NEW` so that `ok` and `merged` share their first four fields. Decide before U3b writes the reader.

#### F6. `merged` is the first write-success verdict word

**Severity:** Informational (downgraded from Minor: no precedent)
**Location:** `scripts/build-loop.sh:1103`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

No existing precedent in the verdict words printed by `scripts/build-loop.sh`, `scripts/dev-cycle.sh` and `scripts/questions.sh` (grep of `echo "<word> `: only `ok`, `refuse`, `skip`; `path`/`deny` as rows)

**Evidence:**
```
    [[ "$v" == merged* ]] || exit 2
```

Every earlier verdict word judges (`ok`, `refuse`, `skip`). `merged` reports an action taken, which is a useful distinction (a consumer never mistakes a check's `ok` for a landing), and it reads naturally beside the planned `dispatched N` (`--start`/`--prompt`, plan Script interface). This sets the convention for later writing modes: past-tense verb for "done".

**Recommendation:** None required; mention the convention in the plan's Script interface when F5 is recorded, so `--start`'s output follows it.

#### F7. `--merge` output names `--check` in the checkout refusal, and the review-policy refusal will go stale with `--approved`

**Severity:** Informational
**Location:** header lines 168-172 (checkout refusal text, unchanged by this diff); `scripts/build-loop.sh:1021`
**Move:** 3 (documentation drift)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
  [[ "${VERDICT[policy]}" == self-merge ]] || { MERGE_WHY="the brief's policy is review; --merge lands only a self-merge brief"; return 1; }
```

Under `--merge`, check_line's checkout refusal still reads "a self-merge brief needs --check run from a clean checkout of the default branch's commit; ...". The header declares that prefix fixed, so changing it would break a consumer; it only reads oddly. The plan's interface is `--merge BRIEF --expect SHA [--approved Q-NNN]` (Script interface), and with `--approved` a review brief lands, so "--merge lands only a self-merge brief" becomes false at that unit.

**Recommendation:** Leave both texts; note in the header that the checkout refusal's wording is shared with `--merge`, and carry a note into the `--approved` unit to reword the policy refusal ("without --approved").

## What Looks Good

- `--merge` reuses `--check`'s parser, `--expect` validation (full 40/64-hex) and usage-line format; the usage string and `-h` header both list the new form, matching the plan's Script interface minus the deferred `--approved`.
- Output keeps the grammar: verdict line first, `refuse BRIEF: WHY` for every land refusal, check_line's own refusals and skips printed unchanged, path rows after, `refuse state` findings at start-up as for `--check`. Exit codes follow the same 0/2/1 split, documented in the header.
- Land refusals are lower-case clauses naming the condition, without git stderr or worktree paths (the worktree is "the worktree with the default branch checked out", not its path), the same style as check_line.
- The commit message and trailer match plan D7 exactly and parse as a git trailer (`interpret-trailers --parse` and `%(trailers:key=Build-loop-gate,valueonly)` both return the stem, probed), which is what U3b's `--main-log` `gate` classification needs. Parents (MAIN, TIP) and tree match D7, verified by test 1.
- T22 (CAS, parents, shim race G17, repeat merge G13) and T23 (ff in W, W dirty, W on another branch, rebase/bisect of main in any worktree) from rev 2 are both covered, plus the F50 untracked/ignored collision and the row 494 state-gate re-run.
- A re-run of the state gate before the move is reported as a per-brief refusal with the first state line quoted, rather than a second bare `refuse state` block, which keeps "bare state lines come before any brief" true.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Identity refusal host-dependent; use `user.useConfigOnly=true` | Minor | `scripts/build-loop.sh:990-1000` | High |
| F2 | `--merge` with no brief: "needs at least one brief path" | Minor | `scripts/build-loop.sh:281-283` | High |
| F3 | CAS and ff paths write different reflog messages | Minor | `scripts/build-loop.sh:1068-1073` | High |
| F4 | Path lines follow land refusals; header rule lists three cases | Minor | `scripts/build-loop.sh:1101-1106`, header | High |
| F5 | `merged` shifts TIP/TREE vs `ok`; record or reorder before U3b | Informational | `scripts/build-loop.sh:1103` | Medium |
| F6 | `merged` sets the first write-success verdict word | Informational | `scripts/build-loop.sh:1103` | Medium |
| F7 | `--check` named in `--merge` output; policy refusal stale at `--approved` | Informational | header 168-172, `scripts/build-loop.sh:1021` | Medium |

## Overall Assessment

The `--merge` surface is consistent with `--check` and the plan: same parser, verdict-first grammar, `refuse BRIEF: WHY` style, exit codes, and the D7 commit message and trailer that U3b will read. Nothing breaks an existing consumer (`--check`, `--status`, `--settings` are unchanged in output; check_line's added values are internal). The four Minor findings are small fixes in place: make the identity refusal deterministic (F1, the only one with a behavioural consequence, a merge under a guessed identity on some hosts), unify the `--merge` usage error (F2), give the fast-forward the same reflog message (F3), and state in the header that path lines follow a land refusal (F4). F5 is worth deciding now, while `merged`'s only reader is still unwritten.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/api-consistency-review-2026-10-10-u3a2-i1.md, structured per the api-consistency-reviewer skill.
- Answered: API-consistency review of the U3a2 public surface (CLI flags, usage and errors, exit codes, output line grammar, commit message and trailer, reflog message) against `--check`/`--status`/`--settings`, dev-cycle.sh conventions, plan D4/D7, step 7's U3a2 bullet and rev 2's T22/T23; behaviours cited in F1-F3 were probed in /tmp/u3a2-api-* directories (removed).
- Out of scope: security of the race residuals (Q-103; rows 509, 646), store_check cost (row 639), performance; the fact-check's other doc-accuracy items (2a, 3, 4, 5, 13) except where they touch the contract (F1). Bats suites were not run.
- Escalate: none. F5 (field order of `merged`) is a small design choice the author can make; nothing needs the user.
