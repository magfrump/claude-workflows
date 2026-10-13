Commit: 5583a2cd

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b3 (branch `feat/build-loop-u3b3`)
**Scope:** branch diff `main...5583a2cd`: `docs/working/plan-build-loop-handoff.md` (the U3b3 as-built note), `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `test/lib/d6-snippet.bash`, `test/scripts/build-loop-check.bats`, `test/scripts/build-loop-orchestrator.bats`, the seven new rows of `docs/reviews/override-log.md` (lines 732-738), and the messages of 9925f2a7, a0014ce5, d9515d09, c9648432 and 5583a2cd. 7a927183 and 5d175c0e carry no checkable claim beyond their subjects.
**Checked:** 2026-10-12
**Replication:** k=3, replicate r1 (final confirming pass, iteration 3 of 3)
**Total claims checked:** 59
**Summary:** 50 verified, 3 mostly accurate, 1 stale, 2 incorrect, 3 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`). Claim 54d, a test tally in a commit message that this pass could not reproduce, belongs to the same class as the logged "mode1-equiv 33 claimed ... holds 25" and "All 85 tests ... pass" patterns: a count claim to check against a run. No fabricated symbol, API or flag was found, so the log is not edited. The brief allows writing only this file.

**Iteration 2 fixes (B1-B19).** The verified reader holds against every probe this pass ran: a forged loose copy beside the packed real tree (P5), a tree or tip rewritten in place (tests 13 and 14), a tampered `cat-file --batch` stream (T33), a missing commit and a shallow clone (test 15). The text fixes hold, with one exception. B10's "store_check and the snippet's reader name each other" is still false: the snippet names no store_check (Claims 23 and 54b). One test comment went stale under the rewrite (Claim 47). One new residue: P6 shows that "another repository" is identified only by main's first-parent root id. A repository whose main chains onto a copy of 640cf007's commit object runs its own scripts, not the image copy (Claim 15, escalation 1).

**Execution provenance (shared by every `executed` claim).** All runs were as uid 1000, with git 2.39.5, bash 5.2 and `LC_ALL=C`. Every probe script starts with `set -eu`, makes its own `mktemp -d /tmp/u3b3-fc3r1-*-XXXX`, refuses to go on outside that directory, and removes it on exit. None was left behind. Scripts and captured output are in `/tmp/claude-1000/-workspace/c69d4d0f-5190-473b-ba2f-85b5a43f49ee/scratchpad/fc3r1/`, called `LOGS/` below.
- **S1** `bash LOGS/suites.sh` (cwd `/workspace/.claude/wt-build-loop-u3b3`, its own TMPDIR per suite, serial), started 2026-10-13T01:54:25Z, exit 0 (`LOGS/suites.ts`, `LOGS/<suite>.log`). Results: build-loop-orchestrator 20/20, build-loop-check 146/146, build-loop-read 20/20, build-loop-dispatch 4/4, build-loop-merge 12/12, dev-cycle 79/79, fixture-git-env 2/2. That is 283/283 with no skips. T37's real /opt test (test 17) ran rather than skipped, because `/opt/claude-workflows` here is root-owned and mode 555.
- **P1-P6** `bash LOGS/probes.sh`, 2026-10-13T01:55:30Z, exit 0 (`LOGS/probes.log`). P1: the snippet fed to `bash -s -- build-loop.sh --settings <<'D6'` from `zsh -f`, run in a `--no-local` clone of /workspace (the real D6_ROOT), plus `dev-cycle.sh --check-path`. P2: the verified reader's exit status for a missing object, a good run, an unwritable output directory and another root. P3: `GIT_CONFIG_COUNT=010` as git and as git_harden read it. P4: `log.showSignature=true` with `gpg.program` set, against main's and 5583a2cd's dev-cycle.sh digest. P5: the real objects packed (`repack -ad`) and a forged loose copy of `main:scripts`. P6: another repository whose main's first parent is a copy of 640cf007's commit object.
- **M** `bash LOGS/mutants.sh`, 2026-10-13T01:58:15Z, exit 0 (`LOGS/mutants.out`, `LOGS/{a0,m1,m2,m3,m4a,m4b,c0,n1,n2,c1}.log`). It applied mutants to `git archive` copies of a0014ce5 and c9648432 (scripts/ and test/) and ran `bats -f` on them. It also ran two ad-hoc tests (c1): `--state` against log.date and log.showSignature caller pairs, and the snippet against a symlinked script on main.
- **X1** `LOGS/prec.sh` 01:58:56Z (`LOGS/prec.log`): count pair against caller `-c`, and caller `-c` against a command-line `-c`. **X2** `LOGS/safe.sh` 01:59:19Z (`LOGS/safe.log`): a different owner simulated with git's `GIT_TEST_ASSUME_DIFFERENT_OWNER=1` and a global `safe.directory=*`. **X3** `LOGS/time.sh` 01:59:28Z (`LOGS/time.log`): wall time of d9515d09's snippet, 5583a2cd's snippet and a direct `--help`, in a clone of /workspace (load average about 4). **X4** dev-cycle.sh with `GIT_CONFIG_COUNT` set to 010 and 1x, about 01:59:47Z (`LOGS/dc-count.log`). **X5** `LOGS/t14.sh` 02:00:05Z (`LOGS/t14.log`) and **X6** `LOGS/t14b.sh` 02:00:21Z (`LOGS/t14b.log`): test 14's tip rewrite under 5583a2cd's and d9515d09's snippet, with stderr captured, plus `update-ref` of a branch to a tag. **X7** `LOGS/rr.sh` 02:02:06Z (`LOGS/rr.log`): repo `core.useReplaceRefs=true` against `GIT_NO_REPLACE_OBJECTS=1`. All exit 0.

---

## Claim 1: "The snippet trusts refs/heads/main itself: a same-uid loop that moves main's ref onto its own commit on top of the real history passes every hash check, and the snippet runs that commit's scripts ... Stated in the snippet's header."

**Location:** `docs/reviews/override-log.md:732`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that the snippet's start id is the ref and that the header says so. It does not establish the Won't-Fix judgement (Q-103's), or that the same mechanism is limited to claude-workflows (see Claim 15 and P6).
**Legibility-target:** for-orchestrator-synthesis

The start id is the ref, unchecked against anything: `sha="$(g rev-parse --verify -q "refs/heads/$m")"` (`test/lib/d6-snippet.bash:54`). It is passed to the reader as `$c` (`:78`). Every later id comes from bytes that hash, so a new commit on top of the real history passes. The header says: "it trusts refs/heads/main itself (a moved main is --main-log's to report, D13; F19, rows 509, 721)" (`test/lib/d6-snippet.bash:23-24`).

**Evidence:** `test/lib/d6-snippet.bash:23-24`, `test/lib/d6-snippet.bash:54`, `test/lib/d6-snippet.bash:58-78`

---

## Claim 2: "The snippet's own re-hash is plain SHA-1 with no collision detection ... Revisit trigger: claude-workflows moves to SHA-256 (the snippet then takes the image copy)"

**Location:** `docs/reviews/override-log.md:733`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hash function used and the non-SHA-1 branch. It does not establish the claim that a chosen-prefix collision is "out of a loop's reach today", which is a judgement about the world.
**Legibility-target:** for-orchestrator-synthesis

`use Digest::SHA qw(sha1_hex)` and `sha1_hex("$t $s\0$b") eq $id` (`test/lib/d6-snippet.bash:58`, `:62`) compute plain SHA-1. A repository that is not SHA-1 skips the reader: `if [[ "$x" == sha1 ]]; then ... else x=other; fi` (`:77-79`), and `other` takes `d="$D6_OPT"` (`:82-83`).

**Evidence:** `test/lib/d6-snippet.bash:58-62`, `test/lib/d6-snippet.bash:75-86`

---

## Claim 3a: "Each snippet call pays ~70 ms of fixed fork overhead over a direct run"

**Location:** `docs/reviews/override-log.md:734`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers wall time in a clone of this repository on this host, under load. It does not establish the reviewer's original measurement, which was on the i2 code.
**Legibility-target:** for-author

X3 measured the snippet at 0.110-0.114 s and a direct `build-loop.sh --help` at 0.014-0.016 s. That is about 95-100 ms of overhead at 5583a2cd, not ~70 ms. Part of it is not fixed: the reader walks every first-parent commit (`while (1) { ... obj($c, "commit") ... last unless defined $p; $c = $p }`, `test/lib/d6-snippet.bash:65-66`), 1,122 commits here, so the cost grows with history. A more precise row would say "~100 ms here, part of it linear in main's first-parent history".

**Evidence:** `test/lib/d6-snippet.bash:65-66`, `LOGS/time.log`

---

## Claim 3b: "the verified reader already cut the history walks from two to one"

**Location:** `docs/reviews/override-log.md:734`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the number of history walks in d9515d09 against 5583a2cd. It does not establish any timing.
**Legibility-target:** for-orchestrator-synthesis

d9515d09 ran `g rev-list --first-parent --max-parents=0 "$sha"` and then `g rev-list --first-parent "$sha"` piped into the re-hash (two walks; `git show d9515d09:test/lib/d6-snippet.bash`). At 5583a2cd the only walk is the perl loop at `test/lib/d6-snippet.bash:65-66`.

**Evidence:** `test/lib/d6-snippet.bash:65-66`, d9515d09's `test/lib/d6-snippet.bash` (the `if [[ "$(g rev-list ...` block)

---

## Claim 4: "`refuse d6: WHY` (exit 2) can now precede any mode's output ... Contract for U4, written into the plan's as-built note"

**Location:** `docs/reviews/override-log.md:735`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal format and the plan note's hand-off. It does not establish U4's parser, which is not written yet.
**Legibility-target:** for-orchestrator-synthesis

`no() { echo "refuse d6: $*"; exit 2; }` (`test/lib/d6-snippet.bash:39`) runs before any script, whatever the mode. The plan note says: "match a first line starting `refuse d6: ` before parsing any mode's output, as a stop, never as a brief's verdict" (`docs/working/plan-build-loop-handoff.md:326`).

**Evidence:** `test/lib/d6-snippet.bash:39`, `docs/working/plan-build-loop-handoff.md:326`

---

## Claim 5: "the lib cannot be sourced before it is checked, it runs once per process, exporting it makes --state refuse (row 702), and the snippet's G lives only in its own bash"

**Location:** `docs/reviews/override-log.md:736`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four stated properties. It does not establish whether U4 can build a third wrapper.
**Legibility-target:** for-orchestrator-synthesis

Runs once: `[[ -z "$CALLER_COUNT" ]] || return 0` (`scripts/lib/dev-cycle-read.sh:352`); mutant n2 removed it and test 19 went red (M). Exported pairs refused: a count pair `core.hooksPath` gets `refuse state core.hookspath` (`test/scripts/build-loop-orchestrator.bats:48-49`), and S1 test 2 passes. G is local to the snippet's bash: `G=(env ... git -c ...)` (`test/lib/d6-snippet.bash:40`), an array, never exported.

**Evidence:** `scripts/lib/dev-cycle-read.sh:351-361`, `test/lib/d6-snippet.bash:40`, `LOGS/mutants.out`, `LOGS/build-loop-orchestrator.log`

---

## Claim 6: "The snippet passes HARDEN as git -c pairs, which outrank a caller's git -c; git_harden passes them as count pairs, which a caller's git -c outranks ... a caller pair for a HARDEN key fails --state by name"

**Location:** `docs/reviews/override-log.md:737`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's precedence and caller_gate's refusal for log.date and log.showsignature. It does not establish the precedence in other git versions.
**Legibility-target:** for-orchestrator-synthesis

X1: a count pair `x.y=count` with a caller `GIT_CONFIG_PARAMETERS` `x.y=param` reads `param`; a caller `x.y=caller` with a command-line `-c x.y=snippet` reads `snippet`. M's c1 test: `GIT_CONFIG_KEY_0=log.date` gives exit 2 and `refuse state log.date: ...`, and `GIT_CONFIG_PARAMETERS="'log.showsignature'='false'"` gives `refuse state log.showsignature: ...`.

**Evidence:** `scripts/build-loop.sh:559-575`, `LOGS/prec.log`, `LOGS/c1.log`

---

## Claim 7: "`git_harden` (lib) holds HARDEN, CALLER_COUNT and the environment build-loop.sh exported ... build-loop.sh and dev-cycle.sh call it after scrub_reexec, before their first git call; a second call returns at once."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function's body, both call sites and the idempotence guard. It does not establish that no later line overrides a variable on purpose (Claim 25 names those lines).
**Legibility-target:** for-orchestrator-synthesis

`export GIT_CONFIG_COUNT="$c" GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none` (`scripts/lib/dev-cycle-read.sh:360`, function read to `:361`) is the set the diff removes from build-loop.sh. build-loop.sh: `source "$READ_LIB"` / `scrub_reexec ...` (`scripts/build-loop.sh:442-443`), then the mode `case` (`:445-488`; it calls only `usage` and the lib's `readerform`, and neither runs git; `readerform` is at `scripts/lib/dev-cycle-read.sh:634-638`), then `git_harden` (`:497`). dev-cycle.sh: `scrub_reexec` (`scripts/dev-cycle.sh:105`), the arg loop (`:110-125`, no git), then `git_harden` (`:131`) and the first git call (`:132`). The lib makes no git call at source time (paraphrased — no quote available because this is a claim about absence: an awk pass over the lib's top-level lines outside functions found no `git ` call). Test 19, which calls git_harden twice, passes (S1), and its mutant n2 fails (M).

**Evidence:** `scripts/lib/dev-cycle-read.sh:349-361`, `scripts/build-loop.sh:438-497`, `scripts/dev-cycle.sh:93-132`, `LOGS/mutants.out`

---

## Claim 8: "HARDEN gains `log.date=default` (row 505: a bogus log.date stopped --check-brief) and `log.showSignature=false` (a planted one made the digest's git log run gpg.program on main); caller_gate refuses both keys by name with the rest."

**Location:** `docs/working/plan-build-loop-handoff.md:326` (same claims in commit 9925f2a7 and a0014ce5)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two pairs, main's gpg.program run and caller_gate's refusal. It does not establish every git subcommand's reading of log.showSignature.
**Legibility-target:** for-orchestrator-synthesis

`HARDEN=(... log.date=default log.showSignature=false)` (`scripts/lib/dev-cycle-read.sh:349`). P4: main's `dev-cycle.sh --since=2020-01-01` with `log.showSignature true` and `gpg.program` set printed "P4 main: gpg.program RAN". 5583a2cd's printed "did not run". caller_gate takes its keys from the same list: `for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done` (`scripts/build-loop.sh:567`). The c1 test refused both keys (Claim 6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:349`, `scripts/build-loop.sh:559-575`, `LOGS/probes.log` (P4), `LOGS/c1.log`

---

## Claim 9: "dev-cycle.sh now reads no user or system git config and no transport (its header says so)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh's own git calls and those of its children (the lib, questions.sh), as test 20's shim logs them. It does not cover the deliberate `GIT_LITERAL_PATHSPECS=0` overrides, which are not config or transport.
**Legibility-target:** for-orchestrator-synthesis

Test 20 runs a `--check-brief` and a digest through a logging git shim and requires `G=/dev/null P=none S=1` and every HARDEN pair on each logged call: `for kv in $(bash -c 'source "$1"; echo "${HARDEN[*]}"' ...) G=/dev/null P=none S=1; do ! grep -v -- " $kv" ...` (`test/scripts/build-loop-orchestrator.bats:377-379`). It passes (S1). The header text is at `scripts/dev-cycle.sh:83-86` (Claim 28).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:363-380`, `scripts/dev-cycle.sh:83-86`, `LOGS/build-loop-orchestrator.log`

---

## Claim 10: "the Bash tool's shell can be zsh (an alias `g` broke a pasted function)"

**Location:** `docs/working/plan-build-loop-handoff.md:326` (also commit a0014ce5)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the claim's existence. The incident is in a session transcript, not the repository.
**Legibility-target:** for-orchestrator-synthesis

The incident needs the original session's transcript. The session shell here is zsh, which fits the first half (paraphrased — no quote available because this comes from the environment, not a file).

**Evidence:** `docs/working/plan-build-loop-handoff.md:326`

---

## Claim 11: "a script bash reads, not a function pasted into the caller's shell (its `d6` function lives only in that bash) ... U4's SKILL.md feeds the file, byte for byte, to `bash -s -- SCRIPT ARG... <<'D6'`, and the snippet runs everything with stdin from /dev/null."

**Location:** `docs/working/plan-build-loop-handoff.md:326`; `test/lib/d6-snippet.bash:2-10`, `:90-92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heredoc form from `zsh -f`, run against the real D6_ROOT in a clone. It does not establish the SKILL.md block, which U4 writes, or byte equality (T33's pending half).
**Legibility-target:** for-orchestrator-synthesis

P1 wrote `bash -s -- build-loop.sh --settings <<'D6'`, the file and `D6` to a script and ran it with `zsh -f`. Exit 0, and the five `--settings` lines printed. The file ends `d6 "$@" </dev/null` (`test/lib/d6-snippet.bash:92`), and every path in `d6` ends in `exit` (`:39`, `:44`, `:88`), so bash reads no further heredoc line. The clone took the `main` path (D6_ROOT matched), and TMPDIR was empty afterwards.

**Evidence:** `test/lib/d6-snippet.bash:36-92`, `LOGS/probes.log` (P1)

---

## Claim 12: "Checks, in order: ... its ref's own object a commit (not peeled from a tag; origin/HEAD is left to the script's default_gate)" and "These checks come before, not instead of, the script's own state and default-branch gates."

**Location:** `docs/working/plan-build-loop-handoff.md:326`; `test/lib/d6-snippet.bash:34-35`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of the snippet's checks (exact) and which scripts have a default_gate. It does not establish what dev-cycle.sh reads when origin/HEAD names another branch (row 548, settled).
**Legibility-target:** for-author

The order matches the code: replace refs (`test/lib/d6-snippet.bash:47-48`), grafts (`:49-50`), exactly one of main and master (`:51-52`), not symbolic (`:53`), and `[[ "$(g cat-file -t "$sha")" == commit ]]` on the unpeeled ref (`:54`). "Left to the script's default_gate" and "the script's own state and default-branch gates" hold only for build-loop.sh. dev-cycle.sh has no `default_gate` or `state_gate` (paraphrased — no quote available because this is a claim about absence: `grep -n 'default_gate\|state_gate' scripts/dev-cycle.sh` finds none). The lib's own header says so: "dev-cycle.sh runs no state gate (row 548)" (`scripts/lib/dev-cycle-read.sh:347`). dev-cycle.sh's `resolve_main` tries origin/HEAD first (`scripts/dev-cycle.sh:198`, "tried origin/HEAD, main, master"). A more precise text would read "origin/HEAD is left to build-loop.sh's default_gate (dev-cycle.sh has none: row 548)". Re-flag of settled row 548.

**Evidence:** `test/lib/d6-snippet.bash:34-35`, `test/lib/d6-snippet.bash:47-54`, `scripts/lib/dev-cycle-read.sh:346-347`, `scripts/dev-cycle.sh:198`

---

## Claim 13: "the verified reader: one perl process drives one `git cat-file --batch`, uses an object only once its bytes SHA-1 to its id, and takes every next id from bytes it has checked ... No other reader (rev-list, ls-tree) decides what runs, so a second copy of an object, packed or loose, cannot either (i2 B1's two-pack forgery now runs main's real scripts; a forged copy read would refuse)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`; `test/lib/d6-snippet.bash:11-19`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every id and byte the reader uses: the start id is the ref (Claim 1), and every later id is parsed from hashed bytes. It covers a packed-real/loose-forged pair (P5) and an in-place loose rewrite (tests 13, 14). It does not establish the exact two-pack layout i2 used, and it does not cover a commit whose header carries a `parent` line after `author` (perl's `/^parent .../m` would take it while git would not). Such bytes are hashed and sit on a main the loop must have moved, which is Claim 1's class.
**Legibility-target:** for-orchestrator-synthesis

`obj` writes one id to the batch, reads one header, requires `$i eq $id && $t eq $want && $s =~ /\A[0-9]+\z/ && read($r, $b, $s) == $s && getc($r) eq "\n"`, then `sha1_hex("$t $s\0$b") eq $id` (`test/lib/d6-snippet.bash:60-62`). Ids come from `$hd =~ /\Atree ([0-9a-f]{40})\n/`, `/^parent ([0-9a-f]{40})$/m` and `unpack("H*", $id)` of a tree entry's 20 bytes (`:63-66`), always out of a checked `$b`. The files are written from `$b` (`:70`). The only other git reads are refs, paths and the type check (`:47-54`, `:75`). P5: with the real objects packed and a forged loose `scripts` tree at the same id, `git ls-tree` still showed the real blob, and the snippet ran the real `--settings` (exit 0, no "replaced"). X5 and test 14: a tip rewritten in place gives exit 2 and the A1 line, with perl's "does not hash to its id" on stderr.

**Evidence:** `test/lib/d6-snippet.bash:58-79`, `LOGS/probes.log` (P5), `LOGS/t14.log`, `LOGS/build-loop-orchestrator.log` (tests 11, 13, 14)

---

## Claim 14: "Any read failure refuses, never falls to the image copy (i2 B2: a missing first-parent commit, a shallow clone)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reader's failures and the snippet's own git and mkdir steps. A non-SHA-1 repository takes the image copy by design, which is not a read failure.
**Legibility-target:** for-orchestrator-synthesis

`x="$(LC_ALL=C perl -e "$P" ...)" || no "..."` (`test/lib/d6-snippet.bash:78`). Any non-`main`/`other` answer gets `else no "the verified reader gave no answer"` (`:86`). P2: a missing object exits 255 and an unwritable output exits 2, both non-zero. Test 15 passes (S1), and mutant n1, which replaced the refusal with `x=other`, turned it red (M).

**Evidence:** `test/lib/d6-snippet.bash:75-86`, `LOGS/probes.log` (P2), `LOGS/n1.log`

---

## Claim 15: "Another root, or a repository that is not SHA-1, runs `D6_OPT/scripts/SCRIPT` once the four files are regular, root-owned (`stat -c %u`), not symlinks and not writable (`-w`), and so is every directory from `scripts/lib` up to `/`" / "In any other repository (another root, or not SHA-1) it runs the image copy under D6_OPT, by absolute path"

**Location:** `docs/working/plan-build-loop-handoff.md:326`; `test/lib/d6-snippet.bash:19-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the narrow reading, "a repository whose main's first-parent root id is not D6_ROOT". It does not establish that a repository other than claude-workflows always takes the image copy. P6 copied 640cf007's commit object into a fresh repository (the object is public, and same-uid readable from /workspace) and pointed main at a commit whose parent is that object. The snippet printed "planted build-loop.sh", exit 0: that repository's own scripts ran, not /opt's. This needs a loop that moves main (Claim 1's class), but in a project other than claude-workflows it bypasses the image copy's ownership checks entirely. See escalation 1.
**Legibility-target:** for-orchestrator-synthesis

`own() { [[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no ...; }` (`test/lib/d6-snippet.bash:42`). The files are checked by `for f in "${F[@]}"; do own "$d/scripts/$f"; [[ -f "$d/scripts/$f" ]] || no ...; done` and the directories by `x="$d/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done` (`:84-85`), and the script runs as `bash "$d/scripts/$s"` (`:87`). The repository test is `if ($c ne $root) { print "other\n"; exit 0 }` on the last commit of the first-parent walk (`:67`). T37's two tests ran here, neither skipped (S1), and mutant m2 (own() always true) turned the uid-owned case red (M).

**Evidence:** `test/lib/d6-snippet.bash:42`, `test/lib/d6-snippet.bash:65-67`, `test/lib/d6-snippet.bash:80-87`, `LOGS/probes.log` (P6), `LOGS/m2.log`

---

## Claim 16: "(the `-w` test makes a root run refuse unless the mount is read-only)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing executed. It does not establish behaviour under uid 0.
**Legibility-target:** for-orchestrator-synthesis

Execution is required and blocked because no uid 0 is available. Statically, `! -w "$1"` (`test/lib/d6-snippet.bash:42`) is false for root on a writable mount whatever the mode bits, which fits the claim.

**Evidence:** `test/lib/d6-snippet.bash:42`

---

## Claim 17: "The run has BASH_ENV, ENV and DEV_CYCLE_SCRUBBED unset; the temp dir is removed on exit."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the run and the EXIT trap after mktemp, on both success and refusal. A refusal before mktemp creates no directory to remove.
**Legibility-target:** for-orchestrator-synthesis

`env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"` then `exit "$?"` (`test/lib/d6-snippet.bash:87-88`). `trap 'rm -rf "$t"' EXIT` is set right after `t="$(mktemp -d)"` (`:72-73`). T33 checks `[ -z "$(ls -A "$TMPDIR")" ]` after a run and after a tamper refusal (`test/scripts/build-loop-orchestrator.bats:261`, `:267`), and it passes (S1). P1's TMPDIR was empty after its runs.

**Evidence:** `test/lib/d6-snippet.bash:72-88`, `test/scripts/build-loop-orchestrator.bats:245-269`, `LOGS/probes.log`

---

## Claim 18: "Refusal: one `refuse d6: WHY` line on stdout and exit 2, nothing run (git or perl may add a stderr line); exit 1 for another first argument" and the header's Exit list.

**Location:** `docs/working/plan-build-loop-handoff.md:326`; `test/lib/d6-snippet.bash:26-33`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every refusal the list names: replace ref, grafts, the default-branch cases, a non-commit ref, unreadable or unhashed history, trees and files, a shallow history, a non-regular script on main (symlink case), the image-copy ownership checks, git or temp-dir failures, and the bad first argument. It does not establish the stderr text of every failure.
**Legibility-target:** for-orchestrator-synthesis

T36's `d6_is` requires `[ "$status" -eq 2 ] && [ "$output" = "$1" ] && [ -z "$stderr" ]` (`test/scripts/build-loop-orchestrator.bats:237`) for each check in `:271-284`, and the bad-argument case requires exit 1, empty stdout and the stderr line (`:283`). All pass (S1). M's c1 test: a symlinked `scripts/questions.sh` on main gives exit 2 and a `refuse d6:` line. The mode check is `entry(..., qr/\A100(644|755)\z/)` (`test/lib/d6-snippet.bash:70`).

**Evidence:** `test/lib/d6-snippet.bash:26-33`, `test/lib/d6-snippet.bash:39-54`, `test/lib/d6-snippet.bash:70`, `LOGS/c1.log`, `LOGS/build-loop-orchestrator.log`

---

## Claim 19: "Its git carries HARDEN as `-c` and git_harden's variables (G), a test pins the lists equal (the snippet cannot source the lib before checking it)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`; `test/lib/d6-snippet.bash:32-34`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lists' contents and order: test 19 pins the lib's HARDEN and environment to H and E, and the G line to the same H and E. It does not pin precedence (Claim 6).
**Legibility-target:** for-orchestrator-synthesis

The snippet's line is `G=(env GIT_NO_REPLACE_OBJECTS=1 ... git -c core.useReplaceRefs=false ... -c log.showSignature=false)` (`test/lib/d6-snippet.bash:40`). The cat-file reader gets the same array: `perl -e "$P" "$D6_ROOT" "$t" "$sha" "${G[@]}"` (`:78`). Test 19 checks `printf "pair %s\n" "${HARDEN[@]}"` and the exported `GIT_*` set against `H`/`E` (`test/scripts/build-loop-orchestrator.bats:348-356`), then G's `-c` list and its `GIT_*=` words against the same `H`/`E` (`:358-360`). It passes (S1).

**Evidence:** `test/lib/d6-snippet.bash:40`, `test/lib/d6-snippet.bash:78`, `test/scripts/build-loop-orchestrator.bats:346-361`

---

## Claim 20: "The snippet trusts refs/heads/main itself: a moved main is F19's class (--main-log reports an honest slip, not a forger; rows 509, 721, and this unit's row)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and content of the cited rows. It does not establish the ruling, which is Q-103's.
**Legibility-target:** for-orchestrator-synthesis

Row 721 says "D13's check catches an honest slip ..., not a forger" (`docs/reviews/override-log.md:721`), and this unit's row is `:732` (Claim 1).

**Evidence:** `docs/reviews/override-log.md:509`, `docs/reviews/override-log.md:721`, `docs/reviews/override-log.md:732`

---

## Claim 21: "Rows: 200 discharged (every byte run is hashed before it is written; a writer racing the 0700 dir is the Q-103 class, row 509)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claude-workflows (extraction) path, which row 200 is about. The lib is hashed with the scripts, and the files are written into a fresh `mktemp -d`. It does not cover the image-copy path, whose bytes are trusted by ownership and not hashed, or a racer after the write (row 509, settled).
**Legibility-target:** for-orchestrator-synthesis

The four files, `lib/dev-cycle-read.sh` among them, are written only from `my $b = obj(..., "blob")`, which has passed the SHA-1 check (`test/lib/d6-snippet.bash:69-70`). The directory comes from `t="$(mktemp -d)"` (`:72`), mode 0700 by mktemp's default. Row 200 asked to "hash-check the lib with the scripts and extract into a fresh mktemp dir" (`docs/reviews/override-log.md:200`).

**Evidence:** `test/lib/d6-snippet.bash:69-74`, `docs/reviews/override-log.md:200`, `LOGS/build-loop-orchestrator.log` (test 11)

---

## Claim 22: "311 (git_harden's exact environment is pinned)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that dropping `GIT_NO_REPLACE_OBJECTS=1` from git_harden now fails a test. It does not run that mutant itself: the conclusion follows from test 19 comparing the whole `GIT_*` environment.
**Legibility-target:** for-orchestrator-synthesis

Test 19 compares `env | grep "^GIT_" | sort` with `E`, which holds `GIT_NO_REPLACE_OBJECTS=1` (`test/scripts/build-loop-orchestrator.bats:348`, `:351`, `:355-356`), so any change to the exported set fails it. It passes (S1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:346-356`, `docs/reviews/override-log.md:311`

---

## Claim 23: "644/648 not moved (store_check stays build-loop.sh's; the snippet's reader is narrower, SHA-1 only and needs no second-copy rule since it uses only bytes it hashed; each comment names the other)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cross-reference in both directions. It does not dispute the decision to leave store_check in build-loop.sh.
**Legibility-target:** for-author

store_check's comment names the snippet: "(The D6 snippet, test/lib/d6-snippet.bash, runs a narrower reader before this script: SHA-1 only and no second-copy rule ...)" (`scripts/build-loop.sh:928-930`). The snippet never names store_check or build-loop.sh's object check (paraphrased — no quote available because this is a claim about absence: `grep -n -i store test/lib/d6-snippet.bash` finds nothing at 5583a2cd or c9648432). Only one direction exists. Fix: add a store_check reference to the snippet's reader comment (`test/lib/d6-snippet.bash:55-57`), or reword the note to "store_check's comment names the snippet". Comment/doc only.

**Evidence:** `scripts/build-loop.sh:927-930`, `test/lib/d6-snippet.bash:1-57`

---

## Claim 24: "(the lib's HARDEN list: core.useReplaceRefs, core.hooksPath, core.fsmonitor, core.attributesFile, core.commitGraph, core.multiPackIndex, log.date, log.showSignature; a git -c pair would win over it)"

**Location:** `scripts/build-loop.sh:134-137`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight keys and the `-c` precedence. Nothing is left unchecked.
**Legibility-target:** for-orchestrator-synthesis

These are the eight keys of `HARDEN=(...)` (`scripts/lib/dev-cycle-read.sh:349`), in order. X1 shows a caller `-c` beats a count pair.

**Evidence:** `scripts/build-loop.sh:134-137`, `scripts/lib/dev-cycle-read.sh:349`, `LOGS/prec.log`

---

## Claim 25: "The caller's global config, for merge_ident alone ... every other call reads none" / "Every git call in this process, the lib's included, runs hardened, but for caller_gate's read of the caller's pairs and merge_ident's CALLER_GLOBAL"

**Location:** `scripts/build-loop.sh:490-497`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers config pairs, the global and system config, and transport across build-loop.sh and the lib. It does not count `md_ls`'s `GIT_LITERAL_PATHSPECS=0` (`scripts/lib/dev-cycle-read.sh:1601`), a deliberate pathspec override with explicit `:(glob,icase)` magic that leaves all config and transport hardening in place.
**Legibility-target:** for-orchestrator-synthesis

`CALLER_GLOBAL=(-u GIT_CONFIG_GLOBAL); [[ -z "${GIT_CONFIG_GLOBAL+set}" ]] || CALLER_GLOBAL=("GIT_CONFIG_GLOBAL=$GIT_CONFIG_GLOBAL")` (`:492`) runs before `git_harden` (`:497`), so it holds the caller's value. The only lines that hand back a caller setting are `x="$(GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list ...)"` (`:564`) and `env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var ...` (`:1321`). That is what a grep for every `GIT_CONFIG_COUNT=`, `GIT_CONFIG_GLOBAL=`, `-u GIT_` and `GIT_ALLOW_PROTOCOL=` assignment in build-loop.sh, the lib and dev-cycle.sh returns (paraphrased — no quote available because this is a grep result over three files).

**Evidence:** `scripts/build-loop.sh:490-497`, `scripts/build-loop.sh:564`, `scripts/build-loop.sh:1317-1325`

---

## Claim 26: "A caller pair ... (read with the caller's count, so git_harden's own pairs are not listed) ... git applies git -c pairs after git_harden's, so they win (a GIT_CONFIG_COUNT pair comes before git_harden's and loses, but is refused too)."

**Location:** `scripts/build-loop.sh:553-557`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5. It does not establish other versions.
**Legibility-target:** for-orchestrator-synthesis

`GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list --show-scope --name-only` (`scripts/build-loop.sh:564`) limits the read to indices below the caller's count. git_harden puts HARDEN at indices from the caller's count upward (`scripts/lib/dev-cycle-read.sh:357-359`), so a caller's count pair comes earlier and loses. X1: `-c` beats a count pair. S1 test 2 and c1 show the count-pair refusal.

**Evidence:** `scripts/build-loop.sh:551-575`, `scripts/lib/dev-cycle-read.sh:351-361`, `LOGS/prec.log`, `LOGS/c1.log`

---

## Claim 27: "(The D6 snippet, test/lib/d6-snippet.bash, runs a narrower reader before this script: SHA-1 only and no second-copy rule, since it uses only bytes it has hashed itself.)"

**Location:** `scripts/build-loop.sh:928-930`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reader's properties. It does not establish the reverse cross-reference (Claim 23).
**Legibility-target:** for-orchestrator-synthesis

SHA-1 only: `if [[ "$x" == sha1 ]]` (`test/lib/d6-snippet.bash:77`). The reader has no listing of object copies, only `obj`'s hash check (`:60-62`).

**Evidence:** `test/lib/d6-snippet.bash:58-79`

---

## Claim 28: "Its git reads are hardened (the lib's git_harden): they read no user or system git config (a repository owned by another user that needs a global safe.directory reads as "Not inside a git repository") and no transport (a partial clone's missing object fails)."

**Location:** `scripts/dev-cycle.sh:83-86` (same note in commit 9925f2a7)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the safe.directory consequence with the different owner simulated by git's `GIT_TEST_ASSUME_DIFFERENT_OWNER=1`, not a real second uid. The no-transport half rests on git_harden's export and build-loop-check's partial-clone tests (`:1685`, `:1729`), which exercise build-loop.sh, not dev-cycle.sh.
**Legibility-target:** for-orchestrator-synthesis

X2: with a global `safe.directory=*`, plain git found the repository. 5583a2cd's `dev-cycle.sh --check-path x` printed "Not inside a git repository" (exit 1), while main's dev-cycle.sh answered `skip x: ...` (exit 0). git_harden exports `GIT_ALLOW_PROTOCOL=none` (`scripts/lib/dev-cycle-read.sh:360`).

**Evidence:** `scripts/dev-cycle.sh:83-86`, `scripts/dev-cycle.sh:131-132`, `LOGS/safe.log`

---

## Claim 29: "Exit: ... 1 bad usage, a GIT_CONFIG_COUNT that is not plain decimal, not a git repo, ..."

**Location:** `scripts/dev-cycle.sh:87-90`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 010 and 1x through scrub_reexec. It does not cover `-h`, which exits 0 before git_harden.
**Legibility-target:** for-orchestrator-synthesis

X4: both counts printed "dev-cycle.sh: GIT_CONFIG_COUNT is not a plain decimal count", exit 1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:354`, `LOGS/dc-count.log`

---

## Claim 30: "Every git call from here on, the lib's and questions.sh's included, runs hardened, as build-loop.sh's do ... File names are literal, not pathspecs." (and the removed `export GIT_LITERAL_PATHSPECS=1`)

**Location:** `scripts/dev-cycle.sh:127-131`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git call after `:131`, children included. questions.sh does not reset any GIT_ variable (paraphrased — no quote available because this is a claim about absence: grep for `GIT_` in `scripts/questions.sh` finds none). It does not cover `matches()`'s deliberate `GIT_LITERAL_PATHSPECS=0` with explicit `:(glob)`/`:(literal)` magic (`:149`, `:153`), which predates the diff.
**Legibility-target:** for-orchestrator-synthesis

`git_harden` (`:131`) now exports `GIT_LITERAL_PATHSPECS=1` before `ROOT="$(git rev-parse --show-toplevel ...)"` (`:132`), earlier than the removed export did (after `cd "$ROOT"`), so every path that had it still has it. questions.sh runs as `bash "$QS" open` (`:408`), a child that inherits the exports. Test 20's shim, which logs the digest's calls, questions.sh's among them, passes (S1).

**Evidence:** `scripts/dev-cycle.sh:127-140`, `scripts/dev-cycle.sh:389-408`, `LOGS/build-loop-orchestrator.log`

---

## Claim 31: "git_harden and the state gate own item 2's fsmonitor and replace refs"

**Location:** `scripts/lib/dev-cycle-read.sh:70`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the renamed symbol. It does not re-check the state gate's keys.
**Legibility-target:** for-orchestrator-synthesis

`core.fsmonitor=false` and `core.useReplaceRefs=false` are in `HARDEN` (`scripts/lib/dev-cycle-read.sh:349`), and `git_harden` exists (`:351`). No `harden()` remains (paraphrased — no quote available because this is a claim about absence: grep finds no `^harden()` in scripts/).

**Evidence:** `scripts/lib/dev-cycle-read.sh:70`, `scripts/lib/dev-cycle-read.sh:349-351`

---

## Claim 32: "git_harden: every later git call in this process and its children runs hardened, but where a caller hands back its own setting on purpose (build-loop.sh's caller_gate reads the caller's count, merge_ident its global config); build-loop.sh and dev-cycle.sh call it once, after scrub_reexec and before their first git call"

**Location:** `scripts/lib/dev-cycle-read.sh:326-330`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** The same as Claims 7 and 25. It does not count the pathspec-only overrides named there.
**Legibility-target:** for-orchestrator-synthesis

The call sites are `scripts/build-loop.sh:497` and `scripts/dev-cycle.sh:131`. The exceptions are `scripts/build-loop.sh:564` and `:1321` (quoted in Claim 25).

**Evidence:** `scripts/lib/dev-cycle-read.sh:326-361`, `scripts/build-loop.sh:442-497`, `scripts/dev-cycle.sh:104-132`

---

## Claim 33: "HARDEN's config pairs outrank the repo's config: main's own objects (core.useReplaceRefs there would override GIT_NO_REPLACE_OBJECTS), ... git log's own date format and no signature check (a bad log.date stops git log; log.showSignature runs gpg.program)."

**Location:** `scripts/lib/dev-cycle-read.sh:333-338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the replace-refs, log.date and showSignature reasons, executed. The hook, fsmonitor, attributes, multi-pack-index and commit-graph reasons carry over from build-loop.sh's earlier comment and were not re-run here.
**Legibility-target:** for-orchestrator-synthesis

X7: with a replace ref and `GIT_NO_REPLACE_OBJECTS=1`, `cat-file` read `real`. With repo `core.useReplaceRefs=true` as well it read `replaced`. With a count pair `core.useReplaceRefs=false` added it read `real`. P4 covers showSignature (Claim 8). Test 20, with repo `log.date bogus`, passes with the pair in place (S1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:333-338`, `LOGS/rr.log`, `LOGS/probes.log` (P4)

---

## Claim 34: "GIT_CONFIG_GLOBAL=/dev/null and GIT_CONFIG_NOSYSTEM ... GIT_ALLOW_PROTOCOL=none: no transport, so a lazy fetch (a partial clone's missing object) fails however its config was planted."

**Location:** `scripts/lib/dev-cycle-read.sh:338-341`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers build-loop.sh's partial-clone tests and dev-cycle.sh's call log. It does not establish a partial-clone run of dev-cycle.sh itself.
**Legibility-target:** for-orchestrator-synthesis

The export is at `scripts/lib/dev-cycle-read.sh:360`. build-loop-check's tests assert `[ ! -e "$BATS_TEST_TMPDIR/fetched" ] || { echo "upload-pack ran"; ...}` (`test/scripts/build-loop-check.bats:1685`, `:1729`) and pass (S1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:360`, `test/scripts/build-loop-check.bats:1685`, `test/scripts/build-loop-check.bats:1729`, `LOGS/build-loop-check.log`

---

## Claim 35: "The caller's own pairs (git -c, GIT_CONFIG_COUNT) still apply, git -c ones after HARDEN's: CALLER_COUNT keeps the caller's count for build-loop.sh's caller_gate, which refuses a HARDEN key there by name."

**Location:** `scripts/lib/dev-cycle-read.sh:341-344`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same as Claims 6 and 26.
**Legibility-target:** for-orchestrator-synthesis

`CALLER_COUNT="$c"` is set before the loop (`scripts/lib/dev-cycle-read.sh:356`) and read at `scripts/build-loop.sh:564`. X1 and c1 show the precedence and the refusal.

**Evidence:** `scripts/lib/dev-cycle-read.sh:351-361`, `scripts/build-loop.sh:564`, `LOGS/prec.log`, `LOGS/c1.log`

---

## Claim 36: "A GIT_CONFIG_COUNT that is not plain decimal (010 reads as 8 here and as 10 to git) exits 1."

**Location:** `scripts/lib/dev-cycle-read.sh:344-346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 and bash 5.2.
**Legibility-target:** for-orchestrator-synthesis

P3: with `GIT_CONFIG_COUNT=010` and keys 0-9 set, git listed `x.k7`, `x.k8` and `x.k9`, so it counted 10. Bash's `$((c + 0))` gave 8. Sourcing the lib and calling git_harden printed "GIT_CONFIG_COUNT is not a plain decimal count", exit 1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:354`, `LOGS/probes.log` (P3)

---

## Claim 37: "What these cannot switch off, build-loop.sh's state gate refuses in its gated modes; dev-cycle.sh runs no state gate (row 548)."

**Location:** `scripts/lib/dev-cycle-read.sh:346-347`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which script runs a state gate. It does not establish the state gate's completeness.
**Legibility-target:** for-orchestrator-synthesis

dev-cycle.sh has no `state_gate` call (paraphrased — no quote available because this is a claim about absence: grep finds none in `scripts/dev-cycle.sh`). Row 548 is cited correctly (`docs/reviews/override-log.md:548`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:346-347`, `docs/reviews/override-log.md:548`

---

## Claim 38: "A second call returns at once: it would count HARDEN's pairs as the caller's."

**Location:** `scripts/lib/dev-cycle-read.sh:347-348`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a second call in one process. A child that sources the lib again starts with `CALLER_COUNT=""` (`:350`), but neither script starts such a child.
**Legibility-target:** for-orchestrator-synthesis

The guard is `[[ -z "$CALLER_COUNT" ]] || return 0` (`:352`). Mutant n2 removed it, and test 19 (two calls, `caller 1`, `GIT_CONFIG_COUNT=9`) went red (M).

**Evidence:** `scripts/lib/dev-cycle-read.sh:350-361`, `LOGS/n2.log`

---

## Claim 39: "It never reads the working tree, ~/.claude/scripts or a replaced object"

**Location:** `test/lib/d6-snippet.bash:22-23`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the snippet reads to choose and write the script. It does not cover what the chosen script reads afterwards: dev-cycle.sh reads the working tree by design, and would fall back to `$HOME/.claude/scripts/questions.sh` (`scripts/dev-cycle.sh:390`) only if questions.sh were missing beside it, which both snippet paths rule out.
**Legibility-target:** for-orchestrator-synthesis

The snippet's git reads are refs, paths, a type check, the object format and `cat-file --batch` (`test/lib/d6-snippet.bash:47-54`, `:75`, `:59`). All run with `GIT_NO_REPLACE_OBJECTS=1 ... -c core.useReplaceRefs=false` (`:40`), after the refusal of any `refs/replace/` ref (`:47-48`). T33 makes the working tree's four files `exit 9` and still runs main's (`test/scripts/build-loop-orchestrator.bats:252-260`), and it passes (S1).

**Evidence:** `test/lib/d6-snippet.bash:40-79`, `test/scripts/build-loop-orchestrator.bats:245-269`

---

## Claim 40: "It prints "main" once the four files are written, "other" when the first-parent root is not D6_ROOT; any failure dies (status 255)."

**Location:** `test/lib/d6-snippet.bash:55-57`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the outputs and exit statuses P2 produced. The bash side tests only for non-zero (`|| no`, `:78`), so the imprecision changes no outcome.
**Legibility-target:** for-author

P2: a missing object exits 255, but a failed `open(my $fh, ">", ...)` exits 2. Perl's `die` exits with `$!` when it is set, and 255 only otherwise. "main" and "other" print as described, each with exit 0. A more precise comment would say "any failure dies (a non-zero status)".

**Evidence:** `test/lib/d6-snippet.bash:55-71`, `LOGS/probes.log` (P2)

---

## Claim 41: "Not log.date: git_harden's log.date pair overrides it (row 505); a bad boolean still stops git log."

**Location:** `test/scripts/build-loop-check.bats:1660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers log.abbrevCommit=bogus against git 2.39.5.
**Legibility-target:** for-orchestrator-synthesis

The test sets `git config log.abbrevCommit bogus` and expects the `skip ...` line (`:1661-1663`). It passes (S1). Test 20 shows that a repo `log.date bogus` no longer stops anything.

**Evidence:** `test/scripts/build-loop-check.bats:1658-1668`, `LOGS/build-loop-check.log`

---

## Claim 42: "every git call --check makes carries git_harden's config pairs ..." / "HARDEN from the lib itself, so a key added there is checked here too."

**Location:** `test/scripts/build-loop-check.bats:1689`, `:1699`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's loop source and its result.
**Legibility-target:** for-orchestrator-synthesis

`for kv in $(bash -c 'source "$1"; echo "${HARDEN[*]}"' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh") G=/dev/null P=none S=1` (`:1700`). Passes (S1).

**Evidence:** `test/scripts/build-loop-check.bats:1689-1703`, `LOGS/build-loop-check.log`

---

## Claim 43: "A plain caller pair passes; a count git_harden would misread stops every mode (row 276)."

**Location:** `test/scripts/build-loop-orchestrator.bats:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts `010 08 1x " 1"` against `--settings`, as the test loops them.
**Legibility-target:** for-orchestrator-synthesis

`for c in 010 08 1x " 1"; do run ... bash "$BL" --settings` (`:52-53`). Passes (S1), and X4 gives the same for dev-cycle.sh.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:50-56`, `LOGS/build-loop-orchestrator.log`

---

## Claim 44: T33: "the D6 snippet runs main's four scripts from a fresh temp dir, each with its own lib and questions.sh, never the working tree's, and removes the dir", with its comments ("The snippet exports no config pair, so --state run through it passes caller_gate (row 702)"; "A byte the reader did not hash is never used"; byte-equality "pending until U4").

**Location:** `test/scripts/build-loop-orchestrator.bats:245`, `:257`, `:262`, `:268`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts and that it passes. Its lib-origin check covers build-loop.sh's run; dev-cycle.sh's lib origin is shown only by the exit 0 (the working tree's lib is `exit 9`). The byte-equality half is a pending comment, as stated.
**Legibility-target:** for-orchestrator-synthesis

The test asserts the lib path `"lib at $TMPDIR/"*/scripts/lib/dev-cycle-read.sh` (`:256`), `--state` printing `ok` (`:258`), main's questions.sh line `Q-001  trigger  from-main` (`:260`), an empty TMPDIR (`:261`, `:267`), and the tamper refusal (`:265-266`). It passes (S1). Mutants m1 (hash check off, at a0014ce5) and m4a (working tree's script run) each turned it red (M).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:245-269`, `LOGS/m1.log`, `LOGS/m4a.log`

---

## Claim 45: T36: "refuses before running anything: a blob or commit replace ref, info/grafts, not exactly one plain main or master" and "git refuses to update-ref a branch to a tag: write the ref file (row 656's case)."

**Location:** `test/scripts/build-loop-orchestrator.bats:271`, `:279`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's update-ref refusal and the test's cases.
**Legibility-target:** for-orchestrator-synthesis

X5: `git update-ref refs/heads/x <tag>` gave "fatal: ... trying to write non-commit object ... to branch", exit 128. The test passes (S1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:271-284`, `LOGS/t14.log`

---

## Claim 46: Test names: "refuses the scripts/ tree rewritten in place, and runs no planted bytes"; "refuses a first-parent commit rewritten in place to end main's history at D6_ROOT"; "refuses, never falls to the image copy, when main's first-parent history cannot be read whole: a missing commit, a shallow clone"

**Location:** `test/scripts/build-loop-orchestrator.bats:290`, `:300`, `:310`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each test's assertion of exit 2 and the A1 line.
**Legibility-target:** for-orchestrator-synthesis

Each asserts `[ "$status" -eq 2 ] && [ "$output" = "$A1" ]` (`:297`, `:307`, `:312`, `:314`). All pass (S1). n1 turned `:310` red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:286-315`, `LOGS/n1.log`

---

## Claim 47: "git names the mismatch on stderr too; the one stdout line is the snippet's."

**Location:** `test/scripts/build-loop-orchestrator.bats:306`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this test's scenario under 5583a2cd's and d9515d09's snippets. The test's assertion does not depend on the comment.
**Legibility-target:** for-author

X6, under d9515d09's snippet: stderr held git's `error: hash mismatch ebf96dc3...` lines, as the comment says. X5, under 5583a2cd's verified reader, with the same steps: stderr holds only perl's "b7480a53... does not hash to its id". git prints nothing. The fix: "perl names the mismatch on stderr; the one stdout line is the snippet's". Comment only.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:300-308`, `LOGS/t14.log`, `LOGS/t14b.log`

---

## Claim 48: T27: "a gate copy patched in the loop's worktree prints ok for its tip; the D6 snippet's copy from main refuses the same tip"

**Location:** `test/scripts/build-loop-orchestrator.bats:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted ok and refuse lines.
**Legibility-target:** for-orchestrator-synthesis

It asserts `ok $B` from the patched copy (`:324`) and `refuse $B: 1 of 2 changed paths refused ...` through the snippet (`:326-327`). It passes (S1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:317-328`

---

## Claim 49: T37: "outside claude-workflows the D6 snippet runs the image copy by absolute path, not main's copy" and "refuses an image copy the uid owns, and never runs main's"

**Location:** `test/scripts/build-loop-orchestrator.bats:330`, `:338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tests, which ran here (the /opt half did not skip). "Never runs main's" rests on the exact single refusal line with empty stderr. Main's copy prints "main copy", which would show.
**Legibility-target:** for-orchestrator-synthesis

Both pass (S1). m2 turned `:338` red (M).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:330-344`, `LOGS/m2.log`

---

## Claim 50: Test names: "git_harden exports HARDEN's pairs after the caller's and a fixed environment, once however often it is called; the D6 snippet's git carries the same" and "every git call dev-cycle.sh makes carries git_harden's pairs: a bogus log.date stops nothing, log.showSignature runs no gpg.program"

**Location:** `test/scripts/build-loop-orchestrator.bats:346`, `:363`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each test's assertions.
**Legibility-target:** for-orchestrator-synthesis

Both pass (S1). n2 turned `:346` red, and m3 and m4b turned `:363` red (M).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:346-380`, `LOGS/mutants.out`

---

## Claim 51: Commit 9925f2a7: "Moves build-loop.sh's harden, HARDEN and its environment exports into the lib as git_harden ... HARDEN gains log.date=default ... and log.showSignature=false (git log would run gpg.program). Notes: ... a host repo that needs a global safe.directory would stop."

**Location:** commit `9925f2a7`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same as Claims 7, 8 and 28 (safe.directory simulated).
**Legibility-target:** for-orchestrator-synthesis

See Claims 7, 8 and 28 (P4, X2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:326-361`, `LOGS/probes.log`, `LOGS/safe.log`

---

## Claim 52: Commit a0014ce5: "extracts main's four scripts into a fresh temp dir, hash-checks each against main's tree ... T33 (own lib and questions.sh, working tree ignored, temp dir removed, a tampered extraction refused, --state passes ...) ... Mutants checked: hash check removed, ownership check removed, log.showSignature pair removed, main's dev-cycle.sh: each turns a test red."

**Location:** commit `a0014ce5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claims against a0014ce5's own code and tests. "Main's dev-cycle.sh" was run under both readings (the working tree's script run instead of main's, m4a; main's pre-git_harden dev-cycle.sh, m4b), and both are red. It does not re-establish i1's A1, which showed this design insufficient.
**Legibility-target:** for-orchestrator-synthesis

At a0014ce5, `[[ "$(g hash-object --no-filters "$d/scripts/${F[i]}")" == "${ids[i]}" ]] || no ...` compares each extracted file to ids from `ls-tree` (paraphrased — no quote available beyond this line because the file is quoted from `git show a0014ce5:test/lib/d6-snippet.bash`, not the worktree). Its T33 holds `d6 build-loop.sh --state` (its line 258) and a `cat-file blob` tamper shim (its line 264). M: an unmutated a0 run was 7/7 ok, and m1, m2, m3, m4a and m4b were each 1 not ok.

**Evidence:** `LOGS/mutants.out`, `LOGS/{a0,m1,m2,m3,m4a,m4b}.log`

---

## Claim 53: Commit d9515d09: "In claude-workflows it now re-hashes, in one cat-file --batch pass SHA-1'd in perl, every first-parent commit of main (which the root check walked) and the trees down to scripts/lib/. Two tests: a rewritten scripts tree, and a tip rewritten to forge the root. A2: the default branch's ref must name a commit itself ... Notes: about 0.1 s over this repository's ~1,100 first-parent commits."

**Location:** commit `d9515d09`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d9515d09's own code. X3 timed the whole snippet run, an upper bound on the re-hash. It does not cover i2's B1, which showed this design insufficient.
**Legibility-target:** for-orchestrator-synthesis

d9515d09's code pipes `g rev-list --first-parent "$sha" && g rev-parse "$sha^{tree}" "$sha:scripts" "$sha:scripts/lib"` into `g cat-file --batch | perl -MDigest::SHA=sha1_hex ...` (`git show d9515d09:test/lib/d6-snippet.bash`). X6: that snippet refused test 14's tip rewrite. X3: the whole d9515d09 snippet ran in 0.073-0.081 s, over 1,122 first-parent commits (`git rev-list --first-parent --count main`).

**Evidence:** `LOGS/t14b.log`, `LOGS/time.log`

---

## Claim 54a: Commit c9648432: "one perl process drives one cat-file --batch, uses an object only once its bytes SHA-1 to its id, and takes every next id from bytes it checked ... The two-pack probe now runs main's real scripts. B2: any read failure refuses ... a repository that is not SHA-1 takes the image copy. B11: one history walk instead of two. B4: --state's header names HARDEN's eight keys. ... B8: git_harden returns on a second call. B9: both call-log tests loop over the lib's HARDEN."

**Location:** commit `c9648432`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed items. The two-copy probe here was pack plus loose (P5), not i2's two packs.
**Legibility-target:** for-orchestrator-synthesis

See Claims 13 (P5), 14, 3b, 24, 38 and 42 (`test/scripts/build-loop-check.bats:1700`, `test/scripts/build-loop-orchestrator.bats:377`).

**Evidence:** `test/lib/d6-snippet.bash:58-86`, `LOGS/probes.log`, `LOGS/mutants.out`

---

## Claim 54b: Commit c9648432: "B10: store_check and the snippet's reader name each other."

**Location:** commit `c9648432`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** The same as Claim 23. The commit message is immutable, so the fix belongs in the snippet's comment.
**Legibility-target:** for-author

Only `scripts/build-loop.sh:928-930` names the snippet. `test/lib/d6-snippet.bash` at c9648432 has no "store" anywhere (paraphrased — no quote available because this is a claim about absence: `git show c9648432:test/lib/d6-snippet.bash | grep -ci store` gives 0).

**Evidence:** `scripts/build-loop.sh:927-930`, `test/lib/d6-snippet.bash:1-92`

---

## Claim 54c: Commit c9648432: "Mutants: no refusal on a failed read (B2 test red); git_harden called twice (environment test pins one count)."

**Location:** commit `c9648432`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two mutants as this pass built them (n1: `|| x=other`; n2: the guard removed).
**Legibility-target:** for-orchestrator-synthesis

M: an unmutated c0 run was 10/10 ok. n1 failed test "refuses, never falls to the image copy", and n2 failed "git_harden exports ...".

**Evidence:** `LOGS/mutants.out`, `LOGS/n1.log`, `LOGS/n2.log`

---

## Claim 54d: Commit c9648432: "Suites: 285/285."

**Location:** commit `c9648432`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the seven suites S1 ran. The commit names no suite set, so 285 could not be matched to one.
**Legibility-target:** for-orchestrator-synthesis

S1: build-loop-orchestrator, build-loop-check, build-loop-read, build-loop-dispatch, build-loop-merge, dev-cycle and fixture-git-env gave 283/283 green. The code is unchanged between c9648432 and 5583a2cd (docs only). No set of the unit's suites totals 285 without adding unrelated suites. To verify, the commit would need to name its suites. This matches the logged pattern class of test-tally claims ("mode1-equiv 33 ... holds 25"), but nothing here shows the number is wrong rather than taken over a different set.

**Evidence:** `LOGS/suites.ts`, `LOGS/*.log`

---

## Claim 55: Commit 5583a2cd: "U3b3 iteration 2: reports, rubric, seven override rows"

**Location:** commit `5583a2cd`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row count.
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/override-log.md:732-738` are the seven added rows tagged `feat/build-loop-u3b3`.

**Evidence:** `docs/reviews/override-log.md:732-738`

---

## Claims Requiring Attention

### Incorrect
- **Claim 23** (`docs/working/plan-build-loop-handoff.md:326`): "each comment names the other". Only store_check's comment names the snippet, and the snippet names no store_check. Add the reference in `test/lib/d6-snippet.bash:55-57` or reword the note. Comment/doc.
- **Claim 54b** (commit c9648432): "B10: store_check and the snippet's reader name each other". This is the same gap, and the message is immutable, so fix it via Claim 23. Comment/doc.

### Stale
- **Claim 47** (`test/scripts/build-loop-orchestrator.bats:306`): "git names the mismatch on stderr too". That was true under d9515d09. Under the verified reader only perl writes to stderr. Comment only.

### Mostly Accurate
- **Claim 3a** (`docs/reviews/override-log.md:734`): "~70 ms of fixed fork overhead". It measures ~95-100 ms here, part of it linear in main's first-parent history. Doc.
- **Claim 12** (`docs/working/plan-build-loop-handoff.md:326`; `test/lib/d6-snippet.bash:34-35`): "left to the script's default_gate" and "the script's own state and default-branch gates" hold for build-loop.sh only. dev-cycle.sh has neither (row 548). Comment/doc.
- **Claim 40** (`test/lib/d6-snippet.bash:57`): "any failure dies (status 255)". A failed open died with exit 2, so say "non-zero". Comment only. The bash side is unaffected.

### Unverifiable
- **Claim 10** (plan note; a0014ce5): the zsh alias `g` incident needs the session transcript.
- **Claim 16** (plan note): "the -w test makes a root run refuse" needs a uid-0 run.
- **Claim 54d** (c9648432): "Suites: 285/285". 283/283 was reproduced over seven suites, and the commit's suite set is unnamed.

## Re-flagged settled decisions
- Claim 12's residue is row 548 (dev-cycle.sh runs no state_gate or default_gate). It is settled; only the snippet's and the plan note's wording overreach.
- Claim 21's residue (a racer after the write into the 0700 dir) is row 509's Q-103 class.
- Claim 13's residue (a commit header with a late `parent` line read differently by perl and git) needs a main the loop has moved: row 732's class.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/code-fact-check-report-2026-10-12-u3b3-final-r1.md, structured per the code-fact-check skill.
- Answered: yes. All ten brief focus areas were checked against code and tests. All seven related suites were run (283/283). Every executable claim was executed except two blocked ones (uid 0 for Claim 16; the transcript for Claim 10), plus the commit's unnamed suite set (Claim 54d). Mutants were re-run for both commit messages that cite them.
- Out of scope: the security judgement on escalation 1, which is security-reviewer's. docs/reviews/hallucination-patterns.md was not edited, because no fabrication was found and the brief allows writing only this report.
- Escalate: (1) security-reviewer / orchestrator, `test/lib/d6-snippet.bash:67` (`if ($c ne $root) { print "other\n"; exit 0 }`). The snippet decides "claude-workflows or not" from main's first-parent root id alone. P6 copied 640cf007's commit object (public, and same-uid readable from /workspace) into an unrelated repository, then pointed main at a commit with that parent and planted scripts. The snippet ran the planted `build-loop.sh` (exit 0), not the root-owned /opt copy. This needs a loop that moves main, which is row 732's Won't-Fix class. But row 732 and the plan note describe a moved main "on top of the real history" in claude-workflows. In every other project, the same move defeats the image copy's ownership checks, which exist for exactly those projects. Confirm that row 732 covers it, or route it (for example, require the D6_ROOT path only when the repository also passes some non-forgeable test, or record the residual).
- Decisions I made: I counted the `GIT_LITERAL_PATHSPECS=0` pathspec overrides (md_ls, matches) as outside "hardened", because the comments define hardening as config pairs, config files and transport. I recorded them in Scope fields, not as findings. For row 200 I read "every byte run" as the extraction path, which is what row 200 is about. I kept probe logs in the session scratchpad, not docs/reviews/execution-logs, to honour the write-only-this-file rule.
