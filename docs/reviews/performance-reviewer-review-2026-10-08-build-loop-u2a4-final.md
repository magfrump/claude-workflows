Commit: 2b6f2f91

# Performance Review: feat/build-loop-u2a4, final confirming pass (U2a4, the self-merge floor)

**Scope:** `git diff main...HEAD` (main = 7afdb8d2, HEAD = 2b6f2f91), mainly `scripts/lib/dev-cycle-read.sh` (isstart, prompt_dir, prompt_bases, IMPORT_AWK's emit/put/scan/names, import_targets, both walks, truthrule, truthwalk, floor) and `scripts/dev-cycle.sh` check_fix
**Date:** 2026-10-08
**Based on:** the final pass's Stage 1 summary (`code-fact-check-report-build-loop-u2a4-final-r{1,2,3}.md`: 0 Incorrect), iteration 1's report `performance-reviewer-review-2026-10-07-build-loop-u2a4.md`, and override-log rows 469-471

Execution provenance: every probe ran under `timeout`, with `LC_ALL=C` and `TMPDIR=/tmp/u2a4f-perf-lDIA`. The scripts and logs are `/tmp/u2a4f-perf-lDIA/p/q1.sh` to `q5`, with `q*.log` beside them. `mainlib.sh` there is `git show main:scripts/lib/dev-cycle-read.sh`. Fixtures were mktemp repos under that TMPDIR, and each script removed its own. The floor probe ran read-only in the worktree against its own `main`. No probe process was left running (`ps` was checked afterwards). Each timing is one sample on this WSL2 host (load average 0.2-1.4).

## Data Flow and Hot Paths

- **Callers.**
  - `imported_names` (the tree walk) runs once per `--check-fix` process.
  - `main_imports` (the main walk) runs once per gate decision. Both cache.
  - `floor` has no caller yet. U2b/U2c will call it once per changed path of a branch, so it runs N times per merge decision.
- **Path temperature.** Everything here is cold: per CLI process or per merge decision.
- **Size of the inputs.** The inputs that can be large are repo text, and two budgets bound them per walk:
  - parser work, `IMPORT_WORK_MAX=50000000`;
  - printed output, `IMPORT_OUT_MAX=4000000`.

  When either budget is spent, the walk fails closed: `--check-fix` then skips every path, and `floor` refuses every path with "could not be walked".
- **What iteration 2 changed in the cost model.**
  - The quoted run is a second candidate run per `@"`, and it reads past blanks to the closing quote. Every prefix of it is emitted.
  - A prompt start's names resolve against `prompt_bases`: the top level, plus the directory holding each enclosing `.claude`. The extra `""` base that iteration 1's F1 measured is gone: `.claude/commands/x.md` now gets exactly one extra base (`q3.log`: `k=1 ... bases=1 xdirs_bytes=1`).

**Answer to the focus question (measured): no path is unbounded.**
- Every `emit` and `put` is still charged before its memo check.
- awk still exits at `IMPORT_LEFT`.
- No adversarial input in q1 to q3 ran longer than 1.1 s per walk.

There are two super-linear shapes, and both end by failing closed, quickly:
- **The quoted run's output is quadratic in its length** (Finding 1). This is a new availability cliff that ordinary text can reach.
- **The size of `IT_XDIRS` is quadratic in `.claude` nesting** (Finding 2). This one is adversarial only.

## Findings

#### 1. An unclosed `@"` before about 2.4-3.2 KB of prose prints about 4 MB of prefixes, failing both walks so that floor and --check-fix refuse every path; main's parser printed 6 bytes for the same file

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:664-686` (scan, names), `:628-643` (emit), `:661` (put's output check)
**Move:** Check the asymptotic behavior; Ask "what's the size of N?"
**Classification:** Macro (output quadratic in the length of the quoted run) / Cold path (once per walk). The result is a liveness cliff, not a cost: it fails closed in about 100 ms.
**Confidence:** High
**Baseline:** One unclosed `@"` followed by 3,200 characters of prose (`word word ...`) in an instruction file:
- At HEAD, both walks fail: `instr N=3200 lines=1 tree rc=1 ms=86`, `main rc=1 ms=82`, and `floor docs/a.md rc=0 why=the default branch's instruction files could not be walked for @ imports`.
- main's lib on the same repo: `instr N=3200 lines=1 tree rc=0 ms=12 bytes=6`.

From `/tmp/u2a4f-perf-lDIA/p/q2.log` and `q2main.log`, 2026-10-08.
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```awk
# scripts/lib/dev-cycle-read.sh:664-686 (scan and names, whole functions, read)
function scan(line,   i, L) {
  L = length(line)
  for (i = 1; i <= L; i++) {
    if (substr(line, i, 1) != "@") continue
    names(line, i + 1, L, 0)
    ...
    if (substr(line, i + 1, 1) == "\"") names(line, i + 2, L, 1)
  }
}
function names(line, j, L, q,   ch, name) {
  name = ""
  for (; j <= L; j++) {
    ch = substr(line, j, 1)
    if (q) { if (ch == "\"") break }
    else if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ }
    else if (ch == " " || ch == "\t" || ch == "\r") break
    name = name ch; emit(name)
  }
}
```

- **Mechanism.** In quoted mode the run ends only at a `"` or at the end of the line. `emit(name)` then fires once per prefix. Each prefix is a distinct resolved spelling, so put prints each one: N characters print about N²/2 bytes. Each extra base multiplies that, because emit's loop at `:642` puts every relative prefix once per directory.
- **Parser output (`q1.log`).** 1,000 characters printed 337,701 bytes plain, 680,084 bytes as a top-level prompt and 1,019,787 bytes as a `sub/` prompt. The unquoted reading of the same text printed 18, 48 and 69 bytes.
- **The cliff (`q2.log`).**
  - Both walks fail closed with one such line of about 3,200 characters in an instruction file, or about 2,400 in a top-level command.
  - Several distinct lines add up, because the budget is per walk. Twelve distinct 1,000-character lines in an instruction file fail it. So do four in a `sub/` command, or fifteen 500-character lines there.
  - A file the walk reaches by an import counts too, not only start files.
- **How close real text comes.** The longest `@"` run in this repo's tracked markdown is 376 characters (a review record, which no walk reads). About 8× that fails a walk. The trigger needs an unclosed `@"`, or a closed one wrapping thousands of characters, on one long line of a file a session loads. This is rare, but it is reachable by prose, and not only by crafted input.
- **What the failure costs.** It is the safe direction, so no file is under-read. While such a line sits on main, every self-merge is refused and every in-cycle fix is filed. The cause is reported only as "could not be walked" (override row 467 defers the cause word to U2c).
- **Relation to row 469.** Row 469 declined the cost of the uncharged per-line loop once the output budget binds. This finding is about which text reaches that budget. It became reachable only with iteration 2's change that reads past blanks, after row 469 was written.

**Recommendation:** Pick one of two options:
- **Emit the quoted name once, at its closing quote.** The quoted run would then emit only the whole name (`name` when `ch == "\""`), not every prefix, and nothing for an unclosed `@"`. That makes the run linear: one candidate per mention. The extractor the security review quoted from the 2.1.293 binary is `@"([^"]+)"`. It requires the closing quote and captures only the whole content. Prefixes up to the first blank are still read by the unquoted run on the same text. This narrows what is read, so it needs security sign-off, since under-reading is the failure class that matters.
- **Keep the superset.** Name the cliff in known issue A5, beside the output-budget note: "an unclosed `@"` before about 2-3 KB of text fails the walk".

In either case, add a test with an unclosed `@"` before 3,200 characters of prose, pinning whichever behavior is chosen.

#### 2. `IT_XDIRS` grows quadratically with `.claude` nesting, and past about 225 nested components (a path of about 1.8 KB) `env` fails with E2BIG, failing the walk

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:495-503` (prompt_bases), `:727` and `:746` (import_targets builds `x` and passes `IT_XDIRS="$x"` through `env`)
**Move:** Ask "what's the size of N?"
**Classification:** Macro (quadratic in path length) / Cold path. Adversarial only, and it fails closed.
**Confidence:** High
**Baseline:** From `/tmp/u2a4f-perf-lDIA/p/q3.log`, 2026-10-08:
- 128 nested `.claude/` components (a 1,037-byte path): 65,152 bytes of `IT_XDIRS`.
- 256 components (2,061 bytes): 261,376 bytes, and `import_targets rc=1 ... env: Argument list too long`.
- 180 components: still `rc=0`, with 1,239,804 work units for a one-name file.

**Legibility-target:** for-author

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:495-503 (prompt_bases, whole function, read)
prompt_bases() {
  local -n pb_a="$1"; local rest="/$2" n
  pb_a=("")
  while [[ "$rest" == */.claude/* ]]; do
    rest="${rest#*/.claude}"; n=$(( ${#2} - ${#rest} - 8 ))
    (( n <= 0 )) || pb_a+=("${3:0:n}")
  done
}
# scripts/lib/dev-cycle-read.sh:727, :746 (import_targets, :724-748, read)
  [[ $# -lt 2 ]] || x="$(printf 'x%s\n' "${@:2}")"  # the walks refuse a name holding a newline
  printf '%s\n' "$toks" | env LC_ALL=C IT_DIR="$1" IT_XDIRS="$x" ...
```

- **Mechanism.** A path made of k nested `.claude/` components gets k bases. Each base is a prefix of the path, so `IT_XDIRS` is about k × len / 2 bytes. Linux caps one environment string at 128 KiB (MAX_ARG_STRLEN), so `env` fails between 180 and 256 levels.
- **Cost before the cap.** prompt_bases itself took 10 ms at 400 levels. The parser's per-candidate puts grow with k, but they are charged.
- **Who can reach it.** Only a deliberately crafted tree. The result is the same fail-closed walk as Finding 1.

**Recommendation:** No change needed. If one is wanted, pass the bases on a file descriptor or stdin header rather than the environment, or fail with a named reason when there are more than some fixed number of bases (for example 32).

## Deferred rows, re-measured at 2b6f2f91 (not re-filed)

- **Iteration 1 F1 (duplicate `""` base): fixed.** `prompt_bases` starts from `pb_a=("")` and adds only bases with `n > 0`, so a top-level command gets one extra base (`q3.log` `k=1 bases=1`).
- **Row 470, floor per path.** 7,586 µs per path over 200 paths with the walk cached (iteration 1: 7,378 µs). The split, measured separately per call:
  - `lower`: 2,018 µs, called twice per path;
  - `need_root`: 624 µs, called three times per path.

  The glob membership test is unchanged. Row 470's U2c trigger stands (`q4.log`).
- **Row 471, start loop.** 400 one-line command starts: the tree walk took 4,404 ms and the main walk 2,891 ms (iteration 1: 10,352 / 5,938 ms, under different host load). That is about 11 ms per start in the tree walk. The trigger (a tree walk past 5 s) is not reached here.
- **Row 469, output budget binding first.** Consistent with Finding 1's walks: about 1.1 s for a main walk printing 3.6 MB (`q2.log`: `instr N=3000 ... main rc=0 ms=1086 bytes=3607208`).

## Endorsements (evidence-gated)

- **The index pop removes a super-linear term in situ.** One instruction file importing N docs, each read once. The main walk took 5,049 ms at N=1,000 and 16,104 ms at N=3,000 at HEAD (×3.2). main's lib took 6,450 ms and 28,846 ms (×4.5). The tree walk took 20,571 ms at HEAD vs 25,812 ms with main's lib at N=3,000 (`q4.log`). `[unverified — submitted as claim]`
- **The phase-2 swap is linear.** `queue=("${tq[@]}"); tq=(); qi=0` (`:918`) copies each checkout-phase item once per swap. Items reached during phase 2 append to `queue` or `tq`, so total copying stays linear in the files queued. `[unverified — submitted as claim]`
- **Every base is charged before its memo check, and awk stops at `IMPORT_LEFT`.** Every quoted-run prefix and every `prompt_bases` base resolution pays `work += length(c)` before its `tried` memo check. So no input in q1 to q3 ran past either budget: the 200,000-character quoted run failed in 85 ms (`q1.log`). `[unverified — submitted as claim]`
- **Iteration 1's F1 is fixed.** A top-level `.claude/commands/x.md` resolves against two directories, not three (`q3.log` `k=1 bases=1`). `[unverified — submitted as claim]`
- **The quoted run adds one O(run²) pass per `@"`, not a cubic term.** The runs from distinct `@"` end at the next `"`, so they are disjoint, and a line's quoted-run work is at most about L²/2. The 2,000-quote test line stays a single unquoted run. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Unclosed `@"` before about 2.4-3.2 KB of prose prints about 4 MB of prefixes; both walks fail closed, so floor and --check-fix refuse every path (main: 6 bytes) | Low | `scripts/lib/dev-cycle-read.sh:664-686`, `:642`, `:661` | High |
| 2 | `IT_XDIRS` is quadratic in `.claude` nesting; E2BIG past about 225 levels fails the walk | Informational | `scripts/lib/dev-cycle-read.sh:495-503`, `:727`, `:746` | High |

## Overall Assessment

- **Posture.** Sound for a cold-path gate. Iteration 2's changes kept every new parser path charged and output-bounded. No measured input ran past 1.1 s per walk, and the index pop measurably flattens the main walk's growth (×3.2 vs ×4.5 for a 3× larger import set). Iteration 1's F1 is fixed.
- **What is new.** One reachability shift (Finding 1): the quoted run emits every prefix through blanks, so a few kilobytes of ordinary prose after an unclosed `@"` now fill the 4 MB output budget. One such line on main stalls every self-merge until it is edited.
- **The fix.** Fixable in place, and the decision belongs to security: emit only the closed, whole quoted name (linear, and matching the binary's `@"([^"]+)"`), or keep the superset and document the cliff.
- **The rest.** Finding 2 and the re-measured deferred rows need nothing in this unit.
- **Profiling.** None needed. U2c should still measure floor over a realistic branch (row 470).

## Goal-Alignment Note

- **Success criterion (verbatim):** "your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence."
- **Answered:** yes. Each focus item was measured under `timeout`:
  - the prompt-start cost model, with prompt_bases and the quoted run against both budgets (q1, q2, q3);
  - the index pop, in situ against main's lib (q4);
  - the tree walk's per-start cost (q4);
  - floor's per-path cost (q4);
  - the quadratic quote fix and prompt_bases, checked for unbounded or super-linear paths: two super-linear shapes, both bounded and failing closed (F1, F2).

  Both findings quote whole functions.
- **Out of scope:**
  - Whether Claude Code reads an unclosed `@"`, or prefixes of a quoted name. The no-egress caveat applies to F1's first option. The binary regex is quoted from the security review, not re-checked.
  - U2c's real per-branch path count.
  - Variance: each timing is a single sample.
- **Escalate:** F1's choice between narrowing the quoted run and documenting the cliff is a security-reader-model decision, not a performance one. Route it with the security reviewer's view.
- **Decisions I made:**
  - F1 is Low, not Medium. It fails closed, fast, on a cold path, and the brief names over-reading as the safe direction.
  - Deferred rows 469-471 are re-measured, not re-filed, since no number crossed their revisit triggers.
  - The endorsements are tagged unverified, as directed, although my probes measured them.
