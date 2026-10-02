Commit: c034a75 (A) / a218ad8 (B)

# Security Review — dev-cycle pass 11 (digest c034a75, skill/docs a218ad8)

**Scope:** Partial, k=1 delta (the pass-10 fix round only). A: `git diff b88a9c4..c034a75 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff 79b1bfe..a218ad8 -- skills/dev-cycle/SKILL.md docs/working/questions.md docs/working/seed-build-loop-handoff.md` (worktree `/workspace/.claude/wt-devcycle`). Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** loop pass 10's k=1 fact-check, `docs/reviews/code-fact-check-report-digest-pass10.md` (Claims 14b/26a: skipped inputs read as absent; Claim 15: "symlink" label on non-regular paths; Claim 20: step 0's inference). Also pass 10's security review (`security-review-2026-10-01-digest-pass10.md`), whose Findings 1–6 this round addresses.

Execution logs (scratch, not committed): `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec11/` holds `probe.sh` + `probe.log` (P1–P7, run against `git show c034a75:scripts/dev-cycle.sh` in `mktemp -d` repos under `timeout`, removed on exit) and `bats.log`. `bats test/scripts/dev-cycle.bats` at the worktree HEAD (9e23ea8, which changes no file under `scripts/` or `test/` since c034a75): 21/21 ok.

Legibility-target values: **maintainer** (someone editing the script or tests), **agent** (the model running the skill), **user** (the human reading Q-103 or the docs).

## Trust Boundary Map

```
B1:         [committed tree: names, file symlinks]          → [inrepo() / skipped(), dev-cycle.sh:92,101]        → [digest sections 1-8 on stdout, via scrub]
B1d (new):  [committed directory symlinks / non-dirs]       → [plaindir() / skipdir(), dev-cycle.sh:95,102]      → [the two globs, :128-129 and :174]
B2:         [section 8 list + Window line]                  → [agent, skill step 0 / record template]            → [cycle record, committed and landed on the default branch]
B4:         [roadmap Now item text]                         → [build brief + stale-brief question, SKILL.md:214-233] → [user-started RPI session / user's answer (human gate)]
B5:         [Build-loop policy line, docs/dev-cycle.md]     → [seed design item 2 (no reader at a218ad8)]        → [future handoff unit's merge decision]
```

Input-source classification:

```
S1: committed names and symlink targets under docs/          — repo content (anyone landing a commit)  — UNTRUSTED for path, read and display sinks
S2: host filesystem reached through a committed symlink      — outside the repo                        — CONFIDENTIAL: names, existence and contents must not reach the record (it is pushed)
S3: roadmap / idea text                                      — runtime-mutable (any commit)            — UNTRUSTED as instructions; data to weigh
S4: `Build-loop policy:` line                                — runtime-mutable                         — UNTRUSTED toward merge decisions (no reader yet)
S5: $QS (SCRIPT_DIR/questions.sh or ~/.claude/scripts)       — deploy-time                             — trusted for exec (unchanged here)
```

c034a75 adds one gate (B1d): a glob now expands only in a directory whose real path is exactly `$ROOT_REAL/<dir>`, closing pass-10 Finding 1 (outside names listed into section 8). It also moves the newline replacement into `skipped()` (closing pass-10 Finding 2). What still crosses from S2 into section 8 is one bit per fixed input name (Finding 2 below). a218ad8 is prose: the one security-relevant change is step 0's new "fix or report the link" instruction (Finding 3).

## Findings

#### 1. Section 2 says "No revisit triggers recorded." when `docs/decisions` itself is skipped and the log probe adds nothing

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:173-175`, `:200-203` (wt-digest, c034a75)
**Boundary:** B1d, B2
**Move:** 3 (error path), 11 (bypass enumeration on the new branch)
**Confidence:** High (executed, probe P1 and P5)
**Legibility-target:** maintainer

**Evidence (verbatim):**
```bash
# scripts/dev-cycle.sh:173-176
decisions_glob=()
if plaindir docs/decisions; then decisions_glob=(docs/decisions/[0-9][0-9][0-9]-*.md); else skipdir docs/decisions || true; fi
n_before_triggers=${#SKIPPED[@]}
for f in "${decisions_glob[@]}"; do
```
(excerpt ends inside the loop; the loop runs to :185, then the log read :186-199, whose `else` arm is `skipped docs/decisions/log.md || true`.)
```bash
# scripts/dev-cycle.sh:200-203
if [[ $found -eq 0 ]]; then
  if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then echo "No revisit triggers read: decision records or the log were skipped as not plain files (section 8)."
  else echo "No revisit triggers recorded."; fi
fi
```
Probe P1 (`docs/decisions` → an outside directory holding `001-a.md` with a trigger, no `log.md`) printed `No revisit triggers recorded.` in section 2 while section 8 listed `- docs/decisions/`. P5 (`docs/decisions` a dangling symlink) printed the same.

`n_before_triggers` is captured after `skipdir docs/decisions` has already appended, so the directory skip is not counted; the only later append is the log probe, which fires only if `log.md` exists through the symlink. This answers the brief's question "can it miss a skip?": yes, exactly the case this round's new directory gate creates. Security impact is bounded: no content or name leaks, and section 8 still names the directory; the cost is that step 2 reads an affirmative "nothing recorded" for suppressed triggers, the skipped-versus-absent distinction this round set out to make. Graded Low on impact (a misleading status line, no protected asset reached), not on likelihood. Test 7 builds exactly this state but asserts nothing about section 2, so it passes with the defect.

**Recommendation:** Move `n_before_triggers=${#SKIPPED[@]}` above line 173 (before `skipdir`). Add `[[ "$output" == *"No revisit triggers read"* ]]` to test 7's first run.

#### 2. A symlinked parent directory still discloses whether fixed-name files exist in the directory it points to

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:101`, called at `:198`, `:226`, `:248`, `:298`, `:317`
**Boundary:** B1, B2
**Move:** 1 (per-consequence trust: S2 toward the record sink), 12 (sweep of existence probes)
**Confidence:** High that the mechanism exists (executed, P2 and P4); low likelihood (needs a committed directory symlink, a cycle run, and a pushed record)
**Legibility-target:** maintainer

**Evidence (verbatim):**
```bash
# scripts/dev-cycle.sh:101
skipped() { if [[ -e "$1" || -L "$1" ]] && ! inrepo "$1"; then SKIPPED+=("${1//$'\n'/ }"); return 0; fi; return 1; }
```
`[[ -e ]]` follows every symlinked component. P2 (`docs/decisions` → an outside directory that contains `log.md`) listed both `- docs/decisions/` and `- docs/decisions/log.md` in section 8; with no `log.md` there (P1), only `- docs/decisions/`. P4 (`docs/working` → outside, containing `questions.md` but no `idea-log.md`) listed `- docs/working/questions.md` and printed "No docs/working/idea-log.md: no ideas seeded" for the other.

So the round's stated property "a symlinked directory is listed once, never its contents" holds for globbed names but not for the fixed input names under it: one bit per name (`log.md`, `questions.md`, `roadmap.md` if `docs` is linked, `idea-log.md`) about a host directory a committer chooses, carried into a committed record. pass-10 Finding 1 (arbitrary names) was Medium; this leak is limited to fixed names, which is why it is graded Low ("minor information leak") on impact. The same mechanism also prints the absent reading ("No docs/working/idea-log.md") for a file whose parent was skipped, a small instance of the Finding 1 class.

**Recommendation:** In `skipped()`, before probing, walk the path's parent directories with `plaindir`; if one fails, record that directory (`skipdir`) and return 0 without probing through it. Then a skipped parent produces one entry and every input under it reads "skipped", never "absent". Extend test 7 with an outside `log.md` and assert that section 8 does not list `docs/decisions/log.md`.

#### 3. Step 0's "fix or report the link" invites resolving a committed symlink whose target may be outside the repo

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:102-103` (wt-devcycle, a218ad8)
**Boundary:** B2
**Move:** 1 (runtime-mutable ⇒ compromise-reachable: the link target is S1-controlled), 2 (implicit sanitization assumption)
**Confidence:** Low. The general rule at `SKILL.md:61-67` forbids reading through a symlink, so the agent has to read "fix" against that rule for the mechanism to fire.
**Legibility-target:** agent

**Evidence (verbatim):**
```markdown
date. If instead it says the records were skipped (section 8), the record exists but is not a
plain file: note that, fix or report the link, and rerun with `--since` the same way.
```
(excerpt is the end of step 0's paragraph, :99-103; the next paragraph, :105, is the digest-failure rule.)

The natural "fix" for a symlinked `cycle-YYYY-MM-DD.md` is to replace it with a plain file holding the record's content. The only source of that content is the link target, which a committer chose and may point at any host file (`~/.ssh/id_ed25519`, a token file). Step 7 then commits and lands the record branch. That re-creates, through the agent, the exfiltration path that `inrepo` and `plaindir` close in the script. The countervailing rule exists ("reads and writes repo files … only by plain paths"), hence Low confidence. The floor rule sets the grade: the mechanism is concrete, and its impact (a host secret committed and pushed) is high.

**Recommendation:** Replace "fix or report the link" with "report the link (one `agent` entry naming it; do not read, copy or rewrite through it)". If a fix is wanted, say what it is: `git rm` the link and leave the record missing.

#### 4. Seed design item 2: a policy line inside an HTML comment, or in `docs/dev-cycle.md` changed by a self-merging loop, is not addressed

**Severity:** Informational
**Location:** `docs/working/seed-build-loop-handoff.md:29-36` (wt-devcycle, a218ad8)
**Boundary:** B5
**Move:** 11 (bypass enumeration on the policy matcher)
**Confidence:** Medium (read-static; no reader exists at a218ad8, so nothing is reachable today)
**Legibility-target:** maintainer (of the future handoff unit)

**Evidence (verbatim):**
```markdown
2. Policy: set only when `docs/dev-cycle.md` has exactly one line, outside code blocks,
   reading exactly `Build-loop policy: self-merge` or `Build-loop policy: review` (a trailing
   CR is ignored); anything else is `review`. Each brief records the resolved value; at merge time a loop
   follows the stricter of its brief and the default branch's current setting.
3. Self-merge only for work outside what later runs follow unreviewed (hooks, enforcement and
   harness settings, instruction files, `skills/`, `workflows/`, `scripts/`, `guides/`,
   `patterns/`, `templates/`, `test/`, `devcontainer-config/`), with a `Paths:` allowlist and
```
(excerpt ends inside item 3, which continues at :36 with the pre-merge diff and no-added-symlink check.)

The fail-closed default (anything else → `review`) is right. Two edges remain for the unit that implements it. (a) "Outside code blocks" leaves HTML comments in: `<!--`, a newline, `Build-loop policy: self-merge`, a newline, `-->` makes one counted line that is invisible in rendered Markdown. (b) Item 3's exclusion list does not name `docs/dev-cycle.md`. That file holds the policy and the idea sources, which later cycles follow. The binary policy limits (b): a self-merging loop cannot raise anything. It could still repoint the idea sources.

**Recommendation:** When the unit is built, count only lines outside fenced blocks *and* HTML comments, or require the line to be the file's first non-heading line. Add `docs/dev-cycle.md` to item 3's exclusion list.

## Untested bypass candidates

Guardrail: `plaindir` / `skipdir` (`scripts/dev-cycle.sh:95,102`). Tested: directory symlink to an outside dir (test 7, P1, P2, P4); a symlinked ancestor (`docs/working` → outside, P4: `docs/working/cycles/` listed, no outside name); a dangling directory symlink and a symlink loop (P5: both listed, no glob); a directory named like a record inside a plain dir (P7: listed via `skipped`).

- **Directory symlink pointing inside the repo** (`docs/decisions -> ../archive/decisions`): not executed. Read-static: `realpath` differs from `$ROOT_REAL/docs/decisions`, so it is skipped (fail-closed).
- **Case-insensitive filesystem** (on-disk `Docs/`, script path `docs/`): not tested (Linux host). Read-static: if `realpath` returns the on-disk case, the comparison fails and the directory is skipped (fail-closed); if it returns the case as given, it passes, which is correct because no symlink is involved.
- **Bind mount or mount point under `docs/`**: not tested. It needs host control, which is below the reachable-environment bar.

Guardrail: newline replacement in `skipped()` (`:101`). Tested: LF (test 7: `- docs/decisions/002-a - FORGED.md` on one line); CR, ESC and U+2028 in names (P6: scrub removes CR, ESC and LS, and every section 8 line keeps its `- ` prefix). Not tested: names that collide after replacement (`a\nb` and `a b` dedupe to one line under `sort -u`). Read-static, that is harmless: both exist and both are skipped.

The guardrails therefore stay out of Endorsement Claims as wholes. The claims below are scoped to single properties.

## Endorsement Claims

- **Claim:** Neither glob in the digest expands unless its directory's real path equals `$ROOT_REAL/<dir>`; on failure the directory alone is appended to section 8.
  **Location:** `scripts/dev-cycle.sh:128-136`, `:173-174`
  **Evidence:** executed
  **Verified:** test 7 (outside `001-private-plan.md`, `SECRET` and `cycle-2026-02-01` absent from output; `- docs/decisions/` and `- docs/working/cycles/` present); P1, P4 and P5 show no outside glob match in any section.
  **Not verified:** fixed-name probes through the same skipped directory (Finding 2 shows they do reach the target).
  **route: code-fact-check**

- **Claim:** Every name `skipped()` appends has LF replaced by a space before it is stored, and section 8 prints each stored name as one `- `-prefixed line.
  **Location:** `scripts/dev-cycle.sh:101`, `:323-329`
  **Evidence:** executed
  **Verified:** test 7's FORGED case; P6 (CR, ESC and U+2028 names: no such byte in section 8, three `- ` lines).
  **Not verified:** `skipdir`'s appended names, which are the two code-constant paths only (read-static, `:135`, `:174`).
  **route: code-fact-check**

- **Claim:** `records_skipped` counts only cycle-record skips: `SKIPPED` has no append site before `:128`.
  **Location:** `scripts/dev-cycle.sh:100-137`
  **Evidence:** executed
  **Verified:** P4 and P5 print "no readable cycle record (one or more were skipped …)"; P3 (readable 2026-01-01 record plus a symlinked 2026-02-20 record) prints "from the last cycle record, docs/working/cycles/cycle-2026-01-01.md". The window is wider, which is the safe direction for review coverage. The skipped newer record appears only in section 8. That part is a correctness note for fact-check: step 0's new sentence does not fire, and its older sentence would say that cycle "skipped step 7".
  **Not verified:** the `--since` branch with a skipped record (the note is not printed, which is by design).
  **route: code-fact-check**

- **Claim:** The seed's policy rule defaults to `review` for every line other than the two exact values, and Q-103 option [2]'s exclusion list now names the same directories as seed item 3. The wording differs once: Q-103 says "harness config" where the seed says "harness settings".
  **Location:** `docs/working/seed-build-loop-handoff.md:29-36`; `docs/working/questions.md:57`
  **Evidence:** read-static
  **Verified:** the a218ad8 text of both files.
  **Not verified:** any implementation (none exists; the handoff unit is deferred).

- **Claim:** The 14-day stale-brief rule only files a `you: judgment` question; it closes nothing and moves nothing without the user, so it adds no autonomous state change.
  **Location:** `skills/dev-cycle/SKILL.md:214-219`
  **Evidence:** read-static
  **Verified:** the In-flight bullet at a218ad8. The only automatic transitions remain "merged → Done" and "user dropped → Ideas".
  **Not verified:** how the agent interpolates `<item>` (roadmap text, S3) into the entry's slug or heading; pass-10 Finding 6's lineage, unchanged here.

## Primitive sweep

Primitive: directory enumeration (shell glob)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:129` cycle records | S1/S2 | `plaindir docs/working/cycles` (:128), then `inrepo` per name | cleared (test 7, P4, P5) |
| `scripts/dev-cycle.sh:174` decision records | S1/S2 | `plaindir docs/decisions`, then `inrepo` per name (:177) | cleared for names; Finding 1 for the status line |

Primitive: existence probe through a path (`[[ -e ]]` / `[[ -L ]]`)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:101` `skipped()` via `:130`, `:177` (globbed names) | S1 | parent passed `plaindir` | cleared |
| `:101` `skipped()` via `:198` log.md, `:226` questions.md, `:248`/`:298` roadmap.md, `:317` idea-log.md | S1/S2 | none on parents | Finding 2 |
| `:102` `skipdir()` via `:135`, `:174` | S1 | the path itself is a code constant | cleared |

Primitive: file read (cat, awk, grep on repo paths). Unchanged by c034a75, and every site is still preceded by `inrepo` on the same literal path (`:177-184`, `:186-196`, `:208`, `:243`, `:293`, `:304`). Cleared, per pass 10's sweep.

Primitive: process exec (`bash "$QS" open`, `:210`). Unchanged; S5 deploy-time. Cleared.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 3 | Step 0's "fix … the link" invites resolving a symlink into a committed record | Medium | B2 | `SKILL.md:102-103` | Low |
| 1 | Section 2 says "No revisit triggers recorded." when `docs/decisions` is skipped | Low | B1d, B2 | `dev-cycle.sh:173-175,200-203` | High |
| 2 | Fixed-name existence probed through a skipped parent directory | Low | B1, B2 | `dev-cycle.sh:101` | High |
| 4 | Seed policy rule: HTML-comment line; `docs/dev-cycle.md` not excluded | Informational | B5 | `seed-build-loop-handoff.md:29-36` | Medium |

## Overall Assessment

The round closes what pass 10 raised. Outside directory listings no longer reach section 8, a newline name cannot forge a line, the non-regular-path label is accurate, Q-103's list and Interim line match the seed, and the final message tells the user to read a brief before starting it. Everything left is fixable in place, and none of it is architectural. The single most important item is Finding 3. It is a one-sentence prose fix, but as written it hands the agent a reason to dereference an attacker-chosen link and commit the result, which is the exact path the script's gates exist to close. Finding 1 is a one-line move of `n_before_triggers` plus a test assertion. Finding 2 is a small change to `skipped()` that makes the round's "never its contents" property hold for fixed names too. Under the loop's "no known issues" bar this delta pass is not clean (one Medium in B, two Lows in A). There are no findings beyond those within the code paths read; endorsement claims are pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-01-digest-pass11.md`, with first line `Commit: c034a75 (A) / a218ad8 (B)`. It follows the security-reviewer structure: header, Trust Boundary Map with source table, anchored findings carrying Severity, Location, Evidence (verbatim), Confidence and Legibility-target, untested bypass candidates, Endorsement Claims routed to code-fact-check, Primitive sweep, Summary Table and Overall Assessment. Toward the user goal (a clean pass, then merge both branches), it answers both of the brief's claim lists. For A, the directory gate and newline fix hold. The section-2 branch misses a directory skip (Finding 1), and the Window branch can coexist with a readable record without misleading in an unsafe direction. For B, the stale-brief rule keeps the human gate, and step 0's new sentence needs one wording change (Finding 3).
