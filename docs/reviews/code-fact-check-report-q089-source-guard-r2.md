Commit: cb428e81

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `wt-2026-11-05-q089-source-guard-narrow`, branch `test/q089-source-guard-narrow`)
**Scope:** `git diff db31db8b..cb428e81 -- test/cc-host-tool-sources.bats docs/working/research-2026-11-05-q089-source-guard-narrow.md`, plus the commit messages of `git log db31db8b..cb428e81`
**Checked:** 2026-11-05
**Replication:** k=3 replicate, final pass
**Total claims checked:** 53
**Summary:** 44 verified, 5 mostly accurate, 4 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). No claim here matches a logged pattern. Claims 15, 27a, 28 and 29 are counts or descriptions that were true at 8880c925 and were not carried forward, so they are Stale, not fabrications, and no entry qualifies.

Shorthand: `R` is `docs/working/research-2026-11-05-q089-source-guard-narrow.md`, `T` is `test/cc-host-tool-sources.bats`, `FC` is `/tmp/claude-1000/-workspace/47403b7b-5fcb-4e13-8807-c539081df064/scratchpad/2026-11-05-q089-source-guard-narrow/fc`, and `R2` is the same path ending in `fc-r2`.

Prior report (k=1 at 8880c925) was read for its evidence only. Every behavioural claim below was re-derived at cb428e81; stored output in `FC` was reused only where the input it ran on is unchanged on this branch (`git diff --stat db31db8b..cb428e81 -- test/cc-isolated-functions.bats test/cc-push.bats devcontainer-config` is empty, E6).

## Execution log

Every run used a scratch copy made by `git archive cb428e81` under `R2`, or a copy of `FC/seeds`. The worktree's code was not edited. cwd of each command was the worktree; each script then creates and enters its own directory. Times are UTC, 2026-11-06. Output stays in `R2` because the dispatch limited this pass to this one file.

| Id | Command | Exit | Time | Output |
|---|---|---|---|---|
| E1 | `timeout 300 bash R2/r2a.sh` (baseline, `check_entry` mutations, seeds D1-D3 with the cb428e81 file, last-line probe, `)` detector, directory probes, list read) | 0 | 03:40:11 | `R2/r2a.out` |
| E2 | `timeout 200 bash R2/r2b.sh` (each stated limit through the real case 1, ordering, stand-ins) | 0 | 03:40:24 | `R2/r2b.out` |
| E3 | `timeout 420 bash R2/r2c.sh` (name and order mutations against the 11 filtered host-tool tests of `test/cc-isolated-functions.bats` and the installed-copy test of `test/cc-push.bats`; not a whole suite) | 0 | 03:40:31 | `R2/r2c.out` |
| E4 | `timeout 120 bash R2/r2d.sh` (reads, history, transitive no-newline probe) | 0 | 03:41:29 | `R2/r2d.out` |
| E5 | `timeout 60 bash R2/r2e.sh` (citations, 8880c925's `check_entry`) | 0 | 03:42:14 | `R2/r2e.out` |
| E6 | `timeout 30 bash R2/r2f.sh` (step 1a count, unchanged-suite check, leftover-probe check) | 0 | 03:43:13 | `R2/r2f.out` |
| E7 | `timeout 30 bash R2/r2g.sh` (`cmp` of the stored baselines, enclosing function of `:527`, line numbers in `FC/forms.sh`) | 0 | 03:47:43 | `R2/r2g.out` |

Reused from the k=1 pass, because their inputs are unchanged: `FC/seed-runs.out`, `FC/seed-s3.out`, `FC/s1fix.out`, `FC/s3-live.out`, `FC/s3p.out`, `FC/forms.out`, `FC/forms2.out`.

---

## Claim 1: "Brief: `docs/working/briefs/2026-11-05-q089-source-guard-narrow.md` (dispatched at db31db8b)."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the brief's existence and db31db8b being this branch's base; does not establish the brief's content against the doc.
**Legibility-target:** for-orchestrator-synthesis

The file exists at that path, and `git merge-base main cb428e81` printed `db31db8b054da3fda3e34e08ba849ff2698e60e2` (paraphrased — no quote available because the claim is about file presence and a git command's output).

**Evidence:** `docs/working/briefs/2026-11-05-q089-source-guard-narrow.md`

---

## Claim 2: "FP-082 (a literal grep broken by an inserted argument) ... The test keeps fa059477's positive control (both entry points must reach `cc-gitdir.sh`), and a missing check call fails, so neither case passes empty."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:10-12`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the FP-082 gloss and the two fail-closed paths in `check_entry`; does not establish that every malformed list shape is refused, though a call with no matching spelling does reach the first path.
**Legibility-target:** for-orchestrator-synthesis

`docs/failure-patterns.md:224` reads `symptom:literal-adjacency-grep-broken-by-inserted-argument`. `[ -n "$args" ] || { echo "no verify_host_tools call in $entry"; return 1; }` (`T:46`) and `[[ " ${SOURCED[*]} " == *" cc-gitdir.sh "* ]] || { echo "parse missed cc-gitdir.sh for $entry: ${SOURCED[*]}"; return 1; }` (`T:54`) are both exercised by case 8, which passes (`ok 8`, E1).

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `test/cc-host-tool-sources.bats:44-54`, `test/cc-host-tool-sources.bats:121-133`, `docs/failure-patterns.md:224`, `R2/r2a.out`

---

## Claim 3: "FP-175 (`echo | grep -q` SIGPIPE under pipefail): the source of R2's 1-in-25 flake. The new file does not source the launcher into the test shell, so it has no pipefail, and it still uses a here-string."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:13`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the shared mechanism (a `grep -q` pipe's writer killed by SIGPIPE under pipefail) and the test's shell; does not establish that FP-175 records R2's flake, which it does not: FP-175 is a later incident with the same mechanism, and R2's pipe was `host_tool_files | grep -q`, not `echo | grep -q`.
**Legibility-target:** for-orchestrator-synthesis

The Q-089 rubric's R2 row says the test "is flaky under the sourced script's pipefail (`host_tool_files \| grep -q` SIGPIPE, 1/25 runs)" (`docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:20`). FP-175 is dated `2026-10-29` (`docs/failure-patterns.md:317`), after that rubric. The launcher is only sourced in a child: `hosts="$(bash -c 'source "$1"; host_tool_files' _ "$dir/cc-isolated.sh")"` (`T:55`). The here-string is `grep -qx -- "$f" <<< "$hosts"` (`T:58`). `set -euo pipefail` is at `devcontainer-config/cc-isolated.sh:79`, so the child has it; the child only echoes.

**Evidence:** `test/cc-host-tool-sources.bats:55-58`, `docs/failure-patterns.md:317`, `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:20`, `devcontainer-config/cc-isolated.sh:79`

---

## Claim 4: The rubric quotes: "scope the claim honestly: it guards plain spellings against accidental drift and is not complete for bash." and "would be forced into `host_tool_files` by tests, but the launcher would still source it unchecked."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:17`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both quotes and the list of forms; does not establish the summary "Every pass converged on the runtime code" beyond what the rubric's own gate section says.
**Legibility-target:** for-orchestrator-synthesis

Rubric `:97`: "its first job is to scope the claim honestly: it guards plain spellings against accidental drift and is not complete for bash." Rubric `:35`: "A new helper sourced by the scan would be forced into `host_tool_files` by tests, but the launcher would still source it unchecked." The forms are at `:94`: "(`FOO=1 . f`, case arms, `\. f`, quoted or obfuscated `source`, `$c f`)".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:35`, `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:92-97`

---

## Claim 5: "baseline: 260 ok, 0 failed, `LC_ALL=C`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named suites, unchanged on this branch; does not establish the whole repo suite, which the doc does not claim.
**Legibility-target:** for-orchestrator-synthesis

`FC/seed-runs.out` holds `--- base existing: ok=260 not-ok=0`. The whole-suite run was not repeated, per the dispatch; `test/cc-isolated-functions.bats`, `test/cc-push.bats` and `devcontainer-config` have no diff on the branch (E6 prints `0`). `rg -c '^@test'` gives 212 and 48, which sum to 260.

Reused command `bash FC/seed-runs.sh`, exit 0, 2026-11-06T03:04:09Z to 03:06:15Z (`FC/seeds.status`).

**Evidence:** `FC/seed-runs.out`, `R2/r2f.out`

---

## Claim 6: The D1-D3 table: D1 "1 fails, `test/cc-push.bats:803`"; D2 "1 fails: `test/cc-isolated-functions.bats:1193`"; D3 "**260 ok, 0 failed**"; and the "This test" column's three messages

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:25-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all six cells, with the "This test" column rerun at cb428e81; does not establish that D1's and D3's message is the only failing case in the file (at cb428e81 D1 fails cases 1, 4, 6 and 8, and D3 fails 1 and 6).
**Legibility-target:** for-orchestrator-synthesis

`FC/seeds/s1/existing.out`: `# (in test file test/cc-push.bats, line 803)` with `` `[ "$status" -eq 0 ]' failed ``, which is the `--help` run at `test/cc-push.bats:802-803`, in a fixture that copies only `cc-push.sh` and `cc-gitdir.sh` (`:800`). `FC/seeds/s2/existing.out`: `# (in test file test/cc-isolated-functions.bats, line 1193)`, and E3's fresh mutation at cb428e81 failed at the same line. `FC/seed-s3.out`: `existing: ok=260 not-ok=0`. With the cb428e81 bats file, E1 printed `# cc-push.sh sources cc-exit-scan.sh unchecked`, `# cc-isolated.sh sources cc-gitdir.sh unchecked` and `# cc-isolated.sh sources cc-helper.sh unchecked`.

Commands `bash R2/r2a.sh` and `bash R2/r2c.sh`, cwd worktree, exit 0, 03:40:11Z and 03:40:31Z.

**Evidence:** `test/cc-push.bats:797-808`, `test/cc-isolated-functions.bats:1193`, `FC/seed-runs.out`, `FC/seed-s3.out`, `R2/r2a.out`, `R2/r2c.out`

---

## Claim 7: "Dropping a name in use today is caught, directly (`cc-isolated-functions.bats:1193`, `cc-push.bats:807`)"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three pairs (launcher and `cc-exit-scan.sh`, launcher and `cc-gitdir.sh`, `cc-push.sh` and `cc-gitdir.sh`), each dropped and run against the filtered host-tool tests; does not establish the unfiltered suites' full failure sets.
**Legibility-target:** for-author

The conclusion holds for all three drops. The line citation is off by one for `cc-push`: the drop fails at `:806`, not `:807`. E3 printed `# (in test file test/cc-push.bats, line 806)`, which is `[ "$status" -eq 1 ]`, and bats stops there; `:807` (`[[ "$output" == *"ERROR: cc-push refuses to run:"*"cc-gitdir.sh changed since the last bless"* ]]`) is the next line and is not reached. `:1193` is exact. The citations also omit the third pair: dropping `cc-exit-scan.sh` fails at `test/cc-isolated-functions.bats:1153` and `:1180`.

Precise version: `cc-push.bats:806-807`, and add `cc-isolated-functions.bats:1153` if all the names are meant.

Command `bash R2/r2c.sh`, cwd worktree, exit 0, 03:40:31Z.

**Evidence:** `test/cc-push.bats:805-807`, `test/cc-isolated-functions.bats:1153`, `test/cc-isolated-functions.bats:1180`, `test/cc-isolated-functions.bats:1193`, `R2/r2c.out`

---

## Claim 8: "D1's catch is a fixture accident, and with the fixture copying the file `test/cc-push.bats` passes 48 of 48 with the seed in."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `test/cc-push.bats` with the fixture extended; does not establish the same for `test/cc-isolated-functions.bats`, which D1 does not fail.
**Legibility-target:** for-orchestrator-synthesis

`FC/s1fix.out` opens `1..48` and holds 48 `ok` lines and no `not ok` line (paraphrased — no quote available because the claim is a count over a captured TAP file). The fixture at `test/cc-push.bats:800` copies `"$BATS_TEST_DIRNAME/../devcontainer-config/cc-push.sh" "$BATS_TEST_DIRNAME/../devcontainer-config/cc-gitdir.sh"` only.

**Evidence:** `test/cc-push.bats:800`, `FC/s1fix.out`

---

## Claim 9: "D3 ran the two suites above; `test/cc-verify.bats` and `test/install-host.bats` also need `cc-helper.sh` in a fixture, and with that they match the baseline. The full suite was not run on the seed."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the captured runs; "match the baseline" for `test/install-host.bats` means the same one failure (`not ok 9 T9`) on both sides, not an all-green run.
**Legibility-target:** for-orchestrator-synthesis

`cmp FC/base-cc-verify.out FC/s3p2-cc-verify.out` and `cmp FC/base-install-host.out FC/s3p3-install-host.out` both report no difference (E7 prints `same-cc-verify` and `same-install-host`). Each install-host output has one `not ok` line, `not ok 9 T9 installed hooks still find lib/ and ../scripts (log-usage smoke test)`, so the baseline it matches is not clean; that failure is present without the seed.

Command `bash R2/r2g.sh`, cwd worktree, exit 0, 03:47:43Z.

**Evidence:** `FC/base-cc-verify.out`, `FC/s3p2-cc-verify.out`, `FC/base-install-host.out`, `FC/s3p3-install-host.out`, `R2/r2g.out`

---

## Claim 10: "a tampered helper ran with `HOST_TOOLS_ERR` empty, while the `cc-gitdir.sh` control was refused. So after the fixes the suite asks for, the installed launcher would source a file with no hash check, and nothing says so. That breaks row 71's stated rule ("Each entry point checks the host tools it executes before sourcing them")"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seeded tree sourcing the launcher; does not establish a real install, and the probe used a bless-shaped manifest rather than `--bless`.
**Legibility-target:** for-orchestrator-synthesis

`FC/s3-live.out`: `HOST_TOOLS_ERR=[]`, `tampered helper RAN at source time`, then `control: tampered gitdir refused, did not run`. Row 71 reads "Each entry point checks the host tools it executes before sourcing them" (`docs/decisions/log.md:94`).

Reused command `bash FC/s3-live.sh`, 2026-11-06T03:07Z, exit 0.

**Evidence:** `FC/s3-live.out`, `FC/s3-live.sh`, `docs/decisions/log.md:94`

---

## Claim 11: "The sourced set has not changed since Q-089, and `cc-verify.sh` joined the host tools without sourcing anything. ... row 71 places this under non-targeted tampering, as defence in depth."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:31`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `source "` line history in the five `cc-*.sh` files and row 71's text; does not establish other load spellings in history.
**Legibility-target:** for-orchestrator-synthesis

`git log -G'^[[:space:]]*source "'` over those files tops out at `4be0445d feat(cc-push): check itself and cc-gitdir.sh against host-tools.sha256 before sourcing (Q-0...` and `f2533b33 feat(cc-isolated): host-only tools get their own trust manifest (Q-089 unit A1)`. A load-spelling grep over `devcontainer-config/cc-verify.sh` prints nothing (E5). Row 71 ends "Those are row 45's existing threat model: non-targeted host tampering, defence in depth." (`docs/decisions/log.md:94`).

**Evidence:** `R2/r2d.out`, `R2/r2e.out`, `docs/decisions/log.md:94`

---

## Claim 12: Constraint and option-table facts: "no matches found ... beyond decision 017's "grep table in the bats suite"", "about 100 lines of test", "two byte-pinned copies", "a tool the repo's tests do not otherwise need"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:35-48`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these four facts and the S/H labels against `docs/constraints.md`; the prior pruning grep's "no matches" was not rerun in full, only the decision 017 hit, and the verdicts in the option table are design rationale and are not checked.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/017-polyglot-test-hermeticity.md:125`: "[1 grep table in the bats suite]: H2 is structural — a bats test in *this* repo cannot lint another repo". `rg -vc '^\s*(#|$)' test/cc-host-tool-sources.bats` printed `102`. `@test "verify_host_tools is the same code in cc-isolated.sh and cc-push.sh"` is at `test/cc-isolated-functions.bats:1134`. `rg -l shfmt test scripts hooks` printed only `hooks/auto-approve-allowed-commands.sh`, no test. `docs/constraints.md:17` (S3) has "one source of truth per rule or grammar".

**Evidence:** `docs/decisions/017-polyglot-test-hermeticity.md:125`, `test/cc-isolated-functions.bats:1134`, `docs/constraints.md:17`

---

## Claim 13: "`cc-verify.sh` shipped a grammar for the same rule after this test was split off (its comment cites Q-147)."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers order and the comment; "same rule" is the spelling rule, not list membership, which `source_lines_ok` does not check.
**Legibility-target:** for-orchestrator-synthesis

`git log -S'source_lines_ok()'` gives `d5fa26c1 2026-10-20`; fa059477 is `2026-10-14`. `devcontainer-config/cc-verify.sh:45-46`: "are not seen (as row 71's\n# Q-147)".

**Evidence:** `devcontainer-config/cc-verify.sh:41-46`, `R2/r2d.out`

---

## Claim 14: "and it is shorter."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the check itself, 18 code lines of `check_entry` against 27 for fa059477's test; does not establish that the file is shorter, since this file's 102 code lines are mostly seeded cases the old test did not have.
**Legibility-target:** for-orchestrator-synthesis

E4 printed `old test code lines 27 raw 40` and, for `check_entry`, `18`. `setup` adds three lines for the extraction (`T:24-27`).

Command `bash R2/r2d.sh`, cwd worktree, exit 0, 03:41:29Z.

**Evidence:** `test/cc-host-tool-sources.bats:21-30`, `test/cc-host-tool-sources.bats:42-60`, `R2/r2d.out`

---

## Claim 15: "The cost is one rename: `source_lines_ok` does not know `$CC_PUSH_DIR`, so the test renames that variable in its copy of `cc-push.sh`."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sentence's description of the code at cb428e81; the first half (the grammar does not know `$CC_PUSH_DIR`) stays true, as Claim 41 shows.
**Legibility-target:** for-author

This was true at 8880c925: `sed -i 's/CC_PUSH_DIR/CC_ISOLATED_DIR/g' "$dir/cc-push.sh"` (8880c925's `check_entry`, `R2/r2e.out`). cb428e81 changed the code to every copy, and added a second adjustment, but left this sentence:

```bash
# test/cc-host-tool-sources.bats:47-50
for f in "$dir"/cc-*.sh; do
  sed -i 's/CC_PUSH_DIR/CC_ISOLATED_DIR/g' "$f"
  echo >> "$f"
done
```

The doc is now inconsistent with itself: `R:62` records the newline step, and cb428e81's message says the rename "covered only cc-push.sh" as the defect it fixed. What the code does: it renames in every `cc-*.sh` copy and appends a newline to each. Precise version: "The cost is a rename: ... so the test renames that variable in its copies."

**Evidence:** `test/cc-host-tool-sources.bats:47-50`, `R2/r2e.out`

---

## Claim 16: The reach lists ("a sample of 19 spellings"; seen by fa059477 only, by `source_lines_ok` only, by both, by neither, with the outside-the-sample forms)

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 19 sampled spellings and the five named outside forms, with "seen" meaning noticed by the detector, whether accepted or refused; does not establish "anything with the word on the line" for every construct, only the three named examples.
**Legibility-target:** for-orchestrator-synthesis

`FC/forms.out` has 19 rows and sorts 3 / 1 / 10 / 5 as the doc says: for example `FOO=1 source "$D/h.sh"   seen   miss`, `\. "$D/h.sh"   miss   seen`, `so""urce "$D/h.sh"   miss   miss`. `FC/forms2.out` has `trap 'source "$D/h.sh"' EXIT   seen   miss`, `bash -c 'source "$D/h.sh"'   seen   miss`, `exec . "$D/h.sh"   seen   miss` and `eval "$x"   miss   seen`. The regexes in `FC/forms.sh:10-12` equal those at fa059477 (`FC/fa-cif.bats:1049-1051`, compared in E4), and `source_lines_ok` has no diff on the branch.

Reused command `bash FC/forms.sh`, exit 0, 2026-11-06T03:05Z.

**Evidence:** `FC/forms.out`, `FC/forms2.out`, `FC/fa-cif.bats:1049-1051`, `R2/r2d.out`

---

## Claim 17: "The real loss is the one-line case arm, which is these files' own idiom: an unchecked `--x) source ...` in `cc-push.sh` leaves the test green. It is accepted and the file header names it."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one-line arms in `cc-push.sh` and the test staying green at cb428e81; "the real loss" is a judgment and is not checked.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/cc-push.sh:437`: `--yes)    yes=1; shift ;;`; a pattern count gives 7 such arms. E2: `case   rc=0` for `case x in x) source "$CC_PUSH_DIR/cc-exit-scan.sh" ;; esac` appended to `cc-push.sh`. `T:10` has "one-line case arms". The detector's prefix class is `(^|[\;\&\|\{\(\!\`]|then|do|else|if|elif|while|until|time)` (`devcontainer-config/cc-verify.sh:56`), with no `)`.

Command `bash R2/r2b.sh`, cwd worktree, exit 0, 03:40:24Z.

**Evidence:** `devcontainer-config/cc-push.sh:434-438`, `devcontainer-config/cc-verify.sh:56`, `test/cc-host-tool-sources.bats:10`, `R2/r2b.out`

---

## Claim 18: "adding `)` to its detector alone refuses today's launcher on prose."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `)` added to the character class only, on a copy, with an unmodified control; does not establish that a fuller fix would be refused, or the cost of one.
**Legibility-target:** for-orchestrator-synthesis

With `arch/f1.py`'s one-character edit applied to a scratch `cc-verify.sh`, E1 printed for `cc-isolated.sh` `rc=1` with the line `echo "ERROR: unknown egress profile $(printf %q "$p") (names must match exactly). Available:" >&2`, which is `devcontainer-config/cc-isolated.sh:469`: `exactly). Available` is `)`, then `.`, then a space. The unmodified control printed `cc-isolated.sh rc=0 out=[]`. The same edit also refuses `cc-exit-scan.sh` and a renamed `cc-push.sh` on prose, so the doc's sentence is narrower than the effect, not wrong.

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:469`, `devcontainer-config/cc-verify.sh:56`, `R2/r2a.out`

---

## Claim 19: "The architecture review compared the two and rated the reuse better by a modest margin."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what that review says; the review itself is out of scope and was not checked.
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/architecture-review-2026-11-05-q089-source-guard.md:31`: "The new design is better, by a modest margin."

**Evidence:** `docs/reviews/architecture-review-2026-11-05-q089-source-guard.md:29-31`

---

## Claim 20: "The test adds a final newline to its copies: `source_lines_ok`'s read loop never sees an unterminated last line (security review F1). The shipped function has the same gap; fixing it is a host-tool change, left as a follow-up."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:62`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read loop, run directly, and the follow-up record; does not establish any exposure today, since all five `cc-*.sh` files end in a newline (E4).
**Legibility-target:** for-orchestrator-synthesis

The loop is `while IFS= read -r line; do` ... `done < "$f"` (`devcontainer-config/cc-verify.sh:54-62`). The extracted function run directly printed `no-newline rc=0 SOURCED=[]` and `newline rc=0 SOURCED=[h.sh]` (E1). The security review's heading is `#### 1. A plain `source` on a last line with no newline passes the guard unseen` (`docs/reviews/security-review-2026-11-05-q089-source-guard.md:32`), and the branch's rubric calls it `security-reviewer F1`. The deferral is the last row of `docs/reviews/override-log.md`.

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `devcontainer-config/cc-verify.sh:54-62`, `docs/reviews/security-review-2026-11-05-q089-source-guard.md:32`, `docs/reviews/override-log.md`, `R2/r2a.out`

---

## Claim 21: "the 3325-line `test/cc-isolated-functions.bats`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:63`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count at cb428e81; "no use for that file's setup" is rationale.
**Legibility-target:** for-orchestrator-synthesis

`wc -l` printed `3325 test/cc-isolated-functions.bats` (paraphrased — no quote available because the claim is a file's length).

**Evidence:** `test/cc-isolated-functions.bats:3325`

---

## Claim 22: "Full-line comments are dropped before reading the check list, so such a comment quoting a call cannot stand in for it. An end-of-line comment still can."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a comment placed above the real call with a wider list; string forms are Claim 37.
**Legibility-target:** for-orchestrator-synthesis

`args="$(grep -vE '^[[:space:]]*#' "$dir/$entry" \` (`T:44`; excerpt ends `:44`; the assignment continues to `:45` — read). E2: `st-full   rc=1 # cc-push.sh sources cc-exit-scan.sh unchecked` and `st-eol   rc=0`.

Command `bash R2/r2b.sh`, cwd worktree, exit 0, 03:40:24Z.

**Evidence:** `test/cc-host-tool-sources.bats:44-45`, `R2/r2b.out`

---

## Claim 23: "A permanent seeded-drift case per failure path of `check_entry` (H2) ... assertions that could not fail are a large family in `docs/failure-patterns.md` (17 `vacuous-assertion` entries)."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:65`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five `return 1` paths of `check_entry`, including the missing-file route through the second, and the entry count by `cause:` tag; does not establish that each path is seeded for both entry points (case 8's no-call seed is `cc-push.sh` only).
**Legibility-target:** for-orchestrator-synthesis

`rg -c 'cause:vacuous-assertion' docs/failure-patterns.md` printed `17`; a bare `vacuous-assertion` count gives 19, the other two being the taxonomy row (`:62`) and a prose line (`:106`). The paths are at `T:46, :51, :54, :57, :58`, and each has a case that asserts its message: `:127`, `:113`, `:132`, `:73`, `:104`.

Command `bash R2/r2d.sh`, cwd worktree, exit 0, 03:41:29Z.

**Evidence:** `test/cc-host-tool-sources.bats:46-58`, `docs/failure-patterns.md:62`, `docs/failure-patterns.md:106`, `R2/r2d.out`

---

## Claim 24: "`cc-verify.sh` is not walked: it has no `verify_host_tools` call and sources nothing. The `--list` argument lists (`cc-isolated.sh:527-528`) are separate copies and are not compared. The file header states both limits, and that it checks list membership, not whether the check runs before the `source`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:66`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the citation, both limits through the real case 1, and the header's text; does not establish what `--list` reports when those lists drift.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/cc-isolated.sh:527-528` are `lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true` and `perr="$(verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh)" || true`. E2: `verify   rc=0` (`cc-verify.sh` seeded to source a tool) and `list   rc=0` (both lists cut). `T:11-13`: "cc-verify.sh (no verify_host_tools call;\n# it sources nothing today), the lists `--list` passes, or whether the check comes\n# before the source or gates it."

Command `bash R2/r2b.sh`, cwd worktree, exit 0, 03:40:24Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:527-528`, `test/cc-host-tool-sources.bats:11-13`, `R2/r2b.out`

---

## Claim 25: "(the launch tests in `test/cc-isolated-functions.bats` cover that for the names in use)"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:66`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the check-before-source and gating order for both entry points against the filtered tests; the order of `cc-push.sh` is covered, but by another file, and no test pins order for a name not yet in use.
**Legibility-target:** for-author

True for the launcher, not for `cc-push`. Moving the launcher's `source` above the check, or out of the `if`, fails `test/cc-isolated-functions.bats:1158` (`o-launch-first`, `o-launch-ungated`). Moving `source "$CC_PUSH_DIR/cc-gitdir.sh"` above `cc-push.sh`'s check leaves all 11 filtered tests of that file green: E3 printed `[o-push-first] cif rc=0 ok=11 notok=0; push rc=1 ok=0 notok=1`, and the catch is `# (in test file test/cc-push.bats, line 808)`, `[ ! -e "$M/gitdir-ran" ]`. `test/cc-isolated-functions.bats` never runs `cc-push.sh`: its only hits are the byte-pin at `:1137` and a `cp` at `:1269` (grep, E4).

Precise version: "the launch tests in `test/cc-isolated-functions.bats` and the installed-copy test at `test/cc-push.bats:797` cover that for the names in use".

Command `bash R2/r2c.sh`, cwd worktree, exit 0, 03:40:31Z.

**Evidence:** `test/cc-isolated-functions.bats:1143-1158`, `test/cc-push.bats:797-808`, `R2/r2c.out`, `R2/r2d.out`

---

## Claim 26: "`cc-verify.sh`'s comment ("as row 71's Q-147") and row 71 ("because grep cannot cover every bash spelling") already claim no more than the test does, so neither changes. No guide names the guard."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:68`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both quotes and the absence from `guides/`; "claim no more" is read as neither text promising completeness.
**Legibility-target:** for-orchestrator-synthesis

Row 71: "a static test tying each entry point's `source` lines to its check list was split out as Q-147, because grep cannot cover every bash spelling." (`docs/decisions/log.md:94`). `git grep -l 'cc-host-tool-sources' cb428e81 -- . ':!docs/reviews'` printed only the research doc, so no guide names it (paraphrased — no quote available because the claim covers absence of matches).

**Evidence:** `devcontainer-config/cc-verify.sh:44-46`, `docs/decisions/log.md:94`, `R2/r2d.out`

---

## Claim 27a: "Against today's code, in the worktree: `bats test/cc-host-tool-sources.bats`, 7 ok."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:72`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at cb428e81; the result is still all green, only the number is old.
**Legibility-target:** for-author

The file has nine cases at cb428e81. E1 printed `[base] rc=0 ok=9 notok=0` and `1..9`. 7 was right at 8880c925 (`FC/wt-run.out`: `1..7`). cb428e81 added cases 3 and 4 without updating this line, which reads as a present-tense result. Precise version: "9 ok".

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `test/cc-host-tool-sources.bats:62-140`, `FC/wt-run.out`, `R2/r2a.out`

---

## Claim 27b: "The test as it stood at fa059477, appended to a scratch copy, also passes today's code."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stored run, valid here because `devcontainer-config` has no diff on the branch.
**Legibility-target:** for-orchestrator-synthesis

`FC/seed-runs.out` ends `ok 1 every file an entry point sources, directly or through what it sources, is in its verify_host_tools list`.

Reused command `bash FC/seed-runs.sh`, exit 0, 2026-11-06T03:06Z.

**Evidence:** `FC/seed-runs.out`

---

## Claim 28: The seeded-run block: "new: ok=5 not-ok=2", "not ok 4 a new helper in the check list but not in host_tool_files is named"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:78-81`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block's numbers against the file at cb428e81; its finding stands (D3 turns the guard red, and `existing: ok=260 not-ok=0` at `:77` is still right).
**Legibility-target:** for-author

The block is an accurate record of a seven-case file, with no marker that it is. With the cb428e81 file on seed D3, E1 printed `[d-s3] rc=1 ok=7 notok=2`, `not ok 1 plain source lines ...` and `not ok 6 a new helper in the check list but not in host_tool_files is named`. Precise version: either relabel the block as the 8880c925 run, or replace with `new: ok=7 not-ok=2` and `not ok 6`.

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `test/cc-host-tool-sources.bats:98-105`, `FC/seed-s3.out`, `R2/r2a.out`

---

## Claim 29: "(Case 4 fails there only because the seed has already made `cc-helper.sh` a host tool.)"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:84`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case number; the stated reason stays true of the case now numbered 6.
**Legibility-target:** for-author

Case 4 at cb428e81 is `a helper that names its directory CC_PUSH_DIR is read like cc-push.sh itself`, which passes on D3. The case the sentence means is number 6: `@test "a new helper in the check list but not in host_tool_files is named"` (`T:98`), and it fails there because `[[ "$output" == *"cc-helper.sh is not a host tool"* ]]` (`T:104`) cannot hold once the seed lists the helper in `host_tool_files`. E1 shows `not ok 6` and no `not ok 4` for `d-s3`. Precise version: "Case 6".

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `test/cc-host-tool-sources.bats:83-105`, `R2/r2a.out`

---

## Claim 30: "The seeds' sed edit of the hook's regex was imprecise and made `test/hooks/live-verify-gate.bats` case 26 fail: that case forces the regex, not the check list, so D3 still stands; with the regex edited exactly, that file passes 35 of 35."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two stored runs; the hook file has no diff on the branch.
**Legibility-target:** for-orchestrator-synthesis

`FC/seed-s3.out`: `not ok 26 the hook's host_tools regex names exactly host_tool_files, no more`. `FC/s3p.out`: `test/hooks/live-verify-gate.bats rc=0 ok=35 not-ok=0`.

Reused commands `bash FC/seed-s3.sh` and `bash FC/s3p.sh`, exit 0, 2026-11-06T03:07Z to 03:11Z.

**Evidence:** `FC/seed-s3.out`, `FC/s3p.out`

---

## Claim 31: "Files read": the rubric, `test/cc-isolated-functions.bats` "at fa059477 and at db31db8b", the five `devcontainer-config` files, and "`docs/decisions/log.md` row 71"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:90-93`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each listed path and revision resolves; does not establish that the author read them.
**Legibility-target:** for-orchestrator-synthesis

Each path was opened in this pass and both revisions resolve in the repo (paraphrased — no quote available because the claim is about path existence).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md`, `docs/decisions/log.md:94`, `FC/fa-cif.bats`

---

## Claim 32: "a new helper that an entry point plainly sources, directly or through a file it sources, must be in that entry point's verify_host_tools list, or it runs unchecked."

**Location:** `test/cc-host-tool-sources.bats:3-5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test enforcing this directly and transitively, and the runtime consequence on the D3 tree; does not establish it for spellings the header excludes.
**Legibility-target:** for-orchestrator-synthesis

Direct: case 2 passes. Transitive: seed D3, `# cc-isolated.sh sources cc-helper.sh unchecked` (E1). Runtime: `FC/s3-live.out`, `tampered helper RAN at source time`.

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `test/cc-host-tool-sources.bats:56-59`, `R2/r2a.out`, `FC/s3-live.out`

---

## Claim 33: "No other test ties the list to the `source` lines; the two names in use today are pinned one by one."

**Location:** `test/cc-host-tool-sources.bats:5-6`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `cc-exit-scan.sh` and `cc-gitdir.sh` in the launcher's call and `cc-gitdir.sh` in `cc-push.sh`'s, each dropped at cb428e81, and D3's green run for the "no other test" half; the D3 run was the two launcher suites plus the two fixture-adjusted files, not the whole repo suite.
**Legibility-target:** for-orchestrator-synthesis

`rg -l verify_host_tools test` prints only `test/cc-isolated-functions.bats` and `test/cc-host-tool-sources.bats` (E4), and D3 leaves the former green (`existing: ok=260 not-ok=0`, `FC/seed-s3.out`). All three drops fail by name, each in its own file (E3): `[p-launch-scan] ... notok=2` at `:1153` and `:1180`, `[p-launch-gitdir] ... notok=1` at `:1193`, `[p-push-gitdir] ... push rc=1` at `test/cc-push.bats:806`. The `cc-push.sh` self-entry in its own list is not a sourced name, so the "two names" count is right.

Command `bash R2/r2c.sh`, cwd worktree, exit 0, 03:40:31Z.

**Evidence:** `test/cc-isolated-functions.bats:1153`, `test/cc-isolated-functions.bats:1180`, `test/cc-isolated-functions.bats:1193`, `test/cc-push.bats:806`, `R2/r2c.out`, `R2/r2d.out`

---

## Claim 34: "A grep guards plain spellings only, and it cannot be complete for bash: Q-089's fourth review pass showed that."

**Location:** `test/cc-host-tool-sources.bats:8-9`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation; "cannot be complete" is the rubric's finding and was not proved here beyond the examples in Claim 35.
**Legibility-target:** for-orchestrator-synthesis

Rubric `:94`: "Pass 4's fact-check (fa059477) found 3 Incorrect. Two concern the static source-set test's reach".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:92-97`

---

## Claim 35: "Forms this one misses include `FOO=1 . f`, `FOO=1 source f`, one-line case arms, a quoted or obfuscated `source`, and `$c f`."

**Location:** `test/cc-host-tool-sources.bats:9-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each form appended to `cc-push.sh` through the real case 1 at cb428e81; "include" makes no claim the list is exhaustive, and it is not (`coproc source`, for one, passes, `FC/../sec/probe.out`).
**Legibility-target:** for-orchestrator-synthesis

E2, each with an unlisted `cc-exit-scan.sh`: `foo-dot rc=0`, `foo-src rc=0`, `case rc=0`, `quoted rc=0`, `obf rc=0`, `var rc=0`, against a positive control `st-none rc=1 # cc-push.sh sources cc-exit-scan.sh unchecked`.

Command `bash R2/r2b.sh`, cwd worktree, exit 0, 03:40:24Z.

**Evidence:** `R2/r2b.out`

---

## Claim 36: "It also does not see a tool run by name, cc-verify.sh (no verify_host_tools call; it sources nothing today), the lists `--list` passes, or whether the check comes before the source or gates it."

**Location:** `test/cc-host-tool-sources.bats:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all five limits through the real case 1 at cb428e81, including both ordering forms; the mutations ran on `cc-push.sh` for order and on the launcher for gating.
**Legibility-target:** for-orchestrator-synthesis

E2: `byname rc=0` (`bash "$CC_PUSH_DIR/cc-exit-scan.sh"`), `verify rc=0`, `list rc=0`, `o-after rc=0` (the `source` above the check), `o-ungated rc=0` (the `source` after the `fi`, reached when the check fails). `devcontainer-config/cc-verify.sh` has no `verify_host_tools` text and no load line (paraphrased — no quote available because the claim covers absence of matches; the load-spelling grep in E5 prints nothing).

Command `bash R2/r2b.sh`, cwd worktree, exit 0, 03:40:24Z.

**Evidence:** `test/cc-host-tool-sources.bats:11-13`, `R2/r2b.out`, `R2/r2e.out`

---

## Claim 37: "An end-of-line comment or string quoting a check call above the real one is read as the list."

**Location:** `test/cc-host-tool-sources.bats:13-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an end-of-line comment and a single-quoted string above the real call, with the real call kept; does not extend to a double-quoted string with escaped inner quotes, which the regex does not match, nor to text below the real call, which `head -1` drops.
**Legibility-target:** for-orchestrator-synthesis

The regex wants the literal `verify_host_tools "\$CC_(ISOLATED|PUSH)_DIR"` (`T:45`). E2: `st-eol rc=0` and `st-single rc=0`, while `st-dq-esc rc=1`, `st-full rc=1` and `st-below rc=1`, each `# cc-push.sh sources cc-exit-scan.sh unchecked`.

Command `bash R2/r2b.sh`, cwd worktree, exit 0, 03:40:24Z.

**Evidence:** `test/cc-host-tool-sources.bats:44-45`, `R2/r2b.out`

---

## Claim 38: "It is hardening against a refactor, and the runtime checks do not depend on it."

**Location:** `test/cc-host-tool-sources.bats:14-15`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the dependency direction; "hardening against a refactor" is intent and is not checked.
**Legibility-target:** for-orchestrator-synthesis

No file under `devcontainer-config` changes on the branch (E6 prints `0`), and `git grep` finds the file's name only in the research doc outside `docs/reviews` (paraphrased — no quote available because the claim covers absence of a dependency).

**Evidence:** `R2/r2f.out`, `R2/r2d.out`

---

## Claim 39: "The spelling rule is cc-verify.sh's own source_lines_ok, read from that file rather than restated here, so there is one grammar to keep."

**Location:** `test/cc-host-tool-sources.bats:17-18`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `source`/`.` grammar; does not cover the separate regex at `T:45`, which reads the check list and is not part of that grammar.
**Legibility-target:** for-orchestrator-synthesis

`sed -n '/^source_lines_ok() {/,/^}/p' "$SRC/cc-verify.sh" > "$T/source-lines-ok.sh"` (`T:24`) and `source "$T/source-lines-ok.sh"` (`T:27`). `FC/mut2.out` shows the file failing in `setup` when the function is renamed: `# no source_lines_ok in cc-verify.sh`.

Reused command `bash FC/mut2.sh`, exit 0, 2026-11-06T03:22Z.

**Evidence:** `test/cc-host-tool-sources.bats:24-27`, `FC/mut2.out`

---

## Claim 40: "what ENTRY plainly sources, directly or through what those files source, is in its first verify_host_tools call and in host_tool_files. Prints the first problem."

**Location:** `test/cc-host-tool-sources.bats:36-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "first" in run order, and as the first call spelled with `$CC_ISOLATED_DIR` or `$CC_PUSH_DIR`; does not mean the first call in the file, because the launcher's first textual calls (`:527-528`, `$cfg_real`) are skipped by the regex, and if `:748` went, `:843` (`cc-push.sh` alone) would be read in its place.
**Legibility-target:** for-orchestrator-synthesis

E1 printed `cc-isolated.sh: cc-exit-scan.sh cc-gitdir.sh` and `cc-push.sh: cc-push.sh cc-gitdir.sh`, with the call list `527`, `528`, `748`, `843`, `856` under it. `:527-528` sit inside `list_projects() {` (`devcontainer-config/cc-isolated.sh:506`, E7), reached through `--list)       action="list"; shift ;;` (`:796`); `:748` is at top level, so it runs first. `FC/mut2.out` shows the `:843` fallback: with `:748` renamed, the launcher fails `# cc-isolated.sh sources cc-exit-scan.sh unchecked`, not the no-call message. Each failure branch does `return 1` straight after its one `echo` (`T:46-58`).

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `test/cc-host-tool-sources.bats:44-59`, `devcontainer-config/cc-isolated.sh:527-528`, `devcontainer-config/cc-isolated.sh:748`, `devcontainer-config/cc-isolated.sh:843`, `R2/r2a.out`, `FC/mut2.out`

---

## Claim 41: "It works on copies, which it adjusts for the shared grammar: CC_PUSH_DIR, which the grammar does not know, becomes the launcher's variable (so a refused line shows that name), and each copy gets a final newline, because the grammar's read loop never sees an unterminated last line."

**Location:** `test/cc-host-tool-sources.bats:38-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the copies, the rename in every copy, the newline in every copy and both reasons; the adjustments persist between the two `check_entry` calls of case 1, which is harmless (the regex accepts either name, and a repeat newline is a blank line).
**Legibility-target:** for-orchestrator-synthesis

`cp "$SRC"/cc-*.sh "$T/cfg/"` (`T:29`), and every case passes `"$T/cfg"`. The grammar's `src` regex names only `\$CC_ISOLATED_DIR` and the `dirname` form (`devcontainer-config/cc-verify.sh:49`); removing the rename fails 7 of 9 cases (E1, `[m-norn] rc=1 ok=2 notok=7`). A refused line shows the new name: `source "$CC_ISOLATED_DIR/sub/cc-gitdir.sh"` for a seeded `$CC_PUSH_DIR` line (E1). Newline: E1's direct run, as in Claim 20. In a non-entry copy the behaviour holds too: `printf` of an unterminated source onto `cc-gitdir.sh` gave `rc=1`, `# cc-isolated.sh sources cc-helper.sh unchecked` (E4), the shape of the security review's P1.

Commands `bash R2/r2a.sh` and `bash R2/r2d.sh`, cwd worktree, exit 0, 03:40:11Z and 03:41:29Z.

**Evidence:** `test/cc-host-tool-sources.bats:29`, `test/cc-host-tool-sources.bats:47-50`, `devcontainer-config/cc-verify.sh:49`, `R2/r2a.out`, `R2/r2d.out`

---

## Claim 42: "Positive control: both entry points reach cc-gitdir.sh (the launcher through the scan)."

**Location:** `test/cc-host-tool-sources.bats:53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers today's source lines; does not establish the control's sensitivity on the launcher side, whose seed is `cc-push.sh` only.
**Legibility-target:** for-orchestrator-synthesis

`source "$CC_PUSH_DIR/cc-gitdir.sh"` (`devcontainer-config/cc-push.sh:214`), `source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` (`devcontainer-config/cc-isolated.sh:750`), and `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"` (`devcontainer-config/cc-exit-scan.sh:12`).

**Evidence:** `devcontainer-config/cc-push.sh:214`, `devcontainer-config/cc-isolated.sh:750`, `devcontainer-config/cc-exit-scan.sh:12`

---

## Claim 43: Test name: "a plain source on a last line with no newline is still read"

**Location:** `test/cc-host-tool-sources.bats:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an unterminated last line of the entry copy, and the case's power to fail; does not cover a non-entry copy, which no case seeds (Claim 47).
**Legibility-target:** for-orchestrator-synthesis

The case does `printf 'source "$CC_PUSH_DIR/cc-exit-scan.sh"' >> "$T/cfg/cc-push.sh"` (`T:77`) and asserts `"cc-push.sh sources cc-exit-scan.sh unchecked"` (`T:80`). The real `cc-push.sh` ends in a newline (E4), so the seed is the file's last line. Deleting `echo >> "$f"` fails this case and only this case: `[m-nonl] rc=1 ok=8 notok=1`, `not ok 3 a plain source on a last line with no newline is still read`.

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `test/cc-host-tool-sources.bats:76-81`, `R2/r2a.out`

---

## Claim 44: Test name: "a helper that names its directory CC_PUSH_DIR is read like cc-push.sh itself"

**Location:** `test/cc-host-tool-sources.bats:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a non-entry copy's `$CC_PUSH_DIR` line being accepted, and the case's power to fail; the assertion shows the helper's line was not refused, not what the helper's own sources were, since `cc-gitdir.sh` is already in the set.
**Legibility-target:** for-orchestrator-synthesis

The helper is `source "$CC_PUSH_DIR/cc-gitdir.sh"` (`T:84`); the case expects `"cc-push.sh sources cc-helper.sh unchecked"` (`T:88`), reached only if the walk gets past the helper's line. Restricting the rename to `cc-push.sh` (8880c925's behaviour) fails this case and only this case: `[m-rn-push] rc=1 ok=8 notok=1`, `not ok 4 a helper that names its directory CC_PUSH_DIR is read like cc-push.sh itself`.

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `test/cc-host-tool-sources.bats:83-89`, `R2/r2a.out`

---

## Claim 45: The other seven test names (`:62`, `:69`, `:91`, `:98`, `:107`, `:121`, `:135`) against their assertions

**Location:** `test/cc-host-tool-sources.bats:62-140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its assertions at cb428e81, all passing; case 8's no-call seed is `cc-push.sh` only (on the launcher, `:843` stands in and the failure carries another message, still a failure), and case 7's "any other directory" is two seeds in the file plus four probes here.
**Legibility-target:** for-orchestrator-synthesis

E1 printed `ok` for all nine. Case 7's name was also probed: `source "/etc/x.sh"`, `source "$CC_PUSH_DIR/sub/cc-gitdir.sh"`, `source cc-gitdir.sh` and `source "$OTHER/cc-gitdir.sh"` each gave `rc=1` with `# not a plain source line: ...` (E1). Case 9's message is `cc-gitdir.sh is missing` from `[ -f "$f" ] || { echo "$f is missing"; return 1; }` (`devcontainer-config/cc-verify.sh:53`), printed through the `not a plain source line:` wrapper (`T:51`; `FC/../sec/probe.out`'s P6 shows the shape), so the name holds and the message arrives with that prefix.

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `test/cc-host-tool-sources.bats:62-74`, `test/cc-host-tool-sources.bats:91-140`, `devcontainer-config/cc-verify.sh:53`, `R2/r2a.out`

---

## Claim 46: cb428e81: "Review pass 1: the grammar's read loop misses an unterminated last line, and the rename covered only cc-push.sh." and "Header and research doc state the remaining limits."

**Location:** commit cb428e81 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two defects as of 8880c925 and that limits are stated in `T:8-15` and `R:58-66`; does not establish that those documents state every limit.
**Legibility-target:** for-orchestrator-synthesis

8880c925's `check_entry` had `sed -i 's/CC_PUSH_DIR/CC_ISOLATED_DIR/g' "$dir/cc-push.sh"` and no newline step (`R2/r2e.out`). The read loop is at `devcontainer-config/cc-verify.sh:54-62`.

**Evidence:** `R2/r2e.out`, `devcontainer-config/cc-verify.sh:54-62`, `test/cc-host-tool-sources.bats:8-15`

---

## Claim 47: cb428e81: "check_entry now adjusts every copy, with a seeded case for each."

**Location:** commit cb428e81 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each adjustment's seeded case and each's reach across copies; the behaviour is right in every copy (Claim 41), so this concerns what the cases pin, not what the code does.
**Legibility-target:** for-author

Both adjustments do apply to every copy, and each has a seeded case. But the newline's case seeds only the entry copy. A mutant that appends the newline to the entry alone, `[ "$f" = "$dir/$entry" ] && echo >> "$f"`, leaves the file green: `[m-nl-entry] rc=0 ok=9 notok=0`. So "every copy" is pinned for the rename (case 4 fails under `m-rn-push`) and not for the newline, though the security review's first probe (P1) was in `cc-gitdir.sh`, a non-entry copy. Precise version: "with a seeded case for each adjustment; the newline's seed is in the entry point".

Command `bash R2/r2a.sh`, cwd worktree, exit 0, 03:40:11Z.

**Evidence:** `test/cc-host-tool-sources.bats:47-50`, `test/cc-host-tool-sources.bats:76-81`, `R2/r2a.out`, `FC/../sec/probe.sh`

---

## Claim 48: cb428e81: "Three findings declined or deferred, rows in the override log. The shipped source_lines_ok gap is a host-tool follow-up."

**Location:** commit cb428e81 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three `test/q089-source-guard-narrow` rows; whether each decision is sound is not checked.
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/override-log.md` gains three rows for the branch: performance-reviewer F1 `Won't-Fix`, architecture-review F3 `Defer`, and security-reviewer escalation `Defer`, the last with "Revisit trigger: the next change to cc-verify.sh; raised in the ready marker."

**Evidence:** `docs/reviews/override-log.md`

---

## Claim 49: cb428e81: "Size: about 130 code lines against main."

**Location:** commit cb428e81 message
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pr-prep step 1a's count at cb428e81; the unit is far under both caps either way, so no gate depends on the difference.
**Legibility-target:** for-author

Step 1a's command, `git diff --numstat "$BASE"...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` (`workflows/pr-prep.md:91`), prints `140` for db31db8b...cb428e81 (E6; `117` at 8880c925, `119` at cb59c2bb). The file has 128 non-blank lines, which may be the source of "about 130", but the step's count includes blanks and comments. Precise version: "Size: 140 code lines against main."

Command `bash R2/r2f.sh`, cwd worktree, exit 0, 03:43:13Z.

**Evidence:** `workflows/pr-prep.md:91`, `workflows/review-fix-loop.md:57`, `R2/r2f.out`

---

## Claim 50: cb59c2bb: "Pass 1 fact-check: 2 Incorrect and 8 Mostly accurate, all prose. The motive text names which drift is caught and how, the header says unchecked and adds the ordering limit, and the seeds are D1 to D3, apart from constraint S3. The commit message of 8880c925 says "today's suite"; that run was the two launcher suites, and the research doc now says so."

**Location:** commit cb59c2bb message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each statement against the diff and the prior report's summary, including that every seed in `R` is D1 to D3 and the remaining `S3`s are the constraint; "iteration 1 of 3" is process state, read from the branch rubric.
**Legibility-target:** for-orchestrator-synthesis

Prior report header: `**Summary:** 25 verified, 8 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable`. The commit's diff to `T` adds "must be in\n# that entry point's verify_host_tools list, or it runs unchecked" and "or whether the check comes\n# before the source". `R:21`: "(D1 to D3, so as not to read as constraints)". `R:29`: "D3 ran the two suites above".

**Evidence:** `docs/reviews/code-fact-check-report-q089-source-guard.md:10`, `test/cc-host-tool-sources.bats:3-13`, `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`

---

## Claim 51a: 8880c925: "Land Q-089 finding A6's static guard, claiming only plain spellings and accidental drift. The spelling rule is read from cc-verify.sh's source_lines_ok, not restated." and "reuses source_lines_ok instead of fa059477's regexes (S3); reach difference recorded in the research doc."

**Location:** commit 8880c925 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against the commit's content; history, not editable.
**Legibility-target:** for-orchestrator-synthesis

The extraction is at `T:24` and the reach lists at `R:51-56`, with the same extraction in 8880c925 (paraphrased — no quote available because the claim restates Claims 16 and 39, whose quotes apply).

**Evidence:** `test/cc-host-tool-sources.bats:24`, `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51-56`

---

## Claim 51b: 8880c925: "A seeded new helper left today's suite green."

**Location:** commit 8880c925 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the D3 run; history, not editable, and already qualified by `R:29` and cb59c2bb's message.
**Legibility-target:** for-orchestrator-synthesis

The run was `bats test/cc-isolated-functions.bats test/cc-push.bats` (`FC/seed-s3.sh`), `existing: ok=260 not-ok=0`, not the whole suite; `R:29` says "The full suite was not run on the seed." No action is possible or needed.

**Evidence:** `FC/seed-s3.sh`, `FC/seed-s3.out`, `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 15** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`): says the test renames in "its copy of `cc-push.sh`" and that the cost is "one rename"; since cb428e81 it renames in every copy and also appends a newline.
- **Claim 27a** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:72`): "7 ok" under "today's code"; the file has nine cases and prints `ok=9`.
- **Claim 28** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:78-81`): the D3 block shows a seven-case file (`ok=5 not-ok=2`, `not ok 4`) without saying so; at cb428e81 it is `ok=7 not-ok=2`, `not ok 6`.
- **Claim 29** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:84`): "Case 4" is now case 6; case 4 is the rename case and passes on D3.

### Mostly Accurate
- **Claim 7** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`): `cc-push.bats:807` should be `:806-807`, since the drop fails at `:806`; the `cc-exit-scan.sh` drop's lines (`:1153`, `:1180`) are not cited.
- **Claim 25** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:66`): the launch tests cover order for the launcher only; `cc-push`'s order is covered by `test/cc-push.bats:797-808`.
- **Claim 47** (commit cb428e81): the newline's seeded case is on the entry copy only; an entry-only mutant stays 9 of 9. Behaviour in other copies is right, by probe. Tighten the message, or seed a non-entry copy.
- **Claim 49** (commit cb428e81): step 1a's count is 140, not "about 130".
- **Claim 51b** (commit 8880c925): "today's suite" was two suites. History, already qualified in the doc; nothing to do.

### Unverifiable
None.

## Goal-Alignment Note

- Success criterion (restated verbatim): a report at docs/reviews/code-fact-check-report-q089-source-guard-r2.md with `Commit: cb428e81`, each claim tagged with Legibility-target, ending in a Goal-Alignment Note. Commit nothing, edit nothing else.
- Answered: yes. Every claim family in the dispatch was checked, with the header limits, both new cases, the `)` sentence, the name pins and the order coverage run at cb428e81 in scratch copies. Both prior fixes hold as behaviour.
- Out of scope: review reports in `docs/reviews` (read only where `R` cites them); whole-suite reruns (E3 used 11 filtered tests plus one, and stored runs were reused where the input has no diff on the branch); option-table rationale; whether to land.
- Escalate: no Incorrect, so nothing here blocks on behaviour. Four Stale claims are all leftovers in `R` from cb428e81 adding two cases and widening the rename: `R:51`, `R:72`, `R:78-81`, `R:84`. They are text-only fixes. Claim 47's surviving mutant is the one point about what the tests pin rather than what prose says: the orchestrator decides whether to seed a non-entry copy or just tighten the wording, and cb428e81's message can only change if the branch's history is rewritten, so a one-line note in `R` may be the cheaper fix for Claims 47 and 49.
- Decisions I made: execution logs stay in `R2`, not `docs/reviews/execution-logs/`, because the dispatch limited this pass to one file. Claim 7 is Mostly accurate rather than Verified because line citations were an explicit ask, though `:807` is the adjacent assertion. Claim 3 stays Verified on the mechanism, with FP-175's different date and pipe in the Scope field. Claim 47 reads "for each" as each adjustment, and is Mostly accurate because the sentence's "every copy" is not pinned for the newline. No entry was added to `docs/reviews/hallucination-patterns.md`: none qualifies, and the dispatch said to edit nothing else.
