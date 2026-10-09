Commit: 82bb5281
# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/workspace/.claude/wt-build-loop-u2b3b2a`, branch `feat/build-loop-u2b3b2a`
**Scope:** `git diff main...HEAD -- scripts test` at HEAD 82bb5281: `scripts/lib/dev-cycle-read.sh` (the walk block, lines ~640-1440), `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, and the commit messages of 55490d15, 18fba03d and 82bb5281. This is the iteration-3 final confirming pass, replicate r2 of k=3.
**Checked:** 2026-10-09
**Total claims checked:** 38
**Summary:** 34 verified, 3 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries): I compared every claim against it. The only near-class entries are the "specific measured value quoted from an artifact set" patterns, which bear on the commit-message counts (Claims 27, 32). Both counts recompute exactly, so neither matches a pattern.

Declined rows I took as context and did not re-raise: override-log rows 558-572 (A3 absent home, the FIFO swap, any readable file parsed, the large file, the long name, the double parse, the O(R²) dotnest, the direct-call contract, the `|| true` mutant, the FIFO Unverifiable, B1's commit message, the outside_ok name, the ignored DIR, and the two cost rows). Claims 20b and 30 restate two of these rows' verdicts as carried, and neither changes.

## Execution provenance

Every probe follows the brief's probe-safety rule. Each script starts with `set -eu`, creates its own `mktemp -d` dir, `cd`s into it and checks `pwd` before any `git init` or commit. The scripts and logs are under `/tmp/claude-1000/-workspace/715dcdb7-5140-4bd1-a115-cbeff3508ce5/scratchpad/u2b3b2a-i3/fact-check-r2/` (`logs/` holds the output). No process outlived its script, and every temp dir was removed.

| Run | Command | cwd | Exit | Timestamp (UTC) | Output |
|---|---|---|---|---|---|
| S | `LC_ALL=C LANG=C TMPDIR=$T timeout 900 bats <suite>` over build-loop-check, build-loop-read, dev-cycle, fixture-git-env, fixture-hermeticity | worktree | 0 each (120/120, 20/20, 79/79, 2/2, 2/2 ok) | 2026-10-09T16:47:03Z to 16:48:30Z | `logs/suite-*.txt`, `logs/suites.rc` |
| P1 | `timeout 120 bash probe1.sh` (import_work on trailerless `//12`; the parser on `@/12 @/ @/..`; import_outside/import_file with and without IMPORT_WORK_LEFT; missing, directory and mode-000 files with pipefail on and off; outside_ok; whole mode through `od -c`; IMPORT_WHOLE exported before sourcing) | scratch dir | 0 | 2026-10-09T16:49:47Z | `logs/probe1.txt` |
| P2 | `timeout 120 bash probe2.sh` (IMPORT_DOTNEST against main's awk dotnest test over 13 roots, including glob and dot components; a git PATH shim that counts `worktree list` calls during each walk and during direct calls) | scratch dir | 0 | 2026-10-09T16:50:25Z | `logs/probe2.txt` |
| P3 | `timeout 1500 bash probe3.sh` (55490d15's three new tests against main's lib, with a 55490d15 control; mutants M1-M3 of 18fba03d's fixes at 82bb5281, with a HEAD control; trees from `git archive`) | scratch dir | 0 | 2026-10-09T16:50:55Z | `logs/probe3.txt` |
| P4 | `timeout 300 bash probe4.sh` (both walks over this worktree; `@/usr/bin/python3.md`; an outside link into the gate's checkout whose target the branch deletes) | scratch dir | 0 | 2026-10-09T16:51:34Z | `logs/probe4.txt` |
| P5 | `timeout 300 bash probe5.sh` (main's lib against HEAD's lib, both walks over this worktree: name lists and time) | scratch dir | 0 | 2026-10-09T16:51:58Z | `logs/probe5.txt` |
| P6 | `timeout 60 bash probe6.sh` (import_targets with refused settings, fresh and memoized, and with a caller root of `/`) | scratch dir | 0 | 2026-10-09T16:52:31Z | `logs/probe6.txt` |

---

## Claim 1: "and prints a path below no reader root on its second channel: import_readers"

**Location:** `scripts/lib/dev-cycle-read.sh:679`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tree walk header's description of the parser's output for a name below every reader root. It does not establish what the walk then does with such a name (Claim 2).

`put` ends `if (nho == 0) show("/" out)` (`scripts/lib/dev-cycle-read.sh:899`), where `nho` counts the reader roots that hold `out` (`:893`). P1 printed `//1` and `//12` for `@/12` (`logs/probe1.txt`). The suite's parser test asserts `//etc/x.md` and `//opt/d/a.md` (`test/scripts/build-loop-check.bats:637`), and it passed in run S.

**Evidence:** `scripts/lib/dev-cycle-read.sh:893-899`, `test/scripts/build-loop-check.bats:637`, `logs/probe1.txt`, `logs/suite-build-loop-check.txt`

---

## Claim 2: "Both walks follow an import to a file below no reader root (the parser's second channel) when outside_ok admits it, reading it from the file system, as the checkout phase does, through import_outside (the main walk in phase 2); one that is missing, unreadable or not a regular file here is skipped."

**Location:** `scripts/lib/dev-cycle-read.sh:720-723`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both walks' `//` arms, the admission rule and the read path. It does not establish that this file-system view matches what a session on main would see (Claim 3b).

Tree walk: `[[ "$p" != //* ]] || { p="${p#/}"; outside_ok "$p" && ... queue+=("$p"); continue; }` (`:1278`). Main walk: the same arm queues to `tq` (`:1386`). Phase 2 swaps `tq` in (`:1343`), and its absolute paths take the `checkout)` arm through `import_file` (`:1347`). That arm runs `import_outside` for a path led by `/` (`:1154`). P1: outside_ok answered `ok` for the readable file and `skip` for the missing file, the directory and the mode-000 file. The suite test "an outside name whose real path lies in the repo … an unreadable, missing or non-regular outside name is skipped" passed for both walks (run S).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1154`, `:1158`, `:1278`, `:1343-1348`, `:1386`, `logs/probe1.txt`, `logs/suite-build-loop-check.txt`

---

## Claim 3a: "Known exceptions: a file a session elsewhere can load that this container cannot see (…), and a regular file swapped for a FIFO after its admission, which stalls the read (…). A large outside file a prefix names (@/usr/bin/python3.md reads /usr/bin/python3) or a very long absolute name (…) can spend a walk's budget, which fails closed (…). The walk reads outside files as they are when it runs: one changed or removed during the walk is read as it then is."

**Location:** `scripts/lib/dev-cycle-read.sh:724-733`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each exception the list names. It does not establish that the list is complete (Claim 3b).

P4(b): with `@/usr/bin/python3.md` in AGENTS.md (the target is 6,834,488 bytes), both walks printed `walk: failed` and `docs/x.md: imported`, so the walks fail closed (`logs/probe4.txt`). The FIFO stall follows from `import_outside`. `realpath -e` succeeds on a FIFO, and the next line opens the file with `capped_read < "$1"` (`:1142`, `:1144`), which blocks on a FIFO with no writer. That part was not executed: brief rule, no stalling probes. The absent-home case is override row 558.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1142-1144`, `logs/probe4.txt`, `docs/reviews/override-log.md:558-562`

---

## Claim 3b: The exception list (as the list of the cases where a session can load what the walks skip)

**Location:** `scripts/lib/dev-cycle-read.sh:724-733`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers one case the list does not name: a stable file-system state, not a change during the walk. It does not establish how likely that state is on a real host. The exception list still matches what the walk does, and the mechanism ("reading it from the file system … one that is missing … here is skipped") is stated at `:721-723`.

The main walk reads repo paths from main's commit, but it admits and projects an outside name from the live checkout. Take an outside symlink into the gate's own checkout (`/o/tl.md -> $ROOT_REAL/docs/t.md`) whose target the branch deletes. On the branch, outside_ok finds a dangling link and the main walk skips it, so main's `docs/t.md` reads as not imported. A session on main loads that file through the link. P4(c), on main with the target present: `main docs/t.md: imported`. On the branch with `docs/t.md` deleted: `main walk: ok`, `main docs/t.md: -`. Control: a direct `@docs/u.md` on main, absent from the checkout, gives `main docs/u.md: imported` (`logs/probe4.txt`). The case is narrow, since a link into the main worktree (another reader root) still resolves. The precise version would add "an outside link into this checkout resolves against the checkout, not main" to the exceptions, or route it to the security critic.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1386`, `:1158`, `:1142-1146`, `logs/probe4.txt`

---

## Claim 4: "The walks' lists (IMPORTED, IMPORTED_MAIN) also hold the second channel's lower-cased // names, which no repo path isimported asks for can match."

**Location:** `scripts/lib/dev-cycle-read.sh:737-738`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers repo-relative queries. It does not establish what an absolute query to isimported gets, though `"\n/x\n"` cannot match inside `"\n//x\n"` either.

`lp="$(lower "$out")" … IMPORTED+="$lp"$'\n'` appends the walk's whole output, `//` lines included (`:1275`). P2 counted 57 `//` lines in the lists of a fixture walk (`logs/probe2.txt`). isimported tests `[[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]`. A repo path never starts with `/` (paraphrased — no quote available because this follows from `show(substr(out, length(pre[h[i]]) + 1))` at `:895`, where `pre` ends in `/`, together with `put`'s collapse of empty components), so it cannot equal a line that starts with `//`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:895`, `:1275`, `isimported` (`:1400-1409`), `logs/probe2.txt`

---

## Claim 5: "each a repo-relative directory joined under every reader root or, led by /, an absolute one joined as it is (a file below no root): one repo-relative path per line, or // and the absolute path for a name below no root (the second channel), case kept, each once. With IMPORT_WHOLE set, each line on stdin is one name, taken whole (no prefixes, no blanks)" (and `:969` "IT_WHOLE: each line is one name, read as written")

**Location:** `scripts/lib/dev-cycle-read.sh:776-784`, `:969`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the output shape and whole mode. It does not establish one detail: in whole mode a line holding a byte above 0x7f may also be read decoded (the UTF-8 branch still runs), which adds names (superset) and changes none.

Whole mode runs `if (whole) { emit($0, 1); next }` (`:970`) with sed's blank substitutions replaced by `-e ''` (`:1105`). P1's `od -c` shows `//x/a b.md` and `//x/c\302\240d.md` kept whole, with no prefix lines (`logs/probe1.txt`). The suite asserts `whole docs/a b.md` and `whole //etc/x y`, exactly two whole lines (`test/scripts/build-loop-check.bats:637-638`), and it passed in run S.

**Evidence:** `scripts/lib/dev-cycle-read.sh:964`, `:969-970`, `:1105`, `test/scripts/build-loop-check.bats:631-641`, `logs/probe1.txt`

---

## Claim 6: "It also reads ROOT_REAL and import_readers' IMPORT_ROOTS, IMPORT_HOMES and IMPORT_DOTNEST, calling it (which sets those and the IMPORT_HOME* globals in the caller's shell unless called in a subshell; its refusal fails this call)"

**Location:** `scripts/lib/dev-cycle-read.sh:785-787`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reader-set source and the refusal. It does not establish caching across direct calls: each `printf | import_targets` runs in a pipeline subshell, so P2 saw 2 registry listings for 2 direct calls, as "unless called in a subshell" says.

`import_readers || return 1` (`:1102`), and the awk gets `IT_ROOTS="$IMPORT_ROOTS" IT_HOMES="$IMPORT_HOMES" IT_DOTNEST="$IMPORT_DOTNEST"` (`:1123`). P6: refused settings gave `fresh refused rc=1` and `memoized refused rc=1`. Cleared settings gave rc=0, and a caller root of `/` gave rc=1 (`logs/probe6.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1102`, `:1123-1124`, `logs/probe6.txt`, `logs/probe2.txt`

---

## Claim 7: "made absolute (ROOT/DIR/name for each reader root and each of $1 and the further directories, or DIR/name for one led by /, unless the name starts with /) … a name below no reader root (…) is printed on the second channel, and any other relative to each root holding it but an outer one … (the parser's dotnest …)"

**Location:** `scripts/lib/dev-cycle-read.sh:811-818`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the superset statement's edited sentences. It does not re-verify the unchanged claim that these rules read every name Claude Code 2.1.292 can import.

`for (i = 0; i <= nd; i++) if (substr(dirs[i], 1, 1) == "/") put(dirs[i] "/" c); else for (r = 1; r <= nr; r++) put(roots[r] "/" dirs[i] "/" c)` (`:865`). `if (substr(c, 1, 1) == "/") { put(c); return }` (`:861`). The suite asserts `//opt/d/a.md`, and asserts that `a.md`, `docs/a.md` and the dot-nested `.claude/wt-b/n.md` are not printed (`test/scripts/build-loop-check.bats:637`, `:640`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:861-865`, `:893-899`, `test/scripts/build-loop-check.bats:637-640`, `logs/suite-build-loop-check.txt`

---

## Claim 8: "It returns 1 when sed, python3, awk or import_readers fails (an empty ROOT_REAL, or refused settings, among its reasons)"

**Location:** `scripts/lib/dev-cycle-read.sh:836-837`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the import_readers-fails arm. It does not re-execute the sed and python3 arms, which are unchanged.

`[[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1` (`:1053`) inside import_readers, which import_targets calls first (`:1102`). P6 gave rc=1 for refused settings. The suite test asserts two `rc=1` lines, for a ROOT_REAL of `/` and for an empty one (`test/scripts/build-loop-check.bats:636`, `:638`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1053`, `:1102`, `logs/probe6.txt`, `test/scripts/build-loop-check.bats:636-638`

---

## Claim 9: "an absolute directory (a file below no root) is the one directory it names."

**Location:** `scripts/lib/dev-cycle-read.sh:863-865`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers emit's join for a dir led by `/`. It does not establish what a prompt base (which is always repo-relative) gets in import_outside: it is joined under every root, as for repo files.

Quoted at `:865` in Claim 7. P1: `import_outside` on `$T/out/o.md` passes its own directory, and the name `@%s/out/d/x.md` came out as `//…/out/d/x.md` with no root-joined copy (`logs/probe1.txt`). The test at `:660` asserts `/$o/docs/n.md` from `@docs/n.md` in `$o/p.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:865`, `:1144`, `test/scripts/build-loop-check.bats:660-670`, `logs/probe1.txt`

---

## Claim 10: `if (index(out, "\n") || out == "") return` (an empty resolved name prints nothing)

**Location:** `scripts/lib/dev-cycle-read.sh:880-882`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `@/` and `@/..`. It does not establish other names that would resolve to `/`, though by the code every such name has `k == 0` and returns the same way.

P1: `imp @/12 and @/ and @/..` printed only `//1` and `//12`, with no line that is `/` alone. Such a line would have been `show("/" "")` (`logs/probe1.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:877-882`, `logs/probe1.txt`

---

## Claim 11: "(dotnest, from import_readers)" and truthrule's "import_readers' dotnest pairs omit only such paths: keep the two equal"

**Location:** `scripts/lib/dev-cycle-read.sh:884`, `:1427`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the predicate equality between the pair rule and truthrule's dot word. It does not establish truthrule's other words.

The pair rule adds (I, J) when `"/${t#"$p"}"` holds `/.` (`:1093`), so the outer spelling of a path under J has a component led by `.`. truthrule refuses `[[ "/$1" == */.* ]]` (`:1427`), the same predicate over the whole path, and that is a superset. P2's 7 pairs each nest through a dot component (`logs/probe2.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1093`, `:1427`, `logs/probe2.txt`

---

## Claim 12: "Below no root: the second channel, / and the absolute path (so // leads it, and no repo name or work trailer can be read as one)" and import_work's "a second-channel name starts with //"

**Location:** `scripts/lib/dev-cycle-read.sh:897-899`, `:1159-1162`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers import_work's parse and both walks' `//` arms, including names that end in digits and import_outside's summed trailer. It does not establish behaviour for a caller that reads the output without import_work.

import_work accepts only `"$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w"` with an all-digit `$iw_w` (`:1165`). P1: trailerless `//12` gave rc=1, `docs/a\n//12` gave rc=1, and `//12\n/5` gave rc=0 with `out=[//12] w=5`. `import_outside` printed one summed trailer, `/1395`, after its `//` lines (`logs/probe1.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1146`, `:1163-1168`, `logs/probe1.txt`

---

## Claim 13: IMPORT_DOTNEST: "the parser's dotnest pairs, "I J" lines by 1-based index into IMPORT_ROOTS: J lies below I through a dot component" (the bash test equals main's awk test; no trailing newline; BEGIN's `IT_DOTNEST` comment; the dropped `roots[i] == "/"` arm)

**Location:** `scripts/lib/dev-cycle-read.sh:960-962`, `:1090-1095`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 13 roots, including glob characters (`[x]`, `*`), dot components, and pairs that share a prefix without nesting (`/q` vs `/qq/.u`). It does not establish equality for a root of `/`, which the dropped arm handled and which import_readers now refuses.

P2 compared the pairs with main's awk test, run verbatim over the same IMPORT_ROOTS: `pairs new=7 old=7`, `EQUAL`, `no trailing newline` (`logs/probe2.txt`). `/` is refused upstream by `[[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1` (`:1070`): P6 printed `caller root / rc=1`. Order: `printf -v IMPORT_ROOTS '%s\n' "${rs_ro[@]}"` (`:1088`) uses the same array the pair loop indexes with `$((i + 1))`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:960-962`, `:1070`, `:1088-1095`, `logs/probe2.txt`, `logs/probe6.txt`

---

## Claim 14: "IMPORT_DOTNEST holds the parser's dotnest pairs over IMPORT_ROOTS (its comment in the body says how)."

**Location:** `scripts/lib/dev-cycle-read.sh:1008-1009`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the header's pointer. It does not establish the pairs' correctness (Claim 13).

The body comment exists: `# IMPORT_DOTNEST: the parser's dotnest pairs, "I J" lines by 1-based index into IMPORT_ROOTS` (`:1090`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1008-1009`, `:1090`

---

## Claim 15: "Set only as a one-call prefix (import_outside's projection), never assigned by a caller; cleared here, so an inherited one cannot make every walk read its text as whole names. IMPORT_LEFT and IMPORT_WORK_LEFT need no clearing: every walk sets both for each call."

**Location:** `scripts/lib/dev-cycle-read.sh:1031-1035`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers scripts/ and test/ uses and both walks' parser calls. It does not establish that a caller that assigns IMPORT_WHOLE after sourcing is harmless (none exists).

A grep of scripts/ and test/ finds IMPORT_WHOLE assigned only at `:1035`, as the prefix `IMPORT_WHOLE=1 import_targets /` (`:1145`), and in the tests' prefixes. P1, with `IMPORT_WHOLE=1` exported before sourcing, printed `IMPORT_WHOLE after source: []`. P3's mutant M1 (`IMPORT_WHOLE=""` → `:`) fails the chain test, and the unmutated control passes (`logs/probe3.txt`). Every parser call in the walks sets both budgets: `:1270` (tree), `:1347` (checkout arm) and `:1349` (blob arm). The `120000` arm calls no parser.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1035`, `:1145`, `:1270`, `:1347-1350`, `logs/probe1.txt`, `logs/probe3.txt`

---

## Claim 16: "The reader set and its refusal are import_readers' alone, so refused settings fail every call (…); within a walk it is memoized and forks nothing."

**Location:** `scripts/lib/dev-cycle-read.sh:1099-1102`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers registry listings per walk. It does not establish fork counts other than `git worktree list` (the walk's own `$(...)` subshells are not import_readers').

P2's git shim counted `tree: worktree listings=1` and `main: worktree listings=1` for full walks that read 4 files, one of them outside (`logs/probe2.txt`). Refusal: Claim 6.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1043-1049`, `:1102`, `logs/probe2.txt`, `logs/probe6.txt`

---

## Claim 17: `[[ -z "${IMPORT_WHOLE:-}" ]] || s=(-e '')  # names, not text: no byte is a blank`

**Location:** `scripts/lib/dev-cycle-read.sh:1105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the sed step and awk's whole-line emit. It does not cover the NUL case: a real path cannot hold a NUL.

P1's `od -c` shows the U+00A0 bytes `302 240` and a space kept inside one name (`logs/probe1.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1105`, `:970`, `logs/probe1.txt`

---

## Claim 18a: "import_outside FILE [DIRS...]: … read from the file system against its own directory and each DIRS entry …; when its real path differs (a symlink on the way), that path is also projected whole (IMPORT_WHOLE), so a link into a reader root reads as an import of the repo path and one to another outside file as that file, which the walk then reads again under its real path. For a walk …: the two trailers are summed into one, and each call may spend all that a walk has left, so the walk's own import_work check is what bounds the pair."

**Location:** `scripts/lib/dev-cycle-read.sh:1126-1135`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mechanism and the budget statement. It does not establish the pair's output bound: both calls inherit the same IMPORT_LEFT, and the walk's `used` check (`:1273`, `:1380`) bounds the sum.

```bash
# scripts/lib/dev-cycle-read.sh:1140-1146
import_outside() {
  local d="${1%/*}" r a b="" w=0 rl=()
  nul_list rl realpath -ez -- "$1" && [[ ${#rl[@]} -eq 1 && "${rl[0]}" != *$'\n'* ]] || return 1
  r="${rl[0]}"
  a="$(capped_read < "$1" | import_targets "${d:-/}" "${@:2}")" && import_work a w || return 1
  if [[ "$r" != "$1" ]]; then b="$(printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /)" && import_work b w || return 1; fi
  printf '%s\n' ${a:+"$a"} ${b:+"$b"} "/$w"
}
```

Both calls run with the caller's IMPORT_WORK_LEFT. The two trailers add into `w`, and the walk's `import_work out work` checks the sum against IMPORT_WORK_MAX. The suite tests for links into the repo (`dl/s.md`, `tl.md` → `docs/t.md`, then `@u.md` → `docs/u.md`) and for DIRS passed in both walks (run S). M3 (DIRS dropped) fails its test (`logs/probe3.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1140-1146`, `:1270-1273`, `:1347-1348`, `test/scripts/build-loop-check.bats:660-686`, `logs/probe3.txt`

---

## Claim 18b: "It returns 1 when IMPORT_WORK_LEFT is unset or empty (no trailer to sum), when realpath, a read or import_targets fails, or on a real path holding a newline …, so a file that changed after the walk admitted it fails the walk rather than being skipped."

**Location:** `scripts/lib/dev-cycle-read.sh:1135-1139`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed return-1 path, with and without pipefail. It does not establish the FIFO case, which stalls (named in the walk header).

The "a read … fails" arm holds only under pipefail. `a="$(capped_read < "$1" | import_targets …)"`: a failed open of `"$1"` fails `capped_read`, the pipeline's first command, so without pipefail the status is import_targets', which is 0 on empty input. P1, on a mode-000 file: with pipefail on, `rc=1`. With pipefail off, `Permission denied`, then `/0` and `rc=0`, an empty output passed as a success (`logs/probe1.txt`). Both walks set pipefail (`:1249`, `:1300`), so every current caller fails as stated. The other arms are executed: no IMPORT_WORK_LEFT gives rc=1, missing gives rc=1 (realpath), a directory gives rc=1, and newline is test `:660`/M2. The precise version is "a read fails (under pipefail, which both walks set)". The same qualifier applies to import_file's "a caller treats that 1 as a failed walk, never as a file to skip" (`:1152-1153`) for the first non-walk caller U2b3b2b plans.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1142-1146`, `:1249`, `:1300`, `logs/probe1.txt`, `logs/probe3.txt`

---

## Claim 19: "import_file FILE DIR [DIRS...]: … a repo path (DIR and DIRS as import_targets takes them), or an absolute one through import_outside (its own directory in place of DIR, and DIRS). An absolute FILE needs IMPORT_WORK_LEFT set, as every walk sets it, and returns 1 without it; a caller treats that 1 as a failed walk, never as a file to skip."

**Location:** `scripts/lib/dev-cycle-read.sh:1148-1154`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the dispatch, the IMPORT_WORK_LEFT duty and both current callers. The pipefail qualifier on a read failure is Claim 18b.

`import_file() { if [[ "$1" == /* ]]; then import_outside "$1" "${@:3}"; else capped_read < "$1" | import_targets "${@:2}"; fi; }` (`:1154`). P1: `import_file "$T/out/o.md" ignored` without IMPORT_WORK_LEFT gave `rc=1`. Both callers write `… import_file … && import_work out work || { IMPORTED=error; return 1; }` (`:1270-1271`, `:1347-1348`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1154`, `:1270-1271`, `:1347-1348`, `logs/probe1.txt`

---

## Claim 20a: "outside_ok PATH: whether a walk reads PATH, a name below no reader root: a readable regular file (the one admission rule both walks apply)."

**Location:** `scripts/lib/dev-cycle-read.sh:1155-1158`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both `//` arms. It does not establish behaviour after admission (Claims 3a, 18b).

`outside_ok() { [[ -f "$1" && -r "$1" ]]; }`. Each `//` arm calls it (`:1278`, `:1386`), and no other test admits a `//` name. P1: ok, skip, skip, skip, as in Claim 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1158`, `:1278`, `:1386`, `logs/probe1.txt`

---

## Claim 20b: "Anything else is skipped: a session in this container cannot load it either."

**Location:** `scripts/lib/dev-cycle-read.sh:1157`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing new. This restates override row 567 (the FIFO / non-regular case is untraced in Claude Code). It is not re-raised.

What Claude Code's loader does with a non-regular `@` target needs a probe inside a Claude Code session (paraphrased — no quote available because the claim is about Claude Code's runtime, not this repository's code).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1157`, `docs/reviews/override-log.md:567`

---

## Claim 21: "A name below no root (//PATH) is read where it lies, when a session could load it."

**Location:** `scripts/lib/dev-cycle-read.sh:1277`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tree walk arm (`:1278`). "When a session could load it" means outside_ok (see 20b).

Same arm and evidence as Claim 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1278`, `logs/suite-build-loop-check.txt`

---

## Claim 22: main_imports' failure list: "a blob, checkout file or outside file cannot be read (import_outside)"

**Location:** `scripts/lib/dev-cycle-read.sh:1291`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers an outside read failure inside the main walk under its pipefail. It does not cover the FIFO stall.

The `checkout)` arm, which outside files take, ends `|| { IMPORTED_MAIN=error; return 1; }` (`:1348`). P1's failed reads return 1 under pipefail, and main_imports sets it (`:1300`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1300`, `:1347-1348`, `logs/probe1.txt`

---

## Claim 23: "Phase 2 begins when queue empties: tq's checkout files and outside files (absolute paths, never main's) then join it" and "Below no root: read from the file system in phase 2, as the checkout is."

**Location:** `scripts/lib/dev-cycle-read.sh:1297-1298`, `:1385`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the queueing. A repo path that an outside file names and that main stores is read from main's blob even in phase 2 (`queue+=`, `:1391`). That is by design and not contradicted.

`[[ "$p" != //* ]] || { …; tq+=("$p"); continue; }` (`:1386`) returns before `main_checkout` (`:1388`). An absolute path cannot be an `ent` key (keys come from `git ls-tree` names, which never lead with `/`, `:1311-1313`), so `${ent[$f]-checkout}` sends it to the `checkout)` arm (`:1346-1347`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1311-1313`, `:1343-1347`, `:1386-1391`

---

## Claim 24: test comment "An inherited IMPORT_WHOLE is cleared when the lib is sourced, so text is still read as text (i1 architecture A1)."

**Location:** `test/scripts/build-loop-check.bats:655-656`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test's power: it fails without the clear. It does not cover a caller that assigns IMPORT_WHOLE after sourcing.

M1 makes this test fail, and HEAD passes it (`logs/probe3.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:655-656`, `logs/probe3.txt`

---

## Claim 25: test title "an outside link whose real path holds a newline fails the tree walk (the main walk already fails on the newline-named checkout file)…"

**Location:** `test/scripts/build-loop-check.bats:660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers why each walk fails. It does not establish that the main walk's import_outside newline check is pinned by any test (it is not; the title no longer claims it).

The main walk fails at `for f in "${recs[@]}"; do [[ "$f" != *$'\n'* ]] || return 1; …` over checkout_md (`scripts/lib/dev-cycle-read.sh:1328-1329`), before any outside read. M2 fails this test through the tree half (`logs/probe3.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1328-1329`, `test/scripts/build-loop-check.bats:660-664`, `logs/probe3.txt`

---

## Claim 26: Sourcing inventory lists import_outside, import_file, outside_ok, IMPORT_DOTNEST, IMPORT_WHOLE

**Location:** `test/scripts/dev-cycle.bats:1110`, `:1114`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers presence after sourcing. It does not establish that the inventory is exhaustive.

The test passed in run S (dev-cycle 79/79). The names are defined at `scripts/lib/dev-cycle-read.sh:1140`, `:1154`, `:1158`, `:1030` and `:1035`.

**Evidence:** `test/scripts/dev-cycle.bats:1107-1117`, `logs/suite-dev-cycle.txt`

---

## Claim 27: Commit 55490d15: "build-loop-check 119, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2"

**Location:** commit `55490d15` message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test counts at 55490d15. It does not establish that they passed at that commit (HEAD's suites pass, run S).

Counts of `^@test` in `git show 55490d15:<file>`: 119, 20, 79, 2, 2 (paraphrased — no quote available because the counts come from a grep over five historical blobs). Main has 117: the commit rewrote one test and added two, which matches "three new" when the rewritten parser test is counted.

**Evidence:** `test/scripts/build-loop-check.bats`, `test/scripts/build-loop-read.bats`, `test/scripts/dev-cycle.bats`, `test/scripts/fixture-git-env.bats`, `test/fixture-hermeticity.bats` (at 55490d15 and main)

---

## Claim 28: Commit 55490d15: "Tests: three new (…), each red on main"

**Location:** commit `55490d15` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three tests as written at 55490d15. It does not establish which assertion fails first on main.

P3: with main's tree and 55490d15's test file and fixtures, all three were `not ok`. With 55490d15's own tree, all three were `ok` (`logs/probe3.txt`).

**Evidence:** `logs/probe3.txt`

---

## Claim 29: Commit 55490d15: "Over this worktree both walks give main's 64 names in about the same time (0.7-0.8 s); no walked file here holds an outside name."

**Location:** commit `55490d15` message
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the worktree at HEAD as of 2026-10-09T16:52Z. Timings depend on load (tree 0.55-0.59 s, main 0.77 s now). It does not establish the state at 55490d15.

P5: main's lib and HEAD's lib each gave 64 names for each walk, and the name lists are byte-identical. Times were tree 0.55/0.59 s and main 0.77/0.77 s. P4(a): 0 `//` lines in either list (`logs/probe4.txt`, `logs/probe5.txt`).

**Evidence:** `logs/probe4.txt`, `logs/probe5.txt`

---

## Claim 30: Commit 55490d15 Notes: "Of nine mutants tried, one survives: import_targets' `import_readers || return 1` made `|| true` (equivalent: an empty root list makes the parser exit 2)."

**Location:** commit `55490d15` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Carried from iteration 1 (override row 566, Accepted-immutable). It is not re-raised, and the nine unnamed mutants are not re-run.

An import_home failure returns from import_readers before `IMPORT_ROOTS=""` (`scripts/lib/dev-cycle-read.sh:1045`, `:1050`), so under `|| true` the parser would use a stale set. "Equivalent" is not quite right. No behaviour is affected: the real code returns 1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1044-1050`, `docs/reviews/override-log.md:566`

---

## Claim 31: Commit 55490d15: "a ROOT_REAL of / now fails a direct call too, as it always failed the walks"

**Location:** commit `55490d15` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the direct call. It does not re-establish the walks' history.

The suite asserts two `rc=1` lines, for ROOT_REAL `/` and for ROOT_REAL empty (`test/scripts/build-loop-check.bats:636-638`), and it passed in run S. P6 printed `caller root / rc=1`.

**Evidence:** `test/scripts/build-loop-check.bats:636-638`, `logs/probe6.txt`

---

## Claim 32: Commit 18fba03d: "build-loop-check 120, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2. 213 code lines against main."

**Location:** commit `18fba03d` message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the counts and the line total as `git diff --numstat main 18fba03d -- scripts test`. It does not count only non-comment lines (there are 107).

`--numstat`: 110+41, 53+5 and 2+2, so 213. The `^@test` counts at 18fba03d are 120, 20, 79, 2 and 2. HEAD runs the same counts green (run S).

**Evidence:** `logs/suites.rc`, `logs/suite-*.txt`

---

## Claim 33: Commit 18fba03d: "The three fix mutants each fail a test."

**Location:** commit `18fba03d` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers M1 (clear removed), M2 (newline check removed) and M3 (DIRS dropped), each applied to 82bb5281's lib. It does not establish the commit author's exact mutant spellings.

P3: M1, M2 and M3 each gave `not ok`, and the unmutated HEAD controls gave `ok`. The diffs printed in the log confirm that each mutation applied (`logs/probe3.txt`).

**Evidence:** `logs/probe3.txt`

---

## Claim 34: Commit 18fba03d: "a new test for the newline real path (both walks fail)"

**Location:** commit `18fba03d` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the observed outcome: both walks print `walk: failed`. Why the main walk fails is Claim 25, and the test title now says it.

The test asserts `want walk failed` for `tree` and `main` (`test/scripts/build-loop-check.bats:664`), and it passed in run S.

**Evidence:** `test/scripts/build-loop-check.bats:664`, `logs/suite-build-loop-check.txt`

---

## Claim 35: Commit 82bb5281: "Comments and a test title only; suites unchanged."

**Location:** commit `82bb5281` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `git show -U0 82bb5281 -- scripts test`. It does not cover the docs/ files it also changed.

Filtering the commit's +/- lines for lines that are not comments leaves only the old and new `@test` title of `test/scripts/build-loop-check.bats:660`. The suites at HEAD give 120/20/79/2/2, all ok (run S).

**Evidence:** `test/scripts/build-loop-check.bats:660`, `logs/suites.rc`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 3b** (`scripts/lib/dev-cycle-read.sh:724-733`): the exception list does not name an outside link into the gate's own checkout whose target the branch deleted. The main walk skips it as missing, so main's file reads not imported (executed: P4(c)). Name it, or route it to security.
- **Claim 18b** (`scripts/lib/dev-cycle-read.sh:1135-1139`): "returns 1 when … a read … fails" holds only under pipefail. Without it, an unreadable file returns 0 with `/0` (executed: P1). Both walks set pipefail. Say so for U2b3b2b's non-walk caller.
- **Claim 30** (commit 55490d15 Notes): the `|| true` mutant is not quite equivalent. Carried from row 566, Accepted-immutable.

### Unverifiable
- **Claim 20b** (`scripts/lib/dev-cycle-read.sh:1157`): "a session in this container cannot load it either". Checking it needs a Claude Code session probe. Carried from row 567.

## Goal-Alignment Note

The unit's goal is that both walks see repo → outside → repo chains and never answer "not imported" for a file a session loads. The goal is met for every case the brief lists. Executed: chains, links into the repo, DIRS, the whole-mode projection, the newline refusal, the inherited IMPORT_WHOLE, the refusal state, dotnest equality, budget fail-closed, and suites 120/20/79/2/2 green. The fix mutants die and the new tests are red on main.

Two residues are for the critics, not blockers here:

1. **The Claim 3b fail-open (narrow):** the main walk admits and projects outside names against the live checkout, while it reads repo names from main. An outside symlink pointing into the gate's own checkout at a file the branch deletes makes the floor answer "not imported" for a path main's sessions load through that link. A link into the main worktree, another reader root, still resolves, which limits the exposure.
2. **The Claim 18b pipefail dependence:** this matters once U2b3b2b adds a non-walk caller of import_file / import_outside.

No hallucination patterns were confirmed, so none were appended.
