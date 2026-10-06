Commit: 7697c6e6

# Performance Review — feat/build-loop-u2a2 (U2a2, iteration 3, final confirming pass)

**Scope:** net branch diff `git diff main...HEAD` (main 20347279, HEAD 7697c6e6): `scripts/lib/dev-cycle-read.sh` (import_targets, UNI_SPACES, instruction_names, untracked_md, inrepo_here, imported_names, isimported) and `scripts/dev-cycle.sh` check_fix
**Date:** 2026-10-06
**Based on:** Stage-1 fact-check summary (k=3 at 7697c6e6, replicates `code-fact-check-report-build-loop-u2a2-f-r{1,2,3}.md`); override-log rows 346, 355 (settled, cited not re-filed)
**Legibility-target:** for-orchestrator-synthesis

All numbers in this report were measured on 2026-10-06 in this worktree. The worktree has 2,954 tracked files, and 45 of them pass `instruction_names`; those 45 start files hold 3 import tokens in total. Timings came from bash `$EPOCHREALTIME` with `LC_ALL=C` (the host has no en_US.UTF-8 locale, so bash ran in C anyway). Each figure is 2-5 runs. The lib versions were `git archive` copies of HEAD and main under `/tmp/u2a2f-perf-8i7k/`, and the scripts are in `/tmp/u2a2f-perf-8i7k/s/` (`walk.sh`, `parts.sh`, `tok.sh`, `cf.sh`, `syn.sh`). The synthetic repo `syn/` is one `AGENTS.md` importing n empty `docs/fN.md` files, with a token suffix of none, `.` or `)`. The host was noisy: load average 4.4 on 16 cores during the n=300/500 runs, which produced outliers of 5-7 s. The n=100 runs and the repo runs were stable. Every process ran under `timeout`, and none remains. The listed bats suites gave 100/100 ok and 0 `not ok` at HEAD, in 42 s.

## Data Flow and Hot Paths

- **`check_fix`** (`scripts/dev-cycle.sh:170-183`) runs once per `--check-fix` argument. The cheap string arms come first. Only a path that survives them reaches `isimported tree "$lp"` (`:180`), which runs the walk once per process and caches it (`IMPORTED_DONE`, lib `:494`). **Path temperature: cold.** It is a CLI check run by the dev cycle for each proposed in-cycle fix, a handful of paths per cycle.
- **`imported_names`** (lib `:491-508`) has three phases:
  1. One `git ls-files -z` plus `untracked_md`, piped through the `instruction_names` grep.
  2. A start loop: one `lower` fork and one `inrepo_here` per name. `inrepo_here` forks a `$(blocker)` subshell, and blocker forks `realpath` once per existing path component plus once for the file.
  3. A queue walk: one `import_targets` call per file reached.
- **`import_targets`** (lib `:468-482`) runs one `env grep -aoE` per file. Per token, it does:
  1. 19 in-shell `${t%%"$u"*}` cuts (UNI_SPACES).
  2. An in-shell trailing-punctuation strip.
  3. **One `realpath` fork per emitted name.** A token ending in `. , ; : ! ? * _ ~` emits two names, the whole one and the stripped one (`:474-479`).

  Back in `imported_names`, every emitted name costs one `lower` fork (`:504`) and, unless it was already seen, one `inrepo_here` (`:505`).

Measured:

| What | HEAD 7697c6e6 | main 20347279 |
|---|---|---|
| `imported_names`, this repo (`walk.sh`) | 366-418 ms | 396-475 ms |
| listing + `instruction_names` (45 names) | 5-6 ms | |
| start loop (`lower` + `inrepo_here` x45) | 250-256 ms (~5.6 ms/start file) | |
| `import_targets` over the 45 start files | 59-63 ms (bare `grep` alone: 39-71 ms) | |
| `isimported tree`, cached, per call | 1.8-3.1 ms | |
| UNI_SPACES cut loop, per token (in-shell) | ~30 µs (6 ms / 200 tokens) | absent |
| `realpath` fork / `lower` fork | ~0.6 ms / ~1.0 ms | |
| `import_targets`, 200 plain tokens / 200 `.`-ended tokens (`tok.sh`) | 205-213 ms (200 names) / 391-415 ms (400 names) | |
| `--check-fix scripts/foo.sh` (early skip, full script) | 14-16 ms | 420-458 ms |
| `--check-fix docs/thoughts/x.md` (reaches the walk) | 382-443 ms | 397-413 ms (one 5,275 ms outlier) |
| `--check-fix` with 10 docs/thoughts paths | 474-525 ms | 474-512 ms |
| synthetic, n=100, plain tokens | 594-628 ms | 694-805 ms |
| synthetic, n=100, `.`-ended tokens | 1,034-1,088 ms (200 IMPORTED lines) | 727-776 ms (100 lines) |
| synthetic, n=100, `)`-ended tokens | 594-614 ms | 694-761 ms |

## Findings

#### Each punctuation-ended import token now costs about twice the forks: one more realpath, lower and inrepo_here for the whole name

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:474-479`, `scripts/lib/dev-cycle-read.sh:503-505`
**Move:** Count the hidden multiplications
**Classification:** Micro (a fixed ~4 ms of extra forks per punctuation-ended token) / Cold path (once per `--check-fix` process, cached across its arguments)
**Confidence:** High
**Baseline:** synthetic repo, one AGENTS.md importing 100 files. `imported_names` took 1,034-1,088 ms with `.`-ended tokens and 594-628 ms with plain tokens at HEAD, and 727-776 ms with `.`-ended tokens on main (`/tmp/u2a2f-perf-8i7k/s/syn.sh` + `walk.sh`, 2026-10-06). `import_targets` alone took 391-415 ms vs 205-213 ms for 200 tokens (`tok.sh`).

**Evidence:**
```
    v="$t"; while [[ "$v" == *[.,\;:!?*_~] ]]; do v="${v%?}"; done
    for t in "$t" "$v"; do
      [[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue
      p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)" || continue
      [[ "$p" != .. && "$p" != ../* ]] || continue
      printf '%s\n' "$p"
      [[ "$v" != "$t" ]] || break
    done
```
```
    while IFS= read -r p; do
      IMPORTED+="$(lower "$p")"$'\n'
      if [[ "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo_here "$p"; then seen+="$p"$'\n'; queue+=("$p"); fi
```

The kept-and-stripped double emission is deliberate: either reading should refuse (settled row 356). Its cost is that the whole name pays a second `realpath` fork in `import_targets`, a second `lower` fork, and an `inrepo_here` probe. That probe is a `$(blocker)` subshell plus a `realpath` for each existing parent directory. Usually the whole name (`docs/f0.md.`) does not exist, so it never enters `seen`. A repeated punctuation-ended token therefore re-probes it every time, because nothing caches a negative answer. The net is about +4.4 ms per such token, 1.7x the plain-token walk, and it scales with the number of tokens, not with tree size. In this repo the 45 instruction files hold 3 tokens, none of them punctuation-ended, so the cost here is zero. A token-heavy instruction file (many `@decorator.` or `@user,` mentions in prose or code spans) would pay about 4 ms per token: about 2 s per `--check-fix` process at 500 such tokens (extrapolated from n=100; speculative above that). The settled rows already cover the same fork-per-item shape: row 355 for the per-edge `lower`, row 346 for batching. This finding adds only the doubling factor for the record.

**Recommendation:** No change in U2a2. When the row 346 / row 355 rework fires, batch the work. `realpath -ms --relative-to=` accepts many operands, so `import_targets` can resolve all of a file's names in one call. Lower `IMPORTED` with one `tr` after the queue drains. Skip `inrepo_here` for a name already probed and found absent. Those three changes make a file cost O(1) forks instead of O(tokens).

## Endorsements

- At HEAD, `check_fix` reaches the tree walk only through `isimported tree` after its string arms. An early-refused path took 14-16 ms on the whole script against 420-458 ms on main, and a path that reaches the walk timed the same on both (382-443 ms vs 397-413 ms). [read: scripts/dev-cycle.sh:170-183, scripts/lib/dev-cycle-read.sh:491-522]
- `inrepo_here` drops the per-path `need_root` (a `$(pwd -P)` subshell) from both walk loops. On this repo the walk measured 366-418 ms at HEAD against 396-475 ms on main, and 594-628 ms against 694-805 ms on the plain n=100 synthetic. That is consistent with one fewer fork per start file and per target. [unverified — submitted as claim]
- The UNI_SPACES cut is 19 in-shell parameter expansions per token, about 30 µs per token (6 ms for 200 tokens), with no fork. Adding it cost nothing measurable. [unverified — submitted as claim]
- The walk runs once per process, however many arguments `--check-fix` gets: 10 arguments took 474-525 ms against 382-443 ms for one argument, about 9 ms per extra argument including `check_path`. A cached `isimported tree` call took 1.8-3.1 ms. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A punctuation-ended token doubles the per-token forks (realpath, lower, inrepo_here): +4.4 ms per token, 1.7x on a 100-import synthetic, 0 here (no such tokens) | Informational | `scripts/lib/dev-cycle-read.sh:474-479, :503-505` | High |

## Overall Assessment

On performance, this branch is fine to merge at its final state. Moving main_imports to U2a3 removed iteration 2's only Low finding, the bash loop over every tree record, from this unit. What remains is the tree walk, which costs the same as on main or slightly less (366-418 ms vs 396-475 ms here). `check_fix` keeps its early-skip speedup, about 15 ms instead of about 430 ms. The walk is dominated by the per-start-file `lower` + `inrepo_here` forks (~250 ms of ~390 ms), which this branch did not change and which scale with instruction-file count, not with tree size. The token rules added this round cost nothing measurable for spaces (UNI_SPACES is in-shell). Punctuation-ended tokens pay a doubling, recorded above as Informational. It folds into the existing row 346/355 batching rework rather than needing a new decision. No further profiling is needed before merge. One forward note: the fact-check's E1 fix (an `@` after a UNI_SPACES character) will probably add one stream transform per file before the grep. At ~1 ms per process that is negligible, provided it is one process per file and not per token.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7697c6e6` as its first line."
- **Answered:** a performance review of the net diff at 7697c6e6, covering import_targets' per-token loop (UNI_SPACES cut, double emission), the tree walk and check_fix's call to `isimported tree`. It was measured on this repo against main's scripts and on a synthetic repo with 100-500 imports.
- **Out of scope:** correctness of the token rules (fact-check E1, E2 and the `[` comment belong to Stage 1 and security); main_imports (U2a3); settled rows 346, 355 and 356, which are cited, not re-filed. Neither trigger has fired: this repo walks ~48 files, against row 355's trigger of 1,000+ walked files.
- **Escalate:** none.
