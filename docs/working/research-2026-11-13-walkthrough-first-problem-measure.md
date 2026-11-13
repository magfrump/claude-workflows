# Research: how often a walkthrough's first problem was one an agent could have found

- **Goal**: Do step 1 of `docs/thoughts/proposal-2026-11-12-agent-first-pass-playtest.md` for this repo: classify the first problem reported in each answered `you: walkthrough` entry as mechanical, a person-only finding, or none, and give the mechanical share.
- **Problem framing**: Count the answered entries routed `you: walkthrough`, plus any earlier entry that was plainly a walkthrough. Considered and discarded: counting every owner-run `you: terminal` paste as a walkthrough. That would fill the denominator with scripted host checks the playtest proposal does not target, and would pick the denominator from whatever produced output (FP-114, a past bug where a measurement counted only the cases that produced output; see Prior failures).
- **Project state**: Step 1 of the playtest proposal, this repo only; other repos are measured in their own sessions · unblocks the roadmap Next item "Agent first-pass playtest" (cite: docs/roadmap.md, Next item 2)
- **Task status**: complete (measurement done; result is "too few to decide")

## Result

**Zero answered `you: walkthrough` entries in this repo, and zero earlier entries that were plainly walkthroughs. Fewer than five, so the result is "too few to decide", not a share.**

| Source (commit 63184f91) | Entries routed `you: walkthrough` | Answered |
|---|---|---|
| `docs/working/questions.md` | 0 (its open entries: 7 `you: judgment`, 3 `you: terminal`) | 0 |
| `docs/working/questions-archive.md` (260 entries) | 0 (206 `you: judgment`, 32 `you: terminal`, the rest old agent/watch routes) | 0 |

The only matches for `you: walkthrough` in the two files are the route table, `docs/working/questions.md:16`, and two prose lines that describe the route, `docs/working/questions-archive.md:4538` and `:4661`. None is an entry's `**Needs:**` line.

The route has existed since commit `9a12425a` (2026-10-28; the first unit of decision 040, which split the owner routes). Since then this repo has opened 62 owner entries: 54 `you: judgment` and 8 `you: terminal`. That is enough traffic for a walkthrough to have shown up if one had been needed [observed count; the reason below is inference].

**Why there are none (inference):** this repo is the harness itself, with no player- or user-facing product to sit down with. What the owner runs by hand here is a scripted host check, and those are routed `you: terminal` by design.

### Earlier entries considered, and why none counts

The brief asks for entries that predate the route but were plainly walkthroughs: the owner ran something by hand and reported what happened. Every owner-run entry in this repo is a pasted, scripted command. These are the closest, and none counts:

| Entry | Reported | Why it is not a walkthrough |
|---|---|---|
| Q-176 · q092-deny-matcher-live-check | "1. denied / 2. model refusal, then allowed / … / 9. allowed but error: no configured push destination" (`docs/human-author/answers-10-16-26.txt:25-33`) | The nearest case, since it opens an interactive `claude` session (`docs/working/questions-archive.md:4075`). But the owner typed nine fixed probe spellings to test a deny matcher. That is a security probe, not product use. |
| Q-170 · decision-015-isolation-rerun | "When I fell back to running host sessions, it was because I installed a new devcontainer config that was unable to launch cc-isolated." (`answers-10-16-26.txt:18`) | It recalls failures in everyday use, given as background for a `you: judgment` answer. It is not a session the owner sat down for. |
| Q-082 | "When I ran the same two lines, the harness refused with \"Permission to use Bash with command … has been denied.\"" (`docs/human-author/answers-9-28-26.txt:21`) | Like Q-176: an interactive `claude` session, but running fixed probe lines to test a hook. |
| Q-162 · merges-and-cleanup-2026-10-14 | "Ran this, had some error messages like \"wt-build-loop-u3a1 is not a working tree\"" (`answers-10-16-26.txt:5`) | A `you: terminal` merge paste. |

Owner notes that answer no entry are also out. `docs/human-author/feedback.md:31` (H-05) reports hands-on use in another repo ("I spent a full day running ui-visual-review on Behemoth Arsenal…"), and `feedback.md:28` (H-04) and `feedback-10-29-26.txt:5` are similar. They describe other repos' builds and answer no `you: walkthrough` entry. The brief says those repos are measured in their own sessions, so they are not counted here.

## Not counted: what the owner's hand-run pastes hit first

This is context, not the measurement. These are `you: terminal` entries, outside the proposal's scope, and they are not added to any share. They show where first problems land in this repo when the owner runs something by hand:

| Entry | First problem, quoted | Class | Could a container agent have hit it? |
|---|---|---|---|
| Q-011 (first ask, headed "Q3" before IDs were used; matching it to Q-011 is inference) | "Cache/Requests.lean: No such file or directory (os error 2)" (`docs/human-author/answers-9-17-26.txt:6`) | mechanical (wrong path in the paste) | yes, inference: an agent in that container would have hit the same path |
| Q-019 | "ran the delete; du still returned 231M" (`docs/human-author/answers-9-17-26-2.txt:42`) | mechanical (wrong target: container path, not host) | no: host checkout |
| Q-049 run 1 | "INCONCLUSIVE, claude did not run: Ignoring 1 permissions.allow entry … this workspace has not been trusted" (`docs/human-author/answers-9-23-26.txt:14`) | mechanical | no: live `claude` on the host (H3 bars it in the sandbox) |
| Q-117 | "Running this requires a devcontainer install with a branched image, which refuses while any other work is running." (`docs/human-author/answers-10-12-26.txt:4`) | a person-only finding (the process is too disruptive) | no |
| Q-156 | "release refused: devcontainer-config differs from M" (`docs/human-author/answers-10-16-26.txt:54`) | mechanical | no: host release |
| Q-169 | "REFUSED: fix/egress-dnsmasq-ipset does not merge cleanly with main" (`docs/human-author/answers-10-28-26.txt:19`) | mechanical (stale branch) | yes, inference: `git merge-tree` in the sandbox would have shown it |

Reading (inference, six cases): when the owner's hand-run work fails first, it is usually mechanical, but mostly on the host, where a container agent cannot run the steps. If that held for walkthroughs in other repos, the proposal's container pre-pass would catch fewer of the mechanical problems than the raw share suggests. This is a hypothesis for the other repos' counts to test, not a finding.

## The proposal's rule, applied

- Brief rule: fewer than five entries means "too few to decide", not a share. Here there are 0.
- Proposal rule (step 1): stop if mechanical problems are under about 20% of the answers that reported any problem. With too few to tell (under about 8), "say so and treat steps 2–4 as a trial".
- So this repo neither supports nor refutes the hunch, and gives no reason to stop. It adds 0 to the pooled cross-repo count. The decision belongs to the other repos' counts (belegarth-herald, philosophy-research and the rest, each in its own session).
- Per the brief, a result that is not "under 20%" lists the proposal's three open questions in the marker body (the handoff commit message this loop leaves for the dev cycle), in questions-entry shape, for the cycle to file. The cycle may hold them until another repo reports a count: Q1 especially depends on which repo has walkthroughs.

### The three open questions (for the marker body)

**1. Which project gets the first trial?** It should have a CLI or TUI surface, so the trial doesn't wait on the Chromium decision.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Data-led** (recommended) | The first repo whose own count shows at least 5 walkthroughs and at least 20% mechanical | None now; one count per repo, run by its own cycle | The trial waits until a repo has 5 walkthroughs |
| **[2] You name one now** | A CLI/TUI project you pick | One line naming it | It may have too few walkthroughs to show a result |
| **[3] No trial** | Stop the proposal and record why | None | A real waste in other repos goes unfixed |

**2. Should the pre-pass run automatically, or only when you ask?**

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Automatic** | Runs whenever a cycle is about to file a `you: walkthrough` entry | None per walkthrough | One subagent dispatch per walkthrough, even ones you'd rather skip |
| **[2] Opt-in by file** (recommended) | Runs only in repos that have a `docs/playtest.md` | Writing that file once per project, about 10–20 min | A project without the file gets no pre-pass |
| **[3] On request** | Runs only when you ask | Remembering to ask, every time | It rarely runs (the proposal's S10 concern: safety that depends on you remembering) |

**3. Should Chromium/Playwright go into the cc-isolated image?** This only matters for web projects, and S8 (no new image package without a decision) makes it a separate decision.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Not now** (recommended) | CLI/TUI projects only; web projects get no pre-pass | None | Web projects keep their first-contact blockers |
| **[2] Add it** | A decision record, then the image change | One host rebuild per project | A larger image and more egress surface, for a benefit not yet measured |
| **[3] Decide at the first web trial** | Wait until a web project wins question 1 | None now | The trial for that project waits on a rebuild |

## Decisions in this unit

- What counts as "plainly a walkthrough": hands-on product use that the owner reported on, not a scripted paste. Two readings, one clear winner (the proposal's own definition: "sitting down with the build").
- Whether to add the `you: terminal` table to the measurement: no. It is kept as a labelled side table (FP-114 below).
- How to apply the decision rule when there are too few entries: the brief and the proposal agree. Report "too few", don't stop, and list the questions. One reading, so no divergent design was needed.
- The recommended options in the three tables are this loop's reading, for the cycle to adjust when it files them.

## What exists

- `docs/thoughts/proposal-2026-11-12-agent-first-pass-playtest.md`: steps 1–4, the decision rule and the three open questions [observed].
- `scripts/questions.sh` has accepted the `you: walkthrough` route since `9a12425a` [observed via `git log -S`].
- `docs/human-author/answers-*.txt` and `feedback*.{md,txt}` on the default branch hold the owner's answers. No answer reports a walkthrough [observed: every file read]. Several `answers-11-*.txt` files in the shared checkout are untracked, so they are not on the default branch and were not read, as the brief requires.

## Invariants

- The deliverable is this file. The only other change is the brief's Status line.
- No proposal, roadmap or questions edit.

## Prior art

- `docs/working/feedback/belegarth-herald.md` and `philosophy-research.md` record other repos' harness friction, but no walkthrough counts.

## Gotchas

- Failure-pattern grep: FP-077, FP-110, FP-114 (see Prior failures)
  - grep run: `grep -inE 'walkthrough|playtest|classif|measure|research doc|denominator|under-count|undercount' docs/failure-patterns.md`
- An empty route can mean the route went unused rather than the need being absent. The global instructions warn against numbers from instruments that under-count. Here the route's 16 days and 62 other owner entries make "unused because unneeded" the likelier reading [inference].

## Prior failures

- **FP-077, FP-110, FP-114** (`cause:wrong-denominator`): a measurement picked its own denominator, or dropped the cases that failed. Applied here: the denominator is the set the brief names (answered `you: walkthrough` entries). The terminal pastes stay out of it, even though counting them would turn "too few" into a share.

## Files read

`docs/working/questions.md`, `docs/working/questions-archive.md`, every `docs/human-author/answers-*.txt` on the default branch, `docs/human-author/feedback.md`, `docs/human-author/feedback-10-29-26.txt`, the proposal, `docs/thoughts/proposal-2026-11-12-cross-project-board.md`, `docs/roadmap.md` (Next item 2), `docs/working/feedback/*.md` (heads), `docs/failure-patterns.md` (grep).
