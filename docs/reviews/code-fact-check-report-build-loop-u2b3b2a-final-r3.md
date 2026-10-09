Commit: 82bb5281
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b3b2a (claude-workflows, branch `feat/build-loop-u2b3b2a`)
**Scope:** `git diff main...HEAD -- scripts test` at HEAD 82bb5281 (scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats), plus the code commits' messages (55490d15, 18fba03d, f7a96eed, 82bb5281). Final confirming pass, replicate r3 of k=3.
**Checked:** 2026-10-09
**Total claims checked:** 40
**Summary:** 37 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Context read first: `docs/reviews/hallucination-patterns.md` (no logged pattern matches a claim here), the iteration 1-2 rubric `docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b2a.md`, the `feat/build-loop-u2b3b2a` override rows at the end of `docs/reviews/override-log.md`, and the i2 fact-check report. Declined rows are not re-raised; where a claim touches one, the row is named.

Execution provenance. Every probe ran from a fresh `mktemp -d` directory under `/tmp` (scripts start with `set -eu`, create and `cd` into their own temp dir, and run `git init`/`commit` only after checking `pwd` lies under it), with `GIT_CONFIG_GLOBAL=/dev/null` and a temp `HOME`. Scripts and captured output are under `/tmp/claude-1000/-workspace/715dcdb7-5140-4bd1-a115-cbeff3508ce5/scratchpad/u2b3b2a-i3/fact-check-r3/` (abbreviated `$FC` below). Each log's first line is its UTC start time, and its last line is the script's exit code.

| Log | Command (cwd) | Exit | Start (UTC) |
|---|---|---|---|
| `$FC/suite-*.log` (5 files) | `$FC/run-suites.sh`: `LC_ALL=C LANG=C TMPDIR=$T bats <suite>` for build-loop-check, build-loop-read, dev-cycle, fixture-git-env, fixture-hermeticity (cwd the worktree) | 0 each | 16:47:57-16:49:13 |
| `$FC/red-on-main.log` | `$FC/red-on-main.sh`, `$FC/red-on-main2.sh`: `git archive main` plus the branch's build-loop-check.bats, then the four branch tests by `-f` (cwd a temp copy) | 0 | 16:48:09 |
| `$FC/probe1.log` | `$FC/probe1.sh` (parser, import_work, IMPORT_WHOLE, import_outside, outside_ok; temp fixture repo) | 0 | 16:48:34 |
| `$FC/probe2.log` | `$FC/probe2.sh` (registry listings through a git PATH shim, both walks over an outside chain, dotnest old-vs-new over 300 random root sets) | 0 | 16:49:08 |
| `$FC/probe3.log` | `$FC/probe3.sh` (diff 18fba03d..82bb5281, numstat line counts, main lib with ROOT_REAL=/) | 1 (the last section failed because `bc` is missing; it was re-run in probe4) | 16:50:29 |
| `$FC/probe4.log` | `$FC/probe4.sh` (unprimed ROOT_REAL=/ on the main and branch libs, the import_outside summed budget, both walks over this worktree, read-only) | 0 | 16:50:55 |
| `$FC/mutants.log` | `$FC/mutants.sh`: `git archive HEAD` copy, one mutation each (A1, A2, A4), then the pinning test by `-f` | 0 | 16:51:58 |

---

## Claim 1: "prints a path below no reader root on its second channel: import_readers"

**Location:** `scripts/lib/dev-cycle-read.sh:679`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree-walk header's description of the parser's output for absolute and resolved names below no root. It does not establish anything about `~/` names under an absent reader home (override row, security i1 F1).
**Legibility-target:** for-orchestrator-synthesis

`if (nho == 0) show("/" out)` (`scripts/lib/dev-cycle-read.sh:899`) prints `/` plus the absolute path, which itself starts with `/`. probe1 P1 printed `//1`, `//12`, `//123` and `//9` for `@/123 @/9/`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:892-899`, `$FC/probe1.log`

---

## Claim 2: "Both walks follow an import to a file below no reader root ... when outside_ok admits it, reading it from the file system ... through import_outside (the main walk in phase 2); one that is missing, unreadable or not a regular file here is skipped."

**Location:** `scripts/lib/dev-cycle-read.sh:720-723`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' `//` arms, the admission rule and an outside chain (link to an outside file, then back into the repo). It does not establish behaviour when a file changes between admission and read (Claims 5 and 23).
**Legibility-target:** for-orchestrator-synthesis

Tree arm: `[[ "$p" != //* ]] || { p="${p#/}"; outside_ok "$p" && [[ "$seen" != ... ]] && seen+="$p"$'\n' && queue+=("$p"); continue; }` (`:1278`). Main arm: `... [[ -z "${seen[$p]+set}" ]] && outside_ok "$p" && seen[$p]=1 && tq+=("$p"); continue; }` (`:1386`). A false `outside_ok` short-circuits to `continue`, so the name is skipped. probe2 Q1: AGENTS.md → outside `o.md` → outside link `l.md` → `r.md` → `docs/y.md`. Both walks returned rc=0 and reported `docs/y.md imported`. The suite test "an outside name whose real path lies in the repo..." (missing, mode 000 and directory names skipped) passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1276-1281`, `scripts/lib/dev-cycle-read.sh:1383-1392`, `$FC/probe2.log`, `$FC/suite-build-loop-check.log`

---

## Claim 3: "Known exceptions: a file a session elsewhere can load that this container cannot see (...), and a regular file swapped for a FIFO after its admission, which stalls the read (as a checkout file can)."

**Location:** `scripts/lib/dev-cycle-read.sh:723-728`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the read path that a FIFO swap would block (an open with no writer) and the `-f && -r` test that skips an invisible home. It does not establish that Claude Code itself loads or skips a FIFO (override row "a session cannot load it either", Won't-Fix). The FIFO stall was not executed here.
**Legibility-target:** for-orchestrator-synthesis

`a="$(capped_read < "$1" | import_targets ...)"` (`:1144`) opens the file with no timeout after `realpath -ez` (`:1142`), which succeeds on a FIFO. A file that is missing in this container fails `outside_ok() { [[ -f "$1" && -r "$1" ]]; }` (`:1158`) and is skipped. Both are named exceptions (override rows security i1 F1 and F2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1142-1144`, `scripts/lib/dev-cycle-read.sh:1158`, `docs/reviews/override-log.md` (rows dated 2026-10-09)

---

## Claim 4: "A large outside file a prefix names (@/usr/bin/python3.md reads /usr/bin/python3) or a very long absolute name (each prefix prints, about L*L/2 bytes ...) can spend a walk's budget, which fails closed"

**Location:** `scripts/lib/dev-cycle-read.sh:728-732`
**Type:** Performance / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mechanism: each prefix of a token is emitted, an existing prefix file is admitted, and a spent budget returns 1. The budget numbers are not re-measured here; the override rows record executed measurements (performance i1 F1, F2).
**Legibility-target:** for-orchestrator-synthesis

`name = name ch; emit(name)` (`:942`) emits every prefix. `/usr/bin/python3` is a symlink to `python3.11` (`ls -la`), so `-f` follows it and `outside_ok` admits it. `show` exits 3 past `left` (`:904`), and both walks fail on `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { ...=error; return 1; }` (`:1273`, `:1380`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:904`, `scripts/lib/dev-cycle-read.sh:936-944`, `scripts/lib/dev-cycle-read.sh:1273`, `scripts/lib/dev-cycle-read.sh:1380`

---

## Claim 5: "The walk reads outside files as they are when it runs: one changed or removed during the walk is read as it then is (i2 security F2)."

**Location:** `scripts/lib/dev-cycle-read.sh:732-733`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the absence of any snapshot: the file is opened at read time. "Removed ... read as it then is" means the read finds no file and the walk fails. The race was not executed.
**Legibility-target:** for-orchestrator-synthesis

`nul_list rl realpath -ez -- "$1" && ... || return 1` (`:1142`) fails on a file removed after admission, and the walk turns the failure into `IMPORTED=error; return 1` (`:1271`). Changed content is read by `capped_read < "$1"` (`:1144`) as it then is.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1142-1146`, `scripts/lib/dev-cycle-read.sh:1270-1271`

---

## Claim 6: "(known issue A5; U2b3b2b's outside starts), nor at a start file only another registered checkout holds (U2b3b2b)" and ":829 ... U2b3b2b"

**Location:** `scripts/lib/dev-cycle-read.sh:735-736`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the unit name exists and that it owns outside seeds and other roots' start files. It does not establish that U2b3b2b is scheduled or will land.
**Legibility-target:** for-orchestrator-synthesis

The plan's line 305 reads: "**U2b3b2b, outside seeds and C1**: ... each other reader root's untracked and ignored start files), queued as absolute items through U2b3b2a's reader".

**Evidence:** `docs/working/plan-build-loop-handoff.md:305`, `scripts/lib/dev-cycle-read.sh:829`

---

## Claim 7: "The walks' lists (IMPORTED, IMPORTED_MAIN) also hold the second channel's lower-cased // names, which no repo path isimported asks for can match."

**Location:** `scripts/lib/dev-cycle-read.sh:737-738`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repo-relative query paths, which never start with `/`. It does not establish what happens if a caller passes a `//`-led string to isimported, which would match.
**Legibility-target:** for-orchestrator-synthesis

`lp="$(lower "$out")" ...; IMPORTED+="$lp"$'\n'` (`:1275`) appends the whole parser output, `//` lines included. probe2 printed lower-cased `//tmp/...` lines from `IMPORTED_MAIN`. isimported matches `*$'\n'"$lp"$'\n'*` (`:1405-1406`), so only a `//`-led query could hit them.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1275`, `scripts/lib/dev-cycle-read.sh:1382`, `scripts/lib/dev-cycle-read.sh:1400-1409`, `$FC/probe2.log`

---

## Claim 8: "each a repo-relative directory joined under every reader root or, led by /, an absolute one joined as it is ...: one repo-relative path per line, or // and the absolute path for a name below no root ... With IMPORT_WHOLE set, each line on stdin is one name, taken whole (no prefixes, no blanks)"

**Location:** `scripts/lib/dev-cycle-read.sh:776-784`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the directory joining, both output channels and whole mode. It does not establish whole mode's handling of a path holding invalid UTF-8: `import_targets` still appends the decoded copy (`:1114-1117`), a second name and so a superset.
**Legibility-target:** for-orchestrator-synthesis

`if (substr(dirs[i], 1, 1) == "/") put(dirs[i] "/" c); else for (r = 1; r <= nr; r++) put(roots[r] "/" dirs[i] "/" c)` (`:865`) and `if (whole) { emit($0, 1); next }` (`:970`). In the suite test (`build-loop-check.bats:631`) `@a.md` in `/opt/d` gives `//opt/d/a.md`, and whole input `docs/a b.md` stays one name. probe1 P3 printed `x y.md` as one line.

**Evidence:** `scripts/lib/dev-cycle-read.sh:862-865`, `scripts/lib/dev-cycle-read.sh:968-970`, `scripts/lib/dev-cycle-read.sh:1105`, `$FC/probe1.log`, `$FC/suite-build-loop-check.log`

---

## Claim 9: "also reads ROOT_REAL and import_readers' IMPORT_ROOTS, IMPORT_HOMES and IMPORT_DOTNEST, calling it (which sets those and the IMPORT_HOME* globals in the caller's shell unless called in a subshell; its refusal fails this call)"

**Location:** `scripts/lib/dev-cycle-read.sh:785-787`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call, the variables passed to awk and the refusal path. It does not establish the memo's behaviour across an `import_reset` (outside this unit's diff).
**Legibility-target:** for-orchestrator-synthesis

`import_readers || return 1` (`:1102`), then `IT_ROOTS="$IMPORT_ROOTS" IT_HOMES="$IMPORT_HOMES" IT_DOTNEST="$IMPORT_DOTNEST"` (`:1123`). probe4 S1: with ROOT_REAL=/, the branch lib returned rc=1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1097-1125`, `$FC/probe4.log`

---

## Claim 10: "made absolute (ROOT/DIR/name for each reader root and each of $1 and the further directories, or DIR/name for one led by /, unless the name starts with /) ... a name below no reader root ... is printed on the second channel, and any other relative to each root holding it but an outer one ... dot"

**Location:** `scripts/lib/dev-cycle-read.sh:811-819`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers emit's joins and put's projection, including the suite test's dot-nested `.claude/wt-b` root. It does not re-verify the superset claim against Claude Code's grammar (prior units).
**Legibility-target:** for-orchestrator-synthesis

Joins: emit at `:861` and `:865`. Projection: `for (j = 1; j <= nho; j++) if ((h[i], h[j]) in dotnest) break; if (j > nho) show(substr(out, length(pre[h[i]]) + 1))` (`:893-896`). The suite test asserts `n.md` is printed and `.claude/wt-b/n.md` is not.

**Evidence:** `scripts/lib/dev-cycle-read.sh:847-900`, `test/scripts/build-loop-check.bats:631-641`, `$FC/suite-build-loop-check.log`

---

## Claim 11: "It returns 1 when sed, python3, awk or import_readers fails (an empty ROOT_REAL, or refused settings, among its reasons), when a ~/ name appears and the home is not absolute, or when ... a work bound or ... IMPORT_LEFT"

**Location:** `scripts/lib/dev-cycle-read.sh:836-839`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed path to `return 1`. It does not establish that this list is exhaustive for a failing `printf` into the pipe.
**Legibility-target:** for-orchestrator-synthesis

`import_readers || return 1` (`:1102`) and `[[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1` (`:1053`). The awk exits are `exit 4` for a home that is not absolute (`:857`) and `exit 3` for the bounds (`:848`, `:904`). The suite test asserts `rc=1` twice, for ROOT_REAL `/` and `""`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1053`, `scripts/lib/dev-cycle-read.sh:1102-1124`, `test/scripts/build-loop-check.bats:636-638`, `$FC/suite-build-loop-check.log`

---

## Claim 12: "an absolute directory (a file below no root) is the one directory it names."

**Location:** `scripts/lib/dev-cycle-read.sh:862-865`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers relative names in an outside file. It does not establish anything for `~/` or absolute names, which never reach this loop.
**Legibility-target:** for-orchestrator-synthesis

This is the `:865` loop quoted in Claim 8. probe1 P4 resolved `@b.md` in `$O/link.md` to `//$O/b.md` only, with no root-joined spellings.

**Evidence:** `scripts/lib/dev-cycle-read.sh:865`, `$FC/probe1.log`

---

## Claim 13: `if (index(out, "\n") || out == "") return` (out == "" returns)

**Location:** `scripts/lib/dev-cycle-read.sh:882`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers names that resolve to `/` itself. It does not establish whether Claude Code imports anything for `@/` (a directory, which nothing loads).
**Legibility-target:** for-orchestrator-synthesis

Without the guard, `show("/" out)` (`:899`) would print a bare `/`, which reads like an empty work trailer. probe1 P1 fed `@/` and `@/..` and printed no `/` line. The only `/`-led single-slash line was the trailer `/51`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:879-882`, `$FC/probe1.log`

---

## Claim 14: "(dotnest, from import_readers)" (put) and "import_readers' dotnest pairs omit only such paths: keep the two equal" (truthrule)

**Location:** `scripts/lib/dev-cycle-read.sh:884`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the pairs come from import_readers and that a pair exists only when the outer spelling has a `/.` component, which the dot word refuses. It does not establish truthrule's other words.
**Legibility-target:** for-orchestrator-synthesis

The builder adds a pair only when `"/${t#"$p"}" == *"/."*` (`:1093`). The outer spelling is then `<inner-root-rel>/...` with a `/.`-led component, which `[[ "/$1" == */.* ]]` (`:1427`) refuses.

**Evidence:** `scripts/lib/dev-cycle-read.sh:884`, `scripts/lib/dev-cycle-read.sh:1092-1095`, `scripts/lib/dev-cycle-read.sh:1427`

---

## Claim 15: "Below no root: the second channel, / and the absolute path (so // leads it, and no repo name or work trailer can be read as one"

**Location:** `scripts/lib/dev-cycle-read.sh:897-899`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers import_work's parse, both walks' line loops and import_outside's summed trailer, including outputs ending in digits. It does not establish anything about a caller that reads parser output without import_work.
**Legibility-target:** for-orchestrator-synthesis

import_work accepts only `"$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w"` with digit-only `iw_w` (`:1165`). In probe1 P2, `//123⏎/5` → ok (t=5, `//123` kept) and `docs/9⏎/7` → ok. `//1` and `docs/1` alone (no trailer) → fail. A repo name is `substr(out, length(pre)+1)` with no leading `/` (`:895`). import_outside prints `${a:+"$a"} ${b:+"$b"} "/$w"` (`:1146`) after stripping both inner trailers, so one trailer remains.

**Evidence:** `scripts/lib/dev-cycle-read.sh:895-899`, `scripts/lib/dev-cycle-read.sh:1144-1146`, `scripts/lib/dev-cycle-read.sh:1163-1168`, `$FC/probe1.log`

---

## Claim 16: The dropped `roots[i] == "/"` arm (`pre[i] = roots[i] "/"`); a root of `/` is refused upstream

**Location:** `scripts/lib/dev-cycle-read.sh:959-960`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every path by which a root reaches IT_ROOTS (import_readers alone, Claim 20). It does not establish anything for a direct awk invocation outside import_targets.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1` (`:1070`) and `[[ -n "${rs_real[i]//\//}" ... ]] || return 1` (`:1077`) refuse `/` as written and as resolved. probe4 S1: ROOT_REAL=/ gives rc=1 on the branch.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1068-1077`, `$FC/probe4.log`

---

## Claim 17: "IMPORT_DOTNEST: the parser's dotnest pairs, "I J" lines by 1-based index into IMPORT_ROOTS ... Built once here, not in every parser process" (with the awk reader at :961-962)

**Location:** `scripts/lib/dev-cycle-read.sh:1090-1095`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers equality with main's awk test over 300 random root sets (duplicates, dot and `..` components, nesting), 1-based indexing in the same order the awk splits IT_ROOTS, and no trailing newline. It does not establish behaviour for a root holding a newline (refused at `:1070`).
**Legibility-target:** for-orchestrator-synthesis

`IMPORT_DOTNEST+="$((i + 1)) $((n + 1))"$'\n'` over `rs_ro`, which is printed as IMPORT_ROOTS in the same order (`:1088`), then `IMPORT_DOTNEST="${IMPORT_DOTNEST%$'\n'}"` (`:1095`). The awk reads it with `split(dn[i], ab, " ") == 2) dotnest[ab[1], ab[2]] = 1` (`:962`). probe2 Q2 compared main's formula (`length(pre[j]) > length(pre[i]) && index(pre[j], pre[i]) == 1 && index("/" substr(...), "/.")`) with the bash builder: `mismatches=0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:961-962`, `scripts/lib/dev-cycle-read.sh:1088-1095`, `$FC/probe2.log`

---

## Claim 18: "IMPORT_DOTNEST holds the parser's dotnest pairs over IMPORT_ROOTS (its comment in the body says how)."

**Location:** `scripts/lib/dev-cycle-read.sh:1008-1009`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header's pointer. Correctness of the pairs is Claim 17.
**Legibility-target:** for-orchestrator-synthesis

The body comment is at `:1090-1091`, quoted in Claim 17.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1008-1009`, `scripts/lib/dev-cycle-read.sh:1090-1091`

---

## Claim 19: "Set only as a one-call prefix (import_outside's projection), never assigned by a caller; cleared here, so an inherited one cannot make every walk read its text as whole names ... IMPORT_LEFT and IMPORT_WORK_LEFT need no clearing: every walk sets both for each call."

**Location:** `scripts/lib/dev-cycle-read.sh:1031-1035`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every reference to IMPORT_WHOLE outside docs/ (rg) and every parser call inside both walks. It does not establish anything about a caller that assigns IMPORT_WHOLE after sourcing (none exists) or a direct non-walk import_targets call, which reads an exported IMPORT_LEFT.
**Legibility-target:** for-orchestrator-synthesis

The only assignment is `IMPORT_WHOLE=1 import_targets /` (`:1145`), apart from the clear at `:1035`. probe1 P3 printed `after=[]` after the prefix call. Both walks set both budgets as prefixes on each parser call (`:1270`, `:1347`, `:1349`). Mutant A1 (the `IMPORT_WHOLE=""` line removed) fails the chain test (`$FC/mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1035`, `scripts/lib/dev-cycle-read.sh:1145`, `scripts/lib/dev-cycle-read.sh:1270`, `scripts/lib/dev-cycle-read.sh:1347-1349`, `$FC/probe1.log`, `$FC/mutants.log`

---

## Claim 20: "The reader set and its refusal are import_readers' alone, so refused settings fail every call ...; within a walk it is memoized and forks nothing."

**Location:** `scripts/lib/dev-cycle-read.sh:1099-1102`
**Type:** Architectural / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the registry listings counted through a git shim: once per direct pipeline call, and once per walk. It does not establish that import_home forks nothing on a HOME change (its key changes, by design).
**Legibility-target:** for-orchestrator-synthesis

probe2 Q1: three direct `printf | import_targets` calls, each in a pipeline subshell, listed the registry 3 times. After priming `import_readers` in the shell, three calls listed it once (the priming). A full tree walk listed it once, and a full main walk listed it once. Memo hit: `if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi` (`:1049`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1043-1050`, `scripts/lib/dev-cycle-read.sh:1102`, `$FC/probe2.log`

---

## Claim 21: "import_outside FILE [DIRS...]: ... read from the file system against its own directory and each DIRS entry ...; when its real path differs (a symlink on the way), that path is also projected whole (IMPORT_WHOLE), so a link into a reader root reads as an import of the repo path and one to another outside file as that file, which the walk then reads again under its real path."

**Location:** `scripts/lib/dev-cycle-read.sh:1126-1133`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers own-directory resolution, DIRS, both projections and the re-read. It does not establish handling of a bind-mount spelling, which realpath does not resolve (no such alias of /workspace exists in this container: `/proc/self/mountinfo` shows only `/workspace`).
**Legibility-target:** for-orchestrator-synthesis

`a="$(capped_read < "$1" | import_targets "${d:-/}" "${@:2}")"` and `if [[ "$r" != "$1" ]]; then b="$(printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /)" ...` (`:1144-1145`). probe1 P4 printed `//$O/b.md` (resolved against the link's directory) and `//$O/real.md` (the projection). probe2 shows the walks then read `r.md` and reach `docs/y.md`. The suite test with `$o/tl.md -> docs/t.md` passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1140-1147`, `$FC/probe1.log`, `$FC/probe2.log`, `$FC/suite-build-loop-check.log`

---

## Claim 22: "For a walk, which sets IMPORT_WORK_LEFT: the two trailers are summed into one, and each call may spend all that a walk has left, so the walk's own import_work check is what bounds the pair."

**Location:** `scripts/lib/dev-cycle-read.sh:1133-1135`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the summing and that the walk's check (`work + w` against IMPORT_WORK_MAX) is at least as strict as import_outside's own (`w` alone). It does not establish that import_outside never fails first (it can: Claim 23).
**Legibility-target:** for-orchestrator-synthesis

`import_work a w` and `import_work b w` (`:1144-1145`) add both to the local `w`, which is printed once as `"/$w"` (`:1146`). The walks then run `import_work out work` (`:1271`, `:1348`). probe4 S2 measured a=18000 and b=69, each bounded only by the same IMPORT_WORK_LEFT.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1144-1146`, `scripts/lib/dev-cycle-read.sh:1271`, `$FC/probe4.log`

---

## Claim 23: "It returns 1 when IMPORT_WORK_LEFT is unset or empty (no trailer to sum), when realpath, a read or import_targets fails, or on a real path holding a newline ..., so a file that changed after the walk admitted it fails the walk rather than being skipped."

**Location:** `scripts/lib/dev-cycle-read.sh:1135-1139`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` in import_outside and the consequence clause. It does not establish whether the omission changes any walk's answer: it does not, because the walk fails either way.
**Legibility-target:** for-author

Two imprecisions:

1. The list omits a fourth reason. `import_work a w` / `import_work b w` (`:1144-1145`) returns 1 when the summed `w` passes IMPORT_WORK_MAX (`(( (iw_t += iw_w) <= IMPORT_WORK_MAX ))`, `:1167`). In probe4 S2, IMPORT_WORK_MAX=IMPORT_WORK_LEFT=18034 with a=18000 ≤ 18034 < a+b=18069 gave `import_outside rc=1`. Neither import_targets call failed, and IMPORT_WORK_LEFT was set.
2. "a file that changed after the walk admitted it fails the walk" is broader than the code. Only a change that makes the file missing, unreadable, a directory or a newline-named real path fails. Changed content is read as it then is, as the walk header itself says (Claim 5). A FIFO swap stalls (Claim 3).

Precise version: "...when realpath, a read or import_targets fails, when the pair's summed work passes IMPORT_WORK_MAX, or on a real path holding a newline ..., so a file removed or made unreadable after the walk admitted it fails the walk rather than being skipped."

**Evidence:** `scripts/lib/dev-cycle-read.sh:1140-1147`, `scripts/lib/dev-cycle-read.sh:1163-1168`, `$FC/probe4.log`

---

## Claim 24: "import_file FILE DIR [DIRS...]: ... An absolute FILE needs IMPORT_WORK_LEFT set, as every walk sets it, and returns 1 without it; a caller treats that 1 as a failed walk, never as a file to skip"

**Location:** `scripts/lib/dev-cycle-read.sh:1148-1154`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both branches and both callers. It does not establish anything for future callers (U2b3b2b's seeds).
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$1" == /* ]]; then import_outside "$1" "${@:3}"; else capped_read < "$1" | import_targets "${@:2}"; fi` (`:1154`). probe1 P5 (no IMPORT_WORK_LEFT) gave rc=1. Both callers write `... import_file ...)" && import_work out work || { IMPORTED...=error; return 1; }` (`:1270-1271`, `:1347-1348`). Mutant A4 (DIRS dropped) fails the import_file test (`$FC/mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1154`, `scripts/lib/dev-cycle-read.sh:1270-1271`, `scripts/lib/dev-cycle-read.sh:1347-1348`, `$FC/probe1.log`, `$FC/mutants.log`

---

## Claim 25: "outside_ok PATH: whether a walk reads PATH, a name below no reader root: a readable regular file (the one admission rule both walks apply)."

**Location:** `scripts/lib/dev-cycle-read.sh:1155-1158`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the predicate and that it is the only admission test in both `//` arms. The clause "a session in this container cannot load it either" is not re-verdicted: it is under an existing Won't-Fix row (fact-check i1, Unverifiable).
**Legibility-target:** for-orchestrator-synthesis

`outside_ok() { [[ -f "$1" && -r "$1" ]]; }` (`:1158`). probe1 P7 results: regular file → ok; symlink to a regular file → ok; missing file, directory, FIFO and `/dev/null` → no. It is called at `:1278` and `:1386` only.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1158`, `scripts/lib/dev-cycle-read.sh:1278`, `scripts/lib/dev-cycle-read.sh:1386`, `$FC/probe1.log`

---

## Claim 26: "import_work OUT TOTAL: strips the parser's work trailer (its last line, "/N" ...; a repo-relative name never starts with /, and a second-channel name starts with //) ... returns 1 when the trailer is missing or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:1159-1162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parse and the cap (see Claim 15). It does not establish behaviour for OUT holding only an empty trailer `/` (non-digit, so refused).
**Legibility-target:** for-orchestrator-synthesis

This is the function at `:1163-1168`, quoted in Claim 15, with probe1 P2 outputs.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1163-1168`, `$FC/probe1.log`

---

## Claim 27: "A name below no root (//PATH) is read where it lies, when a session could load it." / "Below no root: read from the file system in phase 2, as the checkout is."

**Location:** `scripts/lib/dev-cycle-read.sh:1277`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both arms (tree `:1277-1278`, main `:1385-1386`), including that the main walk never sends an absolute path through main's mode arms or main_checkout. "Could load" carries the Claim 3 exceptions.
**Legibility-target:** for-orchestrator-synthesis

The main arm runs `continue` before `main_checkout ent pok "$p"` (`:1388`). A queued absolute `f` is never an `ent` key (keys come from `git ls-tree` paths, `:1311-1313`, which are repo-relative), so `case "${ent[$f]-checkout}"` takes the `checkout)` arm and calls `import_file`, which hands an absolute FILE to `import_outside` (`:1347`, `:1154`). probe2 Q1 ran both walks over an outside chain with rc=0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1276-1281`, `scripts/lib/dev-cycle-read.sh:1309-1313`, `scripts/lib/dev-cycle-read.sh:1342-1392`, `$FC/probe2.log`

---

## Claim 28: "a blob, checkout file or outside file cannot be read (import_outside)" and "Phase 2 begins when queue empties: tq's checkout files and outside files (absolute paths, never main's) then join it"

**Location:** `scripts/lib/dev-cycle-read.sh:1291`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main_imports' failure list entry and the phase-2 comment (`:1297-1298`). It does not establish the rest of the pre-existing failure list.
**Legibility-target:** for-orchestrator-synthesis

Outside names go only to `tq+=("$p")` (`:1386`). `[[ $qi -lt ${#queue[@]} ]] || { queue=("${tq[@]}"); tq=(); qi=0; }` (`:1343`) moves them into the queue once main's walk is done. A failed `import_file` sets `IMPORTED_MAIN=error; return 1` (`:1348`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1291`, `scripts/lib/dev-cycle-read.sh:1297-1298`, `scripts/lib/dev-cycle-read.sh:1343-1348`, `scripts/lib/dev-cycle-read.sh:1386`

---

## Claim 29: Test title "the parser prints a name below no reader root as //PATH, joins a relative name to an absolute directory alone, reads IMPORT_WHOLE lines whole, takes import_readers' roots outside a walk, and fails for a ROOT_REAL of / or empty"

**Location:** `test/scripts/build-loop-check.bats:631`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test passes at HEAD and fails on main's lib. It does not establish anything beyond the asserted lines.
**Legibility-target:** for-orchestrator-synthesis

The test passes in the full suite (120/120). On main's lib it fails with `# missing //etc/x.md: opt/d/a` (`$FC/red-on-main.log`).

**Evidence:** `test/scripts/build-loop-check.bats:631-641`, `$FC/suite-build-loop-check.log`, `$FC/red-on-main.log`

---

## Claim 30: Test title "both walks follow an import below no reader root, read where it lies against its own directory, through outside chains and back into the repo; a cycle ends" and its comment "An inherited IMPORT_WHOLE is cleared when the lib is sourced, so text is still read as text"

**Location:** `test/scripts/build-loop-check.bats:643`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the passing test, its failure on main, and its failure under mutant A1. It does not establish termination beyond `imps`' `timeout 60`.
**Legibility-target:** for-orchestrator-synthesis

The fixture writes `o2: @%s/docs/x.md, @../o1.md and @../../repo/docs/y.md` (`:648`), a cycle back to o1. The test passes at HEAD, is `not ok` on main, and is `not ok` with the `IMPORT_WHOLE=""` clear removed.

**Evidence:** `test/scripts/build-loop-check.bats:643-658`, `$FC/suite-build-loop-check.log`, `$FC/red-on-main.log`, `$FC/mutants.log`

---

## Claim 31: Test title "an outside link whose real path holds a newline fails the tree walk (the main walk already fails on the newline-named checkout file); import_file reads an outside file against its own directory and the DIRS it is given"

**Location:** `test/scripts/build-loop-check.bats:660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the retitled test (H2). The main-walk parenthetical rests on `[[ "$f" != *$'\n'* ]] || return 1` over checkout_md (`dev-cycle-read.sh:1329`), read statically.
**Legibility-target:** for-orchestrator-synthesis

The test passes at HEAD, fails on main, and fails under mutants A2 (newline check removed) and A4 (DIRS dropped).

**Evidence:** `test/scripts/build-loop-check.bats:660-669`, `scripts/lib/dev-cycle-read.sh:1329`, `$FC/suite-build-loop-check.log`, `$FC/red-on-main.log`, `$FC/mutants.log`

---

## Claim 32: Test title "an outside name whose real path lies in the repo reads as that repo path; an unreadable, missing or non-regular outside name is skipped"

**Location:** `test/scripts/build-loop-check.bats:671`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the passing test as non-root (it skips under uid 0). The "as a session cannot load it" clause carries Claim 25's scope note.
**Legibility-target:** for-orchestrator-synthesis

It asserts `want docs/q.md -` for the mode-000 file and `imported` for docs/s.md, t.md and u.md (`:682`). It passes at HEAD and fails on main.

**Evidence:** `test/scripts/build-loop-check.bats:671-684`, `$FC/suite-build-loop-check.log`, `$FC/red-on-main.log`

---

## Claim 33: The sourcing inventory lists import_outside, import_file, outside_ok, IMPORT_DOTNEST and IMPORT_WHOLE

**Location:** `test/scripts/dev-cycle.bats:1109`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers presence after sourcing. It does not establish the values.
**Legibility-target:** for-orchestrator-synthesis

dev-cycle.bats passes 79/79.

**Evidence:** `test/scripts/dev-cycle.bats:1107-1117`, `$FC/suite-dev-cycle.log`

---

## Claim 34: Commit 55490d15: "Tests: three new ..., each red on main; build-loop-check 119, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2."

**Location:** `55490d15` (commit message)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `@test` counts at the commit (`git show 55490d15:<file> | grep -c '^@test'`) and red-on-main for the HEAD versions of the tests, which extend the 55490d15 versions. "Three new" counts the rewritten parser test, which replaced main's ROOT_REAL=/ test (117 − 1 + 3 = 119).
**Legibility-target:** for-orchestrator-synthesis

The counts are 119/20/79/2/2 at 55490d15 and 117/20/79/2/2 on main. All four branch tests, run against main's lib, are `not ok`.

**Evidence:** `test/scripts/build-loop-check.bats:631`, `test/scripts/build-loop-check.bats:643`, `test/scripts/build-loop-check.bats:671`, `$FC/red-on-main.log`

---

## Claim 35: Commit 55490d15: "Over this worktree both walks give main's 64 names in about the same time (0.7-0.8 s); no walked file here holds an outside name."

**Location:** `55490d15` (commit message)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** True as of 2026-10-09T16:50:55Z on this host at HEAD (timing varies with load). It does not establish that the measurement was taken at 55490d15.
**Legibility-target:** for-orchestrator-synthesis

probe4 S3 results: main rc=0 in 764 ms and tree rc=0 in 818 ms. Each list has 64 lines and both lists are equal. Neither holds a `//` line.

**Evidence:** `$FC/probe4.log`

---

## Claim 36: Commit 55490d15: "a ROOT_REAL of / now fails a direct call too, as it always failed the walks."

**Location:** `55490d15` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an unprimed direct call on main's lib and on the branch's, and main's import_readers. It does not establish anything about callers outside the lib (none exist: override row api i1 F5).
**Legibility-target:** for-orchestrator-synthesis

In probe4 S1, main's lib printed `d ... docs/a.md` with rc=0, and the branch lib gave rc=1. In probe3 R3, main's `import_readers` with ROOT_REAL=/ gave rc=1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1102`, `$FC/probe3.log`, `$FC/probe4.log`

---

## Claim 37: Commit 55490d15 Notes: "Of nine mutants tried, one survives: import_targets' `import_readers || return 1` made `|| true` (equivalent: an empty root list makes the parser exit 2)."

**Location:** `55490d15` (commit message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Re-confirms the i1 verdict only. Already Accepted-immutable (override row, fact-check i1); no action.
**Legibility-target:** for-orchestrator-synthesis

`import_home || return 1` (`:1045`) returns before `IMPORT_ROOTS=""` (`:1050`). Under `|| true`, an import_home failure after an earlier walk would leave the old roots in place, and the parser would run instead of exiting 2. The mutant is not quite equivalent. Tagged for-orchestrator-synthesis rather than the default for-author because the commit message is immutable and a row already records the finding.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1043-1050`, `docs/reviews/override-log.md` (row "Commit 55490d15's Notes call the surviving ... mutant equivalent")

---

## Claim 38: Commit 18fba03d: "a new test for the newline real path (both walks fail) and import_file's DIRS. The three fix mutants each fail a test. build-loop-check 120, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2. 213 code lines against main."

**Location:** `18fba03d` (commit message)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at the commit, three mutants (A1, A2, A4 as described in its bullets) at HEAD, and `git diff --numstat main...18fba03d -- scripts test` (165 + 48 = 213). It does not establish that the commit's own mutants were the same edits.
**Legibility-target:** for-orchestrator-synthesis

The counts are 120/20/79/2/2. Each mutant makes its pinning test `not ok`. "Both walks fail" holds: the test asserts `want walk failed` for tree and main. HEAD is now 174 + 50 = 224 lines against main; the brief's "about 216" is an estimate, not a code claim.

**Evidence:** `test/scripts/build-loop-check.bats:660-669`, `$FC/mutants.log`, `$FC/probe3.log`

---

## Claim 39: Commit 82bb5281: "Comments and a test title only; suites unchanged."

**Location:** `82bb5281` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git diff -U0 18fba03d 82bb5281 -- scripts test`. f7a96eed sits between them and is comment-only too.
**Legibility-target:** for-orchestrator-synthesis

Excluding `#` lines, the only changed lines are the `@test` title at `build-loop-check.bats:660`. Test counts are equal at 18fba03d and 82bb5281, and all suites pass.

**Evidence:** `test/scripts/build-loop-check.bats:660`, `$FC/probe3.log`, `$FC/suite-build-loop-check.log`

---

## Claim 40: Commit 82bb5281: "H1: import_outside's returns-1 list is complete."

**Location:** `82bb5281` (commit message)
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same list as Claim 23. The omission never changes a walk's answer, because the walk's own check fails on the same total.
**Legibility-target:** for-author

The list now names the two reasons i2 found missing. It still omits the pair's summed work passing IMPORT_WORK_MAX (`import_work a w` / `import_work b w`, `:1144-1145`), executed in probe4 S2 (rc=1). "Complete" is therefore one condition short. The fix is in the header (Claim 23); the commit message is immutable.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1135-1139`, `scripts/lib/dev-cycle-read.sh:1144-1145`, `$FC/probe4.log`

---

## Brief item 10 (security coverage note)

No path was found by which repo or outside content makes the floor answer "not imported" for a path a session loads, beyond the declined rows (an absent reader home; a FIFO swap, which stalls rather than answers).

Paths checked:

- `//` and trailer confusion (Claim 15).
- IMPORT_WHOLE inheritance (Claim 19).
- A newline-named real path (Claim 31; mutant A2).
- An outside link into the repo, and an outside link to another outside file (Claim 21).
- An outside file removed between admission and read: the walk fails (Claim 5).
- The main walk sending an absolute path through main's arms or main_checkout (Claim 27).
- Refused settings or ROOT_REAL `/` reaching the parser (Claims 16, 20).
- seen-key collision: absolute paths versus repo-relative names cannot collide.

Untested here: a bind-mount alias of a reader root, which realpath does not resolve. None exists in this container (`/proc/self/mountinfo`: `/home/magfrump/claude-workflows /workspace`, the host spelling that IMPORT_READER_ROOTS already models). Such an alias would be a reader-root question, not this unit's, and not a regression: main dropped such names entirely.

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 23** (`scripts/lib/dev-cycle-read.sh:1135-1139`): import_outside's returns-1 list omits the pair's summed work passing IMPORT_WORK_MAX (executed: rc=1 with neither import_targets call failing). "A file that changed after the walk admitted it fails the walk" should read "removed or made unreadable"; changed content is read as it is.
- **Claim 37** (commit 55490d15 Notes): the `|| true` mutant is not quite equivalent. Already Accepted-immutable; no action.
- **Claim 40** (commit 82bb5281): "H1: import_outside's returns-1 list is complete" is one condition short (as Claim 23). The commit message is immutable; fix the header.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): "your report saved at the path your own tail names, structured per your skill file, with a `Commit: 82bb5281` line at the top."
- Answered: Yes. Saved at /workspace/.claude/wt-build-loop-u2b3b2a/docs/reviews/code-fact-check-report-build-loop-u2b3b2a-final-r3.md, with `Commit: 82bb5281` as its first line, the skill's header and seven fields per claim, a Legibility-target on every claim, and 32 of 40 claims executed. Brief claims 1-10 map as follows: 1 → Claims 15, 26; 2 → 21-24; 3 → 2, 25, 27, 28; 4 → 19; 5 → 9, 20; 6 → 17; 7 → 12, 13, 16; 8 → 1-11, 14, 18, 23, 26-28; 9 → 34-40; 10 → the coverage note.
- Out of scope: outside seeds (U2b3b2b); whether Claude Code skips a FIFO (an existing row).
- Escalate: none blocking. The only new item is a 🟢 comment fix (Claim 23/40: one missing return-1 reason, and "changed" should be "removed or made unreadable").
