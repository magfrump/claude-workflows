Commit: 368a3194

# Architecture Review — feat/build-loop-u2b2 (iteration 2)

**Scope:** delta `c10b972a..368a3194` (fix commits 639f7b40, 368a3194) in `/workspace/.claude/wt-build-loop-u2b2`. Read whole: `checkout_gate` (`scripts/build-loop.sh:609-689`), `check_line` (`:690-753`), `callervar` and `gate_repo` (`:526-554`), the `--check` dispatch arm (`:765-777`), `harden` and the process exports (`:206-226`), the help text's checkout refusal (`:112-141`), the lib header `scripts/lib/dev-cycle-read.sh:1-90`, `need_root` and `floor`'s head (`:139-143`, `:1145-1150`), and the plan's U2b2/U2c bullets (`docs/working/plan-build-loop-handoff.md:284-286`). The tests (`test/scripts/build-loop-check.bats`) and `known-issues-dev-cycle.md` A5 were read as context.
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md` (k=1, 26 claims; 3 Incorrect about documented order, fixed in 368a3194). It leaves two residues. Claim 3: the blob-missing and lower-casing refusals return before the checkout refusal and replace it. Claim 23: the locale is now exported to child processes (`local -x`). This review uses Claims 3 and 23 and does not re-verify them.

## Scope check

In scope under two triggers.

- **Cross-cutting concern.** The checkout precondition moved from the composition root (the `--check` arm) into the per-brief decision (`check_line`). That changes when, and for whom, the gate caller contract is enforced.
- **Public API and contract.** The verdict line now has a third source, the checkout refusal, which is followed by path lines. The lib's gate caller contract also gets a rewritten ownership split.

## Dependency Map

The `--check` arm in the parent shell runs `read_settings`, `open_shared` and `gate_repo`, then calls `check_line` once per brief inside `$(...)`. It no longer calls `checkout_gate`.

Inside `check_line`, the call order is:

1. `import_reset` (contract item 4).
2. `status_line`, then `check_branch` and `merge_result`.
3. `gate_git diff-tree` and the record parse.
4. **New position:** `checkout_gate`, only when `pol == self-merge`. Its refusal text is stored in the local `co`.
5. The blob-presence batch, which can return.
6. `nul_list lower_all`, which can return.
7. The per-path loop with `nrules`. U2c's floor walk will join this loop.
8. The verdict line, where `co` wins over `nd`, which wins over `ok`. The rows follow it.

`checkout_gate` reads the checkout through the caller's git: `rev-parse`, `config`, `ls-files`, `status`, `hash-object` and `ls -A`. It reads main's tree through `ls-tree`, and `GATE_TMP` as scratch. It shares one predicate, `callervar`, with `gate_repo`. Every dependency still points from the script to the lib. None points back.

The lib header names `build-loop.sh`'s `harden`, state gate and `checkout_gate` in prose (`dev-cycle-read.sh:55-62`). That is a documentation edge, not a code edge. The deferred F7 already covers it.

**Trust-boundary cross-reference.** The skill scans for `docs/reviews/security-review-*.md`. This unit's security output is named `security-reviewer-review-2026-10-08-build-loop-u2b2.md` (Commit: `c10b972a`), so that glob does not match it. Its Trust Boundary Map is still the relevant one, so it is used read-only here.

Its `B5` reads: `[CHECKOUT_WHY (process global, set once)] → [check_line, pol == self-merge] → [refuse line / merge_result]`. The fix commits moved that crossing. The verdict is now computed per brief, inside `check_line`, after the diff parse. **The security review predates this diff, so `B5`'s placement there is stale.** Finding 1 touches `B5` but does not recommend moving it.

## Status of the iteration-1 findings

| # | Iteration-1 finding | Status at 368a3194 | Evidence |
|---|---|---|---|
| F1 | "final before the walk" had no owner | **Resolved.** The gate runs per self-merge brief, after `import_reset` and before the per-path loop. | `check_line`: `co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: ..."; fi`; the `--check` arm's `checkout_gate || true` is gone |
| F2 | The advisory run lost its path lines | **Resolved.** One residue is carried as new finding 1. | `if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; ...; printf '%s\n' "${rows[@]}"` |
| F3 | An empty `CHECKOUT_WHY` meant both "passed" and "never ran" | **Resolved.** The global is read on the same line as the call that set it, and the return code decides. | `! checkout_gate; then co="...; $CHECKOUT_WHY"` |
| F4 | The lib's item-3 note over-claimed | **Resolved.** The header now gives a three-way split: harden and the state gate, `checkout_gate`, and the walk. | `harden and its state gate own item 2's fsmonitor and replace refs; checkout_gate the rest of item 2 ...` |
| F5 | The trusted-`GIT_*` rule was written twice | **Resolved.** There is one `callervar`. `checkout_gate` adds a single extra exception, `GIT_PREFIX`, with its reason given. | `callervar() { [[ "$1" == GIT_CONFIG_PARAMETERS \|\| ... ]]; }` |
| F6 | A5 was stale | **Resolved.** | A5 now lists what U2b2 closes and what stays open. |
| F7 | `checkout_gate` sits apart from the lib | Deferred, as agreed. The revisit is at a second caller. | — |

## Findings

#### 1. With the refusal deferred to the verdict line, U2c's floor walk will run per path even when the checkout has just failed the contract that walk requires, and nothing tells U2c to skip it

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:730-735`, `:744-749`, `:609-616`; `scripts/lib/dev-cycle-read.sh:46-51` (item 2); `docs/working/plan-build-loop-handoff.md:286` (the U2c bullet)
**Move:** 7 (control coupling across units), 3 (contract at the module boundary)
**Confidence:** High on the structure. Medium on the consequence, because U2c is not written yet.
**Legibility-target:** the `check_line` comment "before U2c's floor walk, which runs per path below", and the U2c bullet

Evidence. The fix for F2 now lets the per-path loop run after a checkout refusal:

```
  # A self-merge brief's checkout (contract items 2 and 3), checked once the
  # merge's paths are read and before U2c's floor walk, which runs per path
  # below; its refusal replaces the verdict line only, so the path lines still
  # print (a loop's advisory run from its own branch learns them).
  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: ..."; fi
```

The walk's precondition, from the lib's contract:

> 2. Walk a clean worktree at MAIN_SHA, final before the walk ... under the git environment the override log names (GIT_INDEX_FILE, GIT_WORK_TREE, fsmonitor, sparse checkout, core.ignoreCase, replace refs).

The iteration-1 F2 recommendation kept the floor out of the advisory rows ("the S rules except the floor can print their path/deny lines"). The fix keeps the path lines but does not carry that exception forward. The comment says the floor "runs per path below", with no condition. The U2c bullet does not mention `co` at all.

The N rules are safe to run after a refusal because they read only main's tree and the merge's paths. The floor is different: it reads the checkout. Once U2c adds the floor to this loop as described, a loop's advisory run from its own branch will get `deny`/`path` rows computed by a walk over the very checkout the gate just rejected. Examples are a different HEAD, a `GIT_INDEX_FILE`, or a gitlink holding files.

Those rows can be wrong in either direction. For example, a branch-only `CLAUDE.md` import is read as the checkout state, not main's. The loop then acts on them as the advisory channel's answer, and the brief also pays a full walk for a verdict that is already "refuse". So the unit that owns the contract (U2b2) has arranged for its own refusal not to stop the consumer it guards. That breaks a contract invariant across a unit boundary, and the code does not record it.

`B5` from `docs/reviews/security-reviewer-review-2026-10-08-build-loop-u2b2.md` (Commit: `c10b972a`) is where this verdict crosses into `check_line`. That security review predates this diff, so the boundary may be stale. This finding keeps the crossing where it is.

**Recommendation:** State the rule now, where U2c will read it. Change the `check_line` comment to "U2c's floor runs per path below only when `co` is empty; after a checkout refusal the rows carry the N rules (and S rules that read no checkout) alone". Add the same clause to the U2c bullet. The alternative is that U2c's floor rows say they were not checked, for example `deny ... : the floor needs a clean checkout`. In that case, state that instead.

#### 2. Contract item 1's locale is now set inside `checkout_gate` alone, so the walk it guards will not inherit it

**Severity:** Minor
**Location:** `scripts/build-loop.sh:627-629`; the process-wide exports at `:224-226`; `scripts/lib/dev-cycle-read.sh:44-45` (item 1)
**Move:** 4 (implicit layering: process-wide environment versus per-function), 3
**Confidence:** Medium. The structure is High. Whether U2c's floor needs C is Medium, but item 1 states it.
**Legibility-target:** the lib header's ownership sentence (`dev-cycle-read.sh:55-62`), which names an owner for items 2 and 3 but not item 1

Evidence. Contract item 1:

> 1. Run as above, with main found by name, under LC_ALL=C (under a UTF-8 locale a non-UTF-8 name on main fails the walk).

This script's composition root sets process-wide execution conditions in one place:

```
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none
```

The locale fix instead lands in one function:

```
  local -x LC_ALL=C  # exported: tr, awk and git run under it too
```

There is no other `LC_ALL` in the script except three per-command `env LC_ALL=C` / `LC_ALL=C grep` uses. The new test even runs the whole script under `LC_ALL=C.utf8`. So the guard (`checkout_gate`) runs under C, but the guarded walk that U2c adds to the same loop will run under the caller's locale. That is exactly the case item 1 forbids.

The fix solved the security symptom (fact-check Claim 23) at function scope. The contract duty belongs to the caller as a whole, and the new ownership split in the lib header lists items 2 and 3 but leaves item 1 without an owner. U2c will have to rediscover this, as U2b2 did.

**Recommendation:** Either export `LC_ALL=C` with the other process-wide exports, if the scrub and the messages tolerate it (the scrub is already byte-pinned), or name item 1's owner in the lib header's split and in the U2c bullet ("U2c's floor call sets LC_ALL=C"). In both cases, keep the `checkout_gate` local as a belt.

#### 3. The verdict line's precedence is now spread across four early returns and a final if-chain, and the order is stated only in prose

**Severity:** Informational
**Location:** `scripts/build-loop.sh:735`, `:740-743`, `:744`, `:750`; help `:131-134`
**Move:** 8 (extension points)
**Confidence:** High (fact-check Claim 3)
**Legibility-target:** the help sentence "The merge's own refusals above (a conflict, a missing blob...) come first"

Evidence. The precedence is "merge integrity, then checkout, then N rules (later S rules), then ok". The code expresses it in two ways at once.

The blob and lower-casing refusals are evaluated *after* `checkout_gate` but `return` early, so they replace `co`:

```
    echo "refuse $a: the merge of $br names a blob the object store lacks"; return
```

The end of the function chooses among the rest:

```
  if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ..."; fi
```

The empty-path case has a third copy: `echo "${co:-ok $a $sha $tree}"`. U2c adds the S-rule and floor outcomes to the same chain. That will make three places to update and an order checked by no single statement.

This is the deferred "check_line returns text, not values (U3)" shape, not a new defect. **Recommendation:** none now. When U2c extends the chain, consider one `verdict` assembly at the end that both the empty-path and per-path exits call.

#### 4. `callervar` merges two questions, and `checkout_gate` patches the gap with an inline exception

**Severity:** Informational
**Location:** `scripts/build-loop.sh:526-531`, `:633-636`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** the `callervar` comment

Evidence:

```
callervar() { [[ "$1" == GIT_CONFIG_PARAMETERS || "$1" == GIT_CONFIG_COUNT || "$1" == GIT_NO_REPLACE_OBJECTS ]]; }
```

```
    [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" \
```

`gate_repo` asks one question: "which repo-local variables may follow git into the gate's own repository?" `checkout_gate` asks another: "which repo-local variables cannot change what the checkout reads?"

The two answers agree today, apart from `GIT_PREFIX`, which `gate_repo` unsets and `checkout_gate` tolerates. That is why the second caller needs its own exception. Sharing the predicate was the right call for F5, because the config-pair trust is a single policy. But if a future variable joins one answer and not the other, the shared name will invite a change that silently widens the other caller.

**Recommendation:** none now. If a second exception appears, split the predicate into `trusted_config_vars` (shared) plus each caller's own list.

## What Looks Good

- **The precondition now has the same lifetime as its consumer.** `import_reset` and `checkout_gate` both run per decision inside `check_line`, so items 2 and 4 share a lifetime. That is the iteration-1 F1 concern, closed by the simpler of its two recommended shapes.
- **Fail-closed state is restored.** The refusal is derived from the return code at the call, so "never ran" can no longer read as "passed" (F3).
- **The advisory channel keeps the concerns apart.** "Can this environment judge?" takes the verdict line, and "which rules does the branch break?" keeps its rows. The help text documents this: "this one replaces only the verdict line".
- **One predicate decides which caller variables are trusted** (`callervar`), shared by both readers (F5). `GIT_CONFIG` now leaves `gate_repo`'s environment too.
- **The ownership split is now correct and minimal.** The lib header names the owner of each duty in items 2 and 3, and it tells U2c which duties remain the walk's own.
- **Each failure mode has its own refusal reason** (status failed versus differs, tree unreadable versus name unreadable, hash failed versus mismatch). The function's error surface is easier to extend than one merged "or unreadable" message.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | U2c's floor walk will run per path after a checkout refusal; neither the comment nor the U2c bullet says to skip it | Coupling | `scripts/build-loop.sh:730-735`, plan `:286` | High (structure), Medium (consequence) |
| 2 | Item 1's `LC_ALL=C` is set only inside `checkout_gate`; the guarded walk will not inherit it, and the lib's ownership split names no owner for item 1 | Minor | `scripts/build-loop.sh:629`, `:224-226`; lib `:44-45`, `:55-62` | Medium |
| 3 | Verdict precedence spread over early returns plus an if-chain (three copies of the ok/co choice) | Informational | `scripts/build-loop.sh:735-750` | High |
| 4 | `callervar` serves two different questions; `GIT_PREFIX` is patched inline | Informational | `scripts/build-loop.sh:531`, `:635` | Medium |

## Overall Assessment

The fix commits improve the structure. All six actionable iteration-1 findings (F1-F6) are resolved in place, and F7 stays deferred as agreed. The checkout precondition now runs at the decision's granularity, the sentinel global no longer stands in for a result, and the contract's ownership split is accurate. Nothing here calls for restructuring.

The most important remaining concern is a forward coupling introduced by the F2 fix (finding 1). Path lines now print after a checkout refusal, and the code says U2c's floor walk "runs per path below" without a condition. The next unit would therefore run the walk on a checkout its own guard just rejected, and print the result as advisory rows. It is a one-sentence fix in the `check_line` comment and the U2c bullet, made now while the author of the rule is still in context. Finding 2 is the same kind of gap for item 1's locale. Neither is a defect in U2b2's own behaviour.

## Goal-Alignment Note

**User goal:** land build-loop handoff unit U2b2 through its review-fix loop.
**Alignment:** The delta serves the goal. It closes the iteration-1 architecture findings without widening the unit's scope, and adds no new module or cross-unit code edge. No finding blocks landing: there is no Structural finding, and the one Coupling finding is a comment or plan-bullet fix whose effect lands in U2c. Findings 1 and 2 are best fixed before the merge, because they tell the next unit (U2c, the floor's first caller) which of the contract's duties remain its own. That is the purpose this unit states ("so U2c's floor walk can rely on it").
