Commit: 83cdb005

# Security Review: feat/build-loop-u1d (U1d)

**Scope:** `git diff main...HEAD` (one commit, 83cdb005): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats. Units read beyond the diff: `pathform`, `main_entry`, `brief_fields`, `check_brief`, `check_branch`, `resolve_main` and `check_answer` (lib), and `main_file`, `marker_kind`, `shared_branches` and `status_line` (build-loop.sh), plus the plan's D1, D5, D9 and F17 rows.
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1d.md (merged, k=3), including its Escalations section addressed to this critic.

## Trust Boundary Map

```
B1 (moved): [path string: --status/--check-* arg, git grep output, U2's changed paths] → [pathform, now inside main_entry] → [git ls-tree pathspec; answer blob|absent|notfile|notdir|error]
B2:         [docs on main's commit: dev-cycle.md, briefs, questions]                    → [FENCE_AWK / SETTINGS_AWK / brief_fields]        → [policy, never list, Status/Branch fields]
B3:         [repo git config + object store (the shared .git common dir)]                → [exit status of git calls in check_brief, check_branch, marker_kind, shared_branches] → [--status "ok"/"skip" line read by the orchestrator]
B4:         [caller environment: GIT_CONFIG_COUNT pairs]                                  → [cfg pair appended at build-loop.sh:112]          → [core.useReplaceRefs=false for every git read]
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | Brief path argument (`--status BRIEF`, `--check-brief`), originally repo text (roadmap lines) | request-time | UNTRUSTED for pathspec/path sinks (ls-tree, `rev:path`) |
| S2 | Brief contents on main (Status:, Branch:, Dispatched:) | runtime-mutable (any merged commit) | UNTRUSTED for ref/path sinks; the fields drive the skip/ok decisions |
| S3 | Path names in main's tree, as git grep lists them | runtime-mutable | UNTRUSTED for path sinks (fed back into brief_fields) |
| S4 | U2's changed-path list (a loop branch's diff), future caller of main_entry | loop-controlled | UNTRUSTED (all sinks) |
| S5 | `.git/config` and the object store, shared by every worktree, a loop's included | runtime-mutable | UNTRUSTED toward "a git failure is a positive answer"; a writer of it already has stronger primitives (hooks, fsmonitor), so trusted for availability only |
| S6 | Caller's `GIT_CONFIG_COUNT` / `git -c` | caller-set | trusted (documented at build-loop.sh:110-111) |
| S7 | Tip commit objects on a loop branch (subject, parents, tree) | loop-controlled | UNTRUSTED for the marker decision |
| S8 | Fixed file names (`docs/dev-cycle.md`, `docs/working/questions{,-archive}.md`) | code-constant | trusted |

The diff's one boundary change is B1: path-form validation moves from "every caller runs pathform first" into main_entry itself, ahead of U2's floor, which feeds main_entry loop-controlled paths (S4). The wording edits restate fail-closed behaviour on B2 and B3. The escalated issue (Finding 1) sits on B3, outside the diff: a git failure inside the `$(...)` subshells that build-loop.sh reads from.

## Findings

#### 1. A failed git read inside check_branch / marker_kind prints a positive `ok … working` line with DATE missing (the escalation)

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:382`, `scripts/build-loop.sh:282`, `:342-357`
**Boundary:** B3
**Move:** 3 (error path), 2 (assumed "positive line = answered")
**Confidence:** High (mechanism executed); Medium (consequence, since it depends on how U2/U3 consume the line)
**Legibility-target:** for-author
**Evidence:**
> `    if [[ -n "$sha" ]]; then echo "ok $a $sha $(git rev-list --count "$MAIN_SHA..$sha") $(git log -1 --format=%cs "$sha")"` (lib:382)
> `  msg="$(git log -1 --format=%B "$1")"; subj="${msg%%$'\n'*}"` (build-loop.sh:282; excerpt ends inside marker_kind, which continues to :297, read)
> `  out="$(check_branch "$br")"` (build-loop.sh:342)
> `    "ok "*) read -r _ _ sha ahead date <<<"$out" ;;` (build-loop.sh:345)
> `  echo "ok $a $st $pol $br $loop $sha $date $disp$reason"` (build-loop.sh:357)

The mechanism differs from the fact-check's description. The fact-check says the ahead count came back empty. In fact `git rev-list --count` succeeds under `grep.patternType bogus` (probe: prints `1`, rc 0). It is `git log` that dies (`fatal: bad grep.patterntype argument`, rc 128), and `log.date bogus` has the same effect. So `check_branch` prints `ok feat/x SHA 1 ` with an empty DATE, because a substitution inside `echo`'s arguments never trips `set -e`. Then `marker_kind` (run in `$(...)`, where bash does not inherit errexit) gets an empty `msg` and answers `working`. Executed at 83cdb005 with `log.date bogus`:

```
ok docs/working/briefs/2026-10-01-a.md done review feat/x working f5205b4…  0$     (clean run: skip …: not a marker)
ok docs/working/briefs/2026-10-01-b.md open review feat/y working 5c375d5…  0$     (clean run: ready … 2026-10-05 0)
```

`dev-cycle.sh --check-branch feat/x` under `grep.patternType bogus` printed `ok feat/x <sha> 1 ` (trailing empty DATE). By contrast, `dev-cycle.sh --check-brief` exits 128 with no line, because it calls check_brief in the main shell. The same lib function therefore fails closed in one script and prints a degraded positive line in the other.

**Is it fail-open?** It does not open merge or dispatch. `ready` degrades to `working`, so nothing merges, and the loop is counted as live, so it holds a slot (D9) and fewer loops start. The dispatch cap is enforced by `--prompt` reading the brief from main (plan D1/F45), not by this line. Two things do open, though:
- (a) A malformed-marker tip that should give `skip … not a marker` gives `ok … working` instead.
- (b) The line loses a field. Read positionally, DATE becomes the DISPATCHED value and DISPATCHED is missing. That breaks the lib header's contract ("treat any line that is not a positive answer as a refusal"), because a failed read arrives as a positive answer.

Reaching it needs a write to the shared `.git/config` (any worktree's process, a loop's included) or a corrupt object. A writer with that access already has stronger primitives, so this is Low, not a gate bypass. The floor rule does not apply: no reachable outcome advances a merge or a dispatch today.

**Which unit:** not U1d. U1d's stated intent is no behaviour change beyond the two named items, and the code predates it (check_branch is U0's lib move; marker_kind/status_line are U1c's). It belongs in **U2**. U2's `--check` state gate is the first consumer that decides on LOOP/SHA, and it calls the same readers. Record it as an override-log row with "U2" as the revisit trigger.

**Recommendation:** In check_branch, read the count and date into locals and fail closed: `n="$(git rev-list --count …)" && d="$(git log -1 --format=%cs …)" || { echo "skip $a: the branch could not be read"; return; }`, then validate `^[0123456789]+$` and the date shape. In marker_kind, a failed `git log`/`rev-list` should answer `bad … could not be read`, not `working`. In status_line, refuse an `ok` line whose `ahead`/`date` fields fail those shapes. Add a test with `git config log.date bogus` that asserts a skip.

#### 2. U2 must treat main_entry's `error` as a per-path refusal; it now also means "name refused"

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:263`
**Boundary:** B1 (moved)
**Move:** 11 (bypasses), 5 (invert: what does `error` prevent?)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> `  if ! main_by_name || ! pathform "$1"; then echo error; return; fi`

On the focus question, the earlier refusal **closes** a fail-open path and opens none. Executed against main's pre-guard lib, a present file `docs/é.md` read **`absent`**: ls-tree C-quotes the name, so the lookup in `m[]` misses. `docs/a*` and `:(top)docs/ab.md` read `absent` too. At 83cdb005 all three read `error`. A floor that answers "absent ⇒ new path ⇒ added-file rules" (T10 separates an added review from a modified one) would have read an existing quoted-name file as new. Now it cannot, even if U2 forgets F17's own pathform step.

What U2 must not do is map `error` to "skip this path" or "not counted". The `--status` code has exactly that pattern: shared_branches `continue`s past a brief that brief_fields refuses (build-loop.sh:313-314). Doing the same in a floor would let a loop drop a refused name out of the floor by giving it an odd name. Also, `error` now covers four causes: no default branch, ls-tree failed, a duplicate name, and pathform. The lib:252-255 list still names three. A merge-entry body that says "the tree could not be read" for a refused name would mislead the reviewer.

**Recommendation:** In U2, run pathform on every changed path first, with its own non-echoing reason (F17). Treat any main_entry answer other than `blob`/`absent` as a refusal of that path and of the merge, never as a skip. Add `pathform` to the error list at lib:252-255.

#### 3. The fail-closed wording edits claim no more than the code delivers

**Severity:** Informational
**Location:** `scripts/build-loop.sh:17-18`, `:68-72`, `:307-309`
**Boundary:** B2, B3
**Move:** 2
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
> `#                 also needs a valid never line, so a never list hidden in`
> `#                 markup, with no exact never line beside it, turns it off.`
> `  # an exit above 1 fails closed (SHARED_BRANCHES=error: every open brief`
> `  # skips). A brief git grep cannot read is not counted (row 293).`

Every imprecision the fact-check found runs in the safe direction. In Claim 1, letter-preserving markup beside an exact line makes the never line malformed, so self-merge is **off**, where the sentence implies on. When the markup hides the list from the copy count, an exact line wins and the hidden list is ignored; the header's "only an exact line ever sets a value" (:39-42) already discloses that. In Claim 7, a corrupt blob makes git grep exit 128, which fails closed for all briefs and is stricter than "not counted". In Claim 3, the marker skip also applies to done briefs, which is more skipping, not less. Dropping "(git grep failed)" leaks less mechanism. No edited comment now asserts a guarantee the code lacks. Wording fixes, if wanted, belong to the fact-check's ambers.

**Recommendation:** None for security.

## Untested bypass candidates

Move 11 on main_entry's guard. Tested (all `error`): trailing `\n`, an embedded `\n`, `é`, a fullwidth `ａ`, NBSP, `*`, a trailing `/`, `:(top)` magic, the empty string, `./`, and the dev-cycle.bats set (`"`, `../`, a leading `-`, `//`). The non-ASCII inputs were tried under C, C.UTF-8 and POSIX. Untested:
- **Bracket matching under other installed locales** (tr_TR, en_US.UTF-8): not installed in this sandbox. pathform lists its characters one by one to avoid locale ranges (lib:136-139), but this was not exercised.
- **Case-variant names** (`DOCS/ab.md` → `absent`): true on git's case-sensitive tree. Whether U2's floor compares case-folded (as `INSTRUCTION_FILE` does) is U2's design, not testable here.
- **ARG_MAX on a very deep path** (ls-tree gets one pathspec per directory level): expected to make ls-tree fail, which gives `error`, but this was not run.

Because of these, the guard itself does not appear under Endorsement Claims.

## Endorsement Claims

- **Claim:** Moving pathform into main_entry changes no existing caller's printed output, because brief_fields (lib:296) and check_brief (lib:327) run pathform before calling main_entry, and check_answer (lib:553-554) and main_file (build-loop.sh:122-124) pass only fixed names that pathform accepts.
  **Location:** `scripts/lib/dev-cycle-read.sh:263`, `:296`, `:327`, `:553-554`; `scripts/build-loop.sh:124`
  **Evidence:** read-static
  **Verified:** every `main_entry "` call site found by `rg` in scripts/ (4 sites), and each one's preceding guard or literal argument.
  **Not verified:** callers outside scripts/ (skills or hooks that source the lib) were not searched.
  **route: code-fact-check**
- **Claim:** The new dev-cycle.bats test fails when the pathform guard is removed from main_entry (3 of its 4 paths flip from `error`).
  **Location:** `test/scripts/dev-cycle.bats:1328-1335`
  **Evidence:** read-static (relying on fact-check Claim 21's executed mutant m5b)
  **Verified:** the test body, and the fact-check's mutant result.
  **Not verified:** ordering. A mutant that runs pathform after the ls-tree read passes, but its answer is the same `error`.
  **route: code-fact-check**
- **Claim:** The U1d --settings test fails when a caller-supplied GIT_CONFIG_COUNT stops the core.useReplaceRefs=false pair from applying (a replace ref then swaps in the self-merge blob).
  **Location:** `test/scripts/build-loop-read.bats:420-425`; `scripts/build-loop.sh:112`
  **Evidence:** read-static (relying on fact-check Claim 14's mutants m4, M3, M4c)
  **Verified:** the test sets a replace ref plus `GIT_CONFIG_COUNT=1` and asserts `policy review`.
  **Not verified:** that the caller's own pair is preserved. A mutant that overwrites index 0 passes, though it does not weaken the guard.
  **route: code-fact-check**

## Primitive sweep

Primitive: an untrusted path reaching a git object read (an ls-tree pathspec, or `rev:path`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:265` (ls-tree in main_entry) | S1, S3, S4 | pathform at :263 (new), `--`, GIT_LITERAL_PATHSPECS in both scripts | cleared: probed inputs give `error` (Finding 2 covers U2's use) |
| `scripts/lib/dev-cycle-read.sh:299` (cat-file in brief_fields) | S1, S3 | pathform plus main_entry == blob (:296) | cleared |
| `scripts/lib/dev-cycle-read.sh:563` (cat-file in check_answer) | S8 | fixed names | cleared: code constants |
| `scripts/build-loop.sh:132` (cat-file in main_file) | S8 | fixed names | cleared: code constants |
| `scripts/build-loop.sh:310` (git grep) | S8 pathspec, MAIN_SHA | fixed pathspec | cleared: its output (S3) goes through brief_fields' pathform |
| `scripts/build-loop.sh:284` (cat-file commit) | sha from show-ref (hex) | show-ref --verify + rev-parse ^{commit} | cleared |
| `scripts/dev-cycle.sh:296` (cat-file -e HEAD:$f) | shell glob of docs/decisions (working tree) | rawfile | cleared: existence probe only, outside the diff |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | A git failure in check_branch/marker_kind prints `ok … working` with DATE missing (the escalation; defer to U2) | Low | B3 | `lib:382`, `build-loop.sh:282`, `:342-357` | High (mechanism) / Medium (impact) |
| 2 | U2 must treat main_entry `error` as a per-path refusal; the error list omits pathform | Informational | B1 | `lib:263`, `:252-255` | High |
| 3 | The fail-closed wording edits err in the safe direction | Informational | B2, B3 | `build-loop.sh:17-18`, `:68-72`, `:307-309` | High |

## Overall Assessment

There are no findings within the diff's code paths; the endorsement claims are pending execution verification. The one behaviour change, main_entry's own pathform guard, closes a real fail-open: a present non-ASCII or pathspec-magic name used to read `absent` and now reads `error`. That matters for U2, whose floor will feed it loop-controlled paths. The guard opens nothing as long as U2 treats `error` as a refusal, never a skip (Finding 2). The escalated issue is real but outside the diff, with a different mechanism than reported: `git log` fails, not `rev-list`. It degrades `ready`/`skip` to `working`, never toward merge or dispatch, so it is Low. It belongs to U2, which first gates on these readers. The single most important follow-up is an override-log row deferring Finding 1 to U2, with a `log.date bogus` regression test.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/security-reviewer-review-2026-10-06-build-loop-u1d.md (first line `Commit: 83cdb005`), structured per the security-reviewer skill.
- Answered: yes. The pathform guard (closes `absent` for quoted names; opens nothing if U2 refuses on `error`), the wording edits (all err safe) and the escalation (Low, not fail-open toward merge or dispatch; defer to U2) are all covered.
- Out of scope: the fact-check's non-security ambers (test titles, Claims 15-18, 24); hostile-config hardening in general (U3b's hardened git).
- Escalate: Finding 1 needs an override-log row (trigger: U2). Also correct the fact-check's mechanism for the escalation: `git log` fails, while `rev-list --count` works.
- Decisions I made: I rated Finding 1 Low rather than Medium under the floor rule, because no reachable outcome advances a merge or dispatch; Medium would follow if U2's gate is counted as reachable. I assigned it to U2 rather than a standalone fix unit, because U2 is the next unit touching these readers.
