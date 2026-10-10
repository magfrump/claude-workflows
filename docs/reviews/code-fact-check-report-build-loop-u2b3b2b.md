Commit: 1c820663

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b3b2b, branch feat/build-loop-u2b3b2b)
**Scope:** `git diff main...HEAD` (main 07fe578b, HEAD 1c820663): scripts/lib/dev-cycle-read.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/working/plan-build-loop-handoff.md, plus commit message 1c820663
**Checked:** 2026-10-09 (probes ran 2026-10-10T03:03Z to 03:06Z UTC)
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 24 (Claim 19 split into 19a/19b)
**Summary:** 16 verified, 3 mostly accurate, 1 stale, 3 incorrect, 1 unverifiable

The hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read first. No claim here matches a logged pattern. The closest family is the "suite count claimed in commit" entries, and this commit's counts check out (Claim 21).

Execution provenance. All executed claims used scripts in the session scratchpad (`S=/tmp/claude-1000/-workspace/7705a73b-d526-48c8-9948-70a1335d5801/scratchpad`). Each script created its own `mktemp -d /tmp/u2b3b2b-fc-*` dir, refused git outside that dir, and removed the dir at the end. Captured output is in `$S/u2b3b2b-fc-logs/`:
- `u2b3b2b-fc-suites.sh`: cwd is its temp dir. Started 2026-10-10T03:03:54Z, ended 03:05:29Z, exit 0. Per-suite exit codes are in `suites.rc`, TAP output in `head-*.tap` and `mainlib-new.tap`.
- `u2b3b2b-fc-probe.sh`: cwd is its temp dir. Run at 2026-10-10T03:04:42Z, exit 0, output in `probe.out`.
- `u2b3b2b-fc-probe2.sh`: cwd is its temp dir. Run at 2026-10-10T03:05:14Z, exit 0, output in `probe2.out`.

Environment note: `find` on this host is bfs 4.1.1, not GNU find. Every option the lib uses (`-printf '%P\0'`, `-xtype`, `-iname`, `-L` loop detection) behaved as the comments describe.

---

## Claim 1: "pushed onto the main walk's tq (K5, pinned by a test)"

**Location:** `docs/working/plan-build-loop-handoff.md:306`
**Type:** Staleness / Reference
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** plan doc, read by the next unit's planner and by reviewers
**Verification mode:** static
**Scope:** Covers whether any test in the branch pins the main walk's phase-2 placement of seeds. Does not establish whether such a test is possible (see Claim 23).

The plan paragraph was written "before code" and promises a K5 test. The commit that implemented it says the opposite: "K5 has no observable test (seeds read the same in either phase)" (commit 1c820663 body). None of the five new tests checks phase order (paraphrased — no quote available because this claim is about the absence of code: `rg 'K5|phase 2' test/scripts/build-loop-check.bats` matches only pre-existing tests at :101, :802 and :853). The plan's promise was overtaken by the implementation and was not updated.

**Evidence:** `docs/working/plan-build-loop-handoff.md:306`, `test/scripts/build-loop-check.bats:688-756`, commit 1c820663 message

---

## Claim 2: "Both walks also start at outside_seeds' files ... the tree walk after the checkout's starts, the main walk in phase 2."

**Location:** `scripts/lib/dev-cycle-read.sh:740-745`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** walk header comment, read by maintainers of both walks
**Verification mode:** executed
**Scope:** Covers where each walk enqueues seeds relative to its own starts. Does not establish that the seed list is complete (Claims 4 and 19b).

In the tree walk, seeds are appended to `queue` after the `tree_starts` loop:
```bash
# scripts/lib/dev-cycle-read.sh:1392-1396
  outside_seeds sd || return 1
  for f in "${sd[@]}"; do
    p="${f:1}"; outside_ok "$p" && [[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue
    seen+="$p"$'\n'; queue+=("$p"); [[ "$f" != p* ]] || pdir[$p]="$p"
  done
```
In the main walk, seeds go to `tq`, which becomes `queue` only once main's queue is empty:
```bash
# scripts/lib/dev-cycle-read.sh:1475-1476, 1481
    seen[$p]=1; tq+=("$p"); ...
    [[ $qi -lt ${#queue[@]} ]] || { queue=("${tq[@]}"); tq=(); qi=0; }  # phase 2
```
The five new tests and the three walk suites pass on HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1374-1415`, `scripts/lib/dev-cycle-read.sh:1431-1533`; `$S/u2b3b2b-fc-logs/head-build-loop-check.tap` (125 ok)

---

## Claim 3: "Named exceptions: a home or root this container cannot see ..., a C1 start whose bytes match ROOT_REAL's file at its path in a checkout that is not clean ..., and an ancestor or config dir find cannot list, which fails the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:745-749`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** walk header comment, read by reviewers who audit the floor's coverage
**Verification mode:** executed
**Scope:** Covers the three exceptions the header names, each of which holds. Does not establish that the list is complete: the list leaves out one exception, an unnamed C1 gap in a clean checkout (below).

Each named exception holds:
- An absent root is dropped by `-d "$r"` (`:1259`).
- A find failure returns 1. The probe showed `find: File system loop detected` followed by `walk tree: failed` (`probe.out`, P3), and test 5 shows the same.
- The main walk reads main's blob, not the checkout, so a dirty checkout breaks the byte comparison.

The list is missing one case. If ROOT_REAL's copy of a start is one the tree walk does not read itself, the C1 copy elsewhere is still skipped when its bytes match, even in a clean checkout. A committed symlinked `CLAUDE.md` is an example: `inrepo_here` refuses it (`scripts/lib/dev-cycle-read.sh:1387`, `if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi`). For details see Claim 19b. A precise version of the comment would add "or one whose ROOT_REAL copy the tree walk itself skips (inrepo_here)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:745-749`, `:1259`, `:1277`, `:1387`; `$S/u2b3b2b-fc-logs/probe.out`, `$S/u2b3b2b-fc-logs/probe2.out`

---

## Claim 4: "over this repository's 6 registered worktrees, about 140 seed files and 7 s per walk, against 0.7 s without (2026-10-09; the file-system listing of other roots is about 1.9 s of it)"

**Location:** `scripts/lib/dev-cycle-read.sh:749-752`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** walk header comment, read by anyone weighing the per-walk cost
**Verification mode:** static
**Scope:** Covers nothing beyond the current worktree count. Does not establish the 140, 7 s, 0.7 s or 1.9 s figures.

Reproducing these figures needs a timed walk over /workspace's live registry. The probe rules confine lib runs to throwaway repos, and the registry has changed since the measurement: `git worktree list | wc -l` now prints 8, against the 6 the comment records. To verify, time `imported_names` and `main_imports` with `ROOT_REAL=/workspace` on a quiet host and count `outside_seeds`' output.

**Evidence:** `scripts/lib/dev-cycle-read.sh:749-752`

---

## Claim 5: "The managed policy's directory ... set here, so the environment never moves it (a test sets it)."

**Location:** `scripts/lib/dev-cycle-read.sh:1050-1052`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** lib global's comment, read by callers and test authors
**Verification mode:** executed
**Scope:** Covers the value after sourcing when the environment exports MANAGED_DIR. Does not establish anything about a caller that assigns it after sourcing, which is how the tests set it.

The lib assigns `MANAGED_DIR=/etc/claude-code` unconditionally (`:1052`). The probe `env MANAGED_DIR=/elsewhere bash -c 'source "$LIB"; echo "MANAGED_DIR=$MANAGED_DIR"'` printed `MANAGED_DIR=/etc/claude-code` (`probe.out`, P8). Test 1 in dev-cycle.bats also checks that the variable is declared (`test/scripts/dev-cycle.bats:1112`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1052`; `$S/u2b3b2b-fc-logs/probe.out`

---

## Claim 6: "outside_proj OUT TOTAL: the // names in the variable OUT that outside_ok rejects get one realpath -m, and each whose real path differs ... is projected whole ... appended to OUT and its work to TOTAL ... It returns 1 when realpath or the projection fails, a real path holds a newline, or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:1179-1186`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** function header, read by maintainers of both walks
**Verification mode:** executed
**Scope:** Covers the rejected-name filter, the single realpath call, the whole-name projection with its work charge, and each return-1 path listed. Does not establish that names the projection itself prints are re-projected; they are not, because the function makes only one pass.

```bash
# scripts/lib/dev-cycle-read.sh:1189-1195
  while IFS= read -r p; do [[ "$p" != //* ]] || outside_ok "${p#/}" || rj+=("${p#/}"); done < <(printf '%s\n' "$op_o")
  [[ ${#rj[@]} -gt 0 ]] || return 0
  nul_list rl realpath -mz -- "${rj[@]}" && [[ ${#rl[@]} -eq ${#rj[@]} ]] || return 1
  for i in "${!rj[@]}"; do [[ "${rl[i]}" != *$'\n'* ]] || return 1; [[ "${rl[i]}" == "${rj[i]}" ]] || df+=("${rl[i]}"); done
  [[ ${#df[@]} -gt 0 ]] || return 0
  b="$(printf '%s\n' "${df[@]}" | IMPORT_WHOLE=1 IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - op_t)) import_targets /)" && import_work b op_t || return 1
  [[ -z "$b" ]] || op_o+="${op_o:+$'\n'}$b"
```
`import_work` returns 1 when the total passes the maximum (`:1293`). Both walks call the function after `import_work`. In the tree walk the call is at `:1403`. In the main walk it is at `:1517`, after every case arm, so main's blobs are projected too. Both calls come before the `used` charge, so the projected names count toward IMPORT_OUT_MAX. The new test for dangling links and linked directories passes on HEAD and fails on main's lib (`mainlib-new.tap`, "not ok 4").

**Evidence:** `scripts/lib/dev-cycle-read.sh:1187-1196`, `:1289-1294`, `:1403`, `:1517`; `$S/u2b3b2b-fc-logs/head-build-loop-check.tap`, `$S/u2b3b2b-fc-logs/mainlib-new.tap`

---

## Claim 7: "(1) Each config dir (every reader home's .claude, CLAUDE_CONFIG_DIR when absolute, and MANAGED_DIR ...): its instruction-named files, rules/ (f), commands/, agents/, output-styles/, skills/ and plugins/cache/ (p; every installed plugin version, a superset) and auto memory's projects/*/memory/MEMORY.md (f)"

**Location:** `scripts/lib/dev-cycle-read.sh:1200-1204`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** outside_seeds header, read by reviewers who map seeds to Claude Code's loader
**Verification mode:** executed
**Scope:** Covers the config-dir set and which subtrees are listed. Does not establish that Claude Code loads exactly these.

The config dirs, rules, prompt dirs and the auto-memory depth filter all match the comment (`:1220-1221`, `:1230-1235`, `:1247-1252`). Test 1 confirms them: `n` (another memory file) is not imported, while `d` (MEMORY.md) is.

"plugins/cache/" is imprecise. The code does not list `plugins/cache` itself. It lists each `installPath` that `installed_plugins.json` names, and lists the whole cache only when python3 fails:
```bash
# scripts/lib/dev-cycle-read.sh:1144-1145
      for d in "${fl[@]}"; do [[ "$d" != /* || ! -d "$d" ]] || pr+=("$d"); done
    else for d in "${pj[@]}"; do [[ ! -d "${d%/*}/cache" ]] || pr+=("${d%/*}/cache"); done; fi
```
With a valid JSON file, only the installed version was listed: `cache/b/1`, but not `cache/b/0` (`probe.out`, P5, "home only"). A config dir with a cache but no `installed_plugins.json` contributes no plugin seeds. An installPath outside `plugins/cache` is listed anyway. A more precise wording: "each installed plugin version's directory, as installed_plugins.json names it (the whole plugins/cache when it cannot be parsed)". The inline comment at `:1236-1238` already says this.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1216-1252`; `$S/u2b3b2b-fc-logs/probe.out`

---

## Claim 8: "followed through links (find -L: the user's skills link into /opt)"

**Location:** `scripts/lib/dev-cycle-read.sh:1204-1205`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** outside_seeds header
**Verification mode:** executed
**Scope:** Covers the rules, prompt and memory listings using `-L`, and the skills link on this host. Does not establish whether other hosts have the same layout.

The rules, prompt and memory listings use `find -L` (`:1247`, `:1248`, `:1250`). On this host, `ls -ld /home/node/.claude/skills` prints `/home/node/.claude/skills -> /opt/claude-workflows/skills`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1247-1250`

---

## Claim 9: "(2) Each ancestor of a reader root that lies below no root: its instruction-named files, and its .claude as a config dir."

**Location:** `scripts/lib/dev-cycle-read.sh:1205-1207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** outside_seeds header
**Verification mode:** executed
**Scope:** Covers the ancestor loop's below-no-root test and what each ancestor contributes. Does not establish anything about ancestors of host roots that do not exist here: they are skipped by `-d`, which is the named exception A3.

```bash
# scripts/lib/dev-cycle-read.sh:1225-1227
      d="${d%/*}"; d="${d:-/}"; in=""
      for q in "${rs[@]}"; do [[ "$d" != "$q" && "$d" != "$q"/* ]] || in=1; done
      [[ -n "$in" || -n "${os_s[a$d]+set}" ]] || { os_s[a$d]=1; [[ ! -d "$d" ]] || tops+=("$d"); cf+=("${d%/}/.claude"); }
```
Each top-level file is then filtered by `isstart` on its whole path (`:1256`, `:1269`). Test 2 passes on HEAD and fails on main's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1222-1229`, `:1256`; `$S/u2b3b2b-fc-logs/head-build-loop-check.tap`, `$S/u2b3b2b-fc-logs/mainlib-new.tap`

---

## Claim 10: "(3) C1: every start file isstart names in another reader root present here, tracked or not (a superset), listed once: a root below another listed one comes with it"

**Location:** `scripts/lib/dev-cycle-read.sh:1207-1209`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** outside_seeds header, read by anyone who would drop the walks' de-duplication
**Verification mode:** executed
**Scope:** Covers the "listed once" property when roots are nested. Does not establish any effect on walk results: the walks de-duplicate seeds through `seen` (`:1394`, `:1475`), so a duplicate costs a second hash and nothing more.

A root below another listed one is listed again, along with its parent, whenever it lies below ROOT_REAL:
```bash
# scripts/lib/dev-cycle-read.sh:1262-1265
    in=""; [[ "$r" == "$ROOT_REAL"/* ]] || for q in "${cr[@]}"; do [[ "$r" != "$q"/* ]] || in=1; done
    [[ -z "$in" ]] || continue
    nul_list fl find -P "$r" -name .git -prune -o '(' -type f -o -type l ')' -iname '*.md' -printf '%P\0' || return 1
    for d in "${fl[@]}"; do [[ "$r/$d" == "$ROOT_REAL"/* && "$r" != "$ROOT_REAL"/* ]] || { rel+=("$d"); abs+=("$r/$d"); }; done
```
Take ROOT_REAL `r`, a worktree `r/q`, and a worktree `r/q/r2` inside it. Both are below ROOT_REAL, so both are listed, and `q`'s listing keeps `r2`'s files, because the drop applies only when `q` is not below ROOT_REAL. The probe printed `fT/p1a/r/q/r2/CLAUDE.local.md` twice (`probe.out`, P1a).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1259-1266`, `:1394`, `:1475`; `$S/u2b3b2b-fc-logs/probe.out`

---

## Claim 11: "and ROOT_REAL's own files are the walks' already" (C1 drops them)

**Location:** `scripts/lib/dev-cycle-read.sh:1209-1210`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** outside_seeds header
**Verification mode:** executed
**Scope:** Covers the drop of files under ROOT_REAL when ROOT_REAL is nested inside another listed root, and the exclusion of ROOT_REAL itself from `cr`. Does not establish that the walks read every one of those files: they do not read files `inrepo_here` refuses (Claim 19b).

ROOT_REAL is excluded from `cr` (`:1259`, `[[ "$r" != "$ROOT_REAL" && -d "$r" ...`). When ROOT_REAL lies inside another root, its files are dropped from that root's listing (`:1265`, quoted in Claim 10). In the probe, ROOT_REAL was `m/wt` inside root `m`. The output listed `m/CLAUDE.local.md` and `m/sub/CLAUDE.md`, and nothing under `m/wt` (`probe2.out`, P1b).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1259`, `:1265`; `$S/u2b3b2b-fc-logs/probe2.out`

---

## Claim 12: "Roots are listed from the file system (find -P, .git pruned), never with git -C"

**Location:** `scripts/lib/dev-cycle-read.sh:1210-1212`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** outside_seeds header, read by security reviewers
**Verification mode:** executed
**Scope:** Covers outside_seeds' listing of other roots. Does not establish anything about git run elsewhere in the walks: `import_readers` runs `git worktree list` in ROOT_REAL, which is by design.

The listing is `find -P "$r" -name .git -prune ...` (`:1264`), and no `git` call appears in outside_seeds (`:1216-1284`, read in full). Test 3 wraps `git` in a logging shim and asserts that no call was made with cwd under the other root and no call used `-C` (`test/scripts/build-loop-check.bats:732`). The test passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1216-1284`; `test/scripts/build-loop-check.bats:726-733`; `$S/u2b3b2b-fc-logs/head-build-loop-check.tap`

---

## Claim 13: "It returns 1 when a find, realpath or lower_all fails, or a seed's path holds a newline."

**Location:** `scripts/lib/dev-cycle-read.sh:1212-1213`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** outside_seeds header, read by callers
**Verification mode:** executed
**Scope:** Covers every `return 1` in the function body. Does not establish behaviour when python3 fails, which by design falls back to the whole cache instead of returning 1 (Claim 14).

Every condition listed returns 1. The list leaves out the `sha1sum` failure and the short-count checks:
```bash
# scripts/lib/dev-cycle-read.sh:1280
    nul_list lo sha1sum -z -- "${hs[@]}" && [[ ${#lo[@]} -eq ${#hs[@]} ]] || return 1
```
With ROOT_REAL's `CLAUDE.local.md` made mode 000, the probe printed `sha1sum: CLAUDE.local.md: Permission denied` and then `outside_seeds rc=1` (`probe.out`, P9). The walk fails closed, as intended. Only the list in the comment is short.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1267`, `:1280`, `:1283`; `$S/u2b3b2b-fc-logs/probe.out`

---

## Claim 14: "Plugins: each installed version's directory, as installed_plugins.json names it; a file python3 cannot read that way gives every cached version (a superset, rather than a failed walk)."

**Location:** `scripts/lib/dev-cycle-read.sh:1236-1238`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** inline comment, read by maintainers
**Verification mode:** executed
**Scope:** Covers the parse path and the fallback. Does not establish that the fallback is per file: a single bad file switches every config dir to its whole cache. That is still a superset, but python's traceback lands on the walk's stderr.

On a successful parse, only the installed version is listed (Claim 7, P5 "home only"). In the probe, `$CLAUDE_CONFIG_DIR/plugins/installed_plugins.json` was invalid and `~/.claude`'s was valid. The output listed every cached version of both: `b/0`, `b/1` and `a/1`. A python `JSONDecodeError` traceback was printed to stderr (`probe.out`, P5 "both"). Test 1's fallback check (`test/scripts/build-loop-check.bats:703`) does not assert an empty stderr, so the traceback goes unchecked.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1139-1146`; `$S/u2b3b2b-fc-logs/probe.out`

---

## Claim 15: "-H and -xtype, not -L: a link to a file counts, and a link to an ancestor (a loop to find -L) is not followed."

**Location:** `scripts/lib/dev-cycle-read.sh:1253-1255`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** inline comment
**Verification mode:** executed
**Scope:** Covers the depth-1 tops listing. Does not establish anything about the `-L` subtree listings, where an ancestor link does fail the walk: a fail-closed path that is the second exception in Claim 3.

In an ancestor, a link to a file was listed (`fT/p3/CLAUDE.md`). A link to the ancestor itself (`self -> .`) produced neither an entry nor an error (`probe.out`, P3). For contrast, under `rules/` (listed with `find -L`), a link `up -> ..` made bfs print "File system loop detected", and the walk failed and answered imported. A dangling link under `rules/` was skipped without error, and the walk succeeded.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1256`, `:1247`; `$S/u2b3b2b-fc-logs/probe.out`

---

## Claim 16: "A root below another is listed with it, unless the walks' own ROOT_REAL, whose files are dropped there, lies between."

**Location:** `scripts/lib/dev-cycle-read.sh:1261`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** inline comment, read by maintainers
**Verification mode:** executed
**Scope:** Covers the condition under which a nested root is listed on its own. Does not establish any walk-result difference: the walks de-duplicate seeds.

The code exempts every root below ROOT_REAL, whether or not ROOT_REAL lies between it and the enclosing root: `[[ "$r" == "$ROOT_REAL"/* ]] || for q in ...` (`:1262`, quoted in Claim 10). When both roots are below ROOT_REAL, ROOT_REAL does not lie between them. The inner root is listed on its own and also with its parent, so its files appear twice (`probe.out`, P1a). A precise version: "unless it lies below ROOT_REAL".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1261-1265`; `$S/u2b3b2b-fc-logs/probe.out`

---

## Claim 17: "The outside starts, after the checkout's, admitted as a // name is."

**Location:** `scripts/lib/dev-cycle-read.sh:1391`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** inline comment
**Verification mode:** static
**Scope:** Covers the tree walk's admission and order. Does not establish anything about the seed list itself.

Seeds pass the same `outside_ok` and `seen` tests that a `//` import passes at `:1410`, and they are appended after the `tree_starts` loop (`:1392-1396`, quoted in Claim 2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1391-1396`, `:1410`

---

## Claim 18: "The outside starts join phase 2, as an outside import does (never main's arms)."

**Location:** `scripts/lib/dev-cycle-read.sh:1472`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** inline comment
**Verification mode:** static
**Scope:** Covers the queue a seed goes to and the case arm that reads it. Does not establish phase-order effects (Claim 23).

A seed is an absolute path, so `ent[$f]` is never set for it, and `case "${ent[$f]-checkout}"` takes the `checkout)` arm (`:1484-1486`). That arm calls `import_file`, which sends a path starting with `/` to `import_outside` (`:1174`). An outside import is queued the same way: `tq+=("$p")` (`:1525`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1473-1477`, `:1484-1486`, `:1174`, `:1525`

---

## Claim 19a: "A C1 start whose bytes equal ROOT_REAL's file at its path below its innermost root yields no name that file does not (the parser joins a repo file's names under every root)"

**Location:** `scripts/lib/dev-cycle-read.sh:1271-1273`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** inline comment, read by reviewers of the C1 skip
**Verification mode:** static
**Scope:** Covers name-set containment between the absolute C1 read and the repo read of identical bytes, prompts included. Does not establish that the repo copy is actually read (19b).

The C1 copy is read through `import_outside` with its absolute directory as the base (`:1161`, `d="${1%/*}"`), so its relative names resolve under that one root. The repo copy's directory is relative and is joined under every reader root, the other root included (`scripts/lib/dev-cycle-read.sh:792-798`: "each a repo-relative directory joined under every reader root or, led by /, an absolute one joined as it is"). Its names are therefore a superset. For prompts, the C1 seed's `prompt_bases` are "" plus the absolute prefix before `.claude`, which is the other root. The repo copy gets "" (`:663-672`), which already covers that root. Confidence is medium because the parser (IMPORT_AWK) was not re-read end to end for dotnest pruning.

**Evidence:** `scripts/lib/dev-cycle-read.sh:663-672`, `:792-798`, `:1160-1167`, `:1268-1278`

---

## Claim 19b: "and the walks read that file as a start already"

**Location:** `scripts/lib/dev-cycle-read.sh:1273-1274`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** inline comment and the walk header's exception list (Claim 3), read by reviewers who audit floor coverage
**Verification mode:** executed
**Scope:** Covers the tree walk when ROOT_REAL's copy fails `inrepo_here`, in a clean checkout. Does not establish any main-walk gap in a clean checkout: the main walk read the symlinked start and answered imported.

The skip tests only `-f "$d"` (which follows links) and `isstart` on ROOT_REAL's copy:
```bash
# scripts/lib/dev-cycle-read.sh:1277
    if [[ -n "$q" && -f "$d" ]] && isstart "${lo[i]:${#lo[i]}-${#d}}" && outside_ok "${abs[i]}"; then sp+=("$c${abs[i]}"); hs+=(...); else os_a+=("$c${abs[i]}"); fi
```
The tree walk, however, skips a start that `inrepo_here` refuses (`:1387`). In the probe, a repo committed `CLAUDE.md -> docs/real.md`, and `real.md` imports `@<root>/docs/x.md`. A sibling worktree held the same symlink, and the checkout was clean.
- The seed list was empty, and the tree walk answered `docs/x.md: -`. The main walk answered `docs/x.md: imported`.
- With one extra line in the sibling's copy, so the bytes differ, the sibling's file became a seed and the tree walk answered `docs/x.md: imported` (`probe2.out`, P2).

So the skip drops a start whose names the tree walk then never reads, even though a session in the sibling worktree loads them. The gap matches how the tree walk already treats ROOT_REAL's own symlinked start, but neither this comment nor the walk header names it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1268-1282`, `:1383-1390`, `:184`; `$S/u2b3b2b-fc-logs/probe2.out`

---

## Claim 20: "T_MANAGED becomes MANAGED_DIR (by default a path that does not exist)."; bl_setup "The walks read the config dirs under HOME and CLAUDE_CONFIG_DIR (outside_seeds): the fixture's home only."

**Location:** `test/scripts/build-loop-check.bats:18-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** test helper comments, read by test authors
**Verification mode:** static
**Scope:** Covers the imps helper and bl_setup. Does not establish whether other suites that source the lib unset CLAUDE_CONFIG_DIR; dev-cycle.bats does (`test/scripts/dev-cycle.bats:18-19`).

`imps` sets `MANAGED_DIR="${T_MANAGED:-/nonexistent/managed}"` (`test/scripts/build-loop-check.bats:25`). bl_setup does `export HOME="$BATS_TEST_TMPDIR/home" LC_ALL=C; unset CLAUDE_CONFIG_DIR` (`test/lib/build-loop-fixtures.bash:20`).

**Evidence:** `test/scripts/build-loop-check.bats:15-29`, `test/lib/build-loop-fixtures.bash:19-20`

---

## Claim 21: Commit 1c820663: "five new in build-loop-check.bats, each red on main's lib ... Suites 125/79/20/2/2. 248 code lines against main."

**Location:** commit 1c820663 message
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** commit message, read by the merge reviewer
**Verification mode:** executed
**Scope:** Covers the five tests' results against main's lib, the suite counts and pass state, and the line count. Does not establish which two 2-test suites the commit meant: three such suites exist, and all of them pass.

- **Red on main's lib.** In an exported copy of HEAD with `scripts/lib/dev-cycle-read.sh` taken from main, `bats -f U2b3b2b` gave "not ok" for all five tests. Each failed on its first `want` because the walks did not reach the seeded imports (`mainlib-new.tap`, exit 1).
- **Suite counts.** On HEAD, build-loop-check passed 125/125, dev-cycle 79/79 and build-loop-read 20/20. fixture-git-env, utility-smoke and fixture-hermeticity each passed 2/2, all with exit 0 (`suites.rc`).
- **Line count.** `git diff --numstat main...HEAD` outside docs gives 144+18, 2+1, 75+1 and 4+3, for a total of 248.

**Evidence:** `$S/u2b3b2b-fc-logs/suites.rc`, `$S/u2b3b2b-fc-logs/head-*.tap`, `$S/u2b3b2b-fc-logs/mainlib-new.tap`, `$S/u2b3b2b-fc-suites.sh`

---

## Claim 22: Commit 1c820663: "plugins are seeds (installed versions from installed_plugins.json, the whole cache when python3 cannot read it), not an exception; A3 (an unseen host home) stays a named exception."

**Location:** commit 1c820663 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** commit message
**Verification mode:** executed
**Scope:** Covers the plugin seed behaviour and A3's presence in the header. Does not establish anything about the stderr noise noted in Claim 14.

The plugin behaviour matches (P5, Claim 14). A3 is named in the walk header (`scripts/lib/dev-cycle-read.sh:745-746`: "a home or root this container cannot see (the host's: U2b3b2a i1 security F1, A3)").

**Evidence:** `scripts/lib/dev-cycle-read.sh:745-746`, `:1139-1146`; `$S/u2b3b2b-fc-logs/probe.out`

---

## Claim 23: Commit 1c820663: "K5 has no observable test (seeds read the same in either phase)."

**Location:** commit 1c820663 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** commit message, read against override row 576
**Verification mode:** static
**Scope:** Covers the main walk's per-name routing, which does not depend on phase. Does not establish timing or budget-order effects, which are not observable in the walk's answer.

In `main_imports`, where an imported name goes depends only on `ent` and `main_checkout`, never on the current phase:
```bash
# scripts/lib/dev-cycle-read.sh:1525-1530
      [[ "$p" != //* ]] || { p="${p#/}"; [[ -z "${seen[$p]+set}" ]] && outside_ok "$p" && seen[$p]=1 && tq+=("$p"); continue; }
      [[ -z "${seen[$p]+set}" ]] || continue
      c=0; [[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p" || c=$?
      [[ $c -ne 1 ]] || { IMPORTED_MAIN=error; return 1; }
      seen[$p]=1
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); elif [[ $c -eq 0 ]]; then tq+=("$p"); fi
```
Both phases append to the same `queue` and read seeds through the same arm. Moving the seeds into phase 1 would therefore produce the same IMPORTED_MAIN set (paraphrased — no quote available because this follows from the loop's control flow at `:1480-1532` as a whole, not from one line).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1478-1533`

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:1208`): the comment says C1 starts are "listed once", but a root nested in another root, with both below ROOT_REAL, is listed twice. This is harmless because the walks de-duplicate. Fix the wording, or skip such a root.
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:1261`): the comment says a nested root is exempt only when "ROOT_REAL lies between". The code exempts any root below ROOT_REAL. The comment should say "unless it lies below ROOT_REAL".
- **Claim 19b** (`scripts/lib/dev-cycle-read.sh:1273-1274`): "the walks read that file as a start already" is false for the tree walk when ROOT_REAL's copy fails `inrepo_here`, for example a committed symlinked CLAUDE.md. A same-bytes C1 copy is then skipped and its imports go unread, even in a clean checkout. The probe showed `tree docs/x.md: -`, while the main walk answered imported. Either name this case or make the skip also require `inrepo_here "$d"`.

### Stale
- **Claim 1** (`docs/working/plan-build-loop-handoff.md:306`): the plan says "K5, pinned by a test", but the commit states that no test is possible and none was added.

### Mostly Accurate
- **Claim 3** (`scripts/lib/dev-cycle-read.sh:745-749`): the named-exceptions list omits the Claim 19b case.
- **Claim 7** (`scripts/lib/dev-cycle-read.sh:1203`): "plugins/cache/" is really the installPath directories that installed_plugins.json names. The whole cache is listed only on a parse failure, and nothing is listed without the JSON file.
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:1212-1213`): the return-1 list omits the sha1sum failure and the short-count checks.

### Unverifiable
- **Claim 4** (`scripts/lib/dev-cycle-read.sh:749-752`): "7 s per walk", "about 140 seed files" and "1.9 s" need a timed walk over /workspace's live registry. That registry now holds 8 worktrees, not 6.

---

## Goal-Alignment Note

The unit's goal is to make both import walks start where Claude Code sessions actually start: config dirs, ancestors, and other worktrees' start files. Executed checks confirm that this works and fails closed:
- All five new tests are red on main's lib and green on HEAD.
- The six suites pass.
- Unlistable seeds fail the walk.
- Git is never run in another root.

The one substantive finding is Claim 19b. The C1 same-bytes skip assumes the tree walk reads ROOT_REAL's copy. When that copy is a symlinked start, which the tree walk refuses, the skip silently drops a start that a session in the other worktree loads, even in a clean checkout, and the walk header's exception list does not name the case. Its reach is narrow and matches how the tree walk already treats its own symlinked starts, so it is a documentation-or-one-condition fix, not a design problem. Claims 10 and 16 are wording-only (harmless duplicates). Claim 1 is plan-doc drift. Nothing found undermines the fail-closed design rule. The python traceback on stderr during the plugin fallback (Claim 14) is worth a glance by whoever checks walk stderr.
