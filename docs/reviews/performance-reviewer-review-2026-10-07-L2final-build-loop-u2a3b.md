Commit: e1654266

# Performance Review: feat/build-loop-u2a3b (loop 2, final confirming pass)

**Scope:** `git diff main...e1654266 -- . ':!docs/reviews'` (merge base f6fdda68; main at 8f24e63a)
**Date:** 2026-10-07
**Based on:** Stage 1 summary (`u2a3b-L2final-stage1.md`) and code-fact-check reports `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r{1,2,3}.md`

All measurements below ran on 2026-10-07 between 02:50 and 03:05 local time, from `git archive` copies of main and e1654266 in `/tmp/u2a3bperffin-Vkf5/{main,br}`. The host was shared with other agents (load average 5.2-6.8 at 03:03), so absolute times drift between runs. Interleaved pairs are the comparable unit.

## Data Flow and Hot Paths

`import_targets` runs once per walked file. Both callers use it: `imported_names` (the tree walk, once per `--check-fix` process, behind `IMPORTED_DONE`) and `main_imports` (main's commit; only tests call it so far, and U2a4's floor will be its first caller). Per file it forks `env sed` (the 20-expression space conversion). When the text holds a byte above 0x7f it also forks `env awk` (the UTF8_OK gate), plus `python3` when the gate rejects. Then it forks `env awk` (the parser). The caller adds a `$(...)` subshell, `head -c` for the tree walk (`git cat-file` for the main walk), and one `lower` (tr) per file. Main's version forked `env grep` once per file and `realpath` once per `@` token.

N is the number of walked files: 80 in /workspace (35 of them ignored `devcontainer-config/claude-home/**` instruction files, which `untracked_md` lists), and 45 in the worktree and in a clean clone. Per file, N is also the candidates the parser emits. That is bounded by `head -c 4194305` (tree walk only), by the 50M work bound, and by IMPORT_LEFT / IMPORT_OUT_MAX (4M printed characters per walk). The path is cold: a CLI run, with one walk per process. It blocks a human-run `--check-fix` and, from U2a4 on, the build-loop gate.

### The gap against main, explained (executed)

| Checkout | Walked files | main --check-fix (s) | branch (s) | Gap |
|---|---|---|---|---|
| /workspace, 919 paths, 3 interleaved runs | 80 | 2.69 / 2.76 / 2.73 | 3.20 / 3.19 / 3.33 | 0.43-0.60 s |
| worktree, 948 paths | 45 | 2.37 / 2.43 / 2.42 | 2.78 / 2.72 / 2.67 | 0.25-0.41 s |
| clean clone at e1654266, 948 paths | 45 | 4.41 / 4.58 / 4.43 | 5.13 / 5.00 / 5.15 | 0.42-0.72 s (the clone sits on /tmp and ran under higher load) |
| /workspace, one path (README.md), 4 runs | 80 | 0.71-0.79 | 1.11-1.18 | ~0.40 s |

The answers diffed to 0 lines in every pair. The one-path row shows that the gap is almost all the tree walk, because `--check-fix` runs the walk once whatever the path count. I timed every `import_targets` call in one /workspace walk: main's 80 calls took 0.116 s in total (1.5 ms mean), the branch's took 0.465 s (5.8 ms mean, 18.8 ms max). The per-step costs on `skills/spike/SKILL.md` (mean of 30 runs) were: sed 1.23 ms, UTF8_OK gate 1.20 ms, parser awk 1.41 ms, `lower` 1.04 ms, a bare subshell 0.32 ms, python3 6.85 ms (not reached, because the gate passed). 77 of the 80 walked files hold a byte above 0x7f (mostly em dashes), so the gate runs on nearly every file. The rest is caller-side: the longer IMPORTED list (5,607 against 313 characters) costs 30.6 ms against 4.4 ms over 919 membership globs, and the extra `-f` and `inrepo_here` probes for candidates that name files add a little more.

So the gap is a fixed cost of about 4-5 ms per walked file at this load, multiplied by the walked-file count. /workspace walks 80 files and the worktree 45, which is why r3 found 3.2-3.3 s against 2.6-2.75 s there while e1654266's commit message (2.63-2.77 s against 2.39-2.76 s) holds for the worktree. The main walk has the same shape: in the clean clone, main took 0.85-0.91 s and the branch 1.23-1.37 s (3 interleaved runs, both exit 0).

## Findings

#### F1. The work bound charges a candidate's length, not its resolution cost, so a deep directory makes a 4 MiB file run for minutes and succeed

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:535-562` (`emit`, `put`); the bound's premise is stated at `:526-529`
**Move:** Hidden multiplication / asymptotic behaviour (worst-case inputs)
**Classification:** Macro (cost per emit grows with the file's directory depth, and the work bound does not see it) / Cold path (one walk per CLI run), over large adversarial data
**Confidence:** High (executed)
**Legibility-target:** for-author
**Baseline:** 4 MiB file of `@a ` tokens: 3.08 s at the repo top level, 21.86 s with `$1` 50 components deep (`/tmp/u2a3bperffin-Vkf5/wc.sh`, 2026-10-07)

Evidence (verbatim):
```
function emit(c) {
  work += length(c); if (work > 50000000) exit 3
...
function put(c,   n, i, k, part, st, out) {
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  n = split(c, part, "/"); k = 0
...
  out = ""; for (i = 1; i <= k; i++) out = out "/" st[i]
  if (index(out, pre) != 1 || length(out) <= length(pre)) return
  out = substr(out, length(pre) + 1)
  if (out in seen) return
```
(`put` continues with the `seen`/`printed`/IMPORT_LEFT check and `print out`.)

`emit` charges `length(c)`, but `put` prefixes `root "/" dir "/"` and then splits and rejoins the whole path. A repeated candidate dedups at `out in seen`, so it never reaches the `printed` / IMPORT_LEFT bound. The real cost per emit is therefore O(depth of dir), while the charge is O(len(c)). Measured cost is linear in component count: a 420 KB file took 0.33 / 1.25 / 2.21 / 4.25 / 8.4 / 17.19 s at depth 0 / 25 / 50 / 100 / 200 / 400. Fifteen 250-character components took only 1.79 s, so the count of components drives it, not the number of characters. The densest shape that stays under the 50M bound is `@` plus 23 characters plus a blank, repeated. Each run of it takes 8.0 s at depth 0 and 59.05 s at depth 50, and returns rc=0. Extrapolated, depth 400 is about 8 minutes per file (depth is limited only by PATH_MAX). There is no bound across files: the head cap and the work bound are per file, and IMPORT_LEFT counts only printed output. End to end, a scratch repo with two such CLAUDE.md files 50 and 51 levels deep ran `--check-fix docs/guide.md` for 28.6 s and printed `ok docs/guide.md`, rc=0 (`/tmp/u2a3bperffin-Vkf5/e2e.sh`). The main walk shares the parser, and its blob is uncapped (that part is already routed to U2a3c), so the same shape applies there. None of this fails open, because a stalled walk prints no `ok`. But it falsifies the comment's "so a pathological file fails the walk rather than stalling it". It is not a regression: main's parser forks one `realpath` per token (14,000 `@a` tokens took 15.36 s on main and 0.02 s on the branch), so main's worst case for the same 4 MiB file is about 25 minutes, unbounded.

**Recommendation:** Charge what `put` does. In BEGIN, count the components of `root "/" dir` once (`nd`), and in `put` add `nd` to `work` for a relative candidate. Better still, memoise `put` on `c` (`if (c in done) return; done[c] = 1`) before resolving, so a repeated candidate costs a hash lookup. Either change bounds the shape above. The memo alone makes it about as cheap as depth 0.

#### F2. emit's 50M work bound has no test, and it is the only bound on a repeated long token

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:536`; `test/scripts/build-loop-check.bats:383-388`
**Move:** Asymptotic behaviour (a bound that has no test)
**Classification:** Macro / Cold path
**Confidence:** High (executed)
**Legibility-target:** for-automated-gate
**Baseline:** 2,090 lines of `@` plus 2,000 `a`: 0.49 s rc=1 at e1654266, 14.97 s rc=0 with both `if (work > 50000000) exit 3` arms replaced by `if (0)` (`/tmp/u2a3bperffin-Vkf5/mut`)

Evidence: `work += length(c); if (work > 50000000) exit 3`. The test comment says "the sixth run trips it". Stage 1 (r1 33, r2 38) found that IMPORT_LEFT now stops that test first, so a mutant deleting the work bound passes. I ran the shape the work bound exists for: identical long tokens whose prefixes dedup, so printed output stays at 2,000 lines. With the bound in place it fails in 0.49 s. Without it, the parse succeeds after 15 s, and that time also scales with F1's depth factor. The suite would not catch a regression here.

**Recommendation:** Add a fixture of repeated identical long tokens (for example 300 lines of `@` plus 2,000 `a`) and assert rc=1 together with output below IMPORT_LEFT. That assertion holds whatever the timing, and it kills the mutant.

#### F3. import_home forks getent on every walked file when HOME is unset

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:604-610`, called from `:613` once per file
**Move:** Work moved to the wrong place
**Classification:** Micro (three forks per file) / Cold path
**Confidence:** High (executed)
**Legibility-target:** for-author
**Baseline:** /workspace `--check-fix README.md`, 3 interleaved pairs: HOME set 1.63 / 1.68 / 1.84 s, `env -u HOME` 1.89 / 2.03 / 2.12 s (+0.25-0.35 s over 80 files); one call 2.47 ms in a subshell against 0.06 ms with HOME set

Evidence:
```
  h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}" || h=""
  [[ "$IMPORT_HOME_KEY" != "x$h" ]] || return 0
```
(the function then realpaths and sets IMPORT_HOME, IMPORT_HOMER and the key.)

The memo key is the computed home. Computing it with HOME unset or empty costs `id`, `getent` and `cut` before the key is compared. This matches r3 21c. Each file's `import_targets` runs inside `$(...)`, so the walk's own early call does not help. HOME is preserved through `scrub_reexec`, so only `env -i`, cron or systemd callers pay this.

**Recommendation:** Key the memo on the raw input (`k="${HOME+s:$HOME}"`) and compare it before running getent, or have the walk export the computed home once. This is not needed for merge.

#### F4. The per-file fixed cost (three forked tools, head and lower) is now about 4-5 ms, up from the "+2 ms" an earlier Won't-Fix row priced

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:611-634` (`import_targets`), `:669` (`imported_names`' per-file read)
**Move:** Hidden multiplication
**Classification:** Micro (fork overhead per file) / Cold path
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** /workspace walk, `import_targets` total 0.116 s (main) against 0.465 s (branch) over 80 files; `--check-fix` 2.69-2.76 s against 3.19-3.33 s (919 paths)

The override row "Each walked file costs two command substitutions (env sed, env grep), about +2 ms per file" was Won't-Fix at 45 files. This unit has since added the UTF8_OK gate fork (1.2 ms on 77 of 80 files here), and it replaced `grep` with the larger parser awk. The cost now runs to about 4-5 ms per file, and /workspace walks 80 files because the ignored `devcontainer-config/claude-home` tree adds 35. This is the whole gap r3 measured, with no other contributor. It stays under the row's revisit premise (its trigger is the batching rework), so this is new evidence on the price, not a re-raise. One cheap cut: fold the gate into the sed step's output check, or run it as a bash `[[ =~ ]]` test with no fork. Measure that first, since glibc's ERE on a 4 MiB string is untested here.

**Recommendation:** Update the override row's price (4-5 ms per file, 80 files in /workspace) when it is next touched. No change before merge.

## Deferred items re-checked

- **blocker per directory prefix (main_imports):** the cost is unchanged by e1654266. The `.git` skip and the `~/` home and homer pair add at most one candidate per token, and the `pok` memo still stops at the first checked parent. The clean-clone main walk moved from 0.85-0.91 s to 1.23-1.37 s, and that increase is the per-file fixed cost (F4), not blocker forks.
- **@-less lines:** unchanged. A 4 MiB file with no `@` takes 0.61 s in 1,000-byte lines and 0.68 s as one line.
- **UTF8_OK gate worst case:** 0.79 s on one 4 MiB line of `é`, 0.09-0.12 s on 1,000-character lines, and 0.004 s to reject (it exits at the first bad line). With an invalid byte the text is doubled and python3 runs: a 4 MiB file of `@a\xff ` tokens took 9.06 s, rc=0. That is the worst depth-0 shape I found that still succeeds. Depth multiplies it as in F1.
- **Other bounds:** one 20,000-character token trips IMPORT_LEFT in 0.14 s. `<!---->` repeated 590,000 times on one line trips the splice work bound in 0.6 s. 2M bare `@ ` tokens finish in 0.92 s (no emit, no work).

## Endorsements

- The UTF8_OK gate keeps python3 off well-formed text: the gate costs 1.2 ms against python3's 6.85 ms per file, on 77 of 80 walked files in /workspace, which saves about 0.45 s per walk. Stage 1 r3 41 notes that the gate's removal survives the suite (time only). `[unverified — submitted as claim]` Location: `scripts/lib/dev-cycle-read.sh:622`
- The branch's worst case is orders of magnitude below main's: 14,000 `@a` tokens took 0.02 s against main's 15.36 s (one `realpath` fork per token), and every depth-0 4 MiB shape I tried finished in 9.1 s or less. `[unverified — submitted as claim]` Location: `scripts/lib/dev-cycle-read.sh:611-634`
- The 4 MiB head cap bounds the tree walk's read per file. Each run read at most 4,194,305 bytes, whatever the file size. `[unverified — submitted as claim]` Location: `scripts/lib/dev-cycle-read.sh:669`
- The 50M work bound turns a 15 s success into a 0.49 s failure on repeated long tokens (F2 shape). `[unverified — submitted as claim]` Location: `scripts/lib/dev-cycle-read.sh:536`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Work bound ignores per-emit resolution cost: depth-50 4 MiB file takes 22-59 s and succeeds, no cross-file bound | Low | `scripts/lib/dev-cycle-read.sh:535-562` | High |
| F2 | emit's 50M work bound is untested (mutant: 15 s success against 0.49 s failure) | Low | `scripts/lib/dev-cycle-read.sh:536`; `test/scripts/build-loop-check.bats:383-388` | High |
| F3 | import_home forks getent per file with HOME unset (+0.25-0.35 s at 80 files) | Informational | `scripts/lib/dev-cycle-read.sh:604-613` | High |
| F4 | Per-file fixed cost now 4-5 ms (the whole /workspace gap), above the Won't-Fix row's "+2 ms" | Informational | `scripts/lib/dev-cycle-read.sh:611-634, 669` | High |

## Overall Assessment

The unit's cost against main is a fixed 4-5 ms per walked file, from the forks for the sed step, the gate and the parser plus the per-file head and lower. It shows up as +0.25-0.4 s in the worktree and the clone (45 files) and +0.45-0.6 s in /workspace (80 files, 35 of them ignored devcontainer files). That fully explains r3's gap. It is acceptable on a once-per-process CLI path. The pathological ceiling is far better than main's, which was unbounded at one fork per token. The one real gap is F1: the work bound does not charge the directory-depth factor of `put`, so a deep start file can run for minutes and still print `ok`. That contradicts the comment's "fails the walk rather than stalling it". It fails closed in the sense that matters (no `ok` while stalled), and it is a small in-place fix (memoise `put` on `c`, or charge the depth). F2 is the matching test gap. Neither blocks merge on performance grounds alone. I would fix F1 in place or route it with F2 to U2a3c, which builds the shared capped reader. No further profiling is needed.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: e1654266` line at the top.
- **Answered:** the whole-unit cost against main (interleaved, 3+ runs in /workspace, the worktree and a clean clone at e1654266), with the gap explained per step; import_home's per-file getent with HOME unset (F3, measured); the UTF8_OK gate's cost and worst case; the worst-case inputs (F1: depth-weighted emits that run long and succeed; the bounds that do trip: work, IMPORT_LEFT, splice); the deferred items (blocker per prefix, @-less lines): cost unchanged.
- **Out of scope:** the main walk's uncapped blob read (routed to U2a3c; F1 notes only that it shares the depth factor); correctness of the superset (Stage 1).
- **Escalate:** F1 contradicts the stated premise of the bound (`:526-529`), so the orchestrator should decide between fix-in-place and routing to U2a3c.
- **Decisions I made:** I rated F1 Low rather than Medium because it is cold-path, fail-closed (no `ok` while stalled) and a large improvement on main's worst case. I treated F4 as new pricing evidence for an existing Won't-Fix row, not a re-raise.
