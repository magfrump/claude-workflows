Commit: 55490d15

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u2b3b2a, branch feat/build-loop-u2b3b2a)
**Scope:** branch diff `git diff main...HEAD` (one commit, 55490d15): scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, and the commit message
**Checked:** 2026-10-09
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 25
**Summary:** 20 verified, 3 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log read (docs/reviews/hallucination-patterns.md). The logged patterns are all "a measured value quoted from an artifact set that does not hold it"; the commit's test counts and timing figures (Claims 19-21) were checked against that class and do not match it: each figure re-measured as stated.

Execution provenance. All executed probes ran from `/workspace/.claude/wt-build-loop-u2b3b2a` (suites) or a fresh `mktemp -d /tmp/u2b3b2a-factcheck-*` fixture (probes), each probe script `set -eu` and creating its own dir. Scripts and captured output are in `/tmp/claude-1000/-workspace/715dcdb7-5140-4bd1-a115-cbeff3508ce5/scratchpad/u2b3b2a-i1/fact-check/` (the brief allows writing only this report, so logs stay in the role scratch dir rather than docs/reviews/execution-logs/):
- `suites.sh` → `suites.rc`, `suites.ts` (2026-10-09T16:19:13Z start), `suite-*.log`; all five exit 0.
- `redmain.sh` → `redmain.log` (HEAD's tree with main's dev-cycle-read.sh); each filter exit 1.
- `probe1.sh` → `probe1.log` (16:19:37Z, exit 0): import_work and the second channel.
- `probe2.sh` → `probe2.log` (16:19:49Z, exit 0): dotnest old-awk vs new-bash.
- `probe3.sh`/`probe3b.sh` → `probe3.log`/`probe3b.log` (16:20:03Z/16:20:16Z, exit 0): whole-mode projection (newline, NBSP), memo fork count.
- `probe5.sh` → `probe5.log` (16:20:41Z, exit 0): FIFO, /proc/self/environ, unsearchable dir, mode-000, missing.
- `probe6.sh` → `probe6.log` (16:21:02Z, exit 0): both walks over this worktree, branch lib vs main lib.

---

## Claim 1: "prints a path below no reader root on its second channel: import_readers"

**Location:** `scripts/lib/dev-cycle-read.sh:679`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the parser printing `//`+absolute path for names below no root (absolute, `~/` and relative-to-absolute-dir names); does not establish anything about the outside *seeds* (U2b3b2b) or roots import_readers does not list.

The awk's `put` ends `if (nho == 0) show("/" out)` (`scripts/lib/dev-cycle-read.sh:889`). probe1 printed `//etc/x9`, `//123` and the home-joined `//tmp/.../home` for `@/etc/x9`, `@/123` and `@~/` in a fixture whose only root is the repo (probe1.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:857-890`, probe1.log

---

## Claim 2: "Both walks follow an import to a file below no reader root ... when it is a readable regular file, reading it from the file system ... through outside_targets; one that is missing, unreadable or not a regular file is skipped"

**Location:** `scripts/lib/dev-cycle-read.sh:720-724`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the walks' admission test (`-f` and `-r` at queue time) and that FIFO, mode-000, missing, unsearchable-directory and /proc names leave both walks `ok`; does not establish the "since a session cannot load it either" rationale (Claim 3). A file that turns unreadable or vanishes *between* the test and the read fails the walk rather than being skipped.

Tree walk: `[[ "$p" != //* ]] || { p="${p#/}"; [[ -f "$p" && -r "$p" && "$seen" != *$'\n'"$p"$'\n'* ]] && seen+="$p"$'\n' && queue+=("$p"); continue; }` (`:1245`). Main walk: the same test, queueing to `tq` (`:1353`). The read goes through `file_targets` → `outside_targets` (`:1125`, `:1115-1121`). probe5 put `@<o>/fifo.md @/proc/self/environ @<o>/nox/f.md @<o>/locked.md @<o>/missing.md` in AGENTS.md: `tree walk ok`, `main walk ok`, no stall (probe5.log). Calling `outside_targets` directly on the mode-000, missing and unsearchable-dir names returned `rc=1` each (probe5.log), so the read-time failure path is fail-closed: `r="$(realpath -e -- "$1")" || return 1` and the `capped_read < "$1" | ...` pipeline under the walk's pipefail (`:1117-1118`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1115-1125`, `:1243-1248`, `:1350-1359`, probe5.log, test "an outside name whose real path lies in the repo ..." (suite-build-loop-check.log)

---

## Claim 3: "since a session cannot load it either"

**Location:** `scripts/lib/dev-cycle-read.sh:723-724`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing on Claude Code's side; for same-uid sessions an unreadable or missing file is plainly unloadable, but whether Claude Code reads an `@` import that names a FIFO or other non-regular file (or a symlinked /proc entry) is not established.

The claim is about Claude Code's loader, not this repo's code (paraphrased — no quote available because the claim's subject is an external binary's behaviour, not code in scope). Verifying it needs a Claude Code session importing a FIFO / character device and observing whether it blocks, reads, or skips.

**Evidence:** `scripts/lib/dev-cycle-read.sh:720-725`

---

## Claim 4: "each a repo-relative directory joined under every reader root or, led by /, an absolute one joined as it is (a file below no root): one repo-relative path per line, or // and the absolute path for a name below no root (the second channel), case kept, each once"

**Location:** `scripts/lib/dev-cycle-read.sh:768-772`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the absolute-dir join and both output channels; does not establish that every walk caller passes only repo-relative extra dirs (prompt_bases does: `:663-672`).

`for (i = 0; i <= nd; i++) if (substr(dirs[i], 1, 1) == "/") put(dirs[i] "/" c); else for (r = 1; r <= nr; r++) put(roots[r] "/" dirs[i] "/" c)` (`:855`). The new parser test asserts `//opt/d/a.md` for `@a.md` with dir `/opt/d` and the absence of `a.md`/`docs/a.md`, and passes (suite-build-loop-check.log); it fails on main's lib (redmain.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:855`, `test/scripts/build-loop-check.bats:631-641`, suite-build-loop-check.log, redmain.log

---

## Claim 5: "With IMPORT_WHOLE set, each line on stdin is one name, taken whole (no prefixes, no blanks)"

**Location:** `scripts/lib/dev-cycle-read.sh:772-774`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the awk whole arm and the sed no-op (NBSP, spaces kept); does not establish that a caller's input line is the whole path (see Claim 14: a path holding a newline is two lines), and a line with invalid UTF-8 also yields its decoded copy as a second name (`:1097-1100`).

`[[ -z "${IMPORT_WHOLE:-}" ]] || s=(-e '')` (`:1088`) and `if (whole) { emit($0, 1); next }` (`:960`). The test prints `whole docs/a b.md` and `whole //etc/x y` (passes); probe3b's link to `docs/x<NBSP>y.md` reads as that path and its import `r.md` resolves under docs/ (`[docs/x y.md]: imported`, `[docs/r.md]: imported`, probe3b.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1088`, `:954`, `:960`, probe3b.log

---

## Claim 6: "It also reads ROOT_REAL and import_readers' IMPORT_ROOTS, IMPORT_HOMES and IMPORT_DOTNEST, calling it (which sets those and the IMPORT_HOME* globals in the caller's shell unless called in a subshell; its refusal fails this call)"

**Location:** `scripts/lib/dev-cycle-read.sh:775-777`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the unconditional `import_readers || return 1`, the memo hit inside a walk's `$(...)` subshells, and the refusal of ROOT_REAL `/` and empty; does not establish that a direct piped call forks only once (each `printf | import_targets` is itself a subshell, so each forks `git worktree list`: 2 forks for 2 piped calls in probe3b).

`import_readers || return 1` (`:1085`). A `git` PATH shim counting `worktree list` calls saw 1 per walk for both walks (the walk's own `import_readers` at `:1219`/`:1271`, then memo hits in every `$(file_targets ...)` subshell, since `import_home`'s key `x${HOME+set}:${HOME-}` is unchanged), and 2 for two piped direct calls (probe3b.log). The test's `for ROOT_REAL in / ""` loop gives `rc=1` twice (passes). No caller relies on the old ROOT_REAL-only fallback (paraphrased — no quote available because the claim covers absence: `rg import_targets` hits only the lib, test/scripts/build-loop-check.bats and test/scripts/dev-cycle.bats, and all their suites pass).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1080-1108`, `:983-989`, `:1027-1033`, probe3b.log, suite-dev-cycle.log

---

## Claim 7: "Each candidate is trimmed of spaces, made absolute (ROOT/DIR/name for each reader root, $1 and each further directory, unless it starts with /)"

**Location:** `scripts/lib/dev-cycle-read.sh:800-802`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the superset statement's resolution sentence; does not establish anything about the ~/ arm, which the paragraph states separately.

The branch added an absolute-directory case (`if (substr(dirs[i], 1, 1) == "/") put(dirs[i] "/" c)`, `:855`), where a relative name becomes DIR/name with no ROOT; the superset statement (the "one statement of it", `:786`) still says ROOT/DIR/name for each root. The import_targets header above it (`:768-770`) does state the new case. Precise version: "(ROOT/DIR/name for each reader root and each repo-relative directory, DIR/name for an absolute one, unless it starts with /)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:786-802`, `:855`

---

## Claim 8: "a name below no reader root (import_readers: ...) is printed on the second channel, and any other relative to each root holding it but an outer one whose path down to a nested root holding it has a dot component"

**Location:** `scripts/lib/dev-cycle-read.sh:804-809`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers channel selection by `nho` and the dotnest omission; does not establish dotnest's equivalence to the old table (Claim 13).

`nho = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i])) h[++nho] = i` then the dotnest loop, then `if (nho == 0) show("/" out)` (`:882-889`). The parser test asserts `n.md` and not `.claude/wt-b/n.md` for a dot-nested worktree (passes).

**Evidence:** `scripts/lib/dev-cycle-read.sh:873-890`, `test/scripts/build-loop-check.bats:637-640`

---

## Claim 9: "a start file only another reader root's checkout holds (... the walks read the gate's own checkout only; U2b3b2)"

**Location:** `scripts/lib/dev-cycle-read.sh:817-819`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the unit label only; does not establish whether the exception itself is still open (it is: outside seeds are out of scope here).

This branch relabelled the same exception elsewhere: `nor at a start file only another registered checkout holds (U2b3b2b).` (`:728`), and the shared brief names "other roots' untracked starts" as U2b3b2b. The superset statement's copy still says `U2b3b2`, the pre-split unit (split in b7728cfd, before this commit). Update to U2b3b2b.

**Evidence:** `scripts/lib/dev-cycle-read.sh:719-728`, `:814-819`

---

## Claim 10: "It returns 1 when sed, python3, awk or import_readers fails (an empty ROOT_REAL, or refused settings, among its reasons), when a ~/ name appears and the home is not absolute, or when ..."

**Location:** `scripts/lib/dev-cycle-read.sh:826-829`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the import_readers-failure and empty/`/` ROOT_REAL returns; the remaining reasons (sed, python3, work bounds) are unchanged by this branch and were not re-probed.

`import_readers || return 1` (`:1085`); `[[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1` (`:1037`); `[[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1` (`:1054`). The test's two `rc=1` lines pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1027-1061`, `:1085`, suite-build-loop-check.log

---

## Claim 11: "an absolute directory (a file below no root) is the one directory it names"

**Location:** `scripts/lib/dev-cycle-read.sh:852-855`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers emit's relative arm; does not establish ~/ or absolute candidates (separate arms, `:846-851`).

Quoted at `:855` (Claim 4). The outside-chain test (`o1: @sub/o2.md`, `@../o1.md`, `@../../repo/docs/y.md` inside outside files) passes for both walks, `docs/y.md: imported` (suite-build-loop-check.log), and is red on main (redmain.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:855`, `test/scripts/build-loop-check.bats:643-656`

---

## Claim 12: "Below no root: the second channel, / and the absolute path (so // leads it, and no repo name or work trailer can be read as one)"

**Location:** `scripts/lib/dev-cycle-read.sh:887-889`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers import_work's parse against outputs ending in a digit-ended outside name, an outside name `/`+digits, an empty output and a missing trailer, plus `put`'s `out == ""` guard; does not establish anything for callers that strip the trailer some other way (there are none: `rg import_work`).

import_work: `iw_w="${iw_o##*/}"` then `[[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1` (`:1131-1132`). probe1: `docs/a.md\n//etc/x123\n/42` → ok, w=42; `//123`, `docs/a.md\n//123`, `""`, `//etc/x123` (no trailer) → rc=1 each; `//123\n/9` → ok, out `//123`, w=9 (probe1.log). `@/` and `@/..` print nothing: `if (index(out, "\n") || out == "") return` (`:872`), so `/` alone is never emitted as a would-be trailer-shaped name (probe1.log P3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:872`, `:889`, `:1130-1135`, probe1.log

---

## Claim 13: "IT_DOTNEST: 'I J' lines, root J nested in root I below a dot component" / "The parser's dotnest pairs, by 1-based index into IMPORT_ROOTS ... Built once here, not in every parser process"

**Location:** `scripts/lib/dev-cycle-read.sh:951-952`, `:1074-1078`
**Type:** Invariant / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers index alignment (rs_ro order = IMPORT_ROOTS = awk roots[1..nr]) and equivalence of the bash test to main's awk test over 15 roots (225 pairs: dot, `..y`, `b.`, shared-prefix `/ab` vs `/a`, equal length); does not establish equivalence for a root `/` (now refused before the table) or for roots containing glob metacharacters beyond the one `*` probe.

`printf -v IMPORT_ROOTS '%s\n' "${rs_ro[@]}"` (`:1072`) and `IMPORT_DOTNEST+="$((i + 1)) $((n + 1))"` over `"${!rs_ro[@]}"` (`:1076-1077`), read by `dotnest[ab[1], ab[2]] = 1` (`:952`) against `split(ENVIRON["IT_ROOTS"], roots, "\n")` (`:949`). probe2: old awk and new bash both give the same 13 pairs (`SAME`), and `[[ "$t" != "$p"* ]]` with `p='/a*/'` is literal (probe2.log). The table is built after the memo check (`:1033`), so once per reader set.

**Evidence:** `scripts/lib/dev-cycle-read.sh:949-952`, `:1033-1034`, `:1072-1078`, probe2.log

---

## Claim 14: "when its real path differs (a symlink on the way), that path is also projected whole (IMPORT_WHOLE), so a link into a reader root reads as an import of the repo path and one to another outside file as that file"

**Location:** `scripts/lib/dev-cycle-read.sh:1111-1114`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers real paths in the repo, outside, under a symlinked directory, and holding NBSP/spaces; does not hold for a real path holding a newline, and does not establish anything about a real path that changes between `realpath` and the read.

`b="$(printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /)"` (`:1119`) prints `$r` as one line only when `$r` has no newline. probe3b linked `<o>/nl.md` to the repo file `docs/a<LF>b.md` (which imports `q.md`): the tree walk reported `[docs/a\nb.md]: -` and `[docs/q.md]: -`, walk ok (probe3b.log), because the two lines project as `docs/a` and `//b.md`. The main walk fails closed on the same repo (`main walk failed`, since main's tree holds a newline name). This is no regression (main's lib dropped every outside name), and the parser already drops newline names on the direct path (`:870-872`), but the comment's "reads as an import of the repo path" is unqualified. Precise version: add "(a real path holding a newline is not projected)". NBSP and other blanks are kept: `[docs/x y.md]: imported`, `[docs/r.md]: imported` (probe3b.log). NUL cannot occur in a path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1115-1121`, `:1243-1248`, probe3b.log

---

## Claim 15: "The two work trailers are summed into one."

**Location:** `scripts/lib/dev-cycle-read.sh:1114`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the trailer arithmetic and that the walk's own checks still bound the total; does not establish a per-file bound of one IMPORT_WORK_LEFT: each of the two calls inherits the same IMPORT_WORK_LEFT/IMPORT_LEFT, so one outside file may spend up to twice the remaining budget before the walk's `import_work out work` and `used` checks fail it.

`a="$(capped_read < "$1" | import_targets "${d:-/}")" && import_work a w || return 1`, the same for `b`, then `printf '%s\n' ${a:+"$a"} ${b:+"$b"} "/$w"` (`:1118-1120`); `w` starts at 0 and the walk then strips exactly one `/N` (`:1237-1238`, `:1314-1315`) and checks `(( (iw_t += iw_w) <= IMPORT_WORK_MAX ))` (`:1134`) and `(( (used += ${#out}) <= IMPORT_OUT_MAX ))` (`:1240`, `:1347`). The prefix assignments `IMPORT_LEFT=... IMPORT_WORK_LEFT=... file_targets` are visible inside the function and exported to its awk children (paraphrased — no quote available because this is bash's temporary-environment rule for function calls, confirmed by the trailer being present: the outside tests would fail import_work otherwise).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1115-1121`, `:1130-1135`, `:1237-1240`, `:1314-1315`, `:1347`

---

## Claim 16: "file_targets FILE DIR [DIRS...]: import_targets over FILE as the file system holds it, for both walks: a repo path (DIR and DIRS as import_targets takes them), or an absolute one through outside_targets."

**Location:** `scripts/lib/dev-cycle-read.sh:1122-1125`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the dispatch and its two callers; does not establish that main's blob arm uses it (it does not, by design: `:1316`).

`file_targets() { if [[ "$1" == /* ]]; then outside_targets "$1"; else capped_read < "$1" | import_targets "${@:2}"; fi; }` (`:1125`); called at `:1237` (tree walk) and `:1314` (main walk's checkout arm).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1125`, `:1237`, `:1314`

---

## Claim 17: "a repo-relative name never starts with /, and a second-channel name starts with //"

**Location:** `scripts/lib/dev-cycle-read.sh:1126-1129`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the parser's two print sites; does not establish anything for a root that is a proper prefix-with-slash of `out` equal to `out` itself (excluded by `length(out) > length(pre[i])`, `:882`).

`show(substr(out, length(pre[h[i]]) + 1))` drops `root/` so no leading slash; `show("/" out)` with `out` starting `/` (`:885`, `:889`). Confirmed by probe1's outputs (probe1.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:882-889`, probe1.log

---

## Claim 18: "Below no root: read from the file system in phase 2, as the checkout is." (and the brief's: main_checkout never applied to an absolute path; an absolute item cannot hit a main entry)

**Location:** `scripts/lib/dev-cycle-read.sh:1352-1353`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers routing of `//` names to `tq` before `main_checkout` and the `case "${ent[$f]-checkout}"` arm choice; does not establish the checkout-side refusals (symlinked/unsearchable ancestors) for outside files, which are deliberately not applied.

`[[ "$p" != //* ]] || { p="${p#/}"; [[ -z "${seen[$p]+set}" && -f "$p" && -r "$p" ]] && seen[$p]=1 && tq+=("$p"); continue; }` precedes `main_checkout ent pok "$p"` (`:1353-1355`). `ent` keys come from `git ls-tree -r -z --full-tree` records matched by `\t(.+)$` (`:1275-1280`), and git never stores a path with a leading slash (paraphrased — no quote available because this is git's tree-entry rule, not code in scope), so `${ent[/abs]-checkout}` is always `checkout` and reaches `file_targets` → `outside_targets` (`:1314`). Repo names an outside file yields then take the normal arms: main's blob when main has them (`:1358`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1275-1280`, `:1309-1315`, `:1350-1359`

---

## Claim 19: "build-loop-check 119, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2"

**Location:** commit 55490d15 message, Tests line
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers counts and pass state at 55490d15 in this sandbox; does not establish the other suites in test/ (not claimed).

Command: `LC_ALL=C LANG=C TMPDIR=$T timeout 900 bats <file>` for each file, cwd the worktree, start 2026-10-09T16:19:13Z: all rc=0; 119/20/79/2/2 `ok`, 0 `not ok` (suites.rc, suite-*.log). `bats --count` gives the same counts.

**Evidence:** suites.sh, suites.rc, suites.ts, suite-build-loop-check.log, suite-build-loop-read.log, suite-dev-cycle.log, suite-fixture-git-env.log, suite-fixture-hermeticity.log

---

## Claim 20: "three new ... each red on main"

**Location:** commit 55490d15 message, Tests line
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three new tests run against main's dev-cycle-read.sh with HEAD's test files; does not establish that each fails for the intended reason in every assertion (the outputs show the missing outside names).

`redmain.sh`: `git archive 55490d15` into a mktemp dir, `git show main:scripts/lib/dev-cycle-read.sh` over the lib, then `bats -f <name>` for each: `not ok 1` and `rc=1` for all three (redmain.log, run 2026-10-09 ~16:19Z).

**Evidence:** redmain.sh, redmain.log, redmain.ts

---

## Claim 21: "Over this worktree both walks give main's 64 names in about the same time (0.7-0.8 s); no walked file here holds an outside name."

**Location:** commit 55490d15 message, Tests line
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers name count, set equality with main's lib, zero `//` names, and same-time; the absolute seconds are load-dependent (measured tree 0.58 s, main 0.76 s on the branch lib vs 0.53 s / 0.75 s on main's).

probe6 (cwd the worktree, 16:21:02Z): `tree walk=ok names=64 outside=0 secs=0.58`, `main walk=ok names=64 outside=0 secs=0.76`, main's lib 0.53/0.75, and `tree: same names as main lib`, `main: same names as main lib` (probe6.log).

**Evidence:** probe6.sh, probe6.log

---

## Claim 22: "a ROOT_REAL of / now fails a direct call too, as it always failed the walks"

**Location:** commit 55490d15 message, H5 bullet
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers direct calls and the walks; does not establish a historical "always" before main's current import_readers (main's copy has the refusal; earlier history not traced).

Main's import_readers already refused it (`[[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1`, main:scripts/lib/dev-cycle-read.sh:1037), while main's import_targets fell back to `roots="${ROOT_REAL:-}"` (main:...:1063) and main's test asserted `rc=0` for ROOT_REAL=/. The new test asserts `rc=1` for `/` and `""` and passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1054`, `:1085`, `git show main:scripts/lib/dev-cycle-read.sh` lines 1037, 1063, `test/scripts/build-loop-check.bats:635`

---

## Claim 23: "Of nine mutants tried, one survives: import_targets' `import_readers || return 1` made `|| true` (equivalent: an empty root list makes the parser exit 2)."

**Location:** commit 55490d15 message, Notes
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the equivalence argument; the mutant run itself (nine mutants, one survivor) was not re-run.

Every refusal path after `IMPORT_READERS_DONE="$IMPORT_READERS_KEY"; IMPORT_ROOTS=""; ...` (`:1034`) leaves IMPORT_ROOTS empty, and a memoized refusal keeps it empty (`:1033`), so the awk's `if (nr == 0 || roots[1] == "") exit 2` (`:949`) fails the call. But `import_home || return 1` (`:1029`) returns *before* that reset, so under the mutant an import_home failure after an earlier successful import_readers would run the parser with the previous, stale IMPORT_ROOTS. import_home fails only when `realpath -m` fails on an absolute HOME (`:987`), so the mutant is equivalent in practice, not strictly. Precise version: "equivalent but for an import_home failure, which leaves the prior root list".

**Evidence:** `scripts/lib/dev-cycle-read.sh:983-989`, `:1027-1037`, `:949`

---

## Claim 24: "the second channel is always on (every caller is a walk or a test)"

**Location:** commit 55490d15 message, Notes
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers callers in scripts/ and test/; does not establish callers outside this repo.

Callers (paraphrased — no quote available because the claim covers absence: `rg -l import_targets scripts test` lists only scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats and test/scripts/dev-cycle.bats; in the lib the callers are outside_targets, file_targets and main_imports' blob arm, `:1118-1119`, `:1125`, `:1316`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1115-1125`, `:1316`

---

## Claim 25: "H2: import_readers builds the parser's dotnest pairs once per reader set (IMPORT_DOTNEST), rather than every parser process."

**Location:** commit 55490d15 message, H2 bullet
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers placement after the memo check and the removal from the awk BEGIN; does not establish a measured speedup.

The awk BEGIN now only reads `ENVIRON["IT_DOTNEST"]` (`:952`); the O(roots²) loop runs in import_readers after `if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then ...; return; fi` (`:1033`, `:1076-1078`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:949-952`, `:1033`, `:1076-1078`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:819`): the superset statement's known-exception still labels other roots' untracked starts `U2b3b2`; the branch relabelled the same item `U2b3b2b` at `:728`.

### Mostly Accurate
- **Claim 7** (`scripts/lib/dev-cycle-read.sh:801-802`): the superset statement's "ROOT/DIR/name for each reader root" omits the new absolute-directory join (DIR/name, no root).
- **Claim 14** (`scripts/lib/dev-cycle-read.sh:1111-1113`): a real path holding a newline is split into two lines and not projected, so the tree walk misses that repo file and its imports (main walk fails closed); qualify the comment.
- **Claim 23** (commit 55490d15 Notes): the `|| true` mutant is equivalent except when import_home fails, which returns before IMPORT_ROOTS is cleared and leaves a stale root list.

### Unverifiable
- **Claim 3** (`scripts/lib/dev-cycle-read.sh:723-724`): "a session cannot load it either" for non-regular files (FIFO, devices) needs a Claude Code probe.

---

## Goal-Alignment Note

**Success criterion (restated verbatim):** "your report saved at the path your own tail names, structured per your skill file, with a `Commit: 55490d15` line at the top."

**Answered:** Yes. Saved at /workspace/.claude/wt-build-loop-u2b3b2a/docs/reviews/code-fact-check-report-build-loop-u2b3b2a.md with `Commit: 55490d15` first. All ten brief claims were checked: 1 (Claims 12, 17), 2 (Claim 15), 3 (Claims 5, 14), 4 (Claim 18), 5 (Claims 2, 3), 6 (Claim 6), 7 (Claim 13), 8 (Claims 10, 12, 22), 9 (Claims 7, 9, 19-25), and 10 in part (probe5: /proc/self/environ, FIFO, unsearchable and mode-000 names leave both walks ok with no stall; nothing outside the walk's name list is printed).

**Out of scope:** Outside seeds (U2b3b2b); a security verdict on parsing arbitrary readable files (security-reviewer owns it); whether skip-on-non-regular is the right policy (a design question, not a claim).

**Escalate:** Claim 14's newline case is the one false-negative shape found. A repo file whose name holds a newline, reached only through an outside symlink, is missing from the tree walk (--check-fix). The floor's main walk fails closed on the same repo. It is not a regression, but the security/architecture critics should judge it against the fail-closed principle. A cheap fix is to fail (or skip) when `$r` holds a newline. Also, for brief item 5: a file that turns unreadable or disappears between the queue-time `-f/-r` test and the read *fails* the walk (outside_targets rc=1), not a skip. That is fail-closed and consistent with the principle, but the `:720-724` comment says only "skipped".

**Questions/Decisions:** none.
