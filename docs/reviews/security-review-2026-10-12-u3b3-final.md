Commit: 5583a2cd

# Security Review — feat/build-loop-u3b3, iteration 3 (final confirming pass)

**Scope:** `main...5583a2cd` (feat/build-loop-u3b3); focus on `test/lib/d6-snippet.bash` (the verified reader, the `P=` program), the seven 2026-10-12 override rows (`docs/reviews/override-log.md:732-738`) and the plan's U3b3 as-built note
**Date:** 2026-10-12
**Based on:** code-fact-check-report-2026-10-12-u3b3-final-r{1,2,3}.md; rubric code-review-rubric-2026-10-12-feat-build-loop-u3b3.md (A1, B1, B2)

## Rulings asked for

1. **Does the verified reader close B1's class?** Yes, for the class B1 named. After the starting id (refs/heads/main, row 732's settled trust), every id the reader follows (first parents, the tip's tree, `scripts`, `lib`, the four blobs) is cut from bytes whose SHA-1 matched their id, and the bytes written to the temp dir are those same checked blob bytes. No second process (rev-list, ls-tree) reads an id any more, so a second packed or loose copy cannot choose what runs. The bash side runs only `$t` (after a `main` answer) or `D6_OPT` (after an `other` answer plus `own()` checks); any other perl result, including exit 0 with no answer, refuses. What remains is not "another reader picks the ids" but "which repository and which ref the one reader starts from": that is Finding 1 and row 732.
2. **The fact-check escalation (a foreign project whose main reaches a copy of 640cf007):** **New finding (Finding 1, Medium), not covered by row 732.** Same mechanism family as row 732 (trusting state a same-uid loop writes), but outside that row's stated scope and reason. Row 732 describes a main moved "on top of the real history" in claude-workflows, and its Won't-Fix reason is about what `--main-log` sees there. In a foreign project the root-owned image copy is the only defence, and the header promises it ("In any other repository ... it runs the image copy"). I also found two more routes to the same outcome: a hash-valid commit whose `parent` line comes after `author` (git reads it as a root commit; the reader follows it), and a rewritten `.git` gitfile in a linked worktree, which works while the real main never moves. Cheapest sound fix: an opt-in from the orchestrator's trusted environment (details under Finding 1). The doc-only fallback is to amend row 732 and the header.
3. **Anything the rewrite introduced:** no new exploitable path in the parsing, the `cat-file --batch` protocol or the exit handling beyond Finding 1's parent-line variant. The traced cases are listed under Endorsement Claims and Untested bypass candidates.

## Trust Boundary Map

```
B1: [refs/heads/main (loop-writable ref)]           → [show-ref / rev-parse --verify / cat-file -t]   → [the reader's starting commit id]
B2: [object store bytes, packs, loose, alternates]  → [perl SHA-1 gate in obj()]                       → [parent ids, tree id, entries, blob bytes] (moved: one reader, i2)
B3: [first-parent root id, from B2-checked bytes]   → [`$c ne $root` in the reader]                    → [run main's copy from $t vs the /opt image]
B4: [cwd's .git / gitfile (working tree)]           → [git repository discovery]                       → [the repository B1-B3 read]
B5: [/opt/claude-workflows (deploy-time, root)]     → [own() + -f on files, dirs up to /]              → [bash exec]
B6: [mktemp -d dir, 0700]                           → [bash "$t/scripts/$s"]                           → [exec] (row 509, Q-103)
```

| Label | Source | Mutability | Trust per sink |
|---|---|---|---|
| S1 | refs/heads/main, refs/heads/master | runtime-mutable (any same-uid loop) | UNTRUSTED toward the exec choice. Accepted for claude-workflows by row 732 |
| S2 | object store contents | runtime-mutable | UNTRUSTED until obj()'s SHA-1 matches the id; then trusted as "the bytes of that id" |
| S3 | `.git` gitfile / directory found from cwd | runtime-mutable (working tree) | UNTRUSTED toward "which repository is this" (Finding 1c) |
| S4 | /opt/claude-workflows files and every directory above | deploy-time, root-owned | trusted for exec once own() passes |
| S5 | D6_ROOT, F, the P program, G | code constant | trusted |
| S6 | orchestrator environment (PATH, TMPDIR, PERL5*, GIT_DIR) | deploy-time per the lib's trust model | trusted (loops cannot change the orchestrator's environment) |
| S7 | .git/config, info/, alternates | runtime-mutable | UNTRUSTED. The `-c` pairs and the G variables cover config; GIT_ALLOW_PROTOCOL=none blocks a promisor fetch; the hash gate covers object bytes |

Summary: everything the snippet reads from the repository is loop-writable. The reader turns S2 into trusted bytes by hashing them. But the two decisions that pick what runs, "which repository" (S3) and "is this claude-workflows" (S1 through B3), still rest on loop-writable state. For claude-workflows that is the settled row 732. For every other project it turns off the image copy that B5 protects.

## Findings

#### Finding 1: In a foreign project, the image copy can be swapped for the project's own scripts, because "is this claude-workflows" is decided from loop-writable state

**Severity:** Medium
**Location:** `test/lib/d6-snippet.bash:65-67` (the walk and the root test); header `:11`, `:19-23`; plan as-built note ("Another root, or a repository that is not SHA-1, runs D6_OPT/scripts/SCRIPT"); override row 732
**Boundary:** B3, B1, B4
**Move:** 5 (invert the access control model), 11 (bypass enumeration)
**Confidence:** High (all three routes executed)
**Legibility-target:** for-author

Evidence (verbatim):
- `my ($p) = $hd =~ /^parent ([0-9a-f]{40})$/m; last unless defined $p; $c = $p }` / `if ($c ne $root) { print "other\n"; exit 0 }` (`:66-67`)
- Header `:19-22`: "In any other repository (another root, or not SHA-1) it runs the image copy under D6_OPT, by absolute path, once those files and every directory above them are root-owned, no symlink and not writable here. It never reads the working tree, ~/.claude/scripts or a replaced object"
- Row 732: "a same-uid loop that moves main's ref onto its own commit on top of the real history passes every hash check ... Won't-Fix | The hostile-loop class F19 names: D13's --main-log catches an honest slip, not a forger"

The snippet treats "main's first-parent chain ends at 640cf007" as proof that the repository is claude-workflows, and so that main's own scripts may run. The ownership checks on the image copy run only on the other branch. 640cf007's commit object is public, and its id is fixed by its bytes, so any repository can hold a valid copy. The reader needs only that one commit object, not its tree. Preconditions: a same-uid loop able to write the foreign project's refs, its object store, or the orchestrator worktree's `.git` gitfile (all inside the brief's threat model). Impact: the loop's own build-loop.sh or dev-cycle.sh runs in place of the root-owned image copy, so it controls the gate's verdicts and the digest in that project. That is exactly what the image copy and its `own()` checks exist to prevent. Three routes, each executed against the snippet at 5583a2cd in my own temp dir:
- (a) **Moved main.** Main is moved onto a commit whose parent is a copy of 640cf007. Observed: the planted build-loop.sh ran, exit 0. This reproduces r1's P6.
- (b) **Late parent line.** A commit whose only `parent` line comes after `committer`. git reads it as a root commit (`rev-list --parents` lists no parent). The reader's `/^parent .../m` still finds the line and walks to 640cf007. Observed: planted ran, exit 0. This is a parser divergence from git's grammar, where parents follow `tree` directly. It adds no power beyond (a), but it makes the snippet's "first-parent root" differ from the one `--main-log` and every git tool see.
- (c) **Gitfile redirect.** A linked worktree of an honest foreign repository has its `.git` gitfile rewritten to point at a crafted repository. Observed: before the rewrite the /opt build-loop.sh ran; after it, the planted one ran, while the honest repository's main was unmoved. This also falsifies "It never reads the working tree" (git discovery reads the gitfile in the working tree). In claude-workflows itself, (c) is an equal-power alternative to row 732's moved main that leaves the real main, and so `--main-log`'s record, untouched.

Why this is not row 732: that row accepts a forged main where main's scripts were always going to run (claude-workflows). Here the snippet's own design says main's scripts must *not* run, and the header and plan state that guarantee without the ref-trust caveat. Row 732's reason ("--main-log catches an honest slip") does not apply, because in a foreign project the planted scripts include the `--main-log` that would report it.

**Recommendation:** The cheapest sound fix is to take main's copy only when two things hold: the root test passes, *and* a signal from the orchestrator's own environment (S6, trusted under the lib's trust model and not writable by loops at run time) says this container is claude-workflows. For example, a variable set only in claude-workflows' container definition. In every other case, go straight to the `other` branch without consulting the reader. This closes (a), (b) and (c) in foreign projects at a cost of about one line plus the deployment setting. A root-owned pin under `D6_OPT` naming a common-dir path would not work if every project mounts at `/workspace`. Independently, anchor the parent parse to git's grammar (parent lines only directly after `tree`, e.g. `\Atree [0-9a-f]{40}\n(?:parent ([0-9a-f]{40})\n)?`) so the walk matches git's. Fallback if the user rules this a Q-103 residual: amend row 732 to name foreign projects and the gitfile route explicitly, and correct header `:19-22` (both "In any other repository" and "never reads the working tree") and the plan note to carry the "while main's ref and the worktree's .git are honest" caveat.

## Re-flagged settled decisions

- **Row 732 (moved main in claude-workflows, Won't-Fix).** Confirmed as settled for claude-workflows. One addition for the row's text: route (c) above reaches the same result without moving the real main, so `--main-log` on the real repository shows nothing. Same class; I suggest the row name it.
- **Row 509 (same-uid racer on the 0700 temp dir, Q-103).** The window between perl's write and bash's run of `$t/scripts/$s` is this class. Unchanged; not re-filed.
- **Row 733 (plain SHA-1, no collision detection, Won't-Fix).** The reader's gate is `sha1_hex("$t $s\0$b") eq $id`. It agrees with the row; nothing new.
- **Row 548 (dev-cycle.sh runs no state/default gate, Q-103).** r1-r3 note that "before, not instead of, the script's own ... gates" holds for build-loop.sh's gated modes only. That is a text accuracy point under this row, with no new security consequence.

## Untested bypass candidates (move #11, verified reader)

- **Duplicate entry names in a hashed tree.** Traced, not executed: `entry()` returns the first match. Both entries sit under the same hash-checked tree that main names, so the choice gains nothing beyond row 732.
- **A very large object size in a `--batch` header.** Not executed: `read($r, $b, $s)` allocates up to `$s`. Reaching it requires main or the store to name a huge hash-valid object (a loop with ref-write power already has row 732). Availability only.
- **A promisor/partial-clone fetch or an alternates path triggered by cat-file on a missing object.** Traced, not executed: `GIT_ALLOW_PROTOCOL=none` blocks transports, and any fetched or alternate bytes still pass the hash gate.
- **Writing `extensions.objectFormat` so that `--show-object-format` is not sha1.** Traced: the result is the `other` branch, which is the image copy (the safe direction).

## Endorsement Claims

- **Claim:** After the starting commit id, every id the reader follows and every byte it writes to `$t/scripts/` comes from object bytes whose SHA-1 equals the requested id; no other git reader supplies an id.
  **Location:** `test/lib/d6-snippet.bash:58-71`
  **Evidence:** executed
  **Verified:** read the whole `P=` program and the bash lines `:72-88`; `bats test/scripts/build-loop-orchestrator.bats` 20/20 at 5583a2cd (tests 13 and 14: a tree and a commit rewritten in place refuse; test 11 runs main's four scripts); r1's P5 (a forged loose copy beside a packed real tree) ran the real scripts.
  **Not verified:** a two-copy store in which the *packed* copy is the forged one and the loose copy is real (r1's P5 tested the reverse layout).
  **route: code-fact-check**
- **Claim:** Any reader failure (a missing object, a short read, a hash mismatch, a git that died, an unwritable output) makes the snippet print `refuse d6:` and exit 2, never fall to the image copy; a perl exit 0 without `main` or `other` also refuses.
  **Location:** `test/lib/d6-snippet.bash:61-62, 78, 86`
  **Evidence:** executed (test 15: a missing commit, a shallow clone) plus read-static (die's exit is $! or 255, never 0; the `else no "the verified reader gave no answer"` arm)
  **Verified:** test 15 passes; the `|| no` and `else no` arms read.
  **Not verified:** perl killed by a signal mid-write after printing nothing; by the same `|| no` arm it should refuse, but this was not executed.
  **route: code-fact-check**
- **Claim:** The request/response loop cannot desynchronise: each request is one 40-hex id followed by a newline; the answer's name, type and decimal size are checked, exactly `size` bytes are read, and a trailing newline is required before the next request.
  **Location:** `test/lib/d6-snippet.bash:60-62`
  **Evidence:** read-static
  **Verified:** `obj()` read in full; ids come only from `rev-parse --verify` or `[0-9a-f]{40}` / `unpack("H*", 20 bytes)`.
  **Not verified:** git's behaviour for a `--batch` answer that contains `missing` or `ambiguous` (both lack a third field, so `defined $s` fails; this is git's documented format but was not executed here).

## Primitive sweep

Primitive: process exec / interpreter run

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/lib/d6-snippet.bash:87` `bash "$d/scripts/$s"` with d=$t | S2 via B2, chosen by S1/S3 via B3/B4 | SHA-1 gate, root test | Finding 1 (choice of branch); the bytes themselves are cleared (B1 closed) |
| `:87` with d=D6_OPT | S4 | own() + `-f` on files, dirs to / | cleared: root-owned and unwritable, no TOCTOU by a same-uid writer |
| `:78` `perl -e "$P"` | S5 program, S6 perl/@INC | constant; no `.` in @INC | cleared (S6 trusted per the trust model) |
| `:59` `open2(..., @git, "cat-file", "--batch")` | S5 G, S7 config | `-c` pairs, G variables | cleared |
| `:47-54, :75` git calls via `g` | S1, S7 | G | cleared for exec; S1 is row 732 |

Primitive: file write

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:70` `open(my $fh, ">", "$out/scripts/$f")` | S5 names, S6 TMPDIR | 3-arg open, constant names, fresh mktemp dir | cleared (racer: row 509) |
| `:73` trap `rm -rf "$t"` | S6 | `$t` from mktemp | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | In a foreign project, a main moved onto a 640cf007 copy, a late parent line, or a gitfile redirect runs the project's own scripts in place of the /opt image | Medium | B3, B1, B4 | `test/lib/d6-snippet.bash:65-67`, header `:19-23` | High |

## Overall Assessment

The verified reader does what i2 set out to do. B1's class is closed: no reader other than the one hash-gated stream chooses an id or a byte that runs, and B2's fall-through to /opt on a read failure is gone (executed). The remaining weakness is architectural, not in the parser: the decision "is this claude-workflows?" is made from a ref, from commit bytes chosen by that ref, and from a gitfile in the working tree, all loop-writable. For claude-workflows that is the settled row 732. In foreign projects it silently removes the image copy's protection that the header and plan promise. The single most important action is to gate the main-copy branch on a trusted, deploy-time signal (the orchestrator's environment), or, if the user rules it a Q-103 residual, to amend row 732 and correct the header and plan text so the guarantee is not overstated. Within the code paths read there are no other findings; endorsement claims are pending execution verification where marked.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/security-review-2026-10-12-u3b3-final.md, structured per the security-reviewer skill.
- Answered: yes. It rules on B1's class (closed), the escalation (new finding, not row 732), and the rewrite (nothing further beyond the parent-line variant).
- Out of scope: the text-accuracy items r1-r3 already carry (the store_check cross-reference, the stale test comment at build-loop-orchestrator.bats:306, the ~70 ms figure). These are fact-check items with no security consequence.
- Escalate: Finding 1 needs a ruling: fix (an environment opt-in for the main-copy branch, plus anchored parent parsing) or a Q-103 residual (amend row 732 and correct header `:19-22` and the plan note). It is a judgment about what the image copy is meant to guarantee in foreign projects.
- Decisions I made: I treated the orchestrator's environment as trusted (the lib's stated trust model), so PERL5LIB/PATH/GIT_DIR are not findings. I rejected a root-owned path pin under D6_OPT as the fix, because foreign projects may share the `/workspace` mount path. Probes ran in `/tmp/u3b3-sec4-XXXX` dirs, which were removed on exit; the script is at the session scratchpad `sec4-probe.sh`.
