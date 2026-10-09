Commit: 8ed86432
# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u2b3b1)
**Scope:** `git diff main...HEAD` on `feat/build-loop-u2b3b1` (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md, three .bats files) plus commit 8ed86432's message
**Checked:** 2026-10-09
**Total claims checked:** 17
**Summary:** 13 verified, 3 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable
**Commit:** 8ed86432
**Replication:** k=1 (loop pass, decision 031)

Hallucination log (`docs/reviews/hallucination-patterns.md`) read; no claim matches a logged pattern. Execution logs live in the role scratch dir `/tmp/claude-1000/-workspace/f2c3719b-892d-4844-84dc-9c1b5883d0c4/scratchpad/u2b3b1-i1/factcheck/` (probe1-4 scripts and `.out` files, `bats.out`, `bats2.out`, `probe2-timing.out`); each probe ran from its own `mktemp -d /tmp/factcheck-XXXX` repo except probe2, which reads /workspace only.

---

## Claim 1: "Reader roots: ... Each is one line of absolute paths separated by single spaces (or `none`), followed by a blank line. A second copy, or a line in any other form, fails the import walks, so the floor refuses every path. Only the default branch's copy is read"

**Location:** `docs/dev-cycle.md:28-34`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the doc paragraph against reader_settings and SETTINGS_AWK; does not establish anything about U2b3b2's outside starts.

The code accepts "the next line outside a fence blank or the end" (`if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }` at `scripts/lib/dev-cycle-read.sh:563`, with `nx[k] = 1` set on the first copy), so a key line at end of file, or one followed by a fenced block and then a blank line, is valid; probe1 "at EOF no newline" gave `readers 1-roots 0-homes set` and "next line in fence then blank" gave `readers 1-roots 0-homes set`. "followed by a blank line" omits the end-of-file and fence cases; it also omits the third failure source, a file FENCE_AWK refuses (probe1 "CR CR" → `readers malformed: line 1 of docs/dev-cycle.md holds a carriage return that does not end it ...`). The rest holds: the working tree and a loop branch are ignored (test `build-loop-read.bats:528-532`, passing). No prose line in the paragraph is counted as a copy: an awk pass over the file with the letters-only prefix rule printed only lines 7, 24 and 26 (`7: Build-loop policy: review (interim; Q-103)`, `24: Reader roots: /home/magfrump/claude-workflows`, `26: Reader homes: /home/magfrump`).

Precise version: "... followed by a blank line or the end of the file (outside a fence). A second copy, a line in any other form, or a file the fence reader refuses fails the import walks ...".

**Legibility-target:** for-author
**Evidence:** `docs/dev-cycle.md:24-34`, `scripts/lib/dev-cycle-read.sh:557-574`, probe1.out (command `timeout 120 bash probe1.sh`, cwd scratch dir, exit 0, 2026-10-09T07:49:06Z)

---

## Claim 2: "--settings  five lines from the default branch's commit, never the working tree"

**Location:** `scripts/build-loop.sh:11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count and the main-commit source of the readers line; does not establish the content of lines 1-4 (unchanged).

`printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE" "$READERS_LINE"` (`scripts/build-loop.sh:739`); reader_settings reads through `main_file "$f" "$SETTINGS_AWK"` (`scripts/lib/dev-cycle-read.sh:607`), which reads `git cat-file blob "$MAIN_SHA:$f"`. Tests `--settings prints its five lines in order` and the branch/working-tree block of the U2b3b1 --settings test pass (bats run below).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/build-loop.sh:739`, `scripts/lib/dev-cycle-read.sh:536-549,607`, bats.out

---

## Claim 3: build-loop.sh's readers-line rules ("one line, single spaces, the next line outside a fence blank or the end; a PATH is absolute, not / alone, of letters, digits and . _ - / with no empty, . or .. part, listed once. none: no file or no such line. malformed (a second copy, a bad line, or a file not read) fails both walks")

**Location:** `scripts/build-loop.sh:43-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed rule against reader_settings and readerform with probes; "listed once" is per key (the same path in roots and homes is accepted, probe1); does not establish how the walks use the paths (Claims 9-11).

```bash
# scripts/lib/dev-cycle-read.sh:580-583
readerform() {
  local rest="${1#/}/" c
  [[ "$1" == /?* && "$1" =~ ^[$NAMECHARS]+$ ]] || return 1
  while [[ -n "$rest" ]]; do c="${rest%%/*}"; rest="${rest#*/}"; [[ -n "$c" && "$c" != . && "$c" != .. ]] || return 1; done
}
```

`NAMECHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-'` (`:202`). Probe1: tab separator → malformed entry 1; `Reader homes: /h /h` → `lists entry 2 twice`; `Reader roots: none` + `Reader homes: none` → `0-roots 0-homes set`; absent file → `readers none: no docs/dev-cycle.md on the default branch`; no key line → `readers none: no line starts ...`; unbalanced fence → `readers malformed: the code fence ... never closed`; a fenced second copy is ignored. The test at `build-loop-read.bats:493` covers `/`, `//a`, `/a/`, `/a//b`, `/..`, `/a/./b`, `~/x`, UTF-8, `*`, `:` and passes. The "malformed fails both walks" consequence is Claims 9 and 15.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:577-640`, probe1.out, bats.out

---

## Claim 4: "The walk also models the host readers the default branch's docs/dev-cycle.md names ... and fails when those lines are malformed."

**Location:** `scripts/dev-cycle.sh:56-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-fix's tree walk taking reader_settings' lists and failing on a malformed line; does not establish that "malformed" is read to include an unread file (it does: Claim 3), which the header leaves to build-loop.sh --settings.

`reader_settings` runs at `scripts/dev-cycle.sh:193` before the check modes; test `dev-cycle.bats:1407` (passing) shows `ok` without the lines, `skip ...: an instruction file names it` with `Reader roots: /host/cw` / `Reader homes: /host`, and `skip docs/notes.md: the instruction-file import walk failed` with `Reader roots: host/cw`.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/dev-cycle.sh:56-59,189-193`, `test/scripts/dev-cycle.bats:1407-1419`, bats.out

---

## Claim 5: "The reader lists the import walk takes, from main's settings (the lib's caller contract item 9); without main found by name they stay empty."

**Location:** `scripts/dev-cycle.sh:190-191`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-main-by-name path (lists and IMPORT_READER_WHY empty, so the walk runs with no host readers rather than failing); does not establish whether that is the desired policy.

`if ! main_by_name; then READERS_LINE="readers none: no default branch found by name"; return 0; fi` (`scripts/lib/dev-cycle-read.sh:606`), after the lists are cleared at `:605`. Probe1 "no main by name" (repo on branch `feat`, resolve_main succeeded on the current branch, file holding the malformed `Reader roots: rel`) printed `readers none: no default branch found by name [] R=[]`.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:603-640`, probe1.out

---

## Claim 6: "Both walks also read the repository's worktree registry (import_readers), and reader_settings reads docs/dev-cycle.md from the default branch's commit."

**Location:** `scripts/lib/dev-cycle-read.sh:42-43`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers reader_settings' file source; does not establish anything further.

`local f=docs/dev-cycle.md ...` and `if ! main_file "$f" "$SETTINGS_AWK"; then` (`:603,607`); main_file reads `git cat-file blob "$MAIN_SHA:$f"` (`:543`).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:536-549,601-640`

---

## Claim 7: Contract item 9: "Call reader_settings after sourcing the lib (which clears the reader lists) and resolve_main, and before a decision's first walk: it sets IMPORT_READER_ROOTS and IMPORT_READER_HOMES from the default branch's docs/dev-cycle.md, never from the environment ..., or IMPORT_READER_WHY, which fails both walks. build-loop.sh and dev-cycle.sh both call it."

**Location:** `scripts/lib/dev-cycle-read.sh:86-92`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sourcing clearing the lists and IMPORT_READER_WHY, both callers' placement, and the refusal; does not establish that no future caller walks before calling it.

Sourcing sets `READERS_LINE=""; IMPORT_READER_WHY=""` (`:600`) and `IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""` (`:1007`); probe1 "env not honoured" (`IMPORT_READER_ROOTS=/env IMPORT_READER_WHY=envwhy` in the environment) printed `R=[] W=[]`. build-loop.sh calls it at `:305`, after `resolve_main` and `main_by_name` and before any walk (state_gate and default_gate at `:298,:302` run no walk; `check_line`'s `import_reset` at `:673` follows). dev-cycle.sh calls it at `:193`. Refusal: `[[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1` (`:1025`).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:86-92,600,1007,1025`, `scripts/build-loop.sh:296-305`, `scripts/dev-cycle.sh:189-193`, probe1.out

---

## Claim 8: reader_settings' comment ("Each key is one line, as 'Self-merge never:' is: exact, single spaces, the next line outside a fence blank or the end, each PATH in readerform and listed once ... No file and no line add no reader. A file main_file does not read, a second copy of a key or a malformed line sets IMPORT_READER_WHY instead ... Without main found by name there is no settings source, so the lists stay empty.")

**Location:** `scripts/lib/dev-cycle-read.sh:585-599`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every stated rule (probe1 cases plus the passing --settings test); copy detection is the documented best-effort letters-only prefix, so a prose line whose letters start "readerroots" (e.g. "Reader rootstock ...") is counted as a malformed copy (probe1) — consistent with the documented rule, not a mismatch.

```bash
# scripts/lib/dev-cycle-read.sh:616-619
      key="Reader $k:"; t="${text[$k]}"; v="${t#"$key" }"
      if [[ "${cnt[$k]}" -gt 1 ]]; then why="more than one line starts \"$key\" (lines ${first[$k]} and ${second[$k]})"
      elif [[ "$t" != "$key "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then why="line ${first[$k]} is not exactly \"$key PATH ...\" with single spaces"
      elif [[ "${next[$k]}" != 1 ]]; then why="line ${first[$k]} is followed by a non-blank line outside a fence (it may continue the list)"
```
(excerpt ends :619; enclosing reader_settings() continues to :640 — read). On any `why`, `:634-636` clears both lists, sets `IMPORT_READER_WHY="$why"` and the malformed READERS_LINE. Probe1 results as in Claims 1, 3 and 5.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:585-640`, probe1.out, bats.out

---

## Claim 9: "IMPORT_ROOTS holds ROOT_REAL, every path git worktree list registers ..., each IMPORT_READER_ROOTS entry and, beneath each such entry, every registered worktree that lies beneath the main worktree (the first record), re-spelled there"

**Location:** `scripts/lib/dev-cycle-read.sh:979-984` (and `:1028-1030`, "The first record is the main worktree")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers re-spelling (prunable entries included) and that porcelain's first record is the main worktree, also when run from a linked worktree outside it; in a bare repository the first record is the bare git directory (`worktree .../b.git` + `bare`), so "main worktree" there means the bare dir and worktrees nested in it are re-spelled — a case the walks never meet (they need a checkout). Does not establish Claude Code's own path handling on the host.

```bash
# scripts/lib/dev-cycle-read.sh:1027,1031-1037
  for p in "${rs_l[@]}"; do [[ "$p" != "worktree "* ]] || rs_w+=("${p#worktree }"); done
  [[ ${#rs_w[@]} -eq 0 ]] || rs_m="${rs_w[0]}"
  [[ -z "$IMPORT_READER_ROOTS" ]] || mapfile -t rs_c <<<"$IMPORT_READER_ROOTS"
  rs_r=("$ROOT_REAL" "${rs_w[@]}")
  for rs_cr in "${rs_c[@]}"; do
    [[ -n "$rs_cr" ]] || continue
    rs_r+=("$rs_cr"); for p in "${rs_w[@]}"; do [[ -z "$rs_m" || "$p" != "$rs_m"/* ]] || rs_r+=("$rs_cr${p#"$rs_m"}"); done
  done
```
(excerpt ends :1037; enclosing import_readers() continues to :1063 — read). Probe3, run from `../outside` with `IMPORT_READER_ROOTS=/host/cw`: porcelain first record `worktree .../r` (also from the linked worktree), IMPORT_ROOTS `.../outside`, `.../r`, `.../r/.claude/wt-a`, `.../r/.claude/wt-gone` (prunable), `/host/cw`, `/host/cw/.claude/wt-a`, `/host/cw/.claude/wt-gone`; `../outside` is not re-spelled. Bare clone: `worktree .../b.git`, `bare`, `worktree .../b.git/w1`.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:979-1063`, probe3.out (command `timeout 120 bash probe3.sh`, cwd scratch dir, exit 0, 2026-10-09T07:50:10Z)

---

## Claim 10a: "A refusal is memoized too, as an empty IMPORT_ROOTS (a result never is: ROOT_REAL leads it), so a refusing decision lists the registry once"

**Location:** `scripts/lib/dev-cycle-read.sh:1019-1022`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` after `IMPORT_READERS_DONE="$IMPORT_READERS_KEY"; IMPORT_ROOTS=""` (all leave IMPORT_ROOTS empty; a success puts ROOT_REAL first via `rs_r=("$ROOT_REAL" ...)`) and the key change on IMPORT_READER_WHY; does not establish behaviour of import_targets after a memoized refusal (Claim 12).

Probe3: with `IMPORT_READER_ROOTS=rel`, two calls returned `a=1`, `b=1`; clearing the list gave `c=0 roots=4`, `d=0`; git-stub listings 2 (one per key). With `IMPORT_READER_WHY=x`: `why1=1 why2=1`, clearing it `why3=0`, listings 1 (WHY refuses before listing, so the key including WHY is what lets the cleared state recompute).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:1010-1026`, probe3.out

---

## Claim 10b: "The result, a refusal included, is memoized in IMPORT_READERS_DONE, keyed on ROOT_REAL, HOME, the caller's two lists and IMPORT_READER_WHY"

**Location:** `scripts/lib/dev-cycle-read.sh:1000-1002`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which refusals are memoized; does not establish import_home's own memo behaviour.

`import_home || return 1` (`:1017`) runs before `import_readers_key` and before `IMPORT_READERS_DONE` is set (`:1018,1022`), so an import_home refusal is not memoized in IMPORT_READERS_DONE; every refusal after `:1022` is. Precise version: "a refusal after import_home included". Low impact: that path does not list the registry.

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:1015-1025`

---

## Claim 11: "It returns 1 when IMPORT_READER_WHY is set (reader_settings refused the settings), import_home or the listing fails, ..."

**Location:** `scripts/lib/dev-cycle-read.sh:993-995`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers import_readers' return and its observers: main_imports and imported_names fail (`import_readers || { ...; return 1; }` at `:1185,:1246`), truthwalk returns 0 (refuse) on a failed walk (`:1371`) and floor uses truthwalk (`:1419`); does not establish build-loop.sh's floor walk, which is U2c's.

Executed via the passing test `build-loop-check.bats:1854` (malformed or duplicate line → `walk failed`, `docs/other.md imported` for both walks) and probe3 `why1=1`.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:993-995,1025,1185,1246,1369-1373,1419`, bats.out, probe3.out

---

## Claim 12: "It also reads ... import_readers' IMPORT_ROOTS and IMPORT_HOMES when its memo key is current (else ROOT_REAL alone and import_home's home: a call outside a walk)"

**Location:** `scripts/lib/dev-cycle-read.sh:771-773` (unchanged line, made stale by this diff's D7 memo)
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers import_targets after a memoized import_readers refusal; does not establish any walk-reachable effect (both walks return before import_targets when import_readers fails) — the effect is on a direct caller such as U2b3b2's outside-seed caller (override row 538, H5).

```bash
# scripts/lib/dev-cycle-read.sh:1068-1069
  import_readers_key
  [[ -z "$IMPORT_READERS_DONE" || "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
```
(excerpt ends :1069; enclosing import_targets() continues to :1091 — read). Before this branch a refusal left `IMPORT_READERS_DONE` empty, so import_targets fell back to ROOT_REAL; now a refusal sets DONE to the current key with `IMPORT_ROOTS=""`, so import_targets passes an empty `IT_ROOTS` and the parser exits 2 (`if (nr == 0 || roots[1] == "") exit 2`, `:940`). Probe4, same repo, `IMPORT_READER_ROOTS=rel; import_readers` then `import_targets ""`: branch lib `after-refusal rc=1` (no names); main's lib printed the names and `after-refusal rc=0`. The behaviour fails closed; the comment's "else ROOT_REAL alone" no longer describes the memoized-refusal case. Precise version: "... when its memo key is current (an empty IMPORT_ROOTS, a memoized refusal, fails the call; with no current key, ROOT_REAL alone ...)".

**Legibility-target:** for-author
**Evidence:** `scripts/lib/dev-cycle-read.sh:766-780,940,1064-1091`, probe4.out (command `timeout 60 bash probe4.sh`, cwd scratch dir, exit 0, 2026-10-09T07:50:33Z)

---

## Claim 13: "Each caller root re-spells the worktrees under the main worktree, so one host alias about doubles the count (49 roots here: 1.5 s per walk, U2b3b1)."

**Location:** `scripts/lib/dev-cycle-read.sh:751-752`
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers /workspace at 2026-10-09 (25 registered worktrees); timings are wall-clock on a shared host and exclude the import_readers call made before the timer; does not establish the figure for other registries.

Probe2 over /workspace (read-only), branch lib: without readers `roots=25 main_names=128 main_s=1.35/1.29 tree_names=128 tree_s=1.61/1.60`; with `IMPORT_READER_ROOTS=/home/magfrump/claude-workflows`, `IMPORT_READER_HOMES=/home/magfrump`: `roots=49 main_names=128 main_s=1.44/1.39 tree_names=128 tree_s=1.55/1.66`. 25 → 49 is "about doubles"; 1.4-1.7 s per walk matches "1.5 s".

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:746-752`, probe2.out, probe2-timing.out (command `timeout 300 bash probe2.sh`, cwd /workspace, exit 0, 2026-10-09T07:49:29Z)

---

## Claim 14a: Commit 8ed86432 message, figures: "Over /workspace both walks still give 128 names, at 49 roots (was 25): the main walk takes 1.5 s (was 1.3 s). Suites 220/220; ... 375 code lines against main (the move counted twice)."

**Location:** commit 8ed86432 message
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 128/49/25 (probe2), timing within noise (Claim 13), 375 = numstat outside docs/ (295 added + 80 deleted), and 220 = 117 + 20 + 79 + 2 + 2 tests (build-loop-check, build-loop-read, dev-cycle, fixture-git-env, utility-smoke, the five suites prior commits list as "114/19/78/2/2"); the pass count is from this run's bats (below); does not re-run the health check.

`git diff --numstat main...HEAD | awk '$3 !~ /^docs\// {a+=$1; d+=$2} END{print a, d, a+d}'` → `295 80 375`. Test counts by `grep -c '^@test'`: 20, 117, 79, 2, 2. bats: fixture-git-env and utility-smoke 4/4 ok (bats2.out); the three changed suites: `1..216`, 216 `ok`, no `not ok`, exit 0 (command `LC_ALL=C.UTF-8 TMPDIR=$(mktemp -d /tmp/factcheck-XXXX) bats -j 4 test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/build-loop-check.bats`, cwd worktree, started 2026-10-09T07:50:49Z). 216 + 4 = 220/220.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** probe2.out, probe2-timing.out, bats.out, bats2.out (command `bats test/scripts/fixture-git-env.bats test/scripts/utility-smoke.bats`, cwd worktree, exit 0, 2026-10-09T07:51:24Z)

---

## Claim 14b: Commit 8ed86432 message, mechanism: "A second copy, a malformed line or a file FENCE_AWK refuses sets IMPORT_READER_WHY, which import_readers refuses, so both walks fail closed. Paths are absolute NAMECHARS with no empty, . or .. part, so no control byte passes (D6). import_readers memoizes a refusal (D7) and re-spells every worktree registered beneath the main worktree under each caller root (G8). main_file and SETTINGS_AWK move from build-loop.sh into the lib ... without main found by name the lists stay empty"

**Location:** commit 8ed86432 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each mechanism via Claims 3, 5, 9, 10a, 11 and the diff (main_file and SETTINGS_AWK deleted from build-loop.sh, added at lib `:532-574`); does not cover the import_targets side effect of D7 (Claim 12), which the message does not mention.

Tab between paths is refused (probe1 "tab sep" → `lists entry 1, which is not an absolute path ...`); NAMECHARS (`:202`) holds no byte below 0x2d.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:202,532-640,1015-1063`, probe1.out, probe3.out

---

## Claim 15: Test "both walks take the reader lists from main's docs/dev-cycle.md, never the working tree, and a malformed line fails them (U2b3b1; H4)"

**Location:** `test/scripts/build-loop-check.bats:1854-1877`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `T_SETTINGS=1` calls reader_settings as the scripts do (`[[ -z "${T_SETTINGS:-}" ]] || reader_settings`, `:24`), that a working-tree-only root (`/wt`) is not read (`docs/w.md -`), and a malformed line and a markup second copy fail both walks; does not test an unread file (FENCE_AWK) at the walk level (covered at --settings level in build-loop-read.bats).

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `test/scripts/build-loop-check.bats:18-27,1854-1877`, bats.out

---

## Claim 16: Test "a caller root re-spells the worktrees registered beneath the main worktree" and the D7 test comment "The walk, then isimported for each path: three calls of the walk in one decision."

**Location:** `test/scripts/build-loop-check.bats:1879-1903`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each test discriminates its feature; does not run the tests against main's lib.

G8: run from `../gate` (outside the main worktree), `@/host/cw/.claude/wt-b/docs/n.md` reads `-` with no caller root and `imported` with `/host/cw`; without re-spelling `/host/cw` alone yields only the dot path `.claude/wt-b/docs/n.md` (override row 533's case), so the test needs G8. D7: imps calls the walk once and isimported twice; isimported calls `main_imports || return 0` / `imported_names || return 0` (`scripts/lib/dev-cycle-read.sh:1334-1335`) and each walk clears its own cache on an import_readers failure (`import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; return 1; }`, `:1246`), so the walk really runs three times; `T_READER_ROOTS=rel` is refused after the listing (`:1042`), so pre-D7 code would list three times and the `-eq 1` assertion discriminates.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `test/scripts/build-loop-check.bats:1879-1903`, `scripts/lib/dev-cycle-read.sh:1185,1246,1329-1336,1038-1044`, probe3.out, bats.out

---

## Claim 17: Test "--check-fix models the host readers main's docs/dev-cycle.md names, and refuses every path on a malformed line (U2b3b1; H4)"

**Location:** `test/scripts/dev-cycle.bats:1407`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name against the body; does not dispute the behaviour.

The malformed-line step passes a single path: `run --separate-stderr bash "$DC" --check-fix docs/notes.md` (`test/scripts/dev-cycle.bats:1417`), so "every path" is asserted for one path (the earlier steps use two). The behaviour holds by construction (a failed walk skips each path in check_fix), but the test does not exercise "every".

**Legibility-target:** for-author
**Evidence:** `test/scripts/dev-cycle.bats:1407-1419`, bats.out

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- **Claim 12** (`scripts/lib/dev-cycle-read.sh:771-773`): import_targets' "else ROOT_REAL alone" fallback no longer applies after a memoized import_readers refusal (D7): the key is current with an empty IMPORT_ROOTS, so the call fails (rc 1; main's lib printed names). Fail-closed; update the comment, and U2b3b2's outside-seed caller (row 538) should know.

### Mostly Accurate
- **Claim 1** (`docs/dev-cycle.md:32-33`): "followed by a blank line" omits end of file and the fence case; the failure list omits a file the fence reader refuses.
- **Claim 10b** (`scripts/lib/dev-cycle-read.sh:1000`): "a refusal included" — an import_home refusal returns before the memo is set.
- **Claim 17** (`test/scripts/dev-cycle.bats:1407,1417`): "refuses every path" is asserted with one path.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report at the output path your role names, structured per your skill, every finding with a verbatim Evidence quote and path:line.
- Answered: yes
- Out of scope: H5, H2, C1, G9 and outside starts (U2b3b2's by the plan split); settled override rows.
- Escalate: Claim 12 (D7 changed import_targets' no-walk fallback for a memoized refusal; interacts with row 538/H5 in U2b3b2).
- Decisions I made: counted "220" as the five suites prior commit messages list (114/19/78/2/2 then); timed walks after import_readers, so the 1.5 s claim is compared with a slightly smaller number.
