Commit: 5516c6e6

# API Consistency Review: feat/build-loop-u2b3a (U2b3a, reader roots and homes)

**Scope:** branch diff `git diff main...HEAD` (e50aab35..5516c6e6): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`. The surface is the lib's internal API, shared by `scripts/dev-cycle.sh` (--check-fix) and `scripts/build-loop.sh`.
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 5516c6e6; 27 claims, 0 Incorrect, 1 Stale, 3 Mostly accurate, 1 Unverifiable), shared brief `u2b3a-i1/shared.md`, override rows 425, 431, 432, 437, 477.
**Review pass:** iteration 1 (--loop-pass). Probe: `bats test/scripts/dev-cycle.bats` on HEAD, 78/78 ok, exit 0 (log: scratchpad `u2b3a-api-devcycle.txt`). The fact-check reports `build-loop-check.bats` at 112/112 on HEAD.

## Baseline Conventions

These are the lib's conventions as they stood on main and in the code this diff leaves alone:

- **Function names.** Helpers for one subsystem share a prefix. The import subsystem uses `import_reset`, `import_home`, `import_targets` and `import_work` (`scripts/lib/dev-cycle-read.sh:610`, `:821`, `:880`, `:912`). Predicates use `is*` (`isstart`, `isimported`, `isbrief`, `isclosed`). Readers and checks use `check_*` and `main_*`.
- **Cache keys.** A memoized global result goes with a `*_DONE` global that holds the inputs it was computed for: `IMPORTED_DONE`, `IMPORTED_MAIN_DONE` (`:608`) and `IMPORT_HOME_DONE` (`:820`, "holds a key for the HOME it was computed for"). `import_reset` clears the walk keys (`:610`).
- **Caller knobs.** These are upper-case `IMPORT_*` shell variables. Either the lib gives them a default (`IMPORT_OUT_MAX=4000000`, `IMPORT_WORK_MAX=50000000`, `:616`, `:628`) or the lib reads them with `${VAR:-default}` (`IMPORT_LEFT`, `IMPORT_WORK_LEFT`, `:905`). Their meaning is stated in the comment of the function that reads them and, when a gate caller must act on them, in the numbered gate caller contract (`:43-91`).
- **Errors.** Every walk input that fails returns 1 with no message. The walk then reads as `error`, which `isimported` treats as fail-closed (contract item 6). Own-HOME defects fail lazily: "A relative home is kept, and the parser fails on a ~/ name then" (`:819`). The walk fails only when a `~/` name actually needs that home.
- **Parser env.** The shell passes values to awk as `IT_*` environment variables, never `-v`, because "awk -v would read backslash escapes" (`:901-902`). Lists are newline-separated, with an `x` prefix where an empty entry must survive `split` (`IT_XDIRS`, `:789-790`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `reader_set` | function | `import_home`, `import_targets`, `import_reset` | `scripts/lib/dev-cycle-read.sh:610,821,880` | Inconsistent (Minor): it is the import subsystem's input builder, the direct analogue of `import_home`, but it drops the `import_` prefix (F2) |
| `IMPORT_READERS_FOR` | global (cache key) | `IMPORT_HOME_DONE`, `IMPORTED_DONE`, `IMPORTED_MAIN_DONE` | `scripts/lib/dev-cycle-read.sh:608,820` | Inconsistent (Minor): the same role as the `*_DONE` keys under a new `_FOR` suffix (F1) |
| `IMPORT_ROOTS`, `IMPORT_HOMES` | global (computed output) | `IMPORT_HOME`, `IMPORT_HOME_REAL` | `scripts/lib/dev-cycle-read.sh:820` | Consistent: `IMPORT_` plus a plural noun, set by the subsystem's builder |
| `IMPORT_READER_ROOTS`, `IMPORT_READER_HOMES` | caller knob | `IMPORT_OUT_MAX`, `IMPORT_WORK_MAX`, `IMPORT_LEFT` | `scripts/lib/dev-cycle-read.sh:616,628,905` | Consistent prefix. They are read with `${VAR:-}` (`:858`, `:860`), which follows `IMPORT_LEFT`'s precedent. The lib does not declare them, so they are not documented in the contract (F6). The spelling sits close to the output names `IMPORT_ROOTS`/`IMPORT_HOMES`, but the `READER` infix separates input from output well enough |
| `IT_ROOTS`, `IT_HOMES` | parser env | `IT_XDIRS`, `IT_DIR`, `IT_ROOT` | `scripts/lib/dev-cycle-read.sh:789-791` | Consistent: newline-separated like `IT_XDIRS`. No `x` prefix is needed, because empty roots are refused and the parser skips an empty home (`:707`). `IT_ROOT` stays only for its exit-2 check (F8) |
| `rs_*` locals | locals | `iw_t`, `iw_w` (import_work's prefixed locals) | `scripts/lib/dev-cycle-read.sh:915` | Consistent: a function-initials prefix on locals |

## Findings

#### F3. An own HOME holding a newline now fails every walk, against the lib's lazy own-home rule and reader_set's own comment

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:867-876` (comment `:842-845`; import_home convention `:819`)
**Move:** 4 (error consistency), 3 (consumer contract)
**Confidence:** High (the behaviour was executed by the fact-check, Claim 18 P2)
**Legibility-target:** for-author

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:869-873
    if [[ $i -ge 2 ]]; then
      [[ -n "$p" ]] || continue
      [[ "$p" == /* && -n "${p//\//}" ]] || return 1
    fi
    [[ "$p" != *$'\n'* ]] || return 1
```
(excerpt ends :873; enclosing reader_set() continues to :879, read)
```bash
# :842-845
# It returns 1 when import_home or the listing fails, or a root or
# home (but this process's own home, which the parser already refuses to join
# when it is relative) is not absolute, holds a newline, or is / alone
```
```bash
# :819 (import_home)
# computed for: whether it was set, and its value). A relative home is kept, and the parser fails on a ~/ name then.
```

The lib's rule for this process's own home is lazy: a home the parser cannot use fails a walk only when a `~/` name needs it (`:819`, and the parser's `exit 4` at `:706`). The comment at `:843` extends that exemption to the own home. The newline check at `:873` sits outside the `i -ge 2` block, so it runs on the own-home entries too. On main, a HOME with a newline let both walks succeed, because `put` dropped any resolved name holding a newline. On this branch, every walk fails, even in a repo with no `~/` names. Both consumers see that as fail-closed: `floor` refuses every path and `--check-fix` refuses every doc. That is safe, but it changes the error semantics existing callers had, and the comment describes the opposite.

**Recommendation:** Pick one rule and state it. Either move the newline check inside the `i -ge 2` block, so the own home keeps main's lazy behaviour (the parser already drops newline names), or keep the eager refusal and edit `:842-845` to exempt the own home from "not absolute" and "/ alone" only.

#### F4. Roots and homes apply the "/ alone" refusal differently

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:864` vs `:871`, comment `:842-845`
**Move:** 7 (asymmetry)
**Confidence:** High (executed by the fact-check, Claim 18 P3: `IMPORT_READER_HOMES=/x/..` ok, `IMPORT_READER_ROOTS=/x/..` failed)
**Legibility-target:** for-author

Evidence:
```bash
# :863-864 (roots)
    [[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1
    r="$(realpath -m -- "$p")" && [[ -n "${r//\//}" ]] || return 1
# :871, :874 (caller homes)
      [[ "$p" == /* && -n "${p//\//}" ]] || return 1
    r="$p"; [[ $i -lt 2 ]] || r="$(realpath -m -- "$p")" || return 1
```

The two knobs are documented together as "newline-separated absolute paths" with one refusal list (`:835-837`, `:842-845`), and they are validated differently. A root is checked again after realpath. A caller home is checked on its spelling only, so `/x/..` passes and becomes `/` in IMPORT_HOMES. The comment's reason for the rule ("every path would project into the repo") is a roots reason. For a home, `/` only widens `~/x` to `/x`, and that name still has to fall under a root. The risk to callers is small. The cost is that a caller reading one rule for both knobs is wrong about one of them.

**Recommendation:** Either recheck `r` for caller homes the way `:864` does for roots, or say in the comment that "/ alone" is a roots-only rule (fact-check Claim 18's precise version).

#### F6. The new caller inputs are not in the lib's header contract, and two parser comments still describe the one-root model

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:34-42` (Inputs paragraph), `:43-91` (contract), `:63-66` (item 4), `:667-668`, `:702-704`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```bash
# :63-66 (contract item 4)
#  4. Call import_reset before each gate decision and after any checkout
#     change (rows 372, 439), or when IMPORT_OUT_MAX or IMPORT_WORK_MAX
#     changes: neither walk's cache key holds them (both hold reader_set's
#     roots and homes, so HOME and IMPORT_READER_* need no reset).
# :667-668
# made absolute (ROOT_REAL/DIR/name for $1 and each further directory, unless
# it starts with /) and resolved
# :703-704
#   # for each reader home (the home of this process first), each also spelled through its
#   # real path, since the roots are real too.
```

The header calls the gate caller contract "the one statement of it" (`:43-44`). Item 4 is the only place the contract mentions `IMPORT_READER_*`, and it mentions them only to say they need no reset. What the variables are, their format (newline-separated absolute paths, blank lines skipped), and that a gate caller must set them for the host spelling (Q-121, Q-123) are stated only in reader_set's comment (`:835-837`). The header's "Inputs:" paragraph (`:34-42`) also leaves out that the walks now run `git worktree list` and read the worktree registry. Separately, the fact-check rates `:667-668` Stale (Claim 5: the parser joins every root, `:713`) and `:704` Mostly accurate (Claim 9: roots hold spelled forms too).

**Recommendation:** Add a contract line, or a clause on item 1, naming `IMPORT_READER_ROOTS`/`IMPORT_READER_HOMES` as the gate caller's reader inputs and pointing to reader_set for their format. U2b3b's settings line is the caller that will set them. Add the worktree registry to the Inputs paragraph, and apply the fact-check's wording for Claims 5 and 9.

#### F2. `reader_set` drops the import subsystem's `import_` prefix

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:852`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `import_<noun>` for the import walks' helpers, used in `scripts/lib/dev-cycle-read.sh:610` (`import_reset`), `:821` (`import_home`), `:880` (`import_targets`), `:912` (`import_work`)

`reader_set` does exactly what `import_home` does for one more input: it computes `IMPORT_*` globals that the parser reads, and its validity key is read by `import_targets`. Its outputs (`IMPORT_ROOTS`, `IMPORT_HOMES`) and its caller knobs (`IMPORT_READER_*`) all carry the `IMPORT_` prefix, but the function does not. That also hides it from anyone grepping `import_` for the subsystem's entry points. "set" can read as a verb (a setter), which adds to the ambiguity. The name does match the plan's term ("the reader set"), which is why this is Minor and not Inconsistent.

**Recommendation:** Rename it `import_readers`, matching `import_home`, or leave it and note the plan term in the comment. There are two call sites (`:1000`, `:1050`) and one comment reference per walk header.

#### F1. `IMPORT_READERS_FOR` is a cache-validity key named off the `*_DONE` pattern

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:851`, `:854`, `:878`, `:884`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `*_DONE` holds the inputs a cached global was computed for, used in `scripts/lib/dev-cycle-read.sh:608` (`IMPORTED_DONE`, `IMPORTED_MAIN_DONE`) and `:820` (`IMPORT_HOME_DONE`)

Evidence:
```bash
# :878
  IMPORT_READERS_FOR="$ROOT_REAL"$'\n'"$IMPORT_HOME_DONE"
# :884
  [[ "$IMPORT_READERS_FOR" != "${ROOT_REAL:-}"$'\n'"$IMPORT_HOME_DONE" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
```

`IMPORT_READERS_FOR` does what `IMPORT_HOME_DONE` does. It records the inputs the computed globals belong to, and a reader compares it against the current inputs before trusting them. `IMPORT_HOME_DONE` is even folded into its value. The one difference is that reader_set never skips work because of it (it always recomputes), so `_DONE` is not a perfect fit either. A reader who knows the lib looks for `IMPORT_READERS_DONE` and will not find it with a `_DONE` grep.

**Recommendation:** Rename it `IMPORT_READERS_DONE`, or keep `_FOR` and add half a sentence saying why it is not a `_DONE` key (it gates reuse by import_targets, not recomputation by reader_set).

#### F5. A standalone `import_targets` now depends on hidden state from an earlier walk, and that state is not keyed on the caller's lists

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:881-884`, comment `:641-643`, `:845-847`
**Move:** 3 (consumer contract)
**Confidence:** High (fact-check Claim 4, probe P4: after a walk with `IMPORT_READER_ROOTS=/host/cw`, changing it to `/other` with no walk left `/host/cw` in force)
**Legibility-target:** for-orchestrator-synthesis

Evidence: see `:884` under F1. On main, `import_targets`' output depended only on ROOT_REAL, HOME and the budget variables. Now it also depends on whether reader_set ran earlier in the same shell, and the guard compares ROOT_REAL and HOME only. A direct caller that changes `IMPORT_READER_ROOTS` or `IMPORT_READER_HOMES` between a walk and an `import_targets` call gets the old lists. No in-tree caller does this: the walks call reader_set first, and the direct callers are tests that run before any walk (`test/scripts/build-loop-check.bats:415`, `:468`, `:628`, `:695`, `:1184`). The comment states the ROOT_REAL/HOME condition accurately.

**Recommendation:** Fold the two caller lists into `IMPORT_READERS_FOR` (for example `"$ROOT_REAL"$'\n'"$IMPORT_HOME_DONE"$'\n'"x${IMPORT_READER_ROOTS-}"...`), which costs nothing, or add "or IMPORT_READER_* changed since" to the comment at `:845-847`.

#### F7. The lib-surface sourcing test does not list the new function or globals

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:1108-1114`
**Move:** 3 (test drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```bash
# test/scripts/dev-cycle.bats:1110, 1114
                 isclosed entry_why isimported inrepo_here main_imports nul_list import_targets instruction_names untracked_md tree_starts md_ls checkout_md main_checkout lower_all capped_read import_work; do
        for v in SKIPPED SKIP_AT MAIN MAIN_SHA MAIN_BY_NAME IMPORTED IMPORTED_DONE IMPORTED_MAIN IMPORTED_MAIN_DONE BRIEF BRIEF_ODD; do declare -p "$v" >/dev/null 2>&1 || echo "unset $v"; done
```

This test pins the lib's sourced surface. It does not list `reader_set`, `IMPORT_ROOTS`, `IMPORT_HOMES` or `IMPORT_READERS_FOR`. Under `set -u`, the walks read the last three before their first assignment, and `:884` reads `IMPORT_READERS_FOR` bare. The list was already partial (`import_home`, `import_reset` and `IMPORT_HOME*` are missing too), so this is long-standing drift, not a new break. The suite passes on HEAD (78/78).

**Recommendation:** Add `reader_set` (and `import_home`/`import_reset`) to the function list, and add `IMPORT_ROOTS IMPORT_HOMES IMPORT_READERS_FOR` to the declared-globals list, so a later edit that drops `:851` fails here and not under `set -u` in a caller.

#### F8. `IT_ROOT` survives beside `IT_ROOTS` only for its empty check

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:791-793`, `:904`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```awk
  dirs[0] = ENVIRON["IT_DIR"]; root = ENVIRON["IT_ROOT"]; if (root == "") exit 2
  # IT_ROOTS and IT_HOMES: newline-separated, ROOT_REAL and the home of this process first (reader_set).
  nr = split(ENVIRON["IT_ROOTS"], roots, "\n"); for (i = 1; i <= nr; i++) pre[i] = (roots[i] == "/") ? "/" : roots[i] "/"
```

The diff replaced `IT_HOME`/`IT_HOME_REAL` with `IT_HOMES`, but it kept `IT_ROOT` next to `IT_ROOTS`, whose first entry is the same value (fact-check Claim 10). `root` is no longer read after `BEGIN`. Nothing outside the lib sets `IT_*` (`rg IT_HOME|IT_ROOT` outside the lib finds nothing), so this is tidiness only. A future editor may still wonder which of the two is authoritative.

**Recommendation:** Test `roots[1] == ""` (or `nr == 0`) and drop `IT_ROOT`, or add a comment saying `IT_ROOT` exists only for the exit-2 rule.

#### F9. A nested worktree's paths now project to that worktree's names, so answers depend on the registry

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:731-735`
**Move:** 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```awk
  k = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i]) && length(pre[i]) > k) k = length(pre[i])
  if (!k) return
  out = substr(out, k + 1)
```
(excerpt ends :735; enclosing put() continues to :740, read)

On main, `@.claude/wt-b/docs/n.md` read from the main checkout gave `isimported tree .claude/wt-b/docs/n.md` = imported. On this branch, when `.claude/wt-b` is a registered worktree, the name projects to `docs/n.md`, and the `.claude/...` spelling reads as not imported. So isimported's answer for a path now depends on `git worktree list`, which is outside the commit and the checkout. Neither consumer is exposed: `floor` and `--check-fix` both go through `truthrule`, which refuses every dot path (`:1171`) before it asks the walk. The comment states the design (`:838-841`), and the commit records the alternative it rejected (37x output). This is noted so that a future consumer that asks isimported about non-dot paths under a registered nested worktree knows about it.

**Recommendation:** None for this unit. If U2b3b or U2c adds a caller outside truthrule, have it document whether that caller relies on the dot rule.

## What Looks Good

- **No consumer of the old interface breaks.** `IT_HOME` and `IT_HOME_REAL` had no users outside the lib. `IMPORTED_DONE` and `IMPORTED_MAIN_DONE` are compared only inside the lib. Tests that clear them with `=""` (`build-loop-check.bats:445`, `:650`, `:923`, `:927`, `:354`) and `import_reset` (`:610`, `build-loop.sh:704`) still work, because clearing a key still forces a walk. The relative-HOME `exit 4` test (`:693-696`) and the HOME tests at `:668`, `:687`, `:741-744` pass. Both suites pass: dev-cycle.bats 78/78 (this review) and build-loop-check.bats 112/112 (the fact-check).
- **Contract item 4 gets narrower, not looser.** HOME and the new knobs moved into both cache keys (override row 437), so a caller has fewer reset duties. The budgets, which are still outside the keys, are still named.
- **reader_set failures follow the walks' error convention.** They return 1 silently and set `IMPORTED=error` with an empty key, so the next call re-checks inputs that may have changed. Its refusals (relative, newline, `/`) fail closed, and the tests check that by asserting `docs/other.md imported` on every failed walk.
- **The new caller knobs follow `IMPORT_LEFT`'s pattern:** an `IMPORT_` prefix, `${VAR:-}` reads that are safe under `set -u`, and newline-separated lists like `IT_XDIRS`.
- **The parser env keeps the `IT_*`-through-environment rule** (`:901-902`) for the new lists, so a backslash in a host path is not unescaped.
- **The six tests drive both walks (`for w in tree main`) through the same `imps`/`want` helpers as the rest of the file.** Test 6 runs in one shell with no import_reset, which is exactly the contract change.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F3 | Own HOME with a newline fails every walk, against the lazy own-home rule and the comment's exemption | Minor | `scripts/lib/dev-cycle-read.sh:873` | High |
| F4 | "/ alone" rechecked after realpath for roots, spelling only for homes | Minor | `scripts/lib/dev-cycle-read.sh:864,871` | High |
| F6 | Caller inputs missing from the header contract and Inputs paragraph; two comments still describe one root | Minor | `scripts/lib/dev-cycle-read.sh:34-91,667,704` | High |
| F2 | `reader_set` drops the `import_` prefix | Minor | `scripts/lib/dev-cycle-read.sh:852` | Medium |
| F1 | `IMPORT_READERS_FOR` breaks the `*_DONE` key naming | Minor | `scripts/lib/dev-cycle-read.sh:851,878,884` | Medium |
| F5 | Standalone import_targets reuses stale lists after IMPORT_READER_* change | Informational | `scripts/lib/dev-cycle-read.sh:884` | High |
| F7 | Sourcing test does not list reader_set or the new globals | Informational | `test/scripts/dev-cycle.bats:1110,1114` | High |
| F8 | `IT_ROOT` redundant beside `IT_ROOTS` | Informational | `scripts/lib/dev-cycle-read.sh:791` | High |
| F9 | Nested-worktree projection makes isimported's answers depend on the registry | Informational | `scripts/lib/dev-cycle-read.sh:731-735` | Medium |

## Overall Assessment

The change fits the lib's conventions. It keeps the `IMPORT_*` caller knobs, newline-separated `IT_*` env lists, silent fail-closed returns and cache keys that hold their inputs, and no caller or test of the old interface breaks: both suites are green, and the removed `IT_HOME`/`IT_HOME_REAL` had no outside users. There are no Breaking or Inconsistent findings. Two Minor findings are error-semantics asymmetries in reader_set's validation (F3, F4). Each can be fixed in place by a one-line code move or a comment edit, and both fail closed, so neither exposes a consumer. F6 is the main legibility gap: the caller-facing inputs U2b3b will set are defined only in reader_set's comment, not in the contract the header calls "the one statement of it". F1 and F2 are optional renames.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/api-consistency-review-2026-10-08-u2b3a.md, structured per the api-consistency-reviewer skill, with `Commit: 5516c6e6` as its first line.
- Answered: yes
- Out of scope: Override rows 431 and 477 (outside-repo starts, the host settings line) are U2b3b's and were not re-flagged. Whether a HOME holding a newline should be refused at all is a policy question for the security critic. F3 reports only the inconsistency.
- Escalate: F3 overlaps the fact-check's E1 escalation (the own-HOME newline refusal), so the synthesis should merge them, not count them twice. F6's contract line is the natural place for U2b3b's settings-line caller to land.
- Decisions I made: I ran dev-cycle.bats myself (78/78), because the fact-check ran only build-loop-check.bats and --check-fix is the other consumer. I kept F1 and F2 at Minor and not Inconsistent, because each name has a defensible reading (`_FOR` gates reuse, not recomputation; "reader set" is the plan's term).
