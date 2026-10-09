Commit: 82bb5281
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2b3b2a`, branch `feat/build-loop-u2b3b2a`)
**Scope:** `git diff main...HEAD -- scripts test` at 82bb5281 (scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats), plus the commit messages of 55490d15, 18fba03d, f7a96eed and 82bb5281. Iteration 3, final confirming pass, replicate r1 of k=3.
**Checked:** 2026-10-09
**Total claims checked:** 48
**Summary:** 45 verified, 1 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Execution logs: `/tmp/claude-1000/-workspace/715dcdb7-5140-4bd1-a115-cbeff3508ce5/scratchpad/u2b3b2a-i3/fact-check-r1/logs/` (suite TAP files with `.ts` timestamp and exit files; `probe1.log` to `probe7.log`). The probe scripts sit beside them (`probe1.sh` to `probe7.sh`). Each starts with `set -eu`, makes and enters its own `mktemp -d` directory, checks `pwd -P` before any `git init`, and removes that directory at the end. Every probe exited 0. Suites ran with `cd /workspace/.claude/wt-build-loop-u2b3b2a && LC_ALL=C LANG=C TMPDIR=<mktemp> bats <suite>`.

Hallucination log: read. The one relevant pattern is test-count claims in commit messages ("All 85 tests ... but the suites hold 97", "mode1-equiv 33 ... holds 25"). Every count checked here matches (Claims 40, 45).

---

## Claim 1: "and prints a path below no reader root on its second channel: import_readers"

**Location:** `scripts/lib/dev-cycle-read.sh:679`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk header's statement that the parser prints names below no root, not drops them. It does not establish how the walk then admits them (Claim 2).
**Legibility-target:** for-orchestrator-synthesis

The parser's `put` ends with `if (nho == 0) show("/" out)` (`scripts/lib/dev-cycle-read.sh:899`). probe1.log shows `@/opt/5` printing `//o` … `//opt/5`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:892-899`; probe1.sh (cwd its mktemp dir, 2026-10-09T16:50:13Z, exit 0), logs/probe1.log `== 1`

---

## Claim 2: "Both walks follow an import to a file below no reader root ... when outside_ok admits it, reading it from the file system ... through import_outside (the main walk in phase 2); one that is missing, unreadable or not a regular file here is skipped."

**Location:** `scripts/lib/dev-cycle-read.sh:720-723`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' `//` arms, outside_ok's four outcomes and the route through import_file to import_outside. It does not establish what a Claude Code session loads (Claim 28b).
**Legibility-target:** for-orchestrator-synthesis

Tree arm: `[[ "$p" != //* ]] || { p="${p#/}"; outside_ok "$p" && [[ "$seen" != *$'\n'"$p"$'\n'* ]] && seen+="$p"$'\n' && queue+=("$p"); continue; }` (`:1278`). Main arm: `... outside_ok "$p" && seen[$p]=1 && tq+=("$p"); continue; }` (`:1386`). Both pop the path into `import_file`, whose branch `if [[ "$1" == /* ]]; then import_outside ...` (`:1154`) handles it. probe1.log: `outside_ok none.md rc=1`, `d.md rc=1`, `fifo.md rc=1`, `locked.md rc=1`, `p.md rc=0`. The test at `test/scripts/build-loop-check.bats:671` passes in both walks (logs/build-loop-check.tap).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1154-1158`, `:1270`, `:1278`, `:1347`, `:1386`; probe1.log `== 2`; build-loop-check.tap (2026-10-09T16:46:51Z, exit 0)

---

## Claim 3: "Known exceptions: a file a session elsewhere can load that this container cannot see (... reader home ... absent here, or under another uid ...), and a regular file swapped for a FIFO after its admission, which stalls the read"

**Location:** `scripts/lib/dev-cycle-read.sh:724-728`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip of an unreadable or absent path and the stall on a FIFO read past admission. It does not race a real swap; it calls import_outside on a FIFO directly.
**Legibility-target:** for-orchestrator-synthesis

`outside_ok() { [[ -f "$1" && -r "$1" ]]; }` (`:1158`) skips a mode-000 file (`locked.md rc=1`) and an absent one. Called directly on a FIFO under `timeout 2`, import_outside returned `rc=124`: realpath passes and `capped_read < "$1"` blocks in the open (`:1144`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1142-1144`, `:1158`; probe1.log `-- fifo (timeout 2)`

---

## Claim 4: "A large outside file a prefix names (@/usr/bin/python3.md reads /usr/bin/python3) or a very long absolute name (each prefix prints, about L*L/2 bytes ...) can spend a walk's budget, which fails closed"

**Location:** `scripts/lib/dev-cycle-read.sh:728-732`
**Type:** Performance / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks on a fixture whose AGENTS.md names `@/usr/bin/python3.md` (6.8 MB python3.11 here), or a 3,000-character absolute token. It does not establish the exact threshold.
**Legibility-target:** for-orchestrator-synthesis

probe6.log: `py tree walk failed`, `py main walk failed`, `long tree walk failed`, `long main walk failed`. main's lib passes all four (`mainlib ... walk ok`), so these are new failures, and they fail closed as stated.

**Evidence:** `scripts/lib/dev-cycle-read.sh:899`, `:904`; probe6.sh (2026-10-09T16:53:16Z, exit 0), logs/probe6.log

---

## Claim 5: "The walk reads outside files as they are when it runs: one changed or removed during the walk is read as it then is"

**Location:** `scripts/lib/dev-cycle-read.sh:732-733`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the absence of any snapshot of outside files: each is opened when popped. It does not establish behaviour inside the admission-to-read window, which import_outside's header covers (Claim 25b).
**Legibility-target:** for-author

Admission (`outside_ok`, `:1278`/`:1386`) and the read (`capped_read < "$1"`, `:1144`) both act on the live file system, with no copy taken. A file removed before admission is skipped. One removed after admission fails `realpath -e` and so fails the walk (probe1.log `-- missing ... rc=1`). "Read as it then is" covers both outcomes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1142-1144`, `:1278`, `:1386`

---

## Claim 6: "(known issue A5; U2b3b2b's outside starts), nor at a start file only another registered checkout holds (U2b3b2b)"

**Location:** `scripts/lib/dev-cycle-read.sh:735-736`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the plan names U2b3b2b as owning these seeds. It does not establish U2b3b2b's design.
**Legibility-target:** for-author

The plan's split note reads "**U2b3b2b, outside seeds and C1**: the seeds above (user memory ..., ancestors outside every root, each other reader root's untracked and ignored start files)" (`docs/working/plan-build-loop-handoff.md:305`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:305`

---

## Claim 7: "The walks' lists (IMPORTED, IMPORTED_MAIN) also hold the second channel's lower-cased // names, which no repo path isimported asks for can match."

**Location:** `scripts/lib/dev-cycle-read.sh:737-738`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the lists append and the three callers' path forms. It does not establish that a future caller could not pass a `/`-led path.
**Legibility-target:** for-orchestrator-synthesis

probe2.log shows `tree slash-slash lines: 74` and `main slash-slash lines: 74`. isimported matches whole lines (`[[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]`, `:1406`). It has three callers. check_fix gates on `pathform`, whose form excludes a leading `/` (`scripts/dev-cycle.sh:179`, lib header `:192-193`). floor takes "the path as the merge result stores it" (`:1462`), and a git tree path never starts with `/`. The third caller is truthwalk (`:1443`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1275`, `:1382`, `:1400-1409`, `:1443`, `:1490`; `scripts/dev-cycle.sh:179-185`; probe2.sh (2026-10-09T16:50:46Z, exit 0), logs/probe2.log

---

## Claim 8: "each a repo-relative directory joined under every reader root or, led by /, an absolute one joined as it is ...: one repo-relative path per line, or // and the absolute path for a name below no root ... With IMPORT_WHOLE set, each line on stdin is one name, taken whole (no prefixes, no blanks)"

**Location:** `scripts/lib/dev-cycle-read.sh:776-784`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output format, the directory join and whole mode's no-prefix, no-trim, no-blank reading. It does not establish whole mode's handling of invalid UTF-8: the python3 step still appends a decoded spelling as an extra line, which is a superset.
**Legibility-target:** for-orchestrator-synthesis

Whole mode swaps the blank-making sed script for `s=(-e '')` (`:1105`) and runs `if (whole) { emit($0, 1); next }` (`:970`), with keep=1, so no trim. probe1.log `== 4` prints `docs/a b.md ` (trailing space kept) and `//etc/x\ty` as whole lines. With DIRS `"" /alt`, probe1.log prints both `docs/x.md` (joined under the root) and `//alt/docs/x.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:865`, `:970`, `:1105`; probe1.log `== 4`, `-- DIRS`

---

## Claim 9: "It also reads ROOT_REAL and import_readers' IMPORT_ROOTS, IMPORT_HOMES and IMPORT_DOTNEST, calling it (which sets those and the IMPORT_HOME* globals in the caller's shell unless called in a subshell; its refusal fails this call)"

**Location:** `scripts/lib/dev-cycle-read.sh:785-787`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the memo's reach in the caller's shell and in a subshell. It does not cover the brief's shorthand "outside a walk it lists the registry once", which holds only for calls made in the caller's shell.
**Legibility-target:** for-orchestrator-synthesis

`import_readers || return 1` (`:1102`). The variables go to awk unchanged (`IT_ROOTS="$IMPORT_ROOTS" ... IT_DOTNEST="$IMPORT_DOTNEST"`, `:1123`). A git shim counted `git worktree list` calls (probe1.log `== 5`):
- `same-shell calls: 1` for two direct calls;
- `pipe-subshell calls: 2` for two `printf | import_targets` calls, the subshell case the header names;
- `after import_readers, subshell calls: 0`;
- `refused rc=1` with IMPORT_READER_WHY set.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1043-1050`, `:1102`, `:1123-1124`; probe1.log `== 5`

---

## Claim 10: "made absolute (ROOT/DIR/name for each reader root and each of $1 and the further directories, or DIR/name for one led by /, unless the name starts with /)"

**Location:** `scripts/lib/dev-cycle-read.sh:811-812`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers emit's join for relative names. It does not establish the ~/ branch (unchanged).
**Legibility-target:** for-author

`for (i = 0; i <= nd; i++) if (substr(dirs[i], 1, 1) == "/") put(dirs[i] "/" c); else for (r = 1; r <= nr; r++) put(roots[r] "/" dirs[i] "/" c)` (`:865`). The test at `test/scripts/build-loop-check.bats:631` expects `//opt/d/a.md`, and its line 640 asserts no `a.md` line. It passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:861-865`; build-loop-check.tap

---

## Claim 11: "a name below no reader root (...) is printed on the second channel, and any other relative to each root holding it but an outer one whose path down to a nested root holding it has a dot component"

**Location:** `scripts/lib/dev-cycle-read.sh:814-820`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers put's projection loop. It does not establish case-insensitive matching (a named exception).
**Legibility-target:** for-author

`nho = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i])) h[++nho] = i` and the dotnest skip (`:892-896`), then `if (nho == 0) show("/" out)` (`:899`). The test at `:631` asserts that `n.md` prints and `.claude/wt-b/n.md` does not.

**Evidence:** `scripts/lib/dev-cycle-read.sh:891-899`; build-loop-check.tap

---

## Claim 12: "It returns 1 when sed, python3, awk or import_readers fails (an empty ROOT_REAL, or refused settings, among its reasons), when a ~/ name appears and the home is not absolute, or when ..."

**Location:** `scripts/lib/dev-cycle-read.sh:836-839`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the import_readers-derived failures (empty ROOT_REAL, `/`, refused settings). It does not re-test the unchanged budget and ~/ branches.
**Legibility-target:** for-author

import_readers runs `[[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1` (`:1053`) and refuses `/` (`-n "${p//\//}"`, `:1070`). The test at `:631` counts two `rc=1` lines, for ROOT_REAL `/` and `""`. probe1.log shows `refused rc=1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1053`, `:1070`, `:1077`, `:1102`; build-loop-check.tap; probe1.log `== 5`

---

## Claim 13: "an absolute directory (a file below no root) is the one directory it names."

**Location:** `scripts/lib/dev-cycle-read.sh:862-865`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers emit's absolute-dirs branch. It does not establish that a walk ever passes an absolute DIRS entry (none does: prompt_bases yields repo-relative ones, and outside files are never starts).
**Legibility-target:** for-author

See Claim 10's quote. probe1.log `-- plain, WORK set` gives only `//<o>/docs/x.md`-form lines for a file in `<o>`, with no root-joined copy.

**Evidence:** `scripts/lib/dev-cycle-read.sh:865`; probe1.log `== 2`

---

## Claim 14: "A quoted text that spans lines can resolve to a name holding a newline, which no file a walk admits has (and a printed one would split in two)."

**Location:** `scripts/lib/dev-cycle-read.sh:880-882`
**Type:** Invariant
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the outside admission rule and both walks on a fixture whose AGENTS.md carries a quoted mention spanning lines that names an outside file with a newline in its name. It does not establish that Claude Code's mention reader reaches that file in a session: the superset statement models it as a candidate (`:803-806`).
**Legibility-target:** for-orchestrator-synthesis

The claim held while the walks admitted only repo files: the main walk refuses any newline-named repo name (`:1312`, `:1329`). This branch added `outside_ok() { [[ -f "$1" && -r "$1" ]]; }` (`:1158`), which admits such a file outside the repo. probe2.log: `-- outside_ok on the newline name` `rc=0`. The parser still drops the name (`if (index(out, "\n") || out == "") return`, `:882`). So the outside file `<o>/a\nb.md` is never read, and the repo file it imports goes unseen: `tree docs/q.md: -`, `tree walk ok`, `main docs/q.md: -`, `main walk ok` (probe2.log). A sibling outside file on the same line is followed (`docs/r.md: imported`). This is a false negative inside the walks' own model, which reads `@"` text "to its closing quote on that line or a later one" (`:803-805`).

It is not a regression: main dropped every outside name. It contrasts with A2's fix, which fails the walk on a newline *real* path (`:1142`), where this *spelled* newline is dropped silently. Precise version: "which no repo file a walk admits has; an outside file named with a newline is dropped (a false negative)". Alternatively, make the drop fail the walk when the spelling lies below no root.

**Evidence:** `scripts/lib/dev-cycle-read.sh:803-806`, `:880-882`, `:975`, `:1142`, `:1158`; probe2.sh (2026-10-09T16:50:46Z, exit 0), logs/probe2.log

---

## Claim 15: put returns on `out == ""` (a name resolving to `/` prints nothing)

**Location:** `scripts/lib/dev-cycle-read.sh:882`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `@/`. It does not establish that a `/` line would have been harmful (it would print a bare `/`, which import_work does not read as a trailer).
**Legibility-target:** for-author

probe1.log `== 1`: the input `@/123 @/opt/5 @docs/7 @/` prints no bare `/` line before the trailer `/360`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:879-882`; probe1.log `== 1`

---

## Claim 16: "(dotnest, from import_readers)"

**Location:** `scripts/lib/dev-cycle-read.sh:884`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the table comes from. Its contents are Claim 22.
**Legibility-target:** for-author

The parser fills `dotnest` only from `ENVIRON["IT_DOTNEST"]` (`:962`), which import_targets passes as `IT_DOTNEST="$IMPORT_DOTNEST"` (`:1123`). import_readers builds it (`:1092-1095`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:962`, `:1092-1095`, `:1123`

---

## Claim 17: "Below no root: the second channel, / and the absolute path (so // leads it, and no repo name or work trailer can be read as one ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:897-899`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers names ending in digits, the `//N` edge and outputs without a trailer. It does not establish behaviour if a root were spelled with a trailing slash. Such a spelling never matches and so never yields a `/`-led repo name, because `out` has no empty component.
**Legibility-target:** for-orchestrator-synthesis

`out` is built as `"/" st[i]` over non-empty components (`:879`), so a second-channel line is `//` plus at least one component. A repo name is `substr(out, length(pre[h[i]]) + 1)` past `root/` and never starts with `/`. probe1.log results:
- `iw rc=0 out=[//1 //12 //123] w=23`: the trailer is split off correctly beside names ending in digits.
- `no trailer iw rc=1` for `//123` and for `//5`: import_work's `"$iw_o" == "/$iw_w" || ... == *$'\n'"/$iw_w"` never matches a `//`-led line.

**Evidence:** `scripts/lib/dev-cycle-read.sh:879`, `:895`, `:899`, `:1163-1168`; probe1.log `== 1`

---

## Claim 18: "IT_DOTNEST: "I J" lines, root J nested in root I below a dot component"

**Location:** `scripts/lib/dev-cycle-read.sh:961-962`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parse and the orientation of `(outer, inner)` against put's lookup. It does not establish that the builder emits the right pairs (Claim 22).
**Legibility-target:** for-author

`if (split(dn[i], ab, " ") == 2) dotnest[ab[1], ab[2]] = 1` (`:962`). put skips outer root `h[i]` when `(h[i], h[j]) in dotnest` (`:894`). The builder emits `"$((i + 1)) $((n + 1))"` with `i` the shorter, outer root (`:1093`). The orientation matches main's `dotnest[i, j]`, where `pre[j]` was the longer one.

**Evidence:** `scripts/lib/dev-cycle-read.sh:894`, `:962`, `:1093`

---

## Claim 19: "IT_WHOLE: each line is one name, read as written (a real path a walk projects)."

**Location:** `scripts/lib/dev-cycle-read.sh:969-970`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 8's whole-mode half.
**Legibility-target:** for-author

`if (whole) { emit($0, 1); next }` (`:970`). probe1.log `== 4` shows the result.

**Evidence:** `scripts/lib/dev-cycle-read.sh:964`, `:970`; probe1.log `== 4`

---

## Claim 20: "IMPORT_DOTNEST holds the parser's dotnest pairs over IMPORT_ROOTS (its comment in the body says how)."

**Location:** `scripts/lib/dev-cycle-read.sh:1008-1009`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header's pointer. It does not establish the table's correctness (Claim 22).
**Legibility-target:** for-author

The body comment sits at `:1090-1091` beside the builder, and the variable is cleared with the others at `:1050`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1050`, `:1090-1095`

---

## Claim 21: "Set only as a one-call prefix (import_outside's projection), never assigned by a caller; cleared here, so an inherited one cannot make every walk read its text as whole names ... IMPORT_LEFT and IMPORT_WORK_LEFT need no clearing: every walk sets both for each call."

**Location:** `scripts/lib/dev-cycle-read.sh:1031-1035`
**Type:** Invariant / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every assignment in scripts/ and every walk's import_targets/import_file call. It does not establish behaviour for a caller that sets IMPORT_WHOLE after sourcing (none does).
**Legibility-target:** for-orchestrator-synthesis

`rg` over the repo outside docs finds IMPORT_WHOLE assigned only at `:1035` (`IMPORT_WHOLE=""`) and as the prefix `IMPORT_WHOLE=1 import_targets /` (`:1145`), plus tests. probe1.log `== 3`: exported `IMPORT_WHOLE=1`, after sourcing `[]`, and `@docs/x.md` is read as text (its prefixes print). Mutant m1, which drops `:1035`, fails test 2 of the U2b3b2a filter (probe3.log). Every walk call site sets both budgets: `IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - work))` (`:1270`, `:1347`, `:1349`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1035`, `:1105`, `:1124`, `:1145`, `:1270`, `:1347`, `:1349`; probe1.log `== 3`; probe3.sh (2026-10-09T16:51:20Z, exit 0), logs/probe3.log `m1`

---

## Claim 22: "IMPORT_DOTNEST: the parser's dotnest pairs, "I J" lines by 1-based index into IMPORT_ROOTS: J lies below I through a dot component. Built once here, not in every parser process" (and no trailing newline; equal to main's awk test)

**Location:** `scripts/lib/dev-cycle-read.sh:1090-1095`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 3,000 random root sets (1-6 roots, nested, with dot, glob, space and multibyte components) in the C locale. It does not establish a UTF-8 locale run (the host has none). For valid UTF-8, a prefix match ending in `/` agrees by byte and by character.
**Legibility-target:** for-orchestrator-synthesis

The builder (`:1092-1095`, copied verbatim into probe5.sh) was compared with main's awk lines `if (length(pre[j]) > length(pre[i]) && index(pre[j], pre[i]) == 1 && index("/" substr(pre[j], length(pre[i]) + 1), "/.")) print i " " j`. The result was `trials=3000 with_pairs=1431 mismatches=0`, with no `TRAILING NEWLINE` line. The indices are 1-based over `rs_ro`, the same array printed into IMPORT_ROOTS (`:1088`) that awk splits from 1 (`:959`). The table is built in import_readers, past the memo check, so once per reader key.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1049`, `:1088`, `:1092-1095`, `:959-962`; probe5.sh (2026-10-09T16:52:13Z, exit 0), logs/probe5.log

---

## Claim 23: "The reader set and its refusal are import_readers' alone, so refused settings fail every call (...); within a walk it is memoized and forks nothing."

**Location:** `scripts/lib/dev-cycle-read.sh:1099-1101`
**Type:** Architectural / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the single source and the memo hit in walk subshells. It does not establish that import_home forks nothing on a HEAD-changed key (it recomputes only when HOME changes).
**Legibility-target:** for-orchestrator-synthesis

import_targets no longer holds a `roots="${ROOT_REAL:-}"` fallback. Its one reader-set line is `import_readers || return 1` (`:1102`). On a memo hit, import_readers returns at `:1049` after `import_home` (key check, `return 0`, `:995`) and `import_readers_key` (assignments only). probe1.log: `after import_readers, subshell calls: 0`, and `refused rc=1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:993-999`, `:1039-1049`, `:1102`; probe1.log `== 5`

---

## Claim 24: "import_outside FILE [DIRS...]: ... read from the file system against its own directory and each DIRS entry ...; when its real path differs (a symlink on the way), that path is also projected whole (IMPORT_WHOLE), so a link into a reader root reads as an import of the repo path and one to another outside file as that file, which the walk then reads again under its real path. For a walk ...: the two trailers are summed into one, and each call may spend all that a walk has left, so the walk's own import_work check is what bounds the pair."

**Location:** `scripts/lib/dev-cycle-read.sh:1126-1135`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the plain, link-into-repo, link-to-outside and DIRS cases and the trailer sum. It does not establish that IMPORT_LEFT is also per call (each call may print up to it as well; the walk's `used` check at `:1273`/`:1380` bounds that too).
**Legibility-target:** for-orchestrator-synthesis

`a="$(capped_read < "$1" | import_targets "${d:-/}" "${@:2}")" && import_work a w`, and then for `[[ "$r" != "$1" ]]`, `b="$(printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /)" && import_work b w`, printing `"/$w"` (`:1144-1146`). probe1.log:
- `-- link into repo` gives `docs/x.md`, `/97`;
- `-- link to outside` gives `//<o>/real.md`, `/91`;
- `-- DIRS` (`"" /alt`) gives both `docs/...` and `//alt/...` lines.

Both inner calls inherit the walk's single IMPORT_WORK_LEFT, and the walk then runs `import_work out work` against IMPORT_WORK_MAX (`:1270-1271`, `:1347-1348`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1140-1147`, `:1163-1168`, `:1270-1273`, `:1347-1348`; probe1.log `== 2`

---

## Claim 25a: "It returns 1 when IMPORT_WORK_LEFT is unset or empty (no trailer to sum), when realpath, a read or import_targets fails, or on a real path holding a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:1135-1138`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed case under pipefail, which both walks set. It does not establish a failed `capped_read` under a caller without pipefail (the pipeline would then report import_targets' status).
**Legibility-target:** for-orchestrator-synthesis

probe1.log: `WORK unset ... rc=1`, `WORK empty ... rc=1`, `missing` (realpath error) `rc=1`, and `dir` (`head: error reading ... Is a directory`) `rc=1`. Mutant m2, which restores `$(realpath -e ...)`, fails the newline test (probe3.log). The list now matches i2's precise version (H1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1142-1146`; probe1.log `== 2`; probe3.log `m2`

---

## Claim 25b: "so a file that changed after the walk admitted it fails the walk rather than being skipped."

**Location:** `scripts/lib/dev-cycle-read.sh:1138-1139`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers removal, a swap to a directory and a newline real path after admission. It does not establish any check on content edits, which are read normally, or on a FIFO, which stalls (Claim 3).
**Legibility-target:** for-author

The changes that make a listed step fail do fail the walk: removal (`rc=1`), a directory (`rc=1`) and a newline real path (test `:660`). An edit to the file's text is simply read (Claim 5). A FIFO swap blocks (`rc=124` under timeout) and does not fail. Read alone, "a file that changed ... fails the walk" is broader than the code. Precise version: "so a file removed, made unreadable or swapped for a non-file after admission fails the walk rather than being skipped (a FIFO stalls instead; an edit is read)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1142-1144`, `:724-733`; probe1.log `== 2`

---

## Claim 26: `nul_list rl realpath -ez -- "$1" && [[ ${#rl[@]} -eq 1 && "${rl[0]}" != *$'\n'* ]] || return 1` refuses a real path holding a newline

**Location:** `scripts/lib/dev-cycle-read.sh:1142`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an interior newline through the test at `:660`. It does not re-run i2's trailing-newline edge (unchanged code since).
**Legibility-target:** for-orchestrator-synthesis

The test at `:660` passes at HEAD and fails under m2 (`not ok 3 an outside link whose real path holds a newline ...`, probe3.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1142`; probe3.log `m2`; build-loop-check.tap

---

## Claim 27: "import_file FILE DIR [DIRS...]: ... a repo path (DIR and DIRS as import_targets takes them), or an absolute one through import_outside (its own directory in place of DIR, and DIRS). An absolute FILE needs IMPORT_WORK_LEFT set, as every walk sets it, and returns 1 without it; a caller treats that 1 as a failed walk, never as a file to skip"

**Location:** `scripts/lib/dev-cycle-read.sh:1148-1153`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both call sites and the unset-budget return. It does not establish U2b3b2b's future callers.
**Legibility-target:** for-orchestrator-synthesis

`import_file() { if [[ "$1" == /* ]]; then import_outside "$1" "${@:3}"; else capped_read < "$1" | import_targets "${@:2}"; fi; }` (`:1154`). Both callers end `|| { IMPORTED=error; return 1; }` (`:1271`) and `|| { IMPORTED_MAIN=error; return 1; }` (`:1348`). For the unset budget, probe1.log shows `WORK unset rc=1`. Mutant m3 (`import_outside "$1"`) fails the `:660` test (probe3.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1154`, `:1270-1271`, `:1347-1348`; probe1.log; probe3.log `m3`

---

## Claim 28a: "outside_ok PATH: whether a walk reads PATH, a name below no reader root: a readable regular file (the one admission rule both walks apply). Anything else is skipped"

**Location:** `scripts/lib/dev-cycle-read.sh:1155-1157`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the predicate and that the two `//` arms are its only users. It does not establish that the admitted set matches what Claude Code loads (28b), nor names the parser drops before admission (Claim 14).
**Legibility-target:** for-orchestrator-synthesis

`outside_ok() { [[ -f "$1" && -r "$1" ]]; }` (`:1158`), called at `:1278` and `:1386` only. Outcomes are in Claim 2's list. `-f` follows symlinks: `ln.md rc=0`, `in.md rc=0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1158`, `:1278`, `:1386`; probe1.log

---

## Claim 28b: "a session in this container cannot load it either." (also the title of `test/scripts/build-loop-check.bats:671`: "as a session cannot load it")

**Location:** `scripts/lib/dev-cycle-read.sh:1157`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond i1's verdict. It does not establish Claude Code's behaviour on a FIFO, a directory or an unreadable file.
**Legibility-target:** for-orchestrator-synthesis

paraphrased — no quote available because the claim is about Claude Code's file reader, which is outside this repository. It needs a probe inside a Claude Code session. Already declined (override row 567, Won't-Fix), and its substance is unchanged, so it is not re-raised.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1155-1158`; `docs/reviews/override-log.md:567`

---

## Claim 29: "import_work OUT TOTAL: strips the parser's work trailer (its last line, "/N", ...; a repo-relative name never starts with /, and a second-channel name starts with //) ... It returns 1 when the trailer is missing or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:1159-1162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 17.
**Legibility-target:** for-author

`[[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1` (`:1165`). probe1.log `== 1` shows it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1163-1168`; probe1.log `== 1`

---

## Claim 30: "A name below no root (//PATH) is read where it lies, when a session could load it." / "Below no root: read from the file system in phase 2, as the checkout is." (the main walk reads outside files only through tq, never through main's arms or main_checkout)

**Location:** `scripts/lib/dev-cycle-read.sh:1277`, `:1385`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the main walk's routing of `//` lines. It does not establish the "could load" half (28b).
**Legibility-target:** for-orchestrator-synthesis

In the main arm, `... && tq+=("$p"); continue; }` (`:1386`) runs before `main_checkout ent pok "$p"` (`:1388`). The path is absolute and git tree names never are, so `ent` never holds it. When popped (`queue=("${tq[@]}")`, `:1343`), it reaches `case "${ent[$f]-checkout}"` → `checkout)` → `import_file` (`:1346-1347`) and never the blob arms.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1309-1313`, `:1342-1349`, `:1383-1391`

---

## Claim 31: "a blob, checkout file or outside file cannot be read (import_outside)"

**Location:** `scripts/lib/dev-cycle-read.sh:1291`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the main walk's handling of import_outside's 1. It does not repeat Claim 25a.
**Legibility-target:** for-author

`checkout) out="$(... import_file "$f" "$d" "${xs[@]}")" && import_work out work || { IMPORTED_MAIN=error; return 1; }` (`:1347-1348`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1347-1348`

---

## Claim 32: "Phase 2 begins when queue empties: tq's checkout files and outside files (absolute paths, never main's) then join it, and a path main lacks reads the checkout."

**Location:** `scripts/lib/dev-cycle-read.sh:1297-1298`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 30.
**Legibility-target:** for-author

`[[ $qi -lt ${#queue[@]} ]] || { queue=("${tq[@]}"); tq=(); qi=0; }` (`:1343`), with outside paths entering tq only at `:1386`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1342-1343`, `:1386`

---

## Claim 33: "import_readers' dotnest pairs omit only such paths: keep the two equal"

**Location:** `scripts/lib/dev-cycle-read.sh:1427`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the omitted outer spellings against truthrule's dot word. It does not establish isimported's matching of the inner spelling.
**Legibility-target:** for-author

A pair `I J` exists only when `"/${t#"$p"}" == *"/."*` (`:1093`), meaning J's path below I has a dot-led component. The omitted outer name is that path plus the rest, so `"/$1" == */.*` (`:1427`) refuses it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:894-895`, `:1093`, `:1427`

---

## Claim 34: Test title "the parser prints a name below no reader root as //PATH, joins a relative name to an absolute directory alone, reads IMPORT_WHOLE lines whole, takes import_readers' roots outside a walk, and fails for a ROOT_REAL of / or empty"

**Location:** `test/scripts/build-loop-check.bats:631`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause against the test body. It does not establish coverage of the IMPORT_DOTNEST trailing newline (no test pins it; Claim 22 executed it).
**Legibility-target:** for-author

The body asserts `//etc/x.md`, `//opt/d/a.md`, the worktree names `docs/w.md` and `n.md`, `whole docs/a b.md`, `whole //etc/x y`, and two `rc=1`. It passes at HEAD and fails on main's lib (probe3.log, `not ok 1`). The comment at `:639` ("A relative name stays in its absolute directory; a dot-nested root's outer spelling is not printed") matches the negative grep at `:640`.

**Evidence:** `test/scripts/build-loop-check.bats:631-641`; build-loop-check.tap; probe3.log

---

## Claim 35: "against the home's directory, not the repo"

**Location:** `test/scripts/build-loop-check.bats:649`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's `$HOME/h.md` with `@docs/z.md`.
**Legibility-target:** for-author

`want docs/z.md -` (`:654`) passes in both walks. `$HOME/docs/z.md` is outside every root and absent, so it is skipped.

**Evidence:** `test/scripts/build-loop-check.bats:649-654`; build-loop-check.tap

---

## Claim 36: "An inherited IMPORT_WHOLE is cleared when the lib is sourced, so text is still read as text (i1 architecture A1)."

**Location:** `test/scripts/build-loop-check.bats:655-656`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exported-before-source case.
**Legibility-target:** for-author

Under m1 the test fails (`not ok 2 both walks follow ...`, probe3.log), so it pins the clearing line.

**Evidence:** `test/scripts/build-loop-check.bats:655-656`; probe3.log `m1`

---

## Claim 37: Test title "an outside link whose real path holds a newline fails the tree walk (the main walk already fails on the newline-named checkout file); import_file reads an outside file against its own directory and the DIRS it is given"

**Location:** `test/scripts/build-loop-check.bats:660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the retitled claim (H2) and the DIRS half. The main half is not attributed to the link, as the title now says.
**Legibility-target:** for-author

probe7.log: an untracked `docs/a\nb.md` with no outside link gives `main walk failed` and `tree walk ok`, through checkout_md's `[[ "$f" != *$'\n'* ]] || return 1` (`scripts/lib/dev-cycle-read.sh:1329`). Mutants m2 and m3 each fail this test (probe3.log).

**Evidence:** `test/scripts/build-loop-check.bats:660-669`; `scripts/lib/dev-cycle-read.sh:1329`; probe7.sh (2026-10-09T16:54:28Z, exit 0), logs/probe7.log; probe3.log

---

## Claim 38: "Read as the repo's docs/t.md, so @u.md resolves against docs/."

**Location:** `test/scripts/build-loop-check.bats:676`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the projection's route: the b-part prints `docs/t.md`, which the walk reads against `docs`.
**Legibility-target:** for-author

`want docs/u.md imported` passes in both walks. The a-part reads tl.md against the outside directory and yields only `//<o>/u.md`-form names (Claim 24's mechanism).

**Evidence:** `test/scripts/build-loop-check.bats:671-684`; `scripts/lib/dev-cycle-read.sh:1144-1145`; build-loop-check.tap

---

## Claim 39: The sourcing inventory lists import_outside, import_file, outside_ok, IMPORT_DOTNEST and IMPORT_WHOLE

**Location:** `test/scripts/dev-cycle.bats:1110`, `:1114`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence of the names after sourcing.
**Legibility-target:** for-author

The dev-cycle suite runs 79 tests, all ok (logs/dev-cycle.tap, exit 0).

**Evidence:** `test/scripts/dev-cycle.bats:1108-1117`; dev-cycle.tap (2026-10-09T16:47:37Z, exit 0)

---

## Claim 40: Commit 55490d15: "Tests: three new (...), each red on main; build-loop-check 119, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2."

**Location:** commit 55490d15 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers red-on-main for the three tests (55490d15's test file over main's lib) and the counts as `@test` totals at that commit. It does not re-run the full suites at 55490d15.
**Legibility-target:** for-orchestrator-synthesis

probe3.log gives `55490d15 tests on main's lib: rc=1 0 ok, 3 not ok` and `55490d15 tests on 55490d15's lib: rc=0 3 ok`. The `@test` counts at 55490d15 are `119 20 79 2 2`.

**Evidence:** probe3.log; `git show 55490d15:<suite> | grep -c '^@test'`

---

## Claim 41: Commit 55490d15: "Over this worktree both walks give main's 64 names in about the same time (0.7-0.8 s); no walked file here holds an outside name."

**Location:** commit 55490d15 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers this worktree at HEAD as of 2026-10-09T16:51:54Z (load average 0.52). Timings are load-dependent.
**Legibility-target:** for-author

probe4.log, HEAD lib: `walk=main ... lines=64 slash=0 secs=0.77` and `walk=tree ... lines=64 slash=0 secs=0.60`. main's lib: `64`, `0.82` and `64`, `0.58`.

**Evidence:** probe4.sh (cwd the worktree, read-only, exit 0), logs/probe4.log

---

## Claim 42: Commit 55490d15: "a ROOT_REAL of / now fails a direct call too, as it always failed the walks."

**Location:** commit 55490d15 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main's import_readers refusal and HEAD's direct call (Claim 12).
**Legibility-target:** for-author

main's import_readers already held `[[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1` (`git show main:scripts/lib/dev-cycle-read.sh`, line 1037). main's import_targets fell back to `roots="${ROOT_REAL:-}"` outside a walk, so a direct call accepted `/` (the deleted test asserted `rc=0`).

**Evidence:** `main:scripts/lib/dev-cycle-read.sh:1037`, `:1058-1064`

---

## Claim 43: Commit 55490d15 Notes: "the second channel is always on (every caller is a walk or a test)."

**Location:** commit 55490d15 message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers scripts/ and test/ at HEAD.
**Legibility-target:** for-author

paraphrased — no quote available because the claim covers the absence of other callers: `rg 'import_targets|import_outside|import_file'` outside docs finds calls only at `scripts/lib/dev-cycle-read.sh:1144`, `:1145`, `:1154`, `:1270`, `:1347`, `:1349` and in test/.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1144-1154`, `:1270`, `:1347-1349`

---

## Claim 44: Commit 18fba03d: "The three fix mutants each fail a test."

**Location:** commit 18fba03d message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers m1 (no IMPORT_WHOLE clearing), m2 (old `$(realpath -e)`) and m3 (DIRS dropped), re-applied at HEAD.
**Legibility-target:** for-orchestrator-synthesis

probe3.log: `m1 ... 1 not ok` (test 2), `m2 ... 1 not ok` (test 3), `m3 ... 1 not ok` (test 3).

**Evidence:** probe3.sh (2026-10-09T16:51:20Z, exit 0), logs/probe3.log

---

## Claim 45: Commit 18fba03d: "build-loop-check 120, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2. 213 code lines against main."

**Location:** commit 18fba03d message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at HEAD, where the suites are unchanged since 18fba03d (`@test` totals equal), and 213 as insertions plus deletions under scripts/ and test/.
**Legibility-target:** for-author

The suites run at HEAD gave 120/120, 20/20, 79/79, 2/2 and 2/2 ok (logs/*.tap; `test/fixture-hermeticity.bats` lives under test/, not test/scripts/). `git diff --numstat main...18fba03d -- scripts test` gives `165+48=213`. At HEAD it is `174+50=224`, all of the extra being comment lines (Claim 46).

**Evidence:** logs/build-loop-check.tap, build-loop-read.tap, dev-cycle.tap, fixture-git-env.tap, fixture-hermeticity.tap (2026-10-09T16:46:51Z-16:49:34Z, each exit 0)

---

## Claim 46: Commit 82bb5281: "Comments and a test title only; suites unchanged."

**Location:** commit 82bb5281 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `18fba03d..82bb5281` (f7a96eed included) under scripts/ and test/.
**Legibility-target:** for-author

With `git diff 18fba03d 82bb5281 -- scripts test`, filtering out `#`-led lines leaves only the one `@test "an outside link ..."` title change. The `@test` counts at 82bb5281 are `120 20 79 2 2`.

**Evidence:** `git diff 18fba03d 82bb5281 -- scripts test`; Claim 45's suite logs

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 14** (`scripts/lib/dev-cycle-read.sh:880-882`): "which no file a walk admits has" stopped holding once outside_ok admits outside files. An outside file named with a newline, reached by a quoted mention spanning lines, is dropped silently, and its imports into the repo go unseen while both walks report ok (executed). Fix the comment, or fail the walk on a below-no-root spelling that holds a newline, as A2 does for a real path.

### Mostly Accurate
- **Claim 25b** (`scripts/lib/dev-cycle-read.sh:1138-1139`): "a file that changed after the walk admitted it fails the walk" holds for removal or a swap to a non-file. An edit is read as it is, and a FIFO stalls.

### Unverifiable
- **Claim 28b** (`scripts/lib/dev-cycle-read.sh:1157`, test title `:671`): what Claude Code loads for a non-regular or unreadable file needs a session probe. Already declined (override row 567), not re-raised.

---

## Goal-Alignment Note

The branch's goal is that both walks follow imports through files below no reader root and fail closed on what they do not model. Executed checks confirm it for every shape the tests name: absolute, `~/` and `../` names, chains back into the repo, links into a root or to another outside file, skips for missing, unreadable and non-regular files, and the budget failures. The dotnest move (H2) is equivalent to main over 3,000 random root sets. The single reader-set source (H5/A1) holds, and its memo hits in walk subshells. All four suites pass at HEAD, and every commit-message count, mutant and red-on-main claim reproduces.

The one gap against brief item 10 (fail-open) is Claim 14: a fail-open inside the walks' own model, and new in kind, since outside_ok is what now admits such a file. It is not a regression, because main dropped every outside name. It is narrow, needing an outside file whose name holds a newline plus a quoted mention spanning lines. An orchestrator may weigh it as 🟢 Consider (Low) with a comment fix, or as a one-line refusal symmetric with A2. Nothing else found makes the floor answer "not imported" for a path the walks' model says a session loads, beyond the already-declined absent-home exception (row 558).
