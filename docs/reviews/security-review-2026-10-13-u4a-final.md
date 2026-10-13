Commit: b1a6f0a2

# Security Review — feat/build-loop-u4a (U4a, final confirming pass)

**Scope:** whole branch `git diff main...HEAD` at b1a6f0a2: `scripts/build-loop.sh` (`land_cycle`, `cycle_rules`, `questions_rules`, `cycle_diff`, `asked`, `chore_msg`, `chore_record`, `log_class`'s chore arm, `land()`), `scripts/lib/dev-cycle-read.sh` (`isrecord`, `writable`, the `truthrule` comment), `test/scripts/build-loop-orchestrator.bats` (the three U4a tests). Read for context: `merge_result`, `store_check`, `state_start`, `raw_records`, `merge_ident`, `truthrule`, `floor`, `floor_why`, `GATE_CODE`, `lower`, `scripts/dev-cycle.sh` `--check-fix` (:186-193), `skills/dev-cycle/SKILL.md` step 2/3 (:295-319).
**Date:** 2026-10-13
**Based on:** docs/reviews/code-fact-check-report-2026-10-13-u4a-final.md (k=3, merged), docs/reviews/security-review-2026-10-13-u4a-i1.md, docs/reviews/security-review-2026-10-13-u4a-i2.md, the rubric and override rows dated 2026-10-13 for `feat/build-loop-u4a`.

Threat model, per the brief: honest-path slips must fail loudly. A hostile same-uid loop with a shell is Q-103's residual class. Settled override rows (719, 722, 745-753, 754-768) are not re-filed. Where a finding touches one, it says what is new. Probes ran under `/tmp/u4a-secf-*` (removed; no process left running) against the worktree's script on benign fixtures.

## Verdict on earlier findings

| Earlier finding | Rubric | Closed? | Basis |
|---|---|---|---|
| i1 F1: added Asked: IDs not checked | A1 | **Closed as filed.** An added item must be an exact `Q-NNN`/`Q-NNN@SHA` naming a heading the listing gains. A residue remains (F2 below): the ID is not bound to the brief its entry names. | fact-check executed; probe P3 |
| i1 F2: truth files land unjudged | A2 | **Closed for truthrule's classes** in both modes. @-imports (row 764) and the floor's "below" class (F3 below, new) are not covered. | fact-check executed (28 single-path cases) |
| i1 F3: brief deleted or renamed drops IDs | A4 | **Closed.** | fact-check executed; test |
| i1 F4: asked()/brief_fields divergence | A18 | Settled (row 760). | — |
| i1 F5: questions guard text under --land-cycle | A5 | **Closed.** The guard is now in `cycle_diff` only, and `SIDE` words the refusals. | read-static, fact-check |
| i2 F-a: one new ID on several briefs | B2 | **Closed as filed** (`used[$id]`, :1976). i2 recommended binding the ID to its brief through the entry's slug. The fix chose "added once" instead, which leaves F2 below. | test; probe P3 |
| i2 F-b: item checked only at its start | B1 | **Closed.** Anchored regex at :1973. | test, fact-check |
| i2 F-c: same name in briefs/ and closed/ | B3 | **Closed.** | test |
| i2 F-d: cycle file in another case | B4 | **Closed** for ASCII case (:1924). Non-ASCII folding is untested (F4). | test |
| i2 F-e: @-imported docs | B14 | Settled (row 764). | — |

## Trust Boundary Map

```
B1 (new): chore branch HEAD commit + its history (orchestrator worktree) → land_cycle: branch regex, LAND_MAIN==MAIN_SHA, diff-index, merge_result, store_check → R, the merge tree
B2: R vs MAIN_SHA listing (RAW_*, every changed path)                   → cycle_rules: GATE_CODE, truthrule(lower(p)) != cycle, case, brief/questions/roadmap/idea-log rules → "judged" (everything else passes unread)
B3: brief Asked: lines in R (keyed by file name)                        → asked() → extension + exact item + NEW + used[]       → step 2's --check-answer by ID alone (keep/drop/done)
B4: questions headings in R (QKEYS h lines, both files)                  → NEW = headings MAIN_SHA lacks                          → B3's allow-list
B5: judged R, h, MAIN_SHA                                               → land(): commit-tree (chore_msg) + update-ref CAS / merge --ff-only in W → refs/heads/main
```

Input-source classification:

```
S1: HEAD's commit h and every commit main..h (incl. any branch it was cut from) — runtime-mutable (orchestrator; loops' branches if merged in) — UNTRUSTED toward the main-ref write
S2: brief Asked: lines in R             — runtime-mutable (orchestrator writes; loop text can steer it) — UNTRUSTED toward answer application
S3: questions entry headings/slugs in R — runtime-mutable — UNTRUSTED as an authority over which brief an entry belongs to
S4: path spellings in R (case, Unicode) — runtime-mutable — UNTRUSTED toward readers on a case-insensitive checkout
S5: --main SHA, --answered IDs          — request-time (orchestrator's own claim) — trusted toward the CAS base (a wrong value only refuses); --answered as row 748
S6: branch name from symbolic-ref       — runtime-mutable, regex-limited — trusted toward the message (regex admits digits and fixed text only)
```

The diff adds a second writer of main (B1→B5). It judges the merge it lands, which is a real improvement over main, where the chore branch landed through pr-prep with no gate. The judgment is a deny-list (B2): GATE_CODE, truthrule's classes, the cycle files' own rules. Every other path in R lands unread. Two findings follow from that. One follows from B4 being a set of IDs, not a map from ID to brief.

## Findings

#### F1. --land-cycle lands any path outside the deny-list, including a loop branch's code when the chore branch was cut from or merged with it

**Severity:** Medium
**Location:** `scripts/build-loop.sh:2026-2060` (land_cycle), `:1940` (`*) continue ;;` in cycle_rules)
**Boundary:** B1, B2
**Move:** 5 (invert the access model), 11
**Confidence:** Medium (the trigger is an orchestrator slip whose odds depend on U4b's step 9 text)
**Legibility-target:** for-orchestrator-synthesis
**Regression from main:** no. main had no gate on the chore land.
**Evidence (probe P1, executed):** a chore branch `chore/dev-cycle-2026-10-12` was created from a loop's `feat/x` tip, which changes `src/app.sh` and adds `test/t.bats`, and a cycle record was committed on it. `--land-cycle --main <main>` printed `landed chore/dev-cycle-2026-10-12 …`, exit 0, and `git show main:src/app.sh` held the loop's line. Source at :1940: `      *) continue ;;` (inside the `case "$p" in` of cycle_rules' per-path loop; the remainder judges only the roadmap and idea log).

The land's only checks on content are the deny-list classes. HEAD's history is not read. A chore branch cut from the wrong base, or one that ran `git merge feat/x` by mistake, lands that branch's code and tests on main as `chore`. That bypasses `--check`/`--merge`'s policy, N rules, floor and approval, and `--main-log` reads the result as chore. This touches rows 722/745 ("a slip committed onto the chore branch itself lands as chore"; "a path list would misfire"). Three things are new. U4a is the land those rows deferred to. The shape here is a loop's history, not the orchestrator's own commit. And `--check-fix` (`scripts/dev-cycle.sh:191`) now defines the in-cycle fix scope as an allow-list (tracked `docs/**.md` outside working/ and reviews/, plus README.md), so the "misfire" objection is weaker than when row 722 was written.

**Recommendation:** add a check that needs no path list: refuse when any commit in `MAIN_SHA..h` is reachable from another local branch head (`git rev-list MAIN_SHA..h --not --exclude=refs/heads/B --branches` must list every commit `rev-list MAIN_SHA..h` lists). That catches a branch cut from, or merged with, a loop branch that still exists. Alternatively, or in addition, print the paths outside the cycle files and `--check-fix`'s scope in the landed output so step 9 can put them in the record (row 745's own trigger offers this). Either way, U4b's step 9 should name the residue.

#### F2. An added Asked: ID is not bound to the brief its entry is for: an entry filed for brief Y, appended to brief X, passes both modes

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1966-1978` (the Asked: loop in cycle_rules), `:2019-2020` (NEW in questions_rules)
**Boundary:** B3, B4
**Move:** 11
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Regression from main:** no (main has no Asked: rule). It is the half of i2 F-a's recommendation not taken.
**Evidence (probe P3, executed):** the change files `### Q-002 · keep-or-drop-2026-10-01-y-1`, the slug the skill gives an entry for brief y (`skills/dev-cycle/SKILL.md:316`), and appends `, Q-002` to brief **x**'s `Asked:` line. `--cycle-diff` printed `ok`, and `--land-cycle` printed `landed chore/dev-cycle-2026-10-14 …`. The source: `      elif [[ -n "${used[$id]-}" ]]; then echo "refuse ${ap[$f]}: …"; bad=1` / `      else used[$id]=1; fi` (excerpt of the per-item loop; the remainder closes the loops and returns `$bad`).

NEW is a set of IDs, and `used[]` makes each one single-use, but nothing ties an ID to the brief whose stem is in its heading. A swap between two briefs filed in the same cycle passes. That is an honest slip of exactly the kind row 745 names. The user's keep-or-drop answer about Y is then applied to X by step 2, which matches by ID alone. For example, a `drop` answer would drop X. Y's own question is never applied.

**Recommendation:** when an item is added to brief `NAME.md`, require the heading NEW took the ID from to read `### Q-NNN · keep-or-drop-NAME-<n>` (QKEYS already reads the heading line, so NEW can carry the slug beside the ID). That is the binding i2 F-a proposed, and the skill already fixes the slug's form.

#### F3. The self-merge floor's "below" class is not in cycle_rules: a directory at an instruction file's name lands

**Severity:** Low
**Location:** `scripts/build-loop.sh:1917-1926`, against `scripts/lib/dev-cycle-read.sh` floor's `below` arm
**Boundary:** B2
**Move:** 11
**Confidence:** High (probe P2)
**Legibility-target:** for-orchestrator-synthesis
**Regression from main:** no
**Evidence (probe P2, executed):** a chore commit adding `AGENTS.md/x` (with no `AGENTS.md` on main) landed. floor refuses this shape for a self-merge (`below`: "a directory there keeps the file from being created", U2c1 i1 security 1). `--check-fix` also refuses it (it is not under `docs/`).

No instruction content changes. The effect is that the instruction file at that name can no longer be created, so this is availability, not injection. I rate it Low rather than Informational because the floor treats the same shape as a refusal. The fix belongs with F1's: an allow-list or a listing covers it, and so does running floor's `below` walk over each path's prefixes.

**Recommendation:** have cycle_rules refuse a path any of whose prefixes `isstart` names, as floor does, or cover it with F1's fix.

#### F4. Informational: case comparison is ASCII-only, so a non-ASCII case variant of a gate or truth path is not refused

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:917` (`lower`), `scripts/build-loop.sh:1918-1925`
**Boundary:** B2
**Move:** 11
**Confidence:** Low (the effect needs a case-insensitive host that folds Unicode; not tested on one)
**Legibility-target:** for-orchestrator-synthesis
**Regression from main:** no. check_line and floor share `lower` (row 754).
**Evidence (probe P2, executed on Linux):** `SKILLS/dev-cycle/x.md` (KELVIN SIGN in place of K) landed. On Linux it is a different directory. On a filesystem that applies Unicode case folding it may alias `skills/dev-cycle/`. `--check-fix` would refuse the path through `pathform`. cycle_rules has no pathform test.

This is row 393's class (macOS Unicode, deferred to a macOS host). The only new thing is the second caller.

**Recommendation:** none for this unit. When row 393 fires, refuse non-`pathform` paths in cycle_rules as `--check-fix` does.

## Untested bypass candidates

- **Truth/gate deny-list:** a Unicode case fold (F4: tested only on Linux), NFD/NFC spelling on HFS+, NTFS trailing-dot and 8.3 short names (git's `core.protectNTFS` refuses these at checkout, but the gate does not). None was tested on a host where it matters.
- **`Applied:` pre-filled with a new ID** (i2's candidate, still not probed). The rule judges only `Asked:`.
- **A brief's `Asked:` ID naming an entry that main gained after the fork:** by reading, `--cycle-diff` counts it as new (its BASE is the merge base) and `--land-cycle` refuses it (its BASE is MAIN_SHA). Not executed.

## Endorsement Claims

- **Claim:** `--land-cycle` writes exactly the tree it judged: commit-tree of `merge_result`'s R with parents MAIN_SHA and HEAD's commit `h`, message `chore_msg B`, moved by update-ref with old value MAIN_SHA or by `merge --ff-only` in W, no hook run.
  **Location:** `scripts/build-loop.sh:2026-2060`, `:1549-1560`
  **Evidence:** read-static (here); the fact-check executed it (three replicates, planted hooks)
  **Verified:** `land_cycle` reads `h` once and passes it (VERDICT[tip]) and R (VERDICT[tree]) to land; land's commit-tree takes those two and MAIN_SHA; probes P1-P3 landed with the expected `landed` fields
  **Not verified:** the ff-only path when W's own config.worktree sets merge options (land clears them per its comment; I did not re-read that block)
  **route: code-fact-check**
- **Claim:** `--land-cycle` refuses when `--main` differs from the default branch's commit at run time, and when the index differs from HEAD's commit.
  **Location:** `scripts/build-loop.sh:2031`, `:2034-2036`
  **Evidence:** executed (U4a test 2; fact-check)
  **Verified:** both refusal texts with exit 2
  **Not verified:** a 64-hex `--main` in a SHA-1 repository (by reading it parses, then refuses at the CAS check)
  **route: code-fact-check**
- **Claim:** `--land-cycle` judges the merge against main rather than the index, so a rename that git pairs into a new questions file, carrying main's answer, refuses.
  **Location:** `scripts/build-loop.sh:2048-2052`
  **Evidence:** executed (U4a test 3; fact-check)
  **Verified:** the refusal line for a Q-001 answer that arrives through the rename
  **Not verified:** a fence pair in the chore's copy capturing a main-side answer line without a rename (same listing; not separately run)
  **route: code-fact-check**
- **Claim:** `log_class`'s chore arm after the refactor reads a record only at `docs/working/cycles/cycle-YYYY-MM-DD.md`, mode 100644, status A or M.
  **Location:** `scripts/build-loop.sh:1737-1745`, `scripts/lib/dev-cycle-read.sh:407`
  **Evidence:** read-static (fact-check executed the `-HHMM` and `-x` record names as other)
  **Verified:** chore_record's conditions and isrecord's regex
  **Not verified:** a record whose blob read fails mid-pipe under pipefail (the comment says it is no record)
  **route: code-fact-check**

The Asked: rule and the truth/gate deny-list do not appear here. F2 is a tested bypass of the first, and F4 and the candidates above are open against the second.

## Primitive sweep

Primitive: git ref write (main moved)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `land()` `update-ref --no-deref … "$NEW" "$MAIN_SHA"` (via `land cycle`, :2057) | S1, S5 | CAS from MAIN_SHA; LAND_MAIN check; cycle_rules; store_check | CAS cleared. Content: F1, F2, F3 |
| `land()` `merge --ff-only NEW` in W | S1 | state gate in W, W's status/untracked-path checks over CHANGED | cleared (shared with --merge, unchanged in this diff apart from the message branch) |

Primitive: commit object write

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `land()` commit-tree with `chore_msg` (:1549) | S6 | branch regex at :2029 (digits and fixed text) | cleared: `printf '%s'` of a regex-matched name |

Primitive: repo blob text into awk/grep

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `asked()` over `cyc_blob` output (:1902) | S2 | 100644 only; FENCE_AWK | cleared as a parser (row 760); F2 is in the rule, not the parser |
| NEW awk over QKEYS output (:2019) | S3 | whole-file ANSWER_AWK refusal first | cleared as a reader; F2 concerns its use |
| `grep -qxF -- "$id" "$t.new"` (:1975) | S2 (digits from BASH_REMATCH) | `-F -x --` | cleared |
| `chore_record` `cat-file blob \| awk -v w="Branch: $1"` (:1742) | S1, S6 | `-v` with a regex-limited name; exact line compare | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence | Regression from main |
|---|---------|----------|----------|----------|------------|---|
| F1 | --land-cycle lands any path outside the deny-list, incl. a loop branch's code via the chore branch's history | Medium | B1, B2 | `scripts/build-loop.sh:2026-2060, 1940` | Medium | No (touches rows 722/745; new: U4a is their trigger, history check proposed) |
| F2 | Added Asked: ID not bound to its entry's brief (entry for Y appended to X passes) | Medium | B3, B4 | `scripts/build-loop.sh:1966-1978` | Medium | No (i2 F-a's slug binding not taken) |
| F3 | Floor's "below" class (a directory at an instruction file's name) not refused | Low | B2 | `scripts/build-loop.sh:1917-1926` | High | No |
| F4 | ASCII-only case folding; Unicode variant of a gate path passes (row 393 class) | Informational | B2 | `scripts/lib/dev-cycle-read.sh:917` | Low | No |

## Overall Assessment

This branch regresses nothing from main. Every new check makes the chore land stricter than main's ungated pr-prep route. The land's commit identity (R, MAIN_SHA, h, chore_msg, CAS) holds by reading and by the fact-check's executed probes. Every earlier security finding (i1 F1-F5, i2 F-a to F-d) is closed as filed. Two Medium residues remain, both in content the land does not judge, and both are fixable in place. The most important is F1: the land never reads HEAD's history, so a chore branch carrying a loop's commits lands that code as `chore`. A reachability check against the other branch heads closes the realistic slip without a path list. F2 is the slug binding i2 proposed for the Asked: rule. If the loop chooses to defer either, the defer belongs with rows 745/764, with U4b's step 9 as the trigger. Verdict: no findings above Medium within the code paths read; endorsement claims are pending execution verification by code-fact-check.

## Goal-Alignment Note

- **User goal:** land unit U4a of the build-loop handoff (claude-workflows) once its review-fix loop is clean.
- **Current task:** security critic on the final confirming pass, whole branch `feat/build-loop-u4a` vs main at b1a6f0a2.
- **Success criterion:** a markdown report saved at the exact path your own prompt names, structured per your skill.
- **Alignment:** saved at `docs/reviews/security-review-2026-10-13-u4a-final.md` with `Commit: b1a6f0a2` first. It contains a verdict on each earlier finding, the trust boundary map and source table, findings with Severity, Location, Evidence, Confidence, Legibility-target and regression status, untested candidates, routed endorsements and the primitive sweep. Probes P1-P3 ran in `/tmp/u4a-secf-*` (removed). No other file was written.
