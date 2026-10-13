Commit: 5583a2cd

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b3 (branch `feat/build-loop-u3b3`)
**Scope:** branch diff `main...5583a2cd` (final confirming pass, iteration 3 of 3, replicate fc3-1 of k=3): `docs/working/plan-build-loop-handoff.md` (U3b3 as-built note), `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `test/lib/d6-snippet.bash`, `test/scripts/build-loop-check.bats`, `test/scripts/build-loop-orchestrator.bats`, the seven new override rows (`docs/reviews/override-log.md:732-738`), and the messages of 9925f2a7, a0014ce5, d9515d09, c9648432, 5583a2cd (7a927183 and 5d175c0e carry no checkable body)
**Checked:** 2026-10-12
**Replication:** k=3, this is one replicate (fc3-1)
**Total claims checked:** 87
**Summary:** 75 verified, 5 mostly accurate, 1 stale, 2 incorrect, 4 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). No claim matches a logged pattern. The two Incorrect claims (26b, 81) say a cross-reference comment exists in `test/lib/d6-snippet.bash` when it does not. That is close to the log's "symbol claimed to exist" class. The log is not edited here because the dispatch allows writing only this file; the orchestrator can decide whether to add it.

**Prior-iteration fixes.** The iteration 1 and 2 items the rubric marks Fixed hold, with two exceptions. B10 ("store_check and the snippet's reader name each other") is only half done: Claims 26b and 81. A comment that d9515d09 made true went stale under c9648432's rewrite: Claim 62b. No behavioural fix re-fires. The two-pack forgery (B1) runs main's real scripts whichever pack git reads first (Claim 15). Any read failure refuses (B2, Claim 16). The mutants for both fixes turn tests red (Claim 82).

**Execution provenance (shared by every `executed` claim).** All runs were made as uid 1000 with git 2.39.5, GNU bash 5.2, perl 5.36.0 and `LC_ALL=C`. Every probe script starts with `set -eu`, creates its own `mktemp -d /tmp/u3b3-fc31*-XXXX`, refuses to continue outside it, and removes it. None was left behind (checked after the last run). No background process is left. Scripts and captured output are in `LOGS/` = `/tmp/claude-1000/-workspace/c69d4d0f-5190-473b-ba2f-85b5a43f49ee/scratchpad/fc3-1/`. Times are -07:00.
- **E1**: `bats test/scripts/build-loop-orchestrator.bats`, cwd the worktree, own TMPDIR, 2026-10-12T18:52:33, exit 0. Result: 20/20 ok. Test 17 (T37's real /opt half) ran rather than skipping, because a root-owned `/opt/claude-workflows` exists here (`LOGS/bats-orch.log`).
- **E2**: `bash LOGS/probe1.sh`, cwd /, 18:55:48, exit 0 (`LOGS/probe1.log`). Covers: P1, repo `core.useReplaceRefs=true` against `GIT_NO_REPLACE_OBJECTS=1`; P2, `log.date=bogus` and `log.showSignature` with gpg.program; P3, count pair against `git -c` against repo config; P4, main's and the branch's dev-cycle.sh digest under a planted showSignature/gpg.program and `log.date=bogus`; P5, dev-cycle.sh with `GIT_CONFIG_COUNT` 010 and 1x; P6, another owner simulated with `GIT_TEST_ASSUME_DIFFERENT_OWNER=1` and a global `safe.directory=*`; P7, git calls made while sourcing the lib, and the digest's calls, questions.sh's among them, logged by a shim.
- **E3**: `bash LOGS/mutants.sh`, cwd /, 18:56:17, exit 0 (`LOGS/mutants.log`). Six mutants M1-M6 against `git archive 5583a2cd scripts test` copies, each run through the orchestrator suite.
- **E4**: `bash LOGS/probe2.sh`, cwd /, 18:56:53, exit 0 (`LOGS/probe2.log`). F1/F2 add a second pack whose hand-edited idx maps main's build-loop.sh blob id to planted bytes, newer (F1) or older (F2) than the real pack. E feeds the perl reader a missing tip, a tree as tip, an unwritable out dir and another root.
- **E5**: `bash LOGS/mutants-a00.sh`, cwd /, 18:58:14, exit 0 (`LOGS/mutants-a00.log`). a0014ce5's four named mutants against an a0014ce5 archive. The baseline a0014ce5 suite passes 17/17 (`LOGS/baseline-a00.log`).
- **E6**: `bash LOGS/probe3.sh`, cwd /, 18:59:13, exit 0 (`LOGS/probe3.log`). Runs `--state` with a caller pair for log.date and for log.showSignature. Feeds the snippet through `bash -s -- build-loop.sh --stdin <<'D6'` with main's build-loop.sh printing its stdin.
- **E7**: `bats --filter 'row 307|T26, A4|partial' test/scripts/build-loop-check.bats`, cwd the worktree, 18:59:31, exit 0, 4/4 ok (`LOGS/bats-check-filter.log`).
- **E8**: `bash test/lib/d6-snippet.bash build-loop.sh --settings` in the real repository (the worktree), 18:59:44, exit 0, temp dir empty afterwards (`LOGS/real-repo-d6.log`).
- **E9**: the snippet's perl program (`P`), run alone against the real repository with D6_ROOT 640cf007, 18:59:52, exit 0. It printed `main`, and the four written files hash to main's blobs (`LOGS/real-repo-reader.log`).
- **E10**: timing: the snippet, a direct run and the reader alone, three runs each (`LOGS/timing.log`).
- **E11**: `bash LOGS/probe4.sh`, cwd /, 19:03:10, exit 0. Test 14's scenario, with the snippet's stderr captured (`LOGS/probe4.log`).
- **E12**: `bash LOGS/probe5.sh`, cwd /, 19:03:32, exit 0. A caller's `GIT_CONFIG_PARAMETERS` against a later `git -c` (`LOGS/probe5.log`).

---

## Claim 1: "The snippet trusts refs/heads/main itself: a same-uid loop that moves main's ref onto its own commit on top of the real history passes every hash check, and the snippet runs that commit's scripts ... Stated in the snippet's header."

**Location:** `docs/reviews/override-log.md:732`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the tip id comes from and whether the header states the trust. It does not establish the Won't-Fix ruling (Q-103's).
**Legibility-target:** for-orchestrator-synthesis

The tip is `sha="$(g rev-parse --verify -q "refs/heads/$m")"` (`test/lib/d6-snippet.bash:54`), and the reader starts its walk there (`:78`). A forged tip whose history and tree hash correctly passes. The header states it: "it trusts refs/heads/main itself (a moved main is --main-log's to report, D13; F19, rows 509, 721)" (`test/lib/d6-snippet.bash:23-24`).

**Evidence:** `test/lib/d6-snippet.bash:23-24`, `test/lib/d6-snippet.bash:54`, `test/lib/d6-snippet.bash:78`

---

## Claim 2: "The snippet's own re-hash is plain SHA-1 with no collision detection ... Revisit trigger: claude-workflows moves to SHA-256 (the snippet then takes the image copy)"

**Location:** `docs/reviews/override-log.md:733`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hash primitive and the non-SHA-1 branch. It does not establish the row's risk judgement.
**Legibility-target:** for-orchestrator-synthesis

The reader uses `use Digest::SHA qw(sha1_hex)` and `sha1_hex("$t $s\0$b") eq $id` (`test/lib/d6-snippet.bash:58`, `:62`). That is plain SHA-1. The non-SHA-1 branch is `if [[ "$x" == sha1 ]]; then ... else x=other; fi` (`:77-79`), and `other` takes `d="$D6_OPT"` (`:83`).

**Evidence:** `test/lib/d6-snippet.bash:58-62`, `test/lib/d6-snippet.bash:75-85`

---

## Claim 3: "Each snippet call pays ~70 ms of fixed fork overhead over a direct run ... the verified reader already cut the history walks from two to one."

**Location:** `docs/reviews/override-log.md:734`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the measured overhead in this repository at 1,122 first-parent commits, and the single walk. It does not establish the timing on other hosts.
**Legibility-target:** for-author

The magnitude is right, but most of the overhead is not fixed. E10 measured the snippet at 110-137 ms against 33-35 ms for a direct `--settings` run. The perl reader alone took 61-63 ms, and it walks every first-parent commit: `my $tree; while (1) { my ($hd) = split /\n\n/, obj($c, "commit"), 2; ... last unless defined $p; $c = $p }` (`test/lib/d6-snippet.bash:65-66`). So about 60 ms of the ~80 ms grows linearly with main's history. "One walk" holds: no rev-list is left in the file (paraphrased — no quote available because the claim is an absence; `rg rev-list test/lib/d6-snippet.bash` has no hit). A precise version: "~80 ms over a direct run, about 60 ms of it the reader's walk, linear in main's first-parent commits."

**Evidence:** `test/lib/d6-snippet.bash:65-66`, `LOGS/timing.log`

---

## Claim 4: "`refuse d6: WHY` (exit 2) can now precede any mode's output ... Contract for U4, written into the plan's as-built note"

**Location:** `docs/reviews/override-log.md:735`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal's position and the plan hand-off text. It does not establish U4's parser.
**Legibility-target:** for-orchestrator-synthesis

`no() { echo "refuse d6: $*"; exit 2; }` (`test/lib/d6-snippet.bash:39`) runs before `bash "$d/scripts/$s"` (`:87`) for every mode. The plan says: "match a first line starting `refuse d6: ` before parsing any mode's output, as a stop, never as a brief's verdict" (`docs/working/plan-build-loop-handoff.md:326`).

**Evidence:** `test/lib/d6-snippet.bash:39`, `test/lib/d6-snippet.bash:87`, `docs/working/plan-build-loop-handoff.md:326`

---

## Claim 5: "as built it cannot be one: the lib cannot be sourced before it is checked, it runs once per process, exporting it makes --state refuse (row 702), and the snippet's G lives only in its own bash"

**Location:** `docs/reviews/override-log.md:736`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four stated reasons. It does not establish which option U4 takes.
**Legibility-target:** for-orchestrator-synthesis

Runs once: `[[ -z "$CALLER_COUNT" ]] || return 0` (`scripts/lib/dev-cycle-read.sh:352`), pinned by test 19 (E1, M5 red in E3). Exported pairs refuse: orchestrator test 2 passes `GIT_CONFIG_COUNT=2 ... GIT_CONFIG_KEY_1=core.hooksPath ... --state` to `refuse state core.hookspath` (`test/scripts/build-loop-orchestrator.bats:48-49`). E6 shows the same refusal for log.date and log.showSignature. G is local to the snippet's bash: `G=(env ...)` inside `d6()` (`test/lib/d6-snippet.bash:40`), run by a separate `bash -s`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:351-361`, `test/lib/d6-snippet.bash:36-41`, `test/scripts/build-loop-orchestrator.bats:48-49`, `LOGS/bats-orch.log`, `LOGS/probe3.log`, `LOGS/mutants.log`

---

## Claim 6: "The snippet passes HARDEN as git -c pairs, which outrank a caller's git -c; git_harden passes them as count pairs, which a caller's git -c outranks"

**Location:** `docs/reviews/override-log.md:737`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's ordering of inherited GIT_CONFIG_PARAMETERS, a later `-c`, and count pairs. It does not establish other git versions.
**Legibility-target:** for-orchestrator-synthesis

E12: a caller's `GIT_CONFIG_PARAMETERS` log.date=bogus, then `git -c log.date=default`, exits 0. The reverse exits 128, so the later `-c` wins. E2 P3: a count pair `log.date=default` with `git -c log.date=bogus` fails, so `-c` outranks the count. The snippet's pairs are `-c` (`test/lib/d6-snippet.bash:40`). git_harden's are count pairs (`scripts/lib/dev-cycle-read.sh:357-358`).

**Evidence:** `test/lib/d6-snippet.bash:40`, `scripts/lib/dev-cycle-read.sh:357-360`, `LOGS/probe5.log`, `LOGS/probe1.log`

---

## Claim 7: "The canonical D6 source sits in test/lib/ beside fixtures; the plan calls it a copy of the SKILL.md block, its header the reverse"

**Location:** `docs/reviews/override-log.md:738`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two texts. It does not establish which copy U4 makes canonical.
**Legibility-target:** for-orchestrator-synthesis

The plan says "`test/lib/d6-snippet.bash`, a byte copy of the SKILL.md block" (`docs/working/plan-build-loop-handoff.md:321`). The header says "U4 puts this file, byte for byte, in skills/dev-cycle/SKILL.md" (`test/lib/d6-snippet.bash:3`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:321`, `test/lib/d6-snippet.bash:2-5`

---

## Claim 8: "`git_harden` (lib) holds HARDEN, CALLER_COUNT and the environment build-loop.sh exported ... build-loop.sh and dev-cycle.sh call it after scrub_reexec, before their first git call; a second call returns at once."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exported set against the removed build-loop.sh export, the call position in both scripts, the lib's source-time calls and idempotence. It does not establish that no later call overrides the settings (Claim 28 covers build-loop.sh's two exceptions).
**Legibility-target:** for-orchestrator-synthesis

The removed line was `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none` (diff, old build-loop.sh). The lib now exports the same seven plus `GIT_CONFIG_COUNT="$c"` (`scripts/lib/dev-cycle-read.sh:360`). The call order in build-loop.sh is `source "$READ_LIB"` / `scrub_reexec` (`scripts/build-loop.sh:442-443`), then arg parsing, whose only helper `readerform` is pure bash (`scripts/lib/dev-cycle-read.sh:634-638`), then `git_harden` (`scripts/build-loop.sh:497`). dev-cycle.sh: `scrub_reexec` (`:104`), the arg loop (sed only), `git_harden` (`:131`), then the first git call (`:132`). E2 P7: sourcing the lib makes 0 git calls. Test 19 calls it twice and pins `GIT_CONFIG_COUNT=9` (E1). Removing the guard turns test 19 red (E3 M5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:349-361`, `scripts/build-loop.sh:439-497`, `scripts/dev-cycle.sh:96-132`, `test/scripts/build-loop-orchestrator.bats:346-361`, `LOGS/probe1.log`, `LOGS/mutants.log`

---

## Claim 9: "HARDEN gains `log.date=default` (row 505: a bogus log.date stopped --check-brief) and `log.showSignature=false` (a planted one made the digest's git log run gpg.program on main); caller_gate refuses both keys by name with the rest."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both pairs, main's digest failing and running gpg without them, and caller_gate's refusal. It does not establish behaviour on a git newer than 2.39.5.
**Legibility-target:** for-orchestrator-synthesis

`HARDEN=(... log.date=default log.showSignature=false)` (`scripts/lib/dev-cycle-read.sh:349`). E2 P4 ran main's dev-cycle.sh digest and got "gpg ran"; the branch's got "gpg did not run". Under `log.date=bogus`, main's digest exits 128 ("fatal: unknown date format bogus") and the branch's exits 0. caller_gate loops over HARDEN: `for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done` (`scripts/build-loop.sh:567`). E6 got `refuse state log.date: ...` and `refuse state log.showsignature: ...`, both exit 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:349`, `scripts/build-loop.sh:559-573`, `LOGS/probe1.log`, `LOGS/probe3.log`

---

## Claim 10: "dev-cycle.sh now reads no user or system git config and no transport (its header says so)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the environment every dev-cycle.sh git call gets, and the user-config effect through safe.directory. It does not execute a lazy fetch through dev-cycle.sh (that part rests on `GIT_ALLOW_PROTOCOL=none`).
**Legibility-target:** for-orchestrator-synthesis

E2 P7: every logged digest call carries `G=/dev/null P=none S=1`. E2 P6: with a global `safe.directory=*` and a simulated other owner, plain git exits 0. The branch's dev-cycle.sh exits 1 with "Not inside a git repository", so the global config is not read. The header says so at `scripts/dev-cycle.sh:83-86`.

**Evidence:** `scripts/dev-cycle.sh:83-86`, `scripts/lib/dev-cycle-read.sh:360`, `LOGS/probe1.log`

---

## Claim 11: "`test/lib/d6-snippet.bash` is a script bash reads, not a function pasted into the caller's shell ... U4's SKILL.md feeds the file, byte for byte, to `bash -s -- SCRIPT ARG... <<'D6'`, and the snippet runs everything with stdin from /dev/null."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heredoc form run from a bash caller and the stdin of the script it runs. It does not establish a zsh caller (not run).
**Legibility-target:** for-orchestrator-synthesis

The file's last line is `d6 "$@" </dev/null` (`test/lib/d6-snippet.bash:92`). E6 fed it through `bash -s -- build-loop.sh --stdin <<'D6'`. Main's build-loop.sh reported its stdin as `/dev/null`, and the caller continued with `exit 0`.

**Evidence:** `test/lib/d6-snippet.bash:36`, `test/lib/d6-snippet.bash:92`, `LOGS/probe3.log`

---

## Claim 12: "the Bash tool's shell can be zsh (an alias `g` broke a pasted function)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond the session environment stating zsh. It does not establish the alias incident.
**Legibility-target:** for-orchestrator-synthesis

This session's environment reports "Shell: zsh", and zsh's glob errors appear in this run's tool output (paraphrased — no quote available because it is session metadata, not repository text). The `g` alias incident is in an earlier session's transcript, which is not available here.

**Evidence:** `docs/working/plan-build-loop-handoff.md:326`

---

## Claim 13a: "Checks, in order: no replace ref, no info/grafts, exactly one of refs/heads/main and master, not symbolic, its ref's own object a commit (not peeled from a tag ...)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each check and its order. It does not establish a check on origin/HEAD (13b).
**Legibility-target:** for-orchestrator-synthesis

`test/lib/d6-snippet.bash:47-54`, in order: `for-each-ref ... refs/replace/` → `--git-path info/grafts` → `show-ref --verify -q "refs/heads/$n"` for main and master → `symbolic-ref -q` → `rev-parse --verify -q "refs/heads/$m"` with `cat-file -t` equal to `commit`. Test 12 refuses each case, including an annotated tag written into the ref (E1).

**Evidence:** `test/lib/d6-snippet.bash:47-54`, `test/scripts/build-loop-orchestrator.bats:271-284`, `LOGS/bats-orch.log`

---

## Claim 13b: "(origin/HEAD is left to the script's default_gate)" ... "These checks come before, not instead of, the script's own state and default-branch gates."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which scripts and modes run default_gate and state_gate. It does not establish the settled ruling (row 548).
**Legibility-target:** for-author

This holds for build-loop.sh's gated modes only. dev-cycle.sh defines and runs neither gate, and its `resolve_main` follows origin/HEAD first: `origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD ...)"; [[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")` (`scripts/lib/dev-cycle-read.sh:568-569`). So under the snippet a dev-cycle.sh run can read a branch other than the one the snippet checked. build-loop.sh's read modes are ungated too: `GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1` (`scripts/build-loop.sh:608`). A precise version: "left to build-loop.sh's default_gate in its gated modes; dev-cycle.sh runs none (row 548)". This is a re-flag of settled row 548, not a new defect.

**Evidence:** `scripts/lib/dev-cycle-read.sh:565-587`, `scripts/build-loop.sh:579-598`, `scripts/build-loop.sh:608`, `docs/reviews/override-log.md:548`

---

## Claim 14: "the verified reader ...: one perl process drives one `git cat-file --batch`, uses an object only once its bytes SHA-1 to its id, and takes every next id from bytes it has checked ... No other reader (rev-list, ls-tree) decides what runs"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sources of every id and byte the reader uses: the commit header, tree entries, object header lines, sizes, the batch protocol and the exit the bash side reads. It does not establish that perl's parent parse equals git's for a malformed commit: perl takes the first `^parent` line anywhere in the header, git only the lines after `tree`. Such a commit would have to be in main's own hashed first-parent history.
**Legibility-target:** for-orchestrator-synthesis

`open2(my $r, my $w, @git, "cat-file", "--batch")` is the only reader (`test/lib/d6-snippet.bash:59`). `obj` requires `$i eq $id && $t eq $want && $s =~ /\A[0-9]+\z/ && read($r, $b, $s) == $s && getc($r) eq "\n"` and `sha1_hex("$t $s\0$b") eq $id` (`:61-62`). A `missing` reply has no third field and fails `defined $s`. The next ids come from checked bytes: `$hd =~ /\Atree ([0-9a-f]{40})\n/` and `/^parent ([0-9a-f]{40})$/m` from the commit header (`:65-66`), and `unpack("H*", $id)` from tree entries matched by `/\G([0-7]+) ([^\0]+)\0(.{20})/gs` with exact-name and mode checks (`:64`). A duplicate name takes the first entry. The first id is the ref's tip (Claim 1). E3 M1, which drops the hash line, turns tests 11, 13 and 14 red. E9 in the real repository printed `main`, and all four written files hash to main's blobs.

**Evidence:** `test/lib/d6-snippet.bash:58-71`, `test/lib/d6-snippet.bash:78`, `LOGS/mutants.log`, `LOGS/real-repo-reader.log`

---

## Claim 15: "(i2 B1's two-pack forgery now runs main's real scripts; a forged copy read would refuse)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers a reconstructed two-pack forgery (a second pack whose idx maps main's build-loop.sh blob id to planted bytes) with either pack newer, plus the refusal when altered bytes reach the reader. It does not reproduce i2's exact probe.
**Legibility-target:** for-orchestrator-synthesis

E4 F1: with the forged pack newer, plain `git cat-file -p` printed `echo PLANTED; exit 0`, but the snippet exited 0 with main's real `--settings` output. F2 (forged pack older) gave the same result. The forged-read half is test 11's tamper case: a git whose `--batch` output is altered gives the `A1` refusal and "does not hash to its id" on stderr (`test/scripts/build-loop-orchestrator.bats:262-265`, E1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:262-266`, `LOGS/probe2.log`, `LOGS/bats-orch.log`

---

## Claim 16: "Any read failure refuses, never falls to the image copy (i2 B2: a missing first-parent commit, a shallow clone)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reader's failures and the bash steps around it. It does not establish a reader that exits 0 with no output (that path also refuses, through `:86`).
**Legibility-target:** for-orchestrator-synthesis

`x="$(LC_ALL=C perl -e "$P" ...)" || no "$m's first-parent history ..."` (`test/lib/d6-snippet.bash:78`). The fall-through is `else no "the verified reader gave no answer"; fi` (`:86`). Test 15 covers both B2 cases (E1). Mutant M4 (`|| x=other`) turns test 15 red (E3).

**Evidence:** `test/lib/d6-snippet.bash:75-86`, `test/scripts/build-loop-orchestrator.bats:310-315`, `LOGS/mutants.log`

---

## Claim 17: "Another root, or a repository that is not SHA-1, runs `D6_OPT/scripts/SCRIPT` once the four files are regular, root-owned (`stat -c %u`), not symlinks and not writable (`-w`), and so is every directory from `scripts/lib` up to `/`"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the another-root path against the real root-owned /opt copy and a uid-owned copy. The non-SHA-1 path is read, not run.
**Legibility-target:** for-orchestrator-synthesis

`own() { [[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no ...; }` (`test/lib/d6-snippet.bash:42`). Files: `for f in "${F[@]}"; do own "$d/scripts/$f"; [[ -f ... ]] || no ...; done` (`:84`). Directories: `x="$d/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done` (`:85`), which walks lib, scripts, /opt/claude-workflows, /opt and /. Test 17 ran against the real /opt (E1). Test 18 refuses a uid-owned copy. Mutant M2 turns test 18 red (E3).

**Evidence:** `test/lib/d6-snippet.bash:42`, `test/lib/d6-snippet.bash:82-85`, `LOGS/bats-orch.log`, `LOGS/mutants.log`

---

## Claim 18: "(the `-w` test makes a root run refuse unless the mount is read-only)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing executed. It does not establish bash's `-w` result for uid 0 on this kernel.
**Legibility-target:** for-orchestrator-synthesis

This needs a uid 0 run, and this sandbox runs as uid 1000 (paraphrased — no quote available because the blocker is the runtime uid, not code). Execution was required and is blocked.

**Evidence:** `test/lib/d6-snippet.bash:42`

---

## Claim 19: "The run has BASH_ENV, ENV and DEV_CYCLE_SCRUBBED unset; the temp dir is removed on exit."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the run line and removal after success and after a refusal. It does not establish removal after a SIGKILL.
**Legibility-target:** for-orchestrator-synthesis

`env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"` (`test/lib/d6-snippet.bash:87`) and `trap 'rm -rf "$t"' EXIT` (`:73`). Test 11 asserts `[ -z "$(ls -A "$TMPDIR")" ]` after the runs and after the tamper refusal (E1). E8's real-repository run left the temp dir empty.

**Evidence:** `test/lib/d6-snippet.bash:72-73`, `test/lib/d6-snippet.bash:87`, `LOGS/real-repo-d6.log`

---

## Claim 20: "Refusal: one `refuse d6: WHY` line on stdout and exit 2, nothing run (git or perl may add a stderr line); exit 1 for another first argument."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal format and the exit-1 path. It does not establish anything about what stderr contains (Claim 62b).
**Legibility-target:** for-orchestrator-synthesis

`no() { echo "refuse d6: $*"; exit 2; }` (`test/lib/d6-snippet.bash:39`). The usage line is `echo "d6: the first argument is build-loop.sh or dev-cycle.sh" >&2; exit 1` (`:44`). `d6_is` asserts exit 2, one exact stdout line and an empty stderr (`test/scripts/build-loop-orchestrator.bats:237`). Test 12 asserts the exit-1 case (E1).

**Evidence:** `test/lib/d6-snippet.bash:39`, `test/lib/d6-snippet.bash:44`, `test/scripts/build-loop-orchestrator.bats:237`, `test/scripts/build-loop-orchestrator.bats:283`

---

## Claim 21: "Its git carries HARDEN as `-c` and git_harden's variables (G), a test pins the lists equal"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the G array, its use by every git call (the reader's included), and test 19's equality. It does not establish precedence (Claim 6).
**Legibility-target:** for-orchestrator-synthesis

`g() { "${G[@]}" "$@"; }` (`test/lib/d6-snippet.bash:41`), and the reader gets `"${G[@]}"` as its git (`:78`). Test 19 compares the lib's HARDEN and environment with H and E, then G's `-c` list and `GIT_*=` list with the same H and E (`test/scripts/build-loop-orchestrator.bats:347-360`). E3 M3 (one HARDEN pair dropped) turns test 19 red.

**Evidence:** `test/lib/d6-snippet.bash:40-41`, `test/lib/d6-snippet.bash:78`, `test/scripts/build-loop-orchestrator.bats:346-361`, `LOGS/mutants.log`

---

## Claim 22: "The snippet trusts refs/heads/main itself: a moved main is F19's class (... rows 509, 721, and this unit's row)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the cited rows. It does not establish the ruling.
**Legibility-target:** for-orchestrator-synthesis

Row 732 is "The snippet trusts refs/heads/main itself ... Won't-Fix" (`docs/reviews/override-log.md:732`). Rows 509 and 721 exist with the cited subjects.

**Evidence:** `docs/reviews/override-log.md:509`, `docs/reviews/override-log.md:721`, `docs/reviews/override-log.md:732`

---

## Claim 23: "U4 hand-offs (override rows dated 2026-10-12): ... call --state through the snippet, which exports no pair (row 702); write the SKILL.md block, name one canonical copy ..."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the snippet exports no pair and that rows 735, 736 and 738 hold the hand-offs. It does not establish U4's implementation.
**Legibility-target:** for-orchestrator-synthesis

Test 11 runs `d6 build-loop.sh --state` and gets `ok` (`test/scripts/build-loop-orchestrator.bats:257-258`, E1). Rows 735, 736 and 738 are dated 2026-10-12 and keyed `feat/build-loop-u3b3`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:257-258`, `docs/reviews/override-log.md:735-738`

---

## Claim 24: "Rows: 200 discharged (every byte run is hashed before it is written; a writer racing the 0700 dir is the Q-103 class, row 509)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the extraction path (main's four files, the lib among them, hashed before `print $fh $b`). It does not cover the image-copy path, where nothing is hashed and ownership stands in, nor a racer on the 0700 dir (row 509).
**Legibility-target:** for-orchestrator-synthesis

`my $b = obj(entry(...), "blob"); open(my $fh, ">", "$out/scripts/$f") ...; print $fh $b` (`test/lib/d6-snippet.bash:70`). `obj` returns only after the SHA-1 check (`:62`). `t="$(mktemp -d)"` (`:72`) makes a 0700 dir.

**Evidence:** `test/lib/d6-snippet.bash:62`, `test/lib/d6-snippet.bash:69-72`, `docs/reviews/override-log.md:200`

---

## Claim 25: "311 (git_harden's exact environment is pinned)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that dropping GIT_NO_REPLACE_OBJECTS (row 311's case) would fail test 19's exact comparison. That mutant was read, not run.
**Legibility-target:** for-orchestrator-synthesis

Test 19 sets `E="... GIT_NO_REPLACE_OBJECTS=1 ..."` and asserts `[ "$output" = "$want" ]` over `env | grep "^GIT_" | sort` (`test/scripts/build-loop-orchestrator.bats:348-356`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:346-356`, `docs/reviews/override-log.md:311`

---

## Claim 26a: "644/648 not moved (store_check stays build-loop.sh's; the snippet's reader is narrower, SHA-1 only and needs no second-copy rule since it uses only bytes it hashed"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where store_check lives and what the reader omits. It does not establish the cross-reference (26b).
**Legibility-target:** for-orchestrator-synthesis

store_check is still defined only in build-loop.sh (`scripts/build-loop.sh:954`). The reader has no store listing and accepts only bytes that pass `sha1_hex` (`test/lib/d6-snippet.bash:62`).

**Evidence:** `scripts/build-loop.sh:927-954`, `test/lib/d6-snippet.bash:58-71`

---

## Claim 26b: "each comment names the other"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both files' comments at 5583a2cd. It does not establish any behaviour.
**Legibility-target:** for-author

store_check's comment names the snippet: "(The D6 snippet, test/lib/d6-snippet.bash, runs a narrower reader before this script ...)" (`scripts/build-loop.sh:928-929`). The snippet never names store_check: `grep -n -i 'store' test/lib/d6-snippet.bash` has no hit, and the branch's history of that file has never added the word (paraphrased — no quote available because the claim is an absence; grep output and `git log -p` over the file). Fix: add the reverse pointer to the snippet's header, or drop "each comment names the other" from the plan (and note it against c9648432's B10).

**Evidence:** `scripts/build-loop.sh:927-930`, `test/lib/d6-snippet.bash:1-35`, `test/lib/d6-snippet.bash:55-57`

---

## Claim 27: "(the lib's HARDEN list: core.useReplaceRefs, core.hooksPath, core.fsmonitor, core.attributesFile, core.commitGraph, core.multiPackIndex, log.date, log.showSignature; a git -c pair would win over it)"

**Location:** `scripts/build-loop.sh:134-137`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list against HARDEN. Precedence is Claim 6/39.
**Legibility-target:** for-orchestrator-synthesis

The eight keys match `HARDEN=(...)` at `scripts/lib/dev-cycle-read.sh:349` in order.

**Evidence:** `scripts/build-loop.sh:131-138`, `scripts/lib/dev-cycle-read.sh:349`

---

## Claim 28: "Every git call in this process, the lib's included, runs hardened, but for caller_gate's read of the caller's pairs and merge_ident's CALLER_GLOBAL" (with CALLER_GLOBAL captured before git_harden)

**Location:** `scripts/build-loop.sh:490-497`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the calls `--check` makes (T26) and the two named overrides. It does not establish a call log for every other mode.
**Legibility-target:** for-orchestrator-synthesis

`CALLER_GLOBAL=(-u GIT_CONFIG_GLOBAL); [[ -z "${GIT_CONFIG_GLOBAL+set}" ]] || CALLER_GLOBAL=("GIT_CONFIG_GLOBAL=$GIT_CONFIG_GLOBAL")` (`:492`) comes before `git_harden` (`:497`). The two overrides are `GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list ...` (`:564`) and `env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var ...` (`:1321`). No other `GIT_CONFIG_*` or `env -i` override exists (paraphrased — no quote available because the claim is an absence; `grep -n 'GIT_CONFIG_COUNT\|GIT_CONFIG_GLOBAL\|env -i' scripts/build-loop.sh`). T26 (E7) passes: every `--check` call carries the lib's HARDEN pairs, `G=/dev/null P=none S=1`.

**Evidence:** `scripts/build-loop.sh:490-497`, `scripts/build-loop.sh:564`, `scripts/build-loop.sh:1318-1322`, `LOGS/bats-check-filter.log`

---

## Claim 29: "(The D6 snippet, test/lib/d6-snippet.bash, runs a narrower reader before this script: SHA-1 only and no second-copy rule, since it uses only bytes it has hashed itself.)"

**Location:** `scripts/build-loop.sh:928-930`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same reading as Claim 26a. It does not establish the reverse pointer (26b).
**Legibility-target:** for-orchestrator-synthesis

See Claim 26a. The reader runs at `test/lib/d6-snippet.bash:78`, before the script at `:87`.

**Evidence:** `scripts/build-loop.sh:927-930`, `test/lib/d6-snippet.bash:77-87`

---

## Claim 30: The comments renamed harden → git_harden: "which git_harden does not switch off", "which git_harden extends and trusts", "so git_harden's own pairs are not listed", "git applies git -c pairs after git_harden's ... a GIT_CONFIG_COUNT pair comes before git_harden's and loses", "git_harden switches off the multi-pack-index", "Item 2's fsmonitor and replace refs are git_harden's", "which git_harden hides from the gate's own git"

**Location:** `scripts/build-loop.sh:499`
**Type:** Staleness / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the symbol exists and that each sentence still matches git_harden. The precedence parts rest on Claim 39's execution.
**Legibility-target:** for-orchestrator-synthesis

`git_harden` exists (`scripts/lib/dev-cycle-read.sh:351`) and sets `core.multiPackIndex=false`, `core.fsmonitor=false`, `core.useReplaceRefs=false`, `core.attributesFile=/dev/null` (`:349`). caller_gate reads with `GIT_CONFIG_COUNT="$CALLER_COUNT"`, so git_harden's pairs are not listed (`scripts/build-loop.sh:564`). A caller's count pairs take indices 0..N-1, before HARDEN's (`scripts/lib/dev-cycle-read.sh:352-358`). The other sites are `:536`, `:554-556`, `:943`, `:1105` and `:1114`.

**Evidence:** `scripts/build-loop.sh:499`, `scripts/build-loop.sh:536`, `scripts/build-loop.sh:546-557`, `scripts/build-loop.sh:943`, `scripts/build-loop.sh:1105`, `scripts/build-loop.sh:1114`

---

## Claim 31: "Its git reads are hardened (the lib's git_harden): they read no user or system git config (a repository owned by another user that needs a global safe.directory reads as "Not inside a git repository") and no transport (a partial clone's missing object fails)."

**Location:** `scripts/dev-cycle.sh:83-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the safe.directory case, simulated with `GIT_TEST_ASSUME_DIFFERENT_OWNER=1` rather than a real second uid. The partial-clone part rests on `GIT_ALLOW_PROTOCOL=none` and was not run through dev-cycle.sh.
**Legibility-target:** for-orchestrator-synthesis

E2 P6: the branch's dev-cycle.sh gave exit 1, `Not inside a git repository`. Main's gave exit 0, and plain git gave exit 0. Main's reads the global safe.directory, which shows the effect is the branch's.

**Evidence:** `scripts/dev-cycle.sh:83-86`, `scripts/dev-cycle.sh:131-132`, `LOGS/probe1.log`

---

## Claim 32: "Exit: ... 1 bad usage, a GIT_CONFIG_COUNT that is not plain decimal, not a git repo, ..."

**Location:** `scripts/dev-cycle.sh:87-90`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 010 and 1x through the re-exec. It does not establish other exit lines (unchanged).
**Legibility-target:** for-orchestrator-synthesis

E2 P5: both counts gave exit 1, empty stdout and `dev-cycle.sh: GIT_CONFIG_COUNT is not a plain decimal count`. The message comes from `echo "${0##*/}: GIT_CONFIG_COUNT is not a plain decimal count" >&2; exit 1` (`scripts/lib/dev-cycle-read.sh:354`).

**Evidence:** `scripts/dev-cycle.sh:87-90`, `scripts/lib/dev-cycle-read.sh:354`, `LOGS/probe1.log`

---

## Claim 33: "Every git call from here on, the lib's and questions.sh's included, runs hardened, as build-loop.sh's do (the lib's git_harden: no hook, fsmonitor, replace ref, user or system config, or transport)"

**Location:** `scripts/dev-cycle.sh:127-131`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's and `--check-brief`'s logged calls, questions.sh's two among them. It does not establish calls in modes not run.
**Legibility-target:** for-orchestrator-synthesis

E2 P7: 10 digest calls, 2 of them from `questions.sh open`, and 0 lacking `log.showSignature=false`. The questions.sh lines show all eight pairs and `G=/dev/null P=none S=1`. Test 20 (E1) checks every call of `--check-brief` and the digest against the lib's HARDEN. Mutant M6 (call removed) turns it red (E3).

**Evidence:** `scripts/dev-cycle.sh:127-132`, `scripts/dev-cycle.sh:389-421`, `LOGS/probe1.log`, `LOGS/mutants.log`

---

## Claim 34: "File names are literal, not pathspecs." (now via git_harden's export; the old `export GIT_LITERAL_PATHSPECS=1` removed)

**Location:** `scripts/dev-cycle.sh:130`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every call after line 131, which now gets `GIT_LITERAL_PATHSPECS=1` earlier than before (the old export followed the `cd`). It does not cover the three deliberate pattern calls `GIT_LITERAL_PATHSPECS=0 git ls-files` (`scripts/dev-cycle.sh:149`, `:153`, `scripts/lib/dev-cycle-read.sh:1601`), which predate this diff.
**Legibility-target:** for-orchestrator-synthesis

`export GIT_CONFIG_COUNT="$c" GIT_LITERAL_PATHSPECS=1 ...` (`scripts/lib/dev-cycle-read.sh:360`) runs at `scripts/dev-cycle.sh:131`, before `ROOT=` (`:132`).

**Evidence:** `scripts/dev-cycle.sh:127-136`, `scripts/lib/dev-cycle-read.sh:360`

---

## Claim 35: "git_harden and the state gate own item 2's fsmonitor and replace refs"

**Location:** `scripts/lib/dev-cycle-read.sh:70`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rename (the meaning is unchanged). It does not cover dev-cycle.sh, which runs no state gate.
**Legibility-target:** for-orchestrator-synthesis

HARDEN sets `core.fsmonitor=false core.useReplaceRefs=false` (`:349`). The state gate refuses replace refs (`scripts/build-loop.sh:508`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:70`, `scripts/lib/dev-cycle-read.sh:349`, `scripts/build-loop.sh:508`

---

## Claim 36: "git_harden: every later git call in this process and its children runs hardened, but where a caller hands back its own setting on purpose (build-loop.sh's caller_gate reads the caller's count, merge_ident its global config); build-loop.sh and dev-cycle.sh call it once, after scrub_reexec and before their first git call"

**Location:** `scripts/lib/dev-cycle-read.sh:326-330`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same evidence as Claims 8, 28 and 33; children were shown through questions.sh. It does not establish children that reset their own environment (none found).
**Legibility-target:** for-orchestrator-synthesis

Exactly one call per script: `scripts/build-loop.sh:497` and `scripts/dev-cycle.sh:131` (paraphrased — no quote available because the claim is call-site counting; `grep -n '^git_harden'` over both). E2 P7 shows a child's (questions.sh's) calls carrying the pairs.

**Evidence:** `scripts/lib/dev-cycle-read.sh:326-330`, `scripts/build-loop.sh:497`, `scripts/dev-cycle.sh:131`, `LOGS/probe1.log`

---

## Claim 37: Per-pair reasons: "(core.useReplaceRefs there would override GIT_NO_REPLACE_OBJECTS), no hook, no fsmonitor command, no core.attributesFile, no multi-pack-index (a second route to an object, past build-loop.sh's store_check), no commit-graph (a forged one changes merge bases), git log's own date format and no signature check (a bad log.date stops git log; log.showSignature runs gpg.program)."

**Location:** `scripts/lib/dev-cycle-read.sh:333-338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Executed: the replace-refs override, log.date and log.showSignature. The multi-pack-index and commit-graph reasons are read, not run (carried from build-loop.sh's earlier text).
**Legibility-target:** for-orchestrator-synthesis

E2 P1: with repo `core.useReplaceRefs=true` and `GIT_NO_REPLACE_OBJECTS=1`, `cat-file -p` printed `replaced`. With `-c core.useReplaceRefs=false` it printed the real `a`. E2 P2: `log.date=bogus` gave exit 128, "fatal: unknown date format bogus". `log.showSignature=true` with a gpg.program shim gave "gpg ran".

**Evidence:** `scripts/lib/dev-cycle-read.sh:333-338`, `scripts/lib/dev-cycle-read.sh:349`, `LOGS/probe1.log`

---

## Claim 38: "GIT_CONFIG_GLOBAL=/dev/null and GIT_CONFIG_NOSYSTEM: a loop can write the user's ~/.gitconfig as easily as .git/config. GIT_ALLOW_PROTOCOL=none: no transport, so a lazy fetch (a partial clone's missing object) fails however its config was planted."

**Location:** `scripts/lib/dev-cycle-read.sh:339-341`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the exported values. It does not execute a lazy fetch under git_harden alone (the partial-clone test in build-loop-check.bats exercises the state gate's refusal first).
**Legibility-target:** for-orchestrator-synthesis

`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none` (`:360`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:339-341`, `scripts/lib/dev-cycle-read.sh:360`

---

## Claim 39: "The caller's own pairs (git -c, GIT_CONFIG_COUNT) still apply, git -c ones after HARDEN's: CALLER_COUNT keeps the caller's count for build-loop.sh's caller_gate, which refuses a HARDEN key there by name."

**Location:** `scripts/lib/dev-cycle-read.sh:342-345`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers precedence on git 2.39.5 and caller_gate's use of CALLER_COUNT.
**Legibility-target:** for-orchestrator-synthesis

E2 P3: a count pair `log.date=default` with `-c log.date=bogus` fails (`-c` wins), and a count pair outranks a repo-config `log.date=bogus`. caller_gate: `x="$(GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list --show-scope --name-only)"` (`scripts/build-loop.sh:564`). The by-name refusal is executed in E6.

**Evidence:** `scripts/lib/dev-cycle-read.sh:342-345`, `scripts/lib/dev-cycle-read.sh:352-358`, `scripts/build-loop.sh:564-571`, `LOGS/probe1.log`, `LOGS/probe3.log`

---

## Claim 40: "A GIT_CONFIG_COUNT that is not plain decimal (010 reads as 8 here and as 10 to git) exits 1."

**Location:** `scripts/lib/dev-cycle-read.sh:345-346`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both scripts' exit. "Reads as 10 to git" is read from git's documented decimal parse, not run.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$c" =~ ^(0|[123456789][0123456789]*)$ ]] || { echo ...; exit 1; }` (`:354`). Orchestrator test 2 loops `010 08 1x " 1"` (E1). E2 P5 covers dev-cycle.sh.

**Evidence:** `scripts/lib/dev-cycle-read.sh:354`, `test/scripts/build-loop-orchestrator.bats:50-54`, `LOGS/probe1.log`

---

## Claim 41: "What these cannot switch off, build-loop.sh's state gate refuses in its gated modes; dev-cycle.sh runs no state gate (row 548)."

**Location:** `scripts/lib/dev-cycle-read.sh:346-347`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which scripts call state_gate. It does not establish the state gate's completeness.
**Legibility-target:** for-orchestrator-synthesis

state_gate is defined in build-loop.sh (`scripts/build-loop.sh:499-533`), and `GATED` excludes settings, status and marker (`:608`). dev-cycle.sh has no state_gate (paraphrased — no quote available because the claim is an absence; `grep -n state_gate scripts/dev-cycle.sh` has no hit).

**Evidence:** `scripts/build-loop.sh:499-533`, `scripts/build-loop.sh:608`, `docs/reviews/override-log.md:548`

---

## Claim 42: "A second call returns at once: it would count HARDEN's pairs as the caller's."

**Location:** `scripts/lib/dev-cycle-read.sh:347-348`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a second call in the same process. It does not cover a child process that re-sources the lib with the pairs already exported (it would count them as the caller's; no such child exists today).
**Legibility-target:** for-orchestrator-synthesis

`[[ -z "$CALLER_COUNT" ]] || return 0` (`:352`). Test 19 calls `git_harden; git_harden` and pins `caller 1` and `GIT_CONFIG_COUNT=9` (E1). M5 turns it red (E3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:350-361`, `test/scripts/build-loop-orchestrator.bats:347-356`, `LOGS/mutants.log`

---

## Claim 43: "the one way the orchestrator runs build-loop.sh ... and dev-cycle.sh ... as the body of a quoted heredoc that bash reads, so it runs the same from any login shell and defines nothing in the caller's"

**Location:** `test/lib/d6-snippet.bash:2-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the heredoc form from a bash caller. A zsh or other login shell was not run, and U4's SKILL.md does not exist yet.
**Legibility-target:** for-orchestrator-synthesis

E6 ran it through `bash -s -- ... <<'D6'`. The quoted delimiter stops the caller's shell from expanding anything inside, and `d6` is defined only in the child bash (`:36`).

**Evidence:** `test/lib/d6-snippet.bash:2-9`, `test/lib/d6-snippet.bash:36`, `LOGS/probe3.log`

---

## Claim 44: "T33 is to assert the two match once U4 writes the block (pending until then)."

**Location:** `test/lib/d6-snippet.bash:10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pending state.
**Legibility-target:** for-orchestrator-synthesis

T33 holds only `# The SKILL.md block and test/lib/d6-snippet.bash are byte-equal (T33): pending until U4 writes the block.` (`test/scripts/build-loop-orchestrator.bats:268`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:268`

---

## Claim 45: "In claude-workflows (main's first-parent root commit is D6_ROOT) it runs main's own scripts: one perl process reads every object it uses through one cat-file --batch ... it writes the four files from those bytes into a fresh temp dir (a same-uid writer racing that 0700 dir is the Q-103 class, row 509)."

**Location:** `test/lib/d6-snippet.bash:11-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real repository: D6_ROOT is main's first-parent root, and the reader writes main's exact blobs. It does not cover the race (row 509).
**Legibility-target:** for-orchestrator-synthesis

`git rev-list --first-parent --max-parents=0 main` gives `640cf00735754d4253819a0354fb8ca9b71a8ea7`, which equals `D6_ROOT` (`:38`). In E9 the reader printed `main`, and all four files match main's blob ids. E8 ran the whole snippet in the real repository with exit 0.

**Evidence:** `test/lib/d6-snippet.bash:38`, `test/lib/d6-snippet.bash:58-81`, `LOGS/real-repo-reader.log`, `LOGS/real-repo-d6.log`

---

## Claim 46: "In any other repository (another root, or not SHA-1) it runs the image copy under D6_OPT, by absolute path, once those files and every directory above them are root-owned, no symlink and not writable here."

**Location:** `test/lib/d6-snippet.bash:19-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 17.
**Legibility-target:** for-orchestrator-synthesis

See Claim 17. Test 17 asserts the output equals `bash /opt/claude-workflows/scripts/build-loop.sh --help` (`test/scripts/build-loop-orchestrator.bats:334`).

**Evidence:** `test/lib/d6-snippet.bash:82-87`, `test/scripts/build-loop-orchestrator.bats:330-344`, `LOGS/bats-orch.log`

---

## Claim 47: "It never reads the working tree, ~/.claude/scripts or a replaced object"

**Location:** `test/lib/d6-snippet.bash:22-23`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the snippet's own reads: every git call is a ref, path or object read, with replace objects off. It does not cover git's repository discovery (which reads the checkout's `.git` entry) or the scripts it runs, which read the working tree by design.
**Legibility-target:** for-orchestrator-synthesis

The git calls are `for-each-ref`, `rev-parse --git-path`, `show-ref`, `symbolic-ref`, `rev-parse --verify`, `cat-file -t`, `rev-parse --show-object-format` and `cat-file --batch` (`:47-54`, `:59`, `:75`). G carries `GIT_NO_REPLACE_OBJECTS=1` and `-c core.useReplaceRefs=false` (`:40`). questions.sh is extracted beside dev-cycle.sh, so dev-cycle.sh's `[[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"` never falls back (`scripts/dev-cycle.sh:389-390`). In the /opt path, `own` requires questions.sh to exist (`test/lib/d6-snippet.bash:84`). Test 11 replaces the working tree's four scripts with `exit 9`, and the runs pass (E1).

**Evidence:** `test/lib/d6-snippet.bash:40-59`, `test/lib/d6-snippet.bash:75-87`, `scripts/dev-cycle.sh:389-390`, `test/scripts/build-loop-orchestrator.bats:252`

---

## Claim 48: "Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout, with nothing run, for a replace ref, info/grafts, a default branch that is not exactly one plain main or master or whose ref names no commit itself, a first-parent history, tree or file that cannot be read whole or does not hash to its id (a shallow history among them), a script on main that is not a regular file, an image copy that fails the ownership checks, or a git read or temp-dir step that fails ...; 1 for another first argument."

**Location:** `test/lib/d6-snippet.bash:26-33`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Executed: replace refs, grafts, main/master, symbolic, tag, rewritten tree, rewritten commit, missing commit, shallow clone, uid-owned image copy and a bad first argument. Read, not run: "not a regular file" (perl's mode check `qr/\A100(644|755)\z/` dies on 120000/160000) and temp-dir failures.
**Legibility-target:** for-orchestrator-synthesis

Every refusal goes through `no` (`:39`) before `bash "$d/scripts/$s"` (`:87`). Tests 12-15 and 18 pass (E1). `exit "$?"` (`:88`) returns the script's own status.

**Evidence:** `test/lib/d6-snippet.bash:39-88`, `test/scripts/build-loop-orchestrator.bats:271-344`, `LOGS/bats-orch.log`

---

## Claim 49: "Its git carries the lib's HARDEN pairs and git_harden's environment (G; a test pins the two lists equal)."

**Location:** `test/lib/d6-snippet.bash:33-34`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 21.
**Legibility-target:** for-orchestrator-synthesis

See Claim 21: test 19's `grep -o -- '-c [^ )]*'` and `grep -o 'GIT_[A-Z_]*=[^ ]*'` over the `G=(env ` line (`test/scripts/build-loop-orchestrator.bats:358-360`).

**Evidence:** `test/lib/d6-snippet.bash:40`, `test/scripts/build-loop-orchestrator.bats:357-360`, `LOGS/mutants.log`

---

## Claim 50: "These checks come before, not instead of, the script's own state and default-branch gates."

**Location:** `test/lib/d6-snippet.bash:34-35`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which runs have such gates. It does not establish the row-548 ruling.
**Legibility-target:** for-author

This is true for build-loop.sh's gated modes. dev-cycle.sh has no state or default-branch gate, and build-loop.sh's `--settings`, `--status` and `--marker` are ungated: `GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1` (`scripts/build-loop.sh:608`). For those runs the snippet's checks are the only ones. A precise version: "before, not instead of, build-loop.sh's state and default-branch gates in its gated modes (dev-cycle.sh has none: row 548)". Re-flag of settled row 548.

**Evidence:** `test/lib/d6-snippet.bash:34-35`, `scripts/build-loop.sh:608`, `scripts/lib/dev-cycle-read.sh:565-587`

---

## Claim 51: "t stays global: the EXIT trap reads it"

**Location:** `test/lib/d6-snippet.bash:43`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `t` is not in the `local` list and is the trap's variable.
**Legibility-target:** for-orchestrator-synthesis

`local s="${1:-}" F x m n sha f d P` has no `t` (`:43`). The trap is `trap 'rm -rf "$t"' EXIT` (`:73`).

**Evidence:** `test/lib/d6-snippet.bash:43`, `test/lib/d6-snippet.bash:72-73`

---

## Claim 52: "It prints "main" once the four files are written, "other" when the first-parent root is not D6_ROOT; any failure dies (status 255)."

**Location:** `test/lib/d6-snippet.bash:55-57`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reader's outputs and exit statuses. The bash side treats any non-zero exit as a refusal (`:78`), so behaviour is unaffected.
**Legibility-target:** for-author

E4 E: a missing tip and a tree given as the tip exited 255. An unwritable out dir (`open ... or die "$f: $!\n"`, `:70`) exited **2**: perl's `die` exits with `$!` when it is non-zero. Another root printed `[other]` with exit 0, and main printed `main` (E9). A precise version: "any failure dies (non-zero: 255, or the errno of a failed open)".

**Evidence:** `test/lib/d6-snippet.bash:55-57`, `test/lib/d6-snippet.bash:60-71`, `test/lib/d6-snippet.bash:78`, `LOGS/probe2.log`

---

## Claim 53: "Under bash -s the script is the heredoc on stdin: bash has read this whole line before it runs, and no child reads the rest of it."

**Location:** `test/lib/d6-snippet.bash:90-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heredoc form from bash.
**Legibility-target:** for-orchestrator-synthesis

E6: the script run through the heredoc reported stdin `/dev/null`, and the caller's next line ran ("after the heredoc: exit 0").

**Evidence:** `test/lib/d6-snippet.bash:90-92`, `LOGS/probe3.log`

---

## Claim 54: "Not log.date: git_harden's log.date pair overrides it (row 505); a bad boolean still stops git log."

**Location:** `test/scripts/build-loop-check.bats:1660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count pair outranking repo config and the abbrevCommit test.
**Legibility-target:** for-orchestrator-synthesis

E2 P3: "repo bogus, count default: ok (count outranks repo)". E7: the row-307 test passes with `git config log.abbrevCommit bogus`, giving the skip line for `--status` and `--check-branch`.

**Evidence:** `test/scripts/build-loop-check.bats:1658-1665`, `LOGS/probe1.log`, `LOGS/bats-check-filter.log`

---

## Claim 55: Test name "every git call --check makes carries git_harden's config pairs (core.hooksPath=/dev/null among them), no global or system config and no transport (T26, ...)"

**Location:** `test/scripts/build-loop-check.bats:1688`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts.
**Legibility-target:** for-orchestrator-synthesis

The test asserts that no logged call lacks each HARDEN pair, `G=/dev/null`, `P=none` or `S=1` (`:1700-1702`). It passes (E7).

**Evidence:** `test/scripts/build-loop-check.bats:1688-1703`, `LOGS/bats-check-filter.log`

---

## Claim 56: "HARDEN from the lib itself, so a key added there is checked here too."

**Location:** `test/scripts/build-loop-check.bats:1699`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop source.
**Legibility-target:** for-orchestrator-synthesis

`for kv in $(bash -c 'source "$1"; echo "${HARDEN[*]}"' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh") G=/dev/null P=none S=1; do` (`:1700`). It passes (E7).

**Evidence:** `test/scripts/build-loop-check.bats:1699-1702`

---

## Claim 57: "A plain caller pair passes; a count git_harden would misread stops every mode (row 276)."

**Location:** `test/scripts/build-loop-orchestrator.bats:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test 2's assertions.
**Legibility-target:** for-orchestrator-synthesis

Test 2 passes (E1). The count loop is `for c in 010 08 1x " 1"` (`:52`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:50-56`, `LOGS/bats-orch.log`

---

## Claim 58: "d6_copy ROOT OPT: D6, a copy of test/lib/d6-snippet.bash with D6_ROOT and D6_OPT replaced. d6_setup: main holds this branch's four scripts, and D6 takes this fixture's root commit as claude-workflows' own."

**Location:** `test/scripts/build-loop-orchestrator.bats:227-229`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helpers.
**Legibility-target:** for-orchestrator-synthesis

`sed "s|^  D6_ROOT=.*; D6_OPT=.*|  D6_ROOT=$1; D6_OPT=$2|" ... ; grep -qxF ...` (`:230`). d6_setup copies the four scripts and calls `d6_copy "$(git rev-list --max-parents=0 main)" /opt/claude-workflows` (`:231-234`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:227-234`

---

## Claim 59: T33 name "runs main's four scripts from a fresh temp dir, each with its own lib and questions.sh, never the working tree's, and removes the dir", plus its comments "The snippet exports no config pair, so --state run through it passes caller_gate (row 702)" and "A byte the reader did not hash is never used: a git whose cat-file --batch alters one word of the blobs it prints."

**Location:** `test/scripts/build-loop-orchestrator.bats:245`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions. dev-cycle.sh's own lib is shown indirectly: the working-tree lib is `exit 9`, and the run exits 0.
**Legibility-target:** for-orchestrator-synthesis

The test asserts the lib path is under `$TMPDIR/*/scripts/lib/`, main's questions.sh's `Q-001 ... from-main` line, `--state` giving `ok`, an empty `$TMPDIR`, and the tamper refusal (`:245-267`). The tamper shim is `sed -u s/pipefail/PIPEFAIL/` over the `--batch` output, the first match per line. It passes (E1). M1 turns it red (E3).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:245-269`, `LOGS/bats-orch.log`, `LOGS/mutants.log`

---

## Claim 60: Test name "refuses before running anything: a blob or commit replace ref, info/grafts, not exactly one plain main or master (T36, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:271`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted cases (the symbolic and tag cases included).
**Legibility-target:** for-orchestrator-synthesis

`d6_is` asserts exit 2, the exact line and empty stderr for each (`:272-283`). It passes (E1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:271-284`, `LOGS/bats-orch.log`

---

## Claim 61: Test name "refuses the scripts/ tree rewritten in place, and runs no planted bytes (T36, U3b3 i1 A1, i2 B1)"

**Location:** `test/scripts/build-loop-orchestrator.bats:290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loose in-place rewrite.
**Legibility-target:** for-orchestrator-synthesis

It asserts ls-tree now sees the planted id, then that the snippet gives `A1`, exit 2 (`:291-298`). It passes (E1). M1 turns it red (E3).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:290-298`, `LOGS/mutants.log`

---

## Claim 62a: Test name "refuses a first-parent commit rewritten in place to end main's history at D6_ROOT (T36, U3b3 i1 A1)" and "the one stdout line is the snippet's"

**Location:** `test/scripts/build-loop-orchestrator.bats:300`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions.
**Legibility-target:** for-orchestrator-synthesis

It asserts git's rev-list root is now the fake root, then `A1` and exit 2 (`:301-307`). It passes (E1). M1 turns it red (E3).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:300-308`, `LOGS/mutants.log`

---

## Claim 62b: "git names the mismatch on stderr too"

**Location:** `test/scripts/build-loop-orchestrator.bats:306`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stderr of test 14's scenario at 5583a2cd. It does not affect the test, which asserts nothing on stderr.
**Legibility-target:** for-author

E11 reproduced the test. Stderr is the perl reader's `die` line, `5fc8badb... does not hash to its id`, not git's. `cat-file --batch` printed nothing for the rewritten loose object (also seen in a direct check). The comment came in d9515d09, whose `g rev-parse "$sha^{tree}" ...` pipeline was a git parse that checks hashes. c9648432 removed that call. Now: "the reader names the mismatch on stderr".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:306`, `test/lib/d6-snippet.bash:62`, `LOGS/probe4.log`

---

## Claim 63: Test name "refuses, never falls to the image copy, when main's first-parent history cannot be read whole: a missing commit, a shallow clone (T36, U3b3 i2 B2)"

**Location:** `test/scripts/build-loop-orchestrator.bats:310`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both cases.
**Legibility-target:** for-orchestrator-synthesis

It passes (E1). M4 turns it red (E3).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:310-315`, `LOGS/mutants.log`

---

## Claim 64: T27 name "a gate copy patched in the loop's worktree prints ok for its tip; the D6 snippet's copy from main refuses the same tip"

**Location:** `test/scripts/build-loop-orchestrator.bats:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions.
**Legibility-target:** for-orchestrator-synthesis

It asserts `ok $B` from the patched copy and `refuse $B: 1 of 2 changed paths refused ...` plus the deny line through the snippet (`:318-328`). It passes (E1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:317-328`, `LOGS/bats-orch.log`

---

## Claim 65: T37 name "outside claude-workflows the D6 snippet runs the image copy by absolute path, not main's copy"

**Location:** `test/scripts/build-loop-orchestrator.bats:330`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real /opt copy on this host (the test did not skip).
**Legibility-target:** for-orchestrator-synthesis

It passes, not skipped (E1). `/opt/claude-workflows` and its scripts are root-owned and `r-x` here.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:330-336`, `LOGS/bats-orch.log`

---

## Claim 66: T37 name "outside claude-workflows the D6 snippet refuses an image copy the uid owns, and never runs main's"

**Location:** `test/scripts/build-loop-orchestrator.bats:338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertion. "Never runs main's" is shown by the exact single-line stdout: main's copy would print `main copy`.
**Legibility-target:** for-orchestrator-synthesis

It passes (E1). M2 turns it red (E3).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:338-344`, `LOGS/mutants.log`

---

## Claim 67: Test name "git_harden exports HARDEN's pairs after the caller's and a fixed environment, once however often it is called; the D6 snippet's git carries the same" and "The snippet cannot source the lib (it runs before anything is checked)"

**Location:** `test/scripts/build-loop-orchestrator.bats:346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions.
**Legibility-target:** for-orchestrator-synthesis

It passes (E1). M3 and M5 turn it red (E3).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:346-361`, `LOGS/mutants.log`

---

## Claim 68: Test name "every git call dev-cycle.sh makes carries git_harden's pairs: a bogus log.date stops nothing, log.showSignature runs no gpg.program"

**Location:** `test/scripts/build-loop-orchestrator.bats:363`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-brief` and the digest.
**Legibility-target:** for-orchestrator-synthesis

It passes (E1). M3 and M6 turn it red (E3).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:363-380`, `LOGS/mutants.log`

---

## Claim 69: 9925f2a7: "Moves build-loop.sh's harden, HARDEN and its environment exports into the lib as git_harden ... dev-cycle.sh now calls it before its first git call ... HARDEN gains log.date=default (row 505 ...) and log.showSignature=false (git log would run gpg.program). Notes: ... a host repo that needs a global safe.directory would stop."

**Location:** `9925f2a7` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behaviour as of 5583a2cd. Later commits did not change these lines' meaning.
**Legibility-target:** for-orchestrator-synthesis

See Claims 8, 9 and 31.

**Evidence:** `scripts/lib/dev-cycle-read.sh:349-361`, `scripts/dev-cycle.sh:131`, `LOGS/probe1.log`

---

## Claim 70: a0014ce5: "In claude-workflows (main's first-parent root is 640cf007) it extracts main's four scripts into a fresh temp dir, hash-checks each against main's tree, runs that copy and removes the dir"

**Location:** `a0014ce5` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the root id and a0014ce5's design as committed. The ids-from-ls-tree weakness is i1's A1, since superseded.
**Legibility-target:** for-orchestrator-synthesis

The root is 640cf007 (Claim 45). At a0014ce5: `[[ "$(g hash-object --no-filters "$d/scripts/${F[i]}")" == "${ids[i]}" ]] || no ...` (`git show a0014ce5:test/lib/d6-snippet.bash`, the extraction loop).

**Evidence:** `test/lib/d6-snippet.bash:38`, `LOGS/real-repo-reader.log`

---

## Claim 71: a0014ce5: "It is a bash script body, not a function"

**Location:** `a0014ce5` (commit message)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file's shape. The message is immutable, and the rubric already notes this (i1 A5).
**Legibility-target:** for-orchestrator-synthesis

The file defines and calls a function: `d6() {` ... `d6 "$@" </dev/null` (`test/lib/d6-snippet.bash:36`, `:92`). What holds is that no function lands in the caller's shell.

**Evidence:** `test/lib/d6-snippet.bash:36`, `test/lib/d6-snippet.bash:92`

---

## Claim 72: a0014ce5: "Tests: T27 ..., T33 (own lib and questions.sh, working tree ignored, temp dir removed, a tampered extraction refused, --state passes; the SKILL.md byte-equality half waits for U4), T36, T37 (the real /opt half skips without a root-owned image copy) ... The row-307 test now breaks git log with log.abbrevCommit"

**Location:** `a0014ce5` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a0014ce5's test file and its passing baseline.
**Legibility-target:** for-orchestrator-synthesis

At a0014ce5, T33 has the `--state` line (`git show a0014ce5:test/scripts/build-loop-orchestrator.bats:257-258`) and the `cat-file blob` tamper shim (`:263-264`). The a0014ce5 suite passes 17/17 (E5). T37's skip guard is `skip "no root-owned image copy at $O here"` (`test/scripts/build-loop-orchestrator.bats:332`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:332`, `LOGS/baseline-a00.log`

---

## Claim 73: a0014ce5: "dev-cycle.sh's calls hardened (rows 495, 505: a planted log.showSignature ran gpg.program on main)"

**Location:** `a0014ce5` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's digest at 27cedb99 on git 2.39.5.
**Legibility-target:** for-orchestrator-synthesis

E2 P4: main's dev-cycle.sh digest with `log.showSignature=true` and a gpg.program shim gave "gpg ran". The branch's gave "gpg did not run".

**Evidence:** `LOGS/probe1.log`

---

## Claim 74: a0014ce5: "Mutants checked: hash check removed, ownership check removed, log.showSignature pair removed, main's dev-cycle.sh: each turns a test red."

**Location:** `a0014ce5` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four mutants on an a0014ce5 archive. "main's dev-cycle.sh" was read as dev-cycle.sh without its git_harden call (main's hardening state).
**Legibility-target:** for-orchestrator-synthesis

E5: hash check → test 11 red. Ownership → test 15 red. showSignature pair → tests 16 and 17 red. Unhardened dev-cycle.sh → test 17 red. Baseline 17/17 green.

**Evidence:** `LOGS/mutants-a00.log`, `LOGS/baseline-a00.log`

---

## Claim 75: d9515d09: "Two tests: a rewritten scripts tree, and a tip rewritten to forge the root. A2: the default branch's ref must name a commit itself, not a peeled tag."

**Location:** `d9515d09` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tests and the ref check, which are still present.
**Legibility-target:** for-orchestrator-synthesis

The two tests are 13 and 14 (`test/scripts/build-loop-orchestrator.bats:290`, `:300`). The ref check is `[[ "$(g cat-file -t "$sha")" == commit ]]` (`test/lib/d6-snippet.bash:54`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:290-308`, `test/lib/d6-snippet.bash:54`

---

## Claim 76: d9515d09: "Notes: about 0.1 s over this repository's ~1,100 first-parent commits."

**Location:** `d9515d09` (commit message)
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the commit count (1,122 now). It does not establish d9515d09's re-hash timing, which was not run.
**Legibility-target:** for-orchestrator-synthesis

`git rev-list --first-parent --count main` gives 1122. The current reader takes 61-63 ms (E10), which is consistent but measures a different program.

**Evidence:** `LOGS/timing.log`

---

## Claim 77: c9648432: "d9515d09 re-hashed main's commits and trees through one cat-file --batch, but rev-list, rev-parse and ls-tree still chose the ids and blobs"

**Location:** `c9648432` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers d9515d09's file.
**Legibility-target:** for-orchestrator-synthesis

d9515d09's snippet: `{ g rev-list --first-parent "$sha" && g rev-parse "$sha^{tree}" "$sha:scripts" "$sha:scripts/lib"; } | g cat-file --batch` (line 53). `x="$(g ls-tree --format=... "$sha" -- "scripts/$f")"` (line 61). `g cat-file blob "${BASH_REMATCH[2]}"` (line 64).

**Evidence:** `test/lib/d6-snippet.bash:1-92` (current), d9515d09 `test/lib/d6-snippet.bash:48-64`

---

## Claim 78: c9648432: "one perl process drives one cat-file --batch, uses an object only once its bytes SHA-1 to its id, and takes every next id from bytes it checked ... The two-pack probe now runs main's real scripts."

**Location:** `c9648432` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Same as Claims 14 and 15 (a reconstructed probe).
**Legibility-target:** for-orchestrator-synthesis

See Claims 14 and 15.

**Evidence:** `test/lib/d6-snippet.bash:58-71`, `LOGS/probe2.log`

---

## Claim 79: c9648432: "B2: any read failure refuses instead of falling to the image copy (a missing commit, a shallow clone); a repository that is not SHA-1 takes the image copy. B11: one history walk instead of two."

**Location:** `c9648432` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 16, 2 and 3. The non-SHA-1 branch was read, not run.
**Legibility-target:** for-orchestrator-synthesis

See Claims 16 and 2. The one walk is `test/lib/d6-snippet.bash:65-66`.

**Evidence:** `test/lib/d6-snippet.bash:65-79`, `LOGS/mutants.log`

---

## Claim 80: c9648432: "B4: --state's header names HARDEN's eight keys. ... B8: git_harden returns on a second call. B9: both call-log tests loop over the lib's HARDEN."

**Location:** `c9648432` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers B4, B8 and B9. The B5-B7, B12 and B13 text edits are covered by the claims above.
**Legibility-target:** for-orchestrator-synthesis

B4 is Claim 27. B8 is Claim 42. B9: `test/scripts/build-loop-check.bats:1700` and `test/scripts/build-loop-orchestrator.bats:377` both use `$(bash -c 'source "$1"; echo "${HARDEN[*]}"' ...)`.

**Evidence:** `scripts/build-loop.sh:134-137`, `scripts/lib/dev-cycle-read.sh:352`, `test/scripts/build-loop-check.bats:1700`, `test/scripts/build-loop-orchestrator.bats:377`

---

## Claim 81: c9648432: "B10: store_check and the snippet's reader name each other."

**Location:** `c9648432` (commit message)
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Same reading as Claim 26b. The message is immutable, so the fix belongs in the snippet's header.
**Legibility-target:** for-author

Only store_check's comment names the snippet (`scripts/build-loop.sh:928-929`). c9648432's diff to `test/lib/d6-snippet.bash` adds no store_check reference (paraphrased — no quote available because the claim is an absence; `git log -p main..5583a2cd -- test/lib/d6-snippet.bash | grep -i store_check` has only the commit-message hit).

**Evidence:** `scripts/build-loop.sh:927-930`, `test/lib/d6-snippet.bash:1-92`

---

## Claim 82: c9648432: "Mutants: no refusal on a failed read (B2 test red); git_harden called twice (environment test pins one count)."

**Location:** `c9648432` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two mutants on 5583a2cd, which has the same code as c9648432.
**Legibility-target:** for-orchestrator-synthesis

E3: M4 turns test 15 red (and 11, 13, 14). M5 turns test 19 red.

**Evidence:** `LOGS/mutants.log`

---

## Claim 83: c9648432: "Suites: 285/285."

**Location:** `c9648432` (commit message)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers suite counts only. The suites are not named, and only the orchestrator suite (20/20) and four build-loop-check tests were run here.
**Legibility-target:** for-orchestrator-synthesis

`bats --count` over the build-loop-*.bats and dev-cycle.bats suites gives 146+4+12+20+20+79 = 281. Adding fixture-git-env (2) and utility-smoke (2) would make 285, but the message does not say which set it ran (paraphrased — no quote available because these are counts from `bats --count`, not file text).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:1`, `test/scripts/build-loop-check.bats:1`

---

## Claim 84: 5583a2cd: "U3b3 iteration 2: reports, rubric, seven override rows"

**Location:** `5583a2cd` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row count.
**Legibility-target:** for-orchestrator-synthesis

Rows 732-738 are the seven `feat/build-loop-u3b3` rows. `git diff --stat` shows `override-log.md | 7 +`.

**Evidence:** `docs/reviews/override-log.md:732-738`

---

## Claims Requiring Attention

### Incorrect
- **Claim 26b** (`docs/working/plan-build-loop-handoff.md:326`): comment/doc. "each comment names the other": store_check's comment names the snippet, but `test/lib/d6-snippet.bash` never names store_check. Add the pointer to the snippet header, or narrow the plan text.
- **Claim 81** (`c9648432` message): comment/doc. Same mismatch ("B10: store_check and the snippet's reader name each other"). The message is immutable, so fix it through the snippet header.

### Stale
- **Claim 62b** (`test/scripts/build-loop-orchestrator.bats:306`): comment. "git names the mismatch on stderr too": since c9648432 the perl reader's `die` names it, and git prints nothing (E11).

### Mostly Accurate
- **Claim 3** (`docs/reviews/override-log.md:734`): comment/doc. Overhead is ~80 ms here, but ~60 ms of it is the reader's walk, linear in main's first-parent history, not a fixed fork cost.
- **Claim 13b** (`docs/working/plan-build-loop-handoff.md:326`): comment/doc. "origin/HEAD is left to the script's default_gate" / "before, not instead of": true for build-loop.sh's gated modes only. dev-cycle.sh has no such gate (row 548, settled).
- **Claim 50** (`test/lib/d6-snippet.bash:34-35`): comment. Same scope gap as 13b (dev-cycle.sh and build-loop.sh's read modes).
- **Claim 52** (`test/lib/d6-snippet.bash:57`): comment. "any failure dies (status 255)": a failed open exits with its errno (2 observed). Behaviour is unaffected because bash refuses on any non-zero exit.
- **Claim 71** (`a0014ce5` message): comment/doc. "a bash script body, not a function". Already noted (i1 A5), and the message is immutable.

### Unverifiable
- **Claim 12** (plan :326): the zsh `g` alias incident needs the earlier session's transcript.
- **Claim 18** (plan :326): the `-w` result as root needs a uid 0 run.
- **Claim 76** (`d9515d09` message): the ~0.1 s timing of d9515d09's re-hash; the count (1,122) holds.
- **Claim 83** (`c9648432` message): "285/285" needs the suite list it summed.

### Re-flagged settled decisions
- Claims 13b and 50: dev-cycle.sh runs no state or default-branch gate, and its resolve_main follows origin/HEAD (row 548, Q-103 residual).
- Claims 1 and 22: a moved refs/heads/main (row 732, Won't-Fix).
- Claim 24: a racer on the 0700 extraction dir (rows 200 and 509).

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/code-fact-check-report-2026-10-12-u3b3-final-r2.md, structured per the code-fact-check skill.
- Answered: yes. All ten brief focus areas were checked, the perl reader's parsing and protocol included. The orchestrator suite passed 20/20 and the edited build-loop-check tests 4/4. Mutants were run at both 5583a2cd and a0014ce5. Every executable claim was run except two that are blocked (root; a transcript).
- Out of scope: security judgement of the reader's parent parse (perl takes the first `^parent` line anywhere in the header; it only matters for a malformed commit already in main's hashed first-parent history, Claim 14 scope). `docs/reviews/hallucination-patterns.md` was not edited: write-only-this-report rule.
- Escalate: (1) for author, `test/lib/d6-snippet.bash:1-35` / `docs/working/plan-build-loop-handoff.md:326`: B10 is half done. The snippet header never names store_check (Claims 26b, 81). This is a text fix. (2) For author, `test/scripts/build-loop-orchestrator.bats:306`: a stale comment (Claim 62b). Nothing behavioural.
- Decisions I made: I read a0014ce5's "main's dev-cycle.sh" mutant as dev-cycle.sh without its git_harden call; the alternative was running main's file in place. I reconstructed B1's two-pack probe with a hand-edited idx rather than i2's original. I kept probe logs in the session scratchpad, not `docs/reviews/execution-logs/`, under the write-only rule.
