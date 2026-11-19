# Research: should build loops wait on files and jobs in the foreground?

- **Goal**: Decide, with evidence, whether the build-loop dispatch prompt or a skill a loop runs should tell a loop to wait in the foreground, and if so draft the exact wording and its target lines.
- **Problem framing**: Build loops lose their run (an early handback with no marker, or a two-hour idle) when they wait for a subagent, background job or file by ending their turn instead of staying inside a tool call. Considered and discarded: "the two-hour re-dispatch rule is too long" (roadmap Next 2), which prices the loss after it happens but does not stop a loop from losing its run.
- **Project state**: research doc only, the first step of the roadmap Now item "Loops wait on a file or job in the foreground" · standalone · not blocked (cite: docs/working/briefs/2026-11-19-loops-wait-foreground.md)
- **Task status**: complete (research done; the change it recommends is gate code, so it goes to a review brief)

Brief: `docs/working/briefs/2026-11-19-loops-wait-foreground.md` at a4509413. Branch: `docs/loops-wait-foreground`. Research only: no code, prompt, skill or workflow changes, and no command but `git`, `rg` and reads (criterion 6).

## What the feedback records (criterion 1)

- **F-012** (`docs/working/feedback/philosophy-research.md:97-103`, 2026-11-05). Three loops were told to wait for a warm-build file. Two went idle for about two hours, one right after loading the `Monitor` tool, while the agent list said `running`. `SendMessage` "queued until the next tool round and did not wake them". The two-hour rule stopped one; the other woke by itself. Separately, "a loop that ended its turn with a reviewer still running got a `[handback-send-enforce]` message and handed back early, with no marker". Loops later told to run in the foreground finished in 30 to 60 minutes.
- **F-013** (same file, `:105-111`, 2026-11-07). Three background loops each ended on a `tool_use` with no result (`Bash`, `Skill`, `Bash`). None woke in about two hours although the orchestrator's own commands ran and a background job had finished. "The cause is not known."
- **This repo, 2026-11-19** (`docs/working/cycles/cycle-2026-11-19.md:371`, `:573`; `docs/roadmap.md:193-195`). Two loops (worktrees-outside-dot-claude at 20:01 UTC, code-review-lever3-correction at 21:47 UTC) "handed back before their confirming review reported", work committed and no marker. Each then waited the full two hours before `--prompt --steal` could re-dispatch it. In the first, the round-2 reviewer later reported clean: the loop had nothing left to do but wait for it and write the marker.

## Where a loop waits (criterion 2)

"Loop" below means a build loop: a background subagent dispatched by the dev cycle. Lines marked *orchestrator* are the top-level session's, which the harness does re-invoke on a task notification (it ends its turn by design and wakes on the notification or a fallback wakeup, `skills/dev-cycle/SKILL.md:1034-1038`). They are listed so the split is visible, not as targets.

Repo text, at a4509413:

| # | Where | What waits on what | Who |
|---|---|---|---|
| W1 | `scripts/build-loop.sh:1978` (in `loop_prompt`) | "Start subagents only for research and review"; a reviewer subagent runs in the background (see H-a below) and the loop waits for its report | loop |
| W2 | same line | "Never start build loops, background agents or schedules": read literally, it forbids the background reviewer W1 allows; the prompt never says how to wait for one | loop |
| W3 | `workflows/pr-prep.md:180` | "Run skills in parallel; perform manual checks while waiting for results" (code-review and self-eval) | loop |
| W4 | `skills/code-review/SKILL.md:526-529` | three fact-check replicates launched in one message; "CHECKPOINT: Wait for all three replicate agents to return" | loop (as reviewer orchestrator) |
| W5 | `skills/code-review/SKILL.md:1000-1002` | all Stage 2 critics launched at once; "CHECKPOINT: Wait for ALL critic agents to return results" | loop |
| W6 | `skills/code-review/SKILL.md:851` | chain mode: "Wait for the upstream critic to return" | loop |
| W7 | `skills/code-review/SKILL.md:399-400` | record each sub-agent's token total "when the notification arrives": the report comes as a notification | loop |
| W8 | `workflows/pr-prep.md:339` | "Quiesce before the gate. Wait until no subagent this task started is still running" | loop |
| W9 | `workflows/pr-prep.md:337`, `scripts/health-check.sh:1159-1169` | the health check: one full run took 140 s at `--jobs 8`, over the Bash tool's 120 s default timeout, so a loop must raise the call's timeout or background it; and it waits on `health-check.lock` with no bound unless `HEALTH_CHECK_LOCK_WAIT` is set, for instance behind the orchestrator's own run | loop |
| W10 | `skills/code-review/SKILL.md:299` | reviewer probes (`sleep`, FIFO readers, background scripts) run under `timeout` and are killed before the agent reports: a cleanup rule, not a wait rule | reviewer |
| W11 | `scripts/build-loop.sh:1965` | "Never wait for an answer": waiting on the user, not on a job; already covered | loop |
| W12 | `skills/dev-cycle/SKILL.md:390-394` | health check "to a file, in the background, and wait for it to finish" | orchestrator |
| W13 | `skills/dev-cycle/SKILL.md:222-225` | steps 2, 3, 4 and 4b as parallel subagents | orchestrator |
| W14 | `skills/dev-cycle/SKILL.md:1001`, `:1034-1038` | dispatch "one background subagent" per loop; wait on its task notification, 1800 s fallback | orchestrator |
| W15 | `skills/dev-cycle/SKILL.md:707-711` | the two-hour stall rule on a working loop | orchestrator |

`workflows/research-plan-implement.md` and `workflows/review-fix-loop.md` name no background job, file wait, `Monitor` or subagent wait: `rg -n -i 'monitor|background|foreground|sleep|subagent|notif'` hits only RPI `:314` ("background that doesn't affect implementation decisions"), and their "wait" lines (RPI `:115`, `:117`, `:281`; review-fix-loop `:55`, `:61`, `:172`) are about not waiting for the user. They reach W3 to W9 through pr-prep's review-fix loop.

Harness text a loop sees (not repo text; observed in this loop's own session on 2026-11-19; it may differ across Claude Code versions):

- H-a: the Agent tool: "Subagents run in the background; you'll be notified when one completes." Its schema here has no foreground switch for a general-purpose agent. So W1 to W8 are always waits on a background subagent.
- H-b: the Bash tool: `run_in_background` "re-invokes you when it exits ... do not poll its output file while waiting", and "Foreground `sleep` is blocked; use Monitor with an until-loop to wait on a condition." The harness steers a waiting agent toward exactly the background-job and `Monitor` paths F-012 saw go idle.
- H-c: SubagentHandback: "The call ends your run", and a reminder that "Only a report delivered through SubagentHandback reaches your caller; plain text you write at the end of your run is NOT delivered."

## Why a waiting loop stalls or hands back early (criterion 3)

What the evidence shows:

- E1. Early handback follows a loop ending its turn while its reviewer still runs (F-012's `[handback-send-enforce]` case; both 2026-11-19 loops, at the confirming review). Three cases, all at a review wait (W3 to W5).
- E2. A loop told to wait on a file through `Monitor` or a background job can sit idle for about two hours while listed as running (F-012, two of three).
- E3. A message sent to an idle loop is queued "until the next tool round" (F-012): delivery happens between tool calls, not while the loop is idle.
- E4. Loops told to wait in the foreground finished in 30 to 60 minutes (F-012). This is one repo, one night, with no controlled comparison.
- E5. Prior art in this repo: FP-124 (`docs/failure-patterns.md:266`, commit 9ae66943). A headless top-level code-review orchestrator dispatched background replicates and ended its turn; `claude -p` waited out its 600 s background ceiling and stopped with one replicate written, while reporting success. The fix set `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0` so that background completions would re-invoke it (the commit states the intent, not an observed re-run), and its own notes say that with no ceiling a wedged subagent can hang the run. It says nothing direct about subagents, and whether a like ceiling or re-invocation applies to a subagent is L5 below.
- E6. One observation in this loop's own run (2026-11-19, 23:47 to about 23:49 UTC): this loop started one review subagent, then did not end its turn but kept making short `git`/`rg` reads. The reviewer's report arrived as a message between two of those tool calls, about 76 s after launch, and the loop went on. One run, one harness version; it supports I3 and answers L1 for this case only. No foreground `sleep` was used (criterion 6), so it says nothing about L2.

Inferences (not shown by the evidence):

- I1. For a subagent, ending its turn is ending its run. The harness then sends `[handback-send-enforce]`, a reminder to call SubagentHandback (H-c), and the loop obeys and hands back before the reviewer's notification has arrived. The message's text is not recorded anywhere in this repo; the reading rests on its name, H-c and E1.
- I2. A loop that ends its turn waiting on a `Monitor` event or a background job is woken only if the harness re-invokes a subagent on that event, and F-012 suggests it does so late or not at all (E2, E3).
- I3. A foreground wait works because the loop never yields: it stays inside one bounded tool call, and the reviewer's notification arrives with the next tool result (E3). That would explain E4.

Facts only a live run could show (no dedicated probe was run here, and E6 is incidental; criterion 6 allows only `git`, `rg` and reads):

- L1. Whether a subagent's own background subagent's completion notification is delivered with its next tool result, or only after its turn ends. This decides whether "keep making tool calls until the report arrives" works at all. E6 is one positive observation; a second, in a dispatched build loop, is still owed.
- L2. Whether H-b's "Foreground sleep is blocked" refuses `timeout 540 sh -c 'until test -e FILE; do sleep 15; done'`, or only a bare `sleep N`. A wording that names a refused command would send the loop to the `Monitor` path it was meant to avoid.
- L3. What `[handback-send-enforce]` says, and whether a loop that ignores it and makes another tool call keeps its run.
- L4. F-013's cause: a `tool_use` with no result is not a wait the loop chose, and no wording of the prompt is shown to prevent it. This change does not cover it (as the roadmap item says), and a wait with no bound would turn such a hang into a two-hour stall, so the wording below is bounded.
- L5. Whether a subagent that ends its turn is ever re-invoked by its own subagent's completion, and under what ceiling (compare E5's `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS` for headless top-level runs).

## Design

Failure-pattern grep: FP-124

(grep `-i -e 'monitor|background|idle|stall|handback|notification|sleep|wake|foreground|subagent'` over `docs/failure-patterns.md`; FP-124 is the only hit about waiting on background work, E5 above. The other hits match on `install-the-dependency` or unrelated background terms.)

Constraints that bind: S4 (prose arrives at the moment it is needed), S2 (no more than ~30 always-loaded lines; it binds only option D, since the dispatch prompt is not always-loaded context), S3 (one source of truth per rule), S5 (motive first; status quo valid), S6 (an observable that could come out negative), H3 (verifiable with hermetic tests), S8 (one revert undoes it).

Motive (S5): three early handbacks (E1) and two two-hour idles (E2) in two repos over two weeks, each costing about two hours of a slot and a re-dispatch, and in the 2026-11-19 cases nothing but a marker was left to write. The benefit is real if the wording stops even one of these a week.

### Placement: divergent design (four viable options)

| Option | What changes | For | Against |
|---|---|---|---|
| **[A] Change nothing** | status quo; roadmap Next 2 (the two-hour rule) carries the cost | no gate-code review | the losses recur at every review wait (E1) |
| **[B] One rule in `loop_prompt`** | `scripts/build-loop.sh:1978`, beside the subagent line; gate code, review merge | one place (S3); reaches every build loop and only build loops; arrives with the dispatch; test pinned in `test/scripts/build-loop-dispatch.bats:36` | reaches a loop at its start, not at the wait; dispatch prompt grows by about 3 lines per loop |
| **[C] At each wait point** | code-review W4 to W6, pr-prep W3 and W8; `workflows/` is a never glob (review merge) | arrives exactly at the wait (S4) | five places for one rule (S3); a top-level session is re-invoked on notification and should end its turn, so each line needs a "when you are a subagent" condition |
| **[D] Global instructions line** | `global-instructions/CLAUDE.md` | reaches every subagent everywhere | always-loaded for every session (S2), an instruction file (floor), most sessions never wait like this |
| **[E] A tested wait helper** | e.g. `scripts/wait-for.sh FILE SECONDS` (S4) | a mechanical step in a tested script | a reviewer's report is a notification, not a file (reviewers cannot write report files, herald F-010), so it covers F-012's file wait but none of the three E1 cases; a new script needs its own call site (S6) |

Decision (Path A, one option dominates): **[B]**. It is the only option that covers all three observed early handbacks from one source (C needs five, E covers none of them, D over-reaches S2). To keep S3, the new line says only how to wait (stay inside a tool call, bounded); when to wait stays with pr-prep `:339` and code-review's checkpoints, which it points to. Against [A], it costs about three prompt lines per dispatch to remove a measured two-hour loss. Its weakness, arriving at the start rather than at the wait, is softened by the dispatch prompt staying in the loop's context for the whole run.

Other choices (fewer than three viable options, one-line notes):

- W2's wording: reword "background agents" to "agents that outlive your run" so the rule no longer reads as forbidding the reviewers W1 allows; same line, same review.
- Bound the health-check wait (W9): the new rule names the Bash call's timeout; setting `HEALTH_CHECK_LOCK_WAIT` for loops is a separate question about the lock and is left to the review brief's author.
- The command form: an `until`-loop under `timeout`, not `Monitor` or `run_in_background`, because those are F-012's idle paths; L2 decides whether it survives H-b, so the wording carries a fallback.

### Drafted wording

Target: `scripts/build-loop.sh`, `loop_prompt`, the heredoc line at 1978 ("Start subagents only for research and review, ..."). Gate code: needs a review merge. Replace its second sentence's first clause, and add the wait rule as its own new heredoc line after 1978 (a separate line keeps the bats check at `test/scripts/build-loop-dispatch.bats:50`, which greps the "Start subagents only" line for the merge text, as it is):

Current (1978, start):

> Start subagents only for research and review, each with its own scratch directory under $s/ in your scratchpad directory. Never start build loops, background agents or schedules; never send your branch to a remote, ...

Proposed:

> Start subagents only for research and review, each with its own scratch directory under $s/ in your scratchpad directory. Never start build loops, schedules or agents that outlive your run; never send your branch to a remote, ...
>
> When pr-prep or code-review has you wait for a subagent or job you started, wait inside your turn: ending your turn can end your run with no marker. Wait for a subagent's report, which comes as a message between your tool calls, by making short reads (git log, git status) until it arrives; wait for a file or job with one Bash call, its timeout at 600000 ms, running timeout 540 sh -c 'until test -e "$1"; do sleep 15; done' _ ./FILE, not run_in_background or the Monitor tool. Wait 30 minutes at most in all; then write your marker, naming what did not finish.

The wording claims only what the evidence shows: "can end your run" (E1, I1), and the report arriving between tool calls (E3, E6). The file path goes in as `"$1"`, never into the shell string (the repo's first Code rule in `CLAUDE.md`). The 30-minute bound keeps a hung reviewer (L4) from becoming a two-hour stall, and its exit uses the existing marker paths (`scripts/build-loop.sh:1974-1977`). "ready" needs a clean review-fix loop, which an unreturned reviewer has not given, so as drafted the loop writes "blocked" naming the unfinished reviewer; the review brief may pick another exit.

`test/scripts/build-loop-dispatch.bats:36` pins "Never start build loops, background agents or schedules; never send your branch to a remote", so the review brief updates that assertion and adds one for the new line (H3).

Observable that could come out negative (S6): the cycle records' step-7 lines. Base rate in this repo: of the dispatches recorded in `docs/working/cycles/cycle-2026-11-19.md` (`10.` lines, about ten), two loops "ended with no marker" at a review wait; the phrase appears in no earlier cycle record (`rg -c 'ended with no marker' docs/working/cycles/`). Over the next twenty dispatches after the change lands, about four would be expected at that rate. Zero or one supports the change; three or more says the wording does not hold the turn (L1 or L3 false), and the change is reverted (one `git revert`, S8). Philosophy-research's step-7 lines can be counted the same way to widen the base.

## Invariants

- The dispatch prompt is printed, never retyped (`skills/dev-cycle/SKILL.md:1001-1002`), so any wording lives only in `loop_prompt`.
- T20 holds `scripts/build-loop.sh` to never naming git's push command (comment at `:1953-1954`); the wording above names none.
- A line of the marker body over 300 bytes is cut; the proposed prompt line is prompt text, not a marker body, so that bound does not apply to it.

## Gotchas

- `loop_prompt`'s heredocs are unquoted (`cat <<PROMPT`, so `$s`, `$MAIN` expand): the drafted `"$1"` must be written `"\$1"` there, or the prompt prints the function's first argument (the brief path) in its place. A bats assertion on the printed `"$1"` catches it.
- W2 and W1 conflict today in this harness (H-a): every review the loop starts is a background agent.
- The Bash tool's 120 s default timeout is under the health check's 140 s run (W9), which pushes a loop toward `run_in_background`.
- Waiting by short reads costs a tool round each, each re-reading the cached context. In E6 the loop made about twenty reads while the reviewer ran (its own run took 76 s), so a ten-minute review could take a hundred rounds or more. A file wait's nine-minute call is cheap; for a subagent wait, the review brief should measure the round count in its live check and, if it is large, pair the reads with a bounded foreground pause once L2 shows one is allowed. Even a hundred cached rounds are small next to a lost two-hour slot and a re-dispatch.

## Files read

Last verified: 2026-11-19
docs/working/briefs/2026-11-19-loops-wait-foreground.md
docs/working/feedback/philosophy-research.md
docs/working/feedback/belegarth-herald.md
scripts/build-loop.sh
scripts/health-check.sh
skills/dev-cycle/SKILL.md
skills/code-review/SKILL.md
workflows/research-plan-implement.md
workflows/pr-prep.md
workflows/review-fix-loop.md
docs/constraints.md
docs/roadmap.md
docs/working/cycles/
docs/failure-patterns.md
docs/working/research-2026-11-19-subagent-report-as-text.md
docs/working/questions-archive.md
test/scripts/build-loop-dispatch.bats

## For the dev cycle

Suggested roadmap change: replace the Now item "Loops wait on a file or job in the foreground" with a review brief.

- Goal: add the drafted "wait inside a tool call" line to `loop_prompt` and reword "background agents" to "agents that outlive your run", as drafted in this doc's "Drafted wording"; update and extend `test/scripts/build-loop-dispatch.bats` for both.
- Paths: `scripts/build-loop.sh`, `test/scripts/build-loop-dispatch.bats`.
- Policy: review (gate code).
- Precondition, before the wording lands: one live check of L1 and L2 in a dispatched loop (it starts a reviewer subagent and waits as drafted; does the report arrive, and is the `until` command allowed under H-b). E6 is one positive for L1 already. A negative L2 drops the file-wait half of the command, not the placement; a negative L1 sends the item back to research.
- The review brief also picks the bounded wait's exit (blocked marker naming the unfinished reviewer, as drafted, or another) and confirms its bound: the drafted 30 minutes is a guess with no measured source, set from this loop's reviewers (49 s and 76 s) and the two-hour rule it must stay well under; a slow code-review round may need more.
- After merge: the S6 count above, over twenty dispatches.

F-013's unreturned tool calls stay out of this item (L4).
