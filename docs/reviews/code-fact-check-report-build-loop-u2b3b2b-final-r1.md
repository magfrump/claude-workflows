Commit: 8f99fcaf

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b3b2b (feat/build-loop-u2b3b2b)
**Scope:** `git diff main...HEAD -- scripts test` (scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, test/lib/build-loop-fixtures.bash), the U2b3b2b and U2b3b2c plan bullets in docs/working/plan-build-loop-handoff.md, and the commit messages of main..HEAD (1c820663, 39f64d62, 8f99fcaf). Final confirming pass, replicate r1 of k=3.
**Checked:** 2026-10-09
**Total claims checked:** 29
**Summary:** 23 verified, 4 mostly accurate, 2 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (docs/reviews/hallucination-patterns.md). The closest logged pattern is the one about suite counts in a commit message that do not match the suites ("All 85 tests ... but the suites hold 97"; "mode1-equiv 33 ... holds 25"). This branch's suite counts were checked against that pattern and match (Claims 26-28a). No fabricated symbol, API or flag was found.

Execution logs live outside the repo, in `/tmp/claude-1000/-workspace/7705a73b-d526-48c8-9948-70a1335d5801/scratchpad/u2b3b2b-final/ffc1-logs/` (LOGS below). The probe scripts are next to them in `.../u2b3b2b-final/ffc1-*.sh`. Every probe used `/tmp/u2b3b2b-ffc1-*` temp dirs, and all of those were removed.

---

## Claim 1: "Plan (2026-10-09, before code). ... Seeds: (1) each config dir ... gives ... `{commands,agents,output-styles,skills}/**.md` and `plugins/cache/**.md` (p) ... **Plugins: seeds**, not an exception (`plugins/cache`, every installed version, read as prompts): a superset costs one find."

**Location:** `docs/working/plan-build-loop-handoff.md:306`
**Legibility-target:** plan reader (next unit's implementer)
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how the plan bullet describes plugin seeding and C1 nesting. It does not establish whether the rest of the bullet's history (the "Review iteration 1" timings) still holds, which Claim 27 covers.

The code does not run one find over `plugins/cache/**.md`. It reads each `installed_plugins.json` with python3 and seeds only the `installPath` directories. It falls back to the whole cache only when that parse fails:

```bash
# scripts/lib/dev-cycle-read.sh:1279-1285 (outside_seeds; excerpt ends :1285; enclosing outside_seeds continues to :1344 — read)
  if [[ ${#pj[@]} -gt 0 ]]; then
    if nul_list fl python3 -I -c 'import json, sys
for f in sys.argv[1:]:
    for v in json.load(open(f))["plugins"].values():
        for e in v: sys.stdout.write(e["installPath"] + "\0")' "${pj[@]}" 2>/dev/null; then
      for d in "${fl[@]}"; do [[ "$d" != /* || ! -d "$d" ]] || pr+=("$d"); done
    else for d in "${pj[@]}"; do [[ ! -d "${d%/*}/cache" ]] || pr+=("${d%/*}/cache"); done; fi
```

The suite asserts the narrower behaviour: an uninstalled cached version `0` is not imported (`for f in h n o; do want "docs/$f.md" -; done`, test/scripts/build-loop-check.bats:407). "Every installed version" is right. "`plugins/cache/**.md`" and "a superset ... one find" describe a design the code dropped at 1c820663, whose Notes say "installed versions from installed_plugins.json, the whole cache when python3 cannot read it". The bullet's "a root nested in another listed one skipped" also predates the exception the code makes for a root below ROOT_REAL, which gets its own listing (`:1319`). The bullet does not mention iteration 2's whole-path start test either.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1279-1287`, `scripts/lib/dev-cycle-read.sh:1319`, `test/scripts/build-loop-check.bats:392-414`; LOGS/suite-build-loop-check.bats.log (bats, cwd = archive of 8f99fcaf under /tmp/u2b3b2b-ffc1-suites-*, exit 0, 2026-10-10T03:35:12Z)

---

## Claim 2: "U2b3b2c ... an import a start in another root reaches through a file that root holds with other bytes, or alone, is read from ROOT_REAL's or main's copy. ... Seeding every @-bearing .md in other roots was tried and gave 6,720 seeds over /workspace's untracked clones (both walks failed)."

**Location:** `docs/working/plan-build-loop-handoff.md:307`
**Legibility-target:** plan reader (U2b3b2c implementer)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the walks read for a repo-relative name that a C1 seed yields. It does not establish the historical 6,720 count, which depends on worktree state that has changed since.

A relative name a C1 seed yields is joined under every root and printed repo-relative. The tree walk then reads it only from ROOT_REAL's working tree:

```bash
# scripts/lib/dev-cycle-read.sh:1472 (imported_names; enclosing function :1434-1475 — read)
      if [[ -f "$p" && "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo_here "$p"; then seen+="$p"$'\n'; queue+=("$p"); fi
```

The main walk reads main's blob, or ROOT_REAL's checkout when main lacks the path (`main_checkout`, `:1587-1590`). That confirms the "other bytes" case. In the "alone" case (only the other root holds the file), neither ROOT_REAL nor main has a copy, so nothing is read. A more precise version would say "is read from ROOT_REAL's or main's copy, or not at all when only that root holds it". The 6,720 figure could not be reproduced as stated (paraphrased — no quote available because it is a historical measurement of a deleted experiment). A fresh count of @-bearing .md files over the other worktrees is in the thousands, so the figure is the same order of magnitude, but that count double-counts nested worktrees (LOGS/misc.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1464-1474`, `scripts/lib/dev-cycle-read.sh:1585-1590`; LOGS/misc.log

---

## Claim 3: "Both walks also read the repository's worktree registry (import_readers) and, through outside_seeds, the config dirs (each reader home's .claude, CLAUDE_CONFIG_DIR, IMPORT_MANAGED_DIR), the roots' ancestors and the other roots' file trees (find, grep, sha1sum, python3 on installed_plugins.json)"

**Location:** `scripts/lib/dev-cycle-read.sh:42-46`
**Legibility-target:** lib caller
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which inputs outside_seeds reads and the tools named for them. It does not establish that the tool list is complete: outside_seeds also forks realpath, xargs, sh and tr (lower_all).

```bash
# scripts/lib/dev-cycle-read.sh:1262-1264 (outside_seeds; enclosing continues to :1344 — read)
  mapfile -t rs <<<"$IMPORT_ROOTS"; mapfile -t fl <<<"$IMPORT_HOMES"
  for d in "${fl[@]}"; do [[ "$d" != /* ]] || cf+=("${d%/}/.claude"); done
  [[ -z "${CLAUDE_CONFIG_DIR:-}" ]] || cf+=("$CLAUDE_CONFIG_DIR"); cf+=("$IMPORT_MANAGED_DIR")
```

The ancestors are read at `:1265-1272`, other roots through `root_starts` (find) at `:1321`, grep through `with_at` at `:1304`/`:1330`, sha1sum at `:1340` and python3 at `:1280`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1258-1344`

---

## Claim 4: "4. Call import_reset ... or CLAUDE_CONFIG_DIR or IMPORT_MANAGED_DIR (outside_seeds reads them): neither walk's cache key holds them"

**Location:** `scripts/lib/dev-cycle-read.sh:68-74`
**Legibility-target:** gate caller (contract)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk's cache key ignoring CLAUDE_CONFIG_DIR, plus a static read of both keys. It does not establish IMPORT_MANAGED_DIR behaviour by execution; that rests on a static read of the same keys.

```bash
# scripts/lib/dev-cycle-read.sh:1441 (imported_names)
  IMPORTED_DONE="$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"; IMPORTED=error
# scripts/lib/dev-cycle-read.sh:1498 (main_imports)
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"
```

Probe P6: after a first walk, exporting `CLAUDE_CONFIG_DIR` to a dir whose CLAUDE.md imports docs/g.md left the answer `-`. After `import_reset`, the answer was `imported`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1437-1441`, `:1497-1498`; LOGS/probe1.log (command `bash ffc1-probe1.sh`, cwd /tmp, temp repo /tmp/u2b3b2b-ffc1-DjgF, exit 0, 2026-10-10T03:35:37Z; section P6)

---

## Claim 5: "8. Pass truthrule, isstart, ownfile, prompt_dir and prompt_bases a lower-cased path (prompt_dir and prompt_bases also take the path as spelled; floor, check_fix and the walks lower first ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:87-90`
**Legibility-target:** lib caller (contract)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the new call sites in this branch (outside_seeds and the walks' seed loops). It does not re-establish call sites that predate this branch.

```bash
# scripts/lib/dev-cycle-read.sh:1453-1456 (imported_names; enclosing to :1475 — read)
  for f in "${sd[@]}"; do
    p="${f:1}"; outside_ok "$p" && [[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue
    seen+="$p"$'\n'; queue+=("$p"); [[ "$f" != p* ]] || pdir[$p]="$(lower "$p")" || return 1
  done
```

`prompt_bases xs "${pdir[$f]}" "$f"` (`:1460`) then gets the lower-cased and spelled forms. Inside outside_seeds, isstart reads `lo` (lower_all output) at `:1299` and `:1333`, and the inner tail at `:1337`. main_imports does the same at `:1534-1537`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1297-1299`, `:1329-1337`, `:1453-1460`, `:1533-1537`

---

## Claim 6: "Both walks also start at outside_seeds' files (U2b3b2b; its comment lists them): ... the tree walk after the checkout's starts, the main walk in phase 2."

**Location:** `scripts/lib/dev-cycle-read.sh:744-749`
**Legibility-target:** maintainer
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ordering and phase of seed queuing in both walks. It does not establish that the main walk's phase-2 placement is observable, which the 1c820663 Notes say no test can see.

```bash
# scripts/lib/dev-cycle-read.sh:1533-1537 (main_imports; enclosing to :1593 — read)
  outside_seeds sd || return 1
  for f in "${sd[@]}"; do
    p="${f:1}"; [[ -z "${seen[$p]+set}" ]] && outside_ok "$p" || continue
    seen[$p]=1; tq+=("$p"); [[ "$f" != p* ]] || pdir[$p]="$(lower "$p")" || return 1
  done
```

The seeds go onto `tq`, which joins `queue` only when queue empties (`:1541`). In imported_names they are appended after the checkout's starts (`:1452-1456`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1443-1456`, `:1528-1541`

---

## Claim 7: "Named exceptions: a home or root this container cannot see ...; an import a start in another root reaches there through a file that root holds with other bytes or alone (routed to U2b3b2c); a symlinked directory in another root (A5); and a C1 start whose bytes match ROOT_REAL's in a checkout that is not clean (the gate's is, by contract item 2)."

**Location:** `scripts/lib/dev-cycle-read.sh:749-754`
**Legibility-target:** maintainer / reviewer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of each named gap in the code. It does not establish that the list of gaps is complete.

`root_starts` lists with `find -P` (`:1213`), which does not descend a symlinked directory. The byte skip compares against ROOT_REAL's working file (`hs+=("${cx[i]}" "${ir[i]}")`, `:1337`), while the main walk reads main's blob for a path main stores (`:1547`). The two agree only for a clean checkout at MAIN_SHA (contract item 2, `:52-56`). For the U2b3b2c gap, see Claim 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1213`, `:1337-1342`, `:1545-1548`

---

## Claim 8: "Any seed listing find, grep or sha1sum cannot complete fails the walk, so an unreadable directory in any registered worktree, or a link loop under a config dir's trees, fails every walk"

**Location:** `scripts/lib/dev-cycle-read.sh:754-757`
**Legibility-target:** operator (why a walk failed)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk under bfs 4.1.1 for both cases (main walk by shared outside_seeds code plus the suite's mode-000 test). It does not establish the sha1sum failure path by execution.

```bash
# scripts/lib/dev-cycle-read.sh:1287 (outside_seeds)
  if [[ ${#fr[@]} -gt 0 ]]; then nul_list fl find -L "${fr[@]}" -type f -iname '*.md' -print0 || return 1; ...
```

P4 put a loop `rules/loop/up -> ..` under `$HOME/.claude`. The result was `tree-failed`, with stderr "find: File system loop detected". P5 made a mode-000 dir in the other worktree. The result was `tree-failed`, with stderr "Permission denied".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1213`, `:1287-1292`, `:1321`; LOGS/probe1.log (P4, P5; same run as Claim 4)

---

## Claim 9: "The seeds cost: over this repository's 8 registered worktrees, about 50 seeds and 2 to 2.5 s per walk, against 0.6 s without (2026-10-09; i1, i2 performance)."

**Location:** `scripts/lib/dev-cycle-read.sh:759-761`
**Legibility-target:** maintainer (performance)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the live worktree set (8 worktrees, real HOME, reader_settings) on 2026-10-10 UTC under load average ~2 from other sessions. It does not establish the timing on an idle host or for a different worktree set (time-varying input).

Measured with HEAD's lib: 50 seeds. Tree walk 2.14, 3.22, 3.01, 2.06 s. Main walk 2.77, 2.60, 2.49, 2.48 s. With main's lib: tree 0.62/0.60 s, main 0.81/0.79 s. The outliers above 2.5 s came while the suites ran concurrently. True as of the worktree registry at 2026-10-10T03:36Z.

**Evidence:** LOGS/timing.log (command `bash ffc1-timing.sh`, cwd /workspace/.claude/wt-build-loop-u2b3b2b inside the script, exit 0, 2026-10-10T03:36:20Z, rerun 03:38:27Z)

---

## Claim 10: "Every name starts at an @ byte: outside_seeds drops a seed holding none (with_at leans on this)."

**Location:** `scripts/lib/dev-cycle-read.sh:937-938`
**Legibility-target:** parser maintainer
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every name path from file text (scan, names, quoted, the cross-line qopen carry, splice, the UNI_SPACES/NUL sed and python3's U+FFFD decoding). It does not cover IMPORT_WHOLE mode, whose names start at no @.

In text mode every candidate is anchored at an @. `names(line, i + 1, L)` and `names(line, i + 2, L)` run only after `substr(line, i, 1) == "@"`. `quoted` and `qopen` take text after `@"` (`:939-951`). `splice` only deletes bytes (`:969-977`). The sed maps NUL and Unicode spaces to a space, and python3's replace decoding yields U+FFFD, so neither creates an @. IMPORT_WHOLE mode takes a different path that never calls scan:

```awk
# scripts/lib/dev-cycle-read.sh:993-994 (IMPORT_AWK main rule)
  # IT_WHOLE: each line is one name, read as written (a real path a walk projects).
  if (whole) { emit($0, 1); next }
```

Those projected names hold no @. The dependence still holds: whole mode reads only import_outside's real-path projection, and outside_seeds keeps link-reached seeds for exactly that case (`:1301-1311`, `:1333`). A more precise version would say "Every name scan reads from text starts at an @ byte (IMPORT_WHOLE projections excepted; outside_seeds keeps link-reached seeds for those)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:939-977`, `:992-1003`, `:1171-1178`

---

## Claim 11: "The managed policy's directory (Claude Code on Linux), an outside_seeds config dir; set here, so the environment never moves it (a test sets it). A caller that changes it calls import_reset (contract item 4)."

**Location:** `scripts/lib/dev-cycle-read.sh:1060-1063`
**Legibility-target:** lib caller
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reset at source time. It does not establish that /etc/claude-code is Claude Code's managed-policy path on Linux (an external fact, and the dir is absent in this container).

`IMPORT_MANAGED_DIR=/etc/claude-code` (`:1063`) is unconditional. `env IMPORT_MANAGED_DIR=/x bash -c 'source lib; echo $IMPORT_MANAGED_DIR'` printed `managed=/etc/claude-code`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1063`; LOGS/misc.log (cwd /workspace/.claude/wt-build-loop-u2b3b2b, exit 0, 2026-10-10T03:37:32Z)

---

## Claim 12: "import_outside FILE ...: an absolute path (for the walks, a name from the parser's second channel, below no reader root, or an outside_seeds start, which may lie in another root)"

**Location:** `scripts/lib/dev-cycle-read.sh:1154-1156`
**Legibility-target:** maintainer
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers C1 seeds, which lie in another root, reaching import_outside. It does not establish anything new about second-channel names, which predate this branch.

`import_file` routes any `/`-led FILE to import_outside (`:1185`). P1's seed `p/tmp/.../side/.claude/skills/wt/README.md` lies in another root. The suite's C1 test then asserts docs/w.md is imported through it (build-loop-check.bats:443, passing).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1171-1185`; LOGS/probe1.log (P1); LOGS/suite-build-loop-check.bats.log

---

## Claim 13: "outside_ok PATH: whether a walk reads PATH, an absolute name (one below no reader root, or an outside_seeds start, which may lie in another root): a readable regular file"

**Location:** `scripts/lib/dev-cycle-read.sh:1186-1190`
**Legibility-target:** maintainer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test and its use on seeds in both walks. It does not establish TOCTOU behaviour after admission, which the walk header's FIFO exception names.

`outside_ok() { [[ -f "$1" && -r "$1" ]]; }` (`:1190`) is applied to every seed at `:1454` and `:1535`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1190`, `:1454`, `:1535`

---

## Claim 14: "outside_proj OUT TOTAL: the // names in the variable OUT that outside_ok rejects get one realpath -m, and each whose real path differs ... is projected whole ...; the projection's names are appended to OUT and its work to TOTAL ... It returns 1 when realpath or the projection fails, a real path holds a newline, or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:1191-1198`
**Legibility-target:** maintainer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function body and the suite's dangling-link and linked-directory test. It does not establish behaviour for a // name whose realpath -m equals itself (by design, not projected).

```bash
# scripts/lib/dev-cycle-read.sh:1203-1207 (outside_proj; enclosing :1199-1209 — read)
  [[ ${#rj[@]} -gt 0 ]] || return 0
  nul_list rl realpath -mz -- "${rj[@]}" && [[ ${#rl[@]} -eq ${#rj[@]} ]] || return 1
  for i in "${!rj[@]}"; do [[ "${rl[i]}" != *$'\n'* ]] || return 1; [[ "${rl[i]}" == "${rj[i]}" ]] || df+=("${rl[i]}"); done
  [[ ${#df[@]} -gt 0 ]] || return 0
  b="$(printf '%s\n' "${df[@]}" | IMPORT_WHOLE=1 IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - op_t)) import_targets /)" && import_work b op_t || return 1
```

`import_work` returns 1 when TOTAL passes IMPORT_WORK_MAX (`:1353`). The test at build-loop-check.bats:451-460 passes on HEAD and was red on main's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1199-1209`, `:1349-1354`; LOGS/suite-build-loop-check.bats.log; LOGS/red.log

---

## Claim 15: "root_starts ROOT: the start-named files (instruction_names) below ROOT, an absolute directory, as absolute paths, NUL-separated, listed with find -P (.git pruned): regular files and links. It fails when find or grep does."

**Location:** `scripts/lib/dev-cycle-read.sh:1210-1213`
**Legibility-target:** maintainer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-line body and the failure on an unreadable dir. It does not establish behaviour on a non-absolute ROOT (callers pass realpath output only).

`find -P "$1" -name .git -prune -o '(' -type f -o -type l ')' -iname '*.md' -print0 | instruction_names` runs under local pipefail. `instruction_names` maps grep's status 1 to 0 (`:1360`). P5 showed the find failure fails the walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1213`, `:1360`; LOGS/probe1.log (P5)

---

## Claim 16: "with_at NAME PATH...: array NAME gets the PATHs outside_ok admits that hold an @ byte, read by grep in xargs batches ... It returns 1 on any grep error"

**Location:** `scripts/lib/dev-cycle-read.sh:1214-1218`
**Legibility-target:** maintainer
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers grep status 2, grep killed by a signal, the outside_ok prefilter and the nameref chain with_at → nul_list → caller array. It does not establish behaviour when xargs itself is killed (xargs status 125 would also fail nul_list).

```bash
# scripts/lib/dev-cycle-read.sh:1219-1225 (with_at, whole function)
with_at() {
  local -n wa_a="$1"; local p wa_ok=(); shift
  # shellcheck disable=SC2034  # wa_a is the caller's array, filled by name
  wa_a=()
  for p in "$@"; do ! outside_ok "$p" || wa_ok+=("$p"); done
  [[ ${#wa_ok[@]} -eq 0 ]] || nul_list wa_a xargs -0r -a <(printf '%s\0' "${wa_ok[@]}") sh -c 'grep -lZF -e @ -- "$@"; [ $? -le 1 ]' sh
}
```

P3 used a grep shim exiting 2 and got `rc=1`. P3b used a shim that `kill -9`s itself and got `rc=1`. P2 passed three links: one to an @-free regular file, one to an @ file and one to /dev/zero. Only the @ file was kept, and /dev/zero was never grepped (outside_ok rejects it). The nameref chain works: with_at's locals (`wa_a`, `p`, `wa_ok`) and nul_list's `nl_a` do not collide with the callers' `fl`, and P2's `r` array was filled.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1219-1225`, `:1367`; LOGS/probe1.log (P2, P3, P3b)

---

## Claim 17: "(1) Each config dir (every reader home's .claude, CLAUDE_CONFIG_DIR, and IMPORT_MANAGED_DIR ...): its instruction-named files, rules/ (f), commands/, agents/, output-styles/, skills/ and each installed plugin version (p; every cached version when installed_plugins.json does not read as Claude Code writes it) and auto memory's projects/*/memory/MEMORY.md (f), its trees followed through links (find -L: the user's skills link into /opt)."

**Location:** `scripts/lib/dev-cycle-read.sh:1229-1235`
**Legibility-target:** maintainer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed source, as asserted by the suite's config-dir test and the live `~/.claude/skills -> /opt/claude-workflows/skills` link. It does not establish Claude Code's actual load set (an external fact the walks model as a superset).

`:1273-1292` builds each listing. The config-dir test (build-loop-check.bats:392-414) asserts a, b, c, d, e, f and p imported, n and o not (o comes back as imported on a broken json), and that a relative CLAUDE_CONFIG_DIR fails the walk. It passes on HEAD. misc.log shows the skills link into /opt.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1273-1292`; LOGS/suite-build-loop-check.bats.log; LOGS/misc.log

---

## Claim 18: "(2) Each ancestor of a reader root that lies below no root: its instruction-named files, and its .claude as a config dir."

**Location:** `scripts/lib/dev-cycle-read.sh:1235-1237`
**Legibility-target:** maintainer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ancestor loop up to and including `/`, and the suite's ancestor test. It does not establish behaviour for an ancestor that is unreadable (a failing find fails the walk, per the walk header).

```bash
# scripts/lib/dev-cycle-read.sh:1265-1272 (outside_seeds; enclosing to :1344 — read)
  for r in "${rs[@]}"; do
    d="$r"
    while [[ "$d" != / ]]; do
      d="${d%/*}"; d="${d:-/}"; in=""
      for q in "${rs[@]}"; do [[ "$d" != "$q" && "$d" != "$q"/* ]] || in=1; done
      [[ -n "$in" || -n "${os_s[a$d]+set}" ]] || { os_s[a$d]=1; [[ ! -d "$d" ]] || tops+=("$d"); cf+=("${d%/}/.claude"); }
    done
  done
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:1265-1272`, `:1293-1300`; LOGS/suite-build-loop-check.bats.log (test at build-loop-check.bats:416-426)

---

## Claim 19: "(3) C1: every start file (isstart, by its path below its innermost root) in another reader root present here, tracked or not (a superset)."

**Location:** `scripts/lib/dev-cycle-read.sh:1237-1239`
**Legibility-target:** maintainer / next reviewer
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which path isstart and the prompt test read for C1 candidates. It does not cover the byte-skip path, which Claim 21 covers.

Iteration 2 (B3) changed isstart and the prompt test to read the whole lower-cased path. This header sentence was not updated, so it now contradicts the inline comment beside the code:

```bash
# scripts/lib/dev-cycle-read.sh:1324-1333 (outside_seeds; excerpt ends :1333; enclosing continues to :1344 — read)
  # isstart (the authority, after instruction_names' prefilter) and the prompt
  # test read the whole path, so a start below any root holding it counts (a
  # superset: i2 fact-check, a worktree nested in a .claude/skills/); the byte
  # comparison takes the path below its innermost root.
  ...
  lo=(); if [[ ${#cx[@]} -gt 0 ]]; then nul_list lo lower_all "${cx[@]}" && [[ ${#lo[@]} -eq ${#cx[@]} ]] || return 1; fi
  ...
    isstart "${lo[i]}" && [[ -n "${os_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue
```

P1: a worktree nested at `side/.claude/skills/wt` holds README.md. Its inner path `readme.md` is not a start (`inner-not-start`). Its whole path is (`whole-start`), and outside_seeds emits `p/tmp/.../side/.claude/skills/wt/README.md`. Under the header's rule it would not be a seed. The header should say "isstart on its whole lower-cased path". The inner path is used only by the byte skip.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1237-1238`, `:1324-1337`; LOGS/probe1.log (P1, P1b); `git diff 39f64d62..8f99fcaf -- scripts` (the header lines are unchanged while :1324-1333 changed)

---

## Claim 20: "A root below another listed one comes with it, unless it lies below ROOT_REAL, whose files that listing drops: then it is listed itself (and a root below it twice, which the walks' seen absorbs)."

**Location:** `scripts/lib/dev-cycle-read.sh:1239-1241`
**Legibility-target:** maintainer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the listing and drop rules and the seen deduplication in both walks. It does not establish a test for a root nested two deep below ROOT_REAL (none exists).

```bash
# scripts/lib/dev-cycle-read.sh:1317-1323 (outside_seeds)
  for r in "${cr[@]}"; do
    # A root below another is listed with it, but one below ROOT_REAL (whose files that listing drops) by itself.
    in=""; [[ "$r" == "$ROOT_REAL"/* ]] || for q in "${cr[@]}"; do [[ "$r" != "$q"/* ]] || in=1; done
    [[ -z "$in" ]] || continue
    nul_list fl root_starts "$r" || return 1
    for d in "${fl[@]}"; do [[ "$d" == "$ROOT_REAL"/* && "$r" != "$ROOT_REAL"/* ]] || cx+=("$d"); done
  done
```

Duplicates are absorbed by `seen` at `:1454` (tree walk) and `seen[$p]` at `:1535` (main walk).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1314-1323`, `:1454`, `:1535`

---

## Claim 21: "One whose bytes equal ROOT_REAL's plain file (rawfile) at that path is skipped: the parser joins that file's names under every root and the walks start there too (given contract item 2's clean checkout ...)."

**Location:** `scripts/lib/dev-cycle-read.sh:1241-1245`
**Legibility-target:** maintainer
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skip's conditions and justification. It does not establish that the skip is safe outside contract item 2 (a named exception).

The justification is right, but the header omits two conditions the code requires before skipping: the seed must not be a link, and ROOT_REAL's copy must be a start at the inner path:

```bash
# scripts/lib/dev-cycle-read.sh:1337 (outside_seeds)
    if [[ ! -L "${cx[i]}" ]] && isstart "${lo[i]:${#lo[i]}-${#ir[i]}}" && rawfile "${ir[i]}" && outside_ok "${cx[i]}"; then sp+=("$c${cx[i]}"); hs+=("${cx[i]}" "${ir[i]}"); else os_a+=("$c${cx[i]}"); fi
```

A more precise version would say "One that is not a link, whose path below its innermost root names a start, and whose bytes equal ROOT_REAL's plain file (rawfile) there is skipped". Under the header's stale inner-path rule (Claim 19) the second condition was implied. Under the whole-path rule it is not.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1241-1247`, `:1332-1342`

---

## Claim 22: "Only a seed holding an @ byte or reached through a link (import_outside projects its real path) can yield a name, so the rest are dropped ...; an unreadable file is skipped, as outside_ok skips it."

**Location:** `scripts/lib/dev-cycle-read.sh:1250-1253`
**Legibility-target:** maintainer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the config rule (a link kept only when its real path lies below a reader root) and the C1 rule (any `-L` seed). It does not establish C1's handling of intermediate linked directories, which `find -P` never enters (A5).

P7: an @-free config rule linked to a file below no root was dropped. An @-free rule linked to `repo/docs/z.md` was kept (`f/.../rules/z.md`). C1 keeps `-L` seeds at `:1333`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1304-1312`, `:1333`; LOGS/probe1.log (P7)

---

## Claim 23: "It returns 1 when a find, grep, sha1sum, realpath or lower_all fails, a seed's path holds a newline, or CLAUDE_CONFIG_DIR is set but not absolute."

**Location:** `scripts/lib/dev-cycle-read.sh:1255-1257`
**Legibility-target:** caller
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed failure sources (python3 failure deliberately falls back rather than failing). It does not establish that "a seed's path holds a newline" covers dropped candidates, which are checked only once kept (`:1343`).

`:1261` returns 1 for a relative CLAUDE_CONFIG_DIR, and `:1343` returns 1 for a newline in a kept seed. Every find, xargs, realpath and lower_all call ends in `|| return 1`. The suite's fail-closed test (newline name, mode-000 dir, grep shim) and its relative-CLAUDE_CONFIG_DIR assertion pass on HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1261`, `:1287-1290`, `:1297`, `:1304-1307`, `:1314`, `:1321`, `:1329-1330`, `:1340`, `:1343`; LOGS/suite-build-loop-check.bats.log

---

## Claim 24: "The config seeds that can yield a name: an @ in the file, or a link on the way to a real path below a reader root (projected as that repo path; one below no root holds no @ either: i2 performance N1)."

**Location:** `scripts/lib/dev-cycle-read.sh:1301-1303`
**Legibility-target:** maintainer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the keep rule at `:1308-1312`. It does not establish the projection of a link into a root whose checkout lacks the file (outside_ok rejects a dangling seed before reading).

The code checks `os_at`, else whether `rl[i]` differs and lies below an entry of `rs`. See P7.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1304-1312`; LOGS/probe1.log (P7)

---

## Claim 25: "isstart (the authority, after instruction_names' prefilter) and the prompt test read the whole path ...; the byte comparison takes the path below its innermost root."

**Location:** `scripts/lib/dev-cycle-read.sh:1324-1327`
**Legibility-target:** maintainer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers C1's isstart, its PROMPT_DIR test and the sha1sum pair. It does not establish the config seeds' isstart, which reads whole paths too (`:1299`).

`isstart "${lo[i]}"` and `[[ ! "${lo[i]}" =~ $PROMPT_DIR ]]` read the whole path (`:1333-1334`). `hs+=("${cx[i]}" "${ir[i]}")` compares against the inner path (`:1337`). P1 confirmed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1328-1342`; LOGS/probe1.log (P1)

---

## Claim 26: Commit 1c820663: "Tests: five new in build-loop-check.bats, each red on main's lib ... Suites 125/79/20/2/2. 248 code lines against main. ... Walks over this repo's worktrees take about 7 s each against 0.7 s"

**Location:** `1c820663` (commit message)
**Legibility-target:** reviewer
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers red-on-main for the five tests, the line count, the @test count at 1c820663 (125) and timing re-measured today. It does not establish that the suites passed at 1c820663 itself (only HEAD's suites were run).

1c820663's test file was run against main's lib: all five U2b3b2b tests reported `not ok`. `git diff --shortstat main..1c820663 -- scripts test` gives 225+23 = 248. 1c820663's lib took 7.32 s (tree) and 7.17 s (main), with 143 seeds. Main's lib took 0.6-0.8 s.

**Evidence:** LOGS/red.log (command `bash ffc1-red.sh`, cwd /tmp, exit 0, 2026-10-10T03:37Z region; section (b)); LOGS/timing2.log (exit 0, 2026-10-10T03:37:56Z)

---

## Claim 27: Commit 39f64d62: "Walks over this repository's 8 worktrees: 7 s -> 3 to 3.5 s, same names. ... Suites 125/79/20/2/2; 302 code lines against main."

**Location:** `39f64d62` (commit message)
**Legibility-target:** reviewer
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the line count and today's timing of 39f64d62's lib (2.99 s tree, 3.59 s main, 85 seeds, the same 1210 repo names as 1c820663). It does not establish the suites at 39f64d62 itself.

273+29 = 302. The repo-name count matches between 1c820663 and 39f64d62 (1210/1210).

**Evidence:** LOGS/timing2.log

---

## Claim 28a: Commit 8f99fcaf: "Each new assertion is red on 39f64d62's lib. Suites 125/79/20/2/2; 333 code lines against main. ... Walks: 2 to 2.5 s over 8 worktrees, same 1177 names."

**Location:** `8f99fcaf` (commit message)
**Legibility-target:** reviewer
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers red-on-39f64d62 for the two changed tests, all five suites at 8f99fcaf (125/79/20/2/2, all ok), 303+30 = 333 and the walk timing. It does not establish the absolute name count 1177, which is time-varying (today 1210, equal across 39f64d62 and HEAD, so "same" holds).

Running 8f99fcaf's tests against 39f64d62's lib, the C1 test failed at `want: docs/w.md: imported` and the fail-closed test failed at `want: walk: failed` (grep shim).

**Evidence:** LOGS/red.log (section (a)); LOGS/suites.exit and LOGS/suite-*.log (command `ffc1-suites.sh`, cwd = `git archive 8f99fcaf` extract under /tmp/u2b3b2b-ffc1-suites-*, all exit 0, 2026-10-10T03:35:12Z to 03:36:47Z); LOGS/timing.log

---

## Claim 28b: Commit 8f99fcaf B1: "with_at reads only seeds outside_ok admits, keeps links unread, and accepts grep status 0 or 1 only"

**Location:** `8f99fcaf` (commit message)
**Legibility-target:** reviewer
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers with_at's treatment of links. It does not concern C1's keep rule, which keeps a link without needing an @.

with_at greps an admitted link through to its target. In P2, a link to an @ file was kept and a link to an @-free file was dropped, so both targets were read. Only a link to a non-regular file (/dev/zero, a FIFO) stays unread, because outside_ok rejects it (`:1223`). A more precise version would say "keeps links to anything but a readable regular file unread". The other two atoms are verified (Claim 16).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1219-1225`; LOGS/probe1.log (P2)

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 1** (`docs/working/plan-build-loop-handoff.md:306`): the plan describes plugins as `plugins/cache/**.md` in one find. The code seeds installPaths from installed_plugins.json, with the whole cache only as a fallback. The nesting rule also lacks the below-ROOT_REAL exception.
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:1237-1238`): the outside_seeds header says C1's isstart reads "its path below its innermost root". Since 8f99fcaf it reads the whole lower-cased path (`:1324-1333`), and only the byte skip uses the inner path.

### Mostly Accurate
- **Claim 2** (`docs/working/plan-build-loop-handoff.md:307`): "or alone, is read from ROOT_REAL's or main's copy": when only the other root holds the file, nothing is read.
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:937-938`): "Every name starts at an @ byte" holds for text but not for IMPORT_WHOLE projections (which outside_seeds covers via link-reached seeds).
- **Claim 21** (`scripts/lib/dev-cycle-read.sh:1241-1245`): the byte-skip sentence omits the seed-not-a-link and ROOT_REAL-copy-is-a-start-at-the-inner-path conditions (`:1337`).
- **Claim 28b** (`8f99fcaf` message): "keeps links unread": with_at greps through admitted links. Only links to non-regular files stay unread.

### Unverifiable
(none as separate claims; the residues are named in the Scope lines of Claims 2, 9, 11 and 28a)

---

## Goal-Alignment Note

The PR's goal is that both import walks start at the outside seeds (config dirs, ancestors, C1) and fail closed. The code does what the PR intent describes. Every behavioural claim checked by execution held: the suites at HEAD are 125/79/20/2/2 all ok, the new tests are red on their stated bases, the fail-closed paths fire on a find loop, an unreadable dir and grep status 2 or a signal, and the timings reproduce at about 2-2.5 s against 0.6 s. The two Stale findings are documentation drift with no behavioural defect:

- the outside_seeds header's C1 sentence was not updated for iteration 2's whole-path isstart;
- the plan's "before code" plugin description predates the installed_plugins.json design.

Both are one-line text fixes. Neither changes what the walks import, and neither affects the fail-closed property the self-merge floor relies on. The Mostly-accurate items are precision gaps in a header, a parser comment, a plan bullet and a commit message, none of which would lead a caller to an unsafe use.
