Commit: 7697c6e6

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a2 (branch feat/build-loop-u2a2)
**Scope:** Stage 2.5 submitted claims only, from the five final-pass critic reports dated 2026-10-06 for build-loop-u2a2. No claims were harvested here; the harvested claims are Claims 1-10 of `docs/reviews/code-fact-check-report-build-loop-u2a2-final.md`.
**Checked:** 2026-10-06
**Total claims checked:** 6
**Summary:** 4 verified, 1 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Sweep result: `security-reviewer` routed 2 claims (`route: code-fact-check`). `performance-reviewer` submitted 3 claims (`[unverified — submitted as claim]`) plus 1 `[read:]`-tagged endorsement. `api-consistency-reviewer`, `architecture-review` and `test-strategy` submitted nothing: their "What Looks Good" items carry no route tag, no `[unverified]` tag and no `[read:]` tag. `security-reviewer`'s third Endorsement Claim (the `check_fix` superset claim at `scripts/dev-cycle.sh:177-183`) has no `route:` line, so it is not verdicted here.

Execution provenance: all runs used cwd `/tmp/u2a2f-subfc-Qrx0` or the scratch repos below it. `head/` and `main/` are `git archive` copies of 7697c6e6 and main (20347279). `r-head/` and `r-main/` are those trees committed into fresh git repos. `syn/` is a synthetic repo with an AGENTS.md that imports 100 plain files. The probe scripts sit next to their logs. Timestamps are UTC. Wall-clock timings on this WSL2 host are noisy: one EPOCHREALTIME run showed negative intervals (`timing2.log`). The timing verdicts therefore rest on the CPU and median figures in `timing3.log` and on the in-process `walk.log`.

---

## Submitted Claims

## Claim 11: "At HEAD, `check_fix` reaches the tree walk only through `isimported tree` after its string arms. An early-refused path took 14-16 ms on the whole script against 420-458 ms on main, and a path that reaches the walk timed the same on both (382-443 ms vs 397-413 ms)."

**Submitted by:** performance-reviewer (endorsement tagged `[read: scripts/dev-cycle.sh:170-183, scripts/lib/dev-cycle-read.sh:491-522]`)
**Location:** `scripts/dev-cycle.sh:170-183`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of `check_fix`'s arms at HEAD against main, and the whole-script cost of an early-refused path and of one walk-reaching path on this repo's tree. It does not establish the exact millisecond figures on another host, the cost on a token-heavy tree, or any caller of the walk other than `check_fix`. The only other callers at HEAD are the tests.

I read `check_fix` in full at HEAD. The walk is reached only from the last `elif`, after the glob, `pathform`, `writable` and documentation-scope arms:

```bash
# scripts/dev-cycle.sh:177-183
  if writable "$a" || writable "$lp"; then echo "skip $a: one of the cycle's own files (use --check-write)"
  elif [[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|human-author|reviews|decisions)/ \
  ...
  elif isimported tree "$lp"; then
    echo "skip $a: an instruction file imports it with @ ..."
  else check_path "$a"; fi
```

On main the walk ran unconditionally, before any arm:

```bash
# main:scripts/dev-cycle.sh:176-178
  low="${lp##*/}"
  imported_names
  if writable "$a" || writable "$lp"; then ...
```

`rg -n "imported_names|isimported"` over `scripts/` finds no other runtime caller. The hits are `scripts/dev-cycle.sh:181` and `scripts/lib/dev-cycle-read.sh:519`.

Executed: `timeout 500 bash /tmp/u2a2f-subfc-Qrx0/timing3.sh` at 2026-10-06T22:20:57Z, exit 0, 11 runs per row:

```
head early-refused             wall med   19 (p25-p75 17-19)   cpu med   18
head walk-reaching 1 arg       wall med  489 (p25-p75 467-532) cpu med  366
main early-refused             wall med  445 (p25-p75 438-491) cpu med  335
main walk-reaching 1 arg       wall med  541 (p25-p75 485-586) cpu med  426
```

The early-refused path (`docs/working/x.md`) skips the walk at HEAD: 17-19 ms against 438-491 ms. The walk-reaching path (`docs/thoughts/failure-patterns.md`) costs about the same on both, with HEAD slightly lower (see Claim 15 for why). This reproduces the submitted figures in magnitude.

**Evidence:** `scripts/dev-cycle.sh:170-183`, `scripts/lib/dev-cycle-read.sh:514-522`, `/tmp/u2a2f-subfc-Qrx0/timing3.log`, `/tmp/u2a2f-subfc-Qrx0/timing3.sh`

---

## Claim 12: "In the shapes executed, `import_targets` yields every name Claude Code 2.1.292 resolves for: blanks, CR, VT, `#` fragments, backtick code spans, `\_` escapes, trailing `. , ; : ! ? * _ ~`, the 19 UNI_SPACES characters ending a token, ASCII controls and U+0085 (read as part of a token on both sides), and `..x` names. The exceptions are F1's inline-token stops, E1 and the deferred `\ `."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:452-482`
**Type:** Behavioral / Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the walk side only: what `import_targets` emits for each listed shape, plus the named exceptions E1 and `\ `. It does not establish the Claude Code side (which names CC 2.1.292 resolves for each shape), so it does not establish the subset relation the claim asserts. Execution on the CC side was blocked, as described below.

I read `import_targets` in full (`:468-482`) and ran it on each listed shape with directory `docs`: `timeout 60 bash /tmp/u2a2f-subfc-Qrx0/probe1.sh` at 2026-10-06T22:18:58Z, exit 0. Walk-side results from `probe1.log`:

- Blank, tab+CR and VT stops, `#x` fragments and backtick spans all give `docs/x.md`. `[:space:]` in the C locale includes `\r` and `\v`, and `#` and the backtick are in the excluded set of `IMPORT_RE='(^|[^[:alnum:]])@[^][:space:]\\#`()]+'` (`:456`).
- `@x\_y.md` gives `docs/x` (the token stops at `\`).
- Trailing `. , ; : ! ?`, `**…**`, `_…_` and `~~…~~` each give both the whole name and the stripped one, for example `docs/x.md. docs/x.md` and `docs/x.md** docs/x.md`, per `:473-479`.
- All 19 UNI_SPACES entries end the token (`docs/x.md` for each `@x.md<sp>tail`). `${#UNI_SPACES[@]}` is 19 (`walk.log`).
- `\x01` and U+0085 stay inside the token (one name, `docs/x?y.md`).
- `@..x.md` gives `docs/..x.md`, and `@../up.md` gives `up.md` (dropped only at the repo top, per `:477`).
- Exceptions reproduce on the walk side. E1: `@a.md<NBSP>@b.md` gives only `docs/a.md`. `\ `: `@my\ notes.md` gives `docs/my`.

So the walk-side half of the claim holds for every listed shape. Two extra walk-side facts are relevant to F1's class rather than to this claim: `@x.md[y]` gives `docs/x.md[y`, because `[` is not in `IMPORT_RE`'s excluded set (the Stage-1 `[` comment item), and `@x.md(y)` gives `docs/x.md`.

The Claude Code half could not be re-executed. The claim rests on the reviewer's harness, which emulates CC's `reo()` over marked bytes extracted from the 2.1.292 bundle. A first-hand read of the installed binary (`claude --version` → `2.1.292`) confirmed that its import regex is `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` with a `#` cut, matching the harness's first line. My further reads of the bundle and of the reviewer's harness inputs were refused by the session's permission classifier, so the CC-side sets per shape are not independently established here. Whether marked splits `\_` into a separate `escape` token, which decides the `\_` row, is the main open point.

**Evidence:** `scripts/lib/dev-cycle-read.sh:450-482`, `/tmp/u2a2f-subfc-Qrx0/probe1.sh`, `/tmp/u2a2f-subfc-Qrx0/probe1.log`

---

## Claim 13: "The UNI_SPACES cut is 19 in-shell parameter expansions per token, about 30 µs per token (6 ms for 200 tokens), with no fork. Adding it cost nothing measurable."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:472`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cut's structure (19 expansions, no fork) and its per-token cost in a 1000-iteration microbenchmark on this host. It does not establish the cost of the rest of the per-token loop (the `realpath` and `lower` forks dominate), or the cost on a host other than this WSL2 machine.

The cut is one loop of parameter expansions over the array, with no command substitution:

```bash
# scripts/lib/dev-cycle-read.sh:472
    for u in "${UNI_SPACES[@]}"; do t="${t%%"$u"*}"; done
```

The array `:453-455` has 19 entries (`UNI_SPACES entries=19` in `walk.log`), and the loop runs once per grep match (`:470-481`), so there are 19 expansions per token and no fork.

Executed: `timeout 60 bash /tmp/u2a2f-subfc-Qrx0/walk.sh head <repo>`, 10 runs at 2026-10-06T22:22:32Z, exit 0, with the same loop timed over 1000 tokens. The figure was `UNI_SPACES cut per token us=` 38, 40, 40, 41, 42, 43, 49, 53, 38, 40. That is about 40 µs per token (8 ms for 200), not about 30 µs. Every run was above 30. Against a cold walk of 382-547 ms on this repo (same log), the cut is still unmeasurable, so "cost nothing measurable" holds. The figure to tighten is "about 30 µs" to "about 30-50 µs (host-dependent)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:453-455`, `scripts/lib/dev-cycle-read.sh:470-481`, `/tmp/u2a2f-subfc-Qrx0/walk.sh`, `/tmp/u2a2f-subfc-Qrx0/walk.log`

---

## Claim 14: "The walk runs once per process, however many arguments `--check-fix` gets: 10 arguments took 474-525 ms against 382-443 ms for one argument, about 9 ms per extra argument including `check_path`. A cached `isimported tree` call took 1.8-3.1 ms."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:494`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one `--check-fix` process with ten arguments on this repo's tree: one walk, and the per-argument and cached-call cost in magnitude. It does not establish caching across processes (there is none), behavior when `ROOT_REAL` changes within a process (the cache is keyed on it and recomputes), or exact timings on another host.

The cache is keyed on the root:

```bash
# scripts/lib/dev-cycle-read.sh:494
  [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return; IMPORTED_DONE="$ROOT_REAL"; IMPORTED=$'\n'
```

`isimported` runs in the caller's shell (`scripts/dev-cycle.sh:181`, a plain `elif`, not a subshell), so the cache survives from one argument to the next.

Executed: `timeout 120 bash /tmp/u2a2f-subfc-Qrx0/trace10.sh` at 2026-10-06T22:23:58Z, exit 0. This runs the scrubbed child (`DEV_CYCLE_SCRUBBED=1 bash -x scripts/dev-cycle.sh --check-fix` with 10 tracked docs paths). The trace shows `walk starts (IMPORTED_DONE=<root> assignments): 1` and `isimported tree calls: 9`; `docs/roadmap.md` was refused earlier as a cycle file. The single assignment is at `xtrace10.err:253`, and the later 8 `imported_names` calls return at the cache test.

Timing (`timing3.log`, 11 runs): 10 arguments gave a wall median of 586 ms (p25-p75 577-625) against 489 ms (467-532) for one argument. That is about 10-11 ms per extra argument, close to the submitted "about 9 ms". The in-process cached `isimported tree` call (`walk.log`, mean of 20 calls per run) measured 2.5-5.0 ms with a median of about 3.0 ms. That overlaps the submitted 1.8-3.1 ms. The cost is the `need_root` `$(pwd -P)` and the `lower` pipeline in `isimported` (`:516-517`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:491-522`, `scripts/dev-cycle.sh:181`, `/tmp/u2a2f-subfc-Qrx0/trace10.sh`, `/tmp/u2a2f-subfc-Qrx0/trace10.log`, `/tmp/u2a2f-subfc-Qrx0/xtrace10.err`, `/tmp/u2a2f-subfc-Qrx0/timing3.log`, `/tmp/u2a2f-subfc-Qrx0/walk.log`

---

## Claim 15: "`inrepo_here` drops the per-path `need_root` (a `$(pwd -P)` subshell) from both walk loops. On this repo the walk measured 366-418 ms at HEAD against 396-475 ms on main, and 594-628 ms against 694-805 ms on the plain n=100 synthetic. That is consistent with one fewer fork per start file and per target."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:496`, `scripts/lib/dev-cycle-read.sh:505`
**Type:** Performance / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the swap from `inrepo` to `inrepo_here` at both walk call sites, the resulting `need_root` call count, and the direction of the walk-time change on this repo and on a 100-import synthetic. It does not establish the submitted millisecond ranges, which this host reproduced only in direction. It also does not establish that `need_root`'s guard still runs once per walk on every path into the walk; it does, from `imported_names:493`, which is the only entry.

The two walk loops call `inrepo_here`, which has no `need_root`:

```bash
# scripts/lib/dev-cycle-read.sh:121-124
inrepo() { need_root; inrepo_here "$1"; }
# inrepo for a caller that has run need_root itself (a walk, per path); it has
# no need_root of its own.
inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }
```

The calls are at `:496` (`|| ! inrepo_here "$f"; then continue; fi`) and `:505` (`&& inrepo_here "$p"; then seen+=...`). On main both sites called `inrepo` (`main:scripts/lib/dev-cycle-read.sh:456` and `:477`). `need_root`'s second test is `[[ "$ROOT_REAL" == "$(pwd -P)" ]]` (`:93`), the subshell named in the claim.

Executed: `walk.sh` wraps `need_root` with a counter and times one cold `imported_names` in-process. It ran 5 rounds at 2026-10-06T22:22:32Z, exit 0:

```
head walk_ms=382..547  need_root_calls=1   (this repo)
main walk_ms=469..758  need_root_calls=49  (this repo)
syn head walk_ms=638..1151 need_root_calls=1
syn main walk_ms=896..3629 need_root_calls=102
```

The call counts confirm the mechanism exactly. On main they are 1 + one per start file + one per reached target (49 here; 102 on the synthetic, which has 1 start file and 100 targets). At HEAD the count is 1. In every round HEAD's walk was faster than main's on both trees, but this host's ranges are wider than the submitted ones (WSL clock noise; see the header note).

**Evidence:** `scripts/lib/dev-cycle-read.sh:91-95`, `scripts/lib/dev-cycle-read.sh:121-124`, `scripts/lib/dev-cycle-read.sh:491-508`, `/tmp/u2a2f-subfc-Qrx0/walk.sh`, `/tmp/u2a2f-subfc-Qrx0/mksyn.sh`, `/tmp/u2a2f-subfc-Qrx0/walk.log`

---

## Claim 16: "For any walk name other than `tree`, `isimported` returns 0 (imported) under `if`. With `tree`, it returns 0 exactly when the lower-cased path is a line of `IMPORTED`."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:514-522`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `isimported`'s two arms at 7697c6e6 for the walk names `tree`, `main`, `bogus` and the empty string, and for mixed-case paths. It does not establish U2a3's future `main` arm or its floor caller (not on this branch), or behavior when `need_root` fails (it exits the process rather than returning).

The whole function:

```bash
# scripts/lib/dev-cycle-read.sh:514-522
isimported() {
  local lp
  need_root
  lp="$(lower "$2")"
  case "$1" in
    tree) imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
    *) return 0 ;;
  esac
}
```

`IMPORTED` is newline-delimited, starts with `$'\n'` (`:494`), and holds `lower`ed paths (`:504`), so the `tree` arm's test is exact line membership of the lower-cased argument.

Executed (`probe1.sh`, 2026-10-06T22:18:58Z, exit 0). The fixture is an AGENTS.md with `See @docs/A.md and @docs/b.md.` and a non-imported `docs/c.md`. Results: `tree` gives 0 for `docs/a.md`, `DOCS/A.MD` and `docs/b.md`, and 1 for `docs/c.md`. `main`, `bogus` and `''` give 0 for all four paths. `IMPORTED` was `|docs/a.md|docs/b.md.|docs/b.md|`. The suite run (`bats.log`, 2026-10-06T22:17:48Z, exit 0, 100/100) includes `ok 2 isimported answers imported under if for a walk name it does not know (U2a2)`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:494`, `scripts/lib/dev-cycle-read.sh:504`, `scripts/lib/dev-cycle-read.sh:514-522`, `test/scripts/build-loop-check.bats:41-45`, `/tmp/u2a2f-subfc-Qrx0/probe1.log`, `/tmp/u2a2f-subfc-Qrx0/bats.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:472`): the UNI_SPACES cut measured 38-53 µs per token on this host, not "about 30 µs" (8 ms, not 6 ms, per 200 tokens). The structural claim (19 expansions, no fork, unmeasurable against the walk) holds.

### Unverifiable
- **Claim 12** (`scripts/lib/dev-cycle-read.sh:452-482`): the walk-side outputs match every listed shape and both named exceptions. Establishing the subset relation needs the CC-side sets per shape: a re-run of the marked-based `reo()` emulation, or Claude Code 2.1.292 itself, on those 27 lines. Reading the bundle was refused in this session.
