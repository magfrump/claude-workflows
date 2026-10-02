Commit: 366efd7 (A) / b73069e (B)

# Security Review — dev-cycle pass 28 (the pass-27 fix round)

**Scope:** Partial. A: `git diff b00c057..366efd7 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`, commits 56cc6fe and 366efd7). B: `git diff 7f3e392..b73069e -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`, merge d535260; SKILL.md is identical at b73069e and d535260). Everything else is context only.
**Date:** 2026-10-02
**Based on:** the shared brief `digest-pass28-brief-dc1aa358.md`; Stage-1 context `docs/reviews/code-fact-check-report-digest-pass27.md` (it covers b00c057, so every function cited below was re-read whole at 366efd7: FENCE_AWK `:251-269`, check_brief `:270-301`, check_branch `:302-322`, ANSWER_AWK and check_answer `:343-433`, the default-branch gate `:434-475`); the pass-27 security report, whose probes were rerun.
**Replication:** k=1 (loop pass)

**Probe discipline.** Each probe was one script that started with `set -eu`, made its own `mktemp -d -p sec28/` directory in that same script, and checked `case "$PWD"` before any `git init`, commit or write. Code came from `git archive <commit> | tar -x` into the temp dir. Every process ran under `timeout`, and all of them finished in the foreground. The bats processes visible in `pgrep` belong to another session's suite run in wt-devcycle; I did not start or stop them. Apart from this report, nothing was written to `/workspace` or either worktree. Afterwards `/workspace` was on `main` and both worktrees showed an empty `git status --short`. Probes ran under `LC_ALL=C.utf8`, and the container's awk is mawk 1.3.4.

Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec28/` (`sec28/` below):
- `probe1.sh`/`.log`: bats (`bats.log`), hermeticity lint (`lint.log`), shellcheck, the `--help` range, and `--check-answer` on every real ID at b00c057 vs 366efd7 (d535260's two questions files: 102 IDs; `/workspace` main's: 99 IDs).
- `probe2.sh`/`.log` and `probe2b.sh`/`.log`: crafted `--check-answer` entries, b00c057 vs 366efd7. These cover pass-27 F1/F2/F3/F7 shapes plus new candidates.
- `probe3.sh`/`.log`: `--check-brief` fence shapes; `-G` attribution through a `--no-ff` merge, a squash, a fast-forward of a branch that merged main in, and a `git mv` into `closed/`; `-s` with and without `--diff-merges`; closed/ path forms; a symlinked `closed/`; the glob vs `closed/`; `--check-branch main`.

Legibility-target values: **agent** (the model running the dev-cycle skill acts on the output); **user** (the human who answers questions and reads the roadmap/record); **maintainer** (someone editing the script or skill).

---

## Trust Boundary Map

```
B1 (moved): questions files (recorded user answers, plus text any session writes) → --check-answer awk (heading-bounded entry; FENCE_AWK inside the target only; in a fence only "### Q-NNN " ends it; first "**Status:** " token gate) → keep/drop/done/open/unrecognized → brief Kept:/Applied:/close (SKILL:281-295)
B2 (moved): brief blob on the default branch, briefs/ or briefs/closed/ (any merged change) → --check-brief awk (FENCE_AWK, first unfenced Status:) + git log --first-parent --diff-merges=first-parent -s -G → status + named commit → Done / Ideas / git mv (SKILL:269-280)
B3: brief's branch (name from repo text; dates from whoever commits) → --check-branch (default branch refused unconditionally) → "shows no work", tip date > today+1 ⇒ idle (SKILL:296-307)
B4 (moved): roadmap In flight lines (repo text) + briefs glob → stale-line correction to closed/ → In flight check 1 → Done/Ideas (SKILL:83-92, :266-280)
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | questions-file content (working tree) | runtime-mutable (user, any session, the cycle) | UNTRUSTED toward the close/keep decision. Only the target entry's own recorded answer, once its header is ANSWERED, should decide |
| S2 | brief blob and its history on the default branch | runtime-mutable (any merge) | UNTRUSTED toward Done/dropped and toward the named commit. Accepted by design as a self-report reviewed at merge |
| S3 | brief branch tip commit (committer date and zone) | runtime-mutable (any committer) | UNTRUSTED toward the idle decision |
| S4 | path named in repo text (In flight line, closed/ target) | per cycle | UNTRUSTED toward write sinks (`--check-write`) and the `git mv` |
| S5 | local refs / `origin/HEAD` | host-local / clone-time | trusted toward choosing the default branch |

Untrusted text still reaches decision sinks only through S1 and S2. This round replaces the 3-character fence model with a shared CommonMark-style reader, takes the gate value from the first `**Status:** ` token, and attributes the status commit along first-parent history. Every pass-27 probe now reads as CommonMark does. Two shapes now decide where b00c057 did not: a forged entry quoted in a fence and followed by an ordinary info-string block (F1), and a fence opened on a list-marker line (F2). Both are Low. The other findings are Informational.

## Findings

#### F1. The forged-entry residual (pass-27 F2) is now reached by a common shape: a quoted entry followed by one ordinary ```` ```bash ```` block reads `done`

**Severity:** Low (carried class, wider reach)
**Location:** `scripts/dev-cycle.sh:386-394` (366efd7)
**Boundary:** B1
**Move:** 11 (bypass enumeration)
**Confidence:** High (executed). Preconditions: an `Asked:` ID with no real entry in either questions file (lost, or never written), plus some other entry quoting a copy of that entry in a fence that is followed, before the next heading, by an odd number of fence lines as seen from the forged heading. A single ordinary code block with an info string is enough.
**Legibility-target:** maintainer

**Evidence (verbatim):**
```awk
# scripts/dev-cycle.sh:386-394 (ANSWER_AWK; :395-418 header, answer and END rules follow, read)
heading($0) { count++; inside = (count == 1); infence = 0; header = 0; next }
inside && infence {
  if ($0 ~ /^### Q-[0123456789]+ /) { broken = 1; inside = 0; next }
  if (closes($0)) infence = 0
  next
}
/^(#|##|###) / { inside = 0 }
!inside { next }
opens($0) { infence = 1; next }
```
`probe2b.log`. Q-009 holds `` ```markdown `` / `### Q-018 · forged` / ANSWERED header / `**Answer:** [3]` / `` ``` `` / `Run:` / `` ```bash `` / `echo hi` / `` ``` ``. b00c057 reads `unrecognized Q-018`, and 366efd7 reads `done Q-018`.

`heading()` runs before any fence state, so the quoted heading starts the target entry. From there, the quote's closing `` ``` `` opens a fence, `` ```bash `` does not close it (an info string), and the block's own `` ``` `` closes it, so the reader leaves the entry with no open fence and no `broken`. Under the old 3-character model the `` ```bash `` line closed the fence and the final `` ``` `` left one open, which was fail-closed. The pass-27 shape with nothing after the quote still reads `unrecognized` (Q-022/Q-023 here), and with a real Q-018 present the ID is a duplicate skip. Impact: a brief closes to Done on quoted text. As in pass 27, whoever wrote the quote could write a decisive line directly, so no party gains a capability. But an honest quote of an answered entry, followed by a command block, now decides for a lost ID.

**Recommendation:** As pass-25 F3 and pass-27 F2: track fences over the whole file, so a `### Q-NNN ` line inside any entry's fence is not a heading. That needs only FENCE_AWK's `opens`/`closes` to run for every line, not only inside the target. Add the Q-009 shape as a bats case.

#### F2. A fence opened on a list-marker line (`` - ``` ``) is invisible to FENCE_AWK while its indented closer is seen as an opener, which inverts the fencing of what follows

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:255-268` (FENCE_AWK); used at `:287-292` and `:394` (366efd7)
**Boundary:** B1, B2
**Move:** 11
**Confidence:** Medium-High. The code's reading is executed. The CommonMark reading is derived from the spec: a fence may open inside a list item on the marker line, and a column-0 line that is not a lazy paragraph continuation ends the item. No reference parser is installed in the container, so it was not executed.
**Legibility-target:** maintainer

**Evidence (verbatim):**
```awk
# scripts/dev-cycle.sh:256-263 (closes() :265-268 follows, read)
function lead(l,   i) { i = 1; while (i <= 3 && substr(l, i, 1) == " ") i++; return substr(l, i) }
function run(l, ch,   n) { n = 0; while (substr(l, n + 1, 1) == ch) n++; return n }
function opens(l,   s, ch, n) {
  s = lead(l); ch = substr(s, 1, 1)
  if (ch != "`" && ch != "~") return 0
```
The comment at `:251` says "Code fences, as CommonMark has them".

| Input (executed, `probe2.log` Q-015, `probe3.log` list.md) | 366efd7 | CommonMark reading |
|---|---|---|
| ANSWERED; `` - ``` `` / `  x` / `  ``` ` / `` ``` `` / `**Answer:** [2] drop` / `` ``` `` / `**Answer:** [1] keep` / `` ``` `` | `drop Q-015` (b00c057: `unrecognized`) | keep |
| brief `list.md`: `` - ``` `` / `  x` / `  ``` ` / `` ``` `` / `Status: done` / `` ``` `` / `Status: open` / `` ``` `` | `ok … done` | open |
| Q-024: `1. Run:` / `` - ```bash `` / `  echo` / `  ``` ` / `**Answer:** [1] keep` | `unrecognized` (b00c057: `keep`) | keep (fail-closed loss) |

`opens()` takes `-` as the first character and returns 0, so the list-item fence is never seen. Its closer, indented 2 spaces, passes `lead` and opens a fence, and every fence after that pairs the other way round. This is the same class as pass-27 F1: a quoted line decides the outcome. It is graded Low for the same reason, since the quoter could write the decisive line directly.

**Recommendation:** Either treat a list-marker prefix (`- `, `* `, `+ `, `N. `, `N) `) as leading indentation in `lead()`, or make any fence-shaped line whose pairing is ambiguous end the read as `unrecognized` / skip. Reword the `:251` comment to the subset actually handled. Add the two executed shapes as bats cases.

#### F3. The ANSWERED gate reads the first `**Status:** ` substring, not the first field; it disagrees with questions.sh and regresses one shape that b00c057 read as open

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:395-399`; comment `:349-350` (366efd7)
**Boundary:** B1
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** maintainer

**Evidence (verbatim):**
```awk
# scripts/dev-cycle.sh:395-399 (whole rule)
!header && /^\*\*Needs:\*\*/ {
  header = 1; v = $0; p = index(v, "**Status:** "); answered = 0
  if (p) { v = substr(v, p + 12); q = index(v, " "); if (q) v = substr(v, 1, q - 1); answered = (v == "ANSWERED") }
  next
}
```
The comment says "Its status is the first "**Status:** " field of that line, up to the next space". `questions.sh` (`scripts/questions.sh:171-180`) removes `**`, splits on ` · `, and keeps the last field starting `Status:`, whole.

| Header (`probe2.log`, `probe2b.log`) | b00c057 | 366efd7 | questions.sh status |
|---|---|---|---|
| Q-005 `… · **Status:** OPEN · was set by **Status:** ANSWERED` (pass-27 F3) | drop | **open** (fixed) | OPEN |
| Q-006 `**Needs:** you: judgment (was **Status:** ANSWERED until reopened) · … · **Status:** OPEN` | open | **drop** | OPEN |
| Q-007 `… · **Status:** ANSWERED (2026-10-02)` | open | drop | `ANSWERED (2026-10-02)` (not a valid status) |

Only the header's writer can produce these shapes, and that writer could set ANSWERED directly, so this is Informational, as in pass 27. But Q-006 is a regression against b00c057, and the comment's "field" is not what the code computes.

**Recommendation:** Split the header on ` · ` as questions.sh does and take the field that begins `**Status:** `, compared whole (`v == "**Status:** ANSWERED"`). A malformed field such as Q-007's then reads open, which matches questions.sh's `check`.

#### F4. With the target's fence left open, a non-`### Q-` heading no longer ends the entry, so an answer-shaped line past a later `## ` section is read

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:387-392`; comment `:350-353` (366efd7)
**Boundary:** B1
**Move:** 3 (error path)
**Confidence:** High (executed). Needs a section heading after the target entry. In questions.sh's layout (`## Index`, then `## Open`/`## Answered` and the entries; checked in d535260's files) no section follows the entries, so this is not reachable in that layout.
**Legibility-target:** maintainer

**Evidence (verbatim):** the comment says "(then, or when the entry ends with a fence still open, the answer is unrecognized: lost, never read from another entry)". In `probe2.log`, Q-021 (ANSWERED) holds `` ```text `` / `**Answer:** [1] keep` with the fence left open, followed by `## Notes` / `` ``` `` / `**Answer:** [2] drop` / `` ```bash `` / `echo` / `` ``` ``. It reads `drop Q-021` (b00c057: `unrecognized`). This is consistent with CommonMark, where `## Notes` is fenced text. But it contradicts the comment, and the recorder's own answer (`keep`) is overridden.

**Recommendation:** Inside the target's fence, also end the entry, with `broken`, on `^#{1,2} ` headings, or reword the comment to "never read from another `### Q-` entry".

#### F5. The named commit is not always the default branch's own: a fast-forwarded back-merge names a branch-side merge, and a move into closed/ names the move

**Severity:** Informational (pass-27 F4, narrowed)
**Location:** `scripts/dev-cycle.sh:294-299`; `skills/dev-cycle/SKILL.md:80-82`, `:270-271` (b73069e)
**Boundary:** B2 (S2)
**Move:** 5
**Confidence:** High (executed)
**Legibility-target:** user, agent

**Evidence (verbatim):** the code is `c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a")"`. The skill says "(the commit is the default branch's own commit that last changed a `Status:` line there; for merged work, the merge)". `probe3.log`:

| History | Printed | Commit that set the status |
|---|---|---|
| status set on `feat`, merged `--no-ff` | merge `6be2be3` | the merge brought it in: matches |
| squash merge | squash `6c6722a` | matches |
| main sets `done` (`8482593`); branch `ff` merges main (`bf94aad`); main `--ff-only` to `ff` | `bf94aad` (a commit made on `ff`) | `8482593` |
| `done` set (`7c9f407`), then `git mv` into `closed/` (`871095d`); read on the closed path | `871095d` | `7c9f407` |

After a fast-forward, the first-parent chain is the branch's, so "the default branch's own commit" does not hold. Without `--follow`, a rename re-adds the `Status:` line. Only the status value comes from the blob, so no decision changes. This is provenance in the Done line. The `--no-ff` merge case from pass 27 is fixed.

**Recommendation:** Word SKILL:81-82 and the comment as "the last commit on the default branch's first-parent history whose diff adds or removes a `Status: ` line at this path (a move into `closed/` counts)", or accept the residual explicitly.

#### F6. A closed/ brief whose status is still `open` (or `new`) has no exit from In flight, and step 3 says it "still holds its slot", which contradicts the slot rule

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:83-92`, `:266-280`, `:296-303` (b73069e)
**Boundary:** B4, B2
**Move:** 5
**Confidence:** Medium (read-static; `--check-brief` on closed/ paths is executed in `probe3.log`)
**Legibility-target:** agent

**Evidence (verbatim):**
- Rules: "**A brief holds a slot** when the glob prints `ok` for it … unless it is under `closed/` or `--check-brief` prints `done` or `dropped` for it". The stale-line correction then says "(In flight's check 1 then moves it to Done or Ideas by the state `--check-brief` prints)".
- Step 3: "Until it is answered, the brief still holds its slot."

End to end, for a brief moved to `closed/` outside the cycle:
- With `done` or `dropped`, the flow is clean. Check 1 routes it, "a brief already under `closed/` stays", so nothing is moved twice, and the line points at the existing closed path. No roadmap line is left at a removed path: the correction either points the line at an `ok` closed path or removes it.
- With `open` (moved by hand without setting the status), check 1 does not route it, and steps 2-3 treat it as an open brief. They file keep-or-drop every 14 idle days. A `keep` answer leaves it in In flight permanently, with no slot by the Rules but "still holds its slot" by step 3.
- With `new`, the default branch has no file at the closed path, but `--check-path` printed `ok`: the file is on the cycle's branch only, or is a gitignored file under `docs/working/`, which `--check-path` allows. `new` still has no route, as in pass-27 F5.

Every one of these fails toward asking or leaving the line in place. None of them closes a brief.

**Recommendation:** In check 1, route a closed/ path whose state is `open` or `new` to Ideas as "moved to closed/ outside the cycle, status <state>", with a record note, and exempt closed/ briefs from step 3.

#### F7. In flight is now defined by the slot rule, which excludes a brief that `--check-brief` prints `done` for: the very lines check 1 exists to move

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:266-269` (b73069e)
**Boundary:** B4
**Move:** 5
**Confidence:** Low (wording; the agent probably reads it as intended)
**Legibility-target:** agent

**Evidence (verbatim):** "**In flight**: items whose brief holds a slot (as in the Rules), plus any line being resolved after its brief moved to `closed/`". A brief still in `briefs/` whose merged change set `Status: done` holds no slot (Rules: "unless … `--check-brief` prints `done` or `dropped`") and has not moved. Read literally, its line is not In flight, so check 1 ("`--check-brief` prints `done` … → Done") does not reach it.

**Recommendation:** "items whose brief holds a slot or is not yet moved to Done/Ideas by check 1", or define In flight as "every line naming a brief path", with the slot rule only for the 3-brief cap.

## Pass-27 probe reruns (executed; not endorsements, because the fence reader has F1/F2 and untested candidates)

| Pass-27 shape | b00c057 | 366efd7 | CommonMark |
|---|---|---|---|
| F1 Q-022: `` ````markdown `` quoting `` ``` `` + `[2]`, then `[1]` (`probe2b` Q-001) | drop | keep | keep |
| F1 Q-023: `` ```text `` / `` ```bash `` / `[2]` / `` ``` `` / `[1]` (Q-002) | unrecognized | keep | keep |
| F1 indented (2 spaces) fence around `[2]` (Q-003) | drop | keep | keep |
| `~~~~` quoting `~~~` (Q-010) | drop | keep | keep |
| CRLF `` ```` `` / `` ``` `` (Q-020) | drop | keep | keep |
| `` ```foo`bar `` is not a fence (Q-011) | unrecognized | keep | keep |
| `~~~ a`b` is a fence (Q-012); 4-space indent is not (Q-013); a 4-space closer does not close (Q-014); a tab-indented fence is not one (Q-017); a closer with trailing space/tab closes (Q-019) | keep ×5 | keep ×5 | keep ×5 |
| F7 Q-024: `[1]` then fenced `# run this` (Q-004) | unrecognized | keep | keep |
| F3 Q-020 header shape (Q-005) | drop | open | open |
| F2 pass-27 shape, quote at end (Q-022/Q-023 in probe2b) | unrecognized | unrecognized | — |
| unclosed fence before the next `### Q-` (Q-016) | unrecognized | unrecognized | — |
| entry quoting another entry's heading in a balanced fence (Q-008) | unrecognized | unrecognized | (lost answer; documented) |
| briefs `four.md`, `info.md`, `indent.md` | done ×3 (pass 27) | open ×3 | open ×3 |
| unclosed fence before `Status:` | — | skip | — |

## Untested bypass candidates

- Blockquote fences (`` > ``` ``) with unprefixed lines in between: not run. Prefixed lines are never read as answers, and CommonMark ends the quote at an unprefixed line, so the two readings should agree. Not executed.
- `<pre>`/HTML-block content holding `**Answer:**` or `Status:` lines: not run (CommonMark would not fence it either).
- Fences in list items with content columns of 4 or more (`10. ```` `): not run. Both lines are invisible to FENCE_AWK, so they should pair consistently.
- gawk and busybox awk: not installed, so FENCE_AWK + ANSWER_AWK concatenation ran under mawk only (bats 46/46 and every probe).
- git older than 2.31 (no `--diff-merges`): not run. `c="$(git log …)"` failing under `set -e` would end the check with non-zero status, which the skill records ("A check that exits non-zero … is recorded"). That is fail-closed by reading, not executed.
- Committer zones more than 24 h apart (+14:00 vs an agent at −12:00) can still put an active branch's tip two days after today: not run (the "a day covers time zones" rule).

Because of F1, F2 and these candidates, neither fence reader appears in the Endorsement Claims.

## Endorsement Claims

- **Claim:** `--check-answer` output on every real ID is identical at b00c057 and 366efd7: 102 IDs in d535260's files (3 done, 19 drop, 26 keep, 13 open, 41 unrecognized) and 99 in `/workspace` main's (3 / 19 / 23 / 12 / 42).
  **Location:** `scripts/dev-cycle.sh:343-433`
  **Evidence:** executed
  **Verified:** `probe1.log`; `diff ans-old-*.log ans-new-*.log` empty for both sources.
  **Not verified:** entries written after d535260, and any real entry that becomes ANSWERED with a list-marker fence (F2).
  **route: code-fact-check**
- **Claim:** For the status commit, `-s` does not disable the `-G` filter: with and without `-s`, the lookup returns the same merge `6be2be3` for a status set on a `--no-ff`-merged branch. The squash commit is named for a squash merge. A Status line set inside a merge is attributed to that merge (`--diff-merges=first-parent`; on git 2.39 `--first-parent` alone gives the same answer).
  **Location:** `scripts/dev-cycle.sh:298-299`
  **Evidence:** executed
  **Verified:** `probe3.log` "-G attribution" (git 2.39.5).
  **Not verified:** fast-forward and rename histories (F5); other git versions.
  **route: code-fact-check**
- **Claim:** `--check-brief` reads `briefs/closed/YYYY-MM-DD-<slug>.md` paths. A brief moved there reads `done <move commit>`, and its old path reads `new`. `closed/closed/…`, `closed/../…` and a non-slug name (`NOPE`) are skipped. An absent closed path reads `new`. A `closed/` directory that is a symlink is skipped ("reached through a symlink"), and its target is not read.
  **Location:** `scripts/dev-cycle.sh:276-283`
  **Evidence:** executed
  **Verified:** `probe3.log` "closed-path forms", "symlinked closed dir".
  **Not verified:** a `closed/` file that is a symlink inside a plain `closed/` directory (the same `blocker` path as other briefs, not rerun).
  **route: code-fact-check**
- **Claim:** The `docs/working/briefs/*.md` glob does not list a tracked `briefs/closed/` file, so the slot rule's closed/ exemption only adds to it.
  **Location:** `scripts/dev-cycle.sh:215-230`; `skills/dev-cycle/SKILL.md:83-85`
  **Evidence:** executed
  **Verified:** `probe3.log` "check-path/check-write on closed": the glob printed 9 `briefs/` paths and not `closed/2026-10-02-mv.md`, which `--check-path` printed `ok` for directly.
  **Not verified:** a gitignored file under `briefs/closed/` (the ignored-file branch of `matches`).
- **Claim:** `--check-branch` refuses the default branch by name (`skip main: the default branch`) and reports another branch normally. The `:460` gate guarantees `MAIN` was found by name before `:315` runs.
  **Location:** `scripts/dev-cycle.sh:315`, `:460-462`
  **Evidence:** executed
  **Verified:** `probe3.log` last block; `:460` read.
  **Not verified:** an `origin/HEAD` naming a branch other than `main` while a local `main` exists. There `main` is reported, not refused, by design.
  **route: code-fact-check**
- **Claim:** The A gates hold at 366efd7: bats 46/46, `hermeticity-lint --root .` clean (126 files), shellcheck clean. `--help` prints `sed -n '2,64p'`: 63 lines ending at the Exit paragraph. Line 64 is the blank line before `set -euo pipefail`. 56cc6fe touches only `scripts/dev-cycle.sh` and `test/scripts/dev-cycle.bats`, 366efd7 only `scripts/dev-cycle.sh` (2 lines), and b73069e only `skills/dev-cycle/SKILL.md`.
  **Location:** `scripts/dev-cycle.sh:2-64`, `:127`
  **Evidence:** executed
  **Verified:** `bats.log`, `lint.log`, `probe1.log`, `git show --stat`.
  **Not verified:** the full repo suite.
  **route: code-fact-check**
- **Claim:** The B text now has the final message list keep-or-drop answers read as `unrecognized` as well as unreadable and `open` ones, and idle-by-future-date requires a tip more than a day after today (pass-27 F6's east-zone case, 2026-10-03 vs 2026-10-02, is no longer idle by the wording).
  **Location:** `skills/dev-cycle/SKILL.md:364-366`, `:305-307`
  **Evidence:** read-static
  **Verified:** the sentences as worded at b73069e.
  **Not verified:** that the agent compares dates as calendar days, and zone spreads over 24 h (see Untested).

## Primitive sweep

Primitive: process exec (`git`/`awk` argv) on values from repo text or refs, in the changed lines and their enclosing functions

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:283` `git cat-file -t "$MAIN_SHA:$a"` | S2/S4 path | `pathform` + brief regex (briefs/ or closed/) + `blocker`, hash prefix | cleared: argv only |
| `scripts/dev-cycle.sh:287` `git cat-file blob "$MAIN_SHA:$a" \| awk "$FENCE_AWK"'…'` | S2 blob | same; constant program | cleared as exec; F2 is reader logic |
| `scripts/dev-cycle.sh:298` `git log -1 … -G'^Status: ' "$MAIN_SHA" -- "$a"` | S2 path, history | same, after `--`; constant regex; `GIT_LITERAL_PATHSPECS=1` | cleared; F5 covers its meaning |
| `scripts/dev-cycle.sh:299` `git log -1 --format=%H "$MAIN_SHA" -- "$a"` | S2 path | same | cleared |
| `scripts/dev-cycle.sh:319` `git rev-list --count "$MAIN_SHA..$sha"`, `git log -1 --format=%cs "$sha"` | S3 (hash from show-ref, peeled) | hash only | cleared (unchanged) |
| `scripts/dev-cycle.sh:425` `awk -v id="$a" "$FENCE_AWK$ANSWER_AWK" "$f"` | S1 file, ID | ID `^Q-[0123456789]+$`; constant programs; fixed file names | cleared as exec; F1, F3, F4 are logic |

No eval, deserialization, SQL or HTML sinks in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Forged quoted entry + one info-string block now reads `done` (b00c057: unrecognized) | Low | B1 | `scripts/dev-cycle.sh:386-394` | High |
| F2 | List-marker fence invisible, indented closer opens: Q-015 drop, list.md done (CommonMark: keep, open) | Low | B1, B2 | `scripts/dev-cycle.sh:255-268` | Medium-High |
| F3 | Gate takes first `**Status:** ` substring, not field; Q-006 regresses to drop; disagrees with questions.sh | Informational | B1 | `scripts/dev-cycle.sh:395-399` | High |
| F4 | Unclosed target fence + later `## ` section: answer read past it, contrary to the comment | Informational | B1 | `scripts/dev-cycle.sh:387-392` | High |
| F5 | Named commit after a fast-forwarded back-merge or a move into closed/ is not "the default branch's own" status commit | Informational | B2 | `:294-299`; SKILL:80-82 | High |
| F6 | closed/ brief with `open`/`new` has no exit from In flight; step 3's "holds its slot" contradicts the Rules | Informational | B4, B2 | SKILL:83-92, :266-303 | Medium |
| F7 | In flight defined by slots excludes done-but-unmoved briefs that check 1 must move | Informational | B4 | SKILL:266-269 | Low |

## Overall Assessment

The pass-27 targets are fixed as executed:
- the 4-backtick, info-string, indented, `~~~~` and CRLF fence shapes and the fenced shell-comment shape read as CommonMark does;
- the field-boundary header shape reads `open`;
- a status set in a `--no-ff` merge is attributed to the merge, and `-s` does not suppress the pickaxe;
- `--check-brief` reads `closed/` paths, with the same path, symlink and slug guards;
- `--check-branch` refuses the default branch;
- all 102 real IDs (and main's 99) read unchanged, and the gates are green.

The B-side stale-line flow does not move a closed brief twice, and it leaves no roadmap line pointing at a removed path.

What remains is two Low members of the fence class:
- F1 is the carried forged-entry residual. The new length/info-string rules now let it decide on a common shape where b00c057 failed closed.
- F2 is the list-marker opener.

Both need an honest quote to sit in a specific position, and neither gives any party a capability it lacks. F3–F7 are wording, provenance and bookkeeping gaps that fail toward asking or leaving a line in place, except that F3's Q-006 shape and F4 can each pick an answer the header or recorder did not intend.

None is architectural, and none is Medium or above. The single most useful fix is to track fences over the whole questions file (F1), which also closes pass-27 F2 for good. This review found no further findings within the code paths read, and the endorsement claims are pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

Saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass28.md`, first line `Commit: 366efd7 (A) / b73069e (B)`. It follows the security-reviewer structure: header, Trust Boundary Map and S-table, Findings, Untested bypass candidates, Endorsement Claims (`route: code-fact-check` where they could anchor a rubric row), Primitive sweep, Summary Table and Overall Assessment. A probe-rerun table is added because the brief asked for those results and the skill bars the fence reader from Endorsement Claims. Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target.

The brief's attack list was covered:
- pass 27's fence probes rerun against the shared reader under mawk (rerun table; F1, F2, F4);
- the header field read against questions.sh (F3);
- the first-parent `-G` lookup across merge, squash, fast-forward, rename and `-s` (endorsement 2; F5);
- closed/ reading (endorsement 3);
- the stale-line → closed/ → check 1 flow and the slot rule against the glob (F6, F7; endorsement 4);
- the help range and commits 56cc6fe, 366efd7, b73069e (endorsement 6).

Nothing was committed.
