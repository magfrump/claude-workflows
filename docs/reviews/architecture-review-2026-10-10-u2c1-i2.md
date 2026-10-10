Commit: cf7dd447

# Architecture Review — feat/build-loop-u2c1 (U2c1, iteration 2, fix range)

**Scope:** `git diff eddfd5f9..HEAD -- scripts test` (d435100e, cf7dd447): scripts/build-loop.sh, test/scripts/build-loop-check.bats; plan text changed in that range; override rows 608-616
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2c1-i2.md (Commit cf7dd447); my iteration-1 report docs/reviews/architecture-review-2026-10-10-u2c1.md (Commit eddfd5f9); rubric docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c1.md

Scope check: in scope. The fix range adds a shared parser (`list_entries`) that two modules' grammars now depend on. It also changes which input a lib predicate (`ownfile`) receives from its caller and states check_line's per-brief isolation convention. The lib (`scripts/lib/dev-cycle-read.sh`) is not changed in this range. I read it as context because the fix range relies on its contract.

Trust-boundary scan: `docs/reviews/security-review-2026-10-10-u2c1.md` (Commit: eddfd5f9) is the most recent security review. None of the findings below moves a boundary it labels, so the cross-reference does not apply.

## Dependency Map

- `build-loop.sh` sources the lib. New in this range: `list_entries LINE KEY WORD FORM` (build-loop.sh:356-377) sets the globals `LIST`/`LIST_WHY` and calls FORM by name. Its two callers are `read_settings`' never branch (`:416`, FORM `globform`, defined in build-loop.sh) and `read_paths` (`:628`, FORM `pathform`, defined in the lib). `read_paths` replaces `paths_read`.
- The lib's `reader_settings` (lib :604-655) still has its own copy of the list-line grammar (row 616).
- `srules` now passes `ownfile` (lib :1805) the path as spelled (`$2`). Before, it passed the lower-cased spelling.
- `srules`' never deny reads `NEVER[i]` and `NEVER_RES[i]` as parallel arrays. `never_res` builds one regex per NEVER entry, in order (fact-check Claim 13).
- `check_line`'s failed re-read now writes `PATHS`/`PATHS_WHY` itself (`:809`). Before, the failure was an early return. `read_paths` is the other writer of those globals.
- Dependency direction is unchanged: the lib still makes no call into build-loop.sh.

## Iteration-1 dispositions (confirmed against the code)

| i1 | Rubric | Disposition claimed | Confirmed |
|---|---|---|---|
| F1 (Coupling) | A1 | Fixed in part; lib copy deferred (row 616) | Yes for build-loop.sh: one parser, two callers, no `paths_read` left (fact-check 3, 8, 10: 44-case differential, 0 differences). Row 616 exists. Its reason misdescribes the constraint (F-iii below). |
| F2 (Minor) | B1 | Fixed: ownfile gets the path as spelled | Yes in code (`:663`, mutation-tested, fact-check 12). ownfile's lib comment still states the old precondition (F-i below). |
| F3 (Minor) | B5 | Slip fixed; chain deferred to U3 (row 613) | Yes. The early return is gone, so `co` and every path line print after a failed re-read (fact-check 15, forced-failure probe). Row 613 re-keys row 530's trigger to U3's --merge, which is acceptable. |
| F4 (Minor) | B6 | Fixed in text | Yes, the check_line header now states the convention (`:759-762`). Two precision gaps remain (F-v below). |
| F5 (Info) | B10 | Won't-Fix (row 614) | Accepted. Row 459's reading, that the contract names who discharges each duty, is a fair basis. |
| F6 (Info) | B10 | Won't-Fix (row 615) | Accepted. |

## Findings

#### F-i. srules now depends on ownfile's implementation, against ownfile's stated contract

**Severity:** Minor
**Location:** `scripts/build-loop.sh:652-655`, `scripts/build-loop.sh:663`, `scripts/lib/dev-cycle-read.sh:1798-1810`
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/lib/dev-cycle-read.sh:1798-1800 (ownfile's comment; the function runs :1805-1810)
# A brief's own files, keyed on its full stem $2 (YYYY-MM-DD-slug, so a slug
# shared by two dates is not a collision), for a lower-cased path $1 with
# diff-tree status letter $3: its working docs, docs/working/{research,plan,
```
```bash
# scripts/build-loop.sh:652-655, :663 (srules; the function continues to :669)
# allowlist widens nothing by case: Paths: entries compare exactly, and ownfile
# gets the path as spelled, so an own file passes only when the diff spells
# it in lower case (ownfile folds nothing).
...
  ! ownfile "$2" "$1" "$4" || return 0
```

The B1 fix is correct, and the test pins it: test 3 fails with `ownfile "$3"` restored (fact-check 12). But the lib documents `$1` as "a lower-cased path", and srules now deliberately passes a path that may not be lower-cased. The fix's safety rests on "ownfile folds nothing", which is a fact about ownfile's body, and only the caller states it. Suppose a later lib edit honours the documented precondition defensively, say by folding `$1` or matching case-insensitively, because "callers pass it lower-cased anyway". The allowlist would then widen by case again. The lib author would have no hint that a caller relies on the opposite. In iteration 1, F2 asked for this line in ownfile's comment, and the fix batch put it only at the caller.

**Recommendation:** Change ownfile's comment to "for a path $1 as given (it folds nothing: floor passes it lower-cased, build-loop.sh's srules as spelled, so an allowlist widens nothing by case)". This is one comment line in the lib header region, with no code change.

#### F-ii. read_settings orders its reasons by matching the text of list_entries' reason

**Severity:** Minor
**Location:** `scripts/build-loop.sh:415-421`, `scripts/build-loop.sh:367`
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:415-421 (read_settings' never branch; read_settings continues to :460)
      t="${text[never]}"; v="${t#Self-merge never: }"
      list_entries "$t" "Self-merge never" glob globform; why="$LIST_WHY"
      # The form reason comes first, then the next line, then the entries.
      if [[ "$why" != "is not exactly"* && "${next[never]}" != 1 ]]; then why="is followed by a non-blank line outside a fence (it may continue the list)"; fi
      if [[ -n "$why" ]]; then NEVER_LINE="never malformed: line ${first[never]} $why"
      elif [[ "$v" == none ]]; then never_ok=1; NEVER_LINE="never none: line ${first[never]} $where lists none"
```
```bash
# scripts/build-loop.sh:367 (list_entries; continues to :377)
  if [[ "$1" != "$2: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then LIST_WHY="is not exactly \"$2: ${3^^} ...\" with single spaces"; return 0; fi
```

The precedence is preserved exactly: the fact-check's differential found 0 differences over 44 cases. But it now hangs on the wording of the helper's message. Whether the next-line rule overrides a reason depends on whether that reason starts with the literal "is not exactly". That string lives in another function, and nothing ties the two together. Rewording the form reason in list_entries, for example to say which key, would silently move the next-line reason ahead of a form error. No test says the order changed (`build-loop-read.bats` checks reasons by full text, so it would fail, but as a wording mismatch, not as a precedence change). read_settings also re-strips the key into `v` to test `none` and to build NEVER_LINE, which repeats what list_entries just decided. This keeps a second spelling of the "none" rule beside the shared one.

**Recommendation:** Have list_entries say which kind of reason it set, through its return status or a `LIST_KIND=form|entry` global, and branch on that. Test `${#LIST[@]} -eq 0` (or the kind) rather than `"$v" == none`. Or, if the size budget rules this out, add a one-line comment at `:418` naming the coupling ("matches list_entries' form reason, :367").

#### F-iii. Row 616's deferral reason describes a constraint the helper's placement created

**Severity:** Informational
**Location:** `scripts/build-loop.sh:356-377`, `scripts/lib/dev-cycle-read.sh:626-641`, `docs/reviews/override-log.md:616`
**Move:** 1 (dependency direction), 3
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
override-log.md:616 ... | Fixed in part; rest Defer | Fixed for build-loop.sh: list_entries now parses both Self-merge never: and Paths: ... The lib's reader_settings keeps its own copy (it has two keys and the lib cannot call build-loop.sh). Revisit trigger: unchanged from row 546 (a fourth list line, or the next edit of reader_settings).
```
```bash
# scripts/lib/dev-cycle-read.sh:629-631 (reader_settings; continues to :655)
      elif [[ "$t" != "$key "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then why="line ${first[$k]} is not exactly \"$key PATH ...\" with single spaces"
      elif [[ "${next[$k]}" != 1 ]]; then why="line ${first[$k]} is followed by a non-blank line outside a fence (it may continue the list)"
      elif [[ "$v" != none ]]; then
```

"The lib cannot call build-loop.sh" is true. It argues for putting `list_entries` in the lib, though, not for keeping two copies. list_entries depends on nothing in build-loop.sh: it takes FORM by name, and one of its two FORMs (`pathform`) is already a lib function. In the lib it would be callable from reader_settings, from build-loop.sh and from any later Paths: reader, such as row 612's possible --status reader or U3/U4's entry writer, with the dependency pointing the right way. Where it sits now, the shared grammar lives in the caller, and the one copy in the stable module is the one left out. The remaining duplication is back to the two copies row 546 accepted, so nothing is urgent. The record should still give the real reason, which is the size cap or the unit staying within build-loop.sh, so the next editor does not read "cannot" as a hard limit.

**Recommendation:** Amend row 616's reason to name the real constraint, and record that the helper's home is the lib. Or move `list_entries` into the lib now, a pure move with no line growth, and leave reader_settings' adoption to its own revisit trigger.

#### F-iv. The re-read fallback reports a brief-level failure through the Paths: channel, and PATHS gains a second writer

**Severity:** Informational
**Location:** `scripts/build-loop.sh:808-809`, `scripts/build-loop.sh:664`, `scripts/build-loop.sh:624-630`
**Move:** 2 (responsibility), 7
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:809 (check_line; continues to :828)
  if [[ "$pol" == self-merge ]]; then if brief_fields "$a"; then read_paths; else PATHS=(); PATHS_WHY="could not be read again"; fi; fi
```
```bash
# scripts/build-loop.sh:664 (srules)
  [[ -z "$PATHS_WHY" ]] || { DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"; return 0; }
```

This fixes the precedence slip from iteration 1. It does so by turning "the brief could not be read" into a reason about its Paths: line, so each deny reads "the brief's Paths: line could not be read again". What failed is the whole brief_fields read, not the Paths: line. PATHS/PATHS_WHY now also have two writers, read_paths and check_line, so the "each helper empties its own globals" convention at `:761-762` has one exception. The outcome is sound (fact-check 15). The cost is a misleading per-path reason and a second place to update if the Paths state ever grows a field.

**Recommendation:** Move the fallback into read_paths. For example, `read_paths` could take the brief_fields status and set `PATHS_WHY` itself, keeping one writer. Word the reason as the brief's: "the brief could not be read again, so only its own files land". This is optional. Row 612 already defers the brief-level reason shape.

#### F-v. check_line's isolation comment lists a subset of the globals and overstates where set -e applies

**Severity:** Informational
**Location:** `scripts/build-loop.sh:759-762`
**Move:** 4 (cross-cutting lifecycle)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:759-762
# status_line, then the gate's own reasons). It runs in the caller's shell
# (set -e applies; an exit ends the run), so nothing but its locals and the
# walk caches it resets may carry from one brief to the next: each helper it
# calls empties its own globals (DENY, PATHS, BRIEF, CHECKOUT_WHY, FLOOR_WHY).
```

This resolves iteration-1 F4's core ask: the convention is now written where a U3 author will see it. Two gaps remain. First, the parenthesised list reads as complete, but check_line's helpers also set PATHS_WHY, LIST, LIST_WHY, TRUTH_WHY and the lib's walk globals (fact-check 14b scope), and F-iv's fallback writes PATHS itself. Second, per fact-check 14a, errexit is suspended inside floor's whole walk and inside brief_fields, checkout_gate and nul_list, because they are called in conditions, and inside every `$(...)`. "set -e applies" holds only for check_line's own lines and for nrules/srules. The invariant a future editor needs is "a failing command in these helpers continues", which is the opposite of what the comment says.

**Recommendation:** Write "e.g." before the list, or name the rule rather than the members ("every global a helper sets is reset by that helper before use"). Narrow the set -e clause to the fact-check's precise version.

## What Looks Good

- **One grammar, two callers.** `list_entries` has a narrow signature. FORM is a strategy passed by name, and WORD derives the reason placeholder. Both lists now share the "none" spelling, the single-space rule, the form check on `${e%/}` and the duplicate check. The differential shows the never line's behaviour is byte-identical (fact-check 9, 10).
- **The B1 fix restores the plan's rule** that the two halves of the allowlist compare the same way. The mutation-tested case in test 3 keeps it from regressing.
- **The never deny names its glob** through index-aligned NEVER/NEVER_RES. This keeps parsing (`read_settings`) and compilation (`never_res`) separate, and the deny line can name the rule as written.
- **The failed re-read no longer short-circuits the verdict chain.** The stated precedence (checkout refusal replaces the verdict line, and path lines always print) now holds on every path through check_line.
- **Deferrals are dispositioned this time.** Rows 613 and 616 re-key the triggers of rows 530 and 546, which closes the process gap iteration 1 raised.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F-i | srules relies on ownfile folding nothing; ownfile's lib comment still says it takes a lower-cased path | Minor | `scripts/lib/dev-cycle-read.sh:1798-1800`, `scripts/build-loop.sh:663` | High |
| F-ii | read_settings' reason precedence keys on list_entries' message prefix "is not exactly"; `v == none` re-derives the none rule | Minor | `scripts/build-loop.sh:415-421` | High |
| F-iii | Row 616's reason ("the lib cannot call build-loop.sh") argues for placing list_entries in the lib, not for two copies | Informational | `scripts/build-loop.sh:356-377`, `override-log.md:616` | Medium |
| F-iv | Re-read fallback reports a brief failure as a Paths: line reason; PATHS gets a second writer | Informational | `scripts/build-loop.sh:809` | High |
| F-v | check_line comment's global list reads as complete; "set -e applies" overstated | Informational | `scripts/build-loop.sh:759-762` | High |

Rubric mapping: no Structural (🔴) or Coupling (🟡) findings. All five map to 🟢 Consider.

## Overall Assessment

The fix range improves the structure. Iteration 1's Must Address (three copies of the list-line grammar) is resolved within build-loop.sh by a small, well-shaped helper. The case slip in the allowlist is fixed and pinned by a test. The verdict-chain slip is gone, and both deferred triggers now have rows. The remaining findings are about keeping contracts written down where the code relies on them. The most important is F-i. The B1 fix depends on ownfile's body, while ownfile's documented precondition says the opposite. A one-line lib comment closes this. F-ii is the one new piece of coupling the shared helper introduced, and it is cheap to remove or annotate. Nothing needs restructuring.

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line.
- Answered: yes. I covered the three areas the dispatch named: list_entries as the shared grammar and the deferred lib copy (F-ii, F-iii), the re-read fallback (F-iv) and check_line's parent-shell comment (F-v). All six iteration-1 findings' dispositions are confirmed in the table above, and F-i is the residue of F2's disposition.
- Static review only. No probes were run. Behaviour claims rest on the i2 fact-check's executed checks (differential, mutation, forced re-read failure), cited by claim number.
- Out of scope: correctness of the Exit: text (fact-check 7), the floor/allowlist case disagreement in --help (fact-check 5, a text issue), and the security reading of "a failed re-read of an own-files-only brief now verdicts ok" (outcome equals `Paths: none`; flagged for the security critic, not judged here).
