Commit: 39f64d62
# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b3b2b, branch feat/build-loop-u2b3b2b)
**Scope:** `git diff 1c820663..39f64d62` (review iteration 1's fix commit), with the enclosing functions in `scripts/lib/dev-cycle-read.sh` read whole (`outside_seeds`, `root_starts`, `outside_proj`, `outside_ok`, `import_outside`, both walks' seed loops, the walk header, caller contract items 1-9), and the commit message of 39f64d62.
**Checked:** 2026-10-09
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 26
**Summary:** 20 verified, 4 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 30 lines). No claim below matches a logged pattern.

**Provenance note.** While this review ran, the worktree's `scripts/lib/dev-cycle-read.sh` gained uncommitted edits (an i2 performance N1 change at `:1287-1297`). Every executed verdict below was therefore re-run against `git show 39f64d62:scripts/lib/dev-cycle-read.sh`, copied into a temp dir, and the suites against a `git archive 39f64d62` export. Runs that touched the edited working-tree file are not cited. All line numbers are 39f64d62's. Captured outputs live in `/tmp/claude-1000/-workspace/7705a73b-d526-48c8-9948-70a1335d5801/scratchpad/u2b3b2b-fc2/` (below, `$S/`), next to the probe scripts that produced them. They are outside the repo because the dispatch allows this report as the only repo file.

---

## Claim 1: "walks 7 s → 3 to 3.5 s over 8 worktrees"

**Location:** `docs/working/plan-build-loop-handoff.md:306`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the wall time of both walks over /workspace's 8 registered worktrees at 39f64d62 and at 1c820663 under this session's load (1.4-2.6). It does not establish the times on an idle machine.

`git worktree list` printed 8 entries. Measured at 39f64d62 with the real HOME, `resolve_main; reader_settings`, and a fresh `import_reset` per walk:

- tree walk: 3.14, 3.30, 3.00, 3.16, 3.08 s
- main walk: 4.09, 4.19, 4.32, 3.84, 3.85 s
- 1c820663: 7.8-8.8 s

The tree walk is inside "3 to 3.5 s". The main walk ran 3.8-4.3 s in all five runs, at load 1.95-2.6 while other agents ran. Precise version: "about 3 s (tree) and 4 s (main) under load, from about 8 s".

Commands: `bash $S/probe2.sh` and `bash $S/probe7.sh`. cwd: the worktree, read-only. Both exited 0, at 2026-10-09T20:24:19-07:00 and 20:25:57-07:00.

**Evidence:** `$S/probe2-39.out`, `$S/probe7.out`, `scripts/lib/dev-cycle-read.sh:1411-1452`, `:1468-1514`

---

## Claim 2: "Seeding every @-bearing .md in other roots was tried and gave 6,720 seeds over /workspace's untracked clones (both walks failed)."

**Location:** `docs/working/plan-build-loop-handoff.md:307`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the claim's existence. It does not establish the count or the failure.

paraphrased — no quote available because the experiment's code was never committed (neither 1c820663 nor 39f64d62 holds a seed-every-@-.md variant), and the registry's untracked clones have changed since. Checking it would need the discarded patch, re-run over the same registry.

**Evidence:** `git log main..39f64d62` (two commits, neither holding the variant)

---

## Claim 3: "Both walks also read the repository's worktree registry (import_readers) and, through outside_seeds, the config dirs (each reader home's .claude, CLAUDE_CONFIG_DIR, IMPORT_MANAGED_DIR), the roots' ancestors and the other roots' file trees (find, grep, sha1sum, python3 on installed_plugins.json)"

**Location:** `scripts/lib/dev-cycle-read.sh:42-46`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the inputs `outside_seeds` reads. It does not establish that the parenthesised tool list is exhaustive: `xargs`, `realpath` and `tr` (`lower_all`) also run.

The config dirs come from `cf+=("${d%/}/.claude")` for each home, then `[[ -z "${CLAUDE_CONFIG_DIR:-}" ]] || cf+=("$CLAUDE_CONFIG_DIR"); cf+=("$IMPORT_MANAGED_DIR")` (`:1249-1250`). The ancestors come from the `while [[ "$d" != / ]]` loop (`:1253-1257`). The other roots are read through `root_starts "$r"` (`:1300`), python3 runs over `"${pj[@]}"` (`:1266-1269`), and sha1sum at `:1317`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1244-1321`

---

## Claim 4: "or CLAUDE_CONFIG_DIR or IMPORT_MANAGED_DIR (outside_seeds reads them): neither walk's cache key holds them"

**Location:** `scripts/lib/dev-cycle-read.sh:68-74`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both walks' memo keys. It does not establish that every caller calls import_reset after changing them.

The keys are `"$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1417`) and `"$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1474`). Neither holds either variable, and `outside_seeds` reads both at `:1247-1250`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1247-1250`, `:1417`, `:1474`

---

## Claim 5: Contract item 8, "Pass … prompt_bases a lower-cased path … floor, check_fix and the walks lower first"

**Location:** `scripts/lib/dev-cycle-read.sh:86-89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walks' outside prompt seeds: the lowered path goes in pdir, and the walk passes it to prompt_bases with the path as spelled. It does not establish floor's or check_fix's lowering, which this commit did not change.

Each seed loop sets `pdir[$p]="$(lower "$p")"` (`:1432`, `:1513`). The pop then calls `prompt_bases xs "${pdir[$f]}" "$f"` (`:1437`, `:1519`). The C1 test adds a `.CLAUDE` prompt, `printf 'p: @docs/up.md\n' > "$sd/sub/.CLAUDE/commands/p.md"`, and expects `sub/docs/up.md imported` (`test/scripts/build-loop-check.bats:724-742`). It passes for both walks.

Command: `bash $S/suites.sh $S`, a `git archive 39f64d62` export. Exit 0 at 2026-10-09T20:25:39-07:00.

**Evidence:** `$S/suites39.log`, `$S/suite39-build-loop-check.tap`, `scripts/lib/dev-cycle-read.sh:1432`, `:1513`, `:667-676`

---

## Claim 6: The walk header's named exceptions: "a home or root this container cannot see …; an import a start in another root reaches there through a file that root holds with other bytes or alone (routed to U2b3b2c); a symlinked directory in another root (A5); and a C1 start whose bytes match ROOT_REAL's in a checkout that is not clean"

**Location:** `scripts/lib/dev-cycle-read.sh:749-754`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the match between each named exception and the code: `find -P` does not enter linked dirs, the same-bytes skip, and no read of another root's non-start copy. It does not establish that the list is complete (see the Goal-Alignment Note on the innermost-root change).

`root_starts` lists with `find -P "$1" -name .git -prune -o '(' -type f -o -type l ')'` (`:1211`), so a linked directory is neither entered nor listed. A seed is skipped only when `[[ "${lo[2*i]:0:40}" == "${lo[2*i+1]:0:40}" ]]` (`:1318`) compares equal against `ir[i]`, the copy relative to ROOT_REAL. Nothing in `outside_seeds` reads another root's non-start file (paraphrased — no quote available because the claim covers absence of code: no path in `:1244-1321` lists other roots except `root_starts`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1211`, `:1296-1319`

---

## Claim 7: "Any seed listing find, grep or sha1sum cannot complete fails the walk, so an unreadable directory in any registered worktree, or a link loop under a config dir's trees, fails every walk"

**Location:** `scripts/lib/dev-cycle-read.sh:754-758`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers find failures (an unreadable dir, a link loop) and a killed or signalled grep or sha1sum. It does not hold for a grep that finishes with error status 2 on a file.

The find half holds. Under `find -L`, a link loop exits 1 with "File system loop detected" (P12, GNU findutils 4.9.0, which is `/usr/bin/find` in non-interactive bash). `nul_list` then fails, and so does `|| return 1` (`:1273-1276`). The unreadable-directory case is the suite's locked-`rules/` test, which passes.

grep is the exception. The wrapper is `sh -c 'grep -lsZF -e @ -- "$@"; [ $? -le 2 ]' sh` (`:1288`, `:1308`). It turns grep's status 2, which GNU grep 3.8 returns for any error, into success. A grep that hits an error on a file therefore completes as a no-match for that file, and the walk goes on without it. Claim 16 has the consequence. Precise version: "Any seed listing find or sha1sum cannot complete, or a grep killed by a signal, fails the walk; grep's per-file errors drop that file".

Commands: `bash $S/probe7.sh` (P12), exit 0 at 2026-10-09T20:26:24-07:00. Suites: `$S/suites39.log`.

**Evidence:** `$S/probe7.out`, `$S/suites39.log`, `scripts/lib/dev-cycle-read.sh:1273-1276`, `:1288`, `:1308`

---

## Claim 8: "over this repository's 8 registered worktrees, about 85 seeds and 3 to 3.5 s per walk, against 0.6 s without (2026-10-09; i1 performance)"

**Location:** `scripts/lib/dev-cycle-read.sh:759-761`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the worktree count, the seed count and the walk times with and without seeds (outside_seeds stubbed to an empty array) under load ~2. It does not establish idle-machine times.

- worktrees: 8.
- seeds: `outside_seeds` returned 85 at 39f64d62, against 143 at 1c820663 (P7).
- with seeds: tree 3.0-3.3 s, main 3.8-4.3 s.
- without seeds: tree 0.63-1.17 s, main 0.80-0.85 s.

The seed count is exact. The main walk sat above the stated band in every run, and "0.6 s without" is the low end of the tree walk alone. Precise version: "about 3-4 s per walk, against 0.6-0.9 s without".

Commands: `bash $S/probe3.sh` (P7, exit 0, 2026-10-09T20:24:16-07:00) and `bash $S/probe7.sh` (P11).

**Evidence:** `$S/probe3-39.out`, `$S/probe7.out`

---

## Claim 9: import_outside and outside_ok take "an outside_seeds start, which may lie in another root"

**Location:** `scripts/lib/dev-cycle-read.sh:1152-1155`, `:1184-1186`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two header updates against the seed loops. It does not establish anything about import_outside's body, which this commit did not change.

Both walks queue each seed as `p="${f:1}"` after `outside_ok "$p"` (`:1431`, `:1512`), and C1 seeds are paths below other roots (`cx+=("$d")`, `:1301`). `import_file` sends any `/`-led path to `import_outside` (`:1183`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1183`, `:1301`, `:1431`, `:1512`

---

## Claim 10: "no // name: no fork (i1 performance F3)"

**Location:** `scripts/lib/dev-cycle-read.sh:1199`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guard's match for a `//` line at any position. It does not establish outside_proj's behaviour once a `//` line exists, which is unchanged.

`[[ "$op_o" == //* || "$op_o" == *$'\n'//* ]] || return 0` matches a first line or any later line that starts with `//`. A relative name never starts with `/` (`import_work`'s comment, `:1322-1324`), so no `//` name can be missed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1197-1207`

---

## Claim 11: "root_starts ROOT: the start-named files (instruction_names) below ROOT … listed with find -P (.git pruned): regular files and links. It fails when find or grep does."

**Location:** `scripts/lib/dev-cycle-read.sh:1208-1211`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the listing and its failure paths. It does not establish that instruction_names' match on absolute paths is a superset of isstart on root-relative paths, which is argued under Claim 18.

`root_starts() { local -; set -o pipefail; find -P "$1" -name .git -prune -o '(' -type f -o -type l ')' -iname '*.md' -print0 | instruction_names; }` (`:1211`). Under pipefail, a find failure fails the pipe. `instruction_names` is `grep -zaiE … || [[ $? -eq 1 ]]` (`:1337`), so grep's status 2 fails it and only no-match succeeds.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1211`, `:1337`

---

## Claim 12: "(3) C1: every start file (isstart, by its path below its innermost root) in another reader root present here, tracked or not (a superset)."

**Location:** `scripts/lib/dev-cycle-read.sh:1223-1224`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code's isstart authority, which is the innermost-root path, as the comment says. It does not establish that this set contains every start a session in the *outer* root sees. For a root nested in a listed root below a `.claude/<prompt-dir>/` there, the outer-root reading was in 1c820663's set and is not in 39f64d62's (P5).

`ir` holds each path below its longest matching root (`:1306`). Then `isstart "${lo[i]}"` runs on `lower_all "${ir[@]}"` (`:1307`, `:1311`).

P5 built worktree A, a third worktree C as ROOT_REAL, and a worktree at `A/.claude/skills/wt` holding `README.md` with `r: @docs/z.md`:

- 1c820663 seeded `pA/.claude/skills/wt/README.md`, its isstart running on the A-relative path `.claude/skills/wt/readme.md`.
- 39f64d62 does not seed it: the innermost-root path `readme.md` is no start.

The 39f64d62 behaviour matches its comment. The change is reported as a regression candidate in the Goal-Alignment Note.

Command: `bash $S/probe1.sh` (P1-P5). cwd: temp dirs under `/tmp/u2b3b2b-fc2-*`, removed. Exit 0 at 2026-10-09T20:24:12-07:00.

**Evidence:** `$S/probe1-39.out`, `scripts/lib/dev-cycle-read.sh:1304-1311`

---

## Claim 13: "A root below another listed one comes with it, unless it lies below ROOT_REAL, whose files that listing drops: then it is listed itself (and a root below it twice, which the walks' seen absorbs)."

**Location:** `scripts/lib/dev-cycle-read.sh:1224-1227`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the listing-selection loop and the drop rule. It does not establish duplicates' cost: a duplicate also enters the `hs`/sha1sum list twice.

`in=""; [[ "$r" == "$ROOT_REAL"/* ]] || for q in "${cr[@]}"; do [[ "$r" != "$q"/* ]] || in=1; done` (`:1298`) lists every root below ROOT_REAL on its own. `[[ "$d" == "$ROOT_REAL"/* && "$r" != "$ROOT_REAL"/* ]] || cx+=("$d")` (`:1301`) drops ROOT_REAL's files only from a listing whose root lies above ROOT_REAL. Two roots that both lie below ROOT_REAL, one nested in the other, are both listed, so the inner one's files appear twice. The seed loops skip a repeat through `seen` (`:1431`, `:1512`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1296-1302`, `:1431`, `:1512`

---

## Claim 14: "One whose bytes equal ROOT_REAL's plain file (rawfile) at that path is skipped" / "rawfile: a ROOT_REAL copy reached through a link the tree walk does not start at (i1 fact-check 19b)"

**Location:** `scripts/lib/dev-cycle-read.sh:1227-1231`, `:1313`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip condition: a non-link seed, `rawfile` on the innermost-root path, outside_ok, and equal SHA-1. It also covers the rubric's A1 fix (Fixed is confirmed). It does not establish the clean-checkout precondition, which is the caller's (contract item 2).

The skip runs only when `[[ ! -L "${cx[i]}" ]] && rawfile "${ir[i]}" && outside_ok "${cx[i]}"` holds. Otherwise the seed goes straight to `os_a` (`:1314`). `rawfile` needs `-f` and `realpath -e` equal to `$ROOT_REAL/$1` (`:160`), so a ROOT_REAL copy behind a link is no skip target.

The C1 test makes ROOT_REAL's `CLAUDE.md` a link to `docs/l.md`, which holds `@docs/v.md`. It then wants `docs/v.md imported` and `GEMINI.md` (no `@`) absent from the seeds. Both walks pass (`test/scripts/build-loop-check.bats:724-742`).

**Evidence:** `$S/suite39-build-loop-check.tap`, `scripts/lib/dev-cycle-read.sh:160`, `:1310-1319`

---

## Claim 15: "Only a seed holding an @ byte or reached through a link (import_outside projects its real path) can yield a name, so the rest are dropped" / "The config seeds that can yield a name: an @ in the file, or a link on the way."

**Location:** `scripts/lib/dev-cycle-read.sh:1236-1238`, `:1287`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every parser path and both phases' tests:
- parser: the scan, the comment splice, quoted mentions, the U+FFFD-decoded copy and the IMPORT_WHOLE projection;
- config phase: `realpath -m` differs, which catches a link anywhere on the path, as with `find -L` under a linked dir;
- C1 phase: `-L` on the file only, sound because `find -P` from a realpath'd root never passes through a linked dir.

It does not establish output equality for inputs other than /workspace's 8 worktrees and this HOME.

The parser emits names only from `names()` calls inside `scan`, after `if (substr(line, i, 1) != "@") continue` (`:941`). Its other inputs never create an `@` byte:
- `quoted()` is reached from a scanned `@"` (`:944-948`) or an open quote that one began (`:994-996`);
- `splice` removes comment text (`:966-974`);
- python3's `"replace"` decoding writes U+FFFD, never 0x40 (`:1141`);
- UNI_SPACES become blanks (`:1149`).

The one name source with no `@` is the IMPORT_WHOLE projection of a differing real path (`:1174`), and that is the link case.

P1 (config): `rules/a.md` without `@` was dropped, while `rules/b.md` with `@` and `rules/ln/c.md`, `@`-free behind a linked dir, were kept. P6 (real repo): both walks' full lists (1,628 lines, 1,177 non-`//` names) are byte-identical between 1c820663 and 39f64d62.

**Evidence:** `$S/probe1-39.out`, `$S/probe2-39.out`, `scripts/lib/dev-cycle-read.sh:930-975`, `:1169-1176`, `:1287-1291`, `:1308-1311`

---

## Claim 16: "an unreadable file is skipped, as outside_ok skips it."

**Location:** `scripts/lib/dev-cycle-read.sh:1238-1239`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a file without read permission (executed). It does not establish equivalence for other grep errors: an I/O error mid-read, or memory exhaustion on a huge line, also give status 2. Those drop a file that outside_ok would admit, and that import_outside would read or fail on.

P3 put `@y.md` in a `chmod 000` rules file. `outside_seeds` returned 0 without it, matching `outside_ok() { [[ -f "$1" && -r "$1" ]]; }` (`:1188`). The wrapper `[ $? -le 2 ]` (`:1288`, `:1308`) accepts status 2 whatever its cause, and the file is not listed. Without the filter, a walk reading such a file through import_outside would fail on `capped_read`'s non-zero exit under pipefail (`:1173`), not skip it.

The difference is fail-closed becoming skip. It applies only to a readable non-link file that grep cannot finish reading. A link is kept regardless, through the realpath or `-L` test. Precise version: "a file grep cannot read (unreadable, or a read error) is dropped; outside_ok skips the unreadable ones too".

Command: `bash $S/probe1.sh` (P3).

**Evidence:** `$S/probe1-39.out`, `scripts/lib/dev-cycle-read.sh:1173`, `:1188`, `:1288`, `:1308`

---

## Claim 17: "It returns 1 when a find, grep, sha1sum, realpath or lower_all fails, a seed's path holds a newline, or CLAUDE_CONFIG_DIR is set but not absolute."

**Location:** `scripts/lib/dev-cycle-read.sh:1241-1243`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed return path, with relative CLAUDE_CONFIG_DIR and realpath failure executed. "grep fails" means status >2 or a killed grep, per Claim 7. It does not establish the python3 path, which falls back rather than failing.

The relative-dir check is `[[ -z "${CLAUDE_CONFIG_DIR:-}" || "$CLAUDE_CONFIG_DIR" == /* ]] || return 1` (`:1247`), and the suite's relative-CLAUDE_CONFIG_DIR test passes. When realpath fails (E2BIG, P2), `outside_seeds` printed `rc=1`. The newline check is at `:1320`.

**Evidence:** `$S/probe1-39.out`, `$S/suite39-build-loop-check.tap`, `scripts/lib/dev-cycle-read.sh:1247`, `:1290`, `:1320`

---

## Claim 18: "Each one's path below its innermost root: isstart's (the authority, after instruction_names' prefilter), the prompt test's and the byte comparison's."

**Location:** `scripts/lib/dev-cycle-read.sh:1304-1305`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the use of `ir`/`lo` in all three tests. instruction_names' patterns are anchored on `(^|/)`, so matching them on absolute paths is a superset of matching root-relative ones. It does not establish the outer-root reading (Claim 12's residue).

`ir+=("${d#"$q"/}")` with `q` the longest root prefix (`:1306`). `lo` comes from `lower_all "${ir[@]}"` (`:1307`). `isstart "${lo[i]}"` (`:1311`), `[[ ! "${lo[i]}" =~ $PROMPT_DIR ]]` (`:1312`) and `rawfile "${ir[i]}"`/`hs+=(… "${ir[i]}")` (`:1314`) all read it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1304-1314`, `:1337`

---

## Claim 19: The prompt seed's `pdir[$p]="$(lower "$p")" || return 1` leaves the walk in its error state

**Location:** `scripts/lib/dev-cycle-read.sh:1432`, `:1513`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assignment's status and both walks' state on that return. It does not establish when `lower` (`printf | tr`) can fail in practice.

An associative-element assignment returns its command substitution's status. In P4, `m[x]="$(false)" || echo` printed `assign rc=1`, and `[[ "$x" != p* ]] || pdir[$x]="$(exit 3)" || return 1` returned 1. `IMPORTED=error` is already set at `:1418`, with IMPORTED_DONE keyed, so a later call returns the cached error through `:1417`. `IMPORTED_MAIN=error` is likewise set at `:1475`.

**Evidence:** `$S/probe1-39.out`, `scripts/lib/dev-cycle-read.sh:1417-1418`, `:1474-1475`

---

## Claim 20: "A relative CLAUDE_CONFIG_DIR is not modelled: the walk fails (i1 api F5)."

**Location:** `test/scripts/build-loop-check.bats:706`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks with `CLAUDE_CONFIG_DIR=rel`. It does not establish a CLAUDE_CONFIG_DIR that is absolute but missing, which is skipped by `-d`.

`CLAUDE_CONFIG_DIR=rel imps "$w" docs/o.md; want walk failed` passes for both walks. The code is at `:1247`.

**Evidence:** `$S/suite39-build-loop-check.tap`, `scripts/lib/dev-cycle-read.sh:1247`

---

## Claim 21: Test name "skipping one whose bytes match this checkout's plain copy or that holds no @"

**Location:** `test/scripts/build-loop-check.bats:724`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions: AGENTS.md (same bytes) and GEMINI.md (no `@`) are absent from the seeds, and the linked CLAUDE.md's import is reached. It does not establish a test for a C1 seed dropped because grep errored.

`! printf '%s\n' "$output" | grep -qF -e "$sd/AGENTS.md" -e "$sd/GEMINI.md"` (`:742`), which passes.

**Evidence:** `$S/suite39-build-loop-check.tap`, `test/scripts/build-loop-check.bats:724-742`

---

## Claim 22a: "only seeds holding an @ or reached through a link are kept (xargs grep …)": the grep and sha1sum argument lists cannot overflow

**Location:** commit 39f64d62 message; `scripts/lib/dev-cycle-read.sh:1288`, `:1308`, `:1317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two greps and sha1sum, each under `xargs -0r -a <(…)`. It does not cover the other external commands in the same filter (22b).

For 40,003 seeds (4.6 MB of paths), the xargs grep listed 40,001 files and exited 0 (P2).

**Evidence:** `$S/probe1-39.out`

---

## Claim 22b: "… (xargs grep, so no argument list overflows)": the seed filter has no argument-list overflow

**Location:** commit 39f64d62 message; `scripts/lib/dev-cycle-read.sh:1290`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the config phase's `realpath -mz -- "${cx[@]}"`, which this commit added. That realpath decides the filter's "reached through a link" half, and it is one exec over every config seed. It does not establish whether a real config tree reaches the limit (ARG_MAX here is 2,097,152).

The fix added `[[ ${#cx[@]} -eq 0 ]] || nul_list rl realpath -mz -- "${cx[@]}" && [[ ${#rl[@]} -eq ${#cx[@]} ]] || return 1` (`:1290`), one argv holding every config seed (rules, prompts, plugin caches, memory, top-level starts). In P2, 40,000 rules files in a fixture HOME made `outside_seeds` print `/usr/bin/realpath: Argument list too long` and return 1, so both walks fail. 1c820663 had no realpath over config seeds: it appended them directly. So this is a new E2BIG site, inside the hunk the sentence describes.

It fails closed, so no name is lost. But the claim, and the rubric's K11 "Fixed (xargs)" with performance i2 F4 "the E2BIG part is fixed", read as clearance that does not hold. Fix: run this realpath under `xargs -0r -a <(…)` as the others are, or reword.

Command: `bash $S/probe1.sh` (P2). cwd: temp dir. Exit 0 at 2026-10-09T20:24:16-07:00.

**Evidence:** `$S/probe1-39.out`, `scripts/lib/dev-cycle-read.sh:1290`

---

## Claim 23: "Walks over this repository's 8 worktrees: 7 s -> 3 to 3.5 s, same names."

**Location:** commit 39f64d62 message
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "same names", where the full IMPORTED and IMPORTED_MAIN line sets are identical between 1c820663 and 39f64d62, and the worktree count. The timing half carries Claim 1's Mostly-accurate qualifier (main walk 3.8-4.3 s under load), which this verdict does not repeat.

P6: tree and main, old and new, each 1,177 non-`//` names and 1,628 lines, and `diff` is empty for both walks.

**Evidence:** `$S/probe2-39.out`

---

## Claim 24: "A relative CLAUDE_CONFIG_DIR fails the walk (api F5); python3's traceback stays off stderr (security F5)"

**Location:** commit 39f64d62 message; `scripts/lib/dev-cycle-read.sh:1247`, `:1269`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both fixes through their suite tests. It does not establish stderr silence for other children of `outside_seeds`: find and realpath still write to stderr, as P2 shows for realpath.

`"${pj[@]}" 2>/dev/null` (`:1269`). The test appends `[ -z "$stderr" ] || return 1` after the malformed `installed_plugins.json` (`test/scripts/build-loop-check.bats:705`), and it passes.

**Evidence:** `$S/suite39-build-loop-check.tap`, `scripts/lib/dev-cycle-read.sh:1269`

---

## Claim 25: "Suites 125/79/20/2/2; 302 code lines against main."

**Location:** commit 39f64d62 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers build-loop-check (125), dev-cycle (79), build-loop-read (20), fixture-git-env (2) and utility-smoke (2), all passing at 39f64d62, plus `git diff --numstat main...39f64d62` outside `docs/` (273 + 29 = 302). It does not establish which suites the author meant by the two 2-test entries.

Command: `bash $S/suites.sh $S`, a `git archive 39f64d62` export, `TMPDIR` under `/tmp/u2b3b2b-fc2-ts-*`. Exit 0, 2026-10-09T20:24:12 to 20:25:39-07:00. Every suite was `ok` with none `not ok`.

**Evidence:** `$S/suites39.log`, `$S/suite39-*.tap`

---

## Claims Requiring Attention

### Incorrect
- **Claim 22b** (`scripts/lib/dev-cycle-read.sh:1290`, commit message): the new config-phase `realpath -mz -- "${cx[@]}"` is one argv over every config seed. 40,000 rules files hit E2BIG and fail both walks (fail-closed). Run it under `xargs` like the greps and sha1sum, or drop "no argument list overflows". Rubric K11 / performance i2 F4 ("E2BIG fixed") rest on this.

### Mostly Accurate
- **Claim 1** (`docs/working/plan-build-loop-handoff.md:306`): "3 to 3.5 s" fits the tree walk (3.0-3.3 s). The main walk measured 3.8-4.3 s under load ~2.
- **Claim 7** (`scripts/lib/dev-cycle-read.sh:754-758`): grep's error status 2 is accepted, so a grep error drops a file rather than failing the walk. Only find, sha1sum and a killed grep fail it.
- **Claim 8** (`scripts/lib/dev-cycle-read.sh:759-761`): 8 worktrees and 85 seeds are exact. Times are 3-4 s with seeds and 0.6-0.9 s without, not "3 to 3.5" and "0.6".
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:1238-1239`): status 2 covers any grep read error, not only a permission failure. A readable non-link file that grep cannot finish is dropped, where import_outside would have failed the walk.

### Unverifiable
- **Claim 2** (`docs/working/plan-build-loop-handoff.md:307`): the 6,720-seed experiment's code was not committed. Checking it needs the discarded patch.

---

## Goal-Alignment Note

The goal is to land U2b3b2b after a clean review-fix loop, and this pass checks the iteration-1 fix commit.

**Rubric Fixed items:**
- Confirmed: A1 (Claim 14), A4 (Claim 5), A5 (Claim 4), A6 (Claims 15 and 23: same names, about half the time), K1, K2, K3, K4, K5, K6, K9, K10, K13.
- Partly fixed: K11. sha1sum and grep are fixed, but the fix commit added a new single-argv `realpath` over every config seed (Claim 22b). A config tree past about 2 MiB of paths now fails both walks, where 1c820663 did not exec over that list at all. It is fail-closed but a regression, and the rubric and performance i2 report it as fixed.

**Regressions the fixes introduced:**
1. **Claim 22b** (above).
2. **C1's isstart authority moved from the listed (outer) root's path to the innermost root's path** (Claim 12, P5). A worktree nested in another listed root below a `.claude/{commands,agents,output-styles,skills,rules}/` there loses starts that a session in the outer root would read. In P5, `README.md` lost its start status. A `SKILL.md` there survives but is now tagged `f`, so it is no longer read against prompt_bases. 1c820663 seeded those files.

   The layout is unusual: /workspace's worktrees sit at `.claude/wt-*`, which no prompt dir matches. The outer root's own tree walk also skips nested-repo files (known issue A5). The cheap restore is isstart on either path. If the lead accepts the narrowing instead, the walk header should name it.

**Smaller items:**
- The grep wrapper's `[ $? -le 2 ]` makes any per-file grep error a skip (Claims 7 and 16). The header's "Any seed listing … grep … cannot complete fails the walk" overstates this. The practical exposure is a readable file with a mid-read I/O error, low.
- The `pdir` lowering keeps both walks in their error state on failure (Claim 19).

**Process note.** The worktree's lib was edited, uncommitted, during this review. Reviewers that probed the working-tree file may have measured the i2 N1 edit instead of 39f64d62. In this session, one probe of the edited file returned 50 seeds instead of 85, and a debug copy of it hit `rl[i]: unbound variable`. That copy had a debug line inserted at the wrong offset, so it is not evidence against the edit, but a reviewer reading such runs would be misled.

Single-sample review; absence of findings is not an attestation.
