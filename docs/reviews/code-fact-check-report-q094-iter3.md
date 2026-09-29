# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`), branch `q094b-exit-scan-worktree-removal`, stacked on `q094-exit-scan-worktree-layout`
**Scope:** `git diff 5fadfc2..ba03833`, which is unit A's fix commit 037621f plus unit B's commit ba03833. Files: `devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats` (Q-094 section), `docs/working/plan-q094-exit-scan-worktree-layout.md` (rule 6, B21, B23, B27, B29, B30), the iteration-2 section of `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md`, and both commit messages. The unit A guide and script were read at `q094-exit-scan-worktree-layout` (= 037621f). dfe4c0d..5fadfc2 is context only. It was fact-checked in `docs/reviews/code-fact-check-report.md`. `scan_std_worktrees`, `_snap_config`, `_snap_remote`, `_snap_wrel`, `_snap_gitdir`, `_snap_nested`, `_snap_dotgit` and `git_exit_scan` were read in full.
**Commit:** ba03833
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-09-28
**Total claims checked:** 36
**Summary:** 33 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) first. Its entries are miscounted figures in commit messages and docs. This diff's counts ("399", "89") are close to that pattern, so both were recomputed with `git diff --numstat`, and both match (Claims 28 and 34).

**Execution provenance.** All runs used cwd `/workspace/.claude/worktrees/agent-aaad54fc687b7548c` (or the scratch copies named below), git 2.39.5 and `LC_ALL=C.UTF-8`. Without that setting, this host's missing `en_US.UTF-8` locale adds `setlocale` warnings to the output and breaks test 1's one-line check. That is an environment artifact, not a code fault. Every scratch repo was made with `mktemp -d`, and every scratch bats file exports `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`. The logs are in the session scratchpad, `$SP = /tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/q094i3/`, and are **not tracked**:
- `$SP/bats-q094.txt`: `bats --filter 'Q-094' test/cc-isolated-functions.bats`. Exit 0, 10/10. Run 2026-09-29T02:35Z.
- `$SP/unitA-bats.txt`: the same filter, run on unit A's script and tests (`git show q094-exit-scan-worktree-layout:…`) in `$SP/unitA/`. Exit 0, 9/9. Run 2026-09-29T02:38Z.
- `$SP/mutation-insteadof.txt`: `$SP/mut/` with `cc-exit-scan.sh:417` deleted, filter `relative hooksPath, attributesFile or remote`. Exit 1: the test fails. Run 2026-09-29T02:37Z.
- `$SP/mutation-pairing.txt`: `$SP/mut/` with the content regex at `:861` changed to `re="^file "`, filter `removed`. Exit 1: "pairs only with the .git that pointed at it" fails. Run 2026-09-29T02:40Z.
- `$SP/exp-out.txt` (`exp.bats`, E1–E8), `$SP/exp2-out.txt` (`exp2.bats`), `$SP/exp3-out.txt` (`exp3.bats`, E9–E10), `$SP/exp4-out.txt` (`exp4.bats`, E11). Each exited 0. Runs 2026-09-29T02:37Z–02:41Z.

---

## Claim 1: "When every difference is a linked worktree added or removed in git's own layout … the scan prints one `note:` and returns 0"

**Location:** `devcontainer-config/cc-exit-scan.sh:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers added, removed, and mixed added-and-removed standard worktrees reaching the note with status 0. It does not establish which removal shapes count as "git's own layout". Claims 4a/4b cover that.

`git_exit_scan` returns 0 after printing the note when `scan_std_worktrees` succeeds (`cc-exit-scan.sh:954-956`: `if [ -z "$invalid" ] && note="$(scan_std_worktrees …)"; then printf '%s\n' "$note" | scan_vis >&2; return 0`). Both record signs are now accepted (`:833-834`: `[+-]F$'\t'dotgit$'\t'*)`). E3 (`git worktree remove` alone) printed `(removed: agent-x)` with status 0. The bats test at `:2263` asserts `(added: agent-z; removed: agent-y).` with status 0, and it passes.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:75-77,830-837,954-956`; `$SP/bats-q094.txt`; `$SP/exp-out.txt` (E3)

---

## Claim 2: `[ "$t" != . ] || _snap_wrel "$key" "$f" ./   # a base "." starts a relative path`

**Location:** `devcontainer-config/cc-exit-scan.sh:417`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the insteadOf / pushInsteadOf base `.`, which now leaves a W record and refuses the note. It does not establish that the rewritten URL is walked. It is not walked (Claim 22).

`_snap_wrel` appends a W record for any value that is not empty, absolute or `~/` (`:292-293`), so `./` always records one. E8 printed `W	url...insteadof	…/.git/config` for base `.`, `W	remote	./` for base `./`, and nothing for an absolute base. In exp2, the same plant scanned as `status=0 note: …(added: agent-x)` on the copy with this line removed, and as `status=1 WARNING` on the worktree's code.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:290-294,346-357,414-418`; `$SP/exp-out.txt` (E8); `$SP/exp2-out.txt`

---

## Claim 3: "Only dotgit, commondir-file and hooksdir records differ, and the exit snapshot has no W record."

**Location:** `devcontainer-config/cc-exit-scan.sh:797-798`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the record-kind filter and the W refusal. It does not establish anything about records that are identical in both snapshots, which never enter the diff.

`:815`: `[[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1`. `:832-836`: only `[+-]F` records of `dotgit`, `commondir-file` or `hooksdir` are kept, and `*) return 1 ;;` declines everything else.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:815,830-837`

---

## Claim 4a: "Removed <n>: those two records gone, P gone on disk, and one gone `dotgit` record that held exactly "gitdir: P\n" (either form)."

**Location:** `devcontainer-config/cc-exit-scan.sh:798-800`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three removal conditions, including the container `/workspace` form. It does not establish checks on the vacated working-tree directory. The code makes none, and the comment claims none.

```bash
# devcontainer-config/cc-exit-scan.sh:855-868
    if [ "${rec:0:1}" = - ]; then
      [ ! -e "$p" ] && [ ! -L "$p" ] || return 1
      ...
      ok="" h="$(_snap_hash_str "gitdir: $p"$'\n')" g=""
      [ -z "$ccommon" ] || g="$(_snap_hash_str "gitdir: $ccommon/worktrees/$n"$'\n')"
      re="^file [0-7]+ ($h${g:+|$g})\$"
      ...
      [ -n "$ok" ] || return 1
      used["$ok"]=1; removed+=("$n")
      continue
    fi
```
Runs: with HEAD or commondir deleted but P left in place, E1 and E2 returned status 1. In E9, a removed `.git` holding the `/workspace/.git/worktrees/agent-x` form paired and gave the note. In E10, a container form naming a different `<n>` did not pair and returned status 1.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:841-869`; `$SP/exp-out.txt` (E1, E2); `$SP/exp3-out.txt` (E9, E10)

---

## Claim 4b: the removal description leaves out that the removed records must be the standard ones

**Location:** `devcontainer-config/cc-exit-scan.sh:798-802`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the comment says the removal rule requires. It does not establish any code defect: the code is stricter than the comment.

The comment gives "`commondir-file P/commondir` of exactly "../..\n"" and "`hooksdir P/hooks missing`" only under "Added <n>:". The shared checks at `:850-853` apply to both signs: `re="^file [0-7]+ $std\$"; [[ "$attrs" =~ $re ]] || return 1` and `hk="${rec:0:1}F"$'\t'"hooksdir"…$'\t'"missing"`. So a removed worktree must also have had `commondir` exactly `../..\n` and no `hooks/`. A more precise comment would read "Removed <n>: those two records gone, as in the added form (`../..\n`, hooks `missing`)". Plan rule 6 (`plan…:60`) and the commit message both state this correctly.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:798-802,850-853`

---

## Claim 5: "Its own `.git` file gone too … Another worktree's .git never pairs."

**Location:** `devcontainer-config/cc-exit-scan.sh:857-858`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a removed `.git` whose content names a different private dir. It does not establish anything about a `.git` at an unrelated path whose content names this P, which would pair. Pairing is by content, not by path.

The test at `:2290` (agent-a's git dir gone, agent-b's `.git` gone) returns status 1. With the regex mutated to `re="^file "`, which approximates count pairing, that test fails at `[ "$status" -eq 1 ]`, so the test does discriminate content pairing.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:857-866`; `test/cc-isolated-functions.bats:2290-2302`; `$SP/mutation-pairing.txt`

---

## Claim 6: note text "(added: …; removed: …)"

**Location:** `devcontainer-config/cc-exit-scan.sh:911-914`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the added-only, removed-only and both forms of the note. It does not establish sort order beyond `LC_ALL=C sort`.

`:913`: `line="${line:+${line% }; }removed: …"`. The test assertions `*"(removed: agent-y)."*` and `*"(added: agent-z; removed: agent-y)."*` pass, and E3 printed the exact removed-only sentence.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:911-914`; `$SP/bats-q094.txt`; `$SP/exp-out.txt` (E3)

---

## Claim 7: "Only linked worktrees added or removed in git's standard layout (STANDARD WORKTREES above): a note, not a finding."

**Location:** `devcontainer-config/cc-exit-scan.sh:951-952`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call site in unit B. The same words were Stale on unit A (earlier fact-check, Claim 12). They are accurate here because unit B accepts removals.

The evidence is the same as for Claim 1 (`:954-956`, E3).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:951-956`; `$SP/exp-out.txt` (E3)

---

## Claim 8: "Fact-check (k=1): 36 claims. 1 Incorrect … 5 Stale … 3 Mostly accurate, fixed (the header's "." exception, B28's coverage wording, the host-dependent ms figure)"

**Location:** `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md:49-51`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tally and the three Mostly-accurate items against the iteration-2 report. It does not re-verify that report's verdicts.

`docs/reviews/code-fact-check-report.md` says `**Total claims checked:** 36` and `**Summary:** 26 verified, 3 mostly accurate, 5 stale, 1 incorrect, 1 unverifiable`. Its Mostly Accurate list holds Claim 2 (the header's "."), Claim 21 (B28) and Claim 29 (the ms figure). Commit 5fadfc2 records these fixes.

**Evidence:** `docs/reviews/code-fact-check-report.md:1-12,768-771`

---

## Claim 9: R3 "Fixed: insteadOf bases of `.` always make a W record; a test case pins it and a mutation that drops the fix fails it. … now a guide Known route"

**Location:** `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md:55`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fix, the test and the mutation. It does not establish anything about bases other than `.` (see Claim 16).

The mutation run fails `warns_listing_wt` on the insteadOf loop entry `"url...insteadOf https://x.invalid/"` (`test/cc-isolated-functions.bats:2402`). The Known route is at `guides/cc-isolated-usage.md:386-388`.

**Evidence:** `$SP/mutation-insteadof.txt`; `test/cc-isolated-functions.bats:2398-2412`

---

## Claim 10: I1 "Accepted: fails closed; the existing "After the scan" route (B24)"

**Location:** `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md:56`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of B24 and the guide route. It does not re-run the FIFO race.

Plan B24 reads "a later change is the documented "After the scan" route". The guide has `- **After the scan.** The container keeps running…` (`guides/cc-isolated-usage.md:374`).

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:96`; `guides/cc-isolated-usage.md:374-376`

---

## Claim 11: performance row "12–18 ms/MiB; … (3,000 worktrees: 165 s → 0.2 s); the note holds at 300 and 600 worktrees"

**Location:** `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md:57`
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the iteration-2 performance review. It does not re-measure anything.

The performance review says "`207 ms at N=3,000 (was 164,848 ms)`" (`:72`), "`about 12–18 ms per MiB`" (`:96`), and "`Note held at 300 and 600 worktrees`" (`:71`).

**Evidence:** `docs/reviews/performance-review-2026-09-28-q094-iter2.md:49-50,71-72,96`

---

## Claim 12: rule 6, "The stacked unit accepts a removal when the difference removes exactly `hooksdir P/hooks missing` and `commondir-file … H("../..\n")`, `P` no longer exists on disk, and one removed `dotgit` record held exactly `gitdir: P\n` (either form)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the removal rule in ba03833. It does not establish the historical "447 lines" figure.

The code is quoted under Claim 4a, with the shared checks at `:850-853`. E1, E2, E3, E9 and E10 all behave as the rule says.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:850-869`; `$SP/exp-out.txt`; `$SP/exp3-out.txt`

---

## Claim 13: B21 "private dir made "not a git dir" (HEAD or commondir deleted) … Rule 6 requires `P` gone on disk"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers deleting HEAD alone and deleting commondir alone. It does not re-verify "E10: a private dir without HEAD is refused by git anyway".

E1 (HEAD only) returned status 1 and listed `- dotgit`, `- commondir-file` and `- hooksdir`. E2 (commondir only) also returned status 1. `:856`: `[ ! -e "$p" ] && [ ! -L "$p" ] || return 1`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:856`; `$SP/exp-out.txt` (E1, E2)

---

## Claim 14: B23 "Remove-and-re-add at the same path (dotgit changed) … In the stacked unit, the added side is verified by rule 5 and the removed `dotgit` is paired by content"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:95`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a re-add at the same path under a new `<n>` (the only way the dotgit changes there). It does not cover a re-add of the same `<n>` at a different path. There the commondir and hooks records are unchanged, nothing pairs, and it warns, which is safe.

E6 (same path, new name `agent-x1`) printed `(added: agent-x1; removed: agent-x)` with status 0. E5 (same name, other path) listed `- dotgit …/agent-x/.git` and `+ dotgit …/other/agent-x/.git` with status 1.

**Evidence:** `$SP/exp-out.txt` (E5, E6)

---

## Claim 15: B27 "Only the `dotgit` record goes. … count pairing did NOT cover this … It is fixed there by pairing on content"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unpruned-removal warning with and without a concurrent clean removal. "Here, any removal warns" refers to unit A, and unit A's test confirms it (Claim 23).

The test at `:2263` deletes agent-x's working tree after agent-y's clean removal and asserts status 1 and `- dotgit …/agent-x/.git`. It passes. The pairing mutation fails the test at `:2290` (Claim 5).

**Evidence:** `test/cc-isolated-functions.bats:2276-2280`; `$SP/bats-q094.txt`; `$SP/mutation-pairing.txt`

---

## Claim 16: B30 "The `.` exemption no longer applies to insteadOf bases: they always make a W record."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:101`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the effect for base `.` and the row's experiment parenthetical. It does not endorse the broad reading that every insteadOf base makes a W record.

For base `.` the effect is right: E8 and exp2 show a W record and a warning. The mechanism wording is loose. The exemption in `_snap_remote` still runs for insteadOf bases (`:357`: `[ "$p" = . ] || _snap_wrel remote "$p" "$p"`). The W record comes from a separate call in the caller (`:417`). "They always make a W record" is true only for base `.`. E8's absolute base made none. A more precise wording is "an insteadOf base of `.` always makes a W record", which is the commit's own wording. The parenthetical "(a planted `<wt>/.evil` bare repo's hook ran on push)" was reproduced in exp2. Row order is B28, B30, B29, but that is not a factual claim.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:357,417`; `$SP/exp-out.txt` (E8); `$SP/exp2-out.txt`

---

## Claim 17: B29 "verified: a push to `.` from the worktree ran the common `pre-receive`, not the private one"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 with a planted private `hooks/pre-receive`. This row is unchanged context in this diff.

E11 printed `common=ran private=no`.

**Evidence:** `$SP/exp4-out.txt`

---

## Claim 18: "A linked worktree added or removed in git's own layout (an agent worktree left behind) is not a finding: one `note:` line, and the exit status is claude's."

**Location:** `guides/cc-isolated-usage.md:66-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unit B's behavior. The launcher-level test (`:2417`) exercises only the added case. Removal is exercised at the `git_exit_scan` level. The parenthetical example describes the added case.

The evidence is the same as for Claim 1. On unit A this sentence says only "added" (verified under Claim 23).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:954-956`; `$SP/bats-q094.txt`; `$SP/exp-out.txt` (E3)

---

## Claim 19: "or removed (`git worktree remove`: git dir and `.git` file both gone) in the exact layout git writes, the scan prints one `note: …` line"

**Location:** `guides/cc-isolated-usage.md:334-339`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git worktree remove`, and `rm -rf` of the tree followed by `git worktree prune`. It does not establish that the working-tree directory is gone, which is neither claimed nor checked.

E3 (`git worktree remove`) and E4 (`rm -rf` then `git worktree prune`) both printed the removed note with status 0. The guide's example text `(added: agent-x) …` matches the format at `:912`.

**Evidence:** `$SP/exp-out.txt` (E3, E4); `devcontainer-config/cc-exit-scan.sh:911-914`

---

## Claim 20: the "Exact" rule, read as applying to removed worktrees too

**Location:** `guides/cc-isolated-usage.md:342-348`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how the paragraph's "Exact" list maps onto the removal path. It does not find any removal accepted that should warn.

The paragraph now covers additions and removals, but its "Exact" list ("working tree is inside the checkout", "the container's `/workspace/…` path (which, if it exists on the host, must be the same directory)") describes the added-side checks. For a removal the code checks only the removed records and that P is gone (`:855-868`, quoted under Claim 4a). The same-directory check (`:902-904`) and the working-tree location check (`:881-889`) run only for added worktrees. The removed `.git`'s container form pairs whether or not that path exists (E9). This is harmless, because the file is gone. The paragraph's restrictions (commondir `../..\n`, no `hooks/`, `config` or symlink) still hold in effect through the record kinds and hashes (paraphrased — no quote available because this is inferred from `:833-836` declining any other record kind together with `:850-853`). To be precise, add one clause: "for a removed worktree: those records gone, its private dir gone, and a gone `.git` that named it".

**Evidence:** `guides/cc-isolated-usage.md:342-348`; `devcontainer-config/cc-exit-scan.sh:833-836,850-869,881-904`; `$SP/exp3-out.txt` (E9)

---

## Claim 21: "Anything else warns … also any other change in the session, a working tree deleted without a prune"

**Location:** `guides/cc-isolated-usage.md:348-349`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an unpruned working-tree deletion, alone or next to a clean removal. "Anything else" is verified only for the shapes the tests and E1–E10 exercise.

The test at `:2276-2280` passes, and so do E1 and E2.

**Evidence:** `test/cc-isolated-functions.bats:2276-2280`; `$SP/bats-q094.txt`; `$SP/exp-out.txt`

---

## Claim 22: "**A URL rewritten by `url.<base>.insteadOf`.** The base is walked, never the rewritten URL, so a remote rewritten to a local path the session plants runs that repository's hooks on push."

**Location:** `guides/cc-isolated-usage.md:386-388`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the top-level checkout with an existing base dir. It does not claim that the base walk catches the plant when the base dir is created during the session. There, a change to the base's own record can catch it, as security iteration 2's E6 showed.

`:416-418` passes only the base `t` to `_snap_remote`. In E7 the config was `url.$WS/p/.insteadOf=https://x.invalid/` with `origin=https://x.invalid/evil`. A bare repo planted at `$WS/p/evil` gave scan `status=0` with no output, and a host `git push` then ran its `pre-receive` (`hook ran: yes`). E8 shows the base walked (`W remote ./`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:414-418`; `$SP/exp-out.txt` (E7, E8)

---

## Claim 23: unit A guide and script, "a worktree removed during it" warns / "(a removal warns)"

**Location:** `guides/cc-isolated-usage.md:348` and `devcontainer-config/cc-exit-scan.sh:798`, at `q094-exit-scan-worktree-layout`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unit A's text and behavior at 037621f. Unit A's launch step (`:66`) says only "A linked worktree added in git's own layout". It does not establish unit B.

At unit A, `git show q094-exit-scan-worktree-layout:guides/cc-isolated-usage.md` line 348 reads "also any other change in the session, a worktree removed during it". The script's comment reads "records are added (a removal warns)". Unit A's test "a worktree removed during the session still warns" passes on unit A's script.

**Evidence:** `$SP/unitA-bats.txt`; `$SP/unitA/devcontainer-config/cc-exit-scan.sh:798`

---

## Claim 24: test name "a removed standard worktree is a note; a half-removed one warns"

**Location:** `test/cc-isolated-functions.bats:2263`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name against the assertions. The final `status -eq 0` step (agent-x fully gone) checks only status, not the note text.

It asserts status 0 and `(removed: agent-y).`; then status 0 and `(added: agent-z; removed: agent-y).`; then status 1 with the working tree deleted; then status 1 with HEAD and commondir deleted; then status 0 with P gone. The test passes.

**Evidence:** `test/cc-isolated-functions.bats:2263-2288`; `$SP/bats-q094.txt`

---

## Claim 25: test name "a removed git dir pairs only with the .git that pointed at it"

**Location:** `test/cc-isolated-functions.bats:2290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the negative case, which does discriminate count pairing from content pairing. The positive pairing is covered by the test at `:2263`.

It asserts status 1 and `- dotgit …/agent-b/.git`. It passes, and it fails under the pairing mutation.

**Evidence:** `test/cc-isolated-functions.bats:2290-2302`; `$SP/mutation-pairing.txt`

---

## Claim 26: 037621f "the "." exemption in _snap_remote also covered url.<base>.insteadOf bases … (https://x.invalid/evil -> .evil). A bare repo planted at <new worktree>/.evil passed with the note, and a host push there ran its hook."

**Location:** commit 037621f message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behavior before the fix, reproduced on a copy with `:417` removed, which matches 5fadfc2's `_snap_config` (`:414-418` minus that line). It does not cover `pushInsteadOf`, which follows the same path but was not run.

exp2 pre-fix printed `status=0 note: … (added: agent-x)` and `hook ran: yes`.

**Evidence:** `$SP/exp2-out.txt`; `devcontainer-config/cc-exit-scan.sh:355-357`

---

## Claim 27: 037621f "Test case added; a mutation that drops the line fails it."

**Location:** commit 037621f message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers deleting exactly `:417`.

Covered under Claim 9.

**Evidence:** `$SP/mutation-insteadof.txt`

---

## Claim 28: 037621f "unit at 399 changed code lines outside docs/ against dfe4c0d" and "The guide's per-worktree ms clause makes room for it (size cap)"

**Location:** commit 037621f message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the decision-log row 62 counting (added plus removed, outside `docs/`, against the unit base).

`git diff --numstat dfe4c0d 037621f -- . ':(exclude)docs/'` gives 171+4, 2+1, 29+3 and 189+0, which is 399. At 5fadfc2 the count was 397. The ms clause was added inside this unit: dfe4c0d has 0 hits for "check that allows the note". Removing it cancels two counted lines, so without that removal the unit would be at 401.

**Evidence:** command output in this session, cwd = worktree, exit 0; `docs/decisions/log.md:85`

---

## Claim 29: 037621f "Performance iteration 2: no findings (linear [[ ]] matches; O(n^2) gone)."

**Location:** commit 037621f message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the review artifact only.

The performance review says "`I see nothing further to fix for performance`" and "`The O(n²) is gone`".

**Evidence:** `docs/reviews/performance-review-2026-09-28-q094-iter2.md:61,96`

---

## Claim 30: ba03833 "A worktree removed with `git worktree remove` drops three records: its .git file, its private dir's commondir, and the missing hooks/."

**Location:** commit ba03833 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a standard worktree with no private hooks, config or links.

E1's warning listed exactly `- dotgit …/.git`, `- commondir-file …/commondir` and `- hooksdir …/hooks  missing`.

**Evidence:** `$SP/exp-out.txt` (E1)

---

## Claim 31: ba03833 conditions list, including "(a dir made invisible to the scan by deleting HEAD or commondir but left in place still warns)"

**Location:** commit ba03833 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD-only and commondir-only deletion separately. The repo test deletes both together.

E1 and E2 are covered under Claim 13. The "../..\n" and "missing" conditions are at `:850-853`.

**Evidence:** `$SP/exp-out.txt` (E1, E2); `devcontainer-config/cc-exit-scan.sh:850-856`

---

## Claim 32: ba03833 "Pairing is by content, not count: security review iteration 1 showed count pairing let one clean removal absorb another worktree's deleted .git."

**Location:** commit ba03833 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the historical finding and the current content pairing.

The iteration-1 security review says "`treats every remaining unpaired - dotgit … record as benign as long as ndot == nrm`" (`security-review-2026-09-28-q094.md:42`). Current pairing is by content (Claim 5).

**Evidence:** `docs/reviews/security-review-2026-09-28-q094.md:34-55`; `$SP/mutation-pairing.txt`

---

## Claim 33: ba03833 "Anything else, including a working tree deleted without a prune, warns."

**Location:** commit ba03833 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same as Claim 21.

Covered under Claim 21.

**Evidence:** `test/cc-isolated-functions.bats:2276-2280`; `$SP/bats-q094.txt`

---

## Claim 34: ba03833 "89 changed code lines"

**Location:** commit ba03833 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count against unit A (037621f), outside `docs/`.

`git diff --numstat 037621f ba03833` gives 32+13, 5+4 and 33+2, which is 89.

**Evidence:** command output in this session, cwd = worktree, exit 0

---

## Claim 35: ba03833 "Stacked on q094-exit-scan-worktree-layout (split off for the decision log row 62 size cap)"

**Location:** commit ba03833 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch ancestry and the existence of row 62.

`git branch --contains 037621f` lists both branches, and `q094-exit-scan-worktree-layout` = 037621f. Row 62: "`Every review unit has a hard size cap of ~400 changed code lines, counted outside docs/`".

**Evidence:** `docs/decisions/log.md:85`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 4b** (`devcontainer-config/cc-exit-scan.sh:798-802`): the "Removed <n>" sentence leaves out that the removed `commondir-file` must be `../..\n` and the removed `hooksdir` must be `missing`. The code checks both at `:850-853`.
- **Claim 16** (`docs/working/plan-q094-exit-scan-worktree-layout.md:101`): "they always make a W record" holds only for base `.`. The `_snap_remote` exemption still runs, and the W record comes from `:417`. Use the commit's wording: "an insteadOf base of `.` always makes a W record".
- **Claim 20** (`guides/cc-isolated-usage.md:342-348`): the "Exact" list describes the added-side checks. For a removal, only the removed records and "private dir gone" are checked, and the container-path same-directory check does not apply.

### Unverifiable
None.
