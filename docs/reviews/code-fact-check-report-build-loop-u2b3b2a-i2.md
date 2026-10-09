Commit: f7a96eed

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u2b3b2a, branch feat/build-loop-u2b3b2a)
**Scope:** fix range `55490d15..HEAD` (261ecd96 context only; 18fba03d, f7a96eed): scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, and the two commit messages
**Checked:** 2026-10-09
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 30
**Summary:** 27 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

I read the hallucination-pattern log (docs/reviews/hallucination-patterns.md). Its entries are mostly "a measured value quoted from an artifact set that does not hold it", among them commit-message test tallies. So I re-measured this commit's tallies and code-line count (Claims 26, 27). Each matches as stated. No claim matches a logged pattern.

Execution logs (scratch, bare paths): `/tmp/claude-1000/-workspace/715dcdb7-5140-4bd1-a115-cbeff3508ce5/scratchpad/u2b3b2a-i2/fact-check/{mutants,mainonly,edges,py3,nowork,suites}.log`. The probe scripts that wrote them sit beside them as `*.sh`. Each probe starts with `set -eu`, makes its own mktemp dir, cds there, and removes the dir afterwards. The mutant probes ran on `git archive HEAD` copies, so the worktree was never edited.

---

## Claim 1: "Both walks follow an import to a file below no reader root ... when outside_ok admits it, reading it from the file system ... through import_outside (the main walk in phase 2); one that is missing, unreadable or not a regular file here is skipped."

**Location:** `scripts/lib/dev-cycle-read.sh:720-723`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the admission and skip of a // name in both walks, and the main walk queuing it to tq (phase 2). It does not establish what happens after admission when the file changes (Claims 2, 12).
**Legibility-target:** for-orchestrator-synthesis

The tree walk: `[[ "$p" != //* ]] || { p="${p#/}"; outside_ok "$p" && [[ "$seen" != ... ]] && seen+="$p"$'\n' && queue+=("$p"); continue; }` (`:1272`). The main walk: `... && outside_ok "$p" && seen[$p]=1 && tq+=("$p"); continue; }` (`:1380`). An absolute path has no `ent` entry, so when popped it takes `case "${ent[$f]-checkout}" in checkout) ... import_file "$f" ...` (`:1340-1341`). `import_file` sends a leading-`/` FILE to `import_outside` (`:1148`). The existing test "an outside name whose real path lies in the repo ... unreadable, missing or non-regular outside name is skipped" passes at HEAD (suites.log: build-loop-check 1..120, no `not ok`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1148`, `:1152`, `:1272`, `:1340-1341`, `:1380`. Command: `bats test/scripts/build-loop-check.bats` (and the four other suites). cwd /workspace/.claude/wt-build-loop-u2b3b2a, TMPDIR a fresh mktemp dir, 2026-10-09T16:33:26Z to 16:34:53Z. No `not ok` lines. The exit codes were not captured, because the zsh wrapper read `PIPESTATUS` empty. suites.log

---

## Claim 2: "Known exceptions: a file ... this container cannot see (under a reader home such as the host's ... or under another uid ...), and a regular file swapped for a FIFO after its admission, which stalls the read (as a checkout file can)."

**Location:** `scripts/lib/dev-cycle-read.sh:724-728`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the FIFO stall in import_outside and the skip of a name under an absent home. It does not establish the checkout phase's own FIFO behaviour (stated by reference only).
**Legibility-target:** for-orchestrator-synthesis

The probe ran `timeout 3 ... IMPORT_WORK_LEFT=1000 import_outside "$O/f.md"` on a FIFO and got `inner_rc=124`, so the read blocked. `import_outside` reads through `capped_read < "$1"` (`:1140`), and opening a FIFO with no writer blocks. A `~/` name is joined to every reader home (`for (i = 1; i <= nh; i++) if (homes[i] != "") put(homes[i] "/" substr(c, 3))`, `:857`). A home that is absent here yields a // name, which `outside_ok` (`[[ -f "$1" && -r "$1" ]]`, `:1152`) rejects, so the file is skipped.

**Evidence:** `scripts/lib/dev-cycle-read.sh:857`, `:1140`, `:1152`. Command: `bash .../fact-check/edges.sh`, cwd a mktemp fixture repo, 2026-10-09T16:34:05Z, exit 0. edges.log (`== fifo`)

---

## Claim 3: "A large outside file a prefix names (@/usr/bin/python3.md reads /usr/bin/python3) or a very long absolute name (each prefix prints, about L*L/2 bytes ...) can spend a walk's budget, which fails closed"

**Location:** `scripts/lib/dev-cycle-read.sh:728-733`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the python3 example on this host (6.8 MB binary) for the tree walk and for import_targets. It does not establish the long-name L*L/2 figure by execution (that part is static: `names()` emits every prefix, `:935-943`, and each distinct absolute prefix is shown once).
**Legibility-target:** for-orchestrator-synthesis

On a fixture whose AGENTS.md is `See @/usr/bin/python3.md`, `imported_names` returned `walk_rc=1` after 1514 ms. Run directly, `head -c 4194305 /usr/bin/python3 | IMPORT_WORK_LEFT=50000000 import_targets /` returned 1 with trailer `/8115791`, so it stopped at the IMPORT_LEFT print budget (`if (printed - 1 > left) exit 3`, `:903`). With IMPORT_LEFT raised, it returned 1 at the work bound, trailer `/50000619` (`if (work > wmax) exit 3`). Both failures are fail-closed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:903`, `:935-943`. Commands: edges.sh (`== python3_prefix`, 2026-10-09T16:34:05Z, exit 0) and py3.sh (2026-10-09T16:34:26Z, exit 0), each with cwd a mktemp fixture repo. edges.log, py3.log

---

## Claim 4: "The walks' lists (IMPORTED, IMPORTED_MAIN) also hold the second channel's lower-cased // names, which no repo path isimported asks for can match."

**Location:** `scripts/lib/dev-cycle-read.sh:736-737`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what both lists append and how isimported matches. It does not establish that callers never pass a //-led path to isimported.
**Legibility-target:** for-orchestrator-synthesis

Both walks append the whole lower-cased output, // lines included: `IMPORTED+="$lp"$'\n'` (`:1269`) and `IMPORTED_MAIN+="$i"$'\n'` (`:1376`). isimported matches a whole line: `[[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]` (`:1399-1400`). A repo-relative path never starts with `//`, so it cannot match one of those lines.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1269`, `:1376`, `:1390-1400`

---

## Claim 5: "made absolute (ROOT/DIR/name for each reader root and each of $1 and the further directories, or DIR/name for one led by /, unless the name starts with /)"

**Location:** `scripts/lib/dev-cycle-read.sh:810-811`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers emit's join rule for relative and absolute names. `~/` names are covered by the same paragraph's later sentence, not by this one.
**Legibility-target:** for-orchestrator-synthesis

```awk
# scripts/lib/dev-cycle-read.sh:863-864
  if (substr(c, 1, 1) == "/") { put(c); return }
  ...
  for (i = 0; i <= nd; i++) if (substr(dirs[i], 1, 1) == "/") put(dirs[i] "/" c); else for (r = 1; r <= nr; r++) put(roots[r] "/" dirs[i] "/" c)
```
(The excerpt ends at :864, the last line of emit, which I read from :846.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:846-865`

---

## Claim 6: "(dotnest, from import_readers)"

**Location:** `scripts/lib/dev-cycle-read.sh:883`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the awk's dotnest table comes from. It does not establish the table's correctness (Claim 9).
**Legibility-target:** for-orchestrator-synthesis

The awk fills the table from the environment: `n = split(ENVIRON["IT_DOTNEST"], dn, "\n"); ... dotnest[ab[1], ab[2]] = 1` (`:961`). import_targets passes `IT_DOTNEST="$IMPORT_DOTNEST"` (`:1120`), and only import_readers builds that variable (`:1087-1092`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:961`, `:1087-1092`, `:1120`

---

## Claim 7: "IMPORT_DOTNEST holds the parser's dotnest pairs over IMPORT_ROOTS (its comment in the body says how)."

**Location:** `scripts/lib/dev-cycle-read.sh:1007-1008`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one dot-nested worktree. It does not establish behaviour with multiple nesting levels.
**Legibility-target:** for-orchestrator-synthesis

With a worktree added at `.claude/wt-x`, `import_readers; printf "[%s]\n" "$IMPORT_DOTNEST"` printed `[1 2]`: root 2 lies under root 1 through a dot component. The body comment at `:1087-1088` gives the "I J" format.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1087-1092`. edges.sh `== dotnest`, 2026-10-09T16:34:05Z, exit 0. edges.log

---

## Claim 8: "Set only for one import_targets call (import_outside's projection); cleared here, so an inherited one cannot make every walk read its text as whole names"

**Location:** `scripts/lib/dev-cycle-read.sh:1030-1032`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lib, dev-cycle.sh and build-loop.sh: no script sets IMPORT_WHOLE after sourcing. It does not establish behaviour for a future caller that assigns it after sourcing.
**Legibility-target:** for-orchestrator-synthesis

`rg IMPORT_WHOLE scripts test` finds exactly one assignment outside tests, `IMPORT_WHOLE=1 import_targets /` (`:1141`), plus the clearing `IMPORT_WHOLE=""` (`:1032`). With `export IMPORT_WHOLE=1` set before sourcing, the probe read back `[]` and `declare -x IMPORT_WHOLE=""`. The variable stays exported but empty, and import_targets reads `${IMPORT_WHOLE:-}` (`:1102`, `:1121`). Mutant m1 deletes `:1032`. It fails the chain test (`# want: docs/x.md: imported`) and the dev-cycle sourcing test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1032`, `:1102`, `:1121`, `:1141`. edges.sh `== whole_cleared_exported` (2026-10-09T16:34:05Z, exit 0) and mutants.sh `== m1_no_clear` (2026-10-09T16:32:44Z, exit 0). edges.log, mutants.log

---

## Claim 9: "IMPORT_DOTNEST: the parser's dotnest pairs, "I J" lines by 1-based index into IMPORT_ROOTS" (trailing newline stripped)

**Location:** `scripts/lib/dev-cycle-read.sh:1087-1092`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the format and that the awk still reads the last pair now that the trailing newline is gone. It does not establish cache or key effects (IMPORT_DOTNEST is in no key; it is rebuilt with IMPORT_ROOTS).
**Legibility-target:** for-orchestrator-synthesis

`IMPORT_DOTNEST="${IMPORT_DOTNEST%$'\n'}"` (`:1092`) leaves `1 2` with no trailing newline (probe output `[1 2]`). The awk splits on "\n" and keeps only two-field lines (`if (split(dn[i], ab, " ") == 2)`, `:961`), so the last pair is still read and an empty value yields no pairs. The dot-nested-root test at build-loop-check.bats:631 passes at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:961`, `:1092`. edges.log `== dotnest`, suites.log

---

## Claim 10: "import_outside FILE [DIRS...]: ... read from the file system against its own directory and each DIRS entry ...; when its real path differs ..., that path is also projected whole (IMPORT_WHOLE) ..., which the walk then reads again under its real path."

**Location:** `scripts/lib/dev-cycle-read.sh:1123-1130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the DIRS pass-through and the whole-name projection. "Reads again" holds only when the projected name is itself admitted (a // name passing outside_ok, or a repo file).
**Legibility-target:** for-orchestrator-synthesis

`a="$(capped_read < "$1" | import_targets "${d:-/}" "${@:2}")"` (`:1140`) and `if [[ "$r" != "$1" ]]; then b="$(printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /)"` (`:1141`). The new test's second half prints both `docs/n.md` (from DIRS "") and `//$o/docs/n.md` (from its own directory). Mutant m3 (`import_outside "$1"` without `${@:3}`) fails that test: `# missing docs/n.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1136-1143`. mutants.log `== m3_no_dirs`

---

## Claim 11: "For a walk, which sets IMPORT_WORK_LEFT: the two trailers are summed into one, and each call may spend all that a walk has left, so the walk's own import_work check is what bounds the pair."

**Location:** `scripts/lib/dev-cycle-read.sh:1130-1132`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the budget arithmetic. It does not establish that the pair's total stays within IMPORT_WORK_LEFT before the walk's check (it does not need to).
**Legibility-target:** for-orchestrator-synthesis

Both import_targets calls inherit the same IMPORT_WORK_LEFT (`IT_WORK="${IMPORT_WORK_LEFT:-}"`, `:1121`). `import_work a w` and `import_work b w` add into a local `w=0` checked only against IMPORT_WORK_MAX (`(( (iw_t += iw_w) <= IMPORT_WORK_MAX ))`, `:1161`), and `printf ... "/$w"` (`:1142`) hands the sum to the walk. The walk's `import_work out work` (`:1265`, `:1342`) then bounds the walk total.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1121`, `:1136-1143`, `:1157-1162`, `:1265`, `:1342`

---

## Claim 12: "It returns 1 on a failed read or a real path holding a newline (the projection reads one name per line ...), so a file that changed after the walk admitted it fails the walk rather than being skipped."

**Location:** `scripts/lib/dev-cycle-read.sh:1132-1135`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the return-1 paths of import_outside. It does not establish the failure mode under a caller without pipefail.
**Legibility-target:** for-author

The two named cases hold. A trailing-newline real path returns 1 (edges.log `trailing_nl ret=1`), and a deleted file fails `realpath -e`. The list is incomplete, though. import_outside also returns 1 whenever IMPORT_WORK_LEFT is unset or empty. In that case import_targets prints no trailer and `import_work a w` (`:1140`) fails: nowork.log shows `unset_rc=1 out=[]` for a plain readable file, against `set_rc=0` with IMPORT_WORK_LEFT=100000. It also returns 1 when import_targets fails for any of its reasons (budget, import_readers refusal). "Changed after admission ... fails" has the FIFO exception, which stalls instead (the walk header names it, Claim 2). A failed `capped_read` reaches the return only under pipefail, which both walks set (`set -o pipefail`, `:1243`, `:1294`). The precise version: "It returns 1 when IMPORT_WORK_LEFT is unset (no trailer), when import_targets or a read fails, or when the real path holds a newline."

**Evidence:** `scripts/lib/dev-cycle-read.sh:1136-1143`, `:1157-1162`. nowork.sh: cwd a mktemp fixture repo, 2026-10-09T16:35:19Z, exit 0. nowork.log, edges.log

---

## Claim 13: `nul_list rl realpath -ez -- "$1" && [[ ${#rl[@]} -eq 1 && "${rl[0]}" != *$'\n'* ]] || return 1` refuses a real path holding a newline, a trailing one included (brief item A2)

**Location:** `scripts/lib/dev-cycle-read.sh:1138`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers single-argument `realpath -ez` (one NUL record) with interior and trailing newlines. It does not establish behaviour on a realpath without `-z`.
**Legibility-target:** for-orchestrator-synthesis

For a link to `x.md\n`, `realpath -ez` prints one NUL-terminated record holding the newline, and import_outside returns 1 (`trailing_nl ret=1`). The old `$(realpath -e ...)` would have dropped that trailing newline. The interior case fails both walks in the new test. Mutant m2 restores `r="$(realpath -e -- "$1")"` and fails it (`# want: walk: failed`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1138`. edges.log (`== trailing_nl`, `== realpath_records`), mutants.log `== m2_old_realpath`

---

## Claim 14: "import_file FILE DIR [DIRS...]: ... or an absolute one through import_outside (its own directory in place of DIR, and DIRS)."

**Location:** `scripts/lib/dev-cycle-read.sh:1144-1148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argument routing. It does not cover the trailer asymmetry between the two branches (Claim 24).
**Legibility-target:** for-orchestrator-synthesis

`import_file() { if [[ "$1" == /* ]]; then import_outside "$1" "${@:3}"; else capped_read < "$1" | import_targets "${@:2}"; fi; }` (`:1148`). The m3 mutant fails the test that pins this.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1148`. mutants.log

---

## Claim 15: "outside_ok PATH: ... a readable regular file (the one admission rule both walks apply)."

**Location:** `scripts/lib/dev-cycle-read.sh:1149-1152`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the // arms of both walks. It does not establish anything about repo-path admission, which uses `-f` plus inrepo_here or main_checkout.
**Legibility-target:** for-orchestrator-synthesis

`outside_ok() { [[ -f "$1" && -r "$1" ]]; }` (`:1152`) is called at `:1272` and `:1380` and nowhere else. No inline `-f ... -r` test is left in a // arm.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1152`, `:1272`, `:1380`

---

## Claim 16: The rewritten // arms keep their order and behaviour (main: seen before outside_ok; tree: outside_ok before seen)

**Location:** `scripts/lib/dev-cycle-read.sh:1272`, `scripts/lib/dev-cycle-read.sh:1380`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers equivalence with 55490d15's arms. It does not re-review the arms' design.
**Legibility-target:** for-orchestrator-synthesis

The old arms were `[[ -f "$p" && -r "$p" && "$seen" != ...]]` (tree) and `[[ -z "${seen[$p]+set}" && -f "$p" && -r "$p" ]]` (main), per the fix-range diff. The new arms are `outside_ok "$p" && [[ "$seen" != ... ]]` (`:1272`) and `[[ -z "${seen[$p]+set}" ]] && outside_ok "$p"` (`:1380`). The tests run in the same order with the same short-circuit. A rejected name is still left unmarked as seen in both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1272`, `:1380`; `git diff 55490d15..HEAD -- scripts`

---

## Claim 17: "Phase 2 begins when queue empties: tq's checkout files and outside files (absolute paths, never main's) then join it"

**Location:** `scripts/lib/dev-cycle-read.sh:1291-1292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the queue swap and where outside files are queued. It does not establish the order within tq.
**Legibility-target:** for-orchestrator-synthesis

`[[ $qi -lt ${#queue[@]} ]] || { queue=("${tq[@]}"); tq=(); qi=0; }` (`:1337`). // names go only to `tq+=("$p")` (`:1380`). `ent` is keyed by ls-tree paths, which are never absolute (`f="${BASH_REMATCH[2]}"`, `:1305`), so an outside file is never main's.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1300-1306`, `:1336-1342`, `:1380`

---

## Claim 18: "import_readers' dotnest pairs omit only such paths: keep the two equal"

**Location:** `scripts/lib/dev-cycle-read.sh:1421`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pairing condition against truthrule's dot test. It does not establish truthrule's other words.
**Legibility-target:** for-orchestrator-synthesis

A pair is built when `"/${t#"$p"}" == *"/."*` (`:1090`), meaning the relative path from root I down to root J has a dot component. The outer spelling put suppresses for such a pair is therefore that dot path plus the file. truthrule's `[[ "/$1" == */.* ]]` (`:1421`) refuses every such path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:882-898`, `:1090`, `:1421`

---

## Claim 19: "An inherited IMPORT_WHOLE is cleared when the lib is sourced, so text is still read as text (i1 architecture A1)."

**Location:** `test/scripts/build-loop-check.bats:655-656`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the line pins the A1 fix for both walks. It does not cover IMPORT_WHOLE set after sourcing.
**Legibility-target:** for-orchestrator-synthesis

`IMPORT_WHOLE=1 imps "$w" docs/x.md` reaches the sourced lib through `env ... bash -c` (`:20`). It passes at HEAD and fails under m1 (`# want: docs/x.md: imported`).

**Evidence:** `test/scripts/build-loop-check.bats:19-28`, `:655-656`. mutants.log

---

## Claim 20a: "an outside link whose real path holds a newline fails both walks"

**Location:** `test/scripts/build-loop-check.bats:660`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which walk's failure the fixture attributes to the outside link. It does not establish a fixture where the main walk's failure depends on the link.
**Legibility-target:** for-author

Both walks do fail at HEAD. The main walk, though, fails in this fixture without the link and without the fix. The newline-named untracked `docs/a\nb.md` alone fails it through checkout_md (`[[ "$f" != *$'\n'* ]] || return 1`, `scripts/lib/dev-cycle-read.sh:1323`). mainonly.log shows `main-nolink: walk: failed` on HEAD, and under m2 shows `tree: walk: ok docs/q.md: -` alongside `main: walk: failed`. Only the tree half pins A2, so the title's "fails both walks" reads as more coverage than the test gives. The precise version: "fails the tree walk (the main walk already fails on the newline-named checkout file)".

**Evidence:** `test/scripts/build-loop-check.bats:660-664`, `scripts/lib/dev-cycle-read.sh:1323`. mainonly.sh: cwd an archive copy, 2026-10-09T16:33:12Z, exit 0. mainonly.log

---

## Claim 20b: "import_file reads an outside file against its own directory and the DIRS it is given"

**Location:** `test/scripts/build-loop-check.bats:660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers DIRS "" and the file's own directory. It does not check the call's exit status (the test greps output only).
**Legibility-target:** for-orchestrator-synthesis

`IMPORT_WORK_LEFT=100000 import_file "$2" ignored ""` (`:667`), followed by grep for `docs/n.md` and `/$o/docs/n.md`. It fails under m3.

**Evidence:** `test/scripts/build-loop-check.bats:665-668`. mutants.log

---

## Claim 21: The sourcing inventory lists import_outside, import_file, outside_ok, IMPORT_DOTNEST and IMPORT_WHOLE

**Location:** `test/scripts/dev-cycle.bats:1110`, `test/scripts/dev-cycle.bats:1114`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the names are defined or declared after sourcing. `declare -p` does not check that IMPORT_WHOLE is empty (Claim 19 pins that).
**Legibility-target:** for-orchestrator-synthesis

The test passes at HEAD and fails under m1, where IMPORT_WHOLE is undeclared (mutants.log `== m1_no_clear :: sourcing ... not ok`).

**Evidence:** `test/scripts/dev-cycle.bats:1106-1117`. mutants.log

---

## Claim 22: Commit 18fba03d: "A1 ...: an exported one [could] make every walk read its files as whole names (a false negative ...)"

**Location:** commit 18fba03d message (A1)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the false negative under the m1 mutant and its removal at HEAD.
**Legibility-target:** for-orchestrator-synthesis

Under m1, the chain test reports docs/x.md as not imported. At HEAD it reports imported (mutants.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1032`. mutants.log

---

## Claim 23: Commit 18fba03d: "A2 ...: fails on one holding a newline, which the projection would split in two (the tree walk missed the file and reported ok)."

**Location:** commit 18fba03d message (A2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix behaviour reproduced by m2. It does not cover the main walk (Claim 20a).
**Legibility-target:** for-orchestrator-synthesis

m2 probe: `RESULT tree: walk: ok docs/q.md: -`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1138`. mainonly.log

---

## Claim 24: Commit 18fba03d: "A4 ...: DIRS reach import_outside, and both headers say a walk sets IMPORT_WORK_LEFT and that the walk's own check bounds the pair (G2)."

**Location:** commit 18fba03d message (A4); `scripts/lib/dev-cycle-read.sh:1144-1147`
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two headers A4 names (import_outside, import_file). It does not dispute the DIRS half, which is Verified (Claim 14).
**Legibility-target:** for-author

Only import_outside's header says this: "For a walk, which sets IMPORT_WORK_LEFT: ... the walk's own import_work check is what bounds the pair" (`:1130-1132`). import_file's header reads, in full: "import_targets over FILE as the file system holds it, for both walks: a repo path (DIR and DIRS as import_targets takes them), or an absolute one through import_outside (its own directory in place of DIR, and DIRS)." (`:1144-1147`). It names neither IMPORT_WORK_LEFT nor the budget. `rg IMPORT_WORK_LEFT` finds header mentions only at `:789`, `:1130` and `:1154`. A4's trailer-contract half therefore remains undocumented at import_file, the function U2b3b2b's outside seeds will call: its absolute branch returns 1 without IMPORT_WORK_LEFT (nowork.log `unset_rc=1`), while its repo branch succeeds with no trailer. To fix, have import_file's header say that a walk sets IMPORT_WORK_LEFT and that the absolute branch fails without it, or reword the commit claim.

**Evidence:** `scripts/lib/dev-cycle-read.sh:789`, `:1130-1132`, `:1144-1148`, `:1154`. nowork.log

---

## Claim 25: Commit 18fba03d: "The three fix mutants each fail a test."

**Location:** commit 18fba03d message (Tests)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers my reconstruction of the three mutants (drop `IMPORT_WHOLE=""`; restore `r="$(realpath -e -- "$1")"`; drop `"${@:3}"`). The author's exact mutants may differ.
**Legibility-target:** for-orchestrator-synthesis

m1 fails the chain test and the dev-cycle inventory, m2 fails the newline test, and m3 fails the newline test's DIRS half. The base copy passes all three tests.

**Evidence:** mutants.sh: cwd archive copies under the fact-check scratch dir, 2026-10-09T16:32:44Z to 16:32:52Z, exit 0. mutants.log

---

## Claim 26: Commit 18fba03d: "build-loop-check 120, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2."

**Location:** commit 18fba03d message (Tests)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers counts and passing at HEAD f7a96eed (comment-only after 18fba03d).
**Legibility-target:** for-orchestrator-synthesis

`bats --count` gives 120, 20, 79, 2 and 2. The full runs print plans 1..120, 1..20, 1..79, 1..2 and 1..2 with no `not ok` line.

**Evidence:** suites.log (cwd /workspace/.claude/wt-build-loop-u2b3b2a, 2026-10-09T16:33:26Z to 16:34:53Z)

---

## Claim 27: Commit 18fba03d: "213 code lines against main."

**Location:** commit 18fba03d message (Tests)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pr-prep step-1a count at 18fba03d. HEAD counts 216, because f7a96eed adds 3.
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat main...18fba03d -- . ':!docs/'` gives 165 added and 48 removed, 213 in all.

**Evidence:** `workflows/pr-prep.md:86-91`. Command run in /workspace/.claude/wt-build-loop-u2b3b2a, 2026-10-09; output quoted here: `165 48 213`

---

## Claim 28: Commit 18fba03d Notes: "refusing a // name under an absent home would fail every walk that meets an @~/ name, since the host home is never visible here."

**Location:** commit 18fba03d message (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers runs with a Reader homes line naming a host home. It does not apply when IMPORT_READER_HOMES is empty.
**Legibility-target:** for-orchestrator-synthesis

Each `~/` name is joined to every reader home (`:857`). The host home is below no root and absent here, so every `@~/` name yields a // name under it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:857`, `:594-633`

---

## Claim 29: Commit f7a96eed: "found the variable dropped from the header when its sentence moved."

**Location:** commit f7a96eed message; `scripts/lib/dev-cycle-read.sh:1007-1008`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header edit history.
**Legibility-target:** for-orchestrator-synthesis

18fba03d removed "IMPORT_DOTNEST the parser's dotnest pairs over IMPORT_ROOTS" from the header's list, and f7a96eed restores it as "IMPORT_DOTNEST holds the parser's dotnest pairs over IMPORT_ROOTS (its comment in the body says how)" (`:1007-1008`).

**Evidence:** `git show 18fba03d f7a96eed -- scripts/lib/dev-cycle-read.sh`; `scripts/lib/dev-cycle-read.sh:1007-1008`

---

## Claims Requiring Attention

### Incorrect
- **Claim 24** (commit 18fba03d A4; `scripts/lib/dev-cycle-read.sh:1144-1147`): "both headers say a walk sets IMPORT_WORK_LEFT". Only import_outside's header says it. import_file's header names neither IMPORT_WORK_LEFT nor that its absolute branch returns 1 without it.

### Stale
- None.

### Mostly Accurate
- **Claim 12** (`scripts/lib/dev-cycle-read.sh:1132-1135`): import_outside's return-1 list leaves out an unset IMPORT_WORK_LEFT (always 1) and import_targets failures. A FIFO swap stalls rather than fails.
- **Claim 20a** (`test/scripts/build-loop-check.bats:660`): "fails both walks" holds, but the main walk fails on the newline-named checkout file alone, so only the tree half pins A2.

### Unverifiable
- None.

## Goal-Alignment Note

**Success criterion (restated verbatim):** "your report saved at the path your own tail names, structured per your skill file, with a `Commit: f7a96eed` line at the top."

**Answered:** Yes. The report is saved at /workspace/.claude/wt-build-loop-u2b3b2a/docs/reviews/code-fact-check-report-build-loop-u2b3b2a-i2.md with `Commit: f7a96eed` first. Brief items: 1 (A1: Claims 8, 19, 22; A2: Claims 13, 20a, 23; A4: Claims 10, 14, 24), 2 (Claims 15, 16), 3 (Claims 1-7, 9, 11, 12, 17, 18), 4 (Claims 19-21, 25), 5 (renames: no `outside_targets`/`file_targets` left outside docs/reviews; IMPORT_DOTNEST newline: Claim 9; the extra fork: no claim states its cost).

**Out of scope:** Outside seeds (U2b3b2b), and whether the main walk's newline refusal is the right policy.

**Escalate:** None blocking. Claim 24 matters most for U2b3b2b: that unit will call import_file for outside seeds, and the header it reads does not state the IMPORT_WORK_LEFT requirement for the absolute branch.
