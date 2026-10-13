Commit: 7a927183

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b3 (branch `feat/build-loop-u3b3`)
**Scope:** branch diff `main...7a927183`: `docs/working/plan-build-loop-handoff.md` (U3b3 as-built note), `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `test/lib/d6-snippet.bash`, `test/scripts/build-loop-check.bats`, `test/scripts/build-loop-orchestrator.bats`, and the messages of 9925f2a7, a0014ce5 and 7a927183
**Checked:** 2026-10-12
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 48
**Summary:** 37 verified, 4 mostly accurate, 1 stale, 3 incorrect, 3 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): no claim below matches a logged pattern, and no fabricated symbol was found.

**Execution provenance (shared by every `executed` claim).** All probes ran as uid 1000, git 2.39.5, bash 5.2.15, `LC_ALL=C`. Each probe script begins `set -eu`, makes its own `mktemp -d /tmp/u3b3-fc1-pN-XXXX`, refuses to continue outside it, and removes it. The scripts and their captured output are in `/tmp/claude-1000/-workspace/c69d4d0f-5190-473b-ba2f-85b5a43f49ee/scratchpad/u3b3-fc1-logs/`, called `LOGS/` below:
- **S1** `LOGS/run-suites.sh`, run from cwd `/workspace/.claude/wt-build-loop-u3b3` with its own TMPDIR at 2026-10-13T01:03:43Z UTC, exit 0. It runs `bats test/scripts/build-loop-orchestrator.bats`: 17/17 ok, test 14 (the real /opt half of T37) ran rather than skipping (`LOGS/suite-orch.log`). It also runs `bats -f 'row 307|carries git_harden' test/scripts/build-loop-check.bats`: 2/2 ok (`LOGS/suite-check307.log`).
- **P1** `LOGS/probe1.sh`, 2026-10-13T01:04:12Z, exit 0 (`LOGS/probe1.log`): `$((010))`=8, and git reads `GIT_CONFIG_COUNT=010` as 10. Precedence: git -c beats a count pair, and a count pair beats repo config. A non-decimal count exits 1 through the lib, dev-cycle.sh and build-loop.sh. `-w` is false on /opt for uid 1000.
- **P2** `LOGS/probe2.sh`, 2026-10-13T01:04:40Z, exit 0 (`LOGS/probe2.log`): runs main's pre-U3b3 scripts against two new probe tests, then four mutants of 7a927183 against the named bats tests.
- **P3** `LOGS/probe3.sh`, 2026-10-13T01:05:15Z, exit 0 (`LOGS/probe3.log`): rewrites main's `scripts` tree object in place, then runs the snippet.
- **P4** `LOGS/probe4.sh`, 2026-10-13T01:06:37Z, exit 0 (`LOGS/probe4.log`): the `bash -s` form from a file and from a pipe; a tag-named refs/heads/main; caller_gate refusing log.date and log.showSignature; core.useReplaceRefs against GIT_NO_REPLACE_OBJECTS.
- **P5** `LOGS/probe5.sh`, 2026-10-13T01:07:07Z, exit 0 (`LOGS/probe5.log`): a script committed as a symlink.
- **P6** `LOGS/probe6.sh`, 2026-10-13T01:07:49Z, exit 0 (`LOGS/probe6.log`): a lazy fetch in a partial clone, with and without git_harden.

---

## Claim 1: "`git_harden` (lib) holds HARDEN, CALLER_COUNT and the environment build-loop.sh exported ... build-loop.sh and dev-cycle.sh call it after scrub_reexec, before their first git call."

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the lib function exports and where each script calls it. It does not establish that every later git call keeps those settings (see Claim 14).
**Legibility-target:** for-orchestrator-synthesis

The lib exports the eight pairs and the seven variables the old build-loop.sh block exported (`scripts/lib/dev-cycle-read.sh:356` `export GIT_CONFIG_COUNT="$c" GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none`). The old block matches (diff line 51, removed from build-loop.sh). Call order is `scripts/build-loop.sh:441-442` (`source "$READ_LIB"` / `scrub_reexec ...`), then the mode `case` (no git: `readerform` at `scripts/lib/dev-cycle-read.sh:630-634` is pure bash), then `git_harden` at `:495`. dev-cycle.sh has `source`/`scrub_reexec` at `:100-101`, then the arg loop (no git; `-h` uses sed), then `git_harden` at `:128`, then the first git call, `ROOT="$(git rev-parse --show-toplevel ...)"`, at `:129`. In S1, test 16 printed the exact environment.

**Evidence:** `scripts/lib/dev-cycle-read.sh:346-357`, `scripts/build-loop.sh:441-495`, `scripts/dev-cycle.sh:100-129`, `LOGS/suite-orch.log`

---

## Claim 2: "HARDEN gains `log.date=default` (row 505: a bogus log.date stopped --check-brief) and `log.showSignature=false` (a planted one made the digest's git log run gpg.program on main); caller_gate refuses both keys by name with the rest."

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix behaviour on main's scripts, the fix on the branch, and caller_gate's refusal of both keys from git -c. It does not establish other log.* keys (log.abbrevCommit still stops git log, which the row-307 test relies on).
**Legibility-target:** for-orchestrator-synthesis

In P2, main's dev-cycle.sh under `git config log.date bogus` printed `status 128 out [] err [fatal: unknown date format bogus]` for `--check-brief`. Under `log.showSignature true` with a stub gpg.program, it printed `GPG RAN (status 0)` for the digest. On the branch, S1 test 17 passes both cases. P4: `GIT_CONFIG_PARAMETERS="'log.date'='iso'"` printed `refuse state log.date: ...` and exit 2, and `'log.showsignature'='false'` printed `refuse state log.showsignature: ...` and exit 2. Both come from caller_gate's HARDEN loop (`scripts/build-loop.sh:565` `for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:346`, `scripts/build-loop.sh:557-570`, `LOGS/probe2.log`, `LOGS/probe4.log`, `LOGS/suite-orch.log`

---

## Claim 3: "dev-cycle.sh now reads no user or system git config."

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git call that dev-cycle.sh and its children make through PATH's git after `git_harden`. It does not cover the pre-`git_harden` parent of scrub_reexec, which makes no git call.
**Legibility-target:** for-orchestrator-synthesis

`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` are exported (`scripts/lib/dev-cycle-read.sh:356`). In S1, test 17's shim logged more than 10 calls from `--check-brief` and the digest. Every one carried `G=/dev/null` and `S=1` (`test/scripts/build-loop-orchestrator.bats:438-440`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:356`, `test/scripts/build-loop-orchestrator.bats:425-441`, `LOGS/suite-orch.log`

---

## Claim 4: "`test/lib/d6-snippet.bash` is a bash script body, not a function" (also commit a0014ce5: "It is a bash script body, not a function")

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how the file is run: by a child `bash`, never defined in the caller's shell. It does not establish the literal wording, because the file defines a function and calls it.
**Legibility-target:** for-author

The file defines a function and calls it: `test/lib/d6-snippet.bash:39` `d6() {` ... `:81` `d6 "$@" </dev/null`. The intended point holds: no function is pasted into the caller's (possibly zsh) shell, and bash runs the whole file. A more precise wording: "a bash script fed to `bash -s`, which wraps its body in a function it calls once".

**Evidence:** `test/lib/d6-snippet.bash:39`, `test/lib/d6-snippet.bash:81`

---

## Claim 5: "the Bash tool's shell can be zsh (an alias `g` broke a pasted function)"

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond the session environment's reported shell. It does not establish the historical alias incident.
**Legibility-target:** for-orchestrator-synthesis

Paraphrased — no quote available because the claim describes a past interactive session, not code. This session's environment reports `Shell: zsh`, and zsh's glob errors (`(eval):1: no matches found`) appeared in this review's own Bash calls, which is consistent with the first half. The `g` alias incident left no artifact in the repo. Verifying it would need the transcript of that session.

**Evidence:** `test/lib/d6-snippet.bash:243` (the `g()` helper the alias would shadow)

---

## Claim 6: "It refuses with one `refuse d6: WHY` line on stdout and exit 2, nothing run, for a replace ref, info/grafts, a default branch that is not exactly one of refs/heads/main and master (not symbolic ...), a script on main that is not mode 100644/100755, or extracted bytes that do not hash (`hash-object --no-filters`) to main's id; exit 1 for another first argument."

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal and the exit-1 usage case. It does not cover the "a commit" atom, which is split out as Claim 7.
**Legibility-target:** for-orchestrator-synthesis

`no() { echo "refuse d6: $*"; exit 2; }` (`test/lib/d6-snippet.bash:242`) is stdout plus exit 2. In S1, T36 hit each listed case: blob and commit replace refs, grafts, both main and master, and a symbolic main (`d6_is` asserts one line, exit 2 and empty stderr). It also asserts the usage case: `[ "$status" -eq 1 ] && [ -z "$output" ] && [ "$stderr" = "d6: the first argument is build-loop.sh or dev-cycle.sh" ]` (`test/scripts/build-loop-orchestrator.bats:376`). The mode regex is `^100(644|755)\ blob\ ([0-9a-f]+)$` (`test/lib/d6-snippet.bash:264`). P5 committed `scripts/questions.sh` as a symlink and got `refuse d6: scripts/questions.sh is not a regular file on main`, exit 2. In S1, T33's tamper shim produced the hash refusal.

**Evidence:** `test/lib/d6-snippet.bash:242-270`, `test/scripts/build-loop-orchestrator.bats:358-377`, `LOGS/probe5.log`, `LOGS/suite-orch.log`

---

## Claim 7: "a default branch that is not exactly one of refs/heads/main and master (not symbolic, a commit; origin/HEAD is left to the script's default_gate)"

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "a commit" atom: a refs/heads/main that names an annotated tag. It does not establish any harm beyond that. build-loop.sh's own default_gate still refuses such a ref; dev-cycle.sh has no default_gate (row 548).
**Legibility-target:** for-author

The snippet peels the ref instead of checking its own type: `sha="$(g rev-parse --verify -q "refs/heads/$m^{commit}")" || no "refs/heads/$m names no commit"` (`test/lib/d6-snippet.bash:256`). In P4, refs/heads/main was set to an annotated tag of main's commit (`type tag`). The snippet then ran dev-cycle.sh (`dev-cycle via snippet exit 0`). It ran build-loop.sh too, whose own default_gate refused (`refuse state default-branch: refs/heads/main names an object that is not a commit`, exit 2). So the snippet does not refuse a default branch that names a tag; it accepts any ref that peels to a commit. Either the note should say "peels to a commit", or the snippet should check `cat-file -t` the way default_gate does (row 656).

**Evidence:** `test/lib/d6-snippet.bash:253-256`, `scripts/build-loop.sh:586-590`, `LOGS/probe4.log`

---

## Claim 8: "In claude-workflows it extracts all four files with the same layout into one `mktemp -d`, checks all four hashes, runs main's copy with BASH_ENV, ENV and DEV_CYCLE_SCRUBBED unset, and removes the dir on exit."

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the extraction, the hash loop, the env unsets and cleanup on both success and refusal. It does not establish integrity of the tree the ids come from (see Claim 27).
**Legibility-target:** for-orchestrator-synthesis

`test/lib/d6-snippet.bash:258-270` does the mktemp, `trap 'rm -rf "$d"' EXIT`, the `scripts/lib` layout, the four `cat-file blob` writes and four `hash-object --no-filters` checks. `:276` is `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"`. In S1, T33 asserts that the lib is sourced from `$TMPDIR/*/scripts/lib/dev-cycle-read.sh` and that main's questions.sh answered. It also asserts that TMPDIR is empty after a run and after a refusal (`[ -z "$(ls -A "$TMPDIR")" ]`). In P2, the mutant with the hash check removed turned T33 red.

**Evidence:** `test/lib/d6-snippet.bash:257-277`, `test/scripts/build-loop-orchestrator.bats:341-364`, `LOGS/suite-orch.log`, `LOGS/probe2.log`

---

## Claim 9: "Elsewhere it runs `D6_OPT/scripts/SCRIPT` once the four files are regular, root-owned (`stat -c %u`), not symlinks and not writable (`-w`), and so is every directory from `scripts/lib` up to `/`"

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the checks on the four files and on the directory chain scripts/lib, scripts, /opt/claude-workflows, /opt and /. It does not establish the root case (Claim 10) or the order of checks against a racing writer.
**Legibility-target:** for-orchestrator-synthesis

`own() { [[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no ...; }` (`test/lib/d6-snippet.bash:244`). The file loop is at `:273`. The directory walk at `:274` is `x="$d/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done`, which checks `/` last. In S1, T37's real half ran against /opt/claude-workflows (not skipped) and matched the image copy's `--help`. Its uid-owned half refused. In P2, the mutant with `own` removed turned the uid-owned T37 test red.

**Evidence:** `test/lib/d6-snippet.bash:244`, `test/lib/d6-snippet.bash:271-275`, `LOGS/suite-orch.log`, `LOGS/probe2.log`

---

## Claim 10: "(it refuses when run as root, where `-w` always holds)"

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing executed: execution was required, and the review sandbox runs as uid 1000.
**Legibility-target:** for-orchestrator-synthesis

The code path exists: `own` requires `! -w "$1"` (`test/lib/d6-snippet.bash:244`). Paraphrased — no quote available because the claim is about kernel access semantics, not a snippet: bash's `-w` asks the kernel, which grants root write access to a mode-0555 directory on a writable filesystem. So under root the check should refuse. P1 confirmed only the non-root half (`-w` false on /opt for uid 1000). Running it as root would verify it, and a user namespace does not substitute, because root-owned files do not map into it.

**Evidence:** `test/lib/d6-snippet.bash:244`, `LOGS/probe1.log`

---

## Claim 11: "Its own git calls carry HARDEN's pairs as `-c` and git_harden's variables, a test pins the lists equal ... The snippet exports no pair, so `--state` through it passes caller_gate (row 702)."

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `g()` helper's pairs and variables, the test that pins them, and `--state` through the snippet. It does not establish that a future HARDEN edit cannot drift, beyond the pin turning red.
**Legibility-target:** for-orchestrator-synthesis

Every git call in the snippet goes through `g()` (`test/lib/d6-snippet.bash:243`); a grep of the file finds no bare `git` outside it. In S1, test 16 compares `g`'s `-c` list with H and its `GIT_*=` list with E, and checks that the lib exports exactly H and E (`test/scripts/build-loop-orchestrator.bats:412-422`). In P2, the mutant that drops `log.showSignature=false` from HARDEN turned test 16 red. In S1, T33 asserts `d6 build-loop.sh --state; [ "$status" -eq 0 ] && [ "$output" = ok ]` (`:354`).

**Evidence:** `test/lib/d6-snippet.bash:243`, `test/scripts/build-loop-orchestrator.bats:354`, `test/scripts/build-loop-orchestrator.bats:408-423`, `LOGS/suite-orch.log`, `LOGS/probe2.log`

---

## Claim 12: "Rows: 200 discharged (the lib is hash-checked with the scripts ...); 311 (git_harden's exact environment is pinned); 644/648 not moved (store_check: the digest re-hashes nothing, so its only caller stays build-loop.sh); ... T33's byte-equality half is a comment until U4 writes the SKILL.md block"

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each row's stated discharge mechanism. It does not establish that the ids the hash check compares against are genuine: main's tree objects are not re-hashed (P3, Claim 27).
**Legibility-target:** for-orchestrator-synthesis

Row 200 asked that the lib be hash-checked with the scripts in a fresh mktemp dir. `F=(build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh)` (`test/lib/d6-snippet.bash:248`) feeds the hash loop at `:268-270`. Row 311 is pinned by test 16 (S1), whose E list includes `GIT_NO_REPLACE_OBJECTS=1`. For rows 644/648, `store_check` appears in dev-cycle.sh and the lib only in a comment (`scripts/lib/dev-cycle-read.sh:334` `past build-loop.sh's store_check`); its definition and callers are all in build-loop.sh. T33's byte-equality half is the comment `# The SKILL.md block and test/lib/d6-snippet.bash are byte-equal (T33): pending until U4 writes the block.` (`test/scripts/build-loop-orchestrator.bats:363`).

**Evidence:** `test/lib/d6-snippet.bash:248-270`, `test/scripts/build-loop-orchestrator.bats:363`, `test/scripts/build-loop-orchestrator.bats:408-423`, `scripts/lib/dev-cycle-read.sh:334`, `LOGS/suite-orch.log`

---

## Claim 13: "The caller's global config, for merge_ident alone ... every other call reads none." (CALLER_GLOBAL now captured before `git_harden`)

**Location:** `scripts/build-loop.sh:489-491`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the capture order: line 491 runs before `git_harden` at line 495 overwrites GIT_CONFIG_GLOBAL. It does not re-establish merge_ident's own behaviour, which this diff does not change.
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:491` is `CALLER_GLOBAL=(-u GIT_CONFIG_GLOBAL); [[ -z "${GIT_CONFIG_GLOBAL+set}" ]] || CALLER_GLOBAL=("GIT_CONFIG_GLOBAL=$GIT_CONFIG_GLOBAL")`, and `:495` is `git_harden`. The only reader is `:1317` `x="$(env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var "GIT_${w}_IDENT" ...)"`.

**Evidence:** `scripts/build-loop.sh:489-495`, `scripts/build-loop.sh:1317`

---

## Claim 14: "Every git call in this process, the lib's included, runs hardened (the lib's git_harden ...)"

**Location:** `scripts/build-loop.sh:492-495`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the general case. It does not hold for two deliberate exceptions in this file, named elsewhere but not here.
**Legibility-target:** for-author

Two calls step outside it. caller_gate reads the caller's pairs with HARDEN's pairs dropped: `x="$(GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list --show-scope --name-only)"` (`scripts/build-loop.sh:562`). merge_ident restores the caller's global config (`:1317`, quoted in Claim 13). The comment just above (`:489-490`) names the merge_ident exception, and caller_gate's header (`:551-552`, "read with the caller's count") names the other. A precise version: "every git call but merge_ident's and caller_gate's config read". These exceptions predate the diff; the comment was rewritten here.

**Evidence:** `scripts/build-loop.sh:489-495`, `scripts/build-loop.sh:562`, `scripts/build-loop.sh:1317`

---

## Claim 15: Renamed comments: "git applies git -c pairs after git_harden's, so they win (a GIT_CONFIG_COUNT pair comes before git_harden's and loses, but is refused too)"; "git_harden switches off the multi-pack-index"; "the user's global ones included, which git_harden hides from the gate's own git"

**Location:** `scripts/build-loop.sh:551-555`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's ordering of git -c pairs against count pairs, and the presence of `core.multiPackIndex=false` and `core.attributesFile=/dev/null` in HARDEN. It does not re-verify the other unchanged renamed comments (`:497`, `:534`, `:1101`), which only change the function's name.
**Legibility-target:** for-orchestrator-synthesis

In P1, with a count pair `a.x=count` and `git -c a.x=param`, `git config --get a.x` printed `param`: git -c wins. A count pair `a.y=count` against repo config `a.y=repo` printed `count`. HARDEN includes both keys (`scripts/lib/dev-cycle-read.sh:346`). In P4, caller_gate refused a git -c HARDEN key (Claim 2). Context for the other two comments is at `scripts/build-loop.sh:939` and `:1110`.

**Evidence:** `scripts/build-loop.sh:551-555`, `scripts/build-loop.sh:939`, `scripts/build-loop.sh:1110`, `scripts/lib/dev-cycle-read.sh:346`, `LOGS/probe1.log`

---

## Claim 16: "Exit: ... 1 bad usage, a GIT_CONFIG_COUNT that is not plain decimal, not a git repo, ..."

**Location:** `scripts/dev-cycle.sh:84-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new exit-1 case. It does not re-verify the header's other, pre-existing exit cases.
**Legibility-target:** for-orchestrator-synthesis

In P1, `GIT_CONFIG_COUNT=010 bash scripts/dev-cycle.sh --check-path x` printed `dev-cycle.sh: GIT_CONFIG_COUNT is not a plain decimal count` and `dev-cycle exit 1`. The exit is git_harden's `exit 1` in the scrubbed child (`scripts/lib/dev-cycle-read.sh:350`), which the parent propagates through `exit "${PIPESTATUS[0]}"` (`:158`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:350`, `scripts/lib/dev-cycle-read.sh:155-159`, `LOGS/probe1.log`

---

## Claim 17: "Every git call from here on, the lib's and questions.sh's included, runs hardened, as build-loop.sh's do (... no hook, fsmonitor, replace ref, user or system config, or transport) ... File names are literal, not pathspecs." (and the removal of the old `export GIT_LITERAL_PATHSPECS=1`)

**Location:** `scripts/dev-cycle.sh:124-128`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git call after `:128`, including questions.sh run as a child (`bash "$QS" open`, `:405`) through the exported environment. GIT_LITERAL_PATHSPECS is now exported earlier than before (before `rev-parse --show-toplevel`), so every path that had it still has it. The comment does not mention the deliberate per-call `GIT_LITERAL_PATHSPECS=0` glob reads at `:146`, `:150` and lib `md_ls` (`scripts/lib/dev-cycle-read.sh:1597`), which predate the diff (main's dev-cycle.sh `:141`, `:145`).
**Legibility-target:** for-orchestrator-synthesis

In S1, test 17's shim found every logged call from `--check-brief` and the digest carrying all eight pairs plus `G=/dev/null P=none S=1`. In P2, the mutant that swaps in main's dev-cycle.sh (no `git_harden` call) turned test 17 red.

**Evidence:** `scripts/dev-cycle.sh:124-129`, `scripts/dev-cycle.sh:146-150`, `scripts/dev-cycle.sh:386-405`, `LOGS/suite-orch.log`, `LOGS/probe2.log`

---

## Claim 18: "build-loop.sh and dev-cycle.sh call it once, after scrub_reexec and before their first git call"

**Location:** `scripts/lib/dev-cycle-read.sh:327-328`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two scripts' top levels and the lib's source-time code, which makes no git call. It does not cover other callers, and none exist.
**Legibility-target:** for-orchestrator-synthesis

Grep finds exactly one `git_harden` call in each script (`scripts/build-loop.sh:495`, `scripts/dev-cycle.sh:128`). The order and the absence of git before each call are traced in Claim 1. Paraphrased — no quote available because the claim covers absence of code: the lib's top level holds only assignments and function definitions, and a grep for top-level `git` invocations outside function bodies found none.

**Evidence:** `scripts/build-loop.sh:441-495`, `scripts/dev-cycle.sh:100-128`, `scripts/lib/dev-cycle-read.sh:326-357`

---

## Claim 19: "git_harden: every later git call in this process and its children runs hardened"

**Location:** `scripts/lib/dev-cycle-read.sh:326-327`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the exported settings, which children inherit. It does not hold for the two build-loop.sh calls that deliberately override them (Claim 14).
**Legibility-target:** for-author

Same exceptions as Claim 14: `scripts/build-loop.sh:562` runs with `GIT_CONFIG_COUNT="$CALLER_COUNT"`, which drops HARDEN's pairs, and `:1317` restores the caller's GIT_CONFIG_GLOBAL. The lib header even names one consumer: "CALLER_COUNT keeps the caller's count for build-loop.sh's caller_gate" (`:341-342`). A precise version: "every later git call ... except where a caller deliberately overrides it (build-loop.sh's caller_gate and merge_ident)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:326-357`, `scripts/build-loop.sh:562`, `scripts/build-loop.sh:1317`

---

## Claim 20: "HARDEN's config pairs outrank the repo's config: main's own objects (core.useReplaceRefs there would override GIT_NO_REPLACE_OBJECTS) ... git log's own date format and no signature check (a bad log.date stops git log; log.showSignature runs gpg.program)."

**Location:** `scripts/lib/dev-cycle-read.sh:331-336`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers precedence of count pairs over repo config, the useReplaceRefs override, and the two log.* reasons. It does not re-execute the fsmonitor, hooks, commit-graph or multi-pack-index reasons, which predate the diff and are covered by existing tests.
**Legibility-target:** for-orchestrator-synthesis

P1 showed a count pair beating repo config. In P4, with a replace ref, `GIT_NO_REPLACE_OBJECTS=1 git cat-file blob` printed the original (`#!/bin/bash`). Adding repo `core.useReplaceRefs true` printed `replaced`, so the config does override the env. P2 confirmed the log.date and log.showSignature reasons on main's code (Claim 2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:331-336`, `LOGS/probe1.log`, `LOGS/probe4.log`, `LOGS/probe2.log`

---

## Claim 21: "GIT_ALLOW_PROTOCOL=none: no transport, so a lazy fetch (a partial clone's missing object) fails however its config was planted."

**Location:** `scripts/lib/dev-cycle-read.sh:337-339`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a file:// promisor remote under the lib's git_harden. It does not test other transports, which the same allow-list blocks.
**Legibility-target:** for-orchestrator-synthesis

In P6, after `source lib; git_harden`, `git cat-file blob` of a missing blob printed `fatal: transport 'file' not allowed` / `fatal: could not fetch ... from promisor remote` and exited 128. Without hardening, the same call lazily fetched it and printed `big`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:356`, `LOGS/probe6.log`

---

## Claim 22: "The caller's own pairs (git -c, GIT_CONFIG_COUNT) still apply, git -c ones after HARDEN's: CALLER_COUNT keeps the caller's count for build-loop.sh's caller_gate, which refuses a HARDEN key there by name."

**Location:** `scripts/lib/dev-cycle-read.sh:340-342`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ordering, CALLER_COUNT capture, and caller_gate's by-name refusal. It does not establish what happens to a caller who sets a HARDEN key by GIT_CONFIG_COUNT outside `--state` (that pair loses, per Claim 15).
**Legibility-target:** for-orchestrator-synthesis

`CALLER_COUNT="$c"` is set before the loop appends HARDEN (`scripts/lib/dev-cycle-read.sh:352-355`). In S1, test 16 printed `caller 1` for a caller count of 1, with HARDEN at indices 1-8. P1 showed the git -c ordering. P4 showed caller_gate's refusals (Claim 2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:348-357`, `scripts/build-loop.sh:562-569`, `LOGS/suite-orch.log`, `LOGS/probe1.log`, `LOGS/probe4.log`

---

## Claim 23: "A GIT_CONFIG_COUNT that is not plain decimal (010 reads as 8 here and as 10 to git) exits 1."

**Location:** `scripts/lib/dev-cycle-read.sh:342-344`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex, the exit, and both readings of 010. It does not establish other bash/git disagreements, such as a leading `+` or blanks, which the regex also refuses.
**Legibility-target:** for-orchestrator-synthesis

In P1, `$((010))` gave `8`. git with `GIT_CONFIG_COUNT=010` and keys 0-7 only failed with `error: missing config key GIT_CONFIG_KEY_8`, and with keys 0-9 it read `a.k9`, so git counts 10. The lib, dev-cycle.sh and build-loop.sh each exited 1 with the message `[[ "$c" =~ ^(0|[123456789][0123456789]*)$ ]] || { echo "${0##*/}: GIT_CONFIG_COUNT is not a plain decimal count" >&2; exit 1; }` (`:350`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:350`, `LOGS/probe1.log`

---

## Claim 24: "What these cannot switch off, build-loop.sh's state gate refuses."

**Location:** `scripts/lib/dev-cycle-read.sh:344-345`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers build-loop.sh's gated modes, where state_gate runs. It does not apply to dev-cycle.sh, which also calls git_harden but runs no state gate (settled override row 548, Q-103 residual).
**Legibility-target:** for-orchestrator-synthesis

The sentence names build-loop.sh's gate, which exists (`scripts/build-loop.sh:496-531`, the state_gate header "repo-local git state ... which git_harden does not switch off"). Paraphrased — no quote available because the claim covers absence of code: dev-cycle.sh has no state_gate or default_gate call (grep). A reader of the lib header who arrives from dev-cycle.sh may assume coverage that row 548 explicitly defers.

**Evidence:** `scripts/build-loop.sh:496-531`, `scripts/lib/dev-cycle-read.sh:344-345`

---

## Claim 25: "in claude-workflows (main's first-parent root commit is D6_ROOT)"; `D6_ROOT=640cf00735754d4253819a0354fb8ca9b71a8ea7`

**Location:** `test/lib/d6-snippet.bash:11-12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the constant against /workspace's main. It does not establish that no other repository shares that root, which a SHA-1 collision would require.
**Legibility-target:** for-orchestrator-synthesis

`git rev-list --first-parent --max-parents=0 main` in the worktree printed `640cf00735754d4253819a0354fb8ca9b71a8ea7`, and so did the full `--max-parents=0` (one root). The constant is at `test/lib/d6-snippet.bash:241`.

**Evidence:** `test/lib/d6-snippet.bash:241`, `test/lib/d6-snippet.bash:257` (command run in cwd `/workspace/.claude/wt-build-loop-u3b3` at 2026-10-13T01:05Z, exit 0, output quoted above)

---

## Claim 26: "T33 asserts the two match."

**Location:** `test/lib/d6-snippet.bash:9`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the present-tense test-coverage claim. It does not concern the plan, which correctly says the half is pending.
**Legibility-target:** for-author

T33 has no byte-equality assertion. The half is a comment: `# The SKILL.md block and test/lib/d6-snippet.bash are byte-equal (T33): pending until U4 writes the block.` (`test/scripts/build-loop-orchestrator.bats:363`). The plan says the same (`docs/working/plan-build-loop-handoff.md:325`, "T33's byte-equality half is a comment until U4 writes the SKILL.md block"). The header should say "T33 will assert (U4)", or it should be updated when U4 lands the block.

**Evidence:** `test/lib/d6-snippet.bash:9`, `test/scripts/build-loop-orchestrator.bats:341-364`

---

## Claim 27: "It trusts no file the uid can write: in claude-workflows ... it runs main's own scripts, extracted from main's commit into a fresh temp dir and hash-checked just before the run"

**Location:** `test/lib/d6-snippet.bash:10-14`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claude-workflows branch. The snippet trusts main's ref and the object store, both uid-writable. Tree and commit objects are never re-hashed, so the hash check verifies extraction against an id that a rewritten tree object supplies. It does not cover the separate fresh-temp-dir race (row 509, Q-103 class).
**Legibility-target:** for-author

The hash check compares the extracted bytes with the id that `ls-tree` read from main's tree: `x="$(g ls-tree --format='%(objectmode) %(objecttype) %(objectname)' "$sha" -- "scripts/$f")"` (`:263`), then `[[ "$(g hash-object --no-filters "$d/scripts/${F[i]}")" == "${ids[i]}" ]]` (`:269`). Nothing verifies that the commit or tree object's bytes hash to their own ids. P3 rewrote the loose object file of main's `scripts` tree in place, giving it the content of a tree whose `build-loop.sh` names a planted blob. main's ref and root were unchanged (`main still 4bbf4794... == root 4bbf4794...`). The snippet then ran the planted script: `PWNED-from-a-rewritten-tree-object`, exit 0. This is behavioural: the stated invariant does not hold against the threat model's same-uid writer of `.git`. The plan's U3a1 note records in-place object rewrites as a residual only for after store_check's startup re-hash, and the snippet has no such re-hash. Either the header should say what it does trust (main's ref and its objects, unverified), or the snippet should re-hash the commit and trees it walks.

**Evidence:** `test/lib/d6-snippet.bash:257-270`, `docs/working/plan-build-loop-handoff.md:317`, `LOGS/probe3.sh`, `LOGS/probe3.log`

---

## Claim 28: "hash-checked just before the run"

**Location:** `test/lib/d6-snippet.bash:13-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering: all four hashes are checked after extraction and immediately before `env ... bash`. It does not establish what the hashes are checked against (Claim 27) or the check-to-use gap in the temp dir (row 509).
**Legibility-target:** for-orchestrator-synthesis

The hash loop at `:268-270` is followed directly by `:276` `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"`. In S1, T33's tamper case refused (`refuse d6: the extracted scripts/build-loop.sh does not hash to main's copy`).

**Evidence:** `test/lib/d6-snippet.bash:268-277`, `LOGS/suite-orch.log`

---

## Claim 29: "in any other repository it runs the image copy under D6_OPT, by absolute path, once those files and every directory above them are root-owned, no symlink and not writable here."

**Location:** `test/lib/d6-snippet.bash:14-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 9: the four files and the directory chain up to `/`. It does not include the root case (Claim 10).
**Legibility-target:** for-orchestrator-synthesis

See Claim 9 for the quoted `own` and the walk (`:244`, `:273-274`). `d="$D6_OPT"` is absolute, and `:276` runs `"$d/scripts/$s"`. In S1, both T37 tests passed, the real half against /opt.

**Evidence:** `test/lib/d6-snippet.bash:244`, `test/lib/d6-snippet.bash:271-276`, `LOGS/suite-orch.log`

---

## Claim 30: "It never reads the working tree, ~/.claude/scripts or a replaced object."

**Location:** `test/lib/d6-snippet.bash:16-17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named sources. Its git calls read refs and objects only, and run with no replace refs, GIT_NO_REPLACE_OBJECTS=1 and core.useReplaceRefs=false. It does not cover the repository's own config and object store, which it does read (Claim 27).
**Legibility-target:** for-orchestrator-synthesis

The snippet's git subcommands are for-each-ref, rev-parse, show-ref, symbolic-ref, rev-list, ls-tree, cat-file and hash-object on temp files (`test/lib/d6-snippet.bash:249-269`). Paraphrased — no quote available because the claim covers absence of code: none of these reads the index or work tree, and the file never names `~/.claude`. In S1, T33 replaced every working-tree script with `exit 9`, and the snippet still ran main's copies. T36 refused blob and commit replace refs.

**Evidence:** `test/lib/d6-snippet.bash:243-276`, `test/scripts/build-loop-orchestrator.bats:348-370`, `LOGS/suite-orch.log`

---

## Claim 31: "Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout, with nothing run, for a replace ref, info/grafts, a default branch that is not exactly one plain main or master, a script on main that is not a regular file or whose extracted bytes do not hash to main's id, or an image copy that fails the ownership checks; 1 for another first argument."

**Location:** `test/lib/d6-snippet.bash:18-22`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the listed refusals and exit codes, which are correct (Claim 6). It does not hold as a complete list: other exit-2 refusals exist.
**Legibility-target:** for-author

Other `no` calls are not in the list: `refs/replace could not be listed` (`:249`), `the grafts path could not be read` (`:251`), `refs/heads/$m names no commit` (`:256`), `mktemp failed` (`:258`), `the temp dir could not be laid out` (`:260`), `scripts/$f could not be listed` (`:263`) and `scripts/$f could not be read from $m` (`:266`). "The script's own status" holds: `exit "$?"` (`:277`), and an EXIT trap that does not call exit keeps that status. A precise version adds "or a git read or temp-dir step that fails".

**Evidence:** `test/lib/d6-snippet.bash:242-277`

---

## Claim 32: "Its own git calls carry the lib's HARDEN pairs and git_harden's environment (a test pins the two lists equal)."

**Location:** `test/lib/d6-snippet.bash:23-24`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 11.
**Legibility-target:** for-orchestrator-synthesis

See Claim 11: in S1, test 16 passed, and in P2 a HARDEN mutant turned it red.

**Evidence:** `test/lib/d6-snippet.bash:243`, `test/scripts/build-loop-orchestrator.bats:408-423`, `LOGS/suite-orch.log`, `LOGS/probe2.log`

---

## Claim 33: "# d stays global: the EXIT trap reads it"

**Location:** `test/lib/d6-snippet.bash:245`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the declaration. It does not establish behaviour if `d` were made local.
**Legibility-target:** for-orchestrator-synthesis

`local s="${1:-}" F x m n sha ids f i` omits `d` (`:245`), and `trap 'rm -rf "$d"' EXIT` (`:259`) reads it. In S1, T33's empty-TMPDIR checks confirm the cleanup.

**Evidence:** `test/lib/d6-snippet.bash:245`, `test/lib/d6-snippet.bash:258-259`

---

## Claim 34: "Under bash -s the script is the heredoc on stdin: bash has read this whole line before it runs, and no child reads the rest of it."

**Location:** `test/lib/d6-snippet.bash:279-281`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `bash -s -- SCRIPT ARG...` with stdin from a file and from a pipe. It does not exercise the literal `<<'D6'` heredoc inside SKILL.md, which U4 writes.
**Legibility-target:** for-orchestrator-synthesis

`d6 "$@" </dev/null` (`:281`). In P4, both `bash -s -- build-loop.sh --settings < d6.bash` and `cat d6.bash | bash -s -- build-loop.sh --settings` printed the full five-line `--settings` output and exited 0. The repo's tests run the file only as `bash "$D6"`, so this form was otherwise untested.

**Evidence:** `test/lib/d6-snippet.bash:279-281`, `LOGS/probe4.log`

---

## Claim 35: "# Not log.date: git_harden's log.date pair overrides it (row 505); a bad boolean still stops git log."

**Location:** `test/scripts/build-loop-check.bats:1660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers log.abbrevCommit=bogus stopping the reads, and log.date being overridden. It does not cover other log.* keys.
**Legibility-target:** for-orchestrator-synthesis

In S1, the row-307 test passed with `git config log.abbrevCommit bogus` and its expected skip lines. In S1, test 17 shows that log.date=bogus no longer stops `--check-brief`.

**Evidence:** `test/scripts/build-loop-check.bats:1658-1666`, `LOGS/suite-check307.log`, `LOGS/suite-orch.log`

---

## Claim 36: "every git call --check makes carries git_harden's config pairs (core.hooksPath=/dev/null among them), no global or system config and no transport (T26, ...)"

**Location:** `test/scripts/build-loop-check.bats:1688`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the calls the shim logs (git through PATH). It does not cover a git reached by absolute path; grep finds none in the scripts.
**Legibility-target:** for-orchestrator-synthesis

The loop now includes `log.date=default log.showSignature=false` (`:1699`). In S1 the test passed.

**Evidence:** `test/scripts/build-loop-check.bats:1688-1701`, `LOGS/suite-check307.log`

---

## Claim 37: "# A plain caller pair passes; a count harden would misread stops every mode (row 276)."

**Location:** `test/scripts/build-loop-orchestrator.bats:50`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the function name only. The behaviour the comment describes holds (Claim 23).
**Legibility-target:** for-author

`harden` no longer exists. The function is `git_harden` in the lib (`scripts/lib/dev-cycle-read.sh:348`), and this diff renamed every other code comment's `harden` reference (diff lines 58-115). A grep for a bare `harden` in `scripts/` and `test/` finds only this line. It should read "a count git_harden would misread".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:50`, `scripts/lib/dev-cycle-read.sh:348`

---

## Claim 38: "d6_copy ROOT OPT: D6, a copy of test/lib/d6-snippet.bash with D6_ROOT and D6_OPT replaced. d6_setup: main holds this branch's four scripts, and D6 takes this fixture's root commit as claude-workflows' own."

**Location:** `test/scripts/build-loop-orchestrator.bats:323-330`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helpers' effect. It does not cover the d6_copy sed matching a reformatted D6_ROOT line, which its `grep -qxF` guard would fail on.
**Legibility-target:** for-orchestrator-synthesis

`sed "s|^  D6_ROOT=.*; D6_OPT=.*|  D6_ROOT=$1; D6_OPT=$2|" ... ; grep -qxF "  D6_ROOT=$1; D6_OPT=$2" "$D6"` (`:326`). `d6_setup` copies the four scripts, runs `commit_all`, and calls `d6_copy "$(git rev-list --max-parents=0 main)" /opt/claude-workflows` (`:328-329`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:323-331`

---

## Claim 39: T33 test name: "the D6 snippet runs main's four scripts from a fresh temp dir, each with its own lib and questions.sh, never the working tree's, and removes the dir", and the in-test comments ("An extracted file whose bytes differ from main's id is never run: a git that appends to every blob it prints"; "The snippet exports no config pair, so --state run through it passes caller_gate")

**Location:** `test/scripts/build-loop-orchestrator.bats:341-364`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts and that the asserts discriminate: a mutant without the hash check turns it red. It does not cover the byte-equality half (Claim 26).
**Legibility-target:** for-orchestrator-synthesis

The asserts are the lib path under `$TMPDIR` (`:352`), main's questions.sh's `from-main` entry (`:356`), `--state` printing `ok` (`:354`), an empty TMPDIR (`:357`, `:362`) and the tamper refusal (`:361`). In S1 the test passed, and in P2 the hash-removed mutant turned it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:341-364`, `LOGS/suite-orch.log`, `LOGS/probe2.log`

---

## Claim 40: T36 test name: "the D6 snippet refuses before running anything: a blob or commit replace ref, info/grafts, not exactly one plain main or master"

**Location:** `test/scripts/build-loop-orchestrator.bats:366-377`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed cases. It does not cover a tag-named main (Claim 7) or neither branch existing, both untested.
**Legibility-target:** for-orchestrator-synthesis

`d6_is` asserts exit 2, the one line and empty stderr, so nothing ran. In S1 the test passed.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:333`, `test/scripts/build-loop-orchestrator.bats:366-377`, `LOGS/suite-orch.log`

---

## Claim 41: T27 test name: "a gate copy patched in the loop's worktree prints ok for its tip; the D6 snippet's copy from main refuses the same tip"

**Location:** `test/scripts/build-loop-orchestrator.bats:379-390`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one patched rule (the mode/symlink rule) and the snippet run from the worktree. It does not cover other patched rules.
**Legibility-target:** for-orchestrator-synthesis

The patched copy asserts `ok $B`, and through the snippet the result is `refuse $B: 1 of 2 changed paths refused ...` with the symlink deny line (`:386-389`). In S1 the test passed.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:379-390`, `LOGS/suite-orch.log`

---

## Claim 42: T37 test names: "outside claude-workflows the D6 snippet runs the image copy by absolute path, not main's copy" / "... refuses an image copy the uid owns, and never runs main's"

**Location:** `test/scripts/build-loop-orchestrator.bats:392-406`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both halves. The first ran against the real root-owned /opt here rather than skipping. "never runs main's" is asserted through `d6_is`'s single-line stdout and empty stderr, so `echo main copy` did not run. It does not assert "by absolute path", which comes from reading the code (Claim 29).
**Legibility-target:** for-orchestrator-synthesis

The asserts are `[ "$output" = "$(bash "$O/scripts/build-loop.sh" --help)" ]` (`:397`) and `d6_is "refuse d6: $U/scripts/build-loop.sh is not root-owned, a plain path and unwritable here"` (`:405`). In S1 both were ok (tests 14, 15). In P2, the own-removed mutant turned test 15 red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:392-406`, `LOGS/suite-orch.log`, `LOGS/probe2.log`

---

## Claim 43: Test names: "git_harden exports HARDEN's pairs after the caller's and a fixed environment; the D6 snippet's git carries the same" / "every git call dev-cycle.sh makes carries git_harden's pairs: a bogus log.date stops nothing, log.showSignature runs no gpg.program"

**Location:** `test/scripts/build-loop-orchestrator.bats:408-441`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what each test asserts and that mutants turn both red. It does not cover git calls not made through PATH.
**Legibility-target:** for-orchestrator-synthesis

In S1 both passed. In P2, the mutant that drops `log.showSignature=false` turned both red (test 17 reported `gpg.program ran`), and the main's-dev-cycle.sh mutant turned test 17 red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:408-441`, `LOGS/suite-orch.log`, `LOGS/probe2.log`

---

## Claim 44: Commit 9925f2a7: "Moves build-loop.sh's harden, HARDEN and its environment exports into the lib as git_harden (rows 281, 495), with the trust model stated once. dev-cycle.sh now calls it before its first git call ... HARDEN gains log.date=default (row 505: a bogus log.date stopped --check-brief) and log.showSignature=false (git log would run gpg.program)."

**Location:** commit 9925f2a7 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the move and both pre-fix reasons. It does not cover the Notes line (Claim 45).
**Legibility-target:** for-orchestrator-synthesis

The diff removes `harden`/`HARDEN`/exports from build-loop.sh (diff lines 22-51) and adds them to the lib (`scripts/lib/dev-cycle-read.sh:326-357`). P2 confirmed the pre-fix reasons on main's code (Claim 2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:326-357`, `scripts/build-loop.sh:489-495`, `LOGS/probe2.log`

---

## Claim 45: Commit 9925f2a7 Notes: "dev-cycle.sh now reads no user or system git config, like build-loop.sh; a host repo that needs a global safe.directory would stop."

**Location:** commit 9925f2a7 message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The first half is verified (Claim 3). The safe.directory consequence would need a repository owned by another uid, which uid 1000 cannot create here.
**Legibility-target:** for-orchestrator-synthesis

Paraphrased — no quote available because the claim depends on git's ownership check, which is not in this repo. git honours `safe.directory` only from system, global or command-line config, and GIT_CONFIG_GLOBAL=/dev/null with GIT_CONFIG_NOSYSTEM=1 removes the first two (`scripts/lib/dev-cycle-read.sh:356`). The consequence is plausible. Running dev-cycle.sh on a repository owned by another uid would verify it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:356`

---

## Claim 46: Commit a0014ce5: "Mutants checked: hash check removed, ownership check removed, log.showSignature pair removed, main's dev-cycle.sh: each turns a test red."

**Location:** commit a0014ce5 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four mutants as P2 built them. "main's dev-cycle.sh" was read as "main's pre-U3b3 dev-cycle.sh, with no git_harden call". It does not establish which mutant the author ran when the wording allows another reading.
**Legibility-target:** for-orchestrator-synthesis

P2 results: the hash-removed mutant made T33 `not ok`. The own-removed mutant made the uid-owned T37 `not ok`. The showSignature-removed mutant made test 17 `not ok` (`gpg.program ran`) and test 16 `not ok`. main's dev-cycle.sh made test 17 `not ok`.

**Evidence:** `LOGS/probe2.sh`, `LOGS/probe2.log`

---

## Claim 47: Commit a0014ce5: "dev-cycle.sh's calls hardened (rows 495, 505: a planted log.showSignature ran gpg.program on main)"

**Location:** commit a0014ce5 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's pre-U3b3 digest under a planted log.showSignature with a gpgsig-headed commit on main. It does not cover other gpg-invoking keys, which the state gate lists for build-loop.sh only.
**Legibility-target:** for-orchestrator-synthesis

In P2, main's scripts gave `GPG RAN (status 0)`.

**Evidence:** `LOGS/probe2.log`

---

## Claim 48: Commit a0014ce5: "T33 (own lib and questions.sh, working tree ignored, temp dir removed, a tampered extraction refused, --state passes; the SKILL.md byte-equality half waits for U4), T36, T37 (the real /opt half skips without a root-owned image copy) ... children's stdin cut from the heredoc"

**Location:** commit a0014ce5 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed T33 assert, T37's skip guard and the `</dev/null`. It does not cover the skip path itself, since /opt exists here, so the real half ran.
**Legibility-target:** for-orchestrator-synthesis

T33's asserts are listed in Claim 39. T37's guard is `[[ -f "$O/scripts/build-loop.sh" && "$(stat -c %u "$O/scripts")" == 0 ]] || skip ...` (`test/scripts/build-loop-orchestrator.bats:394`). `d6 "$@" </dev/null` is at `test/lib/d6-snippet.bash:281`. S1 passed.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:341-398`, `test/lib/d6-snippet.bash:281`, `LOGS/suite-orch.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`docs/working/plan-build-loop-handoff.md:325`): "(not symbolic, a commit)". The snippet peels `refs/heads/$m^{commit}` and accepts a main that names an annotated tag (P4). It then ran dev-cycle.sh; build-loop.sh's default_gate refused on its own. Behavioural doc-vs-code: fix the wording to "peels to a commit", or check the ref's own type as default_gate does.
- **Claim 26** (`test/lib/d6-snippet.bash:9`): "T33 asserts the two match". T33 holds only a pending comment (`build-loop-orchestrator.bats:363`). Comment-only, about test coverage.
- **Claim 27** (`test/lib/d6-snippet.bash:10-14`): "It trusts no file the uid can write". The snippet trusts main's ref and the object store without re-hashing commit or tree objects. A tree object rewritten in place made the snippet run a planted build-loop.sh with main's ref unchanged (P3). Behavioural/security: the header's invariant is false against the threat model's `.git` writer.

### Stale
- **Claim 37** (`test/scripts/build-loop-orchestrator.bats:50`): "a count harden would misread". The function is now `git_harden`. Comment-only.

### Mostly Accurate
- **Claim 4** (`docs/working/plan-build-loop-handoff.md:325`, commit a0014ce5): "a bash script body, not a function". The file defines `d6()` and calls it. The point is that the caller's shell defines no function. Doc-only.
- **Claim 14** (`scripts/build-loop.sh:492`): "Every git call in this process ... runs hardened". It omits caller_gate's CALLER_COUNT read (`:562`) and merge_ident's CALLER_GLOBAL (`:1317`). Comment-only.
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:326`): "every later git call in this process and its children runs hardened". Same two build-loop.sh exceptions. Comment-only.
- **Claim 31** (`test/lib/d6-snippet.bash:18-22`): the Exit list omits the exit-2 refusals for "names no commit" and for git-read and temp-dir failures. Comment-only.

### Unverifiable
- **Claim 5** (`docs/working/plan-build-loop-handoff.md:325`): the zsh alias `g` incident needs the original session transcript.
- **Claim 10** (`docs/working/plan-build-loop-handoff.md:325`): "refuses when run as root" needs execution as root.
- **Claim 45** (commit 9925f2a7): the global safe.directory consequence needs a repository owned by another uid.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/code-fact-check-report-2026-10-12-u3b3-i1.md, structured per the code-fact-check skill.
- Answered: yes. All seven brief focus areas were checked; the orchestrator suite and the touched check tests were run (17/17, 2/2); every executable claim was executed (P1-P6, S1).
- Out of scope: security judgement of Claim 27's finding (left to security-reviewer); docs/reviews/hallucination-patterns.md not edited (write-only-own-report rule; no fabrication found anyway).
- Escalate: Claim 27. The D6 snippet runs a planted script from a tree object rewritten in place (P3). No override row covers it; the U3a1 note treats in-place rewrites as a residual only after store_check's re-hash, and the snippet has none. Security should decide whether this is a Must Fix or a Q-103 residual. Also Claim 7 (a tag-named main accepted by the snippet).
- Decisions I made: I read "main's dev-cycle.sh" in a0014ce5's mutant list as main's pre-U3b3 dev-cycle.sh; I kept probe logs in the session scratchpad, not in the worktree's docs/reviews/execution-logs, to honour the write-only-your-report rule.
