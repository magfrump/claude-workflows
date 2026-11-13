# Proposal: a cross-project board over the files the repos already keep

**Date:** 2026-11-12 · **Status:** proposal, nothing implemented · **Source:** owner conversation 2026-11-11/12 (IDE survey → "the real pain point is dedicated attention time on projects and keeping up with project status"; "a Kanban view for what progress has been made, what projects are active, adding items to the roadmap, and adjusting priorities would be nice")

## Motive (S5)

The owner's attention is the binding budget (roadmap Now, 2026-11-11 entry), and right now it is spread over several repos that each keep their own state. Every repo that runs these workflows already writes the inputs a board needs:

- `docs/roadmap.md`, with `## Now`, `## In flight`, `## Next` (in the owner's order), `## Ideas` and `## Done`;
- `docs/working/questions.md`, whose open entries carry a `**Needs:**` route (`you: judgment`, `you: walkthrough`, `you: terminal`, `you: fyi`);
- `docs/working/watching.md` and `docs/working/cycles/`;
- the git log.

What's missing is a view across those repos. Today the only way to answer "which project needs me, and which one is playable?" is to open every workspace. Two symptoms already recorded in this repo:

- Entries sit for a month (brainstorm 2026-10-29, signal S5).
- Feedback moves between projects by hand (signal S7).

The status quo is a valid outcome. The board earns its place only if the owner uses it to choose what to work on (see Observable).

## Design

### What it reads

`scripts/board.py` is python3 stdlib only, read-only, and calls no LLM, so H4 doesn't apply. For each repo in a registry, it reads:

| Input | Read how | Shows as |
|---|---|---|
| `docs/roadmap.md` | Top-level bullets under Now, In flight and Next, each cut to its bold title | the project's cards, Next kept in the owner's order |
| `docs/working/questions.md` | `questions.sh open`, run in that repo (S3: one grammar, never restated). It prints ID, route and slug today; this proposal adds an `Opened` date column to its output (a few lines in `cmd_open`) rather than re-parsing the file | count per route, plus the age of the oldest entry |
| `docs/working/watching.md` | Count of open watches | one number |
| `git log` | Commits since the last board run, plus the date of the last commit | "what changed" line |
| `docs/working/cycles/` | Date of the latest cycle record | "last cycle" date |

### Registry

The registry is one absolute repo path per line, in `~/.claude/board-repos`. It sits outside every repo, so no project can add itself. The script only reads paths listed there.

### Columns

Each project goes in exactly one column, chosen by a rule written into the board's footer:

- **Waiting on you** — any open `you: judgment` or `you: terminal` entry.
- **Playable** — any open `you: walkthrough` entry.
- **Active** — a commit in the last 7 days, or an item In flight.
- **Parked** — none of the above for 21+ days. That matches the 21-day expiry idea in brainstorm B5.

If a project matches more than one column, the first matching column wins. "Waiting on you" comes before "Playable" because a judgment can unblock agent work, and a walkthrough can't.

### Output

The board is `~/board.md`:

- one table at the top: project × column, open-question counts, oldest open entry age, last activity;
- below it, one short section per project with its Now/Next titles, each linked to the line in the repo's `roadmap.md`.

It opens in VS Code next to the owner's other docs; the Ctrl+Shift+V preview stays fixed on it while other files are edited.

### Editing

The board writes nothing to project repos. There's no second source of truth for priorities (S3):

- **Reorder priorities** by reordering `## Next` in that repo's `roadmap.md`. The dev cycle already keeps Next in the user's order.
- **Add an item** with `board add <project> "<text>"`. It appends one bullet under `## Ideas` in that repo's roadmap, marked `(owner, YYYY-MM-DD)`, so the next cycle's step 6 picks it up. This is the only write, and it is a single append (S8: one `git revert` undoes it).

### Call site (S6)

- The owner runs `board` from any terminal.
- The dev cycle's final message ends with one line pointing to it ("board: 2 waiting on you, 1 playable"), read from the same script.

No hook and no new mandatory dispatch (S2). The added always-loaded context is zero lines.

### Size

The plan is about 200 lines of script, plus bats fixtures: three tiny fixture repos covering an unborn repo, one with entries, and one parked. H3 requires these to be hermetic, and they are under the ~400-line cap (S8).

## Observable (S6, can come out negative)

Measured over the 4 weeks after landing, against the 4 weeks before:

- **Age:** the oldest open `you:` entry across all repos is younger.
- **Turnaround:** median days from filing to answer for `you: walkthrough` entries goes down.
- **Use:** the script appends one line per run to `~/.claude/board-runs.log`.

If the board has been opened fewer than 3 times by week 2, or both age measures are flat at week 4, delete it. That is one revert.

## Alternatives considered

| Option | Why not first |
|---|---|
| [Backlog.md](https://github.com/MrLesk/Backlog.md) or beads | Per-repo stores that would compete with `roadmap.md` and `questions.md` rather than aggregate them (S3). Worth revisiting only if migrating off the current grammar becomes a goal. |
| GitHub Projects | The projects self-merge locally and GitHub is optional. A board that depends on pushing would show a stale view. |
| An LLM-written status summary per project | One dispatch per project per run (S2), and not re-checkable. If wanted later, add it as an optional one-line "what changed" per project, on top of the deterministic board. |
| Do nothing | Valid. Keep this if the observable comes out flat. |

## Sandbox constraints (from belegarth-herald feedback, 2026-11-12)

The design above assumes one process that can see every repo. In the cc-isolated setup that process doesn't exist yet:

- **Each project is its own container.** Its `/workspace` is that project's repo only, and `~/.claude` is a per-project volume. So a `~/.claude/board-repos` written inside one container is that project's file, and the other repos aren't mounted there to read.
- **Adding a directory doesn't make it readable.** Herald F-006 (`docs/working/feedback/belegarth-herald.md`): an added `/opt/claude-workflows` directory was still refused for Read after a restart, while an added directory under home worked. The board script reads through Bash, not the Read tool, so F-006 doesn't block it directly. But mounting other repos into a container would be a new decision under S8, not configuration.

**Host vs container: a decision this proposal now needs.**

| Option | What it means | Cost | If it's wrong |
|---|---|---|---|
| **[1] Host only** | `board` runs on the WSL host. The registry is `~/.config/board-repos` on the host, and `board.md` is written there. The dev cycle's final line is dropped: no container can compute it. | The owner runs `board` in a WSL terminal, not inside a session. | The board gets no free nudge from the cycle, so the "Use" observable decides faster. |
| **[2] Host builds, containers read a snapshot** | The host run also writes a one-line summary into each registered repo's untracked `.board-summary`, which the cycle's final message reads. | A host write into every repo (S3: a cache, not a source of truth). It goes stale until the next host run. | A stale line is worse than none; the line needs its own date. |
| **[3] Mount all repos read-only into every container** | `cc-isolated.sh` mounts the registry's repos read-only. | An enforcement-file change (Live-verified trailer, pre-mortem) that widens every container's view of every other project. | Every project's agent can read every other project, which weakens isolation. |

Recommendation: [1], and add [2] only if the "Use" count is low because the owner forgets the board exists. `board add` (the one write) has to run on the host either way.

## Risks

- **Grammar drift.** If `roadmap.md` sections are renamed in one repo, that repo's cards vanish silently. Mitigation (H2-style): if an expected section is missing, the board prints that project as `UNREADABLE: no ## Next` rather than empty.
- **Repo text is evidence, not instructions.** The board copies titles verbatim into a markdown file and never executes or follows anything from them. Links are relative file paths only.
- **The board becomes a new place that needs attention.** It asks for nothing and has no unread state. If it starts to feel like a queue, the column rules are wrong.

## Open questions for the owner

These are not filed as Q entries yet; they become entries if this moves to the roadmap.

1. Which repos go in the registry, and where do they live in WSL?
2. Should Parked hold a **WIP limit**, e.g. warn when more than 3 projects are Active? That's the reframe from the IDE survey: if too many projects are active, a cap does more than any view.
3. Phone access: remote control can't render workspace markdown. The options are:
   - render `board.md` to a single HTML file the owner opens in a browser, on the laptop or through a VS Code tunnel;
   - push the one-line summary as a notification;
   - leave it laptop-only.
