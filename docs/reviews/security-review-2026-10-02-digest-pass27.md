Commit: b00c057 (A) / 7f3e392 (B)

# Security Review — dev-cycle pass 27 (the pass-26 fix round)

**Scope:** Partial. A: `git diff 10c2809..b00c057 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff 875b41f..7f3e392 -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`, merge c7a29b3). Everything else is context only.
**Date:** 2026-10-02
**Based on:** the shared brief `digest-pass27-brief-dc1aa358.md`; the Stage-1 context `docs/reviews/code-fact-check-report-digest-pass26.md` (it covers 10c2809, so every function cited below was re-read whole at b00c057); the pass-26 security, performance and fact-check reports, whose probes were rerun.
**Replication:** k=1 (loop pass)

**Probe discipline.** Each probe was one script starting with `set -eu`, creating its own `mktemp -d -p sec27/` directory in that same script and checking `case "$PWD"` before any `git init`, commit or write. Code came from `git archive <commit> | tar -x` into the temp dir. Every process ran under `timeout`; none of mine is still running (the bats processes visible in `pgrep` belong to another session's `install-host.bats` run in wt-devcycle, as in pass 26; I did not start or stop them). Apart from this report nothing was written to `/workspace` or either worktree; afterwards `/workspace` was on `main` and both worktrees showed an empty `git status --short`. Probes ran with `LC_ALL=C.utf8`.

Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec27/` (below, `sec27/`):
- `probe1.sh`/`.log`: bats 44/44 (`bats.log`), hermeticity lint clean (`lint.log`), shellcheck clean; `--check-answer` on every real ID at 10c2809 vs b00c057 (c7a29b3's two questions files: 102 IDs; `/workspace` main's: 99 IDs), plus a scan for heading-shaped lines inside fences in the real files.
- `probe2.sh`/`.log`: crafted `--check-answer` entries, old (10c2809) vs new (b00c057): pass-26 security F1/F2/F3/F5, fact-check P1 Q-7/Q-8 and P6, performance P4 shapes, plus new fence and gate candidates.
- `probe3.sh`/`.log`: `--check-brief` fence edges, 300 KB blobs, `-G'^Status: '` attribution (later quoted line, mid-line mention, status edited inside a merge, `--no-ff` branch, move into the path, CRLF rewrite), closed/ paths for the stale-line rule, `--check-fix` names, an east-zone tip date.
- `probe4.sh`/`.log`: all seven check calls in an unborn repo (branch `trunk`, and branch `main` unborn), a detached HEAD with no branches, a `trunk`-only repo, a dangling `origin/HEAD`; a tip date after today in the agent's zone.

Legibility-target values: **agent** (the model running the dev-cycle skill acts on the output); **user** (the human who answers questions and reads the roadmap/record); **maintainer** (someone editing the script or skill).

---

## Trust Boundary Map

```
B1 (moved): questions files (recorded user answers, plus text any session writes) → --check-answer awk (heading-bounded entry, in-entry fence by 3-char kind, line-end ANSWERED gate, open fence ⇒ unrecognized) → keep/drop/done/open → brief Kept:/Applied:/close (SKILL:274-288)
B2 (moved): brief blob on the default branch (any merged change) → --check-brief awk (whole blob, first unfenced Status:) + git log -G'^Status: ' → status + named commit → Done / Ideas / git mv to closed/ (SKILL:263-273, :304-305)
B3: repo-text path (in-cycle fix target) → --check-fix ($INSTRUCTION_FILE now agents?) → in-cycle docs edit
B4: brief's branch (name from repo text; commits and committer dates from whoever pushes) → --check-branch → "shows no work" incl. future date ⇒ idle (SKILL:289-299)
B5 (moved): local refs / origin/HEAD → default-branch resolution → by-name gate now only for --check-brief/--check-branch (dev-cycle.sh:424-430)
B6 (moved): roadmap In flight lines (repo text) + briefs glob → stale-line correction / orphan-brief line (SKILL:84-87) → In flight checks
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | questions-file content (working tree) | runtime-mutable (user, any session, the cycle) | UNTRUSTED toward the close/keep decision; only the target entry's own recorded answer, once its header is ANSWERED, should decide |
| S2 | brief blob and its history on the default branch | runtime-mutable (any merge) | UNTRUSTED toward Done/dropped and toward the named commit; accepted by design as a self-report reviewed at merge |
| S3 | brief branch tip commit (committer date and zone) | runtime-mutable (any committer) | UNTRUSTED toward the idle decision |
| S4 | path named in repo text (fix target, In flight line) | per cycle | UNTRUSTED toward write sinks |
| S5 | `refs/remotes/origin/HEAD` | set at clone / `remote set-head` | trusted toward choosing the default branch (remote owner's choice) |
| S6 | local refs `main`/`master`, HEAD state | host-local | trusted |

Untrusted text still reaches decision sinks only through S1 and S2. This round fixes pass 26's regression: headings bound entries again, so an unclosed fence no longer carries the read into the next entry, and every pass-26 probe shape now reads a skip, `open` or `unrecognized`. What remains on B1/B2 is the 3-character fence model, which is narrower than CommonMark (F1). The `-G` commit and the B-side stale-line rule are bookkeeping gaps, not decision bypasses (F4, F5).

## Findings

#### F1. Fence handling is narrower than CommonMark: a 4+-character fence closes at the first 3-character line, an info-string line closes a fence, and indented fences are not fences — so quoted `**Answer:**` / `Status:` lines are read

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:268-269` (check_brief awk), `:365-366` (ANSWER_AWK) (b00c057)
**Boundary:** B1, B2
**Move:** 11 (bypass enumeration)
**Confidence:** High on the mechanism (executed). Likelihood low-to-moderate: a 4-backtick fence is the ordinary way to quote markdown that itself contains a fence, for example an agent's note quoting an answer format above the recorder's answer line.
**Legibility-target:** maintainer

**Evidence (verbatim):**
```awk
# scripts/dev-cycle.sh:365-367 (ANSWER_AWK; :361-364 heading/entry-end rules precede, :368-386 answer block and END follow, read)
fence != "" { if (substr($0, 1, 3) == fence) fence = ""; next }
/^(```|~~~)/ { fence = substr($0, 1, 3); next }
!header && /^\*\*Needs:\*\*/ { header = 1; answered = ($0 ~ / \*\*Status:\*\* ANSWERED$/); next }
```
The same two fence lines are at `:268-269` in check_brief (whole program `:265-270`, read).

Executed (`probe2.log`, `probe3.log`):

| Input | b00c057 reads | CommonMark reading |
|---|---|---|
| Q-022: ANSWERED; ```` ````markdown ```` / ```` ``` ```` / `**Answer:** [2] drop` / ```` ``` ```` / ```` ```` ```` / `**Answer:** [1] keep` | `drop Q-022` | keep (the 4-backtick block holds everything up to ```` ```` ````) |
| brief `four.md`: ```` ````markdown ```` / ```` ``` ```` / `Status: done` / … / `Status: open` | `ok … done` | open |
| brief `info.md`: ```` ```text ```` / ```` ```bash ```` / `Status: done` / ```` ``` ```` / `Status: open` | `ok … done` | open (a closing fence takes no info string) |
| brief `indent.md`: two-space-indented ```` ``` ```` around `Status: done` | `ok … done` | open (up to 3 spaces of indent still opens a fence) |
| Q-023: ```` ```text ```` / ```` ```bash ```` / `**Answer:** [2] drop` / ```` ``` ```` / `**Answer:** [1] keep` | `unrecognized` (the final fence stays open: fail-safe) | keep |

The pass-26 F3 case (`~~~` quoting ```` ``` ````) is fixed: `tilde.md` reads `open`, Q-013 reads `keep`. These are the remaining members of the same class. A wrong `drop`/`done` on B1 closes a brief on quoted text; on B2 it moves a brief to Done. Graded Low, consistent with pass-26 F3: the writer of the quoted text could equally write the decisive line directly, so no party gains a capability, but an honest quote can decide the outcome.

**Recommendation:** Record the opening run (character and length ≥ 3, up to 3 leading spaces) and close only on a line of the same character with at least that length followed only by whitespace. Minimal alternative in ANSWER_AWK: any fence-shaped line inside an open fence that is not an exact close makes the answer `unrecognized`. Add bats cases for the 4-backtick and info-string shapes.

#### F2. The forged-entry case survives when the quoting entry's fences balance (pass-26 F5, narrowed, carried)

**Severity:** Low (carried)
**Location:** `scripts/dev-cycle.sh:362-366` (b00c057)
**Boundary:** B1
**Move:** 11
**Confidence:** High (executed). Needs an Asked: ID with no real entry in either questions file (a lost or never-written entry), plus a quoted copy whose following fence lines balance before the next heading.
**Legibility-target:** maintainer

**Evidence (verbatim):** `heading($0) { count++; inside = (count == 1); fence = ""; header = 0; next }` (`:362`). Q-091 quotes, in a fence, `### Q-018 · forged` / an ANSWERED header / `**Answer:** [3]`, then closes it and has two more fenced blocks before the next heading: `done Q-018` (old and new, `probe2.log`). The pass-26 shape with nothing after the quote (Q-017) now reads `unrecognized` (old: `done`), and with a real entry present the ID is a duplicate skip (Q-007, Q-031, Q-016).

**Recommendation:** As pass-25 F3: track fences over the whole file and ignore a heading inside another entry's fence, or require the matched heading to sit outside any fence opened since the previous real heading.

#### F3. The header gate is anchored at the line end but not at a field boundary

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:367` (b00c057)
**Boundary:** B1
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** maintainer

**Evidence (verbatim):** `answered = ($0 ~ / \*\*Status:\*\* ANSWERED$/)`. Probe Q-020's header `**Needs:** you: judgment · **Opened:** 2026-10-01 · **Status:** OPEN · was set by **Status:** ANSWERED` reads `drop Q-020`. `questions.sh` (`scripts/questions.sh:174-179`) splits the header on ` · ` and takes the field starting `Status:` (here `OPEN`), so the two readers disagree. The pass-26 F2 line `… **Status:** OPEN (was **Status:** ANSWERED earlier)` now reads `open` (Q-010), and a trailing space reads `open` (Q-021): both fail-closed. Graded Informational: only the header's writer can produce this, and that writer could set ANSWERED directly.

**Recommendation:** Use pass-26 F2's field anchor, `/ · \*\*Status:\*\* ANSWERED$/`, which matches questions.sh's ` · ` split.

#### F4. The `-G'^Status: '` commit is "last commit adding or removing any line starting `Status: `", which is not the commit that set the status in four executed cases

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:271-274` (b00c057); `skills/dev-cycle/SKILL.md:263-265`, `:304-305` (7f3e392)
**Boundary:** B2 (S2)
**Move:** 5 (what does the rule not cover?)
**Confidence:** High (executed)
**Legibility-target:** user, agent

**Evidence (verbatim):**
- Code: `c="$(git log -1 --format=%H -G'^Status: ' "$MAIN_SHA" -- "$a")"` with the comment "The commit on the default branch that last added or removed a Status line in this file (not a later edit to its Asked:/Kept: lines, nor the merge)."
- Skill: "naming the commit it prints (the last commit on the default branch that changed the brief's Status line)".

`probe3.log`:

| History on main | Printed | Commit that set `done` |
|---|---|---|
| create (`open`) → set `done` → later commit appends a fenced `Status: done` quote | the quote commit `6056eb7` | `6dcf136` |
| `Status: open` → `done` edited inside a `--no-ff --no-commit` merge | the creation commit `5e8629d` (it added `Status: open`) | the merge `a79ed2b` |
| file created in `closed/` with `done`, then `git mv` into `briefs/` | the move `d2d3092` | the creation `748669b` |
| LF → CRLF rewrite of the whole file | the CRLF commit `6acf220` | `46e5569` |
| status set on a branch, merged `--no-ff` | the branch commit `c05cc23` (correct) | same |
| later line `note: Status: dropped is mentioned` (mid-line) | `8ce3220` (correct; `^` anchors per line) | same |

The pickaxe sees any `^Status: ` line (fenced or not, the first or a later one), any rewrite, and a rename into the path (no `--follow`), and it does not diff merges, so a status set in a merge is attributed to whatever earlier commit last touched a `Status:` line. The status value itself still comes from the blob, so no decision changes; the Done line names a wrong commit as provenance. The bats test (`dev-cycle.bats` "reads a large brief whole and names the commit") covers only the later-`Asked:` case.

**Recommendation:** Word the code comment and SKILL:264-265 as what is computed ("the last commit whose diff adds or removes a line starting `Status: `"), or accept the residual explicitly. An exact alternative is to walk `git log --format=%H -- <path>` and stop at the oldest commit whose reader output equals the current one, at a cost per brief.

#### F5. The stale-line rule points an In flight line at `briefs/closed/`, which In flight's own check refuses every cycle; nothing moves it out of In flight

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:84-87`, `:261-273` (7f3e392); `scripts/dev-cycle.sh:259` (b00c057)
**Boundary:** B6, B2
**Move:** 5
**Confidence:** Medium (the check outputs are executed; the agent's reading of the rule is read-static)
**Legibility-target:** agent

**Evidence (verbatim):**
- Rule: "A roadmap In flight path that `--check-path` skips (the brief moved, or never landed) is recorded and its line corrected: pointed at `briefs/closed/<same name>` if `--check-path` prints `ok` there, otherwise removed. A brief that holds a slot but that no In flight line names gets one, so In flight's checks reach it."
- `probe3.log` B4, after a brief is moved to `closed/` outside the cycle: `--check-path` prints `ok docs/working/briefs/closed/2026-10-02-r.md` and `skip docs/working/briefs/2026-10-02-r.md: no tracked file …`; `--check-brief` on the closed path prints `skip …: not an open build brief (docs/working/briefs/YYYY-MM-DD-<slug>.md)`, and on the old path `ok … new`.

The corrected line still sits under In flight ("items with an open build brief"). In flight step 1 runs `--check-brief` on it and gets the same skip every cycle, which is recorded each time. Step 1 also has no route for `new`, and no check mode reads a closed brief's status, so the rule cannot tell whether the brief belongs in Done or Ideas. Nothing is closed wrongly (fail-closed), and the line holds no slot because the `briefs/*.md` glob does not list `closed/`. The result is a permanent skip line plus a roadmap item stuck in In flight.

On the brief's question about which check proves that no In flight line names a brief: none does. The orphan rule is the agent's own string match of the glob's `ok` paths against the roadmap's In flight paths (S4 repo text). The executed paths fail benignly. A line in a non-canonical form (for example `./docs/…`) is skipped by `pathform` and removed, and the orphan rule then re-adds a canonical line. A duplicate line repeats the per-brief steps, but step 3 is gated on that brief's own `Asked:` line, so it files no second question.

**Recommendation:** Say where the corrected line goes: out of In flight, into Done or Ideas as "closed outside the cycle (status not read)", with a record note. Alternatively, let `--check-brief` read `briefs/closed/` paths so the status can route it.

#### F6. A tip date after today counts as idle, and an east-of-agent committer produces one on an active branch

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:296-299` (7f3e392); `scripts/dev-cycle.sh:295` (b00c057)
**Boundary:** B4 (S3)
**Move:** 5
**Confidence:** High (executed)
**Legibility-target:** agent, user

**Evidence (verbatim):** "A tip date after today is recorded and counts as idle (the committer sets the date)." `probe4.log` Z: a commit at `2026-10-03T13:00:00+14:00` (2026-10-02 16:00 at −07:00, the user's zone in c7a29b3's merge) prints `ok east … 1 2026-10-03`. That is after the agent's today (2026-10-02), so a branch committed to minutes ago counts as idle. Step 3 still requires 14 days since `Kept:` or the brief's date. The effect is one unneeded keep-or-drop question. It fails toward asking the user and never closes anything. This change fixes pass-26 F6, where a far-future date never read idle.

**Recommendation:** Count as idle only a date more than one day after today. Optionally have `--check-branch` print the date in UTC (`%cd` with `--date=format-local:%F` under `TZ=UTC`).

#### F7. `/^(#|##|###) /` ends the target entry on a shell comment inside a fenced paste block

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:363`, `:383-385` (b00c057)
**Boundary:** B1
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** maintainer, agent

**Evidence (verbatim):** `/^(#|##|###) / { if (inside && fence != "") broken = 1; inside = 0 }`. Real Q-084 (a `you: terminal` entry in c7a29b3's and main's `questions.md`) has six lines such as `# 1. a clean session: launch, make one commit, exit claude -> expect exit 0 and no WARNING` inside its fence (`probe1.log`). Q-024 (ANSWERED, `**Answer:** [1] keep`, then a fenced `# run this`) reads `unrecognized` (old: `keep`). This fails closed, and the code comment's "which can only lose an answer" holds in every probe. Keep-or-drop entries are cycle-written and rarely hold paste blocks. The cost is a re-ask whenever a recorder adds one.

**Recommendation:** End the entry on the questions.sh heading grammar (`^### Q-[0-9]+ · `) at any fence depth, and on other `#`/`##`/`###` headings only outside a fence. That keeps the pass-26 fix (headings checked before fences).

## Untested bypass candidates

- Fence line indented with a tab, and a blockquote-prefixed fence (`> ```` ``` ````): not run. Both are the same pattern miss as F1's indented case, and F1 is already filed for this guardrail.
- `~~~~` (4 tildes): not run separately. It takes the same `substr($0,1,3)` path as the executed 4-backtick case.
- `-G` under a repo config `log.diffMerges`/`diff.external`: not run. That config is host-local, not repo text.

Because of F1 and these candidates, the fence handlers appear in no Endorsement Claim.

## Endorsement Claims

- **Claim:** Every pass-26 probe shape now reads a skip, `open` or `unrecognized` at b00c057, never a keep/drop/done taken from another entry: sec F1 / perf P4 Q-001 (with a real duplicate) → dup skip; Q-002 → open; fact-check P1 Q-7 → dup skip; P6 (archive Q-031) → dup skip; sec F5 Q-017 → `unrecognized`; Q-030 (answer then fenced quoted heading) → `unrecognized`.
  **Location:** `scripts/dev-cycle.sh:341-386`
  **Evidence:** executed
  **Verified:** `probe2.log`, old vs new columns; the bats case "an unclosed fence stays inside its entry" covers Q-1 alone → `unrecognized`.
  **Not verified:** the balanced-fence forged shape (F2) and the 4-backtick shape (F1), which still decide.
  **route: code-fact-check**
- **Claim:** `--check-answer` output on every real ID is identical at 10c2809 and b00c057: 102 IDs in c7a29b3's files (3 done, 19 drop, 26 keep, 13 open, 41 unrecognized) and 99 in `/workspace` main's.
  **Location:** `scripts/dev-cycle.sh:341-401`
  **Evidence:** executed
  **Verified:** `probe1.log`, `diff ans-old-*.log ans-new-*.log` empty for both sources.
  **Not verified:** entries written after c7a29b3, and Q-084 once it becomes ANSWERED (F7).
  **route: code-fact-check**
- **Claim:** `--check-brief` returns rc 0 with a status line for 300 KB blobs whose `Status:` is at the head or after 300 KB, together with a normal brief in the same call.
  **Location:** `scripts/dev-cycle.sh:265-270`
  **Evidence:** executed
  **Verified:** `probe3.log` B2: `ok … big.md open`, `ok … bigtail.md done`, `ok … plain.md open`, rc=0.
  **Not verified:** blobs with NUL bytes or no trailing newline.
  **route: code-fact-check**
- **Claim:** With no default branch found by name, `--check-path` (plain and glob), `--check-write`, `--check-fix` and `--check-answer` each exit 0 with their normal answer. `--check-brief` and `--check-branch` exit 1 with "needs a default branch". This holds in an unborn repo (on `trunk`, and on an unborn `main`), on a detached HEAD with no branches, in a `trunk`-only repo, and with a dangling `origin/HEAD`. Among the check modes, `MAIN_SHA` is read only by check_brief (`:261`, `:265`, `:273-274`) and check_branch (`:295`).
  **Location:** `scripts/dev-cycle.sh:424-430`
  **Evidence:** executed
  **Verified:** `probe4.log` U1, U2, D1, D2, D3 (35 calls); `grep -n MAIN_SHA` at b00c057.
  **Not verified:** the digest's own exit code in the unborn repo. The probe captured its stderr ("Could not resolve a default branch …"), but its rc capture inside `$(…)` was wrong.
  **route: code-fact-check**
- **Claim:** The mixed-kind fence case is fixed in both readers: a `~~~` block quoting a ```` ``` ```` line no longer exposes a quoted line (`tilde.md` → `open`, Q-013 → `keep`). An unclosed fence before the status reads as a skip.
  **Location:** `scripts/dev-cycle.sh:268-269`, `:365-366`
  **Evidence:** executed
  **Verified:** `probe2.log`, `probe3.log` B1.
  **Not verified:** the longer-fence, info-string and indented shapes; see F1.
- **Claim:** `$INSTRUCTION_FILE` now refuses `AGENT.md`, `agent.md` and `Agent.Override.md`, and still refuses `AGENTS.md`, `agents.local.md`, `SKILL.md` and `Gemini.md`. The anchors hold: `agentx.md`, `aagent.md`, `CLAUDE-old.md` and `claude..md` read `ok`.
  **Location:** `scripts/dev-cycle.sh:307`, `:315`
  **Evidence:** executed
  **Verified:** `probe3.log` B5, 12 names.
  **Not verified:** bash versions other than the container's.
  **route: code-fact-check**
- **Claim:** The A gates hold at b00c057: bats 44/44, `hermeticity-lint --root .` reports no unstubbed network spawns, and shellcheck is clean. b00c057 touches only `scripts/dev-cycle.sh` and `test/scripts/dev-cycle.bats`.
  **Location:** `test/scripts/dev-cycle.bats`, `scripts/dev-cycle.sh`
  **Evidence:** executed
  **Verified:** `bats.log`, `lint.log`, `probe1.log`, and `git show --stat b00c057`.
  **Not verified:** the full repo suite.
  **route: code-fact-check**
- **Claim:** The final message now lists each brief holding a slot (skip-held ones included), and keep-or-drop IDs still `open`, with their brief. This addresses pass-26 F8's unasked skip-held slot at the text level.
  **Location:** `skills/dev-cycle/SKILL.md:356-360`, `:278-281`, `:162`, `:340`
  **Evidence:** read-static
  **Verified:** the sentences as worded at 7f3e392.
  **Not verified:** that the agent derives "holding a slot" from the glob plus `--check-brief` rather than from In flight lines.

## Primitive sweep

Primitive: process exec (`git`/`awk` argv) on values from repo text or refs, in the changed lines and their enclosing functions

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:265` `git cat-file blob "$MAIN_SHA:$a"` | S2 path | `pathform` + `isbrief` + `blocker`, hash prefix | cleared: argv only; F1 is the reader logic |
| `scripts/dev-cycle.sh:273` `git log -1 --format=%H -G'^Status: ' "$MAIN_SHA" -- "$a"` | S2 path, history | same, after `--`; constant regex | cleared: argv only; F4 covers its meaning |
| `scripts/dev-cycle.sh:274` `git log -1 --format=%H "$MAIN_SHA" -- "$a"` | S2 path | same | cleared |
| `scripts/dev-cycle.sh:295` `git rev-list --count "$MAIN_SHA..$sha"`, `git log -1 --format=%cs "$sha"` | S3 (hash from show-ref, peeled) | hash only | cleared; F6 covers the date |
| `scripts/dev-cycle.sh:393` `awk -v id="$a" "$ANSWER_AWK" "$f"` | S1 file, ID | ID `^Q-[0123456789]+$`, constant program | cleared; F1–F3 and F7 are logic findings |

No eval, deserialization, SQL or HTML sinks in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | 4+-char fences, info-string closes and indented fences expose quoted `**Answer:**`/`Status:` lines (Q-022 drop; briefs four/info/indent done) | Low | B1, B2 | `scripts/dev-cycle.sh:268-269`, `:365-366` | High |
| F2 | Forged entry with balanced trailing fences still reads when no real entry exists (pass-26 F5, narrowed) | Low | B1 | `scripts/dev-cycle.sh:362-366` | High |
| F3 | Gate anchored at line end, not at a ` · ` field; disagrees with questions.sh | Informational | B1 | `scripts/dev-cycle.sh:367` | High |
| F4 | `-G` names later quote/rewrite/move commits; misses a status set in a merge; skill and comment over-promise | Informational | B2 | `scripts/dev-cycle.sh:271-274`; SKILL:263-265 | High |
| F5 | Stale-line rule leaves a closed/ line in In flight, skipped by `--check-brief` every cycle; no check proves "no In flight line names it" | Informational | B6, B2 | SKILL:84-87, :261-273 | Medium |
| F6 | Future tip date ⇒ idle; an east-zone commit on an active branch reads tomorrow | Informational | B4 | SKILL:296-299 | High |
| F7 | Shell comments in a fenced paste block end the entry (real Q-084 shape) → unrecognized | Informational | B1 | `scripts/dev-cycle.sh:363` | High |

## Overall Assessment

The pass-26 fixes hold on everything they targeted:
- Headings bound entries again, and an open fence at the entry's end reads `unrecognized`. Every pass-26 fence probe (security F1/F5, fact-check P1/P6, performance P4) now reads a skip, `open` or `unrecognized`.
- Fences close only by kind, so the mixed `~~~`/```` ``` ```` case is fixed.
- The ANSWERED gate is anchored at the line end, and the pass-26 F2 shape reads `open`.
- `--check-brief` reads 300 KB blobs without the SIGPIPE abort.
- The four non-brief modes answer in unborn, detached and branchless repos. Only `--check-brief` and `--check-branch` refuse, and only those two read `MAIN_SHA`.
- All 102 real IDs read as before.

What remains is hardening:
- F1 is the rest of the fence class: CommonMark's length rule, the info-string rule and indentation. It can still let a quoted line decide.
- F2 is the carried forged-entry residual.
- F3–F7 are bookkeeping and wording gaps that fail toward asking or recording, never toward closing.

None is architectural, and none blocks the clean pass on security grounds. F1 is the item most worth a small fix (a length-aware fence close). This review found no further findings within the code paths read. The endorsement claims are pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

Saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass27.md`, with first line `Commit: b00c057 (A) / 7f3e392 (B)`. It follows the security-reviewer structure: header, Trust Boundary Map and S-table, Findings, Untested bypass candidates, Endorsement Claims (`route: code-fact-check` where they could anchor a rubric row), Primitive sweep, Summary Table and Overall Assessment. Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. The brief's attack list was covered:
- pass 26's attacks rerun against the new fence handling (endorsement 1; F1, F2, F7);
- the anchored ANSWERED gate (F3);
- the whole-blob brief reader (endorsement 3) and its `-G` commit (F4);
- the narrowed default-branch gate in unborn and detached repos (endorsement 4);
- the orphan and stale-line rules (F5), the future-date rule (F6), and commits b00c057 and 7f3e392 (endorsement 7).

Nothing was committed.
