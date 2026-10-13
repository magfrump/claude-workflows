Commit: 5583a2cd

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b3 (branch `feat/build-loop-u3b3`)
**Scope:** branch diff `main...5583a2cd` (final confirming pass, iteration 3 of 3): `docs/working/plan-build-loop-handoff.md` (the U3b3 as-built note), `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `test/lib/d6-snippet.bash`, `test/scripts/build-loop-check.bats`, `test/scripts/build-loop-orchestrator.bats`, the seven new rows of `docs/reviews/override-log.md` (732-738), and the messages of 9925f2a7, a0014ce5, 7a927183, d9515d09, 5d175c0e, c9648432 and 5583a2cd. This report merges three replicate reports (`docs/reviews/code-fact-check-report-2026-10-12-u3b3-final-r1.md`, `-r2.md`, `-r3.md`, all `Commit: 5583a2cd`) under the most-severe-wins rule.
**Checked:** 2026-10-12
**Total claims checked:** 95
**Summary:** 80 verified, 8 mostly accurate, 1 stale, 2 incorrect, 4 unverifiable
**Commit:** 5583a2cd
**Replication:** k=3

Merge notes:
- Each claim has two added fields. **Replicate verdicts** gives each replicate's verdict; `(compound)` means that replicate gave one verdict to a larger claim that this report splits into several rows, and `—` means the replicate did not verdict this claim. **Replicate annotations** carries, by union, every scope caveat, placement note, disclaimer and escalation note any replicate attached.
- `Verdict`, `Confidence`, `Type`, `Verification mode`, `Scope` and the body of each claim come from the replicate whose verdict won (ties: most specific `Scope:` line, then lowest replicate number). The body is that replicate's headline evidence, condensed.
- Log paths. Each replicate kept its probe logs in the session scratchpad `/tmp/claude-1000/-workspace/c69d4d0f-5190-473b-ba2f-85b5a43f49ee/scratchpad/`, under `fc3r1/` (r1, which its report calls `LOGS/`), `fc3-1/` (r2, which its report also calls `LOGS/`) and `fc3r3/` (r3). This report writes each path with its directory so the two `LOGS/` spellings stay apart.
- Execution provenance is in each replicate report. Summary: all three ran as uid 1000 with git 2.39.5, bash 5.2, perl 5.36.0. r1 ran seven suites (283/283), probes P1-P6, mutants and X1-X7. r2 ran the orchestrator suite (20/20), four build-loop-check tests, probes E2-E12 and mutants M1-M6 plus a0014ce5's four. r3 ran eight suites (285/285), probes P, Q, R, U and mutants M0-M3 and a0-a4.
- All three read `docs/reviews/hallucination-patterns.md`. None edited it. r2 and r3 name the one-way cross-reference (Claims 26b, 89) as a candidate new pattern. r1 links Claim 91's tally to the logged test-count class. See Escalations.
- Compound-carried verdicts. In Claims 3b and 13a the winning verdict is a compound replicate's Mostly accurate. That replicate's own text puts the defect in the sibling row (3a, 13b). Both rows say so in their annotations.

---

## Claim 1: "The snippet trusts refs/heads/main itself: a same-uid loop that moves main's ref onto its own commit on top of the real history passes every hash check, and the snippet runs that commit's scripts ... Stated in the snippet's header."

**Location:** `docs/reviews/override-log.md:732`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that the snippet's start id is the ref and that the header says so. It does not establish the Won't-Fix judgement (Q-103's), or that the same mechanism is limited to claude-workflows (see Claim 17 and P6).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: the Won't-Fix ruling (Q-103) is not established · r1: in a project other than claude-workflows, the same move bypasses the image copy's ownership checks (P6). See Escalations E1 · r3 (compound, its Claim 73): verdicted together with the factual premises of all seven new rows
**Legibility-target:** for-orchestrator-synthesis

The start id is the ref, unchecked against anything: `sha="$(g rev-parse --verify -q "refs/heads/$m")"` (`test/lib/d6-snippet.bash:54`), passed to the reader as `$c` (`:78`). Every later id comes from bytes that hash, so a new commit on top of the real history passes. The header says: "it trusts refs/heads/main itself (a moved main is --main-log's to report, D13; F19, rows 509, 721)" (`test/lib/d6-snippet.bash:23-24`).

**Evidence:** `test/lib/d6-snippet.bash:23-24`, `test/lib/d6-snippet.bash:54`, `test/lib/d6-snippet.bash:58-78`

---

## Claim 2: "The snippet's own re-hash is plain SHA-1 with no collision detection ... Revisit trigger: claude-workflows moves to SHA-256 (the snippet then takes the image copy)"

**Location:** `docs/reviews/override-log.md:733`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hash function used and the non-SHA-1 branch. It does not establish the claim that a chosen-prefix collision is "out of a loop's reach today", which is a judgement about the world.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish the row's risk judgement" · r3 (compound, its Claim 73): verdicted together with the other six rows' premises
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
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "The magnitude is right, but most of the overhead is not fixed. E10 measured the snippet at 110-137 ms against 33-35 ms for a direct `--settings` run. The perl reader alone took 61-63 ms ... about 60 ms of the ~80 ms grows linearly with main's history". Precise version: "~80 ms over a direct run, about 60 ms of it the reader's walk, linear in main's first-parent commits". Also: "It does not establish the timing on other hosts" · r3 (compound, its Claim 73): "It does not re-measure '~70 ms' fork overhead". r3's Q1 timed one whole snippet run at 110 ms (its Claim 68)
**Legibility-target:** for-author

X3 measured the snippet at 0.110-0.114 s and a direct `build-loop.sh --help` at 0.014-0.016 s. That is about 95-100 ms of overhead at 5583a2cd, not ~70 ms. Part of it is not fixed. The reader walks every first-parent commit (`while (1) { ... obj($c, "commit") ... last unless defined $p; $c = $p }`, `test/lib/d6-snippet.bash:65-66`), 1,122 commits here, so the cost grows with history. A more precise row would say "~100 ms here, part of it linear in main's first-parent history".

**Evidence:** `test/lib/d6-snippet.bash:65-66`, `fc3r1/time.log`, `fc3-1/timing.log`

---

## Claim 3b: "the verified reader already cut the history walks from two to one"

**Location:** `docs/reviews/override-log.md:734`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the measured overhead in this repository at 1,122 first-parent commits, and the single walk. It does not establish the timing on other hosts.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound) · r3=Verified (compound)
**Replicate annotations:** merge note: r2 verdicted this clause and the ~70 ms clause (Claim 3a) as one claim. Its Mostly accurate rests on the timing, and its text says "'One walk' holds" · r1 (Verified, static): "d9515d09 ran `g rev-list --first-parent --max-parents=0 "$sha"` and then `g rev-list --first-parent "$sha"` ... (two walks). At 5583a2cd the only walk is the perl loop". It does not establish any timing · r3 (compound, its Claim 73): "the history walks cut from two to one" is among the premises it verified
**Legibility-target:** for-author

Headline evidence from r2 (compound). "One walk" holds: no rev-list is left in the file (paraphrased — no quote available because the claim is an absence; `rg rev-list test/lib/d6-snippet.bash` has no hit). The one walk is `my $tree; while (1) { my ($hd) = split /\n\n/, obj($c, "commit"), 2; ... last unless defined $p; $c = $p }` (`test/lib/d6-snippet.bash:65-66`). r2's Mostly accurate attaches to the sentence's "~70 ms of fixed fork overhead" (Claim 3a).

**Evidence:** `test/lib/d6-snippet.bash:65-66`, d9515d09's `test/lib/d6-snippet.bash`, `fc3-1/timing.log`

---

## Claim 4: "`refuse d6: WHY` (exit 2) can now precede any mode's output ... Contract for U4, written into the plan's as-built note"

**Location:** `docs/reviews/override-log.md:735`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal format and the plan note's hand-off. It does not establish U4's parser, which is not written yet.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: U4's parser is not established · r3 (compound, its Claim 73): verdicted with the other rows' premises ("the snippet refuses before running")
**Legibility-target:** for-orchestrator-synthesis

`no() { echo "refuse d6: $*"; exit 2; }` (`test/lib/d6-snippet.bash:39`) runs before any script, whatever the mode. The plan note says: "match a first line starting `refuse d6: ` before parsing any mode's output, as a stop, never as a brief's verdict" (`docs/working/plan-build-loop-handoff.md:326`).

**Evidence:** `test/lib/d6-snippet.bash:39`, `test/lib/d6-snippet.bash:87`, `docs/working/plan-build-loop-handoff.md:326`

---

## Claim 5: "the lib cannot be sourced before it is checked, it runs once per process, exporting it makes --state refuse (row 702), and the snippet's G lives only in its own bash"

**Location:** `docs/reviews/override-log.md:736`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four stated properties. It does not establish whether U4 can build a third wrapper.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "It does not establish which option U4 takes". E6 shows the refusal for log.date and log.showSignature too · r3 (compound, its Claim 73): row 704's premises verified (orchestrator :46-47, Q3)
**Legibility-target:** for-orchestrator-synthesis

Runs once: `[[ -z "$CALLER_COUNT" ]] || return 0` (`scripts/lib/dev-cycle-read.sh:352`). Mutant n2 removed it and test 19 went red. Exported pairs refused: a count pair `core.hooksPath` gets `refuse state core.hookspath` (`test/scripts/build-loop-orchestrator.bats:48-49`), and S1 test 2 passes. G is local to the snippet's bash: `G=(env ... git -c ...)` (`test/lib/d6-snippet.bash:40`), an array, never exported.

**Evidence:** `scripts/lib/dev-cycle-read.sh:351-361`, `test/lib/d6-snippet.bash:40`, `fc3r1/mutants.out`, `fc3r1/build-loop-orchestrator.log`

---

## Claim 6: "The snippet passes HARDEN as git -c pairs, which outrank a caller's git -c; git_harden passes them as count pairs, which a caller's git -c outranks ... a caller pair for a HARDEN key fails --state by name"

**Location:** `docs/reviews/override-log.md:737`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's precedence and caller_gate's refusal for log.date and log.showsignature. It does not establish the precedence in other git versions.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: other git versions not established · r3 (compound, its Claim 73): the "snippet's -c outranks a caller's -c" premise rests on git appending each `-c` after inherited GIT_CONFIG_PARAMETERS entries. r3 tagged this paraphrased, as git's documented behaviour; P5 executed the count-against-`-c` order
**Legibility-target:** for-orchestrator-synthesis

X1: a count pair `x.y=count` with a caller `GIT_CONFIG_PARAMETERS` `x.y=param` reads `param`, and a caller `x.y=caller` with a command-line `-c x.y=snippet` reads `snippet`. M's c1 test: `GIT_CONFIG_KEY_0=log.date` gives exit 2 and `refuse state log.date: ...`, and `GIT_CONFIG_PARAMETERS="'log.showsignature'='false'"` gives `refuse state log.showsignature: ...`.

**Evidence:** `scripts/build-loop.sh:559-575`, `fc3r1/prec.log`, `fc3r1/c1.log`, `fc3-1/probe5.log`

---

## Claim 7: "The canonical D6 source sits in test/lib/ beside fixtures; the plan calls it a copy of the SKILL.md block, its header the reverse"

**Location:** `docs/reviews/override-log.md:738`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two texts. It does not establish which copy U4 makes canonical.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3 (compound, its Claim 73): "the canonical copy in test/lib" is among the verified premises
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
**Scope:** Covers the function's body, both call sites and the idempotence guard. It does not establish that no later line overrides a variable on purpose (Claims 30 and 39 name those lines).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: does not establish that no later call site overrides a setting (build-loop.sh's two exceptions) · r2: E2 P7 executed that sourcing the lib makes 0 git calls · r3: mutant M2 deleted the return line and the environment test went red
**Legibility-target:** for-orchestrator-synthesis

`export GIT_CONFIG_COUNT="$c" GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none` (`scripts/lib/dev-cycle-read.sh:360`) is the set the diff removes from build-loop.sh. build-loop.sh runs `source "$READ_LIB"` / `scrub_reexec ...` (`scripts/build-loop.sh:442-443`), then the mode `case` (`:445-488`, no git), then `git_harden` (`:497`). dev-cycle.sh runs `scrub_reexec` (`scripts/dev-cycle.sh:105`), the arg loop, then `git_harden` (`:131`) and the first git call (`:132`). Test 19 calls git_harden twice and passes. Its mutant n2 fails.

**Evidence:** `scripts/lib/dev-cycle-read.sh:349-361`, `scripts/build-loop.sh:438-497`, `scripts/dev-cycle.sh:93-132`, `fc3r1/mutants.out`

---

## Claim 9: "HARDEN gains `log.date=default` (row 505: a bogus log.date stopped --check-brief) and `log.showSignature=false` (a planted one made the digest's git log run gpg.program on main); caller_gate refuses both keys by name with the rest."

**Location:** `docs/working/plan-build-loop-handoff.md:326` (same claims in commit 9925f2a7 and a0014ce5)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two pairs, main's gpg.program run and caller_gate's refusal. It does not establish every git subcommand's reading of log.showSignature.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish behaviour on a git newer than 2.39.5". Under `log.date=bogus` main's digest exits 128 and the branch's exits 0 · r3: "does not establish other git log config keys (only log.abbrevCommit is used elsewhere)". Q3 refused both keys whatever the value (`log.date=iso` included)
**Legibility-target:** for-orchestrator-synthesis

`HARDEN=(... log.date=default log.showSignature=false)` (`scripts/lib/dev-cycle-read.sh:349`). P4: main's `dev-cycle.sh --since=2020-01-01` with `log.showSignature true` and `gpg.program` set printed "P4 main: gpg.program RAN", and 5583a2cd's printed "did not run". caller_gate takes its keys from the same list: `for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done` (`scripts/build-loop.sh:567`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:349`, `scripts/build-loop.sh:559-575`, `fc3r1/probes.log` (P4), `fc3r1/c1.log`, `fc3-1/probe3.log`, `fc3r3/probe2.log` (Q3)

---

## Claim 10: "dev-cycle.sh now reads no user or system git config and no transport (its header says so)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the global/system config through the exported variables (every logged call carries G=/dev/null and S=1) and the safe.directory effect, with ownership simulated by git's `GIT_TEST_ASSUME_DIFFERENT_OWNER`. It does not establish a real lazy fetch failing under dev-cycle.sh itself (that mechanism is executed for --check, Claim 41) or a repository truly owned by another uid.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "It does not cover the deliberate `GIT_LITERAL_PATHSPECS=0` overrides, which are not config or transport" · r2: "It does not execute a lazy fetch through dev-cycle.sh (that part rests on `GIT_ALLOW_PROTOCOL=none`)"
**Legibility-target:** for-orchestrator-synthesis

The export is `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none` (`scripts/lib/dev-cycle-read.sh:360`). Test 20 logs every git call dev-cycle.sh makes through a PATH shim and requires `G=/dev/null P=none S=1` on each one. It passed in S1. P7: `P7 main exit=0` against `Not inside a git repository` / `P7 head exit=1` under a global `safe.directory = *`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:360`, `test/scripts/build-loop-orchestrator.bats:363-380`, `fc3r3/suite.log`, `fc3r3/probe.log` (P7)

---

## Claim 11: "`test/lib/d6-snippet.bash` is a script bash reads, not a function pasted into the caller's shell (its `d6` function lives only in that bash) ... U4's SKILL.md feeds the file, byte for byte, to `bash -s -- SCRIPT ARG... <<'D6'`, and the snippet runs everything with stdin from /dev/null."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heredoc form from `zsh -f`, run against the real D6_ROOT in a clone. It does not establish the SKILL.md block, which U4 writes, or byte equality (T33's pending half).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound): verdicted together with the snippet header (`test/lib/d6-snippet.bash:2-10`) and `:90-92` (Claims 46, 58) · r2: "It does not establish a zsh caller (not run)". r2 ran the heredoc from bash. r1 ran it from `zsh -f` · r3: ran it from a pipe and from a file on stdin. "It does not establish U4's SKILL.md block"
**Legibility-target:** for-orchestrator-synthesis

P1 wrote `bash -s -- build-loop.sh --settings <<'D6'`, the file and `D6` to a script and ran it with `zsh -f`. Exit 0, and the five `--settings` lines printed. The file ends `d6 "$@" </dev/null` (`test/lib/d6-snippet.bash:92`), and every path in `d6` ends in `exit` (`:39`, `:44`, `:88`), so bash reads no further heredoc line.

**Evidence:** `test/lib/d6-snippet.bash:36-92`, `fc3r1/probes.log` (P1), `fc3-1/probe3.log`, `fc3r3/probe2.log` (Q1)

---

## Claim 12: "the Bash tool's shell can be zsh (an alias `g` broke a pasted function)"

**Location:** `docs/working/plan-build-loop-handoff.md:326` (also commit a0014ce5)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond the session environment stating zsh. It does not establish the alias incident.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1+r2+r3: the incident is in an earlier session's transcript, not in the repository. r1 rated it Confidence Low
**Legibility-target:** for-orchestrator-synthesis

This session's environment reports "Shell: zsh", and zsh's glob errors appear in this run's tool output (paraphrased — no quote available because it is session metadata, not repository text). The `g` alias incident is in an earlier session's transcript, which is not available here.

**Evidence:** `docs/working/plan-build-loop-handoff.md:326`

---

## Claim 13a: "Checks, in order: no replace ref, no info/grafts, exactly one of refs/heads/main and master, not symbolic, its ref's own object a commit (not peeled from a tag ...)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of the snippet's checks (exact) and which scripts have a default_gate. It does not establish what dev-cycle.sh reads when origin/HEAD names another branch (row 548, settled).
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified · r3=Verified
**Replicate annotations:** merge note: r1 verdicted this list and the origin/HEAD / "before, not instead of" clauses (Claims 13b, 53) as one claim. Its Mostly accurate rests on those clauses, and its text says "The order matches the code" · r2 (Verified, executed): "Test 12 refuses each case, including an annotated tag written into the ref". It "does not establish a check on origin/HEAD (13b)" · r3 (Verified, executed): "with no `^{commit}` peel". It "does not establish origin/HEAD handling beyond its absence from the snippet"
**Legibility-target:** for-author

Headline evidence from r1 (compound). The order matches the code: replace refs (`test/lib/d6-snippet.bash:47-48`), grafts (`:49-50`), exactly one of main and master (`:51-52`), not symbolic (`:53`), and `[[ "$(g cat-file -t "$sha")" == commit ]]` on the unpeeled ref (`:54`). r1's Mostly accurate attaches to "left to the script's default_gate", which holds only for build-loop.sh (Claim 13b).

**Evidence:** `test/lib/d6-snippet.bash:47-54`, `test/scripts/build-loop-orchestrator.bats:271-284`

---

## Claim 13b: "(origin/HEAD is left to the script's default_gate)" ... "These checks come before, not instead of, the script's own state and default-branch gates."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which scripts and modes run default_gate and state_gate. It does not establish the settled ruling (row 548).
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r1+r2+r3: a re-flag of settled row 548, not a new defect · r1: "dev-cycle.sh's `resolve_main` tries origin/HEAD first (`scripts/dev-cycle.sh:198`)". Precise text: "origin/HEAD is left to build-loop.sh's default_gate (dev-cycle.sh has none: row 548)" · r2: "under the snippet a dev-cycle.sh run can read a branch other than the one the snippet checked" · r3 (compound, its Claim 15, also covering `test/lib/d6-snippet.bash:34-35`): "This is a text imprecision only; no behaviour change is implied". r3 graded it Mostly accurate rather than Incorrect because row 548 is settled and stated in the lib · r3 (its Claim 5) verdicted the origin/HEAD parenthesis as part of the Verified check list, and scoped that verdict to origin/HEAD's absence from the snippet
**Legibility-target:** for-author

This holds for build-loop.sh's gated modes only. dev-cycle.sh defines and runs neither gate, and its `resolve_main` follows origin/HEAD first: `origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD ...)"; [[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")` (`scripts/lib/dev-cycle-read.sh:568-569`). build-loop.sh's read modes are ungated too: `GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1` (`scripts/build-loop.sh:608`). A precise version: "left to build-loop.sh's default_gate in its gated modes; dev-cycle.sh runs none (row 548)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:565-587`, `scripts/build-loop.sh:579-598`, `scripts/build-loop.sh:608`, `docs/reviews/override-log.md:548`

---

## Claim 14: "the verified reader ...: one perl process drives one `git cat-file --batch`, uses an object only once its bytes SHA-1 to its id, and takes every next id from bytes it has checked ..."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sources of every id and byte the reader uses: the commit header, tree entries, object header lines, sizes, the batch protocol and the exit the bash side reads. It does not establish that perl's parent parse equals git's for a malformed commit: perl takes the first `^parent` line anywhere in the header, git only the lines after `tree`. Such a commit would have to be in main's own hashed first-parent history.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: perl's `/^parent .../m` may read a malformed but hash-valid commit header differently from git. This needs a main the loop has moved (row 732's class). See Escalations E5 · r1 (compound, also `test/lib/d6-snippet.bash:11-19`): "It does not establish the exact two-pack layout i2 used" · r3: "A parent id that is not 40 lowercase hex reads as a root, which fails toward the root-owned image copy". Mutant M3 (SHA-1 gate removed) turned three tests red. P3 read a tree holding a name with a newline correctly, and a symlink entry died
**Legibility-target:** for-orchestrator-synthesis

`open2(my $r, my $w, @git, "cat-file", "--batch")` is the only reader (`test/lib/d6-snippet.bash:59`). `obj` requires `$i eq $id && $t eq $want && $s =~ /\A[0-9]+\z/ && read($r, $b, $s) == $s && getc($r) eq "\n"` and `sha1_hex("$t $s\0$b") eq $id` (`:61-62`). The next ids come from checked bytes: `$hd =~ /\Atree ([0-9a-f]{40})\n/` and `/^parent ([0-9a-f]{40})$/m` from the commit header (`:65-66`), and `unpack("H*", $id)` from tree entries with exact-name and mode checks (`:64`). E3 M1, which drops the hash line, turns tests 11, 13 and 14 red. E9 in the real repository printed `main`, and all four written files hash to main's blobs.

**Evidence:** `test/lib/d6-snippet.bash:58-71`, `test/lib/d6-snippet.bash:78`, `fc3-1/mutants.log`, `fc3-1/real-repo-reader.log`

---

## Claim 15: "No other reader (rev-list, ls-tree) decides what runs, so a second copy of an object, packed or loose, cannot either (i2 B1's two-pack forgery now runs main's real scripts; a forged copy read would refuse)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers a reconstructed two-pack forgery (a second pack whose idx maps main's build-loop.sh blob id to planted bytes) with either pack newer, plus the refusal when altered bytes reach the reader. It does not reproduce i2's exact probe.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: i2's exact two-pack layout was not rebuilt · r1 (compound): P5 packed the real objects with a forged loose `scripts` tree at the same id. `git ls-tree` still showed the real blob, and the snippet ran the real `--settings` · r3: "Which copy cat-file returns there is git's choice; either outcome is covered (real runs, forged refuses)". Q2 packed-real/loose-forged gave exit 0 and `replaced=0`
**Legibility-target:** for-orchestrator-synthesis

E4 F1: with the forged pack newer, plain `git cat-file -p` printed `echo PLANTED; exit 0`, but the snippet exited 0 with main's real `--settings` output. F2 (forged pack older) gave the same result. The forged-read half is test 11's tamper case: a git whose `--batch` output is altered gives the `A1` refusal and "does not hash to its id" on stderr (`test/scripts/build-loop-orchestrator.bats:262-265`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:262-266`, `fc3-1/probe2.log`, `fc3r1/probes.log` (P5), `fc3r3/probe2.log` (Q2)

---

## Claim 16: "Any read failure refuses, never falls to the image copy (i2 B2: a missing first-parent commit, a shallow clone)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reader's failures and the snippet's own git and mkdir steps. A non-SHA-1 repository takes the image copy by design, which is not a read failure.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish a reader that exits 0 with no output (that path also refuses, through `:86`)" · r3: "does not establish the refusal when another process kills perl and bash still sees status 0, which is not a reachable path". r3 notes this matters because a root-owned /opt copy exists on this host
**Legibility-target:** for-orchestrator-synthesis

`x="$(LC_ALL=C perl -e "$P" ...)" || no "..."` (`test/lib/d6-snippet.bash:78`). Any non-`main`/`other` answer gets `else no "the verified reader gave no answer"` (`:86`). P2: a missing object exits 255 and an unwritable output exits 2, both non-zero. Test 15 passes, and mutant n1, which replaced the refusal with `x=other`, turned it red.

**Evidence:** `test/lib/d6-snippet.bash:75-86`, `fc3r1/probes.log` (P2), `fc3r1/n1.log`, `fc3-1/mutants.log`, `fc3r3/mutants.log` (M1)

---

## Claim 17: "Another root, or a repository that is not SHA-1, runs `D6_OPT/scripts/SCRIPT` once the four files are regular, root-owned (`stat -c %u`), not symlinks and not writable (`-w`), and so is every directory from `scripts/lib` up to `/`"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the narrow reading, "a repository whose main's first-parent root id is not D6_ROOT". It does not establish that a repository other than claude-workflows always takes the image copy. P6 copied 640cf007's commit object into a fresh repository and pointed main at a commit whose parent is that object. The snippet printed "planted build-loop.sh", exit 0: that repository's own scripts ran, not /opt's. This needs a loop that moves main (Claim 1's class), but in a project other than claude-workflows it bypasses the image copy's ownership checks entirely. See escalation E1.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound, also `test/lib/d6-snippet.bash:19-22`): the P6 residue in Scope, routed as Escalations E1 · r2: "The non-SHA-1 path is read, not run". Test 17 ran against the real /opt, and mutant M2 turns test 18 red · r3: "It does not execute a SHA-256 repository". In P3 a foreign root printed `other` with exit 0
**Legibility-target:** for-orchestrator-synthesis

`own() { [[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no ...; }` (`test/lib/d6-snippet.bash:42`). The files are checked by `for f in "${F[@]}"; do own "$d/scripts/$f"; [[ -f "$d/scripts/$f" ]] || no ...; done`, and the directories by `x="$d/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done` (`:84-85`). The script runs as `bash "$d/scripts/$s"` (`:87`). The repository test is `if ($c ne $root) { print "other\n"; exit 0 }` on the last commit of the first-parent walk (`:67`). T37's two tests ran here, and mutant m2 (own() always true) turned the uid-owned case red.

**Evidence:** `test/lib/d6-snippet.bash:42`, `test/lib/d6-snippet.bash:65-67`, `test/lib/d6-snippet.bash:80-87`, `fc3r1/probes.log` (P6), `fc3r1/m2.log`

---

## Claim 18: "(the `-w` test makes a root run refuse unless the mount is read-only)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing executed. It does not establish behaviour under uid 0.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1+r2+r3: execution needs uid 0, and the sandbox runs as uid 1000 · r1+r3: statically, bash's `-w` is true for root on a writable mount, which fits the claim
**Legibility-target:** for-orchestrator-synthesis

Execution is required and blocked because no uid 0 is available. Statically, `! -w "$1"` (`test/lib/d6-snippet.bash:42`) is false for root on a writable mount whatever the mode bits, which fits the claim.

**Evidence:** `test/lib/d6-snippet.bash:42`

---

## Claim 19: "The run has BASH_ENV, ENV and DEV_CYCLE_SCRUBBED unset; the temp dir is removed on exit."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the run and the EXIT trap after mktemp, on both success and refusal. A refusal before mktemp creates no directory to remove.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: removal after a SIGKILL is not established
**Legibility-target:** for-orchestrator-synthesis

`env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"`, then `exit "$?"` (`test/lib/d6-snippet.bash:87-88`). `trap 'rm -rf "$t"' EXIT` is set right after `t="$(mktemp -d)"` (`:72-73`). T33 checks `[ -z "$(ls -A "$TMPDIR")" ]` after a run and after a tamper refusal (`test/scripts/build-loop-orchestrator.bats:261`, `:267`), and it passes.

**Evidence:** `test/lib/d6-snippet.bash:72-88`, `test/scripts/build-loop-orchestrator.bats:245-269`, `fc3r1/probes.log`, `fc3-1/real-repo-d6.log`

---

## Claim 20: "Refusal: one `refuse d6: WHY` line on stdout and exit 2, nothing run (git or perl may add a stderr line); exit 1 for another first argument"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every refusal the list names: replace ref, grafts, the default-branch cases, a non-commit ref, unreadable or unhashed history, trees and files, a shallow history, a non-regular script on main (symlink case), the image-copy ownership checks, git or temp-dir failures, and the bad first argument. It does not establish the stderr text of every failure.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound): verdicted together with the header's Exit list (`test/lib/d6-snippet.bash:26-33`, Claim 51) · r1+r2+r3: the stderr content is not established (see Claim 68 for one stale stderr comment)
**Legibility-target:** for-orchestrator-synthesis

T36's `d6_is` requires `[ "$status" -eq 2 ] && [ "$output" = "$1" ] && [ -z "$stderr" ]` (`test/scripts/build-loop-orchestrator.bats:237`) for each check in `:271-284`. The bad-argument case requires exit 1, empty stdout and the stderr line (`:283`). All pass. M's c1 test: a symlinked `scripts/questions.sh` on main gives exit 2 and a `refuse d6:` line.

**Evidence:** `test/lib/d6-snippet.bash:26-33`, `test/lib/d6-snippet.bash:39-54`, `test/lib/d6-snippet.bash:70`, `fc3r1/c1.log`, `fc3r1/build-loop-orchestrator.log`

---

## Claim 21: "Its git carries HARDEN as `-c` and git_harden's variables (G), a test pins the lists equal (the snippet cannot source the lib before checking it)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lists' contents and order: test 19 pins the lib's HARDEN and environment to H and E, and the G line to the same H and E. It does not pin precedence (Claim 6).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3 (compound): verdicted together with the snippet header's sentence (`test/lib/d6-snippet.bash:32-34`, Claim 52) · r1+r2+r3: precedence is not pinned · r2: mutant M3 (one HARDEN pair dropped) turns test 19 red
**Legibility-target:** for-orchestrator-synthesis

The snippet's line is `G=(env GIT_NO_REPLACE_OBJECTS=1 ... git -c core.useReplaceRefs=false ... -c log.showSignature=false)` (`test/lib/d6-snippet.bash:40`). The cat-file reader gets the same array (`:78`). Test 19 checks `printf "pair %s\n" "${HARDEN[@]}"` and the exported `GIT_*` set against `H`/`E` (`test/scripts/build-loop-orchestrator.bats:348-356`), then G's `-c` list and its `GIT_*=` words against the same `H`/`E` (`:358-360`). It passes.

**Evidence:** `test/lib/d6-snippet.bash:40`, `test/lib/d6-snippet.bash:78`, `test/scripts/build-loop-orchestrator.bats:346-361`

---

## Claim 22: "The snippet trusts refs/heads/main itself: a moved main is F19's class (--main-log reports an honest slip, not a forger; rows 509, 721, and this unit's row)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and content of the cited rows. It does not establish the ruling, which is Q-103's.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the Q-103 ruling is not established · r3: also verified that the start id is the ref (`test/lib/d6-snippet.bash:54`)
**Legibility-target:** for-orchestrator-synthesis

Row 721 says "D13's check catches an honest slip ..., not a forger" (`docs/reviews/override-log.md:721`), and this unit's row is `:732` (Claim 1).

**Evidence:** `docs/reviews/override-log.md:509`, `docs/reviews/override-log.md:721`, `docs/reviews/override-log.md:732`

---

## Claim 23: "U4 hand-offs (override rows dated 2026-10-12): ... route the orchestrator's own git reads through a script mode run by the snippet (git_harden is no shell wrapper: row 704 amended) ...; call --state through the snippet, which exports no pair (row 702); write the SKILL.md block, name one canonical copy ..."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the snippet exports no pair and that rows 735, 736 and 738 hold the hand-offs. It does not establish U4's implementation.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3: the amending row exists and row 704 itself is unedited. "G is a per-call `env` prefix, not an export"
**Legibility-target:** for-orchestrator-synthesis

Test 11 runs `d6 build-loop.sh --state` and gets `ok` (`test/scripts/build-loop-orchestrator.bats:257-258`). Rows 735, 736 and 738 are dated 2026-10-12 and keyed `feat/build-loop-u3b3`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:257-258`, `docs/reviews/override-log.md:735-738`, `docs/reviews/override-log.md:704`

---

## Claim 24: "Rows: 200 discharged (every byte run is hashed before it is written; a writer racing the 0700 dir is the Q-103 class, row 509)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claude-workflows (extraction) path, which row 200 is about. The lib is hashed with the scripts, and the files are written into a fresh `mktemp -d`. It does not cover the image-copy path, whose bytes are trusted by ownership and not hashed, or a racer after the write (row 509, settled).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the image-copy path is not hashed (ownership stands in), and a racer on the 0700 dir is row 509's class, not established
**Legibility-target:** for-orchestrator-synthesis

The four files, `lib/dev-cycle-read.sh` among them, are written only from `my $b = obj(..., "blob")`, which has passed the SHA-1 check (`test/lib/d6-snippet.bash:69-70`). The directory comes from `t="$(mktemp -d)"` (`:72`), mode 0700 by mktemp's default. Row 200 asked to "hash-check the lib with the scripts and extract into a fresh mktemp dir" (`docs/reviews/override-log.md:200`).

**Evidence:** `test/lib/d6-snippet.bash:69-74`, `docs/reviews/override-log.md:200`, `fc3r1/build-loop-orchestrator.log` (test 11)

---

## Claim 25: "311 (git_harden's exact environment is pinned)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers row 311's case: dropping GIT_NO_REPLACE_OBJECTS=1 now fails a test. It does not establish a behavioural test of replace refs under that variable alone.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: the mutant was read, not run. The conclusion follows from test 19's exact comparison of the `GIT_*` environment. r3 ran it
**Legibility-target:** for-orchestrator-synthesis

Row 311 reads "`GIT_NO_REPLACE_OBJECTS=1` … can be dropped with no test failing" (`docs/reviews/override-log.md:311`). The row-311 mutant removed it from git_harden's export, and the result was `row-311 mutant bats-exit=1` / `not ok 1 git_harden exports …`.

**Evidence:** `docs/reviews/override-log.md:311`, `scripts/lib/dev-cycle-read.sh:360`, `test/scripts/build-loop-orchestrator.bats:346-356`, `fc3r3/probe3.log`

---

## Claim 26a: "644/648 not moved (store_check stays build-loop.sh's; the snippet's reader is narrower, SHA-1 only and needs no second-copy rule since it uses only bytes it hashed"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where store_check lives and what the reader omits. It does not establish the cross-reference (26b).
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** merge note: r1 (its Claim 23) and r3 (its Claim 19) quoted the whole sentence but scoped their Incorrect to the "each comment names the other" clause (Claim 26b) · r1: "It does not dispute the decision to leave store_check in build-loop.sh" · r3: "The rest (store_check stays in build-loop.sh; the reader is SHA-1 only and has no second-copy rule) is accurate"
**Legibility-target:** for-orchestrator-synthesis

store_check is still defined only in build-loop.sh (`scripts/build-loop.sh:954`). The reader has no store listing and accepts only bytes that pass `sha1_hex` (`test/lib/d6-snippet.bash:62`).

**Evidence:** `scripts/build-loop.sh:927-954`, `test/lib/d6-snippet.bash:58-71`

---

## Claim 26b: "each comment names the other"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference / Staleness
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "each comment names the other" clause. The rest (store_check stays in build-loop.sh; the reader is SHA-1 only and has no second-copy rule) is accurate. It does not establish whether a one-way reference suffices for rows 644/648.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1: `grep -n -i store test/lib/d6-snippet.bash` finds nothing at 5583a2cd or c9648432. Fix: add a store_check reference to the snippet's reader comment (`test/lib/d6-snippet.bash:55-57`), or reword the note to "store_check's comment names the snippet". Comment/doc only · r2: "the branch's history of that file has never added the word". Fix: add the reverse pointer to the snippet's header, or drop the clause (and note it against c9648432's B10) · r1+r2+r3: same defect as Claim 89 (c9648432's B10). See Escalations E2
**Legibility-target:** for-author

store_check's comment names the snippet: "(The D6 snippet, test/lib/d6-snippet.bash, runs a narrower reader before this script: SHA-1 only and no second-copy rule, …)" (`scripts/build-loop.sh:928-930`). The snippet never names store_check or build-loop.sh's object check (paraphrased — no quote available because this is an absence claim: `grep -n -i 'store\|second.copy\|narrow\|row 64[48]' test/lib/d6-snippet.bash` returns nothing). The only other mention, "past build-loop.sh's store_check", is in the lib's git_harden header (`scripts/lib/dev-cycle-read.sh:336`), not in the snippet. The reference is one-way. Either the snippet's reader comment (`test/lib/d6-snippet.bash:55-57`) names store_check, or the plan stops saying "each comment names the other".

**Evidence:** `scripts/build-loop.sh:927-930`, `test/lib/d6-snippet.bash:55-57`, `scripts/lib/dev-cycle-read.sh:336`

---

## Claim 27: "666 no change (row 709's reasons)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that row 709 states reasons for 666. It does not re-judge them.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

Row 709 reads "666's listed keys change W's own files only (row 657's class) or are the caller's shell" (`docs/reviews/override-log.md:709`).

**Evidence:** `docs/reviews/override-log.md:666`, `docs/reviews/override-log.md:709`

---

## Claim 28: "(the lib's HARDEN list: core.useReplaceRefs, core.hooksPath, core.fsmonitor, core.attributesFile, core.commitGraph, core.multiPackIndex, log.date, log.showSignature; a git -c pair would win over it)"

**Location:** `scripts/build-loop.sh:134-137`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight keys and the `-c` precedence. Nothing is left unchecked.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2 (static): precedence is covered by its Claims 6/39 (merged Claims 6, 42) · r3: "It does not establish other keys caller_gate refuses through STATE_KEYS_RE"
**Legibility-target:** for-orchestrator-synthesis

These are the eight keys of `HARDEN=(...)` (`scripts/lib/dev-cycle-read.sh:349`), in order. X1 shows a caller `-c` beats a count pair.

**Evidence:** `scripts/build-loop.sh:134-137`, `scripts/lib/dev-cycle-read.sh:349`, `fc3r1/prec.log`, `fc3r3/probe.log` (P5)

---

## Claim 29: "The caller's global config, for merge_ident alone (...); every other call reads none." (CALLER_GLOBAL captured before git_harden overwrites GIT_CONFIG_GLOBAL)

**Location:** `scripts/build-loop.sh:490-492`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the capture order and the single use. It does not establish merge_ident's ident checks.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2 (compound): verdicted together with "Every git call in this process ... runs hardened" (Claim 30)
**Legibility-target:** for-orchestrator-synthesis

The capture is `CALLER_GLOBAL=(-u GIT_CONFIG_GLOBAL); [[ -z "${GIT_CONFIG_GLOBAL+set}" ]] || CALLER_GLOBAL=("GIT_CONFIG_GLOBAL=$GIT_CONFIG_GLOBAL")` at `:492`, before `git_harden` at `:497`. The only use of `CALLER_GLOBAL` is at `:1321` (grep).

**Evidence:** `scripts/build-loop.sh:492`, `scripts/build-loop.sh:497`, `scripts/build-loop.sh:1321`

---

## Claim 30: "Every git call in this process, the lib's included, runs hardened, but for caller_gate's read of the caller's pairs and merge_ident's CALLER_GLOBAL"

**Location:** `scripts/build-loop.sh:493-497`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers config pairs, the global and system config, and transport across build-loop.sh and the lib. It does not count `md_ls`'s `GIT_LITERAL_PATHSPECS=0` (`scripts/lib/dev-cycle-read.sh:1601`), a deliberate pathspec override with explicit `:(glob,icase)` magic that leaves all config and transport hardening in place.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: md_ls's `GIT_LITERAL_PATHSPECS=0` is not counted as an exception · r2: "It does not establish a call log for every other mode". T26 passes · r3: "The A17 history is not re-run"
**Legibility-target:** for-orchestrator-synthesis

`CALLER_GLOBAL=...` (`:492`) runs before `git_harden` (`:497`), so it holds the caller's value. The only lines that hand back a caller setting are `x="$(GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list ...)"` (`:564`) and `env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var ...` (`:1321`). That is what a grep for every `GIT_CONFIG_COUNT=`, `GIT_CONFIG_GLOBAL=`, `-u GIT_` and `GIT_ALLOW_PROTOCOL=` assignment in build-loop.sh, the lib and dev-cycle.sh returns (paraphrased — no quote available because this is a grep result over three files).

**Evidence:** `scripts/build-loop.sh:490-497`, `scripts/build-loop.sh:564`, `scripts/build-loop.sh:1317-1325`, `fc3-1/bats-check-filter.log`, `fc3r3/suite.log`

---

## Claim 31: The comments renamed harden → git_harden: "which git_harden does not switch off", "which git_harden extends and trusts", "so git_harden's own pairs are not listed", "git applies git -c pairs after git_harden's ...", "git_harden switches off the multi-pack-index", "Item 2's fsmonitor and replace refs are git_harden's", "which git_harden hides from the gate's own git"

**Location:** `scripts/build-loop.sh:499` (also `:536`, `:554-556`, `:943-944`, `:1105`, `:1114`)
**Type:** Staleness / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the symbol exists and that each sentence still matches git_harden. The precedence parts rest on Claim 42's execution.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3 (its Claim 26, sites `:943-944`, `:1105`, `:1114`): "It does not re-verify store_check or checkout_gate"
**Legibility-target:** for-orchestrator-synthesis

`git_harden` exists (`scripts/lib/dev-cycle-read.sh:351`) and sets `core.multiPackIndex=false`, `core.fsmonitor=false`, `core.useReplaceRefs=false`, `core.attributesFile=/dev/null` (`:349`). caller_gate reads with `GIT_CONFIG_COUNT="$CALLER_COUNT"`, so git_harden's pairs are not listed (`scripts/build-loop.sh:564`). A caller's count pairs take indices 0..N-1, before HARDEN's (`scripts/lib/dev-cycle-read.sh:352-358`).

**Evidence:** `scripts/build-loop.sh:499`, `scripts/build-loop.sh:536`, `scripts/build-loop.sh:546-557`, `scripts/build-loop.sh:943`, `scripts/build-loop.sh:1105`, `scripts/build-loop.sh:1114`

---

## Claim 32: "A caller pair ... (read with the caller's count, so git_harden's own pairs are not listed) ... git applies git -c pairs after git_harden's, so they win (a GIT_CONFIG_COUNT pair comes before git_harden's and loses, but is refused too)."

**Location:** `scripts/build-loop.sh:553-557`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5. It does not establish other versions.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2 (compound, its Claim 30): verdicted with the other renamed comments (Claim 31) · r3: "It does not establish multi-valued keys"
**Legibility-target:** for-orchestrator-synthesis

`GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list --show-scope --name-only` (`scripts/build-loop.sh:564`) limits the read to indices below the caller's count. git_harden puts HARDEN at indices from the caller's count upward (`scripts/lib/dev-cycle-read.sh:357-359`), so a caller's count pair comes earlier and loses. X1: `-c` beats a count pair. S1 test 2 and c1 show the count-pair refusal.

**Evidence:** `scripts/build-loop.sh:551-575`, `scripts/lib/dev-cycle-read.sh:351-361`, `fc3r1/prec.log`, `fc3r1/c1.log`, `fc3r3/probe.log` (P5)

---

## Claim 33: "(The D6 snippet, test/lib/d6-snippet.bash, runs a narrower reader before this script: SHA-1 only and no second-copy rule, since it uses only bytes it has hashed itself.)"

**Location:** `scripts/build-loop.sh:928-930`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reader's properties. It does not establish the reverse cross-reference (Claim 26b).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: the reverse pointer is not established (Claim 26b) · r3: "It does not establish that the snippet is the only caller path (U4)"
**Legibility-target:** for-orchestrator-synthesis

SHA-1 only: `if [[ "$x" == sha1 ]]` (`test/lib/d6-snippet.bash:77`). The reader has no listing of object copies, only `obj`'s hash check (`:60-62`).

**Evidence:** `test/lib/d6-snippet.bash:58-79`, `scripts/build-loop.sh:927-930`

---

## Claim 34: "Its git reads are hardened (the lib's git_harden): they read no user or system git config (a repository owned by another user that needs a global safe.directory reads as "Not inside a git repository") and no transport (a partial clone's missing object fails)."

**Location:** `scripts/dev-cycle.sh:83-86` (same note in commit 9925f2a7)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the safe.directory consequence with the different owner simulated by git's `GIT_TEST_ASSUME_DIFFERENT_OWNER=1`, not a real second uid. The no-transport half rests on git_harden's export and build-loop-check's partial-clone tests (`:1685`, `:1729`), which exercise build-loop.sh, not dev-cycle.sh.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: ownership simulated, not a real second uid. The partial-clone half was not run through dev-cycle.sh · r2: main's dev-cycle.sh reads the global safe.directory (exit 0), which shows the effect is the branch's. r2 and r3 rated it Confidence High
**Legibility-target:** for-orchestrator-synthesis

X2: with a global `safe.directory=*`, plain git found the repository. 5583a2cd's `dev-cycle.sh --check-path x` printed "Not inside a git repository" (exit 1), while main's dev-cycle.sh answered `skip x: ...` (exit 0). git_harden exports `GIT_ALLOW_PROTOCOL=none` (`scripts/lib/dev-cycle-read.sh:360`).

**Evidence:** `scripts/dev-cycle.sh:83-86`, `scripts/dev-cycle.sh:131-132`, `fc3r1/safe.log`, `fc3-1/probe1.log`, `fc3r3/probe.log` (P7)

---

## Claim 35: "Exit: ... 1 bad usage, a GIT_CONFIG_COUNT that is not plain decimal, not a git repo, ..."

**Location:** `scripts/dev-cycle.sh:87-90`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 010 and 1x through scrub_reexec. It does not cover `-h`, which exits 0 before git_harden.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: other exit lines (unchanged) not established · r3: "It does not exercise a leading-blank count for dev-cycle.sh (build-loop.sh's test covers `" 1"`)"
**Legibility-target:** for-orchestrator-synthesis

X4: both counts printed "dev-cycle.sh: GIT_CONFIG_COUNT is not a plain decimal count", exit 1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:354`, `fc3r1/dc-count.log`, `fc3-1/probe1.log`, `fc3r3/probe.log` (P6)

---

## Claim 36: "Every git call from here on, the lib's and questions.sh's included, runs hardened, as build-loop.sh's do (the lib's git_harden: no hook, fsmonitor, replace ref, user or system config, or transport)"

**Location:** `scripts/dev-cycle.sh:127-131`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git call after `:131`, children included. questions.sh does not reset any GIT_ variable (paraphrased — no quote available because this is a claim about absence: grep for `GIT_` in `scripts/questions.sh` finds none). It does not cover `matches()`'s deliberate `GIT_LITERAL_PATHSPECS=0` with explicit `:(glob)`/`:(literal)` magic (`:149`, `:153`), which predates the diff.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3 (compound): verdicted together with "File names are literal, not pathspecs" (Claim 37) · r2: "It does not establish calls in modes not run". E2 P7 logged 10 digest calls, 2 of them from `questions.sh open`, none lacking the pairs. Mutant M6 (call removed) turns test 20 red · r3: the `matches()` and `md_ls` pathspec overrides "keep every listed protection"
**Legibility-target:** for-orchestrator-synthesis

`git_harden` (`:131`) now exports `GIT_LITERAL_PATHSPECS=1` before `ROOT="$(git rev-parse --show-toplevel ...)"` (`:132`). questions.sh runs as `bash "$QS" open` (`:408`), a child that inherits the exports. Test 20's shim, which logs the digest's calls, questions.sh's among them, passes.

**Evidence:** `scripts/dev-cycle.sh:127-140`, `scripts/dev-cycle.sh:389-408`, `fc3r1/build-loop-orchestrator.log`, `fc3-1/probe1.log`

---

## Claim 37: "File names are literal, not pathspecs." (now via git_harden's export; the old `export GIT_LITERAL_PATHSPECS=1` removed)

**Location:** `scripts/dev-cycle.sh:130` (the removed export at `:135-136`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every call after line 131, which now gets `GIT_LITERAL_PATHSPECS=1` earlier than before (the old export followed the `cd`). It does not cover the three deliberate pattern calls `GIT_LITERAL_PATHSPECS=0 git ls-files` (`scripts/dev-cycle.sh:149`, `:153`, `scripts/lib/dev-cycle-read.sh:1601`), which predate this diff.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3 (its Claims 29 compound and 30): "It does not cover a caller that sources the lib without calling git_harden (none does)"
**Legibility-target:** for-orchestrator-synthesis

`export GIT_CONFIG_COUNT="$c" GIT_LITERAL_PATHSPECS=1 ...` (`scripts/lib/dev-cycle-read.sh:360`) runs at `scripts/dev-cycle.sh:131`, before `ROOT=` (`:132`).

**Evidence:** `scripts/dev-cycle.sh:127-136`, `scripts/lib/dev-cycle-read.sh:360`

---

## Claim 38: "git_harden and the state gate own item 2's fsmonitor and replace refs"

**Location:** `scripts/lib/dev-cycle-read.sh:70`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the renamed symbol. It does not re-check the state gate's keys.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover dev-cycle.sh, which runs no state gate". The state gate refuses replace refs (`scripts/build-loop.sh:508`)
**Legibility-target:** for-orchestrator-synthesis

`core.fsmonitor=false` and `core.useReplaceRefs=false` are in `HARDEN` (`scripts/lib/dev-cycle-read.sh:349`), and `git_harden` exists (`:351`). No `harden()` remains (paraphrased — no quote available because this is a claim about absence: grep finds no `^harden()` in scripts/).

**Evidence:** `scripts/lib/dev-cycle-read.sh:70`, `scripts/lib/dev-cycle-read.sh:349-351`

---

## Claim 39: "git_harden: every later git call in this process and its children runs hardened, but where a caller hands back its own setting on purpose (build-loop.sh's caller_gate reads the caller's count, merge_ident its global config); build-loop.sh and dev-cycle.sh call it once, after scrub_reexec and before their first git call"

**Location:** `scripts/lib/dev-cycle-read.sh:326-330`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** The same as Claims 8 and 30. It does not count the pathspec-only overrides named there.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2 (executed): children shown through questions.sh. "It does not establish children that reset their own environment (none found)" · r3: includes Claim 30's pathspec caveat
**Legibility-target:** for-orchestrator-synthesis

The call sites are `scripts/build-loop.sh:497` and `scripts/dev-cycle.sh:131`. The exceptions are `scripts/build-loop.sh:564` and `:1321` (quoted in Claim 30).

**Evidence:** `scripts/lib/dev-cycle-read.sh:326-361`, `scripts/build-loop.sh:442-497`, `scripts/dev-cycle.sh:104-132`

---

## Claim 40: "HARDEN's config pairs outrank the repo's config: main's own objects (core.useReplaceRefs there would override GIT_NO_REPLACE_OBJECTS), ... no multi-pack-index (...), no commit-graph (...), git log's own date format and no signature check (a bad log.date stops git log; log.showSignature runs gpg.program)."

**Location:** `scripts/lib/dev-cycle-read.sh:333-338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the replace-refs, log.date and showSignature reasons, executed. The hook, fsmonitor, attributes, multi-pack-index and commit-graph reasons carry over from build-loop.sh's earlier comment and were not re-run here.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the multi-pack-index and commit-graph reasons were read, not run. r2 rated it Confidence Medium
**Legibility-target:** for-orchestrator-synthesis

X7: with a replace ref and `GIT_NO_REPLACE_OBJECTS=1`, `cat-file` read `real`. With repo `core.useReplaceRefs=true` as well it read `replaced`. With a count pair `core.useReplaceRefs=false` added it read `real`. P4 covers showSignature (Claim 9). Test 20, with repo `log.date bogus`, passes with the pair in place.

**Evidence:** `scripts/lib/dev-cycle-read.sh:333-338`, `fc3r1/rr.log`, `fc3r1/probes.log` (P4), `fc3-1/probe1.log`, `fc3r3/probe.log` (P4)

---

## Claim 41: "GIT_CONFIG_GLOBAL=/dev/null and GIT_CONFIG_NOSYSTEM ... GIT_ALLOW_PROTOCOL=none: no transport, so a lazy fetch (a partial clone's missing object) fails however its config was planted."

**Location:** `scripts/lib/dev-cycle-read.sh:338-341`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers build-loop.sh's partial-clone tests and dev-cycle.sh's call log. It does not establish a partial-clone run of dev-cycle.sh itself.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2 (static, Confidence Medium): "It does not execute a lazy fetch under git_harden alone (the partial-clone test in build-loop-check.bats exercises the state gate's refusal first)" · r3: "It does not run dev-cycle.sh against a partial clone"
**Legibility-target:** for-orchestrator-synthesis

The export is at `scripts/lib/dev-cycle-read.sh:360`. build-loop-check's tests assert `[ ! -e "$BATS_TEST_TMPDIR/fetched" ] || { echo "upload-pack ran"; ...}` (`test/scripts/build-loop-check.bats:1685`, `:1729`) and pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:360`, `test/scripts/build-loop-check.bats:1685`, `test/scripts/build-loop-check.bats:1729`, `fc3r1/build-loop-check.log`

---

## Claim 42: "The caller's own pairs (git -c, GIT_CONFIG_COUNT) still apply, git -c ones after HARDEN's: CALLER_COUNT keeps the caller's count for build-loop.sh's caller_gate, which refuses a HARDEN key there by name."

**Location:** `scripts/lib/dev-cycle-read.sh:341-345`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same as Claims 6 and 32.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: a count pair outranks a repo-config `log.date=bogus` (E2 P3) · r3: "It does not establish read modes, where caller_gate does not run"
**Legibility-target:** for-orchestrator-synthesis

`CALLER_COUNT="$c"` is set before the loop (`scripts/lib/dev-cycle-read.sh:356`) and read at `scripts/build-loop.sh:564`. X1 and c1 show the precedence and the refusal.

**Evidence:** `scripts/lib/dev-cycle-read.sh:351-361`, `scripts/build-loop.sh:564`, `fc3r1/prec.log`, `fc3r1/c1.log`

---

## Claim 43: "A GIT_CONFIG_COUNT that is not plain decimal (010 reads as 8 here and as 10 to git) exits 1."

**Location:** `scripts/lib/dev-cycle-read.sh:344-346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 and bash 5.2.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "'Reads as 10 to git' is read from git's documented decimal parse, not run" · r3: "It does not trace git's own count parser in source; '10 to git' is pre-existing text". r1's P3 executed git's count (10)
**Legibility-target:** for-orchestrator-synthesis

P3: with `GIT_CONFIG_COUNT=010` and keys 0-9 set, git listed `x.k7`, `x.k8` and `x.k9`, so it counted 10. Bash's `$((c + 0))` gave 8. Sourcing the lib and calling git_harden printed "GIT_CONFIG_COUNT is not a plain decimal count", exit 1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:354`, `fc3r1/probes.log` (P3), `fc3r3/probe3.log`

---

## Claim 44: "What these cannot switch off, build-loop.sh's state gate refuses in its gated modes; dev-cycle.sh runs no state gate (row 548)."

**Location:** `scripts/lib/dev-cycle-read.sh:346-347`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which script runs a state gate. It does not establish the state gate's completeness.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "It does not enumerate the gated modes". r2 cites `GATED` excluding settings, status and marker (`scripts/build-loop.sh:608`)
**Legibility-target:** for-orchestrator-synthesis

dev-cycle.sh has no `state_gate` call (paraphrased — no quote available because this is a claim about absence: grep finds none in `scripts/dev-cycle.sh`). Row 548 is cited correctly (`docs/reviews/override-log.md:548`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:346-347`, `docs/reviews/override-log.md:548`, `scripts/build-loop.sh:608`

---

## Claim 45: "A second call returns at once: it would count HARDEN's pairs as the caller's."

**Location:** `scripts/lib/dev-cycle-read.sh:347-348`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a second call in one process. A child that sources the lib again starts with `CALLER_COUNT=""` (`:350`), but neither script starts such a child.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: a child process that re-sources the lib with the pairs already exported would count them again. No such child exists today
**Legibility-target:** for-orchestrator-synthesis

The guard is `[[ -z "$CALLER_COUNT" ]] || return 0` (`:352`). Mutant n2 removed it, and test 19 (two calls, `caller 1`, `GIT_CONFIG_COUNT=9`) went red.

**Evidence:** `scripts/lib/dev-cycle-read.sh:350-361`, `fc3r1/n2.log`, `fc3-1/mutants.log`, `fc3r3/mutants.log` (M2)

---

## Claim 46: "the one way the orchestrator runs build-loop.sh (the gate) and dev-cycle.sh (the digest). U4 puts this file, byte for byte, in skills/dev-cycle/SKILL.md, the root-owned image copy, as the body of a quoted heredoc that bash reads, so it runs the same from any login shell and defines nothing in the caller's"

**Location:** `test/lib/d6-snippet.bash:2-9`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the bash -s form working from a pipe and from stdin, defining d6 only in that bash, and the image's SKILL.md being root-owned. "The one way" and U4's paste are future conventions; they are not established.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound, its Claim 11): ran the heredoc form from `zsh -f` against the real D6_ROOT · r2: "A zsh or other login shell was not run, and U4's SKILL.md does not exist yet"
**Legibility-target:** for-orchestrator-synthesis

Q1's pipe and file-stdin runs exited 0. `ls -ln /opt/claude-workflows/skills/dev-cycle/SKILL.md` shows `-r--r--r-- 1 0 0` (paraphrased — no quote available because this is host file metadata, not repository text).

**Evidence:** `test/lib/d6-snippet.bash:2-8`, `test/lib/d6-snippet.bash:36`, `fc3r3/probe2.log` (Q1), `fc3-1/probe3.log`

---

## Claim 47: "T33 is to assert the two match once U4 writes the block (pending until then)."

**Location:** `test/lib/d6-snippet.bash:10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pending state.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3: "There is no assertion yet"
**Legibility-target:** for-orchestrator-synthesis

T33 holds only `# The SKILL.md block and test/lib/d6-snippet.bash are byte-equal (T33): pending until U4 writes the block.` (`test/scripts/build-loop-orchestrator.bats:268`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:268`

---

## Claim 48: "In claude-workflows (main's first-parent root commit is D6_ROOT) it runs main's own scripts: one perl process reads every object it uses through one cat-file --batch ... it writes the four files from those bytes into a fresh temp dir (a same-uid writer racing that 0700 dir is the Q-103 class, row 509)."

**Location:** `test/lib/d6-snippet.bash:11-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real repository: D6_ROOT is main's first-parent root, and the reader writes main's exact blobs. It does not cover the race (row 509).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound, its Claim 13): verdicted together with the plan's verified-reader text (Claims 14, 15) · r3: "It does not cover other clones of claude-workflows with rewritten roots". Q1 reported root 640cf007 and 1,122 commits
**Legibility-target:** for-orchestrator-synthesis

`git rev-list --first-parent --max-parents=0 main` gives `640cf00735754d4253819a0354fb8ca9b71a8ea7`, which equals `D6_ROOT` (`:38`). In E9 the reader printed `main`, and all four files match main's blob ids. E8 ran the whole snippet in the real repository with exit 0.

**Evidence:** `test/lib/d6-snippet.bash:38`, `test/lib/d6-snippet.bash:58-81`, `fc3-1/real-repo-reader.log`, `fc3-1/real-repo-d6.log`, `fc3r3/probe2.log` (Q1)

---

## Claim 49: "In any other repository (another root, or not SHA-1) it runs the image copy under D6_OPT, by absolute path, once those files and every directory above them are root-owned, no symlink and not writable here."

**Location:** `test/lib/d6-snippet.bash:19-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 17.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** r1 (compound, its Claim 15): covers only the narrow reading, "a repository whose main's first-parent root id is not D6_ROOT". It does not establish that a repository other than claude-workflows always takes the image copy: P6's copied root object made the snippet run that repository's planted scripts. See Escalations E1
**Legibility-target:** for-orchestrator-synthesis

See Claim 17. Test 17 asserts the output equals `bash /opt/claude-workflows/scripts/build-loop.sh --help` (`test/scripts/build-loop-orchestrator.bats:334`).

**Evidence:** `test/lib/d6-snippet.bash:82-87`, `test/scripts/build-loop-orchestrator.bats:330-344`, `fc3-1/bats-orch.log`, `fc3r1/probes.log` (P6)

---

## Claim 50: "It never reads the working tree, ~/.claude/scripts or a replaced object"

**Location:** `test/lib/d6-snippet.bash:22-23`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers working-tree file contents (T33's `exit 9` copies never run), ~/.claude/scripts (all four files are always present in the run directory, so dev-cycle.sh's `$HOME/.claude/scripts/questions.sh` fallback is never taken), and replace refs (refused, and the reader is hash-checked). It does not cover repository discovery: in a linked worktree git reads the `.git` gitfile there, which a loop that can write the tree could redirect. That route yields another repository's main, the same trusted-ref class as Claim 22.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "It does not cover what the chosen script reads afterwards: dev-cycle.sh reads the working tree by design" · r2 (static): "It does not cover git's repository discovery (which reads the checkout's `.git` entry) or the scripts it runs" · r1+r2: Confidence High · r3: the `.git` gitfile route is noted, not escalated. See Escalations E6
**Legibility-target:** for-orchestrator-synthesis

The fallback is `QS="$SCRIPT_DIR/questions.sh"; [[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"` (`scripts/dev-cycle.sh:389-390`). For /opt, `[[ -f "$d/scripts/$f" ]] || no` covers questions.sh (`test/lib/d6-snippet.bash:84`). T33 writes `exit 9` over the working tree's four files, and the runs still succeed.

**Evidence:** `test/lib/d6-snippet.bash:22-23`, `test/lib/d6-snippet.bash:84`, `scripts/dev-cycle.sh:389-390`, `fc3r3/suite.log`

---

## Claim 51: "Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout, with nothing run, for a replace ref, info/grafts, a default branch that is not exactly one plain main or master or whose ref names no commit itself, a first-parent history, tree or file that cannot be read whole or does not hash to its id (a shallow history among them), a script on main that is not a regular file, an image copy that fails the ownership checks, or a git read or temp-dir step that fails ...; 1 for another first argument."

**Location:** `test/lib/d6-snippet.bash:26-33`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Executed: replace refs, grafts, main/master, symbolic, tag, rewritten tree, rewritten commit, missing commit, shallow clone, uid-owned image copy and a bad first argument. Read, not run: "not a regular file" (perl's mode check `qr/\A100(644|755)\z/` dies on 120000/160000) and temp-dir failures.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound, its Claim 18): ran the symlink case (c1: a symlinked `scripts/questions.sh` on main gives exit 2 and a `refuse d6:` line) · r3: P3's symlink entry died with exit 255, which bash maps to `no`. "It does not exercise the mktemp and mkdir failures"
**Legibility-target:** for-orchestrator-synthesis

Every refusal goes through `no` (`:39`) before `bash "$d/scripts/$s"` (`:87`). Tests 12-15 and 18 pass. `exit "$?"` (`:88`) returns the script's own status.

**Evidence:** `test/lib/d6-snippet.bash:39-88`, `test/scripts/build-loop-orchestrator.bats:271-344`, `fc3-1/bats-orch.log`, `fc3r1/c1.log`, `fc3r3/probe.log` (P3)

---

## Claim 52: "Its git carries the lib's HARDEN pairs and git_harden's environment (G; a test pins the two lists equal)."

**Location:** `test/lib/d6-snippet.bash:33-34`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 21.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3 (compound): verdicted together with the plan's sentence (Claim 21) · r3: precedence is not pinned
**Legibility-target:** for-orchestrator-synthesis

See Claim 21: test 19's `grep -o -- '-c [^ )]*'` and `grep -o 'GIT_[A-Z_]*=[^ ]*'` over the `G=(env ` line (`test/scripts/build-loop-orchestrator.bats:358-360`).

**Evidence:** `test/lib/d6-snippet.bash:40`, `test/scripts/build-loop-orchestrator.bats:357-360`, `fc3-1/mutants.log`

---

## Claim 53: "These checks come before, not instead of, the script's own state and default-branch gates."

**Location:** `test/lib/d6-snippet.bash:34-35`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which runs have such gates. It does not establish the row-548 ruling.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r1+r3 (compound): verdicted together with the plan's sentence (Claim 13b) · r1+r2+r3: re-flag of settled row 548 · r3: "This is a text imprecision only; no behaviour change is implied". The lib's own header says "dev-cycle.sh runs no state gate (row 548)" (`scripts/lib/dev-cycle-read.sh:346`)
**Legibility-target:** for-author

This is true for build-loop.sh's gated modes. dev-cycle.sh has no state or default-branch gate, and build-loop.sh's `--settings`, `--status` and `--marker` are ungated: `GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1` (`scripts/build-loop.sh:608`). For those runs the snippet's checks are the only ones. A precise version: "before, not instead of, build-loop.sh's state and default-branch gates in its gated modes (dev-cycle.sh has none: row 548)".

**Evidence:** `test/lib/d6-snippet.bash:34-35`, `scripts/build-loop.sh:608`, `scripts/lib/dev-cycle-read.sh:565-587`

---

## Claim 54: "t stays global: the EXIT trap reads it"

**Location:** `test/lib/d6-snippet.bash:43`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `t` is not in the `local` list and is the trap's variable.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3: "It does not establish trap timing"
**Legibility-target:** for-orchestrator-synthesis

`local s="${1:-}" F x m n sha f d P` has no `t` (`:43`). The trap is `trap 'rm -rf "$t"' EXIT` (`:73`).

**Evidence:** `test/lib/d6-snippet.bash:43`, `test/lib/d6-snippet.bash:72-73`

---

## Claim 55: "It prints "main" once the four files are written, "other" when the first-parent root is not D6_ROOT; any failure dies (status 255)."

**Location:** `test/lib/d6-snippet.bash:55-57`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers outputs and exit statuses. "main" and "other" are exact. Failures exit non-zero, but not always 255. The bash side tests only non-zero, so nothing depends on the number.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: a failed `open` dies with its errno (2 observed), not 255. Behaviour is unaffected because bash refuses on any non-zero exit (`:78`). Precise text: "any failure dies (a non-zero status)" · r3: "A signal death (SIGPIPE) gives 141"
**Legibility-target:** for-author

The observed runs were `P3 other-root exit=0 out=[other]`, `P3 main exit=0 out=[main]`, and 255 for the die paths exercised. Perl's `die` exits with `$!` when `$!` is non-zero, so the `open(...) or die "$f: $!\n"` / `close(...) or die` paths (`:70`) exit with the errno (`perl -e 'open(my $f,">","/nonexistent/x") or die …'` exited 2 here). A more precise comment: "any failure exits non-zero".

**Evidence:** `test/lib/d6-snippet.bash:55-71`, `test/lib/d6-snippet.bash:78`, `fc3r3/probe.log` (P3), `fc3r1/probes.log` (P2), `fc3-1/probe2.log`

---

## Claim 56: "D6_ROOT is a SHA-1 id: a repository in another format is not claude-workflows."

**Location:** `test/lib/d6-snippet.bash:76`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the id is 40 hex. It does not establish a future SHA-256 conversion of claude-workflows (override row's revisit trigger).
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

The constant is `D6_ROOT=640cf00735754d4253819a0354fb8ca9b71a8ea7` (40 hex, `:38`), and the branch is `if [[ "$x" == sha1 ]]; … else x=other; fi` (`:77-79`).

**Evidence:** `test/lib/d6-snippet.bash:38`, `test/lib/d6-snippet.bash:76-79`

---

## Claim 57: Refusal text "main's first-parent history, the trees above scripts/lib/ or the four files could not be read whole, or an object does not hash to its id"

**Location:** `test/lib/d6-snippet.bash:78`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which objects the reader reads. The scripts/lib tree itself is also read (`entry($l, …)`), and a failure there produces the same text. The plan's "the trees down to scripts/lib/" is exact.
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** r3: "Message text only"
**Legibility-target:** for-author

The reader reads `my $l = entry($s, "lib", …)` and then `entry($t, $n, …)` with `$t = $l` for the lib file (`:68-70`), so the lib tree is read too. "The trees down to scripts/lib/" would match the code.

**Evidence:** `test/lib/d6-snippet.bash:68-70`, `test/lib/d6-snippet.bash:78`

---

## Claim 58: "Under bash -s the script is the heredoc on stdin: bash has read this whole line before it runs, and no child reads the rest of it."

**Location:** `test/lib/d6-snippet.bash:90-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pipe and regular-file stdin. It does not exercise a bash version whose heredoc is a pipe versus a temp file; both stdin kinds were run.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound, its Claim 11): ran the heredoc from `zsh -f`, and bash read no further heredoc line · r2: ran a real heredoc from bash. The script reported stdin `/dev/null`, and the caller's next line ran
**Legibility-target:** for-orchestrator-synthesis

The runs were `cat "$SN" | bash -s -- build-loop.sh --settings` (exit 0) and `bash -s -- dev-cycle.sh … < "$SN"` (exit 0, `ok README.md`). The redirect is `d6 "$@" </dev/null` (`:92`).

**Evidence:** `test/lib/d6-snippet.bash:90-92`, `fc3r3/probe2.log` (Q1), `fc3-1/probe3.log`

---

## Claim 59: "Not log.date: git_harden's log.date pair overrides it (row 505); a bad boolean still stops git log."

**Location:** `test/scripts/build-loop-check.bats:1660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers log.abbrevCommit=bogus against git 2.39.5.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "It does not cover other log.* booleans"
**Legibility-target:** for-orchestrator-synthesis

The test sets `git config log.abbrevCommit bogus` and expects the `skip ...` line (`:1661-1663`). It passes. Test 20 shows that a repo `log.date bogus` no longer stops anything.

**Evidence:** `test/scripts/build-loop-check.bats:1658-1668`, `fc3r1/build-loop-check.log`, `fc3-1/probe1.log`

---

## Claim 60: Test name "every git call --check makes carries git_harden's config pairs (core.hooksPath=/dev/null among them), no global or system config and no transport (T26, ...)"

**Location:** `test/scripts/build-loop-check.bats:1688`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3 (compound): verdicted together with the `:1699` comment (Claim 61) · r3: "It does not cover non---check modes"
**Legibility-target:** for-orchestrator-synthesis

The test asserts that no logged call lacks each HARDEN pair, `G=/dev/null`, `P=none` or `S=1` (`:1700-1702`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1688-1703`, `fc3-1/bats-check-filter.log`

---

## Claim 61: "HARDEN from the lib itself, so a key added there is checked here too."

**Location:** `test/scripts/build-loop-check.bats:1699`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop source.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3 (compound): verdicted together with the test name (Claim 60)
**Legibility-target:** for-orchestrator-synthesis

`for kv in $(bash -c 'source "$1"; echo "${HARDEN[*]}"' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh") G=/dev/null P=none S=1; do` (`:1700`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1699-1702`

---

## Claim 62: "A plain caller pair passes; a count git_harden would misread stops every mode (row 276)."

**Location:** `test/scripts/build-loop-orchestrator.bats:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts `010 08 1x " 1"` against `--settings`, as the test loops them.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: dev-cycle.sh's case is covered by X4 / Claim 35
**Legibility-target:** for-orchestrator-synthesis

`for c in 010 08 1x " 1"; do run ... bash "$BL" --settings` (`:52-53`). It passes, and X4 gives the same for dev-cycle.sh.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:50-56`, `fc3r1/build-loop-orchestrator.log`

---

## Claim 63: "d6_copy ROOT OPT: D6, a copy of test/lib/d6-snippet.bash with D6_ROOT and D6_OPT replaced. d6_setup: main holds this branch's four scripts, and D6 takes this fixture's root commit as claude-workflows' own."

**Location:** `test/scripts/build-loop-orchestrator.bats:227-229`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helpers.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3: "The `grep -qxF` guard fails the helper when the sed misses"
**Legibility-target:** for-orchestrator-synthesis

`sed "s|^  D6_ROOT=.*; D6_OPT=.*|  D6_ROOT=$1; D6_OPT=$2|" ... ; grep -qxF ...` (`:230`). d6_setup copies the four scripts and calls `d6_copy "$(git rev-list --max-parents=0 main)" /opt/claude-workflows` (`:231-234`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:227-234`

---

## Claim 64: T33: "the D6 snippet runs main's four scripts from a fresh temp dir, each with its own lib and questions.sh, never the working tree's, and removes the dir", with its comments ("The snippet exports no config pair, so --state run through it passes caller_gate (row 702)"; "A byte the reader did not hash is never used"; byte-equality "pending until U4")

**Location:** `test/scripts/build-loop-orchestrator.bats:245` (also `:257`, `:262`, `:268`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts and that it passes. Its lib-origin check covers build-loop.sh's run; dev-cycle.sh's lib origin is shown only by the exit 0 (the working tree's lib is `exit 9`). The byte-equality half is a pending comment, as stated.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: dev-cycle.sh's own lib is shown only indirectly (exit 0 with the working tree's lib set to `exit 9`) · r2+r3: the tamper sed rewrites `pipefail` in the whole `--batch` stream (r2: "the first match per line"; r3: "blobs and any other object alike")
**Legibility-target:** for-orchestrator-synthesis

The test asserts the lib path `"lib at $TMPDIR/"*/scripts/lib/dev-cycle-read.sh` (`:256`), `--state` printing `ok` (`:258`), main's questions.sh line `Q-001  trigger  from-main` (`:260`), an empty TMPDIR (`:261`, `:267`), and the tamper refusal (`:265-266`). It passes. Mutants m1 (hash check off, at a0014ce5) and m4a (working tree's script run) each turned it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:245-269`, `fc3r1/m1.log`, `fc3r1/m4a.log`, `fc3-1/mutants.log`, `fc3r3/mutants.log` (M3)

---

## Claim 65: T36: "refuses before running anything: a blob or commit replace ref, info/grafts, not exactly one plain main or master" and "git refuses to update-ref a branch to a tag: write the ref file (row 656's case)."

**Location:** `test/scripts/build-loop-orchestrator.bats:271` (also `:279`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's update-ref refusal and the test's cases.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: the symbolic and tag cases are included (the name folds them into "plain")
**Legibility-target:** for-orchestrator-synthesis

X5: `git update-ref refs/heads/x <tag>` gave "fatal: ... trying to write non-commit object ... to branch", exit 128. The test passes.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:271-284`, `fc3r1/t14.log`

---

## Claim 66: Test name "refuses the scripts/ tree rewritten in place, and runs no planted bytes (T36, U3b3 i1 A1, i2 B1)"

**Location:** `test/scripts/build-loop-orchestrator.bats:290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loose in-place rewrite.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound): verdicted together with the `:300` and `:310` test names (Claims 67, 69) · r3: "The exact stdout match excludes the planted `echo replaced` output"
**Legibility-target:** for-orchestrator-synthesis

It asserts ls-tree now sees the planted id, then that the snippet gives `A1`, exit 2 (`:291-298`). It passes. M1 turns it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:290-298`, `fc3-1/mutants.log`

---

## Claim 67: Test name "refuses a first-parent commit rewritten in place to end main's history at D6_ROOT (T36, U3b3 i1 A1)" and "the one stdout line is the snippet's"

**Location:** `test/scripts/build-loop-orchestrator.bats:300`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound): verdicted together with the `:290` and `:310` test names · r3: "It does not cover a forged middle commit (the same code path)"
**Legibility-target:** for-orchestrator-synthesis

It asserts git's rev-list root is now the fake root, then `A1` and exit 2 (`:301-307`). It passes. M1 turns it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:300-308`, `fc3-1/mutants.log`

---

## Claim 68: "git names the mismatch on stderr too; the one stdout line is the snippet's."

**Location:** `test/scripts/build-loop-orchestrator.bats:306`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stderr of the tip's snippet on this test's scenario. The test asserts nothing about stderr, so no behaviour depends on it. "The one stdout line is the snippet's" is still true.
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale
**Replicate annotations:** r1+r2+r3: true under d9515d09's snippet, whose git readers printed `error: hash mismatch`. c9648432's rewrite removed them, and now only perl's "does not hash to its id" line is on stderr. Fix: "perl (the reader) names the mismatch on stderr". Comment only · r2: `cat-file --batch` printed nothing for the rewritten loose object. See Escalations E3
**Legibility-target:** for-author

On the same scenario (a tip rewritten in place to a forged root), the tip's snippet prints only perl's line on stderr: `stderr: 8c41e52b… does not hash to its id`, with no git line. `git cat-file --batch` serves the rewritten loose object silently (`cat-file --batch exit=0 stderr=[]`). d9515d09's snippet, where the comment was added (`git log -S`), did emit git's `error: hash mismatch …` three times. The c9648432 rewrite removed the git readers that printed it. The comment should say that perl names the mismatch on stderr.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:306`, `fc3r3/probe4.log`, `fc3r3/probe5.log`, `fc3r3/probe3.log`, `fc3r1/t14.log`, `fc3r1/t14b.log`, `fc3-1/probe4.log`

---

## Claim 69: Test name "refuses, never falls to the image copy, when main's first-parent history cannot be read whole: a missing commit, a shallow clone (T36, U3b3 i2 B2)"

**Location:** `test/scripts/build-loop-orchestrator.bats:310`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both cases.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound): verdicted together with the `:290` and `:300` test names
**Legibility-target:** for-orchestrator-synthesis

It passes. M4 turns it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:310-315`, `fc3-1/mutants.log`, `fc3r1/n1.log`, `fc3r3/mutants.log` (M1)

---

## Claim 70: T27: "a gate copy patched in the loop's worktree prints ok for its tip; the D6 snippet's copy from main refuses the same tip"

**Location:** `test/scripts/build-loop-orchestrator.bats:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted ok and refuse lines.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: covers the mode-rule patch and the symlink case
**Legibility-target:** for-orchestrator-synthesis

It asserts `ok $B` from the patched copy (`:324`) and `refuse $B: 1 of 2 changed paths refused ...` through the snippet (`:326-327`). It passes.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:317-328`

---

## Claim 71: T37 name "outside claude-workflows the D6 snippet runs the image copy by absolute path, not main's copy"

**Location:** `test/scripts/build-loop-orchestrator.bats:330`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real /opt copy on this host (the test did not skip).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound): verdicted together with `:338` (Claim 72) · r3: "It does not cover hosts without one; there it skips by design"
**Legibility-target:** for-orchestrator-synthesis

It passes, not skipped. `/opt/claude-workflows` and its scripts are root-owned and `r-x` here.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:330-336`, `fc3-1/bats-orch.log`

---

## Claim 72: T37 name "outside claude-workflows the D6 snippet refuses an image copy the uid owns, and never runs main's"

**Location:** `test/scripts/build-loop-orchestrator.bats:338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertion. "Never runs main's" is shown by the exact single-line stdout: main's copy would print `main copy`.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound): verdicted together with `:330` · r3: mutant a2 (own() a no-op, at a0014ce5) turned this test red
**Legibility-target:** for-orchestrator-synthesis

It passes. M2 turns it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:338-344`, `fc3-1/mutants.log`, `fc3r1/m2.log`

---

## Claim 73: Test name "git_harden exports HARDEN's pairs after the caller's and a fixed environment, once however often it is called; the D6 snippet's git carries the same" and "The snippet cannot source the lib (it runs before anything is checked)"

**Location:** `test/scripts/build-loop-orchestrator.bats:346` (also `:357`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound): verdicted together with `:363` (Claim 74) · r3: M2 and the row-311 mutant each turn it red
**Legibility-target:** for-orchestrator-synthesis

It passes. M3 and M5 turn it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:346-361`, `fc3-1/mutants.log`, `fc3r3/probe3.log`

---

## Claim 74: Test name "every git call dev-cycle.sh makes carries git_harden's pairs: a bogus log.date stops nothing, log.showSignature runs no gpg.program"

**Location:** `test/scripts/build-loop-orchestrator.bats:363` (also `:365`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-brief` and the digest.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound): verdicted together with `:346` · r3: also covers the `:365` comment's premise (main's code ran gpg.program on the same fixture shape). "It does not cover the --check-* modes other than --check-brief". Mutant a3 turned it red
**Legibility-target:** for-orchestrator-synthesis

It passes. M3 and M6 turn it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:363-380`, `fc3-1/mutants.log`, `fc3r3/probe.log` (P1)

---

## Claim 75: Commit 9925f2a7: "Moves build-loop.sh's harden, HARDEN and its environment exports into the lib as git_harden ... HARDEN gains log.date=default ... and log.showSignature=false (git log would run gpg.program). Notes: ... a host repo that needs a global safe.directory would stop."

**Location:** commit `9925f2a7`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same as Claims 8, 9 and 34 (safe.directory simulated).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "Later commits did not change these lines' meaning" · r3: "It does not check the intermediate tree beyond the tip"
**Legibility-target:** for-orchestrator-synthesis

See Claims 8, 9 and 34 (P4, X2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:326-361`, `fc3r1/probes.log`, `fc3r1/safe.log`

---

## Claim 76: Commit a0014ce5: "In claude-workflows (main's first-parent root is 640cf007) it extracts main's four scripts into a fresh temp dir, hash-checks each against main's tree, runs that copy and removes the dir"

**Location:** commit `a0014ce5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the root id and a0014ce5's design as committed. The ids-from-ls-tree weakness is i1's A1, since superseded.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1 (compound, its Claim 52): verdicted with the T33 list and the mutants list. "It does not re-establish i1's A1, which showed this design insufficient" · r3 (compound, its Claim 65): "'hash-checks each against main's tree' describes that commit's code, since superseded by the reader"
**Legibility-target:** for-orchestrator-synthesis

The root is 640cf007 (Claim 48). At a0014ce5: `[[ "$(g hash-object --no-filters "$d/scripts/${F[i]}")" == "${ids[i]}" ]] || no ...` (`git show a0014ce5:test/lib/d6-snippet.bash`, the extraction loop).

**Evidence:** `test/lib/d6-snippet.bash:38`, `fc3-1/real-repo-reader.log`

---

## Claim 77: Commit a0014ce5: "It is a bash script body, not a function"

**Location:** commit `a0014ce5`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file's shape. The message is immutable, and the rubric already notes this (i1 A5).
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
**Replicate annotations:** r2: already noted (i1 A5). The message is immutable
**Legibility-target:** for-orchestrator-synthesis

The file defines and calls a function: `d6() {` ... `d6 "$@" </dev/null` (`test/lib/d6-snippet.bash:36`, `:92`). What holds is that no function lands in the caller's shell.

**Evidence:** `test/lib/d6-snippet.bash:36`, `test/lib/d6-snippet.bash:92`

---

## Claim 78: Commit a0014ce5: "Tests: T27 ..., T33 (own lib and questions.sh, working tree ignored, temp dir removed, a tampered extraction refused, --state passes; the SKILL.md byte-equality half waits for U4), T36, T37 (the real /opt half skips without a root-owned image copy) ... The row-307 test now breaks git log with log.abbrevCommit"

**Location:** commit `a0014ce5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a0014ce5's test file and its passing baseline.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3 (compound): verdicted together with the snippet description and (r1) the mutants list · r3: "It does not establish the zsh alias incident (Claim 12)"
**Legibility-target:** for-orchestrator-synthesis

At a0014ce5, T33 has the `--state` line (`git show a0014ce5:test/scripts/build-loop-orchestrator.bats:257-258`) and the `cat-file blob` tamper shim (`:263-264`). The a0014ce5 suite passes 17/17 (E5). T37's skip guard is `skip "no root-owned image copy at $O here"` (`test/scripts/build-loop-orchestrator.bats:332`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:332`, `fc3-1/baseline-a00.log`, `fc3r3/mutants.log` (a0)

---

## Claim 79: Commit a0014ce5: "dev-cycle.sh's calls hardened (rows 495, 505: a planted log.showSignature ran gpg.program on main)"

**Location:** commit `a0014ce5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's digest at 27cedb99 on git 2.39.5.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (compound, its Claim 8): verdicted as the same claim as the plan's (Claim 9) · r3: "It does not cover a real gpg binary"
**Legibility-target:** for-orchestrator-synthesis

E2 P4: main's dev-cycle.sh digest with `log.showSignature=true` and a gpg.program shim gave "gpg ran". The branch's gave "gpg did not run".

**Evidence:** `fc3-1/probe1.log`, `fc3r3/probe.log` (P1)

---

## Claim 80: Commit a0014ce5: "Mutants checked: hash check removed, ownership check removed, log.showSignature pair removed, main's dev-cycle.sh: each turns a test red."

**Location:** commit `a0014ce5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four mutants on an a0014ce5 archive. "main's dev-cycle.sh" was read as dev-cycle.sh without its git_harden call (main's hardening state).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** the replicates read "main's dev-cycle.sh" differently and all found it red: r1 ran both readings (m4a, the working tree's script run instead of main's; m4b, main's pre-git_harden dev-cycle.sh). r2 read it as dev-cycle.sh without its git_harden call. r3 read it as the working tree's dev-cycle.sh run instead of main's, "the reading i2 also used"
**Legibility-target:** for-orchestrator-synthesis

E5: hash check → test 11 red. Ownership → test 15 red. showSignature pair → tests 16 and 17 red. Unhardened dev-cycle.sh → test 17 red. Baseline 17/17 green.

**Evidence:** `fc3-1/mutants-a00.log`, `fc3-1/baseline-a00.log`, `fc3r1/mutants.out`, `fc3r3/mutants.log` (a1-a4)

---

## Claim 81: Commits 7a927183 and 5d175c0e (subjects only: the plan's as-built note; i1 fact-check report and rubric, short-circuited at A1)

**Location:** commit `7a927183`, commit `5d175c0e`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the subjects match the files touched. The note's content is covered by Claims 8-27.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** r1+r2 (header Scope): these two commits "carry no checkable claim beyond their subjects"
**Legibility-target:** for-orchestrator-synthesis

The rubric's first lines read `Loop-pass short-circuit: used at 7a927183` and `Loop-pass short-circuit: behavioural 🔴 confirmed at fact-check` (`docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b3.md:2-8`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b3.md:1-8`

---

## Claim 82: Commit d9515d09: "In claude-workflows it now re-hashes, in one cat-file --batch pass SHA-1'd in perl, every first-parent commit of main (which the root check walked) and the trees down to scripts/lib/."

**Location:** commit `d9515d09`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d9515d09's own code. X3 timed the whole snippet run, an upper bound on the re-hash. It does not cover i2's B1, which showed this design insufficient.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1 (compound, its Claim 53): verdicted together with the two-tests, A2 and 0.1 s sentences (Claims 83, 84)
**Legibility-target:** for-orchestrator-synthesis

d9515d09's code pipes `g rev-list --first-parent "$sha" && g rev-parse "$sha^{tree}" "$sha:scripts" "$sha:scripts/lib"` into `g cat-file --batch | perl -MDigest::SHA=sha1_hex ...` (`git show d9515d09:test/lib/d6-snippet.bash`). X6: that snippet refused test 14's tip rewrite.

**Evidence:** `fc3r1/t14b.log`, `fc3r1/time.log`

---

## Claim 83: Commit d9515d09: "Two tests: a rewritten scripts tree, and a tip rewritten to forge the root. A2: the default branch's ref must name a commit itself, not a peeled tag."

**Location:** commit `d9515d09`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tests and the ref check, which are still present.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3 (compound): verdicted together with the 0.1 s note (Claim 84)
**Legibility-target:** for-orchestrator-synthesis

The two tests are 13 and 14 (`test/scripts/build-loop-orchestrator.bats:290`, `:300`). The ref check is `[[ "$(g cat-file -t "$sha")" == commit ]]` (`test/lib/d6-snippet.bash:54`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:290-308`, `test/lib/d6-snippet.bash:54`

---

## Claim 84: Commit d9515d09: "Notes: about 0.1 s over this repository's ~1,100 first-parent commits."

**Location:** commit `d9515d09`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the commit count (1,122 now). It does not establish d9515d09's re-hash timing, which was not run.
**Replicate verdicts:** r1=Verified (compound) · r2=Unverifiable · r3=Verified (compound)
**Replicate annotations:** r1 (compound, its Claim 53): X3 ran the whole d9515d09 snippet in 0.073-0.081 s over 1,122 first-parent commits, "an upper bound on the re-hash" · r3 (compound, its Claim 68, Confidence Medium): "The 0.1 s figure was for d9515d09's re-hash and was not re-timed. The tip's whole snippet run, including --settings, took 110 ms"
**Legibility-target:** for-orchestrator-synthesis

`git rev-list --first-parent --count main` gives 1122. The current reader takes 61-63 ms (E10), which is consistent but measures a different program.

**Evidence:** `fc3-1/timing.log`, `fc3r1/time.log`, `fc3r3/probe2.log` (Q1)

---

## Claim 85: Commit c9648432: "d9515d09 re-hashed main's commits and trees through one cat-file --batch, but rev-list, rev-parse and ls-tree still chose the ids and blobs"

**Location:** commit `c9648432`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers d9515d09's file.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3 (compound, its Claim 69): verdicted with the rest of the message's fix list. "'(executed: planted bytes ran)' is i2's probe and was not re-run"
**Legibility-target:** for-orchestrator-synthesis

d9515d09's snippet: `{ g rev-list --first-parent "$sha" && g rev-parse "$sha^{tree}" "$sha:scripts" "$sha:scripts/lib"; } | g cat-file --batch` (line 53). `x="$(g ls-tree --format=... "$sha" -- "scripts/$f")"` (line 61). `g cat-file blob "${BASH_REMATCH[2]}"` (line 64).

**Evidence:** `test/lib/d6-snippet.bash:1-92` (current), d9515d09 `test/lib/d6-snippet.bash:48-64`

---

## Claim 86: Commit c9648432: "one perl process drives one cat-file --batch, uses an object only once its bytes SHA-1 to its id, and takes every next id from bytes it checked ... The two-pack probe now runs main's real scripts."

**Location:** commit `c9648432`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Same as Claims 14 and 15 (a reconstructed probe).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1 (compound, its Claim 54a): "The two-copy probe here was pack plus loose (P5), not i2's two packs" · r3 (compound, its Claim 69): i2's probe not re-run
**Legibility-target:** for-orchestrator-synthesis

See Claims 14 and 15.

**Evidence:** `test/lib/d6-snippet.bash:58-71`, `fc3-1/probe2.log`

---

## Claim 87: Commit c9648432: "B2: any read failure refuses instead of falling to the image copy (a missing commit, a shallow clone); a repository that is not SHA-1 takes the image copy. B11: one history walk instead of two."

**Location:** commit `c9648432`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 16, 2 and 3b. The non-SHA-1 branch was read, not run.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3 (compound): verdicted with the rest of the message's fix list
**Legibility-target:** for-orchestrator-synthesis

See Claims 16 and 2. The one walk is `test/lib/d6-snippet.bash:65-66`.

**Evidence:** `test/lib/d6-snippet.bash:65-79`, `fc3-1/mutants.log`

---

## Claim 88: Commit c9648432: "B4: --state's header names HARDEN's eight keys. ... B8: git_harden returns on a second call. B9: both call-log tests loop over the lib's HARDEN."

**Location:** commit `c9648432`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers B4, B8 and B9. The B5-B7, B12 and B13 text edits are covered by the claims above.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3 (compound): verdicted with the rest of the message's fix list
**Legibility-target:** for-orchestrator-synthesis

B4 is Claim 28. B8 is Claim 45. B9: `test/scripts/build-loop-check.bats:1700` and `test/scripts/build-loop-orchestrator.bats:377` both use `$(bash -c 'source "$1"; echo "${HARDEN[*]}"' ...)`.

**Evidence:** `scripts/build-loop.sh:134-137`, `scripts/lib/dev-cycle-read.sh:352`, `test/scripts/build-loop-check.bats:1700`, `test/scripts/build-loop-orchestrator.bats:377`

---

## Claim 89: Commit c9648432: "B10: store_check and the snippet's reader name each other."

**Location:** commit `c9648432`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the snippet's text at c9648432 and at the tip, which are identical (`git diff c9648432 5583a2cd` touches only docs/reviews/). Only store_check names the snippet.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: the message is immutable, so the fix belongs in the snippet's comment or header (via Claim 26b) · r3: "The rubric's B10 'Fixed (cross-reference comments)' rests on this". The fix is a comment in the snippet, or rubric/plan text saying the reference is one-way · r2: `git log -p main..5583a2cd -- test/lib/d6-snippet.bash | grep -i store_check` has only the commit-message hit · r2+r3: a candidate hallucination-pattern entry. See Escalations E2, E7
**Legibility-target:** for-author

See Claim 26b. `git diff d9515d09 c9648432 -- test/lib/d6-snippet.bash | grep -i store` is empty, so the B10 change added no reference on the snippet's side. The rubric's B10 "Fixed (cross-reference comments)" rests on this. The commit message cannot be changed. The fix is a comment in the snippet, or rubric/plan text saying the reference is one-way.

**Evidence:** `scripts/build-loop.sh:928-930`, `test/lib/d6-snippet.bash:55-57`

---

## Claim 90: Commit c9648432: "Mutants: no refusal on a failed read (B2 test red); git_harden called twice (environment test pins one count)."

**Location:** commit `c9648432`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two mutants as this pass built them (n1: `|| x=other`; n2: the guard removed).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: run on 5583a2cd, "which has the same code as c9648432". M4 also turned tests 11, 13 and 14 red · r3 (compound, its Claim 71): verdicted together with "Suites: 285/285" (Claim 91)
**Legibility-target:** for-orchestrator-synthesis

M: an unmutated c0 run was 10/10 ok. n1 failed test "refuses, never falls to the image copy", and n2 failed "git_harden exports ...".

**Evidence:** `fc3r1/mutants.out`, `fc3r1/n1.log`, `fc3r1/n2.log`, `fc3-1/mutants.log`, `fc3r3/mutants.log` (M1, M2)

---

## Claim 91: Commit c9648432: "Suites: 285/285."

**Location:** commit `c9648432`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the seven suites S1 ran. The commit names no suite set, so 285 could not be matched to one.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Verified (compound)
**Replicate annotations:** r1: matches the logged pattern class of test-tally claims ("mode1-equiv 33 ... holds 25"), "but nothing here shows the number is wrong rather than taken over a different set" · r2 (static, Confidence Low): `bats --count` over the build-loop-*.bats and dev-cycle.bats suites gives 281. Adding fixture-git-env (2) and utility-smoke (2) would make 285 · r3 (compound with the mutants sentence, its Claim 71): "285 = orchestrator 20 + check 146 + dispatch 4 + merge 12 + read 20 + dev-cycle 79 + hermeticity 2 + git-env 2, all ok at 5583a2cd, whose code equals c9648432's. Other repository suites were not run". The three replicates summed the 285 over different suite sets
**Legibility-target:** for-orchestrator-synthesis

S1: build-loop-orchestrator, build-loop-check, build-loop-read, build-loop-dispatch, build-loop-merge, dev-cycle and fixture-git-env gave 283/283 green. The code is unchanged between c9648432 and 5583a2cd (docs only). To verify, the commit would need to name its suites.

**Evidence:** `fc3r1/suites.ts`, `fc3r1/*.log`, `fc3r3/suite.log`, `fc3r3/suite2.log`

---

## Claim 92: Commit 5583a2cd: "U3b3 iteration 2: reports, rubric, seven override rows"

**Location:** commit `5583a2cd`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row count.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: also covers the file list (the four i2 critic reports, the i2 fact-check report and the rubric's iteration-2 section)
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/override-log.md:732-738` are the seven added rows tagged `feat/build-loop-u3b3`.

**Evidence:** `docs/reviews/override-log.md:732-738`

---

## Claims Requiring Attention

### Incorrect
- **Claim 26b** (`docs/working/plan-build-loop-handoff.md:326`): "each comment names the other". Only store_check's comment names the snippet. The snippet never names store_check. Add the reference in `test/lib/d6-snippet.bash:55-57`, or reword the note. Comment/doc. All three replicates said Incorrect.
- **Claim 89** (commit c9648432): "B10: store_check and the snippet's reader name each other". The same gap. The message is immutable, so fix it via Claim 26b. The rubric's B10 "Fixed" rests on this. All three replicates said Incorrect.

### Stale
- **Claim 68** (`test/scripts/build-loop-orchestrator.bats:306`): "git names the mismatch on stderr too". That was true under d9515d09. Under the verified reader only perl writes to stderr. Comment only. All three replicates said Stale.

### Mostly Accurate
- **Claim 3a** (`docs/reviews/override-log.md:734`): "~70 ms of fixed fork overhead". It measures ~80-100 ms here, about 60 ms of it the reader's walk, which is linear in main's first-parent history. Doc.
- **Claim 3b** (`docs/reviews/override-log.md:734`): "history walks from two to one". The verdict comes from r2's compound claim with 3a, and r2's text says "'One walk' holds". r1 and r3 said Verified. Doc.
- **Claim 13a** (`docs/working/plan-build-loop-handoff.md:326`): the ordered check list. The verdict comes from r1's compound claim with 13b, and r1's text says "The order matches the code". r2 and r3 said Verified.
- **Claim 13b** (`docs/working/plan-build-loop-handoff.md:326`): "left to the script's default_gate" and "before, not instead of" hold only in build-loop.sh's gated modes. dev-cycle.sh has no such gate (row 548, settled). Comment/doc.
- **Claim 53** (`test/lib/d6-snippet.bash:34-35`): the same scope gap as 13b. Comment.
- **Claim 55** (`test/lib/d6-snippet.bash:57`): "any failure dies (status 255)". A failed open exits with its errno (2 observed), and a signal death exits with 128+n. Say "non-zero". Comment only. The bash side is unaffected.
- **Claim 57** (`test/lib/d6-snippet.bash:78`): the refusal says "the trees above scripts/lib/", but the reader also reads the scripts/lib tree itself ("down to"). Message text only. r3 alone.
- **Claim 77** (commit a0014ce5): "a bash script body, not a function". Already noted (i1 A5), and the message is immutable. r2 alone.

### Unverifiable
- **Claim 12** (plan :326; a0014ce5): the zsh alias `g` incident needs the authoring session's transcript.
- **Claim 18** (plan :326): "the -w test makes a root run refuse" needs a uid-0 run.
- **Claim 84** (commit d9515d09): the ~0.1 s re-hash timing was not re-timed. The commit count (1,122) holds. r1 and r3 (compound) said Verified.
- **Claim 91** (commit c9648432): "Suites: 285/285". The commit does not name its suite set. r3 (compound) reproduced 285/285 over eight suites. r1 got 283/283 over seven, and r2 counted 281 plus two candidate suites.

## Re-flagged settled decisions
- Claims 13b and 53: dev-cycle.sh runs no state or default-branch gate, and its resolve_main follows origin/HEAD (row 548). Raised by r1, r2 and r3.
- Claims 1 and 22: a moved refs/heads/main (row 732, Won't-Fix). Raised by r2.
- Claim 24: a racer on the 0700 extraction dir (rows 200 and 509). Raised by r1 and r2.
- Claim 14: a commit header with a late `parent` line, which perl and git read differently, needs a main the loop has moved (row 732's class). Raised by r1.

## Escalations

- **E1** · `test/lib/d6-snippet.bash:67` (`if ($c ne $root) { print "other\n"; exit 0 }`) · raised by r1 · addressee: **security-reviewer** (r1 also names the orchestrator). The snippet decides "claude-workflows or not" from main's first-parent root id alone. P6 copied 640cf007's commit object into an unrelated repository and pointed main at a commit with that parent and planted scripts. The snippet ran the planted `build-loop.sh` (exit 0), not the root-owned /opt copy. This needs a loop that moves main, which is row 732's Won't-Fix class. But row 732 and the plan note describe a moved main "on top of the real history" in claude-workflows. In every other project the same move defeats the image copy's ownership checks, which exist for exactly those projects. r1 asks to confirm that row 732 covers this, or to route it (for example, require the D6_ROOT path only when the repository also passes some non-forgeable test, or record the residual). This sits on Claims 1, 17 and 49.
- **E2** · `test/lib/d6-snippet.bash:55-57` (also `:1-35`), `docs/working/plan-build-loop-handoff.md:326`, the rubric's B10 row · raised by r2+r3 · addressee: **author** (no critic named, so **orchestrator** routes it). B10 is half done: the snippet never names store_check. Name it in the snippet, or reword the plan note and the rubric's B10 row. Text fix only (Claims 26b, 89).
- **E3** · `test/scripts/build-loop-orchestrator.bats:306` · raised by r2+r3 · addressee: **author** (no critic named, so **orchestrator** routes it). Stale stderr comment (Claim 68). Nothing behavioural.
- **E4** · `test/lib/d6-snippet.bash:34-35`, `:57`, `:78` · raised by r3 · addressee: **author** (no critic named, so **orchestrator** routes it). Text-only tightenings (Claims 53, 55, 57).
- **E5** · `test/lib/d6-snippet.bash:65-66` (the perl reader's `/^parent ([0-9a-f]{40})$/m`) · raised by r1 (as a re-flag note), r2 and r3 (each an Out-of-scope hand-off) · addressee: **security-reviewer**. The security judgement of perl's parent parse is open. Perl takes the first `^parent` line anywhere in the header, and git only the lines after `tree`. This matters only for a malformed but hash-valid commit already in main's first-parent history. r1 and r3 reduce it to the moved-main / trusted-ref class (rows 509, 732). r3 notes it but does not escalate it (Claim 14).
- **E6** · `test/lib/d6-snippet.bash:22-23` (repository discovery through a linked worktree's `.git` gitfile) · raised by r3 (an Out-of-scope hand-off) · addressee: **security-reviewer**. A loop that can write the tree could redirect the gitfile to another repository's main. r3 reduces this to the trusted-ref class of row 509 / the moved-main row, noted but not escalated (Claim 50).
- **E7** · `docs/reviews/hallucination-patterns.md` · raised by r2+r3 · addressee: **orchestrator**. Decide whether to log a new pattern: a fix claimed as a two-way cross-reference whose second half does not exist (Claims 26b, 89). None of the replicates edited the log, because each was allowed to write only its own report.

## Verdict stability

- **Total clusters:** 95 (sub-claim rows counted separately).
- **Clusters where all reporting replicates agreed:** 90. Seven of them were verdicted by one replicate only (Claims 26a, 27, 56, 57, 77, 81, 82), and eight by two (Claims 7, 23, 31, 47, 49, 54, 63, 85).
- **Clusters where verdicts disagreed:** 5
  - Claim 3a (override row 734, "~70 ms of fixed fork overhead"): r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Verified (compound)
  - Claim 3b (override row 734, "walks from two to one"): r1=Verified · r2=Mostly accurate (compound) · r3=Verified (compound)
  - Claim 13a (plan, ordered check list): r1=Mostly accurate (compound) · r2=Verified · r3=Verified
  - Claim 84 (d9515d09, "about 0.1 s"): r1=Verified (compound) · r2=Unverifiable · r3=Verified (compound)
  - Claim 91 (c9648432, "Suites: 285/285"): r1=Unverifiable · r2=Unverifiable · r3=Verified (compound)
- **Agreement rate:** 90/95 = 94.7%. Over the 80 clusters that all three replicates verdicted: 75/80 = 93.8%.
- All five disagreements involve a compound verdict, and none touches the blocking channel. Every Incorrect and Stale cluster (26b, 89, 68) was unanimous across r1, r2 and r3.
- Per-replicate claim totals: r1 59, r2 87, r3 74 (each replicate's own header count).
