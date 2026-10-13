Commit: 5583a2cd

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b3 (branch feat/build-loop-u3b3), verified against a `git archive 5583a2cd` extract, not the live worktree
**Scope:** Stage 2.5 submitted claims 96-104 from the final security and performance reviews (and two from the i2 security review), checked against `test/lib/d6-snippet.bash`, `scripts/lib/dev-cycle-read.sh` (HARDEN, git_harden), `scripts/dev-cycle.sh` (lines 86-132) and `test/scripts/build-loop-orchestrator.bats`
**Checked:** 2026-10-12 (probes ran 2026-10-13T02:24Z-02:40Z UTC)
**Total claims checked:** 9
**Summary:** 9 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Agent tag `fc25`. Extract: `git -C /workspace/.claude/wt-build-loop-u3b3 archive 5583a2cd | tar -x -C /tmp/u3b3-fc25-m6jn`. All line numbers are the extract's (5583a2cd). Probe scripts are in `/tmp/u3b3-fc25-m6jn/probes/`, captured output in `/tmp/u3b3-fc25-m6jn/logs/` (abbreviated `$L` below). Each probe made its own `mktemp -d /tmp/u3b3-fc25{p,q,r,s}-XXXX` dir, checked `pwd -P` before any `git init`, and the dirs are removed. No process was left running (checked with `ps` afterwards). Fixtures used a hermetic git environment (`HOME` inside the temp dir, `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`). Where the snippet itself ran, only its two constants were replaced (`D6_ROOT`, `D6_OPT`), with the same `sed` the suite's `d6_copy` uses. The direct reader runs used the `P=` program extracted verbatim from the file (`P.pl`, 1599 bytes).

Executed runs (cwd `/tmp/u3b3-fc25-m6jn` for each):
- E0: `LC_ALL=C TMPDIR=$(mktemp -d /tmp/u3b3-fc25t-XXXX) timeout 900 bats test/scripts/build-loop-orchestrator.bats`, started 2026-10-13T02:24:04Z, exit 0, 20/20 ok, output `$L/bats.out`.
- P1: `timeout 300 bash probes/p1.sh`, 2026-10-13T02:37:13Z, exit 0, output `$L/p1.out`. Two earlier attempts timed out (exit 124) because of a fault in my probe, not in the snippet: my truncating git shim (`head -c 300`) waited on a full block and deadlocked the pipe. The final run uses a byte-wise `sysread` truncator instead.
- P2: `timeout 120 bash probes/p2.sh`, 2026-10-13T02:38:17Z, exit 0, output `$L/p2.out`.
- P3: `timeout 280 bash probes/p3.sh`, 2026-10-13T02:39:07Z, exit 0, output `$L/p3.out`. A first run at 02:38:46Z gave the same memory figures, but its answer column printed the wrong line.
- P4: `timeout 280 bash probes/p4.sh`, 2026-10-13T02:39:35Z, exit 0, output `$L/p4.out`. It used a `--shared --no-checkout` clone of /workspace (main 27cedb99, 1,122 first-parent commits), so nothing was written to /workspace.

## Submitted Claims

## Claim 96: "After the starting commit id, every id the reader follows and every byte it writes to $t/scripts/ comes from object bytes whose SHA-1 equals the requested id; no other git reader supplies an id."

**Submitted by:** security-reviewer (final, `docs/reviews/security-review-2026-10-12-u3b3-final.md:79-84`)
**Location:** `test/lib/d6-snippet.bash:58-71`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers where each id and each written byte comes from inside the `P=` program and the bash lines that feed it (`:54`, `:78`), including the critic's untested layout (packed copy forged, loose copy real). It does not establish that those ids mean what git means: a late `parent` header that git's parser would ignore is still followed, and the `$c ne $root` meaning (r1's escalation) is a separate question. It also does not establish SHA-1 collision resistance: Digest::SHA is plain SHA-1, not git's collision-detecting sha1dc.

`obj()` returns bytes only after `die "$id does not hash to its id\n" unless sha1_hex("$t $s\0$b") eq $id; return $b` (`test/lib/d6-snippet.bash:62`), and `$t eq $want` is required on `:61`, so the hashed type is the requested one. Each next id comes from returned bytes:
- the walk: `$tree //= $hd =~ /\Atree ([0-9a-f]{40})\n/ ? $1 : die` and `my ($p) = $hd =~ /^parent ([0-9a-f]{40})$/m; ... $c = $p` (`:65-66`), where `$hd` is the header of `obj($c, "commit")`;
- tree entries: `return unpack("H*", $id)` from `$b = obj($t, "tree")` (`:63-64`);
- the written bytes: `my $b = obj(entry($t, $n, qr/\A100(644|755)\z/), "blob"); open(my $fh, ">", "$out/scripts/$f") ... print $fh $b` (`:70`).

On the bash side, the only id passed in is `$sha` from `sha="$(g rev-parse --verify -q "refs/heads/$m")"` (`:54`). That is the starting id the claim excludes. `g cat-file -t "$sha"` on the same line checks the type and supplies no id. Once the reader prints `main`, the run uses `d="$t"` (`:80-81`).

Executed:
- E0 tests 11, 13 and 14 pass. Test 11 includes a git shim whose `--batch` output alters one word, and the snippet refuses with "does not hash to its id".
- P1 section B is the critic's not-verified case. The probe packed a one-object pack holding a blob that prints `echo PLANTED` and renamed its idx entry to the id of main's real, loose `scripts/build-loop.sh` (f091ce5c...). `git cat-file -p` then printed `echo PLANTED`, so git serves the packed copy first. The snippet printed `refuse d6: main's first-parent history, ... or an object does not hash to its id`, stderr `f091ce5c... does not hash to its id`, and exited 2. The planted bytes did not run.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/lib/d6-snippet.bash:54`, `test/lib/d6-snippet.bash:58-71`, `test/lib/d6-snippet.bash:78-81`, `test/scripts/build-loop-orchestrator.bats:245-268`, `/tmp/u3b3-fc25-m6jn/logs/p1.out`, `/tmp/u3b3-fc25-m6jn/logs/bats.out`, `/tmp/u3b3-fc25-m6jn/probes/p1.sh`

---

## Claim 97: "Any reader failure (missing object, short read, hash mismatch, git died, unwritable output) makes the snippet print `refuse d6:` and exit 2, never fall to the image copy; a perl exit 0 without `main` or `other` also refuses."

**Submitted by:** security-reviewer (final, `docs/reviews/security-review-2026-10-12-u3b3-final.md:85-90`)
**Location:** `test/lib/d6-snippet.bash:61-62`, `:78`, `:86`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each failure the claim lists, plus perl killed by SIGKILL. All were run against the whole snippet except unwritable output, which ran against the extracted reader alone. A failure there gives a non-zero status that feeds the same `|| no` arm. It does not cover a git or perl that hangs without failing: a stalled reader stalls the snippet, which has no timeout of its own.

The bash side refuses on any non-zero status: `x="$(LC_ALL=C perl -e "$P" ...)" || no "$m's first-parent history, ..."` (`test/lib/d6-snippet.bash:78`). It also refuses on any word other than the two answers: `if [[ "$x" == main ]] ... elif [[ "$x" == other ]] ... else no "the verified reader gave no answer"; fi` (`:80-86`). `no` is `echo "refuse d6: $*"; exit 2` (`:39`), called in the main shell, not in a subshell.

Executed in P1, with each run's output in `$L/p1.out`:
- **Hash mismatch** (section B): exit 2 with the refuse line.
- **perl exiting 0 with no output, and printing `mainx`** (section C, PATH shims): both gave `refuse d6: the verified reader gave no answer`, exit 2.
- **perl killed by SIGKILL**: exit 2 with the reader refuse line.
- **git exiting at once on `--batch`** (section D): exit 2.
- **git output cut at 300 bytes** (section D): exit 2, stderr `a358ca35... is not a whole commit`.

Direct runs of the reader (section E):
- A missing id gave exit 255, `... is not a whole commit`.
- A read-only `scripts/` gave exit 13, `build-loop.sh: Permission denied`. That is errno, not 255, and still non-zero.

Git's answer for a missing id is `1111...1111 missing` (section F). It has no size field, so `defined $s` on `:61` fails. In every refusal the output is the reader's message, never an ownership refusal from the image branch (`:84-85`). E0 test 15 (a missing commit, a shallow clone) also passes. Every refused run left 0 entries in the private TMPDIR.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/lib/d6-snippet.bash:39`, `test/lib/d6-snippet.bash:60-62`, `test/lib/d6-snippet.bash:78-86`, `test/scripts/build-loop-orchestrator.bats:310-316`, `/tmp/u3b3-fc25-m6jn/logs/p1.out`, `/tmp/u3b3-fc25-m6jn/logs/bats.out`

---

## Claim 98: "The request/response loop with cat-file --batch cannot desynchronise (one 40-hex id + newline per request; name, type and decimal size checked; exactly size bytes read; trailing newline required)."

**Submitted by:** security-reviewer (final, `docs/reviews/security-review-2026-10-12-u3b3-final.md:91-95`)
**Location:** `test/lib/d6-snippet.bash:60-62`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers obj()'s protocol: one request in flight at a time, the format of each request, and every check on each answer. It does not establish that a forged size is harmless to git itself, or that a git which stalls mid-answer is detected (perl's `read` blocks until EOF).

Each request is `print $w "$id\n"`, and the next line is read only after it: `my $h = <$r>` (`:60`). The answer is accepted only if `defined $s && $i eq $id && $t eq $want && $s =~ /\A[0-9]+\z/ && read($r, $b, $s) == $s && getc($r) eq "\n"` (`:61`), after `chomp $h; my ($i, $t, $s) = split / /, $h, 3`. Requested ids are 40 hex characters:
- the first is `rev-parse --verify` output in a repository whose format was checked as sha1 (`:75-77`);
- later ids come from `([0-9a-f]{40})` (`:65-66`) or `unpack("H*", $id)` of a 20-byte field (`:64`).

The pipes are binary (`binmode $r; binmode $w; $w->autoflush(1)`, `:59`). Any failed check dies, so no later request is sent. Executed:
- P1 section F shows git's own `missing` answers for a missing id and a non-id. Neither has a size field, so they fail `defined $s`.
- The section D truncation stopped mid-object and was rejected as `not a whole commit`.
- P3's runs completed 1,000, 30,000 and 300,000 round trips in step and answered `main` each time.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/lib/d6-snippet.bash:59-66`, `test/lib/d6-snippet.bash:75-78`, `/tmp/u3b3-fc25-m6jn/logs/p1.out`, `/tmp/u3b3-fc25-m6jn/logs/p3.out`

---

## Claim 99: "In the image mode, own() runs on each of the four files and on every directory from `$D6_OPT/scripts/lib` up to `/`, and each check requires no symlink, owner uid 0 and `! -w` for the running uid."

**Submitted by:** security-reviewer (i2, `docs/reviews/security-review-2026-10-12-u3b3-i2.md:115-120`; the exact wording above)
**Location:** `test/lib/d6-snippet.bash:42`, `:84-85` (at i2 it was `:35`, `:71-72`)
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the set of paths own() checks and the four conditions it applies, on the real root-owned /opt copy and on a symlinked ancestor. It does not cover a filesystem that misreports ownership (FUSE, user namespaces) or root's `-w` on a read-only mount (the critic's not-verified items). It also does not cover files the image scripts might source beyond the four: build-loop.sh sources only `$READ_LIB`, at `scripts/build-loop.sh:442`.

own() is `[[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no ...` (`test/lib/d6-snippet.bash:42`). The image branch runs `for f in "${F[@]}"; do own "$d/scripts/$f"; [[ -f ... ]] || no ...; done`, then `x="$d/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done` (`:84-85`). `F` names the four files (`:46`).

Executed:
- P2's `bash -x` trace of the image path lists exactly the four files, then `/opt/claude-workflows/scripts/lib`, `/opt/claude-workflows/scripts`, `/opt/claude-workflows`, `/opt` and `/`.
- With `D6_OPT` set to a uid-owned symlink to /opt/claude-workflows, the snippet printed `refuse d6: .../optlink is not root-owned, a plain path and unwritable here` and exited 2. The four files were real and root-owned, and the walk still caught the symlinked ancestor.
- P1 section A2 ran the real /opt copy's `build-loop.sh --help`.
- E0 test 18 (a uid-owned image copy refused) passes.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/lib/d6-snippet.bash:42`, `test/lib/d6-snippet.bash:46`, `test/lib/d6-snippet.bash:82-85`, `scripts/build-loop.sh:442`, `/tmp/u3b3-fc25-m6jn/logs/p2.out`, `/tmp/u3b3-fc25-m6jn/logs/p1.out`, `/tmp/u3b3-fc25-m6jn/logs/bats.out`

---

## Claim 100: "dev-cycle.sh calls git_harden before its first git call, and the lib runs no git at source time." (The dispatch adds: questions.sh inherits it.)

**Submitted by:** security-reviewer (i2, `docs/reviews/security-review-2026-10-12-u3b3-i2.md:121-126`; the exact wording above)
**Location:** `scripts/dev-cycle.sh:94-132` (at i2 it was `:125-129`), `scripts/lib/dev-cycle-read.sh`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers dev-cycle.sh's own git calls, the lib's calls when sourced, and questions.sh's calls in the digest and `--check-brief` runs of test 20. It does not cover the scrub_reexec parent: that parent runs `bash` and `perl` (the scrub) unhardened before the child's git_harden, but it makes no git call (the critic's not-verified item). It also does not cover check modes that test 20 did not run.

Before `git_harden` (`scripts/dev-cycle.sh:131`), the script runs:
- `command -v perl` (`:94`);
- `SCRIPT_DIR="$(cd "$(dirname ...)" && pwd)"` (`:95`);
- `source "$READ_LIB"` (`:103`);
- `scrub_reexec "${BASH_SOURCE[0]}" "$@"` (`:104`), whose body is `DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" ... | scrub` and has no git (`scripts/lib/dev-cycle-read.sh:155-160`);
- the argument loop (`:109-124`). Its only external command is `sed` for `-h`.

The first git call is `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"` (`:132`). questions.sh inherits the exported environment: git_harden ends `export GIT_CONFIG_COUNT="$c" GIT_LITERAL_PATHSPECS=1 ...` (`scripts/lib/dev-cycle-read.sh:360`), and `scripts/questions.sh` contains no `env -i`, `unset` or `GIT_CONFIG` (grep, no match).

Executed:
- P2 sourced the lib under a logging git shim and recorded `calls while sourcing: 0`.
- E0 test 20 passes. Its shim logs every git call that dev-cycle.sh's `--check-brief` and `--since=2020-01-01` digest make (more than 10 calls, questions.sh's included, since the digest prints `## 3. Watched questions`). The test asserts that every call carries every HARDEN pair plus `G=/dev/null P=none S=1`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/dev-cycle.sh:94-132`, `scripts/lib/dev-cycle-read.sh:155-160`, `scripts/lib/dev-cycle-read.sh:349-361`, `test/scripts/build-loop-orchestrator.bats:363-380`, `/tmp/u3b3-fc25-m6jn/logs/p2.out`, `/tmp/u3b3-fc25-m6jn/logs/bats.out`

---

## Claim 101: "The reader's memory is constant in history length (peak RSS 7.2-7.7 MB from 1k to 300k first-parent commits)."

**Submitted by:** performance-reviewer (final, `docs/reviews/performance-review-2026-10-12-u3b3-final.md:91`)
**Location:** `test/lib/d6-snippet.bash:60-66`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the perl reader process's peak RSS (VmHWM) on linear histories of 1,000 to 300,000 commits with small objects. It does not cover the `git cat-file --batch` child's memory, or large trees and blobs, whose bytes `obj` holds whole: one object at a time, so memory scales with object size.

The walk keeps only `$c`, `$tree` and the current header: `my ($hd) = split /\n\n/, obj($c, "commit"), 2; ... $c = $p` (`:65-66`). P3 built fast-import histories and ran the extracted reader with an appended `END` block. That block only reads `/proc/self/status`. Results:

| First-parent commits | Answer | VmHWM | Wall time |
|---|---|---|---|
| 1,000 | `main` | 7,380 kB | 41 ms |
| 30,000 | `main` | 7,364 kB | 893 ms |
| 300,000 | `main` | 7,268 kB | 9,484 ms |

The earlier run gave 7,376, 7,272 and 7,444 kB. These fit inside the critic's 7.2-7.7 MB range.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/lib/d6-snippet.bash:60-66`, `/tmp/u3b3-fc25-m6jn/probes/p3.sh`, `/tmp/u3b3-fc25-m6jn/logs/p3.out`

---

## Claim 102: "The snippet's temp dir is removed on every run, main and other paths."

**Submitted by:** performance-reviewer (final, `docs/reviews/performance-review-2026-10-12-u3b3-final.md:92`)
**Location:** `test/lib/d6-snippet.bash:72-73`, `:87-88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers normal exits on the main and other paths, every refusal after the dir is made, and SIGTERM, SIGINT and SIGHUP sent to the snippet's shell while the script runs. It does not cover SIGKILL (nothing can clean up) or `mktemp` itself failing. In that case `no "mktemp failed"` exits before the trap is set and no dir exists.

The dir is made and trapped at once: `t="$(mktemp -d)" || no "mktemp failed"` then `trap 'rm -rf "$t"' EXIT` (`:72-73`). The script runs as a child, not via `exec`, and the snippet then calls `exit "$?"` (`:87-88`), so the EXIT trap fires.

Executed in P1, each with a private TMPDIR:
- 40 main-path and 40 other-path runs (the other path ran /opt's `build-loop.sh --help`) left 0 entries (section G).
- Every refusal in sections B to D left 0 entries.
- In section H, a main script of `sleep 3` was running with 1 temp entry present. After the snippet's bash got TERM, INT or HUP, 0 entries remained each time.

E0 test 11 also asserts `[ -z "$(ls -A "$TMPDIR")" ]` after main-path runs and a refusal.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/lib/d6-snippet.bash:72-73`, `test/lib/d6-snippet.bash:87-88`, `test/scripts/build-loop-orchestrator.bats:261`, `test/scripts/build-loop-orchestrator.bats:267`, `/tmp/u3b3-fc25-m6jn/logs/p1.out`

---

## Claim 103: "git_harden adds no forks and returns at once on a second call."

**Submitted by:** performance-reviewer (final, `docs/reviews/performance-review-2026-10-12-u3b3-final.md:93`)
**Location:** `scripts/lib/dev-cycle-read.sh:351-361`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers git_harden's own body, including its error branch, which uses only builtins. It does not cover forks by the callers around it. The critic's gloss "a bash loop over 8 HARDEN pairs and one export" understates the exports: the loop body is itself an `export`, so a first call makes 9 `export` builtin calls. All of them are builtins.

The body is `[[ -z "$CALLER_COUNT" ]] || return 0`, a `[[ =~ ]]` test, `CALLER_COUNT="$c"`, `for kv in "${HARDEN[@]}"; do export ...; c=$((c + 1)); done` and one final `export` (`:352-360`). There is no command substitution, pipeline or external command. HARDEN has 8 pairs (`:349`).

Executed in P2, under `ulimit -u 1`, where any fork fails:
- Two git_harden calls succeeded, leaving `GIT_CONFIG_COUNT=8 then 8 CALLER_COUNT=0`.
- The control subshell `( : )` failed with `fork: Resource temporarily unavailable`.

E0 test 19 passes. It calls git_harden twice with a caller count of 1 and asserts `GIT_CONFIG_COUNT=9`, so the second call added nothing.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:349-361`, `test/scripts/build-loop-orchestrator.bats:346-361`, `/tmp/u3b3-fc25-m6jn/logs/p2.out`, `/tmp/u3b3-fc25-m6jn/logs/bats.out`

---

## Claim 104: "The digest's core.commitGraph=false costs no measurable time at this size (perf2's numbers; not re-measured)."

**Submitted by:** performance-reviewer (final, `docs/reviews/performance-review-2026-10-12-u3b3-final.md:94`)
**Location:** `scripts/lib/dev-cycle-read.sh:349`, `scripts/dev-cycle.sh:131`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** This covers the `--since=2026-09-01` digest at 1,122 first-parent commits in a shared clone, where the commit-graph is reachable through alternates. It does not cover larger histories, the check modes, or a repository with 13 live worktrees as in perf2's run. Confidence is Medium because the run-to-run spread (496-569 ms) is wider than any effect.

The cited numbers match perf2's table: `706/687/709, 779/783/695,773/738/695` (`docs/reviews/performance-review-2026-10-12-u3b3-i2.md:35`). The script behind them is `/tmp/claude-1000/-workspace/c69d4d0f-5190-473b-ba2f-85b5a43f49ee/scratchpad/perf2-probe1.sh`. It re-enabled the graph with `env GIT_CONFIG_PARAMETERS="'core.commitgraph'='true'"`, the `git -c` channel (`:31`).

I re-measured in P4:
- **The caller's `-c` pair does re-enable the graph.** After git_harden, `git config --get core.commitGraph` printed `true` with the caller's `-c` pair and `false` without it. This matches the lib header's "git -c ones after HARDEN's" (`scripts/lib/dev-cycle-read.sh:343`).
- **The graph is in use in the clone.** `rev-list --first-parent main` took 9-10 ms with the graph off and 2 ms with it on.
- **The digest's time is unchanged.** Five paired digest runs: hardened 512/511/546/496/510 ms against graph re-enabled 516/569/506/511/509 ms.
- **The output is unchanged.** Both outputs were byte-identical (246 lines).

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:343-349`, `docs/reviews/performance-review-2026-10-12-u3b3-i2.md:35`, `/tmp/claude-1000/-workspace/c69d4d0f-5190-473b-ba2f-85b5a43f49ee/scratchpad/perf2-probe1.sh`, `/tmp/u3b3-fc25-m6jn/probes/p4.sh`, `/tmp/u3b3-fc25-m6jn/logs/p4.out`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
(none)

### Unverifiable
(none)

Notes for synthesis (none changes a verdict):
- **Claim 96.** The reader follows the first `^parent` line anywhere in the commit header, not only the one right after `tree`. Its hashing is plain SHA-1 rather than sha1dc. Both are provenance-neutral but sit next to r1's `$c ne $root` escalation.
- **Claim 97.** A stalled git or perl stalls the snippet, which has no timeout. My own probe hit this by accident through a buffering shim.
- **Claim 103.** The "one export" wording undercounts: a first call makes 9 export builtin calls. None of them forks.
