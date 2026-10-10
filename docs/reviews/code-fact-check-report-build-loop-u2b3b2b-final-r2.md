Commit: 8f99fcaf

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b3b2b (branch feat/build-loop-u2b3b2b)
**Scope:** `git diff main...HEAD -- scripts test` (scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, test/lib/build-loop-fixtures.bash), the U2b3b2b and U2b3b2c plan bullets in docs/working/plan-build-loop-handoff.md, and the three branch commit messages (1c820663, 39f64d62, 8f99fcaf). Final confirming pass, replicate 2 of 3.
**Checked:** 2026-10-09 (probes ran 2026-10-10T03:36Z to 03:41Z UTC)
**Total claims checked:** 42
**Summary:** 32 verified, 4 mostly accurate, 2 stale, 2 incorrect, 2 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. Its five entries are all "a specific measured value quoted from an artifact set that does not contain it" (test counts, corpus statistics). The test counts, line counts and seed count claimed here were recomputed and match (Claims 34, 35, 10). No claim matches a logged pattern. This replicate writes no log entry because the dispatch allows only this report file, and no Incorrect verdict below is a fabricated symbol.

Execution logs are kept outside the repo (the dispatch allows only this report file), in `/tmp/claude-1000/-workspace/7705a73b-d526-48c8-9948-70a1335d5801/scratchpad/u2b3b2b-final/ffc2/` (abbreviated `$L` below):
- `$L/suites.ts`, `$L/suite-*.txt`: the five suites at HEAD. Command `TMPDIR=$(mktemp -d /tmp/u2b3b2b-ffc2-ts-XXXX) bats <file>`, cwd the worktree, started 2026-10-10T03:36:43Z, every exit 0.
- `$L/redbase.sh` → `$L/redbase.out`: the branch's tests run against main's lib (with 1c820663's tests) and against 39f64d62's lib (with HEAD's tests), in temp copies. Command `bash $L/redbase.sh`, cwd `$L`, 2026-10-10T03:37:12Z, exit 0 (the tests inside it are red, as intended).
- `$L/timing.sh` → `$L/timing.out`: read-only timing of both walks over this worktree, HEAD lib vs main lib, 2 rounds. 2026-10-10T03:38:27Z, exit 0. Load average 2.13 at start.
- `$L/samenames.sh` → `$L/samenames.out`: both walks' sorted name lists, 39f64d62 lib vs HEAD lib. 2026-10-10T03:38:54Z, exit 0.
- `$L/probe.sh` → `$L/probe.out`: behaviour probes P1 to P8 in a throwaway repo under `/tmp/u2b3b2b-ffc2-*`. Run right after samenames, exit 0.
- `$L/probe2.sh` → `$L/probe2.out`: the byte-skip vs whole-path prompt probe. 2026-10-10T03:41:00Z, exit 0.

---

## Claim 1: "(1) each config dir … gives its instruction-named files (f), `rules/**.md` (f), `{commands,agents,output-styles,skills}/**.md` and `plugins/cache/**.md` (p)"

**Location:** `docs/working/plan-build-loop-handoff.md:306`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** plan reader (next unit's builder)
**Scope:** Covers which plugin `.md` files the config-dir seeds include. Does not establish the rest of seed source (1), which matches the code.

The plan's seed list names the whole `plugins/cache/**.md` tree. The code reads only the install paths that `installed_plugins.json` lists. It falls back to the whole cache only when python3 cannot parse that JSON:

```bash
# scripts/lib/dev-cycle-read.sh:1279-1286
  if [[ ${#pj[@]} -gt 0 ]]; then
    if nul_list fl python3 -I -c 'import json, sys
for f in sys.argv[1:]:
    for v in json.load(open(f))["plugins"].values():
        for e in v: sys.stdout.write(e["installPath"] + "\0")' "${pj[@]}" 2>/dev/null; then
      for d in "${fl[@]}"; do [[ "$d" != /* || ! -d "$d" ]] || pr+=("$d"); done
    else for d in "${pj[@]}"; do [[ ! -d "${d%/*}/cache" ]] || pr+=("${d%/*}/cache"); done; fi
  fi
```

The branch's own test asserts that an uninstalled cached version is *not* read (`for f in h n o; do want "docs/$f.md" -; done`, `test/scripts/build-loop-check.bats:703`, where `o` is the uninstalled `$pc/0`). Later in the same bullet the plan says "every installed version", which is right. The "(1)" list was written "before code" and was never updated. Every branch commit already reads installed versions only (1c820663's message: "installed versions from installed_plugins.json, the whole cache when python3 cannot read it").

**Evidence:** `docs/working/plan-build-loop-handoff.md:306`, `scripts/lib/dev-cycle-read.sh:1277-1288`, `test/scripts/build-loop-check.bats:688-710`

---

## Claim 2: "(3) C1: each other root present here, real path deduplicated, a root nested in another listed one skipped and ROOT_REAL's own files dropped, gives every start file `isstart` names below it"

**Location:** `docs/working/plan-build-loop-handoff.md:306`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** plan reader
**Scope:** Covers the C1 root-selection rule. Does not establish the byte skip (Claim 21).

The rule as coded has one more case than the plan states. A root nested below ROOT_REAL is listed by itself, not skipped:

```bash
# scripts/lib/dev-cycle-read.sh:1318-1320
    # A root below another is listed with it, but one below ROOT_REAL (whose files that listing drops) by itself.
    in=""; [[ "$r" == "$ROOT_REAL"/* ]] || for q in "${cr[@]}"; do [[ "$r" != "$q"/* ]] || in=1; done
    [[ -z "$in" ]] || continue
```

A precise version would say "a root nested in another listed one skipped, unless it lies below ROOT_REAL". The plan's "isstart names below it" also needs "by the whole lower-cased path" (Claims 19, 28).

**Evidence:** `docs/working/plan-build-loop-handoff.md:306`, `scripts/lib/dev-cycle-read.sh:1313-1323`

---

## Claim 3: "U2b3b2c … an import a start in another root reaches through a file that root holds with other bytes, or alone, is read from ROOT_REAL's or main's copy"

**Location:** `docs/working/plan-build-loop-handoff.md:307`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** plan reader
**Scope:** Covers the gap description and the matching references in the lib headers. Does not establish the "6,720 seeds" figure (Claim 37) or the proposed fix's cost.

A C1 seed is read through `import_outside`, and the names it yields are repo-relative. The walks then read those names from ROOT_REAL's checkout (`imported_names`, `[[ -f "$p" … ]] && inrepo_here "$p"`, `:1472`) or from main's blob (`main_imports`, `:1587-1590`), never from the other root. Both lib headers route this gap to U2b3b2c: `:750-752` and `:1245-1247` ("Not covered (routed to U2b3b2c)").

**Evidence:** `scripts/lib/dev-cycle-read.sh:750-752`, `:1245-1247`, `:1468-1473`, `:1582-1591`

---

## Claim 4: "Both walks also read the repository's worktree registry (import_readers) and, through outside_seeds, the config dirs (each reader home's .claude, CLAUDE_CONFIG_DIR, IMPORT_MANAGED_DIR), the roots' ancestors and the other roots' file trees (find, grep, sha1sum, python3 on installed_plugins.json)"

**Location:** `scripts/lib/dev-cycle-read.sh:42-46`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib caller
**Scope:** Covers the input sources outside_seeds reads and the tools it runs. Does not establish that the list is exhaustive for tools (realpath, xargs, tr, sh also run).

`outside_seeds` builds `cf` from `IMPORT_HOMES` (`"${d%/}/.claude"`), `CLAUDE_CONFIG_DIR` and `IMPORT_MANAGED_DIR` (`:1263-1264`). It walks each root's ancestors (`:1265-1272`), lists other roots with `root_starts` (`find -P`, `:1213`), greps through `with_at` (`:1224`), hashes with `sha1sum` (`:1340`), and runs python3 on `installed_plugins.json` (`:1280`). Both walks call it (`:1452`, `:1533`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:42-46`, `:1258-1344`, `:1452`, `:1533`

---

## Claim 5: Contract item 4: "…or CLAUDE_CONFIG_DIR or IMPORT_MANAGED_DIR (outside_seeds reads them): neither walk's cache key holds them"

**Location:** `scripts/lib/dev-cycle-read.sh:68-74`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** gate caller
**Scope:** Covers the two cache keys' contents. Does not establish that every caller resets after changing those variables (U2c owns the floor caller).

```bash
# scripts/lib/dev-cycle-read.sh:1440
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]] && { [[ "$IMPORTED" != error ]]; return; }
# scripts/lib/dev-cycle-read.sh:1497
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
```

Neither key holds `CLAUDE_CONFIG_DIR` or `IMPORT_MANAGED_DIR`. `import_readers_key` (`:1068`) does not hold them either. outside_seeds reads both (`:1261`, `:1264`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:68-74`, `:1068-1069`, `:1440`, `:1497`

---

## Claim 6: Contract item 8: "Pass truthrule, isstart, ownfile, prompt_dir and prompt_bases a lower-cased path (… the walks lower first …)"

**Location:** `scripts/lib/dev-cycle-read.sh:86-89`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers the new call sites in outside_seeds and the two walks' seed loops. Does not re-check pre-existing call sites.

Every new `isstart` call gets a `lower_all` output: `isstart "${lo[i]}"` at `:1299` (with `lo` from `lower_all` at `:1298`), and at `:1333` and `:1337` (with `lo` from `:1329`). Prompt seeds pass `prompt_bases` a lowered LP: `pdir[$p]="$(lower "$p")"` at `:1455` and `:1536`, consumed by `prompt_bases xs "${pdir[$f]}" "$f"` at `:1460` and `:1542`. The test's upper-case `.CLAUDE` prompt passes (`want sub/docs/up.md imported`, `test/scripts/build-loop-check.bats:739`; suite exit 0, `$L/suite-build-loop-check.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1298-1299`, `:1329-1337`, `:1455`, `:1536`

---

## Claim 7: "Both walks also start at outside_seeds' files …; the tree walk after the checkout's starts, the main walk in phase 2"

**Location:** `scripts/lib/dev-cycle-read.sh:744-749`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers queue placement. Does not establish K5 observably; the plan itself notes "no observable test".

```bash
# scripts/lib/dev-cycle-read.sh:1451-1456
  # The outside starts, after the checkout's, admitted as a // name is.
  outside_seeds sd || return 1
  for f in "${sd[@]}"; do
    p="${f:1}"; outside_ok "$p" && [[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue
    seen+="$p"$'\n'; queue+=("$p"); [[ "$f" != p* ]] || pdir[$p]="$(lower "$p")" || return 1
  done
```

In `main_imports` the seeds go onto `tq` (`seen[$p]=1; tq+=("$p")`, `:1536`), and `tq` joins `queue` only once main's walk is done (`:1541`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:744-749`, `:1451-1456`, `:1532-1541`

---

## Claim 8: "Named exceptions: a home or root this container cannot see …; an import a start in another root reaches there through a file that root holds with other bytes or alone (routed to U2b3b2c); a symlinked directory in another root (A5); and a C1 start whose bytes match ROOT_REAL's in a checkout that is not clean"

**Location:** `scripts/lib/dev-cycle-read.sh:749-754`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** gate reviewer
**Scope:** Covers whether each named exception exists and whether the list is complete for the byte skip. Does not establish exceptions outside outside_seeds.

Each named exception holds. A further byte-skip gap is missing from the list, and it occurs even in a clean checkout. A C1 file that is a prompt by its whole path (its root lies under another root's `.claude/skills/`) is skipped when its bytes match ROOT_REAL's copy at the inner path. ROOT_REAL's copy is not a prompt there, so it is not read against prompt_bases. Executed in `$L/probe2.out` (Claim 21 has the details): with equal bytes `name.md: - sub/name.md: -`; with different bytes `name.md: imported sub/name.md: imported`. A precise list would add "a C1 prompt (by its whole path) whose bytes match a ROOT_REAL copy that is not a prompt at its inner path".

**Evidence:** `scripts/lib/dev-cycle-read.sh:749-754`, `:1332-1338`; `$L/probe2.sh`, `$L/probe2.out` (cwd `$L`, exit 0, 2026-10-10T03:41:00Z)

---

## Claim 9: "Any seed listing find, grep or sha1sum cannot complete fails the walk, so an unreadable directory in any registered worktree, or a link loop under a config dir's trees, fails every walk"

**Location:** `scripts/lib/dev-cycle-read.sh:754-758`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** gate operator
**Scope:** Covers an unreadable directory in another listed root, a `find -L` loop under `rules/`, and a grep error. Does not establish the case of an unreadable directory inside ROOT_REAL itself when no other root contains it: C1 does not list ROOT_REAL, and that case falls to the tree walk's git listing.

Probes P4a and P4b (`$L/probe.out`): `find: File system loop detected; '…/home/.claude/rules/d/up' …  walk: failed docs/a.md: imported`, the same for main. With `side/locked` at mode 000: `find: '…/side/locked': Permission denied walk: failed docs/a.md: imported`, for both walks. P2: a grep shim exiting 2 gives `with_at rc=1 n=0`. The suite's fail-closed test passes at HEAD (`$L/suite-build-loop-check.txt`). The failure path is `nul_list fl root_starts "$r" || return 1` (`:1321`) and `outside_seeds sd || return 1` with IMPORTED left at `error` (`:1441`, `:1452`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1287-1297`, `:1321`, `:1340`, `:1441`, `:1452`, `:1498`, `:1533`; `$L/probe.sh`, `$L/probe.out` (cwd `$L`, exit 0, about 2026-10-10T03:39Z)

---

## Claim 10: "The seeds cost: over this repository's 8 registered worktrees, about 50 seeds and 2 to 2.5 s per walk, against 0.6 s without (2026-10-09; i1, i2 performance)"

**Location:** `scripts/lib/dev-cycle-read.sh:759-761`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** gate operator
**Scope:** Covers the worktree count, the seed count and the per-walk times as re-measured now. Does not establish timings under other load.

From `$L/timing.out` (real HOME, `CLAUDE_CONFIG_DIR=/home/node/.claude`, load 2.13):
- `worktrees: 8`, `head seeds: 50`. Exact.
- HEAD tree walk: 3.08 s (first, cold) and 2.14 s.
- HEAD main walk: 2.58 s and 2.59 s.
- Main's lib: 0.59 to 0.60 s (tree) and 0.77 to 0.78 s (main).

The seed count is right. The cost runs a little above "2 to 2.5 s" (2.1 to 3.1 s), and "0.6 s without" holds for the tree walk but is 0.8 s for the main walk. A precise version would say "about 2 to 3 s per walk, against 0.6 to 0.8 s".

**Evidence:** `$L/timing.sh`, `$L/timing.out` (cwd: the worktree via subshell, exit 0, 2026-10-10T03:38:27Z)

---

## Claim 11: "Every name starts at an @ byte: outside_seeds drops a seed holding none (with_at leans on this)"

**Location:** `scripts/lib/dev-cycle-read.sh:937-938`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** parser maintainer
**Scope:** Covers every name the parser derives from file text: `scan`'s unquoted runs, `@"` quoted text (including quotes carried across lines), splices, decoded text, NULs and UNI_SPACES. Does not cover the `IMPORT_WHOLE` input mode. That mode yields names with no @ (it reads real paths, not file text), and outside_seeds keeps link-reached seeds for exactly that reason.

`scan` calls `names`/`quoted` only after `if (substr(line, i, 1) != "@") continue` (`:942`). A carried quote's text is opened only at an `@"` (`:944-949`). `splice` only removes `<!-- … -->` text (`:969-977`). python3's "replace" decoding and the sed blanking add no 0x40 byte (`:1136`, `:1143`). The one path that yields a name without an @ is `if (whole) { emit($0, 1); next }` (`:994`). Probe P3: a file with names, a splice, a quote, invalid UTF-8 and a NUL but no @ gives `names from no-@ text: []`, while `IMPORT_WHOLE` gives `[docs/a.md]`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:939-1003`; `$L/probe.out` (P3)

---

## Claim 12: "IMPORT_MANAGED_DIR … set here, so the environment never moves it (a test sets it). A caller that changes it calls import_reset (contract item 4)."

**Location:** `scripts/lib/dev-cycle-read.sh:1060-1063`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib caller
**Scope:** Covers the assignment at source time and its cross-reference to item 4. Does not establish that `/etc/claude-code` is Claude Code's managed-policy directory (an external fact).

`IMPORT_MANAGED_DIR=/etc/claude-code` (`:1063`) is an unconditional assignment when the lib is sourced, so an inherited value is overwritten. Tests set it after sourcing (`IMPORT_MANAGED_DIR="${T_MANAGED:-/nonexistent/managed}"`, `test/scripts/build-loop-check.bats:25`). Item 4 names it (`:70`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1063`, `:70`; `test/scripts/build-loop-check.bats:25`

---

## Claim 13: import_outside header: "(for the walks, a name from the parser's second channel, below no reader root, or an outside_seeds start, which may lie in another root)"

**Location:** `scripts/lib/dev-cycle-read.sh:1154-1156`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers which absolute files reach import_outside. Does not establish other callers.

`import_file` routes any absolute path to `import_outside` (`if [[ "$1" == /* ]]; then import_outside "$1" "${@:3}"`, `:1185`). The seed loops queue absolute seed paths (`:1455`, `:1536`). C1 seeds lie under other roots, for example `seed:f/…/side/CLAUDE.md` in `$L/probe.out` (P8).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1185`, `:1455`, `:1536`; `$L/probe.out`

---

## Claim 14: outside_ok: "an absolute name (one below no reader root, or an outside_seeds start, which may lie in another root): a readable regular file (the one admission rule both walks apply)"

**Location:** `scripts/lib/dev-cycle-read.sh:1186-1189`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers the test and its use for seeds and `//` names in both walks. Does not establish TOCTOU behaviour; the walk header names that exception.

`outside_ok() { [[ -f "$1" && -r "$1" ]]; }` (`:1190`). It is applied at `:1454` and `:1470` (tree walk) and at `:1535` and `:1585` (main walk), as well as in `with_at` (`:1223`) and `outside_proj` (`:1202`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1190`, `:1202`, `:1223`, `:1454`, `:1470`, `:1535`, `:1585`

---

## Claim 15: outside_proj header (rejected `//` names get one `realpath -m`; differing ones projected whole; names appended to OUT, work to TOTAL; returns 1 on realpath/projection failure, a newline, or TOTAL past IMPORT_WORK_MAX)

**Location:** `scripts/lib/dev-cycle-read.sh:1191-1198`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer
**Scope:** Covers the function body and its call after each file's parse in both walks. Does not establish a bind-mount alias (untested, as U2b3b2a noted).

```bash
# scripts/lib/dev-cycle-read.sh:1202-1208
  while IFS= read -r p; do [[ "$p" != //* ]] || outside_ok "${p#/}" || rj+=("${p#/}"); done < <(printf '%s\n' "$op_o")
  [[ ${#rj[@]} -gt 0 ]] || return 0
  nul_list rl realpath -mz -- "${rj[@]}" && [[ ${#rl[@]} -eq ${#rj[@]} ]] || return 1
  for i in "${!rj[@]}"; do [[ "${rl[i]}" != *$'\n'* ]] || return 1; [[ "${rl[i]}" == "${rj[i]}" ]] || df+=("${rl[i]}"); done
  [[ ${#df[@]} -gt 0 ]] || return 0
  b="$(printf '%s\n' "${df[@]}" | IMPORT_WHOLE=1 IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - op_t)) import_targets /)" && import_work b op_t || return 1
  [[ -z "$b" ]] || op_o+="${op_o:+$'\n'}$b"
```

The function ends at `:1209` (read). It is called at `:1463` and `:1577`. The suite test "a // name outside_ok rejects is projected through its realpath -m" (dangling link and linked directory) passes at HEAD and is red on main's lib (`$L/redbase.out`, `not ok 4`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1199-1209`, `:1463`, `:1577`; `$L/suite-build-loop-check.txt`, `$L/redbase.out`

---

## Claim 16: root_starts: "the start-named files (instruction_names) below ROOT … as absolute paths, NUL-separated, listed with find -P (.git pruned): regular files and links. It fails when find or grep does."

**Location:** `scripts/lib/dev-cycle-read.sh:1210-1212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers the one-line body. Does not establish behaviour for a relative ROOT, which the callers never pass (cr holds realpath output).

`find -P "$1" -name .git -prune -o '(' -type f -o -type l ')' -iname '*.md' -print0 | instruction_names` runs under a local `pipefail`. instruction_names treats grep's status 1 as success (`|| [[ $? -eq 1 ]]`, `:1360`), so only a real grep error fails it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1213`, `:1360`

---

## Claim 17: with_at: "array NAME gets the PATHs outside_ok admits that hold an @ byte, read by grep in xargs batches … It returns 1 on any grep error"

**Location:** `scripts/lib/dev-cycle-read.sh:1214-1218`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer
**Scope:** Covers the outside_ok prefilter, grep status ≥2 → xargs 123 → nul_list failure, and the nameref chain `caller array ← wa_a ← nl_a`. Does not establish safety for a caller whose array is named `wa_a`, `p` or `wa_ok`: nameref collisions are not guarded, and today's callers pass `fl` only.

```bash
# scripts/lib/dev-cycle-read.sh:1220-1224
  local -n wa_a="$1"; local p wa_ok=(); shift
  # shellcheck disable=SC2034  # wa_a is the caller's array, filled by name
  wa_a=()
  for p in "$@"; do ! outside_ok "$p" || wa_ok+=("$p"); done
  [[ ${#wa_ok[@]} -eq 0 ]] || nul_list wa_a xargs -0r -a <(printf '%s\0' "${wa_ok[@]}") sh -c 'grep -lZF -e @ -- "$@"; [ $? -le 1 ]' sh
```

P1: given a link to an @ file, an @-free file and a FIFO, grep received only the first two (`-lZF -e @ -- …/link.md …/noat.md`). The caller's array came back as `kept:…/link.md`, which confirms the nameref chain. P2: a grep shim exiting 2 gave `with_at rc=1 n=0`. The suite assertion with the same shim passes at HEAD and was red on 39f64d62 (`walk: ok`, `docs/a.md: -` in `$L/redbase.out`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1219-1225`, `:1367`; `$L/probe.out` (P1, P2), `$L/redbase.out`

---

## Claim 18: outside_seeds header, sources (1) and (2): config dirs (homes' `.claude`, CLAUDE_CONFIG_DIR, IMPORT_MANAGED_DIR) → instruction-named files, `rules/` (f), prompt dirs and installed plugin versions (p; every cached version when the JSON does not parse), auto memory `projects/*/memory/MEMORY.md` (f), trees via `find -L`; ancestors below no root → instruction files and their `.claude`

**Location:** `scripts/lib/dev-cycle-read.sh:1226-1236`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** gate reviewer
**Scope:** Covers each listed source and its f/p tag. Does not establish that Claude Code loads exactly these (the superset claim is external), nor the "user's skills link into /opt" beyond this machine.

The code matches source by source: `:1263-1264` (config dirs), `:1265-1272` (ancestors, `tops` and `cf`), `:1275-1277` (rules, projects, prompt dirs, plugin JSON), `:1279-1286` (plugins), `:1287-1292` (`find -L`, tags f/p/f), and `:1296-1300` (top-level files by `isstart`). The two suite tests for (1) and (2) pass at HEAD and are red on main's lib (`$L/redbase.out`, `not ok 1`, `not ok 2`). The /opt link is real here: the 39f64d62-vs-HEAD diff lists `//opt/claude-workflows/skills/…` names reached through `~/.claude/skills` (`$L/samenames.out`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1258-1300`; `$L/suite-build-loop-check.txt`, `$L/redbase.out`, `$L/samenames.out`

---

## Claim 19: "(3) C1: every start file (isstart, by its path below its innermost root) in another reader root present here"

**Location:** `scripts/lib/dev-cycle-read.sh:1237-1238`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer
**Scope:** Covers which path C1's start test reads. Does not establish the byte-skip test, which does use the inner path (`:1337`).

Since 8f99fcaf (B3), `isstart` reads the **whole** lower-cased path, not the path below the innermost root:

```bash
# scripts/lib/dev-cycle-read.sh:1329,1333
  lo=(); if [[ ${#cx[@]} -gt 0 ]]; then nul_list lo lower_all "${cx[@]}" && [[ ${#lo[@]} -eq ${#cx[@]} ]] || return 1; fi
    isstart "${lo[i]}" && [[ -n "${os_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue
```

The in-body comment at `:1324-1327` states this correctly ("isstart … and the prompt test read the whole path"). At 39f64d62 the code ran `lower_all "${ir[@]}"` (inner paths) and the header matched. Probe P5 shows the difference: `README.md` in a worktree nested in `side/.claude/skills/` is seeded (`seed:p…/side/.claude/skills/wt/README.md`), and an inner-path `isstart("readme.md")` would reject it. The header should say "isstart, by its whole path".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1237-1238`, `:1324-1334`; `git show 39f64d62:scripts/lib/dev-cycle-read.sh` (`:1223`, the same header text over inner-path code); `$L/probe.out` (P5)

---

## Claim 20: "A root below another listed one comes with it, unless it lies below ROOT_REAL, whose files that listing drops: then it is listed itself (and a root below it twice, which the walks' seen absorbs)"

**Location:** `scripts/lib/dev-cycle-read.sh:1238-1241`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer
**Scope:** Covers root selection and the ROOT_REAL drop filter. Does not establish cost on deep nesting.

`:1319-1322`, quoted in Claim 2, implements both cases, and `[[ "$d" == "$ROOT_REAL"/* && "$r" != "$ROOT_REAL"/* ]] || cx+=("$d")` drops ROOT_REAL's files only from an outer root's listing. P6: a worktree at `repo/.claude/inner` (below ROOT_REAL) is seeded (`seed:f…/repo/.claude/inner/CLAUDE.local.md`). In the same run, the worktree nested in `side` comes with side's listing (`seed:p…/side/.claude/skills/wt/README.md`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1317-1323`; `$L/probe.out` (P6)

---

## Claim 21: "One whose bytes equal ROOT_REAL's plain file (rawfile) at that path is skipped: the parser joins that file's names under every root and the walks start there too (given contract item 2's clean checkout, which also keeps out an untracked nested repo whose files neither walk lists)"

**Location:** `scripts/lib/dev-cycle-read.sh:1241-1245`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** gate reviewer
**Scope:** Covers the justification that a skipped seed reads the same as ROOT_REAL's copy. It is refuted when the seed is a prompt by its whole path but ROOT_REAL's copy is not a prompt at its inner path. It holds when both copies have the same prompt class (P8). The clean-checkout half (checkout_gate refuses a nested repo) is correct.

The skip condition requires ROOT_REAL's copy to be a *start* at the inner path, not a *prompt*:

```bash
# scripts/lib/dev-cycle-read.sh:1334-1337
    c=f; [[ ! "${lo[i]}" =~ $PROMPT_DIR ]] || c=p
    # rawfile: a ROOT_REAL copy reached through a link the tree walk does not start at (i1 fact-check 19b).
    # isstart on the inner path's tail of lo: ROOT_REAL's copy must be a start there too.
    if [[ ! -L "${cx[i]}" ]] && isstart "${lo[i]:${#lo[i]}-${#ir[i]}}" && rawfile "${ir[i]}" && outside_ok "${cx[i]}"; then sp+=("$c${cx[i]}"); hs+=("${cx[i]}" "${ir[i]}"); else os_a+=("$c${cx[i]}"); fi
```

Here `c` comes from the whole path (B3). A `p` seed would also be read against prompt_bases: the session top level and the directory holding each `.claude`. The skipped ROOT_REAL copy is read against its own directory only. Probe2 setup: worktree `side`, and a worktree nested at `side/sub/.claude/skills/wt` with `docs/CLAUDE.md` = `c: @name.md`, the same bytes as ROOT_REAL's tracked `docs/CLAUDE.md`. Both walks then give `name.md: -  sub/name.md: -` and no seed. When only the bytes change, both give `name.md: imported  sub/name.md: imported` and seed `p…/wt/docs/CLAUDE.md`. So the byte skip drops names the superset model yields for that seed. The precondition is a worktree nested under another root's `.claude/{commands,agents,output-styles,skills}/`. It has low practical exposure in this repository, whose nested worktrees sit under `.claude/worktrees/` and `.claude/wt-*`. The gap appeared at 8f99fcaf: at 39f64d62 both tests used the inner path. A fix would require the inner path's prompt class to match `c` before skipping (or never skip `p` seeds whose inner path is not a prompt). Alternatively, name the case as an exception.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1241-1245`, `:1324-1342`, `:661-676`; `scripts/build-loop.sh:631-637` (nested-repo refusal); `$L/probe2.sh`, `$L/probe2.out` (cwd `$L`, exit 0, 2026-10-10T03:41:00Z)

---

## Claim 22: "Not covered (routed to U2b3b2c): a file another root holds with other bytes, or alone, that a start there imports (the walks read ROOT_REAL's copy or main's: i1 security F1)"

**Location:** `scripts/lib/dev-cycle-read.sh:1245-1247`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** gate reviewer
**Scope:** Covers the routing reference and its plan bullet. Does not establish the fix.

The plan bullet exists (`docs/working/plan-build-loop-handoff.md:307`), and the read paths are as Claim 3 describes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1245-1247`; `docs/working/plan-build-loop-handoff.md:307`

---

## Claim 23: "Roots are listed with find -P (.git pruned), never git -C: a loop controls its worktree's .git file, so git there could read a config the loop wrote"

**Location:** `scripts/lib/dev-cycle-read.sh:1248-1250`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security reviewer
**Scope:** Covers outside_seeds and the walks over other roots. Does not establish what git commands run in ROOT_REAL.

Within outside_seeds, `root_starts` is the only lister of other roots, and it uses find (`:1213`). The C1 suite test logs every git call through a shim and asserts `! grep -e "^$sd" -e ' -C ' "$S/log"` (`test/scripts/build-loop-check.bats:741`). It passes at HEAD (`$L/suite-build-loop-check.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1213`, `:1321`; `test/scripts/build-loop-check.bats:734-741`

---

## Claim 24: "Only a seed holding an @ byte or reached through a link … can yield a name, so the rest are dropped …; an unreadable file is skipped, as outside_ok skips it. Not covered: a symlinked directory in another root, which find -P does not enter"

**Location:** `scripts/lib/dev-cycle-read.sh:1250-1254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer
**Scope:** Covers the keep rule for both seed groups. A config link is kept only when its real path lies below a reader root (`:1310`), which narrows "reached through a link"; links whose real path lies below no root can yield only `//` names. Does not establish TOCTOU behaviour.

`:1309-1311` (config) and `:1333` (C1: `os_at` or `-L`). P7: a mode-000 `@` rule file leaves both walks `walk: ok`. `find -P` does not descend into symlinked directories (POSIX `-P`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1304-1312`, `:1330-1333`; `$L/probe.out` (P7)

---

## Claim 25: "It returns 1 when a find, grep, sha1sum, realpath or lower_all fails, a seed's path holds a newline, or CLAUDE_CONFIG_DIR is set but not absolute. Run it after import_readers."

**Location:** `scripts/lib/dev-cycle-read.sh:1255-1257`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib caller
**Scope:** Covers every `return 1` in the body. "A seed's path" means a *kept* seed (`:1343` checks `os_a` only). An @-free, link-free name with a newline is dropped silently. python3 failure falls back rather than failing.

The `return 1` sites are `:1261`, `:1287`, `:1288`, `:1290`, `:1297-1298`, `:1304`, `:1307`, `:1314`, `:1321`, `:1329`, `:1330`, `:1340` and `:1343`. All are find, grep (`with_at`, `instruction_names`), realpath, lower_all, sha1sum, the newline check or the CLAUDE_CONFIG_DIR check. The body reads `IMPORT_ROOTS` and `IMPORT_HOMES`, which import_readers sets. The suite's relative-CLAUDE_CONFIG_DIR and newline assertions pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1258-1344`

---

## Claim 26: "-H and -xtype, not -L: a link to a file counts, and a link to an ancestor (a loop to find -L) is not followed"

**Location:** `scripts/lib/dev-cycle-read.sh:1293-1295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers the top-level listing `find -H "${tops[@]}" -maxdepth 1 -xtype f`. Does not establish bfs-specific quirks (not probed for this line).

With `-H`, only command-line links are followed. `-maxdepth 1` stops descent, and `-xtype f` tests a link's target, so a link to a file passes and a link to a directory is neither entered nor listed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1297`

---

## Claim 27: "The config seeds that can yield a name: an @ in the file, or a link on the way to a real path below a reader root (projected as that repo path; one below no root holds no @ either)"

**Location:** `scripts/lib/dev-cycle-read.sh:1301-1303`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer
**Scope:** Covers the keep rule at `:1308-1312`. Does not establish anything about seeds dropped by the rule, which can yield only `//` names that no isimported query matches.

The rule is `[[ -n "$in" || "${rl[i]}" == "${cx[i]}" ]] || for q in "${rs[@]}"; do [[ "${rl[i]}" != "$q"/* ]] || in=1; done` (`:1310`). Run against the real home, the 39f64d62 and HEAD libs give identical repo-name sets (1210 non-`//` lines each). The lists differ only in 35 `//opt/claude-workflows/skills/…` lines, the @-free skill links this rule now drops (`$L/samenames.out`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1304-1312`; `$L/samenames.out`

---

## Claim 28: "isstart (the authority, after instruction_names' prefilter) and the prompt test read the whole path …; the byte comparison takes the path below its innermost root"

**Location:** `scripts/lib/dev-cycle-read.sh:1324-1327`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer
**Scope:** Covers the comment against `:1328-1341`. Does not establish that the two readings agree on prompt class (they need not: Claim 21).

The start and prompt tests read `lo` (whole path) at `:1333-1334`. The byte comparison reads `ir` (innermost-root relative) at `:1328`, `:1337` and `:1340`. P5 confirms the whole-path prompt test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1328-1341`; `$L/probe.out` (P5)

---

## Claim 29: "isstart on the inner path's tail of lo: ROOT_REAL's copy must be a start there too"

**Location:** `scripts/lib/dev-cycle-read.sh:1336`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers the start-ness check `isstart "${lo[i]:${#lo[i]}-${#ir[i]}}"`, which takes the lowered tail of the same length as `ir` (tr changes only ASCII bytes, so lengths agree). Does not establish that the copy's prompt class also matches (it is not checked: Claim 21).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1337`

---

## Claim 30: Walk seed comments: "The outside starts, after the checkout's, admitted as a // name is." / "The outside starts join phase 2, as an outside import does (never main's arms)."

**Location:** `scripts/lib/dev-cycle-read.sh:1451`, `:1532`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers admission and queueing. Does not establish dedup across spelled and real forms of the same file, which are distinct strings.

Seeds pass the same `outside_ok` + seen test as `//` names (`:1454` vs `:1470`, `:1535` vs `:1585`). In main_imports a seed is never in `ent`, so `case "${ent[$f]-checkout}"` takes the checkout arm (`:1544-1546`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1451-1456`, `:1532-1546`

---

## Claim 31: "The walks read the config dirs under HOME and CLAUDE_CONFIG_DIR (outside_seeds): the fixture's home only."

**Location:** `test/lib/build-loop-fixtures.bash:19-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** test author
**Scope:** Covers HOME and CLAUDE_CONFIG_DIR. Does not establish hermeticity against the fixture root's ancestors (`$BATS_TEST_TMPDIR`, `/tmp`, `/`) and their `.claude`, which outside_seeds also reads (source (2)). It also does not establish hermeticity against `/etc/claude-code` in suites that do not override IMPORT_MANAGED_DIR (dev-cycle.bats).

`export HOME="$BATS_TEST_TMPDIR/home" LC_ALL=C; unset CLAUDE_CONFIG_DIR` (`:20`). dev-cycle.bats does the same (`test/scripts/dev-cycle.bats:19`).

**Evidence:** `test/lib/build-loop-fixtures.bash:19-20`; `test/scripts/dev-cycle.bats:18-19`

---

## Claim 32: "T_MANAGED becomes IMPORT_MANAGED_DIR (by default a path that does not exist)."

**Location:** `test/scripts/build-loop-check.bats:18-19`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** test author
**Scope:** Covers `imps` only. Does not establish this for the inline `bash -c` blocks at `:742`, which set `/nonexistent` themselves.

`IMPORT_MANAGED_DIR="${T_MANAGED:-/nonexistent/managed}"` runs after `source "$1"` (`:25`).

**Evidence:** `test/scripts/build-loop-check.bats:18-25`

---

## Claim 33: 1c820663: "Tests: five new in build-loop-check.bats, each red on main's lib"

**Location:** commit 1c820663 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer of the commit
**Scope:** Covers the five tests as they stood at 1c820663, run against main's lib. Does not establish per-assertion redness within each test.

The @test count goes from 120 (main) to 125 (1c820663). `bats -f 'U2b3b2b'` over 1c820663's tests with main's lib gives `not ok 1` … `not ok 5` (`$L/redbase.out`).

**Evidence:** `$L/redbase.sh`, `$L/redbase.out` (cwd `$L`, exit 0, 2026-10-10T03:37:12Z)

---

## Claim 34: "Suites 125/79/20/2/2" (all three commits)

**Location:** commits 1c820663, 39f64d62, 8f99fcaf messages
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers the counts at all three commits (static `grep -c '^@test'`) and the pass at HEAD (executed). Does not establish that the suites passed at 1c820663 and 39f64d62.

The order is build-loop-check / dev-cycle / build-loop-read / fixture-git-env / fixture-hermeticity, which is the U2b3b2a merge message's suite set. The counts are 125/79/20/2/2 at each of 1c820663, 39f64d62 and 8f99fcaf. At HEAD every suite exits 0 with 125, 20, 79, 2 and 2 `ok` lines (`$L/suite-*.txt`).

**Evidence:** `$L/suites.ts`, `$L/suite-build-loop-check.txt`, `$L/suite-dev-cycle.txt`, `$L/suite-build-loop-read.txt`, `$L/suite-fixture-git-env.txt`, `$L/suite-fixture-hermeticity.txt`

---

## Claim 35: "248 code lines" / "302 code lines" / "333 code lines against main"

**Location:** commits 1c820663, 39f64d62, 8f99fcaf messages
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers insertions plus deletions under `scripts` and `test`. Does not establish any other counting convention.

`git diff --numstat main...<sha> -- scripts test`, with insertions and deletions summed, gives 248, 302 and 333. The command ran in the worktree, exit 0, 2026-10-10 about 03:36Z. Its output is in this session's transcript only, because the dispatch allowed no log file in the repo. The HEAD `--stat` lines (236 + 3 + 87 + 7 = 333) agree.

**Evidence:** `git diff --numstat main...8f99fcaf -- scripts test` (reproducible)

---

## Claim 36: 1c820663: "Walks over this repo's worktrees take about 7 s each against 0.7 s (measured; recorded in the walk header). K4 not done: 83 KB of // lines here."

**Location:** commit 1c820663 message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** reviewer
**Scope:** Covers the "recorded in the walk header" part, which holds: 1c820663's lib says "and 7 s per walk, against 0.7 s without" at `:751`. Does not establish the 7 s or 83 KB figures, which describe the repository state at that commit. Re-measuring needs 1c820663's lib over the same worktree and home state, which has since changed.

**Evidence:** `git show 1c820663:scripts/lib/dev-cycle-read.sh` `:751`

---

## Claim 37: 39f64d62: "Walks over this repository's 8 worktrees: 7 s -> 3 to 3.5 s, same names" and "a first fix seeding every @-bearing .md in other roots gave 6,720 seeds and failed both walks"

**Location:** commit 39f64d62 message (also `docs/working/plan-build-loop-handoff.md:306-307`)
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers the order of magnitude only. Does not establish the historical figures.

That first fix was never committed, and the worktree set has changed. A current count of @-bearing `.md` files under `/workspace`, excluding this checkout, is 10,839 (find + grep, run in the worktree, exit 0, 2026-10-10 about 03:41Z). That is the same order as 6,720, so the claim is plausible.

**Evidence:** reproducible one-liner, `find -P /workspace -name .git -prune -o -type f -iname '*.md' -print0 | grep -zv "^$PWD/" | xargs -0r grep -lF @ | wc -l` (output in session transcript)

---

## Claim 38a: 8f99fcaf B1: "with_at reads only seeds outside_ok admits … and accepts grep status 0 or 1 only, so a fatal grep error fails the walk and a link to /dev/zero or a FIFO no longer hangs it"

**Location:** commit 8f99fcaf message
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers the outside_ok prefilter (a FIFO and a character device fail `-f`) and the exit-status rule. Does not establish behaviour for a regular file swapped for a FIFO after admission (a named exception).

P1: the FIFO is not passed to grep. P2: grep exit 2 → `rc=1`. The suite shim assertion passes at HEAD and was red on 39f64d62 (Claim 17).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1219-1225`; `$L/probe.out`, `$L/redbase.out`

---

## Claim 38b: 8f99fcaf B1: "with_at … keeps links unread"

**Location:** commit 8f99fcaf message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers with_at's treatment of a symlink to a readable regular file. Does not cover links to non-regular files, which are unread because outside_ok rejects them. A reading where "links" means "links to devices or FIFOs" would make the clause true, but the sentence does not say that.

with_at grepped a symlink: `grep argv: -lZF -e @ -- …/o/link.md …/o/noat.md`, and `link.md` was returned as kept (P1). Links are kept *regardless of their bytes* by outside_seeds' callers (`-L "${cx[i]}"` at `:1333`, the realpath rule at `:1310`), not left unread by with_at. A precise version would say "outside_seeds keeps C1 links whatever their bytes; with_at reads only regular files".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1223-1224`, `:1310`, `:1333`; `$L/probe.sh`, `$L/probe.out` (P1)

---

## Claim 39: 8f99fcaf B2, B3, B4, L1 (batched config realpath; whole-path C1 isstart plus inner-path start check for the byte skip; no early return with each phase guarding its own empty list; @-free link-reached config seed kept only below a reader root)

**Location:** commit 8f99fcaf message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** reviewer
**Scope:** Covers the code changes as described. Does not establish that B3 is safe for the byte skip's prompt class (Claim 21).

The changes are at:
- B2: `xargs … realpath -mz` (`:1307`).
- B3: `lower_all "${cx[@]}"` (`:1329`) and the tail `isstart` (`:1337`).
- B4: outside_seeds has no `return 0`. `rl=()` and `lo=()` are reset before guarded use (`:1307`, `:1329`), and the old `[[ ${#cx[@]} -gt 0 ]] || return 0` is gone (`git diff 39f64d62 8f99fcaf`).
- L1: `:1310`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1304-1342`; `git diff 39f64d62 8f99fcaf -- scripts`

---

## Claim 40: 8f99fcaf: "Walks: 2 to 2.5 s over 8 worktrees, same 1177 names."

**Location:** commit 8f99fcaf message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers "same names" as the repo-name set across 39f64d62 and HEAD libs, and timing as re-measured now. Does not establish the 1177 count at commit time.

The repo-name sets of the two libs are identical today (1210 non-`//` lines each, both walks). The walk lists are not identical: HEAD drops 35 `//opt/…` lines by L1's design (`$L/samenames.out`). The count is now 1210, not 1177, because the workspace has changed since. Timing as in Claim 10: 2.1 to 3.1 s. A precise version would say "same repo names (the `//` entries for @-free links below no root drop out)".

**Evidence:** `$L/samenames.sh`, `$L/samenames.out` (exit 0, 2026-10-10T03:38:54Z); `$L/timing.out`

---

## Claim 41: 8f99fcaf: "Each new assertion is red on 39f64d62's lib."

**Location:** commit 8f99fcaf message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers the three iteration-2 assertions: `docs/w.md` imported, the grep-shim walk failure, and `with_at` in the sourcing inventory. Does not establish mutant coverage of each fix.

HEAD's tests run against 39f64d62's lib:
- C1 test fails at `want: docs/w.md: imported` (`docs/w.md: -`).
- The fail-closed test fails at the shim step (`want: walk: failed`, got `walk: ok`).
- dev-cycle's inventory test fails (`not ok 1 sourcing the reader lib defines its functions…`).

**Evidence:** `$L/redbase.sh`, `$L/redbase.out` (cwd `$L`, exit 0, 2026-10-10T03:37:12Z)

---

## Claims Requiring Attention

### Incorrect
- **Claim 21** (`scripts/lib/dev-cycle-read.sh:1241-1245`): the byte-skip justification ("the walks start there too" and so read the same names) fails when a C1 seed is a prompt by its whole path but ROOT_REAL's copy is not a prompt at its inner path. The skip then drops prompt-base names (executed: `name.md`, `sub/name.md` missed with equal bytes, imported with different bytes). This was introduced by B3 at 8f99fcaf. To fix, require the inner path's prompt class to match `c` before skipping, or name the case as an exception at `:749-754`.
- **Claim 38b** (commit 8f99fcaf, B1): "with_at … keeps links unread" is wrong. with_at greps a link to a regular file. Links are kept whatever their bytes by outside_seeds (`:1310`, `:1333`), not left unread.

### Stale
- **Claim 1** (`docs/working/plan-build-loop-handoff.md:306`): seed list (1) says `plugins/cache/**.md`. The code reads installed versions only, and the whole cache only when the JSON does not parse.
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:1237-1238`): "isstart, by its path below its innermost root" should say "by its whole lower-cased path" (changed by B3). The in-body comment at `:1324-1327` is already right.

### Mostly Accurate
- **Claim 2** (`docs/working/plan-build-loop-handoff.md:306`): the C1 nesting rule omits "unless it lies below ROOT_REAL, then listed itself".
- **Claim 8** (`scripts/lib/dev-cycle-read.sh:749-754`): the named-exceptions list is missing the whole-path-prompt byte-skip case of Claim 21.
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:759-761`): 50 seeds is exact, but the walks measured 2.1 to 3.1 s (not 2 to 2.5 s), and 0.8 s for main's walk without seeds.
- **Claim 40** (commit 8f99fcaf): the repo-name sets are identical across libs, but the walk lists differ by 35 `//` lines (by design), and the count is now 1210.

### Unverifiable
- **Claim 36** (commit 1c820663): 7 s / 0.7 s and 83 KB of `//` lines describe the state at that commit. Re-measuring needs that commit's lib over the same worktree and home state.
- **Claim 37** (commit 39f64d62, plan :306-307): 3 to 3.5 s and 6,720 seeds come from an uncommitted experiment. The current @-bearing `.md` count (10,839) is the same order.

## Goal-Alignment Note

The PR aims to make both import walks start at every outside file a Claude Code session may load: config dirs, ancestors, and other roots' start files (C1). The walks must remain a fail-closed superset. Execution supports that aim. Every seed source loads as described. The fail-closed paths fire: a find loop, an unreadable worktree directory, and a grep error all fail the walk. No git runs in another root. Every new test is red on its base and green at HEAD (125/20/79/2/2).

One finding bears directly on the superset property. The C1 same-bytes skip (Claim 21) can drop names when the whole-path and inner-path prompt classes differ. That combination appeared with iteration 2's whole-path start test. The same pass left the header's "innermost root" wording stale (Claim 19). The gap needs a worktree nested under another root's `.claude/{commands,agents,output-styles,skills}/`, which this repository does not have. It is narrow, but it is a fail-open inside the superset model rather than a named exception, so the merge decision should either fix it or name it. The other findings are text: the plan's plugin and nesting wording, the timing ranges, and the commit's "keeps links unread".
