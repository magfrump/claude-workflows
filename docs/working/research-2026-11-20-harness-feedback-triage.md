# Research: triage of the six harness-feedback entries ingested in ad4f0eef

Brief: `docs/working/briefs/2026-11-20-harness-feedback-triage.md` (at 10c42a29).
Branch: `docs/harness-feedback-triage-2026-11-20`. Date: 2026-11-20.
Scope: research only. This doc is the whole output; no code, test, skill, hook or
feedback file changes. Commands run: `git`, `rg` and reads only, so every "verified"
below is a code path or a test name, not a run.

## Gotchas

- Failure-pattern grep: FP-185, FP-051, FP-164 (see Prior failures)
- The brief places `--check-answer` in `scripts/build-loop.sh`. It is in
  `scripts/dev-cycle.sh` (mode list, line 114), implemented by `check_answer` in
  `scripts/lib/dev-cycle-read.sh:1203`. `build-loop.sh` holds `--main-log`'s `answers`
  class, which reuses the same answer labels.
- In the same commit, `philosophy-research.md`'s `Project:` line now
  reads `task-workspace-designer` (ad4f0eef's diff, line 3). The file name was left as
  it was. The F-020 to F-022 entries describe the philosophy-research workspace
  (MAIS drafts, Theorem Atlas). Nothing here depends on the name.
- Both named fixes are in the installed image. `git merge-base --is-ancestor` puts
  61122f34 (guard worktree-taint fix) and b3e25cf1 (worktrees under `.worktrees/`) in
  665dbf95, the image commit this repo's cycle records as installed (cycle-2026-11-20,
  iteration 2317, step 0). That commit is dated 2026-11-20 11:19 -0800, after F-020's
  and F-021's events on 2026-11-19. Whether each reporting project's container has
  restarted onto it is a host fact this doc cannot see.

### Prior failures

- FP-185 (a web-taint guard asked on every edit in a worktree under `.claude/`, because
  a blanket path-segment rule caught whole checkouts): this is F-021's cause (2),
  fixed by 61122f34. It also shows why taint scoping (F-021's cause 1) now matters
  much less.
- FP-051 (a URL-literal check rejected URLs used as data): same shape as F-022. A
  text-pattern guard can't tell a token used as data (a `>` in a quoted format
  string, a policy path a read names) from the act it guards.
- FP-164 (a profile grant silently overwritten): same shape as F-001. State left over
  from an earlier step (an emptied heading) silently changed what later writes mean,
  and nothing noticed.

## What I read

- The three feedback files in full: `behemoth-arsenal.md` (F-001, F-002),
  `belegarth-herald.md` (F-013 and the earlier F-001 to F-012 for context),
  `philosophy-research.md` (F-020 to F-022, plus F-019, which they cite).
- 61122f34 (merge of `fix/guard-worktree-taint`, 19 new bats cases named
  `worktree taint: ...`), its research doc, and b3e25cf1 (merge of
  `feat/worktrees-outside-dot-claude`: `build-loop.sh --start` defaults to
  `.worktrees/`, `WT_BASE_NAME=.worktrees` at `scripts/build-loop.sh:1984`). This
  loop's own worktree, `/workspace/.worktrees/wt-2026-11-20-harness-feedback-triage`,
  is an instance of it.
- `hooks/guard-trusted-writes.py` (543 lines) and `hooks/web-taint-mark.py` (86
  lines), in full.
- `scripts/questions.sh` `cmd_check` (292-392), `cmd_migrate` (529-573),
  `entry_sections` (282), `cmd_init`'s layout (631-660).
- `scripts/lib/dev-cycle-read.sh` `check_answer` (1203-1230) and `GATE_CODE` (1038);
  `scripts/build-loop.sh` `--main-log`'s class rules (160-200).
- `skills/dev-cycle/SKILL.md`: step 0.2 on `other` commits (318-335), the "working"
  stall rule (759-772), step 7's answer reading (838-846), step 9's in-session
  answers and `--cycle-diff` (996-1030), the final message (1096-1104).
- `devcontainer-config/devcontainer.json` mounts (73-80), `Dockerfile` Android block
  (202-232), `cc-isolated.sh` profile detection (430-434),
  `scripts/claude_config_audit.py` `SKIP_DIRS` (127-130).
- `docs/constraints.md` (quoted in the dispatch), `hooks/live-verify-gate.sh`'s
  enforcement set (83).
- This repo's own handling of an owner answers file: 7df4654d
  (`docs/human-author/answers-11-20-26.txt`, 247 lines) and cycle-2026-11-20,
  iteration 2317.

## Triage table

| Entry | Verdict | Fixed by / evidence | Can the cause still occur here today? |
|---|---|---|---|
| behemoth F-001: owner entries filed under stale route headings | not covered | `cmd_migrate` removes entries only (`live_without_entry`) and never touches `##` headings. `cmd_check` reads sections only in `watching.md` (`entry_sections` knows only `## Closed`), so an open `you:` entry under `## Watched conditions` in `questions.md` passes | Yes, in any project whose `questions.md` predates decision 040's layout. Not in this repo: its `questions.md` has only `## Index` (24) and `## Open` (37) |
| behemoth F-002: an owner answers file is invisible to the gate | not covered (by design) | `check_answer` reads only `docs/working/questions.md` and `questions-archive.md` (`dev-cycle-read.sh:1208`). `--main-log`'s `answers` class needs a commit that changes only those two files (`build-loop.sh:182`). Step 0.2 lists an `other` commit, and step 7 says it "holds no answer" (SKILL.md:844) | Yes, and it does here: 7df4654d (this repo's owner, answers to Q-255, Q-302, Q-327) was classed `other`. Iteration 2317 recorded none of them and "asked in the final message". Same failure as behemoth's, caught by hand |
| herald F-013: toolchain caches wiped on every harness update | not covered (worked around in the project) | `devcontainer.json:78-79` mounts only two per-project volumes, `/commandhistory` and `/home/node/.claude`. `~/.cache` and `~/.gradle` are on the container's root filesystem, which a harness update recreates | Yes, for any toolchain cache outside `~/.claude`. Herald now pins build-tools 35.0.0 and keeps `GRADLE_USER_HOME` under `~/.claude/.cache` |
| philosophy F-020: a background subagent blocks silently on a write that needs approval | partly covered | The trigger is gone. The asks came from web taint plus the `.claude` path rule (F-021's diagnosis), now fixed for file tools in `.claude/worktrees/<name>/` and `.claude/wt-*/` by 61122f34. b3e25cf1 also moves dispatched loops to `.worktrees/`. Both are in image 665dbf95. The general gap remains: the stall rule waits for a TIP unmoved over two hours of iterations (SKILL.md:759-761) and never reads a transcript | Yes, for any other ask in a background subagent: a tainted write to a real SOFT file (a skill, a `CLAUDE.md`), or a non-allowlisted command outside `auto` mode. Its old trigger can't occur on the fixed image |
| philosophy F-021: web taint plus a worktree under `.claude/` asks on every write | covered (cause 2); not changed (causes 1 and 3) | 61122f34, `hooks/guard-trusted-writes.py` `_worktree_root` (270), `_verified_worktree` (288), `_is_soft_path`. Pinned by `test/hooks/guard-trusted-writes.bats` "worktree taint: the reproduction table (tainted and clean, both layouts, .worktrees, main checkout)" and 18 sibling cases. Cause 1 (taint keyed on `session_id`, `web-taint-mark.py:48`, `guard-trusted-writes.py:490-491`) and cause 3 (SOFT plus taint asks) are unchanged | Not for ordinary files in a verified linked worktree. Yes for real SOFT files there, which is intended. Session-wide taint still makes one subagent's fetch taint its siblings, but now only real SOFT files ask |
| philosophy F-022: the write guard denies read-only Bash that names a hook | not covered | `WRITE_PRIMITIVE` (`guard-trusted-writes.py:427-435`) matches a `>` whether quoted or not (only `/dev/null` and fd duplicates are excepted) and any `python3 ... -c` or `-e`. `HARD_FRAG` (456) or `SETTINGS_OR_HOOKS` plus `CFG_INDICATOR` then denies (`bash_targets`, 461; deny text 502). No bats case pins a read-only false positive of this shape. The one read-only case, "read-only commands on a project CLAUDE.md are not denied" (265), has no `.claude` indicator | Yes, in any session, any project |

An extra finding under F-021: the `web-taint-mark.py` docstring (line 5) says "Taint
does NOT propagate between subagent and parent sessions". F-021 observed the opposite
for Workflow subagents, which report the parent's `session_id`. Whether Agent-tool
subagents do the same is not verified here: no command could run. Either way the
comment states as fact something one observed case contradicts.

## Per entry: smallest fix, policy, worth it

Policy follows the paths: `scripts/questions.sh`, `scripts/lib/`, `scripts/dev-cycle.sh`
and `skills/dev-cycle/` match `GATE_CODE` (`dev-cycle-read.sh:1038`), so `Policy:
review`. `hooks/*.py` are review too (the in-flight
`2026-11-20-write-guard-wt-exemption` brief on the same hook is `Policy: review`).
`devcontainer-config/devcontainer.json` is in the live-verify enforcement set
(`live-verify-gate.sh:83`): it needs review, a `Live-verified:` trailer and a host
install.

### behemoth F-001: stale route headings

Options: (a) `check` flags an entry in `questions.md` that sits under a `##` heading
other than `## Open`; (b) `migrate` deletes a route heading it leaves empty; (c) the
cycle files new entries through a script that inserts them under `## Open`; (d) status
quo. Option (a) dominates (Path A). It is a detector for every cause: a migration
leftover, a hand edit, an append under a later heading. It runs where the cycle
already runs `check` (step 1b after a remedy, SKILL.md:490; step 9 before staging
filed entries, SKILL.md:988), so behemoth's first misfiled entry would have been
caught. (b) is a cheap complement for the one known cause. (c) adds a second filing
path (S3). To avoid FP-113 (a new gate that every existing clone fails), reuse
`check`'s existing `LEGACY_BEFORE` split: ⚠ for entries opened before the cutoff, ✗
after.

- Paths: `scripts/questions.sh` (`cmd_check`, a section-aware twin of
  `entry_sections`; `cmd_migrate` for (b)), `test/scripts/questions*.bats`.
- Policy: review (gate code).
- Worth it now: yes. One project so far, but 19 of 20 open owner questions were
  misfiled and the owner missed answers: the S10 harm (owner attention), and a silent
  one. Small change (an awk pass plus a few bats cases).

### behemoth F-002: owner answers files (divergent design)

Motive (S5): real and repeated. The owner has answered by committed files since
September in at least three projects: behemoth F-002, philosophy-research's earlier F-004 (answers-file-not-read-by-gate) and F-005, and this repo. This repo has about ten `answers` commits under
`docs/human-author/`, the latest 7df4654d. Each time the cycle reads the IDs as
`open`, and the owner or a hand session has to restate or copy the answers. The global
instructions' "Running questions document" says the owner writes `Q-NNN: <answer>`
"anywhere (a reply, a file, a commit)". The gate honours only the questions files and
in-session words (D8, the design rule that an answer is taken only from the questions
files or the owner's words in session). So the harness breaks its own stated contract.

Candidates:

- A. Status quo plus guidance: the owner puts answers in `questions.md` (an `answers`
  commit, already read). Costs the owner a habit change. Their files also carry prose
  and questions back (the "answer files can ask back" note), which doesn't fit an
  entry.
- B. Detector: step 0.2 parses an `other` commit that adds `docs/human-author/answers-*`,
  lists its `Q-NNN: [N]` lines whose IDs are open, and offers a one-word batch confirm
  in the final message ("take answers-11-20-26-2.txt"). This uses the existing batched
  in-session answer route (SKILL.md:1000-1005), so trust is unchanged. The owner still
  has to be in a session, and the loop still idles until then.
- C. `questions.sh apply-answers FILE`: copies the owner's lines into their entries,
  landed as an `answers` commit, which the existing gate reads. Someone has to run it
  per batch: a recurring chore (S10) unless a hand session does it at the owner's word,
  which is B with extra steps.
- D. Declared input: `check_answer` also reads `docs/human-author/answers-*.txt` on
  main, with the same `ANSWER_AWK` labels. No owner action. A conflict (two files, or a
  file and an entry, answering one ID differently) skips, as two entries with one
  heading already do.

Against the constraints. H1 holds for all four: the logic stays in the image, and a
file is input. H4 holds for all four (mechanical parse, no LLM). S3: D and B reuse the
existing parse and batch route; C adds a writer. S10: D is the only one that costs the
owner nothing per batch; B costs one reply; A and C cost a habit or a chore. Trust
(S1, F19, the rule that a commit's class is read from its own text and catches honest
slips, not disguised commits): D adds `docs/human-author/` as a source of answers.
Build loops can't write it (self-merge floor "record", `dev-cycle-read.sh:992`), and
`--cycle-diff` refuses it for the cycle (truth file, SKILL.md:1022). So its writers are
the owner and hand sessions, the same set that can already write answer lines into
`questions.md`. Residuals for D: an ID-collision history
(`questions-id-collision-concurrent-sessions`, where an old file's `Q-NNN` may name a
different question), handled by reading only files added after the entry's `Opened`
date; and a prose line that starts `Q-NNN:` but isn't an answer, which reads as
`unrecognized` (a skip, never a wrong merge).

No option dominates. D wins on owner attention, B on keeping the trust regime as it
is, and changing D8's source list is the owner's authority. Path C tentative pick:
**D**. Tiebreaker: S10 and the global instructions' own "a file" contract. Fallback if
the owner declines: B.

The question for the owner (also in the marker): should a committed answers file under
`docs/human-author/` count as your answer, the way a line you write into
`questions.md` already does?

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| [1] Read the file (D) | the gate reads `Q-NNN: [N]` lines in new `docs/human-author/answers-*` files | none per batch | a hand session's file could answer for you, as `questions.md` already can |
| [2] Detect and confirm (B) | the cycle lists the file's answers; you reply one word to take them | one reply per batch | answers wait until your next session |
| [3] Status quo (A) | answer in `questions.md` or in session | change your habit | answers files keep being ignored |

- Paths for D: `scripts/lib/dev-cycle-read.sh` (`check_answer`), `scripts/build-loop.sh`
  (an `answers` class for a commit that adds only `docs/human-author/answers-*`),
  `skills/dev-cycle/SKILL.md` (step 7, final message), bats. For B:
  `skills/dev-cycle/SKILL.md` and a small parse helper in `scripts/dev-cycle.sh`.
- Policy: review (gate code), whichever option.
- Worth it now: yes. It recurs every batch, in three projects, and the loop stalls on it.

### herald F-013: toolchain caches (divergent design)

Motive (S5): weak today. One project. It bit about five times, and the project has
already removed its trigger: it pins build-tools 35.0.0, so no SDK overlay, and its
wrapper puts `GRADLE_USER_HOME` under `~/.claude/.cache`. What's left is about 3
minutes of Gradle download per Android project after a cache wipe, now avoided by the
wrapper.

Candidates: (1) a generic per-project cache volume (`cc-${CC_PROJECT_ID}-cache` at
`/home/node/.cache`, with `GRADLE_USER_HOME`, `npm_config_cache` and `PIP_CACHE_DIR`
pointed into it); (2) a per-project toolchain manifest that also derives egress;
(3) a read-only host Gradle cache with `GRADLE_RO_DEP_CACHE`; (4) bake more
build-tools into the image; (5) status quo (the project-side wrapper).

Against the constraints. (1) changes `devcontainer.json`, which is enforcement: a
live probe, a host install and a host paste (S10), plus a new volume to reset or
size-report (S10: "nothing left behind to clean up"). (2) is large and speculative
(S6, S8). (3) adds a host bind, a new trust path (S1, H1). (4) grows the shared image
for one project. (5) works now at no harness cost. Status quo dominates (Path A).
Revisit trigger: a second project loses a toolchain cache to an update, or herald's
wrapper breaks. Then (1) is the first candidate, as the herald pass also found.

Two facts for the owner, from herald's ideas list:

- Herald's idea 4 asks whether the shared image already ships the SDK. It does, by
  design: `Dockerfile:202-209` bakes JDK 17 and the Android SDK unconditionally in the
  shared base image (decision log #19), and the egress profile gates only the network.
  So "no SDK in images for projects without Android egress" is not the harness's rule
  today, and an Android-only image variant would reverse a recorded decision.
- The config auditor skips `.cache` but not `cache` (`claude_config_audit.py:129`).
  Herald already moved its cache to `.cache`. No harness change is needed unless the
  cache volume is built.

Worth it now: no. Close as worked around in the project, with the trigger above.

### philosophy F-020: silent block on a pending approval

The trigger is fixed (above). The residual is the orchestrator's blindness to a
pending `tool_use`. Smallest fix: in the "working" bullet of step 7, a loop this
session started whose TIP hasn't moved for 30 minutes gets a read of its transcript's
last line. A pending `tool_use` with no result is filed as `blocked` ("waiting on an
approval") instead of waiting out the two-hour stall rule. Mechanically that wants a
script mode (the transcript path comes from the task ID), so it is gate code
(`scripts/build-loop.sh` or `scripts/lib/`, `skills/dev-cycle/SKILL.md`), review policy,
with a hermetic bats case on a fixture transcript.

Worth it now: no. It bit one project for one night, from a cause now fixed on the
image. Every remaining ask source is rarer: tainted SOFT writes in a loop, or modes
other than `auto`. Suggested as a watch: reopen if a loop is seen idle on a pending
`tool_use` again. The cost of a miss is bounded by the two-hour stall rule.

### philosophy F-021: taint scoping

Cause 2 is covered. For cause 1, per-agent taint isn't worth building. Now that
ordinary worktree files don't ask, session-wide taint over-asks only on real SOFT
files, which is the safe direction (S1). Building it would need the hook input to
carry a per-agent identity, which is unverified here. The one cheap thing worth doing:
correct `web-taint-mark.py`'s "Taint does NOT propagate between subagent and parent
sessions" to say a subagent that reports its parent's `session_id` shares its taint.
That is a comment-only change to a hook (review policy), small enough to ride with the
next guard brief.

Worth it now: close F-021 as covered by 61122f34. Fold the comment fix into the F-022
brief.

### philosophy F-022: read-only Bash denied (divergent design, Path A)

Candidates: (a) quote-aware redirect detection; (b) `python3 -c` counted as a write
only when its code holds a write call; (c) the deny text names the read routes (the
Read tool, or a script file run by path); (d) status quo. (a) and (b) relax a HARD
`deny`, the tier whose Bash exemption (Q-048) was withdrawn after three review passes
found bypasses. The same quoting and indirection families apply here (`"$(printf
'>')"`, `getattr` for `open`), so either would need a pre-mortem and several rounds,
for a friction cost of one retry per hit. (c) changes no decision, only text, and it
cuts the retry loop by naming the route on the first deny. (c) dominates (Path A).

Note on (c): `python3 script.py` is already ungated (TODO A8, `guard-trusted-writes.py:421-423`),
so naming a script file as the read route adds no bypass that isn't already allowed
(S1). The text should say it is for reads and tests.

- Paths: `hooks/guard-trusted-writes.py` (the Bash deny text, line 502), the bats case
  asserting that text, plus the F-021 comment fix in `hooks/web-taint-mark.py`.
- Policy: review. Sequence it after `2026-11-20-write-guard-wt-exemption`, which edits
  the same file.
- Worth it now: yes, as a small one. Read-only denials of this shape have bitten at
  least three projects: philosophy F-022 (2), herald F-001 (about 4 of its 20 were
  searches or hook experiments), and this repo (the guard-worktree-taint research
  notes the guard blocking its own heredocs).

## Design choices with fewer than 3 options

- Output form: one research doc, as the brief requires. No choice.
- Whether to run each entry's experiment: the brief allows only `git`, `rg` and reads,
  so coverage evidence is code paths and test names. A host or hook run is left to the
  briefs below.

## For the dev cycle

Suggested briefs (one per entry worth fixing):

1. **questions-check-section** (closes behemoth F-001). Goal: `questions.sh check`
   reports an entry in `questions.md` that sits under a `##` heading other than
   `## Open` (⚠ before `LEGACY_BEFORE`, ✗ after), and `migrate` drops a route heading
   it leaves empty. Paths: `scripts/questions.sh`, `test/scripts/questions*.bats`.
   Policy: review (gate code). Doc change: the `check` and `migrate` usage text.
2. **answers-file-route** (closes behemoth F-002; philosophy-research F-004/F-005 and this repo's answers files too).
   Waits on the owner's question below. Interim pick D: `check_answer` reads
   `Q-NNN:` lines from `docs/human-author/answers-*` files on main added after the
   entry's `Opened` date, a conflict skips, and `--main-log` classes such a commit
   `answers`. Paths: `scripts/lib/dev-cycle-read.sh`, `scripts/build-loop.sh`,
   `skills/dev-cycle/SKILL.md`, bats. Policy: review (gate code).
3. **guard-read-route-text** (closes philosophy F-022, and finishes F-021 with the
   comment fix). Goal: the guard's Bash deny text names the Read tool and a script
   file as the way to read or test a policy file, and `web-taint-mark.py`'s docstring
   says subagents that report the parent's `session_id` share its taint. Paths:
   `hooks/guard-trusted-writes.py`, `hooks/web-taint-mark.py`,
   `test/hooks/guard-trusted-writes.bats`. Policy: review. After
   `2026-11-20-write-guard-wt-exemption` merges.

Entries to close without a brief:

- philosophy F-021: covered by 61122f34 (verified-worktree classification, 19 bats
  cases) and b3e25cf1, both in image 665dbf95; the residual comment fix rides on
  brief 3.
- philosophy F-020: trigger covered by the same two commits. The residual (a pending
  approval invisible to the orchestrator) isn't worth a build. Suggested watch: a
  loop seen idle on an unanswered `tool_use` reopens it, with the transcript-tail
  check above as the fix.
- herald F-013: worked around in the project. Status quo by divergent design.
  Suggested watch: a second project losing a toolchain cache to an update brings
  back the per-project cache volume.

Question for the owner (for the cycle to file as `you: judgment`): should a committed
answers file under `docs/human-author/` count as the owner's answer? Options and table
are in the F-002 section above. Tentative pick [1] (D), tiebreaker S10, the
constraint that spends the owner's attention last.
