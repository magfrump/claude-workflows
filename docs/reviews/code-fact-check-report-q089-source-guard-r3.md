Commit: cb428e81

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `wt-2026-11-05-q089-source-guard-narrow`, branch `test/q089-source-guard-narrow`)
**Scope:** `git diff db31db8b..cb428e81 -- test/cc-host-tool-sources.bats docs/working/research-2026-11-05-q089-source-guard-narrow.md`, plus the commit messages of `git log db31db8b..cb428e81`
**Checked:** 2026-11-05
**Replication:** final pass, replicate k=3
**Total claims checked:** 51
**Summary:** 40 verified, 7 mostly accurate, 4 stale, 0 incorrect, 0 unverifiable

The pattern log (`docs/reviews/hallucination-patterns.md`) was read. No claim here is a fabrication. The four Stale claims are measured or descriptive text that cb428e81 overtook, which is not the log's class, so nothing qualifies for it.

Shorthand: `R` is `docs/working/research-2026-11-05-q089-source-guard-narrow.md`, `T` is `test/cc-host-tool-sources.bats`, `FC` is `/tmp/claude-1000/-workspace/47403b7b-5fcb-4e13-8807-c539081df064/scratchpad/2026-11-05-q089-source-guard-narrow/fc`, and `X` is the same path ending in `fc-r3`.

No file under `devcontainer-config/` changed in `db31db8b..cb428e81`, so runs on the earlier trees still describe today's config.

## Execution log

All X runs are in scratch copies built with `git archive cb428e81`, cwd `X`, times UTC 2026-11-06. No worktree file was touched. Output stays in `X` because the dispatch allowed this one file only. Per-seed exit codes are in each output file.

| Id | Command | Exit | Time | Output |
|---|---|---|---|---|
| X1 | `LC_ALL=C timeout 280 bash exp1.sh` (quoted calls above the real one, gating, a case arm in cc-push's own argument case, three mutations of the test, the argument lists read, `)` added to the detector) | 0 | 03:39:12 | `X/exp1.out`, `X/exp1/*/out.txt` |
| X2 | `LC_ALL=C timeout 560 bash exp2.sh` (each name dropped from a list, each source moved above its check, D1 with and without the fixture fix, D1 to D3 against T as it stands; filtered `bats -f` runs only) | 0 | 03:41:00 | `X/exp2.out`, `X/exp2/*/out*.txt` |
| X3 | `LC_ALL=C timeout 120 bash mut.sh` (`FC/mut.sh` rerun against T at cb428e81) | 0 | 03:41:05 | `X/mut.out` |
| X4 | `LC_ALL=C timeout 60 bash s3-live.sh` (`FC/s3-live.sh` rerun) | 0 | 03:41:05 | `X/s3-live.out` |
| X5 | `LC_ALL=C timeout 40 bash exp3.sh` (D1's failure text, in the installed-copy fixture's shape) | 0 | 03:42:51 | `X/exp3.out` |

Reused from the prior pass, not rerun, as the dispatch directed (ids from `docs/reviews/code-fact-check-report-q089-source-guard.md`): E1 `FC/seed-runs.out`, E2 `FC/seed-s3.out`, E3 `FC/forms.out`, E4 `FC/forms2.out`, E6 `FC/pf.out`, E8 `FC/s1fix.out`, E10 `FC/s3p.out`, E11 `FC/base-cc-verify.out` and `FC/base-install-host.out`, E12 `FC/s3p2-cc-verify.out`, E13 `FC/s3p3-install-host.out`, E14 `FC/mut2.out`. I read each output and did not rely on the prior report's verdicts.

No whole suite was rerun. No process from these runs was left running (`ps` filter on `fc-r3` printed nothing).

---

## Claim 1: "The test keeps fa059477's positive control (both entry points must reach `cc-gitdir.sh`), and a missing check call fails, so neither case passes empty."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both failure paths as T seeds them on `cc-push.sh`; does not establish that a renamed launcher call prints the "no verify_host_tools call" message, because the launcher then falls through to its later call at `:843` and fails with a different message.
**Legibility-target:** for-orchestrator-synthesis

The control is at `test/cc-host-tool-sources.bats:54`: `[[ " ${SOURCED[*]} " == *" cc-gitdir.sh "* ]] || { echo "parse missed cc-gitdir.sh for $entry: ${SOURCED[*]}"; return 1; }`. The same line is in fa059477's test, with `$closure` for `SOURCED`. The missing-call path is `:46`: `[ -n "$args" ] || { echo "no verify_host_tools call in $entry"; return 1; }`. Case 8 passes in X1's `base` run (ok=9). For the launcher, E14's output reads `cc-isolated.sh sources cc-exit-scan.sh unchecked`: it still fails, under a different message.

**Evidence:** `test/cc-host-tool-sources.bats:46`, `test/cc-host-tool-sources.bats:54`, `test/cc-host-tool-sources.bats:121-133`, `X/exp1/base/out.txt`, `FC/mut2.out`

---

## Claim 2: "FP-175 (`echo | grep -q` SIGPIPE under pipefail): the source of R2's 1-in-25 flake. The new file does not source the launcher into the test shell, so it has no pipefail, and it still uses a here-string."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:13`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test shell's option state and the one membership grep; does not establish anything about the separate `bash -c` that sources the launcher, which does have pipefail on but only prints `host_tool_files`.
**Legibility-target:** for-orchestrator-synthesis

`test/cc-host-tool-sources.bats:55` sources the launcher in a child: `hosts="$(bash -c 'source "$1"; host_tool_files' _ "$dir/cc-isolated.sh")"`. Line `:58` uses the here-string: `grep -qx -- "$f" <<< "$hosts"`. E6's output shows `pipefail off` in a bats test and `on` in the child. The rubric's row R2 reads "`host_tool_files \| grep -q` SIGPIPE, 1/25 runs" (`docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:20`).

**Evidence:** `test/cc-host-tool-sources.bats:55`, `test/cc-host-tool-sources.bats:58`, `docs/failure-patterns.md:317`, `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:20`, `FC/pf.out`

---

## Claim 3: "scope the claim honestly: it guards plain spellings against accidental drift and is not complete for bash." and A6's "would be forced into `host_tool_files` by tests, but the launcher would still source it unchecked."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:17`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both quotations and the listed spellings against the rubric text; does not establish that "every pass converged on the runtime code", which is the rubric's own judgement.
**Legibility-target:** for-orchestrator-synthesis

Both quotes match the rubric word for word: `:97` has "scope the claim honestly: it guards plain spellings against accidental drift and is not complete for bash", and `:35` has "would be forced into `host_tool_files` by tests, but the launcher would still source it unchecked". The spelling list matches `:94`: "`FOO=1 . f`, case arms, `\. f`, quoted or obfuscated `source`, `$c f`".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:35`, `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:94`, `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:97`

---

## Claim 4: "baseline: 260 ok, 0 failed, `LC_ALL=C`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:21`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named files on today's config; does not establish the full suite, which was not run.
**Legibility-target:** for-orchestrator-synthesis

`bats --count` gives 212 and 48, which sum to 260. E1's output reads `--- base existing: ok=260 not-ok=0`.

**Evidence:** `test/cc-isolated-functions.bats:1`, `test/cc-push.bats:1`, `FC/seed-runs.out`

---

## Claim 5: D1 row: "1 fails, `test/cc-push.bats:803`, only because that fixture lacks the file: the failure does not mention the list" / "fails: `cc-push.sh sources cc-exit-scan.sh unchecked`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failing line, its cause and T's message on the seed; does not establish D1 under any suite other than the two named.
**Legibility-target:** for-orchestrator-synthesis

X2's `d1` stops at `test/cc-push.bats, line 803`, which is `[ "$status" -eq 0 ]` after `run bash "$d/cc-push.sh" --help`. X5's text is `./cc-push.sh: line 215: D/cc-exit-scan.sh: No such file or directory`, with no mention of the list. With the file in the fixture, X2's `d1f` passes. `g-s1` prints `# cc-push.sh sources cc-exit-scan.sh unchecked`.

**Evidence:** `test/cc-push.bats:797-803`, `X/exp2.out`, `X/exp3.out`, `FC/seed-runs.out`

---

## Claim 6: D2 row: "1 fails: `test/cc-isolated-functions.bats:1193` asserts that the refusal names that tool" / "fails: `cc-isolated.sh sources cc-gitdir.sh unchecked`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `cc-gitdir.sh` dropped from the launcher's call; does not cover the other two list entries, which Claim 8 takes.
**Legibility-target:** for-orchestrator-synthesis

X2's `p-iso-git` stops at `test/cc-isolated-functions.bats, line 1193`, which is `[[ "$output" == *"cc-exit-scan.sh changed"*"cc-gitdir.sh changed"* ]]`. E1 shows one failure across the two files. `g-s2` prints `# cc-isolated.sh sources cc-gitdir.sh unchecked`.

**Evidence:** `test/cc-isolated-functions.bats:1193`, `X/exp2.out`, `FC/seed-runs.out`

---

## Claim 7: D3 row: "**260 ok, 0 failed**" / "fails: `cc-isolated.sh sources cc-helper.sh unchecked`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row's two cells for the two named files; does not establish the rest of the suite, which line `:29` itself discloses.
**Legibility-target:** for-orchestrator-synthesis

E2 reads `existing: ok=260 not-ok=0`. `seed-s3.sh` touches each thing the row lists (`host_tool_files`, PAYLOAD, the hook regex, fixtures, pinned lists) and does not touch the check list. X2's `g-s3` prints `# cc-isolated.sh sources cc-helper.sh unchecked` from T at cb428e81.

**Evidence:** `FC/seed-s3.out`, `X/exp2.out`

---

## Claim 8: "Dropping a name in use today is caught, directly (`cc-isolated-functions.bats:1193`, `cc-push.bats:807`)"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three (entry point, sourced name) pairs; does not establish anything about the `--list` copies, which nothing here pins.
**Legibility-target:** for-author

The conclusion holds for every pair, but one citation is a line short of what fires. With `cc-gitdir.sh` dropped from `cc-push.sh`, X2's `p-push-git` stops at `test/cc-push.bats, line 806`, which is `[ "$status" -eq 1 ]`, so `:807` never runs. The launcher pair for `cc-exit-scan.sh`, which the sentence does not cite, fails at `test/cc-isolated-functions.bats:1153` and `:1180`. `:1193` is right for `cc-gitdir.sh` (Claim 6). The precise text is `cc-push.bats:806`.

**Evidence:** `test/cc-push.bats:805-807`, `test/cc-isolated-functions.bats:1153`, `test/cc-isolated-functions.bats:1180`, `X/exp2.out`

---

## Claim 9: "D1's catch is a fixture accident, and with the fixture copying the file `test/cc-push.bats` passes 48 of 48 with the seed in."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-push.bats with that one fixture changed; does not establish the other test files on the same seed.
**Legibility-target:** for-orchestrator-synthesis

E8's output has 48 `ok` lines and ends `ok 48 installed copy: cc-push checks itself and cc-gitdir.sh before sourcing, and refuses on a change (row 71)`. X2 repeated the one affected case on a fresh tree (`d1f`, `rc=0 ok=1 notok=0`).

**Evidence:** `FC/s1fix.out`, `X/exp2.out`

---

## Claim 10: "`test/cc-verify.bats` and `test/install-host.bats` also need `cc-helper.sh` in a fixture, and with that they match the baseline. The full suite was not run on the seed."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two files' per-case results compared with the base tree; does not make the baseline green, since `install-host.bats` has one baseline failure (T9).
**Legibility-target:** for-orchestrator-synthesis

Before the fixture edit E10 has `test/cc-verify.bats rc=1 ok=11 not-ok=1` and `test/install-host.bats rc=124 ok=4 not-ok=32`. After it, E12 has 12 ok and 0 not ok, equal to E11's base, and `diff` of the `ok`/`not ok` lines of E11 and E13 for `install-host.bats` is empty. The one shared failure is `not ok 9 T9 installed hooks still find lib/ and ../scripts (log-usage smoke test)`.

**Evidence:** `FC/s3p.out`, `FC/s3p2-cc-verify.out`, `FC/s3p3-install-host.out`, `FC/base-cc-verify.out`, `FC/base-install-host.out`

---

## Claim 11: "A live probe from the fact-check confirmed the result: a tampered helper ran with `HOST_TOOLS_ERR` empty, while the `cc-gitdir.sh` control was refused."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sourcing the seeded launcher against a hashed manifest; does not establish a full launch, since the probe stops at the source step.
**Legibility-target:** for-orchestrator-synthesis

X4 reproduced it: `HOST_TOOLS_ERR=[]`, `tampered helper RAN at source time`, then `HOST_TOOLS_ERR=[S/fc-r3/s3-live/cfg/cc-gitdir.sh changed since the last bless]` and `control: tampered gitdir refused, did not run`.

**Evidence:** `X/s3-live.out`, `FC/s3-live.sh`

---

## Claim 12: "That breaks row 71's stated rule ("Each entry point checks the host tools it executes before sourcing them")"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quotation; does not judge whether "in the quiet way H2 rules out" is the best reading of H2, which is rationale.
**Legibility-target:** for-orchestrator-synthesis

The quotation is word for word in `docs/decisions/log.md:94`: "Each entry point checks the host tools it executes before sourcing them (`verify_host_tools`, one copy in `cc-isolated.sh` and `cc-push.sh`, pinned byte for byte by a test)".

**Evidence:** `docs/decisions/log.md:94`, `docs/constraints.md:6`

---

## Claim 13: "The sourced set has not changed since Q-089, and `cc-verify.sh` joined the host tools without sourcing anything. The runtime checks do not depend on the test, and row 71 places this under non-targeted tampering, as defence in depth."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:31`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers git history of the source and check lines and row 71's wording; does not weigh "rare", which is a judgement.
**Legibility-target:** for-orchestrator-synthesis

Paraphrased — no quote available because the first part is an absence in history: `git log -G` on those lines ends at afe1ae59 (2026-10-14), and `echo "cc-verify.sh"` entered `host_tool_files` in d5fa26c1 (2026-10-20). `rg source devcontainer-config/cc-verify.sh` finds only the function, its comment and its two calls. Row 71 reads "Those are row 45's existing threat model: non-targeted host tampering, defence in de[pth]" (`docs/decisions/log.md:94`).

**Evidence:** `devcontainer-config/cc-verify.sh:41-65`, `devcontainer-config/cc-verify.sh:203-204`, `docs/decisions/log.md:94`

---

## Claim 14: "leaves A6 open for about 100 lines of test saved"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:41`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file's size at cb428e81; does not bear on the option's ranking, which a 40-line change does not alter.
**Legibility-target:** for-author

T is 140 lines, and pr-prep's count gives 140 (`140	0	test/cc-host-tool-sources.bats`). "About 100" fits only the 102 lines left after dropping comments and blanks, and it conflicts with cb428e81's own "about 130" (Claim 47). Retiring the test saves the whole file, so the precise text is "about 140 lines of test".

**Evidence:** `test/cc-host-tool-sources.bats:1-140`, `workflows/pr-prep.md:86-92`

---

## Claim 15: Design-table facts: decision 017's "grep table in the bats suite" was pruned "because a bats test cannot lint another repo"; `shfmt` is "a tool the repo's tests do not otherwise need"; "two byte-pinned copies"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:35`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these three checkable facts; does not re-run the "Prior pruning grep" or judge any option's verdict, which is rationale.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/017-polyglot-test-hermeticity.md:125` has "[1 grep table in the bats suite]: H2 is structural — a bats test in *this* repo cannot lint another repo". Paraphrased — no quote available because the claim covers absence: `rg shfmt test scripts` finds nothing, and its one hit is an allow-list in `hooks/auto-approve-allowed-commands.sh`. The byte pin is `@test "verify_host_tools is the same code in cc-isolated.sh and cc-push.sh"` at `test/cc-isolated-functions.bats:1134`.

**Evidence:** `docs/decisions/017-polyglot-test-hermeticity.md:125`, `test/cc-isolated-functions.bats:1134-1139`

---

## Claim 16a: "`cc-verify.sh` shipped a grammar for the same rule after this test was split off (its comment cites Q-147)."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of events and the citation; does not establish that the two grammars accept the same forms, and the reach lists show they do not.
**Legibility-target:** for-orchestrator-synthesis

The split is dated 2026-10-14 (rubric `:92`). `cc-verify.sh` was added in 6870e947 and `git log -S'source_lines_ok() {'` gives d5fa26c1, both 2026-10-20. The comment reads "(as row 71's\n# Q-147)" at `devcontainer-config/cc-verify.sh:45-46`.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:92`, `devcontainer-config/cc-verify.sh:45-46`

---

## Claim 16b: "...which S3 forbids, and it is shorter."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers code lines of the closure check, counted without comments and blanks; does not count seeded cases, which fa059477 did not have, and "shorter" depends on that counting choice, hence Medium.
**Legibility-target:** for-author

fa059477's whole test (`test/cc-isolated-functions.bats:1038-1076` at that commit) is 27 code lines. `setup` plus `check_entry` were 24 at 8880c925 and are 27 at cb428e81, so the two now tie. Adding the 6-line `@test` that calls `check_entry` gives 33 against 27. The S3 reason stands alone without "and it is shorter".

**Evidence:** `test/cc-host-tool-sources.bats:21-30`, `test/cc-host-tool-sources.bats:42-67`

---

## Claim 16c: "The cost is one rename: `source_lines_ok` does not know `$CC_PUSH_DIR`, so the test renames that variable in its copy of `cc-push.sh`."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what check_entry edits at cb428e81; does not dispute that `source_lines_ok` lacks `$CC_PUSH_DIR`, which is true.
**Legibility-target:** for-author

cb428e81 widened this and did not update the sentence. The code loops over every copy and also appends a newline:

```bash
# test/cc-host-tool-sources.bats:47-50
for f in "$dir"/cc-*.sh; do
  sed -i 's/CC_PUSH_DIR/CC_ISOLATED_DIR/g' "$f"
  echo >> "$f"
done
```

X1's `t-entry` mutation confirms the wider rename is load-bearing: limiting it to the entry point fails `not ok 4 a helper that names its directory CC_PUSH_DIR is read like cc-push.sh itself`. The precise text is "renames that variable in every copy", and the cost is now the rename plus the newline. Line `:62` of the same doc already has the newline.

**Evidence:** `test/cc-host-tool-sources.bats:47-50`, `X/exp1.out`

---

## Claim 17: The reach lists: "Seen by fa059477 only", "Seen by `source_lines_ok` only", "Seen by both", "Seen by neither", "from running both grammars over a sample of 19 spellings"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every spelling named in the four lists against both grammars, apart from the one generalisation in Claim 18; does not make either list exhaustive, which the doc does not claim.
**Legibility-target:** for-orchestrator-synthesis

`forms.sh` holds 19 spellings and its three regexes match fa059477's text at `:1049-1051`. The lists partition the 19 as 3, 1, 10 and 5, each matching its `forms.out` row, for example `\. "$D/h.sh"   miss   seen` and `FOO=1 source "$D/h.sh"   seen   miss`. The items marked "outside the sample" match `forms2.out`: `trap`, `bash -c` and `exec . ` are `seen miss`, and `eval "$x"` is `miss seen`.

**Evidence:** `FC/forms.out`, `FC/forms2.out`, `FC/forms.sh`

---

## Claim 18: "the same holds for anything with the word on the line, such as `trap 'source f' EXIT`, `bash -c 'source f'` and `exec . f`."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:53`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this one generalisation; does not affect the fact that each named form is seen by fa059477 only.
**Legibility-target:** for-author

Each form's result is right (E4), but `exec . f` has no word `source` on the line. fa059477 catches it through `dotcmd`, whose keyword list includes `exec`, not through `srcword`. The precise text is "anything with the word on the line, or a dot after `exec`".

**Evidence:** `FC/forms2.out`, `FC/forms.sh`

---

## Claim 19: "an unchecked `--x) source ...` in `cc-push.sh` leaves the test green. It is accepted and the file header names it."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an arm placed in cc-push's real argument case; does not establish that multi-word arms behave differently, though X3's `m-case` and `m-case2` show two more shapes passing.
**Legibility-target:** for-orchestrator-synthesis

X1's `arm` seed puts `--x) source "$CC_PUSH_DIR/cc-exit-scan.sh"; shift ;;` at `cc-push.sh:434` and reports `rc=0 ok=1 notok=0`. The header names it at `test/cc-host-tool-sources.bats:10`: "one-line case arms".

**Evidence:** `X/exp1.out`, `X/mut.out`, `test/cc-host-tool-sources.bats:9-10`

---

## Claim 20: "adding `)` to its detector alone refuses today's launcher on prose."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `)` added to the character class of a scratch copy of the function, run on the launcher; does not establish how many such lines exist, since the function stops at the first.
**Legibility-target:** for-orchestrator-synthesis

The patched function returned `rc=1` on `cc-isolated.sh`, naming this line:

```bash
# devcontainer-config/cc-isolated.sh:469
echo "ERROR: unknown egress profile $(printf %q "$p") (names must match exactly). Available:" >&2
```

The match is the `). ` in the message text, a closing bracket, a dot and a space, which the detector reads as a `.` command. That is prose. Only the one `)` was changed, by `arch/f1.py` (a two-line diff of the function).

**Evidence:** `devcontainer-config/cc-verify.sh:56`, `devcontainer-config/cc-isolated.sh:469`, `X/exp1.out`

---

## Claim 21: "The architecture review compared the two and rated the reuse better by a modest margin."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation only; review reports are outside this pass, so its reasoning was not checked.
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/architecture-review-2026-11-05-q089-source-guard.md:31` reads "The new design is better, by a modest margin."

**Evidence:** `docs/reviews/architecture-review-2026-11-05-q089-source-guard.md:31`

---

## Claim 22: "The test adds a final newline to its copies: `source_lines_ok`'s read loop never sees an unterminated last line (security review F1). The shipped function has the same gap"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:62`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's fix and the loop's behaviour; does not establish the shipped gap's reach, which the override log says is nil today because all files end in a newline.
**Legibility-target:** for-orchestrator-synthesis

The loop is `while IFS= read -r line; do` ... `done < "$f"` (`devcontainer-config/cc-verify.sh:54,62`). X1's `t-nonl` deletes `echo >> "$f"` and fails exactly `not ok 3 a plain source on a last line with no newline is still read`, with the other eight passing. The label "F1" is the rubric's (`docs/reviews/code-review-rubric-2026-11-05-test-q089-source-guard-narrow.md:21`, "security-reviewer F1"); the security report itself heads it "#### 1.".

**Evidence:** `devcontainer-config/cc-verify.sh:54`, `devcontainer-config/cc-verify.sh:62`, `test/cc-host-tool-sources.bats:49`, `X/exp1.out`

---

## Claim 23: "New file rather than the 3325-line `test/cc-isolated-functions.bats`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:63`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count; does not judge "it has no use for that file's setup", which is rationale.
**Legibility-target:** for-orchestrator-synthesis

Paraphrased — no quote available because the claim is a file length: `wc -l` gives 3325.

**Evidence:** `test/cc-isolated-functions.bats:1-3325`

---

## Claim 24: "Full-line comments are dropped before reading the check list, so such a comment quoting a call cannot stand in for it. An end-of-line comment still can."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both comment forms, with the real call both removed and kept; does not cover strings, which Claim 36 takes.
**Legibility-target:** for-orchestrator-synthesis

`test/cc-host-tool-sources.bats:44` starts `args="$(grep -vE '^[[:space:]]*#' "$dir/$entry" \`. With the real call renamed, X3's `c-full` fails and `c-trail` passes. With the real call kept and a wider list quoted above it, X1's `full-above` fails with `cc-push.sh sources cc-exit-scan.sh unchecked` and `eol-above` passes.

**Evidence:** `test/cc-host-tool-sources.bats:44-45`, `X/mut.out`, `X/exp1.out`

---

## Claim 25: "A permanent seeded-drift case per failure path of `check_entry` (H2) ... (17 `vacuous-assertion` entries)."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:65`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and each `return 1` in `check_entry`; does not cover `setup`'s failure path at `:25`, which has no case and which the sentence's "of `check_entry`" excludes.
**Legibility-target:** for-orchestrator-synthesis

`grep -c 'cause:vacuous-assertion' docs/failure-patterns.md` gives 17, and the plain word gives 19 because of a table row at `:62` and prose at `:106`. `check_entry`'s paths map to cases: `:46` case 8, `:51` cases 7 and 9, `:54` case 8, `:57` cases 2 to 5, `:58` case 6. All nine pass on base (X1), and each case asserts `[ "$status" -eq 1 ]` plus the path's own text, so each path did fire.

**Evidence:** `docs/failure-patterns.md:62`, `docs/failure-patterns.md:106`, `test/cc-host-tool-sources.bats:42-60`, `X/exp1/base/out.txt`

---

## Claim 26a: "`cc-verify.sh` is not walked: it has no `verify_host_tools` call and sources nothing. The `--list` argument lists (`cc-isolated.sh:527-528`) are separate copies and are not compared. The file header states both limits"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:66`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two limits and the line citation; does not establish that any other test compares the `--list` copies.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/cc-isolated.sh:527-528` is `lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true` and the matching `perr` line. X3's `m-list` drops `cc-gitdir.sh` from both and passes. `m-verify` adds a `source` to `cc-verify.sh` and passes. The header states both at `test/cc-host-tool-sources.bats:11-13`.

**Evidence:** `devcontainer-config/cc-isolated.sh:527-528`, `test/cc-host-tool-sources.bats:11-13`, `X/mut.out`

---

## Claim 26b: "...not whether the check runs before the `source` (the launch tests in `test/cc-isolated-functions.bats` cover that for the names in use)"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:66`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each entry point's own `source` line moved above its check; does not establish gating, since a source moved after the `if` was checked only against the guard (Claim 35), not against these tests.
**Legibility-target:** for-author

Order is covered for the names in use, but only half of it is in the file named. X2's `o-iso` moves the launcher's source above its check and fails at `test/cc-isolated-functions.bats, line 1158`, `[ ! -e "$mark" ]`. X2's `o-push` does the same in `cc-push.sh`: 37 filtered tests of that file stay green (`rc=0 ok=37 notok=0`), and the catch is `test/cc-push.bats, line 808`, `[ ! -e "$M/gitdir-ran" ]`. Paraphrased — no quote available because the claim covers absence: `rg 'bash .*cc-push' test/cc-isolated-functions.bats` has no hit, so that file never runs cc-push. The precise text adds "and `test/cc-push.bats:808` for cc-push".

**Evidence:** `test/cc-isolated-functions.bats:1143-1158`, `test/cc-push.bats:797-808`, `X/exp2.out`

---

## Claim 27: "`cc-verify.sh`'s comment ("as row 71's Q-147") and row 71 ("because grep cannot cover every bash spelling") already claim no more than the test does, so neither changes. No guide names the guard."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:68`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both quotations and a search of `guides/`; does not search review reports, which do name the guard.
**Legibility-target:** for-orchestrator-synthesis

The first quotation spans `devcontainer-config/cc-verify.sh:45-46`. The second is in `docs/decisions/log.md:94`: "was split out as Q-147, because grep cannot cover every bash spelling". Paraphrased — no quote available because the claim covers absence: `rg 'cc-host-tool-sources|source guard|source_lines_ok' guides` finds nothing.

**Evidence:** `devcontainer-config/cc-verify.sh:45-46`, `docs/decisions/log.md:94`

---

## Claim 28: "Against today's code, in the worktree: `bats test/cc-host-tool-sources.bats`, 7 ok."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:72`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at cb428e81; does not put the test's passing in doubt, since all cases pass.
**Legibility-target:** for-author

The file has 9 cases: `bats --count` gives 9, and X1's `base` is `rc=0 ok=9 notok=0`. The line dates from 8880c925, when the file had 7, and cb428e81 added two. The precise text is "9 ok".

**Evidence:** `test/cc-host-tool-sources.bats:62-140`, `X/exp1.out`

---

## Claim 29: "The test as it stood at fa059477, appended to a scratch copy, also passes today's code."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that one old test against the config, which is unchanged since db31db8b; does not say anything about the old test's reach.
**Legibility-target:** for-orchestrator-synthesis

E1's output ends `ok 1 every file an entry point sources, directly or through what it sources, is in its verify_host_tools list`.

**Evidence:** `FC/seed-runs.out`

---

## Claim 30a: The seeded-run block (`new: ok=5 not-ok=2`, `not ok 4 a new helper in the check list but not in host_tool_files is named`) and "(Case 4 fails there only because the seed has already made `cc-helper.sh` a host tool.)"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:78-84`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the numbers and case number against T at cb428e81; does not touch D3's result, since `not ok 1` and its message are unchanged, nor the explanation of why that case fails, which still holds.
**Legibility-target:** for-author

X2's `g-s3` gives `rc=1 ok=7 notok=2`, with `not ok 1` and `not ok 6 a new helper in the check list but not in host_tool_files is named`. Case 4 is now `a helper that names its directory CC_PUSH_DIR is read like cc-push.sh itself`, and it passes on the seed, so "Case 4" names the wrong test. The precise text is `new: ok=7 not-ok=2`, `not ok 6`, and "Case 6", or a note that the block is the 7-case run at 8880c925.

**Evidence:** `test/cc-host-tool-sources.bats:83-105`, `X/exp2.out`

---

## Claim 30b: "The seeds' sed edit of the hook's regex was imprecise and made `test/hooks/live-verify-gate.bats` case 26 fail: that case forces the regex, not the check list, so D3 still stands; with the regex edited exactly, that file passes 35 of 35."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reused E2 and E10 logs; I did not rerun this.
**Legibility-target:** for-orchestrator-synthesis

E2 has `not ok 26 the hook's host_tools regex names exactly host_tool_files, no more`. E10 has `test/hooks/live-verify-gate.bats rc=0 ok=35 not-ok=0`.

**Evidence:** `FC/seed-s3.out`, `FC/s3p.out`

---

## Claim 31: "a new helper that an entry point plainly sources, directly or through a file it sources, must be in that entry point's verify_host_tools list, or it runs unchecked."

**Location:** `test/cc-host-tool-sources.bats:3-5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher through the scan; does not separately probe a helper sourced directly by cc-push, though the listed-only mechanism is the same.
**Legibility-target:** for-orchestrator-synthesis

The check only hashes the names it is passed (`verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh`, `devcontainer-config/cc-isolated.sh:748`). X4 shows a tampered unlisted helper running with `HOST_TOOLS_ERR=[]`.

**Evidence:** `devcontainer-config/cc-isolated.sh:748`, `X/s3-live.out`

---

## Claim 32: "No other test ties the list to the `source` lines; the two names in use today are pinned one by one."

**Location:** `test/cc-host-tool-sources.bats:5-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two files that name the check plus the wider files E10 to E13 ran; does not cover the full suite on seed D3, so "no other test" rests on those files and on `rg` for `verify_host_tools` in `test/`, and it does not cover the `--list` copies.
**Legibility-target:** for-orchestrator-synthesis

First half: D3 leaves 260 of 260 green (E2), and `cc-verify.bats` and `install-host.bats` return to baseline once their fixtures have the file (E12, E13). Second half: all three pairs fail an existing test when dropped (X2): launcher and `cc-exit-scan.sh` at `test/cc-isolated-functions.bats:1153` and `:1180`, launcher and `cc-gitdir.sh` at `:1193`, cc-push and `cc-gitdir.sh` at `test/cc-push.bats:806`.

**Evidence:** `test/cc-isolated-functions.bats:1153`, `test/cc-isolated-functions.bats:1180`, `test/cc-isolated-functions.bats:1193`, `test/cc-push.bats:806`, `FC/seed-s3.out`, `X/exp2.out`

---

## Claim 33: "Q-089's fourth review pass showed that. Forms this one misses include `FOO=1 . f`, `FOO=1 source f`, one-line case arms, a quoted or obfuscated `source`, and `$c f`."

**Location:** `test/cc-host-tool-sources.bats:8-10`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named form run through T's real first case at cb428e81; "include" makes the list non-exhaustive, and `trap`, `timeout 5 source f` and others are also missed.
**Legibility-target:** for-orchestrator-synthesis

X3, each with an unlisted `cc-exit-scan.sh`: `m-foo-dot`, `m-foo-src`, `m-case`, `m-case2`, `m-quoted`, `m-obf` and `m-var` all report `rc=0 ok 1`. The rubric's `:94` has "Pass 4's fact-check (fa059477) found 3 Incorrect. Two concern the static source-set test's reach".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:94`, `X/mut.out`

---

## Claim 34: "It also does not see a tool run by name, cc-verify.sh (no verify_host_tools call; it sources nothing today), the lists `--list` passes"

**Location:** `test/cc-host-tool-sources.bats:11-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one seed of each limit; does not cover other ways of running a tool, such as `exec`.
**Legibility-target:** for-orchestrator-synthesis

X3: `m-byname` (`bash "$CC_PUSH_DIR/cc-exit-scan.sh"`), `m-verify` and `m-list` all pass. Paraphrased — no quote available because the claim covers absence: `rg verify_host_tools devcontainer-config/cc-verify.sh` has no hit, and its only `source` tokens are the function and its calls (`:47`, `:203-204`).

**Evidence:** `devcontainer-config/cc-verify.sh:47`, `devcontainer-config/cc-verify.sh:203-204`, `X/mut.out`

---

## Claim 35: "or whether the check comes before the source or gates it."

**Location:** `test/cc-host-tool-sources.bats:12-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers order on cc-push and gating on both entry points; does not assess whether other tests catch gating.
**Legibility-target:** for-orchestrator-synthesis

X3's `o-after` (source moved above the check) passes. X1's `gate-push` (the `exit 1` removed from the refusal block) and `gate-iso` (the source moved after the `fi`, so it runs whether or not the check passed) both report `rc=0 ok=1 notok=0`.

**Evidence:** `devcontainer-config/cc-push.sh:204-214`, `devcontainer-config/cc-isolated.sh:748-753`, `X/exp1.out`, `X/mut.out`

---

## Claim 36: "An end-of-line comment or string quoting a check call above the real one is read as the list."

**Location:** `test/cc-host-tool-sources.bats:13-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an end-of-line comment and a string whose text has the literal `"$CC_PUSH_DIR"`; does not cover a double-quoted string with escaped quotes, which does not match the grep and so is not read.
**Legibility-target:** for-orchestrator-synthesis

With a wider list quoted above the real call and an unlisted source appended, X1's `eol-above` and `str-above` pass, while `ctl-noquote`, the same seed with no quotation, fails. `str-esc` (`echo "verify_host_tools \"\$CC_PUSH_DIR\" ...`) fails, because the backslashes break the match.

**Evidence:** `test/cc-host-tool-sources.bats:44-45`, `X/exp1.out`

---

## Claim 37: "It is hardening against a refactor, and the runtime checks do not depend on it."

**Location:** `test/cc-host-tool-sources.bats:14-15`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the dependency direction; the branch adds no runtime file.
**Legibility-target:** for-orchestrator-synthesis

Paraphrased — no quote available because the claim covers absence: the diff adds one file under `test/` and changes nothing in `devcontainer-config/`, and `rg cc-host-tool-sources devcontainer-config` has no hit.

**Evidence:** `test/cc-host-tool-sources.bats:1-140`

---

## Claim 38: "The spelling rule is cc-verify.sh's own source_lines_ok, read from that file rather than restated here, so there is one grammar to keep."

**Location:** `test/cc-host-tool-sources.bats:17-18`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `source`-line grammar; does not extend to the check-call regex at `:45`, a separate pattern for a different job, or to the adapter edits `check_entry` makes.
**Legibility-target:** for-orchestrator-synthesis

`test/cc-host-tool-sources.bats:24` is `sed -n '/^source_lines_ok() {/,/^}/p' "$SRC/cc-verify.sh" > "$T/source-lines-ok.sh"`, and `:25` fails if the extract is empty. E14 confirms with the function renamed: `no source_lines_ok in cc-verify.sh`. Paraphrased — no quote available because the claim covers absence: `rg source_lines_ok test scripts skills` hits only T, and T holds no copy of the regexes.

**Evidence:** `test/cc-host-tool-sources.bats:24-27`, `devcontainer-config/cc-verify.sh:47-65`, `FC/mut2.out`

---

## Claim 39: "is in its first verify_host_tools call and in host_tool_files."

**Location:** `test/cc-host-tool-sources.bats:36-37`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which call is read for each entry point today; does not change the outcome for cc-push, whose first call is the one read.
**Legibility-target:** for-author

The first call in `cc-isolated.sh` is `:527`, and the one read is `:748`. The grep at `:45` admits only two directory variables, `verify_host_tools "\$CC_(ISOLATED|PUSH)_DIR"`, so `$cfg_real` at `:527-528` is skipped. X1's `args` output confirms it: `verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh` comes first. The header's `--list` limit reconciles this for a careful reader. The precise text is "its first verify_host_tools call on `$CC_ISOLATED_DIR` or `$CC_PUSH_DIR`".

**Evidence:** `test/cc-host-tool-sources.bats:44-45`, `devcontainer-config/cc-isolated.sh:527`, `devcontainer-config/cc-isolated.sh:748`, `X/exp1.out`

---

## Claim 40: "It works on copies, which it adjusts for the shared grammar: CC_PUSH_DIR, which the grammar does not know, becomes the launcher's variable (so a refused line shows that name), and each copy gets a final newline, because the grammar's read loop never sees an unterminated last line."

**Location:** `test/cc-host-tool-sources.bats:38-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every clause; does not establish that callers always pass copies, though all cases do (`"$T/cfg"`, filled at `:29`).
**Legibility-target:** for-orchestrator-synthesis

The grammar's `src` regex at `devcontainer-config/cc-verify.sh:49` admits `\$CC_ISOLATED_DIR` and the own-directory form only. X1's `t-noren` removes the rename and refuses the real tree: `not a plain source line: ...cc-push.sh: source "$CC_PUSH_DIR/cc-gitdir.sh"`, with 7 of 9 failing. `test/cc-host-tool-sources.bats:113` asserts the refused line shows `. "$CC_ISOLATED_DIR/cc-gitdir.sh"`. `t-nonl` covers the newline (Claim 22), and `t-entry` covers "every copy" (Claim 16c).

**Evidence:** `test/cc-host-tool-sources.bats:28-29`, `test/cc-host-tool-sources.bats:47-50`, `test/cc-host-tool-sources.bats:113`, `devcontainer-config/cc-verify.sh:49`, `X/exp1.out`

---

## Claim 41: "Positive control: both entry points reach cc-gitdir.sh (the launcher through the scan)."

**Location:** `test/cc-host-tool-sources.bats:53`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's source lines; the control's failure path is Claim 1's.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/cc-exit-scan.sh:12` is the launcher's route: `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"`. `devcontainer-config/cc-push.sh:214` is direct: `source "$CC_PUSH_DIR/cc-gitdir.sh"`. Case 1 passes on both entry points (X1 `base`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:12`, `devcontainer-config/cc-push.sh:214`, `X/exp1/base/out.txt`

---

## Claim 42: The seven original @test names (cases 1, 2, 5, 6, 7, 8, 9) against what each asserts

**Location:** `test/cc-host-tool-sources.bats:62-74`, `test/cc-host-tool-sources.bats:91-140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its body and a passing run; does not generalise beyond the seeds: case 7's "any other directory" tries only `$(config_dir)`, and case 8's "no check call" half and cases 2, 6, 7 and 9 run on `cc-push.sh` alone.
**Legibility-target:** for-orchestrator-synthesis

I read each body whole. Case 1 runs `check_entry` on both entry points and needs status 0. Cases 2 and 5 assert `sources ... unchecked`, and case 5's name is right because cc-gitdir reaches the launcher only through the scan (Claim 41). Case 6 asserts `cc-helper.sh is not a host tool`. Case 7 asserts `not a plain source line` for a dot source and for `$(config_dir)/cc-gitdir.sh`. Case 8 asserts both messages. Case 9 removes the file and asserts `cc-gitdir.sh is missing`, which reaches the output through `:51` with a "not a plain source line:" prefix; the name's "naming it" still holds. All pass in X1 `base`, and each failure case asserts status 1 plus its text.

**Evidence:** `test/cc-host-tool-sources.bats:62-74`, `test/cc-host-tool-sources.bats:91-140`, `X/exp1/base/out.txt`

---

## Claim 43: "a plain source on a last line with no newline is still read"

**Location:** `test/cc-host-tool-sources.bats:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-push as the file with the unterminated line; does not separately cover a helper with one, though the loop at `:47-50` treats every copy the same.
**Legibility-target:** for-orchestrator-synthesis

`:77` is `printf 'source "$CC_PUSH_DIR/cc-exit-scan.sh"' >> "$T/cfg/cc-push.sh"`, and the file already ends in a newline, so the line stands alone and unterminated. `:80` asserts `cc-push.sh sources cc-exit-scan.sh unchecked`. The case can fail: X1's `t-nonl` fails it alone.

**Evidence:** `test/cc-host-tool-sources.bats:76-81`, `X/exp1.out`

---

## Claim 44: "a helper that names its directory CC_PUSH_DIR is read like cc-push.sh itself"

**Location:** `test/cc-host-tool-sources.bats:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helper's line being accepted rather than refused; does not show a name reached only through the helper, because the helper sources `cc-gitdir.sh`, which `cc-push.sh` already sources, so the assertion's `cc-helper.sh` comes from cc-push's own line.
**Legibility-target:** for-orchestrator-synthesis

The helper's body is `source "$CC_PUSH_DIR/cc-gitdir.sh"` (`:84`). `:88` asserts `cc-push.sh sources cc-helper.sh unchecked`, a message that needs the walk to pass the helper without refusal. X1's `t-entry` limits the rename to the entry point and fails this case alone, so the helper is read and the rename is what admits it.

**Evidence:** `test/cc-host-tool-sources.bats:83-89`, `X/exp1.out`

---

## Claim 45: 8880c925: "A seeded new helper left today's suite green."

**Location:** commit 8880c92560470347dfe15ac5754d604ecbce82d3
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sentence as written; it is history and not editable, and the rest of that message ("reuses source_lines_ok", the reach record) is accurate.
**Legibility-target:** for-orchestrator-synthesis

The run was two files, not the suite (`existing: ok=260 not-ok=0`, E2), and three further files went red on that seed before their fixtures were edited (E2, E10). cb59c2bb's message records the correction and `R:21` and `R:29` scope it. No action is open.

**Evidence:** `FC/seed-s3.out`, `FC/s3p.out`

---

## Claim 46: cb59c2bb: "Pass 1 fact-check: 2 Incorrect and 8 Mostly accurate, all prose. The motive text names which drift is caught and how, the header says unchecked and adds the ordering limit, and the seeds are D1 to D3, apart from constraint S3."; cb428e81: "the grammar's read loop misses an unterminated last line, and the rename covered only cc-push.sh. check_entry now adjusts every copy, with a seeded case for each."; "Three findings declined or deferred, rows in the override log."

**Location:** commit cb59c2bb3e240f17d653bedf332b460950e86569, commit cb428e81a7223c1387e17418c89da4a5e3fd6892
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these sentences; "Header and research doc state the remaining limits" holds for the limits, though the doc's `:51` still describes the old rename (Claim 16c), and "iteration 1 of 3" was not checked beyond the rubric's "Loop pass 1".
**Legibility-target:** for-orchestrator-synthesis

The prior report's header reads `25 verified, 8 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable`, and its attention list is all documentation text. At cb59c2bb the rename was `sed -i 's/CC_PUSH_DIR/CC_ISOLATED_DIR/g' "$dir/cc-push.sh"`. T went from 7 to 9 cases, and `t-nonl` and `t-entry` each fail exactly the new case for their fix (X1). The override log diff adds three rows: one Won't-Fix and two Defer.

**Evidence:** `docs/reviews/code-fact-check-report-q089-source-guard.md:10`, `docs/reviews/override-log.md`, `X/exp1.out`

---

## Claim 47: cb428e81: "Size: about 130 code lines against main."

**Location:** commit cb428e81a7223c1387e17418c89da4a5e3fd6892
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figure under pr-prep step 1a's count; does not touch the gate, since 140 is far under the 400 cap.
**Legibility-target:** for-orchestrator-synthesis

pr-prep's own command, `git diff --numstat main...cb428e81 -- ':(top)' ':(top,exclude)docs/'`, prints `140	0	test/cc-host-tool-sources.bats`, so the figure is 140. Counts that drop lines give 128 (no blanks) or 102 (no comments or blanks), neither of which is the defined measure. Editing the message would change the commit id, so this is for the orchestrator to weigh; the size gate is unaffected.

**Evidence:** `workflows/pr-prep.md:86-92`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 16b** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`): "and it is shorter" no longer holds: 27 code lines against fa059477's 27, 33 with the calling test. Drop the clause.
- **Claim 16c** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`): "renames that variable in its copy of `cc-push.sh`" predates cb428e81. It is every copy now, and the cost is the rename plus the newline.
- **Claim 28** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:72`): "7 ok" should be 9 ok.
- **Claim 30a** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:78-84`): the block is the 7-case run. Today it is `ok=7 not-ok=2` with `not ok 6`, and "Case 4" now names a different test that passes on the seed.

### Mostly Accurate
- **Claim 8** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`): `cc-push.bats:807` should be `:806`, where the drop actually fails.
- **Claim 14** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:41`): "about 100 lines" should be about 140.
- **Claim 18** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:53`): `exec . f` has no word `source` on the line.
- **Claim 26b** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:66`): the launch tests cover the launcher's order only; cc-push's is `test/cc-push.bats:808`.
- **Claim 39** (`test/cc-host-tool-sources.bats:36-37`): "first verify_host_tools call" is the first on `$CC_ISOLATED_DIR` or `$CC_PUSH_DIR`; the launcher's literal first is `:527`.
- **Claim 45** (commit 8880c925): "today's suite" was two files. History; already recorded by cb59c2bb.
- **Claim 47** (commit cb428e81): "about 130 code lines" is 140 by pr-prep's count.

### Unverifiable
(none)

---

## Goal-Alignment Note

- Success criterion (restated verbatim): a report at docs/reviews/code-fact-check-report-q089-source-guard-r3.md with `Commit: cb428e81`, each claim tagged with Legibility-target, ending in a Goal-Alignment Note. Commit nothing, edit nothing else.
- Answered: yes. All three named claim groups were checked, by execution wherever a claim concerned behaviour, and the two new cases were each shown able to fail.
- Out of scope: review reports' reasoning, 8880c925's wording as an edit target, test quality beyond what claims assert, and whole-suite reruns (filtered `bats -f` runs only; 260 and 48-of-48 rest on reused E1, E2 and E8).
- Escalate: no Incorrect, and the test's behaviour and its header match. Eight prose items in the research doc are worth one edit, four of them Stale from cb428e81 not reaching `:51`, `:72` and `:78-84`. One code comment is imprecise (Claim 39). None changes the land decision: D1 to D3 reproduce against T at cb428e81.
- Decisions I made: execution logs stay in `X`, because the dispatch allowed one file. Claim 16b is Stale at Medium confidence, because "shorter" depends on what is counted. Claims 45 and 47 are tagged for-orchestrator-synthesis, because neither message can change without history edits. Seven original test names share one claim because they earn the same verdict.
