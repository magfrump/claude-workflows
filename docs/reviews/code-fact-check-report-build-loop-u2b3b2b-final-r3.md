Commit: 8f99fcaf
# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b3b2b, branch feat/build-loop-u2b3b2b)
**Scope:** `git diff main...HEAD -- scripts test` at 8f99fcaf (scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, test/lib/build-loop-fixtures.bash), the U2b3b2b and U2b3b2c plan bullets in docs/working/plan-build-loop-handoff.md, and the three commit messages in `git log main..HEAD`. I read these functions whole: `outside_seeds`, `with_at`, `root_starts`, `outside_proj`, `outside_ok`, `import_outside`, `import_file`, `imported_names`, `main_imports`, `nul_list`, `isstart`, `prompt_bases`, `rawfile`, `scan` (IMPORT_AWK), plus the walk header and contract items 1-9.
**Checked:** 2026-10-09 (probes ran 2026-10-10T03:34Z-03:42Z UTC)
**Replication:** replicate 3 of 3 (k=3, final confirming pass)
**Total claims checked:** 32
**Summary:** 24 verified, 6 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`). No claim below matches a logged pattern. Commit 8f99fcaf's suite tally (`125/79/20/2/2`) resembles the logged class "suite count claimed in commit", but this time it checks out (Claim 31).

`$S` stands for `/tmp/claude-1000/-workspace/7705a73b-d526-48c8-9948-70a1335d5801/scratchpad/u2b3b2b-final`. Each probe script (`$S/ffc3-*.sh`) makes its own temp dir under `/tmp/u2b3b2b-ffc3-*`, and each removed it. After the run, `ls /tmp | grep -c u2b3b2b-ffc3` gave 0. The timing probes ran in the worktree read-only: they sourced the lib and ran `find`, `grep` and `git ls-files`, with no git writes. `git status --short` was empty afterwards.

---

## Claim 1: "Plan (2026-10-09, before code). One lib function, `outside_seeds ARRAY` ... (3) C1: each other root present here, real path deduplicated, a root nested in another listed one skipped and ROOT_REAL's own files dropped ... Any find failure fails the walk. Seeds are admitted by outside_ok, deduplicated with the walk's seen, appended after the tree walk's repo starts and pushed onto the main walk's tq ... Review iteration 1: ... walks 7 s → 3 to 3.5 s"

**Location:** `docs/working/plan-build-loop-handoff.md:306`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers each design element of the plan bullet against the code at 8f99fcaf. It does not establish that the plan was meant to track iteration 2: the bullet records iteration 1 only.

Most of the bullet matches the code. The seeds are queued after the checkout's starts in the tree walk, as the plan says (`dev-cycle-read.sh:1452-1456`, `outside_seeds sd || return 1` then `queue+=("$p")`), and on `tq` in the main walk (`:1533-1537`, `tq+=("$p")`).

The nesting rule is narrower in the plan than in the code. The plan says "a root nested in another listed one skipped". The code skips such a root only when it is not below ROOT_REAL:

```bash
# scripts/lib/dev-cycle-read.sh:1318-1320
    # A root below another is listed with it, but one below ROOT_REAL (whose files that listing drops) by itself.
    in=""; [[ "$r" == "$ROOT_REAL"/* ]] || for q in "${cr[@]}"; do [[ "$r" != "$q"/* ]] || in=1; done
    [[ -z "$in" ]] || continue
```

(excerpt ends :1320; enclosing outside_seeds() continues to :1344 — read)

The bullet also records iteration 1 only. Iteration 2's changes are missing: the grep-status rule, the link-to-a-root rule for config seeds and the whole-path isstart. It still gives the iteration-1 timing (3 to 3.5 s), where the code header now says 2 to 2.5 s. A precise version would add "unless it lies below ROOT_REAL" to the nesting rule and add an iteration-2 note.

**Evidence:** `docs/working/plan-build-loop-handoff.md:306`, `scripts/lib/dev-cycle-read.sh:1317-1323`, `:1452-1456`, `:1533-1537`

---

## Claim 2: "an import a start in another root reaches through a file that root holds with other bytes, or alone, is read from ROOT_REAL's or main's copy"

**Location:** `docs/working/plan-build-loop-handoff.md:307`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the gap the bullet describes: a repo-relative name a seed yields is read only at ROOT_REAL (tree walk) or main/ROOT_REAL (main walk). It does not establish the proposed name-driven fix.

A name a seed yields comes back repo-relative, and both walks read repo-relative names in ROOT_REAL. The tree walk does `if [[ -f "$p" && ... ]] && inrepo_here "$p"; then ... queue+=("$p")` (`:1472`). The main walk does `[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"` (`:1587`). Neither walk opens another root's copy of the file.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1468-1473`, `:1582-1591`

---

## Claim 3: "Seeding every @-bearing .md in other roots was tried and gave 6,720 seeds over /workspace's untracked clones (both walks failed)."

**Location:** `docs/working/plan-build-loop-handoff.md:307`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers today's count of @-bearing .md files in other roots, which shows the order of magnitude. It does not establish the historical 6,720 or the failure of that discarded code, which is no longer in any commit.

`find -P /workspace -name .git -prune -o -path <this worktree> -prune -o -type f -iname '*.md' -print0 | xargs -0r grep -lZF -e @` now counts 10,839 files. That is the same order of magnitude as the claim, but the set has grown since. The discarded attempt cannot be rerun. To check the claim, someone would need the attempt's code or its log. Command cwd: /workspace. Exit 0. 2026-10-10T03:41Z.

**Evidence:** `docs/working/plan-build-loop-handoff.md:307`; the count is the command output quoted above (paraphrased — no quote available because a terminal-only count was not captured to a file)

---

## Claim 4: "Both walks also read the repository's worktree registry (import_readers) and, through outside_seeds, the config dirs (each reader home's .claude, CLAUDE_CONFIG_DIR, IMPORT_MANAGED_DIR), the roots' ancestors and the other roots' file trees (find, grep, sha1sum, python3 on installed_plugins.json)"

**Location:** `scripts/lib/dev-cycle-read.sh:42-46`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the input sources and the named tools. It does not establish that the tool list is exhaustive: `realpath`, `xargs` and `tr` (lower_all) also run.

The config dirs are built at `:1263-1264`: `cf+=("${d%/}/.claude")`, `cf+=("$CLAUDE_CONFIG_DIR")`, `cf+=("$IMPORT_MANAGED_DIR")`. The ancestors come from the loop at `:1265-1272`. The other roots are listed through `root_starts` (`:1321`). `sha1sum` runs at `:1340`, and `python3 ... installPath` at `:1280-1283`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1259-1344`

---

## Claim 5: Contract item 4: "... or CLAUDE_CONFIG_DIR or IMPORT_MANAGED_DIR (outside_seeds reads them): neither walk's cache key holds them"

**Location:** `scripts/lib/dev-cycle-read.sh:68-74`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both walks' cache keys and import_readers' memo key. It does not establish that any caller calls import_reset when it changes either variable (no caller changes them today).

The tree walk's key is `IMPORTED_DONE="$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1441`). The main walk's key is `IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1498`). import_readers' key is built from ROOT_REAL, HOME, the reader lists and IMPORT_READER_WHY (`:1068-1069`). None of the three holds CLAUDE_CONFIG_DIR or IMPORT_MANAGED_DIR.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1067-1069`, `:1440-1441`, `:1497-1498`

---

## Claim 6: Contract item 8: "Pass truthrule, isstart, ownfile, prompt_dir and prompt_bases a lower-cased path (... the walks lower first ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:86-89`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the calls this branch adds: isstart and PROMPT_DIR in outside_seeds, and pdir/prompt_bases for seeds in both walks. It does not re-check callers that predate the branch.

outside_seeds always passes isstart a lower-cased path. At `:1298-1299` it runs `nul_list lo lower_all "${fl[@]}"` and then `isstart "${lo[i]}"`. At `:1329-1333`, the C1 path, it runs `nul_list lo lower_all "${cx[@]}"` and then `isstart "${lo[i]}"`. The byte-skip test at `:1337` passes `isstart "${lo[i]:${#lo[i]}-${#ir[i]}}"`, which is a tail of a lower-cased string. Both walks lower a seed before storing it for prompt_bases: `pdir[$p]="$(lower "$p")"` (`:1455`, `:1536`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1298-1299`, `:1329-1337`, `:1455`, `:1536`

---

## Claim 7: Walk header: "Both walks also start at outside_seeds' files ...: the user's memory, rules, prompts, installed plugins and auto memory under each config dir, the managed policy, instruction files in ancestors below no root, and the start files other reader roots hold (C1); the tree walk after the checkout's starts, the main walk in phase 2."

**Location:** `scripts/lib/dev-cycle-read.sh:744-749`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each seed class reaching both walks: by the branch's tests, and by probe P1 for ancestors, nested roots, link seeds and the byte skip. It does not establish phase placement observably (K5: a seed reads the same in either phase). I checked phase placement statically.

All five new tests pass at HEAD, and every one fails on main's lib (`$S/ffc3-red.log`, `$S/ffc3-red2.log`). Probe P1 lists the seeds for a fixture: it keeps an ancestor's `AGENTS.md` that holds an @, and drops the ancestor's @-free `CLAUDE.md`. For phase placement, the tree walk appends to `queue` after the checkout's starts (`:1452-1455`), and the main walk appends to `tq` (`:1536`). `tq` joins the queue only once main's walk is done: `[[ $qi -lt ${#queue[@]} ]] || { queue=("${tq[@]}"); tq=(); qi=0; }` (`:1541`).

Commands: `timeout 600 bash $S/ffc3-red.sh` and `$S/ffc3-red2.sh` (each `bats -f U2b3b2b` against main's, 39f64d62's, 1c820663's and 8f99fcaf's libs), and `timeout 120 bash $S/ffc3-p1.sh`. cwd /workspace/.claude/wt-build-loop-u2b3b2b. Exit 0 each. 2026-10-10T03:36Z-03:41Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1452-1456`, `:1533-1541`; `$S/ffc3-red.log`, `$S/ffc3-red2.log`, `$S/ffc3-p1.log`

---

## Claim 8: Named exceptions: "a home or root this container cannot see ...; an import a start in another root reaches there through a file that root holds with other bytes or alone (routed to U2b3b2c); a symlinked directory in another root (A5); and a C1 start whose bytes match ROOT_REAL's in a checkout that is not clean" (also outside_seeds' "Not covered" lines)

**Location:** `scripts/lib/dev-cycle-read.sh:749-754`, `:1245-1247`, `:1253-1255`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each named exception against the code that produces it. It does not establish that the list is complete: see Claim 21 for a byte-skip residue the list does not name.

An unseen root or home is skipped because each source is tested with `-d` (`:1270`, `:1274`, `:1315`). A symlinked directory is not entered because the listing is `find -P "$1" -name .git -prune -o '(' -type f -o -type l ')'` (`:1213`). The other-bytes gap is Claim 2. The not-clean exception follows from the byte skip comparing against the working-tree file (`rawfile "${ir[i]}"`, `:1337`), while the main walk reads main's blob for a path main stores (`:1547`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1213`, `:1270-1274`, `:1315`, `:1337`, `:1547`

---

## Claim 9: "Any seed listing find, grep or sha1sum cannot complete fails the walk, so an unreadable directory in any registered worktree, or a link loop under a config dir's trees, fails every walk"

**Location:** `scripts/lib/dev-cycle-read.sh:754-758`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers an unreadable directory in another root, one in ROOT_REAL when ROOT_REAL is not nested in another root, and a config-dir link loop, for both walks. It does not establish behaviour when ROOT_REAL itself is nested in another root, where the outer root's `find` crosses ROOT_REAL; I read that case statically as failing.

Probe P3 (`$S/ffc3-p3.log`):

- **Unreadable directory in another root:** both walks fail. The output shows `find: '.../side/locked': Permission denied` and `tree failed` / `main failed`.
- **Config link loop:** both walks fail. The output shows `find: File system loop detected` and `tree failed` / `main failed`.
- **Unreadable directory in ROOT_REAL (a top-level root):** the result is `tree ok`, `main failed`. ROOT_REAL's own tree is not a seed listing (`[[ "$r" != "$ROOT_REAL" ...` at `:1315`). The tree walk's `tree_starts` does not check git's stderr (`:1384`), so git's `warning: could not open directory 'locked/'` does not fail it. The main walk fails through `checkout_md`.

The mechanism is right. "any registered worktree" is broader than the code, though: a precise version says "any other registered worktree (or, for the main walk, the checkout)".

Command: `timeout 120 bash $S/ffc3-p3.sh`. cwd /workspace/.claude/wt-build-loop-u2b3b2b. Exit 0. 2026-10-10T03:41:08Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1213`, `:1287-1290`, `:1315`, `:1384`, `:1388`; `$S/ffc3-p3.log`

---

## Claim 10: "The seeds cost: over this repository's 8 registered worktrees, about 50 seeds and 2 to 2.5 s per walk, against 0.6 s without (2026-10-09; i1, i2 performance)."

**Location:** `scripts/lib/dev-cycle-read.sh:759-761`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers wall time for each walk at HEAD's lib and at main's lib, over /workspace's 8 worktrees with reader_settings applied, at load average about 1.8 (other sessions running). It does not establish timings on another host or under another load.

Results from `$S/ffc3-time.log`, two runs per walk:

| Lib | Walk | Time per walk | Seeds |
|---|---|---|---|
| HEAD | tree | 2.09 / 2.10 s | 50 |
| HEAD | main | 2.54 / 2.47 s | 50 |
| main | tree | 0.60 / 0.59 s | — |
| main | main | 0.80 / 0.84 s | — |

There are 8 worktrees and 15 roots. The seed count and the with-seeds range hold. "0.6 s without" holds for the tree walk only. The main walk takes about 0.8 s without seeds, so a precise version says "0.6 to 0.8 s without".

Command: `timeout 600 bash $S/ffc3-time.sh`. cwd: its temp dir, with each walk run in `/workspace/.claude/wt-build-loop-u2b3b2b`. Exit 0. 2026-10-10T03:37:41Z. Load-dependent.

**Evidence:** `$S/ffc3-time.log`

---

## Claim 11: scan: "Every name starts at an @ byte: outside_seeds drops a seed holding none (with_at leans on this)."

**Location:** `scripts/lib/dev-cycle-read.sh:937-938`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers file text read without IMPORT_WHOLE, through scan, quoted mentions, comment splices, NUL and UNI_SPACES blanking, and python3 replacement decoding. Seed files are always read that way. It does not hold for IMPORT_WHOLE input, which never reaches scan.

In probe P2 (`$S/ffc3-p2.log`), @-free text yields no names. This covers plain text, a quote with a comment, invalid UTF-8, fullwidth `＠` (U+FF20), a NUL, and an overlong `\xc1\x80`: each prints only the work trailer (`/0` or `/16`). With an @ the parser yields names, and a splice after an @ yields the spliced name.

Under `IMPORT_WHOLE=1`, though, `docs/a.md` comes back as `//docs/a.md` with no @. That is because the awk main block does `if (whole) { emit($0, 1); next }` (`:994`) before `scan`. So "every name" is true only for text the parser reads, which is everything with_at filters, since a seed's own bytes are never read whole. A precise version says "Every name read from a file's text starts at an @ byte (IMPORT_WHOLE input does not)".

Command: `timeout 60 bash $S/ffc3-p2.sh`. cwd /workspace/.claude/wt-build-loop-u2b3b2b. Exit 0. 2026-10-10T03:41:08Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:939-951`, `:992-1003`; `$S/ffc3-p2.log`

---

## Claim 12: "The managed policy's directory (Claude Code on Linux), an outside_seeds config dir; set here, so the environment never moves it (a test sets it). A caller that changes it calls import_reset"

**Location:** `scripts/lib/dev-cycle-read.sh:1060-1063`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the unconditional assignment at source time and the test override after sourcing. It does not establish Claude Code's managed-policy path, which is an external fact.

`IMPORT_MANAGED_DIR=/etc/claude-code` (`:1063`) is unconditional, so an inherited value is overwritten. The test's `imps` sets it after `source`: `IMPORT_MANAGED_DIR="${T_MANAGED:-/nonexistent/managed}"` (`build-loop-check.bats:25`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1063`, `test/scripts/build-loop-check.bats:25`

---

## Claim 13: import_outside and outside_ok: "an absolute name (one below no reader root, or an outside_seeds start, which may lie in another root)"

**Location:** `scripts/lib/dev-cycle-read.sh:1154-1156`, `:1186-1188`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that a C1 seed path inside another root is passed to import_file/import_outside as an absolute path, and that its names resolve to repo paths. It does not establish anything beyond the two callers.

`import_file` sends any `/`-led path to `import_outside` (`:1185`). A C1 seed reads against its own absolute directory: `import_targets "${d:-/}"` (`:1175`). The C1 test checks that `t: @../docs/t.md` in `$sd/sub/CLAUDE.md` makes `docs/t.md` imported in both walks (`build-loop-check.bats:737`, `:743`), and it passes at HEAD (`$S/ffc3-suites.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1171-1185`; `$S/ffc3-suites.log`

---

## Claim 14: outside_proj header: "the // names in the variable OUT that outside_ok rejects get one realpath -m, and each whose real path differs ... is projected whole ... appended to OUT and its work to TOTAL ... It returns 1 when realpath or the projection fails, a real path holds a newline, or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:1191-1198`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the whole function body and its two call sites. It does not establish that a `//` name the projection yields is itself re-projected; the header does not claim it.

The body does what the header says:

- One call: `nul_list rl realpath -mz -- "${rj[@]}"` (`:1204`).
- Newline refusal: `[[ "${rl[i]}" != *$'\n'* ]] || return 1` (`:1205`).
- Projection: `IMPORT_WHOLE=1 ... import_targets /` then `import_work b op_t` (`:1207`), which returns 1 past IMPORT_WORK_MAX (`:1353`).

Both walks call it after `import_work` (`:1463`, `:1577`). The projection test (`build-loop-check.bats:747-756`) passes at HEAD and fails on main's lib (`$S/ffc3-red.log`, `not ok 4`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1199-1209`, `:1463`, `:1577`; `$S/ffc3-red.log`

---

## Claim 15: root_starts: "the start-named files (instruction_names) below ROOT ... listed with find -P (.git pruned): regular files and links. It fails when find or grep does."

**Location:** `scripts/lib/dev-cycle-read.sh:1210-1212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the find expression and the failure propagation. It does not establish isstart parity beyond instruction_names' documented prefilter role.

The function is `local -; set -o pipefail; find -P "$1" -name .git -prune -o '(' -type f -o -type l ')' -iname '*.md' -print0 | instruction_names` (`:1213`). `instruction_names` returns 1 only when grep fails (`:1360`). Probe P3 shows a find permission error failing both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1213`, `:1360`; `$S/ffc3-p3.log`

---

## Claim 16: with_at: "array NAME gets the PATHs outside_ok admits that hold an @ byte, read by grep in xargs batches ... It returns 1 on any grep error"

**Location:** `scripts/lib/dev-cycle-read.sh:1214-1218`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers outside_ok filtering (FIFO, /dev/zero, unreadable, missing), the nameref chain `with_at fl` → `nul_list wa_a` into a caller's local array, and grep status 2 failing the call. It does not establish behaviour under signals or partial xargs batches beyond the status rule.

The grep step is `sh -c 'grep -lZF -e @ -- "$@"; [ $? -le 1 ]'` (`:1224`). Any grep status of 2 or more makes `sh` exit 1, `xargs` then exits 123, and `nul_list` fails.

Probe P1 (`$S/ffc3-p1.log`) ran two cases from a function-local `fl`:

- Six paths: plain @-free, `at.md`, a FIFO, `/dev/zero`, mode 000, and missing. The result was `rc=0 n=1 <…/at.md>`, with no hang.
- The same call with a `grep` shim that exits 2 gave `shim rc=1 n=0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1219-1225`, `:1367`; `$S/ffc3-p1.log`

---

## Claim 17: outside_seeds (1): "Each config dir (every reader home's .claude, CLAUDE_CONFIG_DIR, and IMPORT_MANAGED_DIR ...): its instruction-named files, rules/ (f), commands/, agents/, output-styles/, skills/ and each installed plugin version (p; every cached version when installed_plugins.json does not read as Claude Code writes it) and auto memory's projects/*/memory/MEMORY.md (f), its trees followed through links (find -L: the user's skills link into /opt)."

**Location:** `scripts/lib/dev-cycle-read.sh:1229-1235`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed class through the config test, which passes at HEAD and fails on main's lib, and the /opt link on this host. It does not establish that a top-level file is admitted by instruction name alone: `isstart` on the whole path would also admit a prompt-dir path if a config dir were itself inside one, which no real config dir is.

The code matches the header:

- Rules, prompts and memory are listed with `find -L` (`:1287-1290`), and memory at `-mindepth 3 -maxdepth 3 -name MEMORY.md`.
- Plugins come from the JSON's installPaths (`:1280-1284`), falling back to `plugins/cache` (`:1285`).

The config test (`build-loop-check.bats:688-710`) checks each class, the fallback (`o.md`) and the relative-`CLAUDE_CONFIG_DIR` failure. It passes at HEAD and fails on main (`$S/ffc3-red.log`). `ls -la /home/node/.claude/skills` shows `-> /opt/claude-workflows/skills`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1273-1300`; `$S/ffc3-red.log`, `$S/ffc3-suites.log`

---

## Claim 18: outside_seeds (2): "Each ancestor of a reader root that lies below no root: its instruction-named files, and its .claude as a config dir."

**Location:** `scripts/lib/dev-cycle-read.sh:1235-1237`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers ancestors up to `/`, deduplicated, and tested `-d`. It does not establish reading an ancestor that is not a directory here (skipped).

The loop is `[[ -n "$in" || -n "${os_s[a$d]+set}" ]] || { os_s[a$d]=1; [[ ! -d "$d" ]] || tops+=("$d"); cf+=("${d%/}/.claude"); }` (`:1270`). P1 seeds `$T/w/AGENTS.md`, the parent of the root. The ancestor test passes at HEAD and fails on main.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1265-1272`; `$S/ffc3-p1.log`, `$S/ffc3-red.log`

---

## Claim 19: outside_seeds (3): "C1: every start file (isstart, by its path below its innermost root) in another reader root present here"

**Location:** `scripts/lib/dev-cycle-read.sh:1237-1238`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers which path isstart reads when it selects C1 seeds, at 39f64d62 and at HEAD. It does not establish any defect in the selection: whole-path selection is a superset of inner-path selection.

The header was right at 39f64d62, where `nul_list lo lower_all "${ir[@]}"` lower-cased the inner path (39f64d62 `:1307`). Iteration 2 (B3) changed this to the whole path:

```bash
# scripts/lib/dev-cycle-read.sh:1329, 1333
  lo=(); if [[ ${#cx[@]} -gt 0 ]]; then nul_list lo lower_all "${cx[@]}" && [[ ${#lo[@]} -eq ${#cx[@]} ]] || return 1; fi
    isstart "${lo[i]}" && [[ -n "${os_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue
```

(excerpt lines from enclosing outside_seeds(), :1258-1344 — read). The inline comment at `:1324-1327` now says isstart reads "the whole path". The header line was not updated. The executed evidence is the HEAD C1 test's nested `.claude/skills/wt/README.md`: it is not a start by its inner path (`readme.md`), yet `docs/w.md` is imported. That assertion fails on 39f64d62's lib (`$S/ffc3-red.log`: `want: docs/w.md: imported`). The fix is "isstart, by its whole lower-cased path; the byte comparison uses the path below its innermost root".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1237-1238`, `:1324-1337`; `git show 39f64d62:scripts/lib/dev-cycle-read.sh` `:1223`, `:1304-1311`; `$S/ffc3-red.log`

---

## Claim 20: "A root below another listed one comes with it, unless it lies below ROOT_REAL, whose files that listing drops: then it is listed itself (and a root below it twice, which the walks' seen absorbs)."

**Location:** `scripts/lib/dev-cycle-read.sh:1238-1241`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a worktree nested below ROOT_REAL and another nested below that one. It does not establish the case where ROOT_REAL is itself nested in another root; I read that case statically as consistent (`:1322`).

Probe P1 seeds `…/repo/nest/inner/CLAUDE.md` once and `…/repo/nest/inner/deeper/CLAUDE.md` twice. Both walks succeed, and `seen` absorbs the duplicate (`:1454`, `:1535`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1317-1323`; `$S/ffc3-p1.log`

---

## Claim 21: "One whose bytes equal ROOT_REAL's plain file (rawfile) at that path is skipped: the parser joins that file's names under every root and the walks start there too (given contract item 2's clean checkout ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:1241-1245`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the same-bytes skip for a plain start (P1, the C1 test's `s.md`) and for a seed that is a prompt by its whole path but a plain start at its inner path (P4). It does not establish whether Claude Code loads a CLAUDE.md under `.claude/skills/<dir>/` as a prompt; the lib treats any .md there as a prompt (a superset).

For a plain start the justification holds. P1 skips `side/AGENTS.md`, which has the same bytes, and `docs/s.md` is still imported.

There is a residue the justification does not name. The skip compares bytes only, but the walks read the skipped seed and ROOT_REAL's copy differently:

- The seed would be read as a prompt, because `c=p` follows `"${lo[i]}" =~ $PROMPT_DIR` on the whole path (`:1334`). As a prompt, its names would also resolve against prompt_bases, which includes the directory holding the `.claude`.
- ROOT_REAL's copy, at an inner path such as `CLAUDE.md`, is walked as a plain start.

Probe P4 (`$S/ffc3-p4.log`) shows the effect. A worktree is nested at `side/sub/.claude/skills/wt`, and its `CLAUDE.md` (`c: @z.md`) has the same bytes as ROOT_REAL's. Both walks then answer `sub/z.md=-`. Add one blank line so the bytes differ, and both answer `sub/z.md=imported`, with the seed tagged `p`. A precise version adds "and is a prompt there exactly when the seed is" to the skip condition. Otherwise the header should name the residue.

Command: `timeout 120 bash $S/ffc3-p4.sh`. cwd /workspace/.claude/wt-build-loop-u2b3b2b. Exit 0. 2026-10-10T03:41:08Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1332-1342`, `:662-676`; `$S/ffc3-p4.log`, `$S/ffc3-p1.log`

---

## Claim 22: "Roots are listed with find -P (.git pruned), never git -C: a loop controls its worktree's .git file"

**Location:** `scripts/lib/dev-cycle-read.sh:1248-1250`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers outside_seeds and both walks over a fixture with a sibling worktree. It does not establish that no git command reads another root's config through some other path outside these functions.

The C1 test puts a git shim on PATH that logs `$PWD $*`. It asserts that no logged line starts with the sibling root and that no line holds ` -C ` (`build-loop-check.bats:735`, `:745`). The test passes at HEAD (`$S/ffc3-suites.log`). No `git` call appears in `outside_seeds` (paraphrased — no quote available because the claim covers absence of code: `:1258-1344` holds no git invocation).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1213`, `:1258-1344`; `$S/ffc3-suites.log`

---

## Claim 23: "Only a seed holding an @ byte or reached through a link (import_outside projects its real path) can yield a name, so the rest are dropped (i1 performance F1); an unreadable file is skipped, as outside_ok skips it."

**Location:** `scripts/lib/dev-cycle-read.sh:1250-1253`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers @-free plain files (dropped), links into a root (kept), links out of every root with no @ (also dropped, per `:1301-1303`) and unreadable files (skipped). It does not establish that "the rest" is the full drop set. The header gives a necessary condition, and the inline comment narrows it for config links.

Probe P1 shows each case:

| Seed | Result |
|---|---|
| `l_out.md` (link out of every root, no @) | dropped |
| `none.md` (@-free) | dropped |
| `unr.md` (mode 000) | dropped |
| `l_in.md` (link into the repo) | kept |
| `at.md` (holds an @) | kept |

**Evidence:** `scripts/lib/dev-cycle-read.sh:1304-1312`, `:1330-1333`; `$S/ffc3-p1.log`

---

## Claim 24: "It returns 1 when a find, grep, sha1sum, realpath or lower_all fails, a seed's path holds a newline, or CLAUDE_CONFIG_DIR is set but not absolute."

**Location:** `scripts/lib/dev-cycle-read.sh:1255-1257`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers find (unreadable directory, loop), grep (shim), a newline in a kept seed, and a relative CLAUDE_CONFIG_DIR, all executed. It covers sha1sum, realpath and lower_all statically. It does not establish python3's failure path, which is a fallback, not a failure (correctly omitted).

The failure tests pass at HEAD:

- The fail-closed test checks mode 000, a newline name and the grep shim (`build-loop-check.bats:758-769`).
- The config test checks `CLAUDE_CONFIG_DIR=rel` (`:707`).

For the static cases: sha1sum (`:1340`), realpath (`:1307`, `:1314`) and lower_all (`:1298`, `:1329`) each end in `|| return 1`. The final check is `[[ "$d" != *$'\n'* ]] || return 1` over `os_a` (`:1343`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1261`, `:1287-1343`; `$S/ffc3-suites.log`, `$S/ffc3-p3.log`

---

## Claim 25: "Top-level files, by isstart on their whole path. -H and -xtype, not -L: a link to a file counts, and a link to an ancestor (a loop to find -L) is not followed."

**Location:** `scripts/lib/dev-cycle-read.sh:1293-1295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the find flags' semantics (bfs 4.1.1 / GNU-compatible). It does not establish an executed run with a top-level link loop.

The command is `find -H "${tops[@]}" -maxdepth 1 -xtype f -print0` (`:1297`). `-H` follows only the command-line roots. `-maxdepth 1` stops descent. `-xtype f` matches a symlink whose target is a regular file. The result goes through `isstart "${lo[i]}"` on the lower-cased whole path (`:1299`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1296-1300`

---

## Claim 26: "The config seeds that can yield a name: an @ in the file, or a link on the way to a real path below a reader root (projected as that repo path; one below no root holds no @ either: i2 performance N1)."

**Location:** `scripts/lib/dev-cycle-read.sh:1301-1303`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers keep and drop for link-reached config seeds by where their real path lies. It does not establish that dropping out-of-root links loses nothing: their real file's bytes are the bytes with_at already found @-free.

P1 keeps `l_in.md` and drops `l_out.md` (Claim 23). The probe in `$S/ffc3-names.log` compared the walks' names with 39f64d62's lib against HEAD's over /workspace. Both libs give 1177 distinct repo names. The only differences are 35 `//opt/claude-workflows/skills/...` outside names that the dropped link seeds used to project.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1304-1312`; `$S/ffc3-p1.log`, `$S/ffc3-names.log`

---

## Claim 27: "isstart (the authority, after instruction_names' prefilter) and the prompt test read the whole path, so a start below any root holding it counts (a superset ...); the byte comparison takes the path below its innermost root." / "isstart on the inner path's tail of lo: ROOT_REAL's copy must be a start there too."

**Location:** `scripts/lib/dev-cycle-read.sh:1324-1327`, `:1335-1336`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers selection on the whole path, the prompt tag on the whole path, and the inner-path start test before the byte skip. It does not cover the prompt-class residue of the skip (Claim 21).

The code is `isstart "${lo[i]}"`, then `c=f; [[ ! "${lo[i]}" =~ $PROMPT_DIR ]] || c=p`, then `isstart "${lo[i]:${#lo[i]}-${#ir[i]}}" && rawfile "${ir[i]}"` (`:1333-1337`). P4's seed is tagged `p` by its whole path. The C1 test's `docs/w.md` assertion passes at HEAD and fails on 39f64d62.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1328-1337`; `$S/ffc3-p4.log`, `$S/ffc3-red.log`

---

## Claim 28: Test and fixture comments: "T_MANAGED becomes IMPORT_MANAGED_DIR (by default a path that does not exist)"; "A rule's relative name stays in its directory; other memory files and uninstalled plugin versions are not loaded"; "An installed list python3 cannot read gives every cached version"; "A prompt under .CLAUDE also resolves against the directory holding it"; bl_setup/dev-cycle setup "the fixture's home only"

**Location:** `test/lib/build-loop-fixtures.bash:19-20`, `test/scripts/build-loop-check.bats:18-19`, `:702`, `:704`, `:729`, `test/scripts/dev-cycle.bats:18-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each comment's assertion passing at HEAD, with the setup lines doing what the comments say. It does not establish Claude Code's own loading of these files.

All suites pass (Claim 31). `unset CLAUDE_CONFIG_DIR` sits beside each setup comment (`build-loop-fixtures.bash:20`, `dev-cycle.bats:19`). The `/nonexistent/managed` default is at `build-loop-check.bats:25`.

**Evidence:** `test/scripts/build-loop-check.bats:25`, `:688-745`; `$S/ffc3-suites.log`

---

## Claim 29: Commit 1c820663: "Tests: five new in build-loop-check.bats, each red on main's lib ... Suites 125/79/20/2/2. 248 code lines against main ... Walks over this repo's worktrees take about 7 s each against 0.7 s"

**Location:** `git show 1c820663` (commit message)
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 1c820663's own five tests run against main's lib and against 1c820663's lib, the line count, the @test counts, and today's timing of 1c820663's lib. It does not establish timings at commit time, since the worktree contents change.

- With 1c820663's tests, all five fail on main's lib and pass on 1c820663's (`$S/ffc3-red2.log`).
- `git diff --shortstat main...1c820663 -- scripts test` gives `225 insertions(+), 23 deletions(-)`, which is 248 lines.
- build-loop-check went from 120 to 125 @tests. The other suites are unchanged (79/20/2/2).
- 1c820663's lib takes 6.05 to 8.16 s per walk today, and main's takes 0.59 to 0.84 s (`$S/ffc3-time2.log`, `$S/ffc3-time.log`).

**Evidence:** `$S/ffc3-red2.log`, `$S/ffc3-time.log`, `$S/ffc3-time2.log`

---

## Claim 30: Commit 39f64d62: "Walks over this repository's 8 worktrees: 7 s -> 3 to 3.5 s, same names ... Suites 125/79/20/2/2; 302 code lines against main."

**Location:** `git show 39f64d62` (commit message)
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers today's timing of 39f64d62's lib against 1c820663's, the line count, and the @test count. It does not establish the commit-time run or the suite pass at 39f64d62 (not rerun at that commit).

- 39f64d62's lib takes 2.88 to 3.68 s per walk, against 6.05 to 8.16 s for 1c820663's (`$S/ffc3-time2.log`).
- Both libs give 1846 IMPORTED lines (`names=1846`).
- `git diff --shortstat main...39f64d62` gives `273 insertions(+), 29 deletions(-)`, which is 302 lines.

**Evidence:** `$S/ffc3-time2.log`

---

## Claim 31: Commit 8f99fcaf: "Walks: 2 to 2.5 s over 8 worktrees, same 1177 names ... Suites 125/79/20/2/2; 333 code lines against main" and "a link to /dev/zero or a FIFO no longer hangs it"

**Location:** `git show 8f99fcaf` (commit message)
**Type:** Reference / Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers all five suites at HEAD, the line count, today's timings, the distinct repo-name count, and with_at over a FIFO and /dev/zero. It does not establish timings under other loads.

- The suites gave 125/79/20/2/2, all ok, with rc=0 each (`$S/ffc3-suites.log`, 03:34:56Z to 03:36:30Z).
- `git diff --numstat main...HEAD -- scripts test` sums to 303+30=333.
- The walks took 2.09 to 2.54 s (`$S/ffc3-time.log`).
- Both libs give 1177 distinct repo names (`$S/ffc3-names.log`).
- with_at returned at once over a FIFO and /dev/zero (`$S/ffc3-p1.log`).

**Evidence:** `$S/ffc3-suites.log`, `$S/ffc3-time.log`, `$S/ffc3-names.log`, `$S/ffc3-p1.log`

---

## Claim 32: Commit 8f99fcaf: "Each new assertion is red on 39f64d62's lib."

**Location:** `git show 8f99fcaf` (commit message)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the iteration-2 test diff (`git diff 39f64d62 8f99fcaf -- test`) run against 39f64d62's lib. It does not establish red-on-base for B4 or L1, which add no assertion.

HEAD's tests against 39f64d62's lib (`$S/ffc3-red.log`):

| Assertion added in iteration 2 | On 39f64d62's lib |
|---|---|
| `docs/w.md` (B3) | red: `not ok 3`, `want: docs/w.md: imported` |
| grep shim (B1) | red: `not ok 5`, `want: walk: failed` |
| `with_at` in the dev-cycle.bats sourcing inventory | red (with_at did not exist) |
| `root_starts` in the same inventory | green (39f64d62 already defines `root_starts()`) |

A precise version says "each new behavioural assertion".

**Evidence:** `$S/ffc3-red.log`; `git show 39f64d62:scripts/lib/dev-cycle-read.sh` (defines `root_starts()`); `test/scripts/dev-cycle.bats:1111`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:1237-1238`): outside_seeds' header still says C1 selects by "isstart, by its path below its innermost root". Since iteration 2 (B3), isstart reads the whole lower-cased path (`:1329`, `:1333`), and only the byte-skip test uses the inner path.

### Mostly Accurate
- **Claim 1** (`docs/working/plan-build-loop-handoff.md:306`): the plan says a nested root is always skipped, but the code lists one below ROOT_REAL by itself. The bullet also lacks iteration 2 (grep status, config link rule, whole-path isstart, 2 to 2.5 s).
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:754-758`): an unreadable directory fails every walk only in *other* worktrees. One in ROOT_REAL (not nested in another root) leaves the tree walk ok (executed).
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:759-761`): "0.6 s without" holds for the tree walk. The main walk takes 0.8 s without seeds.
- **Claim 11** (`scripts/lib/dev-cycle-read.sh:937-938`): "Every name starts at an @ byte" holds for file text but not for IMPORT_WHOLE input, which bypasses scan (`:994`).
- **Claim 21** (`scripts/lib/dev-cycle-read.sh:1241-1245`): the same-bytes skip drops a seed that is a prompt by its whole path while ROOT_REAL's copy is a plain start, which loses its prompt_bases names (executed: `sub/z.md` unimported with equal bytes, imported with one byte changed).
- **Claim 32** (8f99fcaf message): "Each new assertion is red on 39f64d62" is true of the behavioural assertions. The `root_starts` inventory entry is green there.

### Unverifiable
- **Claim 3** (`docs/working/plan-build-loop-handoff.md:307`): the 6,720-seed figure is from a discarded attempt. Today's count of @-bearing .md files in other roots is 10,839 (same order).

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill, with a Goal-Alignment Note.
- Answered: yes. All seven brief items are verdicted, behaviour claims are executed, and the report is saved at the dispatched path with `Commit: 8f99fcaf`.
- Out of scope: the review artifacts under docs/reviews/ (context only) and the 1c820663 "83 KB of // lines" aside (not measured).
- Escalate: Claim 21 is a behavioural residue, not only text. The C1 byte skip loses prompt_bases names when the whole-path prompt class differs from the inner-path class. It is narrow (a worktree nested under a non-root `.claude/skills/`) and within the lib's own superset model. The orchestrator should decide between a code fix (also compare the prompt class) and a named exception. Claim 19 is a one-line header fix. Claim 9's ROOT_REAL residue was also raised at i2 (that report's Claim 7) and remains.
- Decisions I made: I read "every name" in scan's comment as including IMPORT_WHOLE, because the same awk program serves both modes. I counted the dev-cycle.bats inventory entries as "assertions" for Claim 32. I measured timings at load average about 1.8 and called them consistent within that noise.
