Commit: eddfd5f9

# Architecture Review — feat/build-loop-u2c1 (U2c1, iteration 1)

**Scope:** `git diff main...HEAD` (one commit, eddfd5f9): scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh (header comments), test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2c1.md (Commit eddfd5f9); override-log rows 523, 530, 546, 547

Scope check: in scope. The diff adds a cross-cutting rule set (the S rules) to the gate's verdict pipeline. It moves `check_line` out of its subshell, which changes how per-brief state is isolated. It also edits the lib's caller contract, which is the public interface between `dev-cycle-read.sh` and its callers. The test and plan edits were read only as evidence.

Trust-boundary scan: no security review for U2c1 exists yet. The most recent build-loop security review, `docs/reviews/security-review-2026-10-09-u2b3b2c-i1.md` (Commit: `f7e1bea2`, which predates this diff), maps walk-side boundaries (B1-B5: reader roots, dangling links, registry). None of the module-boundary findings below moves or relocates one of those crossings.

## Dependency Map

- `build-loop.sh` sources `scripts/lib/dev-cycle-read.sh`. It now calls these lib functions per changed path: `floor`, `ownfile`, `truthrule` and `pathform`. It reads the lib globals `FLOOR_WHY`, `TRUTH_WHY` and `BRIEF[paths]`. Per brief it also calls `brief_fields` and `import_reset`.
- New in build-loop.sh: `paths_read` (BRIEF → PATHS/PATHS_WHY), `never_res` (NEVER from `read_settings` → NEVER_RES) and `srules` (floor → never → Paths/ownfile). These sit next to `nrules`.
- Direction: the caller (build-loop.sh) depends on the lib. The lib's code still has no call into build-loop.sh. Its prose now names more of the caller's internals, though: header item 5 and the `FLOOR_WHY` comment "read by floor's caller (build-loop.sh srules)". See F5.
- Plan D5's allowlist is split across the two modules: the `Paths:` half is in build-loop.sh (`paths_read`, `srules`) and the own-file half is in the lib (`ownfile`). The floor is in the lib. The never globs are parsed in build-loop.sh (`read_settings`) and compiled there (`never_res`).
- `check_line` now runs in the main shell of `--check`. Every global it or its callees set persists from one brief to the next.

## Findings

#### F1. The list-line grammar is now written three times, and row 546's trigger fired with no disposition

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:613-628` (paths_read), `scripts/build-loop.sh:390-408` (read_settings), `scripts/lib/dev-cycle-read.sh:622-634` (reader_settings)
**Move:** 7 (coupling surface), 2 (responsibility)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:619-626 (paths_read; continues to :628)
  if [[ "$t" != "Paths: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then PATHS_WHY='is not exactly "Paths: PATH ..." with single spaces'; return 0; fi
  IFS=' ' read -ra PATHS <<<"$v"  # not a bare $v: the shell would expand * and ? against files
  for e in "${PATHS[@]}"; do
    i=$((i + 1))
    if ! pathform "${e%/}"; then PATHS_WHY="lists entry $i, which is not an allowed path form"; break; fi
    if [[ -n "${seen[${e%/}]-}" ]]; then PATHS_WHY="lists entry $i twice"; break; fi
    seen[${e%/}]=1
```
```bash
# scripts/build-loop.sh:393-403 (read_settings, Self-merge never:)
      if [[ "$t" != "Self-merge never: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
...
        IFS=' ' read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
        for g in "${parts[@]}"; do
          i=$((i + 1))
          if ! globform "${g%/}"; then why="lists entry $i, which is not an allowed glob form"; break; fi
          if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"; break; fi
```
```
override-log.md:546 ... the list-line rule (exact key, single spaces, next line blank, form check, listed once) is written twice ... | 🟡 Must Address (Coupling) | Defer | Both copies are correct and tested; a shared decoder and list-line helper would move ~40 lines already on main past the 400-line cap (the unit is at 397). Revisit trigger: the next settings key, or U2c (which parses `Paths:` lists).
```

Row 546 deferred this coupling and named U2c as the point to revisit it. U2c1 adds a third copy instead: `paths_read` repeats the single-space regex, the `IFS=' ' read -ra` split, the form check on `${e%/}` and the `seen` duplicate check almost token for token. The plan's U2c split note does not mention row 546 under U2c1 or U2c2, so the trigger fired and nothing disposed of it. The deferral rested on the size cap ("the unit is at 397"). That reason does not hold here: the commit message counts 229 changed code lines, and the cap is about 400.

The copies also differ in ways a reader cannot see from any one of them:
- An empty list is spelled `Paths:` alone, but `Self-merge never: none` / `Reader roots: none`; a bare `Self-merge never:` is malformed.
- `Paths:` has no next-line-blank check, so a wrapped `Paths:` line silently drops its continuation. This fails closed, but the plan's grammar doesn't record it.
- A malformed line has a different consequence each time: own files only, self-merge off, or both walks fail.

Each future grammar change (a new form character, quoting) has to be made three times.

**Recommendation:** Extract one helper, e.g. `list_line KEY TEXT FORMFN` that sets `LIST=()` / `LIST_WHY`, and call it from all three sites. It fits within U2c1's remaining budget. If it stays deferred, add an override row that re-keys row 546's trigger and lists the three intentional differences above, so the next editor knows they are deliberate.

#### F2. The allowlist's own-file half inherits the floor's case policy, so the allowlist widens by case

**Severity:** Minor
**Location:** `scripts/build-loop.sh:658`, `scripts/lib/dev-cycle-read.sh:1805-1810`, `scripts/lib/dev-cycle-read.sh:1842`
**Move:** 3 (module boundary), 6 (substitutability)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:658 (srules, $3 = lower-cased path; srules continues to :664)
  ! ownfile "$3" "$1" "$4" || return 0
```
```
# docs/working/plan-build-loop-handoff.md:311
`Paths: P …` (rev 2's grammar): single spaces, pathform entries compared exactly (an allowlist widens nothing by case)
```
```bash
# scripts/lib/dev-cycle-read.sh:1842 (floor's use of the same predicate)
  elif [[ "$lp" == docs/working/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY="a working file that is not this brief's own (they carry its full stem)"
```

`ownfile` was written for the floor. The floor lower-cases every path because a case-insensitive checkout aliases `Docs/` to `docs/`, so there a case-folded own-file match is the conservative reading. srules reuses the same predicate as half of an *allowlist* and passes it the lower-cased spelling. The two halves of plan D5's allowlist therefore compare differently: `Paths:` entries compare exactly (`:661`), but own files compare lower-cased. The fact-check's FCPROBE 1 shows `Docs/Working/Plan-2026-10-01-x.md` landing (Claim 2a). The impact is low, but the case policy of an allowlist now depends silently on how a lib predicate built for a different role treats its input. A later change to ownfile's input contract for the floor would change the allowlist too.

**Recommendation:** In srules, pass the exact path: `! ownfile "$2" "$1" "$4"`. The floor already lets a case-variant own file through, so it would then be judged by `Paths:`. Add one line to ownfile's comment saying its result depends on the spelling it is given, and one test.

#### F3. The verdict chain grows again, and row 530's trigger fired with no disposition; one new early return breaks the stated precedence

**Severity:** Minor
**Location:** `scripts/build-loop.sh:797-800`, `scripts/build-loop.sh:815`, `scripts/build-loop.sh:818`
**Move:** 8 (extension points), 2
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:797-800 (check_line, continues to :820)
  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"; fi
  # The S rules' inputs, read again from main's commit (status_line read them in a subshell).
  stem="${a##*/}"; stem="${stem%.md}"
  if [[ "$pol" == self-merge ]]; then brief_fields "$a" || { echo "refuse $a: the brief could not be read again"; return 0; }; paths_read; fi
```
```bash
# scripts/build-loop.sh:815
    [[ -n "$DENY" || "$pol" != self-merge || "$p" == "$a" ]] || srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"
```
```
override-log.md:530 Verdict precedence in check_line spread over two early returns and an if-chain ... | 🟢 Consider (Informational) | Defer | Revisit trigger: U2c (it extends the verdict chain), a second floor caller, or a second callervar exception.
```

U2c1 extends the chain, which is exactly row 530's trigger, and neither the plan's split note nor the commit says what was decided. Three changes add to the spread:
1. A new early return (brief re-read failed) sits between the computation of `co` and its use.
2. The policy dispatch and the "own brief: N rules only" rule are encoded as a three-way guard in the per-path loop.
3. `co` reaches srules as a parameter whose only job is to switch the floor off.

One concrete precedence slip results. The comment at `:792-796` says the checkout refusal "replaces the verdict line only, so the path and deny lines still print", but when `brief_fields` fails after `co` is set, the run prints neither `co` nor any path line. Both outcomes refuse, so nothing is unsafe, but each new rule now has to be placed by reading the whole 65-line function, and U3's `--merge`/`--approved` will extend it again.

**Recommendation:** Record a disposition for row 530 (defer to U3 with a re-keyed trigger, or act on it). At minimum, move the brief re-read above `checkout_gate`, or fold its failure into `co`, so the stated precedence holds. If acting, have check_line compute a per-brief rule set once (N only, or N+S with floor on/off) and call one `path_rules` function per path.

#### F4. Moving check_line into the parent shell replaces structural isolation with a reset-by-convention invariant that nothing states

**Severity:** Minor
**Location:** `scripts/build-loop.sh:838-842`, `scripts/build-loop.sh:755-759`
**Move:** 4 (cross-cutting lifecycle), 7
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:838-842
      # In this shell, not $(...): the floor's need_root exit ends the run, and
      # check_line's import_reset is what keeps one brief's walk from the next.
      check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"
      [[ "$(head -c 3 "$GATE_TMP/line")" == "ok " ]] || fails=1
```
```bash
# scripts/build-loop.sh:757-759
  local -x LC_ALL=C
  local a="$1" out st pol br loop sha n tree meta p shown co stem rc=0 i nd=0 rows=() oms=() nms=() nos=() ss=() ps=() lps=() ids=()
  import_reset  # caller contract item 4: no walk cache outlives a decision
```

The move is justified: it makes need_root's exit end the run and makes import_reset observable, and the fact-check confirms both by mutation. But the `$(...)` was also the only structural guarantee that no per-brief state survives into the next brief. Now `DENY`, `PATHS`, `PATHS_WHY`, `BRIEF`, `TRUTH_WHY`, `FLOOR_WHY`, `CHECKOUT_WHY` and the lib's walk caches all persist. Two things keep them apart today: each setter resets its own global before use (verified by the fact-check, Claim 12), and srules/paths_read run only for self-merge briefs. Under `set -euo pipefail` (`:202`), errexit now also applies inside check_line, where `$(...)` used to clear it. Any unguarded failing command added later ends the whole `--check` instead of one brief's line.

None of this is written down where a U3 author adding a global to check_line would see it: the check_line comment and the lib's contract item 4 cover only the walk caches. The comment at `:838` is accurate but names only the benefit.

**Recommendation:** Add a sentence to check_line's header comment: it runs in `--check`'s shell under `set -e`, every global it or its callees set must be reset before use, and any non-zero command must be guarded. Optionally add a test that runs a self-merge brief followed by a review brief and asserts that the second shows no srules deny wording.

#### F5. The lib's caller contract now documents one caller's internals

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:76-85`, `scripts/lib/dev-cycle-read.sh:1824`
**Move:** 1 (dependency direction), 3
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
# scripts/lib/dev-cycle-read.sh:79-83
#     build-loop.sh reads diff-tree -r of main and the merge instead, where a
#     symlink or gitlink above a path is a changed entry of its own. Floor
#     item 5 (symlinks, gitlinks) and the brief's own Status change are the
#     caller's rules; build-loop.sh's N rules apply them, and pathform, under
#     both policies, and its S rules run floor only on a path they pass, so a
```
```
# scripts/lib/dev-cycle-read.sh:1824
FLOOR_WHY=""  # read by floor's caller (build-loop.sh srules)
```

The header calls itself "the one statement" of the gate caller contract for floor and main_imports, meaning any caller. Item 5 now has two branches: a generic rule ("a caller that reads a path from main by name asks floor before main_entry") and a description of how build-loop.sh satisfies it, naming its N and S rules. That was already the pattern (items 3 and 4 name build-loop.sh), and the edit is accurate (fact-check Claim 14). The cost is the usual one for prose dependencies running the wrong way: every rename in build-loop.sh (srules, nrules) now needs a lib header edit. A second floor caller would also have to tell the generic duty apart from build-loop.sh's particular way of meeting it.

**Recommendation:** No change needed for U2c1. When U3 or a second floor caller arrives, keep the generic duty in the header and move the "how build-loop.sh meets it" sentences into build-loop.sh's own comments, with a pointer back.

#### F6. status_line now runs under two locales depending on the mode

**Severity:** Informational
**Location:** `scripts/build-loop.sh:757`, `scripts/build-loop.sh:479`, `scripts/build-loop.sh:827`
**Move:** 4 (cross-cutting concern)
**Confidence:** Low
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:757
  local -x LC_ALL=C
# scripts/build-loop.sh:479 (status_line)
  if [[ ! "${BRIEF[branch]}" =~ ^Branch:\ ([^\ ]+)$ ]]; then echo "skip $a: its first Branch: line is not exactly \"Branch: NAME\""; return; fi
# scripts/build-loop.sh:827 (--status)
    for a in "${ARGS[@]}"; do status_line "$a"; done
```

Contract item 1's locale is set per function, inside check_line, not at the mode's entry. Because `local -x` is dynamically scoped, the `status_line` call that check_line makes now runs under C, while `--status` calls the same function under the caller's locale. Bracket expressions such as `[^\ ]+` treat non-UTF-8 bytes differently in the two locales, so `--status` and `--check` could in principle read the same brief's Branch: line differently. I have not executed this. The fact-check saw no difference in the suite (Claim 10 scope).

**Recommendation:** Consider setting `LC_ALL=C` once for every mode at script entry, after any locale-dependent output, so all readers share one locale. Or note in the check_line comment that status_line inherits it.

## What Looks Good

- **Dependency direction is right.** The S rules live in the caller and compose lib primitives (`floor`, `ownfile`, `truthrule`, `pathform`) without adding any lib → caller call. `FLOOR_WHY` stays a lib-owned output.
- **srules is a separate function** with a narrow argument list and one output (`DENY`), next to `nrules` and in the same style. The first-match order (floor → never → allowlist) is readable in a single 13-line body.
- **never_res compiles the globs once**, after `read_settings`, and keeps parsing (`read_settings`/`globform`) apart from matching. Every character globform admits is handled (fact-check Claim 8).
- **The nrules prefix loop reuses `truthrule`** rather than adding a second list of cycle file names, so row 523's fix tracks future cycle files automatically.
- **check_line's move to the parent shell is tested by mutation.** Removing `import_reset` or `LC_ALL=C` fails a test (fact-check Claims 10 and 12), which turns two previously invisible invariants into checked ones.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | List-line grammar written a third time (paths_read); row 546's trigger fired with no disposition, and the cap reason no longer holds | Coupling | `scripts/build-loop.sh:613-628` | High |
| F2 | ownfile gets the lower-cased path in srules, so the allowlist widens by case, against plan:311 | Minor | `scripts/build-loop.sh:658` | High |
| F3 | Verdict chain extended (row 530's trigger, no disposition); the brief re-read return drops `co` and the path lines | Minor | `scripts/build-loop.sh:797-800` | High |
| F4 | Parent-shell check_line: global isolation and errexit now rest on an unstated convention | Minor | `scripts/build-loop.sh:838-842` | Medium |
| F5 | Lib contract item 5 and the FLOOR_WHY comment describe build-loop.sh internals | Informational | `scripts/lib/dev-cycle-read.sh:76-85` | Medium |
| F6 | status_line runs under C in --check and the caller's locale in --status | Informational | `scripts/build-loop.sh:757` | Low |

## Overall Assessment

The change keeps the system's structure sound. The S rules sit on the caller's side of the lib boundary and compose existing primitives, and the parent-shell move is a net gain because it makes two contract invariants observable. All findings can be fixed in place. The most important one is F1, a process problem as much as a code one. Two prior deferrals (rows 546 and 530) named U2c as their revisit point, and U2c1 hit both triggers without a disposition in the plan's split note or the commit. For row 546, the deferral's own reason (the line cap) no longer applies. F2 is the one place where reusing a lib predicate quietly changes a stated rule. It is a one-token fix.

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line.
- Answered: yes. All four focus areas were covered: where the S rules live (F2, F5), the verdict chain / row 530 (F3), the parent-shell move (F4, F6) and the duplicated list-line grammar / row 546 (F1).
- Settled rows: 530 and 546 are re-raised only because their own revisit triggers name U2c and the diff extends exactly what they describe. Row 547's trigger ("U2c's floor caller") was checked: build-loop.sh calls `reader_settings` at `:325` before any walk, so it is not re-raised. Row 523 is resolved by the diff.
- Out of scope: correctness of the floor itself, performance (the timings), and security of the glob matching.
