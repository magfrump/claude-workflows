# Running questions

Questions raised during autonomous work that did not justify stopping.

**To answer:** write `Q-0NN: <your answer>` anywhere — a reply, a file, a commit.
The ID is the whole handle; you never have to restate the question. Answers move
the entry to `questions-archive.md`, so this file only ever holds what is still open.

**Needs** is the route — who or what actually discharges the item, from
`docs/working/triage-2026-09-17-backlog.md` §3.1:

| Route | Meaning |
|---|---|
| `you: judgment` | Needs your taste or authority. The only real attention spend. |
| `you: terminal` | Needs your machine, not your mind. Collected into one paste below. |
| `agent` | Mechanical. Should not be here long. |
| `trigger` | Not a question yet — a condition being watched. Costs you nothing. |
| `deferred` | Scheduled behind an event that has not happened. |

Maintained by `scripts/questions.sh` (`check` · `index` · `archive` · `next-id` · `open`).
The index below is generated — edit entries, not the table.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-064](#q-064--unreadable-cwd-gate) | you: judgment | The Q-062 detector skips a same-uid process whose cwd it cannot read. Should it refuse instead? | 2026-09-25 |
<!-- index:end -->

## Open




### Q-064 · unreadable-cwd-gate
**Needs:** you: judgment · **Opened:** 2026-09-25 · **Status:** OPEN

The Q-062 detector skips a same-uid process whose cwd it cannot read. Should it refuse instead?

- **Why it's yours:** it sets how far your Q-062 [2] answer reaches: leftover helpers only, or also a process that actively hides.
- **Read:** `docs/reviews/security-review-2026-09-25-q062-q063.md` F1; rubric `code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md` A1; decision 037 "What the gate does not see".
- **Context:** the cwd is unreadable for a process that calls `prctl(PR_SET_DUMPABLE, 0)` (reproduced), and also for ssh-agent. A leftover helper does not do this by accident. A process that does can also evade by sitting in `/` with an open handle on the checkout, which no cwd check sees.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Skip and document** | Unreadable cwds are skipped; 037 lists "a process that hides its cwd" as not seen | None | A deliberately evading same-uid process writes during the install, unseen (it could evade anyway via an open handle) |
| **[2] Refuse on unreadable cwd** | Any same-uid process whose cwd can't be read refuses the install, naming it | Kill ssh-agent (and any other non-dumpable process) before every install | Nuisance refusals every install while ssh-agent runs; spoofable if an allowlist is added to reduce them |

- **Blocks:** nothing (A1's author note points here)
- **Interim:** [1]. The skip is commented at `procs_in_checkout` and listed in 037.
- **If the answer differs:** [2] replaces the `|| continue` with a refusal list plus a test; nothing is redone.
