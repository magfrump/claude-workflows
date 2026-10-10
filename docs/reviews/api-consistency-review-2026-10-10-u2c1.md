Commit: eddfd5f9

# API Consistency Review: feat/build-loop-u2c1 (U2c1, iteration 1)

**Scope:** `git diff main...HEAD` (eddfd5f9): scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2c1.md (21 claims; Claims 1 and 2a are cited here and not re-verified)
**Surface reviewed:** `--check`'s verdict, path and deny lines and their WHY texts; `--help`; the `Paths:` grammar against `--settings`' `Self-merge never:` and reader grammars (read_settings, globform); the lib's floor/ownfile contract.

## Baseline Conventions

- **Output lines.** `--check` prints one verdict line per brief (`ok BRIEF TIP TREE` / `refuse BRIEF: WHY` / `skip BRIEF: WHY`), then `path BRIEF S PATH` / `deny BRIEF S PATH: WHY` (scripts/build-loop.sh:103-191). D4 (plan:59) makes this output the body of a review entry, so deny WHYs reach the user verbatim.
- **Deny WHY texts** (nrules, floor) are mostly noun phrases that say what the path *is*: "one of the dev cycle's own files", "the user's constraints doc, which every loop prompt carries", "a symlink, gitlink or other non-file entry on one side (...)" (build-loop.sh:585-599), and "an instruction or prompt file, which sessions load from the checkout", "a dotfile or a path under a dot-directory", "a record later runs read as truth" (dev-cycle-read.sh:1833-1847).
- **Settings-line grammars** (`--settings`, build-loop.sh:11-55; read_settings :369-420): "KEY: V ..." with single spaces; an empty list is spelled with the keyword `none` ("Self-merge never: none", "Reader roots: none"); "KEY:" with nothing after it is malformed ("is not exactly \"Self-merge never: GLOB ...\" with single spaces"); a malformed or duplicate entry names the entry index ("lists entry $i twice"); a malformed never line surfaces at the policy level ("policy review unset: ... so self-merge is off", :414-415).
- **Brief machine lines** (brief_fields, dev-cycle-read.sh:373-409): the first unfenced line of each key wins; a second copy is ignored (Status, Branch, Policy alike).
- **Case.** Denylists fold case (nrules' cycle names, floor, globs); the plan says allowlists do not widen by case.
- **Function/global naming.** A setter function and its output global share a name (open_shared → OPEN_SHARED); refusal reasons go in `X_WHY` globals (CHECKOUT_WHY, FLOOR_WHY, TRUTH_WHY); readers are verb-first or noun-noun (read_settings, reader_settings, brief_fields).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `srules` | function | `nrules`, `truthrule` | `scripts/build-loop.sh:583`, `scripts/lib/dev-cycle-read.sh` truthrule | Consistent: N rules / S rules pair, as the plan names them |
| `paths_read` | function | `read_settings`, `reader_settings`, `brief_fields` | `scripts/build-loop.sh:369`, `scripts/lib/dev-cycle-read.sh` reader_settings, :386 | Minor: noun-verb, where the sibling field reader in the same file is verb-noun (Finding 8) |
| `never_res` | function | `open_shared` (sets OPEN_SHARED), `import_reset` | `scripts/lib/dev-cycle-read.sh` open_shared | Consistent: function named after the global it fills |
| `PATHS`, `NEVER_RES` | global | `NEVER`, `BRIEF`, `OPEN_SHARED` | `scripts/build-loop.sh:367` | Consistent |
| `PATHS_WHY` | global | `CHECKOUT_WHY`, `FLOOR_WHY`, `TRUTH_WHY`, `IMPORT_READER_WHY` | `scripts/build-loop.sh` checkout_gate, `scripts/lib/dev-cycle-read.sh:1824` | Consistent: `X_WHY` |
| deny WHY "a path below the name of one of the dev cycle's own files or the constraints doc" | output text | "one of the dev cycle's own files", "the user's constraints doc, ..." | `scripts/build-loop.sh:597-598` | Consistent: noun phrase |
| deny WHY "a Self-merge never: glob in docs/dev-cycle.md matches it" | output text | floor WHYs, nrules WHYs | `scripts/build-loop.sh:585-599`, `scripts/lib/dev-cycle-read.sh:1833-1847` | Minor: a clause, and names no glob (Finding 4) |
| deny WHY "the brief's Paths: line ... so only its own files land" | output text | read_settings' never WHYs | `scripts/build-loop.sh:393-401` | Consistent: reuses the never line's sub-reasons verbatim |
| deny WHY "neither listed in the brief's Paths: line nor one of its own files" | output text | "not an allowed path form (...)" | `scripts/build-loop.sh:585` | Consistent enough: adjective phrase, like the path-form WHY |
| `Paths:` grammar | brief line | `Self-merge never:`, `Reader roots:` | `scripts/build-loop.sh:25-31, 41-50` | Inconsistent on the empty spelling (Finding 1) and trailing `/` (Finding 6) |

## Findings

#### 1. `Paths:` spells "none" differently from every settings list, and "Paths: none" lists a path named `none`

**Severity:** Minor
**Location:** `scripts/build-loop.sh:614-617` (paths_read; the function continues to :628), `scripts/build-loop.sh:185-188` (--help)
**Move:** 2 (naming against the grain), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Precedent: an empty list is "KEY: none", and "KEY:" alone is malformed, used in `scripts/build-loop.sh:25-27` ("Self-merge never: GLOB ..." (or "...: none")), `scripts/build-loop.sh:46` ("Reader roots: PATH ..." ... or "...: none"), `scripts/build-loop.sh:392-393, 407`

Evidence:
```bash
# scripts/build-loop.sh:617-619
  [[ "$t" != "Paths:" ]] || return 0
  v="${t#Paths: }"
  if [[ "$t" != "Paths: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then PATHS_WHY='is not exactly "Paths: PATH ..." with single spaces'; return 0; fi
```
and the help: `"Paths:" alone or no line lists none` (:187-188).

The same --help documents two list grammars side by side with opposite empty spellings: the settings lists say `none` and refuse a bare "Self-merge never:", while `Paths:` takes the bare key as empty. There is no special case for `none`, so an orchestrator that writes "Paths: none" by analogy passes pathform and gets a one-entry allowlist for a top-level file called `none`. This fails closed (narrower, not wider). Rev 2's grammar (plan D5 context) chose "empty/absent = none", so this is a convention clash, not a bug.

**Recommendation:** Either accept "Paths: none" as the empty list (matching the settings grammars) or refuse `none` as an entry, with the help saying which. A one-line case in the malformed-Paths test would pin it.

#### 2. --help understates the floor's working-doc and review refusals

**Severity:** Minor
**Location:** `scripts/build-loop.sh:174-179` (--help), against `scripts/lib/dev-cycle-read.sh:1842-1843` (floor, :1826-1849)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
# scripts/build-loop.sh:176-178
#                 dot paths, the gate's own code, the user's and the cycle's
#                 records, other briefs' working docs and reviews; not run
```
```bash
# scripts/lib/dev-cycle-read.sh:1842-1843
  elif [[ "$lp" == docs/working/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY="a working file that is not this brief's own (they carry its full stem)"
  elif [[ "$lp" == docs/reviews/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY="a review record (only an added review named STEM.md or NAME-STEM.md lands)"
```

The floor refuses every `docs/working/*` path that is not this brief's own (for example `docs/working/notes.md`, which belongs to no brief) and every review except an *added* own review, so a modified own review is refused too. The test asserts that case (`has "deny $B M docs/reviews/old.md: $REV"`, build-loop-check.bats:1960). "other briefs' working docs and reviews" tells the orchestrator that writes `Paths:` that anything not keyed to another brief may be listed, and then the floor denies it. The fact-check flagged the reviews half in its Claim 4 scope note. The deny WHYs themselves are accurate. Only the help lags them.

**Recommendation:** Say "working docs and reviews that are not this brief's own (an own review only when added)" in place of "other briefs' working docs and reviews".

#### 3. "Compared exactly" holds for `Paths:` only; own files compare lower-cased

**Severity:** Minor
**Location:** `scripts/build-loop.sh:183-187` (--help), `scripts/build-loop.sh:658` (srules, :651-664), `docs/working/plan-build-loop-handoff.md:311`
**Move:** 7 (asymmetry within one allowlist), 3 (documentation)
**Confidence:** High (executed by the fact-check, Claim 2a, FCPROBE 1)
**Legibility-target:** for-author

Evidence:
```bash
# scripts/build-loop.sh:658
  ! ownfile "$3" "$1" "$4" || return 0
```
(`$3` is `${lps[$i]}`, the lower-cased path: `srules "$stem" "$p" "${lps[$i]}" ...`, :815.) Plan:311: "pathform entries compared exactly (an allowlist widens nothing by case)".

The allowlist has two halves, and they fold case differently. `Paths:` entries compare byte for byte (:661). Own files compare lower-cased, so `Docs/Working/Plan-2026-10-01-x.md` lands as an own file (fact-check Claim 2a). The help's "compared exactly" sits in the `Paths:` sentence and is accurate there. But plan:311 states the case rule for "an allowlist" as a whole, and that is false for the own-file half. A consumer reading the plan would expect a case-variant own file to be denied. Whether that matters is a design question the fact-check already escalated. The consistency point is that the contract should say which half folds.

**Recommendation:** Either pass `$2` (the path as stored) to ownfile so the whole allowlist compares exactly, as plan:311 says, or amend plan:311 and the help to "own files compare lower-cased".

#### 4. The never-glob deny WHY names no glob and breaks the noun-phrase pattern

**Severity:** Minor
**Location:** `scripts/build-loop.sh:655-657` (srules, :651-664)
**Move:** 4 (error consistency)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```bash
# scripts/build-loop.sh:656
    [[ ! "$3" =~ $re ]] || { DENY="a Self-merge never: glob in docs/dev-cycle.md matches it"; return 0; }
```
Compare the sibling reasons, which say what the path is ("one of the dev cycle's own files", :597; "a record later runs read as truth", lib :1836), and the settings reader, which names the offending entry ("lists entry $i, which is not an allowed glob form", :401).

Under D4 (plan:58-59) a refused self-merge falls to review "with the refusal quoted in the entry", so this text is what the user reads. With several globs on the line, it doesn't say which one fired. The user has to reconstruct the match by hand, even though the regex loop has the matching index in hand. It is also the only S-rule deny written as a clause with "it" as object ("... matches it") rather than a description of the path. Every glob is globform-safe (letters, digits, `. _ - / * ?`), so printing it needs no scrubbing beyond what the output already gets.

**Recommendation:** Name the glob as written, e.g. `DENY="under the Self-merge never: glob $g of docs/dev-cycle.md"`. That means keeping NEVER's entries parallel to NEVER_RES so the index can be mapped back.

#### 5. A malformed `Paths:` line surfaces only as repeated per-path denies; the plan's brief-line note still says "no self-merge"

**Severity:** Minor
**Location:** `scripts/build-loop.sh:659` (srules), `scripts/build-loop.sh:619-627` (paths_read), `docs/working/plan-build-loop-handoff.md:238`
**Move:** 7 (asymmetry with the settings grammar), 3 (documentation drift)
**Confidence:** Medium (the per-path behaviour is deliberate per plan:311; the asymmetry is the finding)
**Legibility-target:** for-author

Evidence:
```bash
# scripts/build-loop.sh:659
  [[ -z "$PATHS_WHY" ]] || { DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"; return 0; }
```
Plan:238: "`Paths: P…` (a malformed or duplicate entry means no self-merge);". Settings precedent (build-loop.sh:414-415): a malformed never line yields `policy review unset: ... so self-merge is off`, a single brief-level line.

A malformed settings list is reported once, at the policy level. A malformed `Paths:` line leaves `--status` printing POLICY `self-merge`, and `--check` repeats the same Paths reason on every non-own deny line. For a D4 entry that quotes the output, N copies of one brief-level reason read as N path problems. Plan:238 (fact-check Claim 1, Stale) still promises the old consequence, and plan:311 records the new one. The behaviour fails closed and the change is deliberate. The issue is that two places describe the contract differently, and the output's shape doesn't say the reason applies to the whole brief.

**Recommendation:** Update plan:238 to match plan:311 (the fact-check's fix). Optionally, have the verdict line carry the Paths reason once (for example, the K of N refusal naming it) so the per-path lines can stay short. That option is a U3/U4 entry-format choice and can wait.

#### 6. A trailing `/` means opposite things in the two path lists of one help page

**Severity:** Informational
**Location:** `scripts/build-loop.sh:179-188` (--help), `scripts/build-loop.sh:629-631, 660-662`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
# scripts/build-loop.sh:629-631
# NEVER's globs as regexes for a lower-cased path (a denylist, so case folds):
# * and ? match within one part, and a glob matches the path or any directory
# above it (a trailing / changes nothing). Set once, after read_settings.
```
```bash
# scripts/build-loop.sh:661
    [[ "$2" != "$e" && ( "$e" != */ || "$2" != "$e"* ) ]] || return 0
```

`Self-merge never: docs/a` covers `docs/a/x`. `Paths: docs/a` covers only a file named `docs/a`, and `docs/a/x` gets the generic "neither listed in the brief's Paths: line nor one of its own files", with no hint that `docs/a/` was meant. Both rules are documented. The asymmetry is defensible (a denylist reads wide, an allowlist narrow) and fails closed. It is noted because an orchestrator writing both lines will reach for one convention.

**Recommendation:** None required. If the deny text is revisited (row 472's U3 pass), consider adding "(a directory needs a trailing /)" when the path lies below a listed non-`/` entry.

#### 7. --check can now exit 1 after printing verdict lines, which the Exit: contract does not list

**Severity:** Informational
**Location:** `scripts/build-loop.sh:197-200` (Exit: in --help), `scripts/build-loop.sh:836-843`
**Move:** 3 (consumer contract)
**Confidence:** High on the mechanism (fact-check Claim 12, executed analog); Low on reachability
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
# scripts/build-loop.sh:197-200
# Exit: 0 every line printed (or help), and for --check every verdict line ok;
# 2 any --check verdict line or the state gate not ok; 1 bad usage, not a git
# repo, no perl or lib/dev-cycle-read.sh, a failed mktemp (--check; no line
# printed), or no default branch found by name.
```
```bash
# scripts/build-loop.sh:838-841
      # In this shell, not $(...): the floor's need_root exit ends the run, and
      # check_line's import_reset is what keeps one brief's walk from the next.
      check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"
      [[ "$(head -c 3 "$GATE_TMP/line")" == "ok " ]] || fails=1
```

With check_line in the parent shell under `set -euo pipefail` (:202), need_root's `exit 1` (lib :160-164), or any unguarded failure, ends `--check` with status 1. Earlier briefs' lines are already printed, and the current brief's line is lost when the EXIT trap removes GATE_TMP. Before this change, the same fault gave a non-ok line and exit 2. The Exit: line keeps 1 for start-up failures with "no line printed". need_root cannot fire in normal operation (ROOT_REAL is set after `cd "$ROOT"`, :314-316), and the fact-check found no unguarded failing statement, so this is a contract-completeness note, not a live bug. A caller that treats exit 1 as "bad usage" would still not merge, so it fails closed.

**Recommendation:** Add to Exit: "or (--check) an internal fault mid-run, after which no further line prints".

#### 8. `paths_read` inverts the sibling reader's verb-noun order

**Severity:** Informational
**Location:** `scripts/build-loop.sh:613`
**Move:** 2 (naming)
**Confidence:** High
**Legibility-target:** for-author

Precedent: verb-first or noun-noun field readers, used in `scripts/build-loop.sh:369` (`read_settings`), `scripts/lib/dev-cycle-read.sh:386` (`brief_fields`), `scripts/lib/dev-cycle-read.sh` (`reader_settings`)

Evidence: `paths_read() {` (:613). No other function in scripts/build-loop.sh, scripts/dev-cycle.sh or scripts/lib/dev-cycle-read.sh ends in `_read`.

This is an internal function, not a consumer surface. `read_paths` (or `brief_paths`, beside `brief_fields`) would match its neighbours.

**Recommendation:** Rename on the next touch. Not worth a fix pass alone.

## What Looks Good

- **The verdict/path/deny line shapes are unchanged.** S-rule refusals reuse `deny BRIEF S PATH: WHY` and the existing "K of N changed paths refused" verdict, and `head -c 3 == "ok "` keeps the old ok test. A consumer that parsed U2b2's output parses U2c1's.
- **The Paths: sub-reasons reuse read_settings' wording verbatim** ("is not exactly \"... PATH ...\" with single spaces", "lists entry $i, which is not an allowed path form", "lists entry $i twice"). The same check gets the same words across the settings and the brief.
- **paths_read mirrors the never reader's parser** (single-space regex, `read -ra` over `<<<` rather than a bare expansion, `${e%/}` for pathform and dedup), so the two grammars differ only where the help says they do (Findings 1 and 6).
- **First-line-wins for `Paths:`** matches brief_fields' rule for Status, Branch and Policy, rather than importing the settings' duplicate-is-malformed rule. That is consistent with the brief-line family.
- **`PATHS_WHY`, `NEVER_RES`/`never_res`, `srules`** follow the X_WHY, function-named-after-global and N/S-rules conventions.
- **The new N rule (row 523) applies under both policies**, as the help's "The N rules, under either policy" promises. Its WHY is a noun phrase in the existing family.
- **The lib's floor/ownfile contract is unchanged.** Header items 3 and 5 now name build-loop.sh's actual duties (diff-tree caller, floor only on N-passed paths), and FLOOR_WHY's comment names its real reader (fact-check Claims 14, 15).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `Paths:` empty spelling differs from settings' `none`; "Paths: none" lists a file `none` | Minor | `scripts/build-loop.sh:614-617` | High |
| 2 | --help says the floor refuses "other briefs'" working docs/reviews; it refuses any non-own one | Minor | `scripts/build-loop.sh:176-178` | High |
| 3 | Own files compare lower-cased; plan:311 says the allowlist compares exactly | Minor | `scripts/build-loop.sh:658` | High |
| 4 | Never-glob deny WHY names no glob; clause, not noun phrase | Minor | `scripts/build-loop.sh:656` | Medium |
| 5 | Malformed Paths: only as repeated per-path denies; plan:238 still "no self-merge" | Minor | `scripts/build-loop.sh:659`, plan:238 | Medium |
| 6 | Trailing `/` opposite meaning in never vs Paths: | Informational | `scripts/build-loop.sh:629-631, 661` | High |
| 7 | --check may exit 1 after printing lines; Exit: does not list it | Informational | `scripts/build-loop.sh:197-200, 838-841` | High |
| 8 | `paths_read` vs `read_settings` order | Informational | `scripts/build-loop.sh:613` | High |

## Overall Assessment

U2c1 extends `--check`'s surface consistently. Output line shapes, verdict semantics and the X_WHY / N-rules naming are preserved, and the Paths: reader reuses the never reader's parser and wording. No finding is breaking, and every one fails closed. The issues are contract wording. Three are about what --help and the plan say against what the code does: the floor's working-doc scope (2), case folding of own files (3) and plan:238 (5). Two are about consumer legibility of the texts D4 will quote: the unnamed glob (4) and the `none` spelling (1). All are fixable in place with doc edits plus, at most, a one-line DENY change.

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line.
- Answered: yes. Saved at docs/reviews/api-consistency-review-2026-10-10-u2c1.md with `Commit: eddfd5f9` at the top. 8 findings, each with Severity, Location path:line, verbatim Evidence, Confidence and Legibility-target.
- Out of scope / not re-raised: row 472 (FLOOR_WHY as words, U3), row 526 (S-rule flags under review, U3/U4), and the U2c2 walk-side rows. Behaviour was taken from the fact-check report and not re-executed.
- Escalate: none beyond the fact-check's Claim 2a design question, which Finding 3 restates as a contract choice.
