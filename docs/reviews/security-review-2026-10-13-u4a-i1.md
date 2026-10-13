Commit: 722c2e10

# Security Review — feat/build-loop-u4a (U4a, review-fix loop iteration 1)

**Scope:** branch diff `main...feat/build-loop-u4a` (scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-orchestrator.bats), plus `land()`, `state_start`, `caller_gate`, `brief_fields`, `FENCE_AWK`, `truthrule`, `check_fix` and the dev-cycle skill's step 7 text, read for context
**Date:** 2026-10-13
**Based on:** docs/reviews/code-fact-check-report-2026-10-13-u4a-i1.md (its Claim 3 and Claim 13 residues are taken up below)

Threat model, per the brief and the plan's "What the gate can and cannot do": honest-path slips must fail loudly. A hostile same-uid loop with a shell is Q-103's residual class, not this gate's. I also count a third source: repo text a loop wrote (briefs, marker bodies) that the orchestrator reads and may act on. Such text can steer the orchestrator's own edits without giving the loop a shell. Settled override rows (719, 722, 725, 745, 747-749, 752, 753) are not re-filed. Where a finding touches one, it says what is new.

## Trust Boundary Map

```
B1 (new): chore branch HEAD commit (orchestrator worktree)  → land_cycle: branch regex, EXPECT==MAIN_SHA, diff-index, merge_result, store_check, cycle_rules, chore_record → refs/heads/main (land: commit-tree + CAS / ff in W)
B2 (moved): merged tree R vs MAIN_SHA listing (RAW_*)       → cycle_rules (GATE_CODE, Asked:, roadmap/idea-log, questions QKEYS)                                  → "judged" verdict that authorises B1's write
B3 (new): brief text (Asked: line, loop/orchestrator-written) → asked() / brief_fields (FENCE_AWK)                                                               → step 2's answer application (keep/drop/done) on main
B4: caller environment (orchestrator shell, git -c pairs)   → git_harden + state_gate + default_gate (no caller_gate for --land-cycle, as for --merge) → every git call in land()
B5: CLI args --expect / --answered                          → argument parser regexes                                                                           → EXPECT CAS base, ANSWERED allow-list in cycle_rules
```

Input-source classification:

```
S1: HEAD's commit and the tree it reaches          — runtime-mutable (orchestrator commits; any same-uid writer) — UNTRUSTED toward the main-ref write sink; trusted only for what cycle_rules judges
S2: brief files' Asked: lines (in S1's tree)       — runtime-mutable (orchestrator writes; loop text can steer it) — UNTRUSTED toward the answer-application sink (step 2 closes or keeps a brief)
S3: docs/dev-cycle.md, docs/constraints.md, instruction/dot files in S1's tree — runtime-mutable — UNTRUSTED toward the policy sink (they set self-merge policy, Self-merge never:, loop seeding) once on main
S4: --expect SHA, --answered IDs                   — request-time (orchestrator's own claim) — trusted toward the CAS base (a wrong value only refuses); --answered is the orchestrator's unrecorded claim (row 748, settled)
S5: caller env / git -c pairs                       — deploy-time-ish (the orchestrator's environment) — trusted per git_harden's model (rows 276, 281, 666)
S6: MAIN_SHA's tree                                 — read from main after store_check --main — trusted as the comparison base
```

What enters from outside is the chore branch's commit (S1). Its content is judged by `cycle_rules` against main, then written to main with no human step. The diff turns the chore landing from an ad-hoc `git merge` into a gate-sanctioned path. So the question is what that gate leaves unjudged on the way to main (B1/B2), and whether the new Asked: rule (B3) closes the hazard it names.

## Findings

#### F1. The Asked: rule accepts an appended ID that is not new, so a brief can still take another question's answer (row 745's hazard)

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1902-1905` (cycle_rules' Asked: loop; cycle_rules runs :1873-1944, read whole)
**Boundary:** B3, B2
**Move:** 11 (guardrail bypasses), 2 (assumed sanitisation)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:1902-1905 (excerpt; cycle_rules continues to :1944 — read)
  for f in "${!ao[@]}"; do
    [[ -n "${ao[$f]}" && -n "${an[$f]+set}" ]] || continue
    [[ "${an[$f]}" == "${ao[$f]}" || "${an[$f]}" == "${ao[$f]}, "* ]] || { echo "refuse ${ap[$f]}: its first Asked: line drops or changes an ID it held; the cycle only appends one"; bad=1; }
  done
```
The rule's own comment states the purpose: "Step 6 only appends an ID to Asked: (row 745: a retargeted ID would reuse another question's answer)".

**Weakness.** The rule pins the IDs a brief already held. It does not check the IDs being added. Step 2 of the skill applies `--check-answer` to every ID on `Asked:` that is not yet on `Applied:`. `--check-answer` takes only the ID (`scripts/dev-cycle.sh:217`) and does not bind the entry's `keep-or-drop-<brief>` slug to the brief. So an ID that is already answered for a different brief applies that answer to this brief, whether it is appended or written as a first `Asked:` line. That is the same answer-reuse that row 745 asked U4 to refuse. A retarget was only one way to reach it.

**Preconditions.** An orchestrator slip writes a wrong ID: a typo, a stale ID, or the neighbouring brief's ID. Repo text steering the orchestrator would also do it. No shell access is needed.

**Probes** (benign fixtures in a temp repo under `/tmp/u4a-sec1-*`, since removed):
- P1: brief `a` held `Asked: Q-001`, and the cycle appended `, Q-003`, where Q-003 is brief `b`'s question, ANSWERED `[2]`. `--cycle-diff` printed `ok`, exit 0.
- P2: brief `c` had no `Asked:` line and gained `Asked: Q-003`. Result: `ok`, exit 0. This is the fact-check's case (a).
- Both are free under `--land-cycle` too, since it runs the same `cycle_rules`.

**Impact.** On the next cycle, step 2 reads Q-003's answer for brief `a`. That answer was `drop` (or `done`), so brief `a` is closed and its work is dropped without the user ever being asked about `a`. A `keep` answer instead resets the brief's idle clock, so the brief holds its slot with no question asked about it. Either way it is a silent integrity failure in the brief queue that no later check surfaces.

**Fix.** Require every ID added to an `Asked:` line to be new: either a key of the listing's `docs/working/questions.md` that BASE's copy lacks, or an entry the same listing files OPEN. This covers both appended IDs and a first `Asked:` line. `cycle_rules` already builds the questions files' entry keys (QKEYS) for both sides, so the check is a set difference over IDs it has in hand. A cheaper partial fix is to have `--check-answer` take the brief and refuse an entry whose slug does not name it. Approval's slug check for `--merge` already works this way.

#### F2. --land-cycle lands the self-merge settings, the user's constraints and instruction files without judging them, while the new GATE_CODE rule's own text says an in-cycle fix edits only --check-fix docs

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1876-1878` (the GATE_CODE rule), `:1885-1889` (the `case` that passes every other path), `:1970-1976` (land_cycle's judgment and land)
**Boundary:** B1, B2
**Move:** 5 (invert the access-control model), 1 (per-consequence trust)
**Confidence:** Medium. The mechanism was executed. Whether the honest path ever stages these files is a reading of the skill.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```bash
# scripts/build-loop.sh:1877-1878 (excerpt; cycle_rules continues to :1944 — read)
    # An in-cycle fix edits only docs --check-fix allows, and the gate's code decides what an answer is (U3c final security F2).
    if [[ "$(lower "$p")" =~ $GATE_CODE ]]; then echo "refuse $p: the gate's own code; an in-cycle fix edits only docs --check-fix allows"; bad=1; continue; fi
```
`truthrule` (`scripts/lib/dev-cycle-read.sh:1912-1922`) names the classes `settings` (docs/dev-cycle.md), `user` (docs/constraints.md), `instr` (instruction and prompt files) and `dot` (dot paths). For each of these, `check_fix` prints `skip` (`scripts/dev-cycle.sh:189-190`).

**Probe P4.** On a chore branch whose commit changed `docs/dev-cycle.md` (appending `Self-merge never: none`), `docs/constraints.md` and `AGENTS.md`, plus the cycle record, `--land-cycle --expect MAIN` printed `landed chore/dev-cycle-2026-10-12 …`, exit 0. `git diff --name-only main^1 main` then listed all four paths.

**Weakness.** `--land-cycle` is a new gate-sanctioned route to main, and it does not require a human. For self-merge, `--merge` refuses the same files through the floor (truthrule's settings, user, instr and dot words). `--land-cycle` refuses only GATE_CODE. `docs/dev-cycle.md` decides the self-merge policy and the `Self-merge never:` list that `--merge` enforces, and `docs/constraints.md` seeds every loop prompt. A chore commit that edits either one widens what later loops may self-merge, and the gate counts that commit as `chore`. Row 722's settled "the chore branch's other paths are not judged" was reasoned on "a path list would misfire". It does not cover these files. `check_fix` already refuses every truthrule class but `cycle` (`TRUTH_WHY` non-empty means skip), so refusing those classes here cannot misfire on an in-cycle fix the skill allows. Also, under `--land-cycle` the listing is MAIN against R, so main's own changes merged into HEAD are not in it.

**Preconditions.** Either the orchestrator slips (an "in-cycle fix" to a settings or instruction file the skill says to file instead), or repo text steers it into such an edit. No shell is needed.

**Impact.** Policy escalation lands on main as `chore`, unreviewed. For example, `Self-merge never:` is emptied or the policy is flipped to self-merge, so later loop work self-merges paths the user had reserved for review.

**Fix.** In `cycle_rules`, refuse a changed path when `truthrule "$(lower "$p")"` sets `TRUTH_WHY` to anything but `cycle`. Optionally also run `truthwalk main`, so an imported .md is refused as the floor refuses it. The refusal text should follow the GATE_CODE rule's wording ("an in-cycle fix edits only docs --check-fix allows"). Alternatively, list every non-cycle path in the record and the final message, which row 745's revisit trigger already proposes; that path belongs to U4b. **Regression from main:** no. Main has no `--land-cycle`, and the chore merge there is not gated at all. This is a gap in the new gate, at the trigger rows 722 and 745 named ("U4's step 9").

#### F3. A brief's Asked: IDs can be dropped by deleting the brief or renaming it to another file name, with no refusal (fact-check Claim 3 residue)

**Severity:** Low
**Location:** `scripts/build-loop.sh:1880-1884` (keying by `${p##*/}`), `:1902-1905`
**Boundary:** B3
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:1882-1883 (excerpt; cycle_rules continues to :1944 — read)
      [[ "${RAW_OM[i]}" == 000000 ]] || ao[${p##*/}]="$(asked "$t.o")"
      [[ "${RAW_NM[i]}" == 000000 ]] || { an[${p##*/}]="$(asked "$t.n")"; ap[${p##*/}]="$p"; }
```
The loop then skips any key with no new side: `[[ -n "${ao[$f]}" && -n "${an[$f]+set}" ]] || continue`.

**Probes:**
- P5: `git rm` of a brief holding `Asked: Q-001` printed `ok`.
- P3: `git mv briefs/2026-10-01-a.md closed/2026-10-01-z.md`, with `Asked:` changed to another brief's answered ID, printed `ok`. The two sides key differently, so neither is compared.

**Weakness and impact.** The skill only ever moves a brief to `closed/` under the same file name. A deletion or a rename is therefore off the honest path, yet the rule passes both silently. A deleted brief takes its open question link and its queue slot with it. A renamed one escapes the rule entirely, which also re-opens F1's answer reuse. Severity is Low (not Medium) because the outcome needs a slip the skill's text does not invite. The mechanism is concrete, though, so Confidence is High.

**Fix.** Refuse a brief path with status D unless the listing adds the same base name under `closed/`. Refuse an A whose base name has no D partner unless it is a new brief with no `Asked:` line (or with only new IDs, per F1).

#### F4. Informational: the asked()/brief_fields divergence (fact-check Claim 13) does not open a bypass

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1867`, `scripts/lib/dev-cycle-read.sh:446-459`
**Boundary:** B3
**Move:** 2
**Confidence:** Medium (read-static, plus the fact-check's E3)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```bash
asked() { LC_ALL=C awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } /^Asked:/ { print; exit }' "$1"; }
```
`brief_fields` uses the same `fence()` and the same `^Asked:` match, but prints no field when `odd` or `infence` is set at END.

Both readers pick the same line, or `brief_fields` picks none. They can never pick different lines. `fence()` returns 1 for every line after the first odd one, so `asked()` reads nothing past an odd line. A new side made odd *before* its `Asked:` line reads as empty, and an empty `an` against a non-empty `ao` refuses. A new side made odd *after* the line keeps the line `asked()` compares. `brief_fields` then skips the brief, so no answer is applied while it stays odd. A later cycle compares against the same `asked()` view, so continuity holds. The divergence is a wording issue (Claim 13), not a hole.

#### F5. Informational: the questions guard is unreachable under --land-cycle, which is correct, but its refusal text names --cycle-diff's remedy

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1911-1916`
**Boundary:** B2
**Move:** 3
**Confidence:** High (fact-check Claim 15)
**Legibility-target:** for-author

With BASE = MAIN_SHA, the two `ls-tree` listings are the same, so the guard cannot fire. That is the intended result: `--land-cycle` judges the merged questions files directly (row 753; E1 test 27). The comment says so ("always so for --land-cycle"). This needs no change. It is recorded so a later edit that passes some other BASE to `cycle_rules` under `--land-cycle` is seen to re-enable a guard whose text ("stage again") does not fit that mode.

## Untested bypass candidates

- **Two changed briefs with the same base name** (`briefs/X.md` and `closed/X.md` both in the listing, for a reopened brief): `ao` and `an` keep only the last one in diff order. I did not probe this. It needs both paths to change in one cycle.
- **GATE_CODE through a symlinked directory** (for example `scripts/lib` replaced by a 120000 link): the probe was not run. By reading, every tracked file under the old directory lists as D and refuses, and an added link at `scripts/lib` does not match `^scripts/lib/`. On a repo where the directory does not yet exist, an added link is not refused. That case is out of this gate's honest-path scope.
- **Attributes in R** (`.gitattributes` in HEAD affecting `merge-tree` in the gate repository): not probed. The gate repository's config is written fresh (fact-check Claim 5), but whether git 2.39's merge-tree reads attributes from the merged trees was not established. F2's fix would refuse `.gitattributes` anyway, as a `dot` path.

## Endorsement Claims

- **Claim:** `--land-cycle` writes the main ref only by compare-and-swap from MAIN_SHA, or by a fast-forward in W after W is re-checked at MAIN_SHA. A main that moved after `--expect` refuses.
  **Location:** `scripts/build-loop.sh:1954`, `:1537-1547`
  **Evidence:** read-static (plus fact-check E1 test 26 for the moved-main refusal)
  **Verified:** `[[ "$EXPECT" == "$MAIN_SHA" ]]`; `update-ref --no-deref … "$NEW" "$MAIN_SHA"`; W's `rev-parse HEAD^{commit} == MAIN_SHA` before `merge --ff-only`
  **Not verified:** a main that moves between W's check and its `merge --ff-only` (`--ff-only` from a moved branch lands NEW on a non-descendant only if NEW descends from it; not executed)
  **route: code-fact-check**
- **Claim:** the commit `land` writes for `--land-cycle` has the tree `cycle_rules` judged (R) and the parents MAIN_SHA and HEAD's commit h, with no hook running on either move path.
  **Location:** `scripts/build-loop.sh:1974`, `:1531-1533`
  **Evidence:** executed (fact-check E1 test 26, E2 hooks probe)
  **Verified:** `VERDICT=([tip]="$h" [tree]="$r" …)`, the `commit-tree -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}"` call, and E2's empty marks file on both paths
  **Not verified:** hook sources other than `core.hooksPath` in git versions after 2.39.5
  **route: code-fact-check**
- **Claim:** the land judges HEAD's commit, not the index. Staged changes refuse, and R comes from `merge-tree` in the gate repository. This answers row 749's re-stage risk by re-judging, not by stopping hooks.
  **Location:** `scripts/build-loop.sh:1955-1972`
  **Evidence:** executed (fact-check E1 test 26, E4 "judge" mutant)
  **Verified:** the `diff-index --cached` refusal; `merge_result` and the `diff-tree MAIN_SHA R` listing; the mutant failing tests 26 and 27
  **Not verified:** the fence-pair capture case of row 753 (fact-check Claim 18 left it static)
  **route: code-fact-check**

## Primitive sweep

Primitive: git ref write (main moved)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1538` `update-ref --no-deref` | S1 (via R, h), S4 (EXPECT) | CAS from MAIN_SHA; cycle_rules; store_check | cleared for CAS. F1 and F2 concern what the judged tree may hold |
| `scripts/build-loop.sh:1544` `merge --ff-only` in W | S1, S5 | state_gate in W, W at MAIN_SHA, no hooks (HARDEN) | cleared. Same content caveat as F2 |

Primitive: commit object write

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1532` `gate_git commit-tree` | S1 (tree R, tip h), branch name from regex | branch regex limits the message to `chore/dev-cycle-DATE[-HHMM]`; `--no-gpg-sign`; gate repository config | cleared. The message is printf'd from a regex-matched name, so no injection |

Primitive: file read of repo blobs into awk (brief / record / questions)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1867` `asked()` on cyc_blob output | S2 | cyc_blob requires 100644; FENCE_AWK | F4 (cleared), F1/F3 (rule gaps, not parser) |
| `scripts/build-loop.sh:1722` `chore_record` cat-file into awk | S1 | isrecord, 100644, A/M; `-v w=` is the regex-matched branch | cleared. `awk -v` interprets backslash escapes, but B matches `[0-9-]` and the fixed prefix only |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence | Regression from main |
|---|---------|----------|----------|----------|------------|---|
| 1 | Asked: rule accepts an appended or first ID that is not new: another brief's answer applies | Medium | B3, B2 | `scripts/build-loop.sh:1902-1905` | High | No (new rule, incomplete) |
| 2 | --land-cycle lands docs/dev-cycle.md, docs/constraints.md, instruction and dot files unjudged | Medium | B1, B2 | `scripts/build-loop.sh:1877-1889, 1970-1976` | Medium | No (main's chore merge is ungated) |
| 3 | Deleting a brief, or renaming it to another name, drops Asked: IDs freely | Low | B3 | `scripts/build-loop.sh:1880-1884` | High | No |
| 4 | asked()/brief_fields divergence opens no bypass | Informational | B3 | `scripts/build-loop.sh:1867` | Medium | No |
| 5 | Questions guard unreachable under --land-cycle (correct; text tied to --cycle-diff) | Informational | B2 | `scripts/build-loop.sh:1911-1916` | High | No |

## Overall Assessment

The land mechanics are sound within the code paths read: a CAS or a re-checked fast-forward, a tree that equals the judged merge, HEAD's commit rather than the index, and no hooks. Their positive claims are routed to code-fact-check above. No finding is a regression from main, which has no gated chore land at all. Both Medium findings are gaps in what the new gate judges, and both can be fixed in place inside `cycle_rules` without design change:

- F1: the Asked: rule must check that added IDs are new, or row 745's answer-reuse hazard stays reachable by appending.
- F2: refuse truthrule's non-cycle classes. They cannot misfire on a `--check-fix`-allowed edit.

The single most important item is F1, because it defeats the stated purpose of a rule this unit adds. The review found no further issues within the code paths read; the endorsement claims are pending execution verification.

## Goal-Alignment Note

- **User goal:** land unit U4a of the build-loop handoff (claude-workflows) once its review-fix loop is clean.
- **Current task:** security review of `feat/build-loop-u4a` vs `main` at 722c2e10.
- **Success criterion:** a markdown report saved at the exact path your own prompt names, structured per your skill.
- **Alignment:** saved at `docs/reviews/security-review-2026-10-13-u4a-i1.md` with `Commit: 722c2e10` first. It has the trust boundary map, the source table, findings with Severity, Location, Evidence, Confidence and Legibility-target, untested bypass candidates, routed endorsements, the primitive sweep, and regression status per finding. Both fact-check residues are covered: Claim 3 is F3 (plus F1, which is wider) and Claim 13 is F4. Probes ran only in a `/tmp/u4a-sec1-*` directory, now removed. No other file was written.
