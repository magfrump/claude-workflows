Commit: 10c2809 (A) / 875b41f (B)

# Performance Review — dev-cycle pass 26 (pass-25 fix round, k=1 delta)

**Scope:** Partial. A: `git diff cbfdf35..10c2809 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff 77e21af..875b41f -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle`, merged as bf5dfac. `bf5dfac:skills/dev-cycle/SKILL.md` is byte-identical to 875b41f's (`cmp`), and 10c2809 is an ancestor of the digest tip 18cb059 that bf5dfac merges, with only review docs after it. Focus, per the brief: `--check-brief` with the awk reader, `--check-branch` with the added `git log -1 --format=%cs`, and `--check-answer` after the header-only gate. Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `docs/reviews/code-fact-check-report-digest-pass25.md` (verdicts on cbfdf35 / 77e21af, the code this round changes), `performance-review-2026-10-02-digest-pass25.md`, and its probes in `scratchpad/perf25/`.

> ⚠️ **No code fact-check report covers 10c2809 / 875b41f.** The comments, help text and commit claims this round added have not been checked by a fact-check stage. The numbers below come from my own runs, and runtime endorsements are submitted as claims.

**Measurements.** All are mine, taken 2026-10-02 in this sandbox (git 2.39.5, mawk). "new" means `git show 10c2809:scripts/dev-cycle.sh` and "old" means `cbfdf35:…`; they ran in the same loop. Scratch is under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf26/` (written `perf26/` below). Each probe (`p1`–`p5`) is one `set -eu` script that creates its own `mktemp -d` dir under `perf26/` and checks `$PWD` before any `git init`, commit or write. Every process ran under `timeout`, and none of mine is still running. The bats processes visible in `ps` belong to another session's wt-devcycle suite run, and I left them alone. Nothing was written to either worktree or to `/workspace` except this file. `/workspace` is still on `main`, and its status is unchanged.

- **P1, long histories** (`perf26/p1.log`). This uses pass 25's generator (`perf25/gen.py`, copied). It writes N linear commits on main, puts the oldest brief in commit 1, adds `feat/longlived` forked at commit 1 with N commits, and adds an unrelated `feat/orphan`. Every repo was measured without a commit-graph, and then with `--changed-paths`. Each cell gives two runs of the whole call, old → new:

  | History | `--check-brief` oldest | `new` brief | 5 briefs | `--check-branch` long-lived | orphan | raw `git log -1 --format=%cs <tip>` |
  |---|---|---|---|---|---|---|
  | 10k, no graph | 55 → 55–56 ms | 15–16 → 16 | 137–142 → 135–137 | 63–65 → 64–67 | 40–45 → 41–42 | 2 ms |
  | 10k, graph | 23–28 → 23–24 | 16–18 → 16 | 64–68 → 62–67 | 22 → 22–24 | 19–20 → 21 | 2 ms |
  | 100k, no graph | 455–515 → 477–514 | 15–17 → 16–17 | 1,159–1,275 → 1,193–1,341 | 611–637 → 616–666 | 302–344 → 303–341 | 2 ms |
  | 100k, graph | 116 (797 cold) → 117–123 | 18–24 → 22–39 | 289–997 → 313–341 | 133–149 → 151–153 | 80–87 → 84 | 3 ms |

  On a clone of this repo (1,897 commits on main), `--check-branch` for a branch at the root commit takes 24–25 ms (pass 25: 17–19 ms) and prints `ok … 0 2026-02-24`.
- **P2, edges** (`perf26/p2.log`). For `--check-brief` on briefs of 1 KiB to 64 MiB, each test brief had its `Status: open` either first, last or missing, and was followed by a 1 KiB brief in the same call (three runs each). `%cs` was checked on a commit made at `2026-10-01T23:30-0700`. The no-default-branch exit was checked on a repo whose only branch is `trunk`.
- **P3, `--check-answer`** (`perf26/p3.log`). Readings were diffed over every real ID, old against new, in wt-devcycle's files (102 IDs) and in `/workspace`'s (99 IDs), each copied read-only into a temp repo. Every real entry's header shape was classified. Cost was measured against pass 25's 1×/10×/100× archives, and against a synthetic 17.5 MB archive of 60,000 fenced entries.
- **P4, fence reach** (`perf26/p4.log`). The target entry has an unclosed fence, and the entry after it holds a fenced format example. I also counted entries with an odd number of fence lines in all four real questions files.
- **P5, tests and lint** (`perf26/p5.log`), on `git archive 10c2809`: `bats test/scripts/dev-cycle.bats` gives **41/41 ok, rc 0, 10.3 s**. `python3 scripts/hermeticity-lint --root .` gives **rc 0**, 126 files, 4.7 s. Swapping in cbfdf35's `dev-cycle.sh` makes the lint fail (`can spawn \`claude\` (via scripts/dev-cycle.sh)`), so the quoted-variable change is what fixed it.

Legibility-target values: **maintainer** (someone editing the script or skill) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

Every check mode is a **cold path**: one agent Bash call per mode and batch, once per cycle. What can push a finding up is the agent's 120 s Bash timeout, a check that exits non-zero (the skill records it and stops the step that needed it, `SKILL.md:89-90`), inputs that grow without bound, and a slot held with no exit.

- **`--check-brief`** (`scripts/dev-cycle.sh:255-269`). The `grep -m1` is replaced by an awk that skips fenced lines and exits at the first unfenced `Status:` line (`:262-265`). A `new` brief still stops at `git cat-file -t`, flat at 16 ms. A landed brief still pays `git log -1 -- <path>`, which is linear in commits since its last change on main. Cost is unchanged within noise (P1). N is the briefs that hold a slot plus roadmap paths, about 3.
- **`--check-branch`** (`:284-288`). It adds one `git log -1 --format=%cs <sha>`, which reads only the tip commit: 2–3 ms at 10k and 100k commits, with or without a graph (P1). The `rev-list --count` walk is unchanged. N is one name per open brief.
- **`--check-answer`** (`:349-355`). Two rules now run before `heading()`: `inside && /^(```|~~~)/` and `inside && fence`. For a line outside the target entry, `inside` is 0, so both short-circuit. The ANSWERED test moved from a `tolower()` regex on every inside line to the first `**Needs:**` line only. Cost is unchanged within noise on the real-shaped archives. On the synthetic all-fenced archive it is about 9% slower (88–89 → 94–97 ms, four runs each, P3).
- **No default branch by name** (`:413-416`). The check modes now exit 1 in 13 ms (P2, `no-main new|13ms|rc=1`). cbfdf35 answered from the current branch instead. This is an exit, not a cost.
- **B** adds no loop. The cycle still runs `--check-brief` per brief and per name it writes, `--check-branch` per brief, and `--check-answer` per brief's pending IDs. The new idle rule reads the date `--check-branch` already prints, and the final-message listing is at most one open ID per brief (`SKILL.md:287-288`: step 3 files a new question only when no `Asked:` ID is still open or skipped).

## Findings

#### 1. The fence-before-heading reorder lets an unclosed fence in the target entry read the next entries as its own, so a later entry's fenced answer line can decide it

**Severity:** Medium (cross-lane: a correctness consequence, graded by its effect rather than a cost. A wrong `drop` or `done` closes an open brief: In flight step 2 → step 1 moves it to `closed/`). Preconditions: (a) the target entry has an odd number of fence lines, and (b) a later entry has a fence pair holding a line-start answer label or `Q-NNN:` line. In P4, no entry in the four real files has an odd fence count. Confidence: High on the mechanism (executed); Low on frequency.
**Location:** `scripts/dev-cycle.sh:349-353` (A, 10c2809)
**Evidence (verbatim):**
```awk
{ sub(/\r$/, "") }
inside && /^(```|~~~)/ { fence = !fence; next }
inside && fence { next }
heading($0) { count++; inside = (count == 1); fence = 0; header = 0; next }
/^(#|##|###) / { inside = 0 }
```
(This is `:349-353`. The program continues at `:354` with `!inside { next }`, then the header rule at `:355`, the `!done` answer block at `:356-369` and `END` at `:370-373`, which prints `open`, the result or `unrecognized`.)
**Move:** Trace the memory lifecycle (the state is `fence`. Once set inside the target, nothing outside a fence line resets it.)
**Classification:** Macro (state that leaks across entries, for the rest of the file) / Cold path (one awk per ID per cycle)
**Confidence:** High (mechanism) / Low (frequency)
**Baseline:** P4 (`perf26/p4.log`), 2026-10-02. Q-1 is `**Status:** ANSWERED` with an unclosed fence. Q-2 is an OPEN entry whose fenced example reads `**Answer:** [2] drop`. A second `### Q-1` heading follows. Readings: `case old: skip Q-1: more than one entry with this heading …; open Q-2;` and `case new: drop Q-1; open Q-2;`. Real files: 0 entries with an odd fence count.
**Legibility-target:** maintainer

Before this round, a heading reset `fence` (pass 25's fact-check verified Claim 17, "Fences reset per entry, so an unclosed one hides nothing outside it"). Now a fence open in the target hides every later heading. The `### Q-` headings of the following entries are hidden, and so are the `#`/`##` section headings and a duplicate of the target's own heading, which no longer counts as `dup`. The next fence line anywhere below flips the state. Lines between another entry's fence pair are then read as the target's, and its fenced example became Q-1's answer. The change fixed a safe-direction failure: a `# comment` inside a fenced block used to end the entry early, which gave `unrecognized`, so the user was asked again. It traded that for an unsafe one, a decision taken from another entry's text. The comment at `:347-348` ("Lines inside a fence in the entry are skipped, headings included") does not state the cost.

**Recommendation:** Let a `### ` heading line always end the target entry and reset `fence`, as before. Keep only the `#`/`##` end-of-entry test behind the fence, so a fenced `# comment` no longer ends the entry. A fenced quote of a `### Q-` heading then gives `unrecognized` or `dup`, both safe. Add a test with an unclosed fence followed by an entry holding a fenced answer.

#### 2. `--check-brief` exits 141 with no output for any landed brief over 64 KiB whose status line comes early; the threshold dropped from 70–256 KiB to 60–70 KiB

**Severity:** Low. Preconditions: a brief on main larger than the pipe buffer (64 KiB on Linux), with its first unfenced `Status:` line near the top, as the skill's template puts it. Real briefs are a few KiB. Confidence: High (measured, 3/3 runs at each size).
**Location:** `scripts/dev-cycle.sh:262-265` (A, 10c2809), under `set -euo pipefail` at `:63`
**Evidence (verbatim):**
```bash
  st="$(git cat-file blob "$MAIN_SHA:$a" | env LC_ALL=C awk '
    { sub(/\r$/, "") }
    /^(```|~~~)/ { fence = !fence; next }
    !fence && /^Status:/ { if ($0 ~ /^Status: (open|done|dropped)$/) print; exit }')"
```
(This is `:262-265`. The function continues at `:266` with `c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"`, prints at `:267-268`, and ends at `:269`. `st`'s first use is `:267`.)
**Move:** Trace the memory lifecycle (a pipe whose reader exits before the writer finishes)
**Classification:** Micro (one call per brief) / Cold path. It is a cliff, not a cost: past a fixed size the call fails outright.
**Confidence:** High
**Baseline:** P2 (`perf26/p2.log`), 2026-10-02, with `Status: open` on line 1 and a 1 KiB brief as the second argument. **new**: 1 and 60 KiB give `rc=0`, two lines. 70, 256, 4096 and 65536 KiB give **`rc=141`, 0 lines** (18–20 ms), and the second brief is lost too. **old** (`grep -m1 … || true`): rc 0 up to 70 KiB, and `rc=141`, 0 lines from 256 KiB. The same file with its status last, or with none, gives rc 0 at every size in both versions (the reader drains the pipe). That run took 156–164 ms new and 75–87 ms old at 64 MiB.
**Legibility-target:** maintainer

When awk `exit`s at the status line, `git cat-file` gets SIGPIPE writing the rest of a blob larger than the pipe buffer. `pipefail` makes the substitution's status 141, and `set -e` ends the script mid-batch. The skill then records a failed check and stops the In flight step for **every** brief in the batch, not only the large one. The behavior is not new, since cbfdf35's `grep -m1` had it too. But grep's larger read buffer kept it past 70 KiB, and the awk reader brings it down to just above 64 KiB. The `|| true` that cbfdf35 wrapped around grep never covered the writer's status, so neither version handled it.

**Recommendation:** Let the reader drain instead of exiting. Replace `print; exit` with a flag and `next` (`!fence && !seen && /^Status:/ { seen = 1; if (…) print }`), so it reads to EOF. That costs one linear pass over the blob, about 2 ms per MiB as measured ((156–164 − 27) ms over 64 MiB, the status-last runs). A cheaper alternative is to cap the read: `git cat-file blob … | head -c 65536 | awk …`, where `head` drains its own input. Add a test with a brief over 64 KiB.

#### 3. A brief that the glob lists but no roadmap In flight line names holds a slot and is never asked keep-or-drop

**Severity:** Informational. Preconditions: a brief stays in `docs/working/briefs/`, open or new on main, after its roadmap In flight line has gone, for example through a hand edit or a merge resolution. The final message still lists it by path (`SKILL.md:354`), so it is not silent. Confidence: Medium (read; not executed, since the skill is prose).
**Location:** `skills/dev-cycle/SKILL.md:81-84` with `:259-261` (B, 875b41f)
**Evidence (verbatim):**
```
has no file there (not landed yet, or already moved to `closed/`). **A brief holds a slot**
when the glob lists it or this cycle wrote it, unless `--check-brief` prints `done` or
`dropped` for it; a brief the check skips keeps its slot (recorded) until the cause is
fixed. A roadmap In flight path that `--check-path` skips (the brief moved, or never
```
(This is `:81-84`. The sentence ends at `:85`, "landed) is recorded and its line corrected." The In flight steps at `:259-296` start with "items with an open build brief, each naming its brief path. Every cycle checks each". They iterate roadmap items, not glob results.)
**Move:** Trace the memory lifecycle (a slot is a bounded resource, 3)
**Classification:** Macro (an unbounded hold on 1 of 3 slots) / Cold path
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** agent

The single slot rule counts what the glob lists, but only roadmap In flight items reach steps 1–3, which close a done brief, apply answers and file keep-or-drop. The Rules correct the reverse case, a roadmap path whose file is gone (`:84-85`), but not a listed brief with no roadmap line. Such a brief keeps its slot until someone notices it. Unlike pass 25's finding 3 (now closed, see Endorsements), no keep-or-drop question is ever filed for it. The gap predates this round, but this round makes the glob the one slot source.

**Recommendation:** In the Rules sentence, add the mirror case: a brief that holds a slot but that no In flight line names gets an In flight line (recorded), so steps 1–3 reach it.

## Cross-lane observations (not graded here; for the API-consistency critic and fact-check)

- `SKILL.md:278` says to list an `open` ID "in the final message with the date it was asked". The final-message sentence at `:353-355` lists "any keep-or-drop answer step 6 could not read" and does not name open IDs or their dates. Whether "could not read" covers `open` is for the API critic. `[unverified — submitted as claim]`
- `SKILL.md:160` ("an open brief (found as in the Rules)") and the record's `<k>/3 open` (`:337`) still say "open". The Rules now define "holds a slot", which covers `new` and skipped briefs but not a `done` one that has not been moved yet. Wording only. `[unverified — submitted as claim]`
- `%cs` is the committer's own zone (P2: committed `2026-10-01T23:30-0700`, printed `2026-10-01`, which is 2026-10-02 UTC), and it is the committer date, not the author date (the author date in that probe was 2026-09-01). A rebase or amend therefore resets the idle clock. Both effects are at most a day, or else delay the question, which is the safe direction at a 14-day threshold. `[unverified — submitted as claim]`

## Endorsements

- The header-only ANSWERED gate changes no reading of any real entry. Old → new readings match exactly over all 102 IDs in wt-devcycle's files and all 99 in `/workspace`'s (`(no difference)`, 0 stderr). Every archived entry (89 and 87) has `**Status:** ANSWERED` on its first `**Needs:**` line, every live entry (13 and 12) has its `**Status:**` there too, and no entry has ANSWERED on any other line (0 mismatches, P3). `[unverified — submitted as claim]` (my execution, P3)
- Pass 25's finding 3 (Low) is closed in mechanism. A squash-merged or WIP branch whose tip is more than 14 days old now "shows no work" (`SKILL.md:294-296`), and `--check-branch` supplies the date at O(1): the raw `git log -1 --format=%cs` takes 2–3 ms at 10k and 100k commits, graph or not. An active but slow branch is asked at most once per 14 days per brief. Asking needs both 14 days since `Kept:` and an idle tip, any `keep` resets `Kept:` to today, and no new question is filed while one is still open (`:287-289`). So the attention cost is bounded at ≤3 questions per 14 days. `[read: skills/dev-cycle/SKILL.md:280,287-296]`
- The check modes' new costs are flat. The awk reader matches grep within noise at real brief sizes (27–28 ms at 1–60 KiB, P2) and on long histories (P1). The no-default-branch exit takes 13 ms. `[unverified — submitted as claim]` (my execution, P1/P2)
- The help range `sed -n '2,62p'` (`:125`) covers the whole header: `:61` is the last comment line, and `:62` is blank before `set -euo pipefail` at `:63`. `[read: scripts/dev-cycle.sh:52-63,125]`
- The suite is 41/41 ok at 10c2809 (10.3 s), and the hermeticity lint passes. With cbfdf35's script swapped in, the lint fails on `dev-cycle.sh`. `[unverified — submitted as claim]` (my execution, P5)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Fence-before-heading reorder: an unclosed fence in the target hides later headings (including its own duplicate), and a later entry's fenced answer decides it (`drop Q-1` where cbfdf35 gave a dup skip) | Medium (cross-lane) | `scripts/dev-cycle.sh:349-353` (A) | High (mechanism) / Low (frequency) |
| 2 | `--check-brief` exits 141 with no output, losing the whole batch, for a landed brief over 64 KiB with an early status line (cbfdf35: from 70–256 KiB) | Low | `scripts/dev-cycle.sh:262-265` (A) | High |
| 3 | A glob-listed brief with no In flight line holds a slot and is never asked keep-or-drop | Informational | `skills/dev-cycle/SKILL.md:81-84` (B) | Medium |

## Overall Assessment

On cost, the round is neutral. The awk status reader, the extra `git log -1 --format=%cs` (2–3 ms at any history size) and the header-only gate measure the same as cbfdf35 within noise from 10k to 100k commits and from 186 KB to 17 MB archives. The header-only gate leaves every real reading unchanged, and pass 25's Low (an idle squash-merged branch never asked) is closed with a bounded question rate. The one issue worth fixing before the clean pass is a state leak, not a cost (finding 1). Moving the fence test ahead of the heading test means an unclosed fence in one entry now runs into later entries, so another entry's fenced example can decide a keep-or-drop. That is the unsafe direction, where cbfdf35 failed safe. No real entry triggers it today. Finding 2 is an old pipe cliff that the awk reader lowers to just above 64 KiB, and it is easily drained. Finding 3 is a pre-existing slot-lifecycle gap that the single slot rule now makes visible. All three are fixable in place, and no further benchmarking is needed.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file."
- **Path:** saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass26.md`, first line `Commit: 10c2809 (A) / 875b41f (B)`. Not committed.
- **Structure:** follows the performance-reviewer layout: header, no-fact-check warning, data flow and hot paths, findings, cross-lane observations, evidence-tagged endorsements (≤5), summary table and overall assessment. Each finding carries Severity (with preconditions and confidence), Location, verbatim Evidence with a note naming the rest of its unit, Move, Classification, Confidence, Baseline and Legibility-target.
