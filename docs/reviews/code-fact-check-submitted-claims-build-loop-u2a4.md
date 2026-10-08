Commit: 2b6f2f91

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-u2a4-final-snap (detached snapshot of feat/build-loop-u2a4 at 2b6f2f91)
**Scope:** Stage 2.5 submitted claims only (9 endorsements from the final security-reviewer and performance-reviewer passes at 2b6f2f91); no harvested claims. Numbering continues from 60 as the brief asks. Main for comparisons is 7afdb8d2.
**Checked:** 2026-10-08
**Total claims checked:** 9
**Summary:** 8 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance for every executed claim: the scripts and captured output are in the scratch dir `/tmp/u2a4s25-ml7c/` (logs under `logs/`, each with a `.ts` file holding the start time, the exit code and the end time). The brief allows writing only this report in the worktree, so the logs were not copied to `docs/reviews/execution-logs/`. Libraries probed: `head-lib.sh` = `git show 2b6f2f91:scripts/lib/dev-cycle-read.sh` (byte-identical to the snapshot's file, checked with `cmp`), `main-lib.sh` = `git show 7afdb8d2:scripts/lib/dev-cycle-read.sh`, and `mainsnap/scripts/` = `git archive 7afdb8d2 scripts`, so main's `dev-cycle.sh` sources main's lib. `env.sh` sets the same hermetic git environment as `test/lib/build-loop-fixtures.bash` (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, HOME under the scratch dir, `LC_ALL=C`), and its `floors` and `imps` helpers are copies of `test/scripts/build-loop-check.bats:16-31`. Every fixture repo is built with `mktemp -d` under the scratch dir. Each command ran with cwd `/tmp/u2a4s25-ml7c` under `timeout`. Host: 16 cores, WSL2, other sessions active; timing claims are verdicted on shape (ratios inside one process), not on exact seconds.

Hallucination pattern log: `docs/reviews/hallucination-patterns.md` was read; none of these claims name a symbol that does not exist, and none match a logged pattern.

---

## Submitted Claims

## Claim 60: "At 2b6f2f91, the fixtures for iteration-1 security F1 (quoted mention @"docs/q.md" in a command), F2 (skill body @docs/k.md in .claude/skills/k/SKILL.md) and F3 (nested and doubled .claude/) are refused by floor with the imported reason and imported by the tree walk (--check-fix skips)."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:495-503`, `:664-686`, `:484`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture of `test/scripts/build-loop-check.bats:1182-1197` (eight target paths, committed on main, the targets present as files) through floor, both walks and `dev-cycle.sh --check-fix` at 2b6f2f91, with main's lib as a control; does not establish the same fixtures with a prompt directory stored as a symlink, untracked or checkout-only prompts, or whether Claude Code itself loads these names.

Every fixture target is refused by floor, imported by both walks, and skipped by --check-fix. The "imported reason" part holds for six of the eight targets. The two targets that lie under a `.claude/` directory are refused by an earlier floor arm with a different reason:

```
a/.claude/commands/b/docs/n.md: an instruction or prompt file, which sessions load from the checkout
c/.claude/d.md: a dotfile or a path under a dot-directory
```

`c/.claude/d.md` is the target that the doubled-`.claude/` fix produces. `prompt_bases` keeps `c/.claude` as a base (`scripts/lib/dev-cycle-read.sh:499-501`, `rest="${rest#*/.claude}"; n=$(( ${#2} - ${#rest} - 8 ))`), but floor's `truthrule` refuses it for its dot component before it reaches `truthwalk`. So, for that fix, the floor protection comes from the dot rule, not from the walk. The other six targets (`docs/q.md`, `docs/a b.md`, `docs/k.md`, `docs/n.md`, `a/docs/n.md`, `c/d.md`) carry `an instruction file on the default branch imports it with @ (directly or through another import)`.

All eight targets print `imported` from the tree walk and from the main walk at HEAD. With main's lib, the tree walk imports none of them (control). In --check-fix, the walk-based skip message appears only for `docs/q.md`, `docs/k.md` and `docs/n.md`. `docs/a b.md` is skipped by pathform (`not an allowed path form`), and the other four targets are skipped by the docs-only rule, so the walk's verdict on them is never consulted. Main's --check-fix answers `ok` for `docs/q.md`, `docs/k.md` and `docs/n.md`. A non-imported `docs/plain.md` control passes floor (`-`) and --check-fix (`ok`).

The quoted-run reader is `if (substr(line, i + 1, 1) == "\"") names(line, i + 2, L, 1)` (`scripts/lib/dev-cycle-read.sh:674`), where `if (q) { if (ch == "\"") break }` (`:681`) ends the run at the closing quote. Skills reach the start rule through `PROMPT_DIR='(^|/)\.claude/(commands|agents|output-styles|skills)/'` (`:484`).

Command: `timeout 300 bash c60.sh`, exit 0, 2026-10-08T07:32:57Z (`logs/c60.ts`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:484`, `scripts/lib/dev-cycle-read.sh:495-503`, `scripts/lib/dev-cycle-read.sh:664-686`, `scripts/lib/dev-cycle-read.sh:990-999`, `scripts/lib/dev-cycle-read.sh:1039-1061`, `/tmp/u2a4s25-ml7c/c60.sh`, `/tmp/u2a4s25-ml7c/logs/c60.log`, `/tmp/u2a4s25-ml7c/logs/c60.ts`
**Legibility-target:** for-author (narrow the wording to "refused by floor; the six targets outside a `.claude/` directory carry the imported reason, and the two inside one are refused as instr and dot").

---

## Claim 61: "In floor, every path no earlier arm refuses reaches `truthwalk main`, including a brief's own working or review file (the docs/working/* and docs/reviews/* arms fall through when ownfile holds), and the function's only `return 1` is the final else."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1039-1061`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's whole body (`:1039-1061`) and ownfile (`:1018-1023`), plus execution of own and non-own working and review files (statuses A and M) against a main that imports some of them; does not establish what U2c's caller does with the answer, or truthrule's own arms (claim 63 covers those through check_fix).

floor is one `if`/`elif` chain, and its last two arms are:

```bash
# scripts/lib/dev-cycle-read.sh:1055-1060
  elif [[ "$lp" == docs/working/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY="a working file that is not this brief's own (they carry its full stem)"
  elif [[ "$lp" == docs/reviews/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY="a review record (only an added review named STEM.md or NAME-STEM.md lands)"
  elif truthwalk main "$lp"; then
    if [[ "$TRUTH_WHY" == walk ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports"
    else FLOOR_WHY="an instruction file on the default branch imports it with @ (directly or through another import)"; fi
  else return 1; fi
```

When ownfile holds, `! ownfile` is false, so the compound test fails and control falls to the next `elif`. A `docs/working/` path cannot match the `docs/reviews/*` arm, so both own-file kinds reach `truthwalk main`. A scan of floor's body for `return` finds two lines: `lp="$(lower "$1")" || { FLOOR_WHY="the path could not be lower-cased"; return 0; }` (`:1043`) and `else return 1; fi` (`:1060`). The `else return 1` is the only `return 1` (log, first section).

Executed with stem `2026-10-01-x` and a main whose instruction file imports `docs/working/plan-2026-10-01-x.md`, `docs/reviews/2026-10-01-x.md` and `docs/reviews/sec-2026-10-01-x.md`. At status A, all three own files get the imported reason. The own but non-imported `docs/working/research-2026-10-01-x.md` and `docs/reviews/other-2026-10-01-x.md` answer `-`, because truthwalk misses and the chain reaches the else. The non-own `docs/working/plan-2026-10-01-y.md` gets the working-file reason. At status M, `docs/reviews/2026-10-01-x.md` is no longer own and gets the review-record reason, while the own working file still gets the imported reason.

Command: `timeout 300 bash c6162.sh`, exit 0, 2026-10-08 (`logs/c6162.ts`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1018-1023`, `scripts/lib/dev-cycle-read.sh:1039-1061`, `/tmp/u2a4s25-ml7c/c6162.sh`, `/tmp/u2a4s25-ml7c/logs/c6162.log`, `/tmp/u2a4s25-ml7c/logs/c6162.ts`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 62: "truthwalk returns 0 with TRUTH_WHY=walk when its walk fails or the walk name is unknown, and returns 1 with TRUTH_WHY empty only after a successful walk whose membership test misses."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1007-1011`, `:969-978`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both function bodies and execution of a hit, a mixed-case hit, a miss, an unknown and an empty walk name, a failed tree walk, a failed main walk and a failing `tr` after a successful walk, all in the caller's shell; does not establish behavior in a subshell (cache and TRUTH_WHY lost), and a reader should note that a failure after a successful walk (a failed lower in isimported) answers 0 with TRUTH_WHY=imported, not walk.

```bash
# scripts/lib/dev-cycle-read.sh:1007-1011
truthwalk() {
  TRUTH_WHY=walk
  case "$1" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac
  TRUTH_WHY=imported; isimported "$1" "$2" || { TRUTH_WHY=""; return 1; }
}
```

The only `return 1` follows a successful walk and a non-zero isimported. isimported answers non-zero only through its membership tests, `[[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]` and `[[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]` (`:974-975`). Its other exits are `lower ... || return 0`, `main_imports || return 0`, `imported_names || return 0` and `*) return 0` (`:972-976`), which all answer 0. Executed (`logs/c6162.log`):

```
w=[main] p=docs/plain.md rc=1 why=[]
w=[foo] p=docs/imp.md rc=0 why=[walk]
w=[] p=docs/plain.md rc=0 why=[walk]
tree rc=0 why=[walk]        (a start whose name holds a newline)
main rc=0 why=[walk]        (no default branch by name)
main rc=0 why=[imported]    (failing tr after a successful walk)
```

Hits (`docs/imp.md`, `docs/IMP.md`) answer `rc=0 why=[imported]` for both walks. A pre-set `TRUTH_WHY=pre` is overwritten in every case, so the empty value on a miss is written, not inherited.

Command: `timeout 300 bash c6162.sh`, exit 0, 2026-10-08 (`logs/c6162.ts`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:969-978`, `scripts/lib/dev-cycle-read.sh:1007-1011`, `/tmp/u2a4s25-ml7c/c6162.sh`, `/tmp/u2a4s25-ml7c/logs/c6162.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 63: "check_fix's refactor refuses every path main's check_fix refused (byte-identical --check-fix output over all tracked paths; a failed lower now refuses where main had no check)."

**Submitted by:** security-reviewer
**Location:** `scripts/dev-cycle.sh:171-183`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identical output over all 3,104 paths tracked at 2b6f2f91, a 37-path synthetic differential (case, dot, instruction, writable, record, working, review, settings and constraints paths, plus imports from an instruction file, a command and a skill), a failed tree walk and a failing `tr`, together with a static mapping of each of main's conditions; does not establish the walk-arm messages on this repo's own paths (no tracked path reaches a walk arm in either version), or behavior on a case-insensitive filesystem.

Over the tracked paths, both outputs have 3,104 lines and `cmp` reports them identical (`BYTE-IDENTICAL` in `logs/c63.log`). The distribution is 3,072 docs-only skips, 9 path-form skips, 8 cycle-file skips and 15 `ok`. No tracked path reaches either walk arm, so the walk arms rest on the synthetic run and the static mapping.

Static mapping, from main's arms (`git show 7afdb8d2:scripts/dev-cycle.sh`, `check_fix`) to HEAD's (`scripts/dev-cycle.sh:177-182`):

- Main's `writable "$a" || writable "$lp"` matches only lower-case names (`SLUG='[abcdefghijklmnopqrstuvwxyz0123456789-]+'`, `scripts/lib/dev-cycle-read.sh:195`, and the literal patterns at `:199-200`), so in practice `a == lp`. No writable path is an instruction name or contains a dot component, so truthrule answers `cycle` and the message is the same.
- Main's `human-author|decisions` maps to `record`, `dev-cycle.md` to `settings`, `constraints.md` to `user`, `"$a" == */.*` to `dot` (whose `"/$1" == */.*` is a superset), and `$low =~ $INSTRUCTION_FILE` to `instr`. Each of these sets TRUTH_WHY, which makes HEAD's `[[ -n "$TRUTH_WHY" || ...` true, so it prints the same docs-only skip.
- Main's `! imported_names` and `isimported tree` become `truthwalk tree` with the same two messages.

In the synthetic differential, the only lines that differ are `docs/cmd.md` and `docs/sk.md` (imported only by a `.claude/commands` file and a skill). Main answers `ok` for both, and HEAD skips both as imported. No path is skipped by main and `ok` at HEAD. With a start whose name holds a newline, both versions print the walk-failed skip. With a failing `tr`, HEAD prints `skip docs/plain.md: the path could not be lower-cased; file it instead` and exits 0. Main prints nothing and exits 1, because its unchecked `lp="$(... | tr ...)"` dies under the script's error handling. So "where main had no check" is accurate: main aborted the run rather than giving a per-path refusal.

Commands: `timeout 700 bash c63.sh`, exit 0, 2026-10-08T07:34:05Z to 07:34:22Z (cwd for the two runs `/workspace/.claude/wt-u2a4-final-snap`, read-only); `timeout 600 bash c63b.sh`, exit 0 (`logs/c63b.ts`).

**Evidence:** `scripts/dev-cycle.sh:171-183`, `scripts/lib/dev-cycle-read.sh:195-201`, `scripts/lib/dev-cycle-read.sh:990-999`, `/tmp/u2a4s25-ml7c/c63.sh`, `/tmp/u2a4s25-ml7c/logs/c63.log`, `/tmp/u2a4s25-ml7c/logs/c63-head.out`, `/tmp/u2a4s25-ml7c/logs/c63-main.out`, `/tmp/u2a4s25-ml7c/c63b.sh`, `/tmp/u2a4s25-ml7c/logs/c63b.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 64: "The index pop removes a super-linear term: one instruction file importing N docs, main walk N=1000 vs N=3000 grows ~x3.2 at HEAD vs ~x4.5 with main's lib (tree walk also faster at N=3000)."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:856-857`, `:917-919`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the walks over one committed instruction file that imports N = 1,000 or 3,000 committed docs, with each lib in its own process, two reps per process and two processes per lib, interleaved; does not establish that HEAD's walks are linear (HEAD's main-walk ratio is still above 3, so other super-linear terms remain, such as the tree walk's string `seen` lookups at `:867`), other walk shapes, or exact seconds on a host with other sessions running.

Main's lib popped by copying the whole queue on each pop: `f="${queue[0]}"; queue=("${queue[@]:1}")` (main's `scripts/lib/dev-cycle-read.sh:784` and `:845`). HEAD pops by index: `f="${queue[qi]}"; qi=$((qi + 1))` (`:857` and `:919`). Within each process, the N=3000/N=1000 ratio of the main walk (`logs/c64.log`) was:

| Process | Lib | Rep 1 | Rep 2 |
|---|---|---|---|
| 1 | HEAD | x3.30 | x2.50 |
| 2 | main | x4.72 | x3.35 |
| 3 | HEAD | x3.49 | x2.69 |
| 4 | main | x4.75 | x3.72 |

HEAD's ratio is lower than main's lib in every matched rep. The first reps match the reviewer's ~x3.2 against ~x4.5. The second reps run lower in both libs because their N=1000 walk ran after an N=3000 walk in the same process. At N=3000 the tree walk took 37.1-40.4 s at HEAD and 50.0-58.2 s with main's lib. Both walks returned 0 with 12,005 names at N=3000 and 4,005 names at N=1000.

Command: `timeout 3000 bash c64.sh`, exit 0, 2026-10-08T07:35:39Z to 07:47:51Z (`logs/c64.ts`). Load average was 0.7-1.1 on 16 cores (`uptime` lines in the log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:856-867`, `scripts/lib/dev-cycle-read.sh:917-919`, `/tmp/u2a4s25-ml7c/c64.sh`, `/tmp/u2a4s25-ml7c/logs/c64.log`, `/tmp/u2a4s25-ml7c/logs/c64.ts`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 65: "The phase-2 swap `queue=("${tq[@]}"); tq=(); qi=0` (:918) is linear in total files queued."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:918`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the swap's copying cost over a whole main_imports run, including repeated swaps when phase 2 reaches further checkout files; does not establish the cost of the other per-item work in the loop (parser, `seen` lookups, main_checkout), or memory, since consumed queue entries are kept until the next swap.

```bash
# scripts/lib/dev-cycle-read.sh:917-919
  while [[ $qi -lt ${#queue[@]} || ${#tq[@]} -gt 0 ]]; do
    [[ $qi -lt ${#queue[@]} ]] || { queue=("${tq[@]}"); tq=(); qi=0; }  # phase 2: main's walk is done
    f="${queue[qi]}"; qi=$((qi + 1)); ...
```
(excerpt ends :919; the enclosing main_imports continues to :962 — read)

The swap runs only when the index has consumed `queue`, and it copies just `tq`, the items gathered since the last swap, then empties `tq`. A swap can run more than once: during phase 2, a path main lacks is appended to `tq` again, `elif [[ $c -eq 0 ]]; then tq+=("$p"); fi` (`:960`). Each path enters `tq` at most once, because every enqueue is gated on `seen`: `[[ -z "${seen[$p]+set}" ]] || continue` followed by `seen[$p]=1` (`:956-959`), and the starts are gated by `seen[$f]=1` (`:911`). So the total number of elements copied across all swaps is at most the number of items ever put into `tq`, which is linear.

**Evidence:** `scripts/lib/dev-cycle-read.sh:905-962`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 66: "Every base resolution and quoted-run prefix is charged `work += length(c)` before its `tried` memo check, and awk stops at IMPORT_LEFT, so no input runs past either budget (a 200,000-character quoted run fails closed quickly)."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:628-663`
**Type:** Performance / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser's charged paths (emit, put, splice) and the IMPORT_LEFT stop, with 200,000-character quoted, unquoted and blank-bearing quoted runs, and an output-bound run; does not establish a bound on the uncharged work the lib comment names (the per-character scan of @-less text, sed, the python3 decode and the blob drain, each linear in the 4 MiB capped read), or the bash side after awk.

```awk
# scripts/lib/dev-cycle-read.sh:628-629 (emit) and :644-648 (put)
function emit(c,   i) {
  work += length(c); if (work > wmax) exit 3
...
function put(c,   n, i, k, part, st, out) {
  ...
  work += length(c); if (work > wmax) exit 3
  if (c in tried) return
```
(excerpts end :629 and :648; emit continues to :643 and put to :663 — read)

emit calls `put(root "/" dirs[i] "/" c)` once per base (`:642`). Each `put` charges the resolved spelling before the `tried` check, so a repeated spelling still costs. Each quoted-run prefix reaches `emit(name)` from `names` (`:684`), which charges it first. Printing stops at `seen[out] = 1; printed += length(out) + 1; if (printed - 1 > left) exit 3` (`:661`). Executed through `import_targets` (`logs/c6668.log`, `logs/c6668b.log`):

- A 200,000-character quoted run with no closing quote gives `rc=1` after 0.068 s. The output bound stops it first (2,827 names printed).
- The same input with `IMPORT_LEFT=inf` gives `rc=1` after 0.399 s, with the trailer at `/50005930`, just past the 50,000,000 work bound.
- A 200,000-character unquoted run gives `rc=1` after 0.066 s, and a quoted run with blanks gives `rc=1` after 0.213 s.
- With `IMPORT_LEFT=50`, 100 names give `rc=1` after 9 lines. The control gives `rc=0`.

Commands: `timeout 1200 bash c6668.sh` and `timeout 1200 bash c6668b.sh`, both exit 0, 2026-10-08 (`logs/c6668.ts`, `logs/c6668b.ts`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:628-697`, `scripts/lib/dev-cycle-read.sh:746-747`, `/tmp/u2a4s25-ml7c/c6668.sh`, `/tmp/u2a4s25-ml7c/c6668b.sh`, `/tmp/u2a4s25-ml7c/logs/c6668.log`, `/tmp/u2a4s25-ml7c/logs/c6668b.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 67: "Iteration-1 performance F1 is fixed: a top-level .claude/commands/x.md resolves against two directories (its own and the top level), not three."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:495-503`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers prompt_bases and the resolved spellings at 2b6f2f91 for top-level command and skill files, and for nested and doubled `.claude/` files; does not re-execute iteration 1's code (d7cdc1ea), so "not three" rests on that review's finding 1.

```bash
# scripts/lib/dev-cycle-read.sh:496-501
  local -n pb_a="$1"; local rest="/$2" n
  pb_a=("")
  while [[ "$rest" == */.claude/* ]]; do
    ...
    rest="${rest#*/.claude}"; n=$(( ${#2} - ${#rest} - 8 ))
    (( n <= 0 )) || pb_a+=("${3:0:n}")
```

For `.claude/commands/x.md`, n is `21 - 14 - 8 = -1`, so no base is added beyond the top level `""`. Executed:

```
.claude/commands/x.md: own=[.claude/commands] bases=1 -> []
.claude/skills/k/SKILL.md: own=[.claude/skills/k] bases=1 -> []
a/.claude/commands/x.md: own=[a/.claude/commands] bases=2 -> [] [a]
c/.claude/.claude/commands/y.md: own=[c/.claude/.claude/commands] bases=3 -> [] [c] [c/.claude]
```

Running `@n.md` through `import_targets .claude/commands ""` prints two spellings per prefix (`.claude/commands/n.md` and `n.md`) and nothing else. Iteration 1's finding (`docs/reviews/performance-reviewer-review-2026-10-07-build-loop-u2a4.md:25`, "A top-level prompt resolves against the top level twice") gave three.

Command: `timeout 1200 bash c6668.sh`, exit 0 (`logs/c6668.ts`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:495-503`, `scripts/lib/dev-cycle-read.sh:724-747`, `/tmp/u2a4s25-ml7c/logs/c6668.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 68: "The quoted run adds one O(run^2) pass per @", not a cubic term; quoted runs from distinct @" are disjoint."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:664-686`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quoted-run pass's growth (charged work and wall time for r against 2r, and K runs) and the disjointness of runs from distinct `@"`; does not establish the unquoted pass, whose runs from successive `@` in one blank-free run overlap (a pre-existing, work-charged term), or the per-base factor (each prefix is resolved once per base).

A quoted run ends at the first `"` after its start (`if (q) { if (ch == "\"") break }`, `:681`). Every `@"` contains a `"`, so any later `@"` inside an earlier run ends that run at its own quote, and the two runs share no characters. Executed: `@"docs/a @"docs/b.md" tail` yields the first run's prefixes only up to `docs/a @`, and the second run from `docs/b.md` (`logs/c6668.log`, "nested"). Each run of length r emits r prefixes of length at most r, so it costs O(r²). Disjoint runs have Σr ≤ L, so their total is at most L².

Measured with `IMPORT_LEFT=inf` (`logs/c6668b.log`):

- Doubling r multiplies charged work by 3.96 (r=1500→3000: 4,587,058→18,174,058; r=2000→4000: 8,116,058→32,232,058) and wall time by 3.5-4.1 (0.035-0.039 s → 0.130-0.139 s; 0.059-0.063 s → 0.241-0.261 s). A cubic term would give about 8.
- K disjoint runs of 1,000 give work 4.1M, 8.2M and 16.5M for K = 2, 4 and 8, which is linear in K.

Commands: `timeout 1200 bash c6668.sh` and `timeout 1200 bash c6668b.sh`, both exit 0 (`logs/c6668.ts`, `logs/c6668b.ts`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:664-686`, `/tmp/u2a4s25-ml7c/c6668.sh`, `/tmp/u2a4s25-ml7c/c6668b.sh`, `/tmp/u2a4s25-ml7c/logs/c6668.log`, `/tmp/u2a4s25-ml7c/logs/c6668b.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 60** (`scripts/lib/dev-cycle-read.sh:495-503`): every fixture target is refused by floor and imported by both walks, but `a/.claude/commands/b/docs/n.md` and `c/.claude/d.md` (the doubled-`.claude/` base) are refused as instr and dot, not with the imported reason. Only `docs/q.md`, `docs/k.md` and `docs/n.md` reach --check-fix's walk skip.

### Unverifiable
(none)
