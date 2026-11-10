Commit: bd312d15

# Code Fact-Check Report

**Commit:** bd312d15
**Repository:** /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback (branch `fix/confine-tests-dash-and-fallback`)
**Scope:** 23ffb16c..bd312d15: `scripts/confine-tests.sh`, `test/scripts/confine-tests.bats`, `guides/test-hermeticity.md`, `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md`, `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md`, and the commit messages `git log 23ffb16c..bd312d15` (final confirming pass, replicate 2)
**Checked:** 2026-11-10
**Total claims checked:** 47
**Summary:** 38 verified, 4 mostly accurate, 1 stale, 3 incorrect, 1 unverifiable

Scratch directory for every experiment (called `$R` below): `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/review-final-fc-r2`. Captured output is under `$R/logs/` and `$R/mut-run.txt`, as named in each claim's Evidence line. The repo's script and test were never edited: every run used copies.

Main executed experiments:

- **E1, old against new, behaviour.** `cd $R/cmp && CMP_DIR=$R CMP_OUT=$R/cmpout timeout 590 bats test/scripts/compare.bats`, started 2026-11-10T22:30:26Z, exit 0. The harness is the test file's own helpers (`setup`, the stand-ins, `confine`, lines 1-204), with one added test that copies the 23ffb16c script, then the bd312d15 script, to the same path and runs each on every input in this matrix: `sh` absent, linked to bash, or linked to dash; bwrap absent/ok/refused/run-fails; unshare absent/ok/refused; ip absent/ok/fails; and 21 argument sets. The argument sets are the three probe spellings (`--probe`, `--no-loopback --probe`, `--probe --no-loopback`), no arguments, `--`, `--no-loopback --`, and runs of RECORD, `''`, a directory, a file without the execute bit, a name that is no file, `-record -x`, `-a x RECORD one`, `-nonexistent y`, `-`, `-- RECORD`, `-p RECORD`, `eval 'touch pwned'`, plus the `--no-loopback` forms of `''` and `-a x RECORD one`. That is 2268 cases and 4536 runs, recording status, stdout, stderr, whether the child ran, whether `pwned` appeared, and any call a stand-in did not accept. The analysis is `python3 -I $R/analyse.py $R` (exit 0), with output in `$R/logs/compare-analysis.txt`. The raw records are in `$R/cmpout/{old,new}/`. (My first run of this harness used loop variables that bats' `run` overwrote, so its ip mode went wrong. I discarded it and re-ran with renamed variables, and only the second run is cited.)
- **E2, mutation re-run.** `cd $R && timeout 590 python3 mutate.py /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback $R/mut`, started 2026-11-10T22:26:22Z, exit 0, output in `$R/mut-run.txt`.
- **E3, gates.** `timeout 590 bash $R/gates.sh` (cwd the worktree, 2026-11-10T22:28:26Z). It runs the probe, the lint, shellcheck, the test file from a scratch copy, and the bd312d15 test file against the 23ffb16c script. Statuses are in `$R/logs/*.status` and outputs in `$R/logs/{probe.err,lint.out,shellcheck.out,bats-new.out,bats-old.out}`.
- **E4, per commit.** `timeout 590 bash $R/percommit.sh` (2026-11-10T22:31:06Z) runs each commit's own test file against its own script. Output is in `$R/logs/percommit.txt` and `$R/percommit/<sha>.out`.
- **E5, shell probes.** `timeout 60 bash $R/probe-shells.sh` (2026-11-10T22:29:12Z, exit 0), output in `$R/logs/probe-shells.txt`. I also re-ran a copy of the author's `probe1.sh` (`timeout 120 bash $R/probe1.sh`, exit 0, output in `$R/logs/probe1.txt`).

`docs/reviews/hallucination-patterns.md` was checked for logged patterns. No claim below matches one.

---

## Claim 1: "238 lines change outside `docs/` (227 in the script and its test, 11 in the guide)" and "a count of 539 changed lines, 301 of them the research doc"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line counts of 23ffb16c..ca6cf3be, the diff the pre-mortem's Proposal line names; does not establish the counts at any later commit.
**Legibility-target:** for-orchestrator-synthesis

I ran `timeout 60 bash $R/q1.sh`, which runs `git diff --numstat 23ffb16c..ca6cf3be` among other things (cwd the worktree, 2026-11-10T22:38:16Z, exit 0, output in `$R/logs/q1.txt`). It gives `301 0 research`, `9 2 guides/test-hermeticity.md`, `61 13 scripts/confine-tests.sh` and `119 34 test/scripts/confine-tests.bats`. Script and test come to 74 + 153 = 227, the guide to 11, together 238, and the total is 539.

**Evidence:** `$R/logs/q1.txt`; `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:12`

---

## Claim 2: "Prior art: `grep -ril -e 'BASH_ENV' -e 'uid 0' -e 'warning fatigue' -e 'unshare -r' docs/decisions/ docs/working/` returns decision 017, the two earlier confine-tests research docs and this unit's own."

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:14`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tracked files at de1f4bf9 and at bd312d15; does not cover untracked files in the author's checkout, which could only add hits.
**Legibility-target:** for-author

The same pattern over tracked files (`git grep -il -e 'BASH_ENV' -e 'uid 0' -e 'warning fatigue' -e 'unshare -r' de1f4bf9 -- docs/decisions/ docs/working/`, cwd the worktree, exit 0) returns 17 files, not 4. Besides the four the doc names, the list includes `docs/decisions/019-arithmetic-eval-sandboxing.md`, both confine-tests briefs, five `docs/working/cycles/cycle-*.md` files, `docs/working/research-2026-11-01-restriction-audit.md`, `docs/working/research-2026-11-05-d6-block-into-image.md`, `docs/working/diagnosis-cc-isolated-login-dns.md`, `docs/working/plan-build-loop-handoff.md` and `docs/working/questions-archive.md` (paraphrased: no quote available because the claim is about a grep's result set, listed in full in the command output). The conclusion drawn from the grep ("the others are new") rests on a result the grep does not give. The review-pass-1 reports do not mention this sentence.

**Evidence:** `$R/logs/prior-art-grep.txt` (the `git grep` above, cwd the worktree, 2026-11-10T22:38Z, exit 0); `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:14`

---

## Claim 3: Narrative 1: a fallback `--probe` "prints `primitive available: unshare (loopback=1)` and exits 0, with no warning"; "The run prints the new warning as the file's first six lines"; the four root-skip tests at `test/cc-push.bats:417`, `test/hooks/guard-trusted-writes.bats:889`, `test/install-host.bats:680`, `test/cc-isolated-functions.bats:1970`; the quoted headline; `docs/roadmap.md:49`'s wording.

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:20-26`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe and run output under stand-ins, the line references and the roadmap quote; does not cover the narrative's prediction about a future kernel or loop.
**Legibility-target:** for-orchestrator-synthesis

E1 found that every fallback probe has an empty stderr. For each of the 112 runs whose only stderr change is the warning, the new stderr is a 6-line warning followed by exactly the old stderr. The banner is therefore line seven, which bears on narrative 2 as well. The warning's six lines come from `scripts/confine-tests.sh:132-139`: one `echo`, three heredoc lines, one `echo`, and one `printf` line for the single further argument at `:224` or `:228`. Each of the four files carries `[ "$(id -u)" -ne 0 ] || skip` at the cited line (for example `test/cc-push.bats:417: [ "$(id -u)" -ne 0 ] || skip "root ignores directory permissions"`). At `test/install-host.bats:680` the skip comes after `need_script;`, so "begin" is loose there. A repo-wide grep finds no fifth such line. `docs/roadmap.md:49` reads `wording (run \`scripts/confine-tests.sh --probe\`; exit 0: tests pass confined; exit 3:`. The quoted headline is a prefix of `scripts/confine-tests.sh:222`.

**Evidence:** `$R/logs/compare-analysis.txt`; `$R/logs/q1.txt`; `scripts/confine-tests.sh:132-139,216-230`

---

## Claim 4: Narrative 2: "no caller exists in this repo, and `grep -rn confine-tests` over code finds none"; the header "now says the warning comes first on stderr"; "the log shows the banner on line seven".

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:30-35`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers callers in `*.sh`, `*.bats` and `*.py` and the header wording; does not cover callers outside the repo.
**Legibility-target:** for-author

No caller exists. However, the grep does return hits outside the script and its test: `test/fixture-hermeticity.bats:15: # namespace: scripts/confine-tests.sh -- scripts/run-tests.sh --all`, which is a comment. The precise sentence would be "finds no caller". The header does say the run "says first, on stderr, what that leaves unconfined" (`scripts/confine-tests.sh:33-34`). Banner on line seven: see Claim 3. The research doc's "Callers: none in code" (`:22`) states the same thing correctly.

**Evidence:** `grep -rn confine-tests --include='*.sh' --include='*.bats' --include='*.py' .` (cwd the worktree, exit 0); `scripts/confine-tests.sh:29-35`

---

## Claim 5: Narrative 3: "a non-interactive bash sources the file `BASH_ENV` names; the `sh` it replaces does not, whether it is dash or bash started as `sh`"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12 on this host, started with `-c`; does not cover other bash builds, or exported functions, which the narrative does not test.
**Legibility-target:** for-orchestrator-synthesis

E5, with `BASH_ENV=envfile` where `envfile` holds `echo SOURCED`, printed `bash -c: SOURCED` then `body`, `dash -c: body`, and `bash-as-sh -c: body`. The body runs under bash at `scripts/confine-tests.sh:285`: `exec unshare -rn -- "$BASH" -c '`.

**Evidence:** `$R/logs/probe-shells.txt`; `scripts/confine-tests.sh:285-290`

---

## Claim 6: Narrative 4: "four other tests fail with `exec: sh: not found`"; "the mutant 'body under sh again' fails tests 16, 18, 19, 20 and 21, and on a host without dash it would still fail 16, 19, 20 and 21"; "`setup()` links only `bash`, `cat` and `awk` into `$TOOLS`".

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:48-53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this host, which has dash; the "host without dash" half follows from test 18 alone adding a dash `sh` (it is inferred, not run without dash).
**Legibility-target:** for-orchestrator-synthesis

E2 gave `m01 body under sh again (exec -- kept): exit 1; failing tests: 16, 18, 19, 20, 21`. Setup reads `for tool in bash cat awk; do` (`test/scripts/confine-tests.bats:65`). The `exec: sh: not found` message (`.../stub/unshare/unshare: line 29: exec: sh: not found`) appears in tests 16, 19, 20 and 21 of the E4 run at d03a3078, where the body was still `sh -c`.

**Evidence:** `$R/mut-run.txt`; `$R/percommit/d03a3078.out`; `test/scripts/confine-tests.bats:65,443-465`

---

## Claim 7: Line references into the 23ffb16c script: detection "lines 79-118", the switch "134-152", the run "176-227", the defect at ":225", the warning "inside the `primitive == bwrap && loopback == 0` branch (line 134)", "Location: lines 134-143", "227 lines", a "seven-line warning (six `echo`s after the headline)", and the test file at "420 lines, 17 tests".

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:14-20,39,43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the files at 23ffb16c; does not cover the same numbers at later commits.
**Legibility-target:** for-orchestrator-synthesis

`git show 23ffb16c:scripts/confine-tests.sh | cat -n` shows `79 detect_primitive() {`, the `exit 3` / `fi` at 117-118, `134 if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]; then` with seven `echo`s at 137-143 and `fi` at 152, `176 # --- run`, `220 exec unshare -rn -- sh -c '`, `225 exec "$@"' sh "${cmd[@]}"` and `227 exec unshare -rn -- "${cmd[@]}"`. `wc -l` gives 227 for the script and 420 for the test file, and `grep -c '^@test'` gives 17.

**Evidence:** `git show 23ffb16c:scripts/confine-tests.sh` (cwd the worktree, exit 0); `git show 23ffb16c:test/scripts/confine-tests.bats | wc -l`

---

## Claim 8: "Callers: none in code"; decision 018 at `:43,117` cites `scripts/confine-tests.sh:220`; `CLAUDE.md` names the script without a line; decision 018 item 4 ("Defeat option injection at the argv layer ..."); `hooks/live-verify-gate.sh`'s `enforcement` and `host_tools` patterns "match only `devcontainer-config/`".

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:22,52,59`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cited files at bd312d15; does not establish whether other repo docs cite the old line.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43` reads `(\`scripts/confine-tests.sh:220\` is the reference for this pattern.)` and `:117` reads `` `scripts/confine-tests.sh:220` — reference argv-passthrough pattern. ``. `:46` reads `4. Defeat *option* injection at the argv layer: prefix a relative path with \`./\``. `CLAUDE.md:9` ends `(record 018; the reference pattern is in \`scripts/confine-tests.sh\`)`. `hooks/live-verify-gate.sh:83` reads `enforcement='^devcontainer-config/(...)'` and `:91` reads `host_tools='^devcontainer-config/(...)'`. The only non-test mention of the script in code is the comment at `test/fixture-hermeticity.bats:15` (see Claim 4).

**Evidence:** `$R/logs/q1.txt` (exit 0)

---

## Claim 9: The D1 table: under bash-as-`sh`, `-rec -x` is refused (`exec: -r: invalid option`), `-a x rec one` runs `rec` with `one`, `eval echo hi` runs the file `eval`, and `-nonexistent y` is refused (`exec: -n: invalid option`). Under dash it runs `-rec`, says `exec: -a: not found`, runs the file `eval`, and says `exec: -nonexistent: not found`.

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:34-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12; does not cover other shells as `sh`.
**Legibility-target:** for-orchestrator-synthesis

The re-run of `probe1.sh` printed `exec "$@" | -rec -x -> ... | sh: line 1: exec: -r: invalid option`, `exec "$@" | -a x rec one -> ... | RAN rec: [one]` and `exec "$@" | -nonexistent y -> ... | sh: line 1: exec: -n: invalid option` (sh-bash), and `RAN -rec: [-x]`, `sh: 1: exec: -a: not found` and `sh: 1: exec: -nonexistent: not found` (sh-dash). Both shells print `RAN eval: [echo] [hi]`. The probe's status column reads 0 throughout, which the doc itself says is broken (`:276`).

**Evidence:** `$R/logs/probe1.txt`

---

## Claim 10: "D2, reproduced": at 23ffb16c, `confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- "$RECORD" one` exits 0 with one line on stderr, the banner.

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stand-in harness with `sh` as bash or dash; does not cover a real unshare.
**Legibility-target:** for-orchestrator-synthesis

The E1 records for `sh=bash` and `sh=dash`, `bwrap=absent,unshare=ok,ip=ok,args=RUN:REC`, show old status 0 with stderr `confine-tests: denying network via unshare (loopback=1)` alone. At bd312d15 the same input prints the 6-line warning first. The root cause the doc names is the guard at old `:134`, and the 23ffb16c source shows the warning only inside that branch.

**Evidence:** `$R/cmpout/old/*` (KEY lines with `args=RUN:REC`); `$R/logs/compare-analysis.txt`

---

## Claim 11: Gotchas: "`exec -- "$@"` is right under bash, in posix mode too ..., and wrong under dash, which runs `--` as the command"; "`command -- "$@"` and a bare `"$@"` both run a shell builtin"; "`"$BASH" -c '... exec -- "$@"'` ... exits 127 for a name not on PATH (`-a` among them) and 126 for a directory".

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:65-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12; the "keeps the pid" part rests on test 16's `same_process` and was not probed separately.
**Legibility-target:** for-orchestrator-synthesis

E5 printed `dash: 1: exec: --: not found` / `127`, `bash-as-sh exec -- true: 0`, `confine-tests: unshare body: line 3: exec: -a: not found` / `status 127`, and `dir: 126`. In probe 1, `command -- "$@" | eval echo hi` and `"$@" | eval echo hi` print `hi` under both shells. `$BASH` being the PATH's bash is pinned by test 16 (`call unshare 2 -rn -- "$TOOLS/bash" -c ...`, `test/scripts/confine-tests.bats:425`), which passes (E3).

**Evidence:** `$R/logs/probe-shells.txt`; `$R/logs/probe1.txt`; `$R/logs/bats-new.out`

---

## Claim 12: Prior failures: FP-050 (unshare tier shares the host's mount namespace), FP-044 and FP-057 (a fallback tier ran with less confinement), FP-058 (a bwrap failure at run time dropped work silently); the second grep's hits (FP-025, -032, -046, -067, -118, -134) concern other mechanisms.

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:73-79`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each entry's one-line symptom; does not re-run the two greps for completeness of the hit list.
**Legibility-target:** for-orchestrator-synthesis

`docs/failure-patterns.md:192` reads `FP-050 ... symptom:unshare-tier-shares-host-mount-namespace-host-writes`, `:186` reads `FP-044 ... symptom:fallback-tier-ran-with-network-intact`, `:199` reads `FP-057 ... symptom:fallback-tier-blocks-writes-but-not-reads-disclosure` and `:200` reads `FP-058 ... symptom:bwrap-runtime-failure-drops-the-computation-silently`. The other six are a `#` read as a comment (`:167`), single-quote injection (`:174`), shell state across calls (`:188`), a builtin-name collision (`:209`), pipeline status under errexit (`:260`) and an exit trap (`:276`), which matches the doc's list.

**Evidence:** `docs/failure-patterns.md:167,174,186,188,192,199,200,209,260,276`

---

## Claim 13: DD-1 match-table evidence: candidate 1 leaves "`-a x CMD` still runs `CMD` and exits 0"; 3 and 4 run the builtin `eval`; 5 reads "a name holding `=` ... as an assignment (`a=b z` set a variable and tried to run `z`)"; 12 "util-linux `unshare` has no such option".

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:117-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the probe-1 evidence rows and util-linux 2.38.1's help text; does not verify the judgment cells (C7-C10).
**Legibility-target:** for-orchestrator-synthesis

Probe 1 printed `exec env -- "$@" | a=b z -> ... | env: 'z': No such file or directory` and `"$@" | eval echo hi -> ... | hi`. Row 1's exit 0 comes from E1 (`sh=bash ... RUN:-a x REC one old= 0 ... child yes`). `unshare --help | grep -i loopback` prints nothing for `unshare from util-linux 2.38.1` (paraphrased: no quote available because the claim concerns the absence of an option, and the grep output is empty). The two survivors' cells were not re-scored.

**Evidence:** `$R/logs/probe1.txt`; `$R/logs/compare-analysis.txt`; `unshare --help` (exit 0)

---

## Claim 14: DD-2, "Other choices, one line each" (seven sentences: the function's argument shape; the two headlines and `command -v bwrap`, "which runs nothing"; `--no-loopback` without bwrap printing the fallback warning and naming both steps, a route that "At 23ffb16c ... printed no warning at all"; the `--no-loopback` warning "byte for byte what it was"; the body's `$0` and the example `confine-tests: unshare body: line 6: exec: -a: not found`; `sh` leaving the built PATH; the dash test's skip).

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:205-211`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each sentence against the bd312d15 code and E1; does not judge whether the choices are right.
**Legibility-target:** for-orchestrator-synthesis

In order: `warn_unshare_only` prints `$1`, the heredoc, `"... filesystem. $2"`, then `printf '  %s\n' "${@:3}"` (`scripts/confine-tests.sh:131-140`). `command -v bwrap` selects the headline (`:221`), and the script's refusal says `` `unshare -rn`, which is unusable here `` (`:178`). The `and_flag=" and drop --no-loopback"` branch (`:217-220`) is pinned by test 15 (`:401`). In E1, the `NL:*` runs at 23ffb16c with bwrap absent or refused print the banner alone. No probe differs in E1, and test 11 passes against 23ffb16c (E3). E1's new stderr for `-a x REC one` ends `confine-tests: unshare body: line 6: exec: -a: not found`. Setup links `bash cat awk` (`test/scripts/confine-tests.bats:65`). The skip reads `dash="$(type -P dash)" || skip "dash is not installed on this machine"` (`:463`).

**Evidence:** `$R/logs/compare-analysis.txt`; `$R/cmpout/new/*`; `$R/logs/bats-old.out`; `scripts/confine-tests.sh:131-140,216-230`

---

## Claim 15: Exit statuses table: `-record -x` gives 2 (bash `sh`) / own / own; `-a x CMD one` gives CMD's own, CMD ran / 127 / 127; `-nonexistent y` gives 2 / 127 / 127; `''` gives 127 / 126 (`exec: : Permission denied`) / 127.

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:290-297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all twelve cells on the unshare-with-loopback form, with bwrap absent or refused, under stand-ins; does not cover a real unshare.
**Legibility-target:** for-orchestrator-synthesis

E1's status-difference list contains exactly these rows for sh in {bash, dash}: `sh=bash args='RUN:-record -x' old= 2 new= 0 child no->yes`, `sh=bash args='RUN:-a x REC one' old= 0 new=127 child yes->no`, `sh=bash args='RUN:-nonexistent y' old= 2 new=127` and `sh=dash args='RUN:EMPTY' old=126 new=127`. The unchanged cells (dash `-record -x` own, dash `-a` and `-nonexistent` 127, bash `''` 127) appear as no-difference cases. E5 shows dash's `N: 1: exec: : Permission denied` / `126`.

**Evidence:** `$R/logs/compare-analysis.txt`; `$R/logs/probe-shells.txt`

---

## Claim 16: "Every other input the review compared, on every route, exits as before, and so does every `--probe`."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:299`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the review's inputs and, more widely, E1's matrix with `sh` as bash or dash. It does not establish that dash-named inputs outside the table keep their status: they do not (see below). It also does not cover a host with no `sh` at all, where every loopback unshare run changes.
**Legibility-target:** for-orchestrator-synthesis

In E1, 0 of the probe cases and 0 stdouts differ, no stand-in got an unexpected call, and no primitive differs (paraphrased: no quote available because this is a count over 2268 records in `$R/logs/compare-analysis.txt`). Caveat, with risk. With `sh` as bash, two dash-named inputs outside the table also change status: `sh=bash args='RUN:-- REC' old= 0 new=127 child yes->no` (a command word `--`: the old body's `exec -- REC` ran REC, the new `exec -- -- REC` looks for a command named `--`) and `sh=bash args='RUN:-p REC' old= 2 new=127`. Both start with `-`, so they belong to D1's class, and the new result matches what the stand-in gives on the bwrap form. They are not in the table. With no `sh` on PATH, the 23ffb16c script exits 127 on every loopback unshare run and the new one runs. That change is the doc's "a host with bash and no `sh` now works where it did not" (`:189`).

**Evidence:** `$R/logs/compare-analysis.txt`; `$R/cmpout/{old,new}/`

---

## Claim 17a: The mutation table's rows ("22 of 22 fail at least one test, and the unchanged script passes 21 of 21", and each row's failing tests) and the test-number key.

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:303-329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the re-run of `mutate.py` on bd312d15 (E2), each mutant's text, and the test order; does not show that 22 mutants exhaust the plausible regressions.
**Legibility-target:** for-orchestrator-synthesis

E2 printed `m00 control: the script unchanged: exit 0; failing tests: NONE` and `SURVIVORS: none`, and each of m01-m22 matches its table row exactly (for example `m09 ... failing tests: 14, 15, 20` and `m17 ... 15, 16, 17, 18, 19, 20, 21`). The table merges m04 and m05 into one row. I read every mutant in `mutate.py:47-70`. Each does what its name says, with one exception noted in 17b. m10's `fi 2>&1` sends the block's `>&2` to stdout. m16 inserts its line after the line that carries `$2`, so after the shared text. The key matches the `@test` order in `$R/logs/bats-new.out` (11 and 12 the `--no-loopback` switch and run, 14 the fallback probe, ..., 21 `lo` not raised).

**Evidence:** `$R/mut-run.txt`; `$R/mutate.py:47-70`; `$R/logs/bats-new.out`

---

## Claim 17b: Mutation-table row "the `--no-loopback` warning re-wrapped (the first version's line breaks)"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:326`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mutant's text against the de1f4bf9 function; does not affect the row's failing tests.
**Legibility-target:** for-author

Mutant m20 (`mutate.py:67`) ends the shared sentence on its own line and puts `"  $2"` on the next, leaving the later lines as they are now. The first version (`git show de1f4bf9:scripts/confine-tests.sh:166-168`) also re-wrapped the way back: `"Drop the flag to get the hardened profile (loopback is not egress — the"` / `"namespace has no route off the host)."`. m20 re-creates the first version's break after "filesystem." but not its later breaks. `mutate.py`'s own name is accurate ("shared sentence ends its line"). The doc's gloss is the loose part.

**Evidence:** `$R/mutate.py:67`; `git show de1f4bf9:scripts/confine-tests.sh`

---

## Claim 18: History: "In the first, the 'extra line' mutant passed every test: the comparison of shared text stopped at its fourth line. The test was strengthened (ca6cf3be), and the second run had no survivor (19 of 19). After review pass 1 ... three were added."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:331`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the three run logs and ca6cf3be's diff; the first two runs' mutant definitions no longer exist (`mutate.py` was rewritten), so the survivor's exact text is not checked.
**Legibility-target:** for-orchestrator-synthesis

`mutation-run-1.txt` lists 19 mutants with `m16 the shared text differs on the fallback route: exit 0; failing tests: NONE` and `SURVIVORS: ['m16 ...']`. `mutation-run-2.txt` lists 19 with `SURVIVORS: none`, and `mutation-run-3.txt` lists 22. ca6cf3be's test diff compares `"${stderr_lines[@]:1:4}"` and adds `[[ "${stderr_lines[5]}" == "  Install bwrap"* ]]`, which fits "stopped at its fourth line". Note the run-1 mutant was named "the shared text differs", not "extra line".

**Evidence:** author scratch `mutation-run-{1,2,3}.txt`; `git show ca6cf3be -- test/scripts/confine-tests.bats`

---

## Claim 19: "The test of the whole `--no-loopback` warning (test 11) also passes against the script at 23ffb16c"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test 11 of bd312d15 against the 23ffb16c script; does not cover the other 20 tests there (7 fail, as expected).
**Legibility-target:** for-orchestrator-synthesis

E3's `bats-old.out` has `ok 11 --no-loopback switches from bwrap to unshare and warns about what is lost, in either flag order`. The same test fails against the 6465a156 script (`not ok 1 ... \`[ "$stderr" = "$LO_WARNING_TEXT" ]' failed`, `$R/logs/c646-test11.txt`), so it does detect the re-wrap.

**Evidence:** `$R/logs/bats-old.out`; `$R/logs/c646-test11.txt` (`bats -f 'either flag order'`, cwd `$R/c646`, exit 1)

---

## Claim 20: Gates: the probe "exit 3"; "21 of 21 pass"; the lint "exit 0: '143 test file(s) checked, no unstubbed network spawns'"; shellcheck "(the health check's command) exit 0".

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:337-342`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four gates re-run at bd312d15 on this host; does not cover the whole suite (Claim 21).
**Legibility-target:** for-orchestrator-synthesis

E3 gave `probe exit 3` (first stderr line `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`), `bats exit 0` with 21 `ok`, `lint exit 0` (`hermeticity-lint: 143 test file(s) checked, no unstubbed network spawns.`) and `shellcheck exit 0`. `scripts/health-check.sh:525` runs `shellcheck -x -e SC1091 -s bash -S warning "$f"`.

**Evidence:** `$R/logs/{probe.err,probe.status,bats-new.out,lint.out,shellcheck.status}`; `scripts/health-check.sh:525`

---

## Claim 21: "`scripts/run-tests.sh` (whole suite, serial, output to a file) at ca6cf3be, before review | exit 0: 2012 of 2012 pass"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:343`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the author's `suite-1.txt` and `suite-1.head` as instructed (not re-run); does not establish the suite's state at bd312d15.
**Legibility-target:** for-author

`suite-1.head` reads `ca6cf3be`, and `suite-1.txt` ends `exit=0` with `1..2012`, 2012 `ok` lines and 0 `not ok`. Two of those are skips: `ok 1190 ... # skip settings file has no permissions.allow array` and `ok 1191 ... # skip ...`. The file also opens `=== NOT RUN: 50 report-dependent suite(s)`. The precise wording would be "2010 pass, 2 skip; 50 report-dependent suites not run".

**Evidence:** author scratch `suite-1.txt:1,1338-1339`, `suite-1.head`

---

## Claim 22: Review: "No red"; the re-wrap fix and that "The API pass advised correcting the claim"; the security-2 fix; "unusable here", the body's `$0`, "where bwrap works", "the first line of its stdout"; "Four wrong or loose sentences" (rules file line number; "ran `z`"; "238 code lines"; the `--probe` invariant); the two commit-message sentences that stand.

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:345-357`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the doc's summary against the pass-1 rubric; does not re-check the pass-1 reports' own verdicts.
**Legibility-target:** for-orchestrator-synthesis

The rubric (`docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md`) has `## 🔴 Must Fix ... None.` (`:13-18`). The rest map one to one onto rows: A1 ("The API critic advised keeping the re-wrap and correcting the claim", `:37`), C1/S2 (`:55`), C2, C3 and C4 (`:56-58`), A2 (`:38`), A3, A6 and A7 (`:39,42,43`), and A4 and A5, which stand (`:40-41`). bd312d15's code shows each fix (`scripts/confine-tests.sh:45-48,222,290`; guide `:63`).

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:13-58`

---

## Claim 23: "None does: the probe still asks bwrap for less than a run does (O1; the stand-in's two accepted argv shapes are unchanged), no primitive and no command still exits 3 (O3 ...), and the bwrap profile is untouched (O5)."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:361`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script and stand-in diff plus E1's no-primitive cases; does not evaluate O1/O5 under a real bwrap.
**Legibility-target:** for-orchestrator-synthesis

The diff leaves `detect_primitive`, the `exec bwrap` profile (`scripts/confine-tests.sh:253-264`) and `write_stub` untouched. In E1, every case with no usable primitive and argument set `""` or `--` has the same status (3) old and new, because no case with `bwrap=absent/refused, unshare=absent/refused` appears in the difference list.

**Evidence:** `git diff 23ffb16c..bd312d15 -- scripts/confine-tests.sh test/scripts/confine-tests.bats`; `$R/logs/compare-analysis.txt`

---

## Claim 24: "nothing shows that a real `unshare -rn` starts `"$BASH"`"; Risks: "The path is the one the kernel already ran the script from, and `-r` maps the caller to root ..., so reading it cannot be refused ... [inferred]"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:264,365`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Scope:** Covers the attempt to run a real primitive; establishes nothing about a real namespace.
**Legibility-target:** for-orchestrator-synthesis

E3's probe exits 3 (`confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE`), so no real `unshare -rn` can start here. Verifying this needs one confined run on a host where `unshare -rn` works. The doc marks it inferred and lists it as a follow-up.

**Evidence:** `$R/logs/probe.err`, `$R/logs/probe.status`

---

## Claim 25: "the four tests here that begin `[ "$(id -u)" -ne 0 ] || skip`" and "The test file is 516 lines"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:370-371`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four cited lines and the repo-wide grep for that guard; same caveat as Claim 3 on "begin" at `test/install-host.bats:680`.
**Legibility-target:** for-orchestrator-synthesis

`wc -l test/scripts/confine-tests.bats` gives `516`. The grep for `"$(id -u)" -ne 0 ] || skip` over `test/` returns exactly the four cited lines.

**Evidence:** `$R/logs/q1.txt`; `wc -l` (exit 0)

---

## Claim 26: "Docs: ... The guide's `Last verified:` date is not moved" and the `docs/roadmap.md:49` follow-up wording "exit 0: tests pass confined"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:376,382`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guide header and roadmap line at bd312d15.
**Legibility-target:** for-orchestrator-synthesis

`guides/test-hermeticity.md:7` still reads `Last verified: 2026-07-13`. `docs/roadmap.md:49` contains `exit 0: tests pass confined`.

**Evidence:** `guides/test-hermeticity.md:7`; `docs/roadmap.md:49`

---

## Claim 27: Guide paragraph: "When `bwrap` is not installed or is unusable, a run falls back to `unshare -rn`, which denies the network and nothing else: the tests run as uid 0 against the real filesystem. The run goes ahead, and first prints a warning on stderr that names what is absent. `--probe` names the primitive it found ... on the first line of its stdout."

**Location:** `guides/test-hermeticity.md:59-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers runs that start (refusals such as no `ip` print no warning, and the paragraph does not claim they do) and probe stdout under stand-ins; does not cover a real primitive.
**Legibility-target:** for-orchestrator-synthesis

E1 shows the warning prepended on every fallback run that reaches the banner, and probe line 1 is `confine-tests: primitive available: $primitive (loopback=$loopback)` on stdout (`scripts/confine-tests.sh:197`). The warning's text names the read-only rootfs, private /tmp, pid namespace and uid 0 (`:134-136`).

**Evidence:** `$R/logs/compare-analysis.txt`; `scripts/confine-tests.sh:131-140,196-200`

---

## Claim 28: Known gaps: "On the `unshare` fallback writes are not confined either (see 'Triage vs. ground truth')."

**Location:** `guides/test-hermeticity.md:183-184`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unshare run forms' argv and the cross-reference's target; does not test real writes.
**Legibility-target:** for-orchestrator-synthesis

Both unshare forms are `exec unshare -rn -- ...` with no bind or tmpfs options (`scripts/confine-tests.sh:285,292`). `## Triage vs. ground truth` is at guide `:42`, and the new paragraph sits under it (`:59`).

**Evidence:** `scripts/confine-tests.sh:284-292`; `guides/test-hermeticity.md:42,59-63`

---

## Claim 29: Header: "A weaker primitive is a warning, on every run. ... When bwrap is not installed or is unusable, the run falls back to unshare and goes ahead, and says first, on stderr, what that leaves unconfined. A --probe that falls back prints its verdict, which names the primitive, and not this warning."

**Location:** `scripts/confine-tests.sh:29-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every probe and run in E1. "On every run" holds for runs that start: refusals (no `ip`, `ip` failing at :287, nothing to run) print no warning, which `:209-212` states. It does not cover a real primitive.
**Legibility-target:** for-orchestrator-synthesis

The `fell_back` block (`:216-230`) runs after the probe's `exit 0` (`:196-200`) and before the banner (`:232`). E1 shows 0 probe differences, and on fallback runs the warning comes first.

**Evidence:** `$R/logs/compare-analysis.txt`; `scripts/confine-tests.sh:142-152,196-232`

---

## Claim 30: LOOPBACK header: "Where bwrap works, the script says so, in the fallback warning's words, on a run and on a --probe, and refuses outright when unshare is unusable. Where bwrap does not work, the flag changes nothing about the primitive, and a run prints the fallback's warning."

**Location:** `scripts/confine-tests.sh:42-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bwrap-ok and bwrap-absent/refused routes with `--no-loopback` in E1 and tests 11, 13 and 15. "In the fallback warning's words" holds for the shared lines, not the headline or the way back.
**Legibility-target:** for-orchestrator-synthesis

With bwrap ok, `:168-174` calls `warn_unshare_only` before the probe answers, which tests 11 and 12 cover, and exits 2 when unshare fails (`:175-181`, test 13). With bwrap absent or refused, `primitive` is already `unshare`, `:168` is skipped, and the run prints the fallback warning with "and drop --no-loopback" (test 15, `:400-401`).

**Evidence:** `$R/logs/bats-new.out`; `scripts/confine-tests.sh:168-183,216-230`

---

## Claim 31: warn_unshare_only's comment: "$2 is its first words, which finish the last shared line, and each further argument is a line of its own. That split keeps the --no-loopback warning byte for byte what it was before the text was shared, so no --probe prints anything it did not print before."

**Location:** `scripts/confine-tests.sh:124-130`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers stdout, stderr and status of every probe input in E1: 4 bwrap modes × 3 unshare × 3 ip × 3 `sh` states × 3 probe spellings (both flag orders), and the `--no-loopback` run routes with bwrap ok. It does not cover `--help`, which is untouched apart from the header text it prints.
**Legibility-target:** for-orchestrator-synthesis

The function body is `echo "confine-tests: WARNING — $1"`, three heredoc lines, `echo "  with EROFS will succeed against the real filesystem. $2"` and `printf '  %s\n' "${@:3}"` (`:131-140`). Called with the arguments at `:171-174`, it reproduces old `:137-143` byte for byte. E1 found `probe cases differing: 0`, and the `NL:*` runs with bwrap ok are absent from the stderr-difference list. Test 11 passes against 23ffb16c (Claim 19).

**Evidence:** `$R/logs/compare-analysis.txt`; `$R/logs/bats-old.out`

---

## Claim 32: "Detection settled for unshare: bwrap is not installed, or its probe failed."

**Location:** `scripts/confine-tests.sh:147-148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `detect_primitive`'s two branches; the `--no-loopback` switch later sets `primitive=unshare` without setting `fell_back`, which the comment does not claim.
**Legibility-target:** for-orchestrator-synthesis

`detect_primitive` (`:88-100`) returns `bwrap` only when `command -v bwrap` and the probe both succeed, and otherwise tries unshare. `fell_back=1` is set at `:149-152`, before the switch at `:168`.

**Evidence:** `scripts/confine-tests.sh:88-100,142-152`

---

## Claim 33: The fell_back comment: "only a run that is about to start prints it: --probe's output and the refusals above are unchanged. `command -v` runs nothing." and "bwrap cannot keep `lo` down, so the flag would switch to unshare again"

**Location:** `scripts/confine-tests.sh:209-215`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusals before `:216` (exit 3 no primitive, exit 2 flag refusal, exit 3 no `ip`, exit 2 nothing to run) in E1. The in-body refusal (`ip` failing, exit 3) comes after the warning by design and is not "above".
**Legibility-target:** for-orchestrator-synthesis

E1 found no status differences and no stderr differences on any refusal input with `sh` present. Test 15 pins the no-`ip` refusal as stderr's first line, and test 20 pins the nothing-to-run case. `command -v` is a bash builtin, and E1 recorded no unexpected stand-in call; the `bwrap` call counts in tests 14 and 20 (`calls bwrap 1 unshare 2 ip 0`) show no extra bwrap call. The selection block confirms the second sentence: with bwrap ok and loopback 0 it switches to unshare (`:168-171`).

**Evidence:** `$R/logs/compare-analysis.txt`; `$R/logs/bats-new.out`; `scripts/confine-tests.sh:168-205,216-230`

---

## Claim 34: Comment above the body: "`--` ends exec's options so a command named `-a` is run (or not found), never read as one"; "bash's exec takes options and needs the `--`, dash's takes none and would run `--` as the command"; "The body is the same text whatever the command".

**Location:** `scripts/confine-tests.sh:274-281`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12, and the stand-in argv; does not cover a real unshare.
**Legibility-target:** for-orchestrator-synthesis

E5: `dash: 1: exec: --: not found` (127) and `bash -c 'exec -- "$@"' ... -a x true one` gives `exec: -a: not found` (127). Test 16 compares the body across two commands (`[ "${first[4]}" = "${second[4]}" ]`, `test/scripts/confine-tests.bats:434`) and passes. Mutant m03 (`exec "$@"` under `$BASH`) fails tests 17 and 18 (E2).

**Evidence:** `$R/logs/probe-shells.txt`; `$R/mut-run.txt`; `scripts/confine-tests.sh:284-290`

---

## Claim 35: "The body's $0 names it, so bash's own errors read "confine-tests: unshare body: line N: ...", N a line of the body and not of this file."

**Location:** `scripts/confine-tests.sh:281-283`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash's not-found, is-a-directory and permission errors from the body; does not cover errors from the `ip` call.
**Legibility-target:** for-orchestrator-synthesis

E1's new stderr for `-a x REC one` ends `confine-tests: unshare body: line 6: exec: -a: not found`. Line 6 is the body's `exec -- "$@"` line, counting the empty first line after `'`; the file's line for it is 290. For a directory, the new stderr has `confine-tests: unshare body: line 6: ...: Is a directory`.

**Evidence:** `$R/cmpout/new/*` (KEY `sh=bash,bwrap=absent,unshare=ok,ip=ok,args=RUN:-a x REC one`); `scripts/confine-tests.sh:285-290`

---

## Claim 36: Test header: "Every test but one runs the script on a PATH built here: the real bash, cat and awk, plus stand-ins ... (no sh: the script runs none, and two tests add one to show it makes no difference)."

**Location:** `test/scripts/confine-tests.bats:8-11`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers setup and the two `dash_named_on_unshare` tests, plus the script's run forms; "makes no difference" is shown for the inputs those tests use.
**Legibility-target:** for-orchestrator-synthesis

Setup reads `for tool in bash cat awk; do` (`:65`), and only `dash_named_on_unshare` adds `ln -s "$1" "$TOOLS/sh"` (`:444`), used by tests 17 and 18. The script's run forms are `exec bwrap`, `exec unshare -rn -- "$BASH" -c` and `exec unshare -rn --` (`scripts/confine-tests.sh:253,285,292`), with no `sh`. With `sh` absent, the new script passes every unshare test (E3), and m01 (`sh -c` again) fails four tests that do not add `sh` (E2). Test 3 is the one without stand-ins (`:233`).

**Evidence:** `test/scripts/confine-tests.bats:65,233,444`; `$R/mut-run.txt`; `$R/logs/bats-new.out`

---

## Claim 37: LO_WARNING_TEXT: "The whole --no-loopback warning, byte for byte what the script printed before the fallback came to share its text"

**Location:** `test/scripts/confine-tests.bats:29-38`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test 11's comparison against the 23ffb16c script; see Claim 19.
**Legibility-target:** for-orchestrator-synthesis

Test 11 (`[ "$stderr" = "$LO_WARNING_TEXT" ]`, `:334`) passes against 23ffb16c (`ok 11` in `bats-old.out`) and fails against the re-wrapped 6465a156 script.

**Evidence:** `$R/logs/bats-old.out`; `$R/logs/c646-test11.txt`

---

## Claim 38: confine(): "Fails the test ... when -STATUS is given and is not the exit status (bats' `run -N`; it warns about a 127 it was not told to expect)."

**Location:** `test/scripts/confine-tests.bats:149-154`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this host's bats-core (`/usr/lib/bats-core`); does not cover bats versions before 1.5.0, which the file refuses with `bats_require_minimum_version 1.5.0`.
**Legibility-target:** for-orchestrator-synthesis

The E4 run at d03a3078 printed `BW01: \`run\`'s command ... exited with code 127, indicating 'Command not found'. Use run's return code checks, e.g. \`run -127\`, to fix this message.` for tests that got an unexpected 127. Mutant m03, where `-a x RECORD one` runs RECORD and exits 0, fails test 17 at `confine -127` (E2). `want=("$1")` is passed as `run "${want[@]}"` (`:157,162`).

**Evidence:** `$R/percommit/d03a3078.out`; `$R/mut-run.txt`; `test/scripts/confine-tests.bats:155-165`

---

## Claim 39: same_process: "This cannot see the body's own exec: the body runs under bash, which runs the last command of a -c string in place with or without it. The test with a command named eval sees it."

**Location:** `test/scripts/confine-tests.bats:167-172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mutants m04 (`"$@"`) and m05 (`command -- "$@"`); does not cover a body with a command after the last line.
**Legibility-target:** for-orchestrator-synthesis

E2: `m04 bare "$@" in the body: ... failing tests: 17, 18, 19` and `m05 command -- "$@" ...: 17, 18, 19`. Test 16, which calls `same_process` (`:419`), passes under both, so `same_process` cannot see the missing `exec`. Test 19 (the `eval` test) fails under both. Tests 17 and 18 fail on the error text (`-a: command not found` against `exec: -a: not found`), not on `same_process`.

**Evidence:** `$R/mut-run.txt`; `test/scripts/confine-tests.bats:409-474`

---

## Claim 40: The names and comments of the new or changed tests 14-20 (and the `dash_named_on_unshare` comment "a body that ends `exec "$@"` under sh runs `-a x CMD one` as CMD where sh is bash")

**Location:** `test/scripts/confine-tests.bats:367-508`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its body and the mutants that break it; tests 17 and 18 "fail on one that names no file" is shown for `-a` only.
**Legibility-target:** for-orchestrator-synthesis

Each name matches what its body asserts. Test 14 checks the probe verdict and `[ -z "$stderr" ]` on both routes. Test 15 checks the refusal as the first stderr line on probe and run, and `--no-loopback` served with the fallback warning. Test 16 checks `"$TOOLS/bash" -c BODY NAME CMD...` and that BODY is the same for two commands. Tests 17 and 18 check the dash-named run with status 7 and `-a x ... one` giving 127 with `exec: -a: not found`. Test 19 checks that the file `eval` ran with `touch pwned` and that no `pwned` appeared. Test 20 checks the exact stderr on three routes plus nothing to run. The mutants confirm each one (m08 → 15, 20; m09 → 14; m01 → 16; m03 → 17, 18; m04 → 19). Probe 1 confirms the helper comment (`RAN rec: [one]` under sh-bash).

**Evidence:** `$R/mut-run.txt`; `$R/logs/probe1.txt`; `$R/logs/bats-new.out`

---

## Claim 41a: d03a3078: "7 of the 21 fail at this commit"; "an unshare run with sh linked to bash refuses `-record -x` (exit 2, 'exec: -r: invalid option')"; "With sh linked to dash the same test fails only on the name bash's error will carry after the fix."

**Location:** `git log` d03a3078
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d03a3078's test file against its own script.
**Legibility-target:** for-orchestrator-synthesis

E4 gave `== d03a3078: 14 ok, 7 not ok` (tests 15-21). Test 17 shows `status: 2`, `sh: line 6: exec: -r: invalid option`. Test 18 passes its status checks and fails at the name match, with stderr `sh: 6: exec: -a: not found`.

**Evidence:** `$R/percommit/d03a3078.out`

---

## Claim 41b: d03a3078: "each for the reason it names"

**Location:** `git log` d03a3078
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seven failures' first failing assertions; already recorded as standing (rubric A4, research doc `:355`).
**Legibility-target:** for-author

Test 20, named in the commit as "prints no warning: defect D2", fails at d03a3078 on `[ "$status" -eq 7 ]` with `exec: sh: not found`, not on the missing warning. The commit's third bullet covers that reason only for "the unshare run tests". The research doc's Review section (`:355`) and rubric A4 already record this (rubric verdict "Mostly accurate"). I verdict it Incorrect because the stated mechanism is wrong for one of the seven.

**Evidence:** `$R/percommit/d03a3078.out`; `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:40`

---

## Claim 42: bd657ce8: "`-- -a x CMD one` ran CMD and exited 0, and `-- -record -x` was refused"; "a dash-named command runs with its arguments, and a name that is no file exits 127 with nothing run in its place. The script no longer needs sh."; "Tests: 19 of 21 pass; the two left are the fallback warning (next commit)."

**Location:** `git log` bd657ce8
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bd657ce8's tests against its script and E1's old/new rows; does not cover a real unshare (the commit says so).
**Legibility-target:** for-orchestrator-synthesis

E4 gave `== bd657ce8: 19 ok, 2 not ok`. The two failures are tests 15 and 20, both at `[ "${stderr_lines[0]}" = "$NO_BWRAP_WARNING" ]`. For the behaviour, see Claim 15.

**Evidence:** `$R/percommit/bd657ce8.out`; `$R/logs/compare-analysis.txt`

---

## Claim 43a: 6465a156: "--probe is unchanged for every input"

**Location:** `git log` 6465a156
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 6465a156 script (identical to de1f4bf9's) on the `--no-loopback --probe` route with bwrap working; already recorded as standing (rubric A5, research doc `:355`, bd312d15's body).
**Legibility-target:** for-author

Test 11 of bd312d15 fails against the 6465a156 script: `` `[ "$stderr" = "$LO_WARNING_TEXT" ]' failed `` (the warning was re-wrapped). The commit's own "Tests: 21 of 21 pass" is Verified (E4: `== 6465a156: 21 ok`). Its sentence "its line breaks moved so the shared sentences end on line boundaries" was true of that commit and was reverted in bd312d15.

**Evidence:** `$R/logs/c646-test11.txt`; `$R/logs/percommit.txt`

---

## Claim 43b: ca6cf3be: "Each route's way back to bwrap's profile must now start on the sixth line, so the text between the headline and it is the same four lines everywhere. 19 of 19 mutants now fail at least one test; the unchanged script passes 21 of 21."

**Location:** `git log` ca6cf3be
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ca6cf3be, where the counts hold (E4 `== ca6cf3be: 21 ok`; `mutation-run-2.txt` 19 with no survivor), and bd312d15, where the shape statement no longer holds.
**Legibility-target:** for-author

At bd312d15 the way back starts mid-line on line 5 (`echo "  with EROFS will succeed against the real filesystem. $2"`, `scripts/confine-tests.sh:138`), and test 20 compares whole texts, not lines 1-4 and 6. The research doc records the change (`:331`: "After review pass 1 changed the warning's shape, the mutants were rewritten").

**Evidence:** `$R/logs/percommit.txt`; author scratch `mutation-run-2.txt`; `scripts/confine-tests.sh:131-140`

---

## Claim 44: de1f4bf9 "Size: 238 code lines against 23ffb16c" and bd312d15 "Size: 270 code lines against 23ffb16c"; bd312d15 "passes against the script at 23ffb16c too", "Tests: 21 of 21; 22 of 22 mutants fail at least one test", and its "Not changed" list.

**Location:** `git log` de1f4bf9, bd312d15
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The mostly-accurate part is the two Size lines. The test, mutant, 23ffb16c and Not-changed sentences are Verified, and so is the pre-mortem's corrected wording. This claim does not cover the review reports added in bd312d15.
**Legibility-target:** for-author

`git diff --numstat 23ffb16c..bd312d15` gives `78 13 scripts/confine-tests.sh`, `132 36 test/scripts/confine-tests.bats` and `9 2 guides/test-hermeticity.md`. Script and test come to 259, and 270 counts the guide's 11 markdown lines as code, the same counting rubric A7 called loose in de1f4bf9's "238" (227 code). The precise lines would be "259 code lines (270 with the guide)" and "227 (238 with the guide)". The de1f4bf9 message stands as recorded (A7); bd312d15 repeats the convention. The rest is confirmed: E3 (`ok 11` against 23ffb16c, 21 of 21) and E2 (`SURVIVORS: none` over m01-m22). The Not-changed items match rubric A4, A5, C6 and C7.

**Evidence:** `$R/logs/q1.txt`; `$R/logs/bats-old.out`; `$R/mut-run.txt`; `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:40-61`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:14`): the prior-art grep returns 17 files (including decision 019, briefs, cycle logs), not "decision 017, the two earlier confine-tests research docs and this unit's own". Correct the result list, or narrow the pattern.
- **Claim 41b** (commit d03a3078): "each for the reason it names". Test 20 fails on `exec: sh: not found`. Already recorded (rubric A4, research doc `:355`). It cannot be edited.
- **Claim 43a** (commit 6465a156): "--probe is unchanged for every input" was false at that commit (re-wrapped `--no-loopback` warning). Already recorded (rubric A5, research doc `:355`, bd312d15's body).

### Stale
- **Claim 43b** (commit ca6cf3be): "the way back must now start on the sixth line". Since bd312d15 it starts mid-line on line 5, and test 20 compares whole texts. Recorded in the research doc `:331`.

### Mostly Accurate
- **Claim 4** (`docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:35`): the grep "finds none". It finds a comment at `test/fixture-hermeticity.bats:15`. Say "finds no caller".
- **Claim 17b** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:326`): mutant m20 is not "the first version's line breaks". It re-creates only the break after "filesystem.".
- **Claim 21** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:343`): "2012 of 2012 pass" includes 2 skips, and 50 report-dependent suites were NOT RUN.
- **Claim 44** (commits de1f4bf9, bd312d15): "238"/"270 code lines" each count the guide's 11 markdown lines. The code lines are 227 and 259.

(Not counted above: Claims 3 and 25 are Verified with a minor note. `test/install-host.bats:680` does not *begin* with the uid guard, because `need_script;` comes first.)

### Unverifiable
- **Claim 24** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:264,365`): that `"$BASH"` starts under a real `unshare -rn` needs one confined run on a host where unshare works. This container's probe exits 3.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback/docs/reviews/code-fact-check-report-final-rN-2026-11-10-confine-tests-dash-and-fallback.md (N your replicate number), structured per the code-fact-check skill, with a first line `Commit: bd312d15` and a bolded `**Commit:** bd312d15` header field.
- Answered: yes (N = 2)
- Out of scope: the whole-suite run (read from the author's suite-1.txt as instructed, not re-run); a real namespace (the container cannot create one); the earlier pass's reports' own verdicts, which were read only to check fixes.
- Escalate: (1) For api-consistency, Claim 16's caveat: on a host where `sh` is bash, `confine-tests.sh -- -- CMD` (a command word `--`) used to run CMD with exit 0 and now exits 127, and `-- -p CMD` goes from 2 to 127. Both are dash-named, so they belong to D1's class and match the bwrap form, but the research doc's Exit-statuses table does not list them. One row or one sentence would cover them. (2) The pre-mortem's prior-art sentence (Claim 2) is a new Incorrect that the earlier pass did not catch.
- Decisions I made: I verdicted d03a3078's "each for the reason it names" Incorrect where rubric A4 has Mostly accurate, because the skill puts a refuted mechanism at Incorrect. I counted the pre-existing comment at `test/fixture-hermeticity.bats:15` as a grep hit but not a caller. I discarded my first E1 run because of a harness bug (bats' `run` overwrote my loop variable) and cited only the corrected re-run.
