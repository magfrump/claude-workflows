Commit: 4dc84ce4

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1c (claude-workflows, branch feat/build-loop-u1c)
**Scope:** Submitted claims 36-43 (Stage 2.5, U1c final confirming pass, iteration 3) from performance-reviewer, architecture-review, api-consistency-reviewer and security-reviewer; scripts/build-loop.sh at 4dc84ce4 (plus scripts/lib/dev-cycle-read.sh and scripts/dev-cycle.sh where a claim reaches them). No harvested claims in this report.
**Checked:** 2026-10-05
**Total claims checked:** 9 (claim 40 split into 40a and 40b because the parts earn different verdicts)
**Summary:** 6 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries). No submitted claim matches a logged pattern. Claim 36 quotes a measured time, which is close to the logged "specific measured value" class. Its 0.18 s did not reproduce here (about 0.07-0.09 s), but a wall-clock time depends on the machine, so this is not a fabrication.

All probes ran under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/` with git 2.39.5, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, `LC_ALL=C` and TMPDIR unset. Every process ran under `timeout`. Each probe sources `common.sh`, which holds the fixture helpers copied from `test/lib/build-loop-fixtures.bash`. The script under test is `/workspace/.claude/wt-build-loop-u1c/scripts/build-loop.sh`. Probe40 checked that it is byte-identical to `git archive 4dc84ce4`. For the differential claim 40, the c143b929 and 4dc84ce4 versions of `scripts/` were extracted with `git archive` into `tree-c143b929/` and `tree-4dc84ce4/`. At HEAD, `bats test/scripts/build-loop-read.bats` gave 16/16 ok (`bats.log`; cwd the worktree; exit 0; 2026-10-05T17:53:52Z).

Legibility-target values: **maintainer** (someone editing build-loop.sh or its lib), **agent** (the orchestrator model that reads `--status`/`--settings` output).

---

## Submitted Claims

## Claim 36: "At 2000 closed briefs `--status` with one argument takes about 0.18 s, and 21 MB of closed-brief text adds no measurable time."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:301-315`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers one-argument `--status` wall time on this 16-core host with 2000 closed briefs that read `Status: done` (113,786 bytes, then 21,731,786 bytes), in a packed repo and a loose-object repo. It does not establish the 0.18 s figure on the critic's host. It also does not cover cost when closed briefs still carry a `Status: open` line, because each of those is read by `brief_fields` (measured: about 10 ms each).

The scaling mechanism holds. Only files that match one `git grep` reach `brief_fields`:

```bash
# scripts/build-loop.sh:306-310
  list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"
  while IFS= read -r f; do
    f="${f#"$MAIN_SHA":}"
    if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
    [[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue
```
(excerpt ends :310; enclosing shared_branches() continues to :315 — read)

Executed results:
- Loose objects (`probe36.log`), 5 runs each. With 2000 small closed briefs: 0.084-0.088 s. After growing them to 21.7 MB: 0.103-0.114 s. With no closed briefs: 0.046-0.048 s. In this layout the 21 MB added about 20-28 ms, and the run ranges do not overlap.
- Packed with `git gc` (`probe36b.log`), 15 interleaved runs. Small: median 74 ms (67-82). 21.7 MB: median 73 ms (63-83). No measurable difference.
- Residue (`probe36c.log`): 200 closed briefs with `Status: open` took 2017 ms.

A more precise version of the claim would read: "about 0.1 s here (0.18 s on the critic's host); 21 MB of closed-brief text adds no measurable time in a packed repo and about 25 ms with loose objects."

**Evidence:** `scripts/build-loop.sh:301-315`, `scripts/lib/dev-cycle-read.sh:289-312`. Commands: `timeout 590 bash probe36.sh > probe36.log 2>&1` (exit 0, 2026-10-05T17:52:41Z), `timeout 590 bash probe36b.sh > probe36b.log 2>&1` (exit 0, 2026-10-05T17:53:04Z), `timeout 400 bash probe36c.sh > probe36c.log 2>&1` (exit 0, 2026-10-05T17:53:15Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe36.log`, `.../probe36b.log`, `.../probe36c.log`

---

## Claim 37: "Moving the guard to the top of `status_line` gives the right answer on every path. `check_brief` runs in a subshell, so the only `BRIEF` writer after the guard is `brief_fields "$a"` itself."

**Submitted by:** architecture-review
**Location:** `scripts/build-loop.sh:316-355`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which `BRIEF` contents `status_line` judges on every return path (skip, new, Branch/Dispatched/F31 skips, absent, marker), for one or several arguments. It does not establish that the guard's shared set is itself correct: under repo `color.ui=always` or `color.grep=always`, `shared_branches` finds nothing and F31 is off (see claims 41 and 43).

The guard is the first statement, and every later call that could write `BRIEF` runs in a command substitution, except `brief_fields "$a"`:

```bash
# scripts/build-loop.sh:318-323
  [[ -n "$SHARED_BRANCHES" ]] || shared_branches  # first: it reads other briefs into BRIEF
  out="$(check_brief "$a")"
  [[ "$out" == "ok "* ]] || { echo "$out"; return; }
  read -r _ _ st _ <<<"$out"
  if [[ "$st" == new ]]; then echo "ok $a new review - absent - - 0"; return; fi
  brief_fields "$a" || { echo "skip $a: the brief is not read"; return; }
```
(excerpt ends :323; enclosing status_line() continues to :352 — read)

The rest of the function writes nothing to `BRIEF`: `check_branch` (:336), `marker_kind` (:344) and `lower` (:333) all run inside `$(...)`. `brief_fields` starts with `BRIEF=(); BRIEF_ODD=""` (`scripts/lib/dev-cycle-read.sh:293`), so a leftover value cannot survive into a later read. The two returns before :323 (:320, :322) do not read `BRIEF`.

Executed (`probe37.log`): the queried brief `a` (self-merge, Dispatched 3) came out as `ok ... open self-merge feat/a absent - - 3`. That held even though `shared_branches` read `zz` (Dispatched 7) and `closed/...-zzz` (Dispatched 9) last, and for argument orders `a`, `zz a`, `a zz`, `docs/x.md a` and `new a`. `probe37b.log`: two open briefs that both name the odd keys `@`, `*` or `x]y` still produce the F31 skip with exit 0.

**Evidence:** `scripts/build-loop.sh:300-352`, `scripts/lib/dev-cycle-read.sh:289-312`. Commands: `timeout 300 bash probe37.sh > probe37.log 2>&1` (exit 0, 2026-10-05T17:53:34Z), `timeout 200 bash probe37b.sh > probe37b.log 2>&1` (exit 0, ~2026-10-05T17:53:40Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe37.log`, `.../probe37b.log`

---

## Claim 38: "C23's `constraint(s)` matches dev-cycle.sh's `(s)` convention exactly."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/build-loop.sh:265`, `scripts/dev-cycle.sh:259`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plural form after a count: a count, then the noun with `(s)` attached. It does not establish that every count-plus-noun output in build-loop.sh uses `(s)`. The one other count message, `it has N parents` (:284), prints only for N of 2 or more.

```bash
# scripts/build-loop.sh:265
          else CONSTRAINTS_LINE="constraints none-hard: $f on the default branch has $l1 soft constraint(s) and no hard one (H1: with a success: line)"; fi ;;
```
```bash
# scripts/dev-cycle.sh:259
echo "$n_merges merge(s) on \`$MAIN\`'s first-parent line; $commits commit(s) reachable from it, merged branches included."
```
dev-cycle.sh uses the same shape in `file(s)` (:400), `item(s)` (:433) and `day(s)` (:449). The executed diff in claim 40 shows the output changed from `2 soft constraints` to `2 soft constraint(s)`.

**Evidence:** `scripts/build-loop.sh:265`, `scripts/dev-cycle.sh:259`, `scripts/dev-cycle.sh:400`, `scripts/dev-cycle.sh:433`, `scripts/dev-cycle.sh:449`

---

## Claim 39: "A17's 'for an open brief' matches the `st == open` gate."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/build-loop.sh:68-69`, `scripts/build-loop.sh:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help's condition that only an open queried brief takes the F31 skip, and that a done or dropped one sharing the branch does not. It does not establish that the shared set is complete under colour config (claims 41 and 43). It also does not cover open briefs whose `Branch:` line is malformed: those are not counted, and the help's "names the same branch" leaves that case open.

```bash
# scripts/build-loop.sh:68-69
#                 for an open brief, another open brief on main (in briefs/ or
#                 closed/) names the same branch (ignoring case), or the tip's subject (its
```
```bash
# scripts/build-loop.sh:333-335
  if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then
    echo "skip $a: another open brief on the default branch names the same branch (compared ignoring case)"; return
  fi
```
"Another" holds because the queried open brief is always one of the counted briefs. Its first unfenced `Status:` line is exactly `Status: open` (`scripts/lib/dev-cycle-read.sh:349`), so the grep at :306 finds the file, and the count at :310-311 uses the same `Branch:` regex as :325. A skip therefore needs a count of 2 or more, which means at least one other brief.

Executed (`probe41.log` baseline): with open briefs a (`feat/x`) and b (`Feat/X`) and a done brief c (`feat/x`), the output was `skip a ...`, `skip b ...` and `ok c done review feat/x absent - - 0`. bats T28 asserts the same for a done brief (`bats.log`, ok 16).

**Evidence:** `scripts/build-loop.sh:68-69`, `scripts/build-loop.sh:306-314`, `scripts/build-loop.sh:333-335`, `scripts/lib/dev-cycle-read.sh:348-351`. Command: `timeout 300 bash probe41.sh > probe41.log 2>&1` (exit 0, 2026-10-05T17:51:41Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe41.log`, `.../bats.log`

---

## Claim 40a: "4dc84ce4 changes no output format. The `--settings` four-line order, the `--status` field order ... are byte-identical to c143b929"

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/build-loop.sh:262-269`, `scripts/build-loop.sh:316-363` (via `git diff c143b929 4dc84ce4 -- scripts/build-loop.sh`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output strings and field order that build-loop.sh itself emits. It does not establish that classifications are unchanged. A12 moves `- [x] H2: x` from `none-hard` to `unreadable`, using a reason string that already existed.

`git diff c143b929 4dc84ce4 -- scripts/build-loop.sh` changes only these things:
- header comments
- the C23 string (`soft constraints` → `soft constraint(s)`, :265)
- the near-miss regex (:175)
- the `shared_branches` list source (:306-308)
- where the guard sits (:318)

It changes no `echo` or `printf` format. The `printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE"` (:361) and `echo "ok $a $st $pol $br $loop $sha $date $disp$reason"` (:351) lines are the same in both versions (paraphrased — no quote available because the claim concerns lines the diff does not touch; the diff text was read in full).

Executed differential (`probe40.log`): both versions gave the same output on the r41, r43 and r37 fixtures (`--status` with open/done/new/non-brief/marker/stopped/closed briefs, and `--settings`). For the constraints variants, there were two kinds of difference:
- the C23 prose (`2 soft constraints` vs `2 soft constraint(s)`, and the same for `0`)
- the A12 reclassification of `- [x] H2: x`

**Evidence:** `scripts/build-loop.sh:175`, `scripts/build-loop.sh:265`, `scripts/build-loop.sh:306-318`, `scripts/build-loop.sh:351`, `scripts/build-loop.sh:361`. Command: `timeout 400 bash probe40.sh > probe40.log 2>&1` (exit 1 from the abandoned duplicate-tree tail, redone in probe40b; every SAME/DIFF line above it ran; 2026-10-05T17:54:18Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe40.log`

---

## Claim 40b: "... and every skip reason [is] byte-identical to c143b929, apart from the C23 prose."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:337` (claim cites `git diff c143b929 4dc84ce4 -- scripts/build-loop.sh`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every skip reason `--status` can print between c143b929 and 4dc84ce4, including those that come from the lib. It does not cover `--check-answer` output from dev-cycle.sh, where the same lib wording change (:557) also lands.

The claim holds for build-loop.sh's own strings. But `--status` also prints check_brief's reasons, and the range c143b929..4dc84ce4 includes the merge of main (48663245, bringing in 8dc4880b). That merge changed one of check_brief's reasons:

```bash
# scripts/lib/dev-cycle-read.sh:337
    error) echo "skip $a: the tree of the default branch could not be read"; return ;;
```
At c143b929 the line read `skip $a: the default branch's tree could not be read`. 4dc84ce4 as a commit did not make this change (`git show --stat 4dc84ce4` lists only build-loop.sh, the bats file and override-log.md). It still falls inside the c143b929-to-4dc84ce4 comparison the claim makes.

Executed (`probe40b.log`): a main commit whose `docs/working/briefs/` tree lists `2026-10-01-a.md` twice. c143b929 printed `skip docs/working/briefs/2026-10-01-a.md: the default branch's tree could not be read`. 4dc84ce4 printed `skip docs/working/briefs/2026-10-01-a.md: the tree of the default branch could not be read`.

Precise version: "byte-identical apart from C23 and check_brief's tree-read error reason, which main's U1a gate fix reworded."

**Evidence:** `scripts/lib/dev-cycle-read.sh:337`, `scripts/lib/dev-cycle-read.sh:557`, `scripts/build-loop.sh:319-320`. Command: `timeout 200 bash probe40b.sh > probe40b.log 2>&1` (exit 0, 2026-10-05T17:54:31Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe40b.log`

---

## Claim 41: "With repo config grep.patternType=fixed|perl, grep.extendedRegexp=false, grep.fullName=true, grep.lineNumber=true, grep.column=true, core.bigFileThreshold=1, core.quotePath=true, submodule.recurse=true, grep.fallbackToNoIndex=true, color.grep.filename=red or core.attributesFile=/nonexistent, the two-brief fixture still prints both F31 skips."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:306`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed key set alone in `.git/config` (plus grep.patternType=basic and grep.threads=1), checked against exact expected output on a three-brief fixture (two open sharing a branch case-insensitively, one done). It does not establish robustness to other repo config. **Repo `color.ui=always` or `color.grep=always` defeats F31:** both open briefs print `ok ...` instead of skipping. `color.grep.filename=red` is harmless only while colour is off.

```bash
# scripts/build-loop.sh:306-308
  list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"
  while IFS= read -r f; do
    f="${f#"$MAIN_SHA":}"
```
(excerpt ends :308; enclosing shared_branches() continues to :315 — read)

Executed (`probe41.log`): every listed config gave PASS, with output equal to `skip a`, `skip b`, `ok c done review feat/x absent - - 0`. Three settings outside the list gave FAIL: `color.ui=always`, `color.grep=always`, and `color.grep.filename=red` combined with `color.ui=always`. In each, `--status` printed `ok ... open review feat/x absent - - 0` for a and `ok ... Feat/X ...` for b. The raw grep shows the cause: under `color.ui=always`, `git grep -l` prints `\033[35mmain:docs/...a.md\033[m`, so the `${f#"$MAIN_SHA":}` strip and `isbrief` both fail, and no brief is counted.

**Evidence:** `scripts/build-loop.sh:306-315`, `scripts/build-loop.sh:333`. Command: `timeout 300 bash probe41.sh > probe41.log 2>&1` (exit 0, 2026-10-05T17:51:41Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe41.log`

---

## Claim 42: "A diff=x textconv or a binary -text attribute in .git/info/attributes for *.md leaves the F31 result unchanged."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:306`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the F31 skip lines and exit status on the three-brief fixture under the attributes `*.md diff=x`, `-text`, `binary`, `-text -diff` and `diff=x -text`, with textconv set to a failing command, `false`, `cat`, `sed s/open/shut/`, or an upper-casing `sh -c`. It does not establish that `--status` runs no repo-configured command. check_brief's `git log -G'^Status: '` (`scripts/lib/dev-cycle-read.sh:357`) does invoke the textconv driver, and a failing one writes `fatal: unable to read files to diff` to stderr once per brief.

`git grep` at :306 has no `--textconv`, so it reads raw blobs, and `-l` lists binary-marked files the same way (raw `git grep -l` under `diff=x -text` listed both briefs, `probe41.log`). Executed (`probe42.log`): every attribute and textconv combination printed exactly `skip a ...`, `skip b ...`, `ok c done ...` with exit 0. Even `sed s/open/shut/`, which would hide `Status: open` from a reader that applied it, left both skips in place. With the failing textconvs (`tr a-z A-Z` given a file operand, `false`), stderr carried `fatal: unable to read files to diff` three times. That comes from the lib's `git log -G` (:357), not from :306:

```bash
# scripts/lib/dev-cycle-read.sh:357-358
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
```
(excerpt ends :358; enclosing check_brief() continues to :360 — read)

**Evidence:** `scripts/build-loop.sh:306`, `scripts/lib/dev-cycle-read.sh:357-359`. Commands: `timeout 300 bash probe42.sh > probe42.log 2>&1` (exit 0, 2026-10-05T17:52:02Z), `timeout 300 bash probe41.sh > probe41.log 2>&1` (attribute section; exit 0, 2026-10-05T17:51:41Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe42.log`, `.../probe41.log`

---

## Claim 43: "Under repo color.ui=always, the --status line for a marked branch carries no ESC byte and reads ready; among the --status git calls, only the git grep at :306 was colour-sensitive."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:276-296`, `scripts/build-loop.sh:336-351`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the marker read (`ready`, and `stopped` with its reason) and the 20 git invocations on the `--status` path, under repo `color.ui=always` (also with `color.diff=always`, `color.decorate.branch=red` and `log.decorate=full`). It does not establish that the colour sensitivity of :306 is harmless. At 4dc84ce4 it is still live and turns F31 off (claim 41's scope). It also does not cover a `git -c` or `GIT_CONFIG_*` colour setting in the caller's environment.

```bash
# scripts/build-loop.sh:279-281
  read -ra p <<<"$(git rev-list --parents -n 1 "$1")"
  msg="$(git log -1 --format=%B "$1")"; subj="${msg%%$'\n'*}"
  [[ "$subj" == handoff:* ]] || { echo working; return; }
```
(excerpt ends :281; enclosing marker_kind() continues to :296 — read)

Executed (`probe43.log`): with `color.ui always`, `--status` printed `ok ...-m.md open review feat/m ready 0799065f... 2026-10-05 1` and `ok ...-s.md open review feat/s stopped 8cb2bf08... 2026-10-05 0 needs a key`, with no ESC byte (`od -c` shows no `033`). The 20 calls were each run separately, and 19 printed no ESC:
- rev-parse --show-toplevel, symbolic-ref, show-ref (main, branch), rev-parse --verify ^{commit}/^{tree}
- ls-tree -t --full-tree, cat-file blob (brief, settings)
- log -G and log -1 --format=%H (check_brief), check-ref-format (both forms)
- rev-list --count, log --format=%cs, rev-list --parents, log --format=%B, cat-file commit

The one that printed ESC was `git grep -l ... -- docs/working/briefs/`.

**Evidence:** `scripts/build-loop.sh:276-296`, `scripts/build-loop.sh:306`, `scripts/build-loop.sh:336-351`, `scripts/lib/dev-cycle-read.sh:357-358`, `scripts/lib/dev-cycle-read.sh:370-383`. Command: `timeout 300 bash probe43.sh > probe43.log 2>&1` (exit 0, 2026-10-05T17:52:22Z); cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub`. Output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-sub/probe43.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 36** (`scripts/build-loop.sh:301-315`): 0.18 s is host-specific (about 0.07-0.09 s here). "21 MB adds no measurable time" holds in a packed repo but not with loose objects (+20-28 ms). Closed briefs left at `Status: open` cost about 10 ms each.
- **Claim 40b** (`scripts/lib/dev-cycle-read.sh:337`): across c143b929..4dc84ce4, check_brief's tree-read error reason changed ("the default branch's tree" → "the tree of the default branch") through the merge of main. "Every skip reason byte-identical apart from C23" needs that exception.

### Unverifiable
(none)

### Residue named in Verified scopes (not a verdict change)
- **Claims 37, 39, 41, 43**: repo `color.ui=always` or `color.grep=always` colours `git grep -l` output at `scripts/build-loop.sh:306`. Every open brief then reads `ok` instead of taking the F31 skip (`probe41.log`). No submitted claim asserts otherwise, but this is a new way to silently turn F31 off, and no `--no-color` or `-c color.grep=false` guards against it.
- **Claim 42**: check_brief's `git log -G` (`scripts/lib/dev-cycle-read.sh:357`) runs a repo-configured textconv driver. The F31 result is unaffected.
