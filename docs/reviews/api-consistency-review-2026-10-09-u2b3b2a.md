Commit: 55490d15

# API Consistency Review — feat/build-loop-u2b3b2a (U2b3b2a, iteration 1)

**Scope:** `git diff main...HEAD` (55490d15): scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats
**Date:** 2026-10-09
**Based on:** shared brief u2b3b2a-i1/shared.md; the parallel code-fact-check was not available to this pass.

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

## Baseline Conventions

- **Function contracts are documented in a leading comment** of the form `name ARGS: what it does ... It returns 1 when ...` (import_work, import_readers, import_targets, capped_read, md_ls). Outputs of the parser family are newline-separated text; a walk strips a single `/N` work trailer with `import_work`.
- **Parser-family naming:** helpers that serve the import walks carry the `import_` prefix: `import_reset` (:732), `import_home` (:983), `import_readers_key` (:1023), `import_readers` (:1027), `import_targets` (:1080), `import_work` (:1130). The walks themselves are `imported_names` and `main_imports`; other lib helpers are subject_object nouns (`main_file`, `checkout_md`, `tree_starts`, `main_checkout`, `capped_read`).
- **Caller knobs** are upper-case `IMPORT_*` globals read with `${X:-}`: `IMPORT_LEFT`, `IMPORT_WORK_LEFT`, `IMPORT_OUT_MAX`, `IMPORT_WORK_MAX`, `IMPORT_READER_ROOTS/HOMES/WHY`. `IMPORT_WORK_LEFT` is the switch that turns the trailer on: unset, `import_targets` prints none.
- **Memoized reader-set globals** (`IMPORT_ROOTS`, `IMPORT_HOMES`) are newline-separated with the trailing newline stripped (`IMPORT_ROOTS="${IMPORT_ROOTS%$'\n'}"`, :1072-1073), cleared together on a recompute and memoized under `IMPORT_READERS_DONE`.
- **Lib surface inventory:** test/scripts/dev-cycle.bats:1101-1118 ("sourcing the reader lib defines its functions...") lists the lib's functions and globals by name, and is the codebase's record of what the lib exports.
- **Error convention:** return 1, no stderr; walks turn any helper failure into `IMPORTED=error`/`IMPORTED_MAIN=error`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `outside_targets` | function | `import_targets`, `import_work`, `import_readers` | scripts/lib/dev-cycle-read.sh:983-1130 | Minor drift: a parser-family helper without the `import_` prefix (F3) |
| `file_targets` | function | `import_targets`, `capped_read`, `main_file` | scripts/lib/dev-cycle-read.sh:536, :1080, :1162 | Minor drift: same as above; "file" is generic next to `main_file`/`rawfile`/`ownfile` (F3) |
| `IMPORT_WHOLE` | caller knob (global/env) | `IMPORT_LEFT`, `IMPORT_WORK_LEFT`, `IMPORT_READER_WHY` | scripts/lib/dev-cycle-read.sh:776-790, :1019 | Consistent: `IMPORT_*` prefix, read as `${IMPORT_WHOLE:-}`, set-or-empty switch like `IMPORT_WORK_LEFT` |
| `IMPORT_DOTNEST` | memoized global | `IMPORT_ROOTS`, `IMPORT_HOMES` | scripts/lib/dev-cycle-read.sh:1019, :1034, :1072-1073 | Consistent name and lifecycle (declared, cleared and set beside its siblings); format differs (F4) |
| `IT_DOTNEST`, `IT_WHOLE` | awk env | `IT_ROOTS`, `IT_HOMES`, `IT_LEFT`, `IT_WORK` | scripts/lib/dev-cycle-read.sh:947-956, :1106-1107 | Consistent |
| `//PATH` output line | output format | `/N` work trailer, repo-relative lines | scripts/lib/dev-cycle-read.sh:1126-1135 | Consistent; disjoint from both (a repo name never starts with `/`, the trailer is `/` + digits only) |

## Findings

#### F1. file_targets' output contract depends on the kind of FILE: an absolute FILE fails without IMPORT_WORK_LEFT and ignores DIR/DIRS

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:1109-1125`
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** High

Evidence (verbatim):
```
  a="$(capped_read < "$1" | import_targets "${d:-/}")" && import_work a w || return 1
  ...
  printf '%s\n' ${a:+"$a"} ${b:+"$b"} "/$w"
}
# file_targets FILE DIR [DIRS...]: import_targets over FILE as the file system
# holds it, for both walks: a repo path (DIR and DIRS as import_targets takes
# them), or an absolute one through outside_targets.
file_targets() { if [[ "$1" == /* ]]; then outside_targets "$1"; else capped_read < "$1" | import_targets "${@:2}"; fi; }
```

`import_targets` prints the work trailer only when `IMPORT_WORK_LEFT` is set (header :776-790; awk `trail = (ENVIRON["IT_WORK"] != "")`). `outside_targets` always runs `import_work` on its inner call, so with `IMPORT_WORK_LEFT` unset or empty it returns 1. Probe (fixture repo under mktemp): `file_targets r.md ""` printed names and rc=0; `file_targets "$T/out/o.md" ignored` printed nothing and rc=1; with `IMPORT_WORK_LEFT=100000` it printed names plus `/1343` and rc=0. So one function has two contracts: repo FILE gives "trailer iff IMPORT_WORK_LEFT", absolute FILE gives "trailer always, IMPORT_WORK_LEFT required". It also silently drops DIR and DIRS for an absolute FILE (prompt_bases' `xs` included). Neither is in either header. Both current callers (the two walks, :1237 and :1314) set IMPORT_WORK_LEFT and pass no `xs` for outside files, so nothing breaks today. A later caller (U2b3b2b's outside seeds, or a test that calls `file_targets` the way the existing tests call `import_targets` with no budget) would hit a bare rc=1 that reads like a parse failure.

**Recommendation:** State it in the headers ("outside_targets: needs IMPORT_WORK_LEFT; always prints one trailer; DIR/DIRS ignored for an absolute FILE"), or make `outside_targets` match `import_targets` and print/strip the trailer only when `IMPORT_WORK_LEFT` is set.

#### F2. The lib's sourcing inventory test was not extended for the new names

**Severity:** Minor
**Location:** `test/scripts/dev-cycle.bats:1110,1114`
**Move:** 3 (test drift)
**Confidence:** High

Evidence (verbatim, :1110 and :1114):
```
... main_checkout lower_all capped_read import_work import_readers import_readers_key; do
... IMPORT_ROOTS IMPORT_HOMES IMPORT_READERS_DONE IMPORT_READERS_KEY IMPORT_READER_ROOTS IMPORT_READER_HOMES BRIEF BRIEF_ODD; do declare -p "$v" ...
```

This test is the lib's list of what sourcing defines. Every earlier unit added its new walk helpers and memo globals to it (`import_readers`, `import_readers_key`, `IMPORT_READERS_KEY`, `IMPORT_READER_ROOTS/HOMES`). This diff adds two functions both walks now depend on (`outside_targets`, `file_targets`) and a global initialized at source time beside IMPORT_ROOTS (`IMPORT_DOTNEST`, :1019), but adds none of them to the list. If either function were renamed or lost, the walks would still fail closed (rc=1 → `error`), so nothing silent happens. The inventory just falls behind.

**Recommendation:** Add `outside_targets file_targets` to the function list and `IMPORT_DOTNEST` to the variable list.

#### F3. New parser-family helpers drop the `import_` prefix

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1115, 1125`
**Move:** 2 (naming)
**Confidence:** Medium

Precedent: `import_<noun>` for helpers serving the walks, used in scripts/lib/dev-cycle-read.sh:732 (`import_reset`), :983 (`import_home`), :1023 (`import_readers_key`), :1027 (`import_readers`), :1080 (`import_targets`), :1130 (`import_work`)

`outside_targets` and `file_targets` sit between `import_targets` and `import_work` and are wrappers of the former. Every other function in that block has the prefix. `file_targets` is also a generic name in a lib that already has `rawfile`, `main_file` and `ownfile` with unrelated meanings. A reader grepping `import_` to find the parser's surface (which the inventory test above effectively does) misses both. The cost is cognitive only.

**Recommendation:** Consider `import_outside` / `import_file` (or `import_targets_outside` / `import_targets_file`). Keeping the current names is acceptable if the headers say they belong to the import_targets family.

#### F4. IMPORT_DOTNEST is described under "Each is newline-separated, ROOT_REAL ... first, ... as written and as realpath -m reads it" but has a different shape and keeps a trailing newline

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:995-998, 1074-1078`
**Move:** 7 (asymmetry), 8 (format contract)
**Confidence:** High

Evidence (verbatim):
```
# IMPORT_READER_HOMES; IMPORT_DOTNEST the parser's dotnest pairs over IMPORT_ROOTS. Each is newline-separated, ROOT_REAL or this process's
# home first, and lists every entry as written and as realpath -m reads it,
# once; ...
  printf -v IMPORT_ROOTS '%s\n' "${rs_ro[@]}"; IMPORT_ROOTS="${IMPORT_ROOTS%$'\n'}"
  ...
    ... || IMPORT_DOTNEST+="$((i + 1)) $((n + 1))"$'\n'
```

The inserted clause puts IMPORT_DOTNEST inside the scope of "Each is ... ROOT_REAL or this process's home first, and lists every entry as written and as realpath -m reads it". That sentence describes path lists, and IMPORT_DOTNEST holds "I J" index pairs. Its siblings also strip their trailing newline and IMPORT_DOTNEST keeps one. The awk consumer tolerates this (`split(dn[i], ab, " ") == 2` skips the empty last field), so nothing breaks. The format ("I J" 1-based indices into IMPORT_ROOTS, newline-terminated) is written down only in the awk BEGIN comment (:951) and at the build site, not in import_readers' header, which is the documented contract.

**Recommendation:** Move IMPORT_DOTNEST into its own sentence after "once;" ("IMPORT_DOTNEST: one `I J` line per pair, 1-based into IMPORT_ROOTS, J nested in I below a dot component"). Optionally strip the trailing newline to match the siblings.

#### F5. Direct import_targets calls changed behavior (ROOT_REAL=/ now fails; outside a walk it forks git and reads the worktree registry)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1080-1085`; test/scripts/build-loop-check.bats:631-641
**Move:** 3, 6 (versioning impact)
**Confidence:** High

Evidence (verbatim):
```
-@test "the parser keeps every path below ROOT_REAL /, and returns 1 for an empty ROOT_REAL (U2a3b L2-i2 test-strategy)" {
+  import_readers || return 1
```

This is a semantic change to an existing function, and the earlier contract was itself tested ("keeps every path below ROOT_REAL /"). A direct call now needs a git repository (`git worktree list`), refuses ROOT_REAL=/, and returns the full reader set rather than ROOT_REAL alone. A grep of scripts/ and test/ found no production caller of `import_targets` outside the two walks (build-loop.sh and dev-cycle.sh reach it only through `isimported`/`truthwalk`). The tests that call it directly all run inside a fixture repo, so the change breaks nothing in the tree. The commit message states it ("a ROOT_REAL of / now fails a direct call too"), and the header (:775-778, :826-827) was updated. Recorded only so the convention is deliberate: the parser's contract is now "a call inside a repository with valid reader settings".

**Recommendation:** None required.

#### F6. IMPORTED/IMPORTED_MAIN now mix two namespaces; isimported's "path $2" can match a `//` line

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1242, 1349, 1362-1375`
**Move:** 8 (nullability/format of a shared result)
**Confidence:** Medium

Evidence (verbatim): `lp="$(lower "$out")" || { IMPORTED=error; return 1; }; IMPORTED+="$lp"$'\n'` (:1242). The cached lists now hold `//abs/path` lines next to repo-relative ones. `isimported tree //etc/x.md` would answer imported. Every current caller passes a repo-relative path (truthwalk, floor, --check-fix), and a hit only adds a false positive, which the superset principle accepts. isimported's header still says only "Whether path $2 (any case) is imported".

**Recommendation:** Optionally note in isimported's header (or at :718-728) that the cached lists also carry second-channel `//` names and that $2 is repo-relative.

## What Looks Good

- The second channel (`//` + absolute path) keeps the existing output contract intact for every current consumer. A repo-relative name never starts with `/`, and the `/N` trailer is `/` + digits only, so `import_work`'s strip (`${iw_o##*/}` with `"$iw_o" == *$'\n'"/$iw_w"`) cannot mistake one for the other. Its comment was updated to say so.
- `IMPORT_WHOLE` and `IT_WHOLE`/`IT_DOTNEST` follow the established knob conventions: the `IMPORT_*`/`IT_*` prefixes, `${X:-}` reads, values passed through the environment and not `awk -v`.
- `IMPORT_DOTNEST` follows its siblings' lifecycle exactly: declared at :1019, cleared at :1034 with IMPORT_ROOTS/HOMES, rebuilt under the same memo key, so a refusal leaves it empty along with the others.
- Refusal now has one state (`import_readers || return 1`), so a refusal always looks the same to every caller. This matches how the walks already treated it (:1219, :1271).
- Both walks reach the checkout file read through one shared function (`file_targets`). This removes a duplicated pipeline, and the main walk's `100644|100755` arm keeps its blob-reading form.
- The new bats tests use the existing harness vocabulary (`imps`, `want`, `commit_all`) and naming style ("... (U2b3b2a)").

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | file_targets/outside_targets: an absolute FILE needs IMPORT_WORK_LEFT (else rc=1) and ignores DIR/DIRS; undocumented | Inconsistent | `scripts/lib/dev-cycle-read.sh:1109-1125` | High |
| F2 | Sourcing inventory test lacks outside_targets, file_targets, IMPORT_DOTNEST | Minor | `test/scripts/dev-cycle.bats:1110,1114` | High |
| F3 | New parser-family helpers drop the `import_` prefix | Minor | `scripts/lib/dev-cycle-read.sh:1115,1125` | Medium |
| F4 | IMPORT_DOTNEST described under the path-list "Each ..." sentence; keeps a trailing newline unlike siblings | Minor | `scripts/lib/dev-cycle-read.sh:995-998,1074-1078` | High |
| F5 | Direct import_targets: ROOT_REAL=/ now fails; needs a repo; no external caller affected | Informational | `scripts/lib/dev-cycle-read.sh:1080-1085` | High |
| F6 | IMPORTED lists mix `//` and repo names; isimported doc unchanged | Informational | `scripts/lib/dev-cycle-read.sh:1242,1349,1362-1375` | Medium |

## Overall Assessment

The change fits the lib's conventions. The new output channel is disjoint from both existing line kinds, the knobs and globals follow the established `IMPORT_*` patterns, and no consumer in scripts/ or the bats suites breaks. The one substantive inconsistency is F1: `file_targets` has two contracts, and the trailer/IMPORT_WORK_LEFT dependency appears in no header. It is harmless with today's two callers but is the first thing U2b3b2b's outside seeds will call. F2 to F4 are documentation and inventory gaps that can be fixed in place in a few lines.

## Goal-Alignment Note

The goal is to land U2b3b2a through its review-fix loop with the walks' superset/fail-closed property intact. None of these findings is a false negative (a path imported but reported "not imported"). Every API gap here makes a misuse fail closed (rc=1 → `error`) or adds false positives. The finding that bears most on the next unit (U2b3b2b, outside seeds) is F1: those seeds will most likely enter through `outside_targets`/`file_targets`, so its contract should be written down before they are built. F2 to F6 can be fixed in this unit's fix pass or deferred without risk to the goal.
