Commit: d7cdc1ea

# Performance Review: feat/build-loop-u2a4 (U2a4, the self-merge floor)

**Scope:** `git diff main...HEAD` (main = 7afdb8d2, HEAD = d7cdc1ea), mainly `scripts/lib/dev-cycle-read.sh` (isstart, prompt_dir, IMPORT_AWK emit/put, import_targets, both walks, truthrule, truthwalk, ownfile, floor) and `scripts/dev-cycle.sh` check_fix
**Date:** 2026-10-07 (probes ran 2026-10-08 UTC)
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a4.md` (30 claims; Claims 5, 25 and 26 bear on cost)

Execution provenance: every probe ran under `timeout`, with `LC_ALL=C` and `TMPDIR=/tmp/u2a4-perf-fIav` (HOME set to that directory for the fixture walks). Scripts and logs are in `/tmp/u2a4-perf-fIav/p/` (`p1.sh` to `p6.sh`, `p*.log`). Fixtures were built in mktemp directories under that TMPDIR and removed afterwards. `p5.sh` ran read-only in the worktree, against its own `main`. Nothing was left running. Each timing below is one run on this WSL2 host. They are single samples, not distributions.

## Data Flow and Hot Paths

- **Callers.** `imported_names` (tree walk) runs once per `dev-cycle.sh --check-fix` process and caches its result per ROOT_REAL. `main_imports` (main walk) runs once per gate decision and caches per `MAIN_SHA MAIN_BY_NAME ROOT_REAL`. `floor` has no caller yet. U2b/U2c will call it once per changed path of a branch being merged, so it runs N times per merge.
- **Path temperature.** All of this is cold or warm. It runs per CLI invocation or per merge decision, never per request. The inputs that can be large are untrusted repo text: a file's `@` candidates, bounded by the per-file and per-walk parser work (`IMPORT_WORK_MAX=50000000`) and by the printed output (`IMPORT_OUT_MAX=4000000`). The other large input is the number of start files and changed paths.
- **What changed.** A prompt start under `.claude/{commands,agents,output-styles}/` now resolves each relative candidate against up to three directories: its own directory, the directory holding its `.claude/`, and the top level. emit calls `put` once per directory, and every `put` is charged against the work bound before its `tried` memo check. The start set widens to every `.md` file under those directories and under `.claude/rules/`. Both queues pop by index. floor composes `lower`, `truthrule`, `truthwalk` (which calls `main_imports`, then `isimported`, which runs `lower` again and then a glob membership test).

**Answer to the cost-model question (measured).** The extra base directories do not escape the bounds. Each extra `put` is charged (`work += length(c); if (work > wmax) exit 3` precedes `if (c in tried) return`), and awk exits once `printed - 1 > left`, before it prints past the output budget. An adversarial prompt file therefore costs at most what the two budgets allow (`p1.log`):
- On a 1,500-deep `@a/a/...` run, the plain resolution finished: `adv.txt plain rc=0 work=9159000 lines=1501 ms=587`.
- The same text as a prompt failed closed at the output budget after about 1 s: `adv.txt top rc=1 ... ms=1015` and `adv.txt sub rc=1 ... ms=1013`.

What the extra directories do change is which budget binds first, and how much uncharged shell work runs after the parser (Findings 1 and 2).

## Findings

#### 1. A top-level prompt resolves against the top level twice, spending about 40% more parser work for identical output

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:832`, `:894` (the `xs=` assignment), `:627` (emit's loop), `:490` (prompt_dir)
**Move:** Count the hidden multiplications
**Classification:** Micro (a redundant charged `put` per candidate) / Cold path (once per walk)
**Confidence:** High
**Baseline:** 10,942,680 parser work units with the duplicate base vs 7,843,110 without it, for the same 48,017 output lines. Measured with `import_targets .claude/commands "" ""` vs `import_targets .claude/commands ""` on a 3,000-line file (`/tmp/u2a4-perf-fIav/p/p2.log`, 2026-10-08).
**Legibility-target:** for-author

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:490
prompt_dir() { local -n pd_m="$1"; [[ ! "$2" =~ $PROMPT_DIR ]] || pd_m[$3]="${3:0:${#BASH_REMATCH[1]}}"; }
# scripts/lib/dev-cycle-read.sh:894 (excerpt; main_imports continues to :937, read)
    f="${queue[qi]}"; qi=$((qi + 1)); xs=(); [[ -z "${pdir[$f]+set}" ]] || xs=("${pdir[$f]}" "")
# scripts/lib/dev-cycle-read.sh:627 (last line of emit, :613-628, read)
  for (i = 0; i <= nd; i++) put(root "/" dirs[i] "/" c)
```

- **Why it happens.** For a start at `.claude/commands/x.md` (the usual place for a command), prompt_dir stores `""`, so `xs=("" "")` and awk's `dirs` is `.claude/commands`, `""`, `""`. Every relative candidate gets a third `put` whose spelling is the same as the second's. `put` charges `length(c)` before the `tried` check returns, so the charge is paid and nothing new is resolved.
- **Measured effect.** Wall time barely moves (179 ms either way, `p2.log`), because the `tried` hit is cheap. What moves is the work budget: a top-level command reaches `IMPORT_WORK_MAX` with about 28% less text than it would otherwise need.
- **What that costs.** A walk that hits the budget fails closed. `--check-fix` then refuses every path, and floor answers "could not be walked" for every path.
- **Scope.** This is wasted budget, not unbounded cost. It applies only to top-level prompts. For `sub/.claude/...`, `xs=("sub/" "")` gives three distinct spellings.

**Recommendation:** Pass the top level only when prompt_dir's value is non-empty: `xs=("${pdir[$f]}"); [[ -z "${pdir[$f]}" ]] || xs+=("")`. Alternatively, drop duplicate directories in awk's `BEGIN`. Re-run `p2.sh`. The work figure should then match the `dedup` row.

#### 2. Prompt starts make the output budget, not the work budget, the binding bound, and the uncharged per-line shell loop scales with that output

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:894-900` (prompt reads), `:924-936` (main walk's per-output-line loop), `:832-842` (tree walk's)
**Move:** Ask "what's the size of N?" and Check the asymptotic behavior
**Classification:** Macro (cost linear in output lines, not charged to the work bound) / Cold path, bounded by IMPORT_OUT_MAX
**Confidence:** High
**Baseline:** a 13,536 ms main walk for one `sub/.claude/commands/x.md` printing 3,877,660 bytes (97% of IMPORT_OUT_MAX), vs 4,063 ms for the same text as an instruction file (759,154 bytes). Measured in an 8,000-line fixture (`/tmp/u2a4-perf-fIav/p/p4.log`, 2026-10-08).
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:926-936 (excerpt of main_imports' loop body; the loop ends :936, the function :937, read)
    (( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED_MAIN=error; return 1; }
    ...
    while IFS= read -r p; do
      ...
      c=0; [[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p" || c=$?  # main lacks p: admitted before it is marked seen
```

- **What is charged and what is not.** IMPORT_WORK_MAX charges only the parser. The shell loop over each printed path (a `seen` lookup, and `main_checkout` with its `-e`/`-L` tests for paths main lacks) is bounded only by the output budget.
- **What the extra directories change.** They multiply printed paths per unit of parser work (`p3.log`: the same 3,000 lines print 279,154 / 966,443 / 1,437,660 bytes as instruction file / top-level command / sub command). A prompt therefore reaches the 4 MB output ceiling at well under the work ceiling. The same 8,000 lines as an instruction file stayed far below both.
- **Per-byte cost.** It did not rise: about 3.5 s/MB for the prompt cases vs about 5.4 s/MB for the instruction file. So the bound holds, and an adversarial command file cannot multiply cost past what IMPORT_OUT_MAX already allowed.
- **What a repo can now do.** It can reach that ceiling with less text. The measured ceiling for this text shape was about 13.5 s per main walk. The tree walk's ceiling in the same fixture was 3,842 ms.
- **Scope.** This is over-reading by design (the safe direction, per the brief), and it is bounded. It is filed because the cost of the 4 MB budget, once paid only by unusual text, is now paid by ordinary-looking prompt text.

**Recommendation:** No code change needed for correctness. If gate latency matters for U2c, record the measured ceiling (about 13.5 s main walk at the output budget) in the cost-model comment beside IMPORT_OUT_MAX, or charge printed lines into the work total so that one budget bounds both. After Finding 1's fix, re-measure top-level prompts.

#### 3. floor lower-cases each path twice and forks need_root three times; its membership test is linear in the walk's size, per changed path

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1015`, `:1028`, `:983`, `:947-949`
**Move:** Count the hidden multiplications
**Classification:** Micro (forks per path) plus Macro (O(|IMPORTED_MAIN|) per path, times N paths) / Cold path (once per merge decision; no caller until U2b/U2c)
**Confidence:** High
**Baseline:**
- Small walk list: 7,378 µs per floor call (200 paths, walk cached, 2,020-byte IMPORTED_MAIN, this worktree against main 7afdb8d2).
- Synthetic 4,400,001-byte IMPORTED_MAIN: 97,924 µs per call (50 paths).

Both from `/tmp/u2a4-perf-fIav/p/p5.log`, 2026-10-08.
**Legibility-target:** for-author

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1015 (floor, :1011-1032, read)
  lp="$(lower "$1")" || { FLOOR_WHY="the path could not be lower-cased"; return 0; }
# scripts/lib/dev-cycle-read.sh:983 (truthwalk, :980-984, read)
  TRUTH_WHY=imported; isimported "$2" "$1"
# scripts/lib/dev-cycle-read.sh:947-949 (isimported, :944-953, read)
  lp="$(lower "$2")" || return 0
  case "$1" in
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
```

- **Main walk: cached.** `main_imports` is cached. The real walk took 730 ms once (`walk rc=0 ms=730`), so N paths do not re-walk.
- **Forks per path.** floor passes an already lower-cased `lp`, and isimported forks `lower` on it again (about 2.3 ms per `lower` here: `lower x200 ms=466`, `p3.log`). Each path also runs `need_root`'s `$(pwd -P)` subshell three times: floor, main_imports' guard, isimported.
- **Membership test.** It is a glob over the whole newline list, so each path costs O(|IMPORTED_MAIN|). The list can reach IMPORT_OUT_MAX (lower-cased, about 4 MB). At that size, 50 globs alone took 1,907 ms (`glob x50 vs big`). The rest of the roughly 98 ms per path is the forks, which get slower as the shell's heap grows. 1,000 changed paths against a full list comes to about 100 s; against this repo's list, about 7 s.
- **Shared code.** check_fix has the same double `lower`, but it runs once per path given on the command line, and that pattern predates this diff.

**Recommendation:**
- Let truthwalk/isimported accept an already lower-cased path, so floor and check_fix skip the second `lower` fork.
- When U2c loops floor over a branch, build an associative set from the walk result once per walk (`local -A`, keyed on each line), so each membership test is O(1).
- Measure U2c's gate on a realistic branch size before deciding whether that is needed.

#### 4. The tree walk forks lower and inrepo_here per start, and the start set now includes every prompt and rules .md file

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:819-827` (imported_names' start loop), `:739` (instruction_names)
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (forks per start) / Cold path (once per --check-fix process, cached)
**Confidence:** High
**Baseline:**
- 400 one-line command files: tree walk 10,352 ms; main walk 5,938 ms.
- 100 files: 2,687 ms and 1,509 ms.

From `/tmp/u2a4-perf-fIav/p/p3.log`, 2026-10-08.
**Legibility-target:** for-author

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:823-824 (imported_names' start loop; the function continues to :843, read)
    lp="$(lower "$f")" || return 1
    if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi
```

- **Fork count unchanged.** Lowering the whole path instead of the basename does not add forks: main's code also forked `lower` once per prefiltered record.
- **What did change.** The prefilter now passes every `.md` file under `.claude/{rules,commands,agents,output-styles}/`. That includes ignored vendored copies, because `untracked_md` lists ignored files. Each of those starts pays one `lower` fork, `inrepo_here`'s `blocker` subshell with a `realpath` per path component, and a parse.
- **Per-start cost.** About 26 ms in the tree walk vs about 15 ms in main_imports, which lowers the whole candidate list in one `tr` (`lower_all`) and skips `inrepo_here` for main's starts.
- **Scale.** A repo with a few hundred command or agent files, or a `node_modules/` holding packages that ship `.claude/agents/`, adds seconds to each `--check-fix` process.

**Recommendation:** Lower the start records in one `nul_list ... lower_all` call, as main_imports does at `:878-880`. Only if real repos show many prompt starts, consider whether ignored `.claude/` directories under vendored trees should be starts at all (that last point is a reader-model question for U2b, not a performance fix).

## Endorsements (evidence-gated)

- The index pop removes a quadratic copy. In a bash micro-benchmark of the two pop shapes, popping 5,000 ~25-byte paths by `queue=("${queue[@]:1}")` took 7,981 ms, and popping by index took 19 ms. At 2,000 paths: 1,310 ms vs 7 ms (`/tmp/u2a4-perf-fIav/p/p6.log`). Fact-check Claim 5 verified the structure but ran no timing. `[unverified — submitted as claim]`
- Every extra-directory `put` is charged before its `tried` check. awk exits at `IMPORT_LEFT` before printing past it, so a prompt file's parser cost stays within IMPORT_WORK_MAX and its output within IMPORT_OUT_MAX. In `p1.log`, prompt-resolved adversarial input failed closed in about 1 s, and the plain case finished in 587 ms. `[unverified — submitted as claim]`
- floor runs the main walk once per gate decision, not once per path. After a 730 ms walk, 200 floor calls averaged 7.4 ms each (`p5.log`). `[unverified — submitted as claim]`
- The phase-2 swap `queue=("${tq[@]}"); tq=(); qi=0` copies each checkout-phase item once per swap, so total copying stays linear in queued items. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A top-level prompt resolves against `""` twice: about 40% more parser work for identical output | Low | `scripts/lib/dev-cycle-read.sh:832`, `:894`, `:627` | High |
| 2 | Prompt starts make the output budget bind first; the uncharged per-line loop reaches about 13.5 s at the 4 MB ceiling | Low | `scripts/lib/dev-cycle-read.sh:894-936` | High |
| 3 | floor: double `lower` plus 3 `need_root` forks per path; glob membership is O(\|IMPORTED_MAIN\|) per path (7.4 ms to 98 ms per path) | Low | `scripts/lib/dev-cycle-read.sh:1015`, `:947-949`, `:983` | High |
| 4 | Tree walk forks `lower` and `inrepo_here` per start over a wider start set (400 commands: 10.4 s) | Informational | `scripts/lib/dev-cycle-read.sh:823-824` | High |

## Overall Assessment

- **Posture.** Sound for a cold-path gate. The question the brief raised has a measured answer: the extra base directories cannot push a walk past its budgets. Each extra resolution is charged before its memo check, and awk stops at the output budget, so an adversarial command file fails closed in about 1 s. The index pop removes a real quadratic: about 8 s at 5,000 queued files with the old copy pop.
- **What remains.** Accounting and fork overhead, not unbounded cost. The only fix worth making in this unit is Finding 1: it is one line, and it stops ordinary top-level command files from spending about 40% of the work budget on nothing.
- **For U2c.** Findings 2 and 3 matter when U2c loops floor over a branch. U2c should measure its gate on a realistic branch, against both this repo's 2 KB walk list and a large one, before choosing between the double-`lower` removal and an associative set.
- **Profiling.** None needed beyond those U2c measurements.

## Goal-Alignment Note

- **Success criterion (verbatim):** "your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence."
- **Answered:** yes. All four focus areas were measured, not estimated:
  - the cost model under the extra base directories (`p1`, `p2`, `p4`);
  - the tree walk's start-loop forks (`p3`);
  - the index pop (`p6`);
  - floor's per-path cost against cached and 4.4 MB walk lists (`p5`).

  Each finding quotes the code it rests on, with the enclosing function read.
- **Out of scope:**
  - U2b/U2c callers, which do not exist yet. Finding 3's N-path figures are projections from per-path measurements.
  - Variance: each timing is a single sample on one WSL2 host.
  - Whether Claude Code loads `.claude/` directories under ignored vendored trees (Finding 4's reader-model note; no egress).
- **Escalate:** Finding 1 is a one-line fix that is in scope for this review-fix loop. Finding 3's recommendation belongs in U2c's plan, not this unit.
- **Decisions I made:**
  - Findings 1-3 are Low and Finding 4 Informational, because every path is cold (per process or per merge) and bounded. I did not treat them as hot paths.
  - Endorsements are tagged unverified as the task directs, even where my own probe measured them, because only a fact-check execution verdict may carry a categorical runtime claim.
