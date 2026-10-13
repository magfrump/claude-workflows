Commit: 5d175c0e

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b3 (branch `feat/build-loop-u3b3`)
**Scope:** branch diff `main...5d175c0e` (docs/reviews/ excluded): `docs/working/plan-build-loop-handoff.md` (U3b3 as-built note), `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `test/lib/d6-snippet.bash`, `test/scripts/build-loop-check.bats`, `test/scripts/build-loop-orchestrator.bats`, and the messages of 9925f2a7, a0014ce5, d9515d09 (7a927183 and 5d175c0e carry no checkable claim beyond their subjects)
**Checked:** 2026-10-12
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 57
**Summary:** 49 verified, 5 mostly accurate, 0 stale, 0 incorrect, 3 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): no claim below matches a logged pattern, and no fabricated symbol was found, so the log is not edited (and the brief allows writing only this file).

**Iteration 1 fixes (A1-A7).** All hold. A1: the snippet now re-hashes main's first-parent commits and the three trees (Claims 30b, 36; tests 13 and 14 pass; a second, forged copy of a packed tree is ignored by both the re-hash and ls-tree, P2/P3). A2: the ref's own type is checked (Claim 54). The i1 text items (i1 Claims 14, 19, 26, 31, 37) are fixed (Claims 16, 21, 29, 40). No fix re-fires. One gap is new in A1's text: the Exit list now says "a git read ... that fails" refuses, but the one read that picks the branch does not (Claims 7, 33).

**Execution provenance (shared by every `executed` claim).** All runs were as uid 1000, with git 2.39.5, GNU bash 5.2.15 and `LC_ALL=C`. Every probe script starts with `set -eu`, makes its own `mktemp -d /tmp/u3b3-fc2-pN-XXXX`, refuses to go on outside it, and removes it; none was left behind. Scripts and captured output are in `/tmp/claude-1000/-workspace/c69d4d0f-5190-473b-ba2f-85b5a43f49ee/scratchpad/fc2-i2/`, called `LOGS/` below.
- **S1**: `bats test/scripts/build-loop-orchestrator.bats`, cwd `/workspace/.claude/wt-build-loop-u3b3`, with its own TMPDIR `/tmp/u3b3-fc2-bats-XXXX`, at 2026-10-13T01:20:57Z, exit 0. Result: 19/19 ok. Test 16 (T37's real /opt half) ran and did not skip (`LOGS/bats-orch.log`).
- **P1**: `bash LOGS/probe1.sh`, 2026-10-13T01:21:14Z, exit 0 (`LOGS/probe1.log`). It checked these git semantics: repo `core.useReplaceRefs=true` against `GIT_NO_REPLACE_OBJECTS=1`; a repo `log.date=bogus` with and without a count pair; the order of a count pair against `git -c`; `GIT_CONFIG_COUNT=010`; and `log.abbrevCommit=bogus`.
- **P2**: `bash LOGS/probe2.sh`, 2026-10-13T01:22:13Z, exit 0 (`LOGS/probe2.log`). It ran the snippet under `bash -s` from a file, a pipe and a quoted heredoc, with main's script reading stdin. It ran the snippet with the root commit's loose object removed. It ran the snippet with a loose forged copy of a packed `scripts` tree.
- **P3**: `bash LOGS/probe3.sh`, 2026-10-13T01:22:34Z, exit 0 (`LOGS/probe3.log`). It ran a0014ce5's four mutants against private copies of `scripts/` and `test/`, with `bats -f`.
- **P4**: `bash LOGS/probe4.sh`, 2026-10-13T01:22:48Z, exit 0 (`LOGS/probe4.log`). It ran dev-cycle.sh with `GIT_CONFIG_COUNT` set to 010, 08 and 1x. It ran `bats -f 'row 307, U2b1a1|T26, A4' test/scripts/build-loop-check.bats` (2/2 ok).
- **P5**: `bash LOGS/probe5.sh`, 2026-10-13T01:24:20Z, exit 0 (`LOGS/probe5.log`). It counted main's first-parent commits, read the D6 root, and timed the re-hash pipeline against /workspace's object store (read-only).

---

## Claim 1: "`git_harden` (lib) holds HARDEN, CALLER_COUNT and the environment build-loop.sh exported ... build-loop.sh and dev-cycle.sh call it after scrub_reexec, before their first git call."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the function sets and where both scripts call it. It does not establish that no later call overrides those settings (Claim 16 covers that).
**Legibility-target:** for-orchestrator-synthesis

The function sets `CALLER_COUNT="$c"` and exports the pairs and `GIT_CONFIG_COUNT="$c" GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none` (`scripts/lib/dev-cycle-read.sh:350-359`, read to its closing brace). That is the set removed from build-loop.sh (diff: `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 ...`). build-loop.sh runs `source "$READ_LIB"` and `scrub_reexec "${BASH_SOURCE[0]}" "$@"` (`scripts/build-loop.sh:441-442`), then the mode `case` (`:444-487`, which runs no git; `-h` uses sed), then `git_harden` (`:496`). dev-cycle.sh runs `source`/`scrub_reexec` (`scripts/dev-cycle.sh:100-101`), then the arg loop (`:107-121`, no git), then `git_harden` (`:128`), then its first git call, `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"` (`:129`). The lib runs no git at source time (paraphrased — no quote available because this is a claim about absence: a grep of the lib's top-level lines finds only assignments and function definitions). scrub_reexec's parent process re-runs the script and exits (`scripts/lib/dev-cycle-read.sh:155-160`, `exit "${PIPESTATUS[0]}"`), so only the child reaches git_harden, and the parent makes no git call.

**Evidence:** `scripts/lib/dev-cycle-read.sh:155-160`, `scripts/lib/dev-cycle-read.sh:348-359`, `scripts/build-loop.sh:431-496`, `scripts/dev-cycle.sh:88-129`

---

## Claim 2: "HARDEN gains `log.date=default` (row 505: a bogus log.date stopped --check-brief) and `log.showSignature=false` (a planted one made the digest's git log run gpg.program on main); caller_gate refuses both keys by name with the rest."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HARDEN's two new pairs, their effect on dev-cycle.sh's --check-brief and digest, and caller_gate looping over HARDEN. It does not establish gpg.program behaviour for a git newer than 2.39.5.
**Legibility-target:** for-orchestrator-synthesis

`HARDEN=(... log.date=default log.showSignature=false)` (`scripts/lib/dev-cycle-read.sh:348`). caller_gate refuses by looping over the whole list: `for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done` (`scripts/build-loop.sh:566`). Override row 505 reads "Under log.date bogus `dev-cycle.sh --check-brief` exits 128 with no line" (`docs/reviews/override-log.md:505`). Test 19 (`build-loop-orchestrator.bats:355`) passes in S1, with log.date bogus, log.showSignature true and a gpg.program that records running. In P3's mutant M3b, `log.showSignature=false` was removed from HARDEN and the per-call pair check was relaxed in a private copy of the test. The test then failed on `[ ! -e "$BATS_TEST_TMPDIR/gpg-ran" ]` with the output "gpg.program ran", so the planted setting did run gpg.program on main's commit.

**Evidence:** `scripts/lib/dev-cycle-read.sh:348`, `scripts/build-loop.sh:558-570`, `docs/reviews/override-log.md:505`, `test/scripts/build-loop-orchestrator.bats:355-371`, `LOGS/bats-orch.log`, `LOGS/probe3.log`

---

## Claim 3: "dev-cycle.sh now reads no user or system git config."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every git call after `git_harden` in dev-cycle.sh, the lib and questions.sh (children inherit the exports). It does not cover the scrub_reexec parent, which makes no git call.
**Legibility-target:** for-orchestrator-synthesis

`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` are exported (`scripts/lib/dev-cycle-read.sh:358`), and git_harden runs before the first git call (`scripts/dev-cycle.sh:128-129`). None of dev-cycle.sh, the lib or questions.sh overrides either variable (paraphrased — no quote available because this is a claim about absence: grepping the three files for `env -u`, `env -i`, `GIT_CONFIG_GLOBAL=` and `unset GIT` finds only the lib's export and a perl `env -u PERL_UNICODE` line).

**Evidence:** `scripts/lib/dev-cycle-read.sh:358`, `scripts/dev-cycle.sh:128-129`, `scripts/questions.sh:80-84`

---

## Claim 4: "`test/lib/d6-snippet.bash` is a script bash reads, not a function pasted into the caller's shell (its `d6` function lives only in that bash) ... U4's SKILL.md feeds the file ... to `bash -s -- SCRIPT ARG... <<'D6'`, and the snippet runs everything with stdin from /dev/null."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `bash -s` form fed from a file, a pipe and a quoted heredoc, and children's stdin. It does not establish how the Bash tool's zsh treats the heredoc (Claim 5).
**Legibility-target:** for-orchestrator-synthesis

The last line is `d6 "$@" </dev/null` (`test/lib/d6-snippet.bash:79`). In P2, main's build-loop.sh was `x="$(cat)"; echo "child stdin bytes: ${#x}"`. The snippet fed through `bash -s -- build-loop.sh < file`, through `cat file | bash -s ...` and through `<<'D6'` printed `child stdin bytes: 0` and `rc=0` each time, and left no temp dir behind.

**Evidence:** `test/lib/d6-snippet.bash:77-79`, `LOGS/probe2.log`

---

## Claim 5: "the Bash tool's shell can be zsh (an alias `g` broke a pasted function)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the record that the incident happened. It does not establish the alias's source or that zsh is the only failing shell.
**Legibility-target:** for-orchestrator-synthesis

This is a historical incident from an earlier session. Checking it needs that session's transcript (paraphrased — no quote available because the claim is about a past runtime event, not about code). Under the `bash -s` form a non-interactive bash expands no alias, so the stated motive is consistent with the design.

**Evidence:** `docs/working/plan-build-loop-handoff.md:326`

---

## Claim 6: "It refuses with one `refuse d6: WHY` line on stdout and exit 2, nothing run, for a replace ref, info/grafts, a default branch that is not exactly one of refs/heads/main and master (not symbolic; the ref's own object a commit, not peeled from a tag ...), an object that does not hash to its id (...), a script on main that is not mode 100644/100755, ... or extracted bytes that do not hash (`hash-object --no-filters`) to main's id; exit 1 for another first argument."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal except "a failed git read or temp-dir step", which is split out as Claim 7. It does not establish the mode-check message for a script missing from main (it refuses with "is not a regular file").
**Legibility-target:** for-orchestrator-synthesis

Each refusal is the code's: `no() { echo "refuse d6: $*"; exit 2; }` (`test/lib/d6-snippet.bash:33`). The checks are `[[ -z "$x" ]] || no "a replace ref exists (F38)"` (`:41`), `[[ ! -e "$x" && ! -L "$x" ]] || no "info/grafts exists (F38)"` (`:43`), the main/master count and the symbolic-ref check (`:44-46`), and `[[ "$(g cat-file -t "$sha")" == commit ]] || no` (`:47`). The mode check is `[[ "$x" =~ ^100(644|755)\ blob\ ([0-9a-f]+)$ ]] || no` (`:62`), and the hash check is `[[ "$(g hash-object --no-filters ...)" == "${ids[i]}" ]] || no` (`:67`). A bad first argument prints to stderr and runs `exit 1` (`:37`). In S1, tests 12 (replace refs, grafts, two branches, symbolic, a tag-named main, `x` giving exit 1), 13 and 14 (the in-place rewrites), and 11's tamper half all pass.

**Evidence:** `test/lib/d6-snippet.bash:30-76`, `test/scripts/build-loop-orchestrator.bats:245-307`, `LOGS/bats-orch.log`

---

## Claim 7: "... a failed git read or temp-dir step ..." (among the refusals: exit 2, nothing run)

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git read in the snippet. It does not establish whether the fallthrough described below is acceptable; that is a security judgement (escalated).
**Legibility-target:** for-author

Most reads refuse when they fail (`|| no ...` at `test/lib/d6-snippet.bash:40, 42, 47, 55, 56, 58, 61, 64`). The root check does not: `if [[ "$(g rev-list --first-parent --max-parents=0 "$sha")" == "$D6_ROOT" ]]; then` (`:48`). A failed rev-list yields empty output, which takes the `else` branch and runs the image copy. In P2, a claude-workflows-shaped fixture had its root commit's loose object removed. rev-list then failed (`rc=128`, "fatal: Failed to traverse parents of commit ..."), and the snippet exited 0 after running `/opt/claude-workflows/scripts/build-loop.sh --settings` (it printed "slots 3 default: ..."), with no `refuse d6:` line. The precise version is: "a failed git read or temp-dir step, except the root check, whose failure selects the image copy".

**Evidence:** `test/lib/d6-snippet.bash:48`, `test/lib/d6-snippet.bash:70-74`, `LOGS/probe2.log` (section P2)

---

## Claim 8: "In claude-workflows it extracts all four files with the same layout into one `mktemp -d`, checks all four hashes, runs main's copy with BASH_ENV, ENV and DEV_CYCLE_SCRUBBED unset, and removes the dir on exit."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the extraction path and the cleanup on a normal or refused exit. It does not establish cleanup when the snippet is killed by SIGKILL.
**Legibility-target:** for-orchestrator-synthesis

The code is `d="$(mktemp -d)"`, then `trap 'rm -rf "$d"' EXIT`, then `mkdir "$d/scripts" "$d/scripts/lib"` (`test/lib/d6-snippet.bash:56-58`). It extracts all four files, then checks all four hashes (`:60-68`), and runs `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"` (`:74`). In S1, test 11 shows main's lib sourced from `$TMPDIR/*/scripts/lib/dev-cycle-read.sh`, and `$TMPDIR` empty afterwards, after a run and after a refusal.

**Evidence:** `test/lib/d6-snippet.bash:56-75`, `test/scripts/build-loop-orchestrator.bats:245-268`, `LOGS/bats-orch.log`

---

## Claim 9: "Elsewhere it runs `D6_OPT/scripts/SCRIPT` once the four files are regular, root-owned (`stat -c %u`), not symlinks and not writable (`-w`), and so is every directory from `scripts/lib` up to `/`."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the checks and the directory walk. It does not establish that the checks still hold at exec time (a root-owned tree is outside the uid's reach, so no race applies).
**Legibility-target:** for-orchestrator-synthesis

The ownership test is `own() { [[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no ...; }` (`test/lib/d6-snippet.bash:35`). The checks are `for f in "${F[@]}"; do own "$d/scripts/$f"; [[ -f "$d/scripts/$f" ]] || no ...; done` (`:71`) and the walk `x="$d/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done` (`:72`). The walk checks `scripts/lib`, `scripts`, D6_OPT, its parents and `/`. In S1, test 17 (a uid-owned copy refused) and test 16 (the real root-owned /opt copy run) pass. In P3, mutant M2 (`own() { :; }`) turns test 17 red.

**Evidence:** `test/lib/d6-snippet.bash:35`, `test/lib/d6-snippet.bash:70-72`, `LOGS/bats-orch.log`, `LOGS/probe3.log`

---

## Claim 10: "(it refuses when run as root, where `-w` always holds)"

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing executed. It does not establish root behaviour on a read-only mount.
**Legibility-target:** for-orchestrator-synthesis

Execution is required and is blocked: the probes run as uid 1000, and root is not available. One caveat comes from static reading only (paraphrased — no quote available because it concerns bash's and the kernel's access check, not repository code). bash's `-w` uses an effective-access check, and for root that check fails with EROFS on a read-only filesystem. So "always" holds only where D6_OPT is on a writable mount. Here /opt is on the container's writable overlay (`/proc/mounts` shows no read-only /opt), so the claim would hold in this image.

**Evidence:** `test/lib/d6-snippet.bash:35`, `/proc/mounts`

---

## Claim 11: "Its own git calls carry HARDEN's pairs as `-c` and git_harden's variables, a test pins the lists equal (the snippet cannot source the lib before checking it)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the snippet's `g` wrapper and test 18's comparison. It does not establish that the pairs' order matches HARDEN's order beyond what the test compares (it compares the ordered `-c` list).
**Legibility-target:** for-orchestrator-synthesis

Every git call in the snippet goes through `g() { GIT_NO_REPLACE_OBJECTS=1 ... git -c core.useReplaceRefs=false ... -c log.showSignature=false "$@"; }` (`test/lib/d6-snippet.bash:34`; there is no bare `git` elsewhere in the file). Test 18 compares the lib's HARDEN and its exported environment, and the `g` line's `-c` list and `GIT_*=` list, with the same literals H and E (`test/scripts/build-loop-orchestrator.bats:342-353`). It passes in S1.

**Evidence:** `test/lib/d6-snippet.bash:34`, `test/scripts/build-loop-orchestrator.bats:338-353`, `LOGS/bats-orch.log`

---

## Claim 12: "The snippet exports no pair, so `--state` through it passes caller_gate (row 702)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the snippet's own environment. It does not establish an orchestrator environment free of pairs (U4's job).
**Legibility-target:** for-orchestrator-synthesis

The snippet passes its pairs only as `-c` arguments inside `g` and has no `export` (`test/lib/d6-snippet.bash:34`). It runs the script through `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED` alone (`:74`). In S1, test 11's `d6 build-loop.sh --state` gives `ok`, exit 0.

**Evidence:** `test/lib/d6-snippet.bash:34`, `test/lib/d6-snippet.bash:74`, `test/scripts/build-loop-orchestrator.bats:258`, `LOGS/bats-orch.log`

---

## Claim 13: "Rows: 200 discharged (the lib is hash-checked with the scripts ...); 311 (git_harden's exact environment is pinned); 644/648 not moved (store_check: the digest re-hashes nothing, so its only caller stays build-loop.sh); 666 no change (row 709's reasons)."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's stated condition against the code. It does not establish that the override log itself was updated (that is outside this diff).
**Legibility-target:** for-orchestrator-synthesis

Row 200 asks that the snippet "must hash-check the lib with the scripts and extract into a fresh mktemp dir" (`docs/reviews/override-log.md:200`). F includes `lib/dev-cycle-read.sh` (`test/lib/d6-snippet.bash:39`), and every extracted file is hash-checked (`:66-68`). Row 311 says GIT_NO_REPLACE_OBJECTS "can be dropped with no test failing". Test 18 now compares the exact environment, `GIT_NO_REPLACE_OBJECTS=1` included (`test/scripts/build-loop-orchestrator.bats:343`). For rows 644/648, store_check is defined and called only in build-loop.sh (`scripts/build-loop.sh:951`, `:1203`, `:1276`). Row 666's reasons are those in row 709 (`docs/reviews/override-log.md:709`).

**Evidence:** `docs/reviews/override-log.md:200`, `docs/reviews/override-log.md:311`, `docs/reviews/override-log.md:644`, `docs/reviews/override-log.md:648`, `docs/reviews/override-log.md:709`, `scripts/build-loop.sh:951`

---

## Claim 14: "T33's byte-equality half is a comment until U4 writes the SKILL.md block; U4 adds the assertion."

**Location:** `docs/working/plan-build-loop-handoff.md:326`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test file. It does not establish U4's future work.
**Legibility-target:** for-orchestrator-synthesis

The test has `# The SKILL.md block and test/lib/d6-snippet.bash are byte-equal (T33): pending until U4 writes the block.` (`test/scripts/build-loop-orchestrator.bats:267`), and no assertion compares the two.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:245-268`

---

## Claim 15: "The caller's global config, for merge_ident alone ..." (CALLER_GLOBAL captured before `git_harden` overwrites GIT_CONFIG_GLOBAL)

**Location:** `scripts/build-loop.sh:489-491`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of capture and overwrite and merge_ident's use of the capture. It does not establish what else merge_ident's call reads (the system config stays off).
**Legibility-target:** for-orchestrator-synthesis

`CALLER_GLOBAL=(-u GIT_CONFIG_GLOBAL); [[ -z "${GIT_CONFIG_GLOBAL+set}" ]] || CALLER_GLOBAL=("GIT_CONFIG_GLOBAL=$GIT_CONFIG_GLOBAL")` (`:491`) runs before `git_harden` (`:496`). merge_ident uses it in `x="$(env "${CALLER_GLOBAL[@]}" git -c user.useConfigOnly=true var "GIT_${w}_IDENT" 2>/dev/null)"` (`:1318`).

**Evidence:** `scripts/build-loop.sh:489-496`, `scripts/build-loop.sh:1315-1320`

---

## Claim 16: "Every git call in this process, the lib's included, runs hardened, but for caller_gate's read of the caller's pairs and merge_ident's CALLER_GLOBAL"

**Location:** `scripts/build-loop.sh:492-495`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every env override in build-loop.sh and the lib. It does not establish the narrower `GIT_LITERAL_PATHSPECS=0` call sites, which loosen pathspec parsing, not hardening.
**Legibility-target:** for-orchestrator-synthesis

The only per-call overrides of git_harden's variables in build-loop.sh and the lib are `GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list ...` (`:563`, caller_gate) and `env "${CALLER_GLOBAL[@]}" git ...` (`:1318`, merge_ident). This is paraphrased — no quote available because the claim is about absence: a grep for `env -u`, `env -i`, `GIT_CONFIG_COUNT=`, `GIT_CONFIG_GLOBAL=`, `GIT_ALLOW_PROTOCOL=`, `GIT_NO_REPLACE_OBJECTS=` and `unset GIT` across both files finds only those two and the lib's export. The i1 Claim 14 gap (no exceptions named) is fixed.

**Evidence:** `scripts/build-loop.sh:492-496`, `scripts/build-loop.sh:563`, `scripts/build-loop.sh:1318`, `scripts/lib/dev-cycle-read.sh:358`

---

## Claim 17: "git applies git -c pairs after git_harden's, so they win (a GIT_CONFIG_COUNT pair comes before git_harden's and loses, but is refused too)"

**Location:** `scripts/build-loop.sh:554-556`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's precedence and git_harden's index order. It does not establish other git versions.
**Legibility-target:** for-orchestrator-synthesis

git_harden appends from the caller's count upward: `local c="${GIT_CONFIG_COUNT:-0}"` ... `export "GIT_CONFIG_KEY_$c=..."; c=$((c + 1))` (`scripts/lib/dev-cycle-read.sh:351-356`). In P1, `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=a.b GIT_CONFIG_VALUE_0=1 git -c a.b=2 config --get a.b` printed `2`, so git -c is applied last. Test 2 (a count pair for core.hooksPath refused) passes in S1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:350-359`, `scripts/build-loop.sh:552-570`, `LOGS/probe1.log` (C3), `LOGS/bats-orch.log`

---

## Claim 18: the comments renamed harden → git_harden ("which git_harden does not switch off", "which git_harden extends and trusts", "git_harden's own pairs are not listed", "git_harden switches off the multi-pack-index", "Item 2's fsmonitor and replace refs are git_harden's", "which git_harden hides from the gate's own git")

**Location:** `scripts/build-loop.sh:498`, `:535`, `:545`, `:553`, `:940`, `:1102`, `:1111`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the symbol and the property each comment attributes to it. It does not re-verify those properties' older evidence beyond HARDEN's contents.
**Legibility-target:** for-orchestrator-synthesis

`git_harden` exists (`scripts/lib/dev-cycle-read.sh:350`), and `harden` is gone from scripts/ (paraphrased — no quote available because the claim is about absence: grep finds no `harden()` and no bare `harden` call). The properties are in HARDEN: `core.multiPackIndex=false`, `core.fsmonitor=false`, `core.useReplaceRefs=false`, `core.attributesFile=/dev/null` (`:348`), and in the export `GIT_NO_REPLACE_OBJECTS=1 ... GIT_ATTR_NOSYSTEM=1` (`:358`). caller_gate reads with the caller's count, `GIT_CONFIG_COUNT="$CALLER_COUNT"` (`scripts/build-loop.sh:563`), so git_harden's pairs are not listed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:348-358`, `scripts/build-loop.sh:563`

---

## Claim 19: "Exit: ... 1 bad usage, a GIT_CONFIG_COUNT that is not plain decimal, not a git repo, ..."

**Location:** `scripts/dev-cycle.sh:84-87`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 010, 08 and 1x with `--check-path`. It does not establish the digest mode separately (the same git_harden line runs first for every mode).
**Legibility-target:** for-orchestrator-synthesis

The check is `[[ "$c" =~ ^(0|[123456789][0123456789]*)$ ]] || { echo "${0##*/}: GIT_CONFIG_COUNT is not a plain decimal count" >&2; exit 1; }` (`scripts/lib/dev-cycle-read.sh:352`). In P4, each value gave `rc=1 out=dev-cycle.sh: GIT_CONFIG_COUNT is not a plain decimal count`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:352`, `scripts/dev-cycle.sh:128`, `LOGS/probe4.log`

---

## Claim 20: "Every git call from here on, the lib's and questions.sh's included, runs hardened, as build-loop.sh's do (... no hook, fsmonitor, replace ref, user or system config, or transport) ... File names are literal, not pathspecs."

**Location:** `scripts/dev-cycle.sh:124-127`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh, the lib and questions.sh as a child process, and the move of the GIT_LITERAL_PATHSPECS export. It does not cover the deliberate `GIT_LITERAL_PATHSPECS=0` calls, which use explicit `:(glob)`/`:(literal)` magic.
**Legibility-target:** for-orchestrator-synthesis

questions.sh runs as a child, `QS="$SCRIPT_DIR/questions.sh"` (`scripts/dev-cycle.sh:386`), and inherits the exports. Test 19 logs every git call from `--check-brief` and the digest through a shim, and finds HARDEN's pairs and G/P/S on each (S1, more than 10 calls). The old `export GIT_LITERAL_PATHSPECS=1` came after `cd "$ROOT"`. git_harden now exports it before the first git call (`scripts/lib/dev-cycle-read.sh:358`), so every path that had it still has it, and the remaining `GIT_LITERAL_PATHSPECS=0 git ls-files` calls (`scripts/dev-cycle.sh:146`, `:150`) are unchanged.

**Evidence:** `scripts/dev-cycle.sh:124-153`, `scripts/dev-cycle.sh:386`, `test/scripts/build-loop-orchestrator.bats:355-371`, `LOGS/bats-orch.log`

---

## Claim 21: "every later git call in this process and its children runs hardened, but where a caller hands back its own setting on purpose (build-loop.sh's caller_gate reads the caller's count, merge_ident its global config); build-loop.sh and dev-cycle.sh call it once, after scrub_reexec and before their first git call"

**Location:** `scripts/lib/dev-cycle-read.sh:326-330`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two call sites and the two exceptions. It does not establish anything about future callers.
**Legibility-target:** for-orchestrator-synthesis

The only two callers are `scripts/build-loop.sh:496` and `scripts/dev-cycle.sh:128` (paraphrased — no quote available because this is a grep result across scripts/ and test/). The ordering is as in Claim 1, and the exceptions are as in Claim 16. The i1 Claim 19 gap is fixed.

**Evidence:** `scripts/build-loop.sh:496`, `scripts/dev-cycle.sh:128`, `scripts/build-loop.sh:563`, `scripts/build-loop.sh:1318`

---

## Claim 22: "(core.useReplaceRefs there would override GIT_NO_REPLACE_OBJECTS)"

**Location:** `scripts/lib/dev-cycle-read.sh:334`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5, the installed git. It does not establish newer git, whose replace-ref setting may combine the two differently.
**Legibility-target:** for-orchestrator-synthesis

In P1, the blob A was replaced by B. `GIT_NO_REPLACE_OBJECTS=1 git cat-file blob A` printed `A`. With repo `core.useReplaceRefs=true` it printed `B`, so the repo config overrides the variable. Adding `-c core.useReplaceRefs=false` printed `A` again.

**Evidence:** `scripts/lib/dev-cycle-read.sh:333-334`, `LOGS/probe1.log` (C1)

---

## Claim 23: "git log's own date format and no signature check (a bad log.date stops git log; log.showSignature runs gpg.program)"

**Location:** `scripts/lib/dev-cycle-read.sh:337-338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 with repo-scope settings. It does not establish a caller-scope `git -c log.date=bogus`, which would still win (caller_gate refuses it in --state).
**Legibility-target:** for-orchestrator-synthesis

In P1, repo `log.date=bogus` made `git log` fail with `rc=128`, and the same command with a count pair `log.date=default` succeeded. For log.showSignature, see Claim 2 (P3's M3b: gpg.program ran without the pair).

**Evidence:** `scripts/lib/dev-cycle-read.sh:348`, `LOGS/probe1.log` (C2), `LOGS/probe3.log` (M3b)

---

## Claim 24: "CALLER_COUNT keeps the caller's count for build-loop.sh's caller_gate, which refuses a HARDEN key there by name."

**Location:** `scripts/lib/dev-cycle-read.sh:343-345`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the value CALLER_COUNT takes and caller_gate's use of it. It does not establish that dev-cycle.sh reads CALLER_COUNT (it does not, and need not).
**Legibility-target:** for-orchestrator-synthesis

`CALLER_COUNT="$c"` is set before the loop raises `c` (`scripts/lib/dev-cycle-read.sh:354`). caller_gate reads with `GIT_CONFIG_COUNT="$CALLER_COUNT"` and marks HARDEN keys (`scripts/build-loop.sh:563-566`). In S1, test 18 prints `caller 1` for a caller count of 1, and test 2 refuses a caller's `core.hooksPath` pair.

**Evidence:** `scripts/lib/dev-cycle-read.sh:349-354`, `scripts/build-loop.sh:558-570`, `LOGS/bats-orch.log`

---

## Claim 25: "A GIT_CONFIG_COUNT that is not plain decimal (010 reads as 8 here and as 10 to git) exits 1."

**Location:** `scripts/lib/dev-cycle-read.sh:345-346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash's arithmetic reading, git 2.39.5's reading and the exit. It does not establish other git versions.
**Legibility-target:** for-orchestrator-synthesis

In P1, `$((010))` = `8`. Git with `GIT_CONFIG_COUNT=010` and only key 0 set failed with "missing config key GIT_CONFIG_KEY_1", so it counts past 8 (base 10). Exit 1 is shown in Claim 19 (P4).

**Evidence:** `scripts/lib/dev-cycle-read.sh:352`, `LOGS/probe1.log` (C4), `LOGS/probe4.log`

---

## Claim 26: "What these cannot switch off, build-loop.sh's state gate refuses."

**Location:** `scripts/lib/dev-cycle-read.sh:346-347`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim's reach for both callers. It does not re-open row 548's settled decision.
**Legibility-target:** for-author

The sentence sits in the shared lib's git_harden header, which dev-cycle.sh also calls. dev-cycle.sh runs neither state_gate nor default_gate (`docs/reviews/override-log.md:548`: "dev-cycle.sh runs neither state_gate nor default_gate ... Defer (Q-103 residual)"). The sentence is true of build-loop.sh's gated modes. For the digest and the check modes, which D6 now runs as gate code, nothing refuses what git_harden leaves on. A precise version: "...build-loop.sh's state gate refuses for its gated modes; dev-cycle.sh runs none (row 548)." Comment-only; this re-flags the settled row 548.

**Evidence:** `scripts/lib/dev-cycle-read.sh:346-347`, `docs/reviews/override-log.md:548`, `scripts/dev-cycle.sh:128-129`

---

## Claim 27: "build-loop.sh --check does ... git_harden and the state gate own item 2's fsmonitor and replace refs"

**Location:** `scripts/lib/dev-cycle-read.sh:70`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rename and HARDEN's two keys. It does not re-verify the state gate's refs/replace check beyond its line.
**Legibility-target:** for-orchestrator-synthesis

HARDEN holds `core.fsmonitor=false` and `core.useReplaceRefs=false` (`scripts/lib/dev-cycle-read.sh:348`), and state_gate lists `refs/replace/` (`scripts/build-loop.sh:526`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:348`, `scripts/build-loop.sh:526`

---

## Claim 28: "U4 puts this file ... as the body of a quoted heredoc that bash reads, so it runs the same from any login shell and defines nothing in the caller's: `bash -s -- build-loop.sh ARG... <<'D6'`"

**Location:** `test/lib/d6-snippet.bash:2-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heredoc form run from bash. It does not establish zsh as the outer shell (not installed here), though a quoted heredoc is passed literally by both shells.
**Legibility-target:** for-orchestrator-synthesis

P2 ran `bash -s -- build-loop.sh <<'D6'` with the file as body, exit 0. The snippet's functions live in the child bash, which exits at `exit "$?"` (`test/lib/d6-snippet.bash:75`).

**Evidence:** `test/lib/d6-snippet.bash:2-9`, `LOGS/probe2.log` (P1)

---

## Claim 29: "T33 is to assert the two match once U4 writes the block (pending until then)."

**Location:** `test/lib/d6-snippet.bash:10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the current test's pending comment. It does not establish U4's assertion.
**Legibility-target:** for-orchestrator-synthesis

See Claim 14: `pending until U4 writes the block` (`test/scripts/build-loop-orchestrator.bats:267`). This fixes i1 Claim 26.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:267`

---

## Claim 30a: "in claude-workflows (main's first-parent root commit is D6_ROOT)"

**Location:** `test/lib/d6-snippet.bash:12-13`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the constant against this repository's main. It does not establish uniqueness of that root to claude-workflows' clones.
**Legibility-target:** for-orchestrator-synthesis

The constant is `D6_ROOT=640cf00735754d4253819a0354fb8ca9b71a8ea7` (`test/lib/d6-snippet.bash:32`). P5 printed `first-parent root: 640cf00735754d4253819a0354fb8ca9b71a8ea7` for main 27cedb99.

**Evidence:** `test/lib/d6-snippet.bash:32`, `LOGS/probe5.log`

---

## Claim 30b: "extracted from main's commit into a fresh temp dir once every object that chose them hashes to its id (main's first-parent commits, the trees down to scripts/lib/, the four extracted files)"

**Location:** `test/lib/d6-snippet.bash:13-16`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the set of objects hashed, and their consistency with what ls-tree and cat-file then read, including a second (loose) copy of a packed tree. It does not establish anything about a writer racing between the re-hash (`:53-55`) and the reads at `:61-64` (the Q-103 class, row 509, named in d9515d09's notes). It does not establish that refs/heads/main names the commit the gate landed (see the escalation).
**Legibility-target:** for-orchestrator-synthesis

The re-hash input is `{ g rev-list --first-parent "$sha" && g rev-parse "$sha^{tree}" "$sha:scripts" "$sha:scripts/lib"; } | g cat-file --batch`, which perl checks with `sha1_hex("$t $s\0$b") eq $id` and `exit($n < 4)` (`test/lib/d6-snippet.bash:53-55`). That covers every commit ls-tree's `"$sha"` and the root check's walk read, and the three trees ls-tree walks to `scripts/<f>` and `scripts/lib/<f>`. The four blobs are re-hashed after extraction (`:66-68`). The pipeline runs under `set -u -o pipefail` (`:31`), so a failed rev-parse (for example, no `scripts/lib` on main) also refuses. In P5 the pipeline hashed 1,125 objects (1,122 commits + 3 trees). In S1, tests 13 (a scripts tree rewritten in place) and 14 (the tip rewritten in place) pass. In P2/P3, with a packed true tree and a loose forged copy at the same id, ls-tree read the true blob id (`6826567...`, not the planted `b6aff63...`). The snippet ran main's real copy, so the re-hash and the reads take the same copy.

**Evidence:** `test/lib/d6-snippet.bash:31`, `test/lib/d6-snippet.bash:48-68`, `test/scripts/build-loop-orchestrator.bats:285-307`, `LOGS/bats-orch.log`, `LOGS/probe5.log`, `LOGS/probe2.log` (P3)

---

## Claim 30c: "It runs no file the uid can write"

**Location:** `test/lib/d6-snippet.bash:11-12`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the files the snippet executes. It does not establish whether the bytes main names were written by the uid (a ref question, escalated).
**Legibility-target:** for-author

In the claude-workflows branch, the executed file is the extracted copy in `d="$(mktemp -d)"` (`test/lib/d6-snippet.bash:56`). That is a uid-owned 0700 directory whose files the uid can write between the hash check (`:66-68`) and `bash "$d/scripts/$s"` (`:74`), and while the script sources its lib. This is the gap row 200 and row 509 name as the Q-103 class. The precise version: "it runs no file the uid could have written before the snippet started: main's bytes, hash-checked into a fresh temp dir (the same-uid race on that dir is Q-103's), or a root-owned image copy". Comment-only.

**Evidence:** `test/lib/d6-snippet.bash:56-74`, `docs/reviews/override-log.md:200`, `docs/reviews/override-log.md:509`

---

## Claim 31: "in any other repository it runs the image copy under D6_OPT, by absolute path, once those files and every directory above them are root-owned, no symlink and not writable here"

**Location:** `test/lib/d6-snippet.bash:16-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 9.
**Legibility-target:** for-orchestrator-synthesis

See Claim 9: the checks are at `test/lib/d6-snippet.bash:35`, `:71-72`. The run is `bash "$d/scripts/$s"` with `d="$D6_OPT"`, an absolute path (`:70`, `:74`). Tests 16 and 17 pass (S1), and mutant M2 turns test 17 red (P3).

**Evidence:** `test/lib/d6-snippet.bash:35`, `test/lib/d6-snippet.bash:70-74`, `LOGS/bats-orch.log`, `LOGS/probe3.log`

---

## Claim 32: "It never reads the working tree, ~/.claude/scripts or a replaced object."

**Location:** `test/lib/d6-snippet.bash:18-19`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the snippet's own reads and the choice of which questions.sh dev-cycle.sh runs. It does not cover git's repository discovery, which in a linked worktree reads the `.git` gitfile there. It does not cover what the scripts it runs read (the digest reads the working tree by design).
**Legibility-target:** for-orchestrator-synthesis

The snippet's reads are `g for-each-ref`, `rev-parse --git-path`, `show-ref`, `symbolic-ref`, `cat-file`, `rev-list`, `ls-tree`, and `hash-object --no-filters` on the temp dir (`test/lib/d6-snippet.bash:40-68`). None names a working-tree path. Replaced objects: `GIT_NO_REPLACE_OBJECTS=1` and `-c core.useReplaceRefs=false` are on every call (`:34`), and a replace ref refuses (`:41`). ~/.claude/scripts: dev-cycle.sh falls back to `QS="$HOME/.claude/scripts/questions.sh"` only when `[[ -f "$QS" ]]` fails for its own directory (`scripts/dev-cycle.sh:386-387`). Both snippet branches guarantee that file: it is extracted and hash-checked, or own-checked with `-f` (`:71`). Test 11 shows main's questions.sh answering (`from-main`) with the working tree's copy replaced by `exit 9` (S1).

**Evidence:** `test/lib/d6-snippet.bash:34-71`, `scripts/dev-cycle.sh:386-387`, `test/scripts/build-loop-orchestrator.bats:245-260`, `LOGS/bats-orch.log`

---

## Claim 33: "Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout, with nothing run, for ... an object above that does not hash to its id, ... or a git read or temp-dir step that fails ...; 1 for another first argument."

**Location:** `test/lib/d6-snippet.bash:21-27`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same finding as Claim 7, in the snippet's own header. The other listed exits are Verified under Claim 6.
**Legibility-target:** for-author

The root check's read (`if [[ "$(g rev-list --first-parent --max-parents=0 "$sha")" == "$D6_ROOT" ]]`, `test/lib/d6-snippet.bash:48`) is a git read whose failure does not refuse: it selects the image copy. P2 got exit 0 with /opt's build-loop.sh output and no `refuse d6:` line. "The script's own status" is right: `exit "$?"` directly after the `env ... bash` run (`:74-75`), and the EXIT trap's `rm` does not change it. Comment-only in this location; the behaviour is escalated.

**Evidence:** `test/lib/d6-snippet.bash:21-27`, `test/lib/d6-snippet.bash:48`, `test/lib/d6-snippet.bash:74-75`, `LOGS/probe2.log` (P2)

---

## Claim 34: "Its own git calls carry the lib's HARDEN pairs and git_harden's environment (a test pins the two lists equal)."

**Location:** `test/lib/d6-snippet.bash:28-29`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 11.
**Legibility-target:** for-orchestrator-synthesis

See Claim 11 (`test/lib/d6-snippet.bash:34`; test 18 passes in S1).

**Evidence:** `test/lib/d6-snippet.bash:34`, `test/scripts/build-loop-orchestrator.bats:338-353`, `LOGS/bats-orch.log`

---

## Claim 35: "# d stays global: the EXIT trap reads it"

**Location:** `test/lib/d6-snippet.bash:37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the variable's scope and the trap's quoting. It does not establish cleanup on SIGKILL.
**Legibility-target:** for-orchestrator-synthesis

The local list is `local s="${1:-}" F x m n sha ids f i`, which omits `d` (`:37`). The trap is single-quoted, `trap 'rm -rf "$d"' EXIT` (`:57`), so `$d` expands at exit, after `d6` has returned via `exit`. Test 11's empty `$TMPDIR` confirms the cleanup (S1).

**Evidence:** `test/lib/d6-snippet.bash:37`, `test/lib/d6-snippet.bash:57`, `LOGS/bats-orch.log`

---

## Claim 36: "Every object that chose the bytes must hash to its id, read as git reads it (an object rewritten in place changes what ls-tree or rev-list says): main's first-parent commits, which made the root match, and the trees down to scripts/lib/. D6_ROOT is a SHA-1 id, so the repository is SHA-1."

**Location:** `test/lib/d6-snippet.bash:49-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 30b. The SHA-1 inference holds because a SHA-256 repository's 64-hex ids can never equal the 40-hex D6_ROOT (`:32`), so such a repository never reaches the branch.
**Legibility-target:** for-orchestrator-synthesis

See Claim 30b. The walk re-hashed is the same `rev-list --first-parent "$sha"` the root check made (`:48`, `:53`). Because the tip is hashed first and each parent id comes from an already-hashed commit, every id in the walk is the true parent. Test 14 shows a forged tip that ends the history at a new root being refused (S1).

**Evidence:** `test/lib/d6-snippet.bash:48-55`, `test/scripts/build-loop-orchestrator.bats:299-307`, `LOGS/bats-orch.log`

---

## Claim 37: "Under bash -s the script is the heredoc on stdin: bash has read this whole line before it runs, and no child reads the rest of it."

**Location:** `test/lib/d6-snippet.bash:77-78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers file, pipe and heredoc input with a stdin-reading child. It does not establish the claim for input that does not end in a newline after the last line.
**Legibility-target:** for-orchestrator-synthesis

See Claim 4: P2's child read 0 bytes in all three forms, and the snippet exited 0.

**Evidence:** `test/lib/d6-snippet.bash:79`, `LOGS/probe2.log` (P1)

---

## Claim 38: "# Not log.date: git_harden's log.date pair overrides it (row 505); a bad boolean still stops git log."

**Location:** `test/scripts/build-loop-check.bats:1660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 and the test's pass. It does not establish other log.* keys.
**Legibility-target:** for-orchestrator-synthesis

In P1, repo `log.date=bogus` is overridden by a `log.date=default` count pair, and repo `log.abbrevCommit=bogus` makes `git log` fail. The test passes (P4, 2/2).

**Evidence:** `test/scripts/build-loop-check.bats:1658-1667`, `LOGS/probe1.log` (C2, C5), `LOGS/probe4.log`

---

## Claim 39: test name "every git call --check makes carries git_harden's config pairs (core.hooksPath=/dev/null among them), no global or system config and no transport"

**Location:** `test/scripts/build-loop-check.bats:1688`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--check` path the test drives. It does not establish other modes.
**Legibility-target:** for-orchestrator-synthesis

The test's list now includes `log.date=default log.showSignature=false` (`:1699`). It checks every logged call and passes (P4).

**Evidence:** `test/scripts/build-loop-check.bats:1688-1702`, `LOGS/probe4.log`

---

## Claim 40: "# A plain caller pair passes; a count git_harden would misread stops every mode (row 276)."

**Location:** `test/scripts/build-loop-orchestrator.bats:50`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rename (fixes i1 Claim 37) and test 2's pass. It does not establish "every mode" beyond the `--settings` runs the loop makes.
**Legibility-target:** for-orchestrator-synthesis

`git_harden` is the name (`scripts/lib/dev-cycle-read.sh:350`). Test 2 passes (S1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:50-56`, `LOGS/bats-orch.log`

---

## Claim 41: test name "the D6 snippet runs main's four scripts from a fresh temp dir, each with its own lib and questions.sh, never the working tree's, and removes the dir (T33, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:245`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts. It does not establish the lib's source path for the dev-cycle.sh run (its stderr is not checked there; main's questions.sh is).
**Legibility-target:** for-orchestrator-synthesis

The test replaces all four working-tree files with `exit 9` (`:252`). It asserts the lib path under `$TMPDIR` (`:256`), main's `from-main` entry (`:260`), an empty `$TMPDIR` (`:261`, `:266`), and the tamper refusal (`:265`). In P3, mutant M1 (hash loop removed) and M4 (the working tree's `scripts/$s` run) each turn it red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:245-268`, `LOGS/bats-orch.log`, `LOGS/probe3.log`

---

## Claim 42: test name "the D6 snippet refuses before running anything: a blob or commit replace ref, info/grafts, not exactly one plain main or master (T36, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:270`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each case plus the symbolic and tag-named main and the exit-1 argument. It does not establish the master-only case (only main + master is tried).
**Legibility-target:** for-orchestrator-synthesis

`d6_is` requires exit 2, exactly the refusal line and empty stderr (`:237`), for each case at `:273-280`. The test passes (S1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:237`, `test/scripts/build-loop-orchestrator.bats:270-283`, `LOGS/bats-orch.log`

---

## Claim 43: test name "the D6 snippet refuses a tree above scripts/ rewritten in place, which points ls-tree at planted bytes (T36, U3b3 i1 A1)"

**Location:** `test/scripts/build-loop-orchestrator.bats:289`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which tree the test rewrites. The refusal itself is Verified (S1).
**Legibility-target:** for-author

The test rewrites `x="$(git rev-parse main:scripts)"` (`:292`), which is the `scripts/` tree itself (the tree above `scripts/lib/`), not a tree above `scripts/` (that would be main's root tree). Its in-body comment is right: "written over main's real scripts tree" (`:291`). A precise name: "refuses the scripts/ tree rewritten in place". Comment-only.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:289-297`, `LOGS/bats-orch.log`

---

## Claim 44: test name "the D6 snippet refuses a first-parent commit rewritten in place to end main's history at D6_ROOT (T36, U3b3 i1 A1)"

**Location:** `test/scripts/build-loop-orchestrator.bats:299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tip commit. It does not establish a deeper first-parent commit (the same check covers it, untested).
**Legibility-target:** for-orchestrator-synthesis

The tip `t` is overwritten with a commit whose parent is the new root `r` (`:301-303`), the snippet's D6_ROOT is set to `r` (`:304`), and the test expects `$A1` with exit 2 (`:306`). It passes (S1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:299-307`, `LOGS/bats-orch.log`

---

## Claim 45: test name "a gate copy patched in the loop's worktree prints ok for its tip; the D6 snippet's copy from main refuses the same tip (T27, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:309`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one patched rule (the symlink/mode rule). It does not establish other patches.
**Legibility-target:** for-orchestrator-synthesis

The worktree copy is patched with `elif false && ` (`:313`), and its `--check` prints `ok` (`:315-316`). The snippet's run refuses with the symlink deny line (`:317-319`). The test passes (S1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:309-320`, `LOGS/bats-orch.log`

---

## Claim 46: test name "outside claude-workflows the D6 snippet runs the image copy by absolute path, not main's copy (T37, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:322`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this image (root-owned /opt present, so the test ran). It does not establish behaviour where it skips.
**Legibility-target:** for-orchestrator-synthesis

Test 16 ran and passed in S1, with no skip. Its output equals `bash /opt/claude-workflows/scripts/build-loop.sh --help`, not `main copy`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:322-328`, `LOGS/bats-orch.log`

---

## Claim 47: test name "outside claude-workflows the D6 snippet refuses an image copy the uid owns, and never runs main's (T37, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:330`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the uid-owned case. "Never runs main's" follows from `d6_is` requiring the refusal line as the whole stdout; main's copy would print `main copy`.
**Legibility-target:** for-orchestrator-synthesis

`d6_is "refuse d6: $U/scripts/build-loop.sh is not root-owned, ..."` (`:335`). The test passes (S1) and goes red under mutant M2 (P3).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:330-336`, `LOGS/bats-orch.log`, `LOGS/probe3.log`

---

## Claim 48: test name "git_harden exports HARDEN's pairs after the caller's and a fixed environment; the D6 snippet's git carries the same (rows 281, 311, 495, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact `GIT_*` environment under `env -i` and the snippet's lists. It does not establish the order git applies them in (Claim 17).
**Legibility-target:** for-orchestrator-synthesis

The test compares the whole sorted `GIT_*` environment with the caller's key 0 and HARDEN at keys 1-8, `GIT_CONFIG_COUNT=9` (`:343-348`). It passes (S1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:338-353`, `LOGS/bats-orch.log`

---

## Claim 49: test name "every git call dev-cycle.sh makes carries git_harden's pairs: a bogus log.date stops nothing, log.showSignature runs no gpg.program (rows 495, 505, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:355`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-brief` and the digest. It does not establish the other check modes (same process setup, untested here).
**Legibility-target:** for-orchestrator-synthesis

The test passes (S1). Mutants M3 and M3b fail it on the gpg-ran assertion (P3).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:355-371`, `LOGS/bats-orch.log`, `LOGS/probe3.log`

---

## Claim 50: "Mutants checked: hash check removed, ownership check removed, log.showSignature pair removed, main's dev-cycle.sh: each turns a test red."

**Location:** commit a0014ce5 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the four mutants applied to 5d175c0e's files and run against 5d175c0e's tests, not a0014ce5's. It reads "main's dev-cycle.sh" as "the snippet runs the working tree's script instead of main's"; i1 read it as "main's pre-U3b3 dev-cycle.sh", and found it red too.
**Legibility-target:** for-orchestrator-synthesis

In P3: M1 (the hash-object loop deleted) gave T33 `not ok`, at the tamper assertion. M2 (`own() { :; }`) gave T37's uid-owned test `not ok`. M3 (`log.showSignature=false` dropped from HARDEN) gave test 19 `not ok`, with "gpg.program ran". M4 (`bash "scripts/$s"`) gave T33 `not ok` with status 9.

**Evidence:** `LOGS/probe3.sh`, `LOGS/probe3.log`

---

## Claim 51: "dev-cycle.sh's calls hardened (rows 495, 505: a planted log.showSignature ran gpg.program on main)"

**Location:** commit a0014ce5 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 2.
**Legibility-target:** for-orchestrator-synthesis

P3's M3b: without the pair, test 19's gpg.program stub ran on main's signed-looking commit.

**Evidence:** `LOGS/probe3.log` (M3b), `test/scripts/build-loop-orchestrator.bats:357-366`

---

## Claim 52: "T33 (own lib and questions.sh, working tree ignored, temp dir removed, a tampered extraction refused, --state passes; the SKILL.md byte-equality half waits for U4)"

**Location:** commit a0014ce5 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 41.
**Legibility-target:** for-orchestrator-synthesis

Each part is asserted at `test/scripts/build-loop-orchestrator.bats:256-267`, and the test passes (S1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:245-268`, `LOGS/bats-orch.log`

---

## Claim 53: "about 0.1 s over this repository's ~1,100 first-parent commits"

**Location:** commit d9515d09 (message Notes)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers this machine, warm cache, the re-hash pipeline alone. It does not establish cold-cache or other hosts.
**Legibility-target:** for-orchestrator-synthesis

P5: `first-parent commits: 1122`, `objects hashed: 1125`, `elapsed s: 0.036`. That is within "about 0.1 s".

**Evidence:** `LOGS/probe5.sh`, `LOGS/probe5.log`

---

## Claim 54: "A2: the default branch's ref must name a commit itself, not a peeled tag."

**Location:** commit d9515d09 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an annotated tag written into refs/heads/main. It does not establish a tree or blob there (git itself rejects those first, per the plan's U3b1 note).
**Legibility-target:** for-orchestrator-synthesis

The check is `sha="$(g rev-parse --verify -q "refs/heads/$m")" && [[ "$(g cat-file -t "$sha")" == commit ]] || no "refs/heads/$m names no commit"` (`test/lib/d6-snippet.bash:47`; no `^{commit}` peel). Test 12's tag case passes (S1).

**Evidence:** `test/lib/d6-snippet.bash:47`, `test/scripts/build-loop-orchestrator.bats:278-279`, `LOGS/bats-orch.log`

---

## Claim 55: "dev-cycle.sh now reads no user or system git config, like build-loop.sh; a host repo that needs a global safe.directory would stop."

**Location:** commit 9925f2a7 (message Notes)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The first half is Verified as Claim 3. The safe.directory consequence is not established.
**Legibility-target:** for-orchestrator-synthesis

Execution is required and is blocked: the consequence needs a repository owned by another uid, and the probes run unprivileged as uid 1000 (paraphrased — no quote available because the claim concerns git's ownership check, not repository code).

**Evidence:** `scripts/lib/dev-cycle-read.sh:358`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 7** (`docs/working/plan-build-loop-handoff.md:326`): "a failed git read ... refuses". The root check's rev-list (`test/lib/d6-snippet.bash:48`) is a read whose failure selects the image copy. P2 got exit 0 with /opt's output. Fix the wording, or refuse when that rev-list fails. Behavioural mismatch between doc and code.
- **Claim 26** (`scripts/lib/dev-cycle-read.sh:346-347`): "What these cannot switch off, build-loop.sh's state gate refuses". This holds only for build-loop.sh's gated modes; dev-cycle.sh, which also calls git_harden, runs no state gate (row 548, settled). Comment-only.
- **Claim 30c** (`test/lib/d6-snippet.bash:11-12`): "runs no file the uid can write". The extracted copy is in a uid-writable 0700 temp dir (the Q-103 race, rows 200/509). Narrow it to "no file the uid could have written before the run". Comment-only.
- **Claim 33** (`test/lib/d6-snippet.bash:21-27`): the Exit list has the same root-check gap as Claim 7. Comment-only here; the behaviour is in Claim 7.
- **Claim 43** (`test/scripts/build-loop-orchestrator.bats:289`): the test name says "a tree above scripts/", but the test rewrites the scripts/ tree itself. Comment-only.

### Unverifiable
- **Claim 5** (`docs/working/plan-build-loop-handoff.md:326`): the zsh alias `g` incident needs the original session's transcript.
- **Claim 10** (`docs/working/plan-build-loop-handoff.md:326`): "refuses when run as root" needs a root run. Statically, root's `-w` is false on a read-only mount, so "always" is mount-dependent.
- **Claim 55** (commit 9925f2a7): the safe.directory consequence needs a repository owned by another uid.

## Re-flagged settled decisions
- Claim 26 restates row 548 (dev-cycle.sh runs no state_gate or default_gate; Q-103 residual) against the new lib comment. The decision is settled; only the comment's reach is in question.
- Claim 30c's residue is row 509's class (a same-uid racer against a fresh 0700 temp dir; Q-103), which d9515d09's notes already name.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/code-fact-check-report-2026-10-12-u3b3-i2.md, structured per the code-fact-check skill.
- Answered: yes. All eight brief focus areas were checked, including the i1 fixes and the new re-hash. The orchestrator suite (19/19) and the two edited check tests (2/2) were run, and every executable claim was executed except two blocked ones (root; another uid).
- Out of scope: security judgement of the two items below (left to security-reviewer). docs/reviews/hallucination-patterns.md was not edited (no fabrication found, and the write-only-your-report rule applies).
- Escalate: (1) security, `test/lib/d6-snippet.bash:48`. A failed root-check rev-list silently selects the /opt image copy instead of refusing. P2 did this by removing one loose commit object, which a same-uid loop can do. In claude-workflows that steers the orchestrator from main's gate to the image's, possibly older, gate. Is that acceptable, or should a rev-list failure refuse? (2) security, `test/lib/d6-snippet.bash:44-48`. The re-hash proves main's objects are self-consistent, not that refs/heads/main names a commit the gate landed. Under the brief's threat model (loops write refs), a loop that moves main onto its own commit atop the real history passes every hash, and the snippet runs the loop's scripts, including the `--main-log` that would report the move. This is probably the hostile-loop / Q-103 class (rows 509, 548), but no row names it for the D6 snippet. Confirm it is settled, or route it.
- Decisions I made: I read "main's dev-cycle.sh" in a0014ce5's mutant list as "the working tree's script run instead of main's" (i1 used the other reading; both are red). I kept probe logs in the session scratchpad, not in docs/reviews/execution-logs, to honour the write-only-your-report rule. I graded Claims 7/33 Mostly accurate rather than Incorrect because every listed refusal holds and the one exception runs root-owned, not uid-written, bytes.
