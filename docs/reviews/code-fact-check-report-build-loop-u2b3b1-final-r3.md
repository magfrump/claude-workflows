Commit: f56ba3f5
# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u2b3b1)
**Scope:** `git diff main...HEAD` on `feat/build-loop-u2b3b1` at f56ba3f5 (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md, docs/working/plan-build-loop-handoff.md line 204, three .bats files) plus the messages of 8ed86432, 1ece139d and f56ba3f5
**Checked:** 2026-10-09
**Total claims checked:** 24
**Summary:** 17 verified, 4 mostly accurate, 2 stale, 0 incorrect, 1 unverifiable
**Commit:** f56ba3f5
**Replication:** k=3 replicate r3 (final confirming pass)

Hallucination log (`docs/reviews/hallucination-patterns.md`) read; no claim matches a logged pattern. Execution logs are in the role scratch dir `/tmp/claude-1000/-workspace/f2c3719b-892d-4844-84dc-9c1b5883d0c4/scratchpad/u2b3b1-final/fc-r3/`:
- `bats.out`: `LC_ALL=C.UTF-8 TMPDIR=$(mktemp -d /tmp/fc-r3-XXXX) bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/scripts/utility-smoke.bats`, cwd the worktree, rc 0, 2026-10-09T08:05Z-08:11:50Z: 220 `ok`, 0 `not ok`.
- `probe-rules.out`: `timeout 300 bash probe-rules.sh`, cwd the scratch dir (the probe builds its repo in `mktemp -d /tmp/fc-r3-XXXX`), rc 0, 2026-10-09T08:11:13Z.
- `probe-measure.out` (08:11:20Z, overlapping the bats run's last 30 s) and `probe-measure2.out` (08:12:17Z, load average 2.1): `timeout 500 bash probe-measure.sh`, rc 0; read-only over /workspace with ROOT_REAL=/workspace, no reader list / IMPORT_READER_ROOTS=/home/magfrump/claude-workflows / plus IMPORT_READER_HOMES=/home/magfrump.
- `probe-scale.out`: `timeout 580 bash probe-scale.sh`, rc 0, 2026-10-09T08:12:31Z; one root, and 0, 1, 5, 10, 22 synthetic host aliases.

---

## Claim 1: "The two lines above name the readers ... besides this checkout, its registered worktrees and the running session's HOME ... Each is one line of absolute paths separated by single spaces (or `none`), followed by a blank line (outside a code block) or the end of the file. A second copy, a line in any other form, or a file the readers refuse (an unclosed code block, say) fails the import walks, so the floor refuses every path. Only the default branch's copy is read"

**Location:** `docs/dev-cycle.md:28-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paragraph's rules against reader_settings, SETTINGS_AWK, import_readers and floor, and that no prose line of this file is counted as a copy; does not establish U2b3b2's outside starts (out of scope by plan split).

The next-line rule matches `if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }` after `fence($0) { next }` (`scripts/lib/dev-cycle-read.sh:557-560`): probe-rules gave `readers 1-roots 0-homes set` for a key followed by a fenced block and then a blank line, and `readers malformed: line 1 is followed by a non-blank line outside a fence` when the fence was followed by prose; `Reader roots: /a /b` with no trailing newline gave `readers 2-roots 0-homes set`. A refused file: `Reader roots: /a\r\r` gave `readers malformed: line 1 of docs/dev-cycle.md holds a carriage return that does not end it, so the file is not read; both import walks fail`; the unclosed fence case is asserted by `test/scripts/build-loop-read.bats` (`settings_is readers 'readers malformed: the code fence opened at line 3 ...'`). "the floor refuses every path": every path floor does not refuse earlier reaches `elif truthwalk main "$lp"; then` (`scripts/lib/dev-cycle-read.sh:1415`), and truthwalk returns 0 when the walk fails (`main) main_imports || return 0`, `:1367`), which import_readers forces while `IMPORT_READER_WHY` is set (`[[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1`, `:1020`). Running the file's own content through the letters-only prefix rule printed only `7: Build-loop policy: review (interim; Q-103)`, `24: Reader roots: /home/magfrump/claude-workflows` and `26: Reader homes: /home/magfrump`, so the new paragraph's prose ("The two lines above ...") is not counted as a copy. The working tree and a loop branch are ignored (test at `test/scripts/build-loop-read.bats:528-532`, passing). "besides this checkout, its registered worktrees and the running session's HOME" matches `rs_r=("$ROOT_REAL" "${rs_w[@]}")` (`:1028`) and `for p in "$IMPORT_HOME" "$IMPORT_HOME_REAL"` (`:1053`).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `docs/dev-cycle.md:24-35`, `scripts/lib/dev-cycle-read.sh:551-573`, `scripts/lib/dev-cycle-read.sh:1010-1056`, `scripts/lib/dev-cycle-read.sh:1397-1419`, probe-rules.out, bats.out

---

## Claim 2: "--settings  five lines from the default branch's commit, never the working tree"

**Location:** `scripts/build-loop.sh:11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count and order of --settings; does not establish the content of lines 1-4 (unchanged on this branch).

`printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE" "$READERS_LINE"` (`scripts/build-loop.sh:741`); the test "--settings prints its five lines in order" (`test/scripts/build-loop-read.bats:198`) passed in bats.out.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/build-loop.sh:738-742`, `test/scripts/build-loop-read.bats:198-203`, bats.out

---

## Claim 3: "readers N-roots M-homes set|none|malformed: WHY ... Each is one line, single spaces, the next line outside a fence blank or the end; a PATH is absolute, not / alone, of letters, digits and . _ - / with no empty, . or .. part, listed once. none: no file or no such line. malformed (a second copy, a bad line, or a file not read) fails both walks, so the floor refuses every path; its WHY ends "; both import walks fail"."

**Location:** `scripts/build-loop.sh:43-53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every rule named against reader_settings and readerform as reached from --settings; does not establish the no-main-by-name malformed case through --settings (unreachable there: build-loop.sh exits first at `scripts/build-loop.sh:302`), which is checked under Claim 10.

`readerform` requires `[[ "$1" == /?* && "$1" =~ ^[$NAMECHARS]+$ ]]` and rejects empty, `.`, `..` parts (`scripts/lib/dev-cycle-read.sh:577-581`), with `NAMECHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-'` (`:201`). Duplicates: `if [[ -n "${rd_seen[$p]-}" ]]; then why="line ${first[$k]} lists entry $i twice"` (`:621`). Both malformed exits end the line `READERS_LINE="readers malformed: $why; both import walks fail"` (`:630`; and `:599` for no main). Probe outputs: no file → `readers none: no docs/dev-cycle.md on the default branch`; no line → `readers none: no line starts "Reader roots:" or "Reader homes:"`; `Reader roots: none` → `readers 0-roots 0-homes set` (the value `none`, not the status, as the header's `"...: none"` says); tab separator, `Reader roots /a`, `# Reader Roots: /a` → `not exactly "Reader roots: PATH ..." with single spaces`; `/a/b-c_d.e` accepted. The build-loop-read test enumerates `/`, `//a`, `/a/`, `/a//b`, `/a/../b`, `/a/./b`, `/..`, `~/x`, non-ASCII, `*`, `:` and tab (`test/scripts/build-loop-read.bats:507-512`), passing.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/build-loop.sh:43-53`, `scripts/lib/dev-cycle-read.sh:574-635`, `test/scripts/build-loop-read.bats:493-532`, probe-rules.out, bats.out

---

## Claim 4: "The reader lists both import walks take, from main's settings (the lib's caller contract item 9), before any walk; --settings prints its line. Not read_settings below: without this call the walks model no host reader."

**Location:** `scripts/build-loop.sh:304-307`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call's placement (top level, in the script's shell, after `main_by_name` and before any mode runs) and the no-call consequence; does not establish U2c's future floor caller.

The call sits at top level after `main_by_name || { ... exit 1; }` (`scripts/build-loop.sh:302-307`); no walk function is called in build-loop.sh (grep for `main_imports|imported_names|truthwalk|floor |isimported` finds only comments: paraphrased — no quote available because the claim covers absence of code). Without the call the lists stay as sourcing left them (`IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""` at `scripts/lib/dev-cycle-read.sh:1001`, `IMPORT_READER_WHY=""` at `:591`), and the first test's `imps` runs without `T_SETTINGS` give `walk ok` and `docs/h.md -` (`test/scripts/build-loop-check.bats:1857-1859`), i.e. no host reader.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/build-loop.sh:296-307`, `scripts/lib/dev-cycle-read.sh:591`, `scripts/lib/dev-cycle-read.sh:1001`, `test/scripts/build-loop-check.bats:1854-1859`, bats.out

---

## Claim 5: "The walk also models the host readers the default branch's docs/dev-cycle.md names ("Reader roots:", "Reader homes:"; see build-loop.sh --settings), and fails when those lines are malformed or no default branch is found by name."

**Location:** `scripts/dev-cycle.sh:56-60`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-fix's tree walk under reader_settings; does not establish the other dev-cycle.sh modes (they run no walk).

Both stated triggers hold (dev-cycle.bats:1407 test, passing: malformed `Reader roots: host/cw` and `git branch -m main trunk` each give `skip ...: the reader settings of docs/dev-cycle.md cannot be used (...`). The walk also fails when the file itself is refused (a second copy, or a carriage return / unclosed fence that main_file refuses: `why="$FILE_WHY"` at `scripts/lib/dev-cycle-read.sh:603`), which "those lines are malformed" covers only under the --settings vocabulary the header points to (where all three print `readers malformed`). Precise version: "... and fails when the readers line of build-loop.sh --settings would read malformed (a bad or second line, or a file not read) or no default branch is found by name."

**Legibility-target:** for-author
**Evidence:** `scripts/dev-cycle.sh:56-60`, `scripts/lib/dev-cycle-read.sh:597-605`, `test/scripts/dev-cycle.bats:1407-1424`, probe-rules.out, bats.out

---

## Claim 6: "skip $a: the reader settings of docs/dev-cycle.md cannot be used ($IMPORT_READER_WHY), so the instruction-file import walk failed; file it instead"

**Location:** `scripts/dev-cycle.sh:186`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the causal wording (a set WHY always fails the walk, so the walk failure is that cause); does not establish wording for other walk failures (unchanged branch at `:187`).

The branch fires on `[[ "$TRUTH_WHY" == walk && -n "$IMPORT_READER_WHY" ]]` (`scripts/dev-cycle.sh:186`); with WHY set, imported_names fails at `import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:1181`) because import_readers refuses (`:1020`), so whenever the message prints, the settings caused the failure. Asserted for both a malformed line and no main by name (`test/scripts/dev-cycle.bats:1417-1424`), passing.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/dev-cycle.sh:176-190`, `scripts/lib/dev-cycle-read.sh:1177-1182`, `test/scripts/dev-cycle.bats:1407-1424`, bats.out

---

## Claim 7: "The reader lists the import walk takes, from main's settings (the lib's caller contract item 9); without main found by name the walk fails closed."

**Location:** `scripts/dev-cycle.sh:192-194`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-main-by-name path including the current-branch fallback of resolve_main; does not establish the origin/HEAD-redirect case (settled override row, Q-103 residual).

`if ! main_by_name; then IMPORT_READER_WHY="no default branch was found by name, ..."` (`scripts/lib/dev-cycle-read.sh:597-599`); `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`:310`) is false for resolve_main's current-branch fallback, which leaves `MAIN_BY_NAME` empty (`:521-526`). probe-rules "no main by name" printed `WHY[no default branch was found by name, ...]`; dev-cycle.bats:1421-1424 passes (run at `:1422`).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/dev-cycle.sh:192-194`, `scripts/lib/dev-cycle-read.sh:310`, `scripts/lib/dev-cycle-read.sh:508-529`, `scripts/lib/dev-cycle-read.sh:593-600`, probe-rules.out

---

## Claim 8: "Both walks also read the repository's worktree registry (import_readers), and reader_settings reads docs/dev-cycle.md from the default branch's commit."

**Location:** `scripts/lib/dev-cycle-read.sh:42-43`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the read source of reader_settings; does not establish which callers call it (Claim 9).

`main_file "$f" "$SETTINGS_AWK"` with `f=docs/dev-cycle.md` (`scripts/lib/dev-cycle-read.sh:594,601`), and main_file reads `git cat-file blob "$MAIN_SHA:$f"` (`:544`).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:531-550`, `scripts/lib/dev-cycle-read.sh:593-605`

---

## Claim 9: "Call reader_settings after sourcing the lib (which clears the reader lists) and resolve_main, before a decision's first walk: it sets IMPORT_READER_ROOTS and IMPORT_READER_HOMES from main's docs/dev-cycle.md (host spellings of the main worktree and host HOMEs), or IMPORT_READER_WHY, which fails both walks; both scripts call it."

**Location:** `scripts/lib/dev-cycle-read.sh:86-91`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the clearing on source, the setters, both walks failing on WHY and the two script call sites; does not establish a fail-closed sentinel for a caller that skips the call (none exists; settled override row).

Sourcing clears `IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""` (`:1001`) and `READERS_LINE=""; IMPORT_READER_WHY=""` (`:591`). Both walks call import_readers first (`:1181` imported_names, `:1231` main_imports), which refuses on WHY (`:1020`); `T_SETTINGS=1 imps` with a malformed line gives `walk failed` for both tree and main (`test/scripts/build-loop-check.bats:1872-1877`). Call sites: `scripts/build-loop.sh:307` and `scripts/dev-cycle.sh:194` (paraphrased — no quote available because the claim covers absence of further callers: grep for `reader_settings` in scripts/ finds only these two calls and the lib definition).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:86-91`, `scripts/lib/dev-cycle-read.sh:591`, `scripts/lib/dev-cycle-read.sh:1001`, `scripts/lib/dev-cycle-read.sh:1020`, `scripts/build-loop.sh:307`, `scripts/dev-cycle.sh:194`, bats.out

---

## Claim 10: "reader_settings: ... "Reader roots: PATH ..." (host spellings of the main worktree, the first git worktree list entry) and "Reader homes: PATH ..." (host homes), or "none"; each one line as "Self-merge never:" is, each PATH in readerform, listed once. Sets IMPORT_READER_ROOTS, IMPORT_READER_HOMES and READERS_LINE; no file or line adds no reader. A file main_file refuses, a second copy, a bad line or no main found by name (i1 security F1) sets IMPORT_READER_WHY, which fails both walks. Call it in the caller's shell once main is resolved; a caller that never calls it models no host reader (override row)."

**Location:** `scripts/lib/dev-cycle-read.sh:582-590`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed outcome and the "as Self-merge never:" parity (exact key, single-space regex, next-line rule, form check, listed once, compared with read_settings at `scripts/build-loop.sh:351-389`); does not establish that the override row's sentinel concern is resolved (it is deferred by that row).

Parity: read_settings uses `[[ "$t" != "Self-merge never: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]` and `next[never] != 1` (`scripts/build-loop.sh:374-377`), reader_settings `[[ "$t" != "$key "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]` and `"${next[$k]}" != 1` (`scripts/lib/dev-cycle-read.sh:614-615`). Outcomes in probe-rules.out: absent file and no line → empty lists, empty WHY; second copy, bad line, refused file and no main by name → WHY set and lists emptied (`IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""; IMPORT_READER_WHY="$why"`, `:629`). A partial success is not kept: `Reader roots: /a` then `Reader homes: rel` printed `R[] H[]` with WHY set. The override row exists (`docs/reviews/override-log.md`, row "A caller that walks without calling reader_settings gets empty reader lists ...").

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:582-635`, `scripts/build-loop.sh:351-389`, `docs/reviews/override-log.md` (2026-10-09 rows), probe-rules.out

---

## Claim 11: "/workspace's walks spend about 350,000 each over its 25 reader roots and 870,000 over 49 (one host alias), 8,200 with one (2026-10-09)."

**Location:** `scripts/lib/dev-cycle-read.sh:740`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the work totals of both walks over /workspace as registered at 08:12Z (25 worktrees); does not establish the figures at the time the comment was written (the registry's paths may have changed since).

Measured with `import_work` wrapped to record the walk's running total: 25 roots → `main_work=347710`, `tree_work=347710`; 49 roots (IMPORT_READER_ROOTS=/home/magfrump/claude-workflows) → `main_work=899730`, `tree_work=899730`; one root → `work=8240`. 350,000 and 8,200 hold; 870,000 is 3.4% under the measured 899,730 (about 900,000).

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:733-751`, probe-measure2.out, probe-scale.out

---

## Claim 12a: "the honest walks spend this bound near 570 roots ... Roots are about (1 + C) times the worktrees for C host aliases (G8): with one, near 285 worktrees"

**Location:** `scripts/lib/dev-cycle-read.sh:741-746`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the root multiplication and the bound's root count over /workspace's 128 names with alias paths of the real alias's length; does not establish the bound for other name sets or much longer alias paths.

Synthetic aliases (`/home/magfrump/claude-workflowNN`): C=1 → 49 roots, 902,850; C=5 → 145, 4,621,010; C=10 → 265, 12,638,310; C=22 → 553 roots, 47,155,350 (94% of `IMPORT_WORK_MAX=50000000`). 553 = 23 x 24 + 1, so roots ≈ (1 + C) x worktrees (all 24 linked worktrees lie beneath /workspace, the first record), and the bound falls just above 553 roots, consistent with "near 570"; half of that is the "near 285 worktrees" with one alias. Confidence medium: the per-alias cost depends on alias length.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:741-746`, `scripts/lib/dev-cycle-read.sh:1028-1032`, probe-scale.out

---

## Claim 12b: "(49 roots here: 1.5 s per walk; U2b3b1 i1 performance F1)"

**Location:** `scripts/lib/dev-cycle-read.sh:746`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers wall time of each walk at 49 roots on this host at load average about 2; does not establish an idle-host figure.

Measured at 49 roots: main walk 1.39-1.67 s (1.48-1.59 s including import_readers), tree walk 1.71-1.72 s across three runs (probe-measure.out, probe-measure2.out). 1.5 s fits the main walk; the tree walk ran about 1.7 s. At 25 roots: main 1.38 s, tree 1.49 s. Precise version: "about 1.5 s for the main walk, 1.7 s for the tree walk".

**Legibility-target:** for-author
**Evidence:** probe-measure.out, probe-measure2.out

---

## Claim 13: "import_readers' IMPORT_ROOTS and IMPORT_HOMES when its memo key is current (else ROOT_REAL alone and import_home's home: a call outside a walk; either fails on refused settings)"

**Location:** `scripts/lib/dev-cycle-read.sh:765-766`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both branches with IMPORT_READER_WHY set and the fallback without it; does not establish H5's outside-seed caller (U2b3b2).

`[[ -z "$IMPORT_READER_WHY" ]] || return 1  # refused settings fail every reader` (`scripts/lib/dev-cycle-read.sh:1065`) sits after the memo selection, so both branches refuse. probe-rules: memo current with WHY → `targets(memo, WHY) rc=1`; no memo with WHY → `targets(no memo, WHY) rc=1`; no memo, no WHY → names printed, `rc=0` (the ROOT_REAL-alone fallback). A memo current with a non-settings refusal (`IMPORT_READER_ROOTS=rel`) also gives rc=1 (empty roots make awk `exit 2`, `:934`), consistent with "IMPORT_ROOTS ... when its memo key is current".

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:760-766`, `scripts/lib/dev-cycle-read.sh:1059-1092`, probe-rules.out

---

## Claim 14: "it is kept only when it lies below a reader root (import_readers: ROOT_REAL, every registered worktree, the caller's IMPORT_READER_ROOTS)"

**Location:** `scripts/lib/dev-cycle-read.sh:794-796`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reader-root list this sentence enumerates; does not establish anything else in the import_targets superset comment. (The lines predate the branch, `git blame` 4dba56dc/3d2d8c44, but this branch's G8 change makes the list incomplete.)

import_readers now also adds, beneath each caller root, every worktree registered beneath the main worktree: `rs_r+=("$rs_cr"); for p in "${rs_w[@]}"; do [[ -z "$rs_m" || "$p" != "$rs_m"/* ]] || rs_r+=("$rs_cr${p#"$rs_m"}"); done` (`scripts/lib/dev-cycle-read.sh:1031`). probe-rules printed `/host/cw/.wt/a` among IMPORT_ROOTS with IMPORT_READER_ROOTS=/host/cw. Precise version: "... the caller's IMPORT_READER_ROOTS and the worktrees beneath the main worktree re-spelled under each".

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:794-796`, `scripts/lib/dev-cycle-read.sh:1028-1032`, probe-rules.out

---

## Claim 15: "IMPORT_ROOTS holds ROOT_REAL, every path git worktree list registers ..., each IMPORT_READER_ROOTS entry and, beneath each such entry, every registered worktree that lies beneath the main worktree (the first record), re-spelled there ... It returns 1 when IMPORT_READER_WHY is set ..., import_home or the listing fails, or a root ... The result, a refusal included (but not an import_home failure, which returns first), is memoized in IMPORT_READERS_DONE, keyed on ROOT_REAL, HOME, the caller's two lists and IMPORT_READER_WHY"

**Location:** `scripts/lib/dev-cycle-read.sh:976-998`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers G8 re-spelling (inside vs outside the main worktree, from the main and a linked worktree), the first porcelain record being the main worktree, the WHY refusal, the import_home exemption from the memo and the key parts; does not establish git's ordering guarantee beyond the git version in this sandbox.

probe-rules: porcelain listed `worktree /tmp/fc-r3-FxEH/repo` first even when run from `.wt/a`; IMPORT_ROOTS gained `/host/cw` and `/host/cw/.wt/a` but no re-spelling of `../outside`. With `import_home() { return 1; }`, import_readers gave `rc=1 done=[]` (not memoized: `import_home || return 1` precedes the memo at `:1012`). Key: `local a="${ROOT_REAL:-}" b="$IMPORT_HOME_DONE" c="$IMPORT_READER_ROOTS" d="$IMPORT_READER_HOMES" e="$IMPORT_READER_WHY"` (`:1007`), where IMPORT_HOME_DONE is import_home's key over HOME (`key="x${HOME+set}:${HOME-}"`, printed by probe-rules from `declare -f import_home`). WHY set → `readers rc=1 roots=[]`.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:976-1056`, probe-rules.out

---

## Claim 16: "A refusal is memoized too, as an empty IMPORT_ROOTS (a result never is: ROOT_REAL leads it), so a refusing decision lists the registry once"

**Location:** `scripts/lib/dev-cycle-read.sh:1014-1016`
**Type:** Performance / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the memo-hit return and the single listing per decision for a refusal after the listing; does not establish a refusal before the listing (WHY or empty ROOT_REAL lists zero times, which is within "once").

`if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi` (`:1016`); a result always holds ROOT_REAL, checked absolute and not `/` (`[[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1`, `:1038`). Test "a refused reader set is memoized, so a decision lists the worktree registry once" (`test/scripts/build-loop-check.bats:1898`) counts one `worktree` call for three walk calls, passing.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:1010-1056`, `test/scripts/build-loop-check.bats:1898-1909`, bats.out

---

## Claim 17: "the reader settings of docs/dev-cycle.md cannot be used ($IMPORT_READER_WHY), so the instruction files could not be walked for @ imports"

**Location:** `scripts/lib/dev-cycle-read.sh:1416`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the floor's new message branch; does not establish U2c's printing of FLOOR_WHY.

As in Claim 6, main_imports refuses through import_readers whenever WHY is set (`import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; return 1; }`, `:1231`). The test wants the exact text with `(more than one line starts "Reader roots:" (lines 1 and 3))` (`test/scripts/build-loop-check.bats:1879-1880`), passing.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:1397-1419`, `test/scripts/build-loop-check.bats:1878-1880`, bats.out

---

## Claim 18: "(U2b3b1) `readers N-roots M-homes set|none|malformed: WHY` (the `Reader roots:` and `Reader homes:` lines of `docs/dev-cycle.md`)"

**Location:** `docs/working/plan-build-loop-handoff.md:204`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three printed forms; does not establish the other four lines' grammar.

The code prints `"readers $nr-roots $nh-homes set: $f on the default branch"`, `readers none: ...` and `"readers malformed: $why; both import walks fail"` (`scripts/lib/dev-cycle-read.sh:599,602,630,633-634`); probe-rules shows each form.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `docs/working/plan-build-loop-handoff.md:204`, `scripts/lib/dev-cycle-read.sh:593-635`, probe-rules.out

---

## Claim 19: "build-loop.sh and dev-cycle.sh both call it once main is found by name (H4; without main by name there is no settings source, so the lists stay empty)"

**Location:** `docs/working/plan-build-loop-handoff.md:301`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-main-by-name clause of the plan's U2b3b1 sub-bullet (on main from f8d003c7, not edited by the branch); does not establish the rest of that bullet.

Since 1ece139d, no main by name sets `IMPORT_READER_WHY="no default branch was found by name, ..."` (`scripts/lib/dev-cycle-read.sh:598`), failing both walks, and dev-cycle.sh calls reader_settings whether or not main is found by name (`scripts/dev-cycle.sh:191-194`). The lists are empty but the walks fail closed rather than model no host reader. (8ed86432's commit note said the same and was accurate at 8ed86432, where the branch was `READERS_LINE="readers none: no default branch found by name"; return 0`.)

**Legibility-target:** for-author
**Evidence:** `docs/working/plan-build-loop-handoff.md:301`, `scripts/lib/dev-cycle-read.sh:597-600`, `scripts/dev-cycle.sh:191-194`, probe-rules.out

---

## Claim 20: 8ed86432's message: "A second copy, a malformed line or a file FENCE_AWK refuses sets IMPORT_READER_WHY, which import_readers refuses ... Over /workspace both walks still give 128 names, at 49 roots (was 25): the main walk takes 1.5 s (was 1.3 s). Suites 220/220 ... 375 code lines against main (the move counted twice)."

**Location:** commit 8ed86432 (message body)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures and the refusal mechanism; does not establish 8ed86432's no-main behaviour as current (superseded, Claim 19).

`git diff --numstat main...8ed86432 -- ':(top)' ':(top,exclude)docs/'` sums 295 added + 80 deleted = 375. Test count at 8ed86432 over build-loop-check, build-loop-read, dev-cycle, fixture-git-env and utility-smoke: 220 (main: 215). Measured now: 128 names in both walks at 25 and 49 roots; main walk 1.38 s at 25 and 1.47-1.67 s at 49 (probe-measure2.out).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `git show 8ed86432`, probe-measure2.out, bats.out

---

## Claim 21: 1ece139d's message: "with no default branch found by name, reader_settings now sets IMPORT_READER_WHY, so --check-fix fails closed ... import_targets refuses while IMPORT_READER_WHY is set, memo or not ... the floor and --check-fix name the reader settings when they fail a walk ... the H4 test now checks two paths ... (397 lines) ... Suites 220/220."

**Location:** commit 1ece139d (message body)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed fixes and figures; does not establish the Notes line's "~30 test call sites" for a reverted sentinel (Claim 22).

numstat `main...1ece139d` sums 312 + 85 = 397; 220 tests at 1ece139d, and 220/220 at f56ba3f5 (bats.out). Fixes: Claims 7, 13, 6/17; the H4 test passes `docs/notes.md docs/h.md` in its first three steps (`test/scripts/dev-cycle.bats:1410,1413,1417`).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `git show 1ece139d`, `test/scripts/dev-cycle.bats:1407-1424`, bats.out

---

## Claim 22: "the fail-closed sentinel for a missing reader_settings call (arch F2) was built and reverted: it needs ~30 test call sites, past the cap."

**Location:** commit 1ece139d (Notes)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about the reverted work; does not establish the call-site count.

The reverted code is in no commit on the branch (paraphrased — no quote available because the claim covers absence of code: `git log main..HEAD` holds only 8ed86432, 1ece139d and f56ba3f5, none with a sentinel). Verifying needs the reverted diff or a definition of which test call sites count.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `git log main..HEAD`

---

## Claim 23: "--check-fix models the host readers main's docs/dev-cycle.md names, and refuses every path on a malformed line or with no main by name"

**Location:** `test/scripts/dev-cycle.bats:1407`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts against its name; does not establish behaviour beyond the paths passed.

The malformed step asserts both of two paths (run at `:1417`, checked at `:1418-1419`), but the no-main step passes one path, `run --separate-stderr bash "$DC" --check-fix docs/notes.md` (`:1422`), so "every path" is asserted with one path there. The behaviour holds by construction (each path re-asks the failed walk), but the test does not exercise "every" for that case.

**Legibility-target:** for-author
**Evidence:** `test/scripts/dev-cycle.bats:1407-1424`, bats.out

---

## Claim 24: Test names and comments in build-loop-check.bats and build-loop-read.bats ("T_SETTINGS=1 sets them as the scripts do, with reader_settings"; "both walks take the reader lists from main's docs/dev-cycle.md, never the working tree, and a malformed line fails them"; "a caller root re-spells the worktrees registered beneath the main worktree"; "a refused reader set is memoized ..."; "--settings: ... any other form is malformed and never echoed"; "The host alias and HOME (Q-121, Q-123), and no prose line read as a copy.")

**Location:** `test/scripts/build-loop-check.bats:17-18`, `test/scripts/build-loop-check.bats:1854`, `test/scripts/build-loop-check.bats:1885`, `test/scripts/build-loop-check.bats:1898`, `test/scripts/build-loop-read.bats:77`, `test/scripts/build-loop-read.bats:493`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its body and its passing run; does not establish coverage beyond those bodies.

`[[ -z "${T_SETTINGS:-}" ]] || reader_settings` after `resolve_main || true` (`test/scripts/build-loop-check.bats:24,34`) mirrors the scripts' order. The working-tree copy naming `/wt` leaves `docs/w.md -` (`:1862-1867`); the re-spell test reaches `docs/n.md imported` only with `T_READER_ROOTS=/host/cw` from a sibling worktree `../gate` (`:1885-1896`); the never-echoed loop checks `"$output" != *caf* && ... != *rel*` (`test/scripts/build-loop-read.bats:511`); the repo-file assertion `readers 1-roots 1-homes set` (`:78`) agrees with Claim 1's prefix-rule run. All pass in bats.out.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `test/scripts/build-loop-check.bats:14-36`, `test/scripts/build-loop-check.bats:1854-1909`, `test/scripts/build-loop-read.bats:74-79`, `test/scripts/build-loop-read.bats:493-532`, bats.out

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- **Claim 14** (`scripts/lib/dev-cycle-read.sh:794-796`): the reader-root list in import_targets' superset comment omits G8's re-spelled worktrees beneath each caller root (import_readers `:1031`).
- **Claim 19** (`docs/working/plan-build-loop-handoff.md:301`): "without main by name ... the lists stay empty" predates 1ece139d; no main by name now sets IMPORT_READER_WHY and fails both walks (not in the branch diff; the plan bullet is the unit's spec).

### Mostly Accurate
- **Claim 5** (`scripts/dev-cycle.sh:59-60`): "those lines are malformed" omits a refused file (CR, unclosed fence), which also fails the walk.
- **Claim 11** (`scripts/lib/dev-cycle-read.sh:740`): 870,000 at 49 roots measures 899,730 now (about 900,000).
- **Claim 12b** (`scripts/lib/dev-cycle-read.sh:746`): 1.5 s fits the main walk; the tree walk measured about 1.7 s.
- **Claim 23** (`test/scripts/dev-cycle.bats:1407,1422`): "every path ... with no main by name" is asserted with one path.

### Unverifiable
- **Claim 22** (commit 1ece139d Notes): the "~30 test call sites" for the reverted sentinel needs the reverted diff.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report at the output path your role names, structured per your skill, every finding with a verbatim Evidence quote and path:line.
- Answered: yes
- Out of scope: H5, H2, C1, G9 and outside starts (U2b3b2's by the plan split); settled override rows (duplicated parser, missing-call sentinel, origin/HEAD redirect, alias cap, Won't-Fix nits); f56ba3f5's review files (records, not code claims).
- Escalate: Claim 19 (the plan's U2b3b1 bullet still says no main by name leaves the lists empty; the code now fails closed); Claim 14 is a one-phrase comment fix if lines allow.
- Decisions I made: counted "220" over the five suites prior commits list; measured work by wrapping import_work in the probe (no lib edit); included two out-of-hunk lines (Claims 14, 19) because this branch's behaviour change made them stale.
