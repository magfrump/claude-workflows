# Answer key: Q-278 reader tasks (2026-11-18)

**Never shown to readers.** Written from the Q-272 archive entry, the research doc
`docs/working/research-2026-11-11-confine-tests-fallback-data.md`, decision-log row 87 and H2 in
`docs/constraints.md`, not from Q-278. ● required, ○ credit.

**Intended gist.** Problem: the test-confinement script falls back to a weaker tool (`unshare`) when
`bwrap` is missing. Should it run after a warning, or refuse? Insight: the owner asked for data first,
and the data is mostly empty. `bwrap` presence is unknown, because neither tool works anywhere on record,
and no run has ever hit the fallback. Key move: a refusal would have stopped 0 runs, so [2] costs nothing
observed, and it follows H2 with no exception. Finding: the tentative pick is [2], or keep [1] until a
real `--probe` inside a session has run.

## Decider

**D0.** ● Run-or-refuse for the `unshare` fallback when `bwrap` can't be used. ● No answer keeps the Q-272
[1] "to start" interim: it runs under `unshare` after a warning. ○ That is a provisional H2 exception, not
written into `constraints.md`.

**D1.** Testimony. Record the option, and whether anything was opened.

**D2.** ● One self-merged build loop. ● If wrong: a run without `bwrap` that doesn't pass the new flag
stops until someone passes it. ○ 0 runs would have stopped so far.

**D3.** ● Keeping the fallback is an exception to hard constraint H2, which only the owner grants.
○ H2: a degraded tool refuses and names what went unenforced.

**D4.** ● How often `bwrap` is missing: not enough data. Neither tool works in the sandbox or the current
image, and the host isn't on record. ● Friction: none so far. 7 build loops all exited 3, the fallback
never ran, and a refusal would have stopped 0. ○ The 2026-11-12 revert took `bwrap` out of the image.
○ Nothing records which tool `--probe` finds.

**D5.** Testimony. Credit: "wait for data" (in prose under the table, not a row); "build warning tracking
first" (research §3: six ways, none built).

## Acting agent

**A0.** ● Interim [1]: run under `unshare` after a warning. ● It rests on the owner's Q-272 answer "[1] to
start" (decision-log row 87).

**A1.** ● Write a brief for one build loop. Without `bwrap` the script exits 3, unless a new flag asks for
`unshare`, and the briefs' test wording passes that flag. ● It self-merges. ○ It updates decision-log row
87 and drops the provisional exception. ○ Under [2], `--probe` also refuses on a fallback (Q-272).

**A2.** ● [1] means one line in `docs/constraints.md` recording the H2 exception, **which the owner
commits** (no agent writes that file). ● Record the condition. ● "Keep tracking" has no mechanism today:
nothing records the probe's tool, and research §3's options are unbuilt. So the condition needs a
roadmap item or a follow-up entry to the owner, not silence.
