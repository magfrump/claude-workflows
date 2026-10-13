Commit: 5583a2cd

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b3 (branch `feat/build-loop-u3b3`)
**Scope:** branch diff `main...5583a2cd` (final confirming pass, iteration 3 of 3, replicate r3 of k=3): `docs/working/plan-build-loop-handoff.md` (U3b3 as-built note), `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `test/lib/d6-snippet.bash`, `test/scripts/build-loop-check.bats`, `test/scripts/build-loop-orchestrator.bats`, the seven override rows added to `docs/reviews/override-log.md`, and the messages of 9925f2a7, a0014ce5, 7a927183, d9515d09, 5d175c0e, c9648432, 5583a2cd
**Checked:** 2026-10-12
**Replication:** k=3, this file is replicate r3
**Total claims checked:** 74
**Summary:** 66 verified, 3 mostly accurate, 1 stale, 2 incorrect, 2 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`). No claim matches a logged pattern. Claims 19 and 70 say a cross-reference comment exists that does not exist. That may count as a new pattern, but the brief lets me write only this file, so the log is not edited. The orchestrator decides.

## Execution provenance (shared by the claims below)

Every probe was a script under `/tmp/claude-1000/-workspace/c69d4d0f-5190-473b-ba2f-85b5a43f49ee/scratchpad/fc3r3/`. Each one started with `set -eu`, created its own `mktemp -d /tmp/u3b3-fc3r3-*` directory, checked `pwd -P` before writing anything, set HOME and TMPDIR inside that directory, and deleted it at the end. Afterwards `ls /tmp | grep u3b3-fc3r3` was empty. The review worktree was never written; mutants ran in `git archive` copies. Times are UTC on 2026-10-13, which is 2026-10-12 local. Tools: git 2.39.5, perl v5.36.0, uid 1000.

| ID | Command | cwd | Exit | Time | Output |
|---|---|---|---|---|---|
| S1 | `suite.sh`: `bats test/scripts/build-loop-orchestrator.bats`, then `bats test/scripts/build-loop-check.bats` (LC_ALL=C, own TMPDIR) | worktree | 0 / 0 | 01:52:37–01:54:02 | `fc3r3/suite.log` (20/20 and 146/146 ok; T37's real-/opt test ran, not skipped) |
| S2 | `suite2.sh`: bats dispatch, merge, read, dev-cycle, fixture-hermeticity, fixture-git-env | worktree | 0 each | 01:55:46–01:57:13 | `fc3r3/suite2.log` (119/119 ok) |
| P | `probe.sh`: main's vs the tip's dev-cycle.sh under a planted log.showSignature/gpg.program (P1) and log.date bogus (P2); a non-decimal count (P6); a global safe.directory with `GIT_TEST_ASSUME_DIFFERENT_OWNER=1` (P7); core.useReplaceRefs (P4); -c vs count precedence (P5); the verified reader run alone (P3) | own temp | 0 | 01:57:04 | `fc3r3/probe.log` |
| M | `mutants.sh`: control and mutants of 5583a2cd (M0–M3) and a0014ce5 (a0–a4), filtered bats, plus P7's message | own temp | 0 | 01:57:34 | `fc3r3/mutants.log` |
| Q | `probe2.sh`: the shipped snippet on a `--no-hardlinks` clone of /workspace main (Q1, file, pipe `bash -s` and file-stdin `bash -s`); a packed real plus a forged loose copy of the scripts tree (Q2); caller_gate on the new keys (Q3) | own temp | 0 | 01:59:40 | `fc3r3/probe2.log` |
| R | `probe3.sh`: `$((010))`; `cat-file --batch` stderr on a commit rewritten in place; the row-311 mutant (GIT_NO_REPLACE_OBJECTS dropped from git_harden) | own temp | 0 | 02:01:38 | `fc3r3/probe3.log` |
| U | `probe4.sh` (the tip's snippet) and `probe5.sh` (d9515d09's snippet) on a tip commit rewritten in place: stdout, stderr | own temp | 0 / 0 | ~02:01:56 / ~02:02:13 (file mtimes) | `fc3r3/probe4.log`, `fc3r3/probe5.log` |

---

## Claim 1: "`git_harden` (lib) holds HARDEN, CALLER_COUNT and the environment build-loop.sh exported ... build-loop.sh and dev-cycle.sh call it after scrub_reexec, before their first git call; a second call returns at once."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what git_harden sets, the order of the call in both scripts and the second-call return. It does not establish that no later call site overrides a setting (Claims 22 and 29 cover the exceptions).
**Legibility-target:** for-orchestrator-synthesis

The function body is `[[ -z "$CALLER_COUNT" ]] || return 0` … `export GIT_CONFIG_COUNT="$c" GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none` (`scripts/lib/dev-cycle-read.sh:351-361`, read to the closing brace). This is the export line removed from build-loop.sh. In build-loop.sh the order is `source "$READ_LIB"` / `scrub_reexec "${BASH_SOURCE[0]}" "$@"` (`scripts/build-loop.sh:442-443`), then the mode `case`, which runs no git (`:445-488`), then `git_harden` (`:497`). In dev-cycle.sh it is `source`/`scrub_reexec` (`scripts/dev-cycle.sh:103-104`), then the argument loop, then `git_harden` (`:131`), then the first git call, `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"` (`:132`). The lib runs no git at source time (paraphrased — no quote available because this is an absence claim: an awk pass over the lib's top-level, non-function lines found no git call). Mutant M2 deleted the return line, and the environment test went red (`fc3r3/mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:351-361`, `scripts/build-loop.sh:442-497`, `scripts/dev-cycle.sh:103-132`, `fc3r3/mutants.log` (M2)

---

## Claim 2: "HARDEN gains `log.date=default` (row 505: a bogus log.date stopped --check-brief) and `log.showSignature=false` (a planted one made the digest's git log run gpg.program on main); caller_gate refuses both keys by name with the rest."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's behaviour before the change and the tip's after, for the digest and --check-brief, and caller_gate's refusal of the two keys through GIT_CONFIG_PARAMETERS. It does not establish other git log config keys (only log.abbrevCommit is used elsewhere, Claim 49).
**Legibility-target:** for-orchestrator-synthesis

`HARDEN=(... log.date=default log.showSignature=false)` (`scripts/lib/dev-cycle-read.sh:349`). Probe P1 ran the digest: `P1 main exit=0 gpg-ran=yes` and `P1 head exit=0 gpg-ran=no`. Probe P2 ran --check-brief: `P2 main exit=128 out=[] … fatal: unknown date format bogus` and `P2 head exit=0 out=[ok docs/working/briefs/2026-10-01-x.md open …]` (`fc3r3/probe.log`). caller_gate loops over HARDEN: `for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done` (`scripts/build-loop.sh:567`). Q3 refused both keys, whatever the value: `Q3 git -c log.date=default: exit=2 out=[refuse state log.date: …`, `log.showSignature=false: exit=2 … refuse state log.showsignature`, `log.date=iso: exit=2` (`fc3r3/probe2.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:349`, `scripts/build-loop.sh:559-573`, `fc3r3/probe.log` (P1, P2), `fc3r3/probe2.log` (Q3)

---

## Claim 3: "dev-cycle.sh now reads no user or system git config and no transport (its header says so)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the global/system config through the exported variables (every logged call carries G=/dev/null and S=1) and the safe.directory effect, with ownership simulated by git's `GIT_TEST_ASSUME_DIFFERENT_OWNER`. It does not establish a real lazy fetch failing under dev-cycle.sh itself (that mechanism is executed for --check, Claim 34) or a repository truly owned by another uid.
**Legibility-target:** for-orchestrator-synthesis

The export is `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none` (`scripts/lib/dev-cycle-read.sh:360`). Test 20 of S1 logs every git call dev-cycle.sh makes, through a PATH shim, and requires `G=/dev/null P=none S=1` on each one: `ok 20 every git call dev-cycle.sh makes carries git_harden's pairs …` (`fc3r3/suite.log`). P7: `P7 main exit=0` against `Not inside a git repository` / `P7 head exit=1` under a global `safe.directory = *` (`fc3r3/probe.log`, `fc3r3/mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:360`, `test/scripts/build-loop-orchestrator.bats:363-380`, `fc3r3/suite.log`, `fc3r3/probe.log` (P7), `fc3r3/mutants.log`

---

## Claim 4a: "`test/lib/d6-snippet.bash` is a script bash reads, not a function pasted into the caller's shell (its `d6` function lives only in that bash) ... U4's SKILL.md feeds the file, byte for byte, to `bash -s -- SCRIPT ARG... <<'D6'`, and the snippet runs everything with stdin from /dev/null."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file run as bash's script from a pipe and from a file on stdin, and the /dev/null stdin for everything d6 runs. It does not establish U4's SKILL.md block, which is not written yet.
**Legibility-target:** for-orchestrator-synthesis

The last line is `d6 "$@" </dev/null` (`test/lib/d6-snippet.bash:92`), and `d6()` is defined at `:36`. Q1 ran `cat "$SN" | bash -s -- build-loop.sh --settings` (exit 0, the settings line printed) and `bash -s -- dev-cycle.sh --check-path README.md < "$SN"` (`exit=0 out=[ok README.md]`) (`fc3r3/probe2.log`).

**Evidence:** `test/lib/d6-snippet.bash:36`, `test/lib/d6-snippet.bash:92`, `fc3r3/probe2.log` (Q1)

---

## Claim 4b: "the Bash tool's shell can be zsh (an alias `g` broke a pasted function)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that this session's environment declares zsh as the shell. It does not establish the alias incident.
**Legibility-target:** for-orchestrator-synthesis

The environment block of this session says `Shell: zsh`, and an `echo ====` in this session failed with zsh's `=cmd` expansion (paraphrased — no quote available because the evidence is session metadata, not repository text). The incident in which an alias `g` broke a pasted function would need the authoring session's transcript.

**Evidence:** `docs/working/plan-build-loop-handoff.md:326`

---

## Claim 5: "Checks, in order: no replace ref, no info/grafts, exactly one of refs/heads/main and master, not symbolic, its ref's own object a commit (not peeled from a tag; origin/HEAD is left to the script's default_gate)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order and each refusal. It does not establish origin/HEAD handling beyond its absence from the snippet.
**Legibility-target:** for-orchestrator-synthesis

The checks appear in this order at `test/lib/d6-snippet.bash:47-54`: `for-each-ref … refs/replace/`, `--git-path info/grafts`, the `for n in main master` count, `! g symbolic-ref -q`, and `sha="$(g rev-parse --verify -q "refs/heads/$m")" && [[ "$(g cat-file -t "$sha")" == commit ]]`, with no `^{commit}` peel. T36 (`ok 12`, S1) pins every refusal string, the annotated-tag case included.

**Evidence:** `test/lib/d6-snippet.bash:47-54`, `test/scripts/build-loop-orchestrator.bats:271-284`, `fc3r3/suite.log`

---

## Claim 6: "the verified reader ... one perl process drives one `git cat-file --batch`, uses an object only once its bytes SHA-1 to its id, and takes every next id from bytes it has checked: main's first parents to the root, and, when the root is D6_ROOT, the trees down to `scripts/lib/` and the four files, written from those bytes into one `mktemp -d`."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the id flow inside the perl program and the SHA-1 gate. The gate is test-pinned: mutant M3 removed it and three tests went red. It does not establish that perl's parse of a commit header matches git's on malformed but hash-valid objects. The first `^parent` line is taken with `/m`. A parent id that is not 40 lowercase hex reads as a root, which fails toward the root-owned image copy.
**Legibility-target:** for-orchestrator-synthesis

`open2(my $r, my $w, @git, "cat-file", "--batch")` is the only git process the program starts (`test/lib/d6-snippet.bash:59`). `obj` returns `$b` only after `die "$id does not hash to its id\n" unless sha1_hex("$t $s\0$b") eq $id` (`:60-62`). The walk sets `$c = $p` from `my ($p) = $hd =~ /^parent ([0-9a-f]{40})$/m` over checked bytes (`:65-66`), and the tree comes from the tip's checked bytes (`$tree //= … /\Atree ([0-9a-f]{40})\n/`). `entry` returns `unpack("H*", $id)` from a checked tree (`:63-64`). Files are written `print $fh $b` from `obj(…, "blob")` (`:69-70`, read to `print "main\n";'` at `:71`). The start id `$sha` is the ref itself (Claim 14). Results: M3, with the SHA-1 gate removed, turned T33, the tree-rewrite test and the commit-rewrite test red (`fc3r3/mutants.log`). P3 found the four files through a tree holding a name with a newline and wrote exactly their bytes (`P3 main exit=0 out=[main] … wrote=[echo build-loop.sh echo lib/dev-cycle-read.sh ]`), and a symlink entry for one file died (`fc3r3/probe.log`).

**Evidence:** `test/lib/d6-snippet.bash:58-71`, `test/lib/d6-snippet.bash:78`, `fc3r3/mutants.log` (M0, M3), `fc3r3/probe.log` (P3)

---

## Claim 7: "No other reader (rev-list, ls-tree) decides what runs, so a second copy of an object, packed or loose, cannot either (i2 B1's two-pack forgery now runs main's real scripts; a forged copy read would refuse)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the absence of other deciding readers, plus an executed packed-real/loose-forged second copy and the in-place forged reads (T36, T33's tampered stream). It does not rebuild i2's exact two-pack layout. Which copy cat-file returns there is git's choice; either outcome is covered (real runs, forged refuses).
**Legibility-target:** for-orchestrator-synthesis

The git calls outside perl are only the ref and refusal checks at `test/lib/d6-snippet.bash:47-54` and `rev-parse --show-object-format` (`:75`). None of them yields an id that perl reads (paraphrased — no quote available because this is an absence claim over the function's git calls, all read). Q2 packed the real scripts tree and planted a loose copy of the same id holding a forged tree: `Q2 packed-real/loose-forged exit=0 … replaced=0` (`fc3r3/probe2.log`). The forged-read refusals are `ok 11`, `ok 13`, `ok 14` in S1.

**Evidence:** `test/lib/d6-snippet.bash:47-78`, `fc3r3/probe2.log` (Q2), `fc3r3/suite.log`

---

## Claim 8: "Any read failure refuses, never falls to the image copy (i2 B2: a missing first-parent commit, a shallow clone)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a perl failure of any status and the "gave no answer" fallthrough. It does not establish the refusal when another process kills perl and bash still sees status 0, which is not a reachable path.
**Legibility-target:** for-orchestrator-synthesis

`x="$(LC_ALL=C perl -e "$P" …)" || no "$m's first-parent history, …"` and `else no "the verified reader gave no answer"; fi` (`test/lib/d6-snippet.bash:78`, `:86`). In S1, `ok 15 … never falls to the image copy …` passed. Mutant M1 replaced the refusal with `x=other`, and the same test went red (`not ok 1 … never falls to the image copy`, `fc3r3/mutants.log`). That matters here because a root-owned /opt copy exists on this host.

**Evidence:** `test/lib/d6-snippet.bash:77-86`, `test/scripts/build-loop-orchestrator.bats:310-315`, `fc3r3/mutants.log` (M1)

---

## Claim 9: "Another root, or a repository that is not SHA-1, runs `D6_OPT/scripts/SCRIPT` once the four files are regular, root-owned (`stat -c %u`), not symlinks and not writable (`-w`), and so is every directory from `scripts/lib` up to `/`"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "other" output, the not-SHA-1 branch (`else x=other`) and the ownership walk. It does not execute a SHA-256 repository.
**Legibility-target:** for-orchestrator-synthesis

The ownership check is `own() { [[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no …; }` (`test/lib/d6-snippet.bash:42`). The loop is `for f in "${F[@]}"; do own "$d/scripts/$f"; [[ -f "$d/scripts/$f" ]] || no …; done` and the walk is `x="$d/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done` (`:84-85`). In S1, both T37 tests passed against the real root-owned `/opt/claude-workflows` (mode 555), and the uid-owned copy was refused. In P3, a foreign root printed `other` with exit 0.

**Evidence:** `test/lib/d6-snippet.bash:42`, `test/lib/d6-snippet.bash:79-85`, `fc3r3/suite.log`, `fc3r3/probe.log` (P3)

---

## Claim 10: "(the `-w` test makes a root run refuse unless the mount is read-only)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the reading of `! -w`. It does not establish the root behaviour, which needs uid 0 (blocker: this session runs as uid 1000).
**Legibility-target:** for-orchestrator-synthesis

The test is `! -w "$1"` inside `own` (`test/lib/d6-snippet.bash:42`). For uid 0, bash's `-w` is true on a writable mount, so own would refuse (paraphrased — no quote available because this is bash/kernel access() semantics, not repository code). Verifying it needs a root run.

**Evidence:** `test/lib/d6-snippet.bash:42`

---

## Claim 11: "The run has BASH_ENV, ENV and DEV_CYCLE_SCRUBBED unset; the temp dir is removed on exit."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the env command and the EXIT trap on the success, refusal and tamper paths T33 runs. It does not establish removal when bash itself is killed by SIGKILL.
**Legibility-target:** for-orchestrator-synthesis

The run line is `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"` and the trap is `trap 'rm -rf "$t"' EXIT` (`test/lib/d6-snippet.bash:87`, `:73`). T33 asserts `[ -z "$(ls -A "$TMPDIR")" ]` after runs and after the tampered refusal (`test/scripts/build-loop-orchestrator.bats:261`, `:267`; ok in S1). Q1 found `temp dirs left: 0`.

**Evidence:** `test/lib/d6-snippet.bash:72-73`, `test/lib/d6-snippet.bash:87-88`, `fc3r3/suite.log`, `fc3r3/probe2.log`

---

## Claim 12: "Refusal: one `refuse d6: WHY` line on stdout and exit 2, nothing run (git or perl may add a stderr line); exit 1 for another first argument."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `no` call site and the usage exit. It does not establish the stderr content of each git failure.
**Legibility-target:** for-orchestrator-synthesis

The refusal is `no() { echo "refuse d6: $*"; exit 2; }` and the usage exit is `{ echo "d6: the first argument is build-loop.sh or dev-cycle.sh" >&2; exit 1; }` (`test/lib/d6-snippet.bash:39`, `:44`). `d6_is` requires the exact single stdout line, status 2 and empty stderr (`test/scripts/build-loop-orchestrator.bats:237`). The test at `:283` requires status 1 for argument `x`. Both pass in S1.

**Evidence:** `test/lib/d6-snippet.bash:39-44`, `test/scripts/build-loop-orchestrator.bats:237`, `test/scripts/build-loop-orchestrator.bats:283`, `fc3r3/suite.log`

---

## Claim 13: "Its git carries HARDEN as `-c` and git_harden's variables (G), a test pins the lists equal (the snippet cannot source the lib before checking it)." (also the header: "Its git carries the lib's HARDEN pairs and git_harden's environment (G; a test pins the two lists equal)")

**Location:** `docs/working/plan-build-loop-handoff.md:326`; `test/lib/d6-snippet.bash:33-34`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers list equality: the lib's HARDEN and the snippet's `-c` list, both equal to the test's H; git_harden's environment and G's variables, both equal to E. It does not pin precedence (row "opposite precedence", Claim 73).
**Legibility-target:** for-orchestrator-synthesis

G is `G=(env GIT_NO_REPLACE_OBJECTS=1 … GIT_ATTR_NOSYSTEM=1 git -c core.useReplaceRefs=false … -c log.showSignature=false)` (`test/lib/d6-snippet.bash:40`). The test compares `printf "pair %s\n" "${HARDEN[@]}"` and `env | grep "^GIT_"` against H/E, then compares G's `-c` list to `"$H "` and G's variables to `"$E "` (`test/scripts/build-loop-orchestrator.bats:348-360`). `ok 19` in S1.

**Evidence:** `test/lib/d6-snippet.bash:40`, `test/scripts/build-loop-orchestrator.bats:346-361`, `fc3r3/suite.log`

---

## Claim 14: "The snippet trusts refs/heads/main itself: a moved main is F19's class (--main-log reports an honest slip, not a forger; rows 509, 721, and this unit's row)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the start id is the ref and that the cited rows exist and say this. It does not rule on Q-103.
**Legibility-target:** for-orchestrator-synthesis

The start id is `sha="$(g rev-parse --verify -q "refs/heads/$m")"` (`test/lib/d6-snippet.bash:54`). The new row reads "The snippet trusts refs/heads/main itself … Won't-Fix | The hostile-loop class F19 names: D13's --main-log catches an honest slip, not a forger (rows 509, 721)" (`docs/reviews/override-log.md`, the first 2026-10-12 `feat/build-loop-u3b3` row). Row 721 reads "D13's check catches an honest slip … not a forger" (`docs/reviews/override-log.md:721`).

**Evidence:** `test/lib/d6-snippet.bash:54`, `docs/reviews/override-log.md:509`, `docs/reviews/override-log.md:721`

---

## Claim 15: "These checks come before, not instead of, the script's own state and default-branch gates."

**Location:** `docs/working/plan-build-loop-handoff.md:326`; `test/lib/d6-snippet.bash:34-35`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers build-loop.sh's gated modes, where state_start/default_gate run after the snippet. It does not hold for dev-cycle.sh, which runs neither gate (row 548, settled), or for build-loop.sh's ungated read modes. This is a text imprecision only; no behaviour change is implied.
**Legibility-target:** for-author

dev-cycle.sh contains no `state_gate` or `default_gate` call (paraphrased — no quote available because this is an absence claim: `grep -n 'state_gate\|default_gate' scripts/dev-cycle.sh` returns nothing). The lib's own header says so: "dev-cycle.sh runs no state gate (row 548)" (`scripts/lib/dev-cycle-read.sh:346`). A more precise wording: "before, not instead of, build-loop.sh's own state and default-branch gates in its gated modes (dev-cycle.sh runs neither: row 548)".

**Evidence:** `test/lib/d6-snippet.bash:34-35`, `scripts/lib/dev-cycle-read.sh:345-346`, `docs/reviews/override-log.md:548`

---

## Claim 16: "**U4 hand-offs** ... route the orchestrator's own git reads through a script mode run by the snippet (git_harden is no shell wrapper: row 704 amended) ...; call --state through the snippet, which exports no pair (row 702)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the amending row exists and that --state through the snippet passes. It does not establish U4, which is not written.
**Legibility-target:** for-orchestrator-synthesis

The new row reads "Amends row 704's trigger: U4 routes every orchestrator git read through a script mode run by the snippet, or adds a third copy of HARDEN …" (override-log, 2026-10-12 `feat/build-loop-u3b3`). Row 704 itself is unedited. T33 runs `d6 build-loop.sh --state; [ "$status" -eq 0 ] && [ "$output" = ok ]` (`test/scripts/build-loop-orchestrator.bats:258`; ok in S1). G is a per-call `env` prefix, not an export (`test/lib/d6-snippet.bash:40-41`).

**Evidence:** `docs/reviews/override-log.md:704`, `test/scripts/build-loop-orchestrator.bats:258`, `test/lib/d6-snippet.bash:40-41`, `fc3r3/suite.log`

---

## Claim 17: "Rows: 200 discharged (every byte run is hashed before it is written; a writer racing the 0700 dir is the Q-103 class, row 509)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claude-workflows branch, where the four files are written from hashed bytes into `mktemp -d`. The /opt branch runs unhashed root-owned files, which is outside row 200 (it asks for the lib to be hash-checked "with the scripts" in a fresh mktemp dir). It does not establish anything about the race (Q-103).
**Legibility-target:** for-orchestrator-synthesis

Row 200 asks that "it must hash-check the lib with the scripts and extract into a fresh mktemp dir" (`docs/reviews/override-log.md:200`). The lib is one of the four files (`for my $f ("build-loop.sh", "dev-cycle.sh", "questions.sh", "lib/dev-cycle-read.sh")`, `test/lib/d6-snippet.bash:69`), written only from `obj(…)` bytes (Claim 6), into `t="$(mktemp -d)"` (`:72`).

**Evidence:** `docs/reviews/override-log.md:200`, `test/lib/d6-snippet.bash:69-72`, `fc3r3/mutants.log` (M3)

---

## Claim 18: "311 (git_harden's exact environment is pinned)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers row 311's case: dropping GIT_NO_REPLACE_OBJECTS=1 now fails a test. It does not establish a behavioural test of replace refs under that variable alone.
**Legibility-target:** for-orchestrator-synthesis

Row 311 reads "`GIT_NO_REPLACE_OBJECTS=1` … can be dropped with no test failing" (`docs/reviews/override-log.md:311`). The row-311 mutant removed it from git_harden's export, and the result was `row-311 mutant bats-exit=1` / `not ok 1 git_harden exports …` (`fc3r3/probe3.log`).

**Evidence:** `docs/reviews/override-log.md:311`, `scripts/lib/dev-cycle-read.sh:360`, `fc3r3/probe3.log`

---

## Claim 19: "644/648 not moved (store_check stays build-loop.sh's; the snippet's reader is narrower, SHA-1 only and needs no second-copy rule since it uses only bytes it hashed; each comment names the other)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference / Staleness
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "each comment names the other" clause. The rest (store_check stays in build-loop.sh; the reader is SHA-1 only and has no second-copy rule) is accurate. It does not establish whether a one-way reference suffices for rows 644/648.
**Legibility-target:** for-author

store_check's comment names the snippet: "(The D6 snippet, test/lib/d6-snippet.bash, runs a narrower reader before this script: SHA-1 only and no second-copy rule, …)" (`scripts/build-loop.sh:928-930`). The snippet never names store_check or build-loop.sh's object check (paraphrased — no quote available because this is an absence claim: `grep -n -i 'store\|second.copy\|narrow\|row 64[48]' test/lib/d6-snippet.bash` returns nothing). The only other mention, "past build-loop.sh's store_check", is in the lib's git_harden header (`scripts/lib/dev-cycle-read.sh:336`), not in the snippet. The reference is one-way. Either the snippet's reader comment (`test/lib/d6-snippet.bash:55-57`) names store_check, or the plan stops saying "each comment names the other". Same defect as Claim 70.

**Evidence:** `scripts/build-loop.sh:927-930`, `test/lib/d6-snippet.bash:55-57`, `scripts/lib/dev-cycle-read.sh:336`

---

## Claim 20: "666 no change (row 709's reasons)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that row 709 states reasons for 666. It does not re-judge them.
**Legibility-target:** for-orchestrator-synthesis

Row 709 reads "666's listed keys change W's own files only (row 657's class) or are the caller's shell" (`docs/reviews/override-log.md:709`).

**Evidence:** `docs/reviews/override-log.md:666`, `docs/reviews/override-log.md:709`

---

## Claim 21: "(the lib's HARDEN list: core.useReplaceRefs, core.hooksPath, core.fsmonitor, core.attributesFile, core.commitGraph, core.multiPackIndex, log.date, log.showSignature; a git -c pair would win over it)"

**Location:** `scripts/build-loop.sh:134-137`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight keys and the git -c precedence. It does not establish other keys caller_gate refuses through STATE_KEYS_RE.
**Legibility-target:** for-orchestrator-synthesis

The keys match `HARDEN=(core.useReplaceRefs=false … log.date=default log.showSignature=false)` (`scripts/lib/dev-cycle-read.sh:349`). P5 gave `P5 order: count dashc` / `P5 get: dashc`, so a `-c` pair comes after the count pairs and wins (`fc3r3/probe.log`).

**Evidence:** `scripts/build-loop.sh:131-137`, `scripts/lib/dev-cycle-read.sh:349`, `fc3r3/probe.log` (P5)

---

## Claim 22: "Every git call in this process, the lib's included, runs hardened, but for caller_gate's read of the caller's pairs and merge_ident's CALLER_GLOBAL (the lib's git_harden, which states the trust model; the system config is no more the gate's than the user's: merge.directoryRenames there flipped a conflict, A17)."

**Location:** `scripts/build-loop.sh:493-497`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the config, replace, protocol and attribute settings. Every --check call in T26 carries them, and the two exceptions are the only overrides of those variables. It does not count `GIT_LITERAL_PATHSPECS=0` in the lib's `md_ls` (`scripts/lib/dev-cycle-read.sh:1601`), a deliberate pathspec choice with fixed `:(glob,icase)` magic that keeps every security setting, as an exception. The A17 history is not re-run.
**Legibility-target:** for-orchestrator-synthesis

The only overrides of a git_harden variable in build-loop.sh are `x="$(GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list …)"` (`:564`) and `x="$(env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var …)"` (`:1321`, in merge_ident, read to its end at `:1325`) (paraphrased — no quote available for the absence of others because it rests on a grep for `env -u`, `GIT_CONFIG_COUNT=`, `GIT_CONFIG_GLOBAL=` and the other variables across the script and the lib). T26 (`ok 109`, S1) logs every --check call carrying the HARDEN pairs read from the lib, with G=/dev/null, P=none and S=1.

**Evidence:** `scripts/build-loop.sh:493-497`, `scripts/build-loop.sh:564`, `scripts/build-loop.sh:1318-1325`, `test/scripts/build-loop-check.bats:1688-1703`, `fc3r3/suite.log`

---

## Claim 23: "The caller's global config, for merge_ident alone (...); every other call reads none." (CALLER_GLOBAL captured before git_harden overwrites GIT_CONFIG_GLOBAL)

**Location:** `scripts/build-loop.sh:490-492`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the capture order and the single use. It does not establish merge_ident's ident checks.
**Legibility-target:** for-orchestrator-synthesis

The capture is `CALLER_GLOBAL=(-u GIT_CONFIG_GLOBAL); [[ -z "${GIT_CONFIG_GLOBAL+set}" ]] || CALLER_GLOBAL=("GIT_CONFIG_GLOBAL=$GIT_CONFIG_GLOBAL")` at `:492`, before `git_harden` at `:497`. The only use of `CALLER_GLOBAL` is at `:1321` (grep).

**Evidence:** `scripts/build-loop.sh:492`, `scripts/build-loop.sh:497`, `scripts/build-loop.sh:1321`

---

## Claim 24: "A caller pair (git -c, GIT_CONFIG_COUNT; read with the caller's count, so git_harden's own pairs are not listed) ...: git applies git -c pairs after git_harden's, so they win (a GIT_CONFIG_COUNT pair comes before git_harden's and loses, but is refused too)."

**Location:** `scripts/build-loop.sh:553-557`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of count pairs and `-c` pairs and the caller-count read. It does not establish multi-valued keys.
**Legibility-target:** for-orchestrator-synthesis

The read is `GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list --show-scope --name-only` (`:564`). git_harden appends HARDEN at indices from `$c`, the caller's count (`scripts/lib/dev-cycle-read.sh:357-359`), so caller count pairs come first. P5 shows the order `count dashc`. In S1, the --state test refuses a caller count pair `GIT_CONFIG_KEY_1=core.hooksPath` (`test/scripts/build-loop-orchestrator.bats:46-47`).

**Evidence:** `scripts/build-loop.sh:553-573`, `scripts/lib/dev-cycle-read.sh:357-359`, `fc3r3/probe.log` (P5), `fc3r3/suite.log`

---

## Claim 25: "(The D6 snippet, test/lib/d6-snippet.bash, runs a narrower reader before this script: SHA-1 only and no second-copy rule, since it uses only bytes it has hashed itself.)"

**Location:** `scripts/build-loop.sh:928-930`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reader's properties. It does not establish that the snippet is the only caller path (U4).
**Legibility-target:** for-orchestrator-synthesis

The reader is `use Digest::SHA qw(sha1_hex)` and runs only under `if [[ "$x" == sha1 ]]` (`test/lib/d6-snippet.bash:58`, `:77`). No copy count is taken (paraphrased — no quote available because this is an absence claim over the perl program, read whole).

**Evidence:** `scripts/build-loop.sh:927-930`, `test/lib/d6-snippet.bash:58-79`

---

## Claim 26: "git_harden switches off the multi-pack-index" / "Item 2's fsmonitor and replace refs are git_harden's and the state gate's" / "the user's global ones included, which git_harden hides from the gate's own git"

**Location:** `scripts/build-loop.sh:943-944`, `scripts/build-loop.sh:1105`, `scripts/build-loop.sh:1114`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rename's accuracy against the lib's settings. It does not re-verify store_check or checkout_gate.
**Legibility-target:** for-orchestrator-synthesis

The settings are `core.multiPackIndex=false`, `core.fsmonitor=false`, `core.useReplaceRefs=false`, `core.attributesFile=/dev/null` (`scripts/lib/dev-cycle-read.sh:349`) and `GIT_NO_REPLACE_OBJECTS=1 … GIT_CONFIG_GLOBAL=/dev/null` (`:360`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:349-360`

---

## Claim 27: "Its git reads are hardened (the lib's git_harden): they read no user or system git config (a repository owned by another user that needs a global safe.directory reads as "Not inside a git repository") and no transport (a partial clone's missing object fails)."

**Location:** `scripts/dev-cycle.sh:83-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same ground as Claim 3, with the same scope caveats: ownership simulated by `GIT_TEST_ASSUME_DIFFERENT_OWNER`; the lazy fetch executed only through --check (Claim 34).
**Legibility-target:** for-orchestrator-synthesis

P7 printed `Not inside a git repository` / `P7 head exit=1`, while main's copy printed `P7 main exit=0` (`fc3r3/mutants.log`, `fc3r3/probe.log`). The message comes from `|| { echo "Not inside a git repository" >&2; exit 1; }` (`scripts/dev-cycle.sh:132`).

**Evidence:** `scripts/dev-cycle.sh:83-86`, `scripts/dev-cycle.sh:132`, `fc3r3/probe.log` (P7), `fc3r3/mutants.log`

---

## Claim 28: "Exit: ... 1 bad usage, a GIT_CONFIG_COUNT that is not plain decimal, not a git repo, ..."

**Location:** `scripts/dev-cycle.sh:87-90`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 010 and 1x through scrub_reexec's parent. It does not exercise a leading-blank count for dev-cycle.sh (build-loop.sh's test covers `" 1"`).
**Legibility-target:** for-orchestrator-synthesis

The output was `P6 count=010 exit=1 … dev-cycle.sh: GIT_CONFIG_COUNT is not a plain decimal count` and `P6 count=1x exit=1` (`fc3r3/probe.log`). The check is `{ echo "${0##*/}: GIT_CONFIG_COUNT is not a plain decimal count" >&2; exit 1; }` (`scripts/lib/dev-cycle-read.sh:354`).

**Evidence:** `scripts/dev-cycle.sh:87-90`, `scripts/lib/dev-cycle-read.sh:354`, `fc3r3/probe.log` (P6)

---

## Claim 29: "Every git call from here on, the lib's and questions.sh's included, runs hardened, as build-loop.sh's do (the lib's git_harden: no hook, fsmonitor, replace ref, user or system config, or transport): D6 runs the digest as gate code. File names are literal, not pathspecs."

**Location:** `scripts/dev-cycle.sh:127-131`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git process the digest and --check-brief start, questions.sh's included (through the PATH shim, which logs children). "Literal" holds for the default. `matches()` and `md_ls` deliberately set `GIT_LITERAL_PATHSPECS=0` with explicit `:(literal)`/`:(glob)` magic (`scripts/dev-cycle.sh:149-160`, `scripts/lib/dev-cycle-read.sh:1601`), and those calls keep every listed protection.
**Legibility-target:** for-orchestrator-synthesis

Test 20 of S1 asserts `[ "$n" -gt 10 ]` logged calls, each carrying HARDEN, `G=/dev/null P=none S=1` (`test/scripts/build-loop-orchestrator.bats:375-379`). questions.sh calls git (`git -C "$PWD" rev-parse …`, `scripts/questions.sh:80`) and inherits the exported environment.

**Evidence:** `scripts/dev-cycle.sh:127-160`, `scripts/questions.sh:80-84`, `test/scripts/build-loop-orchestrator.bats:363-380`, `fc3r3/suite.log`

---

## Claim 30: Removal of dev-cycle.sh's `export GIT_LITERAL_PATHSPECS=1` (every path that relied on it still gets it)

**Location:** `scripts/dev-cycle.sh:135-136`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers dev-cycle.sh and the lib, sourced before. It does not cover a caller that sources the lib without calling git_harden (none does).
**Legibility-target:** for-orchestrator-synthesis

The old export ran after `cd "$ROOT"`. The variable is now exported by `git_harden` at `:131`, before any git call, through `export … GIT_LITERAL_PATHSPECS=1` (`scripts/lib/dev-cycle-read.sh:360`).

**Evidence:** `scripts/dev-cycle.sh:131-136`, `scripts/lib/dev-cycle-read.sh:360`

---

## Claim 31: "git_harden and the state gate own item 2's fsmonitor and replace refs"

**Location:** `scripts/lib/dev-cycle-read.sh:70`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rename. It does not re-verify the state gate's keys.
**Legibility-target:** for-orchestrator-synthesis

`core.fsmonitor=false core.useReplaceRefs=false` are in HARDEN (`:349`), and `GIT_NO_REPLACE_OBJECTS=1` is exported (`:360`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:70`, `scripts/lib/dev-cycle-read.sh:349-360`

---

## Claim 32: "git_harden: every later git call in this process and its children runs hardened, but where a caller hands back its own setting on purpose (build-loop.sh's caller_gate reads the caller's count, merge_ident its global config); build-loop.sh and dev-cycle.sh call it once, after scrub_reexec and before their first git call"

**Location:** `scripts/lib/dev-cycle-read.sh:326-330`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claims 1 and 22, including Claim 22's pathspec caveat.
**Legibility-target:** for-orchestrator-synthesis

See Claim 1 for the call order (`scripts/build-loop.sh:442-497`, `scripts/dev-cycle.sh:103-132`) and Claim 22 for the two hand-backs (`scripts/build-loop.sh:564`, `:1321`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:326-330`, `scripts/build-loop.sh:564`, `scripts/build-loop.sh:1321`

---

## Claim 33: "HARDEN's config pairs outrank the repo's config: main's own objects (core.useReplaceRefs there would override GIT_NO_REPLACE_OBJECTS), no hook, no fsmonitor command, no core.attributesFile, no multi-pack-index (...), no commit-graph (...), git log's own date format and no signature check (a bad log.date stops git log; log.showSignature runs gpg.program)."

**Location:** `scripts/lib/dev-cycle-read.sh:332-337`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the useReplaceRefs override, log.date and log.showSignature on git 2.39.5. It does not execute the multi-pack-index or commit-graph rationales (pre-existing text).
**Legibility-target:** for-orchestrator-synthesis

With the repo's `core.useReplaceRefs true`, the output was `P4 env only: repl` (the replacement read despite `GIT_NO_REPLACE_OBJECTS=1`) and `P4 env + -c false: orig` (`fc3r3/probe.log`). For log.date and log.showSignature, see Claim 2 (P1, P2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:332-337`, `fc3r3/probe.log` (P1, P2, P4)

---

## Claim 34: "GIT_CONFIG_GLOBAL=/dev/null and GIT_CONFIG_NOSYSTEM ... GIT_ALLOW_PROTOCOL=none: no transport, so a lazy fetch (a partial clone's missing object) fails however its config was planted."

**Location:** `scripts/lib/dev-cycle-read.sh:338-341`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --check path's lazy fetch, which the existing test asserts never runs upload-pack. It does not run dev-cycle.sh against a partial clone.
**Legibility-target:** for-orchestrator-synthesis

The existing check test asserts `[ ! -e "$BATS_TEST_TMPDIR/fetched" ] || { echo "upload-pack ran"; return 1; }` (`test/scripts/build-loop-check.bats:1685`), and it passed in S1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:338-341`, `test/scripts/build-loop-check.bats:1670-1686`, `fc3r3/suite.log`

---

## Claim 35: "The caller's own pairs (git -c, GIT_CONFIG_COUNT) still apply, git -c ones after HARDEN's: CALLER_COUNT keeps the caller's count for build-loop.sh's caller_gate, which refuses a HARDEN key there by name."

**Location:** `scripts/lib/dev-cycle-read.sh:341-344`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers order and refusal (P5, Q3, the --state test). It does not establish read modes, where caller_gate does not run.
**Legibility-target:** for-orchestrator-synthesis

The capture is `CALLER_COUNT="$c"` before the loop (`:356`). It is read at `scripts/build-loop.sh:564`. For the refusals, see Claims 2 and 24.

**Evidence:** `scripts/lib/dev-cycle-read.sh:352-361`, `scripts/build-loop.sh:564-569`, `fc3r3/probe.log` (P5), `fc3r3/probe2.log` (Q3)

---

## Claim 36: "A GIT_CONFIG_COUNT that is not plain decimal (010 reads as 8 here and as 10 to git) exits 1."

**Location:** `scripts/lib/dev-cycle-read.sh:344-345`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash's octal reading and the exit in both scripts. It does not trace git's own count parser in source; "10 to git" is pre-existing text.
**Legibility-target:** for-orchestrator-synthesis

Probe R printed `bash $((010)) = 8` (`fc3r3/probe3.log`). The exit is shown for dev-cycle.sh in P6 and for build-loop.sh by the orchestrator test's `for c in 010 08 1x " 1"` loop (`test/scripts/build-loop-orchestrator.bats:51-54`; ok in S1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:354`, `fc3r3/probe3.log`, `fc3r3/probe.log` (P6), `fc3r3/suite.log`

---

## Claim 37: "What these cannot switch off, build-loop.sh's state gate refuses in its gated modes; dev-cycle.sh runs no state gate (row 548)."

**Location:** `scripts/lib/dev-cycle-read.sh:345-346`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the gate exists only in build-loop.sh. It does not enumerate the gated modes.
**Legibility-target:** for-orchestrator-synthesis

`grep -n 'state_gate\|default_gate' scripts/dev-cycle.sh` returns nothing (paraphrased — no quote available because this is an absence claim). Row 548 reads "dev-cycle.sh runs neither state_gate nor default_gate" (`docs/reviews/override-log.md:548`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:345-346`, `docs/reviews/override-log.md:548`

---

## Claim 38: "A second call returns at once: it would count HARDEN's pairs as the caller's."

**Location:** `scripts/lib/dev-cycle-read.sh:346-347`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers calls within one shell. A child that re-sources the lib starts with `CALLER_COUNT=""` and would append again; no such child exists today.
**Legibility-target:** for-orchestrator-synthesis

The guard is `[[ -z "$CALLER_COUNT" ]] || return 0` (`:352`). Mutant M2 removed it, and the test went red (`fc3r3/mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:350-352`, `fc3r3/mutants.log` (M2)

---

## Claim 39: "the one way the orchestrator runs build-loop.sh (the gate) and dev-cycle.sh (the digest). U4 puts this file, byte for byte, in skills/dev-cycle/SKILL.md, the root-owned image copy, as the body of a quoted heredoc that bash reads, so it runs the same from any login shell and defines nothing in the caller's"

**Location:** `test/lib/d6-snippet.bash:2-8`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the bash -s form working from a pipe and from stdin, defining d6 only in that bash, and the image's SKILL.md being root-owned. "The one way" and U4's paste are future conventions; they are not established.
**Legibility-target:** for-orchestrator-synthesis

Q1's pipe and file-stdin runs exited 0 (`fc3r3/probe2.log`). `ls -ln /opt/claude-workflows/skills/dev-cycle/SKILL.md` shows `-r--r--r-- 1 0 0` (paraphrased — no quote available because this is host file metadata, not repository text).

**Evidence:** `test/lib/d6-snippet.bash:2-8`, `fc3r3/probe2.log` (Q1)

---

## Claim 40: "T33 is to assert the two match once U4 writes the block (pending until then)."

**Location:** `test/lib/d6-snippet.bash:10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pending comment. There is no assertion yet.
**Legibility-target:** for-orchestrator-synthesis

The comment is `# The SKILL.md block and test/lib/d6-snippet.bash are byte-equal (T33): pending until U4 writes the block.` (`test/scripts/build-loop-orchestrator.bats:268`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:268`

---

## Claim 41: "In claude-workflows (main's first-parent root commit is D6_ROOT) it runs main's own scripts: one perl process reads every object it uses through one cat-file --batch ..."

**Location:** `test/lib/d6-snippet.bash:11-19`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers D6_ROOT against /workspace main and a real run on a clone of it. It does not cover other clones of claude-workflows with rewritten roots.
**Legibility-target:** for-orchestrator-synthesis

The constant is `D6_ROOT=640cf00735754d4253819a0354fb8ca9b71a8ea7` (`:38`). Q1 reported `root 640cf00735754d4253819a0354fb8ca9b71a8ea7  commits 1122` and `Q1 file exit=0 ms=110` with main's --settings output (`fc3r3/probe2.log`).

**Evidence:** `test/lib/d6-snippet.bash:11-19`, `test/lib/d6-snippet.bash:38`, `fc3r3/probe2.log` (Q1)

---

## Claim 42: "It never reads the working tree, ~/.claude/scripts or a replaced object"

**Location:** `test/lib/d6-snippet.bash:22-23`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers working-tree file contents (T33's `exit 9` copies never run), ~/.claude/scripts (all four files are always present in the run directory, so dev-cycle.sh's `$HOME/.claude/scripts/questions.sh` fallback is never taken), and replace refs (refused, and the reader is hash-checked). It does not cover repository discovery: in a linked worktree git reads the `.git` gitfile there, which a loop that can write the tree could redirect. That route yields another repository's main, the same trusted-ref class as Claim 14.
**Legibility-target:** for-orchestrator-synthesis

The fallback is `QS="$SCRIPT_DIR/questions.sh"; [[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"` (`scripts/dev-cycle.sh:389-390`). For /opt, `[[ -f "$d/scripts/$f" ]] || no` covers questions.sh (`test/lib/d6-snippet.bash:84`). T33 (`ok 11`, S1) writes `exit 9` over the working tree's four files and the runs still succeed.

**Evidence:** `test/lib/d6-snippet.bash:22-23`, `test/lib/d6-snippet.bash:84`, `scripts/dev-cycle.sh:389-390`, `fc3r3/suite.log`

---

## Claim 43: "Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout, with nothing run, for a replace ref, info/grafts, a default branch that is not exactly one plain main or master or whose ref names no commit itself, a first-parent history, tree or file that cannot be read whole or does not hash to its id (a shallow history among them), a script on main that is not a regular file, an image copy that fails the ownership checks, or a git read or temp-dir step that fails (...); 1 for another first argument."

**Location:** `test/lib/d6-snippet.bash:26-33`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal (T36, B2, T37, P3's symlink death mapped to `no`) and that the exit status passes through after the EXIT trap. It does not exercise the mktemp and mkdir failures.
**Legibility-target:** for-orchestrator-synthesis

Every refusal goes through `no` (Claim 12). The pass-through is `exit "$?"` after the run (`:88`). P3 printed `P3 symlink exit=255 … questions.sh is not a (?^:\A100(644|755)\z) entry` (`fc3r3/probe.log`), and bash maps any non-zero perl status to `no` at `:78`.

**Evidence:** `test/lib/d6-snippet.bash:26-33`, `test/lib/d6-snippet.bash:78-88`, `fc3r3/suite.log`, `fc3r3/probe.log` (P3)

---

## Claim 44: "t stays global: the EXIT trap reads it"

**Location:** `test/lib/d6-snippet.bash:43`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the local list. It does not establish trap timing.
**Legibility-target:** for-orchestrator-synthesis

The declaration `local s="${1:-}" F x m n sha f d P` omits `t`, and the trap is `trap 'rm -rf "$t"' EXIT` (`:73`).

**Evidence:** `test/lib/d6-snippet.bash:43`, `test/lib/d6-snippet.bash:72-73`

---

## Claim 45: "It prints "main" once the four files are written, "other" when the first-parent root is not D6_ROOT; any failure dies (status 255)."

**Location:** `test/lib/d6-snippet.bash:55-57`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers outputs and exit statuses. "main" and "other" are exact. Failures exit non-zero, but not always 255. The bash side tests only non-zero, so nothing depends on the number.
**Legibility-target:** for-author

The observed runs were `P3 other-root exit=0 out=[other]`, `P3 main exit=0 out=[main]`, and 255 for the die paths exercised (`fc3r3/probe.log`). Perl's `die` exits with `$!` when `$!` is non-zero, so the `open(...) or die "$f: $!\n"` / `close(...) or die` paths (`:70`) exit with the errno (`perl -e 'open(my $f,">","/nonexistent/x") or die …'` exited 2 here). A signal death (SIGPIPE) gives 141. A more precise comment: "any failure exits non-zero".

**Evidence:** `test/lib/d6-snippet.bash:55-71`, `test/lib/d6-snippet.bash:78`, `fc3r3/probe.log` (P3)

---

## Claim 46: "D6_ROOT is a SHA-1 id: a repository in another format is not claude-workflows."

**Location:** `test/lib/d6-snippet.bash:76`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the id is 40 hex. It does not establish a future SHA-256 conversion of claude-workflows (override row's revisit trigger).
**Legibility-target:** for-orchestrator-synthesis

The constant is `D6_ROOT=640cf00735754d4253819a0354fb8ca9b71a8ea7` (40 hex, `:38`), and the branch is `if [[ "$x" == sha1 ]]; … else x=other; fi` (`:77-79`).

**Evidence:** `test/lib/d6-snippet.bash:38`, `test/lib/d6-snippet.bash:76-79`

---

## Claim 47: Refusal text "main's first-parent history, the trees above scripts/lib/ or the four files could not be read whole, or an object does not hash to its id"

**Location:** `test/lib/d6-snippet.bash:78`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which objects the reader reads. The scripts/lib tree itself is also read (`entry($l, …)`), and a failure there produces the same text. The plan's "the trees down to scripts/lib/" is exact.
**Legibility-target:** for-author

The reader reads `my $l = entry($s, "lib", …)` and then `entry($t, $n, …)` with `$t = $l` for the lib file (`:68-70`), so the lib tree is read too. "The trees down to scripts/lib/" would match the code.

**Evidence:** `test/lib/d6-snippet.bash:68-70`, `test/lib/d6-snippet.bash:78`

---

## Claim 48: "Under bash -s the script is the heredoc on stdin: bash has read this whole line before it runs, and no child reads the rest of it."

**Location:** `test/lib/d6-snippet.bash:90-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pipe and regular-file stdin. It does not exercise a bash version whose heredoc is a pipe versus a temp file; both stdin kinds were run.
**Legibility-target:** for-orchestrator-synthesis

The runs were `cat "$SN" | bash -s -- build-loop.sh --settings` (exit 0) and `bash -s -- dev-cycle.sh … < "$SN"` (exit 0, `ok README.md`) (`fc3r3/probe2.log`). The redirect is `d6 "$@" </dev/null` (`:92`).

**Evidence:** `test/lib/d6-snippet.bash:90-92`, `fc3r3/probe2.log` (Q1)

---

## Claim 49: "Not log.date: git_harden's log.date pair overrides it (row 505); a bad boolean still stops git log."

**Location:** `test/scripts/build-loop-check.bats:1660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --status and --check-branch under `log.abbrevCommit bogus`. It does not cover other log.* booleans.
**Legibility-target:** for-orchestrator-synthesis

The test passes in S1 (`ok 106 under a broken log.* config …`). P2 shows a bogus log.date is harmless at the tip.

**Evidence:** `test/scripts/build-loop-check.bats:1658-1667`, `fc3r3/suite.log`, `fc3r3/probe.log` (P2)

---

## Claim 50: "every git call --check makes carries git_harden's config pairs ..." / "HARDEN from the lib itself, so a key added there is checked here too."

**Location:** `test/scripts/build-loop-check.bats:1688`, `test/scripts/build-loop-check.bats:1699-1700`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop source and the test passing. It does not cover non---check modes.
**Legibility-target:** for-orchestrator-synthesis

The loop is `for kv in $(bash -c 'source "$1"; echo "${HARDEN[*]}"' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh") G=/dev/null P=none S=1` (`:1700`), and `ok 109` in S1.

**Evidence:** `test/scripts/build-loop-check.bats:1688-1703`, `fc3r3/suite.log`

---

## Claim 51: "A plain caller pair passes; a count git_harden would misread stops every mode (row 276)."

**Location:** `test/scripts/build-loop-orchestrator.bats:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers build-loop.sh modes in the loop. dev-cycle.sh is covered by Claim 28.
**Legibility-target:** for-orchestrator-synthesis

The test passes in S1 (`ok 2`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:50-55`, `fc3r3/suite.log`

---

## Claim 52: "d6_copy ROOT OPT: D6, a copy of test/lib/d6-snippet.bash with D6_ROOT and D6_OPT replaced. d6_setup: main holds this branch's four scripts, and D6 takes this fixture's root commit as claude-workflows' own."

**Location:** `test/scripts/build-loop-orchestrator.bats:227-229`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helpers. The `grep -qxF` guard fails the helper when the sed misses.
**Legibility-target:** for-orchestrator-synthesis

The helpers are `sed "s|^  D6_ROOT=.*; D6_OPT=.*|  D6_ROOT=$1; D6_OPT=$2|"` with `grep -qxF` (`:230`) and `d6_copy "$(git rev-list --max-parents=0 main)" /opt/claude-workflows` (`:233`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:227-234`

---

## Claim 53: T33's name "runs main's four scripts from a fresh temp dir, each with its own lib and questions.sh, never the working tree's, and removes the dir" and its comments ("The snippet exports no config pair, so --state run through it passes caller_gate (row 702)"; "A byte the reader did not hash is never used: a git whose cat-file --batch alters one word of the blobs it prints")

**Location:** `test/scripts/build-loop-orchestrator.bats:245-268`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers build-loop.sh's lib path (asserted on stderr), dev-cycle.sh's questions.sh (asserted by output) and the temp-dir removal. dev-cycle.sh's lib path is shown only indirectly: exit 0 when the working tree's lib is `exit 9`. The tamper sed rewrites every `pipefail` in the batch stream, blobs and any other object alike.
**Legibility-target:** for-orchestrator-synthesis

The assertions read `[[ "$l" == "lib at $TMPDIR/"*/scripts/lib/dev-cycle-read.sh ]]` (`:256`), `*$'\n- Q-001  trigger  from-main\n'*` (`:260`), and `[ "$status" -eq 2 ] && [ "$output" = "$A1" ] && [[ "$stderr" == *" does not hash to its id" ]]` (`:266`). `ok 11` in S1. M3 turns it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:245-268`, `fc3r3/suite.log`, `fc3r3/mutants.log` (M3)

---

## Claim 54: T36 "refuses before running anything: a blob or commit replace ref, info/grafts, not exactly one plain main or master"

**Location:** `test/scripts/build-loop-orchestrator.bats:271`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each case listed, plus symbolic and tag cases the name folds into "plain".
**Legibility-target:** for-orchestrator-synthesis

`ok 12` in S1. Each case uses `d6_is`, which requires empty stderr and exact stdout (`:237`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:271-284`, `fc3r3/suite.log`

---

## Claim 55: "refuses the scripts/ tree rewritten in place, and runs no planted bytes (T36, U3b3 i1 A1, i2 B1)"

**Location:** `test/scripts/build-loop-orchestrator.bats:290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loose in-place case. The exact stdout match excludes the planted `echo replaced` output.
**Legibility-target:** for-orchestrator-synthesis

The test checks `[ "$(git ls-tree … scripts/build-loop.sh)" = "$e" ]` (git sees the plant), then `[ "$output" = "$A1" ]` (`:295-297`). `ok 13` in S1. M3 turns it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:290-298`, `fc3r3/suite.log`, `fc3r3/mutants.log`

---

## Claim 56: "refuses a first-parent commit rewritten in place to end main's history at D6_ROOT"

**Location:** `test/scripts/build-loop-orchestrator.bats:300`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the forged tip. It does not cover a forged middle commit (the same code path).
**Legibility-target:** for-orchestrator-synthesis

The test checks `[ "$(git rev-list --first-parent --max-parents=0 main)" = "$r" ]`, then refusal (`:304-307`). `ok 14` in S1. M3 turns it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:300-308`, `fc3r3/suite.log`, `fc3r3/mutants.log`

---

## Claim 57: "git names the mismatch on stderr too; the one stdout line is the snippet's."

**Location:** `test/scripts/build-loop-orchestrator.bats:306`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stderr of the tip's snippet on this test's scenario. The test asserts nothing about stderr, so no behaviour depends on it. "The one stdout line is the snippet's" is still true.
**Legibility-target:** for-author

On the same scenario (a tip rewritten in place to a forged root), the tip's snippet prints only perl's line on stderr: `stderr: 8c41e52b… does not hash to its id`, with no git line (`fc3r3/probe4.log`). `git cat-file --batch` serves the rewritten loose object silently (`cat-file --batch exit=0 stderr=[]`, `fc3r3/probe3.log`). d9515d09's snippet, where the comment was added (`git log -S`), did emit git's `error: hash mismatch …` three times (`fc3r3/probe5.log`). The c9648432 rewrite removed the git readers that printed it. The comment should say that perl names the mismatch on stderr.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:306`, `fc3r3/probe4.log`, `fc3r3/probe5.log`, `fc3r3/probe3.log`

---

## Claim 58: "refuses, never falls to the image copy, when main's first-parent history cannot be read whole: a missing commit, a shallow clone"

**Location:** `test/scripts/build-loop-orchestrator.bats:310`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 8.
**Legibility-target:** for-orchestrator-synthesis

`ok 15` in S1. M1 turns it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:310-315`, `fc3r3/suite.log`, `fc3r3/mutants.log` (M1)

---

## Claim 59: T27 "a gate copy patched in the loop's worktree prints ok for its tip; the D6 snippet's copy from main refuses the same tip"

**Location:** `test/scripts/build-loop-orchestrator.bats:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mode-rule patch and the symlink case.
**Legibility-target:** for-orchestrator-synthesis

`ok 16` in S1. The test asserts `ok $B` for the patched copy and `refuse $B: 1 of 2 changed paths refused …` through the snippet (`:323-327`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:317-328`, `fc3r3/suite.log`

---

## Claim 60: T37 "outside claude-workflows the D6 snippet runs the image copy by absolute path, not main's copy"

**Location:** `test/scripts/build-loop-orchestrator.bats:330`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The test ran (not skipped) against this host's root-owned /opt copy. It does not cover hosts without one; there it skips by design.
**Legibility-target:** for-orchestrator-synthesis

`ok 17` in S1, with no `# skip` marker (`fc3r3/suite.log` line 20). /opt is `0 555` down to `scripts/lib`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:330-336`, `fc3r3/suite.log`

---

## Claim 61: T37 "refuses an image copy the uid owns, and never runs main's"

**Location:** `test/scripts/build-loop-orchestrator.bats:338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the uid-owned file case. "Never runs main's" follows from `d6_is`'s exact stdout and empty stderr: main's `echo main copy` cannot have run.
**Legibility-target:** for-orchestrator-synthesis

`ok 18` in S1. Mutant a2 (own() a no-op, at a0014ce5) turned this test red (`fc3r3/mutants.log`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:338-344`, `fc3r3/suite.log`, `fc3r3/mutants.log` (a2)

---

## Claim 62: "git_harden exports HARDEN's pairs after the caller's and a fixed environment, once however often it is called; the D6 snippet's git carries the same" / "The snippet cannot source the lib (it runs before anything is checked): its one git array repeats both lists."

**Location:** `test/scripts/build-loop-orchestrator.bats:346`, `test/scripts/build-loop-orchestrator.bats:357`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 13. M2 and the row-311 mutant each turn it red.
**Legibility-target:** for-orchestrator-synthesis

The test calls `git_harden; git_harden` and then compares against a want with `GIT_CONFIG_COUNT=9` (`:348`, `:355`). `ok 19` in S1.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:346-361`, `fc3r3/suite.log`, `fc3r3/mutants.log`, `fc3r3/probe3.log`

---

## Claim 63: "every git call dev-cycle.sh makes carries git_harden's pairs: a bogus log.date stops nothing, log.showSignature runs no gpg.program" / "A signed-looking commit on main: git log under log.showSignature runs gpg.program for it."

**Location:** `test/scripts/build-loop-orchestrator.bats:363`, `test/scripts/build-loop-orchestrator.bats:365`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test and the comment's premise (main's code ran gpg.program on the same fixture shape). It does not cover the --check-* modes other than --check-brief.
**Legibility-target:** for-orchestrator-synthesis

`ok 20` in S1. P1 printed `P1 main … gpg-ran=yes`. Mutant a3 (log.showSignature dropped) turned the test red (`fc3r3/mutants.log`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:363-380`, `fc3r3/suite.log`, `fc3r3/probe.log` (P1), `fc3r3/mutants.log` (a3)

---

## Claim 64: 9925f2a7 message: "Moves build-loop.sh's harden, HARDEN and its environment exports into the lib as git_harden ... dev-cycle.sh now calls it before its first git call ... HARDEN gains log.date=default (row 505: a bogus log.date stopped --check-brief) and log.showSignature=false (git log would run gpg.program). ... a host repo that needs a global safe.directory would stop."

**Location:** `9925f2a7` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the move and the three behaviours (P1, P2, P7). It does not check the intermediate tree beyond the tip.
**Legibility-target:** for-orchestrator-synthesis

See Claims 1, 2 and 27 (`fc3r3/probe.log`, `fc3r3/mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:326-361`, `fc3r3/probe.log`

---

## Claim 65: a0014ce5 message: the snippet's description and "T33 (own lib and questions.sh, working tree ignored, temp dir removed, a tampered extraction refused, --state passes; the SKILL.md byte-equality half waits for U4), T36, T37 (the real /opt half skips without a root-owned image copy) ... The row-307 test now breaks git log with log.abbrevCommit"

**Location:** `a0014ce5` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a0014ce5's own tree: control run a0, all seven D6/harden tests ok. "hash-checks each against main's tree" describes that commit's code, since superseded by the reader. It does not establish the zsh alias incident (Claim 4b).
**Legibility-target:** for-orchestrator-synthesis

At a0014ce5, T33 contained `PATH="$S:$PATH" d6_is "refuse d6: the extracted scripts/build-loop.sh does not hash to main's copy"` and `d6 build-loop.sh --state; … [ "$output" = ok ]` (`git show a0014ce5:test/scripts/build-loop-orchestrator.bats`, lines 258-266). Control a0 passed in `fc3r3/mutants.log`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:245-268` (at a0014ce5), `fc3r3/mutants.log` (a0)

---

## Claim 66: a0014ce5 message: "a planted log.showSignature ran gpg.program on main"

**Location:** `a0014ce5` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest under main's scripts. It does not cover a real gpg binary.
**Legibility-target:** for-orchestrator-synthesis

P1 printed `P1 main exit=0 gpg-ran=yes` (`fc3r3/probe.log`).

**Evidence:** `fc3r3/probe.log` (P1)

---

## Claim 67: a0014ce5 message: "Mutants checked: hash check removed, ownership check removed, log.showSignature pair removed, main's dev-cycle.sh: each turns a test red."

**Location:** `a0014ce5` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four mutants on a0014ce5's tree. I read "main's dev-cycle.sh" as "the working tree's dev-cycle.sh run instead of main's", the reading i2 also used. It does not establish other mutant readings.
**Legibility-target:** for-orchestrator-synthesis

The results were a1 (hash check off) `not ok 1 the D6 snippet runs main's four scripts …`, a2 (own off) `not ok 2 … refuses an image copy the uid owns`, a3 (log.showSignature off) `not ok 1 every git call dev-cycle.sh makes …`, and a4 (the working tree's dev-cycle.sh) `not ok 1 the D6 snippet runs main's four scripts …` (`fc3r3/mutants.log`).

**Evidence:** `fc3r3/mutants.log` (a1–a4)

---

## Claim 68: d9515d09 message: "about 0.1 s over this repository's ~1,100 first-parent commits"; "A2: the default branch's ref must name a commit itself, not a peeled tag."

**Location:** `d9515d09` (commit message)
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the commit count (1122) and A2 (Claim 5). The 0.1 s figure was for d9515d09's re-hash and was not re-timed. The tip's whole snippet run, including --settings, took 110 ms.
**Legibility-target:** for-orchestrator-synthesis

Q1 printed `commits 1122`, `ms=110` (`fc3r3/probe2.log`).

**Evidence:** `fc3r3/probe2.log` (Q1), `test/lib/d6-snippet.bash:54`

---

## Claim 69: c9648432 message: "d9515d09 re-hashed main's commits and trees through one cat-file --batch, but rev-list, rev-parse and ls-tree still chose the ids and blobs ... one perl process drives one cat-file --batch ... B2: any read failure refuses ...; a repository that is not SHA-1 takes the image copy. B11: one history walk instead of two. B4: --state's header names HARDEN's eight keys. ... B8: git_harden returns on a second call. B9: both call-log tests loop over the lib's HARDEN."

**Location:** `c9648432` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed item at the tip, plus d9515d09's readers (`git show d9515d09:test/lib/d6-snippet.bash` holds `g rev-list --first-parent`, `g ls-tree --format=…` and `g cat-file blob`). "(executed: planted bytes ran)" is i2's probe and was not re-run.
**Legibility-target:** for-orchestrator-synthesis

See Claims 6, 8, 21, 38 and 50. d9515d09's snippet contained `x="$(g ls-tree --format='%(objectmode) %(objecttype) %(objectname)' "$sha" -- "scripts/$f")"` and `g cat-file blob "${BASH_REMATCH[2]}" > "$d/scripts/$f"` (d9515d09 `test/lib/d6-snippet.bash`, function lines 32-35).

**Evidence:** `test/lib/d6-snippet.bash:58-79`, `fc3r3/mutants.log`, `fc3r3/suite.log`

---

## Claim 70: c9648432 message: "B10: store_check and the snippet's reader name each other."

**Location:** `c9648432` (commit message)
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the snippet's text at c9648432 and at the tip, which are identical (`git diff c9648432 5583a2cd` touches only docs/reviews/). Only store_check names the snippet.
**Legibility-target:** for-author

See Claim 19. `git diff d9515d09 c9648432 -- test/lib/d6-snippet.bash | grep -i store` is empty, so the B10 change added no reference on the snippet's side. The rubric's B10 "Fixed (cross-reference comments)" rests on this. The commit message cannot be changed; the fix is a comment in the snippet, or rubric/plan text saying the reference is one-way.

**Evidence:** `scripts/build-loop.sh:928-930`, `test/lib/d6-snippet.bash:55-57`

---

## Claim 71: c9648432 message: "Mutants: no refusal on a failed read (B2 test red); git_harden called twice (environment test pins one count). Suites: 285/285."

**Location:** `c9648432` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both mutants and the count. 285 = orchestrator 20 + check 146 + dispatch 4 + merge 12 + read 20 + dev-cycle 79 + hermeticity 2 + git-env 2, all ok at 5583a2cd, whose code equals c9648432's. Other repository suites were not run.
**Legibility-target:** for-orchestrator-synthesis

M1 gave `not ok 1 … never falls to the image copy` and M2 gave `not ok 1 git_harden exports …` (`fc3r3/mutants.log`). S1 had 166 ok and S2 had 119 ok (`fc3r3/suite.log`, `fc3r3/suite2.log`).

**Evidence:** `fc3r3/mutants.log` (M1, M2), `fc3r3/suite.log`, `fc3r3/suite2.log`

---

## Claim 72: 5583a2cd message: "U3b3 iteration 2: reports, rubric, seven override rows"

**Location:** `5583a2cd` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file list and the row count.
**Legibility-target:** for-orchestrator-synthesis

`git diff main...5583a2cd -- docs/reviews/override-log.md` adds 7 rows (paraphrased — no quote available because this is a count over the diff). The commit adds the four i2 critic reports, the i2 fact-check report and the rubric's iteration-2 section.

**Evidence:** `docs/reviews/override-log.md` (last seven rows)

---

## Claim 73: The seven new override rows' statements and Won't-Fix/Defer reasons

**Location:** `docs/reviews/override-log.md` (the seven 2026-10-12 `feat/build-loop-u3b3` rows at the end)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers each row's factual premise: the moved-main trust and its header mention (Claim 14); plain SHA-1 via Digest::SHA and the SHA-256 fallback (`else x=other`); the history walks cut from two to one; `refuse d6:` preceding any mode (the snippet refuses before running); row 704's premises (the lib not sourced before checks, once per process, exported pairs refused by caller_gate (Claim 2/Q3, orchestrator :46-47), G local to its bash); the opposite precedence (P5, plus git appending the snippet's own `-c` after any inherited GIT_CONFIG_PARAMETERS); and the canonical copy in test/lib. It does not re-measure "~70 ms" fork overhead or rule on the Won't-Fix judgements.
**Legibility-target:** for-orchestrator-synthesis

The row's premise is `use Digest::SHA qw(sha1_hex)` (`test/lib/d6-snippet.bash:58`), and the branch is `else x=other; fi` (`:79`). For precedence, P5 printed `count dashc` (`fc3r3/probe.log`). The "snippet's -c outranks a caller's -c" premise rests on git appending each `-c` to GIT_CONFIG_PARAMETERS after inherited entries (paraphrased — no quote available because this is git's documented command-line config behaviour, not repository code).

**Evidence:** `docs/reviews/override-log.md` (last seven rows), `test/lib/d6-snippet.bash:40`, `test/lib/d6-snippet.bash:58-79`, `fc3r3/probe.log` (P5), `fc3r3/probe2.log` (Q3)

---

## Claim 74: 7a927183 and 5d175c0e messages (subjects only: the plan's as-built note; i1 fact-check report and rubric, short-circuited at A1)

**Location:** `7a927183`, `5d175c0e` (commit messages)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the subjects match the files touched. The note's content is covered by Claims 1–20.
**Legibility-target:** for-orchestrator-synthesis

The rubric's first lines read `Loop-pass short-circuit: used at 7a927183` and `Loop-pass short-circuit: behavioural 🔴 confirmed at fact-check` (`docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b3.md:2-8`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b3.md:1-8`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19** (`docs/working/plan-build-loop-handoff.md:326`): "each comment names the other" (rows 644/648). Only store_check's comment names the snippet; the snippet never names store_check. Add the reference to the reader comment at `test/lib/d6-snippet.bash:55-57`, or reword the note. Comment/doc only.
- **Claim 70** (commit c9648432): "B10: store_check and the snippet's reader name each other". Same one-way reference, and the rubric's B10 "Fixed" rests on it. Comment/doc only.

### Stale
- **Claim 57** (`test/scripts/build-loop-orchestrator.bats:306`): "git names the mismatch on stderr too". That was true for d9515d09's snippet; since the verified reader, only perl names it. The test asserts nothing about stderr. Comment only.

### Mostly Accurate
- **Claim 15** (`test/lib/d6-snippet.bash:34-35`, plan :326): "before, not instead of, the script's own state and default-branch gates". dev-cycle.sh and build-loop.sh's read modes run neither gate (row 548). Doc only.
- **Claim 45** (`test/lib/d6-snippet.bash:57`): "any failure dies (status 255)". A die after a failed open or close exits with the errno, and a signal death with 128+n. Bash tests only non-zero. Comment only.
- **Claim 47** (`test/lib/d6-snippet.bash:78`): the refusal says "the trees above scripts/lib/", but the reader also reads the scripts/lib tree itself ("down to"). Message text only.

### Unverifiable
- **Claim 4b** (plan :326): the zsh alias `g` incident. Needs the authoring session's transcript.
- **Claim 10** (plan :326): "the -w test makes a root run refuse unless the mount is read-only". Needs a uid-0 run.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/code-fact-check-report-2026-10-12-u3b3-final-r3.md, structured per the code-fact-check skill.
- Answered: yes. I checked all ten brief focus areas, the seven new override rows and all seven branch commits. I ran the full 285-test build-loop set (285/285 ok), 7 hermetic probes and 10 mutants (2 controls, 8 mutants, every mutant red). Every executable claim was executed except two blocked ones (uid 0; a session transcript).
- Out of scope: security judgement of the verified reader's parse of malformed but hash-valid commit headers (Claim 6's residue) and of the `.git` gitfile route (Claim 42's residue). Both reduce to the trusted-ref class of row 509 / the moved-main row; they are noted, not escalated. `docs/reviews/hallucination-patterns.md` was not edited because only this file may be written. Claims 19/70 are a candidate pattern: a fix claimed as a two-way cross-reference whose second half does not exist.
- Escalate: none behavioural. For the author (text only): `test/lib/d6-snippet.bash:55-57` (Claims 19/70: name store_check, or reword `docs/working/plan-build-loop-handoff.md:326` and the rubric's B10 row); `test/scripts/build-loop-orchestrator.bats:306` (Claim 57); `test/lib/d6-snippet.bash:34-35` and `:57`, `:78` (Claims 15, 45, 47).
- Decisions I made: I read "main's dev-cycle.sh" in a0014ce5's mutant list as "the working tree's dev-cycle.sh run instead of main's", as i2 did. I simulated another owner with git's `GIT_TEST_ASSUME_DIFFERENT_OWNER` instead of a second uid. I reproduced the second-copy case as a packed real copy plus a forged loose copy rather than i2's exact two-pack layout. Probe and suite logs are kept in the session scratchpad (`fc3r3/`), not in `docs/reviews/execution-logs/`, to honour the write-only-your-report rule. I graded Claim 15 Mostly accurate, not Incorrect: dev-cycle.sh's lack of gates is settled (row 548) and stated in the lib, so the snippet's sentence misleads only a reader who skips the lib.
