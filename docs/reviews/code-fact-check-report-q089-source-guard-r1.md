Commit: cb428e81

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `wt-2026-11-05-q089-source-guard-narrow`, branch `test/q089-source-guard-narrow`)
**Scope:** `git diff db31db8b..cb428e81 -- test/cc-host-tool-sources.bats docs/working/research-2026-11-05-q089-source-guard-narrow.md`, plus the commit messages of `git log db31db8b..cb428e81`. Review reports in `docs/reviews` were used as evidence only.
**Checked:** 2026-11-05
**Replication:** k=3 final pass; this is replicate r1
**Total claims checked:** 61
**Summary:** 52 verified, 6 mostly accurate, 3 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). No claim here is a fabrication. Claims 33 and 35 are counts that were true of an earlier version of the file, so they are stale, not the log's "value the artifact does not contain" class. Claim 60 ("about 130") is nearest to that class, but it is an approximation and no gate depends on it.

Shorthand: `R` is `docs/working/research-2026-11-05-q089-source-guard-narrow.md`, `T` is `test/cc-host-tool-sources.bats`, `X` is `/tmp/claude-1000/-workspace/47403b7b-5fcb-4e13-8807-c539081df064/scratchpad/2026-11-05-q089-source-guard-narrow/fc-r1`, and `FC` is the sibling `fc` directory, the prior pass's evidence.

## Execution log

All new runs used scratch copies made with `git archive cb428e81` under `X`. The worktree's code was not changed. `git rev-parse HEAD` in the worktree gave cb428e81 and `git status --short` was empty before this report was written. Times are UTC, 2026-11-06. `devcontainer-config/` is unchanged between db31db8b and cb428e81, so earlier evidence about the grammar and the config still applies.

| Id | Command | Cwd | Exit | Time | Output |
|---|---|---|---|---|---|
| N1 | `timeout 240 bash ./x1.sh` (nine cases on the base copy; two mutated copies of T; header forms; quoted calls; order and gate; detector with `)`; unterminated line; D1 to D3 with the current T) | `X` | 0 | 03:40:12 | `X/x1.out`, `X/x1/*/out.txt` |
| N2 | `timeout 560 bash ./x2.sh` (a dropped name, a moved check or a lost gate, then `bats -f 'host.tool\|verify_host_tools\|cc-push\|tampered' test/cc-isolated-functions.bats` and `bats -f 'installed copy' test/cc-push.bats`) | `X` | 0 | 03:40:59 | `X/x2.out`, `X/x2/*.out` |
| N3 | `timeout 60 bash s1.sh`, `s2.sh`, `s3.sh`, `s4.sh` (read-only greps, counts and `git` queries on the worktree, including `bats --count`) | `X` | 0 | 03:35 to 03:43 | `X/s1.out`, `X/s2.out`, `X/s3.out`, `X/s4.out` |
| N4 | `timeout 60 bash s5.sh` (`git diff --numstat`, a grep of `test/cc-isolated-functions.bats` for a run of cc-push, cited line numbers, this report's own counts) | `X` | 0 | 03:50 | `X/s5.out` |

Reused from the prior pass, not rerun: `FC/seed-runs.out` (E1), `FC/seed-s3.out` (E2), `FC/forms.out` (E3), `FC/forms2.out` (E4), `FC/mut.out` (E5), `FC/pf.out` (E6), `FC/s1fix.out` (E8), `FC/s3-live.out` (E9), `FC/s3p.out` (E10), `FC/base-*.out` (E11), `FC/s3p2-cc-verify.out` (E12), `FC/s3p3-install-host.out` (E13), `FC/mut2.out` (E14). Their commands, exits and times are in the prior report's execution log, `docs/reviews/code-fact-check-report-q089-source-guard.md`. `forms.sh`'s regexes were compared with fa059477 and are the same text (`git show fa059477:test/cc-isolated-functions.bats`, lines 1049-1051).

No process from these runs was left running (`pgrep -af 'x1.sh|x2.sh|bats'` matched only its own shell).

---

## Claim 1: "Brief: `docs/working/briefs/2026-11-05-q089-source-guard-narrow.md` (dispatched at db31db8b)."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the brief's existence and its iteration matching db31db8b's merge; does not establish that the brief's requirements were met.
**Legibility-target:** for-orchestrator-synthesis

The brief says `Date: 2026-11-05 (dev cycle iteration 2026-11-05-2347)` (`docs/working/briefs/2026-11-05-q089-source-guard-narrow.md:4`), and db31db8b is `Merge branch 'chore/dev-cycle-2026-11-05-2347'`.

**Evidence:** `docs/working/briefs/2026-11-05-q089-source-guard-narrow.md:4`, `X/s4.out`

---

## Claim 2: "The test keeps fa059477's positive control (both entry points must reach `cc-gitdir.sh`), and a missing check call fails, so neither case passes empty."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the control at `T:54` and failure on a lost call at both entry points; does not establish the message for the launcher, which falls through to its next call and says something else.
**Legibility-target:** for-orchestrator-synthesis

`[[ " ${SOURCED[*]} " == *" cc-gitdir.sh "* ]] || { echo "parse missed cc-gitdir.sh for $entry` (`test/cc-host-tool-sources.bats:54`, excerpt ends mid-line; enclosing `check_entry` continues to `:60` — read). Case 8 passes on cc-push (N1). With the launcher's first call renamed the run still fails, printing `cc-isolated.sh sources cc-exit-scan.sh unchecked` (E14).

**Evidence:** `test/cc-host-tool-sources.bats:42-60`, `test/cc-host-tool-sources.bats:121-133`, `X/x1.out`, `FC/mut2.out`

---

## Claim 3: "FP-175 ... the source of R2's 1-in-25 flake. The new file does not source the launcher into the test shell, so it has no pipefail, and it still uses a here-string."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:13`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pipefail being off in the bats test shell and the here-string; does not establish the same for the child shell at `T:55`, which has pipefail but only echoes.
**Legibility-target:** for-orchestrator-synthesis

`hosts="$(bash -c 'source "$1"; host_tool_files' _ "$dir/cc-isolated.sh")"` (`test/cc-host-tool-sources.bats:55`) and `grep -qx -- "$f" <<< "$hosts"` (`:58`). `FC/pf.out` (E6) has `pipefail off` in the test shell. T's setup is unchanged in this respect since that run.

**Evidence:** `test/cc-host-tool-sources.bats:55-58`, `docs/failure-patterns.md:317`, `FC/pf.out`

---

## Claim 4: The rubric's quotes and its list (`FOO=1 . f`, case arms, `\. f`, quoted or obfuscated `source`, `$c f`), and finding A6's quote

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:17`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted text; does not establish that the earlier rubric's own findings were correct.
**Legibility-target:** for-orchestrator-synthesis

`Two concern the static source-set test's reach (`FOO=1 . f`, case arms, `\. f`, quoted or obfuscated `source`, `$c f`)` and `it guards plain spellings against accidental drift and is not complete for bash` (`docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:94-97`). `would be forced into `host_tool_files` by tests, but the launcher would still source it unchecked` (same file, `:35`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:35`, `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:92-97`

---

## Claim 5: "(baseline: 260 ok, 0 failed, `LC_ALL=C`)"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:21`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named suites; does not establish anything about the repo's other suites.
**Legibility-target:** for-orchestrator-synthesis

`--- base existing: ok=260 not-ok=0` (`FC/seed-runs.out`). `bats --count` gives 212 and 48 for the two files (N3), which sum to 260.

**Evidence:** `FC/seed-runs.out`, `X/s2.out`

---

## Claim 6: D1 row: "1 fails, `test/cc-push.bats:803`, only because that fixture lacks the file: the failure does not mention the list" / "fails: `cc-push.sh sources cc-exit-scan.sh unchecked`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both columns; does not establish how many cases of T fail, which is now four, not the three of the earlier seven-case file.
**Legibility-target:** for-orchestrator-synthesis

`# (in test file test/cc-push.bats, line 803)` and ``#   `[ "$status" -eq 0 ]' failed`` (`FC/seeds/s1/existing.out`). The fixture copies only cc-push.sh and cc-gitdir.sh (`test/cc-push.bats:800`). With the current T, `# cc-push.sh sources cc-exit-scan.sh unchecked` (N1, `d1`).

**Evidence:** `test/cc-push.bats:797-803`, `FC/seed-runs.out`, `X/x1.out`

---

## Claim 7: D2 row: "1 fails: `test/cc-isolated-functions.bats:1193` asserts that the refusal names that tool" / "fails: `cc-isolated.sh sources cc-gitdir.sh unchecked`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the dropped cc-gitdir.sh only; the dropped cc-exit-scan.sh is Claim 9.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$output" == *"cc-exit-scan.sh changed"*"cc-gitdir.sh changed"* ]]` (`test/cc-isolated-functions.bats:1193`). N2's `dl-git` fails at that line, and N1's `d2` prints the stated message.

**Evidence:** `test/cc-isolated-functions.bats:1193`, `X/x2.out`, `X/x1.out`

---

## Claim 8: D3 row: "added to `host_tool_files`, PAYLOAD, the hook's regex, the fixtures and the pinned lists, but not to the launcher's check" / "**260 ok, 0 failed**" / "fails: `cc-isolated.sh sources cc-helper.sh unchecked`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seed's steps and the two named suites; does not establish the whole repo suite, which R:29 says was not run.
**Legibility-target:** for-orchestrator-synthesis

`existing: ok=260 not-ok=0` (`FC/seed-s3.out`). The seed's steps are in `FC/seed-s3.sh`, including `sed -i '/^PAYLOAD=(/s/cc-gitdir\.sh/& cc-helper.sh/' "$C/install.sh"`. N1's `d3`, with the current T on that seed's config, prints `# cc-isolated.sh sources cc-helper.sh unchecked`.

**Evidence:** `FC/seed-s3.sh`, `FC/seed-s3.out`, `X/x1.out`

---

## Claim 9: "Dropping a name in use today is caught, directly (`cc-isolated-functions.bats:1193`, `cc-push.bats:807`)"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all four list entries, each dropped alone; does not establish coverage of a name not yet in use.
**Legibility-target:** for-author

The conclusion holds for every entry (N2). The cc-push citation is one line off. Dropping cc-gitdir.sh from cc-push's list fails at `[ "$status" -eq 1 ]`, `test/cc-push.bats:806`, and `:807` is never reached: `# (in test file test/cc-push.bats, line 806)` (`X/x2.out`, `dp-git`). `:807` is the line that would name the tool, so the citation is defensible as "the assertion that names it" but is not where the test fails. Also, `cc-isolated-functions.bats:1193` is the cc-gitdir.sh drop only. Dropping cc-exit-scan.sh fails at `:1153` and `:1180` (`dl-scan`). The precise version: `cc-isolated-functions.bats:1153` and `:1193`, `cc-push.bats:806`.

**Evidence:** `test/cc-push.bats:805-807`, `test/cc-isolated-functions.bats:1153`, `test/cc-isolated-functions.bats:1180`, `X/x2.out`

---

## Claim 10: "D1's catch is a fixture accident, and with the fixture copying the file `test/cc-push.bats` passes 48 of 48 with the seed in."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `test/cc-push.bats` with D1 and that one fixture change; does not establish other suites under D1.
**Legibility-target:** for-orchestrator-synthesis

`ok 48 installed copy: cc-push checks itself and cc-gitdir.sh before sourcing, and refuses on a change (row 71)` is the last line of `FC/s1fix.out`, which has 48 `ok` lines and no `not ok`.

**Evidence:** `FC/s1fix.out`

---

## Claim 11: "`test/cc-verify.bats` and `test/install-host.bats` also need `cc-helper.sh` in a fixture, and with that they match the baseline. The full suite was not run on the seed."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers those two files; "the baseline" includes one existing install-host failure (T9), which is the same on both sides.
**Legibility-target:** for-orchestrator-synthesis

`FC/base-cc-verify.out` and `FC/s3p2-cc-verify.out` both have 12 `ok`. `FC/base-install-host.out` and `FC/s3p3-install-host.out` both have 104 `ok` and 1 `not ok` (`not ok 9 T9 installed hooks still find lib/ and ../scripts`), and they do not differ once timings are stripped (N3).

**Evidence:** `FC/base-cc-verify.out`, `FC/s3p2-cc-verify.out`, `FC/base-install-host.out`, `FC/s3p3-install-host.out`, `X/s1.out`

---

## Claim 12: "A live probe from the fact-check confirmed the result: a tampered helper ran with `HOST_TOOLS_ERR` empty, while the `cc-gitdir.sh` control was refused."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe's output; it sourced the launcher in a scratch config and is not a host install.
**Legibility-target:** for-orchestrator-synthesis

`HOST_TOOLS_ERR=[]` then `tampered helper RAN at source time`, and `control: tampered gitdir refused, did not run` (`FC/s3-live.out`).

**Evidence:** `FC/s3-live.out`

---

## Claim 13: "That breaks row 71's stated rule ("Each entry point checks the host tools it executes before sourcing them")"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quote and that D3 contradicts it; "in the quiet way H2 rules out" is a reading of H2, not checked further.
**Legibility-target:** for-orchestrator-synthesis

`Each entry point checks the host tools it executes before sourcing them` (`docs/decisions/log.md:94`).

**Evidence:** `docs/decisions/log.md:94`, `docs/constraints.md:6`

---

## Claim 14: "The sourced set has not changed since Q-089, and `cc-verify.sh` joined the host tools without sourcing anything. ... row 71 places this under non-targeted tampering, as defence in depth."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:31`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `^\s*source` history in the four files and row 71's text; does not cover spellings other than `source` in history.
**Legibility-target:** for-orchestrator-synthesis

`git log -G'^\s*source '` over those four files gives 4be0445d and f2533b33 (both Q-089) as the newest (`X/s2.out`). `cc-verify.sh` has no code line that sources: the only grep hits are comment lines and the grammar's own strings (`devcontainer-config/cc-verify.sh:42-56`). `non-targeted host tampering, defence in depth` (`docs/decisions/log.md:94`).

**Evidence:** `devcontainer-config/cc-verify.sh:42-56`, `docs/decisions/log.md:94`, `X/s2.out`

---

## Claim 15: "leaves A6 open for about 100 lines of test saved"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:41`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-blank, non-comment lines, 102 at cb428e81; the file's total is 140.
**Legibility-target:** for-orchestrator-synthesis

`cb428e81 total=140 code=102 core=33` (`X/s4.out`).

**Evidence:** `X/s4.out`

---

## Claim 16: "decision 017's "grep table in the bats suite", which was pruned because a bats test cannot lint another repo"; candidate 5, "a test dependency on a tool the repo's tests do not otherwise need"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quote and that `test/` and `scripts/` do not use shfmt; the pruning verdicts themselves are design rationale, not checked.
**Legibility-target:** for-orchestrator-synthesis

`[1 grep table in the bats suite]: H2 is structural — a bats test in *this* repo cannot lint another repo` (`docs/decisions/017-polyglot-test-hermeticity.md:125`). `git grep -n shfmt -- test scripts` printed nothing (paraphrased — no quote available because the claim covers absence of code; output in `X/s4.out`).

**Evidence:** `docs/decisions/017-polyglot-test-hermeticity.md:125`, `X/s4.out`

---

## Claim 17: "`cc-verify.sh` shipped a grammar for the same rule after this test was split off (its comment cites Q-147)."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers dates and the comment; "for the same rule" is the spelling rule only, since `source_lines_ok` does not compare anything to a check list.
**Legibility-target:** for-orchestrator-synthesis

`parser: other spellings, or a staged script run by name, are not seen (as row 71's` then `Q-147)` (`devcontainer-config/cc-verify.sh:45-46`). cc-verify's first commit, 6870e947, is 2026-10-20; the split was 2026-10-14 (`docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:92`).

**Evidence:** `devcontainer-config/cc-verify.sh:41-46`, `X/s2.out`

---

## Claim 18: "and it is shorter."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers non-comment lines of the guard's core against fa059477's single test; does not count seeded cases, which fa059477 did not have.
**Legibility-target:** for-author

fa059477's test is `fa total=39 code=27`. Option 2's `setup`, `check_entry` and case 1 are `core=33` at cb428e81 and `core=30` at 8880c925 (`X/s4.out`). Without `setup`, which fa059477 did not need because it used the host file's, that is about 24 against 27. So it is shorter only if `setup` is left out, although `setup` holds the three lines that read the grammar. The precise version would drop the size argument or say the two are about the same length. The S3 argument in the same sentence stands without it.

**Evidence:** `test/cc-host-tool-sources.bats:21-30`, `test/cc-host-tool-sources.bats:42-67`, `X/s4.out`

---

## Claim 19: "The cost is one rename: `source_lines_ok` does not know `$CC_PUSH_DIR`, so the test renames that variable in its copy of `cc-push.sh`."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rename's reach; the first half, that the grammar lacks the variable, holds.
**Legibility-target:** for-author

cb428e81 changed this code and not this sentence. The code now is `for f in "$dir"/cc-*.sh; do` / `sed -i 's/CC_PUSH_DIR/CC_ISOLATED_DIR/g' "$f"` (`test/cc-host-tool-sources.bats:47-48`), every copy. Restoring the cc-push.sh-only rename fails case 4: `not ok 4 a helper that names its directory CC_PUSH_DIR is read like cc-push.sh itself` (N1, `m-rename1`). The commit message says the same: "the rename covered only cc-push.sh. check_entry now adjusts every copy". The precise version: "so the test renames that variable in every copy".

**Evidence:** `test/cc-host-tool-sources.bats:47-50`, `X/x1.out`

---

## Claim 20: The change in reach, "from running both grammars over a sample of 19 spellings", and the four lists

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each spelling listed, in and outside the sample; "seen" means the grammar's detector fires, and for `source_lines_ok` a form with a trailing comment is seen because it is refused.
**Legibility-target:** for-orchestrator-synthesis

Each row of `FC/forms.out` (19 rows: 3 + 1 + 10 + 5) matches its list, for example `a) source "$D/h.sh" ;;                       seen     miss`, `\. "$D/h.sh"                                  miss     seen` and `$c "$D/h.sh"                                  miss     miss`. The outside-sample items match `FC/forms2.out`: `trap 'source "$D/h.sh"' EXIT                 seen     miss`, `exec . "$D/h.sh"                             seen     miss`, `eval "$x"                                    miss     seen`. `forms.sh`'s regexes are fa059477's (execution log above).

**Evidence:** `FC/forms.out`, `FC/forms2.out`, `FC/forms.sh`

---

## Claim 21: "The real loss is the one-line case arm, which is these files' own idiom: an unchecked `--x) source ...` in `cc-push.sh` leaves the test green. It is accepted and the file header names it."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that form with the arm's first command as `source`; `a) x; source f ;;` is a different form, which the `;` makes visible.
**Legibility-target:** for-orchestrator-synthesis

`h-case-arm             rc=0 ok 1 plain source lines in the entry points stay inside their verify_host_tools lists` (`X/x1.out`), with an unlisted cc-exit-scan.sh. The idiom: `--list)       action="list"; shift ;;` (`devcontainer-config/cc-isolated.sh:796`). The header: `one-line case arms` (`test/cc-host-tool-sources.bats:10`).

**Evidence:** `devcontainer-config/cc-isolated.sh:796`, `test/cc-host-tool-sources.bats:9-10`, `X/x1.out`

---

## Claim 22: "adding `)` to its detector alone refuses today's launcher on prose."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `)` added to the character class and nothing else, run on the launcher and on cc-push.sh; does not establish that any wider fix would be clean.
**Legibility-target:** for-orchestrator-synthesis

With `)` in the class (`FC/../arch/f1.py`), `source_lines_ok` on the launcher returns 1, printing `cfg/cc-isolated.sh:       echo "ERROR: unknown egress profile $(printf %q "$p") (names must match exactly). Available:" >&2` (`X/x1.out`; the source line is `devcontainer-config/cc-isolated.sh:469`). The match is `). ` in that message, so it is prose. cc-push.sh is refused the same way, on the `git_version_ok` message.

**Evidence:** `devcontainer-config/cc-isolated.sh:469`, `devcontainer-config/cc-verify.sh:56`, `X/x1.out`

---

## Claim 23: "The architecture review compared the two and rated the reuse better by a modest margin."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the review says, not whether it is right.
**Legibility-target:** for-orchestrator-synthesis

`The new design is better, by a modest margin.` (`docs/reviews/architecture-review-2026-11-05-q089-source-guard.md:31`)

**Evidence:** `docs/reviews/architecture-review-2026-11-05-q089-source-guard.md:31`

---

## Claim 24: "The test adds a final newline to its copies: `source_lines_ok`'s read loop never sees an unterminated last line (security review F1). The shipped function has the same gap; fixing it is a host-tool change, left as a follow-up."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:62`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gap in the shipped function and the test's fix; the follow-up exists only as a Defer row in the override log, with no roadmap or questions entry.
**Legibility-target:** for-orchestrator-synthesis

`no-newline rc=0 SOURCED=[]` and `newline rc=0 SOURCED=[a.sh]` (`X/x1.out`), run on the function extracted from cc-verify.sh at cb428e81. The loop is `while IFS= read -r line; do` (`devcontainer-config/cc-verify.sh:54`). The review's heading is `#### 1. A plain `source` on a last line with no newline passes the guard unseen` (`docs/reviews/security-review-2026-11-05-q089-source-guard.md:32`). Its Defer row is `docs/reviews/override-log.md:896`. `git grep source_lines_ok` found nothing else under `docs/working` or the roadmap (paraphrased — no quote available because the claim covers absence; `X/s3.out`).

**Evidence:** `devcontainer-config/cc-verify.sh:47-66`, `docs/reviews/override-log.md:896`, `X/x1.out`

---

## Claim 25: "New file rather than the 3325-line `test/cc-isolated-functions.bats`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:63`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at cb428e81.
**Legibility-target:** for-orchestrator-synthesis

`3325 test/cc-isolated-functions.bats` (`X/s2.out`).

**Evidence:** `X/s2.out`

---

## Claim 26: "Full-line comments are dropped before reading the check list, so such a comment quoting a call cannot stand in for it. An end-of-line comment still can."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both comment forms placed above the real call; a wider list in the comment and an unlisted real source.
**Legibility-target:** for-orchestrator-synthesis

`q-full                 rc=1 not ok 1` and `q-eol                  rc=0 ok 1` (`X/x1.out`). The filter is `grep -vE '^[[:space:]]*#' "$dir/$entry"` (`test/cc-host-tool-sources.bats:44`).

**Evidence:** `test/cc-host-tool-sources.bats:44-45`, `X/x1.out`

---

## Claim 27: "A permanent seeded-drift case per failure path of `check_entry` (H2) ... assertions that could not fail are a large family in `docs/failure-patterns.md` (17 `vacuous-assertion` entries)."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:65`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five `echo` paths of `check_entry` and entries with `cause:vacuous-assertion`; the word `vacuous-assertion` occurs on 19 lines, the other two being the legend and a summary sentence.
**Legibility-target:** for-orchestrator-synthesis

The paths and their cases: `no verify_host_tools call` (case 8), `not a plain source line` (7, 9), `parse missed` (8), `sources $f unchecked` (2 to 5), `is not a host tool` (6). All nine pass (N1). `rg -n 'cause:vacuous-assertion' docs/failure-patterns.md | wc -l` gives 17 (`X/s2.out`, listed in `X/s3.out`, for example `- **FP-082** 2026-07-30 symptom:literal-adjacency-grep-broken-by-inserted-argument cause:vacuous-assertion`, `docs/failure-patterns.md:224`).

**Evidence:** `test/cc-host-tool-sources.bats:42-60`, `docs/failure-patterns.md:224`, `X/x1.out`, `X/s2.out`, `X/s3.out`

---

## Claim 28: "`cc-verify.sh` is not walked: it has no `verify_host_tools` call and sources nothing. The `--list` argument lists (`cc-isolated.sh:527-528`) are separate copies and are not compared. The file header states both limits, and that it checks list membership, not whether the check runs before the `source`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-verify.sh and both `--list` lines at cb428e81; "sources nothing" is by grep for `source`, `.` and `eval`.
**Legibility-target:** for-orchestrator-synthesis

`lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true` (`devcontainer-config/cc-isolated.sh:527`). `h-list` (both lists cut) and `h-verify` (a real source added to cc-verify.sh) stay green, `rc=0` (`X/x1.out`). A move of the check is also green: `o-op`, `o-ol` `rc=0`.

**Evidence:** `devcontainer-config/cc-isolated.sh:527-528`, `test/cc-host-tool-sources.bats:11-13`, `X/x1.out`

---

## Claim 29a: "(the launch tests in `test/cc-isolated-functions.bats` cover that for the names in use)", for the launcher

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher's check moved below the source (`ol`) and the source moved out of the `if` (`ul`), run with the suite's ten host-tool tests; cc-gitdir.sh is covered only through the scan that sources it.
**Legibility-target:** for-orchestrator-synthesis

Both mutations fail `not ok 7 launch: a tampered cc-exit-scan.sh is never sourced; --bless still works and clears it` at `line 1158` (`X/x2.out`).

**Evidence:** `test/cc-isolated-functions.bats:1143-1169`, `X/x2.out`

---

## Claim 29b: The same parenthesis, for `cc-push.sh`'s `cc-gitdir.sh`

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:66`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-push's check moved below the source (`op`) and its refusal no longer exiting (`up`), against the filtered tests of both suites; the other 202 tests of `test/cc-isolated-functions.bats` were not run on those mutations, but no line of that file runs cc-push.sh.
**Legibility-target:** for-author

The order is covered, but not by the file named. Under `op` and `up`, `cif rc=0 ok=10 notok=0` and the failure is in the other suite: `not ok 1 installed copy: cc-push checks itself and cc-gitdir.sh before sourcing, and refuses on a change (row 71)` at `test/cc-push.bats` lines 808 and 806 (`X/x2.out`). A grep of `test/cc-isolated-functions.bats` for a run of cc-push finds only a message string at `:1196` (paraphrased — no quote available because the claim covers absence of code; `X/s5.out`). The precise version: "the launch tests in `test/cc-isolated-functions.bats` and the installed-copy test in `test/cc-push.bats` cover that".

**Evidence:** `test/cc-push.bats:797-808`, `X/x2.out`, `X/s5.out`

---

## Claim 30: "`cc-verify.sh`'s comment ("as row 71's Q-147") and row 71 ("because grep cannot cover every bash spelling") already claim no more than the test does ... No guide names the guard."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:68`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two quotes and tracked files outside `docs/reviews`.
**Legibility-target:** for-orchestrator-synthesis

`because grep cannot cover every bash spelling` (`docs/decisions/log.md:94`). `git grep -ln cc-host-tool-sources cb428e81 -- . ':!docs/reviews'` lists only `docs/working/research-2026-11-05-q089-source-guard-narrow.md` (`X/s4.out`). (The test file itself does not name itself.)

**Evidence:** `devcontainer-config/cc-verify.sh:45`, `docs/decisions/log.md:94`, `X/s4.out`

---

## Claim 31: "Prior pruning grep ... S3 (one grammar), S8 (small, one revert), H3 (hermetic), H1 and S10 ..."; S6's observable; S1 proportion

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that each label names a real constraint with that subject; whether H1 bears on option 4 is rationale and was not judged.
**Legibility-target:** for-orchestrator-synthesis

`a change one `git revert` undoes` (S8, `docs/constraints.md:22`), `a claimed benefit with an observable that could come out negative` (S6, `:20`), `Reuse the existing reviewed mechanism` (S3, `:17`), `Security measures are proportionate` (S1, `:15`).

**Evidence:** `docs/constraints.md:3-23`

---

## Claim 32: "The test as it stood at fa059477, appended to a scratch copy, also passes today's code."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a run on config unchanged since; not rerun in this pass.
**Legibility-target:** for-orchestrator-synthesis

`ok 1 every file an entry point sources, directly or through what it sources, is in its verify_host_tools list` (`FC/seed-runs.out`).

**Evidence:** `FC/seed-runs.out`

---

## Claim 33: "Against today's code, in the worktree: `bats test/cc-host-tool-sources.bats`, 7 ok."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:72`
**Type:** Configuration / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at cb428e81; all cases do pass, so only the number is wrong.
**Legibility-target:** for-author

The file has nine cases and all pass: `base                   rc=0 ok=9 notok=0` (`X/x1.out`); `bats --count` gives 9 (`X/s2.out`). cb428e81 added two cases and did not update this line. Precise version: "9 ok".

**Evidence:** `test/cc-host-tool-sources.bats:62-140`, `X/x1.out`, `X/s2.out`

---

## Claim 34: "The seeds' sed edit of the hook's regex was imprecise and made `test/hooks/live-verify-gate.bats` case 26 fail: that case forces the regex, not the check list, so D3 still stands; with the regex edited exactly, that file passes 35 of 35."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook test file; not rerun in this pass.
**Legibility-target:** for-orchestrator-synthesis

`not ok 26 the hook's host_tools regex names exactly host_tool_files, no more` (`FC/seed-s3.out`) and `test/hooks/live-verify-gate.bats rc=0 ok=35 not-ok=0` (`FC/s3p.out`).

**Evidence:** `FC/seed-s3.out`, `FC/s3p.out`

---

## Claim 35: The seeded-run block, "new: ok=5 not-ok=2", "not ok 4 a new helper in the check list ...", and "(Case 4 fails there only because the seed has already made `cc-helper.sh` a host tool.)"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:76-84`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and the case number with the current nine-case file; the block is true of the seven-case file, and the reason given for that case's failure holds.
**Legibility-target:** for-author

With the current T on the same seed: `d3                     rc=1 ok=7 notok=2`, `not ok 1 plain source lines ...`, `not ok 6 a new helper in the check list but not in host_tool_files is named` (`X/x1.out`). So "Case 4" now names a different test, `a helper that names its directory CC_PUSH_DIR is read like cc-push.sh itself`, which passes on that seed. Precise version: rerun the block, or say it is the seven-case file, and write "Case 6".

**Evidence:** `test/cc-host-tool-sources.bats:83-105`, `X/x1.out`

---

## Claim 36: "a new helper that an entry point plainly sources, directly or through a file it sources, must be in that entry point's verify_host_tools list, or it runs unchecked."

**Location:** `test/cc-host-tool-sources.bats:3-5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both paths, direct (case 2) and through the scan (D3, case 5), and the runtime consequence in a scratch config; "plainly" is limited as the header goes on to say.
**Legibility-target:** for-orchestrator-synthesis

`# cc-isolated.sh sources cc-helper.sh unchecked` (N1, `d3`). `tampered helper RAN at source time` (`FC/s3-live.out`).

**Evidence:** `X/x1.out`, `FC/s3-live.out`

---

## Claim 37: "No other test ties the list to the `source` lines; the two names in use today are pinned one by one."

**Location:** `test/cc-host-tool-sources.bats:5-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-exit-scan.sh and cc-gitdir.sh in the launcher's list and cc-gitdir.sh in cc-push's; "no other test" rests on D3 being green in the five files run, plus a repo-wide grep of `*.bats`, not on a full suite run.
**Legibility-target:** for-orchestrator-synthesis

The two names are the two that get sourced; cc-push.sh in its own list is not sourced. Each drop fails an existing test: `dl-scan` at `test/cc-isolated-functions.bats:1153`, `dl-git` at `:1193`, `dp-git` at `test/cc-push.bats:806`, and `dp-self`, the self-entry, at `:817` (`X/x2.out`). Each asserts on a name or on a tamper of that one file, not on the source lines. All `verify_host_tools` references in `*.bats` outside T call the function or compare its two copies (`test/cc-isolated-functions.bats:1082-1231`; paraphrased — no quote available because the claim spans 20 call sites, listed in `X/s2.out`). D3 leaves the suites green (`FC/seed-s3.out`, `FC/s3p.out`, `FC/s3p3-install-host.out`).

**Evidence:** `test/cc-isolated-functions.bats:1134-1139`, `X/x2.out`, `X/s2.out`, `FC/seed-s3.out`

---

## Claim 38: "Q-089's fourth review pass showed that. Forms this one misses include `FOO=1 . f`, `FOO=1 source f`, one-line case arms, a quoted or obfuscated `source`, and `$c f`."

**Location:** `test/cc-host-tool-sources.bats:8-10`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each form as a real appended line in cc-push.sh, sourcing an unlisted host tool, through case 1 at cb428e81.
**Legibility-target:** for-orchestrator-synthesis

`h-foo-dot`, `h-foo-src`, `h-case-oneline`, `h-case-arm`, `h-quoted`, `h-obf` and `h-var` each show `rc=0 ok 1` (`X/x1.out`). `The loop ran a 4th pass` (`docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:94`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:92-97`, `X/x1.out`

---

## Claim 39: "It also does not see a tool run by name, cc-verify.sh (no verify_host_tools call; it sources nothing today), the lists `--list` passes, or whether the check comes before the source or gates it."

**Location:** `test/cc-host-tool-sources.bats:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one mutation for each listed limit, and order and gate at both entry points.
**Legibility-target:** for-orchestrator-synthesis

All `rc=0 ok 1` (`X/x1.out`): `h-byname`, `bash "$CC_PUSH_DIR/cc-exit-scan.sh"`; `h-verify`, a `source` added to cc-verify.sh; `h-list`, both lists cut; `o-ol` and `o-op`, source above the check; `o-ul` and `o-up`, source no longer gated.

**Evidence:** `X/x1.out`, `X/order.py`

---

## Claim 40: "An end-of-line comment or string quoting a check call above the real one is read as the list."

**Location:** `test/cc-host-tool-sources.bats:13-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an end-of-line comment and a single-quoted string; a double-quoted string with escaped inner quotes does not match, so "string" means one holding the call's literal text.
**Legibility-target:** for-orchestrator-synthesis

With the real call lacking cc-exit-scan.sh, which is sourced: `q-eol rc=0`, `q-sstr rc=0`, and `q-dstr-esc rc=1`, `# cc-push.sh sources cc-exit-scan.sh unchecked` (`X/x1.out`).

**Evidence:** `test/cc-host-tool-sources.bats:44-45`, `X/x1.out`

---

## Claim 41: "It is hardening against a refactor, and the runtime checks do not depend on it."

**Location:** `test/cc-host-tool-sources.bats:14-15`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that nothing in `devcontainer-config` names the test; "hardening" is a characterisation.
**Legibility-target:** for-orchestrator-synthesis

The diff touches no file under `devcontainer-config` (`140	0	test/cc-host-tool-sources.bats` is the only non-docs line of `git diff --numstat`, `X/s5.out`), and `git grep cc-host-tool-sources` names only R outside reviews (`X/s4.out`).

**Evidence:** `X/s4.out`, `X/s5.out`

---

## Claim 42: "The spelling rule is cc-verify.sh's own source_lines_ok, read from that file rather than restated here, so there is one grammar to keep."

**Location:** `test/cc-host-tool-sources.bats:17-18`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the spelling rule; `:45` holds a separate regex for the check-list shape, which is not spelling and is not in the shipped code.
**Legibility-target:** for-orchestrator-synthesis

`sed -n '/^source_lines_ok() {/,/^}/p' "$SRC/cc-verify.sh" > "$T/source-lines-ok.sh"` (`test/cc-host-tool-sources.bats:24`), then `source "$T/source-lines-ok.sh"` (`:27`). Renaming the function turns every case red (E14: `no source_lines_ok in cc-verify.sh`).

**Evidence:** `test/cc-host-tool-sources.bats:21-30`, `FC/mut2.out`

---

## Claim 43: "is in its first verify_host_tools call"

**Location:** `test/cc-host-tool-sources.bats:37`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which call is read in each entry point; does not bear on cc-push.sh, where the literal first call is the one read.
**Legibility-target:** for-author

It reads the first call whose directory argument is `$CC_ISOLATED_DIR` or `$CC_PUSH_DIR`: `grep -oE 'verify_host_tools "\$CC_(ISOLATED|PUSH)_DIR"( [a-z-]+\.sh)+' | head -1` (`test/cc-host-tool-sources.bats:45`). In the launcher the first call in the file is `lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true` (`devcontainer-config/cc-isolated.sh:527`), which is skipped, and the one read is `:748`. If `:748` is lost, `:843`'s `cc-push.sh`-only list is read instead (E14). The header's `--list` limit says as much, so a reader is not misled for long. Precise version: "its first verify_host_tools call on its own directory variable".

**Evidence:** `test/cc-host-tool-sources.bats:44-46`, `devcontainer-config/cc-isolated.sh:527`, `devcontainer-config/cc-isolated.sh:748`, `FC/mut2.out`

---

## Claim 44: "Prints the first problem. It works on copies, which it adjusts for the shared grammar: CC_PUSH_DIR, which the grammar does not know, becomes the launcher's variable (so a refused line shows that name)"

**Location:** `test/cc-host-tool-sources.bats:37-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rename across `cc-*.sh` in the copied directory; a sourced file not named `cc-*.sh` is not copied, and so is reported as missing.
**Legibility-target:** for-orchestrator-synthesis

`cp "$SRC"/cc-*.sh "$T/cfg/"` (`test/cc-host-tool-sources.bats:29`), `sed -i 's/CC_PUSH_DIR/CC_ISOLATED_DIR/g' "$f"` (`:48`). Case 7 asserts `*'not a plain source line'*'. "$CC_ISOLATED_DIR/cc-gitdir.sh"'*` (`:113`) on a line written with `$CC_PUSH_DIR`, and passes (N1). Every failure path is `echo` then `return 1` (`:46`, `:51`, `:54`, `:57`, `:58`).

**Evidence:** `test/cc-host-tool-sources.bats:29`, `test/cc-host-tool-sources.bats:42-60`, `X/x1.out`

---

## Claim 45: "each copy gets a final newline, because the grammar's read loop never sees an unterminated last line."

**Location:** `test/cc-host-tool-sources.bats:40-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function at cb428e81 and the removal of the fix; a copy with a final newline gains a harmless blank line.
**Legibility-target:** for-orchestrator-synthesis

`no-newline rc=0 SOURCED=[]`, `newline rc=0 SOURCED=[a.sh]` (`X/x1.out`). Removing `echo >> "$f"` fails case 3 and only case 3: `m-nonl rc=1 ok=8 notok=1`, `not ok 3 a plain source on a last line with no newline is still read`.

**Evidence:** `test/cc-host-tool-sources.bats:47-50`, `devcontainer-config/cc-verify.sh:54`, `X/x1.out`

---

## Claim 46: "Positive control: both entry points reach cc-gitdir.sh (the launcher through the scan)."

**Location:** `test/cc-host-tool-sources.bats:53`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's source lines; the failure branch is exercised for cc-push only.
**Legibility-target:** for-orchestrator-synthesis

`source "$CC_PUSH_DIR/cc-gitdir.sh"` (`devcontainer-config/cc-push.sh:214`) and `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"` (`devcontainer-config/cc-exit-scan.sh:12`). Case 1 passes for both (N1).

**Evidence:** `devcontainer-config/cc-push.sh:214`, `devcontainer-config/cc-exit-scan.sh:12`, `X/x1.out`

---

## Claim 47: @test "plain source lines in the entry points stay inside their verify_host_tools lists"

**Location:** `test/cc-host-tool-sources.bats:62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both entry points on the real tree; `cc-verify.sh` is not an entry point here, as the header says.
**Legibility-target:** for-orchestrator-synthesis

`run check_entry "$T/cfg" cc-isolated.sh` and `run check_entry "$T/cfg" cc-push.sh` (`:63`, `:65`). It goes red under D1, D2 and D3 (N1).

**Evidence:** `test/cc-host-tool-sources.bats:62-67`, `X/x1.out`

---

## Claim 48: @test "a plain source of a host tool outside the entry point's list is named"

**Location:** `test/cc-host-tool-sources.bats:69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-exit-scan.sh in cc-push.sh, a real host tool outside that list.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$output" == *"cc-push.sh sources cc-exit-scan.sh unchecked"* ]]` (`:73`). `ok 2` (N1).

**Evidence:** `test/cc-host-tool-sources.bats:69-74`, `X/x1.out`

---

## Claim 49: @test "a plain source on a last line with no newline is still read" (new)

**Location:** `test/cc-host-tool-sources.bats:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an unterminated line in the entry point; the helper-file path uses the same loop in `check_entry` but has no case of its own.
**Legibility-target:** for-orchestrator-synthesis

`printf 'source "$CC_PUSH_DIR/cc-exit-scan.sh"' >> "$T/cfg/cc-push.sh"` (`:77`) has no newline, and the assertion names cc-exit-scan.sh (`:80`). The case can fail: without the newline fix it is `not ok 3` (N1, `m-nonl`).

**Evidence:** `test/cc-host-tool-sources.bats:76-81`, `X/x1.out`

---

## Claim 50: @test "a helper that names its directory CC_PUSH_DIR is read like cc-push.sh itself" (new)

**Location:** `test/cc-host-tool-sources.bats:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a helper reached from cc-push.sh, one level down; the assertion shows the helper passed the grammar, not that its own `source` target was followed, since cc-gitdir.sh is already reached from cc-push.sh.
**Legibility-target:** for-orchestrator-synthesis

`echo 'source "$CC_PUSH_DIR/cc-gitdir.sh"' > "$T/cfg/cc-helper.sh"` (`:84`), and the output is `cc-push.sh sources cc-helper.sh unchecked` (`:88`), not a refusal. The case can fail: with the rename on cc-push.sh only it is `not ok 4` (N1, `m-rename1`). The grammar reads the helper's line, so "is read" holds.

**Evidence:** `test/cc-host-tool-sources.bats:83-89`, `X/x1.out`

---

## Claim 51: @test "a name dropped from the launcher's list is named, through the file that sources it"

**Location:** `test/cc-host-tool-sources.bats:91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-gitdir.sh, reached through the scan; the output does not name the scan, so "through" describes the path, not the message.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$output" == *"cc-isolated.sh sources cc-gitdir.sh unchecked"* ]]` (`:95`). The launcher has no direct `source` of cc-gitdir.sh (`devcontainer-config/cc-isolated.sh:750` sources the scan). `ok 5` (N1).

**Evidence:** `test/cc-host-tool-sources.bats:91-96`, `X/x1.out`

---

## Claim 52: @test "a new helper in the check list but not in host_tool_files is named"

**Location:** `test/cc-host-tool-sources.bats:98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the path with a helper listed at cc-push; it is the one case that a seed making the helper a host tool turns red (Claim 35).
**Legibility-target:** for-orchestrator-synthesis

`[[ "$output" == *"cc-helper.sh is not a host tool"* ]]` (`:104`). `ok 6` (N1).

**Evidence:** `test/cc-host-tool-sources.bats:98-105`, `X/x1.out`

---

## Claim 53: @test "a dot source, or a source from any other directory, is refused as not plain"

**Location:** `test/cc-host-tool-sources.bats:107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The test asserts one other directory, `$(config_dir)`; "any" rests on the `src` regex, read but not exercised case by case.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$output" == *'not a plain source line'*'$(config_dir)/cc-gitdir.sh'* ]]` (`:118`). The grammar's `src` allows only `$CC_ISOLATED_DIR` or the file's own `dirname` and a name without `/`: `([A-Za-z0-9._-]+)` (`devcontainer-config/cc-verify.sh:49`). `ok 7` (N1).

**Evidence:** `test/cc-host-tool-sources.bats:107-119`, `devcontainer-config/cc-verify.sh:49`, `X/x1.out`

---

## Claim 54: @test "an entry point with no check call, or that no longer reaches cc-gitdir.sh, fails rather than passes empty"

**Location:** `test/cc-host-tool-sources.bats:121`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Asserts cc-push only; the launcher also fails on a lost first call, but with another message (E14).
**Legibility-target:** for-orchestrator-synthesis

`[[ "$output" == *"no verify_host_tools call in cc-push.sh"* ]]` (`:127`) and `[[ "$output" == *"parse missed cc-gitdir.sh for cc-push.sh"* ]]` (`:132`). `ok 8` (N1).

**Evidence:** `test/cc-host-tool-sources.bats:121-133`, `FC/mut2.out`, `X/x1.out`

---

## Claim 55: @test "a missing sourced file fails, naming it"

**Location:** `test/cc-host-tool-sources.bats:135`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file being named; the message is prefixed `not a plain source line:`, which is not what happened, but no claim says otherwise.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$output" == *"cc-gitdir.sh is missing"* ]]` (`:139`), raised by `[ -f "$f" ] || { echo "$f is missing"; return 1; }` (`devcontainer-config/cc-verify.sh:53`). `ok 9` (N1).

**Evidence:** `test/cc-host-tool-sources.bats:135-140`, `devcontainer-config/cc-verify.sh:53`, `X/x1.out`

---

## Claim 56: "A seeded new helper left today's suite green." (8880c925, history, not editable)

**Location:** `git log -1 8880c925`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the run behind the sentence; cb59c2bb's message and R:21 carry the correction, so nothing is owed here.
**Legibility-target:** for-orchestrator-synthesis

The run was the two launcher suites, not the whole suite: `existing: ok=260 not-ok=0` (`FC/seed-s3.out`). R:29 says `The full suite was not run on the seed.`

**Evidence:** `FC/seed-s3.out`, `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`

---

## Claim 57: "The spelling rule is read from cc-verify.sh's source_lines_ok, not restated." and "reach difference recorded in the research doc." (8880c925)

**Location:** `git log -1 8880c925`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against T and R as they stand.
**Legibility-target:** for-orchestrator-synthesis

See Claims 20 and 42. `sed -n '/^source_lines_ok() {/,/^}/p' "$SRC/cc-verify.sh"` (`test/cc-host-tool-sources.bats:24`).

**Evidence:** `test/cc-host-tool-sources.bats:24`, `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51-58`

---

## Claim 58: "Pass 1 fact-check: 2 Incorrect and 8 Mostly accurate, all prose. The motive text names which drift is caught and how, the header says unchecked and adds the ordering limit, and the seeds are D1 to D3, apart from constraint S3. The commit message of 8880c925 says "today's suite"; that run was the two launcher suites, and the research doc now says so." (cb59c2bb)

**Location:** `git log -1 cb59c2bb`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each stated change in cb59c2bb's diff and the prior report's summary line; does not repeat the prior report's verdicts.
**Legibility-target:** for-orchestrator-synthesis

`**Summary:** 25 verified, 8 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable` (`docs/reviews/code-fact-check-report-q089-source-guard.md:10`). The header diff adds `# that entry point's verify_host_tools list, or it runs unchecked.` and `# before the source.` (`X/s3.out`). R:21 has `(D1 to D3, so as not to read as constraints)` and `against `test/cc-isolated-functions.bats` and `test/cc-push.bats``.

**Evidence:** `docs/reviews/code-fact-check-report-q089-source-guard.md:10`, `docs/working/research-2026-11-05-q089-source-guard-narrow.md:21`, `X/s3.out`

---

## Claim 59: "Review pass 1: the grammar's read loop misses an unterminated last line, and the rename covered only cc-push.sh. check_entry now adjusts every copy, with a seeded case for each. Header and research doc state the remaining limits. ... Three findings declined or deferred, rows in the override log. The shipped source_lines_ok gap is a host-tool follow-up." (cb428e81)

**Location:** `git log -1 cb428e81`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two fixes, their cases, and the three override rows; "research doc" stating the limits does not mean it is current everywhere (Claims 19, 33, 35).
**Legibility-target:** for-orchestrator-synthesis

`m-nonl` and `m-rename1` each fail one seeded case (`X/x1.out`). The diff adds three rows to `docs/reviews/override-log.md`, one `Won't-Fix` and two `Defer`, the last of which is `Shipped source_lines_ok misses an unterminated last line` (`X/s3.out`).

**Evidence:** `docs/reviews/override-log.md:896`, `X/x1.out`, `X/s3.out`

---

## Claim 60: "Size: about 130 code lines against main." (cb428e81)

**Location:** `git log -1 cb428e81`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count by pr-prep step 1a's rule, against db31db8b; the cap is about 400, so no gate turns on the difference.
**Legibility-target:** for-author

`git diff --numstat db31db8b...cb428e81 -- ':(top)' ':(top,exclude)docs/'` gives `140	0	test/cc-host-tool-sources.bats` (`X/s5.out`), and the rule in `workflows/pr-prep.md:86-92` counts added and removed lines outside `docs/`. So the figure by that rule is 140. No count gives 130: the file is 117 at 8880c925, 119 at cb59c2bb, 140 at cb428e81, and 102 without comments and blanks (`X/s4.out`). cb428e81's message is editable; 8880c925's is the one that is not.

**Evidence:** `workflows/pr-prep.md:86-92`, `X/s4.out`, `X/s5.out`

---

## Claims Requiring Attention

### Stale
- **Claim 19** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`): says the test renames in its copy of `cc-push.sh`; since cb428e81 it renames in every copy.
- **Claim 33** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:72`): says 7 ok; the file has 9 cases, all passing.
- **Claim 35** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:76-84`): the block is from the seven-case file. Now `ok=7 not-ok=2`, and "Case 4" should be case 6; today's case 4 is a different test, which passes on that seed.

### Mostly Accurate
- **Claim 9** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`): the cc-push drop fails at `test/cc-push.bats:806`, not `:807`, and the cc-exit-scan.sh drop fails at `cc-isolated-functions.bats:1153`, which is not cited.
- **Claim 18** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`): "it is shorter" holds only without `setup` (about 24 against 27 code lines; 33 with it).
- **Claim 29b** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:66`): cc-push's order and gate are covered by `test/cc-push.bats:797-808`, not by the launch tests named.
- **Claim 43** (`test/cc-host-tool-sources.bats:37`): "first verify_host_tools call" is the first on `$CC_*_DIR`; in the launcher that is `:748`, not `:527`.
- **Claim 56** (8880c925, not editable): "today's suite" was two suites; already corrected by cb59c2bb and R.
- **Claim 60** (cb428e81 message): "about 130" is 140 by pr-prep step 1a.

Claim 18 aside, these are one-phrase corrections.

### Incorrect
None.

### Unverifiable
None.

## Goal-Alignment Note

- Success criterion (restated): a report at `docs/reviews/code-fact-check-report-q089-source-guard-r1.md` with `Commit: cb428e81`, each claim tagged with Legibility-target, ending in a Goal-Alignment Note; commit nothing, edit nothing else.
- Answered: yes. Every item in the dispatch was checked at cb428e81: the bats header and `check_entry` comment by mutation (Claims 36 to 46), each `@test` name (47 to 55, the two new cases with a mutation showing each can fail), and the research doc's table, reach lists, `)` sentence, 17 count, line citations and launch-test sentence (5 to 9, 20, 22, 27, 29a, 29b).
- Is the branch clean? The test code is. All nine cases pass, every header limit holds under execution, and no comment in T misleads beyond Claim 43's wording. The prose is not quite: the three Stale items all trace to cb428e81, which changed the test and left R's matching lines behind. None of the 6 Mostly accurate or 3 Stale items changes the land decision, and D3 still stands with the current file.
- Prior-pass fixes: cb59c2bb's and cb428e81's fixes were rechecked rather than assumed. Those fixes themselves hold, including "the two names in use today are pinned one by one", which replaced an Incorrect. The sentence added for the prior ordering note (Claim 29) is the one new imprecision they introduced.
- Out of scope: whether to land, test quality beyond what claims assert, and review reports' content. The full `bats` suite was not run, per the dispatch; N2 ran only the host-tool tests of the two launcher suites, ten and one, on each mutation.
- Escalate: Claims 19, 33 and 35 are fixes for R. For the orchestrator: the follow-up for the shipped `source_lines_ok` gap exists only as a Defer row at `docs/reviews/override-log.md:896` (Claim 24).
- Decisions I made: execution logs stay in `X`, not `docs/reviews/execution-logs/`, because the dispatch allowed one file. No entry went to `docs/reviews/hallucination-patterns.md`, for the same reason and because nothing here is a fabrication. Claim 29b is Mostly accurate rather than Incorrect because the claim omits a test file rather than naming a mechanism the code refutes: the order is tested. Claims 33 and 35 are Stale because each number was true when written. Claim numbering 29a/29b counts as two in the total; Claim 31 sits after 30 though its line is earlier, which departs from the skill's strict line order to keep the constraint labels together.
