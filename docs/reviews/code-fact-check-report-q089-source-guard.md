Commit: 8880c925

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `wt-2026-11-05-q089-source-guard-narrow`, branch `test/q089-source-guard-narrow`)
**Scope:** branch diff `git diff db31db8b..HEAD` (`test/cc-host-tool-sources.bats`, `docs/working/research-2026-11-05-q089-source-guard-narrow.md`) plus the commit message of 8880c925
**Checked:** 2026-11-05
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 35
**Summary:** 25 verified, 8 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Claim 19b belongs to the class the log records as "a specific measured value quoted from an artifact set that does not contain it"; see the Goal-Alignment Note.

Shorthand: `R` is `docs/working/research-2026-11-05-q089-source-guard-narrow.md`, `T` is `test/cc-host-tool-sources.bats`, and `FC` is `/tmp/claude-1000/-workspace/47403b7b-5fcb-4e13-8807-c539081df064/scratchpad/2026-11-05-q089-source-guard-narrow/fc`.

## Execution log

Every run was in a scratch copy under `FC` (cwd `FC` unless stated), except E7, which only read the worktree. Captured output is in `FC`, because the dispatch limited this pass to this one file. Times are UTC, 2026-11-06.

| Id | Command | Exit | Time | Output |
|---|---|---|---|---|
| E1 | `timeout 560 bash ./seed-runs.sh` (copy of the author's script, B pointed at `FC/seeds`) | 0 | 03:04:09 | `FC/seed-runs.out`, `FC/seeds/{base,s1,s2}/{existing,new}.out` |
| E2 | `timeout 560 bash ./seed-s3.sh` (same) | 0 | 03:06:15 | `FC/seed-s3.out`, `FC/seeds/s3/{existing,new}.out` |
| E3 | `timeout 60 bash ./forms.sh` (same) | 0 | 03:05:28 | `FC/forms.out` |
| E4 | `timeout 30 bash ./forms2.sh` (forms.sh's method, nine further spellings) | 0 | 03:05:50 | `FC/forms2.out` |
| E5 | `timeout 200 bash ./mut.sh` (one mutated copy of the config per line, then bats case 1) | 0 | 03:06:22 | `FC/mut.out`, `FC/mut/*/out.txt` |
| E6 | `timeout 30 bats pf.bats` (prints shell options inside a bats test) | 0 | 03:06:22 | `FC/pf.out` |
| E7 | `LC_ALL=C timeout 60 bats test/cc-host-tool-sources.bats`, cwd the worktree | 0 | 03:06:22 | `FC/wt-run.out` |
| E8 | `LC_ALL=C timeout 300 bats test/cc-push.bats`, cwd `FC/s1fix` (S1's tree, with that one fixture also copying `cc-exit-scan.sh`) | 0 | 03:06:57 | `FC/s1fix.out` |
| E9 | `timeout 60 bash ./s3-live.sh` (S3's config, hashed manifest, tampered helper, launcher sourced) | 0 | 03:07:23 | `FC/s3-live.out` |
| E10 | `timeout 530 bash ./s3p.sh` (S3 with the hook regex edited exactly, then three wider files) | 0 | 03:07:56 | `FC/s3p.out`, `FC/s3p-*.out` |
| E11 | `bats test/cc-verify.bats` and `bats test/install-host.bats`, cwd `FC/seeds/base` | 0; 1 | 03:11:15 | `FC/base-cc-verify.out`, `FC/base-install-host.out` |
| E12 | `LC_ALL=C timeout 90 bats test/cc-verify.bats`, cwd `FC/s3p`, after adding `cc-helper.sh` to that fixture | 0 | 03:14:29 | `FC/s3p2-cc-verify.out` |
| E13 | `LC_ALL=C timeout 480 bats test/install-host.bats`, cwd `FC/s3p`, after adding `cc-helper.sh` to that fixture | 1 | 03:17:48 | `FC/s3p3-install-host.out` |
| E14 | `timeout 120 bash ./mut2.sh` (launcher's first call renamed; `source_lines_ok` renamed) | 0 | 03:22:13 | `FC/mut2.out` |

No process from these runs was left running at the end (`ps` filter on `FC` printed 0).

---

## Claim 1: "The test keeps fa059477's positive control (both entry points must reach `cc-gitdir.sh`), and a missing check call fails, so neither case passes empty."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the positive control's text, FP-082's description, and a failure on a lost call for both entry points; does not establish that the launcher reports it as "no verify_host_tools call", since it has a second call and reports something else.
**Legibility-target:** for-orchestrator-synthesis

The control is the same line as at fa059477 (`fa059477:test/cc-isolated-functions.bats`): `# Positive control: both entry points reach cc-gitdir.sh (the launcher through the scan).` at `test/cc-host-tool-sources.bats:45`. FP-082's entry reads `symptom:literal-adjacency-grep-broken-by-inserted-argument cause:vacuous-assertion` (`docs/failure-patterns.md:224`). Case 6 passes for cc-push (E7). With the launcher's first call renamed, the test still fails, but the regex picks up the later `cc-push.sh` warning call, so the output is `cc-isolated.sh sources cc-exit-scan.sh unchecked` (E14, `FC/mut2.out`).

**Evidence:** `test/cc-host-tool-sources.bats:39-46`, `devcontainer-config/cc-isolated.sh:748`, `devcontainer-config/cc-isolated.sh:843`, `FC/mut2.out`, `FC/wt-run.out`

---

## Claim 2: "FP-175 (`echo | grep -q` SIGPIPE under pipefail): the source of R2's 1-in-25 flake. The new file does not source the launcher into the test shell, so it has no pipefail, and it still uses a here-string."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:13`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pipefail being off in a bats test shell here and the here-string at `:50`; does not establish that the child shell at `:47` lacks it (it has it, and only echoes there), and FP-175 itself is a later incident with the same mechanism, not the record of R2's flake.
**Legibility-target:** for-orchestrator-synthesis

The probe printed `pipefail off` inside a bats test and `pipefail on` in the `bash -c 'source "$1"...'` child (E6, `FC/pf.out`). The launcher is only sourced in that child: `hosts="$(bash -c 'source "$1"; host_tool_files' _ "$dir/cc-isolated.sh")"` (`test/cc-host-tool-sources.bats:47`). The here-string is `grep -qx -- "$f" <<< "$hosts"` (`:50`). The rubric's R2 row records `host_tool_files \| grep -q` SIGPIPE, 1/25 runs (`docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:20`). FP-175 is dated 2026-10-29 and refers to the health check (`docs/failure-patterns.md:317`). The one remaining pipe (`:39-40`) ends in `|| true`.

**Evidence:** `test/cc-host-tool-sources.bats:39-50`, `docs/failure-patterns.md:317`, `FC/pf.out`

---

## Claim 3: "scope the claim honestly: it guards plain spellings against accidental drift and is not complete for bash." and "would be forced into `host_tool_files` by tests, but the launcher would still source it unchecked."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:17`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both quotes and the summary of the convergence diagnosis as text in the rubric; does not establish that the rubric's own claims about earlier passes were right.
**Legibility-target:** for-orchestrator-synthesis

Both quotes are verbatim: `its first job is to scope the claim honestly: it guards plain spellings against accidental drift and is not complete for bash.` (rubric `:97`) and `would be forced into `host_tool_files` by tests, but the launcher would still source it unchecked.` (rubric `:35`). The doc's form list matches `:94`, and its summary matches `every pass converged on the runtime code. The only thing that did not converge was a test making a completeness claim that grep cannot meet.` (rubric `:103`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:35`, `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:92-104`

---

## Claim 4: "baseline: 260 ok, 0 failed, `LC_ALL=C`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:21`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `test/cc-isolated-functions.bats` plus `test/cc-push.bats` in an unmodified scratch copy; does not establish the rest of the suite.
**Legibility-target:** for-orchestrator-synthesis

E1 printed `--- base existing: ok=260 not-ok=0` and `--- base new: ok=7 not-ok=0`.

**Evidence:** `FC/seed-runs.out`, `FC/seeds/base/existing.out`

---

## Claim 5: "1 fails, `test/cc-push.bats:803`, only because that fixture lacks the file: the failure does not mention the list" (S1)

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers S1 against the two named files and the cause of that one failure; does not establish the seed's result in other test files, and the table leaves out that S1 also turns the new file's cases 4 and 6 red.
**Legibility-target:** for-orchestrator-synthesis

E1 reproduced one failure, `not ok 260 installed copy: cc-push checks itself and cc-gitdir.sh before sourcing, and refuses on a change (row 71)`, at `# (in test file test/cc-push.bats, line 803)`, on `[ "$status" -eq 0 ]`. No output mentions a check list. To test "only because", E8 kept the S1 seed and changed only that fixture's `cp` to include `cc-exit-scan.sh`: `test/cc-push.bats` then gave `ok=48 not-ok=0`, so with the file present nothing in that suite notices the unchecked source. The new test's message `cc-push.sh sources cc-exit-scan.sh unchecked` reproduced as well.

**Evidence:** `test/cc-push.bats:797-803`, `FC/seed-runs.out`, `FC/seeds/s1/existing.out`, `FC/s1fix.out`

---

## Claim 6: "1 fails, the refusal test that names that tool" (S2)

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers S2 against the two named files; the naming is in the failing assertion, not the test title, which speaks of a boundary change.
**Legibility-target:** for-orchestrator-synthesis

E1 reproduced `not ok 90 launch: a host-tool refusal still shows a boundary change made alongside it, and bless prints both`, at line 1193: `[[ "$output" == *"cc-exit-scan.sh changed"*"cc-gitdir.sh changed"* ]]`. The new test printed `cc-isolated.sh sources cc-gitdir.sh unchecked`.

**Evidence:** `test/cc-isolated-functions.bats:1171-1193`, `FC/seeds/s2/existing.out`, `FC/seed-runs.out`

---

## Claim 7: "**260 ok, 0 failed**" and "fails: `cc-isolated.sh sources cc-helper.sh unchecked`" (S3, with the output block at `:75-81`)

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers S3 against the two named files and the new test; does not establish the wider suite (Claims 9 and 33).
**Legibility-target:** for-orchestrator-synthesis

E2 reproduced the block exactly: `existing: ok=260 not-ok=0`, `new: ok=5 not-ok=2`, `not ok 1 plain source lines in the entry points stay inside their verify_host_tools lists`, `# cc-isolated.sh sources cc-helper.sh unchecked`, `not ok 4 a new helper in the check list but not in host_tool_files is named`. The seeds all applied: the diff of base against s3 shows the extra `source`, the `host_tool_files` line, the PAYLOAD entry and the hook edit (paraphrased — no quote available because the diff spans five files; it was read in full).

**Evidence:** `FC/seed-s3.out`, `FC/seeds/s3/new.out`, `FC/seeds/s3/existing.out`

---

## Claim 8: "The two names in use today are pinned by other tests, by accident of those tests' fixtures"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers why S1 and S2 fail today; does not touch the sentence's other half, "a new helper is not", which Claim 7 supports, or the decision to land.
**Legibility-target:** for-author

Only S1 is a fixture accident (Claim 5), and S1 is a name added outside a list, not a pinned name. The names in the lists are pinned on purpose. The test that catches S2 sets up the change and asserts on it directly:

```bash
# test/cc-isolated-functions.bats:1189-1193
  # Every changed tool is named, cc-push included, before the bless is suggested.
  echo '# y' >> "$d/cc-gitdir.sh"; echo '# y' >> "$d/cc-push.sh"; echo '# y' >> "$d/cc-exit-scan.sh"
  run bash "$d/cc-isolated.sh" "$ws"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cc-exit-scan.sh changed"*"cc-gitdir.sh changed"* ]]
```

(excerpt ends :1193; enclosing test continues to :1202 — read). The same holds for cc-push's list: `[[ "$output" == *"ERROR: cc-push refuses to run:"*"cc-gitdir.sh changed since the last bless"* ]]` (`test/cc-push.bats:807`). A precise version: S1 is caught only by a fixture's missing file; a name dropped from a list is caught by tests that assert that name; a new helper has neither.

**Evidence:** `test/cc-isolated-functions.bats:1171-1202`, `test/cc-push.bats:797-809`, `FC/s1fix.out`, `FC/seeds/s2/existing.out`

---

## Claim 9: "After every step the suite forces" (with the row's "added to `host_tool_files`, PAYLOAD, the hook's regex, the fixtures and the pinned lists")

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the forced steps in the five test files that name a host tool; does not establish the other test files, which were not run on the seed.
**Legibility-target:** for-author

The seed did not take every forced step: it edited fixtures in `test/cc-isolated-functions.bats` only, and the doc ran only that file and `test/cc-push.bats`. Run on S3, `test/cc-verify.bats` case 10 fails at line 204 and `test/install-host.bats` fails widely on `ERROR: payload source(s) not found in commit ... devcontainer-config/cc-helper.sh` (E10). Both are fixtures again: `cp "$SRC/cc-isolated.sh" "$SRC/cc-exit-scan.sh" "$SRC/cc-gitdir.sh" "$T/cfg/"` (`test/cc-verify.bats:202`) and the file list at `test/install-host.bats:104`. With `cc-helper.sh` added to each, cc-verify gives `ok=12 notok=0` (E12) and install-host gives `ok=104 notok=1` (E13), the same as base (E11). The one failure, T9, needs a `.git` the scratch copy lacks. So the conclusion holds. The precise version: two more fixture edits are forced, and neither mentions the check list.

**Evidence:** `test/cc-verify.bats:197-204`, `test/install-host.bats:104`, `FC/s3p.out`, `FC/s3p2-cc-verify.out`, `FC/s3p3-install-host.out`, `FC/base-cc-verify.out`, `FC/base-install-host.out`

---

## Claim 10: "the installed launcher would source a file with no hash check, and nothing says so."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher's top-level check and `source` with a tampered helper; does not exercise `--list` or a bless, though `--list` passes the same two names (`cc-isolated.sh:527`).
**Legibility-target:** for-orchestrator-synthesis

E9 hashed S3's config, appended a `touch` to `cc-helper.sh` and sourced the launcher. Output: `HOST_TOOLS_ERR=[]` and `tampered helper RAN at source time`. The control, tampering `cc-gitdir.sh` instead, printed `changed since the last bless` and `control: tampered gitdir refused, did not run`.

**Evidence:** `devcontainer-config/cc-isolated.sh:748-750`, `FC/s3-live.out`

---

## Claim 11: Row 71 quotes: "Each entry point checks the host tools it executes before sourcing them", "because grep cannot cover every bash spelling", and row 71 "places this under non-targeted tampering, as defence in depth"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`, `:31`, `:67`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted text of row 71 and of `cc-verify.sh`'s comment; does not establish that the new test enforces "before" (Claim 29).
**Legibility-target:** for-orchestrator-synthesis

Row 71 has `Each entry point checks the host tools it executes before sourcing them`, `because grep cannot cover every bash spelling`, and `Those are row 45's existing threat model: non-targeted host tampering, defence in depth.` (`docs/decisions/log.md:94`). `cc-verify.sh` reads `are not seen (as row 71's` / `# Q-147)` across a line break (`devcontainer-config/cc-verify.sh:45-46`).

**Evidence:** `docs/decisions/log.md:94`, `devcontainer-config/cc-verify.sh:44-46`

---

## Claim 12: "The sourced set has not changed since Q-089, and `cc-verify.sh` joined the host tools without sourcing anything."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:31`
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers line-start `source`/`.` lines in the `cc-*.sh` files at fa059477, db31db8b and HEAD, and cc-verify's joining commit; forms the grep cannot see are outside it, and fa059477 is not an ancestor of main, so it stands in for Q-089's end state.
**Legibility-target:** for-orchestrator-synthesis

The same three lines exist at all three commits, differing only in line number: `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"` in the scan, `source "$CC_ISOLATED_DIR/cc-exit-scan.sh"` and `source "$CC_PUSH_DIR/cc-gitdir.sh"`. d5fa26c1 added `echo "cc-verify.sh"` to `host_tool_files`, and `cc-verify.sh` at that commit has 0 such lines (paraphrased — no quote available because the claim covers absence of code; the grep returned a count of 0).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:12`, `devcontainer-config/cc-isolated.sh:750`, `devcontainer-config/cc-push.sh:214`, `devcontainer-config/cc-isolated.sh:212-217`

---

## Claim 13: "no matches found for [source, host tool, bash parse] beyond decision 017's "grep table in the bats suite", which was pruned because a bats test cannot lint another repo"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:35`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers decision 017's quote and reason, and that no pruned candidate on this subject turned up; does not reproduce the author's grep, whose exact pattern is not recorded, and the word "source" alone does hit an unrelated use at `docs/decisions/036-cc-isolated-repo-split.md:90`.
**Legibility-target:** for-orchestrator-synthesis

Decision 017 reads `[1 grep table in the bats suite]: H2 is structural — a bats test in *this* repo cannot lint another repo` (`docs/decisions/017-polyglot-test-hermeticity.md:125`; excerpt ends mid-paragraph, the rest lists other candidates — read).

**Evidence:** `docs/decisions/017-polyglot-test-hermeticity.md:125`, `docs/decisions/036-cc-isolated-repo-split.md:90`

---

## Claim 14: "`cc-verify.sh` shipped the same grammar after this test was split off (its comment cites Q-147)."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of events, the citation and how far the two grammars match; does not assess which is better.
**Legibility-target:** for-author

The order and the citation hold: d5fa26c1 (2026-10-20) added `source_lines_ok`, after the 2026-10-14 split, and the comment cites Q-147 (`devcontainer-config/cc-verify.sh:45-46`). "The same grammar" is loose: it enforces the same rule by different regexes, and the doc's next lines list where they differ. The precise version: "shipped a grammar for the same rule".

**Evidence:** `devcontainer-config/cc-verify.sh:47-65`, `fa059477:test/cc-isolated-functions.bats:1038-1075`

---

## Claim 15a: "Seen by fa059477 only: `FOO=1 source f`, a one-line case arm `a) source f ;;`, `"source" f`" and the "Seen by both", "Seen by neither" and `\. f` entries, "from running both grammars over 19 spellings"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these 19 spellings, with forms.sh's regexes confirmed identical to fa059477's `canon`, `srcword` and `dotcmd`; does not establish reach beyond them (Claim 16).
**Legibility-target:** for-orchestrator-synthesis

E3 printed 19 rows that sort exactly into the doc's sets: `\. "$D/h.sh"  miss  seen`; `FOO=1 source "$D/h.sh"  seen  miss`; `a) source "$D/h.sh" ;;  seen  miss`; `"source" "$D/h.sh"  seen  miss`; `FOO=1 . "$D/h.sh"  miss  miss`, and so on. Ten rows are `seen seen`, five are `miss miss`.

**Evidence:** `FC/forms.out`, `FC/forms.sh`

---

## Claim 15b: "Seen by `source_lines_ok` only: ... `eval` with no `source` on the line." (attributed to the 19-spelling run)

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:54`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `eval "$x"` and `eval $x`; the fact is right, only its stated source is not.
**Legibility-target:** for-author

The claim is true: E4 printed `eval "$x"  miss  seen` and `eval $x  miss  seen`. But no such spelling is among the 19. The only eval line in `forms.sh` is `eval "source $x"`, which has `source` on the line and lands in "seen by both". The bullets hold 20 entries for 19 runs. The precise version: "20 spellings", with the form added to the script, or the bullet marked as read from the regex at `devcontainer-config/cc-verify.sh:56`.

**Evidence:** `FC/forms.sh`, `FC/forms.out`, `FC/forms2.out`, `devcontainer-config/cc-verify.sh:56`

---

## Claim 16: "Giving up three forms for one grammar is acceptable for a guard that claims only plain spellings."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of forms lost; "acceptable" is a design judgment and is not verdicted.
**Legibility-target:** for-author

Three is the count within the sample, not the size of what is lost. fa059477's `srcword` matched `source` as a word anywhere on a line, and `source_lines_ok` needs it in a command position. E4 found more forms seen by the old grammar only: `trap 'source "$D/h.sh"' EXIT`, `bash -c 'source "$D/h.sh"'`, `timeout 5 source "$D/h.sh"`, `env FOO=1 source "$D/h.sh"`, `foo && FOO=1 source "$D/h.sh"`, `exec . "$D/h.sh"`, each printing `seen  miss`. `trap` does load the file in the same shell, and E5's `m-trap` passes the new test. The precise version: "giving up every `source` that is not in a recognised command position, three of the 19 sampled".

**Evidence:** `FC/forms2.out`, `FC/mut.out`, `fa059477:test/cc-isolated-functions.bats:1038-1075`, `devcontainer-config/cc-verify.sh:56`

---

## Claim 17: "the 3325-line `test/cc-isolated-functions.bats`"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:62`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count at HEAD only.
**Legibility-target:** for-orchestrator-synthesis

`wc -l` printed `3325 test/cc-isolated-functions.bats`.

**Evidence:** `test/cc-isolated-functions.bats:1-3325`

---

## Claim 18: "Comment lines are dropped before reading the check list, so a comment quoting a call cannot stand in for it."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:63`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers full-line comments, end-of-line comments and one string form on cc-push.sh; does not cover other literal text.
**Legibility-target:** for-author

Only whole-line comments are dropped: `args="$(grep -vE '^[[:space:]]*#' "$dir/$entry" \` (`test/cc-host-tool-sources.bats:39`; excerpt ends mid-pipeline, continues to :40 — read). With cc-push's real call disabled, a full-line comment fails the test (`c-full  rc=1`), but an end-of-line comment passes it (`c-trail  rc=0`, using `true # verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh`), as does a quoted string (`c-strplain  rc=0`) (E5). The precise version: "a full-line comment quoting a call cannot stand in for it".

**Evidence:** `test/cc-host-tool-sources.bats:39-41`, `FC/mut.out`

---

## Claim 19a: "A permanent seeded-drift case per failure path (H2)"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:64`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failure paths in `check_entry` and `setup`; does not establish that each case kills every mutant of its path.
**Legibility-target:** for-author

All five paths in `check_entry` have a case: `:41` (case 6), `:43` (cases 5 and 7), `:46` (case 6), `:49` (cases 2 and 3), `:50` (case 4). The sixth path has none: `[ -s "$T/source-lines-ok.sh" ] || { echo "no source_lines_ok in cc-verify.sh"; return 1; }` (`test/cc-host-tool-sources.bats:22`). It does work: with the function renamed, every case fails naming that line (E14). The precise version: "per failure path in `check_entry`".

**Evidence:** `test/cc-host-tool-sources.bats:18-27`, `test/cc-host-tool-sources.bats:37-52`, `FC/mut2.out`

---

## Claim 19b: "the repo's largest failure family is assertions that could not fail."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:64`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the `cause:` tags in `docs/failure-patterns.md`, the repo's record of root-caused bugs; another grouping could rank differently, but no doc states one (a search for "largest" with family, cause or class found only this line).
**Legibility-target:** for-author

The library defines the family as `` `vacuous-assertion` | the assertion could not fail `` (`docs/failure-patterns.md:62`). Over its 169 entries the tally is 25 `cause:fail-open`, 17 `cause:vacuous-assertion`, 17 `cause:guard-misses-subject`, 14 `cause:boundary-too-wide` (paraphrased — no quote available because this is a count over 169 lines, from `rg '^- \*\*FP-' | rg -o 'cause:[a-z-]+' | sort | uniq -c`). So it ties for second. The precise version: "a large failure family" or "the second-largest". The design choice does not depend on the ranking.

**Evidence:** `docs/failure-patterns.md:62`, `docs/failure-patterns.md:224`

---

## Claim 20: "`cc-verify.sh` is not walked: it has no `verify_host_tools` call and sources nothing. The `--list` argument lists (`cc-isolated.sh:527-528`) are separate copies and are not compared. The file header states both limits"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both limits by mutation; see Claim 26 for the header.
**Legibility-target:** for-orchestrator-synthesis

The lists are `lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true` and `perr="$(verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh)" || true` (`devcontainer-config/cc-isolated.sh:527-528`). Removing `cc-gitdir.sh` from both (`m-list`) and adding a `source` to `cc-verify.sh` (`m-verify`) each leave case 1 at `rc=0` (E5).

**Evidence:** `devcontainer-config/cc-isolated.sh:527-528`, `FC/mut.out`

---

## Claim 21: "No guide names the guard."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:67`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `guides/` at HEAD for `Q-147`, `source set`, `source guard`; a differently worded mention is not excluded.
**Legibility-target:** for-orchestrator-synthesis

`git grep -i -E 'Q-147|source.set|source guard' HEAD -- guides` printed nothing (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `guides/`

---

## Claim 22: "`bats test/cc-host-tool-sources.bats`, 7 ok. The test as it stood at fa059477, appended to a scratch copy, also passes today's code."

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one run of each on 8880c925's tree; does not establish flake-freedom over many runs.
**Legibility-target:** for-orchestrator-synthesis

E7 printed `ok 1` to `ok 7` in about 1.3 s. E1 ended with `ok 1 every file an entry point sources, directly or through what it sources, is in its verify_host_tools list`.

**Evidence:** `FC/wt-run.out`, `FC/seed-runs.out`

---

## Claim 23: "Case 4 fails there only because the seed has already made `cc-helper.sh` a host tool." and "The seeds' sed edit of the hook's regex was imprecise and made `test/hooks/live-verify-gate.bats` case 26 fail: that case forces the regex, not the check list"

**Location:** `docs/working/research-2026-11-05-q089-source-guard-narrow.md:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both explanations; see Claim 9 for the two other files.
**Legibility-target:** for-orchestrator-synthesis

Case 4 fails at line 80, `[ "$status" -eq 1 ]`, because `check_entry` returned 0 (`FC/seeds/s3/new.out`). The seed's edit produced `cc-gitdir|cc-helper\.sh`, dropping `\.sh` from the first name. Case 26 is `the hook's host_tools regex names exactly host_tool_files, no more` (`test/hooks/live-verify-gate.bats:360`). With the regex edited exactly, the file gives `ok=35 not-ok=0` (E10), so S3 stands.

**Evidence:** `FC/seed-s3.out`, `FC/seeds/s3/new.out`, `FC/s3p.out`

---

## Claim 24: "when a plain `source` line is added to a host tool's entry point, or a name is dropped from its check list, the file it loads could run unhashed without any test noticing."

**Location:** `test/cc-host-tool-sources.bats:3-5`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three seeds; "could" is read as "in some such case".
**Legibility-target:** for-author

Two imprecisions. First, the file is hashed but not checked: in E9 `cc-helper.sh` is in `host-tools.sha256` and runs anyway, and the test's own message says `unchecked` (`:49`). Second, "without any test noticing" is true of S3 only: S1 and S2 each turn one existing test red (Claims 5 and 6). A dropped name, the second case in the sentence, is caught today by a direct assertion (Claim 8). The precise version: "could run unchecked, and for a new helper no other test notices".

**Evidence:** `test/cc-host-tool-sources.bats:49`, `FC/s3-live.out`, `FC/seed-runs.out`, `FC/seed-s3.out`

---

## Claim 25: "Forms this one misses include `FOO=1 . f`, `FOO=1 source f`, one-line case arms, a quoted or obfuscated `source`, and `$c f`."

**Location:** `test/cc-host-tool-sources.bats:7-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed form through the real test on a real entry point; "include" makes the list open, and it does not name the `trap`/`bash -c`/prefix-command family of Claim 16.
**Legibility-target:** for-orchestrator-synthesis

E5 appended each form to cc-push.sh, sourcing `cc-exit-scan.sh`, and case 1 stayed green: `m-foo-dot`, `m-foo-src`, `m-case`, `m-case2`, `m-quoted`, `m-obf`, `m-var` all `rc=0`. "Q-089's fourth review pass showed that" matches the rubric (`Pass 4's fact-check (fa059477) found 3 Incorrect.`, rubric `:94`).

**Evidence:** `FC/mut.out`, `FC/forms.out`, `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md:94`

---

## Claim 26: "It also does not see a tool run by name, cc-verify.sh (no verify_host_tools call; it sources nothing today) or the lists `--list` passes."

**Location:** `test/cc-host-tool-sources.bats:10-11`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three limits and cc-verify.sh's current state; cc-verify.sh checks itself and the launcher by `hash_ok`, a separate path this claim does not speak to.
**Legibility-target:** for-orchestrator-synthesis

`m-byname` (`bash "$CC_PUSH_DIR/cc-exit-scan.sh"`), `m-verify` and `m-list` all stay `rc=0` (E5). In `devcontainer-config/cc-verify.sh` no line is a `source` or `.` command and none calls `verify_host_tools`; its `source` matches are `source_lines_ok` and regex text (paraphrased — no quote available because the claim covers absence of code; greps over the file). Its own checks are `hash_ok host-tools.sha256 cc-verify.sh` and `hash_ok manifest.sha256 cc-isolated.sh` (`:201-202`).

**Evidence:** `devcontainer-config/cc-verify.sh:47-65`, `devcontainer-config/cc-verify.sh:201-204`, `FC/mut.out`

---

## Claim 27: "the runtime checks do not depend on it."

**Location:** `test/cc-host-tool-sources.bats:11-12`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers runtime code's independence of this test; does not establish that the test is run, which `scripts/run-tests.sh` does by `find` and the `@category` tag.
**Legibility-target:** for-orchestrator-synthesis

The diff touches two files, neither a runtime file, and `git grep cc-host-tool-sources HEAD` hits only the research doc (paraphrased — no quote available because the claim covers absence of a reference). The checks run from `verify_host_tools` in the entry points (`devcontainer-config/cc-isolated.sh:748`, `devcontainer-config/cc-push.sh:204`).

**Evidence:** `devcontainer-config/cc-isolated.sh:748`, `devcontainer-config/cc-push.sh:204`, `scripts/run-tests.sh:217`

---

## Claim 28: "The spelling rule is cc-verify.sh's own source_lines_ok, read from that file rather than restated here, so there is one grammar to keep."

**Location:** `test/cc-host-tool-sources.bats:14-15`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grammar for `source` lines; the regex for the check call at `:40` is this test's own and is a separate thing to keep in step.
**Legibility-target:** for-orchestrator-synthesis

`sed -n '/^source_lines_ok() {/,/^}/p' "$SRC/cc-verify.sh" > "$T/source-lines-ok.sh"` (`test/cc-host-tool-sources.bats:21`), then it is sourced at `:24`. No regex for `source` appears in the file. Renaming the function fails all cases (E14).

**Evidence:** `test/cc-host-tool-sources.bats:21-24`, `devcontainer-config/cc-verify.sh:47-65`, `FC/mut2.out`

---

## Claim 29: "what ENTRY plainly sources, directly or through what those files source, is in its first verify_host_tools call and in host_tool_files. Prints the first problem. cc-push.sh names its directory CC_PUSH_DIR, which the shared grammar does not know, so its copy is renamed to the launcher's variable."

**Location:** `test/cc-host-tool-sources.bats:33-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers list membership and the rename; it does not check order, so a `source` moved above the check call passes (`o-after  rc=0`), and row 71's "before sourcing" stays unguarded by this test.
**Legibility-target:** for-orchestrator-synthesis

The whole of `check_entry` (`:37-52`) was read. The rename is `sed -i 's/CC_PUSH_DIR/CC_ISOLATED_DIR/g' "$dir/cc-push.sh"` (`:42`), on the scratch copy (`mkdir "$T/cfg"`, `cp "$SRC"/cc-*.sh "$T/cfg/"`, `:25-26`). It runs after `args` is read and for either entry, which is why the regex at `:40` accepts both names. The grammar's own pattern names only `\$CC_ISOLATED_DIR` and the `dirname` form (`devcontainer-config/cc-verify.sh:49`). The rename also makes `:59`'s assignment rule apply to cc-push's `CC_PUSH_DIR=` line. `SOURCED` is declared local at `:38`, and `source_lines_ok` fills it through bash's dynamic scope.

**Evidence:** `test/cc-host-tool-sources.bats:37-52`, `devcontainer-config/cc-verify.sh:47-65`, `devcontainer-config/cc-push.sh:203-204`, `FC/mut.out`

---

## Claim 30: "Positive control: both entry points reach cc-gitdir.sh (the launcher through the scan)."

**Location:** `test/cc-host-tool-sources.bats:45`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's tree and the cc-push arm of the control; the launcher arm is not separately seeded.
**Legibility-target:** for-orchestrator-synthesis

`source "$CC_PUSH_DIR/cc-gitdir.sh"` (`devcontainer-config/cc-push.sh:214`); the launcher sources the scan (`devcontainer-config/cc-isolated.sh:750`), and the scan sources it (`devcontainer-config/cc-exit-scan.sh:12`). Case 6 asserts `parse missed cc-gitdir.sh for cc-push.sh` and passes (E7).

**Evidence:** `devcontainer-config/cc-push.sh:214`, `devcontainer-config/cc-isolated.sh:750`, `devcontainer-config/cc-exit-scan.sh:12`, `FC/wt-run.out`

---

## Claim 31: The seven test names (`:54`, `:61`, `:68`, `:75`, `:84`, `:98`, `:112`) describe what each case asserts

**Location:** `test/cc-host-tool-sources.bats:54-117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each body against its name; "any other directory" (`:84`) rests on one sample, "an entry point" (`:98`) is only exercised on cc-push, and case 7's message carries the prefix `not a plain source line:` although the cause is a missing file.
**Legibility-target:** for-orchestrator-synthesis

Each case seeds its named drift and asserts the named message, for example `[[ "$output" == *"cc-isolated.sh sources cc-gitdir.sh unchecked"* ]]` (`:72`) and `[[ "$output" == *"cc-helper.sh is not a host tool"* ]]` (`:81`). Each seed is a `sed` or append whose failure to apply leaves `status` 0, so `[ "$status" -eq 1 ]` then fails loudly rather than passing. All seven pass (E7). Case 7 reaches `:43`, `echo "not a plain source line: $why"`, by way of `echo "$f is missing"` (`devcontainer-config/cc-verify.sh:53`).

**Evidence:** `test/cc-host-tool-sources.bats:43`, `test/cc-host-tool-sources.bats:54-117`, `FC/wt-run.out`

---

## Claim 32: "Land Q-089 finding A6's static guard, claiming only plain spellings and accidental drift. The spelling rule is read from cc-verify.sh's source_lines_ok, not restated." and "reuses source_lines_ok instead of fa059477's regexes (S3); reach difference recorded in the research doc."

**Location:** `git show 8880c925` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these statements against the diff; "(S3)" here is the constraint, and the research doc uses S3 for both the constraint (`:37`, `:51`) and the seed (`:27`, `:29`), so the label alone does not say which.
**Legibility-target:** for-orchestrator-synthesis

The header opens `Accidental-drift guard (Q-147, from Q-089 unit A's finding A6)` and says `A grep guards plain spellings only` (`test/cc-host-tool-sources.bats:3`, `:7`). The extraction is at `:21`. The reach difference is at `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51-56`.

**Evidence:** `test/cc-host-tool-sources.bats:3-15`, `test/cc-host-tool-sources.bats:21`, `docs/working/research-2026-11-05-q089-source-guard-narrow.md:51-58`

---

## Claim 33: "A seeded new helper left today's suite green."

**Location:** `git show 8880c925` (commit message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five test files that name a host tool; the whole `bats` suite was not run on the seed by the author or by this pass.
**Legibility-target:** for-author

Green is true of the two files the doc names (`existing: ok=260 not-ok=0`, E2), but the message says "today's suite". On the same seed `test/hooks/live-verify-gate.bats` case 26 went red from the seed's own imprecise edit, which the doc discloses at `:83`. `test/cc-verify.bats` case 10 and `test/install-host.bats` also go red, which the doc does not mention (E10). All of those clear once the seed takes the remaining steps (Claim 9), so nothing in those files notices the unchecked source and the commit's point stands. The precise version: "left the host-tool tests green once its fixtures were updated".

**Evidence:** `FC/seed-s3.out`, `FC/s3p.out`, `FC/s3p2-cc-verify.out`, `FC/s3p3-install-host.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`): "by accident of those tests' fixtures" is true only of S1. A name dropped from a list is caught by assertions that name the tool (`test/cc-isolated-functions.bats:1189-1193`, `test/cc-push.bats:807`). The decision is unaffected: a new helper is still uncaught.
- **Claim 19b** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:64`): "largest failure family": `vacuous-assertion` has 17 entries, tied for second with `guard-misses-subject`; `fail-open` has 25.

### Stale
(none)

### Mostly Accurate
- **Claim 9** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:29`): "every step the suite forces" omits fixtures at `test/cc-verify.bats:202` and `test/install-host.bats:104`; the result holds once they are added.
- **Claim 14** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:51`): "the same grammar" should be "a grammar for the same rule".
- **Claim 15b** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:54`): `eval` with no `source` is true but was not among the 19 spellings run.
- **Claim 16** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:58`): "three forms" counts the sample; `trap 'source f' EXIT`, `timeout 5 source f`, `env FOO=1 source f` and others are lost too.
- **Claim 18** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:63`): only a full-line comment is refused; an end-of-line comment or a string quoting the call stands in for it.
- **Claim 19a** (`docs/working/research-2026-11-05-q089-source-guard-narrow.md:64`): `setup`'s failure path at `test/cc-host-tool-sources.bats:22` has no seeded case.
- **Claim 24** (`test/cc-host-tool-sources.bats:3-5`): "unhashed" should be "unchecked", and "without any test noticing" holds only for a new helper.
- **Claim 33** (commit 8880c925): "today's suite" should name the scope; three more files went red on the seed before their fixtures were updated.

### Unverifiable
(none)

---

## Goal-Alignment Note

- Success criterion (restated verbatim): a report at docs/reviews/code-fact-check-report-q089-source-guard.md (in the worktree) in the code-fact-check skill's format.
- Answered: yes. All six dispatch items were checked, S1, S2 and S3 reproduced by execution, and the claimed misses run through the real test by mutation.
- Out of scope: whether to land, and test quality beyond what claims assert. The full `bats` suite was not run on the seed; only the five files that name a host tool were.
- Escalate: neither Incorrect changes the land decision; S3 stands and E9 shows the tampered helper really runs. Two facts for the critics: the guard does not check order (`o-after` passes), and an end-of-line comment or string can stand in for the check call (Claim 18).
- Decisions I made: execution logs stay in `FC`, not `docs/reviews/execution-logs/`, and the Claim 19b entry was not added to `docs/reviews/hallucination-patterns.md`, because the dispatch said to edit nothing else; the orchestrator can add it if it qualifies. Claim 8 is Incorrect rather than Mostly accurate because its stated mechanism is refuted, though the conclusion holds.
